# DONE-R22.md — Rank-4 实机录屏交付（ROUND=R22）

- 派单 id：`cmd-20261109-124640-188-A4`（`[ROUND=R22]`，附带 godogen 技能纪律）
- 执行：Rank-4（美术管线与工具链）
- 时间：2026-11-09（本机 +0800）
- 必读（已读）：`teamwork/Rank-4/调度任务单-latest.json`、技能 `engines/godot-gdscript.md` §Capture、`project.godot`（只读）、`courtyard.tscn`（只读）、`hybrid_2d3d_animated_sprite.gd` / `quality_settings.gd` / `hud.gd` / `hd2d_fx.gd` / `fx_profile_controller.gd` / `world_state.gd` / `grace_network.tres` / `player_spriteframes.tres` / `verify_fx_mobile.gd` / `verify_fx_profile.gd`（只读）、`capture/CAPTURE-REPORT.md`、`DONE-R21.md` / `DONE-R21B.md`
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`），本机 OpenGL / NVIDIA RTX 4060 Ti
- 一句话结论：**450 帧 / 15 秒 / 1280×720 真实完整实机画面真实产出、MP4 真实产出、ViewImage 首/中/尾三帧真看且跨段行为推进成立；因 `--script` 与录制在本工程 SubViewport 3D 上冲突，按任务单授权改用等价确定性方式并如实登记 2 个改动点；47 PASS / 34 PASS 不回退、三段门禁 SCRIPT ERROR=0；HD-2D 全绿未达成，如实写「未达」；无伪造、无谎报、无 git 提交。**

---

## 0. 环境事实

| 项 | 值 |
|---|---|
| 工程根 | `F:/Game/aierdengfahuan`（`godot/project.godot`，`config_version=5`，本轮四路均冻结不写） |
| 主场景 | `res://scenes/courtyard.tscn`（25 节点，本轮零写入） |
| ffmpeg | 本机可用：`/c/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg`（含 `libx264`） |
| 目录所有权 | 只写 `godot/test/presentation.gd`、`capture/` 下本轮产物、`teamwork/Rank-4/`、回执 `command_center/ai/4/outbox/`。**未写** `project.godot` / `courtyard.tscn` / `quality_settings.*` / `hud.gd` / `hd2d_fx.*` / `verify_frame_data.gd` |

---

## 1. 实际交付清单

| # | 产物 / 动作 | 真跑命令 / 说明 | EXIT | 状态 |
|---|---|---|---|---|
| 1 | `godot/test/presentation.gd` | 新写 `extends SceneTree`：引用 `courtyard.tscn` 单实例、`root.get_node("WorldState")` 取 autoload、`process_frame` 逐帧驱动画质档位切换 / `set_pose` 切帧 / HUD flag 变化；全静态类型标注；无 `class_name` | — | 新增（本轮唯一新增工程内文件，另有引擎自动 `.uid`） |
| 2 | 三段门禁 | `G1 --headless --import` → `G2 --headless --check-only --script res://test/presentation.gd` → `G3 --headless --quit` | 0/0/0 | 全绿，三段 `SCRIPT ERROR\|Parse Error=0`（`r22_gate_*.log`） |
| 3 | **450 帧实机录屏** | `--write-movie capture/r22_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn` | 0 | **真实产出 450 帧**（`r22_capture.log`） |
| 4 | PNG 序列 | `r22_demo00000000.png` ~ `r22_demo00000449.png` | — | 450 张、编号连续 `0..449`、均 1280×720 |
| 5 | WAV | `r22_demo.wav` | — | 5,760,044 字节（Movie Maker 自动音频轨） |
| 6 | **MP4** | `ffmpeg -framerate 30 -start_number 0 -i r22_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart r22_demo.mp4` | 0 | **真实产出**，760,956 字节；ffprobe `h264/yuv420p/1280×720/450 帧/30fps/15.000s` |
| 7 | `capture/R22-RUNTIME-REVIEW.md` | ViewImage 真看首/中/尾帧 + 跨段推进 + HD-2D 差距 + 改动点 + 未完成项 | — | 已写 |
| 8 | `capture/CAPTURE-REPORT.md` | **独占追加**「R22 实机录屏」段落 | — | 已追加 |
| 9 | verify 回归 | `--headless --script res://scripts/verify_fx_mobile.gd` / `verify_fx_profile.gd` | 0/0 | **47 PASS / 34 PASS 不回退** |
| 10 | `teamwork/Rank-4/DONE-R22.md` | 本文件 | — | 已写 |
| 11 | 回执 JSON | `teamwork/command_center/ai/4/outbox/cmd-20261109-124640-188-A4.json` | — | 已写 |

---

## 2. 450 帧与 MP4 是否真实产出：**是**

```
Done recording movie at path: F:/Game/aierdengfahuan/capture/r22_demo.png
450 frames at 30 FPS (movie length: 00:00:15:00), recorded in 00:00:42 (35% of real-time speed).
```

- **PNG**：450 张（`r22_demo00000000.png` ~ `r22_demo00000449.png`），Python 校验 `count=450 first=0 last=449 continuous_0_449=True`；首/中/尾 IHDR 实测均 **1280×720**；首/中/尾 md5 全不同（`02b700…` / `bdf4a2…` / `863ee8…`）→ **非单帧循环**。
- **WAV**：`r22_demo.wav`，**5,760,044 字节**，Movie Maker 自动产出，单独保留。
- **MP4**：`r22_demo.mp4`，**760,956 字节**；ffmpeg 本机可用、`EXIT=0`；ffprobe 实测 `codec_name=h264`、`pix_fmt=yuv420p`、`width=1280`、`height=720`、`nb_frames=450`、`r_frame_rate=30/1`、`duration=15.000000`。**MP4 仅含视频轨，未混入 WAV、未谎报音视频合并**（任务单要求 libx264 / yuv420p / faststart 全部满足）。
- **录屏日志门禁**：`SCRIPT ERROR|Parse Error = 0`；`SEG=3`、`POSE=30`、`HUD=5`、`set_quality+apply=2`；时间线跑到 `frame=450`。

---

## 3. ViewImage 回看结论（首 / 中 / 尾三帧真看）

| 帧 | 所见 |
|---|---|
| **首帧 0**（段 A medium/desktop） | 3D 暖金横砖地面铺满下半屏（透视砖缝、左侧立体台阶）；中央蓝色盔甲像素骑士 `idle` 站立、脚下湿地倒影亮线；左上深蓝金边 HUD「赐福 · 宁姆格福」暗灰字，右上「画质设置 · 低/中/高」金框按钮；地平线暖金 bloom 光点、体积光扇形、冷白/暖金光尘点；亮蓝纯色天空 |
| **中帧 225**（段 B low/mobile） | 砖缝/色块**明显变粗**（low 档 `stretch_shrink=3` 放大）、HUD 面板**明显放大**且文字变「赐福 · 巡礼教堂」暗灰；**体积光/光尘/bloom/倒影四项全部消失**；角色处于 `set_pose(death)` 姿态且被放大 HUD 遮挡，站立骑士不可见 |
| **尾帧 449**（段 C high/desktop） | 砖缝比中段**更细更清晰**（high 档 `shrink=1`）、HUD 面板缩小且文字变「赐福 · 希芙拉河井底」暗灰；骑士 `set_pose(attack_heavy)` 举武器姿态可见、脚下倒影恢复；四项光效**全部恢复** |

**是否跨段有行为推进：是。** 三段各 150 帧（5 秒）：`0–149 medium/desktop 四项全开` →（帧 150 `set_quality("low")+apply()`）`150–299 low/mobile 四项全关` →（帧 300 `set_quality("high")+apply()`）`300–449 high/desktop 四项全开`。全段 **30 次 `set_pose` 切帧**（每 15 帧，8 个冻结 pose 循环）、**5 次 HUD flag 变化**（帧 40/190/250/340/420，`WorldState.set_flag → flag_changed → HUD` 事件驱动增量刷新）、**2 次画质档位切换**（连带 `fx_profile desktop→mobile→desktop`）。HUD 标题、角色姿态、砖缝粗细、HUD 面板尺寸、四项光效开关在三帧间均不同 → 明确跨段推进，非单帧循环。desktop 段另有 `hd2d_fx.gd` 既有 `_process` 逐帧重绘（光尘上飘 / 倒影波纹）提供逐帧动画。如实说明：段 B 光效全关期间 3D 主体静止（相机写入会破坏 3D 录制，故取消逐帧相机/角色位移），仅靠 pose 每 15 帧切换与 HUD 事件推进，存在短静止区间。

**与 HD-2D 目标差距：未达全绿**（详见 `capture/R22-RUNTIME-REVIEW.md` §4）。达到/部分达到：金线深蓝 UI（深蓝底 + 金色 1px 边框 + 金色中文标题/按钮）、像素精灵 vs 3D 透视砖地的 2D/3D 对比。未达/近似：**无平滑景深/DOF 与大气远景**（3D 地面远近全程清晰、天空纯色亮蓝）；体积光/光尘/湿地倒影/bloom 全是 **2D 程序化 `draw_*` 近似**（扇形/圆点/垂直镜像色块/同心圆），非 3D 体积散射、SSR、HDR bloom（`gl_compatibility` 后端限制）；整体是**亮蓝白天 + 高亮暖金砖地**，偏亮偏平，非《八方旅人》式深蓝夜景/黄昏氛围光；ComfyUI 正式 spritesheet 未接入（8 pose 各仅 1 帧、只有切 pose 换图、无逐帧动作）；像素精灵与 3D 地面光照/阴影未统一。本轮只做录屏交付与目视回看、未精修美术，**不冒充全绿**。

---

## 4. 改动点（任务单授权的「等价确定性方式」，如实登记）

任务单原命令（无位置参数、由脚本 `instantiate()+add_child()` 加载 `courtyard.tscn`）**已真跑**：`EXIT=0`、同样 450 帧，但 **Movie Maker 只录到 2D CanvasLayer（HUD/FX），SubViewport 的 3D 世界（砖地 / 像素骑士）不进入录制，画面主体缺失** —— 这是 `--script` 与录制在画面语义上的冲突。按任务单「若 --script 方式与录制冲突，可用等价的确定性方式（仍须 450 帧、真实画面、跨段有行为推进），并如实登记改动点」授权切换，改动点 2 个：

1. **命令末尾补位置参数 `res://scenes/courtyard.tscn`**，由引擎正常加载场景（单实例、3D 渲染完整）；`presentation.gd` 的 `_initialize()` 改为 `root.get_node_or_null("Courtyard")` 复用引擎加载的实例，不再自行 `instantiate()+add_child()`（也避免双实例）。仍为 `extends SceneTree`、`root.get_node("WorldState")` 取 autoload、`process_frame` 逐帧驱动、`--fixed-fps 30 --quit-after 450`、450 帧 15 秒、确定性。
2. 任务要求「`_initialize()` 里预置相机」。实测 `--script` 模式下脚本对 `Camera3D` 写任何属性（`position`/`rotation_degrees`/`fov`/`current`，含 `call_deferred` 后写、含逐帧改 transform）都会破坏 SubViewport 的 3D 相机注册 → 3D 主体消失。故**相机预置由 `courtyard.tscn` 静态节点承担**（`pos=(0,8,15)` / `rot=(20,0,0)` / `fov=40` / `current=true`，与场景原值一致），脚本在 `_initialize()` 里读取并打印确认、**不写入**；逐帧相机缓动取消，跨帧推进改由画质档位切换 / `set_pose` / HUD flag / `hd2d_fx` 既有逐帧重绘承担。这是「等价」而非「照抄」，如实登记。

**对照真跑证据（`capture/` 内 PNG + log 均保留，均经 ViewImage 真看）**：

| 对照短跑 | 方式 | 3D 砖地/角色 |
|---|---|---|
| `r22_baseline` | `--write-movie … res://scenes/courtyard.tscn`（无 `--script`，位置参数） | **完整可见** |
| `r22_nocam` | `--script` + 位置参数、复用单实例、**完全不写相机** | **完整可见** |
| `r22_combo` | `--script` + 位置参数 + 脚本自行 `add_child()`（双实例） | 缺失 |
| `r22_reuse` | `--script` + 位置参数、复用单实例、写相机属性 | 缺失 |
| `r22_cam2` | 写 transform + current + 逐帧改相机 | 缺失 |
| `r22_cam3` | 仅 `_initialize` 写 transform/fov（不写 current） | 缺失 |
| `r22_defer` | `call_deferred` 延后到 `_ready` 之后写相机 | 缺失 |

> 定稿版 `r22_demo` 已覆盖首版（首版缺 3D 主体、未单独留档），**最终交付为定稿版**；诊断产物保留作为改动点证据，未删除、未冒充。

---

## 5. 回归与合规

- `verify_fx_mobile.gd` 真跑 `==== [R19] SUMMARY pass=47 fail=0 total=47 ==== RESULT=PASS`；`verify_fx_profile.gd` 真跑 `==== [R17] SUMMARY pass=34 fail=0 total=34 ==== RESULT=PASS` → **47 PASS / 34 PASS 不回退**。
- 三段门禁 `G1/G2/G3` 与 2 个 verify 的 `--check-only --script` 全部 `EXIT=0`；**16 个 `r22_*.log` 的 `SCRIPT ERROR|Parse Error` SUM = 0**（含 `r22_capture.log`）。
- 本轮四路均**未写 `project.godot`**（工程冻结，保证录屏对应稳定工程）；本 Rank **未写** `courtyard.tscn` / `quality_settings.*` / `hud.gd` / `hd2d_fx.*` / `verify_frame_data.gd`。
- godogen 运行时纪律：用跑起来的画面判断进度（ViewImage 真看 3 帧 + 7 组对照）、结构性事实自己验（能加载、无 SCRIPT ERROR、资产就位）、生成结果先目视检查再接入、零付费不引入任何付费素材生成服务、一次只跑一个 Godot/ffmpeg 任务；GDScript 全静态类型标注；新增文件后跑 `--headless --import`。
- 公共契约：直接改、直接真跑，未新建只读探针/巡检脚本（所有诊断均在唯一交付文件 `presentation.gd` 内迭代并真跑验证）、未主动扫目录做进度巡检、未伪造产物、未谎报成功、未自行 git 提交。

---

## 6. 未完成项与阻塞

1. **HD-2D 全绿未达成**（§3），本轮不精修美术，如实写「未达」。
2. 段 B（mobile 四项全关）3D 主体静止、且 `death` 姿态 + 低分辨率下 HUD 面板放大遮挡使角色不可见；相机/角色逐帧位移动画因破坏 3D 录制而取消，跨段推进靠档位 / pose / HUD / FX 事件。
3. MP4 仅含视频轨；Movie Maker 自动产出的 `r22_demo.wav` 单独保留，未混入、未谎报音视频合并。
4. 首版 `r22_demo`（原命令、缺 3D 主体）已被定稿版覆盖、未单独留档；7 组诊断对照 PNG/log 保留在 `capture/` 作为改动点证据。
5. 未做人工试玩逐帧动态验收、未做 GPU 时间戳 / 逐 `_draw()` 拆分；Movie Maker 固定步长录屏不等价于实时性能评测。
6. 沿用 R20/R21 长期边界：引擎级 640×360 PNG 输出未达成（需改 `project.godot`，本轮冻结禁写）；ComfyUI 正式 spritesheet 未接入；四项光效仍是 2D 程序化近似。
7. **本轮真跑失败项：无**（门禁 / 录屏 / ffmpeg / verify 全部 `EXIT=0`）。

---

## 7. 回执

- 精确路径：`F:/Game/aierdengfahuan/teamwork/command_center/ai/4/outbox/cmd-20261109-124640-188-A4.json`（**未写到工程根 `command_center/`**；工程根本轮复核确认无 `command_center/` 目录）
- 内容：`{"task_id":"cmd-20261109-124640-188-A4","ai":4,"status":"done","result":"引用本 DONE-R22.md 实际结论"}`
- 投递事实（如实登记）：该回执写入精确路径后**被调度中枢即时收取并归档**至 `teamwork/command_center/dispatcher/receipts/cmd-20261109-124640-188-A4.json`（已 Read 校验内容与写入件逐字一致、`task_id`/`ai`/`status` 正确）；因收取机制实时清空 `outbox/`，本轮幂等重写一次后再次被收取，`outbox/` 校验时为空、`receipts/` 留有权威副本。此为协作空间正常消费行为，非回执未写或路径错误。用 `Glob **/cmd-20261109-124640-188-A4.json` 可定位到归档副本。

详细目视回看与差距分析见 `capture/R22-RUNTIME-REVIEW.md`；报告追加见 `capture/CAPTURE-REPORT.md`「R22 实机录屏」段落。
