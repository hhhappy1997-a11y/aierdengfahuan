extends SceneTree
## R21 / cmd-20261109-115818-641-A2 · Rank-2 CombatDataValidator 类级实例化真跑
##
## 真读 3 份运行权威 .tres（boss / player_actions / enemy），逐项打印「实际值 / 期望值 / PASS|FAIL」：
##   组A：玩家 8 帧动作（8 条 action 的 startup/active/recovery/total/hit 区间）+ 翻滚 E-7 + E-6，
##        与 Boss 三招按 pose key「p1_dagger_slash / p1_staff_slam / p2_holy_hammer」的
##        47 / 71 / 91 帧与 hit 区间 [18,23)/[30,37)/[42,51) 一并纳入断言，与文档口径逐项核对；
##   组B：与 R19 总指挥裁决值「4/9/9=22、无敌[4,13)」逐项核对（本轮为回归，不再改数值）；
##   组C：【R21 变更】preload(res://scripts/combat/combat_data_validator.gd).new() 真实实例化
##        CombatDataValidator 类并调用 validate_all() -> Dictionary（checks/pass/fail/errors），
##        替换 R20 的「§9 等价校验同跑」；类内实际断言 player_actions.tres 4/9/9=22 帧@60 /
##        无敌[4,13)、Boss 三招 47/71/91 与 hit 区间、E-8 max_resistance 400/480/420。
##        组A / 组B 与 612 PASS 口径不回退；组C PASS 由类返回，因新增类级专项断言「可增不可减」。
##
## 【R20 缺口已补】CombatDataValidator 类自 R2 起未落位工程根；R21 已新写
##   godot/scripts/combat/combat_data_validator.gd（class_name CombatDataValidator, extends
##   RefCounted）。本轮不注册 autoload（project.godot 本轮冻结，无人可写），类由本脚本
##   preload + .new() 真实实例化调用，不依赖场景树 / _ready / autoload 挂载。
##
## 三段门禁由外部命令执行：--import / --check-only --script / --quit；
## 运行：godot --headless --path godot --script res://scripts/verify_frame_data.gd
## 静态：godot --headless --path godot --check-only --script res://scripts/verify_frame_data.gd
## 退出码：quit(0) 仅表示脚本正常执行且数据成功读取；PASS/FAIL 由「实际值 vs 期望值」真实计算，
##        不伪造、不预设结论。不写 courtyard.tscn / project.godot / 其它 Rank 独占件。中文 UTF-8。

const BOSS_TRES := "res://data/combat/boss_01_margit.tres"
const PLAYER_TRES := "res://data/combat/player_actions.tres"
const ENEMY_TRES := "res://data/combat/enemy_01_limgrave_soldier.tres"

# 组C：真实实例化 CombatDataValidator 类（R21 落位 res://scripts/combat/）
const VALIDATOR_SCRIPT = preload("res://scripts/combat/combat_data_validator.gd")

# 组A 期望值：Boss 三招（按 pose key = phase.pose_prefix + move.pose_name 点名）
#   47 / 71 / 91 帧与 hit 区间一并纳入（BOSS-DATA-FINAL.md §3.1/§3.2、数据表schema.md §3/E-2、
#   motion-mapping.md §4.2、接口契约.md M1「p1_ / p2_ 前缀」口径）
const BOSS_POSE_MOVES := {
	"p1_dagger_slash": {"move_id": "move_01_dagger_slash", "startup": 18, "active": 5, "recovery": 24, "total": 47, "hit_start": 18, "hit_end": 23},
	"p1_staff_slam": {"move_id": "move_02_staff_slam", "startup": 30, "active": 7, "recovery": 34, "total": 71, "hit_start": 30, "hit_end": 37},
	"p2_holy_hammer": {"move_id": "move_03_holy_hammer", "startup": 42, "active": 9, "recovery": 40, "total": 91, "hit_start": 42, "hit_end": 51},
}

# 组A 期望值：玩家 8 帧动作（player_actions.tres 真实值 / motion-mapping.md §4.1 / schema §7）
#   total 依 E-2 派生 = startup + active + recovery；hit_end = startup + active（左闭右开）
const PLAYER_ALL_EXPECTED := {
	"action_01_idle": {"startup": 0, "active": 1, "recovery": 0, "total": 1, "hit_end": 1, "inv_start": -1, "inv_end": -1, "priority": 0},
	"action_02_walk": {"startup": 0, "active": 1, "recovery": 0, "total": 1, "hit_end": 1, "inv_start": -1, "inv_end": -1, "priority": 10},
	"action_03_run": {"startup": 0, "active": 1, "recovery": 0, "total": 1, "hit_end": 1, "inv_start": -1, "inv_end": -1, "priority": 20},
	"action_04_roll": {"startup": 4, "active": 9, "recovery": 9, "total": 22, "hit_end": 13, "inv_start": 4, "inv_end": 13, "priority": 60},
	"action_05_attack_light": {"startup": 8, "active": 5, "recovery": 14, "total": 27, "hit_end": 13, "inv_start": -1, "inv_end": -1, "priority": 40},
	"action_06_attack_heavy": {"startup": 20, "active": 8, "recovery": 26, "total": 54, "hit_end": 28, "inv_start": -1, "inv_end": -1, "priority": 45},
	"action_07_hitstun": {"startup": 0, "active": 12, "recovery": 6, "total": 18, "hit_end": 12, "inv_start": -1, "inv_end": -1, "priority": 70},
	"action_08_death": {"startup": 0, "active": 48, "recovery": 0, "total": 48, "hit_end": 48, "inv_start": -1, "inv_end": -1, "priority": 100},
}

# 组A 期望值：翻滚（motion-mapping.md §4.1、战斗系统设计.md §2、schema §7/E-7）
# R19 裁决：改前 4/12/12=28、无敌[4,16) → 改后 4/9/9=22、无敌[4,13)（inv_end=startup+active=13）
const ROLL_EXPECTED := {"startup": 4, "active": 9, "recovery": 9, "inv_start": 4, "inv_end": 13, "total": 22, "logic_fps": 60}

# 组B 期望值：R19 总指挥裁决「4/9/9=22 帧@60、无敌[4,13)」
const DISPATCH_ROLL := {"startup": 4, "active": 9, "recovery": 9, "total": 22, "inv_end": 13, "logic_fps": 60}

var _pass_a := 0
var _fail_a := 0
var _pass_b := 0
var _fail_b := 0
var _pass_c := 0
var _fail_c := 0

# 组C 结果由 CombatDataValidator.validate_all() 返回（checks/pass/fail/errors/e8_max_resistance/status）
var _validator_result: Dictionary = {}


func _initialize() -> void:
	print("==== [R21 VALIDATOR-CLASS VERIFY] START ====")
	var boss = load(BOSS_TRES)
	var player = load(PLAYER_TRES)
	var enemy = load(ENEMY_TRES)
	if boss == null or player == null or enemy == null:
		print("[FATAL] load() 失败 | boss_null=%s player_null=%s enemy_null=%s" % [str(boss == null), str(player == null), str(enemy == null)])
		print("==== [R21 VALIDATOR-CLASS VERIFY] RESULT=LOAD_FAILED ====")
		quit(1)
		return
	print("---- [0] 加载 3 份运行权威 .tres ----")
	print("[0] BOSS   load() OK | path=%s | phases=%d" % [BOSS_TRES, boss.get("phases").size()])
	print("[0] PLAYER load() OK | path=%s | actions=%d" % [PLAYER_TRES, player.get("actions").size()])
	print("[0] ENEMY  load() OK | path=%s | id=%s" % [ENEMY_TRES, String(enemy.get("id"))])

	var pose_moves := _collect_boss_pose_moves(boss)
	var actions_by_id := _collect_actions(player)

	_print_actual(pose_moves, actions_by_id)

	print("---- [3] 组A 玩家 8 帧动作 + Boss 三招 47/71/91 帧与 hit 区间（文档口径逐项核对）----")
	_check_group_a_boss_pose(pose_moves)
	_check_group_a_player_all(actions_by_id)
	_check_group_a_roll(actions_by_id)
	_check_group_a_fps(actions_by_id)

	print("---- [4] 组B 与 R19 裁决值「4/9/9=22、无敌[4,13)」逐项核对（回归，不改数值）----")
	_check_group_b(actions_by_id)

	print("---- [5] 组C 真实实例化 CombatDataValidator 类并调用 validate_all()（R21 落位）----")
	var validator = VALIDATOR_SCRIPT.new()
	_validator_result = validator.validate_all()
	_pass_c = int(_validator_result.get("pass", 0))
	_fail_c = int(_validator_result.get("fail", 0))
	print("[C][类实例] preload=res://scripts/combat/combat_data_validator.gd | 实例有效=%s | validate_all() -> checks=%d pass=%d fail=%d errors=%d status=%s" % [str(is_instance_valid(validator)), int(_validator_result.get("checks", 0)), _pass_c, _fail_c, (_validator_result.get("errors", []) as Array).size(), String(_validator_result.get("status", ""))])
	print("[C][声明] 组C 由 preload(res://scripts/combat/combat_data_validator.gd).new() 真实实例化 CombatDataValidator 并调用 validate_all() 取得，已替换 R20 的 §9 等价校验同跑；组A/组B 与 612 PASS 口径未回退。")

	print("==== [R21 VALIDATOR-CLASS VERIFY] SUMMARY ====")
	var pa := _pass_a
	var fa := _fail_a
	var pb := _pass_b
	var fb := _fail_b
	var pc := _pass_c
	var fc := _fail_c
	print("  组A 文档/帧数据核对 | DOC_PASS=%d DOC_FAIL=%d -> %s" % [pa, fa, "DOC_CONSISTENCY=PASS" if fa == 0 else "DOC_CONSISTENCY=FAIL"])
	print("  组B R19 裁决值 | VERDICT_PASS=%d VERDICT_FAIL=%d -> %s" % [pb, fb, "MATCH" if fb == 0 else "MISMATCH"])
	print("  组C CombatDataValidator.validate_all()（类级真实实例化） | VALIDATOR_CHECKS=%d VALIDATOR_PASS=%d VALIDATOR_FAIL=%d -> VALIDATOR_ERROR=%d" % [int(_validator_result.get("checks", pc + fc)), pc, fc, fc])
	print("  合计 | PASS_COUNT=%d FAIL_COUNT=%d" % [pa + pb + pc, fa + fb + fc])
	print("  E-8 max_resistance (bleed/poison/frost) = %s" % String(_validator_result.get("e8_max_resistance", "N/A")))
	var verdict := "SEE_ABOVE"
	if fa == 0 and fb == 0 and fc == 0:
		verdict = "ALL_MATCH"
	elif fc > 0:
		verdict = "VALIDATOR_ERROR_NONZERO"
	elif fb > 0:
		verdict = "ROLL_FRAME_MISMATCH_VS_R19_VERDICT"
	elif fa > 0:
		verdict = "FRAME_DATA_MISMATCH"
	print("  RESULT=%s" % verdict)
	print("  NOTE: quit(0)=脚本执行/读取成功；PASS/FAIL 由实际值 vs 期望值真实计算，不预设结论；不写 courtyard.tscn / project.godot / 其它 Rank 独占件；组A/组B 不回退。")
	print("==== [R21 VALIDATOR-CLASS VERIFY] END ====")
	quit(0)


# ---------------------------------------------------------------- 采集
# pose key = phase.pose_prefix + move.pose_name（p1_dagger_slash / p1_staff_slam / p2_holy_hammer）
func _collect_boss_pose_moves(boss: Variant) -> Dictionary:
	var out := {}
	for ph in boss.get("phases"):
		var prefix := String(ph.get("pose_prefix"))
		for mv in ph.get("moves"):
			var key := prefix + String(mv.get("pose_name"))
			if not out.has(key):
				out[key] = mv
	return out


func _collect_actions(player: Variant) -> Dictionary:
	var out := {}
	for ac in player.get("actions"):
		out[String(ac.get("id"))] = ac
	return out


# ---------------------------------------------------------------- 实际值快照
func _print_actual(pose_moves: Dictionary, actions_by_id: Dictionary) -> void:
	print("---- [1] 实际值快照：Boss 三招（pose key 口径，按 id 去重）----")
	var keys := pose_moves.keys()
	keys.sort()
	for key in keys:
		var mv = pose_moves[key]
		var s := int(mv.get("startup_frames"))
		var a := int(mv.get("active_frames"))
		var r := int(mv.get("recovery_frames"))
		print("[ACTUAL][BOSS] pose=%s | move_id=%s | startup=%d active=%d recovery=%d | total(derived)=%d | hit=[%d,%d)" % [key, String(mv.get("id")), s, a, r, s + a + r, s, s + a])
	print("[ACTUAL][BOSS] pose_keys=%s" % str(keys))
	print("---- [2] 实际值快照：玩家 8 帧动作 ----")
	var ids := actions_by_id.keys()
	ids.sort()
	for aid in ids:
		var ac = actions_by_id[aid]
		var s := int(ac.get("startup_frames"))
		var a := int(ac.get("active_frames"))
		var r := int(ac.get("recovery_frames"))
		var ist := int(ac.get("invulnerable_start_frame"))
		var ien := int(ac.get("invulnerable_end_frame"))
		print("[ACTUAL][PLAYER] id=%s | startup=%d active=%d recovery=%d | inv=[%d,%d) | logic_fps=%d | total(derived)=%d | hit=[%d,%d)" % [aid, s, a, r, ist, ien, int(ac.get("logic_fps")), s + a + r, s, s + a])
	var fps_list := []
	var prio_list := []
	for aid in ids:
		fps_list.append(int(actions_by_id[aid].get("logic_fps")))
		prio_list.append(int(actions_by_id[aid].get("state_priority")))
	print("[ACTUAL][PLAYER] actions=%d | logic_fps=%s | state_priority=%s" % [ids.size(), str(fps_list), str(prio_list)])
	print("[ACTUAL][ENGINE] physics_ticks_per_second=%d" % Engine.physics_ticks_per_second)


# ---------------------------------------------------------------- 组A：帧数据核对
func _check_group_a_boss_pose(pose_moves: Dictionary) -> void:
	var keys := BOSS_POSE_MOVES.keys()
	keys.sort()
	for key in keys:
		var exp = BOSS_POSE_MOVES[key]
		var src := "BOSS-DATA-FINAL §3.1/§3.2、schema §3/E-2、motion-mapping §4.2、接口契约 M1"
		if not pose_moves.has(key):
			_check("A", "%s 存在(pose key)" % key, "MISSING", "present", src)
			continue
		var mv = pose_moves[key]
		var s := int(mv.get("startup_frames"))
		var a := int(mv.get("active_frames"))
		var r := int(mv.get("recovery_frames"))
		_check("A", "%s 存在(pose key)" % key, "present", "present", src)
		_check("A", "%s -> move_id" % key, String(mv.get("id")), String(exp["move_id"]), src)
		_check("A", "%s.startup_frames(前摇)" % key, s, int(exp["startup"]), src)
		_check("A", "%s.active_frames(判定)" % key, a, int(exp["active"]), src)
		_check("A", "%s.recovery_frames(后摇)" % key, r, int(exp["recovery"]), src)
		_check("A", "%s.total=startup+active+recovery(派生)" % key, s + a + r, int(exp["total"]), "BOSS-DATA-FINAL §3.2 / schema E-2")
		_check("A", "%s 判定区间 start==startup" % key, s, int(exp["hit_start"]), "schema §3/E-2")
		_check("A", "%s 判定区间 end==startup+active(hit=[%d,%d))" % [key, s, s + a], s + a, int(exp["hit_end"]), "schema §3/E-2")


func _check_group_a_player_all(actions_by_id: Dictionary) -> void:
	var ids := PLAYER_ALL_EXPECTED.keys()
	ids.sort()
	var src := "player_actions.tres / motion-mapping §4.1 / 数据表schema §7/E-2"
	for aid in ids:
		var exp = PLAYER_ALL_EXPECTED[aid]
		if not actions_by_id.has(aid):
			_check("A", "%s 存在" % aid, "MISSING", "present", src)
			continue
		var ac = actions_by_id[aid]
		var s := int(ac.get("startup_frames"))
		var a := int(ac.get("active_frames"))
		var r := int(ac.get("recovery_frames"))
		_check("A", "%s.startup_frames" % aid, s, int(exp["startup"]), src)
		_check("A", "%s.active_frames" % aid, a, int(exp["active"]), src)
		_check("A", "%s.recovery_frames" % aid, r, int(exp["recovery"]), src)
		_check("A", "%s.total(派生)=s+a+r" % aid, s + a + r, int(exp["total"]), "schema E-2")
		_check("A", "%s 判定区间 end=startup+active" % aid, s + a, int(exp["hit_end"]), "schema §3/E-2")
		_check("A", "%s.invulnerable_start_frame" % aid, int(ac.get("invulnerable_start_frame")), int(exp["inv_start"]), src)
		_check("A", "%s.invulnerable_end_frame" % aid, int(ac.get("invulnerable_end_frame")), int(exp["inv_end"]), src)
		_check("A", "%s.logic_fps(@60)" % aid, int(ac.get("logic_fps")), 60, "schema §7 / E-6")
		_check("A", "%s.state_priority" % aid, int(ac.get("state_priority")), int(exp["priority"]), "schema §7 / E-6")


func _check_group_a_roll(actions_by_id: Dictionary) -> void:
	if not actions_by_id.has("action_04_roll"):
		_check("A", "action_04_roll 存在", "MISSING", "present", "motion-mapping §4.1")
		return
	var ac = actions_by_id["action_04_roll"]
	var s := int(ac.get("startup_frames"))
	var a := int(ac.get("active_frames"))
	var r := int(ac.get("recovery_frames"))
	var ist := int(ac.get("invulnerable_start_frame"))
	var ien := int(ac.get("invulnerable_end_frame"))
	var fps := int(ac.get("logic_fps"))
	var total := s + a + r
	var src := "motion-mapping §4.1 / 战斗系统设计 §2 / schema §7"
	_check("A", "roll.startup_frames", s, int(ROLL_EXPECTED["startup"]), src)
	_check("A", "roll.active_frames(无敌段)", a, int(ROLL_EXPECTED["active"]), src)
	_check("A", "roll.recovery_frames", r, int(ROLL_EXPECTED["recovery"]), src)
	_check("A", "roll.invulnerable_start_frame", ist, int(ROLL_EXPECTED["inv_start"]), src)
	_check("A", "roll.invulnerable_end_frame", ien, int(ROLL_EXPECTED["inv_end"]), src)
	_check("A", "roll.logic_fps(@60)", fps, int(ROLL_EXPECTED["logic_fps"]), "schema §7 / E-6")
	_check("A", "roll.total=4+9+9", total, int(ROLL_EXPECTED["total"]), "战斗系统设计 §2.2 / schema E-7")
	_check("A", "E-7 inv_start==startup", ist, s, "schema E-7")
	_check("A", "E-7 inv_end==startup+active", ien, s + a, "schema E-7")
	_check("A", "E-7 inv_len(end-start)==active", ien - ist, a, "战斗系统设计 §2.2 / schema E-7")
	_check("A", "E-7 0<=start<end<=total", (ist >= 0 and ist < ien and ien <= total), true, "schema E-7")


func _check_group_a_fps(actions_by_id: Dictionary) -> void:
	var ids := actions_by_id.keys()
	ids.sort()
	var fps_all_60 := true
	var prio_seen := {}
	var prio_distinct := true
	for aid in ids:
		var ac = actions_by_id[aid]
		if int(ac.get("logic_fps")) != 60:
			fps_all_60 = false
		var p := int(ac.get("state_priority"))
		if prio_seen.has(p):
			prio_distinct = false
		prio_seen[p] = true
	_check("A", "E-6 8 条动作齐全(actions==8)", ids.size(), 8, "schema §7 / E-6")
	_check("A", "E-6 8 条 logic_fps 全=60(@60)", fps_all_60, true, "schema §7 / E-6")
	_check("A", "E-6 state_priority 互异", prio_distinct, true, "schema E-6")
	_check("A", "E-6 logic_fps==Engine.physics_ticks_per_second", Engine.physics_ticks_per_second, 60, "schema §7")


# ---------------------------------------------------------------- 组B：R19 裁决值核对
func _check_group_b(actions_by_id: Dictionary) -> void:
	if not actions_by_id.has("action_04_roll"):
		_check("B", "action_04_roll 存在", "MISSING", "present", "R19 裁决")
		return
	var ac = actions_by_id["action_04_roll"]
	var s := int(ac.get("startup_frames"))
	var a := int(ac.get("active_frames"))
	var r := int(ac.get("recovery_frames"))
	var ien := int(ac.get("invulnerable_end_frame"))
	var fps := int(ac.get("logic_fps"))
	var total := s + a + r
	var src := "R19 裁决 4/9/9=22、无敌[4,13)"
	_check("B", "roll.startup_frames", s, int(DISPATCH_ROLL["startup"]), src)
	_check("B", "roll.active_frames", a, int(DISPATCH_ROLL["active"]), src)
	_check("B", "roll.recovery_frames", r, int(DISPATCH_ROLL["recovery"]), src)
	_check("B", "roll.total", total, int(DISPATCH_ROLL["total"]), src)
	_check("B", "roll.invulnerable_end_frame(按E-7:4+9=13)", ien, int(DISPATCH_ROLL["inv_end"]), src)
	_check("B", "roll.logic_fps(@60)", fps, int(DISPATCH_ROLL["logic_fps"]), src)


# ---------------------------------------------------------------- 工具
func _check(group: String, label: String, actual: Variant, expected: Variant, src: String) -> void:
	var ok: bool = (actual == expected)
	if group == "A":
		if ok:
			_pass_a += 1
		else:
			_fail_a += 1
	elif group == "B":
		if ok:
			_pass_b += 1
		else:
			_fail_b += 1
	else:
		if ok:
			_pass_c += 1
		else:
			_fail_c += 1
	print("  [%s][组%s] %s | 实际=%s 期望=%s | 来源=%s" % ["PASS" if ok else "FAIL", group, label, str(actual), str(expected), src])
