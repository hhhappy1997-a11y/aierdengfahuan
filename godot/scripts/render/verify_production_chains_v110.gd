extends SceneTree
## ===========================================================================
## R34 [ROUND=R34] · v0.11.0 生产运行时 6 条触发链验证（Rank-1）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/render/verify_production_chains_v110.gd
##
## A49 口径（裁决）：「真实可达」必须在不加载 presentation.gd 的进程里由真实输入连通。
##   本脚本【不加载 presentation.gd】；自行 instantiate 主场景 courtyard.tscn，
##   断言 6 条生产运行时触发链真实连通，全程只读、不改任何工程文件：
##     a) 命中 → 削韧：注入真实 light_attack 命中 → player_hit_landed →
##        StaggerService.apply_hit(真实 poise_damage) → 韧性快照变化。
##     b) 帧驱动 → tick：导演层 _step 每逻辑拍驱动 StaggerService.tick / ComboService.tick。
##     c) 清波 → 卡片：真实 WaveTrialDirector.wave_cleared → HUD 三选一卡片 open。
##     d) apply/settle 消费方：真实数字键抉择 → BoonDraftService.apply() 结算生效
##        （boon_draft_applied 成对 effect/cost）+ 下一波 wave_started 广播修正。
##     e) 点数落盘：HUD 只发 points_awarded 信号 / 传参，Rank-1 不写存档文件（A50）。
##     f) 生产 HUD 常驻可见节点：hud.gd 自建 ProductionMechanismsLayer 按状态显示。
##
## combo 状态变化：ComboService 属 Rank-2 本轮并发新增件、此刻未落盘、构造签名由
##   Rank-2 定义。Rank-1 不主动 new（避免签名不符 SCRIPT ERROR / 伪造联调），
##   本脚本经 bind_combo_service() 注入契约替身（FakeCombo），断言「命中 → combo
##   消费方状态变化」这一 Rank-1 转发链真实连通；真实评级逻辑待 Rank-2 落盘联调，
##   如实登记，不冒充已联调。口径同 verify_stagger_runtime_v100.gd 的替身 / 真实双组。
##
## --script / SceneTree 纪律：
##   add_child 不自动 flush _ready() → 对 3 个导演节点显式 call("_ready")；
##   call_deferred 不自动 flush → 显式 call("_r34_bootstrap") 完成确定性装配；
##   用 Engine.get_main_loop() as SceneTree 取 root，不用 get_tree() / 不用 /root/...
##   绝对路径；资源回读 CACHE_MODE_IGNORE；信号 connect 前 get_signal_connection_list
##   去重、验证结束显式 disconnect；未引入 cosf()/sinf()（R31 踩坑）。
## 输出：逐条 PASS/FAIL + SUMMARY + RESULT=ALL_MATCH（全通过）/ MISMATCH。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。
## ===========================================================================

const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"
const NODE_COUNT_EXPECTED: int = 41

# 关键节点相对路径（相对主场景根 Courtyard，不用 /root/... 绝对路径）
const REL_HUD: String = "SubViewportContainer/SubViewport/FXLayer/Hud"
const REL_ENC: String = "EncounterRoot"
const REL_WAVE: String = "WaveTrialDirector"

# project.godot [input] 物理键码
const KEY_2: int = 50             # 数字键 2（赐福抉择第 2 项）
const KEY_F: int = 70             # 处决
const KEY_TAB: int = 4194306      # 图鉴开关（A46 单一 Tab 仲裁者）

## 契约替身：ComboService（Rank-2 本轮并发新增、未落盘）。只声明与命中转发链一致的
## 公开方法 / 快照，用于证明 Rank-1「命中 → combo 消费方」链连通，不冒充真实评级联调。
class FakeCombo extends RefCounted:
	var hit_count: int = 0
	var tick_count: int = 0
	var _rank: String = "D"

	func register_hit(_damage: Variant = null) -> void:
		hit_count += 1
		_rank = "B" if hit_count >= 3 else ("C" if hit_count >= 2 else "D")

	func tick(_delta: Variant = null) -> void:
		tick_count += 1

	func get_snapshot() -> Dictionary:
		return {"count": hit_count, "rank": _rank,
				"multiplier": 1.0, "combo_service": "fake_contract"}


var _pass: int = 0
var _fail: int = 0
var _tree: SceneTree = null
var _courtyard: Node = null
var _hud: Node = null
var _enc: Node = null
var _wave: Node = null
var _fake_combo: FakeCombo = null

# 探针信号回读（连接后统计，不写任何状态）
var _points_log: Array[Dictionary] = []
var _applied_log: Array[Dictionary] = []
var _modifier_log: Array[Dictionary] = []
var _exec_log: Array[Dictionary] = []
var _selected_log: Array[Dictionary] = []
var _probes_connected: bool = false


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V110] %s PASS=%s | %s" % [tag, str(ok), detail])


func _key(code: int, pressed: bool = true) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	e.echo = false
	return e


## connect 前去重；返回是否新连。
func _dedup_connect(obj: Object, sig: String, method: String) -> bool:
	if obj == null or not obj.has_signal(sig):
		return false
	var cb: Callable = Callable(self, method)
	for conn in obj.get_signal_connection_list(sig):
		var c: Callable = conn.get("callable", Callable())
		if c.get_object() == self and String(c.get_method()) == method:
			return false
	obj.connect(sig, cb)
	return true


func _initialize() -> void:
	print("[V110] ==== verify_production_chains_v110 真跑开始 | R34 v0.11.0 Rank-1 ====")
	print("[V110] A49：本进程不加载 presentation.gd；自行 instantiate 主场景 + 显式 _ready()/bootstrap()")
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null:
		print("[V110] RESULT=MISMATCH（Engine.get_main_loop() 非 SceneTree）")
		quit(1)
		return
	_load_main_scene()
	if _courtyard == null:
		_finish(true)
		return
	_resolve_nodes()
	var ready_ok: bool = _explicit_ready()
	if not ready_ok:
		_finish(true)
		return
	_explicit_bootstrap()
	# 关闭 Boss AI（既有 @export 自测隔离开关）：--script 的 _initialize() 阶段引擎未
	# flush Boss._ready、_hp 默认 0，get_hp_ratio()<=0 会误判 _finish(true) 令 _step
	# 首拍后 early return（真跑实证 tick_count 0→1）。关闭后命中链确定性推进，不改任何状态口径。
	if _enc != null:
		_enc.set("simulate_boss", false)
	_inject_combo()
	_bind_probe_signals()
	_t_a38()
	_t_f_visible_layer()
	_t_chain_a_b()
	_t_chain_c()
	_t_chain_d()
	_t_chain_e()
	_t_chain_f_refresh()
	_t_tab_arbitration()
	_t_combo_static()
	_t_a57_full_chain()
	_finish(false)


## 实例化主场景（CACHE_MODE_IGNORE 回读），挂到 SceneTree.root，不用 /root/... 绝对路径。
func _load_main_scene() -> void:
	var packed: PackedScene = ResourceLoader.load(
			COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		print("[V110] 主场景加载失败：%s" % COURTYARD_PATH)
		return
	_courtyard = packed.instantiate()
	if _courtyard == null:
		print("[V110] 主场景 instantiate 失败")
		return
	_tree.root.add_child(_courtyard)
	print("[V110] 主场景已实例化入树 | name=%s is_inside_tree=%s（未加载 presentation.gd）" % [
			str(_courtyard.name), str(_courtyard.is_inside_tree())])


func _resolve_nodes() -> void:
	_hud = _courtyard.get_node_or_null(NodePath(REL_HUD))
	_enc = _courtyard.get_node_or_null(NodePath(REL_ENC))
	_wave = _courtyard.get_node_or_null(NodePath(REL_WAVE))
	_ck("A0 主场景关键节点可寻址（EncounterRoot / Hud / WaveTrialDirector）",
			_hud != null and _enc != null and _wave != null,
			"enc=%s hud=%s wave=%s" % [str(_enc != null), str(_hud != null), str(_wave != null)])


## --script 模式 add_child 不 flush _ready() → 显式 call（3 个导演节点，顺序无依赖）。
func _explicit_ready() -> bool:
	if _hud == null or _enc == null or _wave == null:
		print("[V110] RESULT=MISMATCH（关键节点缺失，显式 _ready 跳过）")
		return false
	for n: Node in [_enc, _hud, _wave]:
		if not n.is_node_ready() and n.has_method("_ready"):
			n.call("_ready")
	print("[V110] 显式 _ready() 完成（EncounterDirector / HUD / WaveTrialDirector）")
	return true


## call_deferred 不自动 flush → 显式调用装配入口完成确定性接线。
func _explicit_bootstrap() -> void:
	if _enc.has_method("_r34_bootstrap"):
		_enc.call("_r34_bootstrap")
	if _hud.has_method("_r34_bootstrap"):
		_hud.call("_r34_bootstrap")
	print("[V110] 显式 _r34_bootstrap() 完成（a/b 命中订阅 + c/d 波次订阅 + f 可见层）")


## 生产装配（HUD._ready → _r34_create_boon_service）已防御式创建真实 ComboService 并
## 转注入导演层：优先【直接沿用】，验证的是真正的生产运行时链，不临时替换实例。
## 仅当生产未落盘/未装配时，才由验证进程注入真实服务或契约替身（如实登记降级）。
func _inject_combo() -> void:
	var existing: Object = null
	if _enc != null and _enc.has_method("get_combo_service"):
		existing = _enc.call("get_combo_service") as Object
	if existing != null and is_instance_valid(existing) \
			and existing.has_method("register_hit") and existing.has_method("get_snapshot"):
		print("[V110] 生产运行时已绑定【A54 唯一实例】ComboService（HUD._r34_bootstrap 经 wave.get_combo_service 复用）→ 直接沿用，验证生产链本身")
		return
	# A54：绝不另建第二个 ComboService 实例。生产未装配时优先从 wave 复用其唯一实例。
	if _wave != null and _wave.has_method("get_combo_service"):
		var wave_combo: Object = _wave.call("get_combo_service") as Object
		if wave_combo != null and is_instance_valid(wave_combo) \
				and wave_combo.has_method("register_hit") and wave_combo.has_method("get_snapshot"):
			if _hud != null and _hud.has_method("bind_combo_service"):
				_hud.call("bind_combo_service", wave_combo)
			elif _enc != null and _enc.has_method("bind_combo_service"):
				_enc.call("bind_combo_service", wave_combo)
			print("[V110] 生产未装配 → 复用 wave_trial_director 唯一 ComboService（A54，不 new 第二实例）")
			return
	_fake_combo = FakeCombo.new()
	if _hud.has_method("bind_combo_service"):
		_hud.call("bind_combo_service", _fake_combo)
	elif _enc != null and _enc.has_method("bind_combo_service"):
		_enc.call("bind_combo_service", _fake_combo)
	print("[V110] 唯一 ComboService 不可用 → 契约替身验证 Rank-1 命中→combo 转发链（A54：替身非第二 ComboService 实例），如实登记不冒充")


func _bind_probe_signals() -> void:
	if _hud == null:
		return
	_probes_connected = true
	_dedup_connect(_hud, "points_awarded", "_on_points")
	_dedup_connect(_hud, "boon_draft_applied", "_on_applied")
	_dedup_connect(_hud, "production_wave_modifier", "_on_modifier")
	_dedup_connect(_hud, "execution_performed", "_on_exec")
	_dedup_connect(_hud, "boon_draft_selected", "_on_selected")


func _on_points(reason: String, points: int, source: String) -> void:
	_points_log.append({"reason": reason, "points": points, "source": source})


func _on_applied(index: int, choice_id: String, effect_key: String, effect_value: float, cost_key: String, cost_value: float) -> void:
	_applied_log.append({"index": index, "choice_id": choice_id,
			"effect_key": effect_key, "effect_value": effect_value,
			"cost_key": cost_key, "cost_value": cost_value})


func _on_modifier(wave_index: int, effect_key: String, effect_value: float, cost_key: String, cost_value: float) -> void:
	_modifier_log.append({"wave_index": wave_index, "effect_key": effect_key,
			"effect_value": effect_value, "cost_key": cost_key, "cost_value": cost_value})


func _on_exec(window_id: String, bonus_points: int) -> void:
	_exec_log.append({"window_id": window_id, "bonus_points": bonus_points})


func _on_selected(index: int, choice_id: String) -> void:
	_selected_log.append({"index": index, "choice_id": choice_id})


# ---------------------------------------------------------------------------
# A38 基线：courtyard.tscn 节点数 41 / uv 2/1/1 / 关键信号方法
# ---------------------------------------------------------------------------
func _t_a38() -> void:
	var text: String = FileAccess.get_file_as_string(COURTYARD_PATH)
	var count: int = 0
	for line: String in text.split("\n"):
		if line.begins_with("[node "):
			count += 1
	_ck("A38-1 courtyard.tscn 静态 [node] 行数 == 41（只读不改）",
			count == NODE_COUNT_EXPECTED, "count=%d expected=%d" % [count, NODE_COUNT_EXPECTED])
	var uv_2x: int = text.count("Vector3(2, 2, 1)")
	var uv_1x: int = text.count("Vector3(1, 1, 1)")
	_ck("A38-2 uv 2/1/1 原样（Vector3(2,2,1)×1 + Vector3(1,1,1)×2）",
			uv_2x == 1 and uv_1x == 2, "uv_2x=%d uv_1x=%d" % [uv_2x, uv_1x])
	if _hud != null:
		var sigs: Array[String] = ["grace_selected", "travel_confirmed", "rest_requested",
				"hud_refreshed", "execution_performed", "boon_draft_selected",
				"points_awarded", "boon_draft_applied", "production_wave_modifier"]
		var miss: Array[String] = []
		for s: String in sigs:
			if not _hud.has_signal(s):
				miss.append(s)
		_ck("A38-3 既有 6 信号 + R34 3 信号齐全 + 关键生产方法可寻址",
				miss.is_empty() and _hud.has_method("process_key_event") \
						and _hud.has_method("get_production_status") \
						and _hud.has_method("on_wave_cleared"),
				"missing_sigs=%s" % str(miss))


# ---------------------------------------------------------------------------
# f) 生产 HUD 常驻可见节点（hud.gd 自建，非 presentation.gd 构造）
# ---------------------------------------------------------------------------
func _t_f_visible_layer() -> void:
	if _hud == null:
		_ck("F0 HUD 可用", false, "hud=null")
		return
	var st: Dictionary = _hud.call("get_production_status") as Dictionary
	_ck("f1 生产装配：StaggerService / BoonDraftService / 真实 ComboService 均绑定生产实例",
			bool(st.get("stagger_bound", false)) and bool(st.get("boon_bound", false)) \
					and bool(st.get("combo_bound", false)),
			"stagger_bound=%s boon_bound=%s combo_bound=%s" % [
					str(st.get("stagger_bound", "?")), str(st.get("boon_bound", "?")),
					str(st.get("combo_bound", "?"))])
	_ck("f2 c/d 链：HUD 已订阅真实 wave_cleared / wave_started",
			bool(st.get("wave_cleared_connected", false)) and bool(st.get("wave_started_connected", false)),
			"wave_cleared=%s wave_started=%s" % [
					str(st.get("wave_cleared_connected", "?")), str(st.get("wave_started_connected", "?"))])
	var layer: Node = _courtyard.get_node_or_null(NodePath("ProductionMechanismsLayer"))
	var nodes_ok: bool = layer != null \
			and layer.get_node_or_null(NodePath("ProdPoiseBar")) != null \
			and layer.get_node_or_null(NodePath("ProdStaggerLabel")) != null \
			and layer.get_node_or_null(NodePath("ProdDraftLabel")) != null \
			and layer.get_node_or_null(NodePath("ProdComboLabel")) != null
	# --script 的 _initialize() 阶段引擎未 flush enter_tree，整棵树 is_inside_tree=false
	# （真跑实证）；此处判「由 hud.gd 挂到生产主场景 Courtyard 且 4 节点齐全」，
	# 真正的渲染入树前提由 GATE-3（--headless --quit 主场景实证）日志证明 is_inside_tree=true。
	var mounted: bool = layer != null and layer.get_parent() == _courtyard
	_ck("f3 生产常驻可见层由 hud.gd 挂到主场景且 4 个真实节点齐全（ProgressBar+3 Label，非 presentation.gd 构造）",
			mounted and nodes_ok, "mounted=%s nodes_ok=%s is_inside_tree(此阶段=%s，GATE-3 实证入树)" % [
					str(mounted), str(nodes_ok),
					str(layer != null and layer.is_inside_tree())])
	# 同一 StaggerService 实例：命中削韧与 HUD 韧性条单一事实源
	if _enc != null and _enc.has_method("get_stagger_service"):
		var ss: Object = _enc.call("get_stagger_service") as Object
		var bound: Object = _hud.get("_stagger_service") as Object
		_ck("f4 命中削韧与 HUD 韧性条为同一 StaggerService 实例（单一事实源）",
				ss != null and bound != null and ss == bound,
				"enc_svc=%s hud_svc=%s same=%s" % [
						str(ss != null), str(bound != null), str(ss != null and ss == bound)])


# ---------------------------------------------------------------------------
# a) 命中 → 削韧 + b) 帧驱动 → tick + combo 转发链
# ---------------------------------------------------------------------------
func _t_chain_a_b() -> void:
	if _enc == null or _hud == null:
		_ck("AB0 导演层/HUD 可用", false, "enc/hud null")
		return
	var snap0: Dictionary = _enc.call("get_production_snapshot") as Dictionary
	var stagger0: Dictionary = snap0.get("stagger", {}) as Dictionary
	var s_val0: float = float(stagger0.get("stagger", -1.0))
	var hit0: int = int(snap0.get("hit_chain", 0))
	var tick0: int = int(snap0.get("tick_count", 0))
	var combo0: int = int(snap0.get("combo_forward_count", 0))
	var fake0: int = _fake_combo.hit_count if _fake_combo != null else -1
	_ck("a0 生产 StaggerService 已创建（stagger_available + 满韧性初值）",
			bool(snap0.get("stagger_available", false)) and s_val0 > 0.0,
			"available=%s stagger0=%.1f max=%.1f" % [
					str(snap0.get("stagger_available", "?")), s_val0,
					float(stagger0.get("stagger_max", -1.0))])
	_ck("a0b player_hit_landed 已订阅削韧回调（hit_signal_connected）",
			bool(snap0.get("hit_signal_connected", false)),
			"connected=%s" % str(snap0.get("hit_signal_connected", "?")))
	# 注入真实玩家命中：经 _request_action / _step 走既有 _try_player_hit() 真实结算，
	# 绝不直接 apply_hit(100) 伪造。attack_light startup=8，debug_step(12) 覆盖 active 窗口。
	for _i: int in range(3):
		if _enc.has_method("debug_request_action"):
			_enc.call("debug_request_action", "attack_light")
		if _enc.has_method("debug_step"):
			_enc.call("debug_step", 12)
	var snap1: Dictionary = _enc.call("get_production_snapshot") as Dictionary
	var stagger1: Dictionary = snap1.get("stagger", {}) as Dictionary
	var s_val1: float = float(stagger1.get("stagger", -1.0))
	var hit1: int = int(snap1.get("hit_chain", 0))
	var tick1: int = int(snap1.get("tick_count", 0))
	var combo1: int = int(snap1.get("combo_forward_count", 0))
	var fake1: int = _fake_combo.hit_count if _fake_combo != null else -1
	_ck("a1 注入真实 light_attack 命中 → player_hit_landed 递增（命中链真实触发）",
			hit1 > hit0, "hit_chain %d -> %d" % [hit0, hit1])
	_ck("a2 命中 → StaggerService.apply_hit(真实 poise_damage) → 韧性快照下降（非演示固定 100）",
			s_val1 < s_val0 and s_val1 >= 0.0, "stagger %.1f -> %.1f (last_poise=%.1f)" % [
					s_val0, s_val1, float(snap1.get("last_poise", 0.0))])
	_ck("b1 导演层 _step 每逻辑拍驱动 tick(delta)（tick_count 递增）",
			tick1 > tick0, "tick_count %d -> %d" % [tick0, tick1])
	# combo 状态变化：真实 ComboService 快照 combo 计数递增（或契约替身计数递增）
	var combo_snap0: Dictionary = snap0.get("combo", {}) as Dictionary
	var combo_snap1: Dictionary = snap1.get("combo", {}) as Dictionary
	var real_combo0: int = int(combo_snap0.get("combo", 0))
	var real_combo1: int = int(combo_snap1.get("combo", 0))
	var combo_moved: bool = combo1 > combo0
	var fake_moved: bool = (_fake_combo != null and fake1 > fake0)
	var real_moved: bool = real_combo1 > real_combo0
	_ck("ab-combo 命中 → 真实 ComboService 连击状态变化（转发计数 + 快照 combo 递增）",
			combo_moved and (fake_moved or real_moved),
			"combo_forward %d -> %d | real_combo %d -> %d rank=%s | fake_hit %d -> %d" % [
					combo0, combo1, real_combo0, real_combo1,
					str(combo_snap1.get("rank", "?")), fake0, fake1])
	# HUD 韧性条同步（同一实例事件驱动）
	var sv: Dictionary = _hud.call("get_stagger_hud_view") as Dictionary
	_ck("a3 同一实例事件驱动：HUD 韧性条 poise_ratio 随削韧同步",
			float(sv.get("poise_ratio", 1.0)) < 1.0,
			"poise_ratio=%.3f poise_text=[%s]" % [
					float(sv.get("poise_ratio", 1.0)), str(sv.get("poise_text", ""))])
	# f 链按状态显示：削韧态显式刷新可见层（--script 无帧循环，手动驱动渲染层）→ 韧性条可见
	if _hud.has_method("_r34_refresh_visible"):
		_hud.call("_r34_refresh_visible")
	var ab_layer: Node = _courtyard.get_node_or_null(NodePath("ProductionMechanismsLayer"))
	var ab_bar: ProgressBar = ab_layer.get_node_or_null(NodePath("ProdPoiseBar")) as ProgressBar if ab_layer != null else null
	_ck("a4/f 削韧态生产可见层按状态显示真实 ProgressBar 韧性条（value<100）",
			ab_bar != null and ab_bar.visible and float(ab_bar.value) < 100.0,
			"poise_bar_visible=%s poise_value=%.1f" % [
					str(ab_bar != null and ab_bar.visible),
					float(ab_bar.value) if ab_bar != null else -1.0])


# ---------------------------------------------------------------------------
# c) 真实 wave_cleared 信号 → HUD 抉择卡片 open
# ---------------------------------------------------------------------------
func _t_chain_c() -> void:
	if _hud == null or _wave == null:
		_ck("C0 波次导演/HUD 可用", false, "wave/hud null")
		return
	# 只读驱动：让 WaveTrialDirector 走真实状态机产生 wave_cleared（bind_persistence(null)
	# 显式降级避免 --script 工具模式写存档文件；不 emit_signal 伪造）。
	if _wave.has_method("bind_persistence"):
		_wave.call("bind_persistence", null, null)
	_points_log.clear()
	if _hud.has_method("close_boon_draft"):
		_hud.call("close_boon_draft")
	var before_open: bool = bool(_hud.call("is_boon_draft_open"))
	# 真实状态机：start_trial → 越过 TELEGRAPH → WAVE_ACTIVE → on_encounter_finished(true)
	# → _clear_wave() → wave_cleared.emit（Rank-2 改后仍保留该信号与公开接口）。
	if _wave.has_method("start_trial"):
		_wave.call("start_trial")
	if _wave.has_method("debug_advance"):
		_wave.call("debug_advance", 999.0)
	var finished: bool = false
	if _wave.has_method("on_encounter_finished"):
		finished = bool(_wave.call("on_encounter_finished", true))
	var bv: Dictionary = _hud.call("get_boon_draft_view") as Dictionary
	var opened: bool = bool(_hud.call("is_boon_draft_open"))
	var choices: Array = bv.get("choices", []) as Array
	_ck("c1 真实 wave_cleared 信号（WaveTrialDirector 状态机清波）→ HUD 三选一卡片 open",
			(not before_open) and opened, "on_encounter_finished=%s open %s -> %s" % [
					str(finished), str(before_open), str(opened)])
	_ck("c2 卡片候选为真实 BoonDraftService 的 3 个选项",
			choices.size() == 3 and bool(bv.get("service_available", false)),
			"choices=%d service_available=%s" % [
					choices.size(), str(bv.get("service_available", "?"))])
	var pts_reason: bool = false
	for e: Dictionary in _points_log:
		if String(e.get("reason", "")) == "wave_cleared":
			pts_reason = true
	_ck("c3 清波点数经 e 链 points_awarded 信号同步发出（wace_cleared 分支）",
			pts_reason, "points_log=%s" % str(_points_log))
	# 生产可见层按状态显示卡片
	if _hud.has_method("_r34_refresh_visible"):
		_hud.call("_r34_refresh_visible")
	var layer: Node = _courtyard.get_node_or_null(NodePath("ProductionMechanismsLayer"))
	var dl: Label = layer.get_node_or_null(NodePath("ProdDraftLabel")) as Label if layer != null else null
	_ck("f5 按状态显示：卡片 open 时生产可见层 ProdDraftLabel 真实可见",
			dl != null and dl.visible, "draft_label_visible=%s" % [
					str(dl != null and dl.visible)])


# ---------------------------------------------------------------------------
# d) 抉择选中 → apply/settle 结算生效 + 作用于下一波
# ---------------------------------------------------------------------------
func _t_chain_d() -> void:
	if _hud == null:
		_ck("D0 HUD 可用", false, "hud=null")
		return
	_applied_log.clear()
	_modifier_log.clear()
	_selected_log.clear()
	# 真实按键注入：Input.parse_input_event + 同一事件喂 process_key_event（与
	# _unhandled_input 完全相同的 R32 键处理路径，口径同 R33 H 组）。
	var ev: InputEventKey = _key(KEY_2, true)
	Input.parse_input_event(ev)
	var consumed: bool = bool(_hud.call("process_key_event", ev))
	var rel: InputEventKey = _key(KEY_2, false)
	Input.parse_input_event(rel)
	var bv: Dictionary = _hud.call("get_boon_draft_view") as Dictionary
	_ck("d1 真实数字键 2 → HUD 真实键处理路径 → 抉择选中、卡片关闭、boon_draft_selected 发出",
			consumed and (not bool(bv.get("open", true))) \
					and int(bv.get("selected_index", -1)) == 1 \
					and _selected_log.size() == 1,
			"consumed=%s open=%s selected_index=%s selected_signal=%d" % [
					str(consumed), str(bv.get("open", "?")),
					str(bv.get("selected_index", "?")), _selected_log.size()])
	var la: Dictionary = _hud.call("get_last_boon_apply") as Dictionary
	_ck("d2 选中后 BoonDraftService.apply() 真实结算生效（ok + paired 成对 effect/cost）",
			bool(la.get("ok", false)) and bool(la.get("paired", false)) \
					and not String(la.get("effect_key", "")).is_empty() \
					and not String(la.get("cost_key", "")).is_empty(),
			"ok=%s paired=%s effect=%s cost=%s" % [
					str(la.get("ok", "?")), str(la.get("paired", "?")),
					str(la.get("effect_key", "?")), str(la.get("cost_key", "?"))])
	_ck("d3 boon_draft_applied 成对 effect/cost 信号发出（供 Rank-2 消费）",
			_applied_log.size() == 1 \
					and not String((_applied_log[0] as Dictionary).get("effect_key", "")).is_empty() \
					and not String((_applied_log[0] as Dictionary).get("cost_key", "")).is_empty(),
			"applied_log=%s" % str(_applied_log))
	var st: Dictionary = _hud.call("get_production_status") as Dictionary
	var pending: Dictionary = st.get("pending_wave_modifier", {}) as Dictionary
	_ck("d4 抉择修正缓存为「待作用于下一波」（pending_wave_modifier 非空）",
			not pending.is_empty(), "pending_keys=%s" % str(pending.keys()))
	# d 链闭环：抉择已注入 Rank-2 wave_trial_director 的 boon 服务（select_boon 公开注入口），
	# 使其 _clear_wave() 里 has_selection() 分支在下一波清波时真实 apply()/settle() 结算。
	var rank2_has_sel: bool = false
	if _wave != null and _wave.has_method("get_boon_service"):
		var r2boon: Object = _wave.call("get_boon_service") as Object
		if r2boon != null and r2boon.has_method("has_selection"):
			rank2_has_sel = bool(r2boon.call("has_selection"))
	_ck("d4b 抉择已注入 Rank-2 下游消费方（wave_trial_director.boon.has_selection=true，下一波 apply/settle 生效）",
			bool(st.get("boon_forward_ok", false)) and rank2_has_sel,
			"boon_forward_ok=%s rank2_has_selection=%s" % [
					str(st.get("boon_forward_ok", "?")), str(rank2_has_sel)])
	# 下一波 wave_started → production_wave_modifier 广播（d 链作用于下一波）
	if _wave != null and _wave.has_method("debug_advance"):
		_wave.call("debug_advance", 0.0)   # WAVE_CLEARED → NEXT_WAVE
		_wave.call("debug_advance", 0.0)   # NEXT_WAVE → 下一波 TELEGRAPH → wave_started.emit
	var active: Dictionary = _hud.call("get_active_wave_modifier") as Dictionary
	_ck("d5 下一波 wave_started → production_wave_modifier 广播 + active_wave_modifier 生效",
			_modifier_log.size() >= 1 and not active.is_empty(),
			"modifier_log=%d active_keys=%s" % [_modifier_log.size(), str(active.keys())])


# ---------------------------------------------------------------------------
# e) 点数落盘：Rank-1 只发信号 / 传参，不写存档文件（A50 / I-1）
# ---------------------------------------------------------------------------
func _t_chain_e() -> void:
	if _hud == null:
		_ck("E0 HUD 可用", false, "hud=null")
		return
	# 处决点数：开窗前置用【真实命中链】连续削韧至破韧（A49：绝不回退演示驱动）。
	# 每次 debug_request_action("attack_light") + debug_step 走既有 _try_player_hit()
	# 真实结算 → player_hit_landed → StaggerService.apply_hit(数据表 poise_damage=18)，
	# 削韧归零时服务自身 emit execution_window_opened → HUD 开窗；不直接调 apply_hit 伪造窗口。
	# attack_light 总帧 = startup 8 + active 5 + recovery 14 = 27；debug_step(30) 让动作
	# 完整走完回到 idle，下一轮 debug_request_action 才会被状态机接受（12 帧不够会拒绝，
	# 削韧累积不到破韧）。每轮命中削韧 18（数据表 poise_damage），~6 次削韧 100 归零开窗。
	if _enc != null and _enc.has_method("debug_request_action") and _enc.has_method("debug_step"):
		for _i: int in range(12):
			_enc.call("debug_request_action", "attack_light")
			_enc.call("debug_step", 30)
			if _hud.has_method("poll_stagger_service"):
				_hud.call("poll_stagger_service")
			if bool((_hud.call("get_stagger_hud_view") as Dictionary).get("window_open", false)):
				break
	var sv: Dictionary = _hud.call("get_stagger_hud_view") as Dictionary
	var window_open: bool = bool(sv.get("window_open", false))
	_exec_log.clear()
	var before_pts: int = _points_log.size()
	if window_open:
		var fev: InputEventKey = _key(KEY_F, true)
		Input.parse_input_event(fev)
		_hud.call("process_key_event", fev)
		var frel: InputEventKey = _key(KEY_F, false)
		Input.parse_input_event(frel)
	var exec_reason: bool = false
	var exec_bonus: int = 0
	for e: Dictionary in _points_log:
		if String(e.get("reason", "")) == "execution":
			exec_reason = true
			exec_bonus = int(e.get("points", 0))
	_ck("e1 窗口内真实 F 处决 → execution_performed + points_awarded(execution, bonus) 信号发出",
			window_open and _exec_log.size() == 1 and exec_reason \
					and _points_log.size() > before_pts,
			"window_open=%s exec_signal=%d exec_bonus=%d points_awarded=%s" % [
					str(window_open), _exec_log.size(), exec_bonus, str(exec_reason)])
	_ck("e2 点数只经信号 / 传参发出，携带真实 bonus_points 与 source（Rank-1 不写盘）",
			exec_reason and exec_bonus >= 0,
			"bonus=%d（点数由 Rank-3 I-1 权威写入点订阅落盘）" % exec_bonus)
	# 静态口径：Rank-1 两文件 R34 段不含任何 set_flag / commit / FileAccess 写盘调用
	var enc_src: String = FileAccess.get_file_as_string("res://scripts/combat/encounter_director.gd")
	var hud_src: String = FileAccess.get_file_as_string("res://scripts/hud.gd")
	# 只检查「本轮 R34 追加段」是否有新增写盘点；既有 purchase_upgrade 的 set_flag 属
	# R27B 既有兑换逻辑（不在 R34 段），不误判。
	var enc_r34: String = enc_src.substr(enc_src.find("# R34 [ROUND=R34]"))
	var hud_r34: String = hud_src.substr(hud_src.find("# 16) R34 [ROUND=R34]"))
	var no_write: bool = (not enc_r34.contains(".call(\"set_flag\"") and not enc_r34.contains(".call(\"commit\"")) \
			and (not hud_r34.contains(".call(\"set_flag\"") and not hud_r34.contains(".call(\"commit\"")) \
			and (not enc_r34.contains("FileAccess.open") and not hud_r34.contains("FileAccess.open"))
	var seg_ok: bool = enc_r34.length() > 0 and hud_r34.length() > 0
	_ck("e3 R34 生产链源码零写盘：enc/hud 追加段不含 set_flag/commit/FileAccess 写盘点（I-1）",
			seg_ok and no_write,
			"enc_r34_len=%d hud_r34_len=%d no_write=%s" % [
					enc_r34.length(), hud_r34.length(), str(no_write)])


# ---------------------------------------------------------------------------
# f) 按状态显示（韧性条 / 读秒） + 首帧隐藏基线
# ---------------------------------------------------------------------------
func _t_chain_f_refresh() -> void:
	if _hud == null:
		_ck("FR0 HUD 可用", false, "hud=null")
		return
	# 处决（e 链）后：StaggerService.try_execute() 恢复满韧性并关窗，卡片已关 →
	# 生产可见层按状态收敛隐藏（不残留）。--script 无帧循环，显式驱动渲染层后断言。
	if _hud.has_method("close_boon_draft"):
		_hud.call("close_boon_draft")
	if _hud.has_method("_r34_refresh_visible"):
		_hud.call("_r34_refresh_visible")
	var sv2: Dictionary = _hud.call("get_stagger_hud_view") as Dictionary
	var layer: Node = _courtyard.get_node_or_null(NodePath("ProductionMechanismsLayer"))
	var bar: ProgressBar = layer.get_node_or_null(NodePath("ProdPoiseBar")) as ProgressBar if layer != null else null
	var dl: Label = layer.get_node_or_null(NodePath("ProdDraftLabel")) as Label if layer != null else null
	var settled_hidden: bool = bar != null and dl != null \
			and not bar.visible and not dl.visible \
			and not bool(sv2.get("window_open", true))
	_ck("f6 按状态收敛：处决后满韧性+窗口关+卡片关 → 生产可见层隐藏（削韧态可见已在 a4 验证）",
			settled_hidden,
			"window_open=%s poise_ratio=%.2f poise_bar_visible=%s draft_visible=%s" % [
					str(sv2.get("window_open", "?")), float(sv2.get("poise_ratio", 1.0)),
					str(bar != null and bar.visible), str(dl != null and dl.visible)])


# ---------------------------------------------------------------------------
# ② A46：Tab 图鉴仍走 HUD 单一仲裁者（不回退吞键）
# ---------------------------------------------------------------------------
func _t_tab_arbitration() -> void:
	if _hud == null:
		_ck("TAB0 HUD 可用", false, "hud=null")
		return
	var c0: bool = bool(_hud.call("is_codex_open"))
	var tp: InputEventKey = _key(KEY_TAB, true)
	Input.parse_input_event(tp)
	var consumed: bool = bool(_hud.call("process_key_event", tp))
	var tr: InputEventKey = _key(KEY_TAB, false)
	Input.parse_input_event(tr)
	var c1: bool = bool(_hud.call("is_codex_open"))
	_ck("tab1 HUD 真实键处理路径消费 Tab 并翻转图鉴（A46 单一仲裁者，不回退）",
			consumed and c1 != c0, "consumed=%s codex %s -> %s" % [
					str(consumed), str(c0), str(c1)])
	# 再按一次恢复，避免影响后续
	var tp2: InputEventKey = _key(KEY_TAB, true)
	Input.parse_input_event(tp2)
	_hud.call("process_key_event", tp2)
	var tr2: InputEventKey = _key(KEY_TAB, false)
	Input.parse_input_event(tr2)


func _finish(early: bool) -> void:
	# A57：释放生产编排层 4 信号订阅（有释放路径，不留悬空 Callable）。
	if _a57_orch != null and is_instance_valid(_a57_orch) and _a57_orch.has_method("_release"):
		_a57_orch.call("_release")
	# 释放探针信号连接（有释放路径，不留悬空 Callable）
	if _probes_connected and _hud != null and is_instance_valid(_hud):
		var pairs: Dictionary = {
			"points_awarded": "_on_points", "boon_draft_applied": "_on_applied",
			"production_wave_modifier": "_on_modifier",
			"execution_performed": "_on_exec", "boon_draft_selected": "_on_selected"}
		for sig: String in pairs.keys():
			var cb: Callable = Callable(self, String(pairs[sig]))
			if _hud.has_signal(sig) and _hud.is_connected(sig, cb):
				_hud.disconnect(sig, cb)
	var ok: bool = (not early) and _fail == 0 and _pass > 0
	print("[V110] ---- 回读汇总 ----")
	print("[V110] SUMMARY pass=%d fail=%d total=%d ok=%s" % [
			_pass, _fail, _pass + _fail, str(ok)])
	if ok:
		print("[V110] RESULT=ALL_MATCH")
	else:
		print("[V110] RESULT=MISMATCH")
	print("[V110] ==== verify_production_chains_v110 真跑结束 ====")
	quit(0 if ok else 1)


# ---------------------------------------------------------------------------
# R34B 扩展：A54 唯一实例 / 4 信号订阅 / combo 真实可达链 / 运行时敌人参数
#   （保留既有 31 条断言不删不放宽；本组只读 + 真实命中/受击，不改既有状态口径）
# ---------------------------------------------------------------------------
func _t_combo_static() -> void:
	if _enc == null or _hud == null or _wave == null:
		_ck("CB0 关键节点可用", false, "enc/hud/wave null")
		return
	# ① A54 唯一实例证据：enc / hud / wave.get_combo_service() 三方同一实例。
	var c_enc: Object = _enc.call("get_combo_service") as Object if _enc.has_method("get_combo_service") else null
	var c_hud: Object = _hud.call("get_combo_service") as Object if _hud.has_method("get_combo_service") else null
	var c_wave: Object = _wave.call("get_combo_service") as Object if _wave.has_method("get_combo_service") else null
	_ck("cb-unique A54：enc / hud / wave.get_combo_service() 为同一 ComboService 唯一实例（绝不另建第二实例）",
			c_enc != null and c_enc == c_hud and c_hud == c_wave \
					and c_enc.has_method("register_hit") and c_enc.has_signal("combo_changed"),
			"enc=%s hud=%s wave=%s same=%s" % [str(c_enc != null), str(c_hud != null),
					str(c_wave != null), str(c_enc != null and c_enc == c_hud and c_hud == c_wave)])
	var b_wave: Object = _wave.call("get_boon_service") as Object if _wave.has_method("get_boon_service") else null
	var b_hud: Object = _hud.get("_boon_draft_service") as Object
	_ck("cb-unique-boon A54：hud._boon_draft_service 复用 wave.get_boon_service() 唯一实例",
			b_wave != null and b_hud == b_wave,
			"hud=%s wave=%s same=%s" % [str(b_hud != null), str(b_wave != null), str(b_hud == b_wave)])
	# ② 4 信号订阅 + HUD 可见层视图（供 Rank-4 读取）。
	var st: Dictionary = _hud.call("get_production_status") as Dictionary
	_ck("cb-signals HUD 已订阅 combo_changed/rank_changed/combo_reset/combo_settled（生产 HUD 可见层）",
			bool(st.get("combo_signals_connected", false)) and _hud.has_method("get_combo_hud_view"),
			"connected=%s" % str(st.get("combo_signals_connected", false)))
	var cv: Dictionary = _hud.call("get_combo_hud_view") as Dictionary
	_ck("cb-hud-view get_combo_hud_view() 提供评级/倍率/连击数（供 Rank-4 连击视觉反馈读取）",
			cv.has("rank") and cv.has("multiplier") and cv.has("count"),
			"rank=%s mult=%s count=%s" % [str(cv.get("rank", "?")), str(cv.get("multiplier", "?")), str(cv.get("count", "?"))])
	# ③ 任务2：运行时敌人参数作用链路（波次开始已把 cost/effect 推到 ENC）。
	var ep: Dictionary = _enc.call("get_enemy_runtime_params") as Dictionary
	_ck("cb-enemy-params 任务2：波次开始已把 cost/effect 推到运行时敌人参数（hp_scale/telegraph_scale/削韧字段齐全）",
			_enc.has_method("apply_wave_enemy_params") and _enc.has_method("get_enemy_runtime_params") \
					and not ep.is_empty() and bool(ep.get("applied", false)) \
					and ep.has("hp_scale") and ep.has("telegraph_scale") and ep.has("poise_damage_bonus"),
			"cost=%s effect=%s hp_scale=%s telegraph_scale=%s poise_bonus=%s degraded=%s" % [
					str(ep.get("cost_key", "?")), str(ep.get("effect_key", "?")),
					str(ep.get("hp_scale", "?")), str(ep.get("telegraph_scale", "?")),
					str(ep.get("poise_damage_bonus", "?")), str(ep.get("degraded", "?"))])
	# ④ combo 真实可达：真实命中 → combo 增长 → 跨档（A48 玩家真实可达）。
	if c_enc != null and c_enc.has_method("reset"):
		c_enc.call("reset")
	var before: int = int(c_enc.call("get_combo")) if c_enc != null and c_enc.has_method("get_combo") else -1
	for _i: int in range(4):
		if _enc.has_method("debug_request_action"):
			_enc.call("debug_request_action", "attack_light")
		if _enc.has_method("debug_step"):
			_enc.call("debug_step", 30)
	var after: int = int(c_enc.call("get_combo")) if c_enc != null and c_enc.has_method("get_combo") else -1
	var rank_after: String = str(c_enc.call("get_rank")) if c_enc != null and c_enc.has_method("get_rank") else "?"
	_ck("cb-real-hit 真实 light_attack 命中 → 唯一实例 ComboService combo 增长 + 跨档（A48 玩家真实可达）",
			after > before and after >= 4 and rank_after != "D",
			"combo %d -> %d rank=%s" % [before, after, rank_after])
	# ⑤ 受击 → on_hit_taken → combo 归零（受击中断）。
	if _enc.has_method("debug_boss_hit"):
		_enc.call("debug_boss_hit")
	var after_hit: int = int(c_enc.call("get_combo")) if c_enc != null and c_enc.has_method("get_combo") else -1
	_ck("cb-hit-taken 玩家受击 → ComboService.on_hit_taken() → combo 归零（受击中断）",
			after_hit == 0, "combo %d -> %d" % [after, after_hit])


# ===========================================================================
# A57 [ROUND=R34D] · 裁决 A57 全链回归（追加组，既有 38 条断言逐字不删不放宽）
#   真实命中 → combo 增长 → 评级变化 → 清波按倍率结算 → points_awarded 携带倍率后值
#   → PointsCommitOrchestrator（生产 autoload，原样采信）落盘。
#   独立 PID 临时槽：只改落盘目标路径，生产 slot_01 全程只读 md5 前后对照。
#   不重复挂载编排层：优先用引擎已装配的 autoload；仅当未装配时按注册项挂同一生产脚本。
#   A49：不在验证脚本内模拟编排 / 不加载 presentation.gd；点数累加 / 去重 / 落盘
#   全部由生产脚本 points_commit_orchestrator.gd 执行，本脚本只注入真实输入 + 读磁盘断言。
# ===========================================================================
const PCO_AUTOLOAD_NAME: String = "PointsCommitOrchestrator"
const PCO_PATH: String = "res://scripts/rpg/points_commit_orchestrator.gd"
const PRODUCTION_DELTA: String = "user://saves/slot_01/delta.json"
const A57_SLOT_BASE: String = "user://saves/verify_r34d_chains"
const K_POINTS: String = "grace.trial.points"

var _a57_orch: Node = null
var _a57_slot_dir: String = ""
var _a57_delta_path: String = ""
var _a57_prod_md5_before: String = ""
var _a57_points_trace: Array[int] = []


func _a57_read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


func _a57_prod_md5() -> String:
	if not FileAccess.file_exists(PRODUCTION_DELTA):
		return "<absent>"
	return FileAccess.get_md5(PRODUCTION_DELTA)


func _t_a57_full_chain() -> void:
	print("[V110][A57] ==== 裁决 A57 全链组开始（R34D / 独立临时槽）====")
	# ① 生产编排层：优先复用引擎已装配的 autoload，绝不重复挂载第二个实例。
	var orch: Node = _tree.root.get_node_or_null(NodePath(PCO_AUTOLOAD_NAME)) as Node
	var source: String = "autoload"
	if orch != null:
		# --script 模式 add_child 不自动 flush _ready() → 显式补一次（编排层另有惰性初始化兜底）。
		if orch.has_method("_ready") and not orch.is_node_ready():
			orch.call("_ready")
	else:
		# 极端降级：autoload 未装配时按 project.godot 注册项挂【同一生产脚本】，不在本脚本内另写编排逻辑。
		var scr: Script = ResourceLoader.load(
			PCO_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		if scr != null:
			var n: Node = Node.new()
			n.name = PCO_AUTOLOAD_NAME
			n.set_script(scr)
			_tree.root.add_child(n)
			if n.has_method("_ready"):
				n.call("_ready")
			orch = n
			source = "manual-same-script"
	_a57_orch = orch
	_ck("A57-0 生产编排层实例就位（优先 autoload，不重复挂载；降级时挂同一生产脚本）",
		orch != null and is_instance_valid(orch), "source=%s" % source)
	if orch == null:
		return
	# ② 独立 PID 临时槽（落盘前注入）+ 生产 slot_01 md5 基线。
	_a57_slot_dir = "%s_%d" % [A57_SLOT_BASE, OS.get_process_id()]
	_a57_delta_path = _a57_slot_dir + "/delta.json"
	_a57_prod_md5_before = _a57_prod_md5()
	var cfg_ok: bool = bool(orch.call("configure_slot", _a57_slot_dir))
	_ck("A57-1 独立 PID 临时槽与生产 slot_01 物理隔离（落盘前注入）",
		cfg_ok and not _a57_slot_dir.contains("slot_01") and _a57_delta_path != PRODUCTION_DELTA,
		"slot=%s" % _a57_slot_dir)
	# ③ 绑定生产订阅者（4 信号，编排层 connect 前自行去重）。
	var bound: bool = bool(orch.call("bind_hud", _hud))
	_ck("A57-2 PointsCommitOrchestrator.bind_hud 成功（4 信号订阅、A55 唯一权威通道）",
		bound, "bound=%s" % str(bound))
	# ④ 构造干净的 A 级清波场景：
	#   既有 d 链遗留 boon 选中 + _t_combo_static 受击归零 → 先清 boon / reset combo，
	#   再推进 TELEGRAPH → WAVE_ACTIVE（真实状态机、不 emit 伪造）→ 14 击真实命中到 A 级。
	var boon: Object = null
	if _wave.has_method("get_boon_service"):
		boon = _wave.call("get_boon_service") as Object
	if boon != null and boon.has_method("has_selection") and bool(boon.call("has_selection")):
		if boon.has_method("reset"):
			boon.call("reset")
	var combo: Object = null
	if _enc.has_method("get_combo_service"):
		combo = _enc.call("get_combo_service") as Object
	if combo != null and combo.has_method("reset"):
		combo.call("reset")
	if _wave.has_method("debug_advance"):
		_wave.call("debug_advance", 999.0)   # TELEGRAPH → WAVE_ACTIVE（真实状态机）
	for _i: int in range(14):
		_enc.call("debug_request_action", "attack_light")
		_enc.call("debug_step", 30)
	var combo_a: int = int(combo.call("get_combo")) if combo != null and combo.has_method("get_combo") else -1
	var rank_a: String = str(combo.call("get_rank")) if combo != null and combo.has_method("get_rank") else "?"
	var mult_a: float = float(combo.call("get_multiplier")) if combo != null and combo.has_method("get_multiplier") else 0.0
	_ck("A57-3 真实命中 → combo 增长 → 评级变化：14 击到 A 级 1.6（A48 玩家真实可达）",
		combo_a >= 14 and rank_a == "A" and abs(mult_a - 1.6) < 0.001,
		"combo=%d rank=%s mult=%.2f" % [combo_a, rank_a, mult_a])
	# ⑤ 真实清波：既有 e 链探针 _points_log 清空后只记录本次 A57 事件。
	#    ★ 期望倍率后值【不硬编码】：由 ComboService 本次结算真值 base_points × multiplier 动态推导。
	#      wave_trial.tres 各波基础点数不同（第 1 波 100 / 第 2 波 150 / 第 3 波 200 [PLACEHOLDER]），
	#      本组波次由既有 a~f 链真实推进决定；按真值断言、如实登记，不臆断 160、不篡改状态机。
	_points_log.clear()
	var finished: bool = bool(_wave.call("on_encounter_finished", true))
	var ss: Dictionary = _wave.call("get_settlement_snapshot") as Dictionary
	var last: Dictionary = {}
	if combo != null and combo.has_method("get_last_settlement"):
		last = combo.call("get_last_settlement") as Dictionary
	var base_actual: int = int(last.get("base_points", 0))
	var mult_actual: float = float(last.get("multiplier", 0.0))
	var expect: int = int(roundf(float(base_actual) * mult_actual))
	print("[V110][A57] 本次清波真值：基础 pts=%d × 评级倍率 %.2f → 倍率后值=%d（波次基础点数来自 wave_trial.tres）" % [
		base_actual, mult_actual, expect])
	_ck("A57-4 清波按倍率结算：导演层 / ComboService 结算值均为倍率后值 base×mult（严格大于基础值）",
		finished and base_actual > 0 and abs(mult_actual - 1.6) < 0.001 \
				and expect > base_actual \
				and int(ss.get("last_settled_points", 0)) == expect \
				and int(last.get("total_points", 0)) == expect \
				and int(last.get("base_points", 0)) == base_actual \
				and str(last.get("rank", "")) == "A",
		"finished=%s base=%d mult=%.2f expect=%d settled=%s combo_total=%s" % [
			str(finished), base_actual, mult_actual, expect,
			str(ss.get("last_settled_points", "?")), str(last.get("total_points", "?"))])
	# ⑥ HUD points_awarded 探针：wave_cleared 事件恰 1 条、携带倍率后值（A57 发射值修正）。
	var wave_events: Array[Dictionary] = []
	for e: Dictionary in _points_log:
		if String(e.get("reason", "")) == "wave_cleared":
			wave_events.append(e)
	_ck("A57-5 ★ points_awarded 携带倍率后值（wave_cleared 分支发射值修正，每条清波只发一次、不再是基础值）",
		wave_events.size() == 1 and int((wave_events[0] as Dictionary).get("points", 0)) == expect,
		"wave_events=%s expect=%d" % [str(wave_events), expect])
	# ⑦ 编排层原样采信落盘：get_status.points + 磁盘 flags.grace.trial.points 一致。
	var st: Dictionary = orch.call("get_status") as Dictionary
	var disk: Dictionary = _a57_read_json(_a57_delta_path)
	var flags: Dictionary = disk.get("flags", {}) as Dictionary
	var disk_pts: int = int(flags.get(K_POINTS, 0))
	_a57_points_trace.append(disk_pts)
	_ck("A57-6 ★ PointsCommitOrchestrator 原样采信落盘倍率后值（运行时 get_status + 磁盘真值一致）",
		int(st.get("points", 0)) == expect and disk_pts == expect and int(st.get("commit_count", 0)) > 0,
		"runtime=%s disk=%d expect=%d commit_count=%s" % [str(st.get("points", "?")),
			disk_pts, expect, str(st.get("commit_count", "?"))])
	# ⑧ 全链一致：base×mult 的倍率后值落在 points_awarded 与磁盘（A57 倍率后值实证）。
	var pa_pts: int = int((wave_events[0] as Dictionary).get("points", 0)) if wave_events.size() == 1 else -1
	_ck("A57-7 ★ 全链一致：导演层结算 / combo 结算 / points_awarded / 编排层 / 磁盘 均为同一倍率后值",
		int(ss.get("last_settled_points", 0)) == expect and int(last.get("total_points", 0)) == expect \
				and pa_pts == expect and int(st.get("points", 0)) == expect and disk_pts == expect,
		"settled=%s combo=%s pa=%d runtime=%s disk=%d expect=%d" % [str(ss.get("last_settled_points", "?")),
			str(last.get("total_points", "?")), pa_pts, str(st.get("points", "?")), disk_pts, expect])
	# ⑨ combo_settled 只作对账 / 展示、绝不二次入账：编排层不订阅 + 落盘恰 1 次倍率后值 + points_awarded 恰 1 次。
	var orch_subs_settled: bool = false
	if combo != null and combo.has_signal("combo_settled"):
		for conn in combo.get_signal_connection_list("combo_settled"):
			var c: Callable = conn.get("callable", Callable())
			if c.get_object() == orch:
				orch_subs_settled = true
	_ck("A57-8 combo_settled 绝不二次入账（编排层不订阅 + 磁盘=expect 而非 2×expect + points_awarded 恰 1 次）",
		(not orch_subs_settled) and disk_pts == expect and wave_events.size() == 1,
		"orch_subs_combo_settled=%s disk=%d expect=%d" % [str(orch_subs_settled), disk_pts, expect])
	# ⑩ 同一清波重复触发被去重拒绝（两层门控）。
	var cnt_before: int = int((_wave.call("get_settlement_snapshot") as Dictionary).get("settlement_count", 0))
	var dup_finish: bool = bool(_wave.call("on_encounter_finished", true))
	var cnt_after: int = int((_wave.call("get_settlement_snapshot") as Dictionary).get("settlement_count", 0))
	_ck("A57-9a 同一清波重复 on_encounter_finished 被 Rank-2 WAVE_ACTIVE 门控拒绝（不重复结算）",
		(not dup_finish) and cnt_after == cnt_before,
		"dup_accepted=%s settlement_count %d -> %d" % [str(dup_finish), cnt_before, cnt_after])
	# 重放必须用【同一倍率后值】，否则参数指纹不同会被当成新事件（首轮真跑实证）。
	_hud.emit_signal("points_awarded", "wave_cleared", expect, "wave_trial_director.wave_cleared")
	var disk2: Dictionary = _a57_read_json(_a57_delta_path)
	var disk2_pts: int = int((disk2.get("flags", {}) as Dictionary).get(K_POINTS, 0))
	_a57_points_trace.append(disk2_pts)
	_ck("A57-9b 重放同一 points_awarded 被编排层去重键拒绝（磁盘不增、不二次入账）",
		disk2_pts == expect and disk2_pts == disk_pts,
		"disk %d -> %d（重放被拒）" % [disk_pts, disk2_pts])
	# ⑪ 点数只增不减（磁盘逐次回读序列单调不减）。
	var mono: bool = true
	for i: int in range(1, _a57_points_trace.size()):
		if _a57_points_trace[i] < _a57_points_trace[i - 1]:
			mono = false
	_ck("A57-10 点数只增不减（磁盘逐次回读序列单调不减）",
		mono and _a57_points_trace.size() >= 2, "trace=%s" % str(_a57_points_trace))
	# ⑫ 生产 slot_01 不被污染（只读 md5 前后对照）。
	_ck("A57-11 生产 slot_01 md5 前后一致（全程不写 slot_01）",
		_a57_prod_md5() == _a57_prod_md5_before, "md5=%s" % _a57_prod_md5_before)
	print("[V110][A57] ==== 裁决 A57 全链组结束 ====")
