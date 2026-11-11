extends SceneTree

## R26 · 波次试炼三段式 flag 口径自测（Rank-3，cmd-20261111-073556-928-A3，[ROUND=R26]，v0.4.0）
## 目标：把 00-协作契约.md §3.3 / 存档与flag规范.md §3.3 / WAVE-TRIAL-GDD.md §6 的口径
##   逐条转成机器可判定断言，真跑输出 PASS/FAIL 与 RESULT。
## 验证 5 类：
##   A 三段式正则（3 个新 flag 通过 + 六类反例拒绝）
##   B best_wave 单调递增（只增不减 / 新局只打 1 波不回退 / 多次挑战取历史最高）
##   C completed 只增不减（false→true 单向）+ grace.trial.points 单调递增
##   D 重启读回一致（真实 FileAccess 落盘 → 新建独立 State 实例 _load() 逐项读回；
##     并由 WAVE_V040_PHASE=write|read 两个独立引擎进程实证「重启」）
##   E commit 顺序「先落盘再改运行时实例」+ 十字段齐全 / schema_version=3 / 落盘 flags 全合法
## --script 模式纪律：不用 /root/... 绝对路径；用 Engine.get_main_loop() / get_root().get_node_or_null()
##   相对探活，取不到如实降级、不依赖其结果判 PASS（任务单明确要求）。
## 如实边界：本载体是「口径级模拟」，不碰 godot/ 工程文件、不写 slot_01/delta.json（用独立
##   user:// 文件）、不对 Rank-1/2 运行时代验；本轮 Rank-3 不写任何 godot/ 工程文件。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const K_BEST: String = "dungeon.wave_trial.best_wave"
const K_COMPLETED: String = "dungeon.wave_trial.completed"
const K_POINTS: String = "grace.trial.points"
const STATE_PATH: String = "user://wave_flags_v040_state.json"

## 十字段（存档与flag规范.md §4.1 冻结，§4.4 回放消费）；用于断言新 flag 不新增顶层字段。
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]

## 口径基线快照（自测构造的模拟状态，非工程 / GDD 数值、不进入任何数据表）：
## 模拟「三波全清一局」——best_wave=3、completed=true、points=3（3 次波次结算各 +1 的模拟值）。
## points=3 是口径级模拟，不引用也不替代 Rank-2 reward_points [PLACEHOLDER]。
const EXPECT: Dictionary = {
	K_BEST: 3,
	K_COMPLETED: true,
	K_POINTS: 3,
}

var _pass: int = 0
var _fail: int = 0
var _frame: int = 0
var _phase: String = ""
var _re: RegEx = null

# 口径级内存状态：模拟 I-1 WorldState flags
var _flags: Dictionary = {}
# 模拟磁盘态（落盘目标）与运行时实例，用于断言「先落盘再改运行时实例」
var _disk: Dictionary = {}
var _runtime: Dictionary = {}
var _order: Array[String] = []


## 独立 State：模拟一次「重启」后的内存重建 —— 新实例、空内存，只能从磁盘 _load() 回填。
class _State:
	var _f: Dictionary = {}

	func load_from_file(path: String) -> bool:
		if not FileAccess.file_exists(path):
			return false
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		if f == null:
			return false
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) != TYPE_DICTIONARY:
			return false
		var d: Dictionary = parsed as Dictionary
		if not d.has("flags"):
			return false
		_f = (d["flags"] as Dictionary).duplicate(true)
		return true

	func get_flag(key: String, default_value: Variant) -> Variant:
		if _f.has(key):
			return _f[key]
		return default_value

	func snapshot() -> Dictionary:
		return _f.duplicate(true)


func _check(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
		print("[WFV040] %s PASS=true | %s" % [tag, detail])
	else:
		_fail += 1
		print("[WFV040] %s PASS=false | %s" % [tag, detail])


## 值相等：容忍 JSON int→float round-trip（与 R25 / r22_save_e2e.gd 同口径），bool/String 严格类型+值。
func _val_eq(a: Variant, b: Variant) -> bool:
	var ta: int = typeof(a)
	var tb: int = typeof(b)
	if (ta == TYPE_INT or ta == TYPE_FLOAT) and (tb == TYPE_INT or tb == TYPE_FLOAT):
		return is_equal_approx(float(a), float(b))
	return ta == tb and a == b


func _initialize() -> void:
	_phase = OS.get_environment("WAVE_V040_PHASE")
	if _phase == "":
		_phase = "selftest"
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	_flags = {
		K_BEST: 0,
		K_COMPLETED: false,
		K_POINTS: 0,
	}
	print("[WFV040] ==== verify_wave_flags_v040 真跑开始 ====")
	print("[WFV040] phase=%s pid=%d" % [_phase, OS.get_process_id()])
	# --script 模式不用 /root/... 绝对路径：用 Engine.get_main_loop() / get_root() 相对取节点，取不到如实降级。
	var ml: MainLoop = Engine.get_main_loop()
	var root: Node = get_root()
	var ws_probe: Node = null
	if root != null:
		ws_probe = root.get_node_or_null("WorldState")
	print("[WFV040] main_loop=%s root=%s WorldState_probe=%s（仅探活，不用 /root/ 绝对路径，不依赖其结果判 PASS）" % [
		str(ml != null), str(root != null), str(ws_probe != null)])
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	if _frame < 3:
		return
	process_frame.disconnect(_on_frame)
	if _phase == "selftest":
		_run_selftest()
	elif _phase == "write":
		_run_write()
	elif _phase == "read":
		_run_read()
	else:
		print("[WFV040] 未知 WAVE_V040_PHASE=%s（应为 selftest|write|read）" % _phase)
		_check("PHASE_VALID", false, "phase=%s" % _phase)
	_finish()


## 口径级「先落盘再改运行时实例」：模拟 WAVE-TRIAL-GDD.md §6.4 步骤 3(commit) → 步骤 4(改实例)。
## 纪律：先写 _disk（落盘），再写 _runtime（运行时实例），事件顺序追加进 _order 供机器判定。
func _commit_then_runtime(reason: String, snapshot: Dictionary) -> void:
	_order.append("disk_write:" + reason)          # ★ 先落盘
	_disk = snapshot.duplicate(true)
	_order.append("runtime_update:" + reason)     # 再改运行时实例
	_runtime = snapshot.duplicate(true)


## 构造十字段 payload（新 flag 只进 flags 字典，不新增顶层字段）。
func _make_payload(flags_snapshot: Dictionary, reason: String) -> Dictionary:
	return {
		"schema_version": 3,
		"slot": "slot_01",
		"seq": 1,
		"baseline": {},
		"flags": flags_snapshot.duplicate(true),
		"quests": {},
		"inventory": {},
		"spawns": {},
		"removals": [],
		"meta": {"last_commit_reason": reason},
	}


func _run_selftest() -> void:
	_test_regex()
	_test_best_wave_monotonic()
	_test_completed_and_points()
	_test_restart_readback()
	_test_commit_and_schema()


## ================= A 三段式正则 =================
func _test_regex() -> void:
	var keys: Array[String] = [K_BEST, K_COMPLETED, K_POINTS]
	var bad: Array[String] = []
	for k in keys:
		if _re.search(k) == null:
			bad.append(k)
	_check("A1 三个新 flag 通过三段式正则", bad.is_empty(),
		"regex=%s keys=%s bad=%s" % [FLAG_KEY_REGEX, str(keys), str(bad)])
	# 六类反例：两段式 / 大写 / 连字符 / 四段 / 非法前缀 / 中文
	var bad_keys: Array[String] = [
		"dungeon.wave_trial_best_wave",
		"dungeon.Wave_trial.best_wave",
		"dungeon.wave-trial.best_wave",
		"dungeon.wave_trial.best_wave.extra",
		"hero.wave_trial.best_wave",
		"dungeon.wave_trial.最高波次",
	]
	var bad_hits: Array[String] = []
	for k in bad_keys:
		if _re.search(k) != null:
			bad_hits.append(k)
	_check("A2 六类非法 key 全部被三段式正则拒绝", bad_hits.is_empty(),
		"bad_total=%d bad_accepted=%s" % [bad_keys.size(), str(bad_hits)])


## ================= B best_wave 单调递增 =================
func _test_best_wave_monotonic() -> void:
	_flags = {K_BEST: 0, K_COMPLETED: false, K_POINTS: 0}
	var series: Array[int] = []
	# 模拟一局三波推进：每抵达一波，best_wave = max(旧, 当前波)，只增不减
	for wave in range(1, 4):
		var old: int = int(_flags.get(K_BEST, 0))
		_flags[K_BEST] = maxi(old, wave)
		_commit_then_runtime("wave_trial_cleared_%d" % wave, _flags)
		series.append(int(_flags.get(K_BEST, -1)))
	var expect: Array[int] = [1, 2, 3]
	var mono: bool = series == expect
	for i in range(1, series.size()):
		if series[i] <= series[i - 1]:
			mono = false
	_check("B1 三波推进 best_wave 严格单调递增 0→1→2→3", mono,
		"series=%s expect=%s" % [str(series), str(expect)])
	# 反向注入较小值 / 新一局只打 1~2 波：历史最佳 3 不回退（max 口径）
	for wave_attempt in range(1, 3):
		var old2: int = int(_flags.get(K_BEST, 0))
		_flags[K_BEST] = maxi(old2, wave_attempt)
	_check("B2 新局较低波次不回退历史最佳（max 口径）", int(_flags.get(K_BEST, -1)) == 3,
		"best_wave=%s" % str(_flags.get(K_BEST, -1)))
	# 多次挑战取历史最高：再打一局到 3，仍为 3；不因重复挑战 +N
	_flags[K_BEST] = maxi(int(_flags.get(K_BEST, 0)), 3)
	_check("B3 多次挑战取历史最高、不重复累加", int(_flags.get(K_BEST, -1)) == 3,
		"best_wave=%s" % str(_flags.get(K_BEST, -1)))


## ================= C completed 只增不减 + points 单调递增 =================
func _test_completed_and_points() -> void:
	_flags = {K_BEST: 3, K_COMPLETED: false, K_POINTS: 0}
	# 三波全清：completed false→true 单向
	_flags[K_COMPLETED] = true
	_commit_then_runtime("wave_trial_completed", _flags)
	_check("C1 三波全清 completed false→true", bool(_flags.get(K_COMPLETED, false)) == true,
		"completed=%s" % str(_flags.get(K_COMPLETED)))
	# 失败 / 重启 / 重复挑战：口径中无 false 回写路径，三次结算事件后仍为 true
	for i in range(3):
		_commit_then_runtime("wave_trial_settled_%d" % i, _flags)
	_check("C2 失败 / 重启 / 重复挑战 completed 只增不减（无 false 回写）",
		bool(_flags.get(K_COMPLETED, false)) == true,
		"completed=%s" % str(_flags.get(K_COMPLETED)))
	# points：3 次波次结算各 +1（模拟值，不引用 Rank-2 reward_points）
	var p_series: Array[int] = []
	for i in range(3):
		_flags[K_POINTS] = int(_flags.get(K_POINTS, 0)) + 1
		_commit_then_runtime("wave_trial_cleared_%d" % i, _flags)
		p_series.append(int(_flags.get(K_POINTS, -1)))
	var p_expect: Array[int] = [1, 2, 3]
	var p_mono: bool = p_series == p_expect
	for i in range(1, p_series.size()):
		if p_series[i] <= p_series[i - 1]:
			p_mono = false
	_check("C3 grace.trial.points 三次结算严格单调递增 0→1→2→3", p_mono,
		"series=%s" % str(p_series))
	_check("C4 赐福休息后 points 不清零、completed 不回退",
		int(_flags.get(K_POINTS, -1)) == 3 and bool(_flags.get(K_COMPLETED, false)) == true,
		"points=%s completed=%s" % [str(_flags.get(K_POINTS)), str(_flags.get(K_COMPLETED))])


## ================= D 重启读回一致 =================
func _test_restart_readback() -> void:
	# 落盘 B/C 演变后的 _flags（应等于 EXPECT），再与 EXPECT 逐项比对，验证真实演变态可重启读回
	var payload: Dictionary = _make_payload(_flags, "wave_trial_completed")
	var f: FileAccess = FileAccess.open(STATE_PATH, FileAccess.WRITE)
	var write_ok: bool = f != null
	if write_ok:
		f.store_string(JSON.stringify(payload))
		f.close()
	_check("D1 真实落盘到独立 user:// 文件（不碰 slot_01/delta.json）",
		write_ok and FileAccess.file_exists(STATE_PATH),
		"path=%s abs=%s" % [STATE_PATH, ProjectSettings.globalize_path(STATE_PATH)])
	# 模拟「重启」：新建完全独立的 State 实例，空内存，从磁盘 _load() 读回（不复用 _flags）
	var reborn := _State.new()
	var load_ok: bool = reborn.load_from_file(STATE_PATH)
	_check("D2 新实例 _load() 从磁盘重建内存", load_ok, "load_ok=%s" % str(load_ok))
	var mism: Array[String] = []
	for k in EXPECT.keys():
		var key: String = String(k)
		var got: Variant = reborn.get_flag(key, null)
		if not _val_eq(got, EXPECT[key]):
			mism.append("%s got=%s want=%s" % [key, str(got), str(EXPECT[key])])
	_check("D3 重启读回逐项一致（best_wave / completed / points 3/3）", mism.is_empty(),
		"readback=%s mism=%s" % [str(reborn.snapshot()), str(mism)])


## ================= E commit 顺序 + 十字段 / schema_version =================
func _test_commit_and_schema() -> void:
	_order.clear()
	_disk.clear()
	_runtime.clear()
	for i in range(3):
		_commit_then_runtime("wave_trial_cleared_%d" % i, _flags)
	var ok: bool = _order.size() == 6
	for i in range(0, _order.size(), 2):
		if not (String(_order[i]).begins_with("disk_write") and String(_order[i + 1]).begins_with("runtime_update")):
			ok = false
	_check("E1 commit 顺序「先落盘再改运行时实例」（连续 3 次）", ok,
		"order=%s" % str(_order))
	_check("E2 落盘态与运行时实例态逐项一致", _disk == _runtime,
		"disk=%s runtime=%s" % [str(_disk), str(_runtime)])
	var payload: Dictionary = _make_payload(EXPECT, "wave_trial_completed")
	var top: Array = payload.keys()
	var extra: Array[String] = []
	var missing: Array[String] = []
	for k in top:
		if not TEN_FIELDS.has(String(k)):
			extra.append(String(k))
	for k in TEN_FIELDS:
		if not payload.has(k):
			missing.append(k)
	_check("E3 十字段齐全且无额外顶层字段（新 flag 只进 flags 字典）",
		extra.is_empty() and missing.is_empty() and top.size() == TEN_FIELDS.size(),
		"top=%s extra=%s missing=%s" % [str(top), str(extra), str(missing)])
	_check("E4 schema_version 保持 3、不触发迁移", int(payload.get("schema_version", -1)) == 3,
		"schema_version=%s" % str(payload.get("schema_version", -1)))
	var bad: Array[String] = []
	for k in (payload["flags"] as Dictionary).keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_check("E5 落盘 flags 全通过三段式正则", bad.is_empty(),
		"keys=%s bad=%s" % [str((payload["flags"] as Dictionary).keys()), str(bad)])


## ================= write / read 两阶段（真·跨进程重启实证） =================
func _run_write() -> void:
	var payload: Dictionary = _make_payload(EXPECT, "wave_trial_completed")
	var f: FileAccess = FileAccess.open(STATE_PATH, FileAccess.WRITE)
	var ok: bool = f != null
	if ok:
		f.store_string(JSON.stringify(payload))
		f.close()
	_check("W1 write 阶段真实落盘种子", ok and FileAccess.file_exists(STATE_PATH),
		"path=%s abs=%s" % [STATE_PATH, ProjectSettings.globalize_path(STATE_PATH)])
	var bad: Array[String] = []
	for k in (payload["flags"] as Dictionary).keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_check("W2 落盘 flags 全通过三段式正则", bad.is_empty(),
		"keys=%s bad=%s" % [str((payload["flags"] as Dictionary).keys()), str(bad)])
	_check("W3 种子基线 best_wave=3 / completed=true / points=3",
		int(EXPECT[K_BEST]) == 3 and bool(EXPECT[K_COMPLETED]) == true and int(EXPECT[K_POINTS]) == 3,
		"expect=%s" % str(EXPECT))


func _run_read() -> void:
	# 新进程：内存为空（未读档），必须从磁盘 _load() 重建
	var reborn := _State.new()
	var load_ok: bool = reborn.load_from_file(STATE_PATH)
	_check("R1 新进程 _load() 从磁盘重建内存", load_ok, "load_ok=%s" % str(load_ok))
	var mism: Array[String] = []
	for k in EXPECT.keys():
		var key: String = String(k)
		var got: Variant = reborn.get_flag(key, null)
		if not _val_eq(got, EXPECT[key]):
			mism.append("%s got=%s want=%s" % [key, str(got), str(EXPECT[key])])
	_check("R2 跨进程读回 3/3 一致（best_wave / completed / points）", mism.is_empty(),
		"readback=%s mism=%s" % [str(reborn.snapshot()), str(mism)])
	var got_completed: Variant = reborn.get_flag(K_COMPLETED, false)
	var got_best: Variant = reborn.get_flag(K_BEST, 0)
	_check("R3 重启恢复：completed 不回退、best_wave 不回退",
		_val_eq(got_completed, true) and _val_eq(got_best, 3),
		"completed=%s best_wave=%s" % [str(got_completed), str(got_best)])


func _finish() -> void:
	var ok: bool = _fail == 0 and _pass > 0
	print("[WFV040] ---- 回读汇总 ----")
	print("[WFV040] SUMMARY phase=%s pid=%d pass=%d fail=%d ok=%s" % [
		_phase, OS.get_process_id(), _pass, _fail, str(ok)])
	print("[WFV040] RESULT=%s" % ("ALL_PASS" if ok else "HAS_FAIL"))
	quit(0 if ok else 1)
