#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""R23: 从本机 DNF ImagePacks2 提取参考贴片 -> 风格证据联系表 + 风格统计。

合规：DNF 资源版权归 Neople / 腾讯，仅本机开发参考。
raw/ 原始可识别贴片由 .gdignore + .gitignore 双重隔离，不进 Godot pck / 发布包；
contact_sheet.png 为 4x 像素化「风格证据」，不直接分发可识别商业贴片。
"""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

Image.MAX_IMAGE_PIXELS = None

EXE = Path("C:/Users/62668/WorkBuddy/2026-10-31-15-43-21/dfo-extractor.exe")
NPK = Path("D:/WeGameApps/地下城与勇士：创新世纪/ImagePacks2")
REF = Path("F:/Game/aierdengfahuan/teamwork/Rank-4/r23_dnf_reference")
RAW, WORK = REF / "raw", REF / "_work"
for d in (RAW, WORK):
    d.mkdir(parents=True, exist_ok=True)

# ---- 合规隔离 ----
(REF / ".gdignore").write_text("", encoding="utf-8")
(REF / ".gitignore").write_text(
    "# DNF 参考贴片：版权归 Neople / 腾讯，仅本机开发参考\n"
    "# 原始可识别商业贴片禁止入库 / 禁止进入任何发布包\n"
    "raw/\n_work/\n",
    encoding="utf-8",
)

SOURCES = [
    # 人物：鬼剑士时装单层部件（179 帧）。单层部件稀疏，用 bbox 裁紧放大到 128 画布。
    dict(cat="character", name="swordman_ghosthand",
         pack="sprite_character_swordman_equipment_growtype_basics.NPK",
         entry="sprite/character/swordman/equipment/growtype/basics/ghosthand.img",
         frames=[0, 1, 2], fit="bbox"),
    # 怪物：滚石哥布林 25 帧动作序列
    dict(cat="monster", name="abnova_kobolt",
         pack="sprite_monster_abnova_kobolt.NPK",
         entry="sprite/monster/abnova/kobolt/rollingkobolt.img",
         frames=[0, 1, 2]),
    # 地砖/铺地：map 包内正常尺寸的地面 / 石砌贴片
    # （避开 sprite_commonmap_town_*_tile.NPK 的超宽横条：本机提取器不支持该 LINK 变体）
    dict(cat="tile", name="mobgen_floor",
         pack="sprite_map_breakableobject.NPK",
         entry="sprite/map/breakableobject/mobgen_floor.img", frames=[0]),
    dict(cat="tile", name="stonetomb",
         pack="sprite_map_breakableobject.NPK",
         entry="sprite/map/breakableobject/stonetomb.img", frames=[0, 1]),
    dict(cat="tile", name="jip",
         pack="sprite_map_breakableobject.NPK",
         entry="sprite/map/breakableobject/jip.img", frames=[0]),
    dict(cat="tile", name="rollingstonepiece",
         pack="sprite_map_breakableobject.NPK",
         entry="sprite/map/breakableobject/rollingstonepiece.img", frames=[0]),
    # 特效/光感：正常尺寸的 DNF 光晕 / 粒子贴片
    # （避开 sprite_character_*_effect_* 与 commoneffect2_ground 的超宽横条）
    dict(cat="effect", name="fountainwaterglow",
         pack="sprite_map_act2_fountain.NPK",
         entry="sprite/map/act2/fountain/fountainwaterglow.img", frames=[0, 1]),
    dict(cat="effect", name="fountainparticles",
         pack="sprite_map_act2_fountain.NPK",
         entry="sprite/map/act2/fountain/fountainparticles.img", frames=[0, 1]),
    dict(cat="effect", name="ob_light",
         pack="sprite_map_breakableobject.NPK",
         entry="sprite/map/breakableobject/chn_event_doll_ob_light.img", frames=[0]),
    dict(cat="effect", name="timespiral_particle",
         pack="sprite_map_breakableobject.NPK",
         entry="sprite/map/breakableobject/timespiral_particle.img", frames=[0, 1]),
    # 场景道具：已知可稳定提取
    dict(cat="prop", name="treasurebox",
         pack="sprite_map_breakableobject.NPK",
         entry="sprite/map/breakableobject/treasurebox.img", frames=[0]),
    dict(cat="prop", name="barrel",
         pack="sprite_map_breakableobject.NPK",
         entry="sprite/map/breakableobject/barrel.img", frames=[0]),
    dict(cat="prop", name="fountain",
         pack="sprite_map_act2_fountain.NPK",
         entry="sprite/map/act2/fountain/fountain2.img", frames=[0]),
]


def preview(pack: str, entry: str, frame: int):
    out = WORK / "preview.png"
    if out.exists():
        out.unlink()
    r = subprocess.run(
        [str(EXE), "preview", str(NPK / pack), "--entry", entry, "--frame", str(frame)],
        cwd=str(WORK), capture_output=True, text=True,
        encoding="utf-8", errors="replace", timeout=120,
    )
    if r.returncode != 0 or not out.exists():
        return None, (r.stderr or r.stdout or "")[:160]
    return Image.open(out).convert("RGBA"), ""


def stats(im: Image.Image) -> dict:
    a = np.asarray(im.getchannel("A"))
    vis = a > 16
    cov = float(vis.mean())
    rgb = np.asarray(im.convert("RGB"))[vis].reshape(-1, 3)
    if rgb.size == 0:
        return {}
    uniq, cnt = np.unique(rgb, axis=0, return_counts=True)
    order = np.argsort(cnt)[::-1]
    top = [{"rgb": [int(x) for x in uniq[i]],
            "share": round(float(cnt[i] / rgb.shape[0]), 4)} for i in order[:8]]
    lum = 0.299 * rgb[:, 0] + 0.587 * rgb[:, 1] + 0.114 * rgb[:, 2]
    g = np.asarray(im.convert("RGB")).astype(np.int16)
    dx = np.abs(np.diff(g, axis=1)).mean(axis=2)
    dy = np.abs(np.diff(g, axis=0)).mean(axis=2)
    ed = np.concatenate([dx[vis[:, 1:]].ravel(), dy[vis[1:, :]].ravel()])
    sat = rgb.max(axis=1).astype(float) - rgb.min(axis=1).astype(float)
    return {
        "size": list(im.size),
        "alpha_coverage": round(cov, 4),
        "unique_rgb_visible": int(len(uniq)),
        "top_colors": top,
        "luma_mean": round(float(lum.mean()), 1),
        "luma_p90": round(float(np.percentile(lum, 90)), 1),
        "edge_mae": round(float(ed.mean()), 1) if ed.size else 0.0,
        "edge_strong_ratio": round(float((ed > 30).mean()), 4) if ed.size else 0.0,
        "sat_mean": round(float(sat.mean()), 1),
    }


items: list[dict] = []
for s in SOURCES:
    got = 0
    for fi in s["frames"]:
        im, err = preview(s["pack"], s["entry"], fi)
        if im is None:
            items.append(dict(cat=s["cat"], name=s["name"], frame=fi,
                              status="preview_failed", err=err))
            continue
        w, h = im.size
        cov = float((np.asarray(im.getchannel("A")) > 16).mean())
        if cov < 0.005 or min(w, h) < 8:
            items.append(dict(cat=s["cat"], name=s["name"], frame=fi,
                              status="near_empty", src_size=[w, h],
                              coverage=round(cov, 5)))
            continue
        if s.get("fit") == "bbox":
            bb = im.getchannel("A").getbbox()
            if bb:
                im = im.crop(bb)
        im2 = im.copy()
        im2.thumbnail((128, 128), Image.NEAREST)
        cell = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        cell.paste(im2, ((128 - im2.width) // 2, (128 - im2.height) // 2), im2)
        stem = f"{s['cat']}__{s['name']}__f{fi:02d}"
        cell.save(RAW / (stem + ".png"))
        st = stats(cell)
        items.append(dict(cat=s["cat"], name=s["name"], frame=fi, status="ok",
                          pack=s["pack"], entry=s["entry"],
                          raw="raw/" + stem + ".png", **st))
        got += 1
    print(f"[{s['cat']:9s}] {s['name']:26s} ok={got}/{len(s['frames'])}", flush=True)

# ---- 联系表：4x 像素化风格证据（不直接分发可识别商业贴片）----
ok = [i for i in items if i["status"] == "ok"]
font = ImageFont.load_default()
CW, CH, COLS = 148, 176, 4
rows = max(1, (len(ok) + COLS - 1) // COLS)
sheet = Image.new("RGB", (COLS * CW, rows * CH), (14, 18, 30))
d = ImageDraw.Draw(sheet)
for idx, it in enumerate(ok):
    x, y = (idx % COLS) * CW, (idx // COLS) * CH
    im = Image.open(RAW / Path(it["raw"]).name).convert("RGBA")
    small = im.resize((32, 32), Image.NEAREST).resize((128, 128), Image.NEAREST)
    bg = Image.new("RGBA", (128, 128), (20, 26, 42, 255))
    bg.alpha_composite(small)
    sheet.paste(bg.convert("RGB"), (x + 10, y + 6))
    d.text((x + 10, y + 138), f"{it['cat']}/{it['name']}"[:22],
           fill=(235, 210, 150), font=font)
    d.text((x + 10, y + 150),
           f"f{it['frame']} colors={it['unique_rgb_visible']} cov={it['alpha_coverage']}",
           fill=(150, 175, 205), font=font)
    for k, c in enumerate(it["top_colors"][:8]):
        d.rectangle([x + 10 + k * 14, y + 162, x + 10 + k * 14 + 12, y + 170],
                    fill=tuple(c["rgb"]))
sheet.save(REF / "contact_sheet.png")

manifest = {
    "schema_version": 1,
    "round": "R23",
    "purpose": "DNF 风格 / 构图参考（仅本机开发参考，非发布素材）",
    "source_root": str(NPK),
    "npk_total": 16691,
    "extractor": str(EXE),
    "extractor_commands": ["preview <NPK> --entry <img> --frame <n>"],
    "provenance": "DNF 客户端 ImagePacks2 原始贴片，版权归 Neople / 腾讯，仅本机本地开发参考",
    "published_in_pck": False,
    "compliance": {
        "gdignore": True,
        "raw_gitignored": True,
        "copied_into_godot_assets": False,
        "in_pck_exe_apk_release": False,
        "contact_sheet": "4x 像素化风格证据，不分发可识别商业贴片",
    },
    "items": items,
    "ok_count": len(ok),
}
(REF / "manifest.json").write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
(REF / "style_stats.json").write_text(
    json.dumps({"ok": ok, "categories": sorted({i["cat"] for i in ok})},
               ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({"sources": len(SOURCES), "ok": len(ok),
                  "sheet": str(REF / "contact_sheet.png"),
                  "manifest": str(REF / "manifest.json")}, ensure_ascii=False))
