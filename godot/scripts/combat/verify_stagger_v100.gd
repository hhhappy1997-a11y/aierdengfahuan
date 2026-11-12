extends SceneTree

## ===========================================================================
## R32 / v0.10.0 · Boss 韧性处决「规则表 + 结算纯逻辑 + 信号」自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_stagger_v100.gd
## 覆盖（任务单 ③）：正常 / 边界 / 异常三类输入 ——
##   正常：满韧性起始、命中累积削韧、归零开窗、窗口内处决给额外点数、关窗恢复韧性；
##   边界：0 韧性、满韧性、超窗口时长、恰好窗口时长、窗口内递减、连续命中不叠加、
##         同帧多次请求；
##   异常：null / 负数 / 0 / 字符串削韧、null / 负 delta、config=null、
##         重复处决、Boss 死亡后不再开窗。
## 信号订阅：connect 3 个公开 signal 到本 SceneTree 实例，计数 + payload 断言
##   （Object 级信号，RefCounted 直接 connect，不经场景树 / 不 add_child）。
## 输出逐条 PASS=true/false + SUMMARY + OVERALL=PASS/FAIL + RESULT=ALL_MATCH；失败 quit(1)。
## --script 模式纪律：不 add_child、不取 /root/... 绝对路径、不用 get_tree()；
##   用 Engine.get_main_loop() as SceneTree 取 root 做只读断言；读表 CACHE_MODE_IGNORE；
##   不写 user:// 存档、不碰渲染；时间由 tick(delta) 确定性驱动，不依赖真实引擎时钟。
## 期望值来自 stagger_rules.tres 首版 [PLACEHOLDER]（100.0 / 3.0 / 50 / 25.0）。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const CONFIG_PATH: String = "res://data/combat/stagger_rules.tres"

## [PLACEHOLDER] R32 首版期望（校验基准，不写进数据表；待人工试玩校准）。
const EXPECT_STAGGER_MAX: float = 100.0
const EXPECT_WINDOW_DURATION: float = 3.0
const EXPECT_EXECUTE_BONUS: int = 50
const EXPECT_REFERENCE_POISE: float = 25.0

var _pass: int = 0
var _fail: int = 0

## 信号计数 / payload（connect 后统计，每组开头 _reset_signals() 清零）。
var _sig_opened: int = 0
var _sig_closed: int = 0
var _sig_changed: int = 0
var _last_open_remaining: float = -1.0
var _last_open_bonus: int = -1
var _last_close_reason: String = ""


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V100-ST] %s PASS=%s | %s" % [tag, str(ok), detail])


func _on_opened(remaining: float, bonus: int) -> void:
	_sig_opened += 1
	_last_open_remaining = remaining
	_last_open_bonus = bonus


func _on_closed(reason: String) -> void:
	_sig_closed += 1
	_last_close_reason = reason


func _on_changed(current: float, maximum: float) -> void:
	_sig_changed += 1


func _reset_signals() -> void:
	_sig_opened = 0
	_sig_closed = 0
	_sig_changed = 0
	_last_open_remaining = -1.0
	_last_open_bonus = -1
	_last_close_reason = ""


## 构造并 connect 3 个公开信号（Object 级，不经场景树）。
func _make(cfg: StaggerConfig) -> StaggerService:
	var s: StaggerService = StaggerService.new(cfg)
	s.connect("stagger_value_changed", Callable(self, "_on_changed"))
	s.connect("execution_window_opened", Callable(self, "_on_opened"))
	s.connect("execution_window_closed", Callable(self, "_on_closed"))
	return s


func _initialize() -> void:
	print("[V100-ST] === SELFTEST START ===")
	# --script 模式纪律：用 Engine.get_main_loop() as SceneTree 取 root（只读断言），
	# 不用 get_tree()、不用 /root/... 绝对路径；本夹具纯内存，不 add_child。
	var ml: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = ml as SceneTree
	var root_node: Node = tree.root if tree != null else null
	_ck("scene_tree_root_via_main_loop", tree != null and root_node != null,
		"Engine.get_main_loop() as SceneTree -> root，不用 get_tree()/绝对路径")
	var cfg: StaggerConfig = ResourceLoader.load(
		CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as StaggerConfig
	_ck("table_load_cache_ignore", cfg != null, "path=%s" % CONFIG_PATH)
	if cfg == null:
		_finish()
		return
	_test_structure(cfg)          # 正常：表结构 / 首版数值 / 降级基线
	_test_public_api(cfg)         # 正常：公开方法与信号签名稳定
	_test_normal_flow(cfg)        # 正常：满韧性→削韧→开窗→处决→恢复
	_test_boundaries(cfg)         # 边界：0 韧性 / 满韧性 / 超时长 / 恰好时长 / 递减
	_test_invalid_inputs(cfg)     # 异常：null / 负 / 0 / 字符串 / config=null
	_test_no_stacking(cfg)        # 边界：连续命中不叠加异常
	_test_same_frame(cfg)         # 边界：同帧多次请求幂等
	_test_boss_defeated(cfg)      # 异常：Boss 死亡后不再开窗
	_finish()


## A) [正常] 表结构 / 4 个 [PLACEHOLDER] / is_valid / 代码不写死设计数值
func _test_structure(cfg: StaggerConfig) -> void:
	_ck("stagger_max_ph", is_equal_approx(cfg.stagger_max, EXPECT_STAGGER_MAX),
		"got=%s expect=%s [PLACEHOLDER]" % [str(cfg.stagger_max), str(EXPECT_STAGGER_MAX)])
	_ck("window_duration_ph", is_equal_approx(cfg.window_duration_sec, EXPECT_WINDOW_DURATION),
		"got=%s expect=%s [PLACEHOLDER]" % [str(cfg.window_duration_sec), str(EXPECT_WINDOW_DURATION)])
	_ck("execute_bonus_ph", cfg.execute_bonus_points == EXPECT_EXECUTE_BONUS,
		"got=%d expect=%d [PLACEHOLDER]" % [cfg.execute_bonus_points, EXPECT_EXECUTE_BONUS])
	_ck("reference_poise_ph", is_equal_approx(cfg.reference_poise_damage, EXPECT_REFERENCE_POISE),
		"got=%s expect=%s [PLACEHOLDER]" % [str(cfg.reference_poise_damage), str(EXPECT_REFERENCE_POISE)])
	_ck("ruleset_valid", cfg.is_valid(), "is_valid=true")
	# 降级基线 != 设计数值：证明代码里没有写死 [PLACEHOLDER] 设计数值（只改表不改代码）
	_ck("default_is_not_design_max", not is_equal_approx(StaggerConfig.DEFAULT_STAGGER_MAX, EXPECT_STAGGER_MAX),
		"DEFAULT_STAGGER_MAX=%s != 表值 100.0（降级基线，非设计数值）" % str(StaggerConfig.DEFAULT_STAGGER_MAX))
	_ck("default_is_not_design_window", not is_equal_approx(StaggerConfig.DEFAULT_WINDOW_DURATION_SEC, EXPECT_WINDOW_DURATION),
		"DEFAULT_WINDOW_DURATION_SEC=%s != 表值 3.0" % str(StaggerConfig.DEFAULT_WINDOW_DURATION_SEC))
	_ck("default_is_not_design_bonus", StaggerConfig.DEFAULT_EXECUTE_BONUS_POINTS != EXPECT_EXECUTE_BONUS,
		"DEFAULT_EXECUTE_BONUS_POINTS=%d != 表值 50" % StaggerConfig.DEFAULT_EXECUTE_BONUS_POINTS)


## B) [正常] 公开方法 / 信号签名稳定（供 Rank-1 接线，见 DONE-R32.md）
func _test_public_api(cfg: StaggerConfig) -> void:
	var s: StaggerService = StaggerService.new(cfg)
	_ck("signal_stagger_value_changed_exists", s.has_signal("stagger_value_changed"),
		"signal stagger_value_changed(current: float, maximum: float)")
	_ck("signal_execution_window_opened_exists", s.has_signal("execution_window_opened"),
		"signal execution_window_opened(remaining_sec: float, bonus_points: int)")
	_ck("signal_execution_window_closed_exists", s.has_signal("execution_window_closed"),
		"signal execution_window_closed(reason: String)")
	_ck("close_reason_constants", StaggerService.CLOSE_EXECUTED == "executed" \
		and StaggerService.CLOSE_TIMEOUT == "timeout" \
		and StaggerService.CLOSE_BOSS_DEFEATED == "boss_defeated",
		"CLOSE_EXECUTED / CLOSE_TIMEOUT / CLOSE_BOSS_DEFEATED 稳定")
	var snap: Dictionary = s.get_snapshot()
	for k: String in ["stagger", "stagger_max", "window_open", "window_remaining",
		"window_duration_sec", "execute_bonus_points", "boss_defeated", "total_execute_bonus"]:
		_ck("snapshot_has_%s" % k, snap.has(k), "get_snapshot() 含 %s" % k)
	_ck("public_read_methods", not s.is_window_open() and is_equal_approx(s.get_stagger(), EXPECT_STAGGER_MAX) \
		and is_equal_approx(s.get_max_stagger(), EXPECT_STAGGER_MAX) \
		and is_equal_approx(s.get_window_remaining(), 0.0) \
		and not s.is_boss_defeated() and s.get_total_execute_bonus() == 0,
		"is_window_open/get_stagger/get_max_stagger/get_window_remaining/is_boss_defeated/get_total_execute_bonus")


## C) [正常] 满韧性起始 → 4 次 25 削韧归零开窗 → 开窗信号 → 窗口内处决 → 关窗恢复满韧性
func _test_normal_flow(cfg: StaggerConfig) -> void:
	_reset_signals()
	var s: StaggerService = _make(cfg)
	_ck("flow_full_stagger_start", is_equal_approx(s.get_stagger(), EXPECT_STAGGER_MAX) and not s.is_window_open(),
		"起始满韧性=%s 未开窗" % str(s.get_stagger()))
	s.apply_hit(25.0)
	s.apply_hit(25.0)
	s.apply_hit(25.0)
	var r4: Dictionary = s.apply_hit(25.0)
	_ck("flow_zero_stagger_opens_window", bool(r4.get("ok")) and bool(r4.get("opened_now")) \
		and s.is_window_open() and is_equal_approx(s.get_stagger(), 0.0),
		"4×25 削韧归零开窗，stagger=0 [PLACEHOLDER]")
	_ck("flow_window_remaining", is_equal_approx(s.get_window_remaining(), EXPECT_WINDOW_DURATION),
		"窗口剩余=%s [PLACEHOLDER]" % str(s.get_window_remaining()))
	_ck("signal_opened_once", _sig_opened == 1, "execution_window_opened 恰好发 1 次")
	_ck("signal_opened_payload", is_equal_approx(_last_open_remaining, EXPECT_WINDOW_DURATION) \
		and _last_open_bonus == EXPECT_EXECUTE_BONUS,
		"payload remaining=%s bonus=%d" % [str(_last_open_remaining), _last_open_bonus])
	_ck("signal_changed_4", _sig_changed == 4, "stagger_value_changed 发 4 次（4 次命中）")
	var ex: Dictionary = s.try_execute()
	_ck("flow_execute_ok", bool(ex.get("ok")) and int(ex.get("bonus_points")) == EXPECT_EXECUTE_BONUS \
		and int(ex.get("total_execute_bonus")) == EXPECT_EXECUTE_BONUS,
		"处决成功 bonus=%d total=%d [PLACEHOLDER]" % [int(ex.get("bonus_points")), int(ex.get("total_execute_bonus"))])
	_ck("flow_window_closed_recovered", not s.is_window_open() \
		and is_equal_approx(s.get_stagger(), EXPECT_STAGGER_MAX),
		"关窗并恢复满韧性=%s" % str(s.get_stagger()))
	_ck("signal_closed_executed", _sig_closed == 1 \
		and _last_close_reason == StaggerService.CLOSE_EXECUTED,
		"execution_window_closed(reason=executed)")
	var ex2: Dictionary = s.try_execute()
	_ck("flow_execute_idempotent", not bool(ex2.get("ok")) \
		and str(ex2.get("reason")) == StaggerService.REASON_NO_WINDOW,
		"窗口关闭后重复处决 -> no_window 拒绝（不重复给点）")


## D) [边界] 0 韧性 / 满韧性 / 超窗口时长 / 恰好窗口时长 / 窗口内递减
func _test_boundaries(cfg: StaggerConfig) -> void:
	# 超窗口时长：一次打空开窗后 tick(999) 超时关窗并恢复满韧性
	_reset_signals()
	var s1: StaggerService = _make(cfg)
	s1.apply_hit(EXPECT_STAGGER_MAX)  # 一击削到 0 开窗
	_ck("bnd_zero_stagger_window_open", s1.is_window_open() and is_equal_approx(s1.get_stagger(), 0.0),
		"0 韧性时窗口开启、stagger 夹取到 0（不为负）")
	var t1: Dictionary = s1.tick(999.0)
	_ck("bnd_over_duration_timeout", bool(t1.get("ok")) and bool(t1.get("timed_out")) \
		and not s1.is_window_open() and is_equal_approx(s1.get_stagger(), EXPECT_STAGGER_MAX),
		"delta=999 > 3.0 -> 超时关窗 + 恢复满韧性")
	_ck("bnd_timeout_closed_signal", _sig_closed == 1 \
		and _last_close_reason == StaggerService.CLOSE_TIMEOUT,
		"execution_window_closed(reason=timeout)")
	# 恰好窗口时长：tick(3.0) 使 remaining=0 -> 超时
	_reset_signals()
	var s2: StaggerService = _make(cfg)
	s2.apply_hit(EXPECT_STAGGER_MAX)
	var t2: Dictionary = s2.tick(EXPECT_WINDOW_DURATION)
	_ck("bnd_exact_duration_timeout", bool(t2.get("timed_out")) and not s2.is_window_open(),
		"delta=3.0（恰好窗口时长）-> 超时关窗")
	# 窗口内递减：tick(1.0) -> remaining=2.0，不超时
	_reset_signals()
	var s3: StaggerService = _make(cfg)
	s3.apply_hit(EXPECT_STAGGER_MAX)
	var t3: Dictionary = s3.tick(1.0)
	_ck("bnd_within_duration_decrement", bool(t3.get("ok")) and not bool(t3.get("timed_out")) \
		and s3.is_window_open() and is_equal_approx(s3.get_window_remaining(), 2.0),
		"delta=1.0 -> remaining=2.0，窗口仍开")
	# 满韧性：reset 后满韧性、未开窗
	var s4: StaggerService = _make(cfg)
	s4.apply_hit(10.0)
	s4.reset()
	_ck("bnd_reset_full_stagger", is_equal_approx(s4.get_stagger(), EXPECT_STAGGER_MAX) \
		and not s4.is_window_open() and not s4.is_boss_defeated(),
		"reset -> 满韧性、关窗、清死亡标志")


## E) [异常] null / 负 / 0 / 字符串削韧；null / 负 delta；config=null
func _test_invalid_inputs(cfg: StaggerConfig) -> void:
	var s: StaggerService = _make(cfg)
	var r_null: Dictionary = s.apply_hit(null)
	_ck("invalid_hit_null_rejected", not bool(r_null.get("ok")) \
		and str(r_null.get("reason")) == StaggerService.REASON_INVALID_HIT, "apply_hit(null) 拒绝")
	_ck("invalid_hit_negative_rejected", not bool(s.apply_hit(-5.0).get("ok")), "apply_hit(-5) 拒绝")
	_ck("invalid_hit_zero_rejected", not bool(s.apply_hit(0).get("ok")), "apply_hit(0) 拒绝")
	_ck("invalid_hit_string_rejected", not bool(s.apply_hit("x").get("ok")), "apply_hit(字符串) 拒绝")
	_ck("invalid_hit_no_state_change", is_equal_approx(s.get_stagger(), EXPECT_STAGGER_MAX) and not s.is_window_open(),
		"异常输入削韧不改状态（仍满韧性、未开窗）")
	var t_null: Dictionary = s.tick(null)
	_ck("invalid_delta_null_rejected", not bool(t_null.get("ok")) \
		and str(t_null.get("reason")) == StaggerService.REASON_INVALID_DELTA, "tick(null) 拒绝")
	_ck("invalid_delta_negative_rejected", not bool(s.tick(-1.0).get("ok")), "tick(-1) 拒绝")
	var s_null: StaggerService = StaggerService.new(null)
	var r_nocfg: Dictionary = s_null.apply_hit(25.0)
	_ck("invalid_no_config_rejected", not bool(r_nocfg.get("ok")) \
		and str(r_nocfg.get("reason")) == StaggerService.REASON_NO_CONFIG, "config=null 命中拒绝")
	# tick 无窗口时 no-op（不崩、不超时）
	var s3: StaggerService = _make(cfg)
	var t3: Dictionary = s3.tick(0.5)
	_ck("tick_no_window_noop", bool(t3.get("ok")) and not bool(t3.get("timed_out")), "无窗口 tick no-op")
	# 异常后正常流程仍成立
	var s4: StaggerService = _make(cfg)
	s4.apply_hit(null)
	var ok_hit: Dictionary = s4.apply_hit(EXPECT_STAGGER_MAX)
	_ck("invalid_then_normal_ok", bool(ok_hit.get("ok")) and s4.is_window_open(), "异常后正常命中仍开窗")


## F) [边界] 连续命中不叠加异常：开窗后再命中幂等、不重复开窗、韧性不变
func _test_no_stacking(cfg: StaggerConfig) -> void:
	_reset_signals()
	var s: StaggerService = _make(cfg)
	var first: Dictionary = s.apply_hit(EXPECT_STAGGER_MAX)  # 一击开窗
	_ck("stack_first_opens", bool(first.get("opened_now")) and s.is_window_open(), "首次命中开窗")
	var h2: Dictionary = s.apply_hit(50.0)  # 窗口期内命中
	_ck("stack_window_hit_idempotent", not bool(h2.get("ok")) \
		and str(h2.get("reason")) == StaggerService.REASON_WINDOW_OPEN,
		"窗口期内命中 -> window_open_idempotent 拒绝")
	_ck("stack_no_double_open", _sig_opened == 1, "execution_window_opened 仍只 1 次（不重复开窗）")
	_ck("stack_stagger_unchanged", is_equal_approx(s.get_stagger(), 0.0), "韧性不变（仍 0，不叠加异常）")
	_ck("stack_changed_once", _sig_changed == 1, "stagger_value_changed 仍只 1 次（幂等命中不 emit）")


## G) [边界] 同帧多次请求：多次命中 / 开窗后幂等 / 多次处决只第一次给点 / 多次 tick no-op
func _test_same_frame(cfg: StaggerConfig) -> void:
	_reset_signals()
	var s: StaggerService = _make(cfg)
	# 同帧 5 次 20 削韧 = 100 -> 第 5 次开窗
	for i: int in range(5):
		s.apply_hit(20.0)
	_ck("same_frame_opens_once", s.is_window_open() and _sig_opened == 1,
		"同帧 5 次命中累计削韧，开窗 1 次")
	# 同帧窗口开启后再 2 次命中 -> 幂等拒绝，不重复开窗
	s.apply_hit(10.0)
	s.apply_hit(10.0)
	_ck("same_frame_window_hits_idempotent", _sig_opened == 1 and is_equal_approx(s.get_stagger(), 0.0),
		"开窗后同帧多次命中不叠加")
	# 同帧多次处决：只第一次给点
	var e1: Dictionary = s.try_execute()
	var e2: Dictionary = s.try_execute()
	_ck("same_frame_execute_once", bool(e1.get("ok")) and not bool(e2.get("ok")) \
		and s.get_total_execute_bonus() == EXPECT_EXECUTE_BONUS,
		"同帧 2 次处决只第 1 次给 %d 点（不刷点）" % EXPECT_EXECUTE_BONUS)
	# 同帧多次 tick（无窗口）-> no-op
	var k1: Dictionary = s.tick(0.016)
	var k2: Dictionary = s.tick(0.016)
	_ck("same_frame_tick_noop", bool(k1.get("ok")) and bool(k2.get("ok")) \
		and not bool(k1.get("timed_out")) and not bool(k2.get("timed_out")),
		"同帧多次 tick 无窗口 no-op")


## H) [异常] Boss 死亡后不再开窗 / 死亡时若窗口开着立即关闭并恢复韧性
func _test_boss_defeated(cfg: StaggerConfig) -> void:
	var s1: StaggerService = _make(cfg)
	s1.on_boss_defeated()
	_ck("boss_defeated_flag", s1.is_boss_defeated(), "on_boss_defeated -> is_boss_defeated=true")
	var r: Dictionary = s1.apply_hit(EXPECT_STAGGER_MAX)
	_ck("boss_defeated_no_window", not bool(r.get("ok")) \
		and str(r.get("reason")) == StaggerService.REASON_BOSS_DEFEATED \
		and not s1.is_window_open(),
		"Boss 死亡后命中 -> 拒绝且不再开窗")
	_ck("boss_defeated_execute_rejected", not bool(s1.try_execute().get("ok")), "Boss 死亡后处决拒绝")
	# 死亡时窗口开着 -> 立即关窗（reason=boss_defeated）+ 恢复韧性
	_reset_signals()
	var s2: StaggerService = _make(cfg)
	s2.apply_hit(EXPECT_STAGGER_MAX)  # 开窗
	s2.on_boss_defeated()
	_ck("boss_defeated_closes_open_window", not s2.is_window_open() \
		and is_equal_approx(s2.get_stagger(), EXPECT_STAGGER_MAX) \
		and _sig_closed == 1 and _last_close_reason == StaggerService.CLOSE_BOSS_DEFEATED,
		"死亡时开窗状态被关闭 + 恢复满韧性 + closed(boss_defeated)")


func _finish() -> void:
	print("[V100-ST] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V100-ST] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V100-ST] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V100-ST] === SELFTEST END ===")
	quit(0 if all_ok else 1)
