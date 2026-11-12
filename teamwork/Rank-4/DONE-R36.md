# DONE-R36.md · R36 / v0.13.0「专注值与战技 · 画面补齐」交付报告（Rank-4）

> 轮次：`R36 / v0.13.0` ｜ 任务单 id：`cmd-20261112-154132-920-A4` ｜ 执行 AI：`4（Rank-4 美术管线与工具链）`
> 真源：`teamwork/Rank-4/调度任务单-latest.json`（`task` 全文 + 公共契约 + A48 硬要求 + 目录所有权）
>   + `teamwork/Rank-2/DONE-R36.md` §3（FocusService 4 信号/公开方法完整签名）
>   + `teamwork/Rank-4/DONE-R35B.md`（弹反光环历史定位 / 半透明矩形定位 / 总指挥目视纠正口径）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> ffmpeg：`C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`（9.x，`-fps_mode passthrough`，未用 `-vsync 0`）
>
> **一句话结论**：本轮四项任务全部真跑完成 —— ① `hd2d_fx.gd` 落地 A67 光环可见性增强层（暗衬 / 加粗 / 提亮 / 静止读秒刻度 / 余辉延长 / 形态+时间+空间三重避让 R32 `impact_fx`），既有 `PARRY_*` / R35B `[PLACEHOLDER]` 数值与语义逐字不动、全部新增量走独立 `[PLACEHOLDER]` 常量表；② 订阅 Rank-2 `FocusService` 4 个公开信号（A54 唯一实例、A48① 生产运行时订阅者）并程序化 `_draw()` 画 Q 释放冷蓝弹道 / 暖金斩击弧（两战技可区分、短促不过曝）+ 拒绝 / 回满 / 冷却就绪反馈，保留降级开关、移动端轻量绘制（A63）、零新增色号；③ `capture/v130_final.mp4` 15 秒定稿录屏（磁盘 **450 帧连续 0..449** / ffprobe **450 帧 15.000000s** / **1,491,435 字节** / Movie Maker 未加 `--headless` / 录屏前 `--headless --import` / 录屏 `SCRIPT ERROR=0`）；④ A41 首/中/尾 + 弹反开窗/成功/战技释放帧目视 + 三段门禁 + 全工程 G3 `grep SCRIPT ERROR=0` 全绿。
> **A67 核心目标达成情况**：程序化 `_draw()` 金色预兆环 / 成功闪光由「实机不易辨识」提升为「定稿关键帧可辨识」——改前/改后同帧像素证据见 §5；**但最终画面验收由总指挥在定稿录屏关键帧目视确认（A67），代码断言不算画面验收**，本 DONE 的像素统计与目视自评只作证据与登记，不冒充验收结论。
> 如实登记（不沿用 R35 旧自评、不冒称）：HD-2D **全绿未达**（仍是 `CanvasItem._draw()` 2D 程序化近似）；D→A / S 级爆发本录屏未覆盖（最高 D→B）；战技 Q 在 HUD 默认取 `art_ids[0]`，本录屏只释放 `glintstone_pebble`（冷蓝弹道），暖金 `lion_slash` 斩击弧代码路径已实现但本录屏未触发；R35B 定位的半透明浅色大矩形本体仍在（Rank-1 独占只读 `impact_feedback.gd`，非本轮授权）。

---

## 1. 交付清单（实际落地文件）

### 工程脚本（唯一改动，Rank-4 授权）

| 文件 | 改动 | 边界 |
|---|---|---|
| `godot/scripts/hd2d_fx.gd` | 版本头注 ⑪⑫ + R36/A67 `[PLACEHOLDER]` 常量表（约 24 个常量，逐项 rationale）+ 战技层状态 + `_try_bind_focus()` / 4 信号回调 / `_update_focus_timers()` / `_a67_fx_active()` / `_draw_parry_a67()` / `_draw_focus_fx()`；`_ready` / `_process` / `_draw` 三处接线；`_on_parry_window_opened` / `_on_parry_succeeded` / `_on_parry_failed` / `_update_parry_timers` 加余辉计时；`_draw_impact_fx()` 加激活帧时间避让 | **既有 `PARRY_*` / R35B `[PLACEHOLDER]` 常量数值与语义逐字不动**；HUD 文字框 / `hud.gd` / `presentation.gd` / `encounter_director.gd` / `wave_trial_director.gd` / `points_commit_orchestrator.gd` / `project.godot` / `courtyard.tscn` / `impact_feedback.gd` / `hd2d_parallax.gd` / r23 PNG 与 import.json / 数据表一律只读未改 |

### 定稿录屏与中间帧（capture/，Rank-4 授权）

| 文件 | 说明 |
|---|---|
| `capture/v130_final.mp4` | **15 秒定稿成片**：1280×720 / 30fps / 450 帧 15.000000s / **1,491,435 字节** |
| `capture/v130_final00000000.png` … `v130_final00000449.png` | Movie Maker 原始帧 450 张（编号 0..449 连续、无缺失、`contiguous_0_to_449=True`） |
| `capture/r36_a67_before00000000.png` … `...00449.png` | **A67 改前基线帧 450 张**（本轮改动前、同命令同帧率同场景，专门留作改前/改后对比，不与定稿帧混前缀） |
| `capture/r36_a67_tri_f{024,050,148,150,340}.png` | 改前｜改后｜差分×3 三连对比证据图（中央 FX 区裁剪） |
| `capture/r36_final_review_01..08.png` | 从**定稿 MP4** 用 `-fps_mode passthrough` 抽的首/开窗/战技/中/尾目视帧（n=24/30/50/148/150/225/340/440） |
| `capture/r36_review_f{024,030,050,148,225,340,440}.png` | 定稿原始帧另存（全尺寸目视备份） |
| `capture/r36_a67_before_metrics.json` / `r36_a67_compare.log` / `r36_a67_frameloc.log` / `r36_a67_segsum.log` | 全 450 帧 ROI 指标 / 改前改后对比 / 差分帧定位 / 分段汇总（Pillow 像素证据原文） |
| `capture/r36_*_movie.log` / `r36_g1_import.log` / `r36_g2_checkonly.log` / `r36_g3_quit.log` / `r36_final_g3_quit.log` / `r36_ffmpeg.log` / `r36_ffprobe.log` / `r36_final_extract.log` | 录屏 / 三段门禁 / 全工程 G3 / ffmpeg / ffprobe / 抽帧 真跑日志原文 |

### 文档 / 回执

| 文件 | 说明 |
|---|---|
| `teamwork/Rank-4/DONE-R36.md` | 本交付报告 |
| `teamwork/command_center/ai/4/outbox/cmd-20261112-154132-920-A4.json` | 本轮回执（**teamwork/command_center/**，非工程根），中枢归档见 §9 |

---

## 2. 需求 → 实现 → 数值 → 验收拆解

### ① A67 光环可辨识度（核心目标）

既有 `PARRY_*` / R35B `[PLACEHOLDER]` 常量（`PARRY_RING_BASE_R=44.0` / `MIN_R=28.0` / `ALPHA=0.40` / `WIDTH=2.0` / `TICKS=12` / `PARRY_FLASH_SEC=0.36` / `PARRY_FLASH_ALPHA=0.42` / 锚点 `PLAYER=(320,250)` / `BOSS=(386,168)` / 轻量环参数等）**数值与语义逐字不动**，改前基线里环带与紧邻背景亮度差仅 `localC≈4`（不易辨识的量化体现，见 §5）。本轮新增一层 `_draw_parry_a67()` 叠加在 `_draw_parry_fx()` 之上，全部由**新增独立 `[PLACEHOLDER]` 常量表**控制（调参唯一入口，只改表不改算法）：

| 需求 | 实现 | `[PLACEHOLDER]` 常量 + rationale |
|---|---|---|
| 局部亮度对比 | 金环正下方垫冷夜雾 `#16233F` 暗环（宽 3x），把金环从亮石板/角色底上「托」出来 | `A67_RING_UNDERLAY_W=6.0` / `A67_RING_UNDERLAY_ALPHA=0.72`：暗色属既有冷夜雾色号、非纯白不过曝 |
| 对比度 / 线宽 | 加粗金环 + 峰值 alpha 提升 + `#FFF0C2` 外发光细环 + `#BFD0EA` 冷蓝内芯 | `A67_RING_W=4.0`（2x=8px，原 2.0）/ `A67_RING_ALPHA=0.95`（原 0.40）/ `A67_RING_HALO_W=1.5` / `A67_RING_HALO_ALPHA=0.55` / `A67_RING_COLD_INNER_W=2.0` / `_ALPHA=0.60`：不叠乘 FXBloom `#FFF0C2 a=.85` 核心，防过曝 A41 |
| 形态差异化（避误认） | 12 格**静止**读秒刻度（径向 9px 短刻线，3px 粗），R32 impact_fx 是 12fps **循环**同心环 + 十字准星 | `A67_RING_TICK_W=3.0` / `A67_RING_TICK_LEN=9.0` |
| 延长可见帧数 | 主闪 0.36s 逐字保留并叠更亮更粗扩散环；主闪结束后接余辉衰减环（`pow(1-q, DECAY)`），总可辨识帧数 ~11 → ~29 | `A67_FLASH_AFTERGLOW_SEC=0.60` / `A67_FLASH_DECAY=2.2`（**衰减标 `[PLACEHOLDER]` + rationale**：前段保持可辨、后段快速收干净避免拖尾糊画面）/ `A67_FLASH_AFTERGLOW_ALPHA=0.62` / `A67_FLASH_RING_W=4.0` |
| 避让 R32 `impact_fx` 循环帧 | **时间避让**：弹反/战技反馈任一激活帧把 R32 循环帧 alpha `0.32 → 0.32×0.18≈0.06`；**形态避让**（静止刻度环 vs 循环同心环）；**空间避让**（战技锚点在 R32 屏幕区外） | `A67_IMPACT_DODGE_ALPHA=0.18`：`impact_fx_enabled` 开关 / 加载 / 循环逻辑逐字不改，仅绘制时按激活态乘系数 |

### ② 战技视觉反馈

- **A54 唯一实例 / 不自建 / 不读私有实现**：`_try_bind_focus()` 照 R34/R35 同款 `_find_node_with_method(tree.root, "get_focus_service")` 遍历 + `call_deferred` 绑定 + `_process` 自愈（上限 `FOCUS_BIND_MAX_ATTEMPTS=90`），只 connect 4 个**公开信号**，不 new 第二个、不读 `_config` / `_fp` 等私有成员。G3 实证：`[R36][FocusFX] 绑定唯一 FocusService 成功 fx_node=FXBloom getter_owner=Hud signals=4`（HUD 与 WaveTrialDirector 的 `get_focus_service()` 均转调 `wave_trial_director.gd` 装配的唯一实例）。
- **A48① 生产运行时订阅者**：本层即挂 `courtyard.tscn` 的 `FXBloom` 生产节点；真实链路 `presentation.gd` 注入 Q → `hud.gd:2981 request_focus_skill` → `focus_service.spend_fp(art_id)` → `focus_spent` → 本层 `_draw_focus_fx()` 绘制到画面（非验证脚本、非演示驱动、非纯逻辑）。定稿录屏日志实证 **Q 注入 14 / 战技命中 `focus_skill_performed` 13 次**。
- **4 信号回调职责**（签名逐字对齐 `teamwork/Rank-2/DONE-R36.md` §3.1）：
  - `focus_spent(art_id, fp_cost, damage, poise_damage, fp_remaining)` → 起 `FOCUS_FX_SEC=0.42` 主演出：`glintstone_pebble` 画**冷蓝直线弹道**（`#BFD0EA` 主线 + `#4A6089` 拖尾 + `#FFF0C2` 弹头），`lion_slash` 画**暖金大斩击弧**（`draw_arc` -150°→-20°，`#FFD27A`/`#F0A94C`/`#FFF0C2` 三层）——**两战技形态（直线 vs 弧）+ 色相（冷蓝 vs 暖金）双重可区分**。
  - `focus_rejected(art_id, reason)` → 短促冷夜雾暗环（FP 不足 / 冷却中失败反馈）。
  - `focus_restored(fp_before, fp_after, policy)` → 柔和暖金扩散环（赐福休息回满）。
  - `focus_cooldown_ready(art_id)` → 冷蓝小点亮（收起冷却角标 / 图标点亮）。
  - 4 信号任一缺失（Rank-2 并发半成品中间态）→ 不绑定、静默降级，既有层照常、不产生 ERROR。
- **短促不过曝 / 色数 / 降级**：`FOCUS_FX_ALPHA=0.90` 峰值、`pow(1-p,0.8)` 衰减、无纯白大核心、不叠乘 bloom；`FOCUS_MINOR_SEC=0.24` 次级反馈更短。**零新增色号**（脚本内 16 个 hex 全部在既有 `PALETTE_HEX` 内，实测见 §4.7）；单帧 ≤16 色受控 + 项目级 ≥256 色色库两层口径（A15）不变；`@export var focus_fx_enabled: bool = true` 降级开关；未绑定 / 开关关闭 → 整层零绘制。
- **移动端轻量绘制（A63）**：mobile 四项全关档位 `_draw()` 走 `_draw_focus_fx()` 的 `lite` 分支（单条弹道线 / 单条弧 + 弹头，去掉外发光 / 拖尾 / 内层弧），`_process` mobile 分支同样推进战技计时器 + 绑定自愈。

### ③ 15 秒定稿录屏

- 录屏前跑一次 `--headless --import`（`r36_g1_import.log`，含本轮全部接线，`SCRIPT ERROR=0`）；工程收敛无其它 Rank 半成品，无需「等一下再重跑」。
- Movie Maker **未加 `--headless`**（A47，dummy 渲染器 `texture_2d_get` 空纹理崩溃 `0xC0000005`）；`--write-movie F:/Game/aierdengfahuan/capture/v130_final.png`（绝对路径 + `.png` 后缀）。
- 磁盘 **450 帧连续 0..449**（`missing_in_0_449=0` / `contiguous_0_to_449=True` / `extra_beyond_449=0`），引擎自报 `450 frames at 30 FPS (movie length: 00:00:15:00)`，磁盘 / ffprobe / 引擎日志三者一致 → **450 帧达标，未触发「短录清理重跑」**（A62）。
- ffmpeg 9.x `-framerate 30 -start_number 0 -i capture/v130_final%08d.png -c:v libx264 -pix_fmt yuv420p -fps_mode passthrough`（未用 `-vsync 0`），ffprobe 实测 `nb_read_frames=450 / duration=15.000000 / 1280×720 / 30/1`。

---

## 3. 真跑输出原文

命令前缀统一 `D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot ...`；引擎版本行 `Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org`。

### 3.1 A67 改前基线录制（改动前，同命令同帧率，450 帧）

```
--write-movie F:/Game/aierdengfahuan/capture/r36_a67_before.png --fixed-fps 30 --quit-after 450 \
  --script res://test/presentation.gd res://scenes/courtyard.tscn
450 frames at 30 FPS (movie length: 00:00:15:00), recorded in 00:00:37 (40% of real-time speed).
=== movie SCRIPT ERROR === 0       === disk frames === 450
日志实证：波次开始精准弹反开窗=3 / 战技命中=13 / 弹反成功日志=43（含 INPUT 提示文字，真实 [R35][HUD] 弹反成功 |=1）
```

### 3.2 三段门禁（最终统一 `SCRIPT ERROR=0`）

```
=== G1 --headless --import ===            G1_EXIT=0  SCRIPT ERROR=0  PARSE_ERROR=0
=== G2 --check-only --script hd2d_fx.gd ===  G2_EXIT=0  SCRIPT ERROR=0  PARSE_ERROR=0
=== G3 --headless --quit（主场景）===        G3_EXIT=0  SCRIPT ERROR=0  PARSE_ERROR=0
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41
[R35][ParryFX] 绑定唯一 ParryService 成功 node=FXBloom signals=4
[R34][ComboFX] 绑定唯一 ComboService 成功 node=FXBloom signals=4
[R36][FocusFX] 绑定唯一 FocusService 成功 fx_node=FXBloom getter_owner=Hud signals=4（A54 复用 get_focus_service，不自建）
[R36][ENC] 生产装配 | focus_unique_instance=true focus_skill_subscribed=true（A48① 生产运行时订阅者）
全工程 G3 独立复跑：SCRIPT ERROR=0
```

**七份日志统一 grep**（`r36_g1_import` / `r36_g2_checkonly` / `r36_g3_quit` / `r36_a67_before_import` / `r36_a67_before_movie` / `r36_a67_checkonly` / `r36_v130_movie`）：**全部 `SCRIPT ERROR=0` / `PARSE_ERROR=0`**。

### 3.3 15 秒定稿录屏（`capture/v130_final.mp4`）

```
--write-movie F:/Game/aierdengfahuan/capture/v130_final.png --fixed-fps 30 --quit-after 450 \
  --script res://test/presentation.gd res://scenes/courtyard.tscn
MOVIE_EXIT=0
450 frames at 30 FPS (movie length: 00:00:15:00), recorded in 00:00:36 (41% of real-time speed).
CPU render time: 0.44 s (avg 0.98 ms/frame)  GPU render time: 0.32 s (avg 0.72 ms/frame)
Encoding time: 22.66 s (avg 50.36 ms/frame)
=== movie SCRIPT ERROR === 0
disk frames = 450 / min/max = 0 449 / missing_in_0_449 = 0 / contiguous_0_to_449 = True / extra_beyond_449 = 0
movie log: FocusFX 绑定=1 / 战技命中(focus_skill_performed)=13 / 弹反开窗=3 / [R35][HUD] 真实弹反成功=1
```

### 3.4 ffmpeg 9.x 合成与 ffprobe 实测

```
FFMPEG_EXIT=0     === MP4 bytes === 1491435
=== ffprobe ===
width=1280  height=720  r_frame_rate=30/1  duration=15.000000  nb_read_frames=450
抽帧 REVIEW_EXTRACT_EXIT=0（8 帧，-fps_mode passthrough）
```

### 3.5 A38 一致性（只读核对 `courtyard.tscn`，本轮零改动）

```
node 行数 = 41
uv1_scale = ['(2, 2, 1)', '(1, 1, 1)', '(1, 1, 1)']   → 2/1/1
首/末节点名 = Courtyard / TutorialDirector    HD2DFX present = True
```

### 3.6 色数口径（零新增色号，脚本内 hex 实测）

```
脚本内全部 hex 数 = 16
越出既有 PALETTE_HEX 的 hex = 无（零新增色号 ✓）
→ 单帧 ≤16 色受控 + 项目级 ≥256 色色库两层口径（A15）不变
```

---

## 4. A41 三判据与目视结论（按总指挥 R35 目视纠正后口径）

> 采样：从**定稿 MP4** 用 `-fps_mode passthrough` 抽 `r36_final_review_01..08.png`（n=24 弹反开窗 / 30 首 / 50 战技释放 / 148 弹反窗口·D→C / 150 SEG 切换 / 225 SEG-B mobile 中 / 340 尾段暖金 / 440 尾）；另对照改前基线帧、改前/改后三连对比图（`r36_a67_tri_f*`）与差分日志。**不沿用 R35「弹反反馈未能辨识 / HUD 既有重叠」旧自评**。

- **弹反 HUD 文字层清晰可见（总指挥纠正口径，本轮复核一致）**：n=24「精准弹反窗口 0.2s · 按 K」、n=150「精准弹反窗口 0.3s · 按 K」、n=225「弹反成功！+削韧 / +赐福点数 / 连击不断」均清晰可读、位置合适。
- **HUD 无重叠（含新增 FP 条）**：新增「专注值 FP 100/100 ｜ Q 战技 ｜ 赐福休息·FP 回满」（n=24）、「专注值 FP 88/100 ｜ Q 战技 ｜ 冷却中」（n=50）、「专注值 FP 4/100 ｜ Q 战技 ｜ 专注不足」（n=440）全程清晰、与既有赐福引导 / 兑换面板 / 画质面板 / 评级条**无重叠**；R34C 修复保持有效。如实补记：n=225 图鉴 Tab 打开瞬间，弹反成功提示与图鉴正文有局部叠字（既有 Rank-1 只读 HUD 层、非本轮引入、非新增 FP 条），不冒充「每一像素全程无叠字」。
- **A67 金色预兆环 / 成功闪光可辨识（本轮核心改善）**：n=24 画面中央**明显金色粗环 + 暗色衬底 + 白色静止读秒刻度 + 外发光**，改前同帧（`r36_a67_tri_f024` 左）仅有极淡几乎看不出的细环；n=150 右下角金色大环（SEG-B 切换点轻量降级绘制）同样可辨。像素证据见 §5。**此为Rank-4 自评 + 像素证据，最终画面验收由总指挥在定稿录屏关键帧目视确认（A67），代码断言不算画面验收。**
- **战技反馈可见**：Q 释放后冷蓝弹道每 30 帧周期出现（f33/49/79/109/139 冷蓝像素新增 264~489，与 `R36_SKILL_KEY_INTERVAL=30` 吻合），FP 条 `100→88→…` 递减 + 「冷却中 / 专注不足」文本印证；三连差分图 `r36_a67_tri_f050` 右侧明确显示反馈环与弹道差分。如实：本录屏 Q 默认只释放 `glintstone_pebble`（冷蓝弹道），暖金 `lion_slash` 斩击弧代码路径已实现但本次未触发（见 §6）。
- **连击 D→C 已可见（总指挥纠正口径）、D→B 亦可见**：n=148「4 连击 · 评级 C · 倍率 1.15 · 4 HIT x1.15」；n=440「8 连击 · 评级 B · 倍率 1.35 · 8 HIT x1.35」；n=340「3 连击 · 评级 D · 1.00」。**D→A / S 级爆发本录屏未覆盖**（真实命中/受击重置使 combo 未跨 A 门槛），与总指挥纠正结论一致，不伪造。
- **面板不遮挡角色**：赐福成长兑换面板（右）、赐福图鉴 / 画质设置面板（上）均避开中央骑士主体；角色面甲 / 武器 / 动作帧清晰。
- **暖金收束未过曝**：n=340 / n=440 顶部暖金体积光主光可辨、砖面纹理与角色面甲 / 武器细节清晰，无泛白、无纯白大核心（A67 增强层峰值 alpha 受控、不叠乘 bloom 核心）。
- **地面观感（总指挥纠正口径，本轮复核一致）**：八帧地面均为规整错缝轴对齐矩形石板、1px 连贯深色缝、无斜向阶梯锯齿与破碎多边形碎片；相比 R34 Voronoi 破碎裂缝观感提升。整 tile 重复为平铺固有、仍存在（如实）。
- **A59 扣费出口生效（总指挥纠正口径，本轮复核一致）**：n=340 / n=440「赐福成长 ｜ 当前余额 339（点数 448 − 已消费 109）」+「兑换成功：赐福·生命上限（消耗 100，余额 339）」。
- **像素硬边 vs 平滑景深**：中央骑士硬边像素（1px 深色描边 / Nearest / 有限色板）与平滑远山渐变 / 光束 / 光尘层次成立，暖金 × 冷夜蓝对冲清晰；但仍是 `CanvasItem._draw()` 2D 程序化近似。
- **HD-2D 全绿：未达（如实）**。差距清单（真 DoF / 真 `volumetric_fog` / SSR / `Environment.glow` / Forward+ 后端）保持未达；本轮未新增任何真 3D 光效、未切后端、未把 2D 近似包装成全绿。

---

## 5. A67 可见性对比证据（改前 / 改后关键帧像素或区域对比）

### 5.1 对比方法与确定性校验（先证明两次录制可严格逐像素比较）

- **改前基线**：本轮改动**前**用同一命令（`--fixed-fps 30 --quit-after 450 --script presentation.gd courtyard.tscn`）录的 450 帧 `capture/r36_a67_before*.png`；**改后**：定稿 450 帧 `capture/v130_final*.png`。两者唯一差异是 `hd2d_fx.gd` 本轮改动，场景 / 输入注入 / 帧率 / 数据表完全一致。
- **确定性校验（背景角落逐像素差）**：远离 FX 的左下 / 右下背景角落在 f0/75/225/375/449 两次录制 `mean|Δ|=0.00`（`r36_a67_compare.log` §1）——证明除本轮绘制外画面确定性，改前/改后可严格同帧对比。
- **如实登记噪声源**：`_draw()` 内 `Time.get_ticks_msec()` 驱动的光尘上飘 / 倒影波纹 / R32 `impact_fx` 12fps 循环帧相位在两次录制间不同，全帧差分含此分量（`r36_a67_segsum.log`：三段各 150/150 帧有差分、累计变化像素 SEG-A 843,712 / SEG-B 263,443 / SEG-C 910,921，SEG-C 差分 bbox 止于 y=362，与 R35B「high 档 FX 缩到左上 1/4」一致）。**因此 A67 结论不靠全帧差分总量，而靠不受 `t` 影响的环带 ROI 统计量 + 同帧三连目视对比图 + 背景 Δ=0 确定性校验三者交叉印证**。

### 5.2 关键帧区域像素对比（`r36_a67_compare.log` §3，改前 → 改后）

环带 ROI = 屏幕 `(640,500)` 中心、半径 50~96px（`PARRY_RING_ANCHOR_PLAYER=(320,250)` ×2 后）；`gold`=暖金高亮像素数（R>150 且 R−B>45 且 G−B>10），`std`=亮度标准差（局部亮度对比），`peak`=峰值亮度。

| 帧 | 事件 | 环带 gold 改前→改后 | 环带 std 改前→改后 | 环带 peak 改前→改后 |
|---|---|---|---|---|
| **f21** | **弹反开窗（A67 增强峰值）** | **2947 → 6528（+121%）** | **42.1 → 49.7（+18%）** | **212 → 228** |
| f4 | 非开窗对照 | 2157 → 2157（无变化） | 41.1 → 41.1 | 205 → 205 |
| f30 | 战技 Q 段 | 1486 → 1490 | 39.9 → 39.9 | 196 → 196 |
| f148 | 弹反窗口·D→C | 1746 → 1746 | 42.7 → 42.7 | 206 → 206 |
| f150 | 成功 / SEG 切换 | 1329 → 1329 | 39.1 → 39.1 | 188 → 188 |

- **开窗连续帧环带 `mean|Δ`（`r36_a67_frameloc.log`）**：f21=37.5 / f22=39.7 / f23=41.2 / f24=41.9 / f25=41.9（A67 开窗环 5 帧连续生效），对照非开窗帧普遍 `≤2.4`；全帧变化像素 f21-25 = 16118 / 19735 / 18572 / 15112 / 14986（`r36_a67_segsum.log`）。
- **量级自洽**：加粗金环周长 `2π×r(≈70px 屏幕) × 线宽(8px) ≈ 3500 px`，与 f21 环带暖金像素 `+3581` 高度吻合——证明新增像素来自加粗金环 / 暗衬 / 刻度，而非背景相位噪声（背景角落 Δ=0）。
- **局部亮度对比提升**：暗衬 `#16233F a=.72` 垫底 + 金环 `#F0A94C a=.95` 提亮，环带亮度标准差 42.1→49.7、峰值 212→228。

### 5.3 改前 / 改后关键帧目视对比图（`capture/r36_a67_tri_f024.png`，裁剪中央 FX 区）

- **左（改前 BEFORE f24）**：中央骑士周围仅极淡、几乎与背景融为一体的细金环。
- **中（改后 AFTER f24）**：**清晰金色粗环 + 暗色衬底轮廓 + 白色静止读秒刻度 + 外发光亮环**，环从亮石板上被「托」出，1280×720 全尺寸下明确可辨识。
- **右（差分 DIFF×3）**：精确显示圆环轮廓 + 刻度点差分，与环带 ROI 位置完全对应，证明像素差异来自 A67 绘制而非背景。
- 另 `r36_a67_tri_f050.png`（战技 Q 段）差分图显示冷蓝反馈环 / 弹道轮廓；`r36_a67_tri_f148/f150/f340` 留档。

### 5.4 延长可见帧数 / 避让 R32 循环帧 的像素证据

- **延长可见帧数**：成功弹反主闪 `PARRY_FLASH_SEC=0.36`（~11 帧）逐字保留，主闪结束后接 `A67_FLASH_AFTERGLOW_SEC=0.60`（~18 帧）`pow(1-q,2.2)` 衰减余辉环，总可辨识 ~11→~29 帧；`_update_parry_timers` 仅在 `_parry_flash_left<=0` 后推进余辉、不与主闪叠乘过曝。像素侧：成功闪光差分 TOP 帧 f21/34/35/65/94/95/125/37 呈 30 帧周期（与 Q/弹反节奏吻合，`r36_a67_frameloc.log`）。
- **避让 R32 `impact_fx` 循环帧**：`_a67_fx_active()` 激活帧把 R32 循环帧 alpha `0.32→~0.06`，impact 区（屏幕 x400-592 / y300-492）`mean|Δ|` 在 f0/14/17/29/46/87/90/106 等帧为 9.4~13.2（`r36_a67_frameloc.log`），证明时间避让真实生效；R32 层本身只读未改、`impact_fx_enabled` 开关与 12fps 循环逻辑逐字保留。

> **A67 验收声明（任务单硬要求）**：以上为 Rank-4 的改前/改后像素与区域对比证据 + 自评审视，**最终画面验收由总指挥在定稿录屏关键帧目视确认（A67），代码断言不算画面验收**。本 DONE 不冒称已通过总指挥验收。

---

## 6. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① A67 增强层落地（暗衬 / 加粗 / 提亮 / 静止刻度 / 余辉延长 + 衰减 `[PLACEHOLDER]`/rationale / 形态+时间+空间三重避让 R32），既有 `PARRY_*`/R35B `[PLACEHOLDER]` 数值语义逐字不动、零新增色号、单帧 ≤16 色 / 项目 ≥256 色不变；② 战技层订阅 FocusService 4 信号（A54 唯一实例 / A48① 生产订阅者 / 不自建 / 不读私有实现），冷蓝弹道 / 暖金斩击弧两战技可区分、短促不过曝，降级开关 + mobile 轻量（A63）；③ 定稿录屏 450 帧连续 0..449 / ffprobe 450 帧 15.000000s / 1,491,435 字节 / Movie Maker 未加 `--headless`（A47）/ 录屏前 `--headless --import` / 录屏 `SCRIPT ERROR=0`；④ 三段门禁 + 全工程 G3 `grep SCRIPT ERROR=0` / `PARSE_ERROR=0`（7 份日志全绿）；⑤ A38 节点 41 / uv 2/1/1 / 节点名不变（`courtyard.tscn` 零改动）；⑥ A62 磁盘连续编号 + ffprobe 帧数口径；⑦ A41 首/中/尾 + 弹反开窗/成功/战技释放帧目视（按总指挥纠正口径）完成；⑧ **A67 改前/改后关键帧像素或区域对比证据**（§5，含背景 Δ=0 确定性校验 / f21 环带 gold +121% / std +18% / 三连对比图）；⑨ 回执写入并确认中枢归档（§9）。 |
| **失败 / 未达** | ① **HD-2D 全绿未达**（仍 `CanvasItem._draw()` 2D 程序化近似，差距清单保持，A30 如实写「未达」）；② **D→A / S 级连击爆发本录屏未覆盖**（最高 D→B），与总指挥纠正结论一致；③ **暖金 `lion_slash` 斩击弧本录屏未触发**（HUD 默认 `art_ids[0]=glintstone_pebble` 冷蓝，代码路径已实现）；④ **R35B 定位的半透明浅色大矩形本体仍在中景**（根因在 Rank-1 独占只读 `impact_feedback.gd`，非本轮授权，如实留档不冒称消除）；⑤ 若干 `[PLACEHOLDER]` 数值未经人工试玩校准（调参唯一入口已给出）。 |
| **需用户确认 / 待裁决** | 见 §7。 |

---

## 7. 未完成项 / 待总指挥裁决项（只登记、不擅改）

1. **A67 最终画面验收**：按任务单，**由总指挥在定稿录屏 `capture/v130_final.mp4` 关键帧（建议 n=24 弹反开窗 / n=150 开窗 / n=50 战技释放）目视确认「金色预兆环与成功闪光可辨识」**；本 DONE 的像素统计与 Rank-4 自评不算画面验收。
2. **暖金战技未覆盖**：HUD `request_focus_skill()` 默认取 `get_art_ids()[0]`（`hud.gd:2898`，Rank-1 独占只读），本录屏 Q 只释放 `glintstone_pebble`（冷蓝弹道）。请裁决是否由 Rank-1 增加战技切换键（如数字键切 `lion_slash`）以便在实机录屏覆盖暖金斩击弧；Rank-4 两战技视觉代码已可区分、不越界改 HUD / 数据表。
3. **半透明浅色大矩形本体消除**（沿用 R35B §7.1）：请授权把 `godot/scripts/render/impact_feedback.gd`（R31 打击反馈层）纳入可写范围或派单 Rank-1 改局部闪光 / 降峰值 alpha / 缩短衰减。本轮只做了 R32 `impact_fx` 循环帧的**时间避让**（在弹反/战技激活帧降权），未消除 R31 大矩形本体，不冒称。
4. **D→A / S 级爆发覆盖**：演示 `presentation.gd`（Rank-1 只读）尾段 J 注入密度已增强（R36），本录屏最高 D→B；如需覆盖 S 级收束爆发请裁决是否调整注入节奏（不改本层）。
5. **全部 `[PLACEHOLDER]` 校准**：`A67_RING_*` / `A67_FLASH_*` / `A67_IMPACT_DODGE_ALPHA` / `FOCUS_FX_*` / `FOCUS_MINOR_*` / 战技锚点 `FOCUS_BOLT_*` / `FOCUS_ARC_*` 及既有 R34/R35/R35B 常量，调参唯一入口 = `hd2d_fx.gd` 常量表（只改表不改算法），待人工试玩校准。
6. **J1 10%/25% 缩略图转灰度严格判定**未做（本轮按八帧全尺寸目视 + ROI 像素统计），不冒称 J1 通过。
7. **R19 `verify_fx_mobile.gd` 口径**：R35B 起 mobile 档 `FXBloom` 保持 `visible` 画轻量环，该脚本（Rank-1 只读）旧断言「mobile 4 节点 visible 全 false」不再成立；本轮未改、未跑该脚本，沿用 R35B §7.2 待裁决。
8. **§9.3 程序化 `_draw()` 口径差异**：契约把 `_draw()` 定位「M0 占位 / 显存不足降级」，本层按任务单「以任务单为准」用于运行时视觉反馈层，沿用 R35/R35B 登记，请裁决是否补例外条款。
9. **A65~A68 新裁决由 Rank-3 登记**（任务单目录所有权），Rank-4 不越界写协作契约。

---

## 8. A48 硬要求 / 公共契约落地声明（逐条）

| 条目 | 落地 | 证据 |
|---|---|---|
| A48① 新信号必须有**生产运行时订阅者** | 本层（挂 `courtyard.tscn` 的 FXBloom 生产节点）connect FocusService 4 信号并有真实绘制职责；真实 Q → HUD → spend_fp → focus_spent → 画面 | G3 日志 `[R36][FocusFX] 绑定... signals=4`；定稿录屏 `战技命中=13`；冷蓝弹道差分每 30 帧周期 |
| A48② 遵守 A54 唯一实例 | `get_focus_service()` 复用 wave 装配的唯一实例，HUD / wave getter 均转调同一实例，绝不 new 第二个、不读私有实现 | G3 `[R36][FocusFX] ... getter_owner=Hud signals=4` + `[R36][HUD] focus_unique_instance=true ... 不自建第二实例` |
| A48③ 一条不加载 `presentation.gd`、不在验证脚本内模拟编排的真实可达回归 | G3 `--headless --quit` 主场景真跑（真实 autoload、不加载 presentation.gd）实证生产装配；定稿录屏是「真实输入→生产链路→画面」实机证据 | `r36_g3_quit.log` 装配日志 + node_count=41；`r36_v130_movie.log` 13 次 Q 命中 + 冷蓝弹道像素 |
| A48④ 纯逻辑 + 单元断言不算可玩交付 | 本轮交付为**实机 15 秒录屏 + 目视回看**，非纯逻辑 / 单元断言 | `capture/v130_final.mp4` 450 帧 + §4 A41 目视 |
| 不新建只读探针 / 巡检脚本 | 本轮未新建任何 .gd 探针 / 巡检脚本；像素对比用工程外一次性 Pillow 分析（`capture/` 日志与图留档） | 交付清单仅改 `hd2d_fx.gd` + capture 产物 |
| 三段门禁 grep `SCRIPT ERROR=0` | G1 import → G2 check-only → G3 quit + 全工程 G3 独立复跑，7 份日志全绿 | §3.2 |
| 零付费 / 零外部依赖 / 不启 GPU job | 仅本地 Godot 4.7.2 + 本地 ffmpeg 9.x + 本地 Pillow 12.3.0 像素分析 | — |
| A47 Movie Maker 禁 `--headless` | 定稿录屏命令未带 `--headless` | §3.3 |
| A62 帧数以磁盘连续编号 + ffprobe 为准 | 磁盘 450 连续 + ffprobe 450 / 15.000000s，三者一致，未触发短录重跑 | §3.3 / §3.4 |
| A63 移动端轻量绘制 | mobile 档战技层 `lite` 分支（单条弹道 / 弧），`_process` 同步推进计时/绑定 | §2② |
| 不伪造产物 / 不谎报成功 / 不自行 git / 不删 `.workbuddy` | 全绿 / 未达 / 未覆盖项如实登记，未 git、未删目录 | 全文 |

---

## 9. 回执与中枢归档

- 回执写入 Rank-4 授权路径（**`teamwork/command_center/`，非工程根**）：
  `teamwork/command_center/ai/4/outbox/cmd-20261112-154132-920-A4.json`，
  四字段 `{"task_id":"cmd-20261112-154132-920-A4","ai":4,"status":"done","result":"引用 DONE-R36.md 实际结论"}`。
- **中枢归档回读确认（写后实测，如实登记、不伪造）**：
  - `ai/4/outbox/` 写后已被中枢清空（回执移入 `dispatcher/receipts/`，属中枢正常处理，与 R34/R35/R35B 一致，不重放、不伪造）。
  - 归档副本 `teamwork/command_center/dispatcher/receipts/cmd-20261112-154132-920-A4.json` 存在（**2052 字节**），回读 **VALID_JSON**，四字段齐全：`keys=['ai','result','status','task_id']` / `task_id=cmd-20261112-154132-920-A4` / `ai=4` / `status=done` / `result_len=1064`，与回执逐字一致。
  - `ai/4/status.json` 更新为 `{"ai":4,"state":"idle","current_task":"","completed":67,"last_seen":"2026-11-12 17:47:03"}`（`completed` 66 → 67、`state` working → idle、`current_task` 清空）。
  - `dispatcher/dispatcher.log` 尾部原文：`[2026-11-12 17:47:03] ← 4 号 AI 回执 <cmd-20261112-154132-920-A4> 完成：R36/v0.13.0 完成，实际结论见 teamwork/Rank-4/DONE-R36.md…`（回收 `done`）。
  - `dispatcher/ledger.jsonl` 本任务单登记：`status=done` / `finished_at=2026-11-12 17:47:03` / `result` 与回执逐字一致；派单 `issued_at=2026-11-12 15:41:33` 与任务单一致。
  - 注：本轮中枢归档副本文件名为 `receipts/<id>.json`（非 `receipt_<id>.json` 前缀），`status.json` / `ledger.jsonl` / `dispatcher.log` 三处均实证回收；如实登记，不臆造文件名。

---

## 10. 硬约束遵守声明

- **只写授权文件**：`godot/scripts/hd2d_fx.gd`（唯一改动的工程脚本）、`capture/`（定稿成片 / 450 帧 / 改前基线 450 帧 / 目视帧 / 三连对比图 / 日志 / 像素证据）、`teamwork/Rank-4/DONE-R36.md`、回执。
- **只读未改**：`hud.gd` / `presentation.gd` / `encounter_director.gd` / `wave_trial_director.gd` / `points_commit_orchestrator.gd` / `project.godot` / `courtyard.tscn`（A38 节点 41 / uv 2/1/1 / 节点名不变）/ `impact_feedback.gd` / `hd2d_parallax.gd` / `v070_depth_grade.gdshader` / r23 下 PNG 与 `import.json` / 全部数据表 / 其它 Rank 产出。
- **HUD 文字框逐字未动**；未越界篡改其它 Rank 的运行时节点 / 状态；未改场景节点 / uv / 数据表 / `[PLACEHOLDER]` 数值语义。
- 默认不刺探：未扫目录做进度巡检、未新建只读探针 / 巡检脚本、未反复核对文件状态；读取仅限任务单指定契约文件、接线所必需的生产源码、目标帧与根因定位。
- 按总指挥 R35 目视纠正后口径写 DONE：弹反 HUD 文字层清晰可见、HUD 无重叠（含新增 FP 条）、连击 D→C（及 D→B）已可见、地面规整错缝石板、A59 扣费出口生效、HD-2D 全绿未达 —— **不沿用 R35「弹反反馈未能辨识 / HUD 既有重叠」旧自评**。
- **最终画面验收由总指挥在定稿录屏关键帧目视确认（A67），代码断言不算画面验收** —— 本 DONE 的像素统计与目视自评只作证据与登记。
