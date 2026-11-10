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
##
## v0.2.0 P1 · 本轮 [ROUND=R24] 扩展（保持 v0.1.0 的 20 条断言与 debug_* 签名不变）：
##   ① 赐福休息真正重置 Boss —— 采用「重新实例化 Boss 子节点替换」：全新实例
##      天然 _defeated=false / _hp=max_hp / 阶段 1 / 冷却与招式帧清空；只复制
##      Boss 节点公开 @export 配置，不改 BossController 既有件、不碰私有状态字段。
##   ② 接 EncounterRulesV020 规则层（BossData.ai_poll_interval_sec 注入），
##      每帧 tick_frame、落地招式走 should_allow_move 放行门、retry_count 可观测。
##   ③ 重复挑战计数 rematch_count、胜负快照 wins/losses/outcome_history 进 get_snapshot()。
##   边界与取舍详见 teamwork/Rank-2/DONE-R24.md。

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

# ---- v0.2.0 新增状态（既有字段与取值口径不变） ----
var _rules: EncounterRulesV020 = null
var _rematch_count: int = 0            # 成功重置 Boss 并重复挑战的次数
var _wins: int = 0
var _losses: int = 0
var _outcome_history: Array[int] = []  # 每次结算的 1/0 快照序列
var _suppressed_moves: int = 0         # 运行时被规则层抑制的落地招式次数

# ---- R25 [ROUND=R25] 追加：A13 / GRACE-RETRY / CombatResolver 接线 ----
## 三段式 flag 的模块段 / 状态段；对象段由 EncounterRulesV020.ENCOUNTER_ID 提供
## （GRACE-RETRY-V020.md §2.3「两边统一、不改数据表 id」对齐口径）。
const FLAG_MODULE: String = "grace"
const FLAG_STATE_RETRIED: String = "retried"
const FLAG_STATE_RETRY_ACTIVE: String = "retry_active"
const COMMIT_GRACE_RETRY: String = "grace_retry"

# A13：赐福休息时只读记录的 L1 永久击败 flag 快照，绝不写回 / 不清除 / 不用 removals。
var _l1_defeat_snapshot: Dictionary = {}
var _l1_defeat_ignored: bool = false
# GRACE-RETRY 两个 flag 的运行时镜像（真值在 WorldState，镜像仅供快照观测）。
var _retried_count: int = 0
var _retry_active: bool = false
# CombatResolver 接线：全部为 L3 运行时状态，不进任何 flag / SaveDelta。
var _boss_poise: float = 0.0
var _poise_break_remaining_sec: float = 0.0
var _poise_since_last_hit_sec: float = 0.0
var _last_poise_after_hit: float = 0.0
var _status_current: Dictionary = {}
var _status_resistance: Dictionary = {}
var _status_since_last_sec: Dictionary = {}
var _execute_available: bool = false


func _ready() -> void:
	_table = load(player_table_path) as Resource
	_boss_data = load(boss_data_path) as BossData
	_state = PlayerActionState.new(_table)
	_player_hp = player_max_hp
	_boss = get_node_or_null(boss_path)
	_resolver = get_node_or_null(resolver_path)
	_label = get_node_or_null(hud_label_path) as Label
	# v0.2.0：规则层用 BossData.ai_poll_interval_sec 注入（数据驱动，不硬编码帧数）。
	_rules = EncounterRulesV020.new(
		_boss_data.ai_poll_interval_sec if _boss_data != null else 0.0,
		float(PlayerActionState.LOGIC_FPS))

	if _boss == null:
		push_warning("[Encounter] Boss 节点缺失，Boss 侧逻辑降级为不可用")
	else:
		# BossController 自带 _physics_process；关掉它，统一由本导演按固定拍驱动，
		# 避免同一帧被推进两次导致招式帧与冷却错乱。
		_bind_boss(_boss)
	if _boss_data == null:
		push_warning("[Encounter] boss_data 未加载，防御/掉落数值走 0 降级")
	_init_combat_state()
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
		if _rules != null:
			_rules.tick_frame(delta)
		_boss.call("advance", delta)
		if _boss.has_method("get_hp_ratio") and float(_boss.call("get_hp_ratio")) <= 0.0:
			_finish(true)
	_tick_combat_state(delta)
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
		_resolve_poise_on_hit(action)
		_apply_action_status(action)


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
	# v0.2.0：仅当携带 MoveData（BossController 真实落地）时接入数据驱动规则层；
	# debug_boss_hit() 传 null，完全走 v0.1.0 既有结算，保证 20 条断言不回退。
	if _move is MoveData and _rules != null:
		var mv: MoveData = _move
		if not report_boss_move(mv.id, mv.cooldown_sec):
			_suppressed_moves += 1
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
	if won:
		_wins += 1
	else:
		_losses += 1
	_outcome_history.append(_outcome)
	encounter_finished.emit(won)
	# 胜利不重复 commit：BossController._die → CombatEventBus → GameEvents
	# → SaveDeltaWriter._on_boss_defeated 已完成 I-2 落盘；只有败北补一次。
	if not won:
		_commit("encounter_v010_defeat")
	finish_grace_retry()
	_update_hud()


func _grace_rest() -> void:
	if _state == null:
		return
	_player_hp = player_max_hp
	_state.reset()
	_last_attack_id = ""
	_outcome = -1
	_grace_rests += 1
	# A13 [ROUND=R25]：只读记录 L1 永久击败 flag（world/combat 两个 key），
	# 绝不据其阻止重打、绝不写回、绝不清除、不写 removals。
	_l1_defeat_snapshot = _read_l1_defeat_flags()
	# v0.2.0：赐福休息真正重置 Boss（HP 回满 / 阶段回 1 / 清除击败态）。
	if _respawn_boss():
		_rematch_count += 1
		_l1_defeat_ignored = _l1_snapshot_has_defeat()
	if _rules != null:
		_rules.reset_for_rematch()
	_commit("grace_rest")
	grace_rested.emit(_grace_rests)
	_update_hud()


## v0.2.0：赐福休息真正重置 Boss —— 采用「重新实例化 Boss 子节点替换」。
## 不改 BossController 既有件；全新实例天然 _defeated=false / _hp=max_hp /
## 阶段 1 / 冷却字典与招式帧清空。只复制公开 @export 配置，不碰任何私有状态字段。
## 返回是否成功重建（Boss 缺失 / 无父节点 / 无脚本时降级返回 false，不崩）。
func _respawn_boss() -> bool:
	if _boss == null or not is_instance_valid(_boss):
		return false
	var old: Node = _boss
	var parent: Node = old.get_parent()
	var boss_script: Script = old.get_script() as Script
	if parent == null or boss_script == null:
		push_warning("[Encounter] Boss 父节点或脚本缺失，跳过重建，仅重置玩家侧")
		return false
	# 先复制公开 @export 配置（含数据表与依赖路径），再释放旧实例。
	var boss_name: String = str(old.name)
	var cfg: Dictionary = {}
	for key: String in ["boss_data", "sprite_path", "event_bus_path", "world_state_path"]:
		cfg[key] = old.get(key)
	# 断开旧信号连接，避免旧实例释放后 _exit_tree 误判悬空 Callable。
	if old.has_signal("move_landed"):
		var cb_old: Callable = Callable(self, "_on_boss_move_landed")
		if old.is_connected("move_landed", cb_old):
			old.disconnect("move_landed", cb_old)
	_connected_boss = null
	# 节点类型必须在 free() 之前取，避免 use-after-free。
	var is_3d: bool = old is Node3D
	parent.remove_child(old)
	old.free()
	# 新实例沿用旧节点的引擎类型（encounter_v010.tscn 的 Boss 为 Node3D）；
	# 非 3D 时降级为 Node —— BossController extends Node，逻辑不依赖 Node3D。
	var fresh: Node = Node3D.new() if is_3d else Node.new()
	fresh.name = boss_name
	fresh.set_script(boss_script)
	for key: String in cfg.keys():
		fresh.set(key, cfg[key])
	# A13 [ROUND=R25]：赐福休息重建的是 L3 运行时实例，必须忽略 L1 永久击败 flag。
	# BossController._ready() 读 boss_data.defeated_flag_key（world.<id>.defeated），
	# 为 true 会保持 IDLE 不再进战斗。这里只给运行时实例一份「去掉 L1 就绪 key」的
	# 数据表副本（数值逐字复制自原表，数据驱动不变），使本次遭遇可重打；
	# 绝不清除 world/combat 永久击败记录、不写 removals、不改任何数据表文件。
	var src_data: BossData = fresh.get("boss_data") as BossData
	if src_data != null:
		var rt_data: BossData = src_data.duplicate() as BossData
		rt_data.defeated_flag_key = ""
		fresh.set("boss_data", rt_data)
	parent.add_child(fresh)
	# --script / SceneTree 模式 add_child 不 flush _ready；is_node_ready() 为假时
	# 显式补一次。真实运行时 add_child 已触发 _ready，跳过，避免重复初始化。
	if not fresh.is_node_ready():
		fresh.call("_ready")
	# 回填 --script 模式下 /root/... 绝对路径不可解析的依赖（不改既有件文件）。
	_inject_boss_deps(fresh)
	_boss = fresh
	_bind_boss(fresh)
	return true


## 仅 --script / SceneTree 验证模式需要：BossController._ready 里
## world_state_path = ^"/root/WorldState" 绝对路径在该模式不可解析。
## 从 Engine.get_main_loop().root 与场景兄弟节点回填等价引用，业务代码零改动。
func _inject_boss_deps(node: Node) -> void:
	var loop: MainLoop = Engine.get_main_loop()
	if not loop is SceneTree:
		return
	var tree_root: Node = (loop as SceneTree).root
	if tree_root == null:
		return
	var ws: Node = tree_root.get_node_or_null("WorldState")
	if ws != null:
		node.set("_world_state", ws)
	var parent: Node = node.get_parent()
	if parent != null:
		var bus: Node = parent.get_node_or_null("CombatEventBus")
		if bus != null:
			node.set("_event_bus", bus)


## 统一装配 Boss 节点（_ready 与赐福重建共用）：关掉自带物理推进、
## 摆位归零、连接 move_landed，保证导演按固定拍唯一驱动。
func _bind_boss(node: Node) -> void:
	node.set_physics_process(false)
	if node.has_method("set_boss_position"):
		node.call("set_boss_position", Vector3.ZERO)
	if node.has_method("set_target_position"):
		node.call("set_target_position", Vector3.ZERO)
	if node.has_signal("move_landed"):
		var cb: Callable = Callable(self, "_on_boss_move_landed")
		if not node.is_connected("move_landed", cb):
			node.connect("move_landed", cb)
		_connected_boss = node


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
# v0.1.0 的 debug_* 签名逐字保持不变；v0.2.0 只新增非 debug 的 report_boss_move。

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


## v0.2.0：把一次 Boss 招式交给数据驱动规则层，返回是否放行（连续同名返回 false）。
## fps<=0 时规则层用自身构造帧率（PlayerActionState.LOGIC_FPS），导演层不硬编码帧数。
func report_boss_move(move_id: String, cooldown_sec: float, fps: float = -1.0) -> bool:
	if _rules == null:
		return true
	return _rules.should_allow_move(_rules.last_move_id, move_id, cooldown_sec, fps)


func get_snapshot() -> Dictionary:
	var ratio: float = float(_boss.call("get_hp_ratio")) if _boss != null and _boss.has_method("get_hp_ratio") else -1.0
	var phase: int = int(_boss.call("get_phase_index")) if _boss != null and _boss.has_method("get_phase_index") else -1
	return {
		"player_hp": _player_hp,
		"outcome": _outcome,
		"hits_taken": _hits_taken,
		"dodges": _dodges,
		"hits_landed": _hits_landed,
		"grace_rests": _grace_rests,
		"frame": _state.get_frame() if _state != null else -1,
		"pose": _state.get_current_pose() if _state != null else "idle",
		"boss_hp_ratio": ratio,
		# ---- v0.2.0 追加（既有 10 个键名与取值口径不变） ----
		"rematch_count": _rematch_count,
		"wins": _wins,
		"losses": _losses,
		"outcome_history": _outcome_history.duplicate(),
		"retry_count": _rules.retry_count if _rules != null else 0,
		"last_move_id": _rules.last_move_id if _rules != null else "",
		"suppressed_moves": _suppressed_moves,
		"boss_phase": phase,
		"boss_defeated": ratio <= 0.0 and _boss != null,
		# ---- R25 追加（既有键名与取值口径不变） ----
		"l1_defeat_keys": get_l1_defeat_keys(),
		"l1_defeat_snapshot": _l1_defeat_snapshot.duplicate(),
		"l1_defeat_ignored": _l1_defeat_ignored,
		"retried_count": _retried_count,
		"retry_active": _retry_active,
		"boss_poise": _boss_poise,
		"poise_break_remaining_sec": _poise_break_remaining_sec,
		"last_poise_after_hit": _last_poise_after_hit,
		"execute_available": _execute_available,
		"status_current": _status_current.duplicate(),
	}


# ===========================================================================
# R25 [ROUND=R25] 追加：A13 落地 / GRACE-RETRY 两个三段式 flag /
#   CombatResolver 既有能力接线（削韧 / 异常 / 处决）。
#   既有 v0.1.0 20 条 + v0.2.0 45 条断言与 debug_* 签名逐字不变。
# ===========================================================================

## I-1：经 Engine.get_main_loop() 取 WorldState，与 _commit() 同一装配口径，
## --script / SceneTree 验证模式下不触发绝对路径解析错误。
func _get_world_state() -> Node:
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("WorldState")
	return null


## 两个三段式 flag 的 key（对象段统一由 EncounterRulesV020.ENCOUNTER_ID 提供）。
func flag_retried_key() -> String:
	return "%s.%s.%s" % [FLAG_MODULE, EncounterRulesV020.ENCOUNTER_ID, FLAG_STATE_RETRIED]


func flag_retry_active_key() -> String:
	return "%s.%s.%s" % [FLAG_MODULE, EncounterRulesV020.ENCOUNTER_ID, FLAG_STATE_RETRY_ACTIVE]


## A13：L1 永久击败 flag 的两个 key，全部来自数据表 / 数据表 id，不硬编码 id。
func get_l1_defeat_keys() -> Array[String]:
	var keys: Array[String] = []
	if _boss_data != null:
		if not _boss_data.defeated_flag_key.is_empty():
			keys.append(_boss_data.defeated_flag_key)
		keys.append("combat.%s.defeated" % _boss_data.id)
	return keys


## A13：只读取 L1 flag 值，绝不写回、绝不清除、绝不进 removals。
func _read_l1_defeat_flags() -> Dictionary:
	var ws: Node = _get_world_state()
	var result: Dictionary = {}
	for k in get_l1_defeat_keys():
		var v: bool = false
		if ws != null and ws.has_method("get_flag"):
			v = bool(ws.call("get_flag", k, false))
		result[k] = v
	return result


func _l1_snapshot_has_defeat() -> bool:
	for k in _l1_defeat_snapshot.keys():
		if bool(_l1_defeat_snapshot[k]):
			return true
	return false


## 任务 ②：发起一次「重复挑战」。顺序严格按 GRACE-RETRY-V020.md §4.2：
##   先 set_flag 两个三段式 key → commit("grace_retry") 强制落盘 → 才改 L3 运行时实例。
## 门控：retry_active == true 时拒绝（回合内防重复发起），retried 单调递增不回退。
func start_grace_retry() -> bool:
	if _state == null:
		return false
	var ws: Node = _get_world_state()
	if ws == null or not ws.has_method("set_flag"):
		push_warning("[Encounter] WorldState 不可用，重复挑战未发起")
		return false
	if bool(ws.call("get_flag", flag_retry_active_key(), false)):
		return false
	var n: int = int(ws.call("get_flag", flag_retried_key(), 0)) + 1
	ws.call("set_flag", flag_retried_key(), n)
	ws.call("set_flag", flag_retry_active_key(), true)
	_commit(COMMIT_GRACE_RETRY)          # ★ 先落盘
	# 落盘后才改运行时实例（HP / 状态机 / Boss / 规则层 / outcome）。
	_reset_runtime_for_retry()
	_retried_count = n
	_retry_active = true
	return true


## 任务 ②：结算（胜 / 败 / 退出）清理回合并先落盘，再释放运行时状态。
func finish_grace_retry() -> void:
	if not _retry_active:
		return
	var ws: Node = _get_world_state()
	if ws != null and ws.has_method("set_flag"):
		ws.call("set_flag", flag_retry_active_key(), false)
	_commit(COMMIT_GRACE_RETRY)          # ★ 结算清理先落盘
	_retry_active = false


func _reset_runtime_for_retry() -> void:
	_player_hp = player_max_hp
	if _state != null:
		_state.reset()
	_last_attack_id = ""
	_outcome = -1
	_l1_defeat_snapshot = _read_l1_defeat_flags()
	if _respawn_boss():
		_rematch_count += 1
		_l1_defeat_ignored = _l1_snapshot_has_defeat()
	if _rules != null:
		_rules.reset_for_rematch()
	_init_combat_state()


# ---------------------------------------------------------------------------
# 任务 ③：接 CombatResolver 既有能力到导演层。数值全部来自数据表
#   （BossData / PhaseData / PoiseConfig / StatusBuildup / PlayerActionData / MoveData），
#   或由调用方从数据表取得后传入；代码内零战斗数值硬编码。
# ---------------------------------------------------------------------------

## 当前阶段的韧性配置：阶段 override 优先，否则 Boss 顶层 poise（全部数据表）。
func _active_poise_config() -> PoiseConfig:
	if _boss_data == null:
		return null
	var idx: int = 0
	if _boss != null and _boss.has_method("get_phase_index"):
		idx = int(_boss.call("get_phase_index")) - 1
	if idx >= 0 and idx < _boss_data.phases.size():
		var ph: PhaseData = _boss_data.phases[idx] as PhaseData
		if ph != null and ph.poise_override != null:
			return ph.poise_override
	return _boss_data.poise


func _init_combat_state() -> void:
	_boss_poise = 0.0
	_poise_break_remaining_sec = 0.0
	_poise_since_last_hit_sec = 0.0
	_last_poise_after_hit = 0.0
	_status_current = {}
	_status_resistance = {}
	_status_since_last_sec = {}
	_execute_available = false
	if _boss_data == null:
		return
	var cfg: PoiseConfig = _active_poise_config()
	if cfg != null:
		_boss_poise = cfg.max_poise
		_last_poise_after_hit = cfg.max_poise
	for entry in _boss_data.status_buildups:
		var sb: StatusBuildup = entry as StatusBuildup
		if sb == null:
			continue
		_status_current[sb.status_type] = 0.0
		_status_resistance[sb.status_type] = 0.0
		_status_since_last_sec[sb.status_type] = 0.0


## 削韧：compute_poise_after_hit + resolve_poise（poise_damage 来自数据表动作字段）。
func _resolve_poise(poise_damage: float) -> Dictionary:
	if _resolver == null or _boss_data == null:
		return {}
	var cfg: PoiseConfig = _active_poise_config()
	if cfg == null:
		return {}
	if _resolver.has_method("compute_poise_after_hit"):
		_last_poise_after_hit = float(_resolver.call("compute_poise_after_hit", _boss_poise, poise_damage))
	if not _resolver.has_method("resolve_poise"):
		return {}
	var r: Dictionary = _resolver.call("resolve_poise", _boss_poise, poise_damage, cfg, _poise_break_remaining_sec)
	_boss_poise = float(r.get("poise", _boss_poise))
	_poise_break_remaining_sec = float(r.get("break_remaining_sec", _poise_break_remaining_sec))
	_execute_available = bool(r.get("stance_broken", false))
	_poise_since_last_hit_sec = 0.0
	return r


func _resolve_poise_on_hit(action: PlayerActionData) -> void:
	_resolve_poise(action.poise_damage)


## 异常：apply_status_buildup（三种 status 配置全部来自 BossData.status_buildups）。
func _apply_status(status_type: String, amount: float, dt: float) -> Dictionary:
	if _resolver == null or _boss_data == null or not _resolver.has_method("apply_status_buildup"):
		return {}
	var sb: StatusBuildup = null
	for entry in _boss_data.status_buildups:
		var cand: StatusBuildup = entry as StatusBuildup
		if cand != null and cand.status_type == status_type:
			sb = cand
			break
	if sb == null:
		return {}
	var phase_mult: float = 1.0
	if _boss != null and _boss.has_method("get_phase_index"):
		var idx: int = int(_boss.call("get_phase_index")) - 1
		if idx >= 0 and idx < _boss_data.phases.size():
			var ph: PhaseData = _boss_data.phases[idx] as PhaseData
			if ph != null:
				phase_mult = ph.status_resistance_multiplier
	var current: float = float(_status_current.get(status_type, 0.0))
	var resist: float = float(_status_resistance.get(status_type, 0.0))
	var since: float = float(_status_since_last_sec.get(status_type, 0.0))
	var r: Dictionary = _resolver.call(
		"apply_status_buildup",
		_boss_data.id, status_type, current, amount, sb, resist, phase_mult,
		_boss_data.max_hp, dt, since)
	_status_current[status_type] = float(r.get("buildup", current))
	_status_resistance[status_type] = float(r.get("accumulated_resistance", resist))
	_status_since_last_sec[status_type] = 0.0
	return r


func _apply_action_status(action: PlayerActionData) -> void:
	# 数值来自 PlayerActionData 数据表字段（本表当前三条均为 0.0，接入不虚构数值）。
	if action.status_buildup_bleed != 0.0:
		_apply_status("bleed", action.status_buildup_bleed, 0.0)
	if action.status_buildup_poison != 0.0:
		_apply_status("poison", action.status_buildup_poison, 0.0)
	if action.status_buildup_frost != 0.0:
		_apply_status("frost", action.status_buildup_frost, 0.0)


## 每逻辑帧：regen_poise 韧性回复 + 崩坏窗口倒计时 + 异常计时（全部数据表配置）。
func _tick_combat_state(delta: float) -> void:
	if _resolver == null or _boss_data == null:
		return
	var cfg: PoiseConfig = _active_poise_config()
	if cfg == null:
		return
	_poise_since_last_hit_sec += delta
	if _resolver.has_method("regen_poise"):
		_boss_poise = float(_resolver.call("regen_poise", _boss_poise, cfg, delta, _poise_since_last_hit_sec))
	_poise_break_remaining_sec = maxf(0.0, _poise_break_remaining_sec - delta)
	for k in _status_since_last_sec.keys():
		_status_since_last_sec[k] = float(_status_since_last_sec[k]) + delta


## 处决判定：can_execute（配置 / HP 比例 / 韧性 / 崩坏窗口全来自数据表与运行时；
## 判定帧、距离、命中登记按设计文档 §3.2 由调用方提供）。
func check_execute(distance_px: float, hitbox_reach_px: float, attacker_in_hit_window: bool, hit_registered: bool) -> bool:
	if _resolver == null or not _resolver.has_method("can_execute"):
		return false
	var cfg: PoiseConfig = _active_poise_config()
	if cfg == null:
		return false
	var hp_ratio: float = 0.0
	if _boss != null and _boss.has_method("get_hp_ratio"):
		hp_ratio = float(_boss.call("get_hp_ratio"))
	return bool(_resolver.call("can_execute",
		cfg, _last_poise_after_hit, _poise_break_remaining_sec, hp_ratio,
		attacker_in_hit_window, distance_px, hitbox_reach_px, hit_registered))


# ---- 集成层只读 / 驱动接口（供 verify_encounter_v030.gd；非探针） ----

func debug_resolve_poise(poise_damage: float) -> Dictionary:
	return _resolve_poise(poise_damage)


func debug_apply_status(status_type: String, amount: float, dt: float = 0.0) -> Dictionary:
	return _apply_status(status_type, amount, dt)


func debug_tick_combat(delta: float) -> void:
	_tick_combat_state(delta)


func debug_start_grace_retry() -> bool:
	return start_grace_retry()


func debug_finish_grace_retry() -> void:
	finish_grace_retry()
