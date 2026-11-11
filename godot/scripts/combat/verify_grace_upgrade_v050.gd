extends SceneTree

## ===========================================================================
## R27 / v0.5.0 · 赐福成长「点数兑换」自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_grace_upgrade_v050.gd
## 覆盖（任务单 ⑤）：正常购买 / 点数不足 / 重复购买 / 空表·字段缺失 /
##   余额非负 / 异常输入；并实证三段式 flag 语义（spent_points 单调递增、
##   绝不回退 points、绝不 removals）与三项运行时接线（HP 上限 / 翻滚无敌 / 攻击力）。
## 输出逐条 PASS=true/false + SUMMARY pass/fail + RESULT；失败 quit(1)，不伪造 PASS。
## 期望值来自任务单 ② 首版 [PLACEHOLDER]，试玩校准后需同步更新 EXPECT_* 与
##   GRACE-UPGRADE-TUNING.md §1，不静默改数。
## 读表统一走 CACHE_MODE_IGNORE，校验落盘真值而非缓存。
## ===========================================================================

const CONFIG_PATH: String = "res://data/rpg/grace_upgrades.tres"
const PLAYER_TABLE_PATH: String = "res://data/combat/player_actions.tres"
const ENCOUNTER_SCRIPT_PATH: String = "res://scripts/combat/encounter_director.gd"
const WORLD_STATE_SCRIPT_PATH: String = "res://scripts/rpg/world_state.gd"

const FIELD_KEYS: Array = ["id", "display_name", "cost", "effect_key", "effect_value"]

# [PLACEHOLDER] R27 首版期望（任务单 ②），校验基准，不写进数据表；待人工试玩校准。
const EXPECT_IDS: Array = ["hp_max_bonus", "roll_iframe_bonus", "attack_power_bonus"]
const EXPECT_NAMES: Array = ["赐福·生命上限", "赐福·翻滚余韵", "赐福·攻击强化"]
const EXPECT_COSTS: Array = [100, 200, 300]
const EXPECT_KEYS: Array = ["hp_max", "roll_iframe", "attack_power"]
const EXPECT_VALUES: Array = [20.0, 1.0, 5.0]

const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"

var _pass: int = 0
var _fail: int = 0
## 手动 new() 的 Node 临时实例统一登记，_finish() 退出前 free，
## 避免 --script 模式退出时「ObjectDB instances were leaked / resources still in use」。
var _temps: Array[Node] = []


func _track(n: Node) -> void:
	_temps.append(n)


## 显式注入的 SaveDeltaWriter 替身：只记录 commit(reason)，不写 user:// 盘，
## 使 verify 可实证「先 set_flag 后 commit」链路而不污染存档。
class FakeWriter extends Node:
	var commits: Array[String] = []

	func commit(reason: String) -> void:
		commits.append(reason)


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V050] %s PASS=%s | %s" % [tag, str(ok), detail])


func _good_row() -> Dictionary:
	return {
		"id": "hp_max_bonus",
		"display_name": "赐福·生命上限",
		"cost": 100,
		"effect_key": "hp_max",
		"effect_value": 20.0,
	}


func _find_action(table: Resource, pose: String) -> PlayerActionData:
	var raw: Variant = table.get("actions")
	if typeof(raw) != TYPE_ARRAY:
		return null
	for a: Variant in (raw as Array):
		var action: PlayerActionData = a as PlayerActionData
		if action != null and action.pose_name == pose:
			return action
	return null


func _initialize() -> void:
	print("[V050] === SELFTEST START ===")
	var cfg: GraceUpgradeConfig = ResourceLoader.load(
		CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as GraceUpgradeConfig
	_ck("table_load_cache_ignore", cfg != null, "path=%s" % CONFIG_PATH)
	if cfg == null:
		_finish()
		return
	_test_structure_and_landings(cfg)
	_test_normal_purchase()
	_test_insufficient()
	_test_duplicate()
	_test_empty_and_missing(cfg)
	_test_balance_nonneg()
	_test_abnormal_input()
	_test_flag_semantics()
	_test_runtime_wiring(cfg)
	_finish()


## A) 表结构 / 逐字段首版 [PLACEHOLDER] / 合法性 / effect_key 既有落点 / flag key 正则
func _test_structure_and_landings(cfg: GraceUpgradeConfig) -> void:
	_ck("upgrade_count_3", cfg.upgrade_count() == 3 and cfg.upgrades.size() == 3,
		"count=%d size=%d" % [cfg.upgrade_count(), cfg.upgrades.size()])
	for i: int in range(3):
		var row: Dictionary = cfg.upgrades[i] as Dictionary
		var missing: Array[String] = []
		for k: String in FIELD_KEYS:
			if not row.has(k):
				missing.append(k)
		_ck("fields[%d]" % i, missing.is_empty(), "keys=%d missing=%s" % [row.size(), str(missing)])
		_ck("id[%d]" % i, str(row.get("id")) == str(EXPECT_IDS[i]),
			"got=%s expect=%s" % [str(row.get("id")), str(EXPECT_IDS[i])])
		_ck("name[%d]" % i, str(row.get("display_name")) == str(EXPECT_NAMES[i]),
			"got=%s expect=%s" % [str(row.get("display_name")), str(EXPECT_NAMES[i])])
		_ck("cost[%d]" % i, int(row.get("cost")) == int(EXPECT_COSTS[i]),
			"got=%s expect=%s" % [str(row.get("cost")), str(EXPECT_COSTS[i])])
		_ck("effect_key[%d]" % i, str(row.get("effect_key")) == str(EXPECT_KEYS[i]),
			"got=%s expect=%s" % [str(row.get("effect_key")), str(EXPECT_KEYS[i])])
		_ck("effect_value[%d]" % i, float(row.get("effect_value")) == float(EXPECT_VALUES[i]),
			"got=%s expect=%s" % [str(row.get("effect_value")), str(EXPECT_VALUES[i])])
		_ck("valid[%d]" % i, cfg.is_upgrade_valid(cfg.get_upgrade(i)), "is_upgrade_valid=true")
	var all_known: bool = true
	for i: int in range(3):
		if not cfg.is_known_effect_key(str(EXPECT_KEYS[i])):
			all_known = false
	_ck("effect_keys_all_known", all_known, "hp_max / roll_iframe / attack_power 均在白名单")
	_ck("make_upgrade_5_fields", cfg.make_upgrade("x", "n", 1, "hp_max", 1.0).size() == 5, "size=5")
	_ck("bounds_negative_rejected", cfg.get_upgrade(-1) == null, "get_upgrade(-1)=null")
	_ck("bounds_index3_rejected", cfg.get_upgrade(3) == null, "get_upgrade(3)=null")
	# 既有落点核对：三个 effect_key 都必须能在既有数据表 / 导演层找到对应落点。
	var table: Resource = load(PLAYER_TABLE_PATH) as Resource
	_ck("landing_player_actions_exists", table != null, "path=%s" % PLAYER_TABLE_PATH)
	var roll: PlayerActionData = _find_action(table, "roll")
	_ck("landing_roll_iframe_13", roll != null and roll.invulnerable_start_frame == 4 \
		and roll.invulnerable_end_frame == 13,
		"roll iframe=[4,13) got=[%d,%d)" % [
			roll.invulnerable_start_frame if roll != null else -1,
			roll.invulnerable_end_frame if roll != null else -1])
	var light: PlayerActionData = _find_action(table, "attack_light")
	_ck("landing_attack_power_85", light != null and light.base_attack == 85.0,
		"base_attack=%s" % (str(light.base_attack) if light != null else "null"))
	var enc_script: Script = load(ENCOUNTER_SCRIPT_PATH) as Script
	var enc_probe: Node = Node.new()
	_track(enc_probe)
	enc_probe.set_script(enc_script)
	var has_hp_prop: bool = false
	for p: Dictionary in enc_probe.get_property_list():
		if String(p.get("name", "")) == "player_max_hp":
			has_hp_prop = true
			break
	_ck("landing_hp_max_player_max_hp", has_hp_prop,
		"EncounterDirector @export player_max_hp 存在")
	_ck("landing_hp_max_public_method", enc_probe.has_method("trial_grace_rest"),
		"公开方法 trial_grace_rest() 存在")
	# 三段式 flag key 全部符合 WorldState FLAG_KEY_REGEX。
	var re: RegEx = RegEx.new()
	re.compile(FLAG_KEY_REGEX)
	var keys_ok: bool = true
	var check_keys: Array[String] = [
		GraceUpgradeService.FLAG_POINTS,
		GraceUpgradeService.FLAG_SPENT_POINTS,
		GraceUpgradeService.purchased_flag_key(str(EXPECT_IDS[0])),
		GraceUpgradeService.purchased_flag_key(str(EXPECT_IDS[1])),
		GraceUpgradeService.purchased_flag_key(str(EXPECT_IDS[2])),
	]
	for k: String in check_keys:
		if re.search(k) == null:
			keys_ok = false
	_ck("flag_keys_three_segment_regex", keys_ok,
		"5 个 key 全部匹配 ^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$")


## B) 正常购买：1000 点依次买 100/200/300，spent 累计 600、余额 400、points 不变
func _test_normal_purchase() -> void:
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	var r0: Dictionary = svc.purchase(1000, 0, _good_row())
	_ck("normal_buy_hp_ok", bool(r0.get("ok")), "reason=%s" % str(r0.get("reason")))
	_ck("normal_buy_hp_reason_ok", str(r0.get("reason")) == GraceUpgradeService.REASON_OK, "reason=ok")
	_ck("normal_buy_hp_spent_100", int(r0.get("spent_points")) == 100, "spent=%s" % str(r0.get("spent_points")))
	_ck("normal_buy_hp_balance_900", int(r0.get("balance")) == 900, "balance=%s" % str(r0.get("balance")))
	_ck("normal_buy_hp_points_unchanged", int(r0.get("points")) == 1000, "points=%s（只读，绝不回退）" % str(r0.get("points")))
	var r1: Dictionary = svc.purchase(1000, 100, {
		"id": "roll_iframe_bonus", "display_name": "赐福·翻滚余韵", "cost": 200,
		"effect_key": "roll_iframe", "effect_value": 1.0})
	_ck("normal_buy_roll_spent_300", bool(r1.get("ok")) and int(r1.get("spent_points")) == 300,
		"spent=%s" % str(r1.get("spent_points")))
	var r2: Dictionary = svc.purchase(1000, 300, {
		"id": "attack_power_bonus", "display_name": "赐福·攻击强化", "cost": 300,
		"effect_key": "attack_power", "effect_value": 5.0})
	_ck("normal_buy_attack_spent_600", bool(r2.get("ok")) and int(r2.get("spent_points")) == 600,
		"spent=%s" % str(r2.get("spent_points")))
	_ck("normal_buy_all_balance_400", int(r2.get("balance")) == 400, "balance=%s" % str(r2.get("balance")))
	_ck("normal_purchased_ids_3", svc.get_purchased_ids().size() == 3,
		"ids=%s" % str(svc.get_purchased_ids()))
	_ck("normal_get_spent_points_600", svc.get_spent_points() == 600, "spent=%d" % svc.get_spent_points())
	_ck("normal_can_purchase_false_when_all_owned",
		not svc.can_purchase(1000, 600, _good_row()), "三项已购后同 id 再判购买=false")


## C) 点数不足：余额 < cost 一律拒绝，spent 不变
func _test_insufficient() -> void:
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	var row: Dictionary = {
		"id": "roll_iframe_bonus", "display_name": "赐福·翻滚余韵", "cost": 200,
		"effect_key": "roll_iframe", "effect_value": 1.0}
	var r: Dictionary = svc.purchase(100, 0, row)
	_ck("insufficient_rejected", not bool(r.get("ok")), "points=100 < cost=200")
	_ck("insufficient_reason", str(r.get("reason")) == GraceUpgradeService.REASON_INSUFFICIENT,
		"reason=%s" % str(r.get("reason")))
	_ck("insufficient_spent_unchanged", int(r.get("spent_points")) == 0 and svc.get_spent_points() == 0,
		"spent 不变=0（不扣点）")
	_ck("insufficient_zero_points_reject", not svc.can_purchase(0, 0, _good_row()), "points=0 拒绝")
	_ck("balance_helper", GraceUpgradeService.balance(1000, 600) == 400, "balance(1000,600)=400")
	_ck("negative_balance_rejected",
		not svc.can_purchase(50, 100, _good_row()), "points=50 spent=100 → 余额为负，拒绝")


## D) 重复购买同一 id 必须被拒绝，且绝不重复扣点
func _test_duplicate() -> void:
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	var first: Dictionary = svc.purchase(1000, 0, _good_row())
	_ck("dup_first_ok", bool(first.get("ok")), "首次购买成功")
	var second: Dictionary = svc.purchase(1000, 100, _good_row())
	_ck("dup_second_rejected", not bool(second.get("ok")), "第二次同 id 被拒绝")
	_ck("dup_reason_duplicate", str(second.get("reason")) == GraceUpgradeService.REASON_DUPLICATE,
		"reason=%s" % str(second.get("reason")))
	_ck("dup_spent_unchanged", int(second.get("spent_points")) == 100, "spent 仍=100（不重复扣点）")
	var still_rejected: bool = true
	for _i: int in range(4):
		if bool(svc.purchase(1000, 100, _good_row()).get("ok")):
			still_rejected = false
	_ck("dup_4x_still_rejected", still_rejected, "连买 4 次仍全部拒绝")
	_ck("dup_spent_still_100", svc.get_spent_points() == 100, "spent 恒=100（幂等）")
	_ck("dup_is_purchased_true", svc.is_purchased("hp_max_bonus"), "is_purchased=true")
	_ck("dup_can_purchase_false", not svc.can_purchase(1000, 100, _good_row()), "can_purchase=false")
	# 跨「从 flag 恢复」的重复：load_state 注入已购 id 后应拒绝，且不回退 spent。
	var svc2: GraceUpgradeService = GraceUpgradeService.new()
	svc2.load_state(100, ["hp_max_bonus"])
	var r2: Dictionary = svc2.purchase(1000, 100, _good_row())
	_ck("dup_across_load_state_rejected", not bool(r2.get("ok")), "flag 恢复后同 id 仍拒绝")
	_ck("dup_across_load_state_spent_unchanged", int(r2.get("spent_points")) == 100, "spent 仍=100")


## E) 空表 / 字段缺失降级：不崩、回落 [PLACEHOLDER] 基线、缺字段判非法
func _test_empty_and_missing(cfg: GraceUpgradeConfig) -> void:
	var empty: GraceUpgradeConfig = GraceUpgradeConfig.new()
	_ck("empty_count_0", empty.upgrade_count() == 0, "count=%d" % empty.upgrade_count())
	_ck("empty_get_null", empty.get_upgrade(0) == null, "空表 get_upgrade(0)=null 不崩")
	_ck("empty_get_neg_null", empty.get_upgrade(-1) == null, "空表 get_upgrade(-1)=null")
	_ck("empty_valid_null", not cfg.is_upgrade_valid(null), "is_upgrade_valid(null)=false")
	var d0 := cfg.upgrade_from_dict({})
	_ck("missing_all_no_crash", d0 != null, "upgrade_from_dict({}) 返回视图")
	_ck("missing_all_defaults",
		d0.id == GraceUpgradeConfig.DEFAULT_ID
		and d0.display_name == GraceUpgradeConfig.DEFAULT_DISPLAY_NAME
		and d0.cost == GraceUpgradeConfig.DEFAULT_COST
		and d0.effect_key == GraceUpgradeConfig.DEFAULT_EFFECT_KEY
		and d0.effect_value == GraceUpgradeConfig.DEFAULT_EFFECT_VALUE,
		"5 字段全回落 [PLACEHOLDER] 基线")
	_ck("missing_all_invalid", not cfg.is_upgrade_valid(d0), "空 id / 空 key → 判非法")
	var partial: GraceUpgradeConfig = GraceUpgradeConfig.new()
	partial.upgrades.append({"id": "hp_max_bonus", "cost": 100, "effect_key": "hp_max", "effect_value": 20.0})
	var pv := partial.get_upgrade(0)
	_ck("half_row_no_crash", pv != null, "半行 Dictionary 不崩")
	_ck("half_row_defaults_filled",
		pv != null and pv.display_name == GraceUpgradeConfig.DEFAULT_DISPLAY_NAME,
		"缺 display_name 回落基线")
	_ck("half_row_invalid", pv != null and not cfg.is_upgrade_valid(pv), "缺 display_name → 判非法")
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	_ck("missing_svc_empty_dict_rejected", not svc.can_purchase(1000, 0, {}), "can_purchase({})=false")
	_ck("missing_svc_null_rejected", not svc.can_purchase(1000, 0, null), "can_purchase(null)=false")
	var miss: Dictionary = _good_row()
	miss.erase("effect_value")
	_ck("missing_svc_field_rejected", not svc.can_purchase(1000, 0, miss), "缺 effect_value=false")


## F) 余额非负 / spent_points 单调递增（外部传入落后值不回退累计）
func _test_balance_nonneg() -> void:
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	var ok_all: bool = true
	var nonneg: bool = true
	var spent: int = 0
	for i: int in range(3):
		var row: Dictionary = {
			"id": str(EXPECT_IDS[i]), "display_name": "x", "cost": int(EXPECT_COSTS[i]),
			"effect_key": str(EXPECT_KEYS[i]), "effect_value": float(EXPECT_VALUES[i])}
		var r: Dictionary = svc.purchase(1000, spent, row)
		if not bool(r.get("ok")):
			ok_all = false
		spent = int(r.get("spent_points"))
		if int(r.get("balance")) < 0:
			nonneg = false
	_ck("balance_all_purchases_ok", ok_all, "3 项连续购买全成功")
	_ck("balance_all_nonneg", nonneg, "每次成功购买后余额均 >= 0")
	_ck("balance_spent_le_points", svc.get_spent_points() <= 1000, "spent=%d <= points=1000" % svc.get_spent_points())
	# 关键单调性：内部累计 500，外部传入 spent=0（落后值），购买 100 后应为 600 而非 100。
	var svc2: GraceUpgradeService = GraceUpgradeService.new()
	svc2.load_state(500, [])
	var r2: Dictionary = svc2.purchase(1000, 0, _good_row())
	_ck("spent_monotonic_no_rollback", int(r2.get("spent_points")) == 600,
		"max(500,0)+100=600（外部落后值不回退）got=%s" % str(r2.get("spent_points")))
	_ck("spent_monotonic_getter", svc2.get_spent_points() == 600, "getter=600")
	_ck("negative_points_rejected", not svc2.can_purchase(-1, 0, _good_row()), "points=-1 拒绝")


## G) 异常输入：null / 非字典 / 缺字段 / 负 cost / 未知 key / 负 value / 负点数 全拒绝不崩
func _test_abnormal_input() -> void:
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	_ck("abnormal_null", not svc.can_purchase(1000, 0, null), "upgrade=null 拒绝")
	_ck("abnormal_int", not svc.can_purchase(1000, 0, 123), "upgrade=int 拒绝")
	_ck("abnormal_string", not svc.can_purchase(1000, 0, "hp_max"), "upgrade=String 拒绝")
	_ck("abnormal_empty_dict", not svc.can_purchase(1000, 0, {}), "upgrade={} 拒绝")
	var r1 := _good_row()
	r1.erase("id")
	_ck("abnormal_missing_id", not svc.can_purchase(1000, 0, r1), "缺 id 拒绝")
	var r2 := _good_row()
	r2["id"] = ""
	_ck("abnormal_empty_id", not svc.can_purchase(1000, 0, r2), "空 id 拒绝")
	var r3 := _good_row()
	r3["cost"] = -100
	_ck("abnormal_negative_cost", not svc.can_purchase(1000, 0, r3), "负 cost 拒绝")
	var r4 := _good_row()
	r4["cost"] = 0
	_ck("abnormal_zero_cost", not svc.can_purchase(1000, 0, r4), "0 cost 拒绝")
	var r5 := _good_row()
	r5["effect_key"] = "unknown_key"
	_ck("abnormal_unknown_effect_key", not svc.can_purchase(1000, 0, r5), "未知 effect_key 拒绝")
	var r6 := _good_row()
	r6["effect_value"] = -5.0
	_ck("abnormal_negative_effect_value", not svc.can_purchase(1000, 0, r6), "负 effect_value 拒绝")
	var r7 := _good_row()
	r7["cost"] = "100"
	_ck("abnormal_string_cost", not svc.can_purchase(1000, 0, r7), "cost 为字符串拒绝")
	var r8 := _good_row()
	r8["effect_value"] = "20.0"
	_ck("abnormal_string_effect_value", not svc.can_purchase(1000, 0, r8), "effect_value 为字符串拒绝")
	_ck("abnormal_negative_points", not svc.can_purchase(-1, 0, _good_row()), "points=-1 拒绝")
	_ck("abnormal_negative_spent", not svc.can_purchase(1000, -1, _good_row()), "spent_points=-1 拒绝")
	var rp: Dictionary = svc.purchase(1000, 0, null)
	_ck("abnormal_purchase_no_crash_no_spend", not bool(rp.get("ok")) and svc.get_spent_points() == 0,
		"purchase(null) 不崩、不扣点")


## H) 三段式 flag 语义：grace.trial.spent_points 单调递增、绝不回退 points、绝不 removals
func _test_flag_semantics() -> void:
	var ws_script: Script = load(WORLD_STATE_SCRIPT_PATH) as Script
	var ws: Node = Node.new()
	_track(ws)
	ws.set_script(ws_script)
	ws.call("_ready")
	_ck("mem_world_state_ready", ws.has_method("get_flag") and ws.has_method("set_flag"),
		"内存 WorldState 实例就绪（不 add_child、不写 user:// 盘）")
	ws.call("set_flag", GraceUpgradeService.FLAG_POINTS, 1000)
	_ck("flag_points_init_1000", int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)) == 1000,
		"grace.trial.points=1000（测试夹具初值）")
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var rt: GraceUpgradeRuntime = GraceUpgradeRuntime.new()
	_track(rt)
	var b0: Dictionary = rt.try_purchase("hp_max_bonus", ws, fw)
	_ck("flag_buy_hp_ok", bool(b0.get("ok")), "reason=%s" % str(b0.get("reason")))
	_ck("flag_buy_hp_spent_100", int(b0.get("spent_points")) == 100, "spent=%s" % str(b0.get("spent_points")))
	_ck("flag_buy_hp_points_still_1000", int(b0.get("points")) == 1000, "points 读回仍=1000（绝不回退）")
	_ck("flag_buy_hp_bought_flag_true",
		bool(ws.call("get_flag", GraceUpgradeService.purchased_flag_key("hp_max_bonus"), false)),
		"grace.trial.bought_hp_max_bonus=true")
	_ck("flag_buy_hp_committed", bool(b0.get("committed")), "经 writer.commit 落盘链路")
	_ck("flag_buy_hp_commit_reason", fw.commits.size() == 1 and fw.commits[0] == "grace_upgrade_purchased",
		"commit reason=%s" % str(fw.commits))
	var b0d: Dictionary = rt.try_purchase("hp_max_bonus", ws, fw)
	_ck("flag_buy_hp_duplicate_rejected", not bool(b0d.get("ok")), "重复购买同 id 被拒绝")
	_ck("flag_buy_hp_duplicate_spent_100", int(b0d.get("spent_points")) == 100, "spent 仍=100（不重复扣点）")
	var b1: Dictionary = rt.try_purchase("roll_iframe_bonus", ws, fw)
	_ck("flag_buy_roll_spent_300", bool(b1.get("ok")) and int(b1.get("spent_points")) == 300,
		"spent=%s" % str(b1.get("spent_points")))
	var b2: Dictionary = rt.try_purchase("attack_power_bonus", ws, fw)
	_ck("flag_buy_attack_spent_600", bool(b2.get("ok")) and int(b2.get("spent_points")) == 600,
		"spent=%s" % str(b2.get("spent_points")))
	_ck("flag_buy_all_balance_400", int(b2.get("balance")) == 400, "balance=%s" % str(b2.get("balance")))
	_ck("flag_points_never_rolled_back",
		int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)) == 1000,
		"全程 grace.trial.points 恒=1000（只读）")
	_ck("flag_spent_points_monotonic_600",
		int(ws.call("get_flag", GraceUpgradeService.FLAG_SPENT_POINTS, 0)) == 600,
		"grace.trial.spent_points 单调递增到 600")
	var flags_intact: bool = true
	for id: String in EXPECT_IDS:
		if not bool(ws.call("get_flag", GraceUpgradeService.purchased_flag_key(id), false)):
			flags_intact = false
	_ck("no_removals_flags_intact", flags_intact, "3 个 bought_* flag 均仍在（未 removals / 未 erase）")
	var delta_v: Variant = ws.get("_delta")
	var removals: Array = []
	if typeof(delta_v) == TYPE_DICTIONARY:
		removals = (delta_v as Dictionary).get("removals", []) as Array
	_ck("no_removals_array_empty", removals.is_empty(), "_delta.removals size=%d" % removals.size())
	_ck("flag_unknown_id_rejected", not bool(rt.try_purchase("not_exist", ws, fw).get("ok")),
		"未知 upgrade id 购买被拒绝")


## I) 运行时接线实证（裁决 A22：只经既有 @export / 公开方法；不伪造真机自动生效）
func _test_runtime_wiring(cfg: GraceUpgradeConfig) -> void:
	var table: Resource = load(PLAYER_TABLE_PATH) as Resource
	var roll_before: PlayerActionData = _find_action(table, "roll")
	var light_before: PlayerActionData = _find_action(table, "attack_light")
	_ck("wiring_before_roll_end_13", roll_before != null and roll_before.invulnerable_end_frame == 13,
		"apply 前 invulnerable_end_frame=%d" % (roll_before.invulnerable_end_frame if roll_before != null else -1))
	_ck("wiring_before_attack_85", light_before != null and light_before.base_attack == 85.0,
		"apply 前 base_attack=%s" % (str(light_before.base_attack) if light_before != null else "null"))
	# 真实 EncounterDirector 脚本实例（不调 _ready：避免触发既有 _commit 写盘；
	# _state=null 时既有 _grace_rest 会直接 return，接线仍可验证 @export）。
	var enc_script: Script = load(ENCOUNTER_SCRIPT_PATH) as Script
	var enc: Node = Node.new()
	_track(enc)
	enc.set_script(enc_script)
	_ck("wiring_before_player_max_hp_100", float(enc.get("player_max_hp")) == 100.0,
		"apply 前 @export player_max_hp=%s" % str(enc.get("player_max_hp")))
	# 构造「三项已购」的内存 flag 状态。
	var ws_script: Script = load(WORLD_STATE_SCRIPT_PATH) as Script
	var ws: Node = Node.new()
	_track(ws)
	ws.set_script(ws_script)
	ws.call("_ready")
	ws.call("set_flag", GraceUpgradeService.FLAG_POINTS, 1000)
	ws.call("set_flag", GraceUpgradeService.FLAG_SPENT_POINTS, 600)
	for id: String in EXPECT_IDS:
		ws.call("set_flag", GraceUpgradeService.purchased_flag_key(id), true)
	var rt: GraceUpgradeRuntime = GraceUpgradeRuntime.new()
	_track(rt)
	var report: Dictionary = rt.apply_purchased(enc, ws)
	_ck("wiring_report_applied_3", int(report.get("applied")) == 3,
		"applied=%s degraded=%s" % [str(report.get("applied")), str(report.get("degraded"))])
	_ck("wiring_report_degraded_0", int(report.get("degraded")) == 0, "degraded=0")
	_ck("wiring_hp_max_after_120", float(enc.get("player_max_hp")) == 120.0,
		"@export player_max_hp 100 → 120（+20）")
	_ck("wiring_roll_end_after_14", roll_before != null and roll_before.invulnerable_end_frame == 14,
		"@export invulnerable_end_frame 13 → 14（+1）")
	_ck("wiring_attack_after_90", light_before != null and light_before.base_attack == 90.0,
		"@export base_attack 85 → 90（+5）")
	var heavy: PlayerActionData = _find_action(table, "attack_heavy")
	_ck("wiring_attack_heavy_also_90", heavy != null and heavy.base_attack == 90.0,
		"attack_heavy 同步 +5")
	# 用既有 PlayerActionState 实证无敌窗口 / 攻击力确实变化（导演层读的是同一表实例）。
	var st: PlayerActionState = PlayerActionState.new(table)
	st.request("roll")
	for _i: int in range(13):
		st.tick()
	_ck("wiring_roll_iframe_runtime_invulnerable",
		st.get_frame() == 13 and st.is_invulnerable(),
		"frame=%d is_invulnerable=%s（原 e=13 时该帧应为 false，现 e=14 为 true）" % [
			st.get_frame(), str(st.is_invulnerable())])
	var st2: PlayerActionState = PlayerActionState.new(table)
	st2.request("attack_light")
	var cur: PlayerActionData = st2.get_current()
	_ck("wiring_attack_runtime_base_attack_90", cur != null and cur.base_attack == 90.0,
		"PlayerActionState.get_current().base_attack=%s" % (str(cur.base_attack) if cur != null else "null"))
	_ck("wiring_hp_via_export_and_public_method", enc.has_method("trial_grace_rest"),
		"接线经 @export player_max_hp + 既有公开方法 trial_grace_rest()")
	# 同进程重复 apply 不得重复叠加。
	var report2: Dictionary = rt.apply_purchased(enc, ws)
	_ck("wiring_idempotent_no_double_stack",
		float(enc.get("player_max_hp")) == 120.0
		and roll_before != null and roll_before.invulnerable_end_frame == 14
		and light_before != null and light_before.base_attack == 90.0,
		"重复 apply 后数值不变（applied=%s）" % str(report2.get("applied")))
	# 降级登记实证：未注入 EncounterDirector 时如实登记「数据已落、效果待接」，不伪造生效。
	var ws2: Node = Node.new()
	_track(ws2)
	ws2.set_script(ws_script)
	ws2.call("_ready")
	ws2.call("set_flag", GraceUpgradeService.purchased_flag_key("hp_max_bonus"), true)
	var rt2: GraceUpgradeRuntime = GraceUpgradeRuntime.new()
	_track(rt2)
	var rep2: Dictionary = rt2.apply_purchased(null, ws2)
	var items: Array = rep2.get("items", []) as Array
	var hp_item: Dictionary = {}
	for it: Variant in items:
		var d: Dictionary = it as Dictionary
		if str(d.get("effect_key", "")) == "hp_max":
			hp_item = d
			break
	_ck("wiring_degrade_hp_registered",
		str(hp_item.get("status", "")) == "degraded" and int(rep2.get("applied")) == 0,
		"encounter=null → hp_max status=%s applied=%s" % [str(hp_item.get("status")), str(rep2.get("applied"))])
	_ck("wiring_degrade_reason_honest",
		str(hp_item.get("reason", "")).contains("数据已落、效果待接"),
		"reason=%s" % str(hp_item.get("reason")))


func _finish() -> void:
	# 先释放手动 new() 的临时 Node，避免 --script 退出时 ObjectDB / 资源占用告警。
	for n: Node in _temps:
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	print("[V050] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	print("[V050] RESULT=%s" % ("ALL_MATCH" if _fail == 0 else "FAILED"))
	print("[V050] === SELFTEST END ===")
	quit(0 if _fail == 0 else 1)
