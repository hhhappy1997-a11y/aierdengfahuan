# -*- coding: utf-8 -*-
"""
R35 / v0.12.0 · Rank-4 地面裂缝精修（程序化重绘，零外部依赖 / 仅 Pillow）
派单 cmd-20261112-125821-147-A4 ② [ROUND=R35]

在 R34 Voronoi 不规则石板（已去掉斜条纹，但深色裂缝偏破碎 / 斜边细碎锯齿）基础上：
  - 改为【轴对齐错缝矩形石板 running bond】：每块石板边界全为水平 / 垂直直线，
    裂缝是连贯的 1px 深色直线网格（规整、不破碎），彻底消除 Voronoi 斜向阶梯
    锯齿与细碎碎块；
  - 5 个 band（行高确定性微扰 26/25/28/24/24）× 每行 4 列（列宽 31/31/32/33
    微扰 + 每行不同错缝 offset），保留一定不规则度，避免回到 R30 的 4x4 死板
    网格 / 斜条纹周期感；
  - 每块砖 3 阶明度（左上受光亮边 / 主体 / 右下背光暗边，均在受控板内）
    + 1 个 2x2 硬边高光点（确定性位置、形状受控、非逐像素噪点）。

硬约束（逐条，落盘实测写进 DONE-R35.md）：
  - 6 色受控板（从 R34 实测 hex_sorted 逐字沿用，零新增色号）
  - 128x128 / RGBA / alpha 集合 {255}
  - 左右边缘逐像素相等 + 上下边缘逐像素相等（diff=0）：
    127 核心周期 wrap 绘制 + 第 127 列/行复制第 0 列/行
  - 硬边、无渐变、无 dithering、无噪点
  - 不改 courtyard.tscn 的 uv（保 A38）

用法：python teamwork/Rank-4/r35_ground_tile_redraw.py
"""
import hashlib
import json
import os
from collections import Counter
from PIL import Image

ROOT = "F:/Game/aierdengfahuan"
DST = ROOT + "/godot/assets/generated/r23/ground_tile.png"
PREVIEW = ROOT + "/capture/r35_ground_2x2_after.png"
IMPORT_JSON = ROOT + "/godot/assets/generated/r23/ground_tile.import.json"

W = H = 128
CORE = 127
SEED = 20261112

# 6 色受控板：逐字沿用 R34 ground_tile.import.json measured.hex_sorted（按明度升序）
L = [
    (0x06, 0x0A, 0x14),  # L0 #060A14 最暗 → 缝 GAP
    (0x0A, 0x10, 0x20),  # L1 #0A1020
    (0x1B, 0x2A, 0x4A),  # L2 #1B2A4A
    (0x2C, 0x4C, 0x8C),  # L3 #2C4C8C 主体基调
    (0x3F, 0x6F, 0xC4),  # L4 #3F6FC4
    (0x79, 0xB4, 0xE8),  # L5 #79B4E8 高光
]
GAP = L[0]

# 水平缝线（band 边界，核心坐标 0..126）；5 个 band，行高确定性微扰，总和 = 127
HY = [0, 26, 51, 79, 103]
# 每行 band 的垂直缝线基础（核心坐标）；4 列，列宽微扰，总和 = 127
VX_BASE = [0, 31, 62, 94]
# 每行不同错缝 offset（确定性，制造 running bond 错缝、降低 4x4 死板周期感）
BAND_OFFSET = [0, 15, 8, 22, 12]


def _h(*parts):
    """确定性 hash（sha256 前 4 字节），固定 SEED 可复现，绝不引入随机噪点。"""
    key = (str(SEED) + "|" + "|".join(str(p) for p in parts)).encode("utf-8")
    return int.from_bytes(hashlib.sha256(key).digest()[:4], "little")


def _hex(c):
    return "#%02X%02X%02X" % (c[0], c[1], c[2])


def main():
    # 核心 127x127，全部初始化为缝色；任何跨边界绘制经 % CORE wrap → 天然 tileable
    cv = [[GAP for _ in range(CORE)] for _ in range(CORE)]

    def put(x, y, c):
        cv[int(y) % CORE][int(x) % CORE] = c

    def rect(x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                put(x, y, c)

    brick_report = []
    for b in range(len(HY)):
        y0 = HY[b]
        y1 = HY[b + 1] if b + 1 < len(HY) else CORE   # 末 band 上界 = 127
        by0, by1 = y0 + 1, y1 - 1                      # 砖内 y（缝线 y0 / y1 保持 GAP）
        if by1 <= by0:
            continue
        vxs = sorted((v + BAND_OFFSET[b]) % CORE for v in VX_BASE)
        for ci in range(len(vxs)):
            vx0 = vxs[ci]
            vx1 = vxs[(ci + 1) % len(vxs)]
            x_start = vx0 + 1
            # 跨 0 段（vx1 < vx0）：区间绕回，wrap put 自动把两半填到核心对应位置
            x_end = vx1 - 1 if vx1 > vx0 else vx1 + CORE - 1
            h = _h("brick", b, ci)
            base = 2 + (h % 3)                 # 主体基调 L2 / L3 / L4（受控板内）
            dark = max(1, base - 1)           # 右下背光暗阶 >= L1（L0 只作缝）
            light = min(5, base + 1)          # 左上受光亮阶 <= L5
            # ① 整块填主体色（轴对齐矩形，边界直线、无锯齿）
            rect(x_start, by0, x_end, by1, L[base])
            # ② 左上受光 1px 硬边（暖金主光自左上）
            for x in range(x_start, x_end):
                put(x, by0, L[light])
            for y in range(by0, by1):
                put(x_start, y, L[light])
            # ③ 右下背光 1px 硬边（冷夜雾阴影在右下）
            for x in range(x_start + 1, x_end + 1):
                put(x, by1, L[dark])
            for y in range(by0 + 1, by1 + 1):
                put(x_end, y, L[dark])
            # ④ 每块 1 个 2x2 硬边高光点（偏左上受光侧，确定性 jitter、非噪点）
            hh = _h("hl", b, ci)
            xspan = max(1, (x_end - x_start) - 8)
            yspan = max(1, (by1 - by0) - 8)
            hx = x_start + 3 + (hh % xspan)
            hy = by0 + 3 + ((hh >> 8) % yspan)
            for dy in range(2):
                for dx in range(2):
                    put(hx + dx, hy + dy, L[5])
            brick_report.append((b, ci, base))

    # 输出 128x128：核心 [0..126][0..126] + 第 127 列/行复制第 0 列/行
    out = Image.new("RGBA", (W, H))
    opx = out.load()
    for y in range(CORE):
        for x in range(CORE):
            opx[x, y] = tuple(cv[y][x]) + (255,)
    for y in range(W):
        opx[CORE, y] = opx[0, y]                 # col127 = col0
    for x in range(W):
        opx[x, CORE] = opx[x, 0]                 # row127 = row0
    os.makedirs(os.path.dirname(DST), exist_ok=True)
    out.save(DST)

    # 2x2 平铺预览（供 A41 目视对照 R34 before）
    tiled = Image.new("RGBA", (W * 2, H * 2))
    for r in range(2):
        for c in range(2):
            tiled.paste(out, (c * W, r * W))
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    tiled.save(PREVIEW)

    # ---- 落盘实测（重新打开磁盘文件，非内存自报）----
    chk = Image.open(DST).convert("RGBA")
    px = chk.load()
    colors = Counter(chk.getdata())
    hex_sorted = sorted({_hex(c[:3]) for c in colors})
    alpha_set = sorted({c[3] for c in colors})
    lr = sum(1 for y in range(H) if px[0, y] != px[W - 1, y])
    tb = sum(1 for x in range(W) if px[x, 0] != px[x, H - 1])
    edge_diff = lr + tb
    print("=== ground_tile R35 MEASURED ===")
    print("size", chk.size)
    print("unique_rgb", len(hex_sorted))
    print("hex_sorted", hex_sorted)
    print("counts", {_hex(c[:3]): n for c, n in colors.most_common()})
    print("alpha_set", alpha_set)
    print("LR_col_mismatch_px", lr, "TB_row_mismatch_px", tb)
    print("EDGE_DIFF", edge_diff)
    print("bricks", len(brick_report), "bands", len(HY), "cols_per_band", len(VX_BASE))
    print("saved", PREVIEW, tiled.size)

    # 断言：6 色 / 全在受控板 / alpha 全 255 / 严格无缝
    assert chk.size == (W, H)
    assert len(hex_sorted) == 6
    assert set(hex_sorted) == {_hex(c) for c in L}
    assert alpha_set == [255]
    assert lr == 0 and tb == 0
    print("ASSERT = ALL PASS")

    # ---- 同步更新 ground_tile.import.json（独立登记，含落盘实测）----
    doc = {
        "schema_version": "1.0",
        "round": "R35",
        "task_id": "cmd-20261112-125821-147-A4",
        "asset_id": "ground_tile_r35_v1",
        "res_path": "res://assets/generated/r23/ground_tile.png",
        "note": "R35 地面裂缝精修的独立登记文件。r23/import.json 是 impact_fx.png 专用（hd2d_fx.gd R32 只读加载其帧参数），本轮逐字未动。本文件单独登记 ground_tile 规格与落盘实测。",
        "spec": {
            "canvas": "128x128（128px 基准画布不变）",
            "mode": "RGBA",
            "palette_layer": "6 色受控板（逐字沿用 R34 实测 6 色，零新增色号）",
            "colors_6": hex_sorted,
            "hard_edge": True,
            "gradient": False,
            "dithering": False,
            "noise": False,
            "seamless": "左右列逐像素相等 + 上下行逐像素相等（diff=0），127 核心周期 wrap + 复制边界列/行",
            "uv_unchanged": "courtyard.tscn 的 ground_tile.png 引用路径与 3 处 uv1_scale (2,2,1)/(1,1,1)/(1,1,1) 逐字未动（保 A38 断言）"
        },
        "technique": {
            "name": "deterministic_tileable_ashlar_running_bond",
            "core_period_px": CORE,
            "seed": SEED,
            "bands": len(HY),
            "band_heights": [HY[i + 1] - HY[i] for i in range(len(HY) - 1)] + [CORE - HY[-1]],
            "col_widths": [VX_BASE[i + 1] - VX_BASE[i] for i in range(len(VX_BASE) - 1)] + [CORE - VX_BASE[-1]],
            "band_offsets": BAND_OFFSET,
            "bricks": len(brick_report),
            "method": "把 127 核心周期按 5 条水平缝线 + 每行 4 条错缝垂直缝线切成轴对齐矩形石板；每块边界全为水平/垂直直线，裂缝是连贯 1px 深色直线网格（不破碎、无斜向阶梯锯齿）；每块 3 阶明度（左上受光/主体/右下背光，受控板内）+ 1 个 2x2 硬边高光点。跨 0 段经 %127 wrap 自动无缝，输出 128 时第 127 列/行复制第 0 列/行 → col0==col127 / row0==row127 严格 diff=0。",
            "vs_r34": "R34 为 24 个 Voronoi 种子 → 斜向多边形边（阶梯锯齿）+ 深色裂缝破碎、细碎；本轮改轴对齐错缝矩形石板，边界直线化、裂缝连贯化、锯齿消除，达成『更规整石板分区 / 减少细碎锯齿』。",
            "placeholder": {
                "band_heights": "[PLACEHOLDER] 5 段行高 26/25/28/24/24，待试玩校准；rationale：总和恰为 127 核心周期、行高微扰降低 4x4 死板网格周期感，调参只改生成参数与登记、不改算法/场景/uv。",
                "col_widths": "[PLACEHOLDER] 4 段列宽 31/31/32/33，待试玩校准；rationale：总和 127、列宽微扰与错缝配合制造 running bond 不规则度。",
                "band_offsets": "[PLACEHOLDER] 每行错缝 offset [0,15,8,22,12]；rationale：确定性错缝打破垂直缝对齐、避免竖缝贯穿整幅形成网格感。",
                "seed_20261112": "[PLACEHOLDER] 确定性随机种子（本轮日期）；rationale：固定 seed 保证可复现、零随机噪点。",
                "core_period_127": "[PLACEHOLDER] tileable 核心周期；rationale：127 核心 + 1 复制边界列/行满足严格 diff=0 无缝且内部连续。"
            }
        },
        "measured": {
            "size": [W, H],
            "unique_rgb": len(hex_sorted),
            "hex_sorted": hex_sorted,
            "counts": {_hex(c[:3]): n for c, n in colors.most_common()},
            "alpha_set": alpha_set,
            "alpha_bins": [0, 255],
            "LR_col_mismatch_px": lr,
            "TB_row_mismatch_px": tb,
            "edge_diff": edge_diff,
            "within_6_colors": True,
            "hard_alpha_only_255": True
        },
        "two_layer_color_policy": {
            "per_frame_max_colors": 16,
            "project_palette_min_colors": 256,
            "note": "单帧 6 色 ≤16 受控上限；项目级色库 ≥256 沿用 palette_256.json（R32 已扩充至实测 256 色）。本件零新增色号，两层口径均不变。00-协作契约.md §9.3 把程序化管线定位为降级/占位；本件属本地零付费程序化素材管线，ComfyUI 仍是主美术路线，不宣称已能出图。"
        },
        "visual_review": {
            "before": "capture/r34_ground_2x2_after.png — R34 Voronoi 不规则多边形、斜向阶梯锯齿边、深色裂缝破碎细碎",
            "after": "capture/r35_ground_2x2_after.png — R35 轴对齐错缝矩形石板、边界直线、1px 连贯深色缝、锯齿消除",
            "conclusion": "裂缝由『斜向破碎 + 细碎锯齿』收敛为『规整连贯直线网格』，杂乱感明显降低（如实登记；整 tile 重复为平铺固有、仍存在）"
        },
        "zero_gpu_job": True,
        "zero_paid_service": True,
        "zero_external_dependency": True,
        "generated_by": "Python + Pillow 逐像素确定性生成（本地零付费管线，非素材生成服务）",
        "generated_at": "2026-11-12",
        "version": "v1"
    }
    with open(IMPORT_JSON, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, indent=2)
    print("saved", IMPORT_JSON)


if __name__ == "__main__":
    main()
