# DONE-R35B.md · R35B「弹反视觉收敛」交付报告（Rank-4 美术管线与工具链）

> 轮次：`R35B / v0.12.1` ｜ 任务单 id：`cmd-20261112-142648-353-A4` ｜ 执行 AI：`4（Rank-4 美术管线与工具链）`
> 真源：`teamwork/Rank-4/调度任务单-latest.json`（`task` 全文 + 总指挥目视纠正结论 + 公共契约 + 目录所有权）。**以任务单为准**。
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> ffmpeg：`C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`（9.x，`-fps_mode passthrough`，未用 `-vsync 0`）

> **一句话结论**：任务单四项任务全部真跑完成 —— `hd2d_fx.gd` 弹反视觉收敛（a~e 全落地，含 mobile 轻量降级绘制）、`capture/v120_final.mp4` 覆盖重跑（磁盘 **450 帧** / ffprobe **450 帧 15.000000s** / **1,958,653 字节** / 录屏 `SCRIPT ERROR=0`）、首中尾 + 弹反窗口帧目视（按总指挥纠正口径）、三段门禁 + G3 + A38 全过。**但【如实、不冒称】画面中景那块半透明浅色大矩形本体未在授权范围内消除**：经像素级定位，它来自 **R31 `godot/scripts/render/impact_feedback.gd` 打击反馈层的暖金闪光安全单元网格（Rank-1 独占只读）**，不是 `hd2d_fx.gd` 的弹反层 / 不是抉择卡片底板 / 不是 HUD 文字框 / 不是地面贴图；该文件不在本轮唯一写入方清单内，故只完成定位实证 + 本层收敛，矩形本体列为**未完成 / 待裁决**（请授权改 `impact_feedback.gd` 或派单 Rank-1）。

---

## 1. 交付清单（实际落地文件）

| # | 文件 | 类型 | 本轮改动 |
|---|---|---|---|
| ① | `godot/scripts/hd2d_fx.gd` | 修改（Rank-4 授权） | R35B 版本头注 ⑩ + `godray_spread_*` 收束常量 + R35B `[PLACEHOLDER]` 常量表（局部环锚点 / 轻量环参数）+ `_draw_combo_rank_fx()` 全宽横带改局部 + `_draw_parry_fx()` 收敛（局部环 / 移除全宽横带 / 成功闪光锚 Boss）+ 新增 `_draw_parry_lightweight()` + `_apply_profile()` / `_process()` / `_draw()` 三处 mobile 轻量降级接线。**HUD 文字框逐字未动**；`hd2d_parallax.gd`、r23 PNG、`courtyard.tscn`、`hud.gd`、`presentation.gd` 等一律未改。 |
| ② | `capture/v120_final.mp4` | 覆盖（Rank-4 授权） | 15 秒定稿录屏成片，450 帧 @30fps / 1280×720 / **1,958,653 字节**（覆盖 R35 的 1,784,400 字节版）。 |
| ③ | `capture/v120_final_r35b00000000.png` … `...00000449.png` | 新增（中间帧） | 本轮 Movie Maker 原始帧 450 张（编号 0..449 连续、无缺失），与 R35 旧帧分前缀留档，避免帧数统计混淆。 |
| ④ | `capture/r35b_review_01..07.png` | 新增 | 从新 MP4 用 `-fps_mode passthrough` 抽的首 / 弹反窗口 / 中 / 尾帧（n=30/110/148/150/225/340/440），供 A41 目视。 |
| ⑤ | `capture/r35b_probe_*.png` / `r35b_v110_*.png` / `r35b_crop_*.png` / `r35b_diff_*.png` / `r35b_segb_*.png` / `r35b_decay_*.png` | 新增 | 改前基线帧、v110 对照帧、中景裁剪、v110↔v120 差分、SEG-B 分段、连续帧衰减曲线 —— **半透明矩形定位实证**留档。 |
| ⑥ | `capture/r35b_g1_import.log` / `r35b_movie.log` / `r35b_ffmpeg.log` / `r35b_g3_quit.log` / `r35b_verify_fx_mobile.log` / `r35b_extract.log` | 新增 | 三段门禁 / 录屏 / ffmpeg / R19 口径核对 真跑日志原文留档。 |
| ⑦ | `teamwork/Rank-4/DONE-R35B.md` | 新增 | 本交付报告。 |
| ⑧ | `teamwork/command_center/ai/4/outbox/cmd-20261112-142648-353-A4.json` | 新增 | 本轮回执（**teamwork/command_center/**，非工程根）。 |

### ① `hd2d_fx.gd` 收敛要点（逐条对应任务单 1 a~e）

- **a) 移除 / 缩小半透明大矩形底板**：
  - `_draw_godrays()` 的 6 层暖金半透明扇形底边由 `spread 40..190`（宽 380 逻辑px，2x 后 760 屏幕px）收束为 `spread 20..70`（宽 140 逻辑px，2x 后 280 屏幕px），`[PLACEHOLDER]` `godray_spread_base=20.0 / godray_spread_step=10.0` + rationale，**峰值 alpha 0.18 / 6 层 / 中心高光带逐字不改**（不过曝、暖金主光仍在）。
  - `_draw_combo_rank_fx()` 冷却：原 4 条全宽 `draw_rect(Rect2(0,…,BUFFER_W,…))` 半透明横带 → 围绕角色脚下的**局部短带**（≤120 逻辑px）+ 一个局部收环。
  - `_draw_parry_fx()` 失败回落：原 4 条全宽 `draw_rect` 半透明横带 → **移除**，只留围绕角色的局部暗色收环 + 一段 104 逻辑px 局部冷雾短带。
  - **保留**右下评级条（`162×28` 小 UI，总指挥确认「4 HIT x1.15」可读）与全部 HUD 文字框。
- **b) 局部金色预兆环**：环心改用 `[PLACEHOLDER]` 常量表 `PARRY_RING_ANCHOR_PLAYER=(320,250)`（中央骑士脚底）/ `PARRY_RING_ANCHOR_BOSS=(386,168)`（Boss 躯干），**半径仍为 28~44 逻辑px 的局部量级**，逐项 rationale 已写入常量区（调参唯一入口 = 常量表，只改表不改算法）。预兆环 / 失败收环围绕角色，成功冲击闪光围绕 Boss；均不再 `draw_rect` 全宽铺中景。
- **c) 成功闪光短促不过曝**：`PARRY_FLASH_SEC=0.36`、`PARRY_FLASH_ALPHA=0.42`、两段既有色号（冷蓝 `#BFD0EA`/`#4A6089` → 暖金 `#FFD27A`/`#F0A94C`）交替、无连续 RGB 插值、无纯白大核心、不叠乘既有 FXBloom `#FFF0C2 a=.85` 核心。
- **d) mobile 四项全关档位轻量降级绘制**：`_draw()` **不再 `if not _all_on: return`** —— mobile 档仅 `FXBloom` 节点画 `_draw_parry_lightweight()`（局部暖金环 + 短促成功扩散环 + 低 alpha 收环），四项光效 / R32 `impact_fx` / R34 连击层 / 全宽横带仍全关；`_process()` mobile 分支仍推进弹反计时器 + 绑定自愈 + `queue_redraw()`（每帧 1~2 个 `draw_arc`）；`_apply_profile()` 令 mobile 档仅 `FXBloom` 保持 `visible`（否则 `CanvasItem._draw()` 不会被调用）。**HUD 文字由 `hud.gd` 生产常驻可见层承担，本层不重复画文字、不动 HUD 文字框**。SEG-B 切换点（frame=150）也能看到反馈。
- **e) 色数口径不变**：全部色号逐字复用既有 `_draw` / `PALETTE_HEX` 已用 hex（`#F0A94C / #FFD27A / #FFF0C2 / #BFD0EA / #4A6089 / #2B3A5C / #16233F`），**零新增色号**；单帧 ≤16 色受控 + 项目级 ≥256 色色库两层口径（A15）不变；`r23/import.json` 与 `ground_tile.png` 逐字未动。

---

## 2. 真跑输出原文

命令前缀统一 `D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot ...`；Movie Maker **未加 `--headless`**（A47）。

### 2.1 录屏前 `--headless --import`（G1）

```
G1_IMPORT_EXIT=0
[ DONE ] first_scan_filesystem
[ DONE ] loading_editor_layout
=== G1 SCRIPT ERROR === 0
```

### 2.2 G2 语法检查（改后立即验证）

```
D:/Godot/... --headless --path F:/Game/aierdengfahuan/godot --check-only --script res://scripts/hd2d_fx.gd
CHECK_EXIT=0   （无输出、无解析错误）
```

### 2.3 15 秒定稿录屏（Movie Maker 覆盖重跑，`capture/v120_final.mp4`）

```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/v120_final_r35b.png \
  --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn
```

```
MOVIE_EXIT=0
==== [R22 presentation] 时间线完成 frame=450（--quit-after 450 负责退出）====
Done recording movie at path: F:/Game/aierdengfahuan/capture/v120_final_r35b.png
450 frames at 30 FPS (movie length: 00:00:15:00), recorded in 00:00:48 (31% of real-time speed).
CPU render time: 0.44 seconds (average: 0.98 ms/frame)
GPU render time: 0.32 seconds (average: 0.71 ms/frame)
Encoding time: 22.01 seconds (average: 48.90 ms/frame)
=== movie SCRIPT ERROR === 0
=== disk frames === 450
```

```
disk frames = 450
min/max = 0 449
missing_in_0_449 = 0
contiguous_0_to_449 = True
```

### 2.4 ffmpeg 9.x 合成与 ffprobe 实测（`-fps_mode passthrough`）

```
FFMPEG_EXIT=0
=== MP4 bytes === 1958653
=== ffprobe ===
width=1280
height=720
r_frame_rate=30/1
duration=15.000000
nb_read_frames=450
```

合成命令：`-framerate 30 -start_number 0 -i v120_final_r35b%08d.png -c:v libx264 -pix_fmt yuv420p -fps_mode passthrough` → `capture/v120_final.mp4`（**覆盖 R35 的 1,784,400 字节版**）。抽帧：`-vf "select=eq(n,30)+eq(n,110)+eq(n,148)+eq(n,150)+eq(n,225)+eq(n,340)+eq(n,440)" -fps_mode passthrough` → 7 帧 `REVIEW_EXTRACT_EXIT=0`。

### 2.5 三段门禁 + 全工程 G3 `grep SCRIPT ERROR=0`

```
G1_IMPORT_EXIT=0
G2_CHECK_EXIT=0
G3_QUIT_EXIT=0
r35b_g1_import.log : SCRIPT_ERROR=0 PARSE_ERROR=0
r35b_movie.log     : SCRIPT_ERROR=0 PARSE_ERROR=0
r35b_g3_quit.log   : SCRIPT_ERROR=0 PARSE_ERROR=0
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
```

既有 WARNING（如实登记、非本轮引入、非 SCRIPT ERROR、不影响 `EXIT=0`）：`2 ObjectDB instances were leaked at exit`。

### 2.6 A38 一致性（只读核对 `courtyard.tscn`）

```
node_count = 41
uv1_scale occurrences = ['uv1_scale = Vector3(2, 2, 1)', 'uv1_scale = Vector3(1, 1, 1)', 'uv1_scale = Vector3(1, 1, 1)']
18_tile ref = True
first/last node names = Courtyard / TutorialDirector
HD2DFX present = True
```

节点 **41** / uv **`2/1/1`**（`(2,2,1)` + 两处 `(1,1,1)`）/ 节点名不变 —— **A38 通过**，本轮零改动 `courtyard.tscn`。

### 2.7 R19 `verify_fx_mobile.gd` 口径真跑核对（如实登记）

```
VERIFY_FX_MOBILE_EXIT=1
==== [R19] SUMMARY pass=45 fail=2 total=47 ====
==== [R19] RESULT=FAIL ====
[R19_CHK] [FXBloom][mobile] visible PASS=false | actual=true expected=false
[R19_CHK] ⑦ desktop_vs_mobile_diff_all_4 PASS=false | ...
[R19_READ][FXBloom][mobile] visible=true _all_on=false fx_profile=mobile texture_filter=1(Nearest=1) | _on_reflection=false _on_godrays=false _on_motes=false _on_bloom=false
```

- **45/47 PASS**：4 节点 desktop 全项、mobile 的 `_all_on=false` / `fx_profile=mobile` / `texture_filter=Nearest` / **四项绘制门全 false** 全部保持。
- **2 项 FAIL** 仅因任务单 d) 修订 mobile 口径：`FXBloom` 在 mobile 档需保持 `visible=true` 才能调用 `_draw()` 画轻量环，R19 旧断言「mobile 4 节点 `visible` 全 false」不再成立。该验证脚本属 Rank-1 只读、非本轮授权、**未改**；本轮任务 4 三段门禁不含此脚本，三段门禁全 `EXIT=0` / `SCRIPT ERROR=0`。列为待裁决（§7）。

---

## 3. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① `hd2d_fx.gd` 弹反视觉收敛 a~e 全落地（局部环 `[PLACEHOLDER]`+rationale / 短促闪光不过曝 / 移除全宽横带 / 体积光收束 / mobile 轻量降级绘制 / 零新增色号）；② HUD 文字提示框**逐字未动**（总指挥确认可读、位置合适）；③ 定稿录屏覆盖重跑：磁盘 **450 帧连续 0..449** / ffprobe **450 帧 15.000000s** / **1,958,653 字节** / 录屏 `SCRIPT ERROR=0` / Movie Maker 未加 `--headless` / 录屏前 `--headless --import`；④ 三段门禁 + 全工程 G3 `SCRIPT ERROR=0` / `PARSE_ERROR=0`；⑤ A38 节点 41 / uv `2/1/1` / 节点名不变；⑥ A62 帧数口径裁决（§5）；⑦ 按总指挥纠正口径完成首/中/尾 + 弹反窗口帧 A41 目视（§4）；⑧ 半透明大矩形**精确定位实证**（§6）+ 本层「不再铺满中景」的收敛实证；⑨ 回执写入并确认中枢归档（§8）。 |
| **失败 / 未达** | ① **半透明浅色大矩形本体未消除**（根因在 Rank-1 独占只读的 `impact_feedback.gd`，超本轮授权写入范围，§6 如实登记，不伪造「已消除」）；② **HD-2D 全绿未达** —— 仍是 `CanvasItem._draw()` 2D 程序化近似（无真 DoF / 真体积光 / SSR / `Environment.glow` / Forward+），按 A30 如实写「未达」；③ D→A / S 级连击递进与 S 级收束爆发在本录屏未覆盖（仅 D→C 可见），与总指挥纠正结论一致；④ 程序化 `_draw()` 金色预兆环 / 成功闪光在实机画面仍不易明确辨识（开窗 `window_sec≈0.35s` ≈10 帧、alpha 0.40、与既有 FX / 角色 / 面板叠加）—— **此点只适用于程序化光环/闪光，HUD 文字层反馈清晰可见**；⑤ R19 `verify_fx_mobile.gd` 45/47（mobile 口径修订，见 §2.7）。 |
| **需用户确认 / 待裁决** | ① 授权修改 `impact_feedback.gd` 或派单 Rank-1 把「全屏暖金闪光矩形网格」改为局部闪光 / 降峰值 alpha / 缩短衰减（§7.1）；② R19 验证脚本 mobile `visible` 断言口径同步（§7.2）；③ 全部 `[PLACEHOLDER]` 数值待人工试玩校准；④ J1 10%/25% 缩略图转灰度严格判定未做（本轮按七帧全尺寸目视）；⑤ A62 裁决口径请总指挥复核（§5）；⑥ §9.3 程序化 `_draw()` 用于运行时反馈层的口径差异（沿用 R35 登记）。 |

---

## 4. A41 三判据与目视结论（按总指挥纠正后口径）

> 采样：新 MP4 抽帧 `r35b_review_01..07.png`（n=30 首 SEG-A / 110、148、150 弹反窗口 / 225 SEG-B 四项全关 / 340、440 尾 SEG-C），另对照改前基线 `r35b_probe_*`、v110 原始帧、差分图与连续帧衰减序列。**不沿用 R35「弹反反馈未能辨识 / HUD 既有重叠」旧结论**。

- **弹反反馈 HUD 文字层清晰可见（总指挥纠正口径，本轮复核一致）**：第 148 帧「精准弹反窗口 0.3s · 按 K」、第 150 帧「弹反成功！+削韧 / +赐福点数 / 连击不断」均清晰可读、位置合适；**HUD 文字没有重叠**（R34C 修复保持有效）。旧自评中「弹反反馈未能明确目视辨识」只适用于程序化 `_draw()` 金色预兆环 / 成功闪光，不适用于 HUD 文字层 —— 本轮按此口径纠正。
- **局部金色预兆环 / 成功闪光（程序化层）**：本轮已把环心改为角色 `(320,250)` / Boss `(386,168)` 的局部锚点、半径 28~44 逻辑px，成功闪光两段既有色号短促收束；实机画面受开窗 ~10 帧、alpha 0.40、与既有 R32 `impact_fx` 同心圆装饰 / 角色 / 面板叠加影响，**仍不易明确辨识**，如实登记（不冒称可见）。mobile 档新增轻量环路径已在 SEG-B 生效（帧 225 无开窗，环不显示属状态正确，非绘制缺失）。
- **连击 D→C 递进可见**：第 148 帧「评级 C / 倍率 1.15」、右下 `4 HIT x1.15`；第 440 帧「连击评价·6 连击·评级 C·倍率 1.15」、`4 HIT x1.15`。**D→A / S 级递进未覆盖**（真实命中数 19、受击/超时重置使 combo 未跨 A 门槛），与总指挥纠正结论一致。
- **地面观感（总指挥纠正口径，本轮复核一致）**：七帧地面均为规整错缝轴对齐矩形石板、1px 连贯直线深色缝、无斜向阶梯锯齿与破碎多边形碎片、平铺接缝不可见；相比 R34 Voronoi 破碎裂缝**观感提升**。整 tile 重复为平铺固有、仍存在（如实）。
- **A59 扣费出口生效（总指挥纠正口径，本轮复核一致）**：第 340 / 440 帧「赐福成长 ｜ 当前余额 106（点数 215 − 已消费 109）」+「提示：兑换成功：赐福·生命上限（消耗 100，余额 106）」，证明扣费出口生效。
- **暖金是否过曝**：体积光收束为窄光束后，七帧暖金主光可辨但**未泛白过曝**（砖面纹理、角色面甲 / 武器细节清晰）；成功闪光峰值 alpha ≤0.42、无纯白大核心，未在画面出现过曝。**未把 2D 近似包装成全绿**。
- **像素硬边 vs 平滑景深**：中央骑士硬边像素（1px 深色描边 / Nearest / 有限色板）与平滑远山渐变 / 光束 / 光尘层次成立，暖金 × 冷夜蓝对冲清晰；但按 A30 全部是 `CanvasItem._draw()` 的 2D 程序化近似。
- **HD-2D 全绿：未达**（如实）。差距清单（真 DoF / 真 `volumetric_fog` / SSR / `Environment.glow` / Forward+ 后端）保持未达；本轮未新增任何真 3D 光效、未切后端。

---

## 5. A62 帧数口径裁决结论（不伪造、不静默忽略）

| 来源 | R35（上一轮） | R35B（本轮） |
|---|---|---|
| 引擎 Movie Maker 日志自报 | `411 frames at 30 FPS (movie length: 00:00:13:21)` | `450 frames at 30 FPS (movie length: 00:00:15:00)` |
| 磁盘落盘帧 | 450 张（`v120_final00000000..449`，0..449 连续） | 450 张（`v120_final_r35b00000000..449`，0..449 连续、`missing_in_range=0`、`contiguous=True`） |
| ffprobe | `nb_read_frames=450 / duration=15.000000` | `nb_read_frames=450 / duration=15.000000` |
| 成片 | 1,784,400 字节 | 1,958,653 字节 |

- **差异来源（如实写清）**：R35 的 `411 frames / 00:00:13:21` 是 **Movie Maker 引擎内部帧计数统计**（`--fixed-fps 30` 下与帧提交 / 编码时序相关的一次性统计偏差），**不是产物丢帧、不是短录、不是成片只有 13.7 秒**；磁盘实际落盘 450 张连续编号 PNG、ffprobe 实测 450 帧 15.000000 秒，成片可正常播放 15 秒。本轮**同一命令、同一 `--quit-after 450 --fixed-fps 30`** 重跑，引擎日志自报已回到 `450 frames / 00:00:15:00`，与磁盘 / ffprobe 三者一致 —— 反向佐证 411 是引擎内部统计口径的偶发差异，而非固定偏移或产物缺失。
- **裁决 A62**：**以磁盘连续帧编号（0..449 无缺失）+ ffprobe 实测 450 帧 / 15.000000 秒为准**；引擎日志自报帧数仅作参考，不以其判定成片长度 / 是否短录。R35 的 411 与 R35B 的 450 两个数字均原样留档，不伪造、不静默忽略、不把短录冒充 15 秒。本轮 450 帧达标，**无需「清理中间帧后串行重跑」**（该条款仅在短于 450 帧时触发）。

---

## 6. 半透明矩形消除实证（定位实证 + 未消除如实登记）

> 任务单要求「定位它来自哪个层（弹反预兆层底板 / 抉择卡片底板 / FX 层），改成只围绕角色或 Boss 的局部金色预兆环 + 短促成功闪光，不再铺满中景」。本轮用 **v110↔v120 同帧像素差分 + 七帧分段目视 + 像素边界 / 色相 / 连续帧衰减实测 + 素材排除** 完成定位，结论如下。

### 6.1 定位结论：**FX 层 —— R31 `impact_feedback.gd` 打击反馈层的暖金闪光安全单元网格**（不是弹反预兆层底板、不是抉择卡片底板、不是 HUD 文字框、不是地面贴图）

证据链（全部留档于 `capture/r35b_*`）：

1. **v110 ↔ v120 同帧差分**：v110 的 f30/f110/f148/f150 **没有**该浅色大矩形（地面为深色 Voronoi 破碎石板、砖纹清晰、对比度正常）；v120 同帧有。差分图 `r35b_diff_f148.png` 显示新增暖色区域起于 **x≈388 / y≈188**，铺到右下 —— 与任务单「x≈390..1280、y≈190..720」吻合。
2. **边界像素精确吻合 `impact_feedback.gd` 的 HUD 避让矩形**：`RECT_CODEX (24,272,356,236).grow(8)` 右边界 = **388**；`RECT_QUALITY (760,0,520,180).grow(8)` 下边界 = **188**。`FlashPainter._draw()` 只画「与任一避让矩形交集面积为 0」的 `_flash_rects` 网格单元 → 闪光区域左 / 上边界正是 388 / 188。实测改前 f148 行 y=400：`x=384 (42,50,70)` 冷 → `x=392 (159,162,150)` 暖，阶跃点 ~388。
3. **色相**：矩形内地面像素 `(179,173,137)` / `(163,108,86)` / `(127,124,98)` 为**暖色**（R−B = +29~+77），矩形外左侧 `(64,89,115)` 为冷蓝（R−B = −51）。暖金 `FLASH_GOLD=(0.98,0.80,0.34)` 以 alpha 0.42 叠在蓝石板上正好把蓝中和成暖灰 —— 与「半透明浅色压低对比度」一致。
4. **连续帧衰减曲线坐实（决定性）**：中景暖色代理 `mean(R−B)` 实测 `f146 −46.1 → f148 +32.4（峰值）→ f150 −8.1 → f152 −34.5 → f154 −60.9（归零）→ f156/158/160 ≈ −58`，**正是 `FLASH_PEAK_ALPHA=0.42` / `FLASH_DECAY_PER_FRAME=0.06`（≈7 帧归零）的短促暖金闪光衰减曲线**，由 `player_hit_landed` / `move_landed` 信号触发。R35 高密度真实按键注入（每 4 帧 J + 每 5 帧 K）改变了命中时序，使弹反窗口帧（110/148/150）恰好落在闪光窗口内 → **「v110 定稿帧里没有的本轮新回归」**。
5. **SEG 分段排除**：SEG-B（f225，mobile 四项全关、`hd2d_fx.gd` 零绘制）与 SEG-C（f340/f440）**均无**该矩形 —— 与「由命中驱动的短促闪光、非常驻层」一致，也排除「常驻 FX 铺底」假设。
6. **素材 / 层排除**：`impact_fx.png` 为透明底同心环 + 十字准星 + 放射刻度（`r35b` 目视留档），无浅色大矩形；`r35_ground_2x2_after.png` / `ground_tile.png`（6 色、亮色为散点）无大浅色块；`v070_depth_grade.gdshader` 为径向 `exp(-gd²·16)` 光晕、非矩形；`hud.gd` 的 `R34_RECT_*=(900,190,1276,352)` 卡片底板是深色 `Color(0.04,0.06,0.12,0.30)` 且位于右上，不是中景浅色大矩形。**HUD 文字提示框保留、未动**。
7. **前后差分（`hd2d_fx.gd` 改动的实际效果）**：改前 / 改后原始帧 f148 / f30 分块平均差 **≈0~3**（仅暖金光束区 x≈800..960 有 5~10），证明该矩形**不由 `hd2d_fx.gd` 产生**；本轮对 `hd2d_fx.gd` 的收敛（收窄体积光、移除全宽横带）确实让中景不再被本层额外铺色，但矩形本体来自另一只读层。

### 6.2 已消除 / 已收敛的部分（本层，实证）

- `hd2d_fx.gd` 内**所有** `draw_rect(Rect2(0,…,BUFFER_W,…))` 全宽半透明横带（连击冷却 4 条 + 弹反失败 4 条）已移除 / 改为 ≤120 逻辑px 的局部短带 —— 代码中已无全宽铺中景的矩形底板。
- 6 层暖金大三角由 380 逻辑px 底边收束到 140 逻辑px（±70 → ±20..70），前后差分在 x≈800..960 光束区可见 5~10 的收窄。
- 弹反反馈收敛为角色 / Boss 周围的局部环（半径 28~56 逻辑px）+ 0.36s 短促闪光，不再 `draw_rect` 铺中景；mobile 四项全关档位改为轻量环 + 既有 HUD 文字（`_draw()` 不再直接 return）。

### 6.3 **未消除（如实、不冒称）**

- **`impact_feedback.gd` 的暖金闪光安全单元网格仍在**：改后 f30 / f110 / f148 / f150 中景仍可见该半透明浅色大矩形（色相 / 边界 / 衰减曲线与改前一致）。
- **原因（越界限制，非技术阻塞）**：`godot/scripts/render/impact_feedback.gd` 是 R31 **Rank-1 独占产出**，本轮目录所有权明确「其余文件（… / 其它 Rank 产出）一律只读不改」，**不在 Rank-4 唯一写入方清单内**；`hud.gd`（运行时挂载 / 绑定该层）、`presentation.gd`（R35 高密度按键注入）同为只读。本轮**未**改这些文件、**未**在运行时篡改其它 Rank 的节点 / 状态、**未**伪造画面。
- 因此「半透明矩形消除」这一验收项判定为 **未达（受限于只读边界）**，本交付只提供**定位实证**与**本层收敛实证**，不伪造「已消除」。请总指挥按 §7.1 裁决授权。

---

## 7. 未完成项 / 待总指挥裁决项（只登记、不擅改）

1. **【核心待裁决】半透明浅色大矩形本体消除**：请授权把 `godot/scripts/render/impact_feedback.gd`（R31 打击反馈层）纳入 Rank-4 写入范围，或派单 Rank-1 把「全屏 `_flash_rects` 暖金闪光网格」改为围绕命中点的局部闪光 / 降低 `FLASH_PEAK_ALPHA` / 缩短 `FLASH_DECAY_PER_FRAME`；亦或协调调整 `presentation.gd` 的 R35 高密度命中注入时序（均只读）。本轮已完成精确定位与本层收敛，未越界。
2. **R19 `verify_fx_mobile.gd` 口径同步**：本轮按任务单 d) 修订 mobile 口径后该脚本 `45/47`（两项 FAIL 均为 `FXBloom` mobile `visible`）。请裁决是否同步更新该验证脚本的 mobile `visible` 断言（脚本只读、非本轮授权、未改）。
3. **程序化弹反环 / 成功闪光辨识度**：如需在实机画面明确可辨，请裁决是否允许提高开窗窗口 / 环 alpha / 拉开与 R32 `impact_fx` 同心圆装饰的视觉差异，或把成功弹反安排到 desktop 四项全开段（涉及只读的 `presentation.gd` / 数据表的 `[PLACEHOLDER]`，本轮未擅改）。
4. **全部 `[PLACEHOLDER]` 校准**：`godray_spread_base/step`、`PARRY_RING_ANCHOR_PLAYER/_BOSS`、`PARRY_LITE_RING_R / ALPHA / FLASH_ALPHA` 及 R35 的 `RING_* / FLASH_* / FAIL_* / BIND_*` 待人工试玩校准；调参唯一入口 = `hd2d_fx.gd` 常量表（只改表不改算法）。
5. **演示覆盖**：D→A 递进 / S 级收束爆发 / 冷夜雾冷却仍属「链路已接线但 15 秒演示未覆盖」，不伪造画面、不回退演示驱动。
6. **A62 口径复核**：§5 裁决（以磁盘连续编号 + ffprobe 为准）请总指挥确认；引擎日志自报帧数仅作参考。
7. **J1 10% / 25% 缩略图转灰度严格判定**未做（本轮按七帧全尺寸目视），不冒称 J1 通过。
8. **§9.3 口径差异**：程序化 `_draw()` 契约定位为「M0 占位 / 显存不足降级」，本层按任务单「以任务单为准」用于运行时视觉反馈层；沿用 R35 登记，请裁决是否补例外条款。
9. **HD-2D 全绿未达**：差距清单保持未达（§3 / §4），不冒称。

---

## 8. 回执与中枢归档

- 回执写入 Rank-4 授权路径（**`teamwork/command_center/`，非工程根**）：`teamwork/command_center/ai/4/outbox/cmd-20261112-142648-353-A4.json`，四字段 `{"task_id":"cmd-20261112-142648-353-A4","ai":4,"status":"done","result":"引用 DONE-R35B.md 实际结论"}`。
- **中枢归档回读确认（写后实测，如实登记、不伪造）**：
  - `ai/4/outbox/` 已清空（回执被中枢移走 → `dispatcher/receipts/`，属中枢正常处理，与 R34 / R35 一致，不重放、不伪造）。
  - 归档副本 `dispatcher/receipts/cmd-20261112-142648-353-A4.json` 存在（**2855 字节**），回读 **VALID_JSON**，四字段齐全：`task_id=cmd-20261112-142648-353-A4 / ai=4 / status=done / result_len=1473`。
  - `ai/4/status.json` 更新为 `{"ai":4,"state":"idle","current_task":"","completed":65,"last_seen":"2026-11-12 15:09:13"}`（`completed` 由 64 → 65、`current_task` 清空）。
  - `dispatcher/dispatcher.log` 尾部原文：`[2026-11-12 15:09:13] ← 4 号 AI 回执 <cmd-20261112-142648-353-A4> 完成：R35B 完成，实际结论见 teamwork/Rank-4/DONE-R35B.md。① hd2d_fx.gd 弹反视觉…`，确认 id 与派单一致。

---

## 9. 硬约束遵守声明

- 只写授权文件：`godot/scripts/hd2d_fx.gd`（唯一改动的工程脚本）、`capture/`（录屏成片 / 中间帧 / 目视帧 / 日志 / 定位实证）、`teamwork/Rank-4/DONE-R35B.md`、回执。
- **未改** `hud.gd` / `presentation.gd` / `encounter_director.gd` / `wave_trial_director.gd` / `points_commit_orchestrator.gd` / `project.godot` / `courtyard.tscn`（A38 节点 41 / uv `2/1/1` / 节点名不变）/ `impact_feedback.gd` / `hd2d_parallax.gd` / `v070_depth_grade.gdshader` / r23 下 PNG 与 `import.json` / 数据表 / 其它 Rank 产出。
- **HUD 文字提示框逐字未动**（总指挥确认可读、位置合适）；未越界篡改其它 Rank 的运行时节点 / 状态。
- 零付费、零外部依赖（仅本地 Godot + 本地 ffmpeg 9.x + 本地 Pillow 像素分析）、不启 GPU job、不列任何付费项。
- 单帧 ≤16 色受控 + 项目级 ≥256 色两层口径不变（本层零新增色号）；A54 复用唯一 ParryService / ComboService，不自建第二个实例；`[PLACEHOLDER]` 全部标注 rationale + 调参唯一入口。
- 不伪造产物、不谎报成功、**不冒称半透明矩形已消除**、不冒称 HD-2D 全绿、不把 2D 近似包装成全绿、不自行 git、未删除 `.workbuddy`。
- Movie Maker **未加 `--headless`**（A47）；`--write-movie` 绝对路径 + `.png`；ffmpeg 9.x 用 `-fps_mode passthrough`，未用 `-vsync 0`；录屏前先跑 `--headless --import`；磁盘 450 帧达标，未触发「短录清理重跑」。
- 默认不刺探：未扫目录做进度巡检、未新建只读探针 / 巡检脚本；所有读取均针对任务单指定的契约 / 目标文件 / 目视帧与根因定位所必需的代码，用跑起来的画面判断进度。
- 按总指挥亲自目视纠正后的口径写 DONE：HUD 文字层清晰可见、连击 D→C 递进可见、HUD 文字无重叠、地面规整错缝观感提升、第 340 帧 A59 扣费出口生效 —— **不沿用 R35「弹反反馈未能辨识 / HUD 既有重叠」旧结论**。
