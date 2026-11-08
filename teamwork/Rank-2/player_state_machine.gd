extends Node
class_name PlayerStateMachine

## 2 号工位 · 玩家战斗状态机骨架（M1 玩家动作 / M5 Boss 战共用）
##
## 设计原则：
##  - 一切帧数、速度、倍率、优先级、pose 名均来自 PlayerActionData 数据表；
##    本文件唯一允许的战斗数值常量是 MIN_DAMAGE（伤害下限）。
##  - I-4：只通过 set_pose(pose_name, frame_index) 通知 1 号的 Hybrid2D3DAnimatedSprite，
##    不写 billboard / 锚定 / 缩放 / SpriteFrames 操作。
##  - I-1：世界状态只经 WorldState.get_flag / set_flag 访问，不读写存档、不碰 SaveDelta。
##  - I-2：击败事件只发信号，由 3 号订阅写 Delta；2 号不写 defeated_flag_key。
##  - 字段定义唯一真源：teamwork/Rank-2/数据表schema.md
##  - 目标路径：res://scripts/combat/player_state_machine.gd

enum State {
	IDLE,
	WALK,
	RUN,
	ROLL,
	ATTACK_LIGHT,
	ATTACK_HEAVY,
	HITSTUN,
	DEATH,
}

# ---- I-2：2 号 → 3 号（3 号订阅后写入 SaveDelta） ----
signal enemy_defeated(enemy_id: String)
signal boss_defeated(boss_id: String)

# ---- 模块内信号（1 号 / UI 可选订阅） ----
signal state_changed(from_state: State, to_state: State)
signal invulnerability_changed(active: bool)
signal damage_dealt(target_id: String, amount: float, damage_type: String)
signal poise_damage_dealt(target_id: String, amount: float)
signal status_buildup_applied(target_id: String, status_type: String, amount: float)
signal stance_broken(target_id: String)
signal death_confirmed()

## 唯一允许的伤害数值常量：伤害结算下限（防止高防御出现 0 / 负伤害）。
const MIN_DAMAGE: float = 1.0

# ---- 编辑器挂载项 ----
@export var actions: Array[PlayerActionData] = []
@export var sprite_path: NodePath = ^"../Hybrid2D3DAnimatedSprite"
@export var world_state_path: NodePath = ^"/root/WorldState"
@export var player_alive_flag: String = "world.player.alive"

# ---- 运行时状态 ----
var current_state: State = State.IDLE
var state_frame: int = 0

var _action_by_state: Dictionary = {}
var _sprite: Node = null
var _world_state: Node = null
var _flag_get_argc: int = 2
var _was_invulnerable: bool = false
var _hit_targets: Dictionary = {}


func _ready() -> void:
	_sprite = get_node_or_null(sprite_path)
	_world_state = get_node_or_null(world_state_path)
	_resolve_world_flag_signature()
	_build_action_table()
	if _action_by_state.size() != State.size():
		push_error("PlayerStateMachine: PlayerActionData 必须覆盖全部 %d 个状态，当前 %d 条（E-6）" % [State.size(), _action_by_state.size()])
		set_physics_process(false)
		return
	_validate_action_table()
	var alive: bool = bool(_read_world_flag(player_alive_flag, true))
	_enter_state(State.DEATH if not alive else State.IDLE)


func _physics_process(_delta: float) -> void:
	var action: PlayerActionData = _current_action()
	if action == null:
		return
	state_frame += 1
	_apply_pose(action)
	var invuln_now: bool = is_invulnerable()
	if invuln_now != _was_invulnerable:
		_was_invulnerable = invuln_now
		invulnerability_changed.emit(invuln_now)
	if not _is_persistent(current_state) and state_frame >= _total_frames(action):
		_transition_to(State.IDLE)


# ---------------------------------------------------------------------------
# 数据表装载与自检（E-6 / E-7，运行时自检，非探针脚本）
# ---------------------------------------------------------------------------

func _build_action_table() -> void:
	_action_by_state.clear()
	for action: PlayerActionData in actions:
		if action == null:
			continue
		var s: State = _state_from_name(action.state_name)
		if _action_by_state.has(s):
			push_error("PlayerStateMachine: state_name 重复 -> %s（E-6）" % action.state_name)
			continue
		_action_by_state[s] = action


func _validate_action_table() -> void:
	var expected_fps: int = -1
	var seen_priority: Dictionary = {}
	for s in _action_by_state.keys():
		var a: PlayerActionData = _action_by_state[s] as PlayerActionData
		if expected_fps < 0:
			expected_fps = a.logic_fps
		elif a.logic_fps != expected_fps:
			push_error("PlayerStateMachine: logic_fps 必须全表一致（E-6），%s = %d，期望 %d" % [a.id, a.logic_fps, expected_fps])
		if seen_priority.has(a.state_priority):
			push_error("PlayerStateMachine: state_priority 重复 %d（E-6）" % a.state_priority)
		seen_priority[a.state_priority] = true
		if expected_fps != Engine.physics_ticks_per_second:
			push_warning("PlayerStateMachine: 数据表 logic_fps=%d 与 Engine.physics_ticks_per_second=%d 不一致，帧数口径需对齐" % [expected_fps, Engine.physics_ticks_per_second])
		if a.invulnerable_end_frame > a.invulnerable_start_frame and a.invulnerable_start_frame >= 0:
			if a.invulnerable_start_frame != a.startup_frames or a.invulnerable_end_frame != a.startup_frames + a.active_frames:
				push_error("PlayerStateMachine: 无敌区间与三段帧不自洽（E-7）-> %s" % a.id)


func _state_from_name(state_name: String) -> State:
	match state_name:
		"idle": return State.IDLE
		"walk": return State.WALK
		"run": return State.RUN
		"roll": return State.ROLL
		"attack_light": return State.ATTACK_LIGHT
		"attack_heavy": return State.ATTACK_HEAVY
		"hitstun": return State.HITSTUN
		"death": return State.DEATH
	push_error("PlayerStateMachine: 未知 state_name -> %s" % state_name)
	return State.IDLE


func _current_action() -> PlayerActionData:
	return _action_by_state.get(current_state, null) as PlayerActionData


func _total_frames(action: PlayerActionData) -> int:
	## E-2：total 不设字段，只由三段相加派生，避免双源不一致。
	return action.startup_frames + action.active_frames + action.recovery_frames


func _is_persistent(s: State) -> bool:
	## 持续状态不自动回到 idle，由输入 / 世界状态驱动转移。
	match s:
		State.IDLE, State.WALK, State.RUN, State.DEATH:
			return true
	return false


# ---------------------------------------------------------------------------
# 状态转移：优先级 + 白名单（全部数值查表）
# ---------------------------------------------------------------------------

func request_state(next_state: State) -> bool:
	var from_action: PlayerActionData = _current_action()
	var to_action: PlayerActionData = _action_by_state.get(next_state, null) as PlayerActionData
	if to_action == null:
		return false
	if current_state == State.DEATH:
		return false
	if from_action == null:
		_transition_to(next_state)
		return true
	if next_state == current_state and _is_persistent(current_state):
		return false
	if to_action.state_priority >= from_action.state_priority:
		_transition_to(next_state)
		return true
	# 低优先级请求：仅在当前动作结束或处于取消窗口、且目标在白名单内时放行。
	# 取消窗口 = [total - cancel_window_frames, total) 左闭右开。
	var total: int = _total_frames(from_action)
	var cancel_start: int = total - from_action.cancel_window_frames
	var in_cancel_window: bool = from_action.cancel_window_frames > 0 \
		and state_frame >= cancel_start and state_frame < total
	if (state_frame >= total or in_cancel_window) \
		and from_action.can_cancel_into.has(to_action.state_name):
		_transition_to(next_state)
		return true
	return false


func _transition_to(next_state: State) -> void:
	var previous: State = current_state
	if previous == next_state:
		return
	_exit_state(previous)
	current_state = next_state
	state_frame = 0
	_enter_state(next_state)
	state_changed.emit(previous, next_state)


func _enter_state(s: State) -> void:
	var action: PlayerActionData = _action_by_state.get(s, null) as PlayerActionData
	if action == null:
		return
	_hit_targets.clear()
	_was_invulnerable = false
	_apply_pose(action)
	match s:
		State.ROLL:
			# 无敌帧的实际判定统一走 is_invulnerable()，此处不写死帧数。
			pass
		State.ATTACK_LIGHT, State.ATTACK_HEAVY:
			# 命中判定区间 [startup, startup + active) 左闭右开，见 is_in_hit_window()。
			pass
		State.HITSTUN:
			pass
		State.DEATH:
			death_confirmed.emit()
		_:
			pass


func _exit_state(s: State) -> void:
	var action: PlayerActionData = _action_by_state.get(s, null) as PlayerActionData
	if action == null:
		return
	_hit_targets.clear()
	if _was_invulnerable:
		invulnerability_changed.emit(false)
		_was_invulnerable = false


# ---------------------------------------------------------------------------
# 帧判定（区间一律左闭右开）
# ---------------------------------------------------------------------------

func is_invulnerable() -> bool:
	## E-7：无敌区间 [invulnerable_start_frame, invulnerable_end_frame)
	## 翻滚自洽等式：start == startup_frames，end == startup_frames + active_frames，
	## total == startup + active + recovery。非无敌动作两端为 -1，判定自动关闭。
	var a: PlayerActionData = _current_action()
	if a == null:
		return false
	if a.invulnerable_start_frame < 0 or a.invulnerable_end_frame <= a.invulnerable_start_frame:
		return false
	return state_frame >= a.invulnerable_start_frame and state_frame < a.invulnerable_end_frame


func is_in_hit_window() -> bool:
	## 攻击判定帧区间 [startup_frames, startup_frames + active_frames) 左闭右开。
	var a: PlayerActionData = _current_action()
	if a == null or a.motion_multiplier <= 0.0:
		return false
	return state_frame >= a.startup_frames and state_frame < a.startup_frames + a.active_frames


func frame_to_seconds(action: PlayerActionData, frames: int) -> float:
	return float(frames) / float(action.logic_fps)


func register_hit(target_id: String) -> bool:
	## 同一动作内对同一目标只结算一次。
	if _hit_targets.has(target_id):
		return false
	_hit_targets[target_id] = true
	return true


# ---------------------------------------------------------------------------
# I-4：只调 set_pose()，pose 名与帧索引全部来自数据表
# ---------------------------------------------------------------------------

func _apply_pose(action: PlayerActionData) -> void:
	if _sprite == null or not _sprite.has_method("set_pose"):
		return
	var frame_index: int = action.pose_frame_offset + state_frame
	_sprite.call("set_pose", action.pose_name, frame_index)
	## Boss 二阶段的 pose_prefix 拼接、SpriteFrames 替换入口归属见 README.md Q1；
	## 本状态机不触碰 1 号的精灵表、billboard、锚定与缩放。


# ---------------------------------------------------------------------------
# I-1：世界状态只经 WorldState.get_flag / set_flag
# ---------------------------------------------------------------------------

func _resolve_world_flag_signature() -> void:
	## 契约写 get_flag(key)，任务书 §5 写 get_flag(key, default)。此处做一次签名兼容，
	## 不私改接口；最终口径见 README.md Q2。
	if _world_state == null or not _world_state.has_method("get_flag"):
		return
	for info in _world_state.get_method_list():
		if String(info.get("name", "")) == "get_flag":
			var args: Array = info.get("args", [])
			_flag_get_argc = args.size()
			return


func _read_world_flag(key: String, default_value: Variant) -> Variant:
	if _world_state == null or not _world_state.has_method("get_flag"):
		return default_value
	if _flag_get_argc >= 2:
		return _world_state.callv("get_flag", [key, default_value])
	return _world_state.callv("get_flag", [key])


func _write_world_flag(key: String, value: Variant) -> void:
	## 严禁用于 defeated_flag_key：击败记录由 I-2 信号交由 3 号写入 Delta。
	## 本函数仅供 M5 缓存运行时战斗态（如阶段号），不触碰存档文件与 SaveDelta。
	if key.ends_with(".defeated"):
		push_error("PlayerStateMachine: 击败 flag 只能由 3 号经 I-2 写入，2 号禁止写 -> %s" % key)
		return
	if _world_state != null and _world_state.has_method("set_flag"):
		_world_state.callv("set_flag", [key, value])


# ---------------------------------------------------------------------------
# I-2：2 号 → 3 号。全模块唯一发射点，Boss / 普通敌人击杀结算都调这里。
# ---------------------------------------------------------------------------

func report_defeat(instance_id: String, is_boss: bool) -> void:
	## instance_id：优先 SpawnRequest.enemy_instance_id，缺省时回退 EnemyData / BossData.id。
	## 3 号订阅 enemy_defeated / boss_defeated 后写 SaveDelta；2 号不 set_flag、不写存档。
	if is_boss:
		boss_defeated.emit(instance_id)
	else:
		enemy_defeated.emit(instance_id)


# ---------------------------------------------------------------------------
# 查表结算：所有入参由调用方从数据表字段取得，本文件不注入任何数值
# ---------------------------------------------------------------------------

## A = BossData / EnemyData.base_attack 或 PlayerActionData.base_attack
## M = MoveData.motion_multiplier 或 PlayerActionData.motion_multiplier
## P = PhaseData.phase_damage_multiplier
## S = PoiseConfig.stance_break_damage_multiplier（未崩坏时由调用方给 1.0）
## D = base_defense + PhaseData.phase_defense
func compute_damage(
	attack_power: float,
	move_multiplier: float,
	phase_multiplier: float,
	stance_break_multiplier: float,
	defense: float
) -> float:
	## 伤害 = A × M × P × S − D，下限 MIN_DAMAGE。
	var raw: float = attack_power * move_multiplier * phase_multiplier * stance_break_multiplier - defense
	return maxf(MIN_DAMAGE, raw)


func emit_damage(target_id: String, amount: float, damage_type: String) -> void:
	damage_dealt.emit(target_id, amount, damage_type)


func emit_poise_damage(target_id: String, poise_damage: float) -> void:
	## poise_damage 来自 MoveData.poise_damage / PlayerActionData.poise_damage
	poise_damage_dealt.emit(target_id, poise_damage)


func compute_effective_status_threshold(buildup: StatusBuildup, accumulated_resistance: float, phase_resistance_multiplier: float) -> float:
	## 实际阈值 = (threshold + 累计抗性) × PhaseData.status_resistance_multiplier
	return (buildup.threshold + accumulated_resistance) * phase_resistance_multiplier


func compute_status_trigger_damage(buildup: StatusBuildup, target_max_hp: float) -> float:
	## 异常触发伤害不吃招式倍率与阶段倍率（避免乘法套娃）
	return maxf(MIN_DAMAGE, target_max_hp * buildup.trigger_damage_ratio + buildup.trigger_damage_flat)
