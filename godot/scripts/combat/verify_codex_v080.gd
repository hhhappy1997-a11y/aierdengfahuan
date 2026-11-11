extends SceneTree
## ===========================================================================
## R30 [ROUND=R30] · 赐福图鉴 v0.8.0 自测（Rank-1，cmd-20261111-125001-344-A1）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_codex_v080.gd
##
## 断言 9 组：
##   A 依赖缺失降级（Rank-2 .tres 未落盘 → 内置 4 项 + 如实 push_warning、不崩）
##   B 4 项条件逐项达成 + best_wave 边界(2 否 / 3 是) + all_upgrades(2/3 否 / 3/3 是)
##   C 严格「先落盘再改运行时实例」(stage_flags → disk_write:codex_unlocked → runtime_update)
##   D 单向解锁（来源 flag 复位后 codex flag 不回写 false）
##   E 重复达成不双写（重复 flag_changed / evaluate 不增 commit / 不重发信号）
##   F Tab 开关（KEY_TAB 开 / 再按关 / 默认隐藏 / 不与教学 T 键 84 冲突 / 不干扰 E、1）
##   G 面板不遮角色（与 6 套 HUD + 玩家/Boss + 兑换面板 8 矩形交集为 0、alpha≤0.35、
##      独立 CanvasLayer 不写场景、已达成 GOLD 高亮 / 未达成 DIM、进度 n/4）
##   H courtyard.tscn 静态节点数 == 41（裁决 A35，不写场景节点）
##   I 成就 flag 三段式合法（grace.codex_<id>.unlocked 匹配 WorldState 正则）
##
## 口径：
##   - 全程用「内存 WorldState(真实 world_state.gd 脚本) + FakeWriter」验证真实 I-1
##     set_flag / flag_changed 订阅 / commit 编排，不写 user://saves（不污染回归基线、
##     不伪造落盘）；真实场景集成与真实 Input.parse_input_event 路由由三段门禁 +
##     presentation.gd 15 秒录屏单独证明（见 DONE-R30.md）。
##   - --script 模式纪律：不用 /root/... 绝对路径（root.add_child 相对装配）；
##     每个夹具挂独立 host 节点，free 时连同自建 CanvasLayer 一起释放，无残留 / 无重名冲突；
##     Tab 输入用构造真实 InputEventKey 传给 _unhandled_input（工程既有
##     verify_grace_runtime_v050.gd::_test_input_routing 同口径）。
##   - 「同跑回归」：v060 64/86/21/48/37、v070 6/46 及既有全回归由门禁阶段串行真跑，
##     日志落 teamwork/Rank-1/，结论写入 DONE-R30.md（不在本脚本内伪造数字）。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。
## ===========================================================================

const DIRECTOR_PATH: String = "res://scripts/combat/codex_director.gd"
const WORLD_STATE_PATH: String = "res://scripts/rpg/world_state.gd"
const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"
const CODEX_ENTRIES_PATH: String = "res://data/rpg/codex_entries.tres"
const MISSING_PATH: String = "res://__r30_missing__/codex_entries.tres"

# 既有三段式来源 flag
const F_TUTORIAL: String = "grace.tutorial.completed"
const F_TRIAL: String = "dungeon.wave_trial.completed"
const F_BEST: String = "dungeon.wave_trial.best_wave"
const UPGRADE_IDS: Array[String] = ["hp_max_bonus", "roll_iframe_bonus", "attack_power_bonus"]
const FLAG_UPGRADE_PREFIX: String = "grace.upgrade_"
const FLAG_UPGRADE_SUFFIX: String = ".unlocked"

# 成就 flag（裁决 A36 三段式）
const K_TUTORIAL: String = "grace.codex_tutorial_complete.unlocked"
const K_TRIAL: String = "grace.codex_trial_cleared.unlocked"
const K_UPGRADES: String = "grace.codex_all_upgrades.unlocked"
const K_BEST: String = "grace.codex_best_wave_ge3.unlocked"
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const COMMIT_REASON: String = "codex_unlocked"

# 面板几何与避让矩形（courtyard.tscn 实读 / R29B 真跑像素框）
const CODEX_RECT: Rect2 = Rect2(24.0, 272.0, 356.0, 236.0)
const RECT_GRACE_HUD: Rect2 = Rect2(0.0, 0.0, 730.0, 220.0)
const RECT_QUALITY: Rect2 = Rect2(760.0, 0.0, 520.0, 180.0)
const RECT_WAVE: Rect2 = Rect2(24.0, 232.0, 696.0, 32.0)
const RECT_TUTORIAL: Rect2 = Rect2(24.0, 520.0, 1076.0, 36.0)
const RECT_SHOP: Rect2 = Rect2(740.0, 358.0, 536.0, 210.0)
const RECT_BOTTOM: Rect2 = Rect2(24.0, 660.0, 1200.0, 32.0)
const RECT_PLAYER: Rect2 = Rect2(400.0, 320.0, 290.0, 250.0)
const RECT_BOSS: Rect2 = Rect2(645.0, 230.0, 235.0, 120.0)
const SCREEN: Rect2 = Rect2(0.0, 0.0, 1280.0, 720.0)
const NODE_COUNT_EXPECTED: int = 41
const KEY_TAB: int = 4194306
const KEY_T: int = 84
const KEY_E: int = 69
const KEY_1: int = 49
const MAX_ALPHA: float = 0.35
const GOLD: Color = Color(0.83, 0.68, 0.3, 1.0)
const DIM: Color = Color(0.55, 0.54, 0.50, 1.0)


## 只记录 commit(reason) 的替身：验证「先落盘」编排而不写 user:// 盘。
class FakeWriter extends Node:
	var commits: Array[String] = []

	func commit(reason: String) -> void:
		commits.append(reason)


## 收集 director 两个信号的只读监听者。
class Spy extends Node:
	var unlocked: Array = []
	var progress: Array = []

	func on_unlocked(id: String, title: String) -> void:
		unlocked.append({"id": id, "title": title})

	func on_progress(u: int, t: int) -> void:
		progress.append({"unlocked": u, "total": t})


var _pass: int = 0
var _fail: int = 0
var _temps: Array[Node] = []
var _dir_script: Script = null
var _re: RegEx = null


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V080] %s PASS=%s | %s" % [tag, str(ok), detail])


func _track(n: Node) -> void:
	_temps.append(n)


func _new_mem_ws() -> Node:
	var ws: Node = Node.new()
	ws.set_script(load(WORLD_STATE_PATH) as Script)
	_track(ws)
	ws.call("_ready")
	return ws


## 每个夹具挂独立 host：director 的 CanvasLayer 会挂在 host 下，free(host) 一并释放，
## 避免多个实例的 CodexPanelLayer 在 root 下重名 / 残留。
func _new_director(ws: Node, writer: Node, path: String, spy: Node = null) -> Node:
	var host: Node = Node.new()
	host.name = "CodexTestHost"
	_track(host)
	root.add_child(host)
	var d: Node = _dir_script.new() as Node
	_track(d)
	d.set("injected_state", ws)
	d.set("injected_writer", writer)
	d.set("codex_entries_path", path)
	if spy != null:
		d.connect("codex_entry_unlocked", Callable(spy, "on_unlocked"))
		d.connect("codex_progress_changed", Callable(spy, "on_progress"))
	host.add_child(d)
	if not d.is_node_ready():
		d.call("_ready")
	d.call("build_panel_now")
	return d


func _status(d: Node) -> Dictionary:
	return d.call("get_status") as Dictionary


func _flag(ws: Node, key: String, default_value: Variant) -> Variant:
	return ws.call("get_flag", key, default_value)


func _set_flag(ws: Node, key: String, value: Variant) -> void:
	ws.call("set_flag", key, value)


func _overlap_area(a: Rect2, b: Rect2) -> float:
	return a.intersection(b).get_area()


func _tab_event(pressed: bool) -> InputEventKey:
	var k: InputEventKey = InputEventKey.new()
	k.physical_keycode = KEY_TAB
	k.keycode = KEY_TAB
	k.pressed = pressed
	k.echo = false
	return k


func _key_event(code: int, pressed: bool) -> InputEventKey:
	var k: InputEventKey = InputEventKey.new()
	k.physical_keycode = code
	k.keycode = code
	k.pressed = pressed
	k.echo = false
	return k


func _initialize() -> void:
	print("[V080] ==== verify_codex_v080 真跑开始 | cmd-20261111-125001-344-A1 [ROUND=R30] Rank-1 ====")
	_dir_script = load(DIRECTOR_PATH) as Script
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	if _dir_script == null:
		print("[V080] RESULT=FAIL（codex_director.gd 加载失败）")
		quit(1)
		return
	print("[V080] pid=%d | codex_entries.tres exists=%s（Rank-2 并发时序，当前应尚未落盘）" % [
			OS.get_process_id(), str(ResourceLoader.exists(CODEX_ENTRIES_PATH))])
	_test_degrade()
	_test_conditions()
	_test_order()
	_test_oneway_and_repeat()
	_test_tab()
	_test_geometry()
	_test_node_count()
	_test_flag_keys()
	_finish()


# ---------------------------------------------------------------------------
# A) 依赖缺失降级：Rank-2 .tres 未落盘 → 内置 4 项 + 如实登记、不崩
# ---------------------------------------------------------------------------
func _test_degrade() -> void:
	var ws: Node = _new_mem_ws()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var d: Node = _new_director(ws, fw, MISSING_PATH)
	var st: Dictionary = _status(d)
	var entries: Array = d.call("get_entries") as Array
	_ck("A1 .tres 缺失 → source=builtin_default",
			String(st.get("source", "")) == "builtin_default",
			"source=%s" % str(st.get("source", "")))
	_ck("A2 .tres 缺失 → degraded=true 且如实登记原因（含「未落盘」）",
			bool(st.get("degraded", false)) and (st.get("reasons", []) as Array).size() >= 1 \
					and String((st.get("reasons", []) as Array)[0]).contains("未落盘"),
			"degraded=%s reasons=%s" % [str(st.get("degraded", false)), str(st.get("reasons", []))])
	_ck("A3 降级后仍有内置 4 项（id/title/description/condition 齐全）",
			entries.size() == 4 and _entries_complete(entries),
			"entries=%d" % entries.size())
	_ck("A4 降级不崩：status / get_progress / get_panel_rect 均可读回",
			int((d.call("get_progress") as Dictionary).get("total", -1)) == 4 \
					and (d.call("get_panel_rect") as Rect2).get_area() > 0.0,
			"progress=%s rect=%s" % [str(d.call("get_progress")), str(d.call("get_panel_rect"))])
	# 真实 Rank-2 路径：并发时序下「已落盘 / 未落盘」两种时序都如实断言，不假设某一态。
	var ws2: Node = _new_mem_ws()
	var fw2: FakeWriter = FakeWriter.new()
	_track(fw2)
	var d2: Node = _new_director(ws2, fw2, CODEX_ENTRIES_PATH)
	var st2: Dictionary = _status(d2)
	var exists2: bool = ResourceLoader.exists(CODEX_ENTRIES_PATH)
	var source2: String = String(st2.get("source", ""))
	var degraded2: bool = bool(st2.get("degraded", false))
	_ck("A5 真实 Rank-2 路径并发时序如实：落盘→source=tres/不降级；未落盘→builtin_default/降级",
			(exists2 and source2 == "tres" and not degraded2) \
					or (not exists2 and source2 == "builtin_default" and degraded2),
			"exists=%s source=%s degraded=%s" % [str(exists2), source2, str(degraded2)])
	# A6：读到 Rank-2 .tres 后状态机仍工作（按 tres 第 1 项 id 动态断言，不硬编码 id）。
	var entries2: Array = d2.call("get_entries") as Array
	var first_id: String = "" if entries2.is_empty() else String((entries2[0] as Dictionary).get("id", ""))
	_set_flag(ws2, F_TUTORIAL, true)
	_ck("A6 读到 Rank-2 .tres 后 4 项齐全且教学完成仍可解锁（数据驱动 id 段）",
			entries2.size() == 4 and not first_id.is_empty() \
					and bool(d2.call("is_unlocked", first_id)) \
					and bool(_flag(ws2, "grace.codex_" + first_id + ".unlocked", false)),
			"entries=%d first_id=%s progress=%s" % [
					entries2.size(), first_id, str(d2.call("get_progress"))])


func _entries_complete(entries: Array) -> bool:
	if entries.size() != 4:
		return false
	for v: Variant in entries:
		var e: Dictionary = v as Dictionary
		for f: Variant in ["id", "title", "description", "condition"]:
			if String(e.get(String(f), "")).is_empty():
				return false
	return true


# ---------------------------------------------------------------------------
# B) 4 项条件逐项达成（订阅 flag_changed 事件驱动自动解锁）+ 边界
# ---------------------------------------------------------------------------
func _test_conditions() -> void:
	# B1 教学完成
	var r1: Array = _one_condition_case(F_TUTORIAL, true, K_TUTORIAL, "tutorial_complete")
	_ck("B1 教学完成 → 仅解锁 grace.codex_tutorial_complete.unlocked", r1[0], str(r1[1]))
	# B2 三波全清
	var r2: Array = _one_condition_case(F_TRIAL, true, K_TRIAL, "trial_cleared")
	_ck("B2 三波全清 → 仅解锁 grace.codex_trial_cleared.unlocked", r2[0], str(r2[1]))
	# B3 best_wave=2 不解锁 / B4 best_wave=3 解锁（≥3 边界）
	var ws3: Node = _new_mem_ws()
	var fw3: FakeWriter = FakeWriter.new()
	_track(fw3)
	var spy3: Spy = Spy.new()
	_track(spy3)
	var d3: Node = _new_director(ws3, fw3, MISSING_PATH, spy3)
	_set_flag(ws3, F_BEST, 2)
	_ck("B3 最高波次 2 < 3 → 不解锁 best_wave_ge3",
			not bool(d3.call("is_unlocked", "best_wave_ge3")) and fw3.commits.is_empty(),
			"unlocked=%s commits=%d" % [str(d3.call("is_unlocked", "best_wave_ge3")), fw3.commits.size()])
	_set_flag(ws3, F_BEST, 3)
	_ck("B4 最高波次 3 ≥ 3 → 解锁 best_wave_ge3 且只落盘一次",
			bool(d3.call("is_unlocked", "best_wave_ge3")) \
					and bool(_flag(ws3, K_BEST, false)) and fw3.commits.size() == 1,
			"unlocked=%s flag=%s commits=%d" % [
					str(d3.call("is_unlocked", "best_wave_ge3")), str(_flag(ws3, K_BEST, false)), fw3.commits.size()])
	# B5 三项增益 2/3 不解锁 / B6 3/3 解锁
	var ws4: Node = _new_mem_ws()
	var fw4: FakeWriter = FakeWriter.new()
	_track(fw4)
	var d4: Node = _new_director(ws4, fw4, MISSING_PATH)
	_set_flag(ws4, FLAG_UPGRADE_PREFIX + UPGRADE_IDS[0] + FLAG_UPGRADE_SUFFIX, true)
	_set_flag(ws4, FLAG_UPGRADE_PREFIX + UPGRADE_IDS[1] + FLAG_UPGRADE_SUFFIX, true)
	_ck("B5 三项增益仅 2/3 解锁 → 不解锁 all_upgrades",
			not bool(d4.call("is_unlocked", "all_upgrades")) and fw4.commits.is_empty(),
			"unlocked=%s commits=%d" % [str(d4.call("is_unlocked", "all_upgrades")), fw4.commits.size()])
	_set_flag(ws4, FLAG_UPGRADE_PREFIX + UPGRADE_IDS[2] + FLAG_UPGRADE_SUFFIX, true)
	_ck("B6 三项增益 3/3 解锁 → 解锁 all_upgrades",
			bool(d4.call("is_unlocked", "all_upgrades")) and bool(_flag(ws4, K_UPGRADES, false)),
			"unlocked=%s flag=%s" % [
					str(d4.call("is_unlocked", "all_upgrades")), str(_flag(ws4, K_UPGRADES, false))])
	# B7 信号：codex_entry_unlocked(id,title) 1 次 + codex_progress_changed 末条 (1,4)
	var last_prog: Dictionary = {} if spy3.progress.is_empty() else (spy3.progress[spy3.progress.size() - 1] as Dictionary)
	_ck("B7 信号 codex_progress_changed(unlocked,total) 末条 == (1,4)",
			int(last_prog.get("unlocked", -1)) == 1 and int(last_prog.get("total", -1)) == 4,
			"progress_signals=%s" % str(spy3.progress))
	_ck("B8 信号 codex_entry_unlocked(id,title) 恰好 1 次且 title 非空",
			spy3.unlocked.size() == 1 and not String((spy3.unlocked[0] as Dictionary).get("title", "")).is_empty(),
			"unlocked_signals=%s" % str(spy3.unlocked))


## 单条件用例：全新夹具，设一个来源 flag（自动触发 flag_changed → evaluate）。
## 返回 [ok, detail]：只解锁目标 1 项 / flag 为 true / progress 1/4 / commit 1 次。
func _one_condition_case(flag_key: String, value: Variant, codex_key: String, id: String) -> Array:
	var ws: Node = _new_mem_ws()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var d: Node = _new_director(ws, fw, MISSING_PATH)
	_set_flag(ws, flag_key, value)
	var prog: Dictionary = d.call("get_progress") as Dictionary
	var ok: bool = bool(d.call("is_unlocked", id)) and bool(_flag(ws, codex_key, false)) \
			and int(prog.get("unlocked", -1)) == 1 and int(prog.get("total", -1)) == 4 \
			and fw.commits.size() == 1
	var detail: String = "flag=%s codex=%s progress=%s/%s commits=%d" % [
			flag_key, str(_flag(ws, codex_key, false)), str(prog.get("unlocked", "?")),
			str(prog.get("total", "?")), fw.commits.size()]
	return [ok, detail]


# ---------------------------------------------------------------------------
# C) 严格「先落盘再改运行时实例」（stage_flags → disk_write → runtime_update）
# ---------------------------------------------------------------------------
func _test_order() -> void:
	var ws: Node = _new_mem_ws()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var spy: Spy = Spy.new()
	_track(spy)
	var d: Node = _new_director(ws, fw, MISSING_PATH, spy)
	_set_flag(ws, F_TUTORIAL, true)
	var ev: Array = d.call("get_unlock_events") as Array
	var i_stage: int = _index_of_prefix(ev, "stage_flags:")
	var i_disk: int = _index_of_prefix(ev, "disk_write:codex_unlocked")
	var i_runtime: int = _index_of_prefix(ev, "runtime_update:")
	_ck("C1 unlock_events 三段齐全且顺序 stage_flags < disk_write < runtime_update",
			i_stage >= 0 and i_disk >= 0 and i_runtime >= 0 \
					and i_stage < i_disk and i_disk < i_runtime,
			"events=%s" % str(ev))
	_ck("C2 commit(reason) == \"codex_unlocked\" 且恰好 1 次（先落盘）",
			fw.commits.size() == 1 and fw.commits[0] == COMMIT_REASON \
					and int(_status(d).get("commits", -1)) == 1,
			"commits=%s status.commits=%s" % [str(fw.commits), str(_status(d).get("commits", "?"))])
	_ck("C3 落盘之后才改运行时实例（_unlocked 镜像 + 解锁信号均非提前触发）",
			i_runtime > i_disk and spy.unlocked.size() == 1 \
					and bool(d.call("is_unlocked", "tutorial_complete")),
			"i_disk=%d i_runtime=%d signals=%d" % [i_disk, i_runtime, spy.unlocked.size()])
	# C4 一次解锁全 4 项：每项各一组严格三段（逐 flag_changed 事件驱动）
	var ws2: Node = _new_mem_ws()
	var fw2: FakeWriter = FakeWriter.new()
	_track(fw2)
	var d2: Node = _new_director(ws2, fw2, MISSING_PATH)
	_set_flag(ws2, F_TUTORIAL, true)
	_set_flag(ws2, F_TRIAL, true)
	_set_flag(ws2, F_BEST, 3)
	for id: String in UPGRADE_IDS:
		_set_flag(ws2, FLAG_UPGRADE_PREFIX + id + FLAG_UPGRADE_SUFFIX, true)
	var prog2: Dictionary = d2.call("get_progress") as Dictionary
	_ck("C4 4 类条件全满足 → 4/4 全解锁、每类各一次 commit（共 4 次）",
			int(prog2.get("unlocked", -1)) == 4 and fw2.commits.size() == 4,
			"progress=%s/4 commits=%d" % [str(prog2.get("unlocked", "?")), fw2.commits.size()])


func _index_of_prefix(arr: Array, prefix: String) -> int:
	for i: int in range(arr.size()):
		if String(arr[i]).begins_with(prefix):
			return i
	return -1


# ---------------------------------------------------------------------------
# D) 单向解锁 / E) 重复达成不双写
# ---------------------------------------------------------------------------
func _test_oneway_and_repeat() -> void:
	var ws: Node = _new_mem_ws()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var spy: Spy = Spy.new()
	_track(spy)
	var d: Node = _new_director(ws, fw, MISSING_PATH, spy)
	_set_flag(ws, F_TUTORIAL, true)
	var ev_before: int = (d.call("get_unlock_events") as Array).size()
	var commits_before: int = fw.commits.size()
	var sig_before: int = spy.unlocked.size()
	# D：来源 flag 复位 false → codex flag 绝不回写 false（单向）
	_set_flag(ws, F_TUTORIAL, false)
	_ck("D1 来源 flag 复位 false → codex flag 仍 true、不回写 false",
			bool(_flag(ws, K_TUTORIAL, false)) and bool(d.call("is_unlocked", "tutorial_complete")),
			"codex_flag=%s unlocked=%s" % [
					str(_flag(ws, K_TUTORIAL, false)), str(d.call("is_unlocked", "tutorial_complete"))])
	# E：重复达成（false→true 再触发 flag_changed）+ 多次 evaluate，不双写
	_set_flag(ws, F_TUTORIAL, true)
	d.call("evaluate")
	d.call("evaluate")
	_ck("E1 重复达成不双写：commit 次数不增",
			fw.commits.size() == commits_before,
			"commits_before=%d commits_after=%d" % [commits_before, fw.commits.size()])
	_ck("E2 重复达成不双写：unlock_events 长度不增（无第二组落盘/运行时事件）",
			(d.call("get_unlock_events") as Array).size() == ev_before,
			"events_before=%d events_after=%d" % [ev_before, (d.call("get_unlock_events") as Array).size()])
	_ck("E3 重复达成不双写：codex_entry_unlocked 信号不重发",
			spy.unlocked.size() == sig_before,
			"signals_before=%d signals_after=%d" % [sig_before, spy.unlocked.size()])
	_ck("D2 来源 flag 复位 + 重复达成后 progress 仍恒为 1/4（只增不减、不回退）",
			int((d.call("get_progress") as Dictionary).get("unlocked", -1)) == 1,
			"progress=%s" % str(d.call("get_progress")))


# ---------------------------------------------------------------------------
# F) Tab 开关（KEY_TAB，不与教学 T 键冲突 / 不干扰兑换键）
# ---------------------------------------------------------------------------
func _test_tab() -> void:
	var ws: Node = _new_mem_ws()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var d: Node = _new_director(ws, fw, MISSING_PATH)
	_ck("F1 面板默认隐藏", not bool(d.call("is_panel_open")),
			"panel_open=%s" % str(d.call("is_panel_open")))
	d.call("_unhandled_input", _tab_event(true))
	_ck("F2 KEY_TAB 按下 → 图鉴面板打开", bool(d.call("is_panel_open")),
			"panel_open=%s" % str(d.call("is_panel_open")))
	d.call("_unhandled_input", _tab_event(true))
	_ck("F3 KEY_TAB 再按 → 图鉴面板关闭（开关）", not bool(d.call("is_panel_open")),
			"panel_open=%s" % str(d.call("is_panel_open")))
	# 教学 T 键 84 / interact E / 数字键 1 均不触发图鉴
	var before: bool = bool(d.call("is_panel_open"))
	for code: int in [KEY_T, KEY_E, KEY_1]:
		d.call("_unhandled_input", _key_event(code, true))
	_ck("F4 教学 T(84) / E(69) / 1(49) 均不触发图鉴（不与教学 T 键冲突、不干扰兑换）",
			bool(d.call("is_panel_open")) == before,
			"before=%s after=%s" % [str(before), str(d.call("is_panel_open"))])
	# release 事件（pressed=false）不触发
	d.call("_unhandled_input", _tab_event(false))
	_ck("F5 Tab 释放事件（pressed=false）不触发开关",
			bool(d.call("is_panel_open")) == before,
			"panel_open=%s" % str(d.call("is_panel_open")))


# ---------------------------------------------------------------------------
# G) 面板不遮角色 / 独立 CanvasLayer / 高亮 / 进度 n/4
# ---------------------------------------------------------------------------
func _test_geometry() -> void:
	var ws: Node = _new_mem_ws()
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var d: Node = _new_director(ws, fw, MISSING_PATH)
	_set_flag(ws, F_TUTORIAL, true)
	var rect: Rect2 = d.call("get_panel_rect") as Rect2
	var avoids: Array = [
		["赐福HUD", RECT_GRACE_HUD], ["画质面板", RECT_QUALITY], ["波次HUD", RECT_WAVE],
		["教学HUD", RECT_TUTORIAL], ["兑换面板", RECT_SHOP], ["底部战斗HUD", RECT_BOTTOM],
		["玩家", RECT_PLAYER], ["Boss", RECT_BOSS],
	]
	var worst: float = 0.0
	var worst_name: String = ""
	for pair: Variant in avoids:
		var a: Array = pair as Array
		var area: float = _overlap_area(rect, a[1] as Rect2)
		if area > worst:
			worst = area
			worst_name = String(a[0])
	_ck("G1 面板与 6 套 HUD + 玩家/Boss + 兑换面板 8 矩形几何交集恒为 0（不遮角色）",
			worst == 0.0,
			"rect=%s worst_overlap=%.1f px² (%s)" % [str(rect), worst, worst_name])
	_ck("G2 面板矩形与 CODEX_RECT 一致且完整落在 1280×720 屏幕内",
			rect == CODEX_RECT and SCREEN.encloses(rect),
			"rect=%s expect=%s screen_encloses=%s" % [str(rect), str(CODEX_RECT), str(SCREEN.encloses(rect))])
	_ck("G3 半透明底 alpha ≤ 0.35",
			float(d.call("get_panel_alpha")) <= MAX_ALPHA,
			"alpha=%.2f ≤ %.2f" % [float(d.call("get_panel_alpha")), MAX_ALPHA])
	_ck("G4 运行时独立 CanvasLayer(layer=46)，不写 courtyard.tscn 场景节点",
			int(d.call("get_layer_index")) == 46 \
					and String(d.call("get_layer_name")) == "CodexPanelLayer" \
					and not String(d.call("get_layer_parent_name")).is_empty(),
			"layer_index=%s layer_name=%s parent=%s" % [
					str(d.call("get_layer_index")), str(d.call("get_layer_name")), str(d.call("get_layer_parent_name"))])
	# 4 项名称/描述/已达成高亮/进度 n/4
	var titles: Array = []
	var got0: bool = bool(d.call("is_unlocked", "tutorial_complete"))
	var row0: String = String(d.call("get_row_text", 0))
	var row1: String = String(d.call("get_row_text", 1))
	var all_rows_filled: bool = true
	for i: int in range(4):
		var t: String = String(d.call("get_row_text", i))
		titles.append(t)
		if t.is_empty() or not t.contains("｜"):
			all_rows_filled = false
	_ck("G5 面板 4 行均含「标记 名称｜描述」", all_rows_filled, "rows=%s" % str(titles))
	_ck("G6 已达成行高亮(✓+GOLD) / 未达成行暗色(○+DIM)",
			got0 and row0.begins_with("✓") and row1.begins_with("○") \
					and _color_close(d.call("get_row_color", 0) as Color, GOLD) \
					and _color_close(d.call("get_row_color", 1) as Color, DIM),
			"row0=%s color0=%s | row1=%s color1=%s" % [
					row0, str(d.call("get_row_color", 0)), row1, str(d.call("get_row_color", 1))])
	_ck("G7 进度文本为 n/4（当前 1/4）",
			String(d.call("get_progress_text")) == "进度 1/4",
			"progress_text=%s" % str(d.call("get_progress_text")))


func _color_close(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.02 and absf(a.g - b.g) < 0.02 \
			and absf(a.b - b.b) < 0.02


# ---------------------------------------------------------------------------
# H) courtyard.tscn 静态节点数 41 + 未写入图鉴节点（裁决 A35）
# ---------------------------------------------------------------------------
func _test_node_count() -> void:
	var text: String = FileAccess.get_file_as_string(COURTYARD_PATH)
	var count: int = 0
	for line: String in text.split("\n"):
		if line.begins_with("[node "):
			count += 1
	_ck("H1 courtyard.tscn 静态 [node] 行数 == 41（A35 节点数保持）",
			count == NODE_COUNT_EXPECTED, "count=%d expected=%d" % [count, NODE_COUNT_EXPECTED])
	_ck("H2 courtyard.tscn 文本无 CodexPanelLayer / CodexDirector（运行时建层、不写场景）",
			not text.contains("CodexPanelLayer") and not text.contains("CodexDirector"),
			"contains_layer=%s contains_director=%s" % [
					str(text.contains("CodexPanelLayer")), str(text.contains("CodexDirector"))])


# ---------------------------------------------------------------------------
# I) 成就 flag 三段式合法（不改 world_state.gd 正则）
# ---------------------------------------------------------------------------
func _test_flag_keys() -> void:
	var keys: Array[String] = [K_TUTORIAL, K_TRIAL, K_UPGRADES, K_BEST]
	var all_ok: bool = true
	for k: String in keys:
		if _re.search(k) == null:
			all_ok = false
	_ck("I1 4 个 grace.codex_<id>.unlocked 均匹配 WorldState 三段式正则",
			all_ok, "keys=%s regex=%s" % [str(keys), FLAG_KEY_REGEX])
	_ck("I2 4 个成就 key 互不重复且 id 段含下划线（A36 / A23 口径）",
			keys.size() == 4 and K_TUTORIAL != K_TRIAL and K_TRIAL != K_UPGRADES \
					and K_UPGRADES != K_BEST and K_BEST != K_TUTORIAL \
					and K_UPGRADES.contains("all_upgrades"),
			"keys=%s" % str(keys))


func _finish() -> void:
	# 倒序释放：先 free director（断开到 Spy 的信号连接）再 free Spy / 替身，避免悬空 Callable。
	for i: int in range(_temps.size() - 1, -1, -1):
		var n: Node = _temps[i]
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	var ok: bool = _fail == 0 and _pass > 0
	print("[V080] ---- 回读汇总 ----")
	print("[V080] SUMMARY pid=%d pass=%d fail=%d ok=%s" % [
			OS.get_process_id(), _pass, _fail, str(ok)])
	print("[V080] RESULT=%s" % ("PASS" if ok else "FAIL"))
	print("[V080] ==== verify_codex_v080 真跑结束 ====")
	quit(0 if ok else 1)
