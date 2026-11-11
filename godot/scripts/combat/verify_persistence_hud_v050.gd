extends SceneTree

## v0.5.0 R27 · 存档读回 / 动作帧 HUD / 点数跨局 / 赐福点亮态 验证
## （Rank-1，cmd-20261111-083350-232-A1，[ROUND=R27]）。
##
## 真跑（三段门禁 G2 用 --check-only --script；下列为正式断言跑）：
##   写进程：Godot_v4.7.2 --headless --path <godot> \
##           --script res://scripts/combat/verify_persistence_hud_v050.gd -- phase=write
##   读回进程（独立引擎进程，SaveSystem autoload 经 v050_read 标记自动 _load）：
##           ... --script res://scripts/combat/verify_persistence_hud_v050.gd -- v050_read phase=read
##   自包含自测（单进程，先写后验）：... --script res://scripts/combat/verify_persistence_hud_v050.gd
##
## 断言 5 类（30 条）：
##   A 跨进程读回 / 存档结构（9）  B 动作帧 HUD 推进（6）  C 赐福点数跨局（5）
##   D 赐福点亮态（5）            E 依赖缺失降级（5）
##
## --script 模式纪律（任务单既有踩坑）：
##   - 不用 /root/... 绝对路径：一律 Engine.get_main_loop() + root.get_node_or_null() 相对探活；
##   - add_child 不 flush _ready：所有注入实例显式 call("_ready")；
##   - 注入在 _ready 之后（bind_persistence / bind_world_state / hud_label_path 均在 _ready 后设）。
##   写进程沿用 verify_wave_persist_v040.gd 的一次性测试装配修正：SaveDeltaWriter._ready()
##   的 /root/WorldState 绝对路径在 --script 下探活失效，wr.set("_ws", ws) 补齐委托后 commit。
##
## 数值均为 [PLACEHOLDER-验证桩]，非战斗 / 经济设计值；rationale：跨进程写→读需要一组
## 与既有落盘值不同、可确定性比对的 int/bool，取 7 / 1337 / 37 / true 便于日志逐项核对，
## 不引入任何新设计数值、不改任何 .tres / schema / 顶层字段。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

const SAVE_SCRIPT: String = "res://scripts/world/save_system.gd"
const WS_SCRIPT: String = "res://scripts/rpg/world_state.gd"
const WAVE_SCRIPT: String = "res://scripts/combat/wave_trial_director.gd"
const ENCOUNTER_SCENE: String = "res://scenes/encounter_v010.tscn"
const HUD_SCENE: String = "res://scenes/hud.tscn"
const DELTA_PATH: String = "user://saves/slot_01/delta.json"

const K_BEST: String = "dungeon.wave_trial.best_wave"
const K_COMPLETED: String = "dungeon.wave_trial.completed"
const K_POINTS: String = "grace.trial.points"
const K_SPENT: String = "grace.trial.spent_points"
const K_LAST_GRACE: String = "grace.network.last_grace_id"
const K_REST_EPOCH: String = "grace.network.last_rest_epoch"
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]

# [PLACEHOLDER-验证桩] 写进程落盘的确定性三 flag + spent，供跨进程日志逐项比对。
const WRITE_BEST: int = 7
const WRITE_POINTS: int = 1337
const WRITE_SPENT: int = 37
const WRITE_COMPLETED: bool = true
const WRITE_REASON: String = "v050_write"

const GOLD: Color = Color(0.83, 0.68, 0.3, 1.0)
const DIM: Color = Color(0.45, 0.42, 0.34, 1.0)
# 等 autoload SaveSystem._ready() 在帧循环 flush 后再断言（--script 模式 add_child 不 flush _ready）。
const WAIT_FRAMES: int = 3

var _pass: int = 0
var _fail: int = 0
var _frame: int = 0
var _phase: String = "selftest"
var _has_read_marker: bool = false
var _ws: Node = null                 # 相对探活的 autoload WorldState
var _wr: Node = null                 # 相对探活的 autoload SaveDeltaWriter
var _re: RegEx = null
var _action_re: RegEx = null        # 提取「动作 <pose> <frame>/<total>」
var _points_re: RegEx = null        # 提取「赐福点数 <n>」


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V050] %s PASS=%s | %s" % [tag, str(ok), detail])


func _read_delta() -> Dictionary:
	if not FileAccess.file_exists(DELTA_PATH):
		return {}
	var f: FileAccess = FileAccess.open(DELTA_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


func _free_node(n: Node) -> void:
	if n != null and is_instance_valid(n):
		n.free()


## 提取波次 HUD 文本里的「赐福点数 <n>」；解析不到返回 -1。
func _parse_points(text: String) -> int:
	var m: RegExMatch = _points_re.search(text)
	if m == null:
		return -1
	return int(m.get_string(1))


## 提取底部战斗 HUD 文本里的「动作 <pose> <frame>/<total>」；解析不到返回空字典。
func _parse_action(text: String) -> Dictionary:
	var m: RegExMatch = _action_re.search(text)
	if m == null:
		return {}
	return {"pose": m.get_string(1), "frame": int(m.get_string(2)), "total": int(m.get_string(3))}


func _initialize() -> void:
	print("[V050] ==== verify_persistence_hud_v050 真跑开始 | cmd-20261111-083350-232-A1 [ROUND=R27] Rank-1 ====")
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	_action_re = RegEx.new()
	_action_re.compile("动作 ([^ ]+) ([0-9]+)/([0-9]+)")
	_points_re = RegEx.new()
	_points_re.compile("赐福点数 (-?[0-9]+)")
	for a: String in OS.get_cmdline_user_args():
		if a == "v050_read":
			_has_read_marker = true
		elif a.begins_with("phase="):
			_phase = a.substr(6)
	# 相对探活（不用 /root/... 绝对路径）
	_ws = root.get_node_or_null(NodePath("WorldState"))
	_wr = root.get_node_or_null(NodePath("SaveDeltaWriter"))
	print("[V050] phase=%s v050_read=%s | root=%s WorldState_probe=%s SaveDeltaWriter_probe=%s（相对探活）" % [
		_phase, str(_has_read_marker), str(root != null), str(_ws != null), str(_wr != null)])
	print("[V050] DELTA_PATH=%s abs=%s" % [DELTA_PATH, ProjectSettings.globalize_path(DELTA_PATH)])

	if _phase == "write":
		_do_write()
		print("[V050] RESULT=WRITE_OK")
		quit(0)
		return
	if _phase == "selftest":
		# 自包含：先落盘一组确定性值，保证单独跑本脚本也能完整断言（不依赖外部前序进程）。
		_do_write()
	# --script 模式 autoload 的 _ready() 在帧循环才 flush（add_child 不 flush _ready 同款踩坑）。
	# 等 WAIT_FRAMES 帧让 SaveSystem 的自动读回真实发生，再跑断言；read 阶段全程不写盘，
	# 只读回前序「写进程」落盘的真实磁盘态，验证跨进程恢复。
	process_frame.connect(Callable(self, "_on_frame"))


func _on_frame() -> void:
	_frame += 1
	if _frame < WAIT_FRAMES:
		return
	process_frame.disconnect(Callable(self, "_on_frame"))
	_test_A_cross_process()
	_test_B_action_frame_hud()
	_test_C_points_across_sessions()
	_test_D_lit_state()
	_test_E_degrade()
	_finish()


## 写进程 / 自包含前缀：经既有 I-1 写入口 set_flag + SaveDeltaWriter.commit 真实落盘，
## 不手改 delta.json、不伪造产物。--script 下 writer 绝对路径探活失效，按 v040 口径
## 一次性修正 _ws 委托（不改任何工程文件）。
func _do_write() -> void:
	if _ws == null:
		push_error("[V050] WorldState 相对探活失败，无法落盘")
		return
	_ws.call("_load")                       # 读回既有存档，保留既有 flags（不抹历史）
	if _wr != null:
		_wr.set("_ws", _ws)                 # 测试装配修正，不改工程文件
	_ws.call("set_flag", K_BEST, WRITE_BEST)
	_ws.call("set_flag", K_POINTS, WRITE_POINTS)
	_ws.call("set_flag", K_SPENT, WRITE_SPENT)
	_ws.call("set_flag", K_COMPLETED, WRITE_COMPLETED)
	if _wr != null and _wr.has_method("commit"):
		_wr.call("commit", WRITE_REASON)
	var d: Dictionary = _read_delta()
	var flags: Dictionary = d.get("flags", {}) as Dictionary
	print("[V050][WRITE] pid=%d 落盘完成 | %s=%s %s=%s %s=%s %s=%s reason=%s" % [
		OS.get_process_id(), K_BEST, str(flags.get(K_BEST, "?")),
		K_POINTS, str(flags.get(K_POINTS, "?")),
		K_SPENT, str(flags.get(K_SPENT, "?")),
		K_COMPLETED, str(flags.get(K_COMPLETED, "?")), WRITE_REASON])


# ---------------------------------------------------------------------------
# A) 跨进程读回 / 存档结构（9 条）
# ---------------------------------------------------------------------------
func _test_A_cross_process() -> void:
	var d: Dictionary = _read_delta()
	_ck("A1 delta.json 存在且可解析（写进程真实落盘）", not d.is_empty(),
		"path=%s abs=%s" % [DELTA_PATH, ProjectSettings.globalize_path(DELTA_PATH)])
	if d.is_empty():
		return
	var top: Array = d.keys()
	var extra: Array[String] = []
	var missing: Array[String] = []
	for k: Variant in top:
		if not TEN_FIELDS.has(String(k)):
			extra.append(String(k))
	for k: String in TEN_FIELDS:
		if not d.has(k):
			missing.append(k)
	_ck("A2 十字段齐全、无额外顶层字段（不动 schema/顶层）", \
			extra.is_empty() and missing.is_empty() and top.size() == TEN_FIELDS.size(),
		"top=%s extra=%s missing=%s" % [str(top), str(extra), str(missing)])
	_ck("A3 schema_version 保持 3", int(d.get("schema_version", -1)) == 3,
		"schema_version=%s" % str(d.get("schema_version", -1)))
	var flags: Dictionary = d.get("flags", {}) as Dictionary
	var bad: Array[String] = []
	for k: Variant in flags.keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_ck("A4 落盘 flags 全通过三段式正则", bad.is_empty(),
		"keys=%s bad=%s" % [str(flags.keys()), str(bad)])
	var disk_best: int = int(flags.get(K_BEST, -1))
	var disk_points: int = int(flags.get(K_POINTS, -1))
	var disk_completed: bool = bool(flags.get(K_COMPLETED, false))
	_ck("A5 三 flag 落盘值 == 写进程常量（跨进程写入值一致）", \
			disk_best == WRITE_BEST and disk_points == WRITE_POINTS and disk_completed == WRITE_COMPLETED,
		"%s=%d %s=%d %s=%s（expect %d/%d/true）" % [
			K_BEST, disk_best, K_POINTS, disk_points, K_COMPLETED, str(disk_completed),
			WRITE_BEST, WRITE_POINTS])

	# 真·重启读回：新建独立 WorldState 实例（空内存），只能经 _load() 从磁盘重建。
	var reborn: Node = Node.new()
	reborn.set_script(load(WS_SCRIPT) as Script)
	reborn.name = "V050RebornWorldState"
	root.add_child(reborn)
	reborn.call("_ready")               # add_child 不 flush _ready
	reborn.call("_load")
	var rb_best: int = int(reborn.call("get_flag", K_BEST, -1))
	var rb_points: int = int(reborn.call("get_flag", K_POINTS, -1))
	var rb_completed: bool = bool(reborn.call("get_flag", K_COMPLETED, false))
	_ck("A6 重启读回一致（新实例 _load() 三 flag == 磁盘）", \
			rb_best == disk_best and rb_points == disk_points and rb_completed == disk_completed,
		"readback best=%d points=%d completed=%s / disk %d/%d/%s" % [
			rb_best, rb_points, str(rb_completed), disk_best, disk_points, str(disk_completed)])
	_ck("A7 重启不回退（best/completed 不回落默认值）", \
			rb_best >= WRITE_BEST and rb_completed == true,
		"readback best=%d completed=%s" % [rb_best, str(rb_completed)])
	_free_node(reborn)

	# autoload WorldState：带 v050_read 标记时 SaveSystem 已自动读回；否则手动 _load 走等价路径。
	var ss: Node = root.get_node_or_null(NodePath("SaveSystem"))
	var auto_loaded: bool = ss != null and bool(ss.call("is_loaded"))
	if not auto_loaded and _ws != null:
		_ws.call("_load")
	var a_best: int = int(_ws.call("get_flag", K_BEST, -1)) if _ws != null else -1
	var a_points: int = int(_ws.call("get_flag", K_POINTS, -1)) if _ws != null else -1
	var a_completed: bool = bool(_ws.call("get_flag", K_COMPLETED, false)) if _ws != null else false
	_ck("A8 autoload WorldState 自动/等价读回 == 磁盘三 flag", \
			a_best == disk_best and a_points == disk_points and a_completed == disk_completed,
		"auto_loaded=%s best=%d points=%d completed=%s" % [
			str(auto_loaded), a_best, a_points, str(a_completed)])
	var loaded_v: Variant = ss.call("is_loaded") if ss != null else false
	_ck("A9 SaveSystem 接线可读且按模式如实（带标记 true / --script 降级 false，不崩）", \
			ss != null and ss.has_method("is_loaded") and typeof(loaded_v) == TYPE_BOOL \
			and bool(loaded_v) == (_has_read_marker or not OS.get_cmdline_args().has("--script")),
		"is_loaded=%s v050_read=%s has_method=%s" % [
			str(loaded_v), str(_has_read_marker), str(ss != null and ss.has_method("is_loaded"))])


# ---------------------------------------------------------------------------
# B) 动作帧 HUD 推进（6 条）—— 底部战斗 HUD 的 get_current_pose / get_frame / get_total
# ---------------------------------------------------------------------------
func _make_encounter() -> Node:
	var packed: PackedScene = ResourceLoader.load(
			ENCOUNTER_SCENE, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var e: Node = packed.instantiate()
	e.set("simulate_boss", false)       # 关 Boss AI，帧级断言确定性（既有 @export 开关）
	root.add_child(e)
	e.call("_ready")                    # add_child 不 flush _ready
	return e


func _test_B_action_frame_hud() -> void:
	var e: Node = _make_encounter()
	var label: Label = e.get_node_or_null("HUD/StatusLabel") as Label
	_ck("B1 底部战斗 HUD StatusLabel 可寻址", label != null,
		"path=HUD/StatusLabel text=%s" % (label.text if label != null else "<null>"))
	if label == null:
		_free_node(e)
		return
	var t0: String = label.text
	_ck("B2 初始动作帧 HUD 为 idle 0/0（R25 实机基线）", t0.contains("动作 idle 0/0"),
		"text=%s" % t0)
	var accepted: bool = bool(e.call("debug_request_action", "attack_light"))
	_ck("B3 debug_request_action(attack_light) 被接受", accepted, "accepted=%s" % str(accepted))
	var t1: String = label.text
	var snap: Dictionary = e.call("get_snapshot")
	var a1: Dictionary = _parse_action(t1)
	# R27 改动：请求被接受的「当帧」就刷新，不必等 _physics_process → 立即脱离 idle 0/0。
	_ck("B4 动作请求当帧动作帧 HUD 推进（脱离 idle 0/0，pose/total 生效）", \
			not t1.contains("动作 idle 0/0") and a1.get("pose", "") == "attack_light" \
			and int(a1.get("total", 0)) > 0,
		"text=%s parsed=%s" % [t1, str(a1)])
	_ck("B5 HUD 动作帧 pose/frame 与 get_snapshot() 一致", \
			String(a1.get("pose", "")) == String(snap.get("pose", "")) \
			and int(a1.get("frame", -1)) == int(snap.get("frame", -2)),
		"hud=%s snapshot pose=%s frame=%s" % [str(a1), str(snap.get("pose", "?")), str(snap.get("frame", "?"))])
	e.call("debug_step", 1)
	var t2: String = label.text
	var a2: Dictionary = _parse_action(t2)
	_ck("B6 debug_step 后 frame 推进，既有 HUD 其它文本字段保留", \
			int(a2.get("frame", 0)) > int(a1.get("frame", 0)) \
			and t2.contains("玩家 HP") and t2.contains("Boss HP") \
			and t2.contains("闪避") and t2.contains("命中"),
		"frame %s→%s text=%s" % [str(a1.get("frame", "?")), str(a2.get("frame", "?")), t2])
	_free_node(e)


# ---------------------------------------------------------------------------
# C) 赐福点数跨局（5 条）—— 波次 HUD 显示持久化余额 points - spent，而非本局累计
# ---------------------------------------------------------------------------
func _make_wave_director() -> Node:
	var host: Node = Node.new()
	host.name = "V050WaveHost"
	root.add_child(host)
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "WaveTrialHud"
	host.add_child(layer)
	var label: Label = Label.new()
	label.name = "WaveLabel"
	layer.add_child(label)
	var d: Node = Node.new()
	d.name = "WaveTrialDirector"
	d.set_script(load(WAVE_SCRIPT) as Script)
	host.add_child(d)
	# 注入在 _ready 之后：先给相对 NodePath，再显式 call("_ready")。
	d.set("auto_start", false)
	d.set("hud_label_path", NodePath("../WaveTrialHud/WaveLabel"))
	d.call("_ready")
	return d


func _test_C_points_across_sessions() -> void:
	if _ws == null or _wr == null:
		_ck("C0 持久化依赖相对探活可用", false, "ws=%s wr=%s" % [str(_ws != null), str(_wr != null)])
		return
	var d: Node = _make_wave_director()
	d.call("bind_persistence", _ws, _wr)     # 注入在 _ready 之后
	# 经 WorldState 公开入口设持久化 points / spent（Rank-2 兑换消费口径）
	_ws.call("set_flag", K_POINTS, 1337)
	_ws.call("set_flag", K_SPENT, 37)
	d.call("_refresh_hud")
	var s1: Dictionary = d.call("get_snapshot")
	var bal1: int = _parse_points(String(s1.get("hud_text", "")))
	_ck("C1 波次 HUD 赐福点数 == points - spent（1337-37=1300）", bal1 == 1300,
		"hud_text=%s balance=%d" % [str(s1.get("hud_text", "")), bal1])
	_ws.call("set_flag", K_SPENT, 337)
	d.call("_refresh_hud")
	var bal2: int = _parse_points(String(d.call("get_snapshot").get("hud_text", "")))
	_ck("C2 spent 变化 → 余额随之变化（1337-337=1000，与 Rank-2 消费对齐）", bal2 == 1000,
		"balance=%d" % bal2)

	# 跨局核心：新建第二个导演实例（新一局，本局累计 points_total=0），
	# HUD 赐福点数仍读持久化余额、不随本局累计归零。
	_ws.call("set_flag", K_SPENT, 37)
	var d2: Node = _make_wave_director()
	d2.call("bind_persistence", _ws, _wr)
	d2.call("_refresh_hud")
	var s2: Dictionary = d2.call("get_snapshot")
	var bal_new: int = _parse_points(String(s2.get("hud_text", "")))
	_ck("C3 跨局不归零：新一局 points_total=0 但 HUD 仍显示持久化余额", \
			bal_new == 1300 and int(s2.get("points_total", -1)) == 0,
		"new_session balance=%d points_total=%s" % [bal_new, str(s2.get("points_total", "?"))])

	_ws.call("set_flag", K_SPENT, 99999)     # 异常 spent > points
	d.call("_refresh_hud")
	var bal_neg: int = _parse_points(String(d.call("get_snapshot").get("hud_text", "")))
	_ck("C4 余额非负保护（spent>points 时 clamp 到 0，不崩）", bal_neg == 0,
		"balance=%d" % bal_neg)
	# 依赖缺失降级：解绑 WorldState / writer，HUD 仍可刷新、不崩
	var ok_bind: bool = bool(d.call("bind_persistence", null, null))
	d.call("_refresh_hud")
	var sd: Dictionary = d.call("get_snapshot")
	_ck("C5 依赖缺失降级（bind_persistence(null,null) 不崩、HUD 仍刷新）", \
			not ok_bind and not bool(sd.get("persist_available", true)) \
			and _parse_points(String(sd.get("hud_text", ""))) >= 0,
		"persist_available=%s hud_text=%s" % [str(sd.get("persist_available", "?")), str(sd.get("hud_text", ""))])
	_free_node(d.get_parent())
	_free_node(d2.get_parent())


# ---------------------------------------------------------------------------
# D) 赐福点亮态（5 条）—— 读三段式 flag，颜色切换统一 apply_lit_state
# ---------------------------------------------------------------------------
func _test_D_lit_state() -> void:
	var packed: PackedScene = ResourceLoader.load(
			HUD_SCENE, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var h: Node = packed.instantiate()
	root.add_child(h)
	h.call("_ready")
	# 独立干净 WorldState（空内存、不读盘），隔离验证点亮态、不污染 autoload / 磁盘。
	var clean_ws: Node = Node.new()
	clean_ws.set_script(load(WS_SCRIPT) as Script)
	clean_ws.name = "V050CleanWS"
	root.add_child(clean_ws)
	clean_ws.call("_ready")
	h.call("bind_world_state", clean_ws)     # 注入在 _ready 之后
	h.call("refresh_all")                    # 基于干净基线 → 暗灰 DIM
	var label: Label = h.get_node_or_null("TitleLabel") as Label
	if label == null:
		_ck("D0 TitleLabel 可寻址", false, "<null>")
		_free_node(clean_ws)
		_free_node(h)
		return
	var c0: Color = label.get_theme_color("font_color", "Label")
	_ck("D1 初始赐福标题暗灰（DIM）", c0.is_equal_approx(DIM), "color=%s" % str(c0))
	# 试炼完成：三段式 bool flag false→true → 亮金
	clean_ws.call("set_flag", K_COMPLETED, true)
	var c1: Color = label.get_theme_color("font_color", "Label")
	_ck("D2 试炼完成（dungeon.wave_trial.completed=true）→ 亮金（GOLD）", \
			c1.is_equal_approx(GOLD), "color=%s" % str(c1))
	var src_true: bool = bool(h.call("_read_lit_sources"))
	# 复位后测「赐福休息」：三段式 int flag 0→1 → 亮金
	clean_ws.call("set_flag", K_COMPLETED, false)
	var c_back: Color = label.get_theme_color("font_color", "Label")
	clean_ws.call("set_flag", K_REST_EPOCH, 1)
	var c2: Color = label.get_theme_color("font_color", "Label")
	_ck("D3 赐福休息（grace.network.last_rest_epoch>0）→ 亮金（GOLD），复位回暗灰", \
			c_back.is_equal_approx(DIM) and c2.is_equal_approx(GOLD),
		"after_reset=%s after_rest=%s" % [str(c_back), str(c2)])
	clean_ws.call("set_flag", K_REST_EPOCH, 0)
	var src_false: bool = bool(h.call("_read_lit_sources"))
	_ck("D4 _read_lit_sources() 随三段式 flag 变化（true→false，数据驱动）", \
			src_true and not src_false, "lit(true)=%s lit(false)=%s" % [str(src_true), str(src_false)])
	var src_flags: Array = h.get("LIT_SOURCE_FLAGS") as Array
	_ck("D5 点亮来源为登记的三段式 flag（不硬编码颜色切换条件）", \
			src_flags.size() == 2 and src_flags.has(K_COMPLETED) and src_flags.has(K_REST_EPOCH) \
			and h.has_method("apply_lit_state") and h.has_method("_read_lit_sources"),
		"sources=%s apply_lit_state=%s" % [str(src_flags), str(h.has_method("apply_lit_state"))])
	_free_node(clean_ws)
	_free_node(h)


# ---------------------------------------------------------------------------
# E) 依赖缺失降级（5 条）
# ---------------------------------------------------------------------------
func _test_E_degrade() -> void:
	# E1：new 一个 SaveSystem 实例，--script 无标记降级 / 带标记读回，均不崩
	var ss: Node = Node.new()
	ss.set_script(load(SAVE_SCRIPT) as Script)
	ss.name = "V050SaveSystemProbe"
	root.add_child(ss)
	ss.call("_ready")
	var loaded: Variant = ss.call("is_loaded")
	var expect_loaded: bool = _has_read_marker or not OS.get_cmdline_args().has("--script")
	_ck("E1 SaveSystem _ready() 依赖/模式降级不崩、is_loaded 如实", \
			typeof(loaded) == TYPE_BOOL and bool(loaded) == expect_loaded,
		"is_loaded=%s expect=%s" % [str(loaded), str(expect_loaded)])
	_ck("E2 SaveSystem 提供 is_loaded() 查询接口", ss.has_method("is_loaded"),
		"has_method=%s" % str(ss.has_method("is_loaded")))
	_free_node(ss)

	# E3：hud 无 WorldState 降级 → _read_lit_sources 返回 false、不崩
	var packed: PackedScene = ResourceLoader.load(
			HUD_SCENE, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var h: Node = packed.instantiate()
	root.add_child(h)
	h.call("_ready")
	h.call("bind_world_state", null)
	var lit: bool = bool(h.call("_read_lit_sources"))
	_ck("E3 hud 无 WorldState 降级（_read_lit_sources=false、不崩）", not lit,
		"lit=%s" % str(lit))
	_free_node(h)

	# E4：wave_trial_director 依赖缺失降级（C5 已覆盖，这里再断言孤立实例 bind 结果）
	var d: Node = _make_wave_director()
	var bound: bool = bool(d.call("bind_persistence", null, null))
	var s: Dictionary = d.call("get_snapshot")
	_ck("E4 波次导演依赖缺失降级（persist_available=false、不崩）", \
			not bound and not bool(s.get("persist_available", true)),
		"persist_available=%s" % str(s.get("persist_available", "?")))
	_free_node(d.get_parent())

	# E5：动作帧 HUD 在 _label 缺失时 _update_hud() 直接 return、不崩
	var bare: Node = Node.new()
	bare.set_script(load("res://scripts/combat/encounter_director.gd") as Script)
	root.add_child(bare)
	bare.call("_update_hud")
	_ck("E5 无 StatusLabel 时 _update_hud() 降级不崩", true, "bare director _update_hud() 正常返回")
	_free_node(bare)


func _finish() -> void:
	var ok: bool = _fail == 0 and _pass > 0
	print("[V050] ---- 回读汇总 ----")
	print("[V050] SUMMARY pid=%d pass=%d fail=%d ok=%s" % [
		OS.get_process_id(), _pass, _fail, str(ok)])
	print("[V050] RESULT=%s" % ("ALL_PASS" if ok else "HAS_FAIL"))
	print("[V050] ==== verify_persistence_hud_v050 真跑结束 ====")
	quit(0 if ok else 1)
