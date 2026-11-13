extends SceneTree

## ===========================================================================
## R38 / v0.15.0 · 大地图野外遭遇「正常 / 边界 / 异常」生产级自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_world_encounter_v150.gd
##
## 覆盖（任务单 ④）：
##   - 读表 4 分区 / 6 遭遇点 / 7 字段 / [PLACEHOLDER] 数值 / 分区 id 对齐；
##   - enter_region 进入触发、try_trigger 距离判定（半径内 / 半径外）、
##     已清除区域不重复触发、重复触发幂等、异常输入拒绝、区域进度单调递增；
##   - on_encounter_cleared 标记清除 / 重复清除幂等、reset 复位；
##   - config 缺失 / 非法表 / 异常输入一律拒绝且不改状态；异常后正常流程仍成功；
##   - 4 个公开信号存在且 payload 正确；纯逻辑边界（I-1 不读写存档 / 不碰渲染）；
##   - A48① 静态证据：生产源码含 4 信号订阅者 + 唯一实例 getter + 结算接线 + 驱动口。
##
## 【--script 模式纪律 / 不写生产存档】
## - 用 Engine.get_main_loop() as SceneTree 取 root：不用 get_tree()、
##   不用 /root/... 绝对路径。WorldEncounterService 是 RefCounted 纯逻辑，
##   直接 new、不 add_child、不需要 _ready() flush。
## - 全程只读 ResourceLoader.load(CACHE_MODE_IGNORE)；不碰渲染、不启 GPU job、
##   不读写 user://slot_01/delta.json。
## 输出逐条 PASS=true/false + SUMMARY + OVERALL=PASS/FAIL + RESULT=ALL_MATCH；失败 quit(1)。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const TABLE_PATH: String = "res://data/rpg/world_encounters.tres"
const CONFIG_PATH: String = "res://scripts/combat/world_encounter_config.gd"
const SERVICE_PATH: String = "res://scripts/combat/world_encounter_service.gd"
const DIRECTOR_PATH: String = "res://scripts/combat/wave_trial_director.gd"

## [PLACEHOLDER] R38 首版期望（校验基准；调参只改表，同步本脚本 + DONE-R38.md）。
const EXPECT_REGIONS: int = 4
const EXPECT_ENCOUNTERS: int = 6
const EXPECT_POLICY: String = "reject"
const EXPECT_REGION_IDS: Array = [
	"limgrave", "weeping_peninsula", "stormveil", "siofra_well",
]
const EXPECT_RADIUS: Dictionary = {
	"enc_limgrave_gatefront": 96.0,
	"enc_limgrave_chapel": 80.0,
	"enc_weeping_shore": 112.0,
	"enc_stormveil_gate": 96.0,
	"enc_siofra_well_entry": 128.0,
	"enc_siofra_well_deep": 128.0,
}
const EXPECT_REWARD: Dictionary = {
	"enc_limgrave_gatefront": 80,
	"enc_limgrave_chapel": 100,
	"enc_weeping_shore": 120,
	"enc_stormveil_gate": 150,
	"enc_siofra_well_entry": 160,
	"enc_siofra_well_deep": 200,
}

var _pass: int = 0
var _fail: int = 0
var _root: Node = null

## 验证脚本侧信号计数（单元断言用；A48① 生产订阅者由 director 源码 + GATE-3 实证）。
var _sig_region_entered: int = 0
var _sig_triggered: int = 0
var _sig_triggered_reward: int = -1
var _sig_triggered_id: String = ""
var _sig_cleared: int = 0
var _sig_cleared_payload: int = -1
var _sig_rejected: int = 0
var _sig_last_reject: String = ""


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V150-WE] %s PASS=%s | %s" % [tag, str(ok), detail])


func _on_region_entered(_region_id: String) -> void:
	_sig_region_entered += 1


func _on_encounter_triggered(encounter_id: String, _region_id: String,
		reward_points: int) -> void:
	_sig_triggered += 1
	_sig_triggered_id = encounter_id
	_sig_triggered_reward = reward_points


func _on_encounter_cleared(_encounter_id: String, _region_id: String,
		cleared_count: int) -> void:
	_sig_cleared += 1
	_sig_cleared_payload = cleared_count


func _on_trigger_rejected(reason: String, _encounter_id: String) -> void:
	_sig_rejected += 1
	_sig_last_reject = reason


func _reset_signals() -> void:
	_sig_region_entered = 0
	_sig_triggered = 0
	_sig_triggered_reward = -1
	_sig_triggered_id = ""
	_sig_cleared = 0
	_sig_cleared_payload = -1
	_sig_rejected = 0
	_sig_last_reject = ""


func _load_config() -> WorldEncounterConfig:
	return ResourceLoader.load(TABLE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as WorldEncounterConfig


## 构造一个订阅了 4 信号的独立 service（纯逻辑、不 add_child、不写存档）。
func _make_service(cfg: WorldEncounterConfig) -> WorldEncounterService:
	var s: WorldEncounterService = WorldEncounterService.new(cfg)
	s.connect("region_entered", Callable(self, "_on_region_entered"))
	s.connect("encounter_triggered", Callable(self, "_on_encounter_triggered"))
	s.connect("encounter_cleared", Callable(self, "_on_encounter_cleared"))
	s.connect("trigger_rejected", Callable(self, "_on_trigger_rejected"))
	_reset_signals()
	return s


func _initialize() -> void:
	print("[V150-WE] === SELFTEST START ===")
	var ml: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = ml as SceneTree
	_root = tree.root if tree != null else null
	_ck("scene_tree_root_via_main_loop", tree != null and _root != null,
		"Engine.get_main_loop() as SceneTree -> root，不用 get_tree()/绝对路径")
	if _root == null:
		_finish()
		return

	_test_table_structure()
	_test_enter_and_distance()
	_test_idempotent_and_cleared()
	_test_monotonic_progress()
	_test_abnormal_inputs()
	_test_illegal_tables()
	_test_reset_and_purity()

	_finish()


## A) 表结构 / [PLACEHOLDER] 数值 / 分区 id 对齐 / 信号存在 / 降级基线
func _test_table_structure() -> void:
	var cfg: WorldEncounterConfig = _load_config()
	_ck("table_load_cache_ignore", cfg != null, "path=%s（CACHE_MODE_IGNORE 回读真值）" % TABLE_PATH)
	if cfg == null:
		return
	_ck("config_is_valid", cfg.is_valid(), "WorldEncounterConfig.is_valid()=true")
	_ck("region_count_%d" % EXPECT_REGIONS, cfg.get_region_count() == EXPECT_REGIONS,
		"region_count=%d [PLACEHOLDER]（至少 4 个区域）" % cfg.get_region_count())
	_ck("encounter_count_%d" % EXPECT_ENCOUNTERS, cfg.get_encounter_count() == EXPECT_ENCOUNTERS,
		"encounter_count=%d [PLACEHOLDER]" % cfg.get_encounter_count())
	var ids: PackedStringArray = cfg.get_region_ids()
	var ids_match: bool = ids.size() == EXPECT_REGION_IDS.size()
	for i: int in range(mini(ids.size(), EXPECT_REGION_IDS.size())):
		if String(ids[i]) != String(EXPECT_REGION_IDS[i]):
			ids_match = false
	_ck("region_ids_aligned", ids_match,
		"分区 id 与既有 m6_area_bindings.tres 的 region 字段逐字对齐：%s [PLACEHOLDER]" % str(ids))
	_ck("invalid_input_policy_ph", cfg.get_invalid_input_policy() == EXPECT_POLICY,
		"got=%s expect=%s [PLACEHOLDER]" % [cfg.get_invalid_input_policy(), EXPECT_POLICY])
	# 7 字段 + [PLACEHOLDER] 数值逐项校验
	var rows: Array[Dictionary] = cfg.get_encounters()
	var fields_ok: bool = true
	var radius_ok: bool = true
	var reward_ok: bool = true
	var cleared_ok: bool = true
	var pos_ok: bool = true
	for r: Dictionary in rows:
		for f: String in WorldEncounterConfig.ENCOUNTER_FIELDS:
			if not r.has(f):
				fields_ok = false
		var eid: String = String(r.get("id", ""))
		if EXPECT_RADIUS.has(eid) and not is_equal_approx(float(r.get("trigger_radius", -1.0)), float(EXPECT_RADIUS[eid])):
			radius_ok = false
		if EXPECT_REWARD.has(eid) and int(r.get("reward_points", -1)) != int(EXPECT_REWARD[eid]):
			reward_ok = false
		if typeof(r.get("position")) != TYPE_VECTOR2:
			pos_ok = false
		if typeof(r.get("cleared_flag")) != TYPE_BOOL or bool(r.get("cleared_flag", true)):
			cleared_ok = false
		if String(r.get("region_id", "")) == "" or not cfg.has_region(String(r.get("region_id", ""))):
			fields_ok = false
	_ck("encounter_fields_all_7", fields_ok, "6 行遭遇点均含 id/region_id/position/enemy_group/trigger_radius/cleared_flag/reward_points")
	_ck("placeholder_radius", radius_ok, "6 个 trigger_radius 与 [PLACEHOLDER] 期望一致（96/80/112/96/128/128）")
	_ck("placeholder_reward", reward_ok, "6 个 reward_points 与 [PLACEHOLDER] 期望一致（80/100/120/150/160/200）")
	_ck("placeholder_position_cleared", pos_ok and cleared_ok,
		"position 均为 Vector2 / cleared_flag 均为 false（首版）")
	_ck("default_is_not_design_regions", WorldEncounterConfig.DEFAULT_REGION_IDS.is_empty() \
		and cfg.get_region_count() != WorldEncounterConfig.DEFAULT_REGION_IDS.size(),
		"DEFAULT_REGION_IDS 为空 != 表值 4（调参唯一入口在 .tres）")
	_ck("default_is_not_design_encounters", WorldEncounterConfig.DEFAULT_ENCOUNTERS.is_empty() \
		and cfg.get_encounter_count() != WorldEncounterConfig.DEFAULT_ENCOUNTERS.size(),
		"DEFAULT_ENCOUNTERS 为空 != 表值 6（调参唯一入口在 .tres）")
	# 4 个公开信号存在
	var probe: WorldEncounterService = WorldEncounterService.new(cfg)
	_ck("signal_region_entered_exists", probe.has_signal("region_entered"),
		"signal region_entered(region_id: String)")
	_ck("signal_encounter_triggered_exists", probe.has_signal("encounter_triggered"),
		"signal encounter_triggered(encounter_id, region_id, reward_points)")
	_ck("signal_encounter_cleared_exists", probe.has_signal("encounter_cleared"),
		"signal encounter_cleared(encounter_id, region_id, cleared_count)")
	_ck("signal_trigger_rejected_exists", probe.has_signal("trigger_rejected"),
		"signal trigger_rejected(reason, encounter_id)")


## B) 进入触发 + 距离判定（半径内 / 半径外）+ payload
func _test_enter_and_distance() -> void:
	var cfg: WorldEncounterConfig = _load_config()
	var s: WorldEncounterService = _make_service(cfg)
	var en: Dictionary = s.enter_region("limgrave")
	_ck("enter_region_ok", bool(en.get("ok")) and str(en.get("region_id")) == "limgrave",
		"enter_region(limgrave) 成功、当前分区置位")
	_ck("region_entered_signal_once", _sig_region_entered == 1,
		"region_entered 恰 1 次（进入触发）")
	# 半径内：正好命中遭遇点中心，distance=0
	var t: Dictionary = s.try_trigger(Vector2(512, 384))
	_ck("distance_inside_trigger_ok", bool(t.get("ok")) \
		and str(t.get("encounter_id")) == "enc_limgrave_gatefront" \
		and int(t.get("reward_points")) == 80,
		"try_trigger(512,384) 命中 gatefront、reward=80 [PLACEHOLDER]")
	_ck("trigger_distance_zero", is_equal_approx(float(t.get("distance", -1.0)), 0.0),
		"distance_to=0（2.5D 俯视平面距离判定）")
	_ck("trigger_payload_fields", str(t.get("enemy_group")) == "enemy_01_limgrave_soldier" \
		and str(t.get("region_id")) == "limgrave" \
		and is_equal_approx(float(t.get("trigger_radius", -1.0)), 96.0),
		"payload 含 enemy_group / region_id / trigger_radius=96")
	_ck("encounter_triggered_signal_once", _sig_triggered == 1 \
		and _sig_triggered_id == "enc_limgrave_gatefront" and _sig_triggered_reward == 80,
		"encounter_triggered 恰 1 次、payload(id, reward=80) 正确")
	# 新建实例：半径边缘内（distance=90 <= 96）仍命中
	var s2: WorldEncounterService = _make_service(cfg)
	s2.enter_region("limgrave")
	var edge: Dictionary = s2.try_trigger(Vector2(602, 384))
	_ck("distance_edge_inside_ok", bool(edge.get("ok")) \
		and str(edge.get("encounter_id")) == "enc_limgrave_gatefront",
		"try_trigger(602,384) distance=90 <= radius=96 仍命中")
	# 新建实例：半径外（distance=100 > 96，且 chapel 也够不着）-> no_encounter
	var s3: WorldEncounterService = _make_service(cfg)
	s3.enter_region("limgrave")
	var out: Dictionary = s3.try_trigger(Vector2(612, 384))
	_ck("distance_outside_no_encounter", not bool(out.get("ok")) \
		and str(out.get("reason")) == "no_encounter",
		"try_trigger(612,384) distance=100 > 96 -> no_encounter（距离判定拒绝）")


## C) 重复触发幂等 / 标记清除 / 重复清除幂等 / 已清除区域不重复触发
func _test_idempotent_and_cleared() -> void:
	var cfg: WorldEncounterConfig = _load_config()
	var s: WorldEncounterService = _make_service(cfg)
	s.enter_region("limgrave")
	s.try_trigger(Vector2(512, 384))
	var dup: Dictionary = s.try_trigger(Vector2(512, 384))
	_ck("duplicate_trigger_idempotent", not bool(dup.get("ok")) \
		and str(dup.get("reason")) == "duplicate",
		"active 未清除时重复 try_trigger -> duplicate 拒绝（幂等）")
	_ck("duplicate_no_second_signal", _sig_triggered == 1 \
		and int(s.get_snapshot().get("trigger_count")) == 1,
		"重复触发不二次发信号 / trigger_count 恒 1")
	var clr: Dictionary = s.on_encounter_cleared("enc_limgrave_gatefront")
	_ck("on_encounter_cleared_ok", bool(clr.get("ok")) \
		and int(clr.get("cleared_count")) == 1 and s.is_cleared("enc_limgrave_gatefront"),
		"标记区域已清除：cleared_count=1、is_cleared=true")
	_ck("encounter_cleared_signal_once", _sig_cleared == 1 and _sig_cleared_payload == 1,
		"encounter_cleared 恰 1 次、payload(cleared_count=1) 正确")
	var clr2: Dictionary = s.on_encounter_cleared("enc_limgrave_gatefront")
	_ck("duplicate_clear_idempotent", not bool(clr2.get("ok")) \
		and str(clr2.get("reason")) == "no_active" \
		and int(s.get_snapshot().get("cleared_count")) == 1,
		"重复清除 -> no_active、进度不二次增加（幂等）")
	# 单遭遇区域全清后再触发 -> already_cleared（已清除区域不重复触发）
	var s2: WorldEncounterService = _make_service(cfg)
	s2.enter_region("stormveil")
	var t: Dictionary = s2.try_trigger(Vector2(2048, 768))
	_ck("stormveil_trigger_ok", bool(t.get("ok")) \
		and str(t.get("encounter_id")) == "enc_stormveil_gate",
		"stormveil 单遭遇区域触发成功")
	s2.on_encounter_cleared("enc_stormveil_gate")
	var again: Dictionary = s2.try_trigger(Vector2(2048, 768))
	_ck("cleared_region_no_retrigger", not bool(again.get("ok")) \
		and str(again.get("reason")) == "already_cleared",
		"区域全部遭遇已清除 -> already_cleared（已清除区域不重复触发）")


## D) 区域进度单调递增（连续清 4 个区域各 1 个遭遇）
func _test_monotonic_progress() -> void:
	var cfg: WorldEncounterConfig = _load_config()
	var s: WorldEncounterService = _make_service(cfg)
	var seq: Array[int] = [s.get_cleared_count()]
	var plan: Array = [
		["limgrave", Vector2(512, 384), "enc_limgrave_gatefront"],
		["weeping_peninsula", Vector2(1536, 384), "enc_weeping_shore"],
		["stormveil", Vector2(2048, 768), "enc_stormveil_gate"],
		["siofra_well", Vector2(2560, 512), "enc_siofra_well_entry"],
	]
	for step: Array in plan:
		s.enter_region(String(step[0]))
		var t: Dictionary = s.try_trigger(step[1] as Vector2)
		if bool(t.get("ok")):
			s.on_encounter_cleared(String(t.get("encounter_id", "")))
		seq.append(s.get_cleared_count())
	var mono: bool = true
	for i: int in range(1, seq.size()):
		if seq[i] < seq[i - 1]:
			mono = false
	var expected: Array[int] = [0, 1, 2, 3, 4]
	_ck("cleared_count_monotonic", mono and seq == expected,
		"区域清除进度序列 %s 单调递增（只增不减）" % str(seq))
	_ck("cleared_ids_all_true", s.is_cleared("enc_limgrave_gatefront") \
		and s.is_cleared("enc_weeping_shore") and s.is_cleared("enc_stormveil_gate") \
		and s.is_cleared("enc_siofra_well_entry"),
		"4 个已清除遭遇 is_cleared() 均为 true")


## E) 异常输入拒绝 / config 缺失 / 异常后正常流程 / 拒绝信号
func _test_abnormal_inputs() -> void:
	var cfg: WorldEncounterConfig = _load_config()
	# config 缺失
	var sn: WorldEncounterService = _make_service(null)
	var a0: Dictionary = sn.enter_region("limgrave")
	var a1: Dictionary = sn.try_trigger(Vector2(512, 384))
	_ck("no_config_reject", not bool(a0.get("ok")) and not bool(a1.get("ok")) \
		and str(a0.get("reason")) == "no_config" and str(a1.get("reason")) == "no_config",
		"config=null -> enter_region / try_trigger 均 no_config 拒绝（不崩）")
	# 异常 enter_region
	var s: WorldEncounterService = _make_service(cfg)
	var bad_enter: Array = [null, 123, "", "unknown_region"]
	var enter_all_rejected: bool = true
	for v: Variant in bad_enter:
		var r: Dictionary = s.enter_region(v)
		if bool(r.get("ok")) or (str(r.get("reason")) != "invalid_input" and str(r.get("reason")) != "no_region"):
			enter_all_rejected = false
	_ck("invalid_enter_region_all_rejected", enter_all_rejected,
		"enter_region(null/int/空串/未注册) 全部拒绝（4 类）")
	# 未进入区域直接 try_trigger
	var s2: WorldEncounterService = _make_service(cfg)
	var nr: Dictionary = s2.try_trigger(Vector2(512, 384))
	_ck("try_trigger_without_region", not bool(nr.get("ok")) \
		and str(nr.get("reason")) == "no_region",
		"未 enter_region -> try_trigger 返回 no_region")
	# 异常 position
	var s3: WorldEncounterService = _make_service(cfg)
	s3.enter_region("limgrave")
	var bad_pos: Array = [null, "512,384", Vector3(512, 384, 0),
		Vector2(NAN, 0.0), Vector2(INF, 0.0), Vector2(0.0, NAN)]
	var pos_all_rejected: bool = true
	for v: Variant in bad_pos:
		var r: Dictionary = s3.try_trigger(v)
		if bool(r.get("ok")) or str(r.get("reason")) != "invalid_input":
			pos_all_rejected = false
	_ck("invalid_position_all_rejected", pos_all_rejected,
		"try_trigger(null/字符串/Vector3/NaN/Inf) 全部 invalid_input 拒绝（6 类）")
	_ck("invalid_position_state_clean", str(s3.get_snapshot().get("active_encounter")) == "" \
		and int(s3.get_snapshot().get("trigger_count")) == 0,
		"异常输入拒绝后不改状态（active 空 / trigger_count=0）")
	# 异常 on_encounter_cleared
	var bad_clear: Array = [null, 123, "", "not_exist_id", "enc_limgrave_chapel"]
	var clear_all_rejected: bool = true
	for v: Variant in bad_clear:
		var r: Dictionary = s3.on_encounter_cleared(v)
		if bool(r.get("ok")):
			clear_all_rejected = false
	_ck("invalid_cleared_all_rejected", clear_all_rejected,
		"on_encounter_cleared(null/int/空/不存在/非 active) 全部拒绝（5 类）")
	_ck("trigger_rejected_signal", _sig_rejected >= 4 and _sig_last_reject != "",
		"trigger_rejected 信号被发、reason 记录正确")
	# 异常后正常流程仍成功（状态未被污染）
	var ok_en: Dictionary = s3.enter_region("limgrave")
	var ok_t: Dictionary = s3.try_trigger(Vector2(512, 384))
	_ck("invalid_then_normal_ok", bool(ok_en.get("ok")) and bool(ok_t.get("ok")) \
		and int(ok_t.get("reward_points")) == 80,
		"异常输入拒绝后正常 enter+trigger 仍命中 gatefront、reward=80")


## F) 非法表一律 is_valid()=false（不崩）
func _test_illegal_tables() -> void:
	var base_row: Dictionary = {
		"id": "enc_x", "region_id": "limgrave",
		"position": Vector2(1, 1), "enemy_group": "enemy_01_limgrave_soldier",
		"trigger_radius": 10.0, "cleared_flag": false, "reward_points": 10,
	}
	var cases: Array = []
	var r1: Dictionary = base_row.duplicate(); r1.erase("trigger_radius")
	cases.append(_mk_bad_table([r1], "reject"))
	var r2a: Dictionary = base_row.duplicate(); r2a["id"] = "dup"
	var r2b: Dictionary = base_row.duplicate(); r2b["id"] = "dup"
	cases.append(_mk_bad_table([r2a, r2b], "reject"))
	var r3: Dictionary = base_row.duplicate(); r3["region_id"] = "unknown"
	cases.append(_mk_bad_table([r3], "reject"))
	var r4: Dictionary = base_row.duplicate(); r4["trigger_radius"] = 0.0
	cases.append(_mk_bad_table([r4], "reject"))
	var r5: Dictionary = base_row.duplicate(); r5["reward_points"] = -5
	cases.append(_mk_bad_table([r5], "reject"))
	var r7: Dictionary = base_row.duplicate(); r7["position"] = "not_a_vector2"
	cases.append(_mk_bad_table([r7], "reject"))
	var r8: Dictionary = base_row.duplicate(); r8["reward_points"] = 1.5
	cases.append(_mk_bad_table([r8], "reject"))
	cases.append(_mk_bad_table([base_row.duplicate()], "clamp"))
	var all_invalid: bool = true
	for item: Variant in cases:
		var c: WorldEncounterConfig = item as WorldEncounterConfig
		if c.is_valid():
			all_invalid = false
	_ck("illegal_tables_all_rejected", all_invalid and cases.size() == 8,
		"8 类非法表（缺字段/id 重复/未注册 region/radius<=0/reward<0/position 非 Vector2/reward 非整数/policy 非 reject）is_valid()=false")
	# 合法表仍 true（对照）
	_ck("legal_table_still_valid", _load_config().is_valid(),
		"对照：真实 .tres 表 is_valid()=true")


func _mk_bad_table(rows: Array, policy: String) -> WorldEncounterConfig:
	var c: WorldEncounterConfig = WorldEncounterConfig.new()
	c.region_ids = PackedStringArray(["limgrave", "weeping_peninsula", "stormveil", "siofra_well"])
	var arr: Array[Dictionary] = []
	for r: Variant in rows:
		arr.append((r as Dictionary).duplicate())
	c.encounters = arr
	c.invalid_input_policy = policy
	return c


## G) reset 复位 + 纯逻辑边界（I-1）+ A48① 生产订阅者静态证据
func _test_reset_and_purity() -> void:
	var cfg: WorldEncounterConfig = _load_config()
	var s: WorldEncounterService = _make_service(cfg)
	s.enter_region("limgrave")
	s.try_trigger(Vector2(512, 384))
	s.on_encounter_cleared("enc_limgrave_gatefront")
	var before: Dictionary = s.get_snapshot()
	_ck("pre_reset_state_nonempty", int(before.get("cleared_count")) == 1 \
		and int(before.get("trigger_count")) == 1,
		"reset 前状态非空（cleared_count=1 / trigger_count=1）")
	s.reset()
	var after: Dictionary = s.get_snapshot()
	_ck("reset_clears_all", str(after.get("current_region")) == "" \
		and str(after.get("active_encounter")) == "" \
		and int(after.get("cleared_count")) == 0 \
		and int(after.get("trigger_count")) == 0 and int(after.get("reject_count")) == 0,
		"reset() 回构造初始态（当前分区/active/清除进度/计数全清）")
	# 纯逻辑：service 源码（剥离注释，避免命中头注里「不 add_child」等否定声明）
	# 不含存档 / 场景树 / 渲染 API。
	var svc_code: String = _code_only(_src(SERVICE_PATH))
	_ck("pure_logic_no_save_api", not svc_code.contains("set_flag") \
		and not svc_code.contains("commit(") and not svc_code.contains("add_child") \
		and not svc_code.contains("get_tree()") and not svc_code.contains("/root/") \
		and not svc_code.contains("removals") and not svc_code.contains("open("),
		"service 源码（去注释）不含 set_flag/commit/add_child/get_tree()/root/removals/open（I-1 不读写存档）")
	# config 源码不含设计数值硬编码（数值在 .tres）
	var cfg_src: String = _src(CONFIG_PATH)
	_ck("config_no_design_numbers", not cfg_src.contains("Vector2(512, 384)") \
		and not cfg_src.contains("reward_points\": 80"),
		"config 源码不写死设计数值（调参唯一入口在 .tres）")
	# A48①：生产源码（director）含 4 信号订阅者 + 唯一实例 getter + 结算接线 + 驱动口
	var d_src: String = _src(DIRECTOR_PATH)
	_ck("production_subscriber_in_source", d_src.contains("_bind_world_encounter_signals") \
		and d_src.contains("get_world_encounter_service") \
		and d_src.contains("base_for_combo + _world_reward_acc") \
		and d_src.contains("_mark_world_cleared_on_wave") \
		and d_src.contains("enter_world_region") and d_src.contains("try_world_encounter") \
		and d_src.contains("encounter_triggered"),
		"生产源码含 4 信号订阅者 + 唯一实例 getter + 奖励并入结算 + 清波标记清除 + 驱动口（A48①/A54/A57）")


func _src(res_path: String) -> String:
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	var txt: String = FileAccess.get_file_as_string(abs_path)
	if txt.is_empty():
		txt = FileAccess.get_file_as_string(res_path)
	return txt


## 逐行剥离 `#` 注释（本工程源码无含 `#` 的字符串字面量），供「禁止 API」静态判定
## 只检查真正的代码，不误伤头注里「不 add_child / 不取 root」等否定声明。
func _code_only(src: String) -> String:
	var kept: PackedStringArray = PackedStringArray()
	for line: String in src.split("\n"):
		var idx: int = line.find("#")
		if idx >= 0:
			line = line.substr(0, idx)
		kept.append(line)
	return "\n".join(kept)


func _finish() -> void:
	print("[V150-WE] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V150-WE] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V150-WE] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V150-WE] === SELFTEST END ===")
	quit(0 if all_ok else 1)
