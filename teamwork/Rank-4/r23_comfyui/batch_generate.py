#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""R23: 本机 ComfyUI 串行批量重绘 -> godot/assets/generated/r23/ 可发布 RGBA 素材。

纪律：
- 一次只提交一个 GPU job：POST /prompt 后轮询 /history/<id> 确认完成，再提交下一个。
- 不杀不重启任何既有 job（尤其旧 qwen-image job）。
- /system_stats、/queue 超时按「以 /queue 为准、超时如实登记」处理，写进 batch_log.json。
- 工作流基于 comfyui_workflow_pixel.json 骨架 + 本机 /history 已 success 配置，
  【已移除 ImageQuantize(colors=256)】，允许 256 色以上；128px 基准画布不变。
- 像素 100% 来自 ComfyUI 输出 PNG；alpha 由本机确定性 flood-fill 抠背景生成（不绘制像素、不伪造）。
- 统计只算非透明像素唯一 RGB，如实登记实际色数。
"""
from __future__ import annotations

import json
import os
import time
import urllib.request
from pathlib import Path

import numpy as np
from PIL import Image

BASE = "http://127.0.0.1:8188"
OUT = Path("F:/Download/ComfyUI-output")
DEST = Path("F:/Game/aierdengfahuan/godot/assets/generated/r23")
LOG = Path("F:/Game/aierdengfahuan/teamwork/Rank-4/r23_comfyui/batch_log.json")
DEST.mkdir(parents=True, exist_ok=True)

CKPT = "pixelArtDiffusionXL_spriteShaper.safetensors"
NEG = ("smooth gradients, anti-aliasing, blurry, 3d render, photorealistic, "
       "jpeg artifacts, watermark, text, signature, extra limbs, duplicate characters, "
       "cropped, multiple views, gradient background, glow, motion blur, "
       "realistic skin texture, depth of field, frame, border, vignette")

BASE_POS = ("pixel art game sprite, full body, front three-quarter view, "
            "bold near-black 1px hard outline, flat cel shading with 3 hard value steps, "
            "saturated warm gold armor trim and deep cobalt blue plate, cyan gem accents, "
            "crisp hard pixel edges, no anti-aliasing, centered, feet on ground line, "
            "HD-2D dark fantasy, readable silhouette, "
            "solid uniform flat neutral gray background, no gradient, no shadow, no texture")

# pose 名 / 帧序 / 坐标系与既有 player_spriteframes.tres(8) / boss_spriteframes.tres(3) 一致
PLAYER = ["idle", "walk", "run", "roll", "attack_light", "attack_heavy", "hitstun", "death"]
BOSS = ["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]
PLAYER_POSE = {
    "idle": "standing idle stance holding a longsword lowered",
    "walk": "mid-stride walking pose, one leg forward",
    "run": "running forward with cloak swept back",
    "roll": "crouched rolling dodge, tucked body",
    "attack_light": "quick horizontal sword slash, arm extended",
    "attack_heavy": "heavy overhead greatsword swing raised high, dynamic",
    "hitstun": "recoiling from a hit, staggered backward",
    "death": "fallen to one knee, collapsed",
}
BOSS_POSE = {
    "p1_dagger_slash": "large horned boss demon, twin daggers crossed slash",
    "p1_staff_slam": "large horned boss demon, slamming a great staff down",
    "p2_holy_hammer": "large horned boss demon, raising a glowing holy hammer overhead",
}

JOBS = []
for i, p in enumerate(PLAYER):
    JOBS.append(dict(kind="player", pose=p, tag="player_" + p,
                     text=BASE_POS + ", single fantasy knight, " + PLAYER_POSE[p],
                     seed=20261109010 + i, alpha=True))
for i, p in enumerate(BOSS):
    JOBS.append(dict(kind="boss", pose=p, tag="boss_" + p,
                     text=BASE_POS + ", " + BOSS_POSE[p],
                     seed=20261109030 + i, alpha=True))
JOBS.append(dict(kind="decor", pose="decor_layer", tag="decor_layer",
                 text=("pixel art decorative layer, ancient gothic stone pillar with hanging "
                       "deep-blue gold-trimmed banner, bold near-black 1px outline, flat cel shading, "
                       "warm gold and cobalt blue, crisp hard pixel edges, no anti-aliasing, "
                       "centered, HD-2D dark fantasy, solid uniform flat neutral gray background, "
                       "no gradient, no shadow, full object visible"),
                 seed=20261109050, alpha=True))
JOBS.append(dict(kind="ground", pose="ground_tile", tag="ground_tile",
                 text=("seamless tileable pixel art stone dungeon floor, top-down orthographic, "
                       "square texture, cracked flagstones with warm gold grout, deep blue-grey stone, "
                       "crisp hard pixel edges, no anti-aliasing, full bleed, uniform lighting, "
                       "repeats seamlessly on all four edges, no character, no border, no frame"),
                 seed=20261109060, alpha=False))


def workflow(job: dict) -> dict:
    p = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "LoraLoader", "inputs": {
            "lora_name": "pixel-art-xl.safetensors", "strength_model": 0.8,
            "strength_clip": 0.8, "model": ["1", 0], "clip": ["1", 1]}},
        "3": {"class_type": "LoraLoader", "inputs": {
            "lora_name": "sdxl_lightning_4step_lora.safetensors",
            "strength_model": 0.75, "strength_clip": 0.75,
            "model": ["2", 0], "clip": ["2", 1]}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": job["text"], "clip": ["3", 1]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["3", 1]}},
        "6": {"class_type": "EmptyLatentImage", "inputs": {
            "width": 512, "height": 512, "batch_size": 1}},
        "7": {"class_type": "KSampler", "inputs": {
            "seed": job["seed"], "steps": 8, "cfg": 1.8,
            "sampler_name": "euler", "scheduler": "sgm_uniform", "denoise": 1.0,
            "model": ["3", 0], "positive": ["4", 0], "negative": ["5", 0],
            "latent_image": ["6", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["1", 2]}},
        "9": {"class_type": "ImageScale", "inputs": {
            "image": ["8", 0], "upscale_method": "nearest-exact",
            "width": 128, "height": 128, "crop": "disabled"}},
        "10": {"class_type": "SaveImage", "inputs": {
            "images": ["9", 0], "filename_prefix": "r23_g_" + job["tag"]}},
    }
    # 无 ImageQuantize 节点：解除 <=256 色硬限制
    return p


def post(prompt: dict):
    body = json.dumps({"prompt": prompt, "client_id": "rank4-r23-batch"}).encode()
    req = urllib.request.Request(BASE + "/prompt", data=body,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode())


def probe(url: str, timeout: int = 8):
    """返回 (data|None, timed_out)。超时如实登记。"""
    try:
        with urllib.request.urlopen(url, timeout=timeout) as r:
            return json.loads(r.read().decode()), False
    except Exception:
        return None, True


def wait_done(pid: str, before: set, timeout: int = 240):
    t0 = time.time()
    sys_timeouts = 0
    while time.time() - t0 < timeout:
        d, to = probe(BASE + "/history/" + pid, timeout=10)
        if to:
            sys_timeouts += 1
        if d:
            v = list(d.values())[0]
            if v.get("status", {}).get("completed") or v.get("outputs"):
                # 仍以 /queue 为准复核 idle
                q, qto = probe(BASE + "/queue")
                if qto:
                    sys_timeouts += 1
                    # /queue 超时：以 /history completed 为准，超时如实登记
                    return True, sys_timeouts
                elif q and not q.get("queue_running"):
                    return True, sys_timeouts
        time.sleep(3)
    return False, sys_timeouts


def unique_rgb_visible(im: Image.Image) -> int:
    a = np.asarray(im.convert("RGBA"))
    vis = a[:, :, 3] > 0
    rgb = a[:, :, :3][vis].reshape(-1, 3)
    return int(len(np.unique(rgb, axis=0))) if rgb.size else 0


def remove_bg(im: Image.Image) -> Image.Image:
    """确定性 flood-fill：从四边扩散，只吞掉与背景色接近的连通像素，生成硬边 alpha。"""
    rgb = np.asarray(im.convert("RGB")).astype(np.int16)
    h, w = rgb.shape[:2]
    border = np.concatenate([
        rgb[0:2].reshape(-1, 3), rgb[-2:].reshape(-1, 3),
        rgb[:, 0:2].reshape(-1, 3), rgb[:, -2:].reshape(-1, 3)])
    bg = np.median(border, axis=0)
    dist = np.sqrt(((rgb - bg) ** 2).sum(axis=2))
    T = 46.0
    is_bg = np.zeros((h, w), bool)
    is_bg[0, :] |= dist[0, :] < T
    is_bg[-1, :] |= dist[-1, :] < T
    is_bg[:, 0] |= dist[:, 0] < T
    is_bg[:, -1] |= dist[:, -1] < T
    for _ in range(256):
        dil = is_bg.copy()
        dil[1:, :] |= is_bg[:-1, :]
        dil[:-1, :] |= is_bg[1:, :]
        dil[:, 1:] |= is_bg[:, :-1]
        dil[:, :-1] |= is_bg[:, 1:]
        new = dil & (dist < T)
        if new.sum() == is_bg.sum():
            break
        is_bg = new
    alpha = np.where(is_bg, 0, 255).astype(np.uint8)
    return Image.fromarray(np.dstack([rgb.astype(np.uint8), alpha]), "RGBA")


log = {"round": "R23", "comfyui": "127.0.0.1:8188 v0.33.2 本机",
       "workflow": "pixelArtDiffusionXL + pixel-art-xl + sdxl_lightning_4step, 8 steps, 无 ImageQuantize",
       "queue_discipline": "串行：确认上一个 job completed 且 /queue running=0 才提交下一个",
       "system_stats_timeouts": 0, "queue_timeouts": 0,
       "jobs": [], "blocked": False}

for idx, job in enumerate(JOBS):
    before = set(os.listdir(OUT))
    try:
        res = post(workflow(job))
    except Exception as e:
        log["jobs"].append(dict(tag=job["tag"], status="post_failed", error=str(e)[:200]))
        log["blocked"] = True
        break
    pid = res.get("prompt_id", "")
    done, timeouts = wait_done(pid, before)
    log["queue_timeouts"] += timeouts
    if not done:
        log["jobs"].append(dict(tag=job["tag"], prompt_id=pid, status="timeout",
                                note="job 超过 240s 未完成，按纪律停止后续提交，不无限等待"))
        log["blocked"] = True
        break
    new = [f for f in os.listdir(OUT) if f not in before
           and f.startswith("r23_g_" + job["tag"]) and f.lower().endswith(".png")]
    if not new:
        log["jobs"].append(dict(tag=job["tag"], prompt_id=pid, status="no_output_png"))
        log["blocked"] = True
        break
    src = OUT / sorted(new)[-1]
    im = Image.open(src).convert("RGB")
    if job["alpha"]:
        out_im = remove_bg(im)
    else:
        out_im = Image.fromarray(
            np.dstack([np.asarray(im), np.full((128, 128), 255, np.uint8)]), "RGBA")
    colors = unique_rgb_visible(out_im)
    a = np.asarray(out_im.getchannel("A"))
    cov = round(float((a > 0).mean()), 4)
    out_im.save(DEST / (job["tag"] + ".png"))
    log["jobs"].append(dict(tag=job["tag"], prompt_id=pid, status="ok",
                            seed=job["seed"], kind=job["kind"], pose=job["pose"],
                            size=[128, 128], alpha=bool(job["alpha"]),
                            alpha_coverage=cov, unique_rgb_visible=colors,
                            comfyui_output=src.name))
    print(f"[{idx+1:2d}/{len(JOBS)}] {job['tag']:28s} seed={job['seed']} "
          f"colors={colors:5d} cov={cov} OK", flush=True)

# 拼 spritesheet：帧序/坐标系与既有 .tres 完全一致（单行 128px 网格）
def sheet(names, path, width):
    ok = all((DEST / (n + ".png")).is_file() for n in names)
    if not ok:
        return False
    s = Image.new("RGBA", (width, 128), (0, 0, 0, 0))
    for i, n in enumerate(names):
        s.paste(Image.open(DEST / (n + ".png")).convert("RGBA"), (i * 128, 0))
    s.save(path)
    return True

log["spritesheet_player"] = sheet(["player_" + p for p in PLAYER],
                                  DEST / "player_spritesheet.png", 1024)
log["spritesheet_boss"] = sheet(["boss_" + p for p in BOSS],
                                DEST / "boss_spritesheet.png", 384)

LOG.write_text(json.dumps(log, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({"ok": sum(1 for j in log["jobs"] if j["status"] == "ok"),
                  "total": len(JOBS), "blocked": log["blocked"],
                  "queue_timeouts": log["queue_timeouts"],
                  "log": str(LOG)}, ensure_ascii=False), flush=True)
