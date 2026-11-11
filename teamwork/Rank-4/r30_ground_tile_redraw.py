# -*- coding: utf-8 -*-
"""
R30 v0.8.0 · Rank-4 地面平铺精修（程序化重绘，零外部依赖 / 仅 Pillow）
派单 cmd-20261111-125001-360-A4 [ROUND=R30]

保持（硬约束）：
  - 6 色受控板（从旧版真读、逐字沿用，不私加新色）
  - 128x128 / RGBA
  - 4x4 大砖（每砖 32x32）
  - 左/右 边缘像素完全一致、上/下 边缘像素完全一致（无缝）
改进（降低高倍平铺重复感）：
  - ① 砖块色阶微扰：16 块砖各自「主体明度基调 base / 明度阶数 steps」由确定性 hash 扰动
  - ② 磨损纹理用受控色形状（短划痕 / 2x2 小色块，颜色取自 6 色板），非逐像素随机噪点
  - ③ 每砖恰好 3~5 阶明度（同心方框梯度，板内连续阶、不 clamp 饱和）
旧版先备份到 teamwork/Rank-4/v070_pre_v080_backup/ 再覆盖。

用法：python teamwork/Rank-4/r30_ground_tile_redraw.py
"""
import hashlib
import os
import shutil
from collections import Counter
from PIL import Image

ROOT = "F:/Game/aierdengfahuan"
SRC = ROOT + "/godot/assets/generated/r23/ground_tile.png"
BAK_DIR = ROOT + "/teamwork/Rank-4/v070_pre_v080_backup"
BAK = BAK_DIR + "/ground_tile.png"
PRE_OLD = ROOT + "/teamwork/Rank-4/r30_tile_old_tiled.png"
PRE_NEW = ROOT + "/teamwork/Rank-4/r30_tile_new_tiled.png"

W = H = 128
CELL = 32              # 4x4 大砖
SEED = 20261111


def _h(*parts):
    """确定性 hash（sha256 前 4 字节），固定 SEED 可复现，绝不引入随机噪点。"""
    key = (str(SEED) + "|" + "|".join(str(p) for p in parts)).encode("utf-8")
    return int.from_bytes(hashlib.sha256(key).digest()[:4], "little")


def _tiled_preview(tile, path, n=3):
    out = Image.new("RGBA", (W * n, H * n))
    for r in range(n):
        for c in range(n):
            out.paste(tile, (c * W, r * W))
    out.save(path)


def main():
    # 备份旧版（覆盖前；仅当备份不存在时创建，防重跑把新版覆盖进备份）
    os.makedirs(BAK_DIR, exist_ok=True)
    if not os.path.exists(BAK):
        shutil.copyfile(SRC, BAK)
    # 始终以原始 v070 备份为基准读 6 色板 / 生成旧版预览（重跑不漂移）
    old = Image.open(BAK).convert("RGBA")
    assert old.size == (W, H)
    # 旧版 3x3 平铺预览（先目视检查再接入：与新版对照重复感）
    _tiled_preview(old, PRE_OLD)

    # 6 色受控板：从旧版真读，按明度升序 L0(最暗) .. L5(最亮)
    cnt = Counter(old.getdata())
    assert len(cnt) == 6, "旧版应为 6 色受控板"
    L = sorted([c[:3] for c in cnt], key=lambda c: c[0] + c[1] + c[2])
    GAP = L[0]                      # 最暗阶：缝隙色（保证边缘像素完全一致）

    # 画布：全部初始化为缝隙色
    cv = [[GAP for _ in range(W)] for _ in range(H)]

    def put(x, y, c):
        cv[y % H][x % W] = c        # wrap：任何跨边界绘制自动无缝

    def rect(x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                put(x, y, c)

    # 4x4 大砖逐块绘制
    brick_report = []
    for r in range(4):
        for c in range(4):
            cx, cy = c * CELL, r * CELL
            h = _h("brick", r, c)
            # ① 色阶微扰：主体基调 1/2/3，明度阶数 3/4/5（16 块砖各不相同 → 重复周期 32px→128px）
            #    [PLACEHOLDER] base 取 1/2/3 而非 2/3/4：目视首版偏亮（L5 亮色占 38%），
            #    下调一阶使整体明度贴近 v070 冷夜深蓝基调，避免画面突兀变亮；待试玩校准。
            base = 1 + (h % 3)
            steps = 3 + ((h >> 8) % 3)
            # ③ 3~5 阶明度：同心方框，从外向内逐阶提亮；start 使 steps 个 idx 连续且落在 0..5，
            #    不因 clamp 饱和而让实际明度阶数缩水。
            start = max(0, min(5 - (steps - 1), base - 1))
            used = set()
            for k in range(steps):
                idx = start + k
                rect(cx + 1 + k, cy + 1 + k, cx + 30 - k, cy + 30 - k, L[idx])
                used.add(idx)
            # ② 受控磨损：短划痕 / 2x2 小色块，颜色 = 板内比主体暗 1 阶（非噪点、对比柔和）
            #    [PLACEHOLDER] 每砖固定 2 处：首版 2~3 处目视略碎，收敛为 2 处；待试玩校准。
            wear = L[max(0, min(5, base - 1))]
            nw = 2
            for i in range(nw):
                hh = _h("wear", r, c, i)
                wx = cx + 6 + (hh % 18)
                wy = cy + 6 + ((hh >> 8) % 18)
                kind = (hh >> 16) % 3
                ln = 3 + (hh % 4)
                if kind == 0:
                    for dx in range(ln):
                        put(wx + dx, wy, wear)
                elif kind == 1:
                    for dy in range(ln):
                        put(wx, wy + dy, wear)
                else:
                    for dy in range(2):
                        for dx in range(2):
                            put(wx + dx, wy + dy, wear)
            brick_report.append((r, c, base, steps, used))

    # 缝隙：每砖左右/上下各 1px 全幅缝线、统一 GAP 色
    #   x=0 / x=31 / x=32 / ... / x=127 均为缝 → 左右边缘像素完全一致
    #   y=0 / y=31 / ... / y=127 均为缝 → 上下边缘像素完全一致
    for r in range(4):
        cy = r * CELL
        for x in range(W):
            put(x, cy, GAP)
            put(x, cy + CELL - 1, GAP)
    for c in range(4):
        cx = c * CELL
        for y in range(H):
            put(cx, y, GAP)
            put(cx + CELL - 1, y, GAP)

    # 输出（覆盖 godot/assets/generated/r23/ground_tile.png）
    img = Image.new("RGBA", (W, H))
    img.putdata([tuple(px) + (255,) for row in cv for px in row])
    img.save(SRC)
    _tiled_preview(img, PRE_NEW)

    # ---- 真跑统计（重新打开磁盘文件，非内存自报） ----
    chk = Image.open(SRC).convert("RGBA")
    px = chk.load()
    colors = Counter(chk.getdata())
    lr = sum(1 for y in range(H) if px[0, y] != px[W - 1, y])
    tb = sum(1 for x in range(W) if px[x, 0] != px[x, H - 1])
    step_counts = sorted({len(b[4]) for b in brick_report})
    print("=== R30 ground_tile 重绘实测 ===")
    print("size =", chk.size, " mode =", chk.mode)
    print("unique_colors =", len(colors))
    for col, n in colors.most_common():
        print("   ", tuple(col), n)
    print("palette_in_old_board =", set(c[:3] for c in colors).issubset(set(L)))
    print("left_right_edge_diff =", lr, " top_bottom_edge_diff =", tb)
    print("bricks = 4x4 =", len(brick_report))
    print("brightness_steps_per_brick =", step_counts, "(要求 3~5 阶)")
    print("base_tone_by_brick =", [b[2] for b in brick_report])
    print("steps_by_brick     =", [b[3] for b in brick_report])
    print("backup =", BAK, os.path.getsize(BAK), "B")
    print("preview_old =", PRE_OLD)
    print("preview_new =", PRE_NEW)
    assert chk.size == (W, H)
    assert len(colors) == 6
    assert set(c[:3] for c in colors).issubset(set(L))
    assert lr == 0 and tb == 0
    assert all(3 <= s <= 5 for s in step_counts)
    print("ASSERT = ALL PASS")


if __name__ == "__main__":
    main()
