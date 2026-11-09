extends RefCounted
class_name PlayerActionState

## v0.1.0 · 玩家动作帧状态机（纯逻辑，可脱离场景树单测）。
## 数据唯一真源：res://data/combat/player_actions.tres 的 8 条 PlayerActionData。
## E-7 口径：无敌区间 [invulnerable_start_frame, invulnerable_end_frame) 左闭右开；
## logic_fps=60 与 project.godot common/physics_ticks_per_second=60 对齐，
## 因此 _physics_process 每拍 = 1 逻辑帧，不用 delta 累加，避免浮点漂移。
## 依据 docs.godotengine.org/en/stable/classes/class_refcounted.html（Godot 4.x）。
## 设计意图：只管帧与窗口，不碰伤害、不碰节点，方便 L2 断言覆盖正常/边界/异常。

const LOGIC_FPS: int = 60
const DEFAULT_POSE: String = "idle"

var _table: Resource = null
var _current: PlayerActionData = null
var _frame: int = 0
var _total: int = 0
var _busy: bool = false


func _init(table: Resource = null) -> void:
	_table = table


func set_table(table: Resource) -> void:
	_table = table
	reset()


func get_table() -> Resource:
	return _table


## 按 pose_name 请求动作；忙时拒绝，防止同帧重复触发（并发/连点防护）。
func request(pose_name: String) -> bool:
	if _busy or _table == null:
		return false
	var action: PlayerActionData = _find_action(pose_name)
	if action == null:
		return false
	_current = action
	_frame = 0
	_total = action.startup_frames + action.active_frames + action.recovery_frames
	_busy = true
	return true


## 推进一个逻辑帧；total 到点后回 idle。外部统一由导演层按 60 拍/秒调用。
func tick() -> void:
	if not _busy or _current == null:
		return
	_frame += 1
	if _frame >= _total:
		reset()


func reset() -> void:
	_current = null
	_frame = 0
	_total = 0
	_busy = false


## E-7 左闭右开；未配置（start<0 或 end<=start）视为无无敌帧。
func is_invulnerable() -> bool:
	if not _busy or _current == null:
		return false
	var s: int = _current.invulnerable_start_frame
	var e: int = _current.invulnerable_end_frame
	if s < 0 or e <= s:
		return false
	return _frame >= s and _frame < e


## 攻击判定窗口 [startup, startup+active)，只有攻击类动作有意义。
func in_active_window() -> bool:
	if not _busy or _current == null:
		return false
	var begin: int = _current.startup_frames
	var end: int = begin + _current.active_frames
	return _frame >= begin and _frame < end


func is_busy() -> bool:
	return _busy


func get_frame() -> int:
	return _frame


func get_total() -> int:
	return _total


func get_current() -> PlayerActionData:
	return _current


func get_current_pose() -> String:
	return _current.pose_name if _current != null else DEFAULT_POSE


func _find_action(pose_name: String) -> PlayerActionData:
	if _table == null:
		return null
	var raw: Variant = _table.get("actions")
	if not raw is Array:
		return null
	for item: Variant in raw:
		var action: PlayerActionData = item as PlayerActionData
		if action != null and action.pose_name == pose_name:
			return action
	return null
