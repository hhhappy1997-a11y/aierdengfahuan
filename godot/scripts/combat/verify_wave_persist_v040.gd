extends SceneTree

## v0.4.0 R26B · 赐福试炼「自动开始 + 三 flag 持久化」验证（Rank-1，
## cmd-20261111-080359-707-A1，[ROUND=R26B]，v0.4.0）。
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path <godot> \
##       --script res://scripts/combat/verify_wave_persist_v040.gd
## 断言 6 类：
##   A 自动开始（auto_start 默认 true / _ready 后延迟帧进入第 1 波 / 只发一次信号）
##   B 演示序列不双驱动（外部先 start_trial 优先；不重复计数、不重复发信号）
##   C 三波推进 + 三个 flag 落盘且单调 + 「先落盘再改运行时实例」事件顺序
##   D 重启读回一致（真实 delta.json 落盘 → 新 WorldState 实例 _load() 逐项读回）
##   E 依赖缺失降级（bind_persistence(null,null) / 数据表缺失 → 不写 flag、不崩）
##   F 兼容开关与重开（is_trial_active / has_external_driver / interact_restart / completed 单向）
## --script 模式纪律：不用 /root/... 绝对路径；用 Engine.get_main_loop() / root.get_node_or_null()
##   相对探活；add_child 不 flush _ready 时显式 call("_ready")；注入在 _ready 之后。
## 三个 flag 经既有 WorldState.get_flag/set_flag 与 SaveDeltaWriter.commit 真实落盘到
##   user://saves/slot_01/delta.json（不伪造产物）；不改 schema_version=3、不用 removals、
##   不新增顶层字段。数值用注入桩时序（点数 100/150/200 与 Rank-2 表一致），非新设计数值。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

const DIRECTOR_SCRIPT: String = "res://scripts/combat/wave_trial_director.gd"
const WORLD_STATE_SCRIPT: String = "res://scripts/rpg/world_state.gd"
const DELTA_PATH: String = "user://saves/slot_01/delta.json"
const MISSING_TABLE_PATH: String = "res://data/rpg/__missing_wave_persist__.tres"

const K_BEST: String = "dungeon.wave_trial.best_wave"
const K_COMPLETED: String = "dungeon.wave_trial.completed"
const K_POINTS: String = "grace.trial.points"
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]

## [PLACEHOLDER-桩] 纯时序桩：只用于确定性验证三波推进与点数累计，不是 Rank-2 设计数值；
## 点数 100/150/200 与真实表 wave_trial.tres 的 reward_points 一致（不另造数值）。
const STUB_WAVES: Array = [
	{"telegraph": 1.0, "time_limit": 10.0, "points": 100},
	{"telegraph": 1.0, "time_limit": 10.0, "points": 150},
	{"telegraph": 1.0, "time_limit": 10.0, "points": 200},
]

var _pass: int = 0
var _fail: int = 0
var _started: Array = []
var _cleared: Array = []
var _completed: Array = []
var _re: RegEx = null

# C 阶段记录：三波清波后的两个单调递增序列，以及落盘期望值（基线动态读取，不假设 0）。
var _base_best: int = 0
var _base_points: int = 0
var _base_completed: bool = false
var _expect_best: int = 0
var _expect_points: int = 0


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[WPV040] %s PASS=%s | %s" % [tag, str(ok), detail])


func _on_wave_started(index: int, total: int) -> void:
	_started.append([index, total])


func _on_wave_cleared(index: int, points: int) -> void:
	_cleared.append([index, points])


func _on_trial_completed(best_wave: int) -> void:
	_completed.append(best_wave)


func _reset_signals() -> void:
	_started.clear()
	_cleared.clear()
	_completed.clear()


## --script 模式装配：add_child 不 flush _ready，显式 call 一次；不关 _process，
## 自动开始由本脚本手动 call("_process", 0.016) 两帧确定性驱动（同步 _initialize 内引擎不跑帧）。
func _make_director() -> Node:
	var d: Node = Node.new()
	d.set_script(load(DIRECTOR_SCRIPT) as Script)
	root.add_child(d)
	d.call("_ready")
	d.connect("wave_started", Callable(self, "_on_wave_started"))
	d.connect("wave_cleared", Callable(self, "_on_wave_cleared"))
	d.connect("trial_completed", Callable(self, "_on_trial_completed"))
	return d


func _free_node(n: Node) -> void:
	if n != null and is_instance_valid(n):
		n.free()


## 注入 3 波桩并推进到 TRIAL_COMPLETED（外部驱动模式，杜绝自动开始干扰）。
func _drive_three_waves(d: Node) -> void:
	d.call("configure_waves", STUB_WAVES)
	d.call("set_external_driver", true)
	d.call("start_trial")
	for i in range(3):
		d.call("debug_advance", 1.0)
		d.call("on_encounter_finished", true)
		if i < 2:
			d.call("debug_advance", 0.0)   # WAVE_CLEARED → NEXT_WAVE
			d.call("debug_advance", 0.0)   # NEXT_WAVE → 下一波 TELEGRAPH
	d.call("debug_advance", 0.0)           # 最后一波 → TRIAL_COMPLETED


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


func _initialize() -> void:
	print("[WPV040] ==== verify_wave_persist_v040 真跑开始 | cmd-20261111-080359-707-A1 [ROUND=R26B] ====")
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	# --script 模式不用 /root/... 绝对路径：Engine.get_main_loop() + root.get_node_or_null() 相对探活。
	var ml: MainLoop = Engine.get_main_loop()
	var tree_root: Node = root
	var ws_probe: Node = tree_root.get_node_or_null(NodePath("WorldState")) if tree_root != null else null
	var wr_probe: Node = tree_root.get_node_or_null(NodePath("SaveDeltaWriter")) if tree_root != null else null
	print("[WPV040] main_loop=%s root=%s WorldState_probe=%s SaveDeltaWriter_probe=%s（相对探活，仅登记）" % [
		str(ml != null), str(tree_root != null), str(ws_probe != null), str(wr_probe != null)])
	print("[WPV040] DELTA_PATH=%s abs=%s" % [DELTA_PATH, ProjectSettings.globalize_path(DELTA_PATH)])
	# 踩坑对齐：--script 模式下既有 SaveDeltaWriter._ready() 用 /root/WorldState 绝对路径探活，
	# 其内部委托 _ws 可能未就绪 → commit() 不落盘。测试装配一次性用「相对探活」结果补齐，
	# 并让 WorldState 先 _load() 回放既有存档，使三 flag 落盘不覆盖既有 flags（不改任何工程文件）。
	if wr_probe != null and ws_probe != null:
		var cur_ws: Variant = wr_probe.get("_ws")
		print("[WPV040] writer._ws_probe=%s（既有 /root/... 绝对路径探活结果，仅如实登记）" % str(cur_ws != null))
		ws_probe.call("_load")
		if cur_ws == null or cur_ws != ws_probe:
			wr_probe.set("_ws", ws_probe)
			print("[WPV040] writer._ws 修正为相对探活的 WorldState（测试装配，不改工程文件）")

	_test_auto_start()
	_test_no_double_drive()
	_test_persist_three_waves()
	_test_restart_readback()
	_test_degrade()
	_test_compat_and_restart()
	_finish()


# ---------------------------------------------------------------------------
# A) 自动开始：_ready 后延迟帧自动进入第 1 波，只发一次 wave_started
# ---------------------------------------------------------------------------
func _test_auto_start() -> void:
	_reset_signals()
	var d: Node = _make_director()
	var s0: Dictionary = d.call("get_snapshot")
	_ck("A1 auto_start 默认 true（@export）", bool(s0["auto_start"]),
		"auto_start=%s" % str(s0["auto_start"]))
	_ck("A2 _ready 后初始为 IDLE", int(s0["state"]) == 0 and not bool(s0["is_trial_active"]),
		"state=%s is_trial_active=%s" % [str(s0["state_name"]), str(s0["is_trial_active"])])
	# 手动推进两帧（引擎帧同步 _initialize 内不跑；验证真实 _process → _tick_auto_start 路径）
	d.call("_process", 0.016)
	d.call("_process", 0.016)
	var s1: Dictionary = d.call("get_snapshot")
	_ck("A3 自动开始进入第 1 波 TELEGRAPH", int(s1["state"]) == 1 and int(s1["index"]) == 0 \
			and bool(s1["is_trial_active"]),
		"state=%s index=%s/%s is_trial_active=%s" % [
			str(s1["state_name"]), str(s1["index"]), str(s1["total"]), str(s1["is_trial_active"])])
	_ck("A4 自动开始只发一次 wave_started", _started.size() == 1 \
			and int(s1["start_rejects"]) == 0,
		"wave_started=%s start_rejects=%s" % [str(_started), str(s1["start_rejects"])])
	_free_node(d)


# ---------------------------------------------------------------------------
# B) 演示序列不双驱动：外部先 start_trial 优先，自动开始让位
# ---------------------------------------------------------------------------
func _test_no_double_drive() -> void:
	_reset_signals()
	var d: Node = _make_director()
	# 模拟 presentation.gd 演示序列 frame 0 先经公开接口 start_trial()
	var first: bool = bool(d.call("start_trial"))
	d.call("_process", 0.016)
	d.call("_process", 0.016)
	var s: Dictionary = d.call("get_snapshot")
	_ck("B1 演示序列优先：外部 start_trial 成功、自动开始未重复 start", first \
			and int(s["start_rejects"]) == 0,
		"first=%s start_rejects=%s" % [str(first), str(s["start_rejects"])])
	_ck("B2 演示序列优先：wave_started 只发一次", _started.size() == 1,
		"wave_started=%s" % str(_started))
	_ck("B3 演示序列优先：started_waves 无重复计数", (s["started_waves"] as Array) == [0],
		"started_waves=%s" % str(s["started_waves"]))
	_ck("B4 演示序列优先：仍停在第 1 波 TELEGRAPH", int(s["state"]) == 1 and int(s["index"]) == 0,
		"state=%s index=%s" % [str(s["state_name"]), str(s["index"])])
	_free_node(d)


# ---------------------------------------------------------------------------
# C) 三波推进 + 三 flag 落盘且单调 + 「先落盘再改运行时实例」事件顺序
# ---------------------------------------------------------------------------
func _test_persist_three_waves() -> void:
	_reset_signals()
	var d: Node = _make_director()
	var s0: Dictionary = d.call("get_snapshot")
	_base_best = int(s0["best_wave"])
	_base_points = int(s0["grace_trial_points"])
	_base_completed = bool(s0["wave_trial_completed"])
	_expect_best = maxi(_base_best, 3)
	_expect_points = _base_points + 450
	_ck("C0 持久化依赖可用（WorldState + SaveDeltaWriter 相对探活）", bool(s0["persist_available"]),
		"persist_available=%s reason=%s" % [str(s0["persist_available"]), str(s0["persist_downgrade_reason"])])
	print("[WPV040] C 基线（动态读取，不假设 0）：best=%d points=%d completed=%s → 期望 best=%d points=%d" % [
		_base_best, _base_points, str(_base_completed), _expect_best, _expect_points])

	d.call("configure_waves", STUB_WAVES)
	d.call("set_external_driver", true)
	d.call("start_trial")
	var pts_series: Array[int] = []
	var best_series: Array[int] = []
	for i in range(3):
		d.call("debug_advance", 1.0)
		d.call("on_encounter_finished", true)
		var si: Dictionary = d.call("get_snapshot")
		pts_series.append(int(si["grace_trial_points"]))
		best_series.append(int(si["best_wave"]))
		if i < 2:
			d.call("debug_advance", 0.0)
			d.call("debug_advance", 0.0)
	d.call("debug_advance", 0.0)   # → TRIAL_COMPLETED（completed 单向置 true 落盘）
	var s: Dictionary = d.call("get_snapshot")

	_ck("C1 三波推进到 TRIAL_COMPLETED", int(s["state"]) == 5 and int(s["index"]) == 2,
		"state=%s index=%s/%s" % [str(s["state_name"]), str(s["index"]), str(s["total"])])
	_ck("C2 本局点数累计 100+150+200=450（既有 points_total 不回退）", int(s["points_total"]) == 450,
		"points_total=%s" % str(s["points_total"]))
	_ck("C3 三次清波 grace.trial.points 严格单调递增", pts_series == [
			_base_points + 100, _base_points + 250, _base_points + 450],
		"series=%s" % str(pts_series))
	var best_mono: bool = true
	for i in range(1, best_series.size()):
		if best_series[i] < best_series[i - 1]:
			best_mono = false
	for v in best_series:
		if v < _base_best:
			best_mono = false
	_ck("C4 三次清波 best_wave 只增不减（相对基线不回退）", best_mono,
		"series=%s base=%d" % [str(best_series), _base_best])
	_ck("C5 best_wave 运行时镜像 == max(基线,3)", int(s["best_wave"]) == _expect_best,
		"best_wave=%s expect=%d" % [str(s["best_wave"]), _expect_best])
	_ck("C6 grace.trial.points 运行时镜像 == 基线+450", int(s["grace_trial_points"]) == _expect_points,
		"grace_trial_points=%s expect=%d" % [str(s["grace_trial_points"]), _expect_points])
	_ck("C7 completed 运行时镜像 true（false→true 单向）", bool(s["wave_trial_completed"]),
		"wave_trial_completed=%s base=%s" % [str(s["wave_trial_completed"]), str(_base_completed)])
	var cleared_ok: bool = _cleared.size() == 3 and _cleared[0] == [0, 100] \
			and _cleared[1] == [1, 150] and _cleared[2] == [2, 200]
	_ck("C8 三次 wave_cleared 信号点数 100/150/200", cleared_ok, "wave_cleared=%s" % str(_cleared))
	_ck("C9 trial_completed 信号携 best_wave", _completed.size() == 1 \
			and int(_completed[0]) == _expect_best,
		"trial_completed=%s expect_best=%d" % [str(_completed), _expect_best])
	# 事件顺序：4 次结算（3×cleared + 1×completed）× 3 事件，逐组 stage_flags→disk_write→runtime_update
	var ev: Array = s["persist_events"] as Array
	var order_ok: bool = ev.size() == 12
	if ev.size() == 12:
		for i in range(0, 12, 3):
			if not (String(ev[i]).begins_with("stage_flags") \
					and String(ev[i + 1]).begins_with("disk_write") \
					and String(ev[i + 2]).begins_with("runtime_update")):
				order_ok = false
	_ck("C10 先落盘再改运行时实例（4 组 stage_flags→disk_write→runtime_update）", order_ok,
		"events=%s" % str(ev))
	_ck("C11 commit(reason) 调用 4 次（3 cleared + 1 completed）", int(s["commit_count"]) == 4,
		"commit_count=%s" % str(s["commit_count"]))
	_free_node(d)


# ---------------------------------------------------------------------------
# D) 落盘证据 + 重启读回一致（新 WorldState 实例 _load() 从磁盘重建）
# ---------------------------------------------------------------------------
func _test_restart_readback() -> void:
	var d: Dictionary = _read_delta()
	_ck("D1 delta.json 存在且可解析（真实落盘，不伪造）", not d.is_empty(),
		"path=%s abs=%s" % [DELTA_PATH, ProjectSettings.globalize_path(DELTA_PATH)])
	if d.is_empty():
		return
	var flags: Dictionary = d.get("flags", {}) as Dictionary
	var disk_best: int = int(flags.get(K_BEST, -1))
	var disk_points: int = int(flags.get(K_POINTS, -1))
	var disk_completed: bool = bool(flags.get(K_COMPLETED, false))
	_ck("D2 三个 flag 落盘且值 == 期望", disk_best == _expect_best and disk_points == _expect_points \
			and disk_completed == true,
		"%s=%d %s=%d %s=%s（expect %d/%d/true）" % [
			K_BEST, disk_best, K_POINTS, disk_points, K_COMPLETED, str(disk_completed),
			_expect_best, _expect_points])
	_ck("D3 best_wave 落盘单调（>= 基线、不回退）", disk_best >= _base_best and disk_best == _expect_best,
		"disk=%d base=%d" % [disk_best, _base_best])
	_ck("D4 points 落盘单调（== 基线+450）", disk_points == _base_points + 450,
		"disk=%d base=%d" % [disk_points, _base_points])
	_ck("D5 completed 落盘单向（false→true，无 false 回写）", disk_completed == true,
		"disk=%s base=%s" % [str(disk_completed), str(_base_completed)])
	var top: Array = d.keys()
	var extra: Array[String] = []
	var missing: Array[String] = []
	for k in top:
		if not TEN_FIELDS.has(String(k)):
			extra.append(String(k))
	for k in TEN_FIELDS:
		if not d.has(k):
			missing.append(k)
	_ck("D6 十字段齐全、无额外顶层字段（新 flag 只在 flags 字典内）", \
			extra.is_empty() and missing.is_empty() and top.size() == TEN_FIELDS.size(),
		"top=%s extra=%s missing=%s" % [str(top), str(extra), str(missing)])
	_ck("D7 schema_version 保持 3、不触发迁移", int(d.get("schema_version", -1)) == 3,
		"schema_version=%s" % str(d.get("schema_version", -1)))
	_ck("D8 removals 为空（口径不启用 removals）", (d.get("removals", []) as Array).is_empty(),
		"removals=%s" % str(d.get("removals", [])))
	var bad: Array[String] = []
	for k in flags.keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_ck("D9 落盘 flags 全通过三段式正则", bad.is_empty(),
		"keys=%s bad=%s" % [str(flags.keys()), str(bad)])
	# 真·重启：新建独立 WorldState 实例，空内存，只能经 _load() 从磁盘 delta.json 回放重建
	var reborn: Node = Node.new()
	reborn.set_script(load(WORLD_STATE_SCRIPT) as Script)
	reborn.name = "RebornWorldStateV040"
	root.add_child(reborn)
	reborn.call("_ready")
	reborn.call("_load")
	var rb_best: int = int(reborn.call("get_flag", K_BEST, -1))
	var rb_points: int = int(reborn.call("get_flag", K_POINTS, -1))
	var rb_completed: bool = bool(reborn.call("get_flag", K_COMPLETED, false))
	_ck("D10 重启读回一致（新实例 _load() 三 flag 逐项 == 落盘期望）", \
			rb_best == _expect_best and rb_points == _expect_points and rb_completed == true,
		"readback best=%d points=%d completed=%s" % [rb_best, rb_points, str(rb_completed)])
	_ck("D11 重启不回退（best_wave / completed 均不回退）", rb_best >= 3 and rb_completed,
		"readback best=%d completed=%s" % [rb_best, str(rb_completed)])
	_free_node(reborn)


# ---------------------------------------------------------------------------
# E) 依赖缺失降级：持久化不可用 / 数据表缺失 → 不写 flag、不落盘、不崩
# ---------------------------------------------------------------------------
func _test_degrade() -> void:
	_reset_signals()
	var d: Node = _make_director()
	d.call("bind_persistence", null, null)
	var s0: Dictionary = d.call("get_snapshot")
	_ck("E1 bind_persistence(null,null) → persist_available=false", not bool(s0["persist_available"]),
		"persist_available=%s reason=%s" % [str(s0["persist_available"]), str(s0["persist_downgrade_reason"])])
	_drive_three_waves(d)
	var s: Dictionary = d.call("get_snapshot")
	_ck("E2 降级下三波仍推进完成、不崩", int(s["state"]) == 5 and int(s["points_total"]) == 450,
		"state=%s points_total=%s" % [str(s["state_name"]), str(s["points_total"])])
	_ck("E3 降级下不写 flag、不落盘（events 空 / commit_count=0）", \
			(s["persist_events"] as Array).is_empty() and int(s["commit_count"]) == 0,
		"events=%s commit_count=%s" % [str(s["persist_events"]), str(s["commit_count"])])
	_ck("E4 降级下运行时镜像保持 _ready 读回基线（不写 flag、不改镜像）", \
			int(s["grace_trial_points"]) == int(s0["grace_trial_points"]) \
			and bool(s["wave_trial_completed"]) == bool(s0["wave_trial_completed"]),
		"baseline points=%s completed=%s / after points=%s completed=%s" % [
			str(s0["grace_trial_points"]), str(s0["wave_trial_completed"]),
			str(s["grace_trial_points"]), str(s["wave_trial_completed"])])
	_ck("E5 降级原因如实登记", String(s["persist_downgrade_reason"]).contains("bind_persistence"),
		"reason=%s" % str(s["persist_downgrade_reason"]))
	d.call("set", "table_path", MISSING_TABLE_PATH)
	d.call("reload_table")
	var sd: Dictionary = d.call("get_snapshot")
	_ck("E6 数据表依赖缺失降级单波（不硬编码三波、不崩）", \
			bool(sd["degraded"]) and int(sd["total"]) == 1,
		"degraded=%s total=%s reason=%s" % [
			str(sd["degraded"]), str(sd["total"]), str(sd["degrade_reason"])])
	_free_node(d)


# ---------------------------------------------------------------------------
# F) 兼容开关与重开：is_trial_active / has_external_driver / interact_restart / completed 单向
# ---------------------------------------------------------------------------
func _test_compat_and_restart() -> void:
	_reset_signals()
	var d: Node = _make_director()
	d.call("set_external_driver", true)
	d.call("configure_waves", STUB_WAVES)
	d.call("start_trial")
	var s1: Dictionary = d.call("get_snapshot")
	_ck("F1 is_trial_active() 在 TELEGRAPH 为 true", bool(s1["is_trial_active"]),
		"is_trial_active=%s" % str(s1["is_trial_active"]))
	_ck("F2 active 期 restart_trial() 拒绝（不打断、不重复计数）", not bool(d.call("restart_trial")),
		"restart_in_active=%s" % str(d.call("get_snapshot")["start_rejects"]))
	_ck("F3 has_external_driver 兼容开关可读回", bool(s1["has_external_driver"]),
		"has_external_driver=%s" % str(s1["has_external_driver"]))
	d.call("debug_advance", 1.0)
	d.call("on_encounter_finished", true)
	d.call("debug_advance", 0.0)
	d.call("debug_advance", 0.0)
	d.call("debug_advance", 1.0)
	d.call("on_encounter_finished", true)
	d.call("debug_advance", 0.0)
	d.call("debug_advance", 0.0)
	d.call("debug_advance", 1.0)
	d.call("on_encounter_finished", true)
	d.call("debug_advance", 0.0)
	var s2: Dictionary = d.call("get_snapshot")
	_ck("F4 三波完成 TRIAL_COMPLETED", int(s2["state"]) == 5, "state=%s" % str(s2["state_name"]))
	_ck("F5 completed 镜像单向不回退", bool(s2["wave_trial_completed"]),
		"completed=%s" % str(s2["wave_trial_completed"]))
	var restarted: bool = bool(d.call("restart_trial"))
	var s3: Dictionary = d.call("get_snapshot")
	_ck("F6 赐福休息 / E 键 interact 重开一轮（回到第 1 波 TELEGRAPH）", \
			restarted and int(s3["state"]) == 1 and int(s3["index"]) == 0,
		"restarted=%s state=%s index=%s" % [
			str(restarted), str(s3["state_name"]), str(s3["index"])])
	_ck("F7 重开后 completed 镜像仍 true（单向、不翻转）", bool(s3["wave_trial_completed"]),
		"completed=%s" % str(s3["wave_trial_completed"]))
	_free_node(d)


func _finish() -> void:
	var ok: bool = _fail == 0 and _pass > 0
	print("[WPV040] ---- 回读汇总 ----")
	print("[WPV040] SUMMARY pid=%d pass=%d fail=%d ok=%s" % [
		OS.get_process_id(), _pass, _fail, str(ok)])
	print("[WPV040] RESULT=%s" % ("ALL_PASS" if ok else "HAS_FAIL"))
	print("[WPV040] ==== verify_wave_persist_v040 真跑结束 ====")
	quit(0 if ok else 1)
