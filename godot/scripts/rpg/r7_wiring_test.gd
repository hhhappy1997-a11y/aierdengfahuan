extends Node

## R7 · Rank-3 RPG 层跨模块联调验证载体（工程根 res:// 内实跑）。
## 运行在真实工程根（--path godot），用落位后的正确路径手工实例化 3 号 autoload 语义节点，
## 不写 project.godot、不改任何既有交付件；只经 I-1（WorldState.get_flag / set_flag）与世界状态交互，
## 不直接读写存档文件做业务依赖（落盘产物只作验收读取）、不构造 SaveDelta、不启动任何 GPU job。
## 中文 UTF-8；Godot 4 合法语法。输出统一 W7_ 前缀，便于 grep 归因（与引擎日志区分）。

const WS_PATH: String = "res://scripts/rpg/world_state.gd"
const GE_PATH: String = "res://scripts/rpg/game_events.gd"
const SDW_PATH: String = "res://scripts/rpg/save_delta_writer.gd"
const BRIDGE_PATH: String = "res://scripts/rpg/chunk_world_bridge.gd"
const RUNNER_PATH: String = "res://scripts/rpg/dialogue_runner.gd"
const GRACE_PATH: String = "res://data/rpg/grace_network.tres"
const BINDINGS_PATH: String = "res://data/rpg/m6_area_bindings.tres"
const DIALOGUE_PATH: String = "res://data/rpg/dialogue_and_quest.tres"
const KEY_TABLE_PATH: String = "res://data/rpg/voice_key_table.json"
const DELTA_PATH: String = "user://saves/slot_01/delta.json"

var _pass: int = 0
var _fail: int = 0
var _ws: Node = null
var _events: Node = null
var _writer: Node = null
var _bridge: Node = null
var _runner: Node = null
var _opened: bool = false


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
		print("W7_PASS %s | %s" % [tag, detail])
	else:
		_fail += 1
		print("W7_FAIL %s | %s" % [tag, detail])


func _on_dialogue_opened(graph_id: String, trigger_source: String) -> void:
	_opened = true
	print("W7_EVT dialogue_opened graph=%s trigger=%s" % [graph_id, trigger_source])


func _spawn(path: String, nm: String) -> Node:
	# 优先复用 Rank-1 已注册的 autoload 单例；缺失才按正确落位路径补位（不改 project.godot）
	# 双实例会导致各节点 _ready() 拿到的 /root/WorldState 与联调用的 _ws 不是同一对象
	var existing: Node = get_tree().root.get_node_or_null(NodePath(nm)) as Node
	if existing != null:
		print("W7_DIAG reuse /root/%s (autoload already registered)" % nm)
		return existing
	var s: GDScript = load(path) as GDScript
	var n: Node = s.new()
	n.name = nm
	get_tree().root.add_child(n)   # add_child 触发 _ready()
	print("W7_DIAG spawn /root/%s from %s" % [nm, path])
	return n


func _read_delta() -> Dictionary:
	if not FileAccess.file_exists(DELTA_PATH):
		return {}
	var f: FileAccess = FileAccess.open(DELTA_PATH, FileAccess.READ)
	if f == null:
		return {}
	var t: String = f.get_as_text()
	f.close()
	var p: Variant = JSON.parse_string(t)
	if typeof(p) != TYPE_DICTIONARY:
		return {}
	return p as Dictionary


func _edge_pass(edges: Array, from_id: String, to_id: String) -> bool:
	for e in edges:
		var d: Dictionary = e as Dictionary
		if String(d.get("from", "")) != from_id or String(d.get("to", "")) != to_id:
			continue
		var req: Dictionary = d.get("requires_flags", {}) as Dictionary
		for k in req.keys():
			var got: Variant = _ws.call("get_flag", String(k), false)
			if got != req[k]:
				return false
		return true
	return false


func _graphs_list(main: DialogueGraph) -> Array:
	var out: Array = [main]
	for lg in main.linked_graphs:
		var g: DialogueGraph = lg as DialogueGraph
		if g != null:
			out.append(g)
	return out


func _node_has_line(graphs: Array, gid: String, nid: String, lid: String) -> bool:
	for gr in graphs:
		var g: DialogueGraph = gr as DialogueGraph
		if g.graph_id != gid:
			continue
		for n in g.nodes:
			var dn: DialogueNode = n as DialogueNode
			if dn.node_id != nid:
				continue
			for l in dn.lines:
				var dl: DialogueLine = l as DialogueLine
				if dl.line_id == lid:
					return true
	return false


# ======================================================================
# T2 · SaveDelta / WorldState 与 ChunkManager 的 flag 读写联调（三段式、只经 I-1）
# ======================================================================
func _t_flags() -> void:
	var chunk_id: String = "chunk_limgrave_0_0"
	var raw: String = "chunk.%s.loaded" % chunk_id                       # Rank-1 r4 原始口径
	var norm: String = ChunkWorldBridge.normalize_chunk_flag(chunk_id)  # 3 号归一：world.chunk_limgrave_0_0.loaded
	_ck("T2_RAW_INVALID", not ChunkWorldBridge.is_valid_flag_key(raw), "raw=%s I-1_three_segment=false" % raw)
	_ck("T2_NORM_VALID", ChunkWorldBridge.is_valid_flag_key(norm), "norm=%s I-1_three_segment=true" % norm)

	# 原始口径经 I-1 写入：WorldState 对非法首段 push_warning 并忽略（此 1 条 WARNING 为预期拒绝、非缺陷）
	_ws.call("set_flag", raw, true)
	# 归一后经 I-1 写入：成功
	_ws.call("set_flag", norm, true)
	var norm_read: Variant = _ws.call("get_flag", norm, false)
	_ck("T2_NORM_WRITTEN", norm_read == true, "get_flag(norm,false)=%s" % str(norm_read))

	# ChunkManager._apply_world_flags 的只读收集入口（I-1 纯读）
	var collected: Dictionary = _bridge.call("collect_world_flags", [raw, norm, "no.dot.key"])
	var cv: Variant = collected.get(norm, "<missing>")
	_ck("T2_COLLECT", collected.has(norm) and cv == true, "collected=%s norm_val=%s" % [str(collected), str(cv)])

	# SaveDelta 静态合并类与 WorldState 口径一致：M4 timestamp 升序回放（seq 与 timestamp 反序）
	var lines_ts: Array = [
		{"seq": 1, "written_at_unix": 300, "flags": {"world.x.v": "BY_TS_LATE"}},
		{"seq": 2, "written_at_unix": 100, "flags": {"world.x.v": "BY_TS_EARLY"}}
	]
	var m_ts: Dictionary = SaveDelta.replay(SaveDelta.baseline_delta(), lines_ts)
	var mf_ts: Dictionary = m_ts.get("flags", {}) as Dictionary
	_ck("T2_SD_TS_ORDER", String(mf_ts.get("world.x.v", "")) == "BY_TS_LATE", "timestamp ascending beats seq order")
	# M1 集合并集只增不减
	var lines_union: Array = [
		{"seq": 1, "written_at_unix": 100, "spawns": {"defeated": ["e1"], "epoch": 1}},
		{"seq": 2, "written_at_unix": 200, "spawns": {"defeated": ["e2"], "epoch": 2}}
	]
	var m_union: Dictionary = SaveDelta.replay(SaveDelta.baseline_delta(), lines_union)
	var sp: Dictionary = m_union.get("spawns", {}) as Dictionary
	var defeated: Array = sp.get("defeated", []) as Array
	_ck("T2_SD_UNION", defeated.has("e1") and defeated.has("e2") and int(sp.get("epoch", 0)) == 2, "defeated union=%s epoch=%d" % [str(defeated), int(sp.get("epoch", 0))])

	# 加载边界 → 强制落盘（dungeon_enter）：ChunkWorldBridge → SaveDeltaWriter.commit → WorldState._commit_delta → 原子写
	_events.emit_signal("dungeon_transition_requested", "dungeon_01_bellvault", "enter")
	print("W7_DIAG after_dungeon_emit delta_exists=%s user_dir=%s" % [str(FileAccess.file_exists(DELTA_PATH)), OS.get_user_data_dir()])
	var delta: Dictionary = _read_delta()
	_ck("T2_DELTA_WRITTEN", not delta.is_empty(), "delta.json parsed after dungeon_enter commit")
	if not delta.is_empty():
		var fl: Dictionary = delta.get("flags", {}) as Dictionary
		_ck("T2_RAW_ABSENT", not fl.has(raw), "chunk.* raw key NOT persisted (I-1 rejected)")
		_ck("T2_NORM_PRESENT", fl.has(norm) and fl[norm] == true, "world.*.loaded present in delta flags")
		var meta: Dictionary = delta.get("meta", {}) as Dictionary
		_ck("T2_COMMIT_REASON", String(meta.get("last_commit_reason", "")) == "dungeon_enter", "reason=%s" % String(meta.get("last_commit_reason", "")))


# ======================================================================
# T3 · M6 赐福传送网络：工程根内实跑一次传送流程（6 区域 / 8 赐福覆盖）
# ======================================================================
func _t_m6() -> void:
	var net: Resource = ResourceLoader.load(GRACE_PATH)
	var binds: Resource = ResourceLoader.load(BINDINGS_PATH)
	_ck("T3_LOAD", net != null and binds != null, "grace_network=%s m6_bindings=%s" % [str(net != null), str(binds != null)])
	if net == null or binds == null:
		return
	var gn: GraceNetwork = net as GraceNetwork
	var mb: M6AreaBindings = binds as M6AreaBindings
	var nodes: Array = gn.nodes
	var edges: Array = gn.edges
	var blist: Array = mb.bindings
	_ck("T3_NODES_8", nodes.size() == 8, "grace_nodes=%d" % nodes.size())
	_ck("T3_EDGES_7", edges.size() == 7, "edges=%d" % edges.size())
	_ck("T3_AREAS_6", blist.size() == 6, "area_bindings=%d" % blist.size())

	var area_ids: Array = []
	var bound_graces: Array = []
	for b in blist:
		var d: Dictionary = b as Dictionary
		area_ids.append(String(d.get("area_id", "")))
		for g in (d.get("grace_ids", []) as Array):
			bound_graces.append(String(g))
	var node_graces: Array = []
	var node_areas: Array = []
	var flags_ok: bool = true
	for n in nodes:
		var gnode: GraceNode = n as GraceNode
		node_graces.append(gnode.grace_id)
		node_areas.append(gnode.area_id)
		if not ChunkWorldBridge.is_valid_flag_key(gnode.lit_flag) or not ChunkWorldBridge.is_valid_flag_key(gnode.unlocked_flag):
			flags_ok = false
	var all_areas: bool = true
	for a in node_areas:
		if not area_ids.has(a):
			all_areas = false
	var all_graces: bool = true
	for g in node_graces:
		if not bound_graces.has(g):
			all_graces = false
	_ck("T3_COVER_AREAS", all_areas and area_ids.size() == 6, "6/6 areas cover every node.area_id")
	_ck("T3_COVER_GRACES", all_graces and bound_graces.size() == 8, "8/8 graces bound=%d" % bound_graces.size())
	_ck("T3_FLAGS_3SEG", flags_ok, "all lit/unlocked flags are I-1 three-segment")

	# 一次完整传送流程：grace_limgrave_gatefront -> grace_limgrave_chapel（该边 requires_flags={}）
	var from_id: String = "grace_limgrave_gatefront"
	var to_id: String = "grace_limgrave_chapel"
	_ck("T3_EDGE_OPEN", _edge_pass(edges, from_id, to_id), "%s -> %s edge has no prerequisites" % [from_id, to_id])
	# 落点 flag 经 I-1 写入
	_ws.call("set_flag", "grace.network.last_grace_id", to_id)
	# 传送边界信号 → ChunkWorldBridge._on_travel_requested → SaveDeltaWriter.commit(reason=grace_fast_travel) → 原子写
	_events.emit_signal("travel_requested", to_id)
	print("W7_DIAG after_travel_emit delta_exists=%s" % str(FileAccess.file_exists(DELTA_PATH)))
	var landed: Variant = _ws.call("get_flag", "grace.network.last_grace_id", "")
	_ck("T3_LANDING_FLAG", landed == to_id, "last_grace_id=%s" % str(landed))
	var delta: Dictionary = _read_delta()
	_ck("T3_DELTA_EXISTS", not delta.is_empty(), "delta.json parsed after grace_fast_travel commit")
	if not delta.is_empty():
		var meta: Dictionary = delta.get("meta", {}) as Dictionary
		_ck("T3_COMMIT_REASON", String(meta.get("last_commit_reason", "")) == "grace_fast_travel", "reason=%s" % String(meta.get("last_commit_reason", "")))
		var fl: Dictionary = delta.get("flags", {}) as Dictionary
		_ck("T3_DELTA_FLAGS", fl.has("grace.network.last_grace_id"), "delta flags=%s" % str(fl.keys()))

	# 带前置门控的边：gatefront -> weeping_shore requires world.limgrave_bridge_01.crossed（运行期求值、不缓存）
	var pre: String = "world.limgrave_bridge_01.crossed"
	_ck("T3_GATE_BEFORE", bool(_ws.call("get_flag", pre, false)) == false, "before: %s=false" % pre)
	_ws.call("set_flag", pre, true)
	_ck("T3_GATE_AFTER", bool(_ws.call("get_flag", pre, false)) == true, "after set_flag: %s=true" % pre)
	_ck("T3_GATE_EDGE_PASS", _edge_pass(edges, from_id, "grace_weeping_shore"), "conditional edge now passable")
	# Boss 门控边未满足 → 保持不可传送
	_ck("T3_GATE_LOCKED", not _edge_pass(edges, "grace_limgrave_chapel", "grace_stormveil_gate"), "boss-gated edge stays locked")


# ======================================================================
# T4 · 语音键表与对话节点运行期触发验证（沿用 3 个 WAV，不启动 GPU job）
# ======================================================================
func _t_voice() -> void:
	var binder: VoiceLineBinder = VoiceLineBinder.new()   # 自动 load_key_table(res://data/rpg/voice_key_table.json)
	_ck("T4_BIND_COUNT", binder.bound_count() == 3, "key_table_bound=%d (expect 3)" % binder.bound_count())

	var graph: Resource = ResourceLoader.load(DIALOGUE_PATH)
	_ck("T4_GRAPH_LOAD", graph != null, "dialogue_and_quest.tres loaded=%s" % str(graph != null))
	var kt: FileAccess = FileAccess.open(KEY_TABLE_PATH, FileAccess.READ)
	_ck("T4_KEYTABLE_OPEN", kt != null, "voice_key_table.json opened=%s" % str(kt != null))
	if graph == null or kt == null:
		return
	var kt_root: Dictionary = JSON.parse_string(kt.get_as_text()) as Dictionary
	kt.close()
	var entries: Array = kt_root.get("entries", []) as Array
	var g: DialogueGraph = graph as DialogueGraph
	var graphs: Array = _graphs_list(g)

	# cross_check：3 条键表条目的 line_id / graph_id 必须都在真实对话资源里
	var valid_lines: Array = []
	var valid_graphs: Array = []
	for gr in graphs:
		var gg: DialogueGraph = gr as DialogueGraph
		valid_graphs.append(gg.graph_id)
		for n in gg.nodes:
			var dn: DialogueNode = n as DialogueNode
			for l in dn.lines:
				valid_lines.append((l as DialogueLine).line_id)
	var cc: Dictionary = VoiceLineBinder.cross_check(entries, valid_lines, valid_graphs)
	_ck("T4_CROSS_LINES", (cc.get("missing_lines", []) as Array).is_empty(), "missing_lines=%s" % str(cc.get("missing_lines", [])))
	_ck("T4_CROSS_GRAPHS", (cc.get("missing_graphs", []) as Array).is_empty(), "missing_graphs=%s" % str(cc.get("missing_graphs", [])))

	# 运行期触发链：graph/node/line 三元组 -> res_path -> 对话节点真实存在 -> WAV 运行期加载（沿用 R3 产物）
	for raw_e in entries:
		var e: Dictionary = raw_e as Dictionary
		var gid: String = String(e.get("graph_id", ""))
		var nid: String = String(e.get("node_id", ""))
		var lid: String = String(e.get("line_id", ""))
		var res_path: String = binder.resolve_voice_for(gid, nid, lid)
		_ck("T4_RESOLVE", not res_path.is_empty(), "%s -> %s" % [lid, res_path])
		_ck("T4_NODE_LINE", _node_has_line(graphs, gid, nid, lid), "%s exists in graph=%s node=%s" % [lid, gid, nid])
		var stream: Resource = ResourceLoader.load(res_path)
		var wav_ok: bool = stream != null and stream is AudioStream
		_ck("T4_WAV_LOAD", wav_ok, "%s loaded_as=%s" % [res_path, ("AudioStream" if wav_ok else "NULL")])
		var wf: FileAccess = FileAccess.open(res_path, FileAccess.READ)
		var sz: int = int(wf.get_length()) if wf != null else -1
		if wf != null:
			wf.close()
		_ck("T4_WAV_BYTES", sz == int(e.get("bytes", -1)), "%s bytes=%d expect=%d" % [lid, sz, int(e.get("bytes", -1))])

	# 对话运行器运行期触发：open_graph -> dialogue_opened 信号 -> on_enter_flags 经 I-1 写回
	_opened = false
	_runner.call("open_graph", "graph_npc_bellkeeper", "npc_talk", "npc_01_bellkeeper")
	_ck("T4_RUNNER_OPEN", _opened, "dialogue_opened emitted (trigger_source=npc_talk)")
	var met: Variant = _ws.call("get_flag", "world.npc_01_bellkeeper.met", false)
	_ck("T4_ONENTER_FLAG", met == true, "on_enter_flags wrote world.npc_01_bellkeeper.met=%s via I-1" % str(met))


func _cleanup() -> void:
	# 清除本载体在 user:// 产生的运行时存档产物（验收已在读取之后完成）
	var d: DirAccess = DirAccess.open("user://saves/slot_01")
	if d == null:
		return
	for fn in d.get_files():
		d.remove(fn)


func _ready() -> void:
	# 场景树初始化期间 root 正忙（add_child / 绝对路径 get_node 会被拒），延迟一帧再装配
	call_deferred("_run_all")


func _run_all() -> void:
	# 用落位后的正确路径手工实例化 3 号 autoload 语义节点（不改 project.godot；顺序保证 _ready 依赖就绪）
	_ws = _spawn(WS_PATH, "WorldState")
	_events = _spawn(GE_PATH, "GameEvents")
	_writer = _spawn(SDW_PATH, "SaveDeltaWriter")
	_bridge = _spawn(BRIDGE_PATH, "ChunkWorldBridge")
	_runner = _spawn(RUNNER_PATH, "DialogueRunner")
	_runner.connect("dialogue_opened", Callable(self, "_on_dialogue_opened"))
	await get_tree().process_frame   # 等全部节点 _ready() 完成后再联调
	print("W7_DIAG /root/WorldState resolvable: bridge=%s writer=%s runner=%s" % [
		str(_bridge.get_node_or_null("/root/WorldState") != null),
		str(_writer.get_node_or_null("/root/WorldState") != null),
		str(_runner.get_node_or_null("/root/WorldState") != null)])
	print("W7_DIAG members bridge.ws=%s bridge.writer=%s writer.ws=%s writer.bus=%s runner.ws=%s" % [
		str(_bridge.get("_ws") != null), str(_bridge.get("_writer") != null),
		str(_writer.get("_ws") != null), str(_writer.get("_bus") != null),
		str(_runner.get("_ws") != null)])

	_t_flags()
	_t_m6()
	_t_voice()
	print("W7_SUMMARY pass=%d fail=%d" % [_pass, _fail])
	_cleanup()
	get_tree().quit()
