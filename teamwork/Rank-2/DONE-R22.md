# DONE-R22 · Rank-2 交付完成登记

- 任务单：`cmd-20261109-124640-182-A2`（[ROUND=R22]）
- AI：2（战斗系统与数据驱动）
- 状态：**完成（done）**，无阻塞
- 详细报告：`teamwork/Rank-2/ROLL-RUNTIME-R22.md`
- 回执：`teamwork/command_center/ai/2/outbox/cmd-20261109-124640-182-A2.json`

---

## ① 实际交付清单

| 文件 | 类型 | 说明 |
|---|---|---|
| `godot/scripts/combat/roll_runtime_check.gd` | **新增**（`extends SceneTree`，`class_name RollRuntimeCheck`） | 按 60fps 逐帧真跑 `action_04_roll` 三段、逐帧输出 `frame_index/invulnerable/hit_accepted`、同源读取期望、同跑 `validate_all()` |
| `godot/scripts/combat/roll_runtime_check.gd.uid` | 引擎 `--import` 自动生成 | 新增脚本 UID（20 B） |
| `teamwork/Rank-2/ROLL-RUNTIME-R22.md` | **新增** | 逐帧表 / 可复跑命令 / 真跑 stdout / 未完成项 |
| `teamwork/Rank-2/R22-gate1-import.log` | **新增**（真跑日志） | G1 `--headless --import` |
| `teamwork/Rank-2/R22-gate2-checkonly.log` | **新增**（真跑日志） | G2 `--check-only --script` |
| `teamwork/Rank-2/R22-gate3-quit.log` | **新增**（真跑日志） | G3 `--headless --quit` |
| `teamwork/Rank-2/R22-main-run.log` | **新增**（真跑日志） | 主真跑逐帧 stdout（含 22 帧表 / 断言 / SUMMARY） |
| `teamwork/Rank-2/R22-verify650-run.log` | **新增**（真跑日志） | 外部重跑 `verify_frame_data.gd` 的 650 回归 stdout |
| `teamwork/Rank-2/DONE-R22.md` | **新增** | 本文件 |
| `teamwork/command_center/ai/2/outbox/cmd-20261109-124640-182-A2.json` | **新增**（回执） | 本单精确路径回执 |

**未写 / 未改**：`project.godot`（前后 stat 完全一致）、`courtyard.tscn`、`quality_settings.*`、`hud.gd`、`hd2d_fx.*`、`capture/`、`godot/test/presentation.gd`、`player_actions.tres`（只读）、`verify_frame_data.gd`（**只调用、未修改**）。未自行 git commit / push。

---

## ② 真跑输出结论（逐字关键行）

**主真跑** `R22-main-run.log`：

```
[SOURCE] id=action_04_roll state_name=roll | startup_frames=4 active_frames=9 recovery_frames=9
[SOURCE] invulnerable_start_frame=4 invulnerable_end_frame=13 logic_fps=60
[SOURCE] derived total=s+a+r=22 | 步进 delta=1/60=0.016667 s | 期望 E-7 窗口=[4,13)
FRAME frame_index=0  phase=startup  invulnerable=false hit_accepted=true  inv_expected=false
... （共 22 帧，详见 ROLL-RUNTIME-R22.md §2 逐帧表）
FRAME frame_index=21 phase=recovery invulnerable=false hit_accepted=true  inv_expected=false
[ASSERT] startup [0,4) 全部可受击 -> PASS
[ASSERT] 无敌 [4,13) 全部免伤 -> PASS
[ASSERT] 恢复 [13,22) 全部可受击 -> PASS
[ASSERT] 总帧 frames_run==total(=22) -> PASS
[CombatDataValidator] validate_all() | checks=533 pass=533 fail=0 errors=0 | E-8 max_resistance(bleed/poison/frost)=400.0 / 480.0 / 420.0
[VALIDATOR] VALIDATOR_ERROR=0
  逐帧实测 | FRAMES_RUN=22 TOTAL=22 FPS=60 | startup=[0,4) / 无敌=[4,13) / 恢复=[13,22)
  PASS_COUNT=57 FAIL_COUNT=0
  RESULT=ALL_MATCH
```

**650 回归** `R22-verify650-run.log`：

```
  组A 文档/帧数据核对 | DOC_PASS=111 DOC_FAIL=0 -> DOC_CONSISTENCY=PASS
  组B R19 裁决值 | VERDICT_PASS=6 VERDICT_FAIL=0 -> MATCH
  组C CombatDataValidator.validate_all() | VALIDATOR_CHECKS=533 VALIDATOR_PASS=533 VALIDATOR_FAIL=0 -> VALIDATOR_ERROR=0
  合计 | PASS_COUNT=650 FAIL_COUNT=0
  RESULT=ALL_MATCH
```

**三段门禁 + 主真跑 + 回归**：`G1/G2/G3/G4/G5 EXIT` 全 `0`；五段日志 `SCRIPT ERROR=0 / Parse Error=0 / ERROR:=0 / [FAIL]=0 / FAIL_COUNT>0=0`。

**新增 class_name 结构性核验**：`--headless --import` 后 `.godot/global_script_class_cache.cfg` 已注册 `&"RollRuntimeCheck" -> res://scripts/combat/roll_runtime_check.gd`，`.uid` 已生成。

---

## ③ PASS / FAIL 数字总表

| 项 | 数字 | 结论 |
|---|---|---|
| 主真跑逐帧断言 | `PASS_COUNT=57 FAIL_COUNT=0` | `RESULT=ALL_MATCH` |
| `validate_all()`（主真跑内同跑） | `checks=533 pass=533 fail=0 errors=0` | `VALIDATOR_ERROR=0` / `status=OK` |
| 650 回归合计（外部重跑） | `PASS_COUNT=650 FAIL_COUNT=0` | 与 R21 一致，**650 PASS 不回退**；`RESULT=ALL_MATCH` |
| 逐帧实测 | `FRAMES_RUN=22 TOTAL=22 FPS=60` | `[0,4)` 可受击 / `[4,13)` 免伤 / `[13,22)` 恢复可受击 / 总帧 22 |
| 门禁 grep | `SCRIPT ERROR=0` | 五段全 0 |
| 退出码 | `G1..G5 EXIT=0` | 主真跑用条件退出码，0 即断言全 PASS |

**逐帧实测关键结论**：运行期逐帧推进证实 R19/R21 数据层口径在真实逐帧推进下成立——前摇 4 帧可受击、active 段 9 帧免伤、恢复 9 帧可受击、总 22 帧 @60；期望与运行逻辑均同源读取 `player_actions.tres`，且分别取自 `inv_*` 字段与三段帧 E-7 推导（独立机制），逐帧断言有区分度，非自证循环。

---

## ④ 未完成项与阻塞

- **阻塞：无**。本轮任务单 6 项全部完成。
- **既有 WARNING（非 ERROR、非本轮问题，如实登记）**：主真跑末尾 1 条 `[ChunkManager] 未找到 ChunkRoot`（`res://scripts/world/chunk_streaming.gd:51`）+ 1 条 `2 ObjectDB instances were leaked at exit`；与 R16/R18/R19/R20/R21 历史日志同类，EXIT 仍为 0，未处理、未越界修改。
- **待后续（非本轮、不擅自执行，沿用派单口径）**：`CombatDataValidator` autoload 注册 / Main.tscn 挂载（本轮 `project.godot` 冻结、类不依赖 autoload）、R21B 重导双产物，待总指挥在工程冻结后补单裁决。
- **口径说明（如实登记，非失败）**：规格件 `player_state_machine.gd` 的 `state_frame` 为 1-based 自增后判定，本实测采用 0-based `frame_index` 以与数据层 `[4,13)` 左闭右开直接对齐；差异已在 `ROLL-RUNTIME-R22.md §1` 登记，未擅改规格件。
- **零付费 / 未引入付费素材生成服务**；未新建只读探针/巡检脚本；未主动扫目录做进度巡检；未伪造产物、未谎报成功、未自行 git 提交。

---

## ⑤ 回执

写入精确路径 `F:/Game/aierdengfahuan/teamwork/command_center/ai/2/outbox/cmd-20261109-124640-182-A2.json`（注意在 `teamwork/command_center/` 下，**非**工程根 `command_center/`），内容：

**送达态（写后只读核验，12:57）**：回执写入上述精确路径后已被调度中枢即时消费并归档为 `teamwork/command_center/dispatcher/receipts/cmd-20261109-124640-182-A2.json`（1454 B，JSON 解析通过：`task_id=cmd-20261109-124640-182-A2` / `ai=2` / `status=done`，`result` 引用 DONE-R22.md 实际结论，keys 恰为 4 个必需字段）；`teamwork/command_center/ai/2/status.json` 现为 `state=idle` / `current_task=""` / `completed=24`（R21 为 23 → +1）；工程根 `F:/Game/aierdengfahuan/command_center/` 不存在（未误写）。故 outbox 现为空是「回执已送达中枢」的正常终态，非「回执未写 / 写错路径」。按并发保护「不重复写第二份回执」，本实例不再重写 outbox。回执 JSON 内容如下：

```json
{"task_id":"cmd-20261109-124640-182-A2","ai":2,"status":"done","result":"引用 DONE-R22.md 实际结论：R22 已新写 godot/scripts/combat/roll_runtime_check.gd（extends SceneTree，class_name RollRuntimeCheck），按 60fps 逐帧真跑 action_04_roll 的 startup/active/recovery 共 22 帧，逐帧输出 frame_index/invulnerable/hit_accepted：[0,4) 可受击、[4,13) 免伤、[13,22) 恢复可受击、总帧 22；期望与运行逻辑同源读取 player_actions.tres 字段（零硬编码），运行逻辑复刻 player_state_machine.gd is_invulnerable()（inv_* 字段）、期望由三段帧按 E-7 推导 [startup,startup+active)，逐帧断言有区分度；主真跑 RESULT=ALL_MATCH、PASS_COUNT=57 FAIL_COUNT=0；同跑 CombatDataValidator.validate_all() 得 checks=533 pass=533 fail=0 errors=0、VALIDATOR_ERROR=0；外部重跑 verify_frame_data.gd（只调用未改）确认 PASS_COUNT=650 FAIL_COUNT=0 RESULT=ALL_MATCH，650 PASS 口径不回退；新增 class_name 后 --headless --import 已跑且 class_name 注册核验通过；三段门禁 + 主真跑 + 回归五段 EXIT 全 0、SCRIPT ERROR=0/Parse Error=0/ERROR:=0/[FAIL]=0；project.godot 前后 stat 一致未写，未碰 courtyard.tscn/hud.gd/hd2d_fx.*/capture/；未完成项：无阻塞，既有 WARNING（ChunkManager 未找到 ChunkRoot、2 ObjectDB instances leaked at exit）非 ERROR 未处理，autoload 注册与 R21B 重导双产物待总指挥后续补单。"}
```
