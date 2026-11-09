extends SceneTree

## v0.1.0 · 遭遇战自测（L2 逻辑 + L3 运行时），覆盖正常 / 边界 / 异常三类输入。
## 真跑：--headless --path <godot> --script res://scripts/combat/verify_encounter_v010.gd
## 断言走与运行时完全相同的 _step 路径；不伪造 PASS，失败即 quit(1)。
## 注意：击杀闭环会经 I-2 写 user:// 存档 flag，自测结束会把 flag 恢复为原值（如实登记）。

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
	print("[V010] %s PASS=%s | %s" % [tag, str(ok), detail])


func _initialize() -> void:
	print("[V010] === SELFTEST START ===")
	var table: Resource = load(TABLE_PATH) as Resource
	_ck("table_loaded", table != null, "path=%s" % TABLE_PATH)
	if table == null:
		quit(1)
		return

	# ---- 正常：翻滚 22 帧 @60、无敌 [4,13) 左闭右开 ----
	var st: PlayerActionState = PlayerActionState.new(table)
	_ck("roll_request", st.request("roll"), "busy=%s" % str(st.is_busy()))
	_ck("roll_total_22", st.get_total() == 22, "total=%d" % st.get_total())
	var inv: Array[int] = []
	for i: int in range(22):
		if st.is_invulnerable():
			inv.append(i)
		st.tick()
	var expected: Array[int] = [4, 5, 6, 7, 8, 9, 10, 11, 12]
	_ck("roll_iframe_4_13", inv == expected, "inv=%s expected=%s" % [str(inv), str(expected)])
	_ck("roll_resets_to_idle", not st.is_busy() and st.get_frame() == 0, "busy=%s frame=%d" % [str(st.is_busy()), st.get_frame()])

	# ---- 边界：忙时重复请求被拒；异常：空表 / 未知 pose / idle 空转 ----
	var busy_state: PlayerActionState = PlayerActionState.new(table)
	busy_state.request("roll")
	_ck("busy_reject_repeat", not busy_state.request("attack_light"), "pose=%s" % busy_state.get_current_pose())
	var null_state: PlayerActionState = PlayerActionState.new(null)
	_ck("null_table_no_crash", not null_state.request("roll"), "busy=%s" % str(null_state.is_busy()))
	_ck("unknown_pose_rejected", not st.request("no_such_pose"), "busy=%s" % str(st.is_busy()))
	st.tick()
	_ck("tick_on_idle_safe", st.get_frame() == 0, "frame=%d" % st.get_frame())

	# ---- 集成层：清击败 flag 后实例化独立场景，隔离 Boss AI 以做帧级断言 ----
	var ws: Node = root.get_node_or_null("WorldState")
	var boss_data: BossData = load(BOSS_PATH) as BossData
	# 两个 flag 不是同一个：BossController 只读数据表里的就绪 key，
	# SaveDeltaWriter 经 I-2 写 combat.<id>.defeated。分别保存/恢复，避免污染存档。
	var ready_key: String = boss_data.defeated_flag_key if boss_data != null else ""
	var i2_key: String = "combat.%s.defeated" % (boss_data.id if boss_data != null else "boss_01_margit")
	var original_ready: bool = false
	var original_i2: bool = false
	if ws != null:
		original_ready = bool(ws.call("get_flag", ready_key, false))
		original_i2 = bool(ws.call("get_flag", i2_key, false))
		ws.call("set_flag", ready_key, false)
		ws.call("set_flag", i2_key, false)

	var packed: PackedScene = ResourceLoader.load(SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	_ck("scene_loaded", packed != null, "path=%s" % SCENE_PATH)
	if packed == null:
		_restore_all(ws, ready_key, original_ready, i2_key, original_i2)
		_finish_test()
		return
	var inst: Node = packed.instantiate()
	root.add_child(inst)
	# SceneTree --script 的 _initialize() 内 add_child 不会同步 flush _ready；
	# 按项目既有验证惯例显式调用，保证 boss_data / 阶段 / 信号总线都完成初始化。
	# --script 模式下既有件的 /root/... 绝对路径不可解析，这里补齐等价装配
	# （真实 autoload 实例、真实方法，业务代码零改动；运行时由引擎自动完成）。
	var game_events: Node = root.get_node_or_null("GameEvents")
	var save_writer: Node = root.get_node_or_null("SaveDeltaWriter")
	if save_writer != null:
		var regex: RegEx = RegEx.new()
		regex.compile("^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$")
		save_writer.set("_re", regex)
		save_writer.set("_ws", ws)
	if game_events != null and save_writer != null and game_events.has_signal("boss_defeated"):
		# autoload 通常已自行连接；按连接表逐项核对方法名，避免重复 connect 报错。
		var already_bound: bool = false
		for conn: Dictionary in game_events.get_signal_connection_list("boss_defeated"):
			var bound: Callable = conn["callable"]
			if bound.get_method() == "_on_boss_defeated":
				already_bound = true
		if not already_bound:
			game_events.connect("boss_defeated", Callable(save_writer, "_on_boss_defeated"))
	# 先 _ready 再注入：_ready 内部会把解析失败的 /root/... 结果写回 null，
	# 若顺序反了，注入会被覆盖。
	var boss_node: Node = inst.get_node_or_null("Boss")
	if boss_node != null:
		boss_node.call("_ready")
		boss_node.set("_world_state", ws)
	var bus_node: Node = inst.get_node_or_null("CombatEventBus")
	if bus_node != null:
		bus_node.call("_ready")
		bus_node.set("_game_events", game_events)
	var director: Node = inst
	director.set("simulate_boss", false)
	director.call("_ready")

	var s0: Dictionary = director.call("get_snapshot")
	_ck("init_hp_full", float(s0["player_hp"]) == 100.0, "hp=%s" % str(s0["player_hp"]))

	# 无敌窗口内 Boss 命中 → 免伤；窗口结束后 → 扣血
	director.call("debug_request_action", "roll")
	director.call("debug_step", 4)
	director.call("debug_boss_hit")
	var s1: Dictionary = director.call("get_snapshot")
	_ck("iframe_dodge", int(s1["dodges"]) == 1 and float(s1["player_hp"]) == 100.0,
		"frame=%s dodges=%s hp=%s" % [str(s1["frame"]), str(s1["dodges"]), str(s1["player_hp"])])
	director.call("debug_step", 9)
	director.call("debug_boss_hit")
	var s2: Dictionary = director.call("get_snapshot")
	_ck("post_iframe_takes_hit", int(s2["hits_taken"]) == 1 and float(s2["player_hp"]) < 100.0,
		"frame=%s hits=%s hp=%s" % [str(s2["frame"]), str(s2["hits_taken"]), str(s2["player_hp"])])

	# 边界：血量下限 0、结算后不再重复扣血
	for _i: int in range(20):
		director.call("debug_boss_hit")
	var s3: Dictionary = director.call("get_snapshot")
	_ck("hp_floor_zero", float(s3["player_hp"]) == 0.0 and int(s3["outcome"]) == 0,
		"hp=%s outcome=%s" % [str(s3["player_hp"]), str(s3["outcome"])])
	_ck("no_double_settle", int(s3["hits_taken"]) == 9, "hits_taken=%s expected=9" % str(s3["hits_taken"]))

	# 赐福休息：恢复 HP / 回到进行中 / 触发一次落盘
	director.call("debug_grace_rest")
	var s4: Dictionary = director.call("get_snapshot")
	_ck("grace_rest", float(s4["player_hp"]) == 100.0 and int(s4["outcome"]) == -1 and int(s4["grace_rests"]) == 1,
		"hp=%s outcome=%s rests=%s" % [str(s4["player_hp"]), str(s4["outcome"]), str(s4["grace_rests"])])

	# 正常：轻攻击 active 首帧命中 Boss，HP 比例下降
	director.call("debug_request_action", "attack_light")
	var guard: int = 0
	var landed: int = 0
	while guard < 60:
		director.call("debug_step", 1)
		guard += 1
		var probe: Dictionary = director.call("get_snapshot")
		landed = int(probe["hits_landed"])
		if landed > 0:
			break
	var s5: Dictionary = director.call("get_snapshot")
	_ck("player_hit_lands", landed >= 1 and float(s5["boss_hp_ratio"]) < 1.0,
		"landed=%s boss_ratio=%s guard=%d" % [str(landed), str(s5["boss_hp_ratio"]), guard])

	# 闭环：击杀 → I-2 → GameEvents → SaveDeltaWriter 写三段式 flag
	director.call("debug_kill_boss")
	var s6: Dictionary = director.call("get_snapshot")
	var flag_after: bool = false
	if ws != null:
		flag_after = bool(ws.call("get_flag", i2_key, false))
	_ck("encounter_win", int(s6["outcome"]) == 1, "outcome=%s" % str(s6["outcome"]))
	_ck("i2_defeat_flag", flag_after, "key=%s value=%s" % [i2_key, str(flag_after)])

	# 异常：复用件全缺失时导演仍可构造与推进（降级不崩）
	var bare: Node = Node.new()
	bare.set_script(load(DIRECTOR_SCRIPT) as Script)
	root.add_child(bare)
	bare.call("_ready")
	bare.call("debug_step", 3)
	var s7: Dictionary = bare.call("get_snapshot")
	_ck("missing_deps_degrades", float(s7["player_hp"]) == 100.0, "hp=%s" % str(s7["player_hp"]))
	bare.free()
	inst.free()

	_restore_all(ws, ready_key, original_ready, i2_key, original_i2)
	_finish_test()


func _restore_all(ws: Node, key_a: String, value_a: bool, key_b: String, value_b: bool) -> void:
	if ws == null or not ws.has_method("set_flag"):
		return
	if not key_a.is_empty():
		ws.call("set_flag", key_a, value_a)
	if not key_b.is_empty():
		ws.call("set_flag", key_b, value_b)


func _finish_test() -> void:
	print("[V010] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	print("[V010] RESULT=%s" % ("ALL_MATCH" if _fail == 0 else "FAILED"))
	print("[V010] === SELFTEST END ===")
	quit(0 if _fail == 0 else 1)
