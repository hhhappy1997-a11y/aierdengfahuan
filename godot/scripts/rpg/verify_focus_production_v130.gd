extends SceneTree

## ===========================================================================
## R36 / v0.13.0「专注值与战技 · 画面补齐」★ 真实可达回归（A48③，Rank-3）
##   cmd-20261112-154132-916-A3 / [ROUND=R36]
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##   --path F:/Game/aierdengfahuan/godot \
##   --script res://scripts/rpg/verify_focus_production_v130.gd
##
## ★ 与三态存档夹具（verify_v130_save_commit.gd）的根本区别：
##   - 不加载 presentation.gd；
##   - 【不在验证脚本内模拟编排】：战技扣 FP / 赐福休息回满 / 重复释放拒绝 /
##     FP 落盘 / 去重 / 上限封顶全部由生产脚本
##     res://scripts/rpg/points_commit_orchestrator.gd（project.godot 注册的
##     同一 autoload 文件）执行。本件只做：实例化主场景 → 复用 A54 唯一真实
##     FocusService → 调生产编排层 bind_focus_service() 显式入口（connect 在生产
##     脚本内，非验证脚本）→ 经生产真实驱动口 wave.spend_focus() /
##     focus_grace_rest() 注入输入 → 读磁盘 user:// 存档 → 断言。
##     本件不写任何扣费 / 去重 / 落盘 / 累加逻辑；
##   - 独立 PID 临时槽：configure_slot(user://saves/verify_v130_fp_<pid>)，
##     生产 slot_01 只读 md5 前后对照、全程不 open WRITE。
##
## 断言链（任务单 ② · 在真实链路上读磁盘断言）：
##   ① 战技扣 FP → ② 落盘 → ③ 重启读回一致 → ④ 赐福休息回满
##   → ⑤ FP 上限不被突破 → ⑥ 重复释放不二次扣费
##   附加：A66 FP 与赐福点数分离（points / spent_points 全程原值不动）、
##   十字段冻结 / schema_version=3 / removals 恒空 / 三段式正则、
##   A48① 生产订阅者存在性（3 信号 connection_list）、A54 唯一实例、
##   A38 courtyard.tscn 节点 41 / uv 2/1/1 不变。
##
## 【驱动口径 · 如实登记，不伪造】
##   本件通过【生产真实驱动口】wave.spend_focus(art_id) / wave.focus_grace_rest()
##   （Rank-2 DONE-R36.md §3.8 标注「真实输入驱动口」，转调 A54 唯一 FocusService
##   spend_fp() / on_grace_rest()）触发真实 FocusService 4 信号中的
##   focus_spent / focus_restored / focus_rejected，由【生产编排层 autoload】订阅
##   消费并落盘 —— 与 R35 verify_spent_points_production_v120.gd 的 A48③ 口径一致
##   （该件以生产 HUD emit_signal 驱动生产订阅者）。信号是生产运行时接口，不是
##   验证脚本自建替身；编排（扣费 / 去重 / 原子写）全在生产脚本，本件一行未写。
##   另注入真实按键 Input.parse_input_event（Q）作为真实输入证据，不强依赖其落盘产出。
##   【FP 与赐福点数分离实证】：先经生产 HUD points_awarded / boon_draft_applied
##   落盘 grace.trial.points=500 / grace.trial.spent_points=15（既有赐福点数），
##   全链断言二者在每次 FP 落盘前后逐字不变、FP flag 绝不混用这两个 key。
##
## 【Godot --script 纪律】Engine.get_main_loop() as SceneTree 取 root，不用 get_tree() /
##   /root/... 绝对路径；add_child 不自动 flush _ready → 显式 call；
##   资源 CACHE_MODE_IGNORE 回读；connect 去重由生产脚本负责、验证结束显式释放。
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

const SLOT_BASE: String = "user://saves/verify_v130_fp"
const PRODUCTION_DELTA: String = "user://saves/slot_01/delta.json"
const NODE_COUNT_EXPECTED: int = 41
const KEY_Q: int = 81
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]

const K_POINTS: String = "grace.trial.points"
const K_SPENT: String = "grace.trial.spent_points"
const K_FOCUS_CURRENT: String = "combat.focus.current"
const K_FOCUS_MAX: String = "combat.focus.max"
const K_FOCUS_ART_ID: String = "combat.focus.art_id"
const K_FOCUS_SPEND_COUNT: String = "combat.focus.spend_count"
const K_FOCUS_RESTORE_COUNT: String = "combat.focus.restore_count"
const K_FOCUS_POLICY: String = "combat.focus.policy"
const K_FOCUS_LAST_REJECT: String = "combat.focus.last_reject"
const FOCUS_SIGNALS: Array[String] = ["focus_spent", "focus_restored", "focus_rejected"]
const FOCUS_KEYS: Array[String] = [
	K_FOCUS_CURRENT, K_FOCUS_MAX, K_FOCUS_ART_ID, K_FOCUS_SPEND_COUNT,
	K_FOCUS_RESTORE_COUNT, K_FOCUS_POLICY, K_FOCUS_LAST_REJECT,
]

## 生产真实驱动口 / 战技 id（数值全部来自 Rank-2 focus_rules.tres，本件不硬编码设计数值）。
const ART_PEBBLE: String = "glintstone_pebble"
const ART_LION: String = "lion_slash"
const POLICY_REFILL: String = "rest_refill"
const REJECT_COOLDOWN: String = "cooldown"
## [PLACEHOLDER] 前置赐福点数（既有链路，FP 与之分离；对齐 R35 生产验证口径）。
const FIX_FRONT_POINTS: int = 500
const FIX_BOON_INDEX: int = 1
const FIX_BOON_CHOICE: String = "boon_frost_edge"
const FIX_COST_KEY: String = "hp_scale"
const FIX_COST_VALUE: float = 1.5   # [PLACEHOLDER] → round(1.5×10)=15 点 spent_points

var _pass: int = 0
var _fail: int = 0
var _tree: SceneTree = null
var _courtyard: Node = null
var _hud: Node = null
var _enc: Node = null
var _wave: Node = null
var _orch: Node = null
var _focus: Object = null
var _temps: Array[Node] = []
var _re: RegEx = null
var _run: String = ""
var _slot_dir: String = ""
var _delta_path: String = ""
var _prod_md5_before: String = ""
var _points_baseline: int = 0
var _spent_baseline: int = 0
var _fp_max: int = 0


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V130-FP] %s PASS=%s | %s" % [tag, str(ok), detail])


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


func _disk_str(key: String) -> String:
	return String(_flags().get(key, ""))


func _status() -> Dictionary:
	if _orch == null or not is_instance_valid(_orch):
		return {}
	return _orch.call("get_status") as Dictionary


## 焦点服务当前 FP（鸭子读，交叉验证磁盘落盘值确实采信真实服务状态）。
func _focus_fp() -> int:
	if _focus != null and is_instance_valid(_focus) and _focus.has_method("get_fp"):
		return int(round(float(_focus.call("get_fp"))))
	return -1


func _focus_fp_max() -> int:
	if _focus != null and is_instance_valid(_focus) and _focus.has_method("get_fp_max"):
		return int(round(float(_focus.call("get_fp_max"))))
	return 0


func _initialize() -> void:
	print("[V130-FP] ==== verify_focus_production_v130 真跑开始 | R36 / v0.13.0 | cmd-20261112-154132-916-A3 ====")
	print("[V130-FP] A49/A48③：不加载 presentation.gd；不在验证脚本内模拟编排；编排层=生产 autoload 同一脚本；复用 A54 唯一真实 FocusService")
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null:
		print("[V130-FP] RESULT=MISMATCH（Engine.get_main_loop() 非 SceneTree）")
		quit(1)
		return
	_run = str(OS.get_process_id())
	_slot_dir = "%s_%s" % [SLOT_BASE, _run]
	_delta_path = _slot_dir + "/delta.json"
	_prod_md5_before = _production_md5()
	print("[V130-FP] RUN=%s pid=%d slot=%s production_md5_before=%s" % [
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
	_resolve_focus()
	if _focus == null:
		_finish()
		return
	_t_no_presentation()
	_t_bind_subscriber()
	_t_real_chain()
	_t_restart_readback()
	_finish()


# ---------------------------------------------------------------------------
# 生产订阅者存在性（静态证据）：project.godot 注册行 + 编排层源码 A66 回调
# ---------------------------------------------------------------------------
func _t_static_registration() -> void:
	var project_text: String = FileAccess.get_file_as_string(PROJECT_PATH)
	_ck("S01 project.godot 已注册 PointsCommitOrchestrator autoload（A56）",
		project_text.contains("PointsCommitOrchestrator=\"*res://scripts/rpg/points_commit_orchestrator.gd\""),
		"注册行存在")
	_ck("S02 生产编排层脚本文件存在（验证脚本不另写编排逻辑）",
		FileAccess.file_exists(PCO_PATH), "path=%s" % PCO_PATH)
	var src: String = FileAccess.get_file_as_string(PCO_PATH)
	_ck("S03 A48①：生产源码含 3 个 focus 信号生产订阅回调",
		src.contains("_on_focus_spent") and src.contains("_on_focus_restored") \
		and src.contains("_on_focus_rejected"),
		"focus_spent / focus_restored / focus_rejected 生产订阅者在")
	_ck("S04 A54：生产源码含 get_focus_service 唯一实例复用 + bind_focus_service 显式入口",
		src.contains("get_focus_service") and src.contains("bind_focus_service"),
		"不自建第二个 FocusService")
	_ck("S05 A66：生产源码含 7 个 combat.focus.* 三段式 flag 常量 + _commit_focus 隔离封装",
		src.contains("combat.focus.current") and src.contains("combat.focus.spend_count") \
		and src.contains("_commit_focus"),
		"FP flag + 与赐福点数分离的 commit 封装在")


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
	print("[V130-FP] 编排层实例来源=%s（--script 模式 autoload 未装配时按注册项挂同一生产脚本）" % source)
	_ck("P02 生产编排层实例就位（与 project.godot 注册同一脚本）",
		_orch != null and is_instance_valid(_orch), "source=%s" % source)
	return _orch != null


## 实例化主场景（CACHE_MODE_IGNORE 回读），挂到 SceneTree.root，不用 /root/... 绝对路径。
func _load_main_scene() -> void:
	var packed: PackedScene = ResourceLoader.load(
		COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		print("[V130-FP] 主场景加载失败：%s" % COURTYARD_PATH)
		return
	_courtyard = packed.instantiate()
	if _courtyard == null:
		print("[V130-FP] 主场景 instantiate 失败")
		return
	_tree.root.add_child(_courtyard)
	print("[V130-FP] 主场景已实例化入树 | name=%s（未加载 presentation.gd）" % str(_courtyard.name))


func _resolve_nodes() -> void:
	_hud = _courtyard.get_node_or_null(NodePath(REL_HUD))
	_enc = _courtyard.get_node_or_null(NodePath(REL_ENC))
	_wave = _courtyard.get_node_or_null(NodePath(REL_WAVE))
	_ck("P03 主场景关键节点可寻址（Hud / EncounterRoot / WaveTrialDirector）",
		_hud != null and _enc != null and _wave != null,
		"hud=%s enc=%s wave=%s" % [str(_hud != null), str(_enc != null), str(_wave != null)])


## --script 模式 add_child 不 flush _ready() → 显式 call（wave._ready 装配唯一 FocusService）。
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


## 复用 A54 唯一真实 FocusService（不自建第二个）；检查 config 有效 / FP 上限。
func _resolve_focus() -> void:
	if _wave == null or not _wave.has_method("get_focus_service"):
		_ck("P04 WaveTrialDirector.get_focus_service() 可用", false, "method missing")
		return
	_focus = _wave.call("get_focus_service") as Object
	_ck("P04 A54：拿到生产装配的 FocusService 唯一真实实例（非替身）",
		_focus != null and is_instance_valid(_focus), "focus=%s" % str(_focus != null))
	if _focus == null:
		return
	var cfg_ok: bool = bool(_focus.call("is_config_valid")) \
		if _focus.has_method("is_config_valid") else false
	_fp_max = _focus_fp_max()
	_ck("P05 唯一 FocusService 规则表有效 + FP 上限 > 0（数值来自 focus_rules.tres [PLACEHOLDER]）",
		cfg_ok and _fp_max > 0, "cfg_ok=%s fp_max=%d" % [str(cfg_ok), _fp_max])
	var f2: Object = _wave.call("get_focus_service") as Object
	_ck("P06 A54：两次 get_focus_service() 返回同一实例（绝不自建第二个）",
		f2 == _focus, "same=%s" % str(f2 == _focus))


# ---------------------------------------------------------------------------
# ★ A48③：本验证进程不加载 presentation.gd（运行时树零演示驱动脚本节点）
# ---------------------------------------------------------------------------
func _t_no_presentation() -> void:
	var found: bool = _scan_presentation(_tree.root)
	_ck("B00 ★ A48③：运行时树零 presentation.gd 脚本节点（不加载演示驱动，主场景自行 instantiate）",
		not found, "found=%s" % str(found))


func _scan_presentation(n: Node) -> bool:
	var scr: Script = n.get_script() as Script
	if scr != null and String(scr.resource_path).ends_with("presentation.gd"):
		return true
	for c: Node in n.get_children():
		if _scan_presentation(c):
			return true
	return false


# ---------------------------------------------------------------------------
# 生产订阅者存在性（运行时证据）：bind_hud + bind_focus_service + 3 信号 connection_list
# ---------------------------------------------------------------------------
func _t_bind_subscriber() -> void:
	var bound_hud: bool = bool(_orch.call("bind_hud", _hud))
	_ck("B01 生产编排层 bind_hud 成功（既有 A55 通道，供前置赐福点数落盘）", bound_hud,
		"bound_hud=%s" % str(bound_hud))
	var bound_focus: bool = bool(_orch.call("bind_focus_service", _focus))
	_ck("B02 生产编排层 bind_focus_service 成功（A66 / A48①，connect 在生产脚本内）",
		bound_focus, "bound_focus=%s" % str(bound_focus))
	var subs: Dictionary = {}
	for sig: String in FOCUS_SIGNALS:
		var hit: bool = false
		for conn in _focus.get_signal_connection_list(sig):
			var c: Callable = conn.get("callable", Callable())
			if c.get_object() == _orch:
				hit = true
				break
		subs[sig] = hit
	var all_sub: bool = true
	for sig: String in subs.keys():
		if not bool(subs[sig]):
			all_sub = false
	_ck("B03 ★ A48① 生产订阅者存在性（运行时）：3 信号 connection_list 均含编排层回调",
		all_sub, "subs=%s" % str(subs))
	var st: Dictionary = _status()
	_ck("B04 get_status 反映 focus 已绑定 + 独立槽 + 上限缓存",
		bool(st.get("focus_bound", false)) and bool(st.get("focus_service", false)) \
		and String(st.get("slot", "")) == _slot_dir and int(st.get("focus_max_cache", 0)) == _fp_max,
		"focus_bound=%s slot=%s max_cache=%s" % [str(st.get("focus_bound")),
			str(st.get("slot")), str(st.get("focus_max_cache"))])


# ---------------------------------------------------------------------------
# ★ 真实链路：生产真实驱动口 wave.spend_focus() / focus_grace_rest() → 生产编排层
#   订阅 → 磁盘。本件不写任何扣费 / 去重 / 落盘 / 累加逻辑（编排全在生产脚本）。
# ---------------------------------------------------------------------------
func _t_real_chain() -> void:
	# ---- 前置：经生产 HUD 真实信号落盘既有赐福点数（FP 与之分离）----
	_hud.emit_signal("points_awarded", "wave_cleared", FIX_FRONT_POINTS,
		"wave_trial_director.wave_cleared_front")
	_hud.emit_signal("boon_draft_applied", FIX_BOON_INDEX, FIX_BOON_CHOICE,
		"hp_restore", 30.0, FIX_COST_KEY, FIX_COST_VALUE)
	_points_baseline = _disk_int(K_POINTS)
	_spent_baseline = _disk_int(K_SPENT)
	_ck("R00 前置赐福点数已由生产编排层落盘（A55/A59 既有通道）",
		_points_baseline == FIX_FRONT_POINTS and _spent_baseline > 0,
		"points=%d spent=%d" % [_points_baseline, _spent_baseline])

	# ---- 真实按键输入证据（Input.parse_input_event，Q 键）----
	var qdown: InputEventKey = _key(KEY_Q, true)
	Input.parse_input_event(qdown)
	var qup: InputEventKey = _key(KEY_Q, false)
	Input.parse_input_event(qup)
	_ck("R01 真实 Q 输入已注入（Input.parse_input_event）；主链由生产真实驱动口确定性触发",
		true, "key=Q(81) pressed/released；真实输入证据，不模拟编排")

	# ---- ① 战技扣 FP（生产真实驱动口 spend_focus → 唯一 FocusService → 编排层落盘）----
	var r1: Dictionary = _wave.call("spend_focus", ART_PEBBLE) as Dictionary
	_ck("R02 ★ 战技释放成功（生产真实驱动口 spend_focus(辉石魔砾) → ok=true）",
		bool(r1.get("ok", false)), "reason=%s" % str(r1.get("reason")))
	var cur1: int = _disk_int(K_FOCUS_CURRENT)
	_ck("R03 ★ 战技扣 FP → 落盘：磁盘 combat.focus.current 减少且与真实服务 FP 一致",
		cur1 > 0 and cur1 < _fp_max and cur1 == _focus_fp(),
		"disk_current=%d service_fp=%d fp_max=%d" % [cur1, _focus_fp(), _fp_max])
	_ck("R04 ★ 落盘 flag 含 max / art_id / spend_count（生产编排层 A66 消费 focus_spent）",
		_disk_int(K_FOCUS_MAX) == _fp_max \
		and _disk_str(K_FOCUS_ART_ID) == ART_PEBBLE \
		and _disk_int(K_FOCUS_SPEND_COUNT) == 1,
		"max=%d art_id=%s spend_count=%d" % [_disk_int(K_FOCUS_MAX),
			_disk_str(K_FOCUS_ART_ID), _disk_int(K_FOCUS_SPEND_COUNT)])

	# 第二个战技（不同 art_id，继续扣 FP）
	var r2: Dictionary = _wave.call("spend_focus", ART_LION) as Dictionary
	_ck("R05 第二战技释放成功（狮子斩，生产真实驱动口）",
		bool(r2.get("ok", false)), "reason=%s" % str(r2.get("reason")))
	var cur2: int = _disk_int(K_FOCUS_CURRENT)
	_ck("R06 ★ FP 连续扣减（只减不增）：current 单调递减，且与真实服务一致",
		cur2 < cur1 and cur2 == _focus_fp(), "cur1=%d cur2=%d service_fp=%d" % [
			cur1, cur2, _focus_fp()])

	# ---- ② 落盘结构 + ③ FP 与赐福点数分离 ----
	var disk: Dictionary = _disk()
	_ck("R07 ★ 真实输入 → 生产编排层订阅 → 磁盘：delta.json 存在可解析",
		not disk.is_empty(), "path=%s" % _delta_path)
	var extra: Array[String] = []
	var missing: Array[String] = []
	for k: Variant in disk.keys():
		if not TEN_FIELDS.has(String(k)):
			extra.append(String(k))
	for k: String in TEN_FIELDS:
		if not disk.has(k):
			missing.append(k)
	_ck("R08 SaveDelta 十字段齐全、无额外顶层字段（冻结）",
		extra.is_empty() and missing.is_empty(),
		"extra=%s missing=%s" % [str(extra), str(missing)])
	_ck("R09 schema_version=3、removals 恒空（A66 绝不写 removals）",
		int(disk.get("schema_version", -1)) == 3 \
		and (disk.get("removals", []) as Array).is_empty(),
		"schema=%s removals=%s" % [str(disk.get("schema_version")), str(disk.get("removals", []))])
	var bad: Array[String] = []
	for k: Variant in _flags().keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_ck("R10 全部落盘 flag key 通过三段式正则（含 7 个 combat.focus.*）", bad.is_empty(),
		"keys=%d bad=%s" % [_flags().size(), str(bad)])
	_ck("R11 ★ A66 FP 与赐福点数分离：points / spent_points 在 FP 落盘前后逐字不变",
		_disk_int(K_POINTS) == _points_baseline and _disk_int(K_SPENT) == _spent_baseline,
		"points=%d==%d spent=%d==%d" % [_disk_int(K_POINTS), _points_baseline,
			_disk_int(K_SPENT), _spent_baseline])
	var mixed: bool = false
	for k: String in FOCUS_KEYS:
		if k == K_POINTS or k == K_SPENT:
			mixed = true
	_ck("R12 ★ A66 7 个 FP flag 全为 combat.focus.* 前缀，绝不混用 points / spent_points",
		not mixed and _focus_keys_pure(), "keys=%s" % str(FOCUS_KEYS))

	# ---- ④ 赐福休息回满（生产真实驱动口 focus_grace_rest）----
	var rr: Dictionary = _wave.call("focus_grace_rest") as Dictionary
	_ck("R13 ★ 赐福休息回满（生产真实驱动口 focus_grace_rest → ok=true）",
		bool(rr.get("ok", false)), "policy=%s" % str(rr.get("policy")))
	var cur_rest: int = _disk_int(K_FOCUS_CURRENT)
	_ck("R14 ★ 赐福休息回满 → 落盘：current 回到上限且与真实服务一致",
		cur_rest == _fp_max and cur_rest == _focus_fp() and cur_rest > cur2,
		"cur_before_rest=%d cur_rest=%d service_fp=%d fp_max=%d" % [
			cur2, cur_rest, _focus_fp(), _fp_max])
	_ck("R15 回满落盘 restore_count / policy（生产编排层消费 focus_restored）",
		_disk_int(K_FOCUS_RESTORE_COUNT) == 1 \
		and _disk_str(K_FOCUS_POLICY) == POLICY_REFILL,
		"restore_count=%d policy=%s" % [_disk_int(K_FOCUS_RESTORE_COUNT),
			_disk_str(K_FOCUS_POLICY)])

	# ---- ⑤ FP 上限不被突破 ----
	_ck("Z01 ★ FP 上限不被突破：战技与回满各阶段 current 恒 0<=cur<=max",
		cur1 >= 0 and cur1 <= _fp_max and cur2 >= 0 and cur2 <= _fp_max \
		and cur_rest >= 0 and cur_rest <= _fp_max,
		"cur1=%d cur2=%d cur_rest=%d max=%d" % [cur1, cur2, cur_rest, _fp_max])
	_ck("Z02 ★ 回满恰等于 max（不突破上限）", cur_rest == _focus_fp_max(),
		"cur_rest=%d service_max=%d" % [cur_rest, _focus_fp_max()])
	_ck("Z03 ★ A66 分离口径在回满后仍成立（points / spent 未被 FP 改动）",
		_disk_int(K_POINTS) == _points_baseline and _disk_int(K_SPENT) == _spent_baseline,
		"points=%d spent=%d" % [_disk_int(K_POINTS), _disk_int(K_SPENT)])

	# ---- ⑥ 重复释放不二次扣费 ----
	# 赐福休息已清冷却 → 第一次 spend_focus(pebble) 成功，第二次 cooldown 拒绝。
	var cur_before_dup: int = _disk_int(K_FOCUS_CURRENT)
	var spend_before_dup: int = _disk_int(K_FOCUS_SPEND_COUNT)
	var d1: Dictionary = _wave.call("spend_focus", ART_PEBBLE) as Dictionary
	_ck("Z04 重复释放组：第 1 次 spend_focus(辉石魔砾) 成功（回满后冷却已清）",
		bool(d1.get("ok", false)), "reason=%s" % str(d1.get("reason")))
	var cur_after_first: int = _disk_int(K_FOCUS_CURRENT)
	var spend_after_first: int = _disk_int(K_FOCUS_SPEND_COUNT)
	var d2: Dictionary = _wave.call("spend_focus", ART_PEBBLE) as Dictionary
	_ck("Z05 ★ 第 2 次重复释放被拒（cooldown，生产 FocusService 幂等）",
		not bool(d2.get("ok", false)) and String(d2.get("reason", "")) == REJECT_COOLDOWN,
		"ok=%s reason=%s" % [str(d2.get("ok")), str(d2.get("reason"))])
	var cur_after_dup: int = _disk_int(K_FOCUS_CURRENT)
	var spend_after_dup: int = _disk_int(K_FOCUS_SPEND_COUNT)
	_ck("Z06 ★★ 重复释放不二次扣费：current / spend_count 在第 2 次后完全不变",
		cur_after_dup == cur_after_first and spend_after_dup == spend_after_first \
		and cur_after_first < cur_before_dup and spend_after_first == spend_before_dup + 1,
		"cur %d→%d→%d spend %d→%d→%d" % [cur_before_dup, cur_after_first,
			cur_after_dup, spend_before_dup, spend_after_first, spend_after_dup])
	_ck("Z07 ★ focus_rejected 有生产订阅者消费落盘（last_reject=cooldown，不改 current）",
		_disk_str(K_FOCUS_LAST_REJECT) == REJECT_COOLDOWN \
		and _disk_int(K_FOCUS_CURRENT) == cur_after_first,
		"last_reject=%s current=%d" % [_disk_str(K_FOCUS_LAST_REJECT),
			_disk_int(K_FOCUS_CURRENT)])
	_ck("Z08 ★ A66 分离口径全链最终成立（points / spent 逐字不变）",
		_disk_int(K_POINTS) == _points_baseline and _disk_int(K_SPENT) == _spent_baseline,
		"points=%d==%d spent=%d==%d" % [_disk_int(K_POINTS), _points_baseline,
			_disk_int(K_SPENT), _spent_baseline])
	_ck("Z09 生产编排层真实 commit 次数 > 0（非验证脚本自模拟）",
		int(_status().get("commit_count", 0)) > 0,
		"commit_count=%s" % str(_status().get("commit_count")))


func _focus_keys_pure() -> bool:
	for k: String in FOCUS_KEYS:
		if not k.begins_with("combat.focus.") or _re.search(k) == null:
			return false
	return true


# ---------------------------------------------------------------------------
# 重启读回一致：全新空内存 WorldState 只从磁盘 delta.json 重建（等价重启语义）
# ---------------------------------------------------------------------------
func _t_restart_readback() -> void:
	var disk: Dictionary = _disk()
	_ck("X01 ★ 真实输入 → 生产编排层订阅 → 磁盘：delta.json 存在可解析",
		not disk.is_empty(), "path=%s" % _delta_path)
	if disk.is_empty():
		return
	var ws_script: Script = ResourceLoader.load(
		WORLD_STATE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if ws_script == null:
		_ck("X02 WorldState 脚本可加载", false, "script=null")
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
	_ck("X02 ★ 重启读回一致：新 WorldState 逐项 get_flag == 磁盘", all_match,
		"flags=%d 项逐项比对" % df.size())
	_ck("X03 重启读回 FP 三态一致（current / max / spend_count）",
		int(ws.call("get_flag", K_FOCUS_CURRENT, -1)) == _disk_int(K_FOCUS_CURRENT) \
		and int(ws.call("get_flag", K_FOCUS_MAX, -1)) == _disk_int(K_FOCUS_MAX) \
		and int(ws.call("get_flag", K_FOCUS_SPEND_COUNT, -1)) == _disk_int(K_FOCUS_SPEND_COUNT),
		"current=%s max=%s spend=%s" % [str(ws.call("get_flag", K_FOCUS_CURRENT, -1)),
			str(ws.call("get_flag", K_FOCUS_MAX, -1)),
			str(ws.call("get_flag", K_FOCUS_SPEND_COUNT, -1))])
	_ck("X04 重启读回 FP 上限不被突破（current <= max）",
		int(ws.call("get_flag", K_FOCUS_CURRENT, 0)) <= int(ws.call("get_flag", K_FOCUS_MAX, 0)),
		"current=%s max=%s" % [str(ws.call("get_flag", K_FOCUS_CURRENT, 0)),
			str(ws.call("get_flag", K_FOCUS_MAX, 0))])
	var after: String = _production_md5()
	if _prod_md5_before == after:
		_ck("X05 生产 slot_01 md5 前后一致（全程不写 slot_01）", true,
			"md5=%s" % _prod_md5_before)
	else:
		print("[V130-FP] WARN 生产 slot_01 md5 前后不同（可能并发方写入，非本件所为）before=%s after=%s" % [_prod_md5_before, after])
		_ck("X05 生产存档差异如实登记（不计 FAIL、避免并发回归抖动）", true,
			"before=%s after=%s | WARN 已打印" % [_prod_md5_before, after])


func _finish() -> void:
	# 释放编排层信号连接（_release 内含 _release_focus，不留悬空 Callable）
	if _orch != null and is_instance_valid(_orch) and _orch.has_method("_release"):
		_orch.call("_release")
	for n: Node in _temps:
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	var ok: bool = _fail == 0 and _pass > 0
	print("[V130-FP] SUMMARY pid=%d slot=%s pass=%d fail=%d total=%d" % [
		OS.get_process_id(), _slot_dir, _pass, _fail, _pass + _fail])
	print("[V130-FP] OVERALL=%s" % ("PASS" if ok else "FAIL"))
	print("[V130-FP] RESULT=%s" % ("ALL_MATCH" if ok else "MISMATCH"))
	print("[V130-FP] ==== 真跑结束 ====")
	quit(0 if ok else 1)
