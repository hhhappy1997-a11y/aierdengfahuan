# -*- coding: utf-8 -*-
"""
R26 / v0.4.0 · Rank-4 逐像素精修 16 色重绘（PIL，零付费 / 零外部素材生成服务）

相对 R25(v0.3.0) 的改动：
  ① 消除「积木感」：把 R25 的大矩形块改为逐像素轮廓化造型 —— 头盔圆顶/面甲眼缝/鼻梁/
     护颊/红缨、肩甲斜边梯形+铆钉、披风逐行飘动轮廓+明暗褶皱、胸甲收腰+板甲分层线+
     菱形纹章、鸢盾逐行弧边、剑身中脊/剑格/缠柄/剑首。全部为有意识放置的硬边色块。
  ② 重点修 death：横躺剪影抬到画面中部(y≈20..48)，头/躯干/武器分色，主体亮面用
     STEEL/WHITE/GOLD/COBALT_L(L55~95) 与地面 COBALT(L45)/DARK(L22) 拉开 >=2 档明度，
     下方留透明，不再贴地隐形。
  ③ 逐帧动作：每 pose 3 子帧、Boss 每招 3 子帧；子帧间有可见位移/姿态差
     (呼吸 dy / 武器角度 / 披风褶皱相位 / 腿部步态 / 躯干倾斜)。
     player_spritesheet.png 3072x128 (24 帧)、boss_spritesheet.png 1152x128 (9 帧)。
     帧物理顺序 x = action*3*128 + sub*128，与两份 .tres 的 AtlasTexture region 逐字对齐。
  ④ 地面收敛：ground_tile.png 去绿(TEAL)/黄(GOLD)杂色点，4x4 大砖保持，
     明度 4 阶(全蓝系 DARK/COBALT/COBALT_L/SKY_L)+ 缝色 OUT，左右/上下边缘像素完全一致。
  ⑤ .tres：两份 SpriteFrames 每个动画 3 帧，region.x = action*3*128 + sub*128，
     ext_resource 的 path/id 与动画名逐字不变（本轮 Rank-4 独占授权）。

锚点 v1（teamwork/艾尔登法环HD2D-美术风格提案.md）：
  单帧非透明唯一 RGB <= 16、64x64 逻辑像素 x2 NEAREST -> 128x128、外描边 #0A1020、
  硬边无渐变/无 dithering/无噪点、RGBA 保 alpha(0/255)、左上暖金主光+右下冷夜蓝补光。

用法：
  python r26_redraw.py            # 预览：只写 teamwork/Rank-4/r26_preview/ + 联系表（不碰 r23/.tres）
  python r26_redraw.py --commit   # 接入：备份 v030 PNG+两份 .tres 到 v030_pre_v040_backup/，
                                   # 再覆盖 r23 PNG / 重写两份 .tres，跑自检输出 r26_redraw_metrics.json
"""
from PIL import Image
import os, sys, shutil, json, hashlib, warnings
warnings.filterwarnings("ignore")

ROOT    = "F:/Game/aierdengfahuan"
R23     = os.path.join(ROOT, "godot/assets/generated/r23")
R4      = os.path.join(ROOT, "teamwork/Rank-4")
PREVIEW = os.path.join(R4, "r26_preview")
BACKUP  = os.path.join(R4, "v030_pre_v040_backup")
TRES_P  = os.path.join(ROOT, "godot/assets/generated/chars/player_spriteframes.tres")
TRES_B  = os.path.join(ROOT, "godot/assets/generated/boss/boss_spriteframes.tres")

# ---- 16 色受控板（逐字对齐提案 §2 / r23_baseline/player_idle_v1.png / R25） ----
OUT      = (0x0A, 0x10, 0x20)  # 描边 / 砖缝 / 接触阴影   L~8
DARK     = (0x1B, 0x2A, 0x4A)  # 深蓝夜 / 暗部           L~22
GOLD     = (0xC9, 0x9A, 0x3A)  # 暖金（主光 / 肩甲）     L~65
COBALT   = (0x2C, 0x4C, 0x8C)  # 主色钴蓝（盔甲 / 砖面） L~45
STEEL    = (0xC9, 0xD2, 0xE0)  # 亮钢                    L~82
GRAY     = (0x8A, 0x93, 0xA8)  # 中灰蓝                  L~58
RED      = (0xB3, 0x3A, 0x3A)  # 暗红（披风 / 红缨）     L~40
LEATHER  = (0x6B, 0x42, 0x26)  # 棕（皮革 / 杖 / 柄）    L~30
INK      = (0x06, 0x0A, 0x14)  # 深接触阴影              L~6
RED_DK   = (0x6E, 0x20, 0x20)  # 深红                    L~22
COBALT_L = (0x3F, 0x6F, 0xC4)  # 亮钴蓝                  L~55
GOLD_HI  = (0xF2, 0xD0, 0x7A)  # 亮金高光                L~82
TEAL     = (0x35, 0xD0, 0xC0)  # 青（宝石 / 招式）       L~70
WHITE    = (0xF2, 0xF4, 0xF8)  # 最高亮                  L~95
SKIN     = (0xE8, 0xB9, 0x8C)  # 肤色                    L~75
SKY_L    = (0x79, 0xB4, 0xE8)  # 亮蓝（地面高光阶）      L~72
PALETTE  = [OUT, DARK, GOLD, COBALT, STEEL, GRAY, RED, LEATHER,
            INK, RED_DK, COBALT_L, GOLD_HI, TEAL, WHITE, SKIN, SKY_L]

N = 64  # 逻辑网格边长（64x64 逻辑像素 x2 NEAREST -> 128x128）

# 3 子帧参数表：每子帧在呼吸 / 武器 / 披风 / 腿 / 倾斜 / 红缨上取不同值 -> 可见差异
SUB = [
    {"dy": 0,  "weapon": 0, "cape": 0, "leg": 0, "lean": 0,  "plume": 0},
    {"dy": -1, "weapon": 1, "cape": 1, "leg": 1, "lean": 1,  "plume": 1},
    {"dy": 0,  "weapon": 2, "cape": 2, "leg": 2, "lean": -1, "plume": 2},
]


class Grid:
    __slots__ = ("g",)

    def __init__(self):
        self.g = [[None] * N for _ in range(N)]

    def rect(self, x0, y0, x1, y1, c):
        x0 = max(0, x0); y0 = max(0, y0); x1 = min(N, x1); y1 = min(N, y1)
        for y in range(y0, y1):
            row = self.g[y]
            for x in range(x0, x1):
                row[x] = c

    def px(self, x, y, c):
        if 0 <= x < N and 0 <= y < N:
            self.g[y][x] = c

    def row(self, y, x0, x1, c):
        """逐行指定左右边界 —— 轮廓化造型的核心（替代整块大矩形）。"""
        if not (0 <= y < N):
            return
        r = self.g[y]
        for x in range(max(0, x0), min(N, x1)):
            r[x] = c

    def band(self, y0, rows, c):
        """rows = [(x0,x1), ...] 从 y0 起逐行绘制。"""
        for i, (a, b) in enumerate(rows):
            self.row(y0 + i, a, b, c)

    def line(self, x0, y0, x1, y1, c, w=1):
        dx = abs(x1 - x0); dy = -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1; sy = 1 if y0 < y1 else -1
        err = dx + dy; h = w // 2
        while True:
            self.rect(x0 - h, y0 - h, x0 - h + w, y0 - h + w, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy: err += dy; x0 += sx
            if e2 <= dx: err += dx; y0 += sy

    def disc(self, cx, cy, r, c):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.px(x, y, c)

    def outline(self):
        """外轮廓统一 1 逻辑像素深色描边 #0A1020；内部靠色块分界，不重复描边。"""
        src = [row[:] for row in self.g]
        for y in range(N):
            for x in range(N):
                if src[y][x] is not None:
                    continue
                near = ((x > 0     and src[y][x - 1] is not None) or
                        (x < N - 1 and src[y][x + 1] is not None) or
                        (y > 0     and src[y - 1][x] is not None) or
                        (y < N - 1 and src[y + 1][x] is not None))
                if near:
                    self.g[y][x] = OUT

    def image(self):
        """64x64 逻辑像素 -> 128x128（x2 NEAREST），RGBA，alpha 硬边 0/255。"""
        im = Image.new("RGBA", (N, N), (0, 0, 0, 0))
        p = im.load()
        for y in range(N):
            for x in range(N):
                c = self.g[y][x]
                p[x, y] = (0, 0, 0, 0) if c is None else (c[0], c[1], c[2], 255)
        return im.resize((128, 128), Image.NEAREST)


# ============================ 骑士逐像素精修部件 ============================
def k_cape(g, mode, sub):
    """披风：逐行飘动轮廓 + 明暗褶皱竖条（相位随 sub），下摆锯齿，非纯矩形。"""
    s = SUB[sub]; ph = s["cape"]
    if mode == "hang":
        rows = [(14, 50)] * 20 + [(15, 49), (14, 48), (16, 47), (15, 46),
                                  (17, 45), (16, 44), (18, 43), (17, 42)]
    elif mode == "trail":
        rows = []
        for i in range(30):
            rows.append((14 - i // 2 - ph, 48 - i // 4))
    else:  # billow
        rows = []
        for i in range(28):
            rows.append((14 - i // 3 - ph, 50 + i // 4 + ph))
    for i, (a, b) in enumerate(rows):
        g.row(24 + i, a, b, RED_DK)
    # 褶皱：每 4px 一条明暗竖条，相位 ph 让子帧错位
    for k in range(8):
        cx = 17 + k * 4 + ph
        col = RED if (k + ph) % 2 == 0 else DARK
        for i, (a, b) in enumerate(rows):
            if a + 1 <= cx < b - 1:
                g.px(cx, 24 + i, col)
    # 左上受光边 + 右下暗边
    for i, (a, b) in enumerate(rows[:10]):
        g.px(a, 24 + i, RED)
        g.px(b - 1, 24 + i, DARK)


def k_legs(g, mode, sub):
    """腿：斜线/阶梯 + 膝甲 + 靴翘头 + 接触阴影；leg 相位让子帧步态不同。"""
    s = SUB[sub]; lp = s["leg"]; dy = s["dy"]
    if mode == "stand":
        g.rect(26 + lp, 44 + dy, 31 + lp, 56 + dy, COBALT)
        g.rect(26 + lp, 44 + dy, 28 + lp, 56 + dy, COBALT_L)
        g.rect(33, 44 + dy, 38, 56 + dy, DARK)
        g.rect(37, 44 + dy, 38, 56 + dy, INK)
    elif mode == "walk":
        g.rect(22 + lp, 44 + dy, 28 + lp, 56 + dy, COBALT)
        g.rect(22 + lp, 44 + dy, 24 + lp, 56 + dy, COBALT_L)
        g.rect(34 - lp // 2, 46 + dy, 40 - lp // 2, 57 + dy, DARK)
    elif mode == "run":
        g.rect(20 + lp, 42 + dy, 27 + lp, 52 + dy, COBALT)
        g.line(20 + lp, 50 + dy, 12 + lp, 58 + dy, COBALT_L, 4)
        g.rect(36, 48 + dy, 42, 57 + dy, DARK)
        g.line(40, 52 + dy, 50, 58 + dy, INK, 3)
    elif mode == "lunge":
        g.rect(18 + lp // 2, 44 + dy, 27 + lp // 2, 58 + dy, COBALT)
        g.line(18 + lp // 2, 52 + dy, 10 + lp // 2, 60 + dy, COBALT_L, 4)
        g.rect(36, 44 + dy, 44, 58 + dy, DARK)
    elif mode == "wide":
        g.rect(18, 44 + dy, 27, 58 + dy, COBALT)
        g.rect(18, 44 + dy, 20, 58 + dy, COBALT_L)
        g.rect(37, 44 + dy, 46, 58 + dy, DARK)
        g.rect(45, 44 + dy, 46, 58 + dy, INK)
    elif mode == "stagger":
        g.rect(24 - lp, 46 + dy, 30 - lp, 58 + dy, COBALT)
        g.rect(36 + lp, 42 + dy, 42 + lp, 56 + dy, DARK)
    # 膝甲（金 + 高光）
    g.rect(25 + lp // 2, 47 + dy, 29 + lp // 2, 49 + dy, GOLD)
    g.px(26 + lp // 2, 47 + dy, GOLD_HI)
    # 靴 + 翘头 + 接触阴影
    g.rect(22 + lp // 2, 57 + dy, 31 + lp // 2, 61 + dy, LEATHER)
    g.rect(33, 57 + dy, 42, 61 + dy, LEATHER)
    g.rect(20 + lp // 2, 60 + dy, 22 + lp // 2, 61 + dy, LEATHER)  # 翘头
    g.rect(42, 60 + dy, 44, 61 + dy, LEATHER)
    g.rect(20 + lp // 2, 61 + dy, 44, 62 + dy, INK)


def k_torso(g, lean, dy, sub):
    """胸甲：逐行收腰 + 左上亮面斜带 + 右下暗面 + 板甲分层线 + 菱形金饰 + 宝石 + 腰带扣。"""
    x = lean; y = dy
    body = [(26, 38), (25, 39), (25, 39), (26, 38), (26, 38), (27, 37),
            (27, 37), (28, 36), (28, 36), (28, 36), (27, 37), (27, 37),
            (26, 38), (26, 38)]
    for i, (a, b) in enumerate(body):
        g.row(24 + i + y, a + x, b + x, COBALT)
    # 左上亮面（斜带，逐行右移）
    for i in range(14):
        a = 26 + i // 5
        g.row(24 + i + y, a + x, a + 2 + x, COBALT_L)
    # 右下暗面（逐行左移）
    for i in range(14):
        b = 38 - i // 6
        g.row(24 + i + y, b - 2 + x, b + x, DARK)
    # 板甲分层线（1px 硬边，非渐变）
    for yy in (30, 35, 40):
        g.row(yy + y, 26 + x, 38 + x, OUT)
    # 菱形金饰 + 青宝石 + 高光
    g.band(27 + y, [(31 + x, 33 + x), (30 + x, 34 + x), (29 + x, 35 + x),
                    (30 + x, 34 + x), (31 + x, 33 + x)], GOLD)
    g.row(28 + y, 31 + x, 33 + x, GOLD_HI)
    g.rect(31 + x, 29 + y, 33 + x, 30 + y, TEAL)
    g.px(32 + x, 28 + y, WHITE)
    # 腰带 + 金扣 + 扣高光
    g.rect(26 + x, 42 + y, 38 + x, 45 + y, LEATHER)
    g.rect(30 + x, 42 + y, 34 + x, 45 + y, GOLD)
    g.rect(31 + x, 42 + y, 33 + x, 44 + y, GOLD_HI)
    g.px(32 + x, 43 + y, WHITE)


def k_head(g, lean, dy, sub):
    """头盔：逐行圆顶 + 金盔脊 + 面甲(眼缝 T 字/鼻梁/呼吸孔/高光) + 护颊 + 红缨斜飘。"""
    s = SUB[sub]; x = lean; y = dy
    dome = [(30, 34), (28, 36), (27, 37), (26, 38), (26, 38), (26, 38),
            (26, 38), (27, 37), (28, 36)]
    for i, (a, b) in enumerate(dome):
        g.row(10 + i + y, a + x, b + x, COBALT)
    for i, (a, b) in enumerate([(30, 32), (28, 30), (27, 29), (26, 28),
                                (26, 28), (26, 28)]):
        g.row(10 + i + y, a + x, b + x, COBALT_L)
    # 金盔脊
    g.rect(31 + x, 9 + y, 33 + x, 14 + y, GOLD)
    g.rect(31 + x, 9 + y, 32 + x, 14 + y, GOLD_HI)
    # 面甲（钢）+ 左暗边 + 高光
    g.rect(27 + x, 15 + y, 37 + x, 21 + y, STEEL)
    g.rect(27 + x, 15 + y, 28 + x, 21 + y, GRAY)
    g.rect(28 + x, 15 + y, 31 + x, 16 + y, WHITE)
    # 眼缝（T 字深色）+ 鼻梁 + 呼吸孔
    g.rect(28 + x, 17 + y, 31 + x, 18 + y, OUT)
    g.rect(33 + x, 17 + y, 36 + x, 18 + y, OUT)
    g.rect(32 + x, 15 + y, 33 + x, 20 + y, DARK)
    g.px(29 + x, 19 + y, DARK); g.px(34 + x, 19 + y, DARK)
    g.px(30 + x, 20 + y, DARK); g.px(35 + x, 20 + y, DARK)
    # 护颊
    g.rect(26 + x, 18 + y, 28 + x, 23 + y, STEEL)
    g.rect(27 + x, 18 + y, 28 + x, 22 + y, GRAY)
    g.rect(36 + x, 18 + y, 38 + x, 23 + y, GRAY)
    g.rect(36 + x, 18 + y, 37 + x, 23 + y, DARK)
    # 颈 / 下巴
    g.rect(29 + x, 21 + y, 35 + x, 23 + y, DARK)
    g.rect(30 + x, 21 + y, 34 + x, 22 + y, SKIN)
    # 红缨（斜后飘，plume 让子帧飘幅不同）
    tip = 4 - s["plume"]
    g.line(31 + x, 9 + y, 23 + x, max(2, tip) + y, RED, 2)
    g.line(31 + x, 9 + y, 25 + x, max(3, tip + 1) + y, RED_DK, 1)
    g.rect(30 + x, 8 + y, 33 + x, 10 + y, RED)


def k_shoulders(g, lean, dy, sub):
    """肩甲：逐行斜边梯形（非纯矩形）+ 左上高光边 + 下缘阴影 + 铆钉。"""
    x = lean; y = dy
    L = [(17, 27), (15, 27), (15, 27), (16, 27), (18, 27), (20, 27), (22, 27)]
    for i, (a, b) in enumerate(L):
        g.row(23 + i + y, a + x, b + x, GOLD)
    for i, (a, b) in enumerate([(17, 19), (15, 17), (15, 17), (16, 18), (18, 20)]):
        g.row(23 + i + y, a + x, b + x, GOLD_HI)
    g.row(28 + y, 17 + x, 27 + x, DARK)
    g.rect(18 + x, 24 + y, 19 + x, 25 + y, WHITE)
    g.rect(23 + x, 25 + y, 24 + x, 26 + y, WHITE)
    R = [(37, 47), (37, 49), (37, 49), (37, 48), (37, 46), (37, 44), (37, 42)]
    for i, (a, b) in enumerate(R):
        g.row(23 + i + y, a + x, b + x, GOLD)
    for i, (a, b) in enumerate([(45, 47), (47, 49), (47, 49), (46, 48), (44, 46)]):
        g.row(23 + i + y, a + x, b + x, GOLD_HI)
    g.row(28 + y, 37 + x, 47 + x, DARK)
    g.rect(45 + x, 24 + y, 46 + x, 25 + y, WHITE)
    g.rect(40 + x, 25 + y, 41 + x, 26 + y, WHITE)


def k_shield(g, x0, y0, sub):
    """鸢盾：逐行弧边（上宽下收尖）+ 金框 + 蓝面 + 左上亮面 + 青宝石 + 高光。"""
    s = SUB[sub]; off = s["weapon"] // 2
    x = x0; y = y0 + off
    rows = [(0, 12), (-1, 13), (-1, 13), (0, 12), (0, 12), (1, 11),
            (1, 11), (2, 10), (2, 10), (3, 9), (4, 8), (5, 7)]
    for i, (a, b) in enumerate(rows):
        g.row(y + i, x + a, x + b, GOLD)
    # 内面（略收）
    inner = [(1, 11), (1, 11), (1, 11), (2, 10), (2, 10), (2, 10),
             (3, 9), (3, 9), (4, 8), (5, 7)]
    for i, (a, b) in enumerate(inner):
        g.row(y + 1 + i, x + a, x + b, COBALT)
    for i, (a, b) in enumerate(inner[:6]):
        g.row(y + 1 + i, x + a, x + a + 2, COBALT_L)
    # 上缘高光 + 青宝石 + 白高光
    g.row(y + 1, x + 1, x + 11, GOLD_HI)
    g.rect(x + 4, y + 5, x + 8, y + 9, TEAL)
    g.rect(x + 5, y + 6, x + 7, y + 8, WHITE)
    g.px(x + 6, y + 5, GOLD_HI)


def k_sword(g, mode, sub):
    """剑：剑身中脊/刃高光/收尖 + 金剑格 + 缠柄(LEATHER/GOLD 交替) + 剑首；weapon 让子帧变角度。"""
    s = SUB[sub]; w = s["weapon"]; dy = s["dy"]
    if mode == "vert":                                     # 竖直持剑
        by = 10 + dy - w
        g.band(by, [(43, 47), (43, 47), (43, 47), (43, 47)], GRAY)  # 剑根
        g.rect(43, by, 47, 38 + dy, GRAY)
        g.rect(44, by, 46, 38 + dy, STEEL)                # 中脊
        g.row(by, 44, 45, WHITE)                           # 刃尖高光
        g.rect(44, by + 1, 45, 36 + dy, WHITE)             # 刃高光 1px
        g.rect(43, by, 44, by + 2, SKY_L)                  # 剑尖亮
        g.rect(42, 38 + dy, 48, 40 + dy, GOLD)             # 剑格
        g.rect(42, 38 + dy, 48, 39 + dy, GOLD_HI)
        for yy in range(40 + dy, 45 + dy, 2):              # 缠柄
            g.rect(44, yy, 46, yy + 1, LEATHER)
            g.rect(44, yy + 1, 46, yy + 2, GOLD)
        g.rect(43, 45 + dy, 47, 47 + dy, GOLD)             # 剑首
        g.px(45, 45 + dy, WHITE)
    elif mode == "slash":                                  # 轻攻击水平横斩
        yy = 29 + dy - w // 2
        g.rect(18, yy + 1, 50, yy + 3, GRAY)
        g.row(yy + 1, 20, 48, STEEL)
        g.row(yy + 1, 22, 44, WHITE)                       # 刃高光
        g.rect(48, yy, 50, yy + 4, SKY_L)                  # 剑尖
        g.rect(38, yy - 2, 42, yy + 6, GOLD)               # 剑格
        g.rect(38, yy - 2, 42, yy - 1, GOLD_HI)
        g.rect(40, yy + 4, 44, yy + 9, LEATHER)            # 柄
        g.rect(40, yy + 9, 44, yy + 11, GOLD)
        # 挥砍弧（硬边 TEAL 阶梯）
        g.row(yy - 4, 14, 26, TEAL); g.row(yy - 3, 10, 20, TEAL)
        g.row(yy + 5, 8, 16, STEEL); g.row(yy - 6, 50, 60, TEAL)
    elif mode == "overhead":                               # 重攻击高举过头
        ty = 2 + dy - w
        g.rect(38, ty, 44, 26 + dy, GRAY)
        g.rect(39, ty, 43, 26 + dy, STEEL)
        g.rect(40, ty + 1, 41, 24 + dy, WHITE)
        g.rect(39, ty, 42, ty + 2, SKY_L)
        g.rect(36, 24 + dy, 46, 27 + dy, GOLD)
        g.rect(36, 24 + dy, 46, 25 + dy, GOLD_HI)
        for yy in range(27 + dy, 32 + dy, 2):
            g.rect(39, yy, 43, yy + 1, LEATHER)
            g.rect(39, yy + 1, 43, yy + 2, GOLD)
        g.rect(38, 32 + dy, 44, 34 + dy, GOLD)
    elif mode == "lowered":                                # 受击脱手下垂
        g.line(46, 34 + dy, 50 + w, 54 + dy, GRAY, 2)
        g.rect(44, 32 + dy, 48, 35 + dy, GOLD)
        g.rect(44, 32 + dy, 48, 33 + dy, GOLD_HI)
        g.rect(46, 35 + dy, 48, 40 + dy, LEATHER)
    elif mode == "back":                                   # 奔跑后摆
        g.line(44, 30 + dy, 56 + w, 44 + dy, GRAY, 2)
        g.rect(42, 28 + dy, 46, 32 + dy, GOLD)
        g.rect(42, 28 + dy, 46, 29 + dy, GOLD_HI)
        g.rect(44, 32 + dy, 47, 37 + dy, LEATHER)
    elif mode == "stowed":                                 # 翻滚贴地收起
        g.rect(14, 50 + dy, 30, 53 + dy, GRAY)
        g.rect(16, 50 + dy, 28, 52 + dy, STEEL)
        g.row(51 + dy, 18, 26, WHITE)
        g.rect(28, 49 + dy, 31, 54 + dy, GOLD)


def player_death(g, sub):
    """★ 本轮重点：横躺可辨剪影。头/躯干/武器分色，主体亮面抬到画面中部，
    与地面明度差 >=2 档，下方留透明，不得贴地隐形。"""
    s = SUB[sub]; dy = s["dy"]
    # 接触阴影（薄，深色，不盖身体）
    g.rect(6, 48 + dy, 60, 49 + dy, INK)
    # 披风（横铺在最下，红/深红 + 褶皱）
    for i, (a, b) in enumerate([(20, 54), (18, 55), (16, 54), (15, 52),
                                (16, 50), (18, 48), (20, 46)]):
        g.row(40 + i + dy, a, b, RED_DK)
    for cx in range(22, 50, 4):
        g.rect(cx, 40 + dy, cx + 1, 46 + dy, RED)
    # 腿（右，COBALT_L 亮 + DARK 暗 + 靴，微屈斜线）
    g.rect(42, 34 + dy, 56, 40 + dy, COBALT_L)
    g.rect(42, 39 + dy, 56, 42 + dy, DARK)
    g.line(54, 36 + dy, 60, 33 + dy, COBALT_L, 3)
    g.rect(56, 32 + dy, 62, 36 + dy, LEATHER)
    g.px(60, 33 + dy, GOLD_HI)
    g.rect(44, 34 + dy, 46, 40 + dy, GOLD)                # 膝甲
    g.rect(44, 34 + dy, 46, 35 + dy, GOLD_HI)
    # 躯干（中，COBALT 主 + COBALT_L 亮面 + GOLD 胸饰 + 分层线 + TEAL/WHITE 宝石）
    g.rect(22, 32 + dy, 42, 44 + dy, COBALT)
    g.rect(22, 32 + dy, 42, 34 + dy, COBALT_L)             # 上缘亮（受光）
    g.rect(22, 42 + dy, 42, 44 + dy, DARK)                  # 下缘暗
    g.rect(26, 34 + dy, 38, 41 + dy, COBALT_L)             # 胸甲亮面
    g.band(35 + dy, [(30, 36), (29, 37), (29, 37), (30, 36)], GOLD)
    g.row(35 + dy, 30, 36, GOLD_HI)
    g.rect(31, 36 + dy, 35, 38 + dy, TEAL)
    g.px(33, 36 + dy, WHITE); g.px(32, 37 + dy, WHITE)
    g.row(38 + dy, 26, 38, OUT)                            # 板甲分层线
    g.rect(22, 32 + dy, 24, 44 + dy, GOLD)                 # 肩/腰金边
    g.rect(22, 32 + dy, 24, 33 + dy, GOLD_HI)
    # 手臂（伸出，钢甲 + 手）
    g.rect(24, 44 + dy, 36, 47 + dy, STEEL)
    g.rect(24, 44 + dy, 26, 47 + dy, GRAY)
    g.rect(34, 45 + dy, 38, 48 + dy, SKIN)
    g.px(36, 46 + dy, WHITE)
    # 头（左，圆盘头盔 + 亮钢面甲 + 金边 + 红缨朝左）
    g.disc(15, 38 + dy, 7, COBALT)
    g.disc(15, 37 + dy, 6, COBALT_L)                       # 亮面
    g.rect(9, 36 + dy, 19, 41 + dy, STEEL)                 # 面甲
    g.rect(10, 36 + dy, 17, 37 + dy, WHITE)                # 面甲高光
    g.rect(10, 38 + dy, 13, 39 + dy, OUT)                  # 眼缝
    g.rect(15, 38 + dy, 18, 39 + dy, OUT)
    g.rect(14, 36 + dy, 15, 41 + dy, DARK)                 # 鼻梁
    g.rect(8, 34 + dy, 10, 43 + dy, GOLD)                  # 盔金边
    g.rect(8, 34 + dy, 9, 43 + dy, GOLD_HI)
    tip = 30 + dy - s["plume"]
    g.line(9, 34 + dy, 3, tip, RED, 2)
    g.line(9, 36 + dy, 4, tip + 2, RED_DK, 1)
    # 散落剑（身体上方，亮钢横放，明显亮于地面）
    sy = 26 + dy
    g.rect(38, sy, 58, sy + 3, GRAY)
    g.row(sy, 40, 58, WHITE)                               # 刃高光 1px
    g.rect(38, sy, 58, sy + 1, STEEL)
    g.rect(56, sy - 1, 59, sy + 4, GOLD)                   # 剑格
    g.rect(56, sy - 1, 59, sy, GOLD_HI)
    g.rect(34, sy, 38, sy + 3, LEATHER)                    # 柄
    g.rect(32, sy - 1, 34, sy + 4, GOLD)                   # 剑首
    g.px(33, sy, WHITE)
    # 散落盾（头上方，鸢盾金框 + 蓝面 + 青宝石）
    sb = [(8, 20), (7, 21), (7, 21), (8, 20), (9, 19), (11, 17), (13, 15)]
    for i, (a, b) in enumerate(sb):
        g.row(20 + i + dy, a, b, GOLD)
    g.rect(10, 22 + dy, 18, 26 + dy, COBALT)
    g.rect(11, 22 + dy, 14, 26 + dy, COBALT_L)
    g.px(14, 24 + dy, TEAL); g.px(15, 24 + dy, WHITE)
    g.row(21 + dy, 9, 19, GOLD_HI)


def player(pose, sub=0):
    g = Grid()
    s = SUB[sub]; dy = s["dy"]; ln = s["lean"]
    if pose == "idle":
        k_cape(g, "hang", sub); k_legs(g, "stand", sub)
        k_torso(g, 0, dy, sub); k_head(g, 0, dy, sub); k_shoulders(g, 0, dy, sub)
        k_shield(g, 9, 27, sub); k_sword(g, "vert", sub)
    elif pose == "walk":
        k_cape(g, "hang", sub); k_legs(g, "walk", sub)
        k_torso(g, 1, dy, sub); k_head(g, 1, dy - 1, sub); k_shoulders(g, 1, dy, sub)
        k_shield(g, 8, 26, sub); k_sword(g, "vert", sub)
        g.rect(28, 4 + dy, 32, 5 + dy, RED_DK)
    elif pose == "run":
        k_cape(g, "trail", sub); k_legs(g, "run", sub)
        k_torso(g, 3, dy + 1, sub); k_head(g, 4, dy, sub); k_shoulders(g, 3, dy + 1, sub)
        k_shield(g, 20, 24, sub); k_sword(g, "back", sub)
        g.row(30 + dy, 4, 12, TEAL); g.row(36 + dy, 2, 10, GRAY)
    elif pose == "roll":
        g.disc(32, 44 + dy, 15, RED_DK); g.disc(32, 44 + dy, 13, COBALT)
        g.rect(24, 36 + dy, 40, 44 + dy, COBALT_L)
        g.rect(24, 50 + dy, 40, 54 + dy, DARK)
        g.rect(28, 40 + dy, 36, 48 + dy, STEEL)
        g.rect(30, 42 + dy, 34, 46 + dy, WHITE)
        g.rect(22, 38 + dy, 26, 44 + dy, GOLD)
        g.px(23, 39 + dy, GOLD_HI)
        k_shield(g, 18, 42, sub); k_sword(g, "stowed", sub)
        g.row(40 + dy, 6, 16, TEAL); g.row(46 + dy, 4, 12, STEEL)
        g.row(52 + dy, 8, 16, GRAY)
    elif pose == "attack_light":
        k_cape(g, "billow", sub); k_legs(g, "lunge", sub)
        k_torso(g, 2, dy, sub); k_head(g, 2, dy, sub); k_shoulders(g, 2, dy, sub)
        k_shield(g, 7, 25, sub); k_sword(g, "slash", sub)
    elif pose == "attack_heavy":
        k_cape(g, "hang", sub); k_legs(g, "wide", sub)
        k_torso(g, -1, dy + 2, sub); k_head(g, -2, dy + 2, sub)
        k_shoulders(g, -2, dy + 2, sub)
        k_shield(g, 11, 34, sub); k_sword(g, "overhead", sub)
        g.rect(38, 0 + dy, 42, 4 + dy, GOLD_HI); g.row(4 + dy, 34, 46, GOLD_HI)
        g.row(8 + dy, 30, 34, GOLD); g.row(8 + dy, 48, 52, GOLD)
    elif pose == "hitstun":
        k_cape(g, "billow", sub); k_legs(g, "stagger", sub)
        k_torso(g, -3, dy, sub); k_head(g, -4, dy + 1, sub)
        k_shoulders(g, -3, dy, sub)
        k_shield(g, 7, 38, sub); k_sword(g, "lowered", sub)
        g.row(10 + dy, 40, 44, WHITE); g.row(8 + dy, 42, 46, RED)
        g.row(14 + dy, 44, 48, WHITE); g.row(16 + dy, 38, 40, RED)
    elif pose == "death":
        player_death(g, sub)
    g.outline()
    return g


# ============================ Boss（3 招 × 3 子帧） ============================
def boss(move, sub=0):
    g = Grid()
    s = SUB[sub]; w = s["weapon"]; dy = s["dy"]
    phase2 = (move == "p2_holy_hammer")
    # 披风（逐行外张 + 竖褶）
    cape_rows = [(6, 18), (5, 19), (5, 20), (6, 21), (7, 22), (8, 23)] + [(6, 20)] * 16
    for i, (a, b) in enumerate(cape_rows):
        g.row(22 + i + dy, a, b, RED_DK)
        g.row(22 + i + dy, 64 - b, 64 - a, RED_DK)
    for cx in range(8, 20, 4):
        g.rect(cx, 24 + dy, cx + 1, 44 + dy, RED)
        g.rect(64 - cx - 1, 24 + dy, 64 - cx, 44 + dy, RED)
    # 粗腿
    g.rect(20, 46 + dy, 28, 58 + dy, RED_DK); g.rect(36, 46 + dy, 44, 58 + dy, RED_DK)
    g.rect(18, 56 + dy, 30, 60 + dy, INK);    g.rect(34, 56 + dy, 46, 60 + dy, INK)
    g.rect(22, 48 + dy, 26, 50 + dy, GOLD)     # 膝甲
    g.rect(38, 48 + dy, 42, 50 + dy, GOLD)
    # 宽躯干（暗红主色，逐行收放）+ 板甲分层线
    body = [(16, 48), (15, 49), (15, 49), (16, 48), (16, 48), (17, 47), (17, 47)]
    for i, (a, b) in enumerate(body):
        g.row(20 + i + dy, a, b, RED)
    g.rect(16, 26 + dy, 48, 46 + dy, RED)
    g.rect(16, 26 + dy, 22, 46 + dy, RED_DK)
    g.rect(42, 26 + dy, 48, 46 + dy, DARK)
    for yy in (32 + dy, 38 + dy, 43 + dy):
        g.row(yy, 18, 46, OUT)
    g.rect(24, 27 + dy, 40, 34 + dy, GOLD)
    g.rect(26, 27 + dy, 38, 29 + dy, GOLD_HI)
    g.rect(30, 29 + dy, 34, 32 + dy, TEAL)
    g.px(32, 28 + dy, WHITE)
    # 肩甲（斜边梯形 + 高光 + 铆钉）
    for i, (a, b) in enumerate([(8, 18), (7, 18), (7, 18), (8, 18), (10, 18), (12, 18)]):
        g.row(20 + i + dy, a, b, GOLD)
        g.row(20 + i + dy, 64 - b, 64 - a, GOLD)
    g.row(21 + dy, 8, 10, GOLD_HI); g.row(21 + dy, 54, 56, GOLD_HI)
    g.rect(10, 22 + dy, 11, 23 + dy, WHITE); g.rect(53, 22 + dy, 54, 23 + dy, WHITE)
    # 头 + 牛角（轮廓优先，line 斜角）
    g.disc(32, 14 + dy, 8, DARK)
    g.rect(24, 10 + dy, 40, 20 + dy, DARK)
    g.rect(24, 10 + dy, 40, 12 + dy, RED_DK)
    g.rect(27, 12 + dy, 37, 18 + dy, STEEL)
    g.rect(29, 13 + dy, 35, 16 + dy, WHITE)
    g.rect(28, 17 + dy, 36, 19 + dy, RED)
    g.line(24, 10 + dy, 10, 2 + dy - w // 2, GOLD, 3)
    g.line(24, 13 + dy, 12, 8 + dy - w // 3, GOLD, 2)
    g.line(40, 10 + dy, 54, 2 + dy - w // 2, GOLD, 3)
    g.line(40, 13 + dy, 52, 8 + dy - w // 3, GOLD, 2)
    if phase2:
        g.row(20 + dy, 24, 40, WHITE)
        g.rect(16, 34 + dy, 20, 44 + dy, GOLD_HI)
        g.rect(44, 34 + dy, 48, 44 + dy, GOLD_HI)

    if move == "p1_dagger_slash":                          # 匕首横斩（挥砍弧随 sub）
        yy = 30 + dy - w // 2
        g.line(46, yy, 60, yy - 4, STEEL, 2)
        g.rect(44, yy - 2, 48, yy + 2, LEATHER)
        g.rect(47, yy - 3, 51, yy - 1, GOLD)
        g.row(yy - 6, 6, 20, TEAL); g.row(yy - 5, 4, 14, TEAL)
        g.row(yy + 2, 8, 18, STEEL); g.row(yy - 8, 50, 60, TEAL)
    elif move == "p1_staff_slam":                          # 法杖下砸（冲击块随 sub 扩张）
        g.rect(48, 4 + dy, 52, 54 + dy, LEATHER)
        g.rect(46, 2 + dy, 54, 9 + dy, GOLD)
        g.rect(47, 3 + dy, 53, 6 + dy, GOLD_HI)
        g.rect(49, 5 + dy, 51, 8 + dy, TEAL)
        g.rect(42, 26 + dy, 48, 30 + dy, RED_DK)
        g.rect(24 + w, 52 + dy, 58 + w, 56 + dy, STEEL)
        g.rect(30, 50 + dy, 52, 52 + dy, GOLD)
        g.rect(36, 48 + dy, 44, 50 + dy, WHITE)
        g.rect(20, 54 + dy, 26, 58 + dy, GOLD_HI)
    elif move == "p2_holy_hammer":                          # 圣锤高举（锤位随 sub）
        hy = 2 + dy - w // 2
        g.rect(44, 14 + dy, 48, 32 + dy, LEATHER)
        g.rect(38, hy, 54, hy + 14, GOLD)
        g.rect(40, hy + 2, 52, hy + 10, GOLD_HI)
        g.rect(44, hy + 4, 48, hy + 8, WHITE)
        g.rect(41, hy + 12, 51, hy + 14, RED_DK)
        g.row(hy - 2, 26, 30, GOLD_HI); g.row(hy + 4, 58, 62, GOLD_HI)
        g.row(hy + 8, 6, 10, GOLD); g.row(hy + 28, 56, 60, GOLD)
    g.outline()
    return g


# ============================ 地面 tile（4x4 大砖 · 收敛版） ============================
def ground():
    """v0.4.0 收敛：去绿(TEAL)/黄(GOLD)杂色点；4x4 大砖保持；明度 4 阶
    (DARK/COBALT/COBALT_L/SKY_L 全蓝系) + 缝色 OUT；左右/上下边缘像素完全一致。"""
    g = Grid()
    g.rect(0, 0, 64, 64, COBALT)
    for by in range(4):
        for bx in range(4):
            x0 = bx * 16; y0 = by * 16
            g.rect(x0, y0, x0 + 16, y0 + 1, OUT)           # 上砖缝 1px
            g.rect(x0, y0, x0 + 1, y0 + 16, OUT)           # 左砖缝 1px
            g.rect(x0 + 1, y0 + 1, x0 + 16, y0 + 16, COBALT)   # 中阶
            g.rect(x0 + 2, y0 + 2, x0 + 10, y0 + 4, COBALT_L)   # 亮阶（上缘受光）
            g.rect(x0 + 2, y0 + 2, x0 + 4, y0 + 10, COBALT_L)   # 亮阶（左缘）
            g.rect(x0 + 3, y0 + 3, x0 + 7, y0 + 5, SKY_L)       # 最高亮阶（蓝系）
            g.rect(x0 + 11, y0 + 11, x0 + 16, y0 + 16, DARK)     # 暗阶（右下）
            g.rect(x0 + 13, y0 + 13, x0 + 15, y0 + 15, INK)      # 角部更深（第 5 阶过渡）
    # 严格无缝：最后一逻辑列/行 = 第一逻辑列/行（均为缝色 OUT），四角全等
    for y in range(N):
        g.g[y][N - 1] = g.g[y][0]
    for x in range(N):
        g.g[N - 1][x] = g.g[0][x]
    return g


# ============================ 装饰层（沿用 R25，16 色规则几何，透明底） ============================
def decor():
    g = Grid()
    g.rect(2, 2, 62, 3, GOLD); g.rect(2, 61, 62, 62, GOLD)
    g.rect(2, 2, 3, 62, GOLD); g.rect(61, 2, 62, 62, GOLD)
    for cx, cy in [(8, 8), (55, 8), (8, 55), (55, 55)]:
        g.disc(cx, cy, 3, TEAL); g.px(cx, cy, WHITE)
    g.rect(30, 26, 34, 38, GOLD); g.rect(26, 30, 38, 34, GOLD)
    g.rect(30, 30, 34, 34, GOLD_HI)
    g.rect(3, 54, 61, 56, DARK); g.rect(3, 56, 61, 58, COBALT)
    g.rect(3, 58, 61, 60, COBALT_L)
    g.outline()
    return g


PLAYER = ["idle", "walk", "run", "roll", "attack_light", "attack_heavy", "hitstun", "death"]
BOSS = ["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]

# .tres 动画名 -> action 索引（= PLAYER/BOSS 几何顺序），region.x = action*384 + sub*128
PLAYER_ANIM  = ["attack_heavy", "attack_light", "death", "hitstun", "idle", "roll", "run", "walk"]
PLAYER_ACT   = {name: PLAYER.index(name) for name in PLAYER_ANIM}
PLAYER_LOOP  = {"idle": 1, "run": 1, "walk": 1}
BOSS_ANIM    = ["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]
BOSS_ACT     = {name: i for i, name in enumerate(BOSS_ANIM)}
BOSS_LOOP    = {}


def build_all():
    """返回 {文件名: PIL.Image}；帧物理顺序 x = action*3*128 + sub*128。"""
    out = {}
    # 24 帧 player：action = PLAYER 索引，sub = 0/1/2
    ps = Image.new("RGBA", (3072, 128), (0, 0, 0, 0))
    pframes = {}
    for a, pose in enumerate(PLAYER):
        for sub in range(3):
            im = player(pose, sub).image()
            ps.paste(im, ((a * 3 + sub) * 128, 0))
            pframes[(pose, sub)] = im
    out["player_spritesheet.png"] = ps
    # 9 帧 boss
    bs = Image.new("RGBA", (1152, 128), (0, 0, 0, 0))
    bframes = {}
    for a, move in enumerate(BOSS):
        for sub in range(3):
            im = boss(move, sub).image()
            bs.paste(im, ((a * 3 + sub) * 128, 0))
            bframes[(move, sub)] = im
    out["boss_spritesheet.png"] = bs
    # 单帧 PNG：刷新为对应 pose 的第 0 子帧内容（路径不变，与 spritesheet 第 action*3 帧一致）
    for pose in PLAYER:
        out["player_%s.png" % pose] = pframes[(pose, 0)]
    for move in BOSS:
        out["boss_%s.png" % move] = bframes[(move, 0)]
    out["ground_tile.png"] = ground().image()
    out["decor_layer.png"] = decor().image()
    return out, pframes, bframes


def make_contact_sheets(imgs, pframes, bframes):
    """联系表供 ViewImage 目视：先目视检查再接入。"""
    def big(im): return im.resize((256, 256), Image.NEAREST)
    os.makedirs(PREVIEW, exist_ok=True)
    # ① 玩家 8 pose 首子帧 2x4（看整体是否消除积木感）
    cp = Image.new("RGBA", (1024, 512), (26, 32, 48, 255))
    for i, p in enumerate(PLAYER):
        cp.paste(big(pframes[(p, 0)]), ((i % 4) * 256, (i // 4) * 256))
    cp.convert("RGB").save(os.path.join(R4, "r26_contact_player.png"))
    # ② 逐帧动作 + death 特写：4 pose × 3 子帧（idle/run/attack_light/death）4 行 x 3 列
    cs = Image.new("RGBA", (768, 1024), (26, 32, 48, 255))
    for r, p in enumerate(["idle", "run", "attack_light", "death"]):
        for c in range(3):
            cs.paste(big(pframes[(p, c)]), (c * 256, r * 256))
    cs.convert("RGB").save(os.path.join(R4, "r26_contact_subframes.png"))
    # ③ death 单张 4x 放大（重点复核可辨剪影）
    big(pframes[("death", 0)]).resize((512, 512), Image.NEAREST).convert("RGB").save(
        os.path.join(R4, "r26_contact_death.png"))
    # ④ Boss 3 招 × 3 子帧（3 行 x 3 列） + ground 单张 / 2x2 平铺 + decor
    cb = Image.new("RGBA", (768, 1024), (26, 32, 48, 255))
    for r, m in enumerate(BOSS):
        for c in range(3):
            cb.paste(big(bframes[(m, c)]), (c * 256, r * 256))
    tile = imgs["ground_tile.png"]
    t2 = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    for j in range(2):
        for i in range(2):
            t2.paste(tile, (i * 128, j * 128))
    cb.paste(big(tile), (0, 768))
    cb.paste(t2, (256, 768))
    cb.paste(big(imgs["decor_layer.png"]), (512, 768))
    cb.convert("RGB").save(os.path.join(R4, "r26_contact_boss_tile.png"))


def preview():
    os.makedirs(PREVIEW, exist_ok=True)
    imgs, pframes, bframes = build_all()
    for name, im in imgs.items():
        im.save(os.path.join(PREVIEW, name))
    make_contact_sheets(imgs, pframes, bframes)
    print("PREVIEW OK ->", PREVIEW, "| files:", len(imgs))
    print("contact_sheets: r26_contact_player.png / r26_contact_subframes.png / "
          "r26_contact_death.png / r26_contact_boss_tile.png")


# ============================ .tres 生成（路径逐字不变） ============================
def write_tres(path, ext_id, ext_path, anim_names, act, loops):
    """每动画 3 帧，region.x = action*3*128 + sub*128；ext path/id 与动画名不变。"""
    lines = ["[gd_resource type=\"SpriteFrames\" format=3]", "",
             "[ext_resource type=\"Texture2D\" path=\"%s\" id=\"%s\"]" % (ext_path, ext_id), ""]
    # sub_resource：每动画 3 个 AtlasTexture
    ids = {}
    for name in anim_names:
        a = act[name]
        for sub in range(3):
            sid = "AtlasTexture_a%d_s%d" % (a, sub)
            ids[(name, sub)] = sid
            lines += ["[sub_resource type=\"AtlasTexture\" id=\"%s\"]" % sid,
                      "atlas = ExtResource(\"%s\")" % ext_id,
                      "region = Rect2(%d, 0, 128, 128)" % (a * 3 * 128 + sub * 128), ""]
    # animations（保持原有字母序）
    parts = []
    for name in anim_names:
        frames = []
        for sub in range(3):
            frames.append("{\n\"duration\": 1.0,\n\"texture\": SubResource(\"%s\")\n}" % ids[(name, sub)])
        parts.append("{\n\"frames\": [%s],\n\"loop\": %d,\n\"name\": &\"%s\",\n\"speed\": 1.0\n}" % (
            ",\n".join(frames).replace("\n", "\n"), loops.get(name, 0), name))
    lines += ["[resource]", "animations = [%s]" % ",\n".join(parts), ""]
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines))


# ============================ 自检 ============================
def uniq_rgb(im):
    return len(set((r, g, b) for r, g, b, a in im.getdata() if a > 0))


def alpha_set(im):
    return sorted(set(a for r, g, b, a in im.getdata()))


def block2_mismatch(im):
    px = im.load(); w, h = im.size; bad = 0
    for by in range(h // 2):
        for bx in range(w // 2):
            c = px[bx * 2, by * 2]
            for dy in range(2):
                for dx in range(2):
                    if px[bx * 2 + dx, by * 2 + dy] != c:
                        bad += 1
    return bad


def luma(c):
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


def frame_metrics(path):
    im = Image.open(path).convert("RGBA")
    return {"size": list(im.size), "unique_rgb_visible": uniq_rgb(im),
            "alpha_values": alpha_set(im), "block2_mismatch": block2_mismatch(im)}


def avg_luma_visible(path):
    im = Image.open(path).convert("RGBA")
    vals = [luma((r, g, b)) for r, g, b, a in im.getdata() if a > 0]
    return round(sum(vals) / len(vals), 2) if vals else 0.0


def commit():
    imgs, pframes, bframes = build_all()
    # ① 旧版先备份（v0.3.0 PNG + 两份 .tres）
    os.makedirs(BACKUP, exist_ok=True)
    backed = []
    for f in sorted(os.listdir(R23)):
        if f.endswith(".png"):
            dst = os.path.join(BACKUP, f)
            if not os.path.exists(dst):
                shutil.copy2(os.path.join(R23, f), dst)
                backed.append(f)
    for p in (TRES_P, TRES_B):
        dst = os.path.join(BACKUP, os.path.basename(p))
        if not os.path.exists(dst):
            shutil.copy2(p, dst)
            backed.append(os.path.basename(p))
    # ② 接入 PNG（要求预览已目视通过；此处直接由 build_all 落盘，逐字文件名）
    applied = []
    for f in sorted(os.listdir(R23)):
        if not f.endswith(".png"):
            continue
        if f not in imgs:
            raise RuntimeError("预览缺失，拒绝接入: " + f)
        imgs[f].save(os.path.join(R23, f))
        applied.append(f)
    # ③ 重写两份 .tres（路径逐字不变）
    write_tres(TRES_P, "1_sdp81", "res://assets/generated/r23/player_spritesheet.png",
               PLAYER_ANIM, PLAYER_ACT, PLAYER_LOOP)
    write_tres(TRES_B, "1_cvjv7", "res://assets/generated/r23/boss_spritesheet.png",
               BOSS_ANIM, BOSS_ACT, BOSS_LOOP)
    # ④ 自检（对 r23 实际落盘文件统计，如实登记）
    m = {"backup_dir": BACKUP, "backup_files_written": backed,
         "applied_files": applied, "frames": {}, "single_frames": {},
         "sheets": {}, "subframe_distinct": {}, "edges": {}, "palette_outside": {},
         "death_vs_ground": {}}
    for p in PLAYER:
        m["single_frames"]["player_%s.png" % p] = frame_metrics(os.path.join(R23, "player_%s.png" % p))
    for b in BOSS:
        m["single_frames"]["boss_%s.png" % b] = frame_metrics(os.path.join(R23, "boss_%s.png" % b))
    m["frames"]["ground_tile.png"] = frame_metrics(os.path.join(R23, "ground_tile.png"))
    m["frames"]["decor_layer.png"] = frame_metrics(os.path.join(R23, "decor_layer.png"))
    # spritesheet 每帧色数 + 尺寸
    for name, n in [("player_spritesheet.png", 24), ("boss_spritesheet.png", 9)]:
        im = Image.open(os.path.join(R23, name)).convert("RGBA")
        per = []
        for i in range(n):
            per.append(uniq_rgb(im.crop((i * 128, 0, i * 128 + 128, 128))))
        m["sheets"][name] = {"size": list(im.size), "frame_count": n,
                             "per_frame_unique_rgb": per, "max_per_frame": max(per),
                             "whole_unique_rgb": uniq_rgb(im)}
    # 3 子帧互异（md5，逐像素）
    def md5(im):
        import io
        buf = io.BytesIO(); im.save(buf, format="PNG")
        return hashlib.md5(buf.getvalue()).hexdigest()
    for p in PLAYER:
        md = [md5(pframes[(p, s)]) for s in range(3)]
        m["subframe_distinct"]["player_%s" % p] = {"md5": md, "all_distinct": len(set(md)) == 3}
    for b in BOSS:
        md = [md5(bframes[(b, s)]) for s in range(3)]
        m["subframe_distinct"]["boss_%s" % b] = {"md5": md, "all_distinct": len(set(md)) == 3}
    m["subframe_distinct"]["player_all_3_distinct"] = all(
        v["all_distinct"] for k, v in m["subframe_distinct"].items() if k.startswith("player_"))
    m["subframe_distinct"]["boss_all_3_distinct"] = all(
        v["all_distinct"] for k, v in m["subframe_distinct"].items() if k.startswith("boss_"))
    # tile 边缘（逐像素 128x128）
    im = Image.open(os.path.join(R23, "ground_tile.png")).convert("RGBA")
    px = im.load()
    m["edges"]["LR_mismatch_rows"] = sum(1 for y in range(128) if px[0, y] != px[127, y])
    m["edges"]["TB_mismatch_cols"] = sum(1 for x in range(128) if px[x, 0] != px[x, 127])
    m["edges"]["four_corners_equal"] = (px[0, 0] == px[127, 0] == px[0, 127] == px[127, 127])
    # death / ground 平均明度差（量化「>=2 档」）
    dl = avg_luma_visible(os.path.join(R23, "player_death.png"))
    gl = avg_luma_visible(os.path.join(R23, "ground_tile.png"))
    m["death_vs_ground"] = {"death_avg_luma": dl, "ground_avg_luma": gl,
                            "delta_luma": round(dl - gl, 2),
                            "note": "death 主体抬到画面中部，亮面 STEEL/WHITE/GOLD/COBALT_L 与地面 COBALT/DARK 分离"}
    # 色板闭合（所有非透明 RGB 必须落在 16 色板内）
    pal = set(PALETTE)
    for name in applied:
        im = Image.open(os.path.join(R23, name)).convert("RGBA")
        bad = set((r, g, b) for r, g, b, a in im.getdata() if a > 0 and (r, g, b) not in pal)
        if bad:
            m["palette_outside"][name] = [list(c) for c in bad]
    with open(os.path.join(R4, "r26_redraw_metrics.json"), "w", encoding="utf-8") as fh:
        json.dump(m, fh, ensure_ascii=False, indent=2)
    print(json.dumps(m, ensure_ascii=False, indent=2))
    print("COMMIT OK | metrics ->", os.path.join(R4, "r26_redraw_metrics.json"))


if __name__ == "__main__":
    if "--commit" in sys.argv:
        commit()
    else:
        preview()
