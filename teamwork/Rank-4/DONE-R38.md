# DONE-R38.md · R38 / v0.15.0「大地图 · 2.5D 尺度重构」交付报告（Rank-4 美术管线与工具链）

> 轮次：`R38` ｜ 任务单 id：`cmd-20261112-234238-662-A4` ｜ 执行 AI：`4（Rank-4 美术管线与工具链执行 AI）`
> 真源：`teamwork/Rank-4/调度任务单-latest.json`（task 全文 + 公共契约 + 大改特别条款 + A48 硬要求 + 目录所有权·R38 冻结）
> 必读已读：`teamwork/00-协作契约.md` §9.3（I-5 / 裁决 A15 两层色数口径）、`teamwork/Rank-1/DONE-R38.md`（地图 4096×2304 / zoom 0.5 / 人物 0.64 / 4 层视差 0.06-0.14-0.26-0.42）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（v4.7.2.stable）｜ ffmpeg：`C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`
>
> **一句话结论**：R38 六块任务全部真跑完成 —— ① **4 张程序化 PIL 分层视差 PNG**（远山/雾带/中景哥特塔楼剪影/前景遮挡）落 `r23/`，配 `parallax_import.json`（尺寸/锚点/分层系数/逐帧色数实测），全部 ≤16 色 / RGBA 硬边 alpha / 128px 基准 / 项目级色库 256 色达标；② `ground_tile.png` 实测 **6 色 / 128×128 / edge diff=0 无缝**保持不动，按 Rank-1 新地图尺寸写出平铺规格；③ **40% 人物可读性**：旧版先备份 `v140_pre_v150_backup/`，用板内零新增色号描边增强（方案 C：3px 深色加粗 +1px 中暗蓝外圈），改前/改后 40% 对照图与色数实测齐全；④ **15 秒定稿录屏** `capture/v150_final.mp4` **450 帧 / 2,392,828 字节 / 15.000000 秒**（Movie Maker 不加 `--headless`，ffmpeg 9.x `-fps_mode passthrough`）；⑤ 目视首/中/尾 + 相机移动帧，A41 三判据逐条写结论；⑥ 三段门禁 + 全 8 份日志 `SCRIPT ERROR=0 / PARSE ERROR=0`。**如实登记**：HD-2D 全绿**未达**（仍 2D 近似）；画面角色占屏比实测 ≈0.11~0.22（严格 40% 是 `character_scale=0.64` 的几何口径，画面更小是 3D 战斗视口缩到左上 1/4 的结果）；共 **3 次录屏**（含 1 次互相关测错区域导致的误判与两次计时器修正），全部如实留档、不冒充。

---

## 1. 交付清单（实际落地文件）

| # | 文件 | 类型 | 本轮改动 / 实测 |
|---|---|---|---|
| ① | `godot/assets/generated/r23/parallax_far_mountains.png` | **新建** | 远山：3 层深蓝剪影 + 冷亮边，128×128 RGBA，**落盘实测 4 色**，alpha∈{0,255}，LR diff=0，1087 B |
| ② | `godot/assets/generated/r23/parallax_fog_band.png` | **新建** | 雾带：4 阶冷雾横带，128×128 RGBA，**3 色**，alpha∈{0,255}，LR diff=0，291 B |
| ③ | `godot/assets/generated/r23/parallax_mid_silhouette.png` | **新建** | 中景：哥特塔楼/尖顶/城墙垛口 + 暖金窗光，128×128 RGBA，**4 色**，LR diff=0，768 B |
| ④ | `godot/assets/generated/r23/parallax_foreground.png` | **新建** | 前景遮挡：岩石/石柱剪影 + 冷亮边，128×128 RGBA，**4 色**，LR diff=0，880 B |
| ⑤ | `godot/assets/generated/r23/parallax_import.json` | **新建** | I-5 规格登记：尺寸 128×128 / 锚点（底心 64,128）/ 4 层系数 0.06-0.14-0.26-0.42（注明与 `world_scale.tres` 同源、运行时从表读）/ 逐帧色数实测 / 色板 / 硬边无渐变无 dithering 无噪点 / 项目级色库 256 色。7037 B。**既有 `r23/import.json` 是 impact_fx.png 专用（`hd2d_fx.gd` R32 只读加载），逐字未动**，故新建独立规格文件不破坏既有接线 |
| ⑥ | `godot/assets/generated/r23/v140_pre_v150_backup/` | **新建（备份）** | 改前 v0.14 原件：`player_spritesheet.png`(16313 B) / `boss_spritesheet.png`(4835 B) / `ground_tile.png`(925 B)。**先备份再改** |
| ⑦ | `godot/assets/generated/r23/player_spritesheet.png` | 修改 | 3072×128 / 24 帧，方案 C 描边增强；改前每帧最大 16 色 → 改后 **16 色**（逐帧 11~16），**零新增色号**，alpha∈{0,255}，128px 基准不变，21479 B |
| ⑧ | `godot/assets/generated/r23/boss_spritesheet.png` | 修改 | 1152×128 / 9 帧，方案 C；改前 11 色 → 改后 **11 色**，**零新增色号**，alpha∈{0,255}，6794 B |
| ⑨ | `godot/assets/generated/r23/ground_tile.png` | **未改** | 实测保持 **6 色 / 128×128 / 边缘 diff=0 无缝**（左右列、上下行逐像素相等）；旧版仅备份 |
| ⑩ | `godot/scripts/render/hd2d_parallax.gd` | 修改（Rank-4 授权） | 文件**末尾追加** R38 接线段：只读 `load()` 4 张 PNG → 挂在场景既有 `ParallaxBackdrop._draw()` 远景层按系数滚动平铺 + 按层深度雾 modulate；视差系数/雾从 `world_scale.tres` 读；`Engine.get_process_frames()` 引擎帧计数驱动漂移；headless 守卫跳绘制（A47 规避）。**既有 R23/R27/R29/R31 全部 sky/fog/ridge/grade/motes/shader 逻辑、`_ready()` 原 4 行、`_process()` 原 2 行逐字保留**（仅在 `_ready`/`_draw` 各追加 1 行调用）。未新增节点、未新增信号 |
| ⑪ | `capture/v150_final.mp4` | **新建（定稿）** | **2,392,828 字节 / 1280×720 / 30fps / 15.000000 秒 / nb_read_frames=450**；对应 450 张连续编号 PNG 帧 `v150_final00000000.png`~`v150_final00000449.png` |
| ⑫ | `capture/` 目视/实测证据 | **新建** | `r38_parallax_contact_sheet.png`（4 层素材联系表）、`r38_40pct_candidates.png`（描边方案择优）、`r38_40pct_{player,boss}_{before,after,compare,frames_compare}.png`、`r38_40pct_measurement.json`（逐帧色数）、`r38_character_scale_v140_vs_v150.png` 与 `_f225_`（改前/改后 3D 角色区 2x 对比）、`r38_parallax_camera_motion_evidence.png`（4 帧相机移动）、`r38_parallax_layer_motion_compare.png`、`r38_frame_diff_0_vs_225.png`、`r38_v140_frame{0,225}.png`（v0.14 对照抽帧） |
| ⑬ | `teamwork/Rank-4/r38_*.log`（8 份） | **新建** | G1 import / G2a×2 / G2b V150 / G3 quit / movie_maker / ffmpeg / v140 抽帧日志原文留档 |
| ⑭ | `teamwork/Rank-4/DONE-R38.md` | **新建** | 本交付报告 |
| ⑮ | `teamwork/command_center/ai/4/outbox/cmd-20261112-234238-662-A4.json` | **新建** | 本轮回执（**`teamwork/command_center/`**，非工程根），写后经中枢归档（§9） |

**授权范围内未改 / 只读未动**：`godot/scripts/hd2d_fx.gd`（授权但本轮**未动**，保留 R32 impact_fx / R34 连击 / R35 弹反 / R36 A67 / R36 战技全部既有光效逻辑）、`courtyard.tscn` / `hud.gd` / `presentation.gd` / `wave_trial_director.gd` / `points_commit_orchestrator.gd` / `project.godot`（既有 autoload / run/main_scene / gl_compatibility）/ `impact_feedback.gd` / 全部既有 `.tres` 数值 / 数据表 / `palette_256.json`（实测 256 色，只读）/ 其它 Rank 文件。

---

## 2. 任务① 大地图多层视差素材（PIL 程序化 · 零 GPU job）

生成方式：Python + Pillow `ImageDraw` 硬边纯色块（polygon/rectangle/line），逐像素确定性、零渐变/零 dithering/零噪点/零随机；所有颜色从 `palette_256.json` 项目级色库取（候选色不在板内时取板内最近色，**不新增色号、不改色库文件**）。每张 128px 基准画布、RGBA 保 alpha、alpha 仅 0/255、横向平铺（第 127 列复制第 0 列 → LR diff=0）。

**落盘实测（每帧/每张色数，写进 `parallax_import.json`）**：

| 层 | 文件 | 角色 | 系数 | 实测色数 | alpha | LR diff | 字节 |
|---|---|---|---|---|---|---|---|
| L0 | `parallax_far_mountains.png` | 远山 3 层剪影+冷亮边 | 0.06 | **4** | {0,255} | 0 | 1087 |
| L1 | `parallax_fog_band.png` | 冷雾横带 4 阶 | 0.14 | **3** | {0,255} | 0 | 291 |
| L2 | `parallax_mid_silhouette.png` | 哥特塔楼+暖金窗光 | 0.26 | **4** | {0,255} | 0 | 768 |
| L3 | `parallax_foreground.png` | 岩石/石柱前景遮挡 | 0.42 | **4** | {0,255} | 0 | 880 |

`measured_max_per_frame=4`（≤16 受控上限）、`measured_all_within_16=true`、`measured_all_hard_alpha=true`、`measured_all_lr_seamless=true`、`palette_measured_colors=256`（≥256 项目级下限）。生成原文输出见 §6.1。联系表 `capture/r38_parallax_contact_sheet.png` 经 ViewImage 目视：4 层均为清晰可辨硬边剪影、透明区干净、无破图/空图/渐变。

**接线（让素材真的进画面，不改 `.tscn`）**：`hd2d_parallax.gd` 挂在场景既有 `SubViewportContainer/SubViewport/ParallaxBackdropLayer/ParallaxBackdrop` 节点（Grep 确认 `ext_resource id=11_r23px`），本轮在其 `_draw()` 末尾追加 `_draw_r38_layers()`：4 张 PNG 各按系数 `fposmod(-(cam_x·coef + frames·drift·coef), 128)` 横向平铺 6 次，深度雾以常数 `modulate` 近似（远浓近淡，无渐变无噪点）；`cam_x` 只读生产 `BigMapRuntime.get_bigmap_snapshot()["camera_position"].x`（接口缺失静默回退 0）。系数与雾在 `_r38_init()` 从 `res://data/render/world_scale.tres` 读（**数据驱动，不硬编码**），资源 `load()` 前 `ResourceLoader.exists` 守卫、缺失静默跳过。

---

## 3. 任务② 地面大范围平铺规格（Rank-1 新地图尺寸）

**`ground_tile.png` 本轮未改**（已满足规格），落盘实测原文：

```
size=128x128  unique_rgb_visible=6  alpha_set=[255]
colors_6 = #060A14 / #0A1020 / #1B2A4A / #2C4C8C / #3F6FC4 / #79B4E8
LR_col_mismatch_px=0  TB_row_mismatch_px=0  edge_diff=0  hard_alpha_only_255=true
```

**平铺规格说明（按 Rank-1 A74 新基线，只读引用、不改节点与 uv）**：
- 地图逻辑尺寸 **4096×2304**（`world_scale.tres` `map_logic_size`），单屏 1280×720，`camera_zoom=(0.5,0.5)` → 同屏可见 **2560×1440**（视野 2× 扩大）。
- `courtyard.tscn` 三处地面材质 `uv1_scale`：`GroundPlate (16,16,1)`、`TerraceLow (8,8,1)`、`TerraceHigh (8,8,1)`（A74 新基线 16/8/8，由 Rank-1 授权改动，本轮**逐字未动**）。
- tile 为 128×128 单帧、6 色受控、硬边、严格无缝；大地图下 `GroundPlate` 16 倍、`Terrace` 8 倍平铺，使扩大视野中石板不拉伸、不稀疏（Rank-1  rationale：地图远大于单屏需大倍率平铺）。
- 本轮**未调整 tile 观感**（观感已满足规格），仅把 v0.14 原件备份到 `v140_pre_v150_backup/` 作基线留档；既有 `ground_tile.import.json`（R35 登记，含 A74 前 uv 说明）为历史文档，未改、未越权同步。

---

## 4. 任务③ 40% 人物可读性（关键）

**现状诊断**：备份版 `player_spritesheet.png` / `boss_spritesheet.png` 已量化为受控板（player 24 帧每帧 11~16 色、boss 9 帧每帧 11 色、alpha 仅 0/255），且**已有 1px 深色描边 `#0A1020`**（frame0 边界 500/654 px 全为此色）。缩到 40%（128×0.40≈51px，最近邻）时这 1px 描边几乎采样丢失 → 轮廓糊。

**方案择优（如实留档）**：初版「1px 冷亮 `#C9D2E0` 外描边」在 40% 对照图中**断裂成零散白点/白线碎屑，观感像噪点**（`capture/r38_40pct_candidates.png` B 列，Boss 尤甚）→ 判不合格。生成 A/B/C 三候选经 ViewImage 择优：**C = 3 圈 `#060A14` 深色加粗 + 1 圈 `#1B2A4A` 柔和中暗蓝最外圈**（A 纯深色在深蓝背景几乎无改善；B 冷亮 2px 白边太抢眼）。`#060A14` / `#1B2A4A` 在 player 与 boss 板内均已存在 → **零新增色号**。

**改前 / 改后缩到 40% 对照**（`capture/r38_40pct_{player,boss}_compare.png`，51×51 最近邻 → 6x 放大、冷夜底）：
- 改前：深色部位（披风下摆/腿）与深蓝背景融合、轮廓不完整。
- 改后：角色外围出现**柔和暗蓝轮廓环**，角色与背景分隔、人形（头/躯干/披风/盾/剑/腿）更清晰，**无白色碎点**，主体内部细节未被破坏、无明显变胖变形。
- 如实：40% 下角色**内部**细节仍受最近邻采样限制，方案 C 主要改善**外轮廓**，未做内部重着色（避免破坏既有配色）。

**色数实测（`capture/r38_40pct_measurement.json`）**：

```
player 3072×128 / 24 帧：before_max=16 → after_max=16  逐帧 [16…15,11→12,16…15]
boss   1152×128 /  9 帧：before_max=11 → after_max=11  逐帧全 11
all_within16=true   new_hex_added=[]（零新增色号）   alpha=[0,255]   128px 基准不变
```

---

## 5. 任务④ 15 秒定稿录屏（真跑输出）

**录屏纪律**：Movie Maker **不加 `--headless`**（A47：dummy 渲染器 `texture_2d_get` 空纹理崩溃 `0xC0000005`）；录屏前跑 `--headless --import`（G1）确保包含本轮全部接线；`--write-movie` 绝对路径带 `.png`；帧命名 `v150_final%08d.png`；ffmpeg 9.x 用 `-fps_mode passthrough`（无 `-vsync 0`）；帧数以磁盘连续编号 + ffprobe 为准（A62）。

**共 3 次录屏（如实登记，不隐瞒）**：
1. 首录 450 帧成功；随后互相关**误测右半屏**（x=650..1250，那里是既有程序化远景层、静止）得 `dx=0`，误判「4 层视差未滚动」。
2. 第一次修正（`Time.get_ticks_msec()` → `_process(delta)` 累加）后重录 450 帧；差分发现变化集中在左半屏、左半屏互相关 `y=95 dx=+27 / y=300 dx=+44`（恰与系数 0.26/0.42 理论位移 27.3/44.1px 吻合）→ 定位为**测错区域**，非代码 bug。
3. 第二次修正为 **`Engine.get_process_frames()` 引擎帧计数**（Movie Maker `--fixed-fps` 下墙钟与 `delta` 均不推进，帧计数每帧必 +1，最稳）并加每 150 帧 offset 诊断日志 → 第三次重录（清理中间帧、串行）作为**最终定稿**。

**最终定稿原文输出**：

```
G2A_PARALLAX_EXIT=0   G3_QUIT_EXIT=0   MOVIE_MAKER_RERUN3_EXIT=0   FFMPEG_EXIT=0
on-disk frames = 450  (v150_final00000000.png … v150_final00000449.png 连续编号)
Godot: Done recording movie … 450 frames at 30 FPS (movie length: 00:00:15:00)
MP4 bytes = 2392828
ffprobe: width=1280 height=720 r_frame_rate=30/1 duration=15.000000 nb_read_frames=450 size=2392828
```

**接线与视差滚动硬证据（Movie Maker 日志原文）**：

```
[R38][PARALLAX] 4 层视差素材接线 | loaded=4/4 source=res://data/render/world_scale.tres coeffs=[0.06,0.14,0.26,0.42] fog=[0.30,0.18,0.09,0.02] headless=false
[R38][PARALLAX][MOTION] frame=0   cam_x=2048.0 offsets(4 layers, px)=[5.12, 97.28, 107.52, 35.84]
[R38][PARALLAX][MOTION] frame=150 cam_x=2080.0 offsets(4 layers, px)=[127.0, 82.99, 80.99, 120.98]
[R38][PARALLAX][MOTION] frame=300 cam_x=2080.0 offsets(4 layers, px)=[122.79, 73.19, 62.77, 91.56]
```

4 层 offset **逐帧不同且互不相同**（远小近大系数驱动），相机 `cam_x` 2048→2080 真实位移；左半屏互相关 `y=95 dx=+28`、`y=300 dx=+44` 与 coef 0.26 / 0.42 理论位移一致。

---

## 6. 任务⑥ 三段门禁 + 全工程 `SCRIPT ERROR=0`

命令前缀 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`，日志 `teamwork/Rank-4/r38_*.log`。

```
G1_IMPORT_EXIT=0
G2A_PARALLAX_EXIT=0   G2A_PRESENTATION_EXIT=0
G2B_V150_EXIT=0       | [V150] SUMMARY pass=37 fail=0 total=37 ok=true | [V150] RESULT=ALL_MATCH
G3_QUIT_EXIT=0
```

全 8 份日志汇总（G1 / G2a×2 / G2b / G3 / movie_maker / ffmpeg / v140_extract）：

```
ALL_LOGS_TOTAL=0   （逐份 SCRIPT_ERROR=0  PARSE_ERROR=0）
```

- G3 接线日志：`loaded=4/4 source=res://data/render/world_scale.tres coeffs=[0.06,0.14,0.26,0.42] fog=[0.30,0.18,0.09,0.02] headless=true`（门禁为 headless，按 A47 守卫跳过 PNG 绘制，符合预期）。
- V150 主回归（Rank-1 本轮脚本，只读复跑）**37/37 `RESULT=ALL_MATCH`**，未出现 A79/A80 旧基线断言 FAIL（Rank-1 并行同步已完成，不影响画面）。
- **如实登记**：首次门禁曾因 `PackedFloat32Array(0.06,0.14,0.26,0.42)` 变参构造（`hd2d_parallax.gd:678/679`）报 2 条 PARSE ERROR、`G2A_PARALLAX_EXIT=1`；改为 `Array` 兜底 + `ca[i]` 显式转换后**复跑全绿**，未删断言、未放宽判定，未改任何他人脚本。

---

## 7. 人物 40% 画面实测（交付要求专节）

**几何/运行时硬指标（Rank-1 数据驱动，我只读复跑）**：`world_scale.tres` `character_scale = 1.6 × 0.40 = 0.64`；V150 A4/A5/C2/C3 实证 `target_scales=[0.64,0.64,0.64]`、画面像素高度 `2.4000m → 0.9600m ratio=0.4000`（我复跑 V150 37/37 一致）。

**录屏画素实测（红色主体段行投影，`v140_final.mp4` vs `v150_final.mp4` 抽帧）**：

| 画面 | 帧 | Boss 红色主体高度 | player 主体高度 | 备注 |
|---|---|---|---|---|
| v0.14（改前） | f0 / f225 | **110 px / 80 px** | 60 px / 38 px | 3D 战斗场景**铺满全屏 1280×720** |
| v0.15.0（改后） | f0 / f225 / f449 | **12 / 18 / 9 px** | ≈10 px（f449） | 3D 战斗区缩到**左上 640×360** |
| v0.15.0 中央大地图 2D 玩家 | f0/f225/f449 | — | 暖色主体 **12 px**（完整约 20~25 px） | 新增大地图层小角色 |

**画面占屏比 ≈ 0.11~0.22**（Boss 12/110、18/80），**小于 0.40**。原因如实：v0.15 的 3D 战斗视口由全屏缩到左上 1/4（线性 0.5），叠加角色 `scale 0.64`（=1.6×0.40）→ 约 `0.40 × 0.5 = 0.20`，与实测量级一致；红色段受 pose/裁剪影响有波动，非精确计量。

**结论**：人物在画面中**明显变为原来的约 40% 或更小**（占屏比更小是「大地图视野扩大」的结果，不是缩放未达标）；严格 40% 口径是 `character_scale=0.64`（数据驱动 + V150 37/37 实证），**不冒充「画面正好 40%」**。40% 对照图另见 §4（素材 128px → 51px 最近邻），画面中央 2D 玩家约 20~25px 与「40% 后约 50px 再经视口 0.5 缩放」一致。

---

## 8. 大地图视野与多层视差证据（交付要求专节）

- **地图/相机（只读引用 Rank-1 `world_scale.tres`）**：`map_logic_size=4096×2304`、`camera_zoom=(0.5,0.5)` → 可见 `2560×1440`、`limit=[0,0,4096,2304]`、4 层系数 `0.06/0.14/0.26/0.42`、按层雾 `0.30/0.18/0.09/0.02`。
- **视野明显变大 / 可见分区（ViewImage 首/中/尾 + 相机移动 4 帧）**：v0.14 画面为单一 3D 战斗场景铺满全屏（角色 80~110px、深蓝渐变天空）；v0.15 画面变为「左上 3D 战斗区（1/4 屏）+ 右侧/下方大范围分层背景 + 中央大地图 2D 玩家 + 画质设置区 / 波次 HUD / 赐福成长区 / 战技区」多分区，角色缩到几十像素 → **地图视野明显变大、分区可见**。
- **多层视差静态层次**：首/中/尾帧均可见 4 类新增素材 —— 深蓝远山剪影（3 层 + 冷亮边）、冷雾横带、哥特塔楼剪影带暖金窗光、底部黑色锯齿前景遮挡（v0.14 无这些元素）。`capture/r38_parallax_contact_sheet.png` 为 4 层素材本体目视。
- **多层视差动态滚动**：§5 的 `[R38][PARALLAX][MOTION]` 3 组 offsets 逐帧不同且 4 层互不相同（系数驱动）；左半屏互相关 `dx=+28 / +44` 与 coef 0.26/0.42 理论位移 27.3/44.1px 吻合；`cam_x` 2048→2080 真实相机位移。
- **2.5D 层次**：y-sort / 落地阴影（Rank-1 `BigMapRoot`/`WorldActors`，V150 37/37 实证）+ 本轮 L3 前景遮挡（画面底部黑色锯齿剪影，z 前景）+ 按层深度雾 modulate 成立；仍为 CanvasItem 2D 体系、不切后端、无真 3D 网格。
- **如实边界**：新增 4 层 PNG 绘制在**左上 SubViewport 战斗视口区（640×360）**（脚本挂载位置所限，不改 `.tscn`），右半屏大范围深蓝远景为既有程序化层（静止）；扩展到全屏 / 与 `BigMapLayer` 的 4 个空 `ParallaxLayer` 节点对接列 §11 待裁决。

---

## 9. A41 三判据目视结论（首 / 中 / 尾 + 相机移动帧）

| 判据 | 结论 | 依据 |
|---|---|---|
| **人物是否明显变为原来的约 40%** | **是（占屏比更小）** | §7：v0.14 Boss 80~110px → v0.15 9~18px，画面占屏比 ≈0.11~0.22；严格 40% = `scale 0.64`（V150 37/37）。如实：画面比值 ≠0.4000，因 3D 视口缩到 1/4 |
| **地图视野是否明显变大 / 可见分区与多层视差** | **是** | §8：多分区 + 4 类分层背景 + MOTION 4 层 offsets 逐帧不同 |
| **2.5D 层次（y-sort / 阴影 / 前景遮挡）** | **成立（2D 近似）** | y-sort/阴影 V150 实证 + L3 前景黑色锯齿遮挡 + 深度雾；无真 3D 网格/DoF |
| **HUD 文字是否仍可读且不遮角色** | **基本达标，中帧有局部重叠** | 首/尾帧 HUD 清晰、不遮中央角色；**frame=225 左侧「弹反成功!」与图鉴/波次 HUD 文字局部叠加糊在一起**（既有 HUD 在演示序列中的叠加，非本轮引入），如实登记 |
| **暖金收束是否过曝** | **未过曝** | 尾帧为局部金色光晕/光柱，无大片纯白，不盖角色与 HUD |
| **地面平铺观感** | **达标** | 6 色 / 128×128 / edge diff=0，左上 3D 区规整连续、无明显接缝或拉伸；整 tile 重复为平铺固有 |
| **HD-2D 全绿是否达成** | **未达** | 沿用 A41/A52/A61/A68：仍 2D `_draw()` / screen-reading shader 近似、无真 DoF / 真体积光 / SSR / Forward+。本轮只增强「像素角色 vs 平滑多层景深」的 2D 近似层次，差距如上，不冒称全绿 |

---

## 10. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 4 张分层视差 PNG + `parallax_import.json` 落盘，逐张色数 4/3/4/4（≤16）、RGBA 硬 alpha、128px、色库 256 色、LR diff=0，全部实测写进 DONE。② `ground_tile.png` 6 色/128/diff=0 保持、平铺规格说明、旧版备份。③ 40% 人物可读性：备份 → 方案择优（白点版回退）→ 方案 C 描边增强 → 改前/改后 40% 对照图 + 逐帧色数（16/16、11/11、零新增色号）。④ 15 秒定稿录屏 450 帧 / 2,392,828 B / 15.000000 秒，ffprobe 与磁盘一致；MOTION 日志证明 4 层视差逐帧滚动。⑤ 三段门禁 G1/G2a×2/G2b/G3 全 `EXIT=0`，8 份日志 `SCRIPT ERROR=0 / PARSE_ERROR=0`，V150 37/37 `ALL_MATCH`。⑥ 目视首/中/尾 + 相机移动帧，A41 三判据逐条结论。⑦ 只写授权文件、不切后端、美术规格不变、数值数据驱动、零付费/零 GPU job/零外部依赖。⑧ 回执写入并确认中枢归档（§11）。 |
| **失败 / 未达** | ① **HD-2D 全绿未达**（仍 2D 近似，见 §9）。② **画面角色占屏比 ≈0.11~0.22，非 0.4000**（3D 视口缩到左上 1/4 所致；严格 40% 为 `scale 0.64`），如实登记不冒充。③ 新增分层素材只在左上 SubViewport 区绘制，右半屏既有远景层静止。④ 中帧 HUD 局部文字重叠（既有叠加）。⑤ 40% 下角色内部细节仍受最近邻采样限制。⑥ 共 3 次录屏（含 1 次互相关测错区域误判 + 2 次计时器修正），全部如实留档。 |
| **需用户确认 / 待裁决** | 见 §11（共 8 项）。 |

---

## 11. 未完成项 / 待总指挥裁决项（如实登记，不擅改）

1. **§9.3 美术路线口径冲突（最高优先）**：契约 `00-协作契约.md` §9.3 第 347 行写「所有美术素材统一用本地 ComfyUI 制作，程序化 `_draw()` 仅作 M0 占位与显存不足时降级，不是正式素材路线」；本任务单明确授权「程序化 PIL（零 GPU job、零付费）新增分层背景 PNG」且硬约束「不启 GPU job / 不引入外部素材生成服务」。本轮按「以任务单为准」+ 大改特别条款零 GPU job 走 **PIL 程序化**路线，`parallax_import.json` 的 `pipeline_note` 已登记该冲突。请裁决：R38 大改期是否豁免 §9.3 的 ComfyUI 主路线口径，或后续需以 ComfyUI 重出这 4 张（涉及 GPU job，与硬约束冲突）。
2. **画面角色占屏比非 0.40**：是否需调整 `camera_zoom` / SubViewport 布局，使画面中角色像素高度比值正好 ≈0.40（当前 ≈0.11~0.22）？涉及 Rank-1 的 `courtyard.tscn` / `world_scale.tres`，本轮未越权改。
3. **分层素材覆盖范围**：新增 4 层 PNG 现画在左上 `SubViewport` 战斗视口区；`BigMapLayer` 的 `ParallaxLayer0~3` 是**空容器节点**（无 Sprite/texture，Rank-1 骨架）。是否需下轮把素材接入这 4 层 / 扩展到全屏？涉及 `courtyard.tscn` 节点与 uv（Rank-1 授权）。
4. **中帧 HUD 局部文字重叠**：`frame=225` 左侧「弹反成功!」与图鉴/波次 HUD 叠加，属既有 HUD 在演示序列中的叠加（非本轮引入）；是否需 Rank-1 调整 HUD 分区，请裁决。
5. **`[PLACEHOLDER]` 试玩校准**：`R38_DRIFT_PER_FRAME=0.467`（逻辑px/帧）、`R38_LAYER_Y=[0,-8,8,220]`、按层雾 modulate 系数、40% 描边圈数待人工试玩校准；调参唯一入口 = `world_scale.tres`（视差系数/雾），漂移与 y 落点仅本脚本常量，不散落硬编码。
6. **40% 人物内部细节**：方案 C 只改善外轮廓；是否需内部重着色/减色以进一步提升 50px 下内部可辨性（会动既有配色），待试玩校准。
7. **HD-2D 全绿路线**（沿用 A41/A52/A61/A68）：真 DoF / 真体积光 / SSR / Forward+ 仍未实现，本轮如实写「未达」及差距，未冒称。
8. **沿用前序未完成项**：`128bit` 歧义（A43 不消歧）/ 真机 exe·apk 手感与移动端触控 / GitHub 补推 / 大地图 2D 层与既有 3D 层视觉融合与标准 `Camera2D.current` 管线（同 Rank-1 DONE-R38 §10）/ 既有 5 份回归 8 条 A38 旧基线断言同步（Rank-1 §10 待裁决 #1）。

---

## 12. A48 / A54 / 硬约束遵守声明

- **A48① 新信号必须有生产订阅者**：本轮**未新增任何信号**（`hd2d_parallax.gd` 只读生产 `get_bigmap_snapshot()` 快照 + `_draw()` 直接绘制，无事件广播），不构成「无订阅者新信号」；`[R38][PARALLAX][MOTION]` 是生产脚本内诊断 print，**不是新建只读探针/巡检脚本**。
- **A54 唯一实例**：复用 Rank-1 唯一 `world_scale.tres` 配置源（`_r38_init()` 从表读系数/雾），不自建第二份配置、不新增全局服务单例；4 张 PNG 由 `load()` 只读加载。
- **纯逻辑不算可玩交付**：交付含 450 帧真实实机录屏 + 目视回看 + 三段门禁真跑，非仅单元断言。
- **大改特别条款**：保留 v0.1~v0.14 全部机制与入口（未删任何节点/信号/入口）；不切渲染后端（仍 `gl_compatibility`，`project.godot` 只读）；美术规格不变（128px / 单帧 ≤16 色 / 项目级 ≥256 色 / RGBA 保 alpha / 硬边无噪点，全部落盘实测）；人物缩放与地图尺寸数据驱动（只读 `world_scale.tres`，脚本无 1.6/0.64/4096/2304 字面量）。
- **硬约束**：只写授权文件（`hd2d_parallax.gd`、`r23/` 下新 PNG 与 `parallax_import.json`、`player/boss_spritesheet.png`、`ground_tile.png` 未改、`v140_pre_v150_backup/`、`capture/`、`teamwork/Rank-4/`、回执）；**未改** `courtyard.tscn` / `hud.gd` / `presentation.gd` / `wave_trial_director.gd` / `points_commit_orchestrator.gd` / `project.godot` / `hd2d_fx.gd` / 数据表 / 其它 Rank 文件；零付费、零外部依赖、不启 GPU job、不引入外部素材生成服务；默认不刺探（读取均针对任务单指定契约/目标文件/必要对比素材，未主动扫目录做进度巡检、未写只读探针）；不伪造产物、不谎报成功（3 次录屏 / PARSE ERROR 修复 / 测错区域误判 / HD-2D 未达 / 画面占屏比非 0.40 全部如实登记）；不自行 git；未删除 `.workbuddy` 目录。

---

## 13. 回执与中枢归档确认

- 回执写入授权路径（**`teamwork/command_center/`**，非工程根）：`teamwork/command_center/ai/4/outbox/cmd-20261112-234238-662-A4.json`，四字段 `{"task_id":"cmd-20261112-234238-662-A4","ai":4,"status":"done","result":"引用 DONE-R38.md 实际结论"}`。
**中枢归档回读确认（写后实测，原文）**：

```
OUTBOX_FILES= []                                   # ai/4/outbox/ 已清空（回执被中枢移走）
RECEIPT_EXISTS= True BYTES= 2589                   # dispatcher/receipts/cmd-20261112-234238-662-A4.json
RECEIPT_VALID_JSON=True keys=['ai','result','status','task_id']
  task_id=cmd-20261112-234238-662-A4 ai=4 status=done result_len=1448
STATUS_JSON= {"ai":4,"state":"idle","current_task":"","completed":69,"last_seen":"2026-11-13 09:11:00"}
DISPATCHER_LOG= [2026-11-13 09:11:00] ← 4 号 AI 回执 <cmd-20261112-234238-662-A4> 完成：R38/v0.15.0 六块任务全部真跑完成，实际结论见 teamwork/Rank-4/DONE-R38.md：①4 …
LEDGER_VALID_JSON=True id=cmd-20261112-234238-662-A4 ai=4 status=done
  issued_at=2026-11-12 23:42:39 finished_at=2026-11-13 09:11:00 result_len=1448
```

回执四字段齐全、id 与派单一致、`status=done`，中枢已回收验证并归档；`ledger.jsonl` 本任务行 `result_len=1448` 与回执逐字一致（`RESULT_MATCH`）。
