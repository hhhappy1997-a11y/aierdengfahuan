extends Node2D
## R16 · 独立可挂载 HD-2D 光效节点（程序化 _draw() · 零外部素材）
## 派单：cmd-20261109-085736-029-A4 · [ROUND=R16] · 工位 Rank-4
##
## 定位：把 HD2D-FX-PLAN.md §3 的四项 2D 程序化光效（湿地倒影 / 体积光 / 光尘 /
##       bloom）从「焊死在占位层单节点」外提为独立 CanvasLayer 场景里的光效节点。
##       本轮只交付独立场景 hd2d_fx.tscn，不碰 courtyard.tscn（Rank-1 独占），
##       R17 由 Rank-1 挂进主场景。
##
## 四项原语（均落在 _draw() 内，零 PNG / 零贴图 / 零插件 / 零云服务 / 零付费 API）：
##   · 倒影   draw_rect()     垂直镜像 + 压缩 0.70 + 逐行波纹（§3.3 / 占位 step6）
##   · 体积光 draw_colored_polygon()（draw_polygon 家族）+ draw_line() 中心高光（§3.1 / step5）
##   · 光尘   draw_circle()   远景冷白 48 + 近景暖金 32，seed=20261108 固定（§3.2 / step5+8）
##   · bloom  draw_circle()   同心圆 ×5 + 暖金核心，仅 warm_gold_key 过阈（§3.4 / step8）
##
## 档位开关：fx_profile = "desktop" 四项全开 / "mobile" 四项全关
##   （冻结口径 HD2D-FX-PLAN.md §4.2，quality_preset_*.tres / render_profiles.tres）。
##   §4.3「移动档降级而非全关」是待裁决建议，本轮不擅自实现（沿用 R15 登记）。
##
## 约束：ComfyUI 仍是主美术路线，本脚本是零外部依赖的 2D 程序化兜底，不取代主路线、
##       不宣称已能出图 / 已实现 3D 后处理 / 已抓帧验收画面；中文 UTF-8；Godot 4 合法语法。
##       实体坐标 round() 到整数、禁亚像素；Nearest 过滤；不改运行中 hd2d_placeholder.gd。

# ---------------------------------------------------------------------------
# 冻结口径常量（引用 hd2d_placeholder.gd / HD2D-FX-PLAN.md §3 / ART-SPEC-FINAL.md §2.2）
# ---------------------------------------------------------------------------
const BUFFER_W := 640.0
const BUFFER_H := 360.0
const GROUND_Y := 250.0
const PLACEHOLDER_SEED := 20261108
const LIGHT_POS := Vector2(452.0, 92.0)

const PROFILE_DESKTOP := "desktop"
const PROFILE_MOBILE := "mobile"

# 档位开关（唯一开关）：desktop 四项全开 / mobile 四项全关
@export_enum("desktop", "mobile") var fx_profile: String = PROFILE_DESKTOP

# 四项各自的绘制门（由档位派生；分列便于 R17 按接入点 / 待裁决降级建议逐项接线）
var _all_on: bool = true
var _on_reflection: bool = true
var _on_godrays: bool = true
var _on_motes: bool = true
var _on_bloom: bool = true

# 倒影源：与 hd2d_placeholder.gd 一致的 32×32 像素实体色板索引阵列（内联常量，零外部素材）
# 锚点 (16,31)：脚底像素位于 py=31；字符 '0'-'9'/'a'-'f' -> 色板索引 0..15，'.' = 透明。
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

# 取色板：palette_256.json colors[0..15]（内联 hex，零外部素材、不加载 JSON / PNG）
var PALETTE_HEX: Array[String] = [
	"#FFF0C2", "#FFD27A", "#F0A94C", "#C97A2E", "#8A5A22",
	"#BFD0EA", "#7E96BF", "#4A6089", "#2B3A5C", "#16233F", "#0B1226",
	"#1F3A63", "#16294A", "#0E1B33", "#080F1F", "#E8C479"
]

var _palette: Array[Color] = []
var _motes_far: Array[Dictionary] = []    # 远景冷白光尘（确定性 seed）
var _motes_near: Array[Dictionary] = []   # 近景暖金光尘


func _ready() -> void:
	_palette.clear()
	for h in PALETTE_HEX:
		_palette.append(Color(h))
	_build_motes()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_fx_profile(fx_profile)


## 档位开关的公共入口：改档位并立即重算四项门 / 可见性（供 build 脚本回读真跑验证）。
func set_fx_profile(profile: String) -> void:
	fx_profile = profile
	_apply_profile()


func _apply_profile() -> void:
	# 冻结口径（HD2D-FX-PLAN.md §4.2）：desktop 四项全开 / mobile 四项全关。
	# §4.3 的「移动降级而非全关」为待裁决建议，本轮不擅自实现（R15 已登记）。
	_all_on = (fx_profile == PROFILE_DESKTOP)
	_on_reflection = _all_on
	_on_godrays = _all_on
	_on_motes = _all_on
	_on_bloom = _all_on
	# mobile 整层不绘制；desktop 四项由节点名分派、按同层子节点顺序叠加
	visible = _all_on


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
	# 逐帧重绘沿用 hd2d_placeholder.gd::_process 口径（光尘上飘 / 倒影波纹需逐帧）。
	# §4.4「静态层（体积光/bloom）仅档位变化时重绘 + 移动档节流」是给 Rank-1 的
	# 落地建议，本轮不擅自实现，如实登记为待接线项。
	if _all_on:
		queue_redraw()


func _draw() -> void:
	if not _all_on:
		return
	var t := Time.get_ticks_msec() / 1000.0
	# 单节点内按 HD-2D视觉规范.md §10 层序绘制：fx_0_back(倒影/体积光) → fx_1_front(光尘/bloom)。
	# 独立场景由 4 个同名分派节点分担，各节点同处一个 CanvasLayer，靠子节点顺序叠加。
	match str(name):
		"FXReflection":
			if _on_reflection:
				_draw_reflection(t)
		"FXGodRays":
			if _on_godrays:
				_draw_godrays(t)
		"FXMotes":
			if _on_motes:
				_draw_motes(t)
		"FXBloom":
			if _on_bloom:
				_draw_bloom(t)
		_:
			pass


# ---------------------------------------------------------------------------
# 共用辅助
# ---------------------------------------------------------------------------
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
# ① 湿地倒影：镜像 draw_rect()（HD2D-FX-PLAN.md §3.3 / 占位 step6）
# ---------------------------------------------------------------------------
func _draw_reflection(t: float) -> void:
	var blocks := _collect_entity_blocks()
	for b in blocks:
		var sy: float = float(b["y"])
		var y_mirror := 2.0 * GROUND_Y - sy - 1.0             # 脚底 Y 对齐的垂直镜像
		var y_ref := GROUND_Y + (y_mirror - GROUND_Y) * 0.70  # 高度压缩 0.70
		var ripple_dx := sin(t + y_ref) * 0.03 * BUFFER_W     # 逐行横向错位模拟水波
		# 倒影是半透明减色，用普通 Mix（非 Add）；alpha 0.35 冻结值
		draw_rect(Rect2(float(round(float(b["x"]) + ripple_dx)), float(round(y_ref)), 1.0, 1.0),
				_c_palette_alpha(int(b["idx"]), 0.35))


# ---------------------------------------------------------------------------
# ② 体积光：draw_colored_polygon（draw_polygon 家族）+ draw_line 中心高光
#    （HD2D-FX-PLAN.md §3.1 / 占位 step5）
# ---------------------------------------------------------------------------
func _draw_godrays(_t: float) -> void:
	var godray_alpha: Array[float] = [0.18, 0.12, 0.07, 0.04]
	var bottom := GROUND_Y + 30.0
	for i in range(godray_alpha.size()):
		var spread := 40.0 + float(i) * 46.0                  # 40 / 86 / 132 / 178
		var poly := PackedVector2Array([
			LIGHT_POS,
			Vector2(LIGHT_POS.x - spread, bottom),
			Vector2(LIGHT_POS.x + spread, bottom)
		])
		# _draw() 无逐调用 Add 混合参数，用低 alpha 多次叠加近似径向光束衰减；
		# draw_colored_polygon 是 draw_polygon 的单色便捷形式（占位 step5 已验证合法）
		draw_colored_polygon(poly, _c("#FFD27A", godray_alpha[i]))
	# 中心高光带：draw_line 近似方案 §3.1 的 Line2D 锐利核心
	draw_line(LIGHT_POS, Vector2(LIGHT_POS.x, bottom), _c("#FFF0C2", 0.10), 1.0)


# ---------------------------------------------------------------------------
# ③ 光尘：draw_circle()，seed=PLACEHOLDER_SEED 固定（HD2D-FX-PLAN.md §3.2 / step5+8）
# ---------------------------------------------------------------------------
func _draw_motes(t: float) -> void:
	for m in _motes_far:
		var y := fposmod(float(m["y0"]) - float(m["speed"]) * t, BUFFER_H)
		var x := float(m["x0"]) + sin(t * float(m["freq"]) + float(m["phase"])) * 3.0
		draw_circle(Vector2(float(round(x)), float(round(y))), float(m["size"]), _c("#BFD0EA", 0.25))
	for m in _motes_near:
		var y := fposmod(float(m["y0"]) - float(m["speed"]) * t, BUFFER_H)
		var x := float(m["x0"]) + sin(t * float(m["freq"]) + float(m["phase"])) * 3.0
		draw_circle(Vector2(float(round(x)), float(round(y))), float(m["size"]), _c("#FFD27A", 0.45))


# ---------------------------------------------------------------------------
# ④ bloom 近似：同心圆 ×5 + 暖金核心（HD2D-FX-PLAN.md §3.4 / 占位 step8）
#    只让 warm_gold_key 过阈（threshold≈0.95 的几何近似）；冷夜雾区不放置任何光晕。
# ---------------------------------------------------------------------------
func _draw_bloom(_t: float) -> void:
	var radii: Array[float] = [4.0, 8.0, 14.0, 22.0, 32.0]
	var alphas: Array[float] = [0.20, 0.12, 0.07, 0.04, 0.02]
	for i in range(radii.size()):
		draw_circle(LIGHT_POS, radii[i], _c("#FFD27A", alphas[i]))
	draw_circle(LIGHT_POS, 3.0, _c("#FFF0C2", 0.85))          # L8 96% 核心过阈
