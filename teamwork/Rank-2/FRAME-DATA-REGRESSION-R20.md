# FRAME-DATA-REGRESSION-R20.md —— Rank-2 帧数据裁决全链路回归（真跑记录）

> **派单**：调度中枢 `cmd-20261109-110237-801-A2`，`[ROUND=R20]`。
> **定位**：R19 已把 `action_04_roll` 裁决修正为 **`4/9/9=22 帧@60`、无敌 `[4,13)`**；本轮是**回归**，不再改任何战斗数值。
> **载体**：`godot/scripts/verify_frame_data.gd`（本轮唯一改动的工程脚本）。
> **留档**：完整 stdout 见同目录 `R20-verify-run.log`（238 行，G1~G4 逐行原始输出）。
> **硬约束**：零付费 / 零外部依赖；不新建只读探针 / 巡检脚本；不新增工程文件；不碰 `project.godot`（Rank-3 独占）、`courtyard.tscn` / `quality_settings`（Rank-1 独占）、`hd2d_fx`（Rank-4 独占）；不伪造输出、不谎报成功。

---

## 0. 结论速览（真跑）

| 项 | 实际输出 |
|---|---|
| 四段 EXIT | `G1_IMPORT_EXIT=0` / `G2_CHECKONLY_EXIT=0` / `G3_QUIT_EXIT=0` / `G4_RUN_EXIT=0` |
| 组A 文档 / 帧数据核对 | `DOC_PASS=111 DOC_FAIL=0 -> DOC_CONSISTENCY=PASS` |
| 组B R19 裁决值 | `VERDICT_PASS=6 VERDICT_FAIL=0 -> MATCH` |
| 组C CombatDataValidator 校验口径同跑 | `VALIDATOR_CHECKS=495 VALIDATOR_PASS=495 VALIDATOR_FAIL=0 -> VALIDATOR_ERROR=0` |
| **合计** | **`PASS_COUNT=612 FAIL_COUNT=0`** |
| E-8 max_resistance | `400.0 / 480.0 / 420.0`（bleed / poison / frost，仍为 R10 裁决 A1 值） |
| **总结论** | **`RESULT=ALL_MATCH`** |
| 门禁 grep | `SCRIPT ERROR=0` / `Parse Error=0` / `ERROR:=0` / `[FAIL]=0` / `FAIL_COUNT=[1-9]=0` |

---

## 1. 可复跑命令

引擎：`D:/Godot/Godot_v4.7.2-stable_win64_console.exe`（Godot `4.7.2.stable.official.ed1daf0bf` 官方发行包内的 console 版，与派单所指 `Godot_v4.7.2-stable_win64.exe` 同版本；用 console 版以把 stdout 捕获到日志，与 R19 既有口径一致）。

```bash
GODOT="D:/Godot/Godot_v4.7.2-stable_win64_console.exe"
ROOT="F:/Game/aierdengfahuan/godot"
SCRIPT="res://scripts/verify_frame_data.gd"
LOG="F:/Game/aierdengfahuan/teamwork/Rank-2/R20-verify-run.log"

# G1 三段门禁第 1 段：导入
"$GODOT" --headless --path "$ROOT" --import                 ; echo "G1_IMPORT_EXIT=$?"
# G2 三段门禁第 2 段：静态检查（本脚本为门禁与主真跑共同载体）
"$GODOT" --headless --path "$ROOT" --check-only --script "$SCRIPT" ; echo "G2_CHECKONLY_EXIT=$?"
# G3 三段门禁第 3 段：启动即退
"$GODOT" --headless --path "$ROOT" --quit                   ; echo "G3_QUIT_EXIT=$?"
# G4 主真跑：帧数据断言 + CombatDataValidator 校验口径同跑
"$GODOT" --headless --path "$ROOT" --script "$SCRIPT"       ; echo "G4_RUN_EXIT=$?"

# 门禁判定（期望全部为 0）
grep -c "SCRIPT ERROR" "$LOG"        # 0
grep -c "Parse Error"  "$LOG"        # 0
grep -c "ERROR:"       "$LOG"        # 0
grep -c "\[FAIL\]"     "$LOG"        # 0
grep -c "FAIL_COUNT=[1-9]" "$LOG"    # 0
```

> 一次性跑并留档（本轮实际执行的包装）：
> ```bash
> { echo "### G1 --import ###"; "$GODOT" --headless --path "$ROOT" --import; echo "G1_IMPORT_EXIT=$?";
>   echo "### G2 --check-only --script ###"; "$GODOT" --headless --path "$ROOT" --check-only --script "$SCRIPT"; echo "G2_CHECKONLY_EXIT=$?";
>   echo "### G3 --quit ###"; "$GODOT" --headless --path "$ROOT" --quit; echo "G3_QUIT_EXIT=$?";
>   echo "### G4 --script (主真跑) ###"; "$GODOT" --headless --path "$ROOT" --script "$SCRIPT"; echo "G4_RUN_EXIT=$?"; } > "$LOG" 2>&1
> ```

---

## 2. 断言覆盖范围（本轮对 `verify_frame_data.gd` 的改造）

| 组 | 覆盖 | 项数（真跑） |
|---|---|---|
| 组A | Boss 三招按 **pose key = `phase.pose_prefix` + `move.pose_name`** 点名：`p1_dagger_slash` / `p1_staff_slam` / `p2_holy_hammer`，逐项断言 **47 / 71 / 91 帧**与 hit 区间 `[18,23)` / `[30,37)` / `[42,51)`（含 pose→move_id 映射） | 24 |
| 组A | **玩家 8 帧动作**（idle / walk / run / roll / attack_light / attack_heavy / hitstun / death）逐项断言 `startup/active/recovery` + 派生 `total` + `hit_end` + `inv_start/inv_end` + `logic_fps` + `state_priority` | 72 |
| 组A | 翻滚 E-7 四项自洽 + `4/9/9=22` + 无敌 `[4,13)` | 11 |
| 组A | E-6（8 条动作齐全 / 8 条 `logic_fps=60` / `state_priority` 互异 / `Engine.physics_ticks_per_second=60`） | 4 |
| 组B | R19 裁决值 6 项（回归基准） | 6 |
| 组C | `CombatDataValidator` 校验口径同跑：E-1 / E-3 / E-4 / E-5 / E-8 / E-9 全量（含 E-9 静默逐字段计数 456 项） | 495 |
| **合计** | | **612** |

> 组A 111 = 24 + 72 + 11 + 4；组B 6；组C 495。**612 = 111 + 6 + 495**，`FAIL_COUNT=0`。

---

## 3. 真跑输出（逐字摘录自 `R20-verify-run.log`）

### 3.1 四段 EXIT

```
G1_IMPORT_EXIT=0
G2_CHECKONLY_EXIT=0
G3_QUIT_EXIT=0
G4_RUN_EXIT=0
```

### 3.2 G4 实际值快照 · Boss 三招（47 / 71 / 91 与 hit 区间）

```
---- [1] 实际值快照：Boss 三招（pose key 口径，按 id 去重）----
[ACTUAL][BOSS] pose=p1_dagger_slash | move_id=move_01_dagger_slash | startup=18 active=5 recovery=24 | total(derived)=47 | hit=[18,23)
[ACTUAL][BOSS] pose=p1_staff_slam | move_id=move_02_staff_slam | startup=30 active=7 recovery=34 | total(derived)=71 | hit=[30,37)
[ACTUAL][BOSS] pose=p2_dagger_slash | move_id=move_01_dagger_slash | startup=18 active=5 recovery=24 | total(derived)=47 | hit=[18,23)
[ACTUAL][BOSS] pose=p2_holy_hammer | move_id=move_03_holy_hammer | startup=42 active=9 recovery=40 | total(derived)=91 | hit=[42,51)
[ACTUAL][BOSS] pose=p2_staff_slam | move_id=move_02_staff_slam | startup=30 active=7 recovery=34 | total(derived)=71 | hit=[30,37)
```

### 3.3 G4 实际值快照 · 玩家 8 帧动作

```
[ACTUAL][PLAYER] id=action_01_idle | startup=0 active=1 recovery=0 | inv=[-1,-1) | logic_fps=60 | total(derived)=1 | hit=[0,1)
[ACTUAL][PLAYER] id=action_02_walk | startup=0 active=1 recovery=0 | inv=[-1,-1) | logic_fps=60 | total(derived)=1 | hit=[0,1)
[ACTUAL][PLAYER] id=action_03_run | startup=0 active=1 recovery=0 | inv=[-1,-1) | logic_fps=60 | total(derived)=1 | hit=[0,1)
[ACTUAL][PLAYER] id=action_04_roll | startup=4 active=9 recovery=9 | inv=[4,13) | logic_fps=60 | total(derived)=22 | hit=[4,13)
[ACTUAL][PLAYER] id=action_05_attack_light | startup=8 active=5 recovery=14 | inv=[-1,-1) | logic_fps=60 | total(derived)=27 | hit=[8,13)
[ACTUAL][PLAYER] id=action_06_attack_heavy | startup=20 active=8 recovery=26 | inv=[-1,-1) | logic_fps=60 | total(derived)=54 | hit=[20,28)
[ACTUAL][PLAYER] id=action_07_hitstun | startup=0 active=12 recovery=6 | inv=[-1,-1) | logic_fps=60 | total(derived)=18 | hit=[0,12)
[ACTUAL][PLAYER] id=action_08_death | startup=0 active=48 recovery=0 | inv=[-1,-1) | logic_fps=60 | total(derived)=48 | hit=[0,48)
[ACTUAL][PLAYER] actions=8 | logic_fps=[60, 60, 60, 60, 60, 60, 60, 60] | state_priority=[0, 10, 20, 60, 40, 45, 70, 100]
[ACTUAL][ENGINE] physics_ticks_per_second=60
```

### 3.4 组A Boss 三招 47 / 71 / 91 断言摘录（8/8 PASS × 3 招）

```
  [PASS][组A] p1_dagger_slash.total=startup+active+recovery(派生) | 实际=47 期望=47 | 来源=BOSS-DATA-FINAL §3.2 / schema E-2
  [PASS][组A] p1_dagger_slash 判定区间 end==startup+active(hit=[18,23)) | 实际=23 期望=23 | 来源=schema §3/E-2
  [PASS][组A] p1_staff_slam.total=startup+active+recovery(派生) | 实际=71 期望=71 | 来源=BOSS-DATA-FINAL §3.2 / schema E-2
  [PASS][组A] p1_staff_slam 判定区间 end==startup+active(hit=[30,37)) | 实际=37 期望=37 | 来源=schema §3/E-2
  [PASS][组A] p2_holy_hammer.total=startup+active+recovery(派生) | 实际=91 期望=91 | 来源=BOSS-DATA-FINAL §3.2 / schema E-2
  [PASS][组A] p2_holy_hammer 判定区间 end==startup+active(hit=[42,51)) | 实际=51 期望=51 | 来源=schema §3/E-2
```

### 3.5 组C E-8 / E-9 断言摘录（ERROR=0、400/480/420）

```
  [PASS][组C] E-8 抗性不溢出 -> status_01_bleed | limit=380.0 <= max_resistance=400.0 | 实际=true 期望=true | 来源=schema §9 E-8
  [PASS][组C] E-8 max_resistance[status_01_bleed] 仍为 R10 裁决值 | 实际=400.0 期望=400.0 | 来源=R10 裁决 A1 / 400/480/420
  [PASS][组C] E-8 抗性不溢出 -> status_02_poison | limit=450.0 <= max_resistance=480.0 | 实际=true 期望=true | 来源=schema §9 E-8
  [PASS][组C] E-8 max_resistance[status_02_poison] 仍为 R10 裁决值 | 实际=480.0 期望=480.0 | 来源=R10 裁决 A1 / 400/480/420
  [PASS][组C] E-8 抗性不溢出 -> status_03_frost | limit=400.0 <= max_resistance=420.0 | 实际=true 期望=true | 来源=schema §9 E-8
  [PASS][组C] E-8 max_resistance[status_03_frost] 仍为 R10 裁决值 | 实际=420.0 期望=420.0 | 来源=R10 裁决 A1 / 400/480/420
  [PASS][组C] E-9 字段名 ⊆ schema 白名单 | 字段实例=456 越界=0 | 实际=0 期望=0 | 来源=schema §9 E-9
```

### 3.6 SUMMARY（完整段，逐字）

```
==== [R20 FRAME DATA REGRESSION] SUMMARY ====
  组A 文档/帧数据核对 | DOC_PASS=111 DOC_FAIL=0 -> DOC_CONSISTENCY=PASS
  组B R19 裁决值 | VERDICT_PASS=6 VERDICT_FAIL=0 -> MATCH
  组C CombatDataValidator 校验口径同跑 | VALIDATOR_CHECKS=495 VALIDATOR_PASS=495 VALIDATOR_FAIL=0 -> VALIDATOR_ERROR=0
  合计 | PASS_COUNT=612 FAIL_COUNT=0
  E-8 max_resistance (bleed/poison/frost) = 400.0 / 480.0 / 420.0
  RESULT=ALL_MATCH
  NOTE: quit(0)=脚本执行/读取成功；PASS/FAIL 由实际值 vs 期望值真实计算，不预设结论；不写 courtyard.tscn / project.godot。
==== [R20 FRAME DATA REGRESSION] END ====
```

### 3.7 门禁 grep 统计（全部 0）

```
SCRIPT ERROR 匹配数: 0
Parse Error 匹配数: 0
[FAIL] 匹配数: 0
ERROR: 匹配数: 0
FAIL_COUNT=[1-9] 匹配数: 0
```

### 3.8 既有 WARNING（非 ERROR、非本轮问题，如实登记）

- G3 / G4 各 1 条 `2 ObjectDB instances were leaked at exit`；
- G4 另有 1 条 `[ChunkManager] 未找到 ChunkRoot`（`res://scripts/world/chunk_streaming.gd:51`）。

与 R16 / R18 / R19 历史日志同类告警，EXIT 仍为 0，未处理、未越界修改。

---

## 4. 与 `CombatDataValidator` 的关系（诚实声明，不谎报）

- **事实**：`CombatDataValidator` 类（工位件 `teamwork/Rank-2/combat_data_validator.gd`）自 R2 起**未落位真实工程根**——`godot/scripts/combat/` 下无该文件；`godot/scenes/Main.tscn` 与 `project.godot` 的 5 个 autoload 亦均未挂载该类，故 `--headless --quit`（G3）不会触发其 `_ready()`。R10 曾在「系统临时最小工程」由 runner 挂载实跑；R19 交付 §③ 明确登记「是否落位待总指挥裁决」。
- **本轮做法**：按 R20 公共契约「不新建只读探针 / 巡检脚本」「只写本 Rank 目录与本单指定工程文件」「不新增工程文件」，本轮**未实例化该类、未落位、未新建 runner**。组C 是在**同一真跑命令 / 同一进程 / 同一份运行权威 `.tres`**（boss + enemy + player_actions）上，按 `数据表schema.md` §9 与 `combat_data_validator.gd` 的 E-1 / E-3 / E-4 / E-5 / E-8 / E-9 校验式**逐项真实复算**的**等价校验同跑**：`VALIDATOR_ERROR=0`、E-8 三项 `max_resistance=400/480/420` 均由实际资源字段计算得出，未预设结论。
- **性质**：这是「等价校验复核」，**不是**「实例化 `CombatDataValidator` 类」。如中枢要求类级实例化 / 正式落位，需先给出落位授权（R2 起登记的待裁决项），届时可把工位件落位到 Rank-2 所有权目录并由主场景 / runner 挂载。
- 脚本头部注释与 G4 stdout 的 `[C][声明]` 行均如实打印了上述口径，未冒充「已落位运行」。

---

## 5. 残留口径清理

逐文件清单见 `DONE-R20.md` §③ 与 `DONE-R19.md` 附录 C。摘要：

- **已改 3 处当前规格口径 + 1 处 append-only 登记**：`COMBAT-BUILD.md:143`、`README.md:105`、`teamwork/Rank-2/player_actions.tres`（历史规格副本 `12/12/16`→`9/9/13`）、`DONE-R19.md`（追加附录 C）。
- **有意保留**：历史真跑 stdout / 回执 / `.log` 原始输出、`R19 裁决改前→改后对照`、派单描述、与翻滚无关的 `28` / `0.200 s`，按「不伪造输出」原则逐文件登记保留理由。
- 清理后复检：当前生效规格口径统一为 **`4/9/9=22`、无敌 `[4,13)`**；运行权威件 `godot/data/combat/player_actions.tres` 与历史副本数值一致。

---

## 6. 未完成项与阻塞

- **阻塞：无**。任务 4 项（脚本断言扩展、真跑、残留清理、报告）全部完成。
- **待裁决（非本轮、不擅自执行）**：`CombatDataValidator` 类是否落位真实工程根（R2 起登记项）。本轮按契约未落位、未实例化，以等价校验同跑达成 `ERROR=0` 的实质确认。
- **既有历史 stdout 不改写**：R16 / R18 / R19 的历史输出与回执按「不伪造输出」原则原样保留。

---

## 7. 说明：文档清理不影响真跑结论

本轮清理改动的 `COMBAT-BUILD.md` / `README.md` / `DONE-R19.md` / `teamwork/Rank-2/player_actions.tres` 全部位于 `teamwork/Rank-2/`（Godot `res://` 根为 `godot/`，teamwork 目录不被引擎加载）；`verify_frame_data.gd` 加载的 3 份运行权威 `.tres` 位于 `godot/data/combat/`，本轮**未改动**。故 §3 真跑输出即最终状态下的有效结论。

**最终状态复验（文档清理完成后，不覆盖 `R20-verify-run.log`）**：再次执行 G4 `--script`，`G4_RECHECK_EXIT=0`，输出与 §3.6 逐字一致——`DOC_PASS=111 DOC_FAIL=0` / `VERDICT_PASS=6 VERDICT_FAIL=0` / `VALIDATOR_CHECKS=495 ... VALIDATOR_ERROR=0` / `PASS_COUNT=612 FAIL_COUNT=0` / `E-8 max_resistance = 400.0 / 480.0 / 420.0` / `RESULT=ALL_MATCH`。确认文档清理未改变引擎侧数据与真跑结论。
