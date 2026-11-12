extends SceneTree

## ===========================================================================
## R32 / v0.10.0 · 战后赐福抉择 Boon Draft「数据驱动 + 结算纯逻辑」自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_boon_draft_v100.gd
## 覆盖（任务单 ③）：正常 / 边界 / 异常三类输入 ——
##   正常：三选一合法选择、代价与增益成对生效、点数加成结算、reset 重开、余额非负；
##   边界：未选回落、越界 index、恰好 3 项、互斥细分、重复/同帧多次请求幂等；
##   异常：null / 字符串 / 浮点 / 负数点数 / config=null / 重复选择 / 重复 settle。
## 输出逐条 PASS=true/false + SUMMARY pass/fail + OVERALL=PASS/FAIL + RESULT=ALL_MATCH；
## 失败 quit(1)，不伪造 PASS。
## --script 模式纪律：纯 RefCounted + Resource 夹具，不 add_child、不取 /root/... 绝对路径、
##   不用 get_tree()；用 Engine.get_main_loop() as SceneTree 取 root 做只读断言；
##   读表统一 CACHE_MODE_IGNORE，校验落盘真值而非缓存；不写 user:// 存档、不碰渲染。
## 期望值来自 boon_draft.tres 首版 [PLACEHOLDER]（40.0/0.25/60.0、1.15/0.85/1.20），
##   校准后需同步 EXPECT_* 与 DONE-R32.md 数值拆解表，不静默改数。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const CONFIG_PATH: String = "res://data/rpg/boon_draft.tres"

const FIELD_KEYS: Array = [
	"id", "title", "description", "effect_key", "effect_value",
	"cost_key", "cost_value", "exclusive_group",
]

## [PLACEHOLDER] R32 首版期望（校验基准，不写进数据表；待人工试玩校准）。
const EXPECT_IDS: Array = ["boon_01_vigor_mend", "boon_02_poise_edge", "boon_03_grace_tribute"]
const EXPECT_EFFECT_KEYS: Array = ["hp_restore", "poise_damage_bonus", "points_bonus"]
const EXPECT_EFFECT_VALUES: Array = [40.0, 0.25, 60.0]
const EXPECT_COST_KEYS: Array = ["hp_scale", "telegraph_scale", "hp_scale"]
const EXPECT_COST_VALUES: Array = [1.15, 0.85, 1.20]
const EXPECT_GROUPS: Array = ["recovery", "tempo", "recovery"]

var _pass: int = 0
var _fail: int = 0


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V100-BD] %s PASS=%s | %s" % [tag, str(ok), detail])


func _initialize() -> void:
	print("[V100-BD] === SELFTEST START ===")
	# --script 模式纪律：用 Engine.get_main_loop() as SceneTree 取 root（只读断言），
	# 不用 get_tree()、不用 /root/... 绝对路径；本夹具纯内存，不 add_child。
	var ml: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = ml as SceneTree
	var root_node: Node = tree.root if tree != null else null
	_ck("scene_tree_root_via_main_loop", tree != null and root_node != null,
		"Engine.get_main_loop() as SceneTree -> root，不用 get_tree()/绝对路径")
	var cfg: BoonDraftConfig = ResourceLoader.load(
		CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as BoonDraftConfig
	_ck("table_load_cache_ignore", cfg != null, "path=%s" % CONFIG_PATH)
	if cfg == null:
		_finish()
		return
	_test_structure(cfg)          # 正常 + 边界：表结构 / 首版数值
	_test_select_legality(cfg)    # 正常 + 异常：合法性
	_test_exclusive_duplicate(cfg)  # 边界：互斥 / 重复 / 同帧多次
	_test_apply_paired(cfg)       # 正常 + 异常：代价增益成对
	_test_settle_points(cfg)      # 正常 + 边界：点数结算 / 余额非负 / 未选回落
	_test_invalid_inputs(cfg)     # 异常：null / 负数 / 字符串 / config=null
	_test_same_frame(cfg)         # 边界：同帧多次请求幂等
	_test_reset_cycle(cfg)        # 正常：reset 每波重新三选一
	_finish()


## A) [正常] 表结构 / 3 项 8 字段 / 首版 [PLACEHOLDER] / 白名单 / [边界] 越界 / 空表降级
func _test_structure(cfg: BoonDraftConfig) -> void:
	_ck("boon_count_3", cfg.boon_count() == 3 and cfg.boons.size() == 3,
		"count=%d size=%d" % [cfg.boon_count(), cfg.boons.size()])
	for i: int in range(3):
		var row: Dictionary = cfg.boons[i] as Dictionary
		var missing: Array[String] = []
		for k: String in FIELD_KEYS:
			if not row.has(k):
				missing.append(k)
		_ck("fields[%d]" % i, missing.is_empty(),
			"keys=%d missing=%s" % [row.size(), str(missing)])
		var b: BoonDraftConfig.Boon = cfg.get_boon(i)
		_ck("id[%d]" % i, b != null and b.id == str(EXPECT_IDS[i]),
			"got=%s expect=%s" % [str(b.id if b != null else "<null>"), str(EXPECT_IDS[i])])
		_ck("title_desc_nonempty[%d]" % i,
			b != null and not b.title.is_empty() and not b.description.is_empty(),
			"title=%s" % str(b.title if b != null else "<null>"))
		_ck("effect_key[%d]" % i, b != null and b.effect_key == str(EXPECT_EFFECT_KEYS[i]),
			"got=%s expect=%s" % [str(b.effect_key if b != null else "<null>"), str(EXPECT_EFFECT_KEYS[i])])
		_ck("effect_value[%d]" % i, b != null and is_equal_approx(b.effect_value, float(EXPECT_EFFECT_VALUES[i])),
			"got=%s expect=%s [PLACEHOLDER]" % [str(b.effect_value if b != null else -1.0), str(EXPECT_EFFECT_VALUES[i])])
		_ck("cost_key[%d]" % i, b != null and b.cost_key == str(EXPECT_COST_KEYS[i]),
			"got=%s expect=%s" % [str(b.cost_key if b != null else "<null>"), str(EXPECT_COST_KEYS[i])])
		_ck("cost_value[%d]" % i, b != null and is_equal_approx(b.cost_value, float(EXPECT_COST_VALUES[i])),
			"got=%s expect=%s [PLACEHOLDER]" % [str(b.cost_value if b != null else -1.0), str(EXPECT_COST_VALUES[i])])
		_ck("group[%d]" % i, b != null and b.exclusive_group == str(EXPECT_GROUPS[i]),
			"got=%s expect=%s" % [str(b.exclusive_group if b != null else "<null>"), str(EXPECT_GROUPS[i])])
		_ck("valid[%d]" % i, cfg.is_boon_valid(b), "is_boon_valid=true")
	# 增益 / 代价成对：effect_value 与 cost_value 恒 > 0
	var all_positive: bool = true
	for i: int in range(3):
		var bb: BoonDraftConfig.Boon = cfg.get_boon(i)
		if bb == null or bb.effect_value <= 0.0 or bb.cost_value <= 0.0:
			all_positive = false
	_ck("paired_all_positive", all_positive, "3 项增益与代价均 > 0（成对生效前提）")
	_ck("boon_set_valid", cfg.is_boon_set_valid(), "is_boon_set_valid=true（3 项合法且 effect_key 互异）")
	var g: Dictionary = cfg.group_to_ids()
	var rec: Array = g.get("recovery", []) as Array
	var tempo: Array = g.get("tempo", []) as Array
	_ck("group_recovery_2", rec.size() == 2 and rec.has("boon_01_vigor_mend") and rec.has("boon_03_grace_tribute"),
		"recovery=%s" % str(rec))
	_ck("group_tempo_1", tempo.size() == 1 and tempo.has("boon_02_poise_edge"),
		"tempo=%s" % str(tempo))
	# 白名单
	_ck("id_whitelist_3", BoonDraftConfig.KNOWN_IDS.size() == 3, "KNOWN_IDS=%s" % str(BoonDraftConfig.KNOWN_IDS))
	_ck("effect_whitelist_3", BoonDraftConfig.KNOWN_EFFECT_KEYS.size() == 3, "KNOWN_EFFECT_KEYS=%s" % str(BoonDraftConfig.KNOWN_EFFECT_KEYS))
	_ck("cost_whitelist_2", BoonDraftConfig.KNOWN_COST_KEYS.size() == 2, "KNOWN_COST_KEYS=%s" % str(BoonDraftConfig.KNOWN_COST_KEYS))
	_ck("unknown_id_rejected", not BoonDraftConfig.is_id_known("phantom"), "phantom 不在白名单")
	_ck("unknown_effect_rejected", not BoonDraftConfig.is_effect_key_known("fly"), "fly 不在 effect 白名单")
	_ck("unknown_cost_rejected", not BoonDraftConfig.is_cost_key_known("gold"), "gold 不在 cost 白名单")
	# [边界] 越界 / 空表 / 字段缺失降级
	_ck("bounds_negative_null", cfg.get_boon(-1) == null, "get_boon(-1)=null")
	_ck("bounds_index3_null", cfg.get_boon(3) == null, "get_boon(3)=null")
	_ck("find_by_id", cfg.find_boon_by_id("boon_02_poise_edge") != null, "find_boon_by_id 命中")
	_ck("find_unknown_null", cfg.find_boon_by_id("phantom") == null, "find_boon_by_id(phantom)=null")
	var empty: BoonDraftConfig = BoonDraftConfig.new()
	_ck("empty_count_0", empty.boon_count() == 0, "count=0")
	_ck("empty_get_null", empty.get_boon(0) == null, "空表 get_boon(0)=null 不崩")
	_ck("empty_set_invalid", not empty.is_boon_set_valid(), "空表 set=false")
	var d0: BoonDraftConfig.Boon = cfg.boon_from_dict({})
	_ck("missing_all_defaults", d0.id == BoonDraftConfig.DEFAULT_ID \
		and d0.effect_key == BoonDraftConfig.DEFAULT_EFFECT_KEY \
		and is_equal_approx(d0.effect_value, BoonDraftConfig.DEFAULT_EFFECT_VALUE) \
		and is_equal_approx(d0.cost_value, BoonDraftConfig.DEFAULT_COST_VALUE),
		"缺字段全回落 [PLACEHOLDER] 基线")
	_ck("missing_all_invalid", not cfg.is_boon_valid(d0), "空表降级视图判非法")
	_ck("make_boon_8_fields", cfg.make_boon("x", "t", "d", "hp_restore", 1.0, "hp_scale", 1.0, "recovery").size() == 8,
		"size=8")


## B) [正常 + 异常] select 合法性：合法 / null / 字符串 / 浮点 / 越界 / config=null
func _test_select_legality(cfg: BoonDraftConfig) -> void:
	var svc: BoonDraftService = BoonDraftService.new(cfg)
	var r0: Dictionary = svc.select(0)
	_ck("select_valid_ok", bool(r0.get("ok")) and str(r0.get("reason")) == BoonDraftService.REASON_OK,
		"select(0) ok, reason=%s" % str(r0.get("reason")))
	_ck("select_index_recorded", svc.get_selected_index() == 0 and svc.has_selection(),
		"selected_index=%d" % svc.get_selected_index())
	var svc2: BoonDraftService = BoonDraftService.new(cfg)
	var r_null_sel: Dictionary = svc2.select(null)
	_ck("select_null_rejected", not bool(r_null_sel.get("ok")) \
		and str(r_null_sel.get("reason")) == BoonDraftService.REASON_INVALID_INDEX,
		"null -> invalid_index 拒绝")
	var svc3: BoonDraftService = BoonDraftService.new(cfg)
	_ck("select_string_rejected", not bool(svc3.select("0").get("ok")), "字符串 -> 拒绝")
	var svc4: BoonDraftService = BoonDraftService.new(cfg)
	_ck("select_float_rejected", not bool(svc4.select(1.5).get("ok")), "浮点 -> 拒绝")
	var svc5: BoonDraftService = BoonDraftService.new(cfg)
	_ck("select_negative_rejected", not bool(svc5.select(-1).get("ok")), "-1 -> 拒绝")
	var svc6: BoonDraftService = BoonDraftService.new(cfg)
	_ck("select_index3_rejected", not bool(svc6.select(3).get("ok")), "3 -> 拒绝")
	var svc_null: BoonDraftService = BoonDraftService.new(null)
	var r_null: Dictionary = svc_null.select(0)
	_ck("select_no_config_rejected", not bool(r_null.get("ok")) \
		and str(r_null.get("reason")) == BoonDraftService.REASON_NO_CONFIG,
		"config=null 拒绝，reason=%s" % str(r_null.get("reason")))
	_ck("select_reject_no_state_change", not svc2.has_selection() and not svc3.has_selection(),
		"所有拒绝操作不改选择态")


## C) [边界] 互斥 / 重复选择 / 拒绝不改状态
func _test_exclusive_duplicate(cfg: BoonDraftConfig) -> void:
	# 先选 0（recovery），再选 2（recovery 同组）-> EXCLUSIVE
	var s1: BoonDraftService = BoonDraftService.new(cfg)
	s1.select(0)
	var r_ex: Dictionary = s1.select(2)
	_ck("exclusive_same_group_rejected", not bool(r_ex.get("ok")) \
		and str(r_ex.get("reason")) == BoonDraftService.REASON_EXCLUSIVE,
		"0(recovery) + 2(recovery) 互斥拒绝，reason=%s" % str(r_ex.get("reason")))
	_ck("exclusive_no_state_change", s1.get_selected_index() == 0,
		"互斥拒绝后 selected_index 仍=0")
	# 先选 0，再选 0（同一项）-> DUPLICATE
	var s2: BoonDraftService = BoonDraftService.new(cfg)
	s2.select(0)
	_ck("duplicate_same_index_rejected", not bool(s2.select(0).get("ok")) \
		and str(s2.select(0).get("reason")) == BoonDraftService.REASON_DUPLICATE,
		"重复同 index -> duplicate 拒绝")
	# 先选 0，再选 1（不同组 tempo，但三选一已抉择）-> DUPLICATE
	var s3: BoonDraftService = BoonDraftService.new(cfg)
	s3.select(0)
	var r_dup: Dictionary = s3.select(1)
	_ck("duplicate_different_group_rejected", not bool(r_dup.get("ok")) \
		and str(r_dup.get("reason")) == BoonDraftService.REASON_DUPLICATE,
		"不同组但已抉择 -> duplicate 拒绝（三选一不许多选）")
	_ck("duplicate_no_state_change", s3.get_selected_index() == 0,
		"重复拒绝后 selected_index 仍=0")


## D) [正常 + 异常] apply 代价与增益成对生效 / 重复 apply / 未选 / config=null
func _test_apply_paired(cfg: BoonDraftConfig) -> void:
	var svc: BoonDraftService = BoonDraftService.new(cfg)
	svc.select(2)  # points_bonus / hp_scale 1.20
	var r: Dictionary = svc.apply()
	_ck("apply_ok", bool(r.get("ok")) and str(r.get("reason")) == BoonDraftService.REASON_OK,
		"apply() ok")
	_ck("apply_paired_true", bool(r.get("paired")), "paired=true（增益与代价成对）")
	_ck("apply_effect_present", str(r.get("effect_key")) == "points_bonus" \
		and is_equal_approx(float(r.get("effect_value")), 60.0),
		"effect=points_bonus / 60.0 [PLACEHOLDER]")
	_ck("apply_cost_present", str(r.get("cost_key")) == "hp_scale" \
		and is_equal_approx(float(r.get("cost_value")), 1.20),
		"cost=hp_scale / 1.20 [PLACEHOLDER]")
	_ck("apply_both_positive", float(r.get("effect_value")) > 0.0 and float(r.get("cost_value")) > 0.0,
		"增益与代价同时为正、同时存在（绝不只给增益）")
	_ck("apply_flag_set", svc.is_applied(), "is_applied=true")
	var r_dup: Dictionary = svc.apply()
	_ck("apply_duplicate_rejected", not bool(r_dup.get("ok")) \
		and str(r_dup.get("reason")) == BoonDraftService.REASON_ALREADY_APPLIED,
		"重复 apply -> already_applied 拒绝（幂等）")
	var s_unsel: BoonDraftService = BoonDraftService.new(cfg)
	var r_unsel: Dictionary = s_unsel.apply()
	_ck("apply_no_selection_rejected", not bool(r_unsel.get("ok")) \
		and str(r_unsel.get("reason")) == BoonDraftService.REASON_NO_SELECTION,
		"未选 apply -> no_selection 拒绝")
	var s_null: BoonDraftService = BoonDraftService.new(null)
	_ck("apply_no_config_rejected", not bool(s_null.apply().get("ok")), "config=null apply 拒绝")


## E) [正常 + 边界] settle 点数结算 / 余额非负 / 未选回落 / 非点数候选不加点
func _test_settle_points(cfg: BoonDraftConfig) -> void:
	# 正常：选 points_bonus 候选，base=100 -> total=160 / bonus=60 / balance=160
	var s1: BoonDraftService = BoonDraftService.new(cfg)
	s1.select(2)
	var r1: Dictionary = s1.settle(100)
	_ck("settle_points_bonus_ok", bool(r1.get("ok")) and str(r1.get("reason")) == BoonDraftService.REASON_OK,
		"settle(100) ok")
	_ck("settle_points_bonus_total", int(r1.get("total_points")) == 160 \
		and int(r1.get("bonus_points")) == 60 and int(r1.get("balance")) == 160,
		"base=100 +60 -> total=160 / bonus=60 / balance=160 [PLACEHOLDER]")
	_ck("settle_paired_meta", bool(r1.get("paired")) and str(r1.get("cost_key")) == "hp_scale",
		"settle 结果仍带成对 cost 元数据（代价去向明确）")
	# 正常：非 points_bonus 候选（hp_restore / poise_damage_bonus）不加点数
	var s2: BoonDraftService = BoonDraftService.new(cfg)
	s2.select(0)
	var r2: Dictionary = s2.settle(100)
	_ck("settle_non_points_no_bonus", int(r2.get("total_points")) == 100 \
		and int(r2.get("bonus_points")) == 0 and int(r2.get("balance")) == 100,
		"hp_restore 候选只回血不加点：total=100")
	var s3: BoonDraftService = BoonDraftService.new(cfg)
	s3.select(1)
	_ck("settle_poise_no_bonus", int(s3.settle(250).get("total_points")) == 250,
		"poise_damage_bonus 候选不加点：total=250")
	# [边界] 未选回落基础，不惩罚
	var s4: BoonDraftService = BoonDraftService.new(cfg)
	var r4: Dictionary = s4.settle(100)
	_ck("settle_no_selection_baseline", bool(r4.get("ok")) \
		and str(r4.get("reason")) == BoonDraftService.REASON_NO_SELECTION \
		and int(r4.get("total_points")) == 100 and int(r4.get("balance")) == 100,
		"未选 -> 回落基础 100（不惩罚、不加点）")
	# [边界] base=0 余额非负
	var s5: BoonDraftService = BoonDraftService.new(cfg)
	s5.select(2)
	var r5: Dictionary = s5.settle(0)
	_ck("settle_base0_nonneg", int(r5.get("total_points")) == 60 \
		and int(r5.get("balance")) == 60 and int(r5.get("bonus_points")) == 60,
		"base=0 -> total=60 balance=60（非负）")
	# [边界] 大基数余额非负
	var s6: BoonDraftService = BoonDraftService.new(cfg)
	s6.select(2)
	var r6: Dictionary = s6.settle(1000)
	_ck("settle_big_base", int(r6.get("total_points")) == 1060 \
		and int(r6.get("balance")) >= 0,
		"base=1000 -> total=1060")


## F) [异常] null / 负数 / 字符串 / 非数值 / config=null / 重复 settle / 异常后状态未污染
func _test_invalid_inputs(cfg: BoonDraftConfig) -> void:
	var s_neg: BoonDraftService = BoonDraftService.new(cfg)
	s_neg.select(2)
	var r_neg: Dictionary = s_neg.settle(-1)
	_ck("invalid_negative_base_rejected", not bool(r_neg.get("ok")) \
		and str(r_neg.get("reason")) == BoonDraftService.REASON_INVALID_POINTS,
		"base=-1 拒绝，reason=%s" % str(r_neg.get("reason")))
	_ck("invalid_negative_no_points", int(r_neg.get("total_points")) == 0 \
		and int(r_neg.get("balance")) == 0 and int(r_neg.get("bonus_points")) == 0,
		"拒绝时 total=0 balance=0 bonus=0（不产出负点数）")
	var s_null: BoonDraftService = BoonDraftService.new(cfg)
	s_null.select(2)
	_ck("invalid_settle_null_rejected", not bool(s_null.settle(null).get("ok")), "settle(null) 拒绝")
	var s_str: BoonDraftService = BoonDraftService.new(cfg)
	s_str.select(2)
	_ck("invalid_settle_string_rejected", not bool(s_str.settle("bad").get("ok")), "settle(字符串) 拒绝")
	var s_arr: BoonDraftService = BoonDraftService.new(cfg)
	s_arr.select(2)
	_ck("invalid_settle_array_rejected", not bool(s_arr.settle([1, 2]).get("ok")), "settle(Array) 拒绝")
	var s_nocfg: BoonDraftService = BoonDraftService.new(null)
	var r_nocfg: Dictionary = s_nocfg.settle(100)
	_ck("invalid_no_config_rejected", not bool(r_nocfg.get("ok")) \
		and str(r_nocfg.get("reason")) == BoonDraftService.REASON_NO_CONFIG,
		"config=null 结算拒绝")
	# 重复 settle 拒绝（防重复给点 / 防通胀）
	var s_dup: BoonDraftService = BoonDraftService.new(cfg)
	s_dup.select(2)
	var first: Dictionary = s_dup.settle(100)
	var second: Dictionary = s_dup.settle(100)
	_ck("settle_duplicate_rejected", bool(first.get("ok")) and not bool(second.get("ok")) \
		and str(second.get("reason")) == BoonDraftService.REASON_ALREADY_SETTLED,
		"重复 settle -> already_settled 拒绝（不重复给点）")
	# 异常拒绝后正常结算仍 OK（状态未被污染）
	var s_after: BoonDraftService = BoonDraftService.new(cfg)
	s_after.select(2)
	s_after.settle(-5)  # 异常（不改 _settled）
	var r_after: Dictionary = s_after.settle(100)
	_ck("invalid_then_normal_ok", bool(r_after.get("ok")) and int(r_after.get("total_points")) == 160,
		"异常拒绝后正常结算仍得 160（状态未被污染）")


## G) [边界] 同帧多次请求：连续 select/apply/settle 幂等，状态不被污染、不重复给点
func _test_same_frame(cfg: BoonDraftConfig) -> void:
	var svc: BoonDraftService = BoonDraftService.new(cfg)
	# 连续多次 select（模拟同帧重复点击）
	var a: Dictionary = svc.select(0)
	var b: Dictionary = svc.select(0)
	var c: Dictionary = svc.select(1)
	_ck("same_frame_select_once", bool(a.get("ok")) and not bool(b.get("ok")) and not bool(c.get("ok")) \
		and svc.get_selected_index() == 0,
		"同帧 3 次 select 只第 1 次生效，selected_index=0")
	# 连续多次 apply
	var p1: Dictionary = svc.apply()
	var p2: Dictionary = svc.apply()
	_ck("same_frame_apply_once", bool(p1.get("ok")) and not bool(p2.get("ok")) and svc.is_applied(),
		"同帧 2 次 apply 只第 1 次生效")
	# 连续多次 settle（不重复给点）
	var t1: Dictionary = svc.settle(100)
	var t2: Dictionary = svc.settle(100)
	_ck("same_frame_settle_once", bool(t1.get("ok")) and not bool(t2.get("ok")) \
		and int(t1.get("total_points")) == 100,
		"同帧 2 次 settle 只第 1 次生效（hp_restore 候选 total=100，不双算）")
	# snapshot 自洽
	var snap: Dictionary = svc.get_snapshot()
	_ck("same_frame_snapshot_stable", bool(snap.get("has_selection")) \
		and bool(snap.get("applied")) and bool(snap.get("settled")) \
		and int(snap.get("selected_index")) == 0,
		"snapshot=%s" % str(snap))


## H) [正常] reset 后每波清波可重新三选一（玩法闭环）
func _test_reset_cycle(cfg: BoonDraftConfig) -> void:
	var svc: BoonDraftService = BoonDraftService.new(cfg)
	svc.select(2)
	svc.apply()
	svc.settle(100)
	_ck("cycle_wave1_settled", svc.is_settled() and int(svc.get_snapshot().get("selected_index")) == 2,
		"第 1 波抉择完成")
	svc.reset()
	_ck("cycle_reset_clears", not svc.has_selection() and not svc.is_applied() and not svc.is_settled(),
		"reset 清空抉择态")
	var r: Dictionary = svc.select(1)  # 第 2 波改选削韧强化
	_ck("cycle_wave2_reselect_ok", bool(r.get("ok")) and svc.get_selected_index() == 1,
		"第 2 波可重新三选一")
	var ap: Dictionary = svc.apply()
	_ck("cycle_wave2_paired", bool(ap.get("paired")) and str(ap.get("cost_key")) == "telegraph_scale",
		"第 2 波代价=telegraph_scale 成对生效")


func _finish() -> void:
	print("[V100-BD] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V100-BD] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V100-BD] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V100-BD] === SELFTEST END ===")
	quit(0 if all_ok else 1)
