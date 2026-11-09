extends RefCounted
class_name CombatDataValidator

## R21 / cmd-20261109-115818-641-A2 · Rank-2 CombatDataValidator 真实类落位
##
## 目标路径：res://scripts/combat/combat_data_validator.gd
## 本轮不注册 autoload（project.godot 本轮冻结，无人可写）。本类为纯数据校验器
## （extends RefCounted，无场景树 / 无 _ready 依赖），由 verify_frame_data.gd 通过
## preload + .new() 真实实例化并调用 validate_all() -> Dictionary。
##
## validate_all() 自加载 3 份运行权威 .tres，执行：
##   §9 校验式：E-1 / E-3 / E-4 / E-5 / E-8 / E-9（与 R20 组C 等价校验逐字同口径，
##              数据表schema.md §9；E-8 抗性溢出样本次数 = 8）；
##   帧数据专项断言：player_actions.tres 的 4/9/9=22 帧@60、无敌[4,13)；
##                   Boss 三招 p1_dagger_slash / p1_staff_slam / p2_holy_hammer 的
##                   47 / 71 / 91 帧与 hit 区间 [18,23) / [30,37) / [42,51)；
##   E-8 max_resistance 400 / 480 / 420（在 §9 E-8 内按 E8_MAX_RESISTANCE 逐项断言，
##              并由本类返回 e8_max_resistance 字符串供上层 SUMMARY 打印）。
## 返回 {checks, pass, fail, errors, e8_max_resistance, status}；PASS/FAIL 由
## 「实际值 vs 期望值」真实计算，不预设结论、不伪造输出；不写 project.godot / 场景 / 其它独占件。

const BOSS_TRES := "res://data/combat/boss_01_margit.tres"
const PLAYER_TRES := "res://data/combat/player_actions.tres"
const ENEMY_TRES := "res://data/combat/enemy_01_limgrave_soldier.tres"

# §9 E-8 抗性溢出公式的「触发次数样本」（数据表schema.md §9 E-8 的 × 8，R20 组C 同口径）
const RESISTANCE_SAMPLE_TRIGGERS := 8

# 帧数据专项断言期望值（与 verify_frame_data.gd 组A / 组B 同源）
const BOSS_POSE_MOVES := {
	"p1_dagger_slash": {"move_id": "move_01_dagger_slash", "startup": 18, "active": 5, "recovery": 24, "total": 47, "hit_start": 18, "hit_end": 23},
	"p1_staff_slam": {"move_id": "move_02_staff_slam", "startup": 30, "active": 7, "recovery": 34, "total": 71, "hit_start": 30, "hit_end": 37},
	"p2_holy_hammer": {"move_id": "move_03_holy_hammer", "startup": 42, "active": 9, "recovery": 40, "total": 91, "hit_start": 42, "hit_end": 51},
}
const ROLL_EXPECTED := {"startup": 4, "active": 9, "recovery": 9, "total": 22, "inv_start": 4, "inv_end": 13, "logic_fps": 60}
const E8_MAX_RESISTANCE := {"status_01_bleed": 400.0, "status_02_poison": 480.0, "status_03_frost": 420.0}

# §9 E-9 字段名白名单（与 R20 组C schema_fields 逐字一致：R2 全部 schema 类字段并集）
var _schema_fields: Array[String] = [
	"id", "display_name", "max_hp", "base_attack", "base_defense", "phases", "phase_thresholds",
	"poise", "status_buildups", "aggro_radius_px", "lose_radius_px", "chase_speed_px_per_sec",
	"attack_range_px", "ai_poll_interval_sec", "rng_seed", "defeated_flag_key", "death_pose_name",
	"phase_transition_enabled",
	"phase_index", "hp_ratio_enter", "hp_ratio_exit", "phase_damage_multiplier", "phase_defense",
	"sprite_frames_path", "pose_prefix", "moves", "poise_override", "status_resistance_multiplier",
	"transition_pose_name", "transition_frames", "transition_invulnerable", "aggression",
	"pose_name", "startup_frames", "active_frames", "recovery_frames", "motion_multiplier",
	"damage_type", "poise_damage", "status_buildup_bleed", "status_buildup_poison",
	"status_buildup_frost", "hitbox_reach_px", "hitbox_arc_deg", "hitbox_offset_px",
	"min_range_px", "max_range_px", "weight", "cooldown_sec", "can_cancel_frames", "breaks_guard",
	"max_poise", "poise_regen_per_sec", "poise_regen_delay_sec", "stance_break_duration_sec",
	"stance_break_damage_multiplier", "executable", "execute_hp_ratio_threshold",
	"poise_break_pose_name", "poise_break_frame",
	"status_type", "threshold", "decay_per_sec", "decay_delay_sec", "trigger_damage_ratio",
	"trigger_damage_flat", "trigger_poise_damage", "trigger_pose_name", "trigger_frame",
	"duration_sec", "tick_damage_per_sec", "resistance_gain_per_trigger", "max_resistance",
	"action_name", "state_name", "pose_frame_offset", "invulnerable_start_frame",
	"invulnerable_end_frame", "logic_fps", "move_speed_px_per_sec", "state_priority",
	"can_cancel_into", "stamina_cost", "cancel_window_frames",
	"request_id", "enemy_id", "spawn_point_id", "position", "facing_degrees", "level",
	"hp_override", "stance_override", "aggro_radius", "leash_radius", "respawn_policy",
	"defeated_flag", "loot_table_id", "patrol_route", "is_boss", "spawn_group_id", "metadata",
	"actions",
]

# 采集容器（与 R20 组C _validator_collect 逐字一致，保证 §9 E-9 字段实例数一致）
var _v_moves: Array = []
var _v_actions: Array = []
var _v_buildup_hosts: Array = []
var _v_resources: Array = []
var _v_boss_moves: Array = []
var _v_enemy_move_sets: Array = []
var _v_enemies: Array = []

# 计数与错误明细
var _checks: int = 0
var _pass: int = 0
var _fail: int = 0
var _errors: Array[String] = []


## §9 + 帧数据专项断言统一入口：真实实例化后由外部调用，返回结构化结果。
func validate_all() -> Dictionary:
	_reset()
	var boss = load(BOSS_TRES)
	var player = load(PLAYER_TRES)
	var enemy = load(ENEMY_TRES)
	if boss == null or player == null or enemy == null:
		_checks += 1
		_fail += 1
		_errors.append("资源加载失败 boss/player/enemy -> boss_null=%s player_null=%s enemy_null=%s" % [str(boss == null), str(player == null), str(enemy == null)])
		return _build_result("LOAD_FAILED", "N/A")
	_collect(boss, player, enemy)

	# ---- §9 校验式（E-1 / E-3 / E-4 / E-5 / E-8 / E-9）----
	_validate_e1(boss)
	_validate_e3()
	_validate_e4(boss)
	_validate_e5(boss)
	_validate_e8(boss)
	_validate_e9()

	# ---- 帧数据专项断言（任务③）----
	_validate_frame_data(boss, player)

	var e8 := _e8_actual_string(boss)
	# 类级 print：证明类被真实实例化且 validate_all() 已执行（逐项明细静默计数，不刷屏）
	print("[CombatDataValidator] validate_all() | checks=%d pass=%d fail=%d errors=%d | E-8 max_resistance(bleed/poison/frost)=%s" % [_checks, _pass, _fail, _errors.size(), e8])
	return _build_result("OK", e8)


func _reset() -> void:
	_v_moves = []
	_v_actions = []
	_v_buildup_hosts = []
	_v_resources = []
	_v_boss_moves = []
	_v_enemy_move_sets = []
	_v_enemies = []
	_checks = 0
	_pass = 0
	_fail = 0
	_errors = []


func _record(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		_pass += 1
	else:
		_fail += 1
		_errors.append(label)


func _build_result(status: String, e8: String) -> Dictionary:
	return {
		"checks": _checks,
		"pass": _pass,
		"fail": _fail,
		"errors": _errors.duplicate(),
		"e8_max_resistance": e8,
		"status": status,
	}


# ---------------------------------------------------------------- 采集（逐字复刻 R20 组C）
func _collect(boss: Variant, player: Variant, enemy: Variant) -> void:
	if boss != null:
		_v_resources.append(boss)
		if boss.get("poise") != null:
			_v_resources.append(boss.get("poise"))
		_v_buildup_hosts.append(boss.get("status_buildups"))
		for b in boss.get("status_buildups"):
			_v_resources.append(b)
		for p in boss.get("phases"):
			_v_resources.append(p)
			if p.get("poise_override") != null:
				_v_resources.append(p.get("poise_override"))
			for m in p.get("moves"):
				_v_moves.append(m)
				_v_boss_moves.append(m)
				_v_resources.append(m)
	if enemy != null:
		_v_enemies.append(enemy)
		_v_resources.append(enemy)
		if enemy.get("poise") != null:
			_v_resources.append(enemy.get("poise"))
		_v_buildup_hosts.append(enemy.get("status_buildups"))
		for b in enemy.get("status_buildups"):
			_v_resources.append(b)
		var em: Array = []
		for m in enemy.get("moves"):
			_v_moves.append(m)
			em.append(m)
			_v_resources.append(m)
		_v_enemy_move_sets.append(em)
	if player != null:
		_v_resources.append(player)
		for a in player.get("actions"):
			_v_actions.append(a)
			_v_resources.append(a)


# ---------------------------------------------------------------- E-1
func _validate_e1(boss: Variant) -> void:
	var phases = boss.get("phases")
	var thresholds = boss.get("phase_thresholds")
	_record(thresholds.size() == maxi(0, phases.size() - 1), "E-1 阈值表长度 = 阶段数-1")
	for i in range(phases.size()):
		var p = phases[i]
		var pid := String(p.get("id"))
		_record(int(p.get("phase_index")) == i + 1, "E-1 phase_index==下标+1 -> %s" % pid)
		if i < thresholds.size():
			_record(is_equal_approx(float(thresholds[i]), float(p.get("hp_ratio_exit"))), "E-1 threshold==hp_ratio_exit -> %s" % pid)
		if i + 1 < phases.size():
			_record(is_equal_approx(float(p.get("hp_ratio_exit")), float(phases[i + 1].get("hp_ratio_enter"))), "E-1 exit==下一阶段 enter -> %s" % pid)


# ---------------------------------------------------------------- E-3
func _validate_e3() -> void:
	for m in _v_moves:
		_record(int(m.get("can_cancel_frames")) <= int(m.get("recovery_frames")), "E-3 can_cancel_frames<=recovery -> %s" % String(m.get("id")))
	for a in _v_actions:
		_record(int(a.get("cancel_window_frames")) <= int(a.get("recovery_frames")), "E-3 cancel_window_frames<=recovery -> %s" % String(a.get("id")))


# ---------------------------------------------------------------- E-4
func _validate_e4(boss: Variant) -> void:
	for m in _v_moves:
		_record(float(m.get("min_range_px")) <= float(m.get("max_range_px")), "E-4 min<=max -> %s" % String(m.get("id")))
	_record(float(boss.get("attack_range_px")) <= _max_move_range(_v_boss_moves), "E-4 Boss attack_range<=max(moves.max_range)")
	for i in range(_v_enemy_move_sets.size()):
		var set_moves: Array = _v_enemy_move_sets[i]
		if not set_moves.is_empty():
			_record(float(_v_enemies[i].get("attack_range_px")) <= _max_move_range(set_moves), "E-4 敌人 attack_range<=max(moves.max_range) -> %s" % String(_v_enemies[i].get("id")))


func _max_move_range(moves: Array) -> float:
	var result := 0.0
	for m in moves:
		var mr := float(m.get("max_range_px"))
		if mr > result:
			result = mr
	return result


# ---------------------------------------------------------------- E-5
func _validate_e5(boss: Variant) -> void:
	_record(float(boss.get("lose_radius_px")) > float(boss.get("aggro_radius_px")), "E-5 Boss lose>aggro")
	for e in _v_enemies:
		_record(float(e.get("lose_radius_px")) > float(e.get("aggro_radius_px")), "E-5 敌人 lose>aggro -> %s" % String(e.get("id")))


# ---------------------------------------------------------------- E-8（含 400/480/420 实际值断言）
func _validate_e8(boss: Variant) -> void:
	var n := RESISTANCE_SAMPLE_TRIGGERS
	for host in _v_buildup_hosts:
		var seen := {}
		for b in host:
			var bid := String(b.get("id"))
			var stype := String(b.get("status_type"))
			_record(not seen.has(stype), "E-8 status_type 不重复 -> %s" % stype)
			seen[stype] = true
			var limit := float(b.get("threshold")) + float(b.get("resistance_gain_per_trigger")) * float(n)
			_record(limit <= float(b.get("max_resistance")), "E-8 抗性不溢出 -> %s | limit=%s <= max_resistance=%s" % [bid, str(limit), str(float(b.get("max_resistance")))])
			if E8_MAX_RESISTANCE.has(bid):
				_record(float(b.get("max_resistance")) == float(E8_MAX_RESISTANCE[bid]), "E-8 max_resistance[%s] 仍为 R10 裁决值 400/480/420" % bid)


# ---------------------------------------------------------------- E-9
func _validate_e9() -> void:
	var e9_oob: Array[String] = []
	for res in _v_resources:
		for prop in res.get_property_list():
			var usage := int(prop.get("usage", 0))
			if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
				continue
			var fname := String(prop.get("name", ""))
			if fname == "script":
				continue
			var hit := _schema_fields.has(fname)
			_record(hit, "E-9 字段名命中 schema -> %s" % fname)
			if not hit:
				e9_oob.append(fname)
	_record(e9_oob.is_empty(), "E-9 字段名 ⊆ schema 白名单 | 越界=%d" % e9_oob.size())


# ---------------------------------------------------------------- 帧数据专项断言（任务③）
func _validate_frame_data(boss: Variant, player: Variant) -> void:
	# --- player_actions.tres：4/9/9=22 帧@60、无敌[4,13) ---
	var actions := {}
	for ac in player.get("actions"):
		actions[String(ac.get("id"))] = ac
	_record(actions.has("action_04_roll"), "PLAYER action_04_roll 存在")
	if actions.has("action_04_roll"):
		var ac = actions["action_04_roll"]
		var s := int(ac.get("startup_frames"))
		var a := int(ac.get("active_frames"))
		var r := int(ac.get("recovery_frames"))
		var ist := int(ac.get("invulnerable_start_frame"))
		var ien := int(ac.get("invulnerable_end_frame"))
		var fps := int(ac.get("logic_fps"))
		var total := s + a + r
		_record(s == int(ROLL_EXPECTED["startup"]), "PLAYER roll.startup_frames==4")
		_record(a == int(ROLL_EXPECTED["active"]), "PLAYER roll.active_frames==9")
		_record(r == int(ROLL_EXPECTED["recovery"]), "PLAYER roll.recovery_frames==9")
		_record(total == int(ROLL_EXPECTED["total"]), "PLAYER roll.total(4+9+9)==22")
		_record(fps == int(ROLL_EXPECTED["logic_fps"]), "PLAYER roll.logic_fps==60 (@60)")
		_record(ist == int(ROLL_EXPECTED["inv_start"]), "PLAYER roll.invulnerable_start_frame==4")
		_record(ien == int(ROLL_EXPECTED["inv_end"]), "PLAYER roll.invulnerable_end_frame==13")
		_record(ist == s, "PLAYER E-7 inv_start==startup")
		_record(ien == s + a, "PLAYER E-7 inv_end==startup+active (无敌[4,13))")
		_record(ien - ist == a, "PLAYER E-7 无敌长度==active")
		_record(ist >= 0 and ist < ien and ien <= total, "PLAYER E-7 0<=start<end<=total")
	var all60 := true
	for aid in actions.keys():
		if int(actions[aid].get("logic_fps")) != 60:
			all60 = false
	_record(actions.size() == 8, "PLAYER actions==8")
	_record(all60, "PLAYER 8 条 logic_fps 全==60 (@60)")

	# --- Boss 三招 pose key：47/71/91 与 hit 区间 ---
	var pose_moves := {}
	for ph in boss.get("phases"):
		var prefix := String(ph.get("pose_prefix"))
		for mv in ph.get("moves"):
			var key := prefix + String(mv.get("pose_name"))
			if not pose_moves.has(key):
				pose_moves[key] = mv
	var keys := BOSS_POSE_MOVES.keys()
	keys.sort()
	for key in keys:
		var exp = BOSS_POSE_MOVES[key]
		_record(pose_moves.has(key), "BOSS pose key 存在 -> %s" % key)
		if not pose_moves.has(key):
			continue
		var mv = pose_moves[key]
		var s := int(mv.get("startup_frames"))
		var a := int(mv.get("active_frames"))
		var r := int(mv.get("recovery_frames"))
		_record(String(mv.get("id")) == String(exp["move_id"]), "BOSS %s -> move_id==%s" % [key, String(exp["move_id"])])
		_record(s == int(exp["startup"]), "BOSS %s.startup_frames==%d" % [key, int(exp["startup"])])
		_record(a == int(exp["active"]), "BOSS %s.active_frames==%d" % [key, int(exp["active"])])
		_record(r == int(exp["recovery"]), "BOSS %s.recovery_frames==%d" % [key, int(exp["recovery"])])
		_record(s + a + r == int(exp["total"]), "BOSS %s.total==%d (47/71/91)" % [key, int(exp["total"])])
		_record(s == int(exp["hit_start"]), "BOSS %s 判定区间 start==startup==%d" % [key, int(exp["hit_start"])])
		_record(s + a == int(exp["hit_end"]), "BOSS %s 判定区间 end==startup+active==%d (hit=[%d,%d))" % [key, int(exp["hit_end"]), int(exp["hit_start"]), int(exp["hit_end"])])


func _e8_actual_string(boss: Variant) -> String:
	var parts: Array[String] = []
	for bid in ["status_01_bleed", "status_02_poison", "status_03_frost"]:
		for b in boss.get("status_buildups"):
			if String(b.get("id")) == bid:
				parts.append(str(float(b.get("max_resistance"))))
	if parts.size() != 3:
		return "MISSING"
	return "%s / %s / %s" % [parts[0], parts[1], parts[2]]
