extends RefCounted
class_name TrialModifierService

## ===========================================================================
## R31 / v0.9.0 · 试炼词条「结算纯逻辑」服务（RefCounted，Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261111-133549-883-A2）
## 目录所有权·R31：本文件归 Rank-2；既有 .tres / 导演层 / hud.gd / 场景 /
##   素材 / 其它 Rank 文件一律只读、不改。
##
## 【纯逻辑边界（任务单 ②）】
## - 不继承 Node、不碰场景树、不 add_child、不读写存档文件、不碰渲染、不落盘；
##   不调用 WorldState / SaveDeltaWriter / get_tree() / /root/... 绝对路径。
## - 唯一外部输入是构造时注入的 TrialModifierConfig（读表数值）与
##   select()/settle() 的入参；_selected 只是本实例内的选择态，不持久化。
## - 设计数值全部来自 res://data/rpg/trial_modifiers.tres，本文件不写死任何
##   [PLACEHOLDER] 数值（阈值随表变化，调参只改表不改代码）。
##
## 【规则（任务单 ② 逐条）】
## - select(id)：选择合法性（空 / 未知 id / 表内非法项 / 重复一律拒绝）、
##   互斥组拒绝（新词条与已选某词条同 exclusive_group -> 拒绝，需先 clear()）。
##   不同组可共存（如 tempo 的 time_pressure 可与 survival 的任一词条共存）。
## - clear()：清空选择态；未选词条 -> settle 回落到基础结算（base_points 原样返回）。
## - settle(base_points, stats) -> Dictionary：
##     * 异常输入拒绝：base_points < 0 / stats 非 Dictionary / config 缺失 /
##       表项非法 -> ok=false、不产出任何点数（total=0、balance=0、bonus=0）。
##     * 未选词条 -> REASON_NO_MODIFIER，total=base_points（基础结算）。
##     * 已选但条件未达成 -> REASON_CONDITION_NOT_MET，total=base_points
##       （回落基础，绝不惩罚、绝不扣减）。
##     * 已选且条件达成 -> 实际倍率取「达成词条中的最大 reward_multiplier」
##       （max，不叠乘，防奖励通胀），total=floor(base_points * 倍率)。
##     * 奖励单调不减：成功结算恒 total >= base_points（倍率 >= 1.0 且防御夹取）。
##     * 余额非负：成功结算恒 balance = total >= 0、bonus = total - base >= 0。
##
## 【条件语义（与 trial_modifier_config.gd 头注一致，由 id 分派）】
##   no_hit        : damage_taken <= 0
##   time_pressure : elapsed_sec <= time_limit_sec * time_limit_scale
##   low_vigor     : hp_ratio <= hp_scale
##   stats 缺字段 / 类型异常 -> 该词条「未达成」-> 回落基础，不崩、不惩罚。
##
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

const REASON_OK: String = "ok"
const REASON_INVALID_ID: String = "invalid_id"
const REASON_UNKNOWN_ID: String = "unknown_id"
const REASON_DUPLICATE: String = "duplicate"
const REASON_EXCLUSIVE: String = "exclusive_group"
const REASON_NO_CONFIG: String = "no_config"
const REASON_NO_MODIFIER: String = "no_modifier_baseline"
const REASON_CONDITION_NOT_MET: String = "condition_not_met_baseline"
const REASON_INVALID_POINTS: String = "invalid_points"
const REASON_INVALID_STATS: String = "invalid_stats"

## 已选词条 id（跨组共存；同组互斥由 select() 保证），不持久化。
var _selected: Array[String] = []
var _config: TrialModifierConfig = null


func _init(config: TrialModifierConfig = null) -> void:
	_config = config


## 允许构造后替换 / 注入表（含 null 用于「config 缺失」降级验证）。
func set_config(config: TrialModifierConfig) -> void:
	_config = config


func get_config() -> TrialModifierConfig:
	return _config


func get_selected_ids() -> Array[String]:
	return _selected.duplicate()


func has_selection() -> bool:
	return not _selected.is_empty()


## 清空选择态；此后 settle 回落基础结算。
func clear() -> void:
	_selected.clear()


## 选择一个词条：合法性 + 重复 + 互斥组拒绝；成功才写入 _selected。
func select(id: String) -> Dictionary:
	if id.is_empty():
		return _select_result(false, REASON_INVALID_ID, id)
	if _config == null:
		return _select_result(false, REASON_NO_CONFIG, id)
	if not TrialModifierConfig.is_id_known(id):
		return _select_result(false, REASON_UNKNOWN_ID, id)
	var m: TrialModifierConfig.TrialModifier = _config.find_modifier_by_id(id)
	if m == null or not _config.is_modifier_valid(m):
		return _select_result(false, REASON_UNKNOWN_ID, id)
	if _selected.has(id):
		return _select_result(false, REASON_DUPLICATE, id)
	# 互斥组：已选词条中存在与新词条同组者 -> 拒绝（需先 clear()）。
	for other_id: String in _selected:
		var om: TrialModifierConfig.TrialModifier = _config.find_modifier_by_id(other_id)
		if om != null and om.exclusive_group == m.exclusive_group:
			return _select_result(false, REASON_EXCLUSIVE, id)
	_selected.append(id)
	return _select_result(true, REASON_OK, id)


func _select_result(ok: bool, reason: String, id: String) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"id": id,
		"selected_ids": _selected.duplicate(),
	}


## 单个词条条件是否达成（纯函数）。stats 缺字段 / 类型异常一律 false。
static func _condition_met(m: TrialModifierConfig.TrialModifier, s: Dictionary) -> bool:
	var type_ok: bool = false
	match m.id:
		"no_hit":
			if not s.has("damage_taken"):
				return false
			var v: Variant = s.get("damage_taken")
			type_ok = typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT
			return type_ok and float(v) <= 0.0
		"time_pressure":
			if not s.has("elapsed_sec") or not s.has("time_limit_sec"):
				return false
			var e: Variant = s.get("elapsed_sec")
			var t: Variant = s.get("time_limit_sec")
			type_ok = (typeof(e) == TYPE_INT or typeof(e) == TYPE_FLOAT) \
				and (typeof(t) == TYPE_INT or typeof(t) == TYPE_FLOAT)
			return type_ok and float(e) <= float(t) * m.time_limit_scale
		"low_vigor":
			if not s.has("hp_ratio"):
				return false
			var h: Variant = s.get("hp_ratio")
			type_ok = typeof(h) == TYPE_INT or typeof(h) == TYPE_FLOAT
			return type_ok and float(h) <= m.hp_scale
	return false


## 结算：见头注「规则」。stats 用 Variant 以便对「非 Dictionary」异常输入显式拒绝。
func settle(base_points: int, stats: Variant) -> Dictionary:
	# ---- 异常输入拒绝（不产出任何点数、不改状态）----
	if base_points < 0:
		return _settle_result(false, REASON_INVALID_POINTS, base_points, 1.0, 0, false, "")
	if typeof(stats) != TYPE_DICTIONARY:
		return _settle_result(false, REASON_INVALID_STATS, base_points, 1.0, 0, false, "")
	if _config == null:
		return _settle_result(false, REASON_NO_CONFIG, base_points, 1.0, 0, false, "")
	var s: Dictionary = stats as Dictionary

	# ---- 未选词条：回落基础结算 ----
	if _selected.is_empty():
		return _settle_result(true, REASON_NO_MODIFIER, base_points, 1.0, base_points, false, "")

	# ---- 已选：逐条判定条件，生效倍率取「达成词条」的最大值（不叠乘，防通胀）----
	var best_mult: float = 1.0
	var best_id: String = ""
	var any_met: bool = false
	for id: String in _selected:
		var m: TrialModifierConfig.TrialModifier = _config.find_modifier_by_id(id)
		if m == null or not _config.is_modifier_valid(m):
			continue
		if _condition_met(m, s):
			any_met = true
			if m.reward_multiplier > best_mult:
				best_mult = m.reward_multiplier
				best_id = id

	# ---- 条件均未达成：回落基础，绝不惩罚 ----
	if not any_met:
		return _settle_result(true, REASON_CONDITION_NOT_MET, base_points, 1.0, base_points, false, "")

	# ---- 条件达成：floor(base * 倍率)，并做单调不减 / 非负防御夹取 ----
	var total: int = int(floor(float(base_points) * best_mult))
	if total < base_points:
		total = base_points
	if total < 0:
		total = 0
	return _settle_result(true, REASON_OK, base_points, best_mult, total, true, best_id)


func _settle_result(
	ok: bool,
	reason: String,
	base: int,
	mult: float,
	total: int,
	cond_met: bool,
	active_id: String) -> Dictionary:
	var bonus: int = 0
	var balance: int = 0
	if ok:
		bonus = maxi(0, total - base)
		balance = maxi(0, total)
	return {
		"ok": ok,
		"reason": reason,
		"base_points": base,
		"modifier_id": active_id,
		"condition_met": cond_met,
		"reward_multiplier": mult,
		"total_points": total,
		"bonus_points": bonus,
		"balance": balance,
		"selected_ids": _selected.duplicate(),
	}
