extends SceneTree
## ===========================================================================
## R36 [ROUND=R36] · v0.13.0 专注值 FP / 战技 Q【真实可达回归】（Rank-1 唯一写入方）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/render/verify_focus_runtime_v130.gd
##
## A49 / A48③ 口径：【不加载 presentation.gd】、【不在验证脚本内模拟编排】。
##   本脚本自行 instantiate 主场景 courtyard.tscn（CACHE_MODE_IGNORE），
##   显式 _ready() / _r34_bootstrap() 完成生产装配后，注入【真实 Q 输入】
##   （Input.parse_input_event + HUD.process_key_event，与 _unhandled_input 同一 R32 键路径），
##   断言「真实输入 → 生产链路 → 磁盘 / 画面」确实发生：
##     · 真实输入：真实 Q 键注入，走 HUD 单一仲裁者 → request_focus_skill 权威判定；
##     · 生产链路：A54 唯一 Rank-2 FocusService.spend_fp() 真实判定扣 FP →
##       focus_skill_performed（Rank-1 信号，生产订阅者 EncounterDirector 真实削韧 / 伤害）→
##       focus_spent（Rank-2 信号，生产订阅者 wave_trial_director 真实累计清波基数 / 削韧）；
##     · 画面：专注值 FP 条真实可见节点 ProdFocusLabel 文本随 FP 变化。
##   全程复用【生产唯一实例】，纯逻辑 / 契约替身不算可玩交付（A48④）。
##
## A54：focus_service 唯一实例从 wave_trial_director.get_focus_service() 复用，绝不自建；
##   本验证进程直接复用该真实实例（Rank-2 R36 已落盘），HUD / ENC / wave 三方同一 Object。
##   仅当真实实例不可用（并发时序尚未落盘）才降级 FakeFocus 契约替身并如实登记，
##   口径同 R35 FakeParry 先例，不冒充已联调。
##
## 断言组：
##   F 装配：A38 节点 41 uv 2/1/1 / 新信号 / 关键方法 / A54 唯一实例（真实 FocusService）/
##           A48① 生产运行时订阅者 / FP 条真实可见节点 / 不加载 presentation.gd
##   Q 真实 Q 输入 → FP 扣减 / A57 倍率后值 / 生产链路真实消费（Rank-1 + Rank-2 双方订阅者）/ 画面节点变化
##   R 边界：专注不足拒绝（不扣 FP）/ 冷却拒绝（不扣 FP）/ 重复按键幂等 /
##           赐福休息回满（真实 grace_rested 链路）/ 异常输入不崩
##   A65 HUD「弹反·免伤」反馈生产订阅者（免伤主断言在 verify_parry_runtime_v120.gd）
##
## --script / SceneTree 纪律：用 Engine.get_main_loop() as SceneTree 取 root，
##   不用 get_tree() / 不用 /root/... 绝对路径；add_child 不自动 flush _ready() →
##   显式 call("_ready")；资源 CACHE_MODE_IGNORE；connect 前 get_signal_connection_list
##   去重、_finish() 有 disconnect / 释放路径；project.godot 已有的
##   PointsCommitOrchestrator autoload 直接复用，不重复挂载。
## 输出：逐条 PASS/FAIL + SUMMARY + RESULT=ALL_MATCH（全通过）/ MISMATCH。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。
## ===========================================================================

const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"
const NODE_COUNT_EXPECTED: int = 41
const REL_HUD: String = "SubViewportContainer/SubViewport/FXLayer/Hud"
const REL_ENC: String = "EncounterRoot"
const REL_WAVE: String = "WaveTrialDirector"
const REL_PROD_LAYER: String = "ProductionMechanismsLayer"
const FOCUS_LABEL_NAME: String = "ProdFocusLabel"
const KEY_Q: int = 81
const KEY_J: int = 74
# R36B [ROUND=R36B] · 战技切换 R（HOST 裁决 A69，物理键码 82；不与 J/Q/F/K/Tab 冲突）
const KEY_R: int = 82
const ART_LABEL_NAME: String = "ProdArtLabel"

## 降级契约替身：仅当 Rank-2 真实 FocusService 未落盘时启用。镜像真实公开接口
## （spend_fp / get_snapshot / on_grace_rest / tick / reset / get_* 只读），使本验证的
## 鸭子类型 helper 对真实实例与降级替身通用；[验证替身] 数值不写任何 .tres / .gd。
class FakeFocus extends RefCounted:
	var _fp: float = 100.0
	var _fp_max: float = 100.0
	var _cd: float = 0.0
	var _cost: float = 12.0
	var _damage: float = 18.0
	var _poise: float = 8.0
	var _spend_count: int = 0
	var _reject_count: int = 0
	var _restore_count: int = 0
	var _last: Dictionary = {}
	var _last_reject: String = ""

	func spend_fp(_art_id: Variant) -> Dictionary:
		if _cd > 0.0:
			return _reject("cooldown")
		if _fp < _cost:
			return _reject("insufficient_fp")
		_fp -= _cost
		_cd = 0.6
		_spend_count += 1
		_last = {"ok": true, "reason": "ok", "art_id": "glintstone_pebble",
				"fp_cost": _cost, "damage": _damage, "poise_damage": _poise,
				"fp_remaining": _fp, "cooldown_remaining": _cd, "spend_count": _spend_count}
		return _last.duplicate()

	func _reject(reason: String) -> Dictionary:
		_reject_count += 1
		_last_reject = reason
		return {"ok": false, "reason": reason, "fp_remaining": _fp,
				"cooldown_remaining": _cd, "spend_count": _spend_count}

	func get_snapshot() -> Dictionary:
		return {"fp": _fp, "fp_max": _fp_max, "fp_remaining": _fp,
				"spend_count": _spend_count, "reject_count": _reject_count,
				"restore_count": _restore_count, "last_result": _last.duplicate(),
				"last_reject_reason": _last_reject}

	func get_art_ids() -> PackedStringArray:
		return PackedStringArray(["glintstone_pebble"])

	func get_fp() -> float: return _fp
	func get_fp_max() -> float: return _fp_max
	func get_spend_count() -> int: return _spend_count
	func get_reject_count() -> int: return _reject_count
	func get_restore_count() -> int: return _restore_count
	func get_last_result() -> Dictionary: return _last.duplicate()
	func get_last_reject_reason() -> String: return _last_reject

	func tick(d: Variant) -> void:
		if _cd > 0.0 and typeof(d) == TYPE_FLOAT or typeof(d) == TYPE_INT:
			_cd = maxf(0.0, _cd - float(d))

	func on_grace_rest() -> Dictionary:
		var before := _fp
		_fp = _fp_max
		_cd = 0.0
		_restore_count += 1
		return {"ok": true, "fp_before": before, "fp_after": _fp, "policy": "rest_refill"}

	func reset() -> void:
		_fp = _fp_max
		_cd = 0.0
		_spend_count = 0
		_reject_count = 0
		_restore_count = 0
		_last = {}
		_last_reject = ""


var _pass: int = 0
var _fail: int = 0
var _tree: SceneTree = null
var _courtyard: Node = null
var _hud: Node = null
var _enc: Node = null
var _wave: Node = null
var _focus: Object = null              # A54 唯一实例（真实 FocusService / 降级 FakeFocus）
var _focus_source: String = "none"
var _is_real_service: bool = false

# 探针信号回读（只读统计，不写任何状态）
var _performed_log: Array[Dictionary] = []
var _rejected_log: Array[Dictionary] = []
var _negated_log: Array[Dictionary] = []
var _spent_log: Array[Dictionary] = []
var _probes_connected: bool = false


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V130] %s PASS=%s | %s" % [tag, str(ok), detail])


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


## 递归检查场景树是否存在挂载指定脚本（resource_path 含 keyword）的节点（运行时事实，非探针脚本）。
func _tree_has_script(n: Node, keyword: String) -> bool:
	var scr: Script = n.get_script() as Script
	if scr != null and scr.resource_path.contains(keyword):
		return true
	for c: Node in n.get_children():
		if _tree_has_script(c, keyword):
			return true
	return false


func _on_performed(skill_id: String, fp_before: int, fp_after: int, fp_cost: int,
		damage: int, poise: float, multiplier: float) -> void:
	_performed_log.append({"skill_id": skill_id, "fp_before": fp_before,
			"fp_after": fp_after, "fp_cost": fp_cost, "damage": damage,
			"poise": poise, "multiplier": multiplier})


func _on_rejected(reason: String, fp: int, fp_max: int) -> void:
	_rejected_log.append({"reason": reason, "fp": fp, "fp_max": fp_max})


func _on_negated(window_id: String) -> void:
	_negated_log.append({"window_id": window_id})


func _on_spent(art_id: String, fp_cost: float, damage: float, poise_damage: float, fp_remaining: float) -> void:
	_spent_log.append({"art_id": art_id, "fp_cost": fp_cost, "damage": damage,
			"poise_damage": poise_damage, "fp_remaining": fp_remaining})


func _initialize() -> void:
	print("[V130] ==== verify_focus_runtime_v130 真跑开始 | R36 v0.13.0 Rank-1 ====")
	print("[V130] A49/A48③：不加载 presentation.gd；不模拟编排；真实 Q 输入 → 生产链路 → 磁盘/画面")
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null:
		print("[V130] RESULT=MISMATCH（Engine.get_main_loop() 非 SceneTree）")
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
	_bind_focus_service()
	_bind_probes()
	_t_f_assembly()
	_t_q_real_input()
	_t_r_boundaries()
	_t_a65_hud_feedback()
	_t_s_art_switch()          # R36B：R 切换 / 两战技按表生效 / Q 释放当前选中 / 不误触 / 不重置 / 包围盒
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
	print("[V130] 主场景已实例化入树 | name=%s（未加载 presentation.gd）" % str(_courtyard.name))


func _resolve_nodes() -> void:
	_hud = _courtyard.get_node_or_null(NodePath(REL_HUD))
	_enc = _courtyard.get_node_or_null(NodePath(REL_ENC))
	_wave = _courtyard.get_node_or_null(NodePath(REL_WAVE))
	_ck("F0 主场景关键节点可寻址（EncounterRoot / Hud / WaveTrialDirector）",
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
		_enc.call("_r34_bootstrap")     # 内部末尾触发 _r35_bootstrap + _r36_bootstrap（生产订阅者）
	if _hud.has_method("_r34_bootstrap"):
		_hud.call("_r34_bootstrap")     # 内部末尾触发 _r36_bootstrap（A54 复用 + A65 反馈订阅）
	print("[V130] 显式 _r34_bootstrap() 完成（R36 生产订阅者已装配）")


## A54：直接复用 wave_trial_director.get_focus_service() 唯一【真实实例】，注入 HUD 与
## ENC 同一个 Object（生产 _r36_bootstrap 已各自复用，此处显式对齐三方同一实例，绝不自建）。
## 真实实例不可用（并发时序未落盘）→ FakeFocus 契约替身降级并如实登记（R35 FakeParry 先例）。
func _bind_focus_service() -> void:
	var real: Object = null
	if _wave != null and _wave.has_method("get_focus_service"):
		real = _wave.call("get_focus_service") as Object
	if real != null and is_instance_valid(real) \
			and real.has_method("spend_fp") and real.has_method("get_snapshot"):
		_focus = real
		_focus_source = "rank2_production_unique_instance"
		_is_real_service = true
		print("[V130] A54 ★ 复用 wave.get_focus_service() 真实唯一实例（Rank-2 FocusService 已落盘）→ 走真实判定，不冒充联调")
	else:
		_focus = FakeFocus.new()
		_focus_source = "fake_contract_rank2_not_landed"
		_is_real_service = false
		print("[V130] [如实登记] Rank-2 FocusService 真实实例不可用 → 降级 FakeFocus 契约替身仅验证 Rank-1 生产接线链；真实判定待落盘联调，不冒充")
	if _hud != null and _hud.has_method("bind_focus_service"):
		_hud.call("bind_focus_service", _focus)
	if _enc != null and _enc.has_method("bind_focus_service"):
		_enc.call("bind_focus_service", _focus)


func _bind_probes() -> void:
	if _hud == null or _enc == null:
		return
	_probes_connected = true
	_dedup_connect(_hud, "focus_skill_performed", "_on_performed")
	_dedup_connect(_hud, "focus_skill_rejected", "_on_rejected")
	_dedup_connect(_enc, "parry_damage_negated", "_on_negated")
	if _focus != null:
		_dedup_connect(_focus, "focus_spent", "_on_spent")


# ---- 真实服务鸭子类型只读 helper（对真实 FocusService 与降级 FakeFocus 通用）----
func _svc_fp() -> float:
	if _focus == null:
		return 0.0
	if _focus.has_method("get_fp"):
		return float(_focus.call("get_fp"))
	return float((_focus.call("get_snapshot") as Dictionary).get("fp", 0.0))


func _svc_fp_max() -> float:
	if _focus == null:
		return 0.0
	if _focus.has_method("get_fp_max"):
		return float(_focus.call("get_fp_max"))
	return float((_focus.call("get_snapshot") as Dictionary).get("fp_max", 0.0))


func _svc_spend_count() -> int:
	if _focus == null:
		return -1
	if _focus.has_method("get_spend_count"):
		return int(_focus.call("get_spend_count"))
	return int((_focus.call("get_snapshot") as Dictionary).get("spend_count", -1))


func _svc_last_result() -> Dictionary:
	if _focus == null:
		return {}
	if _focus.has_method("get_last_result"):
		return _focus.call("get_last_result") as Dictionary
	return (_focus.call("get_snapshot") as Dictionary).get("last_result", {}) as Dictionary


func _svc_art_ids() -> Array:
	if _focus == null or not _focus.has_method("get_art_ids"):
		return []
	var ids: Variant = _focus.call("get_art_ids")
	if ids is PackedStringArray:
		var a: Array = []
		for s: String in (ids as PackedStringArray):
			a.append(s)
		return a
	if ids is Array:
		return ids as Array
	return []


func _svc_tick(d: float) -> void:
	if _focus != null and _focus.has_method("tick"):
		_focus.call("tick", d)


func _svc_reset() -> void:
	if _focus != null and _focus.has_method("reset"):
		_focus.call("reset")


## 真实 Q 输入：Input.parse_input_event 注入 + HUD.process_key_event（与 _unhandled_input
## 完全相同的 R32 键处理路径，口径同 V120P._press_k / V110 d 链），松开配对。
func _press_q() -> void:
	var press: InputEventKey = _key(KEY_Q, true)
	Input.parse_input_event(press)
	_hud.call("process_key_event", press)
	var rel: InputEventKey = _key(KEY_Q, false)
	Input.parse_input_event(rel)
	_hud.call("process_key_event", rel)


## 同一 event 实例重复投递（幂等断言用）：不 new 第二个事件对象，验证 ENC + HUD 双接 Q
## 时由 HUD 的 event 实例幂等去重保证只结算一次。
func _press_q_same_event_twice(ev: InputEventKey) -> void:
	Input.parse_input_event(ev)
	_hud.call("process_key_event", ev)
	_hud.call("process_key_event", ev)


func _focus_view() -> Dictionary:
	if _hud == null or not _hud.has_method("get_focus_hud_view"):
		return {}
	return _hud.call("get_focus_hud_view") as Dictionary


func _prod_snapshot() -> Dictionary:
	if _enc == null or not _enc.has_method("get_focus_production_snapshot"):
		return {}
	return _enc.call("get_focus_production_snapshot") as Dictionary


# ---------------------------------------------------------------------------
# F) 装配 / A38 / A54 / A48① / FP 条真实节点
# ---------------------------------------------------------------------------
func _t_f_assembly() -> void:
	var sigs: Array[String] = ["focus_skill_performed", "focus_skill_rejected"]
	var miss: Array[String] = []
	for s: String in sigs:
		if _hud == null or not _hud.has_signal(s):
			miss.append(s)
	_ck("F1 HUD 新增 focus_skill_performed / focus_skill_rejected 信号齐全",
			miss.is_empty(), "missing=%s" % str(miss))
	_ck("F1b ENC 新增 parry_damage_negated 信号（A65）存在",
			_enc != null and _enc.has_signal("parry_damage_negated"),
			"has=%s" % str(_enc != null and _enc.has_signal("parry_damage_negated")))
	var methods: Array[String] = ["request_focus_skill", "get_focus_hud_view",
			"get_focus_attempt_log", "bind_focus_service", "get_focus_service",
			"poll_focus_service", "tick_focus", "get_focus_rect",
			"process_key_event", "_r36_refresh_focus"]
	var mmiss: Array[String] = []
	for m: String in methods:
		if _hud == null or not _hud.has_method(m):
			mmiss.append(m)
	_ck("F2 HUD R36 关键公开 / 钩子方法可寻址",
			mmiss.is_empty(), "missing=%s" % str(mmiss))
	var emethods: Array[String] = ["get_focus_service", "get_focus_production_snapshot",
			"bind_focus_service", "_r36_request_focus_skill"]
	var emiss: Array[String] = []
	for m2: String in emethods:
		if _enc == null or not _enc.has_method(m2):
			emiss.append(m2)
	_ck("F2b ENC R36 关键方法可寻址",
			emiss.is_empty(), "missing=%s" % str(emiss))
	# F3 A54 唯一实例：HUD / ENC / wave 三方同一【真实】Object
	var hud_focus: Object = _hud.call("get_focus_service") as Object
	var enc_focus: Object = _enc.call("get_focus_service") as Object
	var wave_focus: Object = _wave.call("get_focus_service") as Object if _wave.has_method("get_focus_service") else null
	_ck("F3 A54 ★ HUD / ENC / wave.get_focus_service() 三方同一真实 Object（绝不自建第二实例）",
			_focus != null and hud_focus == _focus and enc_focus == _focus \
					and (_is_real_service and wave_focus == _focus),
			"source=%s same=%s" % [_focus_source,
					str(hud_focus == _focus and enc_focus == _focus and wave_focus == _focus)])
	_ck("F3b ★ A54 走真实 Rank-2 FocusService（spend_fp / get_snapshot / on_grace_rest / 4 信号），非契约替身",
			_is_real_service and _focus != null and _focus.has_method("spend_fp") \
					and _focus.has_method("get_snapshot") and _focus.has_method("on_grace_rest") \
					and _focus.has_signal("focus_spent") and _focus.has_signal("focus_rejected") \
					and _focus.has_signal("focus_restored") and _focus.has_signal("focus_cooldown_ready"),
			"source=%s has_spend_fp=%s" % [_focus_source,
					str(_focus != null and _focus.has_method("spend_fp"))])
	# F4 A48① focus_skill_performed 生产订阅者 = EncounterDirector
	var prod_sub: bool = false
	if _hud != null:
		for conn in _hud.get_signal_connection_list("focus_skill_performed"):
			var c: Callable = conn.get("callable", Callable())
			if c.get_object() == _enc:
				prod_sub = true
	_ck("F4 A48① ★ focus_skill_performed 有【生产运行时订阅者 EncounterDirector】（不只是验证脚本）",
			prod_sub, "subscribers=%d enc_subscribed=%s" % [
					_hud.get_signal_connection_list("focus_skill_performed").size(), str(prod_sub)])
	var rej_sub: bool = false
	if _hud != null:
		for conn2 in _hud.get_signal_connection_list("focus_skill_rejected"):
			var c2: Callable = conn2.get("callable", Callable())
			if c2.get_object() == _enc:
				rej_sub = true
	_ck("F4b A48① focus_skill_rejected 亦有生产订阅者 ENC",
			rej_sub, "enc_subscribed=%s" % str(rej_sub))
	# F4c A48① Rank-2 侧 focus_spent 生产订阅者 = wave_trial_director（非验证脚本）
	var wave_sub: bool = false
	if _focus != null and _focus.has_signal("focus_spent"):
		for conn5 in _focus.get_signal_connection_list("focus_spent"):
			var c5: Callable = conn5.get("callable", Callable())
			if c5.get_object() == _wave:
				wave_sub = true
	_ck("F4c A48① ★ 真实 FocusService.focus_spent 有【生产订阅者 wave_trial_director】（Rank-2 真实结算链）",
			wave_sub, "wave_subscribed=%s" % str(wave_sub))
	# F5 A48① parry_damage_negated 生产订阅者 = HUD
	var neg_sub: bool = false
	if _enc != null:
		for conn3 in _enc.get_signal_connection_list("parry_damage_negated"):
			var c3: Callable = conn3.get("callable", Callable())
			if c3.get_object() == _hud:
				neg_sub = true
	_ck("F5 A48① ★ parry_damage_negated 有【生产运行时订阅者 HUD】（A65 反馈，非验证脚本）",
			neg_sub, "subscribers=%d hud_subscribed=%s" % [
					_enc.get_signal_connection_list("parry_damage_negated").size(), str(neg_sub)])
	# F6 FP 条真实节点 + 独立分区 rect + 常驻可见
	var layer: Node = _courtyard.get_node_or_null(NodePath(REL_PROD_LAYER))
	var fl: Label = layer.get_node_or_null(NodePath(FOCUS_LABEL_NAME)) as Label if layer != null else null
	var fl_ok: bool = fl != null and is_instance_valid(fl)
	if _hud != null and _hud.has_method("_r34_refresh_visible"):
		_hud.call("_r34_refresh_visible")
	_ck("F6 ★ 专注值 FP 条真实节点 ProdFocusLabel 常驻可见且文本含「专注值 FP 当前/上限」",
			fl_ok and fl.visible and fl.text.contains("专注值 FP") and fl.text.contains("/"),
			"node=%s visible=%s text=[%s]" % [str(fl_ok),
					str(fl.visible) if fl_ok else "?", fl.text if fl_ok else ""])
	var frect: Rect2 = _hud.call("get_focus_rect") as Rect2
	_ck("F6b FP 条独立分区 rect 面积 > 0 且真实节点按锚点定位（非硬编码像素堆叠）",
			fl_ok and frect.get_area() > 0.0 and fl.get_global_rect().is_equal_approx(frect),
			"anchor=%s node_rect=%s" % [str(frect), str(fl.get_global_rect()) if fl_ok else "?"])
	# F7 A38
	var text: String = FileAccess.get_file_as_string(COURTYARD_PATH)
	var count: int = 0
	for line: String in text.split("\n"):
		if line.begins_with("[node "):
			count += 1
	var uv_2x: int = text.count("Vector3(2, 2, 1)")
	var uv_1x: int = text.count("Vector3(1, 1, 1)")
	_ck("F7 A38 courtyard.tscn 节点 41 / uv 2/1/1 原样（只读不改）",
			count == NODE_COUNT_EXPECTED and uv_2x == 1 and uv_1x == 2,
			"count=%d uv_2x=%d uv_1x=%d" % [count, uv_2x, uv_1x])
	# F8 运行时事实口径：本进程 root 下【不存在】挂载 presentation 脚本的节点，
	#   且唯一主场景 courtyard.tscn 由本脚本自行 instantiate（--script 入口是本验证脚本本身）。
	#   用运行时树检查而非自指的源码字符串 contains，避免把断言自身的字面量算作「加载」。
	var has_presentation_node: bool = _tree_has_script(_tree.root, "presentation.gd")
	_ck("F8 A49 ★ 本验证进程不加载 presentation.gd（场景树零 presentation 脚本节点、主场景自行 instantiate）",
			(not has_presentation_node) and _courtyard != null \
					and _courtyard.get_script() == null,
			"has_presentation_node=%s main_scene_instantiated=%s" % [
					str(has_presentation_node), str(_courtyard != null)])


# ---------------------------------------------------------------------------
# Q) 真实 Q 输入 → FP 扣减 → A57 倍率后值 → 生产链路 → 画面
# ---------------------------------------------------------------------------
func _t_q_real_input() -> void:
	print("[V130] ==== Q 组：真实 Q 输入 → 生产链路 → 画面 ====")
	if _hud == null or _enc == null or _wave == null or _focus == null:
		_ck("Q0 关键节点 / 服务可用", false, "hud/enc/wave/focus null")
		return
	# 干净基线：真实服务 reset()（新局 FP 回满）+ 关掉可能拦截 Q 的抉择卡片 / 商店
	_svc_reset()
	if _hud.has_method("close_boon_draft"):
		_hud.call("close_boon_draft")
	_hud.set("shop_open", false)
	if _hud.has_method("set_codex_open"):
		_hud.call("set_codex_open", false)
	_hud.call("poll_focus_service")
	_performed_log.clear()
	_rejected_log.clear()
	_spent_log.clear()
	var fp_before: float = _svc_fp()
	var spend_before: int = _svc_spend_count()
	var layer: Node = _courtyard.get_node_or_null(NodePath(REL_PROD_LAYER))
	var fl: Label = layer.get_node_or_null(NodePath(FOCUS_LABEL_NAME)) as Label if layer != null else null
	var text_before: String = fl.text if fl != null else ""

	# ---- Q1 真实 Q 输入 → 战技成功 ----
	_press_q()
	var log: Array[Dictionary] = _hud.call("get_focus_attempt_log") as Array[Dictionary]
	var last: Dictionary = log[log.size() - 1] if not log.is_empty() else {}
	_ck("Q1 ★ 真实 Q 输入 → 战技成功（权威 spend_fp 判定 ok=true）",
			bool(last.get("ok", false)) and _performed_log.size() == 1,
			"attempt=%s performed=%d source=%s" % [str(last), _performed_log.size(), _focus_source])

	# ---- Q2 FP 真实扣减（真实服务权威态 + HUD 视图同步）----
	var last_result: Dictionary = _svc_last_result()
	var cost: float = float(last_result.get("fp_cost", 0.0))
	_ck("Q2 ★ 真实 Q → FP 扣减：服务 fp %.1f -> %.1f（扣 fp_cost=%.1f），spend_count +1，HUD 视图同步" % [fp_before, _svc_fp(), cost],
			_svc_fp() < fp_before and _svc_spend_count() == spend_before + 1 \
					and absf(_svc_fp() - (fp_before - cost)) < 0.01 \
					and int(_focus_view().get("fp", -1)) == int(_svc_fp()),
			"fp %.1f -> %.1f spend %d -> %d hud_fp=%s" % [fp_before, _svc_fp(),
					spend_before, _svc_spend_count(), str(_focus_view().get("fp", "?"))])

	# ---- Q3 A48③ 画面：FP 条真实节点文本随真实输入变化 ----
	if _hud.has_method("_r34_refresh_visible"):
		_hud.call("_r34_refresh_visible")
	var text_after: String = fl.text if fl != null else ""
	_ck("Q3 ★ A48③ 画面确实发生：ProdFocusLabel 真实可见节点文本随真实 Q 由「%.0f」变为「%.0f」" % [fp_before, _svc_fp()],
			fl != null and fl.visible and text_after != text_before \
					and text_after.contains("%d/%d" % [int(_svc_fp()), int(_svc_fp_max())]),
			"before=[%s] after=[%s] visible=%s" % [text_before, text_after,
					str(fl.visible) if fl != null else "?"])

	# ---- Q4 A48③ 生产链路：Rank-1（ENC）+ Rank-2（wave）双方生产订阅者真实消费 ----
	var esnap: Dictionary = _prod_snapshot()
	var events: Array = esnap.get("skill_events", []) as Array
	var ws: Dictionary = _wave.call("get_settlement_snapshot") as Dictionary if _wave.has_method("get_settlement_snapshot") else {}
	_ck("Q4 ★ A48③ 生产链路：focus_skill_performed → EncounterDirector 真实削韧 / 伤害（skill_events 增长 + 生效计数）",
			events.size() >= 1 and (int(esnap.get("skill_poise_applied_count", 0)) >= 1 \
					or int(esnap.get("skill_damage_applied_count", 0)) >= 1),
			"events=%d poise_applied=%s damage_applied=%s" % [events.size(),
					str(esnap.get("skill_poise_applied_count", "?")),
					str(esnap.get("skill_damage_applied_count", "?"))])
	_ck("Q4b ★ A48③ Rank-2 生产链：真实 focus_spent 广播被 wave 生产订阅者接收（探针 +1）",
			_spent_log.size() == 1,
			"focus_spent_signals=%d art=%s" % [_spent_log.size(),
					str((_spent_log[0] as Dictionary).get("art_id", "?")) if _spent_log.size() == 1 else "?"])

	# ---- Q5 A57 倍率后值：final_damage = round(base_damage × 有效倍率)，multiplier 随信号带出 ----
	var perf: Dictionary = _performed_log[_performed_log.size() - 1] if not _performed_log.is_empty() else {}
	var base_damage: float = float(last_result.get("damage", 0.0))
	var mult: float = float(perf.get("multiplier", 0.0))
	var expect_damage: int = int(roundf(base_damage * mult))
	_ck("Q5 A57 ★ focus_skill_performed.damage 为倍率后最终值（base×mult），multiplier 随信号带出（≥1.0）",
			_performed_log.size() == 1 and int(perf.get("damage", -1)) == expect_damage \
					and mult >= 1.0,
			"base=%.1f mult=%.2f expect=%d signal_damage=%d" % [base_damage,
					mult, expect_damage, int(perf.get("damage", -1))])

	# ---- Q6 成功路径恰发 1 次 performed、0 次 rejected ----
	_ck("Q6 成功路径恰发 1 次 focus_skill_performed、0 次 focus_skill_rejected",
			_performed_log.size() == 1 and _rejected_log.is_empty(),
			"performed=%d rejected=%d" % [_performed_log.size(), _rejected_log.size()])


# ---------------------------------------------------------------------------
# R) 边界：专注不足 / 冷却 / 幂等 / 赐福回满 / 异常输入
# ---------------------------------------------------------------------------
func _t_r_boundaries() -> void:
	print("[V130] ==== R 组：不足拒绝 / 冷却拒绝 / 重复按键幂等 / 赐福休息回满 ====")
	if _hud == null or _enc == null or _focus == null:
		_ck("R0 关键节点 / 服务可用", false, "hud/enc/focus null")
		return
	var ids: Array = _svc_art_ids()
	var art0: String = String(ids[0]) if not ids.is_empty() else ""
	var min_cost: float = 0.0
	# 从真实服务上次成功结果 / 规则表读首战技 cost（不硬编码数值）
	var lr: Dictionary = _svc_last_result()
	if not lr.is_empty():
		min_cost = float(lr.get("fp_cost", 0.0))
	if min_cost <= 0.0:
		min_cost = 1.0

	# ---- R1 专注不足拒绝：用真实服务公开方法把 FP 消耗到 < fp_cost，再真实 Q → 拒绝不扣 ----
	_svc_reset()
	_hud.call("poll_focus_service")
	# 反复真实 Q（每次新 event）+ tick 清冷却，直到 FP < min_cost（真实服务行为、非编排）
	var guard_r1: int = 0
	while _svc_fp() >= min_cost and guard_r1 < 40:
		guard_r1 += 1
		_press_q()
		_svc_tick(2.0)                    # 真实服务 tick 清该 art 冷却（确定性、不读真实时钟）
	_hud.call("poll_focus_service")
	_performed_log.clear()
	_rejected_log.clear()
	var fp_r1: float = _svc_fp()
	var spend_r1: int = _svc_spend_count()
	_press_q()
	var view_r1: Dictionary = _focus_view()
	_ck("R1 ★ 专注不足拒绝：真实 Q → ok=false reason=insufficient_fp，FP 不变（%.1f < cost %.1f）、HUD 提示「专注不足」" % [fp_r1, min_cost],
			fp_r1 < min_cost and absf(_svc_fp() - fp_r1) < 0.001 \
					and _svc_spend_count() == spend_r1 \
					and _rejected_log.size() == 1 \
					and String((_rejected_log[0] as Dictionary).get("reason", "")) == "insufficient_fp" \
					and String(view_r1.get("hint_text", "")) == "专注不足" \
					and _performed_log.is_empty(),
			"fp=%.1f spend=%d rejected=%d hint=[%s]" % [_svc_fp(), _svc_spend_count(),
					_rejected_log.size(), str(view_r1.get("hint_text", "?"))])

	# ---- R2 冷却拒绝：reset 后一次真实 Q 成功置冷却，不同 event 连续再按 → 服务 cooldown 拒绝、不扣 FP ----
	_svc_reset()
	_hud.call("poll_focus_service")
	_performed_log.clear()
	_rejected_log.clear()
	_press_q()                            # 第一次成功（该 art 进入冷却）
	var fp_r2: float = _svc_fp()
	var spend_r2: int = _svc_spend_count()
	_press_q()                            # 不同 event 连续按 Q，真实服务判 cooldown
	var view_r2: Dictionary = _focus_view()
	_ck("R2 ★ 冷却拒绝：冷却期连续真实 Q → ok=false reason=cooldown，FP 不变（%.1f）、HUD 提示「冷却中」" % fp_r2,
			_performed_log.size() == 1 and _rejected_log.size() == 1 \
					and String((_rejected_log[0] as Dictionary).get("reason", "")) == "cooldown" \
					and absf(_svc_fp() - fp_r2) < 0.001 and _svc_spend_count() == spend_r2 \
					and String(view_r2.get("hint_text", "")) == "冷却中",
			"fp=%.1f performed=%d rejected=%d hint=[%s]" % [_svc_fp(), _performed_log.size(),
					_rejected_log.size(), str(view_r2.get("hint_text", "?"))])

	# ---- R3 重复按键幂等：同一 event 实例连投两次 → HUD 去重，只结算一次、FP 只扣一次 ----
	_svc_reset()
	_hud.call("poll_focus_service")
	_performed_log.clear()
	_rejected_log.clear()
	var fp_r3: float = _svc_fp()
	var spend_r3: int = _svc_spend_count()
	var same_ev: InputEventKey = _key(KEY_Q, true)
	_press_q_same_event_twice(same_ev)
	_ck("R3 ★ 重复按键幂等：同一 Q event 连投两次 → 权威 spend 仅 +1、FP 只扣一次、performed 恰 1 次",
			_svc_spend_count() - spend_r3 == 1 and _svc_fp() < fp_r3 \
					and _performed_log.size() == 1 \
					and absf(_svc_fp() - (fp_r3 - min_cost)) < 0.01,
			"spend %d -> %d fp %.1f -> %.1f performed=%d" % [spend_r3,
					_svc_spend_count(), fp_r3, _svc_fp(), _performed_log.size()])

	# ---- R4 赐福休息回满：真实 debug_grace_rest → grace_rested → HUD 生产订阅者 → FP 回满 ----
	_svc_reset()
	_press_q()                            # 先消耗 FP
	var fp_before_rest: float = _svc_fp()
	var restore_before: int = int((_focus.call("get_snapshot") as Dictionary).get("restore_count", 0))
	if _enc.has_method("debug_grace_rest"):
		_enc.call("debug_grace_rest")     # 真实 _grace_rest() → grace_rested.emit → HUD 生产订阅者
	if _hud.has_method("_r34_refresh_visible"):
		_hud.call("_r34_refresh_visible")
	var view_rest: Dictionary = _focus_view()
	var restore_after: int = int((_focus.call("get_snapshot") as Dictionary).get("restore_count", 0))
	_ck("R4 ★ 赐福休息回满：真实 debug_grace_rest → grace_rested → HUD 生产订阅者 → FP 回满（%.1f → %.1f/%.1f），restore_count +1" % [fp_before_rest, _svc_fp_max(), _svc_fp_max()],
			absf(_svc_fp() - _svc_fp_max()) < 0.001 and restore_after > restore_before \
					and int(view_rest.get("fp", -1)) == int(_svc_fp_max()),
			"fp %.1f -> %.1f/%.1f restore %d -> %d hud_fp=%s" % [fp_before_rest,
					_svc_fp(), _svc_fp_max(), restore_before, restore_after,
					str(view_rest.get("fp", "?"))])

	# ---- R5 异常输入：非 Q 键不误触 / 服务判空降级不崩、不产生 SCRIPT ERROR ----
	_svc_reset()
	_hud.call("poll_focus_service")
	_performed_log.clear()
	_rejected_log.clear()
	var bad: InputEventKey = _key(KEY_J, true)   # J（light_attack，非 Q）
	_hud.call("process_key_event", bad)       # HUD R32 键路径不匹配 Q，不应触发战技判定
	var fp_r5: float = _svc_fp()
	var no_misfire: bool = _performed_log.is_empty() and _rejected_log.is_empty() \
			and absf(_svc_fp() - fp_r5) < 0.001
	# 服务判空降级：临时 bind null → request_focus_skill() 返回确定 unavailable、不崩，随后恢复。
	_hud.call("bind_focus_service", null)
	var unavail: Dictionary = _hud.call("request_focus_skill") as Dictionary
	var degrade_ok: bool = typeof(unavail) == TYPE_DICTIONARY \
			and (not bool(unavail.get("ok", true))) \
			and String(unavail.get("reason", "")) == "focus_service_unavailable"
	_hud.call("bind_focus_service", _focus)   # 恢复 A54 唯一实例
	_ck("R5 异常 / 边界输入不崩：非 Q 键不误触战技、服务判空降级返回确定 unavailable 且不误扣 FP",
			no_misfire and degrade_ok,
			"no_misfire=%s degrade=%s unavail=%s" % [str(no_misfire), str(degrade_ok), str(unavail)])


# ---------------------------------------------------------------------------
# A65) HUD「弹反·免伤」生产订阅者反馈（免伤主断言见 verify_parry_runtime_v120.gd）
# ---------------------------------------------------------------------------
func _t_a65_hud_feedback() -> void:
	print("[V130] ==== A65 HUD 反馈：parry_damage_negated 生产订阅者 ====")
	if _enc == null or _hud == null:
		_ck("A65-0 关键节点可用", false, "hud/enc null")
		return
	_negated_log.clear()
	_enc.emit_signal("parry_damage_negated", "v130_a65_probe")
	var view: Dictionary = _focus_view()
	_ck("A65-H1 ★ parry_damage_negated → HUD 生产订阅者显示「弹反·免伤」反馈",
			_negated_log.size() == 1 and String(view.get("parry_negate_text", "")) == "弹反·免伤" \
					and int(view.get("parry_negate_count", 0)) >= 1,
			"negated_signals=%d hint=[%s] count=%s" % [_negated_log.size(),
					str(view.get("parry_negate_text", "?")), str(view.get("parry_negate_count", "?"))])


# ---------------------------------------------------------------------------
# S) R36B [ROUND=R36B] · 战技切换 R（A69 裁决）真实可达回归（既有 28 条不删不放宽）
#   真实 R 输入（Input.parse_input_event + HUD.process_key_event，与 _unhandled_input
#   同一 R32 键路径）→ request_art_switch() 只读 A54 唯一 FocusService 的 arts 列表
#   循环切换当前战技 → 真实 Q 输入 → spend_fp(当前选中 art_id) 按表生效 →
#   focus_spent(art_id) 广播（hd2d_fx 暖金斩击弧 warm 判定条件）。
#   两战技各自 fp_cost / damage / poise_damage 全部与 focus_rules.tres 表值逐项比对，
#   绝不加载 presentation.gd、不在验证脚本内模拟编排（A48③）。
# ---------------------------------------------------------------------------

## 只读数据表行（FocusConfig.get_art_by_id），供「按表生效」逐项比对。
func _svc_art_row(art_id: String) -> Dictionary:
	if _focus != null and _focus.has_method("get_config"):
		var cfg: Object = _focus.call("get_config") as Object
		if cfg != null and cfg.has_method("get_art_by_id"):
			var d: Variant = cfg.call("get_art_by_id", art_id)
			if typeof(d) == TYPE_DICTIONARY:
				return d as Dictionary
	return {}


## 只读真实服务某战技剩余冷却（服务无该接口时返回 -1，降级不假装是 0）。
func _svc_cooldown(art_id: String) -> float:
	if _focus != null and _focus.has_method("get_cooldown_remaining"):
		return float(_focus.call("get_cooldown_remaining", art_id))
	return -1.0


## 真实 R 输入：Input.parse_input_event 注入 + HUD.process_key_event（与 _unhandled_input
## 完全相同的 R32 键路径，口径同 _press_q），松开配对。
func _press_r() -> void:
	var press: InputEventKey = _key(KEY_R, true)
	Input.parse_input_event(press)
	_hud.call("process_key_event", press)
	var rel: InputEventKey = _key(KEY_R, false)
	Input.parse_input_event(rel)
	_hud.call("process_key_event", rel)


func _art_view() -> Dictionary:
	if _hud == null or not _hud.has_method("get_current_art_view"):
		return {}
	return _hud.call("get_current_art_view") as Dictionary


func _near(a: float, b: float) -> bool:
	return absf(a - b) < 0.001


func _t_s_art_switch() -> void:
	print("[V130] ==== S 组 R36B：R 切换 / 两战技按表生效 / Q 释放当前选中 / 不误触 / 不重置 FP·冷却 / 包围盒避让 ====")
	if _hud == null or _enc == null or _wave == null or _focus == null:
		_ck("S0 关键节点 / 服务可用", false, "hud/enc/wave/focus null")
		return
	# 干净基线：真实服务 reset()（新局 FP 回满）+ 关掉可能拦截 R/Q 的抉择卡片 / 商店 / 图鉴
	_svc_reset()
	if _hud.has_method("close_boon_draft"):
		_hud.call("close_boon_draft")
	_hud.set("shop_open", false)
	if _hud.has_method("set_codex_open"):
		_hud.call("set_codex_open", false)
	_hud.call("poll_focus_service")
	var ids: Array = _svc_art_ids()
	_ck("S0 ★ focus_rules.tres arts 恰 2 个战技（只读 A54 唯一实例 get_art_ids）",
			ids.size() == 2, "art_ids=%s" % str(ids))
	if ids.size() != 2:
		return

	# ---- S1 R 切换 → 当前战技变化 ----
	var v0: Dictionary = _art_view()
	var id0: String = str(v0.get("art_id", ""))
	var idx0: int = int(v0.get("art_index", -1))
	var title0: String = str(v0.get("title", ""))
	_press_r()
	var v1: Dictionary = _art_view()
	var id1: String = str(v1.get("art_id", ""))
	var idx1: int = int(v1.get("art_index", -1))
	var title1: String = str(v1.get("title", ""))
	var row1: Dictionary = _svc_art_row(id1)
	_ck("S1 ★ R 切换 → 当前战技变化（index 循环 +1、art_id/title 从 arts[0] 变为 arts[1]，title 只读表）",
			id0 == str(ids[0]) and id1 == str(ids[1]) and id0 != id1 \
					and idx1 == (idx0 + 1) % ids.size() \
					and title1 == str(row1.get("title", "")) and not title1.is_empty() \
					and title0 != title1,
			"%s(index=%d,%s) -> %s(index=%d,%s)" % [id0, idx0, title0, id1, idx1, title1])

	# ---- S2a 当前选中 = arts[1]（狮子斩）：Q 释放 + fp_cost/damage/poise_damage 按表生效 ----
	_performed_log.clear()
	_rejected_log.clear()
	_spent_log.clear()
	_press_q()
	var r1: Dictionary = _svc_last_result()
	var art1: String = str(r1.get("art_id", ""))
	var row_lion: Dictionary = _svc_art_row(str(ids[1]))
	_ck("S2a ★ 狮子斩 fp_cost / damage / poise_damage 按表生效（Q 释放当前选中 arts[1]）",
			art1 == str(ids[1]) and bool(r1.get("ok", false)) \
					and _near(float(r1.get("fp_cost", -1.0)), float(row_lion.get("fp_cost", 0.0))) \
					and _near(float(r1.get("damage", -1.0)), float(row_lion.get("damage", 0.0))) \
					and _near(float(r1.get("poise_damage", -1.0)), float(row_lion.get("poise_damage", 0.0))) \
					and float(row_lion.get("fp_cost", 0.0)) > 0.0,
			"result=%s table=%s" % [str(r1), str(row_lion)])
	_ck("S2a2 ★ focus_spent 广播 art_id=arts[1]（hd2d_fx 暖金斩击弧 warm 判定条件成立）",
			_spent_log.size() == 1 \
					and str((_spent_log[0] as Dictionary).get("art_id", "")) == str(ids[1]),
			"focus_spent_signals=%d art=%s" % [_spent_log.size(),
					str((_spent_log[0] as Dictionary).get("art_id", "?")) if _spent_log.size() == 1 else "?"])

	# ---- S2b 切回 arts[0]（辉石魔砾）：Q 释放 + 按表生效 ----
	_svc_reset()                          # 清狮斩冷却 + FP 回满（不改 HUD 当前 art_index）
	_hud.call("poll_focus_service")
	_press_r()                            # index 1 -> 0
	_performed_log.clear()
	_rejected_log.clear()
	_spent_log.clear()
	_press_q()
	var r0: Dictionary = _svc_last_result()
	var art0: String = str(r0.get("art_id", ""))
	var row_pebble: Dictionary = _svc_art_row(str(ids[0]))
	_ck("S2b ★ 辉石魔砾 fp_cost / damage / poise_damage 按表生效（切回 arts[0] 后 Q 释放当前选中）",
			art0 == str(ids[0]) and bool(r0.get("ok", false)) \
					and _near(float(r0.get("fp_cost", -1.0)), float(row_pebble.get("fp_cost", 0.0))) \
					and _near(float(r0.get("damage", -1.0)), float(row_pebble.get("damage", 0.0))) \
					and _near(float(r0.get("poise_damage", -1.0)), float(row_pebble.get("poise_damage", 0.0))) \
					and float(row_lion.get("damage", 0.0)) > float(row_pebble.get("damage", 0.0)) \
					and float(row_lion.get("fp_cost", 0.0)) > float(row_pebble.get("fp_cost", 0.0)),
			"result=%s table=%s" % [str(r0), str(row_pebble)])

	# ---- S3 Q 释放【当前选中】战技（非硬编码 arts[0]）----
	_ck("S3 ★ Q 释放当前选中战技（非硬编码 arts[0]）：R→arts[1] 后 Q=arts[1]、R→arts[0] 后 Q=arts[0]",
			art1 == str(ids[1]) and art0 == str(ids[0]) and art1 != art0,
			"R→%s / R→%s" % [art1, art0])

	# ---- S4 R 不误触其它键 ----
	_svc_reset()
	_hud.call("poll_focus_service")
	_performed_log.clear()
	_rejected_log.clear()
	var fp_s4: float = _svc_fp()
	var spend_s4: int = _svc_spend_count()
	var exec_s4: int = int((_hud.call("get_stagger_hud_view") as Dictionary).get("execution_count", 0))
	var parry_s4: int = int((_hud.call("get_parry_hud_view") as Dictionary).get("attempt_count", 0))
	var codex_s4: bool = bool(_hud.call("is_codex_open"))
	var buy_s4: int = (_hud.get("grace_purchase_events") as Array).size()
	_press_r()
	var view_s4: Dictionary = _art_view()
	_ck("S4a ★ R 不误触 Q（不释放战技 / 不扣 FP / 不发 focus_skill_performed·rejected）",
			_performed_log.is_empty() and _rejected_log.is_empty() \
					and _near(_svc_fp(), fp_s4) and _svc_spend_count() == spend_s4 \
					and int(view_s4.get("switch_count", 0)) >= 1,
			"fp=%.1f spend=%d performed=%d rejected=%d switch_count=%s" % [
					_svc_fp(), _svc_spend_count(), _performed_log.size(),
					_rejected_log.size(), str(view_s4.get("switch_count", "?"))])
	_ck("S4b ★ R 不误触 F 处决 / K 弹反 / Tab 图鉴 / 数字键兑换（关键计数与面板态不变）",
			int((_hud.call("get_stagger_hud_view") as Dictionary).get("execution_count", 0)) == exec_s4 \
					and int((_hud.call("get_parry_hud_view") as Dictionary).get("attempt_count", 0)) == parry_s4 \
					and bool(_hud.call("is_codex_open")) == codex_s4 \
					and (_hud.get("grace_purchase_events") as Array).size() == buy_s4,
			"exec=%d parry=%d codex=%s buy=%d" % [exec_s4, parry_s4, str(codex_s4), buy_s4])

	# ---- S5 切换不重置 FP / 冷却 ----
	_svc_reset()
	_hud.call("poll_focus_service")
	_press_q()                            # 制造一次真实 FP 消耗 + 冷却
	var last5: Dictionary = _svc_last_result()
	var fp_s5: float = _svc_fp()
	var spend_s5: int = _svc_spend_count()
	var cd_id: String = str(last5.get("art_id", ""))
	var cd_before: float = _svc_cooldown(cd_id)
	_press_r()                            # 只切换，不调 spend/tick/rest/reset
	var fp_after: float = _svc_fp()
	var cd_after: float = _svc_cooldown(cd_id)
	var cd_kept: bool = cd_before < 0.0 \
			or (cd_before > 0.0 and _near(cd_after, cd_before))
	_ck("S5 ★ 切换不重置 FP / 冷却（FP 余额不变、原战技 cooldown_remaining 不归零、不多扣一次）",
			_near(fp_after, fp_s5) and _svc_spend_count() == spend_s5 \
					and float(_focus_view().get("fp", -1)) == int(fp_after) and cd_kept,
			"fp %.1f -> %.1f spend=%d cd(%s) %.3f -> %.3f" % [
					fp_s5, fp_after, spend_s5, cd_id, cd_before, cd_after])

	# ---- S6 HUD 战技名包围盒不与 FP 条 / 其它文字相交（锚点 + 真实节点双重实证）----
	_hud.call("set_layout_viewport", Vector2(1280.0, 720.0))
	_hud.call("_r34_refresh_visible")
	var art_rect: Rect2 = _hud.call("get_current_art_rect") as Rect2
	var focus_rect: Rect2 = _hud.call("get_focus_rect") as Rect2
	var worst: float = art_rect.intersection(focus_rect).get_area()
	var rects_s6: Array = _hud.call("get_layout_rects") as Array
	for e: Variant in rects_s6:
		var br: Rect2 = (e as Dictionary).get("rect", Rect2()) as Rect2
		worst = maxf(worst, art_rect.intersection(br).get_area())
	worst = maxf(worst, art_rect.intersection(
			(_hud.call("get_parry_telegraph_rect") as Rect2)).get_area())
	worst = maxf(worst, art_rect.intersection(
			(_hud.call("get_production_mechanism_rect") as Rect2)).get_area())
	worst = maxf(worst, art_rect.intersection(
			(_hud.call("get_shop_title_rect") as Rect2)).get_area())
	var layer_s6: Node = _courtyard.get_node_or_null(NodePath(REL_PROD_LAYER))
	var al: Label = layer_s6.get_node_or_null(NodePath(ART_LABEL_NAME)) as Label if layer_s6 != null else null
	var fl: Label = layer_s6.get_node_or_null(NodePath(FOCUS_LABEL_NAME)) as Label if layer_s6 != null else null
	var al_ok: bool = al != null and is_instance_valid(al)
	var fl_ok: bool = fl != null and is_instance_valid(fl)
	var nodes_ok: bool = al_ok and fl_ok and al.visible and al.text.contains("当前战技") \
			and al.get_global_rect().is_equal_approx(art_rect) \
			and al.get_global_rect().intersection(fl.get_global_rect()).get_area() == 0.0
	_ck("S6 ★ HUD 战技名包围盒不与 FP 条 / 连击评价带 / 弹反预兆带 / 其它文字相交",
			art_rect.get_area() > 0.0 and worst == 0.0 and nodes_ok,
			"art_rect=%s blocks_worst=%.4f px² node=%s text=[%s]" % [
					str(art_rect), worst, str(al_ok), al.text if al_ok else ""])

	# ---- S7 HUD 显示「当前战技：辉石魔砾 / 狮子斩」真实节点文本随 R 切换变化 ----
	var va: Dictionary = _art_view()
	var title_a: String = str(va.get("title", ""))
	_press_r()
	var vb: Dictionary = _art_view()
	var title_b: String = str(vb.get("title", ""))
	var row_b: Dictionary = _svc_art_row(str(vb.get("art_id", "")))
	_hud.call("_r34_refresh_visible")
	var text_b: String = al.text if al_ok else ""
	_ck("S7 ★ HUD 显示「当前战技」真实节点文本随 R 切换变化、title 来自数据表（非硬编码）",
			al_ok and title_a != title_b and not title_b.is_empty() \
					and title_b == str(row_b.get("title", "")) \
					and text_b.contains("当前战技：") and text_b.contains(title_b),
			"%s -> %s | node_text=[%s]" % [title_a, title_b, text_b])


func _finish(early: bool) -> void:
	# 释放探针信号连接（有释放路径，不留悬空 Callable）
	if _probes_connected:
		if _hud != null and is_instance_valid(_hud):
			var hpairs: Dictionary = {
				"focus_skill_performed": "_on_performed",
				"focus_skill_rejected": "_on_rejected"}
			for sig: String in hpairs.keys():
				var cb: Callable = Callable(self, String(hpairs[sig]))
				if _hud.has_signal(sig) and _hud.is_connected(sig, cb):
					_hud.disconnect(sig, cb)
		if _enc != null and is_instance_valid(_enc):
			var cb2: Callable = Callable(self, "_on_negated")
			if _enc.has_signal("parry_damage_negated") and _enc.is_connected("parry_damage_negated", cb2):
				_enc.disconnect("parry_damage_negated", cb2)
		if _focus != null and is_instance_valid(_focus):
			var cb3: Callable = Callable(self, "_on_spent")
			if _focus.has_signal("focus_spent") and _focus.is_connected("focus_spent", cb3):
				_focus.disconnect("focus_spent", cb3)
	var ok: bool = (not early) and _fail == 0 and _pass > 0
	print("[V130] ---- 回读汇总 ----")
	print("[V130] SUMMARY pass=%d fail=%d total=%d ok=%s focus_source=%s" % [
			_pass, _fail, _pass + _fail, str(ok), _focus_source])
	if ok:
		print("[V130] RESULT=ALL_MATCH")
	else:
		print("[V130] RESULT=MISMATCH")
	print("[V130] ==== verify_focus_runtime_v130 真跑结束 ====")
	quit(0 if ok else 1)
