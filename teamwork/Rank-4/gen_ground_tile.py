# -*- coding: utf-8 -*-
"""
Rank-4 · R13 · 程序化地面 tile 占位生成器（零外部生成服务 / 零付费 / 仅 Pillow）

要点：
- 128x128，暖灰石土 x 冷蓝夜雾，左上暖金主光高光 + 右下冷夜雾阴影；
- 全程整数坐标矩形 / 线 / 点绘制：无 resize、无抗锯齿字体、无模糊、硬像素边；
- 全局量化到 <=256 色：显式取用全项目共享板 hd2d_index_256_v1（冻结 32 色），
  dither=NONE，输出 P 模式索引 PNG，Nearest 整数倍放大不插值出新色；
- 固定 seed，可复现；仅为地形占位，ComfyUI 仍是主美术路线。

用法：python teamwork/Rank-4/gen_ground_tile.py
"""
import json
import os
import random
import shutil
from PIL import Image, ImageDraw

ROOT = "F:/Game/aierdengfahuan"
PALETTE_JSON = ROOT + "/godot/assets/generated/palette_256.json"
DST_GODOT = ROOT + "/godot/assets/generated/terrain/ground_tile.png"
DST_RANK4 = ROOT + "/teamwork/Rank-4/ground_tile.png"

W = H = 128
SEED = 1304
random.seed(SEED)

# ---- 1) 读取全项目共享 <=256 色索引板（当前冻结 32 色），逐字取用，不私加 ----
with open(PALETTE_JSON, "r", encoding="utf-8") as f:
    board = json.load(f)
hexes = board["colors"]
assert len(hexes) == 32, "共享板应冻结为 32 色"
colors = [tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) for h in hexes]

# 语义族索引（对齐 palette_256.json::semantic_groups）
STONE = [colors[i] for i in (18, 19, 20, 21, 22)]   # 暖灰石土，亮 -> 暗
COLD = [colors[i] for i in (5, 6, 7, 8, 9, 10)]      # 冷夜雾冷蓝，亮 -> 暗
DEEP = [colors[i] for i in (11, 12, 13, 14)]         # 深蓝 UI
GOLD = [colors[i] for i in (0, 1, 2, 3, 4)]          # 暖金主光
VEG = [colors[i] for i in (23, 24, 25, 26)]          # 植被 / 苔点


def lerp(a, b, t):
    """在相邻两档共享色之间线性插值，制造板外连续色，供后续全局量化收敛。"""
    return tuple(int(round(a[k] + (b[k] - a[k]) * t)) for k in range(3))


# ---- 2) RGB 底图：整数坐标硬边绘制 ----
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)

# 缝隙基底：最暗深蓝（冷夜雾）
d.rectangle([0, 0, W - 1, H - 1], fill=DEEP[3])

BRICK_W, BRICK_H = 32, 16          # 128 可整除；奇数行错缝半砖 16px -> 可无缝平铺
for row in range(H // BRICK_H):
    y0 = row * BRICK_H
    xoff = BRICK_W // 2 if row % 2 else 0
    for col in range(-1, W // BRICK_W + 1):
        x0 = col * BRICK_W + xoff
        bx0, by0 = x0 + 1, y0 + 1                  # 1px 硬缝
        bx1, by1 = x0 + BRICK_W - 2, y0 + BRICK_H - 2
        if bx1 < 0 or bx0 > W - 1:               # 整块在画布外的跳过（边缘仍会被 clip）
            continue
        # 主体：石土族相邻档插值（板外连续色 -> 量化时收敛回共享板）
        f = random.random() * (len(STONE) - 1)
        i = int(f)
        body = lerp(STONE[i], STONE[min(i + 1, len(STONE) - 1)], f - i)
        d.rectangle([bx0, by0, bx1, by1], fill=body)
        # 上 / 左受光边：暖灰亮档，少量暖金高光（暖金主光自左上）
        hi = GOLD[1] if random.random() < 0.30 else STONE[0]
        d.line([(bx0, by0), (bx1, by0)], fill=hi)
        d.line([(bx0, by0), (bx0, by1)], fill=STONE[0])
        # 下 / 右背光边：冷蓝暗档（冷夜雾阴影）
        d.line([(bx0, by1), (bx1, by1)], fill=COLD[3])
        d.line([(bx1, by0), (bx1, by1)], fill=COLD[4])
        # 砖内硬像素斑点：碎石 / 苔 / 极少暖金，整数坐标、无抗锯齿
        for _ in range(random.randint(3, 6)):
            px = random.randint(bx0 + 2, bx1 - 2)
            py = random.randint(by0 + 2, by1 - 2)
            r = random.random()
            if r < 0.55:
                c = STONE[random.randint(2, 4)]
            elif r < 0.80:
                c = COLD[random.randint(2, 5)]
            elif r < 0.93:
                c = VEG[random.randint(1, 3)]
            else:
                c = GOLD[2]
            d.point((px, py), fill=c)
            if random.random() < 0.25:
                d.point((px + 1, py), fill=c)     # 2px 硬点，仍为整数坐标

pre_unique = len(set(img.get_flattened_data()))

# ---- 3) 全局量化到 <=256 色：显式共享板 + dither=NONE（硬像素边不变） ----
pal_img = Image.new("P", (1, 1))
flat = []
for (r, g, b) in colors:
    flat += [r, g, b]
flat += list(colors[-1]) * (256 - len(colors))      # 余位重复末色，避免引入板外黑
pal_img.putpalette(flat)
q = img.quantize(palette=pal_img, dither=Image.Dither.NONE)
assert q.mode == "P", "量化结果应为索引 P 模式"

os.makedirs(os.path.dirname(DST_GODOT), exist_ok=True)
q.save(DST_GODOT, optimize=True)
shutil.copyfile(DST_GODOT, DST_RANK4)

# ---- 4) 统计与校验（重新打开真跑，非内存自报） ----
chk = Image.open(DST_GODOT)
pal = chk.getpalette()
cnt_idx = chk.getcolors(maxcolors=1 << 20)          # [(count, palette_index), ...]
used_rgb = {tuple(pal[3 * i:3 * i + 3]) for _, i in cnt_idx}
idx_used = len(cnt_idx)
uniq = len(used_rgb)
nbytes = os.path.getsize(DST_GODOT)
nbytes2 = os.path.getsize(DST_RANK4)

# Nearest 适用性：整数倍放大只复制像素，不插值出新色
up = chk.convert("RGB").resize((W * 2, H * 2), Image.Resampling.NEAREST)
up_set = set(up.get_flattened_data())

in_board = used_rgb.issubset(set(colors))
no_new_color = (up_set == used_rgb)
transparent = chk.info.get("transparency")

print("=== R13 ground_tile 真跑统计 ===")
print("palette_id =", board["palette_id"], " board_colors =", len(hexes))
print("seed =", SEED)
print("pre_quantize_unique_rgb =", pre_unique)
print("size =", chk.size, " mode =", chk.mode)
print("palette_indices_used =", idx_used)
print("unique_colors =", uniq)
print("file_bytes_godot =", nbytes)
print("file_bytes_rank4 =", nbytes2, " copy_equal =", nbytes == nbytes2)
print("all_colors_in_shared_board =", in_board)
print("nearest_2x_no_new_color =", no_new_color)
print("transparency =", transparent)
print("quantize_dither = NONE")
assert chk.size == (W, H) and chk.mode == "P"
assert uniq <= 256 and in_board and no_new_color and transparent is None
assert nbytes == nbytes2
print("ASSERT = ALL PASS")
