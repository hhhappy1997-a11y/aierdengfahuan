# DONE-R24B.md — Rank-4 交付清单（R24B / v0.2.0 实机录屏与目视回看）

- 补单 id：`cmd-20261109-211247-261-A4`（`[ROUND=R24B]`）
- 执行：Rank-4（美术管线与工具链）
- 时间：2026-11-09（本机 +0800）
- 前置：四路 R24 已全部 done、工程冻结；本轮只补 15 秒实机录屏与目视回看证据
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable）· OpenGL 3.3 / NVIDIA RTX 4060 Ti
- 详细目视回看：`capture/V020-RUNTIME-REVIEW.md`；报告追加：`capture/CAPTURE-REPORT.md`「R24 v0.2.0 实机录屏」段
- 回执：`teamwork/command_center/ai/4/outbox/cmd-20261109-211247-261-A4.json`
- **一句话结论：450 帧 = 15.000000 s 真实完整画面 + MP4 真实产出；ViewImage 首/中/尾三帧真看——底部战斗 HUD 可见可读、深蓝夜景/三层视差远景/赐福 HUD/画质面板不回退、行为跨整段推进；Boss 仍无可见像素形象（与 Rank-1 R24 登记一致、不翻案）；三段门禁 SCRIPT ERROR=0、47 PASS / 34 PASS 不回退；HD-2D 全绿未达，如实写「未达」；无伪造、无谎报、无 git 提交。**

---

## 1. 录屏命令（R22/R23 已验证形态）

复用 `godot/test/presentation.gd`；命令末尾位置参数 `res://scenes/courtyard.tscn` 为 R22 已验证的必需项（否则 Movie Maker 只录 2D CanvasLayer、3D 砖地/像素骑士不入画）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe \
  --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/v020_demo.png \
  --fixed-fps 30 --quit-after 450 \
  --script res://test/presentation.gd \
  res://scenes/courtyard.tscn
```

## 2. 真实帧数（如实登记）

| 项 | 值 |
|---|---|
| **定稿 run2** | `CAPTURE_EXIT=0`，**450 张 PNG**，`v020_demo00000000.png` ~ `v020_demo00000449.png`，编号连续 `0..449`，均 **1280×720**；`450 frames at 30 FPS (movie length: 00:00:15:00)` = **15.000000 s** |
| 时间线 | `SEG-A frame=0` / `SEG-B frame=150` / `SEG-C frame=300` / `时间线完成 frame=450` |
| 非单帧循环 | 首/中/尾 md5 `2c90061aa2b5` / `f118adc56675` / `0cb370952d6f` 全不同 |
| **首次真跑 run1（偶发短录）** | 同一命令只录 **285 帧 = 9.5 s**（`00:00:09:15`，停在 `frame=270`、无 SEG-C）。清理 `v020_demo*` 后**串行重跑同一命令**得定稿 450 帧，未改任何工程文件 / 脚本参数。根因未逐一追查（`[BossController]` 随机抽招时序 / 首次预热均有可能），`godot/` 运行时脚本经 Grep 诊断无主动 `quit()`；`v020_capture_run1.log` / `v020_capture_run2.log` 两份日志均留证，**如实登记不臆断、不冒充** |

## 3. MP4 与尺寸（真实产出）

| 产物 | 实测 |
|---|---|
| **MP4** | `capture/v020_demo.mp4`，**1,488,378 B**；`ffmpeg -y -framerate 30 -start_number 0 -i v020_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart v020_demo.mp4`，`FFMPEG_EXIT=0` |
| ffprobe | `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000` |
| WAV | `v020_demo.wav`，**5,760,044 B**（Movie Maker 自动音频轨，单独保留） |
| **WAV 是否混入** | **未混入**。ffprobe 音频流计数 = **0**，MP4 仅视频轨；与 R22 `r22_demo.mp4`、R23B `r23_final.mp4` 口径一致，如实登记、不谎报音视频合并 |

> 本机 ffmpeg 9.0.2（含 libx264）可用；录屏（非 headless GPU 渲染）与 ffmpeg 编码**串行**执行，未与其它 GPU 任务并行。

## 4. 三帧目视结论（ViewImage 真看，非推测）

| 帧 | 目视结论 |
|---|---|
| **首 0**（段 A medium/desktop） | 深蓝夜空+星点+远山剪影+冷蓝雾带（分层远景）；密集不规则暖金/青灰石砖透视地面；红发+钴蓝板甲+金饰像素骑士 idle、脚下暖金光池；右上暖金光柱+光尘；左上金线深蓝「赐福 · 宁姆格福」、右上「画质设置 · 低/中/高」面板；**底部 y≈660 金色战斗 HUD 逐字可读** |
| **中 225**（段 B low/mobile） | 石砖纹理仍清晰、像素网格略粗；角色换 pose 完整可见、未被 HUD 遮挡；**四项光效全关**（光柱/光尘/倒影/bloom 消失、更暗）；深蓝夜景与分层远景仍在；标题变「赐福 · 巡礼教堂」(暗)；画质面板尺寸一致；底部战斗 HUD 清晰 |
| **尾 449**（段 C high/desktop） | 石砖最锐利；角色为红发+格纹头巾+胸前发光青蓝宝石 pose，无破图/重复小人；光柱/光尘/光池回归；标题「赐福 · 希芙拉河井底」暗色未点亮（flag 事件驱动生效）；画质面板可见；底部战斗 HUD 清晰 |

**逐项判定**：
- **底部战斗 HUD 可见可读（达到）** —— 三帧金色文字 `玩家 HP 100/100 ｜ Boss HP 100% ｜ 动作 idle 0/0 ｜ 闪避 0 ｜ 命中 0 ｜ 进行中` 逐字可读；但数值整段不推进（无输入注入）。
- **Boss 可见像素形象：无（未达，不翻案）** —— 三帧均只有中央玩家骑士，无独立大型 Boss 精灵；`Boss HP 100%` 仅为 HUD 文本。与 **Rank-1 R24「无可见形象」登记一致，本轮不替它翻案**。
- **深蓝夜景 / 三层视差远景 / 赐福 HUD / 画质面板：均不回退**（分层为 2D 程序化近似）。
- **行为跨整段推进：是** —— `SEG=3 / POSE=30 / HUD=5 / 时间线完成 frame=450`，三帧 md5 全不同；段 B 四项全关期间 3D 主体静止（沿用 R22 边界）。
- **与《八方旅人》式 HD-2D 差距：未达全绿** —— 景深/光效仍为 2D `draw_*` 近似（无 3D 深度雾/DOF/体积散射/SSR/HDR bloom），地面高倍平铺重复感与白天感残留，8 pose 各仅 1 帧无逐帧动画，角色为 3D `AnimatedSprite3D` 像素贴图，Boss 无可见形象。本轮未精修美术，**不冒充全绿**。

## 5. 门禁与回归（真跑，不回退）

| 段 / 脚本 | 命令（`--headless --path <root>`） | EXIT | 结论 |
|---|---|---|---|
| G1 | `--import` | 0 | 无 SCRIPT ERROR |
| G2 | `--check-only --script res://test/presentation.gd` | 0 | 无 SCRIPT ERROR |
| G3 | `--quit` | 0 | 无 SCRIPT ERROR（仅既有 `2 ObjectDB instances were leaked` WARNING） |
| RUN mobile | `--script res://scripts/verify_fx_mobile.gd` | 0 | `pass=47 fail=0 total=47 RESULT=PASS` |
| RUN profile | `--script res://scripts/verify_fx_profile.gd` | 0 | `pass=34 fail=0 total=34 RESULT=PASS` |

- **9 份 `v020_*.log` 的 `SCRIPT ERROR|Parse Error|ERROR:` 合计 = 0**（逐份全 0）→ **SCRIPT ERROR=0 通过**。
- **47 PASS / 34 PASS 不回退**。
- 说明：Grep 工具目录 glob 对含 ANSI 控制符的 Godot 日志未匹配，门禁统计改用任务明文的命令行 `grep` 完成（逐份计数全 0），Grep 工具对精确单文件交叉一致；如实登记工具行为，不影响结论。

## 6. 实际交付清单

| # | 产物 / 动作 | 状态 |
|---|---|---|
| 1 | `capture/v020_demo00000000.png` ~ `v020_demo00000449.png`（450 张 1280×720） | 真实产出 |
| 2 | `capture/v020_demo.wav`（5,760,044 B，单独保留） | 真实产出 |
| 3 | `capture/v020_demo.mp4`（1,488,378 B，h264/yuv420p/+faststart，仅视频轨） | 真实产出 |
| 4 | `capture/V020-RUNTIME-REVIEW.md`（三帧目视 + 逐项判定 + HD-2D 差距 + 未完成项） | 已写 |
| 5 | `capture/CAPTURE-REPORT.md`「R24 v0.2.0 实机录屏」段 | **独占追加**（未覆盖他人内容） |
| 6 | `capture/v020_capture_run1.log`（偶发短录）/ `v020_capture_run2.log`（定稿）/ `v020_ffmpeg.log` / `v020_gate_g*.log` / `v020_verify_fx_*.log` | 运行输出留档 |
| 7 | `teamwork/Rank-4/DONE-R24B.md`（本文件） | 已写 |
| 8 | 回执 `command_center/ai/4/outbox/cmd-20261109-211247-261-A4.json` | 已写（见 §8） |

**目录所有权核对**：只写 `capture/` 与 `teamwork/Rank-4/`（+ 回执到 `command_center/ai/4/outbox/`）；**未写** `project.godot` / `courtyard.tscn` / `quality_settings.*` / `hud.gd` / `hd2d_fx.*` / `verify_fx_*.gd` / `presentation.gd` / 任何 `.tres` / `.png` 美术资源。零付费、零外部依赖、一次只跑一个 GPU 任务、**未自行 git**。

## 7. 未完成项与阻塞

1. **HD-2D 全绿未达成**（§4），本轮不精修美术、不谎报达标。
2. **Boss 无可见像素形象**（与 Rank-1 R24 一致、不翻案）；`courtyard.tscn` 内 encounter 以 instance 接入（node_count 29），Boss AI 日志真实推进但画面无独立 Boss 精灵。
3. **底部战斗 HUD 数值整段不推进**（无输入注入；R24 Rank-1 已登记），按公共契约未新建只读探针/巡检脚本、未做交互注入。
4. **run1 首次真跑偶发短录 285 帧 = 9.5 s**：日志留证、根因未逐一追查、不臆断；定稿为 run2 450 帧。
5. **WAV 未混入 MP4**（音频流=0），`v020_demo.wav` 单独保留，未谎报音视频合并。
6. **段 B（low/mobile 四项全关）3D 主体静止**，仅靠 pose 每 15 帧切换与 HUD 事件推进，存在短静止区间（沿用 R22）。
7. **画面左侧固定深蓝色尖锐几何形状**：首/中/尾均出现、位置固定，为 R23 已登记既有场景/FX 元素，来源未逐一追查，如实登记不臆断。
8. **既有非致命 WARNING**（`2 ObjectDB instances were leaked at exit`）非 SCRIPT ERROR、不改退出码，如实登记。
9. **未做人工鼠标点击 / 真机试玩逐帧动态验收**；Movie Maker 固定步长录屏不等价于实时性能评测。
10. **Grep 工具目录 glob 对含 ANSI 控制符日志未匹配**，门禁统计由命令行 `grep` 完成（§5），结论不受影响。
11. git 收尾按公共契约由总指挥执行，本轮未自行 git。

**阻塞：无。** 本轮计划内产物（15 秒录屏 / MP4 / 三帧目视 / 报告追加 / 门禁 / DONE / 回执）全部完成。

## 8. 回执

- 精确路径：`F:/Game/aierdengfahuan/teamwork/command_center/ai/4/outbox/cmd-20261109-211247-261-A4.json`
- 内容：`{"task_id":"cmd-20261109-211247-261-A4","ai":4,"status":"done","result":"引用本 DONE-R24B.md 实际结论"}`

**回执落盘后续（如实登记，沿用 R22/R24 先例）**：回执写入精确路径后被调度中枢即时收取，原样归档到 `teamwork/command_center/dispatcher/receipts/cmd-20261109-211247-261-A4.json`（755 B，`cmp` 校验 `CONTENT_IDENTICAL=True`）。因收取机制会实时搬移 / 清空 `outbox/`（校验过程中出现过 python 打开瞬间文件被收走的竞态），已从归档**幂等复制回** `ai/4/outbox/` 精确路径；最终两处均为 755 B，精确路径经 stdin 重定向 JSON 解析校验 `VALID_JSON task_id=cmd-20261109-211247-261-A4 ai=4 status=done result_len=427`。此为协作空间正常消费行为，**非回执未写、非路径错误**。
