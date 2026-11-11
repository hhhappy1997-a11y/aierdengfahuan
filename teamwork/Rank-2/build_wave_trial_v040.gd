extends SceneTree

## ===========================================================================
## R26 / v0.4.0 · 波次试炼数据表构建器（Rank-2 自有件，落 teamwork/Rank-2/）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot \
##       --script F:/Game/aierdengfahuan/teamwork/Rank-2/build_wave_trial_v040.gd
## 职责：WaveTrialConfig.make_wave 构造 3 波 → ResourceSaver.save 落盘
##       → ResourceLoader.load(CACHE_MODE_IGNORE) 回读逐字段校验 → BUILD_PASS/FAIL。
## [PLACEHOLDER] 首版数值来自任务单 ②；逐项 rationale 见 WAVE-TRIAL-TUNING.md §2。
## 敌人 id 复用既有 enemy_01_limgrave_soldier / boss_01_margit，不新增数据表。
## ===========================================================================

const OUT_PATH: String = "res://data/rpg/wave_trial.tres"

# [PLACEHOLDER] 首版三波（任务单 ② 给定值）；三波敌人编排为「士兵→士兵→Boss」，待试玩校准。
var WAVE_ROWS: Array = [
	{"enemy_id": "enemy_01_limgrave_soldier", "hp_multiplier": 1.0, "move_weight": 1.0, "reward_points": 100, "telegraph_sec": 1.5, "time_limit_sec": 30.0},
	{"enemy_id": "enemy_01_limgrave_soldier", "hp_multiplier": 1.3, "move_weight": 1.0, "reward_points": 150, "telegraph_sec": 1.5, "time_limit_sec": 30.0},
	{"enemy_id": "boss_01_margit", "hp_multiplier": 1.6, "move_weight": 1.0, "reward_points": 200, "telegraph_sec": 1.5, "time_limit_sec": 30.0},
]

var FIELDS: PackedStringArray = PackedStringArray([
	"enemy_id", "hp_multiplier", "move_weight", "reward_points", "telegraph_sec", "time_limit_sec"])


func _initialize() -> void:
	print("[BUILD] === wave_trial.tres BUILD START ===")
	var cfg: WaveTrialConfig = WaveTrialConfig.new()
	for row: Dictionary in WAVE_ROWS:
		cfg.waves.append(cfg.make_wave(
			str(row["enemy_id"]),
			float(row["hp_multiplier"]),
			float(row["move_weight"]),
			int(row["reward_points"]),
			float(row["telegraph_sec"]),
			float(row["time_limit_sec"])))
	var err: int = ResourceSaver.save(cfg, OUT_PATH)
	print("[BUILD] ResourceSaver.save err=%d path=%s waves=%d" % [err, OUT_PATH, cfg.wave_count()])
	if err != OK:
		print("[BUILD] BUILD_FAIL save_error")
		print("[BUILD] RESULT=BUILD_FAILED")
		quit(1)
		return
	# CACHE_MODE_IGNORE 强制绕缓存读盘，回读校验落盘真值
	var back: WaveTrialConfig = ResourceLoader.load(
		OUT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as WaveTrialConfig
	if back == null:
		print("[BUILD] BUILD_FAIL load_null")
		print("[BUILD] RESULT=BUILD_FAILED")
		quit(1)
		return
	var ok: bool = true
	if back.wave_count() != WAVE_ROWS.size():
		ok = false
		print("[BUILD] wave_count mismatch got=%d expect=%d" % [back.wave_count(), WAVE_ROWS.size()])
	for i: int in range(WAVE_ROWS.size()):
		var row: Dictionary = back.waves[i] as Dictionary
		var expect_row: Dictionary = WAVE_ROWS[i]
		for f: String in FIELDS:
			var got: Variant = row.get(f)
			var expect: Variant = expect_row[f]
			var same: bool = (str(got) == str(expect))
			if not same:
				ok = false
			print("[BUILD] wave[%d].%s = %s | expect=%s | %s" % [
				i, f, str(got), str(expect), "OK" if same else "MISMATCH"])
		# 静态类型视图（get_wave）与合法性一并回读校验
		var view := back.get_wave(i)
		if view == null:
			ok = false
			print("[BUILD] wave[%d] get_wave=null" % i)
		else:
			var view_ok: bool = (view.hp_multiplier == float(expect_row["hp_multiplier"])
				and view.reward_points == int(expect_row["reward_points"])
				and str(view["enemy_id"]) == str(expect_row["enemy_id"]))
			if not view_ok:
				ok = false
			print("[BUILD] wave[%d] view.hp=%s view.reward=%s view_ok=%s valid=%s" % [
				i, str(view.hp_multiplier), str(view.reward_points), str(view_ok),
				str(back.is_wave_valid(view))])
	print("[BUILD] SUMMARY ok=%s" % str(ok))
	print("[BUILD] RESULT=%s" % ("BUILT_AND_VERIFIED" if ok else "BUILD_FAILED"))
	print("[BUILD] === wave_trial.tres BUILD END ===")
	quit(0 if ok else 1)
