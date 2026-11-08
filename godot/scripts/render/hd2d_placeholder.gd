extends Node2D
## HD-2D 程序化 _draw() 占位（R6 装配 · 零外部依赖）
## 来源：Rank-4/hd2d_placeholder.md §2 / §4.6、hd2d_placeholder_r5_params.json、
##       hd2d_placeholder_params.json（R2 冻结 18 键）、HD-2D视觉规范.md §3 / §4 / §7。
## 定位：M0 构图 / 景深 / 冷暖对比验证的占位兜底。ComfyUI 仍是主美术路线，
##       qwen-image 仅本地零付费备选，本脚本不取代二者、不宣称已能出图。
## 约束：单节点、单次 _draw() 内按 10 步顺序绘制；不加载任何 PNG / 贴图 / 插件 /
##       云服务 / 付费 API；实体坐标 round() 到整数，禁止亚像素位移与非整数缩放。
## 退出：assets/generated/bg_layers/ 与 chars/ 有首批合规 spritesheet 且 1 号完成
##       纹理层接入后，逐层把占位绘制替换为 draw_texture_rect() / Sprite 节点；
##       placeholder_enabled 保留为调试开关，不再作为默认画面。

# ---------------------------------------------------------------------------
# 画布：640×360 逻辑缓冲 + 整数倍（2/3/4）Nearest 放大
# ---------------------------------------------------------------------------
const BUFFER_W := 640.0
const BUFFER_H := 360.0
const SKY_BANDS := 64
const GROUND_Y := 250.0
const PLACEHOLDER_SEED := 20261108

@export var placeholder_enabled: bool = true
@export var integer_scale: int = 3
@export var cam_x: float = 0.0
@export var cam_y: float = 0.0
@export var light_pos: Vector2 = Vector2(452.0, 92.0)

# ---------------------------------------------------------------------------
# 视差系数（9 层，对齐 hd2d_placeholder.md §3.2 / 冻结参数表 depth.parallax）
# ---------------------------------------------------------------------------
const P_SKY := 0.05
const P_FAR := 0.15
const P_MID := 0.35
const P_NEAR := 0.70
const P_FX_BACK := 0.45
const P_ENTITY := 1.00
const P_FX_FRONT := 1.00
const P_OCCL := 1.25
const P_UI := 0.00

# 色板：palette_256.json colors[0..15]，单角色 ≤16 色
var PALETTE_HEX: Array[String] = [
	"#FFF0C2", "#FFD27A", "#F0A94C", "#C97A2E", "#8A5A22",
	"#BFD0EA", "#7E96BF", "#4A6089", "#2B3A5C", "#16233F", "#0B1226",
	"#1F3A63", "#16294A", "#0E1B33", "#080F1F", "#E8C479"
]

# 32×32 像素实体色板索引阵列：字符 '0'-'9'/'a'-'f' -> 索引 0..15，'.' = 透明。
# 锚点 (16,31)：脚底像素位于 py=31。1px 轮廓取索引 10（#0B1226）。
var ENTITY_ROWS: Array[String] = [
	"................................",
	"................................",
	"................................",
	"................................",
	".............aaaaaa.............",
	"............a888888a............",
	"............a888888a............",
	"............a222222a............",
	"...........a22222222a...........",
	"............a2a222aa............",
	"............a222222a............",
	"............a222222a............",
	".............a2222a.............",
	".........aaaa777777aaaa.........",
	".........a877777777778a.........",
	".........aa7777777777aa.........",
	".........a.a77777777a.a.........",
	".........a.a77777777a.a.........",
	".........a.a77777777a.a.........",
	".........a.a77777777a.a.........",
	".........a.affffffffa.a.........",
	".........a.a77777777a.a.........",
	".........a.a77777777a.a.........",
	".........a.a77777777a.a.........",
	"............a888888a............",
	"............a888888a............",
	"............a888888a............",
	"............a888888a............",
	"............a888888a............",
	"...........aaaaaaaaaa...........",
	"...........aaaaaaaaaa...........",
	"...........aaaaaaaaaa..........."
]

var _palette: Array[Color] = []
var _motes_far: Array[Dictionary] = []    # 远景冷白光尘（确定性 seed）
var _motes_near: Array[Dictionary] = []   # 近景暖金光尘


func _ready() -> void:
	_palette.clear()
	for h in PALETTE_HEX:
		_palette.append(Color(h))
	_build_motes()
	_apply_integer_scale()


func _apply_integer_scale() -> void:
	var s := clampi(integer_scale, 2, 4)
	scale = Vector2(float(s), float(s))
	# 逻辑缓冲 640×360 以整数倍 Nearest 放大。1 号接入纹理层时改为
	# SubViewport 低分辨率渲染 + TextureRect(Nearest)，届时整体替换本节点。


func _build_motes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = PLACEHOLDER_SEED
	_motes_far.clear()
	for i in range(48):
		_motes_far.append({
			"x0": rng.randf_range(0.0, BUFFER_W),
			"y0": rng.randf_range(0.0, BUFFER_H),
			"phase": rng.randf_range(0.0, TAU),
			"freq": rng.randf_range(TAU / 4.0, TAU / 2.0),   # 横摆周期 2~4 s
			"speed": rng.randf_range(2.0, 6.0),                # 上飘 2~6 px/s
			"size": rng.randf_range(1.0, 3.0)
		})
	_motes_near.clear()
	for i in range(32):
		_motes_near.append({
			"x0": rng.randf_range(0.0, BUFFER_W),
			"y0": rng.randf_range(0.0, BUFFER_H),
			"phase": rng.randf_range(0.0, TAU),
			"freq": rng.randf_range(TAU / 4.0, TAU / 2.0),
			"speed": rng.randf_range(2.0, 6.0),
			"size": rng.randf_range(1.0, 3.0)
		})


func _process(_delta: float) -> void:
	if placeholder_enabled:
		queue_redraw()


func _draw() -> void:
	if not placeholder_enabled:
		return
	var t := Time.get_ticks_msec() / 1000.0
	# 10 步绘制顺序（§2）：9 个视差层 + 1 步湿地倒影（reflection 属 bg_3_near 内效果）
	_pass_01_sky()
	_pass_02_far()
	_pass_03_mid()
	_pass_04_near()
	_pass_05_fx_back(t)
	_pass_06_reflection(t)
	_pass_07_entity()
	_pass_08_fx_front(t)
	_pass_09_occl()
	_pass_10_ui()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------------------------
# 共用辅助
# ---------------------------------------------------------------------------
func _set_parallax(coefficient: float, vertical: bool = false) -> void:
	var ox := float(round(-cam_x * coefficient))
	var oy := 0.0
	if vertical:
		oy = float(round(-cam_y * coefficient * 0.3))
	draw_set_transform(Vector2(ox, oy), 0.0, Vector2.ONE)


func _c(hex_color: String, a: float) -> Color:
	var c := Color(hex_color)
	c.a = a
	return c


func _c_palette_alpha(idx: int, a: float) -> Color:
	var c := _palette[idx]
	c.a = a
	return c


func _hex_char_to_index(ch: String) -> int:
	return "0123456789abcdef".find(ch)


func _collect_entity_blocks() -> Array[Dictionary]:
	var blocks: Array[Dictionary] = []
	var origin_x := BUFFER_W * 0.5 - 16.0    # 锚点 x=16 对齐屏幕中心
	var origin_y := GROUND_Y - 31.0          # py=31 -> 屏幕 y=GROUND_Y
	for py in range(32):
		var row: String = ENTITY_ROWS[py]
		for px in range(32):
			var ch: String = row[px]
			if ch == ".":
				continue
			blocks.append({
				"x": origin_x + float(px),
				"y": origin_y + float(py),
				"idx": _hex_char_to_index(ch)
			})
	return blocks


# ---------------------------------------------------------------------------
# Step 1 · bg_0_sky：天空 64 条横向色带渐变 + 黄金树辉光晕
# ---------------------------------------------------------------------------
func _pass_01_sky() -> void:
	_set_parallax(P_SKY, true)
	var top := Color("#16233F")
	var bot := Color("#2B3A5C")
	var band_h := BUFFER_H / float(SKY_BANDS)
	for i in range(SKY_BANDS):
		var w := float(i) / float(SKY_BANDS - 1)
		var c := Color(
			top.r + (bot.r - top.r) * w,
			top.g + (bot.g - top.g) * w,
			top.b + (bot.b - top.b) * w
		)
		draw_rect(Rect2(-64.0, float(i) * band_h, BUFFER_W + 128.0, band_h + 1.0), c)
	for i in range(3):
		draw_circle(light_pos, 60.0 + float(i) * 34.0, _c("#FFD27A", 0.05))


# ---------------------------------------------------------------------------
# Step 2 · bg_1_far：远山 / 黄金树剪影 + 低 alpha 冷雾矩形
# ---------------------------------------------------------------------------
func _pass_02_far() -> void:
	_set_parallax(P_FAR, true)
	var ridge := PackedVector2Array([
		Vector2(-64.0, 250.0), Vector2(-64.0, 196.0),
		Vector2(90.0, 168.0), Vector2(210.0, 205.0),
		Vector2(340.0, 150.0), Vector2(470.0, 198.0),
		Vector2(640.0, 160.0), Vector2(704.0, 205.0),
		Vector2(704.0, 250.0)
	])
	draw_colored_polygon(ridge, _c("#2B3A5C", 0.85))
	draw_rect(Rect2(446.0, 120.0, 12.0, 130.0), _c("#8A5A22", 0.9))
	draw_circle(Vector2(452.0, 110.0), 42.0, _c("#FFD27A", 0.16))
	draw_circle(Vector2(452.0, 110.0), 24.0, _c("#FFF0C2", 0.14))
	draw_rect(Rect2(-64.0, 170.0, BUFFER_W + 128.0, 90.0), _c("#BFD0EA", 0.10))


# ---------------------------------------------------------------------------
# Step 3 · bg_2_mid：中景崖体 / 林地 + 上缘 1px 受光亮边
# ---------------------------------------------------------------------------
func _pass_03_mid() -> void:
	_set_parallax(P_MID)
	var cliff := PackedVector2Array([
		Vector2(-64.0, 250.0), Vector2(-64.0, 210.0),
		Vector2(60.0, 214.0), Vector2(150.0, 236.0),
		Vector2(300.0, 206.0), Vector2(430.0, 232.0),
		Vector2(560.0, 200.0), Vector2(704.0, 224.0),
		Vector2(704.0, 250.0)
	])
	draw_colored_polygon(cliff, Color("#16233F"))
	for i in range(1, cliff.size()):
		draw_line(cliff[i - 1], cliff[i], _c("#FFD27A", 0.35), 1.0)
	for i in range(6):
		draw_rect(Rect2(20.0 + float(i) * 108.0, 208.0, 34.0, 42.0), _c("#0E1B33", 0.8))


# ---------------------------------------------------------------------------
# Step 4 · bg_3_near：地平线以下地面带 + 湿地 mask 标记
# ---------------------------------------------------------------------------
func _pass_04_near() -> void:
	_set_parallax(P_NEAR)
	draw_rect(Rect2(-64.0, GROUND_Y, BUFFER_W + 128.0, BUFFER_H - GROUND_Y + 64.0), Color("#29251F"))
	draw_rect(Rect2(-64.0, GROUND_Y + 2.0, BUFFER_W + 128.0, 72.0), _c("#16233F", 0.55))
	for i in range(9):
		draw_rect(Rect2(-64.0, GROUND_Y + 6.0 + float(i) * 7.0, BUFFER_W + 128.0, 1.0), _c("#FFD27A", 0.06))


# ---------------------------------------------------------------------------
# Step 5 · fx_0_back：体积光 God Rays（4 层扇形）+ 远景冷白光尘
# ---------------------------------------------------------------------------
func _pass_05_fx_back(t: float) -> void:
	_set_parallax(P_FX_BACK)
	var godray_alpha: Array[float] = [0.18, 0.12, 0.07, 0.04]
	for i in range(godray_alpha.size()):
		var spread := 40.0 + float(i) * 46.0
		var bottom := GROUND_Y + 30.0
		var poly := PackedVector2Array([
			light_pos,
			Vector2(light_pos.x - spread, bottom),
			Vector2(light_pos.x + spread, bottom)
		])
		# _draw() 无逐调用 Add 混合参数，用低 alpha 多次叠加近似径向光束衰减
		draw_colored_polygon(poly, _c("#FFD27A", godray_alpha[i]))
	for m in _motes_far:
		var y := fposmod(float(m["y0"]) - float(m["speed"]) * t, BUFFER_H)
		var x := float(m["x0"]) + sin(t * float(m["freq"]) + float(m["phase"])) * 3.0
		draw_circle(Vector2(float(round(x)), float(round(y))), float(m["size"]), _c("#BFD0EA", 0.25))


# ---------------------------------------------------------------------------
# Step 6 · reflection：湿地倒影（挂在 bg_3_near 湿地区，不单独计层）
# ---------------------------------------------------------------------------
func _pass_06_reflection(t: float) -> void:
	_set_parallax(P_NEAR)
	var blocks := _collect_entity_blocks()
	for b in blocks:
		var sy: float = float(b["y"])
		var y_mirror := 2.0 * GROUND_Y - sy - 1.0        # 脚底 Y 对齐的垂直镜像
		var y_ref := GROUND_Y + (y_mirror - GROUND_Y) * 0.70   # 高度压缩 0.70
		var ripple_dx := sin(t + y_ref) * 0.03 * BUFFER_W      # 逐行横向错位模拟水波
		draw_rect(Rect2(float(round(float(b["x"]) + ripple_dx)), float(round(y_ref)), 1.0, 1.0),
				_c_palette_alpha(int(b["idx"]), 0.35))


# ---------------------------------------------------------------------------
# Step 7 · entity：32×32 像素人形色板索引阵列，锚点 (16,31)
# ---------------------------------------------------------------------------
func _pass_07_entity() -> void:
	_set_parallax(P_ENTITY)
	var blocks := _collect_entity_blocks()
	for b in blocks:
		draw_rect(Rect2(float(round(float(b["x"]))), float(round(float(b["y"]))), 1.0, 1.0),
				_palette[int(b["idx"])])


# ---------------------------------------------------------------------------
# Step 8 · fx_1_front：近景暖金光尘 + 同心圆近似 bloom
# ---------------------------------------------------------------------------
func _pass_08_fx_front(t: float) -> void:
	_set_parallax(P_FX_FRONT)
	var radii: Array[float] = [4.0, 8.0, 14.0, 22.0, 32.0]
	var alphas: Array[float] = [0.20, 0.12, 0.07, 0.04, 0.02]
	# 只让暖金高光过阈；冷夜雾保持不发亮（threshold=0.95 的几何近似）
	for i in range(radii.size()):
		draw_circle(light_pos, radii[i], _c("#FFD27A", alphas[i]))
	for m in _motes_near:
		var y := fposmod(float(m["y0"]) - float(m["speed"]) * t, BUFFER_H)
		var x := float(m["x0"]) + sin(t * float(m["freq"]) + float(m["phase"])) * 3.0
		draw_circle(Vector2(float(round(x)), float(round(y))), float(m["size"]), _c("#FFD27A", 0.45))


# ---------------------------------------------------------------------------
# Step 9 · fg_0_occl：前景草丛 / 柱剪影，压暗制造纵深
# ---------------------------------------------------------------------------
func _pass_09_occl() -> void:
	_set_parallax(P_OCCL)
	var left := PackedVector2Array([
		Vector2(-64.0, 360.0), Vector2(-64.0, 250.0),
		Vector2(28.0, 268.0), Vector2(52.0, 320.0),
		Vector2(74.0, 360.0)
	])
	draw_colored_polygon(left, _c("#0B1226", 0.9))
	var right := PackedVector2Array([
		Vector2(704.0, 360.0), Vector2(704.0, 236.0),
		Vector2(612.0, 262.0), Vector2(586.0, 322.0),
		Vector2(566.0, 360.0)
	])
	draw_colored_polygon(right, _c("#0B1226", 0.9))


# ---------------------------------------------------------------------------
# Step 10 · ui：金线深蓝底板 + 1px 金线描边 + 角饰（系数 0，屏幕固定）
# ---------------------------------------------------------------------------
func _pass_10_ui() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var m := 8.0
	var pw := 176.0
	var ph := 52.0
	var px := BUFFER_W - pw - m
	var py := m
	draw_rect(Rect2(px, py, pw, ph), _c("#0E1B33", 0.92))
	var gold := "#E8C479"
	draw_rect(Rect2(px, py, pw, 1.0), Color(gold))
	draw_rect(Rect2(px, py + ph - 1.0, pw, 1.0), Color(gold))
	draw_rect(Rect2(px, py, 1.0, ph), Color(gold))
	draw_rect(Rect2(px + pw - 1.0, py, 1.0, ph), Color(gold))
	var corners: Array[Vector2] = [
		Vector2(px, py), Vector2(px + pw - 8.0, py),
		Vector2(px, py + ph - 8.0), Vector2(px + pw - 8.0, py + ph - 8.0)
	]
	for c in corners:
		draw_rect(Rect2(c.x, c.y, 8.0, 8.0), _c(gold, 0.9))
	# 文本用点阵方块示意
	for i in range(10):
		draw_rect(Rect2(px + 16.0 + float(i) * 12.0, py + 18.0, 6.0, 6.0), _c("#FFF0C2", 0.8))
