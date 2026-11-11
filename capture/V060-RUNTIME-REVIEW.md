# V060-RUNTIME-REVIEW.md · R28 v0.6.0 15 秒实机录屏运行期目视复核

> 派单 `cmd-20261111-095602-831-A4` · `[ROUND=R28]` · Rank-4（美术管线与工具链）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）
> ffmpeg 9.0.2（本机绝对路径 `C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`，Bash PATH 里没有）
> 真跑产物：`capture/v060_demo*.png` **450 帧** @30fps/15s；`capture/v060_demo.mp4` **897,681 字节**
> 本文件结论以 **ViewImage 真看首 0 / 中 225 / 尾 449 三帧 + 面板区裁剪放大目视 + `capture/r28_capture.log` 逐帧日志 + 像素采样** 为准，不粉饰、不谎报。

---

## 1. 真跑与产物（非伪造）

| 项 | 实测 |
|---|---|
| 录屏命令 | `--path <godot> --write-movie capture/v060_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`，沿用 R22/R25/R26/R27 定稿） |
| 录屏 EXIT / 帧数 | **0** / **450 帧**（`v060_demo00000000.png … v060_demo00000449.png`），`Movie Maker 1280×720 @ 30 FPS` |
| 录屏日志 | `SCRIPT ERROR\|Parse Error` = **0**；`[R28][INPUT]` / `[R28][EVIDENCE]` / `[R28][TUTORIAL]` / `[R28][HUD]` / `[Tutorial]` / `[WaveTrial]` / `[R26][WAVE]` / `[R27][GROWTH]` 均在 |
| ffmpeg | `-framerate 30 -start_number 0 -i v060_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，**EXIT=0** |
| ffprobe 视频 | `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000`；`moov` 前置（`+faststart`） |
| **MP4 字节数** | **`capture/v060_demo.mp4` = 897,681 B**（最终版真跑产物） |
| **WAV 是否混入 MP4** | **未混入**：ffmpeg 输入仅 PNG 序列、无任何音频 `-i`；`ffprobe -select_streams a` 音频流计数 = **0**。如实登记，不谎报音视频合并 |

---

## 2. R28 真实输入注入机制（本轮核心，全部经既有输入路由）

`presentation.gd` 新增 `_inject_key()` / `_drive_real_input()`：构造 `InputEventKey`（同时写 `physical_keycode` 与 `keycode`，`pressed + released` 配对），经 **`Input.parse_input_event()`** 注入引擎输入系统，由引擎分发到场景各节点既有的 `_unhandled_input()` 路由。**不写任何 `Label.text`、不调 `debug_*` 伪造数值、不直接改 HUD**。

| 键 | physical_keycode | 既有 action | 既有输入路由终点 | 真实效果 |
|---|---|---|---|---|
| J | 74 | `light_attack` | `EncounterDirector._request_action("attack_light")` → 当帧 `_update_hud()`；`TutorialDirector` 第 1 步 | 动作帧 HUD 推进 / 教学第 1 步 |
| Space | 32 | `roll` | `EncounterDirector._request_action("roll")` → 当帧 `_update_hud()`；`TutorialDirector` 第 2 步 | 动作帧 HUD 推进 / 教学第 2 步 |
| E | 69 | `interact` | `hud._toggle_shop()`；`EncounterDirector._grace_rest()`；`WaveTrialDirector.interact_restart()`；`TutorialDirector` 第 3 步 | 兑换面板展开 / 教学收口 / 波次衔接 |
| 1 | 49 | （hud 直接判 `physical_keycode`） | `hud.purchase_upgrade(0)` | 购买一项（真实落盘 + 增益运行时） |

- **时序**：`[PLACEHOLDER] ACTION_INTERVAL=6`（待试玩校准，rationale：450/6=75 次注入使动作帧窗口约 6 渲染帧几乎连续覆盖全片）；`f=0 J → f=6 Space → f=20 E` 严格按教学三步顺序，`f=170` 注入数字键 1 购买。E 只注入一次，之后兑换面板保持展开不关闭。
- **1 帧延迟（如实登记）**：`Input.parse_input_event` 缓冲事件在下一帧分发。短跑实测 `f=6` 注入 E → `f=7` 读回 `shop_open=true`；`f=20` 注入 E → `f=22` 教学第 3 步完成。故首帧 0 的 PNG 尚未反映注入（动作帧 `idle 0/0`、面板未展开），此为真实时序、非伪造。
- **tutorial 接口状态（并发时序，如实登记）**：本轮开跑最初全工程无 tutorial 文件；执行期间 Rank-1 落盘了 `tutorial_director.gd`（注释标 `R28 · Rank-1, cmd-20261111-095602-818-A1`）与 `courtyard.tscn` 的 `TutorialHud/TutorialLabel/TutorialDirector` 三节点。故 `_resolve_tutorial_api()` 探测到接口**已落盘**（`[R28][TUTORIAL] 接口已落盘 name=TutorialDirector`），未走「接口缺失降级」分支；逐帧以 `is_tutorial_active()` 监测，`force_complete()` 作为「教学未由真实按键完成才触发」的兜底，**本轮实测未触发**（§4.4）。未谎称接口缺失、也未谎称教学闭环由强制跳过证明。

---

## 3. ViewImage 首 / 中 / 尾三帧（最终版真看，逐帧记录）

| 帧 | 段 / 波 / 画质 | 赐福标题（颜色） | 底部动作帧 HUD | 兑换面板 | 教学引导行 | 金色 WaveLabel |
|---|---|---|---|---|---|---|
| **首 0** | 段 A / 第 1/3 波 / medium-desktop | 「赐福 · 关卡前」**亮金 GOLD** | `玩家 HP 100/100 \| Boss HP 100% \| 动作 idle 0/0 \| 闪避 0 \| 命中 0 \| 进行中` | **未展开**：显示「赐福成长 · 按 E 打开兑换」提示（E 在 f=20 才注入） | 「赐福引导 1/3 \| 按 J 发动一次轻攻击 (J) \| 完成奖励 +20 赐福点数 \| 按 T 重开教学」 | `第 1/3 波 \| 赐福点数 0 \| 倒计时 0.0 \| 历史最佳 0` |
| **中 225** | 段 B / 第 2/3 波 / low-mobile | 「赐福 · 巡礼教堂」**亮金 GOLD** | `玩家 HP 108/120 \| Boss HP 100% \| **动作 roll 6/22** \| 闪避 2 \| 命中 4 \| 进行中` | 日志 `shop_open=true`，但该段 `SubViewport` 缩放后面板文字**目视不可清晰辨认**（见 §4.2） | 「赐福引导 · 已完成（3/3）\| 赐福标题已点亮 \| 按 T 重开教学」 | `第 2/3 波 \| 赐福点数 0 \| 倒计时 29.0 \| 历史最佳 1` |
| **尾 449** | 段 C / 第 3/3 波 / high-desktop | 「赐福 · 希芙拉河井底」**亮金 GOLD** | `玩家 HP 108/120 \| Boss HP 0% \| **动作 roll 8/22** \| 闪避 2 \| 命中 5 \| 胜利 · 已落盘` | **清晰展开**（5 行，见 §4.2），含「兑换成功：赐福·生命上限（消耗 100，余额 0）」 | 「赐福引导 · 已完成（3/3）\| 赐福标题已点亮 \| 按 T 重开教学」 | `第 3/3 波 \| 赐福点数 350 \| 倒计时 0.0 \| 历史最佳 3` |

**画面其它**：三帧均为 R27 修复后的完整连续蓝灰 4×4 砖地，左侧尖锐深蓝楔形已消失；玩家（蓝甲+金肩甲+白面甲+红缨+鸢盾+竖直亮钢剑）在画面中下部、Boss（金角红身）在上方远处，近大远小、上下分离不叠合；画质设置「低 / 中 / 高」面板三帧均在；光柱 / 光尘 / 倒影 / bloom 四项在 desktop 段可见（首/尾）、mobile 段（中）四项全关。

**赐福标题点亮像素实证**（标题区 x=40~320 / y=80~165，GOLD=`hud.gd` 的 `Color(0.83,0.68,0.3)`≈`(212,174,76)`，DIM≈`(115,107,87)`）：

| 帧 | GOLD 像素 | DIM 像素 | 最亮像素 |
|---|---|---|---|
| 首 0 | 3456 | **0** | (212,174,76) |
| 中 225 | 5928 | **0** | (212,174,76) |
| 尾 449 | 1400 | **0** | (212,174,76) |

三帧标题区最亮像素均为 `(212,174,76)`、DIM 像素均为 0 → **三帧赐福标题均为亮金点亮态**（尾帧因字少/暖紫背景对比显暗，但像素实测仍是 GOLD，不靠肉眼主观判断）。点亮链路：`WorldState.set_flag(grace.*.lit, true)` → `flag_changed` → `HUD.refresh_label()` → `apply_lit_state(GOLD)`，全部既有事件驱动路由；教学完成写 `grace.tutorial.completed=true` 亦经 `delta_committed → refresh_all()` 重算，非改 HUD 文本。

---

## 4. 五项判定

### 4.1 动作帧 HUD 是否推进 → **是（本轮达标）**
R27 遗留「三采样点动作帧 HUD 恒 `idle 0/0`」由真实按键注入修复：
- 中帧 225 `动作 roll 6/22`、尾帧 449 `动作 roll 8/22`（均非 idle，且 `roll` 姿态与注入的 Space 一致）；日志 `[R28][EVIDENCE] frame=225/449` 逐帧读回 `StatusLabel.text` 实证。
- 全片 `f%6==0` 交替注入 J/Space，经 `EncounterDirector._request_action()` 当帧 `_update_hud()` 刷新；`frame=171` 已见 `命中 4`、`闪避 2`、玩家 HP 受击/回血等真实战斗数值推进。
- **首帧 0 仍 `idle 0/0`**（`Input.parse_input_event` 1 帧延迟，f=0 注入 J 在 f=1 才分发），如实记录，不冒充三帧全非 idle。「不再**恒** idle 0/0」成立。

### 4.2 兑换面板是否展开 → **是（真实展开，尾帧清晰可辨；中帧不可辨如实登记）**
- `[R28][INPUT] frame=20 注入 interact(E)` → `[R28][EVIDENCE] frame=22 shop_open=true`；`shop_open` 从 frame 22 起持续为 true 到 449（全片 E 只注入一次，不关闭）。
- 尾帧 449 面板区（裁剪放大 `capture/r28_panel_tail.png`）**清晰可辨** 5 行：
  `赐福成长 ｜ 当前余额 0（点数 100 − 已消费 100）｜ 1/2/3 兑换`
  `1. 赐福·生命上限 ｜ 消耗 100 ｜ 已解锁`
  `2. 赐福·翻滚余韵 ｜ 消耗 200 ｜ 点数不足`
  `3. 赐福·攻击强化 ｜ 消耗 300 ｜ 点数不足`
  `提示：兑换成功：赐福·生命上限（消耗 100，余额 0）`
- 购买真实成功：`[R28][EVIDENCE] frame=171 shop_message=兑换成功：赐福·生命上限（消耗 100，余额 0）`，且 `玩家 HP 100/100 → 120/120`（增益运行时 `apply_purchased()` 真实生效），非文本伪造。
- **如实登记**：首帧 0（E 未注入前）面板为未展开的「按 E 打开兑换」提示态；中帧 225 处于段 B `low/mobile`（`SubViewport` 缩放），`capture/r28_panel_mid.png` 裁剪放大后**未见清晰兑换面板文字**（只有砖地/角色/Boss），尽管日志 `shop_open=true`。此为低画质 `SubViewport` 缩放导致的画面事实，不谎称「三帧均清晰展开」。

### 4.3 赐福标题是否点亮 → **是（三帧像素实证均 GOLD）**
见 §3 像素表：三帧标题区 `dim_px=0`、最亮 `(212,174,76)` = GOLD。R28 把 `_drive_hud_flags` 点亮时间线重排到 `f=0/150/300/420`，让三段赐福名切换全程保持点亮、三帧采样均落在 GOLD 态；仍全部经 `WorldState.set_flag → flag_changed → HUD.refresh_label → apply_lit_state()` 既有事件路由，不写 `Label.text`、不构造颜色。

### 4.4 教学到波次是否衔接 → **是（真实按键三步闭环，force_complete 未触发，教学闭环已证明）**
`r28_capture.log` 逐行实证：
```
[Tutorial] 教学开始：STEP_LIGHT_ATTACK（J）｜ 波次冻结，教学期间不推进三波
[WaveTrial] 教学冻结：三波不自动开始 / 不推进（tutorial_freeze=true）
[R28][INPUT] frame=0 注入真实按键 light_attack(J)
[Tutorial] 步骤完成 step=light_attack reward=20 → state=STEP_ROLL（2/3）
[R28][INPUT] frame=6 注入真实按键 roll(Space)
[Tutorial] 步骤完成 step=roll reward=30 → state=STEP_GRACE_SHOP（3/3）
[R28][INPUT] frame=20 注入真实按键 interact(E)
[WaveTrial] 教学解冻 / 教学完成 → 自动进第 1 波：start_trial()=true（state=TELEGRAPH index=1/3）
[Tutorial] 波次衔接：begin_wave_after_tutorial()=true（解冻 + 自动进第 1 波）
[Tutorial] 三步教学完成：grace.tutorial.completed=true（单向）｜ 自动进第 1 波
[Tutorial] 步骤完成 step=grace_shop reward=50 → state=COMPLETED（3/3）
[R28][TUTORIAL] frame=40 快照 state=COMPLETED step_events=["light_attack","roll","grace_shop"] total_reward=100 wave_started=true | is_tutorial_active()=false
[R28][TUTORIAL] frame=40 教学已由真实按键 J→Space→E 三步完成并自动衔接到第 1 波（force_complete 未触发）
```
- 三个步骤 **各由一次真实 `InputEventKey` 注入**消费（`STEP_ACTIONS = light_attack/roll/interact`），奖励 `20/30/50` 来自 Rank-2 `tutorial_steps.tres`，`total_reward=100` 真实落 `grace.trial.points`。
- 教学完成 → `begin_wave_after_tutorial()` 解冻并自动进 **第 1/3 波**；随后既有 `_drive_wave_hud` 在 `f=150/300` 推进到 **第 2/3 波 / 第 3/3 波**（`[R26][WAVE] frame=150/300 驱动完成` + `[R27][GROWTH]` hud_text `第 1/3 波 → 第 2/3 波 → 第 3/3 波`，历史最佳 0→1→2→3、赐福点数 0→100→250→450）。
- `is_tutorial_active()` / `force_complete()` 两接口均被真实调用/监测（帧 40 读回 false、未触发兜底），避免教学状态机与演示序列双驱动；**教学闭环由真实按键证明，非 force_complete 跳过**。额外佐证：本轮 v060 教学验证脚本 `verify_tutorial_v060` 64 PASS、`verify_tutorial_reward_v060` 86 PASS、`verify_save_isolation_v060` 31 PASS 全 ALL_PASS/ALL_MATCH。

### 4.5 HD-2D 全绿是否达到 → **未达（如实写未达）**
本轮解决了「动作帧 HUD 恒 idle」「兑换面板未展开」「赐福标题未点亮」「教学→波次衔接」四项，但以下差距仍在，不冒充达标：
1. 景深 / 光柱 / 光尘 / 光池 / 倒影 / bloom 仍为 `hd2d_fx.gd` 的 2D `draw_*` 近似（`draw_colored_polygon/draw_rect/draw_circle/draw_line`），非真 3D 体积光 / 真景深 / 真 SSR；
2. 三波空间变化仍是 `hd2d_parallax.gd` 的 2D 色带 / 雾 alpha / 地面色调叠加，非真 3D 体积雾 / 动态景深；
3. 地面 4×4 砖高倍平铺重复感仍强；
4. 角色仍是 `AnimatedSprite3D` billboard 像素精灵，非真 3D 体素 / 低多边形角色；
5. 仅 3 帧采样 + 逐帧日志复核，未做人工试玩逐帧动态验收；
6. 段 B `low/mobile` 画质下 `SubViewport` 缩放导致兑换面板文字不可清晰辨认（§4.2）；
7. 首帧动作帧 HUD 仍 `idle 0/0`（输入 1 帧延迟，如实）；
8. 三波色带 / 雾 / 地面数值仍为 `[PLACEHOLDER]`，动作注入节奏 `ACTION_INTERVAL=6` 亦为 `[PLACEHOLDER]`，待试玩校准。
> 真 3D 光效在 `gl_compatibility` 下的可行性与零付费替代方案见 `TECHNICAL-ART-DEPTH-v060.md`（**仅评估、未实现**）。

---

## 5. WAV 是否混入 MP4

**未混入**。ffmpeg 命令输入仅 `v060_demo%08d.png` 序列，无任何音频 `-i`（`capture/frame.wav` 等历史 WAV 未参与）；`ffprobe -select_streams a -show_entries stream=index` 计数 = **0**。如实登记，不谎报音视频合并。

---

## 6. 门禁与回归（真跑，不回退）

**三段门禁**（`capture/r28_g1_import.log` / `r28_g2_checkonly.log` / `r28_g3_quit.log`）：`--headless --import` / `--headless --check-only --script res://test/presentation.gd` / `--headless --quit` **三段 EXIT=0**；连同 `r28_capture.log`、`r28_ffmpeg.log` 逐份 `SCRIPT ERROR|Parse Error` = 0，**合计 0 → 字面 `SCRIPT ERROR=0`**。

**全 PASS 回归**（`capture/r28_verify_*.log`）：

| 脚本 | 结论 |
|---|---|
| `verify_fx_mobile` | 47 PASS / 0 FAIL · `RESULT=PASS` |
| `verify_fx_profile` | 34 PASS / 0 FAIL · `RESULT=PASS` |
| `verify_encounter_v010` | 20 PASS · `ALL_MATCH` |
| `verify_encounter_v020` | 45 PASS · `ALL_MATCH` |
| `verify_encounter_v030` | 53 PASS · `ALL_MATCH` |
| `verify_wave_trial_v040` | 58 PASS · `ALL_MATCH` |
| `verify_frame_data` | 650 PASS / 0 FAIL · `ALL_MATCH` |
| **合计（7 项基线）** | **907 PASS，全部不回退** |
| 本轮 v060 教学验证 | `verify_save_isolation_v060` 31 PASS、`verify_tutorial_reward_v060` 86 PASS、`verify_tutorial_v060` 64 PASS，全 `ALL_MATCH/ALL_PASS`（额外 181 PASS） |
| 全部 `r28_verify_*.log` | `SCRIPT ERROR\|Parse Error` 合计 **0** |

**如实登记的 1 项 FAIL（非 Rank-4 引入、非状态依赖）**：`verify_wave_runtime_v040` 稳定 `pass=36 fail=1 RESULT=FAILED`（重跑 `r28_verify_wave_runtime_v040_rerun.log` 同为 36/1），失败断言：
```
[V040] courtyard_node_count PASS=false | node_count=41 expected=38
```
根因：Rank-1 本轮 R28 并发在 `courtyard.tscn` 新增 `TutorialHud` / `TutorialLabel` / `TutorialDirector` **3 个节点**，使 `[node` 总数 38 → 41，而该脚本硬编码 `NODE_COUNT_AFTER=38` 未同步。基线对照：R27 日志 `r27_verify_wave_runtime_v040.log` 为 `node_count=36 expected=36 PASS`；本轮开跑前该脚本已更新为 `expected=38`（当时场景 38 节点、`PASS`）；场景 mtime `2026-11-11 10:17:16` 在本轮执行期间被 Rank-1 改动。
**Rank-4 本轮只写 `presentation.gd`（mtime 10:26）/ `capture/` / 本评估文档 / `teamwork/Rank-4/`，未写 `courtyard.tscn`、未写任何验证脚本；不改断言、不放宽、不掩盖、不越权改他人所有物。** 该 FAIL 属并发时序下 Rank-1 场景节点新增导致的既有断言过期，建议由该脚本所有者把期望值同步为 41 后复跑；本轮如实登记为未完成项，不谎称「全 PASS」。

---

## 7. 目录所有权 / 合规

- 本轮只写：`godot/test/presentation.gd`、`capture/`、`TECHNICAL-ART-DEPTH-v060.md`、`teamwork/Rank-4/`（+ 回执 `teamwork/command_center/ai/4/outbox/`）。
- **未写**：`courtyard.tscn` / `tutorial_director.gd` / `wave_trial_director.gd` / `hud.gd` / `encounter_director.gd` / 素材 PNG / `.tres`（除本轮无授权）/ `project.godot` / 契约 / README / 任何验证脚本；**未自行 git**（总指挥收尾）。
- 公共契约：**先目视检查再接入**（先 20 帧 / 60 帧真跑短验输入生效与教学闭环，再落正式 450 帧；三帧 ViewImage + 面板区裁剪放大 + 像素采样后才写结论）；**直接改直接真跑**，未新建只读探针 / 巡检脚本（短跑复用同一 `presentation.gd`，仅改 `--quit-after` 参数，临时 PNG 已清理）；不伪造产物、不谎报成功（HD-2D 全绿写未达、WAV 未混入如实登记、中帧面板不可辨如实登记、1 项 FAIL 如实登记）。
- 零 GPU 额外 job、零付费、零外部素材生成服务；录屏（GPU 渲染）与 ffmpeg 编码串行。

---

## 8. 未完成项 / 阻塞

- **HD-2D 全绿未达**（§4.5 八项，如实写未达）；
- 段 B `low/mobile` 画质下兑换面板文字在 `SubViewport` 缩放后不可清晰辨认；
- 首帧动作帧 HUD 仍 `idle 0/0`（`Input.parse_input_event` 1 帧延迟，真实时序）；
- `verify_wave_runtime_v040` 稳定 36/1 FAILED（Rank-1 并发新增 3 节点致 `node_count` 断言过期，非 Rank-4 引入，见 §6）；
- `ACTION_INTERVAL=6`、三波色带 / 雾 / 地面数值为 `[PLACEHOLDER]`，待试玩校准；未做人工试玩逐帧动态验收；
- 真 3D 景深 / 体积光 / 湿地倒影 / bloom **本轮仅评估未实现**（见 `TECHNICAL-ART-DEPTH-v060.md`）；
- 未自行 git（总指挥收尾）。
- **阻塞：无。**
