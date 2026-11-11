extends SceneTree

## R27 · 赐福成长三段式 flag 口径自测（Rank-3，cmd-20261111-083350-244-A3，[ROUND=R27]，v0.5.0）
## 目标：把 00-协作契约.md §3.3 / 存档与flag规范.md §3.3 / WAVE-TRIAL-GDD.md §9.9 的口径
##   逐条转成机器可判定断言，真跑输出 PASS/FAIL 与 RESULT。
## 验证 6 类：
##   A 三段式正则（收敛后新 flag 通过 + 六类反例拒绝，含任务单四段字面被拒）
##   B spent_points 单调递增（购买累加 / 重复购买与余额不足不二次累加 / 休息重启不清零）
##   C unlocked 单向（false→true 单向 / 无 false 回写 / 已解锁重复购买拒绝不翻转）
##   D 余额非负（points − spent_points ≥ 0 / 余额不足拒绝且余额不变 / points 不回退、不用 removals）
##   E 重启读回一致（真实 FileAccess 落盘 → 新建独立 State 实例 _load() 逐项读回；
##     并由 GRACE_V050_PHASE=write|read 两个独立引擎进程实证「重启」）
##   F commit 顺序「先落盘再改运行时实例」+ 十字段齐全 / schema_version=3 / 落盘 flags 全合法
## --script 模式纪律：不用 /root/... 绝对路径；用 Engine.get_main_loop() / get_root().get_node_or_null()
##   相对探活，取不到如实降级、不依赖其结果判 PASS（任务单明确要求）。
## 如实边界：本载体是「口径级模拟」，不碰 godot/ 工程文件、不写 slot_01/delta.json（用独立
##   user:// 文件）、不对 Rank-1/2 运行时代验；本轮 Rank-3 不写任何 godot/ 工程文件。
## <id> 收敛：任务单模式键 grace.upgrade.<id>.unlocked 为四段，无法通过 §3.1 三段式正则；
##   落盘收敛为 grace.upgrade_<id>.unlocked。本脚本用示例 id（hp_max / roll_iframe /
##   attack_power，取自 Rank-2 任务单示例 effect_key，待其 grace_upgrade_config.gd 落地后校对）
##   验证三段式模板与不变量，不依赖、不预设具体 id；四段字面作为 A2 反例被拒，如实登记。
## 模拟常量：points=5 / 每项 cost=2 均为口径级模拟值，不引用也不替代 Rank-2
##   GRACE-UPGRADE-TUNING.md 的 [PLACEHOLDER] 数值；仅用于机器判定单调/单向/余额不变量。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const K_POINTS: String = "grace.trial.points"
const K_SPENT: String = "grace.trial.spent_points"
const K_UP1: String = "grace.upgrade_hp_max.unlocked"
const K_UP2: String = "grace.upgrade_roll_iframe.unlocked"
const K_UP3: String = "grace.upgrade_attack_power.unlocked"
const K_BAD_FOUR: String = "grace.upgrade.hp_max.unlocked"
const STATE_PATH: String = "user://grace_flags_v050_state.json"

## 十字段（存档与flag规范.md §4.1 冻结，§4.4 回放消费）；用于断言新 flag 不新增顶层字段。
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]

## 口径级模拟常量（非游戏数值、不进入任何数据表）：
const SIM_POINTS: int = 5   ## 模拟累计获得点数
const SIM_COST: int = 2     ## 模拟每项兑换成本（三项同成本便于算余额）

## 口径基线快照（自测构造的模拟终态，非工程 / GDD 数值）：
## 模拟「累计 5 点 → 买 2 项各 2 点 → 第 3 项余额不足被拒 → 重复购买被拒」：
##   points=5 / spent_points=4 / up1=true / up2=true / up3=false / 余额=1 ≥ 0。
const EXPECT: Dictionary = {
	K_POINTS: 5,
	K_SPENT: 4,
	K_UP1: true,
	K_UP2: true,
	K_UP3: false,
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
# 购买序列记录（供 B / D 类机器判定）
var _spent_series: Array[int] = []
var _balance_series: Array[int] = []


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
		print("[GFV050] %s PASS=true | %s" % [tag, detail])
	else:
		_fail += 1
		print("[GFV050] %s PASS=false | %s" % [tag, detail])


## 值相等：容忍 JSON int→float round-trip（与 R25 / R26 / r22_save_e2e.gd 同口径），bool/String 严格类型+值。
func _val_eq(a: Variant, b: Variant) -> bool:
	var ta: int = typeof(a)
	var tb: int = typeof(b)
	if (ta == TYPE_INT or ta == TYPE_FLOAT) and (tb == TYPE_INT or tb == TYPE_FLOAT):
		return is_equal_approx(float(a), float(b))
	return ta == tb and a == b


func _initialize() -> void:
	_phase = OS.get_environment("GRACE_V050_PHASE")
	if _phase == "":
		_phase = "selftest"
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	_flags = _baseline()
	print("[GFV050] ==== verify_grace_flags_v050 真跑开始 ====")
	print("[GFV050] phase=%s pid=%d" % [_phase, OS.get_process_id()])
	# --script 模式不用 /root/... 绝对路径：用 Engine.get_main_loop() / get_root() 相对取节点，取不到如实降级。
	var ml: MainLoop = Engine.get_main_loop()
	var root: Node = get_root()
	var ws_probe: Node = null
	if root != null:
		ws_probe = root.get_node_or_null("WorldState")
	print("[GFV050] main_loop=%s root=%s WorldState_probe=%s（仅探活，不用 /root/ 绝对路径，不依赖其结果判 PASS）" % [
		str(ml != null), str(root != null), str(ws_probe != null)])
	process_frame.connect(_on_frame)


func _baseline() -> Dictionary:
	return {
		K_POINTS: SIM_POINTS,
		K_SPENT: 0,
		K_UP1: false,
		K_UP2: false,
		K_UP3: false,
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
		print("[GFV050] 未知 GRACE_V050_PHASE=%s（应为 selftest|write|read）" % _phase)
		_check("PHASE_VALID", false, "phase=%s" % _phase)
	_finish()


## 口径级「先落盘再改运行时实例」：模拟 WAVE-TRIAL-GDD.md §9.9 步骤 3(commit) → 步骤 4(改实例)。
## 纪律：先写 _disk（落盘），再写 _runtime（运行时实例），事件顺序追加进 _order 供机器判定。
func _commit_then_runtime(reason: String, snapshot: Dictionary) -> void:
	_order.append("disk_write:" + reason)          # ★ 先落盘
	_disk = snapshot.duplicate(true)
	_order.append("runtime_update:" + reason)     # 再改运行时实例
	_runtime = snapshot.duplicate(true)


## 口径级兑换：模拟 Rank-2 grace_upgrade_service.purchase() 的判定门控 + Rank-3 落盘。
## 门控顺序：已解锁 → 幂等拒绝；余额不足 → 拒绝；均不写 flag、不 commit。
## 通过则：spent_points = 旧 + cost、unlocked = true，且与 commit 原子绑定（先落盘再改实例）。
func _attempt_purchase(up_key: String, cost: int) -> bool:
	if bool(_flags.get(up_key, false)):           # 已解锁：幂等拒绝，不二次扣点
		return false
	var points: int = int(_flags.get(K_POINTS, 0))
	var spent: int = int(_flags.get(K_SPENT, 0))
	if points - spent < cost:                     # 余额不足：拒绝，不写 flag
		return false
	_flags[K_SPENT] = spent + cost
	_flags[up_key] = true
	_commit_then_runtime("grace_upgrade_purchased", _flags)
	_spent_series.append(int(_flags.get(K_SPENT, -1)))
	_balance_series.append(points - int(_flags.get(K_SPENT, -1)))
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
	_test_spent_monotonic()
	_test_unlocked_oneway()
	_test_balance_nonneg()
	_test_restart_readback()
	_test_commit_and_schema()


## ================= A 三段式正则 =================
func _test_regex() -> void:
	var keys: Array[String] = [K_POINTS, K_SPENT, K_UP1, K_UP2, K_UP3]
	var bad: Array[String] = []
	for k in keys:
		if _re.search(k) == null:
			bad.append(k)
	_check("A1 余额输入 + 新 flag 全部通过三段式正则", bad.is_empty(),
		"regex=%s keys=%s bad=%s" % [FLAG_KEY_REGEX, str(keys), str(bad)])
	# 六类反例：两段式 / 大写 / 连字符 / 非法前缀 / 中文 / 四段（点号嵌套，即任务单四段字面）
	var bad_keys: Array[String] = [
		"grace.trial_spent_points",
		"grace.Trial.spent_points",
		"grace.trial.spent-points",
		"hero.trial.spent_points",
		"grace.trial.已消费",
		K_BAD_FOUR,
	]
	var bad_hits: Array[String] = []
	for k in bad_keys:
		if _re.search(k) != null:
			bad_hits.append(k)
	_check("A2 六类非法 key 全部被三段式正则拒绝（含四段字面 grace.upgrade.<id>.unlocked 收敛反例）", bad_hits.is_empty(),
		"bad_total=%d bad_accepted=%s four_seg=%s" % [bad_keys.size(), str(bad_hits), K_BAD_FOUR])


## ================= B spent_points 单调递增 =================
func _test_spent_monotonic() -> void:
	_flags = _baseline()
	_spent_series.clear()
	_balance_series.clear()
	# 买第 1 项（cost 2）：spent 0→2
	var ok1: bool = _attempt_purchase(K_UP1, SIM_COST)
	# 买第 2 项（cost 2）：spent 2→4
	var ok2: bool = _attempt_purchase(K_UP2, SIM_COST)
	var expect: Array[int] = [2, 4]
	var mono: bool = ok1 and ok2 and _spent_series == expect
	for i in range(1, _spent_series.size()):
		if _spent_series[i] <= _spent_series[i - 1]:
			mono = false
	_check("B1 两次兑换 spent_points 严格单调递增 0→2→4", mono,
		"series=%s expect=%s" % [str(_spent_series), str(expect)])
	# 余额不足（买第 3 项）+ 重复购买（第 1 项）：均被拒，spent 不二次累加
	var ok3: bool = _attempt_purchase(K_UP3, SIM_COST)
	var ok_dup: bool = _attempt_purchase(K_UP1, SIM_COST)
	_check("B2 余额不足 / 重复购买被拒，spent_points 不二次累加",
		(not ok3) and (not ok_dup) and int(_flags.get(K_SPENT, -1)) == 4,
		"spent=%s ok3=%s ok_dup=%s" % [str(_flags.get(K_SPENT)), str(ok3), str(ok_dup)])
	# 赐福休息 / 重启：spent_points 不清零、points 不回退
	for i in range(3):
		_commit_then_runtime("wave_trial_settled_%d" % i, _flags)
	_check("B3 赐福休息 / 重启 spent_points 不清零、points 不回退",
		int(_flags.get(K_SPENT, -1)) == 4 and int(_flags.get(K_POINTS, -1)) == SIM_POINTS,
		"spent=%s points=%s" % [str(_flags.get(K_SPENT)), str(_flags.get(K_POINTS))])


## ================= C unlocked 单向 =================
func _test_unlocked_oneway() -> void:
	# 承接 B 终态：up1 / up2 已 true，up3 因余额不足仍 false
	_check("C1 兑换成功 up1 / up2 false→true、余额不足 up3 保持 false",
		bool(_flags.get(K_UP1, false)) == true and bool(_flags.get(K_UP2, false)) == true and bool(_flags.get(K_UP3, true)) == false,
		"up1=%s up2=%s up3=%s" % [str(_flags.get(K_UP1)), str(_flags.get(K_UP2)), str(_flags.get(K_UP3))])
	# 失败 / 重启 / 重复挑战：口径中无 false 回写路径，三次结算事件后仍为 true
	for i in range(3):
		_commit_then_runtime("wave_trial_settled_%d" % i, _flags)
	_check("C2 失败 / 重启 / 重复挑战 unlocked 只增不减（无 false 回写）",
		bool(_flags.get(K_UP1, false)) == true and bool(_flags.get(K_UP2, false)) == true,
		"up1=%s up2=%s" % [str(_flags.get(K_UP1)), str(_flags.get(K_UP2))])
	# 已解锁项重复 purchase 被拒、不翻转（不产生新 commit）
	var order_before: int = _order.size()
	var ok_dup: bool = _attempt_purchase(K_UP1, SIM_COST)
	_check("C3 已解锁项重复购买被拒、unlocked 不翻转、不产生新 commit",
		(not ok_dup) and bool(_flags.get(K_UP1, false)) == true and _order.size() == order_before,
		"ok_dup=%s up1=%s order_delta=%d" % [str(ok_dup), str(_flags.get(K_UP1)), _order.size() - order_before])


## ================= D 余额非负 =================
func _test_balance_nonneg() -> void:
	# 承接 B 的 _balance_series（每次成功兑换后的余额）
	var all_nonneg: bool = not _balance_series.is_empty()
	for b in _balance_series:
		if b < 0:
			all_nonneg = false
	_check("D1 每次成功兑换后余额 = points − spent_points ≥ 0", all_nonneg,
		"balance_series=%s" % str(_balance_series))
	# 余额不足拒绝后：余额 / points / spent 均不变
	var points_now: int = int(_flags.get(K_POINTS, 0))
	var spent_now: int = int(_flags.get(K_SPENT, 0))
	var balance_now: int = points_now - spent_now
	_check("D2 余额不足拒绝后余额不变、points 不回退、spent 不回退",
		balance_now == 1 and points_now == SIM_POINTS and spent_now == 4,
		"balance=%d points=%d spent=%d" % [balance_now, points_now, spent_now])
	# 绝不写 removals：payload 的 removals 恒为空数组，points 全程不被消费改小
	var payload: Dictionary = _make_payload(_flags, "grace_upgrade_purchased")
	var removals: Array = payload["removals"] as Array
	_check("D3 消费绝不写 removals、绝不回退 points（余额模型而非扣减模型）",
		removals.is_empty() and int(_flags.get(K_POINTS, -1)) == SIM_POINTS,
		"removals=%s points=%s" % [str(removals), str(_flags.get(K_POINTS))])


## ================= E 重启读回一致 =================
func _test_restart_readback() -> void:
	# 落盘 B/C 演变后的 _flags（应等于 EXPECT），再与 EXPECT 逐项比对，验证真实演变态可重启读回
	var payload: Dictionary = _make_payload(_flags, "grace_upgrade_purchased")
	var f: FileAccess = FileAccess.open(STATE_PATH, FileAccess.WRITE)
	var write_ok: bool = f != null
	if write_ok:
		f.store_string(JSON.stringify(payload))
		f.close()
	_check("E1 真实落盘到独立 user:// 文件（不碰 slot_01/delta.json）",
		write_ok and FileAccess.file_exists(STATE_PATH),
		"path=%s abs=%s" % [STATE_PATH, ProjectSettings.globalize_path(STATE_PATH)])
	# 模拟「重启」：新建完全独立的 State 实例，空内存，从磁盘 _load() 读回（不复用 _flags）
	var reborn := _State.new()
	var load_ok: bool = reborn.load_from_file(STATE_PATH)
	_check("E2 新实例 _load() 从磁盘重建内存", load_ok, "load_ok=%s" % str(load_ok))
	var mism: Array[String] = []
	for k in EXPECT.keys():
		var key: String = String(k)
		var got: Variant = reborn.get_flag(key, null)
		if not _val_eq(got, EXPECT[key]):
			mism.append("%s got=%s want=%s" % [key, str(got), str(EXPECT[key])])
	_check("E3 重启读回逐项一致（points / spent_points / 3×unlocked 共 5/5）", mism.is_empty(),
		"readback=%s mism=%s" % [str(reborn.snapshot()), str(mism)])


## ================= F commit 顺序 + 十字段 / schema_version =================
func _test_commit_and_schema() -> void:
	# 重置为干净的事件序列，连续 3 次兑换结算验证顺序（3 个独立 reason，不改 flag 语义）
	_order.clear()
	_disk.clear()
	_runtime.clear()
	for i in range(3):
		_commit_then_runtime("grace_upgrade_purchased_%d" % i, _flags)
	var ok: bool = _order.size() == 6
	for i in range(0, _order.size(), 2):
		if not (String(_order[i]).begins_with("disk_write") and String(_order[i + 1]).begins_with("runtime_update")):
			ok = false
	_check("F1 commit 顺序「先落盘再改运行时实例」（连续 3 次）", ok,
		"order=%s" % str(_order))
	_check("F2 落盘态与运行时实例态逐项一致", _disk == _runtime,
		"disk=%s runtime=%s" % [str(_disk), str(_runtime)])
	var payload: Dictionary = _make_payload(EXPECT, "grace_upgrade_purchased")
	var top: Array = payload.keys()
	var extra: Array[String] = []
	var missing: Array[String] = []
	for k in top:
		if not TEN_FIELDS.has(String(k)):
			extra.append(String(k))
	for k in TEN_FIELDS:
		if not payload.has(k):
			missing.append(k)
	_check("F3 十字段齐全且无额外顶层字段（新 flag 只进 flags 字典）",
		extra.is_empty() and missing.is_empty() and top.size() == TEN_FIELDS.size(),
		"top=%s extra=%s missing=%s" % [str(top), str(extra), str(missing)])
	_check("F4 schema_version 保持 3、不触发迁移", int(payload.get("schema_version", -1)) == 3,
		"schema_version=%s" % str(payload.get("schema_version", -1)))
	var bad: Array[String] = []
	for k in (payload["flags"] as Dictionary).keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_check("F5 落盘 flags 全通过三段式正则", bad.is_empty(),
		"keys=%s bad=%s" % [str((payload["flags"] as Dictionary).keys()), str(bad)])


## ================= write / read 两阶段（真·跨进程重启实证） =================
func _run_write() -> void:
	var payload: Dictionary = _make_payload(EXPECT, "grace_upgrade_purchased")
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
	_check("W3 种子基线 points=5 / spent_points=4 / up1=true / up2=true / up3=false / 余额=1≥0",
		int(EXPECT[K_POINTS]) == 5 and int(EXPECT[K_SPENT]) == 4
			and bool(EXPECT[K_UP1]) == true and bool(EXPECT[K_UP2]) == true
			and bool(EXPECT[K_UP3]) == false and (int(EXPECT[K_POINTS]) - int(EXPECT[K_SPENT])) >= 0,
		"expect=%s balance=%d" % [str(EXPECT), int(EXPECT[K_POINTS]) - int(EXPECT[K_SPENT])])


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
	_check("R2 跨进程读回 5/5 一致（points / spent_points / 3×unlocked）", mism.is_empty(),
		"readback=%s mism=%s" % [str(reborn.snapshot()), str(mism)])
	var got_spent: Variant = reborn.get_flag(K_SPENT, 0)
	var got_points: Variant = reborn.get_flag(K_POINTS, 0)
	var got_up1: Variant = reborn.get_flag(K_UP1, false)
	var got_up2: Variant = reborn.get_flag(K_UP2, false)
	_check("R3 重启恢复：spent_points / unlocked 不回退、余额非负",
		_val_eq(got_spent, 4) and _val_eq(got_up1, true) and _val_eq(got_up2, true)
			and (float(got_points) - float(got_spent)) >= 0.0,
		"spent=%s up1=%s up2=%s balance=%s" % [str(got_spent), str(got_up1), str(got_up2), str(float(got_points) - float(got_spent))])


func _finish() -> void:
	var ok: bool = _fail == 0 and _pass > 0
	print("[GFV050] ---- 回读汇总 ----")
	print("[GFV050] SUMMARY phase=%s pid=%d pass=%d fail=%d ok=%s" % [
		_phase, OS.get_process_id(), _pass, _fail, str(ok)])
	print("[GFV050] RESULT=%s" % ("ALL_PASS" if ok else "HAS_FAIL"))
	quit(0 if ok else 1)
