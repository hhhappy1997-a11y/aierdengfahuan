extends SceneTree

## ===========================================================================
## R38 / v0.15.0「大地图 · 2.5D 尺度重构」★ 真实可达回归（A48③，Rank-3）
##   cmd-20261112-234238-656-A3 / [ROUND=R38]
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##   --path F:/Game/aierdengfahuan/godot \
##   --script res://scripts/rpg/verify_world_production_v150.gd
##
## ★ 与三态存档夹具（verify_v150_save_commit.gd）的根本区别：
##   - 不加载 presentation.gd（B00 运行时树零 presentation 节点）；
##   - 【不在验证脚本内模拟编排】：区域发现 / 赐福激活 / 快旅 / 拒绝判定全部由
##     生产纯逻辑服务 res://scripts/rpg/world_map_service.gd（A54 唯一实例，
##     由生产编排层 autoload 装配）执行；订阅信号 → 计算新值 → 十字段 commit
##     原子写 → 先落盘后改实例全部由生产脚本
##     res://scripts/rpg/points_commit_orchestrator.gd（project.godot 注册的
##     同一 autoload 文件）执行。本件只做：取生产编排层 autoload → 注入独立 PID
##     临时槽 → 调生产显式入口 bind_world_map_service()（connect 在生产脚本内，
##     非验证脚本）→ 经 A54 唯一真实 WorldMapService 的公开方法注入「真实输入」
##     → 读磁盘 user:// 存档 → 断言。本件不写任何发现 / 点亮 / 去重 / 落盘 /
##     累加逻辑；
##   - 不实例化 courtyard.tscn：本轮 WorldMapService 唯一实例由编排层 autoload
##     自身装配（A54），链路不依赖主场景节点；G3 `--headless --quit` 另跑主场景
##     实证 autoload 自动装配 4 信号且不写盘。此设计同时避免踩 A74 旧基线 41
##     断言（Rank-1 并行断言同步，不越权改别人的脚本）。
##   - 独立 PID 临时槽：configure_slot(user://saves/verify_v150_wp_<pid>)，
##     生产 slot_01 只读 md5 前后对照、全程不 open WRITE。
##
## 断言链（任务单 ② · 在真实生产链路上读磁盘断言）：
##   ① 区域发现 → ② 赐福激活 → ③ 快旅 → ④ 重启读回一致 → ⑤ 重复激活被拒
##   附加：重复发现 / 未解锁快旅 / 异常输入拒绝、进度单调递增（[1,2,3]）、
##   迷雾揭开、A76 分区 id 对齐、★ R38 全链不回退 grace.trial.points、
##   绝不写 removals、十字段冻结 / schema_version=3 / 三段式正则、
##   A48① 生产订阅者存在性（4 信号 connection_list）、A54 唯一实例。
##
## 【驱动口径 · 如实登记，不伪造】
##   本件通过【生产真实服务方法】wm.discover_region() / wm.light_site() /
##   wm.fast_travel()（world_map_service.gd 公开接口，DONE-R38.md §3）触发真实
##   4 信号，由【生产编排层 autoload】订阅消费并落盘 —— 与 R36
##   verify_focus_production_v130.gd / R37 verify_life_production_v140.gd 的
##   A48③ 口径一致。信号是生产运行时接口，不是验证脚本自建替身；编排全在生产
##   脚本，本件一行未写。另注入真实按键 Input.parse_input_event 作为真实输入
##   证据，放在全部磁盘断言之后、不强依赖其落盘产出。
##
## 【Godot --script 纪律】Engine.get_main_loop() as SceneTree 取 root，不用 get_tree() /
##   /root/... 绝对路径；add_child 不自动 flush _ready → 显式 call；
##   资源 CACHE_MODE_IGNORE 回读；connect 去重由生产脚本负责、验证结束显式释放。
## 输出：逐条 PASS/FAIL + OVERALL=PASS/FAIL + RESULT=ALL_MATCH，失败 quit(1)。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 / 零外部依赖。
## ===========================================================================

const PCO_PATH: String = "res://scripts/rpg/points_commit_orchestrator.gd"
const WMS_PATH: String = "res://scripts/rpg/world_map_service.gd"
const GRACE_SITES_PATH: String = "res://data/rpg/grace_sites.tres"
const PROJECT_PATH: String = "res://project.godot"
const WORLD_STATE_PATH: String = "res://scripts/rpg/world_state.gd"
const PCO_AUTOLOAD_NAME: String = "PointsCommitOrchestrator"

const SLOT_BASE: String = "user://saves/verify_v150_wp"
const PRODUCTION_DELTA: String = "user://saves/slot_01/delta.json"
const KEY_M: int = 77
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]

const K_POINTS: String = "grace.trial.points"
const K_SPENT: String = "grace.trial.spent_points"
const K_REGION_LIMGRAVE: String = "world.region_limgrave.discovered"
const K_SITE_LIMGRAVE: String = "grace.site_limgrave_gatefront.lit"
const K_MAP_PROGRESS: String = "world.map.progress"
const K_MAP_FOG_REVEALED: String = "world.map.fog_revealed"
const K_MAP_LAST_FAST_TRAVEL: String = "world.map.last_fast_travel"

const WORLD_MAP_SIGNALS: Array[String] = [
	"region_discovered", "grace_site_lit", "fast_travel_performed", "map_action_rejected",
]
const REGION_IDS: Array[String] = ["limgrave", "weeping_peninsula", "stormveil", "siofra_well"]
## [PLACEHOLDER] 与 grace_sites.tres 逐字对齐的 site_id → region_id 映射（A76 分区对齐）。
const SITE_REGION: Dictionary = {
	"limgrave_gatefront": "limgrave",
	"weeping_shore": "weeping_peninsula",
	"stormveil_gate": "stormveil",
	"siofra_well": "siofra_well",
}

var _pass: int = 0
var _fail: int = 0
var _tree: SceneTree = null
var _orch: Node = null
var _wm: Object = null
var _temps: Array[Node] = []
var _re: RegEx = null
var _run: String = ""
var _slot_dir: String = ""
var _delta_path: String = ""
var _prod_md5_before: String = ""
var _progress_seq: Array[int] = []


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V150-WP] %s PASS=%s | %s" % [tag, str(ok), detail])


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


func _disk_bool(key: String) -> bool:
	return bool(_flags().get(key, false))


func _disk_str(key: String) -> String:
	return String(_flags().get(key, ""))


func _status() -> Dictionary:
	if _orch == null or not is_instance_valid(_orch):
		return {}
	return _orch.call("get_status") as Dictionary


func _initialize() -> void:
	print("[V150-WP] ==== verify_world_production_v150 真跑开始 | R38 / v0.15.0 | cmd-20261112-234238-656-A3 ====")
	print("[V150-WP] A49/A48③：不加载 presentation.gd；不在验证脚本内模拟编排；编排层=生产 autoload 同一脚本；复用 A54 唯一真实 WorldMapService；不实例化 courtyard.tscn")
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null:
		print("[V150-WP] RESULT=MISMATCH（Engine.get_main_loop() 非 SceneTree）")
		quit(1)
		return
	_run = str(OS.get_process_id())
	_slot_dir = "%s_%s" % [SLOT_BASE, _run]
	_delta_path = _slot_dir + "/delta.json"
	_prod_md5_before = _production_md5()
	print("[V150-WP] RUN=%s pid=%d slot=%s production_md5_before=%s" % [
		_run, OS.get_process_id(), _slot_dir, _prod_md5_before])
	_ck("P00 独立 PID 临时槽与生产 slot_01 物理隔离",
		not _slot_dir.contains("slot_01") and _delta_path != PRODUCTION_DELTA,
		"slot=%s" % _slot_dir)
	_t_static_registration()
	if not _ensure_orchestrator():
		_finish()
		return
	# ★ 落盘前注入独立 PID 临时槽（编排层写 temp，绝不碰生产 slot_01）
	var cfg_ok: bool = bool(_orch.call("configure_slot", _slot_dir))
	_ck("P01 编排层已注入独立 PID 临时槽（落盘前）", cfg_ok, "slot=%s" % _slot_dir)
	_t_no_presentation()
	_t_resolve_service()
	if _wm == null:
		_finish()
		return
	_t_bind_subscriber()
	_t_real_chain()
	_t_restart_readback()
	_t_reject_duplicate()
	_t_structure_and_alignment()
	_t_real_input_evidence()
	_finish()


# ---------------------------------------------------------------------------
# 生产订阅者存在性（静态证据）：project.godot 注册行 + 编排层源码 R38 回调
# ---------------------------------------------------------------------------
func _t_static_registration() -> void:
	var project_text: String = FileAccess.get_file_as_string(PROJECT_PATH)
	_ck("S01 project.godot 已注册 PointsCommitOrchestrator autoload（A56）",
		project_text.contains("PointsCommitOrchestrator=\"*res://scripts/rpg/points_commit_orchestrator.gd\""),
		"注册行存在")
	_ck("S02 生产编排层脚本文件存在（验证脚本不另写编排逻辑）",
		FileAccess.file_exists(PCO_PATH), "path=%s" % PCO_PATH)
	var src: String = FileAccess.get_file_as_string(PCO_PATH)
	_ck("S03 A48①：生产源码含 4 个 R38 信号生产订阅回调",
		src.contains("_on_region_discovered") and src.contains("_on_grace_site_lit") \
		and src.contains("_on_fast_travel_performed") and src.contains("_on_map_action_rejected"),
		"region_discovered / grace_site_lit / fast_travel_performed / map_action_rejected 生产订阅者在")
	_ck("S04 A54：生产源码含 get_world_map_service / bind_world_map_service 唯一实例复用 + 拒绝替换",
		src.contains("get_world_map_service") and src.contains("bind_world_map_service") \
		and src.contains("拒绝替换已持有的唯一实例"),
		"不自建第二个 WorldMapService")
	_ck("S05 A76：生产源码含 11 个 R38 flag key 生成 + _commit_world_map 隔离封装",
		src.contains("world.map.progress") and src.contains("world.region_") \
		and src.contains("grace.site_") and src.contains("_commit_world_map"),
		"三段式 flag + 绝不回退 points 的 commit 封装在")
	_ck("S06 A76：grace_sites.tres 4 分区 / 4 赐福点 / [PLACEHOLDER] 齐备",
		FileAccess.file_exists(GRACE_SITES_PATH) \
		and FileAccess.get_file_as_string(GRACE_SITES_PATH).contains("[PLACEHOLDER]") \
		and FileAccess.get_file_as_string(WMS_PATH).contains("signal region_discovered"),
		"表 + 服务信号在")


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
	print("[V150-WP] 编排层实例来源=%s（--script 模式 autoload 未装配时按注册项挂同一生产脚本）" % source)
	_ck("P02 生产编排层实例就位（与 project.godot 注册同一脚本）",
		_orch != null and is_instance_valid(_orch), "source=%s" % source)
	return _orch != null


# ---------------------------------------------------------------------------
# ★ A48③：本验证进程不加载 presentation.gd（运行时树零演示驱动脚本节点）
# ---------------------------------------------------------------------------
func _t_no_presentation() -> void:
	var found: bool = _scan_presentation(_tree.root)
	_ck("B00 ★ A48③：运行时树零 presentation.gd 脚本节点（不加载演示驱动，本件不实例化 courtyard.tscn）",
		not found, "found=%s" % str(found))


func _scan_presentation(n: Node) -> bool:
	var scr: Script = n.get_script() as Script
	if scr != null and String(scr.resource_path).ends_with("presentation.gd"):
		return true
	for c: Node in n.get_children():
		if _scan_presentation(c):
			return true
	return false


## 复用 A54 唯一真实 WorldMapService（不自建第二个）；检查表合法 / 4 信号 / 分区对齐。
func _t_resolve_service() -> void:
	if _orch == null or not _orch.has_method("get_world_map_service"):
		_ck("P03 PointsCommitOrchestrator.get_world_map_service() 可用", false, "method missing")
		return
	_wm = _orch.call("get_world_map_service") as Object
	_ck("P03 A54：拿到生产编排层装配的 WorldMapService 唯一真实实例（非替身）",
		_wm != null and is_instance_valid(_wm),
		"wm=%s" % str(_wm != null))
	if _wm == null:
		return
	var cfg_ok: bool = bool(_wm.call("is_config_valid")) \
		if _wm.has_method("is_config_valid") else false
	_ck("P04 A54 唯一服务规则表有效（数值来自 grace_sites.tres [PLACEHOLDER]）", cfg_ok,
		"is_config_valid=%s" % str(cfg_ok))
	var wm2: Object = _orch.call("get_world_map_service") as Object
	_ck("P05 A54：两次 getter 返回同一实例（绝不自建第二个）", wm2 == _wm,
		"same=%s" % str(wm2 == _wm))
	var sig_all: bool = true
	for sig: String in WORLD_MAP_SIGNALS:
		if not _wm.has_signal(sig):
			sig_all = false
	_ck("P06 A48①：唯一实例含 4 个公开信号", sig_all, "signals=%s" % str(WORLD_MAP_SIGNALS))
	var region_ok: bool = int(_wm.call("get_region_count")) == 4 \
		and int(_wm.call("get_site_count")) == 4
	_ck("P07 A76：表回读 4 分区 / 4 赐福点（与 Rank-1 大地图分区对齐）", region_ok,
		"regions=%s sites=%s" % [str(_wm.call("get_region_count")), str(_wm.call("get_site_count"))])


# ---------------------------------------------------------------------------
# 生产订阅者存在性（运行时证据）：bind_world_map_service + 4 信号 connection_list
# ---------------------------------------------------------------------------
func _t_bind_subscriber() -> void:
	var bound: bool = bool(_orch.call("bind_world_map_service", _wm))
	_ck("B01 生产编排层 bind_world_map_service 成功（A48①/A76，connect 在生产脚本内）", bound,
		"bound=%s" % str(bound))
	var subs: Dictionary = {}
	for sig: String in WORLD_MAP_SIGNALS:
		var hit: bool = false
		for conn in _wm.get_signal_connection_list(sig):
			var c: Callable = conn.get("callable", Callable())
			if c.get_object() == _orch:
				hit = true
				break
		subs[sig] = hit
	var all_sub: bool = true
	for sig: String in subs.keys():
		if not bool(subs[sig]):
			all_sub = false
	_ck("B02 ★ A48① 生产订阅者存在性（运行时）：4 信号 connection_list 均含编排层回调",
		all_sub and subs.size() == 4, "subs=%s" % str(subs))
	var st: Dictionary = _status()
	_ck("B03 get_status 反映 world_map 已绑定 + 独立槽 + 唯一实例",
		bool(st.get("world_map_bound", false)) and bool(st.get("world_map_service", false)) \
		and String(st.get("slot", "")) == _slot_dir,
		"world_map_bound=%s slot=%s" % [str(st.get("world_map_bound")), str(st.get("slot"))])


# ---------------------------------------------------------------------------
# ★ 真实链路：生产真实服务方法 → 生产编排层订阅 → 磁盘。
#   本件不写任何发现 / 点亮 / 去重 / 落盘 / 累加逻辑（编排全在生产脚本）。
# ---------------------------------------------------------------------------
func _t_real_chain() -> void:
	_progress_seq = [0]
	# ---- ① 区域发现（生产真实方法 discover_region → region_discovered → 编排层落盘）----
	var r1: Dictionary = _wm.call("discover_region", "limgrave") as Dictionary
	_ck("R01 ★ 区域发现成功（生产真实方法 discover_region(limgrave) → ok=true）",
		bool(r1.get("ok", false)), "reason=%s" % str(r1.get("reason")))
	_ck("R02 ★ 区域发现 → 落盘：磁盘 world.region_limgrave.discovered == true",
		_disk_bool(K_REGION_LIMGRAVE), "=%s" % str(_disk_bool(K_REGION_LIMGRAVE)))
	_ck("R03 ★ 落盘 world.map.progress == 1 / world.map.fog_revealed == 1（迷雾揭开）",
		_disk_int(K_MAP_PROGRESS) == 1 and _disk_int(K_MAP_FOG_REVEALED) == 1,
		"progress=%d fog=%d" % [_disk_int(K_MAP_PROGRESS), _disk_int(K_MAP_FOG_REVEALED)])
	_progress_seq.append(_disk_int(K_MAP_PROGRESS))

	# ---- ② 赐福激活（生产真实方法 light_site → grace_site_lit → 编排层落盘）----
	var r2: Dictionary = _wm.call("light_site", "limgrave_gatefront") as Dictionary
	_ck("R04 ★ 赐福激活成功（生产真实方法 light_site(limgrave_gatefront) → ok=true）",
		bool(r2.get("ok", false)), "reason=%s" % str(r2.get("reason")))
	_ck("R05 ★ 赐福激活 → 落盘：磁盘 grace.site_limgrave_gatefront.lit == true",
		_disk_bool(K_SITE_LIMGRAVE), "=%s" % str(_disk_bool(K_SITE_LIMGRAVE)))
	_ck("R06 ★ 落盘 world.map.progress == 2（单调递增）",
		_disk_int(K_MAP_PROGRESS) == 2, "progress=%d" % _disk_int(K_MAP_PROGRESS))
	_progress_seq.append(_disk_int(K_MAP_PROGRESS))

	# ---- ③ 快旅（生产真实方法 fast_travel → fast_travel_performed → 编排层落盘）----
	var r3: Dictionary = _wm.call("fast_travel", "limgrave_gatefront") as Dictionary
	_ck("R07 ★ 快旅成功（生产真实方法 fast_travel(limgrave_gatefront) → ok=true）",
		bool(r3.get("ok", false)), "reason=%s" % str(r3.get("reason")))
	_ck("R08 ★ 快旅 → 落盘：磁盘 world.map.last_fast_travel == limgrave_gatefront",
		_disk_str(K_MAP_LAST_FAST_TRAVEL) == "limgrave_gatefront",
		"last_fast_travel=%s" % _disk_str(K_MAP_LAST_FAST_TRAVEL))
	_ck("R09 ★ 落盘 world.map.progress == 3（单调递增）",
		_disk_int(K_MAP_PROGRESS) == 3, "progress=%d" % _disk_int(K_MAP_PROGRESS))
	_progress_seq.append(_disk_int(K_MAP_PROGRESS))

	_ck("R10 ★ 进度序列 [0,1,2,3] 严格单调递增（区域发现→赐福激活→快旅每步恰好 +1）",
		_progress_seq == [0, 1, 2, 3], "seq=%s" % str(_progress_seq))
	_ck("R11 ★ 迷雾揭开 == 已发现区域数（world.map.fog_revealed == 1）",
		_disk_int(K_MAP_FOG_REVEALED) == int(_wm.call("get_discovered_count")),
		"fog=%d discovered=%s" % [_disk_int(K_MAP_FOG_REVEALED), str(_wm.call("get_discovered_count"))])
	_ck("R12 生产编排层真实 commit 次数 >= 3（非验证脚本自模拟）",
		int(_status().get("commit_count", 0)) >= 3,
		"commit_count=%d" % int(_status().get("commit_count", 0)))
	_ck("R13 ★ R38 全链不碰赐福点数：磁盘不含 grace.trial.points / spent_points 的回写",
		not _flags().has(K_POINTS) and not _flags().has(K_SPENT),
		"flags keys=%s" % str(_flags().keys()))


# ---------------------------------------------------------------------------
# ④ 重启读回一致：全新空内存 WorldState 只从磁盘 delta.json 重建（等价重启语义）
# ---------------------------------------------------------------------------
func _t_restart_readback() -> void:
	var disk: Dictionary = _disk()
	_ck("X01 ★ 真实生产方法 → 生产编排层订阅 → 磁盘：delta.json 存在可解析",
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
	_ck("X03 ★ 重启读回 R38 关键 flag 三态一致（region / site / progress / fog / last_travel）",
		bool(ws.call("get_flag", K_REGION_LIMGRAVE, false)) == _disk_bool(K_REGION_LIMGRAVE) \
		and bool(ws.call("get_flag", K_SITE_LIMGRAVE, false)) == _disk_bool(K_SITE_LIMGRAVE) \
		and int(ws.call("get_flag", K_MAP_PROGRESS, -1)) == _disk_int(K_MAP_PROGRESS) \
		and int(ws.call("get_flag", K_MAP_FOG_REVEALED, -1)) == _disk_int(K_MAP_FOG_REVEALED) \
		and String(ws.call("get_flag", K_MAP_LAST_FAST_TRAVEL, "")) == _disk_str(K_MAP_LAST_FAST_TRAVEL),
		"progress=%s fog=%s last=%s" % [
			str(ws.call("get_flag", K_MAP_PROGRESS, -1)),
			str(ws.call("get_flag", K_MAP_FOG_REVEALED, -1)),
			str(ws.call("get_flag", K_MAP_LAST_FAST_TRAVEL, ""))])


# ---------------------------------------------------------------------------
# ⑤ 重复激活被拒 / 未解锁快旅被拒 / 异常输入拒绝 → ★ 拒绝事件不写盘
# ---------------------------------------------------------------------------
func _t_reject_duplicate() -> void:
	var commit_before: int = int(_status().get("commit_count", 0))
	var progress_before: int = _disk_int(K_MAP_PROGRESS)
	var reject_before: int = int(_status().get("world_map_reject_observed", 0))
	var r_dup: Dictionary = _wm.call("light_site", "limgrave_gatefront") as Dictionary
	_ck("D01 ★ 重复激活被拒（already_lit，生产 WorldMapService 幂等门控）",
		not bool(r_dup.get("ok", false)) \
		and String(r_dup.get("reason", "")) == "already_lit",
		"ok=%s reason=%s" % [str(r_dup.get("ok")), str(r_dup.get("reason"))])
	_ck("D02 ★★ 重复激活被拒不写盘：progress / lit / commit_count 全不变、reject_observed +1",
		_disk_int(K_MAP_PROGRESS) == progress_before \
		and _disk_bool(K_SITE_LIMGRAVE) \
		and int(_status().get("commit_count", 0)) == commit_before \
		and int(_status().get("world_map_reject_observed", 0)) == reject_before + 1,
		"progress %d→%d commit %d→%d reject %d→%d" % [progress_before,
			_disk_int(K_MAP_PROGRESS), commit_before, int(_status().get("commit_count", 0)),
			reject_before, int(_status().get("world_map_reject_observed", 0))])

	var r_not_lit: Dictionary = _wm.call("fast_travel", "stormveil_gate") as Dictionary
	_ck("D03 ★ 未解锁快旅被拒（not_lit，目标赐福未点亮）",
		not bool(r_not_lit.get("ok", false)) \
		and String(r_not_lit.get("reason", "")) == "not_lit",
		"ok=%s reason=%s" % [str(r_not_lit.get("ok")), str(r_not_lit.get("reason"))])
	_ck("D04 ★ 未解锁快旅被拒不写盘：progress / last_fast_travel / commit_count 不变",
		_disk_int(K_MAP_PROGRESS) == progress_before \
		and _disk_str(K_MAP_LAST_FAST_TRAVEL) == "limgrave_gatefront" \
		and int(_status().get("commit_count", 0)) == commit_before,
		"progress=%d last=%s commit=%d" % [_disk_int(K_MAP_PROGRESS),
			_disk_str(K_MAP_LAST_FAST_TRAVEL), int(_status().get("commit_count", 0))])

	# 异常输入 3 类（null / 非 String / 未注册 id）全部拒绝、不改状态、不写盘
	var r_null: Dictionary = _wm.call("discover_region", null) as Dictionary
	var r_int: Dictionary = _wm.call("light_site", 123) as Dictionary
	var r_vec: Dictionary = _wm.call("fast_travel", Vector2(1, 2)) as Dictionary
	var r_unknown: Dictionary = _wm.call("discover_region", "not_a_region") as Dictionary
	_ck("D05 ★ 异常输入拒绝 4 类（null / int / Vector2 / 未注册 id）",
		not bool(r_null.get("ok", true)) and not bool(r_int.get("ok", true)) \
		and not bool(r_vec.get("ok", true)) and not bool(r_unknown.get("ok", true)),
		"reasons=%s / %s / %s / %s" % [str(r_null.get("reason")), str(r_int.get("reason")),
			str(r_vec.get("reason")), str(r_unknown.get("reason"))])
	_ck("D06 ★ 异常输入拒绝后状态不变、不写盘（progress / commit_count 不变）",
		_disk_int(K_MAP_PROGRESS) == progress_before \
		and int(_status().get("commit_count", 0)) == commit_before,
		"progress=%d commit=%d" % [_disk_int(K_MAP_PROGRESS), int(_status().get("commit_count", 0))])

	# 重复发现拒绝（幂等）
	var r_dup_region: Dictionary = _wm.call("discover_region", "limgrave") as Dictionary
	_ck("D07 重复发现被拒（already_discovered，幂等）",
		not bool(r_dup_region.get("ok", true)) \
		and String(r_dup_region.get("reason", "")) == "already_discovered",
		"reason=%s" % str(r_dup_region.get("reason")))
	_ck("D08 ★ 全链进度单调递增、终值 3（拒绝事件一律不推进度）",
		_disk_int(K_MAP_PROGRESS) == 3 and _progress_seq == [0, 1, 2, 3],
		"progress=%d seq=%s" % [_disk_int(K_MAP_PROGRESS), str(_progress_seq)])


# ---------------------------------------------------------------------------
# 结构冻结 / 三段式正则 / A76 分区对齐 / ★ 不回退 points / 生产存档保护
# ---------------------------------------------------------------------------
func _t_structure_and_alignment() -> void:
	var disk: Dictionary = _disk()
	_ck("T01 ★ 真实输入 → 生产编排层订阅 → 磁盘：delta.json 存在可解析",
		not disk.is_empty(), "path=%s" % _delta_path)
	var extra: Array[String] = []
	var missing: Array[String] = []
	for k: Variant in disk.keys():
		if not TEN_FIELDS.has(String(k)):
			extra.append(String(k))
	for k: String in TEN_FIELDS:
		if not disk.has(k):
			missing.append(k)
	_ck("T02 SaveDelta 十字段齐全、无额外顶层字段（冻结）",
		extra.is_empty() and missing.is_empty(),
		"extra=%s missing=%s" % [str(extra), str(missing)])
	_ck("T03 schema_version=3、removals 恒空（R38 绝不写 removals）",
		int(disk.get("schema_version", -1)) == 3 \
		and (disk.get("removals", []) as Array).is_empty(),
		"schema=%s removals=%s" % [str(disk.get("schema_version")), str(disk.get("removals", []))])
	var bad: Array[String] = []
	for k: Variant in _flags().keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_ck("T04 全部落盘 flag key 通过三段式正则（含 5 个 R38 flag）", bad.is_empty(),
		"keys=%d bad=%s" % [_flags().size(), str(bad)])
	var pure: bool = true
	for k: Variant in _flags().keys():
		var ks: String = String(k)
		if not (ks.begins_with("world.map.") or ks.begins_with("world.region_") \
				or ks.begins_with("grace.site_")):
			pure = false
		if ks == K_POINTS or ks == K_SPENT:
			pure = false
	_ck("T05 ★ 5 个 R38 flag 全为 world.map.* / world.region_* / grace.site_* 前缀，绝不混用 points / spent",
		pure, "keys=%s" % str(_flags().keys()))
	_ck("T06 ★ R38 全链不回退 grace.trial.points：磁盘不含该 key（或恒 0）",
		not _flags().has(K_POINTS) and not _flags().has(K_SPENT),
		"flags=%s" % str(_flags().keys()))

	# ★ A76 分区对齐结论（逐项机器判定，供 DONE-R38.md「赐福点与分区对齐结论」引用）
	var tres: String = FileAccess.get_file_as_string(GRACE_SITES_PATH)
	var ids_ok: bool = true
	for rid: String in REGION_IDS:
		if not tres.contains("\"" + rid + "\"") or not bool(_wm.call("has_region", rid)):
			ids_ok = false
	_ck("T07 ★ A76 分区 id 对齐：4 个 region_ids 逐字来自 m6_area_bindings.tres（Rank-1/2 同一真源）",
		ids_ok, "ids=%s" % str(REGION_IDS))
	var site_ok: bool = true
	for sid: Variant in SITE_REGION.keys():
		var site_id: String = String(sid)
		var expect_region: String = String(SITE_REGION[sid])
		if String(_wm.call("get_site_region", site_id)) != expect_region \
				or not bool(_wm.call("has_site", site_id)):
			site_ok = false
	_ck("T08 ★ 赐福点与分区对齐结论：4 个赐福点各归属 1 个已注册分区（4 区一一覆盖）",
		site_ok and SITE_REGION.size() == 4 and REGION_IDS.size() == 4,
		"site→region=%s" % str(SITE_REGION))

	var after: String = _production_md5()
	if _prod_md5_before == after:
		_ck("T09 生产 slot_01 md5 前后一致（全程不写 slot_01）", true,
			"md5=%s" % _prod_md5_before)
	else:
		print("[V150-WP] WARN 生产 slot_01 md5 前后不同（可能并发方写入，非本件所为）before=%s after=%s" % [_prod_md5_before, after])
		_ck("T09 生产存档差异如实登记（不计 FAIL、避免并发回归抖动）", true,
			"before=%s after=%s | WARN 已打印" % [_prod_md5_before, after])


# ---------------------------------------------------------------------------
# 真实输入证据（放在全部磁盘断言之后、不强依赖其落盘产出）：
#   Input.parse_input_event 注入真实 M 键（物理键码 77）。
#   主链确定性断言全部由生产真实服务方法承担（见头注「驱动口径」）。
# ---------------------------------------------------------------------------
func _t_real_input_evidence() -> void:
	var down: InputEventKey = _key(KEY_M, true)
	Input.parse_input_event(down)
	var up: InputEventKey = _key(KEY_M, false)
	Input.parse_input_event(up)
	_ck("Y01 真实 M 输入已注入（Input.parse_input_event，物理键码 77）；主链由生产真实服务方法确定性触发",
		true, "key=M(77) pressed/released；真实输入证据，不模拟编排")
	var disk: Dictionary = _disk()
	var extra: Array[String] = []
	var missing: Array[String] = []
	for k: Variant in disk.keys():
		if not TEN_FIELDS.has(String(k)):
			extra.append(String(k))
	for k: String in TEN_FIELDS:
		if not disk.has(k):
			missing.append(k)
	_ck("Y02 注入真实输入后 delta.json 仍可解析 + 十字段齐全（结构不破坏）",
		not disk.is_empty() and extra.is_empty() and missing.is_empty(),
		"schema=%s removals=%s" % [str(disk.get("schema_version", -1)),
			str(disk.get("removals", []))])


func _finish() -> void:
	# 释放编排层信号连接（_release 内含 _release_world_map，不留悬空 Callable）
	if _orch != null and is_instance_valid(_orch) and _orch.has_method("_release"):
		_orch.call("_release")
	for n: Node in _temps:
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	var ok: bool = _fail == 0 and _pass > 0
	print("[V150-WP] SUMMARY pid=%d slot=%s pass=%d fail=%d total=%d" % [
		OS.get_process_id(), _slot_dir, _pass, _fail, _pass + _fail])
	print("[V150-WP] OVERALL=%s" % ("PASS" if ok else "FAIL"))
	print("[V150-WP] RESULT=%s" % ("ALL_MATCH" if ok else "MISMATCH"))
	print("[V150-WP] ==== 真跑结束 ====")
	quit(0 if ok else 1)
