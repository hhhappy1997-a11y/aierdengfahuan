extends SceneTree
## ===========================================================================
## R32 [ROUND=R32] · v0.10.0 HUD 分区避让布局自测（Rank-1）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/render/verify_hud_layout_v100.gd
##
## 断言组：
##   A 分区包围盒两两不重叠（1280x720 基准，6 分区）
##   B Tab 互斥状态机（图鉴打开隐藏兑换 / 关闭恢复 / 抉择卡片压过一切 / 同时仅 1 个可见）
##   C 分辨率适配（1280x720 / 960x540 / 640x360 / 480x270：文字不出界且仍不重叠）
##   D 不遮中央角色（所有分区 + 抉择卡片矩形与角色保护区交集 0）
##   E 机制 A 数字键状态隔离（抉择打开时 process_key_event 数字键只走抉择、不误触兑换）
##   F 基线保护（A38 节点数 41 / 既有 4 信号 + 关键方法可寻址 / 新增 2 信号存在）
##   G 真实 Rank-2 BoonDraftService 联调（落盘则跑真实实例，未落盘如实 SKIP）
##   H R33 新增 · 真实 Tab 输入路径 → 实际节点 visible 互斥：
##     Input.parse_input_event() 注入真实 Tab 按下/松开配对，读 GraceShopLabel.visible
##     断言「图鉴打开→兑换隐藏 / 关闭→恢复 / 抉择压过一切」，既有 19 条不删不放宽
##   I R34C 新增 · 真实节点 rect 运行时断言（既有 24 条不删不放宽）：
##     注入真实 Tab（Input.parse_input_event + process_key_event）与真实命中
##     （ComboService.register_hit(10.0)）后读真实 Label 节点 get_global_rect()，
##     断言「生产机制可见层文本 vs 赐福成长标题行」不相交、「评级条 vs 其它 HUD
##     文字块」两两不相交 + 四档降级不出界/不遮角色 + A46 单一 Tab / A48 常驻保持。
##
## --script / SceneTree 纪律：不用 get_tree()、不用 /root/... 绝对路径；
##   add_child 不自动 flush _ready() → 显式 call("_ready") 后 set_process(false)；
##   资源回读 ResourceLoader.load(..., CACHE_MODE_IGNORE)；本脚本只读、不改任何工程文件。
## 输出：逐条 PASS/FAIL + SUMMARY + RESULT=ALL_MATCH（全通过）/ MISMATCH。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。
## ===========================================================================

const HUD_PATH: String = "res://scripts/hud.gd"
const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"
const NODE_COUNT_EXPECTED: int = 41
# R34C I 组：真实命中链路（只读 Rank-2 落盘件，不写、不改）。
const COMBO_SVC_PATH: String = "res://scripts/combat/combo_service.gd"
const COMBO_CFG_PATH: String = "res://data/rpg/combo_rules.tres"
const VIEWPORTS: Array[Vector2] = [
	Vector2(1280.0, 720.0), Vector2(960.0, 540.0),
	Vector2(640.0, 360.0), Vector2(480.0, 270.0)]

var _pass: int = 0
var _fail: int = 0
var _temps: Array[Node] = []
var _hud_script: Script = null
var _hud: Node = null
var _selected_count: int = 0
# R33：H 组用的真实兑换面板节点（挂到 hud 夹具下，供读实际 visible，而非只读逻辑态）。
var _shop_panel: Label = null
# R34C：I 组用的真实生产可见层连击文本节点 + 真实命中服务引用。
#   ComboService 4 信号经 _r34_connect_combo_signals() connect、由 hud._exit_tree
#   → _r34_release() → _r34_disconnect_combo_signals() 释放；本对象随脚本结束回收。
var _i_combo: Object = null
var _i_combo_label: Label = null


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V100HUD] %s PASS=%s | %s" % [tag, str(ok), detail])


func _track(n: Node) -> void:
	_temps.append(n)


func _on_selected(_index: int, _id: String) -> void:
	_selected_count += 1


func _new_hud() -> Node:
	var host: Node = Node.new()
	host.name = "HudLayoutTestHost"
	_track(host)
	root.add_child(host)
	var hud: Node = _hud_script.new() as Node
	_track(hud)
	# R33：挂一个真实兑换面板节点（hud.tscn 独立实例本无此子节点），让 _ready() 里
	#   get_node_or_null("GraceShopLabel") 真正命中，H 组才能读【实际节点 visible】。
	#   不单独 _track：它是 hud 子节点，_finish() 倒序 free(hud) 时一并释放，无双重 free。
	var shop: Label = Label.new()
	shop.name = "GraceShopLabel"
	shop.visible = false
	hud.add_child(shop)
	_shop_panel = shop
	host.add_child(hud)
	if not hud.is_node_ready():
		hud.call("_ready")
	# R34C：独立 --script 实例 _ensure_shop_readable() 判空降级不设 offset，
	#   这里按 hud 公开 get_shop_title_rect() 给赐福成长标题行真实节点补上与实机
	#   同源的定位，供 I 组读真实节点 get_global_rect()（节点本身不变，H1 仍命中）。
	var srt: Rect2 = hud.call("get_shop_title_rect") as Rect2
	_shop_panel.offset_left = srt.position.x
	_shop_panel.offset_top = srt.position.y
	_shop_panel.offset_right = srt.end.x
	_shop_panel.offset_bottom = srt.end.y
	# R34C：显式建生产可见层真实节点（--script 无 deferred bootstrap；实机由
	#   _r34_bootstrap() call_deferred 走同一入口，A48 常驻口径不变）。
	hud.call("ensure_production_visible_layer")
	hud.set_process(false)
	hud.set_process_unhandled_input(false)
	if hud.has_signal("boon_draft_selected"):
		hud.connect("boon_draft_selected", Callable(self, "_on_selected"))
	return hud


func _rect_of(entry: Variant) -> Rect2:
	if entry is Dictionary:
		return (entry as Dictionary).get("rect", Rect2()) as Rect2
	return entry as Rect2


func _worst_overlap(rects: Array) -> float:
	var worst: float = 0.0
	for i: int in range(rects.size()):
		for j: int in range(i + 1, rects.size()):
			var a: Rect2 = _rect_of(rects[i])
			var b: Rect2 = _rect_of(rects[j])
			worst = maxf(worst, a.intersection(b).get_area())
	return worst


func _in_bounds(rects: Array, vp: Vector2) -> bool:
	for e in rects:
		var r: Rect2 = _rect_of(e)
		if r.position.x < -0.001 or r.position.y < -0.001 \
				or r.end.x > vp.x + 0.001 or r.end.y > vp.y + 0.001 \
				or r.get_area() <= 0.0:
			return false
	return true


func _key(code: int) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	e.echo = false
	return e


func _initialize() -> void:
	print("[V100HUD] ==== verify_hud_layout_v100 真跑开始 | R32 v0.10.0 Rank-1 ====")
	_hud_script = ResourceLoader.load(
			HUD_PATH, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if _hud_script == null:
		print("[V100HUD] RESULT=MISMATCH（hud.gd 加载失败）")
		quit(1)
		return
	_hud = _new_hud()
	_test_partition()
	_test_tab_mutex()
	_test_viewports()
	_test_center_char()
	_test_digit_isolation()
	_test_baseline()
	_test_real_boon_draft()
	_test_real_tab_mutex()
	_test_r34c_real_rects()
	_finish()


# ---------------------------------------------------------------------------
# A) 分区包围盒两两不重叠
# ---------------------------------------------------------------------------
func _test_partition() -> void:
	var hud: Node = _hud
	hud.call("set_layout_viewport", Vector2(1280.0, 720.0))
	var rects: Array = hud.call("get_layout_rects") as Array
	var ids: Array[String] = []
	for e in rects:
		ids.append(String((e as Dictionary).get("id", "")))
	_ck("A1 6 个分区且 id 齐全（title/quality/wave/guide/status/side）",
			rects.size() == 6 and ids.has("title") and ids.has("quality") \
					and ids.has("wave") and ids.has("guide") and ids.has("status") \
					and ids.has("side"),
			"count=%d ids=%s" % [rects.size(), str(ids)])
	var worst: float = _worst_overlap(rects)
	_ck("A2 任意两处文字/面板包围盒交集面积恒 == 0（三处重叠已消除）",
			worst == 0.0, "worst_overlap=%.4f px²" % worst)
	_ck("A3 6 个分区面积 > 0 且全部落在 1280x720 内",
			_in_bounds(rects, Vector2(1280.0, 720.0)), "viewport=1280x720")


# ---------------------------------------------------------------------------
# B) Tab 互斥状态机
# ---------------------------------------------------------------------------
func _test_tab_mutex() -> void:
	var hud: Node = _hud
	hud.call("close_boon_draft")
	hud.call("set_codex_open", false)
	hud.set("shop_open", false)
	var v0: Array = hud.call("get_visible_side_panels") as Array
	_ck("B1 初始无面板常驻（visible_side_panels 为空，消除画质/成长面板同时常驻）",
			v0.is_empty(), "visible=%s" % str(v0))
	hud.set("shop_open", true)
	var v1: Array = hud.call("get_visible_side_panels") as Array
	_ck("B2 打开兑换 → 仅 shop 可见", v1.size() == 1 and v1.has("shop"),
			"visible=%s" % str(v1))
	hud.call("set_codex_open", true)
	var v2: Array = hud.call("get_visible_side_panels") as Array
	_ck("B3 Tab 图鉴打开 → 隐藏常驻兑换面板，仅 codex 可见（消除叠压）",
			v2.size() == 1 and v2.has("codex") and not v2.has("shop"),
			"visible=%s codex_open=%s" % [str(v2), str(hud.call("is_codex_open"))])
	hud.call("set_codex_open", false)
	var v3: Array = hud.call("get_visible_side_panels") as Array
	_ck("B4 Tab 图鉴关闭 → 按 shop_open 原态恢复兑换面板",
			v3.size() == 1 and v3.has("shop"), "visible=%s" % str(v3))
	hud.call("set_codex_open", true)
	var choices: Array = [{"id": "hp"}, {"id": "poise"}, {"id": "points"}]
	hud.call("show_boon_draft", choices)
	var v4: Array = hud.call("get_visible_side_panels") as Array
	_ck("B5 赐福抉择卡片压过一切，右侧同时仅 1 个面板可见（互斥）",
			v4.size() == 1 and v4.has("boon_draft"),
			"visible=%s codex_open=%s shop_open=%s" % [
					str(v4), str(hud.call("is_codex_open")), str(hud.get("shop_open"))])
	hud.call("close_boon_draft")
	hud.call("set_codex_open", false)
	hud.set("shop_open", false)


# ---------------------------------------------------------------------------
# C) 分辨率适配（含降级档）
# ---------------------------------------------------------------------------
func _test_viewports() -> void:
	var hud: Node = _hud
	var all_ok: bool = true
	var details: Array[String] = []
	for vp: Vector2 in VIEWPORTS:
		hud.call("set_layout_viewport", vp)
		var rects: Array = hud.call("get_layout_rects") as Array
		var bounded: bool = _in_bounds(rects, vp)
		var overlap: float = _worst_overlap(rects)
		var ok: bool = bounded and overlap == 0.0
		if not ok:
			all_ok = false
		details.append("%dx%d:bounded=%s overlap=%.3f" % [
				int(vp.x), int(vp.y), str(bounded), overlap])
	_ck("C1 1280x720 基准 + 960x540/640x360/480x270 三档降级：文字不出界且仍不重叠",
			all_ok, str(details))
	hud.call("set_layout_viewport", Vector2(1280.0, 720.0))


# ---------------------------------------------------------------------------
# D) 不遮中央角色
# ---------------------------------------------------------------------------
func _test_center_char() -> void:
	var hud: Node = _hud
	hud.call("set_layout_viewport", Vector2(1280.0, 720.0))
	var char_rect: Rect2 = hud.call("get_center_char_rect") as Rect2
	var rects: Array = hud.call("get_layout_rects") as Array
	var worst: float = 0.0
	for e in rects:
		worst = maxf(worst, _rect_of(e).intersection(char_rect).get_area())
	_ck("D1 6 个分区与中央角色保护区交集恒 == 0（不遮角色）",
			worst == 0.0, "worst_overlap=%.4f char=%s" % [worst, str(char_rect)])
	var bdv: Dictionary = hud.call("get_boon_draft_view") as Dictionary
	_ck("D2 赐福抉择卡片矩形与中央角色保护区不重叠",
			not bool(bdv.get("overlaps_center_char", true)),
			"overlaps=%s card_rect=%s" % [
					str(bdv.get("overlaps_center_char", "?")), str(bdv.get("rect", "?"))])


# ---------------------------------------------------------------------------
# E) 机制 A 数字键状态隔离
# ---------------------------------------------------------------------------
func _test_digit_isolation() -> void:
	var hud: Node = _hud
	_selected_count = 0
	hud.call("close_boon_draft")
	hud.call("set_codex_open", false)
	hud.set("shop_open", true)
	var ev_before: int = (hud.get("grace_purchase_events") as Array).size()
	var choices: Array = [{"id": "hp"}, {"id": "poise"}, {"id": "points"}]
	hud.call("show_boon_draft", choices)
	var consumed: bool = bool(hud.call("process_key_event", _key(KEY_1)))
	var dv: Dictionary = hud.call("get_boon_draft_view") as Dictionary
	_ck("E1 抉择卡片打开时数字键 1 被消费 → 走 boon_draft.select、卡片关闭、emit 信号",
			consumed and int(dv.get("selected_index", -1)) == 0 \
					and not bool(dv.get("open", true)) and _selected_count == 1,
			"consumed=%s selected=%d open=%s selected_signal=%d" % [
					str(consumed), int(dv.get("selected_index", -1)),
					str(dv.get("open", "?")), _selected_count])
	var ev_after: int = (hud.get("grace_purchase_events") as Array).size()
	_ck("E2 抉择数字键未误触既有兑换（grace_purchase_events 无新增）",
			ev_after == ev_before, "before=%d after=%d" % [ev_before, ev_after])
	var consumed2: bool = bool(hud.call("process_key_event", _key(KEY_2)))
	_ck("E3 卡片关闭后数字键不被 R32 拦截（交还既有兑换逻辑，状态隔离正确）",
			not consumed2, "consumed=%s" % str(consumed2))
	hud.set("shop_open", false)


# ---------------------------------------------------------------------------
# F) 基线保护
# ---------------------------------------------------------------------------
func _test_baseline() -> void:
	var text: String = FileAccess.get_file_as_string(COURTYARD_PATH)
	var count: int = 0
	for line: String in text.split("\n"):
		if line.begins_with("[node "):
			count += 1
	_ck("F1 courtyard.tscn 静态 [node] 行数 == 41（A38 保持，场景只读）",
			count == NODE_COUNT_EXPECTED, "count=%d expected=%d" % [count, NODE_COUNT_EXPECTED])
	var sigs: Array[String] = ["grace_selected", "travel_confirmed", "rest_requested",
			"hud_refreshed", "execution_performed", "boon_draft_selected"]
	var miss: Array[String] = []
	for s: String in sigs:
		if not _hud.has_signal(s):
			miss.append(s)
	_ck("F2 既有 4 信号 + 新增 2 信号（execution_performed / boon_draft_selected）齐全",
			miss.is_empty(), "missing=%s" % str(miss))
	var methods: Array[String] = ["get_hud_layout", "get_layout_rects", "set_layout_viewport",
			"set_codex_open", "get_visible_side_panels", "bind_stagger_service",
			"request_execution", "get_stagger_hud_view", "show_boon_draft",
			"_select_boon_draft", "get_boon_draft_view", "process_key_event"]
	var mmiss: Array[String] = []
	for m: String in methods:
		if not _hud.has_method(m):
			mmiss.append(m)
	_ck("F3 R32 新增关键公开 / 钩子方法可寻址",
			mmiss.is_empty(), "missing=%s" % str(mmiss))


# ---------------------------------------------------------------------------
# G) 真实 Rank-2 BoonDraftService 联调（落盘则跑真实实例；未落盘则跳过并如实登记）
# ---------------------------------------------------------------------------
func _test_real_boon_draft() -> void:
	var cfg_path: String = "res://data/rpg/boon_draft.tres"
	var svc_path: String = "res://scripts/combat/boon_draft_service.gd"
	var svc_script: Script = null
	var cfg: Resource = null
	if ResourceLoader.exists(svc_path):
		svc_script = ResourceLoader.load(svc_path, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if ResourceLoader.exists(cfg_path):
		cfg = ResourceLoader.load(cfg_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	if svc_script == null or cfg == null:
		print("[V100HUD] G 组 SKIP：Rank-2 boon_draft_service.gd / boon_draft.tres 未落盘，如实登记待复跑")
		return
	print("[V100HUD] G 组：Rank-2 真实服务已落盘 → 绑定真实 BoonDraftService 实例做联调")
	var real: Object = svc_script.new(cfg)
	_hud.call("bind_boon_draft_service", real)
	_hud.call("on_wave_cleared")
	var dv: Dictionary = _hud.call("get_boon_draft_view") as Dictionary
	var choices: Array = dv.get("choices", []) as Array
	_ck("G1 真实 BoonDraftService 绑定 + 清波钩子：卡片打开且读到 3 个真实候选",
			bool(dv.get("open", false)) and bool(dv.get("service_available", false)) \
					and choices.size() == 3,
			"open=%s service=%s choices=%d" % [
					str(dv.get("open", "?")), str(dv.get("service_available", "?")), choices.size()])
	_selected_count = 0
	var consumed: bool = bool(_hud.call("process_key_event", _key(KEY_2)))
	var dv2: Dictionary = _hud.call("get_boon_draft_view") as Dictionary
	var result: Dictionary = dv2.get("last_result", {}) as Dictionary
	_ck("G2 数字键 2 → 真实 boon_draft_service.select(1) 成功、卡片关闭、emit 信号",
			consumed and int(dv2.get("selected_index", -1)) == 1 \
					and not bool(dv2.get("open", true)) \
					and bool(result.get("ok", false)) and _selected_count == 1,
			"consumed=%s selected=%d select_ok=%s reason=%s signal=%d" % [
					str(consumed), int(dv2.get("selected_index", -1)),
					str(result.get("ok", "?")), str(result.get("reason", "?")), _selected_count])


# ---------------------------------------------------------------------------
# H) R33 · 真实 Tab 输入路径 → 实际节点 visible 互斥（本轮新增，既有 19 条不删不放宽）
#    --script 模式无 GUI 输入分发：Input.parse_input_event() 注入真实 Tab 按下/松开后，
#    再把同一事件对象喂 HUD 的 process_key_event()（与 _unhandled_input 完全相同的
#    R32 键处理路径，口径同 verify_stagger_runtime_v100.gd E 组）。
#    断言读【真实节点 GraceShopLabel.visible】，而不是只读 get_visible_side_panels()。
# ---------------------------------------------------------------------------
func _key_released(code: int) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = false
	e.echo = false
	return e


func _inject_tab_pair(hud: Node) -> bool:
	var press: InputEventKey = _key(KEY_TAB)
	var release: InputEventKey = _key_released(KEY_TAB)
	Input.parse_input_event(press)
	var consumed: bool = bool(hud.call("process_key_event", press))
	Input.parse_input_event(release)
	# 松开事件（pressed=false）经同一路径应被忽略，不再翻转状态。
	hud.call("process_key_event", release)
	return consumed


func _side_panels(hud: Node) -> Array:
	return (hud.call("get_hud_layout") as Dictionary).get("visible_side_panels", []) as Array


func _test_real_tab_mutex() -> void:
	var hud: Node = _hud
	print("[V100HUD] ==== H 组 R33 真实 Tab 输入 → 实际节点 visible 互斥 ====")
	_ck("H1 夹具含真实兑换面板节点 GraceShopLabel 且 HUD._shop_label 已绑定（可读实际 visible）",
			_shop_panel != null and is_instance_valid(_shop_panel) \
					and hud.get("_shop_label") == _shop_panel,
			"panel=%s bound=%s" % [
					str(_shop_panel != null), str(hud.get("_shop_label") == _shop_panel)])
	# 复位：关抉择 / 关图鉴 / 打开兑换并同步互斥 → 面板真实节点 visible=true
	hud.call("close_boon_draft")
	hud.call("set_codex_open", false)
	hud.set("shop_open", true)
	hud.call("apply_side_panel_visibility")
	var vis0: bool = _shop_panel.visible
	_ck("H2 初始（图鉴关闭 / shop_open=true）：真实兑换面板节点 visible=true",
			vis0, "visible=%s side=%s" % [str(vis0), str(_side_panels(hud))])
	# 注入真实 Tab 按下/松开（配对）
	var consumed1: bool = _inject_tab_pair(hud)
	var vis1: bool = _shop_panel.visible
	var side1: Array = _side_panels(hud)
	_ck("H3 真实 Tab 按下/松开后：图鉴打开、右侧仅 codex 可见、兑换面板真实节点 visible=false（互斥生效）",
			consumed1 and bool(hud.call("is_codex_open")) and not vis1 \
					and side1.size() == 1 and side1.has("codex"),
			"consumed=%s codex_open=%s shop_visible=%s side=%s" % [
					str(consumed1), str(hud.call("is_codex_open")), str(vis1), str(side1)])
	# 再注入一次 Tab（关闭）→ 恢复
	var consumed2: bool = _inject_tab_pair(hud)
	var vis2: bool = _shop_panel.visible
	var side2: Array = _side_panels(hud)
	_ck("H4 真实 Tab 再按下/松开后：图鉴关闭、兑换面板真实节点 visible=true（关闭恢复原态）",
			consumed2 and not bool(hud.call("is_codex_open")) and vis2 \
					and side2.size() == 1 and side2.has("shop"),
			"consumed=%s codex_open=%s shop_visible=%s side=%s" % [
					str(consumed2), str(hud.call("is_codex_open")), str(vis2), str(side2)])
	# 赐福抉择优先级：卡片打开时兑换真实节点仍 hidden、右侧仅 boon_draft
	hud.call("show_boon_draft", [{"id": "hp"}, {"id": "poise"}, {"id": "points"}])
	var vis3: bool = _shop_panel.visible
	var side3: Array = _side_panels(hud)
	_ck("H5 赐福抉择卡片打开时真实兑换节点仍隐藏、右侧仅 boon_draft 可见（互斥优先级）",
			not vis3 and side3.size() == 1 and side3.has("boon_draft"),
			"shop_visible=%s side=%s" % [str(vis3), str(side3)])
	# 恢复干净态（不影响后续 _finish 释放）
	hud.call("close_boon_draft")
	hud.call("set_codex_open", false)
	hud.set("shop_open", false)


# ---------------------------------------------------------------------------
# I) R34C · 真实节点 rect 运行时断言（任务 2，既有 24 条不删不放宽）
#   --script 模式注入真实 Tab（Input.parse_input_event + process_key_event，同 H 组
#   路径）与真实命中（ComboService.register_hit），后者 emit combo_changed →
#   hud._r34_on_combo_changed → _r34_refresh_visible() 刷新真实节点文本 / visible。
#   断言全部读【真实 Label 节点 get_global_rect()】，不只读逻辑态 Rect2 字典。
# ---------------------------------------------------------------------------
func _i_rect_of(n: Control) -> Rect2:
	return n.get_global_rect()


func _test_r34c_real_rects() -> void:
	var hud: Node = _hud
	print("[V100HUD] ==== I 组 R34C 真实节点 rect 运行时断言（Tab + 命中注入） ====")
	hud.call("set_layout_viewport", Vector2(1280.0, 720.0))
	# 复位：关抉择 / 关图鉴 / 打开兑换 → 赐福成长标题行真实节点 visible=true
	hud.call("close_boon_draft")
	hud.call("set_codex_open", false)
	hud.set("shop_open", true)
	hud.call("apply_side_panel_visibility")

	# ---- 真实命中注入：真实 ComboService + 真实 combo_rules.tres ----
	var combo_script: Script = ResourceLoader.load(
			COMBO_SVC_PATH, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
	var cfg: Resource = null
	if ResourceLoader.exists(COMBO_CFG_PATH):
		cfg = ResourceLoader.load(COMBO_CFG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	var hit_ok: bool = false
	if combo_script != null and cfg != null:
		_i_combo = combo_script.new(cfg)
		if _i_combo != null:
			hud.call("bind_combo_service", _i_combo)
			hud.call("_r34_connect_combo_signals")
			var hr: Dictionary = _i_combo.call("register_hit", 10.0) as Dictionary
			hit_ok = bool(hr.get("ok", false))
	# 命中信号回调内已 _r34_refresh_visible()；--script 无 _process 帧循环，
	#   显式再刷一次（等价生产帧末），随后读真实节点状态 / rect。
	hud.call("_r34_refresh_visible")
	_i_combo_label = hud.get("_r34_combo_label") as Label
	var combo_node_ok: bool = _i_combo_label != null and is_instance_valid(_i_combo_label)
	var combo_text: String = _i_combo_label.text if combo_node_ok else ""
	_ck("I1 真实命中（ComboService.register_hit）后生产机制连击文本真实节点常驻可见且文本含连击/评级/倍率",
			hit_ok and combo_node_ok and _i_combo_label.visible \
					and combo_text.contains("连击") and combo_text.contains("评级") \
					and combo_text.contains("倍率"),
			"hit_ok=%s node=%s visible=%s text=%s" % [
					str(hit_ok), str(combo_node_ok),
					str(_i_combo_label.visible) if combo_node_ok else "?", combo_text])

	# ---- I2 真实节点 rect：生产机制可见层文本 vs 赐福成长标题行 ----
	var shop_node: Label = hud.get("_shop_label") as Label
	var shop_ok: bool = shop_node != null and is_instance_valid(shop_node) \
			and shop_node == _shop_panel
	var cr: Rect2 = _i_rect_of(_i_combo_label) if combo_node_ok else Rect2()
	var sr: Rect2 = _i_rect_of(shop_node) if shop_ok else Rect2()
	var overlap_cs: float = cr.intersection(sr).get_area()
	_ck("I2 真实节点 rect：生产机制可见层文本 vs 赐福成长标题行交集面积恒 == 0（R34B 叠压已消除）",
			combo_node_ok and shop_ok and overlap_cs == 0.0,
			"combo_rect=%s shop_rect=%s overlap=%.4f px²" % [str(cr), str(sr), overlap_cs])

	# ---- I3 评级条锚点 rect vs 其它 HUD 文字块（6 分区 + 赐福成长标题行）----
	var cmb: Rect2 = hud.call("get_production_mechanism_rect") as Rect2
	var blocks: Array = hud.call("get_layout_rects") as Array
	var blocks2: Array = []
	for e in blocks:
		blocks2.append(_rect_of(e))
	blocks2.append(hud.call("get_shop_title_rect") as Rect2)
	var worst: float = 0.0
	for b in blocks2:
		worst = maxf(worst, cmb.intersection(b as Rect2).get_area())
	_ck("I3 评级条（生产机制独立分区）vs 其它 HUD 文字块（title/quality/wave/guide/status/side + 赐福成长标题行）两两不相交",
			worst == 0.0 and cmb.get_area() > 0.0,
			"combo_anchor=%s blocks=%d worst_overlap=%.4f px²" % [
					str(cmb), blocks2.size(), worst])

	# ---- I4 真实节点按锚点定位（非硬编码像素堆叠）----
	var same: bool = combo_node_ok and cr.is_equal_approx(cmb)
	_ck("I4 连击文本真实节点 rect 与独立分区锚点 rect 一致（按锚点定位，不硬编码像素堆叠）",
			same, "node_rect=%s anchor_rect=%s" % [str(cr), str(cmb)])

	# ---- I5 真实 Tab 注入：A46 单一仲裁者 + A48 生产可见层常驻 ----
	var consumed1: bool = _inject_tab_pair(hud)
	hud.call("_r34_refresh_visible")
	var shop_hidden: bool = shop_ok and not shop_node.visible
	var combo_still: bool = combo_node_ok and _i_combo_label.visible
	var side1: Array = _side_panels(hud)
	_ck("I5 真实 Tab 打开图鉴后：赐福成长标题行真实节点隐藏、连击文本仍常驻可见、右侧仅 codex（A46/A48）",
			consumed1 and bool(hud.call("is_codex_open")) and shop_hidden and combo_still \
					and side1.size() == 1 and side1.has("codex"),
			"consumed=%s codex_open=%s shop_hidden=%s combo_visible=%s side=%s" % [
					str(consumed1), str(hud.call("is_codex_open")), str(shop_hidden),
					str(combo_still), str(side1)])
	var consumed2: bool = _inject_tab_pair(hud)
	_ck("I5b 真实 Tab 再注入关闭图鉴 → 赐福成长标题行恢复可见（互斥关闭恢复）",
			consumed2 and not bool(hud.call("is_codex_open")) \
					and shop_ok and shop_node.visible,
			"consumed=%s codex_open=%s shop_visible=%s" % [
					str(consumed2), str(hud.call("is_codex_open")),
					str(shop_node.visible) if shop_ok else "?"])

	# ---- I6 四档降级：真实连击节点不出界 / 不遮中央角色 / 不与赐福成长标题行相交 ----
	var all_ok: bool = true
	var details: Array[String] = []
	for vp: Vector2 in VIEWPORTS:
		hud.call("set_layout_viewport", vp)
		var r2: Rect2 = _i_rect_of(_i_combo_label) if combo_node_ok else Rect2()
		var chr: Rect2 = hud.call("get_center_char_rect") as Rect2
		var sh: Rect2 = hud.call("get_shop_title_rect") as Rect2
		var bounded: bool = r2.position.x >= -0.001 and r2.position.y >= -0.001 \
				and r2.end.x <= vp.x + 0.001 and r2.end.y <= vp.y + 0.001 \
				and r2.get_area() > 0.0
		var ok: bool = bounded and r2.intersection(chr).get_area() == 0.0 \
				and r2.intersection(sh).get_area() == 0.0
		if not ok:
			all_ok = false
		details.append("%dx%d:rect=%s bounded=%s char_ov=%.2f shop_ov=%.2f" % [
				int(vp.x), int(vp.y), str(r2), str(bounded),
				r2.intersection(chr).get_area(), r2.intersection(sh).get_area()])
	_ck("I6 1280x720 + 三档降级：真实连击节点不出界 / 不遮中央角色 / 不与赐福成长标题行相交",
			all_ok, str(details))
	hud.call("set_layout_viewport", Vector2(1280.0, 720.0))
	# 恢复干净态（不影响后续 _finish 释放）
	hud.call("close_boon_draft")
	hud.call("set_codex_open", false)
	hud.set("shop_open", false)


func _finish() -> void:
	for i: int in range(_temps.size() - 1, -1, -1):
		var n: Node = _temps[i]
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	var ok: bool = _fail == 0 and _pass > 0
	print("[V100HUD] ---- 回读汇总 ----")
	print("[V100HUD] SUMMARY pass=%d fail=%d total=%d ok=%s" % [
			_pass, _fail, _pass + _fail, str(ok)])
	if ok:
		print("[V100HUD] RESULT=ALL_MATCH")
	else:
		print("[V100HUD] RESULT=MISMATCH")
	print("[V100HUD] ==== verify_hud_layout_v100 真跑结束 ====")
	quit(0 if ok else 1)
