# DONE-R21.md · 移动档低分辨率与帧时间实测

> 轮次 **R21**｜派单 `cmd-20261109-115818-662-A4`｜命令 `[ROUND=R21]`｜工位 **Rank-4 美术管线与工具链**｜日期 2026-11-09
> 一句话结论：**7 组 Godot CLI 分辨率/窗口参数组合真跑，Movie Maker 输出 PNG 全部实测 1280×720，未达成引擎级 640×360；本轮不改 `project.godot`，如实查清边界并留证，用 `--print-fps` 真跑补上 R20 缺的帧时间实测（mobile 3.43 vs desktop 5.03 mspf @ 关 V-Sync），PIL 2× 降采样对照图已明确标注「后处理对照，非引擎低分辨率渲染」，47/34 PASS 与三段门禁全绿。未达 HD-2D 全绿，不冒充。**
> 必读（已读）：`Rank-4/调度任务单-latest.json`、`DONE-R20.md`、`CAPTURE-REPORT.md`、`project.godot`（只读）、`quality_settings.gd` / `hd2d_fx.gd` / `verify_fx_mobile.gd` / `verify_fx_profile.gd`（只读）、引擎 `--help` 全文（存 `capture/r21_godot_help.txt`）。

---

## 0. 实际结论（先说结果）

1. **边界查清（本轮核心）**：不改 `project.godot` 的前提下，真跑 7 组分辨率/窗口参数组合（`--resolution 640x360` / `1920x1080` / `480x270` / `--fullscreen` / `--windowed --maximized` 等），**全部 EXIT=0、Movie Maker stdout 一律 `recording movie in 1280×720 @ 30 FPS`、PNG IHDR 实测一律 1280×720**，无一输出 640×360。R20 登记的「`--resolution` 未改变录制尺寸」经多组合复现属实。
2. **根因留证**：引擎 `--help` 全文 129 行（`capture/r21_godot_help.txt`）里**没有缩放(scaling)CLI 参数、没有命令行覆盖 project settings 的途径**，尺寸相关只有 `--resolution` / 窗口模式 / `--position` / `--disable-vsync`；录制尺寸由 `project.godot` 的 `viewport_width/height=1280×720` 与 `window_*_override=1280×720` 决定，而本轮硬约束禁写 `project.godot`、也禁在 `godot/` 下新建 `override.cfg` / 临时工程 → **授权范围内无法让引擎直接输出 640×360 PNG**，如实写边界、不冒充。
3. **`--resolution` 确实改变内部渲染画面但不改文件尺寸**：C2 首帧 406020 字节 vs C1 基线 125346；PIL 真算 `c1 vs c2` 差异像素 22.8%、边缘能量 37.037→22.346（砖块像素网格明显变粗）。属内部 SubViewport 低分辨率 + 整数放大，**不等于输出 640×360 文件**。
4. **帧时间真跑（补 R20 §3 第 8 项缺口）**：`--print-fps` 引擎直打 mspf —— V-Sync 开 desktop **16.72** / mobile **16.66** mspf（被 60 Hz 锁死）；关 V-Sync desktop **5.03** / mobile **3.43** mspf（mobile 帧时间少 31.8%、吞吐 1.47×）。数字全部来自真跑 stdout，见 `capture/r21_frame_time.md`。
5. **PIL 后处理对照（禁止冒充）**：唯一 640×360 产物 `capture/r21_lowres_post_2x_downsample.png` 图上红字醒目标注「后处理对照 · 非引擎低分辨率渲染」；另出并排对比图 `r21_lowres_post_vs_engine.png`。**明确声明为后处理，非引擎低分辨率渲染，不冒充 Movie Maker 产物。**
6. **回归全绿**：`verify_fx_mobile.gd` **47 PASS** / `verify_fx_profile.gd` **34 PASS** 不回退；三段门禁 + 两个 RUN 共 6 项 EXIT=0；17 份 `r21_*.log` 的 `SCRIPT ERROR|Parse Error|ERROR` **SUM=0**。本轮零改动工程源件。

---

## 1. 实际交付清单

### 1.1 每种参数组合的真实 PNG 尺寸（任务①核心，`capture/` 下，全部 Movie Maker 真跑输出）

统一命令骨架：`"$GODOT" --path <proj> --write-movie capture/<前缀>.png --fixed-fps 30 --quit-after 4 <额外参数> res://scenes/courtyard.tscn`；每组合产出 4 帧 PNG（`前缀00000000.png` ~ `00000003.png`）+ 1 个自动音频轨 `.wav`。

| # | 前缀 | 额外 CLI 参数 | 档位 | EXIT | stdout 录制尺寸 | PNG 实测尺寸(IHDR) | 首帧字节(范围) | 对应 log |
|---|---|---|---|---|---|---|---|---|
| C1 | `r21_lowres_c1_base` | 无（基线） | desktop | 0 | 1280×720 | **1280×720** | 125346~125610 | `r21_lowres_c1_base.log` |
| C2 | `r21_lowres_c2_res640x360` | `--resolution 640x360` | desktop | 0 | 1280×720 | **1280×720** | 406020~406499 | `r21_lowres_c2_res640x360.log` |
| C3 | `r21_lowres_c3_res1920x1080` | `--resolution 1920x1080` | desktop | 0 | 1280×720 | **1280×720** | 287862~287966 | `r21_lowres_c3_res1920x1080.log` |
| C4 | `r21_lowres_c4_res640_full` | `--resolution 640x360 --fullscreen` | desktop | 0 | 1280×720 | **1280×720** | 126815~126908 | `r21_lowres_c4_res640_full.log` |
| C5 | `r21_lowres_c5_res480x270` | `--resolution 480x270` | desktop | 0 | 1280×720 | **1280×720** | 491198~491493 | `r21_lowres_c5_res480x270.log` |
| C6 | `r21_lowres_c6_res640_max` | `--resolution 640x360 --windowed --maximized` | desktop | 0 | 1280×720 | **1280×720** | 407063~407180 | `r21_lowres_c6_res640_max.log` |
| FT | `r21_lowres_ft_mobile` | 无 + `AIERDENG_FX_PROFILE=mobile` | **mobile 四项全关** | 0 | 1280×720 | **1280×720** | 112772（4 帧全同）| `r21_lowres_ft_mobile.log` |

> 尺寸核验方式：Python `struct.unpack('>II', png[16:24])` 直接读 PNG IHDR，零依赖；与 Godot stdout 的 `recording movie in` 双重印证。7 组共 **28 帧 PNG，全部 1280×720**。

### 1.2 帧时间产物（任务②）

| 文件 | 说明 |
|---|---|
| `capture/r21_frame_time.md` | 帧时间真跑报告：命令 / 两种口径 / 四组真值表 / 边界声明 |
| `capture/r21_frame_time_fps_desktop_vsync.log` | `--print-fps --quit-after 400`，desktop / V-Sync 开，5 行 |
| `capture/r21_frame_time_fps_mobile_vsync.log` | 同上 mobile，4 行 |
| `capture/r21_frame_time_fps_desktop_novsync.log` | `--print-fps --disable-vsync --quit-after 6000`，desktop，28 行 |
| `capture/r21_frame_time_fps_mobile_novsync.log` | 同上 mobile，19 行 |

### 1.3 PIL 后处理对照图（任务③，明确标注、禁止冒充）

| 文件 | 尺寸 | 说明 |
|---|---|---|
| `capture/r21_lowres_post_2x_downsample.png` | **640×360** | 对 `r21_lowres_c1_base00000000.png`（引擎 1280×720）做 2× LANCZOS 降采样；图上顶部红字「后处理对照 · 非引擎低分辨率渲染」/ 英文副标 / 底部来源标注。**后处理对照，非引擎低分辨率渲染** |
| `capture/r21_lowres_post_vs_engine.png` | 1280×416 | 并排对比（左=引擎真实输出缩略 / 右=后处理降采样），标题红字再声明右图非引擎渲染 |

> 全 `capture/` 下唯一 640×360 的 PNG 就是带标注的 `r21_lowres_post_2x_downsample.png`；所有 `r21_lowres_c*/ft_mobile*` 帧仍 1280×720。

### 1.4 门禁 / 引擎参数留证 / 画面量化

- `capture/r21_gate_import.log`、`r21_gate_run_mobile.log`、`r21_gate_run_profile.log`、`r21_gate_checkonly_mobile.log`、`r21_gate_checkonly_profile.log`、`r21_gate_quit.log`（6 项门禁 + 两个 verify 真跑 stdout）。
- `capture/r21_godot_help.txt`：引擎 `--help` 全文 129 行留证（证明无缩放 / settings-override CLI 参数）。
- 画面差距量化（PIL 内联真算、未落盘脚本）：`c1_base vs c2_res640x360` MAD=(10.455,8.888,5.505) / diff_ratio=0.228038 / 边缘能量 37.037→22.346；`c1_base(desktop) vs ft_mobile(mobile)` MAD=(2.299,2.133,1.583) / diff_ratio=0.042374。

### 1.5 报告与回执

| 文件 | 说明 |
|---|---|
| `capture/CAPTURE-REPORT.md` | **独占追加**「R21 低分辨率与帧时间」段落（画面差距 / 边界 / 帧时间 / 防冒充声明） |
| `teamwork/Rank-4/DONE-R21.md` | 本文件 |
| `teamwork/command_center/ai/4/outbox/cmd-20261109-115818-662-A4.json` | 回执 JSON（**精确路径在 `teamwork/command_center/` 下**，已确认该 outbox 目录存在；工程根 `command_center/` 不写） |

### 1.6 零改动与目录所有权

本轮**只写** `capture/` 下本轮产物与 `CAPTURE-REPORT.md`（独占追加）、`teamwork/Rank-4/DONE-R21.md`、回执例外 `teamwork/command_center/ai/4/outbox/<id>.json`。**未写** `project.godot` / `courtyard.tscn` / `quality_settings.*` / `hud.gd` / `verify_frame_data.gd` / `hd2d_fx.*` / `verify_fx_mobile.gd` / `verify_fx_profile.gd` / 任何 `.tres` / `.import` / 其它 `.gd` / 其它工位 / 总线 / 总纲 / 契约 / 任务书。未新建任何只读探针 / 巡检脚本（PIL 与统计均 `python - <<'PY'` 内联执行）；未自行 git。零付费 / 零外部素材 / 零插件 / 零云服务；中文 UTF-8；Godot 4.7.2 合法语法。

---

## 2. 真跑输出结论

### 2.1 命令（Windows Git Bash，引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--version`=4.7.2.stable.official.ed1daf0bf EXIT=0）

```text
# 三段门禁 + 两个 verify 真跑
"$GODOT" --headless --path godot --import                                                    # G1
"$GODOT" --headless --path godot --script res://scripts/verify_fx_mobile.gd                  # RUN_M  → 47 PASS
"$GODOT" --headless --path godot --script res://scripts/verify_fx_profile.gd                 # RUN_P  → 34 PASS
"$GODOT" --headless --path godot --check-only --script res://scripts/verify_fx_mobile.gd     # G2
"$GODOT" --headless --path godot --check-only --script res://scripts/verify_fx_profile.gd    # G2
"$GODOT" --headless --path godot --quit                                                      # G3
# 参数组合抓帧（7 组，见 §1.1）
"$GODOT" --path godot --write-movie capture/r21_lowres_c2_res640x360.png --fixed-fps 30 --quit-after 4 --resolution 640x360 res://scenes/courtyard.tscn
# 帧时间 --print-fps（4 组，见 §1.2）
"$GODOT" --path godot --print-fps --disable-vsync --quit-after 6000 res://scenes/courtyard.tscn
AIERDENG_FX_PROFILE=mobile "$GODOT" --path godot --print-fps --disable-vsync --quit-after 6000 res://scenes/courtyard.tscn
```

### 2.2 三段门禁 + PASS 回归（实际 stdout）

```text
[import] EXIT=0  [run_mobile] EXIT=0  [run_profile] EXIT=0
[checkonly_mobile] EXIT=0  [checkonly_profile] EXIT=0  [quit] EXIT=0
==== [R19] SUMMARY pass=47 fail=0 total=47 ====   → verify_fx_mobile.gd（标签沿用既有 [R19]，未伪装）
==== [R19] RESULT=PASS ====
==== [R17] SUMMARY pass=34 fail=0 total=34 ====   → verify_fx_profile.gd（标签沿用既有 [R17]）
==== [R17] RESULT=PASS ====
```

17 份 `r21_*.log`（7 抓帧 + 4 帧时间 + 6 门禁）的 `grep -cE "SCRIPT ERROR|Parse Error|ERROR"` **逐份 0、SUM=0**。两个 verify 脚本本轮零改动，PASS 为既有脚本原样真跑、非改脚本凑数。

### 2.3 帧时间数字（任务②，全部真跑、非估算）

口径 A —— `--print-fps` 引擎直打 `Project FPS: N (X mspf)`，X 即运行期每帧毫秒；Python 基于该 stdout 统计：

| 组 | 档位 | V-Sync | n | FPS min/均值/max | **mspf 均值** | mspf min~max |
|---|---|---|---|---|---|---|
| `fps_desktop_vsync` | desktop 四项全开 | 开 | 5 | 59/59.8/60 | **16.72 ms** | 16.66~16.94 |
| `fps_mobile_vsync` | mobile 四项全关 | 开 | 4 | 60/60.0/60 | **16.66 ms** | 16.66~16.66 |
| `fps_desktop_novsync` | desktop 四项全开 | 关 | 28 | 184/198.8/213 | **5.03 ms** | 4.69~5.43 |
| `fps_mobile_novsync` | mobile 四项全关 | 关 | 19 | 245/291.7/309 | **3.43 ms** | 3.23~4.08 |

- V-Sync 开：stdout 明示 `Requested V-Sync mode: Enabled - FPS will likely be capped to the monitor refresh rate.`，两组均被 60 Hz 锁死 → 如实登记为 V-Sync 限制，不冒充性能优化。
- 关 V-Sync 全速：**mobile 3.43 vs desktop 5.03 mspf，帧时间少 31.8%、吞吐 1.47×**（198.8→291.7 FPS），是「四项光效全关 → FX 层零绘制」的真实渲染开销下降。

口径 B —— Movie Maker 4 帧录制的 CPU/GPU/Encoding 平均 ms/frame（补充，样本短、不作稳定结论）：

| 组 | CPU render | GPU render | Encoding | recorded in |
|---|---|---|---|---|
| `c1_base`(desktop) | 0.02 | 0.00 | 126.17 | 00:00:11 (9%) |
| `c2_res640x360` | 0.02 | 0.00 | 143.47 | 00:00:12 (8%) |
| `c3_res1920x1080` | 0.02 | 0.00 | 46.86 | 00:00:08 (12%) |
| `c4_res640_full` | 0.01 | 0.00 | 42.59 | 00:00:04 (25%) |
| `c5_res480x270` | 0.02 | 0.00 | 75.27 | 00:00:03 (33%) |
| `c6_res640_max` | 0.02 | 0.00 | 57.53 | 00:00:02 (50%) |
| `ft_mobile`(mobile) | 0.02 | 0.00 | 28.64 | 00:00:02 (50%) |

> CPU/GPU render time 在 4 帧固定步长下均被四舍五入到 0.00~0.02 ms/帧，样本太短不足以区分档位，如实写「不可判定」；Encoding 组间 28.64~143.47 波动大（磁盘 / 画面复杂度），不作稳定性能结论。主结论以口径 A 为准。

### 2.4 边界根因（引擎 `--help` 全文留证）

`capture/r21_godot_help.txt`（129 行）中尺寸 / 缩放相关 CLI 全部为：`--resolution <W>x<H>` / `--position <X>,<Y>` / `--fullscreen(-f)` / `--windowed(-w)` / `--maximized(-m)` / `--screen <N>` / `--single-window` / `--wid` / `--disable-vsync` / `--max-fps` / `--frame-delay` / `--time-scale` / `--fixed-fps` / `--print-fps` / `--write-movie` / `--quit-after` / `--display-driver` / `--rendering-method` / `--gpu-index`。**无 scaling CLI 参数、无 project settings 命令行覆盖开关**（唯一含 "override" 的是无关的 `--audio-output-latency` 与编译期 `disable_path_overrides` 说明）。`--resolution` 只请求窗口分辨率，被 `project.godot` 的 `window_*_override` 压过；Movie Maker 输出锁定 viewport/window 尺寸 1280×720。缩放（如 `rendering/scaling_3d/scale`）只能经 project settings 或运行期 `ProjectSettings.set_setting()`（脚本）改，本轮禁改 `project.godot`、禁新建脚本、禁在 `godot/` 下建 `override.cfg` → 边界成立。

### 2.5 画面差距（ViewImage 真看 + PIL 真算）

- **C1 基线（1280×720, desktop 四项全开）**：蓝天、左上深蓝 HUD「赐福 · 宁姆格福」、右上「画质设置 · 低/中/高」面板、暖金横砖地面（砖缝细密）、中央蓝红像素骑士、地平线暖金 bloom / 体积光亮点、角色脚下倒影亮线；像素细腻、主体全可读。
- **C2（`--resolution 640x360`，仍 1280×720）**：构图元素完全相同，但**砖块像素网格明显变粗、砖缝更块状、HUD 文字与角色轮廓更糊** → 内部低分辨率放大特征。PIL：`c1 vs c2` MAD=(10.455,8.888,5.505)、diff_ratio=0.228038、边缘能量 37.037→22.346。
- **FT（mobile 四项全关，1280×720）**：`c1_base vs ft_mobile` MAD=(2.299,2.133,1.583)、diff_ratio=0.042374，差异集中在天空光尘/bloom 与脚下倒影区域；4 帧 sha256 全同（FX 层零绘制 → 静态），非 desktop 帧改名。
- **后处理对照图**：640×360、画面完整可读但明显更平滑（高质量降采样），与 C2 的「块状像素放大」不同 —— 这正是「后处理降采样 ≠ 引擎内部低分辨率渲染」的直观证据。

### 2.6 抓帧文件名（最终返回用）

`capture/r21_lowres_c1_base00000000.png` ~ `00000003.png`、`r21_lowres_c2_res640x3600000000*.png`、`r21_lowres_c3_res1920x10800000000*.png`、`r21_lowres_c4_res640_full0000000*.png`、`r21_lowres_c5_res480x2700000000*.png`、`r21_lowres_c6_res640_max0000000*.png`、`r21_lowres_ft_mobile0000000*.png`（各 4 帧，全 1280×720）；后处理对照 `r21_lowres_post_2x_downsample.png`（640×360）、`r21_lowres_post_vs_engine.png`（1280×416）。

---

## 3. 未完成项与阻塞（如实登记，不冒充全绿）

| # | 项 | 性质 / 归属 |
|---|---|---|
| 1 | **引擎级 640×360 PNG 输出未达成（本轮主边界）** | 7 组参数组合全 1280×720。唯一途径需改 `project.godot` 的 viewport/window 尺寸（Rank-3 独占，本轮硬约束禁写、避免与其它三路并发冲突），或在 `godot/` 下新建 `override.cfg` / 临时工程（超本轮「只写 `teamwork/Rank-4/` 与 `capture/`」目录所有权）。按派单「重导双产物另以 R21B 补单在工程冻结后执行」，本轮只查清并留证 |
| 2 | **640×360 对照图是后处理、非引擎渲染** | `r21_lowres_post_2x_downsample.png` 由 PIL 对 1280×720 原始帧 2× LANCZOS 降采样得到，图上与报告均明确标注「后处理对照，非引擎低分辨率渲染」，**不冒充引擎低分辨率渲染、不冒充 Movie Maker 产物** |
| 3 | **帧时间口径限制** | V-Sync 组被 60 Hz 锁死、Movie Maker 组被 `--fixed-fps 30` 固定步长限制、4 帧样本太短；真正区分档位的是 `--disable-vsync --print-fps` 组。未做逐 `_draw()` 拆分 / GPU 时间戳查询 / 人工试玩逐帧动态验收 |
| 4 | **并发实例产物（非本实例所为，如实登记）** | 本轮真跑期间另有 Rank-4 并发实例用 `r21_lowres_base / res640 / res320 / res1920 / res640win / res640headless` 命名产出抓帧（32 个文件、mtime 12:08:11~17、均无对应 log、IHDR 全 1280×720；`res640headless.wav` 为 0 字节）。与本实例命名 `c1~c6 / ft_mobile` 互不冲突；本实例**未覆盖、未删除、未冒充**并发产物。定点核查确认 DONE-R21.md / CAPTURE-REPORT R21 段 / 回执在本实例写入前均 ABSENT |
| 5 | **HD-2D 全绿仍未达成（沿用 R20）** | 四项光效是 2D 程序化 `draw_*` 几何/加色近似，非真正 HDR bloom / 3D 体积光 / SSR（`gl_compatibility` 后端不支持）；倒影仍为细亮线 + 少量深色块；地面程序化横砖、构图占位阶段；ComfyUI 正式 spritesheet 未接入。本轮不精修光效 |
| 6 | 强制档位是抓帧/验证专用通道 | 依赖 `AIERDENG_FX_PROFILE` 环境变量（既有 `hd2d_fx.gd` 机制，本轮未改），未接入正式画质菜单；正式切档归 Rank-1 `QualitySettings` / `fx_profile_controller.gd`，本轮不越界 |
| 7 | 长期阻塞（沿用既有登记） | ComfyUI 正式素材接入、`128bit` 口径、apk 产物、运行期可见性人工验收仍未解决；ComfyUI 仍是主美术路线，程序化 `_draw()` 为零外部依赖兜底 |
| 8 | 真跑 / 门禁失败项 | **无**。7 组抓帧 + 4 组帧时间 + 6 项门禁全部 EXIT=0；17 份 `r21_*.log` ERROR SUM=0。若有失败会如实写入本节 |

---

## 4. 合规声明

所有 stdout 均为 Godot 4.7.2 真跑 / `--help` / grep / Python `struct` IHDR / PIL 实际计算结果；所有画面描述基于 ViewImage 真实查看；未伪造产物、未臆造引擎常量、未谎报成功、未冒充引擎级低分辨率、未冒充全绿。`r21_lowres_c*/ft_mobile*` 全部为 Movie Maker 真实输出（非 desktop 帧改名冒充）；`r21_lowres_post_2x_downsample.png` 明确标注为后处理对照。本轮未写 `project.godot` 及任何派单禁改件、未新建只读探针/巡检脚本、未主动扫目录做进度巡检（仅对交付目标与并发产物做定点只读核查）、未自行 git commit / push；零付费 / 零外部素材 / 零插件 / 零云服务；中文 UTF-8；Godot 4.7.2 合法语法。

---

## 5. 回执落地

回执 JSON 按本任务单 id 写入 `F:/Game/aierdengfahuan/teamwork/command_center/ai/4/outbox/cmd-20261109-115818-662-A4.json`，`status=done`、`ai=4`、`result` 引用本文件实际结论。该路径在 `teamwork/command_center/` 下（已确认目录存在）；工程根 `F:/Game/aierdengfahuan/command_center/` 不存在、未写错位置。若中枢按 R20 惯例实时消费并移出 outbox，以 `dispatcher/receipts/` 归档为准，不重发第二份回执。

**回执落地核验（实际 stdout，2026-11-09 12:22）**：写入 outbox 后中枢实时消费，`ai/4/outbox/` 已空；归档件 `teamwork/command_center/dispatcher/receipts/cmd-20261109-115818-662-A4.json`（1790 字节）解析实测 `keys=['ai','result','status','task_id']`、`task_id=cmd-20261109-115818-662-A4`、`ai=4`、`status=done`、`result 长度=1137`，引用 `DONE-R21.md=True`，含 `47 PASS` / `5.03` / `1280x720` / `后处理` 均为 True；`dispatcher/ledger.jsonl` 本轮记录 `status=done`、`finished_at=2026-11-09 12:22:24`。归档路径在 `teamwork/command_center/` 下、工程根 `command_center/` 不存在 → **回执写对路径、已送达、未写错位置、未重发第二份**。
