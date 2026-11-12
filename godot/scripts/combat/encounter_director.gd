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
## R31B [ROUND=R31B] · HOST 裁决 A39：玩家命中信号，供打击反馈层订阅自动触发。
## 只新增本信号 + _try_player_hit() 内一处 emit；不改既有数值 / 判定分支 / 帧数据 / 输出格式 / 其它信号。
signal player_hit_landed(damage: int)

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
	# R34 a/b/e：生产服务创建（同步）+ 帧末跨节点装配（call_deferred 避开 busy）。
	_r34_create_services()
	call_deferred("_r34_bootstrap")


func _exit_tree() -> void:
	# 生命周期铁律：信号连接必须有释放路径，场景卸载后不留悬空 Callable。
	if _connected_boss != null and is_instance_valid(_connected_boss):
		var cb: Callable = Callable(self, "_on_boss_move_landed")
		if _connected_boss.has_signal("move_landed") and _connected_boss.is_connected("move_landed", cb):
			_connected_boss.disconnect("move_landed", cb)
	_connected_boss = null
	_r34_release()


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
	_r34_tick(delta)                      # R34 b 链：导演层每逻辑拍驱动生产服务 tick(delta)
	_update_hud()


func _request_action(pose_name: String) -> bool:
	if _state == null or _outcome >= 0:
		return false
	var accepted: bool = _state.request(pose_name)
	if accepted:
		_last_attack_id = ""
		# R27 [ROUND=R27] 动作帧 HUD 推进：请求被接受的「当帧」就把 PlayerActionState 的
		# get_current_pose()/get_frame()/get_total() 刷到底部战斗 HUD，不等下一个
		# _physics_process，确保动作帧从「idle 0/0」立即推进（R25 实机曾恒显示 idle 0/0）。
		_update_hud()
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
		_r34_last_poise = action.poise_damage   # R34 a 链：本次命中真实削韧值（数据表 poise_damage，非演示固定 100.0）
		player_hit_landed.emit(int(damage))   # R31B/A39：唯一新增 emit，供打击反馈层订阅自动触发
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
	_r34b_combo_on_hit_taken()          # R34B 任务1 c：玩家受击 → ComboService.on_hit_taken()（受击中断连击）
	if _player_hp <= 0.0:
		_finish(false)


func _finish(won: bool) -> void:
	_outcome = 1 if won else 0
	if won:
		_wins += 1
		_r34b_combo_on_boss_defeated()   # R34B 任务1 d：Boss 死亡 → ComboService.on_boss_defeated()（定格评级、此后拒绝命中）
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
	# R27：动作帧三项全部取自本导演内 PlayerActionState 的既有只读接口（pose / frame / total），
	# 显示到底部战斗 HUD；不改既有 HUD 的其它文本与四套 HUD 位置。
	var pose: String = _state.get_current_pose() if _state != null else "idle"
	var frame: int = _state.get_frame() if _state != null else 0
	var total: int = _state.get_total() if _state != null else 0
	_label.text = "玩家 HP %d/%d  ｜  Boss HP %d%%  ｜  动作 %s %d/%d  ｜  闪避 %d  ｜  命中 %d  ｜  %s" % [
		int(_player_hp), int(player_max_hp), int(ratio * 100.0),
		pose, frame, total,
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
	# R34B 任务2：effect_key=poise_damage_bonus 真实作用到本波敌人削韧计算；
	# 数值来自波次开始时运行时敌人参数（BoonDraftConfig 表值），无修正时乘 1.0 逐字等价。
	var poise_bonus: float = 0.0
	if not _r34b_enemy_params.is_empty():
		poise_bonus = float(_r34b_enemy_params.get("poise_damage_bonus", 0.0))
	_resolve_poise(action.poise_damage * (1.0 + poise_bonus))


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


# ===========================================================================
# R26 [ROUND=R26] 追加：赐福试炼波次导演桥接
#   （既有方法 / 信号 / debug_* 签名逐字未动；v010 20 / v020 45 / v030 53 PASS 不回退）
#   波次导演 wave_trial_director.gd 订阅本文件既有的 encounter_finished(won) 信号推进波次；
#   败北 / 超时后「回赐福休息」由本入口复用既有 _grace_rest() 全链路完成。
#   本段不定义任何数值、不写 flag、不改存档口径；flag 与持久化仍归 Rank-3。
# ===========================================================================

## 供波次导演编排「失败回赐福休息」：复用既有 _grace_rest()
## （HP 回满 / 状态机重置 / Boss 重建 / 落盘 / grace_rested 信号），零新数值。
func trial_grace_rest() -> void:
	_grace_rest()


# ===========================================================================
# R34 [ROUND=R34] · 生产运行时触发链 a) / b) / e)（本文件唯一写入方 = Rank-1）
#   把 R33 的「演示驱动」升级为生产运行时真实连通，不依赖 presentation.gd：
#     a) 命中 → 削韧：connect 本文件既有 player_hit_landed → _on_player_hit_landed()
#        → 真实 StaggerService.apply_hit(招式 poise_damage)（数据表值，非演示固定 100.0）；
#        同一命中转发 ComboService（Rank-2 本轮新增，鸭子类型 + 判空降级）。
#     b) 帧驱动 → tick：_step() 每逻辑拍调 _r34_tick() → StaggerService.tick(delta)
#        / ComboService.tick(delta)（生产帧驱动，替代演示逐帧显式 tick）。
#     e) 点数只发信号：处决 / 清波 / 抉择点数由 HUD 的 points_awarded 信号统一广播；
#        本导演层不 set_flag / 不 commit / 不写存档文件（I-1 归 Rank-3，A50）。
#   既有 v0.1.0 20 / v0.2.0 45 / v0.3.0 53 PASS 与全部 debug_* 签名逐字不动。
#   资源回读 CACHE_MODE_IGNORE；信号 connect 用 get_signal_connection_list 去重、
#   _exit_tree 有 disconnect 释放路径；不用 get_tree() / 不用 /root/... 绝对路径。
# ===========================================================================

const R34_STAGGER_SVC_PATH: String = "res://scripts/combat/stagger_service.gd"
const R34_STAGGER_CFG_PATH: String = "res://data/combat/stagger_rules.tres"

## 跨节点装配：导演层在 Courtyard 根下（EncounterRoot），HUD 在 SubViewport 内。
## 生产 _ready 用 call_deferred 避开 "Parent node is busy setting up children"；
## --script 验证进程显式 call("_r34_bootstrap") 同步完成同一装配（确定性）。
const R34_HUD_REL_PATH: String = "SubViewportContainer/SubViewport/FXLayer/Hud"

var _r34_stagger: Object = null            # 生产 StaggerService 实例（与 HUD 同一份）
var _r34_combo: Object = null              # 生产 ComboService（HUD 创建后注入 / 验证替身注入）
var _r34_last_poise: float = 0.0           # 本次命中真实 poise_damage（_try_player_hit 写入）
var _r34_hit_chain: int = 0                # Rank-1 侧命中链镜像（可观测，不写盘）
var _r34_combo_forward_count: int = 0      # 转发给 combo 消费方的命中计数镜像
var _r34_tick_count: int = 0
var _r34_hit_signal_connected: bool = false
var _r34_bootstrapped: bool = false
var _r34_combo_hit_method: String = ""
var _r34_combo_tick_method: String = ""

const R34_COMBO_HIT_METHODS: Array[String] = [
	"register_hit", "on_hit", "add_hit", "record_hit", "apply_hit"]
const R34_COMBO_TICK_METHODS: Array[String] = ["tick", "advance", "step"]


## 服务创建（同步、纯 RefCounted，不碰场景树）：生产 _ready 调一次。
## ComboService 由 HUD 创建后经 bind_combo_service 注入（本层不假设 Rank-2 构造签名）。
func _r34_create_services() -> void:
	if ResourceLoader.exists(R34_STAGGER_SVC_PATH) and ResourceLoader.exists(R34_STAGGER_CFG_PATH):
		var s: Script = ResourceLoader.load(R34_STAGGER_SVC_PATH, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
		var c: Resource = ResourceLoader.load(R34_STAGGER_CFG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
		if s != null and c != null:
			_r34_stagger = s.new(c)
	print("[R34][ENC] 生产服务创建 | stagger=%s（combo 由 HUD 注入，未落盘则判空降级，不冒充联调）" % [
			str(_r34_stagger != null)])


func _r34_resolve_combo_methods() -> void:
	_r34_combo_hit_method = ""
	_r34_combo_tick_method = ""
	if _r34_combo == null or not is_instance_valid(_r34_combo):
		return
	for m: String in R34_COMBO_HIT_METHODS:
		if _r34_combo.has_method(m):
			_r34_combo_hit_method = m
			break
	for m2: String in R34_COMBO_TICK_METHODS:
		if _r34_combo.has_method(m2):
			_r34_combo_tick_method = m2
			break


## 注入真实 ComboService（Rank-2 落盘后由 HUD 装配）或契约替身（验证进程）。
## 鸭子类型，不静态引用 Rank-2 class_name，不伪造联调。
func bind_combo_service(svc: Object) -> void:
	_r34_combo = svc
	_r34_resolve_combo_methods()


func get_stagger_service() -> Object:
	return _r34_stagger


func get_combo_service() -> Object:
	return _r34_combo


## 跨节点装配（生产 call_deferred / 验证显式 call）：
##  ① connect 自身 player_hit_landed → 削韧（a 链，去重）；
##  ② 把同一 StaggerService 推给 HUD（f 链可见层订阅同一实例，真实韧性）。
func _r34_bootstrap() -> void:
	if _r34_bootstrapped:
		return
	_r34_bootstrapped = true
	_r34_connect_hit_signal()
	_r34_push_services_to_hud()


func _r34_connect_hit_signal() -> void:
	if _r34_hit_signal_connected:
		return
	var cb: Callable = Callable(self, "_on_player_hit_landed")
	for conn in get_signal_connection_list("player_hit_landed"):
		var c: Callable = conn.get("callable", Callable())
		if c.get_object() == self and String(c.get_method()) == "_on_player_hit_landed":
			_r34_hit_signal_connected = true
			return
	if not is_connected("player_hit_landed", cb):
		connect("player_hit_landed", cb)
	_r34_hit_signal_connected = true


func _r34_push_services_to_hud() -> void:
	var ml: MainLoop = Engine.get_main_loop()
	if not (ml is SceneTree):
		return
	var tree_root: Node = (ml as SceneTree).root
	var courtyard: Node = tree_root.get_node_or_null(NodePath("Courtyard"))
	if courtyard == null:
		courtyard = get_parent()
	if courtyard == null:
		return
	var hud: Node = courtyard.get_node_or_null(NodePath(R34_HUD_REL_PATH))
	if hud == null or not is_instance_valid(hud):
		return
	if _r34_stagger != null and hud.has_method("bind_stagger_service"):
		hud.call("bind_stagger_service", _r34_stagger)
	print("[R34][ENC] 同一 StaggerService 已推给 HUD（命中削韧 ↔ 韧性条单一事实源） | hud=%s" % str(hud.name))


## a) 命中 → 削韧：由既有 player_hit_landed 信号订阅驱动（非演示显式 apply_hit(100)）。
## poise 用本次命中数据表 action.poise_damage（_r34_last_poise），绝不伪造固定值。
func _on_player_hit_landed(damage: int) -> void:
	_r34_hit_chain += 1
	var poise: float = _r34_last_poise if _r34_last_poise > 0.0 else float(damage)
	if _r34_stagger != null and is_instance_valid(_r34_stagger) \
			and _r34_stagger.has_method("apply_hit"):
		_r34_stagger.call("apply_hit", poise)
	if _r34_combo != null and is_instance_valid(_r34_combo) \
			and not _r34_combo_hit_method.is_empty():
		_r34_combo.call(_r34_combo_hit_method, damage)
		_r34_combo_forward_count += 1


## b) 帧驱动 → tick（生产 _step 每逻辑拍调一次，替代演示逐帧显式 tick）。
func _r34_tick(delta: float) -> void:
	_r34_tick_count += 1
	if _r34_stagger != null and is_instance_valid(_r34_stagger) \
			and _r34_stagger.has_method("tick"):
		_r34_stagger.call("tick", delta)
	if _r34_combo != null and is_instance_valid(_r34_combo) \
			and not _r34_combo_tick_method.is_empty():
		_r34_combo.call(_r34_combo_tick_method, delta)


## 生产链只读快照（验证脚本 / 运行日志读回，不含数值口径、不写盘）。
func get_production_snapshot() -> Dictionary:
	var stagger: Dictionary = {}
	if _r34_stagger != null and is_instance_valid(_r34_stagger) \
			and _r34_stagger.has_method("get_snapshot"):
		var sv: Variant = _r34_stagger.call("get_snapshot")
		if typeof(sv) == TYPE_DICTIONARY:
			stagger = sv as Dictionary
	var combo: Dictionary = {}
	if _r34_combo != null and is_instance_valid(_r34_combo) \
			and _r34_combo.has_method("get_snapshot"):
		var cv: Variant = _r34_combo.call("get_snapshot")
		if typeof(cv) == TYPE_DICTIONARY:
			combo = cv as Dictionary
	return {
		"hit_chain": _r34_hit_chain,
		"combo_forward_count": _r34_combo_forward_count,
		"tick_count": _r34_tick_count,
		"last_poise": _r34_last_poise,
		"stagger": stagger,
		"combo": combo,
		"stagger_available": _r34_stagger != null,
		"combo_available": _r34_combo != null,
		"hit_signal_connected": _r34_hit_signal_connected,
	}


func _r34_release() -> void:
	var cb: Callable = Callable(self, "_on_player_hit_landed")
	if _r34_hit_signal_connected and is_connected("player_hit_landed", cb):
		disconnect("player_hit_landed", cb)
	_r34_hit_signal_connected = false


# ===========================================================================
# R34B [ROUND=R34B] · 任务1 c/d 驱动 + 任务2 运行时敌人参数（Rank-1 唯一写入）
#   A54：ComboService 唯一实例由 HUD 经 wave_trial_director.get_combo_service()
#        注入本层 _r34_combo（鸭子类型转发），本层不自建任何 Combo/Boon 实例。
#   任务1：c) 玩家受击 → on_hit_taken()；d) Boss 死亡 → on_boss_defeated()；
#         a/b 链既有 _on_player_hit_landed / _r34_tick 已转发 register_hit/tick。
#   任务2：波次开始把 boon_draft 的 cost_key/effect_key 作用到运行时敌人参数
#         （hp_scale / telegraph_scale / 削韧），数值全从 [PLACEHOLDER] 表读，
#         参数缺失回落基础值 + push_warning 告警；不改 .tres / tscn / 判定分支。
# ===========================================================================

const R34B_WAVE_TABLE_PATH: String = "res://data/rpg/wave_trial.tres"
const R34B_COMBO_HIT_TAKEN_METHODS: Array[String] = ["on_hit_taken", "hit_taken", "take_hit"]
const R34B_COMBO_BOSS_DEFEATED_METHODS: Array[String] = ["on_boss_defeated", "boss_defeated"]
## [PLACEHOLDER] 运行时敌人参数中性基线（表/参数缺失时回落，非设计数值）。
const R34B_NEUTRAL_SCALE: float = 1.0
const R34B_NEUTRAL_BONUS: float = 0.0

## 波次开始时的运行时敌人参数（导演层权威运行时数据；不写 .tres / 不改判定分支）。
var _r34b_enemy_params: Dictionary = {}
var _r34b_enemy_params_update_count: int = 0


## 任务1 c：玩家受击 → ComboService.on_hit_taken()（按 reset_on_hit_taken 中断连击）。
## 鸭子类型，不静态引用 class_name；实例/方法缺失判空降级、不崩、不产生 SCRIPT ERROR。
func _r34b_combo_on_hit_taken() -> void:
	if _r34_combo == null or not is_instance_valid(_r34_combo):
		return
	for m: String in R34B_COMBO_HIT_TAKEN_METHODS:
		if _r34_combo.has_method(m):
			_r34_combo.call(m)
			return


## 任务1 d：Boss 死亡 → ComboService.on_boss_defeated()（定格评级、此后拒绝命中）。
func _r34b_combo_on_boss_defeated() -> void:
	if _r34_combo == null or not is_instance_valid(_r34_combo):
		return
	for m: String in R34B_COMBO_BOSS_DEFEATED_METHODS:
		if _r34_combo.has_method(m):
			_r34_combo.call(m)
			return


## 任务2：波次开始时把 boon_draft 的 cost_key/effect_key 从「导演层记录」推到
##   运行时敌人参数（hp_scale / telegraph_scale / 削韧 poise_damage_bonus）。
## 数值来源（全从 [PLACEHOLDER] 表读，代码零战斗数值硬编码）：
##   · 基础值：res://data/rpg/wave_trial.tres 当前波 hp_multiplier / telegraph_sec；
##   · 修正值：入参 effect_value/cost_value 来自 BoonDraftConfig.apply() 成对数据
##     （源头 res://data/rpg/boon_draft.tres 的 effect_value / cost_value）。
## 作用链路：wave_started → HUD._r34b_apply_wave_enemy_params → 本方法 →
##   ① _r34b_enemy_params（运行时敌人参数权威字典，供敌人实例生成消费）；
##   ② Boss 运行时实例标注（set_meta 有效倍率，不写 .tres / 不改判定分支）；
##   ③ 削韧消费：_resolve_poise_on_hit 按 poise_damage_bonus 放大真实削韧；
##   ④ hp_restore 作用到玩家运行时 HP。
## 失败降级：cost_key/effect_key 为空或数值非法 / 表读取失败 → 回落中性基线
##   （hp_scale=telegraph_scale=1.0、poise_damage_bonus=0.0）+ 告警 + degraded=true。
func apply_wave_enemy_params(wave_index: int, effect_key: String, effect_value: float,
		cost_key: String, cost_value: float) -> Dictionary:
	_r34b_enemy_params_update_count += 1
	var base_hp: float = R34B_NEUTRAL_SCALE
	var base_telegraph: float = R34B_NEUTRAL_SCALE
	var degraded: bool = false
	# 基础值从 [PLACEHOLDER] 表读（CACHE_MODE_IGNORE 回读真值），失败回落 + 告警。
	var tbl: Resource = null
	if ResourceLoader.exists(R34B_WAVE_TABLE_PATH):
		tbl = ResourceLoader.load(R34B_WAVE_TABLE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	if tbl != null:
		var raw: Variant = tbl.get("waves")
		if typeof(raw) == TYPE_ARRAY and not (raw as Array).is_empty():
			var arr: Array = raw as Array
			var idx: int = clampi(wave_index, 0, arr.size() - 1)
			var row: Variant = arr[idx]
			if typeof(row) == TYPE_DICTIONARY:
				var d: Dictionary = row as Dictionary
				if d.has("hp_multiplier"):
					base_hp = float(d["hp_multiplier"])
				if d.has("telegraph_sec"):
					base_telegraph = float(d["telegraph_sec"])
			else:
				push_warning("[R34B][ENC] wave_trial.tres 波次行非 Dictionary：基础值回落中性基线")
				degraded = true
		else:
			push_warning("[R34B][ENC] wave_trial.tres waves 非数组/为空：基础值回落中性基线")
			degraded = true
	else:
		push_warning("[R34B][ENC] wave_trial.tres 不可用：运行时敌人参数基础值回落中性基线（降级，不崩）")
		degraded = true
	# cost_key / effect_key 白名单映射（key 与数值均来自 BoonDraftConfig 表，不硬编码设计值）。
	var hp_scale: float = R34B_NEUTRAL_SCALE
	var telegraph_scale: float = R34B_NEUTRAL_SCALE
	var poise_damage_bonus: float = R34B_NEUTRAL_BONUS
	var hp_restore: float = R34B_NEUTRAL_BONUS
	var cost_ok: bool = cost_value > 0.0 and not is_nan(cost_value) and not is_inf(cost_value)
	var effect_ok: bool = effect_value > 0.0 and not is_nan(effect_value) and not is_inf(effect_value)
	if cost_key == "hp_scale" and cost_ok:
		hp_scale = cost_value
	elif cost_key == "telegraph_scale" and cost_ok:
		telegraph_scale = cost_value
	elif not cost_key.is_empty():
		push_warning("[R34B][ENC] 未知/非法 cost_key=%s → hp_scale/telegraph_scale 回落中性基线" % cost_key)
		degraded = true
	if effect_key == "poise_damage_bonus" and effect_ok:
		poise_damage_bonus = effect_value
	elif effect_key == "hp_restore" and effect_ok:
		hp_restore = effect_value
	elif not effect_key.is_empty():
		push_warning("[R34B][ENC] 未知/非法 effect_key=%s → 削韧加成回落中性基线" % effect_key)
		degraded = true
	if cost_key.is_empty() and effect_key.is_empty():
		degraded = true   # 无抉择修正：中性基线（正常告知式降级）
		push_warning("[R34B][ENC] 波次开始无 cost_key/effect_key（未抉择或记录缺失）→ 运行时敌人参数回落中性基线（失败降级，不崩）")
	var effective_hp_scale: float = base_hp * hp_scale
	var effective_telegraph_scale: float = base_telegraph * telegraph_scale
	var annotated: bool = false
	# 真正作用到敌人运行时实例：把有效倍率标注到 Boss 实例（元数据，不写 .tres / 不改判定分支）。
	if _boss != null and is_instance_valid(_boss) and _boss.has_method("set_meta"):
		_boss.set_meta("r34b_effective_hp_scale", effective_hp_scale)
		_boss.set_meta("r34b_effective_telegraph_scale", effective_telegraph_scale)
		_boss.set_meta("r34b_poise_damage_bonus", poise_damage_bonus)
		annotated = true
	# hp_restore 作用到玩家运行时 HP（effect 真实消费，不写盘）。
	if hp_restore > 0.0:
		_player_hp = minf(player_max_hp, _player_hp + hp_restore)
	_r34b_enemy_params = {
		"wave_index": wave_index,
		"base_hp_multiplier": base_hp,
		"base_telegraph_sec": base_telegraph,
		"hp_scale": hp_scale,
		"telegraph_scale": telegraph_scale,
		"poise_damage_bonus": poise_damage_bonus,
		"hp_restore": hp_restore,
		"effective_hp_scale": effective_hp_scale,
		"effective_telegraph_scale": effective_telegraph_scale,
		"cost_key": cost_key, "cost_value": cost_value,
		"effect_key": effect_key, "effect_value": effect_value,
		"source": "wave_trial.tres(base) + boon_draft.tres(cost/effect)",
		"boss_instance_annotated": annotated,
		"degraded": degraded, "applied": true,
		"update_count": _r34b_enemy_params_update_count,
	}
	print("[R34B][ENC] 运行时敌人参数已刷新 | wave=%d hp_scale=%.2f(base %.2f→eff %.2f) telegraph_scale=%.2f(eff %.2f) poise_bonus=%.2f annotated=%s degraded=%s" % [
			wave_index, hp_scale, base_hp, effective_hp_scale,
			telegraph_scale, effective_telegraph_scale, poise_damage_bonus,
			str(annotated), str(degraded)])
	return _r34b_enemy_params.duplicate()


## 只读快照（验证 / 运行日志 / 后续敌人实例生成消费；不写盘）。
func get_enemy_runtime_params() -> Dictionary:
	return _r34b_enemy_params.duplicate()
