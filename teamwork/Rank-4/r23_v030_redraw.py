# -*- coding: utf-8 -*-
"""
R25 / Rank-4 · 16 色受控色板重绘（本机 PIL 程序化，零付费、零外部素材服务）。
裁决 A15：项目级色库 >=256 唯一色、单帧 <=16 色索引；128px 基准画布，
64x64 原生逻辑网格 x2 NEAREST 放大；硬边无渐变 / 无 dithering / 无高频噪点；
RGBA 保 alpha（二值硬边）；ground_tile 左右上下边缘像素完全一致。
只换 r23/ 下 PNG 内容、路径逐字不变；旧版已备份 r23_pre_v030_backup/。
128bit 歧义待用户确认，不消歧、不编码进期望值。
"""
import os
import json
from PIL import Image, ImageDraw

ROOT = r'F:/Game/aierdengfahuan'
R23 = ROOT + '/godot/assets/generated/r23'
R4 = ROOT + '/teamwork/Rank-4'

# 单帧受控 16 色板（逐字取自既有 palette_256.json 的 32 功能色）
BASE16 = [
    (11, 18, 38), (22, 35, 63), (43, 58, 92), (74, 96, 137),
    (126, 150, 191), (191, 208, 234), (255, 240, 194), (255, 210, 122),
    (240, 169, 76), (201, 122, 46), (138, 90, 34), (198, 187, 164),
    (154, 142, 120), (110, 100, 83), (217, 88, 74), (111, 191, 142),
]
(NIGHT, BLUE_D, BLUE_M, BLUE_L, BLUE_H, COLD_W,
 GOLD_W, GOLD_L, GOLD_M, GOLD_D, BROWN,
 STONE_L, STONE_M, STONE_D, RED, GREEN) = range(16)
T = (0, 0, 0, 0)


def C(i):
    return BASE16[i] + (255,)


def HEX(c):
    return '#%02X%02X%02X' % c


def build_library():
    """项目级色库：16 基色 x 18 明度变体 + 原色；返回(色表, 单帧 16 基色在库内索引)。"""
    colors, base_index = [], []
    LV = 18
    for base in BASE16:
        grp = []
        for lv in range(LV):
            if lv < LV // 2:
                k = 1.0 - (lv / (LV // 2)) * 0.70
                grp.append(tuple(int(v * k) for v in base))
            else:
                u = (lv - LV // 2 + 1) / (LV - LV // 2 + 1)
                grp.append(tuple(int(v + (255 - v) * u * 0.55) for v in base))
        grp.append(base)
        base_index.append(len(colors) + len(grp) - 1)
        colors.extend(grp)
    return colors, base_index


def canvas():
    return Image.new('RGBA', (64, 64), T)


def rect(d, x, y, w, h, ci):
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=C(ci))


def dot(d, x, y, ci):
    d.point((x, y), fill=C(ci))


def frame_player(pose):
    im = canvas()
    d = ImageDraw.Draw(im)
    if pose == 'walk':
        rect(d, 22, 50, 5, 10, BLUE_D); rect(d, 37, 50, 5, 10, BLUE_D)
    elif pose == 'run':
        rect(d, 19, 50, 5, 10, BLUE_D); rect(d, 40, 49, 5, 11, BLUE_D)
    elif pose == 'roll':
        pass
    elif pose == 'death':
        rect(d, 18, 50, 28, 5, BLUE_D)
    else:
        rect(d, 24, 50, 5, 10, BLUE_D); rect(d, 35, 50, 5, 10, BLUE_D)

    if pose == 'roll':
        rect(d, 20, 40, 24, 18, BLUE_M)
        rect(d, 22, 42, 20, 6, BLUE_L)
        rect(d, 26, 44, 8, 8, RED)
        rect(d, 20, 50, 24, 2, GOLD_D)
        rect(d, 30, 56, 20, 2, STONE_L)
    elif pose == 'death':
        rect(d, 18, 48, 26, 8, BLUE_M)
        rect(d, 26, 49, 14, 4, BLUE_L)
        rect(d, 12, 47, 8, 9, RED)
        rect(d, 14, 49, 4, 3, STONE_L)
        rect(d, 30, 58, 18, 2, STONE_L)
        rect(d, 46, 57, 3, 3, GOLD_M)
    else:
        ox = 3 if pose == 'hitstun' else (2 if pose == 'run' else 0)
        oy = 2 if pose == 'run' else 0
        rect(d, 23 + ox, 34 + oy, 18, 16, BLUE_M)
        rect(d, 26 + ox, 36 + oy, 12, 6, BLUE_L)
        rect(d, 20 + ox, 33 + oy, 6, 5, GOLD_M)
        rect(d, 38 + ox, 33 + oy, 6, 5, GOLD_M)
        rect(d, 23 + ox, 47 + oy, 18, 2, GOLD_D)
        hy = 24 + oy - (2 if pose == 'run' else 0)
        rect(d, 27 + ox, hy, 10, 10, STONE_L)
        rect(d, 26 + ox, hy - 2, 12, 4, RED)
        rect(d, 29 + ox, hy + 3, 2, 2, NIGHT)
        rect(d, 34 + ox, hy + 3, 2, 2, NIGHT)
        if pose == 'hitstun':
            dot(d, 42 + ox, hy + 2, RED); dot(d, 44 + ox, hy + 5, RED); dot(d, 41 + ox, hy + 8, RED)
        if pose == 'attack_light':
            rect(d, 40, 34, 20, 2, STONE_L)
            rect(d, 58, 33, 3, 4, GOLD_W)
            rect(d, 38, 33, 4, 4, GOLD_M)
        elif pose == 'attack_heavy':
            rect(d, 39, 12, 2, 24, STONE_L)
            rect(d, 37, 10, 6, 3, GOLD_W)
            rect(d, 38, 34, 4, 4, GOLD_M)
        else:
            rect(d, 41, 38, 2, 20, STONE_L)
            rect(d, 40, 37, 4, 2, GOLD_M)
        if pose in ('run', 'walk'):
            rect(d, 18 + ox, 34 + oy, 4, 14, BLUE_D)
    return im


def frame_boss(move):
    im = canvas()
    d = ImageDraw.Draw(im)
    rect(d, 18, 26, 28, 26, STONE_D)
    rect(d, 22, 29, 20, 8, STONE_M)
    rect(d, 26, 16, 12, 12, NIGHT)
    rect(d, 25, 13, 14, 4, GOLD_D)
    rect(d, 28, 20, 3, 3, RED); rect(d, 33, 20, 3, 3, RED)
    rect(d, 14, 26, 6, 30, RED)
    rect(d, 44, 26, 6, 30, RED)
    rect(d, 22, 50, 6, 10, STONE_D); rect(d, 36, 50, 6, 10, STONE_D)
    if move == 'p1_dagger_slash':
        for i in range(10):
            rect(d, 46 + i, 30 - i, 2, 2, STONE_L)
        rect(d, 44, 32, 4, 3, GOLD_M)
    elif move == 'p1_staff_slam':
        rect(d, 50, 8, 3, 48, BROWN)
        rect(d, 47, 4, 9, 6, GOLD_W)
        rect(d, 49, 2, 5, 3, GOLD_L)
    else:  # p2_holy_hammer
        rect(d, 50, 22, 3, 34, BROWN)
        rect(d, 45, 12, 13, 10, GOLD_M)
        rect(d, 47, 14, 9, 4, GOLD_W)
        dot(d, 44, 10, GOLD_W); dot(d, 58, 12, GOLD_W); dot(d, 60, 20, GOLD_W)
    return im


def frame_ground():
    """128px 基准画布内 4x4 大砖；确定性磨损块（非高频噪点）；强制四边无缝。"""
    im = canvas()
    d = ImageDraw.Draw(im)
    rect(d, 0, 0, 64, 64, STONE_D)
    for by in range(4):
        for bx in range(4):
            x0, y0 = bx * 16, by * 16
            ci = STONE_L if (bx + by) % 2 == 0 else STONE_M
            rect(d, x0 + 1, y0 + 1, 14, 14, ci)
            rect(d, x0 + 2, y0 + 11, 10, 2, STONE_D)
            if (bx * 3 + by) % 3 == 0:
                rect(d, x0 + 4, y0 + 4, 3, 2, STONE_D)
            if (bx + by * 2) % 4 == 1:
                dot(d, x0 + 11, y0 + 6, GOLD_M)
            if (bx * 2 + by) % 5 == 2:
                dot(d, x0 + 7, y0 + 9, STONE_D)
    for y in range(64):
        im.putpixel((63, y), im.getpixel((0, y)))
    for x in range(64):
        im.putpixel((x, 63), im.getpixel((x, 0)))
    return im


def frame_decor():
    im = canvas()
    d = ImageDraw.Draw(im)
    for i in range(14):
        x = (i * 17 + 5) % 60; y = (i * 23 + 9) % 48
        rect(d, x, y, 2, 2, GOLD_W if i % 2 == 0 else COLD_W)
    for x in range(2, 64, 7):
        rect(d, x, 58, 2, 4, GREEN)
    return im


def up2(im):
    return im.resize((128, 128), Image.NEAREST)


PLAYER = ['idle', 'walk', 'run', 'roll', 'attack_light', 'attack_heavy', 'hitstun', 'death']
PLAYER_FILE = {p: 'player_%s.png' % p for p in PLAYER}
BOSS = ['p1_dagger_slash', 'p1_staff_slam', 'p2_holy_hammer']
BOSS_FILE = {m: 'boss_%s.png' % m for m in BOSS}

frames = {}
for p in PLAYER:
    frames[PLAYER_FILE[p]] = up2(frame_player(p))
for m in BOSS:
    frames[BOSS_FILE[m]] = up2(frame_boss(m))
frames['decor_layer.png'] = up2(frame_decor())
frames['ground_tile.png'] = up2(frame_ground())

for name, im in frames.items():
    im.save(os.path.join(R23, name))


def sheet(names, w):
    s = Image.new('RGBA', (w, 128), T)
    for i, n in enumerate(names):
        s.paste(frames[n], (i * 128, 0))
    return s


sheet([PLAYER_FILE[p] for p in PLAYER], 1024).save(os.path.join(R23, 'player_spritesheet.png'))
sheet([BOSS_FILE[m] for m in BOSS], 384).save(os.path.join(R23, 'boss_spritesheet.png'))

colors, base_index = build_library()
lib = {
    'schema_version': '1.0',
    'palette_id': 'hd2d_project_library_v030',
    'round': 'R25',
    'verdict': 'A15',
    'spec': {
        'project_color_library_unique_min': 256,
        'single_frame_max_color_indices': 16,
        'canvas_base_px': 128,
        'logical_grid_px': 64,
        'scale': 'x2 NEAREST',
        'alpha': 'RGBA binary (0 or 255), hard edge',
        '128bit_ambiguity': '待用户确认，不消歧、不编码进期望值',
    },
    'color_count': len(colors),
    'unique_count': len(set(colors)),
    'single_frame_palette_indices': base_index,
    'single_frame_hex': [HEX(c) for c in BASE16],
    'colors': [HEX(c) for c in colors],
    'note': '项目级色库>=256 唯一色；单帧仅取其中 16 个基色索引，满足裁决 A15 单帧<=16 色索引。',
}
with open(os.path.join(R4, 'palette_256_v030.json'), 'w', encoding='utf-8') as f:
    json.dump(lib, f, ensure_ascii=False, indent=2)


def uniq_visible(im):
    return len(set(c[:3] for c in im.getdata() if c[3] > 0))


print('=== R25 REDRAW VERIFY ===')
print('library color_count=%d unique_count=%d (A15 >=256)' % (len(colors), len(set(colors))))
assert len(set(colors)) >= 256
for name in sorted(frames):
    im = frames[name]
    u = uniq_visible(im)
    alphas = set(c[3] for c in im.getdata())
    print('  %-30s size=%s mode=%s uniq_vis_rgb=%2d alpha=%s' % (name, im.size, im.mode, u, sorted(alphas)))
    assert im.size == (128, 128) and im.mode == 'RGBA'
    assert u <= 16, name
    assert set(alphas) <= {0, 255}, name
print('  single frame <=16 visible RGB : ALL PASS')
for name in frames:
    im = frames[name]
    ok = all(im.getpixel((x, y)) == im.getpixel((x + 1, y)) == im.getpixel((x, y + 1)) == im.getpixel((x + 1, y + 1))
             for y in range(0, 128, 2) for x in range(0, 128, 2))
    assert ok, name
print('  x2 NEAREST (every 2x2 block uniform) : ALL PASS')
ps = Image.open(os.path.join(R23, 'player_spritesheet.png')).convert('RGBA')
bs = Image.open(os.path.join(R23, 'boss_spritesheet.png')).convert('RGBA')
assert ps.size == (1024, 128) and bs.size == (384, 128)
for i, p in enumerate(PLAYER):
    assert list(ps.crop((i * 128, 0, i * 128 + 128, 128)).getdata()) == list(frames[PLAYER_FILE[p]].getdata())
for i, m in enumerate(BOSS):
    assert list(bs.crop((i * 128, 0, i * 128 + 128, 128)).getdata()) == list(frames[BOSS_FILE[m]].getdata())
print('  spritesheet slice == single frame : 8/8 + 3/3 PASS')
g = frames['ground_tile.png']
L = [g.getpixel((0, y)) for y in range(128)]; R = [g.getpixel((127, y)) for y in range(128)]
T0 = [g.getpixel((x, 0)) for x in range(128)]; B = [g.getpixel((x, 127)) for x in range(128)]
print('  ground_tile LR equal=%s TB equal=%s' % (L == R, T0 == B))
assert L == R and T0 == B
assert all(BASE16[i] == colors[base_index[i]] for i in range(16))
print('  single frame 16 colors all indexed in project library : PASS')

# 目视联系表（产出先目视检查）
order = [PLAYER_FILE[p] for p in PLAYER] + [BOSS_FILE[m] for m in BOSS] + ['ground_tile.png', 'decor_layer.png']
CW, CH, cols = 256, 256, 4
rows = (len(order) + cols - 1) // cols
board = Image.new('RGBA', (cols * CW, rows * (CH + 18)), (16, 20, 32, 255))
bd = ImageDraw.Draw(board)
for i, n in enumerate(order):
    big = frames[n].resize((CW, CH), Image.NEAREST)
    x = (i % cols) * CW; y = (i // cols) * (CH + 18)
    board.paste(big, (x, y), big)
    bd.text((x + 4, y + CH + 2), n, fill=(255, 240, 194, 255))
board.save(os.path.join(R4, 'r23_v030_contact.png'))
print('  contact sheet -> teamwork/Rank-4/r23_v030_contact.png')
print('=== ALL PASS ===')
