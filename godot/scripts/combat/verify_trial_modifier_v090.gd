extends SceneTree

## ===========================================================================
## R31 / v0.9.0 · 试炼词条「数据驱动 + 结算纯逻辑」自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_trial_modifier_v090.gd
## 覆盖（任务单 ③）：选择合法性 / 互斥组拒绝 / 未选回落基础 / 奖励单调不减 /
##   余额非负 / 异常输入拒绝 / 条件判定 / 3 词条 7 字段 [PLACEHOLDER] 数值。
## 输出逐条 PASS=true/false + SUMMARY pass/fail + RESULT（ALL_MATCH / FAIL）；
## 失败 quit(1)，不伪造 PASS。
## 纯内存夹具：只用 RefCounted 服务 + Resource 数据表，不 add_child、不取 root、
##   不用 get_tree()、不用 /root/... 绝对路径、不读写 user:// 存档、不碰渲染。
## 读表统一走 CACHE_MODE_IGNORE，校验落盘真值而非缓存。
## 期望值来自 .tres 首版 [PLACEHOLDER]（1.5/1.3/1.4、1.0/0.6/1.0、1.0/1.0/0.5），
##   校准后需同步 EXPECT_* 与 TRIAL-MODIFIER-TUNING.md / DONE-R31.md，不静默改数。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const CONFIG_PATH: String = "res://data/rpg/trial_modifiers.tres"

const FIELD_KEYS: Array = [
	"id", "title", "description", "reward_multiplier", "time_limit_scale",
	"hp_scale", "exclusive_group",
]

## [PLACEHOLDER] R31 首版期望（校验基准，不写进数据表；待人工试玩校准）。
const EXPECT_IDS: Array = ["no_hit", "time_pressure", "low_vigor"]
const EXPECT_MULT: Array = [1.5, 1.3, 1.4]
const EXPECT_TL_SCALE: Array = [1.0, 0.6, 1.0]
const EXPECT_HP_SCALE: Array = [1.0, 1.0, 0.5]
const EXPECT_GROUPS: Array = ["survival", "tempo", "survival"]

var _pass: int = 0
var _fail: int = 0


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V090-TM] %s PASS=%s | %s" % [tag, str(ok), detail])


## 每次新建 Dictionary，避免共享引用被意外改写。
func _stats(damage: int, elapsed: float, limit: float, hp: float) -> Dictionary:
	return {
		"damage_taken": damage,
		"elapsed_sec": elapsed,
		"time_limit_sec": limit,
		"hp_ratio": hp,
	}


func _initialize() -> void:
	print("[V090-TM] === SELFTEST START ===")
	var cfg: TrialModifierConfig = ResourceLoader.load(
		CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as TrialModifierConfig
	_ck("table_load_cache_ignore", cfg != null, "path=%s" % CONFIG_PATH)
	if cfg == null:
		_finish()
		return
	_test_structure(cfg)
	_test_select_legality(cfg)
	_test_exclusive_group(cfg)
	_test_no_modifier_baseline(cfg)
	_test_conditions(cfg)
	_test_monotonic_and_max(cfg)
	_test_balance_nonneg(cfg)
	_test_invalid_inputs(cfg)
	_finish()


## A) 表结构 / 3 项 7 字段 / 首版 [PLACEHOLDER] / 倍率集合 / 分组 / 越界 / 空表降级
func _test_structure(cfg: TrialModifierConfig) -> void:
	_ck("modifier_count_3", cfg.modifier_count() == 3 and cfg.modifiers.size() == 3,
		"count=%d size=%d" % [cfg.modifier_count(), cfg.modifiers.size()])
	for i: int in range(3):
		var row: Dictionary = cfg.modifiers[i] as Dictionary
		var missing: Array[String] = []
		for k: String in FIELD_KEYS:
			if not row.has(k):
				missing.append(k)
		_ck("fields[%d]" % i, missing.is_empty(),
			"keys=%d missing=%s" % [row.size(), str(missing)])
		var m: TrialModifierConfig.TrialModifier = cfg.get_modifier(i)
		_ck("id[%d]" % i, m != null and m.id == str(EXPECT_IDS[i]),
			"got=%s expect=%s" % [str(m.id if m != null else "<null>"), str(EXPECT_IDS[i])])
		_ck("title_desc_nonempty[%d]" % i,
			m != null and not m.title.is_empty() and not m.description.is_empty(),
			"title=%s" % str(m.title if m != null else "<null>"))
		_ck("mult[%d]" % i, m != null and is_equal_approx(m.reward_multiplier, float(EXPECT_MULT[i])),
			"got=%s expect=%s [PLACEHOLDER]" % [str(m.reward_multiplier if m != null else -1.0), str(EXPECT_MULT[i])])
		_ck("tl_scale[%d]" % i, m != null and is_equal_approx(m.time_limit_scale, float(EXPECT_TL_SCALE[i])),
			"got=%s expect=%s [PLACEHOLDER]" % [str(m.time_limit_scale if m != null else -1.0), str(EXPECT_TL_SCALE[i])])
		_ck("hp_scale[%d]" % i, m != null and is_equal_approx(m.hp_scale, float(EXPECT_HP_SCALE[i])),
			"got=%s expect=%s [PLACEHOLDER]" % [str(m.hp_scale if m != null else -1.0), str(EXPECT_HP_SCALE[i])])
		_ck("group[%d]" % i, m != null and m.exclusive_group == str(EXPECT_GROUPS[i]),
			"got=%s expect=%s" % [str(m.exclusive_group if m != null else "<null>"), str(EXPECT_GROUPS[i])])
		_ck("valid[%d]" % i, cfg.is_modifier_valid(m), "is_modifier_valid=true")
	# 倍率全部 >= 1.0（奖励单调不减的结构前提）+ 三档互异
	var all_ge_one: bool = true
	for i: int in range(3):
		var mm: TrialModifierConfig.TrialModifier = cfg.get_modifier(i)
		if mm == null or mm.reward_multiplier < 1.0:
			all_ge_one = false
	_ck("mult_all_ge_1", all_ge_one, "3 项倍率均 >= 1.0（只加成不扣减）")
	_ck("mult_set_valid", cfg.is_multiplier_set_valid(), "is_multiplier_set_valid=true（互异且 >=1）")
	# 分组视图：survival = no_hit + low_vigor，tempo = time_pressure
	var g: Dictionary = cfg.group_to_ids()
	var surv: Array = g.get("survival", []) as Array
	var tempo: Array = g.get("tempo", []) as Array
	_ck("group_survival_2", surv.size() == 2 and surv.has("no_hit") and surv.has("low_vigor"),
		"survival=%s" % str(surv))
	_ck("group_tempo_1", tempo.size() == 1 and tempo.has("time_pressure"),
		"tempo=%s" % str(tempo))
	# 白名单 / 越界 / 空表 / 字段缺失降级
	_ck("id_whitelist_3", TrialModifierConfig.KNOWN_IDS.size() == 3, "KNOWN_IDS=%s" % str(TrialModifierConfig.KNOWN_IDS))
	_ck("group_whitelist_2", TrialModifierConfig.KNOWN_GROUPS.size() == 2, "KNOWN_GROUPS=%s" % str(TrialModifierConfig.KNOWN_GROUPS))
	_ck("unknown_id_rejected", not TrialModifierConfig.is_id_known("phantom"), "phantom 不在白名单")
	_ck("unknown_group_rejected", not TrialModifierConfig.is_group_known("chaos"), "chaos 不在白名单")
	_ck("bounds_negative_null", cfg.get_modifier(-1) == null, "get_modifier(-1)=null")
	_ck("bounds_index3_null", cfg.get_modifier(3) == null, "get_modifier(3)=null")
	_ck("find_no_hit", cfg.find_modifier_by_id("no_hit") != null, "find_modifier_by_id(no_hit)!=null")
	_ck("find_unknown_null", cfg.find_modifier_by_id("phantom") == null, "find_modifier_by_id(phantom)=null")
	var empty: TrialModifierConfig = TrialModifierConfig.new()
	_ck("empty_count_0", empty.modifier_count() == 0, "count=0")
	_ck("empty_get_null", empty.get_modifier(0) == null, "空表 get_modifier(0)=null 不崩")
	_ck("empty_mult_set_invalid", not empty.is_multiplier_set_valid(), "空表倍率集合=false")
	var d0: TrialModifierConfig.TrialModifier = cfg.modifier_from_dict({})
	_ck("missing_all_defaults", d0.id == TrialModifierConfig.DEFAULT_ID \
		and d0.title == TrialModifierConfig.DEFAULT_TITLE \
		and d0.description == TrialModifierConfig.DEFAULT_DESCRIPTION \
		and is_equal_approx(d0.reward_multiplier, TrialModifierConfig.DEFAULT_REWARD_MULTIPLIER) \
		and is_equal_approx(d0.time_limit_scale, TrialModifierConfig.DEFAULT_TIME_LIMIT_SCALE) \
		and is_equal_approx(d0.hp_scale, TrialModifierConfig.DEFAULT_HP_SCALE) \
		and d0.exclusive_group == TrialModifierConfig.DEFAULT_EXCLUSIVE_GROUP,
		"缺字段全回落 [PLACEHOLDER] 基线")
	_ck("missing_all_invalid", not cfg.is_modifier_valid(d0), "空表降级视图判非法")
	_ck("make_modifier_7_fields", cfg.make_modifier("x", "t", "d", 1.1, 1.0, 1.0, "tempo").size() == 7,
		"size=7")


## B) select 合法性：合法 / 空 / 未知 / 重复 / config 缺失
func _test_select_legality(cfg: TrialModifierConfig) -> void:
	var svc: TrialModifierService = TrialModifierService.new(cfg)
	var r0: Dictionary = svc.select("no_hit")
	_ck("select_valid_ok", bool(r0.get("ok")) and str(r0.get("reason")) == TrialModifierService.REASON_OK,
		"select(no_hit) ok, reason=%s" % str(r0.get("reason")))
	_ck("select_ids_after_valid", svc.get_selected_ids() == (["no_hit"] as Array[String]),
		"selected=%s" % str(svc.get_selected_ids()))
	var r_empty: Dictionary = svc.select("")
	_ck("select_empty_id_rejected", not bool(r_empty.get("ok")) \
		and str(r_empty.get("reason")) == TrialModifierService.REASON_INVALID_ID,
		"空 id 拒绝，reason=%s" % str(r_empty.get("reason")))
	var r_unknown: Dictionary = svc.select("phantom")
	_ck("select_unknown_id_rejected", not bool(r_unknown.get("ok")) \
		and str(r_unknown.get("reason")) == TrialModifierService.REASON_UNKNOWN_ID,
		"未知 id 拒绝，reason=%s" % str(r_unknown.get("reason")))
	var r_dup: Dictionary = svc.select("no_hit")
	_ck("select_duplicate_rejected", not bool(r_dup.get("ok")) \
		and str(r_dup.get("reason")) == TrialModifierService.REASON_DUPLICATE,
		"重复 select 拒绝，reason=%s" % str(r_dup.get("reason")))
	_ck("select_reject_no_state_change", svc.get_selected_ids().size() == 1,
		"拒绝操作不改选择态，size=%d" % svc.get_selected_ids().size())
	var svc_null: TrialModifierService = TrialModifierService.new(null)
	var r_null: Dictionary = svc_null.select("no_hit")
	_ck("select_no_config_rejected", not bool(r_null.get("ok")) \
		and str(r_null.get("reason")) == TrialModifierService.REASON_NO_CONFIG,
		"config=null 拒绝，reason=%s" % str(r_null.get("reason")))


## C) 互斥组拒绝 + 跨组共存 + clear 后可重选
func _test_exclusive_group(cfg: TrialModifierConfig) -> void:
	var svc: TrialModifierService = TrialModifierService.new(cfg)
	svc.select("no_hit")
	var r_ex: Dictionary = svc.select("low_vigor")
	_ck("exclusive_same_group_rejected", not bool(r_ex.get("ok")) \
		and str(r_ex.get("reason")) == TrialModifierService.REASON_EXCLUSIVE,
		"no_hit + low_vigor 同 survival 组拒绝，reason=%s" % str(r_ex.get("reason")))
	_ck("exclusive_no_state_change", svc.get_selected_ids() == (["no_hit"] as Array[String]),
		"互斥拒绝后 selected=%s" % str(svc.get_selected_ids()))
	var r_cross: Dictionary = svc.select("time_pressure")
	_ck("exclusive_cross_group_ok", bool(r_cross.get("ok")),
		"no_hit + time_pressure 跨组共存成功")
	_ck("exclusive_selected_2", svc.get_selected_ids() == (["no_hit", "time_pressure"] as Array[String]),
		"selected=%s" % str(svc.get_selected_ids()))
	var r_tp_dup_group: Dictionary = svc.select("time_pressure")
	_ck("exclusive_tp_duplicate_rejected", not bool(r_tp_dup_group.get("ok")),
		"同 id 再选仍按 duplicate 拒绝")
	_ck("has_selection_true", svc.has_selection(), "has_selection=true")
	svc.clear()
	_ck("clear_empty", not svc.has_selection() and svc.get_selected_ids().is_empty(),
		"clear() 后选择态为空")
	var r_reselect: Dictionary = svc.select("low_vigor")
	_ck("clear_then_reselect_ok", bool(r_reselect.get("ok")) \
		and svc.get_selected_ids() == (["low_vigor"] as Array[String]),
		"clear 后可重选 low_vigor，selected=%s" % str(svc.get_selected_ids()))


## D) 未选词条回落基础结算
func _test_no_modifier_baseline(cfg: TrialModifierConfig) -> void:
	var svc: TrialModifierService = TrialModifierService.new(cfg)
	var r: Dictionary = svc.settle(100, _stats(0, 10.0, 30.0, 0.4))
	_ck("baseline_ok", bool(r.get("ok")), "ok=true")
	_ck("baseline_reason", str(r.get("reason")) == TrialModifierService.REASON_NO_MODIFIER,
		"reason=%s" % str(r.get("reason")))
	_ck("baseline_total_100", int(r.get("total_points")) == 100, "total=100（基础结算）")
	_ck("baseline_mult_1", is_equal_approx(float(r.get("reward_multiplier")), 1.0), "倍率=1.0")
	_ck("baseline_condition_false", not bool(r.get("condition_met")), "condition_met=false")
	_ck("baseline_bonus_0", int(r.get("bonus_points")) == 0, "bonus=0")
	_ck("baseline_balance_100", int(r.get("balance")) == 100, "balance=100")
	var r0: Dictionary = svc.settle(0, _stats(0, 10.0, 30.0, 0.4))
	_ck("baseline_base0", int(r0.get("total_points")) == 0 and int(r0.get("balance")) == 0,
		"base=0 -> total=0 balance=0（非负）")


## E) 条件判定（三种词条达成 / 未达成 / 缺字段 / 类型异常一律回落基础）
func _test_conditions(cfg: TrialModifierConfig) -> void:
	# no_hit：damage_taken<=0 达成
	var s1: TrialModifierService = TrialModifierService.new(cfg)
	s1.select("no_hit")
	var r_nh: Dictionary = s1.settle(100, _stats(0, 999.0, 30.0, 1.0))
	_ck("cond_no_hit_met", bool(r_nh.get("ok")) and int(r_nh.get("total_points")) == 150 \
		and bool(r_nh.get("condition_met")) and str(r_nh.get("modifier_id")) == "no_hit",
		"no_hit 达成 -> total=150 mult=1.5 id=%s" % str(r_nh.get("modifier_id")))
	var r_nh_fail: Dictionary = s1.settle(100, _stats(1, 999.0, 30.0, 1.0))
	_ck("cond_no_hit_not_met_baseline", int(r_nh_fail.get("total_points")) == 100 \
		and str(r_nh_fail.get("reason")) == TrialModifierService.REASON_CONDITION_NOT_MET,
		"受击一次 -> 回落基础 100，reason=%s" % str(r_nh_fail.get("reason")))
	# time_pressure：elapsed <= 30 * 0.6 = 18 达成
	var s2: TrialModifierService = TrialModifierService.new(cfg)
	s2.select("time_pressure")
	var r_tp: Dictionary = s2.settle(100, _stats(1, 10.0, 30.0, 1.0))
	_ck("cond_time_pressure_met", int(r_tp.get("total_points")) == 130 \
		and is_equal_approx(float(r_tp.get("reward_multiplier")), 1.3),
		"time_pressure 达成（10<=18）-> total=130 mult=1.3")
	var r_tp_fail: Dictionary = s2.settle(100, _stats(1, 25.0, 30.0, 1.0))
	_ck("cond_time_pressure_not_met", int(r_tp_fail.get("total_points")) == 100,
		"25>18 超时 -> 回落基础 100")
	# low_vigor：hp_ratio <= 0.5 达成
	var s3: TrialModifierService = TrialModifierService.new(cfg)
	s3.select("low_vigor")
	var r_lv: Dictionary = s3.settle(100, _stats(1, 999.0, 30.0, 0.4))
	_ck("cond_low_vigor_met", int(r_lv.get("total_points")) == 140 \
		and is_equal_approx(float(r_lv.get("reward_multiplier")), 1.4),
		"low_vigor 达成（0.4<=0.5）-> total=140 mult=1.4")
	var r_lv_fail: Dictionary = s3.settle(100, _stats(1, 999.0, 30.0, 0.9))
	_ck("cond_low_vigor_not_met", int(r_lv_fail.get("total_points")) == 100,
		"0.9>0.5 -> 回落基础 100")
	# stats 缺字段 / 类型异常 -> 回落基础，不崩
	var r_missing: Dictionary = s1.settle(100, {"elapsed_sec": 10.0, "time_limit_sec": 30.0})
	_ck("cond_missing_field_baseline", int(r_missing.get("total_points")) == 100,
		"缺 damage_taken -> 回落基础 100")
	var r_badtype: Dictionary = s2.settle(100, {"damage_taken": "bad", "elapsed_sec": "x", "time_limit_sec": 30.0})
	_ck("cond_bad_type_baseline", int(r_badtype.get("total_points")) == 100,
		"字段类型异常 -> 回落基础 100")


## F) 奖励单调不减 + 多词条生效倍率取 max（不叠乘，防奖励通胀）
func _test_monotonic_and_max(cfg: TrialModifierConfig) -> void:
	var svc: TrialModifierService = TrialModifierService.new(cfg)
	svc.select("no_hit")
	svc.select("time_pressure")  # 跨组共存，两项同时达成
	var r: Dictionary = svc.settle(100, _stats(0, 10.0, 30.0, 0.4))
	_ck("max_not_multiply", int(r.get("total_points")) == 150,
		"两项达成取 max(1.5,1.3)=1.5 -> total=150（非 1.5*1.3=195，不叠乘）")
	_ck("max_active_id_no_hit", str(r.get("modifier_id")) == "no_hit",
		"生效 id=%s（最高倍率者）" % str(r.get("modifier_id")))
	_ck("max_bonus_50", int(r.get("bonus_points")) == 50, "bonus=50")
	# 收集多种成功结算，统一验证 total>=base 且 bonus>=0（奖励单调不减）
	var results: Array[Dictionary] = []
	results.append(svc.settle(0, _stats(0, 10.0, 30.0, 0.4)))
	results.append(svc.settle(100, _stats(0, 10.0, 30.0, 0.4)))
	results.append(svc.settle(250, _stats(0, 10.0, 30.0, 0.4)))
	results.append(svc.settle(1000, _stats(0, 10.0, 30.0, 0.4)))
	var nondec_ok: bool = true
	var bonus_ok: bool = true
	for d: Dictionary in results:
		if int(d.get("total_points")) < int(d.get("base_points")):
			nondec_ok = false
		if int(d.get("bonus_points")) < 0:
			bonus_ok = false
	_ck("reward_monotonic_nondecreasing", nondec_ok,
		"4 组结算 total>=base：%s / %s / %s / %s" % [
			str(results[0].get("total_points")), str(results[1].get("total_points")),
			str(results[2].get("total_points")), str(results[3].get("total_points"))])
	_ck("reward_bonus_nonneg", bonus_ok, "所有 bonus>=0")
	_ck("reward_big_base", int(results[3].get("total_points")) == 1500,
		"base=1000 -> total=1500（floor(1000*1.5)）")
	# 已选但全部条件未达成 -> 仍回落基础（不惩罚）
	var r_none: Dictionary = svc.settle(100, _stats(1, 999.0, 30.0, 1.0))
	_ck("all_conditions_unmet_baseline", int(r_none.get("total_points")) == 100 \
		and str(r_none.get("reason")) == TrialModifierService.REASON_CONDITION_NOT_MET,
		"两项均未达成 -> 回落基础 100，reason=%s" % str(r_none.get("reason")))


## G) 余额非负：成功结算 balance=total>=0、bonus>=0；条件未达成也不击穿
func _test_balance_nonneg(cfg: TrialModifierConfig) -> void:
	var svc: TrialModifierService = TrialModifierService.new(cfg)
	svc.select("low_vigor")
	var seq: Array[Dictionary] = []
	seq.append(svc.settle(0, _stats(1, 999.0, 30.0, 0.4)))
	seq.append(svc.settle(100, _stats(1, 999.0, 30.0, 0.4)))
	seq.append(svc.settle(100, _stats(1, 999.0, 30.0, 0.9)))  # 未达成，回落
	seq.append(svc.settle(100, _stats(1, 999.0, 30.0, 0.4)))
	var ok_all: bool = true
	for d: Dictionary in seq:
		if int(d.get("balance")) < 0 or int(d.get("balance")) != int(d.get("total_points")):
			ok_all = false
		if int(d.get("bonus_points")) < 0:
			ok_all = false
	_ck("balance_all_nonneg", ok_all, "全程 balance>=0 且 =total，bonus>=0")
	_ck("balance_unmet_no_break", int(seq[2].get("balance")) == 100,
		"条件未达成余额仍=100（非负）")


## H) 异常输入拒绝：负 base / 非 Dictionary stats / config 缺失 / 不改状态
func _test_invalid_inputs(cfg: TrialModifierConfig) -> void:
	var svc: TrialModifierService = TrialModifierService.new(cfg)
	svc.select("no_hit")
	var r_neg: Dictionary = svc.settle(-1, _stats(0, 10.0, 30.0, 0.4))
	_ck("invalid_negative_base_rejected", not bool(r_neg.get("ok")) \
		and str(r_neg.get("reason")) == TrialModifierService.REASON_INVALID_POINTS,
		"base=-1 拒绝，reason=%s" % str(r_neg.get("reason")))
	_ck("invalid_negative_no_points", int(r_neg.get("total_points")) == 0 \
		and int(r_neg.get("balance")) == 0 and int(r_neg.get("bonus_points")) == 0,
		"拒绝时 total=0 balance=0 bonus=0（不产出负点数）")
	var r_null: Dictionary = svc.settle(100, null)
	_ck("invalid_stats_null_rejected", not bool(r_null.get("ok")) \
		and str(r_null.get("reason")) == TrialModifierService.REASON_INVALID_STATS,
		"stats=null 拒绝")
	var r_str: Dictionary = svc.settle(100, "not_a_dict")
	_ck("invalid_stats_string_rejected", not bool(r_str.get("ok")),
		"stats=字符串 拒绝")
	var r_arr: Dictionary = svc.settle(100, [1, 2, 3])
	_ck("invalid_stats_array_rejected", not bool(r_arr.get("ok")),
		"stats=Array 拒绝")
	var svc_null: TrialModifierService = TrialModifierService.new(null)
	var r_nocfg: Dictionary = svc_null.settle(100, _stats(0, 10.0, 30.0, 0.4))
	_ck("invalid_no_config_rejected", not bool(r_nocfg.get("ok")) \
		and str(r_nocfg.get("reason")) == TrialModifierService.REASON_NO_CONFIG,
		"config=null 结算拒绝，reason=%s" % str(r_nocfg.get("reason")))
	_ck("invalid_no_state_change", svc.get_selected_ids() == (["no_hit"] as Array[String]),
		"异常输入不改选择态，selected=%s" % str(svc.get_selected_ids()))
	var r_after: Dictionary = svc.settle(100, _stats(0, 10.0, 30.0, 0.4))
	_ck("invalid_then_normal_ok", bool(r_after.get("ok")) and int(r_after.get("total_points")) == 150,
		"异常拒绝后正常结算仍得 150（状态未被污染）")


func _finish() -> void:
	print("[V090-TM] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V090-TM] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V090-TM] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V090-TM] === SELFTEST END ===")
	quit(0 if all_ok else 1)
