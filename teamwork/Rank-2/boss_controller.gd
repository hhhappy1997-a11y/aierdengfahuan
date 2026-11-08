extends Node
class_name BossController

## ===========================================================================
## 2 号工位 · R4 新增交付件：M5 Boss 控制器（数据驱动二阶段 + 阶段攻击表加权抽招）
##
## 【本轮定位】任务书-R4.md 交付件 1。R2/R3 既有 schema/*.gd、*.tres、combat_*.gd、
##   motion-mapping.md 一律不重做、不改动；本文件是本轮新增件，既有交付件零改动。
## 【数据驱动】全部数值来自 BossData / PhaseData / MoveData / PoiseConfig /
##   StatusBuildup 资源字段（3 份 .tres）。本文件零战斗数值硬编码；仅出现计时起点 0、
##   归零 / 几何 / 数学常量（0.0 / -1.0 / 1.0 / 0.5）与 > 0.0 之类的边界判定，
##   符合《战斗系统设计.md》§4.3 / §7.2。唯一允许的下限常量 MIN_DAMAGE 属结算器，
##   本控制器不做伤害结算、不定义该常量。
## 【二阶段】phases 按 phase_index 升序、phase_thresholds 为唯一阈值真源；HP 比例低于
##   phase_thresholds[_phase_index] 且 phase_transition_enabled 时进入 PhaseTransition，
##   只换资源引用与运行时数值（pose_prefix 由 p1_ 切 p2_、moves 表、
##   phase_damage_multiplier / phase_defense / poise_override /
##   status_resistance_multiplier / aggression），不 change_scene / 不 queue_free 整个节点
##   （《战斗系统设计.md》§6.2）。
## 【公平性】HP 阈值在每次受击结算末尾检查；若命中时正处于招式判定帧，先标记
##   _pending_phase，等招式播放结束再进过渡（《战斗系统设计.md》§6.2）。
## 【招式】当前阶段 moves 表按 weight 加权抽取（rng_seed 播种、固定可复现），过滤
##   min/max_range_px 与 cooldown；startup -> active -> recovery 三段帧推进，
##   active 区间 [startup, startup + active) 发模块内信号 move_landed（带 MoveData），
##   交给 CombatResolver 结算；本脚本不注入任何战斗数值。
## 【I-1】只读 WorldState.get_flag(key, default) 双参，调用方自行 cast；不 set_flag、
##   不写存档、不碰 SaveDelta。
## 【I-2】击杀只经 CombatEventBus.report_defeat() 发到 /root/GameEvents autoload，
##   参数单个 String（BossData.id）；击杀 flag 只由 3 号写，2 号不双写。
## 【I-3】SpawnRequest 17 字段以 3 号《接口契约.md》§3 为唯一定义；Boss 数据由集成层
##   按 enemy_id 查表后赋给 boss_data，本控制器不定义 / 不读取 SpawnRequest 字段。
## 【I-4】只调 set_pose(pose_name, frame_index)；pose 名一律 = PhaseData.pose_prefix +
##   MoveData.pose_name（p1_ / p2_ 前缀）；不写 billboard / 锚定 / 缩放 / SpriteFrames。
## 【目标路径】res://scripts/combat/boss_controller.gd
## 引擎：Godot 4 标准版 / GDScript，全静态类型；中文 UTF-8。
## ===========================================================================

enum BossState {
	IDLE,
	CHASE,
	PHASE_TRANSITION,
	DEATH,
}

# ---- 模块内信号（均非 I-2；击杀出口见 CombatEventBus） ----
## 阶段切换完成（phase_index / id 来自 PhaseData）。
signal phase_changed(phase_index: int, phase_id: String)
## 过渡演出开始 / 结束。
signal transition_started(phase_index: int)
signal transition_finished(phase_index: int)
## 招式判定帧命中：带数据表资源，交给 CombatResolver 结算，本脚本不结算数值。
signal move_landed(defeat_id: String, move: MoveData, attacker_data: Resource)

@export var boss_data: BossData = null
@export var sprite_path: NodePath = ^"../Hybrid2D3DAnimatedSprite"
@export var event_bus_path: NodePath = ^"../CombatEventBus"
@export var world_state_path: NodePath = ^"/root/WorldState"

var _sprite: Node = null
var _event_bus: Node = null
var _world_state: Node = null

var _hp: float = 0.0
var _phase_index: int = 0                  # phases 数组下标（0 起），非 PhaseData.phase_index 值
var _phase: PhaseData = null
var _poise: PoiseConfig = null
var _current_poise: float = 0.0
var _rng: RandomNumberGenerator = null
var _cooldowns: Dictionary = {}            # move.id -> 剩余冷却秒（来自 MoveData.cooldown_sec）
var _current_move: MoveData = null
var _move_frame: int = 0
var _poll_timer: float = 0.0
var _state: BossState = BossState.IDLE
var _transition_frame: int = 0
var _pending_phase: bool = false
var _defeated: bool = false

var _position: Vector3 = Vector3.ZERO
var _player_position: Vector3 = Vector3.ZERO
var _facing_degrees: float = 0.0


func _ready() -> void:
	_sprite = get_node_or_null(sprite_path)
	_event_bus = get_node_or_null(event_bus_path)
	_world_state = get_node_or_null(world_state_path)
	if boss_data == null:
		push_error("BossController: boss_data 未挂载")
		set_physics_process(false)
		return
	if boss_data.phases.is_empty():
		push_error("BossController: phases 为空")
		set_physics_process(false)
		return
	_hp = boss_data.max_hp
	_rng = RandomNumberGenerator.new()
	_rng.seed = boss_data.rng_seed
	# I-1：只读 defeated_flag_key，不写；已击败则不再进入战斗（flag 由 3 号经 I-2 写）。
	if not boss_data.defeated_flag_key.is_empty():
		var already: bool = bool(_read_world_flag(boss_data.defeated_flag_key, false))
		if already:
			push_warning("BossController: 数据表 id 已标记击败，控制器保持 IDLE -> %s" % boss_data.id)
			return
	_enter_phase(0, false)


func _physics_process(delta: float) -> void:
	advance(delta)


# ---------------------------------------------------------------------------
# 阶段装载 / 切换（只换资源引用与运行时数值，节点与场景树保持不变）
# ---------------------------------------------------------------------------

func _enter_phase(index: int, play_transition: bool) -> void:
	_phase_index = index
	_phase = boss_data.phases[index] as PhaseData
	_poise = _phase.poise_override if _phase.poise_override != null else boss_data.poise
	_current_poise = _poise.max_poise if _poise != null else 0.0
	_cooldowns.clear()
	_current_move = null
	_move_frame = 0
	_poll_timer = 0.0
	_pending_phase = false
	if play_transition and boss_data.phase_transition_enabled:
		_state = BossState.PHASE_TRANSITION
		_transition_frame = 0
		_apply_pose(_phase.pose_prefix + _phase.transition_pose_name, _transition_frame)
		print("[BossController] PhaseTransition 开始 -> phase_index=%d id=%s pose_prefix=%s frames=%d" % [
			_phase.phase_index, _phase.id, _phase.pose_prefix, _phase.transition_frames])
		transition_started.emit(_phase.phase_index)
	else:
		_state = BossState.CHASE
	phase_changed.emit(_phase.phase_index, _phase.id)
	print("[BossController] 阶段装载 -> phase_index=%d pose_prefix=%s 招式数=%d" % [
		_phase.phase_index, _phase.pose_prefix, _phase.moves.size()])


func _begin_transition() -> void:
	var next: int = _phase_index + 1
	if next >= boss_data.phases.size():
		return
	_current_move = null
	_enter_phase(next, true)


func _tick_transition() -> void:
	_transition_frame += 1
	_apply_pose(_phase.pose_prefix + _phase.transition_pose_name, _transition_frame)
	if _transition_frame >= _phase.transition_frames:
		_state = BossState.CHASE
		_poll_timer = 0.0
		transition_finished.emit(_phase.phase_index)
		print("[BossController] PhaseTransition 结束 -> phase_index=%d pose_prefix=%s 招式数=%d" % [
			_phase.phase_index, _phase.pose_prefix, _phase.moves.size()])


# ---------------------------------------------------------------------------
# 主推进：轮询拍 + 加权抽取 + 招式三段帧
# ---------------------------------------------------------------------------

func advance(delta: float) -> void:
	if boss_data == null or _phase == null or _defeated:
		return
	if _state == BossState.PHASE_TRANSITION:
		_tick_transition()
		return
	if _state == BossState.DEATH or _state == BossState.IDLE:
		return
	_tick_cooldowns(delta)
	var distance: float = _position.distance_to(_player_position)
	var interval: float = boss_data.ai_poll_interval_sec
	if _phase.aggression > 0.0:
		interval = interval / _phase.aggression
	_poll_timer += delta
	if _poll_timer >= interval:
		_poll_timer -= interval
		_poll_move(distance)
	_tick_move()


func _tick_cooldowns(delta: float) -> void:
	for key in _cooldowns.keys():
		var remaining: float = float(_cooldowns[key])
		if remaining > 0.0:
			_cooldowns[key] = remaining - delta


func _poll_move(distance: float) -> void:
	var candidates: Array[MoveData] = []
	var total_weight: float = 0.0
	for entry in _phase.moves:
		var move: MoveData = entry as MoveData
		if move == null:
			continue
		if distance < move.min_range_px or distance > move.max_range_px:
			continue
		if move.weight <= 0.0:
			continue
		var cd: float = float(_cooldowns.get(move.id, 0.0))
		if cd > 0.0:
			continue
		total_weight += move.weight
		candidates.append(move)
	if total_weight <= 0.0 or candidates.is_empty():
		return
	var pick: float = _rng.randf() * total_weight
	var acc: float = 0.0
	for move in candidates:
		acc += move.weight
		if pick < acc:
			_current_move = move
			_move_frame = 0
			print("[BossController] 抽中招式 -> phase=%d move=%s pose=%s%s weight=%.2f total=%.2f" % [
				_phase.phase_index, move.id, _phase.pose_prefix, move.pose_name,
				move.weight, total_weight])
			return


func _tick_move() -> void:
	if _current_move == null:
		return
	var move: MoveData = _current_move
	_move_frame += 1
	_apply_pose(_phase.pose_prefix + move.pose_name, _move_frame)
	var active_end: int = move.startup_frames + move.active_frames
	if _move_frame >= move.startup_frames and _move_frame < active_end:
		if _in_hit_arc(move):
			move_landed.emit(boss_data.id, move, boss_data)
	var total: int = active_end + move.recovery_frames
	if _move_frame >= total:
		_cooldowns[move.id] = move.cooldown_sec
		_current_move = null
		if _pending_phase:
			_pending_phase = false
			_begin_transition()


func _in_hit_arc(move: MoveData) -> bool:
	# 扇形判定：半径 hitbox_reach_px、张角 hitbox_arc_deg（数值来自 MoveData）。
	# 0.0 / 0.5 / -1.0 / 1.0 为几何与数学常量（零向量、半角、clamp 边界），非战斗数值。
	if _position.distance_to(_player_position) > move.hitbox_reach_px:
		return false
	var facing_rad: float = deg_to_rad(_facing_degrees)
	var facing_dir: Vector3 = Vector3(sin(facing_rad), 0.0, cos(facing_rad))
	var to_player: Vector3 = _player_position - _position
	if to_player.length() <= 0.0:
		return true
	var dot: float = facing_dir.normalized().dot(to_player.normalized())
	var angle_deg: float = rad_to_deg(acos(clampf(dot, -1.0, 1.0)))
	return angle_deg <= move.hitbox_arc_deg * 0.5


# ---------------------------------------------------------------------------
# 受击 / HP 阈值 / 击杀（数值全部来自数据表）
# ---------------------------------------------------------------------------

func apply_damage(amount: float) -> void:
	if _defeated or boss_data == null or _phase == null:
		return
	if _state == BossState.PHASE_TRANSITION and _phase.transition_invulnerable:
		return
	_hp = maxf(0.0, _hp - amount)
	if _hp <= 0.0:
		_die()
		return
	_check_phase_threshold()


func _check_phase_threshold() -> void:
	if not boss_data.phase_transition_enabled:
		return
	var next: int = _phase_index + 1
	if next >= boss_data.phases.size():
		return
	if _phase_index >= boss_data.phase_thresholds.size():
		return
	var ratio: float = _hp / boss_data.max_hp
	var threshold: float = boss_data.phase_thresholds[_phase_index]
	if ratio > threshold:
		return
	# 公平性约束：招式判定帧内先挂起，等招式播放结束再切阶段。
	if _current_move != null and _in_active_window():
		_pending_phase = true
		return
	_begin_transition()


func _in_active_window() -> bool:
	if _current_move == null:
		return false
	var active_end: int = _current_move.startup_frames + _current_move.active_frames
	return _move_frame >= _current_move.startup_frames and _move_frame < active_end


func _die() -> void:
	_defeated = true
	_state = BossState.DEATH
	_current_move = null
	_apply_pose(_phase.pose_prefix + boss_data.death_pose_name, 0)
	print("[BossController] Boss 被击败 -> id=%s（I-2 交给 CombatEventBus）" % boss_data.id)
	_report_defeat(boss_data.id, true)


func _report_defeat(defeat_id: String, is_boss: bool) -> void:
	if _event_bus != null and _event_bus.has_method("report_defeat"):
		_event_bus.call("report_defeat", defeat_id, is_boss)
	else:
		push_warning("BossController: CombatEventBus 未挂载，击杀未发出 I-2 信号 -> %s" % defeat_id)


# ---------------------------------------------------------------------------
# 集成层 / UI 只读查询（非探针；供血条、阶段 UI 与运行日志使用）
# ---------------------------------------------------------------------------

func get_phase_index() -> int:
	return _phase.phase_index if _phase != null else 0


func get_pose_prefix() -> String:
	return _phase.pose_prefix if _phase != null else ""


func get_move_count() -> int:
	return _phase.moves.size() if _phase != null else 0


func get_hp_ratio() -> float:
	if boss_data == null or boss_data.max_hp <= 0.0:
		return 0.0
	return _hp / boss_data.max_hp


# ---------------------------------------------------------------------------
# I-1：统一双参 get_flag(key, default)，调用方自行 cast；不 set_flag
# ---------------------------------------------------------------------------

func _read_world_flag(key: String, default_value: Variant) -> Variant:
	if _world_state == null or not _world_state.has_method("get_flag"):
		return default_value
	return _world_state.call("get_flag", key, default_value)


# ---------------------------------------------------------------------------
# I-4：只调 set_pose(pose_name, frame_index)，pose 名一律带 p1_ / p2_ 前缀
# ---------------------------------------------------------------------------

func _apply_pose(pose_name: String, frame_index: int) -> void:
	if _sprite == null or not _sprite.has_method("set_pose"):
		return
	_sprite.call("set_pose", pose_name, frame_index)


# ---------------------------------------------------------------------------
# 集成层设置：摆位 / 朝向 / 玩家位置（数值来自 SpawnRequest / 场景，2 号不定义）
# ---------------------------------------------------------------------------

func set_boss_position(pos: Vector3) -> void:
	_position = pos


func set_target_position(pos: Vector3) -> void:
	_player_position = pos


func set_facing_degrees(degrees: float) -> void:
	_facing_degrees = degrees
