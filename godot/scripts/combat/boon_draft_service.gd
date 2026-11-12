extends RefCounted
class_name BoonDraftService

## ===========================================================================
## R32 / v0.10.0 · 战后赐福抉择 Boon Draft「结算纯逻辑」服务（RefCounted，Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-074023-393-A2）
## 目录所有权·R32 冻结：本文件归 Rank-2；encounter_director.gd（唯一写入方 Rank-1）/
##   hud.gd / impact_feedback.gd / 场景 / 素材 / 既有 .tres / 其它 Rank 文件只读、不改。
##
## 【纯逻辑边界（任务单 ① / 契约 I-1）】
## - 不继承 Node、不碰场景树、不 add_child、不取 root、不调用 get_tree()、
##   不用 /root/... 绝对路径、不读写存档文件（不 open user://、不 load 生产 delta.json）、
##   不碰渲染、不落盘、不加载任何资源（表由构造注入）。
## - 唯一外部输入是构造时注入的 BoonDraftConfig（读表数值）与
##   select()/apply()/settle() 的入参；_selected_index / _applied / _settled 只是
##   本实例内的抉择态，不持久化、不写任何 flag。
## - 设计数值全部来自 res://data/rpg/boon_draft.tres，本文件不写死任何
##   [PLACEHOLDER] 数值（口径随表变化，调参只改表不改代码）。
##
## 【规则（任务单 ① 逐条）】
## - 每波清波后「三选一」：select(index) 只允许成功一次；再次 select 一律拒绝。
##   * 合法性：index 非 int / null / 越界 / 表项非法 -> 拒绝（不崩）。
##   * 互斥：第二次请求若与已选项同 exclusive_group -> REASON_EXCLUSIVE 拒绝。
##   * 重复选择：第二次请求同一 index -> REASON_DUPLICATE 拒绝；
##     不同组但已抉择 -> 仍按 REASON_DUPLICATE 拒绝（三选一，不许多选）。
##   * 拒绝操作绝不改写选择态（幂等）。
## - apply()：把选中候选的「增益 + 代价」成对生效，成对性由表结构保证
##   （effect_key/effect_value 与 cost_key/cost_value 同时为正、同时存在），
##   缺一即 REASON_INVALID_BOON 拒绝；重复 apply -> REASON_ALREADY_APPLIED。
## - settle(base_points)：点数结算 + 余额非负。
##   * 异常输入拒绝：null / 非数值 / 负点数 / config 缺失 -> ok=false、
##     不产出任何点数（total=0、balance=0、bonus=0）、不改状态。
##   * 未选回落：REASON_NO_SELECTION，total=base_points（基础结算，不惩罚）。
##   * 点数加成：仅 effect_key=="points_bonus" 的候选把 effect_value 计入 bonus；
##     其余两项（生命回复 / 削韧强化）不加点数，total=base_points。
##   * 余额非负：成功结算恒 balance = max(0, total) >= 0、bonus >= 0；
##     重复 settle -> REASON_ALREADY_SETTLED（防同帧多次请求重复给点 / 防通胀）。
## - reset()：清空一次 draft 的抉择/应用/结算态，供导演层每波清波后重新三选一。
##
## 【玩法闭环 / 代价去向（对接说明，不在本服务落地）】
##   apply() 返回的 cost_key / cost_value 是「下一波」乘性修正（hp_scale /
##   telegraph_scale），由导演层在下一波生成敌人时消费；effect_key="hp_restore" /
##   "poise_damage_bonus" 的运行时效果由各自消费方接线。本服务只产出成对数据、
##   不写存档、不碰渲染、不改下一波实例。
##
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

const REASON_OK: String = "ok"
const REASON_NO_CONFIG: String = "no_config"
const REASON_INVALID_INDEX: String = "invalid_index"
const REASON_INVALID_BOON: String = "invalid_boon"
const REASON_DUPLICATE: String = "duplicate"
const REASON_EXCLUSIVE: String = "exclusive_group"
const REASON_NO_SELECTION: String = "no_selection_baseline"
const REASON_ALREADY_APPLIED: String = "already_applied"
const REASON_ALREADY_SETTLED: String = "already_settled"
const REASON_INVALID_POINTS: String = "invalid_points"

## 一次 draft 的抉择态（本实例内，不持久化）。
var _selected_index: int = -1
var _applied: bool = false
var _settled: bool = false
var _config: BoonDraftConfig = null


func _init(config: BoonDraftConfig = null) -> void:
	_config = config


## 允许构造后替换 / 注入表（含 null 用于「config 缺失」降级验证）。
func set_config(config: BoonDraftConfig) -> void:
	_config = config


func get_config() -> BoonDraftConfig:
	return _config


func get_selected_index() -> int:
	return _selected_index


func has_selection() -> bool:
	return _selected_index >= 0


func is_applied() -> bool:
	return _applied


func is_settled() -> bool:
	return _settled


## 清空一次 draft 的抉择态，供每波清波后重新三选一（导演层调用）。
func reset() -> void:
	_selected_index = -1
	_applied = false
	_settled = false


func get_snapshot() -> Dictionary:
	return {
		"selected_index": _selected_index,
		"has_selection": has_selection(),
		"applied": _applied,
		"settled": _settled,
		"config_present": _config != null,
	}


## 选择一个候选：合法性 + 互斥 + 重复拒绝；成功才写入 _selected_index。
## index 用 Variant 以便对 null / 字符串 / 浮点等异常输入显式拒绝（不崩）。
func select(index: Variant) -> Dictionary:
	if _config == null:
		return _select_result(false, REASON_NO_CONFIG, -1)
	if typeof(index) != TYPE_INT:
		return _select_result(false, REASON_INVALID_INDEX, -1)
	var idx: int = int(index)
	if idx < 0 or idx >= _config.boon_count():
		return _select_result(false, REASON_INVALID_INDEX, idx)
	var b: BoonDraftConfig.Boon = _config.get_boon(idx)
	if b == null or not _config.is_boon_valid(b):
		return _select_result(false, REASON_INVALID_BOON, idx)
	# 三选一：已抉择后再次请求一律拒绝，细分 reason 便于机器判定。
	if _selected_index >= 0:
		if idx == _selected_index:
			return _select_result(false, REASON_DUPLICATE, idx)
		var chosen: BoonDraftConfig.Boon = _config.get_boon(_selected_index)
		if chosen != null and chosen.exclusive_group == b.exclusive_group:
			return _select_result(false, REASON_EXCLUSIVE, idx)
		return _select_result(false, REASON_DUPLICATE, idx)
	_selected_index = idx
	return _select_result(true, REASON_OK, idx)


func _select_result(ok: bool, reason: String, index: int) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"index": index,
		"selected_index": _selected_index,
	}


## 把选中候选的「增益 + 代价」成对生效（纯产出数据，不写存档、不碰下一波实例）。
func apply() -> Dictionary:
	if _config == null:
		return _apply_result(false, REASON_NO_CONFIG, "")
	if _applied:
		return _apply_result(false, REASON_ALREADY_APPLIED, "")
	if _selected_index < 0:
		return _apply_result(false, REASON_NO_SELECTION, "")
	var b: BoonDraftConfig.Boon = _config.get_boon(_selected_index)
	if b == null or not _config.is_boon_valid(b):
		return _apply_result(false, REASON_INVALID_BOON, "")
	# 成对性防御：增益与代价必须同时存在且均为正（is_boon_valid 已保证，二次断言
	# 明确「绝不出现只有增益没有代价」）。
	var paired: bool = b.effect_value > 0.0 and b.cost_value > 0.0 \
		and not b.effect_key.is_empty() and not b.cost_key.is_empty()
	if not paired:
		return _apply_result(false, REASON_INVALID_BOON, "")
	_applied = true
	return {
		"ok": true,
		"reason": REASON_OK,
		"id": b.id,
		"effect_key": b.effect_key,
		"effect_value": b.effect_value,
		"cost_key": b.cost_key,
		"cost_value": b.cost_value,
		"exclusive_group": b.exclusive_group,
		"paired": true,
		"selected_index": _selected_index,
	}


func _apply_result(ok: bool, reason: String, id: String) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"id": id,
		"effect_key": "",
		"effect_value": 0.0,
		"cost_key": "",
		"cost_value": 0.0,
		"exclusive_group": "",
		"paired": false,
		"selected_index": _selected_index,
	}


## 点数结算：见头注「规则」。base_points 用 Variant 以便对 null / 非数值显式拒绝。
func settle(base_points: Variant) -> Dictionary:
	# ---- 异常输入拒绝（不产出任何点数、不改状态）----
	if typeof(base_points) != TYPE_INT and typeof(base_points) != TYPE_FLOAT:
		return _settle_result(false, REASON_INVALID_POINTS, 0, 0, 0, 0, "", "", 0.0, false)
	var base_raw: float = float(base_points)
	if base_raw < 0.0 or is_nan(base_raw) or is_inf(base_raw):
		return _settle_result(false, REASON_INVALID_POINTS, 0, 0, 0, 0, "", "", 0.0, false)
	var base: int = int(base_raw)
	if _config == null:
		return _settle_result(false, REASON_NO_CONFIG, base, 0, 0, 0, "", "", 0.0, false)
	if _settled:
		return _settle_result(false, REASON_ALREADY_SETTLED, base, 0, 0, 0, "", "", 0.0, false)

	# ---- 未选回落：基础结算，不惩罚、不加点数 ----
	if _selected_index < 0:
		_settled = true
		return _settle_result(true, REASON_NO_SELECTION, base, base, 0, maxi(0, base), "", "", 0.0, false)

	var b: BoonDraftConfig.Boon = _config.get_boon(_selected_index)
	if b == null or not _config.is_boon_valid(b):
		return _settle_result(false, REASON_INVALID_BOON, base, 0, 0, 0, "", "", 0.0, false)

	# ---- 点数加成：仅 points_bonus 候选把 effect_value 计入 bonus ----
	var bonus: int = 0
	if b.effect_key == "points_bonus":
		bonus = maxi(0, int(roundf(b.effect_value)))
	var total: int = base + bonus
	if total < 0:
		total = 0  # 防御夹取：余额非负不变量（base>=0 且 bonus>=0，正常不触发）
	_settled = true
	return _settle_result(true, REASON_OK, base, total, bonus, maxi(0, total),
		b.effect_key, b.cost_key, b.cost_value, true)


func _settle_result(
	ok: bool,
	reason: String,
	base: int,
	total: int,
	bonus: int,
	balance: int,
	effect_key: String,
	cost_key: String,
	cost_value: float,
	paired: bool) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"base_points": base,
		"total_points": total,
		"bonus_points": bonus,
		"balance": balance,
		"effect_key": effect_key,
		"cost_key": cost_key,
		"cost_value": cost_value,
		"paired": paired,
		"selected_index": _selected_index,
	}
