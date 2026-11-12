# DONE-R37.md · R37 / v0.14.0「元素瓶与死亡轮回 · 画面补齐」交付报告（Rank-4）

> 轮次：`R37 / v0.14.0` ｜ 任务单 id：`cmd-20261112-184157-094-A4` ｜ 执行 AI：`4（Rank-4 美术管线与工具链）`
> 真源：`teamwork/Rank-4/调度任务单-latest.json`（`task` 全文 + 公共契约 + A48 硬要求 + 目录所有权）
>   + `teamwork/Rank-2/DONE-R37.md` §3（FlaskService / DeathService 信号完整签名）
>   + `teamwork/Rank-4/DONE-R36.md`（A67 经验 / 狮子斩弧现状 / 总指挥 R35/R36 目视口径）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> ffmpeg：`C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`（9.x，`-fps_mode passthrough`，未用 `-vsync 0`）
>
> **一句话结论**：四项任务全部真跑完成 —— ① `hd2d_fx.gd` 落地 **A72 狮子斩暖金大斩击弧可见性增强层**（半径 52→88 逻辑px / 线宽 4→10 / 峰值 alpha 0.95 / 冷夜雾宽暗衬 / 三层暖金 + 弧末端火花 / 余辉衰减 `[PLACEHOLDER]`+rationale 延长可见帧数 / 与冷蓝弹道形态+色相双重区分 / 时间+形态+空间三重避让 R32 `impact_fx` 循环帧与 A67 弹反金环），既有 `FOCUS_*` / `A67_*` / `PARRY_*` 常量数值与语义逐字不动、全部新增量走独立 `[PLACEHOLDER]` 常量表；② 订阅 Rank-2 `FlaskService` 3 + `DeathService` 4 共 7 个公开信号（A54 唯一实例、A48① 生产运行时订阅者），程序化 `_draw()` 加翠绿/暖金回复光晕、死亡冷夜雾收束 + 分块压暗、赐福重生暖金扩散环；③ `capture/v140_final.mp4` **15 秒定稿录屏**（磁盘 **450 帧连续 0..449** / ffprobe **450 帧 15.000000s** / **1,678,119 字节** / Movie Maker **未加 `--headless`**（A47）/ 录屏前 `--headless --import` / 录屏 `SCRIPT ERROR=0`）；④ A41 首/中/尾 + 狮子斩释放/元素瓶/死亡重生帧目视 + 三段门禁 + 全工程 G3 `grep SCRIPT ERROR=0` 全绿。
>
> **A72 核心目标达成情况（如实、不冒充）**：**SEG-A（f61~f72，狮子斩释放段）暖金大斩击弧由「改前几乎不可辨」提升为「定稿关键帧明确可辨识」** —— 改前/改后同帧像素证据见 §4（外环带暖金高亮像素 f61 4756→6858 / f64 4757→11588(+144%) / f68 5476→15883(+190%)、局部亮度对比 std 49.1→54.9、背景角落 Δ≈0 确定性校验、三连对比图目视确认粗金弧 + 暗衬 + 差分弧形轮廓）。**但 SEG-C（f301 附近，high 画质档）弧仍不可辨识**：该档 FX 逻辑 640×360 坐标缩到屏幕左上 1/4（R35B 已登记），全帧差分 bbox 止于 y≈358、中央 ROI 暖金几乎无增量、左上 ROI 仅见暗衬压暗（gold −511）与弹反小环，目视三连图无大弧 —— 如实登记为 **未覆盖 / 受限**，不冒充「全段可辨识」，列为 §7 待裁决。
> **最终画面验收由总指挥在定稿录屏关键帧目视确认（A72），代码断言不算画面验收** —— 本 DONE 的像素统计、日志实证与 Rank-4 自评审视只作证据与登记，不冒充验收结论。
>
> **如实登记（不沿用旧自评、不冒称）**：HD-2D **全绿未达**（仍是 `CanvasItem._draw()` 2D 程序化近似）；D→A / S 级连击爆发本录屏未覆盖（最高 D）；**死亡压暗 / 重生扩散环链路已接线但演示未覆盖**（本录屏 HP 从未归零，日志无 `death_occurred` / `respawn_performed` 触发行）；元素瓶仅 f60 成功 1 次（3→2 / HP 88→100），其余 8 次 G 均 `full_hp` 拒绝；R35B 定位的半透明浅色大矩形本体仍在中景（Rank-1 独占只读 `impact_feedback.gd`，非本轮授权）。

---

## 1. 交付清单（实际落地文件）

### 工程脚本（唯一改动，Rank-4 授权）

| 文件 | 改动 | 边界 |
|---|---|---|
| `godot/scripts/hd2d_fx.gd` | 版本头注 ⑬⑭ + **R37/A72 独立 `[PLACEHOLDER]` 常量表**（约 22 个常量，逐项 rationale）+ **R37 生命轮回独立 `[PLACEHOLDER]` 常量表**（约 20 个常量）+ 状态字段 + `_try_bind_flask()` / `_try_bind_death()` / 7 信号回调 / `_update_life_timers()` / `_a72_arc_active()` / `_life_fx_active()` / `_draw_lion_slash_a72()` / `_draw_life_fx()`；`_on_focus_spent` 启动余辉、切换战技收干净；`_a67_fx_active()` 纳入 A72 余辉 + 生命轮回；`_draw_parry_a67()` 加 `dodge` 降权；`_ready` / `_process`（desktop + mobile）/ `_draw`（desktop + mobile）四处接线 | **既有 `FOCUS_*` / `A67_*` / `PARRY_*` / `PARRY_RING_ANCHOR_*` / R35B `[PLACEHOLDER]` 常量数值与语义逐字不动**；既有 `_draw_focus_fx()` 的 R36 小弧逐字不动（A72 为叠加增强层）；HUD 文字框 / `hud.gd` / `presentation.gd` / `encounter_director.gd` / `wave_trial_director.gd` / `points_commit_orchestrator.gd` / `project.godot` / `courtyard.tscn` / `impact_feedback.gd` / `hd2d_parallax.gd` / r23 PNG 与 `import.json` / 数据表一律只读未改 |

### 定稿录屏、改前基线、对比证据与目视帧（`capture/`，Rank-4 授权）

| 文件 | 说明 |
|---|---|
| `capture/v140_final.mp4` | **15 秒定稿成片**：1280×720 / 30fps / 450 帧 15.000000s / **1,678,119 字节** |
| `capture/v140_final00000000.png` … `v140_final00000449.png` | Movie Maker 原始帧 450 张（编号 0..449 连续、无缺失、`contiguous_0_to_449=True`） |
| `capture/r37_a72_before00000000.png` … `...00449.png` | **A72 改前基线帧 450 张**（本轮改动前、同命令同帧率同场景，专门留作改前/改后对比，不与定稿帧混前缀） |
| `capture/r37_a72_tri_f{061,064,068,070,300,303,306,310}.png` | **改前｜改后｜差分×3 三连对比证据图**（SEG-A 中央 FX 区 / SEG-C 左上区裁剪） |
| `capture/r37_final_review_01..14.png` | 从**定稿 MP4** 用 `-fps_mode passthrough` 抽的首/中/尾 + 狮子斩释放/元素瓶/赐福帧目视（n=0/24/61/64/68/105/150/225/246/301/303/340/430/449） |
| `capture/r37_a72_compare.log` / `r37_a72_segc_loc.log` / `r37_life_jade_frameloc.log` / `r37_a72_before_gold_scan.log` / `r37_color_audit.log` | A72 改前/改后 ROI 指标、SEG-C 弧落点定位、翠绿光晕与可见帧数曲线、改前暖金扫描、色数口径（Pillow 像素证据原文） |
| `capture/r37_g0_import_precheck.log` / `r37_g1_import.log` / `r37_g2_checkonly.log` / `r37_g3_quit.log` / `r37_final_g3_quit.log` | 三段门禁 + 全工程 G3 独立复跑真跑日志原文 |
| `capture/r37_a72_before_movie.log` / `r37_v140_movie.log` / `r37_ffmpeg.log` / `r37_ffprobe.log` / `r37_final_extract.log` | 改前基线录制 / 定稿录屏 / ffmpeg 合成 / ffprobe / 抽帧 真跑日志原文 |

### 文档 / 回执

| 文件 | 说明 |
|---|---|
| `teamwork/Rank-4/DONE-R37.md` | 本交付报告 |
| `teamwork/command_center/ai/4/outbox/cmd-20261112-184157-094-A4.json` | 本轮回执（**`teamwork/command_center/`**，非工程根），中枢归档见 §10 |

---

## 2. 需求 → 实现 → 数值 → 验收拆解

### ① A72 狮子斩暖金斩击弧可辨识度（核心目标）

改前 R36 弧：`FOCUS_ARC_R=52` 逻辑px（2x 后 104 屏幕px）、`FOCUS_FX_ARC_W=4.0`（8px）、`FOCUS_FX_ALPHA=0.90`、无暗衬、仅 `FOCUS_FX_SEC=0.42`（~13 帧）。改前实测弧区（矩形 ROI x520..920 / y240..580）暖金像素 f61=13576，而**非弧对照帧 f30=15346** —— 弧的暖金增量淹没在既有暖金地面 / 体积光里，正是总指挥「抽取第 61/301 帧未见大范围暖金斩击弧」的量化体现。

本轮按 A67 同法新增一层 `_draw_lion_slash_a72()` 叠加在 `_draw_focus_fx()` 之上（既有小弧逐字不动，形成「内层细节弧 + 外层大弧」嵌套），全部由**新增独立 `[PLACEHOLDER]` 常量表**控制（调参唯一入口，只改表不改算法）：

| 需求 | 实现 | `[PLACEHOLDER]` 常量 + rationale |
|---|---|---|
| 大范围 | 半径 52→88 逻辑px（176 屏幕px，覆盖画面中央大片区域），扇形张角 -150°→-20° 扩为 -160°→-10° | `A72_ARC_CENTER=(360,206)` / `A72_ARC_R=88.0` / `FROM=-160°` / `TO=-10°` / `SWEEP_GAIN=1.5`：扇形有开口，与冷蓝细直线弹道 / A67 全圆读秒环 / R32 循环同心环形态度区分 |
| 局部亮度对比 | 暖金弧正下方垫冷夜雾 `#16233F` 宽暗衬（16.0 逻辑px，主线 1.6x） | `A72_ARC_UNDERLAY_W=16.0` / `A72_ARC_UNDERLAY_ALPHA=0.70`：暗色属既有冷夜雾色号、非纯白不过曝；把暖金从亮石板 / 体积光暖金底上「托」出来 |
| 对比度 / 线宽 | 主弧 4.0→10.0 逻辑px（2x 后 8→20px）、峰值 alpha 0.90→0.95；三层暖金 `#FFD27A` 主 / `#F0A94C` 内 / `#FFF0C2` 外发光细环 | `A72_ARC_W=10.0` / `A72_ARC_ALPHA=0.95` / `INNER_W=3.0` / `INNER_ALPHA=0.80` / `HALO_W=2.0` / `HALO_ALPHA=0.55`：仍非纯白、不叠乘 FXBloom `#FFF0C2 a=.85` 核心，防过曝 A41 |
| 形态二次区分 | 弧末端亮核 + 径向短火花线（vs 冷蓝弹头小圆点） | `A72_ARC_SPARK_LEN=16.0` / `SPARK_W=3.0` / `HEAD_R=6.0` |
| **延长可见帧数** | 主段 `FOCUS_FX_SEC=0.42` 逐字保留并叠本层峰值（峰值保持 `0.60+0.40*(1-p)`）；主段结束后接 `A72_ARC_AFTERGLOW_SEC=0.78`（~23 帧）余辉衰减环 `pow(1-q, DECAY)`、半径随 q 外扩 16px | **`A72_ARC_AFTERGLOW_SEC=0.78` / `A72_ARC_DECAY=1.8` / `A72_ARC_AFTERGLOW_ALPHA=0.55` / `AFTERGLOW_W=3.0` / `AFTERGLOW_GROW=16.0`** —— **衰减标 `[PLACEHOLDER]` + rationale**：指数 1.8 = 前段保持可辨、后段快速收干净，避免拖尾糊画面 / 过曝；余辉只用低 alpha 暖金细环、无纯白核心、不叠乘 bloom；设计总可辨识 ~13 → ~36 帧（**实测**外环带增量 >1000 连续 14 帧 f61~f74 + 余辉弱段 f75~f80/83/86，如实不夸大） |
| 与冷蓝「辉石魔砾」双重区分 | 形态（大扇形弧 vs 细直线弹道）+ 色相（暖金 3 层 vs 冷蓝 `#BFD0EA`/`#4A6089`）；`_on_focus_spent` 在切回 `glintstone_pebble` 时立即把暖金余辉 `_a72_arc_afterglow_left` 清零，不混色 | 既有 `_draw_focus_fx()` 冷蓝分支逐字不动 |
| 避让 R32 `impact_fx` 循环帧 | **时间避让**：`_a67_fx_active()` 纳入 `_a72_arc_afterglow_left` / `_life_fx_active()`，激活帧按既有 `A67_IMPACT_DODGE_ALPHA=0.18` 把循环帧 alpha 0.32→~0.06；`impact_fx_enabled` 开关 / 加载 / 循环逻辑逐字不改 | 既有 `A67_IMPACT_DODGE_ALPHA=0.18` 常量数值不动 |
| 避让弹反金色环 | **时间避让**：`_draw_parry_a67()` 开窗增强环运行时乘 `A72_PARRY_RING_DODGE_ALPHA=0.28`（既有 `A67_*` 常量数值逐字不动，仅绘制时乘系数，与 A67 对 impact_fx 同构）；**形态避让**（扇形弧 + 火花 vs 全圆静止读秒刻度环）；**空间避让**（弧中心 360,206 与弹反环锚点 320,250 / R32 屏幕区错开） | `A72_PARRY_RING_DODGE_ALPHA=0.28` |

### ② 生命轮回视觉反馈

- **A54 唯一实例 / 不自建 / 不读私有实现**：`_try_bind_flask()` / `_try_bind_death()` 照 R34/R35/R36 同款 `_find_node_with_method(tree.root, "get_flask_service" / "get_death_service")` 遍历 + `call_deferred` 绑定 + `_process` 自愈（上限 `LIFE_BIND_MAX_ATTEMPTS=90`），只 connect 公开信号、不 new 第二个、不读 `_flasks` / `_is_dead` 等私有成员。G3 与定稿录屏日志实证：`[R37][LifeFX] 绑定唯一 FlaskService 成功 fx_node=FXBloom getter_owner=Hud signals=3` / `DeathService ... signals=4`（HUD 与 WaveTrialDirector 的 getter 均转调 `wave_trial_director.gd` 装配的唯一实例）。
- **A48① 生产运行时订阅者**：本层即挂 `courtyard.tscn` 的 `FXBloom` 生产节点；真实链路 G → HUD/ENC → `flask_service.use_flask()` → `flask_used` → 本层 `_draw_life_fx()` 绘制到画面（非验证脚本、非演示驱动、非纯逻辑）。7 信号任一缺失（Rank-2 并发半成品）→ 不绑定、静默降级、既有层照常、不产生 ERROR。
- **7 信号回调职责**（签名逐字对齐 `teamwork/Rank-2/DONE-R37.md` §3.1 / §3.6）：
  - `flask_used(flask_before, flask_after, hp_before, hp_after, healed)` → 起 `LIFE_HEAL_SEC=0.60` 回复光晕：**翠绿 `#6FBF8E` 内核 + 暖金 `#FFD27A` 外环 + `#FFF0C2` 细环**（短促扩散 16→64 逻辑px）。
  - `flask_rejected(reason, flask_remaining)` / `action_rejected(reason, action_id)` → `LIFE_MINOR_SEC=0.30` 冷夜雾小暗环（无瓶 / 满血 / 死亡期间行动等失败反馈）。
  - `flask_restored(flask_before, flask_after, policy)` → 暖金小环（赐福休息补满）。
  - `death_occurred(dropped_points, grace_points_snapshot)` → `LIFE_DEATH_SEC=1.10` **冷夜雾收束**（3 圈由 150→60 逻辑px 向角色收拢的粗暗环）+ **画面压暗**（分块 L 形避开 HUD 矩形 + HUD 区按 `LIFE_HUD_DIM_RATIO=0.35` 极淡压暗；峰值 `LIFE_DEATH_DIM_ALPHA=0.26` 不过黑、深色 `#16233F` 压暗而非 R35B 浅暖金提亮大三角）。
  - `respawn_performed(pending_dropped_points)` → 清死亡压暗 + 起 `LIFE_RESPAWN_SEC=0.90` **暖金扩散环**（20→92 逻辑px）。
  - `points_reclaimed(points, grace_points_snapshot)` → 亮金小环（一次性回收，Rank-4 不再结算）。
- **短促不过曝 / 色数 / 降级**：回复 / 重生环峰值 alpha ≤0.85、无纯白大核心、不叠乘 bloom；`@export var a72_fx_enabled: bool = true` + `@export var life_fx_enabled: bool = true` 两个降级开关；未绑定 / 开关关闭 → 整层零绘制。
- **移动端轻量绘制（A63）**：mobile 四项全关档 `_draw()` 仍走 `_draw_lion_slash_a72()` 的 `lite` 分支（暗衬 + 单主弧、去外发光 / 内层 / 火花）与 `_draw_life_fx()` 的 `lite` 分支（收敛环层数 3→1、去次级细环）；`_process` mobile 分支同样推进绑定自愈 + `_update_life_timers()`。

### ③ 15 秒定稿录屏

- 录屏前跑一次 `--headless --import`（`r37_g1_import.log`，含本轮全部接线，`SCRIPT ERROR=0`）；G3 实证四路 Rank 均已收敛（`[R37][HUD]` / `[R37][ENC]` / `[R37][WaveTrial]` / `[R37][PCO]` 装配日志齐全），无半成品，无需「等一下再重跑」。
- Movie Maker **未加 `--headless`**（A47，dummy 渲染器 `texture_2d_get` 空纹理崩溃 `0xC0000005`）；`--write-movie F:/Game/aierdengfahuan/capture/v140_final.png`（绝对路径 + `.png` 后缀）。
- 磁盘 **450 帧连续 0..449**（`missing_in_0_449=0` / `contiguous_0_to_449=True` / `extra_beyond_449=0`），引擎自报 `450 frames at 30 FPS (movie length: 00:00:15:00)`，磁盘 / ffprobe / 引擎日志三者一致 → **450 帧达标，未触发「短录清理重跑」**（A62）。
- ffmpeg 9.x `-framerate 30 -start_number 0 -i capture/v140_final%08d.png -c:v libx264 -pix_fmt yuv420p -fps_mode passthrough`（未用 `-vsync 0`），ffprobe 实测 `nb_read_frames=450 / duration=15.000000 / 1280×720 / 30/1`。

---

## 3. 真跑输出原文

命令前缀统一 `D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot ...`；引擎版本行 `Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org`。

### 3.1 录屏前工程预检 + 三段门禁 + 全工程 G3（最终统一 `SCRIPT ERROR=0`）

```
=== G0 --headless --import（改前基线录制前预检）===   G0_EXIT=0  SCRIPT ERROR=0  PARSE_ERROR=0
=== G1 --headless --import（录屏前，含本轮全部接线）=== G1_EXIT=0  SCRIPT ERROR=0  PARSE_ERROR=0
=== G2 --check-only --script res://scripts/hd2d_fx.gd === G2_EXIT=0  SCRIPT ERROR=0  PARSE_ERROR=0
=== G3 --headless --quit-after 90（主场景）===       G3_EXIT=0  SCRIPT ERROR=0  PARSE_ERROR=0
=== 全工程 G3 独立复跑 --headless --quit-after 60 ===  FINAL_G3_EXIT=0  SCRIPT ERROR=0
```

七份日志统一 grep（`r37_g0_import_precheck` / `r37_g1_import` / `r37_g2_checkonly` / `r37_g3_quit` / `r37_a72_before_movie` / `r37_v140_movie` / `r37_final_g3_quit`）：

```
  r37_g0_import_precheck.log   SCRIPT_ERROR=0 PARSE_ERROR=0
  r37_g1_import.log            SCRIPT_ERROR=0 PARSE_ERROR=0
  r37_g2_checkonly.log         SCRIPT_ERROR=0 PARSE_ERROR=0
  r37_g3_quit.log              SCRIPT_ERROR=0 PARSE_ERROR=0
  r37_a72_before_movie.log     SCRIPT_ERROR=0 PARSE_ERROR=0
  r37_v140_movie.log           SCRIPT_ERROR=0 PARSE_ERROR=0
  r37_final_g3_quit.log        SCRIPT_ERROR=0 PARSE_ERROR=0
  === 全部 r37 日志 SCRIPT ERROR 总行数 === 0
  === G3 非 SCRIPT ERROR 的 ERROR 行 === (none)
```

### 3.2 G3 主场景实证（A54 / A48① 生产装配，不加载 `presentation.gd`）

```
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41
[R35][WaveTrial] 精准弹反生产订阅者已装配：ParryService 唯一实例 + 4 信号 connect（A48①/A54）
[R36][WaveTrial] 专注值/战技生产订阅者已装配：FocusService 唯一实例 + 4 信号 connect（A48①/A54）
[R37][WaveTrial] 元素瓶生产订阅者已装配：FlaskService 唯一实例 + 3 信号 connect（A48①/A54）
[R37][WaveTrial] 死亡轮回生产订阅者已装配：DeathService 唯一实例 + 4 信号 connect（A48①/A54）
[R37][PCO] A70/A71 生产订阅者已绑定 FlaskService + DeathService 唯一实例 | signals=7
[R37][HUD] 生产装配 | flask_unique=true death_unique=true grace_subscribed=true（A48①/A54，不自建第二实例）
[R34][ComboFX] 绑定唯一 ComboService 成功 node=FXBloom signals=4（A54 复用 get_combo_service，不自建）
[R35][ParryFX] 绑定唯一 ParryService 成功 node=FXBloom signals=4（A54 复用 get_parry_service，不自建）
[R36][FocusFX] 绑定唯一 FocusService 成功 fx_node=FXBloom getter_owner=Hud signals=4（A54 复用 get_focus_service，不自建）
[R37][LifeFX] 绑定唯一 FlaskService 成功 fx_node=FXBloom getter_owner=Hud signals=3（A54 复用 get_flask_service，不自建）
[R37][LifeFX] 绑定唯一 DeathService 成功 fx_node=FXBloom getter_owner=Hud signals=4（A54 复用 get_death_service，不自建）
[R37][ENC] 生产装配 | flask_unique=true death_unique=true flask_signal_subscribed=true（A48① 生产运行时订阅者）
```

### 3.3 A72 改前基线录制（改动前，同命令同帧率，450 帧）

```
--write-movie F:/Game/aierdengfahuan/capture/r37_a72_before.png --fixed-fps 30 --quit-after 450 \
  --script res://test/presentation.gd res://scenes/courtyard.tscn
BEFORE_MOVIE_EXIT=0
450 frames at 30 FPS (movie length: 00:00:15:00), recorded in 00:01:01 (24% of real-time speed).
=== movie SCRIPT ERROR === 0       === disk frames === 450
```

### 3.4 15 秒定稿录屏（`capture/v140_final.mp4`）

```
--write-movie F:/Game/aierdengfahuan/capture/v140_final.png --fixed-fps 30 --quit-after 450 \
  --script res://test/presentation.gd res://scenes/courtyard.tscn   （未加 --headless，A47）
MOVIE_EXIT=0
450 frames at 30 FPS (movie length: 00:00:15:00), recorded in 00:01:05 (23% of real-time speed).
=== movie SCRIPT ERROR === 0
disk frames = 450 / min/max = 0 449 / missing_in_0_449 = 0 / contiguous_0_to_449 = True / extra_beyond_449 = 0
```

### 3.5 ffmpeg 9.x 合成与 ffprobe 实测

```
FFMPEG_EXIT=0     === MP4 bytes === 1678119
=== ffprobe ===
width=1280  height=720  r_frame_rate=30/1  duration=15.000000  nb_read_frames=450
抽帧 REVIEW_EXTRACT_EXIT=0（14 帧，-fps_mode passthrough）
```

### 3.6 生产链路日志实证（定稿录屏）

```
[R36B][INPUT] frame=45/165/285/405 真实按键 R → request_art_switch()
[R36B][HUD] R 切换战技 | index=1/2 art=lion_slash 当前战技：狮子斩
[R36][ENC] 战技生产消费 | skill=lion_slash fp 53->53 cost=35 dmg=45 poise=40.0（A48① 生产订阅者）
[R36][HUD] 真实 Q → 战技命中 | art=lion_slash ... → focus_skill_performed 已发
    focus_skill_performed 命中总数 = 10（含 glintstone_pebble / lion_slash 两战技）
[R37][INPUT] frame=60 真实按键 G → request_flask_use() → A54 唯一 flask_service
[R37][ENC] 元素瓶生产消费 | 瓶 3->2 HP 88->100 → _player_hp=100.0（A57 原样采信服务最终值）
[R37][HUD] 真实 G → 元素瓶成功 | 瓶 3->2 HP 88->100 → flask_used 已发
[R37][ENC] 元素瓶拒绝生产记录 | reason=full_hp flask=2/3（f105/150/195/240/285/330/375/420 共 8 次，满血拒绝不扣瓶）
[R37][INPUT] frame=246/430 真实按键 E(interact) → ENC._grace_rest() → grace_rested（赐福补满瓶）
[R37][LifeFX] 绑定唯一 FlaskService 成功 ... signals=3（A54）
[R37][LifeFX] 绑定唯一 DeathService 成功 ... signals=4（A54）
★ 死亡 / 重生：全日志无 player_died / death_occurred / respawn_performed 触发行
  → 本录屏 HP 从未归零，死亡压暗 / 重生扩散环【链路已接线但演示未覆盖】，如实登记不冒充
```

### 3.7 A38 一致性（只读核对 `courtyard.tscn`，本轮零改动）

```
node 行数 = 41
uv1_scale = ['Vector3(2, 2, 1)', 'Vector3(1, 1, 1)', 'Vector3(1, 1, 1)']   → 2/1/1
首/末节点名 = Courtyard / TutorialDirector    HD2DFX present = True
```

### 3.8 色数口径（`r37_color_audit.log`，工程外一次性 Pillow 分析）

```
脚本内唯一 hex 总数 = 17
PALETTE_HEX 受控板色数 = 16（逐字不动）
越出受控板的运行时内联 hex = ['#6FBF8E']（= 项目 256 色色库 colors[31] 既有翠绿）
palette_256.json md5 = 83fb5a5143ae1697ae2de415ae53f1d5（本轮零改动，项目级 >=256 色色库不变）
```

---

## 4. A72 可见性对比证据（改前 / 改后关键帧像素或区域对比）★ 任务硬要求

### 4.1 对比方法与确定性校验（先证明两次录制可严格逐像素比较）

- **改前基线**：本轮改动**前**用同一命令（`--fixed-fps 30 --quit-after 450 --script presentation.gd courtyard.tscn`）录的 450 帧 `capture/r37_a72_before*.png`；**改后**：定稿 450 帧 `capture/v140_final*.png`。两者唯一差异是 `hd2d_fx.gd` 本轮改动，场景 / 输入注入 / 帧率 / 数据表完全一致。
- **确定性校验（背景角落逐像素差）**：远离 FX 的左下 / 右下 / 右上背景角落在 f0/30/61/75/150/225/301/375/449 两次录制 `mean|Δ| = 0.01~0.15`（`r37_a72_compare.log` §1）——证明除本轮绘制外画面确定性，改前/改后可严格同帧对比。
- **如实登记噪声源**：`_draw()` 内 `Time.get_ticks_msec()` 驱动的光尘上飘 / 倒影波纹 / R32 `impact_fx` 12fps 循环帧相位在两次录制间不同，全帧差分含此分量；**故 A72 结论不靠全帧差分总量，而靠不受 `t` 影响的环带 ROI 统计量 + 同帧三连目视对比图 + 背景 Δ≈0 确定性校验 + 逐帧增量曲线四者交叉印证**。
- **ROI 定义**（屏幕坐标，逻辑→屏幕 ×2）：A72 大弧中心 `(720,412)`、半径 176px；**外环带 r150~205**（A72 大弧 + 16.0 逻辑px 暗衬 + 外发光），**内环带 r92~120**（既有 R36 小弧位置）。`gold`=暖金高亮像素（`R>150 且 R−B>45 且 G−B>10`），`dark`=冷夜雾暗衬像素，`std`=亮度标准差（局部亮度对比），`peak`=峰值亮度。判据逐字沿用 `DONE-R36.md` §5.2。

### 4.2 关键帧区域像素对比（`r37_a72_compare.log` §2，改前 → 改后）

| 帧 | 事件 | 外环带 gold 改前→改后 | 外环带 std 改前→改后 | 外环带 peak | 内环带 gold（既有弧） |
|---|---|---|---|---|---|
| **f61** | **总指挥精准抽取帧 / 狮子斩起弧** | **4756 → 6858（+44%）** | **49.1 → 52.0** | 243 → 243 | 3014 → 3075 |
| f62 | 大弧展开 | 4745 → 8456（+78%） | 49.1 → 53.7 | 243 → 243 | 3336 → 3482 |
| **f64** | **弧峰值（弧展开完整）** | **4757 → 11588（+144%）** | **49.0 → 54.9（+12%）** | 243 → 243 | 3857 → 4113 |
| **f68** | **弧峰值 TOP** | **5476 → 15883（+190%）** | 49.4 → 53.2 | 243 → 243 | — |
| f70 / f72 | 峰值保持段 | 4725 → 14654（+210%） / 4661 → 13258 | 48.9 → 51.2 / 49.3 → 50.2 | 243 | — |
| f75 / f80 | 余辉收束 / 收干净 | 5042 → 5856 / 5125 → 5327 | 49.8 → 50.6 / 49.8 → 50.3 | 243 | — |
| **f301** | **总指挥精准抽取帧（SEG-C high 档）** | **2969 → 2985（几乎无变化）** | 41.3 → 41.3 | 245 → 245 | **2278 → 2278（完全不变）** |

- **量级自洽**：A72 加粗主弧周长 `扇形张角 150° × π/180 × r(176px 屏幕) ≈ 460px`，叠加线宽 20px + 暗衬 32px + 外发光 → 外环带新增暖金像素 f64 +6831 / f68 +10407，与「大范围加粗弧 + 暗衬 + 三层暖金」高度吻合；背景角落 Δ≈0 证明新增像素来自 A72 绘制而非背景相位噪声。
- **局部亮度对比提升**：暗衬 `#16233F a=.70` 垫底 + 金环 `#FFD27A a=.95` 提亮，外环带亮度标准差 49.0→54.9、峰值保持 243（未过曝、无纯白核心）。

### 4.3 改前 / 改后关键帧目视对比图（`capture/r37_a72_tri_f061/f064/f068/f070.png`，裁剪中央 FX 区）

- **左（改前 BEFORE f64）**：角色周围仅有极淡、几乎与背景融为一体的细弧；可见的是 A67 弹反金色读秒环（深色同心圆），**没有大范围暖金斩击弧**。
- **中（改后 AFTER f64）**：**清晰的大范围暖金色粗弧形光带**（从角色左上向右上展开的扇形大弧，带亮金边缘 + 深色暗衬轮廓 + 弧末端亮核），1280×720 全尺寸下明确可辨识；定稿全尺寸帧 `v140_final00000064.png` 目视同样确认。
- **右（差分 DIFF×3）**：精确显示**粗弧形 / 扇形轮廓**（粉黄青混合差分），与外环带 ROI 位置完全对应，证明像素差异来自 A72 绘制而非背景。

### 4.4 延长可见帧数 / 避让 / 既有弧不动 的像素证据

- **延长可见帧数（`r37_life_jade_frameloc.log` §9）**：外环带暖金增量（改后−改前）逐帧 `f61:+2102 → f68:+10407 → f72:+8597 → f73:+1505 → f75:+814 → f80:+202 → f81:-41`；增量 >1000 的**连续可辨识主段 14 帧（f61~f74）**，增量 100~1000 的**余辉/收束段 f75~f80/83/86**，f81 起回基线（收干净、不拖尾）。改前 R36 小弧仅 ~13 帧且增量淹没在背景里；改后高亮 14 帧 + 余辉弱段约 6 帧，**如实登记实测值，不把设计值 ~36 帧冒充实测**。
- **既有弧逐字不动**：内环带 r92~120 在 SEG-C f301/303/304 的 gold / dark / std **完全不变**（2278→2278 / 4977→4977），证明 A72 是叠加增强层、未改 R36 既有弧。
- **避让 R32 `impact_fx` 循环帧**：`_a67_fx_active()` 纳入 A72 余辉 + 生命轮回，激活帧把循环帧 alpha 0.32→~0.06；R32 层本身只读未改、`impact_fx_enabled` 开关与 12fps 循环逻辑逐字保留。
- **避让弹反金色环**：`_draw_parry_a67()` 开窗增强环在 `_a72_arc_active()` 帧乘 `dodge=0.28` 降权（既有 `A67_*` 常量数值逐字不动）；f064 三连图改后中央弹反读秒环明显淡于改前，未与暖金大弧抢画面。

### 4.5 SEG-C（f301，总指挥第二抽取帧）弧仍不可辨识 —— 如实登记

- **中央 ROI**：f301 外环带 gold 2969→2985、std 41.3→41.3、peak 245→245，几乎无变化。
- **左上 ROI**（`r37_a72_segc_loc.log` §5）：SEG-C high 档 FX 逻辑 640×360 缩到屏幕左上 1/4（R35B 已登记），在中心 (360,206) / r68~108 统计，f301~f304 gold **反而 −460~−511**（冷夜雾暗衬压暗了背景暖金），f309~f312 +108（弱余辉）；**没有大范围暖金弧增量**。
- **全帧差分 bbox**（§6）：SEG-A f61~f72 差分 `x0..1273, y0..719`（全屏，2x 放大）；SEG-C f300~f330 差分 `x0..1279, y0..358`（**只上半部 / 止于 y≈360**），与 R35B「high 档 FX 缩到左上 1/4」一致。
- **目视三连图**（`r37_a72_tri_f300/f303/f306/f310.png`，裁剪左上区）：改前 / 改后均只见 HUD 文字框（赐福·啜泣海岸）+ 弹反金色小圆环 + 评级条 + 水平亮线（画质档位差异），**无大范围暖金弧**；差分主要是小圆环与散点。
- **结论**：A72 弧在 SEG-A 明确可辨识（核心改善达成）；在 SEG-C 因 **high 画质档对 FX 层的坐标缩放 + 该区被 HUD 面板覆盖** 仍不可辨识，**如实登记为未覆盖 / 受限，不冒充「第 301 帧已可辨识」**，归属与修复口径列 §7 待裁决。

### 4.6 生命轮回反馈客观像素证据

- **翠绿回复光晕（`r37_life_jade_frameloc.log` §8）**：翠绿像素（`G>R+20 且 G>B+20 且 G>110`）在元素瓶 f60 使用后 `f61 +896 / f62 +1048 / f63 +1112 / f64 +1036 / f65 +876 / f66 +362 / f68 +306`，f70 起衰减回基线 —— 证明 `#6FBF8E` 翠绿内核光晕**真实渲染**（暖金弧 / 冷夜雾暗衬不产生 G 最大的像素），与日志 `flask_used(3→2, HP 88→100)` 一一对应。
- **拒绝 / 补满反馈**：f105 等 `flask_rejected(full_hp)` 触发冷夜雾小暗环、f246/f430 赐福 E `flask_restored` 触发暖金小环（链路接线 + G3 装配日志实证）。
- **死亡压暗 / 重生扩散环**：**本录屏未触发**（HP 从未归零，日志无 `death_occurred` / `respawn_performed`），如实登记「链路已接线但演示未覆盖」，不伪造画面证据。

> **A72 验收声明（任务单硬要求）**：以上为 Rank-4 的改前/改后像素与区域对比证据 + 自评审视，**最终画面验收由总指挥在定稿录屏关键帧目视确认（A72），代码断言不算画面验收**。本 DONE 不冒称已通过总指挥验收。

---

## 5. A41 三判据与目视结论（按总指挥 R35 / R36 目视纠正后口径）

> 采样：从**定稿 MP4** 用 `-fps_mode passthrough` 抽 `r37_final_review_01..14.png`（n=0 首 / 24 / 61 狮子斩+元素瓶 / 64 弧峰值 / 68 / 105 元素瓶拒绝 / 150 中 / 225 中 / 246 赐福 / 301·303 SEG-C / 340 / 430 赐福 / 449 尾），另对照改前基线帧、三连对比图与差分日志。**不沿用 R35「弹反反馈未能辨识 / HUD 既有重叠」旧自评**。

- **弹反金色粗环明显可辨（A67 通过，总指挥口径，本轮复核一致）**：f0 / f61 / f225 角色周围金色粗环 + 暗衬 + 静止读秒刻度清晰，A67 增强层保持有效；A72 弧激活帧按 `dodge` 降权不与大弧抢画面。
- **HUD 无重叠（含新增「元素瓶 N/M」显示）**：f0「元素瓶 3/3 ｜ G 使用」、f61「元素瓶 2/3 ｜ G 使用 ｜ 元素瓶·回复 12 HP」、f449「元素瓶 3/3 ｜ G 使用 ｜ 赐福休息·元素瓶补满」全程清晰可读，与赐福引导 / 兑换面板 / 画质面板 / 评级条 / FP 条**无重叠**；R34C 修复保持有效。如实补记：f225 图鉴 Tab 打开瞬间，弹反成功提示与图鉴正文有**局部叠字**（既有 Rank-1 只读 HUD 层、非本轮引入、非新增元素瓶条，沿用 `DONE-R36.md` §4 口径），不冒充「每一像素全程无叠字」。
- **R 战技切换文字可见 / FP 条状态齐全（总指挥口径）**：f0「当前战技：辉石魔砾」、f61/f64「当前战技：狮子斩」、f449「当前战技：辉石魔砾」可见；FP 条 `100/100 → 53/100 冷却中 → 76/100 弹反·免伤 → 100/100 赐福休息·FP 回满` 状态齐全。
- **暖金斩击弧是否可辨识（A72）**：**SEG-A f61/f64/f68 明确可辨识**（大范围暖金粗弧 + 暗衬 + 亮金边 + 差分弧形轮廓，§4）；**SEG-C f301/f303 仍不可辨识**（high 档 FX 缩放 + HUD 覆盖，§4.5 如实登记）。最终画面验收由总指挥目视确认，代码断言不算画面验收。
- **生命轮回反馈是否可见**：元素瓶回复光晕（翠绿内核 + 暖金外环）f61~f68 可见（翠绿像素 +896~+1112 客观证据）；拒绝 / 补满轻反馈链路接线；**死亡冷夜雾收束 + 压暗 / 重生暖金扩散环本录屏未覆盖**（HP 从未归零），如实登记。
- **连击是否出现 D→A 或 S 级爆发**：**未出现**。f0「0 HIT · 评级 D」、f225「3 连击 · 评级 D · 倍率 1.00」、f449「1 连击 · 评级 D · 倍率 1.00」，评级条全程 D 高亮；与总指挥 R35/R36 纠正结论一致，不伪造。
- **面板是否遮挡角色**：赐福成长兑换面板（右）、赐福图鉴（f225 左中）、画质设置面板（右上）均避开中央骑士主体；角色面甲 / 武器 / 动作帧清晰。
- **暖金收束是否过曝**：f64 / f340 / f449 顶部暖金体积光主光可辨、砖面纹理与角色面甲 / 武器细节清晰，**无泛白、无纯白大核心**（A72 峰值 alpha 受控、不叠乘 bloom 核心；生命轮回压暗为深色低 alpha 非提亮）。
- **地面观感（总指挥口径，本轮复核一致）**：各帧地面均为规整错缝轴对齐矩形石板、1px 连贯深色缝、无斜向阶梯锯齿与破碎多边形碎片；整 tile 重复为平铺固有、仍存在（如实）。
- **A59 扣费出口生效**：f449「赐福成长 ｜ 当前余额 1213（点数 1322 − 已消费 109）」可辨。
- **像素硬边 vs 平滑景深**：中央骑士硬边像素（1px 深色描边 / Nearest / 有限色板）与平滑远山渐变 / 光束 / 光尘层次成立，暖金 × 冷夜蓝对冲清晰；但仍是 `CanvasItem._draw()` 2D 程序化近似。
- **HD-2D 全绿：未达（如实）**。差距清单（真 DoF / 真 `volumetric_fog` / SSR / `Environment.glow` / Forward+ 后端）保持未达；本轮未新增任何真 3D 光效、未切后端、未把 2D 近似包装成全绿。

---

## 6. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① A72 增强层落地（大范围 / 暗衬 / 加粗 / 三层暖金 / 末端火花 / 余辉衰减 `[PLACEHOLDER]`+rationale / 形态+时间+空间三重避让 R32 与 A67 弹反环），既有 `FOCUS_*`/`A67_*`/`PARRY_*` 数值语义逐字不动、R36 既有小弧零改动（内环带 ROI 逐像素不变）；② 生命轮回层订阅 FlaskService 3 + DeathService 4 共 7 信号（A54 唯一实例 / A48① 生产运行时订阅者 / 不自建 / 不读私有实现），翠绿+暖金回复光晕 / 死亡压暗 / 重生扩散环 + 拒绝/补满/回收轻反馈，降级双开关 + mobile 轻量（A63）；③ 定稿录屏 450 帧连续 0..449 / ffprobe 450 帧 15.000000s / **1,678,119 字节** / Movie Maker 未加 `--headless`（A47）/ 录屏前 `--headless --import` / 录屏 `SCRIPT ERROR=0`；④ 三段门禁 + 全工程 G3 独立复跑，7 份日志全 `SCRIPT ERROR=0` / `PARSE_ERROR=0`；⑤ A38 节点 41 / uv 2/1/1 / 首末节点名不变（`courtyard.tscn` 零改动）；⑥ A62 磁盘连续编号 + ffprobe 帧数口径，450 帧达标未触发短录重跑；⑦ A41 首/中/尾 + 狮子斩释放/元素瓶/死亡重生帧目视（按总指挥纠正口径）完成；⑧ **A72 改前/改后关键帧像素或区域对比证据**（§4，含背景 Δ≈0 确定性校验 / f61 +44% · f64 +144% · f68 +190% / std 49→55 / 三连对比图 / 逐帧增量曲线）；⑨ 生命轮回翠绿光晕像素证据（f61~f68 +896~+1112）；⑩ 回执写入并确认中枢归档（§10）。 |
| **失败 / 未达** | ① **HD-2D 全绿未达**（仍 `CanvasItem._draw()` 2D 程序化近似，A30 如实写「未达」）；② **A72 SEG-C（high 画质档，总指挥第 301 帧）暖金弧仍不可辨识**（FX 坐标缩到左上 1/4 + HUD 覆盖，§4.5），不冒充全段可辨识；③ **死亡压暗 / 重生扩散环链路已接线但演示未覆盖**（本录屏 HP 从未归零）；④ **D→A / S 级连击爆发本录屏未覆盖**（最高 D）；⑤ **R35B 半透明浅色大矩形本体仍在中景**（根因在 Rank-1 独占只读 `impact_feedback.gd`，非本轮授权，如实留档不冒称消除）；⑥ 若干 `[PLACEHOLDER]` 数值未经人工试玩校准（调参唯一入口已给出）；⑦ 元素瓶 450 帧内仅 f60 成功 1 次，其余 8 次满血拒绝（由 FlaskService 权威判定，不构造状态），回复光晕覆盖帧有限。 |
| **需用户确认 / 待裁决** | 见 §7。 |

---

## 7. 未完成项 / 待总指挥裁决项（只登记、不擅改）

1. **A72 最终画面验收**：按任务单，**由总指挥在定稿录屏 `capture/v140_final.mp4` 关键帧（建议 n=61 / 64 / 68 狮子斩弧峰值，及 n=301 / 303 SEG-C 对照）目视确认「暖金大斩击弧可辨识」**；本 DONE 的像素统计与 Rank-4 自评不算画面验收，**代码断言不算画面验收**。
2. **SEG-C（high 画质档）弧不可辨识的归属与修复口径**：R35B 已登记 high 档 `shrink=1` 使 FX 逻辑 640×360 坐标缩到屏幕左上 1/4、且该区被 HUD 面板覆盖；`hd2d_fx.gd` 全部既有 FX 均用固定逻辑坐标（非本轮引入）。请裁决是否由 Rank-1 调整画质档位对 FX 层的缩放映射，或授权 Rank-4 让 A72 弧锚点按视口尺寸自适应（涉及 `quality_settings` / `courtyard.tscn` 只读边界，本轮不越界）。
3. **死亡 / 重生演示覆盖**：`presentation.gd`（Rank-1 独占只读）本轮 E 赐福注入只给「HP 曾归零则重生」的机会，实跑 HP 恒未归零 → 死亡压暗 / 重生扩散环未触发。请裁决是否由 Rank-1 调整注入节奏使一次死亡真实发生，以目视验收 b)/c) 两项；Rank-4 链路（7 信号订阅 + 绘制 + G3 装配实证）已就绪。
4. **D→A / S 级爆发覆盖**：演示尾段 J/K 密度已增强（R36/R37），本录屏最高 D；如需覆盖 S 级收束爆发请裁决是否调整注入节奏（不改本层）。
5. **色数口径差异（如实登记，不冒充全绿）**：本轮受控 16 色板 `PALETTE_HEX` 逐字不动、项目 256 色色库 `palette_256.json` md5 零改动；翠绿 `#6FBF8E` 为**项目 256 色色库 colors[31] 既有色号**的运行时内联引用（非零新增色库颜色）。**脚本内唯一 hex 由 16 → 17**（`r37_color_audit.log`）。若按 `DONE-R36.md` §3.6 最严格口径「脚本内 hex 总数 ≤16 = 单帧 ≤16 色受控」判定，则本项 +1 属口径差异，请裁决「单帧实际出现颜色数 ≤16」与「脚本内 hex 总数 ≤16」两种口径取其一；按前者（翠绿仅在元素瓶回复光晕帧出现、不与 A72 弧峰值帧所有层满色叠加）成立。
6. **全部 `[PLACEHOLDER]` 校准**：`A72_*` / `LIFE_*` 及既有 R34/R35/R35B/R36 常量，调参唯一入口 = `hd2d_fx.gd` 本轮两块常量表（只改表不改算法），待人工试玩校准。
7. **R35B 半透明浅色大矩形本体消除**：请授权把 `godot/scripts/render/impact_feedback.gd`（R31 打击反馈层，Rank-1 独占只读）纳入可写或派单 Rank-1；本轮只做了 R32 `impact_fx` 循环帧的时间避让（A67 同法扩展），未消除 R31 大矩形本体，不冒称。
8. **J1 10% / 25% 缩略图转灰度严格判定**未做（本轮按 14 帧全尺寸目视 + ROI 像素统计），不冒称 J1 通过。
9. **R19 `verify_fx_mobile.gd` 口径**：R35B 起 mobile 档 `FXBloom` 保持 `visible` 画轻量环，该脚本（Rank-1 只读）旧断言「mobile 4 节点 visible 全 false」不再成立；本轮未改、未跑，沿用 R35B §7.2 待裁决。
10. **A70~A73 新裁决由 Rank-3 登记**（任务单目录所有权），Rank-4 不越界写协作契约。
11. **§9.3 程序化 `_draw()` 口径差异**：契约把 `_draw()` 定位「M0 占位 / 显存不足降级」，本层按任务单「以任务单为准」用于运行时视觉反馈层，沿用 R35/R35B/R36 登记，请裁决是否补例外条款。

---

## 8. A48 硬要求 / 公共契约落地声明（逐条）

| 条目 | 落地 | 证据 |
|---|---|---|
| A48① 新信号必须有**生产运行时订阅者** | 本轮**不定义新信号**；订阅的是 Rank-2 既有 7 个公开信号，订阅者 = 挂 `courtyard.tscn` 的 `FXBloom` 生产节点，有真实绘制职责；真实 G → HUD/ENC → `use_flask` → `flask_used` → 画面，非验证脚本 / 非演示驱动 | G3 + 定稿录屏 `[R37][LifeFX] 绑定唯一 FlaskService ... signals=3` / `DeathService ... signals=4`；`flask_used(3→2, HP 88→100)` 日志 + 翠绿像素 f61~f68 |
| A48② 遵守 A54 唯一实例 | `_try_bind_flask()` / `_try_bind_death()` 经 `get_flask_service()` / `get_death_service()` 从导演层复用唯一实例（`getter_owner=Hud`，HUD 与 WaveTrialDirector getter 均转调同一实例），绝不 new 第二个、不读私有实现 | G3 `[R37][LifeFX] ... getter_owner=Hud ... 不自建`；`[R37][HUD] flask_unique=true death_unique=true`、`[R37][ENC] flask_unique=true death_unique=true` |
| A48③ 一条不加载 `presentation.gd`、不在验证脚本内模拟编排的真实可达回归 | G3 `--headless --quit` 主场景真跑（真实 autoload、不加载 `presentation.gd`）实证生产装配；定稿录屏是「真实输入 → 生产链路 → 画面」实机证据 | `r37_g3_quit.log` 装配日志 + `node_count=41`；`r37_v140_movie.log` 10 次 `focus_skill_performed` + 元素瓶生产消费 |
| A48④ 纯逻辑 + 单元断言不算可玩交付 | 本轮交付为**实机 15 秒录屏 + 目视回看 + 改前/改后像素对比**，非纯逻辑 / 单元断言 | `capture/v140_final.mp4` 450 帧 + §4 / §5 |
| 所有新数值标 `[PLACEHOLDER]` + rationale + 调参唯一入口 | A72 约 22 个 + 生命轮回约 20 个常量，逐项 rationale，独立常量表 = 调参唯一入口（只改表不改算法） | `hd2d_fx.gd` 「R37 / A72」「R37 / 生命轮回」两块 |
| 三段门禁 `grep SCRIPT ERROR=0` | G1 import → G2 check-only → G3 quit + 全工程 G3 独立复跑，7 份日志全绿 | §3.1 |
| 不新建只读探针 / 巡检脚本 | 本轮未新建任何 .gd 探针 / 巡检脚本；像素对比用**工程外一次性 Pillow 分析**（`python -c`，日志与图留档 `capture/`） | 交付清单仅改 `hd2d_fx.gd` + capture 产物 |
| 零付费 / 零外部依赖 / 不启 GPU job | 仅本地 Godot 4.7.2 + 本地 ffmpeg 9.x + 本地 Pillow 12.3.0 | — |
| A47 Movie Maker 禁 `--headless` | 改前基线与定稿录屏命令均未带 `--headless` | §3.3 / §3.4 |
| A62 帧数以磁盘连续编号 + ffprobe 为准 | 磁盘 450 连续 + ffprobe 450 / 15.000000s，三者一致，未触发短录重跑 | §3.4 / §3.5 |
| A63 移动端轻量绘制 | mobile 档 A72 弧 `lite` 分支 + 生命轮回 `lite` 分支，`_process` 同步推进计时 / 绑定 | §2② |
| 按总指挥 R35/R36 目视口径写 DONE | 弹反金色粗环明显可辨（A67 通过）、HUD 无重叠、R 战技切换文字可见、FP 条状态齐全、HD-2D 全绿未达 —— **不沿用旧自评** | §5 |
| 不伪造产物 / 不谎报成功 / 不自行 git / 不删 `.workbuddy` | 全绿 / 未达 / 未覆盖项如实登记，未 git、未删目录 | 全文 |

---

## 9. 硬约束遵守声明

- **只写授权文件**：`godot/scripts/hd2d_fx.gd`（唯一改动的工程脚本）、`capture/`（定稿成片 / 450 帧 / 改前基线 450 帧 / 目视帧 / 三连对比图 / 日志 / 像素证据）、`teamwork/Rank-4/DONE-R37.md`、回执。`godot/scripts/render/hd2d_parallax.gd` 与 `godot/assets/generated/r23/` 下自有 PNG / `import.json` 本轮**未改**（无需改动）。
- **只读未改**：`encounter_director.gd` / `hud.gd` / `presentation.gd` / `wave_trial_director.gd` / `points_commit_orchestrator.gd` / `project.godot` / `courtyard.tscn`（A38 节点 41 / uv 2/1/1 / 节点名不变）/ `impact_feedback.gd` / 数据表 / 场景节点与 uv / `[PLACEHOLDER]` 既有数值语义 / 其它 Rank 文件。
- **HUD 文字框逐字未动**；未越界篡改其它 Rank 的运行时节点 / 状态；未改场景节点 / uv / 数据表。
- 默认不刺探：未扫目录做进度巡检、未新建只读探针 / 巡检脚本、未反复核对文件状态；读取仅限任务单指定契约文件、接线所必需的生产源码（`wave_trial_director.gd` / `flask_service.gd` / `death_service.gd` / `hud.gd` / `presentation.gd` 的公开签名与注入节奏）、目标帧与根因定位，以及回执目录与中枢归档结构。
- 录屏前 `--headless --import` 已跑且 G3 实证四路 Rank 收敛无半成品，**未触发「等一下再重跑」**；未录短于 450 帧的短录，未冒充 15 秒。
- **最终画面验收由总指挥在定稿录屏关键帧目视确认（A72），代码断言不算画面验收** —— 本 DONE 的像素统计与目视自评只作证据与登记。

---

## 10. 回执与中枢归档确认

- 回执写入 Rank-4 授权路径（**`teamwork/command_center/`，非工程根**）：
  `teamwork/command_center/ai/4/outbox/cmd-20261112-184157-094-A4.json`，
  四字段 `{"task_id", "ai":4, "status":"done", "result"}`（`result` 引用本 DONE 实际结论）。
- **中枢归档回读确认（写后实测，如实登记、不伪造）**：
  - `ai/4/outbox/` 写后已被中枢清空（回执移入 `dispatcher/receipts/`，属中枢正常处理，与 R34/R35/R35B/R36 一致，不重放、不伪造）。
  - 归档副本 `teamwork/command_center/dispatcher/receipts/cmd-20261112-184157-094-A4.json` 存在（**2592 字节**），回读 **VALID_JSON**，四字段齐全：`keys=['ai','result','status','task_id']` / `task_id=cmd-20261112-184157-094-A4` / `ai=4` / `status=done` / `result_len=1298`，与 outbox 回执逐字一致。
  - `ai/4/status.json` 更新为 `{"ai":4,"state":"idle","current_task":"","completed":68,"last_seen":"2026-11-12 19:51:55"}`（`completed` 67 → 68、`state` working → idle、`current_task` 清空）。
  - `dispatcher/ledger.jsonl` 本任务单登记：`status=done` / `finished_at=2026-11-12 19:51:55` / `result` 与回执逐字一致；派单 `issued_at=2026-11-12 18:41:58` 与任务单一致。
  - `dispatcher/dispatcher.log` 尾部原文：`[2026-11-12 19:51:55] ← 4 号 AI 回执 <cmd-20261112-184157-094-A4> 完成：R37/v0.14.0 完成，实际结论见 teamwork/Rank-4/DONE-R37.md…`（回收 `done`）。
  - 注：本轮中枢归档副本文件名为 `receipts/<id>.json`（非 `receipt_<id>.json` 前缀），`status.json` / `ledger.jsonl` / `dispatcher.log` 三处均实证回收；如实登记，不臆造文件名。
