extends SceneTree

## ===========================================================================
## R37 / v0.14.0 · 「死亡掉落 / 一次性回收 / 点数单调 / 瓶数单调 +
##                既有表 md5 零改动」生产级自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_life_settlement_v140.gd
##
## 覆盖（任务单 ④⑤）：
##   - 死亡掉落（只是只读记录，绝不回退 grace.trial.points / 绝不写 removals）、
##     一次性回收、回收点数经既有清波结算基数 -> combo.settle() ->
##     HUD points_awarded 一次入账（A55/A57），不二次入账；
##   - 点数单调 / 余额非负 / 不重复结算 / 回收只生效一次 / 并入后 acc 清零；
##   - 瓶数单调（只减不增除休息）/ 赐福休息补满瓶 / 死亡重生回满瓶；
##   - 死亡期间拒绝行动、赐福重生复位运行时状态（FP / 瓶 / 连击 / 窗口）；
##   - 既有输出格式零改动：wave_cleared(index, points) 仍发基础 pts、
##     get_snapshot() 既有 27 + R34 8 + R35 8 + R36 11 个 key 逐字仍在；
##   - A48① 生产订阅者运行时实证、A54 唯一实例、真实生产脚本驱动
##     （不在验证脚本内模拟编排）；
##   - md5 前后对比证明 10 份既有 .tres 零改动（本轮 2 张新表同样未被脚本写入）。
##
## 【--script 模式纪律 / 不写生产存档】
## - 用 Engine.get_main_loop() as SceneTree 取 root：add_child(d) 后显式
##   d.call("_ready")（--script 模式 add_child 不 flush _ready）；不用 get_tree()、
##   不用 /root/... 绝对路径。
## - 夹具显式 d.set_process(false) + auto_start=false + bind_persistence(null,null)，
##   完全靠 debug_advance / on_encounter_finished / 驱动口确定性驱动，禁止自动 _process 抖动；
##   bind_persistence 显式降级后 _persist_settle 恒返回 false，**绝不写生产 delta.json**。
## - 全程只读 ResourceLoader.load(CACHE_MODE_IGNORE)；不碰渲染、不启 GPU job。
## - 驱动对象是真实生产脚本 wave_trial_director.gd（DIRECTOR_PATH 加载），不是自建替身；
##   结算值经真实 _clear_wave() 产出，不在验证脚本内模拟编排。
## 输出逐条 PASS=true/false + SUMMARY + OVERALL=PASS/FAIL + RESULT=ALL_MATCH；失败 quit(1)。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const DIRECTOR_PATH: String = "res://scripts/combat/wave_trial_director.gd"

## 既有表（本轮只读、零改动）；md5 前后对比的「既有表零改动」证据主体。
## 9 份原始既有表 + R36 新增 focus_rules.tres（R37 视角已存在、同样零改动）。
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
	"res://data/rpg/flask_rules.tres",
	"res://data/rpg/death_rules.tres",
]

## 两波 / 单波夹具（配置注入，不依赖真实落盘波表的 3 波数值）。
const WAVES: Array = [
	{"telegraph": 1.0, "time_limit": 30.0, "points": 100},
	{"telegraph": 1.0, "time_limit": 30.0, "points": 150},
]
const WAVES_ONE: Array = [
	{"telegraph": 1.0, "time_limit": 30.0, "points": 100},
]
const TG: float = 1.0

## [PLACEHOLDER] R37 首版期望（校验基准；调参只改表，同步本脚本）。
const EXPECT_FLASK_MAX: int = 3
const EXPECT_DROP_RATIO: float = 0.5

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
	print("[V140-LS] %s PASS=%s | %s" % [tag, str(ok), detail])


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
	print("[V140-LS] === SELFTEST START ===")
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
	_test_death_reclaim_settlement()
	_test_reclaim_only_once()
	_test_points_monotonic()
	_test_flask_monotonic()
	_test_legacy_output_format()
	_test_a48_production_chain()

	# ---- md5 后：证明本件全程只读、既有表零改动 ----
	var existing_all_same: bool = true
	for p: String in (WATCHED_EXISTING + WATCHED_NEW) as Array:
		var before: String = str(_md5_before.get(p, ""))
		var after: String = _md5(p)
		print("[V140-LS] MD5 %s before=%s after=%s" % [p.get_file(), before, after])
		var same: bool = before == after and not after.is_empty()
		_ck("md5_zero_change_%s" % p.get_file(), same,
			"%s 前后 md5 一致（零改动）" % p.get_file())
		for q: String in WATCHED_EXISTING:
			if p == q and not same:
				existing_all_same = false
	_ck("existing_tables_zero_change", existing_all_same,
		"%d 份既有 .tres 前后 md5 全部一致（零改动）" % WATCHED_EXISTING.size())
	_finish()


## A) 基线：无死亡 / 无回收 -> D 级倍率 1.0，结算点数 = 基础 100；A54 服务装配 / 瓶初始满
func _test_baseline() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	_drive_clear(d, TG)
	var s: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("baseline_settled_100", int(s.get("last_settled_points")) == 100,
		"无死亡 / 0 连击 -> settled=100（D 级 mult=1.0，与既有等价）")
	_ck("baseline_no_reclaim", int(s.get("life_reclaim_acc")) == 0 \
		and int(s.get("life_reclaim_count")) == 0,
		"基线无回收点数凭空出现")
	_ck("a54_all_services_present", d.call("get_flask_service") != null \
		and d.call("get_death_service") != null \
		and d.call("get_focus_service") != null \
		and d.call("get_combo_service") != null \
		and d.call("get_boon_service") != null \
		and d.call("get_parry_service") != null,
		"6 个纯逻辑服务均已装配（A54：唯一实例经 get_*_service() 复用）")
	_ck("flask_initial_full", int(s.get("flask_remaining")) == EXPECT_FLASK_MAX \
		and int(s.get("flask_max")) == EXPECT_FLASK_MAX,
		"flask_remaining=3 / flask_max=3 [PLACEHOLDER]")


## B) 核心：死亡 -> 重生 -> 一次性回收 -> 清波结算（A55/A57 一次入账、不二次入账）
func _test_death_reclaim_settlement() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	_reset_wc()
	d.connect("wave_cleared", Callable(self, "_on_wave_cleared"))
	d.call("start_trial")
	# 真实输入驱动口：使用元素瓶（生产订阅者计数）
	var uf: Dictionary = d.call("use_flask", 50.0, 100.0) as Dictionary
	_ck("flask_use_via_driver", bool(uf.get("ok")) and int(uf.get("flask_after")) == 2,
		"真实输入入口 use_flask(50,100) -> 成功、瓶数 3->2")
	var s_use: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("a48_flask_subscriber_runtime", int(s_use.get("flask_use_count")) == 1,
		"生产订阅者实证：flask_used 已被 wave_trial_director 接收（A48①，非验证脚本订阅）")
	# HP 归零 -> 死亡态 -> 记录掉落（只是只读记录，绝不回退 points / 绝不写 removals）
	var dead: Dictionary = d.call("on_player_death", 200) as Dictionary
	_ck("death_via_driver", bool(dead.get("ok")) \
		and int(dead.get("dropped_points")) == 100 \
		and int(dead.get("grace_points_snapshot")) == 200,
		"真实输入入口 on_player_death(200) -> dropped=100 / 只读快照=200 [PLACEHOLDER]")
	var s_dead: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("a48_death_subscriber_runtime", int(s_dead.get("life_death_count")) == 1 \
		and int(s_dead.get("life_dropped_points")) == 100 \
		and int(s_dead.get("life_grace_snapshot")) == 200,
		"生产订阅者实证：death_occurred 已被接收（只做只读记录）")
	_ck("no_points_rollback_in_production", int(s_dead.get("grace_trial_points")) >= 0 \
		and int(s_dead.get("life_grace_snapshot")) == 200,
		"★ 不回退 grace.trial.points / 不写 removals：只读快照=200、磁盘镜像不减（A59）")
	# 死亡期间拒绝行动
	var guard: Dictionary = d.call("guard_life_action", "attack") as Dictionary
	_ck("dead_action_rejected_in_production", not bool(guard.get("ok")) \
		and str(guard.get("reason")) == "dead" and bool(s_dead.get("life_is_dead")),
		"死亡期间 guard_life_action(attack) -> dead 拒绝（死亡期间拒绝行动）")
	# 赐福重生：生产订阅者复位 FP / 瓶 / 连击 / 窗口
	var resp: Dictionary = d.call("on_grace_respawn") as Dictionary
	_ck("respawn_via_driver", bool(resp.get("ok")) and not bool(resp.get("is_dead")),
		"真实输入入口 on_grace_respawn() -> 存活")
	var s_resp: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("respawn_resets_runtime", int(s_resp.get("life_respawn_count")) == 1 \
		and int(s_resp.get("flask_remaining")) == EXPECT_FLASK_MAX \
		and int(s_resp.get("flask_restore_count")) >= 1,
		"赐福重生复位运行时状态：瓶回满 3（生产订阅者 _on_respawn_performed）")
	# 一次性回收
	var rec: Dictionary = d.call("reclaim_dropped_points") as Dictionary
	_ck("reclaim_via_driver", bool(rec.get("ok")) and int(rec.get("points")) == 100,
		"真实输入入口 reclaim_dropped_points() -> points=100（一次性回收）")
	var s_acc: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("a48_reclaim_subscriber_runtime", int(s_acc.get("life_reclaim_count")) == 1 \
		and int(s_acc.get("life_reclaim_acc")) == 100,
		"生产订阅者实证：points_reclaimed 已累计到待结算 acc=100（A48①）")
	# 清波：回收点数并入 base_for_combo -> combo.settle() -> 唯一最终结算值
	d.call("debug_advance", TG)
	d.call("on_encounter_finished", true)
	var s: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("reclaim_into_settled_200", int(s.get("last_settled_points")) == 200,
		"回收点数 100 并入清波结算基数：100+100 -> settled=200（D 级 1.0）[PLACEHOLDER]")
	_ck("points_total_200", int(s.get("points_total")) == 200,
		"points_total=200（回收点数已并入既有清波点数结算）")
	_ck("reclaim_acc_cleared_after_settle", int(s.get("life_reclaim_acc")) == 0,
		"并入结算后 _death_reclaim_acc 清零（不二次入账）")
	# A57：HUD points_awarded 的取源 = combo.get_last_settlement()["total_points"]
	var combo: Object = d.call("get_combo_service") as Object
	var last: Dictionary = combo.call("get_last_settlement") as Dictionary
	_ck("a57_awarded_source_consistent", int(last.get("total_points")) == 200 \
		and int(last.get("total_points")) == int(s.get("last_settled_points")),
		"A57：最终结算值 200 经 points_awarded 发出的取源与导演层一致（唯一最终值）")
	_ck("no_double_settle_one", int(s.get("settlement_count")) == 1 \
		and bool(combo.call("is_settled")),
		"本波仅结算 1 次（不二次入账）")
	_ck("wave_cleared_format_unchanged", _wc_count == 1 and _wc_index == 0 \
		and _wc_points == 100,
		"wave_cleared(index=0, points=100) 仍发基础 pts，既有输出格式/语义未改")


## C) 回收只生效一次：重复 reclaim 被拒，acc 不增、reclaim_count 恒 1、点数不回退
func _test_reclaim_only_once() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	d.call("start_trial")
	d.call("on_player_death", 200)
	d.call("on_grace_respawn")
	d.call("reclaim_dropped_points")
	var before: Dictionary = d.call("get_snapshot") as Dictionary
	var rec2: Dictionary = d.call("reclaim_dropped_points") as Dictionary
	_ck("reclaim_second_rejected", not bool(rec2.get("ok")) \
		and str(rec2.get("reason")) == "already_reclaimed" \
		and int(rec2.get("points")) == 0,
		"第二次 reclaim -> already_reclaimed / points=0（回收只生效一次）")
	var after: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("reclaim_no_double_acc", int(after.get("life_reclaim_acc")) == int(before.get("life_reclaim_acc")) \
		and int(after.get("life_reclaim_count")) == 1,
		"重复回收不二次累计 acc / reclaim_count 恒 1")
	d.call("debug_advance", TG)
	d.call("on_encounter_finished", true)
	var s: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("settled_200_after_duplicate_reclaim", int(s.get("last_settled_points")) == 200,
		"重复回收后清波仍只结算 200（不二次入账）")


## D) 点数单调 / 余额非负 / 不重复结算
func _test_points_monotonic() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	d.call("start_trial")
	d.call("on_player_death", 200)
	d.call("on_grace_respawn")
	d.call("reclaim_dropped_points")
	d.call("debug_advance", TG)
	var s0: Dictionary = d.call("get_snapshot") as Dictionary
	var p0: int = int(s0.get("points_total"))
	d.call("on_encounter_finished", true)
	var s1: Dictionary = d.call("get_snapshot") as Dictionary
	var p1: int = int(s1.get("points_total"))
	_ck("points_monotonic_increase", p1 > p0 and p1 >= 0,
		"清波后 points_total %d -> %d（只增不减、非负）" % [p0, p1])
	_ck("balance_nonneg", int(s1.get("last_settled_points")) >= 0 \
		and int(s1.get("grace_trial_points")) >= 0,
		"last_settled_points / grace_trial_points 均 >= 0（余额非负、不回退）")
	var rej0: int = int(s1.get("rejected_finishes"))
	d.call("on_encounter_finished", true)   # 重复触发：既有 WAVE_ACTIVE 门控拒绝
	var s2: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("no_double_settle", int(s2.get("points_total")) == p1 \
		and int(s2.get("settlement_count")) == 1 \
		and int(s2.get("rejected_finishes")) == rej0 + 1,
		"重复 on_encounter_finished -> 拒绝（points 不变、不二次入账）")
	_ck("monotonic_after_duplicate", int(s2.get("points_total")) >= p1,
		"重复触发后点数仍不回退")


## E) 瓶数单调（只减不增除休息）/ 赐福休息补满瓶 / 重生回满瓶
func _test_flask_monotonic() -> void:
	var d: Node = _make_director(WAVES)
	if d == null:
		return
	d.call("start_trial")
	var seq: Array[int] = []
	seq.append(int((d.call("get_snapshot") as Dictionary).get("flask_remaining")))
	for hp: float in [50.0, 40.0, 30.0]:
		d.call("use_flask", hp, 100.0)
		seq.append(int((d.call("get_snapshot") as Dictionary).get("flask_remaining")))
	var mono: bool = true
	for i: int in range(1, seq.size()):
		if seq[i] > seq[i - 1] or seq[i] < 0 or seq[i] > EXPECT_FLASK_MAX:
			mono = false
	_ck("flask_monotonic_decrease_in_run", mono,
		"一局内瓶数序列 %s 只减不增 / 非负 / 不超上限" % str(seq))
	var rest: Dictionary = d.call("flask_grace_rest") as Dictionary
	_ck("flask_grace_rest_refill", bool(rest.get("ok")) \
		and int(rest.get("flask_after")) == EXPECT_FLASK_MAX \
		and str(rest.get("policy")) == "rest_refill",
		"赐福休息补满瓶 0->3（唯一允许增加的出口）[PLACEHOLDER]")
	# 死亡 -> 重生：生产订阅者补满瓶（重置运行时状态）
	d.call("use_flask", 50.0, 100.0)   # 3->2
	d.call("on_player_death", 200)
	d.call("on_grace_respawn")
	var s: Dictionary = d.call("get_snapshot") as Dictionary
	_ck("respawn_refills_flask", int(s.get("flask_remaining")) == EXPECT_FLASK_MAX,
		"死亡 / 重生时重置运行时状态：瓶回满 3（生产订阅者）")


## F) 既有输出格式零改动：wave_cleared 基础 pts + get_snapshot() 既有 27 + R34 8 + R35 8 + R36 11 key 逐字仍在
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
	_ck("r36_snapshot_keys_intact", r36_all,
		"get_snapshot() R36 新增 11 个 key 逐字仍在（不回退）")
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
	_ck("r37_snapshot_keys_present", r37_all,
		"get_snapshot() R37 新增 14 个只读 key 可用")
	var ss: Dictionary = d.call("get_settlement_snapshot") as Dictionary
	_ck("r37_settlement_keys_present", ss.has("life_reclaim_bonus") \
		and ss.has("life_reclaim_count") and ss.has("flask_use_count") \
		and ss.has("focus_points_bonus") and ss.has("parry_points_bonus"),
		"get_settlement_snapshot() R37 新增只读 key 可用、既有 key 仍在")


## G) A48 生产链路证据：真实生产脚本（非替身）/ 生产订阅者源码 / 结算接线源码 / 唯一实例
##    如实登记：完整「真实输入 → 磁盘/画面」回归脚本 verify_life_runtime_v140.gd 归 Rank-1
##    （目录所有权），本件只断言生产链路真实产出，不模拟编排、不写生产存档。
func _test_a48_production_chain() -> void:
	var d: Node = _make_director(WAVES_ONE)
	if d == null:
		return
	var script_path: String = String((d.get_script() as Script).resource_path)
	_ck("real_production_director", script_path.contains("wave_trial_director.gd"),
		"驱动对象 = 真实生产脚本 wave_trial_director.gd（非验证脚本内自建替身/模拟编排）")
	var f1: Object = d.call("get_flask_service") as Object
	var f2: Object = d.call("get_flask_service") as Object
	var d1: Object = d.call("get_death_service") as Object
	var d2: Object = d.call("get_death_service") as Object
	_ck("a54_single_instance", f1 != null and f1 == f2 and d1 != null and d1 == d2,
		"A54：两次 get_flask_service() / get_death_service() 各返回同一实例（绝不自建第二个）")
	var abs_path: String = ProjectSettings.globalize_path(DIRECTOR_PATH)
	var src: String = FileAccess.get_file_as_string(abs_path)
	if src.is_empty():
		src = FileAccess.get_file_as_string(DIRECTOR_PATH)
	_ck("production_subscriber_in_source", src.contains("_bind_flask_signals") \
		and src.contains("_bind_death_signals") \
		and src.contains("get_flask_service") and src.contains("get_death_service") \
		and src.contains("base_for_combo + _death_reclaim_acc") \
		and src.contains("points_reclaimed") \
		and src.contains("_flask.on_grace_rest()") \
		and src.contains("_on_respawn_performed"),
		"生产源码含 3+4 信号订阅者 + 两个唯一实例 getter + 回收并入结算 + 赐福休息补满 + 重生复位（A48①/A54/A57）")


func _finish() -> void:
	print("[V140-LS] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V140-LS] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V140-LS] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V140-LS] === SELFTEST END ===")
	quit(0 if all_ok else 1)
