extends SceneTree

## ===========================================================================
## R30 / v0.8.0 · 赐福图鉴「成就奖励」自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_codex_reward_v080.gd
## 覆盖（任务单 ②）：4 项条件 / 奖励单调 / 重复领取拒绝 / 余额非负 /
##   grace.trial.points 只增不减 / commit 先落盘 / 异常输入拒绝。
## 输出逐条 PASS=true/false + SUMMARY pass/fail + RESULT（PASS / FAIL）；
## 失败 quit(1)，不伪造 PASS。
## 期望值来自任务单 ① 首版 [PLACEHOLDER]（30/50/80/120），校准后需同步
##   EXPECT_* 与 CODEX-TUNING.md / DONE-R30.md，不静默改数。
## 读表统一走 CACHE_MODE_IGNORE，校验落盘真值而非缓存。
## 纯内存夹具：WorldState 实例手动 new()（不 add_child、不写 user:// 盘），
##   FakeWriter 只记录 commit(reason) 时序，不污染生产存档。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const CONFIG_PATH: String = "res://data/rpg/codex_entries.tres"
const WORLD_STATE_SCRIPT_PATH: String = "res://scripts/rpg/world_state.gd"

const FIELD_KEYS: Array = [
	"id", "title", "description", "condition_kind", "condition_value", "reward_points"
]

## [PLACEHOLDER] R30 首版期望（任务单 ①），校验基准，不写进数据表；待人工试玩校准。
const EXPECT_IDS: Array = [
	"tutorial_complete", "wave_trial_clear", "all_grace_upgrades", "best_wave_3"
]
const EXPECT_KINDS: Array = ["bool_true", "bool_true", "all_of", "int_at_least"]
const EXPECT_REWARDS: Array = [30, 50, 80, 120]
const EXPECT_TOTAL: int = 280
const EXPECT_THRESHOLD: int = 3
const EXPECT_FLAG_KEYS: Array = [
	["grace.tutorial.completed"],
	["dungeon.wave_trial.completed"],
	[
		"grace.upgrade_hp_max_bonus.unlocked",
		"grace.upgrade_roll_iframe_bonus.unlocked",
		"grace.upgrade_attack_power_bonus.unlocked",
	],
	["dungeon.wave_trial.best_wave"],
]

const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const COMMIT_REASON: String = "codex_reward_claimed"

var _pass: int = 0
var _fail: int = 0
## 手动 new() 的 Node 临时实例统一登记，_finish() 退出前 free，避免 ObjectDB 泄漏告警。
var _temps: Array[Node] = []


func _track(n: Node) -> void:
	_temps.append(n)


## 显式注入的 SaveDeltaWriter 替身：只记录 commit(reason) 时序，不写 user:// 盘，
## 使 verify 可实证「先落盘再改运行时实例」链路而不污染存档。
class FakeWriter extends Node:
	var commits: Array[String] = []

	func commit(reason: String) -> void:
		commits.append(reason)


## 图鉴成就奖励发放夹具（纯内存，验证用，不改生产逻辑）：
##  - points 对应 grace.trial.points，只增不减；
##  - _claimed 已领取成就 id 集合（防重复领取）；
##  - claim() 严格「stage_flags（set_flag 入队）→ disk_write（commit 落盘）→ runtime_update」；
##  - 条件未达成 / 重复 / 非法奖励 / 空 id 一律拒绝，不写 points、不置位、不 commit；
##  - spend() 只增 grace.trial.spent_points，超余额拒绝，保证余额恒非负。
class CodexLedger extends RefCounted:
	var points: int = 0
	var spent: int = 0
	var _claimed: Dictionary = {}
	var events: Array[String] = []
	var ws: Node = null
	var writer: Node = null

	func is_claimed(id: String) -> bool:
		return _claimed.has(id)

	func balance_now() -> int:
		return GraceUpgradeService.balance(points, spent)

	func claim(entry_id: String, reward: int, condition_met: bool) -> Dictionary:
		if entry_id.is_empty():
			return {"ok": false, "reason": "invalid_id", "points": points, "spent": spent, "balance": balance_now()}
		if not condition_met:
			return {"ok": false, "reason": "condition_not_met", "points": points, "spent": spent, "balance": balance_now()}
		if _claimed.has(entry_id):
			return {"ok": false, "reason": "duplicate", "points": points, "spent": spent, "balance": balance_now()}
		if reward <= 0:
			return {"ok": false, "reason": "invalid_reward", "points": points, "spent": spent, "balance": balance_now()}
		var new_points: int = points + reward
		# ★ 顺序：stage_flags（先入队）→ disk_write（commit 先落盘）→ runtime_update（后改运行时实例）。
		events.append("stage_flags:" + entry_id)
		if ws != null and ws.has_method("set_flag"):
			ws.call("set_flag", GraceUpgradeService.FLAG_POINTS, new_points)
		if writer != null and writer.has_method("commit"):
			writer.call("commit", COMMIT_REASON)
			events.append("disk_write:" + COMMIT_REASON)
		else:
			events.append("disk_write_downgrade:" + entry_id)
		# 落盘后才更新运行时实例（points / 已领集合），实证「commit 先落盘」。
		points = new_points
		_claimed[entry_id] = true
		events.append("runtime_update:" + entry_id)
		return {"ok": true, "reason": "ok", "points": points, "spent": spent, "balance": balance_now()}

	func spend(amount: int) -> Dictionary:
		var bal: int = balance_now()
		if amount <= 0 or amount > bal:
			return {"ok": false, "reason": "insufficient", "points": points, "spent": spent, "balance": bal}
		spent += amount
		if ws != null and ws.has_method("set_flag"):
			ws.call("set_flag", GraceUpgradeService.FLAG_SPENT_POINTS, spent)
		return {"ok": true, "reason": "ok", "points": points, "spent": spent, "balance": balance_now()}


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V080] %s PASS=%s | %s" % [tag, str(ok), detail])


func _make_world_state() -> Node:
	var ws_script: Script = load(WORLD_STATE_SCRIPT_PATH) as Script
	var ws: Node = Node.new()
	_track(ws)
	ws.set_script(ws_script)
	ws.call("_ready")
	return ws


func _new_ledger(ws: Node, writer: Node) -> CodexLedger:
	var l: CodexLedger = CodexLedger.new()
	l.ws = ws
	l.writer = writer
	return l


func _initialize() -> void:
	print("[V080] === SELFTEST START ===")
	var cfg: CodexConfig = ResourceLoader.load(
		CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as CodexConfig
	_ck("table_load_cache_ignore", cfg != null, "path=%s" % CONFIG_PATH)
	if cfg == null:
		_finish()
		return
	_test_structure(cfg)
	_test_four_conditions(cfg)
	_test_condition_eval(cfg)
	_test_reward_monotonic(cfg)
	_test_duplicate_claim()
	_test_balance_nonneg()
	_test_points_monotonic()
	_test_commit_before_disk()
	_test_invalid_inputs(cfg)
	_finish()


## A) 表结构 / 4 项 6 字段 / 首版 [PLACEHOLDER] / 越界 / 空表降级
func _test_structure(cfg: CodexConfig) -> void:
	_ck("entry_count_4", cfg.entry_count() == 4 and cfg.entries.size() == 4,
		"count=%d size=%d" % [cfg.entry_count(), cfg.entries.size()])
	for i: int in range(4):
		var row: Dictionary = cfg.entries[i] as Dictionary
		var missing: Array[String] = []
		for k: String in FIELD_KEYS:
			if not row.has(k):
				missing.append(k)
		_ck("fields[%d]" % i, missing.is_empty(), "keys=%d missing=%s" % [row.size(), str(missing)])
		var e: CodexConfig.CodexEntry = cfg.get_entry(i)
		_ck("id[%d]" % i, e != null and e.id == str(EXPECT_IDS[i]),
			"got=%s expect=%s" % [str(e.id if e != null else "<null>"), str(EXPECT_IDS[i])])
		_ck("title_desc_nonempty[%d]" % i, e != null and not e.title.is_empty() and not e.description.is_empty(),
			"title=%s" % str(e.title if e != null else "<null>"))
		_ck("kind[%d]" % i, e != null and e.condition_kind == str(EXPECT_KINDS[i]),
			"got=%s expect=%s" % [str(e.condition_kind if e != null else "<null>"), str(EXPECT_KINDS[i])])
		_ck("reward[%d]" % i, e != null and e.reward_points == int(EXPECT_REWARDS[i]),
			"got=%s expect=%s" % [str(e.reward_points if e != null else -1), str(EXPECT_REWARDS[i])])
		_ck("valid[%d]" % i, cfg.is_entry_valid(e), "is_entry_valid=true")
	# A29：kind 只用既有 3 种 flag 语义，且 4 项覆盖全部 3 种。
	var unknown: Array[String] = []
	for i: int in range(4):
		var e2: CodexConfig.CodexEntry = cfg.get_entry(i)
		if e2 != null and not CodexConfig.is_condition_kind_known(e2.condition_kind):
			unknown.append(e2.condition_kind)
	var kinds_covered: bool = true
	for k: String in ["bool_true", "int_at_least", "all_of"]:
		var hit: bool = false
		for i: int in range(4):
			var e3: CodexConfig.CodexEntry = cfg.get_entry(i)
			if e3 != null and e3.condition_kind == k:
				hit = true
		if not hit:
			kinds_covered = false
	_ck("kind_only_3_known_semantics", unknown.is_empty(), "unknown=%s" % str(unknown))
	_ck("kind_covers_all_3", kinds_covered, "bool_true / int_at_least / all_of 全覆盖")
	_ck("bounds_negative_rejected", cfg.get_entry(-1) == null, "get_entry(-1)=null")
	_ck("bounds_index4_rejected", cfg.get_entry(4) == null, "get_entry(4)=null")
	var empty: CodexConfig = CodexConfig.new()
	_ck("empty_count_0", empty.entry_count() == 0, "count=0")
	_ck("empty_get_null", empty.get_entry(0) == null, "空表 get_entry(0)=null 不崩")
	_ck("empty_monotonic_false", not empty.is_reward_monotonic(), "空表非单调=false")
	_ck("empty_total_0", empty.total_reward_points() == 0, "空表合计=0")
	var d0: CodexConfig.CodexEntry = cfg.entry_from_dict({})
	_ck("missing_all_defaults", d0.id == CodexConfig.DEFAULT_ID \
		and d0.title == CodexConfig.DEFAULT_TITLE \
		and d0.description == CodexConfig.DEFAULT_DESCRIPTION \
		and d0.condition_kind == CodexConfig.DEFAULT_CONDITION_KIND \
		and d0.reward_points == CodexConfig.DEFAULT_REWARD_POINTS \
		and d0.condition_value.is_empty(), "缺字段全回落 [PLACEHOLDER] 基线")
	_ck("missing_all_invalid", not cfg.is_entry_valid(d0), "空表降级视图判非法")
	_ck("make_entry_6_fields", cfg.make_entry("x", "t", "d", "bool_true", {"flag": "grace.tutorial.completed"}, 1).size() == 6,
		"size=6")


## B) 4 项条件：结构合法 / 引用 flag 三段式 + 既有登记（条件可达）/ A36 解锁 key
func _test_four_conditions(cfg: CodexConfig) -> void:
	var re: RegEx = RegEx.new()
	re.compile(FLAG_KEY_REGEX)
	for i: int in range(4):
		var e: CodexConfig.CodexEntry = cfg.get_entry(i)
		if e == null:
			_ck("cond[%d]_shape" % i, false, "entry null")
			continue
		_ck("cond[%d]_shape" % i,
			CodexConfig.is_condition_shape_valid(e.condition_kind, e.condition_value),
			"kind=%s value=%s" % [e.condition_kind, str(e.condition_value)])
		var keys: Array[String] = CodexConfig.condition_flag_keys(e.condition_kind, e.condition_value)
		_ck("cond[%d]_flag_keys" % i, keys == (EXPECT_FLAG_KEYS[i] as Array),
			"keys=%s expect=%s" % [str(keys), str(EXPECT_FLAG_KEYS[i])])
		var bad_regex: Array[String] = []
		var unregistered: Array[String] = []
		for k: String in keys:
			if re.search(k) == null:
				bad_regex.append(k)
			if not CodexConfig.REGISTERED_FLAGS.has(k):
				unregistered.append(k)
		_ck("cond[%d]_flags_three_segment" % i, bad_regex.is_empty(),
			"keys=%s bad=%s" % [str(keys), str(bad_regex)])
		_ck("cond[%d]_flags_registered_reachable" % i, unregistered.is_empty(),
			"引用既有登记 flag，条件可达；unregistered=%s" % str(unregistered))
		# A36：成就解锁 flag = grace.codex_<id>.unlocked，三段式（id 下划线连接）。
		var unlock_key: String = "grace.codex_" + e.id + ".unlocked"
		_ck("cond[%d]_a36_unlock_key" % i, re.search(unlock_key) != null,
			"key=%s" % unlock_key)
	# int_at_least 阈值 == 3（与三波结构一致，保证可达）。
	var e3: CodexConfig.CodexEntry = cfg.get_entry(3)
	_ck("cond_threshold_3", e3 != null and int(e3.condition_value.get("threshold", -1)) == EXPECT_THRESHOLD,
		"threshold=%s expect=%d" % [str(e3.condition_value.get("threshold") if e3 != null else -1), EXPECT_THRESHOLD])


## C) 条件求值（纯函数）：未达成全 false / 达成全 true / 边界 / 非法输入拒绝
func _test_condition_eval(cfg: CodexConfig) -> void:
	var flags_empty: Dictionary = {}
	var flags_met: Dictionary = {
		"grace.tutorial.completed": true,
		"dungeon.wave_trial.completed": true,
		"dungeon.wave_trial.best_wave": EXPECT_THRESHOLD,
		"grace.upgrade_hp_max_bonus.unlocked": true,
		"grace.upgrade_roll_iframe_bonus.unlocked": true,
		"grace.upgrade_attack_power_bonus.unlocked": true,
	}
	var all_false_when_empty: bool = true
	var all_true_when_met: bool = true
	for i: int in range(4):
		var e: CodexConfig.CodexEntry = cfg.get_entry(i)
		if e == null:
			all_false_when_empty = false
			all_true_when_met = false
			continue
		if CodexConfig.evaluate_condition(e.condition_kind, e.condition_value, flags_empty):
			all_false_when_empty = false
		if not CodexConfig.evaluate_condition(e.condition_kind, e.condition_value, flags_met):
			all_true_when_met = false
	_ck("eval_empty_flags_all_false", all_false_when_empty, "4 项条件在未达成快照下全 false")
	_ck("eval_met_flags_all_true", all_true_when_met, "4 项条件在达成快照下全 true")
	# 逐项打印条件明细（落盘真值回读）。
	for i: int in range(4):
		var e2: CodexConfig.CodexEntry = cfg.get_entry(i)
		if e2 != null:
			print("[V080] cond_detail[%d] id=%s kind=%s value=%s flags=%s reward=%d" % [
				i, e2.id, e2.condition_kind, str(e2.condition_value),
				str(CodexConfig.condition_flag_keys(e2.condition_kind, e2.condition_value)),
				e2.reward_points])
	# 边界：best_wave=2 未达成 / =4 达成；all_of 缺一项 false；bool_true false。
	var e_int: CodexConfig.CodexEntry = cfg.get_entry(3)
	_ck("eval_int_below_threshold_false", e_int != null and not CodexConfig.evaluate_condition(
		e_int.condition_kind, e_int.condition_value, {"dungeon.wave_trial.best_wave": 2}), "best_wave=2 → false")
	_ck("eval_int_above_threshold_true", e_int != null and CodexConfig.evaluate_condition(
		e_int.condition_kind, e_int.condition_value, {"dungeon.wave_trial.best_wave": 4}), "best_wave=4 → true")
	var e_all: CodexConfig.CodexEntry = cfg.get_entry(2)
	var partial: Dictionary = {
		"grace.upgrade_hp_max_bonus.unlocked": true,
		"grace.upgrade_roll_iframe_bonus.unlocked": true,
	}
	_ck("eval_all_of_missing_one_false", e_all != null and not CodexConfig.evaluate_condition(
		e_all.condition_kind, e_all.condition_value, partial), "三项只解锁两项 → false")
	_ck("eval_bool_true_false", not CodexConfig.evaluate_condition(
		"bool_true", {"flag": "grace.tutorial.completed"}, {"grace.tutorial.completed": false}), "flag=false → false")
	# 非法输入一律 false、不崩。
	_ck("eval_unknown_kind_false", not CodexConfig.evaluate_condition(
		"string_equals", {"flag": "grace.tutorial.completed"}, flags_met), "未知 kind → false")
	_ck("eval_non_dict_value_false", not CodexConfig.evaluate_condition(
		"bool_true", "grace.tutorial.completed", flags_met), "condition_value 非 Dictionary → false")
	_ck("eval_missing_flag_false", not CodexConfig.evaluate_condition(
		"bool_true", {}, flags_met), "缺 flag → false")
	_ck("eval_bad_flag_key_false", not CodexConfig.evaluate_condition(
		"bool_true", {"flag": "grace.tutorial.completed.extra"}, flags_met), "四段非法 key → false")
	_ck("eval_negative_threshold_false", not CodexConfig.evaluate_condition(
		"int_at_least", {"flag": "dungeon.wave_trial.best_wave", "threshold": -1}, flags_met), "负阈值 → false")
	_ck("eval_empty_all_of_false", not CodexConfig.evaluate_condition(
		"all_of", {"flags": []}, flags_met), "空 flags 列表 → false")
	_ck("keys_invalid_value_empty", CodexConfig.condition_flag_keys("bool_true", null).is_empty(),
		"非 Dictionary → 空 key 数组")


## D) 奖励单调：30<50<80<120、合计 280；非单调表被识别
func _test_reward_monotonic(cfg: CodexConfig) -> void:
	var r: Array[int] = []
	for i: int in range(4):
		var e: CodexConfig.CodexEntry = cfg.get_entry(i)
		r.append(e.reward_points if e != null else 0)
	_ck("reward_monotonic_api", cfg.is_reward_monotonic(), "is_reward_monotonic=true")
	_ck("reward_30_50_80_120", r[0] == 30 and r[1] == 50 and r[2] == 80 and r[3] == 120,
		"rewards=%s" % str(r))
	_ck("reward_strict_inc", r[0] < r[1] and r[1] < r[2] and r[2] < r[3],
		"30 < 50 < 80 < 120")
	_ck("reward_total_280", cfg.total_reward_points() == EXPECT_TOTAL,
		"total=%d expect=%d" % [cfg.total_reward_points(), EXPECT_TOTAL])
	var bad: CodexConfig = CodexConfig.new()
	bad.entries.append(cfg.make_entry("a", "t", "d", "bool_true", {"flag": "grace.tutorial.completed"}, 50))
	bad.entries.append(cfg.make_entry("b", "t", "d", "bool_true", {"flag": "grace.tutorial.completed"}, 30))
	bad.entries.append(cfg.make_entry("c", "t", "d", "bool_true", {"flag": "grace.tutorial.completed"}, 80))
	bad.entries.append(cfg.make_entry("d", "t", "d", "bool_true", {"flag": "grace.tutorial.completed"}, 120))
	_ck("reward_nonmonotonic_detected", not bad.is_reward_monotonic(), "50,30,80,120 → 非单调=false")


## E) 重复领取拒绝：同 id 二次 / 连领多次 / 条件未达成 / points 不变 / commit 不增
func _test_duplicate_claim() -> void:
	var ws: Node = _make_world_state()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var l: CodexLedger = _new_ledger(ws, fw)
	var first: Dictionary = l.claim("tutorial_complete", 30, true)
	_ck("dup_first_ok", bool(first.get("ok")) and l.points == 30, "首次领取 +30")
	var second: Dictionary = l.claim("tutorial_complete", 30, true)
	_ck("dup_second_rejected", not bool(second.get("ok")), "同 id 二次领取被拒")
	_ck("dup_reason", str(second.get("reason")) == "duplicate", "reason=%s" % str(second.get("reason")))
	_ck("dup_points_unchanged", l.points == 30, "points 仍=30（不重复发奖）")
	var still: bool = true
	for _i: int in range(4):
		if bool(l.claim("tutorial_complete", 30, true).get("ok")):
			still = false
	_ck("dup_4x_still_rejected", still, "连领 4 次仍全部拒绝")
	_ck("dup_points_still_30", l.points == 30, "points 恒=30（幂等）")
	_ck("dup_commit_count_1", fw.commits.size() == 1, "仅 1 次成功 → commit=1（失败不落盘）")
	_ck("dup_is_claimed_true", l.is_claimed("tutorial_complete"), "is_claimed=true")
	var not_met: Dictionary = l.claim("best_wave_3", 120, false)
	_ck("dup_condition_not_met_rejected", not bool(not_met.get("ok")) \
		and str(not_met.get("reason")) == "condition_not_met", "条件未达成拒绝")
	_ck("dup_condition_not_met_no_commit", fw.commits.size() == 1 \
		and not l.is_claimed("best_wave_3"), "未达成不置位、不落盘（commit 仍=1）")


## F) 余额非负：领取 / 消费 / 超额消费拒绝全程 balance>=0
func _test_balance_nonneg() -> void:
	var ws: Node = _make_world_state()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var l: CodexLedger = _new_ledger(ws, fw)
	var nonneg: bool = l.balance_now() >= 0
	var ok_all: bool = true
	for i: int in range(4):
		var r: Dictionary = l.claim(str(EXPECT_IDS[i]), int(EXPECT_REWARDS[i]), true)
		if not bool(r.get("ok")):
			ok_all = false
		if int(r.get("balance")) < 0:
			nonneg = false
	_ck("balance_initial_nonneg", nonneg, "初始 balance=0 >= 0")
	_ck("balance_4_claims_ok", ok_all, "四项领取全成功")
	_ck("balance_all_nonneg", nonneg and l.balance_now() >= 0,
		"全程 balance>=0（末值=%d）" % l.balance_now())
	_ck("balance_after_claims_280", l.balance_now() == 280 and l.points == 280,
		"points=%d spent=%d balance=%d" % [l.points, l.spent, l.balance_now()])
	var s1: Dictionary = l.spend(100)
	_ck("balance_spend_100_ok", bool(s1.get("ok")) and l.spent == 100 and l.balance_now() == 180,
		"spend(100) → balance=180")
	_ck("balance_helper_consistent", GraceUpgradeService.balance(l.points, l.spent) == l.balance_now(),
		"GraceUpgradeService.balance 与夹具一致")
	var s2: Dictionary = l.spend(1000)
	_ck("balance_overspend_rejected", not bool(s2.get("ok")) and l.spent == 100,
		"spend(1000) 超余额被拒，spent 不变=100")
	_ck("balance_after_overspend_nonneg", l.balance_now() == 180, "超支后 balance 仍=180 >= 0")


## G) grace.trial.points 只增不减：内存 WorldState 逐次读回，序列非递减、无 removals
func _test_points_monotonic() -> void:
	var ws: Node = _make_world_state()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var l: CodexLedger = _new_ledger(ws, fw)
	var seq: Array[int] = []
	seq.append(int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)))
	for i: int in range(4):
		l.claim(str(EXPECT_IDS[i]), int(EXPECT_REWARDS[i]), true)
		seq.append(int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)))
	# 失败操作（重复 / 条件未达成 / 超支）不得改变 points。
	l.claim("tutorial_complete", 30, true)
	l.claim("best_wave_3", 120, false)
	l.spend(100)
	seq.append(int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)))
	_ck("points_readback_equals_ledger", int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)) == l.points,
		"WorldState 读回=%d 夹具=%d" % [int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)), l.points])
	var nondec: bool = true
	for i: int in range(1, seq.size()):
		if seq[i] < seq[i - 1]:
			nondec = false
	_ck("points_sequence_nondecreasing", nondec, "序列=%s（只增不减）" % str(seq))
	_ck("points_final_280", seq[seq.size() - 1] == 280, "终值=280（30+50+80+120）")
	_ck("points_failed_ops_unchanged", seq[4] == seq[5], "失败操作后 points 不变")
	_ck("points_spent_only_increases", l.spent == 100 and l.balance_now() == 180,
		"spent 只增到 100，余额=180")
	var delta_v: Variant = ws.get("_delta")
	var removals: Array = []
	if typeof(delta_v) == TYPE_DICTIONARY:
		removals = (delta_v as Dictionary).get("removals", []) as Array
	_ck("points_no_removals", removals.is_empty(), "_delta.removals size=%d（绝不 removals）" % removals.size())
	_ck("points_key_three_segment", GraceUpgradeService.FLAG_POINTS == "grace.trial.points",
		"key=%s" % GraceUpgradeService.FLAG_POINTS)


## H) commit 先落盘：stage_flags < disk_write < runtime_update；失败不 commit；reason 正确
func _test_commit_before_disk() -> void:
	var ws: Node = _make_world_state()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var l: CodexLedger = _new_ledger(ws, fw)
	var r: Dictionary = l.claim("tutorial_complete", 30, true)
	_ck("commit_claim_ok", bool(r.get("ok")), "首次领取成功")
	var idx_stage: int = l.events.find("stage_flags:tutorial_complete")
	var idx_disk: int = l.events.find("disk_write:" + COMMIT_REASON)
	var idx_runtime: int = l.events.find("runtime_update:tutorial_complete")
	_ck("commit_stage_before_disk", idx_stage >= 0 and idx_disk >= 0 and idx_stage < idx_disk,
		"stage_flags@%d < disk_write@%d | events=%s" % [idx_stage, idx_disk, str(l.events)])
	_ck("commit_disk_before_runtime", idx_disk >= 0 and idx_runtime >= 0 and idx_disk < idx_runtime,
		"disk_write@%d < runtime_update@%d（commit 先落盘再改运行时实例）" % [idx_disk, idx_runtime])
	_ck("commit_writer_count_1", fw.commits.size() == 1, "commit 次数=1")
	_ck("commit_reason_ok", fw.commits.size() == 1 and fw.commits[0] == COMMIT_REASON,
		"reason=%s" % str(fw.commits))
	var n_before: int = l.events.size()
	l.claim("tutorial_complete", 30, true)
	l.claim("best_wave_3", 120, false)
	_ck("commit_failure_no_new_event", l.events.size() == n_before, "重复/条件未达成失败不新增落盘事件")
	_ck("commit_failure_no_new_commit", fw.commits.size() == 1, "失败不新增 commit")
	_ck("commit_flag_before_writer", int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)) == 30,
		"set_flag(grace.trial.points) 在 commit 前已入队，读回=30")
	# writer 缺失时如实登记降级，不谎报落盘；用独立 ws 实例，避免污染上面读回断言。
	var ws2: Node = _make_world_state()
	var l2: CodexLedger = _new_ledger(ws2, null)
	l2.claim("wave_trial_clear", 50, true)
	_ck("commit_writer_downgrade_honest", l2.events.has("disk_write_downgrade:wave_trial_clear"),
		"writer=null → 登记 disk_write_downgrade，不谎报落盘")
	_ck("commit_downgrade_flag_still_queued", int(ws2.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)) == 50,
		"降级路径 set_flag 仍先入队（读回=50），仅缺 commit，不谎报落盘")


## I) 异常输入拒绝：空 id / 0 或负奖励 / 非法条件 / 未知 kind / 非 Dictionary 行
func _test_invalid_inputs(cfg: CodexConfig) -> void:
	var ws: Node = _make_world_state()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var l: CodexLedger = _new_ledger(ws, fw)
	_ck("invalid_empty_id_rejected", not bool(l.claim("", 30, true).get("ok")), "空 id 拒绝")
	_ck("invalid_zero_reward_rejected", not bool(l.claim("x", 0, true).get("ok")), "0 奖励拒绝")
	_ck("invalid_negative_reward_rejected", not bool(l.claim("x", -5, true).get("ok")), "负奖励拒绝")
	_ck("invalid_no_points_written", l.points == 0 and fw.commits.size() == 0,
		"异常输入不写 points、不 commit")
	_ck("invalid_unknown_kind_rejected", not CodexConfig.is_condition_kind_known("string_equals"),
		"未知 condition_kind 不在白名单")
	_ck("invalid_shape_null_rejected", not CodexConfig.is_condition_shape_valid("bool_true", null),
		"condition_value=null 拒绝")
	_ck("invalid_shape_missing_flag_rejected", not CodexConfig.is_condition_shape_valid("bool_true", {}),
		"缺 flag 拒绝")
	_ck("invalid_shape_bad_key_rejected", not CodexConfig.is_condition_shape_valid(
		"bool_true", {"flag": "BAD.KEY"}), "非法 flag key 拒绝")
	_ck("invalid_shape_negative_threshold_rejected", not CodexConfig.is_condition_shape_valid(
		"int_at_least", {"flag": "dungeon.wave_trial.best_wave", "threshold": -1}), "负阈值拒绝")
	_ck("invalid_shape_empty_all_of_rejected", not CodexConfig.is_condition_shape_valid(
		"all_of", {"flags": []}), "空 all_of 拒绝")
	# 非法 condition_kind 的成就行被 is_entry_valid 拒绝（条件不可达/不可判定）。
	var bad_entry: CodexConfig.CodexEntry = cfg.entry_from_dict({
		"id": "phantom", "title": "幽灵", "description": "非法条件",
		"condition_kind": "string_equals",
		"condition_value": {"flag": "grace.tutorial.completed"},
		"reward_points": 30,
	})
	_ck("invalid_entry_unknown_kind", not cfg.is_entry_valid(bad_entry), "未知 kind 行判非法")
	var unreachable: CodexConfig.CodexEntry = cfg.entry_from_dict({
		"id": "phantom2", "title": "幽灵2", "description": "引用未登记 flag",
		"condition_kind": "bool_true",
		"condition_value": {"flag": "grace.never_written.flag"},
		"reward_points": 30,
	})
	_ck("invalid_entry_unreachable_flag", not cfg.is_entry_valid(unreachable),
		"引用未登记 flag（条件不可达）判非法")
	var zero_reward: CodexConfig.CodexEntry = cfg.entry_from_dict({
		"id": "phantom3", "title": "幽灵3", "description": "0 奖励",
		"condition_kind": "bool_true",
		"condition_value": {"flag": "grace.tutorial.completed"},
		"reward_points": 0,
	})
	_ck("invalid_entry_zero_reward", not cfg.is_entry_valid(zero_reward), "0 奖励行判非法")


func _finish() -> void:
	for n: Node in _temps:
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	print("[V080] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	print("[V080] RESULT=%s" % ("PASS" if _fail == 0 and _pass > 0 else "FAIL"))
	print("[V080] === SELFTEST END ===")
	quit(0 if _fail == 0 and _pass > 0 else 1)
