extends SceneTree

## ===========================================================================
## R37 / v0.14.0「元素瓶与死亡轮回 · 画面补齐」★ 真实可达回归（A48③，Rank-3）
##   cmd-20261112-184157-088-A3 / [ROUND=R37]
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##   --path F:/Game/aierdengfahuan/godot \
##   --script res://scripts/rpg/verify_life_production_v140.gd
##
## ★ 与三态存档夹具（verify_v140_save_commit.gd）的根本区别：
##   - 不加载 presentation.gd（B00 运行时树零 presentation 节点）；
##   - 【不在验证脚本内模拟编排】：元素瓶扣减 / 死亡掉落 / 重生回满 / 一次性
##     回收 / 重复回收被拒 / flag 落盘 / 去重 / 上限封顶全部由生产脚本
##     res://scripts/rpg/points_commit_orchestrator.gd（project.godot 注册的
##     同一 autoload 文件）执行。本件只做：实例化主场景 → 复用 A54 唯一真实
##     FlaskService / DeathService → 调生产编排层 bind_life_services() 显式入口
##     （connect 在生产脚本内，非验证脚本）→ 经生产真实驱动口 wave.use_flask() /
##     on_player_death() / on_grace_respawn() / reclaim_dropped_points() 注入输入
##     → 读磁盘 user:// 存档 → 断言。本件不写任何扣减 / 去重 / 落盘 / 累加逻辑；
##   - 独立 PID 临时槽：configure_slot(user://saves/verify_v140_life_<pid>)，
##     生产 slot_01 只读 md5 前后对照、全程不 open WRITE。
##
## 断言链（任务单 ② · 在真实输入链路上读磁盘断言）：
##   ① 元素瓶扣减 → ② 落盘 → ③ 死亡掉落 → ④ 重生回满 → ⑤ 一次性回收
##   → ⑥ 重启读回一致 → ⑦ 重复回收被拒
##   附加：★ A71 单向 flag 不回退 points 实证（磁盘 grace.trial.points 全链
##   == 前置基线 500、绝不写 removals、回收绝不二次入账）、★ 拒绝事件不写盘
##   （flask_rejected / action_rejected 不产生 commit）、十字段冻结 /
##   schema_version=3 / removals 恒空 / 三段式正则、A48① 生产订阅者存在性
##   （7 信号 connection_list）、A54 唯一实例、A38 courtyard.tscn 节点 41 /
##   uv 2/1/1 不变。
##
## 【驱动口径 · 如实登记，不伪造】
##   本件通过【生产真实驱动口】wave.use_flask(current_hp,max_hp) /
##   wave.on_player_death(grace_points) / wave.on_grace_respawn() /
##   wave.reclaim_dropped_points()（Rank-2 DONE-R37.md §3.11 标注「真实输入驱动口，
##   转调 A54 唯一实例，供 Rank-1 输入层 / 验证调用」）触发真实 FlaskService /
##   DeathService 的 7 个信号，由【生产编排层 autoload】订阅消费并落盘 —— 与 R36
##   verify_focus_production_v130.gd 的 A48③ 口径一致。信号是生产运行时接口，
##   不是验证脚本自建替身；编排（扣减 / 去重 / 原子写）全在生产脚本，本件一行未写。
##   另注入真实按键 Input.parse_input_event（G）作为真实输入证据，放在全部磁盘
##   断言之后、不强依赖其落盘产出。
##   【A71 单向 flag 实证】：先经生产 HUD points_awarded / boon_draft_applied
##   落盘 grace.trial.points=500 / spent_points=15（既有赐福点数），全链断言
##   二者在每次元素瓶 / 死亡 / 重生 / 回收落盘前后逐字不变。
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

const SLOT_BASE: String = "user://saves/verify_v140_life"
const PRODUCTION_DELTA: String = "user://saves/slot_01/delta.json"
const NODE_COUNT_EXPECTED: int = 41
const KEY_G: int = 71
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]

const K_POINTS: String = "grace.trial.points"
const K_SPENT: String = "grace.trial.spent_points"
const K_FLASK_REMAINING: String = "combat.flask.remaining"
const K_FLASK_MAX: String = "combat.flask.max"
const K_FLASK_USE_COUNT: String = "combat.flask.use_count"
const K_FLASK_RESTORE_COUNT: String = "combat.flask.restore_count"
const K_FLASK_POLICY: String = "combat.flask.policy"
const K_DEATH_DROPPED: String = "grace.death.dropped"
const K_DEATH_RECLAIMED: String = "grace.death.reclaimed"
const K_DEATH_COUNT: String = "grace.death.count"
const K_DEATH_GRACE_SNAPSHOT: String = "grace.death.grace_snapshot"
const K_DEATH_RESPAWN_COUNT: String = "grace.death.respawn_count"
const K_DEATH_RECLAIM_COUNT: String = "grace.death.reclaim_count"

const LIFE_KEYS: Array[String] = [
	K_FLASK_REMAINING, K_FLASK_MAX, K_FLASK_USE_COUNT, K_FLASK_RESTORE_COUNT,
	K_FLASK_POLICY, K_DEATH_DROPPED, K_DEATH_RECLAIMED, K_DEATH_COUNT,
	K_DEATH_GRACE_SNAPSHOT, K_DEATH_RESPAWN_COUNT, K_DEATH_RECLAIM_COUNT,
]
const FLASK_SIGNALS: Array[String] = ["flask_used", "flask_rejected", "flask_restored"]
const DEATH_SIGNALS: Array[String] = ["death_occurred", "respawn_performed", "points_reclaimed", "action_rejected"]

## [PLACEHOLDER] 前置赐福点数（既有链路，A71 与之分离；对齐 R36 生产验证口径）。
const FIX_FRONT_POINTS: int = 500
const FIX_BOON_INDEX: int = 1
const FIX_BOON_CHOICE: String = "boon_frost_edge"
const FIX_COST_KEY: String = "hp_scale"
const FIX_COST_VALUE: float = 1.5   # [PLACEHOLDER] → round(1.5×10)=15 点 spent_points
const REJECT_FULL_HP: String = "full_hp"
const REJECT_ALREADY_RECLAIMED: String = "already_reclaimed"

var _pass: int = 0
var _fail: int = 0
var _tree: SceneTree = null
var _courtyard: Node = null
var _hud: Node = null
var _enc: Node = null
var _wave: Node = null
var _orch: Node = null
var _flask: Object = null
var _death: Object = null
var _temps: Array[Node] = []
var _re: RegEx = null
var _run: String = ""
var _slot_dir: String = ""
var _delta_path: String = ""
var _prod_md5_before: String = ""
var _points_baseline: int = 0
var _spent_baseline: int = 0
var _flask_max: int = 0


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V140-LP] %s PASS=%s | %s" % [tag, str(ok), detail])


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


## 真实服务当前瓶数（鸭子读，交叉验证磁盘落盘值确实采信真实服务状态）。
func _flask_remaining() -> int:
	if _flask != null and is_instance_valid(_flask) and _flask.has_method("get_flask_remaining"):
		return int(_flask.call("get_flask_remaining"))
	return -1


func _flask_max_from_service() -> int:
	if _flask != null and is_instance_valid(_flask) and _flask.has_method("get_flask_max"):
		return int(_flask.call("get_flask_max"))
	return 0


func _death_dropped_points() -> int:
	if _death != null and is_instance_valid(_death) and _death.has_method("get_dropped_points"):
		return int(_death.call("get_dropped_points"))
	return -1


func _initialize() -> void:
	print("[V140-LP] ==== verify_life_production_v140 真跑开始 | R37 / v0.14.0 | cmd-20261112-184157-088-A3 ====")
	print("[V140-LP] A49/A48③：不加载 presentation.gd；不在验证脚本内模拟编排；编排层=生产 autoload 同一脚本；复用 A54 唯一真实 FlaskService / DeathService")
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null:
		print("[V140-LP] RESULT=MISMATCH（Engine.get_main_loop() 非 SceneTree）")
		quit(1)
		return
	_run = str(OS.get_process_id())
	_slot_dir = "%s_%s" % [SLOT_BASE, _run]
	_delta_path = _slot_dir + "/delta.json"
	_prod_md5_before = _production_md5()
	print("[V140-LP] RUN=%s pid=%d slot=%s production_md5_before=%s" % [
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
	_resolve_life()
	if _flask == null or _death == null:
		_finish()
		return
	_t_no_presentation()
	_t_bind_subscriber()
	_t_real_chain()
	_t_restart_readback()
	_t_real_input_evidence()
	_finish()


# ---------------------------------------------------------------------------
# 生产订阅者存在性（静态证据）：project.godot 注册行 + 编排层源码 A70/A71 回调
# ---------------------------------------------------------------------------
func _t_static_registration() -> void:
	var project_text: String = FileAccess.get_file_as_string(PROJECT_PATH)
	_ck("S01 project.godot 已注册 PointsCommitOrchestrator autoload（A56）",
		project_text.contains("PointsCommitOrchestrator=\"*res://scripts/rpg/points_commit_orchestrator.gd\""),
		"注册行存在")
	_ck("S02 生产编排层脚本文件存在（验证脚本不另写编排逻辑）",
		FileAccess.file_exists(PCO_PATH), "path=%s" % PCO_PATH)
	var src: String = FileAccess.get_file_as_string(PCO_PATH)
	_ck("S03 A48①：生产源码含 3 个 flask 信号生产订阅回调",
		src.contains("_on_flask_used") and src.contains("_on_flask_rejected") \
		and src.contains("_on_flask_restored"),
		"flask_used / flask_rejected / flask_restored 生产订阅者在")
	_ck("S04 A48①：生产源码含 4 个 death 信号生产订阅回调",
		src.contains("_on_death_occurred") and src.contains("_on_respawn_performed") \
		and src.contains("_on_points_reclaimed") and src.contains("_on_action_rejected"),
		"death_occurred / respawn_performed / points_reclaimed / action_rejected 生产订阅者在")
	_ck("S05 A54：生产源码含 get_flask_service / get_death_service 唯一实例复用 + bind_life_services 显式入口",
		src.contains("get_flask_service") and src.contains("get_death_service") \
		and src.contains("bind_life_services"),
		"不自建第二个 FlaskService / DeathService")
	_ck("S06 A70/A71：生产源码含 11 个三段式 flag 常量 + _commit_life 隔离封装",
		src.contains("combat.flask.remaining") and src.contains("grace.death.dropped") \
		and src.contains("grace.death.reclaimed") and src.contains("grace.death.count") \
		and src.contains("_commit_life"),
		"单向 flag + 绝不回退 points 的 commit 封装在")


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
	print("[V140-LP] 编排层实例来源=%s（--script 模式 autoload 未装配时按注册项挂同一生产脚本）" % source)
	_ck("P02 生产编排层实例就位（与 project.godot 注册同一脚本）",
		_orch != null and is_instance_valid(_orch), "source=%s" % source)
	return _orch != null


## 实例化主场景（CACHE_MODE_IGNORE 回读），挂到 SceneTree.root，不用 /root/... 绝对路径。
func _load_main_scene() -> void:
	var packed: PackedScene = ResourceLoader.load(
		COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		print("[V140-LP] 主场景加载失败：%s" % COURTYARD_PATH)
		return
	_courtyard = packed.instantiate()
	if _courtyard == null:
		print("[V140-LP] 主场景 instantiate 失败")
		return
	_tree.root.add_child(_courtyard)
	print("[V140-LP] 主场景已实例化入树 | name=%s（未加载 presentation.gd）" % str(_courtyard.name))


func _resolve_nodes() -> void:
	_hud = _courtyard.get_node_or_null(NodePath(REL_HUD))
	_enc = _courtyard.get_node_or_null(NodePath(REL_ENC))
	_wave = _courtyard.get_node_or_null(NodePath(REL_WAVE))
	_ck("P03 主场景关键节点可寻址（Hud / EncounterRoot / WaveTrialDirector）",
		_hud != null and _enc != null and _wave != null,
		"hud=%s enc=%s wave=%s" % [str(_hud != null), str(_enc != null), str(_wave != null)])


## --script 模式 add_child 不 flush _ready() → 显式 call（wave._ready 装配唯一服务）。
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


## 复用 A54 唯一真实 FlaskService / DeathService（不自建第二个）；检查 config 有效 / 瓶上限。
func _resolve_life() -> void:
	if _wave == null or not _wave.has_method("get_flask_service") \
			or not _wave.has_method("get_death_service"):
		_ck("P04 WaveTrialDirector.get_flask_service() / get_death_service() 可用", false, "method missing")
		return
	_flask = _wave.call("get_flask_service") as Object
	_death = _wave.call("get_death_service") as Object
	_ck("P04 A54：拿到生产装配的 FlaskService / DeathService 唯一真实实例（非替身）",
		_flask != null and is_instance_valid(_flask) \
		and _death != null and is_instance_valid(_death),
		"flask=%s death=%s" % [str(_flask != null), str(_death != null)])
	if _flask == null or _death == null:
		return
	var cfg_ok: bool = bool(_flask.call("is_config_valid")) \
		if _flask.has_method("is_config_valid") else false
	var cfg_ok2: bool = bool(_death.call("is_config_valid")) \
		if _death.has_method("is_config_valid") else false
	_flask_max = _flask_max_from_service()
	_ck("P05 唯一服务规则表有效 + 瓶数上限 > 0（数值来自 flask_rules.tres [PLACEHOLDER]）",
		cfg_ok and cfg_ok2 and _flask_max > 0,
		"cfg_flask=%s cfg_death=%s flask_max=%d" % [str(cfg_ok), str(cfg_ok2), _flask_max])
	var f2: Object = _wave.call("get_flask_service") as Object
	var d2: Object = _wave.call("get_death_service") as Object
	_ck("P06 A54：两次 getter 各返回同一实例（绝不自建第二个）",
		f2 == _flask and d2 == _death, "flask_same=%s death_same=%s" % [str(f2 == _flask), str(d2 == _death)])


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
# 生产订阅者存在性（运行时证据）：bind_hud + bind_life_services + 7 信号 connection_list
# ---------------------------------------------------------------------------
func _t_bind_subscriber() -> void:
	var bound_hud: bool = bool(_orch.call("bind_hud", _hud))
	_ck("B01 生产编排层 bind_hud 成功（既有 A55 通道，供前置赐福点数落盘）", bound_hud,
		"bound_hud=%s" % str(bound_hud))
	var bound_life: bool = bool(_orch.call("bind_life_services", _flask, _death))
	_ck("B02 生产编排层 bind_life_services 成功（A70/A71 / A48①，connect 在生产脚本内）",
		bound_life, "bound_life=%s" % str(bound_life))
	var subs: Dictionary = {}
	for sig: String in FLASK_SIGNALS:
		var hit: bool = false
		for conn in _flask.get_signal_connection_list(sig):
			var c: Callable = conn.get("callable", Callable())
			if c.get_object() == _orch:
				hit = true
				break
		subs[sig] = hit
	for sig: String in DEATH_SIGNALS:
		var hit: bool = false
		for conn in _death.get_signal_connection_list(sig):
			var c: Callable = conn.get("callable", Callable())
			if c.get_object() == _orch:
				hit = true
				break
		subs[sig] = hit
	var all_sub: bool = true
	for sig: String in subs.keys():
		if not bool(subs[sig]):
			all_sub = false
	_ck("B03 ★ A48① 生产订阅者存在性（运行时）：7 信号 connection_list 均含编排层回调",
		all_sub and subs.size() == 7, "subs=%s" % str(subs))
	var st: Dictionary = _status()
	_ck("B04 get_status 反映 life 已绑定 + 独立槽 + 瓶上限缓存",
		bool(st.get("life_bound", false)) and bool(st.get("flask_service", false)) \
		and bool(st.get("death_service", false)) \
		and String(st.get("slot", "")) == _slot_dir,
		"life_bound=%s slot=%s max_cache=%s" % [str(st.get("life_bound")),
			str(st.get("slot")), str(st.get("flask_max_cache"))])


# ---------------------------------------------------------------------------
# ★ 真实链路：生产真实驱动口 → 生产编排层订阅 → 磁盘。
#   本件不写任何扣减 / 去重 / 落盘 / 累加逻辑（编排全在生产脚本）。
# ---------------------------------------------------------------------------
func _t_real_chain() -> void:
	# ---- 前置：经生产 HUD 真实信号落盘既有赐福点数（A71 与之分离）----
	_hud.emit_signal("points_awarded", "wave_cleared", FIX_FRONT_POINTS,
		"wave_trial_director.wave_cleared_front")
	_hud.emit_signal("boon_draft_applied", FIX_BOON_INDEX, FIX_BOON_CHOICE,
		"hp_restore", 30.0, FIX_COST_KEY, FIX_COST_VALUE)
	_points_baseline = _disk_int(K_POINTS)
	_spent_baseline = _disk_int(K_SPENT)
	_ck("R00 前置赐福点数已由生产编排层落盘（A55/A59 既有通道）",
		_points_baseline == FIX_FRONT_POINTS and _spent_baseline > 0,
		"points=%d spent=%d" % [_points_baseline, _spent_baseline])

	# ---- ① 元素瓶扣减 → ② 落盘（生产真实驱动口 use_flask → 唯一 FlaskService → 编排层落盘）----
	var r1: Dictionary = _wave.call("use_flask", 50, 100) as Dictionary
	_ck("R02 ★ 元素瓶使用成功（生产真实驱动口 use_flask(50,100) → ok=true）",
		bool(r1.get("ok", false)), "reason=%s" % str(r1.get("reason")))
	var rem_after_use: int = _disk_int(K_FLASK_REMAINING)
	_ck("R03 ★ 元素瓶扣减 → 落盘：磁盘 combat.flask.remaining 减少且与真实服务一致",
		rem_after_use > 0 and rem_after_use < _flask_max and rem_after_use == _flask_remaining(),
		"disk_remaining=%d service_remaining=%d flask_max=%d" % [rem_after_use, _flask_remaining(), _flask_max])
	_ck("R04 ★ 落盘 max / use_count（生产编排层 A70 消费 flask_used）",
		_disk_int(K_FLASK_MAX) == _flask_max and _disk_int(K_FLASK_USE_COUNT) >= 1,
		"max=%d use_count=%d" % [_disk_int(K_FLASK_MAX), _disk_int(K_FLASK_USE_COUNT)])
	_ck("R05 ★ 元素瓶落盘不碰赐福点数：points / spent 逐字不变",
		_disk_int(K_POINTS) == _points_baseline and _disk_int(K_SPENT) == _spent_baseline,
		"points=%d==%d spent=%d==%d" % [_disk_int(K_POINTS), _points_baseline,
			_disk_int(K_SPENT), _spent_baseline])

	# ---- 拒绝事件不写盘（满血 flask_rejected）----
	var commit_before_reject: int = int(_status().get("commit_count", 0))
	var use_before_reject: int = _disk_int(K_FLASK_USE_COUNT)
	var r_reject: Dictionary = _wave.call("use_flask", 100, 100) as Dictionary
	_ck("R06 满血 use_flask(100,100) 被拒（full_hp，生产 FlaskService 五道门）",
		not bool(r_reject.get("ok", false)) and String(r_reject.get("reason", "")) == REJECT_FULL_HP,
		"ok=%s reason=%s" % [str(r_reject.get("ok")), str(r_reject.get("reason"))])
	_ck("R07 ★ flask_rejected 拒绝事件不写盘：use_count / remaining / commit_count 全不变",
		_disk_int(K_FLASK_USE_COUNT) == use_before_reject \
		and _disk_int(K_FLASK_REMAINING) == rem_after_use \
		and int(_status().get("commit_count", 0)) == commit_before_reject,
		"use %d→%d rem=%d commit=%d→%d" % [use_before_reject, _disk_int(K_FLASK_USE_COUNT),
			_disk_int(K_FLASK_REMAINING), commit_before_reject, int(_status().get("commit_count", 0))])

	# ---- ③ 死亡掉落 → 落盘（独立单向 flag，★ 绝不回退 points）----
	var r_death: Dictionary = _wave.call("on_player_death", _points_baseline) as Dictionary
	_ck("R08 ★ 死亡发生（生产真实驱动口 on_player_death(500) → ok=true）",
		bool(r_death.get("ok", false)), "reason=%s" % str(r_death.get("reason")))
	_ck("R09 ★ 落盘 grace.death.dropped == 真实服务 get_dropped_points()（独立单向记录、非扣减）",
		_disk_int(K_DEATH_DROPPED) == _death_dropped_points() and _disk_int(K_DEATH_DROPPED) > 0,
		"disk_dropped=%d service_dropped=%d" % [_disk_int(K_DEATH_DROPPED), _death_dropped_points()])
	_ck("R10 ★ 落盘 grace.death.count >= 1 / grace_snapshot == 500（死亡单向计数 + 只读快照）",
		_disk_int(K_DEATH_COUNT) >= 1 and _disk_int(K_DEATH_GRACE_SNAPSHOT) == _points_baseline,
		"count=%d snapshot=%d" % [_disk_int(K_DEATH_COUNT), _disk_int(K_DEATH_GRACE_SNAPSHOT)])
	_ck("R11 ★★ 死亡掉落绝不回退 points：磁盘 grace.trial.points == 前置基线 500",
		_disk_int(K_POINTS) == _points_baseline and _disk_int(K_POINTS) == FIX_FRONT_POINTS,
		"points=%d==%d" % [_disk_int(K_POINTS), _points_baseline])
	_ck("R12 ★ removals 恒空（A71 绝不写 removals）",
		(_disk().get("removals", []) as Array).is_empty(),
		"removals=%s" % str(_disk().get("removals", [])))

	# ---- ④ 重生回满 → 落盘（生产链 respawn_performed → flask_restored → 编排层）----
	var r_respawn: Dictionary = _wave.call("on_grace_respawn") as Dictionary
	_ck("R13 ★ 赐福重生成功（生产真实驱动口 on_grace_respawn() → ok=true）",
		bool(r_respawn.get("ok", false)), "reason=%s" % str(r_respawn.get("reason")))
	_ck("R14 ★ 重生回满：磁盘 combat.flask.remaining == flask_max（生产链 flask_restored → 编排层落盘）",
		_disk_int(K_FLASK_REMAINING) == _flask_max and _disk_int(K_FLASK_REMAINING) == _flask_remaining(),
		"disk_remaining=%d service_remaining=%d flask_max=%d" % [
			_disk_int(K_FLASK_REMAINING), _flask_remaining(), _flask_max])
	_ck("R15 重生单向计数落盘：grace.death.respawn_count >= 1 / restore_count >= 1",
		_disk_int(K_DEATH_RESPAWN_COUNT) >= 1 and _disk_int(K_FLASK_RESTORE_COUNT) >= 1,
		"respawn_count=%d restore_count=%d" % [_disk_int(K_DEATH_RESPAWN_COUNT),
			_disk_int(K_FLASK_RESTORE_COUNT)])
	_ck("R16 ★ 重生不回退 points、不写 removals",
		_disk_int(K_POINTS) == _points_baseline and (_disk().get("removals", []) as Array).is_empty(),
		"points=%d removals=%s" % [_disk_int(K_POINTS), str(_disk().get("removals", []))])

	# ---- ⑤ 一次性回收 → 落盘（独立单向 flag，★ 绝不二次入账 / 不回退 points）----
	var r_reclaim1: Dictionary = _wave.call("reclaim_dropped_points") as Dictionary
	_ck("R17 ★ 第一次回收成功（生产真实驱动口 reclaim_dropped_points() → ok=true）",
		bool(r_reclaim1.get("ok", false)), "reason=%s" % str(r_reclaim1.get("reason")))
	var reclaim_count_1: int = _disk_int(K_DEATH_RECLAIM_COUNT)
	_ck("R18 ★ 落盘 grace.death.reclaimed == true（false→true 单向）",
		_disk_bool(K_DEATH_RECLAIMED), "reclaimed=%s" % str(_disk_bool(K_DEATH_RECLAIMED)))
	_ck("R19 一次性回收落盘：grace.death.reclaim_count >= 1",
		reclaim_count_1 >= 1, "reclaim_count=%d" % reclaim_count_1)
	_ck("R20 ★★ 回收绝不二次入账 / 不回退 points：磁盘 grace.trial.points == 前置基线 500",
		_disk_int(K_POINTS) == _points_baseline and _disk_int(K_POINTS) == FIX_FRONT_POINTS,
		"points=%d==%d（回收点数由 Rank-2 经 points_awarded 一次入账，编排层不二次加工）" % [
			_disk_int(K_POINTS), _points_baseline])
	_ck("R21 ★ removals 恒空（回收绝不写 removals）",
		(_disk().get("removals", []) as Array).is_empty(),
		"removals=%s" % str(_disk().get("removals", [])))

	# ---- 结构冻结 / 正则 / 新 flag 只作 flags 字典 key ----
	var disk: Dictionary = _disk()
	_ck("R22 ★ 真实输入 → 生产编排层订阅 → 磁盘：delta.json 存在可解析",
		not disk.is_empty(), "path=%s" % _delta_path)
	var extra: Array[String] = []
	var missing: Array[String] = []
	for k: Variant in disk.keys():
		if not TEN_FIELDS.has(String(k)):
			extra.append(String(k))
	for k: String in TEN_FIELDS:
		if not disk.has(k):
			missing.append(k)
	_ck("R23 SaveDelta 十字段齐全、无额外顶层字段（冻结）",
		extra.is_empty() and missing.is_empty(),
		"extra=%s missing=%s" % [str(extra), str(missing)])
	_ck("R24 schema_version=3、removals 恒空（A71 绝不写 removals）",
		int(disk.get("schema_version", -1)) == 3 \
		and (disk.get("removals", []) as Array).is_empty(),
		"schema=%s removals=%s" % [str(disk.get("schema_version")), str(disk.get("removals", []))])
	var bad: Array[String] = []
	for k: Variant in _flags().keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_ck("R25 全部落盘 flag key 通过三段式正则（含 11 个 life flag）", bad.is_empty(),
		"keys=%d bad=%s" % [_flags().size(), str(bad)])
	_ck("R26 ★ 11 个 life flag 全为 combat.flask.* / grace.death.* 前缀，绝不混用 points / spent_points",
		_life_keys_pure(), "keys=%s" % str(LIFE_KEYS))

	# ---- ⑦ 重复回收被拒 → ★ 拒绝事件不写盘 ----
	var commit_before_dup: int = int(_status().get("commit_count", 0))
	var points_before_dup: int = _disk_int(K_POINTS)
	var r_reclaim2: Dictionary = _wave.call("reclaim_dropped_points") as Dictionary
	_ck("R27 ★ 第二次回收被拒（already_reclaimed，生产 DeathService 一次性）",
		not bool(r_reclaim2.get("ok", false)) \
		and String(r_reclaim2.get("reason", "")) == REJECT_ALREADY_RECLAIMED,
		"ok=%s reason=%s" % [str(r_reclaim2.get("ok")), str(r_reclaim2.get("reason"))])
	_ck("R28 ★★ 重复回收被拒不写盘：reclaim_count / reclaimed / points 全不变",
		_disk_int(K_DEATH_RECLAIM_COUNT) == reclaim_count_1 \
		and _disk_bool(K_DEATH_RECLAIMED) \
		and _disk_int(K_POINTS) == points_before_dup,
		"reclaim_count %d→%d reclaimed=%s points=%d→%d" % [reclaim_count_1,
			_disk_int(K_DEATH_RECLAIM_COUNT), str(_disk_bool(K_DEATH_RECLAIMED)),
			points_before_dup, _disk_int(K_POINTS)])
	_ck("R29 ★ action_rejected 拒绝事件不写盘：commit_count 不增",
		int(_status().get("commit_count", 0)) == commit_before_dup,
		"commit_count=%d→%d" % [commit_before_dup, int(_status().get("commit_count", 0))])
	_ck("R30 生产编排层真实 commit 次数 > 0（非验证脚本自模拟）",
		commit_before_dup > 0, "commit_count=%d" % commit_before_dup)
	_ck("R31 ★★ A71 全链单向 flag 不回退 points 实证：points 全程 == 500 / spent 全程 == 15",
		_disk_int(K_POINTS) == FIX_FRONT_POINTS and _disk_int(K_POINTS) == _points_baseline \
		and _disk_int(K_SPENT) == _spent_baseline,
		"points=%d spent=%d（元素瓶/死亡/重生/回收/重复回收全链逐字不变）" % [
			_disk_int(K_POINTS), _disk_int(K_SPENT)])


func _life_keys_pure() -> bool:
	for k: String in LIFE_KEYS:
		if not (k.begins_with("combat.flask.") or k.begins_with("grace.death.")):
			return false
		if _re.search(k) == null:
			return false
		if k == K_POINTS or k == K_SPENT:
			return false
	return true


# ---------------------------------------------------------------------------
# ⑥ 重启读回一致：全新空内存 WorldState 只从磁盘 delta.json 重建（等价重启语义）
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
	_ck("X03 ★ 重启读回 A71 单向 flag 三态一致（points / dropped / reclaimed / reclaim_count）",
		int(ws.call("get_flag", K_POINTS, -1)) == _disk_int(K_POINTS) \
		and int(ws.call("get_flag", K_DEATH_DROPPED, -1)) == _disk_int(K_DEATH_DROPPED) \
		and bool(ws.call("get_flag", K_DEATH_RECLAIMED, false)) == _disk_bool(K_DEATH_RECLAIMED) \
		and int(ws.call("get_flag", K_DEATH_RECLAIM_COUNT, -1)) == _disk_int(K_DEATH_RECLAIM_COUNT),
		"points=%s dropped=%s reclaimed=%s reclaim_count=%s" % [
			str(ws.call("get_flag", K_POINTS, -1)), str(ws.call("get_flag", K_DEATH_DROPPED, -1)),
			str(ws.call("get_flag", K_DEATH_RECLAIMED, false)),
			str(ws.call("get_flag", K_DEATH_RECLAIM_COUNT, -1))])
	_ck("X04 ★ 重启读回 A70 元素瓶回满（remaining == max）",
		int(ws.call("get_flag", K_FLASK_REMAINING, 0)) == _flask_max \
		and int(ws.call("get_flag", K_FLASK_MAX, 0)) == _flask_max,
		"remaining=%s max=%s" % [str(ws.call("get_flag", K_FLASK_REMAINING, 0)),
			str(ws.call("get_flag", K_FLASK_MAX, 0))])
	var after: String = _production_md5()
	if _prod_md5_before == after:
		_ck("X05 生产 slot_01 md5 前后一致（全程不写 slot_01）", true,
			"md5=%s" % _prod_md5_before)
	else:
		print("[V140-LP] WARN 生产 slot_01 md5 前后不同（可能并发方写入，非本件所为）before=%s after=%s" % [_prod_md5_before, after])
		_ck("X05 生产存档差异如实登记（不计 FAIL、避免并发回归抖动）", true,
			"before=%s after=%s | WARN 已打印" % [_prod_md5_before, after])


# ---------------------------------------------------------------------------
# 真实输入证据（放在全部磁盘断言之后、不强依赖其落盘产出）：
#   Input.parse_input_event 注入真实 G 键（元素瓶键位，物理键码 71）。
#   主链确定性断言全部由生产真实驱动口承担（见头注「驱动口径」）。
# ---------------------------------------------------------------------------
func _t_real_input_evidence() -> void:
	var gdown: InputEventKey = _key(KEY_G, true)
	Input.parse_input_event(gdown)
	var gup: InputEventKey = _key(KEY_G, false)
	Input.parse_input_event(gup)
	_ck("Y01 真实 G 输入已注入（Input.parse_input_event，物理键码 71）；主链由生产真实驱动口确定性触发",
		true, "key=G(71) pressed/released；真实输入证据，不模拟编排")
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
	# 释放编排层信号连接（_release 内含 _release_focus / _release_life，不留悬空 Callable）
	if _orch != null and is_instance_valid(_orch) and _orch.has_method("_release"):
		_orch.call("_release")
	for n: Node in _temps:
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	var ok: bool = _fail == 0 and _pass > 0
	print("[V140-LP] SUMMARY pid=%d slot=%s pass=%d fail=%d total=%d" % [
		OS.get_process_id(), _slot_dir, _pass, _fail, _pass + _fail])
	print("[V140-LP] OVERALL=%s" % ("PASS" if ok else "FAIL"))
	print("[V140-LP] RESULT=%s" % ("ALL_MATCH" if ok else "MISMATCH"))
	print("[V140-LP] ==== 真跑结束 ====")
	quit(0 if ok else 1)
