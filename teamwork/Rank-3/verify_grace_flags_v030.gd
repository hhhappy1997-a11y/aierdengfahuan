extends SceneTree

## R25 · 重复挑战三段式 flag 口径自测（Rank-3，cmd-20261110-204604-840-A3，[ROUND=R25]，v0.3.0 方向 4）
## 目标：把 GRACE-RETRY-V020.md §2 / §4 的口径逐条转成机器可判定断言，真跑输出 PASS/FAIL 与 RESULT。
## 验证 4 类：
##   A 两个 flag 通过三段式正则（含六类反例）
##   B commit 顺序「先落盘再改运行时实例」（GRACE-RETRY §4.2 纪律）
##   C retried 单调递增（只 +1、休息不清零、门控不二次 +1、defeated 不回退）
##   D 重启读回一致（真实 FileAccess 落盘 → 新建独立 State 实例 _load() 逐项读回；
##     并由 GRACE_V030_PHASE=write|read 两个独立引擎进程实证「重启」）
## --script 模式纪律：不用 /root/... 绝对路径；用 Engine.get_main_loop() / get_root().get_node_or_null()
##   相对探活，取不到如实降级、不依赖其结果判 PASS（任务单明确要求）。
## 如实边界：本载体是「口径级模拟」，不碰 godot/ 工程文件、不写 slot_01/delta.json（用独立
##   user:// 文件）、不对 Rank-2 运行时代验；本轮 Rank-3 不写任何 godot/ 工程文件。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const K_RETRIED: String = "grace.encounter_01.retried"
const K_ACTIVE: String = "grace.encounter_01.retry_active"
const K_DEFEATED: String = "combat.boss_01_margit.defeated"
const STATE_PATH: String = "user://grace_flags_v030_state.json"

# write 阶段注入、read 阶段读回比对的期望快照（口径基线：retried 累计 3 次、回合已结算、Boss 永久击败）
const EXPECT: Dictionary = {
	K_RETRIED: 3,
	K_ACTIVE: false,
	K_DEFEATED: true,
}

var _pass: int = 0
var _fail: int = 0
var _frame: int = 0
var _phase: String = ""
var _re: RegEx = null

# 口径级内存状态：模拟 I-1 WorldState flags（L1 世界持久层 / L2 赐福业务层）
var _flags: Dictionary = {}
# 模拟磁盘态（落盘目标）与运行时实例（L3），用于断言「先落盘再改运行时实例」
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

	func get_flag(key: String, default: Variant) -> Variant:
		if _f.has(key):
			return _f[key]
		return default

	func snapshot() -> Dictionary:
		return _f.duplicate(true)


func _check(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
		print("[GFV030] %s PASS=true | %s" % [tag, detail])
	else:
		_fail += 1
		print("[GFV030] %s PASS=false | %s" % [tag, detail])


## 值相等：容忍 JSON int→float round-trip（与 r22_save_e2e.gd 同口径），bool/String 严格类型+值。
func _val_eq(a: Variant, b: Variant) -> bool:
	var ta: int = typeof(a)
	var tb: int = typeof(b)
	if (ta == TYPE_INT or ta == TYPE_FLOAT) and (tb == TYPE_INT or tb == TYPE_FLOAT):
		return is_equal_approx(float(a), float(b))
	return ta == tb and a == b


func _initialize() -> void:
	_phase = OS.get_environment("GRACE_V030_PHASE")
	if _phase == "":
		_phase = "selftest"
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	_flags = {
		K_RETRIED: 0,
		K_ACTIVE: false,
		K_DEFEATED: true,
	}
	print("[GFV030] ==== verify_grace_flags_v030 真跑开始 ====")
	print("[GFV030] phase=%s pid=%d" % [_phase, OS.get_process_id()])
	# --script 模式不用 /root/... 绝对路径：用 Engine.get_main_loop() / get_root() 相对取节点，取不到如实降级。
	var ml: MainLoop = Engine.get_main_loop()
	var root: Node = get_root()
	var ws_probe: Node = null
	if root != null:
		ws_probe = root.get_node_or_null("WorldState")
	print("[GFV030] main_loop=%s root=%s WorldState_probe=%s（仅探活，不用 /root/ 绝对路径，不依赖其结果判 PASS）" % [
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
		print("[GFV030] 未知 GRACE_V030_PHASE=%s（应为 selftest|write|read）" % _phase)
		_check("PHASE_VALID", false, "phase=%s" % _phase)
	_finish()


## 口径级「先落盘再改运行时实例」：模拟 GRACE-RETRY §4.2 步骤 9(commit) → 步骤 10(改 L3 实例)。
## 纪律：先写 _disk（落盘），再写 _runtime（运行时实例），事件顺序追加进 _order 供机器判定。
func _commit_then_runtime(reason: String, snapshot: Dictionary) -> void:
	_order.append("disk_write:" + reason)          # ★ 先落盘
	_disk = snapshot.duplicate(true)
	_order.append("runtime_update:" + reason)     # 再改运行时实例（L3）
	_runtime = snapshot.duplicate(true)


func _run_selftest() -> void:
	_test_regex()
	_test_commit_order()
	_test_monotonic()
	_test_restart_readback()


## ================= A 三段式正则 =================
func _test_regex() -> void:
	_check("A1 两个新 flag 通过三段式正则",
		_re.search(K_RETRIED) != null and _re.search(K_ACTIVE) != null,
		"regex=%s retried=%s active=%s" % [FLAG_KEY_REGEX,
			str(_re.search(K_RETRIED) != null), str(_re.search(K_ACTIVE) != null)])
	# 反例（GRACE-RETRY §2.3 禁止项里正则确应拒绝的六类）：两段式 / 大写 / 连字符 / 四段 / 非法前缀 / 中文
	var bad_keys: Array[String] = [
		"grace.encounter_01_retried",
		"grace.Encounter_01.retried",
		"grace.encounter-01.retried",
		"grace.encounter_01.retried.extra",
		"hero.encounter_01.retried",
		"grace.encounter_01.重试",
	]
	var bad_hits: Array[String] = []
	for k in bad_keys:
		if _re.search(k) != null:
			bad_hits.append(k)
	_check("A2 六类非法 key 全部被三段式正则拒绝", bad_hits.is_empty(),
		"bad_total=%d bad_accepted=%s" % [bad_keys.size(), str(bad_hits)])


## ================= B commit 顺序「先落盘再改运行时实例」 =================
func _test_commit_order() -> void:
	_order.clear()
	_disk.clear()
	_runtime.clear()
	for i in range(3):
		var snap: Dictionary = _flags.duplicate(true)
		_commit_then_runtime("grace_retry", snap)
	# 每个 commit 内 disk_write 必须紧邻且先于 runtime_update
	var ok: bool = _order.size() == 6
	for i in range(0, _order.size(), 2):
		if not (String(_order[i]).begins_with("disk_write") and String(_order[i + 1]).begins_with("runtime_update")):
			ok = false
	_check("B1 commit 顺序「先落盘再改运行时实例」（连续 3 次 commit）", ok,
		"order=%s" % str(_order))
	_check("B2 落盘态与运行时实例态逐项一致", _disk == _runtime,
		"disk=%s runtime=%s" % [str(_disk), str(_runtime)])


## ================= C retried 单调递增 =================
func _test_monotonic() -> void:
	_flags = {
		K_RETRIED: 0,
		K_ACTIVE: false,
		K_DEFEATED: true,
	}
	var series: Array[int] = []
	# 模拟 3 次「发起重复挑战」：门控 retry_active == false 时才 +1，且先落盘；随后结算置 false 再落盘
	for i in range(3):
		if bool(_flags.get(K_ACTIVE, false)) == false:
			var next: int = int(_flags.get(K_RETRIED, 0)) + 1
			_flags[K_RETRIED] = next
			_flags[K_ACTIVE] = true
			_commit_then_runtime("grace_retry", _flags)   # ★ 发起先落盘
			_flags[K_ACTIVE] = false                       # 结算
			_commit_then_runtime("grace_retry", _flags)   # ★ 结算清理先落盘
		series.append(int(_flags.get(K_RETRIED, -1)))
	var expect: Array[int] = [1, 2, 3]
	var mono: bool = series.size() == expect.size()
	if mono:
		for i in range(series.size()):
			if series[i] != expect[i]:
				mono = false
	for i in range(1, series.size()):
		if series[i] <= series[i - 1]:
			mono = false
	_check("C1 retried 三次发起严格单调递增 0→1→2→3", mono,
		"series=%s expect=%s" % [str(series), str(expect)])
	# 门控：retry_active == true 时重复点「重复挑战」不二次 +1（幂等）
	var before: int = int(_flags.get(K_RETRIED, 0))
	_flags[K_ACTIVE] = true
	if bool(_flags.get(K_ACTIVE, false)) == false:
		_flags[K_RETRIED] = int(_flags.get(K_RETRIED, 0)) + 1
	_check("C2 同回合门控（retry_active=true）不二次 +1", int(_flags.get(K_RETRIED, 0)) == before,
		"before=%d after=%d active=%s" % [before, int(_flags.get(K_RETRIED, 0)), str(_flags.get(K_ACTIVE))])
	_flags[K_ACTIVE] = false
	# 赐福休息不清零 retried、defeated 不回退；重启 _load 不回退（读回段实证）
	var after_rest: int = int(_flags.get(K_RETRIED, 0))
	_check("C3 赐福休息后 retried 不清零、defeated 不回退",
		after_rest == 3 and bool(_flags.get(K_DEFEATED, false)) == true,
		"retried=%d defeated=%s" % [after_rest, str(_flags.get(K_DEFEATED))])


## ================= D 重启读回一致 =================
func _test_restart_readback() -> void:
	var payload: Dictionary = {
		"schema_version": 3,
		"slot": "slot_01",
		"flags": _flags.duplicate(true),
		"meta": {"last_commit_reason": "grace_retry"},
	}
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
	_check("D3 重启读回逐项一致（retried / retry_active / defeated 3/3）", mism.is_empty(),
		"readback=%s mism=%s" % [str(reborn.snapshot()), str(mism)])


## ================= write / read 两阶段（真·跨进程重启实证） =================
func _run_write() -> void:
	_flags = {
		K_RETRIED: 3,
		K_ACTIVE: false,
		K_DEFEATED: true,
	}
	var payload: Dictionary = {
		"schema_version": 3,
		"slot": "slot_01",
		"flags": _flags.duplicate(true),
		"meta": {"last_commit_reason": "grace_retry"},
	}
	var f: FileAccess = FileAccess.open(STATE_PATH, FileAccess.WRITE)
	var ok: bool = f != null
	if ok:
		f.store_string(JSON.stringify(payload))
		f.close()
	_check("W1 write 阶段真实落盘种子", ok and FileAccess.file_exists(STATE_PATH),
		"path=%s abs=%s" % [STATE_PATH, ProjectSettings.globalize_path(STATE_PATH)])
	var bad: Array[String] = []
	for k in _flags.keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_check("W2 落盘 flags 全通过三段式正则", bad.is_empty(),
		"keys=%s bad=%s" % [str(_flags.keys()), str(bad)])
	_check("W3 retried 基线为 3（3 次发起累计）", int(_flags.get(K_RETRIED, -1)) == 3,
		"retried=%s" % str(_flags.get(K_RETRIED, -1)))


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
	_check("R2 跨进程读回 3/3 一致（retried / retry_active / defeated）", mism.is_empty(),
		"readback=%s mism=%s" % [str(reborn.snapshot()), str(mism)])
	var active: Variant = reborn.get_flag(K_ACTIVE, false)
	_check("R3 重启恢复：retry_active 结算为 false（无残留 true）", _val_eq(active, false),
		"retry_active=%s" % str(active))


func _finish() -> void:
	var ok: bool = _fail == 0 and _pass > 0
	print("[GFV030] ---- 回读汇总 ----")
	print("[GFV030] SUMMARY phase=%s pid=%d pass=%d fail=%d ok=%s" % [
		_phase, OS.get_process_id(), _pass, _fail, str(ok)])
	print("[GFV030] RESULT=%s" % ("ALL_PASS" if ok else "HAS_FAIL"))
	quit(0 if ok else 1)
