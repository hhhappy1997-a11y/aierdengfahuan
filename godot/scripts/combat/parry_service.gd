extends RefCounted
class_name ParryService

## ===========================================================================
## R35 / v0.12.0「精准弹反 · 消费闭合」· 精准弹反纯逻辑服务（RefCounted，Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-125821-139-A2）
## 目录所有权·R35 冻结：本文件归 Rank-2；encounter_director.gd（唯一写入方 Rank-1）/
##   hud.gd / presentation.gd / courtyard.tscn / 既有 .tres / 其它 Rank 文件只读、不改。
##
## 【纯逻辑边界（任务单 ① / 契约 I-1）】
## - 不继承 Node、不碰场景树、不 add_child、不取 root、不调用 get_tree()、
##   不用 /root/... 绝对路径、不读写存档文件、不碰渲染、不落盘、不加载任何资源
##   （ParryConfig 规则表由构造注入）。
## - 信号是 Object 级能力（RefCounted 继承 Object）：本服务用 4 个稳定 signal 把
##   「开窗 / 成功 / 失败 / 关窗」广播给 Rank-1（接线）与 Rank-4（视觉反馈），
##   但不依赖场景树、不 connect 任何全局节点；订阅方自行 connect 到本实例。
##   ★ A48①：wave_trial_director.gd（生产运行时节点）已生产订阅全部 4 信号（非验证脚本）。
##   ★ A54：唯一实例由 wave_trial_director.gd 装配，经 get_parry_service() 复用，绝不另建。
## - 时间不由真实引擎时钟驱动（不用 Time.get_ticks_*），由外部（导演层每帧）
##   调用 tick(delta_sec) 确定性推进，保证纯逻辑、可测、同帧多次请求不叠加异常。
## - 设计数值全部来自 res://data/combat/parry_rules.tres，本文件不写死任何
##   [PLACEHOLDER] 数值（口径随表变化，调参只改表不改代码）。
##
## 【公开信号（供 Rank-1 接线 / Rank-4 视觉反馈，签名稳定，见 DONE-R35.md）】
##   signal parry_window_opened(window_sec: float)
##       —— open_window() 成功开窗时发；供 HUD「精准弹反」提示 / Rank-4 前摇高亮。
##   signal parry_succeeded(poise_bonus: float, points_bonus: int, combo_keep: bool)
##       —— 窗口内 try_parry() 成功时发；payload 即并入结算的两项奖励 + 连击保持标志，
##          供 Rank-1 结算接线 / Rank-4 弹反火花演出。
##   signal parry_failed(reason: String, fail_penalty: int)
##       —— 弹反失败（超时 / Boss 招式落地未弹反）时发；reason ∈ {CLOSE_TIMEOUT,
##          CLOSE_MOVE_LANDED}，fail_penalty=表内记录量；供 Rank-4 失败反馈。
##   signal parry_window_closed(reason: String)
##       —— 窗口关闭时发；reason ∈ {CLOSE_SUCCESS, CLOSE_TIMEOUT, CLOSE_MOVE_LANDED,
##          CLOSE_BOSS_DEFEATED, CLOSE_MANUAL}；供 Rank-4 收起提示。
##
## 【规则（任务单 ① 逐条）】
## - open_window()：开启精准弹反窗口；config 缺失/非法 -> REASON_NO_CONFIG；Boss 已死亡 ->
##   REASON_BOSS_DEFEATED；冷却期 -> REASON_COOLDOWN；窗口已开 -> REASON_ALREADY_PARRIED
##   （幂等，不重复开窗）。成功置 window_remaining=window_sec、emit parry_window_opened。
## - try_parry()：玩家按弹反键。
##   * 窗口内且未消费 -> 成功：给 poise_bonus / points_bonus / combo_keep，关窗、进入冷却、
##     emit parry_succeeded + parry_window_closed(CLOSE_SUCCESS)，置 _consumed 幂等标志。
##   * 窗口外（未开窗）-> REASON_NO_WINDOW 拒绝；重复按键（_consumed，含冷却期内）
##     -> REASON_ALREADY_PARRIED 幂等拒绝；Boss 死亡 -> REASON_BOSS_DEFEATED；
##     config 缺失 -> REASON_NO_CONFIG；一律不给奖励、不改已成功状态（防刷点）。
##     「冷却期拒绝」由 open_window() 承载：成功后冷却期内 open_window -> REASON_COOLDOWN。
## - tick(delta_sec)：推进窗口倒计时与冷却倒计时；窗口归零 -> 超时关窗、
##   emit parry_failed(CLOSE_TIMEOUT, fail_penalty) + parry_window_closed(CLOSE_TIMEOUT)。
##   * 异常：null / 非数值 / <0 / NaN / Inf -> REASON_INVALID_DELTA 拒绝、不改状态。
##   * 无窗口时仍推进冷却（ok=true，不崩）。
## - on_boss_move_landed()：Boss 招式落地。窗口仍开且未弹反 -> 失败关窗、
##   emit parry_failed(CLOSE_MOVE_LANDED, fail_penalty) + parry_window_closed(CLOSE_MOVE_LANDED)；
##   已成功弹反 / 无窗口 -> 幂等 no-op（不重复惩罚）；Boss 死亡 / 无 config -> 拒绝。
## - on_boss_defeated()：置死亡标志、立即关窗（若开着）、此后不再开窗、拒绝弹反；幂等。
## - reset()：关窗、清冷却/死亡/消费标志与计数（每波 / 每场 Boss 战开始调用）。
## - 成功奖励只加不减（success_count / 记录只读）；失败惩罚只作记录，绝不扣减既有赐福点数，
##   守住「点数只增不减 / 余额非负」既有不变量。
##
## 【对接说明（不在本服务落地）】
##   Rank-1 在 Boss 出招前摇时调 open_window()、玩家按弹反键调 try_parry()、每帧调 tick(delta)、
##   Boss 招式落地调 on_boss_move_landed()、Boss 死亡调 on_boss_defeated()、每波开始调 reset()，
##   并订阅 4 个 signal 驱动 HUD 与 Rank-4 视觉反馈；parry_succeeded 的 points_bonus 由本轮
##   wave_trial_director.gd 生产订阅者并入既有清波点数结算（经 points_awarded 发最终值，不二次入账），
##   poise_bonus 并入既有 StaggerService 削韧结算。本服务只判定与广播、不写存档、不碰渲染。
##
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- 公开信号（签名稳定，供 Rank-1 订阅 / Rank-4 视觉反馈）----
signal parry_window_opened(window_sec: float)
signal parry_succeeded(poise_bonus: float, points_bonus: int, combo_keep: bool)
signal parry_failed(reason: String, fail_penalty: int)
signal parry_window_closed(reason: String)

## ---- 关窗 / 失败原因（parry_window_closed / parry_failed 的 reason 取值）----
const CLOSE_SUCCESS: String = "success"
const CLOSE_TIMEOUT: String = "timeout"
const CLOSE_MOVE_LANDED: String = "move_landed"
const CLOSE_BOSS_DEFEATED: String = "boss_defeated"
const CLOSE_MANUAL: String = "manual"

## ---- 方法返回 reason（公开常量，签名稳定）----
const REASON_OK: String = "ok"
const REASON_NO_CONFIG: String = "no_config"
const REASON_NO_WINDOW: String = "no_window"
const REASON_ALREADY_PARRIED: String = "already_parried"
const REASON_COOLDOWN: String = "cooldown"
const REASON_BOSS_DEFEATED: String = "boss_defeated"
const REASON_INVALID_DELTA: String = "invalid_delta"

## 运行时状态（本实例内，不持久化）。
var _config: ParryConfig = null
var _window_open: bool = false
var _window_remaining: float = 0.0
var _cooldown_remaining: float = 0.0
var _boss_defeated: bool = false
var _consumed: bool = false            # 本次窗口是否已成功弹反（重复按键幂等）
var _success_count: int = 0
var _fail_count: int = 0
var _last_result: Dictionary = {}
var _last_fail_penalty: int = 0


func _init(config: ParryConfig = null) -> void:
	_config = config
	reset()


## 允许构造后替换 / 注入表（含 null 用于「config 缺失」降级验证）。
func set_config(config: ParryConfig) -> void:
	_config = config
	reset()


func get_config() -> ParryConfig:
	return _config


## 关窗、清冷却 / 死亡 / 消费标志与计数（每波 / 每场 Boss 战开始调用）。
func reset() -> void:
	var was_open: bool = _window_open
	_window_open = false
	_window_remaining = 0.0
	_cooldown_remaining = 0.0
	_boss_defeated = false
	_consumed = false
	_success_count = 0
	_fail_count = 0
	_last_result = {}
	_last_fail_penalty = 0
	if was_open:
		parry_window_closed.emit(CLOSE_MANUAL)


func _config_ok() -> bool:
	return _config != null and _config.is_valid()


func _window_sec() -> float:
	return _config.get_window_sec() if _config_ok() else ParryConfig.DEFAULT_WINDOW_SEC


func _cooldown_sec() -> float:
	return _config.get_cooldown_sec() if _config_ok() else ParryConfig.DEFAULT_COOLDOWN_SEC


func _poise_bonus() -> float:
	return _config.get_poise_bonus() if _config_ok() else ParryConfig.DEFAULT_POISE_BONUS


func _points_bonus() -> int:
	return _config.get_points_bonus() if _config_ok() else ParryConfig.DEFAULT_POINTS_BONUS


func _combo_keep() -> bool:
	return _config.get_combo_keep() if _config_ok() else ParryConfig.DEFAULT_COMBO_KEEP


func _fail_penalty() -> int:
	return _config.get_fail_penalty() if _config_ok() else ParryConfig.DEFAULT_FAIL_PENALTY


## ---- 只读查询（供 HUD / 断言 / 接线）----
func is_window_open() -> bool:
	return _window_open


func get_window_remaining() -> float:
	return _window_remaining


func get_cooldown_remaining() -> float:
	return _cooldown_remaining


func is_boss_defeated() -> bool:
	return _boss_defeated


func is_consumed() -> bool:
	return _consumed


func get_success_count() -> int:
	return _success_count


func get_fail_count() -> int:
	return _fail_count


func get_last_result() -> Dictionary:
	return _last_result.duplicate()


func get_last_fail_penalty() -> int:
	return _last_fail_penalty


func get_window_sec() -> float:
	return _window_sec()


func get_cooldown_sec() -> float:
	return _cooldown_sec()


func get_poise_bonus() -> float:
	return _poise_bonus()


func get_points_bonus() -> int:
	return _points_bonus()


func get_combo_keep() -> bool:
	return _combo_keep()


func get_fail_penalty() -> int:
	return _fail_penalty()


func get_snapshot() -> Dictionary:
	return {
		"window_open": _window_open,
		"window_remaining": _window_remaining,
		"cooldown_remaining": _cooldown_remaining,
		"boss_defeated": _boss_defeated,
		"consumed": _consumed,
		"success_count": _success_count,
		"fail_count": _fail_count,
		"window_sec": _window_sec(),
		"cooldown_sec": _cooldown_sec(),
		"poise_bonus": _poise_bonus(),
		"points_bonus": _points_bonus(),
		"combo_keep": _combo_keep(),
		"fail_penalty": _fail_penalty(),
		"config_present": _config != null,
		"last_result": _last_result.duplicate(),
	}


## 开窗：开启精准弹反窗口（Boss 出招前摇 / 波次开始）。冷却期 / Boss 死亡 / 重复开窗一律拒绝。
func open_window() -> Dictionary:
	if not _config_ok():
		return _open_result(false, REASON_NO_CONFIG)
	if _boss_defeated:
		return _open_result(false, REASON_BOSS_DEFEATED)
	if _cooldown_remaining > 0.0:
		return _open_result(false, REASON_COOLDOWN)
	if _window_open:
		return _open_result(false, REASON_ALREADY_PARRIED)
	_window_open = true
	_window_remaining = _window_sec()
	_consumed = false
	parry_window_opened.emit(_window_remaining)
	return _open_result(true, REASON_OK)


func _open_result(ok: bool, reason: String) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"window_open": _window_open,
		"window_remaining": _window_remaining,
		"cooldown_remaining": _cooldown_remaining,
		"boss_defeated": _boss_defeated,
	}


## 玩家按弹反键：窗口内成功给奖励；窗口外 / 重复 / 冷却 / Boss 死亡 / 无 config 一律拒绝。
func try_parry() -> Dictionary:
	if not _config_ok():
		return _parry_result(false, REASON_NO_CONFIG, 0.0, 0, false)
	if _boss_defeated:
		return _parry_result(false, REASON_BOSS_DEFEATED, 0.0, 0, false)
	# 重复按键幂等：本次窗口已成功弹反后（含冷却期内）一律拒绝，不重复给奖励。
	# 「冷却期拒绝」由 open_window() 承载（成功后冷却期内不能再开窗刷奖励）。
	if _consumed:
		return _parry_result(false, REASON_ALREADY_PARRIED, 0.0, 0, false)
	if not _window_open:
		if _cooldown_remaining > 0.0:
			return _parry_result(false, REASON_COOLDOWN, 0.0, 0, false)
		return _parry_result(false, REASON_NO_WINDOW, 0.0, 0, false)
	var pb: float = _poise_bonus()
	var pts: int = _points_bonus()
	var ck: bool = _combo_keep()
	_consumed = true
	_window_open = false
	_window_remaining = 0.0
	_cooldown_remaining = _cooldown_sec()
	_success_count += 1
	parry_succeeded.emit(pb, pts, ck)
	parry_window_closed.emit(CLOSE_SUCCESS)
	var r: Dictionary = _parry_result(true, REASON_OK, pb, pts, ck)
	_last_result = r.duplicate()
	return r


func _parry_result(ok: bool, reason: String, poise_bonus: float, points_bonus: int,
		combo_keep: bool) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"poise_bonus": poise_bonus,
		"points_bonus": points_bonus,
		"combo_keep": combo_keep,
		"window_open": _window_open,
		"cooldown_remaining": _cooldown_remaining,
		"success_count": _success_count,
		"boss_defeated": _boss_defeated,
	}


## 确定性推进窗口 / 冷却倒计时（由导演层每帧调用）；窗口归零 -> 超时失败关窗。
func tick(delta_sec: Variant) -> Dictionary:
	if typeof(delta_sec) != TYPE_INT and typeof(delta_sec) != TYPE_FLOAT:
		return _tick_result(false, REASON_INVALID_DELTA, 0.0, false)
	var d: float = float(delta_sec)
	if d < 0.0 or is_nan(d) or is_inf(d):
		return _tick_result(false, REASON_INVALID_DELTA, 0.0, false)
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - d)
	var timed_out: bool = false
	if _window_open:
		_window_remaining -= d
		if _window_remaining <= 0.0:
			_window_open = false
			_window_remaining = 0.0
			_fail_count += 1
			_last_fail_penalty = _fail_penalty()
			timed_out = true
			parry_failed.emit(CLOSE_TIMEOUT, _last_fail_penalty)
			parry_window_closed.emit(CLOSE_TIMEOUT)
	return _tick_result(true, REASON_OK, d, timed_out)


func _tick_result(ok: bool, reason: String, delta: float, timed_out: bool) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"delta_sec": delta,
		"window_open": _window_open,
		"window_remaining": _window_remaining,
		"cooldown_remaining": _cooldown_remaining,
		"timed_out": timed_out,
	}


## Boss 招式落地：窗口仍开且未弹反 -> 失败关窗；已成功 / 无窗口 -> 幂等 no-op。
func on_boss_move_landed() -> Dictionary:
	if not _config_ok():
		return _move_result(false, REASON_NO_CONFIG)
	if _boss_defeated:
		return _move_result(false, REASON_BOSS_DEFEATED)
	if _consumed or not _window_open:
		return _move_result(true, REASON_OK)
	_window_open = false
	_window_remaining = 0.0
	_fail_count += 1
	_last_fail_penalty = _fail_penalty()
	parry_failed.emit(CLOSE_MOVE_LANDED, _last_fail_penalty)
	parry_window_closed.emit(CLOSE_MOVE_LANDED)
	return _move_result(true, REASON_OK)


func _move_result(ok: bool, reason: String) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"window_open": _window_open,
		"fail_count": _fail_count,
		"fail_penalty": _last_fail_penalty,
		"boss_defeated": _boss_defeated,
	}


## Boss 死亡：置标志、关窗（若开着）、此后不再开窗 / 拒绝弹反；幂等。
func on_boss_defeated() -> Dictionary:
	if _boss_defeated:
		return _boss_result(false, REASON_BOSS_DEFEATED)
	_boss_defeated = true
	if _window_open:
		_window_open = false
		_window_remaining = 0.0
		parry_window_closed.emit(CLOSE_BOSS_DEFEATED)
	return _boss_result(true, REASON_OK)


func _boss_result(ok: bool, reason: String) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"window_open": _window_open,
		"boss_defeated": _boss_defeated,
		"success_count": _success_count,
	}
