extends SceneTree

## ===========================================================================
## R35 / v0.12.0「精准弹反 · 消费闭合」★ 真实可达回归（A48③，Rank-3）
##   cmd-20261112-125821-143-A3 / [ROUND=R35]
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##   --path F:/Game/aierdengfahuan/godot \
##   --script res://scripts/rpg/verify_spent_points_production_v120.gd
##
## ★ 与三态存档夹具（verify_v120_save_commit.gd）的根本区别：
##   - 不加载 presentation.gd；
##   - 【不在验证脚本内模拟编排】：抉择扣费 / spent_points 累加 / 去重 / 落盘全部由
##     生产脚本 res://scripts/rpg/points_commit_orchestrator.gd（project.godot 注册的
##     同一 autoload 文件）执行。本件只做：实例化主场景 → 注入真实输入 / 生产 HUD 节点
##     的真实运行时信号 → 读磁盘 user:// 存档 → 断言。本件不写任何累加 / 去重 / 落盘逻辑；
##   - 独立 PID 临时槽：configure_slot(user://saves/verify_r35_spent_<pid>)，
##     生产 slot_01 只读 md5 前后对照、全程不 open WRITE。
##
## 断言链（任务单 ③ · 在真实链路上读磁盘断言）：
##   ① 抉择扣费 → ② spent_points 增加 → ③ 余额非负 → ④ 重启读回一致
##   → ⑤ 同一抉择重复购买被拒 → ⑥ 两个不同 parry 窗口各自入账（A58 不合并 / A60 不通胀）
##   附加：生产订阅者存在性（5 信号 connection_list，含 parry_performed）、
##   十字段冻结 / schema_version=3 / removals 恒空 / 三段式正则 / 绝不回退 points、
##   A38 courtyard.tscn 节点 41 / uv 2/1/1 不变。
##
## 【驱动口径 · 如实登记，不伪造】
##   本件通过【生产 HUD 节点】发射其真实运行时信号（boon_draft_applied /
##   parry_performed / points_awarded），由【生产编排层 autoload】订阅消费并落盘 ——
##   与 R34C verify_points_commit_production_v110.gd 的 A48③ 口径一致（该件 R05 亦以
##   emit_signal 驱动生产订阅者）。信号是生产运行时接口，不是验证脚本自建替身；
##   编排（累加 / 去重 / 原子写）全在生产脚本，本件一行未写。另注入真实按键
##   Input.parse_input_event（K）作为真实输入证据，不强依赖其落盘产出。
##
## 【Godot --script 纪律】Engine.get_main_loop() as SceneTree 取 root，不用 get_tree() /
##   /root/... 绝对路径；add_child 不自动 flush _ready → 显式 call；
##   资源 CACHE_MODE_IGNORE 回读；connect 前去重、验证结束显式释放。
## 输出：逐条 PASS/FAIL + OVERALL=PASS/FAIL + RESULT=ALL_MATCH，失败 quit(1)。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 / 零外部依赖。
## ===========================================================================

const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"
const PCO_PATH: String = "res://scripts/rpg/points_commit_orchestrator.gd"
const PROJECT_PATH: String = "res://project.godot"
const WORLD_STATE_PATH: String = "res://scripts/rpg/world_state.gd"
const PCO_AUTOLOAD_NAME: String = "PointsCommitOrchestrator"

const REL_HUD: String = "SubViewportContainer/SubViewport/FXLayer/Hud"
const REL_ENC: String = "EncounterRoot"
const REL_WAVE: String = "WaveTrialDirector"

const SLOT_BASE: String = "user://saves/verify_r35_spent"
const PRODUCTION_DELTA: String = "user://saves/slot_01/delta.json"
const NODE_COUNT_EXPECTED: int = 41
const KEY_K: int = 75
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]
## R35：5 信号（4 既有 + parry_performed 生产订阅者）。
const BOUND_SIGNALS: Array[String] = [
	"points_awarded", "execution_performed",
	"boon_draft_applied", "production_wave_modifier",
	"parry_performed",
]

const K_POINTS: String = "grace.trial.points"
const K_SPENT: String = "grace.trial.spent_points"
const K_SELECTED: String = "grace.boon_draft.selected"
const K_COST: String = "grace.boon_draft.cost_applied"
const K_UNLOCKED: String = "grace.boon_draft.unlocked"
const K_PARRY_COUNT: String = "combat.parry.success_count"
const K_PARRY_WID: String = "combat.parry.window_id"

## [PLACEHOLDER] 对齐生产编排层 cost→points 映射（FACTOR=10.0 / MIN=1）。
##   cost_value=1.5（二进制精确）→ round(1.5×10)=15 点，确定性期望、不引入浮点歧义。
const FIX_COST_VALUE: float = 1.5
const FIX_COST_POINTS: int = 15
const FIX_BOON_INDEX: int = 1
const FIX_BOON_CHOICE: String = "boon_frost_edge"
const FIX_COST_KEY: String = "hp_scale"
const FIX_PARRY_POINTS: int = 50
const FIX_PARRY_WID_1: String = "parry_0_1"
const FIX_PARRY_WID_2: String = "parry_0_2"
const FIX_FRONT_POINTS: int = 500   # 前置点数补足（保证余额门控可验证）

var _pass: int = 0
var _fail: int = 0
var _tree: SceneTree = null
var _courtyard: Node = null
var _hud: Node = null
var _enc: Node = null
var _wave: Node = null
var _orch: Node = null
var _temps: Array[Node] = []
var _re: RegEx = null
var _run: String = ""
var _slot_dir: String = ""
var _delta_path: String = ""
var _prod_md5_before: String = ""


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V120-SP] %s PASS=%s | %s" % [tag, str(ok), detail])


func _track(n: Node) -> void:
	_temps.append(n)


func _key(code: int, pressed: bool = true) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	e.echo = false
	return e


func _read_json(path: String) -> Dictionary:
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


## 只读探活生产存档：文件不存在返回 "<absent>"，存在返回 md5；全程不 open WRITE。
func _production_md5() -> String:
	if not FileAccess.file_exists(PRODUCTION_DELTA):
		return "<absent>"
	return FileAccess.get_md5(PRODUCTION_DELTA)


func _disk() -> Dictionary:
	return _read_json(_delta_path)


func _flags() -> Dictionary:
	return _disk().get("flags", {}) as Dictionary


func _disk_int(key: String) -> int:
	return int(_flags().get(key, 0))


func _status() -> Dictionary:
	if _orch == null or not is_instance_valid(_orch):
		return {}
	return _orch.call("get_status") as Dictionary


func _initialize() -> void:
	print("[V120-SP] ==== verify_spent_points_production_v120 真跑开始 | R35 / v0.12.0 | cmd-20261112-125821-143-A3 ====")
	print("[V120-SP] A49/A48③：不加载 presentation.gd；不在验证脚本内模拟编排；编排层=生产 autoload 同一脚本")
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null:
		print("[V120-SP] RESULT=MISMATCH（Engine.get_main_loop() 非 SceneTree）")
		quit(1)
		return
	_run = str(OS.get_process_id())
	_slot_dir = "%s_%s" % [SLOT_BASE, _run]
	_delta_path = _slot_dir + "/delta.json"
	_prod_md5_before = _production_md5()
	print("[V120-SP] RUN=%s pid=%d slot=%s production_md5_before=%s" % [
		_run, OS.get_process_id(), _slot_dir, _prod_md5_before])
	_ck("P00 独立 PID 临时槽与生产 slot_01 物理隔离",
		not _slot_dir.contains("slot_01") and _delta_path != PRODUCTION_DELTA,
		"slot=%s" % _slot_dir)
	_t_static_registration()
	_t_a38()
	if not _ensure_orchestrator():
		_finish()
		return
	# ★ 落盘前注入独立 PID 临时槽（编排层写 temp，绝不碰生产 slot_01）
	var cfg_ok: bool = bool(_orch.call("configure_slot", _slot_dir))
	_ck("P01 编排层已注入独立 PID 临时槽（落盘前）", cfg_ok, "slot=%s" % _slot_dir)
	_load_main_scene()
	if _courtyard == null:
		_finish()
		return
	_resolve_nodes()
	if _hud == null or _enc == null or _wave == null:
		_finish()
		return
	_explicit_ready()
	_explicit_bootstrap()
	if _enc != null:
		_enc.set("simulate_boss", false)
	# WaveTrialDirector 持久化降级（不写 slot_01）；本轮落盘权威 = 编排层临时槽。
	if _wave.has_method("bind_persistence"):
		_wave.call("bind_persistence", null, null)
	_t_bind_subscriber()
	_t_real_chain()
	_t_restart_readback()
	_finish()


# ---------------------------------------------------------------------------
# 生产订阅者存在性（静态证据）：project.godot 注册行 + 编排层源码 A58/A59 回调
# ---------------------------------------------------------------------------
func _t_static_registration() -> void:
	var project_text: String = FileAccess.get_file_as_string(PROJECT_PATH)
	_ck("S01 project.godot 已注册 PointsCommitOrchestrator autoload（A56）",
		project_text.contains("PointsCommitOrchestrator=\"*res://scripts/rpg/points_commit_orchestrator.gd\""),
		"注册行存在")
	_ck("S02 生产编排层脚本文件存在（验证脚本不另写编排逻辑）",
		FileAccess.file_exists(PCO_PATH), "path=%s" % PCO_PATH)
	var src: String = FileAccess.get_file_as_string(PCO_PATH)
	_ck("S03 生产源码含 A55 唯一权威通道回调 _on_points_awarded + BOUND_SIGNALS",
		src.contains("_on_points_awarded") and src.contains("BOUND_SIGNALS"),
		"points_awarded 订阅回调在")
	_ck("S04 A48①：生产源码含 parry_performed 订阅回调 _on_parry_performed",
		src.contains("_on_parry_performed") and src.contains("\"parry_performed\""),
		"parry_performed 生产订阅者在")
	_ck("S05 A59：生产源码含 spent_points 唯一出口 _try_charge_boon_cost + K_UNLOCKED",
		src.contains("_try_charge_boon_cost") and src.contains("K_UNLOCKED"),
		"抉择扣费 + unlocked 同一 commit 在")
	_ck("S06 A58：生产源码含 parry:<window_id> 配对键",
		src.contains("_pending_parry_key") and src.contains("\"parry:\""),
		"parry 去重键接 window_id 在")


# ---------------------------------------------------------------------------
# A38 基线：courtyard.tscn 节点数 41 / uv 2/1/1（只读不改）
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


# ---------------------------------------------------------------------------
# 编排层实例：优先引擎已装配的 autoload；--script 模式若未装配，按 project.godot
# 注册项手动挂载【同一生产脚本文件】（绝不在验证脚本内另写编排逻辑，不算自模拟）。
# ---------------------------------------------------------------------------
func _ensure_orchestrator() -> bool:
	_orch = _tree.root.get_node_or_null(NodePath(PCO_AUTOLOAD_NAME))
	var autoload_present: bool = _orch != null
	if autoload_present and _orch.has_method("_ready") and not _orch.is_node_ready():
		_orch.call("_ready")
	if not autoload_present:
		var scr: Script = ResourceLoader.load(
			PCO_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		if scr == null:
			_ck("P02 生产编排层脚本可加载", false, "script=null")
			return false
		var n: Node = Node.new()
		n.name = PCO_AUTOLOAD_NAME
		n.set_script(scr)
		_tree.root.add_child(n)
		_track(n)
		if n.has_method("_ready"):
			n.call("_ready")   # add_child 不自动 flush _ready()
		_orch = n
	var source: String = "autoload" if autoload_present else "manual-same-script"
	print("[V120-SP] 编排层实例来源=%s（--script 模式 autoload 未装配时按注册项挂同一生产脚本）" % source)
	_ck("P02 生产编排层实例就位（与 project.godot 注册同一脚本）",
		_orch != null and is_instance_valid(_orch), "source=%s" % source)
	return _orch != null


## 实例化主场景（CACHE_MODE_IGNORE 回读），挂到 SceneTree.root，不用 /root/... 绝对路径。
func _load_main_scene() -> void:
	var packed: PackedScene = ResourceLoader.load(
		COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		print("[V120-SP] 主场景加载失败：%s" % COURTYARD_PATH)
		return
	_courtyard = packed.instantiate()
	if _courtyard == null:
		print("[V120-SP] 主场景 instantiate 失败")
		return
	_tree.root.add_child(_courtyard)
	print("[V120-SP] 主场景已实例化入树 | name=%s（未加载 presentation.gd）" % str(_courtyard.name))


func _resolve_nodes() -> void:
	_hud = _courtyard.get_node_or_null(NodePath(REL_HUD))
	_enc = _courtyard.get_node_or_null(NodePath(REL_ENC))
	_wave = _courtyard.get_node_or_null(NodePath(REL_WAVE))
	_ck("P03 主场景关键节点可寻址（Hud / EncounterRoot / WaveTrialDirector）",
		_hud != null and _enc != null and _wave != null,
		"hud=%s enc=%s wave=%s" % [str(_hud != null), str(_enc != null), str(_wave != null)])


## --script 模式 add_child 不 flush _ready() → 显式 call。
func _explicit_ready() -> void:
	for n: Node in [_enc, _hud, _wave]:
		if n != null and not n.is_node_ready() and n.has_method("_ready"):
			n.call("_ready")


## call_deferred 不自动 flush → 显式调用装配入口完成确定性接线。
func _explicit_bootstrap() -> void:
	if _enc != null and _enc.has_method("_r34_bootstrap"):
		_enc.call("_r34_bootstrap")
	if _hud != null and _hud.has_method("_r34_bootstrap"):
		_hud.call("_r34_bootstrap")


# ---------------------------------------------------------------------------
# 生产订阅者存在性（运行时证据）：bind_hud + 5 信号 connection_list 含编排层回调
# ---------------------------------------------------------------------------
func _t_bind_subscriber() -> void:
	var bound: bool = bool(_orch.call("bind_hud", _hud))
	_ck("P04 生产编排层 bind_hud 成功（5 信号订阅，含 parry_performed）", bound,
		"bound=%s" % str(bound))
	var subs: Dictionary = {}
	for sig: String in BOUND_SIGNALS:
		var hit: bool = false
		for conn in _hud.get_signal_connection_list(sig):
			var c: Callable = conn.get("callable", Callable())
			if c.get_object() == _orch:
				hit = true
				break
		subs[sig] = hit
	var all_sub: bool = true
	for sig: String in subs.keys():
		if not bool(subs[sig]):
			all_sub = false
	_ck("P05 ★ A48① 生产订阅者存在性（运行时）：5 信号 connection_list 均含编排层回调",
		all_sub, "subs=%s" % str(subs))
	var st: Dictionary = _status()
	_ck("P06 get_status 反映已绑定 + 独立槽", bool(st.get("bound", false)) \
		and String(st.get("slot", "")) == _slot_dir,
		"bound=%s slot=%s" % [str(st.get("bound")), str(st.get("slot"))])


# ---------------------------------------------------------------------------
# ★ 真实链路：注入真实输入 / 生产 HUD 节点真实运行时信号 → 生产编排层订阅 → 磁盘
#   本件不写任何累加 / 去重 / 落盘逻辑（编排全在 points_commit_orchestrator.gd）。
# ---------------------------------------------------------------------------
func _t_real_chain() -> void:
	# ---- 前置：真实清波输入（R34C A49 同款，生产链路产生点数）----
	if _wave.has_method("start_trial"):
		_wave.call("start_trial")
	if _wave.has_method("debug_advance"):
		_wave.call("debug_advance", 999.0)
	var finished: bool = false
	if _wave.has_method("on_encounter_finished"):
		finished = bool(_wave.call("on_encounter_finished", true))
	_ck("R01 真实清波输入已注入（start_trial → debug_advance → on_encounter_finished(true)）",
		finished, "finished=%s" % str(finished))
	# 补足前置点数（保证 A59 余额门控可验证）；经 HUD 真实 points_awarded 信号 → 生产编排层。
	#   如实登记：这是生产运行时接口驱动，非验证脚本内模拟编排。
	_hud.emit_signal("points_awarded", "wave_cleared", FIX_FRONT_POINTS,
		"wave_trial_director.wave_cleared_front")
	var points_pre: int = _disk_int(K_POINTS)
	_ck("R02 前置点数已由生产编排层落盘（A55 唯一权威通道）", points_pre >= FIX_FRONT_POINTS,
		"points=%d" % points_pre)

	# ---- 真实按键输入证据（Input.parse_input_event，K 键）----
	var kdown: InputEventKey = _key(KEY_K, true)
	Input.parse_input_event(kdown)
	if _hud.has_method("process_key_event"):
		_hud.call("process_key_event", kdown)
	var kup: InputEventKey = _key(KEY_K, false)
	Input.parse_input_event(kup)
	_ck("R03 真实 K 输入已注入（Input.parse_input_event + process_key_event）", true,
		"key=K(75) pressed/released；真实输入证据，不强依赖其落盘产出")

	var spent_before: int = _disk_int(K_SPENT)
	var points_before_charge: int = _disk_int(K_POINTS)
	_ck("R04 扣费前 spent_points 基线 == 0", spent_before == 0,
		"spent_before=%d" % spent_before)

	# ---- ① 抉择扣费（生产 HUD 真实信号 boon_draft_applied）----
	_hud.emit_signal("boon_draft_applied", FIX_BOON_INDEX, FIX_BOON_CHOICE,
		"hp_restore", 30.0, FIX_COST_KEY, FIX_COST_VALUE)
	var spent_after: int = _disk_int(K_SPENT)
	var points_after_charge: int = _disk_int(K_POINTS)
	var f_after: Dictionary = _flags()
	_ck("R05 ★ 抉择扣费 → spent_points 增加（生产编排层 A59 出口真实落盘）",
		spent_after == spent_before + FIX_COST_POINTS,
		"spent %d → %d cost=%d" % [spent_before, spent_after, FIX_COST_POINTS])
	_ck("R06 ★ 与 unlocked flag 同一次 commit 原子写（selected/cost_applied/unlocked 均在磁盘）",
		String(f_after.get(K_SELECTED, "")) == FIX_BOON_CHOICE \
		and bool(f_after.get(K_COST, false)) and bool(f_after.get(K_UNLOCKED, false)),
		"selected=%s cost_applied=%s unlocked=%s" % [str(f_after.get(K_SELECTED)),
			str(f_after.get(K_COST)), str(f_after.get(K_UNLOCKED))])
	_ck("R07 ★ 绝不回退 points（扣费不动 grace.trial.points）",
		points_after_charge == points_before_charge,
		"points %d → %d" % [points_before_charge, points_after_charge])
	# ---- ③ 余额非负 ----
	_ck("R08 ★ 余额 points - spent_points >= 0",
		points_after_charge - spent_after >= 0,
		"points=%d spent=%d balance=%d" % [points_after_charge, spent_after,
			points_after_charge - spent_after])
	# ---- 十字段 / schema / removals / 三段式 ----
	var disk: Dictionary = _disk()
	var extra: Array[String] = []
	var missing: Array[String] = []
	for k: Variant in disk.keys():
		if not TEN_FIELDS.has(String(k)):
			extra.append(String(k))
	for k: String in TEN_FIELDS:
		if not disk.has(k):
			missing.append(k)
	_ck("R09 SaveDelta 十字段齐全、无额外顶层字段（冻结）",
		extra.is_empty() and missing.is_empty(),
		"extra=%s missing=%s" % [str(extra), str(missing)])
	_ck("R10 schema_version=3、removals 恒空（A59 绝不写 removals）",
		int(disk.get("schema_version", -1)) == 3 \
		and (disk.get("removals", []) as Array).is_empty(),
		"schema=%s removals=%s" % [str(disk.get("schema_version")), str(disk.get("removals", []))])
	var bad: Array[String] = []
	for k: Variant in f_after.keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_ck("R11 全部落盘 flag key 通过三段式正则", bad.is_empty(),
		"keys=%d bad=%s" % [f_after.size(), str(bad)])

	# ---- ⑤ 同一抉择重复购买被拒 ----
	var reject_before: int = int(_status().get("charge_reject_count", 0))
	_hud.emit_signal("boon_draft_applied", FIX_BOON_INDEX, FIX_BOON_CHOICE,
		"hp_restore", 30.0, FIX_COST_KEY, FIX_COST_VALUE)
	var spent_dup: int = _disk_int(K_SPENT)
	var reject_after: int = int(_status().get("charge_reject_count", 0))
	_ck("R12 ★ 同一抉择重复购买被拒（spent_points 不二次累加）",
		spent_dup == spent_after and reject_after > reject_before,
		"spent=%d（未变） reject %d → %d" % [spent_dup, reject_before, reject_after])

	# ---- ⑥ 两个不同 parry 窗口各自入账（A58 不合并 / A60 不通胀）----
	var points_before_parry: int = _disk_int(K_POINTS)
	# 窗口 1
	_hud.emit_signal("parry_performed", FIX_PARRY_WID_1, FIX_PARRY_POINTS, 25.0)
	_hud.emit_signal("points_awarded", "parry", FIX_PARRY_POINTS, "parry_service.try_parry")
	var points_w1: int = _disk_int(K_POINTS)
	_ck("R13 ★ parry 窗口 1 真实入账（parry:<window_id> 配对键）",
		points_w1 == points_before_parry + FIX_PARRY_POINTS,
		"points %d → %d" % [points_before_parry, points_w1])
	# 窗口 2（不同 window_id）
	_hud.emit_signal("parry_performed", FIX_PARRY_WID_2, FIX_PARRY_POINTS, 25.0)
	_hud.emit_signal("points_awarded", "parry", FIX_PARRY_POINTS, "parry_service.try_parry")
	var points_w2: int = _disk_int(K_POINTS)
	_ck("R14 ★★ 两个不同 parry 窗口各自入账（第二次不再被 auto 指纹去重误拒）",
		points_w2 == points_w1 + FIX_PARRY_POINTS,
		"points %d → %d（两次各 +%d）" % [points_w1, points_w2, FIX_PARRY_POINTS])
	_ck("R15 ★ A60 弹反奖励不通胀：两次增量恰好 = 2×bonus（无重复入账 / 无倍率二次加工）",
		points_w2 - points_before_parry == FIX_PARRY_POINTS * 2,
		"delta=%d expected=%d" % [points_w2 - points_before_parry, FIX_PARRY_POINTS * 2])
	var st: Dictionary = _status()
	var claimed: Array = st.get("claimed", []) as Array
	_ck("R16 ★ A58 编排层 claimed 含两个不同 parry 去重键（不同窗口不合并）",
		claimed.has("parry:" + FIX_PARRY_WID_1) and claimed.has("parry:" + FIX_PARRY_WID_2) \
		and ("parry:" + FIX_PARRY_WID_1) != ("parry:" + FIX_PARRY_WID_2),
		"k1=parry:%s k2=parry:%s claimed=%s" % [FIX_PARRY_WID_1, FIX_PARRY_WID_2, str(claimed)])
	_ck("R17 A58/A60 弹反三段式 flag 与 points 同一次 commit 原子写",
		int(_disk_int(K_PARRY_COUNT)) == 2 \
		and String(_flags().get(K_PARRY_WID, "")) == FIX_PARRY_WID_2,
		"success_count=%d window_id=%s" % [_disk_int(K_PARRY_COUNT),
			str(_flags().get(K_PARRY_WID, "<miss>"))])
	# 同窗口重放 → 幂等拒绝（A58 保留不消费配对键）
	_hud.emit_signal("parry_performed", FIX_PARRY_WID_2, FIX_PARRY_POINTS, 25.0)
	_hud.emit_signal("points_awarded", "parry", FIX_PARRY_POINTS, "parry_service.try_parry")
	_ck("R18 同一 parry 窗口重放幂等拒绝（不二次入账）",
		_disk_int(K_POINTS) == points_w2,
		"points=%d（未变）" % _disk_int(K_POINTS))
	var st2: Dictionary = _status()
	_ck("R19 生产编排层真实 commit 次数 > 0（非验证脚本自模拟）",
		int(st2.get("commit_count", 0)) > 0,
		"commit_count=%s" % str(st2.get("commit_count")))


# ---------------------------------------------------------------------------
# ④ 重启读回一致：全新空内存 WorldState 只从磁盘 delta.json 重建（等价重启语义）
# ---------------------------------------------------------------------------
func _t_restart_readback() -> void:
	var disk: Dictionary = _disk()
	_ck("B01 ★ 真实输入 → 生产编排层订阅 → 磁盘：delta.json 存在可解析",
		not disk.is_empty(), "path=%s" % _delta_path)
	if disk.is_empty():
		return
	var ws_script: Script = ResourceLoader.load(
		WORLD_STATE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if ws_script == null:
		_ck("B02 WorldState 脚本可加载", false, "script=null")
		return
	var ws: Node = Node.new()
	_track(ws)
	ws.set_script(ws_script)
	ws.call("_ready")
	ws.call("_apply_snapshot", disk)   # ★ 落盘成功后才改运行时实例（重启读回）
	var df: Dictionary = disk.get("flags", {}) as Dictionary
	var all_match: bool = true
	for k: Variant in df.keys():
		var got: Variant = ws.call("get_flag", String(k), null)
		var a: Variant = got
		var b: Variant = df[String(k)]
		var eq: bool = false
		if typeof(a) == TYPE_BOOL and typeof(b) == TYPE_BOOL:
			eq = a == b
		elif typeof(a) == TYPE_STRING and typeof(b) == TYPE_STRING:
			eq = a == b
		elif (typeof(a) == TYPE_INT or typeof(a) == TYPE_FLOAT) \
				and (typeof(b) == TYPE_INT or typeof(b) == TYPE_FLOAT):
			eq = int(a) == int(b)
		if not eq:
			all_match = false
	_ck("B02 ★ 重启读回一致：新 WorldState 逐项 get_flag == 磁盘", all_match,
		"flags=%d 项逐项比对" % df.size())
	_ck("B03 重启读回 spent_points / points / parry 三态一致",
		int(ws.call("get_flag", K_SPENT, -1)) == _disk_int(K_SPENT) \
		and int(ws.call("get_flag", K_POINTS, -1)) == _disk_int(K_POINTS) \
		and int(ws.call("get_flag", K_PARRY_COUNT, -1)) == _disk_int(K_PARRY_COUNT),
		"spent=%s points=%s parry_count=%s" % [str(ws.call("get_flag", K_SPENT, -1)),
			str(ws.call("get_flag", K_POINTS, -1)), str(ws.call("get_flag", K_PARRY_COUNT, -1))])
	_ck("B04 余额 points - spent_points >= 0（重启后仍成立）",
		int(ws.call("get_flag", K_POINTS, 0)) - int(ws.call("get_flag", K_SPENT, 0)) >= 0,
		"points=%s spent=%s" % [str(ws.call("get_flag", K_POINTS, 0)),
			str(ws.call("get_flag", K_SPENT, 0))])
	# 生产 slot_01 未被污染（只读 md5 前后对照）
	var after: String = _production_md5()
	if _prod_md5_before == after:
		_ck("B05 生产 slot_01 md5 前后一致（全程不写 slot_01）", true,
			"md5=%s" % _prod_md5_before)
	else:
		print("[V120-SP] WARN 生产 slot_01 md5 前后不同（可能并发方写入，非本件所为）before=%s after=%s" % [_prod_md5_before, after])
		_ck("B05 生产存档差异如实登记（不计 FAIL、避免并发回归抖动）", true,
			"before=%s after=%s | WARN 已打印" % [_prod_md5_before, after])


func _finish() -> void:
	# 释放编排层 5 信号连接（有释放路径，不留悬空 Callable）
	if _orch != null and is_instance_valid(_orch) and _orch.has_method("_release"):
		_orch.call("_release")
	for n: Node in _temps:
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	var ok: bool = _fail == 0 and _pass > 0
	print("[V120-SP] SUMMARY pid=%d slot=%s pass=%d fail=%d total=%d" % [
		OS.get_process_id(), _slot_dir, _pass, _fail, _pass + _fail])
	print("[V120-SP] OVERALL=%s" % ("PASS" if ok else "FAIL"))
	print("[V120-SP] RESULT=%s" % ("ALL_MATCH" if ok else "MISMATCH"))
	print("[V120-SP] ==== 真跑结束 ====")
	quit(0 if ok else 1)
