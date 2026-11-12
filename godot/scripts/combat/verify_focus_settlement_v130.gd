extends SceneTree

## ===========================================================================
## R36 / v0.13.0 · 「战技效果并入结算 + 点数单调 + FP 只减不增除休息 +
##                既有表 md5 零改动」生产级自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_focus_settlement_v130.gd
##
## 覆盖（任务单 ③④）：
##   - 战技成功 damage 并入清波点数结算基数，经 combo.settle() 得唯一最终结算值，
##     与 A57「HUD 从 get_last_settlement() 取值发 points_awarded」取源一致、不二次入账；
##   - 战技 poise_damage 由生产订阅者并入既有削韧记录（真实主场景经 StaggerService.apply_hit）；
##   - 两战技（低耗远程 / 高耗高削韧）分别并入、累加，不叠乘其它层；
##   - 点数单调 / 余额非负 / 不重复结算 / 每波累计清零（不重复并入）；
##   - FP 只减不增除休息：一局内连续施放 FP 单调不增，赐福休息是唯一增出口，
##     跨波不回满（专注值跨波资源）；
##   - 既有输出格式零改动：wave_cleared(index, points) 仍发基础 pts、
##     get_snapshot() 既有 27 + R34 8 + R35 8 个 key 逐字仍在；
##   - A48① 生产订阅者运行时实证（focus_spend_count / focus_points_acc）、A54 唯一实例、
##     真实生产脚本驱动（不在验证脚本内模拟编排）；
##   - md5 前后对比证明既有 .tres 零改动（本轮新表同样未被脚本写入）。
##
## 【--script 模式纪律 / 不写生产存档】
## - 用 Engine.get_main_loop() as SceneTree 取 root：add_child(d) 后显式
##   d.call("_ready")（--script 模式 add_child 不 flush _ready）；不用 get_tree()、
##   不用 /root/... 绝对路径。
## - 夹具显式 d.set_process(false) + auto_start=false + bind_persistence(null,null)，
##   完全靠 debug_advance / on_encounter_finished / spend_focus 确定性驱动，禁止自动 _process 抖动；
##   bind_persistence 显式降级后 _persist_settle 恒返回 false，**绝不写生产 delta.json**。
## - 全程只读 ResourceLoader.load(CACHE_MODE_IGNORE)；不碰渲染、不启 GPU job。
## - 驱动对象是真实生产脚本 wave_trial_director.gd（DIRECTOR_PATH 加载），不是自建替身；
##   结算值经真实 _clear_wave() 产出，不在验证脚本内模拟编排。
## 输出逐条 PASS=true/false + SUMMARY + OVERALL=PASS/FAIL + RESULT=ALL_MATCH；失败 quit(1)。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const DIRECTOR_PATH: String = "res://scripts/combat/wave_trial_director.gd"

## 既有表（本轮只读、零改动）；md5 前后对比的「既有表零改动」证据主体。
## 8 份原始既有表 + R35 新增 parry_rules.tres（R36 视角已存在、同样零改动）。
const WATCHED_EXISTING: Array = [
	"res://data/rpg/wave_trial.tres",
	"res://data/rpg/boon_draft.tres",
	"res://data/rpg/trial_modifiers.tres",
	"res://data/combat/stagger_rules.tres",
	"res://data/rpg/combo_rules.tres",
	"res://data/combat/player_actions.tres",
	"res://data/combat/boss_01_margit.tres",
	"res://data/combat/enemy_01_limgrave_soldier.tres",
	"res://data/combat/parry_rules.tres",
]
## 本轮新表（非「既有表」，但同样证明验证脚本只读、未改写任何 .tres）。
const WATCHED_NEW: Array = ["res://data/combat/focus_rules.tres"]

## 两波 / 单波夹具（配置注入，不依赖真实落盘波表的 3 波数值）。
const WAVES: Array = [
	{"telegraph": 1.0, "time_limit": 30.0, "points": 100},
	{"telegraph": 1.0, "time_limit": 30.0, "points": 150},
]
const WAVES_ONE: Array = [
	{"telegraph": 1.0, "time_limit": 30.0, "points": 100},
]
const TG: float = 1.0

## [PLACEHOLDER] R36 首版期望（校验基准；调参只改表，同步本脚本）。
const EXPECT_PEBBLE_ID: String = "glintstone_pebble"
const EXPECT_LION_ID: String = "lion_slash"
const EXPECT_PEBBLE_DAMAGE: float = 18.0
const EXPECT_PEBBLE_POISE: float = 8.0
const EXPECT_LION_DAMAGE: float = 45.0
const EXPECT_LION_POISE: float = 40.0
const EXPECT_PEBBLE_FP_COST: float = 12.0
const EXPECT_LION_FP_COST: float = 35.0
const EXPECT_FP_MAX: float = 100.0

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
	print("[V130-FS] %s PASS=%s | %s" % [tag, str(ok), detail])


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


## 确定性夹具：加载【真实生产脚本】-> new -> add_child(root) -> 显式 _ready ->
## 关闭自动 _process / 自动开始 / 持久化 -> 注入波次配置。绝不写生产存档、不建替身服务。
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
	var snap_init: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("persist_explicitly_downgraded", bool(snap_init.get("persist_available")) == false,
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
	print("[V130-FS] === SELFTEST START ===")
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

	_test_baseline()
	_test_focus_into_settlement()
	_test_both_arts_into_settlement()
	_test_monotonic_and_no_double()
	_test_fp_only_decreases_except_rest()
	_test_per_wave_acc_clear()
	_test_legacy_output_format()
	_test_a48_production_chain()

	# ---- md5 后：证明本件全程只读、既有表零改动 ----
	var existing_all_same: bool = true
	for p: String in (WATCHED_EXISTING + WATCHED_NEW) as Array:
		var before: String = str(_md5_before.get(p, ""))
		var after: String = _md5(p)
		print("[V130-FS] MD5 %s before=%s after=%s" % [p.get_file(), before, after])
		var same: bool = before == after and not after.is_empty()
		_ck("md5_zero_change_%s" % p.get_file(), same,
			"%s 前后 md5 一致（零改动）" % p.get_file())
		for q: String in WATCHED_EXISTING:
			if p == q and not same:
				existing_all_same = false
	_ck("existing_tables_zero_change", existing_all_same,
		"%d 份既有 .tres 前后 md5 全部一致（零改动）" % WATCHED_EXISTING.size())
	_finish()


## A) 基线：无战技 -> D 级倍率 1.0，结算点数 = 基础 100；A54 服务装配 / FP 初始满
func _test_baseline() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	_drive_clear(d, TG)
	var s: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("baseline_settled_100", int(s.get("last_settled_points")) == 100,
		"无战技 / 0 连击 -> settled=100（D 级 mult=1.0，与既有等价）")
	_ck("baseline_combo_rank_D", str(s.get("combo_rank")) == "D" \
		and is_equal_approx(float(s.get("combo_multiplier")), 1.0),
		"combo_rank=D / combo_multiplier=1.0 [PLACEHOLDER]")
	_ck("a54_focus_service_present", d.call("get_focus_service") != null \
		and d.call("get_combo_service") != null and d.call("get_boon_service") != null \
		and d.call("get_parry_service") != null,
		"4 个纯逻辑服务均已装配（A54：唯一实例经 get_*_service() 复用）")
	_ck("focus_initial_fp_full", is_equal_approx(float(s.get("focus_fp")), EXPECT_FP_MAX) \
		and is_equal_approx(float(s.get("focus_fp_max")), EXPECT_FP_MAX),
		"focus_fp=100.0 / focus_fp_max=100.0 [PLACEHOLDER]")
	_ck("baseline_no_focus_bonus", int(s.get("focus_points_acc")) == 0 \
		and int(s.get("focus_spend_count")) == 0,
		"未施放战技 -> 无 damage 凭空出现")


## B) 核心：战技 damage 并入结算，A57 取源一致、一次入账、输出格式不变、A48① 运行时实证
func _test_focus_into_settlement() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	_reset_wc()
	d.connect("wave_cleared", Callable(self, "_on_wave_cleared"))
	d.call("start_trial")
	var focus: FocusService = d.call("get_focus_service") as FocusService
	_ck("focus_service_reachable_at_wave_start", focus != null \
		and is_equal_approx(focus.get_fp(), EXPECT_FP_MAX),
		"波次开始可经 get_focus_service() 取 A54 唯一实例、FP 满")
	var r: Dictionary = d.call("spend_focus", EXPECT_PEBBLE_ID) as Dictionary
	_ck("spend_focus_ok", bool(r.get("ok")) and str(r.get("reason")) == "ok",
		"真实输入入口 spend_focus(辉石魔砾) -> 成功")
	_ck("spend_focus_reward_payload", is_equal_approx(float(r.get("damage")), EXPECT_PEBBLE_DAMAGE) \
		and is_equal_approx(float(r.get("poise_damage")), EXPECT_PEBBLE_POISE) \
		and is_equal_approx(float(r.get("fp_cost")), EXPECT_PEBBLE_FP_COST),
		"奖励 payload=(damage=18.0, poise=8.0, fp_cost=12.0) [PLACEHOLDER]")
	var s_acc: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("a48_production_subscriber_runtime", int(s_acc.get("focus_spend_count")) == 1,
		"生产订阅者实证：focus_spent 已被 wave_trial_director 接收（A48①，非验证脚本订阅）")
	_ck("focus_success_recorded", int(s_acc.get("focus_points_acc")) == int(EXPECT_PEBBLE_DAMAGE) \
		and is_equal_approx(float(s_acc.get("focus_poise_acc")), EXPECT_PEBBLE_POISE),
		"生产订阅者已把 damage/poise_damage 记入导演层")
	var ss: Dictionary = d.call("get_settlement_snapshot") as Dictionary
	_ck("settlement_snapshot_focus_keys", int(ss.get("focus_points_bonus")) == int(EXPECT_PEBBLE_DAMAGE) \
		and is_equal_approx(float(ss.get("focus_poise_bonus")), EXPECT_PEBBLE_POISE) \
		and int(ss.get("focus_spend_count")) == 1,
		"get_settlement_snapshot() 新增只读 key 可用")
	d.call("debug_advance", TG)
	d.call("on_encounter_finished", true)
	var s: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("focus_damage_into_settled_118", int(s.get("last_settled_points")) == 118,
		"战技 damage=18 并入清波结算基数：100+18 -> settled=118（D 级 1.0）[PLACEHOLDER]")
	_ck("focus_points_total_118", int(s.get("points_total")) == 118,
		"points_total=118（战技伤害已并入既有清波点数结算）")
	# A57：HUD points_awarded 的取源 = combo.get_last_settlement()["total_points"]，必须与导演层一致
	var combo: Object = d.call("get_combo_service") as Object
	var last: Dictionary = combo.call("get_last_settlement") as Dictionary
	_ck("a57_awarded_source_consistent", int(last.get("total_points")) == 118 \
		and int(last.get("total_points")) == int(s.get("last_settled_points")),
		"A57：最终结算值 118 经 points_awarded 发出的取源与导演层一致（唯一最终值）")
	_ck("no_double_settle_one", int(s.get("settlement_count")) == 1 \
		and bool(combo.call("is_settled")),
		"本波仅结算 1 次（不二次入账）")
	_ck("wave_cleared_format_unchanged", _wc_count == 1 and _wc_index == 0 \
		and _wc_points == 100,
		"wave_cleared(index=0, points=100) 仍发基础 pts，既有输出格式/语义未改")


## C) 两战技都施放：100 + 18 + 45 = 163（冷却独立、同帧可放；不叠乘其它层）
func _test_both_arts_into_settlement() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	d.call("start_trial")
	var r1: Dictionary = d.call("spend_focus", EXPECT_PEBBLE_ID) as Dictionary
	var r2: Dictionary = d.call("spend_focus", EXPECT_LION_ID) as Dictionary
	_ck("both_arts_ok", bool(r1.get("ok")) and bool(r2.get("ok")),
		"两战技冷却独立、同帧均可施放（低耗远程 + 高耗高削韧）")
	var s_acc: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("both_arts_damage_acc", int(s_acc.get("focus_points_acc")) == 63 \
		and is_equal_approx(float(s_acc.get("focus_poise_acc")), 48.0),
		"damage 累加 18+45=63 / poise_damage 累加 8+40=48 [PLACEHOLDER]")
	_ck("both_arts_fp", is_equal_approx(float(s_acc.get("focus_fp")), 53.0),
		"FP 扣减 12+35=47 -> 53（两战技资源取舍）")
	d.call("debug_advance", TG)
	d.call("on_encounter_finished", true)
	var s: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("both_arts_into_settled_163", int(s.get("last_settled_points")) == 163,
		"两战技 damage 并入清波结算基数：100+18+45 -> settled=163（既有单一倍率，不叠乘）")
	var last: Dictionary = (d.call("get_combo_service") as Object).call("get_last_settlement") as Dictionary
	_ck("both_arts_awarded_source", int(last.get("total_points")) == 163,
		"A57 取源 = 163（含两战技伤害的最终值，一次入账）")


## D) 点数单调 / 余额非负 / 不重复结算 / 不二次入账
func _test_monotonic_and_no_double() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	d.call("start_trial")
	d.call("spend_focus", EXPECT_PEBBLE_ID)
	d.call("debug_advance", TG)
	var s0: Dictionary = d.call("get_snapshot") as Dictionary
	var p0: int = int(s0.get("points_total"))
	d.call("on_encounter_finished", true)
	var s1: Dictionary = d.call("get_snapshot") as Dictionary
	var p1: int = int(s1.get("points_total"))
	_ck("points_monotonic_increase", p1 > p0 and p1 >= 0,
		"清波后 points_total %d -> %d（只增不减、非负）" % [p0, p1])
	_ck("balance_nonneg", int(s1.get("last_settled_points")) >= 0,
		"last_settled_points=%d >= 0（余额非负）" % int(s1.get("last_settled_points")))
	var rej0: int = int(s1.get("rejected_finishes"))
	d.call("on_encounter_finished", true)   # 重复触发：既有 WAVE_ACTIVE 门控拒绝
	var s2: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("no_double_settle", int(s2.get("points_total")) == p1 \
		and int(s2.get("settlement_count")) == 1 \
		and int(s2.get("rejected_finishes")) == rej0 + 1,
		"重复 on_encounter_finished -> 拒绝（points 不变、settlement_count=1、不二次入账）")
	_ck("monotonic_after_duplicate", int(s2.get("points_total")) >= p1,
		"重复触发后点数仍不回退")


## E) FP 只减不增除休息：一局内连续施放单调不增；赐福休息是唯一增出口；跨波不回满
func _test_fp_only_decreases_except_rest() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	d.call("start_trial")
	var focus: FocusService = d.call("get_focus_service") as FocusService
	var f0: float = focus.get_fp()                       # 100
	d.call("spend_focus", EXPECT_PEBBLE_ID)
	var f1: float = focus.get_fp()                       # 88
	d.call("spend_focus", EXPECT_LION_ID)
	var f2: float = focus.get_fp()                       # 53
	_ck("fp_monotonic_decrease_in_run", f0 >= f1 and f1 >= f2 \
		and f2 >= 0.0 and f2 <= EXPECT_FP_MAX,
		"一局内 FP %.1f -> %.1f -> %.1f 只减不增 / 非负 / 不超上限" % [f0, f1, f2])
	var rest: Dictionary = d.call("focus_grace_rest") as Dictionary
	var f3: float = focus.get_fp()                       # 100（唯一允许的增）
	_ck("grace_rest_is_only_increase", bool(rest.get("ok")) \
		and is_equal_approx(f3, EXPECT_FP_MAX) and f3 > f2,
		"赐福休息回满 %.1f -> %.1f（唯一允许 FP 增加的出口）" % [f2, f3])
	var s_rest: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("focus_restore_count_1", int(s_rest.get("focus_restore_count")) == 1,
		"生产订阅者已接收 focus_restored（restore_count=1）")
	d.call("spend_focus", EXPECT_PEBBLE_ID)
	var f4: float = focus.get_fp()                       # 88
	_ck("fp_decreases_after_rest", f4 <= f3 and f4 >= 0.0,
		"休息后再次施放 FP %.1f -> %.1f 继续只减不增" % [f3, f4])
	# 跨波不回满：推进到第 2 波 TELEGRAPH，FP 仍为休息后消耗值（不因波次开始回满）
	d.call("debug_advance", TG)
	d.call("on_encounter_finished", true)
	d.call("debug_advance", 0.0)
	d.call("debug_advance", 0.0)
	var s_w2: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("fp_not_refilled_next_wave", is_equal_approx(float(s_w2.get("focus_fp")), f4) \
		and int(s_w2.get("index")) == 1,
		"第 2 波开始不回满 FP（专注值跨波资源，只有赐福休息 / 新局 reset 回满）")


## F) 每波累计清零：第 1 波战技 damage 不在第 2 波清波重复并入
func _test_per_wave_acc_clear() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	d.call("start_trial")
	d.call("spend_focus", EXPECT_PEBBLE_ID)
	d.call("debug_advance", TG)
	d.call("on_encounter_finished", true)   # 第 1 波结算 118（含战技 +18）
	# WAVE_CLEARED -> NEXT_WAVE -> 第 2 波 TELEGRAPH（波次开始清本波累计）
	d.call("debug_advance", 0.0)
	d.call("debug_advance", 0.0)
	var s_mid: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("focus_acc_cleared_next_wave", int(s_mid.get("focus_points_acc")) == 0 \
		and int(s_mid.get("index")) == 1,
		"第 2 波波次开始清 focus_points_acc（不把第 1 波战技伤害带进第 2 波）")
	d.call("debug_advance", TG)
	d.call("on_encounter_finished", true)
	var s: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("no_repeat_focus_damage_wave2", int(s.get("last_settled_points")) == 150,
		"第 2 波无战技 -> settled=150（第 2 波基础 pts，不含第 1 波 +18，不重复并入）")


## G) 既有输出格式零改动：wave_cleared 基础 pts + get_snapshot() 既有 27 + R34 8 + R35 8 key 逐字仍在
func _test_legacy_output_format() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	var s: Dictionary = d.call("get_snapshot") as Dictionary
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
		"get_snapshot() 既有 27 个 key 逐字仍在（只新增只读 key，不改既有）")
	var r34_keys: Array = [
		"last_settled_points", "combo_rank", "combo_multiplier", "combo_count",
		"boon_cost_key", "boon_effect_key", "boon_cost_value", "settlement_count",
	]
	var r34_all: bool = true
	for k: String in r34_keys:
		if not s.has(k):
			r34_all = false
	_ck("r34_snapshot_keys_intact", r34_all,
		"get_snapshot() R34 新增 8 个 key 逐字仍在（不回退）")
	var r35_keys: Array = [
		"parry_poise_acc", "parry_points_acc", "parry_success_count", "parry_fail_count",
		"parry_window_opened_count", "parry_poise_applied", "parry_last_combo_keep",
		"parry_last_close_reason",
	]
	var r35_all: bool = true
	for k: String in r35_keys:
		if not s.has(k):
			r35_all = false
	_ck("r35_snapshot_keys_intact", r35_all,
		"get_snapshot() R35 新增 8 个 key 逐字仍在（不回退）")
	var r36_keys: Array = [
		"focus_fp", "focus_fp_max", "focus_points_acc", "focus_poise_acc",
		"focus_poise_applied", "focus_spend_count", "focus_reject_count",
		"focus_restore_count", "focus_cooldown_ready_count", "focus_last_art_id",
		"focus_last_reject_reason",
	]
	var r36_all: bool = true
	for k: String in r36_keys:
		if not s.has(k):
			r36_all = false
	_ck("r36_snapshot_keys_present", r36_all,
		"get_snapshot() R36 新增 11 个只读 key 可用")


## H) A48 生产链路证据：真实生产脚本（非替身）/ 生产订阅者源码 / 结算接线源码 / 唯一实例
##    如实登记：完整「真实输入 → 磁盘/画面」回归脚本 verify_focus_runtime_v130.gd 归 Rank-1
##    （目录所有权），本件只断言生产链路真实产出，不模拟编排、不写生产存档。
func _test_a48_production_chain() -> void:
	var d: Node = _make_director(WAVES_ONE)
	if d == null:
		return
	var script_path: String = String((d.get_script() as Script).resource_path)
	_ck("real_production_director", script_path.contains("wave_trial_director.gd"),
		"驱动对象 = 真实生产脚本 wave_trial_director.gd（非验证脚本内自建替身/模拟编排）")
	var f1: Object = d.call("get_focus_service") as Object
	var f2: Object = d.call("get_focus_service") as Object
	_ck("a54_single_instance", f1 != null and f1 == f2,
		"A54：两次 get_focus_service() 返回同一实例（绝不自建第二个）")
	var abs_path: String = ProjectSettings.globalize_path(DIRECTOR_PATH)
	var src: String = FileAccess.get_file_as_string(abs_path)
	if src.is_empty():
		src = FileAccess.get_file_as_string(DIRECTOR_PATH)
	_ck("production_subscriber_in_source", src.contains("_bind_focus_signals") \
		and src.contains("get_focus_service") \
		and src.contains("base_for_combo + _focus_points_acc") \
		and src.contains("focus_spent") and src.contains("_focus.on_grace_rest()"),
		"生产源码含 4 信号订阅者 + 唯一实例 getter + 战技并入结算 + 赐福休息回满（A48①/A57）")


func _finish() -> void:
	print("[V130-FS] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V130-FS] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V130-FS] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V130-FS] === SELFTEST END ===")
	quit(0 if all_ok else 1)
