extends SceneTree
## R19 / cmd-20261109-102334-084-A2 · Rank-2 战斗帧数据核对（真跑）
##
## 真读两份运行权威 .tres，逐项打印「实际值 / 期望值 / PASS|FAIL」：
##   组A：与 BOSS-DATA-FINAL.md / 数据表schema.md / motion-mapping.md 文档口径逐项核对
##   组B：与 R19 总指挥裁决值「4/9/9=22、无敌[4,13)」逐项核对
##   （裁决依据 00-汇总.md §5 M1 验收；本轮 .tres 与文档口径均已按裁决修正后复跑）
##
## 覆盖：Boss 三招 前摇/判定/后摇 + 派生 total/判定区间；翻滚无敌帧 + E-7 等式；
##       攻击帧数据(light/heavy) + 派生 total/判定区间；8 条 logic_fps 全等(E-6)。
##
## 三段门禁由外部命令执行：--import / --check-only --script / --quit；
## 本脚本为门禁第 2 段与主真跑(--script)的共同载体，不自检门禁本身。
## 运行：godot --headless --path godot --script res://scripts/verify_frame_data.gd
## 静态：godot --headless --path godot --check-only --script res://scripts/verify_frame_data.gd
##
## 退出码：quit(0) 表示脚本正常执行且数据成功读取；PASS/FAIL 由逐项「实际值 vs 期望值」
##        真实计算得出，不伪造、不预设结论。Boss 三招数值本轮未改动，仅核对未受影响。
##        不写 courtyard.tscn。中文 UTF-8 / Godot 4 合法语法。

const BOSS_TRES := "res://data/combat/boss_01_margit.tres"
const PLAYER_TRES := "res://data/combat/player_actions.tres"

# 组A 期望值：Boss 三招（BOSS-DATA-FINAL.md §3.1/§3.2、数据表schema.md §3/E-2）
const BOSS_MOVES := {
	"move_01_dagger_slash": {"startup": 18, "active": 5, "recovery": 24, "total": 47, "hit_end": 23},
	"move_02_staff_slam": {"startup": 30, "active": 7, "recovery": 34, "total": 71, "hit_end": 37},
	"move_03_holy_hammer": {"startup": 42, "active": 9, "recovery": 40, "total": 91, "hit_end": 51}
}
# 组A 期望值：翻滚（motion-mapping.md §4.1、战斗系统设计.md §2、schema §7/E-7）
# R19 裁决：改前 4/12/12=28、无敌[4,16) → 改后 4/9/9=22、无敌[4,13)（inv_end=startup+active=13）
const ROLL_EXPECTED := {"startup": 4, "active": 9, "recovery": 9, "inv_start": 4, "inv_end": 13, "total": 22, "logic_fps": 60}
# 组A 期望值：攻击帧（motion-mapping.md §4.1）
const ATTACK_EXPECTED := {
	"action_05_attack_light": {"startup": 8, "active": 5, "recovery": 14, "total": 27, "hit_end": 13},
	"action_06_attack_heavy": {"startup": 20, "active": 8, "recovery": 26, "total": 54, "hit_end": 28}
}
# 组B 期望值：R19 总指挥裁决「4/9/9=22 帧@60、无敌[4,13)」（inv_end 按 E-7 派生 = startup4+active9 = 13）
const DISPATCH_ROLL := {"startup": 4, "active": 9, "recovery": 9, "total": 22, "inv_end": 13, "logic_fps": 60}

var _doc_pass := 0
var _doc_fail := 0
var _disp_pass := 0
var _disp_fail := 0


func _initialize() -> void:
	print("==== [R19 FRAME DATA VERIFY] START ====")
	var boss = load(BOSS_TRES)
	var player = load(PLAYER_TRES)
	if boss == null or player == null:
		print("[FATAL] load() 失败 | boss_null=%s player_null=%s" % [str(boss == null), str(player == null)])
		print("==== [R19 FRAME DATA VERIFY] RESULT=LOAD_FAILED ====")
		quit(1)
		return
	var boss_phases = boss.get("phases")
	var player_actions = player.get("actions")
	print("---- [0] 加载两份运行权威 .tres ----")
	print("[0] BOSS   load() OK | path=%s | phases=%d" % [BOSS_TRES, boss_phases.size()])
	print("[0] PLAYER load() OK | path=%s | actions=%d" % [PLAYER_TRES, player_actions.size()])

	var moves_by_id := _collect_boss_moves(boss)
	var actions_by_id := _collect_actions(player)

	_print_actual(moves_by_id, actions_by_id)

	print("---- [3] 组A 与 BOSS-DATA-FINAL.md / 数据表schema.md / motion-mapping.md 逐项核对 ----")
	_check_group_a_boss(moves_by_id)
	_check_group_a_roll(actions_by_id)
	_check_group_a_attack(actions_by_id)
	_check_group_a_fps(actions_by_id)

	print("---- [4] 组B 与 R19 裁决值「4/9/9=22、无敌[4,13)」逐项核对 ----")
	_check_group_b(actions_by_id)

	print("==== [R19 FRAME DATA VERIFY] SUMMARY ====")
	print("  组A 文档核对 | DOC_PASS=%d DOC_FAIL=%d -> %s" % [_doc_pass, _doc_fail, "DOC_CONSISTENCY=PASS" if _doc_fail == 0 else "DOC_CONSISTENCY=FAIL"])
	print("  组B 裁决值 | VERDICT_PASS=%d VERDICT_FAIL=%d -> %s" % [_disp_pass, _disp_fail, "MATCH" if _disp_fail == 0 else "MISMATCH"])
	print("  合计 | PASS_COUNT=%d FAIL_COUNT=%d" % [_doc_pass + _disp_pass, _doc_fail + _disp_fail])
	var verdict := "SEE_ABOVE"
	if _doc_fail == 0 and _disp_fail == 0:
		verdict = "ALL_MATCH"
	elif _disp_fail > 0:
		verdict = "ROLL_FRAME_MISMATCH_VS_R19_VERDICT"
	elif _doc_fail > 0:
		verdict = "DOC_CONSISTENCY_FAIL"
	print("  RESULT=%s" % verdict)
	print("  NOTE: quit(0)=脚本执行/读取成功；PASS/FAIL 由实际值 vs 期望值真实计算，不预设结论；不写 courtyard.tscn。")
	print("==== [R19 FRAME DATA VERIFY] END ====")
	quit(0)


# ---------------------------------------------------------------- 采集
func _collect_boss_moves(boss: Variant) -> Dictionary:
	var out := {}
	for ph in boss.get("phases"):
		for mv in ph.get("moves"):
			var mid := String(mv.get("id"))
			if not out.has(mid):
				out[mid] = mv
	return out


func _collect_actions(player: Variant) -> Dictionary:
	var out := {}
	for ac in player.get("actions"):
		out[String(ac.get("id"))] = ac
	return out


# ---------------------------------------------------------------- 实际值快照
func _print_actual(moves_by_id: Dictionary, actions_by_id: Dictionary) -> void:
	print("---- [1] 实际值快照：Boss 三招（phases[*].moves 按 id 去重）----")
	var ids := moves_by_id.keys()
	ids.sort()
	for mid in ids:
		var mv = moves_by_id[mid]
		var s := int(mv.get("startup_frames"))
		var a := int(mv.get("active_frames"))
		var r := int(mv.get("recovery_frames"))
		print("[ACTUAL][BOSS] id=%s | startup=%d active=%d recovery=%d | total(derived)=%d | hit=[%d,%d)" % [String(mid), s, a, r, s + a + r, s, s + a])
	print("---- [2] 实际值快照：player_actions 关键动作 ----")
	for aid in ["action_04_roll", "action_05_attack_light", "action_06_attack_heavy"]:
		if not actions_by_id.has(aid):
			print("[ACTUAL][PLAYER] id=%s MISSING" % aid)
			continue
		var ac = actions_by_id[aid]
		var s := int(ac.get("startup_frames"))
		var a := int(ac.get("active_frames"))
		var r := int(ac.get("recovery_frames"))
		var ist := int(ac.get("invulnerable_start_frame"))
		var ien := int(ac.get("invulnerable_end_frame"))
		var fps := int(ac.get("logic_fps"))
		print("[ACTUAL][PLAYER] id=%s | startup=%d active=%d recovery=%d | inv=[%d,%d) | logic_fps=%d | total(derived)=%d | hit=[%d,%d)" % [aid, s, a, r, ist, ien, fps, s + a + r, s, s + a])
	var all_ids := actions_by_id.keys()
	all_ids.sort()
	var fps_list := []
	var prio_list := []
	for aid in all_ids:
		fps_list.append(int(actions_by_id[aid].get("logic_fps")))
		prio_list.append(int(actions_by_id[aid].get("state_priority")))
	print("[ACTUAL][PLAYER] actions=%d | ids=%s" % [all_ids.size(), str(all_ids)])
	print("[ACTUAL][PLAYER] 8 条 logic_fps=%s | state_priority=%s" % [str(fps_list), str(prio_list)])
	print("[ACTUAL][ENGINE] physics_ticks_per_second=%d" % Engine.physics_ticks_per_second)


# ---------------------------------------------------------------- 组A：文档核对
func _check_group_a_boss(moves_by_id: Dictionary) -> void:
	var ids := BOSS_MOVES.keys()
	ids.sort()
	for mid in ids:
		var exp = BOSS_MOVES[mid]
		if not moves_by_id.has(mid):
			_check("A", "%s 存在" % mid, "MISSING", "present", "BOSS-DATA-FINAL §3.1")
			continue
		var mv = moves_by_id[mid]
		var s := int(mv.get("startup_frames"))
		var a := int(mv.get("active_frames"))
		var r := int(mv.get("recovery_frames"))
		var src := "BOSS-DATA-FINAL §3.1/§3.2、schema §3/E-2"
		_check("A", "%s.startup_frames(前摇)" % mid, s, int(exp["startup"]), src)
		_check("A", "%s.active_frames(判定)" % mid, a, int(exp["active"]), src)
		_check("A", "%s.recovery_frames(后摇)" % mid, r, int(exp["recovery"]), src)
		_check("A", "%s.total=startup+active+recovery(派生)" % mid, s + a + r, int(exp["total"]), "BOSS-DATA-FINAL §3.2 / schema E-2")
		_check("A", "%s 判定区间 end=startup+active" % mid, s + a, int(exp["hit_end"]), "schema §3/E-2")


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


func _check_group_a_attack(actions_by_id: Dictionary) -> void:
	var ids := ATTACK_EXPECTED.keys()
	ids.sort()
	for aid in ids:
		var exp = ATTACK_EXPECTED[aid]
		if not actions_by_id.has(aid):
			_check("A", "%s 存在" % aid, "MISSING", "present", "motion-mapping §4.1")
			continue
		var ac = actions_by_id[aid]
		var s := int(ac.get("startup_frames"))
		var a := int(ac.get("active_frames"))
		var r := int(ac.get("recovery_frames"))
		var src := "motion-mapping §4.1 / schema §7/E-2"
		_check("A", "%s.startup_frames(前摇)" % aid, s, int(exp["startup"]), src)
		_check("A", "%s.active_frames(判定)" % aid, a, int(exp["active"]), src)
		_check("A", "%s.recovery_frames(后摇)" % aid, r, int(exp["recovery"]), src)
		_check("A", "%s.total(派生)" % aid, s + a + r, int(exp["total"]), "schema E-2")
		_check("A", "%s 判定区间 end=startup+active" % aid, s + a, int(exp["hit_end"]), "schema §3/E-2")


func _check_group_a_fps(actions_by_id: Dictionary) -> void:
	var all_ids := actions_by_id.keys()
	all_ids.sort()
	var fps_all_60 := true
	var prio_seen := {}
	var prio_distinct := true
	for aid in all_ids:
		var ac = actions_by_id[aid]
		if int(ac.get("logic_fps")) != 60:
			fps_all_60 = false
		var p := int(ac.get("state_priority"))
		if prio_seen.has(p):
			prio_distinct = false
		prio_seen[p] = true
	_check("A", "E-6 8 条动作齐全(actions==8)", all_ids.size(), 8, "schema §7 / E-6")
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
			_doc_pass += 1
		else:
			_doc_fail += 1
	else:
		if ok:
			_disp_pass += 1
		else:
			_disp_fail += 1
	print("  [%s][组%s] %s | 实际=%s 期望=%s | 来源=%s" % ["PASS" if ok else "FAIL", group, label, str(actual), str(expected), src])
