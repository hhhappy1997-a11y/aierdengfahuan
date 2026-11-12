extends RefCounted
class_name StaggerService

## ===========================================================================
## R32 / v0.10.0 · Boss 韧性处决「结算纯逻辑」服务（RefCounted，Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-074023-393-A2）
## 目录所有权·R32 冻结：本文件归 Rank-2；encounter_director.gd（唯一写入方 Rank-1）/
##   hud.gd / impact_feedback.gd / 场景 / 素材 / 既有 .tres / 其它 Rank 文件只读、不改。
##
## 【纯逻辑边界（任务单 ② / 契约 I-1）】
## - 不继承 Node、不碰场景树、不 add_child、不取 root、不调用 get_tree()、
##   不用 /root/... 绝对路径、不读写存档文件、不碰渲染、不落盘、不加载任何资源
##   （StaggerConfig 规则表由构造注入）。
## - 信号是 Object 级能力（RefCounted 继承 Object），本服务用 3 个稳定 signal 把
##   「处决窗口状态」广播给 Rank-1（HUD 提示 / F 键处决），但不依赖场景树、不 connect
##   任何全局节点；订阅方自行 connect 到本实例。
## - 时间不由真实引擎时钟驱动（不用 Time.get_ticks_*），而由外部（导演层每帧）
##   调用 tick(delta_sec) 确定性推进，保证纯逻辑、可测、同帧多次请求不叠加异常。
## - 设计数值全部来自 res://data/combat/stagger_rules.tres，本文件不写死任何
##   [PLACEHOLDER] 数值（口径随表变化，调参只改表不改代码）。
##
## 【公开信号（供 Rank-1 接线，签名稳定，见 DONE-R32.md）】
##   signal stagger_value_changed(current: float, maximum: float)
##       —— 韧性变化（含恢复）时发，供 HUD 韧性条。
##   signal execution_window_opened(remaining_sec: float, bonus_points: int)
##       —— 韧性归零开窗时发，供 HUD 显示「可处决」+ 倒计时 / F 键提示。
##   signal execution_window_closed(reason: String)
##       —— 窗口关闭时发；reason ∈ {CLOSE_EXECUTED, CLOSE_TIMEOUT,
##          CLOSE_BOSS_DEFEATED}，供 HUD 收起提示。
##
## 【规则（任务单 ② 逐条）】
## - apply_hit(poise_damage)：玩家命中累积削韧（clamp 到 [0, max]，绝不负数）；
##   削到 0 时开启 [PLACEHOLDER] 秒处决窗口并 emit execution_window_opened。
##   * 异常：null / 非数值 / <=0 / NaN / Inf 削韧 -> REASON_INVALID_HIT 拒绝。
##   * config 缺失 -> REASON_NO_CONFIG 拒绝。
##   * Boss 已死亡 -> REASON_BOSS_DEFEATED 拒绝（不再开窗）。
##   * 窗口已开启期间的命中 -> REASON_WINDOW_OPEN 幂等拒绝：不改韧性、不重复开窗、
##     不叠加异常（连续命中不叠加）。
## - try_execute()：窗口内处决给 execute_bonus_points 额外点数、关闭窗口、恢复满韧性。
##   * 无窗口 / Boss 已死亡 -> REASON_NO_WINDOW 拒绝、不给点数（幂等，防重复刷点）。
## - tick(delta_sec)：驱动窗口倒计时；delta <= 窗口时长则递减，超过则超时自动
##   关闭窗口（emit execution_window_closed(CLOSE_TIMEOUT)）并恢复满韧性。
##   * 异常：null / 非数值 / <0 / NaN / Inf -> REASON_INVALID_DELTA 拒绝、不改状态。
##   * 无窗口时 no-op（ok=true，不崩）。
##   * 「超窗口时长」delta 一次即可触发超时关窗。
## - on_boss_defeated()：置死亡标志；若窗口开着立即关闭并恢复韧性；此后
##   apply_hit / try_execute 均拒绝、不再开窗。
## - reset()：恢复满韧性、关窗、清死亡标志与累计点数，供每次 Boss 战开始调用。
## - 额外点数累计 total_execute_bonus 只增、恒 >= 0（余额非负）。
##
## 【对接说明（不在本服务落地）】
##   导演层（Rank-1 encounter_director.gd）在玩家命中时调 apply_hit(招式削韧)，
##   每帧调 tick(delta)，订阅 3 个 signal 驱动 HUD；F 键处决调 try_execute()，
##   把返回的 bonus_points 交给点数结算层（Rank-3 I-1）。本服务只判定与广播、
##   不写存档、不碰渲染、不生成敌人。
##
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- 公开信号（签名稳定，供 Rank-1 订阅）----
signal stagger_value_changed(current: float, maximum: float)
signal execution_window_opened(remaining_sec: float, bonus_points: int)
signal execution_window_closed(reason: String)

## ---- 关窗原因（execution_window_closed 的 reason 取值）----
const CLOSE_EXECUTED: String = "executed"
const CLOSE_TIMEOUT: String = "timeout"
const CLOSE_BOSS_DEFEATED: String = "boss_defeated"

## ---- 方法返回 reason ----
const REASON_OK: String = "ok"
const REASON_NO_CONFIG: String = "no_config"
const REASON_INVALID_HIT: String = "invalid_hit"
const REASON_INVALID_DELTA: String = "invalid_delta"
const REASON_WINDOW_OPEN: String = "window_open_idempotent"
const REASON_BOSS_DEFEATED: String = "boss_defeated"
const REASON_NO_WINDOW: String = "no_window"

## 运行时状态（本实例内，不持久化）。
var _config: StaggerConfig = null
var _stagger_max: float = StaggerConfig.DEFAULT_STAGGER_MAX
var _window_duration: float = StaggerConfig.DEFAULT_WINDOW_DURATION_SEC
var _execute_bonus: int = StaggerConfig.DEFAULT_EXECUTE_BONUS_POINTS
var _stagger: float = StaggerConfig.DEFAULT_STAGGER_MAX
var _window_open: bool = false
var _window_remaining: float = 0.0
var _boss_defeated: bool = false
var _total_execute_bonus: int = 0


func _init(config: StaggerConfig = null) -> void:
	_config = config
	reset()


## 允许构造后替换 / 注入表（含 null 用于「config 缺失」降级验证）。
func set_config(config: StaggerConfig) -> void:
	_config = config
	reset()


func get_config() -> StaggerConfig:
	return _config


## 恢复满韧性、关窗、清死亡标志与累计点数（每次 Boss 战开始调用）。
func reset() -> void:
	var cfg_ok: bool = _config != null and _config.is_valid()
	_stagger_max = _config.stagger_max if cfg_ok else StaggerConfig.DEFAULT_STAGGER_MAX
	_window_duration = _config.window_duration_sec if cfg_ok else StaggerConfig.DEFAULT_WINDOW_DURATION_SEC
	_execute_bonus = _config.execute_bonus_points if cfg_ok else StaggerConfig.DEFAULT_EXECUTE_BONUS_POINTS
	_stagger = _stagger_max
	_window_open = false
	_window_remaining = 0.0
	_boss_defeated = false
	_total_execute_bonus = 0
	stagger_value_changed.emit(_stagger, _stagger_max)


func is_window_open() -> bool:
	return _window_open


func get_window_remaining() -> float:
	return _window_remaining


func get_stagger() -> float:
	return _stagger


func get_max_stagger() -> float:
	return _stagger_max


func is_boss_defeated() -> bool:
	return _boss_defeated


func get_total_execute_bonus() -> int:
	return _total_execute_bonus


## 状态快照（供 HUD / 断言读取，不改状态）。
func get_snapshot() -> Dictionary:
	return {
		"stagger": _stagger,
		"stagger_max": _stagger_max,
		"window_open": _window_open,
		"window_remaining": _window_remaining,
		"window_duration_sec": _window_duration,
		"execute_bonus_points": _execute_bonus,
		"boss_defeated": _boss_defeated,
		"total_execute_bonus": _total_execute_bonus,
	}


## 开窗（内部）：置窗口态、emit execution_window_opened。
func _open_window() -> void:
	_window_open = true
	_window_remaining = _window_duration
	execution_window_opened.emit(_window_remaining, _execute_bonus)


## 关窗（内部）：恢复满韧性、清倒计时、emit closed + stagger_value_changed。
func _close_window(reason: String) -> void:
	_window_open = false
	_window_remaining = 0.0
	_stagger = _stagger_max
	execution_window_closed.emit(reason)
	stagger_value_changed.emit(_stagger, _stagger_max)


## 玩家命中累积削韧。poise_damage 用 Variant 以便对 null / 非数值显式拒绝。
func apply_hit(poise_damage: Variant) -> Dictionary:
	if _config == null or not _config.is_valid():
		return _hit_result(false, REASON_NO_CONFIG, 0.0, false)
	if typeof(poise_damage) != TYPE_INT and typeof(poise_damage) != TYPE_FLOAT:
		return _hit_result(false, REASON_INVALID_HIT, 0.0, false)
	var dmg: float = float(poise_damage)
	if dmg <= 0.0 or is_nan(dmg) or is_inf(dmg):
		return _hit_result(false, REASON_INVALID_HIT, 0.0, false)
	if _boss_defeated:
		return _hit_result(false, REASON_BOSS_DEFEATED, dmg, false)
	# 窗口开启期间的命中：幂等拒绝，不改韧性、不重复开窗（连续命中不叠加异常）。
	if _window_open:
		return _hit_result(false, REASON_WINDOW_OPEN, dmg, false)
	_stagger = maxf(0.0, _stagger - dmg)
	stagger_value_changed.emit(_stagger, _stagger_max)
	var opened_now: bool = false
	if _stagger <= 0.0 and not _window_open:
		_open_window()
		opened_now = true
	return _hit_result(true, REASON_OK, dmg, opened_now)


func _hit_result(ok: bool, reason: String, dmg: float, opened_now: bool) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"poise_damage": dmg,
		"stagger": _stagger,
		"stagger_max": _stagger_max,
		"window_open": _window_open,
		"window_remaining": _window_remaining,
		"opened_now": opened_now,
	}


## 窗口内处决：给额外点数、关闭窗口并恢复满韧性。无窗口 / Boss 死亡则拒绝。
func try_execute() -> Dictionary:
	if not _window_open or _boss_defeated:
		return _execute_result(false, REASON_NO_WINDOW, 0)
	var bonus: int = maxi(0, _execute_bonus)
	_total_execute_bonus += bonus
	_close_window(CLOSE_EXECUTED)
	return _execute_result(true, REASON_OK, bonus)


func _execute_result(ok: bool, reason: String, bonus: int) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"bonus_points": bonus,
		"total_execute_bonus": _total_execute_bonus,
		"window_open": _window_open,
		"stagger": _stagger,
	}


## 确定性推进窗口倒计时（由导演层每帧调用）；超时自动关闭并恢复韧性。
func tick(delta_sec: Variant) -> Dictionary:
	if typeof(delta_sec) != TYPE_INT and typeof(delta_sec) != TYPE_FLOAT:
		return _tick_result(false, REASON_INVALID_DELTA, 0.0, false)
	var d: float = float(delta_sec)
	if d < 0.0 or is_nan(d) or is_inf(d):
		return _tick_result(false, REASON_INVALID_DELTA, 0.0, false)
	if not _window_open:
		return _tick_result(true, REASON_OK, d, false)
	_window_remaining -= d
	if _window_remaining <= 0.0:
		_close_window(CLOSE_TIMEOUT)
		return _tick_result(true, REASON_OK, d, true)
	return _tick_result(true, REASON_OK, d, false)


func _tick_result(ok: bool, reason: String, delta: float, timed_out: bool) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"delta_sec": delta,
		"window_open": _window_open,
		"window_remaining": _window_remaining,
		"timed_out": timed_out,
	}


## Boss 死亡：置标志、关窗（若开着）、此后不再开窗。
func on_boss_defeated() -> void:
	_boss_defeated = true
	if _window_open:
		_close_window(CLOSE_BOSS_DEFEATED)
