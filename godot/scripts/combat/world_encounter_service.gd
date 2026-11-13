extends RefCounted
class_name WorldEncounterService

## ===========================================================================
## R38 / v0.15.0「大地图 · 2.5D 尺度重构」· 野外遭遇纯逻辑服务
##                （RefCounted，Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-234238-650-A2）
## 目录所有权·R38 冻结：本文件归 Rank-2；courtyard.tscn / hud.gd / presentation.gd
##   （Rank-1）/ points_commit_orchestrator.gd / project.godot（Rank-3）/ 既有 .tres
##   数值 / 场景 / 素材 / 其它 Rank 文件只读、不改。
##
## 【纯逻辑边界（任务单 ① / 契约 I-1）】
## - 不继承 Node、不碰场景树、不 add_child、不取 root、不调用 get_tree()、
##   不用 /root/... 绝对路径、不读写存档文件、不碰渲染、不落盘、不加载任何资源
##   （WorldEncounterConfig 规则表由构造注入，不是本服务 load 的）。
## - ★ 运行时清除态只记在实例内的 `_cleared` 字典，★ 绝不写回 .tres、绝不读写存档
##   （I-1）；clear 进度 `_cleared_count` 单调递增（除显式 reset）。
## - 信号是 Object 级能力（RefCounted 继承 Object）：本服务用 4 个稳定 signal 把
##   「进入区域 / 遭遇触发 / 遭遇清除 / 触发被拒」广播给 Rank-1（接线）、Rank-3
##   （落盘口径）与 Rank-4（视觉反馈），但不依赖场景树、不 connect 任何全局节点；
##   订阅方自行 connect 到本实例。
##   ★ A48①：wave_trial_director.gd（生产运行时节点）已生产订阅全部 4 信号（非验证脚本）。
##   ★ A54：唯一实例由 wave_trial_director.gd 装配，经 get_world_encounter_service() 复用。
## - 设计数值全部来自 res://data/rpg/world_encounters.tres，本文件不写死任何
##   [PLACEHOLDER] 数值（口径随表变化，调参只改表不改代码）。
##
## 【公开信号（供 Rank-1 接线 / Rank-3 落盘 / Rank-4 视觉反馈，签名稳定，见 DONE-R38.md）】
##   signal region_entered(region_id: String)
##       —— enter_region() 成功时发；payload 为进入的分区 id。
##   signal encounter_triggered(encounter_id: String, region_id: String, reward_points: int)
##       —— try_trigger() 成功、进入距离半径且未清除时发；reward_points 供生产订阅者
##          并入既有清波点数结算基数（A55/A57 经 points_awarded 一次入账，不二次入账）。
##   signal encounter_cleared(encounter_id: String, region_id: String, cleared_count: int)
##       —— on_encounter_cleared() 成功、标记区域已清除时发；cleared_count 单调递增，
##          供 Rank-3 落盘「区域已清除 / 地图进度」三段式 flag 口径。
##   signal trigger_rejected(reason: String, encounter_id: String)
##       —— 异常输入 / 未进入区域 / 距离外 / 已清除 / 重复触发 / 无活跃遭遇被拒时发；
##          reason 供 Rank-4 反馈 / Rank-3 决定是否落盘（建议拒绝事件不写盘）。
##
## 【规则（任务单 ① 逐条）】
## - enter_region(region_id)：设置当前分区；config 缺失/非法 -> no_config；
##   非 String / 空 -> invalid_input；未在 region_ids 注册 -> no_region；成功发 region_entered。
## - try_trigger(position)：进入触发 + 距离判定 + 已清除不重复 + 重复触发幂等 + 异常拒绝。
##   * config/输入异常 -> no_config / invalid_input（null / 非 Vector2 / NaN / Inf）；
##     未 enter_region -> no_region；已有 active（未清除）遭遇 -> duplicate（幂等，不二次发信号）；
##     当前区域全部遭遇已清除 -> already_cleared（已清除区域不重复触发）；
##     半径内无未清除遭遇 -> no_encounter。
##   * 成功：在当前区域未清除遭遇中取 distance_to <= trigger_radius 的**最近**一个，
##     置 active、发 encounter_triggered（携带表内 reward_points）。
##   * 距离判定一律用 Vector2.distance_to（2.5D 俯视平面），不碰渲染、不读相机。
## - on_encounter_cleared(encounter_id)：只能清除当前 active 遭遇；
##   异常 id / 无 active / id 不匹配 -> invalid_input / no_active；
##   成功置 cleared、_cleared_count += 1（单调递增）、清 active、发 encounter_cleared。
##   重复清除幂等：active 清空后再调 -> no_active，不二次增加进度。
## - reset()：回到构造初始态（当前分区 / active / 清除态按表 cleared_flag 初始化 /
##   计数 / 最近结果）；每场新一局调用。
## - get_snapshot()：全状态只读快照（供 HUD 鸭子类型 / 验证 / 接线）。
##
## 【对接说明（不在本服务落地）】
##   wave_trial_director.gd 生产订阅者：encounter_triggered 把 reward_points 累计到
##   _world_reward_acc，在 _clear_wave() 并入 base_for_combo -> combo.settle() ->
##   HUD points_awarded 一次入账（A55/A57），并入后清零（不二次入账）；清波后由导演层
##   调 on_encounter_cleared(active_id) 标记区域已清除（encounter_cleared 供 Rank-3 落盘）。
##   ★ 本服务不读写存档（I-1）、不写 .tres、不回退任何赐福点数、不碰渲染。
##
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- 公开信号（签名稳定，供 Rank-1 订阅 / Rank-3 落盘 / Rank-4 视觉反馈）----
signal region_entered(region_id: String)
signal encounter_triggered(encounter_id: String, region_id: String, reward_points: int)
signal encounter_cleared(encounter_id: String, region_id: String, cleared_count: int)
signal trigger_rejected(reason: String, encounter_id: String)

## ---- 方法返回 reason（公开常量，签名稳定）----
const REASON_OK: String = "ok"
const REASON_NO_CONFIG: String = "no_config"
const REASON_INVALID_INPUT: String = "invalid_input"
const REASON_NO_REGION: String = "no_region"
const REASON_NO_ENCOUNTER: String = "no_encounter"
const REASON_ALREADY_CLEARED: String = "already_cleared"
const REASON_DUPLICATE: String = "duplicate"
const REASON_NO_ACTIVE: String = "no_active"

## 非 String 的 id 在 trigger_rejected payload 里的统一占位（可机器判定、不崩）。
const ID_NONE: String = "<none>"

## 运行时状态（本实例内，不持久化、不写回 .tres）。
var _config: WorldEncounterConfig = null
var _current_region: String = ""
var _cleared: Dictionary = {}        # encounter_id -> bool（运行时清除态，绝不写回表）
var _active_id: String = ""          # 已触发、未清除的活跃遭遇
var _active_region: String = ""
var _cleared_count: int = 0          # 已清除遭遇总数（单调递增，除显式 reset）
var _enter_count: int = 0
var _trigger_count: int = 0
var _clear_count: int = 0
var _reject_count: int = 0
var _last_result: Dictionary = {}
var _last_reject_reason: String = ""


func _init(config: WorldEncounterConfig = null) -> void:
	_config = config
	reset()


## 允许构造后替换 / 注入表（含 null 用于「config 缺失」降级验证）。
func set_config(config: WorldEncounterConfig) -> void:
	_config = config
	reset()


func get_config() -> WorldEncounterConfig:
	return _config


## 回到构造初始态：清当前分区 / active / 计数 / 最近结果；清除态按表 cleared_flag
## 初始化（数据驱动「初始已清区域」）。每场新一局调用。
func reset() -> void:
	_current_region = ""
	_cleared = {}
	_active_id = ""
	_active_region = ""
	_cleared_count = 0
	_enter_count = 0
	_trigger_count = 0
	_clear_count = 0
	_reject_count = 0
	_last_result = {}
	_last_reject_reason = ""
	if _config_ok():
		for e: Variant in _config.get_encounters():
			var d: Dictionary = e as Dictionary
			var eid: String = String(d["id"])
			var init: bool = bool(d["cleared_flag"])
			_cleared[eid] = init
			if init:
				_cleared_count += 1


## ---- 内部只读：表合法性 / 降级基线（代码不写死设计数值）----
func _config_ok() -> bool:
	return _config != null and _config.is_valid()


func _invalid_input_policy_value() -> String:
	return _config.get_invalid_input_policy() if _config_ok() else WorldEncounterConfig.DEFAULT_INVALID_INPUT_POLICY


## ---- 只读查询（供 HUD / 断言 / 接线）----
func get_current_region() -> String:
	return _current_region


func get_active_encounter_id() -> String:
	return _active_id


func get_active_region() -> String:
	return _active_region


func get_cleared_count() -> int:
	return _cleared_count


func is_cleared(encounter_id: String) -> bool:
	return bool(_cleared.get(encounter_id, false))


func get_enter_count() -> int:
	return _enter_count


func get_trigger_count() -> int:
	return _trigger_count


func get_clear_count() -> int:
	return _clear_count


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
		"current_region": _current_region,
		"active_encounter": _active_id,
		"active_region": _active_region,
		"cleared_count": _cleared_count,
		"cleared_ids": _cleared.keys(),
		"enter_count": _enter_count,
		"trigger_count": _trigger_count,
		"clear_count": _clear_count,
		"reject_count": _reject_count,
		"region_count": _config.get_region_count() if _config_ok() else 0,
		"encounter_count": _config.get_encounter_count() if _config_ok() else 0,
		"config_present": _config != null,
		"invalid_input_policy": _invalid_input_policy_value(),
		"last_result": _last_result.duplicate(),
		"last_reject_reason": _last_reject_reason,
	}


## ---- 统一拒绝（发 trigger_rejected，供 Rank-4 反馈 / Rank-3 落盘取舍；不改状态）----
func _reject(reason: String, encounter_id: String) -> Dictionary:
	_reject_count += 1
	_last_reject_reason = reason
	trigger_rejected.emit(reason, encounter_id)
	var r: Dictionary = {
		"ok": false,
		"reason": reason,
		"encounter_id": encounter_id,
		"current_region": _current_region,
		"active_id": _active_id,
		"cleared_count": _cleared_count,
		"config_present": _config != null,
	}
	return r


## 进入分区：config / 输入 / 注册三重门；成功置当前分区、发 region_entered。
func enter_region(region_id: Variant) -> Dictionary:
	if not _config_ok():
		return _reject(REASON_NO_CONFIG, ID_NONE)
	if typeof(region_id) != TYPE_STRING or String(region_id).is_empty():
		return _reject(REASON_INVALID_INPUT, ID_NONE)
	var rid: String = String(region_id)
	if not _config.has_region(rid):
		return _reject(REASON_NO_REGION, ID_NONE)
	_current_region = rid
	_enter_count += 1
	region_entered.emit(rid)
	var r: Dictionary = {
		"ok": true,
		"reason": REASON_OK,
		"region_id": rid,
		"enter_count": _enter_count,
		"cleared_count": _cleared_count,
		"config_present": true,
	}
	_last_result = r.duplicate()
	return r


## 进入触发 + 距离判定 + 已清除不重复 + 重复触发幂等 + 异常拒绝。
func try_trigger(position: Variant) -> Dictionary:
	if not _config_ok():
		return _reject(REASON_NO_CONFIG, ID_NONE)
	if typeof(position) != TYPE_VECTOR2:
		return _reject(REASON_INVALID_INPUT, ID_NONE)
	var p: Vector2 = position as Vector2
	if is_nan(p.x) or is_nan(p.y) or is_inf(p.x) or is_inf(p.y):
		return _reject(REASON_INVALID_INPUT, ID_NONE)
	if _current_region.is_empty():
		return _reject(REASON_NO_REGION, ID_NONE)
	# 重复触发幂等：已有 active（未清除）遭遇 -> 拒绝，不二次发信号 / 不改状态。
	if not _active_id.is_empty():
		return _reject(REASON_DUPLICATE, _active_id)
	# 在当前区域找「半径内、未清除、最近」的遭遇点。
	var best_id: String = ""
	var best_dist: float = -1.0
	var best: Dictionary = {}
	var region_has_uncleared: bool = false
	var region_encounter_count: int = 0
	for e: Variant in _config.get_encounters():
		var d: Dictionary = e as Dictionary
		if String(d["region_id"]) != _current_region:
			continue
		region_encounter_count += 1
		if bool(_cleared.get(String(d["id"]), false)):
			continue
		region_has_uncleared = true
		var ep: Vector2 = d["position"] as Vector2
		var dist: float = p.distance_to(ep)
		var radius: float = float(d["trigger_radius"])
		if dist <= radius and (best_dist < 0.0 or dist < best_dist):
			best_dist = dist
			best_id = String(d["id"])
			best = d
	if region_encounter_count == 0:
		return _reject(REASON_NO_ENCOUNTER, ID_NONE)
	# 已清除区域不重复触发（该区域所有遭遇都已 cleared）。
	if not region_has_uncleared:
		return _reject(REASON_ALREADY_CLEARED, ID_NONE)
	# 距离外：半径内无未清除遭遇。
	if best_id.is_empty():
		return _reject(REASON_NO_ENCOUNTER, ID_NONE)
	_active_id = best_id
	_active_region = _current_region
	_trigger_count += 1
	var reward: int = int(best["reward_points"])
	encounter_triggered.emit(best_id, _active_region, reward)
	var r: Dictionary = {
		"ok": true,
		"reason": REASON_OK,
		"encounter_id": best_id,
		"region_id": _active_region,
		"enemy_group": String(best["enemy_group"]),
		"reward_points": reward,
		"distance": best_dist,
		"trigger_radius": float(best["trigger_radius"]),
		"trigger_count": _trigger_count,
		"cleared_count": _cleared_count,
		"config_present": true,
	}
	_last_result = r.duplicate()
	return r


## 标记区域已清除：只能清除当前 active 遭遇；进度单调递增、重复清除幂等。
func on_encounter_cleared(encounter_id: Variant) -> Dictionary:
	if not _config_ok():
		return _reject(REASON_NO_CONFIG, ID_NONE)
	if typeof(encounter_id) != TYPE_STRING or String(encounter_id).is_empty():
		return _reject(REASON_INVALID_INPUT, ID_NONE)
	var eid: String = String(encounter_id)
	if _active_id.is_empty() or _active_id != eid:
		return _reject(REASON_NO_ACTIVE, eid)
	if bool(_cleared.get(eid, false)):
		return _reject(REASON_ALREADY_CLEARED, eid)
	var region: String = _active_region
	_cleared[eid] = true
	_cleared_count += 1
	_clear_count += 1
	_active_id = ""
	_active_region = ""
	encounter_cleared.emit(eid, region, _cleared_count)
	var r: Dictionary = {
		"ok": true,
		"reason": REASON_OK,
		"encounter_id": eid,
		"region_id": region,
		"cleared_count": _cleared_count,
		"clear_count": _clear_count,
		"config_present": true,
	}
	_last_result = r.duplicate()
	return r
