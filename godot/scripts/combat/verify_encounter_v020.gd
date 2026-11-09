extends SceneTree

## v0.2.0 P1 · 遭遇战自测 L2（规则纯逻辑）+ L3（导演集成）。
## 覆盖：重置后 Boss HP 比例回 1.0、连续同名招式被抑制、重复挑战计数递增、
##       胜负快照、0 血与连点边界、依赖缺失降级、数据驱动（不硬编码帧数）。
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path <godot> \
##       --script res://scripts/combat/verify_encounter_v020.gd
## 装配惯例同 v010：--script 模式 add_child 不 flush _ready，需显式 call("_ready")；
##   /root/... 绝对路径在该模式不可用，用 root.get_node_or_null() 与 Engine.get_main_loop()。
## 断言走与运行时完全相同的 debug_* / report_boss_move / get_snapshot 路径；
## 逐条输出 PASS/FAIL 与 RESULT，失败 quit(1)，不伪造 PASS。
## 注意：击杀闭环经 I-2 写 user:// 存档 flag，自测结束把两个 flag 恢复为原值（如实登记）。

const SCENE_PATH: String = "res://scenes/encounter_v010.tscn"
const TABLE_PATH: String = "res://data/combat/player_actions.tres"
const BOSS_PATH: String = "res://data/combat/boss_01_margit.tres"
const DIRECTOR_SCRIPT: String = "res://scripts/combat/encounter_director.gd"

var _pass: int = 0
var _fail: int = 0


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V020] %s PASS=%s | %s" % [tag, str(ok), detail])


func _initialize() -> void:
	print("[V020] === SELFTEST START ===")
	_test_rules_layer()
	_test_director_layer()
	_finish_test()


# ---------------------------------------------------------------------------
# L2：规则层纯逻辑（数据驱动 / 不硬编码帧数 / 连点 / 0 值 / 依赖缺失降级）
# ---------------------------------------------------------------------------
func _test_rules_layer() -> void:
	# 数据真源：BossData.ai_poll_interval_sec 与 MoveData.cooldown_sec
	var bd: BossData = load(BOSS_PATH) as BossData
	_ck("rules_data_loaded", bd != null, "path=%s" % BOSS_PATH)
	if bd == null:
		return
	var poll: float = bd.ai_poll_interval_sec
	_ck("rules_poll_from_bossdata", poll == 0.2, "ai_poll_interval_sec=%s" % str(poll))
	var mv: MoveData = null
	if not bd.phases.is_empty():
		var ph: PhaseData = bd.phases[0] as PhaseData
		if ph != null and not ph.moves.is_empty():
			mv = ph.moves[0] as MoveData
	_ck("rules_move_from_movedata", mv != null and mv.id == "move_01_dagger_slash" and mv.cooldown_sec == 0.6,
		"id=%s cd=%s" % [mv.id if mv != null else "null", str(mv.cooldown_sec if mv != null else -1.0)])
	var fps: float = float(PlayerActionState.LOGIC_FPS)  # 60，帧率基准，非帧数常量

	# 数据驱动窗口：max(cooldown_sec, ai_poll_interval_sec) × fps，不硬编码帧数
	var r0: EncounterRulesV020 = EncounterRulesV020.new(poll, fps)
	_ck("rules_window_uses_cooldown", r0.window_frames(0.6, fps) == 0.6 * fps,
		"window=%s expect=%s" % [str(r0.window_frames(0.6, fps)), str(0.6 * fps)])
	_ck("rules_window_uses_poll_floor", r0.window_frames(0.0, fps) == poll * fps,
		"window=%s poll_floor=%s" % [str(r0.window_frames(0.0, fps)), str(poll * fps)])
	_ck("rules_window_cd_gt_poll", r0.window_frames(2.2, fps) == 2.2 * fps,
		"window=%s" % str(r0.window_frames(2.2, fps)))
	_ck("rules_poll_injected", r0.get_ai_poll_interval_sec() == poll,
		"injected=%s" % str(r0.get_ai_poll_interval_sec()))

	# 连续同名抑制 + retry_count 计数
	var r: EncounterRulesV020 = EncounterRulesV020.new(poll, fps)
	_ck("rules_first_allow", r.should_allow_move("", "move_01_dagger_slash", 0.6, fps) == true,
		"last=%s" % r.last_move_id)
	_ck("rules_same_suppressed", r.should_allow_move(r.last_move_id, "move_01_dagger_slash", 0.6, fps) == false,
		"retry=%d" % r.retry_count)
	_ck("rules_retry_count_1", r.retry_count == 1, "retry=%d" % r.retry_count)
	# 数据驱动：推进 0.6s×60 帧后冷却结束，同名放行
	var cd_frames: int = int(0.6 * fps)
	for _i: int in range(cd_frames):
		r.tick_frame(1.0 / fps)
	_ck("rules_after_cooldown_allow", r.should_allow_move(r.last_move_id, "move_01_dagger_slash", 0.6, fps) == true,
		"elapsed=%d window=%s" % [r.get_elapsed_frames(), str(r.get_active_window_frames())])
	# 不同招式立即放行
	_ck("rules_different_allow", r.should_allow_move(r.last_move_id, "move_02_staff_slam", 2.2, fps) == true,
		"last=%s" % r.last_move_id)

	# 连点边界：同名连发全抑制、retry_count 单调累加、不崩
	var rc: EncounterRulesV020 = EncounterRulesV020.new(poll, fps)
	rc.should_allow_move("", "A", 0.6, fps)
	var spam: int = 0
	for _i: int in range(20):
		if not rc.should_allow_move("A", "A", 0.6, fps):
			spam += 1
	_ck("rules_spam_all_suppressed", spam == 20 and rc.retry_count == 20,
		"spam=%d retry=%d" % [spam, rc.retry_count])
	_ck("rules_spam_no_crash", rc.total_allowed == 1 and rc.total_suppressed == 20,
		"allowed=%d suppressed=%d" % [rc.total_allowed, rc.total_suppressed])

	# 0 值 / 依赖缺失降级：ai_poll=0、fps=0、cooldown=0、负 fps、空 id 均不崩且放行
	var rz: EncounterRulesV020 = EncounterRulesV020.new(0.0, 0.0)
	_ck("rules_zero_degrade", rz.should_allow_move("A", "A", 0.0, 0.0) == true and rz.retry_count == 0,
		"retry=%d" % rz.retry_count)
	_ck("rules_negative_fps_degrade", rz.should_allow_move("", "B", 0.0, -1.0) == true,
		"last=%s" % rz.last_move_id)
	_ck("rules_empty_id_degrade", rz.should_allow_move("", "", 0.0, fps) == true, "no_crash")

	# reset_for_rematch 清上一招与帧基准，但保留 retry_count 累计
	var rk: EncounterRulesV020 = EncounterRulesV020.new(poll, fps)
	rk.should_allow_move("", "A", 0.6, fps)
	rk.should_allow_move("A", "A", 0.6, fps)
	rk.reset_for_rematch()
	_ck("rules_rematch_reset", rk.last_move_id == "" and rk.get_elapsed_frames() == 0 and rk.retry_count == 1,
		"last=%s elapsed=%d retry=%d" % [rk.last_move_id, rk.get_elapsed_frames(), rk.retry_count])
	rk.reset_all()
	_ck("rules_reset_all", rk.retry_count == 0 and rk.total_allowed == 0, "full_reset")


# ---------------------------------------------------------------------------
# L3：导演集成（赐福重置 Boss / 重复挑战 / 胜负快照 / 0 血 / 依赖缺失降级）
# ---------------------------------------------------------------------------
func _test_director_layer() -> void:
	var table: Resource = load(TABLE_PATH) as Resource
	_ck("dir_table_loaded", table != null, "path=%s" % TABLE_PATH)
	var bd: BossData = load(BOSS_PATH) as BossData
	# 两个 flag 不是同一个：BossController 只读数据表里的就绪 key，
	# SaveDeltaWriter 经 I-2 写 combat.<id>.defeated。分别保存/恢复，避免污染存档。
	var ready_key: String = bd.defeated_flag_key if bd != null else ""
	var i2_key: String = "combat.%s.defeated" % (bd.id if bd != null else "boss_01_margit")
	var ws: Node = root.get_node_or_null("WorldState")
	var original_ready: bool = false
	var original_i2: bool = false
	if ws != null:
		original_ready = bool(ws.call("get_flag", ready_key, false))
		original_i2 = bool(ws.call("get_flag", i2_key, false))
		ws.call("set_flag", ready_key, false)
		ws.call("set_flag", i2_key, false)

	var packed: PackedScene = ResourceLoader.load(SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	_ck("dir_scene_loaded", packed != null, "path=%s" % SCENE_PATH)
	if packed == null:
		_restore_all(ws, ready_key, original_ready, i2_key, original_i2)
		return
	var inst: Node = packed.instantiate()
	root.add_child(inst)
	# SceneTree --script 的 _initialize() 内 add_child 不会同步 flush _ready；
	# 按项目既有验证惯例显式调用，并补齐 /root/... 绝对路径不可解析的依赖。
	var game_events: Node = root.get_node_or_null("GameEvents")
	var save_writer: Node = root.get_node_or_null("SaveDeltaWriter")
	if save_writer != null:
		var regex: RegEx = RegEx.new()
		regex.compile("^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$")
		save_writer.set("_re", regex)
		save_writer.set("_ws", ws)
	if game_events != null and save_writer != null and game_events.has_signal("boss_defeated"):
		var already_bound: bool = false
		for conn: Dictionary in game_events.get_signal_connection_list("boss_defeated"):
			var bound: Callable = conn["callable"]
			if bound.get_method() == "_on_boss_defeated":
				already_bound = true
		if not already_bound:
			game_events.connect("boss_defeated", Callable(save_writer, "_on_boss_defeated"))
	# 先 _ready 再注入：_ready 内部会把解析失败的 /root/... 结果写回 null。
	var boss_node: Node = inst.get_node_or_null("Boss")
	if boss_node != null:
		boss_node.call("_ready")
		boss_node.set("_world_state", ws)
	var bus_node: Node = inst.get_node_or_null("CombatEventBus")
	if bus_node != null:
		bus_node.call("_ready")
		bus_node.set("_game_events", game_events)
	inst.set("simulate_boss", false)
	inst.call("_ready")

	var s0: Dictionary = inst.call("get_snapshot")
	_ck("dir_init_boss_full", float(s0["boss_hp_ratio"]) == 1.0, "ratio=%s" % str(s0["boss_hp_ratio"]))
	_ck("dir_init_phase_1", int(s0["boss_phase"]) == 1, "phase=%s" % str(s0["boss_phase"]))
	_ck("dir_init_rematch_0", int(s0["rematch_count"]) == 0, "rematch=%s" % str(s0["rematch_count"]))
	_ck("dir_init_not_defeated", bool(s0["boss_defeated"]) == false, "defeated=%s" % str(s0["boss_defeated"]))

	# 导演层接规则：连续两次同名招式，第二次被抑制、retry_count 递增
	var a1: bool = bool(inst.call("report_boss_move", "move_01_dagger_slash", 0.6))
	var a2: bool = bool(inst.call("report_boss_move", "move_01_dagger_slash", 0.6))
	_ck("dir_rules_same_suppressed", a1 == true and a2 == false, "a1=%s a2=%s" % [str(a1), str(a2)])
	var sd: Dictionary = inst.call("get_snapshot")
	_ck("dir_rules_retry", int(sd["retry_count"]) == 1 and str(sd["last_move_id"]) == "move_01_dagger_slash",
		"retry=%s last=%s" % [str(sd["retry_count"]), str(sd["last_move_id"])])

	# 0 血边界：击杀 Boss（HP 比例归 0 / 击败态），胜负快照记一次 win
	inst.call("debug_kill_boss")
	var sk: Dictionary = inst.call("get_snapshot")
	_ck("dir_boss_zero_hp", float(sk["boss_hp_ratio"]) == 0.0 and bool(sk["boss_defeated"]) == true,
		"ratio=%s defeated=%s" % [str(sk["boss_hp_ratio"]), str(sk["boss_defeated"])])
	_ck("dir_win_snapshot", int(sk["outcome"]) == 1 and int(sk["wins"]) == 1 and int(sk["losses"]) == 0,
		"outcome=%s wins=%s losses=%s" % [str(sk["outcome"]), str(sk["wins"]), str(sk["losses"])])
	var hist1: Array = sk["outcome_history"] as Array
	_ck("dir_history_1", hist1.size() == 1 and int(hist1[0]) == 1, "hist=%s" % str(hist1))

	# 赐福休息：真正重置 Boss（HP 回 1.0 / 阶段回 1 / 清击败态 / 重复挑战 +1）
	inst.call("debug_grace_rest")
	var sr: Dictionary = inst.call("get_snapshot")
	_ck("dir_reset_boss_full", float(sr["boss_hp_ratio"]) == 1.0, "ratio=%s" % str(sr["boss_hp_ratio"]))
	_ck("dir_reset_phase_1", int(sr["boss_phase"]) == 1, "phase=%s" % str(sr["boss_phase"]))
	_ck("dir_reset_not_defeated", bool(sr["boss_defeated"]) == false, "defeated=%s" % str(sr["boss_defeated"]))
	_ck("dir_reset_player_full", float(sr["player_hp"]) == 100.0 and int(sr["outcome"]) == -1,
		"hp=%s outcome=%s" % [str(sr["player_hp"]), str(sr["outcome"])])
	_ck("dir_rematch_inc_1", int(sr["rematch_count"]) == 1 and int(sr["grace_rests"]) == 1,
		"rematch=%s rests=%s" % [str(sr["rematch_count"]), str(sr["grace_rests"])])
	_ck("dir_reset_rules_last_cleared", str(sr["last_move_id"]) == "", "last=%s" % str(sr["last_move_id"]))

	# 第二次重复挑战：再次击杀 -> 再次赐福，计数递增、胜负快照累计
	inst.call("debug_kill_boss")
	var sk2: Dictionary = inst.call("get_snapshot")
	_ck("dir_second_kill", int(sk2["outcome"]) == 1 and int(sk2["wins"]) == 2,
		"outcome=%s wins=%s" % [str(sk2["outcome"]), str(sk2["wins"])])
	inst.call("debug_grace_rest")
	var sr2: Dictionary = inst.call("get_snapshot")
	_ck("dir_rematch_inc_2", int(sr2["rematch_count"]) == 2 and float(sr2["boss_hp_ratio"]) == 1.0,
		"rematch=%s ratio=%s" % [str(sr2["rematch_count"]), str(sr2["boss_hp_ratio"])])
	var hist2: Array = sr2["outcome_history"] as Array
	_ck("dir_history_2", hist2.size() == 2 and int(hist2[0]) == 1 and int(hist2[1]) == 1,
		"hist=%s" % str(hist2))

	# 玩家 0 血 / 连点边界：连续 Boss 命中扣血到 0，败北只结算一次
	for _i: int in range(20):
		inst.call("debug_boss_hit")
	var sl: Dictionary = inst.call("get_snapshot")
	_ck("dir_player_zero_hp", float(sl["player_hp"]) == 0.0 and int(sl["outcome"]) == 0,
		"hp=%s outcome=%s" % [str(sl["player_hp"]), str(sl["outcome"])])
	_ck("dir_loss_snapshot", int(sl["losses"]) == 1 and int(sl["wins"]) == 2,
		"losses=%s wins=%s" % [str(sl["losses"]), str(sl["wins"])])
	_ck("dir_no_double_settle", int(sl["hits_taken"]) == 9, "hits_taken=%s" % str(sl["hits_taken"]))

	# 依赖缺失降级：裸导演（无 Boss）仍可构造、推进、赐福休息不崩，不产生重复挑战
	var bare: Node = Node.new()
	bare.set_script(load(DIRECTOR_SCRIPT) as Script)
	root.add_child(bare)
	bare.call("_ready")
	bare.call("debug_step", 3)
	bare.call("debug_grace_rest")
	var sb: Dictionary = bare.call("get_snapshot")
	_ck("dir_missing_deps_degrade", float(sb["player_hp"]) == 100.0 and int(sb["rematch_count"]) == 0,
		"hp=%s rematch=%s" % [str(sb["player_hp"]), str(sb["rematch_count"])])
	_ck("dir_missing_deps_no_boss", float(sb["boss_hp_ratio"]) == -1.0 and bool(sb["boss_defeated"]) == false,
		"ratio=%s defeated=%s" % [str(sb["boss_hp_ratio"]), str(sb["boss_defeated"])])
	_ck("dir_missing_deps_rest", int(sb["grace_rests"]) == 1, "rests=%s" % str(sb["grace_rests"]))
	bare.free()
	inst.free()

	_restore_all(ws, ready_key, original_ready, i2_key, original_i2)


func _restore_all(ws: Node, key_a: String, value_a: bool, key_b: String, value_b: bool) -> void:
	if ws == null or not ws.has_method("set_flag"):
		return
	if not key_a.is_empty():
		ws.call("set_flag", key_a, value_a)
	if not key_b.is_empty():
		ws.call("set_flag", key_b, value_b)


func _finish_test() -> void:
	print("[V020] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	print("[V020] RESULT=%s" % ("ALL_MATCH" if _fail == 0 else "FAILED"))
	print("[V020] === SELFTEST END ===")
	quit(0 if _fail == 0 else 1)
