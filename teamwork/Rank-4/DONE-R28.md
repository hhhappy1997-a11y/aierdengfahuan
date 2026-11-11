# DONE-R28.md · Rank-4 交付报告

> 派单 `cmd-20261111-095602-831-A4` · `[ROUND=R28]` · v0.6.0 完善旧内容
> 角色：Rank-4 执行 AI（美术管线与工具链）
> 工程根 `F:/Game/aierdengfahuan` · 协作空间 `teamwork/` · 调度中枢 `teamwork/command_center/`
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）
> ffmpeg `C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`（9.0.2，Bash PATH 里没有）
> 真跑结论：**真实按键 `Input.parse_input_event` 注入 J/Space/E/1 生效** → 教学三步由真实按键闭环并衔接到第 1/3 波、动作帧 HUD 不再恒 idle 0/0、兑换面板真实展开且购买成功、赐福标题三帧均点亮；
> **15 秒录屏 450 帧 + MP4 897,681 B**；首/中/尾三帧 ViewImage 真看 + 面板裁剪 + 像素采样；
> 三段门禁 `SCRIPT ERROR=0`；回归 `47/34/20/45/53/58/650 = 907 PASS`（+ v060 教学 181 PASS）不回退；
> **如实登记 1 项 FAIL（Rank-1 并发新增 3 节点致 `verify_wave_runtime_v040` 断言过期，非本轮引入）**；**HD-2D 全绿仍未达（如实写未达）**；真 3D 光效**仅评估未实现**。

---

## 0. 本轮任务定位

R27（v0.5.0）遗留画面缺口：「三采样点动作帧 HUD 恒 `idle 0/0`、兑换面板从未展开、赐福标题采样帧未点亮、教学→波次未衔接」。本轮 R28 做「完善旧内容」：
改 `presentation.gd` 注入**真实输入事件**（非 `debug_*` / 非直接写 HUD），真跑 15 秒 450 帧录屏回看，另写 `gl_compatibility` 下真 3D 光效可行性评估（只评估不改渲染件）。

---

## 1. 实际交付清单（逐文件，均真实落盘）

| # | 文件 | 动作 |
|---|---|---|
| 1 | `godot/test/presentation.gd` | **改**：新增 `_inject_key()` / `_drive_real_input()` / `_guard_tutorial()` / `_log_input_evidence()` / `_resolve_tutorial_api()`；R28 常量（J/Space/E/1、ACTION_INTERVAL=6、E_OPEN_FRAME=20、BUY_FRAME=170、TUTORIAL_GUARD_FRAME=40）；`_drive_hud_flags` 点亮时间线重排；R22~R27 全部既有驱动逐字保留 |
| 2 | `capture/v060_demo00000000.png … v060_demo00000449.png` | **新增 450 帧** 15 秒实机录屏（1280×720 @30fps / 15.000000s） |
| 3 | `capture/v060_demo.mp4` | **新增 897,681 B**（libx264 / yuv420p / 1280×720 / 30fps / 450 帧 / 15.000000s，`moov` 前置） |
| 4 | `capture/V060-RUNTIME-REVIEW.md` | **新增**：三帧目视复核 + 五项判定 + WAV/门禁/回归 + 未完成项 |
| 5 | `TECHNICAL-ART-DEPTH-v060.md` | **新增**：`gl_compatibility` 下真 3D 景深/体积光/湿地倒影/bloom 可行性评估 + 零付费替代方案与优先级（**仅评估**） |
| 6 | `capture/CAPTURE-REPORT.md` | **独占追加**「## 11. R28 v0.6.0」段落 |
| 7 | `capture/r28_*.log`（门禁 3 / 录屏 1 / ffmpeg 1 / 回归 12+ / 短验 2） | 真跑日志 |
| 8 | `capture/r28_panel_head.png` / `r28_panel_mid.png` / `r28_panel_tail.png` | 三帧面板区裁剪放大目视证据 |
| 9 | `teamwork/Rank-4/DONE-R28.md` | 本文件 |
| 10 | `teamwork/command_center/ai/4/outbox/cmd-20261111-095602-831-A4.json` | 回执 JSON |

短验临时产物 `capture/r28_probe*.png` 已清理（短跑复用同一 `presentation.gd`，未新建只读探针/巡检脚本）。

---

## 2. 真实按键注入方式（任务①，是否生效：**生效**）

**方式**：构造 `InputEventKey`（同时写 `physical_keycode` 与 `keycode`、`pressed + released` 配对），调用 **`Input.parse_input_event()`** 注入引擎输入系统，由引擎分发到场景节点既有 `_unhandled_input()` 路由。**未直接改 HUD 文本、未调 `debug_*` 伪造数值、未写 `Label.text`**。

| 键 | keycode | 既有 action | 既有路由终点 → 真实效果 |
|---|---|---|---|
| J | 74 | `light_attack` | `EncounterDirector._request_action("attack_light")` 当帧 `_update_hud()`；`TutorialDirector` 第 1 步 |
| Space | 32 | `roll` | `EncounterDirector._request_action("roll")` 当帧 `_update_hud()`；`TutorialDirector` 第 2 步 |
| E | 69 | `interact` | `hud._toggle_shop()`（面板展开）/ `encounter._grace_rest()` / `wave.interact_restart()`；`TutorialDirector` 第 3 步 |
| 1 | 49 | hud 直判 keycode | `hud.purchase_upgrade(0)` 购买一项（落盘 + 增益运行时） |

- **时序**：`[PLACEHOLDER] ACTION_INTERVAL=6`（450/6=75 次注入，rationale：动作帧窗口约 6 渲染帧，J/Space 交替使 HUD 全片不恒 idle）；`f=0 J → f=6 Space → f=20 E` 严格按教学三步顺序，`f=170` 购买；E 只注入一次，面板全片保持展开。
- **生效实证（真跑日志 + 画面）**：`f=6` 注入 E → `f=7` 读回 `shop_open=true`；`f=20` 注入 E → 教学第 3 步完成；`f=170` 注入 1 → `frame=171 shop_message=兑换成功：赐福·生命上限（消耗 100，余额 0）` 且 `玩家 HP 100/100 → 120/120`；中帧 `动作 roll 6/22`、尾帧 `动作 roll 8/22`。
- **1 帧延迟（如实）**：`parse_input_event` 缓冲事件下一帧分发，故首帧 0 PNG 仍 `idle 0/0` / 面板未展开，属真实时序非伪造。

**Rank-1 tutorial 接口并发时序（如实登记，不伪造、不谎报教学闭环）**：
- 开跑最初全工程 `find -iname "*tutorial*"` 无结果、`is_tutorial_active|force_complete` grep 无匹配 → 按任务单预备了「接口缺失降级：直接注入按键 + 登记接口缺失」分支。
- 执行期间 Rank-1 落盘 `godot/scripts/combat/tutorial_director.gd`（注释 `R28 · Rank-1, cmd-20261111-095602-818-A1`）+ `courtyard.tscn` 的 `TutorialHud/TutorialLabel/TutorialDirector` 三节点。
- 故 `_resolve_tutorial_api()` 实测探测到**接口已落盘**（`[R28][TUTORIAL] 接口已落盘 name=TutorialDirector`），**未走降级分支**；逐帧 `is_tutorial_active()` 监测，`force_complete()` 仅作「教学未由真实按键完成才触发」的兜底，`frame=40` 读回 `is_tutorial_active()=false` → **未触发**。
- 未谎称接口缺失，也未谎称教学闭环由 `force_complete()` 跳过证明；闭环由真实按键三步证明（§3）。

---

## 3. 教学 → 波次 1/3 衔接（真实按键闭环）

`r28_capture.log` 逐行实证：
```
[Tutorial] 教学开始：STEP_LIGHT_ATTACK（J）｜ 波次冻结，教学期间不推进三波
[WaveTrial] 教学冻结：三波不自动开始 / 不推进（tutorial_freeze=true）
[R28][INPUT] frame=0 注入真实按键 light_attack(J)
[Tutorial] 步骤完成 step=light_attack reward=20 → state=STEP_ROLL（2/3）
[R28][INPUT] frame=6 注入真实按键 roll(Space)
[Tutorial] 步骤完成 step=roll reward=30 → state=STEP_GRACE_SHOP（3/3）
[R28][INPUT] frame=20 注入真实按键 interact(E)
[WaveTrial] 教学完成 → 自动进第 1 波：start_trial()=true（state=TELEGRAPH index=1/3）
[Tutorial] 波次衔接：begin_wave_after_tutorial()=true（解冻 + 自动进第 1 波）
[Tutorial] 三步教学完成：grace.tutorial.completed=true（单向）｜ 自动进第 1 波
[Tutorial] 步骤完成 step=grace_shop reward=50 → state=COMPLETED（3/3）
[R28][TUTORIAL] frame=40 快照 state=COMPLETED step_events=["light_attack","roll","grace_shop"] total_reward=100 wave_started=true | is_tutorial_active()=false
[R28][TUTORIAL] frame=40 教学已由真实按键 J→Space→E 三步完成并自动衔接到第 1 波（force_complete 未触发）
```
三步各由一次真实 `InputEventKey` 消费（`STEP_ACTIONS=light_attack/roll/interact`），奖励 `20/30/50` 来自 Rank-2 `tutorial_steps.tres`、`total_reward=100` 真实写 `grace.trial.points`。教学完成 `begin_wave_after_tutorial()` 解冻并进 **第 1/3 波**；随后既有 `_drive_wave_hud` 在 `f=150/300` 推进到 **第 2/3 波 / 第 3/3 波**（`[R26][WAVE]` 三行 + `[R27][GROWTH]` `第 1/3 → 2/3 → 3/3 波`，历史最佳 0→1→2→3、点数 0→100→250→450）。
额外佐证：v060 教学验证 `verify_tutorial_v060` 64 PASS / `verify_tutorial_reward_v060` 86 PASS / `verify_save_isolation_v060` 31 PASS 全 ALL_PASS/ALL_MATCH。

---

## 4. 15 秒录屏 / MP4 / WAV / 三帧目视（任务②④，真跑）

| 项 | 实测 |
|---|---|
| 录屏 | `--path <godot> --write-movie capture/v060_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`，沿用 R22~R27 定稿），**EXIT=0** |
| **录屏帧数** | **450 帧**（`v060_demo00000000.png … 00000449.png`），1280×720 @30fps / 15.000000s，`SCRIPT ERROR=0` |
| ffmpeg | 绝对路径 `.../ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`，`-framerate 30 -start_number 0 -i v060_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，**EXIT=0** |
| **MP4 字节数** | **`capture/v060_demo.mp4` = 897,681 B**；ffprobe `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000`，`moov` 前置 |
| **WAV 是否混入 MP4** | **未混入**：ffmpeg 输入仅 PNG 序列、无音频 `-i`；`ffprobe -select_streams a` 音频流计数 = **0**。如实登记 |

**ViewImage 真看首 0 / 中 225 / 尾 449 三帧**（+ `r28_panel_head/mid/tail.png` 裁剪放大 + 标题区像素采样，逐帧记录见 `capture/V060-RUNTIME-REVIEW.md §3`）：

| 判定 | 结论 |
|---|---|
| **动作帧 HUD 是否推进** | **是（本轮修复 R27 遗留「恒 idle 0/0」）**：中帧 `动作 roll 6/22`、尾帧 `动作 roll 8/22`（非 idle），全片 J/Space 真实按键经 `_request_action → _update_hud` 驱动；`frame=171` 已见 `命中 4`、`闪避 2`、HP 真实推进。**首帧仍 `idle 0/0`**（输入 1 帧延迟），如实记录，不冒充三帧全非 idle |
| **兑换面板是否展开** | **是**：`shop_open` 从 frame 22 起持续 true 到 449；尾帧 449 清晰可辨 5 行（余额 0、三项增益、「提示：兑换成功：赐福·生命上限（消耗 100，余额 0）」），购买真实成功（`HP 100→120`）。如实登记：首帧为未展开提示态；**中帧 225 段 B `low/mobile` 下 `SubViewport` 缩放使面板文字目视不可清晰辨认**（`r28_panel_mid.png`），不谎称三帧均清晰 |
| **赐福标题是否点亮** | **是**：三帧标题区像素实测最亮 `(212,174,76)` = `hud.gd` GOLD、`dim_px=0`；经 `WorldState.set_flag → flag_changed → HUD.refresh_label → apply_lit_state(GOLD)` 既有事件路由，不写 `Label.text`、不构造颜色 |
| **教学到波次是否衔接** | **是**：真实按键 J→Space→E 三步闭环 → `begin_wave_after_tutorial()` 进第 1/3 波 → f150/300 推进 2/3、3/3（§3）；`force_complete` 未触发 |
| **HD-2D 全绿是否达到** | **未达（如实写未达）**：景深/光效仍 2D `draw_*` 近似、三波变化是 2D 色带叠加、地面高倍平铺、角色仍 `AnimatedSprite3D` billboard、段 B 面板不可辨、首帧 idle、未做人工试玩逐帧动态验收、数值 `[PLACEHOLDER]` |

---

## 5. 景深技术评估要点（任务③，仅评估未实现）

`TECHNICAL-ART-DEPTH-v060.md` 基于工程实测配置（`project.godot:145-146` `gl_compatibility`；`courtyard.tscn:39-48` Environment 仅 `fog_enabled=true` 传统深度雾、无 glow/volumetric_fog/dof/ssr；`build_courtyard.gd:201` `env.glow_enabled=false`；`hd2d_fx.gd` 四项「光效」全是 2D `draw_*`；`quality_preset/render_profiles` 的同名 `volumetric_fog_enabled/glow_enabled/wet_reflection_enabled` 是 2D FX 开关而非 3D Environment 属性）给出：

- **真 3D 景深 / 体积光 / 湿地倒影 / bloom 在 `gl_compatibility` 下当前均不可直接依赖**：`Environment.glow` 历史实测/显式关闭不支持；`volumetric_fog` 属 Compatibility(OpenGL) 后端能力缺口；`DoF` / `SSR` 需 Forward+ 后处理链；Planar 反射对 billboard 穿帮。凡后端支持度判断均标注「需真跑验证」，不把推断当实测。
- **SubViewport 分层方案代价**：显存/带宽（多层 render target）、N 倍 3D draw call（桌面 `target_frame_time_ms=16.67` 无余量）、Movie Maker 只录主视口链（R22 踩坑）、R22 相机只读铁律、输入穿透、**画质档缩放错位**（本轮中帧面板不可辨即实证）、场景节点数变化牵动 `verify_wave_runtime_v040` 断言。结论：代价大于收益。
- **零付费替代方案与优先级**：P0 定调「2D 近似、全绿未达」（本轮已做，仅文档）→ P1 强化既有 2D `draw_*` 伪景深/分层光锥/倒影参数（低风险，需后续派单，脚本不属本轮授权）→ P2 一次全屏 `BackBufferCopy` + `ColorRect` shader（须真跑帧时间）→ P3 切 `forward_plus` / 多 SubViewport（**不推荐**）。
- **严格边界**：本轮**未改任何工程渲染件、未实现、未谎称实现任何真 3D 光效**；文中 `[PLACEHOLDER]` 数值均为建议值待试玩校准。

---

## 6. 三段门禁 / PASS 回归（任务⑤，真跑 `capture/r28_*.log`）

| 段 | 日志 | EXIT / 结论 |
|---|---|---|
| G1 | `r28_g1_import.log`（`--headless --import`） | **0** |
| G2 | `r28_g2_checkonly.log`（`--headless --check-only --script res://test/presentation.gd`） | **0** |
| G3 | `r28_g3_quit.log`（`--headless --quit`） | **0**（仅既有非致命 `2 ObjectDB instances were leaked` WARNING） |
| 录屏 | `r28_capture.log` | **0** · 450 帧 · `SCRIPT ERROR=0` |
| ffmpeg | `r28_ffmpeg.log` | **0** |

- **字面 `SCRIPT ERROR=0`**：`r28_g1/g2/g3` + `r28_capture` + `r28_ffmpeg` 逐份 `SCRIPT ERROR|Parse Error` = 0；全部 `r28_verify_*.log` 合计 **0**。
- **全 PASS 回归不回退**：`verify_fx_mobile` 47 / `verify_fx_profile` 34 / `verify_encounter_v010` 20 / `v020` 45 / `v030` 53 / `verify_wave_trial_v040` 58 / `verify_frame_data` 650 → **合计 907 PASS 全不回退**；本轮 v060 教学验证 `verify_save_isolation_v060` 31 / `verify_tutorial_reward_v060` 86 / `verify_tutorial_v060` 64 → **181 PASS 全 ALL_PASS/ALL_MATCH**。

**如实登记的 1 项 FAIL（非 Rank-4 引入、非状态依赖）**：`verify_wave_runtime_v040` 稳定 `pass=36 fail=1 RESULT=FAILED`（`r28_verify_wave_runtime_v040_rerun.log` 重跑同值）：
```
[V040] courtyard_node_count PASS=false | node_count=41 expected=38
```
根因：Rank-1 本轮并发在 `courtyard.tscn` 新增 `TutorialHud` / `TutorialLabel` / `TutorialDirector` **3 个节点**，`[node` 总数 38 → 41，而脚本硬编码 `NODE_COUNT_AFTER=38` 未同步。基线对照：`r27_verify_wave_runtime_v040.log` 为 `node_count=36 expected=36 PASS`；本轮开跑前脚本已更新为 `expected=38`（当时场景 38 节点、PASS）；场景 mtime `2026-11-11 10:17:16`（本轮执行期间被 Rank-1 改动）。
**Rank-4 本轮只写 `presentation.gd`（mtime 10:26）/ `capture/` / 评估文档 / `teamwork/Rank-4/`，未写 `courtyard.tscn`、未写任何验证脚本；不改断言、不放宽、不掩盖、不越权改他人所有物、不自行 git。** 该 FAIL 属并发时序下 Rank-1 场景节点新增导致的既有断言过期，建议由脚本所有者同步期望值为 41 后复跑；本轮如实登记，不谎称「全 PASS」。

---

## 7. 目录所有权 / 合规

- 只写：`godot/test/presentation.gd` / `capture/` / `TECHNICAL-ART-DEPTH-v060.md` / `teamwork/Rank-4/`（+ 回执 `teamwork/command_center/ai/4/outbox/`）。
- **未写**：`courtyard.tscn` / `tutorial_director.gd` / `wave_trial_director.gd` / `encounter_director.gd` / `hud.gd` / `grace_upgrade_service.gd` / 素材 PNG / `.tres` / `project.godot` / 契约 / README / 任何验证脚本 / 其它 Rank 工位；**未自行 git**（总指挥收尾）。
- 公共契约：**先目视检查再接入**（先 20 帧 / 60 帧短验输入生效与教学闭环 → 正式 450 帧 → 三帧 ViewImage + 面板裁剪 + 像素采样后才写结论）；**直接改直接真跑**，未新建只读探针/巡检脚本（短跑复用同一 `presentation.gd`，仅改 `--quit-after` 参数，临时 PNG 已清理）；不伪造产物、不谎报成功（HD-2D 全绿写未达、WAV 未混入如实登记、中帧面板不可辨如实登记、首帧 idle 如实登记、1 项 FAIL 如实登记、真 3D 光效仅评估未实现）。
- 零 GPU 额外 job、零付费、零外部素材生成服务；录屏（GPU 渲染）与 ffmpeg 编码串行。

---

## 8. 未完成项 / 阻塞

1. **HD-2D 全绿未达**（§4 判定 5，如实写未达，不冒充达标）；
2. 段 B `low/mobile` 画质下 `SubViewport` 缩放导致兑换面板文字不可清晰辨认；
3. 首帧动作帧 HUD 仍 `idle 0/0`（`Input.parse_input_event` 1 帧延迟，真实时序）；
4. `verify_wave_runtime_v040` 稳定 `36/1 FAILED`（Rank-1 并发新增 3 节点致 `node_count` 断言过期，非本轮引入，见 §6）；
5. `ACTION_INTERVAL=6`、三波色带 / 雾 / 地面数值为 `[PLACEHOLDER]`，待试玩校准；未做人工试玩逐帧动态验收；
6. 真 3D 景深 / 体积光 / 湿地倒影 / bloom **本轮仅评估未实现**（`TECHNICAL-ART-DEPTH-v060.md`，P1/P2 需后续派单授权）；
7. 未自行 git（总指挥收尾）。
- **阻塞：无。**

---

## 9. 回执

回执 JSON 写到精确路径（**未写到工程根 `command_center/`**）：
`F:/Game/aierdengfahuan/teamwork/command_center/ai/4/outbox/cmd-20261111-095602-831-A4.json`
内容：`{"task_id":"cmd-20261111-095602-831-A4","ai":4,"status":"done","result":"引用 DONE-R28.md 实际结论：真实按键注入生效/教学闭环衔接到 1-3 波并推进 2/3、3/3/450 帧与 MP4 897681 B/三帧目视（动作帧 roll 6/22、8/22、面板展开、标题 GOLD、全绿未达）/景深仅评估未实现/907+181 PASS 与 1 项 FAIL 如实登记/未完成项"}`。写入后即时校验：文件存在、JSON 合法、`task_id/ai/status` 正确。

**并发调度中枢归档（如实登记）**：调度中枢 `dispatcher` 会自动把各 AI 的 `outbox/` 回执搬到 `teamwork/command_center/dispatcher/receipts/` 并清空 outbox（历史每轮 receipts 均带 `.json.<timestamp>` 备份，本轮 `ai/1~4/outbox` 均空）。本轮回执被归档 2 次（10:47:23 主档 1295 B + 10:49:03 时间戳备份 1295 B，均为本 AI 写入的完整内容），证明回执已送达调度中枢；为满足「精确路径」验收，最终又在 `ai/4/outbox/` 重写并即时校验存在（1301 B，内容与归档一致，仅 JSON 缩进重排）。此为协作空间既定工作流，非交付缺失、未自行 git。
