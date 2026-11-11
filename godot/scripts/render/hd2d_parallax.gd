extends Node2D
## R23 · 程序化多层视差远景（CanvasLayer _draw() 层 · 零外部依赖）
## 派单 cmd-20261109-133602-469-A1 · [ROUND=R23] · AI=1（Rank-1 引擎架构与渲染）
## 定位：把 R22「亮蓝白天调 / 无平滑多层景深」整改到《八方旅人》HD-2D 口径——
##   深蓝夜空 + 冷夜雾带 + 远景山影 3 层视差 + 平滑景深 + 分层光尘 + 地面冷夜压暗，
##   与 courtyard.tscn 的 3D 暖金地面 / AnimatedSprite3D 像素精灵形成
##   「像素精灵 vs 平滑景深」「暖金光 vs 冷夜雾」强对比。
## R23 目视回看精修（首版 r23_night 抓帧 ViewImage 后）：
##   ① 山影改深蓝剪影 + 远/近雾带分置山影两侧，解决首版「雾带盖住山脊、层次不明显」；
##   ② 新增 _draw_ground_grade()：3D 暖金砖地之上叠冷蓝渐变压暗，消除首版「地面过亮、白天感残留」；
##   ③ 去掉首版独立暖金辉光点：hd2d_fx.gd 的体积光/bloom 已提供暖金主光，且其坐标不随
##      SubViewport 档位缩放（Rank-4 独占、本轮不改），重复画会在 high 档出现双光源错位。
## 零外部依赖：单节点 _draw() 内全部 draw_rect / draw_colored_polygon / draw_circle /
##   draw_line 程序化绘制，零 PNG / 零贴图 / 零插件 / 零云服务 / 零付费 API / 零 autoload。
## 不回退：不改动 hd2d_fx.gd 既有四项光效（体积光/光尘/倒影/bloom）、不碰 HUD layer=20 /
##   quality_settings layer=40；本层是 SubViewport 内 layer=5 的纯远景叠加层。
## 自适应：按 640×360 设计缓冲绘制，_draw() 内按 get_viewport().size 等比缩放，
##   low/medium/high（SubViewport 426×240 / 640×360 / 1280×720）三档均铺满、不溢出。
## 光尘避让：沿用 hd2d_fx.gd 冻结 HUD 屏幕矩形 x<730,y<220 逐粒跳过，避免面板被点状遮挡。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 实体坐标 round() 到整数、Nearest 过滤。

const BUFFER_W: float = 640.0
const BUFFER_H: float = 360.0
const HORIZON_Y: float = 96.0           # 地平线（设计坐标），其下留给 3D 地面 / 像素精灵
const SEED: int = 20261109
const SKY_BANDS: int = 64
const GROUND_BANDS: int = 8

# ---------------------------------------------------------------------------
# R27 v0.5.0 · 三波空间节奏（wave_index=1/2/3 · 派单 cmd-20261111-083350-249-A4）
# 按波次让「远景色带 / 雾密度 / 地面色调」产生可辨差异，零新增素材、零 GPU job：
#   波1 冷夜起始（原 R23 基准）；波2 深紫浓雾（雾×1.75 / 地面压暗×1.40 / 山影振幅×1.30）；
#   波3 暖紫雾散（雾×0.60 / 地面偏暖且更亮×0.70 / 山影振幅×0.80 / 地平线暖金高光）。
# [PLACEHOLDER] 下列色带 / 雾 / 地面数值为演示节奏，待试玩校准；
#   rationale：三波需在同一场景内靠程序化 2D _draw() 呈现可辨空间变化，不碰素材 PNG / SpriteFrames。
# ---------------------------------------------------------------------------
const WAVE_SKY_TOP: Array = ["#04081A", "#050A20", "#1A0C22"]
const WAVE_SKY_BOT: Array = ["#142B56", "#1E2A58", "#4A2846"]
const WAVE_FOG_MULT: Array = [1.0, 1.75, 0.60]
const WAVE_FOG_COLOR: Array = ["#7E96BF", "#8E96C8", "#C08A6A"]
const WAVE_GROUND_COLOR: Array = ["#0A1836", "#12164A", "#2A1428"]
const WAVE_GROUND_MULT: Array = [1.0, 1.40, 0.70]
const WAVE_RIDGE_AMP: Array = [1.0, 1.30, 0.80]
const WAVE_HORIZON_GLOW: Array = [0.18, 0.10, 0.34]

# 三层远景山影视差系数（远→近，漂移幅度递增，制造平滑景深）
const P_RIDGE_FAR: float = 0.06
const P_RIDGE_MID: float = 0.14
const P_RIDGE_NEAR: float = 0.26

# HUD 避让（屏幕坐标，沿用 hd2d_fx.gd 冻结口径）
const HUD_AVOID_W: float = 730.0
const HUD_AVOID_H: float = 220.0
const LOGICAL_TO_SCREEN: float = 2.0
const HUD_AVOID_MARGIN: float = 6.0

var _far_motes: Array[Dictionary] = []
var _near_motes: Array[Dictionary] = []
var _stars: Array[Dictionary] = []

# R27 三波状态：wave_index 对外只读展示；_wave_override>=1 时为 presentation.gd 显式驱动；
# _w 是 _draw() 内当帧生效波（1-based）。未显式驱动时自动从 WaveTrialDirector 读快照。
var wave_index: int = 1
var _wave_override: int = -1
var _w: int = 1


func _ready() -> void:
	_build_motes()
	_build_stars()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(_delta: float) -> void:
	queue_redraw()


## R27：演示序列（presentation.gd）显式设置波次，确定性驱动三波空间变化。
func set_wave_index(w: int) -> void:
	_wave_override = clampi(w, 1, 3)
	wave_index = _wave_override
	queue_redraw()


## R27 自动回退：未显式驱动时，经 WaveTrialDirector 既有 get_snapshot() 读 index（0-based）+1。
## 节点不存在 / 无接口时静默回退到波 1，绝不臆造数值、不写任何 Label.text。
func _current_wave() -> int:
	if _wave_override >= 1:
		return _wave_override
	var d: Node = get_tree().root.get_node_or_null("Courtyard/WaveTrialDirector")
	if d != null and d.has_method("get_snapshot"):
		var s: Dictionary = d.call("get_snapshot")
		return clampi(int(s.get("index", 0)) + 1, 1, 3)
	return 1


func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_stars.clear()
	for i in range(28):
		_stars.append({
			"x": rng.randf_range(0.0, BUFFER_W),
			"y": rng.randf_range(0.0, HORIZON_Y - 18.0),
			"size": rng.randf_range(0.6, 1.4),
			"alpha": rng.randf_range(0.15, 0.5)
		})


func _build_motes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_far_motes.clear()
	_near_motes.clear()
	for i in range(40):
		_far_motes.append({
			"x0": rng.randf_range(0.0, BUFFER_W),
			"y0": rng.randf_range(0.0, HORIZON_Y + 40.0),
			"phase": rng.randf_range(0.0, TAU),
			"freq": rng.randf_range(TAU / 6.0, TAU / 3.0),
			"speed": rng.randf_range(1.0, 3.0),
			"size": rng.randf_range(0.7, 1.6)
		})
	for i in range(20):
		_near_motes.append({
			"x0": rng.randf_range(0.0, BUFFER_W),
			"y0": rng.randf_range(0.0, HORIZON_Y + 40.0),
			"phase": rng.randf_range(0.0, TAU),
			"freq": rng.randf_range(TAU / 4.0, TAU / 2.0),
			"speed": rng.randf_range(3.0, 7.0),
			"size": rng.randf_range(1.0, 2.4)
		})


func _c(hex_color: String, a: float) -> Color:
	var c := Color(hex_color)
	c.a = a
	return c


func _is_hud_avoid(logical_x: float, logical_y: float) -> bool:
	var sx: float = logical_x * LOGICAL_TO_SCREEN
	var sy: float = logical_y * LOGICAL_TO_SCREEN
	return (sx < HUD_AVOID_W + HUD_AVOID_MARGIN) \
		and (sy < HUD_AVOID_H + HUD_AVOID_MARGIN)


func _draw() -> void:
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var vs: Vector2 = Vector2(vp.size)
	if vs.x <= 0.0 or vs.y <= 0.0:
		return
	# 设计缓冲 → 实际 SubViewport 尺寸等比缩放：三档自适应铺满，不因低分辨率放大溢出。
	# SubViewport 纹理随后被 SubViewportContainer 拉伸到 1280×720 输出，
	# 故纯设计坐标绘制在三档下输出位置 / 尺寸一致。
	var sc: Vector2 = Vector2(vs.x / BUFFER_W, vs.y / BUFFER_H)
	draw_set_transform(Vector2.ZERO, 0.0, sc)
	_w = _current_wave()
	var t: float = Time.get_ticks_msec() / 1000.0
	_draw_night_sky()
	_draw_fog_bands_far(t)
	_draw_ridges(t)
	_draw_fog_bands_near(t)
	_draw_ground_grade()
	_draw_layered_motes(t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ① 深蓝夜空：64 条色带平滑渐变 + 冷白星点（像素精灵背后的平滑景深底）
func _draw_night_sky() -> void:
	var top := Color(String(WAVE_SKY_TOP[_w - 1]))
	var bot := Color(String(WAVE_SKY_BOT[_w - 1]))
	var band_h: float = HORIZON_Y / float(SKY_BANDS)
	for i in range(SKY_BANDS):
		var w: float = float(i) / float(SKY_BANDS - 1)
		var c := Color(
			top.r + (bot.r - top.r) * w,
			top.g + (bot.g - top.g) * w,
			top.b + (bot.b - top.b) * w
		)
		draw_rect(Rect2(-8.0, float(i) * band_h, BUFFER_W + 16.0, band_h + 1.0), c)
	for s in _stars:
		draw_rect(Rect2(float(round(float(s["x"]))), float(round(float(s["y"]))),
				float(s["size"]), float(s["size"])), _c("#BFD0EA", float(s["alpha"])))


# ② 远景雾带：置于山影之上（y 28/44/60），只做远景空气透视，不盖住山脊轮廓
func _draw_fog_bands_far(t: float) -> void:
	var bands: Array[Dictionary] = [
		{"y": 28.0, "h": 12.0, "a": 0.06},
		{"y": 44.0, "h": 14.0, "a": 0.08},
		{"y": 60.0, "h": 16.0, "a": 0.10},
	]
	_draw_fog_band_set(bands, t)


# ③ 近景雾带：压住山脚 / 地平线，形成冷雾与 3D 地面的平滑衔接
func _draw_fog_bands_near(t: float) -> void:
	var bands: Array[Dictionary] = [
		{"y": 100.0, "h": 14.0, "a": 0.14},
		{"y": 110.0, "h": 16.0, "a": 0.18},
	]
	_draw_fog_band_set(bands, t)


func _draw_fog_band_set(bands: Array[Dictionary], t: float) -> void:
	var fog_mult: float = float(WAVE_FOG_MULT[_w - 1])
	var fog_hex: String = String(WAVE_FOG_COLOR[_w - 1])
	for b in bands:
		var drift: float = sin(t * 0.25 + float(b["y"])) * 4.0
		for k in range(6):
			var a: float = clampf(float(b["a"]) * fog_mult * (1.0 - float(k) / 6.0), 0.0, 0.9)
			draw_rect(Rect2(-8.0 + drift, float(b["y"]) + float(k) * float(b["h"]) / 6.0,
					BUFFER_W + 16.0, float(b["h"]) / 6.0 + 1.0), _c(fog_hex, a))


# ④ 远景山影 3 层：深蓝剪影 + 冷蓝色阶 + alpha 递进 + 分层漂移 → 平滑多层景深
#    无相机输入，用分层错位缓慢漂移近似视差（如实：非真实相机视差）
func _draw_ridges(t: float) -> void:
	var ridge_defs: Array[Dictionary] = [
		{"base": 78.0, "amp": 18.0, "color": "#14294C", "alpha": 0.75, "p": P_RIDGE_FAR},
		{"base": 90.0, "amp": 20.0, "color": "#0C1C36", "alpha": 0.85, "p": P_RIDGE_MID},
		{"base": 102.0, "amp": 14.0, "color": "#050D1E", "alpha": 0.95, "p": P_RIDGE_NEAR},
	]
	var amp_mult: float = float(WAVE_RIDGE_AMP[_w - 1])
	for d in ridge_defs:
		var off: float = sin(t * 0.22 + float(d["p"]) * 7.0) \
			* (4.0 + float(d["p"]) * 30.0)
		var poly := PackedVector2Array()
		poly.append(Vector2(-8.0, HORIZON_Y + 20.0))
		for k in range(9):
			var x: float = -8.0 + float(k) * (BUFFER_W + 16.0) / 8.0
			var y: float = float(d["base"]) \
				- absf(sin(float(k) * 0.9 + float(d["p"]) * 8.0)) * float(d["amp"]) * amp_mult + off
			poly.append(Vector2(x, y))
		poly.append(Vector2(BUFFER_W + 8.0, HORIZON_Y + 20.0))
		draw_colored_polygon(poly, _c(str(d["color"]), float(d["alpha"])))
	# 远山上缘冷雾亮边（1px，强化层次）
	draw_line(Vector2(-8.0, 70.0), Vector2(BUFFER_W + 8.0, 70.0), _c("#3E6096", 0.22), 1.0)


# ⑤ 地面冷夜压暗：8 条渐变冷蓝半透明矩形叠在 3D 暖金砖地之上，
#    越靠画面底部越浓；砖纹保留但整体由「白天亮金」压成「冷夜暗金」，
#    与 HD2DFX(layer=10) 的暖金体积光 / bloom 形成强对比（光效层在其上，不被压暗）。
func _draw_ground_grade() -> void:
	var h: float = (BUFFER_H - HORIZON_Y) / float(GROUND_BANDS)
	var ground_hex: String = String(WAVE_GROUND_COLOR[_w - 1])
	var ground_mult: float = float(WAVE_GROUND_MULT[_w - 1])
	for k in range(GROUND_BANDS):
		var a: float = clampf((0.06 + 0.20 * (float(k) / float(GROUND_BANDS - 1))) * ground_mult,
				0.0, 0.9)
		draw_rect(Rect2(-8.0, HORIZON_Y + float(k) * h,
				BUFFER_W + 16.0, h + 1.0), _c(ground_hex, a))
	# 地平线高光（1px，衔接天空 / 地面）：波3 转暖金，波1/2 沿用冷雾
	var glow_hex: String = "#4A6A9C"
	if _w == 3:
		glow_hex = "#D89A5A"
	draw_line(Vector2(-8.0, HORIZON_Y), Vector2(BUFFER_W + 8.0, HORIZON_Y),
			_c(glow_hex, float(WAVE_HORIZON_GLOW[_w - 1])), 1.0)


# ⑥ 分层光尘：远景冷白（小/慢/淡）+ 近景暖金（略大/快/亮），HUD 区逐粒避让
func _draw_layered_motes(t: float) -> void:
	for m in _far_motes:
		var y: float = fposmod(float(m["y0"]) - float(m["speed"]) * t, HORIZON_Y + 40.0)
		var x: float = float(m["x0"]) + sin(t * float(m["freq"]) + float(m["phase"])) * 3.0
		if _is_hud_avoid(x, y):
			continue
		draw_circle(Vector2(float(round(x)), float(round(y))), float(m["size"]),
				_c("#BFD0EA", 0.22))
	for m in _near_motes:
		var y: float = fposmod(float(m["y0"]) - float(m["speed"]) * t, HORIZON_Y + 40.0)
		var x: float = float(m["x0"]) + sin(t * float(m["freq"]) + float(m["phase"])) * 4.0
		if _is_hud_avoid(x, y):
			continue
		draw_circle(Vector2(float(round(x)), float(round(y))), float(m["size"]),
				_c("#FFD27A", 0.38))
