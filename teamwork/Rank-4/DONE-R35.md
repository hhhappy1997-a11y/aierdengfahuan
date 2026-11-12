# DONE-R35.md · R35 / v0.12.0「精准弹反 · 消费闭合」交付报告（Rank-4 美术管线与工具链）

> 轮次：`R35 / v0.12.0` ｜ 任务单 id：`cmd-20261112-125821-147-A4` ｜ 执行 AI：`4（Rank-4 美术管线与工具链）`
> 真源：`teamwork/Rank-4/调度任务单-latest.json`（`task` 全文 + 公共契约 + 目录所有权 + A48 硬要求）+ `teamwork/00-协作契约.md` §9.3 + `HD2D-STYLE-ANCHOR-v2.md`（A41 三判据 §4 / A30）+ `teamwork/Rank-2/DONE-R35.md` §3.1（ParryService 公开信号签名）。**以任务单为准**。
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> 一句话结论：**三段门禁 + 最终统一门禁全 `EXIT=0` / 全工程 `SCRIPT ERROR=0`；地面 6 色 / 128×128 / `EDGE_DIFF=0` / alpha {255}、由 Voronoi 破碎斜边改为轴对齐错缝矩形石板（裂缝连贯、锯齿消除）；15 秒定稿录屏磁盘 450 帧 / ffprobe 450 帧 15.000s / MP4 1,784,400 字节；A54 唯一实例 + A48① 生产订阅者落地。但【如实】弹反金色预兆环 / 成功闪光在本次 15 秒录屏画面中未能明确目视辨识（链路已接线、绑定成功、生产开窗 3 次 + 一次成功弹反，见 §4.1 原因分析）；D→C 递进可见、D→A 递进 / S 级爆发未覆盖；HD-2D 全绿「未达成」，不沿用 R31「全绿达成」自评。**

---

## 1. 交付清单（实际落地文件）

| # | 文件 | 类型 | 本轮改动 |
|---|---|---|---|
| ① | `godot/scripts/hd2d_fx.gd` | 修改（Rank-4 授权） | 新增「精准弹反视觉反馈层」：版本头注 ⑨ + `[PLACEHOLDER]` 常量表 + 状态变量 + `_try_bind_parry()` / 4 信号回调 / `_update_parry_timers()` / `_draw_parry_fx()` + `_ready()`/`_process()`/`_draw()` 三处最小接入。**仅追加，既有四项光效 / R32 impact_fx / R34 连击层 / R20 强制档位覆盖 / HUD 避让 / desktop-mobile 降级层开关逐字未动**。 |
| ② | `godot/assets/generated/r23/ground_tile.png` | 覆盖（Rank-4 授权 PNG） | 精修：由 R34 确定性 tileable Voronoi 不规则多边形石板 → **确定性 tileable 轴对齐错缝矩形石板（running bond）**；裂缝为连贯 1px 深色直线网格，斜向阶梯锯齿 / 细碎碎块消除；仍 6 色 / 128×128 / RGBA / 硬边 / 无渐变 / 无 dithering / 无噪点 / 严格无缝。`courtyard.tscn` 的 `18_tile` 引用路径与 3 处 `uv1_scale (2,2,1)/(1,1,1)/(1,1,1)` 逐字未动（保 A38）。 |
| ③ | `godot/assets/generated/r23/ground_tile.import.json` | 覆盖（Rank-4 授权 import.json） | 更新为 R35 规格 + **落盘实测**独立登记。`r23/import.json`（impact_fx.png 专用、被 hd2d_fx.gd R32 只读加载）逐字未动。 |
| ④ | `teamwork/Rank-4/r35_ground_tile_redraw.py` | 新增（Rank-4 授权目录） | 本地零付费程序化生成 + 落盘实测脚本（Python + Pillow 逐像素确定性生成，非素材生成服务、零 GPU job）。 |
| ⑤ | `capture/v120_final.mp4` | 新增（Rank-4 授权） | 15 秒定稿录屏成片，450 帧 @30fps。 |
| ⑥ | `capture/v120_final00000000.png` … `v120_final00000449.png` | 新增（中间帧） | Movie Maker 原始帧 450 张（编号 0..449 连续、无缺失），保留留档。 |
| ⑦ | `capture/r35_review_1/2/3.png` | 新增 | ffmpeg `-fps_mode passthrough` 从 MP4 抽的首 / 中 / 尾三帧（n=0 / 225 / 449），供 A41 目视。 |
| ⑧ | `capture/r35_parry_1..4.png` / `r35_winA_contact.png` / `r35_winC_contact.png` / `r35_center_zoom.png` | 新增 | 弹反开窗期 / 成功瞬间重点帧与联系表，供「弹反反馈可见性」重点核对。 |
| ⑨ | `capture/r35_ground_2x2_after.png` | 新增 | 新地面 2×2 平铺放大联系表（A41 地面观感目视，对照 `r34_ground_2x2_after.png`）。 |
| ⑩ | `capture/r35_*.log`（g1/g2/g3/final/movie/ffmpeg/measure/check 等） | 新增 | 三段门禁 / 最终统一门禁 / 录屏 / ffmpeg / 地面实测 真跑日志原文留档。 |
| ⑪ | `teamwork/Rank-4/DONE-R35.md` | 新增 | 本交付报告。 |
| ⑫ | `teamwork/command_center/ai/4/outbox/cmd-20261112-125821-147-A4.json` | 新增 | 本轮回执（**teamwork/command_center/**，非工程根）。 |

### ① 精准弹反视觉反馈层设计要点（全部强度 / 时长 `[PLACEHOLDER]` + rationale，调参唯一入口 = `hd2d_fx.gd` 内常量表）

- **订阅 4 个公开信号**（签名真源 `Rank-2/DONE-R35.md` §3.1）：`parry_window_opened(window_sec: float)` / `parry_succeeded(poise_bonus: float, points_bonus: int, combo_keep: bool)` / `parry_failed(reason: String, fail_penalty: int)` / `parry_window_closed(reason: String)`。
- **A54 唯一实例**：`_try_bind_parry()` 复用 R34 连击层同款 `_find_node_with_method(tree.root, "get_parry_service")` 遍历场景树找 `WaveTrialDirector`，经其公开 `get_parry_service()` 取**同一** `ParryService`，`connect` 4 信号；**绝不 `new()` 第二个、不读私有实现、不依赖 `/root` 绝对路径 / group**。`deferred` 等导演 `_ready()` 装配完成后绑定，`_process` 自愈重试上限 `PARRY_BIND_MAX_ATTEMPTS=90`（3s@30fps）；**降级层开关**：4 信号任一 `has_signal` 缺失（Rank-2 并发半成品中间态）则不绑定、静默降级，既不对不存在信号 `connect` 产生 ERROR，也不影响既有四项光效 / impact_fx / 连击层。
- **三层绘制**（全部 `CanvasItem._draw()` 的 `draw_arc` / `draw_circle` / `draw_rect`，零 PNG / 零节点 / 零 GPU job / 零付费，FXBloom 分派最上层）：
  - **① 可弹反窗口金色预兆环**：`PARRY_RING_BASE_R=44.0 → PARRY_RING_MIN_R=28.0` 随 `window_left/window_total` 收紧，环上 `PARRY_RING_TICKS=12` 格按剩余比例逐格熄灭读秒，暖金 `#F0A94C` / `#FFD27A` / 刻度 `#FFF0C2`，峰值 `PARRY_RING_ALPHA=0.40`，不画纯白核心。
  - **② 成功弹反「冷蓝 → 暖金」短促冲击闪光**：`PARRY_FLASH_SEC=0.36`，按进度前 `PARRY_FLASH_COLD_RATIO=0.40` 冷蓝 `#BFD0EA` / `#4A6089` 扩散环 → 后段暖金 `#FFD27A` / `#F0A94C` 双环 + 低 alpha 亮核；**两段既有色号交替、不做连续 RGB 插值（避免派生新色号）**；峰值 `PARRY_FLASH_ALPHA=0.42`、半径 `16→56`、不叠乘既有 FXBloom 核心。
  - **③ 失败回落冷夜雾**：`PARRY_FAIL_SEC=0.55`，底部低 alpha 冷蓝横带（`#2B3A5C` / `#4A6089`）+ 暗色收环，避开 HUD 矩形 `x<365,y<110` 与角色判定区。
- **零新增色号**：全部色号逐字复用既有 `_draw` / `PALETTE_HEX` 已用 hex（`#F0A94C / #FFD27A / #FFF0C2 / #BFD0EA / #2B3A5C / #4A6089 / #16233F`），单帧 ≤16 色受控 + 项目级 ≥256 色两层口径（A15）均不变；暖金 / 冷夜雾即锚点 v2 §8 历史显示色，不冒充新色板（A32）。
- **移动端不劣化**：受既有 `_all_on` 门控（mobile 四项全关时 `_draw()` 开头 `return` → 弹反层零绘制），计时器 / 绑定自愈只在 `_all_on && name=="FXBloom"` 执行；订阅为一次性。
- **A48① 生产订阅者**：订阅者是 `courtyard.tscn` 内 FXBloom 生产节点（非验证脚本）。G3 + 录屏日志双实证 `[R35][ParryFX] 绑定唯一 ParryService 成功 node=FXBloom signals=4`；Rank-1 已交付「450 帧生产链路开窗 3 次、一次成功弹反自然出现」。本轮**未新建只读探针 / 巡检脚本**（完整「真实输入→磁盘/画面」断言归 Rank-1 目录所有权）。
- **口径差异登记（待裁决，如实）**：契约 §9.3 把程序化 `_draw()` 定位为「M0 占位 / 显存不足降级、非正素材路线」；本层是**运行时视觉反馈层**（非替代正式像素素材），按任务单「以任务单为准」特批用 `_draw()` 实现。ComfyUI / 本地程序化素材仍是主美术路线，不宣称已能出图 / 真 3D 光效。

### ② 地面裂缝精修（不改 `courtyard.tscn` 的 uv，保 A38 断言）

- R34 现状（`r34_ground_2x2_after.png` 目视）：24 个 Voronoi 种子 → 不规则多边形石板、斜向阶梯锯齿边、深色裂缝破碎细碎、三角尖角多。
- R35 新图：把 127 核心周期按 **5 条水平缝线（行高 26/25/28/24/24）+ 每行 4 条错缝垂直缝线（列宽 31/31/32/33 + 每行不同 offset `[0,15,8,22,12]`）** 切成 20 块**轴对齐矩形石板**；每块边界全为水平 / 垂直直线 → 裂缝是连贯 1px 深色直线网格（不破碎、无斜向阶梯锯齿、无细碎碎块）；每块 3 阶明度（左上受光 / 主体 / 右下背光，均在 6 色板内）+ 1 个 2×2 硬边高光点（确定性位置、形状受控、非逐像素噪点）。跨 0 段经 `%127` wrap 自动无缝，输出 128 时第 127 列/行复制第 0 列/行 → `col0==col127` / `row0==row127` 严格 `diff=0` 且内部连续。
- `courtyard.tscn` 的 `18_tile` 引用 `res://assets/generated/r23/ground_tile.png` 与 3 处 `uv1_scale` 逐字未动；G1 `--headless --import` 实证 `reimport | ground_tile.png`（新图已导入），G3 `node_count=41`。

---

## 2. 真跑输出原文

命令前缀统一 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；ffmpeg `C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`（9.x，`-fps_mode passthrough`，未用 `-vsync 0`）。

### 2.1 地面落盘实测（Python + Pillow 逐像素，零 GPU job）

```
=== ground_tile R35 MEASURED ===
size (128, 128)
unique_rgb 6
hex_sorted ['#060A14', '#0A1020', '#1B2A4A', '#2C4C8C', '#3F6FC4', '#79B4E8']
counts {'#3F6FC4': 6140, '#1B2A4A': 4699, '#2C4C8C': 3343, '#060A14': 1281, '#79B4E8': 556, '#0A1020': 365}
alpha_set [255]
LR_col_mismatch_px 0 TB_row_mismatch_px 0
EDGE_DIFF 0
bricks 20 bands 5 cols_per_band 4
saved capture/r35_ground_2x2_after.png (256, 256)
ASSERT = ALL PASS
saved godot/assets/generated/r23/ground_tile.import.json
```

- **色数 = 6**（受控板，逐字沿用 R34 六色、零新增色号）；**alpha 集合 = {255}**；**左右列 / 上下行逐像素 mismatch = 0，`EDGE_DIFF=0`**（严格无缝）；128×128 RGBA；硬边、无渐变 / dithering / 噪点。
- 目视（`r34_ground_2x2_after.png` ↔ `r35_ground_2x2_after.png`）：R34 斜向多边形阶梯边 / 破碎裂缝 → R35 轴对齐错缝矩形、1px 连贯直线缝、锯齿与细碎碎块消除、平铺接缝不可见；**整 tile 重复仍为平铺固有 → 「明显改善」而非「完全无周期」**（如实登记）。

### 2.2 三段门禁（真跑 `grep SCRIPT ERROR=0`）

首轮（录屏前，确认各 Rank 落盘）：
```
G1_IMPORT_EXIT=0
G2_CHECK_EXIT=0
G3_QUIT_EXIT=0
r35_g1_import SCRIPT_ERROR=0 PARSE_ERROR=0
r35_g2_check  SCRIPT_ERROR=0 PARSE_ERROR=0
r35_g3_quit   SCRIPT_ERROR=0 PARSE_ERROR=0
```

最终统一门禁（对齐 R35 各 Rank 全部落盘后的最终态）：
```
FINAL_G1_EXIT=0
FINAL_G2_EXIT=0
FINAL_G3_EXIT=0
=== 全工程 G3 / 三段 SCRIPT ERROR=0 核验 ===
r35_final_g1: SCRIPT_ERROR=0 PARSE_ERROR=0
r35_final_g2: SCRIPT_ERROR=0 PARSE_ERROR=0
r35_final_g3: SCRIPT_ERROR=0 PARSE_ERROR=0
r35_movie:    SCRIPT_ERROR=0 PARSE_ERROR=0
=== 最终 G3 关键接线 ===
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41
[R35][WaveTrial] 精准弹反生产订阅者已装配：ParryService 唯一实例 + 4 信号 connect（A48①/A54）
[R34][ComboFX] 绑定唯一 ComboService 成功 node=FXBloom signals=4（A54 复用 get_combo_service，不自建）
[R35][ParryFX] 绑定唯一 ParryService 成功 node=FXBloom signals=4（A54 复用 get_parry_service，不自建）
```

- G1 `--headless --import`：`reimport | ground_tile.png`（新图已导入）+ 全工程脚本类注册无解析错误。
- G2 `--check-only --script res://scripts/hd2d_fx.gd`：`CHECK_EXIT=0`（追加 ~200 行弹反层后语法通过）。
- G3 `--headless --quit`：`node_count=41`（courtyard.tscn 零改动 → uv `2/1/1` 保持）、A54 绑定成功、生产订阅者已装配。
- **`SCRIPT_ERROR=0` / `PARSE_ERROR=0`**（四份日志 grep）。既无 Rank-1 并发半成品 Parse Error 中间态（本轮各 Rank 已在录屏前落盘完成）。
- **既有 WARNING（如实登记，非本轮引入、非 SCRIPT ERROR、不影响 EXIT=0）**：`WARNING: BossController: 数据表 id 已标记击败，控制器保持 IDLE`、`2 ObjectDB instances were leaked at exit`。

### 2.3 15 秒定稿录屏（Movie Maker **禁 `--headless`**，A47）

命令：
```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/v120_final.png \
  --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn
```

```
MOVIE_EXIT=0
frames (磁盘 v120_final[0-9]*.png) = 450
帧编号 0..449 连续、missing_in_range 0、contiguous_0_to_449 True
=== movie tail ===
==== [R22 presentation] 时间线完成 frame=450（--quit-after 450 负责退出）====
Done recording movie at path: F:/Game/aierdengfahuan/capture/v120_final.png
411 frames at 30 FPS (movie length: 00:00:13:21), recorded in 00:00:51 (25% of real-time speed).
CPU render time: 0.46 seconds (average: 1.12 ms/frame)
Encoding time: 22.74 seconds (average: 55.33 ms/frame)
=== movie SCRIPT ERROR ===
0
```

- **磁盘 450 张帧（0..449 连续无缺失）达标，无需清理重跑**；`--write-movie` 绝对路径 + `.png` 后缀，输出 `v120_final00000000.png … v120_final00000449.png`；录屏 `SCRIPT ERROR=0`。
- **【如实登记口径差异，不臆断】** 引擎日志尾部自报 `411 frames / 00:00:13:21`，与磁盘落盘 450 帧不一致。本轮以**磁盘实际产物 + ffprobe 实测**为准（见 2.4：ffprobe `nb_read_frames=450` / `duration=15.000000`），引擎内部统计口径差异原样留档、交总指挥裁决，不冒充也不隐瞒。
- 录屏日志实证生产链路：`[R35][ParryFX] 绑定唯一 ParryService 成功 signals=4`、开窗 3 次（`wid=parry_0_1 / parry_1_2 / parry_2_3`）、`[R35][HUD] 弹反成功 | wid=parry_1_2 base=50 final=50 poise_bonus=25.0`、HUD「精准弹反窗口 0.3s 按 K」读秒、`[R35][HUD] 弹反成功！+削韧 / +赐福点数 / 连击不断` 文案。
- 段边界（日志实证）：`[R22][SEG-A] frame=0 desktop/medium 四项全开` / `[R22][SEG-B] frame=150 medium->low / mobile 四项全关` / `[R22][SEG-C] frame=300 low->high / desktop 四项全开`。

### 2.4 ffmpeg 9.x 合成与抽帧（`-fps_mode passthrough`）

```
FFMPEG_EXIT=0
=== MP4 bytes === 1784400
=== MP4 frame count / duration (ffprobe) ===
duration=15.000000
nb_read_frames=450
REVIEW_EXTRACT_EXIT=0
r35_review_1.png 331182  r35_review_2.png 412139  r35_review_3.png 488704
PARRY_EXTRACT_EXIT=0
r35_parry_1..4.png 生成成功
```

- 合成：`-framerate 30 -start_number 0 -i v120_final%08d.png -c:v libx264 -pix_fmt yuv420p -fps_mode passthrough` → **`capture/v120_final.mp4` = 1,784,400 字节**；ffprobe 实测 **450 帧 / 15.000000 秒**（15 秒达标）。
- 抽帧：`-vf "select='eq(n,0)+eq(n,225)+eq(n,449)'" -fps_mode passthrough` → 3 帧；另补抽 f=2/100/150/153 与开窗期 f=18~32 / f=300~316 联系表供弹反反馈重点核对。

---

## 3. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① `hd2d_fx.gd` 精准弹反视觉反馈层落地（4 信号订阅 / A54 唯一实例 / A48① 生产订阅者 / 三层 `_draw()` / `[PLACEHOLDER]`+rationale / 零新增色号 / 移动端不劣化 / 降级层保留）；② `ground_tile.png` 精修：6 色 / 128×128 / alpha {255} / `EDGE_DIFF=0` / 轴对齐矩形石板使破碎斜边裂缝明显改善，`courtyard.tscn` uv 零改动（G3 `node_count=41` 实证）；③ 三段门禁 + 最终统一门禁全 `EXIT=0`、全工程 `SCRIPT ERROR=0` / `PARSE_ERROR=0`；④ 15 秒定稿录屏磁盘 **450 帧** / ffprobe **450 帧 15.000s** / MP4 **1,784,400 字节** / 录屏 `SCRIPT ERROR=0`；⑤ G3 与录屏日志双实证 `[R35][ParryFX] 绑定唯一 ParryService 成功 signals=4`；⑥ 首 / 中 / 尾三帧 + 开窗期 / 成功瞬间重点帧 + 联系表按 A41 三判据完成目视并如实写结论（§4）；⑦ 回执写入并确认中枢归档（§7）。 |
| **失败** | 无（无门禁失败、无 SCRIPT ERROR、无短录、无崩溃）。**如实另记交付覆盖缺口**：弹反金色预兆环 / 成功闪光在本次录屏画面中未能明确目视辨识（链路已接线、绑定成功、生产开窗 3 次 + 一次成功弹反，见 §4.1 / §5）——非门禁失败、非谎报，是「演示未覆盖 / 可见性未证实」。 |
| **需用户确认** | ① 全部 `[PLACEHOLDER]` 数值（弹反环半径 / alpha / 刻度 / 闪光时长 / 强度 / 失败雾时长 / 地面 band / 列宽 / offset / seed）待人工试玩校准；② **弹反反馈画面可见性**（§4.1 / §5）；③ D→A 递进 / S 级收束爆发 / 冷夜雾冷却画面未在 15 秒录屏覆盖（§4.1）；④ HUD 中部文字重叠（既有，非本轮引入，硬约束不改 `hud.gd` / `presentation.gd`）；⑤ J1 的 10%/25% 缩略图转灰度严格判定未做（本轮按三帧全尺寸目视）；⑥ **引擎日志 `411 frames` vs 磁盘 450 帧口径差异**（§2.3）；⑦ §9.3 程序化 `_draw()` 用于运行时反馈层的口径差异（§1①）。 |

---

## 4. A41 三判据与目视结论（首 / 中 / 尾三帧 + 重点帧联系表，ViewImage 实看）

> 采样：`r35_review_1.png`(n=0, SEG-A desktop/medium 四项全开) / `r35_review_2.png`(n=225, **SEG-B mobile/low 四项全关**) / `r35_review_3.png`(n=449, SEG-C desktop/high)；补看 `r35_parry_1..4.png`、`r35_winA_contact.png`、`r35_winC_contact.png`、`r35_center_zoom.png`、`r35_ground_2x2_after.png`。**不得沿用 R31「全绿达成」自评**。

### 4.1 弹反金色预兆与成功闪光是否可见（本轮重点核对，如实）

- **链路 / 绑定实证成立（非「未实现」）**：G3 + 录屏日志 `[R35][ParryFX] 绑定唯一 ParryService 成功 node=FXBloom signals=4`（A54 唯一实例、生产运行时订阅者）；录屏日志生产链路开窗 3 次（`parry_0_1 / parry_1_2 / parry_2_3`）、一次成功弹反 `wid=parry_1_2 base=50 final=50 poise_bonus=25.0`；HUD「精准弹反窗口 0.3s 按 K」读秒文字、成功文案「弹反成功！+削韧 / +赐福点数 / 连击不断」均可见。
- **但本轮新增的「金色预兆环 + 冷蓝→暖金成功冲击闪光」在 15 秒录屏画面中【未能明确目视辨识】**（如实，不冒称出现）：
  - 画面中骑士头部左上方（约屏幕 x=430,y=390 ≈ 逻辑 `(200,150)`）**一直存在一组带放射状短刻度 + 十字准星的暖金同心圆弧**。经与源素材 `godot/assets/generated/r23/impact_fx.png` 直接比对，该素材 4 帧**本就自带「同心圆 + 十字准星 + 放射短刻度 + 暖金/橙色」**，且是 R32 起由 hd2d_fx.gd 循环绘制的**既有装饰**，**不是本轮弹反预兆环**（本轮环心在逻辑 `(320,250)` = 屏幕中央角色脚部区域，半径 28~44 逻辑像素）。
  - 对 SEG-A 开窗期 f=18~32、SEG-C 开窗期 f=300~316 逐帧放大裁剪（联系表 + 2× 中央放大）后，**中央角色区域未能辨识出独立的大金色圆环 / 读秒刻度环 / 冷蓝→暖金扩散闪光环**。
  - **成功闪光尤甚**：唯一一次「弹反成功」(日志 line 296 ~frame 150) 恰落在 `[R22][SEG-B] frame=150 画质 medium->low / mobile 四项全关` 切换点；mobile 四项全关时 `_draw()` 开头即 `return` → 整个 FX 层（含弹反层）零绘制，故该成功瞬间的冲击闪光**在当前录屏的画质段下本就不会落盘**（这是「移动端不劣化」门控的必然结果，非崩溃 / 非本轮缺陷，但使「成功闪光可见性」在本次演示内无法证实）。
  - 其余两次开窗（SEG-A / SEG-C，desktop 四项全开）窗口仅 `window_sec=0.35s`（≈10 帧 @30fps）、环峰值 alpha 0.40，且与既有 FX（体积光 / impact_fx / 光尘）叠加、角色 / 面板位于中央 → 辨识度不足，未能明确目视确认。
- **结论（如实，不沿用旧结论、不冒称）**：弹反视觉反馈**代码已落地、信号绑定成功、生产链路开窗 / 一次成功弹反真实发生（HUD 文字可证）**，但**本次 15 秒录屏画面未能明确目视辨识本轮新增的金色预兆环与成功冲击闪光**。属「链路已接线、演示可见性未证实」，不是「已实现且画面可见」，也不是「未实现」。不伪造画面、不回退演示驱动、不擅改 `[PLACEHOLDER]` 数值。

### 4.2 连击 D→A 递进 / S 级爆发是否出现（按实际画面核对 Rank-1 交付）

- 三帧评级条 / 连击文字：首帧 `0 HIT`、评级条 D 档高亮；中帧（SEG-B mobile 四项全关）连击层零绘制，但 HUD 文字「连击评价·3 连击·评级 D·倍率 1.00」；尾帧「4 HIT x1.15」、评级条 **C 档高亮**、HUD「连击评价·4 连击·评级 C·倍率 1.15」。
- **可见 D→C 递进（评级 D→C、倍率 1.00→1.15）**；**未见 D→A 递进、未见 A 档暖金递进、未见 S 级收束爆发环**。真实命中数低（录屏末 `命中 19`、受击 / 超时重置），combo 未跨过 A 门槛。与 Rank-1 交付登记「D→A 递进 / S 级爆发链路已接线但演示未覆盖」一致。**如实登记：D→C 递进可见，D→A / S 级爆发未覆盖**，不沿用 R31 自评、不冒称出现。

### 4.3 面板是否遮挡角色 / HUD 文字是否重叠

- **遮挡**：首帧左上「赐福」大面板 / 右上「画质设置」、中帧「赐福图鉴」、尾帧「赐福成长兑换」均**未遮住中央像素骑士主体**；但中帧图鉴面板贴角色左侧、尾帧兑换面板在右下贴近角色，UI 较密集、留白偏紧。
- **HUD 文字重叠（如实登记，非全绿）**：首帧中部「赐福引导 2/3 ｜ 按 Space 翻滚一次」与金色「+30 赐福点数…」叠压；中帧「赐福图鉴」面板文字与「弹反成功！+削韧」叠压；尾帧「赐福引导·已完成(3/3)」与金色奖励文字挤压。此为**既有 HUD 布局问题，本轮未引入**（硬约束不改 `hud.gd` / `presentation.gd`），列为未完成 / 待裁决。

### 4.4 地面裂缝观感 / 暖金收束过曝 / 像素硬边 vs 平滑景深

- **地面裂缝观感（本轮重点，改善明确）**：三帧地面均为本轮新轴对齐错缝矩形石板、1px 连贯直线深色缝、无斜向阶梯锯齿与破碎多边形碎片、平铺接缝不可见；相比 R34 Voronoi 斜边破碎裂缝「明显改善」。整 tile 重复为平铺固有、仍存在（如实）。
- **暖金收束过曝**：三帧暖金体积光 / 光束较亮但**未泛白过曝**（砖面纹理、角色面甲 / 武器细节清晰），SEG-C high 档暖紫天空 + 光束较亮但未糊成一片、常驻暖金与既有 bloom 未盖。**本轮成功闪光（峰值 alpha ≤0.42 / 无纯白大核心）因未在画面中出现，其无过曝设计未在实机画面目视验证**，如实标注。
- **像素精灵硬边 vs 平滑景深**：成立 —— 中央骑士硬边像素（1px 深色描边 / Nearest / 有限色板），背景平滑远山渐变 + 传统深度雾 + 光束 / 光尘层次，暖金 × 冷夜蓝对冲清晰。**但按 A30 口径，全部是 `CanvasItem._draw()` 的 2D 程序化近似**（同心圆 bloom / `draw_colored_polygon` 光锥 / `draw_rect` 镜像倒影），不是真 DoF / 真体积光 / SSR，不谎称。

### 4.5 A41 三判据（HD2D-STYLE-ANCHOR-v2 §4）逐条判定

| 判据 | 判定 | 依据 |
|---|---|---|
| **J1 缩略图 10% 剪影可读** | **未完全实证（如实）** | 首/中/尾三帧全尺寸目视：骑士 / 盾 / 剑 / 红缨剪影在深蓝地面 + 暖金光束前清晰可辨、主体不黏连背景；但**本轮未做 10%/25% 两级缩略图转灰度严格判定**，不冒称 J1 通过。 |
| **J2 主体与背景明度差 ≥2 档** | **通过（静态色板 + 画面实证）** | 冷夜雾 `#1B2A4A`(L≈22) / 地面 `#2C4C8C`(L≈45) ↔ 主体暖金 `#C99A3A`(L≈65) / 亮钢 `#E8EDF2`(L≈92)，差 ≈2~4 档；三帧灰度下白面甲 / 剑与深蓝地面明显分离。 |
| **J3 同屏高饱和色 ≤3 种** | **通过（目视）** | 同屏抢眼强调色为暖金（HUD 金线 / 字 / 光束）、危险暗红（Boss 披风 / 红缨）、少量青绿（增益 / 宝石点缀），⊆ 白名单 `#B33A3A/#C99A3A/#35D0C0` 且 ≤3；其余冷蓝 / 亮钢为受光过渡色不计入。本轮弹反层零新增色号、强度受控（峰值 alpha ≤0.42），未引入第 4 种抢眼色。 |
| J5 单帧 ≤16 色 | **通过** | 弹反层零新增色号；ground_tile 实测 6 色。 |
| J7 光效不遮 HUD 与角色判定区 | **通过（本层）** | 弹反预兆环心在 `(320,250)` 逻辑、失败冷雾横带在 y≥286 逻辑，主动避开 HUD `x<365,y<110`；既有 HUD 文字重叠属其它 Rank 布局（§4.3）。 |

### 4.6 HD-2D 全绿是否达成

> **未达全绿**（如实登记，不沿用 R31「全绿达成」自评，不把 2D 近似包装成全绿）。按 `HD2D-STYLE-ANCHOR-v2.md` §3 差距清单，仍是 **2D 近似**：

| # | 差距 | 本工程现状 |
|---|---|---|
| 1 | 真 DoF / 平滑多层虚化 | 2D 分层色带 + 视差 + 传统深度雾（`fog_density=0.02`），无相机后处理 |
| 2 | 真 `volumetric_fog` | `draw_colored_polygon()×6 + draw_line()` 光锥近似 |
| 3 | SSR / Planar 湿地倒影 | `draw_rect()` 垂直镜像色块 |
| 4 | `Environment.glow` 后处理 | `draw_circle()` 同心圆；`glow_enabled=false` |
| 9 | Forward+ / Vulkan 渲染后端 | 仍 `gl_compatibility`（A30 裁决不切后端） |

> **已对齐（口径级）**：像素精灵硬边 / 有限色板 / Nearest、暖金主光 × 冷夜雾光色关系、金线深蓝 1px UI。**本轮新增的弹反反馈层同为 `_draw()` 2D 近似、地面仍是 2D tile 贴 3D 平面、角色仍是 billboard 像素精灵，未新增任何真 3D 光效、未切后端**；README「还差什么」第 2 项（真 HDR bloom / 3D 体积光 / SSR）与第 12 项（HD-2D 全绿未达）**保持未达**。

---

## 5. 未完成项 / 阻塞

- **弹反视觉反馈画面可见性未证实（本轮最主要的如实缺口）**：代码 / 绑定 / 生产链路（开窗 3 次 + 一次成功弹反）均已落地且日志实证，但本轮 15 秒录屏未能明确目视辨识本轮新增金色预兆环与成功冲击闪光。原因（§4.1）：① 唯一成功弹反落在 SEG-B frame=150 mobile 四项全关切换点 → FX 层零绘制（降级门控必然结果）；② 开窗 `window_sec=0.35s` 极短、环 alpha 0.40 低、与既有 FX / 中央角色 / 面板叠加；③ 既有 R32 impact_fx 自带同心圆 + 十字准星 + 放射刻度，与弹反环视觉语言相近、易混淆。**未回退演示驱动、未擅改 `[PLACEHOLDER]` 数值、未伪造画面。**
- **D→A 递进 / A 档暖金递进 / S 级收束爆发 / 冷夜雾冷却**：画面未见 D→A / S（仅见 D→C 递进），真实命中数低 + 受击 / 超时重置使 combo 未跨 A 门槛；链路与绘制代码已接线（G3 + 录屏日志 `signals=4`），属「演示未覆盖」，非「未实现」。
- **HUD 中部文字重叠**（既有，§4.3）：非本轮引入，硬约束不改 `hud.gd` / `presentation.gd`，列为待裁决。
- **J1 10% 缩略图严格判定未做**（§4.5），本轮按三帧全尺寸目视，不冒称通过。
- **成功闪光 / 冷夜雾冷却的无过曝与观感**：需人工试玩或更长录屏（且让成功弹反落在 desktop 四项全开段）触发后目视校准，本轮未在实机画面验证。
- **J1 / 全绿**：HD-2D 全绿未达（§4.6），差距清单保持未达。
- 无阻塞；硬约束内工作已完成。

---

## 6. 待总指挥裁决项（只登记、不擅改）

1. **弹反反馈画面可见性**：是否允许在 `[PLACEHOLDER]` 不擅改前提下，由 Rank-1 后续轮次把「成功弹反」安排在 desktop 四项全开段（SEG-A / SEG-C）以覆盖冲击闪光，或提高开窗窗口 / 环 alpha / 环位置以拉开与既有 R32 impact_fx 的辨识度；或协调 R32 impact_fx 与弹反环视觉语言差异化（本轮 Rank-4 未越界改 impact_fx 素材 / 不改 `presentation.gd`）。
2. **引擎日志 `411 frames / 00:00:13:21` vs 磁盘 450 帧 / ffprobe `15.000000s` 口径差异**（§2.3）：本轮交付以磁盘落盘 450 连续帧 + ffprobe 450 帧 15s 为准（成片可正常播放 15 秒），引擎 Movie Maker 内部统计口径差异原样留档，请裁决以何者为准 / 是否需排查 Movie Maker 丢帧统计。
3. **演示覆盖 vs 玩法闭环**：D→A 递进、S 收束、弹反成功闪光均「真实链路已接线但 15 秒演示未覆盖」。是否在 `[PLACEHOLDER]` 不擅改前提下由 Rank-1 提高真实按键密度 / 延长录屏 / 调整画质段以覆盖（**不走演示驱动伪造状态**），或维持如实登记。
4. **HUD 文字重叠**：中部「赐福引导」与金色奖励文字叠压（既有），归属 Rank-1 `hud.gd` / 教学 HUD 布局，本轮 Rank-4 不越界修改。
5. **全部 `[PLACEHOLDER]` 校准**：弹反反馈 `RING_* / FLASH_* / FAIL_* / BIND_*` 与地面 `band_heights / col_widths / band_offsets / seed / core_period`；调参唯一入口 = `hd2d_fx.gd` 常量表与 `ground_tile.import.json`（只改表不改算法）。
6. **§9.3 口径差异**：程序化 `_draw()` 契约定位为「M0 占位 / 显存不足降级」，本轮按任务单「以任务单为准」特批用于**运行时视觉反馈层**（非替代正式素材）。请在 §9.3 / `HD-2D视觉规范.md` 补「运行时反馈层」例外条款，或恢复为纯 ComfyUI 素材路线。
7. **地面 `ground_tile.import.json` 独立登记**：`r23/import.json` 为 impact_fx 专用且被 R32 只读加载，本轮未动；是否统一两资产登记格式由总指挥裁决。
8. **既有 WARNING**（BossController IDLE / ObjectDB leaked）是否纳入后续清理，非本轮引入。

---

## 7. 回执与中枢归档

- 回执写入 Rank-4 授权路径（**`teamwork/command_center/`，非工程根**）：`teamwork/command_center/ai/4/outbox/cmd-20261112-125821-147-A4.json`，四字段 `{"task_id":"cmd-20261112-125821-147-A4","ai":4,"status":"done","result":"引用 DONE-R35.md 实际结论"}`。
- **中枢归档回读确认（写后实测，中枢已运行，如实登记、不伪造）**：
  - `ai/4/outbox/` 已清空（回执被中枢移走 → `dispatcher/receipts/`，属中枢正常处理，与 Rank-2 / R34 一致，不重放、不伪造）。
  - 归档副本 `dispatcher/receipts/cmd-20261112-125821-147-A4.json` 存在（1626 字节），回读 **VALID_JSON**，四字段 `task_id=cmd-20261112-125821-147-A4 / ai=4 / status=done / result_len=823` 齐全。
  - `ai/4/status.json` 更新为 `{"ai":4,"state":"idle","current_task":"","completed":64,"last_seen":"2026-11-12 14:22:58"}`（`completed` 由 63 → 64、`current_task` 清空）。
  - `dispatcher/dispatcher.log` 尾部原文：`[2026-11-12 14:22:58] ← 4 号 AI 回执 <cmd-20261112-125821-147-A4> 完成：R35 / v0.12.0 Rank-4 完成，实际结论见 teamwork/Rank-4/DONE-R35.md…`，确认 id 与派单一致。

---

## 8. 硬约束遵守声明

- 只写授权文件：`godot/assets/generated/r23/` 下 PNG（`ground_tile.png` 覆盖）与 `import.json`（`ground_tile.import.json` 覆盖）、`hd2d_fx.gd`、`capture/`、`teamwork/Rank-4/`（`DONE-R35.md` + `r35_ground_tile_redraw.py`）、回执。
- **未改** `encounter_director.gd` / `hud.gd` / `presentation.gd` / `wave_trial_director.gd` / `points_commit_orchestrator.gd` / `project.godot` / `courtyard.tscn` 场景节点与 uv（A38）/ `r23/import.json`（impact_fx 专用）/ 数据表 / 其它 Rank 文件 / `hd2d_parallax.gd`（本轮无需改动，未触碰）。
- 零付费、零外部依赖（仅本地 Pillow + Godot + 本地 ffmpeg）、不启 GPU job、不引入外部素材生成服务；程序化 `_draw()` 与地面生成均为本地确定性管线。
- 单帧 ≤16 色受控 + 项目级 ≥256 色两层口径不变（弹反层零新增色号）；A54 复用唯一 ParryService、不读私有实现；A48① 生产订阅者 = FXBloom 生产节点；`[PLACEHOLDER]` 全部标注 rationale + 调参唯一入口。
- 不伪造产物、不谎报成功、不冒称弹反反馈画面可见 / 不冒称全绿、不自行 git、未删除 `.workbuddy`；默认不刺探（未扫目录做进度巡检、未写只读探针 / 巡检脚本，仅按任务单有目的地读契约 / 目标文件 / 目视帧）。
- Movie Maker **未加 `--headless`**（A47）；`--write-movie` 绝对路径 + `.png`；ffmpeg 9.x 用 `-fps_mode passthrough`，未用 `-vsync 0`；录屏前先跑 `--headless --import` 确认全部接线。
