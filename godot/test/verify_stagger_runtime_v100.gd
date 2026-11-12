extends SceneTree
## ===========================================================================
## R32 [ROUND=R32] · v0.10.0 韧性处决窗口运行时自测（Rank-1）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://test/verify_stagger_runtime_v100.gd
##
## 背景：Rank-2 stagger_service.gd（RefCounted 纯逻辑）本轮并行交付、此刻未落盘。
##   本脚本用 FakeStaggerService（同名公开方法 / 信号替身）注入 HUD 适配层，
##   验证 Rank-1 接线闭环；**不冒充 Rank-2 真实服务已联调**（见 DONE-R32 待复跑项）。
##
## 断言组：
##   A 窗口开启（信号 emit → HUD window_open=true / 读秒>0 / 韧性条 + 窗口提示）
##   B 超时关闭（tick_stagger 推进超过窗口时长 → 自动关窗）
##   C F 触发（窗口内 process_key_event(KEY_F) → execution_performed / execution_count=1）
##   D 重复触发拒绝（同一窗口内再次 F / request_execution 被拒，计数不变；新窗口可复位）
##   E Input.parse_input_event 注入 F 键可用（注入事件经同一处理路径完成处决）
##   F 降级安全（窗口外 / 未绑定服务时请求均拒绝、无 SCRIPT ERROR）
##   G 契约边界（重复 bind 去重连接 / _exit_tree 释放路径存在）
## 输出：逐条 PASS/FAIL + RESULT=ALL_MATCH（全通过）/ MISMATCH。
##
## --script / SceneTree 纪律：不用 get_tree()、不用 /root/... 绝对路径；
##   add_child 不自动 flush _ready() → 显式 call("_ready") 后 set_process(false)；
##   资源回读 ResourceLoader.load(..., CACHE_MODE_IGNORE)；本脚本只读、不改任何工程文件。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。
## ===========================================================================

const HUD_PATH: String = "res://scripts/hud.gd"
## Rank-2 真实服务路径（此刻未落盘；仅登记回读，不加载、不冒充联调）。
const STAGGER_SERVICE_PATH: String = "res://scripts/combat/stagger_service.gd"


## 契约替身：声明与 Rank-2 stagger_service 契约一致的公开方法 / 信号，
## 不读私有实现、不改既有战斗件；只用于确定性 emit / 状态机验证。
class FakeStaggerService extends Node:
	var _window_open: bool = false
	var _remaining: float = 0.0
	var _poise: float = 1.0
	var _exec_count: int = 0

	func _init() -> void:
		add_user_signal("execution_window_opened", [{"name": "duration", "type": TYPE_FLOAT}])
		add_user_signal("execution_window_closed")

	func open_window(sec: float) -> void:
		_window_open = true
		_remaining = sec
		emit_signal("execution_window_opened", sec)

	func is_window_open() -> bool:
		return _window_open

	func get_window_remaining_sec() -> float:
		return _remaining

	func get_poise_ratio() -> float:
		return _poise

	func set_poise_ratio(v: float) -> void:
		_poise = clampf(v, 0.0, 1.0)

	func tick(delta: float) -> void:
		_remaining = maxf(0.0, _remaining - delta)
		if _remaining <= 0.0 and _window_open:
			_window_open = false
			emit_signal("execution_window_closed")

	func perform_execution() -> Dictionary:
		_exec_count += 1
		return {"ok": true, "bonus_points": 5}


var _pass: int = 0
var _fail: int = 0
var _temps: Array[Node] = []
var _hud_script: Script = null
var _hud: Node = null
var _svc: Node = null
var _exec_signal_count: int = 0
var _last_exec_bonus: int = -1


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V100STG] %s PASS=%s | %s" % [tag, str(ok), detail])


func _track(n: Node) -> void:
	_temps.append(n)


func _on_exec(_id: String, bonus: int) -> void:
	_exec_signal_count += 1
	_last_exec_bonus = bonus


func _key(code: int) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	e.echo = false
	return e


func _new_hud() -> Node:
	var host: Node = Node.new()
	host.name = "StaggerRuntimeTestHost"
	_track(host)
	root.add_child(host)
	var hud: Node = _hud_script.new() as Node
	_track(hud)
	host.add_child(hud)
	if not hud.is_node_ready():
		hud.call("_ready")
	hud.set_process(false)
	hud.set_process_unhandled_input(false)
	if hud.has_signal("execution_performed"):
		hud.connect("execution_performed", Callable(self, "_on_exec"))
	return hud


func _initialize() -> void:
	print("[V100STG] ==== verify_stagger_runtime_v100 真跑开始 | R32 v0.10.0 Rank-1 ====")
	_hud_script = ResourceLoader.load(
			HUD_PATH, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if _hud_script == null:
		print("[V100STG] RESULT=MISMATCH（hud.gd 加载失败）")
		quit(1)
		return
	_svc = FakeStaggerService.new()
	_track(_svc)
	root.add_child(_svc)
	_hud = _new_hud()
	var real_exists: bool = ResourceLoader.exists(STAGGER_SERVICE_PATH)
	print("[V100STG] Rank-2 stagger_service.gd exists=%s（未落盘则用契约替身，不冒充联调）" % str(real_exists))
	_hud.call("bind_stagger_service", _svc)
	_test_window_open()
	_test_timeout_close()
	_test_f_trigger()
	_test_repeat_reject()
	_test_input_injection()
	_test_degrade_safety()
	_test_contract()
	_test_real_service()
	_finish()


# ---------------------------------------------------------------------------
# A) 窗口开启
# ---------------------------------------------------------------------------
func _test_window_open() -> void:
	var hud: Node = _hud
	_svc.call("set_poise_ratio", 0.42)
	hud.call("poll_stagger_service")
	_svc.call("open_window", 2.0)
	var v: Dictionary = hud.call("get_stagger_hud_view") as Dictionary
	_ck("A1 处决窗口开启：window_open=true / 读秒>0",
			bool(v.get("window_open", false)) and float(v.get("remaining_sec", 0.0)) > 0.0,
			"window_open=%s remaining=%s" % [
					str(v.get("window_open", "?")), str(v.get("remaining_sec", "?"))])
	_ck("A2 HUD 显示 Boss 韧性条与「处决窗口」读秒提示",
			str(v.get("poise_text", "")).contains("韧性") \
					and str(v.get("window_text", "")).contains("处决窗口"),
			"poise_text=[%s] window_text=[%s]" % [
					str(v.get("poise_text", "")), str(v.get("window_text", ""))])
	_ck("A3 Boss 韧性经公开方法回读（0.42）",
			absf(float(v.get("poise_ratio", 0.0)) - 0.42) < 0.0001,
			"poise_ratio=%s" % str(v.get("poise_ratio", "?")))


# ---------------------------------------------------------------------------
# B) 超时关闭
# ---------------------------------------------------------------------------
func _test_timeout_close() -> void:
	var hud: Node = _hud
	hud.call("tick_stagger", 2.5)
	var v: Dictionary = hud.call("get_stagger_hud_view") as Dictionary
	_ck("B1 处决窗口超时自动关闭：window_open=false / 读秒=0",
			not bool(v.get("window_open", true)) \
					and float(v.get("remaining_sec", -1.0)) == 0.0,
			"window_open=%s remaining=%s" % [
					str(v.get("window_open", "?")), str(v.get("remaining_sec", "?"))])


# ---------------------------------------------------------------------------
# C) F 触发
# ---------------------------------------------------------------------------
func _test_f_trigger() -> void:
	var hud: Node = _hud
	_exec_signal_count = 0
	_svc.call("open_window", 2.0)
	var consumed: bool = bool(hud.call("process_key_event", _key(KEY_F)))
	var v: Dictionary = hud.call("get_stagger_hud_view") as Dictionary
	_ck("C1 窗口内按 F 触发处决：execution_performed emit / execution_count=1 / F 被消费",
			consumed and _exec_signal_count == 1 \
					and int(v.get("execution_count", 0)) == 1 \
					and bool(v.get("execution_consumed", false)),
			"consumed=%s signal=%d count=%s consumed_flag=%s" % [
					str(consumed), _exec_signal_count,
					str(v.get("execution_count", "?")), str(v.get("execution_consumed", "?"))])


# ---------------------------------------------------------------------------
# D) 重复触发拒绝
# ---------------------------------------------------------------------------
func _test_repeat_reject() -> void:
	var hud: Node = _hud
	hud.call("process_key_event", _key(KEY_F))
	var r: Dictionary = hud.call("request_execution") as Dictionary
	var v: Dictionary = hud.call("get_stagger_hud_view") as Dictionary
	_ck("D1 同一窗口内重复 F / 重复 request_execution 均被拒绝（计数不变）",
			not bool(r.get("ok", true)) and int(v.get("execution_count", 0)) == 1 \
					and _exec_signal_count == 1,
			"repeat_reason=%s count=%s signal=%d" % [
					str(r.get("reason", "?")), str(v.get("execution_count", "?")), _exec_signal_count])
	hud.call("tick_stagger", 2.5)
	_svc.call("open_window", 2.0)
	var r2: Dictionary = hud.call("request_execution") as Dictionary
	var v2: Dictionary = hud.call("get_stagger_hud_view") as Dictionary
	_ck("D2 新窗口开启后 consumed 复位、可再次处决（不误锁死）",
			bool(r2.get("ok", false)) and int(v2.get("execution_count", 0)) == 2,
			"ok=%s reason=%s count=%s" % [
					str(r2.get("ok", "?")), str(r2.get("reason", "?")),
					str(v2.get("execution_count", "?"))])


# ---------------------------------------------------------------------------
# E) Input.parse_input_event 注入
# ---------------------------------------------------------------------------
func _test_input_injection() -> void:
	var hud: Node = _hud
	hud.call("tick_stagger", 2.5)
	_svc.call("open_window", 2.0)
	var before: int = int((hud.call("get_stagger_hud_view") as Dictionary).get("execution_count", 0))
	# 用 Input.parse_input_event 注入一个 F 键事件（引擎输入队列），再从同一事件对象
	# 走 HUD 的 process_key_event 路径（--script 无 GUI 分发，故显式喂同一路径）。
	var ev: InputEventKey = _key(KEY_F)
	Input.parse_input_event(ev)
	var consumed: bool = bool(hud.call("process_key_event", ev))
	var after: int = int((hud.call("get_stagger_hud_view") as Dictionary).get("execution_count", 0))
	_ck("E1 注入 F 键事件经 process_key_event 同一路径完成一次处决",
			consumed and after == before + 1,
			"before=%d after=%d consumed=%s" % [before, after, str(consumed)])


# ---------------------------------------------------------------------------
# F) 降级安全
# ---------------------------------------------------------------------------
func _test_degrade_safety() -> void:
	var hud: Node = _hud
	hud.call("tick_stagger", 2.5)
	var r: Dictionary = hud.call("request_execution") as Dictionary
	_ck("F1 窗口外触发处决被拒绝（window_closed）",
			not bool(r.get("ok", true)), "reason=%s" % str(r.get("reason", "?")))
	hud.call("bind_stagger_service", null)
	var r2: Dictionary = hud.call("request_execution") as Dictionary
	_ck("F2 未绑定 Rank-2 服务（降级）时请求不崩、如实拒绝",
			not bool(r2.get("ok", true)), "reason=%s" % str(r2.get("reason", "?")))
	hud.call("bind_stagger_service", _svc)


# ---------------------------------------------------------------------------
# G) 契约边界
# ---------------------------------------------------------------------------
func _test_contract() -> void:
	var hud: Node = _hud
	var c1: int = _svc.get_signal_connection_list("execution_window_opened").size()
	hud.call("bind_stagger_service", _svc)
	var c2: int = _svc.get_signal_connection_list("execution_window_opened").size()
	_ck("G1 重复 bind_stagger_service 后信号连接仍仅 1 条（去重）",
			c1 == 1 and c2 == 1, "before=%d after=%d" % [c1, c2])
	_ck("G2 _exit_tree 释放路径存在（hud.gd 含 _unbind_stagger_signals）",
			FileAccess.get_file_as_string(HUD_PATH).contains("_unbind_stagger_signals"),
			"release_path=true")


# ---------------------------------------------------------------------------
# H) 真实 Rank-2 StaggerService 联调（落盘则跑真实实例；未落盘则跳过并如实登记）
# ---------------------------------------------------------------------------
func _test_real_service() -> void:
	var cfg_path: String = "res://data/combat/stagger_rules.tres"
	var svc_script: Script = ResourceLoader.load(
			STAGGER_SERVICE_PATH, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
	var cfg: Resource = null
	if ResourceLoader.exists(cfg_path):
		cfg = ResourceLoader.load(cfg_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	if svc_script == null or cfg == null:
		print("[V100STG] H 组 SKIP：Rank-2 stagger_service.gd / stagger_rules.tres 未落盘，如实登记待复跑")
		return
	print("[V100STG] H 组：Rank-2 真实服务已落盘 → 绑定真实 StaggerService 实例做联调")
	var real: Object = svc_script.new(cfg)
	_hud.call("bind_stagger_service", real)
	var v0: Dictionary = _hud.call("get_stagger_hud_view") as Dictionary
	_ck("H1 真实 StaggerService 绑定成功（service_available=true / 初始未开窗 / 满韧性）",
			bool(v0.get("service_available", false)) and not bool(v0.get("window_open", true)) \
					and absf(float(v0.get("poise_ratio", 0.0)) - 1.0) < 0.0001,
			"service=%s window=%s poise=%s" % [
					str(v0.get("service_available", "?")), str(v0.get("window_open", "?")),
					str(v0.get("poise_ratio", "?"))])
	# 真实 apply_hit(100) 削韧归零 → execution_window_opened(3.0, 50) → HUD 开窗
	real.call("apply_hit", 100.0)
	var v1: Dictionary = _hud.call("get_stagger_hud_view") as Dictionary
	_ck("H2 真实 apply_hit(100) 开窗：HUD window_open=true / 读秒>0 / 韧性 0% / bonus=50",
			bool(v1.get("window_open", false)) and float(v1.get("remaining_sec", 0.0)) > 0.0 \
					and absf(float(v1.get("poise_ratio", 1.0))) < 0.0001 \
					and int(v1.get("window_bonus", 0)) == 50,
			"window=%s remaining=%s poise=%s bonus=%s" % [
					str(v1.get("window_open", "?")), str(v1.get("remaining_sec", "?")),
					str(v1.get("poise_ratio", "?")), str(v1.get("window_bonus", "?"))])
	# 窗口内 F → 真实 try_execute()（bonus=50、关窗 + closed(executed)）
	_exec_signal_count = 0
	_last_exec_bonus = -1
	var consumed: bool = bool(_hud.call("process_key_event", _key(KEY_F)))
	var v2: Dictionary = _hud.call("get_stagger_hud_view") as Dictionary
	_ck("H3 窗口内 F 触发真实 try_execute：execution_performed(bonus=50) / 真实服务关窗",
			consumed and _exec_signal_count == 1 and _last_exec_bonus == 50 \
					and not bool(v2.get("window_open", true)),
			"consumed=%s signal=%d bonus=%d window=%s" % [
					str(consumed), _exec_signal_count, _last_exec_bonus,
					str(v2.get("window_open", "?"))])
	# 再开窗 → 真实服务 tick(999) 超时 → closed(timeout) → HUD 关窗
	real.call("apply_hit", 100.0)
	var v3: Dictionary = _hud.call("get_stagger_hud_view") as Dictionary
	var reopened: bool = bool(v3.get("window_open", false))
	real.call("tick", 999.0)
	var v4: Dictionary = _hud.call("get_stagger_hud_view") as Dictionary
	_ck("H4 真实服务 tick(999) 超时 → closed(timeout) → HUD 关窗",
			reopened and not bool(v4.get("window_open", true)),
			"reopened=%s after_tick_window=%s" % [
					str(reopened), str(v4.get("window_open", "?"))])


func _finish() -> void:
	for i: int in range(_temps.size() - 1, -1, -1):
		var n: Node = _temps[i]
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	var ok: bool = _fail == 0 and _pass > 0
	print("[V100STG] ---- 回读汇总 ----")
	print("[V100STG] SUMMARY pass=%d fail=%d total=%d ok=%s" % [
			_pass, _fail, _pass + _fail, str(ok)])
	if ok:
		print("[V100STG] RESULT=ALL_MATCH")
	else:
		print("[V100STG] RESULT=MISMATCH")
	print("[V100STG] ==== verify_stagger_runtime_v100 真跑结束 ====")
	quit(0 if ok else 1)
