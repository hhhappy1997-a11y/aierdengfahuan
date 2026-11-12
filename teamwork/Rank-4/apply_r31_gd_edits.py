# -*- coding: utf-8 -*-
"""
R31 / v0.9.0 · Rank-4 对 hd2d_fx.gd / hd2d_parallax.gd 做光尘密度 + 湿地倒影精修。
派单 cmd-20261111-133549-891-A4 · AI=4 · 工位 Rank-4

方式：按「函数签名 → 下一个顶层 func」切片，整体替换函数体，并自动原样保留
      函数之后的注释块 / 空行（tail）。每次替换断言签名唯一命中，防止误改。
约束：只改 _draw() 绘制参数与函数体；保留全部档位开关 / 接口 / 节点名 / HUD 避让；
      不写 courtyard.tscn（节点数 41 / uv 2/1/1 / A38 断言不受影响）。
"""
import re

FX = "F:/Game/aierdengfahuan/godot/scripts/hd2d_fx.gd"
PX = "F:/Game/aierdengfahuan/godot/scripts/render/hd2d_parallax.gd"


def load(path):
    raw = open(path, "rb").read()
    nl = "\r\n" if b"\r\n" in raw else "\n"
    text = raw.decode("utf-8")
    if nl == "\r\n":
        text = text.replace("\r\n", "\n")
    return text, nl


def save(path, text, nl):
    if nl == "\r\n":
        text = text.replace("\n", "\r\n")
    open(path, "wb").write(text.encode("utf-8"))


def replace_func(text, sig, new_func):
    cnt = text.count(sig)
    assert cnt == 1, "签名非唯一 count=%d : %r" % (cnt, sig)
    start = text.index(sig)
    m = re.search(r"\nfunc ", text[start + 1:])
    nxt = start + 1 + m.start() if m else len(text)
    old_block = text[start:nxt]
    lines = old_block.split("\n")
    # 最后一条以 tab 开头（函数体语句）或 "func " 开头的行之后，均为需原样保留的 tail
    cut = len(lines)
    for idx in range(len(lines) - 1, -1, -1):
        ln = lines[idx]
        if ln.startswith("\t") or ln.startswith("func "):
            cut = idx + 1
            break
    tail = "\n".join(lines[cut:])
    new_block = new_func.rstrip("\n") + "\n" + tail
    print("  OK %-28s (旧 %d 行 -> 新函数 %d 行, tail %d 行保留)" % (
        sig.split("(")[0].replace("func ", ""), len(lines),
        new_func.count("\n") + 1, len(lines) - cut))
    return text[:start] + new_block + text[nxt:]


# ===========================================================================
# hd2d_fx.gd（layer=10 四项光效；fx_profile desktop 全开 / mobile 全关 = 既有降级层开关）
# ===========================================================================
FX_BUILD = """func _build_motes() -> void:
\tvar rng := RandomNumberGenerator.new()
\trng.seed = PLACEHOLDER_SEED
\t_motes_far.clear()
\tfor i in range(MOTES_FAR_COUNT):
\t\t_motes_far.append({
\t\t\t"x0": rng.randf_range(0.0, BUFFER_W),
\t\t\t"y0": rng.randf_range(0.0, BUFFER_H),
\t\t\t"phase": rng.randf_range(0.0, TAU),
\t\t\t"freq": rng.randf_range(TAU / 4.0, TAU / 2.0),
\t\t\t"speed": rng.randf_range(2.0, 6.0),
\t\t\t"size": rng.randf_range(1.0, 3.0),
\t\t\t"tone": i % 3
\t\t})
\t_motes_near.clear()
\tfor i in range(MOTES_NEAR_COUNT):
\t\t_motes_near.append({
\t\t\t"x0": rng.randf_range(0.0, BUFFER_W),
\t\t\t"y0": rng.randf_range(0.0, BUFFER_H),
\t\t\t"phase": rng.randf_range(0.0, TAU),
\t\t\t"freq": rng.randf_range(TAU / 4.0, TAU / 2.0),
\t\t\t"speed": rng.randf_range(2.0, 6.0),
\t\t\t"size": rng.randf_range(1.0, 3.0),
\t\t\t"tone": i % 3
\t\t})
"""

FX_MOTES = """func _draw_motes(t: float) -> void:
\tfor m in _motes_far:
\t\tvar y := fposmod(float(m["y0"]) - float(m["speed"]) * t, BUFFER_H)
\t\tvar x := float(m["x0"]) + sin(t * float(m["freq"]) + float(m["phase"])) * 3.0
\t\tif _is_hud_avoid(x, y):
\t\t\tcontinue
\t\t# 金线深蓝：远景冷白为主，每 3 粒嵌 1 粒深蓝靛，拉开平滑景深冷色层次
\t\tvar far_hex := "#BFD0EA"
\t\tif int(m["tone"]) == 1:
\t\t\tfar_hex = "#4A6089"
\t\tdraw_circle(Vector2(float(round(x)), float(round(y))), float(m["size"]), _c(far_hex, 0.25))
\tfor m in _motes_near:
\t\tvar y := fposmod(float(m["y0"]) - float(m["speed"]) * t, BUFFER_H)
\t\tvar x := float(m["x0"]) + sin(t * float(m["freq"]) + float(m["phase"])) * 3.0
\t\tif _is_hud_avoid(x, y):
\t\t\tcontinue
\t\t# 暖金近景：每 3 粒嵌 1 粒浅金高光，与冷夜雾远景形成暖金 × 冷夜强对比
\t\tvar near_hex := "#FFD27A"
\t\tif int(m["tone"]) == 1:
\t\t\tnear_hex = "#FFF0C2"
\t\tdraw_circle(Vector2(float(round(x)), float(round(y))), float(m["size"]), _c(near_hex, 0.45))
"""

FX_REFLECT = """func _draw_reflection(t: float) -> void:
\tvar blocks := _collect_entity_blocks()
\tvar cx := BUFFER_W * 0.5
\t# [PLACEHOLDER] R31 冷夜雾湿地水面基底：离散冷蓝横带（越深越浓），只铺倒影区宽度
\tvar water_w := 60.0
\tfor k in range(reflection_water_bands):
\t\tvar wa := 0.05 + 0.035 * float(k)
\t\tdraw_rect(Rect2(float(round(cx - water_w * 0.5)),
\t\t\t\tfloat(round(GROUND_Y + 2.0 + float(k) * 7.0)),
\t\t\t\twater_w, 7.0), _c("#16233F", wa))
\t# 水面高光横线：暖金 × 冷白交替（湿地对主光 / 夜雾的镜面反射，硬边 1px）
\tfor q in range(3):
\t\tvar wy := float(round(GROUND_Y + 6.0 + float(q) * 15.0))
\t\tvar hx := sin(t * 0.9 + float(q)) * 3.0
\t\tdraw_line(Vector2(float(round(cx - 30.0 + hx)), wy),
\t\t\t\tVector2(float(round(cx + 30.0 + hx)), wy), _c("#FFD27A", 0.10), 1.0)
\t\tdraw_line(Vector2(float(round(cx - 24.0 - hx)), wy + 2.0),
\t\t\t\tVector2(float(round(cx + 24.0 - hx)), wy + 2.0), _c("#BFD0EA", 0.07), 1.0)
\tfor b in blocks:
\t\tvar sy: float = float(b["y"])
\t\tvar y_mirror := 2.0 * GROUND_Y - sy - 1.0
\t\tvar y_ref := GROUND_Y + (y_mirror - GROUND_Y) * reflection_squash
\t\tvar depth := clampf((y_ref - GROUND_Y) / (31.0 * reflection_squash), 0.0, 1.0)
\t\tvar alpha := reflection_alpha * (1.0 - reflection_fade * depth)
\t\tvar ripple_dx := sin(t * 1.4 + y_ref * 0.35) * reflection_ripple * BUFFER_W
\t\tdraw_rect(Rect2(float(round(float(b["x"]) + ripple_dx)), float(round(y_ref)),
\t\t\t\t\treflection_block_px, reflection_block_px),
\t\t\t\t_c_palette_alpha(int(b["idx"]), alpha))
\t\t# 深层叠冷夜雾：把暖金倒影压进冷蓝水面（暖金 × 冷夜雾分离）
\t\tif depth > 0.35:
\t\t\tdraw_rect(Rect2(float(round(float(b["x"]) + ripple_dx)), float(round(y_ref)),
\t\t\t\t\treflection_block_px, reflection_block_px),
\t\t\t\t\t_c("#4A6089", reflection_cold_tint * depth * alpha))
"""


# ===========================================================================
# hd2d_parallax.gd（layer=5 视差远景；GRADE_FORCE_DRAW_FALLBACK / desktop-mobile 双档 = 既有降级层）
# ===========================================================================
PX_BUILD = """# [PLACEHOLDER] R31 / v0.9.0 · 视差光尘密度精修（待试玩校准）
# rationale：desktop 档新增 16 远 / 12 近光尘并做「金线深蓝」冷暖分层，强化
#   「像素精灵 vs 平滑景深」；mobile 档逐字保持原 40 / 20 粒与原色原 alpha
#   （_draw_layered_motes 按 MOTE_BASE_* 门控跳过新增粒）→ 移动端档位零劣化。
#   三波 WAVE_* / R29 shader 降级层开关 / set_wave_index 接口全部保留不改。
const MOTE_BASE_FAR: int = 40
const MOTE_BASE_NEAR: int = 20
const MOTE_FAR_COUNT: int = 56
const MOTE_NEAR_COUNT: int = 32


func _build_motes() -> void:
\tvar rng := RandomNumberGenerator.new()
\trng.seed = SEED
\t_far_motes.clear()
\t_near_motes.clear()
\tfor i in range(MOTE_FAR_COUNT):
\t\t_far_motes.append({
\t\t\t"x0": rng.randf_range(0.0, BUFFER_W),
\t\t\t"y0": rng.randf_range(0.0, HORIZON_Y + 40.0),
\t\t\t"phase": rng.randf_range(0.0, TAU),
\t\t\t"freq": rng.randf_range(TAU / 6.0, TAU / 3.0),
\t\t\t"speed": rng.randf_range(1.0, 3.0),
\t\t\t"size": rng.randf_range(0.7, 1.6),
\t\t\t"tone": i % 3
\t\t})
\tfor i in range(MOTE_NEAR_COUNT):
\t\t_near_motes.append({
\t\t\t"x0": rng.randf_range(0.0, BUFFER_W),
\t\t\t"y0": rng.randf_range(0.0, HORIZON_Y + 40.0),
\t\t\t"phase": rng.randf_range(0.0, TAU),
\t\t\t"freq": rng.randf_range(TAU / 4.0, TAU / 2.0),
\t\t\t"speed": rng.randf_range(3.0, 7.0),
\t\t\t"size": rng.randf_range(1.0, 2.4),
\t\t\t"tone": i % 3
\t\t})
"""

PX_MOTES = """func _draw_layered_motes(t: float) -> void:
\tvar desktop_extra: bool = (_r29_active_tier != "mobile")
\tfor i in range(_far_motes.size()):
\t\tif i >= MOTE_BASE_FAR and not desktop_extra:
\t\t\tcontinue
\t\tvar m: Dictionary = _far_motes[i]
\t\tvar y: float = fposmod(float(m["y0"]) - float(m["speed"]) * t, HORIZON_Y + 40.0)
\t\tvar x: float = float(m["x0"]) + sin(t * float(m["freq"]) + float(m["phase"])) * 3.0
\t\tif _is_hud_avoid(x, y):
\t\t\tcontinue
\t\tvar hexf: String = "#BFD0EA"
\t\tvar af: float = 0.22
\t\tif i >= MOTE_BASE_FAR:
\t\t\thexf = "#4A6089" if int(m["tone"]) == 1 else "#7E96BF"
\t\t\taf = 0.30
\t\tdraw_circle(Vector2(float(round(x)), float(round(y))), float(m["size"]), _c(hexf, af))
\tfor j in range(_near_motes.size()):
\t\tif j >= MOTE_BASE_NEAR and not desktop_extra:
\t\t\tcontinue
\t\tvar n: Dictionary = _near_motes[j]
\t\tvar y: float = fposmod(float(n["y0"]) - float(n["speed"]) * t, HORIZON_Y + 40.0)
\t\tvar x: float = float(n["x0"]) + sin(t * float(n["freq"]) + float(n["phase"])) * 4.0
\t\tif _is_hud_avoid(x, y):
\t\t\tcontinue
\t\tvar hexn: String = "#FFD27A"
\t\tvar an: float = 0.38
\t\tif j >= MOTE_BASE_NEAR:
\t\t\thexn = "#FFF0C2" if int(n["tone"]) == 1 else "#F0A94C"
\t\t\tan = 0.46
\t\tdraw_circle(Vector2(float(round(x)), float(round(y))), float(n["size"]), _c(hexn, an))
"""

PX_GROUND = """func _draw_ground_grade() -> void:
\tvar h: float = (BUFFER_H - HORIZON_Y) / float(GROUND_BANDS)
\tvar ground_hex: String = String(WAVE_GROUND_COLOR[_w - 1])
\tvar ground_mult: float = float(WAVE_GROUND_MULT[_w - 1])
\tfor k in range(GROUND_BANDS):
\t\tvar a: float = clampf((0.06 + 0.20 * (float(k) / float(GROUND_BANDS - 1))) * ground_mult,
\t\t\t\t0.0, 0.9)
\t\tdraw_rect(Rect2(-8.0, HORIZON_Y + float(k) * h,
\t\t\t\tBUFFER_W + 16.0, h + 1.0), _c(ground_hex, a))
\t# 地平线高光（1px，衔接天空 / 地面）：波3 转暖金，波1/2 沿用冷雾
\tvar glow_hex: String = "#4A6A9C"
\tif _w == 3:
\t\tglow_hex = "#D89A5A"
\tdraw_line(Vector2(-8.0, HORIZON_Y), Vector2(BUFFER_W + 8.0, HORIZON_Y),
\t\t\t_c(glow_hex, float(WAVE_HORIZON_GLOW[_w - 1])), 1.0)
\t# [PLACEHOLDER] R31 / v0.9.0 · 湿地倒影衔接（待试玩校准）
\t# rationale：3D 暖金砖地上补离散「冷夜雾 × 暖金」反光横带，与 hd2d_fx.gd 的
\t#   像素角色湿地倒影呼应，强化「像素精灵 vs 平滑景深」对比；低 alpha 不遮挡
\t#   3D 地面 / HUD。仅 desktop 档绘制，mobile 档零新增绘制（不劣化）。
\tif _r29_active_tier != "mobile":
\t\tfor q in range(3):
\t\t\tvar ry: float = HORIZON_Y + 4.0 + float(q) * 11.0
\t\t\tdraw_rect(Rect2(-8.0, ry, BUFFER_W + 16.0, 2.0), _c("#16233F", 0.06 + 0.03 * float(q)))
\t\t\tvar rh: String = "#FFD27A" if _w == 3 else "#7E96BF"
\t\t\tdraw_line(Vector2(-8.0, ry + 2.0), Vector2(BUFFER_W + 8.0, ry + 2.0),
\t\t\t\t\t_c(rh, 0.05), 1.0)
"""


def apply(path, jobs):
    text, nl = load(path)
    print("\n[PATCH] %s" % path)
    for sig, new_func in jobs:
        text = replace_func(text, sig, new_func)
    save(path, text, nl)
    return text


fx_text = apply(FX, [
    ("func _build_motes() -> void:", FX_BUILD),
    ("func _draw_motes(t: float) -> void:", FX_MOTES),
    ("func _draw_reflection(t: float) -> void:", FX_REFLECT),
])
px_text = apply(PX, [
    ("func _build_motes() -> void:", PX_BUILD),
    ("func _draw_layered_motes(t: float) -> void:", PX_MOTES),
    ("func _draw_ground_grade() -> void:", PX_GROUND),
])

# ---------------------------------------------------------------------------
# 保留项自检（既有降级层开关 / 接口 / 节点名 / HUD 避让 / 三波 / A38 相关不动）
# ---------------------------------------------------------------------------
FX_KEEP = [
    '@export_enum("desktop", "mobile") var fx_profile',
    "func set_fx_profile(profile: String)",
    "_force_profile == PROFILE_MOBILE",
    'ENV_FORCE_PROFILE: String = "AIERDENG_FX_PROFILE"',
    '"FXReflection":', '"FXGodRays":', '"FXMotes":', '"FXBloom":',
    "func _is_hud_avoid(",
    "func _apply_profile()",
]
PX_KEEP = [
    "const GRADE_FORCE_DRAW_FALLBACK: bool = false",
    "func set_wave_index(w: int)",
    "func _r29_current_tier()",
    "const WAVE_SKY_TOP: Array",
    "func _is_hud_avoid(",
    "func _r29_draw_grade(",
]
print("\n===== [R31] 保留项自检 =====")
for k in FX_KEEP:
    assert k in fx_text, "hd2d_fx.gd 丢失保留项: %r" % k
    print("  FX OK  %s" % k)
for k in PX_KEEP:
    assert k in px_text, "hd2d_parallax.gd 丢失保留项: %r" % k
    print("  PX OK  %s" % k)
print("===== 全部保留项通过；两文件已写回 =====")
