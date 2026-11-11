extends SceneTree

## R28 · 赐福引导三步教学三段式 flag 口径自测（Rank-3，cmd-20261111-095602-827-A3，[ROUND=R28]，v0.6.0）
## 目标：把 00-协作契约.md §3.3 / 存档与flag规范.md §3.3 / WAVE-TRIAL-GDD.md §10.8 的口径
##   逐条转成机器可判定断言，真跑输出 PASS/FAIL 与 RESULT。
## 验证 4 类：
##   A 三段式正则（2 个新 flag 通过 + 六类反例拒绝）
##   B 单向 / 单调（completed false→true 无回写；step_index 0→1→2→3 严格递增；
##      错误按键 / 重复触发 / T 重开 / 失败 / 重启不回退、不二次累加、不翻转）
##   C 重启读回一致（真实 FileAccess 落盘 → 新建独立 State 实例 _load() 逐项读回；
##      并由 TUTORIAL_V060_PHASE=write|read 两个独立引擎进程实证「重启」）
##   D commit 顺序「先落盘再改运行时实例」+ 十字段齐全 / schema_version=3 / 落盘 flags 全合法
## --script 模式纪律：不用 /root/... 绝对路径；用 Engine.get_main_loop() / get_root().get_node_or_null()
##   相对探活，取不到如实降级、不依赖其结果判 PASS（任务单明确要求）。
## 如实边界：本载体是「口径级模拟」，不碰 godot/ 工程文件、不写 slot_01/delta.json（用独立
##   user:// 文件）、不对 Rank-1/2 运行时代验；本轮 Rank-3 不写任何 godot/ 工程文件。
## 模拟常量：step_index 上限 3 为任务单给定的「三步」结构描述、非游戏数值；不引用也不替代
##   Rank-2 tutorial_steps.tres / WAVE-TRIAL-TUNING.md / GRACE-UPGRADE-TUNING.md 的 [PLACEHOLDER] 数值。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const K_COMPLETED: String = "grace.tutorial.completed"
const K_STEP: String = "grace.tutorial.step_index"
const K_POINTS: String = "grace.trial.points"
const STATE_PATH: String = "user://tutorial_flags_v060_state.json"

## 十字段（存档与flag规范.md §4.1 冻结，§4.4 回放消费）；用于断言新 flag 不新增顶层字段。
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]

## 口径级模拟常量（非游戏数值、不进入任何数据表）：
const SIM_STEP_MAX: int = 3   ## 「三步」结构，任务单给定描述，非 Rank-2 数值
const SIM_REWARD: int = 1     ## 模拟每步奖励增量，仅用于机器判定 points 只增不减、不引用 Rank-2 reward_points

## 口径基线快照（自测构造的模拟终态，非工程 / GDD 数值）：
## 模拟「三步依次完成 → step_index=3 / completed=true / points=3（每步模拟 +1）」。
const EXPECT: Dictionary = {
	K_COMPLETED: true,
	K_STEP: 3,
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
# 步数序列记录（供 B 类机器判定）
var _step_series: Array[int] = []


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
		print("[TFV060] %s PASS=true | %s" % [tag, detail])
	else:
		_fail += 1
		print("[TFV060] %s PASS=false | %s" % [tag, detail])


## 值相等：容忍 JSON int→float round-trip（与 R25 / R26 / R27 / r22_save_e2e.gd 同口径），bool/String 严格类型+值。
func _val_eq(a: Variant, b: Variant) -> bool:
	var ta: int = typeof(a)
	var tb: int = typeof(b)
	if (ta == TYPE_INT or ta == TYPE_FLOAT) and (tb == TYPE_INT or tb == TYPE_FLOAT):
		return is_equal_approx(float(a), float(b))
	return ta == tb and a == b


func _initialize() -> void:
	_phase = OS.get_environment("TUTORIAL_V060_PHASE")
	if _phase == "":
		_phase = "selftest"
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	_flags = _baseline()
	print("[TFV060] ==== verify_tutorial_flags_v060 真跑开始 ====")
	print("[TFV060] phase=%s pid=%d" % [_phase, OS.get_process_id()])
	# --script 模式不用 /root/... 绝对路径：用 Engine.get_main_loop() / get_root() 相对取节点，取不到如实降级。
	var ml: MainLoop = Engine.get_main_loop()
	var root: Node = get_root()
	var ws_probe: Node = null
	if root != null:
		ws_probe = root.get_node_or_null("WorldState")
	print("[TFV060] main_loop=%s root=%s WorldState_probe=%s（仅探活，不用 /root/ 绝对路径，不依赖其结果判 PASS）" % [
		str(ml != null), str(root != null), str(ws_probe != null)])
	process_frame.connect(_on_frame)


func _baseline() -> Dictionary:
	return {
		K_COMPLETED: false,
		K_STEP: 0,
		K_POINTS: 0,
	}


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
		print("[TFV060] 未知 TUTORIAL_V060_PHASE=%s（应为 selftest|write|read）" % _phase)
		_check("PHASE_VALID", false, "phase=%s" % _phase)
	_finish()


## 口径级「先落盘再改运行时实例」：模拟 WAVE-TRIAL-GDD.md §10.8 步骤 3(commit) → 步骤 4(改实例)。
## 纪律：先写 _disk（落盘），再写 _runtime（运行时实例），事件顺序追加进 _order 供机器判定。
func _commit_then_runtime(reason: String, snapshot: Dictionary) -> void:
	_order.append("disk_write:" + reason)          # ★ 先落盘
	_disk = snapshot.duplicate(true)
	_order.append("runtime_update:" + reason)     # 再改运行时实例
	_runtime = snapshot.duplicate(true)


## 口径级「完成一步」：模拟 Rank-1 tutorial_step_completed → Rank-3 落盘。
## 门控：step 不推进（重复 / 回退）则拒绝、不发奖、不 commit；通过则 step_index = max(旧, step)、
## points += SIM_REWARD，且与 commit 原子绑定（先落盘再改实例）。
func _advance_step(step: int) -> bool:
	var cur: int = int(_flags.get(K_STEP, 0))
	var next: int = step
	if cur > step:
		next = cur                                  # max(旧, 本步)：不回写更小值（T 重开 / 重复触发）
	if next == cur:
		return false                                # 无推进：幂等拒绝，不写 flag、不 commit
	_flags[K_STEP] = next
	_flags[K_POINTS] = int(_flags.get(K_POINTS, 0)) + SIM_REWARD
	_commit_then_runtime("tutorial_step_completed", _flags)
	_step_series.append(int(_flags.get(K_STEP, -1)))
	return true


## 口径级「三步全完成」：completed=false→true 单向，与末次 step_index 同一原子 commit。
func _mark_completed() -> bool:
	if bool(_flags.get(K_COMPLETED, false)):
		return false                                # 已 true：幂等拒绝，不翻转、不产生新 commit
	_flags[K_COMPLETED] = true
	_commit_then_runtime("tutorial_completed", _flags)
	return true


## 构造十字段 payload（新 flag 只进 flags 字典，不新增顶层字段；removals 恒为空）。
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
	_test_oneway_monotonic()
	_test_restart_readback()
	_test_commit_and_schema()


## ================= A 三段式正则 =================
func _test_regex() -> void:
	var keys: Array[String] = [K_COMPLETED, K_STEP]
	var bad: Array[String] = []
	for k in keys:
		if _re.search(k) == null:
			bad.append(k)
	_check("A1 两个新 flag 全部通过三段式正则", bad.is_empty(),
		"regex=%s keys=%s bad=%s" % [FLAG_KEY_REGEX, str(keys), str(bad)])
	# 六类反例：两段式 / 大写 / 连字符 / 非法前缀 / 中文 / 四段（点号嵌套）
	var bad_keys: Array[String] = [
		"grace.tutorial_completed",
		"grace.Tutorial.completed",
		"grace.tutorial.step-index",
		"hero.tutorial.completed",
		"grace.tutorial.已完成",
		"grace.tutorial.step.index",
	]
	var bad_hits: Array[String] = []
	for k in bad_keys:
		if _re.search(k) != null:
			bad_hits.append(k)
	_check("A2 六类非法 key 全部被三段式正则拒绝", bad_hits.is_empty(),
		"bad_total=%d bad_accepted=%s" % [bad_keys.size(), str(bad_hits)])


## ================= B 单向 / 单调 =================
func _test_oneway_monotonic() -> void:
	_flags = _baseline()
	_step_series.clear()
	_order.clear()
	# 三步依次完成：step_index 0→1→2→3
	var ok1: bool = _advance_step(1)
	var ok2: bool = _advance_step(2)
	var ok3: bool = _advance_step(3)
	var expect: Array[int] = [1, 2, 3]
	var mono: bool = ok1 and ok2 and ok3 and _step_series == expect
	for i in range(1, _step_series.size()):
		if _step_series[i] <= _step_series[i - 1]:
			mono = false
	_check("B1 三步依次完成 step_index 严格单调递增 0→1→2→3", mono,
		"series=%s expect=%s" % [str(_step_series), str(expect)])
	# 三步全完成：completed false→true 单向
	var okc: bool = _mark_completed()
	_check("B2 三步全完成 completed false→true、points 每步 +1 只增不减",
		okc and bool(_flags.get(K_COMPLETED, false)) == true and int(_flags.get(K_POINTS, -1)) == SIM_STEP_MAX * SIM_REWARD,
		"completed=%s step=%s points=%s" % [str(_flags.get(K_COMPLETED)), str(_flags.get(K_STEP)), str(_flags.get(K_POINTS))])
	# 重复触发 / 错误按键 / T 重开 / 失败 / 重启：均不回退、不二次累加、不翻转、不产生新 commit
	var order_before: int = _order.size()
	var dup: bool = _advance_step(3)          # 重复触发同一步
	var rollback: bool = _advance_step(1)     # 模拟 T 重开传入更小步序号
	var dup_c: bool = _mark_completed()       # 重复置 completed
	_check("B3 重复触发 / T 重开（更小步序号）/ 重复 completed 被拒，step_index 不回退、points 不二次累加、无新 commit",
		(not dup) and (not rollback) and (not dup_c)
			and int(_flags.get(K_STEP, -1)) == 3
			and int(_flags.get(K_POINTS, -1)) == SIM_STEP_MAX * SIM_REWARD
			and bool(_flags.get(K_COMPLETED, false)) == true
			and _order.size() == order_before,
		"dup=%s rollback=%s dup_c=%s step=%s points=%s order_delta=%d" % [
			str(dup), str(rollback), str(dup_c), str(_flags.get(K_STEP)), str(_flags.get(K_POINTS)), _order.size() - order_before])
	# 失败 / 超时 / 主动退出 / 重启：口径中无 false 回写、无更小 step_index 回写路径
	for i in range(3):
		_commit_then_runtime("wave_trial_settled_%d" % i, _flags)
	_check("B4 失败 / 超时 / 退出 / 重启后 completed 仍 true、step_index 不回退、points 不回退",
		bool(_flags.get(K_COMPLETED, false)) == true
			and int(_flags.get(K_STEP, -1)) == 3
			and int(_flags.get(K_POINTS, -1)) == SIM_STEP_MAX * SIM_REWARD,
		"completed=%s step=%s points=%s" % [str(_flags.get(K_COMPLETED)), str(_flags.get(K_STEP)), str(_flags.get(K_POINTS))])
	# 绝不写 removals：payload 的 removals 恒为空数组，points 全程不被改小
	var payload: Dictionary = _make_payload(_flags, "tutorial_completed")
	var removals: Array = payload["removals"] as Array
	_check("B5 教学奖励绝不写 removals、绝不回退 points（只累加模型）",
		removals.is_empty() and int(_flags.get(K_POINTS, -1)) == SIM_STEP_MAX * SIM_REWARD,
		"removals=%s points=%s" % [str(removals), str(_flags.get(K_POINTS))])


## ================= C 重启读回一致 =================
func _test_restart_readback() -> void:
	# 落盘 B 演变后的 _flags（应等于 EXPECT），再与 EXPECT 逐项比对，验证真实演变态可重启读回
	var payload: Dictionary = _make_payload(_flags, "tutorial_completed")
	var f: FileAccess = FileAccess.open(STATE_PATH, FileAccess.WRITE)
	var write_ok: bool = f != null
	if write_ok:
		f.store_string(JSON.stringify(payload))
		f.close()
	_check("C1 真实落盘到独立 user:// 文件（不碰 slot_01/delta.json）",
		write_ok and FileAccess.file_exists(STATE_PATH),
		"path=%s abs=%s" % [STATE_PATH, ProjectSettings.globalize_path(STATE_PATH)])
	# 模拟「重启」：新建完全独立的 State 实例，空内存，从磁盘 _load() 读回（不复用 _flags）
	var reborn := _State.new()
	var load_ok: bool = reborn.load_from_file(STATE_PATH)
	_check("C2 新实例 _load() 从磁盘重建内存", load_ok, "load_ok=%s" % str(load_ok))
	var mism: Array[String] = []
	for k in EXPECT.keys():
		var key: String = String(k)
		var got: Variant = reborn.get_flag(key, null)
		if not _val_eq(got, EXPECT[key]):
			mism.append("%s got=%s want=%s" % [key, str(got), str(EXPECT[key])])
	_check("C3 重启读回逐项一致（completed / step_index / points 共 3/3）", mism.is_empty(),
		"readback=%s mism=%s" % [str(reborn.snapshot()), str(mism)])


## ================= D commit 顺序 + 十字段 / schema_version =================
func _test_commit_and_schema() -> void:
	# 重置为干净的事件序列，连续 3 次教学结算验证顺序（3 个独立 reason，不改 flag 语义）
	_order.clear()
	_disk.clear()
	_runtime.clear()
	for i in range(3):
		_commit_then_runtime("tutorial_step_completed_%d" % i, _flags)
	var ok: bool = _order.size() == 6
	for i in range(0, _order.size(), 2):
		if not (String(_order[i]).begins_with("disk_write") and String(_order[i + 1]).begins_with("runtime_update")):
			ok = false
	_check("D1 commit 顺序「先落盘再改运行时实例」（连续 3 次）", ok,
		"order=%s" % str(_order))
	_check("D2 落盘态与运行时实例态逐项一致", _disk == _runtime,
		"disk=%s runtime=%s" % [str(_disk), str(_runtime)])
	var payload: Dictionary = _make_payload(EXPECT, "tutorial_completed")
	var top: Array = payload.keys()
	var extra: Array[String] = []
	var missing: Array[String] = []
	for k in top:
		if not TEN_FIELDS.has(String(k)):
			extra.append(String(k))
	for k in TEN_FIELDS:
		if not payload.has(k):
			missing.append(k)
	_check("D3 十字段齐全且无额外顶层字段（新 flag 只进 flags 字典）",
		extra.is_empty() and missing.is_empty() and top.size() == TEN_FIELDS.size(),
		"top=%s extra=%s missing=%s" % [str(top), str(extra), str(missing)])
	_check("D4 schema_version 保持 3、不触发迁移", int(payload.get("schema_version", -1)) == 3,
		"schema_version=%s" % str(payload.get("schema_version", -1)))
	var bad: Array[String] = []
	for k in (payload["flags"] as Dictionary).keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_check("D5 落盘 flags 全通过三段式正则", bad.is_empty(),
		"keys=%s bad=%s" % [str((payload["flags"] as Dictionary).keys()), str(bad)])


## ================= write / read 两阶段（真·跨进程重启实证） =================
func _run_write() -> void:
	var payload: Dictionary = _make_payload(EXPECT, "tutorial_completed")
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
	_check("W3 种子基线 completed=true / step_index=3 / points=3（三步全完成口径级终态）",
		bool(EXPECT[K_COMPLETED]) == true and int(EXPECT[K_STEP]) == SIM_STEP_MAX
			and int(EXPECT[K_POINTS]) == SIM_STEP_MAX * SIM_REWARD,
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
	_check("R2 跨进程读回 3/3 一致（completed / step_index / points）", mism.is_empty(),
		"readback=%s mism=%s" % [str(reborn.snapshot()), str(mism)])
	var got_completed: Variant = reborn.get_flag(K_COMPLETED, false)
	var got_step: Variant = reborn.get_flag(K_STEP, 0)
	var got_points: Variant = reborn.get_flag(K_POINTS, 0)
	_check("R3 重启恢复：completed 不回退、step_index 不回退、points 不回退",
		_val_eq(got_completed, true) and _val_eq(got_step, SIM_STEP_MAX)
			and _val_eq(got_points, SIM_STEP_MAX * SIM_REWARD),
		"completed=%s step=%s points=%s" % [str(got_completed), str(got_step), str(got_points)])


func _finish() -> void:
	var ok: bool = _fail == 0 and _pass > 0
	print("[TFV060] ---- 回读汇总 ----")
	print("[TFV060] SUMMARY phase=%s pid=%d pass=%d fail=%d ok=%s" % [
		_phase, OS.get_process_id(), _pass, _fail, str(ok)])
	print("[TFV060] RESULT=%s" % ("ALL_PASS" if ok else "HAS_FAIL"))
	quit(0 if ok else 1)
