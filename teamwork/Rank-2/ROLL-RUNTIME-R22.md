# ROLL-RUNTIME-R22 · 翻滚无敌窗口运行期逐帧实测

- 任务单：`cmd-20261109-124640-182-A2`（[ROUND=R22]）
- 执行：Rank-2（战斗系统与数据驱动）
- 工程根：`F:/Game/aierdengfahuan/godot`
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`）
- 本轮唯一新增脚本：`godot/scripts/combat/roll_runtime_check.gd`（`extends SceneTree`，`class_name RollRuntimeCheck`）
- 真跑日志：`R22-gate1-import.log` / `R22-gate2-checkonly.log` / `R22-gate3-quit.log` / `R22-main-run.log` / `R22-verify650-run.log`

---

## 1. 设计：运行期实测 ≠ 数据层静态断言

R19/R21 只在数据层断言 `4/9/9=22 帧@60、无敌 [4,13)`。本轮补齐「跑起来的东西」：按 `logic_fps` 逐帧推进 `action_04_roll` 的 `startup/active/recovery`，每帧注入 1 次来袭命中，输出 `frame_index / invulnerable / hit_accepted`。

**数据同源 / 零硬编码期望**：所有边界 `startup / active / recovery / inv_start / inv_end / logic_fps / total` 一律从 `res://data/combat/player_actions.tres` 的 `PlayerActionData` 字段读出并派生，脚本内不出现任何战斗数值字面量常量（4/9/9/22/4/13/60 均不写死）。

为避免「自己验自己」，`期望` 与 `运行逻辑` 刻意同源但取自不同字段、用不同机制计算：

| 层 | 来源 | 判定 |
|---|---|---|
| 运行逻辑（被测） | 逐字复刻 `teamwork/Rank-2/player_state_machine.gd:233-242` 的 `is_invulnerable()` | 用 `invulnerable_start_frame / invulnerable_end_frame` 字段判 `[ist, ien)` —— 即工程玩家状态机真实采用的判定 |
| 期望（基准） | 由三段帧字段按 E-7 自洽等式推导 | `[startup, startup+active)`（与 `godot/scripts/combat/boss_controller.gd:226-227` 的 `[startup, active_end)` 判定窗口口径一致） |
| 逐帧断言 | 两者相等 | 验证「数据层字段」与「运行期状态机行为」一致；若 `.tres` 被改坏（如 `inv_end` 与 active 段错位）运行期即 FAIL，非自证循环 |

**0-based frame_index 口径**：数据层无敌区间 `[inv_start, inv_end)` 为 0-based 左闭右开；规格件 `player_state_machine.gd` 的 `_physics_process` 先 `state_frame += 1` 再判定，存在 1-based 偏移。本实测以 0-based `frame_index ∈ [0, total)` 逐帧推进，使逐帧表与 `[4,13)` 数据口径直接对齐。该口径差异如实登记，不擅改规格件。

**同源读取实测值**（`[SOURCE]` 行，逐字）：

```
[SOURCE] id=action_04_roll state_name=roll | startup_frames=4 active_frames=9 recovery_frames=9
[SOURCE] invulnerable_start_frame=4 invulnerable_end_frame=13 logic_fps=60
[SOURCE] derived total=s+a+r=22 | 步进 delta=1/60=0.016667 s | 期望 E-7 窗口=[4,13)
[SOURCE] 分段口径（均由变量派生）: startup=[0,4) / 无敌=[4,13) / 恢复=[13,22)
```

---

## 2. 逐帧实测表（22 帧 @60fps，delta=1/60 s）

`R22-main-run.log` 第 10–31 行，逐字转录。每帧注入 1 次来袭命中：`hit_accepted = not invulnerable`；`inv_expected` 为独立期望基准，逐帧与 `invulnerable` 断言相等。

| frame_index | phase | invulnerable | hit_accepted | inv_expected | elapsed_sec |
|---:|---|---|---|---|---:|
| 0 | startup | false | true | false | 0.0000 |
| 1 | startup | false | true | false | 0.0167 |
| 2 | startup | false | true | false | 0.0333 |
| 3 | startup | false | true | false | 0.0500 |
| 4 | active | true | false | true | 0.0667 |
| 5 | active | true | false | true | 0.0833 |
| 6 | active | true | false | true | 0.1000 |
| 7 | active | true | false | true | 0.1167 |
| 8 | active | true | false | true | 0.1333 |
| 9 | active | true | false | true | 0.1500 |
| 10 | active | true | false | true | 0.1667 |
| 11 | active | true | false | true | 0.1833 |
| 12 | active | true | false | true | 0.2000 |
| 13 | recovery | false | true | false | 0.2167 |
| 14 | recovery | false | true | false | 0.2333 |
| 15 | recovery | false | true | false | 0.2500 |
| 16 | recovery | false | true | false | 0.2667 |
| 17 | recovery | false | true | false | 0.2833 |
| 18 | recovery | false | true | false | 0.3000 |
| 19 | recovery | false | true | false | 0.3167 |
| 20 | recovery | false | true | false | 0.3333 |
| 21 | recovery | false | true | false | 0.3500 |

**关键结论**：

- `[0,4)`（frame 0–3）：`hit_accepted=true` —— 前摇可受击 ✓
- `[4,13)`（frame 4–12）：`invulnerable=true / hit_accepted=false` —— 免伤窗口 ✓
- `[13,22)`（frame 13–21）：`hit_accepted=true` —— 恢复段可受击 ✓
- 总帧 `FRAMES_RUN=22 / TOTAL=22` @ `FPS=60` ✓
- 边界全部由 `.tres` 变量派生，当前数据下恰为任务要求的 `[0,4) / [4,13) / [13,22) / 22`；断言以变量表达、随数据变化，未硬编码。

---

## 3. 断言清单与 PASS/FAIL

主真跑 `R22-main-run.log` 第 32–49 行，逐字：

```
---- [ASSERT] 分段 / 总帧 / E-7 / fps ----
[ASSERT] startup [0,4) 全部可受击 -> PASS
[ASSERT] 无敌 [4,13) 全部免伤 -> PASS
[ASSERT] 恢复 [13,22) 全部可受击 -> PASS
[ASSERT] 总帧 frames_run==total(=22) -> PASS
[ASSERT] total==startup+active+recovery -> PASS
[ASSERT] E-7 inv_start==startup -> PASS
[ASSERT] E-7 inv_end==startup+active -> PASS
[ASSERT] E-7 无敌长度==active -> PASS
[ASSERT] E-7 0<=inv_start<inv_end<=total -> PASS
[ASSERT] logic_fps>0 且逐帧步进时长自洽 -> PASS
---- [VALIDATOR] 同跑 CombatDataValidator.validate_all() ----
[CombatDataValidator] validate_all() | checks=533 pass=533 fail=0 errors=0 | E-8 max_resistance(bleed/poison/frost)=400.0 / 480.0 / 420.0
[VALIDATOR] instance_valid=true | checks=533 pass=533 fail=0 errors=0 status=OK
[VALIDATOR] VALIDATOR_ERROR=0
[ASSERT] VALIDATOR_ERROR==0 (validate_all fail==0) -> PASS
[ASSERT] VALIDATOR errors 为空 -> PASS
[ASSERT] VALIDATOR status==OK -> PASS
```

SUMMARY（逐字）：

```
==== [R22 ROLL RUNTIME CHECK] SUMMARY ====
  逐帧实测 | FRAMES_RUN=22 TOTAL=22 FPS=60 | startup=[0,4) / 无敌=[4,13) / 恢复=[13,22)
  CombatDataValidator.validate_all() | VALIDATOR_CHECKS=533 VALIDATOR_PASS=533 VALIDATOR_FAIL=0 VALIDATOR_ERROR=0
  PASS_COUNT=57 FAIL_COUNT=0
  RESULT=ALL_MATCH
==== [R22 ROLL RUNTIME CHECK] END ====
```

- 本脚本断言数 `57 = 22帧×2(逐帧 invulnerable / hit_accepted) + 10(分段/总帧/E-7/fps) + 3(VALIDATOR)`，`FAIL_COUNT=0`，`RESULT=ALL_MATCH`。
- 退出码 `quit(0 if _fail==0 else 1)` 真实反映断言结论，`G4_RUN_EXIT=0`。

---

## 4. 三段门禁（含新增 class_name 后的 --headless --import）grep SCRIPT ERROR=0

| 段 | 命令 | EXIT |
|---|---|---|
| G1 | `--headless --path <root> --import` | `G1_IMPORT_EXIT=0` |
| G2 | `--headless --path <root> --check-only --script res://scripts/combat/roll_runtime_check.gd` | `G2_CHECKONLY_EXIT=0` |
| G3 | `--headless --path <root> --quit` | `G3_QUIT_EXIT=0` |
| 主真跑 | `--headless --path <root> --script res://scripts/combat/roll_runtime_check.gd` | `G4_RUN_EXIT=0` |
| 650 回归 | `--headless --path <root> --script res://scripts/verify_frame_data.gd` | `G5_VERIFY650_EXIT=0` |

五段日志 grep 结果（全部 0）：

```
R22-gate1-import.log    | SCRIPT ERROR=0 Parse Error=0 ERROR:=0 [FAIL]=0 FAIL_COUNT>0=0
R22-gate2-checkonly.log | SCRIPT ERROR=0 Parse Error=0 ERROR:=0 [FAIL]=0 FAIL_COUNT>0=0
R22-gate3-quit.log      | SCRIPT ERROR=0 Parse Error=0 ERROR:=0 [FAIL]=0 FAIL_COUNT>0=0
R22-main-run.log        | SCRIPT ERROR=0 Parse Error=0 ERROR:=0 [FAIL]=0 FAIL_COUNT>0=0
R22-verify650-run.log   | SCRIPT ERROR=0 Parse Error=0 ERROR:=0 [FAIL]=0 FAIL_COUNT>0=0
```

**新增 class_name 结构性核验**（`--import` 生效证据）：

```
.godot/global_script_class_cache.cfg:227:"class": &"RollRuntimeCheck",
.godot/global_script_class_cache.cfg:232:"path": "res://scripts/combat/roll_runtime_check.gd"
godot/scripts/combat/roll_runtime_check.gd.uid  已生成（20 B）
```

**project.godot 未被写入**（本轮四路冻结口径，定点 stat 核验）：

```
BEFORE: 1794194044 6664 F:/Game/aierdengfahuan/godot/project.godot
AFTER : 1794194044 6664 F:/Game/aierdengfahuan/godot/project.godot
```

`--headless --import` 仅更新 `.godot/` 缓存（class cache / uid cache），不改 `project.godot`。

---

## 5. R21 的 650 PASS 口径不回退 / VALIDATOR_ERROR=0

650 PASS 口径来自 R21 `verify_frame_data.gd` 的合计（组A 111 + 组B 6 + 组C `validate_all()` 533）。本轮两处真跑共同确认：

1. **主真跑内同跑**：`roll_runtime_check.gd` 内 `preload(...).new()` 真实实例化 `CombatDataValidator.validate_all()`，返回 `checks=533 pass=533 fail=0 errors=0 status=OK`，`VALIDATOR_ERROR=0`。
2. **外部回归（只调用、未修改 `verify_frame_data.gd`）**：`R22-verify650-run.log` SUMMARY 逐字：

```
[CombatDataValidator] validate_all() | checks=533 pass=533 fail=0 errors=0 | E-8 max_resistance(bleed/poison/frost)=400.0 / 480.0 / 420.0
==== [R21 VALIDATOR-CLASS VERIFY] SUMMARY ====
  组A 文档/帧数据核对 | DOC_PASS=111 DOC_FAIL=0 -> DOC_CONSISTENCY=PASS
  组B R19 裁决值 | VERDICT_PASS=6 VERDICT_FAIL=0 -> MATCH
  组C CombatDataValidator.validate_all()（类级真实实例化） | VALIDATOR_CHECKS=533 VALIDATOR_PASS=533 VALIDATOR_FAIL=0 -> VALIDATOR_ERROR=0
  合计 | PASS_COUNT=650 FAIL_COUNT=0
  E-8 max_resistance (bleed/poison/frost) = 400.0 / 480.0 / 420.0
  RESULT=ALL_MATCH
==== [R21 VALIDATOR-CLASS VERIFY] END ====
```

**结论**：`PASS_COUNT=650 FAIL_COUNT=0 RESULT=ALL_MATCH` 与 R21 完全一致，`650 PASS` 口径不回退；`VALIDATOR_ERROR=0`。

---

## 6. 可复跑命令

```bash
ENGINE="D:/Godot/Godot_v4.7.2-stable_win64.exe"
ROOT="F:/Game/aierdengfahuan/godot"
DIR="F:/Game/aierdengfahuan/teamwork/Rank-2"

# G1 新增 class_name 后必跑（重建 global_script_class_cache / uid）
"$ENGINE" --headless --path "$ROOT" --import > "$DIR/R22-gate1-import.log" 2>&1
# G2 静态检查
"$ENGINE" --headless --path "$ROOT" --check-only --script res://scripts/combat/roll_runtime_check.gd > "$DIR/R22-gate2-checkonly.log" 2>&1
# G3 工程启动退出
"$ENGINE" --headless --path "$ROOT" --quit > "$DIR/R22-gate3-quit.log" 2>&1
# 主真跑：逐帧实测 + 同跑 validate_all()
"$ENGINE" --headless --path "$ROOT" --script res://scripts/combat/roll_runtime_check.gd > "$DIR/R22-main-run.log" 2>&1
# 650 回归：只调用，不修改 verify_frame_data.gd
"$ENGINE" --headless --path "$ROOT" --script res://scripts/verify_frame_data.gd > "$DIR/R22-verify650-run.log" 2>&1

# 门禁 grep（全部应为 0）
for f in R22-gate1-import.log R22-gate2-checkonly.log R22-gate3-quit.log R22-main-run.log R22-verify650-run.log; do
  echo "$f SCRIPT ERROR=$(grep -c 'SCRIPT ERROR' "$DIR/$f" || true)"
done
```

---

## 7. 真跑 stdout（完整日志索引）

| 内容 | 文件 | 行 |
|---|---|---|
| 逐帧表 22 行 | `R22-main-run.log` | 10–31 |
| 断言 PASS 清单 | `R22-main-run.log` | 32–49 |
| SUMMARY / RESULT=ALL_MATCH | `R22-main-run.log` | 50–56 |
| `validate_all()` 类级 print | `R22-main-run.log` | 44 |
| 650 回归 SUMMARY | `R22-verify650-run.log` | SUMMARY 段 |
| 三段门禁原始输出 | `R22-gate1-import.log` / `R22-gate2-checkonly.log` / `R22-gate3-quit.log` | 全文 |

完整 stdout 以各 `.log` 原始文件为准，未改写、未伪造。

---

## 8. 未完成项与阻塞

- **阻塞：无**。本轮 5 项（① 新写 `roll_runtime_check.gd` 真跑逐帧；② 期望同源读取、输出 PASS/FAIL 与 `RESULT=ALL_MATCH`；③ 同跑 `validate_all()` + `650 PASS` 不回退 + `VALIDATOR_ERROR=0`；④ 三段门禁含 `--headless --import`、grep `SCRIPT ERROR=0`；⑤ 本文登记）全部完成。
- **既有 WARNING（非 ERROR、非本轮问题，如实登记）**：主真跑末尾有 `[ChunkManager] 未找到 ChunkRoot`（`res://scripts/world/chunk_streaming.gd:51`）与 `2 ObjectDB instances were leaked at exit` 各 1 条；与 R16/R18/R19/R20/R21 历史日志同类，EXIT 仍为 0，未处理、未越界修改。
- **待后续（非本轮、不擅自执行，沿用派单口径）**：`CombatDataValidator` 的 autoload 注册 / Main.tscn 挂载（本轮 `project.godot` 冻结、无人可写，类不依赖 autoload）、R21B 重导双产物，待总指挥在工程冻结后补单裁决。
- **口径说明（如实登记，非失败）**：规格件 `player_state_machine.gd` 的 `state_frame` 为 1-based 自增后判定，本实测采用 0-based `frame_index` 以与数据层 `[4,13)` 左闭右开直接对齐；差异已在 §1 登记，未擅改规格件。
- **未改**：`project.godot`、`courtyard.tscn`、`quality_settings.*`（Rank-1）、`hud.gd`（Rank-3）、`hd2d_fx.*`、`capture/`、`godot/test/presentation.gd`（Rank-4）、`player_actions.tres`（只读）；`verify_frame_data.gd` **只调用、未修改**。未自行 git commit / push。
- **目录所有权**：本轮只写 `godot/scripts/combat/roll_runtime_check.gd`（+ 引擎自动生成的同名 `.uid`）与 `teamwork/Rank-2/` 下 `ROLL-RUNTIME-R22.md` / `DONE-R22.md` / `R22-*.log`；回执写到 `teamwork/command_center/ai/2/outbox/`（本单指定精确路径）。
