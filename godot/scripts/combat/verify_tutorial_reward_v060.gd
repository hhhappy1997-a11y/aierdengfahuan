extends SceneTree

## ===========================================================================
## R28 / v0.6.0 · 教学三步「奖励发放」自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_tutorial_reward_v060.gd
## 覆盖（任务单 ②）：奖励单调 / 余额非负 / 重复领取拒绝 / 超时不重复发奖 /
##   grace.trial.points 只增不减 / commit 先落盘；另附「双写收敛」旁证（H 组）。
## 输出逐条 PASS=true/false + SUMMARY pass/fail + RESULT（ALL_MATCH / FAILED）；
## 失败 quit(1)，不伪造 PASS。
## 期望值来自任务单 ① 首版 [PLACEHOLDER]（20/30/50 / 15.0），校准后需同步
##   EXPECT_* 与 DONE-R28.md，不静默改数。
## 读表统一走 CACHE_MODE_IGNORE，校验落盘真值而非缓存。
## 纯内存夹具：WorldState 实例手动 new()（不 add_child、不写 user:// 盘），
##   FakeWriter 只记录 commit(reason) 时序，不污染生产存档。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const CONFIG_PATH: String = "res://data/rpg/tutorial_steps.tres"
const WORLD_STATE_SCRIPT_PATH: String = "res://scripts/rpg/world_state.gd"

const FIELD_KEYS: Array = ["step_id", "prompt", "expected_action", "reward_points", "timeout_sec"]

# [PLACEHOLDER] R28 首版期望（任务单 ①），校验基准，不写进数据表；待人工试玩校准。
const EXPECT_IDS: Array = ["step_01_light_attack", "step_02_roll", "step_03_interact"]
const EXPECT_ACTIONS: Array = ["J", "Space", "E"]
const EXPECT_REWARDS: Array = [20, 30, 50]
const EXPECT_TIMEOUT: float = 15.0
const EXPECT_TOTAL: int = 100

const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"

var _pass: int = 0
var _fail: int = 0
## 手动 new() 的 Node 临时实例统一登记，_finish() 退出前 free，避免 ObjectDB 泄漏告警。
var _temps: Array[Node] = []


func _track(n: Node) -> void:
	_temps.append(n)


## 显式注入的 SaveDeltaWriter 替身：只记录 commit(reason) 时序，不写 user:// 盘，
## 使 verify 可实证「先 set_flag 后 commit」链路而不污染存档。
class FakeWriter extends Node:
	var commits: Array[String] = []

	func commit(reason: String) -> void:
		commits.append(reason)


## 教学奖励发放夹具（纯内存，验证用，不改生产逻辑）：
##  - points 对应 grace.trial.points，只增不减；
##  - _claimed 已领取 step_id 集合（防重复领取）；
##  - claim() 严格「先 set_flag(grace.trial.points) 再 writer.commit()」；
##  - 超时 / 重复 / 非法奖励一律拒绝，不写 points、不置位、不 commit；
##  - spend() 只增 grace.trial.spent_points，超余额拒绝，保证余额恒非负。
class RewardLedger extends RefCounted:
	var points: int = 0
	var spent: int = 0
	var _claimed: Dictionary = {}
	var events: Array[String] = []
	var ws: Node = null
	var writer: Node = null
	var commit_reason: String = "tutorial_reward_claimed"

	func is_claimed(id: String) -> bool:
		return _claimed.has(id)

	func balance_now() -> int:
		return GraceUpgradeService.balance(points, spent)

	func claim(step_id: String, reward: int, within_timeout: bool) -> Dictionary:
		if not within_timeout:
			return {"ok": false, "reason": "timeout", "points": points, "spent": spent, "balance": balance_now()}
		if _claimed.has(step_id):
			return {"ok": false, "reason": "duplicate", "points": points, "spent": spent, "balance": balance_now()}
		if reward <= 0:
			return {"ok": false, "reason": "invalid_reward", "points": points, "spent": spent, "balance": balance_now()}
		var new_points: int = points + reward
		# ★ commit 先落盘：stage_flags（set_flag 入队）→ disk_write（writer.commit 原子写）。
		events.append("stage_flags:" + step_id)
		if ws != null and ws.has_method("set_flag"):
			ws.call("set_flag", GraceUpgradeService.FLAG_POINTS, new_points)
		points = new_points
		_claimed[step_id] = true
		if writer != null and writer.has_method("commit"):
			writer.call("commit", commit_reason)
			events.append("disk_write:" + commit_reason)
		else:
			events.append("disk_write_downgrade:" + step_id)
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
	print("[V060] %s PASS=%s | %s" % [tag, str(ok), detail])


func _make_world_state() -> Node:
	var ws_script: Script = load(WORLD_STATE_SCRIPT_PATH) as Script
	var ws: Node = Node.new()
	_track(ws)
	ws.set_script(ws_script)
	ws.call("_ready")
	return ws


func _new_ledger(ws: Node, writer: Node) -> RewardLedger:
	var l: RewardLedger = RewardLedger.new()
	l.ws = ws
	l.writer = writer
	return l


func _initialize() -> void:
	print("[V060] === SELFTEST START ===")
	var cfg: TutorialConfig = ResourceLoader.load(
		CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as TutorialConfig
	_ck("table_load_cache_ignore", cfg != null, "path=%s" % CONFIG_PATH)
	if cfg == null:
		_finish()
		return
	_test_structure(cfg)
	_test_reward_monotonic(cfg)
	_test_balance_nonneg()
	_test_duplicate_claim()
	_test_timeout_no_double_pay()
	_test_points_monotonic()
	_test_commit_before_disk()
	_test_doublewrite_convergence()
	_finish()


## A) 表结构 / 逐字段首版 [PLACEHOLDER] / 合法性 / 越界 / 空表降级
func _test_structure(cfg: TutorialConfig) -> void:
	_ck("step_count_3", cfg.step_count() == 3 and cfg.steps.size() == 3,
		"count=%d size=%d" % [cfg.step_count(), cfg.steps.size()])
	for i: int in range(3):
		var row: Dictionary = cfg.steps[i] as Dictionary
		var missing: Array[String] = []
		for k: String in FIELD_KEYS:
			if not row.has(k):
				missing.append(k)
		_ck("fields[%d]" % i, missing.is_empty(), "keys=%d missing=%s" % [row.size(), str(missing)])
		_ck("id[%d]" % i, str(row.get("step_id")) == str(EXPECT_IDS[i]),
			"got=%s expect=%s" % [str(row.get("step_id")), str(EXPECT_IDS[i])])
		_ck("action[%d]" % i, str(row.get("expected_action")) == str(EXPECT_ACTIONS[i]),
			"got=%s expect=%s" % [str(row.get("expected_action")), str(EXPECT_ACTIONS[i])])
		_ck("reward[%d]" % i, int(row.get("reward_points")) == int(EXPECT_REWARDS[i]),
			"got=%s expect=%s" % [str(row.get("reward_points")), str(EXPECT_REWARDS[i])])
		_ck("timeout[%d]" % i, float(row.get("timeout_sec")) == EXPECT_TIMEOUT,
			"got=%s expect=%s" % [str(row.get("timeout_sec")), str(EXPECT_TIMEOUT)])
		_ck("valid[%d]" % i, cfg.is_step_valid(cfg.get_step(i)), "is_step_valid=true")
	_ck("prompt_nonempty_3", (not str(cfg.steps[0].get("prompt", "")).is_empty()) \
		and (not str(cfg.steps[1].get("prompt", "")).is_empty()) \
		and (not str(cfg.steps[2].get("prompt", "")).is_empty()), "三步 prompt 均非空")
	_ck("actions_all_known", cfg.is_known_action("J") and cfg.is_known_action("Space") \
		and cfg.is_known_action("E") and not cfg.is_known_action("K"), "J/Space/E 命中白名单，K 拒绝")
	_ck("make_step_5_fields", cfg.make_step("x", "p", "J", 1, 1.0).size() == 5, "size=5")
	_ck("bounds_negative_rejected", cfg.get_step(-1) == null, "get_step(-1)=null")
	_ck("bounds_index3_rejected", cfg.get_step(3) == null, "get_step(3)=null")
	var empty: TutorialConfig = TutorialConfig.new()
	_ck("empty_count_0", empty.step_count() == 0, "count=0")
	_ck("empty_get_null", empty.get_step(0) == null, "空表 get_step(0)=null 不崩")
	_ck("empty_monotonic_false", not empty.is_reward_monotonic(), "空表非单调=false")
	var d0: TutorialConfig.TutorialStep = cfg.step_from_dict({})
	_ck("missing_all_defaults", d0.step_id == TutorialConfig.DEFAULT_STEP_ID \
		and d0.expected_action == TutorialConfig.DEFAULT_EXPECTED_ACTION \
		and d0.reward_points == TutorialConfig.DEFAULT_REWARD_POINTS \
		and d0.timeout_sec == TutorialConfig.DEFAULT_TIMEOUT_SEC,
		"缺字段全回落 [PLACEHOLDER] 基线")
	_ck("missing_all_invalid", not cfg.is_step_valid(d0), "空表降级视图判非法")


## B) 奖励单调：20<30<50、合计 100；非单调表被识别
func _test_reward_monotonic(cfg: TutorialConfig) -> void:
	var r: Array[int] = []
	for i: int in range(3):
		r.append(int(cfg.steps[i].get("reward_points", 0)))
	_ck("reward_monotonic_api", cfg.is_reward_monotonic(), "is_reward_monotonic=true")
	_ck("reward_20_30_50", r[0] == 20 and r[1] == 30 and r[2] == 50, "rewards=%s" % str(r))
	_ck("reward_strict_inc_1", r[0] < r[1], "20 < 30")
	_ck("reward_strict_inc_2", r[1] < r[2], "30 < 50")
	_ck("reward_total_100", cfg.total_reward_points() == EXPECT_TOTAL,
		"total=%d expect=%d" % [cfg.total_reward_points(), EXPECT_TOTAL])
	var bad: TutorialConfig = TutorialConfig.new()
	bad.steps.append(cfg.make_step("a", "p", "J", 30, 15.0))
	bad.steps.append(cfg.make_step("b", "p", "Space", 20, 15.0))
	bad.steps.append(cfg.make_step("c", "p", "E", 50, 15.0))
	_ck("reward_nonmonotonic_detected", not bad.is_reward_monotonic(), "30,20,50 → 非单调=false")


## C) 余额非负：领取 / 消费 / 超额消费拒绝全程 balance>=0
func _test_balance_nonneg() -> void:
	var ws: Node = _make_world_state()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var l: RewardLedger = _new_ledger(ws, fw)
	var nonneg: bool = l.balance_now() >= 0
	var ok_all: bool = true
	for i: int in range(3):
		var r: Dictionary = l.claim(str(EXPECT_IDS[i]), int(EXPECT_REWARDS[i]), true)
		if not bool(r.get("ok")):
			ok_all = false
		if int(r.get("balance")) < 0:
			nonneg = false
	_ck("balance_initial_nonneg", nonneg, "初始 balance=0 >= 0")
	_ck("balance_3_claims_ok", ok_all, "三步领取全成功")
	_ck("balance_all_nonneg", nonneg and l.balance_now() >= 0,
		"全程 balance>=0（末值=%d）" % l.balance_now())
	_ck("balance_after_claims_100", l.balance_now() == 100 and l.points == 100,
		"points=%d spent=%d balance=%d" % [l.points, l.spent, l.balance_now()])
	var s1: Dictionary = l.spend(30)
	_ck("balance_spend_30_ok", bool(s1.get("ok")) and l.spent == 30 and l.balance_now() == 70,
		"spend(30) → balance=70")
	_ck("balance_helper_consistent", GraceUpgradeService.balance(l.points, l.spent) == l.balance_now(),
		"GraceUpgradeService.balance 与夹具一致")
	var s2: Dictionary = l.spend(1000)
	_ck("balance_overspend_rejected", not bool(s2.get("ok")) and l.spent == 30,
		"spend(1000) 超余额被拒，spent 不变=30")
	_ck("balance_after_overspend_nonneg", l.balance_now() == 70, "超支后 balance 仍=70 >= 0")


## D) 重复领取拒绝：同 step 二次 / 连领多次 / 跨 load 仍拒绝，points 不变
func _test_duplicate_claim() -> void:
	var ws: Node = _make_world_state()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var l: RewardLedger = _new_ledger(ws, fw)
	var first: Dictionary = l.claim("step_01_light_attack", 20, true)
	_ck("dup_first_ok", bool(first.get("ok")) and l.points == 20, "首次领取 +20")
	var second: Dictionary = l.claim("step_01_light_attack", 20, true)
	_ck("dup_second_rejected", not bool(second.get("ok")), "同 step 二次领取被拒")
	_ck("dup_reason", str(second.get("reason")) == "duplicate", "reason=%s" % str(second.get("reason")))
	_ck("dup_points_unchanged", l.points == 20, "points 仍=20（不重复发奖）")
	var still: bool = true
	for _i: int in range(4):
		if bool(l.claim("step_01_light_attack", 20, true).get("ok")):
			still = false
	_ck("dup_4x_still_rejected", still, "连领 4 次仍全部拒绝")
	_ck("dup_points_still_20", l.points == 20, "points 恒=20（幂等）")
	_ck("dup_commit_count_1", fw.commits.size() == 1, "仅 1 次成功 → commit=1（失败不落盘）")
	_ck("dup_is_claimed_true", l.is_claimed("step_01_light_attack"), "is_claimed=true")
	# 跨「从 flag 恢复」的重复：load_state_from_flags 注入已领 id 后仍拒绝。
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	var flags: Dictionary = {GraceUpgradeService.authoritative_unlocked_key("step_01_light_attack"): true}
	svc.load_state_from_flags(flags, EXPECT_IDS, 0)
	_ck("dup_across_flags_rejected", svc.is_purchased("step_01_light_attack"),
		"flag 恢复后同 id 仍判已领（F1 防刷不破坏）")


## E) 超时不重复发奖：超时拒绝、不占名额、时限内可领一次且不重复
func _test_timeout_no_double_pay() -> void:
	var ws: Node = _make_world_state()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var l: RewardLedger = _new_ledger(ws, fw)
	var t0: Dictionary = l.claim("step_01_light_attack", 20, false)
	_ck("timeout_first_rejected", not bool(t0.get("ok")), "超时领取被拒")
	_ck("timeout_reason", str(t0.get("reason")) == "timeout", "reason=%s" % str(t0.get("reason")))
	_ck("timeout_points_unchanged", l.points == 0 and not l.is_claimed("step_01_light_attack"),
		"points=0、未置位（超时不占名额）")
	_ck("timeout_no_commit", fw.commits.size() == 0, "超时不落盘（commit=0）")
	var ok1: Dictionary = l.claim("step_01_light_attack", 20, true)
	_ck("timeout_then_claim_once_ok", bool(ok1.get("ok")) and l.points == 20,
		"超时后时限内重领成功一次 +20")
	var ok2: Dictionary = l.claim("step_01_light_attack", 20, true)
	_ck("timeout_then_claim_not_twice", not bool(ok2.get("ok")) and l.points == 20,
		"再领被拒，points 仍=20（不重复发奖）")
	var ok3: Dictionary = l.claim("step_01_light_attack", 20, false)
	_ck("timeout_after_claimed_rejected", not bool(ok3.get("ok")) and l.points == 20,
		"已领后超时尝试仍拒、不重复发奖")
	_ck("timeout_commit_count_1", fw.commits.size() == 1, "全程仅 1 次成功 → commit=1")


## F) grace.trial.points 只增不减：内存 WorldState 逐次读回，序列非递减、无 removals
func _test_points_monotonic() -> void:
	var ws: Node = _make_world_state()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var l: RewardLedger = _new_ledger(ws, fw)
	var seq: Array[int] = []
	seq.append(int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)))
	for i: int in range(3):
		l.claim(str(EXPECT_IDS[i]), int(EXPECT_REWARDS[i]), true)
		seq.append(int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)))
	# 失败操作（重复 / 超时 / 超支）不得改变 points。
	l.claim("step_01_light_attack", 20, true)
	l.claim("step_02_roll", 30, false)
	l.spend(30)
	seq.append(int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)))
	_ck("points_readback_equals_ledger", int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)) == l.points,
		"WorldState 读回=%d 夹具=%d" % [int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)), l.points])
	var nondec: bool = true
	for i: int in range(1, seq.size()):
		if seq[i] < seq[i - 1]:
			nondec = false
	_ck("points_sequence_nondecreasing", nondec, "序列=%s（只增不减）" % str(seq))
	_ck("points_final_100", seq[seq.size() - 1] == 100, "终值=100（20+30+50）")
	_ck("points_failed_ops_unchanged", seq[3] == seq[4], "失败操作后 points 不变")
	_ck("points_spent_only_increases", l.spent == 30 and l.balance_now() == 70,
		"spent 只增到 30，余额=70")
	var delta_v: Variant = ws.get("_delta")
	var removals: Array = []
	if typeof(delta_v) == TYPE_DICTIONARY:
		removals = (delta_v as Dictionary).get("removals", []) as Array
	_ck("points_no_removals", removals.is_empty(), "_delta.removals size=%d（绝不 removals）" % removals.size())
	_ck("points_key_three_segment", GraceUpgradeService.FLAG_POINTS == "grace.trial.points",
		"key=%s" % GraceUpgradeService.FLAG_POINTS)


## G) commit 先落盘：stage_flags 在 disk_write 之前；失败不 commit；reason 正确
func _test_commit_before_disk() -> void:
	var ws: Node = _make_world_state()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var l: RewardLedger = _new_ledger(ws, fw)
	var r: Dictionary = l.claim("step_01_light_attack", 20, true)
	_ck("commit_claim_ok", bool(r.get("ok")), "首次领取成功")
	var idx_stage: int = l.events.find("stage_flags:step_01_light_attack")
	var idx_disk: int = l.events.find("disk_write:tutorial_reward_claimed")
	_ck("commit_stage_before_disk", idx_stage >= 0 and idx_disk >= 0 and idx_stage < idx_disk,
		"stage_flags@%d < disk_write@%d | events=%s" % [idx_stage, idx_disk, str(l.events)])
	_ck("commit_writer_count_1", fw.commits.size() == 1, "commit 次数=1")
	_ck("commit_reason_ok", fw.commits.size() == 1 and fw.commits[0] == "tutorial_reward_claimed",
		"reason=%s" % str(fw.commits))
	# 失败操作不产生任何新事件 / 新 commit。
	var n_before: int = l.events.size()
	l.claim("step_01_light_attack", 20, true)
	l.claim("step_02_roll", 30, false)
	_ck("commit_failure_no_new_event", l.events.size() == n_before, "重复/超时失败不新增落盘事件")
	_ck("commit_failure_no_new_commit", fw.commits.size() == 1, "失败不新增 commit")
	_ck("commit_flag_before_writer", int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)) == 20,
		"set_flag(grace.trial.points) 在 commit 前已入队，读回=20")
	# writer 缺失时如实登记降级，不谎报落盘；用独立 ws 实例，避免污染上面读回断言。
	var ws2: Node = _make_world_state()
	var l2: RewardLedger = _new_ledger(ws2, null)
	l2.claim("step_02_roll", 30, true)
	_ck("commit_writer_downgrade_honest", l2.events.has("disk_write_downgrade:step_02_roll"),
		"writer=null → 登记 disk_write_downgrade，不谎报落盘")
	_ck("commit_downgrade_flag_still_queued", int(ws2.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)) == 30,
		"降级路径 set_flag 仍先入队（读回=30），仅缺 commit，不谎报落盘")


## H) 双写收敛旁证（任务单 ③）：unlocked 为唯一权威件、bought_ 仅兼容读取
func _test_doublewrite_convergence() -> void:
	var id: String = "hp_max_bonus"
	_ck("dw_authoritative_key", GraceUpgradeService.purchased_flag_key(id) == "grace.upgrade_hp_max_bonus.unlocked",
		"purchased_flag_key=%s" % GraceUpgradeService.purchased_flag_key(id))
	_ck("dw_purchased_equals_authoritative",
		GraceUpgradeService.purchased_flag_key(id) == GraceUpgradeService.authoritative_unlocked_key(id),
		"集中式入口 == 权威 key")
	_ck("dw_legacy_key", GraceUpgradeService.legacy_bought_flag_key(id) == "grace.trial.bought_hp_max_bonus",
		"legacy=%s（仅兼容读取）" % GraceUpgradeService.legacy_bought_flag_key(id))
	_ck("dw_read_authoritative", GraceUpgradeService.is_purchased_in_flags(
		{"grace.upgrade_hp_max_bonus.unlocked": true}, id), "unlocked=true → 已购")
	_ck("dw_read_legacy_save", GraceUpgradeService.is_purchased_in_flags(
		{"grace.trial.bought_hp_max_bonus": true}, id), "纯 bought_ 旧档 → 已购（既有存档可读）")
	_ck("dw_read_absent_false", not GraceUpgradeService.is_purchased_in_flags({}, id), "空 flags → 未购")
	_ck("dw_collect_legacy_id", str(GraceUpgradeService.collect_purchased_ids_from_flags(
		{"grace.trial.bought_b": true}, ["a", "b", "c"])) == "[\"b\"]",
		"从旧档收集已购 id=[b]")
	var re: RegEx = RegEx.new()
	re.compile(FLAG_KEY_REGEX)
	_ck("dw_keys_three_segment_regex",
		re.search(GraceUpgradeService.purchased_flag_key(id)) != null \
		and re.search(GraceUpgradeService.legacy_bought_flag_key(id)) != null,
		"权威 key / 兼容 key 均符合 WorldState 三段式正则")
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	svc.load_state_from_flags({"grace.trial.bought_hp_max_bonus": true}, [id], 0)
	_ck("dw_f1_not_broken", svc.is_purchased(id), "旧档经 load_state_from_flags 恢复后 F1 仍拒绝重复购买")


func _finish() -> void:
	for n: Node in _temps:
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	print("[V060] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	print("[V060] RESULT=%s" % ("ALL_MATCH" if _fail == 0 else "FAILED"))
	print("[V060] === SELFTEST END ===")
	quit(0 if _fail == 0 else 1)
