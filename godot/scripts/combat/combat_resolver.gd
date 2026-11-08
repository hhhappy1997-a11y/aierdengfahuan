extends Node
class_name CombatResolver

## 2 号工位 · M1 战斗结算器（伤害 / 削韧 / 处决 / 异常积累）
##
## 核心验收「数据表改数值不改代码」：本文件是纯结算器，所有数值经参数由调用方从数据表
##   （PlayerActionData / MoveData / PhaseData / PoiseConfig / StatusBuildup / EnemyData / BossData）
##   字段取得。**零战斗数值硬编码**：唯一允许的常量是 MIN_DAMAGE（伤害下限）。
##   出现的 0.0 / 0.0 等仅为归零、衰减与计时边界，以及哨兵判定，非本案战斗数值；
##   无 1.0 乘数（P / S 的「无阶段 / 未崩坏」取值由调用方按数据源传入，不在此写死）。
## 伤害公式：damage = max(MIN_DAMAGE, A × M × P × S − D)
##   A = base_attack，M = motion_multiplier，P = phase_damage_multiplier，
##   S = stance_break_damage_multiplier，D = base_defense + phase_defense。
## 异常触发伤害不吃招式倍率与阶段倍率（避免乘法套娃）。
## I-2：本脚本不写任何 flag、不 emit I-2 信号；击杀由集成层接 target_defeated →
##   PlayerStateMachine.report_defeat() 唯一发射点处理。
## 目标路径：res://scripts/combat/combat_resolver.gd

## 本模块唯一允许的战斗数值常量：伤害结算下限（防止高防御出现 0 / 负伤害）。
const MIN_DAMAGE: float = 1.0

# ---- 模块内信号（1 号 / UI 可选订阅；均非 I-2） ----
signal damage_dealt(target_id: String, amount: float, damage_type: String)
signal poise_damage_dealt(target_id: String, amount: float)
signal status_buildup_applied(target_id: String, status_type: String, amount: float)
signal stance_broken(target_id: String)
signal status_triggered(target_id: String, status_type: String, damage: float, poise_damage: float, pose_name: String, frame: int)
signal execute_available(target_id: String)


# ---------------------------------------------------------------------------
# 伤害：A × M × P × S − D，下限 MIN_DAMAGE（5 入参全部来自数据表字段）
# ---------------------------------------------------------------------------

func compute_damage(
	attack_power: float,
	move_multiplier: float,
	phase_multiplier: float,
	stance_break_multiplier: float,
	defense: float
) -> float:
	var raw: float = attack_power * move_multiplier * phase_multiplier * stance_break_multiplier - defense
	return maxf(MIN_DAMAGE, raw)


# ---------------------------------------------------------------------------
# 削韧 / 韧性回复 / 姿态崩坏
# ---------------------------------------------------------------------------

## 受击削韧：current_poise -= poise_damage，下限 0.0（数值来自 MoveData / PlayerActionData.poise_damage）。
func compute_poise_after_hit(current_poise: float, poise_damage: float) -> float:
	return maxf(0.0, current_poise - poise_damage)


## 韧性回复：超过 poise_regen_delay_sec 后按 poise_regen_per_sec × dt 回复，上限 max_poise。
func regen_poise(current_poise: float, poise_config: PoiseConfig, dt: float, since_last_hit_sec: float) -> float:
	if since_last_hit_sec < poise_config.poise_regen_delay_sec:
		return current_poise
	return minf(poise_config.max_poise, current_poise + poise_config.poise_regen_per_sec * dt)


## 姿态崩坏：韧性 <= 0.0 时复位为 max_poise，并开启 stance_break_duration_sec 窗口。
## 返回 { poise, stance_broken, break_remaining_sec }。
func resolve_poise(
	current_poise: float,
	poise_damage: float,
	poise_config: PoiseConfig,
	break_remaining_sec: float
) -> Dictionary:
	var poise: float = compute_poise_after_hit(current_poise, poise_damage)
	var broken: bool = poise <= 0.0
	var remaining: float = break_remaining_sec
	if broken:
		poise = poise_config.max_poise
		remaining = poise_config.stance_break_duration_sec
	return {
		"poise": poise,
		"stance_broken": broken,
		"break_remaining_sec": remaining,
	}


## 处决触发（设计文档 §3.2 六条全部满足）：
## executable 且 韧性<=0 且 崩坏窗口>0 且 HP 比例<=阈值（阈值 0.0 恒真）
## 且 攻击者处于轻/重击判定帧内 且 距离<=hitbox_reach_px 且 register_hit 通过。
func can_execute(
	poise_config: PoiseConfig,
	current_poise: float,
	break_remaining_sec: float,
	target_hp_ratio: float,
	attacker_in_hit_window: bool,
	distance_px: float,
	hitbox_reach_px: float,
	hit_registered: bool
) -> bool:
	if not poise_config.executable:
		return false
	if current_poise > 0.0 or break_remaining_sec <= 0.0:
		return false
	if poise_config.execute_hp_ratio_threshold > 0.0 and target_hp_ratio > poise_config.execute_hp_ratio_threshold:
		return false
	if not attacker_in_hit_window:
		return false
	if distance_px > hitbox_reach_px:
		return false
	if not hit_registered:
		return false
	return true


# ---------------------------------------------------------------------------
# 异常状态积累（出血 / 中毒 / 冻伤，一条配置 = 一种异常）
# ---------------------------------------------------------------------------

## 实际阈值 = (threshold + 累计抗性) × PhaseData.status_resistance_multiplier
func compute_effective_status_threshold(
	buildup: StatusBuildup,
	accumulated_resistance: float,
	phase_resistance_multiplier: float
) -> float:
	return (buildup.threshold + accumulated_resistance) * phase_resistance_multiplier


## 异常触发伤害 = trigger_damage_ratio × max_hp + trigger_damage_flat，下限 MIN_DAMAGE，不吃 M / P。
func compute_status_trigger_damage(buildup: StatusBuildup, target_max_hp: float) -> float:
	return maxf(MIN_DAMAGE, target_max_hp * buildup.trigger_damage_ratio + buildup.trigger_damage_flat)


## 结算顺序：累加 → 衰减（超过 decay_delay_sec 后按 decay_per_sec 递减）→ 达阈值触发 → 归零。
## 返回 { buildup, triggered, trigger_damage, trigger_poise_damage, trigger_pose_name,
##         trigger_frame, accumulated_resistance, duration_sec, tick_damage_per_sec }。
func apply_status_buildup(
	target_id: String,
	status_type: String,
	current: float,
	amount: float,
	buildup: StatusBuildup,
	accumulated_resistance: float,
	phase_resistance_multiplier: float,
	target_max_hp: float,
	dt: float,
	since_last_sec: float
) -> Dictionary:
	var value: float = current + amount
	if since_last_sec >= buildup.decay_delay_sec:
		value = maxf(0.0, value - buildup.decay_per_sec * dt)
	status_buildup_applied.emit(target_id, status_type, amount)

	var result: Dictionary = {
		"buildup": value,
		"triggered": false,
		"trigger_damage": 0.0,
		"trigger_poise_damage": 0.0,
		"trigger_pose_name": buildup.trigger_pose_name,
		"trigger_frame": buildup.trigger_frame,
		"accumulated_resistance": accumulated_resistance,
		"duration_sec": buildup.duration_sec,
		"tick_damage_per_sec": buildup.tick_damage_per_sec,
	}

	var threshold: float = compute_effective_status_threshold(buildup, accumulated_resistance, phase_resistance_multiplier)
	if value >= threshold:
		var dmg: float = compute_status_trigger_damage(buildup, target_max_hp)
		var new_resistance: float = minf(buildup.max_resistance, accumulated_resistance + buildup.resistance_gain_per_trigger)
		result["buildup"] = 0.0
		result["triggered"] = true
		result["trigger_damage"] = dmg
		result["trigger_poise_damage"] = buildup.trigger_poise_damage
		result["accumulated_resistance"] = new_resistance
		status_triggered.emit(
			target_id,
			status_type,
			dmg,
			buildup.trigger_poise_damage,
			buildup.trigger_pose_name,
			buildup.trigger_frame
		)
	return result


# ---------------------------------------------------------------------------
# 综合命中结算：伤害 + 削韧一次算完并转发信号（异常由 apply_status_buildup 单独串接）
# ---------------------------------------------------------------------------

## 全部入参由调用方从数据表字段取得；返回 { damage, poise, stance_broken, break_remaining_sec }。
func resolve_hit(
	target_id: String,
	attack_power: float,
	move_multiplier: float,
	phase_multiplier: float,
	stance_break_multiplier: float,
	defense: float,
	damage_type: String,
	poise_damage: float,
	current_poise: float,
	poise_config: PoiseConfig,
	break_remaining_sec: float
) -> Dictionary:
	var damage: float = compute_damage(attack_power, move_multiplier, phase_multiplier, stance_break_multiplier, defense)
	var poise_result: Dictionary = resolve_poise(current_poise, poise_damage, poise_config, break_remaining_sec)
	damage_dealt.emit(target_id, damage, damage_type)
	poise_damage_dealt.emit(target_id, poise_damage)
	if poise_result["stance_broken"] as bool:
		stance_broken.emit(target_id)
	return {
		"damage": damage,
		"poise": poise_result["poise"],
		"stance_broken": poise_result["stance_broken"],
		"break_remaining_sec": poise_result["break_remaining_sec"],
	}
