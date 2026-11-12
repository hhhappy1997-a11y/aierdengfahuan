extends SceneTree

## ===========================================================================
## R35 / v0.12.0 · 精准弹反 Parry「规则表 + 纯逻辑 + 信号」自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_parry_v120.gd
## 覆盖（任务单 ①）：正常 / 边界 / 异常三类输入 ——
##   正常：开窗、窗口内成功、4 信号 connect + payload、成功奖励值、成功计数与冷却；
##   边界：窗口外拒绝、重复按键幂等、重复开窗幂等、冷却期拒绝、冷却后可再开窗、
##         恰好超时 / 超时关闭、窗口内递减、Boss 招式落地失败 / 成功后 no-op、
##         Boss 死亡不再开窗 / 幂等、reset 清状态；
##   异常：tick(null / 负数 / 字符串 / NaN / Inf)、config=null、set_config(null)、
##         非法表（window_sec<=0 / NaN）、异常拒绝后正常流程仍成立。
## 输出逐条 PASS=true/false + SUMMARY + OVERALL=PASS/FAIL + RESULT=ALL_MATCH；失败 quit(1)。
## --script 模式纪律：不 add_child、不取 /root/... 绝对路径、不用 get_tree()；
##   用 Engine.get_main_loop() as SceneTree 取 root 做只读断言；读表 CACHE_MODE_IGNORE；
##   不写 user:// 存档、不碰渲染；时间由 tick(delta) 确定性驱动，不依赖真实引擎时钟。
## 期望值来自 parry_rules.tres 首版 [PLACEHOLDER]（0.35 / 1.2 / 25.0 / 50 / true / 10）。
##   调参只改表，同步本脚本 EXPECT_*。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const CONFIG_PATH: String = "res://data/combat/parry_rules.tres"
const DIRECTOR_PATH: String = "res://scripts/combat/wave_trial_director.gd"

## [PLACEHOLDER] R35 首版期望（校验基准，不写进数据表；待人工试玩校准）。
const EXPECT_WINDOW_SEC: float = 0.35
const EXPECT_COOLDOWN_SEC: float = 1.2
const EXPECT_POISE_BONUS: float = 25.0
const EXPECT_POINTS_BONUS: int = 50
const EXPECT_COMBO_KEEP: bool = true
const EXPECT_FAIL_PENALTY: int = 10

var _pass: int = 0
var _fail: int = 0

## 信号计数 / payload（connect 后统计，每组开头 _reset_signals() 清零）。
var _sig_opened: int = 0
var _sig_succeeded: int = 0
var _sig_failed: int = 0
var _sig_closed: int = 0
var _last_open_sec: float = -1.0
var _last_success_payload: Array = []
var _last_fail_reason: String = ""
var _last_fail_penalty: int = -1
var _last_close_reason: String = ""


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V120-PR] %s PASS=%s | %s" % [tag, str(ok), detail])


func _on_opened(window_sec: float) -> void:
	_sig_opened += 1
	_last_open_sec = window_sec


func _on_succeeded(poise_bonus: float, points_bonus: int, combo_keep: bool) -> void:
	_sig_succeeded += 1
	_last_success_payload = [poise_bonus, points_bonus, combo_keep]


func _on_failed(reason: String, fail_penalty: int) -> void:
	_sig_failed += 1
	_last_fail_reason = reason
	_last_fail_penalty = fail_penalty


func _on_closed(reason: String) -> void:
	_sig_closed += 1
	_last_close_reason = reason


func _reset_signals() -> void:
	_sig_opened = 0
	_sig_succeeded = 0
	_sig_failed = 0
	_sig_closed = 0
	_last_open_sec = -1.0
	_last_success_payload = []
	_last_fail_reason = ""
	_last_fail_penalty = -1
	_last_close_reason = ""


## 构造并 connect 4 个公开信号（Object 级，不经场景树）。
func _make(cfg: ParryConfig) -> ParryService:
	var s: ParryService = ParryService.new(cfg)
	s.connect("parry_window_opened", Callable(self, "_on_opened"))
	s.connect("parry_succeeded", Callable(self, "_on_succeeded"))
	s.connect("parry_failed", Callable(self, "_on_failed"))
	s.connect("parry_window_closed", Callable(self, "_on_closed"))
	return s


func _initialize() -> void:
	print("[V120-PR] === SELFTEST START ===")
	# --script 模式纪律：用 Engine.get_main_loop() as SceneTree 取 root（只读断言），
	# 不用 get_tree()、不用 /root/... 绝对路径；本夹具纯内存，不 add_child。
	var ml: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = ml as SceneTree
	var root_node: Node = tree.root if tree != null else null
	_ck("scene_tree_root_via_main_loop", tree != null and root_node != null,
		"Engine.get_main_loop() as SceneTree -> root，不用 get_tree()/绝对路径")
	var cfg: ParryConfig = ResourceLoader.load(
		CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as ParryConfig
	_ck("table_load_cache_ignore", cfg != null, "path=%s" % CONFIG_PATH)
	if cfg == null:
		_finish()
		return

	_test_ruleset(cfg)
	_test_normal(cfg)
	_test_boundary(cfg)
	_test_abnormal(cfg)
	_test_production_subscriber()
	_finish()


## A) 规则表 6 字段 [PLACEHOLDER] + 合法性 + 4 信号存在 + 降级基线 != 设计值
func _test_ruleset(cfg: ParryConfig) -> void:
	_ck("ruleset_valid", cfg.is_valid(), "ParryConfig.is_valid()=true")
	_ck("window_sec_ph", is_equal_approx(cfg.get_window_sec(), EXPECT_WINDOW_SEC),
		"got=%.2f expect=%.2f [PLACEHOLDER]" % [cfg.get_window_sec(), EXPECT_WINDOW_SEC])
	_ck("cooldown_sec_ph", is_equal_approx(cfg.get_cooldown_sec(), EXPECT_COOLDOWN_SEC),
		"got=%.2f expect=%.2f [PLACEHOLDER]" % [cfg.get_cooldown_sec(), EXPECT_COOLDOWN_SEC])
	_ck("poise_bonus_ph", is_equal_approx(cfg.get_poise_bonus(), EXPECT_POISE_BONUS),
		"got=%.1f expect=%.1f [PLACEHOLDER]" % [cfg.get_poise_bonus(), EXPECT_POISE_BONUS])
	_ck("points_bonus_ph", cfg.get_points_bonus() == EXPECT_POINTS_BONUS,
		"got=%d expect=%d [PLACEHOLDER]" % [cfg.get_points_bonus(), EXPECT_POINTS_BONUS])
	_ck("combo_keep_ph", cfg.get_combo_keep() == EXPECT_COMBO_KEEP,
		"got=%s expect=%s [PLACEHOLDER]" % [str(cfg.get_combo_keep()), str(EXPECT_COMBO_KEEP)])
	_ck("fail_penalty_ph", cfg.get_fail_penalty() == EXPECT_FAIL_PENALTY,
		"got=%d expect=%d [PLACEHOLDER]" % [cfg.get_fail_penalty(), EXPECT_FAIL_PENALTY])
	var s: ParryService = ParryService.new(cfg)
	_ck("signal_window_opened_exists", s.has_signal("parry_window_opened"),
		"signal parry_window_opened(window_sec: float)")
	_ck("signal_succeeded_exists", s.has_signal("parry_succeeded"),
		"signal parry_succeeded(poise_bonus: float, points_bonus: int, combo_keep: bool)")
	_ck("signal_failed_exists", s.has_signal("parry_failed"),
		"signal parry_failed(reason: String, fail_penalty: int)")
	_ck("signal_window_closed_exists", s.has_signal("parry_window_closed"),
		"signal parry_window_closed(reason: String)")
	_ck("default_is_not_design_window", not is_equal_approx(
		float(ParryConfig.DEFAULT_WINDOW_SEC), cfg.get_window_sec()),
		"DEFAULT_WINDOW_SEC != 表值（调参唯一入口在 .tres，代码基线不是设计数值）")
	_ck("default_is_not_design_points", ParryConfig.DEFAULT_POINTS_BONUS != cfg.get_points_bonus(),
		"DEFAULT_POINTS_BONUS != 表值（同上）")


## B) 正常：开窗 → 窗口内成功 → 奖励 / 信号 / 计数 / 冷却
func _test_normal(cfg: ParryConfig) -> void:
	_reset_signals()
	var s: ParryService = _make(cfg)
	var o: Dictionary = s.open_window()
	_ck("window_open_ok", bool(o.get("ok")) and str(o.get("reason")) == "ok" \
		and bool(o.get("window_open")) and is_equal_approx(float(o.get("window_remaining")), EXPECT_WINDOW_SEC),
		"open_window -> ok / window_open=true / remaining=0.35")
	_ck("signal_opened_1", _sig_opened == 1 and is_equal_approx(_last_open_sec, EXPECT_WINDOW_SEC),
		"parry_window_opened 恰 1 次，payload window_sec=0.35")
	var p: Dictionary = s.try_parry()
	_ck("window_success_ok", bool(p.get("ok")) and str(p.get("reason")) == "ok",
		"窗口内 try_parry -> ok")
	_ck("success_poise_bonus", is_equal_approx(float(p.get("poise_bonus")), EXPECT_POISE_BONUS),
		"poise_bonus=25.0 [PLACEHOLDER]")
	_ck("success_points_bonus", int(p.get("points_bonus")) == EXPECT_POINTS_BONUS,
		"points_bonus=50 [PLACEHOLDER]")
	_ck("success_combo_keep", bool(p.get("combo_keep")) == EXPECT_COMBO_KEEP,
		"combo_keep=true [PLACEHOLDER]")
	_ck("signal_succeeded_1", _sig_succeeded == 1 and _last_success_payload.size() == 3 \
		and is_equal_approx(float(_last_success_payload[0]), EXPECT_POISE_BONUS) \
		and int(_last_success_payload[1]) == EXPECT_POINTS_BONUS \
		and bool(_last_success_payload[2]) == EXPECT_COMBO_KEEP,
		"parry_succeeded 恰 1 次，payload=(25.0,50,true)")
	_ck("signal_closed_success", _sig_closed == 1 and _last_close_reason == "success",
		"parry_window_closed(reason=success) 恰 1 次")
	_ck("success_state", s.get_success_count() == 1 and not s.is_window_open() \
		and is_equal_approx(s.get_cooldown_remaining(), EXPECT_COOLDOWN_SEC),
		"success_count=1 / window 关闭 / cooldown=1.2")
	_ck("last_result_fields", bool(s.get_last_result().get("ok")) \
		and int(s.get_last_result().get("points_bonus")) == EXPECT_POINTS_BONUS,
		"get_last_result()=成功结算副本")
	var snap: Dictionary = s.get_snapshot()
	_ck("snapshot_fields", snap.has("window_open") and snap.has("cooldown_remaining") \
		and snap.has("success_count") and snap.has("config_present") and snap.has("last_result"),
		"get_snapshot() 全状态快照字段齐全")


## C) 边界：窗口外 / 重复按键 / 冷却 / 超时 / Boss 招式 / Boss 死亡 / reset
func _test_boundary(cfg: ParryConfig) -> void:
	# 窗口外拒绝
	_reset_signals()
	var s1: ParryService = _make(cfg)
	var r1: Dictionary = s1.try_parry()
	_ck("window_outside_reject", not bool(r1.get("ok")) \
		and str(r1.get("reason")) == ParryService.REASON_NO_WINDOW \
		and int(r1.get("points_bonus")) == 0 and s1.get_success_count() == 0,
		"未开窗 try_parry -> no_window 拒绝、不给奖励")
	# 重复按键幂等
	_reset_signals()
	var s2: ParryService = _make(cfg)
	s2.open_window()
	s2.try_parry()
	var r2: Dictionary = s2.try_parry()
	_ck("duplicate_key_idempotent", not bool(r2.get("ok")) \
		and str(r2.get("reason")) == ParryService.REASON_ALREADY_PARRIED \
		and s2.get_success_count() == 1,
		"成功后重复按键 -> already_parried 幂等拒绝，success_count 仍 1（不刷点）")
	# 重复开窗幂等
	_reset_signals()
	var s3: ParryService = _make(cfg)
	s3.open_window()
	var r3: Dictionary = s3.open_window()
	_ck("repeat_open_idempotent", not bool(r3.get("ok")) \
		and str(r3.get("reason")) == ParryService.REASON_ALREADY_PARRIED,
		"窗口已开再 open_window -> already_parried 幂等拒绝（不重复开窗）")
	# 冷却期拒绝
	_reset_signals()
	var s4: ParryService = _make(cfg)
	s4.open_window()
	s4.try_parry()
	var o4: Dictionary = s4.open_window()
	var t4: Dictionary = s4.try_parry()
	_ck("cooldown_reject_open", not bool(o4.get("ok")) \
		and str(o4.get("reason")) == ParryService.REASON_COOLDOWN,
		"成功后冷却期 open_window -> cooldown 拒绝")
	_ck("cooldown_reject_parry", not bool(t4.get("ok")) \
		and int(t4.get("points_bonus")) == 0 and s4.get_success_count() == 1,
		"成功后冷却期 try_parry -> 重复按键幂等拒绝（不给奖励、success_count 仍 1）")
	# 冷却推进后可再开窗
	s4.tick(EXPECT_COOLDOWN_SEC)
	_ck("cooldown_then_reopen", bool(s4.open_window().get("ok")),
		"tick(1.2) 冷却归零后可再次开窗")
	# 窗口内递减 / 恰好超时关闭
	_reset_signals()
	var s5: ParryService = _make(cfg)
	s5.open_window()
	var d5: Dictionary = s5.tick(0.1)
	_ck("within_window_decrement", bool(d5.get("ok")) and not bool(d5.get("timed_out")) \
		and s5.is_window_open() and is_equal_approx(s5.get_window_remaining(), 0.25),
		"tick(0.1) -> remaining=0.25，未超时")
	var d5b: Dictionary = s5.tick(0.25)
	_ck("exact_timeout_close", bool(d5b.get("ok")) and bool(d5b.get("timed_out")) \
		and not s5.is_window_open(),
		"累计恰好 window_sec -> 超时关窗")
	_ck("timeout_failed_signal", _sig_failed == 1 \
		and _last_fail_reason == ParryService.CLOSE_TIMEOUT \
		and _last_fail_penalty == EXPECT_FAIL_PENALTY,
		"parry_failed(timeout, 10) 恰 1 次")
	_ck("timeout_closed_signal", _sig_closed == 1 \
		and _last_close_reason == ParryService.CLOSE_TIMEOUT,
		"parry_window_closed(timeout) 恰 1 次")
	# 超长 delta 一次触发超时
	_reset_signals()
	var s6: ParryService = _make(cfg)
	s6.open_window()
	_ck("overlong_delta_timeout", bool(s6.tick(999.0).get("timed_out")) and not s6.is_window_open(),
		"tick(999) 一次即超时关窗")
	# Boss 招式落地失败 / 成功后 no-op
	_reset_signals()
	var s7: ParryService = _make(cfg)
	s7.open_window()
	var m7: Dictionary = s7.on_boss_move_landed()
	_ck("boss_move_landed_fail", bool(m7.get("ok")) and s7.get_fail_count() == 1 \
		and not s7.is_window_open() \
		and _last_fail_reason == ParryService.CLOSE_MOVE_LANDED,
		"招式落地未弹反 -> 失败关窗 + parry_failed(move_landed)")
	_reset_signals()
	var s8: ParryService = _make(cfg)
	s8.open_window()
	s8.try_parry()
	var m8: Dictionary = s8.on_boss_move_landed()
	_ck("boss_move_landed_noop_after_success", bool(m8.get("ok")) and s8.get_fail_count() == 0,
		"成功后招式落地 -> 幂等 no-op（不重复惩罚）")
	# Boss 死亡不再开窗 / 幂等
	_reset_signals()
	var s9: ParryService = _make(cfg)
	var b9: Dictionary = s9.on_boss_defeated()
	_ck("boss_defeated_flag", bool(b9.get("ok")) and s9.is_boss_defeated(),
		"on_boss_defeated -> boss_defeated=true")
	_ck("boss_defeated_no_window", not bool(s9.open_window().get("ok")) \
		and str(s9.open_window().get("reason")) == ParryService.REASON_BOSS_DEFEATED,
		"Boss 死亡后 open_window -> boss_defeated 拒绝（不再开窗）")
	_ck("boss_defeated_no_parry", not bool(s9.try_parry().get("ok")) \
		and str(s9.try_parry().get("reason")) == ParryService.REASON_BOSS_DEFEATED,
		"Boss 死亡后 try_parry -> boss_defeated 拒绝")
	_ck("boss_defeated_idempotent", not bool(s9.on_boss_defeated().get("ok")),
		"重复 on_boss_defeated -> 幂等拒绝")
	# reset 清状态
	var s10: ParryService = _make(cfg)
	s10.open_window()
	s10.try_parry()
	s10.on_boss_defeated()
	s10.reset()
	_ck("reset_clears_all", not s10.is_window_open() and not s10.is_boss_defeated() \
		and s10.get_success_count() == 0 and is_equal_approx(s10.get_cooldown_remaining(), 0.0),
		"reset() -> 关窗 / 清死亡 / 清计数 / 清冷却")


## D) 异常：tick 异常输入 / config=null / set_config(null) / 非法表 / 异常后正常流程
func _test_abnormal(cfg: ParryConfig) -> void:
	var s1: ParryService = _make(cfg)
	s1.open_window()
	_ck("invalid_tick_null", not bool(s1.tick(null).get("ok")) \
		and str(s1.tick(null).get("reason")) == ParryService.REASON_INVALID_DELTA,
		"tick(null) -> invalid_delta 拒绝")
	_ck("invalid_tick_negative", not bool(s1.tick(-1.0).get("ok")),
		"tick(-1) -> invalid_delta 拒绝")
	_ck("invalid_tick_string", not bool(s1.tick("x").get("ok")),
		"tick(字符串) -> invalid_delta 拒绝")
	_ck("invalid_tick_nan", not bool(s1.tick(NAN).get("ok")),
		"tick(NaN) -> invalid_delta 拒绝")
	_ck("invalid_tick_inf", not bool(s1.tick(INF).get("ok")),
		"tick(Inf) -> invalid_delta 拒绝")
	_ck("invalid_tick_state_unchanged", s1.is_window_open() \
		and is_equal_approx(s1.get_window_remaining(), EXPECT_WINDOW_SEC),
		"异常 delta 拒绝后窗口状态未被污染")
	# config=null 降级
	var s2: ParryService = ParryService.new(null)
	_ck("no_config_open_reject", not bool(s2.open_window().get("ok")) \
		and str(s2.open_window().get("reason")) == ParryService.REASON_NO_CONFIG,
		"config=null -> open_window 拒绝 REASON_NO_CONFIG（不崩）")
	_ck("no_config_parry_reject", not bool(s2.try_parry().get("ok")) \
		and str(s2.try_parry().get("reason")) == ParryService.REASON_NO_CONFIG,
		"config=null -> try_parry 拒绝 REASON_NO_CONFIG（不崩）")
	var s3: ParryService = _make(cfg)
	s3.set_config(null)
	_ck("set_config_null_degrade", not bool(s3.open_window().get("ok")),
		"set_config(null) -> 降级拒绝（不崩）")
	# 非法表（window_sec<=0 / NaN）
	var bad1: ParryConfig = ParryConfig.new()
	bad1.window_sec = -1.0
	_ck("invalid_table_negative_window", not bad1.is_valid(),
		"window_sec=-1 -> ParryConfig.is_valid()=false")
	var bad2: ParryConfig = ParryConfig.new()
	bad2.window_sec = NAN
	_ck("invalid_table_nan_window", not bad2.is_valid(),
		"window_sec=NaN -> ParryConfig.is_valid()=false")
	var sbad: ParryService = ParryService.new(bad1)
	_ck("invalid_table_service_degrade", not bool(sbad.open_window().get("ok")) \
		and str(sbad.open_window().get("reason")) == ParryService.REASON_NO_CONFIG,
		"非法表注入服务 -> REASON_NO_CONFIG 降级（不崩）")
	# 异常拒绝后正常流程仍成立
	_reset_signals()
	var s4: ParryService = _make(cfg)
	s4.tick(null)
	s4.tick(NAN)
	s4.try_parry()
	s4.open_window()
	var ok4: Dictionary = s4.try_parry()
	_ck("invalid_then_normal_ok", bool(ok4.get("ok")) \
		and int(ok4.get("points_bonus")) == EXPECT_POINTS_BONUS \
		and s4.get_success_count() == 1,
		"异常输入拒绝后正常开窗/弹反仍得 points_bonus=50（状态未被污染）")


## E) A48① 生产订阅者静态存在性证据（新信号生产运行时订阅者，不只在验证脚本里）
func _test_production_subscriber() -> void:
	var abs_path: String = ProjectSettings.globalize_path(DIRECTOR_PATH)
	var src: String = FileAccess.get_file_as_string(abs_path)
	if src.is_empty():
		src = FileAccess.get_file_as_string(DIRECTOR_PATH)
	_ck("production_subscriber_in_source", src.contains("_bind_parry_signals") \
		and src.contains("get_parry_service") and src.contains("parry_succeeded") \
		and src.contains("parry_window_opened"),
		"wave_trial_director.gd 生产源码含 4 信号 connect + get_parry_service()（A48①/A54）")


func _finish() -> void:
	print("[V120-PR] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V120-PR] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V120-PR] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V120-PR] === SELFTEST END ===")
	quit(0 if all_ok else 1)
