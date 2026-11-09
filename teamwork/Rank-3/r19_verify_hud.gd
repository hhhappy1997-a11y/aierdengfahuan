extends SceneTree

## R19 · hud.gd 扩展真跑验证（Rank-3，cmd-20261109-102334-088-A3，[ROUND=R19]）
## R20 复用（裁决 A9，cmd-20261109-110237-805-A3，[ROUND=R20]）：
##   SaveDeltaWriter 已正式注册为 autoload，故 ⑫ 的登记期望由「降级=injected」反转为
##   「autoload 源、不降级」，并新增 ⑭ autoload 存在性 / ⑮ autoload commit 顺序 /
##   ⑯ 取不到 writer 时回退注入 committer 三条断言。①~⑬ 其余覆盖与编号保持不变。
## R21 复用（cmd-20261109-115818-643-A3，[ROUND=R21]）：
##   grace_fast_travel() 与 travel_to() 统一「/root/SaveDeltaWriter 优先，注入 committer
##   仅在取不到时兜底」，两入口共用 _commit_before_travel()。①~⑯ 既有覆盖与编号逐字保留，
##   追加 ⑰ grace_fast_travel autoload 优先级 / ⑱ 其 commit 顺序 /
##   ⑲ 两入口登记字段与顺序一致性 / ⑳ grace_fast_travel 取不到 writer 回退注入 committer。
## 只读：CACHE_MODE_IGNORE 强制从磁盘重读 hud.tscn / grace_network.tres → instantiate()，
##   不 pack / 不 save / 不改 hud.tscn 结构 / 不碰 courtyard.tscn / 不写任何工程文件。
##
## 验证项（①~⑯ 既有 + ⑰⑱⑲⑳ R21 新增）：
##   ① hud.tscn 脚本仍挂 res://scripts/hud.gd；② 4 个信号存在且可连接（R17 不破坏）；
##   ③ 新方法 open_grace_menu / travel_to / get_commit_status 可寻址；
##   ④ grace_network.tres 运行期读取 8 节点 / 7 边（不硬编码）；
##   ⑤ open_grace_menu() 实际 call 返回菜单数组 + 统计 8/7；
##   ⑥ R17 flag 增量刷新回归：set_flag 经 flag_changed 不触发 hud_refreshed（计数不变）；
##   ⑦ travel_to()：先 commit 后发 travel_requested 信号（autoload writer.committed 记录顺序）；
##   ⑧ autoload 已注册时 travel_to 走 autoload 源、如实登记（不降级）可经 get_commit_status 读回；
##   ⑭ autoload 存在性；⑮ autoload commit 顺序；⑯ 取不到 writer 回退注入 committer；
##   ⑰⑱ grace_fast_travel 的 autoload 优先级与 commit 顺序；⑲ 两入口口径一致性；
##   ⑳ grace_fast_travel 取不到 writer 回退注入 committer。
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
	print("[R20] ==== 裁决 A9 复用：SaveDeltaWriter 已注册 autoload，⑫ 期望反转 + 新增 ⑭⑮⑯ ====")
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
	# R20：autoload 的 SaveDeltaWriter.committed(reason) 连到同一记录回调，
	# 使「先 commit 后发信号」顺序断言能观测到 autoload 源的真实 commit。
	var writer: Node = get_root().get_node_or_null("SaveDeltaWriter")
	if writer != null and writer.has_signal("committed"):
		writer.connect("committed", Callable(self, "_on_commit"))
		print("[R20] 已连 SaveDeltaWriter.committed -> _on_commit | writer=%s" % str(writer != null))
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

	# ⑫ R20 契约：autoload 已正式注册，travel_to 走 autoload 源（不再降级）。
	# 期望值随裁决 A9 由「degraded=true/source=injected」反转为「degraded=false/source=autoload」，
	# 仍由 get_commit_status 如实读回，不伪造。
	var autoload_status_ok: bool = bool(st.get("degraded")) == false \
		and str(st.get("source")) == "autoload" \
		and str(st.get("reason")) == "grace_fast_travel" \
		and bool(st.get("ok")) == true \
		and bool(st.get("writer_registered_as_autoload")) == true \
		and bool(st.get("writer_root_exists")) == true
	_check("⑫ autoload_registration_readback", autoload_status_ok,
		"degraded=%s source=%s ok=%s writer_registered_as_autoload=%s writer_root_exists=%s" % [str(st.get("degraded")), str(st.get("source")), str(st.get("ok")), str(st.get("writer_registered_as_autoload")), str(st.get("writer_root_exists"))])

	# ⑬ 4 信号在扩展后仍完整（收尾复核，不被破坏）
	var still_ok: bool = true
	for s in ["grace_selected", "travel_confirmed", "rest_requested", "hud_refreshed"]:
		if not hud.has_signal(s):
			still_ok = false
	_check("⑬ four_signals_intact_after_extension", still_ok, "signals=%s" % str(["grace_selected", "travel_confirmed", "rest_requested", "hud_refreshed"]))

	# ===== R20 新增断言（裁决 A9：autoload 存在性 + commit 顺序 + 回退）=====
	# ⑭ autoload 存在性：注册键 + /root 节点 + commit 方法 + 脚本路径
	var w: Node = get_root().get_node_or_null("SaveDeltaWriter")
	var w_registered: bool = ProjectSettings.has_setting("autoload/SaveDeltaWriter")
	var w_has_commit: bool = w != null and w.has_method("commit")
	var w_script_path: String = "<null>"
	if w != null:
		var wscr: Script = w.get_script() as Script
		if wscr != null:
			w_script_path = wscr.resource_path
	_check("⑭ autoload_registered_and_root_node",
		w_registered and w != null and w_has_commit and w_script_path == "res://scripts/save_delta_writer.gd",
		"has_setting=%s root_node=%s has_commit=%s script=%s" % [str(w_registered), str(w != null), str(w_has_commit), w_script_path])

	# ⑮ autoload commit 顺序：travel_to 先触发 writer.committed（先落盘），
	#    再 travel_confirmed、travel_requested；writer 自身 commit_count / reason 可回读。
	var w_count: int = -1
	var w_reason: String = "<null>"
	if w != null:
		w_count = int(w.get("commit_count"))
		w_reason = str(w.get("last_commit_reason"))
	var order_15: bool = _order.size() == 3 and _order[0] == "commit" \
		and _order[1] == "signal:travel_confirmed" and _order[2] == "signal:travel_requested"
	_check("⑮ autoload_commit_before_signal_order", order_15 and w_count >= 1 and w_reason == "grace_fast_travel",
		"order=%s commit_count=%d last_reason=%s" % [str(_order), w_count, w_reason])

	# ⑯ 取不到 /root/SaveDeltaWriter 时回退注入 committer：临时把 autoload 节点移出 root，
	#    travel_to 应回退 set_fast_travel_committer 注入的 committer，如实登记降级；
	#    顺序仍 commit → travel_confirmed → travel_requested。测毕恢复现场。
	_order.clear()
	_committed_reason = ""
	var w2: Node = get_root().get_node_or_null("SaveDeltaWriter")
	if w2 != null:
		get_root().remove_child(w2)
	hud.call("travel_to", TARGET_ID)
	var st2: Dictionary = hud.call("get_commit_status")
	var fallback_ok: bool = _order.size() == 3 and _order[0] == "commit" \
		and _order.has("signal:travel_confirmed") and _order.has("signal:travel_requested") \
		and bool(st2.get("degraded")) == true and str(st2.get("source")) == "injected" \
		and bool(st2.get("ok")) == true
	_check("⑯ fallback_to_injected_when_writer_missing", fallback_ok,
		"writer_removed=%s order=%s degraded=%s source=%s" % [str(w2 != null), str(_order), str(st2.get("degraded")), str(st2.get("source"))])
	if w2 != null:
		get_root().add_child(w2)

	# ===== R21 新增断言（cmd-20261109-115818-643-A3）：两落盘编排入口口径一致性 =====
	# R20 如实登记 grace_fast_travel() 走「注入 committer 优先」旧口径；R21 起它直接
	#   调用 _commit_before_travel()，与 travel_to() 共用同一实现（_delegate_commit()
	#   亦保留为转调该实现的兼容薄委托），优先 /root/SaveDeltaWriter、注入 committer
	#   仅在取不到时兜底。以下 4 条复用本载体既有 _order / get_commit_status() 观测，
	#   不新建探针脚本、不改任何工程文件。
	print("[R21] ==== 追加 ⑰⑱⑲⑳：两落盘编排入口 autoload 优先级 / commit 顺序一致性 ====")

	# ⑰ grace_fast_travel() 正常 autoload 态：走 autoload 源、不降级（与 ⑫ travel_to 对齐）
	_order.clear()
	_committed_reason = ""
	_signal_ids.clear()
	hud.call("grace_fast_travel", TARGET_ID)
	var st_g: Dictionary = hud.call("get_commit_status")
	var g_autoload_ok: bool = bool(st_g.get("degraded")) == false \
		and str(st_g.get("source")) == "autoload" \
		and str(st_g.get("reason")) == "grace_fast_travel" \
		and bool(st_g.get("ok")) == true \
		and bool(st_g.get("writer_registered_as_autoload")) == true \
		and bool(st_g.get("writer_root_exists")) == true
	_check("⑰ grace_fast_travel_autoload_priority", g_autoload_ok,
		"degraded=%s source=%s reason=%s ok=%s writer_registered=%s writer_root_exists=%s" % [
		str(st_g.get("degraded")), str(st_g.get("source")), str(st_g.get("reason")),
		str(st_g.get("ok")), str(st_g.get("writer_registered_as_autoload")), str(st_g.get("writer_root_exists"))])

	# ⑱ grace_fast_travel() commit 顺序：commit → travel_confirmed → travel_requested
	var g_order_ok: bool = _order.size() == 3 and _order[0] == "commit" \
		and _order[1] == "signal:travel_confirmed" and _order[2] == "signal:travel_requested" \
		and _committed_reason == "grace_fast_travel"
	_check("⑱ grace_fast_travel_commit_before_signal_order", g_order_ok,
		"order=%s committed_reason=%s" % [str(_order), _committed_reason])

	# ⑲ 两入口一致性：同一 writer 态下分别调 travel_to / grace_fast_travel，
	#    对比登记字段(source/degraded/ok/reason)与调用顺序，逐项必须一致。
	_order.clear()
	_committed_reason = ""
	_signal_ids.clear()
	hud.call("travel_to", TARGET_ID)
	var st_t2: Dictionary = hud.call("get_commit_status")
	var t_order2: Array = _order.duplicate()
	_order.clear()
	_committed_reason = ""
	_signal_ids.clear()
	hud.call("grace_fast_travel", TARGET_ID)
	var st_g2: Dictionary = hud.call("get_commit_status")
	var g_order2: Array = _order.duplicate()
	var consistent: bool = t_order2 == g_order2 \
		and t_order2.size() == 3 and t_order2[0] == "commit" \
		and str(st_t2.get("source")) == str(st_g2.get("source")) \
		and bool(st_t2.get("degraded")) == bool(st_g2.get("degraded")) \
		and bool(st_t2.get("ok")) == bool(st_g2.get("ok")) \
		and str(st_t2.get("reason")) == str(st_g2.get("reason"))
	_check("⑲ two_entries_autoload_and_order_consistent", consistent,
		"travel_to[order=%s source=%s degraded=%s] grace_fast_travel[order=%s source=%s degraded=%s]" % [
		str(t_order2), str(st_t2.get("source")), str(st_t2.get("degraded")),
		str(g_order2), str(st_g2.get("source")), str(st_g2.get("degraded"))])

	# ⑳ grace_fast_travel() 取不到 /root/SaveDeltaWriter 时同样回退注入 committer（与 ⑯ 对齐）
	_order.clear()
	_committed_reason = ""
	_signal_ids.clear()
	var w3: Node = get_root().get_node_or_null("SaveDeltaWriter")
	if w3 != null:
		get_root().remove_child(w3)
	hud.call("grace_fast_travel", TARGET_ID)
	var st_g3: Dictionary = hud.call("get_commit_status")
	var g_fallback_ok: bool = bool(st_g3.get("degraded")) == true \
		and str(st_g3.get("source")) == "injected" \
		and bool(st_g3.get("ok")) == true \
		and _order.size() == 3 and _order[0] == "commit" \
		and _order[1] == "signal:travel_confirmed" and _order[2] == "signal:travel_requested"
	_check("⑳ grace_fast_travel_fallback_to_injected", g_fallback_ok,
		"writer_removed=%s order=%s degraded=%s source=%s" % [
		str(w3 != null), str(_order), str(st_g3.get("degraded")), str(st_g3.get("source"))])
	if w3 != null:
		get_root().add_child(w3)

	var ok: bool = _fail == 0
	print("[R19] ---- 回读汇总 ----")
	print("[R19] SUMMARY pass=%d fail=%d ok=%s" % [_pass, _fail, str(ok)])
	print("[R19] ==== r19_verify_hud 真跑结束 ====")
	quit(0 if ok else 1)
