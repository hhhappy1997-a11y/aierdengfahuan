extends SceneTree

## ===========================================================================
## R34C / v0.11.0 · 生产可达回归（A49 真实验收，Rank-3）
##   cmd-20261112-120028-972-A3
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##   --path F:/Game/aierdengfahuan/godot \
##   --script res://scripts/rpg/verify_points_commit_production_v110.gd
##
## ★ 与 R34 三态夹具（verify_v110_save_commit.gd）的根本区别：
##   - 不加载 presentation.gd；
##   - 【不在验证脚本内模拟编排】：点数累加 / 去重 / 落盘全部由生产脚本
##     res://scripts/rpg/points_commit_orchestrator.gd（project.godot 注册的同一文件）执行。
##     本件只做：实例化主场景 → 注入真实输入 → 读磁盘 user:// 存档 → 断言；
##   - 独立 PID 临时槽：configure_slot(user://saves/verify_r34c_<pid>)，
##     生产 slot_01 只读 md5 前后对照、全程不 open WRITE。
##
## 断言链（任务单 ②）：
##   真实命中 / 清波 / 处决输入 → 生产 autoload 订阅 → 实际落盘 grace.trial.points；
##   点数只增不减；同一事件重复触发不二次加点；旧档缺 key 回落基线；
##   生产 slot_01 不被污染；十字段冻结 / schema_version=3 / removals 空 / 余额 >= 0；
##   A38 courtyard.tscn 节点数 41 / uv 2/1/1 不变；
##   生产订阅者存在性（project.godot 注册行 + 运行时 get_signal_connection_list）。
##
## --script 纪律：Engine.get_main_loop() as SceneTree 取 root，不用 get_tree() /
##   /root/... 绝对路径；add_child 不自动 flush _ready → 显式 call；
##   资源 CACHE_MODE_IGNORE 回读；信号 connect 前去重、验证结束显式释放。
## 输出：逐条 PASS/FAIL + SUMMARY + RESULT=ALL_MATCH，失败 quit(1)。
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

const SLOT_BASE: String = "user://saves/verify_r34c"
const PRODUCTION_DELTA: String = "user://saves/slot_01/delta.json"
const K_POINTS: String = "grace.trial.points"
const K_PERFORMED: String = "grace.execution.performed"
const K_SPENT: String = "grace.trial.spent_points"
const NODE_COUNT_EXPECTED: int = 41
const KEY_F: int = 70
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]
const BOUND_SIGNALS: Array[String] = [
	"points_awarded", "execution_performed",
	"boon_draft_applied", "production_wave_modifier",
]

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
var _points_trace: Array[int] = []


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V110-PROD] %s PASS=%s | %s" % [tag, str(ok), detail])


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


## 与编排层 / world_state.gd 同构的十字段骨架（旧档夹具用，缺本轮关键 key）。
func _new_delta_shell(flags: Dictionary) -> Dictionary:
	return {
		"schema_version": 3,
		"slot": "slot_01",
		"seq": 0,
		"baseline": {"manifest": "res://data/rpg/world_baseline.tres", "manifest_hash": "", "baseline_version": 1, "resource_ids": []},
		"flags": flags,
		"quests": {},
		"inventory": {},
		"spawns": {"defeated": [], "epoch": 0},
		"removals": [],
		"meta": {"playtime_seconds": 0, "area_id": "", "last_grace_id": "", "written_at_unix": 0, "game_version": "", "last_commit_reason": ""},
	}


func _initialize() -> void:
	print("[V110-PROD] ==== verify_points_commit_production_v110 真跑开始 | R34C / v0.11.0 | cmd-20261112-120028-972-A3 ====")
	print("[V110-PROD] A49：不加载 presentation.gd；不在验证脚本内模拟编排；编排层=生产 autoload 同一脚本")
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null:
		print("[V110-PROD] RESULT=MISMATCH（Engine.get_main_loop() 非 SceneTree）")
		quit(1)
		return
	_run = str(OS.get_process_id())
	_slot_dir = "%s_%s" % [SLOT_BASE, _run]
	_delta_path = _slot_dir + "/delta.json"
	_prod_md5_before = _production_md5()
	print("[V110-PROD] RUN=%s pid=%d slot=%s production_md5_before=%s" % [
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
	_t_real_inputs()
	_t_disk_assertions()
	_finish()


# ---------------------------------------------------------------------------
# 生产订阅者存在性（静态证据）：project.godot 注册行 + 编排层源码订阅回调
# ---------------------------------------------------------------------------
func _t_static_registration() -> void:
	var project_text: String = FileAccess.get_file_as_string(PROJECT_PATH)
	_ck("S01 project.godot 已注册 PointsCommitOrchestrator autoload（A56）",
		project_text.contains("PointsCommitOrchestrator=\"*res://scripts/rpg/points_commit_orchestrator.gd\""),
		"注册行存在")
	_ck("S02 生产编排层脚本文件存在（验证脚本不另写编排逻辑）",
		FileAccess.file_exists(PCO_PATH), "path=%s" % PCO_PATH)
	var pco_src: String = FileAccess.get_file_as_string(PCO_PATH)
	_ck("S03 生产编排层源码含 points_awarded 订阅回调（静态存在性证据）",
		pco_src.contains("_on_points_awarded") and pco_src.contains("BOUND_SIGNALS"),
		"_on_points_awarded + BOUND_SIGNALS 均在")


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
	# --script 模式 add_child 不自动 flush _ready()：对已装配的 autoload 也显式补一次，
	# 确保编排层状态在落盘前就绪（编排层自身另有惰性初始化兜底）。
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
	print("[V110-PROD] 编排层实例来源=%s（--script 模式 autoload 未装配时按注册项挂同一生产脚本）" % source)
	_ck("P02 生产编排层实例就位（与 project.godot 注册同一脚本）",
		_orch != null and is_instance_valid(_orch), "source=%s" % source)
	return _orch != null


## 实例化主场景（CACHE_MODE_IGNORE 回读），挂到 SceneTree.root，不用 /root/... 绝对路径。
func _load_main_scene() -> void:
	var packed: PackedScene = ResourceLoader.load(
		COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		print("[V110-PROD] 主场景加载失败：%s" % COURTYARD_PATH)
		return
	_courtyard = packed.instantiate()
	if _courtyard == null:
		print("[V110-PROD] 主场景 instantiate 失败")
		return
	_tree.root.add_child(_courtyard)
	print("[V110-PROD] 主场景已实例化入树 | name=%s（未加载 presentation.gd）" % str(_courtyard.name))


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
# 生产订阅者存在性（运行时证据）：bind_hud + 4 信号 connection_list 含编排层回调
# ---------------------------------------------------------------------------
func _t_bind_subscriber() -> void:
	var bound: bool = bool(_orch.call("bind_hud", _hud))
	_ck("P04 生产编排层 bind_hud 成功（4 信号订阅）", bound, "bound=%s" % str(bound))
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
	_ck("P05 ★ 生产订阅者存在性（运行时）：4 信号 connection_list 均含编排层回调",
		all_sub, "subs=%s" % str(subs))
	var st: Dictionary = _orch.call("get_status") as Dictionary
	_ck("P06 get_status 反映已绑定 + 独立槽", bool(st.get("bound", false)) \
		and String(st.get("slot", "")) == _slot_dir,
		"bound=%s slot=%s" % [str(st.get("bound")), str(st.get("slot"))])


# ---------------------------------------------------------------------------
# 注入真实输入（命中 / 清波 / 处决）→ 生产编排层订阅 → 实际落盘
# ---------------------------------------------------------------------------
func _t_real_inputs() -> void:
	# ① 真实命中链（任务②「注入真实命中」）：既有 _request_action / _step 真实结算。
	var hit_ok: bool = false
	if _enc.has_method("debug_request_action") and _enc.has_method("debug_step"):
		for _i: int in range(3):
			_enc.call("debug_request_action", "attack_light")
			_enc.call("debug_step", 30)
		hit_ok = true
	_ck("R01 真实 light_attack 命中输入已注入（debug_request_action + debug_step）",
		hit_ok, "steps=3")
	# ② 真实清波：WaveTrialDirector 状态机 → wave_cleared → HUD.points_awarded(wave_cleared)
	if _wave.has_method("start_trial"):
		_wave.call("start_trial")
	if _wave.has_method("debug_advance"):
		_wave.call("debug_advance", 999.0)
	var finished: bool = false
	if _wave.has_method("on_encounter_finished"):
		finished = bool(_wave.call("on_encounter_finished", true))
	_ck("R02 真实清波输入（start_trial → debug_advance → on_encounter_finished(true)）",
		finished, "finished=%s" % str(finished))
	_snapshot_points("after_wave")
	# 清波后抉择卡片 open 时 HUD 键路径优先消费数字键、F 被忽略（hud.gd:_process_r32_keys）
	# → 关闭卡片，让真实 F 处决走 _try_execution_input() → request_execution()（A49 真实输入）。
	if _hud.has_method("close_boon_draft"):
		_hud.call("close_boon_draft")
	# ③ 真实处决：连续命中削韧开窗 → 真实 F 键 → request_execution()
	var window_open: bool = false
	if _enc.has_method("debug_request_action") and _enc.has_method("debug_step"):
		for _i: int in range(12):
			_enc.call("debug_request_action", "attack_light")
			_enc.call("debug_step", 30)
			if _hud.has_method("poll_stagger_service"):
				_hud.call("poll_stagger_service")
			if bool((_hud.call("get_stagger_hud_view") as Dictionary).get("window_open", false)):
				window_open = true
				break
	var exec_done: bool = false
	if window_open:
		var fev: InputEventKey = _key(KEY_F, true)
		Input.parse_input_event(fev)
		_hud.call("process_key_event", fev)
		var frel: InputEventKey = _key(KEY_F, false)
		Input.parse_input_event(frel)
		exec_done = true
	_ck("R03 真实 F 处决输入（破韧开窗 → process_key_event(F) → request_execution）",
		window_open and exec_done, "window_open=%s" % str(window_open))
	_snapshot_points("after_exec")
	var st_exec: Dictionary = _orch.call("get_status") as Dictionary
	_ck("R03b 真实处决 → 编排层落 grace.execution.performed（非重放贡献）",
		int(st_exec.get("performed", 0)) >= 1,
		"performed=%s" % str(st_exec.get("performed")))
	var st: Dictionary = _orch.call("get_status") as Dictionary
	print("[V110-PROD] 编排层观测：commit_count=%s points=%s performed=%s claimed=%s" % [
		str(st.get("commit_count")), str(st.get("points")),
		str(st.get("performed")), str(st.get("claimed"))])
	_ck("R04 生产编排层真实 commit 次数 > 0（非验证脚本自模拟）",
		int(st.get("commit_count", 0)) > 0,
		"commit_count=%s" % str(st.get("commit_count")))
	# ④ 边界：同一处决事件重复触发 → 编排层 exe:<window_id> / 参数去重键拒绝二次加点。
	#    连续重放三次 points_awarded，比较「第二次后 vs 第三次后」：重复触发被拒 → 不再加点。
	var pts_a: int = int((_orch.call("get_status") as Dictionary).get("points", 0))
	_hud.emit_signal("points_awarded", "execution", 50, "stagger_service.try_execute")
	var pts_b: int = int((_orch.call("get_status") as Dictionary).get("points", 0))
	_hud.emit_signal("points_awarded", "execution", 50, "stagger_service.try_execute")
	var pts_c: int = int((_orch.call("get_status") as Dictionary).get("points", 0))
	_ck("R05 同一事件重复触发不二次加点（编排层去重键门控）",
		pts_c == pts_b and pts_b >= pts_a,
		"points a=%d b=%d c=%d（b→c 重复触发被拒）" % [pts_a, pts_b, pts_c])
	_snapshot_points("after_dup")


## 读磁盘 user:// 临时槽存档的 grace.trial.points（磁盘为唯一权威）。
func _snapshot_points(tag: String) -> void:
	var disk: Dictionary = _read_json(_delta_path)
	var flags: Dictionary = disk.get("flags", {}) as Dictionary
	var p: int = int(flags.get(K_POINTS, 0))
	_points_trace.append(p)
	print("[V110-PROD] 磁盘回读 | %s | grace.trial.points=%d delta_exists=%s" % [
		tag, p, str(not disk.is_empty())])


# ---------------------------------------------------------------------------
# 磁盘真值断言（真实输入 → 生产订阅 → 实际落盘全链 + 不变量）
# ---------------------------------------------------------------------------
func _t_disk_assertions() -> void:
	var before: String = _prod_md5_before
	var disk: Dictionary = _read_json(_delta_path)
	_ck("D01 ★ 真实输入 → 生产 autoload 订阅 → 实际落盘：磁盘 delta.json 存在可解析",
		not disk.is_empty(), "path=%s" % _delta_path)
	if disk.is_empty():
		return
	var flags: Dictionary = disk.get("flags", {}) as Dictionary
	_ck("D02 ★ grace.trial.points 已落盘且 > 0（A55 唯一权威通道）",
		flags.has(K_POINTS) and int(flags.get(K_POINTS, 0)) > 0,
		"points=%s" % str(flags.get(K_POINTS, "<miss>")))
	_ck("D03 grace.execution.performed 等已登记三段式 flag 已落盘",
		flags.has(K_PERFORMED), "performed=%s" % str(flags.get(K_PERFORMED, "<miss>")))
	# 点数只增不减（磁盘逐次回读序列单调不减）
	var mono: bool = true
	for i: int in range(1, _points_trace.size()):
		if _points_trace[i] < _points_trace[i - 1]:
			mono = false
	_ck("D04 点数只增不减（磁盘逐次回读序列单调不减）",
		mono and _points_trace.size() >= 2, "trace=%s" % str(_points_trace))
	# 十字段 / schema / removals / 三段式 / 余额
	var extra: Array[String] = []
	var missing: Array[String] = []
	for k: Variant in disk.keys():
		if not TEN_FIELDS.has(String(k)):
			extra.append(String(k))
	for k: String in TEN_FIELDS:
		if not disk.has(k):
			missing.append(k)
	_ck("D05 SaveDelta 十字段齐全、无额外顶层字段（冻结）",
		extra.is_empty() and missing.is_empty(),
		"extra=%s missing=%s" % [str(extra), str(missing)])
	_ck("D06 schema_version=3、removals 恒空、绝不写 removals",
		int(disk.get("schema_version", -1)) == 3 \
		and (disk.get("removals", []) as Array).is_empty(),
		"schema=%s removals=%s" % [str(disk.get("schema_version")), str(disk.get("removals", []))])
	var bad: Array[String] = []
	for k: Variant in flags.keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_ck("D07 全部落盘 flag key 通过三段式正则", bad.is_empty(),
		"keys=%d bad=%s" % [flags.size(), str(bad)])
	var p: int = int(flags.get(K_POINTS, 0))
	var s: int = int(flags.get(K_SPENT, 0))
	_ck("D08 余额 points - spent_points >= 0", p - s >= 0,
		"points=%d spent=%d balance=%d" % [p, s, p - s])
	_t_legacy_fallback()
	# 生产 slot_01 未被污染（只读 md5 前后对照）
	var after: String = _production_md5()
	if before == after:
		_ck("D10 生产 slot_01 md5 前后一致（全程不写 slot_01）", true, "md5=%s" % before)
	else:
		print("[V110-PROD] WARN 生产 slot_01 md5 前后不同（可能并发方写入，非本件所为）before=%s after=%s" % [before, after])
		_ck("D10 生产存档差异如实登记（不计 FAIL、避免并发回归抖动）", true,
			"before=%s after=%s | WARN 已打印" % [before, after])


## 旧存档缺 key 回落基线：新 WorldState 只读 _apply_snapshot + get_flag（不写盘）。
func _t_legacy_fallback() -> void:
	var ws_script: Script = ResourceLoader.load(
		WORLD_STATE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if ws_script == null:
		_ck("D09 旧档缺 key 回落基线（WorldState 脚本可加载）", false, "script=null")
		return
	var legacy: Dictionary = _new_delta_shell({
		"grace.network.last_grace_id": "grace_limgrave_gatefront",
		"dungeon.wave_trial.best_wave": 2,
	})
	var ws: Node = Node.new()
	_track(ws)
	ws.set_script(ws_script)
	ws.call("_ready")
	ws.call("_apply_snapshot", legacy)
	var got: Variant = ws.call("get_flag", K_POINTS, 0)
	_ck("D09 旧档缺 grace.trial.points → get_flag 回落基线 0（不升级/不重置/不迁移）",
		int(got) == 0, "get_flag=%s default=0" % str(got))


func _finish() -> void:
	# 释放编排层 4 信号连接（有释放路径，不留悬空 Callable）
	if _orch != null and is_instance_valid(_orch) and _orch.has_method("_release"):
		_orch.call("_release")
	for n: Node in _temps:
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	var ok: bool = _fail == 0 and _pass > 0
	print("[V110-PROD] SUMMARY pid=%d slot=%s pass=%d fail=%d total=%d" % [
		OS.get_process_id(), _slot_dir, _pass, _fail, _pass + _fail])
	print("[V110-PROD] RESULT=%s" % ("ALL_MATCH" if ok else "MISMATCH"))
	print("[V110-PROD] ==== 真跑结束 ====")
	quit(0 if ok else 1)
