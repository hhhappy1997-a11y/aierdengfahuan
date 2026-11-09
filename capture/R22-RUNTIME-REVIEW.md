# R22 实机录屏 · 运行时目视回看（Rank-4）

- 派单：`cmd-20261109-124640-188-A4` · `[ROUND=R22]` · Rank-4（美术管线与工具链）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`），本机 OpenGL / NVIDIA RTX 4060 Ti
- 本轮核心交付：**用户至今未亲眼看过运行时，本轮首次产出 15 秒实机连续录屏并真看首/中/尾帧**
- 结论速览：**450 帧 / 15 秒 / 1280×720 真实完整画面真实产出，MP4 真实产出，跨段行为推进成立；HD-2D 目标未达全绿，如实写「未达」。**

---

## 1. 录屏命令与实际帧数

**实际采用（R22 等价确定性方式，含如实登记的改动点，见 §5）**：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe \
  --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/r22_demo.png \
  --fixed-fps 30 --quit-after 450 \
  --script res://test/presentation.gd \
  res://scenes/courtyard.tscn
```

任务单原命令为上表去掉末尾 `res://scenes/courtyard.tscn` 位置参数、由脚本 `instantiate()+add_child()` 加载场景的版本；该原命令已真跑（见 `r22_capture.log` 首版 / `r22_combo.log` / `r22_reuse.log`），**EXIT=0 且同样输出 450 帧，但画面主体（3D 砖地 / 像素骑士）缺失**，故按任务单授权切换到等价确定性方式并如实登记。

**真跑输出（日志 `capture/r22_capture.log` 尾部）**：

```
Done recording movie at path: F:/Game/aierdengfahuan/capture/r22_demo.png
450 frames at 30 FPS (movie length: 00:00:15:00), recorded in 00:00:42 (35% of real-time speed).
```

| 项 | 实测值 |
|---|---|
| 退出码 | `CAPTURE EXIT=0` |
| 实际帧数 | **450 帧**（PNG `r22_demo00000000.png` ~ `r22_demo00000449.png`，编号连续 `0..449` 已用 Python 校验 `continuous_0_449=True`） |
| 时长 / 帧率 | 15.000 秒 @ 30 FPS |
| PNG 尺寸 | 三帧 IHDR 实测均 **1280×720** |
| PNG 序列 | 450 张 |
| WAV | `r22_demo.wav`，5,760,044 字节（Movie Maker 自动音频轨） |
| MP4 | `r22_demo.mp4`，760,956 字节；ffprobe：`h264` / `yuv420p` / `1280×720` / `nb_frames=450` / `30/1` / `duration=15.000000` |
| ffmpeg | 本机可用（`/c/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg`），命令 `-framerate 30 -start_number 0 -i r22_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，`FFMPEG EXIT=0`。MP4 仅含视频，WAV 单独保留，未谎报合并音频 |

**日志门禁实证**（`r22_capture.log`）：`SCRIPT ERROR|Parse Error = 0`；`SEG=3`、`POSE=30`、`HUD=5`、`set_quality+apply=2`；时间线跑到 `frame=450`。首/中/尾帧 md5 全不同（`02b700…` / `bdf4a2…` / `863ee8…`），**非单帧循环**。

---

## 2. ViewImage 真看首 / 中 / 尾三帧（逐帧所见）

### 首帧 `r22_demo00000000.png`（第 0 帧，段 A：medium / desktop）

- **3D 地面**：下半屏铺满暖金色横砖透视地面，砖缝清晰、近大远小；左侧可见立体台阶/矮墙砖块（TerraceLow / TerraceHigh），有 3D 透视景深，非平面贴图。
- **像素角色**：中央偏右站立一名蓝色盔甲像素骑士（idle 姿态），像素边缘为 Nearest 硬边，与平滑 3D 砖地形成 2D/3D 对比；脚下有一条水平镜像亮线（湿地倒影）。
- **HUD**：左上深蓝底 + 金色 1px 边框面板，文字「**赐福 · 宁姆格福**」，字为**暗灰色**（未点亮态）。右上深蓝金边「画质设置 · 低 / 中 / 高」面板，三个金框按钮「低 / 中 / 高」。
- **光效**：地平线中央暖金 bloom 光点、淡暖金体积光扇形、散布的冷白/暖金光尘圆点。
- **天空**：亮蓝色纯色天空，约占上方 1/4；整体偏明亮，非深蓝夜景。

### 中帧 `r22_demo00000225.png`（第 225 帧，段 B：low / mobile）

- **3D 地面**：仍在且铺满，但**砖缝与色块明显变粗、更块状**（low 档 `stretch_shrink=3` 低分辨率整数放大），与首帧细砖缝形成明显对比 → 画质档位切换真实可见。
- **HUD**：面板**明显放大**（由约 340px 宽变为约 1020px 宽，覆盖画面中上部），文字变为「**赐福 · 巡礼教堂**」，仍为暗灰色；右上画质设置面板尺寸不变（它不在 SubViewport 内，不受档位缩放影响）。
- **角色**：站立骑士不可见 —— 帧 225 命中 `set_pose(death, 3)`（30 次切帧中的第 15 次），角色处于 death 姿态；且低分辨率下放大的 HUD 面板遮挡中央区域。
- **光效**：体积光扇形、光尘点、bloom、角色脚下倒影**四项全部消失**（mobile 档 `set_fx_profile` 四项全关）；画面只剩亮蓝天空 + 砖地 + 放大 HUD。

### 尾帧 `r22_demo00000449.png`（第 449 帧，段 C：high / desktop）

- **3D 地面**：铺满，砖缝比中帧**更细、更清晰**（high 档 `stretch_shrink=1`），透视结构完整。
- **像素角色**：中央骑士可见，但姿态与首帧不同 —— 帧 435 命中 `set_pose(attack_heavy, 1)`，呈举武器/前倾姿态；脚下湿地倒影亮线恢复。
- **HUD**：面板**缩小**（约 340px 宽），文字变为「**赐福 · 希芙拉河井底**」，暗灰色；右上画质设置面板保持。
- **光效**：地平线暖金光点、体积光扇形、光尘点、bloom **全部恢复**（切回 desktop 四项全开）。
- **天空/色调**：亮蓝纯色天空 + 暖金砖地，整体明亮。

---

## 3. 行为是否跨整段推进：**是**

| 维度 | 首帧 0（段 A） | 中帧 225（段 B） | 尾帧 449（段 C） |
|---|---|---|---|
| 画质档位 | medium（默认） | **low** | **high** |
| fx_profile | desktop 四项全开 | **mobile 四项全关** | **desktop 四项全开** |
| SubViewport 缩放 | shrink=2 | **shrink=3（砖粗/UI 大）** | **shrink=1（砖细/UI 小）** |
| HUD 标题 | 赐福 · 宁姆格福（暗） | **赐福 · 巡礼教堂（暗）** | **赐福 · 希芙拉河井底（暗）** |
| 角色姿态 | idle 站立 | **death（切帧生效）** | **attack_heavy（切帧生效）** |
| 四项光效 | 体积光/光尘/bloom/倒影全在 | **全消失** | **全恢复** |

- 时间线三段各 150 帧（5 秒）：段 A `0–149`、段 B `150–299`（帧 150 `set_quality("low")+apply()`）、段 C `300–449`（帧 300 `set_quality("high")+apply()`）。
- 全段共 **30 次 `set_pose` 切帧**（每 15 帧一次，8 个冻结 pose 循环）、**5 次 HUD flag 变化**（帧 40 / 190 / 250 / 340 / 420，`WorldState.set_flag → flag_changed → HUD` 事件驱动增量刷新）、**2 次画质档位切换**（连带 `fx_profile desktop→mobile→desktop`）。
- desktop 段另有 `hd2d_fx.gd` 既有 `_process` 逐帧 `queue_redraw()`（光尘上飘 / 倒影波纹）提供逐帧动画；首/中/尾 md5 全不同，日志时间线跑到 `frame=450`，**不是单帧循环**。
- 如实说明的静止区间：段 B（mobile 四项全关）期间 3D 主体不做逐帧位移（相机缓动因会破坏 3D 录制而取消），仅由 pose 每 15 帧切换与 HUD 事件推进，故存在短静止区间；这不构成「只播单帧循环」。

---

## 4. 与 HD-2D 目标（《八方旅人》式）的差距：**未达全绿**

对照任务给出的目标项「像素精灵 vs 平滑景深、体积光、光尘、湿地倒影、bloom、金线深蓝 UI」：

| 目标项 | 录屏实际所见 | 判定 |
|---|---|---|
| 像素精灵 vs 3D 场景对比 | 蓝色盔甲像素骑士（Nearest 硬边）站在 3D 透视砖地上，2D/3D 对比成立 | **部分达到** |
| 平滑景深 / DOF / 大气远景 | **无**：3D 地面从近到远全程清晰，远景无虚化；天空为纯色亮蓝，无远景层次、无雾深远景 | **未达** |
| 体积光 | 2D `draw_colored_polygon` 六层暖金扇形 + 中心高光，随档位开关；是 2D 程序化近似，非 3D 体积散射 / 屏幕空间光 shafts | **近似，未达真 3D** |
| 光尘 | 2D `draw_circle` 固定 seed 圆点，desktop 段逐帧上飘；粒子感弱、无景深模糊分层 | **近似，未达** |
| 湿地倒影 | 2D 垂直镜像色块 + 逐行波纹，脚下水平镜像亮线可见；是内联色板镜像，非 SSR / 平面反射 | **近似，未达** |
| bloom | 2D 同心圆 ×5 + 亮核近似；`gl_compatibility` 后端无 HDR bloom / 阈值提取 | **近似，未达** |
| 金线深蓝 UI | 深蓝底 + 金色 1px 边框 + 金色中文标题/按钮，三帧均清晰 | **达到** |
| 整体氛围（深蓝夜景 / 黄昏体积光 / 暗部层次） | 亮蓝白天 + 高亮暖金砖地，整体偏亮偏平；与《八方旅人》式深蓝夜景、暖冷对比、氛围光差距明显 | **未达** |

**结论：未达 HD-2D 全绿**。核心差距（沿用 R20/R21 长期边界，本轮不精修）：四项光效全部是 2D 程序化 `draw_*` 近似而非 3D 后处理；无平滑景深/大气远景；亮蓝白天色调而非深蓝夜景氛围；ComfyUI 正式 spritesheet 未接入（当前 `player_spriteframes.tres` 8 个 pose 各仅 1 帧，只有切 pose 换图、无逐帧动作）；像素精灵与 3D 地面的光照/阴影未统一（角色投影仅是简单倒影亮线）。本轮只做录屏交付与目视回看，未改任何美术/工程源件，不冒充达成。

---

## 5. 改动点登记（任务单授权的「等价确定性方式」）

任务单原命令 `--write-movie … --quit-after 450 --script res://test/presentation.gd`（脚本内 `instantiate()+add_child()` 加载 `courtyard.tscn`）在本机真跑时**能出 450 帧、EXIT=0，但 Movie Maker 只录到 2D CanvasLayer（HUD / FX），SubViewport 的 3D 世界（砖地 / 像素骑士）不进入录制**，画面主体缺失 —— 这是 `--script` 与录制在画面语义上的冲突。按任务单授权改用等价确定性方式，改动点如下，全部有真跑对照证据（日志与 PNG 均保留在 `capture/`）：

| 对照短跑 | 方式 | 3D 砖地/角色 |
|---|---|---|
| `r22_baseline` | `--write-movie … res://scenes/courtyard.tscn`（无 `--script`，位置参数） | **完整可见** |
| `r22_nocam` | `--script` + 位置参数、脚本复用引擎单实例、**完全不写相机** | **完整可见** |
| `r22_combo` | `--script` + 位置参数 + 脚本自行 `add_child()`（双实例） | 缺失 |
| `r22_reuse` | `--script` + 位置参数、脚本复用单实例、写相机属性 | 缺失 |
| `r22_cam2` | 写 transform+current+逐帧改相机 | 缺失 |
| `r22_cam3` | 仅 `_initialize` 写 transform/fov（不写 current） | 缺失 |
| `r22_defer` | `call_deferred` 延后到 `_ready` 之后写相机 | 缺失 |

**改动点 1**：命令末尾补位置参数 `res://scenes/courtyard.tscn`，由引擎正常加载场景（单实例、3D 渲染完整）；`presentation.gd` 的 `_initialize()` 改为 `root.get_node_or_null("Courtyard")` 复用引擎加载的实例，不再自行 `instantiate()+add_child()`（也避免双实例）。仍为 `extends SceneTree`、`root.get_node("WorldState")` 取 autoload、`process_frame` 逐帧驱动行为、`--fixed-fps 30 --quit-after 450`、450 帧 15 秒、确定性。

**改动点 2**：任务要求「`_initialize()` 里预置相机」。实测 `--script` 模式下脚本对 `Camera3D` 写任何属性（`position` / `rotation_degrees` / `fov` / `current`，含 `call_deferred` 后写、含逐帧改 transform）都会破坏 SubViewport 的 3D 相机注册，导致 3D 主体消失（上表 4 组对照）。故**相机预置由 `courtyard.tscn` 静态节点承担**（`pos=(0,8,15)` / `rot=(20,0,0)` / `fov=40` / `current=true`，与场景原值一致），脚本在 `_initialize()` 里读取并打印确认、**不写入**；逐帧相机缓动取消，跨帧推进改由画质档位切换 / `set_pose` / HUD flag / `hd2d_fx` 既有逐帧重绘承担。这是「等价」而非「照抄」，如实登记。

---

## 6. 回归与合规

- `verify_fx_mobile.gd` 真跑 `pass=47 fail=0 RESULT=PASS`；`verify_fx_profile.gd` 真跑 `pass=34 fail=0 RESULT=PASS`（**47 / 34 不回退**）。
- 三段门禁（`--headless --import` → `--check-only --script` → `--headless --quit`）及 2 个 verify 的 `check-only` 全部 `EXIT=0`；16 个 `r22_*.log` 的 `SCRIPT ERROR|Parse Error` **SUM=0**。
- 本轮四路均**未写** `project.godot`；本 Rank **未写** `courtyard.tscn` / `quality_settings.*` / `hud.gd` / `hd2d_fx.*` / `verify_frame_data.gd`。仅新增 `godot/test/presentation.gd`（+ 引擎自动生成的 `.uid`）、`capture/` 下本轮产物、`teamwork/Rank-4/` 与 `command_center/ai/4/outbox/` 回执。
- 零付费、未引入任何付费素材生成服务；一次只跑一个 Godot/ffmpeg 任务；无 git 提交。

---

## 7. 未完成项 / 阻塞

1. **HD-2D 全绿未达成**（§4），本轮不精修美术，如实写「未达」。
2. 段 B（mobile 光效全关）3D 主体静止、且 death 姿态 + 放大 HUD 遮挡使角色不可见；因相机写入会破坏 3D 录制，本轮未做逐帧相机/角色位移动画。
3. MP4 仅含视频轨；Movie Maker 自动产出的 `r22_demo.wav` 单独保留，未混入、未谎报音视频合并。
4. 诊断对照产物（`r22_baseline*` / `r22_combo*` / `r22_reuse*` / `r22_nocam*` / `r22_cam2*` / `r22_cam3*` / `r22_defer*` 的 PNG 与 log，以及首版 `r22_demo` 被覆盖前未单独留档）保留在 `capture/` 作为改动点证据，未删除；本文件与 `CAPTURE-REPORT.md` 已如实说明首版录屏主体缺失、定稿版为最终交付。
5. 未做人工试玩逐帧动态验收、未做 GPU 时间戳 / 逐 `_draw()` 拆分；Movie Maker 固定步长录屏不等价于实时性能评测。

> 详细交付清单见 `teamwork/Rank-4/DONE-R22.md`；`capture/CAPTURE-REPORT.md` 已独占追加「R22 实机录屏」段落。
