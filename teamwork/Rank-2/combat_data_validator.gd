extends Node
class_name CombatDataValidator

## 2 号工位 · 数据表自洽运行时自检（启动即报，非探针 / 非测量 / 非 preflight 脚本）
##
## 在 _ready() 执行 E-1 / E-3 / E-4 / E-5 / E-8 / E-9（E-6 / E-7 已在 player_state_machine.gd 实现，
## 本脚本不重复）。把「数据表自洽」从静态核对变成引擎启动即输出的事实。
## 校验等式定义见 teamwork/Rank-2/数据表schema.md §9；本文件不含任何战斗数值，
## 唯一可调的校验口径参数 resistance_sample_triggers 以 @export 暴露（改数值不改代码）。
## I-2：本脚本不写 flag、不 emit I-2 信号；纯资源自检。
## 目标路径：res://scripts/combat/combat_data_validator.gd

@export var boss_data: BossData = null
@export var enemy_data: Array[EnemyData] = []
@export var player_actions_table: PlayerActionTable = null
## E-8 抗性溢出公式里的「触发次数样本」（数据表schema.md §9 E-8 的 × 8），可配。
@export var resistance_sample_triggers: int = 8

## E-9 字段名白名单：R2 全部 schema 类声明过的字段名并集（去重）。
## 这些是字段名，不是战斗数值；用于核对资源导出属性名是否越界。
var _schema_fields: Array[String] = [
	# BossData
	"id", "display_name", "max_hp", "base_attack", "base_defense", "phases", "phase_thresholds",
	"poise", "status_buildups", "aggro_radius_px", "lose_radius_px", "chase_speed_px_per_sec",
	"attack_range_px", "ai_poll_interval_sec", "rng_seed", "defeated_flag_key", "death_pose_name",
	"phase_transition_enabled",
	# PhaseData
	"phase_index", "hp_ratio_enter", "hp_ratio_exit", "phase_damage_multiplier", "phase_defense",
	"sprite_frames_path", "pose_prefix", "moves", "poise_override", "status_resistance_multiplier",
	"transition_pose_name", "transition_frames", "transition_invulnerable", "aggression",
	# MoveData
	"pose_name", "startup_frames", "active_frames", "recovery_frames", "motion_multiplier",
	"damage_type", "poise_damage", "status_buildup_bleed", "status_buildup_poison",
	"status_buildup_frost", "hitbox_reach_px", "hitbox_arc_deg", "hitbox_offset_px",
	"min_range_px", "max_range_px", "weight", "cooldown_sec", "can_cancel_frames", "breaks_guard",
	# PoiseConfig
	"max_poise", "poise_regen_per_sec", "poise_regen_delay_sec", "stance_break_duration_sec",
	"stance_break_damage_multiplier", "executable", "execute_hp_ratio_threshold",
	"poise_break_pose_name", "poise_break_frame",
	# StatusBuildup
	"status_type", "threshold", "decay_per_sec", "decay_delay_sec", "trigger_damage_ratio",
	"trigger_damage_flat", "trigger_poise_damage", "trigger_pose_name", "trigger_frame",
	"duration_sec", "tick_damage_per_sec", "resistance_gain_per_trigger", "max_resistance",
	# PlayerActionData 新增（与上面复用同名字段不重复列）
	"action_name", "state_name", "pose_frame_offset", "invulnerable_start_frame",
	"invulnerable_end_frame", "logic_fps", "move_speed_px_per_sec", "state_priority",
	"can_cancel_into", "stamina_cost", "cancel_window_frames",
	# SpawnRequest（3 号《接口契约.md》§3 的 17 字段）
	"request_id", "enemy_id", "spawn_point_id", "position", "facing_degrees", "level",
	"hp_override", "stance_override", "aggro_radius", "leash_radius", "respawn_policy",
	"defeated_flag", "loot_table_id", "patrol_route", "is_boss", "spawn_group_id", "metadata",
	# PlayerActionTable
	"actions",
]

var _moves: Array[MoveData] = []
var _buildups: Array[StatusBuildup] = []
var _poises: Array[PoiseConfig] = []
var _actions: Array[PlayerActionData] = []
var _enemies: Array[EnemyData] = []
var _resources: Array[Resource] = []
var _boss_moves: Array[MoveData] = []
var _enemy_move_sets: Array = []          # 每项 Array[MoveData]
var _buildup_hosts: Array = []            # 每项 Array[StatusBuildup]
var _checks: int = 0
var _errors: int = 0


func _ready() -> void:
	_collect_all()
	_validate_e1()
	_validate_e3()
	_validate_e4()
	_validate_e5()
	_validate_e8()
	_validate_e9()
	print("[CombatDataValidator] E-1/E-3/E-4/E-5/E-8/E-9 检查项 %d，错误 %d" % [_checks, _errors])
	if _errors > 0:
		push_error("[CombatDataValidator] 数据表自洽校验失败，错误 %d 项" % _errors)


func _ok(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_errors += 1
		push_error("[CombatDataValidator] FAIL %s" % label)


# ---------------------------------------------------------------------------
# 收集挂载资源及其嵌套资源（供各 E 检查复用）
# ---------------------------------------------------------------------------

func _collect_all() -> void:
	if boss_data != null:
		_resources.append(boss_data)
		if boss_data.poise != null:
			_poises.append(boss_data.poise)
			_resources.append(boss_data.poise)
		_buildup_hosts.append(boss_data.status_buildups)
		for b in boss_data.status_buildups:
			_buildups.append(b)
			_resources.append(b)
		for p in boss_data.phases:
			_resources.append(p)
			if p.poise_override != null:
				_poises.append(p.poise_override)
				_resources.append(p.poise_override)
			for m in p.moves:
				_moves.append(m)
				_boss_moves.append(m)
				_resources.append(m)
	for e in enemy_data:
		_enemies.append(e)
		_resources.append(e)
		if e.poise != null:
			_poises.append(e.poise)
			_resources.append(e.poise)
		_buildup_hosts.append(e.status_buildups)
		for b in e.status_buildups:
			_buildups.append(b)
			_resources.append(b)
		var em: Array[MoveData] = []
		for m in e.moves:
			_moves.append(m)
			em.append(m)
			_resources.append(m)
		_enemy_move_sets.append(em)
	if player_actions_table != null:
		_resources.append(player_actions_table)
		for a in player_actions_table.actions:
			_actions.append(a)
			_resources.append(a)


# ---------------------------------------------------------------------------
# E-1：阶段阈值 / index / 上下阶段比例自洽
# ---------------------------------------------------------------------------

func _validate_e1() -> void:
	if boss_data == null:
		return
	var phases: Array[PhaseData] = boss_data.phases
	var thresholds: Array[float] = boss_data.phase_thresholds
	_ok(thresholds.size() == maxi(0, phases.size() - 1), "E-1 阈值表长度 = 阶段数 - 1")
	for i in range(phases.size()):
		var p: PhaseData = phases[i]
		_ok(p.phase_index == i + 1, "E-1 phase_index == 下标+1 -> %s" % p.id)
		if i < thresholds.size():
			_ok(is_equal_approx(thresholds[i], p.hp_ratio_exit), "E-1 threshold == hp_ratio_exit -> %s" % p.id)
		if i + 1 < phases.size():
			var nxt: PhaseData = phases[i + 1]
			_ok(is_equal_approx(p.hp_ratio_exit, nxt.hp_ratio_enter), "E-1 exit == 下一阶段 enter -> %s" % p.id)


# ---------------------------------------------------------------------------
# E-3：取消窗口不越出动作尾部
# ---------------------------------------------------------------------------

func _validate_e3() -> void:
	for m in _moves:
		_ok(m.can_cancel_frames <= m.recovery_frames, "E-3 can_cancel_frames <= recovery -> %s" % m.id)
	for a in _actions:
		_ok(a.cancel_window_frames <= a.recovery_frames, "E-3 cancel_window_frames <= recovery -> %s" % a.id)


# ---------------------------------------------------------------------------
# E-4：min <= max，且 attack_range <= max(moves.max_range)
# ---------------------------------------------------------------------------

func _validate_e4() -> void:
	for m in _moves:
		_ok(m.min_range_px <= m.max_range_px, "E-4 min <= max -> %s" % m.id)
	if boss_data != null and not _boss_moves.is_empty():
		_ok(boss_data.attack_range_px <= _max_move_range(_boss_moves), "E-4 Boss attack_range <= max(moves.max_range)")
	for i in range(_enemy_move_sets.size()):
		var set_moves: Array[MoveData] = _enemy_move_sets[i]
		if not set_moves.is_empty():
			var e: EnemyData = _enemies[i]
			_ok(e.attack_range_px <= _max_move_range(set_moves), "E-4 敌人 attack_range <= max(moves.max_range) -> %s" % e.id)


func _max_move_range(moves: Array[MoveData]) -> float:
	var result: float = 0.0
	for m in moves:
		if m.max_range_px > result:
			result = m.max_range_px
	return result


# ---------------------------------------------------------------------------
# E-5：lose_radius > aggro_radius（滞回）
# ---------------------------------------------------------------------------

func _validate_e5() -> void:
	if boss_data != null:
		_ok(boss_data.lose_radius_px > boss_data.aggro_radius_px, "E-5 Boss lose > aggro")
	for e in _enemies:
		_ok(e.lose_radius_px > e.aggro_radius_px, "E-5 敌人 lose > aggro -> %s" % e.id)


# ---------------------------------------------------------------------------
# E-8：异常类型不重复、抗性不溢出
# ---------------------------------------------------------------------------

func _validate_e8() -> void:
	for host in _buildup_hosts:
		var seen: Dictionary = {}
		for b in host:
			var buildup: StatusBuildup = b as StatusBuildup
			_ok(not seen.has(buildup.status_type), "E-8 status_type 不重复 -> %s" % buildup.status_type)
			seen[buildup.status_type] = true
			var limit: float = buildup.threshold + buildup.resistance_gain_per_trigger * float(resistance_sample_triggers)
			_ok(limit <= buildup.max_resistance, "E-8 抗性不溢出 -> %s" % buildup.id)


# ---------------------------------------------------------------------------
# E-9：资源导出字段名 ⊆ schema 字段集合（越界字段名数应为 0）
# ---------------------------------------------------------------------------

func _validate_e9() -> void:
	for res in _resources:
		for prop in res.get_property_list():
			var usage: int = int(prop.get("usage", 0))
			if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
				continue
			var field_name: String = String(prop.get("name", ""))
			if field_name == "script":
				continue
			_ok(_schema_fields.has(field_name), "E-9 字段名命中 schema -> %s" % field_name)
