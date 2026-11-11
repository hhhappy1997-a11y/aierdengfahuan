extends SceneTree

## ===========================================================================
## R28B / v0.6.0 · 教学重启与世界持久层收口自测（Rank-1 交付件）
##   cmd-20261111-105411-909-A1 [ROUND=R28B] 任务 ④
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_tutorial_restart_v060.gd
##
## 覆盖（任务单 ④ + 裁决 A26 / A27 + ③ 兼容旧档）：
##   A) grace.tutorial.step_index 世界持久层单调递增（按 max 写、绝不回退）；
##   B) T 键重开：运行时游标归零但世界 flag 不变、completed 单向不清除；
##   C) hud.gd 教学进度显示取【运行时游标】而非世界 flag（裁决 A26）；
##   D) Rank-2 三个兼容函数接入后的「纯旧 bought_ 档」已购识别（③）；
##   E) courtyard.tscn 节点数 41 + 教学 3 节点（裁决 A27 补的 1 条回归用例）
##      + verify_wave_runtime_v040.gd 的 37 PASS 基线不回退；
##   F) completed 单向 / 依赖缺失降级不新增落盘点。
## 逐条输出 PASS/FAIL 与 SUMMARY / RESULT，失败 quit(1)，不伪造 PASS、不谎报数字。
##
## 夹具为纯内存：WorldState 手动 new()（不写 user:// 盘）、FakeWriter 只记
##   commit(reason) 时序、WaveTrialDirector / HUD / Label / GraceUpgradeRuntime 独立实例；
##   显式 call("_ready")（--script 模式 add_child 不 flush _ready）；hud 的
##   bind_world_state / bind_grace_deps 一律在 _ready 之后注入（既有踩坑口径），
##   tutorial_director 的 bind_tutorial_deps 按其 _deps_prebound 设计在 _ready 前预注入。
## --script 模式 /root/... 绝对路径不可用：本脚本只用 root.get_node_or_null() 相对探活，
##   且不依赖 autoload 结果判 PASS（依赖一律显式注入）。
## 引擎：Godot 4.7.2 / GDScript，全静态类型 · 零付费 · 零外部依赖。
## ===========================================================================

const TUT_SCRIPT_PATH: String = "res://scripts/combat/tutorial_director.gd"
const WAVE_SCRIPT_PATH: String = "res://scripts/combat/wave_trial_director.gd"
const RUNTIME_SCRIPT_PATH: String = "res://scripts/combat/grace_upgrade_runtime.gd"
const HUD_SCENE_PATH: String = "res://scenes/hud.tscn"
const WS_SCRIPT_PATH: String = "res://scripts/rpg/world_state.gd"
const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"
const V040_SCRIPT_PATH: String = "res://scripts/combat/verify_wave_runtime_v040.gd"

# ---- 三段式 flag（与 tutorial_director.gd / hud.gd / 契约 §3.3 逐字对齐）----
const FLAG_TUTORIAL_COMPLETED: String = "grace.tutorial.completed"
const FLAG_TUTORIAL_STEP_INDEX: String = "grace.tutorial.step_index"
const FLAG_POINTS: String = "grace.trial.points"
const FLAG_SPENT_POINTS: String = "grace.trial.spent_points"
const FLAG_UNLOCKED_PREFIX: String = "grace.upgrade_"
const FLAG_UNLOCKED_SUFFIX: String = ".unlocked"
const FLAG_BOUGHT_PREFIX: String = "grace.trial.bought_"

# 兑换表首项（Rank-2 res://data/rpg/grace_upgrades.tres），用于纯旧档兼容读取实证。
const EXPECT_ID: String = "hp_max_bonus"
const EXPECT_COST: int = 100
const OTHER_ID: String = "roll_iframe_bonus"

# A27：场景新增 3 个教学节点后 courtyard.tscn 的精确节点数（v040 断言后值）。
const NODE_COUNT_EXPECTED: int = 41
const NODE_COUNT_DELTA_EXPECTED: int = 8
const TOTAL_STEPS: int = 3

const KEY_LIGHT_ATTACK: int = KEY_J
const KEY_ROLL: int = KEY_SPACE
const KEY_INTERACT: int = KEY_E
const KEY_RESTART: int = KEY_T

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
	print("[RST-V060] %s PASS=%s | %s" % [tag, str(ok), detail])


func _finish() -> void:
	for n: Node in _temps:
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	print("[RST-V060] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	print("[RST-V060] RESULT=%s" % ("ALL_PASS" if _fail == 0 else "FAILED"))
	print("[RST-V060] === SELFTEST END ===")
	quit(0 if _fail == 0 else 1)


# ===========================================================================
# 夹具构造（纯内存 / 显式 _ready / 注入优先）
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


func _make_runtime() -> Node:
	var r: Node = _track(Node.new()) as Node
	r.set_script(load(RUNTIME_SCRIPT_PATH) as Script)
	return r


func _make_hud(ws: Node) -> Node:
	var packed: PackedScene = ResourceLoader.load(
			HUD_SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var h: Node = _track(packed.instantiate()) as Node
	h.call("_ready")
	h.call("bind_world_state", ws)    # 注入在 _ready 之后
	h.call("refresh_all")
	return h


## 构造一台教学导演：在 _ready 之前 bind_tutorial_deps() 预注入确定性依赖
## （tutorial_director 尊重 _deps_prebound，与真实场景「先读档再进 _ready」一致）。
func _make_tut(ws: Node, writer: Node, wave: Node, label: Label) -> Node:
	var t: Node = _track(Node.new()) as Node
	t.set_script(load(TUT_SCRIPT_PATH) as Script)
	t.call("bind_tutorial_deps", ws, writer, wave, label)
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


func _flag_int(ws: Node, key: String) -> int:
	if ws != null and ws.has_method("get_flag"):
		return int(ws.call("get_flag", key, 0))
	return -1


func _flag_bool(ws: Node, key: String) -> bool:
	if ws != null and ws.has_method("get_flag"):
		return bool(ws.call("get_flag", key, false))
	return false


func _unlocked_key(id: String) -> String:
	return FLAG_UNLOCKED_PREFIX + id + FLAG_UNLOCKED_SUFFIX


func _bought_key(id: String) -> String:
	return FLAG_BOUGHT_PREFIX + id


func _complete_three_steps(t: Node) -> void:
	_press(t, KEY_LIGHT_ATTACK)
	_press(t, KEY_ROLL)
	_press(t, KEY_INTERACT)


# ===========================================================================
# A) 裁决 A26 · grace.tutorial.step_index 世界持久层单调递增（按 max 写）
# ===========================================================================
func _test_A_world_step_index_monotonic() -> void:
	_sig_events.clear()
	var ws: Node = _make_ws()
	var fw: FakeWriter = _make_writer()
	var t: Node = _make_tut(ws, fw, _make_wave(), _make_label())

	_ck("A1 世界 flag 初始基线 0", _flag_int(ws, FLAG_TUTORIAL_STEP_INDEX) == 0,
			"world_step_index=%d" % _flag_int(ws, FLAG_TUTORIAL_STEP_INDEX))
	_ck("A2 世界 flag 三段式合法（匹配 I-1 正则）",
			FLAG_TUTORIAL_STEP_INDEX.split(".").size() == 3,
			"key=%s" % FLAG_TUTORIAL_STEP_INDEX)

	_press(t, KEY_LIGHT_ATTACK)
	_ck("A3 第 1 步完成 → 世界 flag = 1", _flag_int(ws, FLAG_TUTORIAL_STEP_INDEX) == 1,
			"world_step_index=%d runtime=%s" % [_flag_int(ws, FLAG_TUTORIAL_STEP_INDEX),
				str(_snap(t).get("step_index", "?"))])
	_press(t, KEY_ROLL)
	_ck("A4 第 2 步完成 → 世界 flag = 2", _flag_int(ws, FLAG_TUTORIAL_STEP_INDEX) == 2,
			"world_step_index=%d" % _flag_int(ws, FLAG_TUTORIAL_STEP_INDEX))
	_press(t, KEY_INTERACT)
	_ck("A5 第 3 步完成 → 世界 flag = 3（历史最高）",
			_flag_int(ws, FLAG_TUTORIAL_STEP_INDEX) == TOTAL_STEPS,
			"world_step_index=%d" % _flag_int(ws, FLAG_TUTORIAL_STEP_INDEX))
	_ck("A6 get_snapshot() 同时暴露运行时游标与世界 flag 真值",
			int(_snap(t).get("world_step_index", -1)) == _flag_int(ws, FLAG_TUTORIAL_STEP_INDEX) \
					and int(_snap(t).get("step_index", -1)) == TOTAL_STEPS,
			"runtime=%s world=%s ws=%d" % [str(_snap(t).get("step_index", "?")),
				str(_snap(t).get("world_step_index", "?")), _flag_int(ws, FLAG_TUTORIAL_STEP_INDEX)])
	_ck("A7 get_runtime_step_index() / get_world_step_index() 接口齐备",
			t.has_method("get_runtime_step_index") and t.has_method("get_world_step_index") \
					and int(t.call("get_world_step_index")) == TOTAL_STEPS,
			"runtime=%s world=%s" % [str(t.call("get_runtime_step_index")),
				str(t.call("get_world_step_index"))])
	# A26 不改落盘点：step_index 的 set_flag 合并入既有 3 步 + 1 完成，共 4 次 commit。
	_ck("A8 A26 不新增落盘点（set_flag→commit 仍 4 次，时序末位 tutorial_completed）",
			fw.commits.size() == 4 and fw.commits[3] == "tutorial_completed",
			"commits=%s" % str(fw.commits))

	# 独立夹具：外部注入更大的历史最高值后，继续推进不得把世界 flag 回写更小值。
	var ws2: Node = _make_ws()
	var t2: Node = _make_tut(ws2, _make_writer(), _make_wave(), _make_label())
	_press(t2, KEY_LIGHT_ATTACK)
	ws2.call("set_flag", FLAG_TUTORIAL_STEP_INDEX, 7)   # 模拟旧档/回放已有更高历史进度
	_press(t2, KEY_ROLL)
	_press(t2, KEY_INTERACT)
	_ck("A9 按 max 写：外部更高值 7 不被后续 2/3 回写覆盖（绝不回退）",
			_flag_int(ws2, FLAG_TUTORIAL_STEP_INDEX) == 7,
			"world_step_index=%d（期望 7，按 max 写而非直接覆盖）" % _flag_int(ws2, FLAG_TUTORIAL_STEP_INDEX))


# ===========================================================================
# B) 裁决 A26 · T 重开：运行时游标归零，世界 flag 不变、completed 单向
# ===========================================================================
func _test_B_T_restart() -> void:
	_sig_events.clear()
	var ws: Node = _make_ws()
	var t: Node = _make_tut(ws, _make_writer(), _make_wave(), _make_label())
	_complete_three_steps(t)
	_ck("B1 前置：三步完成 → 世界 flag=3 / completed=true",
			_flag_int(ws, FLAG_TUTORIAL_STEP_INDEX) == TOTAL_STEPS \
					and _flag_bool(ws, FLAG_TUTORIAL_COMPLETED),
			"world=%d completed=%s" % [_flag_int(ws, FLAG_TUTORIAL_STEP_INDEX),
				str(_flag_bool(ws, FLAG_TUTORIAL_COMPLETED))])

	_sig_events.clear()   # 只统计「T 重开之后」重走三步的信号，避免混入前置三步
	_press(t, KEY_RESTART)
	var s: Dictionary = _snap(t)
	_ck("B2 按 T 重开 → 运行时游标归零（step_index==0 / STEP_LIGHT_ATTACK）",
			int(s.get("step_index", -1)) == 0 and str(s.get("state_name", "")) == "STEP_LIGHT_ATTACK",
			"runtime=%s state=%s" % [str(s.get("step_index", "?")), str(s.get("state_name", "?"))])
	_ck("B3 T 重开绝不回退世界 flag（仍 = 3）",
			_flag_int(ws, FLAG_TUTORIAL_STEP_INDEX) == TOTAL_STEPS \
					and int(s.get("world_step_index", -1)) == TOTAL_STEPS,
			"ws=%d snapshot_world=%s" % [_flag_int(ws, FLAG_TUTORIAL_STEP_INDEX),
				str(s.get("world_step_index", "?"))])
	_ck("B4 T 重开绝不清除单向完成 flag（completed 仍 true）",
			_flag_bool(ws, FLAG_TUTORIAL_COMPLETED) and bool(s.get("completed_flag", false)),
			"completed=%s" % str(_flag_bool(ws, FLAG_TUTORIAL_COMPLETED)))
	_ck("B5 T 重开教学 HUD 进度回到 1/3（运行时游标显示）",
			"1/3" in str(s.get("tutorial_hud_text", "")),
			"text=%s" % str(s.get("tutorial_hud_text", "")))
	_ck("B6 T 重开显示 1/3 与世界 flag=3 同时成立（显示口径 ≠ 世界 flag）",
			"1/3" in str(s.get("tutorial_hud_text", "")) \
					and _flag_int(ws, FLAG_TUTORIAL_STEP_INDEX) == 3,
			"hud='%s' world=%d" % [str(s.get("tutorial_hud_text", "")),
				_flag_int(ws, FLAG_TUTORIAL_STEP_INDEX)])

	_complete_three_steps(t)
	var s2: Dictionary = _snap(t)
	_ck("B7 重开后再走三步：状态机 / 信号仍完整，世界 flag 恒 3 不回退",
			_sig_events.size() == 3 and int(s2.get("world_step_index", -1)) == 3 \
					and _flag_int(ws, FLAG_TUTORIAL_STEP_INDEX) == 3,
			"sig=%d world=%d" % [_sig_events.size(), _flag_int(ws, FLAG_TUTORIAL_STEP_INDEX)])
	_ck("B8 重开不重复刷点（已完成存档 reward=0 / points 恒 100）",
			_flag_int(ws, FLAG_POINTS) == 100 and int(s2.get("total_reward", -1)) == 0,
			"points=%d total_reward=%s" % [_flag_int(ws, FLAG_POINTS),
				str(s2.get("total_reward", "?"))])

	# 中途 T 重开（未完成存档）：世界 flag 保持当时历史最高 2，不回退。
	var ws3: Node = _make_ws()
	var t3: Node = _make_tut(ws3, _make_writer(), _make_wave(), _make_label())
	_press(t3, KEY_LIGHT_ATTACK)
	_press(t3, KEY_ROLL)
	_ck("B9 前置：中途已到历史最高 2", _flag_int(ws3, FLAG_TUTORIAL_STEP_INDEX) == 2,
			"world=%d" % _flag_int(ws3, FLAG_TUTORIAL_STEP_INDEX))
	_press(t3, KEY_RESTART)
	var s3: Dictionary = _snap(t3)
	_ck("B10 中途 T 重开：运行时归零 / 世界 flag 仍 2 / completed 未误置",
			int(s3.get("step_index", -1)) == 0 \
					and _flag_int(ws3, FLAG_TUTORIAL_STEP_INDEX) == 2 \
					and not _flag_bool(ws3, FLAG_TUTORIAL_COMPLETED),
			"runtime=%s world=%d completed=%s" % [str(s3.get("step_index", "?")),
				_flag_int(ws3, FLAG_TUTORIAL_STEP_INDEX), str(_flag_bool(ws3, FLAG_TUTORIAL_COMPLETED))])
	_complete_three_steps(t3)
	_ck("B11 中途重开后继续推进：世界 flag 单调 2→3",
			_flag_int(ws3, FLAG_TUTORIAL_STEP_INDEX) == 3,
			"world=%d" % _flag_int(ws3, FLAG_TUTORIAL_STEP_INDEX))


# ===========================================================================
# C) 裁决 A26 · hud.gd 教学进度显示 = 运行时游标，绝不读世界 flag
# ===========================================================================
func _test_C_hud_runtime_cursor() -> void:
	var ws: Node = _make_ws()
	var hud: Node = _make_hud(ws)
	var t: Node = _make_tut(ws, _make_writer(), _make_wave(), _make_label())

	_ck("C1 hud.gd 提供教学进度显示只读接口",
			hud.has_method("read_tutorial_progress") and hud.has_method("tutorial_progress_text"),
			"read=%s text=%s" % [str(hud.has_method("read_tutorial_progress")),
				str(hud.has_method("tutorial_progress_text"))])
	_ck("C2 hud.gd 登记「不用于显示」的世界 flag 常量",
			str(hud.get("FLAG_TUTORIAL_STEP_INDEX")) == FLAG_TUTORIAL_STEP_INDEX,
			"key=%s" % str(hud.get("FLAG_TUTORIAL_STEP_INDEX")))
	_ck("C3 LIT_SOURCE_FLAGS 仍 2 项（v050 D5 口径不回退）",
			(hud.get("LIT_SOURCE_FLAGS") as Array).size() == 2,
			"sources=%s" % str(hud.get("LIT_SOURCE_FLAGS")))

	var p0: Dictionary = hud.call("read_tutorial_progress", t) as Dictionary
	_ck("C4 read_tutorial_progress 来源为运行时游标（非世界 flag）",
			str(p0.get("source", "")) == "runtime_cursor" \
					and str(p0.get("world_flag_key_not_for_display", "")) == FLAG_TUTORIAL_STEP_INDEX,
			"source=%s key=%s" % [str(p0.get("source", "?")),
				str(p0.get("world_flag_key_not_for_display", "?"))])
	_ck("C5 初始教学进度显示 1/3",
			"1/3" in str(p0.get("text", "")),
			"text=%s" % str(p0.get("text", "")))

	_complete_three_steps(t)
	var p1: Dictionary = hud.call("read_tutorial_progress", t) as Dictionary
	_ck("C6 完成后显示 3/3（运行时游标 = 3）",
			"3/3" in str(p1.get("text", "")) and int(p1.get("runtime_step_index", -1)) == 3,
			"text=%s runtime=%s" % [str(p1.get("text", "")),
				str(p1.get("runtime_step_index", "?"))])

	_press(t, KEY_RESTART)
	var p2: Dictionary = hud.call("read_tutorial_progress", t) as Dictionary
	_ck("C7 T 重开后显示回到 1/3（世界 flag 仍 3，显示绝不读世界 flag）",
			"1/3" in str(p2.get("text", "")) and int(p2.get("runtime_step_index", -1)) == 0 \
					and _flag_int(ws, FLAG_TUTORIAL_STEP_INDEX) == 3,
			"text=%s runtime=%s world=%d" % [str(p2.get("text", "")),
				str(p2.get("runtime_step_index", "?")), _flag_int(ws, FLAG_TUTORIAL_STEP_INDEX)])
	_ck("C8 tutorial_progress_text 纯参数函数（0→1/3，2→3/3，越界 clamp）",
			str(hud.call("tutorial_progress_text", 0, 3)) == "赐福引导 1/3" \
					and str(hud.call("tutorial_progress_text", 2, 3)) == "赐福引导 3/3" \
					and str(hud.call("tutorial_progress_text", 99, 3)) == "赐福引导 3/3",
			"t0=%s t2=%s t99=%s" % [str(hud.call("tutorial_progress_text", 0, 3)),
				str(hud.call("tutorial_progress_text", 2, 3)),
				str(hud.call("tutorial_progress_text", 99, 3))])


# ===========================================================================
# D) ③ 兼容旧档 · legacy_bought_flag_key / is_purchased_in_flags /
#    load_state_from_flags 接入 hud.gd / grace_upgrade_runtime.gd 读取路径
# ===========================================================================
func _test_D_legacy_compat() -> void:
	# 纯旧档夹具：只写 grace.trial.bought_<id>=true，绝不写 unlocked；给足点数。
	var legacy_ws: Node = _make_ws()
	var legacy_key: String = GraceUpgradeService.legacy_bought_flag_key(EXPECT_ID)
	_ck("D1 legacy_bought_flag_key() 生成旧档三段式 key",
			legacy_key == _bought_key(EXPECT_ID) and legacy_key.split(".").size() == 3,
			"key=%s" % legacy_key)
	legacy_ws.call("set_flag", FLAG_POINTS, 1000)
	legacy_ws.call("set_flag", legacy_key, true)
	_ck("D2 纯旧档：unlocked 键缺失 / 旧 bought_ 键为真",
			not _flag_bool(legacy_ws, _unlocked_key(EXPECT_ID)) \
					and _flag_bool(legacy_ws, legacy_key),
			"unlocked=%s bought=%s" % [str(_flag_bool(legacy_ws, _unlocked_key(EXPECT_ID))),
				str(_flag_bool(legacy_ws, legacy_key))])
	_ck("D3 is_purchased_in_flags() 纯函数识别纯旧档",
			GraceUpgradeService.is_purchased_in_flags({legacy_key: true}, EXPECT_ID) \
					and not GraceUpgradeService.is_purchased_in_flags({}, EXPECT_ID),
			"legacy_only=true empty=false（纯函数，不碰 WorldState）")

	# hud.gd 读取路径：get_shop_view() 应把纯旧档识别为「已解锁」。
	var fw: FakeWriter = _make_writer()
	var hud: Node = _make_hud(legacy_ws)
	hud.call("bind_grace_deps", legacy_ws, fw, null)   # 注入在 _ready 之后
	var view: Dictionary = hud.call("get_shop_view") as Dictionary
	var hit: Dictionary = {}
	for it: Variant in (view.get("items", []) as Array):
		var row: Dictionary = it as Dictionary
		if str(row.get("id", "")) == EXPECT_ID:
			hit = row
	_ck("D4 hud.get_shop_view() 兼容读取：纯旧档该项 unlocked=true",
			not hit.is_empty() and bool(hit.get("unlocked", false)) \
					and not bool(hit.get("affordable", true)),
			"item=%s" % str(hit))

	# hud.gd 读取路径：purchase_upgrade() 经 load_state_from_flags 恢复 → F1 拒绝重复购买。
	var buy: Dictionary = hud.call("purchase_upgrade", 0) as Dictionary
	_ck("D5 hud.purchase_upgrade() 纯旧档拒绝重复购买（F1 防刷不破坏）",
			not bool(buy.get("ok", true)) \
					and str(buy.get("reason", "")) == "can_purchase_rejected",
			"ok=%s reason=%s balance=%s" % [str(buy.get("ok", "?")),
				str(buy.get("reason", "?")), str(buy.get("balance", "?"))])
	_ck("D6 拒绝路径绝不新写 bought_ / 绝不新写 unlocked（写仅发生在成功购买）",
			not _flag_bool(legacy_ws, _unlocked_key(EXPECT_ID)) \
					and _flag_bool(legacy_ws, legacy_key),
			"unlocked=%s bought=%s" % [str(_flag_bool(legacy_ws, _unlocked_key(EXPECT_ID))),
				str(_flag_bool(legacy_ws, legacy_key))])

	# grace_upgrade_runtime.gd 读取路径：try_purchase() 纯旧档识别已购 → 拒绝。
	var rt: Node = _make_runtime()
	var tp: Dictionary = rt.call("try_purchase", EXPECT_ID, legacy_ws, fw) as Dictionary
	_ck("D7 grace_upgrade_runtime.try_purchase() 纯旧档识别已购 → 拒绝",
			not bool(tp.get("ok", true)) and str(tp.get("reason", "")) == "duplicate_id",
			"ok=%s reason=%s" % [str(tp.get("ok", "?")), str(tp.get("reason", "?"))])

	# grace_upgrade_runtime.gd 读取路径：apply_purchased() 不再把纯旧档判为 not_purchased。
	var ap: Dictionary = rt.call("apply_purchased", null, legacy_ws) as Dictionary
	var legacy_status: String = ""
	for it2: Variant in (ap.get("items", []) as Array):
		var row2: Dictionary = it2 as Dictionary
		if str(row2.get("id", "")) == EXPECT_ID:
			legacy_status = str(row2.get("status", ""))
	_ck("D8 grace_upgrade_runtime.apply_purchased() 兼容读取：纯旧档该项非 not_purchased",
			not legacy_status.is_empty() and legacy_status != "not_purchased",
			"checked=%s status=%s（encounter 未注入 → 效果如实降级，但已购识别生效）" % [
				str(ap.get("checked", "?")), legacy_status])

	# 新档回归：只写 unlocked 的存档仍被识别（裁决 A23 不回退）。
	var fresh_ws: Node = _make_ws()
	fresh_ws.call("set_flag", FLAG_POINTS, 1000)
	fresh_ws.call("set_flag", GraceUpgradeService.authoritative_unlocked_key(EXPECT_ID), true)
	var hud2: Node = _make_hud(fresh_ws)
	hud2.call("bind_grace_deps", fresh_ws, _make_writer(), null)
	var view2: Dictionary = hud2.call("get_shop_view") as Dictionary
	var hit2: Dictionary = {}
	for it3: Variant in (view2.get("items", []) as Array):
		var row3: Dictionary = it3 as Dictionary
		if str(row3.get("id", "")) == EXPECT_ID:
			hit2 = row3
	_ck("D9 新档（仅 unlocked）仍识别已购，A23 不回退",
			not hit2.is_empty() and bool(hit2.get("unlocked", false)),
			"item=%s" % str(hit2))

	# 写入侧仍只写 unlocked：成功购买另一未购项后，绝不新写 bought_。
	var buy_ws: Node = _make_ws()
	buy_ws.call("set_flag", FLAG_POINTS, 1000)
	var hud3: Node = _make_hud(buy_ws)
	hud3.call("bind_grace_deps", buy_ws, _make_writer(), null)
	var ok_buy: Dictionary = hud3.call("purchase_upgrade", 1) as Dictionary
	_ck("D10 成功购买只写 unlocked / 绝不新写 grace.trial.bought_<id>（A23 / F1~F8 不变）",
			bool(ok_buy.get("ok", false)) \
					and _flag_bool(buy_ws, _unlocked_key(OTHER_ID)) \
					and not _flag_bool(buy_ws, _bought_key(OTHER_ID)),
			"ok=%s unlocked=%s bought=%s spent=%d" % [str(ok_buy.get("ok", "?")),
				str(_flag_bool(buy_ws, _unlocked_key(OTHER_ID))),
				str(_flag_bool(buy_ws, _bought_key(OTHER_ID))),
				_flag_int(buy_ws, FLAG_SPENT_POINTS)])
	_ck("D11 接入后 load_state_from_flags 恢复项仍拒绝重复购买（F1 幂等）",
			not bool((hud3.call("purchase_upgrade", 1) as Dictionary).get("ok", true)),
			"第二次购买同 id 被拒绝（已购集合只增不减）")


# ===========================================================================
# E) 裁决 A27 · 节点数 41 + 教学 3 节点（补的 1 条回归用例）+ 37 PASS 基线
# ===========================================================================
func _test_E_nodes_and_A27() -> void:
	var ps: PackedScene = ResourceLoader.load(
			COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	_ck("E1 courtyard.tscn 加载成功（CACHE_MODE_IGNORE）", ps != null,
			"path=%s" % COURTYARD_PATH)
	if ps == null:
		return
	var disk_nodes: int = ps.get_state().get_node_count()
	_ck("E2 节点数 = 41（裁决 A27 授权 v040 期望值 38→41）",
			disk_nodes == NODE_COUNT_EXPECTED,
			"node_count=%d expected=%d delta=+%d" % [disk_nodes, NODE_COUNT_EXPECTED,
				disk_nodes - 33])

	# 【A27 补的 1 条回归用例】教学 3 节点真实存在且类型正确。
	var inst: Node = _track(ps.instantiate()) as Node
	var hud_layer: Node = inst.get_node_or_null("TutorialHud")
	var tut_label: Node = inst.get_node_or_null("TutorialHud/TutorialLabel")
	var tut_dir: Node = inst.get_node_or_null("TutorialDirector")
	var three_ok: bool = hud_layer is CanvasLayer and tut_label is Label and tut_dir != null \
			and tut_dir.get_script() != null
	_ck("E3 tutorial_three_nodes_present（A27 补的 1 条回归用例：教学 3 节点）",
			three_ok,
			"TutorialHud=%s TutorialLabel=%s TutorialDirector=%s（CanvasLayer/Label/Node+脚本）" % [
				str(hud_layer is CanvasLayer), str(tut_label is Label),
				str(tut_dir != null and tut_dir.get_script() != null)])

	# v040 断言后值实证（A27：只改精确期望值，不删断言、不放宽其它判定）。
	var v040: Script = ResourceLoader.load(
			V040_SCRIPT_PATH, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
	var consts: Dictionary = v040.get_script_constant_map() if v040 != null else {}
	var after: int = int(consts.get("NODE_COUNT_AFTER", -1))
	var delta_c: int = int(consts.get("NODE_COUNT_DELTA", -1))
	_ck("E4 v040 NODE_COUNT_AFTER=41 / DELTA=8（A27 断言后值，只改数字）",
			after == NODE_COUNT_EXPECTED and delta_c == NODE_COUNT_DELTA_EXPECTED,
			"NODE_COUNT_AFTER=%d NODE_COUNT_DELTA=%d" % [after, delta_c])
	_ck("E5 v040 37 PASS 基线口径不回退（节点数 41 + 教学 3 节点）",
			disk_nodes == NODE_COUNT_EXPECTED and three_ok,
			"v040 H 组 courtyard_node_count 断言口径成立；v040 37 PASS 由本轮全回归独立复跑实证（r28b_regress_verify_wave_runtime_v040.log），本脚本不伪造该数字")


# ===========================================================================
# F) completed 单向 / 依赖缺失降级不新增落盘点
# ===========================================================================
func _test_F_completed_and_degrade() -> void:
	var ws: Node = _make_ws()
	var t: Node = _make_tut(ws, _make_writer(), _make_wave(), _make_label())
	_ck("F1 初始 completed=false（单向 false→true）",
			not _flag_bool(ws, FLAG_TUTORIAL_COMPLETED),
			"completed=%s" % str(_flag_bool(ws, FLAG_TUTORIAL_COMPLETED)))
	_complete_three_steps(t)
	_ck("F2 三步完成 → completed=true", _flag_bool(ws, FLAG_TUTORIAL_COMPLETED),
			"completed=%s" % str(_flag_bool(ws, FLAG_TUTORIAL_COMPLETED)))
	_press(t, KEY_RESTART)
	_press(t, KEY_RESTART)
	_ck("F3 多次 T 重开 completed 恒 true / 世界 flag 恒 3（均不回退）",
			_flag_bool(ws, FLAG_TUTORIAL_COMPLETED) \
					and _flag_int(ws, FLAG_TUTORIAL_STEP_INDEX) == TOTAL_STEPS,
			"completed=%s world=%d" % [str(_flag_bool(ws, FLAG_TUTORIAL_COMPLETED)),
				_flag_int(ws, FLAG_TUTORIAL_STEP_INDEX)])

	# 依赖全缺失：A26 的 step_index 只走进程内镜像，绝不新增 commit / 绝不崩。
	var t2: Node = _make_tut(null, null, null, null)
	_complete_three_steps(t2)
	var s2: Dictionary = _snap(t2)
	_ck("F4 全依赖缺失：commit_count=0 / 世界镜像单调到 3 / 不崩",
			int(s2.get("commit_count", -1)) == 0 \
					and int(s2.get("world_step_index", -1)) == TOTAL_STEPS \
					and str(s2.get("state_name", "")) == "COMPLETED",
			"commits=%s world=%s state=%s degrade=%s" % [str(s2.get("commit_count", "?")),
				str(s2.get("world_step_index", "?")), str(s2.get("state_name", "?")),
				str(s2.get("degrade_reason", ""))])


# ===========================================================================
func _initialize() -> void:
	print("[RST-V060] === SELFTEST START | R28B 教学重启 / A26 单调 / A27 断言 / 兼容旧档 ===")
	_test_A_world_step_index_monotonic()
	_test_B_T_restart()
	_test_C_hud_runtime_cursor()
	_test_D_legacy_compat()
	_test_E_nodes_and_A27()
	_test_F_completed_and_degrade()
	_finish()
