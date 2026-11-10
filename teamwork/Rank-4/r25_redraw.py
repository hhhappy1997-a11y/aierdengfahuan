# -*- coding: utf-8 -*-
"""
R25 / v0.3.0 · Rank-4 受控 16 色程序化重绘（PIL，零付费 / 零外部素材生成服务）

重绘 godot/assets/generated/r23/ 下全部 PNG 的「内容」，文件名与 .tres/AtlasTexture
引用路径逐字不变；旧版先备份到 teamwork/Rank-4/r23_pre_v030_backup/ 再覆盖。

风格锚点 v1（teamwork/艾尔登法环HD2D-美术风格提案.md）：
  - 单帧非透明唯一 RGB <= 16（全素材共用同一 16 色板，与 r23_baseline/player_idle_v1.png 逐字一致）
  - 64x64 逻辑像素 x2 NEAREST -> 128x128（每个逻辑像素严格 2x2 硬边块）
  - 哑光硬边平涂：无渐变 / 无 dithering / 无高频噪点
  - RGBA 保 alpha：透明 a=0 / 不透明 a=255，无半透明脏边
  - 左上暖金主光 + 右下冷夜蓝补光；每材质 3 阶明度 + 1 阶高光
  - ground_tile 4x4 大砖、砖缝 1px #0A1020、左右/上下边缘像素完全一致

用法：
  python r25_redraw.py            # 预览：只写 teamwork/Rank-4/r25_preview/ + 联系表（不碰 r23）
  python r25_redraw.py --commit   # 接入：备份 r23 旧 PNG，再把「已目视通过」的预览图复制进 r23
                                  并跑自检，输出 r25_redraw_metrics.json
"""
from PIL import Image
import os, sys, shutil, json, hashlib, warnings
warnings.filterwarnings("ignore")

ROOT    = "F:/Game/aierdengfahuan"
R23     = os.path.join(ROOT, "godot/assets/generated/r23")
R4      = os.path.join(ROOT, "teamwork/Rank-4")
PREVIEW = os.path.join(R4, "r25_preview")
BACKUP  = os.path.join(R4, "r23_pre_v030_backup")

# ---- 16 色受控板（逐字对齐 r23_baseline/player_idle_v1.png 实测色板 / 提案 §2） ----
OUT      = (0x0A, 0x10, 0x20)  # 描边 / 砖缝 / 接触阴影
DARK     = (0x1B, 0x2A, 0x4A)  # 深蓝夜 / 暗部
GOLD     = (0xC9, 0x9A, 0x3A)  # 暖金（主光 / 肩甲 / UI 金线）
COBALT   = (0x2C, 0x4C, 0x8C)  # 主色钴蓝（盔甲 / 盾底 / 砖面）
STEEL    = (0xC9, 0xD2, 0xE0)  # 亮钢
GRAY     = (0x8A, 0x93, 0xA8)  # 中灰蓝
RED      = (0xB3, 0x3A, 0x3A)  # 暗红（披风 / 红缨 / 危险）
LEATHER  = (0x6B, 0x42, 0x26)  # 棕（皮革 / 杖）
INK      = (0x06, 0x0A, 0x14)  # 深接触阴影
RED_DK   = (0x6E, 0x20, 0x20)  # 深红
COBALT_L = (0x3F, 0x6F, 0xC4)  # 亮钴蓝
GOLD_HI  = (0xF2, 0xD0, 0x7A)  # 亮金高光
TEAL     = (0x35, 0xD0, 0xC0)  # 青（宝石 / 招式）
WHITE    = (0xF2, 0xF4, 0xF8)  # 最高亮
SKIN     = (0xE8, 0xB9, 0x8C)  # 肤色
SKY_L    = (0x79, 0xB4, 0xE8)  # 亮蓝
PALETTE  = [OUT, DARK, GOLD, COBALT, STEEL, GRAY, RED, LEATHER,
            INK, RED_DK, COBALT_L, GOLD_HI, TEAL, WHITE, SKIN, SKY_L]

N = 64  # 逻辑网格边长（64 x 64 逻辑像素 x2 NEAREST -> 128 x 128）


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
        """外轮廓统一 1 逻辑像素深色描边；内部靠色块分界，不重复描边。"""
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
                if c is None:
                    p[x, y] = (0, 0, 0, 0)
                else:
                    p[x, y] = (c[0], c[1], c[2], 255)
        return im.resize((128, 128), Image.NEAREST)


# ============================ 玩家骑士（8 姿态） ============================
def k_cape(g, mode):
    if mode == "hang":                       # 静止垂披风
        g.rect(16, 26, 26, 50, RED_DK); g.rect(38, 24, 48, 52, RED_DK)
        g.rect(14, 46, 24, 54, RED);    g.rect(42, 48, 52, 56, RED)
    elif mode == "trail":                    # 奔跑：大幅后拖
        g.rect(8, 26, 26, 42, RED_DK);  g.rect(2, 30, 16, 38, RED_DK)
        g.rect(4, 32, 14, 35, RED);     g.rect(40, 24, 50, 48, RED_DK)
    elif mode == "billow":                   # 攻击 / 受击：外张
        g.rect(10, 24, 26, 46, RED_DK); g.rect(4, 28, 18, 42, RED)
        g.rect(40, 22, 54, 46, RED_DK); g.rect(48, 26, 58, 40, RED)


def k_legs(g, mode):
    if mode == "stand":
        g.rect(26, 44, 31, 56, COBALT); g.rect(26, 44, 28, 56, COBALT_L)
        g.rect(33, 44, 38, 56, DARK);   g.rect(37, 44, 38, 56, INK)
    elif mode == "walk":
        g.rect(22, 44, 28, 56, COBALT); g.rect(22, 44, 24, 56, COBALT_L)
        g.rect(34, 46, 40, 58, DARK)
    elif mode == "run":
        g.rect(20, 42, 27, 52, COBALT); g.line(20, 50, 13, 58, COBALT_L, 4)
        g.rect(36, 48, 42, 58, DARK);   g.line(40, 52, 49, 58, INK, 3)
    elif mode == "lunge":                    # 轻攻击弓步
        g.rect(18, 44, 27, 58, COBALT); g.line(18, 52, 11, 60, COBALT_L, 4)
        g.rect(36, 44, 44, 58, DARK)
    elif mode == "wide":                     # 重攻击开立
        g.rect(18, 44, 27, 58, COBALT); g.rect(18, 44, 20, 58, COBALT_L)
        g.rect(37, 44, 46, 58, DARK);   g.rect(45, 44, 46, 58, INK)
    elif mode == "stagger":                  # 受击后撤
        g.rect(24, 46, 30, 58, COBALT); g.rect(36, 42, 42, 56, DARK)
    # 靴 + 接触阴影（各姿态统一）
    g.rect(22, 57, 31, 61, LEATHER); g.rect(33, 57, 42, 61, LEATHER)
    g.rect(20, 60, 44, 62, INK)


def k_torso(g, lean=0, dy=0):
    x = lean
    g.rect(26 + x, 24 + dy, 38 + x, 46 + dy, COBALT)      # 主色中间调
    g.rect(26 + x, 24 + dy, 30 + x, 46 + dy, COBALT_L)    # 左上亮面
    g.rect(36 + x, 24 + dy, 38 + x, 46 + dy, DARK)        # 右下暗面
    g.rect(30 + x, 28 + dy, 34 + x, 34 + dy, GOLD)        # 胸甲金饰
    g.rect(31 + x, 29 + dy, 33 + x, 33 + dy, GOLD_HI)
    g.rect(31 + x, 30 + dy, 33 + x, 32 + dy, TEAL)        # 胸宝石
    g.rect(26 + x, 42 + dy, 38 + x, 45 + dy, LEATHER)     # 腰带
    g.rect(31 + x, 42 + dy, 34 + x, 45 + dy, GOLD)


def k_head(g, lean=0, dy=0):
    x = lean
    g.rect(27 + x, 11 + dy, 37 + x, 23 + dy, DARK)        # 盔底
    g.rect(27 + x, 11 + dy, 37 + x, 15 + dy, COBALT)      # 盔顶
    g.rect(28 + x, 15 + dy, 36 + x, 21 + dy, STEEL)       # 面甲
    g.rect(29 + x, 16 + dy, 35 + x, 19 + dy, WHITE)       # 面甲高光
    g.rect(29 + x, 20 + dy, 35 + x, 22 + dy, SKIN)        # 下巴
    g.rect(27 + x, 18 + dy, 29 + x, 23 + dy, STEEL)       # 左颊
    g.rect(35 + x, 18 + dy, 37 + x, 23 + dy, GRAY)        # 右颊暗
    g.rect(30 + x, 5 + dy, 34 + x, 11 + dy, RED)          # 红缨
    g.rect(31 + x, 4 + dy, 33 + x, 6 + dy, RED_DK)


def k_shoulders(g, lean=0, dy=0):
    x = lean
    g.rect(18 + x, 23 + dy, 27 + x, 29 + dy, GOLD)
    g.rect(18 + x, 23 + dy, 20 + x, 29 + dy, GOLD_HI)
    g.rect(37 + x, 23 + dy, 46 + x, 29 + dy, GOLD)
    g.rect(44 + x, 23 + dy, 46 + x, 29 + dy, GOLD_HI)


def k_shield(g, x0=10, y0=28):
    g.rect(x0, y0, x0 + 12, y0 + 20, GOLD)                # 金框
    g.rect(x0 + 1, y0 + 1, x0 + 11, y0 + 19, COBALT)      # 内
    g.rect(x0 + 2, y0 + 2, x0 + 5, y0 + 18, COBALT_L)     # 亮面
    g.rect(x0 + 4, y0 + 6, x0 + 8, y0 + 12, TEAL)         # 青宝石
    g.rect(x0 + 5, y0 + 7, x0 + 7, y0 + 11, WHITE)
    g.rect(x0 + 1, y0 + 1, x0 + 11, y0 + 2, GOLD_HI)


def k_sword(g, mode):
    if mode == "vert":                                     # 竖直持剑（idle / walk）
        g.rect(43, 10, 47, 40, GRAY); g.rect(44, 10, 46, 40, STEEL)
        g.rect(44, 12, 45, 38, WHITE)
        g.rect(42, 38, 48, 40, GOLD); g.rect(44, 40, 46, 45, LEATHER)
        g.rect(44, 45, 46, 47, GOLD)
    elif mode == "slash":                                  # 轻攻击：水平横斩
        g.rect(18, 29, 48, 33, GRAY); g.rect(18, 30, 48, 32, STEEL)
        g.rect(20, 30, 44, 31, WHITE)
        g.rect(38, 27, 42, 35, GOLD); g.rect(40, 33, 44, 40, LEATHER)
        g.rect(14, 24, 26, 26, TEAL); g.rect(10, 27, 20, 29, TEAL)   # 挥砍弧（硬边）
        g.rect(8, 30, 16, 32, STEEL); g.rect(50, 22, 60, 24, TEAL)
    elif mode == "overhead":                               # 重攻击：高举过头
        g.rect(38, 2, 44, 26, GRAY); g.rect(39, 2, 43, 26, STEEL)
        g.rect(40, 4, 41, 24, WHITE)
        g.rect(36, 24, 46, 27, GOLD); g.rect(39, 27, 43, 32, LEATHER)
    elif mode == "lowered":                                # 受击：脱手下垂
        g.line(46, 34, 50, 54, GRAY, 2); g.rect(44, 32, 48, 35, GOLD)
    elif mode == "back":                                   # 奔跑：后摆
        g.line(44, 30, 56, 44, GRAY, 2); g.rect(42, 28, 46, 32, GOLD)
    elif mode == "stowed":                                 # 翻滚：贴地收起
        g.rect(14, 50, 30, 53, GRAY); g.rect(16, 50, 28, 52, STEEL)


def player(pose):
    g = Grid()
    if pose == "idle":
        k_cape(g, "hang"); k_legs(g, "stand")
        k_torso(g); k_head(g); k_shoulders(g)
        k_shield(g, 10, 28); k_sword(g, "vert")
    elif pose == "walk":
        k_cape(g, "hang"); k_legs(g, "walk")
        k_torso(g, 1); k_head(g, 1, -1); k_shoulders(g, 1)
        k_shield(g, 9, 26); k_sword(g, "vert")
        g.rect(28, 4, 32, 5, RED_DK)                       # 红缨前飘
    elif pose == "run":
        k_cape(g, "trail"); k_legs(g, "run")
        k_torso(g, 3, 1); k_head(g, 4, 0); k_shoulders(g, 3, 1)
        k_shield(g, 20, 24); k_sword(g, "back")
        g.rect(4, 30, 12, 31, TEAL); g.rect(2, 36, 10, 37, GRAY)   # 速度线
    elif pose == "roll":                                   # 蜷缩成球（剪影明显不同）
        g.disc(32, 44, 15, RED_DK); g.disc(32, 44, 13, COBALT)
        g.rect(24, 36, 40, 44, COBALT_L); g.rect(24, 50, 40, 54, DARK)
        g.rect(28, 40, 36, 48, STEEL); g.rect(30, 42, 34, 46, WHITE)
        g.rect(22, 38, 26, 44, GOLD)
        k_shield(g, 18, 42); k_sword(g, "stowed")
        g.rect(6, 40, 16, 42, TEAL); g.rect(4, 46, 12, 48, STEEL)
        g.rect(8, 52, 16, 54, GRAY)
    elif pose == "attack_light":
        k_cape(g, "billow"); k_legs(g, "lunge")
        k_torso(g, 2); k_head(g, 2); k_shoulders(g, 2)
        k_shield(g, 8, 26); k_sword(g, "slash")
    elif pose == "attack_heavy":
        k_cape(g, "hang"); k_legs(g, "wide")
        k_torso(g, -1, 2); k_head(g, -2, 2); k_shoulders(g, -2, 2)
        k_shield(g, 12, 34); k_sword(g, "overhead")
        g.rect(38, 0, 42, 4, GOLD_HI); g.rect(34, 4, 46, 6, GOLD_HI)  # 蓄力光
        g.rect(30, 8, 34, 10, GOLD); g.rect(48, 8, 52, 10, GOLD)
    elif pose == "hitstun":
        k_cape(g, "billow"); k_legs(g, "stagger")
        k_torso(g, -3); k_head(g, -4, 1); k_shoulders(g, -3)
        k_shield(g, 8, 38); k_sword(g, "lowered")
        g.rect(40, 10, 44, 12, WHITE); g.rect(42, 8, 46, 10, RED)      # 受击星
        g.rect(44, 14, 48, 16, WHITE); g.rect(38, 16, 40, 18, RED)
    elif pose == "death":                                  # 横躺（水平剪影）
        g.rect(6, 50, 18, 58, DARK); g.rect(8, 51, 16, 56, STEEL)
        g.rect(9, 52, 14, 54, WHITE); g.rect(10, 46, 14, 50, RED)
        g.rect(18, 48, 40, 58, COBALT); g.rect(18, 48, 40, 51, COBALT_L)
        g.rect(24, 51, 30, 55, GOLD); g.rect(26, 52, 28, 54, TEAL)
        g.rect(40, 49, 54, 57, DARK); g.rect(54, 50, 58, 56, GRAY)
        g.rect(4, 58, 58, 60, INK)
        g.rect(30, 40, 40, 44, GOLD); g.rect(32, 41, 38, 43, COBALT)   # 散落盾
        g.rect(44, 58, 58, 60, STEEL)                                   # 散落剑
    g.outline()
    return g


# ============================ Boss（3 招） ============================
def boss(move):
    g = Grid()
    phase2 = (move == "p2_holy_hammer")
    # 披风（暗红）
    g.rect(6, 22, 18, 44, RED_DK); g.rect(46, 22, 58, 44, RED_DK)
    g.rect(4, 40, 16, 50, RED);   g.rect(48, 40, 60, 50, RED)
    # 粗腿（剪影比玩家宽 1.6 倍）
    g.rect(20, 46, 28, 58, RED_DK); g.rect(36, 46, 44, 58, RED_DK)
    g.rect(18, 56, 30, 60, INK);    g.rect(34, 56, 46, 60, INK)
    # 宽躯干（暗红主色，与玩家同族辅色）
    g.rect(16, 20, 48, 48, RED); g.rect(16, 20, 22, 48, RED_DK)
    g.rect(42, 20, 48, 48, DARK)
    g.rect(24, 26, 40, 34, GOLD); g.rect(26, 27, 38, 31, GOLD_HI)
    g.rect(30, 28, 34, 31, TEAL)
    # 肩甲（暖金）
    g.rect(8, 20, 18, 34, GOLD);  g.rect(8, 20, 10, 34, GOLD_HI)
    g.rect(46, 20, 56, 34, GOLD); g.rect(54, 20, 56, 34, GOLD_HI)
    # 头 + 牛角（轮廓优先）
    g.rect(24, 8, 40, 20, DARK); g.rect(24, 8, 40, 12, RED_DK)
    g.rect(27, 12, 37, 18, STEEL); g.rect(29, 13, 35, 16, WHITE)
    g.rect(28, 17, 36, 19, RED)
    g.line(24, 10, 10, 2, GOLD, 3); g.line(24, 13, 12, 8, GOLD, 2)   # 左角
    g.line(40, 10, 54, 2, GOLD, 3); g.line(40, 13, 52, 8, GOLD, 2)   # 右角
    if phase2:                                                          # 阶段 2 神圣高光
        g.rect(24, 20, 40, 23, WHITE); g.rect(16, 34, 20, 44, GOLD_HI)
        g.rect(44, 34, 48, 44, GOLD_HI)

    if move == "p1_dagger_slash":                                       # 匕首横斩
        g.line(46, 30, 60, 26, STEEL, 2); g.rect(44, 28, 48, 32, LEATHER)
        g.rect(47, 25, 51, 27, GOLD)
        g.rect(6, 24, 20, 26, TEAL); g.rect(4, 27, 14, 29, TEAL)       # 青色横斩弧
        g.rect(8, 30, 18, 32, STEEL); g.rect(50, 22, 60, 24, TEAL)
    elif move == "p1_staff_slam":                                       # 法杖下砸
        g.rect(48, 4, 52, 54, LEATHER); g.rect(46, 2, 54, 9, GOLD)
        g.rect(47, 3, 53, 6, GOLD_HI); g.rect(49, 5, 51, 8, TEAL)
        g.rect(42, 26, 48, 30, RED_DK)
        g.rect(24, 52, 58, 56, STEEL); g.rect(30, 50, 52, 52, GOLD)    # 地面冲击块
        g.rect(36, 48, 44, 50, WHITE); g.rect(20, 54, 26, 58, GOLD_HI)
    elif move == "p2_holy_hammer":                                      # 圣锤高举
        g.rect(44, 14, 48, 32, LEATHER); g.rect(38, 2, 54, 16, GOLD)
        g.rect(40, 4, 52, 12, GOLD_HI); g.rect(44, 6, 48, 10, WHITE)
        g.rect(41, 14, 51, 16, RED_DK)
        g.rect(26, 2, 30, 6, GOLD_HI); g.rect(58, 6, 62, 10, GOLD_HI)  # 暖金光块
        g.rect(6, 10, 10, 14, GOLD);  g.rect(56, 30, 60, 34, GOLD)
        g.rect(30, 18, 34, 20, WHITE)
    g.outline()
    return g


# ============================ 地面 tile（4x4 大砖） ============================
def ground():
    g = Grid()
    g.rect(0, 0, 64, 64, COBALT)                    # 中间调铺底（3 阶之「中」）
    for by in range(4):
        for bx in range(4):
            x0 = bx * 16; y0 = by * 16
            # 砖缝 1 逻辑像素（左 / 上）#0A1020
            g.rect(x0, y0, x0 + 16, y0 + 1, OUT)
            g.rect(x0, y0, x0 + 1, y0 + 16, OUT)
            # 砖面 3 阶明度
            g.rect(x0 + 1, y0 + 1, x0 + 16, y0 + 16, COBALT)          # 中
            g.rect(x0 + 2, y0 + 2, x0 + 9, y0 + 4, COBALT_L)          # 亮（左上暖金主光向）
            g.rect(x0 + 2, y0 + 2, x0 + 4, y0 + 9, COBALT_L)
            g.rect(x0 + 10, y0 + 10, x0 + 16, y0 + 16, DARK)          # 暗（右下冷夜蓝补光）
            g.rect(x0 + 12, y0 + 12, x0 + 14, y0 + 14, INK)
            # 确定性低频装饰（规则几何，非高频噪点）：每砖一个中心块，按 (bx+by) 轮换
            key = (bx + by) % 4
            dc = [GOLD, TEAL, GRAY, STEEL][key]
            g.rect(x0 + 6, y0 + 7, x0 + 10, y0 + 10, dc)
            if key == 0:
                g.rect(x0 + 7, y0 + 7, x0 + 9, y0 + 9, GOLD_HI)
            if bx <= 1 and by <= 1:                                     # 主光区暖金高光点
                g.rect(x0 + 3, y0 + 3, x0 + 5, y0 + 5, GOLD_HI)
    # 严格无缝：最后一逻辑列/行 = 第一逻辑列/行（均为缝色 OUT），四角随之全等
    for y in range(N):
        g.g[y][N - 1] = g.g[y][0]
    for x in range(N):
        g.g[N - 1][x] = g.g[0][x]
    return g


# ============================ 装饰层（16 色规则几何，透明底） ============================
def decor():
    g = Grid()
    g.rect(2, 2, 62, 3, GOLD); g.rect(2, 61, 62, 62, GOLD)               # 金线外框
    g.rect(2, 2, 3, 62, GOLD); g.rect(61, 2, 62, 62, GOLD)
    for cx, cy in [(8, 8), (55, 8), (8, 55), (55, 55)]:                  # 四角青菱
        g.disc(cx, cy, 3, TEAL); g.px(cx, cy, WHITE)
    g.rect(30, 26, 34, 38, GOLD); g.rect(26, 30, 38, 34, GOLD)           # 中心星
    g.rect(30, 30, 34, 34, GOLD_HI)
    g.rect(3, 54, 61, 56, DARK); g.rect(3, 56, 61, 58, COBALT)           # 冷蓝雾带（3 段）
    g.rect(3, 58, 61, 60, COBALT_L)
    g.outline()
    return g


PLAYER = ["idle", "walk", "run", "roll", "attack_light", "attack_heavy", "hitstun", "death"]
BOSS = ["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]


def build_all():
    """返回 {文件名: PIL.Image}，与最终 r23 产物逐字对应。"""
    out = {}
    pimgs = [player(p).image() for p in PLAYER]
    bimgs = [boss(m).image() for m in BOSS]
    # spritesheet（单行 128px 网格，x = index*128，与 .tres AtlasTexture region 逐字对齐）
    ps = Image.new("RGBA", (1024, 128), (0, 0, 0, 0))
    for i, im in enumerate(pimgs):
        ps.paste(im, (i * 128, 0))
    out["player_spritesheet.png"] = ps
    bs = Image.new("RGBA", (384, 128), (0, 0, 0, 0))
    for i, im in enumerate(bimgs):
        bs.paste(im, (i * 128, 0))
    out["boss_spritesheet.png"] = bs
    # 单帧（与 spritesheet 对应帧内容一致）
    for p, im in zip(PLAYER, pimgs):
        out["player_%s.png" % p] = im
    for m, im in zip(BOSS, bimgs):
        out["boss_%s.png" % m] = im
    # 地面 / 装饰
    out["ground_tile.png"] = ground().image()
    out["decor_layer.png"] = decor().image()
    return out


def make_contact_sheets(imgs):
    """联系表（x2 NEAREST 放大）供 ViewImage 目视：先目视检查再接入。"""
    def big(im): return im.resize((256, 256), Image.NEAREST)
    # 玩家 8 帧：2 行 x 4 列
    cp = Image.new("RGBA", (1024, 512), (26, 32, 48, 255))
    for i, p in enumerate(PLAYER):
        cp.paste(big(imgs["player_%s.png" % p]), ((i % 4) * 256, (i // 4) * 256))
    cp.convert("RGB").save(os.path.join(R4, "r25_contact_player.png"))
    # Boss 3 招 + ground 2x2 平铺 + decor：2 行 x 3 列
    cb = Image.new("RGBA", (768, 512), (26, 32, 48, 255))
    for i, m in enumerate(BOSS):
        cb.paste(big(imgs["boss_%s.png" % m]), (i * 256, 0))
    tile = imgs["ground_tile.png"]
    t2 = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    for j in range(2):
        for i in range(2):
            t2.paste(tile, (i * 128, j * 128))
    cb.paste(big(tile), (0, 256))          # ground 单张放大
    cb.paste(t2, (256, 256))               # ground 2x2 平铺（看接缝）
    cb.paste(big(imgs["decor_layer.png"]), (512, 256))
    cb.convert("RGB").save(os.path.join(R4, "r25_contact_boss_tile.png"))


def preview():
    os.makedirs(PREVIEW, exist_ok=True)
    imgs = build_all()
    for name, im in imgs.items():
        im.save(os.path.join(PREVIEW, name))
    make_contact_sheets(imgs)
    print("PREVIEW OK ->", PREVIEW, "| files:", len(imgs))
    print("contact_sheets: r25_contact_player.png / r25_contact_boss_tile.png")


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


def frame_metrics(path):
    im = Image.open(path).convert("RGBA")
    return {"size": list(im.size), "unique_rgb_visible": uniq_rgb(im),
            "alpha_values": alpha_set(im), "block2_mismatch": block2_mismatch(im)}


def commit():
    # ① 旧版先备份（已存在则跳过，防止二次运行把 v0.3.0 当旧版覆盖，保证不可恢复项不被破坏）
    os.makedirs(BACKUP, exist_ok=True)
    pngs = sorted(f for f in os.listdir(R23) if f.endswith(".png"))
    backed = []
    for f in pngs:
        dst = os.path.join(BACKUP, f)
        if not os.path.exists(dst):
            shutil.copy2(os.path.join(R23, f), dst)
            backed.append(f)
    # ② 接入：把「已目视通过」的预览图逐字复制进 r23（文件名 / .tres / AtlasTexture 路径不变）
    applied = []
    for f in pngs:
        src = os.path.join(PREVIEW, f)
        if not os.path.exists(src):
            raise RuntimeError("预览缺失，拒绝接入: " + f)
        shutil.copy2(src, os.path.join(R23, f))
        applied.append(f)
    # ③ 自检（对 r23 实际落盘文件统计，如实登记）
    m = {"backup_dir": BACKUP, "backup_files_written": backed,
         "applied_files": applied, "frames": {}, "sheets": {}, "edges": {}, "distinct": {}}
    for p in PLAYER:
        m["frames"]["player_%s.png" % p] = frame_metrics(os.path.join(R23, "player_%s.png" % p))
    for b in BOSS:
        m["frames"]["boss_%s.png" % b] = frame_metrics(os.path.join(R23, "boss_%s.png" % b))
    m["frames"]["ground_tile.png"] = frame_metrics(os.path.join(R23, "ground_tile.png"))
    m["frames"]["decor_layer.png"] = frame_metrics(os.path.join(R23, "decor_layer.png"))
    # spritesheet 每帧色数
    for name, n in [("player_spritesheet.png", 8), ("boss_spritesheet.png", 3)]:
        im = Image.open(os.path.join(R23, name)).convert("RGBA")
        per = []
        for i in range(n):
            fr = im.crop((i * 128, 0, i * 128 + 128, 128))
            per.append(uniq_rgb(fr))
        m["sheets"][name] = {"size": list(im.size), "per_frame_unique_rgb": per,
                             "whole_unique_rgb": uniq_rgb(im)}
    # tile 边缘（逐像素）
    im = Image.open(os.path.join(R23, "ground_tile.png")).convert("RGBA")
    px = im.load()
    m["edges"]["LR_mismatch_rows"] = sum(1 for y in range(128) if px[0, y] != px[127, y])
    m["edges"]["TB_mismatch_cols"] = sum(1 for x in range(128) if px[x, 0] != px[x, 127])
    m["edges"]["four_corners_equal"] = (px[0, 0] == px[127, 0] == px[0, 127] == px[127, 127])
    # 8 帧 / 3 招互异（md5）
    def md5(p): return hashlib.md5(open(p, "rb").read()).hexdigest()
    m["distinct"]["player_8_md5"] = [md5(os.path.join(R23, "player_%s.png" % p)) for p in PLAYER]
    m["distinct"]["boss_3_md5"] = [md5(os.path.join(R23, "boss_%s.png" % b)) for b in BOSS]
    m["distinct"]["player_all_distinct"] = len(set(m["distinct"]["player_8_md5"])) == 8
    m["distinct"]["boss_all_distinct"] = len(set(m["distinct"]["boss_3_md5"])) == 3
    # 色板闭合（所有非透明 RGB 必须落在 16 色板内）
    pal = set(PALETTE)
    outside = {}
    for name in applied:
        im = Image.open(os.path.join(R23, name)).convert("RGBA")
        bad = set((r, g, b) for r, g, b, a in im.getdata() if a > 0 and (r, g, b) not in pal)
        if bad:
            outside[name] = [list(c) for c in bad]
    m["palette_outside"] = outside
    with open(os.path.join(R4, "r25_redraw_metrics.json"), "w", encoding="utf-8") as fh:
        json.dump(m, fh, ensure_ascii=False, indent=2)
    print(json.dumps(m, ensure_ascii=False, indent=2))
    print("COMMIT OK | metrics ->", os.path.join(R4, "r25_redraw_metrics.json"))


if __name__ == "__main__":
    if "--commit" in sys.argv:
        commit()
    else:
        preview()
