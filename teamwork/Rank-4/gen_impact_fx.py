# -*- coding: utf-8 -*-
"""
R31 / v0.9.0 · Rank-4 程序化 PIL 生成 impact_fx.png + import.json
派单 cmd-20261111-133549-891-A4 · AI=4 · 工位 Rank-4

零 GPU job / 零付费 / 零外部依赖（仅本地 Pillow 12.3.0，已装）。
规格（契约 §9.3 / I-5 两层口径）：
  · 128px 基准画布 × 4 帧「冲击环 / 暖金闪光」逐像素；
  · 单帧 ≤16 色受控索引（从项目级色库取子集）、RGBA 保 alpha；
  · 硬边 / 无渐变 / 无 dithering / 无噪点（前景 alpha 仅 255，背景 alpha 仅 0，
    纯色块 + 整数距离平方阈值，全程确定性几何，无随机、无插值、无抖动）。
输出：godot/assets/generated/r23/impact_fx.png（512×128，4 帧横向）
      godot/assets/generated/r23/import.json
"""
import json
import os
from PIL import Image

ROOT = "F:/Game/aierdengfahuan"
GEN = ROOT + "/godot/assets/generated"
R23 = GEN + "/r23"
PAL_PATH = GEN + "/palette_256.json"
OUT_PNG = R23 + "/impact_fx.png"
OUT_JSON = R23 + "/import.json"

os.makedirs(R23, exist_ok=True)

# ---------------------------------------------------------------------------
# 项目级色库真源（只读引用，不改写他人文件）
# ---------------------------------------------------------------------------
with open(PAL_PATH, encoding="utf-8") as f:
    pal = json.load(f)
COLORS = pal["colors"]                       # 实测 32 色（status=frozen_temporary_R2）
SPEC = pal.get("spec", {})
LIB_MEASURED = len(COLORS)
LIB_DECLARED_MAX = int(SPEC.get("max_colors", 256))
LIB_ID = pal.get("palette_id", "hd2d_index_256_v1")

# 受控索引槽：全部落在项目级色库 colors[0..15]（与 hd2d_fx.gd PALETTE_HEX 对齐）。
# 单帧只从这 16 槽中取子集，实际每帧用量见实测。
IDX = {
    "warm_white": 0,    # #FFF0C2 暖白核心
    "warm_gold": 1,     # #FFD27A 主环暖金
    "gold_orange": 2,   # #F0A94C 中环金橙
    "deep_gold": 3,     # #C97A2E 外环深金
    "dark_gold": 4,     # #8A5A22 暖金收束
    "cold_white": 5,    # #BFD0EA 冷白次级星芒
    "indigo": 7,        # #4A6089 冷蓝细环（金线深蓝对比）
    "night_blue": 9,    # #16233F 冷夜底
    "light_gold": 15,   # #E8C479 十字星芒浅金
}


def rgba(i):
    h = COLORS[i].lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


C = {k: rgba(v) for k, v in IDX.items()}
TRANSPARENT = (0, 0, 0, 0)

FW = FH = 128
COLS, ROWS = 4, 1
CX = CY = 64

# [PLACEHOLDER] 4 帧几何参数待试玩校准。
# rationale：以「起→扩→峰→收」四段表现一次冲击的半径/星芒/核心演化；
#   frame3 环按 4 条对角扇区断裂 + 主环压到深金，表达暖金收束，非随机噪点。
FRAMES = [
    {"r": 10, "w": 3, "star": 8,  "core": 2, "break": False, "tone": "warm_gold"},
    {"r": 20, "w": 3, "star": 14, "core": 2, "break": False, "tone": "warm_gold"},
    {"r": 32, "w": 4, "star": 20, "core": 3, "break": False, "tone": "warm_gold"},
    {"r": 44, "w": 3, "star": 10, "core": 1, "break": True,  "tone": "dark_gold"},
]

sheet = Image.new("RGBA", (FW * COLS, FH * ROWS), TRANSPARENT)
px = sheet.load()


def ring_bands(p):
    """由内到外的硬边同心环：(内半径, 外半径, 颜色)，区间互不相交。"""
    r, w = p["r"], p["w"]
    return [
        (r,           r + w,         C[p["tone"]]),      # 主环（frame3 收束为暗金）
        (r + w + 2,   r + 2 * w + 2, C["gold_orange"]),  # 中环
        (r + 2 * w + 4, r + 3 * w + 4, C["deep_gold"]),  # 外环
        (r + 3 * w + 7, r + 3 * w + 8, C["indigo"]),     # 最外冷蓝细环（1px，金线深蓝）
    ]


def is_break(dx, dy):
    """frame3 收束：4 条对角扇区（|dx|≈|dy|）断裂，硬边确定性。"""
    return abs(abs(dx) - abs(dy)) <= 2


for fi, p in enumerate(FRAMES):
    ox = fi * FW
    bands = ring_bands(p)
    for y in range(FH):
        dy = y - CY
        for x in range(FW):
            dx = x - CX
            d2 = dx * dx + dy * dy
            col = None
            # ① 硬边同心环（整数距离平方阈值，命中即取）
            for (rin, rout, cc) in bands:
                if rin * rin <= d2 < rout * rout:
                    if p["break"] and cc != C["indigo"] and is_break(dx, dy):
                        col = None          # 断裂缺口（透明），非噪点
                    else:
                        col = cc
                    break
            # ② 环未命中（或断裂）时，按优先级画核心 / 星芒（硬边、纯色）
            if col is None:
                if abs(dx) <= p["core"] and abs(dy) <= p["core"]:
                    col = C["warm_white"]                       # 暖白核心方块
                elif (dy == 0 and abs(dx) <= p["star"]) or (dx == 0 and abs(dy) <= p["star"]):
                    col = C["light_gold"]                       # 十字星芒（1px 硬边）
                elif abs(dx) == abs(dy) and 0 < abs(dx) <= max(4, p["star"] // 2) \
                        and d2 > p["r"] * p["r"]:
                    col = C["cold_white"]                       # 对角次级星芒（冷白，环外短段）
                elif (r_out := p["r"] + 3 * p["w"] + 9) \
                        and r_out * r_out <= d2 < (r_out + 1) * (r_out + 1) \
                        and (abs(dx) <= 1 or abs(dy) <= 1):
                    col = C["night_blue"]                       # 最外环 4 个正交冷夜端点（对称设计点）
            if col is None:
                continue
            px[ox + x, y] = col

sheet.save(OUT_PNG, "PNG")

# ---------------------------------------------------------------------------
# 落盘后实测：每帧 RGBA 色数 / alpha 档 / 尺寸 / 字节数
# ---------------------------------------------------------------------------
W, H = sheet.size
frame_counts = []
frame_colors_hex = []
alpha_bins = set()
for fi in range(COLS):
    seen = set()
    for y in range(FH):
        for x in range(FW):
            c = px[fi * FW + x, y]
            seen.add(c)
            alpha_bins.add(c[3])
    frame_counts.append(len(seen))
    hexes = sorted({"#%02X%02X%02X" % (c[0], c[1], c[2]) for c in seen if c[3] != 0})
    frame_colors_hex.append(hexes)

all_used_hex = sorted({h for hs in frame_colors_hex for h in hs})
png_bytes = os.path.getsize(OUT_PNG)

max_per_frame = max(frame_counts)
within_16 = all(n <= 16 for n in frame_counts)
hard_alpha = (alpha_bins == {0, 255})

# ---------------------------------------------------------------------------
# import.json（I-5：帧尺寸 / 锚点 / 帧数 / 动作名 + §9.3 两层口径）
# ---------------------------------------------------------------------------
import_doc = {
    "schema_version": "1.0",
    "asset_id": "impact_fx_r23_v1",
    "res_path": "res://assets/generated/r23/impact_fx.png",
    "sprite_sheet": "impact_fx.png",
    "frame_width": FW,
    "frame_height": FH,
    "columns": COLS,
    "rows": ROWS,
    "frame_count": COLS * ROWS,
    "anchor": {"x": 64, "y": 64,
               "note": "冲击环/闪光中心锚定（特效类，非脚贴地）；全帧共用，禁止逐帧偏移"},
    "actions": [
        {"name": "impact", "start_frame": 0, "end_frame": 3, "fps": 12, "loop": False}
    ],
    "pose_names": ["impact"],
    "palette": all_used_hex,
    "palette_id": LIB_ID,
    "palette_ref": "res://assets/generated/palette_256.json",
    "canvas_base_px": 128,
    "base_canvas_px": 128,
    "indexed": True,
    "max_colors": 16,
    "per_frame_max_colors": 16,
    "color_depth": "RGBA8 (alpha preserved)",
    "hard_edge": True,
    "gradient": False,
    "dithering": False,
    "noise": False,
    "alpha_bins": sorted(alpha_bins),
    "filter": "nearest",
    "mipmaps": False,
    "compression": "lossless",
    "default_texture_filter": 0,
    "expected_import_settings": {
        "compress_mode": "lossless",
        "mipmaps": False,
        "texture_filter": "Nearest",
        "project_default_texture_filter": 0,
        "fix_alpha_border": True,
        "process_fix_alpha_border": True
    },
    "color_policy": {
        "contract": "00-协作契约.md §9.3 / I-5（R25 裁决 A15 统一口径）",
        "two_layers": {
            "project_palette_min_colors": 256,
            "per_frame_max_colors": 16
        },
        "project_palette": {
            "palette_id": LIB_ID,
            "palette_ref": "res://assets/generated/palette_256.json",
            "declared_max_colors": LIB_DECLARED_MAX,
            "measured_color_count": LIB_MEASURED,
            "meets_ge_256": LIB_MEASURED >= 256,
            "status": pal.get("status", "")
        },
        "note": ("单帧层：每帧从项目级色库取 ≤16 色受控索引，实测见 measured_frame_colors，全部 ≤16。"
                 "项目级层：按 §9.3 要求项目级色库 ≥256 色；当前 palette_256.json 实测 colors 仅 "
                 "%d 色（spec.max_colors=%d，status=%s），未达 ≥256 下限，属既有口径差异，"
                 "本轮只引用不扩写他人色库文件、不谎报，列为待总指挥裁决项。"
                 % (LIB_MEASURED, LIB_DECLARED_MAX, pal.get("status", "")))
    },
    "pipeline": "procedural_pil_pixel",
    "pipeline_tier": "fallback",
    "zero_gpu_job": True,
    "zero_paid_service": True,
    "zero_external_dependency": True,
    "generated_by": "Pillow 12.3.0 putpixel 逐像素；零渐变/零 dithering/零噪点/零随机",
    "measured_frame_colors": frame_counts,
    "measured_frame_hex": frame_colors_hex,
    "measured_max_per_frame": max_per_frame,
    "measured_within_16": within_16,
    "measured_hard_alpha_only_0_255": hard_alpha,
    "frames": [
        {"index": i, "action": "impact", "measured_colors": frame_counts[i]}
        for i in range(COLS)
    ],
    "sheet_px": [W, H],
    "png_bytes": png_bytes,
    "notes": ("R31 / v0.9.0 新写。4 帧冲击环/暖金闪光，128px 基准画布，RGBA 保 alpha；"
              "几何数值为 [PLACEHOLDER] 待试玩校准（rationale：起→扩→峰→收四段半径/星芒/核心演化，"
              "frame3 对角扇区断裂表达暖金收束）。ComfyUI 仍是主美术路线，本件是零外部依赖程序化管线产出。"),
    "generated_at": "2026-11-11",
    "version": "v1"
}
with open(OUT_JSON, "w", encoding="utf-8") as f:
    json.dump(import_doc, f, ensure_ascii=False, indent=2)

# ---------------------------------------------------------------------------
print("===== [R31][IMPACT_FX] 实测结论 =====")
print("项目级色库: id=%s 实测色数=%d 声明上限=%d 是否>=256=%s status=%s" % (
    LIB_ID, LIB_MEASURED, LIB_DECLARED_MAX, LIB_MEASURED >= 256, pal.get("status", "")))
print("PNG: %s size=%dx%d bytes=%d" % (OUT_PNG, W, H, png_bytes))
print("逐帧 RGBA 色数(含透明): %s | 最大单帧=%d | 全部<=16=%s" % (
    frame_counts, max_per_frame, within_16))
print("逐帧取用 hex: %s" % frame_colors_hex)
print("alpha 档集合: %s | 仅 0/255(硬边无渐变)=%s" % (sorted(alpha_bins), hard_alpha))
print("受控色板(全表实际取用): %s" % all_used_hex)
print("import.json: %s" % OUT_JSON)
