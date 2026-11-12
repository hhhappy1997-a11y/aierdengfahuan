# DONE-R34.md · R34 / v0.11.0「玩法闭合 · 连击评价」交付报告（Rank-4 美术管线与工具链）

> 轮次：`R34 / v0.11.0` ｜ 任务单 id：`cmd-20261112-091304-459-A4` ｜ 执行 AI：`4（Rank-4）`
> 真源：`teamwork/Rank-4/调度任务单-latest.json`（`task` 全文 + 公共契约 + 目录所有权）+ `teamwork/00-协作契约.md` §9.3 + `HD2D-STYLE-ANCHOR-v2.md`（A41 三判据 / A30）+ `teamwork/Rank-2/DONE-R34.md` §3（ComboService 公开信号签名）。**以任务单为准**。
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> 一句话结论：**三段门禁全 `EXIT=0` / `SCRIPT ERROR=0`；6 色 128×128 地面边缘 diff=0 无缝；15 秒定稿录屏 450 帧 / MP4 1,495,542 字节；连击评级反馈层实机可见（但 15 秒内只见 D 档、未见 D→A 递进）；HD-2D 全绿「未达成」，如实登记、不沿用 R31 自评。**

---

## 1. 交付清单（实际落地文件）

| # | 文件 | 类型 | 本轮改动 |
|---|---|---|---|
| ① | `godot/scripts/hd2d_fx.gd` | 修改（Rank-4 授权） | 新增「连击评级反馈层」：版本头注追加 R34 段 + 常量/状态/函数块 + `_ready()`/`_process()`/`_draw()` 三处最小接入。**仅追加，既有四项光效 / R32 impact_fx / R20 强制档位覆盖 / HUD 避让 / desktop-mobile 降级层开关逐字未动**。 |
| ② | `godot/assets/generated/r23/ground_tile.png` | 覆盖（Rank-4 授权 PNG） | 精修：确定性 tileable Voronoi 不规则多边形石板替代旧 4×4 规整网格 + 对角斜线纹；6 色 / 128×128 / RGBA / 硬边 / 无渐变 / 无 dithering / 无噪点 / 严格无缝。 |
| ③ | `godot/assets/generated/r23/ground_tile.import.json` | 新增（Rank-4 授权 import.json） | ground_tile 规格与**落盘实测**独立登记。**`r23/import.json`（impact_fx.png 专用、被 hd2d_fx.gd R32 只读加载）逐字未动**，避免破坏打击反馈帧参数。 |
| ④ | `capture/v110_final.mp4` | 新增（Rank-4 授权） | 15 秒定稿录屏成片，450 帧 @30fps。 |
| ⑤ | `capture/v110_final00000000.png` … `v110_final00000449.png` | 新增（中间帧） | Movie Maker 原始帧 450 张，保留留档。 |
| ⑥ | `capture/r34_review_1/2/3.png` | 新增 | ffmpeg `-fps_mode passthrough` 从 MP4 抽的首 / 中 / 尾三帧（n=0 / 225 / 449），供 A41 目视。 |
| ⑦ | `capture/r34_combo_1..4.png` + `r34_combo_contact.png` | 新增 | 补抽 desktop 段命中帧（f=45/130/320/400）2×2 联系表，供「连击反馈重点核对」。 |
| ⑧ | `capture/r34_ground_2x2_before.png` / `r34_ground_2x2_after.png` | 新增 | 地面 2×2 平铺放大联系表，精修前后目视对比。 |
| ⑨ | `capture/r34_g1_import.log` / `r34_g2_check.log` / `r34_g3_quit.log` / `r34_movie.log` / `r34_ffmpeg.log` / `r34_combo_extract.log` | 新增 | 三段门禁 / 录屏 / ffmpeg 真跑日志原文留档。 |
| ⑩ | `teamwork/Rank-4/DONE-R34.md` | 新增 | 本交付报告。 |
| ⑪ | `teamwork/command_center/ai/4/outbox/cmd-20261112-091304-459-A4.json` | 新增 | 本轮回执（**teamwork/command_center/**，非工程根）。 |

### ① 连击评级反馈层设计要点（全部数值 `[PLACEHOLDER]` + rationale，调参唯一入口 = `hd2d_fx.gd` 内常量表）

- **五档递进**：`COMBO_RANK_GLOW {D:0 / C:.10 / B:.20 / A:.32 / S:.46}`（暖金强度）、`COMBO_RANK_MOTES {D:0 / C:6 / B:14 / A:24 / S:36}`（光尘密度）；`COMBO_BURST_SEC=0.45`（S 级一次短促收束爆发）、`COMBO_COOLDOWN_SEC=0.90`（受击/超时/manual 重置冷却到冷夜雾）、`COMBO_GLOW_LERP=8.0` / `COMBO_MOTE_RISE=10.0`。逐项 rationale 写在 `hd2d_fx.gd` 头注与常量块（防过曝：峰值 alpha ≤.46、不画纯白核心、不叠乘既有 FXBloom 核心；与 ComboService 门槛 `{0,4,8,14,22}` 同量级；复用既有 `MOTES_NEAR_COUNT=48` 量级）。
- **A54 唯一实例**：`_try_bind_combo()` 用 `has_method("get_combo_service")` 遍历场景树找 `WaveTrialDirector` 节点，经其公开 `get_combo_service()` 取**同一** `ComboService`，`connect` 4 个公开信号（`combo_changed(count:int,rank:String)` / `rank_changed(from,to,mult)` / `combo_reset(reason:String)` / `combo_settled(total,base,rank,mult)`，签名真源 `Rank-2/DONE-R34.md` §3.1）；**绝不 `new()` 第二个 ComboService、不读私有实现、不依赖 `/root` 绝对路径 / group**。`deferred` 等导演 `_ready()` 装配完成后绑定，`_process` 自愈重试上限 90 帧（3s@30fps）；未接线 → `_draw_combo_rank_fx()` 静默 `return`，既有四项光效 + impact_fx 照常（降级层保留）。
- **绘制**：仅 `FXBloom` 分派（最上层）调用 `_draw_combo_rank_fx(t)` —— 评级条（D/C/B/A/S 五档方块 + 字母 + `N HIT` + 倍率角标）、暖金光尘（确定性硬边 1~2px 圆点 + `_is_hud_avoid` 逐粒避让）、S 级低 alpha 扩散环（`draw_arc`）、冷夜雾底部横带。评级条置于右下空地（逻辑 462,318），避开 HUD 面板 `x<365,y<110` 与角色判定区。
- **色数口径不变**：连击层色号逐字复用既有 `PALETTE_HEX` / 既有 `_draw` 已用 hex（`#FFD27A / #F0A94C / #FFF0C2 / #2B3A5C / #4A6089 / #16233F / #BFD0EA`）—— **零新增色号**，单帧 ≤16 色受控 + 项目级色库 ≥256 两层口径（A15）均不变；暖金 `#F0A94C` / 冷夜雾 `#2B3A5C` 即锚点 v2 §8 登记的历史显示色（32 色板 L7/L3），不冒充新色板（A32）。
- **移动端不劣化**：绘制受既有 `_all_on` 门控（mobile 四项全关时 `_draw()` 开头 `return` → 连击层零绘制、零额外加载）；计时器只在 `_all_on && name=="FXBloom"` 更新；订阅为一次性。录屏 B 段（mobile）实证连击层不绘制。
- **口径差异登记（待裁决）**：契约 §9.3 把程序化 `_draw()` 定位为「M0 占位 / 显存不足降级、非正素材路线」；本层是**运行时视觉反馈层**（非替代正式像素素材），按任务单「以任务单为准」特批用 `_draw()` 实现。ComfyUI / 本地程序化素材仍是主美术路线，不宣称已能出图 / 真 3D 光效。

### ② 地面平铺周期精修（不改 `courtyard.tscn` 的 uv，保 A38 断言）

- 旧图 2×2 联系表：4×4 规整石板网格 + 若干格对角斜线纹（`///`），平铺周期感明显。
- 新图：`24` 个确定性种子（seed `20261112`）× 9 个 wrap 镜像做最近距离分类 → 不规则多边形石板；1px 硬边深色缝；每块 2×2 高光点；核心 `127×127` 按周期 127 tileable，扩充 128×128 时第 127 列/行复制第 0 列/行 → `col0==col127` / `row0==row127` 严格 diff=0 且内部连续（`x=126` 与 `x=127(=x=0)` 相邻）。**删除斜线纹装饰与规整网格**。`courtyard.tscn` 的 `18_tile` 引用路径与 3 处 `uv1_scale (2,2,1)/(1,1,1)/(1,1,1)` 逐字未动。

---

## 2. 真跑输出原文

命令前缀统一 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；ffmpeg `C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`（9.x）。

### 2.1 地面落盘实测（Python + Pillow 逐像素，零 GPU job）

```
=== ground_tile R34 MEASURED ===
size (128, 128)
unique_rgb 6
hex_sorted ['#060A14', '#0A1020', '#1B2A4A', '#2C4C8C', '#3F6FC4', '#79B4E8']
counts {'#3F6FC4': 3199, '#0A1020': 1147, '#060A14': 292, '#2C4C8C': 10319, '#1B2A4A': 1381, '#79B4E8': 46}
alpha_set [255]
LR_col_mismatch_px 0 TB_row_mismatch_px 0
EDGE_DIFF 0
saved capture/r34_ground_2x2_after.png (512, 512)
```

- **色数 = 6**（受控板，零新增色号）；**alpha 集合 = {255}**；**左右列 / 上下行逐像素 mismatch = 0，`EDGE_DIFF=0`**（严格无缝）；128×128 RGBA；硬边、无渐变 / dithering / 噪点。
- 目视（`r34_ground_2x2_before.png` ↔ `r34_ground_2x2_after.png`）：斜向条纹装饰与 4×4 规整网格消除，改不规则多边形石板、平铺接缝不可见；**整 tile 重复仍为平铺固有、个别长直边仍在 → 「明显降低」而非「完全无周期」**（如实登记）。

### 2.2 三段门禁（真跑 `grep SCRIPT ERROR=0`）

```
G1_IMPORT_EXIT=0
G2_CHECK_EXIT=0
G3_QUIT_EXIT=0
### SCRIPT ERROR=0 核验 ###
SCRIPT_ERROR_COUNT=0
PARSE_ERROR_COUNT=0
### G1 import 关键行 ###
15:[   0% ] reimport | ground_tile.png
17:[ DONE ] reimport
### G3 主场景 R34 接线实证 ###
10:[R34B][HUD] A54 唯一实例：不自建 Combo/Boon 服务，由 _r34_bootstrap() 经 get_combo_service()/get_boon_service() 绑定 wave_trial_director 唯一实例
26:[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41
47:[R34][HUD] 生产链装配完成 | stagger_bound=true boon_bound=true combo_bound=true combo_signals=true wave_cleared=true wave_started=true visible=true
48:[R34][ComboFX] 绑定唯一 ComboService 成功 node=FXBloom signals=4（A54 复用 get_combo_service，不自建）
```

- G1 `--headless --import` 含 Rank-1 / R34B 接线后的最终工程，并 `reimport | ground_tile.png`（新图已导入）。
- G2 `--check-only --script res://scripts/hd2d_fx.gd` 单独先跑：`Godot Engine v4.7.2.stable.official.ed1daf0bf …` + `CHECK_ONLY_EXIT=0`（无解析错误）。
- G3 `--headless --quit`：主场景实证 `node_count=41`（`courtyard.tscn` 零改动 → uv `2/1/1` 断言保持）、A54 绑定成功、`combo_signals=true`。
- **`SCRIPT_ERROR_COUNT=0` / `PARSE_ERROR_COUNT=0`**（`grep` 三份日志）。
- **既有 WARNING（如实登记，非本轮引入、非 SCRIPT ERROR、不影响 EXIT=0）**：`WARNING: BossController: 数据表 id 已标记击败，控制器保持 IDLE -> boss_01_margit`、`WARNING: 2 ObjectDB instances were leaked at exit`。

### 2.3 15 秒定稿录屏（Movie Maker **禁 `--headless`**）

命令：
```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/v110_final.png \
  --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn
```

```
MOVIE_EXIT=0
FRAME_COUNT=450
=== movie log tail ===
==== [R22 presentation] 时间线完成 frame=450（--quit-after 450 负责退出）====
Done recording movie at path: F:/Game/aierdengfahuan/capture/v110_final.png
450 frames at 30 FPS (movie length: 00:00:15:00), recorded in 00:00:41 (36% of real-time speed).
CPU render time: 0.43 seconds (average: 0.96 ms/frame)
GPU render time: 0.31 seconds (average: 0.68 ms/frame)
Encoding time: 22.03 seconds (average: 48.96 ms/frame)
=== SCRIPT ERROR count in movie ===
0
```

- **450 帧 / 30fps / 15 秒达标**，无需清理重跑；`--write-movie` 绝对路径 + `.png` 后缀，输出 `v110_final00000000.png` … `v110_final00000449.png`；录屏 `SCRIPT ERROR=0`。录屏日志 `63:[R34][ComboFX] 绑定唯一 ComboService 成功 node=FXBloom signals=4`（A54 在 450 帧运行期生效）。
- 说明：上面 Bash 段末条 `grep -c "SCRIPT ERROR"` 无匹配使该条 shell 退出码为 1（**仅 grep 语义**），`MOVIE_EXIT=0` / `FRAME_COUNT=450` 与引擎日志均为成功，不冒充失败。

### 2.4 ffmpeg 9.x 合成与抽帧（`-fps_mode passthrough`，9.x 不支持 `-vsync 0`）

```
FFMPEG_EXIT=0
MP4_BYTES=1495542
EXTRACT_EXIT=0
REVIEW_FRAMES=3
-r-- 319177 r34_review_1.png   (n=0   首帧)
-r-- 379599 r34_review_2.png   (n=225 中帧)
-r-- 507616 r34_review_3.png   (n=449 尾帧)
frame=    3 fps=0.0 q=-0.0 Lsize=N/A time=00:00:15.00 bitrate=N/A speed= 104x elapsed=0:00:00.14
```

- 合成：`-framerate 30 -start_number 0 -i v110_final%08d.png -c:v libx264 -pix_fmt yuv420p -fps_mode passthrough` → **`capture/v110_final.mp4` = 1,495,542 字节**。
- 抽帧：`-vf "select='eq(n,0)+eq(n,225)+eq(n,449)'" -fps_mode passthrough` → 3 帧；`time=00:00:15.00` 证明 passthrough 保留时间戳、未丢帧。补抽 f=45/130/320/400 四帧（`-fps_mode passthrough`）拼 `r34_combo_contact.png` 供重点核对。

### 2.5 录屏日志关键证据（真实链路 / 演示覆盖）

```
73:[R28][EVIDENCE] frame=0   … 命中 0 ｜ 进行中
108:[R28][EVIDENCE] frame=22  … 命中 1 ｜ 进行中
246:[R28][EVIDENCE] frame=171 … 命中 4 ｜ 进行中
284:[R28][EVIDENCE] frame=225 … 命中 4 ｜ 进行中（codex_panel_open=true）
439:[R28][EVIDENCE] frame=449 … 命中 5 ｜ 胜利 · 已落盘
155..273:[R34][INPUT] frame=90..210 每 8 帧注入真实按键 F → request_execution()（窗口由生产削韧链决定，未开则幂等拒绝）
16:[R34][PRESENTATION] 演示驱动已移除：开窗/卡片/读秒/可见层全部由生产运行时真实链路承担；本脚本只保留真实按键注入
```

---

## 3. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① `hd2d_fx.gd` 连击评级反馈层落地（4 信号订阅 / A54 唯一实例 / 五档递进 / S 收束 / 冷夜雾冷却 / `[PLACEHOLDER]`+rationale / 零新增色号 / 移动端不劣化 / 降级层保留）；② `ground_tile.png` 精修：6 色 / 128×128 / alpha {255} / `EDGE_DIFF=0` / 斜条纹周期感明显降低，`courtyard.tscn` uv 零改动（`node_count=41` 实证）；③ 三段门禁 G1/G2/G3 全 `EXIT=0`、`SCRIPT_ERROR=0`、`PARSE_ERROR=0`；④ 15 秒定稿录屏 **450 帧** / MP4 **1,495,542 字节** / 录屏 `SCRIPT ERROR=0`；⑤ G3 与录屏日志双实证 `[R34][ComboFX] 绑定唯一 ComboService 成功 node=FXBloom signals=4`；⑥ 首 / 中 / 尾三帧 + 4 帧联系表按 A41 三判据完成目视并如实写结论（见 §4）；⑦ 回执写入并确认中枢归档（见 §7）。 |
| **失败** | 无（无门禁失败、无 SCRIPT ERROR、无短录、无崩溃）。 |
| **需用户确认** | ① 全部 `[PLACEHOLDER]` 数值（连击反馈各档强度/粒子数/时长、Voronoi 种子数/seed）待人工试玩校准；② 连击反馈 D→A 递进 / S 收束 / 冷夜雾冷却**未在 15 秒录屏中目视覆盖**（见 §4.1 / §6）；③ 破韧开窗 → F 处决窗口**未自然触发**（见 §6）；④ HUD 中部文字重叠（既有，非本轮引入）；⑤ J1 的 10%/25% 缩略图转灰度严格判定未做（本轮按首/中/尾三帧全尺寸目视）；⑥ §9.3 程序化 `_draw()` 用于运行时反馈层的口径差异待裁决（§1①）。 |

---

## 4. A41 三判据与目视结论（首 / 中 / 尾三帧 + 4 帧联系表，ViewImage 实看）

> 采样：`r34_review_1.png`(n=0, 段 A desktop/medium) / `r34_review_2.png`(n=225, **段 B mobile/low 四项全关**) / `r34_review_3.png`(n=449, 段 C desktop/high)；补看 `r34_combo_contact.png`(f=45/130/320/400)。**不得沿用 R31「全绿达成」自评**。

### 4.1 连击评级反馈是否可见（本轮重点核对）

- **可见**：首帧、尾帧、4 帧联系表均可见评级条（`D C B A S` 五档方块 + `N HIT` + 倍率角标），位于右下空地（medium 档）或画面中部偏左（high 档，`stretch_shrink=1` 使既有 FX 层 640×360 逻辑坐标系整体缩放，与 R32 impact_fx / 体积光同现象，**非本层偏移**），未遮挡角色主体、未过曝。命中数随真实链路变化（`0 HIT` / `2 HIT` / `3 HIT`），档位随真实信号更新。
- **中帧（B 段 mobile/low）看不到评级条**：`_all_on=false` → `_draw()` 直接 `return`，连击层零绘制（暖金体积光 / 光尘 / bloom 同步消失，画面偏暗），正是「移动端档位不劣化」的门控实证，非缺陷。
- **未观察到 D→A 递进 / A 档暖金递进 / S 级收束爆发环 / 冷夜雾冷却带**：4 帧联系表与三帧**清一色 D 档高亮**。原因（录屏日志实证）：15 秒 450 帧内真实命中仅 `0→5` 次，且 `f=60/f=220` 受击重置、`timeout_sec=2.5s` 频繁超时、Boss 死亡定格，combo 峰值约 2~3，**从未跨过 `C=4` 门槛**。故反馈层可见且随真实信号更新，但高评级演出在本次演示内未被覆盖。**如实登记，不伪造画面、不回退演示驱动、不擅改 `[PLACEHOLDER]` 数值。**

### 4.2 面板是否遮挡角色 / HUD 文字是否重叠

- **遮挡**：左上「赐福」大面板、右上「画质设置」、中帧「赐福图鉴」面板、尾帧「赐福成长兑换」面板均**未遮住中央像素骑士主体**；但尾帧右侧兑换面板贴近角色右肩、中帧图鉴面板贴近角色左侧，UI 较密集、留白偏紧。
- **HUD 文字重叠（如实登记，非全绿）**：首帧中部「赐福引导 2/3 ｜ 按 Space 翻滚一次」与金色「完成当前 +30 赐福点数…」两行**叠压**；中帧「赐福引导·已完成(3/3)」行与金色奖励文字重叠；尾帧底部同类挤压仍在。此为**既有 HUD 布局问题，本轮未引入**（硬约束不改 `hud.gd` / `presentation.gd`），列为未完成 / 待裁决。

### 4.3 地面重复感 / 暖金收束过曝 / 像素硬边 vs 平滑景深

- **地面重复感**：三帧地面均为新 Voronoi 不规则多边形石板，斜条纹与 4×4 网格消除、平铺接缝不可见；但整 tile 重复为平铺固有、个别长直裂缝仍在 → **「明显降低」而非「完全无重复」**。
- **暖金收束过曝**：三帧暖金体积光 / 光束较亮但**未泛白过曝**（砖面纹理、角色面甲/武器细节仍清晰），常驻暖金与既有 bloom 未糊成一片。**S 级收束爆发因未触发，其「峰值 alpha ≤.18 / 无纯白核心」的无过曝设计未在实机画面目视验证**，如实标注。
- **像素精灵硬边 vs 平滑景深**：成立 —— 中央骑士为硬边像素（1px 深色描边 / Nearest / 有限色板），背景为平滑远山渐变 + 传统深度雾 + 光束 / 光尘层次，暖金 × 冷夜蓝对冲清晰。**但按 A30 口径，这全部是 `CanvasItem._draw()` 的 2D 程序化近似**（同心圆 bloom / `draw_colored_polygon` 光锥 / `draw_rect` 镜像倒影），不是真 DoF / 真体积光 / SSR，不谎称。

### 4.4 A41 三判据（HD2D-STYLE-ANCHOR-v2 §4）逐条判定

| 判据 | 判定 | 依据 |
|---|---|---|
| **J1 缩略图 10% 剪影可读** | **未完全实证（如实）** | 首/中/尾三帧全尺寸目视：骑士 / 盾 / 剑 / 红缨剪影在深蓝地面 + 暖金光束前清晰可辨、主体不黏连背景；但**本轮未做 10%/25% 两级缩略图转灰度的严格判定**，不冒称 J1 通过。 |
| **J2 主体与背景明度差 ≥2 档** | **通过（静态色板 + 画面实证）** | 冷夜雾 `#1B2A4A`(L≈22) / 地面 `#2C4C8C`(L≈45) ↔ 主体暖金 `#C99A3A`(L≈65) / 亮钢 `#E8EDF2`(L≈92)，差 ≈2~4 档；三帧灰度下白面甲 / 剑与深蓝地面明显分离。 |
| **J3 同屏高饱和色 ≤3 种** | **通过（目视）** | 同屏抢眼强调色为暖金（HUD 金线/字/光束）、危险暗红（Boss 披风/红缨）、少量青绿（增益/宝石点缀），⊆ 白名单 `#B33A3A/#C99A3A/#35D0C0` 且 ≤3；其余冷蓝 / 亮钢为受光过渡色不计入。 |
| J5 单帧 ≤16 色 | **通过** | 连击层零新增色号；ground_tile 实测 6 色。 |
| J7 光效不遮 HUD 与角色判定区 | **通过（本层）** | 连击层评级条 / 光尘 / 冷雾带主动避开 HUD `x<365,y<110` 与角色判定区；既有 HUD 文字重叠属其它 Rank 布局（§4.2）。 |

### 4.5 HD-2D 全绿是否达成

> **未达全绿**（如实登记，不沿用 R31「全绿达成」自评，不把 2D 近似包装成全绿）。按 `HD2D-STYLE-ANCHOR-v2.md` §3 差距清单，仍是 **2D 近似**：
>
> | # | 差距 | 本工程现状 |
> |---|---|---|
> | 1 | 真 DoF / 平滑多层虚化 | 2D 分层色带 + 视差 + 传统深度雾（`fog_density=0.02`），无相机后处理 |
> | 2 | 真 `volumetric_fog` | `draw_colored_polygon()×6 + draw_line()` 光锥近似 |
> | 3 | SSR / Planar 湿地倒影 | `draw_rect()` 垂直镜像色块 |
> | 4 | `Environment.glow` 后处理 | `draw_circle()` 同心圆；`glow_enabled=false` |
> | 9 | Forward+ / Vulkan 渲染后端 | 仍 `gl_compatibility`（A30 裁决不切后端，切 `forward_plus` 列 P3 不推荐） |
>
> **已对齐（口径级）**：像素精灵硬边 / 有限色板 / Nearest、暖金主光 × 冷夜雾光色关系、金线深蓝 1px UI。**本轮新增的连击评级反馈层同为 `_draw()` 2D 近似，未新增任何真 3D 光效、未切后端**；README「还差什么」第 2 项（真 HDR bloom / 3D 体积光 / SSR）与第 12 项（HD-2D 全绿未达）**保持未达**。

---

## 5. 未完成项 / 阻塞

- **连击反馈高评级演出未在 15 秒演示内覆盖**：D→A 递进、A 档暖金递进、S 级收束爆发、受击冷夜雾冷却的**画面**未见（原因见 §4.1：真实命中 5 次 + 受击/超时重置，combo 未跨 C=4）。链路与绘制代码已接线（G3 + 录屏日志 `signals=4` 实证），非"未实现"，属"演示未覆盖"。**未回退演示驱动、未改任何 `[PLACEHOLDER]` 数值**。
- **破韧开窗 → F 处决**：录屏日志 F 键在 `f=90..210` 每 8 帧共 16 次真实注入，全部「窗口由生产削韧链决定，未开则幂等拒绝」；**450 帧内处决窗口未自然触发，录屏看不到处决窗口**。按 Rank-1 回报，链路本身由 `verify_production_chains_v110.gd` / `verify_combo_runtime_v110.gd` 实证可达 → **如实写「真实链路已接线但演示未覆盖」**，不为画面好看回退 R33 演示驱动。
- **HUD 中部文字重叠**（既有，§4.2）：非本轮引入，硬约束不改 `hud.gd` / `presentation.gd`，列为待裁决。
- **J1 10% 缩略图严格判定未做**（§4.4），本轮按三帧全尺寸目视，不冒称通过。
- 无阻塞；硬约束内工作已完成。

---

## 6. 待总指挥裁决项（只登记、不擅改）

1. **口径差异（§9.3）**：程序化 `_draw()` 在契约定位为「M0 占位 / 显存不足降级、非正素材路线」，本轮按任务单「以任务单为准」特批用于**运行时视觉反馈层**（非替代正式素材）。请裁决是否需要在 §9.3 / `HD-2D视觉规范.md` 补「运行时反馈层」例外条款，或恢复为纯 ComfyUI 素材路线。
2. **演示覆盖 vs 玩法闭环**：连击 D→A 递进、S 收束、处决窗口均「真实链路已接线但 15 秒演示未覆盖」。是否允许在 `[PLACEHOLDER]` **不擅改**前提下，由 Rank-1 在后续轮次提高真实按键密度 / 延长录屏窗口以覆盖高评级（**不走演示驱动伪造状态**），或维持如实登记。
3. **HUD 文字重叠**：中部「赐福引导」与金色奖励文字叠压（既有），归属 Rank-1 `hud.gd` / 教学 HUD 布局，本轮 Rank-4 不越界修改。
4. **全部 `[PLACEHOLDER]` 校准**：连击反馈 `GLOW/MOTES/BURST/COOLDOWN/LERP/RISE` 与地面 `seeds/seed/core_period`；调参唯一入口 = `hd2d_fx.gd` 常量表与 `ground_tile.import.json`（只改表不改算法）。
5. **S 级爆发 / 冷夜雾冷却的无过曝与观感**：需人工试玩或更长录屏触发高评级后目视校准，本轮未在实机画面验证。
6. **既有 WARNING**（BossController IDLE / ObjectDB leaked）是否纳入后续清理，非本轮引入。
7. **地面 `ground_tile.import.json` 独立登记**：`r23/import.json` 为 impact_fx 专用且被 R32 只读加载，本轮未动；是否统一两资产登记格式由总指挥裁决。

---

## 7. 回执与中枢归档

- 回执写入 Rank-4 授权路径（**`teamwork/command_center/`，非工程根**）：`teamwork/command_center/ai/4/outbox/cmd-20261112-091304-459-A4.json`，四字段 `{"task_id":"cmd-20261112-091304-459-A4","ai":4,"status":"done","result":"引用 DONE-R34.md 实际结论"}`。
- **归档回读确认（写后实测，中枢已运行）**：
  - `ai/4/outbox/` 已清空（回执被中枢移走 → `dispatcher/receipts/`，属中枢正常处理，与 Rank-2 / 其它 AI 一致，不重放、不伪造）。
  - 归档副本 `dispatcher/receipts/cmd-20261112-091304-459-A4.json` 存在（1153 字节），回读 `ARCHIVED_VALID_JSON=True`，四字段 `task_id=cmd-20261112-091304-459-A4 / ai=4 / status=done / result_len=637` 齐全。
  - `dispatcher.log` 尾部原文：`[2026-11-12 11:56:59] ← 4 号 AI 回执 <cmd-20261112-091304-459-A4> 完成：R34 / v0.11.0 完成，实际结论见 teamwork/Rank-4/DONE-R34.md：① 三段门禁 G1`。
  - `ai/4/status.json` 更新为 `{"ai":4,"state":"idle","current_task":"","completed":63,"last_seen":"2026-11-12 11:56:59"}`。

---

## 8. 硬约束遵守声明

- 只写授权文件：`godot/assets/generated/r23/` 下 PNG（`ground_tile.png` 覆盖）与 `import.json`（`ground_tile.import.json` 新增）、`hd2d_fx.gd`、`capture/`、`teamwork/Rank-4/`、回执。
- **未改** `encounter_director.gd` / `hud.gd` / `presentation.gd` / `wave_trial_director.gd` / `courtyard.tscn` 场景节点与 uv / `r23/import.json`（impact_fx 专用）/ 数据表 / 其它 Rank 文件。
- 零付费、零外部依赖（仅本地 Pillow + Godot + 本地 ffmpeg）、不启 GPU job、不引入外部素材生成服务；程序化 `_draw()` 与地面生成均为本地确定性管线。
- 单帧 ≤16 色受控 + 项目级色库 ≥256 两层口径不变（连击层零新增色号）；A54 复用唯一 ComboService、不读私有实现；`[PLACEHOLDER]` 全部标注 rationale + 调参唯一入口。
- 不伪造产物、不谎报成功、不自行 git、未删除 `.workbuddy`；默认不刺探（未扫目录做进度巡检、未写只读探针 / 巡检脚本，仅按任务单有目的地读契约 / 目标文件 / 目视帧）。
- Movie Maker **未加 `--headless`**（A47）；`--write-movie` 绝对路径 + `.png`；ffmpeg 9.x 用 `-fps_mode passthrough`，未用 `-vsync 0`。
