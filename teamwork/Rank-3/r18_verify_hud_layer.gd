extends SceneTree

## R18 · hud.tscn 回读校验载体（临时，落在 Rank-3 工位，不写工程内任何文件）。
## CACHE_MODE_IGNORE 强制从磁盘重读 res://scenes/hud.tscn → instantiate()，
## 回读并断言 5 项：根 CanvasLayer.layer / Panel 背景色(深蓝且 alpha=1 不透明) /
## 金色 1px 四边边框 / TitleLabel 金色文字 / hud.gd 仍挂根节点。
## 只读：不 pack、不 save、不 add_child、不写文件。

const HUD_PATH: String = "res://scenes/hud.tscn"
const SCRIPT_PATH: String = "res://scripts/hud.gd"
const EXPECT_LAYER: int = 20

const EXPECT_BG: Color = Color(0.07, 0.1, 0.16, 1.0)       # 深蓝底，不透明
const EXPECT_GOLD: Color = Color(0.83, 0.68, 0.3, 1.0)     # 金色：边框 / 文字

func _initialize() -> void:
	var pass_count: int = 0
	var fail_count: int = 0

	print("[R18] ==== hud.tscn 回读校验（CACHE_MODE_IGNORE）开始 ====")
	print("[R18] HUD_PATH=%s | cache_mode=CACHE_MODE_IGNORE" % HUD_PATH)

	var packed: PackedScene = ResourceLoader.load(HUD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		print("[R18] ① scene_loaded FAIL=true | 无法加载 %s" % HUD_PATH)
		print("[R18] SUMMARY pass=0 fail=1 ok=false")
		quit(1)
		return
	print("[R18] ① scene_loaded PASS=true | class=PackedScene")

	var root: Node = packed.instantiate()

	# ② 根节点为 CanvasLayer 且 layer == 20（FX 层 layer=10 之上）
	var root_is_canvas: bool = root is CanvasLayer
	var layer_val: int = -2147483648
	if root_is_canvas:
		layer_val = (root as CanvasLayer).layer
	var layer_ok: bool = root_is_canvas and layer_val == EXPECT_LAYER
	print("[R18] ② root_CanvasLayer_layer PASS=%s | class=%s name=%s layer=%d (期望 %d)" % [str(layer_ok), root.get_class(), str(root.name), layer_val, EXPECT_LAYER])
	if layer_ok:
		pass_count += 1
	else:
		fail_count += 1

	# ③ hud.gd 仍挂根节点
	var scr: Script = root.get_script() as Script
	var scr_path: String = "<null>"
	if scr != null:
		scr_path = scr.resource_path
	var script_ok: bool = scr != null and scr.resource_path == SCRIPT_PATH
	print("[R18] ③ script_attached PASS=%s | path=%s" % [str(script_ok), scr_path])
	if script_ok:
		pass_count += 1
	else:
		fail_count += 1

	# ④ Panel 背景色：StyleBoxFlat.bg_color 深蓝且 alpha=1 不透明
	var panel: Node = root.get_node_or_null("HudPanel")
	var sb: StyleBoxFlat = null
	if panel != null:
		sb = panel.get("theme_override_styles/panel") as StyleBoxFlat
	var bg: Color = Color(0, 0, 0, 0)
	var bg_ok: bool = false
	if sb != null:
		bg = sb.bg_color
		bg_ok = bg.is_equal_approx(EXPECT_BG) and is_equal_approx(bg.a, 1.0)
	print("[R18] ④ panel_bg_color PASS=%s | bg_color=%s alpha=%.2f (期望深蓝不透明 %s)" % [str(bg_ok), str(bg), bg.a, str(EXPECT_BG)])
	if bg_ok:
		pass_count += 1
	else:
		fail_count += 1

	# ⑤ 边框色：金色
	var border: Color = Color(0, 0, 0, 0)
	var border_ok: bool = false
	if sb != null:
		border = sb.border_color
		border_ok = border.is_equal_approx(EXPECT_GOLD)
	print("[R18] ⑤ border_color PASS=%s | border_color=%s (期望金色 %s)" % [str(border_ok), str(border), str(EXPECT_GOLD)])
	if border_ok:
		pass_count += 1
	else:
		fail_count += 1

	# ⑥ 四边 1px 边框
	var bw: Array[int] = [-1, -1, -1, -1]
	if sb != null:
		bw = [sb.border_width_left, sb.border_width_top, sb.border_width_right, sb.border_width_bottom]
	var bw_ok: bool = bw[0] == 1 and bw[1] == 1 and bw[2] == 1 and bw[3] == 1
	print("[R18] ⑥ border_width_1px PASS=%s | L/T/R/B=%d/%d/%d/%d (期望 1/1/1/1)" % [str(bw_ok), bw[0], bw[1], bw[2], bw[3]])
	if bw_ok:
		pass_count += 1
	else:
		fail_count += 1

	# ⑦ TitleLabel 文字色：金色
	var label: Node = root.get_node_or_null("TitleLabel")
	var fc: Color = Color(0, 0, 0, 0)
	var fc_ok: bool = false
	if label != null:
		var override_color: Variant = label.get("theme_override_colors/font_color")
		if override_color is Color:
			fc = override_color
			fc_ok = fc.is_equal_approx(EXPECT_GOLD)
	print("[R18] ⑦ font_color PASS=%s | font_color=%s (期望金色 %s)" % [str(fc_ok), str(fc), str(EXPECT_GOLD)])
	if fc_ok:
		pass_count += 1
	else:
		fail_count += 1

	var ok: bool = fail_count == 0
	print("[R18] ---- 回读汇总 ----")
	print("[R18] SUMMARY pass=%d fail=%d ok=%s" % [pass_count, fail_count, str(ok)])
	print("[R18] ==== hud.tscn 回读校验结束 ====")
	# 不 add_child：避免 hud.gd::_ready() 运行期 apply_lit_state 改写落盘金色 override；
	# 显式 free() 让 TextServer / Canvas RID 与 sub-resource 正常回收，退出无残留 ERROR。
	root.free()
	quit(0 if ok else 1)
