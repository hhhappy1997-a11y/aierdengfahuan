extends Node
class_name EnemyDirector

## 2 号工位 · M1 敌人调度器（实体侧）
##
## I-3：消费 3 号 SpawnRequest，字段集严格以 3 号《接口契约.md》§3 的 17 字段为唯一定义
##   （R2 口径 4）。R1 的 enemy_data_path / enemy_instance_id / spawn_position / spawn_facing_deg /
##   chunk_id / respawn_on_rest / level_offset / initial_flags 等最小假设一律按 17 字段收口：
##     enemy_id（查表） / spawn_point_id + position（摆位） / facing_degrees（朝向） /
##     level（只读） / hp_override + stance_override（本次生成覆盖位，不改数据表） /
##     aggro_radius + leash_radius（AI 半径覆盖位） / respawn_policy（不自行刷新） /
##     defeated_flag（只读，不写） / loot_table_id / patrol_route / spawn_group_id /
##     metadata（只读，不得塞战斗数值） / request_id（去重） / is_boss（分支）。
## I-1：只经 WorldState.get_flag(key, default) 双参读取，调用方自行 cast；不 set_flag、不碰存档。
## I-2：击杀 flag 只由 3 号写；本脚本只发模块内信号 target_defeated，由集成层连接
##   PlayerStateMachine.report_defeat()（全模块 I-2 唯一发射点），绝不双写、绝不 emit I-2。
## I-4：只调 set_pose(pose_name, frame_index)，pose 名 = pose_prefix + move.pose_name，
##   前缀按冻结表用 p1_ / p2_（Boss）或 enemy_（普通敌人），不写 billboard / 锚定 / 缩放。
## 数值全部查表：感知 / 丢失半径、追击速度、攻击距离、轮询间隔、aggression、权重、种子、
##   三段帧数、判定扇形、冷却一律来自 EnemyData / BossData / PhaseData / MoveData 资源字段。
##   本文件数字字面量仅为：帧 / 计时起点 0、哨兵 -1 判定、几何与数学常量（半角 0.5、
##   clamp 边界 ±1.0、长度下限 0.0），无任何本案战斗数值（无 420 / 0.5 阈值 / 96 速度 / 2.1 倍率 等）。
## 目标路径：res://scripts/combat/enemy_director.gd

# ---- 模块内信号（非 I-2；集成层连接 PlayerStateMachine.report_defeat） ----
signal target_defeated(defeat_id: String, is_boss: bool)
## 招式判定帧命中：带数据表资源，交给 CombatResolver 结算，本脚本不结算数值。
signal move_landed(defeat_id: String, move: MoveData, attacker_data: Resource)

@export var player_path: NodePath = ^"../Player"
@export var sprite_path: NodePath = ^"../Hybrid2D3DAnimatedSprite"
@export var world_state_path: NodePath = ^"/root/WorldState"
## id -> EnemyData / BossData 资源查表入口（3 号 SpawnRequest.enemy_id 据此查表，2 号不定义表内容）
@export var enemy_registry: Dictionary = {}

var _player: Node3D = null
var _sprite: Node = null
var _world_state: Node = null
## request_id -> 运行时实例字典（Dictionary 为引用类型，就地修改即生效）
var _spawned: Dictionary = {}


func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	_sprite = get_node_or_null(sprite_path)
	_world_state = get_node_or_null(world_state_path)


# ---------------------------------------------------------------------------
# I-3：spawn_from_request —— 消费 3 号 17 字段
# ---------------------------------------------------------------------------

func spawn_from_request(request: SpawnRequest) -> bool:
	if request == null:
		push_error("EnemyDirector: SpawnRequest 为空")
		return false
	# request_id 去重键：重复请求直接丢弃（M2 chunk 重载不刷双份）
	if _spawned.has(request.request_id):
		return false
	# I-1 只读 defeated_flag：已击败则不生成。击杀 flag 由 3 号经 I-2 写，2 号不写。
	if not request.defeated_flag.is_empty():
		var already_defeated: bool = bool(_read_world_flag(request.defeated_flag, false))
		if already_defeated:
			return false
	# enemy_id 必须据此查表；查不到 push_error 不生成（3 号 §3 消费规则 #2）
	var data: Resource = _lookup_enemy_data(request.enemy_id)
	if data == null:
		push_error("EnemyDirector: enemy_id 查表失败 -> %s" % request.enemy_id)
		return false
	var inst: Dictionary = _build_instance(request, data)
	_spawned[request.request_id] = inst
	return true


func _lookup_enemy_data(enemy_id: String) -> Resource:
	return enemy_registry.get(enemy_id, null) as Resource


func _resolve_position(request: SpawnRequest) -> Vector3:
	# spawn_point_id 优先（1 号场景提供 Marker3D），找不到时用 position 兜底。
	var pos: Vector3 = request.position
	if not request.spawn_point_id.is_empty():
		var marker: Node3D = get_node_or_null(NodePath(request.spawn_point_id)) as Node3D
		if marker != null:
			pos = marker.global_position
	return pos


func _build_instance(request: SpawnRequest, data: Resource) -> Dictionary:
	# 从数据表装配全部战斗数值；SpawnRequest 只提供第 7~10 项覆盖位，不改数据表。
	var boss: BossData = data as BossData
	var enemy: EnemyData = data as EnemyData
	var is_boss: bool = request.is_boss

	var max_hp: float = 0.0
	var aggro: float = 0.0
	var leash: float = 0.0
	var chase_speed: float = 0.0
	var attack_range: float = 0.0
	var poll_interval: float = 0.0
	var rng_seed: int = 0
	var max_poise: float = 0.0
	var moves: Array = []
	var pose_prefix: String = ""

	if is_boss and boss != null:
		max_hp = boss.max_hp
		aggro = boss.aggro_radius_px
		leash = boss.lose_radius_px
		chase_speed = boss.chase_speed_px_per_sec
		attack_range = boss.attack_range_px
		rng_seed = boss.rng_seed
		max_poise = boss.poise.max_poise
		var phase: PhaseData = boss.phases[0] as PhaseData
		# 轮询间隔 = 数据表 ai_poll_interval_sec / PhaseData.aggression（数值全部查表，不写死 1.0）
		poll_interval = boss.ai_poll_interval_sec / phase.aggression
		moves = phase.moves
		pose_prefix = phase.pose_prefix
	elif enemy != null:
		max_hp = enemy.max_hp
		aggro = enemy.aggro_radius_px
		leash = enemy.lose_radius_px
		chase_speed = enemy.chase_speed_px_per_sec
		attack_range = enemy.attack_range_px
		poll_interval = enemy.ai_poll_interval_sec
		rng_seed = enemy.rng_seed
		max_poise = enemy.poise.max_poise
		moves = enemy.moves
		pose_prefix = enemy.pose_prefix
	else:
		push_error("EnemyDirector: is_boss 与数据表类型不匹配 -> %s" % request.enemy_id)
		return {}

	# 覆盖位：哨兵语义来自 3 号字段定义（-1 / -1.0 / 0.0 表示「用数据表」），非战斗数值。
	var hp: float = max_hp
	if request.hp_override >= 0:
		hp = float(request.hp_override)
	var poise: float = max_poise
	if request.stance_override >= 0.0:
		poise = request.stance_override
	if request.aggro_radius > 0.0:
		aggro = request.aggro_radius
	if request.leash_radius >= aggro:
		leash = request.leash_radius

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = rng_seed

	return {
		"data": data,
		"defeat_id": request.enemy_id,          # I-2 参数用数据表 id（3 号 §2.1）
		"is_boss": is_boss,
		"position": _resolve_position(request),
		"facing_degrees": request.facing_degrees,
		"hp": hp,
		"poise": poise,
		"aggro": aggro,
		"leash": leash,
		"chase_speed": chase_speed,
		"attack_range": attack_range,
		"poll_interval": poll_interval,
		"moves": moves,
		"pose_prefix": pose_prefix,
		"rng": rng,
		"poll_timer": 0.0,                     # 计时起点
		"chasing": false,
		"current_move": null,
		"move_frame": 0,
		"cooldowns": {},                       # move.id -> 剩余冷却秒（数值来自 MoveData.cooldown_sec）
		# 以下 17 字段中的只读项：登记备查，2 号不回写、不结算、不写 flag
		"request_id": request.request_id,
		"level": request.level,
		"respawn_policy": request.respawn_policy,
		"loot_table_id": request.loot_table_id,
		"patrol_route": request.patrol_route,
		"spawn_group_id": request.spawn_group_id,
		"metadata": request.metadata,
	}


# ---------------------------------------------------------------------------
# 每帧调度：滞回追击 + 轮询 + 加权抽取 + 招式帧推进
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var player_pos: Vector3 = Vector3.ZERO
	if _player != null:
		player_pos = _player.global_position
	for key in _spawned.keys():
		var inst: Dictionary = _spawned[key]
		_tick_instance(inst, delta, player_pos)


func _tick_instance(inst: Dictionary, delta: float, player_pos: Vector3) -> void:
	var pos: Vector3 = inst["position"] as Vector3
	var d: float = pos.distance_to(player_pos)
	var aggro: float = inst["aggro"] as float
	var leash: float = inst["leash"] as float
	var chasing: bool = inst["chasing"] as bool
	# 滞回：d <= aggro 进入 Chase，d > leash 才退回 Idle，aggro < d <= leash 保持上一状态（E-5）
	if d <= aggro:
		chasing = true
	elif d > leash:
		chasing = false
	inst["chasing"] = chasing

	if chasing:
		var step: float = (inst["chase_speed"] as float) * delta
		if d <= (inst["attack_range"] as float):
			step = 0.0                     # 进入出招距离后停止逼近（数值仍来自 attack_range_px）
		pos = pos.move_toward(player_pos, step)
		inst["position"] = pos

	# 冷却递减（数值来自 MoveData.cooldown_sec）
	var cooldowns: Dictionary = inst["cooldowns"]
	for cd_key in cooldowns.keys():
		var remaining: float = cooldowns[cd_key] as float
		if remaining > 0.0:
			cooldowns[cd_key] = remaining - delta

	# 轮询拍：到间隔做一次加权抽取（间隔 = ai_poll_interval_sec / aggression，查表）
	var timer: float = inst["poll_timer"] as float
	timer += delta
	var interval: float = inst["poll_interval"] as float
	if timer >= interval:
		timer -= interval
		_poll_move(inst, d)
	inst["poll_timer"] = timer

	# 招式播放：startup -> active -> recovery，active 区间 [startup, startup+active) 做扇形判定
	var move: MoveData = inst["current_move"] as MoveData
	if move == null:
		return
	var frame: int = (inst["move_frame"] as int) + 1
	_apply_pose(inst, move, frame)
	var active_end: int = move.startup_frames + move.active_frames
	if frame >= move.startup_frames and frame < active_end:
		if _in_hit_arc(inst, move, player_pos):
			move_landed.emit(inst["defeat_id"] as String, move, inst["data"] as Resource)
	var total: int = active_end + move.recovery_frames
	if frame >= total:
		inst["current_move"] = null
		cooldowns[move.id] = move.cooldown_sec
	inst["move_frame"] = frame


func _poll_move(inst: Dictionary, d: float) -> void:
	var moves: Array = inst["moves"] as Array
	var cooldowns: Dictionary = inst["cooldowns"]
	var candidates: Array[MoveData] = []
	var total_weight: float = 0.0
	for entry in moves:
		var m: MoveData = entry as MoveData
		if m == null:
			continue
		# 过滤：min <= d <= max、weight > 0、冷却 <= 0（全部数值来自 MoveData）
		if d < m.min_range_px or d > m.max_range_px:
			continue
		if m.weight <= 0.0:
			continue
		var cd: float = cooldowns.get(m.id, 0.0) as float
		if cd > 0.0:
			continue
		total_weight += m.weight
		candidates.append(m)
	if total_weight <= 0.0 or candidates.is_empty():
		return
	var rng: RandomNumberGenerator = inst["rng"] as RandomNumberGenerator
	var pick: float = rng.randf() * total_weight
	var acc: float = 0.0
	for m in candidates:
		acc += m.weight
		if pick < acc:
			inst["current_move"] = m
			inst["move_frame"] = 0
			return


func _apply_pose(inst: Dictionary, move: MoveData, frame: int) -> void:
	# I-4：只调 set_pose(pose_name, frame_index)；frame_index 为动作内帧索引，clamp 归 1 号。
	if _sprite == null or not _sprite.has_method("set_pose"):
		return
	var prefix: String = inst["pose_prefix"] as String
	_sprite.call("set_pose", prefix + move.pose_name, frame)


func _in_hit_arc(inst: Dictionary, move: MoveData, player_pos: Vector3) -> bool:
	# 扇形判定：半径 hitbox_reach_px、张角 hitbox_arc_deg（数值来自 MoveData）。
	# 以下 0.5 / 1.0 / -1.0 / 0.0 为几何与数学常量（半角、clamp 边界、零向量），非数据表数值。
	var pos: Vector3 = inst["position"] as Vector3
	if pos.distance_to(player_pos) > move.hitbox_reach_px:
		return false
	var facing_rad: float = deg_to_rad(inst["facing_degrees"] as float)
	var facing_dir: Vector3 = Vector3(sin(facing_rad), 0.0, cos(facing_rad))
	var to_player: Vector3 = player_pos - pos
	if to_player.length() <= 0.0:
		return true
	var dot: float = facing_dir.normalized().dot(to_player.normalized())
	var angle_deg: float = rad_to_deg(acos(clampf(dot, -1.0, 1.0)))
	return angle_deg <= move.hitbox_arc_deg * 0.5


# ---------------------------------------------------------------------------
# 受击扣血 / 击杀出口（HP 归零只发模块内信号，不写 flag、不 emit I-2）
# ---------------------------------------------------------------------------

func apply_damage(request_id: String, amount: float) -> void:
	if not _spawned.has(request_id):
		return
	var inst: Dictionary = _spawned[request_id]
	var hp: float = (inst["hp"] as float) - amount
	inst["hp"] = hp
	if hp <= 0.0:
		var defeat_id: String = inst["defeat_id"] as String
		var is_boss: bool = inst["is_boss"] as bool
		_spawned.erase(request_id)
		target_defeated.emit(defeat_id, is_boss)


# ---------------------------------------------------------------------------
# I-1：统一双参 get_flag(key, default)，调用方自行 cast（R2 口径 2）
# ---------------------------------------------------------------------------

func _read_world_flag(key: String, default_value: Variant) -> Variant:
	if _world_state == null or not _world_state.has_method("get_flag"):
		return default_value
	return _world_state.call("get_flag", key, default_value)
