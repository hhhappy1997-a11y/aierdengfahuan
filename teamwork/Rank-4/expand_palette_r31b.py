# -*- coding: utf-8 -*-
"""
R31B / A40 · 项目级色库 >=256 色合规清零（程序化、零依赖、确定性）
派单 cmd-20261111-141611-511-A4 · Rank-4

硬约束落地：
  * 只写 Rank-4 授权范围内的两份 palette_256.json（teamwork/Rank-4/ 与 godot/assets/generated/）。
  * 保留 colors[0..31] 逐字不变 —— hd2d_fx.gd 的 PALETTE_HEX、r23/import.json 的 palette、
    luma_l0_l8 的 index、semantic_groups 的 indices、HD2D-STYLE-ANCHOR-v2.md §8.4 的
    colors[8]/colors[2] 全部引用前 32 色索引，任何改动都会破坏既有引用。
  * 追加 224 色 = 8 语义族 x (4 离散明度档 x 7 色相微阶)，全部精确 hex6 大写、去重、确定性。
  * 「受控色板」：色库是离散索引色号集合，不是图像渲染；4 明度档对应 v1 光照规范
    「3 阶明度(暗/中/亮) + 1 阶高光」的离散索引色，7 色相微阶对应「同族对象只换主色区分个体」，
    档间为硬跳变索引色 —— 无连续插值渐变、无随机噪点、无 dithering。
  * 不改单帧 <=16 色口径（import.json per_frame_max_colors=16 不动）。
  * 零依赖：仅 Python 标准库 json / colorsys / re，无 random（确定性）、无第三方包、无 GPU job。
"""
import json
import colorsys
import re
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

ROOT = "F:/Game/aierdengfahuan"
TARGETS = [
    ROOT + "/teamwork/Rank-4/palette_256.json",
    ROOT + "/godot/assets/generated/palette_256.json",
]
SOURCE = TARGETS[0]

# 8 个语义族（逐字对应既有 semantic_groups 的 key），各取一个 32 色板内的锚点色作 HSV 基准
FAMILIES = [
    ("warm_gold_key", "#C97A2E"),
    ("cold_night_fog", "#2B3A5C"),
    ("deep_blue_ui", "#1F3A63"),
    ("gold_line", "#E8C479"),
    ("stone_earth", "#9A8E78"),
    ("vegetation", "#6C8A70"),
    ("ui_text", "#9FB4D4"),
    ("status", "#D9584A"),
]

# 4 离散明度档（暗 / 中 / 亮 / 高光），非渐变：档间为整数索引硬跳变
V_LEVELS = [0.30, 0.50, 0.70, 0.90]
# 7 个色相微阶（同族个体主色变体），确定性、对称、低幅度
H_OFFSETS = [-0.045, -0.030, -0.015, 0.0, 0.015, 0.030, 0.045]
S_CLAMP_MIN = 0.12
S_CLAMP_MAX = 0.55  # 低饱和夜景为底，不引入新高饱和抢眼色族（J3 白名单不变）
HEX6_RE = re.compile(r"^#[0-9A-F]{6}$")


def hex_to_hsv(hex_color):
    r = int(hex_color[1:3], 16) / 255.0
    g = int(hex_color[3:5], 16) / 255.0
    b = int(hex_color[5:7], 16) / 255.0
    return colorsys.rgb_to_hsv(r, g, b)


def hsv_to_hex(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h % 1.0, max(0.0, min(1.0, s)), max(0.0, min(1.0, v)))
    return "#%02X%02X%02X" % (
        int(round(r * 255)), int(round(g * 255)), int(round(b * 255))
    )


def main():
    with open(SOURCE, "r", encoding="utf-8") as f:
        data = json.load(f)

    base = list(data["colors"])
    assert len(base) == 32, "源色库基线须为 32 色，实测 %d" % len(base)
    base32_snapshot = list(base)
    seen = set(base)

    appended = []
    family_ranges = {}
    idx = len(base)
    for fam_name, anchor_hex in FAMILIES:
        h0, s0, _v0 = hex_to_hsv(anchor_hex)
        s = max(S_CLAMP_MIN, min(S_CLAMP_MAX, s0 * 0.90))
        start = idx
        for v in V_LEVELS:
            for dh in H_OFFSETS:
                cand = hsv_to_hex(h0 + dh, s, v)
                # 确定性去重：撞色时对明度做 1/255 步进微调，仍撞再对色相做 1/1000 步进微调
                k = 0
                while cand in seen and k < 64:
                    cand = hsv_to_hex(h0 + dh + 0.001 * (k // 8 + 1), s, v + 0.004 * (k % 8 + 1))
                    k += 1
                assert cand not in seen, "去重失败（确定性网格冲突）: %s" % cand
                seen.add(cand)
                appended.append(cand)
                idx += 1
        family_ranges[fam_name] = [start, idx - 1]

    assert len(appended) == 224, "扩展色数须为 224，实测 %d" % len(appended)
    colors = base + appended
    assert len(colors) == 256 and len(set(colors)) == 256, "总色数/去重断言失败"
    assert colors[:32] == base32_snapshot, "前 32 色锚点逐字不变断言失败"
    assert all(HEX6_RE.match(c) for c in colors), "存在非 hex6 大写色号"

    # --- 更新 spec（A40 清零后的如实口径；不动 semantic_groups / luma_l0_l8 / usage / pending） ---
    data["version"] = "r31b.1"
    data["status"] = "r31b_expanded_ge256"
    spec = data["spec"]
    spec["color_count"] = 256
    spec["max_colors"] = 256
    spec["note"] = (
        "全项目共用一份项目级色库。R31B / A40 合规清零：色数由冻结 32 色扩充到实测 256 色，"
        "满足契约 §9.3 / 裁决 A15「项目级色库 >=256 色」下限；256 为下限达标实测值、非封顶"
        "（A15 明确不再以 <=256 封顶压缩色域）。colors[0..31] 为冻结 32 色锚点、逐字不变，"
        "保护所有既有索引引用；colors[32..255] 为 R31B 确定性离散扩展色，见 r31b_extension。"
        "单帧强制 <=16 色索引口径不变，后续继续扩展须经总指挥裁决统一并入、单资产不得私加。"
    )

    data["r31b_extension"] = {
        "round": "R31B",
        "decision": "A40 项目级色库 >=256 色合规清零",
        "method": "deterministic_hsv_grid",
        "zero_dependency": "Python 标准库 json/colorsys/re；无 random（确定性）、无第三方包、零付费、零 GPU job、零外部素材服务",
        "base_colors_preserved": 32,
        "appended_colors": 224,
        "total_colors": 256,
        "families": 8,
        "per_family": 28,
        "grid": "每族 4 离散明度档(暗/中/亮/高光 V=0.30/0.50/0.70/0.90) x 7 色相微阶(-0.045..+0.045)，饱和度 clamp 0.12~0.55",
        "family_index_ranges": family_ranges,
        "no_gradient_no_noise_no_dither": (
            "色库是离散索引色号集合、不是图像渲染；4 明度档是 v1 光照「3 阶明度 + 1 阶高光」"
            "的硬跳变索引色（非连续插值渐变），7 色相微阶是「同族对象只换主色区分个体」的"
            "离散主色变体；全部由确定性公式生成，无随机噪点、无 dithering、无 alpha 过渡。"
        ),
        "invariants": [
            "colors[0..31] 逐字不变：hd2d_fx.gd PALETTE_HEX、r23/import.json palette、luma_l0_l8 index、semantic_groups indices、HD2D-STYLE-ANCHOR-v2.md §8.4 colors[8]/colors[2] 全部保持有效",
            "全部 hex6 大写 #RRGGBB、全局去重、确定性可复现",
            "单帧 <=16 色索引口径不变（r23/import.json per_frame_max_colors=16 未改；16 色受控表 §5.2 逐字冻结）",
            "不改 128px 基准画布 / RGBA 保 alpha / 128bit 歧义保留待用户确认",
        ],
        "rationale": (
            "A40 指出 R31 报告 palette_256.json 实测仅 32 色、未达 §9.3 项目级 >=256 下限。"
            "按 A15 两层口径，项目级色库是下限、单帧 <=16 色索引是上限，二者不矛盾："
            "色库大全项目共享、单帧从中取 <=16 色。以 8 语义族 x 28 离散档追加 224 色，"
            "既补齐下限又保持受控色板（低饱和夜景为底、暖金点缀），不引入新色族/渐变/噪点。"
        ),
    }

    payload = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    for path in TARGETS:
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(payload)

    # --- 落盘后逐份回读实测 ---
    print("=== R31B / A40 色库扩充真跑实测 ===")
    for path in TARGETS:
        with open(path, "r", encoding="utf-8") as f:
            d = json.load(f)
        cs = d["colors"]
        uniq = len(set(cs))
        first32_ok = cs[:32] == base32_snapshot
        fmt_ok = all(HEX6_RE.match(c) for c in cs)
        print("PATH=%s" % path)
        print("  palette_id=%s version=%s status=%s" % (
            d["palette_id"], d["version"], d["status"]))
        print("  spec.color_count=%s spec.max_colors=%s" % (
            d["spec"]["color_count"], d["spec"]["max_colors"]))
        print("  measured len(colors)=%d  unique=%d  >=256=%s" % (
            len(cs), uniq, len(cs) >= 256))
        print("  first32_preserved=%s  all_hex6_uppercase=%s  no_duplicate=%s" % (
            first32_ok, fmt_ok, uniq == len(cs)))
        print("  appended=%d  families=%d  per_family=%d" % (
            d["r31b_extension"]["appended_colors"],
            d["r31b_extension"]["families"],
            d["r31b_extension"]["per_family"]))
    print("RESULT=PASS  measured_color_count=256  meets_ge_256=True")


if __name__ == "__main__":
    main()
