extends Node2D
## R18 · 独立可挂载 HD-2D 光效节点（程序化 _draw() · 零外部素材）
## 派单：cmd-20261109-095518-176-A4 · [ROUND=R18] · 工位 Rank-4
## 精修（在 R16 独立场景 / R17 由 Rank-1 挂进主场景的基础上，只改本 .gd）：
##   ① 暖金体积光扇形 4→6 层、峰值 alpha 保持 0.18 不糊画面、补中心高光带（柔核+亮核）；
##   ② 倒影改垂直镜像近似：2×2 半透明色块向下翻转 + 压缩 0.85 + 深度渐隐 + 逐行波纹，
##      不再是被地面横砖淹没成的「一条水平亮线」；
##   ③ 光尘绘制时按 HUD 屏幕矩形（约 x<730、y<220）逐粒跳过，避免面板被点状遮挡；
##   ④ fx_profile desktop/mobile 档位开关与 texture_filter=Nearest 冻结口径不变。
##
## R20 精修（派单 cmd-20261109-110237-810-A4 · [ROUND=R20] · Rank-4）：
##   ⑤ 补 R19 缺口：新增「运行期强制档位覆盖」，读环境变量 AIERDENG_FX_PROFILE=mobile，
##      经 call_deferred 在 courtyard.tscn 的 HD2DFX 根（Rank-1 独占 fx_profile_controller.gd）
##      的 _ready() 强制 desktop 之后，把本 FX 节点真正落到 mobile 四项全关，并锁定档位
##      忽略后续 desktop 请求 → Movie Maker 抓帧可真实输出移动档画面（非 desktop 帧改名）。
##      未设该环境变量时完全不激活：默认 desktop 四项全开零回退，47 PASS 回归不受影响。
##   ⑥ HUD 避让矩形（x<730、y<220）改由 hd2d_fx.tscn 的 metadata 场景级配置、脚本常量兜底；
##      判定纳入光尘圆点半径（margin 只向外扩），避免粒子边缘擦进 HUD 面板。
##      mobile 四项全关时 _draw() 直接 return、FX 层零绘制，天然无光尘遮 HUD。
##
## 定位：把 HD2D-FX-PLAN.md §3 的四项 2D 程序化光效（湿地倒影 / 体积光 / 光尘 /
##       bloom）外提为独立 CanvasLayer 场景里的光效节点。R17 已由 Rank-1 把
##       hd2d_fx.tscn 挂进 courtyard.tscn；本轮不碰主场景（Rank-1 独占）。
##
## 四项原语（均落在 _draw() 内，零 PNG / 零贴图 / 零插件 / 零云服务 / 零付费 API）：
##   · 倒影   draw_rect()     垂直镜像色块 + 压缩 + 逐行波纹 + 深度渐隐（§3.3 / 占位 step6）
##   · 体积光 draw_colored_polygon() ×6 + draw_line() 中心高光（§3.1 / step5）
##   · 光尘   draw_circle()   远景冷白 48 + 近景暖金 32，seed=20261108 固定，HUD 区避让（§3.2）
##   · bloom  draw_circle()   同心圆 ×5 + 暖金核心，仅 warm_gold_key 过阈（§3.4 / step8）
##
## 档位开关：fx_profile = "desktop" 四项全开 / "mobile" 四项全关
##   （冻结口径 HD2D-FX-PLAN.md §4.2，quality_preset_*.tres / render_profiles.tres）。
##   §4.3「移动档降级而非全关」是待裁决建议，本轮不擅自实现（沿用 R15 登记）。
##
## 约束：ComfyUI 仍是主美术路线，本脚本是零外部依赖的 2D 程序化兜底，不取代主路线、
##       不宣称已能出图 / 已实现 3D 后处理；中文 UTF-8；Godot 4 合法语法。
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

# ---------------------------------------------------------------------------
# R20 · 运行期强制档位覆盖（补 R19「只抓到 desktop 画面」缺口）
# 背景：courtyard.tscn 的 HD2DFX 根挂 Rank-1 独占 fx_profile_controller.gd，其 _ready()
#       依 fx_profile_source（固定指向 desktop preset 640×360）把 4 个 FX 子节点强制切回
#       desktop。本脚本是 hd2d_fx.tscn 的 4 个 FX 子节点（Rank-4 可写），在此提供
#       「只在显式请求时激活」的覆盖：环境变量 = mobile 时，deferred 排在 controller
#       _ready() 之后落到 mobile，并锁定档位忽略后续 desktop 请求。
# 默认（未设环境变量）：不激活，_ready() 走原 set_fx_profile(fx_profile) 默认 desktop，
#       desktop 四项全开零回退；verify_fx_mobile.gd 的 47 PASS 回归不受任何影响。
# ---------------------------------------------------------------------------
const ENV_FORCE_PROFILE: String = "AIERDENG_FX_PROFILE"
var _force_profile: String = ""

# 档位开关（唯一开关）：desktop 四项全开 / mobile 四项全关
@export_enum("desktop", "mobile") var fx_profile: String = PROFILE_DESKTOP

# 四项各自的绘制门（由档位派生；分列便于 R17 按接入点 / 待裁决降级建议逐项接线）
var _all_on: bool = true
var _on_reflection: bool = true
var _on_godrays: bool = true
var _on_motes: bool = true
var _on_bloom: bool = true

# ---------------------------------------------------------------------------
# R18 精修参数（普通成员，供 build_fx_r18_verify.gd 运行期 get() 回读；零外部素材）
# ---------------------------------------------------------------------------
# ① 体积光：层数 4→6（径向衰减更细腻），扇形峰值 alpha 保持 0.18 不抬高以免糊画面；
#    另以中心高光带（柔核 + 亮核）强化暖金主光方向。
var godray_layers: int = 6
var godray_alpha: Array[float] = [0.18, 0.14, 0.10, 0.07, 0.045, 0.025]
var godray_spread_base: float = 40.0
var godray_spread_step: float = 30.0
# ② 倒影：垂直镜像 2×2 半透明色块（连成轮廓）+ 压缩 0.85 向下延伸 + 深度渐隐 + 逐行波纹。
var reflection_squash: float = 0.85
var reflection_alpha: float = 0.42
var reflection_fade: float = 0.55
var reflection_block_px: float = 2.0
var reflection_ripple: float = 0.035
# ③ 光尘 HUD 避让：屏幕坐标矩形（约 x<730、y<220），绘制时逐粒跳过。
#    FX 与 HUD 同处 SubViewport(640×360) 逻辑坐标，画布经 stretch_shrink=2 放大到 1280×720。
var hud_avoid_screen_w: float = 730.0
var hud_avoid_screen_h: float = 220.0
var logical_to_screen: float = 2.0
# R20 精修：把光尘圆点半径纳入避让判定（最大 size≈3 逻辑px ×2 = 6 屏幕px），
#   margin 只向外扩、不缩小冻结口径的 x<730 / y<220 矩形，避免粒子边缘擦进 HUD 面板。
var hud_avoid_margin_px: float = 6.0

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
	_apply_hud_avoid_meta()
	# R20 运行期强制档位：仅当显式设置环境变量 AIERDENG_FX_PROFILE=mobile 时激活。
	# courtyard.tscn 的 HD2DFX 根（Rank-1 独占 fx_profile_controller.gd）会在其
	# _ready() 里把 4 个 FX 子节点强制切回 desktop；故此处用 call_deferred 排队到
	# 本帧所有 _ready() 完成后再落到 mobile，并锁定档位忽略后续 desktop 请求。
	_force_profile = _read_forced_profile()
	if _force_profile == PROFILE_MOBILE:
		call_deferred("_apply_forced_mobile")
		print("[R20][%s] 强制档位=mobile（deferred 覆盖 controller 的 desktop）env=%s" % [
				str(name), ENV_FORCE_PROFILE])
	else:
		set_fx_profile(fx_profile)
		print("[R20][%s] 默认档位=%s（未请求覆盖，desktop 四项全开零回退）" % [
				str(name), fx_profile])


## 档位开关的公共入口：改档位并立即重算四项门 / 可见性（供 build 脚本回读真跑验证）。
## R20：强制 mobile 激活期间忽略外部（fx_profile_controller / 画质菜单）切回 desktop 的请求，
##       保证抓帧全程稳定停在 mobile；未激活时行为与 R18/R19 完全一致（47 PASS 不受影响）。
func set_fx_profile(profile: String) -> void:
	if _force_profile == PROFILE_MOBILE and profile == PROFILE_DESKTOP:
		print("[R20][%s] 忽略外部 set_fx_profile(desktop)：强制 mobile 锁定生效" % str(name))
		return
	fx_profile = profile
	_apply_profile()


## R20：读取运行期强制档位（环境变量；零外部依赖、Movie Maker 兼容）。
func _read_forced_profile() -> String:
	if OS.has_environment(ENV_FORCE_PROFILE):
		var v := OS.get_environment(ENV_FORCE_PROFILE).strip_edges().to_lower()
		if v == PROFILE_MOBILE or v == PROFILE_DESKTOP:
			return v
	return ""


## R20：deferred 落地（在所有 _ready() 之后），把本节点真正切到 mobile 四项全关。
func _apply_forced_mobile() -> void:
	set_fx_profile(PROFILE_MOBILE)
	print("[R20][%s] deferred 落地 set_fx_profile(mobile) | visible=%s _all_on=%s fx_profile=%s 四门=[%s %s %s %s]" % [
			str(name), str(visible), str(_all_on), fx_profile,
			str(_on_reflection), str(_on_godrays), str(_on_motes), str(_on_bloom)])


## R20：HUD 避让矩形可由 hd2d_fx.tscn 的 metadata 覆盖（场景级权威数据，脚本常量兜底）。
func _apply_hud_avoid_meta() -> void:
	if has_meta("hud_avoid_screen_w"):
		hud_avoid_screen_w = float(get_meta("hud_avoid_screen_w"))
	if has_meta("hud_avoid_screen_h"):
		hud_avoid_screen_h = float(get_meta("hud_avoid_screen_h"))


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
# R18 ③ 光尘 HUD 避让：逻辑坐标 → 屏幕坐标判定（约 x<730、y<220）
#   FX / HUD 同处 SubViewport(640×360)，stretch_shrink=2 放大到 1280×720；
#   光尘会绘制在 HUD 之上（HD2DFX 与 Hud 同 layer=10、树序靠后），故绘制时逐粒跳过。
#   R20 精修：判定纳入光尘圆点半径（margin 只向外扩、不缩小 x<730 / y<220 矩形）。
# ---------------------------------------------------------------------------
func _is_hud_avoid(logical_x: float, logical_y: float) -> bool:
	var sx := logical_x * logical_to_screen
	var sy := logical_y * logical_to_screen
	return (sx < hud_avoid_screen_w + hud_avoid_margin_px) \
		and (sy < hud_avoid_screen_h + hud_avoid_margin_px)


# ---------------------------------------------------------------------------
# ① 湿地倒影：垂直镜像 2×2 半透明色块（HD2D-FX-PLAN.md §3.3 / 占位 step6）
#    R18：源块关于 GROUND_Y 向下翻转 + 压缩到脚下 + 深度渐隐 + 逐行波纹，
#         画成连片的镜像色块，而非 1×1 点被地面横砖淹没成的一条水平亮线。
# ---------------------------------------------------------------------------
func _draw_reflection(t: float) -> void:
	var blocks := _collect_entity_blocks()
	var cx := BUFFER_W * 0.5
	# 水面基底：2 条极淡横向波纹（仅作湿地反光质感，主体是下方镜像色块）
	for k in range(2):
		var wy := float(round(GROUND_Y + 7.0 + float(k) * 16.0))
		draw_line(Vector2(cx - 26.0, wy), Vector2(cx + 26.0, wy),
				_c("#BFD0EA", 0.05), 1.0)
	for b in blocks:
		var sy: float = float(b["y"])
		# 垂直镜像：源块在 GROUND_Y 之上，关于 GROUND_Y 向下翻转
		var y_mirror := 2.0 * GROUND_Y - sy - 1.0
		# 压缩后落在 GROUND_Y 之下（向下延伸成镜像色块）
		var y_ref := GROUND_Y + (y_mirror - GROUND_Y) * reflection_squash
		# 深度衰减：离脚底越远越淡（水面吸收），脚底最清晰
		var depth := clampf((y_ref - GROUND_Y) / (31.0 * reflection_squash), 0.0, 1.0)
		var alpha := reflection_alpha * (1.0 - reflection_fade * depth)
		# 逐行横向错位 → 水波（相位含 y_ref，行与行错开）
		var ripple_dx := sin(t * 1.4 + y_ref * 0.35) * reflection_ripple * BUFFER_W
		# 2×2 半透明色块连成镜像轮廓（普通 Mix 减色，非 Add）
		draw_rect(Rect2(float(round(float(b["x"]) + ripple_dx)), float(round(y_ref)),
					reflection_block_px, reflection_block_px),
				_c_palette_alpha(int(b["idx"]), alpha))


# ---------------------------------------------------------------------------
# ② 体积光：draw_colored_polygon ×6 + draw_line 中心高光（HD2D-FX-PLAN.md §3.1 / step5）
#    R18：层数 4→6、spread 递进更密、峰值 alpha 保持 0.18 不抬高（不糊画面），
#         另补「柔核 + 亮核」两道暖金中心高光带强化主光方向。
# ---------------------------------------------------------------------------
func _draw_godrays(_t: float) -> void:
	var bottom := GROUND_Y + 30.0
	for i in range(godray_layers):
		var spread := godray_spread_base + float(i) * godray_spread_step
		var poly := PackedVector2Array([
			LIGHT_POS,
			Vector2(LIGHT_POS.x - spread, bottom),
			Vector2(LIGHT_POS.x + spread, bottom)
		])
		# _draw() 无逐调用 Add 混合参数，用低 alpha 多次叠加近似径向光束衰减
		draw_colored_polygon(poly, _c("#FFD27A", godray_alpha[i]))
	# 中心高光带：较宽柔核 + 锐利亮核（只在暖金主光方向，不铺满画面）
	draw_line(LIGHT_POS, Vector2(LIGHT_POS.x, bottom), _c("#FFD27A", 0.16), 3.0)
	draw_line(LIGHT_POS, Vector2(LIGHT_POS.x, bottom), _c("#FFF0C2", 0.12), 1.0)


# ---------------------------------------------------------------------------
# ③ 光尘：draw_circle()，seed=PLACEHOLDER_SEED 固定（HD2D-FX-PLAN.md §3.2 / step5+8）
#    R18/R20：绘制时逐粒跳过 HUD 矩形（约 x<730、y<220），避免面板被点状遮挡。
# ---------------------------------------------------------------------------
func _draw_motes(t: float) -> void:
	for m in _motes_far:
		var y := fposmod(float(m["y0"]) - float(m["speed"]) * t, BUFFER_H)
		var x := float(m["x0"]) + sin(t * float(m["freq"]) + float(m["phase"])) * 3.0
		if _is_hud_avoid(x, y):
			continue
		draw_circle(Vector2(float(round(x)), float(round(y))), float(m["size"]), _c("#BFD0EA", 0.25))
	for m in _motes_near:
		var y := fposmod(float(m["y0"]) - float(m["speed"]) * t, BUFFER_H)
		var x := float(m["x0"]) + sin(t * float(m["freq"]) + float(m["phase"])) * 3.0
		if _is_hud_avoid(x, y):
			continue
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
