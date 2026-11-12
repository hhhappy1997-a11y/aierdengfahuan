extends SceneTree

## ===========================================================================
## R34 / v0.11.0 · 「抉择消费方接线 + 连击倍率并入清波结算」生产级自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_production_settlement_v110.gd
##
## 覆盖（任务单 ③）：
##   - 抉择代价生效：select_boon(2) 清波后，下一波「波次开始」消费到
##     cost_key=hp_scale / effect_key=points_bonus / cost_value=1.20；
##   - 连击倍率：注入 14 连击（A 级 1.6）-> 清波结算 100 -> 160；
##   - 组合：boon points_bonus +60 且 A 级 1.6 -> 160 -> 256；Boss 死亡结算 S 级 -> 200；
##   - 点数单调、余额非负、不重复结算（重复 on_encounter_finished 被既有门控拒绝）；
##   - 既有输出格式零改动：wave_cleared(index, points) 仍发基础 pts=100、
##     get_snapshot() 既有 27 个 key 逐字仍在；
##   - md5 前后对比证明既有 .tres 零改动（外加本轮新表同样未被脚本写入）。
##
## 【--script 模式纪律 / 不写生产存档】
## - 用 Engine.get_main_loop() as SceneTree 取 root：add_child(d) 后显式
##   d.call("_ready")（--script 模式 add_child 不 flush _ready）；不用 get_tree()、
##   不用 /root/... 绝对路径。
## - 夹具显式 d.set_process(false) + auto_start=false + bind_persistence(null,null)，
##   完全靠 debug_advance / on_encounter_finished 确定性驱动，禁止自动 _process 抖动；
##   bind_persistence 显式降级后 _persist_settle 恒返回 false，**绝不写生产 delta.json**。
## - 全程只读 ResourceLoader.load(CACHE_MODE_IGNORE)；不碰渲染、不启 GPU job。
## 输出逐条 PASS=true/false + SUMMARY + OVERALL=PASS/FAIL + RESULT=ALL_MATCH；失败 quit(1)。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const DIRECTOR_PATH: String = "res://scripts/combat/wave_trial_director.gd"

## 既有表（本轮只读、零改动）；md5 前后对比的「既有表零改动」证据主体。
const WATCHED_EXISTING: Array = [
	"res://data/rpg/wave_trial.tres",
	"res://data/rpg/boon_draft.tres",
	"res://data/rpg/trial_modifiers.tres",
	"res://data/combat/stagger_rules.tres",
]
## 本轮新表（非「既有表」，但同样证明验证脚本只读、未改写任何 .tres）。
const WATCHED_NEW: Array = ["res://data/rpg/combo_rules.tres"]

## 两波 / 单波夹具（配置注入，不依赖真实落盘波表的 3 波数值）。
const WAVES: Array = [
	{"telegraph": 1.0, "time_limit": 30.0, "points": 100},
	{"telegraph": 1.0, "time_limit": 30.0, "points": 150},
]
const WAVES_ONE: Array = [
	{"telegraph": 1.0, "time_limit": 30.0, "points": 100},
]
const TG: float = 1.0

var _pass: int = 0
var _fail: int = 0
var _md5_before: Dictionary = {}
var _root: Node = null

## wave_cleared 信号 payload（验证「输出格式未改」：仍发基础 pts）。
var _wc_count: int = 0
var _wc_index: int = -1
var _wc_points: int = -1


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V110-PS] %s PASS=%s | %s" % [tag, str(ok), detail])


func _md5(res_path: String) -> String:
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	var m: String = FileAccess.get_md5(abs_path)
	if m.is_empty():
		m = FileAccess.get_md5(res_path)
	return m


func _on_wave_cleared(index: int, points: int) -> void:
	_wc_count += 1
	_wc_index = index
	_wc_points = points


func _reset_wc() -> void:
	_wc_count = 0
	_wc_index = -1
	_wc_points = -1


## 确定性夹具：加载 director 脚本 -> new -> add_child(root) -> 显式 _ready ->
## 关闭自动 _process / 自动开始 / 持久化 -> 注入波次配置。绝不写生产存档。
func _make_director(waves: Array) -> Node:
	var s: GDScript = ResourceLoader.load(
		DIRECTOR_PATH, "Script", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
	_ck("director_script_load_cache_ignore", s != null, "path=%s" % DIRECTOR_PATH)
	if s == null:
		return null
	var d: Node = s.new() as Node
	_root.add_child(d)
	d.set("auto_start", false)
	d.call("set_external_driver", true)
	d.call("_ready")
	d.set_process(false)
	d.call("bind_persistence", null, null)
	var snap_init = d.call("get_snapshot")
	_ck("persist_explicitly_downgraded", snap_init["persist_available"] == false,
		"bind_persistence(null,null) -> persist_available=false（不写生产存档）")
	_ck("configure_waves_ok", bool(d.call("configure_waves", waves)),
		"注入 %d 波夹具（不读真实 3 波的战斗数值）" % waves.size())
	return d


## 推进到 WAVE_ACTIVE 并清波（真实 wave_cleared 时刻）。
func _drive_clear(d: Node, tg: float) -> void:
	d.call("start_trial")
	d.call("debug_advance", tg)
	d.call("on_encounter_finished", true)


func _initialize() -> void:
	print("[V110-PS] === SELFTEST START ===")
	var ml: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = ml as SceneTree
	_root = tree.root if tree != null else null
	_ck("scene_tree_root_via_main_loop", tree != null and _root != null,
		"Engine.get_main_loop() as SceneTree -> root，不用 get_tree()/绝对路径")
	if _root == null:
		_finish()
		return

	# ---- md5 前：记录既有表 + 本轮新表的落盘真值 ----
	for p: String in (WATCHED_EXISTING + WATCHED_NEW) as Array:
		_md5_before[p] = _md5(p)
		var before: String = str(_md5_before[p])
		_ck("md5_before_%s_nonempty" % p.get_file(), not before.is_empty(),
			"%s md5(before)=%s" % [p.get_file(), before])

	_test_baseline()                     # 基线：无抉择 / 0 连击 -> 100
	_test_combo_multiplier()             # 连击倍率：A 级 -> 160 + 输出格式未改
	_test_boon_cost_applies()            # 抉择代价生效 + points_bonus
	_test_combo_plus_boon()              # 组合：boon +60 且 A 级 1.6 -> 256
	_test_monotonic_and_no_double()      # 点数单调 / 余额非负 / 不重复结算
	_test_boss_defeated_settle()         # Boss 死亡结算：S 级 -> 200
	_test_legacy_snapshot_keys()         # get_snapshot() 既有 27 个 key 逐字仍在

	# ---- md5 后：证明本件全程只读、既有表零改动 ----
	var existing_all_same: bool = true
	for p: String in (WATCHED_EXISTING + WATCHED_NEW) as Array:
		var before: String = str(_md5_before.get(p, ""))
		var after: String = _md5(p)
		print("[V110-PS] MD5 %s before=%s after=%s" % [p.get_file(), before, after])
		var same: bool = before == after and not after.is_empty()
		_ck("md5_zero_change_%s" % p.get_file(), same,
			"%s 前后 md5 一致（零改动）" % p.get_file())
		for q: String in WATCHED_EXISTING:
			if p == q and not same:
				existing_all_same = false
	_ck("existing_tables_zero_change", existing_all_same,
		"4 份既有 .tres（wave_trial / boon_draft / trial_modifiers / stagger_rules）前后 md5 全部一致")
	_finish()


## A) 基线：无抉择 / 0 连击 -> D 级倍率 1.0，结算点数 = 基础 100
func _test_baseline() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	_drive_clear(d, TG)
	var s = d.call("get_snapshot")
	_ck("baseline_settled_100", int(s.get("last_settled_points")) == 100,
		"无抉择 / 0 连击 -> settled=100（D 级 mult=1.0，与既有等价）")
	_ck("baseline_combo_rank_D", str(s.get("combo_rank")) == "D" \
		and is_equal_approx(float(s.get("combo_multiplier")), 1.0),
		"combo_rank=D / combo_multiplier=1.0 [PLACEHOLDER]")
	_ck("baseline_combo_service_present", d.call("get_combo_service") != null \
		and d.call("get_boon_service") != null,
		"两个纯逻辑服务已装配（combo_rules.tres / boon_draft.tres 真表回读）")
	_ck("baseline_no_boon_cost", str(s.get("boon_cost_key")) == "" \
		and str(s.get("boon_effect_key")) == "",
		"未抉择 -> 无 cost_key / effect_key 生效（抉择代价未凭空出现）")


## B) 连击倍率：14 连击 -> A 级 1.6 -> 100*1.6=160；wave_cleared 输出格式未改
func _test_combo_multiplier() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	_reset_wc()
	d.connect("wave_cleared", Callable(self, "_on_wave_cleared"))
	d.call("start_trial")
	var combo = d.call("get_combo_service")
	for i: int in range(14):
		combo.call("register_hit", 10.0)
	d.call("debug_advance", TG)
	d.call("on_encounter_finished", true)
	var s = d.call("get_snapshot")
	_ck("combo_mult_settled_160", int(s.get("last_settled_points")) == 160,
		"14 连击 A 级 1.6 -> settled=160（100*1.6）[PLACEHOLDER]")
	_ck("combo_rank_A", str(s.get("combo_rank")) == "A" \
		and is_equal_approx(float(s.get("combo_multiplier")), 1.6) \
		and int(s.get("combo_count")) == 14,
		"combo_rank=A / multiplier=1.6 / combo_count=14")
	_ck("combo_points_total_160", int(s.get("points_total")) == 160,
		"points_total=160（评级倍率已并入清波点数结算）")
	# 既有输出格式：wave_cleared(index, points) 仍发基础 pts=100（不是 160）
	_ck("wave_cleared_format_unchanged", _wc_count == 1 and _wc_index == 0 \
		and _wc_points == 100,
		"wave_cleared(index=0, points=100) 仍发基础 pts，既有输出格式/语义未改")
	_ck("settlement_count_1", int(s.get("settlement_count")) == 1,
		"本波仅结算 1 次（不重复结算）")


## C) 抉择代价生效：select_boon(2) 清波 -> 下一波波次开始消费 cost_key / effect_key
func _test_boon_cost_applies() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	d.call("start_trial")
	var sel: Dictionary = d.call("select_boon", 2)
	_ck("boon_select_2_ok", bool(sel.get("ok")), "select_boon(2) 选中恩典供奉（points_bonus / hp_scale）")
	d.call("debug_advance", TG)
	d.call("on_encounter_finished", true)
	var sc = d.call("get_snapshot")
	_ck("boon_points_bonus_160", int(sc.get("last_settled_points")) == 160,
		"points_bonus=60 -> settled=160（100+60，combo D 级 1.0）[PLACEHOLDER]")
	var boon_after = d.call("get_boon_service")
	_ck("boon_consumed_and_reset", not bool(boon_after.call("has_selection")) \
		and not bool(boon_after.call("is_settled")),
		"apply()/settle() 已消费并 reset（本波抉择不重复结算、可重新三选一）")
	# 推进：WAVE_CLEARED -> NEXT_WAVE -> 第 2 波 TELEGRAPH（真实「波次开始」）
	d.call("debug_advance", 0.0)
	d.call("debug_advance", 0.0)
	var s = d.call("get_snapshot")
	_ck("boon_cost_key_active_next_wave", str(s.get("boon_cost_key")) == "hp_scale",
		"下一波波次开始消费 cost_key=hp_scale（抉择代价生效）")
	_ck("boon_effect_key_active_next_wave", str(s.get("boon_effect_key")) == "points_bonus",
		"下一波波次开始消费 effect_key=points_bonus")
	_ck("boon_cost_value_1_20", is_equal_approx(float(s.get("boon_cost_value")), 1.20),
		"cost_value=1.20 [PLACEHOLDER]（作用到下一波的乘性修正）")
	_ck("boon_state_after_wave2", int(s.get("index")) == 1,
		"已进入第 2 波（index=1）")


## D) 组合：boon +60 且 14 连击 A 级 1.6 -> 160*1.6=256
func _test_combo_plus_boon() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	d.call("start_trial")
	d.call("select_boon", 2)
	var combo = d.call("get_combo_service")
	for i: int in range(14):
		combo.call("register_hit", 10.0)
	d.call("debug_advance", TG)
	d.call("on_encounter_finished", true)
	var s = d.call("get_snapshot")
	_ck("combo_plus_boon_256", int(s.get("last_settled_points")) == 256,
		"boon +60 -> base=160，A 级 1.6 -> settled=256（两机制都并入、不叠乘其它层）")
	_ck("combo_plus_boon_rank_A", str(s.get("combo_rank")) == "A" \
		and int(s.get("points_total")) == 256,
		"评级 A / points_total=256")


## E) 点数单调 / 余额非负 / 不重复结算
func _test_monotonic_and_no_double() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	d.call("start_trial")
	d.call("debug_advance", TG)
	var s0 = d.call("get_snapshot")
	var p0: int = int(s0.get("points_total"))
	d.call("on_encounter_finished", true)
	var s1 = d.call("get_snapshot")
	var p1: int = int(s1.get("points_total"))
	_ck("points_monotonic_increase", p1 > p0 and p1 >= 0,
		"清波后 points_total %d -> %d（只增不减、非负）" % [p0, p1])
	_ck("balance_nonneg", int(s1.get("last_settled_points")) >= 0,
		"last_settled_points=%d >= 0（余额非负）" % int(s1.get("last_settled_points")))
	var rej0: int = int(s1.get("rejected_finishes"))
	d.call("on_encounter_finished", true)   # 重复触发：既有 WAVE_ACTIVE 门控拒绝
	var s2 = d.call("get_snapshot")
	_ck("no_double_settle", int(s2.get("points_total")) == p1 \
		and int(s2.get("settlement_count")) == 1 \
		and int(s2.get("rejected_finishes")) == rej0 + 1,
		"重复 on_encounter_finished -> 拒绝（points 不变、settlement_count=1、rejected_finishes+1）")
	_ck("monotonic_after_duplicate", int(s2.get("points_total")) >= p1,
		"重复触发后点数仍不回退")


## F) Boss 死亡结算：单波夹具，22 连击 S 级 2.0 -> 200
func _test_boss_defeated_settle() -> void:
	var d: Node = _make_director(WAVES_ONE)
	if d == null:
		return
	d.call("start_trial")
	var combo = d.call("get_combo_service")
	for i: int in range(22):
		combo.call("register_hit", 10.0)
	d.call("debug_advance", TG)
	d.call("on_encounter_finished", true)
	var s = d.call("get_snapshot")
	_ck("boss_defeated_settle_S_200", int(s.get("last_settled_points")) == 200 \
		and str(s.get("combo_rank")) == "S" \
		and is_equal_approx(float(s.get("combo_multiplier")), 2.0),
		"单波（Boss 波）死亡结算：S 级 2.0 -> 100*2.0=200 [PLACEHOLDER]")
	_ck("boss_defeated_service_flag", bool(combo.call("is_boss_defeated")) \
		and bool(combo.call("is_settled")),
		"ComboService 已定格并结算（Boss 死亡后不再接受命中 / 不重复结算）")


## G) 既有输出格式零改动：get_snapshot() 既有 27 个 key 逐字仍在
func _test_legacy_snapshot_keys() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	var s = d.call("get_snapshot")
	var legacy_keys: Array = [
		"state", "state_name", "index", "total", "remaining", "points_total", "best_wave",
		"degraded", "degrade_reason", "grace_rests", "timeouts", "failures",
		"rejected_finishes", "start_rejects", "started_waves", "cleared_waves",
		"hud_text", "auto_start", "has_external_driver", "is_trial_active",
		"tutorial_frozen", "persist_available", "persist_downgrade_reason",
		"grace_trial_points", "wave_trial_completed", "persist_events", "commit_count",
	]
	var all_present: bool = true
	for k: String in legacy_keys:
		if not s.has(k):
			all_present = false
	_ck("legacy_snapshot_keys_all_present", all_present and legacy_keys.size() == 27,
		"get_snapshot() 既有 27 个 key 逐字仍在（只新增 R34 只读 key，不改既有）")
	var ss = d.call("get_settlement_snapshot")
	_ck("settlement_snapshot_api", ss.has("last_settled_points"),
		"get_settlement_snapshot() 新增只读接口可用")


func _finish() -> void:
	print("[V110-PS] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V110-PS] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V110-PS] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V110-PS] === SELFTEST END ===")
	quit(0 if all_ok else 1)
