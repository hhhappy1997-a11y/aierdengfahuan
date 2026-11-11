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

# ===========================================================================
# R29 v0.7.0 · P2 全屏景深强化（shader 小样 / 程序化 _draw 降级）
#   ① shader 路径：运行时创建 CanvasLayer(layer=12) + ColorRect + ShaderMaterial
#      （v070_depth_grade.gdshader, hint_screen_texture），读 Rank-2
#      depth_profile.tres 参数注入；未落盘 → [PLACEHOLDER] 安全默认并如实登记。
#   ② 降级路径：Compatibility screen texture 不可用 → 关闭 shader，改由本节点
#      _draw() 追加 _r29_draw_grade() 程序化强化；不谎称 shader 生效（裁决 A30）。
#   ③ 运行时创建节点，绝不写 courtyard.tscn 的 [node 条目 → 磁盘 node_count 恒 41，
#      verify_wave_runtime_v040 / verify_tutorial_restart_v060 的 41 断言不回退。
#   ④ layer=12 < Hud(20)/WaveTrialHud(20)/TutorialHud(21)/QualitySettings(40)：不遮挡 HUD。
#   [PLACEHOLDER] FINALE_DELAY_SEC / FINALE_DURATION_SEC 为演示收束节奏，待试玩校准
#   （rationale：波3 自 f=300=10s 起，+4.0s=f420 触发、2.0s 单峰脉冲使峰值落在尾帧 449，
#    与 f=430 击败 Boss / f=420 赐福标题切「希芙拉河井底」的尾段收束节奏对齐）。
# ===========================================================================
const DEPTH_GRADE_SHADER_PATH: String = "res://shaders/v070_depth_grade.gdshader"
const DEPTH_PROFILE_PATH: String = "res://data/render/depth_profile.tres"
const GRADE_LAYER_NAME: String = "V070DepthGradeLayer"
const GRADE_RECT_NAME: String = "V070DepthGradeRect"
const GRADE_CANVAS_LAYER: int = 12
# 短跑目视 + 编译日志判定后切换：false=尝试 shader / true=降级 _draw（A30 不谎称）
# [R30 A37] 降级层开关验证已完成：R30 临时置 true 跑过一次 _r29_draw_grade() 目视留证后
#   已恢复 false = shader 默认档（裁决 A37：preserve shader 默认档、不回退画面、不谎称降级层是默认效果）。
#   _draw() 降级层仅作 Compatibility screen texture 失效时的备用路径，平时不启用。
const GRADE_FORCE_DRAW_FALLBACK: bool = false
const FINALE_DELAY_SEC: float = 4.0
const FINALE_DURATION_SEC: float = 2.0

var _r29_params: Dictionary = {}
var _r29_profiles: Dictionary = {}          # "desktop"/"mobile" → 生效参数字典（读 Rank-2 参数表）
var _r29_active_tier: String = "desktop"
var _r29_profile_source: String = "SAFE_DEFAULTS"
var _r29_profile_hits: int = 0
var _grade_layer: CanvasLayer = null
var _grade_rect: ColorRect = null
var _grade_mat: ShaderMaterial = null
var _r29_shader_active: bool = false
var _r29_draw_fallback: bool = false
var _wave_tier: float = 0.0
var _lit_level: float = 0.0
var _wave3_elapsed: float = 0.0
var _finale_triggered: bool = false
var _finale_phase: float = -1.0
var _finale_value: float = 0.0
var _finale_source: String = ""

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
	_r29_init()


func _process(delta: float) -> void:
	queue_redraw()
	_r29_tick(delta)


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
	if _r29_draw_fallback:
		_r29_draw_grade(t)
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


# ===========================================================================
# R29 v0.7.0 · P2 全屏景深强化实现（shader 小样 / 程序化 _draw 降级）
# 详见文件头「R29 v0.7.0」常量区注释。零素材 / 零 GPU job / 零外部依赖。
# ===========================================================================

## 参数表路径可由 courtyard.tscn 的 ParallaxBackdrop 节点 metadata 覆盖（视觉属性，
## 不新增 [node 条目）；未配置则用常量 DEPTH_PROFILE_PATH。
func _r29_profile_path() -> String:
	if has_meta("v070_depth_profile_path"):
		return str(get_meta("v070_depth_profile_path"))
	return DEPTH_PROFILE_PATH


func _r29_init() -> void:
	_r29_load_params()
	if GRADE_FORCE_DRAW_FALLBACK:
		_r29_draw_fallback = true
		_r29_shader_active = false
		print("[R29][GRADE] Compatibility screen texture 不可用（短跑目视/编译日志判定）→ 降级为程序化 _draw() 强化；shader 未生效（A30 如实登记）")
		return
	var sh: Shader = load(DEPTH_GRADE_SHADER_PATH) as Shader
	if sh == null:
		_r29_draw_fallback = true
		_r29_shader_active = false
		push_warning("[R29][GRADE] shader 文件加载失败 → 降级为程序化 _draw() 强化")
		return
	var layer := CanvasLayer.new()
	layer.name = GRADE_LAYER_NAME
	layer.layer = GRADE_CANVAS_LAYER
	var rect := ColorRect.new()
	rect.name = GRADE_RECT_NAME
	rect.color = Color(0.0, 0.0, 0.0, 0.0)   # shader 编译失败时零遮挡，保护画面
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = sh
	rect.material = mat
	layer.add_child(rect)                      # layer 未进树，先组装子节点（安全）
	call_deferred("add_child", layer)           # _ready 期间父节点 busy，延迟挂入树
	_grade_layer = layer
	_grade_rect = rect
	_grade_mat = mat
	_r29_shader_active = true
	_r29_draw_fallback = false
	_r29_apply_params()
	print("[R29][GRADE] shader 小样已挂载（待短跑目视 + 编译日志确认生效） | layer=%d rect=%s | 参数来源=%s 命中=%d/%d" % [
		GRADE_CANVAS_LAYER, GRADE_RECT_NAME, _r29_profile_source,
		_r29_profile_hits, _r29_params.size()])


## [PLACEHOLDER] 安全默认参数（参数表未落盘 / 字段缺失时兜底；待试玩校准）。
## rationale：Rank-2 参数表属并发件，必须有一套零风险兜底；且所有生效数值均由本函数
## 注入 shader，shader 内不硬编码任何生效数值。
func _r29_base_defaults() -> Dictionary:
	return {
		"vignette_strength": 0.42,
		"vignette_inner": 0.34,
		"vignette_outer": 0.78,
		"cool_fog_strength": 0.20,
		"cool_fog_color": Color(0.12, 0.22, 0.40),
		"warm_glow_strength": 0.22,
		"warm_glow_color": Color(1.0, 0.72, 0.32),
		"warm_glow_pos": Vector2(0.706, 0.256),   # LIGHT_POS(452,92) / 640×360
		"depth_far_strength": 0.16,
		"blur_radius": 1.5,
		"bloom_threshold": 0.75,
	}


## 真读 Rank-2 depth_profile.tres：顶层 + desktop/mobile 两套子 Resource 逐字段映射到 shader uniform。
## 参数表未落盘 / load 失败 → 两套都用 [PLACEHOLDER] 安全默认（如实登记，不等待、不伪造）。
func _r29_load_params() -> void:
	_r29_profiles = {}
	_r29_profile_hits = 0
	var path: String = _r29_profile_path()
	var res: Resource = null
	if ResourceLoader.exists(path):
		res = load(path)
	if res == null:
		_r29_profile_source = "SAFE_DEFAULTS[PLACEHOLDER]（参数表未落盘/加载失败）"
		_r29_profiles["desktop"] = _r29_base_defaults()
		_r29_profiles["mobile"] = _r29_base_defaults()
		_r29_params = _r29_profiles["desktop"]
		print("[R29][DEPTH] depth_profile.tres 未落盘/加载失败 path=%s → 自带 [PLACEHOLDER] 安全默认参数，不等待、不伪造" % path)
		return
	for tier: String in ["desktop", "mobile"]:
		var d: Dictionary = _r29_base_defaults()
		var n: int = _r29_map_profile(d, res)               # 顶层字段（结构容错）
		var sub: Resource = res.get(tier) as Resource
		if sub != null:
			n += _r29_map_profile(d, sub)                     # 子 Resource 字段覆盖
		_r29_profiles[tier] = d
		_r29_profile_hits += n
		print("[R29][DEPTH] 档=%s 命中字段=%d | vignette=%.3f warm=%.3f fog=%.3f deep=%.3f blur=%.2f" % [
			tier, n, float(d["vignette_strength"]), float(d["warm_glow_strength"]),
			float(d["cool_fog_strength"]), float(d["depth_far_strength"]), float(d["blur_radius"])])
	_r29_profile_source = path if _r29_profile_hits > 0 else "SAFE_DEFAULTS(字段未匹配)"
	_r29_params = _r29_profiles["desktop"]
	print("[R29][DEPTH] 参数表已读取 path=%s | 总命中=%d | 生效来源=%s | desktop/mobile 双档按画质切换（数值不硬编码于 shader）" % [
		path, _r29_profile_hits, _r29_profile_source])


## 把 Rank-2 DepthProfile 字段映射到 shader uniform，返回命中字段数。
## [PLACEHOLDER] 派生系数 fog_density×5 / layer_depths[0]×0.4 / parallax_coefficients[0]×25
## 为「参数表字段语义 → shader uniform」的量纲换算，待试玩校准；rationale：
## fog_density(0.035/0.018) 需放大到 0~1 雾强度、layer_depths(0.25/0.35) 需映射到远景模糊权重、
## parallax_coefficients(0.06/0.05) 需映射到低分辨率缓冲模糊半径 1.5px 口径。
func _r29_map_profile(d: Dictionary, src: Resource) -> int:
	var n: int = 0
	var v: Variant = src.get("vignette_strength")
	if v is float or v is int:
		d["vignette_strength"] = clampf(float(v), 0.0, 1.0)
		n += 1
	v = src.get("warm_glow_strength")
	if v is float or v is int:
		d["warm_glow_strength"] = clampf(float(v), 0.0, 1.0)
		n += 1
	v = src.get("fog_density")
	if v is float or v is int:
		d["cool_fog_strength"] = clampf(float(v) * 5.0, 0.0, 1.0)
		n += 1
	v = src.get("cold_night_fog_color")
	if v is String and not String(v).is_empty():
		d["cool_fog_color"] = Color(String(v))
		n += 1
	v = src.get("warm_gold_key_color")
	if v is String and not String(v).is_empty():
		d["warm_glow_color"] = Color(String(v))
		n += 1
	v = src.get("layer_depths")
	if v is PackedFloat32Array and (v as PackedFloat32Array).size() > 0:
		d["depth_far_strength"] = clampf(float((v as PackedFloat32Array)[0]) * 0.4, 0.0, 1.0)
		n += 1
	v = src.get("parallax_coefficients")
	if v is PackedFloat32Array and (v as PackedFloat32Array).size() > 0:
		d["blur_radius"] = clampf(float((v as PackedFloat32Array)[0]) * 25.0, 0.0, 4.0)
		n += 1
	return n


## 按 QualitySettings 当前画质档选参数表（防御性；读不到档位默认 desktop）。
func _r29_current_tier() -> String:
	var q: Node = get_tree().root.get_node_or_null("Courtyard/QualitySettings")
	if q != null and q.has_method("get_quality_preset"):
		var p: String = str(q.call("get_quality_preset")).to_lower()
		if p == "low" or p.contains("mobile"):
			return "mobile"
	return "desktop"


## 把生效参数灌入 ShaderMaterial（Color→Vector3 以匹配 vec3 uniform；screen_px 按真实 viewport）。
func _r29_apply_params() -> void:
	if _grade_mat == null:
		return
	for k in _r29_params.keys():
		var v: Variant = _r29_params[k]
		if v is Color:
			var c: Color = v
			v = Vector3(c.r, c.g, c.b)
		_grade_mat.set_shader_parameter(String(k), v)
	var vp: Viewport = get_viewport()
	var sz: Vector2 = Vector2(BUFFER_W, BUFFER_H)
	if vp != null and vp.size.x > 0.0 and vp.size.y > 0.0:
		sz = Vector2(vp.size)
	_grade_mat.set_shader_parameter("screen_px", sz)
	_grade_mat.set_shader_parameter("wave_tier", _wave_tier)
	_grade_mat.set_shader_parameter("lit_level", _lit_level)
	_grade_mat.set_shader_parameter("finale", _finale_value)


## 点亮态 / 波次层次 / 三波收束节奏（每帧平滑，不闪烁、不遮挡 HUD）。
func _r29_tick(delta: float) -> void:
	# 画质档切换 → 采用 Rank-2 参数表对应档（段 A/C desktop、段 B mobile）
	var tier: String = _r29_current_tier()
	if tier != _r29_active_tier and _r29_profiles.has(tier):
		_r29_active_tier = tier
		_r29_params = _r29_profiles[tier]
		print("[R29][DEPTH] 画质档切换 → 采用 %s 档参数表（vignette=%.3f warm=%.3f）" % [
			tier, float(_r29_params["vignette_strength"]), float(_r29_params["warm_glow_strength"])])
	var w: int = _current_wave()
	var tier_target: float = clampf(float(w - 1) / 2.0, 0.0, 1.0)
	_wave_tier = lerpf(_wave_tier, tier_target, clampf(delta * 3.0, 0.0, 1.0))
	var lit: bool = _r29_read_lit_flag()
	# 赐福标题点亮后，暖金层次随波次推进（波1→波2→波3 递进），平滑插值避免闪烁
	var lit_target: float = (0.55 + 0.45 * tier_target) if lit else 0.20
	_lit_level = lerpf(_lit_level, lit_target, clampf(delta * 2.5, 0.0, 1.0))
	_r29_tick_finale(delta, w)
	if _r29_shader_active:
		_r29_apply_params()


## 只读 WorldState 的赐福点亮 flag（防御性；接口缺失返回 false，不伪造点亮）。
func _r29_read_lit_flag() -> bool:
	var ws: Node = get_tree().root.get_node_or_null("WorldState")
	if ws == null or not ws.has_method("get_flag"):
		return false
	var keys: Array[String] = [
		"grace.limgrave_gatefront.lit", "grace.limgrave_chapel.lit",
		"grace.weeping_shore.lit", "grace.siofra_well.lit"]
	for k: String in keys:
		if bool(ws.call("get_flag", k, false)):
			return true
	return false


## 三波完成收束：优先读 WaveTrialDirector TRIAL_COMPLETED(state=5)；
## 未达该状态则用「波3 + 演示节奏计时」兜底触发一次，并如实打印触发来源（不冒充游戏事件证明）。
func _r29_tick_finale(delta: float, w: int) -> void:
	if w >= 3:
		_wave3_elapsed += delta
	if not _finale_triggered:
		# 三波完成收束：以「波3 + 演示尾段计时」确定性触发（一次、尾帧可见）；
		# 导演 TRIAL_COMPLETED(state=5) 只作日志佐证，不提前消费唯一的一次收束。
		if w >= 3 and _wave3_elapsed >= FINALE_DELAY_SEC:
			var completed: bool = _r29_read_trial_completed()
			_finale_triggered = true
			_finale_phase = 0.0
			_finale_source = "演示节奏兜底(波3 + %.1fs)" % FINALE_DELAY_SEC
			if completed:
				_finale_source += " / 导演 TRIAL_COMPLETED(state=5) 已达成"
			print("[R29][FINALE] 三波完成收束光效触发一次 | 来源=%s | wave=%d lit=%.2f tier=%.2f（程序化单峰，不闪烁）" % [
				_finale_source, w, _lit_level, _wave_tier])
	if _finale_phase >= 0.0:
		_finale_phase += delta / FINALE_DURATION_SEC
		# 单峰脉冲 0→1→0，一次性，不反复闪烁
		_finale_value = sin(clampf(_finale_phase, 0.0, 1.0) * PI) if _finale_phase <= 1.0 else 0.0


func _r29_read_trial_completed() -> bool:
	var d: Node = get_tree().root.get_node_or_null("Courtyard/WaveTrialDirector")
	if d == null or not d.has_method("get_snapshot"):
		return false
	var s: Dictionary = d.call("get_snapshot")
	return int(s.get("state", -1)) == 5


## 降级路径：程序化 _draw() 全屏强化层（暗角 / 冷夜雾 / 多层景深 / 暖金光晕 / 收束环）。
## 与 shader 等效的四项观感，全部 draw_rect / draw_circle / draw_arc，零素材、零 GPU job。
func _r29_draw_grade(_t: float) -> void:
	var vignette: float = float(_r29_params.get("vignette_strength", 0.42))
	var fog: float = float(_r29_params.get("cool_fog_strength", 0.20))
	var far_s: float = float(_r29_params.get("depth_far_strength", 0.16))
	var warm: float = float(_r29_params.get("warm_glow_strength", 0.22))
	var lp: Vector2 = Vector2(452.0, 92.0)
	# ① 多层视差景深：上部 3 层冷蓝降饱和雾带（远→近逐层淡）
	for i in range(3):
		draw_rect(Rect2(-8.0, float(i) * 26.0, BUFFER_W + 16.0, 26.0),
				_c("#12345A", far_s * (0.55 - 0.14 * float(i))))
	# ② 冷夜雾：底部横向薄雾
	for i in range(3):
		draw_rect(Rect2(-8.0, BUFFER_H - 60.0 + float(i) * 20.0, BUFFER_W + 16.0, 20.0),
				_c("#1C3556", fog * (0.10 + 0.06 * float(i))))
	# ③ 边缘暗角：6 层四边矩形边框，从外向内 alpha 递减
	for i in range(6):
		var f: float = float(i) / 6.0
		_r29_vignette_frame(4.0 + f * 44.0, vignette * 0.15 * (1.0 - f))
	# ④ 暖金光晕：同心圆（随点亮态 / 波次层次平滑增强，不闪烁）
	var glow: float = warm * (0.55 + 0.45 * _lit_level) * (0.60 + 0.40 * _wave_tier)
	var radii: Array[float] = [48.0, 38.0, 28.0, 18.0, 9.0]
	for i in range(radii.size()):
		draw_circle(lp, radii[i], _c("#FFD27A", glow * (0.05 + 0.05 * float(i))))
	# ⑤ 收束光效（一次性扩散环）
	if _finale_value > 0.001:
		var rr: float = 18.0 + (1.0 - _finale_value) * 230.0
		draw_arc(lp, rr, 0.0, TAU, 48, _c("#FFE6A8", 0.40 * _finale_value), 2.0)


func _r29_vignette_frame(m: float, a: float) -> void:
	var col: Color = _c("#04070F", a)
	draw_rect(Rect2(0.0, 0.0, BUFFER_W, m), col)                       # 上
	draw_rect(Rect2(0.0, BUFFER_H - m, BUFFER_W, m), col)              # 下
	draw_rect(Rect2(0.0, 0.0, m, BUFFER_H), col)                       # 左
	draw_rect(Rect2(BUFFER_W - m, 0.0, m, BUFFER_H), col)              # 右
