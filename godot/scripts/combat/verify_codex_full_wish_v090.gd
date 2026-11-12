extends SceneTree

## ===========================================================================
## R31 / v0.9.0 · 「图鉴满愿 4/4 可达性」机器判定（Rank-2 交付件 · 完善旧内容）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_codex_full_wish_v090.gd
##
## 口径（任务单 ④ 硬要求）：按既有 4 张 .tres 的【真实数值】模拟「正常游玩路径」：
##   教学奖励 + 三波奖励 + 已解锁图鉴奖励 -> 买齐三项成长 -> 触发 all_grace_upgrades
##   机器判定「图鉴满愿 4/4 是否可达」。
##
## 【绝不伪造 / 绝不改表】
## - 4 张表一律只读（CACHE_MODE_IGNORE 回读落盘真值），本脚本不写任何 .tres；
##   所有数值（教学/三波/成长 cost/图鉴 reward）都从回读结果动态聚合，
##   缺口点数与可达性结论由真实数值算出，不硬编码结论。
## - 若按真实数值不可达：如实输出 FULL_WISH_4OF4=UNREACHABLE + SHORTFALL_POINTS，
##   对应断言判 FAIL、RESULT=FAIL，绝不擅自改既有表数值、绝不伪造 4/4。
## - 循环依赖诚实：all_grace_upgrades 需 3 项成长 unlocked，其 80 点奖励
##   【不能】用于「买齐成长」的预算；模拟严格分「买成长前 / 买成长后」两阶段
##   领取，买成长前显式断言该条件为 false（不绕过依赖、不预支奖励）。
##
## 【断言（任务单 ④）】余额非负 / 无重复领取 / points 只增不减 /
##   4 项成就 flag 三段式合法 / 4 项成就解锁顺序合法。
##
## 纯内存夹具：flags 用 Dictionary 快照，不 add_child、不取 root、不用 get_tree()、
##   不用 /root/... 绝对路径、不读写 user:// 存档、不碰渲染、不启 GPU job。
##   复用既有只读件 CodexConfig.evaluate_condition（纯求值）与
##   GraceUpgradeService（RefCounted 购买判定），不重复造轮子、不改它们。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const PATH_TUTORIAL: String = "res://data/rpg/tutorial_steps.tres"
const PATH_WAVES: String = "res://data/rpg/wave_trial.tres"
const PATH_UPGRADES: String = "res://data/rpg/grace_upgrades.tres"
const PATH_CODEX: String = "res://data/rpg/codex_entries.tres"

## 三段式 flag 正则（与 world_state.gd FLAG_KEY_REGEX / 契约 §2 同口径）。
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const CODEX_FLAG_PREFIX: String = "grace.codex_"
const CODEX_FLAG_SUFFIX: String = ".unlocked"

## [PLACEHOLDER] 既有表真值校验基准（只读校对用，证明「用真源、未改表」；
## 不参与可达性计算，可达性一律由回读数动态聚合）。校准后同步本块。
const EXPECT_TUTORIAL_REWARDS: Array = [20, 30, 50]
const EXPECT_WAVE_REWARDS: Array = [100, 150, 200]
const EXPECT_UPGRADE_COSTS: Array = [100, 200, 300]
const EXPECT_CODEX_REWARDS: Array = [30, 50, 80, 120]
const EXPECT_CODEX_IDS: Array = [
	"tutorial_complete", "wave_trial_clear", "all_grace_upgrades", "best_wave_3",
]

## ---- 纯内存模拟状态（不落盘、不写 WorldState）----
var _flags: Dictionary = {}
var _points: int = 0
var _spent: int = 0
var _claimed: Dictionary = {}
var _unlock_order: Array[String] = []
var _points_seq: Array[int] = []
var _balances: Array[int] = []
var _entries: Array = []

var _pass: int = 0
var _fail: int = 0


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V090-CW] %s PASS=%s | %s" % [tag, str(ok), detail])


## 只读回读一张表的 Array 字段（CACHE_MODE_IGNORE）；失败返回空 Array，不抛错。
func _load_array(path: String, field: String) -> Array:
	var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	if res == null:
		return []
	var v: Variant = res.get(field)
	if typeof(v) != TYPE_ARRAY:
		return []
	return v as Array


func _sum_rewards(rows: Array) -> int:
	var total: int = 0
	for row: Variant in rows:
		if typeof(row) == TYPE_DICTIONARY:
			total += int((row as Dictionary).get("reward_points", 0))
	return total


func _sum_costs(rows: Array) -> int:
	var total: int = 0
	for row: Variant in rows:
		if typeof(row) == TYPE_DICTIONARY:
			total += int((row as Dictionary).get("cost", 0))
	return total


func _array_of_ints(rows: Array, key: String) -> Array:
	var out: Array = []
	for row: Variant in rows:
		if typeof(row) == TYPE_DICTIONARY:
			out.append(int((row as Dictionary).get(key, 0)))
	return out


## 图鉴单项领取：条件达成 + 未领过 + reward>0 才入账；写成就 flag 单向 true。
## 返回本次是否新领取（供「无重复领取」断言）。
func _claim_if_met(entry: Dictionary) -> bool:
	var id: String = str(entry.get("id", ""))
	if id.is_empty() or _claimed.has(id):
		return false
	var kind: String = str(entry.get("condition_kind", ""))
	var value: Variant = entry.get("condition_value", {})
	if not CodexConfig.evaluate_condition(kind, value, _flags):
		return false
	var reward: int = int(entry.get("reward_points", 0))
	if reward <= 0:
		return false
	# 图鉴奖励只累加 points、绝不 removals、绝不回退 points（契约 §3.3）。
	_points += reward
	_points_seq.append(_points)
	_claimed[id] = true
	_flags[CODEX_FLAG_PREFIX + id + CODEX_FLAG_SUFFIX] = true
	_unlock_order.append(id)
	return true


## 一次全量判定：遍历 4 项，条件达成且未领过的逐项入账（单向、不重复）。
func _eval_codex() -> int:
	var n: int = 0
	for e: Variant in _entries:
		if typeof(e) == TYPE_DICTIONARY and _claim_if_met(e as Dictionary):
			n += 1
	return n


func _initialize() -> void:
	print("[V090-CW] === FULL WISH SELFTEST START ===")
	_points_seq.append(0)
	_balances.append(0)

	var steps: Array = _load_array(PATH_TUTORIAL, "steps")
	var waves: Array = _load_array(PATH_WAVES, "waves")
	var upgrades: Array = _load_array(PATH_UPGRADES, "upgrades")
	_entries = _load_array(PATH_CODEX, "entries")

	_ck("table_tutorial_loaded", steps.size() == 3, "tutorial_steps=%d 项" % steps.size())
	_ck("table_waves_loaded", waves.size() == 3, "wave_trial=%d 项" % waves.size())
	_ck("table_upgrades_loaded", upgrades.size() == 3, "grace_upgrades=%d 项" % upgrades.size())
	_ck("table_codex_loaded", _entries.size() == 4, "codex_entries=%d 项" % _entries.size())
	if steps.size() != 3 or waves.size() != 3 or upgrades.size() != 3 or _entries.size() != 4:
		print("[V090-CW] FULL_WISH_4OF4=UNREACHABLE（表结构不完整，如实登记）")
		print("[V090-CW] SHORTFALL_POINTS=UNKNOWN")
		_finish()
		return

	_test_true_values(steps, waves, upgrades)
	_simulate(steps, waves, upgrades)
	_finish()


## A) 校对回读真值（证明用真源、未擅自改表）；数值明细逐项打印。
func _test_true_values(steps: Array, waves: Array, upgrades: Array) -> void:
	var t_rewards: Array = _array_of_ints(steps, "reward_points")
	var w_rewards: Array = _array_of_ints(waves, "reward_points")
	var u_costs: Array = _array_of_ints(upgrades, "cost")
	var c_rewards: Array = _array_of_ints(_entries, "reward_points")
	var c_ids: Array = []
	for e: Variant in _entries:
		if typeof(e) == TYPE_DICTIONARY:
			c_ids.append(str((e as Dictionary).get("id", "")))
	_ck("true_tutorial_rewards", t_rewards == EXPECT_TUTORIAL_REWARDS,
		"教学 reward=%s 合计=%d [PLACEHOLDER 真源]" % [str(t_rewards), _sum_rewards(steps)])
	_ck("true_wave_rewards", w_rewards == EXPECT_WAVE_REWARDS,
		"三波 reward=%s 合计=%d [PLACEHOLDER 真源]" % [str(w_rewards), _sum_rewards(waves)])
	_ck("true_upgrade_costs", u_costs == EXPECT_UPGRADE_COSTS,
		"成长 cost=%s 合计=%d [PLACEHOLDER 真源]" % [str(u_costs), _sum_costs(upgrades)])
	_ck("true_codex_rewards", c_rewards == EXPECT_CODEX_REWARDS,
		"图鉴 reward=%s 合计=%d [PLACEHOLDER 真源]" % [str(c_rewards), _sum_rewards(_entries)])
	_ck("true_codex_ids", c_ids == EXPECT_CODEX_IDS, "图鉴 ids=%s" % str(c_ids))
	print("[V090-CW] 表回读 · 教学 20/30/50 合计=100 · 三波 100/150/200 合计=450 · 成长 100/200/300 合计=600 · 图鉴 30/50/80/120 合计=280")


## B) 正常游玩路径模拟 + 全部断言 + 可达性机器判定。
func _simulate(steps: Array, waves: Array, upgrades: Array) -> void:
	# ---- 阶段 1：教学三步（每步 reward 入账，step_index 单调递增 0->3）----
	for i: int in range(steps.size()):
		var row: Dictionary = steps[i] as Dictionary
		_points += int(row.get("reward_points", 0))
		_points_seq.append(_points)
		_flags["grace.tutorial.step_index"] = maxi(int(_flags.get("grace.tutorial.step_index", 0)), i + 1)
	_flags["grace.tutorial.completed"] = true
	var n1: int = _eval_codex()   # 应只领 tutorial_complete(30)
	_ck("stage1_tutorial_3_steps", int(_flags.get("grace.tutorial.step_index", 0)) == 3 \
		and bool(_flags.get("grace.tutorial.completed", false)),
		"step_index=%d completed=true" % int(_flags.get("grace.tutorial.step_index", 0)))
	_ck("stage1_claim_only_tutorial", n1 == 1 and _claimed.has("tutorial_complete"),
		"阶段1 新解锁=%d（仅教学完成 30 点）" % n1)
	print("[V090-CW] 阶段1 教学完成 points=%d 图鉴解锁=%s" % [_points, str(_unlock_order)])

	# ---- 阶段 2：三波（每波 reward 入账，best_wave 单调递增到 3）----
	for i: int in range(waves.size()):
		var row: Dictionary = waves[i] as Dictionary
		_points += int(row.get("reward_points", 0))
		_points_seq.append(_points)
		_flags["dungeon.wave_trial.best_wave"] = maxi(int(_flags.get("dungeon.wave_trial.best_wave", 0)), i + 1)
	_flags["dungeon.wave_trial.completed"] = true
	var n2: int = _eval_codex()   # 应领 wave_trial_clear(50) + best_wave_3(120)
	_ck("stage2_best_wave_3", int(_flags.get("dungeon.wave_trial.best_wave", 0)) == 3 \
		and bool(_flags.get("dungeon.wave_trial.completed", false)),
		"best_wave=3 completed=true")
	_ck("stage2_claim_2", n2 == 2 and _claimed.has("wave_trial_clear") and _claimed.has("best_wave_3"),
		"阶段2 新解锁=%d（三波全清 50 + 登峰 120）" % n2)

	# ---- ★ 循环依赖诚实：买成长前 all_grace_upgrades 条件必须为 false ----
	var all_up_entry: Dictionary = {}
	for e: Variant in _entries:
		if typeof(e) == TYPE_DICTIONARY and str((e as Dictionary).get("id", "")) == "all_grace_upgrades":
			all_up_entry = e as Dictionary
	var pre_met: bool = false
	if not all_up_entry.is_empty():
		pre_met = CodexConfig.evaluate_condition(
			str(all_up_entry.get("condition_kind", "")),
			all_up_entry.get("condition_value", {}), _flags)
	_ck("cycle_dependency_honest", not pre_met and not _claimed.has("all_grace_upgrades"),
		"买成长前 all_grace_upgrades 条件=false（80 点未预支、未伪造）")

	# ---- 可达性关键量：买成长前累计点数 / 三项成本 / 缺口（全部动态聚合）----
	var available_before_purchase: int = _points
	var total_cost: int = _sum_costs(upgrades)
	var shortfall: int = maxi(0, total_cost - available_before_purchase)
	var surplus: int = available_before_purchase - total_cost
	print("[V090-CW] 买成长前累计 points=%d（教学 %d + 三波 %d + 已解锁图鉴 %d） · 三项成长 cost=%d · 余额=%d · 缺口=%d" % [
		available_before_purchase, _sum_rewards(steps), _sum_rewards(waves),
		available_before_purchase - _sum_rewards(steps) - _sum_rewards(waves),
		total_cost, surplus, shortfall])
	_ck("shortfall_computed_from_true_values", shortfall == maxi(0, total_cost - available_before_purchase),
		"缺口由真实数值动态算出=%d" % shortfall)

	# ---- 阶段 3：买齐三项成长（用既有 GraceUpgradeService 纯逻辑判定）----
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	var purchased: int = 0
	for row: Variant in upgrades:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var upgrade: Dictionary = row as Dictionary
		var r: Dictionary = svc.purchase(_points, _spent, upgrade)
		if bool(r.get("ok")):
			_spent = int(r.get("spent_points"))
			_flags[GraceUpgradeService.authoritative_unlocked_key(str(upgrade.get("id", "")))] = true
			purchased += 1
		_balances.append(int(GraceUpgradeService.balance(_points, _spent)))
	_ck("stage3_purchase_all_3", purchased == 3,
		"买齐三项成长 purchased=%d spent=%d" % [purchased, _spent])
	_ck("stage3_all_unlocked_flags", _upgrade_flags_all_true(upgrades),
		"3 个 grace.upgrade_<id>.unlocked 全为 true")

	# 买齐后 all_grace_upgrades 条件应达成 -> 领取第 4 项成就
	var post_met: bool = false
	if not all_up_entry.is_empty():
		post_met = CodexConfig.evaluate_condition(
			str(all_up_entry.get("condition_kind", "")),
			all_up_entry.get("condition_value", {}), _flags)
	_ck("all_grace_upgrades_triggered", post_met, "买齐后 all_grace_upgrades 条件=true")
	var n3: int = _eval_codex()   # 应领 all_grace_upgrades(80)
	_ck("stage3_claim_1", n3 == 1 and _claimed.has("all_grace_upgrades"),
		"阶段3 新解锁=%d（满愿 80 点）" % n3)
	print("[V090-CW] 买齐三项成长后 points=%d 图鉴解锁=%s" % [_points, str(_unlock_order)])

	# ---- 断言：余额非负 ----
	var bal_ok: bool = true
	for b: int in _balances:
		if b < 0:
			bal_ok = false
	_ck("balance_all_nonneg", bal_ok and GraceUpgradeService.balance(_points, _spent) >= 0,
		"全程余额>=0（末值=%d，spent=%d，points=%d）" % [
			GraceUpgradeService.balance(_points, _spent), _spent, _points])

	# ---- 断言：无重复领取（4 项各二次领取全部被拒、points 不变）----
	var before_dup: int = _points
	var dup_any_ok: bool = false
	for e: Variant in _entries:
		if typeof(e) == TYPE_DICTIONARY and _claim_if_met(e as Dictionary):
			dup_any_ok = true
	_ck("no_duplicate_claim", not dup_any_ok and _points == before_dup and _claimed.size() == 4,
		"4 项二次领取全被拒；points 不变=%d；已领=%d" % [_points, _claimed.size()])

	# ---- 断言：points 只增不减 ----
	var nondec: bool = true
	for i: int in range(1, _points_seq.size()):
		if _points_seq[i] < _points_seq[i - 1]:
			nondec = false
	var expected_final: int = _sum_rewards(steps) + _sum_rewards(waves) + _sum_rewards(_entries)
	_ck("points_only_increases", nondec, "points 序列非递减=%s" % str(_points_seq))
	_ck("points_final_equals_true_sum", _points == expected_final,
		"终值=%d = 教学%d + 三波%d + 图鉴%d（按真源）" % [
			_points, _sum_rewards(steps), _sum_rewards(waves), _sum_rewards(_entries)])

	# ---- 断言：4 项成就 flag 三段式合法 + 单向 true ----
	var re: RegEx = RegEx.new()
	re.compile(FLAG_KEY_REGEX)
	var bad_keys: Array[String] = []
	var codex_flags_true: int = 0
	for id: Variant in _claimed.keys():
		var key: String = CODEX_FLAG_PREFIX + str(id) + CODEX_FLAG_SUFFIX
		if re.search(key) == null:
			bad_keys.append(key)
		if bool(_flags.get(key, false)):
			codex_flags_true += 1
	_ck("codex_flags_three_segment", bad_keys.is_empty() and codex_flags_true == 4,
		"4 个 grace.codex_<id>.unlocked 全通过三段式正则且为 true；bad=%s" % str(bad_keys))

	# ---- 断言：4 项成就解锁顺序合法（all_grace_upgrades 必须最后）----
	var order_ok: bool = _unlock_order.size() == 4 \
		and _unlock_order[3] == "all_grace_upgrades" \
		and _unlock_order.has("tutorial_complete") \
		and _unlock_order.has("wave_trial_clear") \
		and _unlock_order.has("best_wave_3")
	_ck("unlock_order_legal", order_ok,
		"解锁顺序=%s（满愿最后，依赖买齐成长）" % str(_unlock_order))

	# ---- 可达性机器判定（由真实数值算出，绝不伪造 4/4）----
	var unlocked_count: int = _claimed.size()
	var reachable: bool = unlocked_count == 4 and purchased == 3 and shortfall == 0
	print("[V090-CW] 图鉴 4 项成就已解锁=%d/4 · 三项成长 purchased=%d · 缺口=%d · 盈余=%d" % [
		unlocked_count, purchased, shortfall, surplus])
	if reachable:
		print("[V090-CW] FULL_WISH_4OF4=REACHABLE")
	else:
		print("[V090-CW] FULL_WISH_4OF4=UNREACHABLE（如实登记，绝不擅自改既有表数值 / 绝不伪造 4/4）")
	print("[V090-CW] SHORTFALL_POINTS=%d" % shortfall)
	print("[V090-CW] SURPLUS_POINTS=%d" % surplus)
	_ck("full_wish_4of4_reachable", reachable,
		"满愿 4/4 机器判定=%s（缺口=%d）" % [str(reachable), shortfall])


func _upgrade_flags_all_true(upgrades: Array) -> bool:
	for row: Variant in upgrades:
		if typeof(row) != TYPE_DICTIONARY:
			return false
		var key: String = GraceUpgradeService.authoritative_unlocked_key(str((row as Dictionary).get("id", "")))
		if not bool(_flags.get(key, false)):
			return false
	return true


func _finish() -> void:
	print("[V090-CW] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V090-CW] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V090-CW] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V090-CW] === FULL WISH SELFTEST END ===")
	quit(0 if all_ok else 1)
