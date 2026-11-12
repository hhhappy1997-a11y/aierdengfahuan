extends SceneTree

## ===========================================================================
## R36 / v0.13.0 · 专注值 FP 与战技「规则表 + 纯逻辑 + 信号」自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_focus_v130.gd
## 覆盖（任务单 ①④）：正常 / 边界 / 异常三类输入 ——
##   正常：读表、5 字段 + arts(2×6) [PLACEHOLDER]、4 信号、spend_fp 成功与 payload、
##         FP 扣减、两战技各自效果、get_snapshot；
##   边界：FP 不足拒绝且不扣、冷却期拒绝、重复按键幂等、冷却推进就绪、赐福休息回满、
##         rest_refill=false 增量回复（含封顶）、FP 只减不增除休息、FP 非负/不超上限、reset；
##   异常：spend_fp(null / 负数 / 浮点 / 数组 / 空串 / 未知 id)、tick(null / 负 / 字符串 /
##         NaN / Inf)、config=null、set_config(null)、非法表（fp_max<=0 / NaN / 非法 policy /
##         空 arts / 重复 id / 负 fp_cost）、异常拒绝后正常流程仍成立；
##   A48① 生产订阅者静态证据（新信号生产运行时订阅者，不只在验证脚本里）。
## 输出逐条 PASS=true/false + SUMMARY + OVERALL=PASS/FAIL + RESULT=ALL_MATCH；失败 quit(1)。
## --script 模式纪律：不 add_child、不取 /root/... 绝对路径、不用 get_tree()；
##   用 Engine.get_main_loop() as SceneTree 取 root 做只读断言；读表 CACHE_MODE_IGNORE；
##   不写 user:// 存档、不碰渲染；时间由 tick(delta) 确定性驱动，不依赖真实引擎时钟。
## 期望值来自 focus_rules.tres 首版 [PLACEHOLDER]。调参只改表，同步本脚本 EXPECT_*。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const CONFIG_PATH: String = "res://data/combat/focus_rules.tres"
const DIRECTOR_PATH: String = "res://scripts/combat/wave_trial_director.gd"

## [PLACEHOLDER] R36 首版期望（校验基准，不写进数据表；待人工试玩校准）。
const EXPECT_FP_MAX: float = 100.0
const EXPECT_FP_REGEN_ON_REST: float = 40.0
const EXPECT_REST_REFILL: bool = true
const EXPECT_POLICY: String = "reject"
const EXPECT_ART_COUNT: int = 2

const EXPECT_PEBBLE_ID: String = "glintstone_pebble"
const EXPECT_PEBBLE_TITLE: String = "辉石魔砾"
const EXPECT_PEBBLE_FP_COST: float = 12.0
const EXPECT_PEBBLE_COOLDOWN: float = 0.6
const EXPECT_PEBBLE_DAMAGE: float = 18.0
const EXPECT_PEBBLE_POISE: float = 8.0

const EXPECT_LION_ID: String = "lion_slash"
const EXPECT_LION_TITLE: String = "狮子斩"
const EXPECT_LION_FP_COST: float = 35.0
const EXPECT_LION_COOLDOWN: float = 1.8
const EXPECT_LION_DAMAGE: float = 45.0
const EXPECT_LION_POISE: float = 40.0

var _pass: int = 0
var _fail: int = 0

## 信号计数 / payload（connect 后统计，每组开头 _reset_signals() 清零）。
var _sig_spent: int = 0
var _sig_rejected: int = 0
var _sig_restored: int = 0
var _sig_ready: int = 0
var _last_spent_payload: Array = []
var _last_reject_payload: Array = []
var _last_restored_payload: Array = []
var _last_ready_id: String = ""


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V130-FP] %s PASS=%s | %s" % [tag, str(ok), detail])


func _on_spent(art_id: String, fp_cost: float, damage: float,
		poise_damage: float, fp_remaining: float) -> void:
	_sig_spent += 1
	_last_spent_payload = [art_id, fp_cost, damage, poise_damage, fp_remaining]


func _on_rejected(art_id: String, reason: String) -> void:
	_sig_rejected += 1
	_last_reject_payload = [art_id, reason]


func _on_restored(fp_before: float, fp_after: float, policy: String) -> void:
	_sig_restored += 1
	_last_restored_payload = [fp_before, fp_after, policy]


func _on_ready(art_id: String) -> void:
	_sig_ready += 1
	_last_ready_id = art_id


func _reset_signals() -> void:
	_sig_spent = 0
	_sig_rejected = 0
	_sig_restored = 0
	_sig_ready = 0
	_last_spent_payload = []
	_last_reject_payload = []
	_last_restored_payload = []
	_last_ready_id = ""


## 构造并 connect 4 个公开信号（Object 级，不经场景树；验证脚本内订阅仅用于断言 payload）。
func _make(cfg: FocusConfig) -> FocusService:
	var s: FocusService = FocusService.new(cfg)
	s.connect("focus_spent", Callable(self, "_on_spent"))
	s.connect("focus_rejected", Callable(self, "_on_rejected"))
	s.connect("focus_restored", Callable(self, "_on_restored"))
	s.connect("focus_cooldown_ready", Callable(self, "_on_ready"))
	return s


## 复制规则表（用于构造 rest_refill=false / 非法表变体，不硬编码设计数值）。
func _clone_arts(cfg: FocusConfig) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d: Dictionary in cfg.arts:
		out.append(d.duplicate())
	return out


func _initialize() -> void:
	print("[V130-FP] === SELFTEST START ===")
	var ml: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = ml as SceneTree
	var root_node: Node = tree.root if tree != null else null
	_ck("scene_tree_root_via_main_loop", tree != null and root_node != null,
		"Engine.get_main_loop() as SceneTree -> root，不用 get_tree()/绝对路径")
	var cfg: FocusConfig = ResourceLoader.load(
		CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FocusConfig
	_ck("table_load_cache_ignore", cfg != null, "path=%s" % CONFIG_PATH)
	if cfg == null:
		_finish()
		return

	_test_ruleset(cfg)
	_test_normal(cfg)
	_test_boundary(cfg)
	_test_abnormal(cfg)
	_test_production_subscriber()
	_finish()


## A) 规则表 5 字段 + arts(2×6) [PLACEHOLDER] + 合法性 + 4 信号 + 降级基线 != 设计值
func _test_ruleset(cfg: FocusConfig) -> void:
	_ck("ruleset_valid", cfg.is_valid(), "FocusConfig.is_valid()=true")
	_ck("fp_max_ph", is_equal_approx(cfg.get_fp_max(), EXPECT_FP_MAX),
		"got=%.1f expect=%.1f [PLACEHOLDER]" % [cfg.get_fp_max(), EXPECT_FP_MAX])
	_ck("fp_regen_on_rest_ph", is_equal_approx(cfg.get_fp_regen_on_rest(), EXPECT_FP_REGEN_ON_REST),
		"got=%.1f expect=%.1f [PLACEHOLDER]" % [cfg.get_fp_regen_on_rest(), EXPECT_FP_REGEN_ON_REST])
	_ck("rest_refill_ph", cfg.get_rest_refill() == EXPECT_REST_REFILL,
		"got=%s expect=%s [PLACEHOLDER]" % [str(cfg.get_rest_refill()), str(EXPECT_REST_REFILL)])
	_ck("invalid_input_policy_ph", cfg.get_invalid_input_policy() == EXPECT_POLICY,
		"got=%s expect=%s [PLACEHOLDER]" % [cfg.get_invalid_input_policy(), EXPECT_POLICY])
	_ck("art_count_2", cfg.get_art_count() == EXPECT_ART_COUNT,
		"arts 恰 %d 个战技 [PLACEHOLDER]" % EXPECT_ART_COUNT)
	var ids: PackedStringArray = cfg.get_art_ids()
	_ck("art_ids_unique", ids.size() == 2 and ids[0] != ids[1],
		"art id 唯一：%s" % str(ids))
	var pebble: Dictionary = cfg.get_art_by_id(EXPECT_PEBBLE_ID)
	_ck("pebble_present", not pebble.is_empty(), "辉石魔砾按 id 可查")
	_ck("pebble_title", str(pebble.get("title", "")) == EXPECT_PEBBLE_TITLE,
		"title=%s [PLACEHOLDER]" % EXPECT_PEBBLE_TITLE)
	_ck("pebble_fp_cost_ph", is_equal_approx(float(pebble.get("fp_cost", -1.0)), EXPECT_PEBBLE_FP_COST),
		"fp_cost=%.1f [PLACEHOLDER] 低耗" % EXPECT_PEBBLE_FP_COST)
	_ck("pebble_cooldown_ph", is_equal_approx(float(pebble.get("cooldown_sec", -1.0)), EXPECT_PEBBLE_COOLDOWN),
		"cooldown_sec=%.1f [PLACEHOLDER]" % EXPECT_PEBBLE_COOLDOWN)
	_ck("pebble_damage_ph", is_equal_approx(float(pebble.get("damage", -1.0)), EXPECT_PEBBLE_DAMAGE),
		"damage=%.1f [PLACEHOLDER] 并入清波点数结算" % EXPECT_PEBBLE_DAMAGE)
	_ck("pebble_poise_ph", is_equal_approx(float(pebble.get("poise_damage", -1.0)), EXPECT_PEBBLE_POISE),
		"poise_damage=%.1f [PLACEHOLDER] 并入既有削韧" % EXPECT_PEBBLE_POISE)
	var lion: Dictionary = cfg.get_art_by_id(EXPECT_LION_ID)
	_ck("lion_present", not lion.is_empty(), "狮子斩按 id 可查")
	_ck("lion_title", str(lion.get("title", "")) == EXPECT_LION_TITLE,
		"title=%s [PLACEHOLDER]" % EXPECT_LION_TITLE)
	_ck("lion_fp_cost_ph", is_equal_approx(float(lion.get("fp_cost", -1.0)), EXPECT_LION_FP_COST),
		"fp_cost=%.1f [PLACEHOLDER] 高耗" % EXPECT_LION_FP_COST)
	_ck("lion_cooldown_ph", is_equal_approx(float(lion.get("cooldown_sec", -1.0)), EXPECT_LION_COOLDOWN),
		"cooldown_sec=%.1f [PLACEHOLDER]" % EXPECT_LION_COOLDOWN)
	_ck("lion_damage_ph", is_equal_approx(float(lion.get("damage", -1.0)), EXPECT_LION_DAMAGE),
		"damage=%.1f [PLACEHOLDER]" % EXPECT_LION_DAMAGE)
	_ck("lion_poise_ph", is_equal_approx(float(lion.get("poise_damage", -1.0)), EXPECT_LION_POISE),
		"poise_damage=%.1f [PLACEHOLDER] 高削韧" % EXPECT_LION_POISE)
	_ck("lion_higher_than_pebble", EXPECT_LION_FP_COST > EXPECT_PEBBLE_FP_COST \
		and EXPECT_LION_POISE > EXPECT_PEBBLE_POISE,
		"狮子斩 高耗高削韧 > 辉石魔砾 低耗远程（设计定位）")
	var s: FocusService = FocusService.new(cfg)
	_ck("signal_spent_exists", s.has_signal("focus_spent"),
		"signal focus_spent(art_id, fp_cost, damage, poise_damage, fp_remaining)")
	_ck("signal_rejected_exists", s.has_signal("focus_rejected"),
		"signal focus_rejected(art_id, reason)")
	_ck("signal_restored_exists", s.has_signal("focus_restored"),
		"signal focus_restored(fp_before, fp_after, policy)")
	_ck("signal_ready_exists", s.has_signal("focus_cooldown_ready"),
		"signal focus_cooldown_ready(art_id)")
	_ck("default_is_not_design_fp_max", not is_equal_approx(
		float(FocusConfig.DEFAULT_FP_MAX), cfg.get_fp_max()),
		"DEFAULT_FP_MAX != 表值（调参唯一入口在 .tres，代码基线不是设计数值）")
	_ck("default_is_not_design_regen", not is_equal_approx(
		float(FocusConfig.DEFAULT_FP_REGEN_ON_REST), cfg.get_fp_regen_on_rest()),
		"DEFAULT_FP_REGEN_ON_REST != 表值（同上）")


## B) 正常：初始满 FP → 施放成功 → payload / 信号 / 扣减 / 两战技 / snapshot
func _test_normal(cfg: FocusConfig) -> void:
	_reset_signals()
	var s: FocusService = _make(cfg)
	_ck("initial_fp_full", is_equal_approx(s.get_fp(), EXPECT_FP_MAX),
		"构造 / reset() 后 FP=fp_max=100")
	var r: Dictionary = s.spend_fp(EXPECT_PEBBLE_ID)
	_ck("spend_pebble_ok", bool(r.get("ok")) and str(r.get("reason")) == FocusService.REASON_OK,
		"spend_fp(辉石魔砾) -> ok")
	_ck("spend_fp_cost", is_equal_approx(float(r.get("fp_cost")), EXPECT_PEBBLE_FP_COST),
		"fp_cost=12.0 [PLACEHOLDER]")
	_ck("spend_damage", is_equal_approx(float(r.get("damage")), EXPECT_PEBBLE_DAMAGE),
		"damage=18.0 [PLACEHOLDER] 供并入清波点数结算")
	_ck("spend_poise", is_equal_approx(float(r.get("poise_damage")), EXPECT_PEBBLE_POISE),
		"poise_damage=8.0 [PLACEHOLDER] 供并入既有削韧")
	_ck("spend_fp_remaining", is_equal_approx(float(r.get("fp_remaining")), 88.0),
		"fp_remaining=100-12=88")
	_ck("spend_fp_deducted", is_equal_approx(s.get_fp(), 88.0) \
		and is_equal_approx(float(s.get_snapshot().get("fp_remaining")), 88.0),
		"FP 实际扣减并反映到 get_snapshot()")
	_ck("signal_spent_1", _sig_spent == 1 and _last_spent_payload.size() == 5 \
		and str(_last_spent_payload[0]) == EXPECT_PEBBLE_ID \
		and is_equal_approx(float(_last_spent_payload[1]), EXPECT_PEBBLE_FP_COST) \
		and is_equal_approx(float(_last_spent_payload[2]), EXPECT_PEBBLE_DAMAGE) \
		and is_equal_approx(float(_last_spent_payload[3]), EXPECT_PEBBLE_POISE) \
		and is_equal_approx(float(_last_spent_payload[4]), 88.0),
		"focus_spent 恰 1 次，payload=(id,12.0,18.0,8.0,88.0)")
	_ck("spend_count_1", s.get_spend_count() == 1 and int(r.get("spend_count")) == 1,
		"spend_count=1")
	_ck("cooldown_set", is_equal_approx(s.get_cooldown_remaining(EXPECT_PEBBLE_ID), EXPECT_PEBBLE_COOLDOWN),
		"冷却置 0.6s [PLACEHOLDER]")
	# 第二个战技（冷却独立，可同帧施放）
	var r2: Dictionary = s.spend_fp(EXPECT_LION_ID)
	_ck("spend_lion_ok", bool(r2.get("ok")) \
		and is_equal_approx(float(r2.get("fp_cost")), EXPECT_LION_FP_COST) \
		and is_equal_approx(float(r2.get("damage")), EXPECT_LION_DAMAGE) \
		and is_equal_approx(float(r2.get("poise_damage")), EXPECT_LION_POISE),
		"spend_fp(狮子斩) -> ok，payload=(35.0,45.0,40.0) [PLACEHOLDER]")
	_ck("spend_both_fp", is_equal_approx(s.get_fp(), 53.0),
		"两战技合计扣 12+35=47 -> FP=53")
	_ck("spend_count_2", s.get_spend_count() == 2 and _sig_spent == 2,
		"两次成功、focus_spent 恰 2 次")
	var snap: Dictionary = s.get_snapshot()
	_ck("snapshot_fields", snap.has("fp") and snap.has("fp_max") and snap.has("cooldowns") \
		and snap.has("spend_count") and snap.has("reject_count") and snap.has("restore_count") \
		and snap.has("art_ids") and snap.has("invalid_input_policy") and snap.has("config_present") \
		and snap.has("last_result"),
		"get_snapshot() 全状态快照字段齐全")
	_ck("snapshot_policy", str(snap.get("invalid_input_policy")) == EXPECT_POLICY,
		"get_snapshot().invalid_input_policy=reject")
	_ck("snapshot_art_ids", (snap.get("art_ids") as PackedStringArray).size() == 2,
		"get_snapshot().art_ids 含 2 个战技 id")
	_ck("last_result_fields", bool(s.get_last_result().get("ok")) \
		and is_equal_approx(float(s.get_last_result().get("damage")), EXPECT_LION_DAMAGE),
		"get_last_result()=最近一次成功结算副本")


## C) 边界：FP 不足 / 冷却 / 幂等 / 就绪 / 赐福休息 / 增量策略 / FP 单调 / reset
func _test_boundary(cfg: FocusConfig) -> void:
	# 冷却期拒绝 + 重复按键幂等
	_reset_signals()
	var s1: FocusService = _make(cfg)
	s1.spend_fp(EXPECT_PEBBLE_ID)
	var c1: Dictionary = s1.spend_fp(EXPECT_PEBBLE_ID)
	_ck("cooldown_reject", not bool(c1.get("ok")) \
		and str(c1.get("reason")) == FocusService.REASON_COOLDOWN,
		"成功后再次施放同战技 -> cooldown 拒绝（冷却期拒绝）")
	_ck("duplicate_key_idempotent", s1.get_spend_count() == 1 \
		and is_equal_approx(s1.get_fp(), 88.0) and int(c1.get("damage")) == 0,
		"重复按键幂等：不二次扣 FP / 不二次给效果 / spend_count 仍 1")
	_ck("reject_signal_1", _sig_rejected == 1 \
		and str(_last_reject_payload[1]) == FocusService.REASON_COOLDOWN,
		"focus_rejected(cooldown) 恰 1 次")
	# 冷却推进 -> focus_cooldown_ready 恰 1 次 -> 可再施放
	s1.tick(EXPECT_PEBBLE_COOLDOWN)
	_ck("cooldown_then_ready", _sig_ready == 1 and _last_ready_id == EXPECT_PEBBLE_ID,
		"tick(0.6) 冷却归零 -> focus_cooldown_ready 恰 1 次")
	_ck("cooldown_then_respend", bool(s1.spend_fp(EXPECT_PEBBLE_ID).get("ok")),
		"冷却归零后可再次施放同一战技")
	# FP 不足拒绝且不扣（连续施放魔砾，每次 tick 清冷却）
	_reset_signals()
	var s2: FocusService = _make(cfg)
	var ok_count: int = 0
	for i: int in range(9):
		if i > 0:
			s2.tick(EXPECT_PEBBLE_COOLDOWN)
		var rr: Dictionary = s2.spend_fp(EXPECT_PEBBLE_ID)
		if bool(rr.get("ok")):
			ok_count += 1
	_ck("fp_exhaust_8_spends", ok_count == 8 and is_equal_approx(s2.get_fp(), 4.0),
		"100/12 -> 连续 8 次成功、FP 余 4")
	var short: Dictionary = s2.tick(EXPECT_PEBBLE_COOLDOWN)
	_ck("tick_ok", bool(short.get("ok")), "tick 正常推进返回 ok")
	var r_short: Dictionary = s2.spend_fp(EXPECT_PEBBLE_ID)
	_ck("fp_insufficient_reject", not bool(r_short.get("ok")) \
		and str(r_short.get("reason")) == FocusService.REASON_INSUFFICIENT_FP,
		"第 9 次 FP=4 < fp_cost=12 -> insufficient_fp 拒绝")
	_ck("fp_insufficient_no_deduct", is_equal_approx(s2.get_fp(), 4.0) \
		and int(r_short.get("damage")) == 0 and s2.get_spend_count() == 8,
		"FP 不足拒绝且不扣 FP / 不给效果 / 不增 spend_count")
	# 赐福休息回满（rest_refill=true）
	_reset_signals()
	var s3: FocusService = _make(cfg)
	s3.spend_fp(EXPECT_PEBBLE_ID)
	s3.spend_fp(EXPECT_LION_ID)
	_ck("before_rest_fp_53", is_equal_approx(s3.get_fp(), 53.0), "休息前 FP=53")
	var rest: Dictionary = s3.on_grace_rest()
	_ck("grace_rest_refill", bool(rest.get("ok")) \
		and is_equal_approx(float(rest.get("fp_after")), EXPECT_FP_MAX) \
		and is_equal_approx(s3.get_fp(), EXPECT_FP_MAX),
		"on_grace_rest() -> 赐福休息回满 fp_max=100")
	_ck("grace_rest_policy", str(rest.get("policy")) == FocusService.REST_REFILL,
		"policy=rest_refill（表 rest_refill=true）")
	_ck("signal_restored_1", _sig_restored == 1 \
		and _last_restored_payload.size() == 3 \
		and is_equal_approx(float(_last_restored_payload[0]), 53.0) \
		and is_equal_approx(float(_last_restored_payload[1]), EXPECT_FP_MAX) \
		and str(_last_restored_payload[2]) == FocusService.REST_REFILL,
		"focus_restored(53.0, 100.0, rest_refill) 恰 1 次")
	_ck("grace_rest_clears_cooldown", is_equal_approx(s3.get_cooldown_remaining(EXPECT_LION_ID), 0.0),
		"赐福休息清全部战技冷却")
	_ck("restore_count_1", s3.get_restore_count() == 1, "restore_count=1")
	# rest_refill=false 增量回复（含封顶）
	var c2: FocusConfig = FocusConfig.new()
	c2.fp_max = EXPECT_FP_MAX
	c2.fp_regen_on_rest = EXPECT_FP_REGEN_ON_REST
	c2.rest_refill = false
	c2.invalid_input_policy = FocusConfig.POLICY_REJECT
	c2.arts = _clone_arts(cfg)
	_ck("regen_variant_valid", c2.is_valid(), "rest_refill=false 变体表合法")
	var s4: FocusService = _make(c2)
	s4.spend_fp(EXPECT_PEBBLE_ID)
	s4.spend_fp(EXPECT_LION_ID)
	var regen: Dictionary = s4.on_grace_rest()
	_ck("rest_regen_increment", bool(regen.get("ok")) \
		and str(regen.get("policy")) == FocusService.REST_REGEN \
		and is_equal_approx(float(regen.get("fp_after")), 93.0),
		"rest_refill=false -> 53+40=93 增量回复（未封顶）[PLACEHOLDER]")
	s4.spend_fp(EXPECT_PEBBLE_ID)
	s4.tick(EXPECT_PEBBLE_COOLDOWN)
	s4.spend_fp(EXPECT_PEBBLE_ID)
	var regen2: Dictionary = s4.on_grace_rest()
	_ck("rest_regen_capped", is_equal_approx(float(regen2.get("fp_after")), EXPECT_FP_MAX) \
		and float(regen2.get("fp_after")) <= EXPECT_FP_MAX,
		"增量回复封顶 fp_max=100（不超上限）")
	# FP 只减不增除休息：一局内连续施放序列单调不增、非负、不超上限
	_reset_signals()
	var s5: FocusService = _make(cfg)
	var seq: Array[float] = [s5.get_fp()]
	for step: int in range(5):
		s5.tick(2.0)   # 清所有冷却
		if step % 2 == 0:
			s5.spend_fp(EXPECT_PEBBLE_ID)
		else:
			s5.spend_fp(EXPECT_LION_ID)
		seq.append(s5.get_fp())
	var mono: bool = true
	for i: int in range(1, seq.size()):
		if float(seq[i]) > float(seq[i - 1]) or float(seq[i]) < 0.0 \
				or float(seq[i]) > EXPECT_FP_MAX:
			mono = false
	_ck("fp_only_decreases", mono,
		"FP 序列 %s 单调不增 / 非负 / 不超上限（除赐福休息外只减不增）" % str(seq))
	_ck("fp_never_negative_after_exhaust", is_equal_approx(s5.get_fp(), 6.0) \
		and s5.get_spend_count() == 4,
		"4 次成功(2×12+2×35=94)后 FP=6；第 5 次魔砾 cost=12>6 自动拒绝，FP 保持 6（非负、不透支）")
	# reset 清状态
	var s6: FocusService = _make(cfg)
	s6.spend_fp(EXPECT_PEBBLE_ID)
	s6.spend_fp(EXPECT_LION_ID)
	s6.on_grace_rest()
	s6.spend_fp("nope")
	s6.reset()
	_ck("reset_clears_all", is_equal_approx(s6.get_fp(), EXPECT_FP_MAX) \
		and s6.get_spend_count() == 0 and s6.get_reject_count() == 0 \
		and s6.get_restore_count() == 0 \
		and is_equal_approx(s6.get_cooldown_remaining(EXPECT_PEBBLE_ID), 0.0) \
		and s6.get_last_result().is_empty() and s6.get_last_reject_reason() == "",
		"reset() -> FP 回满 / 清冷却 / 清三类计数 / 清最近结果")


## D) 异常：spend_fp 异常 id / 负数 / null；tick 异常 delta；config=null；非法表；异常后正常
func _test_abnormal(cfg: FocusConfig) -> void:
	_reset_signals()
	var s1: FocusService = _make(cfg)
	var base: float = s1.get_fp()
	_ck("invalid_art_null", not bool(s1.spend_fp(null).get("ok")) \
		and str(s1.spend_fp(null).get("reason")) == FocusService.REASON_INVALID_ART,
		"spend_fp(null) -> invalid_art 拒绝")
	_ck("invalid_art_unknown_id", not bool(s1.spend_fp("nope").get("ok")) \
		and str(s1.spend_fp("nope").get("reason")) == FocusService.REASON_INVALID_ART,
		"spend_fp(未知 id) -> invalid_art 拒绝")
	_ck("invalid_art_empty", not bool(s1.spend_fp("").get("ok")) \
		and str(s1.spend_fp("").get("reason")) == FocusService.REASON_INVALID_ART,
		"spend_fp(空串) -> invalid_art 拒绝")
	_ck("invalid_art_negative", not bool(s1.spend_fp(-1).get("ok")) \
		and str(s1.spend_fp(-1).get("reason")) == FocusService.REASON_INVALID_ART,
		"spend_fp(负数 -1) -> invalid_art 拒绝")
	_ck("invalid_art_float", not bool(s1.spend_fp(1.5).get("ok")),
		"spend_fp(浮点 1.5) -> invalid_art 拒绝")
	_ck("invalid_art_array", not bool(s1.spend_fp([]).get("ok")),
		"spend_fp(数组) -> invalid_art 拒绝")
	_ck("invalid_art_state_unchanged", is_equal_approx(s1.get_fp(), base) \
		and s1.get_spend_count() == 0 and _sig_spent == 0,
		"异常 id 拒绝后 FP / spend_count / focus_spent 均未改（不隐式扣 FP）")
	_ck("reject_signal_payload", _sig_rejected >= 6 \
		and _last_reject_payload.size() == 2 \
		and str(_last_reject_payload[0]) == FocusService.ART_ID_NONE \
		and str(_last_reject_payload[1]) == FocusService.REASON_INVALID_ART,
		"focus_rejected payload=(<none>, invalid_art)，计数=%d" % _sig_rejected)
	_ck("reject_reason_recorded", s1.get_last_reject_reason() == FocusService.REASON_INVALID_ART,
		"get_last_reject_reason()=invalid_art")
	# tick 异常 delta
	_ck("invalid_tick_null", not bool(s1.tick(null).get("ok")) \
		and str(s1.tick(null).get("reason")) == FocusService.REASON_INVALID_DELTA,
		"tick(null) -> invalid_delta 拒绝")
	_ck("invalid_tick_negative", not bool(s1.tick(-1.0).get("ok")),
		"tick(-1) -> invalid_delta 拒绝")
	_ck("invalid_tick_string", not bool(s1.tick("x").get("ok")),
		"tick(字符串) -> invalid_delta 拒绝")
	_ck("invalid_tick_nan", not bool(s1.tick(NAN).get("ok")),
		"tick(NaN) -> invalid_delta 拒绝")
	_ck("invalid_tick_inf", not bool(s1.tick(INF).get("ok")),
		"tick(Inf) -> invalid_delta 拒绝")
	_ck("invalid_tick_state_unchanged", is_equal_approx(s1.get_fp(), base),
		"异常 delta 拒绝后 FP 状态未被污染")
	# config=null / set_config(null)
	var s2: FocusService = FocusService.new(null)
	_ck("no_config_spend_reject", not bool(s2.spend_fp(EXPECT_PEBBLE_ID).get("ok")) \
		and str(s2.spend_fp(EXPECT_PEBBLE_ID).get("reason")) == FocusService.REASON_NO_CONFIG,
		"config=null -> spend_fp 拒绝 REASON_NO_CONFIG（不崩）")
	var s3: FocusService = _make(cfg)
	s3.set_config(null)
	_ck("set_config_null_degrade", not bool(s3.spend_fp(EXPECT_PEBBLE_ID).get("ok")),
		"set_config(null) -> 降级拒绝（不崩）")
	# 非法表：逐项破坏（基于合法副本）
	var bad1: FocusConfig = _make_bad(cfg)
	bad1.fp_max = -1.0
	_ck("invalid_table_negative_fp_max", not bad1.is_valid(),
		"fp_max=-1 -> FocusConfig.is_valid()=false")
	var bad2: FocusConfig = _make_bad(cfg)
	bad2.fp_max = NAN
	_ck("invalid_table_nan_fp_max", not bad2.is_valid(),
		"fp_max=NaN -> is_valid()=false")
	var bad3: FocusConfig = _make_bad(cfg)
	bad3.invalid_input_policy = "clamp"
	_ck("invalid_table_bad_policy", not bad3.is_valid(),
		"invalid_input_policy=clamp（非 reject）-> is_valid()=false")
	var bad4: FocusConfig = _make_bad(cfg)
	var empty_arts: Array[Dictionary] = []
	bad4.arts = empty_arts
	_ck("invalid_table_empty_arts", not bad4.is_valid(),
		"arts 为空 -> is_valid()=false")
	var bad5: FocusConfig = _make_bad(cfg)
	var dup: Array[Dictionary] = _clone_arts(cfg)
	dup.append(dup[0].duplicate())
	bad5.arts = dup
	_ck("invalid_table_duplicate_id", not bad5.is_valid(),
		"art id 重复 -> is_valid()=false")
	var bad6: FocusConfig = _make_bad(cfg)
	var neg: Array[Dictionary] = _clone_arts(cfg)
	neg[0]["fp_cost"] = -1.0
	bad6.arts = neg
	_ck("invalid_table_negative_fp_cost", not bad6.is_valid(),
		"art fp_cost=-1 -> is_valid()=false")
	var sbad: FocusService = FocusService.new(bad1)
	_ck("invalid_table_service_degrade", not bool(sbad.spend_fp(EXPECT_PEBBLE_ID).get("ok")) \
		and str(sbad.spend_fp(EXPECT_PEBBLE_ID).get("reason")) == FocusService.REASON_NO_CONFIG,
		"非法表注入服务 -> REASON_NO_CONFIG 降级（不崩）")
	# 异常拒绝后正常流程仍成立
	_reset_signals()
	var s4: FocusService = _make(cfg)
	s4.tick(null)
	s4.tick(NAN)
	s4.spend_fp(null)
	s4.spend_fp(-1)
	var ok4: Dictionary = s4.spend_fp(EXPECT_PEBBLE_ID)
	_ck("invalid_then_normal_ok", bool(ok4.get("ok")) \
		and is_equal_approx(float(ok4.get("damage")), EXPECT_PEBBLE_DAMAGE) \
		and s4.get_spend_count() == 1 and is_equal_approx(s4.get_fp(), 88.0),
		"异常输入拒绝后正常施放仍得 damage=18.0（状态未被污染）")


## 构造一份「合法表副本」，供逐项破坏验证 is_valid()。
func _make_bad(cfg: FocusConfig) -> FocusConfig:
	var c: FocusConfig = FocusConfig.new()
	c.fp_max = EXPECT_FP_MAX
	c.fp_regen_on_rest = EXPECT_FP_REGEN_ON_REST
	c.rest_refill = EXPECT_REST_REFILL
	c.invalid_input_policy = FocusConfig.POLICY_REJECT
	c.arts = _clone_arts(cfg)
	return c


## E) A48① 生产订阅者静态存在性证据（新信号生产运行时订阅者，不只在验证脚本里）
func _test_production_subscriber() -> void:
	var abs_path: String = ProjectSettings.globalize_path(DIRECTOR_PATH)
	var src: String = FileAccess.get_file_as_string(abs_path)
	if src.is_empty():
		src = FileAccess.get_file_as_string(DIRECTOR_PATH)
	_ck("production_subscriber_in_source", src.contains("_bind_focus_signals") \
		and src.contains("get_focus_service") and src.contains("focus_spent") \
		and src.contains("focus_cooldown_ready") \
		and src.contains("base_for_combo + _focus_points_acc"),
		"wave_trial_director.gd 生产源码含 4 信号 connect + get_focus_service() + 战技并入结算（A48①/A54/A57）")


func _finish() -> void:
	print("[V130-FP] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V130-FP] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V130-FP] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V130-FP] === SELFTEST END ===")
	quit(0 if all_ok else 1)
