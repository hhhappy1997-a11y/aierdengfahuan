extends SceneTree
## ===========================================================================
## R35 [ROUND=R35] · v0.12.0 精准弹反【真实可达回归】（Rank-1 唯一写入方）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/render/verify_parry_runtime_v120.gd
##
## A49 / A48③ 口径：【不加载 presentation.gd】、【不在验证脚本内模拟编排】。
##   本脚本自行 instantiate 主场景 courtyard.tscn（CACHE_MODE_IGNORE），
##   显式 _ready() / _r34_bootstrap() 完成生产装配后，注入【真实 K 输入】
##   （Input.parse_input_event + HUD.process_key_event，与 _unhandled_input 同一路径），
##   断言「真实输入 → 生产链路（HUD → parry_performed → EncounterDirector 真实削韧
##   → points_awarded → PointsCommitOrchestrator 生产 autoload）→ 磁盘 / 画面」确实发生。
##   点数落盘 / 去重 / 原子写全部由【生产脚本】points_commit_orchestrator.gd 执行，
##   本脚本只读磁盘断言；独立 PID 临时槽与生产 slot_01 物理隔离（md5 前后对照）。
##
## A54：ParryService 唯一实例优先复用 wave_trial_director.get_parry_service()；
##   绝不 new 第二个生产实例。Rank-2 本轮并发新增件【尚未落盘】时，启用
##   FakeParry 契约替身（同 verify_production_chains_v110.gd 的 FakeCombo 先例），
##   仅证明 Rank-1 生产接线链真实连通，如实登记「真实判定逻辑待 Rank-2 落盘联调」，
##   不冒充已联调、不伪造产物。
##
## 断言组：
##   P 装配：A54 唯一实例 / A48① 生产运行时订阅者 / 信号方法 / A38 节点 41 uv 2/1/1
##   W 窗口：金色预兆 + 读秒可见 / 窗口内成功 / 窗口外拒绝 / 重复幂等 /
##           冷却期拒绝 / 超时关窗 / 非空 window_id 且两次窗口不合并（A58）
##   C 生产链：parry_performed → ENC 真实削韧 / points_awarded → 编排层 → 磁盘 /
##           生产 slot_01 不污染 / A58 处决 exe: 去重键不合并不同窗口
##
## --script / SceneTree 纪律：用 Engine.get_main_loop() as SceneTree 取 root，
##   不用 get_tree() / 不用 /root/... 绝对路径；add_child 不自动 flush _ready() →
##   显式 call("_ready")；资源 CACHE_MODE_IGNORE；connect 前 get_signal_connection_list
##   去重、_finish() 有 disconnect / _release() 释放路径；project.godot 已有的
##   PointsCommitOrchestrator autoload 直接复用，不重复挂载。
## 输出：逐条 PASS/FAIL + SUMMARY + RESULT=ALL_MATCH（全通过）/ MISMATCH。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。
## ===========================================================================

const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"
const NODE_COUNT_EXPECTED: int = 41
const REL_HUD: String = "SubViewportContainer/SubViewport/FXLayer/Hud"
const REL_ENC: String = "EncounterRoot"
const REL_WAVE: String = "WaveTrialDirector"
const KEY_K: int = 75
const PCO_AUTOLOAD_NAME: String = "PointsCommitOrchestrator"
const PCO_PATH: String = "res://scripts/rpg/points_commit_orchestrator.gd"
const PRODUCTION_DELTA: String = "user://saves/slot_01/delta.json"
const SLOT_BASE: String = "user://saves/verify_r35_parry"
const K_POINTS: String = "grace.trial.points"


## 契约替身：Rank-2 ParryService（本轮并发新增、未落盘时启用）。只声明与 Rank-2
## 任务单公布的稳定公开方法 / 快照同构的接口，用于证明 Rank-1 生产接线链真实连通，
## 不冒充真实判定联调、不读写存档、不碰渲染（同 R34 FakeCombo 先例）。
class FakeParry extends RefCounted:
	signal parry_window_opened(remaining_sec: float, window_id: String)
	var window_open: bool = false
	var remaining: float = 0.0
	var cooldown: float = 0.0
	var seq: int = 0
	var success_count: int = 0
	var window_sec: float = 1.2
	var cooldown_sec: float = 0.6
	var poise_bonus: float = 25.0
	var points_bonus: int = 30

	func open_window() -> Dictionary:
		seq += 1
		window_open = true
		remaining = window_sec
		parry_window_opened.emit(window_sec, "")
		return {"ok": true, "opened": seq}

	func try_parry() -> Dictionary:
		if not window_open:
			return {"ok": false, "reason": "window_closed"}
		if cooldown > 0.0:
			return {"ok": false, "reason": "cooldown"}
		window_open = false
		cooldown = cooldown_sec
		success_count += 1
		return {"ok": true, "points_bonus": points_bonus, "poise_bonus": poise_bonus}

	func tick(delta: float) -> void:
		if window_open:
			remaining = maxf(0.0, remaining - delta)
			if remaining <= 0.0:
				window_open = false
		if cooldown > 0.0:
			cooldown = maxf(0.0, cooldown - delta)

	func on_boss_move_landed() -> void:
		pass

	func reset() -> void:
		window_open = false
		remaining = 0.0
		cooldown = 0.0

	func get_snapshot() -> Dictionary:
		return {"window_open": window_open, "window_remaining": remaining,
				"cooldown_remaining": cooldown, "poise_bonus": poise_bonus,
				"points_bonus": points_bonus, "opened": seq,
				"parry_service": "fake_contract"}


var _pass: int = 0
var _fail: int = 0
var _tree: SceneTree = null
var _courtyard: Node = null
var _hud: Node = null
var _enc: Node = null
var _wave: Node = null
var _parry: Object = null
var _fake: FakeParry = null
var _parry_source: String = "none"
var _orch: Node = null
var _slot_dir: String = ""
var _delta_path: String = ""
var _prod_md5_before: String = ""
var _probes_connected: bool = false

# 探针信号回读（只读统计，不写任何状态）
var _parry_log: Array[Dictionary] = []
var _points_log: Array[Dictionary] = []
var _exec_log: Array[Dictionary] = []


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V120P] %s PASS=%s | %s" % [tag, str(ok), detail])


func _key(code: int, pressed: bool) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	e.echo = false
	return e


func _dedup_connect(obj: Object, sig: String, method: String) -> bool:
	if obj == null or not obj.has_signal(sig):
		return false
	var cb: Callable = Callable(self, method)
	for conn in obj.get_signal_connection_list(sig):
		var c: Callable = conn.get("callable", Callable())
		if c.get_object() == self and String(c.get_method()) == method:
			return false
	obj.connect(sig, cb)
	return true


func _on_parry(window_id: String, bonus_points: int, poise_bonus: float) -> void:
	_parry_log.append({"window_id": window_id, "bonus_points": bonus_points,
			"poise_bonus": poise_bonus})


func _on_points(reason: String, points: int, source: String) -> void:
	_points_log.append({"reason": reason, "points": points, "source": source})


func _on_exec(window_id: String, bonus_points: int) -> void:
	_exec_log.append({"window_id": window_id, "bonus_points": bonus_points})


func _initialize() -> void:
	print("[V120P] ==== verify_parry_runtime_v120 真跑开始 | R35 v0.12.0 Rank-1 ====")
	print("[V120P] A49/A48③：不加载 presentation.gd；不模拟编排；真实 K 输入 → 生产链路 → 磁盘/画面")
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null:
		print("[V120P] RESULT=MISMATCH（Engine.get_main_loop() 非 SceneTree）")
		quit(1)
		return
	_load_main_scene()
	if _courtyard == null:
		_finish(true)
		return
	_resolve_nodes()
	if not _explicit_ready():
		_finish(true)
		return
	_explicit_bootstrap()
	if _enc != null:
		_enc.set("simulate_boss", false)
	_bind_parry_service()
	_bind_probes()
	_prepare_orchestrator()
	_t_p_assembly()
	_t_w_window_and_input()
	_t_c_production_chain()
	_t_a65_parry_negate()            # R36：A65 弹反成功免伤追加组（既有 27 条断言不删不放宽）
	_finish(false)


func _load_main_scene() -> void:
	var packed: PackedScene = ResourceLoader.load(
			COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		return
	_courtyard = packed.instantiate()
	if _courtyard == null:
		return
	_tree.root.add_child(_courtyard)
	print("[V120P] 主场景已实例化入树 | name=%s（未加载 presentation.gd）" % str(_courtyard.name))


func _resolve_nodes() -> void:
	_hud = _courtyard.get_node_or_null(NodePath(REL_HUD))
	_enc = _courtyard.get_node_or_null(NodePath(REL_ENC))
	_wave = _courtyard.get_node_or_null(NodePath(REL_WAVE))
	_ck("P0 主场景关键节点可寻址（EncounterRoot / Hud / WaveTrialDirector）",
			_hud != null and _enc != null and _wave != null,
			"enc=%s hud=%s wave=%s" % [str(_enc != null), str(_hud != null), str(_wave != null)])


func _explicit_ready() -> bool:
	if _hud == null or _enc == null or _wave == null:
		return false
	for n: Node in [_enc, _hud, _wave]:
		if not n.is_node_ready() and n.has_method("_ready"):
			n.call("_ready")
	return true


func _explicit_bootstrap() -> void:
	if _enc.has_method("_r34_bootstrap"):
		_enc.call("_r34_bootstrap")     # 内部末尾触发 _r35_bootstrap（生产订阅者）
	if _hud.has_method("_r34_bootstrap"):
		_hud.call("_r34_bootstrap")     # 内部复用 wave.get_parry_service（A54）


## A54：优先复用 wave.get_parry_service() 唯一实例；Rank-2 未落盘 → 契约替身（如实登记）。
func _bind_parry_service() -> void:
	var existing: Object = null
	if _wave != null and _wave.has_method("get_parry_service"):
		existing = _wave.call("get_parry_service") as Object
	if existing != null and is_instance_valid(existing) \
			and existing.has_method("open_window") and existing.has_method("try_parry"):
		_parry = existing
		_parry_source = "rank2_production_unique_instance"
		if _hud != null and _hud.has_method("bind_parry_service"):
			_hud.call("bind_parry_service", _parry)
		print("[V120P] A54：复用 wave.get_parry_service() 唯一实例（Rank-2 真实服务已落盘）→ 走真实判定")
	else:
		_fake = FakeParry.new()
		_parry = _fake
		_parry_source = "fake_contract_rank2_not_landed"
		if _hud != null and _hud.has_method("bind_parry_service"):
			_hud.call("bind_parry_service", _fake)
		print("[V120P] [如实登记] Rank-2 ParryService 未落盘 → 契约替身 FakeParry 仅验证 Rank-1 生产接线链；真实判定逻辑待 Rank-2 落盘联调，不冒充")


func _bind_probes() -> void:
	if _hud == null:
		return
	_probes_connected = true
	_dedup_connect(_hud, "parry_performed", "_on_parry")
	_dedup_connect(_hud, "points_awarded", "_on_points")
	_dedup_connect(_hud, "execution_performed", "_on_exec")


func _prepare_orchestrator() -> void:
	# 优先复用引擎已装配的 PointsCommitOrchestrator autoload（绝不重复挂载第二个实例）。
	_orch = _tree.root.get_node_or_null(NodePath(PCO_AUTOLOAD_NAME)) as Node
	var source: String = "autoload"
	if _orch != null:
		if _orch.has_method("_ready") and not _orch.is_node_ready():
			_orch.call("_ready")
	else:
		var scr: Script = ResourceLoader.load(
				PCO_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		if scr != null:
			var n: Node = Node.new()
			n.name = PCO_AUTOLOAD_NAME
			n.set_script(scr)
			_tree.root.add_child(n)
			if n.has_method("_ready"):
				n.call("_ready")
			_orch = n
			source = "manual-same-script"
	_ck("C0 生产编排层实例就位（优先 autoload，不重复挂载；降级时挂同一生产脚本）",
			_orch != null and is_instance_valid(_orch), "source=%s" % source)
	if _orch == null:
		return
	_slot_dir = "%s_%d" % [SLOT_BASE, OS.get_process_id()]
	_delta_path = _slot_dir + "/delta.json"
	_prod_md5_before = _prod_md5()
	var cfg_ok: bool = bool(_orch.call("configure_slot", _slot_dir))
	_ck("C0b 独立 PID 临时槽与生产 slot_01 物理隔离（落盘前注入）",
			cfg_ok and not _slot_dir.contains("slot_01") and _delta_path != PRODUCTION_DELTA,
			"slot=%s" % _slot_dir)
	var bound: bool = bool(_orch.call("bind_hud", _hud))
	_ck("C0c PointsCommitOrchestrator.bind_hud 成功（A55 唯一权威通道，生产订阅者）",
			bound, "bound=%s" % str(bound))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


func _disk_points() -> int:
	var d: Dictionary = _read_json(_delta_path)
	var flags: Dictionary = d.get("flags", {}) as Dictionary
	return int(flags.get(K_POINTS, 0))


func _prod_md5() -> String:
	if not FileAccess.file_exists(PRODUCTION_DELTA):
		return "<absent>"
	return FileAccess.get_md5(PRODUCTION_DELTA)


## 开窗：调【生产对象】的公开 open_window()（Rank-2 契约入口，非演示驱动 / 非自模拟编排），
## 再经 HUD.poll_parry_service() 由服务权威快照同步窗口状态。
func _open_window() -> Dictionary:
	var res: Dictionary = {}
	if _parry != null and is_instance_valid(_parry) and _parry.has_method("open_window"):
		var r: Variant = _parry.call("open_window")
		if typeof(r) == TYPE_DICTIONARY:
			res = r as Dictionary
	if _hud != null and _hud.has_method("poll_parry_service"):
		_hud.call("poll_parry_service")
	return res


## 真实 K 输入：Input.parse_input_event 注入 + HUD.process_key_event（与 _unhandled_input
## 完全相同的 R32 键处理路径），松开配对后返回结果由 get_parry_attempt_log() 最后一条读回。
func _press_k() -> void:
	var press: InputEventKey = _key(KEY_K, true)
	Input.parse_input_event(press)
	_hud.call("process_key_event", press)
	var rel: InputEventKey = _key(KEY_K, false)
	Input.parse_input_event(rel)
	_hud.call("process_key_event", rel)


func _last_attempt() -> Dictionary:
	var log: Array[Dictionary] = _hud.call("get_parry_attempt_log") as Array[Dictionary]
	if log.is_empty():
		return {}
	return log[log.size() - 1] as Dictionary


func _advance(delta: float) -> void:
	if _parry != null and is_instance_valid(_parry) and _parry.has_method("tick"):
		_parry.call("tick", delta)
	if _hud != null and _hud.has_method("tick_parry"):
		_hud.call("tick_parry", delta)
	if _hud != null and _hud.has_method("poll_parry_service"):
		_hud.call("poll_parry_service")


# ---------------------------------------------------------------------------
# P) 装配 / A54 / A48① / A38
# ---------------------------------------------------------------------------
func _t_p_assembly() -> void:
	var hud_parry: Object = null
	if _hud.has_method("get_parry_service"):
		hud_parry = _hud.call("get_parry_service") as Object
	_ck("P1 A54 唯一实例：HUD.get_parry_service() 与验证复用的唯一实例为同一 Object（绝不自建第二实例）",
			_parry != null and hud_parry == _parry,
			"source=%s hud_bound=%s same=%s" % [_parry_source, str(hud_parry != null), str(hud_parry == _parry)])
	# A48①：parry_performed 的生产运行时订阅者 = EncounterDirector（非验证脚本）。
	var prod_subscriber: bool = false
	for conn in _hud.get_signal_connection_list("parry_performed"):
		var c: Callable = conn.get("callable", Callable())
		if c.get_object() == _enc:
			prod_subscriber = true
	_ck("P2 A48① ★ parry_performed 有【生产运行时订阅者 EncounterDirector】（不只是验证脚本订阅）",
			prod_subscriber,
			"subscribers=%d enc_subscribed=%s" % [
					_hud.get_signal_connection_list("parry_performed").size(), str(prod_subscriber)])
	var enc_snap: Dictionary = {}
	if _enc.has_method("get_parry_production_snapshot"):
		enc_snap = _enc.call("get_parry_production_snapshot") as Dictionary
	_ck("P3 A48① 导演层生产装配自报 parry_performed 已订阅 + 唯一实例可用",
			bool(enc_snap.get("parry_signal_connected", false)),
			"connected=%s parry_available=%s" % [
					str(enc_snap.get("parry_signal_connected", "?")),
					str(enc_snap.get("parry_available", "?"))])
	var sigs: Array[String] = ["execution_performed", "boon_draft_selected", "points_awarded",
			"boon_draft_applied", "production_wave_modifier", "parry_performed"]
	var miss: Array[String] = []
	for s: String in sigs:
		if not _hud.has_signal(s):
			miss.append(s)
	var methods: Array[String] = ["process_key_event", "request_parry", "get_parry_hud_view",
			"get_parry_attempt_log", "bind_parry_service", "poll_parry_service",
			"tick_parry", "get_parry_telegraph_rect", "get_stagger_hud_view"]
	var mmiss: Array[String] = []
	for m: String in methods:
		if not _hud.has_method(m):
			mmiss.append(m)
	_ck("P4 HUD 既有 5 信号 + R35 parry_performed 齐全，关键公开 / 钩子方法可寻址",
			miss.is_empty() and mmiss.is_empty(),
			"missing_sigs=%s missing_methods=%s" % [str(miss), str(mmiss)])
	var text: String = FileAccess.get_file_as_string(COURTYARD_PATH)
	var count: int = 0
	for line: String in text.split("\n"):
		if line.begins_with("[node "):
			count += 1
	var uv_2x: int = text.count("Vector3(2, 2, 1)")
	var uv_1x: int = text.count("Vector3(1, 1, 1)")
	_ck("P5 A38 courtyard.tscn 节点 41 / uv 2/1/1 原样（只读不改）",
			count == NODE_COUNT_EXPECTED and uv_2x == 1 and uv_1x == 2,
			"count=%d uv_2x=%d uv_1x=%d" % [count, uv_2x, uv_1x])


# ---------------------------------------------------------------------------
# W) 窗口 / 真实 K 输入 / 幂等 / 冷却 / 超时 / A58 唯一 window_id
# ---------------------------------------------------------------------------
func _t_w_window_and_input() -> void:
	print("[V120P] ==== W 组：真实 K 输入 → 窗口内成功 / 窗口外拒绝 / 幂等 / 冷却 / 唯一 window_id ====")
	if _hud.has_method("close_boon_draft"):
		_hud.call("close_boon_draft")     # 状态隔离：抉择卡片打开会拦截 K
	_hud.set("shop_open", false)
	if _hud.has_method("set_codex_open"):
		_hud.call("set_codex_open", false)

	# ---- W1 开窗 → 金色预兆 + 读秒（真实可见节点 / 画面）----
	_open_window()
	var view: Dictionary = _hud.call("get_parry_hud_view") as Dictionary
	var telegraph: String = String(view.get("telegraph_text", ""))
	var label: Label = _hud.get("_r35_parry_label") as Label
	var label_ok: bool = label != null and is_instance_valid(label)
	if _hud.has_method("_r34_refresh_visible"):
		_hud.call("_r34_refresh_visible")
	_ck("W1 开窗 → HUD 金色预兆 + 读秒：ProdParryLabel 真实节点可见且文本含「精准弹反 / 按 K」",
			bool(view.get("window_open", false)) and telegraph.contains("精准弹反") \
					and telegraph.contains("按 K") and label_ok and label.visible,
			"open=%s text=[%s] node=%s visible=%s" % [
					str(view.get("window_open", "?")), telegraph, str(label_ok),
					str(label.visible) if label_ok else "?"])
	var gold_ok: bool = false
	if label_ok and label.has_theme_color_override("font_color"):
		var col: Color = label.get_theme_color("font_color")
		gold_ok = col.r > 0.9 and col.g > 0.7 and col.b < 0.5
	_ck("W1b 金色预兆文字为金色（r>0.9 / g>0.7 / b<0.5）",
			gold_ok, "gold=%s" % str(gold_ok))

	# ---- W2 窗口内真实 K → 弹反成功 ----
	_parry_log.clear()
	_points_log.clear()
	_press_k()
	var attempt: Dictionary = _last_attempt()
	_ck("W2 ★ 窗口内真实 K 输入（Input.parse_input_event）→ 弹反成功",
			bool(attempt.get("ok", false)) and String(attempt.get("reason", "")) == "ok",
			"attempt=%s parry_source=%s" % [str(attempt), _parry_source])
	var parry_events: int = _parry_log.size()
	var parry_points: Array[Dictionary] = []
	for e: Dictionary in _points_log:
		if String(e.get("reason", "")) == "parry":
			parry_points.append(e)
	_ck("W3 ★ 成功 → parry_performed（带 window_id）+ points_awarded(parry) 各发一次",
			parry_events == 1 and parry_points.size() == 1,
			"parry_performed=%d points_awarded_parry=%d" % [parry_events, parry_points.size()])
	var wid1: String = String(attempt.get("window_id", ""))
	_ck("W4 A58 ★ window_id 非空且为 parry_<wave>_<seq> 格式",
			not wid1.is_empty() and wid1.begins_with("parry_") and wid1.split("_").size() == 3,
			"wid=%s signal_wid=%s" % [wid1,
					String((_parry_log[0] as Dictionary).get("window_id", "")) if parry_events == 1 else "?"])

	# ---- W5 重复按键幂等（同窗口再按 K 不重复结算）----
	var pts_after_1: int = parry_points.size()
	var parry_ev_after_1: int = _parry_log.size()
	_press_k()
	var attempt2: Dictionary = _last_attempt()
	var reason2: String = String(attempt2.get("reason", ""))
	_ck("W5 ★ 窗口内重复按 K 幂等：不重复发 parry_performed / points_awarded（服务成功后关窗→window_closed / HUD consumed→already_parried）",
			(not bool(attempt2.get("ok", true))) \
					and (reason2 == "already_parried" or reason2 == "window_closed") \
					and _parry_log.size() == parry_ev_after_1 and parry_points.size() == pts_after_1,
			"attempt2=%s parry_signals=%d->%d（不重复结算）" % [
					str(attempt2), parry_ev_after_1, _parry_log.size()])

	# ---- W6 窗口外拒绝 ----
	_advance(2.0)   # 推进到窗口超时 + 冷却结束
	var view_closed: Dictionary = _hud.call("get_parry_hud_view") as Dictionary
	_press_k()
	var attempt3: Dictionary = _last_attempt()
	_ck("W6 ★ 窗口外按 K 拒绝（window_closed，失败按既有正常受击结算、不改伤害判定）",
			(not bool(view_closed.get("window_open", true))) \
					and (not bool(attempt3.get("ok", true))) \
					and String(attempt3.get("reason", "")) == "window_closed",
			"window_open=%s attempt=%s" % [str(view_closed.get("window_open", "?")), str(attempt3)])

	# ---- W7 冷却期拒绝 ----
	_open_window()
	_press_k()
	var cd_attempt: Dictionary = _last_attempt()
	_ck("W7a 第 2 个窗口内真实 K → 第 2 次弹反成功（冷却已由上一轮 _advance 清掉）",
			bool(cd_attempt.get("ok", false)), "attempt=%s" % str(cd_attempt))
	var wid2: String = String(cd_attempt.get("window_id", ""))
	_ck("W7b A58 ★ 两次窗口 window_id 不合并（非空、互不相同、随 parry_performed 带出）",
			not wid2.is_empty() and wid1 != wid2,
			"wid1=%s wid2=%s parry_log=%s" % [wid1, wid2, str(_parry_log)])
	# 立刻再开第 3 个窗口（此时 cooldown>0）→ 权威服务在冷却期拒绝开窗，
	# HUD 侧窗口未开或 cooldown 门控命中，按 K 一律不成功、不重复结算。
	var open_res: Dictionary = _open_window()
	var cd_view: Dictionary = _hud.call("get_parry_hud_view") as Dictionary
	_press_k()
	var cd_attempt2: Dictionary = _last_attempt()
	var cd_reason: String = String(cd_attempt2.get("reason", ""))
	var svc_rejects: bool = (not bool(open_res.get("ok", true))) \
			and String(open_res.get("reason", "")) == "cooldown"
	_ck("W7c ★ 冷却期按 K 拒绝：Rank-2 服务 cooldown_remaining>0（服务拒绝开窗或 HUD cooldown 门控）+ 不重复结算",
			float(cd_view.get("cooldown_sec", 0.0)) > 0.0 \
					and (not bool(cd_attempt2.get("ok", true))) \
					and (svc_rejects or cd_reason == "cooldown") \
					and (cd_reason == "cooldown" or cd_reason == "window_closed"),
			"cooldown=%.2f open_res=%s attempt=%s（冷却期拒绝，不重复结算）" % [
					float(cd_view.get("cooldown_sec", 0.0)), str(open_res), str(cd_attempt2)])

	# ---- W8 超时自动关窗 ----
	_advance(3.0)
	var view_timeout: Dictionary = _hud.call("get_parry_hud_view") as Dictionary
	_ck("W8 可弹反窗口超时自动关闭（读秒归零、预兆消失）",
			(not bool(view_timeout.get("window_open", true))) \
					and float(view_timeout.get("remaining_sec", 99.0)) <= 0.001,
			"open=%s remaining=%.2f" % [
					str(view_timeout.get("window_open", "?")),
					float(view_timeout.get("remaining_sec", -1.0))])


# ---------------------------------------------------------------------------
# C) 真实输入 → 生产链路 → 磁盘 / 画面 + A58 exe: 去重键不合并
# ---------------------------------------------------------------------------
func _t_c_production_chain() -> void:
	print("[V120P] ==== C 组：真实输入 → 生产链路 → 磁盘 / 画面 ====")
	# C1 parry_performed 生产订阅者 → EncounterDirector 真实削韧
	var enc_snap: Dictionary = _enc.call("get_parry_production_snapshot") as Dictionary
	_ck("C1 ★ A48③ 生产链：parry_performed 由 EncounterDirector 真实消费并调用既有 _resolve_poise 削韧",
			(enc_snap.get("parry_events", []) as Array).size() >= 2 \
					and int(enc_snap.get("parry_poise_applied_count", 0)) >= 1,
			"events=%d poise_applied=%d" % [
					(enc_snap.get("parry_events", []) as Array).size(),
					int(enc_snap.get("parry_poise_applied_count", 0))])
	# C2 points_awarded(parry) → 生产编排层落盘（磁盘真值）
	var disk_after: int = _disk_points()
	var st: Dictionary = {}
	if _orch != null and is_instance_valid(_orch):
		st = _orch.call("get_status") as Dictionary
	_ck("C2 ★ A48③ 真实输入 → points_awarded → PointsCommitOrchestrator（生产 autoload）→ 磁盘 grace.trial.points",
			disk_after > 0 and int(st.get("commit_count", 0)) > 0,
			"disk=%d runtime=%s commit_count=%s slot=%s" % [
					disk_after, str(st.get("points", "?")), str(st.get("commit_count", "?")), _slot_dir])
	# 如实登记：Rank-3 编排层 parry: 去重键接线状态（Rank-1 已带出非空唯一 window_id，
	#   points_commit_orchestrator.gd 归 Rank-3 唯一写入，本轮不擅改）。
	var claimed_arr: Array = st.get("claimed", []) as Array
	var parry_keys: Array[String] = []
	for k in claimed_arr:
		if String(k).begins_with("parry:"):
			parry_keys.append(String(k))
	if parry_keys.is_empty():
		print("[V120P] [如实登记] Rank-3 编排层本轮尚未订阅 parry_performed 生成 parry:<window_id> 去重键 → 第 2 次弹反 points_awarded 被 auto 指纹去重拒绝（Rank-1 已随 parry_performed 带出非空唯一 window_id；parry: 键接线待 Rank-3 / 总指挥裁决） | claimed=%s" % str(claimed_arr))
	else:
		print("[V120P] Rank-3 parry: 去重键已接线 | keys=%s" % str(parry_keys))
	# C3 A57 倍率后值口径：弹反点数 = 基础 × 有效连击倍率（≥ 基础值）
	var parry_pts: int = -1
	for e: Dictionary in _points_log:
		if String(e.get("reason", "")) == "parry":
			parry_pts = int(e.get("points", -1))
	var base_pts: int = 0
	if _parry != null and is_instance_valid(_parry) and _parry.has_method("get_snapshot"):
		base_pts = int((_parry.call("get_snapshot") as Dictionary).get("points_bonus", 0))
	_ck("C3 A57 口径：points_awarded(parry).points 为倍率后最终值（≥ 基础 points_bonus，无有效倍率则回落基础值）",
			parry_pts >= base_pts and parry_pts > 0,
			"points_awarded=%d base=%d" % [parry_pts, base_pts])
	# C4 生产 slot_01 不污染
	_ck("C4 生产 slot_01 md5 前后一致（全程不写 slot_01）",
			_prod_md5() == _prod_md5_before, "md5=%s" % _prod_md5_before)
	# C5 A58 处决：两次窗口生成两个非空唯一 exe id，编排层 exe: 去重键不合并
	_exec_log.clear()
	_hud.call("close_boon_draft")
	_hud.call("_open_execution_window", 1.0, 50)
	var r1: Dictionary = _hud.call("request_execution") as Dictionary
	_hud.call("_open_execution_window", 1.0, 50)
	var r2: Dictionary = _hud.call("request_execution") as Dictionary
	var exe1: String = ""
	var exe2: String = ""
	if _exec_log.size() >= 1:
		exe1 = String((_exec_log[0] as Dictionary).get("window_id", ""))
	if _exec_log.size() >= 2:
		exe2 = String((_exec_log[1] as Dictionary).get("window_id", ""))
	_ck("C5a A58 ★ 两次处决窗口 window_id 非空且唯一（exe_<wave>_<seq>，不再空串）",
			bool(r1.get("ok", false)) and bool(r2.get("ok", false)) \
					and not exe1.is_empty() and not exe2.is_empty() and exe1 != exe2 \
					and exe1.begins_with("exe_") and exe2.begins_with("exe_"),
			"exe1=%s exe2=%s exec_log=%s" % [exe1, exe2, str(_exec_log)])
	var claimed: Array = []
	if _orch != null and is_instance_valid(_orch):
		claimed = (_orch.call("get_status") as Dictionary).get("claimed", []) as Array
	var k1: String = "exe:" + exe1
	var k2: String = "exe:" + exe2
	_ck("C5b A58 ★ Rank-3 编排层 exe: 去重键不再合并不同窗口（claimed 含两个不同 exe 键）",
			claimed.has(k1) and claimed.has(k2) and k1 != k2,
			"k1=%s k2=%s claimed=%s" % [k1, k2, str(claimed)])
	# C6 源码零写盘（Rank-1 只发信号，A50）
	var hud_src: String = FileAccess.get_file_as_string("res://scripts/hud.gd")
	var enc_src: String = FileAccess.get_file_as_string("res://scripts/combat/encounter_director.gd")
	var hud_r35: String = hud_src.substr(hud_src.find("# 17) R35 [ROUND=R35]"))
	var enc_r35: String = enc_src.substr(enc_src.find("# R35 [ROUND=R35]"))
	var no_write: bool = (not hud_r35.contains("FileAccess.open") and not enc_r35.contains("FileAccess.open")) \
			and (not hud_r35.contains(".call(\"set_flag\"") and not enc_r35.contains(".call(\"set_flag\"")) \
			and (not hud_r35.contains(".call(\"commit\"") and not enc_r35.contains(".call(\"commit\""))
	_ck("C6 A50：Rank-1 R35 追加段源码零写盘（无 set_flag / commit / FileAccess 写盘点）",
			hud_r35.length() > 0 and enc_r35.length() > 0 and no_write,
			"hud_r35_len=%d enc_r35_len=%d no_write=%s" % [
					hud_r35.length(), enc_r35.length(), str(no_write)])


# ---------------------------------------------------------------------------
# A65 [ROUND=R36 / HOST 裁决] · 弹反窗口内成功免伤（既有 27 条断言逐字不删不放宽）
#   窗口内成功弹反 → 免除【该次】Boss 招式伤害（玩家 HP 不变）+ HUD「弹反·免伤」反馈；
#   窗口外 / 超时（guard=false）→ 既有正常扣血路径，不改其它伤害路径。
#   真实输入：_press_k()（Input.parse_input_event + process_key_event，与 _unhandled_input 同路径）。
# ---------------------------------------------------------------------------
func _t_a65_parry_negate() -> void:
	print("[V120P] ==== A65 组：弹反成功免伤 / 窗口外·超时正常扣血 ====")
	if _hud == null or _enc == null:
		_ck("A65-0 关键节点可用", false, "hud/enc null")
		return
	# 状态隔离（同 W 组口径）
	if _hud.has_method("close_boon_draft"):
		_hud.call("close_boon_draft")
	_hud.set("shop_open", false)
	if _hud.has_method("set_codex_open"):
		_hud.call("set_codex_open", false)
	_advance(3.0)
	# 消费 W/C 组可能残留的 parry_guard，确保干净起点（消费后 guard=false）。
	var guard_clean: bool = false
	for _i: int in range(5):
		var gs: Dictionary = _enc.call("get_parry_production_snapshot") as Dictionary
		if not bool(gs.get("parry_guard", false)):
			guard_clean = true
			break
		_enc.call("debug_boss_hit")       # 消费残留 guard（若该次免伤，HP 不变，不影响后续基线）
	_ck("A65-0 起点干净：parry_guard 已复位为 false（窗口外 / 超时态）",
			guard_clean, "guard_clean=%s" % str(guard_clean))

	# ---- A65-1 ★ 窗口外 / 超时 → 正常扣血 ----
	var hp0: float = float((_enc.call("get_snapshot") as Dictionary).get("player_hp", -1.0))
	var neg0: int = int((_enc.call("get_focus_production_snapshot") as Dictionary).get("parry_negate_count", 0))
	_enc.call("debug_boss_hit")
	var hp1: float = float((_enc.call("get_snapshot") as Dictionary).get("player_hp", -1.0))
	var neg1: int = int((_enc.call("get_focus_production_snapshot") as Dictionary).get("parry_negate_count", 0))
	_ck("A65-1 ★ 窗口外 / 超时（guard=false）→ Boss 招式正常扣血（player_hp 下降）、不发免伤",
			hp1 < hp0 and neg1 == neg0,
			"hp %.1f -> %.1f negate_count %d -> %d" % [hp0, hp1, neg0, neg1])

	# ---- A65-2 ★ 窗口内成功弹反 → 该次免伤（HP 不变）----
	_advance(3.0)                          # 清冷却，保证可开窗
	_open_window()
	_press_k()                             # 真实 K 成功 → parry_performed → ENC parry_guard=true
	var attempt: Dictionary = _last_attempt()
	var guard2: bool = bool((_enc.call("get_parry_production_snapshot") as Dictionary).get("parry_guard", false))
	var hp2: float = float((_enc.call("get_snapshot") as Dictionary).get("player_hp", -1.0))
	var neg2: int = int((_enc.call("get_focus_production_snapshot") as Dictionary).get("parry_negate_count", 0))
	_enc.call("debug_boss_hit")            # 该次招式落地 → 消费 guard → A65 免伤
	var hp3: float = float((_enc.call("get_snapshot") as Dictionary).get("player_hp", -1.0))
	var neg3: int = int((_enc.call("get_focus_production_snapshot") as Dictionary).get("parry_negate_count", 0))
	var fv: Dictionary = _hud.call("get_focus_hud_view") as Dictionary
	_ck("A65-2 ★ 窗口内真实 K 成功弹反 → 免除该次 Boss 招式伤害：玩家 HP 不变、negate_count +1、HUD「弹反·免伤」",
			bool(attempt.get("ok", false)) and guard2 and hp3 == hp2 \
					and neg3 == neg2 + 1 \
					and String(fv.get("parry_negate_text", "")) == "弹反·免伤",
			"attempt_ok=%s guard=%s hp %.1f -> %.1f negate %d -> %d hint=[%s]" % [
					str(attempt.get("ok", "?")), str(guard2), hp2, hp3, neg2, neg3,
					str(fv.get("parry_negate_text", "?"))])

	# ---- A65-3 ★ 免伤只作用本次窗口：guard 一次性消费后，下一次招式正常扣血 ----
	_enc.call("debug_boss_hit")
	var hp4: float = float((_enc.call("get_snapshot") as Dictionary).get("player_hp", -1.0))
	var neg4: int = int((_enc.call("get_focus_production_snapshot") as Dictionary).get("parry_negate_count", 0))
	_ck("A65-3 ★ A65 免伤只作用本次窗口（guard 一次性消费）：下一次 Boss 招式正常扣血、不重复免伤",
			hp4 < hp3 and neg4 == neg3,
			"hp %.1f -> %.1f negate_count %d -> %d" % [hp3, hp4, neg3, neg4])


func _finish(early: bool) -> void:
	if _orch != null and is_instance_valid(_orch) and _orch.has_method("_release"):
		_orch.call("_release")
	if _probes_connected and _hud != null and is_instance_valid(_hud):
		var pairs: Dictionary = {
			"parry_performed": "_on_parry", "points_awarded": "_on_points",
			"execution_performed": "_on_exec"}
		for sig: String in pairs.keys():
			var cb: Callable = Callable(self, String(pairs[sig]))
			if _hud.has_signal(sig) and _hud.is_connected(sig, cb):
				_hud.disconnect(sig, cb)
	var ok: bool = (not early) and _fail == 0 and _pass > 0
	print("[V120P] ---- 回读汇总 ----")
	print("[V120P] SUMMARY pass=%d fail=%d total=%d ok=%s parry_source=%s" % [
			_pass, _fail, _pass + _fail, str(ok), _parry_source])
	if ok:
		print("[V120P] RESULT=ALL_MATCH")
	else:
		print("[V120P] RESULT=MISMATCH")
	print("[V120P] ==== verify_parry_runtime_v120 真跑结束 ====")
	quit(0 if ok else 1)
