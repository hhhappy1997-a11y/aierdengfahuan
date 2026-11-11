extends SceneTree

## ===========================================================================
## R26 / v0.4.0 · 波次试炼数据表自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_wave_trial_v040.gd
## 断言（任务单 ④）：3 波 / 倍率与奖励单调递增 / 第 0·4 波越界拒绝 /
##   空表·字段缺失降级 / time_limit 与 telegraph 合法；输出 PASS/FAIL 与 RESULT，
##   失败 quit(1)，不伪造 PASS。
## 期望值来自任务单 ② 首版 [PLACEHOLDER]，试玩校准后需同步更新本文件 EXPECT_*
##   与 WAVE-TRIAL-TUNING.md §1，不静默改数。
## 读表统一走 CACHE_MODE_IGNORE，校验落盘真值而非缓存。
## ===========================================================================

const TABLE_PATH: String = "res://data/rpg/wave_trial.tres"
const ENEMY_TABLE_PATH: String = "res://data/combat/enemy_01_limgrave_soldier.tres"
const BOSS_TABLE_PATH: String = "res://data/combat/boss_01_margit.tres"

const FIELD_KEYS: Array = [
	"enemy_id", "hp_multiplier", "move_weight", "reward_points", "telegraph_sec", "time_limit_sec"]

# [PLACEHOLDER] R26 首版期望（任务单 ②），校验基准，不写进数据表；待人工试玩校准。
const EXPECT_IDS: Array = [
	"enemy_01_limgrave_soldier", "enemy_01_limgrave_soldier", "boss_01_margit"]
const EXPECT_HP: Array = [1.0, 1.3, 1.6]
const EXPECT_REWARD: Array = [100, 150, 200]
const EXPECT_MOVE_WEIGHT: float = 1.0
const EXPECT_TELEGRAPH_SEC: float = 1.5
const EXPECT_TIME_LIMIT_SEC: float = 30.0

var _pass: int = 0
var _fail: int = 0


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V040] %s PASS=%s | %s" % [tag, str(ok), detail])


func _initialize() -> void:
	print("[V040] === SELFTEST START ===")
	var cfg: WaveTrialConfig = ResourceLoader.load(
		TABLE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as WaveTrialConfig
	_ck("table_load_cache_ignore", cfg != null, "path=%s" % TABLE_PATH)
	if cfg == null:
		_finish()
		return
	_test_structure(cfg)
	_test_monotonic(cfg)
	_test_bounds(cfg)
	_test_degrade(cfg)
	_test_timing(cfg)
	_test_reuse_existing(cfg)
	_finish()


## ① 3 波 / 6 字段齐全 / 逐字段等于首版 [PLACEHOLDER] 期望 / 每波合法。
func _test_structure(cfg: WaveTrialConfig) -> void:
	_ck("wave_count_3", cfg.wave_count() == 3 and cfg.waves.size() == 3,
		"count=%d size=%d" % [cfg.wave_count(), cfg.waves.size()])
	for i: int in range(3):
		var row: Dictionary = cfg.waves[i]
		var missing: Array[String] = []
		for k: String in FIELD_KEYS:
			if not row.has(k):
				missing.append(k)
		_ck("wave_fields[%d]" % i, missing.is_empty(),
			"keys=%d missing=%s" % [row.size(), str(missing)])
		_ck("wave_enemy_id[%d]" % i, str(row.get("enemy_id")) == str(EXPECT_IDS[i]),
			"got=%s expect=%s" % [str(row.get("enemy_id")), str(EXPECT_IDS[i])])
		_ck("wave_hp[%d]" % i, float(row.get("hp_multiplier")) == float(EXPECT_HP[i]),
			"got=%s expect=%s" % [str(row.get("hp_multiplier")), str(EXPECT_HP[i])])
		_ck("wave_reward[%d]" % i, int(row.get("reward_points")) == int(EXPECT_REWARD[i]),
			"got=%s expect=%s" % [str(row.get("reward_points")), str(EXPECT_REWARD[i])])
		_ck("wave_move_weight[%d]" % i, float(row.get("move_weight")) == EXPECT_MOVE_WEIGHT,
			"got=%s expect=%s" % [str(row.get("move_weight")), str(EXPECT_MOVE_WEIGHT)])
		_ck("wave_telegraph[%d]" % i, float(row.get("telegraph_sec")) == EXPECT_TELEGRAPH_SEC,
			"got=%s expect=%s" % [str(row.get("telegraph_sec")), str(EXPECT_TELEGRAPH_SEC)])
		_ck("wave_time_limit[%d]" % i, float(row.get("time_limit_sec")) == EXPECT_TIME_LIMIT_SEC,
			"got=%s expect=%s" % [str(row.get("time_limit_sec")), str(EXPECT_TIME_LIMIT_SEC)])
		_ck("wave_valid[%d]" % i, cfg.is_wave_valid(cfg.get_wave(i)),
			"is_wave_valid=true")
	var made: Dictionary = cfg.make_wave("x", 1.0, 1.0, 0, 1.5, 30.0)
	_ck("make_wave_6_fields", made.size() == 6, "size=%d" % made.size())


## ② 倍率与奖励严格单调递增（逐段打印实测值，便于人工核对）。
func _test_monotonic(cfg: WaveTrialConfig) -> void:
	var hp_ok: bool = true
	var reward_ok: bool = true
	for i: int in range(2):
		var ra: Dictionary = cfg.waves[i]
		var rb: Dictionary = cfg.waves[i + 1]
		var hp_a: float = float(ra.get("hp_multiplier"))
		var hp_b: float = float(rb.get("hp_multiplier"))
		var rw_a: int = int(ra.get("reward_points"))
		var rw_b: int = int(rb.get("reward_points"))
		if not (hp_a < hp_b):
			hp_ok = false
		if not (rw_a < rw_b):
			reward_ok = false
		print("[V040] monotonic_step[%d] hp %s<%s reward %s<%s" % [
			i, str(hp_a), str(hp_b), str(rw_a), str(rw_b)])
	_ck("hp_multiplier_strictly_increasing", hp_ok, "1.0<1.3<1.6")
	_ck("reward_points_strictly_increasing", reward_ok, "100<150<200")


## ③ 越界拒绝：3 波合法下标 0..2；波号 0（负下标）与第 4 波（index>=3）均拒绝。
func _test_bounds(cfg: WaveTrialConfig) -> void:
	_ck("bound_wave0_negative_rejected", cfg.get_wave(-1) == null,
		"index=-1 -> null（第 0 波 / 负下标）")
	_ck("bound_wave4_index3_rejected", cfg.get_wave(3) == null,
		"index=3 -> null（第 4 波）")
	_ck("bound_wave4_index4_rejected", cfg.get_wave(4) == null,
		"index=4 -> null")
	_ck("bound_legal_0_1_2",
		cfg.get_wave(0) != null and cfg.get_wave(1) != null and cfg.get_wave(2) != null,
		"合法下标 0..2 均可取")
	_ck("bound_no_wraparound", cfg.get_wave(3) != cfg.get_wave(0),
		"越界不回绕到首波")


## ④ 空表 / 字段缺失降级：不崩、回落 [PLACEHOLDER] 基线、缺 id 判非法。
func _test_degrade(cfg: WaveTrialConfig) -> void:
	var empty: WaveTrialConfig = WaveTrialConfig.new()
	_ck("degrade_empty_count_0", empty.wave_count() == 0, "count=%d" % empty.wave_count())
	_ck("degrade_empty_get_wave_null", empty.get_wave(0) == null,
		"空表 get_wave(0)=null 不崩")
	_ck("degrade_null_wave_invalid", not cfg.is_wave_valid(null),
		"is_wave_valid(null)=false")
	var d0 := cfg.wave_from_dict({})
	_ck("degrade_all_missing_no_crash", d0 != null, "wave_from_dict({}) 返回视图")
	_ck("degrade_all_missing_defaults",
		d0.enemy_id == WaveTrialConfig.DEFAULT_ENEMY_ID
		and d0.hp_multiplier == WaveTrialConfig.DEFAULT_HP_MULTIPLIER
		and d0.move_weight == WaveTrialConfig.DEFAULT_MOVE_WEIGHT
		and d0.reward_points == WaveTrialConfig.DEFAULT_REWARD_POINTS
		and d0.telegraph_sec == WaveTrialConfig.DEFAULT_TELEGRAPH_SEC
		and d0.time_limit_sec == WaveTrialConfig.DEFAULT_TIME_LIMIT_SEC,
		"6 字段全回落 [PLACEHOLDER] 基线")
	_ck("degrade_all_missing_invalid", not cfg.is_wave_valid(d0),
		"enemy_id 空 -> 判非法")
	var d1 := cfg.wave_from_dict({"enemy_id": "enemy_01_limgrave_soldier"})
	_ck("degrade_partial_missing_valid", cfg.is_wave_valid(d1),
		"仅给 enemy_id，其余回落基线且合法")
	_ck("degrade_partial_timing_filled",
		d1.telegraph_sec == WaveTrialConfig.DEFAULT_TELEGRAPH_SEC
		and d1.time_limit_sec == WaveTrialConfig.DEFAULT_TIME_LIMIT_SEC,
		"telegraph=%s time_limit=%s" % [str(d1.telegraph_sec), str(d1.time_limit_sec)])
	# 模拟 .tres 里读到「半行」数据：缺字段必须同样降级，不抛错
	var partial: WaveTrialConfig = WaveTrialConfig.new()
	partial.waves.append({"enemy_id": "enemy_01_limgrave_soldier", "hp_multiplier": 2.0})
	var pv := partial.get_wave(0)
	_ck("degrade_tres_row_partial_no_crash", pv != null, "半行 Dictionary 不崩")
	_ck("degrade_tres_row_partial_filled",
		pv != null and pv.reward_points == WaveTrialConfig.DEFAULT_REWARD_POINTS
		and pv.telegraph_sec == WaveTrialConfig.DEFAULT_TELEGRAPH_SEC,
		"reward=%s telegraph=%s" % [
			str(pv.reward_points) if pv != null else "null",
			str(pv.telegraph_sec) if pv != null else "null"])


## ⑤ time_limit 与 telegraph 合法性：3 波合法；6 类非法组合逐一拒绝。
func _test_timing(cfg: WaveTrialConfig) -> void:
	_ck("timing_all_3_valid",
		cfg.is_wave_valid(cfg.get_wave(0))
		and cfg.is_wave_valid(cfg.get_wave(1))
		and cfg.is_wave_valid(cfg.get_wave(2)),
		"3 波 telegraph>0 / time_limit>0 / telegraph<time_limit")
	var bad_t_zero: Dictionary = cfg.make_wave("x", 1.0, 1.0, 0, 0.0, 30.0)
	_ck("timing_telegraph_zero_invalid",
		not cfg.is_wave_valid(cfg.wave_from_dict(bad_t_zero)), "telegraph=0 -> false")
	var bad_t_neg: Dictionary = cfg.make_wave("x", 1.0, 1.0, 0, -1.0, 30.0)
	_ck("timing_telegraph_negative_invalid",
		not cfg.is_wave_valid(cfg.wave_from_dict(bad_t_neg)), "telegraph=-1 -> false")
	var bad_l_zero: Dictionary = cfg.make_wave("x", 1.0, 1.0, 0, 1.5, 0.0)
	_ck("timing_time_limit_zero_invalid",
		not cfg.is_wave_valid(cfg.wave_from_dict(bad_l_zero)), "time_limit=0 -> false")
	var bad_l_neg: Dictionary = cfg.make_wave("x", 1.0, 1.0, 0, 1.5, -5.0)
	_ck("timing_time_limit_negative_invalid",
		not cfg.is_wave_valid(cfg.wave_from_dict(bad_l_neg)), "time_limit=-5 -> false")
	var bad_order_eq: Dictionary = cfg.make_wave("x", 1.0, 1.0, 0, 30.0, 30.0)
	_ck("timing_telegraph_eq_limit_invalid",
		not cfg.is_wave_valid(cfg.wave_from_dict(bad_order_eq)), "telegraph=time_limit=30 -> false")
	var bad_order_gt: Dictionary = cfg.make_wave("x", 1.0, 1.0, 0, 31.0, 30.0)
	_ck("timing_telegraph_gt_limit_invalid",
		not cfg.is_wave_valid(cfg.wave_from_dict(bad_order_gt)), "telegraph=31>30 -> false")
	var good: Dictionary = cfg.make_wave("x", 1.0, 1.0, 0, 1.5, 30.0)
	_ck("timing_valid_pair_ok", cfg.is_wave_valid(cfg.wave_from_dict(good)),
		"1.5<30 -> true")
	var bad_hp: Dictionary = cfg.make_wave("x", 0.0, 1.0, 0, 1.5, 30.0)
	_ck("timing_hp_zero_invalid",
		not cfg.is_wave_valid(cfg.wave_from_dict(bad_hp)), "hp_multiplier=0 -> false")
	var bad_reward: Dictionary = cfg.make_wave("x", 1.0, 1.0, -1, 1.5, 30.0)
	_ck("timing_negative_reward_invalid",
		not cfg.is_wave_valid(cfg.wave_from_dict(bad_reward)), "reward=-1 -> false")


## ⑥ 复用既有敌人表（不新增数据表）+ 点访问 / 字典式访问双兼容。
func _test_reuse_existing(cfg: WaveTrialConfig) -> void:
	var enemy_tbl: Resource = load(ENEMY_TABLE_PATH) as Resource
	var boss_tbl: Resource = load(BOSS_TABLE_PATH) as Resource
	_ck("reuse_enemy_table_exists", enemy_tbl != null, "path=%s" % ENEMY_TABLE_PATH)
	_ck("reuse_boss_table_exists", boss_tbl != null, "path=%s" % BOSS_TABLE_PATH)
	var allowed: Array[String] = ["enemy_01_limgrave_soldier", "boss_01_margit"]
	var all_in: bool = true
	for i: int in range(3):
		var row: Dictionary = cfg.waves[i]
		if not allowed.has(str(row.get("enemy_id"))):
			all_in = false
	_ck("reuse_ids_only_existing", all_in, "3 波 enemy_id 均来自既有两表 id")
	var v := cfg.get_wave(2)
	_ck("view_dot_and_index_equal",
		v != null and v.hp_multiplier == float(v["hp_multiplier"]),
		"get_wave(2).hp_multiplier == get_wave(2)[\"hp_multiplier\"]")


func _finish() -> void:
	print("[V040] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	print("[V040] RESULT=%s" % ("ALL_MATCH" if _fail == 0 else "FAILED"))
	print("[V040] === SELFTEST END ===")
	quit(0 if _fail == 0 else 1)
