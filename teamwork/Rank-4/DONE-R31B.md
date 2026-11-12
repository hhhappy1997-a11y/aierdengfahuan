# DONE-R31B.md · R31B 遗留由 R32 合并补齐（补回执配套）

> 补回执 id：`cmd-20261111-141611-511-A4` · AI=4（Rank-4）
> 背景：上一轮 R31B 四条派单因**执行进程通道故障未接单**，本轮 R32 / v0.10.0 派单 `cmd-20261112-074023-416-A4` 中【R31B 遗留补执行】段明确「本轮由你合并补齐并另写一份回执」。
> 结论：**R31B 遗留由 R32 合并补齐**，实际结论以 `teamwork/Rank-4/DONE-R32.md` 为准，本文件只做归并索引，不重复、不谎报。

---

## 1. 合并补齐的三项（对应 R32 任务单 ①②④）

| R31B 遗留 | R32 补齐动作 | 落盘实测 / 真跑证据 |
|---|---|---|
| **特效接入**：`godot/assets/generated/r23/impact_fx.png` 生成后未接进特效层 | R32 ② 按 `r23/import.json` 以**只读加载**方式接入 `godot/scripts/hd2d_fx.gd` 程序化特效层（复用既有 `FXBloom` 分派；不改 `courtyard.tscn` 节点 41 / uv 2/1/1 / 节点名，不改 `presentation.gd`；保留降级层开关，mobile 档零额外开销） | 引擎真跑日志 `[R32][impact_fx] 只读加载成功 png=res://assets/generated/r23/impact_fx.png frames=4 fw=128 cols=4 palette_id=hd2d_index_256_v1`；段 A/B/C 切换日志证明 mobile 段四项全关、全片仅加载 1 次；首帧画面可见暖金冲击环、中帧（mobile 段）无特效 → 档位门控实证；三段门禁 `SCRIPT ERROR=0` |
| **色库**：项目级色库实测仅 32 色，未达 §9.3「≥256 色」 | R32 ① A40 合规清零：两份 `palette_256.json` 程序化零依赖扩充（16 语义色族 × 7 离散明度档 × 2 离散色温档、通道量化 8 步；零随机 / 零渐变 / 零噪点 / 零 dithering），前 32 色冻结保留，单帧 ≤16 色索引口径不变；`import.json` 的 `color_policy` 状态字段同步 | 两处各 `len(colors)=256 unique=256 declared color_count=256`，`IMP8_subset=True`；`IMPORT_SYNC measured=256 meets_ge_256=True` |
| **定稿录屏**：需可回看的 15 秒实机录屏 | R32 ④ 真跑 `capture/v100_final.mp4`（Movie Maker `--write-movie <绝对路径>.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`，录屏前先 `--headless --import` 以包含 Rank-1 本轮 HUD 分区重构；ffmpeg 9.x 用 `-fps_mode passthrough`，未用 `-vsync 0`）；R32 ⑤ 目视回看首/中/尾三帧并按 A41 三判据写结论 | `RUN1_FRAMES=450`（一次跑满，未触发短录重跑）、`MP4_BYTES=1475754`、ffprobe `h264 / 1280×720 / 30fps / nb_frames=450 / duration=15.000000`；`v100_key_1/2/3.png` 首/中/尾三帧；尾帧「胜利 · 已落盘」可读；`SCRIPT ERROR=0` |

---

## 2. 与 A41 的关系（如实登记）

R31 曾自评「HD-2D 全绿达成」，总指挥裁决 **A41** 纠正：全绿判据以 `HD2D-STYLE-ANCHOR-v2.md` 三判据为准，当前仍是 2D `_draw()` / screen-reading shader 近似、地面 2D tile 贴 3D 平面、角色 billboard 像素精灵。R32（含本次 R31B 合并补齐）**如实写「未达全绿」**并列出具体差距，不沿用 R31 自评。详见 `DONE-R32.md` §3 / §4。

---

## 3. 边界

- 本轮只写任务单授权文件；未改 `encounter_director.gd` / `hud.gd` / `presentation.gd` / 场景节点与 uv / 数据表 / 其它 Rank 文件。
- 零付费、零外部依赖、不启 GPU job、未引入外部素材生成服务；默认不刺探（不扫目录、不写只读探针 / 巡检脚本）；不伪造产物、不谎报成功、不自行 git；未删除 `.workbuddy` 目录。
- 补回执写在 `teamwork/command_center/ai/4/outbox/cmd-20261111-141611-511-A4.json`（`teamwork/command_center/`，非工程根 `command_center/`）。

---

## 4. 引用

- 实际交付清单 / 真跑输出原文 / 验收三态 / 未完成项 / 待裁决项：**`teamwork/Rank-4/DONE-R32.md`**
- 本轮回执：`teamwork/command_center/ai/4/outbox/cmd-20261112-074023-416-A4.json`
