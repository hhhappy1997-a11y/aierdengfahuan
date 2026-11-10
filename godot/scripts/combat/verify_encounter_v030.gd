extends SceneTree

## v0.3.0 R25 · 遭遇战自测 L3（A13 重打 / GRACE-RETRY 两个三段式 flag /
##   CombatResolver 削韧·异常·处决接线 / 0 血·连点·依赖缺失）。
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path <godot> \
##       --script res://scripts/combat/verify_encounter_v030.gd
## 断言走与运行时完全相同的 debug_* / start_grace_retry / check_execute / get_snapshot
##   路径；逐条输出 PASS/FAIL 与 RESULT，失败 quit(1)，不伪造 PASS。
## 装配惯例同 v010/v020：--script 模式 add_child 不 flush _ready，需显式 call("_ready")；
##   /root/... 绝对路径在该模式不可用，用 root.get_node_or_null() 与 Engine.get_main_loop()。
## 所有数值期望来自数据表（boss_01_margit.tres / player_actions.tres），不硬编码。
## 注意：本脚本经 I-1 写 user:// 存档 flag，结束把 4 个 key 恢复为原值（如实登记）。

const SCENE_PATH: String = "res://scenes/encounter_v010.tscn"
const TABLE_PATH: String = "res://data/combat/player_actions.tres"
const BOSS_PATH: String = "res://data/combat/boss_01_margit.tres"
const DIRECTOR_SCRIPT: String = "res://scripts/combat/encounter_director.gd"
const BOSS_CONTROLLER_SCRIPT: String = "res://scripts/combat/boss_controller.gd"
const FLAG_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"

var _pass: int = 0
var _fail: int = 0
var _ws: Node = null
var _sw: Node = null
var _bd: BossData = null
var _inst: Node = null
var _re: RegEx = null
# 4 个 key 的原值（结束恢复，不污染存档）
var _original: Dictionary = {}


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V030] %s PASS=%s | %s" % [tag, str(ok), detail])


func _initialize() -> void:
	print("[V030] === SELFTEST START ===")
	_re = RegEx.new()
	_re.compile(FLAG_REGEX)
	_ws = root.get_node_or_null("WorldState")
	_sw = root.get_node_or_null("SaveDeltaWriter")
	_bd = load(BOSS_PATH) as BossData
	_ck("v030_boss_data_loaded", _bd != null, "path=%s" % BOSS_PATH)
	_ck("v030_table_loaded", load(TABLE_PATH) as Resource != null, "path=%s" % TABLE_PATH)
	if _bd == null:
		_finish_test()
		return
	_assemble_save_writer()
	_test_flag_keys()
	_test_a13_and_director()
	_restore_all()
	if _inst != null and is_instance_valid(_inst):
		_inst.free()
	_finish_test()


## 补齐 --script 模式下 /root/... 绝对路径不可解析的依赖（业务代码零改动）。
func _assemble_save_writer() -> void:
	if _sw != null:
		_sw.set("_re", _re)
		_sw.set("_ws", _ws)
	var ge: Node = root.get_node_or_null("GameEvents")
	if ge != null and _sw != null and ge.has_signal("boss_defeated"):
		var already_bound: bool = false
		for conn: Dictionary in ge.get_signal_connection_list("boss_defeated"):
			var bound: Callable = conn["callable"]
			if bound.get_method() == "_on_boss_defeated":
				already_bound = true
		if not already_bound:
			ge.connect("boss_defeated", Callable(_sw, "_on_boss_defeated"))


## 两个新 flag 的字面量与三段式正则（对象段由 EncounterRulesV020.ENCOUNTER_ID 驱动）。
func _test_flag_keys() -> void:
	var d: Node = Node.new()
	d.set_script(load(DIRECTOR_SCRIPT) as Script)
	root.add_child(d)
	var k1: String = d.call("flag_retried_key")
	var k2: String = d.call("flag_retry_active_key")
	_ck("v030_flag_retried_literal", k1 == "grace.encounter_01.retried", "key=%s" % k1)
	_ck("v030_flag_retry_active_literal", k2 == "grace.encounter_01.retry_active", "key=%s" % k2)
	_ck("v030_flag_keys_regex", _re.search(k1) != null and _re.search(k2) != null, "regex=%s" % FLAG_REGEX)
	d.free()


func _test_a13_and_director() -> void:
	var k_world: String = _bd.defeated_flag_key
	var k_combat: String = "combat.%s.defeated" % _bd.id
	var k_retried: String = "grace.encounter_01.retried"
	var k_active: String = "grace.encounter_01.retry_active"
	for k in [k_world, k_combat, k_retried, k_active]:
		_original[k] = _ws.call("get_flag", k, false) if _ws != null else false
	# 设置 L1 永久击败 = true（A13 要求绝不清除）；两个新 flag 设基线，便于断言。
	if _ws != null:
		_ws.call("set_flag", k_world, true)
		_ws.call("set_flag", k_combat, true)
		_ws.call("set_flag", k_retried, 0)
		_ws.call("set_flag", k_active, false)
	_ck("a13_l1_flags_set",
		_ws != null and bool(_ws.call("get_flag", k_world, false)) and bool(_ws.call("get_flag", k_combat, false)),
		"world=%s combat=%s" % [
			str(_ws.call("get_flag", k_world, false)) if _ws != null else "null",
			str(_ws.call("get_flag", k_combat, false)) if _ws != null else "null"])

	# ---- 对照：裸 BossController 注入可解析 WorldState 后，L1=true 会保持 IDLE ----
	_test_plain_boss_blocked()

	# ---- 实例化导演场景（--script 惯例装配） ----
	var packed: PackedScene = ResourceLoader.load(SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	_ck("v030_scene_loaded", packed != null, "path=%s" % SCENE_PATH)
	if packed == null:
		return
	_inst = packed.instantiate()
	root.add_child(_inst)
	var boss_node: Node = _inst.get_node_or_null("Boss")
	if boss_node != null:
		# 相对路径指向 /root/WorldState（--script 模式可解析），真实复现 L1 读取。
		boss_node.set("world_state_path", ^"../../WorldState")
		boss_node.call("_ready")
		boss_node.set("_world_state", _ws)
	var bus_node: Node = _inst.get_node_or_null("CombatEventBus")
	if bus_node != null:
		bus_node.call("_ready")
		bus_node.set("_game_events", root.get_node_or_null("GameEvents"))
	_inst.set("simulate_boss", false)
	_inst.call("_ready")

	var s0: Dictionary = _inst.call("get_snapshot")
	_ck("v030_init_boss_full", float(s0["boss_hp_ratio"]) == 1.0, "ratio=%s" % str(s0["boss_hp_ratio"]))
	_ck("v030_init_snapshot_has_phase", s0.has("boss_phase") and s0.has("l1_defeat_keys"),
		"phase=%s l1_keys=%s" % [str(s0["boss_phase"]), str(s0["l1_defeat_keys"])])
	var cfg: PoiseConfig = _bd.poise
	_ck("v030_poise_init_from_data", float(s0["boss_poise"]) == cfg.max_poise,
		"poise=%s expect=%s" % [str(s0["boss_poise"]), str(cfg.max_poise)])

	# ---- A13：赐福休息重置 Boss，即使 L1 永久击败仍可重打，且绝不清除 L1 ----
	_inst.call("debug_grace_rest")
	var sr: Dictionary = _inst.call("get_snapshot")
	_ck("a13_replay_boss_full", float(sr["boss_hp_ratio"]) == 1.0 and int(sr["boss_phase"]) == 1,
		"ratio=%s phase=%s" % [str(sr["boss_hp_ratio"]), str(sr["boss_phase"])])
	_ck("a13_l1_still_true",
		bool(_ws.call("get_flag", k_world, false)) and bool(_ws.call("get_flag", k_combat, false)),
		"world/combat 永久击败 flag 未被清除、未进 removals")
	var snap: Dictionary = sr["l1_defeat_snapshot"] as Dictionary
	_ck("a13_l1_ignored",
		bool(sr["l1_defeat_ignored"]) and snap.size() == 2
			and bool(snap.get(k_world, false)) and bool(snap.get(k_combat, false)),
		"ignored=%s snapshot=%s" % [str(sr["l1_defeat_ignored"]), str(snap)])
	_ck("a13_l1_keys_two", (sr["l1_defeat_keys"] as Array).size() == 2,
		"keys=%s" % str(sr["l1_defeat_keys"]))
	# 可重打的实质证明：重建实例能受伤害（HP 比例下降）
	var before: float = float(_inst.call("get_snapshot")["boss_hp_ratio"])
	_inst.call("debug_request_action", "attack_light")
	var guard: int = 0
	while guard < 60 and int(_inst.call("get_snapshot")["hits_landed"]) == 0:
		_inst.call("debug_step", 1)
		guard += 1
	var after: float = float(_inst.call("get_snapshot")["boss_hp_ratio"])
	_ck("a13_can_damage_after_rest", after < before,
		"before=%s after=%s guard=%d" % [str(before), str(after), guard])

	# ---- 任务 ②：两个三段式 flag（先落盘再改运行时实例 / 门控 / 结算清理） ----
	var ok1: bool = bool(_inst.call("debug_start_grace_retry"))
	_ck("retry_start_ok", ok1, "start_grace_retry=true")
	_ck("retried_inc_1", int(_ws.call("get_flag", k_retried, 0)) == 1,
		"retried=%s" % str(_ws.call("get_flag", k_retried, 0)))
	_ck("retry_active_true", bool(_ws.call("get_flag", k_active, false)),
		"retry_active=%s" % str(_ws.call("get_flag", k_active, false)))
	_ck("commit_reason_grace_retry",
		_sw != null and str(_sw.get("last_commit_reason")) == "grace_retry",
		"reason=%s" % (str(_sw.get("last_commit_reason")) if _sw != null else "null"))
	var srt: Dictionary = _inst.call("get_snapshot")
	_ck("retry_runtime_reset_after_commit",
		float(srt["boss_hp_ratio"]) == 1.0 and int(srt["outcome"]) == -1 and int(srt["retried_count"]) == 1,
		"ratio=%s outcome=%s retried_count=%s" % [
			str(srt["boss_hp_ratio"]), str(srt["outcome"]), str(srt["retried_count"])])
	# 连点门控：同回合第二次发起被拒，retried 不二次 +1
	var ok2: bool = bool(_inst.call("debug_start_grace_retry"))
	_ck("retry_spam_gated", not ok2 and int(_ws.call("get_flag", k_retried, 0)) == 1,
		"second=%s retried=%s" % [str(ok2), str(_ws.call("get_flag", k_retried, 0))])
	# 结算清理：先落盘再释放回合标记
	_inst.call("debug_finish_grace_retry")
	_ck("finish_retry_clears_active", not bool(_ws.call("get_flag", k_active, false)),
		"retry_active=%s" % str(_ws.call("get_flag", k_active, false)))
	_ck("finish_retry_commit_reason",
		_sw != null and str(_sw.get("last_commit_reason")) == "grace_retry",
		"reason=%s" % (str(_sw.get("last_commit_reason")) if _sw != null else "null"))
	# 单调递增：再发起一次 retried 到 2，不回退
	var ok3: bool = bool(_inst.call("debug_start_grace_retry"))
	_ck("retried_monotonic", ok3 and int(_ws.call("get_flag", k_retried, 0)) == 2,
		"third=%s retried=%s" % [str(ok3), str(_ws.call("get_flag", k_retried, 0))])
	_inst.call("debug_finish_grace_retry")

	# ---- 任务 ③：削韧（compute_poise_after_hit / resolve_poise） ----
	var mv0: MoveData = _bd.phases[0].moves[0] as MoveData
	var pd: float = mv0.poise_damage            # 数据表：22.0
	var reach: float = mv0.hitbox_reach_px      # 数据表：84.0
	var p0: float = float(_inst.call("get_snapshot")["boss_poise"])
	_ck("poise_retry_reset_from_data", p0 == cfg.max_poise,
		"poise=%s expect=%s" % [str(p0), str(cfg.max_poise)])
	var r_p1: Dictionary = _inst.call("debug_resolve_poise", pd)
	_ck("poise_after_hit", float(r_p1.get("poise", -1.0)) == maxf(0.0, p0 - pd),
		"poise=%s expect=%s" % [str(r_p1.get("poise", -1.0)), str(maxf(0.0, p0 - pd))])
	_ck("poise_compute_after_hit", float(_inst.call("get_snapshot")["last_poise_after_hit"]) == maxf(0.0, p0 - pd),
		"last=%s" % str(_inst.call("get_snapshot")["last_poise_after_hit"]))
	var broke: bool = false
	var break_r: Dictionary = {}
	for _i in range(20):
		break_r = _inst.call("debug_resolve_poise", pd)
		if bool(break_r.get("stance_broken", false)):
			broke = true
			break
	_ck("poise_to_zero_stance_broken", broke, "stance_broken=%s" % str(break_r.get("stance_broken", false)))
	_ck("poise_break_reset", float(break_r.get("poise", -1.0)) == cfg.max_poise,
		"poise=%s expect=%s" % [str(break_r.get("poise", -1.0)), str(cfg.max_poise)])
	_ck("poise_break_window", float(break_r.get("break_remaining_sec", -1.0)) == cfg.stance_break_duration_sec,
		"remaining=%s expect=%s" % [str(break_r.get("break_remaining_sec", -1.0)), str(cfg.stance_break_duration_sec)])
	_ck("poise_after_hit_floor_zero", float(_inst.call("get_snapshot")["last_poise_after_hit"]) <= 0.0,
		"last=%s" % str(_inst.call("get_snapshot")["last_poise_after_hit"]))

	# ---- 任务 ③：处决窗口（can_execute） ----
	var ex_open: bool = bool(_inst.call("check_execute", 0.0, reach, true, true))
	_ck("execute_window_open", ex_open,
		"break_remaining=%s threshold=%s" % [
			str(_inst.call("get_snapshot")["poise_break_remaining_sec"]), str(cfg.execute_hp_ratio_threshold)])
	_ck("execute_needs_hit_registered", not bool(_inst.call("check_execute", 0.0, reach, true, false)), "hit_registered=false")
	_ck("execute_needs_hit_window", not bool(_inst.call("check_execute", 0.0, reach, false, true)), "in_hit_window=false")
	_ck("execute_out_of_reach", not bool(_inst.call("check_execute", reach * 2.0, reach, true, true)),
		"distance=%s reach=%s" % [str(reach * 2.0), str(reach)])

	# ---- 任务 ③：regen_poise 韧性回复（超过数据表 delay 后按数据表速率回复） ----
	_inst.call("debug_resolve_poise", pd)
	var reduced: float = float(_inst.call("get_snapshot")["boss_poise"])
	_inst.call("debug_tick_combat", cfg.poise_regen_delay_sec + cfg.stance_break_duration_sec)
	var regened: float = float(_inst.call("get_snapshot")["boss_poise"])
	_ck("poise_regen_after_delay", regened > reduced and regened <= cfg.max_poise,
		"reduced=%s regened=%s max=%s" % [str(reduced), str(regened), str(cfg.max_poise)])
	_ck("poise_break_window_expires", float(_inst.call("get_snapshot")["poise_break_remaining_sec"]) == 0.0,
		"remaining=%s" % str(_inst.call("get_snapshot")["poise_break_remaining_sec"]))
	_ck("execute_window_closed", not bool(_inst.call("check_execute", 0.0, reach, true, true)),
		"break_remaining=0 -> can_execute=false")

	# ---- 任务 ③：异常累积与触发（apply_status_buildup，bleed/poison/frost） ----
	_ck("status_three_types", _bd.status_buildups.size() == 3, "count=%d" % _bd.status_buildups.size())
	var bleed: StatusBuildup = _bd.status_buildups[0] as StatusBuildup
	var half: float = bleed.threshold / 2.0
	var r_s1: Dictionary = _inst.call("debug_apply_status", bleed.status_type, half, 0.0)
	_ck("status_accumulate_no_trigger",
		not bool(r_s1.get("triggered", true)) and float(r_s1.get("buildup", -1.0)) == half,
		"buildup=%s triggered=%s threshold=%s" % [
			str(r_s1.get("buildup", -1.0)), str(r_s1.get("triggered", true)), str(bleed.threshold)])
	var r_s2: Dictionary = _inst.call("debug_apply_status", bleed.status_type, half, 0.0)
	_ck("status_trigger",
		bool(r_s2.get("triggered", false)) and float(r_s2.get("buildup", -1.0)) == 0.0,
		"triggered=%s buildup=%s" % [str(r_s2.get("triggered", false)), str(r_s2.get("buildup", -1.0))])
	_ck("status_trigger_damage_from_data",
		float(r_s2.get("trigger_damage", 0.0)) >= _bd.max_hp * bleed.trigger_damage_ratio,
		"damage=%s expect>=%s" % [str(r_s2.get("trigger_damage", 0.0)), str(_bd.max_hp * bleed.trigger_damage_ratio)])
	_ck("status_resistance_gain",
		float(r_s2.get("accumulated_resistance", 0.0)) == bleed.resistance_gain_per_trigger,
		"resistance=%s expect=%s" % [
			str(r_s2.get("accumulated_resistance", 0.0)), str(bleed.resistance_gain_per_trigger)])
	var poison: StatusBuildup = _bd.status_buildups[1] as StatusBuildup
	var frost: StatusBuildup = _bd.status_buildups[2] as StatusBuildup
	var rp: Dictionary = _inst.call("debug_apply_status", poison.status_type, poison.threshold / 4.0, 0.0)
	var rf: Dictionary = _inst.call("debug_apply_status", frost.status_type, frost.threshold / 4.0, 0.0)
	_ck("status_poison_frost_accumulate",
		not bool(rp.get("triggered", true)) and not bool(rf.get("triggered", true)),
		"poison=%s frost=%s" % [str(rp.get("buildup", -1.0)), str(rf.get("buildup", -1.0))])

	# ---- 0 血 / 连点 / 依赖缺失降级 ----
	_inst.call("debug_kill_boss")
	var sk: Dictionary = _inst.call("get_snapshot")
	_ck("boss_zero_hp", float(sk["boss_hp_ratio"]) == 0.0 and int(sk["outcome"]) == 1,
		"ratio=%s outcome=%s" % [str(sk["boss_hp_ratio"]), str(sk["outcome"])])
	_inst.call("debug_grace_rest")
	for _i in range(20):
		_inst.call("debug_boss_hit")
	var sl: Dictionary = _inst.call("get_snapshot")
	_ck("player_zero_hp", float(sl["player_hp"]) == 0.0 and int(sl["outcome"]) == 0,
		"hp=%s outcome=%s" % [str(sl["player_hp"]), str(sl["outcome"])])
	_ck("no_double_settle", int(sl["hits_taken"]) == 9, "hits_taken=%s" % str(sl["hits_taken"]))
	for _i in range(20):
		_inst.call("debug_resolve_poise", pd)
	var s_spam: Dictionary = _inst.call("get_snapshot")
	_ck("spam_no_crash", s_spam.has("boss_poise"), "poise=%s" % str(s_spam["boss_poise"]))

	var bare: Node = Node.new()
	bare.set_script(load(DIRECTOR_SCRIPT) as Script)
	root.add_child(bare)
	bare.call("_ready")
	var r_bare: Dictionary = bare.call("debug_resolve_poise", pd)
	var s_bare: Dictionary = bare.call("debug_apply_status", bleed.status_type, bleed.threshold, 0.0)
	var e_bare: bool = bool(bare.call("check_execute", 0.0, reach, true, true))
	var snap_bare: Dictionary = bare.call("get_snapshot")
	_ck("missing_deps_resolve_empty", r_bare.is_empty(), "resolver 缺失返回空 dict 不崩")
	_ck("missing_deps_status_empty", s_bare.is_empty(), "resolver 缺失返回空 dict 不崩")
	_ck("missing_deps_execute_false", not e_bare, "resolver 缺失 can_execute=false")
	_ck("missing_deps_no_crash", float(snap_bare["player_hp"]) == 100.0, "hp=%s" % str(snap_bare["player_hp"]))
	bare.free()


## 对照：裸 BossController 在 L1 永久击败 flag=true 时保持 IDLE（get_phase_index()==0），
## 证明 A13 的「运行时层忽略 L1」不是空话，而是修复了一个真实存在的阻塞。
func _test_plain_boss_blocked() -> void:
	var probe: Node = Node3D.new()
	probe.set_script(load(BOSS_CONTROLLER_SCRIPT) as Script)
	root.add_child(probe)
	probe.set("boss_data", _bd)
	# 挂在 root 下，用一层相对路径指向 /root/WorldState（--script 模式可解析）。
	probe.set("world_state_path", ^"../WorldState")
	probe.call("_ready")
	var phase: int = int(probe.call("get_phase_index"))
	_ck("a13_plain_boss_blocked_by_l1", phase == 0,
		"phase=%s（L1 defeated=true 时裸 BossController 保持 IDLE）" % str(phase))
	probe.free()


func _restore_all() -> void:
	if _ws == null or not _ws.has_method("set_flag"):
		return
	for k in _original.keys():
		_ws.call("set_flag", k, _original[k])


func _finish_test() -> void:
	print("[V030] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	print("[V030] RESULT=%s" % ("ALL_MATCH" if _fail == 0 else "FAILED"))
	print("[V030] === SELFTEST END ===")
	quit(0 if _fail == 0 else 1)
