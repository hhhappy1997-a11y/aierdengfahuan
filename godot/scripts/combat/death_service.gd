extends RefCounted
class_name DeathService

## ===========================================================================
## R37 / v0.14.0「元素瓶与死亡轮回 · 画面补齐」· 死亡轮回纯逻辑服务
##                （RefCounted，Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-184157-082-A2）
## 目录所有权·R37 冻结：本文件归 Rank-2；encounter_director.gd / hud.gd /
##   presentation.gd（唯一写入方 Rank-1）/ points_commit_orchestrator.gd /
##   project.godot（Rank-3）/ courtyard.tscn / 既有 .tres / 其它 Rank 文件只读、不改。
##
## 【纯逻辑边界（任务单 ② / 契约 I-1）】
## - 不继承 Node、不碰场景树、不 add_child、不取 root、不调用 get_tree()、
##   不用 /root/... 绝对路径、不读写存档文件、不碰渲染、不落盘、不加载任何资源
##   （DeathConfig 规则表由构造注入）。
## - ★ 不回退 grace.trial.points、★ 绝不写 removals：本服务**根本不接触存档**，
##   只把死亡时的点数作为只读快照 `_grace_snapshot` 与派生值 `_dropped_points`
##   记在实例内，用 `_dropped` / `_reclaimed` 两个**独立单向 flag** 表达
##   「掉落已记录 / 掉落已回收」（沿用 A59 口径：独立 flag，不回退 points）。
## - 信号是 Object 级能力（RefCounted 继承 Object）：本服务用 4 个稳定 signal 把
##   「死亡发生 / 赐福重生 / 一次性回收 / 行动被拒」广播给 Rank-1（接线）与 Rank-4
##   （视觉反馈），但不依赖场景树、不 connect 任何全局节点；订阅方自行 connect 到本实例。
##   ★ A48①：wave_trial_director.gd（生产运行时节点）已生产订阅全部 4 信号（非验证脚本）。
##   ★ A54：唯一实例由 wave_trial_director.gd 装配，经 get_death_service() 复用，绝不另建。
## - 「赐福重生（回满 HP / FP / 瓶、重置连击与窗口）」由生产订阅者据
##   respawn_performed 信号执行各服务复位；本服务只广播、不持有 HP/FP/瓶实例。
## - 设计数值全部来自 res://data/rpg/death_rules.tres，本文件不写死任何
##   [PLACEHOLDER] 数值（口径随表变化，调参只改表不改代码）。
##
## 【公开信号（供 Rank-1 接线 / Rank-4 视觉反馈，签名稳定，见 DONE-R37.md）】
##   signal death_occurred(dropped_points: int, grace_points_snapshot: int)
##       —— on_death() 成功、进入死亡态并记录掉落时发；payload 只是记录值，
##          绝不回退 grace.trial.points、绝不写 removals；供 Rank-4 死亡演出 / HUD。
##   signal respawn_performed(pending_dropped_points: int)
##       —— on_grace_respawn() 成功、赐福重生复位时发；携带待回收掉落点数；
##          供生产订阅者复位 FP / 瓶 / 连击 / 窗口，供 Rank-4 重生演出。
##   signal points_reclaimed(points: int, grace_points_snapshot: int)
##       —— reclaim_dropped() 成功、一次性回收时发；points 供生产订阅者并入既有
##          清波点数结算基数（A55/A57 经 points_awarded 一次入账，不二次入账）。
##   signal action_rejected(reason: String, action_id: String)
##       —— 死亡期间行动 / 异常输入 / 重复死亡 / 重复回收被拒时发；reason 供 Rank-4 反馈。
##
## 【规则（任务单 ② 逐条）】
## - on_death(grace_points)：HP 归零 -> 死亡态 -> 记录掉落点数。
##   * config 缺失/非法 -> REASON_NO_CONFIG；异常点数 -> REASON_INVALID_INPUT；
##     死亡期间重复死亡 -> REASON_ALREADY_DEAD（不二次掉落）；
##     已有未回收掉落 -> REASON_DROP_PENDING（不二次掉落）；一律不改本轮掉落记录。
##   * 成功：dropped = floor(grace_points * drop_ratio)（受 drop_cap 封顶），
##     _is_dead=true / _dropped=true / _reclaimed=false，emit death_occurred。
##   * ★ 只是记录，**绝不回退 grace.trial.points、绝不写 removals**（A59）。
## - on_grace_respawn()：赐福重生。仅死亡态有效（否则 REASON_NOT_DEAD）；
##   置 _is_dead=false、保持掉落 pending（dropped=true / reclaimed=false）、
##   emit respawn_performed（携带待回收点数）。复位各服务由生产订阅者执行。
## - reclaim_dropped()：一次性回收。死亡期间拒绝（须先重生）、无掉落拒绝、
##   已回收拒绝（REASON_ALREADY_RECLAIMED，**回收只生效一次**）；
##   成功置 _reclaimed=true、emit points_reclaimed（供一次入账）。
##   回收后允许再次 on_death（新掉落周期），不二次回收旧掉落。
## - request_action(action_id) / can_act()：死亡期间拒绝行动（REASON_DEAD）+
##   异常 action_id 拒绝（REASON_INVALID_INPUT）；存活且合法才放行。
## - reset()：回到构造初始态（清死亡态 / 两个单向 flag / 掉落记录 / 计数）；
##   每场新一局调用。
## - get_snapshot()：全状态只读快照（供 HUD 鸭子类型 / 验证 / 接线）。
##
## 【对接说明（不在本服务落地）】
##   wave_trial_director.gd 生产订阅者：death_occurred 只做只读记录（不回退点数）；
##   respawn_performed 复位 FP / 瓶 / 连击 / 窗口；points_reclaimed 把点数累计到
##   _death_reclaim_acc，在 _clear_wave() 并入 base_for_combo -> combo.settle() ->
##   HUD points_awarded 一次入账（A57），并入后清零（不二次入账）。
##   ★ 本服务不读写存档（I-1）、不写 removals、不回退任何赐福点数、不碰渲染。
##
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- 公开信号（签名稳定，供 Rank-1 订阅 / Rank-4 视觉反馈）----
signal death_occurred(dropped_points: int, grace_points_snapshot: int)
signal respawn_performed(pending_dropped_points: int)
signal points_reclaimed(points: int, grace_points_snapshot: int)
signal action_rejected(reason: String, action_id: String)

## ---- 方法返回 reason（公开常量，签名稳定）----
const REASON_OK: String = "ok"
const REASON_NO_CONFIG: String = "no_config"
const REASON_INVALID_INPUT: String = "invalid_input"
const REASON_ALREADY_DEAD: String = "already_dead"
const REASON_DROP_PENDING: String = "drop_pending"
const REASON_NOT_DEAD: String = "not_dead"
const REASON_NO_DROP: String = "no_drop"
const REASON_ALREADY_RECLAIMED: String = "already_reclaimed"
const REASON_DEAD: String = "dead"

## 非 String 的 action_id 在 action_rejected payload 里的统一占位（可机器判定、不崩）。
const ACTION_ID_NONE: String = "<none>"

## 运行时状态（本实例内，不持久化）。
var _config: DeathConfig = null
var _is_dead: bool = false
var _dropped: bool = false        # 独立单向 flag：本轮掉落已记录
var _reclaimed: bool = false      # 独立单向 flag：本轮掉落已回收
var _dropped_points: int = 0
var _grace_snapshot: int = 0
var _death_count: int = 0
var _respawn_count: int = 0
var _reclaim_count: int = 0
var _reject_count: int = 0
var _last_result: Dictionary = {}
var _last_reject_reason: String = ""


func _init(config: DeathConfig = null) -> void:
	_config = config
	reset()


## 允许构造后替换 / 注入表（含 null 用于「config 缺失」降级验证）。
func set_config(config: DeathConfig) -> void:
	_config = config
	reset()


func get_config() -> DeathConfig:
	return _config


## 回到构造初始态：清死亡态 / 两个单向 flag / 掉落记录 / 计数 / 最近结果（每场新一局）。
func reset() -> void:
	_is_dead = false
	_dropped = false
	_reclaimed = false
	_dropped_points = 0
	_grace_snapshot = 0
	_death_count = 0
	_respawn_count = 0
	_reclaim_count = 0
	_reject_count = 0
	_last_result = {}
	_last_reject_reason = ""


## ---- 内部只读：表值 / 降级基线（代码不写死设计数值）----
func _config_ok() -> bool:
	return _config != null and _config.is_valid()


func _drop_ratio_value() -> float:
	return _config.get_drop_ratio() if _config_ok() else DeathConfig.DEFAULT_DROP_RATIO


func _drop_cap_value() -> int:
	return _config.get_drop_cap() if _config_ok() else DeathConfig.DEFAULT_DROP_CAP


func _invalid_input_policy_value() -> String:
	return _config.get_invalid_input_policy() if _config_ok() else DeathConfig.DEFAULT_INVALID_INPUT_POLICY


func _is_finite_number(v: Variant) -> bool:
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return false
	var f: float = float(v)
	return not (is_nan(f) or is_inf(f))


func _action_id_str(action_id: Variant) -> String:
	return String(action_id) if typeof(action_id) == TYPE_STRING else ACTION_ID_NONE


## ---- 只读查询（供 HUD / 断言 / 接线）----
func is_dead() -> bool:
	return _is_dead


func can_act() -> bool:
	return not _is_dead


func has_pending_drop() -> bool:
	return _dropped and not _reclaimed


func is_reclaimed() -> bool:
	return _reclaimed


func get_dropped_points() -> int:
	return _dropped_points


func get_grace_snapshot() -> int:
	return _grace_snapshot


func get_death_count() -> int:
	return _death_count


func get_respawn_count() -> int:
	return _respawn_count


func get_reclaim_count() -> int:
	return _reclaim_count


func get_reject_count() -> int:
	return _reject_count


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
		"is_dead": _is_dead,
		"dropped": _dropped,
		"reclaimed": _reclaimed,
		"dropped_points": _dropped_points,
		"grace_points_snapshot": _grace_snapshot,
		"drop_ratio": _drop_ratio_value(),
		"drop_cap": _drop_cap_value(),
		"invalid_input_policy": _invalid_input_policy_value(),
		"can_act": can_act(),
		"has_pending_drop": has_pending_drop(),
		"death_count": _death_count,
		"respawn_count": _respawn_count,
		"reclaim_count": _reclaim_count,
		"reject_count": _reject_count,
		"config_present": _config != null,
		"last_result": _last_result.duplicate(),
		"last_reject_reason": _last_reject_reason,
	}


## ---- 统一拒绝（发 action_rejected，供 Rank-4 失败反馈；不改死亡态 / 掉落记录）----
func _reject(reason: String, action_id: String) -> Dictionary:
	_reject_count += 1
	_last_reject_reason = reason
	action_rejected.emit(reason, action_id)
	return {
		"ok": false,
		"reason": reason,
		"action_id": action_id,
		"is_dead": _is_dead,
		"dropped": _dropped,
		"reclaimed": _reclaimed,
		"dropped_points": _dropped_points,
		"grace_points_snapshot": _grace_snapshot,
		"points": 0,
		"death_count": _death_count,
		"respawn_count": _respawn_count,
		"reclaim_count": _reclaim_count,
		"config_present": _config != null,
	}


## HP 归零 -> 死亡态 -> 记录掉落点数（只是记录，绝不回退 points / 绝不写 removals）。
func on_death(grace_points: Variant) -> Dictionary:
	if not _config_ok():
		return _reject(REASON_NO_CONFIG, ACTION_ID_NONE)
	if not _is_finite_number(grace_points):
		return _reject(REASON_INVALID_INPUT, ACTION_ID_NONE)
	var gp: float = float(grace_points)
	if gp < 0.0:
		return _reject(REASON_INVALID_INPUT, ACTION_ID_NONE)
	# 重复死亡不二次掉落
	if _is_dead:
		return _reject(REASON_ALREADY_DEAD, ACTION_ID_NONE)
	# 已有未回收掉落：不二次掉落
	if _dropped and not _reclaimed:
		return _reject(REASON_DROP_PENDING, ACTION_ID_NONE)
	# 成功：记录掉落点数（只读快照 + 派生值，不回退任何赐福点数）
	var snapshot: int = int(gp)
	var dropped: int = int(floorf(gp * _drop_ratio_value()))
	dropped = maxi(0, dropped)
	if _drop_cap_value() > 0:
		dropped = mini(dropped, _drop_cap_value())
	_is_dead = true
	_dropped = true
	_reclaimed = false
	_dropped_points = dropped
	_grace_snapshot = snapshot
	_death_count += 1
	death_occurred.emit(dropped, snapshot)
	var r: Dictionary = {
		"ok": true,
		"reason": REASON_OK,
		"dropped_points": dropped,
		"grace_points_snapshot": snapshot,
		"is_dead": _is_dead,
		"dropped": _dropped,
		"reclaimed": _reclaimed,
		"death_count": _death_count,
		"config_present": true,
	}
	_last_result = r.duplicate()
	return r


## 赐福重生：仅死亡态有效；置存活、保持掉落 pending，广播复位 + 待回收点数。
func on_grace_respawn() -> Dictionary:
	if not _is_dead:
		return _reject(REASON_NOT_DEAD, ACTION_ID_NONE)
	_is_dead = false
	_respawn_count += 1
	respawn_performed.emit(_dropped_points)
	var r: Dictionary = {
		"ok": true,
		"reason": REASON_OK,
		"is_dead": _is_dead,
		"dropped": _dropped,
		"reclaimed": _reclaimed,
		"pending_dropped_points": _dropped_points,
		"respawn_count": _respawn_count,
		"config_present": true,
	}
	_last_result = r.duplicate()
	return r


## 一次性回收掉落点数（供生产订阅者并入清波结算 -> points_awarded 一次入账）。
func reclaim_dropped() -> Dictionary:
	if _is_dead:
		return _reject(REASON_DEAD, ACTION_ID_NONE)
	if not _dropped:
		return _reject(REASON_NO_DROP, ACTION_ID_NONE)
	if _reclaimed:
		return _reject(REASON_ALREADY_RECLAIMED, ACTION_ID_NONE)
	_reclaimed = true
	_reclaim_count += 1
	var pts: int = _dropped_points
	points_reclaimed.emit(pts, _grace_snapshot)
	var r: Dictionary = {
		"ok": true,
		"reason": REASON_OK,
		"points": pts,
		"dropped_points": _dropped_points,
		"grace_points_snapshot": _grace_snapshot,
		"reclaimed": _reclaimed,
		"reclaim_count": _reclaim_count,
		"config_present": true,
	}
	_last_result = r.duplicate()
	return r


## 死亡期间拒绝行动 + 异常 action_id 拒绝；存活且合法才放行（纯逻辑门禁，不执行动作）。
func request_action(action_id: Variant) -> Dictionary:
	if _is_dead:
		return _reject(REASON_DEAD, _action_id_str(action_id))
	if typeof(action_id) != TYPE_STRING or String(action_id).is_empty():
		return _reject(REASON_INVALID_INPUT, _action_id_str(action_id))
	return {
		"ok": true,
		"reason": REASON_OK,
		"action_id": String(action_id),
		"is_dead": _is_dead,
		"config_present": _config != null,
	}
