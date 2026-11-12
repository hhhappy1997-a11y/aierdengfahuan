extends SceneTree

## ===========================================================================
## R37 / v0.14.0 · 元素瓶「规则表 + 纯逻辑 + 信号」自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_flask_v140.gd
## 覆盖（任务单 ①⑤）：正常 / 边界 / 异常三类输入 ——
##   正常：读表 4 字段 [PLACEHOLDER]、is_valid、3 信号、use_flask 成功与 payload、
##         瓶数扣减、HP 回复、get_snapshot；
##   边界：瓶尽拒绝不扣、满血拒绝不扣、HP 不超过上限、赐福休息补满、
##         rest_refill=false 保持瓶数（REST_KEEP）、重复按键幂等、
##         瓶数只减不增除休息 / 非负 / 不超上限、reset；
##   异常：use_flask(null / 负数 / 字符串 / 数组 / NaN / Inf / max_hp<=0 /
##         current_hp>max_hp)、config=null、set_config(null)、非法表
##         （flask_max<=0 / 非整数 / heal<=0 / NaN / 非法 policy）、异常后正常流程仍成立；
##   A48① 生产订阅者静态证据（新信号生产运行时订阅者，不只在验证脚本里）。
## 输出逐条 PASS=true/false + SUMMARY + OVERALL=PASS/FAIL + RESULT=ALL_MATCH；失败 quit(1)。
## --script 模式纪律：不 add_child、不取 /root/... 绝对路径、不用 get_tree()；
##   用 Engine.get_main_loop() as SceneTree 取 root 做只读断言；读表 CACHE_MODE_IGNORE；
##   不写 user:// 存档、不碰渲染；纯逻辑不读真实时钟（无 tick）。
## 期望值来自 flask_rules.tres 首版 [PLACEHOLDER]。调参只改表，同步本脚本 EXPECT_*。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const CONFIG_PATH: String = "res://data/rpg/flask_rules.tres"
const DIRECTOR_PATH: String = "res://scripts/combat/wave_trial_director.gd"

## [PLACEHOLDER] R37 首版期望（校验基准，不写进数据表；待人工试玩校准）。
const EXPECT_FLASK_MAX: int = 3
const EXPECT_HEAL_AMOUNT: float = 50.0
const EXPECT_REST_REFILL: bool = true
const EXPECT_POLICY: String = "reject"

var _pass: int = 0
var _fail: int = 0

## 信号计数 / payload（connect 后统计，每组开头 _reset_signals() 清零）。
var _sig_used: int = 0
var _sig_rejected: int = 0
var _sig_restored: int = 0
var _last_used_payload: Array = []
var _last_reject_payload: Array = []
var _last_restored_payload: Array = []


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V140-FL] %s PASS=%s | %s" % [tag, str(ok), detail])


func _on_used(flask_before: int, flask_after: int, hp_before: float,
		hp_after: float, healed: float) -> void:
	_sig_used += 1
	_last_used_payload = [flask_before, flask_after, hp_before, hp_after, healed]


func _on_rejected(reason: String, flask_remaining: int) -> void:
	_sig_rejected += 1
	_last_reject_payload = [reason, flask_remaining]


func _on_restored(flask_before: int, flask_after: int, policy: String) -> void:
	_sig_restored += 1
	_last_restored_payload = [flask_before, flask_after, policy]


func _reset_signals() -> void:
	_sig_used = 0
	_sig_rejected = 0
	_sig_restored = 0
	_last_used_payload = []
	_last_reject_payload = []
	_last_restored_payload = []


## 构造并 connect 3 个公开信号（Object 级，不经场景树；验证脚本内订阅仅用于断言 payload）。
func _make(cfg: FlaskConfig) -> FlaskService:
	var s: FlaskService = FlaskService.new(cfg)
	s.connect("flask_used", Callable(self, "_on_used"))
	s.connect("flask_rejected", Callable(self, "_on_rejected"))
	s.connect("flask_restored", Callable(self, "_on_restored"))
	return s


func _initialize() -> void:
	print("[V140-FL] === SELFTEST START ===")
	var ml: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = ml as SceneTree
	var root_node: Node = tree.root if tree != null else null
	_ck("scene_tree_root_via_main_loop", tree != null and root_node != null,
		"Engine.get_main_loop() as SceneTree -> root，不用 get_tree()/绝对路径")
	var cfg: FlaskConfig = ResourceLoader.load(
		CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FlaskConfig
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


## A) 规则表 4 字段 [PLACEHOLDER] + 合法性 + 3 信号 + 降级基线 != 设计值
func _test_ruleset(cfg: FlaskConfig) -> void:
	_ck("ruleset_valid", cfg.is_valid(), "FlaskConfig.is_valid()=true")
	_ck("flask_max_ph", cfg.get_flask_max() == EXPECT_FLASK_MAX,
		"got=%d expect=%d [PLACEHOLDER]" % [cfg.get_flask_max(), EXPECT_FLASK_MAX])
	_ck("heal_amount_ph", is_equal_approx(cfg.get_heal_amount(), EXPECT_HEAL_AMOUNT),
		"got=%.1f expect=%.1f [PLACEHOLDER]" % [cfg.get_heal_amount(), EXPECT_HEAL_AMOUNT])
	_ck("rest_refill_ph", cfg.get_rest_refill() == EXPECT_REST_REFILL,
		"got=%s expect=%s [PLACEHOLDER]" % [str(cfg.get_rest_refill()), str(EXPECT_REST_REFILL)])
	_ck("invalid_input_policy_ph", cfg.get_invalid_input_policy() == EXPECT_POLICY,
		"got=%s expect=%s [PLACEHOLDER]" % [cfg.get_invalid_input_policy(), EXPECT_POLICY])
	_ck("default_is_not_design_flask_max", FlaskConfig.DEFAULT_FLASK_MAX != cfg.get_flask_max(),
		"DEFAULT_FLASK_MAX=%d != 表值 %d（调参唯一入口在 .tres）" % [
			FlaskConfig.DEFAULT_FLASK_MAX, cfg.get_flask_max()])
	_ck("default_is_not_design_heal", not is_equal_approx(FlaskConfig.DEFAULT_HEAL_AMOUNT, cfg.get_heal_amount()),
		"DEFAULT_HEAL_AMOUNT=%.1f != 表值 %.1f（调参唯一入口在 .tres）" % [
			FlaskConfig.DEFAULT_HEAL_AMOUNT, cfg.get_heal_amount()])
	_ck("signal_used_exists", _has_signal("flask_used"),
		"signal flask_used(flask_before, flask_after, hp_before, hp_after, healed)")
	_ck("signal_rejected_exists", _has_signal("flask_rejected"),
		"signal flask_rejected(reason, flask_remaining)")
	_ck("signal_restored_exists", _has_signal("flask_restored"),
		"signal flask_restored(flask_before, flask_after, policy)")


func _has_signal(sig: String) -> bool:
	var s: FlaskService = FlaskService.new(null)
	for d: Dictionary in s.get_signal_list():
		if String(d.get("name", "")) == sig:
			return true
	return false


## B) 正常：初始满、使用成功、payload、瓶数扣减、HP 回复、get_snapshot
func _test_normal(cfg: FlaskConfig) -> void:
	_reset_signals()
	var s: FlaskService = _make(cfg)
	_ck("initial_flask_full", s.get_flasks() == EXPECT_FLASK_MAX \
		and s.get_flask_max() == EXPECT_FLASK_MAX,
		"初始瓶数=%d / 上限=%d [PLACEHOLDER]" % [s.get_flasks(), s.get_flask_max()])
	_ck("invalid_input_policy_readable", s.get_invalid_input_policy() == EXPECT_POLICY \
		and s.is_config_valid(), "policy=reject / config 合法")
	var r: Dictionary = s.use_flask(50.0, 100.0)
	_ck("use_flask_ok", bool(r.get("ok")) and str(r.get("reason")) == "ok",
		"use_flask(50,100) -> 成功")
	_ck("use_flask_payload", int(r.get("flask_before")) == 3 \
		and int(r.get("flask_after")) == 2 \
		and is_equal_approx(float(r.get("hp_before")), 50.0) \
		and is_equal_approx(float(r.get("hp_after")), 100.0) \
		and is_equal_approx(float(r.get("healed")), 50.0),
		"payload=(3->2, 50->100, healed=50) [PLACEHOLDER]")
	_ck("signal_used_once", _sig_used == 1 and _last_used_payload.size() == 5,
		"flask_used 恰 1 次，payload 5 项")
	_ck("flask_decremented_by_one", s.get_flasks() == 2 and s.get_use_count() == 1,
		"瓶数 3->2 / use_count=1（只扣 1 瓶）")
	var snap: Dictionary = s.get_snapshot()
	_ck("snapshot_keys", snap.has("flasks") and snap.has("flask_max") \
		and snap.has("heal_amount") and snap.has("rest_refill") \
		and snap.has("use_count") and snap.has("config_present"),
		"get_snapshot() 全状态键可用")


## C) 边界：满血/瓶尽拒绝不扣、HP 不超上限、赐福休息补满、REST_KEEP、幂等、单调、reset
func _test_boundary(cfg: FlaskConfig) -> void:
	# HP 不超过上限：80 -> 100（healed 封顶 20，不超 max_hp）
	_reset_signals()
	var s: FlaskService = _make(cfg)
	var r_cap: Dictionary = s.use_flask(80.0, 100.0)
	_ck("hp_not_exceed_max", bool(r_cap.get("ok")) \
		and is_equal_approx(float(r_cap.get("hp_after")), 100.0) \
		and is_equal_approx(float(r_cap.get("healed")), 20.0),
		"use_flask(80,100) -> hp_after=100 / healed=20（封顶不超上限）")

	# 满血拒绝不扣
	_reset_signals()
	var s2: FlaskService = _make(cfg)
	var r_full: Dictionary = s2.use_flask(100.0, 100.0)
	_ck("full_hp_reject", not bool(r_full.get("ok")) \
		and str(r_full.get("reason")) == "full_hp",
		"满血 use_flask(100,100) -> full_hp 拒绝")
	_ck("full_hp_no_deduct", s2.get_flasks() == EXPECT_FLASK_MAX \
		and int(r_full.get("flask_after")) == EXPECT_FLASK_MAX \
		and s2.get_use_count() == 0,
		"满血拒绝且不扣瓶 / 不增 use_count")
	_ck("signal_rejected_full_hp", _sig_rejected == 1 \
		and str(_last_reject_payload[0]) == "full_hp",
		"flask_rejected(full_hp) 恰 1 次")

	# 瓶尽拒绝不扣：连续 3 次不同签名用光 -> 第 4 次 no_flask
	_reset_signals()
	var s3: FlaskService = _make(cfg)
	var u1: Dictionary = s3.use_flask(50.0, 100.0)   # 3->2
	var u2: Dictionary = s3.use_flask(40.0, 100.0)   # 2->1（不同签名，非重复按键）
	var u3: Dictionary = s3.use_flask(30.0, 100.0)   # 1->0
	_ck("three_uses_exhaust", bool(u1.get("ok")) and bool(u2.get("ok")) and bool(u3.get("ok")) \
		and s3.get_flasks() == 0,
		"连续 3 次不同签名使用成功 -> 瓶数 0")
	var u4: Dictionary = s3.use_flask(20.0, 100.0)
	_ck("no_flask_reject", not bool(u4.get("ok")) \
		and str(u4.get("reason")) == "no_flask" and int(u4.get("flask_after")) == 0,
		"瓶尽 use_flask -> no_flask 拒绝且不扣（瓶数恒 0）")
	_ck("no_flask_no_deduct", s3.get_flasks() == 0 and s3.get_use_count() == 3,
		"瓶尽拒绝不扣 / use_count 恒 3")

	# 赐福休息补满 + policy=rest_refill + flask_restored 信号
	_reset_signals()
	var rest: Dictionary = s3.on_grace_rest()
	_ck("grace_rest_refill", bool(rest.get("ok")) \
		and int(rest.get("flask_after")) == EXPECT_FLASK_MAX \
		and str(rest.get("policy")) == "rest_refill" \
		and s3.get_flasks() == EXPECT_FLASK_MAX,
		"赐福休息补满 0->3 / policy=rest_refill [PLACEHOLDER]")
	_ck("signal_restored_once", _sig_restored == 1 \
		and str(_last_restored_payload[2]) == "rest_refill",
		"flask_restored(0,3,rest_refill) 恰 1 次")

	# rest_refill=false 对照档：REST_KEEP（保持当前瓶数，不补）
	var cfg_keep: FlaskConfig = FlaskConfig.new()
	cfg_keep.flask_max = cfg.get_flask_max()
	cfg_keep.heal_amount = cfg.get_heal_amount()
	cfg_keep.rest_refill = false
	cfg_keep.invalid_input_policy = cfg.get_invalid_input_policy()
	var s4: FlaskService = _make(cfg_keep)
	s4.use_flask(50.0, 100.0)   # 3->2
	var keep: Dictionary = s4.on_grace_rest()
	_ck("rest_keep_policy", bool(keep.get("ok")) \
		and str(keep.get("policy")) == "rest_keep" \
		and s4.get_flasks() == 2,
		"rest_refill=false -> REST_KEEP，瓶数保持 2（对照档，不改代码）")

	# 重复按键幂等：相邻同签名只挡一次，不二次扣瓶 / 不二次回复
	_reset_signals()
	var s5: FlaskService = _make(cfg)
	var d1: Dictionary = s5.use_flask(50.0, 100.0)
	var d2: Dictionary = s5.use_flask(50.0, 100.0)
	_ck("duplicate_key_idempotent", bool(d1.get("ok")) \
		and not bool(d2.get("ok")) and str(d2.get("reason")) == "duplicate",
		"相邻同签名重复按键 -> duplicate 拒绝（幂等）")
	_ck("duplicate_no_double_deduct", s5.get_flasks() == 2 \
		and s5.get_use_count() == 1 and int(d2.get("flask_after")) == 2,
		"重复按键不二次扣瓶 / 不二次回复（瓶数恒 2、use_count 恒 1）")
	var d3: Dictionary = s5.use_flask(30.0, 100.0)   # HP 变化 -> 新签名，可再次使用
	_ck("different_hp_allowed", bool(d3.get("ok")) and s5.get_flasks() == 1,
		"外部更新 HP 后不同签名可再次使用（幂等只挡相邻同签名）")

	# 瓶数只减不增除休息 / 非负 / 不超上限
	_reset_signals()
	var s6: FlaskService = _make(cfg)
	var seq: Array[int] = [s6.get_flasks()]
	for hp: float in [50.0, 40.0, 30.0]:
		s6.use_flask(hp, 100.0)
		seq.append(s6.get_flasks())
	var mono: bool = true
	for i: int in range(1, seq.size()):
		if seq[i] > seq[i - 1] or seq[i] < 0 or seq[i] > EXPECT_FLASK_MAX:
			mono = false
	_ck("flask_monotonic_decrease", mono,
		"一局内瓶数序列 %s 只减不增 / 非负 / 不超上限" % str(seq))
	var rest6: Dictionary = s6.on_grace_rest()
	_ck("grace_rest_is_only_increase", int(rest6.get("flask_after")) == EXPECT_FLASK_MAX \
		and s6.get_flasks() > seq[seq.size() - 1],
		"赐福休息是唯一允许瓶数增加的出口（0->3）")

	# reset
	var s7: FlaskService = _make(cfg)
	s7.use_flask(50.0, 100.0)
	s7.on_grace_rest()
	s7.reset()
	_ck("reset_clears_all", s7.get_flasks() == EXPECT_FLASK_MAX \
		and s7.get_use_count() == 0 and s7.get_reject_count() == 0 \
		and s7.get_restore_count() == 0 and s7.get_last_result().is_empty(),
		"reset() -> 瓶回满 / 清三类计数 / 清最近结果")


## D) 异常：异常输入 / config=null / 非法表 / 异常后正常流程仍成立
func _test_abnormal(cfg: FlaskConfig) -> void:
	_reset_signals()
	var s: FlaskService = _make(cfg)
	var bad_inputs: Array = [
		[null, 100.0], [50.0, null], ["x", 100.0], [[1], 100.0],
		[NAN, 100.0], [INF, 100.0], [50.0, NAN], [50.0, INF],
		[-1.0, 100.0], [50.0, 0.0], [50.0, -10.0], [120.0, 100.0],
	]
	var all_rejected: bool = true
	for pair: Array in bad_inputs:
		var r: Dictionary = s.use_flask(pair[0], pair[1])
		if bool(r.get("ok")) or str(r.get("reason")) != "invalid_input":
			all_rejected = false
	_ck("invalid_input_all_rejected", all_rejected,
		"%d 类异常输入全部 invalid_input 拒绝（null/字符串/数组/NaN/Inf/负/超上限）" % bad_inputs.size())
	_ck("invalid_input_no_state_change", s.get_flasks() == EXPECT_FLASK_MAX \
		and s.get_use_count() == 0,
		"异常输入拒绝且不改瓶数 / 不增 use_count")
	var after: Dictionary = s.use_flask(50.0, 100.0)
	_ck("invalid_then_normal_ok", bool(after.get("ok")) \
		and is_equal_approx(float(after.get("hp_after")), 100.0),
		"异常输入拒绝后正常使用仍得 hp_after=100（状态未被污染）")

	# config=null / set_config(null)
	var s_null: FlaskService = _make(null)
	_ck("no_config_reject", not s_null.is_config_valid() \
		and str(s_null.use_flask(50.0, 100.0).get("reason")) == "no_config",
		"config=null -> use_flask 拒绝 REASON_NO_CONFIG（不崩）")
	_ck("no_config_rest_reject", not bool(s_null.on_grace_rest().get("ok")),
		"config=null -> on_grace_rest 拒绝（不崩）")
	s_null.set_config(cfg)
	_ck("set_config_recovers", s_null.is_config_valid() \
		and bool(s_null.use_flask(50.0, 100.0).get("ok")),
		"set_config(合法表) -> 恢复正常流程")
	s_null.set_config(null)
	_ck("set_config_null_reject", not s_null.is_config_valid() \
		and str(s_null.use_flask(50.0, 100.0).get("reason")) == "no_config",
		"set_config(null) -> 重新降级拒绝")

	# 非法表（6 类）
	_ck("invalid_table_flask_max_zero", not _bad_cfg("flask_max", 0).is_valid(),
		"flask_max=0 -> is_valid()=false")
	_ck("invalid_table_flask_max_negative", not _bad_cfg("flask_max", -1).is_valid(),
		"flask_max=-1 -> is_valid()=false")
	_ck("invalid_table_heal_zero", not _bad_cfg("heal_amount", 0.0).is_valid(),
		"heal_amount=0 -> is_valid()=false")
	_ck("invalid_table_heal_nan", not _bad_cfg("heal_amount", NAN).is_valid(),
		"heal_amount=NaN -> is_valid()=false")
	_ck("invalid_table_bad_policy", not _bad_cfg("invalid_input_policy", "clamp").is_valid(),
		"invalid_input_policy=clamp（非 reject）-> is_valid()=false")
	var bad: FlaskConfig = _bad_cfg("flask_max", 0)
	var s_bad: FlaskService = FlaskService.new(bad)
	_ck("invalid_table_service_reject", not s_bad.is_config_valid() \
		and str(s_bad.use_flask(50.0, 100.0).get("reason")) == "no_config",
		"非法表注入服务 -> 拒绝且不崩（降级）")


func _bad_cfg(key: String, value: Variant) -> FlaskConfig:
	var c: FlaskConfig = FlaskConfig.new()
	c.flask_max = EXPECT_FLASK_MAX
	c.heal_amount = EXPECT_HEAL_AMOUNT
	c.rest_refill = EXPECT_REST_REFILL
	c.invalid_input_policy = EXPECT_POLICY
	c.set(key, value)
	return c


## E) A48① 生产订阅者静态证据（wave_trial_director.gd 生产节点，非验证脚本）
func _test_production_subscriber() -> void:
	var abs_path: String = ProjectSettings.globalize_path(DIRECTOR_PATH)
	var src: String = FileAccess.get_file_as_string(abs_path)
	if src.is_empty():
		src = FileAccess.get_file_as_string(DIRECTOR_PATH)
	_ck("production_subscriber_in_source", src.contains("_bind_flask_signals") \
		and src.contains("get_flask_service") \
		and src.contains("flask_used") \
		and src.contains("_flask.on_grace_rest()") \
		and src.contains("use_flask("),
		"生产源码含 3 信号订阅者 + 唯一实例 getter + 赐福休息补满 + 驱动口（A48①/A54）")


func _finish() -> void:
	print("[V140-FL] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V140-FL] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V140-FL] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V140-FL] === SELFTEST END ===")
	quit(0 if all_ok else 1)
