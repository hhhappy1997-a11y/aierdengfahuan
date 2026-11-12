extends RefCounted
class_name FlaskService

## ===========================================================================
## R37 / v0.14.0「元素瓶与死亡轮回 · 画面补齐」· 元素瓶纯逻辑服务
##                （RefCounted，Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-184157-082-A2）
## 目录所有权·R37 冻结：本文件归 Rank-2；encounter_director.gd / hud.gd /
##   presentation.gd（唯一写入方 Rank-1）/ points_commit_orchestrator.gd /
##   project.godot（Rank-3）/ courtyard.tscn / 既有 .tres / 其它 Rank 文件只读、不改。
##
## 【纯逻辑边界（任务单 ① / 契约 I-1）】
## - 不继承 Node、不碰场景树、不 add_child、不取 root、不调用 get_tree()、
##   不用 /root/... 绝对路径、不读写存档文件、不碰渲染、不落盘、不加载任何资源
##   （FlaskConfig 规则表由构造注入）。
## - 信号是 Object 级能力（RefCounted 继承 Object）：本服务用 3 个稳定 signal 把
##   「使用成功 / 使用被拒 / 赐福休息补满」广播给 Rank-1（接线）与 Rank-4
##   （视觉反馈），但不依赖场景树、不 connect 任何全局节点；订阅方自行 connect 到本实例。
##   ★ A48①：wave_trial_director.gd（生产运行时节点）已生产订阅全部 3 信号（非验证脚本）。
##   ★ A54：唯一实例由 wave_trial_director.gd 装配，经 get_flask_service() 复用，绝不另建。
## - 本服务**不持有 HP**：current_hp / max_hp 由调用方传入，服务只返回回复后的 hp_after，
##   由外部（Rank-1 输入层 / HUD）作用到真实 HP 实例。纯逻辑、可测、不碰存档。
## - 设计数值全部来自 res://data/rpg/flask_rules.tres，本文件不写死任何
##   [PLACEHOLDER] 数值（口径随表变化，调参只改表不改代码）。
##
## 【公开信号（供 Rank-1 接线 / Rank-4 视觉反馈，签名稳定，见 DONE-R37.md）】
##   signal flask_used(flask_before: int, flask_after: int, hp_before: float,
##                     hp_after: float, healed: float)
##       —— use_flask() 成功时发；payload 供 Rank-4 元素瓶演出 / HUD 瓶数与血条补间。
##   signal flask_rejected(reason: String, flask_remaining: int)
##       —— 使用被拒时发（no_config / invalid_input / full_hp / no_flask / duplicate）；
##          reason 供 Rank-4「无瓶 / 满血 / 重复按键」失败反馈。
##   signal flask_restored(flask_before: int, flask_after: int, policy: String)
##       —— on_grace_rest() 补瓶时发；policy ∈ {REST_REFILL="rest_refill",
##          REST_KEEP="rest_keep"}；供 Rank-4 赐福休息演出 / HUD 瓶数回满。
##
## 【规则（任务单 ① 逐条）】
## - use_flask(current_hp, max_hp)：玩家使用元素瓶。
##   * config 缺失/非法 -> REASON_NO_CONFIG；异常输入 -> REASON_INVALID_INPUT；
##     满血 -> REASON_FULL_HP（拒绝且不扣瓶）；瓶尽 -> REASON_NO_FLASK（拒绝且不扣瓶）；
##     相邻同签名重复按键 -> REASON_DUPLICATE（幂等，拒绝且不扣瓶）；一律不回复、不改状态。
##   * 成功：healed = minf(heal_amount, max_hp - current_hp)、hp_after 封顶不超 max_hp、
##     瓶数 -1、use_count+1、emit flask_used，返回 payload 供生产订阅者计数。
## - 重复按键幂等：成功后记录本次输入签名 [current_hp, max_hp]；**紧邻的下一次**
##   同签名调用视为同一按键的重复派发 -> REASON_DUPLICATE 拒绝、不二次扣瓶 /
##   不二次回复；拒绝后清签名（只挡一次）。on_grace_rest() / reset() 清空签名。
##   ★ 语义边界（如实登记、列 DONE-R37 待裁决）：只防「相邻两次同签名调用」；
##     HP 被外部更新为不同值后可再次使用。是否改为「短冷却窗口」（需新增表字段 /
##     tick 转发）交总指挥裁决，不改既有方法清单。
## - 瓶数只减不增除休息：一局内 use_flask 瓶数单调不增、非负、不超 flask_max；
##   on_grace_rest() 是**唯一**允许瓶数增加的出口（守住不变量）。
## - on_grace_rest()：赐福休息。rest_refill=true -> 补满 flask_max；false -> 保持当前瓶数
##   （REST_KEEP）。清重复按键签名、emit flask_restored。
## - reset()：回到构造初始态（瓶回满、清计数 / 最近结果 / 签名）；每场新一局调用。
## - get_snapshot()：全状态只读快照（供 HUD 鸭子类型 / 验证 / 接线）。
##
## 【对接说明（不在本服务落地）】
##   Rank-1 在元素瓶键按下时调 use_flask(current_hp, max_hp) 并把 hp_after 作用到真实 HP、
##   赐福休息调 on_grace_rest()、每场开始调 reset()，并订阅 3 个 signal 驱动 HUD 与 Rank-4
##   视觉反馈；wave_trial_director.gd 生产订阅者只做只读计数（不改存档 / 不碰渲染）。
##   ★ 本服务不读写存档（I-1）、不写 removals、不回退任何赐福点数、不碰渲染。
##
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- 公开信号（签名稳定，供 Rank-1 订阅 / Rank-4 视觉反馈）----
signal flask_used(flask_before: int, flask_after: int, hp_before: float, hp_after: float, healed: float)
signal flask_rejected(reason: String, flask_remaining: int)
signal flask_restored(flask_before: int, flask_after: int, policy: String)

## ---- 方法返回 reason（公开常量，签名稳定）----
const REASON_OK: String = "ok"
const REASON_NO_CONFIG: String = "no_config"
const REASON_INVALID_INPUT: String = "invalid_input"
const REASON_FULL_HP: String = "full_hp"
const REASON_NO_FLASK: String = "no_flask"
const REASON_DUPLICATE: String = "duplicate"

## ---- 赐福休息策略（flask_restored.policy 取值，公开常量）----
const REST_REFILL: String = "rest_refill"
const REST_KEEP: String = "rest_keep"

## 运行时状态（本实例内，不持久化）。
var _config: FlaskConfig = null
var _flasks: int = 0
var _use_count: int = 0
var _reject_count: int = 0
var _restore_count: int = 0
var _last_result: Dictionary = {}
var _last_reject_reason: String = ""
var _duplicate_sig: Array = []       # 重复按键幂等签名 [current_hp, max_hp]


func _init(config: FlaskConfig = null) -> void:
	_config = config
	reset()


## 允许构造后替换 / 注入表（含 null 用于「config 缺失」降级验证）。
func set_config(config: FlaskConfig) -> void:
	_config = config
	reset()


func get_config() -> FlaskConfig:
	return _config


## 回到构造初始态：瓶回满、清计数 / 最近结果 / 重复按键签名（每场新一局调用）。
func reset() -> void:
	_flasks = _flask_max_value()
	_use_count = 0
	_reject_count = 0
	_restore_count = 0
	_last_result = {}
	_last_reject_reason = ""
	_duplicate_sig = []


## ---- 内部只读：表值 / 降级基线（代码不写死设计数值）----
func _config_ok() -> bool:
	return _config != null and _config.is_valid()


func _flask_max_value() -> int:
	return _config.get_flask_max() if _config_ok() else FlaskConfig.DEFAULT_FLASK_MAX


func _heal_amount_value() -> float:
	return _config.get_heal_amount() if _config_ok() else FlaskConfig.DEFAULT_HEAL_AMOUNT


func _rest_refill_value() -> bool:
	return _config.get_rest_refill() if _config_ok() else FlaskConfig.DEFAULT_REST_REFILL


func _invalid_input_policy_value() -> String:
	return _config.get_invalid_input_policy() if _config_ok() else FlaskConfig.DEFAULT_INVALID_INPUT_POLICY


func _is_finite_number(v: Variant) -> bool:
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return false
	var f: float = float(v)
	return not (is_nan(f) or is_inf(f))


## ---- 只读查询（供 HUD / 断言 / 接线）----
func get_flasks() -> int:
	return _flasks


func get_flask_remaining() -> int:
	return _flasks


func get_flask_max() -> int:
	return _flask_max_value()


func get_use_count() -> int:
	return _use_count


func get_reject_count() -> int:
	return _reject_count


func get_restore_count() -> int:
	return _restore_count


func get_last_result() -> Dictionary:
	return _last_result.duplicate()


func get_last_reject_reason() -> String:
	return _last_reject_reason


func get_invalid_input_policy() -> String:
	return _invalid_input_policy_value()


func is_config_valid() -> bool:
	return _config_ok()


func get_snapshot() -> Dictionary:
	return {
		"flasks": _flasks,
		"flask_max": _flask_max_value(),
		"flask_remaining": _flasks,
		"heal_amount": _heal_amount_value(),
		"rest_refill": _rest_refill_value(),
		"invalid_input_policy": _invalid_input_policy_value(),
		"use_count": _use_count,
		"reject_count": _reject_count,
		"restore_count": _restore_count,
		"config_present": _config != null,
		"last_result": _last_result.duplicate(),
		"last_reject_reason": _last_reject_reason,
	}


## ---- 统一拒绝（发 flask_rejected，供 Rank-4 失败反馈；不改瓶数 / 不回复 HP）----
func _reject(reason: String) -> Dictionary:
	_reject_count += 1
	_last_reject_reason = reason
	flask_rejected.emit(reason, _flasks)
	return {
		"ok": false,
		"reason": reason,
		"flask_before": _flasks,
		"flask_after": _flasks,
		"hp_before": 0.0,
		"hp_after": 0.0,
		"healed": 0.0,
		"use_count": _use_count,
		"config_present": _config != null,
	}


## 使用元素瓶：config / 输入 / 满血 / 瓶尽 / 重复按键五道门；成功才扣 1 瓶并回血。
func use_flask(current_hp: Variant, max_hp: Variant) -> Dictionary:
	if not _config_ok():
		return _reject(REASON_NO_CONFIG)
	# 异常输入拒绝（null / 非数值 / NaN / Inf / 负 HP / max_hp<=0 / current_hp>max_hp）
	if not _is_finite_number(current_hp) or not _is_finite_number(max_hp):
		return _reject(REASON_INVALID_INPUT)
	var hp: float = float(current_hp)
	var mx: float = float(max_hp)
	if hp < 0.0 or mx <= 0.0 or hp > mx:
		return _reject(REASON_INVALID_INPUT)
	# 满血拒绝不扣
	if hp >= mx:
		return _reject(REASON_FULL_HP)
	# 瓶尽拒绝不扣
	if _flasks <= 0:
		return _reject(REASON_NO_FLASK)
	# 重复按键幂等：相邻同签名调用只挡一次，不二次扣瓶 / 不二次回复
	var sig: Array = [hp, mx]
	if not _duplicate_sig.is_empty() and _duplicate_sig == sig:
		_duplicate_sig = []
		return _reject(REASON_DUPLICATE)
	_duplicate_sig = []
	# 成功：回复量封顶（HP 不超过上限）、瓶只减 1
	var healed: float = minf(_heal_amount_value(), mx - hp)
	var hp_after: float = minf(mx, hp + _heal_amount_value())
	var before: int = _flasks
	_flasks = maxi(0, _flasks - 1)
	_use_count += 1
	_duplicate_sig = sig
	flask_used.emit(before, _flasks, hp, hp_after, healed)
	var r: Dictionary = {
		"ok": true,
		"reason": REASON_OK,
		"flask_before": before,
		"flask_after": _flasks,
		"hp_before": hp,
		"hp_after": hp_after,
		"healed": healed,
		"use_count": _use_count,
		"config_present": true,
	}
	_last_result = r.duplicate()
	return r


## 赐福休息：唯一允许瓶数增加的出口。rest_refill=true 补满、false 保持当前瓶数。
func on_grace_rest() -> Dictionary:
	var before: int = _flasks
	if not _config_ok():
		return _rest_result(false, REASON_NO_CONFIG, before, before, REST_REFILL)
	var policy: String = REST_KEEP
	var after: int = before
	if _rest_refill_value():
		policy = REST_REFILL
		after = _flask_max_value()
	_flasks = maxi(0, after)
	_duplicate_sig = []
	_restore_count += 1
	flask_restored.emit(before, _flasks, policy)
	return _rest_result(true, REASON_OK, before, _flasks, policy)


func _rest_result(ok: bool, reason: String, before: int, after: int,
		policy: String) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"flask_before": before,
		"flask_after": after,
		"flask_max": _flask_max_value(),
		"policy": policy,
		"restore_count": _restore_count,
		"config_present": _config != null,
	}
