extends SceneTree
## R13 · 最小「金线深蓝」HUD 场景生成器 + CACHE_MODE_IGNORE 回读校验
## 真跑（Godot 4.7.2）：
##   godot --headless --path godot --script res://scripts/build_hud.gd
##
## 纯程序化、零外部素材：仅用内置 CanvasLayer / Panel(StyleBoxFlat) / Label，
## 不加载任何贴图、字体、外部主题资源；不接入 courtyard.tscn 或其它主场景。
##
## 生成结构（根节点直接子节点数 = 2）：
##   Hud (CanvasLayer)
##   ├── HudPanel   (Panel)  深蓝底 Color(0.07,0.10,0.16) + 金色 1px 边框
##   └── TitleLabel (Label)  金色中文文字占位「赐福 · 宁姆格福」
##
## 校验（_verify，用 ResourceLoader.CACHE_MODE_IGNORE 强制忽略缓存、从磁盘重读）：
##   ① 根节点为 CanvasLayer  ② 子节点数  ③ Panel 样式边框色为金色  ④ Label 存在

const OUT_PATH: String = "res://scenes/hud.tscn"
const DEEP_BLUE: Color = Color(0.07, 0.10, 0.16, 1.0)
const GOLD: Color = Color(0.83, 0.68, 0.30, 1.0)
const GOLD_TEXT: String = "赐福 · 宁姆格福"
const EXPECTED_CHILD_COUNT: int = 2
const EXPECTED_BORDER_WIDTH: int = 1

var _pass_count: int = 0
var _fail_count: int = 0


func _initialize() -> void:
	var root: CanvasLayer = CanvasLayer.new()
	root.name = "Hud"

	var panel: Panel = _make_panel()
	var label: Label = _make_label()

	# 先叶子后父级：add_child 后设 owner，保证 PackedScene.pack() 完整保留子节点
	root.add_child(panel)
	panel.owner = root
	root.add_child(label)
	label.owner = root

	var child_count: int = root.get_child_count()
	var node_count: int = _count_nodes(root)

	var packed: PackedScene = PackedScene.new()
	var pack_err: int = packed.pack(root)
	if pack_err != OK:
		push_error("[HUD] PackedScene.pack() 失败 err=%d，拒绝保存" % pack_err)
		_free_tree(root)
		quit(1)
		return

	var probe: Node = packed.instantiate()
	var probe_nodes: int = _count_nodes(probe)
	_free_tree(probe)
	if probe_nodes != node_count:
		push_error("[HUD] 节点数比对失败 expected=%d actual=%d，拒绝保存" % [node_count, probe_nodes])
		_free_tree(root)
		quit(1)
		return

	var save_err: int = ResourceSaver.save(packed, OUT_PATH)
	_free_tree(root)
	if save_err != OK:
		push_error("[HUD] ResourceSaver.save() 失败 err=%d path=%s" % [save_err, OUT_PATH])
		quit(1)
		return

	print("[HUD] BUILD_OK path=%s child_count=%d node_count=%d pack_err=%d save_err=%d"
			% [OUT_PATH, child_count, node_count, pack_err, save_err])

	var ok: bool = _verify()
	print("[HUD] VERIFY_SUMMARY pass=%d fail=%d ok=%s" % [_pass_count, _fail_count, ok])
	quit(0 if ok else 1)


func _make_panel() -> Panel:
	var panel: Panel = Panel.new()
	panel.name = "HudPanel"
	panel.position = Vector2(24.0, 24.0)
	panel.size = Vector2(340.0, 84.0)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = DEEP_BLUE
	sb.border_width_left = EXPECTED_BORDER_WIDTH
	sb.border_width_top = EXPECTED_BORDER_WIDTH
	sb.border_width_right = EXPECTED_BORDER_WIDTH
	sb.border_width_bottom = EXPECTED_BORDER_WIDTH
	sb.border_color = GOLD
	panel.add_theme_stylebox_override("panel", sb)
	return panel


func _make_label() -> Label:
	var label: Label = Label.new()
	label.name = "TitleLabel"
	label.text = GOLD_TEXT
	label.position = Vector2(44.0, 44.0)
	label.size = Vector2(300.0, 40.0)
	label.add_theme_color_override("font_color", GOLD)
	label.add_theme_font_size_override("font_size", 20)
	return label


func _verify() -> bool:
	# CACHE_MODE_IGNORE：不走资源缓存，强制从磁盘重新读取刚保存的 .tscn，
	# 确保校验对象是真正落盘的场景文件，而非内存里刚 pack 出的对象。
	var ps: PackedScene = ResourceLoader.load(
			OUT_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if ps == null:
		push_error("[HUD_VERIFY] CACHE_MODE_IGNORE 回读失败 path=%s" % OUT_PATH)
		return false

	var inst: Node = ps.instantiate()

	# ① 根节点为 CanvasLayer
	_check("① root_is_CanvasLayer", inst is CanvasLayer,
			"root=%s class=%s" % [inst.name, inst.get_class()])

	# ② 子节点数
	var children: int = inst.get_child_count()
	_check("② child_count", children == EXPECTED_CHILD_COUNT,
			"child_count=%d expected=%d names=%s"
			% [children, EXPECTED_CHILD_COUNT, _child_names(inst)])

	# ③ Panel 的样式边框色为金色（且 1px 边框齐全）
	var panel: Panel = inst.get_node_or_null("HudPanel") as Panel
	var sb: StyleBoxFlat = null
	if panel != null:
		sb = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null and panel != null:
		sb = panel.get("theme_override_styles/panel") as StyleBoxFlat
	var gold_ok: bool = false
	var width_ok: bool = false
	var c3_detail: String = "panel_or_stylebox_missing"
	if sb != null:
		var bc: Color = sb.border_color
		gold_ok = _color_approx(bc, GOLD)
		width_ok = (sb.border_width_left == EXPECTED_BORDER_WIDTH
				and sb.border_width_top == EXPECTED_BORDER_WIDTH
				and sb.border_width_right == EXPECTED_BORDER_WIDTH
				and sb.border_width_bottom == EXPECTED_BORDER_WIDTH)
		c3_detail = "bg=(%.3f,%.3f,%.3f) border_color=(%.3f,%.3f,%.3f) gold=(%.3f,%.3f,%.3f) widths=(%d,%d,%d,%d)" % [
				sb.bg_color.r, sb.bg_color.g, sb.bg_color.b,
				bc.r, bc.g, bc.b,
				GOLD.r, GOLD.g, GOLD.b,
				sb.border_width_left, sb.border_width_top,
				sb.border_width_right, sb.border_width_bottom]
	_check("③ panel_border_gold_1px", gold_ok and width_ok, c3_detail)

	# ④ Label 存在（中文占位文字 + 金色字色）
	var label: Label = inst.get_node_or_null("TitleLabel") as Label
	var label_ok: bool = false
	var c4_detail: String = "label_missing"
	if label != null:
		var fc: Color = label.get_theme_color("font_color")
		c4_detail = "text=%s font_color=(%.3f,%.3f,%.3f) color_gold_ok=%s" % [
				label.text, fc.r, fc.g, fc.b, _color_approx(fc, GOLD)]
		label_ok = (label.text == GOLD_TEXT) and _color_approx(fc, GOLD)
	_check("④ label_exists", label_ok, c4_detail)

	inst.free()
	return _fail_count == 0


func _check(label: String, ok: bool, detail: String) -> void:
	if ok:
		_pass_count += 1
	else:
		_fail_count += 1
	print("[HUD_VERIFY] %s PASS=%s | %s" % [label, ok, detail])


func _color_approx(a: Color, b: Color) -> bool:
	# .tscn 序列化 Color 为十进制文本再解析会有浮点误差，按容差比对
	return (absf(a.r - b.r) < 0.002 and absf(a.g - b.g) < 0.002
			and absf(a.b - b.b) < 0.002 and absf(a.a - b.a) < 0.002)


func _child_names(n: Node) -> String:
	var names: PackedStringArray = PackedStringArray()
	for c in n.get_children():
		names.append(str(c.name))
	return str(names)


func _count_nodes(n: Node) -> int:
	var total: int = 1
	for c in n.get_children():
		total += _count_nodes(c)
	return total


func _free_tree(n: Node) -> void:
	for c in n.get_children():
		_free_tree(c)
	n.free()
