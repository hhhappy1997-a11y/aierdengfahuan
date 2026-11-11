extends SceneTree

## ===========================================================================
## R28 / v0.6.0 · 赐福引导「三步教学运行时」自测（Rank-1 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_tutorial_v060.gd
## 覆盖（任务单 ⑤）：① 三步顺序 ② 错误按键不推进 ③ 重复触发 ④ 完成跳过
##   ⑤ T 重开 ⑥ 依赖缺失降级 ⑦ 点亮态与波次衔接 ⑧ 对外接口（is_tutorial_active
##   / force_complete）；输出逐条 PASS/FAIL + SUMMARY + RESULT，失败 quit(1)，不伪造 PASS。
## 夹具为纯内存：WorldState 手动 new()（不写 user:// 盘）、FakeWriter 只记录
##   commit(reason) 时序、WaveTrialDirector / HUD / Label 均独立实例；显式 call("_ready")
##   （--script 模式 add_child 不 flush _ready），注入一律在 _ready 之后（既有踩坑口径）。
## --script 模式 /root/... 绝对路径不可用：本脚本只用 root.get_node_or_null() 相对探活，
##   且不依赖 autoload 结果判 PASS（tutorial_director 的 bind_tutorial_deps 显式注入）。
## 数值期望来自 Rank-2 res://data/rpg/tutorial_steps.tres（20/30/50），不硬编码设计数值。
## 引擎：Godot 4.7.2 / GDScript，全静态类型 · 零付费 · 零外部依赖。
## ===========================================================================

const TUT_SCRIPT_PATH: String = "res://scripts/combat/tutorial_director.gd"
const WAVE_SCRIPT_PATH: String = "res://scripts/combat/wave_trial_director.gd"
const HUD_SCENE_PATH: String = "res://scenes/hud.tscn"
const WS_SCRIPT_PATH: String = "res://scripts/rpg/world_state.gd"
const CONFIG_PATH: String = "res://data/rpg/tutorial_steps.tres"
const MISSING_CONFIG_PATH: String = "res://data/rpg/__r28_missing_tutorial_steps__.tres"

const FLAG_TUTORIAL_COMPLETED: String = "grace.tutorial.completed"
const FLAG_POINTS: String = "grace.trial.points"
const FLAG_TRIAL_COMPLETED: String = "dungeon.wave_trial.completed"
const GOLD: Color = Color(0.83, 0.68, 0.3, 1.0)
const DIM: Color = Color(0.45, 0.42, 0.34, 1.0)

# 既有 input action 键位（project.godot [input]，零新增键位）；T 键直接按 physical_keycode 判定。
const KEY_LIGHT_ATTACK: int = KEY_J
const KEY_ROLL: int = KEY_SPACE
const KEY_INTERACT: int = KEY_E
const KEY_RESTART: int = KEY_T
const KEY_WRONG_HEAVY: int = KEY_K
const KEY_WRONG_DIGIT: int = KEY_1

var _pass: int = 0
var _fail: int = 0
var _temps: Array[Node] = []
var _sig_events: Array[Dictionary] = []


## 显式注入的 SaveDeltaWriter 替身：只记录 commit(reason) 时序，不写 user:// 盘，
## 使 verify 可实证「set_flag → commit」链路而不污染生产存档。
class FakeWriter extends Node:
	var commits: Array[String] = []

	func commit(reason: String) -> void:
		commits.append(reason)


func _track(n: Node) -> Node:
	_temps.append(n)
	return n


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V060-TUT] %s PASS=%s | %s" % [tag, str(ok), detail])


func _finish() -> void:
	for n: Node in _temps:
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	print("[V060-TUT] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	print("[V060-TUT] RESULT=%s" % ("ALL_PASS" if _fail == 0 else "FAILED"))
	print("[V060-TUT] === SELFTEST END ===")
	quit(0 if _fail == 0 else 1)


# ===========================================================================
# 夹具构造
# ===========================================================================
func _make_ws() -> Node:
	var ws: Node = _track(Node.new()) as Node
	ws.set_script(load(WS_SCRIPT_PATH) as Script)
	ws.call("_ready")            # 干净基线，不读 user:// 盘
	return ws


func _make_writer() -> FakeWriter:
	return _track(FakeWriter.new()) as FakeWriter


func _make_wave() -> Node:
	var w: Node = _track(Node.new()) as Node
	w.set_script(load(WAVE_SCRIPT_PATH) as Script)
	w.name = "WaveTrialDirector"
	w.call("_ready")
	return w


func _make_label() -> Label:
	return _track(Label.new()) as Label


func _make_hud(ws: Node) -> Node:
	var packed: PackedScene = ResourceLoader.load(
			HUD_SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var h: Node = _track(packed.instantiate()) as Node
	h.call("_ready")
	h.call("bind_world_state", ws)    # 注入在 _ready 之后
	h.call("refresh_all")
	return h


## 构造一台教学导演：可选预设「存档已完成」、可选把配置路径指向不存在文件（降级测）。
## 在 _ready 之前 bind_tutorial_deps() 预注入确定性依赖：这样启动时的「读档判定」
## （_read_completed_flag）读到的是注入实例而非 --script 模式下的 autoload 基线，
## 与真实场景 SaveSystem 先读回、再进 _ready 的顺序一致（tutorial_director 尊重预注入）。
func _make_tut(ws: Node, writer: Node, wave: Node, label: Label,
		preset_completed: bool = false, cfg_path: String = "") -> Node:
	var t: Node = _track(Node.new()) as Node
	t.set_script(load(TUT_SCRIPT_PATH) as Script)
	if not cfg_path.is_empty():
		t.set("config_path", cfg_path)
	if preset_completed and ws != null and ws.has_method("set_flag"):
		ws.call("set_flag", FLAG_TUTORIAL_COMPLETED, true)
	t.call("bind_tutorial_deps", ws, writer, wave, label)   # _ready 之前预注入
	t.call("_ready")
	if not t.is_connected("tutorial_step_completed", Callable(self, "_on_step")):
		t.connect("tutorial_step_completed", Callable(self, "_on_step"))
	return t


func _on_step(step_id: String, reward: int) -> void:
	_sig_events.append({"step_id": step_id, "reward": reward})


## 模拟一次物理按键（直接调用 _unhandled_input，与运行时同一代码路径）。
func _press(t: Node, keycode: int) -> void:
	var ev: InputEventKey = InputEventKey.new()
	ev.physical_keycode = keycode
	ev.keycode = keycode
	ev.pressed = true
	ev.echo = false
	t.call("_unhandled_input", ev)


func _snap(t: Node) -> Dictionary:
	return t.call("get_snapshot") as Dictionary


func _points(ws: Node) -> int:
	if ws != null and ws.has_method("get_flag"):
		return int(ws.call("get_flag", FLAG_POINTS, 0))
	return -1


func _completed(ws: Node) -> bool:
	if ws != null and ws.has_method("get_flag"):
		return bool(ws.call("get_flag", FLAG_TUTORIAL_COMPLETED, false))
	return false


func _hud_color(h: Node) -> Color:
	var lbl: Label = h.get_node_or_null("TitleLabel") as Label
	if lbl == null:
		return Color(0, 0, 0, 0)
	return lbl.get_theme_color("font_color", "Label")


# ===========================================================================
# A) 三步顺序 / 状态机 / 信号 / 奖励 / 数据驱动
# ===========================================================================
func _test_A_three_steps() -> void:
	_sig_events.clear()
	var ws: Node = _make_ws()
	var fw: FakeWriter = _make_writer()
	var wave: Node = _make_wave()
	var label: Label = _make_label()
	var t: Node = _make_tut(ws, fw, wave, label)

	var s0: Dictionary = _snap(t)
	_ck("A1 初始状态 STEP_LIGHT_ATTACK", int(s0.get("state", -1)) == 1 \
		and str(s0.get("state_name", "")) == "STEP_LIGHT_ATTACK",
		"state=%s" % str(s0.get("state_name", "?")))
	_ck("A2 教学激活 is_tutorial_active=true", bool(s0.get("is_tutorial_active", false)),
		"active=%s" % str(s0.get("is_tutorial_active", "?")))
	_ck("A3 教学期三波冻结", bool(s0.get("wave_frozen", false)) \
		and bool((wave.call("get_snapshot") as Dictionary).get("tutorial_frozen", false)),
		"tut.wave_frozen=%s wave.tutorial_frozen=%s" % [
			str(s0.get("wave_frozen", "?")),
			str((wave.call("get_snapshot") as Dictionary).get("tutorial_frozen", "?"))])
	var hud0: String = str(s0.get("tutorial_hud_text", ""))
	_ck("A4 教学 HUD 含步骤文案/进度 1-3/奖励点数", \
		("1/3" in hud0) and ("轻攻击" in hud0) and ("点数" in hud0), "text=%s" % hud0)
	_ck("A5 数据驱动奖励 20/30/50（读 Rank-2 表）", \
		(s0.get("step_rewards", []) as Array) == [20, 30, 50],
		"rewards=%s" % str(s0.get("step_rewards", [])))

	_press(t, KEY_LIGHT_ATTACK)
	var s1: Dictionary = _snap(t)
	_ck("A6 按 J 完成第 1 步 → STEP_ROLL", str(s1.get("state_name", "")) == "STEP_ROLL",
		"state=%s events=%s" % [str(s1.get("state_name", "?")), str(s1.get("step_events", []))])
	_ck("A7 第 1 步信号 (light_attack, 20)", _sig_events.size() == 1 \
		and str(_sig_events[0].get("step_id", "")) == "light_attack" \
		and int(_sig_events[0].get("reward", -1)) == 20, "events=%s" % str(_sig_events))
	_ck("A8 第 1 步赐福点数 +20（单调累加）", _points(ws) == 20,
		"points=%d" % _points(ws))

	_press(t, KEY_ROLL)
	var s2: Dictionary = _snap(t)
	_ck("A9 按 Space 完成第 2 步 → STEP_GRACE_SHOP", \
		str(s2.get("state_name", "")) == "STEP_GRACE_SHOP",
		"state=%s" % str(s2.get("state_name", "?")))
	_ck("A10 第 2 步信号 (roll, 30)", _sig_events.size() == 2 \
		and str(_sig_events[1].get("step_id", "")) == "roll" \
		and int(_sig_events[1].get("reward", -1)) == 30, "events=%s" % str(_sig_events))
	_ck("A11 前两步点数累计 = 50", _points(ws) == 50, "points=%d" % _points(ws))

	_press(t, KEY_INTERACT)
	var s3: Dictionary = _snap(t)
	_ck("A12 按 E 完成第 3 步 → COMPLETED", str(s3.get("state_name", "")) == "COMPLETED",
		"state=%s" % str(s3.get("state_name", "?")))
	_ck("A13 三步顺序信号 light_attack→roll→grace_shop", \
		(s3.get("step_events", []) as Array) == ["light_attack", "roll", "grace_shop"],
		"events=%s" % str(s3.get("step_events", [])))
	_ck("A14 第 3 步信号 (grace_shop, 50) / 合计 100", _sig_events.size() == 3 \
		and int(_sig_events[2].get("reward", -1)) == 50 \
		and int(s3.get("total_reward", -1)) == 100,
		"events=%s total=%s" % [str(_sig_events), str(s3.get("total_reward", "?"))])
	_ck("A15 三步赐福点数终值 = 100（20+30+50，只增不减）", _points(ws) == 100,
		"points=%d" % _points(ws))
	_ck("A16 写单向完成 flag grace.tutorial.completed=true", _completed(ws) \
		and bool(s3.get("completed_flag", false)),
		"flag=%s snapshot=%s" % [str(_completed(ws)), str(s3.get("completed_flag", "?"))])
	_ck("A17 完成后 is_tutorial_active=false", not bool(s3.get("is_tutorial_active", true)),
		"active=%s" % str(s3.get("is_tutorial_active", "?")))
	_ck("A18 set_flag→commit 落盘时序（3 步 + 完成各一次）", fw.commits.size() == 4 \
		and fw.commits[3] == "tutorial_completed", "commits=%s" % str(fw.commits))
	_ck("A19 完成 HUD 显示已完成态", "已完成" in str(s3.get("tutorial_hud_text", "")),
		"text=%s" % str(s3.get("tutorial_hud_text", "")))


# ===========================================================================
# B) 错误按键不推进
# ===========================================================================
func _test_B_wrong_keys() -> void:
	_sig_events.clear()
	var ws: Node = _make_ws()
	var t: Node = _make_tut(ws, _make_writer(), _make_wave(), _make_label())
	_press(t, KEY_ROLL)          # 第 2 步的键，当前应为第 1 步
	_press(t, KEY_INTERACT)      # 第 3 步的键
	_press(t, KEY_WRONG_HEAVY)   # heavy_attack（K），非教学 action
	_press(t, KEY_WRONG_DIGIT)   # 数字键 1
	var s: Dictionary = _snap(t)
	_ck("B1 错误按键不推进（仍 STEP_LIGHT_ATTACK）", \
		str(s.get("state_name", "")) == "STEP_LIGHT_ATTACK" and int(s.get("step_index", -1)) == 0,
		"state=%s index=%s" % [str(s.get("state_name", "?")), str(s.get("step_index", "?"))])
	_ck("B2 错误按键不发信号 / 不发奖励", _sig_events.is_empty() \
		and (s.get("step_events", []) as Array).is_empty() and _points(ws) == 0,
		"sig=%s points=%d" % [str(_sig_events), _points(ws)])
	_ck("B3 错误按键不触发完成 flag", not _completed(ws), "flag=%s" % str(_completed(ws)))
	# 正确键仍可推进（错误按键未污染状态机）
	_press(t, KEY_LIGHT_ATTACK)
	_ck("B4 错误按键后正确键仍可推进第 1 步", \
		str((_snap(t) as Dictionary).get("state_name", "")) == "STEP_ROLL",
		"state=%s" % str((_snap(t) as Dictionary).get("state_name", "?")))


# ===========================================================================
# C) 重复触发
# ===========================================================================
func _test_C_duplicate() -> void:
	_sig_events.clear()
	var ws: Node = _make_ws()
	var t: Node = _make_tut(ws, _make_writer(), _make_wave(), _make_label())
	_press(t, KEY_LIGHT_ATTACK)
	_press(t, KEY_LIGHT_ATTACK)   # 第 1 步已过，重复按 J
	_press(t, KEY_LIGHT_ATTACK)
	var s: Dictionary = _snap(t)
	_ck("C1 重复按上一步 action 不推进（仍 STEP_ROLL）", \
		str(s.get("state_name", "")) == "STEP_ROLL" and int(s.get("step_index", -1)) == 1,
		"state=%s index=%s" % [str(s.get("state_name", "?")), str(s.get("step_index", "?"))])
	_ck("C2 重复触发不重复发信号 / 不重复加点", _sig_events.size() == 1 \
		and _points(ws) == 20, "sig=%s points=%d" % [str(_sig_events), _points(ws)])
	# 三步完成后继续按键：不推进、不重复发信号、不回退 flag
	_press(t, KEY_ROLL)
	_press(t, KEY_INTERACT)
	_press(t, KEY_LIGHT_ATTACK)
	_press(t, KEY_ROLL)
	_press(t, KEY_INTERACT)
	var s2: Dictionary = _snap(t)
	_ck("C3 完成后再按三 action 仍是 COMPLETED / 不重复计数", \
		str(s2.get("state_name", "")) == "COMPLETED" and _sig_events.size() == 3 \
		and (s2.get("step_events", []) as Array).size() == 3,
		"state=%s sig=%d" % [str(s2.get("state_name", "?")), _sig_events.size()])
	_ck("C4 完成后不回退 points / 不写 false 完成 flag", _points(ws) == 100 \
		and _completed(ws) and int(s2.get("total_reward", -1)) == 100,
		"points=%d flag=%s" % [_points(ws), str(_completed(ws))])


# ===========================================================================
# D) 完成跳过（已有存档完成）
# ===========================================================================
func _test_D_skip_completed() -> void:
	_sig_events.clear()
	var ws: Node = _make_ws()
	var wave: Node = _make_wave()
	var t: Node = _make_tut(ws, _make_writer(), wave, _make_label(), true)
	var s: Dictionary = _snap(t)
	_ck("D1 存档已完成 → 启动跳过教学（COMPLETED）", \
		str(s.get("state_name", "")) == "COMPLETED" and not bool(s.get("is_tutorial_active", true)),
		"state=%s active=%s" % [str(s.get("state_name", "?")), str(s.get("is_tutorial_active", "?"))])
	_ck("D2 跳过教学不冻结三波（wave.tutorial_frozen=false）", \
		not bool((wave.call("get_snapshot") as Dictionary).get("tutorial_frozen", true)),
		"frozen=%s" % str((wave.call("get_snapshot") as Dictionary).get("tutorial_frozen", "?")))
	_ck("D3 跳过教学不发步骤信号 / 不重复发奖励", _sig_events.is_empty() \
		and _points(ws) == 0, "sig=%s points=%d" % [str(_sig_events), _points(ws)])
	_ck("D4 跳过教学 HUD 显示已完成态", "已完成" in str(s.get("tutorial_hud_text", "")),
		"text=%s" % str(s.get("tutorial_hud_text", "")))
	_press(t, KEY_LIGHT_ATTACK)
	_ck("D5 跳过态按 J 不重新进入教学", \
		str((_snap(t) as Dictionary).get("state_name", "")) == "COMPLETED",
		"state=%s" % str((_snap(t) as Dictionary).get("state_name", "?")))


# ===========================================================================
# E) T 重开（含已完成存档强制重开 / 防重复刷点）
# ===========================================================================
func _test_E_restart_T() -> void:
	_sig_events.clear()
	var ws: Node = _make_ws()
	var wave: Node = _make_wave()
	var t: Node = _make_tut(ws, _make_writer(), wave, _make_label())
	_press(t, KEY_LIGHT_ATTACK)
	_press(t, KEY_ROLL)
	_press(t, KEY_INTERACT)
	_ck("E0 前置：三步已完成且 flag=true", _completed(ws) and _points(ws) == 100,
		"flag=%s points=%d" % [str(_completed(ws)), _points(ws)])

	_sig_events.clear()
	_press(t, KEY_RESTART)
	var s: Dictionary = _snap(t)
	_ck("E1 按 T 强制重开（忽略已完成存档）→ STEP_LIGHT_ATTACK", \
		str(s.get("state_name", "")) == "STEP_LIGHT_ATTACK" \
		and bool(s.get("is_tutorial_active", false)),
		"state=%s active=%s" % [str(s.get("state_name", "?")), str(s.get("is_tutorial_active", "?"))])
	_ck("E2 重开后重新冻结三波", bool(s.get("wave_frozen", false)) \
		and bool((wave.call("get_snapshot") as Dictionary).get("tutorial_frozen", false)),
		"frozen=%s" % str(s.get("wave_frozen", "?")))
	_ck("E3 重开 HUD 回到 1/3", "1/3" in str(s.get("tutorial_hud_text", "")),
		"text=%s" % str(s.get("tutorial_hud_text", "")))
	_ck("E4 重开不清除单向完成 flag", _completed(ws), "flag=%s" % str(_completed(ws)))

	# 重开三步：状态机完整走一遍，但已完成存档不重复发放点数奖励（防刷点）。
	_press(t, KEY_LIGHT_ATTACK)
	_press(t, KEY_ROLL)
	_press(t, KEY_INTERACT)
	var s2: Dictionary = _snap(t)
	_ck("E5 重开三步状态机 / 信号仍完整（3 条）", _sig_events.size() == 3 \
		and (s2.get("step_events", []) as Array).size() == 3,
		"sig=%s events=%s" % [str(_sig_events), str(s2.get("step_events", []))])
	_ck("E6 重开不重复刷点（points 仍=100，reward=0）", _points(ws) == 100 \
		and int(s2.get("total_reward", -1)) == 0 \
		and int(_sig_events[0].get("reward", -1)) == 0,
		"points=%d total=%s reward0=%s" % [_points(ws), str(s2.get("total_reward", "?")),
			str(_sig_events[0].get("reward", "?"))])
	_ck("E7 重开完成后再次自动衔接第 1 波", bool(s2.get("wave_started", false)),
		"wave_started=%s" % str(s2.get("wave_started", "?")))
	# 中途按 T 也能重开回首步
	var t2: Node = _make_tut(_make_ws(), _make_writer(), _make_wave(), _make_label())
	_press(t2, KEY_LIGHT_ATTACK)
	_press(t2, KEY_RESTART)
	_ck("E8 教学中途按 T 重开回首步", \
		str((_snap(t2) as Dictionary).get("state_name", "")) == "STEP_LIGHT_ATTACK" \
		and int((_snap(t2) as Dictionary).get("step_index", -1)) == 0,
		"state=%s" % str((_snap(t2) as Dictionary).get("state_name", "?")))


# ===========================================================================
# F) 依赖缺失降级（配置 / WorldState / Writer / Wave / Label）
# ===========================================================================
func _test_F_degrade() -> void:
	_sig_events.clear()
	# F1：配置缺失 + 全依赖注入 null → 仍能走完三步、如实登记降级、不崩。
	var t: Node = _make_tut(null, null, null, null, false, MISSING_CONFIG_PATH)
	var s0: Dictionary = _snap(t)
	_ck("F1 配置缺失降级：config_loaded=false / 不崩", \
		not bool(s0.get("config_loaded", true)) \
		and str(s0.get("state_name", "")) == "STEP_LIGHT_ATTACK",
		"config_loaded=%s state=%s" % [str(s0.get("config_loaded", "?")), str(s0.get("state_name", "?"))])
	_ck("F2 配置缺失回落内置 [PLACEHOLDER] 默认奖励", \
		(s0.get("step_rewards", []) as Array) == [20, 20, 20],
		"rewards=%s" % str(s0.get("step_rewards", [])))
	_press(t, KEY_LIGHT_ATTACK)
	_press(t, KEY_ROLL)
	_press(t, KEY_INTERACT)
	var s1: Dictionary = _snap(t)
	_ck("F3 全依赖缺失仍走完三步 → COMPLETED（不崩）", \
		str(s1.get("state_name", "")) == "COMPLETED" and _sig_events.size() == 3,
		"state=%s sig=%d" % [str(s1.get("state_name", "?")), _sig_events.size()])
	_ck("F4 全依赖缺失：完成 flag 走运行期镜像 / 不谎报落盘", \
		bool(s1.get("completed_flag", false)) and int(s1.get("commit_count", -1)) == 0 \
		and not str(s1.get("degrade_reason", "")).is_empty(),
		"flag=%s commits=%d reason=%s" % [str(s1.get("completed_flag", "?")),
			int(s1.get("commit_count", -1)), str(s1.get("degrade_reason", ""))])
	_ck("F5 全依赖缺失：HUD Label 为空不刷新 / 不崩", \
		str(s1.get("tutorial_hud_text", "")) == "" and not bool(s1.get("wave_started", true)),
		"hud_text='%s' wave_started=%s" % [str(s1.get("tutorial_hud_text", "")), str(s1.get("wave_started", "?"))])

	# F6：WorldState/Writer 缺失但 Wave 存在 → 完成仍能衔接波次（降级只影响落盘）。
	var wave: Node = _make_wave()
	var t2: Node = _make_tut(null, null, wave, _make_label())
	_press(t2, KEY_LIGHT_ATTACK)
	_press(t2, KEY_ROLL)
	_press(t2, KEY_INTERACT)
	_ck("F6 落盘依赖缺失但波次在场 → 仍自动进第 1 波", \
		bool((_snap(t2) as Dictionary).get("wave_started", false)) \
		and str((wave.call("get_snapshot") as Dictionary).get("state_name", "")) == "TELEGRAPH",
		"wave_state=%s" % str((wave.call("get_snapshot") as Dictionary).get("state_name", "?")))
	# F7：Wave 缺失但 WorldState/Writer 在场 → 完成不崩、如实登记未进波。
	var ws: Node = _make_ws()
	var t3: Node = _make_tut(ws, _make_writer(), null, _make_label())
	_press(t3, KEY_LIGHT_ATTACK)
	_press(t3, KEY_ROLL)
	_press(t3, KEY_INTERACT)
	_ck("F7 波次缺失：完成 flag 仍写入 / 不崩 / 不冒充已进波", \
		_completed(ws) and not bool((_snap(t3) as Dictionary).get("wave_started", true)),
		"flag=%s wave_started=%s" % [str(_completed(ws)),
			str((_snap(t3) as Dictionary).get("wave_started", "?"))])


# ===========================================================================
# G) 点亮态（读三段式 flag / 复用 apply_lit_state）与波次衔接
# ===========================================================================
func _test_G_lit_and_wave() -> void:
	_sig_events.clear()
	var ws: Node = _make_ws()
	var hud: Node = _make_hud(ws)
	var c0: Color = _hud_color(hud)
	_ck("G1 初始赐福标题暗灰 DIM", c0.is_equal_approx(DIM), "color=%s" % str(c0))
	_ck("G2 既有 LIT_SOURCE_FLAGS 仍为 2 项（v050 D5 口径不回退）", \
		(hud.get("LIT_SOURCE_FLAGS") as Array).size() == 2,
		"sources=%s" % str(hud.get("LIT_SOURCE_FLAGS")))

	var wave: Node = _make_wave()
	var t: Node = _make_tut(ws, _make_writer(), wave, _make_label())
	_ck("G3 教学期波次不推进（wave 仍 IDLE / tutorial_frozen=true）", \
		str((wave.call("get_snapshot") as Dictionary).get("state_name", "")) == "IDLE" \
		and bool((wave.call("get_snapshot") as Dictionary).get("tutorial_frozen", false)),
		"wave_state=%s" % str((wave.call("get_snapshot") as Dictionary).get("state_name", "?")))
	# 教学期错误按键不会让波次自动开始
	_press(t, KEY_ROLL)
	_ck("G4 教学期错误按键三波仍不推进", \
		str((wave.call("get_snapshot") as Dictionary).get("state_name", "")) == "IDLE",
		"wave_state=%s" % str((wave.call("get_snapshot") as Dictionary).get("state_name", "?")))

	_press(t, KEY_LIGHT_ATTACK)
	_press(t, KEY_ROLL)
	_press(t, KEY_INTERACT)
	var c1: Color = _hud_color(hud)
	_ck("G5 教学完成（grace.tutorial.completed=true）→ 赐福标题亮金 GOLD", \
		c1.is_equal_approx(GOLD) and bool(hud.call("_read_tutorial_lit")),
		"color=%s tutorial_lit=%s" % [str(c1), str(hud.call("_read_tutorial_lit"))])
	# commit → delta_committed → refresh_all 不得把亮金覆盖回暗灰
	hud.call("refresh_all")
	_ck("G6 refresh_all 全量刷新后仍保持亮金（复用 apply_lit_state 同一入口）", \
		_hud_color(hud).is_equal_approx(GOLD), "color=%s" % str(_hud_color(hud)))
	var wsap: Dictionary = wave.call("get_snapshot") as Dictionary
	_ck("G7 教学完成自动进第 1 波（TELEGRAPH / index=0 / 解冻）", \
		str(wsap.get("state_name", "")) == "TELEGRAPH" and int(wsap.get("index", -1)) == 0 \
		and not bool(wsap.get("tutorial_frozen", true)),
		"state=%s index=%s frozen=%s" % [str(wsap.get("state_name", "?")),
			str(wsap.get("index", "?")), str(wsap.get("tutorial_frozen", "?"))])
	_ck("G8 教学完成写 flag 为三段式（符合 WorldState 正则）", \
		FLAG_TUTORIAL_COMPLETED.split(".").size() == 3 and _completed(ws),
		"key=%s flag=%s" % [FLAG_TUTORIAL_COMPLETED, str(_completed(ws))])

	# 既有「试炼完成」点亮入口不受影响（另起干净夹具，读原 LIT_SOURCE_FLAGS）。
	var ws2: Node = _make_ws()
	var hud2: Node = _make_hud(ws2)
	_ck("G9 独立夹具初始暗灰 DIM", _hud_color(hud2).is_equal_approx(DIM),
		"color=%s" % str(_hud_color(hud2)))
	ws2.call("set_flag", FLAG_TRIAL_COMPLETED, true)
	_ck("G10 试炼完成仍点亮 GOLD（既有入口不回退）", \
		_hud_color(hud2).is_equal_approx(GOLD) and bool(hud2.call("_read_lit_sources")),
		"color=%s sources_lit=%s" % [str(_hud_color(hud2)), str(hud2.call("_read_lit_sources"))])


# ===========================================================================
# H) 对外接口 is_tutorial_active() / force_complete()（演示序列跳过，避免双驱动）
# ===========================================================================
func _test_H_external_api() -> void:
	_sig_events.clear()
	var ws: Node = _make_ws()
	var wave: Node = _make_wave()
	var t: Node = _make_tut(ws, _make_writer(), wave, _make_label())
	_ck("H1 提供 is_tutorial_active() / force_complete() 接口", \
		t.has_method("is_tutorial_active") and t.has_method("force_complete"),
		"active=%s complete=%s" % [str(t.has_method("is_tutorial_active")), str(t.has_method("force_complete"))])
	_ck("H2 教学激活时 is_tutorial_active()=true", bool(t.call("is_tutorial_active")),
		"active=%s" % str(t.call("is_tutorial_active")))
	t.call("force_complete")
	var s: Dictionary = _snap(t)
	_ck("H3 force_complete() 一次性完成三步（信号 3 条 / COMPLETED）", \
		str(s.get("state_name", "")) == "COMPLETED" and _sig_events.size() == 3,
		"state=%s sig=%d" % [str(s.get("state_name", "?")), _sig_events.size()])
	_ck("H4 force_complete() 写完成 flag / 自动进第 1 波", \
		_completed(ws) and bool(s.get("wave_started", false)) \
		and str((wave.call("get_snapshot") as Dictionary).get("state_name", "")) == "TELEGRAPH",
		"flag=%s wave=%s" % [str(_completed(ws)),
			str((wave.call("get_snapshot") as Dictionary).get("state_name", "?"))])
	_ck("H5 完成后 is_tutorial_active()=false", not bool(t.call("is_tutorial_active")),
		"active=%s" % str(t.call("is_tutorial_active")))
	var sig_before: int = _sig_events.size()
	var commits_before: int = int((_snap(t) as Dictionary).get("commit_count", 0))
	t.call("force_complete")     # 非激活态幂等：不重复驱动、不重复发信号 / 落盘
	_ck("H6 非激活态 force_complete() 幂等（不双驱动）", \
		_sig_events.size() == sig_before \
		and int((_snap(t) as Dictionary).get("commit_count", -1)) == commits_before,
		"sig=%d->%d commits=%d->%d" % [sig_before, _sig_events.size(), commits_before,
			int((_snap(t) as Dictionary).get("commit_count", -1))])


# ===========================================================================
func _initialize() -> void:
	print("[V060-TUT] === SELFTEST START | R28 教学运行时 ===")
	_test_A_three_steps()
	_test_B_wrong_keys()
	_test_C_duplicate()
	_test_D_skip_completed()
	_test_E_restart_T()
	_test_F_degrade()
	_test_G_lit_and_wave()
	_test_H_external_api()
	_finish()
