#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""R23 破图重试：player_attack_light 首轮（seed=20261109014）生成 4 个重复小人。
换 seed + 强化 single/one-figure 约束重跑，覆盖产物、重建 player_spritesheet，并如实登记重试。
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
TAG = "player_attack_light"
SEED = 20261109914
PLAYER = ["idle", "walk", "run", "roll", "attack_light", "attack_heavy", "hitstun", "death"]

POS = ("pixel art game sprite, full body, front three-quarter view, "
       "bold near-black 1px hard outline, flat cel shading with 3 hard value steps, "
       "saturated warm gold armor trim and deep cobalt blue plate, cyan gem accents, "
       "crisp hard pixel edges, no anti-aliasing, centered, feet on ground line, "
       "HD-2D dark fantasy, readable silhouette, "
       "SINGLE solitary fantasy knight, exactly ONE large figure, quick horizontal sword slash "
       "with arm extended, generous empty space around the character, "
       "solid uniform flat neutral gray background, no gradient, no shadow, no texture")
NEG = ("smooth gradients, anti-aliasing, blurry, 3d render, photorealistic, jpeg artifacts, "
       "watermark, text, signature, extra limbs, gradient background, glow, motion blur, "
       "realistic skin texture, depth of field, frame, border, vignette, "
       "duplicate characters, multiple characters, clones, repeated figures, grid, "
       "sprite sheet, collage, multiple views, crowd, two figures")

WF = {
    "1": {"class_type": "CheckpointLoaderSimple",
          "inputs": {"ckpt_name": "pixelArtDiffusionXL_spriteShaper.safetensors"}},
    "2": {"class_type": "LoraLoader", "inputs": {
        "lora_name": "pixel-art-xl.safetensors", "strength_model": 0.8,
        "strength_clip": 0.8, "model": ["1", 0], "clip": ["1", 1]}},
    "3": {"class_type": "LoraLoader", "inputs": {
        "lora_name": "sdxl_lightning_4step_lora.safetensors", "strength_model": 0.75,
        "strength_clip": 0.75, "model": ["2", 0], "clip": ["2", 1]}},
    "4": {"class_type": "CLIPTextEncode", "inputs": {"text": POS, "clip": ["3", 1]}},
    "5": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["3", 1]}},
    "6": {"class_type": "EmptyLatentImage",
          "inputs": {"width": 512, "height": 512, "batch_size": 1}},
    "7": {"class_type": "KSampler", "inputs": {
        "seed": SEED, "steps": 8, "cfg": 1.8, "sampler_name": "euler",
        "scheduler": "sgm_uniform", "denoise": 1.0, "model": ["3", 0],
        "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["6", 0]}},
    "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["1", 2]}},
    "9": {"class_type": "ImageScale", "inputs": {
        "image": ["8", 0], "upscale_method": "nearest-exact",
        "width": 128, "height": 128, "crop": "disabled"}},
    "10": {"class_type": "SaveImage", "inputs": {
        "images": ["9", 0], "filename_prefix": "r23_retry_" + TAG}},
}


def probe(url, timeout=10):
    try:
        with urllib.request.urlopen(url, timeout=timeout) as r:
            return json.loads(r.read().decode()), False
    except Exception:
        return None, True


def wait_done(pid, timeout=240):
    t0 = time.time()
    tos = 0
    while time.time() - t0 < timeout:
        d, to = probe(BASE + "/history/" + pid)
        if to:
            tos += 1
        if d:
            v = list(d.values())[0]
            if v.get("status", {}).get("completed") or v.get("outputs"):
                q, qto = probe(BASE + "/queue")
                if qto:
                    tos += 1
                    return True, tos
                elif q and not q.get("queue_running"):
                    return True, tos
        time.sleep(3)
    return False, tos


def remove_bg(im):
    rgb = np.asarray(im.convert("RGB")).astype(np.int16)
    h, w = rgb.shape[:2]
    border = np.concatenate([rgb[0:2].reshape(-1, 3), rgb[-2:].reshape(-1, 3),
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
    return Image.fromarray(
        np.dstack([rgb.astype(np.uint8), np.where(is_bg, 0, 255).astype(np.uint8)]), "RGBA")


before = set(os.listdir(OUT))
body = json.dumps({"prompt": WF, "client_id": "rank4-r23-retry"}).encode()
req = urllib.request.Request(BASE + "/prompt", data=body,
                             headers={"Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    pid = json.loads(r.read().decode())["prompt_id"]
done, timeouts = wait_done(pid)
if not done:
    print(json.dumps({"status": "timeout", "tag": TAG, "prompt_id": pid}))
    raise SystemExit(1)

new = [f for f in os.listdir(OUT) if f not in before
       and f.startswith("r23_retry_" + TAG) and f.lower().endswith(".png")]
if not new:
    print(json.dumps({"status": "no_output_png", "tag": TAG, "prompt_id": pid}))
    raise SystemExit(1)
src = OUT / sorted(new)[-1]
out_im = remove_bg(Image.open(src).convert("RGB"))
a = np.asarray(out_im.getchannel("A"))
cov = round(float((a > 0).mean()), 4)
vis = a > 0
colors = int(len(np.unique(np.asarray(out_im.convert("RGB"))[vis].reshape(-1, 3), axis=0)))
out_im.save(DEST / (TAG + ".png"))

# 重建 player_spritesheet.png（帧序与 player_spriteframes.tres 一致）
s = Image.new("RGBA", (1024, 128), (0, 0, 0, 0))
for i, p in enumerate(PLAYER):
    s.paste(Image.open(DEST / ("player_" + p + ".png")).convert("RGBA"), (i * 128, 0))
s.save(DEST / "player_spritesheet.png")

log = json.loads(LOG.read_text(encoding="utf-8"))
for j in log["jobs"]:
    if j.get("tag") == TAG:
        j["retry"] = {
            "reason": "首轮出图目视发现 4 个重复小人（duplicate characters 破图）",
            "original_seed": j["seed"], "original_prompt_id": j.get("prompt_id"),
            "retry_seed": SEED, "retry_prompt_id": pid,
            "retry_output": src.name, "retry_status": "ok",
        }
        j["seed"] = SEED
        j["prompt_id"] = pid
        j["unique_rgb_visible"] = colors
        j["alpha_coverage"] = cov
        j["comfyui_output"] = src.name
        j["visually_rechecked"] = True
log.setdefault("retries", []).append(dict(tag=TAG, original_seed=20261109014,
                                          retry_seed=SEED, prompt_id=pid,
                                          status="ok", timeouts=timeouts))
LOG.write_text(json.dumps(log, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({"status": "ok", "tag": TAG, "seed": SEED,
                  "colors": colors, "cov": cov, "prompt_id": pid,
                  "output": src.name, "timeouts": timeouts}, ensure_ascii=False))
