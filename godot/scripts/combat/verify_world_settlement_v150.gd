extends SceneTree

## ===========================================================================
## R38 / v0.15.0 · 「野外遭遇奖励并入结算 + 点数单调 + 区域清除单调 +
##                既有表 md5 零改动」生产级自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_world_settlement_v150.gd
##
## 覆盖（任务单 ④）：
##   - 野外遭遇触发复用既有三波 / 导演层结算（真实 wave_trial_director.gd，非替身）；
##     清波后标记区域已清除、遭遇奖励经 combo.settle() -> points_awarded 一次入账
##     （A55/A57，不二次入账）；acc 并入后清零；
##   - 点数单调 / 余额非负 / 不重复结算 / 重复触发幂等；
##   - 区域清除单调（world_cleared_count 只增不减）；
##   - 既有输出格式零改动：wave_cleared(index, pts) 仍发基础 pts、
##     get_snapshot() 既有 27 + R34 8 + R35 8 + R36 11 + R37 14 个 key 逐字仍在；
##   - A77：无野外遭遇时既有三波试炼入口仍可达、结算逐字等价；
##   - A48① 生产订阅者运行时实证、A54 唯一实例、真实生产脚本驱动
##     （不在验证脚本内模拟编排）；
##   - md5 前后对比证明 10 份既有 .tres 零改动（本轮新表同样未被脚本写入）。
##
## 【--script 模式纪律 / 不写生产存档】
## - 用 Engine.get_main_loop() as SceneTree 取 root：add_child(d) 后显式
##   d.call("_ready")（--script 模式 add_child 不 flush _ready）；不用 get_tree()、
##   不用 /root/... 绝对路径。
## - 夹具显式 d.set_process(false) + auto_start=false + bind_persistence(null,null)，
##   完全靠 debug_advance / on_encounter_finished / 驱动口确定性驱动；
##   bind_persistence 显式降级后 _persist_settle 恒返回 false，★ 绝不写生产 delta.json。
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
	"res://data/rpg/combo_rules.tres",
	"res://data/combat/stagger_rules.tres",
	"res://data/combat/player_actions.tres",
	"res://data/combat/boss_01_margit.tres",
	"res://data/combat/enemy_01_limgrave_soldier.tres",
	"res://data/combat/parry_rules.tres",
	"res://data/combat/focus_rules.tres",
]
## 本轮新表（非「既有表」，但同样证明验证脚本只读、未改写任何 .tres）。
const WATCHED_NEW: Array = [
	"res://data/rpg/world_encounters.tres",
]

## 单波夹具（配置注入，不依赖真实落盘 3 波数值）；基础点数 100。
const WAVES_ONE: Array = [
	{"telegraph": 1.0, "time_limit": 30.0, "points": 100},
]
const TG: float = 1.0

## [PLACEHOLDER] R38 首版期望（校验基准；调参只改表，同步本脚本 + DONE-R38.md）。
const EXPECT_BASE_POINTS: int = 100
const EXPECT_GATEFRONT_REWARD: int = 80
const EXPECT_SETTLED_WITH_REWARD: int = 180

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
	print("[V150-WS] %s PASS=%s | %s" % [tag, str(ok), detail])


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


func _initialize() -> void:
	print("[V150-WS] === SELFTEST START ===")
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

	_test_baseline_a77()
	_test_reward_into_settlement()
	_test_no_double_settle()
	_test_points_and_clear_monotonic()
	_test_multi_region_clear_monotonic()
	_test_legacy_output_format()
	_test_a48_production_chain()

	# ---- md5 后：证明本件全程只读、既有表零改动 ----
	var existing_all_same: bool = true
	for p: String in (WATCHED_EXISTING + WATCHED_NEW) as Array:
		var before: String = str(_md5_before.get(p, ""))
		var after: String = _md5(p)
		print("[V150-WS] MD5 %s before=%s after=%s" % [p.get_file(), before, after])
		var same: bool = before == after and not after.is_empty()
		_ck("md5_zero_change_%s" % p.get_file(), same,
			"%s 前后 md5 一致（零改动）" % p.get_file())
		for q: String in WATCHED_EXISTING:
			if p == q and not same:
				existing_all_same = false
	_ck("existing_tables_zero_change", existing_all_same,
		"%d 份既有 .tres 前后 md5 全部一致（零改动）" % WATCHED_EXISTING.size())
	_finish()


## A) 基线（A77）：无野外遭遇 -> 既有三波试炼入口仍可达、结算逐字等价（100）
func _test_baseline_a77() -> void:
	var d: Node = _make_director(WAVES_ONE)
	if d == null:
		return
	_reset_wc()
	d.connect("wave_cleared", Callable(self, "_on_wave_cleared"))
	d.call("start_trial")
	d.call("debug_advance", TG)
	d.call("on_encounter_finished", true)
	var s: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("a77_trial_entry_reachable", int(s.get("settlement_count")) == 1 \
		and int(s.get("last_settled_points")) == EXPECT_BASE_POINTS,
		"★ A77：无野外遭遇时既有 start_trial()/on_encounter_finished() 入口仍可达、结算=100")
	_ck("baseline_no_world_reward", int(s.get("world_reward_acc")) == 0 \
		and int(s.get("world_cleared_count")) == 0 \
		and int(s.get("world_trigger_count")) == 0,
		"基线无野外遭遇奖励凭空出现 / 区域清除进度=0")
	_ck("baseline_wave_cleared_format", _wc_count == 1 and _wc_index == 0 \
		and _wc_points == EXPECT_BASE_POINTS,
		"wave_cleared(index=0, points=100) 既有输出格式/语义未改")


## B) 核心：野外遭遇触发 -> 复用既有导演层清波结算 -> 奖励一次入账 + 清波后标记区域已清除
func _test_reward_into_settlement() -> void:
	var d: Node = _make_director(WAVES_ONE)
	if d == null:
		return
	_reset_wc()
	d.connect("wave_cleared", Callable(self, "_on_wave_cleared"))
	# 顺序：start_trial（复位 service）-> enter_region -> try_world_encounter -> 清波
	d.call("start_trial")
	var en: Dictionary = d.call("enter_world_region", "limgrave") as Dictionary
	_ck("enter_region_via_driver", bool(en.get("ok")) \
		and str(en.get("region_id")) == "limgrave",
		"真实输入驱动口 enter_world_region(limgrave) 成功")
	var tr: Dictionary = d.call("try_world_encounter", Vector2(512, 384)) as Dictionary
	_ck("try_world_encounter_via_driver", bool(tr.get("ok")) \
		and str(tr.get("encounter_id")) == "enc_limgrave_gatefront" \
		and int(tr.get("reward_points")) == EXPECT_GATEFRONT_REWARD,
		"真实输入驱动口 try_world_encounter(512,384) -> 命中、reward=80 [PLACEHOLDER]")
	var s_acc: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("a48_trigger_subscriber_runtime", int(s_acc.get("world_reward_acc")) == EXPECT_GATEFRONT_REWARD \
		and int(s_acc.get("world_trigger_count")) == 1,
		"生产订阅者实证：encounter_triggered 已把 reward 累计到待结算 acc=80（A48①）")
	# 清波：奖励并入 base_for_combo -> combo.settle() -> 唯一最终结算值
	d.call("debug_advance", TG)
	d.call("on_encounter_finished", true)
	var s: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("reward_into_settled_180", int(s.get("last_settled_points")) == EXPECT_SETTLED_WITH_REWARD,
		"野外遭遇奖励 80 并入清波结算基数：100+80 -> settled=180（D 级 1.0）[PLACEHOLDER]")
	_ck("points_total_180", int(s.get("points_total")) == EXPECT_SETTLED_WITH_REWARD,
		"points_total=180（遭遇奖励已并入既有清波点数结算）")
	_ck("reward_acc_cleared_after_settle", int(s.get("world_reward_acc")) == 0,
		"并入结算后 _world_reward_acc 清零（不二次入账）")
	_ck("region_cleared_after_wave", int(s.get("world_cleared_count")) == 1 \
		and int(s.get("world_clear_count")) == 1,
		"★ 清波后标记区域已清除：world_cleared_count=1（A48① encounter_cleared 生产订阅者）")
	# A57：HUD points_awarded 的取源 = combo.get_last_settlement()["total_points"]
	var combo: Object = d.call("get_combo_service") as Object
	var last: Dictionary = combo.call("get_last_settlement") as Dictionary
	_ck("a57_awarded_source_consistent", int(last.get("total_points")) == EXPECT_SETTLED_WITH_REWARD \
		and int(last.get("total_points")) == int(s.get("last_settled_points")),
		"A57：最终结算值 180 经 points_awarded 发出的取源与导演层一致（唯一最终值）")
	_ck("no_double_settle_one", int(s.get("settlement_count")) == 1 \
		and bool(combo.call("is_settled")),
		"本波仅结算 1 次（不二次入账）")
	_ck("wave_cleared_format_unchanged", _wc_count == 1 and _wc_index == 0 \
		and _wc_points == EXPECT_BASE_POINTS,
		"wave_cleared(index=0, points=100) 仍发基础 pts，既有输出格式/语义未改")


## C) 不二次入账 / 重复触发幂等 / 重复清波拒绝
func _test_no_double_settle() -> void:
	var d: Node = _make_director(WAVES_ONE)
	if d == null:
		return
	d.call("start_trial")
	d.call("enter_world_region", "limgrave")
	d.call("try_world_encounter", Vector2(512, 384))
	var dup: Dictionary = d.call("try_world_encounter", Vector2(512, 384)) as Dictionary
	_ck("duplicate_trigger_idempotent", not bool(dup.get("ok")) \
		and str(dup.get("reason")) == "duplicate",
		"active 未清除时重复 try_world_encounter -> duplicate 拒绝（幂等）")
	var s_dup: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("duplicate_no_double_acc", int(s_dup.get("world_reward_acc")) == EXPECT_GATEFRONT_REWARD \
		and int(s_dup.get("world_trigger_count")) == 1,
		"重复触发不二次累计 acc / trigger_count 恒 1")
	d.call("debug_advance", TG)
	d.call("on_encounter_finished", true)
	var before: Dictionary = d.call("get_snapshot") as Dictionary
	var p_before: int = int(before.get("points_total"))
	var c_before: int = int(before.get("world_cleared_count"))
	var rej0: int = int(before.get("rejected_finishes"))
	d.call("on_encounter_finished", true)   # 重复触发：既有 WAVE_ACTIVE 门控拒绝
	var after: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("no_double_settle", int(after.get("points_total")) == p_before \
		and int(after.get("settlement_count")) == 1 \
		and int(after.get("rejected_finishes")) == rej0 + 1,
		"重复 on_encounter_finished -> 拒绝（points 不变、不二次入账）")
	_ck("clear_not_repeated", int(after.get("world_cleared_count")) == c_before,
		"重复清波不二次标记区域已清除（cleared_count 不跳变）")


## D) 点数单调 / 余额非负 / 区域清除单调（清波前后 0 -> 180 / 0 -> 1）
func _test_points_and_clear_monotonic() -> void:
	var d: Node = _make_director(WAVES_ONE)
	if d == null:
		return
	d.call("start_trial")
	d.call("enter_world_region", "limgrave")
	d.call("try_world_encounter", Vector2(512, 384))
	d.call("debug_advance", TG)
	var s0: Dictionary = d.call("get_snapshot") as Dictionary
	var p0: int = int(s0.get("points_total"))
	var c0: int = int(s0.get("world_cleared_count"))
	d.call("on_encounter_finished", true)
	var s1: Dictionary = d.call("get_snapshot") as Dictionary
	var p1: int = int(s1.get("points_total"))
	var c1: int = int(s1.get("world_cleared_count"))
	_ck("points_monotonic_increase", p1 > p0 and p1 >= 0,
		"清波后 points_total %d -> %d（只增不减、非负）" % [p0, p1])
	_ck("balance_nonneg", int(s1.get("last_settled_points")) >= 0 \
		and int(s1.get("grace_trial_points")) >= 0,
		"last_settled_points / grace_trial_points 均 >= 0（余额非负、不回退）")
	_ck("clear_count_monotonic", c1 > c0 and c1 == 1,
		"★ 区域清除进度 %d -> %d 单调递增（只增不减）" % [c0, c1])
	d.call("on_encounter_finished", true)
	var s2: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("monotonic_after_duplicate", int(s2.get("points_total")) >= p1 \
		and int(s2.get("world_cleared_count")) >= c1,
		"重复触发后点数 / 区域清除进度仍不回退")


## E) 多区域连续清除：world_cleared_count 序列 [0,1,2,3,4] 单调递增
func _test_multi_region_clear_monotonic() -> void:
	var d: Node = _make_director(WAVES_ONE)
	if d == null:
		return
	d.call("start_trial")
	var seq: Array[int] = [int((d.call("get_snapshot") as Dictionary).get("world_cleared_count"))]
	var plan: Array = [
		["limgrave", Vector2(512, 384)],
		["weeping_peninsula", Vector2(1536, 384)],
		["stormveil", Vector2(2048, 768)],
		["siofra_well", Vector2(2560, 512)],
	]
	for step: Array in plan:
		d.call("enter_world_region", String(step[0]))
		var t: Dictionary = d.call("try_world_encounter", step[1] as Vector2) as Dictionary
		if bool(t.get("ok")):
			d.call("on_world_encounter_cleared", String(t.get("encounter_id", "")))
		seq.append(int((d.call("get_snapshot") as Dictionary).get("world_cleared_count")))
	var mono: bool = true
	for i: int in range(1, seq.size()):
		if seq[i] < seq[i - 1]:
			mono = false
	var expected: Array[int] = [0, 1, 2, 3, 4]
	_ck("multi_region_clear_monotonic", mono and seq == expected,
		"4 个区域连续清除 world_cleared_count 序列 %s 单调递增（只增不减）" % str(seq))


## F) 既有输出格式零改动：get_snapshot() 既有 27 + R34 8 + R35 8 + R36 11 + R37 14 key 逐字仍在
func _test_legacy_output_format() -> void:
	var d: Node = _make_director(WAVES_ONE)
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
	_ck("r34_snapshot_keys_intact", r34_all, "get_snapshot() R34 新增 8 个 key 逐字仍在")
	var r35_keys: Array = [
		"parry_poise_acc", "parry_points_acc", "parry_success_count", "parry_fail_count",
		"parry_window_opened_count", "parry_poise_applied", "parry_last_combo_keep",
		"parry_last_close_reason",
	]
	var r35_all: bool = true
	for k: String in r35_keys:
		if not s.has(k):
			r35_all = false
	_ck("r35_snapshot_keys_intact", r35_all, "get_snapshot() R35 新增 8 个 key 逐字仍在")
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
	_ck("r36_snapshot_keys_intact", r36_all, "get_snapshot() R36 新增 11 个 key 逐字仍在")
	var r37_keys: Array = [
		"flask_remaining", "flask_max", "flask_use_count", "flask_reject_count",
		"flask_restore_count", "life_is_dead", "life_dropped_points",
		"life_grace_snapshot", "life_death_count", "life_respawn_count",
		"life_reclaim_count", "life_reclaim_acc", "life_reject_count",
		"life_last_reject_reason",
	]
	var r37_all: bool = true
	for k: String in r37_keys:
		if not s.has(k):
			r37_all = false
	_ck("r37_snapshot_keys_intact", r37_all, "get_snapshot() R37 新增 14 个 key 逐字仍在")
	var r38_keys: Array = [
		"world_current_region", "world_active_encounter", "world_active_region",
		"world_reward_acc", "world_cleared_count", "world_enter_count",
		"world_trigger_count", "world_clear_count", "world_reject_count",
		"world_last_reject_reason",
	]
	var r38_all: bool = true
	for k: String in r38_keys:
		if not s.has(k):
			r38_all = false
	_ck("r38_snapshot_keys_present", r38_all,
		"get_snapshot() R38 新增 10 个只读 key 可用")
	var ss: Dictionary = d.call("get_settlement_snapshot") as Dictionary
	_ck("r38_settlement_keys_present", ss.has("world_reward_bonus") \
		and ss.has("world_cleared_count") and ss.has("life_reclaim_bonus") \
		and ss.has("focus_points_bonus") and ss.has("parry_points_bonus"),
		"get_settlement_snapshot() R38 新增 2 个只读 key 可用、既有 key 仍在")


## G) A48 生产链路证据：真实生产脚本（非替身）/ 生产订阅者源码 / 结算接线源码 / 唯一实例
func _test_a48_production_chain() -> void:
	var d: Node = _make_director(WAVES_ONE)
	if d == null:
		return
	var script_path: String = String((d.get_script() as Script).resource_path)
	_ck("real_production_director", script_path.contains("wave_trial_director.gd"),
		"驱动对象 = 真实生产脚本 wave_trial_director.gd（非验证脚本内自建替身/模拟编排）")
	var w1: Object = d.call("get_world_encounter_service") as Object
	var w2: Object = d.call("get_world_encounter_service") as Object
	_ck("a54_single_instance", w1 != null and w1 == w2,
		"A54：两次 get_world_encounter_service() 返回同一实例（绝不自建第二个）")
	_ck("a54_world_service_present", w1 != null,
		"WorldEncounterService 唯一实例已装配（表回读成功、不降级）")
	var abs_path: String = ProjectSettings.globalize_path(DIRECTOR_PATH)
	var src: String = FileAccess.get_file_as_string(abs_path)
	if src.is_empty():
		src = FileAccess.get_file_as_string(DIRECTOR_PATH)
	_ck("production_subscriber_in_source", src.contains("_bind_world_encounter_signals") \
		and src.contains("get_world_encounter_service") \
		and src.contains("base_for_combo + _world_reward_acc") \
		and src.contains("_mark_world_cleared_on_wave") \
		and src.contains("enter_world_region") and src.contains("try_world_encounter") \
		and src.contains("on_world_encounter_cleared") \
		and src.contains("_on_world_encounter_triggered") \
		and src.contains("_on_world_encounter_cleared"),
		"生产源码含 4 信号订阅者 + 唯一实例 getter + 奖励并入结算 + 清波标记清除 + 3 驱动口（A48①/A54/A57）")


func _finish() -> void:
	print("[V150-WS] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V150-WS] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V150-WS] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V150-WS] === SELFTEST END ===")
	quit(0 if all_ok else 1)
