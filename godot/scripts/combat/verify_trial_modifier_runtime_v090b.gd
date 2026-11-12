extends SceneTree

## ===========================================================================
## R31B 遗留补齐（由 R32 合并执行）· 试炼词条「运行时真表回读 + md5 零改动」自测
## Rank-2 交付件
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-074023-393-A2）④
##   + R31B 补回执 id cmd-20261111-141611-501-A2。
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_trial_modifier_runtime_v090b.gd
##
## 【与既有 verify_trial_modifier_v090.gd 的区别（本件专注「运行时真表」）】
## - 既有 V090 校验表结构 / 选择 / 条件 / 单调不减；本件用 CACHE_MODE_IGNORE
##   回读【真实落盘】trial_modifiers.tres 与 wave_trial.tres，实例化
##   TrialModifierService 做结算回归，并做 md5 前后对比证明既有 .tres 零改动。
## - 全程只读：ResourceLoader.load(CACHE_MODE_IGNORE) + 纯 RefCounted 服务，
##   不写任何存档、不改既有 .tres、不 add_child、不取 /root/... 绝对路径、
##   不用 get_tree()、不碰渲染；并发共享 user://slot_01/delta.json 会抖动，
##   本件不写生产存档。
## - --script 模式纪律：用 Engine.get_main_loop() as SceneTree 取 root 做只读断言。
##
## 覆盖：正常（三词条 [PLACEHOLDER] 倍率结算）/ 边界（互斥拒绝、未选回落、
##   余额非负）/ 异常（负点数、null stats、config=null、表被意外改写检测）。
## 输出逐条 PASS=true/false + SUMMARY + OVERALL=PASS/FAIL + RESULT=ALL_MATCH；
## 失败 quit(1)，不伪造 PASS。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const MODIFIER_PATH: String = "res://data/rpg/trial_modifiers.tres"
const WAVE_PATH: String = "res://data/rpg/wave_trial.tres"

## [PLACEHOLDER] R31 首版三词条倍率（校验基准，来自 trial_modifiers.tres 落盘真值）。
const EXPECT_MULT: Array = [1.5, 1.3, 1.4]
const EXPECT_IDS: Array = ["no_hit", "time_pressure", "low_vigor"]
## wave_trial.tres 三波 reward_points 首版 [PLACEHOLDER]（用作 base_points 真源）。
const EXPECT_WAVE_REWARDS: Array = [100, 150, 200]

var _pass: int = 0
var _fail: int = 0
var _md5_mod_before: String = ""
var _md5_wave_before: String = ""


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V090B-TM] %s PASS=%s | %s" % [tag, str(ok), detail])


## 只读计算 .tres 落盘文件的 md5（先 globalize 成 OS 绝对路径，失败回落 res:// 直读）。
func _md5(res_path: String) -> String:
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	var m: String = FileAccess.get_md5(abs_path)
	if m.is_empty():
		m = FileAccess.get_md5(res_path)
	return m


## 每次新建 Dictionary，避免共享引用被意外改写。
func _stats(damage: int, elapsed: float, limit: float, hp: float) -> Dictionary:
	return {
		"damage_taken": damage,
		"elapsed_sec": elapsed,
		"time_limit_sec": limit,
		"hp_ratio": hp,
	}


func _initialize() -> void:
	print("[V090B-TM] === SELFTEST START ===")
	# --script 模式纪律：Engine.get_main_loop() as SceneTree 取 root（只读断言）。
	var ml: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = ml as SceneTree
	var root_node: Node = tree.root if tree != null else null
	_ck("scene_tree_root_via_main_loop", tree != null and root_node != null,
		"Engine.get_main_loop() as SceneTree -> root，不用 get_tree()/绝对路径")

	# ---- md5 前：记录两份既有 .tres 的落盘真值 ----
	_md5_mod_before = _md5(MODIFIER_PATH)
	_md5_wave_before = _md5(WAVE_PATH)
	_ck("md5_before_modifier_nonempty", not _md5_mod_before.is_empty(),
		"trial_modifiers.tres md5(before)=%s" % _md5_mod_before)
	_ck("md5_before_wave_nonempty", not _md5_wave_before.is_empty(),
		"wave_trial.tres md5(before)=%s" % _md5_wave_before)

	# ---- CACHE_MODE_IGNORE 回读真实落盘表（校验磁盘真值而非缓存）----
	var mod_cfg: TrialModifierConfig = ResourceLoader.load(
		MODIFIER_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as TrialModifierConfig
	var wave_cfg: WaveTrialConfig = ResourceLoader.load(
		WAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as WaveTrialConfig
	_ck("modifier_table_load_cache_ignore", mod_cfg != null, "path=%s" % MODIFIER_PATH)
	_ck("wave_table_load_cache_ignore", wave_cfg != null, "path=%s" % WAVE_PATH)
	if mod_cfg == null or wave_cfg == null:
		_finish()
		return

	_test_wave_table(wave_cfg)          # wave_trial.tres 真表 + base_points 真源
	_test_multipliers(mod_cfg, wave_cfg)  # 正常：三词条 [PLACEHOLDER] 倍率结算
	_test_exclusive(mod_cfg)            # 边界：互斥拒绝
	_test_no_modifier_baseline(mod_cfg) # 边界：未选回落
	_test_balance_nonneg(mod_cfg)       # 边界：余额非负
	_test_invalid_inputs(mod_cfg)       # 异常：负点数 / null stats / config=null

	# ---- md5 后：证明本件全程只读，两份既有 .tres 零改动 ----
	var md5_mod_after: String = _md5(MODIFIER_PATH)
	var md5_wave_after: String = _md5(WAVE_PATH)
	print("[V090B-TM] MD5 trial_modifiers.tres before=%s after=%s" % [_md5_mod_before, md5_mod_after])
	print("[V090B-TM] MD5 wave_trial.tres    before=%s after=%s" % [_md5_wave_before, md5_wave_after])
	_ck("md5_trial_modifiers_zero_change", _md5_mod_before == md5_mod_after \
		and not md5_mod_after.is_empty(),
		"既有 trial_modifiers.tres 前后 md5 一致（零改动）")
	_ck("md5_wave_trial_zero_change", _md5_wave_before == md5_wave_after \
		and not md5_wave_after.is_empty(),
		"既有 wave_trial.tres 前后 md5 一致（零改动）")
	_finish()


## A) wave_trial.tres 真表：3 波 reward_points 与倍率真源（不写死、从表回读）
func _test_wave_table(wave_cfg: WaveTrialConfig) -> void:
	_ck("wave_count_3", wave_cfg.wave_count() == 3, "count=%d" % wave_cfg.wave_count())
	for i: int in range(3):
		var w: WaveTrialConfig.WaveData = wave_cfg.get_wave(i)
		_ck("wave_reward[%d]" % i, w != null and w.reward_points == int(EXPECT_WAVE_REWARDS[i]),
			"got=%s expect=%s [PLACEHOLDER]" % [str(w.reward_points if w != null else -1), str(EXPECT_WAVE_REWARDS[i])])
		_ck("wave_valid[%d]" % i, wave_cfg.is_wave_valid(w), "is_wave_valid=true")
	_ck("wave_bounds_null", wave_cfg.get_wave(-1) == null and wave_cfg.get_wave(3) == null,
		"越界波返回 null")


## B) [正常] 三词条结算符合 [PLACEHOLDER] 倍率（base_points 取自 wave_trial.tres 真表）
func _test_multipliers(mod_cfg: TrialModifierConfig, wave_cfg: WaveTrialConfig) -> void:
	_ck("modifier_count_3", mod_cfg.modifier_count() == 3, "count=%d" % mod_cfg.modifier_count())
	_ck("modifier_set_valid", mod_cfg.is_multiplier_set_valid(), "is_multiplier_set_valid=true")
	# 表内倍率与 [PLACEHOLDER] 期望逐项一致
	for i: int in range(3):
		var m: TrialModifierConfig.TrialModifier = mod_cfg.get_modifier(i)
		_ck("mult_ph[%d]" % i, m != null and is_equal_approx(m.reward_multiplier, float(EXPECT_MULT[i])),
			"got=%s expect=%s [PLACEHOLDER]" % [str(m.reward_multiplier if m != null else -1.0), str(EXPECT_MULT[i])])
	# base_points 真源：wave_trial.tres 第 1 波 reward_points = 100
	var w0: WaveTrialConfig.WaveData = wave_cfg.get_wave(0)
	var base: int = w0.reward_points
	_ck("base_from_wave_table", base == 100, "base_points=%d（取自真实 wave_trial.tres）" % base)

	# no_hit：damage_taken<=0 达成 -> floor(100*1.5)=150
	var s1: TrialModifierService = TrialModifierService.new(mod_cfg)
	s1.select("no_hit")
	var r1: Dictionary = s1.settle(base, _stats(0, 999.0, 30.0, 1.0))
	_ck("settle_no_hit_150", bool(r1.get("ok")) and int(r1.get("total_points")) == 150 \
		and is_equal_approx(float(r1.get("reward_multiplier")), 1.5),
		"no_hit 达成 -> total=150 mult=1.5 [PLACEHOLDER]")
	# time_pressure：elapsed=10 <= 30*0.6=18 达成 -> floor(100*1.3)=130
	var s2: TrialModifierService = TrialModifierService.new(mod_cfg)
	s2.select("time_pressure")
	var r2: Dictionary = s2.settle(base, _stats(1, 10.0, 30.0, 1.0))
	_ck("settle_time_pressure_130", bool(r2.get("ok")) and int(r2.get("total_points")) == 130 \
		and is_equal_approx(float(r2.get("reward_multiplier")), 1.3),
		"time_pressure 达成（10<=18）-> total=130 mult=1.3 [PLACEHOLDER]")
	# low_vigor：hp_ratio=0.4 <= 0.5 达成 -> floor(100*1.4)=140
	var s3: TrialModifierService = TrialModifierService.new(mod_cfg)
	s3.select("low_vigor")
	var r3: Dictionary = s3.settle(base, _stats(1, 999.0, 30.0, 0.4))
	_ck("settle_low_vigor_140", bool(r3.get("ok")) and int(r3.get("total_points")) == 140 \
		and is_equal_approx(float(r3.get("reward_multiplier")), 1.4),
		"low_vigor 达成（0.4<=0.5）-> total=140 mult=1.4 [PLACEHOLDER]")
	# 多词条取 max 不叠乘（防奖励通胀）：no_hit + time_pressure 跨组共存，两项达成取 1.5
	var s4: TrialModifierService = TrialModifierService.new(mod_cfg)
	s4.select("no_hit")
	s4.select("time_pressure")
	var r4: Dictionary = s4.settle(base, _stats(0, 10.0, 30.0, 0.4))
	_ck("settle_max_not_multiply", int(r4.get("total_points")) == 150,
		"两项达成取 max(1.5,1.3)=1.5 -> 150（非 195，不叠乘）")
	# 用第 2 波 reward_points=150 再验一组：floor(150*1.5)=225
	var w1: WaveTrialConfig.WaveData = wave_cfg.get_wave(1)
	var r5: Dictionary = s1.settle(w1.reward_points, _stats(0, 999.0, 30.0, 1.0))
	_ck("settle_wave2_base_225", int(r5.get("total_points")) == 225,
		"base=150（第 2 波）-> total=225")


## C) [边界] 互斥组拒绝：no_hit + low_vigor 同 survival 组
func _test_exclusive(mod_cfg: TrialModifierConfig) -> void:
	var svc: TrialModifierService = TrialModifierService.new(mod_cfg)
	svc.select("no_hit")
	var r_ex: Dictionary = svc.select("low_vigor")
	_ck("exclusive_same_group_rejected", not bool(r_ex.get("ok")) \
		and str(r_ex.get("reason")) == TrialModifierService.REASON_EXCLUSIVE,
		"no_hit + low_vigor 同 survival 组拒绝，reason=%s" % str(r_ex.get("reason")))
	_ck("exclusive_no_state_change", svc.get_selected_ids() == (["no_hit"] as Array[String]),
		"互斥拒绝不改选择态，selected=%s" % str(svc.get_selected_ids()))
	var r_dup: Dictionary = svc.select("no_hit")
	_ck("duplicate_rejected", not bool(r_dup.get("ok")) \
		and str(r_dup.get("reason")) == TrialModifierService.REASON_DUPLICATE,
		"重复 select 拒绝")
	svc.clear()
	_ck("clear_then_reselect_ok", bool(svc.select("low_vigor").get("ok")) \
		and svc.get_selected_ids() == (["low_vigor"] as Array[String]),
		"clear 后可重选 low_vigor")


## D) [边界] 未选回落基础结算（不惩罚、不加点）
func _test_no_modifier_baseline(mod_cfg: TrialModifierConfig) -> void:
	var svc: TrialModifierService = TrialModifierService.new(mod_cfg)
	var r: Dictionary = svc.settle(100, _stats(0, 10.0, 30.0, 0.4))
	_ck("no_modifier_baseline", bool(r.get("ok")) \
		and str(r.get("reason")) == TrialModifierService.REASON_NO_MODIFIER \
		and int(r.get("total_points")) == 100 and int(r.get("bonus_points")) == 0,
		"未选 -> 回落基础 100（reason=%s）" % str(r.get("reason")))
	# 已选但条件未达成 -> 同样回落基础，不惩罚
	var s2: TrialModifierService = TrialModifierService.new(mod_cfg)
	s2.select("no_hit")
	var r2: Dictionary = s2.settle(100, _stats(1, 999.0, 30.0, 1.0))
	_ck("condition_unmet_baseline", int(r2.get("total_points")) == 100 \
		and str(r2.get("reason")) == TrialModifierService.REASON_CONDITION_NOT_MET,
		"受击一次条件未达成 -> 回落基础 100")


## E) [边界] 余额非负：成功/未达成/大基数全程 balance>=0 且 bonus>=0
func _test_balance_nonneg(mod_cfg: TrialModifierConfig) -> void:
	var svc: TrialModifierService = TrialModifierService.new(mod_cfg)
	svc.select("low_vigor")
	var seq: Array[Dictionary] = []
	seq.append(svc.settle(0, _stats(1, 999.0, 30.0, 0.4)))
	seq.append(svc.settle(100, _stats(1, 999.0, 30.0, 0.4)))
	seq.append(svc.settle(100, _stats(1, 999.0, 30.0, 0.9)))  # 未达成回落
	seq.append(svc.settle(1000, _stats(1, 999.0, 30.0, 0.4)))
	var ok_all: bool = true
	for d: Dictionary in seq:
		if int(d.get("balance")) < 0 or int(d.get("balance")) != int(d.get("total_points")):
			ok_all = false
		if int(d.get("bonus_points")) < 0:
			ok_all = false
	_ck("balance_all_nonneg", ok_all, "全程 balance>=0 且 =total，bonus>=0")
	_ck("balance_unmet_no_break", int(seq[2].get("balance")) == 100,
		"条件未达成余额仍=100（非负）")


## F) [异常] 负点数 / null stats / 非 Dictionary stats / config=null / 异常不改状态
func _test_invalid_inputs(mod_cfg: TrialModifierConfig) -> void:
	var svc: TrialModifierService = TrialModifierService.new(mod_cfg)
	svc.select("no_hit")
	var r_neg: Dictionary = svc.settle(-1, _stats(0, 10.0, 30.0, 0.4))
	_ck("invalid_negative_base_rejected", not bool(r_neg.get("ok")) \
		and str(r_neg.get("reason")) == TrialModifierService.REASON_INVALID_POINTS,
		"base=-1 拒绝，reason=%s" % str(r_neg.get("reason")))
	_ck("invalid_negative_no_points", int(r_neg.get("total_points")) == 0 \
		and int(r_neg.get("balance")) == 0 and int(r_neg.get("bonus_points")) == 0,
		"拒绝时 total=0 balance=0 bonus=0（不产出负点数）")
	_ck("invalid_stats_null_rejected", not bool(svc.settle(100, null).get("ok")), "stats=null 拒绝")
	_ck("invalid_stats_string_rejected", not bool(svc.settle(100, "x").get("ok")), "stats=字符串 拒绝")
	var svc_null: TrialModifierService = TrialModifierService.new(null)
	_ck("invalid_no_config_rejected", not bool(svc_null.settle(100, _stats(0, 10.0, 30.0, 0.4)).get("ok")),
		"config=null 结算拒绝")
	_ck("invalid_no_state_change", svc.get_selected_ids() == (["no_hit"] as Array[String]),
		"异常输入不改选择态")
	var r_after: Dictionary = svc.settle(100, _stats(0, 10.0, 30.0, 0.4))
	_ck("invalid_then_normal_ok", bool(r_after.get("ok")) and int(r_after.get("total_points")) == 150,
		"异常拒绝后正常结算仍得 150（状态未被污染）")


func _finish() -> void:
	print("[V090B-TM] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V090B-TM] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V090B-TM] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V090B-TM] === SELFTEST END ===")
	quit(0 if all_ok else 1)
