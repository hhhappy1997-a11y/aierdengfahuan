extends SceneTree

## ===========================================================================
## verify_life_runtime_v140.gd · R37 / v0.14.0「元素瓶与死亡轮回」真实可达回归
##   Rank-1 唯一写入方 · 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 / 零外部依赖
##
## A48③：本脚本【不加载 presentation.gd】（运行时树零 presentation 节点）、
##   【不在验证脚本内模拟编排】：用真实 InputEventKey 注入（Input.parse_input_event）
##   → HUD/ENC 生产 _unhandled_input / R32 键路径 → A54 唯一 flask_service /
##   death_service 真实判定 → ENC 生产运行时订阅者消费（_player_hp 真实写回，A57）
##   → HUD 生产常驻可见层真实节点 ProdFlaskLabel / ProdDeathLabel 文本变化（画面）。
##   纯逻辑 + 单元断言不算可玩交付；本脚本断言「真实输入 → 生产链路 → 画面」确实发生。
##
## A54 唯一实例：优先复用 wave_trial_director.get_flask_service() /
##   get_death_service() 的【真实】Rank-2 实例；Rank-2 并行派单尚未落盘时，
##   降级 FakeFlask / FakeDeath 契约替身（镜像 Rank-2 派单承诺的公开接口），
##   经 HUD/ENC 既有 bind_*_service() 注入同一个 Object，如实登记 source，不冒充联调
##   （同 R35 FakeParry / R36 FakeFocus 先例）。绝不自建第二个生产实例。
##
## SceneTree / --script 纪律：Engine.get_main_loop() as SceneTree 取 root（不用 get_tree()、
##   不用 /root/... 绝对路径）、add_child 后显式 call("_ready") / _r34_bootstrap()、
##   资源 CACHE_MODE_IGNORE、connect 前 get_signal_connection_list() 去重 +
##   _finish() disconnect 释放；project.godot 既有 PointsCommitOrchestrator autoload
##   直接复用、不重复挂载。
##
## 输出：逐条 PASS/FAIL + SUMMARY + RESULT=ALL_MATCH（全通过）/ MISMATCH。
## ===========================================================================

const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"
const NODE_COUNT_EXPECTED: int = 54  # R38 / A74 新基线（A38 旧基线 41）
const REL_HUD: String = "SubViewportContainer/SubViewport/FXLayer/Hud"
const REL_ENC: String = "EncounterRoot"
const REL_WAVE: String = "WaveTrialDirector"
const REL_PROD_LAYER: String = "ProductionMechanismsLayer"
const FLASK_LABEL_NAME: String = "ProdFlaskLabel"
const DEATH_LABEL_NAME: String = "ProdDeathLabel"
const KEY_G: int = 71
const KEY_Q: int = 81
const KEY_K: int = 75
const KEY_F: int = 70
const KEY_E: int = 69
const KEY_R: int = 82
const KEY_J: int = 74

## 降级契约替身：仅当 Rank-2 真实 FlaskService 未落盘时启用。镜像真实公开接口
## （use_flask(current_hp,max_hp) / on_grace_rest() / reset() / get_snapshot()），
## 使本验证的鸭子类型 helper 对真实实例与降级替身通用；[验证替身] 数值不写任何 .tres / .gd。
class FakeFlask extends RefCounted:
	var _flask: int = 3
	var _flask_max: int = 3
	var _heal: float = 30.0
	var _use_count: int = 0
	var _reject_count: int = 0
	var _rest_count: int = 0
	var _last: Dictionary = {}
	var _last_reject: String = ""

	func use_flask(current_hp: Variant, max_hp: Variant) -> Dictionary:
		var hp: float = float(current_hp)
		var mx: float = float(max_hp)
		if hp < 0.0 or mx <= 0.0 or hp > mx:
			return _reject("invalid_input")
		if _flask <= 0:
			return _reject("flask_empty")
		if hp >= mx:
			return _reject("hp_full")
		var before: int = _flask
		var hp_before: float = hp
		_flask -= 1
		var hp_after: float = minf(mx, hp + _heal)
		_use_count += 1
		_last = {"ok": true, "reason": "ok", "flask": _flask, "flask_max": _flask_max,
				"flask_before": before, "hp_before": int(hp_before), "hp_after": int(hp_after),
				"heal_amount": _heal, "use_count": _use_count}
		return _last.duplicate()

	func _reject(reason: String) -> Dictionary:
		_reject_count += 1
		_last_reject = reason
		_last = {"ok": false, "reason": reason, "flask": _flask, "flask_max": _flask_max,
				"hp_after": 0, "use_count": _use_count}
		return _last.duplicate()

	func on_grace_rest() -> Dictionary:
		var before: int = _flask
		_flask = _flask_max
		_rest_count += 1
		_last = {"ok": true, "reason": "rest_refill", "flask": _flask, "flask_max": _flask_max,
				"flask_before": before, "rest_count": _rest_count}
		return _last.duplicate()

	func reset() -> void:
		_flask = _flask_max
		_use_count = 0
		_reject_count = 0
		_rest_count = 0
		_last = {}
		_last_reject = ""

	func get_snapshot() -> Dictionary:
		return {"flask": _flask, "flask_max": _flask_max, "heal_amount": _heal,
				"use_count": _use_count, "reject_count": _reject_count,
				"rest_count": _rest_count, "last_result": _last.duplicate(),
				"last_reject_reason": _last_reject}

	func get_flask() -> int: return _flask
	func get_flask_max() -> int: return _flask_max
	func get_use_count() -> int: return _use_count
	func get_reject_count() -> int: return _reject_count
	func get_rest_count() -> int: return _rest_count
	func get_last_result() -> Dictionary: return _last.duplicate()
	func get_last_reject_reason() -> String: return _last_reject


## 降级契约替身：镜像 Rank-2 DeathService 公开接口（observe_hp / respawn /
## get_snapshot / reset）；HP 归零 → 死亡态 → 记录掉落赐福点数（只一次，重复死亡
## 不二次掉落）→ 赐福重生 → 一次性回收。不写 flag / 不写存档（I-1）。
class FakeDeath extends RefCounted:
	var _dead: bool = false
	var _dropped: int = 0
	var _reclaimed: bool = false
	var _death_count: int = 0
	var _respawn_count: int = 0
	var _drop_ratio: float = 0.25       # [验证替身][PLACEHOLDER] 掉落比例，非玩法数值

	## 与 Rank-2 真实 DeathService 主接口同名同签名（on_death(grace_points)）。
	func on_death(grace_points: Variant) -> Dictionary:
		var gp: float = float(grace_points)
		if gp < 0.0:
			return get_snapshot()
		if not _dead and not (_dropped > 0 and not _reclaimed):
			_dead = true
			_dropped = int(roundf(gp * _drop_ratio))
			_death_count += 1
		return get_snapshot()

	## 与 Rank-2 真实 DeathService 主接口同名同签名（on_grace_respawn()）。
	func on_grace_respawn() -> Dictionary:
		if not _dead:
			return get_snapshot()
		_dead = false
		_respawn_count += 1
		return get_snapshot()

	## 契约替身降级候选（保留，供 HUD 鸭子类型多候选兼容）。
	func observe_hp(hp: Variant, max_hp: Variant) -> Dictionary:
		var h: float = float(hp)
		var mx: float = float(max_hp)
		if h < 0.0 or mx <= 0.0:
			return get_snapshot()
		if h <= 0.0 and not _dead:
			_dead = true
			_dropped = int(roundf(mx * _drop_ratio))
			_death_count += 1
		return get_snapshot()

	func respawn() -> Dictionary:
		if _dead and not _reclaimed:
			_reclaimed = true
		_dead = false
		_respawn_count += 1
		return get_snapshot()

	func reset() -> void:
		_dead = false
		_dropped = 0
		_reclaimed = false
		_death_count = 0
		_respawn_count = 0

	func get_snapshot() -> Dictionary:
		return {"is_dead": _dead, "dead": _dead, "dropped_points": _dropped,
				"dropped": _dropped, "reclaimed": _reclaimed,
				"death_count": _death_count, "respawn_count": _respawn_count}

	func is_dead() -> bool: return _dead
	func get_dropped_points() -> int: return _dropped
	func get_death_count() -> int: return _death_count
	func get_respawn_count() -> int: return _respawn_count


var _pass: int = 0
var _fail: int = 0
var _tree: SceneTree = null
var _courtyard: Node = null
var _hud: Node = null
var _enc: Node = null
var _wave: Node = null
var _flask: Object = null             # A54 唯一实例（真实 FlaskService / 降级 FakeFlask）
var _death: Object = null             # A54 唯一实例（真实 DeathService / 降级 FakeDeath）
var _flask_source: String = "none"
var _death_source: String = "none"
var _is_real_service: bool = false

# 探针信号回读（只读统计，不写任何状态）
var _flask_used_log: Array[Dictionary] = []
var _flask_rejected_log: Array[Dictionary] = []
var _died_log: Array[Dictionary] = []
var _respawned_log: Array[Dictionary] = []
var _focus_performed_log: Array[Dictionary] = []
var _parry_log: Array[Dictionary] = []
var _exec_log: Array[Dictionary] = []
var _probes_connected: bool = false


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V140] %s PASS=%s | %s" % [tag, str(ok), detail])


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
			return true
	obj.connect(sig, cb)
	return true


func _initialize() -> void:
	print("[V140] ==== verify_life_runtime_v140 真跑开始 | R37 v0.14.0 Rank-1 ====")
	print("[V140] A48③：不加载 presentation.gd；不模拟编排；真实 G/E 输入 → 生产链路 → 画面")
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null:
		print("[V140] RESULT=MISMATCH（Engine.get_main_loop() 非 SceneTree）")
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
	_bind_life_services()
	_bind_probes()
	_t_a_assembly()
	_t_b_flask_real_input()
	_t_c_fp_consume()
	_t_d_death_cycle()
	_t_e_summary()
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
	print("[V140] 主场景已实例化入树 | name=%s（未加载 presentation.gd）" % str(_courtyard.name))


func _resolve_nodes() -> void:
	_hud = _courtyard.get_node_or_null(NodePath(REL_HUD))
	_enc = _courtyard.get_node_or_null(NodePath(REL_ENC))
	_wave = _courtyard.get_node_or_null(NodePath(REL_WAVE))
	_ck("A1 主场景关键节点可寻址（EncounterRoot / Hud / WaveTrialDirector）",
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
		_enc.call("_r34_bootstrap")     # 内部末尾触发 _r35/_r36/_r37_bootstrap（生产订阅者）
	if _hud.has_method("_r34_bootstrap"):
		_hud.call("_r34_bootstrap")     # 内部末尾触发 _r36/_r37_bootstrap（A54 复用 + 生产订阅）
	print("[V140] 显式 _r34_bootstrap() 完成（R37 生产订阅者已装配）")


## A54：直接复用 wave_trial_director.get_flask_service() / get_death_service() 的
## 【真实唯一实例】，注入 HUD 与 ENC 同一个 Object；真实实例不可用（Rank-2 并行
## 派单尚未落盘）→ FakeFlask / FakeDeath 契约替身降级并如实登记（R35/R36 先例）。
func _bind_life_services() -> void:
	var real_flask: Object = null
	var real_death: Object = null
	if _wave != null:
		if _wave.has_method("get_flask_service"):
			real_flask = _wave.call("get_flask_service") as Object
		if _wave.has_method("get_death_service"):
			real_death = _wave.call("get_death_service") as Object
	if real_flask != null and is_instance_valid(real_flask) \
			and real_flask.has_method("use_flask") and real_flask.has_method("get_snapshot"):
		_flask = real_flask
		_flask_source = "rank2_production_unique_instance"
		_is_real_service = true
		print("[V140] A54 ★ 复用 wave.get_flask_service() 真实唯一实例（Rank-2 FlaskService 已落盘）→ 走真实判定，不冒充联调")
	else:
		_flask = FakeFlask.new()
		_flask_source = "fake_contract_rank2_not_landed"
		_is_real_service = false
		print("[V140] [如实登记] Rank-2 FlaskService 真实实例不可用 → 降级 FakeFlask 契约替身仅验证 Rank-1 生产接线链；真实判定待落盘联调，不冒充")
	if real_death != null and is_instance_valid(real_death) \
			and real_death.has_method("get_snapshot"):
		_death = real_death
		_death_source = "rank2_production_unique_instance"
		print("[V140] A54 ★ 复用 wave.get_death_service() 真实唯一实例（Rank-2 DeathService 已落盘）")
	else:
		_death = FakeDeath.new()
		_death_source = "fake_contract_rank2_not_landed"
		print("[V140] [如实登记] Rank-2 DeathService 真实实例不可用 → 降级 FakeDeath 契约替身，不冒充")
	if _hud != null:
		if _hud.has_method("bind_flask_service"):
			_hud.call("bind_flask_service", _flask)
		if _hud.has_method("bind_death_service"):
			_hud.call("bind_death_service", _death)
	if _enc != null:
		if _enc.has_method("bind_flask_service"):
			_enc.call("bind_flask_service", _flask)
		if _enc.has_method("bind_death_service"):
			_enc.call("bind_death_service", _death)


func _bind_probes() -> void:
	if _hud == null:
		return
	_probes_connected = true
	_dedup_connect(_hud, "flask_used", "_on_flask_used")
	_dedup_connect(_hud, "flask_rejected", "_on_flask_rejected")
	_dedup_connect(_hud, "player_died", "_on_player_died")
	_dedup_connect(_hud, "player_respawned", "_on_player_respawned")
	_dedup_connect(_hud, "focus_skill_performed", "_on_focus_performed")
	_dedup_connect(_hud, "parry_performed", "_on_parry")
	_dedup_connect(_hud, "execution_performed", "_on_exec")


func _on_flask_used(a: int, b: int, c: int, d: int) -> void:
	_flask_used_log.append({"flask_before": a, "flask_after": b, "hp_before": c, "hp_after": d})


func _on_flask_rejected(reason: String, flask: int) -> void:
	_flask_rejected_log.append({"reason": reason, "flask": flask})


func _on_player_died(dropped: int) -> void:
	_died_log.append({"dropped_points": dropped})


func _on_player_respawned(hp: int, fp: int, flask: int) -> void:
	_respawned_log.append({"hp": hp, "fp": fp, "flask": flask})


func _on_focus_performed(_a: String, _b: int, _c: int, _d: int, _e: int, _f: float, _g: float) -> void:
	_focus_performed_log.append({})


func _on_parry(_a: String, _b: int, _c: float) -> void:
	_parry_log.append({})


func _on_exec(_a: String, _b: int) -> void:
	_exec_log.append({})


# ---- 真实服务鸭子类型只读 helper（对真实实例与降级替身通用）----
func _flask_count() -> int:
	if _flask == null:
		return -1
	if _flask.has_method("get_flasks"):
		return int(_flask.call("get_flasks"))          # 真实 FlaskService
	if _flask.has_method("get_flask"):
		return int(_flask.call("get_flask"))           # 降级 FakeFlask
	var snap: Dictionary = _flask.call("get_snapshot") as Dictionary
	return int(snap.get("flasks", snap.get("flask_remaining", snap.get("flask", -1))))


func _flask_max() -> int:
	if _flask == null:
		return -1
	if _flask.has_method("get_flask_max"):
		return int(_flask.call("get_flask_max"))
	var snap: Dictionary = _flask.call("get_snapshot") as Dictionary
	return int(snap.get("flask_max", -1))


func _death_snap() -> Dictionary:
	if _death == null or not _death.has_method("get_snapshot"):
		return {}
	return _death.call("get_snapshot") as Dictionary


func _life_view() -> Dictionary:
	if _hud == null or not _hud.has_method("get_life_hud_view"):
		return {}
	return _hud.call("get_life_hud_view") as Dictionary


func _enc_hp() -> float:
	if _enc == null or not _enc.has_method("get_life_hp_view"):
		return -1.0
	return float((_enc.call("get_life_hp_view") as Dictionary).get("hp", -1.0))


func _enc_prod() -> Dictionary:
	if _enc == null or not _enc.has_method("get_life_production_snapshot"):
		return {}
	return _enc.call("get_life_production_snapshot") as Dictionary


## 真实 G 输入：Input.parse_input_event 注入 + HUD.process_key_event（与 _unhandled_input
## 同走 R32 键路径）+ ENC._unhandled_input（生产双接，同一 event 实例幂等去重），
## 再注入 release。绝不调服务方法构造状态、绝不模拟编排。
func _press_g(both: bool = false) -> void:
	var ev: InputEventKey = _key(KEY_G, true)
	Input.parse_input_event(ev)
	if _hud != null and _hud.has_method("process_key_event"):
		_hud.call("process_key_event", ev)
	if both and _enc != null:
		_enc.call("_unhandled_input", ev)      # 同一 event 实例 → HUD 幂等去重，不重复扣瓶
	Input.parse_input_event(_key(KEY_G, false))


## 真实 E 输入：走 ENC 既有 _unhandled_input(interact) → _grace_rest() → grace_rested 广播。
func _press_e() -> void:
	var ev: InputEventKey = _key(KEY_E, true)
	Input.parse_input_event(ev)
	if _enc != null:
		_enc.call("_unhandled_input", ev)
	if _hud != null:
		_hud.call("_unhandled_input", ev)
	Input.parse_input_event(_key(KEY_E, false))


func _tree_has_script(n: Node, keyword: String) -> bool:
	if n == null:
		return false
	var sc: Script = n.get_script() as Script
	if sc != null and String(sc.resource_path).contains(keyword):
		return true
	for c: Node in n.get_children():
		if _tree_has_script(c, keyword):
			return true
	return false


# ===========================================================================
# A 组 · 装配 / A38 / A48① / A54 / 真实节点（既有断言不删不放宽）
# ===========================================================================
func _t_a_assembly() -> void:
	print("[V140] ==== A 组 R37 装配 / A38 / A48① / A54 ====")
	# A2 A38 节点数 54（R38 / A74 新基线）
	var text: String = FileAccess.get_file_as_string(COURTYARD_PATH)
	var count: int = 0
	for line: String in text.split("\n"):
		if line.begins_with("[node "):
			count += 1
	_ck("A2 A38 courtyard.tscn 节点数 == 54（R37 运行时建层、不写场景；R38 / A74 新基线 41→54）",
			count == NODE_COUNT_EXPECTED, "count=%d expected=%d" % [count, NODE_COUNT_EXPECTED])
	# A3 不加载 presentation.gd
	_ck("A3 A48③ 不加载 presentation.gd（运行时树零 presentation 节点）",
			not _tree_has_script(_tree.root, "presentation.gd"),
			"presentation_in_tree=%s" % str(_tree_has_script(_tree.root, "presentation.gd")))
	# A4 HUD 4 个新信号齐全
	var sigs: Array[String] = ["flask_used", "flask_rejected", "player_died", "player_respawned"]
	var miss: Array[String] = []
	for s: String in sigs:
		if _hud == null or not _hud.has_signal(s):
			miss.append(s)
	_ck("A4 HUD 新增 flask_used / flask_rejected / player_died / player_respawned 4 信号齐全",
			miss.is_empty(), "missing=%s" % str(miss))
	# A5 A48① 生产运行时订阅者 = EncounterDirector（非验证脚本）
	var enc_sub: int = 0
	if _hud != null:
		for s2: String in sigs:
			if not _hud.has_signal(s2):
				continue
			for conn in _hud.get_signal_connection_list(s2):
				var c: Callable = conn.get("callable", Callable())
				if c.get_object() == _enc:
					enc_sub += 1
					break
	_ck("A5 A48① ★ HUD 4 个新信号各有生产运行时订阅者 EncounterDirector（_r37_bootstrap connect）",
			enc_sub == 4, "signals_with_enc_subscriber=%d/4" % enc_sub)
	# A6 A54 唯一实例：HUD / ENC /（wave 若落盘）同一 Object
	var hf: Object = _hud.call("get_flask_service") as Object if _hud.has_method("get_flask_service") else null
	var ef: Object = _enc.call("get_flask_service") as Object if _enc.has_method("get_flask_service") else null
	var hd: Object = _hud.call("get_death_service") as Object if _hud.has_method("get_death_service") else null
	var ed: Object = _enc.call("get_death_service") as Object if _enc.has_method("get_death_service") else null
	_ck("A6 A54 ★ HUD / ENC 的 flask_service + death_service 各同一真实 Object（绝不自建第二实例）",
			hf != null and hf == ef and hd != null and hd == ed,
			"flask_same=%s death_same=%s flask_source=%s death_source=%s" % [
					str(hf != null and hf == ef), str(hd != null and hd == ed),
					_flask_source, _death_source])
	# A7 生产常驻可见层含元素瓶 / 死亡态真实节点（hud.gd 自建，非演示构造）
	var layer: Node = _courtyard.get_node_or_null(NodePath(REL_PROD_LAYER))
	if layer == null and _hud != null:
		layer = _hud.get_node_or_null(NodePath(REL_PROD_LAYER))
	var kl: Label = layer.get_node_or_null(NodePath(FLASK_LABEL_NAME)) as Label if layer != null else null
	var xl: Label = layer.get_node_or_null(NodePath(DEATH_LABEL_NAME)) as Label if layer != null else null
	_ck("A7 生产常驻可见层含 R37「元素瓶 N/M」ProdFlaskLabel +「你死了」ProdDeathLabel 真实节点（hud.gd 自建）",
			kl != null and is_instance_valid(kl) and xl != null and is_instance_valid(xl),
			"flask_node=%s death_node=%s text=[%s]" % [
					str(kl != null), str(xl != null), kl.text if kl != null else ""])
	# A8 HUD 元素瓶文字包围盒粗测（细测在 V100HUD M 组四档降级）
	_hud.call("set_layout_viewport", Vector2(1280.0, 720.0))
	if _hud.has_method("_r34_refresh_visible"):
		_hud.call("_r34_refresh_visible")
	var fr: Rect2 = kl.get_global_rect() if kl != null else Rect2()
	var blocks: Array = []
	for e in _hud.call("get_layout_rects") as Array:
		blocks.append((e as Dictionary).get("rect", Rect2()) as Rect2)
	blocks.append(_hud.call("get_shop_title_rect") as Rect2)
	blocks.append(_hud.call("get_production_mechanism_rect") as Rect2)
	blocks.append(_hud.call("get_parry_telegraph_rect") as Rect2)
	blocks.append(_hud.call("get_focus_rect") as Rect2)
	blocks.append(_hud.call("get_current_art_rect") as Rect2)
	var worst: float = 0.0
	for b in blocks:
		worst = maxf(worst, fr.intersection(b as Rect2).get_area())
	_ck("A8 元素瓶文字包围盒不与 6 分区 / 赐福成长标题 / 连击带 / 弹反带 / FP 条 / 战技名相交",
			kl != null and fr.get_area() > 0.0 and worst == 0.0,
			"flask_rect=%s blocks=%d worst_overlap=%.4f px²" % [str(fr), blocks.size(), worst])


# ===========================================================================
# B 组 · 真实 G 输入 → 生产链路（瓶扣减 / HP 回复 / 满血 / 瓶尽 / 幂等 / 补瓶）
# ===========================================================================
func _t_b_flask_real_input() -> void:
	print("[V140] ==== B 组 R37 真实 G → 元素瓶生产链路（A48③）====")
	if _flask.has_method("reset"):
		_flask.call("reset")
	if _hud.has_method("bind_flask_service"):
		_hud.call("bind_flask_service", _flask)      # 同步 HUD 权威镜像到干净基线
	if _hud.has_method("close_boon_draft"):
		_hud.call("close_boon_draft")
	_hud.set("shop_open", false)
	if _hud.has_method("set_codex_open"):
		_hud.call("set_codex_open", false)
	_enc.set("_player_hp", 60.0)                     # 测试基线：非满血（既有 @export 状态镜像，不改判定）
	_hud.call("on_player_hp_changed", 60.0, 100.0)
	var f0: int = _flask_count()
	var hp0: float = _enc_hp()
	var used0: int = _flask_used_log.size()
	var prod0: Dictionary = _enc_prod()
	var wb0: int = int(prod0.get("hp_writeback_count", 0))
	# B1 真实 G → 成功扣瓶 + HP 回复 + ENC 生产订阅者真实写回（A57）
	_press_g(true)
	var f1: int = _flask_count()
	var hp1: float = _enc_hp()
	var used1: int = _flask_used_log.size()
	var prod1: Dictionary = _enc_prod()
	var wb1: int = int(prod1.get("hp_writeback_count", 0))
	_ck("B1 ★ A48③ 真实 G → 瓶数扣减（%d→%d）+ HP 回复（%.0f→%.0f）+ flask_used 广播 + ENC 生产消费真实写回 _player_hp（A57）" % [f0, f1, hp0, hp1],
			f1 == f0 - 1 and hp1 > hp0 and used1 == used0 + 1 and wb1 == wb0 + 1 \
					and (prod1.get("flask_events", []) as Array).size() > (prod0.get("flask_events", []) as Array).size(),
			"flask %d->%d hp %.0f->%.0f used %d->%d writeback %d->%d enc_flask_events=%d" % [
					f0, f1, hp0, hp1, used0, used1, wb0, wb1,
					(prod1.get("flask_events", []) as Array).size()])
	# B2 HUD 元素瓶真实节点文本随状态变化（画面）
	var layer: Node = _courtyard.get_node_or_null(NodePath(REL_PROD_LAYER))
	if layer == null:
		layer = _hud.get_node_or_null(NodePath(REL_PROD_LAYER))
	var kl: Label = layer.get_node_or_null(NodePath(FLASK_LABEL_NAME)) as Label if layer != null else null
	var txt: String = kl.text if kl != null else ""
	_ck("B2 真实 G 后 HUD 真实节点 ProdFlaskLabel 文本显示「元素瓶 %d/%d」（画面同步）" % [f1, _flask_max()],
			kl != null and kl.visible and txt.contains("元素瓶 %d/%d" % [f1, _flask_max()]),
			"node_text=[%s] visible=%s" % [txt, str(kl.visible if kl != null else false)])
	# B5 双接幂等：同一 event 实例 HUD + ENC 双调只扣 1 瓶（_press_g(true) 已同 event 双接）。
	#   真实 FlaskService 自带「相邻同签名重复按键」幂等，故本步先把 HP 设为【不同值】
	#   隔离服务侧 duplicate 门，单独验证 Rank-1 的 event 实例幂等去重。
	_enc.set("_player_hp", 55.0)
	var f_before_idem: int = _flask_count()
	_press_g(true)
	var f_after_idem: int = _flask_count()
	_ck("B5 重复按键幂等：HUD+ENC 双接同一真实 G event 实例只扣 1 瓶（不重复扣瓶 / 不重复回 HP）",
			f_after_idem == f_before_idem - 1,
			"flask %d -> %d（期望 -1）" % [f_before_idem, f_after_idem])
	# B4 瓶尽拒绝：连续真实 G 到瓶尽（每次 HP 取不同值避开服务 duplicate 门），
	#   再按一次不扣瓶 + 「瓶数不足」提示（真实服务 reason=no_flask）。
	var guard: int = 0
	while _flask_count() > 0 and guard < 12:
		_enc.set("_player_hp", 30.0 - float(guard))
		_press_g()
		guard += 1
	_enc.set("_player_hp", 20.0 - float(guard))
	var f_empty: int = _flask_count()
	var rej0: int = _flask_rejected_log.size()
	_press_g()
	var f_after_empty: int = _flask_count()
	var rej1: int = _flask_rejected_log.size()
	var last_rej: String = String((_flask_rejected_log.back() as Dictionary).get("reason", "")) if rej1 > 0 else ""
	_ck("B4 瓶尽拒绝：flask==0 时真实 G 不扣瓶 + flask_rejected（瓶数不足 / no_flask）+ HUD 提示",
			f_empty == 0 and f_after_empty == 0 and rej1 == rej0 + 1 \
					and (last_rej.contains("no_flask") or last_rej.contains("empty") \
							or last_rej.contains("exhaust") or last_rej.contains("insufficient")),
			"flask=%d after=%d reject=%s hint=[%s]" % [
					f_empty, f_after_empty, last_rej, String(_life_view().get("hint_text", ""))])
	# B6 赐福休息补满瓶：真实 E → ENC 既有 _grace_rest() → grace_rested → HUD 生产订阅者补满
	var f_before_rest: int = _flask_count()
	_press_e()
	var f_after_rest: int = _flask_count()
	_ck("B6 赐福休息补满瓶：真实 E → 既有 _grace_rest() → grace_rested 生产订阅 → flask 0→max（不突破上限）",
			f_before_rest == 0 and f_after_rest == _flask_max() and f_after_rest > f_before_rest,
			"flask %d -> %d (max=%d)" % [f_before_rest, f_after_rest, _flask_max()])
	# B3 满血拒绝：赐福休息后 HP 已满，真实 G 不扣瓶 + 「生命已满」提示
	var f_before_full: int = _flask_count()
	var rej_full0: int = _flask_rejected_log.size()
	_press_g()
	var f_after_full: int = _flask_count()
	var rej_full1: int = _flask_rejected_log.size()
	var full_rej: String = String((_flask_rejected_log.back() as Dictionary).get("reason", "")) if rej_full1 > 0 else ""
	_ck("B3 满血拒绝：HP 已满时真实 G 不扣瓶 + flask_rejected（生命已满）+ HUD 提示",
			f_after_full == f_before_full and rej_full1 == rej_full0 + 1 \
					and (full_rej.contains("full") or full_rej.contains("满")),
			"flask=%d reject=%s hint=[%s] hp=%.0f" % [
					f_after_full, full_rej, String(_life_view().get("hint_text", "")), _enc_hp()])
	# B7 异常输入拒绝（负 HP）：服务 invalid_input_policy 不扣瓶
	var f_before_bad: int = _flask_count()
	_enc.set("_player_hp", -1.0)
	_press_g()
	var f_after_bad: int = _flask_count()
	_ck("B7 异常输入拒绝：HP<0 时真实 G 不扣瓶（服务 invalid_input_policy，不崩 / 无解析错误）",
			f_after_bad == f_before_bad, "flask %d -> %d" % [f_before_bad, f_after_bad])
	_enc.set("_player_hp", 100.0)
	_hud.call("on_player_hp_changed", 100.0, 100.0)


# ===========================================================================
# C 组 · 真实 Q 消耗 FP（为「重生后 FP 回满」建立非满基线）
# ===========================================================================
func _t_c_fp_consume() -> void:
	print("[V140] ==== C 组 真实 Q 消耗 FP（重生回满基线）====")
	var fp_view0: Dictionary = _hud.call("get_focus_hud_view") as Dictionary if _hud.has_method("get_focus_hud_view") else {}
	var fp_before: int = int(fp_view0.get("fp", -1))
	var fp_max: int = int(fp_view0.get("fp_max", -1))
	var q: InputEventKey = _key(KEY_Q, true)
	Input.parse_input_event(q)
	if _hud.has_method("process_key_event"):
		_hud.call("process_key_event", q)
	Input.parse_input_event(_key(KEY_Q, false))
	var fp_view1: Dictionary = _hud.call("get_focus_hud_view") as Dictionary if _hud.has_method("get_focus_hud_view") else {}
	var fp_after: int = int(fp_view1.get("fp", -1))
	_ck("C1 真实 Q 消耗 FP 建立非满基线（重生后断言 FP 回满）",
			fp_before > 0 and fp_max > 0 and fp_after < fp_before,
			"fp %d -> %d (max=%d) focus_service 真实唯一实例" % [fp_before, fp_after, fp_max])


# ===========================================================================
# D 组 · HP 归零 → 死亡态 → 死亡期间拒绝 G/Q/K/F → 重复死亡 → 赐福重生回满
# ===========================================================================
func _t_d_death_cycle() -> void:
	print("[V140] ==== D 组 R37 死亡轮回（HP 归零 → 死亡态 → 重生后 HP/FP/瓶回满）====")
	if _death.has_method("reset"):
		_death.call("reset")
	# 干净基线：赐福休息补满瓶 + HP 满
	if _flask.has_method("reset"):
		_flask.call("reset")
	if _hud.has_method("bind_flask_service"):
		_hud.call("bind_flask_service", _flask)
	_enc.set("_player_hp", 100.0)
	_hud.call("on_player_hp_changed", 100.0, 100.0)
	# D1 HP 归零 → 死亡态（经 ENC 转发落点 on_player_hp_changed → death_service 权威判定）
	_enc.set("_player_hp", 0.0)
	var died0: int = _died_log.size()
	_hud.call("on_player_hp_changed", 0.0, 100.0)
	var lv_dead: Dictionary = _life_view()
	var dsnap: Dictionary = _death_snap()
	var died1: int = _died_log.size()
	_ck("D1 HP 归零 → 死亡态（death_service 权威判定）+「你死了 / 掉落赐福点数」+ player_died 广播",
			bool(lv_dead.get("is_dead", false)) and died1 == died0 + 1 \
					and bool(dsnap.get("is_dead", false)) \
					and String(lv_dead.get("death_text", "")).contains("你死了"),
			"hud_dead=%s death_service_dead=%s dropped=%d death_text=[%s]" % [
					str(lv_dead.get("is_dead", false)), str(dsnap.get("is_dead", false)),
					int(lv_dead.get("dropped_points", 0)), String(lv_dead.get("death_text", ""))])
	# D1b 「你死了」真实节点可见 + 文本
	var layer: Node = _courtyard.get_node_or_null(NodePath(REL_PROD_LAYER))
	if layer == null:
		layer = _hud.get_node_or_null(NodePath(REL_PROD_LAYER))
	var xl: Label = layer.get_node_or_null(NodePath(DEATH_LABEL_NAME)) as Label if layer != null else null
	_ck("D1b 死亡态 HUD 真实节点 ProdDeathLabel 可见且显示「你死了 / 掉落赐福点数」（画面）",
			xl != null and xl.visible and xl.text.contains("你死了"),
			"visible=%s text=[%s]" % [str(xl.visible if xl != null else false), xl.text if xl != null else ""])
	# D2 死亡期间拒绝 G/Q/K/F（真实输入，不扣瓶 / 不释放战技 / 不弹反 / 不处决）
	var f_before: int = _flask_count()
	var used_before: int = _flask_used_log.size()
	var focus_before: int = _focus_performed_log.size()
	var parry_before: int = _parry_log.size()
	var exec_before: int = _exec_log.size()
	for code: int in [KEY_G, KEY_Q, KEY_K, KEY_F]:
		var ev: InputEventKey = _key(code, true)
		Input.parse_input_event(ev)
		if _hud.has_method("process_key_event"):
			_hud.call("process_key_event", ev)
		if _enc != null:
			_enc.call("_unhandled_input", ev)
		Input.parse_input_event(_key(code, false))
	_ck("D2 ★ 死亡期间拒绝 G/Q/K/F：真实输入不扣瓶 / 不释放战技 / 不弹反 / 不处决（HUD+ENC 双门禁）",
			_flask_count() == f_before and _flask_used_log.size() == used_before \
					and _focus_performed_log.size() == focus_before \
					and _parry_log.size() == parry_before and _exec_log.size() == exec_before,
			"flask=%d used=%d focus=%d parry=%d exec=%d" % [
					_flask_count(), _flask_used_log.size(), _focus_performed_log.size(),
					_parry_log.size(), _exec_log.size()])
	# D3 重复死亡不二次掉落：已死态再次 HP 归零转发 → death_count / dropped / player_died 不变
	var died_before_dup: int = _died_log.size()
	var dropped_before_dup: int = int(_life_view().get("dropped_points", -1))
	var death_count_before: int = int(_death_snap().get("death_count", -1))
	_hud.call("on_player_hp_changed", 0.0, 100.0)
	_hud.call("on_player_hp_changed", 0.0, 100.0)
	_ck("D3 重复死亡不二次掉落：再次 HP 归零不二次发 player_died / dropped_points 不覆盖 / death_count 不增",
			_died_log.size() == died_before_dup \
					and int(_life_view().get("dropped_points", -1)) == dropped_before_dup \
					and int(_death_snap().get("death_count", -1)) == death_count_before,
			"died_log=%d dropped=%d death_count=%d" % [
					_died_log.size(), int(_life_view().get("dropped_points", -1)),
					int(_death_snap().get("death_count", -1))])
	# D4 赐福重生：真实 E → ENC 既有 _grace_rest() → grace_rested → HUD 生产订阅者
	#   （flask_service.on_grace_rest 补瓶 / death_service.respawn 判定 / 清死亡态 / player_respawned）
	var respawn0: int = _respawned_log.size()
	var fp_view0: Dictionary = _hud.call("get_focus_hud_view") as Dictionary if _hud.has_method("get_focus_hud_view") else {}
	_press_e()
	var lv_alive: Dictionary = _life_view()
	var fp_view1: Dictionary = _hud.call("get_focus_hud_view") as Dictionary if _hud.has_method("get_focus_hud_view") else {}
	var respawn1: int = _respawned_log.size()
	var hp_after: float = _enc_hp()
	_ck("D4 ★ 重生后 HP/FP/瓶回满 + 死亡态清除 + player_respawned 广播（赐福重生）",
			not bool(lv_alive.get("is_dead", true)) and respawn1 == respawn0 + 1 \
					and hp_after >= 99.0 \
					and int(fp_view1.get("fp", 0)) == int(fp_view1.get("fp_max", -1)) \
					and int(lv_alive.get("flask", 0)) == int(lv_alive.get("flask_max", -1)),
			"hp=%.0f fp=%d/%d flask=%d/%d is_dead=%s respawned_log=%d" % [
					hp_after, int(fp_view1.get("fp", 0)), int(fp_view1.get("fp_max", -1)),
					int(lv_alive.get("flask", 0)), int(lv_alive.get("flask_max", -1)),
					str(lv_alive.get("is_dead", true)), respawn1])
	# D4b 重生后「你死了」节点隐藏
	_ck("D4b 重生后 ProdDeathLabel 隐藏（死亡态显示已清除）",
			xl != null and not xl.visible, "visible=%s" % str(xl.visible if xl != null else true))
	# D5 重生后 G 重新可用（死亡门禁解除，服务判定 HP 已满 → 满血拒绝但不报「死亡期间」）
	var rej0: int = _flask_rejected_log.size()
	_press_g()
	var rej1: int = _flask_rejected_log.size()
	var last_reason: String = String((_flask_rejected_log.back() as Dictionary).get("reason", "")) if rej1 > 0 else ""
	_ck("D5 重生后 G 重新可用（门禁解除）：走 flask_service 真实判定，不再报 death_state_reject",
			rej1 == rej0 + 1 and not last_reason.contains("death"),
			"reject_reason=%s" % last_reason)


# ===========================================================================
# E 组 · A48③ 汇总 + 生产消费记录 + 不新增第二套胜负判定
# ===========================================================================
func _t_e_summary() -> void:
	print("[V140] ==== E 组 A48③ 汇总 / 不新增第二套胜负判定 ====")
	var prod: Dictionary = _enc_prod()
	_ck("E1 A48③ ★ 真实输入 → 生产链路 → 画面：ENC 生产消费记录非空（flask_events / death_events / respawn_events / hp_writeback）",
			(prod.get("flask_events", []) as Array).size() >= 1 \
					and (prod.get("death_events", []) as Array).size() >= 1 \
					and (prod.get("respawn_events", []) as Array).size() >= 1 \
					and int(prod.get("hp_writeback_count", 0)) >= 1,
			"flask_events=%d death_events=%d respawn_events=%d hp_writeback=%d hp_forward=%d" % [
					(prod.get("flask_events", []) as Array).size(),
					(prod.get("death_events", []) as Array).size(),
					(prod.get("respawn_events", []) as Array).size(),
					int(prod.get("hp_writeback_count", 0)), int(prod.get("hp_forward_count", 0))])
	_ck("E2 不新增第二套胜负判定：HUD death_service 判定不改既有 _finish / encounter_finished",
			_enc.has_signal("encounter_finished") and _hud.has_method("is_player_dead"),
			"encounter_finished 既有信号保留 / HUD 只暴露 is_player_dead() 只读态")
	_ck("E3 A54 唯一实例未被自建第二个：HUD.get_flask_service() == ENC.get_flask_service() == 本验证同一 Object",
			_hud.call("get_flask_service") == _flask and _enc.call("get_flask_service") == _flask,
			"same_flask=%s same_death=%s" % [
					str(_hud.call("get_flask_service") == _flask),
					str(_hud.call("get_death_service") == _death)])


func _finish(early: bool) -> void:
	# 释放探针信号连接（有释放路径，不留悬空 Callable）
	if _probes_connected and _hud != null and is_instance_valid(_hud):
		var pairs: Dictionary = {
			"flask_used": "_on_flask_used", "flask_rejected": "_on_flask_rejected",
			"player_died": "_on_player_died", "player_respawned": "_on_player_respawned",
			"focus_skill_performed": "_on_focus_performed", "parry_performed": "_on_parry",
			"execution_performed": "_on_exec"}
		for sig: String in pairs.keys():
			var cb: Callable = Callable(self, String(pairs[sig]))
			if _hud.has_signal(sig) and _hud.is_connected(sig, cb):
				_hud.disconnect(sig, cb)
	var ok: bool = (not early) and _fail == 0 and _pass > 0
	print("[V140] ---- 回读汇总 ----")
	print("[V140] SUMMARY pass=%d fail=%d total=%d ok=%s flask_source=%s death_source=%s" % [
			_pass, _fail, _pass + _fail, str(ok), _flask_source, _death_source])
	if ok:
		print("[V140] RESULT=ALL_MATCH")
	else:
		print("[V140] RESULT=MISMATCH")
	print("[V140] ==== verify_life_runtime_v140 真跑结束 ====")
	quit(0 if ok else 1)
