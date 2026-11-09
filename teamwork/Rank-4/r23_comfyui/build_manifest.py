#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""R23: 由 batch_log.json 生成 godot/assets/generated/r23/manifest.json 并重建目视联系表。"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

DEST = Path("F:/Game/aierdengfahuan/godot/assets/generated/r23")
LOG = Path("F:/Game/aierdengfahuan/teamwork/Rank-4/r23_comfyui/batch_log.json")
SHEET = Path("F:/Game/aierdengfahuan/teamwork/Rank-4/r23_comfyui/contact_sheet_generated.png")

log = json.loads(LOG.read_text(encoding="utf-8"))
jobs = [j for j in log["jobs"] if j["status"] == "ok"]

assets = []
for j in jobs:
    a = {
        "file": j["tag"] + ".png",
        "pose": j["pose"],
        "kind": j["kind"],
        "seed": j["seed"],
        "size": j["size"],
        "mode": "RGBA",
        "unique_rgb_visible": j["unique_rgb_visible"],
        "alpha": j["alpha"],
        "alpha_coverage": j["alpha_coverage"],
        "published_in_pck": True,
        "comfyui_output": j["comfyui_output"],
    }
    if j.get("retry"):
        a["retry"] = j["retry"]
    if j.get("postprocess"):
        a["postprocess"] = j["postprocess"]
    assets.append(a)

manifest = {
    "schema_version": 1,
    "round": "R23",
    "task_id": "cmd-20261109-133602-467-A4",
    "source": "ComfyUI 本地 http://127.0.0.1:8188 (v0.33.2)，零付费、本机 GPU (NVIDIA RTX 4060 Ti)",
    "workflow": {
        "base": "comfyui_workflow_pixel.json 的 9 节点骨架 + 本机 /history 已 success 配置",
        "checkpoint": "pixelArtDiffusionXL_spriteShaper.safetensors",
        "loras": ["pixel-art-xl.safetensors (0.8)",
                  "sdxl_lightning_4step_lora.safetensors (0.75)"],
        "sampler": "euler / sgm_uniform / steps=8 / cfg=1.8",
        "latent": "512x512 -> ImageScale nearest-exact -> 128x128",
        "ImageQuantize": "已移除（原 colors=256 硬限制删除），允许 256 色以上",
        "prompt_template": "见 r23_comfyui/batch_generate.py BASE_POS / NEG（DNF 风格规律见 DNF-STYLE-REFERENCE-R23.md）",
    },
    "spec": {
        "canvas": "128x128（128px 基准画布保持不变）",
        "color_policy": "不强制量化到 <=256 色；实测色数按非透明像素唯一 RGB 统计，如实登记",
        "color_range_actual": [min(a["unique_rgb_visible"] for a in assets),
                               max(a["unique_rgb_visible"] for a in assets)],
        "alpha": ("RGBA：玩家 / Boss / 装饰层由本机确定性 flood-fill 抠纯色背景生成硬边 alpha；"
                  "ground_tile alpha 全 255（不透明）"),
        "128bit_ambiguity": ("用户口径「128bit 256色以上」中 128bit 的具体含义仍待用户确认；"
                             "本轮不擅自改尺寸口径，128px 基准画布保持不变，歧义在 DONE-R23.md 显式保留"),
    },
    "provenance": ("像素 100% 来自本机 ComfyUI 输出 PNG；alpha 与 ground_tile 无缝化均为本机确定性后处理，"
                   "不绘制新像素、不伪造 PNG；未使用任何 DNF 贴片或付费素材生成服务"),
    "published_in_pck": True,
    "frame_order": {
        "player": ["idle", "walk", "run", "roll", "attack_light", "attack_heavy", "hitstun", "death"],
        "boss": ["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"],
        "coordinate_system": ("单行 128px 网格：player x=0,128,...,896（1024x128）；"
                              "boss x=0,128,256（384x128）。与既有 player_spriteframes.tres(8) / "
                              "boss_spriteframes.tres(3) 的 AtlasTexture region 逐字一致"),
        "note": "本轮仅产出 r23/ 目录内素材，未改任何 .tres / 场景 / 脚本；R23B 才接入",
    },
    "assets": assets,
    "spritesheets": {
        "player_spritesheet.png": {"size": [1024, 128], "frames": 8, "aligned_with": "player_spriteframes.tres"},
        "boss_spritesheet.png": {"size": [384, 128], "frames": 3, "aligned_with": "boss_spriteframes.tres"},
    },
    "ground_tile_seamless": log.get("ground_tile_seamless"),
    "retries": log.get("retries", []),
    "gpu_discipline": {
        "queue_final": "running=0 / pending=0",
        "one_job_at_a_time": "串行提交：确认上一个 job completed 且 /queue running=0 才提交下一个",
        "old_qwen_image_job": "不杀、不重启、不触碰",
        "queue_timeouts": log.get("queue_timeouts", 0),
        "system_stats_timeouts": log.get("system_stats_timeouts", 0),
        "blocked": log.get("blocked", False),
        "note": ("首轮曾出现 /system_stats、/queue、/history/<id> 的 curl 超时/空返回，"
                 "按「以 /queue 为准、超时如实登记」处理；以 output 目录真实 PNG 为硬证据"),
    },
    "visual_check": ("13 张（含 1 张重试）经 ViewImage 棋盘格联系表目视确认为清晰可辨素材，"
                     "无破图/空白/重复小人，透明背景干净；ground_tile 2x2 平铺目视接缝消失"),
    "three_stage_gate": {
        "commands": ["--headless --import",
                     "--headless --check-only --script res://scripts/verify_fx_mobile.gd",
                     "--headless --quit"],
        "exit_codes": [0, 0, 0],
        "SCRIPT_ERROR_or_Parse_Error_count": 0,
        "note": "G3 退出时引擎报 2 ObjectDB instances leaked（warning，非 SCRIPT ERROR），如实登记",
        "logs": ["capture/r23_ref_g1_import.log", "capture/r23_ref_g2_check.log",
                 "capture/r23_ref_g3_quit.log"],
    },
    "compliance": {
        "dnf_resources": ("DNF 贴片版权归 Neople/腾讯，仅在 teamwork/Rank-4/r23_dnf_reference/ 作本机风格参考；"
                          "该目录 .gdignore + raw/ .gitignore + manifest published_in_pck:false；"
                          "未拷入 godot/assets/、未进 pck/exe/apk/发布包"),
        "generated_assets": "本机 ComfyUI 原创生成，published_in_pck:true，可进发布包",
        "zero_paid": True,
    },
}

(DEST / "manifest.json").write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")

# 重建最终目视联系表（读最新 PNG，含无缝化后的 ground_tile）
CW, CH, COLS = 152, 176, 4
rows = (len(jobs) + COLS - 1) // COLS
sheet = Image.new("RGB", (COLS * CW, rows * CH), (24, 24, 32))
d = ImageDraw.Draw(sheet)
font = ImageFont.load_default()
for i, j in enumerate(jobs):
    im = Image.open(DEST / (j["tag"] + ".png")).convert("RGBA")
    bg = Image.new("RGBA", (128, 128), (0, 0, 0, 255))
    px = bg.load()
    for y in range(128):
        for x in range(128):
            px[x, y] = (58, 58, 68, 255) if ((x // 8) + (y // 8)) % 2 == 0 else (92, 92, 102, 255)
    bg.alpha_composite(im)
    x0, y0 = (i % COLS) * CW + 10, (i // COLS) * CH + 4
    sheet.paste(bg.convert("RGB"), (x0, y0))
    d.text((x0, y0 + 133), j["tag"][:23], fill=(240, 215, 150), font=font)
    d.text((x0, y0 + 146),
           "seed=%d c=%d%s" % (j["seed"], j["unique_rgb_visible"], " R" if j.get("retry") else ""),
           fill=(150, 180, 210), font=font)
sheet.save(SHEET)

print(json.dumps({"manifest": str(DEST / "manifest.json"),
                  "assets": len(assets),
                  "color_range": manifest["spec"]["color_range_actual"],
                  "sheet": str(SHEET),
                  "r23_files": sorted(p.name for p in DEST.iterdir())}, ensure_ascii=False))
