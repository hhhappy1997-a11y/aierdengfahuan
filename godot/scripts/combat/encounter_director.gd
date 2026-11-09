extends Node
class_name EncounterDirector

## v0.1.0 · 单次遭遇战导演层（新增）。
## 挂载：res://scenes/encounter_v010.tscn 的根节点 EncounterRoot。
## 职责：统一 _physics_process 驱动玩家帧状态机 + 复用 BossController，
##       消费输入、判定命中与免伤、维护血量、赐福休息、胜负结算、刷新 HUD。
## 复用边界：BossController / CombatResolver / CombatEventBus / GameEvents /
##           SaveDeltaWriter 全部既有件零改动；本脚本不写 flag、不写存档、
##           不定义战斗数值（数值来自 .tres 与 @export 可调常量）。
## 依据 docs.godotengine.org/en/stable/classes/class_node.html（Godot 4.x）：
##   _physics_process 走固定 60 拍，与 PlayerActionData.logic_fps 对齐；
##   _unhandled_input 在 gui_input/Control 之后接收，避免与 HUD 抢输入。
## 降级：任一复用件缺失时 push_warning 并继续可测，不崩溃、不伪造信号。

signal encounter_finished(won: bool)
signal grace_rested(rest_count: int)

@export var player_table_path: String = "res://data/combat/player_actions.tres"
@export var boss_data_path: String = "res://data/combat/boss_01_margit.tres"
@export var player_max_hp: float = 100.0
@export var incoming_damage: float = 12.0
@export var boss_path: NodePath = ^"Boss"
@export var resolver_path: NodePath = ^"CombatResolver"
@export var hud_label_path: NodePath = ^"HUD/StatusLabel"
## 自测隔离开关：false 时导演不推进 Boss AI，避免随机招式干扰帧级断言。
## 运行时恒为 true；仅 L2 自测置 false，不改任何数值口径。
@export var simulate_boss: bool = true

var _state: PlayerActionState = null
var _table: Resource = null
var _boss_data: BossData = null
var _boss: Node = null
var _resolver: Node = null
var _label: Label = null

var _player_hp: float = 0.0
var _outcome: int = -1                 # -1 进行中 / 0 败北 / 1 胜利
var _hits_taken: int = 0
var _dodges: int = 0
var _hits_landed: int = 0
var _grace_rests: int = 0
var _last_attack_id: String = ""
var _connected_boss: Node = null


func _ready() -> void:
	_table = load(player_table_path) as Resource
	_boss_data = load(boss_data_path) as BossData
	_state = PlayerActionState.new(_table)
	_player_hp = player_max_hp
	_boss = get_node_or_null(boss_path)
	_resolver = get_node_or_null(resolver_path)
	_label = get_node_or_null(hud_label_path) as Label

	if _boss == null:
		push_warning("[Encounter] Boss 节点缺失，Boss 侧逻辑降级为不可用")
	else:
		# BossController 自带 _physics_process；关掉它，统一由本导演按固定拍驱动，
		# 避免同一帧被推进两次导致招式帧与冷却错乱。
		_boss.set_physics_process(false)
		if _boss.has_method("set_boss_position"):
			_boss.call("set_boss_position", Vector3.ZERO)
		if _boss.has_method("set_target_position"):
			_boss.call("set_target_position", Vector3.ZERO)
		if _boss.has_signal("move_landed"):
			var cb: Callable = Callable(self, "_on_boss_move_landed")
			if not _boss.is_connected("move_landed", cb):
				_boss.connect("move_landed", cb)
			_connected_boss = _boss
	if _boss_data == null:
		push_warning("[Encounter] boss_data 未加载，防御/掉落数值走 0 降级")
	_update_hud()


func _exit_tree() -> void:
	# 生命周期铁律：信号连接必须有释放路径，场景卸载后不留悬空 Callable。
	if _connected_boss != null and is_instance_valid(_connected_boss):
		var cb: Callable = Callable(self, "_on_boss_move_landed")
		if _connected_boss.has_signal("move_landed") and _connected_boss.is_connected("move_landed", cb):
			_connected_boss.disconnect("move_landed", cb)
	_connected_boss = null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("roll"):
		_request_action("roll")
	elif event.is_action_pressed("light_attack"):
		_request_action("attack_light")
	elif event.is_action_pressed("heavy_attack"):
		_request_action("attack_heavy")
	elif event.is_action_pressed("interact"):
		_grace_rest()


func _physics_process(delta: float) -> void:
	_step(delta)


## 一个固定逻辑拍。抽出来供自测按帧推进，保证自测与运行走完全相同代码路径。
func _step(delta: float) -> void:
	if _outcome >= 0 or _state == null:
		return
	_state.tick()
	_try_player_hit()
	if simulate_boss and _boss != null and _boss.has_method("advance"):
		_boss.call("advance", delta)
		if _boss.has_method("get_hp_ratio") and float(_boss.call("get_hp_ratio")) <= 0.0:
			_finish(true)
	_update_hud()


func _request_action(pose_name: String) -> bool:
	if _state == null or _outcome >= 0:
		return false
	var accepted: bool = _state.request(pose_name)
	if accepted:
		_last_attack_id = ""
	return accepted


## 玩家攻击命中：只在 active 窗口首帧结算一次，防止连击被重复计伤。
func _try_player_hit() -> void:
	if _state == null or not _state.in_active_window():
		return
	var action: PlayerActionData = _state.get_current()
	if action == null or action.base_attack <= 0.0:
		return
	if _state.get_frame() != action.startup_frames or _last_attack_id == action.id:
		return
	_last_attack_id = action.id
	var damage: float = _compute_damage(action)
	if _boss != null and _boss.has_method("apply_damage"):
		_boss.call("apply_damage", damage)
		_hits_landed += 1


func _compute_damage(action: PlayerActionData) -> float:
	var defense: float = _boss_data.base_defense if _boss_data != null else 0.0
	var multiplier: float = action.motion_multiplier if action.motion_multiplier > 0.0 else 1.0
	# 复用既有 CombatResolver.compute_damage（A×M×P×S−D，下限 1）；
	# 缺失时降级为同式直算，不引入新数值口径。
	if _resolver != null and _resolver.has_method("compute_damage"):
		return float(_resolver.call("compute_damage", action.base_attack, multiplier, 1.0, 1.0, defense))
	return maxf(1.0, action.base_attack * multiplier - defense)


## BossController.move_landed 的落点。参数用 Variant 承接，兼容既有信号声明。
func _on_boss_move_landed(_defeat_id: String, _move: Variant, _attacker: Variant) -> void:
	if _outcome >= 0 or _state == null:
		return
	if _state.is_invulnerable():
		_dodges += 1
		return
	_player_hp = maxf(0.0, _player_hp - incoming_damage)
	_hits_taken += 1
	if _player_hp <= 0.0:
		_finish(false)


func _finish(won: bool) -> void:
	_outcome = 1 if won else 0
	encounter_finished.emit(won)
	# 胜利不重复 commit：BossController._die → CombatEventBus → GameEvents
	# → SaveDeltaWriter._on_boss_defeated 已完成 I-2 落盘；只有败北补一次。
	if not won:
		_commit("encounter_v010_defeat")
	_update_hud()


func _grace_rest() -> void:
	if _state == null:
		return
	_player_hp = player_max_hp
	_state.reset()
	_last_attack_id = ""
	_outcome = -1
	_grace_rests += 1
	_commit("grace_rest")
	grace_rested.emit(_grace_rests)
	_update_hud()


func _commit(reason: String) -> void:
	# 用 get_tree().root 相对查找，不写 /root/... 绝对路径：
	# 运行时等价，且在 --script / SceneTree 验证模式下不会触发
	# "Can't use get_node() with absolute paths from outside the active scene tree"。
	# 用 Engine.get_main_loop() 而非 get_tree()：SceneTree --script 验证模式下
	# 节点的 data.tree 尚未赋值，get_tree() 会报 "Parameter data.tree is null"。
	var loop: MainLoop = Engine.get_main_loop()
	var writer: Node = null
	if loop is SceneTree:
		writer = (loop as SceneTree).root.get_node_or_null("SaveDeltaWriter")
	if writer == null:
		push_warning("[Encounter] SaveDeltaWriter 不可用，跳过落盘：%s" % reason)
		return
	if writer.has_method("commit"):
		writer.call("commit", reason)


func _update_hud() -> void:
	if _label == null:
		return
	var ratio: float = 0.0
	if _boss != null and _boss.has_method("get_hp_ratio"):
		ratio = float(_boss.call("get_hp_ratio"))
	var status: String = "进行中"
	if _outcome == 1:
		status = "胜利 · 已落盘"
	elif _outcome == 0:
		status = "败北 · 按 E 赐福休息"
	_label.text = "玩家 HP %d/%d  ｜  Boss HP %d%%  ｜  动作 %s %d/%d  ｜  闪避 %d  ｜  命中 %d  ｜  %s" % [
		int(_player_hp), int(player_max_hp), int(ratio * 100.0),
		_state.get_current_pose() if _state != null else "idle",
		_state.get_frame() if _state != null else 0,
		_state.get_total() if _state != null else 0,
		_dodges, _hits_landed, status]


# ---- 集成层只读 / 驱动接口（供 HUD、自测与运行日志；非探针，不含数值口径） ----

func debug_request_action(pose_name: String) -> bool:
	return _request_action(pose_name)


func debug_boss_hit() -> void:
	_on_boss_move_landed("debug", null, null)


func debug_step(frames: int, delta: float = 1.0 / 60.0) -> void:
	for _i: int in range(maxi(0, frames)):
		_step(delta)


func debug_kill_boss() -> void:
	if _boss != null and _boss.has_method("apply_damage"):
		_boss.call("apply_damage", 1.0e9)
		_finish(true)


func debug_grace_rest() -> void:
	_grace_rest()


func get_snapshot() -> Dictionary:
	return {
		"player_hp": _player_hp,
		"outcome": _outcome,
		"hits_taken": _hits_taken,
		"dodges": _dodges,
		"hits_landed": _hits_landed,
		"grace_rests": _grace_rests,
		"frame": _state.get_frame() if _state != null else -1,
		"pose": _state.get_current_pose() if _state != null else "idle",
		"boss_hp_ratio": float(_boss.call("get_hp_ratio")) if _boss != null and _boss.has_method("get_hp_ratio") else -1.0,
	}
