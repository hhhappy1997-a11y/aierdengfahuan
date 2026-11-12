extends RefCounted
class_name FocusService

## ===========================================================================
## R36 / v0.13.0「专注值与战技 · 画面补齐」· 专注值 FP 与战技纯逻辑服务
##                （RefCounted，Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-154132-912-A2）
## 目录所有权·R36 冻结：本文件归 Rank-2；encounter_director.gd / hud.gd /
##   presentation.gd（唯一写入方 Rank-1）/ points_commit_orchestrator.gd /
##   project.godot（Rank-3）/ courtyard.tscn / 既有 .tres / 其它 Rank 文件只读、不改。
##
## 【纯逻辑边界（任务单 ① / 契约 I-1）】
## - 不继承 Node、不碰场景树、不 add_child、不取 root、不调用 get_tree()、
##   不用 /root/... 绝对路径、不读写存档文件、不碰渲染、不落盘、不加载任何资源
##   （FocusConfig 规则表由构造注入）。
## - 信号是 Object 级能力（RefCounted 继承 Object）：本服务用 4 个稳定 signal 把
##   「施放成功 / 施放被拒 / 赐福休息回复 / 冷却就绪」广播给 Rank-1（接线）与 Rank-4
##   （视觉反馈），但不依赖场景树、不 connect 任何全局节点；订阅方自行 connect 到本实例。
##   ★ A48①：wave_trial_director.gd（生产运行时节点）已生产订阅全部 4 信号（非验证脚本）。
##   ★ A54：唯一实例由 wave_trial_director.gd 装配，经 get_focus_service() 复用，绝不另建。
## - 时间不由真实引擎时钟驱动（不用 Time.get_ticks_*），由外部（导演层每帧）
##   调用 tick(delta_sec) 确定性推进冷却，保证纯逻辑、可测、同帧多次请求不叠加异常。
## - 设计数值全部来自 res://data/combat/focus_rules.tres，本文件不写死任何
##   [PLACEHOLDER] 数值（口径随表变化，调参只改表不改代码）。
##
## 【公开信号（供 Rank-1 接线 / Rank-4 视觉反馈，签名稳定，见 DONE-R36.md）】
##   signal focus_spent(art_id: String, fp_cost: float, damage: float,
##                      poise_damage: float, fp_remaining: float)
##       —— spend_fp(art_id) 成功时发；payload 即并入结算的两项效果 + 消耗 + 余额，
##          供 Rank-1 结算接线 / Rank-4 战技演出（辉石魔砾 / 狮子斩）。
##   signal focus_rejected(art_id: String, reason: String)
##       —— 施放被拒时发（no_config / invalid_art / insufficient_fp / cooldown）；
##          reason 供 Rank-4「FP 不足 / 冷却中」失败反馈。
##   signal focus_restored(fp_before: float, fp_after: float, policy: String)
##       —— on_grace_rest() 回复 FP 时发；policy ∈ {REST_REFILL="rest_refill",
##          REST_REGEN="rest_regen"}；供 Rank-4 赐福休息演出 / HUD 专注值条回满。
##   signal focus_cooldown_ready(art_id: String)
##       —— tick() 把某战技冷却从 >0 推到 0 时发（每次冷却结束恰 1 次）；
##          供 Rank-4 收起「冷却中」角标 / 战技图标点亮。
##
## 【规则（任务单 ① 逐条）】
## - spend_fp(art_id)：玩家施放战技。
##   * config 缺失/非法 -> REASON_NO_CONFIG；art_id 非 String/空/不存在 -> REASON_INVALID_ART
##     （覆盖异常 id / 负数 / null 拒绝）；冷却期 -> REASON_COOLDOWN（重复按键幂等）；
##     FP 不足 -> REASON_INSUFFICIENT_FP 且**不扣 FP**；一律不给效果、不改已成功状态。
##   * 成功：扣 fp_cost、置该 art 冷却、spend_count+1、emit focus_spent，
##     返回 damage / poise_damage 供生产订阅者并入既有结算（A57 不二次入账）。
## - tick(delta_sec)：确定性推进各战技冷却；某冷却归零 emit focus_cooldown_ready 一次。
##   异常：null / 非数值 / <0 / NaN / Inf -> REASON_INVALID_DELTA 拒绝、不改状态。
## - on_grace_rest()：赐福休息。rest_refill=true -> 回满 fp_max；false -> 按
##   fp_regen_on_rest 增量（封顶 fp_max）。清全部冷却、emit focus_restored。
##   ★ 这是本服务**唯一**允许 FP 增加的出口（守住「FP 只减不增除休息」）。
## - reset()：回到构造初始态（FP 回满、清冷却 / 计数 / 最近结果）；每场新一局调用。
##   ★ 每波开始**不调** reset()（导演层只清「本波累计」），专注值是跨波资源；
##     是否每波回满 FP 列为 DONE-R36 待裁决项。
## - get_snapshot()：全状态只读快照（供 HUD 鸭子类型 / 验证 / 接线）。
##
## 【对接说明（不在本服务落地）】
##   Rank-1 在战技键按下时调 spend_fp(art_id)、每帧调 tick(delta)、赐福休息调
##   on_grace_rest()、每场开始调 reset()，并订阅 4 个 signal 驱动 HUD 与 Rank-4 视觉反馈；
##   focus_spent 的 damage 由本轮 wave_trial_director.gd 生产订阅者并入既有清波点数结算
##   基数（经 combo.settle 得唯一最终值、points_awarded 发一次、不二次入账），
##   poise_damage 并入既有 StaggerService 削韧结算。本服务只判定与广播、不写存档、不碰渲染。
##
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- 公开信号（签名稳定，供 Rank-1 订阅 / Rank-4 视觉反馈）----
signal focus_spent(art_id: String, fp_cost: float, damage: float, poise_damage: float, fp_remaining: float)
signal focus_rejected(art_id: String, reason: String)
signal focus_restored(fp_before: float, fp_after: float, policy: String)
signal focus_cooldown_ready(art_id: String)

## ---- 方法返回 reason（公开常量，签名稳定）----
const REASON_OK: String = "ok"
const REASON_NO_CONFIG: String = "no_config"
const REASON_INVALID_ART: String = "invalid_art"
const REASON_INSUFFICIENT_FP: String = "insufficient_fp"
const REASON_COOLDOWN: String = "cooldown"
const REASON_INVALID_DELTA: String = "invalid_delta"

## ---- 赐福休息策略（focus_restored.policy 取值，公开常量）----
const REST_REFILL: String = "rest_refill"
const REST_REGEN: String = "rest_regen"

## 非 String 的 art_id 在 focus_rejected payload 里的统一占位（可机器判定、不崩）。
const ART_ID_NONE: String = "<none>"

## 运行时状态（本实例内，不持久化）。
var _config: FocusConfig = null
var _fp: float = 0.0
var _cooldowns: Dictionary = {}        # art_id -> 剩余冷却（秒）
var _spend_count: int = 0
var _reject_count: int = 0
var _restore_count: int = 0
var _last_result: Dictionary = {}
var _last_reject_reason: String = ""


func _init(config: FocusConfig = null) -> void:
	_config = config
	reset()


## 允许构造后替换 / 注入表（含 null 用于「config 缺失」降级验证）。
func set_config(config: FocusConfig) -> void:
	_config = config
	reset()


func get_config() -> FocusConfig:
	return _config


## 回到构造初始态：FP 回满、清冷却 / 计数 / 最近结果（每场新一局调用）。
func reset() -> void:
	_fp = _fp_max_value()
	_cooldowns.clear()
	_spend_count = 0
	_reject_count = 0
	_restore_count = 0
	_last_result = {}
	_last_reject_reason = ""


## ---- 内部只读：表值 / 降级基线（代码不写死设计数值）----
func _config_ok() -> bool:
	return _config != null and _config.is_valid()


func _fp_max_value() -> float:
	return _config.get_fp_max() if _config_ok() else FocusConfig.DEFAULT_FP_MAX


func _fp_regen_on_rest_value() -> float:
	return _config.get_fp_regen_on_rest() if _config_ok() else FocusConfig.DEFAULT_FP_REGEN_ON_REST


func _rest_refill_value() -> bool:
	return _config.get_rest_refill() if _config_ok() else FocusConfig.DEFAULT_REST_REFILL


func _invalid_input_policy_value() -> String:
	return _config.get_invalid_input_policy() if _config_ok() else FocusConfig.DEFAULT_INVALID_INPUT_POLICY


func _art_count_value() -> int:
	return _config.get_art_count() if _config_ok() else 0


func _art_ids_value() -> PackedStringArray:
	return _config.get_art_ids() if _config_ok() else PackedStringArray()


func _cooldown_for(id: String) -> float:
	if _cooldowns.has(id):
		return float(_cooldowns[id])
	return 0.0


## 按 id 查战技行（副本）；找不到返回空 Dictionary（异常 id 拒绝依据）。
func _find_art(id: String) -> Dictionary:
	if not _config_ok():
		return {}
	return _config.get_art_by_id(id)


## 非 String 的 art_id 统一归为占位串；String（含空串）原样返回供后续空串校验。
func _art_id_str(art_id: Variant) -> String:
	if typeof(art_id) == TYPE_STRING:
		return String(art_id)
	return ART_ID_NONE


## ---- 只读查询（供 HUD / 断言 / 接线）----
func get_fp() -> float:
	return _fp


func get_fp_remaining() -> float:
	return _fp


func get_fp_max() -> float:
	return _fp_max_value()


func get_cooldown_remaining(art_id: String) -> float:
	return _cooldown_for(art_id)


func get_spend_count() -> int:
	return _spend_count


func get_reject_count() -> int:
	return _reject_count


func get_restore_count() -> int:
	return _restore_count


func get_last_result() -> Dictionary:
	return _last_result.duplicate()


func get_last_reject_reason() -> String:
	return _last_reject_reason


func get_art_ids() -> PackedStringArray:
	return _art_ids_value()


func get_invalid_input_policy() -> String:
	return _invalid_input_policy_value()


func is_config_valid() -> bool:
	return _config_ok()


func get_snapshot() -> Dictionary:
	return {
		"fp": _fp,
		"fp_max": _fp_max_value(),
		"fp_remaining": _fp,
		"rest_refill": _rest_refill_value(),
		"fp_regen_on_rest": _fp_regen_on_rest_value(),
		"invalid_input_policy": _invalid_input_policy_value(),
		"art_count": _art_count_value(),
		"art_ids": _art_ids_value(),
		"cooldowns": _cooldowns.duplicate(),
		"spend_count": _spend_count,
		"reject_count": _reject_count,
		"restore_count": _restore_count,
		"config_present": _config != null,
		"last_result": _last_result.duplicate(),
		"last_reject_reason": _last_reject_reason,
	}


## ---- 统一拒绝（发 focus_rejected，供 Rank-4 失败反馈；不改 FP / 不给效果）----
func _reject(id: String, reason: String, cd_left: float = 0.0) -> Dictionary:
	_reject_count += 1
	_last_reject_reason = reason
	focus_rejected.emit(id, reason)
	return {
		"ok": false,
		"reason": reason,
		"art_id": id,
		"title": "",
		"fp_cost": 0.0,
		"damage": 0.0,
		"poise_damage": 0.0,
		"fp_remaining": _fp,
		"cooldown_remaining": cd_left,
		"spend_count": _spend_count,
		"config_present": _config != null,
	}


## 施放战技：FP 足够且不在冷却期 -> 成功扣 FP 并广播效果；其余一律拒绝且不扣。
func spend_fp(art_id: Variant) -> Dictionary:
	if not _config_ok():
		return _reject(_art_id_str(art_id), REASON_NO_CONFIG)
	var id: String = _art_id_str(art_id)
	if typeof(art_id) != TYPE_STRING or id.is_empty():
		return _reject(id, REASON_INVALID_ART)
	var art: Dictionary = _find_art(id)
	if art.is_empty():
		return _reject(id, REASON_INVALID_ART)
	var cd_left: float = _cooldown_for(id)
	if cd_left > 0.0:
		return _reject(id, REASON_COOLDOWN, cd_left)
	var cost: float = float(art["fp_cost"])
	if _fp < cost:
		return _reject(id, REASON_INSUFFICIENT_FP)
	var dmg: float = float(art["damage"])
	var pd: float = float(art["poise_damage"])
	var cd: float = float(art["cooldown_sec"])
	var title: String = str(art["title"])
	_fp = maxf(0.0, _fp - cost)
	_cooldowns[id] = cd
	_spend_count += 1
	focus_spent.emit(id, cost, dmg, pd, _fp)
	var r: Dictionary = {
		"ok": true,
		"reason": REASON_OK,
		"art_id": id,
		"title": title,
		"fp_cost": cost,
		"damage": dmg,
		"poise_damage": pd,
		"fp_remaining": _fp,
		"cooldown_remaining": cd,
		"spend_count": _spend_count,
		"config_present": true,
	}
	_last_result = r.duplicate()
	return r


## 确定性推进各战技冷却（由导演层每帧调用）；冷却归零时恰发一次 focus_cooldown_ready。
func tick(delta_sec: Variant) -> Dictionary:
	if typeof(delta_sec) != TYPE_INT and typeof(delta_sec) != TYPE_FLOAT:
		return _tick_result(false, REASON_INVALID_DELTA, 0.0, [])
	var d: float = float(delta_sec)
	if d < 0.0 or is_nan(d) or is_inf(d):
		return _tick_result(false, REASON_INVALID_DELTA, 0.0, [])
	var ready: Array = []
	for k: Variant in _cooldowns.keys():
		var cur: float = float(_cooldowns[k])
		if cur > 0.0:
			var nxt: float = maxf(0.0, cur - d)
			_cooldowns[k] = nxt
			if nxt <= 0.0:
				var id: String = str(k)
				ready.append(id)
				focus_cooldown_ready.emit(id)
	return _tick_result(true, REASON_OK, d, ready)


func _tick_result(ok: bool, reason: String, delta: float, ready: Array) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"delta_sec": delta,
		"ready_arts": ready.duplicate(),
		"fp": _fp,
		"cooldowns": _cooldowns.duplicate(),
	}


## 赐福休息：唯一允许 FP 增加的出口。rest_refill=true 回满、false 按增量（封顶 fp_max）。
func on_grace_rest() -> Dictionary:
	var before: float = _fp
	if not _config_ok():
		return _rest_result(false, REASON_NO_CONFIG, before, before, REST_REFILL)
	var policy: String = REST_REGEN
	var after: float = before
	if _rest_refill_value():
		policy = REST_REFILL
		after = _fp_max_value()
	else:
		after = minf(_fp_max_value(), before + _fp_regen_on_rest_value())
	_fp = maxf(0.0, after)
	_cooldowns.clear()   # 赐福休息重置全部战技冷却（不发 focus_cooldown_ready，避免与 tick 语义混淆）
	_restore_count += 1
	focus_restored.emit(before, _fp, policy)
	return _rest_result(true, REASON_OK, before, _fp, policy)


func _rest_result(ok: bool, reason: String, before: float, after: float,
		policy: String) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"fp_before": before,
		"fp_after": after,
		"fp_max": _fp_max_value(),
		"policy": policy,
		"restore_count": _restore_count,
		"config_present": _config != null,
	}
