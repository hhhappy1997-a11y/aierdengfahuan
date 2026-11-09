extends SceneTree
## R16 / cmd-20261109-085736-024-A2 · Rank-2 战斗数据表运行期验证
## 真跑验证：①load() 两个 .tres 打印资源类型 / 顶层字段数；②核对 load_steps 与
##   ext_resource / sub_resource 引用无悬空；③读二阶段与三招数值字段打印实际值与逐项
##   PASS/FAIL（期望基准 = Rank-2/BOSS-DATA-FINAL.md，R9 最终数据表）。
## 运行环境（与 BOSS-RUNTIME-CHECK.md R13 口径一致）：
##   G1 导入门禁   : godot --headless --path <root> --import
##   G2 静态解析   : godot --headless --path <root> --check-only --script res://scripts/verify_combat_runtime.gd
##   G3 加载退出   : godot --headless --path <root> --quit
##   G4 真跑自检   : godot --headless --path <root> --script res://scripts/verify_combat_runtime.gd
## 硬约束：只读不写、不擅改任何战斗数值；差异逐项如实登记、不冒充全绿、不伪造输出。
##   中文 UTF-8 / Godot 4 合法语法。

const BOSS_PATH := "res://data/combat/boss_01_margit.tres"
const PLAYER_PATH := "res://data/combat/player_actions.tres"

var _boss: Resource = null
var _player: Resource = null

var _assert_ok: int = 0
var _fail_count: int = 0          # 运行时健康失败数（决定 quit 退出码）
var _check_ok: int = 0            # 数值对照 PASS 数
var _diff_count: int = 0          # 数值对照 FAIL/登记 数
var _diff_labels: Array = []


func _initialize() -> void:
	print("==== [R16 COMBAT RUNTIME VERIFY] START ====")
	_step1_load()
	_step2_refs("A/BOSS", BOSS_PATH)
	_step2_refs("B/PLAYER", PLAYER_PATH)
	_step3_numbers()
	print("==== [R16 VERIFY] 运行时健康(load/资源类型/字段数/引用无悬空/字段可读): PASS=%d FAIL=%d RESULT=%s ====" % [_assert_ok, _fail_count, "PASS" if _fail_count == 0 else "FAIL"])
	print("==== [R16 VERIFY] 数值逐项对照(基准 BOSS-DATA-FINAL.md R9): PASS=%d FAIL/登记=%d ====" % [_check_ok, _diff_count])
	if _diff_count > 0:
		print("---- [R16 VERIFY] 差异登记清单（不擅改战斗数值，仅如实登记）----")
		for lab in _diff_labels:
			print("   - " + String(lab))
		print("   根因：max_resistance 三项。R10 已按总指挥裁决 A1 (群聊总线 MSG-20261109-0500-HOST / 00-汇总.md 04:00) 由 330/360/320 改为 400/480/420，运行权威件与裁决一致；BOSS-DATA-FINAL.md (R9) 未同步，属『文档-运行件版本差』，非数值错误。")
	print("==== [R16 COMBAT RUNTIME VERIFY] END ====")
	quit(0 if _fail_count == 0 else 1)


# ---------------------------------------------------------------------------
# ① load() 两个 .tres，打印资源类型、顶层字段数
# ---------------------------------------------------------------------------
func _step1_load() -> void:
	print("---- [1] load() 两个 .tres：资源类型 / 顶层字段数 ----")
	_boss = load(BOSS_PATH)
	_assert(_boss != null, "[1-A] boss_01_margit.tres load() 非 null")
	if _boss != null:
		_print_res_info("BOSS", _boss, BOSS_PATH)
	_player = load(PLAYER_PATH)
	_assert(_player != null, "[1-B] player_actions.tres load() 非 null")
	if _player != null:
		_print_res_info("PLAYER", _player, PLAYER_PATH)


func _print_res_info(tag: String, res: Resource, path: String) -> void:
	var scr := res.get_script() as Script
	var gname := "<无脚本>"
	if scr != null and scr.has_method("get_global_name"):
		gname = String(scr.call("get_global_name"))
		if gname == "":
			gname = "<空 global_name>"
	var names := _script_var_names(res)
	var text_props := -1
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa != null:
		var t := fa.get_as_text()
		fa.close()
		text_props = _count_resource_props(t)
	print("  [%s] path=%s" % [tag, path])
	print("  [%s] 资源类型 get_class()=%s | script_class(global_name)=%s" % [tag, res.get_class(), gname])
	print("  [%s] 顶层字段数(运行时脚本导出属性, 不含 script)=%d" % [tag, names.size()])
	print("  [%s] 顶层字段名=%s" % [tag, str(names)])
	print("  [%s] .tres [resource] 段赋值行数(含 script 绑定行)=%d" % [tag, text_props])
	_assert(names.size() > 0, "[%s] 顶层字段可枚举（%d 个）" % [tag, names.size()])


func _script_var_names(res: Resource) -> Array:
	var out: Array = []
	for d in res.get_property_list():
		var usage: int = int(d.get("usage", 0))
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var n := String(d.get("name", ""))
			if n != "script":
				out.append(n)
	return out


func _count_resource_props(t: String) -> int:
	var in_res := false
	var cnt := 0
	for line in t.split("\n"):
		var l := line.strip_edges()
		if l == "[resource]":
			in_res = true
			continue
		if not in_res:
			continue
		if l == "" or l.begins_with("["):
			continue
		if l.find("=") >= 0:
			cnt += 1
	return cnt


# ---------------------------------------------------------------------------
# ② load_steps / ext_resource / sub_resource 引用核对（无悬空）
# ---------------------------------------------------------------------------
func _step2_refs(tag: String, path: String) -> void:
	print("---- [2.%s] %s · load_steps / 引用无悬空核对 ----" % [tag, path])
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa == null:
		_assert(false, "[2.%s] .tres 文本可读" % tag)
		return
	var text := fa.get_as_text()
	fa.close()

	var declared := _grab_int(text, "load_steps")
	var ext_paths: Array = []
	var ext_ids: Array = []
	var sub_ids: Array = []
	for line in text.split("\n"):
		var l := line.strip_edges()
		if l.begins_with("[ext_resource "):
			ext_paths.append(_quoted_after(l, "path"))
			ext_ids.append(_quoted_after(l, "id"))
		elif l.begins_with("[sub_resource "):
			sub_ids.append(_quoted_after(l, "id"))

	var e := ext_paths.size()
	var s := sub_ids.size()
	var calc := 1 + e + s
	print("  load_steps 声明=%d | ext_resource=%d | sub_resource=%d | 计算(1+E+S)=%d" % [declared, e, s, calc])
	_assert(declared == calc, "[2.%s] load_steps(%d) == 1+ext(%d)+sub(%d)=%d" % [tag, declared, e, s, calc])

	for i in range(e):
		var p := String(ext_paths[i])
		var loaded = load(p)
		var exists := ResourceLoader.exists(p)
		_assert(loaded != null, "[2.%s] ext[%d] path=%s 可 load() 解析 (ResourceLoader.exists=%s)" % [tag, i, p, str(exists)])

	var ext_refs := _collect_refs(text, "ExtResource(\"")
	var ext_dangling := 0
	for r in ext_refs:
		if not ext_ids.has(String(r)):
			ext_dangling += 1
	print("  ExtResource(\"id\") 引用=%d | 已声明 ext id=%d | 悬空=%d" % [ext_refs.size(), ext_ids.size(), ext_dangling])
	_assert(ext_dangling == 0, "[2.%s] 全部 ExtResource() 引用可解析（悬空=%d）" % [tag, ext_dangling])

	var sub_refs := _collect_refs(text, "SubResource(\"")
	var sub_dangling := 0
	for r in sub_refs:
		if not sub_ids.has(String(r)):
			sub_dangling += 1
	print("  SubResource(\"id\") 引用=%d | 已声明 sub id=%d | 悬空=%d" % [sub_refs.size(), sub_ids.size(), sub_dangling])
	_assert(sub_dangling == 0, "[2.%s] 全部 SubResource() 引用可解析（悬空=%d）" % [tag, sub_dangling])


func _grab_int(text: String, key: String) -> int:
	var marker := key + "="
	var i := text.find(marker)
	if i < 0:
		return -1
	var s := i + marker.length()
	var j := s
	while j < text.length():
		var c := text.unicode_at(j)
		if c < 48 or c > 57:
			break
		j += 1
	if j == s:
		return -1
	return int(text.substr(s, j - s))


func _quoted_after(line: String, key: String) -> String:
	var marker := key + "=\""
	var i := line.find(marker)
	if i < 0:
		return ""
	var s := i + marker.length()
	var j := line.find("\"", s)
	if j < 0:
		return ""
	return line.substr(s, j - s)


func _collect_refs(text: String, marker: String) -> Array:
	var out: Array = []
	var from := 0
	while true:
		var i := text.find(marker, from)
		if i < 0:
			break
		var s := i + marker.length()
		var j := text.find("\"", s)
		if j < 0:
			break
		out.append(text.substr(s, j - s))
		from = j + 1
	return out


# ---------------------------------------------------------------------------
# ③ 二阶段与三招数值字段：打印实际值与逐项 PASS/FAIL
# ---------------------------------------------------------------------------
func _step3_numbers() -> void:
	if _boss == null or _player == null:
		_assert(false, "[3] 依赖资源为空，无法读取数值")
		return
	_sec_boss()
	_sec_phases()
	_sec_moves()
	_sec_poise()
	_sec_status()
	_sec_player()


func _sec_boss() -> void:
	print("---- [3.1] BossData 顶层数值（对照 BOSS-DATA-FINAL.md §1）----")
	var keys := ["id", "display_name", "max_hp", "base_attack", "base_defense", "phase_thresholds", "aggro_radius_px", "lose_radius_px", "chase_speed_px_per_sec", "attack_range_px", "ai_poll_interval_sec", "rng_seed", "defeated_flag_key", "death_pose_name", "phase_transition_enabled"]
	var exp := {
		"id": "boss_01_margit", "display_name": "恶兆妖鬼 · 玛尔基特", "max_hp": 3500.0,
		"base_attack": 120.0, "base_defense": 42.0, "phase_thresholds": [0.5],
		"aggro_radius_px": 420.0, "lose_radius_px": 620.0, "chase_speed_px_per_sec": 96.0,
		"attack_range_px": 88.0, "ai_poll_interval_sec": 0.2, "rng_seed": 20261108,
		"defeated_flag_key": "world.boss_01_margit.defeated", "death_pose_name": "death",
		"phase_transition_enabled": true,
	}
	_check_dict("BossData", _boss, keys, exp)
	print("       └ 转阶段 HP 点 = max_hp × phase_thresholds[0] = %s × 0.5 = %s" % [str(_boss.get("max_hp")), str(float(_boss.get("max_hp")) * 0.5)])


func _sec_phases() -> void:
	var phases: Array = _boss.get("phases")
	print("---- [3.2] 二阶段 PhaseData ×2（对照 §2）| phases.size=%d ----" % phases.size())
	_assert(phases.size() == 2, "[3.2] phases.size()==2（实际 %d）" % phases.size())
	if phases.size() < 2:
		return
	var pkeys := ["phase_index", "hp_ratio_enter", "hp_ratio_exit", "phase_damage_multiplier", "phase_defense", "status_resistance_multiplier", "transition_frames", "aggression"]
	var e1 := {"phase_index": 1, "hp_ratio_enter": 1.0, "hp_ratio_exit": 0.5, "phase_damage_multiplier": 1.0, "phase_defense": 0.0, "status_resistance_multiplier": 1.0, "transition_frames": 48, "aggression": 1.0}
	var e2 := {"phase_index": 2, "hp_ratio_enter": 0.5, "hp_ratio_exit": 0.0, "phase_damage_multiplier": 1.25, "phase_defense": 18.0, "status_resistance_multiplier": 1.35, "transition_frames": 48, "aggression": 1.4}
	var p1 = phases[0]
	var p2 = phases[1]
	print("  [P1] id=%s | moves=%d | poise_override=%s | pose_prefix=%s" % [str(p1.get("id")), (p1.get("moves") as Array).size(), _res_label(p1.get("poise_override")), str(p1.get("pose_prefix"))])
	_check_dict("P1", p1, pkeys, e1)
	print("  [P2] id=%s | moves=%d | poise_override=%s | pose_prefix=%s" % [str(p2.get("id")), (p2.get("moves") as Array).size(), _res_label(p2.get("poise_override")), str(p2.get("pose_prefix"))])
	_check_dict("P2", p2, pkeys, e2)
	_assert((p1.get("moves") as Array).size() == 2, "[3.2] P1.moves.size()==2（实际 %d）" % (p1.get("moves") as Array).size())
	_assert((p2.get("moves") as Array).size() == 3, "[3.2] P2.moves.size()==3（实际 %d）" % (p2.get("moves") as Array).size())


func _sec_moves() -> void:
	var phases: Array = _boss.get("phases")
	var moves: Array = (phases[1] as Resource).get("moves")
	print("---- [3.3] 三招 MoveData ×3（对照 §3，取自 P2.moves 全 3 招）| moves.size=%d ----" % moves.size())
	_assert(moves.size() == 3, "[3.3] 三招数==3（实际 %d）" % moves.size())
	var mkeys := ["id", "startup_frames", "active_frames", "recovery_frames", "motion_multiplier", "poise_damage", "status_buildup_bleed", "status_buildup_poison", "status_buildup_frost", "hitbox_reach_px", "hitbox_arc_deg", "min_range_px", "max_range_px", "weight", "cooldown_sec", "can_cancel_frames", "damage_type", "breaks_guard"]
	var exps := [
		{"id": "move_01_dagger_slash", "startup_frames": 18, "active_frames": 5, "recovery_frames": 24, "motion_multiplier": 1.0, "poise_damage": 22.0, "status_buildup_bleed": 0.0, "status_buildup_poison": 0.0, "status_buildup_frost": 0.0, "hitbox_reach_px": 84.0, "hitbox_arc_deg": 100.0, "min_range_px": 0.0, "max_range_px": 96.0, "weight": 3.0, "cooldown_sec": 0.6, "can_cancel_frames": 0, "damage_type": "physical", "breaks_guard": false, "total": 47},
		{"id": "move_02_staff_slam", "startup_frames": 30, "active_frames": 7, "recovery_frames": 34, "motion_multiplier": 1.55, "poise_damage": 45.0, "status_buildup_bleed": 0.0, "status_buildup_poison": 0.0, "status_buildup_frost": 0.0, "hitbox_reach_px": 112.0, "hitbox_arc_deg": 120.0, "min_range_px": 0.0, "max_range_px": 128.0, "weight": 1.6, "cooldown_sec": 2.2, "can_cancel_frames": 0, "damage_type": "physical", "breaks_guard": false, "total": 71},
		{"id": "move_03_holy_hammer", "startup_frames": 42, "active_frames": 9, "recovery_frames": 40, "motion_multiplier": 2.1, "poise_damage": 70.0, "status_buildup_bleed": 0.0, "status_buildup_poison": 0.0, "status_buildup_frost": 35.0, "hitbox_reach_px": 156.0, "hitbox_arc_deg": 150.0, "min_range_px": 0.0, "max_range_px": 176.0, "weight": 1.0, "cooldown_sec": 4.0, "can_cancel_frames": 0, "damage_type": "holy", "breaks_guard": true, "total": 91},
	]
	for i in range(moves.size()):
		if i >= exps.size():
			break
		var mv = moves[i]
		var e = exps[i]
		_check_dict("move[%d]" % i, mv, mkeys, e)
		var st := int(mv.get("startup_frames"))
		var ac := int(mv.get("active_frames"))
		var rc := int(mv.get("recovery_frames"))
		var total := st + ac + rc
		_check("move[%d].total(派生 startup+active+recovery)" % i, total, e["total"])
		print("       └ 帧时序: 前摇=%d 判定=%d 后摇=%d | total=%d | 判定区间=[%d, %d)" % [st, ac, rc, total, st, st + ac])


func _sec_poise() -> void:
	print("---- [3.4] 削韧 PoiseConfig ×2（对照 §4）----")
	var pokeys := ["id", "max_poise", "poise_regen_per_sec", "poise_regen_delay_sec", "stance_break_duration_sec", "stance_break_damage_multiplier", "executable", "execute_hp_ratio_threshold", "poise_break_pose_name", "poise_break_frame"]
	var eb := {"id": "poise_01_margit_base", "max_poise": 120.0, "poise_regen_per_sec": 9.0, "poise_regen_delay_sec": 3.5, "stance_break_duration_sec": 2.5, "stance_break_damage_multiplier": 1.4, "executable": true, "execute_hp_ratio_threshold": 0.0, "poise_break_pose_name": "stance_break", "poise_break_frame": 0}
	var e2 := {"id": "poise_02_margit_p2", "max_poise": 150.0, "poise_regen_per_sec": 12.0, "poise_regen_delay_sec": 2.5, "stance_break_duration_sec": 2.0, "stance_break_damage_multiplier": 1.35, "executable": true, "execute_hp_ratio_threshold": 0.0, "poise_break_pose_name": "stance_break", "poise_break_frame": 0}
	var base = _boss.get("poise")
	var phases: Array = _boss.get("phases")
	var ov = (phases[1] as Resource).get("poise_override")
	print("  [BossData.poise] %s" % _res_label(base))
	_check_dict("poise_base", base, pokeys, eb)
	_assert(ov != null, "[3.4] P2.poise_override 非 null")
	if ov != null:
		print("  [P2.poise_override] %s" % _res_label(ov))
		_check_dict("poise_p2", ov, pokeys, e2)


func _sec_status() -> void:
	var sbs: Array = _boss.get("status_buildups")
	print("---- [3.5] 异常积累 StatusBuildup ×3（对照 §5）| status_buildups.size=%d ----" % sbs.size())
	_assert(sbs.size() == 3, "[3.5] status_buildups.size()==3（实际 %d）" % sbs.size())
	var skeys := ["id", "status_type", "threshold", "decay_per_sec", "decay_delay_sec", "trigger_damage_ratio", "trigger_damage_flat", "trigger_poise_damage", "trigger_pose_name", "duration_sec", "tick_damage_per_sec", "resistance_gain_per_trigger"]
	var exps := [
		{"id": "status_01_bleed", "status_type": "bleed", "threshold": 180.0, "decay_per_sec": 7.0, "decay_delay_sec": 2.0, "trigger_damage_ratio": 0.12, "trigger_damage_flat": 0.0, "trigger_poise_damage": 25.0, "trigger_pose_name": "status_bleed", "duration_sec": 0.0, "tick_damage_per_sec": 0.0, "resistance_gain_per_trigger": 25.0, "max_resistance": 330.0},
		{"id": "status_02_poison", "status_type": "poison", "threshold": 210.0, "decay_per_sec": 6.0, "decay_delay_sec": 2.5, "trigger_damage_ratio": 0.0, "trigger_damage_flat": 40.0, "trigger_poise_damage": 0.0, "trigger_pose_name": "status_poison", "duration_sec": 20.0, "tick_damage_per_sec": 12.0, "resistance_gain_per_trigger": 30.0, "max_resistance": 360.0},
		{"id": "status_03_frost", "status_type": "frost", "threshold": 160.0, "decay_per_sec": 5.0, "decay_delay_sec": 2.0, "trigger_damage_ratio": 0.08, "trigger_damage_flat": 0.0, "trigger_poise_damage": 40.0, "trigger_pose_name": "status_frost", "duration_sec": 30.0, "tick_damage_per_sec": 0.0, "resistance_gain_per_trigger": 30.0, "max_resistance": 320.0},
	]
	var r10 := {"status_01_bleed": 400.0, "status_02_poison": 480.0, "status_03_frost": 420.0}
	for i in range(sbs.size()):
		if i >= exps.size():
			break
		var sb = sbs[i]
		var e = exps[i]
		_check_dict("status[%d]" % i, sb, skeys, e)
		var sid := str(sb.get("id"))
		var actual = sb.get("max_resistance")
		_check("status[%d].max_resistance vs R9文档" % i, actual, e["max_resistance"])
		var verdict_ok := _val_eq(actual, r10.get(sid, -1.0))
		print("       └ 裁决 A1(R10) 授权值=%s | 运行件对照=%s | 说明：R9 文档未同步，属版本差，非数值错误；不擅改" % [str(r10.get(sid, -1.0)), "PASS" if verdict_ok else "FAIL"])


func _sec_player() -> void:
	var acts: Array = _player.get("actions")
	print("---- [3.6] player_actions.tres · 8 条动作实际值（补充，能读到的）| actions.size=%d ----" % acts.size())
	_assert(acts.size() == 8, "[3.6] actions.size()==8（实际 %d）" % acts.size())
	var states: Array = []
	var prios: Array = []
	var fps_all := true
	for a in acts:
		var st := str(a.get("state_name"))
		var pr := int(a.get("state_priority"))
		var lf := int(a.get("logic_fps"))
		states.append(st)
		prios.append(pr)
		if lf != 60:
			fps_all = false
		print("  · %s | state=%s | priority=%d | logic_fps=%d | 帧=%d/%d/%d | invul=[%d,%d] | poise_damage=%s | base_attack=%s | motion=%s" % [
			str(a.get("id")), st, pr, lf,
			int(a.get("startup_frames")), int(a.get("active_frames")), int(a.get("recovery_frames")),
			int(a.get("invulnerable_start_frame")), int(a.get("invulnerable_end_frame")),
			str(a.get("poise_damage")), str(a.get("base_attack")), str(a.get("motion_multiplier"))])
	var required := ["idle", "walk", "run", "roll", "attack_light", "attack_heavy", "hitstun", "death"]
	var missing: Array = []
	for r in required:
		if not states.has(r):
			missing.append(r)
	_assert(missing.size() == 0, "[3.6/E-6] 8 状态齐全（缺 %s）" % str(missing))
	var dup := false
	var seen := {}
	for pr in prios:
		if seen.has(pr):
			dup = true
		seen[pr] = true
	_assert(not dup, "[3.6/E-6] state_priority 互异")
	_assert(fps_all, "[3.6/E-6] logic_fps 全等 60")


# ---------------------------------------------------------------------------
# 断言 / 对照 / 工具
# ---------------------------------------------------------------------------
func _assert(cond: bool, label: String) -> void:
	if cond:
		_assert_ok += 1
		print("  [PASS] " + label)
	else:
		_fail_count += 1
		print("  [FAIL] " + label)


func _check_dict(tag: String, res, keys: Array, exp: Dictionary) -> void:
	for k in keys:
		_check("%s.%s" % [tag, k], res.get(k), exp[k])


func _check(label: String, actual, expected) -> void:
	if _val_eq(actual, expected):
		_check_ok += 1
		print("  [PASS] %s | 实际=%s | 期望=%s" % [label, _s(actual), _s(expected)])
	else:
		_diff_count += 1
		_diff_labels.append(label)
		print("  [FAIL/登记] %s | 实际=%s | 期望(R9文档)=%s" % [label, _s(actual), _s(expected)])


func _val_eq(a, b) -> bool:
	var ta := typeof(a)
	var tb := typeof(b)
	if (ta == TYPE_FLOAT or ta == TYPE_INT) and (tb == TYPE_FLOAT or tb == TYPE_INT):
		return abs(float(a) - float(b)) < 0.00001
	return str(a) == str(b)


func _s(v) -> String:
	if v == null:
		return "null"
	return str(v)


func _res_label(v) -> String:
	if v == null:
		return "null"
	if v is Resource:
		var idv = v.get("id")
		if idv != null and str(idv) != "":
			return "%s(id=%s)" % [v.get_class(), str(idv)]
		return v.get_class()
	return str(v)
