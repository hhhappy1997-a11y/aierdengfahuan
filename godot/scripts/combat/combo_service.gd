extends RefCounted
class_name ComboService

## ===========================================================================
## R34 / v0.11.0「玩法闭合 · 连击评价」· Combo Rank 纯逻辑服务（RefCounted，Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-091304-451-A2）
## 目录所有权·R34 冻结：本文件归 Rank-2；encounter_director.gd（唯一写入方 Rank-1）/
##   hud.gd / presentation.gd / courtyard.tscn / 既有 .tres / 其它 Rank 文件只读、不改。
##
## 【纯逻辑边界（任务单 ① / 契约 I-1）】
## - 不继承 Node、不碰场景树、不 add_child、不取 root、不调用 get_tree()、
##   不用 /root/... 绝对路径、不读写存档文件、不碰渲染、不落盘、不加载任何资源
##   （ComboConfig 规则表由构造注入）。
## - 信号是 Object 级能力（RefCounted 继承 Object）：本服务用 4 个稳定 signal 把
##   「连击数 / 评级 / 重置 / 结算」广播给 Rank-1（接线）与 Rank-4（视觉反馈），
##   但不依赖场景树、不 connect 任何全局节点；订阅方自行 connect 到本实例。
## - 时间不由真实引擎时钟驱动（不用 Time.get_ticks_*），由外部（导演层每帧）
##   调用 tick(delta_sec) 确定性推进，保证纯逻辑、可测、同帧多次请求不叠加异常。
## - 设计数值全部来自 res://data/rpg/combo_rules.tres，本文件不写死任何
##   [PLACEHOLDER] 数值（口径随表变化，调参只改表不改代码）。
##
## 【公开信号（供 Rank-1 接线 / Rank-4 视觉反馈，签名稳定，见 DONE-R34.md）】
##   signal combo_changed(count: int, rank: String)
##       —— combo 数变化时发（命中累积 / 重置）；供 HUD 连击数、Rank-4 连击条。
##   signal rank_changed(from_rank: String, to_rank: String, multiplier: float)
##       —— 评级跨 D/C/B/A/S 档时发（含升/降档）；供 Rank-4 评级演出 / 特效切换。
##   signal combo_reset(reason: String)
##       —— combo 归零时发；reason ∈ {RESET_HIT_TAKEN, RESET_TIMEOUT,
##          RESET_BOSS_DEFEATED, RESET_MANUAL}；供 Rank-4 收起连击特效。
##   signal combo_settled(total_points: int, base_points: int, rank: String, multiplier: float)
##       —— Boss 死亡 / 清波结算完成时发；供 Rank-1 接线到点数结算层 / Rank-4 结算演出。
##
## 【规则（任务单 ① 逐条）】
## - register_hit(damage)：连续命中不中断累积 combo（每次 +1、刷新连击计时）。
##   * 异常：null / 非数值 / <=0 / NaN / Inf 伤害 -> REASON_INVALID_HIT 拒绝、不改状态。
##   * config 缺失/非法 -> REASON_NO_CONFIG；Boss 已死亡 -> REASON_BOSS_DEFEATED；
##     已结算 -> REASON_ALREADY_SETTLED（重复输入拒绝）。
##   * 命中后按门槛重算评级；跨档 emit rank_changed，每次 emit combo_changed。
## - 评级 D/C/B/A/S 影响赐福点数结算倍率：settle(base_points) 用【当前评级】倍率
##   放大点数（total = round(base * multiplier)），D 级倍率 1.0 保证不低于基础点数。
## - on_hit_taken()：受击中断连击（reset_on_hit_taken=true 时归零、emit combo_reset）；
##   该字段为 false 时 no-op（REASON_RESET_DISABLED，不改 combo）。
## - tick(delta_sec)：推进「距上次命中」计时；>= timeout_sec 时连击中断归零、
##   emit combo_reset(RESET_TIMEOUT)。delta 异常拒绝；无 combo / 已结算 / Boss 死亡 no-op。
## - on_boss_defeated()：置死亡标志、定格评级；此后 register_hit 拒绝、tick 不再
##   超时重置；允许随后 settle() 做一次「Boss 死亡结算」。重复调用幂等拒绝。
## - settle(base_points)：按当前评级倍率结算点数，成功后置 _settled（幂等，防同帧
##   多次 / 重复结算刷点）；异常（null / 负 / 非数值 / NaN / Inf）拒绝、不产出点数。
##   成功恒 balance = max(0,total) >= 0、bonus >= 0（余额非负、只增不减）。
## - reset()：combo 归零、评级回 D、清死亡/结算标志与计时（每波 / 每场 Boss 战开始调用）。
##
## 【对接说明（不在本服务落地）】
##   Rank-1 在玩家命中时调 register_hit(damage)、每帧调 tick(delta)、受击调
##   on_hit_taken()、Boss 死亡调 on_boss_defeated()、清波/结算调 settle(base_points)，
##   并订阅 4 个 signal 驱动 HUD 与 Rank-4 视觉反馈；settle 返回的 total_points
##   交给点数结算层（Rank-3 I-1）落盘，本服务只判定与广播、不写存档、不碰渲染。
##
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- 公开信号（签名稳定，供 Rank-1 订阅 / Rank-4 视觉反馈）----
signal combo_changed(count: int, rank: String)
signal rank_changed(from_rank: String, to_rank: String, multiplier: float)
signal combo_reset(reason: String)
signal combo_settled(total_points: int, base_points: int, rank: String, multiplier: float)

## ---- combo_reset(reason) 取值（公开常量，签名稳定）----
const RESET_HIT_TAKEN: String = "hit_taken"
const RESET_TIMEOUT: String = "timeout"
const RESET_BOSS_DEFEATED: String = "boss_defeated"
const RESET_MANUAL: String = "manual"

## ---- 方法返回 reason（公开常量，签名稳定）----
const REASON_OK: String = "ok"
const REASON_NO_CONFIG: String = "no_config"
const REASON_INVALID_HIT: String = "invalid_hit"
const REASON_INVALID_POINTS: String = "invalid_points"
const REASON_INVALID_DELTA: String = "invalid_delta"
const REASON_BOSS_DEFEATED: String = "boss_defeated"
const REASON_ALREADY_DEFEATED: String = "already_defeated"
const REASON_ALREADY_SETTLED: String = "already_settled"
const REASON_RESET_DISABLED: String = "reset_disabled"

## 运行时状态（本实例内，不持久化）。
var _config: ComboConfig = null
var _combo: int = 0
var _elapsed: float = 0.0
var _rank: String = "D"
var _boss_defeated: bool = false
var _settled: bool = false
var _last_settlement: Dictionary = {}


func _init(config: ComboConfig = null) -> void:
	_config = config
	reset()


## 允许构造后替换 / 注入表（含 null 用于「config 缺失」降级验证）。
func set_config(config: ComboConfig) -> void:
	_config = config
	reset()


func get_config() -> ComboConfig:
	return _config


## 归零连击、评级回 D、清死亡/结算/计时标志（每波 / 每场 Boss 战开始调用）。
func reset() -> void:
	_combo = 0
	_elapsed = 0.0
	_rank = _compute_rank(0)
	_boss_defeated = false
	_settled = false
	_last_settlement = {}
	combo_changed.emit(0, _rank)
	combo_reset.emit(RESET_MANUAL)


func _config_ok() -> bool:
	return _config != null and _config.is_valid()


func _compute_rank(combo: int) -> String:
	if not _config_ok():
		return ComboConfig.RANK_ORDER[0]      # 降级：D
	return _config.get_rank_for_combo(combo)


func _multiplier() -> float:
	if not _config_ok():
		return 1.0
	return _config.get_multiplier_for_rank(_rank)


func _timeout() -> float:
	return _config.timeout_sec if _config_ok() else ComboConfig.DEFAULT_TIMEOUT_SEC


func _reset_on_hit() -> bool:
	return _config.reset_on_hit_taken if _config_ok() else ComboConfig.DEFAULT_RESET_ON_HIT_TAKEN


## 内部归零：emit combo_reset + combo_changed；评级降档时补发 rank_changed。
func _reset_combo(reason: String) -> void:
	_combo = 0
	_elapsed = 0.0
	var old: String = _rank
	_rank = _compute_rank(0)
	combo_reset.emit(reason)
	combo_changed.emit(0, _rank)
	if old != _rank:
		rank_changed.emit(old, _rank, _multiplier())


## ---- 只读查询（供 HUD / 断言 / 接线）----
func get_combo() -> int:
	return _combo


func get_rank() -> String:
	return _rank


func get_multiplier() -> float:
	return _multiplier()


func get_elapsed_since_hit() -> float:
	return _elapsed


func get_timeout_sec() -> float:
	return _timeout()


func get_reset_on_hit_taken() -> bool:
	return _reset_on_hit()


func is_boss_defeated() -> bool:
	return _boss_defeated


func is_settled() -> bool:
	return _settled


func get_last_settlement() -> Dictionary:
	return _last_settlement.duplicate()


func get_snapshot() -> Dictionary:
	return {
		"combo": _combo,
		"rank": _rank,
		"multiplier": _multiplier(),
		"elapsed_since_hit": _elapsed,
		"timeout_sec": _timeout(),
		"reset_on_hit_taken": _reset_on_hit(),
		"boss_defeated": _boss_defeated,
		"settled": _settled,
		"config_present": _config != null,
		"last_settlement": _last_settlement.duplicate(),
	}


## 玩家命中：combo +1、刷新计时、按门槛重算评级。damage 用 Variant 以显式拒绝异常。
func register_hit(damage: Variant) -> Dictionary:
	if not _config_ok():
		return _hit_result(false, REASON_NO_CONFIG, 0.0)
	if _boss_defeated:
		return _hit_result(false, REASON_BOSS_DEFEATED, 0.0)
	if _settled:
		return _hit_result(false, REASON_ALREADY_SETTLED, 0.0)
	if typeof(damage) != TYPE_INT and typeof(damage) != TYPE_FLOAT:
		return _hit_result(false, REASON_INVALID_HIT, 0.0)
	var d: float = float(damage)
	if d <= 0.0 or is_nan(d) or is_inf(d):
		return _hit_result(false, REASON_INVALID_HIT, 0.0)
	_combo += 1
	_elapsed = 0.0
	var old: String = _rank
	_rank = _compute_rank(_combo)
	combo_changed.emit(_combo, _rank)
	if old != _rank:
		rank_changed.emit(old, _rank, _multiplier())
	return {
		"ok": true,
		"reason": REASON_OK,
		"damage": d,
		"combo": _combo,
		"rank": _rank,
		"multiplier": _multiplier(),
		"rank_up": old != _rank,
	}


func _hit_result(ok: bool, reason: String, damage: float) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"damage": damage,
		"combo": _combo,
		"rank": _rank,
		"multiplier": _multiplier(),
		"rank_up": false,
	}


## 玩家受击：reset_on_hit_taken=true 时中断连击归零；false 时 no-op（不改 combo）。
func on_hit_taken() -> Dictionary:
	if _boss_defeated or _settled:
		return {"ok": true, "reason": REASON_OK, "reset": false, "combo": _combo, "rank": _rank}
	if not _reset_on_hit():
		return {"ok": true, "reason": REASON_RESET_DISABLED, "reset": false, "combo": _combo, "rank": _rank}
	_reset_combo(RESET_HIT_TAKEN)
	return {"ok": true, "reason": REASON_OK, "reset": true, "combo": 0, "rank": _rank}


## 确定性推进连击计时（由导演层每帧调用）；>= timeout_sec 时超时中断归零。
func tick(delta_sec: Variant) -> Dictionary:
	if typeof(delta_sec) != TYPE_INT and typeof(delta_sec) != TYPE_FLOAT:
		return _tick_result(false, REASON_INVALID_DELTA, 0.0, false)
	var d: float = float(delta_sec)
	if d < 0.0 or is_nan(d) or is_inf(d):
		return _tick_result(false, REASON_INVALID_DELTA, 0.0, false)
	if _boss_defeated or _settled or _combo == 0:
		return _tick_result(true, REASON_OK, d, false)
	_elapsed += d
	if _elapsed >= _timeout():
		_reset_combo(RESET_TIMEOUT)
		return _tick_result(true, REASON_OK, d, true)
	return _tick_result(true, REASON_OK, d, false)


func _tick_result(ok: bool, reason: String, delta: float, timed_out: bool) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"delta_sec": delta,
		"combo": _combo,
		"rank": _rank,
		"elapsed_since_hit": _elapsed,
		"timed_out": timed_out,
	}


## Boss 死亡：置标志、定格评级；此后不再接受命中 / 不再超时重置，等待 settle()。
func on_boss_defeated() -> Dictionary:
	if _boss_defeated:
		return _boss_result(false, REASON_ALREADY_DEFEATED)
	_boss_defeated = true
	return _boss_result(true, REASON_OK)


func _boss_result(ok: bool, reason: String) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"combo": _combo,
		"rank": _rank,
		"multiplier": _multiplier(),
		"boss_defeated": _boss_defeated,
	}


## 赐福点数结算：按【当前评级】倍率放大 base_points；幂等（防重复 / 同帧刷点）。
func settle(base_points: Variant) -> Dictionary:
	if not _config_ok():
		return _settle_result(false, REASON_NO_CONFIG, 0, 0, 0, 0, _rank, _multiplier())
	if typeof(base_points) != TYPE_INT and typeof(base_points) != TYPE_FLOAT:
		return _settle_result(false, REASON_INVALID_POINTS, 0, 0, 0, 0, _rank, _multiplier())
	var raw: float = float(base_points)
	if raw < 0.0 or is_nan(raw) or is_inf(raw):
		return _settle_result(false, REASON_INVALID_POINTS, 0, 0, 0, 0, _rank, _multiplier())
	var base: int = int(raw)
	if _settled:
		return _settle_result(false, REASON_ALREADY_SETTLED, base, 0, 0, 0, _rank, _multiplier())
	var mult: float = _multiplier()
	var total: int = int(roundf(float(base) * mult))
	if total < 0:
		total = 0                         # 防御夹取：余额非负不变量
	var bonus: int = maxi(0, total - base)
	var balance: int = maxi(0, total)
	_settled = true
	var result: Dictionary = _settle_result(true, REASON_OK, base, total, bonus, balance, _rank, mult)
	_last_settlement = result.duplicate()
	combo_settled.emit(total, base, _rank, mult)
	return result


func _settle_result(ok: bool, reason: String, base: int, total: int, bonus: int,
		balance: int, rank: String, mult: float) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"base_points": base,
		"total_points": total,
		"bonus_points": bonus,
		"balance": balance,
		"rank": rank,
		"multiplier": mult,
		"combo": _combo,
		"settled": _settled,
	}
