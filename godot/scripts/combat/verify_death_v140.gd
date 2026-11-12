extends SceneTree

## ===========================================================================
## R37 / v0.14.0 · 死亡轮回「规则表 + 纯逻辑 + 信号」自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_death_v140.gd
## 覆盖（任务单 ②⑤）：正常 / 边界 / 异常三类输入 ——
##   正常：读表 3 字段 [PLACEHOLDER]、is_valid、4 信号、HP 归零 -> 死亡态 ->
##         记录掉落点数（0.5 比例）、death_occurred payload、独立 dropped/reclaimed flag；
##   边界：重复死亡不二次掉落、已有未回收掉落不二次掉落、drop_cap 封顶、
##         赐福重生、一次性回收（回收只生效一次）、回收后新周期、死亡期间拒绝行动、
##         绝不回退 grace.trial.points / 绝不写 removals（独立只读快照 + flag）、reset；
##   异常：on_death(null / 负数 / 字符串 / 数组 / NaN / Inf)、request_action 异常 id、
##         config=null、set_config(null)、非法表（比例>1 / <0 / NaN / cap<0 / 非法 policy）、
##         异常后正常流程仍成立；
##   A48① 生产订阅者静态证据（新信号生产运行时订阅者，不只在验证脚本里）。
## 输出逐条 PASS=true/false + SUMMARY + OVERALL=PASS/FAIL + RESULT=ALL_MATCH；失败 quit(1)。
## --script 模式纪律：不 add_child、不取 /root/... 绝对路径、不用 get_tree()；
##   用 Engine.get_main_loop() as SceneTree 取 root 做只读断言；读表 CACHE_MODE_IGNORE；
##   不写 user:// 存档、不碰渲染；纯逻辑不读真实时钟。
## 期望值来自 death_rules.tres 首版 [PLACEHOLDER]。调参只改表，同步本脚本 EXPECT_*。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const CONFIG_PATH: String = "res://data/rpg/death_rules.tres"
const DIRECTOR_PATH: String = "res://scripts/combat/wave_trial_director.gd"

## [PLACEHOLDER] R37 首版期望（校验基准，不写进数据表；待人工试玩校准）。
const EXPECT_DROP_RATIO: float = 0.5
const EXPECT_DROP_CAP: int = 500
const EXPECT_POLICY: String = "reject"

var _pass: int = 0
var _fail: int = 0

## 信号计数 / payload（connect 后统计，每组开头 _reset_signals() 清零）。
var _sig_death: int = 0
var _sig_respawn: int = 0
var _sig_reclaimed: int = 0
var _sig_rejected: int = 0
var _last_death_payload: Array = []
var _last_respawn_payload: Array = []
var _last_reclaimed_payload: Array = []
var _last_reject_payload: Array = []


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V140-DT] %s PASS=%s | %s" % [tag, str(ok), detail])


func _on_death(dropped_points: int, grace_points_snapshot: int) -> void:
	_sig_death += 1
	_last_death_payload = [dropped_points, grace_points_snapshot]


func _on_respawn(pending_dropped_points: int) -> void:
	_sig_respawn += 1
	_last_respawn_payload = [pending_dropped_points]


func _on_reclaimed(points: int, grace_points_snapshot: int) -> void:
	_sig_reclaimed += 1
	_last_reclaimed_payload = [points, grace_points_snapshot]


func _on_rejected(reason: String, action_id: String) -> void:
	_sig_rejected += 1
	_last_reject_payload = [reason, action_id]


func _reset_signals() -> void:
	_sig_death = 0
	_sig_respawn = 0
	_sig_reclaimed = 0
	_sig_rejected = 0
	_last_death_payload = []
	_last_respawn_payload = []
	_last_reclaimed_payload = []
	_last_reject_payload = []


## 构造并 connect 4 个公开信号（Object 级，不经场景树；验证脚本内订阅仅用于断言 payload）。
func _make(cfg: DeathConfig) -> DeathService:
	var s: DeathService = DeathService.new(cfg)
	s.connect("death_occurred", Callable(self, "_on_death"))
	s.connect("respawn_performed", Callable(self, "_on_respawn"))
	s.connect("points_reclaimed", Callable(self, "_on_reclaimed"))
	s.connect("action_rejected", Callable(self, "_on_rejected"))
	return s


func _initialize() -> void:
	print("[V140-DT] === SELFTEST START ===")
	var ml: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = ml as SceneTree
	var root_node: Node = tree.root if tree != null else null
	_ck("scene_tree_root_via_main_loop", tree != null and root_node != null,
		"Engine.get_main_loop() as SceneTree -> root，不用 get_tree()/绝对路径")
	var cfg: DeathConfig = ResourceLoader.load(
		CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as DeathConfig
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


## A) 规则表 3 字段 [PLACEHOLDER] + 合法性 + 4 信号 + 降级基线 != 设计值
func _test_ruleset(cfg: DeathConfig) -> void:
	_ck("ruleset_valid", cfg.is_valid(), "DeathConfig.is_valid()=true")
	_ck("drop_ratio_ph", is_equal_approx(cfg.get_drop_ratio(), EXPECT_DROP_RATIO),
		"got=%.2f expect=%.2f [PLACEHOLDER]" % [cfg.get_drop_ratio(), EXPECT_DROP_RATIO])
	_ck("drop_cap_ph", cfg.get_drop_cap() == EXPECT_DROP_CAP,
		"got=%d expect=%d [PLACEHOLDER]" % [cfg.get_drop_cap(), EXPECT_DROP_CAP])
	_ck("invalid_input_policy_ph", cfg.get_invalid_input_policy() == EXPECT_POLICY,
		"got=%s expect=%s [PLACEHOLDER]" % [cfg.get_invalid_input_policy(), EXPECT_POLICY])
	_ck("default_is_not_design_ratio", not is_equal_approx(DeathConfig.DEFAULT_DROP_RATIO, cfg.get_drop_ratio()),
		"DEFAULT_DROP_RATIO=%.2f != 表值 %.2f（调参唯一入口在 .tres）" % [
			DeathConfig.DEFAULT_DROP_RATIO, cfg.get_drop_ratio()])
	_ck("default_is_not_design_cap", DeathConfig.DEFAULT_DROP_CAP != cfg.get_drop_cap(),
		"DEFAULT_DROP_CAP=%d != 表值 %d（调参唯一入口在 .tres）" % [
			DeathConfig.DEFAULT_DROP_CAP, cfg.get_drop_cap()])
	_ck("signal_death_exists", _has_signal("death_occurred"),
		"signal death_occurred(dropped_points, grace_points_snapshot)")
	_ck("signal_respawn_exists", _has_signal("respawn_performed"),
		"signal respawn_performed(pending_dropped_points)")
	_ck("signal_reclaimed_exists", _has_signal("points_reclaimed"),
		"signal points_reclaimed(points, grace_points_snapshot)")
	_ck("signal_rejected_exists", _has_signal("action_rejected"),
		"signal action_rejected(reason, action_id)")


func _has_signal(sig: String) -> bool:
	var s: DeathService = DeathService.new(null)
	for d: Dictionary in s.get_signal_list():
		if String(d.get("name", "")) == sig:
			return true
	return false


## B) 正常：HP 归零 -> 死亡态 -> 记录掉落点数（0.5 比例）、信号、独立 flag、只读快照
func _test_normal(cfg: DeathConfig) -> void:
	_reset_signals()
	var s: DeathService = _make(cfg)
	_ck("initial_alive", not s.is_dead() and s.can_act() \
		and not s.has_pending_drop() and not s.is_reclaimed(),
		"初始存活 / 可行动 / 无待回收掉落")
	var r: Dictionary = s.on_death(200)
	_ck("on_death_ok", bool(r.get("ok")) and str(r.get("reason")) == "ok",
		"on_death(200) -> 进入死亡态、记录掉落")
	_ck("drop_ratio_applied", int(r.get("dropped_points")) == 100 \
		and int(r.get("grace_points_snapshot")) == 200,
		"dropped=floor(200*0.5)=100 / 只读快照=200 [PLACEHOLDER]")
	_ck("independent_flags", bool(r.get("dropped")) and not bool(r.get("reclaimed")) \
		and bool(r.get("is_dead")),
		"独立单向 flag：dropped=true / reclaimed=false / is_dead=true")
	_ck("signal_death_once", _sig_death == 1 \
		and _last_death_payload.size() == 2 \
		and int(_last_death_payload[0]) == 100 and int(_last_death_payload[1]) == 200,
		"death_occurred(100, 200) 恰 1 次")
	_ck("no_points_rollback", int(s.get_snapshot().get("grace_points_snapshot")) == 200 \
		and int(s.get_snapshot().get("dropped_points")) == 100,
		"★ 只读快照=200 / 掉落记录=100：绝不回退 grace.trial.points、绝不写 removals（A59）")
	_ck("pure_logic_no_save_api", not s.has_method("set_flag") \
		and not s.has_method("commit") and not s.has_method("write_removals") \
		and not s.has_method("add_child") and not s.has_method("get_tree"),
		"纯逻辑服务不暴露 set_flag / commit / removals / add_child / get_tree（I-1）")
	var snap: Dictionary = s.get_snapshot()
	_ck("snapshot_keys", snap.has("is_dead") and snap.has("dropped") \
		and snap.has("reclaimed") and snap.has("dropped_points") \
		and snap.has("grace_points_snapshot") and snap.has("can_act"),
		"get_snapshot() 全状态键可用")


## C) 边界：重复死亡 / drop_cap / 重生 / 一次性回收 / 新周期 / 死亡期间拒绝行动 / reset
func _test_boundary(cfg: DeathConfig) -> void:
	# 重复死亡不二次掉落
	_reset_signals()
	var s: DeathService = _make(cfg)
	s.on_death(200)
	var d2: Dictionary = s.on_death(500)
	_ck("duplicate_death_no_second_drop", not bool(d2.get("ok")) \
		and str(d2.get("reason")) == "already_dead" \
		and s.get_dropped_points() == 100 and s.get_death_count() == 1,
		"死亡期间重复 on_death(500) -> already_dead，不二次掉落（掉落恒 100）")

	# 死亡 -> 重生（未回收）-> 再死亡：drop_pending，不二次掉落
	var s2: DeathService = _make(cfg)
	s2.on_death(200)
	s2.on_grace_respawn()
	var d3: Dictionary = s2.on_death(500)
	_ck("pending_drop_no_second_drop", not bool(d3.get("ok")) \
		and str(d3.get("reason")) == "drop_pending" \
		and s2.get_dropped_points() == 100 and s2.get_death_count() == 1,
		"已有未回收掉落时再死亡 -> drop_pending，不二次掉落")

	# drop_cap 封顶
	var s3: DeathService = _make(cfg)
	var cap: Dictionary = s3.on_death(2000)
	_ck("drop_cap_enforced", int(cap.get("dropped_points")) == EXPECT_DROP_CAP,
		"floor(2000*0.5)=1000 -> drop_cap=500 封顶 [PLACEHOLDER]")

	# 赐福重生 + respawn_performed 信号 + 待回收点数
	_reset_signals()
	var s4: DeathService = _make(cfg)
	s4.on_death(200)
	var resp: Dictionary = s4.on_grace_respawn()
	_ck("grace_respawn_ok", bool(resp.get("ok")) and not bool(resp.get("is_dead")) \
		and int(resp.get("pending_dropped_points")) == 100,
		"赐福重生 -> 存活 / 待回收掉落=100")
	_ck("signal_respawn_once", _sig_respawn == 1 \
		and int(_last_respawn_payload[0]) == 100,
		"respawn_performed(100) 恰 1 次（供生产订阅者复位 FP/瓶/连击/窗口）")
	_ck("respawn_can_act", s4.can_act() and not s4.is_dead(),
		"重生后可行动（can_act=true）")
	_ck("respawn_keeps_drop_pending", s4.has_pending_drop() and not s4.is_reclaimed(),
		"重生保持掉落 pending（dropped=true / reclaimed=false）")

	# 一次性回收：points_reclaimed 恰 1 次，第二次 already_reclaimed
	_reset_signals()
	var rec1: Dictionary = s4.reclaim_dropped()
	_ck("reclaim_once_ok", bool(rec1.get("ok")) and int(rec1.get("points")) == 100 \
		and bool(rec1.get("reclaimed")) and s4.get_reclaim_count() == 1,
		"reclaim_dropped() -> points=100 / reclaimed=true（一次性回收）")
	_ck("signal_reclaimed_once", _sig_reclaimed == 1 \
		and int(_last_reclaimed_payload[0]) == 100 \
		and int(_last_reclaimed_payload[1]) == 200,
		"points_reclaimed(100, 200) 恰 1 次（供 A55/A57 一次入账）")
	var rec2: Dictionary = s4.reclaim_dropped()
	_ck("reclaim_only_once", not bool(rec2.get("ok")) \
		and str(rec2.get("reason")) == "already_reclaimed" \
		and int(rec2.get("points")) == 0 and s4.get_reclaim_count() == 1,
		"★ 回收只生效一次：第二次 -> already_reclaimed / points=0 / 计数恒 1")

	# 回收后允许新掉落周期
	var nd: Dictionary = s4.on_death(400)
	_ck("new_cycle_after_reclaim", bool(nd.get("ok")) \
		and int(nd.get("dropped_points")) == 200 and s4.get_death_count() == 2,
		"回收完成后再死亡 -> 新掉落周期 dropped=200（不二次回收旧掉落）")

	# 死亡期间拒绝行动 + 死亡期间拒绝回收（须先重生）
	_reset_signals()
	var s5: DeathService = _make(cfg)
	s5.on_death(200)
	var act: Dictionary = s5.request_action("attack")
	_ck("dead_action_rejected", not bool(act.get("ok")) \
		and str(act.get("reason")) == "dead" and not s5.can_act(),
		"死亡期间 request_action(attack) -> dead 拒绝、can_act=false")
	var rec_dead: Dictionary = s5.reclaim_dropped()
	_ck("dead_reclaim_rejected", not bool(rec_dead.get("ok")) \
		and str(rec_dead.get("reason")) == "dead",
		"死亡期间回收 -> dead 拒绝（须先赐福重生）")
	_ck("signal_action_rejected", _sig_rejected >= 2,
		"action_rejected 信号如实广播（死亡期间行动 / 回收）")
	var act_alive: Dictionary = s5.on_grace_respawn()
	_ck("respawn_then_action_ok", bool(act_alive.get("ok")) \
		and bool(s5.request_action("attack").get("ok")),
		"重生后合法行动放行（门禁恢复正常）")

	# reset
	var s6: DeathService = _make(cfg)
	s6.on_death(200)
	s6.on_grace_respawn()
	s6.reclaim_dropped()
	s6.reset()
	_ck("reset_clears_all", not s6.is_dead() and not s6.has_pending_drop() \
		and not s6.is_reclaimed() and s6.get_dropped_points() == 0 \
		and s6.get_death_count() == 0 and s6.get_respawn_count() == 0 \
		and s6.get_reclaim_count() == 0,
		"reset() -> 清死亡态 / 两个单向 flag / 掉落记录 / 三类计数")


## D) 异常：异常输入 / config=null / 非法表 / 异常后正常流程仍成立
func _test_abnormal(cfg: DeathConfig) -> void:
	_reset_signals()
	var s: DeathService = _make(cfg)
	var bad_points: Array = [null, -1.0, "x", [1], NAN, INF]
	var all_rejected: bool = true
	for v: Variant in bad_points:
		var r: Dictionary = s.on_death(v)
		if bool(r.get("ok")) or str(r.get("reason")) != "invalid_input":
			all_rejected = false
	_ck("invalid_points_all_rejected", all_rejected,
		"%d 类异常点数全部 invalid_input 拒绝（null/负/字符串/数组/NaN/Inf）" % bad_points.size())
	_ck("invalid_points_no_state_change", not s.is_dead() \
		and s.get_death_count() == 0 and s.get_dropped_points() == 0,
		"异常点数拒绝且不进入死亡态 / 不记录掉落")
	var bad_actions: Array = [null, "", 12, [1], {}]
	var acts_rejected: bool = true
	for a: Variant in bad_actions:
		var r2: Dictionary = s.request_action(a)
		if bool(r2.get("ok")) or str(r2.get("reason")) != "invalid_input":
			acts_rejected = false
	_ck("invalid_action_all_rejected", acts_rejected,
		"%d 类异常 action_id 全部 invalid_input 拒绝" % bad_actions.size())
	var after: Dictionary = s.on_death(200)
	_ck("invalid_then_normal_ok", bool(after.get("ok")) \
		and int(after.get("dropped_points")) == 100,
		"异常输入拒绝后正常死亡仍得 dropped=100（状态未被污染）")

	# config=null / set_config(null)
	var s_null: DeathService = _make(null)
	_ck("no_config_reject", not s_null.is_config_valid() \
		and str(s_null.on_death(200).get("reason")) == "no_config",
		"config=null -> on_death 拒绝 REASON_NO_CONFIG（不崩）")
	s_null.set_config(cfg)
	_ck("set_config_recovers", s_null.is_config_valid() \
		and bool(s_null.on_death(200).get("ok")),
		"set_config(合法表) -> 恢复正常流程")
	s_null.set_config(null)
	_ck("set_config_null_reject", not s_null.is_config_valid() \
		and str(s_null.on_death(200).get("reason")) == "no_config",
		"set_config(null) -> 重新降级拒绝")

	# 非法表（5 类）
	_ck("invalid_table_ratio_gt1", not _bad_cfg("drop_ratio", 1.5).is_valid(),
		"drop_ratio=1.5（>1）-> is_valid()=false")
	_ck("invalid_table_ratio_negative", not _bad_cfg("drop_ratio", -0.1).is_valid(),
		"drop_ratio=-0.1 -> is_valid()=false")
	_ck("invalid_table_ratio_nan", not _bad_cfg("drop_ratio", NAN).is_valid(),
		"drop_ratio=NaN -> is_valid()=false")
	_ck("invalid_table_cap_negative", not _bad_cfg("drop_cap", -1).is_valid(),
		"drop_cap=-1 -> is_valid()=false")
	_ck("invalid_table_bad_policy", not _bad_cfg("invalid_input_policy", "clamp").is_valid(),
		"invalid_input_policy=clamp（非 reject）-> is_valid()=false")
	var bad: DeathConfig = _bad_cfg("drop_ratio", 1.5)
	var s_bad: DeathService = DeathService.new(bad)
	_ck("invalid_table_service_reject", not s_bad.is_config_valid() \
		and str(s_bad.on_death(200).get("reason")) == "no_config",
		"非法表注入服务 -> 拒绝且不崩（降级）")


func _bad_cfg(key: String, value: Variant) -> DeathConfig:
	var c: DeathConfig = DeathConfig.new()
	c.drop_ratio = EXPECT_DROP_RATIO
	c.drop_cap = EXPECT_DROP_CAP
	c.invalid_input_policy = EXPECT_POLICY
	c.set(key, value)
	return c


## E) A48① 生产订阅者静态证据（wave_trial_director.gd 生产节点，非验证脚本）
func _test_production_subscriber() -> void:
	var abs_path: String = ProjectSettings.globalize_path(DIRECTOR_PATH)
	var src: String = FileAccess.get_file_as_string(abs_path)
	if src.is_empty():
		src = FileAccess.get_file_as_string(DIRECTOR_PATH)
	_ck("production_subscriber_in_source", src.contains("_bind_death_signals") \
		and src.contains("get_death_service") \
		and src.contains("points_reclaimed") \
		and src.contains("base_for_combo + _death_reclaim_acc") \
		and src.contains("_flask.on_grace_rest()"),
		"生产源码含 4 信号订阅者 + 唯一实例 getter + 回收并入结算 + 赐福休息补满（A48①/A54/A57）")


func _finish() -> void:
	print("[V140-DT] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V140-DT] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V140-DT] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V140-DT] === SELFTEST END ===")
	quit(0 if all_ok else 1)
