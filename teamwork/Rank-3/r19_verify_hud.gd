extends SceneTree

## R19 · hud.gd 扩展真跑验证（Rank-3，cmd-20261109-102334-088-A3，[ROUND=R19]）
## 只读：CACHE_MODE_IGNORE 强制从磁盘重读 hud.tscn / grace_network.tres → instantiate()，
##   不 pack / 不 save / 不改 hud.tscn 结构 / 不碰 courtyard.tscn / 不写任何工程文件。
##
## 验证项：
##   ① hud.tscn 脚本仍挂 res://scripts/hud.gd；② 4 个信号存在且可连接（R17 不破坏）；
##   ③ 新方法 open_grace_menu / travel_to / get_commit_status 可寻址；
##   ④ grace_network.tres 运行期读取 8 节点 / 7 边（不硬编码）；
##   ⑤ open_grace_menu() 实际 call 返回菜单数组 + 统计 8/7；
##   ⑥ R17 flag 增量刷新回归：set_flag 经 flag_changed 不触发 hud_refreshed（计数不变）；
##   ⑦ travel_to()：先 commit 后发 travel_requested 信号（注入 committer 记录顺序）；
##   ⑧ SaveDeltaWriter 非 autoload 时「注入 committer + 如实登记降级」可经 get_commit_status 读回。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

const HUD_PATH: String = "res://scenes/hud.tscn"
const HUD_SCRIPT_PATH: String = "res://scripts/hud.gd"
const GRACE_PATH: String = "res://data/rpg/grace_network.tres"
const TARGET_ID: String = "grace_limgrave_gatefront"
const UNLOCKED_FLAG: String = "grace.limgrave_gatefront.unlocked"
const UNRELATED_FLAG: String = "world.verify_r19.changed"
const EXPECT_NODES: int = 8
const EXPECT_EDGES: int = 7
const WAIT_FRAMES: int = 3

var _pass: int = 0
var _fail: int = 0
var _frame: int = 0
var _hud: Node = null
var _label: Label = null
var _refresh_count: int = 0
var _order: Array[String] = []
var _committed_reason: String = ""
var _signal_ids: Array[String] = []


func _on_hud_refreshed() -> void:
	_refresh_count += 1


func _probe_str(_s: String) -> void:
	pass


func _on_commit(reason: String) -> void:
	_order.append("commit")
	_committed_reason = reason


func _on_travel_confirmed(id: String) -> void:
	_order.append("signal:travel_confirmed")
	_signal_ids.append(id)


func _on_travel_requested(id: String) -> void:
	_order.append("signal:travel_requested")
	_signal_ids.append(id)


func _check(tag: String, ok: bool, detail: String) -> void:
	print("[R19] %s PASS=%s | %s" % [tag, str(ok), detail])
	if ok:
		_pass += 1
	else:
		_fail += 1


func _initialize() -> void:
	print("[R19] ==== r19_verify_hud 真跑开始 ====")
	print("[R19] extends SceneTree | CACHE_MODE_IGNORE 只读回读，不改任何场景文件")

	# ⓪ 如实记录 autoload 注册态与 /root 子节点（降级判定依据）
	var writer_registered: bool = ProjectSettings.has_setting("autoload/SaveDeltaWriter")
	var root_names: Array = []
	for c in get_root().get_children():
		root_names.append(str(c.name))
	print("[R19] ⓪ /root children = %s" % str(root_names))
	print("[R19] ⓪ ProjectSettings.has_setting(\"autoload/SaveDeltaWriter\") = %s | /root/SaveDeltaWriter exists = %s" % [str(writer_registered), str(get_root().get_node_or_null("SaveDeltaWriter") != null)])

	# ① CACHE_MODE_IGNORE 回读 hud.tscn → instantiate()
	var packed: PackedScene = ResourceLoader.load(HUD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		print("[R19] ① scene_load FAIL | 无法加载 %s" % HUD_PATH)
		print("[R19] SUMMARY mode=ABORT pass=0 fail=1 ok=false")
		quit(1)
		return
	var hud: Node = packed.instantiate()
	_hud = hud
	_check("① scene_instantiate(CACHE_MODE_IGNORE)", hud != null, "class=%s name=%s" % [hud.get_class(), str(hud.name)])

	# ② 脚本仍挂根节点 res://scripts/hud.gd
	var scr: Script = hud.get_script() as Script
	var scr_path: String = "<null>"
	if scr != null:
		scr_path = scr.resource_path
	_check("② script_attached", scr != null and scr_path == HUD_SCRIPT_PATH, "path=%s" % scr_path)

	# ③ TitleLabel 可寻址
	var label: Label = hud.get_node_or_null("TitleLabel") as Label
	_label = label
	var init_text: String = "<null>"
	if label != null:
		init_text = label.text
	_check("③ TitleLabel", label != null, "text=%s" % init_text)

	# ④ 4 个信号存在（R17 已验证集合，不得破坏）
	var sig_names: Array[String] = ["grace_selected", "travel_confirmed", "rest_requested", "hud_refreshed"]
	var sig_ok: bool = true
	for s in sig_names:
		if not hud.has_signal(s):
			sig_ok = false
			print("[R19] ④ signal MISSING %s" % s)
	_check("④ four_signals_exist", sig_ok, "signals=%s" % str(sig_names))

	# ⑤ 4 个信号可实际连接（travel_confirmed 连记录回调，其余连探针）
	var e1: Error = hud.connect("grace_selected", Callable(self, "_probe_str"))
	var e2: Error = hud.connect("travel_confirmed", Callable(self, "_on_travel_confirmed"))
	var e3: Error = hud.connect("rest_requested", Callable(self, "_probe_str"))
	var e4: Error = hud.connect("hud_refreshed", Callable(self, "_on_hud_refreshed"))
	var conn_errs: Array = [e1, e2, e3, e4]
	var conn_ok: bool = true
	for e in conn_errs:
		if int(e) != OK:
			conn_ok = false
	if not hud.is_connected("hud_refreshed", Callable(self, "_on_hud_refreshed")):
		conn_ok = false
	_check("⑤ four_signals_connectable", conn_ok, "connect_errs=%s" % str(conn_errs))

	# ⑥ 新方法可寻址（追加式，不删 R17 的 17 个方法）
	var new_methods: Array[String] = ["open_grace_menu", "travel_to", "get_commit_status"]
	var miss: Array = []
	for m in new_methods:
		if not hud.has_method(m):
			miss.append(m)
	_check("⑥ new_methods_addressable", miss.is_empty(), "total=%d missing=%s" % [new_methods.size(), str(miss)])

	# ⑦ grace_network.tres 运行期读取 8 节点 / 7 边（CACHE_MODE_IGNORE，不硬编码）
	var net: Resource = ResourceLoader.load(GRACE_PATH, "Resource", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	var nodes_n: int = -1
	var edges_n: int = -1
	if net != null:
		var nv: Variant = net.get("nodes")
		var ev: Variant = net.get("edges")
		if typeof(nv) == TYPE_ARRAY:
			nodes_n = (nv as Array).size()
		if typeof(ev) == TYPE_ARRAY:
			edges_n = (ev as Array).size()
	_check("⑦ grace_network_8nodes_7edges", net != null and nodes_n == EXPECT_NODES and edges_n == EXPECT_EDGES,
		"path=%s nodes=%d edges=%d (期望 %d/%d)" % [GRACE_PATH, nodes_n, edges_n, EXPECT_NODES, EXPECT_EDGES])

	# 注入 committer + 连接 GameEvents.travel_requested（验证「后发信号」与顺序）
	hud.call("set_fast_travel_committer", Callable(self, "_on_commit"))
	var bus: Node = get_root().get_node_or_null("GameEvents")
	var bus_connected: bool = false
	if bus != null and bus.has_signal("travel_requested"):
		bus.connect("travel_requested", Callable(self, "_on_travel_requested"))
		bus_connected = true
	print("[R19] 已注入 committer(Callable _on_commit) | GameEvents.travel_requested connected=%s" % str(bus_connected))

	# 加入场景树；_ready() 由帧循环 flush，挂 process_frame 状态机等待（R17 时序口径）
	get_root().add_child(hud)
	print("[R19] 已 add_child(hud) | 等待 _ready() flush（WAIT_FRAMES=%d）" % WAIT_FRAMES)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	if _frame < WAIT_FRAMES:
		return
	process_frame.disconnect(_on_frame)
	_verify_after_ready()


func _verify_after_ready() -> void:
	var hud: Node = _hud
	var label: Label = _label

	# ⑧ _ready() 全量刷新基线（hud_refreshed 计数 == 1）
	var base: int = _refresh_count
	_check("⑧ ready_full_refresh_baseline", base == 1, "frames_waited=%d hud_refreshed_count=%d" % [_frame, base])

	# ⑨ open_grace_menu() 实际 call：返回菜单数组 + 运行期统计 8/7
	var menu: Variant = hud.call("open_grace_menu")
	var st0: Dictionary = hud.call("get_commit_status")
	var nc: int = int(st0.get("grace_node_count", -1))
	var ec: int = int(st0.get("grace_edge_count", -1))
	_check("⑨ open_grace_menu_call", typeof(menu) == TYPE_ARRAY and nc == EXPECT_NODES and ec == EXPECT_EDGES,
		"return_type=%d menu_open=%s node_count=%d edge_count=%d (期望 %d/%d)" % [typeof(menu), str(hud.get("menu_open")), nc, ec, EXPECT_NODES, EXPECT_EDGES])

	# ⑩ R17 flag 增量刷新回归：set_flag → flag_changed → 不 emit hud_refreshed（计数不变）
	var ws: Node = get_root().get_node_or_null("WorldState")
	var ws_ok: bool = ws != null and ws.has_method("set_flag") and ws.has_signal("flag_changed")
	var text_before: String = ""
	if label != null:
		text_before = label.text
	var col_before: Color = Color(0, 0, 0, 0)
	if label != null:
		col_before = label.get_theme_color("font_color", "Label")
	if ws_ok:
		ws.call("set_flag", UNLOCKED_FLAG, true)
		ws.call("set_flag", UNRELATED_FLAG, 1)
	var text_after: String = ""
	if label != null:
		text_after = label.text
	var col_after: Color = Color(0, 0, 0, 0)
	if label != null:
		col_after = label.get_theme_color("font_color", "Label")
	var incr_ok: bool = ws_ok and _refresh_count == base and text_after == text_before and col_after.is_equal_approx(col_before)
	_check("⑩ R17_flag_incremental_intact", incr_ok,
		"ws_ok=%s hud_refreshed_count=%d(基线=%d) text_unchanged=%s color_unchanged=%s" % [str(ws_ok), _refresh_count, base, str(text_after == text_before), str(col_after.is_equal_approx(col_before))])

	# ⑪ travel_to()：先 commit、后发 travel_requested 信号
	_order.clear()
	hud.call("travel_to", TARGET_ID)
	var st: Dictionary = hud.call("get_commit_status")
	print("[R19] ⑪ commit_status 实测 | degraded=%s source=%s reason=%s ok=%s writer_autoload=%s log=%s" % [
		str(st.get("degraded")), str(st.get("source")), str(st.get("reason")),
		str(st.get("ok")), str(st.get("writer_registered_as_autoload")), str(st.get("log"))])
	print("[R19] ⑪ 调用顺序实测 | order=%s committed_reason=%s signal_ids=%s" % [str(_order), _committed_reason, str(_signal_ids)])

	var order_ok: bool = _order.size() == 3 and _order[0] == "commit" and _order.has("signal:travel_confirmed") and _order.has("signal:travel_requested")
	_check("⑪ commit_before_signal_order", order_ok,
		"order=%s reason=%s(期望 grace_fast_travel) 先commit=%s 后travel_requested=%s" % [str(_order), _committed_reason, str(_order.size() > 0 and _order[0] == "commit"), str(_order.has("signal:travel_requested"))])

	# ⑫ 降级登记可经 get_commit_status 读回（如实，不伪造 autoload）
	var degraded_ok: bool = bool(st.get("degraded")) == true and str(st.get("source")) == "injected" and str(st.get("reason")) == "grace_fast_travel" and bool(st.get("ok")) == true and bool(st.get("writer_registered_as_autoload")) == false
	_check("⑫ degraded_registration_readback", degraded_ok,
		"degraded=%s source=%s ok=%s writer_registered_as_autoload=%s" % [str(st.get("degraded")), str(st.get("source")), str(st.get("ok")), str(st.get("writer_registered_as_autoload"))])

	# ⑬ 4 信号在扩展后仍完整（收尾复核，不被破坏）
	var still_ok: bool = true
	for s in ["grace_selected", "travel_confirmed", "rest_requested", "hud_refreshed"]:
		if not hud.has_signal(s):
			still_ok = false
	_check("⑬ four_signals_intact_after_extension", still_ok, "signals=%s" % str(["grace_selected", "travel_confirmed", "rest_requested", "hud_refreshed"]))

	var ok: bool = _fail == 0
	print("[R19] ---- 回读汇总 ----")
	print("[R19] SUMMARY pass=%d fail=%d ok=%s" % [_pass, _fail, str(ok)])
	print("[R19] ==== r19_verify_hud 真跑结束 ====")
	quit(0 if ok else 1)
