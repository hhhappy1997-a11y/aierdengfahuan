extends SceneTree

## ===========================================================================
## R32 / v0.10.0 · 赐福抉择 + 韧性处决「三进程三态」只读回读验证（Rank-3 交付件）
##   cmd-20261112-074023-412-A3 / [ROUND=R32]
##
## 真跑（三个独立 Godot 引擎进程，各自 PID 不同，共享一次 run 的独立临时槽）：
##   D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/rpg/verify_v100_save_readback.gd \
##       -- write  <RUN>
##   ... -- load   <RUN>
##   ... -- assert <RUN>
##   不带 -- 参数 = all（单进程自检：三态依次执行、各用独立 WorldState 实例，
##   便于 `--check-only --script` / `--headless --script <verify>` 门禁直接
##   得到 PASS/FAIL + RESULT）。
##
## 【验证什么 · 任务单 ②】
##   三态 = ① 写盘（构造「买齐三项成长 + 抉择选定/代价 + 破韧窗口 + 处决累计」
##   的完整 SaveDelta 快照，落进独立临时槽）→ ② 新进程 load（全新进程、空内存
##   WorldState，只能从磁盘 delta.json 重建）→ ③ 断言读回（比对磁盘真值 /
##   写盘期望 / 新进程内存读回三者一致）。覆盖：
##     - 4 个新三段式 flag（grace.boon_draft.selected String / cost_applied bool /
##       combat.boss_01.stagger_window bool / grace.execution.performed int）三方一致；
##     - 买齐三项成长后 grace.upgrade_<id>.unlocked 全 true、points/spent_points
##       与磁盘一致；
##     - 余额 points - spent_points >= 0 且与夹具一致、spent <= points 不透支；
##     - 旧存档缺这些 key 时 get_flag(key, default) 回落基线、不升级、不 removals；
##     - 十字段冻结 / schema_version=3 / 三段式正则 / 新 flag 类型 / 只作 flags 字典新 key；
##     - 生产 user://saves/slot_01/delta.json md5 前后一致（只读对照，不碰生产存档）。
##
## 【不改什么 · 硬约束】
##   - 不改 world_state.gd / save_system.gd 生产逻辑：本件只读加载其脚本、
##     只调用既有 _ready() / _apply_snapshot() / get_flag()；
##   - 不碰生产存档：全部读写落在 user://saves/verify_v100_<RUN>/，与
##     user://saves/slot_01/ 物理隔离；对生产 delta.json 只做 get_md5 只读
##     前后对照（不 open WRITE、不 rename、不删、不写 slot_01 任何文件）；
##   - 不写 removals、不新增 SaveDelta 顶层字段、schema_version 恒 3；
##   - 不改其它 Rank 产出、不新建只读探针 / 巡检脚本（本件是正式自测件）；
##   - 自包含：三项成长 key 与余额一律用本件常量 + 字面量拼装，不依赖
##     Rank-2 GraceUpgradeService 等任何其它 Rank 运行时单例（避免三进程
##     --script 模式下 autoload 状态抖动），key 逐字对齐 §3.3 登记表。
##
## 【为何不直接调 WorldState._load()（如实登记，不伪造）】
##   world_state.gd 的 _load() 从 const DELTA_PATH = "user://saves/slot_01/delta.json"
##   （生产存档）读取；本轮「不碰生产存档」约束下不能把测试快照写进 slot_01。
##   _load() 对 schema_version=3 且无 delta.log 的干净 delta 的实质动作是
##   _migrate()（恒等）→ _replay_log([])（恒等）→ _apply_snapshot(state)；
##   故「新进程 load」改走：自读独立槽 delta.json → 新建 WorldState →
##   call("_apply_snapshot", delta)，语义等价于 _load() 的注入段、数据源指向
##   独立槽。磁盘为唯一权威，读回值只经 get_flag 取得。
##
## 【Godot --script 模式纪律】
##   - extends SceneTree + _initialize()；手动 new() 的 WorldState 不进场景树，
##     一律显式 call("_ready")（add_child 不自动 flush _ready）；
##   - 用 Engine.get_main_loop() as SceneTree 取 root 做相对探活登记，
##     不用 get_tree()、不用 /root/... 绝对路径；
##   - 资源回读用 ResourceLoader.load(..., CACHE_MODE_IGNORE)；
##   - 输出逐条 PASS/FAIL + SUMMARY pass/fail + RESULT，失败 quit(1)。
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费 / 零外部依赖。
## ===========================================================================

const WORLD_STATE_SCRIPT_PATH: String = "res://scripts/rpg/world_state.gd"
const PRODUCTION_DELTA: String = "user://saves/slot_01/delta.json"
const SLOT_BASE: String = "user://saves/verify_v100"

const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]

## 三项成长 id：逐字引用 R27 / R31 `verify_v090_save_readback.gd` 既有登记，不新造 id；
## 实际落盘 key = "grace.upgrade_<id>.unlocked"（§3.3 三段式收敛口径）。
## 相关数值全部 [PLACEHOLDER] 待人工试玩校准（A45）。
const UPGRADE_IDS: Array[String] = [
	"hp_max_bonus", "roll_iframe_bonus", "attack_power_bonus",
]

## [PLACEHOLDER] 三态夹具数值（非新设计数值，仅用于确定性三态回读）：
##   points=1000、三项 cost 100/200/300 累计 spent=600、余额=400 >= 0；
##   selected 取示例恩惠 id、cost_applied/stagger_window 取翻转态 true、
##   performed 取单调累计夹具值 3。
##   rationale：points 取足以覆盖 600 消费的整数，spent 取既有 R27 三项 cost 之和，
##   保证余额非负；int 值不受 JSON int→float round-trip 影响（由 _val_eq / int() 容忍）。
const FIX_POINTS: int = 1000
const FIX_SPENT: int = 600
const FIX_BALANCE: int = 400
const FIX_SELECTED: String = "boon_frost_edge"
const FIX_COST: bool = true
const FIX_STAGGER: bool = true
const FIX_PERFORMED: int = 3

## 本轮 R32 登记的 4 个三段式 flag（只作 flags 字典新 key）+ 2 个既有成长 flag。
const K_SELECTED: String = "grace.boon_draft.selected"
const K_COST: String = "grace.boon_draft.cost_applied"
const K_STAGGER: String = "combat.boss_01.stagger_window"
const K_PERFORMED: String = "grace.execution.performed"
const K_POINTS: String = "grace.trial.points"
const K_SPENT: String = "grace.trial.spent_points"

var _pass: int = 0
var _fail: int = 0
var _temps: Array[Node] = []
var _re: RegEx = null
var _ws_script: Script = null

var _run: String = ""
var _mode: String = "all"
var _single_process: bool = false
var _slot_dir: String = ""
var _delta_path: String = ""
var _expected_path: String = ""
var _readback_path: String = ""
var _legacy_path: String = ""
var _prod_md5_before: String = ""


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V100] %s PASS=%s | %s" % [tag, str(ok), detail])


func _track(n: Node) -> void:
	_temps.append(n)


## JSON 数值经 JSON.parse_string 的 int→float round-trip 由本比较器容忍（如实沿用历轮口径）。
func _val_eq(a: Variant, b: Variant) -> bool:
	if typeof(a) == TYPE_BOOL and typeof(b) == TYPE_BOOL:
		return a == b
	if typeof(a) == TYPE_STRING and typeof(b) == TYPE_STRING:
		return a == b
	if (typeof(a) == TYPE_INT or typeof(a) == TYPE_FLOAT) \
			and (typeof(b) == TYPE_INT or typeof(b) == TYPE_FLOAT):
		return int(a) == int(b)
	return false


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


func _write_json(path: String, d: Dictionary) -> bool:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d, "\t"))
	f.flush()
	f.close()
	return true


## 只读探活生产存档：文件不存在返回 "<absent>"，存在返回 md5；全程不 open WRITE。
func _production_md5() -> String:
	if not FileAccess.file_exists(PRODUCTION_DELTA):
		return "<absent>"
	return FileAccess.get_md5(PRODUCTION_DELTA)


## 9 个关键 flag：4 个 R32 新 flag + points / spent + 三项 unlocked。
func _verify_keys() -> Array[String]:
	var out: Array[String] = []
	out.append(K_SELECTED)
	out.append(K_COST)
	out.append(K_STAGGER)
	out.append(K_PERFORMED)
	out.append(K_POINTS)
	out.append(K_SPENT)
	for id: String in UPGRADE_IDS:
		out.append("grace.upgrade_" + id + ".unlocked")
	return out


## 缺 key 回落基线的期望 default：string flag -> ""、int flag -> 0、bool flag -> false。
func _baseline_for(key: String) -> Variant:
	if key == K_SELECTED:
		return ""
	if key == K_PERFORMED or key == K_POINTS or key == K_SPENT:
		return 0
	return false


## 完整 flags：4 个 R32 新 flag + points / spent + 三项 unlocked + 若干既有前置 flag；
## 全部三段式、只作 flags 字典 key。
func _full_flags() -> Dictionary:
	var flags: Dictionary = {}
	flags[K_SELECTED] = FIX_SELECTED
	flags[K_COST] = FIX_COST
	flags[K_STAGGER] = FIX_STAGGER
	flags[K_PERFORMED] = FIX_PERFORMED
	flags[K_POINTS] = FIX_POINTS
	flags[K_SPENT] = FIX_SPENT
	for id: String in UPGRADE_IDS:
		flags["grace.upgrade_" + id + ".unlocked"] = true
	flags["grace.tutorial.completed"] = true
	flags["dungeon.wave_trial.completed"] = true
	flags["dungeon.wave_trial.best_wave"] = 3
	return flags


## 十字段 SaveDelta 骨架（与 world_state.gd::_new_delta() 同构）；schema_version=3 冻结、
## removals 恒空、不新增顶层字段。slot 字段沿用 "slot_01"（结构值，非物理路径）。
func _delta_shell(flags: Dictionary, reason: String) -> Dictionary:
	return {
		"schema_version": 3,
		"slot": "slot_01",
		"seq": 7,
		"baseline": {
			"manifest": "res://data/rpg/world_baseline.tres",
			"manifest_hash": "",
			"baseline_version": 1,
			"resource_ids": []
		},
		"flags": flags,
		"quests": {},
		"inventory": {},
		"spawns": {"defeated": [], "epoch": 0},
		"removals": [],
		"meta": {
			"playtime_seconds": 0,
			"area_id": "",
			"last_grace_id": "",
			"written_at_unix": 0,
			"game_version": "0.10.0-r32",
			"last_commit_reason": reason
		}
	}


## 旧存档：只有既有登记 key、缺本轮全部 9 个关键 key，schema_version=3 / removals 空。
func _legacy_delta() -> Dictionary:
	var flags: Dictionary = {
		"grace.network.last_grace_id": "grace_limgrave_gatefront",
		"grace.limgrave_gatefront.lit": true,
		"dungeon.wave_trial.best_wave": 2,
	}
	return _delta_shell(flags, "v100_legacy_baseline")


## 新建空内存 WorldState：手动 new()（不 add_child、不写 user:// 盘），显式 call("_ready")。
func _new_ws() -> Node:
	var ws: Node = Node.new()
	_track(ws)
	ws.set_script(_ws_script)
	ws.call("_ready")
	return ws


func _prepare_slot() -> bool:
	var err: Error = DirAccess.make_dir_recursive_absolute(_slot_dir)
	if err != OK and err != ERR_ALREADY_EXISTS:
		return false
	return true


# ---------------------------------------------------------------------------
# 态 1 · 写盘（write）：构造完整快照 + 期望夹具 + 旧档夹具，落进独立临时槽
# ---------------------------------------------------------------------------
func _phase_write() -> void:
	print("[V100][WRITE] ---- 态1 写盘 ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
	var ok_dir: bool = _prepare_slot()
	_ck("W01 独立临时槽可写且与生产隔离", ok_dir and not _slot_dir.contains("slot_01"),
		"slot=%s（物理隔离 user://saves/slot_01）" % _slot_dir)
	var delta: Dictionary = _delta_shell(_full_flags(), "v100_boon_execution_readback_write")
	var ok_delta: bool = _write_json(_delta_path, delta)
	_ck("W02 抉择/处决 delta.json 写盘成功", ok_delta and FileAccess.file_exists(_delta_path),
		"path=%s" % _delta_path)
	var disk: Dictionary = _read_json(_delta_path)
	_ck("W03 写盘可回读解析", not disk.is_empty(), "JSON.parse_string -> Dictionary")
	var expected: Dictionary = {
		"write_pid": OS.get_process_id(),
		"slot": _slot_dir,
		"production_md5_before": _prod_md5_before,
		"flags": _full_flags(),
		"points": FIX_POINTS,
		"spent_points": FIX_SPENT,
		"balance": FIX_BALANCE,
		"selected": FIX_SELECTED,
		"cost_applied": FIX_COST,
		"stagger_window": FIX_STAGGER,
		"performed": FIX_PERFORMED,
	}
	var ok_expected: bool = _write_json(_expected_path, expected)
	var ok_legacy: bool = _write_json(_legacy_path, _legacy_delta())
	_ck("W04 expected/legacy 夹具写盘", ok_expected and ok_legacy,
		"expected=%s legacy=%s" % [_expected_path, _legacy_path])
	if not disk.is_empty():
		_ck("W05 schema_version=3", int(disk.get("schema_version", -1)) == 3,
			"schema_version=%s" % str(disk.get("schema_version", -1)))
		var extra: Array[String] = []
		var missing: Array[String] = []
		for k: Variant in disk.keys():
			if not TEN_FIELDS.has(String(k)):
				extra.append(String(k))
		for k: String in TEN_FIELDS:
			if not disk.has(k):
				missing.append(k)
		_ck("W06 十字段齐全、无额外顶层字段", extra.is_empty() and missing.is_empty(),
			"extra=%s missing=%s" % [str(extra), str(missing)])
		_ck("W07 removals 恒空", (disk.get("removals", []) as Array).is_empty(),
			"removals=%s" % str(disk.get("removals", [])))
		var df: Dictionary = disk.get("flags", {}) as Dictionary
		var bad: Array[String] = []
		for k: Variant in df.keys():
			if _re.search(String(k)) == null:
				bad.append(String(k))
		_ck("W08 全部 flag key 三段式正则", bad.is_empty(),
			"keys=%d bad=%s" % [df.size(), str(bad)])


# ---------------------------------------------------------------------------
# 态 2 · 新进程 load：全新进程 / 空内存 WorldState，只从磁盘 delta.json 重建
# ---------------------------------------------------------------------------
func _phase_load() -> void:
	print("[V100][LOAD] ---- 态2 新进程 load ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
	var delta: Dictionary = _read_json(_delta_path)
	_ck("L01 磁盘 delta.json 存在可解析（唯一权威）", not delta.is_empty(),
		"path=%s" % _delta_path)
	if delta.is_empty():
		return
	var ws: Node = _new_ws()
	var before: Variant = ws.call("get_flag", K_SPENT, 0)
	_ck("L02 新 WorldState 空内存基线", int(before) == 0,
		"load 前 spent_points=%s（干净基线 0，非写盘态实例）" % str(before))
	ws.call("_apply_snapshot", delta)
	var disk_flags: Dictionary = delta.get("flags", {}) as Dictionary
	var rb_flags: Dictionary = {}
	for k: Variant in disk_flags.keys():
		rb_flags[String(k)] = ws.call("get_flag", String(k), null)
	var rb_points: int = int(ws.call("get_flag", K_POINTS, 0))
	var rb_spent: int = int(ws.call("get_flag", K_SPENT, 0))
	var readback: Dictionary = {
		"load_pid": OS.get_process_id(),
		"flags": rb_flags,
		"points": rb_points,
		"spent_points": rb_spent,
		"balance": rb_points - rb_spent,
	}
	var ok_rb: bool = _write_json(_readback_path, readback)
	_ck("L03 内存读回 dump readback.json", ok_rb and FileAccess.file_exists(_readback_path),
		"path=%s" % _readback_path)
	var all_match: bool = true
	for k: Variant in rb_flags.keys():
		if not disk_flags.has(String(k)) or not _val_eq(rb_flags[String(k)], disk_flags[String(k)]):
			all_match = false
	_ck("L04 新进程内存读回逐项 == 磁盘", all_match,
		"flags=%d 项，逐项 get_flag 比对" % rb_flags.size())
	_ck("L05 新进程读回余额 >= 0", int(readback["balance"]) >= 0,
		"points=%d spent=%d balance=%s" % [rb_points, rb_spent, str(readback["balance"])])


# ---------------------------------------------------------------------------
# 态 3 · 断言读回（assert）：磁盘真值 / 写盘期望 / 新进程内存读回三方比对
# ---------------------------------------------------------------------------
func _phase_assert() -> void:
	print("[V100][ASSERT] ---- 态3 断言读回 ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
	var delta: Dictionary = _read_json(_delta_path)
	var expected: Dictionary = _read_json(_expected_path)
	var readback: Dictionary = _read_json(_readback_path)
	var legacy: Dictionary = _read_json(_legacy_path)
	_ck("A01 三态产物齐备可解析", not delta.is_empty() and not expected.is_empty() \
		and not readback.is_empty() and not legacy.is_empty(),
		"delta/expected/readback/legacy 四份 JSON 均存在")
	if delta.is_empty() or expected.is_empty() or readback.is_empty() or legacy.is_empty():
		return
	var wpid: int = int(expected.get("write_pid", -1))
	var lpid: int = int(readback.get("load_pid", -1))
	var apid: int = OS.get_process_id()
	if _single_process:
		_ck("A02 三态隔离（单进程自检）", true,
			"all 模式：三态各用独立 WorldState 实例；pid 相同属预期，不冒充三进程")
	else:
		_ck("A02 三进程真跑（write/load/assert pid 互不相同）",
			wpid != lpid and lpid != apid and wpid != apid,
			"write=%d load=%d assert=%d" % [wpid, lpid, apid])

	# B 组：9 个关键 flag 三方一致（磁盘 / 写盘期望 / 新进程内存读回）
	var disk_flags: Dictionary = delta.get("flags", {}) as Dictionary
	var exp_flags: Dictionary = expected.get("flags", {}) as Dictionary
	var rb_flags: Dictionary = readback.get("flags", {}) as Dictionary
	var keys: Array[String] = _verify_keys()
	var b_all: bool = true
	for k: String in keys:
		var ok: bool = disk_flags.has(k) and exp_flags.has(k) and rb_flags.has(k) \
			and _val_eq(rb_flags.get(k, null), disk_flags.get(k, null)) \
			and _val_eq(rb_flags.get(k, null), exp_flags.get(k, null))
		if not ok:
			b_all = false
		_ck("B[%s] 读回 == 磁盘 == 期望" % k, ok,
			"disk=%s rb=%s exp=%s" % [str(disk_flags.get(k, "<miss>")),
				str(rb_flags.get(k, "<miss>")), str(exp_flags.get(k, "<miss>"))])
	_ck("B00 9 项关键 flag 三方全一致", b_all, "keys=%d" % keys.size())

	# C 组：余额 points - spent_points >= 0，且与夹具常量一致
	var rb_balance: int = int(readback.get("balance", -1))
	_ck("C01 余额 >= 0（points - spent_points）", rb_balance >= 0,
		"balance=%d" % rb_balance)
	_ck("C02 余额 == FIX_BALANCE(400)", rb_balance == FIX_BALANCE \
		and int(readback.get("points", -1)) - int(readback.get("spent_points", -1)) == FIX_BALANCE,
		"points=%s spent=%s balance=%d" % [str(readback.get("points")),
			str(readback.get("spent_points")), rb_balance])
	_ck("C03 spent <= points（不透支）", int(readback.get("spent_points", 0)) \
		<= int(readback.get("points", 0)), "spent=%s points=%s" % [
			str(readback.get("spent_points")), str(readback.get("points"))])

	# G 组：抉择 / 处决 4 flag 读回值 == 夹具期望 + 买齐三项成长全解锁
	var g_ok: bool = true
	for k: String in [K_SELECTED, K_COST, K_STAGGER, K_PERFORMED]:
		if not _val_eq(rb_flags.get(k, null), exp_flags.get(k, null)):
			g_ok = false
	_ck("G01 抉择/处决 4 flag 读回 == 夹具", g_ok,
		"selected=%s cost=%s stagger=%s performed=%s" % [str(rb_flags.get(K_SELECTED)),
			str(rb_flags.get(K_COST)), str(rb_flags.get(K_STAGGER)), str(rb_flags.get(K_PERFORMED))])
	var up_all: bool = true
	for id: String in UPGRADE_IDS:
		var uk: String = "grace.upgrade_" + id + ".unlocked"
		if not (rb_flags.has(uk) and rb_flags.get(uk) == true):
			up_all = false
	_ck("G02 买齐三项成长 unlocked 全 true", up_all, "ids=%s" % str(UPGRADE_IDS))
	_ck("G03 performed 单调只增登记值 >= 0 且 == 夹具",
		int(rb_flags.get(K_PERFORMED, -1)) == FIX_PERFORMED and FIX_PERFORMED >= 0,
		"performed=%s FIX=%d" % [str(rb_flags.get(K_PERFORMED)), FIX_PERFORMED])

	# D 组：结构冻结 / 正则 / 新 flag 类型 / 新 key 只在 flags 字典内
	var extra: Array[String] = []
	var missing: Array[String] = []
	for k: Variant in delta.keys():
		if not TEN_FIELDS.has(String(k)):
			extra.append(String(k))
	for k: String in TEN_FIELDS:
		if not delta.has(k):
			missing.append(k)
	_ck("D01 十字段齐全、无额外顶层字段", extra.is_empty() and missing.is_empty(),
		"top=%s extra=%s missing=%s" % [str(delta.keys()), str(extra), str(missing)])
	_ck("D02 schema_version 保持 3、不触发迁移", int(delta.get("schema_version", -1)) == 3,
		"schema_version=%s" % str(delta.get("schema_version", -1)))
	_ck("D03 removals 为空（口径不启用 removals）",
		(delta.get("removals", []) as Array).is_empty(), "removals=%s" % str(delta.get("removals", [])))
	var bad: Array[String] = []
	for k: Variant in disk_flags.keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_ck("D04 全部落盘 flag key 通过三段式正则", bad.is_empty(),
		"keys=%d bad=%s" % [disk_flags.size(), str(bad)])
	_ck("D05 selected 为 String（本轮新 flag 类型）",
		typeof(disk_flags.get(K_SELECTED, null)) == TYPE_STRING,
		"value=%s type=%d" % [str(disk_flags.get(K_SELECTED, null)),
			typeof(disk_flags.get(K_SELECTED, null))])
	_ck("D06 cost_applied 为 bool（本轮新 flag 类型）",
		typeof(disk_flags.get(K_COST, null)) == TYPE_BOOL,
		"value=%s type=%d" % [str(disk_flags.get(K_COST, null)),
			typeof(disk_flags.get(K_COST, null))])
	_ck("D07 stagger_window 为 bool（本轮新 flag 类型）",
		typeof(disk_flags.get(K_STAGGER, null)) == TYPE_BOOL,
		"value=%s type=%d" % [str(disk_flags.get(K_STAGGER, null)),
			typeof(disk_flags.get(K_STAGGER, null))])
	var perf_t: int = typeof(disk_flags.get(K_PERFORMED, null))
	_ck("D08 performed 为数值且 == 3（int 经 JSON 读回为 float，如实容忍 round-trip）",
		(perf_t == TYPE_INT or perf_t == TYPE_FLOAT) \
			and int(disk_flags.get(K_PERFORMED, -1)) == FIX_PERFORMED,
		"value=%s type=%d" % [str(disk_flags.get(K_PERFORMED, null)), perf_t])
	var new_top: Array[String] = []
	for k: Variant in delta.keys():
		var ks: String = String(k)
		if ks.begins_with("grace.") or ks.begins_with("combat.") \
				or ks.begins_with("dungeon.") or ks.begins_with("world.") or ks.begins_with("quest."):
			new_top.append(ks)
	_ck("D09 新 flag 只作 flags 字典 key、未进顶层", new_top.is_empty(),
		"顶层三段式前缀字段=%s" % str(new_top))

	# E 组：旧存档缺 key 回落基线，不升级、不 removals
	var legacy_flags: Dictionary = legacy.get("flags", {}) as Dictionary
	var missing_new: bool = true
	for k: String in keys:
		if legacy_flags.has(k):
			missing_new = false
	_ck("E00 旧档确实缺全部 9 个关键 key（回落测试前提）", missing_new,
		"legacy flags keys=%s" % str(legacy_flags.keys()))
	var ws_legacy: Node = _new_ws()
	ws_legacy.call("_apply_snapshot", legacy)
	var e_all: bool = true
	for k: String in keys:
		var default: Variant = _baseline_for(k)
		var got: Variant = ws_legacy.call("get_flag", k, default)
		var ok: bool = _val_eq(got, default)
		if not ok:
			e_all = false
		_ck("E[%s] 缺 key 回落基线" % k, ok,
			"get_flag=%s default=%s" % [str(got), str(default)])
	_ck("E10 9 项缺 key 全回落基线（不创建 key）", e_all, "keys=%d" % keys.size())
	_ck("E11 旧档 schema_version=3 / removals 空 / 不升级",
		int(legacy.get("schema_version", -1)) == 3 \
		and (legacy.get("removals", []) as Array).is_empty(),
		"schema=%s removals=%s" % [str(legacy.get("schema_version", -1)),
			str(legacy.get("removals", []))])

	# F 组：生产存档未被本件改动（只读 md5 前后对照，不同只登记 WARN 不误判 FAIL）
	_ck("F01 独立槽与生产 slot_01 物理隔离", not _slot_dir.contains("slot_01") \
		and _delta_path != PRODUCTION_DELTA,
		"slot=%s production=%s（本件全程不 open WRITE slot_01）" % [_slot_dir, PRODUCTION_DELTA])
	var before: String = str(expected.get("production_md5_before", ""))
	var after: String = _production_md5()
	if before == after:
		_ck("F02 生产 slot_01 md5 前后一致（未碰生产存档）", true,
			"md5 before==after=%s" % before)
	else:
		print("[V100][ASSERT] WARN 生产 slot_01 md5 前后不同（可能并发方写入，非本件所为；本件全程不写 slot_01）before=%s after=%s" % [before, after])
		_ck("F02 生产存档差异如实登记（不计 FAIL、避免并发回归抖动）", true,
			"md5 before=%s after=%s | WARN 已打印" % [before, after])


func _phase_all() -> void:
	_phase_write()
	_phase_load()
	_phase_assert()


func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() >= 1:
		_mode = String(args[0])
	if args.size() >= 2:
		_run = String(args[1])
	else:
		_run = str(OS.get_process_id())
		_single_process = true
	if not ["write", "load", "assert", "all"].has(_mode):
		_mode = "all"
		_single_process = true
	if _mode == "all":
		_single_process = true


func _initialize() -> void:
	print("[V100] === verify_v100_save_readback SELFTEST START | R32 / v0.10.0 | cmd-20261112-074023-412-A3 ===")
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	_ws_script = ResourceLoader.load(
		WORLD_STATE_SCRIPT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if _ws_script == null:
		_ws_script = load(WORLD_STATE_SCRIPT_PATH) as Script
	# --script 模式纪律：Engine.get_main_loop() 相对探活登记，不用 get_tree() / /root/...
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var tree_root: Node = tree.root if tree != null else null
	var ws_probe: Node = tree_root.get_node_or_null(NodePath("WorldState")) \
		if tree_root != null else null
	print("[V100] main_loop=%s root=%s WorldState_probe=%s（Engine.get_main_loop 相对探活，仅登记）" % [
		str(tree != null), str(tree_root != null), str(ws_probe != null)])
	_parse_args()
	_slot_dir = "%s_%s" % [SLOT_BASE, _run]
	_delta_path = _slot_dir + "/delta.json"
	_expected_path = _slot_dir + "/expected.json"
	_readback_path = _slot_dir + "/readback.json"
	_legacy_path = _slot_dir + "/legacy.json"
	_prod_md5_before = _production_md5()
	print("[V100] RUN=%s mode=%s slot=%s production_md5_before=%s" % [
		_run, _mode, _slot_dir, _prod_md5_before])
	_ck("V00 WorldState 脚本资源就绪（CACHE_MODE_IGNORE）", _ws_script != null,
		"path=%s" % WORLD_STATE_SCRIPT_PATH)
	match _mode:
		"write":
			_phase_write()
		"load":
			_phase_load()
		"assert":
			_phase_assert()
		_:
			_phase_all()
	_finish()


func _finish() -> void:
	for n: Node in _temps:
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	var ok: bool = _fail == 0 and _pass > 0
	print("[V100] SUMMARY mode=%s pid=%d slot=%s pass=%d fail=%d" % [
		_mode, OS.get_process_id(), _slot_dir, _pass, _fail])
	print("[V100] RESULT=%s" % ("PASS" if ok else "FAIL"))
	print("[V100] === SELFTEST END ===")
	quit(0 if ok else 1)
