# R21 帧时间真跑记录（mobile 档 vs desktop 档）

> 轮次 **R21** · 工位 Rank-4 · 派单 `cmd-20261109-115818-662-A4` · 2026-11-09
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`，`--version` EXIT=0）
> 场景 `res://scenes/courtyard.tscn` · 全部数字来自 **Godot 真跑 stdout** 或 Python 基于该 stdout 的统计，**非估算、非引用 R20**。
> 档位切换沿用 `hd2d_fx.gd` 既有机制：desktop＝默认不设环境变量（四项全开）；mobile＝`AIERDENG_FX_PROFILE=mobile`（四项全关）。本轮未改 `hd2d_fx.*` / `project.godot`。

---

## 1. 真跑命令

```text
# 口径 A：--print-fps（引擎每秒打印一次 "Project FPS: N (X mspf)"，X 即运行期每帧毫秒数）
#   主循环真实帧间隔；场景同抓帧，含 quality_settings low→high 重判 + FX 层绘制
"$GODOT" --path <proj> --print-fps --quit-after 400 res://scenes/courtyard.tscn                         # desktop / V-Sync 默认
AIERDENG_FX_PROFILE=mobile "$GODOT" --path <proj> --print-fps --quit-after 400 res://scenes/courtyard.tscn   # mobile / V-Sync 默认
"$GODOT" --path <proj> --print-fps --disable-vsync --quit-after 6000 res://scenes/courtyard.tscn           # desktop / 关 V-Sync
AIERDENG_FX_PROFILE=mobile "$GODOT" --path <proj> --print-fps --disable-vsync --quit-after 6000 res://scenes/courtyard.tscn  # mobile / 关 V-Sync

# 口径 B：Movie Maker 录制（--fixed-fps 30 --quit-after 4），引擎在结束时真打印 CPU/GPU/Encoding 平均 ms/frame
"$GODOT" --path <proj> --write-movie capture/r21_lowres_c1_base.png --fixed-fps 30 --quit-after 4 res://scenes/courtyard.tscn   # desktop 基线
AIERDENG_FX_PROFILE=mobile "$GODOT" --path <proj> --write-movie capture/r21_lowres_ft_mobile.png --fixed-fps 30 --quit-after 4 res://scenes/courtyard.tscn  # mobile
```

原始 stdout 日志：`r21_frame_time_fps_desktop_vsync.log`、`r21_frame_time_fps_mobile_vsync.log`、`r21_frame_time_fps_desktop_novsync.log`、`r21_frame_time_fps_mobile_novsync.log`（口径 A）；`r21_lowres_c1_base.log`、`r21_lowres_ft_mobile.log` 等 7 份抓帧日志（口径 B）。

---

## 2. 口径 A：`--print-fps` 运行期帧时间（主口径，非估算）

`mspf` 是引擎直接打印的每帧毫秒数；`n` 为该次真跑捕获到的 `Project FPS` 行数。均值/极值由 Python 对引擎打印的真值统计得出。

| 组 | 档位 | V-Sync | n | FPS min/均值/max | **mspf 均值** | mspf min~max |
|---|---|---|---|---|---|---|
| `fps_desktop_vsync` | desktop 四项全开 | 开（默认） | 5 | 59 / 59.8 / 60 | **16.72 ms** | 16.66 ~ 16.94 |
| `fps_mobile_vsync` | mobile 四项全关 | 开（默认） | 4 | 60 / 60.0 / 60 | **16.66 ms** | 16.66 ~ 16.66 |
| `fps_desktop_novsync` | desktop 四项全开 | 关（`--disable-vsync`） | 28 | 184 / 198.8 / 213 | **5.03 ms** | 4.69 ~ 5.43 |
| `fps_mobile_novsync` | mobile 四项全关 | 关（`--disable-vsync`） | 19 | 245 / 291.7 / 309 | **3.43 ms** | 3.23 ~ 4.08 |

原始行示例（真跑 stdout，逐字）：

```text
[fps_desktop_vsync]   Project FPS: 60 (16.66 mspf) ... Project FPS: 59 (16.94 mspf)
[fps_mobile_vsync]    Project FPS: 60 (16.66 mspf)  （4 行全同）
[fps_desktop_novsync] Project FPS: 213 (4.69 mspf) ... Project FPS: 189 (5.29 mspf)
[fps_mobile_novsync]  Project FPS: 309 (3.23 mspf) ... Project FPS: 245 (4.08 mspf)
```

**结论（真跑数字）**：

- V-Sync 开启时两组 stdout 均显示 `Requested V-Sync mode: Enabled - FPS will likely be capped to the monitor refresh rate.`，帧时间被显示器 60 Hz 锁死：desktop 16.72 ms / mobile 16.66 ms，**几乎无差异，属 V-Sync 限制而非渲染能力差异**，如实登记、不冒充性能优化结论。
- 关闭 V-Sync 后引擎全速渲染，档位差异显现：**mobile 3.43 ms/帧 vs desktop 5.03 ms/帧**，mobile 帧时间减少约 **31.8%**、吞吐约 **1.47×**（198.8 → 291.7 FPS）。这是「四项光效全关 → FX 层零绘制」带来的真实渲染开销下降。
- 以上为**运行期主循环帧间隔**（含场景逻辑 / 渲染 / 提交），不是逐 `_draw()` 耗时拆分；`--disable-vsync` 组更能反映档位渲染成本，V-Sync 组反映真实显示节奏。两种口径分别记录，未混用。

---

## 3. 口径 B：Movie Maker 录制模式帧时间（补充口径，`--fixed-fps 30`）

引擎在录制结束时真打印 `CPU/GPU/Encoding time ... (average: X ms/frame)`。注意 `--fixed-fps` 强制固定步长（33.33 ms 逻辑帧），下列是渲染/编码**子耗时**，且仅 4 帧样本、PNG 编码受磁盘与画面复杂度影响波动大，**不作稳定性能结论**，仅如实登记。

| 抓帧组 | 档位 | CPU render (ms/帧) | GPU render (ms/帧) | Encoding (ms/帧) | recorded in |
|---|---|---|---|---|---|
| `r21_lowres_c1_base` | desktop 基线 | 0.02 | 0.00 | 126.17 | 00:00:11 (9% 实时) |
| `r21_lowres_c2_res640x360` | desktop + `--resolution 640x360` | 0.02 | 0.00 | 143.47 | 00:00:12 (8%) |
| `r21_lowres_c3_res1920x1080` | desktop + `--resolution 1920x1080` | 0.02 | 0.00 | 46.86 | 00:00:08 (12%) |
| `r21_lowres_c4_res640_full` | desktop + `--resolution 640x360 --fullscreen` | 0.01 | 0.00 | 42.59 | 00:00:04 (25%) |
| `r21_lowres_c5_res480x270` | desktop + `--resolution 480x270` | 0.02 | 0.00 | 75.27 | 00:00:03 (33%) |
| `r21_lowres_c6_res640_max` | desktop + `--resolution 640x360 --windowed --maximized` | 0.02 | 0.00 | 57.53 | 00:00:02 (50%) |
| `r21_lowres_ft_mobile` | **mobile 四项全关**（与 c1 同 CLI 条件） | 0.02 | 0.00 | 28.64 | 00:00:02 (50%) |

- CPU/GPU render time 在 4 帧固定步长下均被四舍五入到 0.00~0.02 ms/帧，**样本太短不足以区分档位**，如实写「不可判定」，不用它编造差异。
- Encoding 时间组间 28.64~143.47 ms/帧波动大（首个 PNG 写入含初始化、画面复杂度不同），**不是稳定帧时间**；c1(desktop) 126.17 与 ft_mobile(mobile) 28.64 的差距仅作参考，主结论以 §2 口径 A 为准。

---

## 4. 边界与诚实声明

1. 本文件所有数字均为 Godot 4.7.2 真跑 stdout 摘录或基于该 stdout 的 Python 统计；无估算、无臆造引擎常量、无引用 R20 数字冒充本轮。
2. 帧时间实测在主场景 `courtyard.tscn` 的非 headless 窗口下真跑（与 R21 抓帧同场景），不是 headless 门禁；未做逐 `_draw()` 拆分 / GPU 时间戳查询 / 人工试玩逐帧动态验收。
3. V-Sync 组被 60 Hz 限制、Movie Maker 组被固定步长限制，两种限制均已在上文显式标注；真正区分档位的是 `--disable-vsync --print-fps` 组。
4. 本轮未改任何工程源文件；帧时间不因本轮产生回退，也不宣称达到 HD-2D 性能/画质全绿。
