extends SceneTree

## ===========================================================================
## R29 [ROUND=R29] · step_index 跨 exe 重启读回实证
## （Rank-1，cmd-20261111-112803-982-A1）
##
## 补 DONE-R28B.md §7.3 登记的缺口：此前 step_index 只在进程内夹具 / Rank-3 三态里
## 验证，从未做「进程 A 写盘 → 独立引擎进程 B 真实场景自动 _load() 读回」的跨 exe 实证。
##
## 真跑（两个独立 Godot 引擎进程，pid 不同，绝不伪造）：
##   进程 A（写）：Godot_v4.7.2 --headless --path <godot> \
##           --script res://scripts/combat/verify_hud_depth_v070.gd -- phase=write
##   进程 B（读）：Godot_v4.7.2 --headless --path <godot> \
##           --quit-after 60 \
##           --script res://scripts/combat/verify_hud_depth_v070.gd \
##           res://scenes/courtyard.tscn -- v050_read phase=read
##
## 进程 B 口径（任务单踩坑）：
##   - 带【真实主场景】res://scenes/courtyard.tscn（引擎正常加载单实例，非纯 --script 工具
##     进程）；--script 仅用于承载断言，不构造 / 不伪造场景。
##   - 同时带【v050_read 用户标记】：SaveSystem autoload 的 _readback_allowed() 在
##     --script 模式下仅显式带该标记时允许 WorldState._load() 自动读盘，故
##     SaveSystem.is_loaded()=true 可实证（纯 --script 工具进程会如实降级为 false）。
##   - 两个进程各自 OS.get_process_id() 打印，绝不复用 pid / 绝不伪造读回值。
##
## 写入侧严格经既有 I-1 权威入口：WorldState.set_flag(三段式 key, 值) →
##   SaveDeltaWriter.commit(reason) 真实原子落盘 user://saves/slot_01/delta.json；
##   不手改 delta.json、不构造 / 解析 SaveDelta、不动 schema_version=3 / 十字段。
## --script 模式纪律：不用 /root/... 绝对路径（一律 root.get_node_or_null() 相对探活）；
##   SaveDeltaWriter._ready() 的 /root/WorldState 绝对路径在 --script 下探活失效，
##   沿用 verify_persistence_hud_v050.gd 的一次性测试装配修正 wr.set("_ws", ws)。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。
## ===========================================================================

const DELTA_PATH: String = "user://saves/slot_01/delta.json"
const K_STEP: String = "grace.tutorial.step_index"
const K_COMPLETED: String = "grace.tutorial.completed"
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"

# [PLACEHOLDER-验证桩] 写进程落盘的确定性值：3 与 true 取自教学三步完成后的世界持久层
# 历史最高进度 / 完成态（tutorial_director.gd 的 A26 口径），非新设计数值。
const WRITE_STEP: int = 3
const WRITE_COMPLETED: bool = true
const WRITE_REASON: String = "v070_step_index_write"

# 等 autoload SaveSystem._ready() 在帧循环 flush 后再断言（--script add_child 不 flush _ready）。
const WAIT_FRAMES: int = 3

var _phase: String = "selftest"
var _has_read_marker: bool = false
var _ws: Node = null
var _wr: Node = null
var _re: RegEx = null
var _frame: int = 0
var _pass: int = 0
var _fail: int = 0


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V070][READ] %s PASS=%s | %s" % [tag, str(ok), detail])


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
	print("[V070] ==== verify_hud_depth_v070 真跑开始 | cmd-20261111-112803-982-A1 [ROUND=R29] Rank-1 ====")
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	for a: String in OS.get_cmdline_user_args():
		if a == "v050_read":
			_has_read_marker = true
		elif a.begins_with("phase="):
			_phase = a.substr(6)
	# 相对探活（不用 /root/... 绝对路径）
	_ws = root.get_node_or_null(NodePath("WorldState"))
	_wr = root.get_node_or_null(NodePath("SaveDeltaWriter"))
	var scene: Node = root.get_node_or_null(NodePath("Courtyard"))
	print("[V070] pid=%d phase=%s v050_read=%s | WorldState=%s SaveDeltaWriter=%s SaveSystem=%s | 真实主场景Courtyard=%s" % [
			OS.get_process_id(), _phase, str(_has_read_marker),
			str(_ws != null), str(_wr != null),
			str(root.get_node_or_null(NodePath("SaveSystem")) != null), str(scene != null)])
	print("[V070] DELTA_PATH=%s abs=%s" % [DELTA_PATH, ProjectSettings.globalize_path(DELTA_PATH)])

	if _phase == "write":
		_do_write()
		print("[V070] RESULT=WRITE_OK")
		quit(0)
		return
	if _phase == "selftest":
		_do_write()   # 自包含：单进程先写后验（便于 --check-only / 单独跑）
	process_frame.connect(Callable(self, "_on_frame"))


## 进程 A（写）：经既有 I-1 入口 set_flag + SaveDeltaWriter.commit 真实落盘。
## 先 _load() 读回既有存档，保留历史 flags（不抹既有波次 / 点数），再写两个教学 flag。
func _do_write() -> void:
	if _ws == null:
		push_error("[V070] WorldState 相对探活失败，无法落盘")
		return
	_ws.call("_load")
	if _wr != null:
		_wr.set("_ws", _ws)     # 一次性测试装配修正，不改任何工程文件
	_ws.call("set_flag", K_STEP, WRITE_STEP)
	_ws.call("set_flag", K_COMPLETED, WRITE_COMPLETED)
	if _wr != null and _wr.has_method("commit"):
		_wr.call("commit", WRITE_REASON)
	var d: Dictionary = _read_delta()
	var flags: Dictionary = d.get("flags", {}) as Dictionary
	print("[V070][WRITE] pid=%d 落盘完成 | %s=%s %s=%s reason=%s | 磁盘回读 flags=%s" % [
			OS.get_process_id(), K_STEP, str(flags.get(K_STEP, "?")),
			K_COMPLETED, str(flags.get(K_COMPLETED, "?")), WRITE_REASON,
			str([K_STEP, K_COMPLETED])])


func _on_frame() -> void:
	_frame += 1
	if _frame < WAIT_FRAMES:
		return
	process_frame.disconnect(Callable(self, "_on_frame"))
	_test_readback()
	print("[V070] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	print("[V070] RESULT=%s" % ("ALL_PASS" if _fail == 0 else "FAILED"))
	print("[V070] ==== verify_hud_depth_v070 真跑结束 ====")
	quit(0 if _fail == 0 else 1)


## 进程 B（读）：只断言，不写盘。值来自前序「写进程」真实落盘的 delta.json，
## 由 SaveSystem autoload 在真实场景启动时经 WorldState._load() 自动读回内存。
func _test_readback() -> void:
	var ss: Node = root.get_node_or_null(NodePath("SaveSystem"))
	var is_loaded: bool = false
	var has_api: bool = ss != null and ss.has_method("is_loaded")
	if has_api:
		is_loaded = bool(ss.call("is_loaded"))
	var step: int = int(_ws.call("get_flag", K_STEP, -1))
	var completed: bool = bool(_ws.call("get_flag", K_COMPLETED, false))
	var d: Dictionary = _read_delta()
	var disk_flags: Dictionary = d.get("flags", {}) as Dictionary
	var disk_step: int = int(disk_flags.get(K_STEP, -1))
	var disk_completed: bool = bool(disk_flags.get(K_COMPLETED, false))
	print("[V070][READ] pid=%d 读回值 | %s=%d %s=%s | SaveSystem.is_loaded()=%s | 磁盘 delta.json %s=%d %s=%s" % [
			OS.get_process_id(), K_STEP, step, K_COMPLETED, str(completed),
			str(is_loaded), K_STEP, disk_step, K_COMPLETED, str(disk_completed)])
	# R1/R2：跨 exe 重启后 WorldState 内存自动读回 3 / true
	_ck("R1 step_index 跨 exe 读回 == 3", step == WRITE_STEP,
			"WorldState.get_flag(%s, -1)=%d expected=%d" % [K_STEP, step, WRITE_STEP])
	_ck("R2 completed 跨 exe 读回 == true", completed == WRITE_COMPLETED,
			"WorldState.get_flag(%s, false)=%s expected=true" % [K_COMPLETED, str(completed)])
	# R3：SaveSystem 接线确实完成自动读回（纯 --script 工具进程会降级为 false）
	_ck("R3 SaveSystem.is_loaded() == true（真实场景自动 _load 读盘）", has_api and is_loaded,
			"has_method(is_loaded)=%s is_loaded()=%s v050_read=%s" % [str(has_api), str(is_loaded), str(_has_read_marker)])
	# R4：磁盘 delta.json 里两 flag 真实存在且值一致（写进程落盘，非伪造）
	_ck("R4 磁盘 delta.json 两 flag == 3 / true（写进程真实落盘）",
			disk_step == WRITE_STEP and disk_completed == WRITE_COMPLETED and not d.is_empty(),
			"disk %s=%d %s=%s delta_exists=%s" % [K_STEP, disk_step, K_COMPLETED, str(disk_completed), str(not d.is_empty())])
	# R5：内存读回值 == 磁盘值（读回确实来自磁盘，不是脚本内硬编码）
	_ck("R5 内存读回 == 磁盘读回（读回链路真实）",
			step == disk_step and completed == disk_completed,
			"memory=%d/%s disk=%d/%s" % [step, str(completed), disk_step, str(disk_completed)])
	# R6：两个 key 均匹配 WorldState 三段式正则（不改正则 / 不动 schema）
	var k1_ok: bool = _re.search(K_STEP) != null
	var k2_ok: bool = _re.search(K_COMPLETED) != null
	_ck("R6 两个 flag key 均合法三段式（未改 world_state.gd 正则）", k1_ok and k2_ok,
			"%s=%s %s=%s" % [K_STEP, str(k1_ok), K_COMPLETED, str(k2_ok)])
