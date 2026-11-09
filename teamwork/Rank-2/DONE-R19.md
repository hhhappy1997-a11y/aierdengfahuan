# DONE-R19.md —— Rank-2 交付（cmd-20261109-102334-084-A2 / ROUND=R19）

> **派单**：调度中枢 `cmd-20261109-102334-084-A2`，`[ROUND=R19]`；总指挥裁决已下，本轮正式修正翻滚帧。
> **裁决依据**：`00-汇总.md` §5 M1 验收与用户原始需求「翻滚无敌帧 4/9/9（22 帧 @60）」（`00-汇总.md:69`）；裁决以 **4/9/9=22 帧@60、无敌 `[4,13)`** 为准，原 `4/12/12=28`、无敌 `[4,16)` 为实现偏差。
> **硬约束遵守**：默认不刺探（只读本工位、公开汇总/裁决、本工位历史件）、零付费 / 零外部依赖、不伪造输出、中文 UTF-8、Godot 4 合法语法；**未碰 `godot/scenes/courtyard.tscn`**（Rank-1 本轮独占）、**未改 Boss 数值**、**未自行 git**。

---

## ① 实际改动清单（含前后值）

### 1.1 裁决口径：`action_04_roll` 改前 → 改后

| 字段 | 改前 | 改后（R19 裁决） | 说明 |
|---|---|---|---|
| `startup_frames` | 4 | **4** | 不变 |
| `active_frames` | 12 | **9** | 无敌段 |
| `recovery_frames` | 12 | **9** | 恢复段 |
| `total`（派生，不设字段） | 28 | **22** | `4 + 9 + 9 = 22` |
| `invulnerable_start_frame` | 4 | **4** | 不变 |
| `invulnerable_end_frame` | 16 | **13** | E-7：`startup + active = 4 + 9 = 13` |
| 无敌区间 | `[4,16)` | **`[4,13)`** | 左闭右开 |
| `logic_fps` | 60 | **60** | 22 帧 @60 不变 |

E-7 自洽复算：`inv_start = 4 = startup`；`inv_end = 13 = 4 + 9 = startup + active`；`inv_len = 13 - 4 = 9 = active`；`0 <= 4 < 13 <= 22` 全成立。

> **技术判断（如实登记）**：派单任务 1 列举了 `total_frames=22`。但 `godot/scripts/combat/player_action_data.gd` 的 `PlayerActionData` 字段集**不含** `total_frames`，且 `数据表schema.md` E-2 / E-7 明确规定「`total_frames` 不设字段，由 `startup+active+recovery` 派生，避免双源不一致」、E-9 要求 `.tres` 字段 ⊆ schema 字段集。故 `.tres` **未新增** `total_frames` 字段，改后 `total=22` 由 `4+9+9` 派生得到（验证脚本亦以 `s+a+r` 派生核对），派单所列为派生口径而非新增字段。

### 1.2 文件清单

**修改 7 个既有文件：**

| # | 文件 | 章节 / 位置 | 改前 → 改后 |
|---|---|---|---|
| 1 | `godot/data/combat/player_actions.tres` | `action_04_roll` | `active_frames 12→9`、`recovery_frames 12→9`、`invulnerable_end_frame 16→13`；`startup_frames=4` / `invulnerable_start_frame=4` 不变（运行权威件） |
| 2 | `godot/scripts/verify_frame_data.gd` | 组A `ROLL_EXPECTED` | `{"startup":4,"active":12,"recovery":12,"inv_start":4,"inv_end":16,"total":28,"logic_fps":60}` → `{"startup":4,"active":9,"recovery":9,"inv_start":4,"inv_end":13,"total":22,"logic_fps":60}` |
| 3 | `godot/scripts/verify_frame_data.gd` | 全脚本 | R18→R19 标记；组B 由「派单字面差异登记」改为「R19 裁决值核对」；`roll.total=4+12+12`→`4+9+9`；verdict / NOTE 文案更新；**`BOSS_MOVES`（Boss 三招）与 `ATTACK_EXPECTED` 数值一字未改** |
| 4 | `teamwork/Rank-2/motion-mapping.md` | §4.1 表格 roll 行 | `4 / 12 / 12`、无敌 `[4,16)`、恢复 `[16,28)` → `4 / 9 / 9`、无敌 `[4,13)`、恢复 `[13,22)`；E-7 注记 `4+9=13` |
| 5 | `teamwork/Rank-2/motion-mapping.md` | §4.1 表后 / §4.3 后换算示例 | 新增 R19 裁决修正注记（改前→改后、依据、E-7 自洽）；换算示例 roll 无敌段 `[4,16)`←`[2,8)` → `[4,13)`←`[2,6.5)` 取整 `[2,7)`（顺带同步同文件同口径，避免自相矛盾） |
| 6 | `teamwork/Rank-2/战斗系统设计.md` | §1.1 表格 roll 行 | `4 / 12 / 12 / [4,16)` → `4 / 9 / 9 / [4,13)`（接口契约 M1 引用「数值见 §1.1」，顺带同步） |
| 7 | `teamwork/Rank-2/战斗系统设计.md` | §2 全节 | 新增裁决注记；§2.1 表格 `12/12/28`、`[4,16)`、`[16,28)` → `9/9/22`、`[4,13)`、`[13,22)`；字段取值 `end=16→13`；§2.2 E-7 等式块 `4+12+12=28 / 16-4=12 / 16=4+12 / 0<=4<16<=28 / [4,16)` → `4+9+9=22 / 13-4=9 / 13=4+9 / 0<=4<13<=22 / [4,13)`；§2.3 验收口径基线 `16→13`、`12→9`、`0.200s→0.150s`、`第 4–15/16 帧→第 4–12/13 帧`（演示目标值 `20/16` 保留并注明为假设值、非落地数值） |
| 8 | `teamwork/Rank-2/数据表schema.md` | §7 字段表后 | 新增 R19 裁决修正注记（字段实例值改前→改后、`total_frames` 不设字段说明） |
| 9 | `teamwork/Rank-2/数据表schema.md` | §9 E-7 校验式后 | 新增 R19 裁决 E-7 口径注记（公式不变、翻滚实例改前→改后、改后逐式仍成立） |
| 10 | `teamwork/Rank-2/DONE-R16.md` | 末尾附录 B | **append-only** 追加 R19 裁决修正注记（改前值→改后值表、依据、已同步件）；**未篡改** R16 任何历史 stdout / 结论 |
| 11 | `teamwork/Rank-2/接口契约.md` | M1 垂直切片验收项 | 翻滚无敌帧 `[4,16)` → `[4,13)`、`4/9/9=22 帧@60`，注明 R19 裁决与改前值 |

**新增 3 个文件：**

| # | 文件 | 用途 |
|---|---|---|
| 12 | `teamwork/Rank-2/R19-verify-run.log` | R19 四段（三段门禁 + 主真跑）完整实际 stdout 原始留档（108 行） |
| 13 | `teamwork/Rank-2/DONE-R19.md` | 本文件 |
| 14 | `teamwork/command_center/ai/2/outbox/cmd-20261109-102334-084-A2.json` | 本轮回执 |

---

## ② 自检（含完整真跑 stdout 与 PASS/FAIL）

### 2.1 引擎与门禁

```
Godot : D:/Godot/Godot_v4.7.2-stable_win64_console.exe（标准版 4.7.2.stable.official.ed1daf0bf）
ROOT  : F:/Game/aierdengfahuan/godot
G1    : godot --headless --path <root> --import
G2    : godot --headless --path <root> --check-only --script res://scripts/verify_frame_data.gd
G3    : godot --headless --path <root> --quit
G4    : godot --headless --path <root> --script res://scripts/verify_frame_data.gd   （主真跑）
```

四段 EXIT：`G1_IMPORT_EXIT=0` / `G2_CHECKONLY_EXIT=0` / `G3_QUIT_EXIT=0` / `G4_RUN_EXIT=0`。

### 2.2 完整实际 stdout（G1~G4，逐行）

> 下方为 `R19-verify-run.log` 全 108 行的**去 ANSI 颜色控制码可读版**，文字逐字一致、无删减；原始字节（含 `\x1b[90m` 等控制码）见同目录 `R19-verify-run.log`。G1 的编辑器进度条带控制码，去码后遗留的 2 个空行原样保留。

```text
### G1 --headless --path <root> --import ###
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[   0% ] first_scan_filesystem | 正在扫描文件结构……
[  16% ] first_scan_filesystem | 正在加载全局类名……
[  33% ] first_scan_filesystem | 正在校验 GDExtension……
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[  66% ] first_scan_filesystem | 正在初始化插件……
[  83% ] first_scan_filesystem | 正在启动文件扫描……
[ DONE ] first_scan_filesystem

[   0% ] loading_editor_layout | Started 正在加载编辑器 (5 steps)
[   0% ] loading_editor_layout | 正在加载编辑器布局……
[  16% ] loading_editor_layout | 正在加载停靠面板……
[ DONE ] loading_editor_layout

G1_IMPORT_EXIT=0
### G2 --headless --path <root> --check-only --script res://scripts/verify_frame_data.gd ###
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

G2_CHECKONLY_EXIT=0
### G3 --headless --path <root> --quit ###
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G3_QUIT_EXIT=0
### G4 --headless --path <root> --script res://scripts/verify_frame_data.gd (主真跑) ###
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

==== [R19 FRAME DATA VERIFY] START ====
---- [0] 加载两份运行权威 .tres ----
[0] BOSS   load() OK | path=res://data/combat/boss_01_margit.tres | phases=2
[0] PLAYER load() OK | path=res://data/combat/player_actions.tres | actions=8
---- [1] 实际值快照：Boss 三招（phases[*].moves 按 id 去重）----
[ACTUAL][BOSS] id=move_01_dagger_slash | startup=18 active=5 recovery=24 | total(derived)=47 | hit=[18,23)
[ACTUAL][BOSS] id=move_02_staff_slam | startup=30 active=7 recovery=34 | total(derived)=71 | hit=[30,37)
[ACTUAL][BOSS] id=move_03_holy_hammer | startup=42 active=9 recovery=40 | total(derived)=91 | hit=[42,51)
---- [2] 实际值快照：player_actions 关键动作 ----
[ACTUAL][PLAYER] id=action_04_roll | startup=4 active=9 recovery=9 | inv=[4,13) | logic_fps=60 | total(derived)=22 | hit=[4,13)
[ACTUAL][PLAYER] id=action_05_attack_light | startup=8 active=5 recovery=14 | inv=[-1,-1) | logic_fps=60 | total(derived)=27 | hit=[8,13)
[ACTUAL][PLAYER] id=action_06_attack_heavy | startup=20 active=8 recovery=26 | inv=[-1,-1) | logic_fps=60 | total(derived)=54 | hit=[20,28)
[ACTUAL][PLAYER] actions=8 | ids=["action_01_idle", "action_02_walk", "action_03_run", "action_04_roll", "action_05_attack_light", "action_06_attack_heavy", "action_07_hitstun", "action_08_death"]
[ACTUAL][PLAYER] 8 条 logic_fps=[60, 60, 60, 60, 60, 60, 60, 60] | state_priority=[0, 10, 20, 60, 40, 45, 70, 100]
[ACTUAL][ENGINE] physics_ticks_per_second=60
---- [3] 组A 与 BOSS-DATA-FINAL.md / 数据表schema.md / motion-mapping.md 逐项核对 ----
  [PASS][组A] move_01_dagger_slash.startup_frames(前摇) | 实际=18 期望=18 | 来源=BOSS-DATA-FINAL §3.1/§3.2、schema §3/E-2
  [PASS][组A] move_01_dagger_slash.active_frames(判定) | 实际=5 期望=5 | 来源=BOSS-DATA-FINAL §3.1/§3.2、schema §3/E-2
  [PASS][组A] move_01_dagger_slash.recovery_frames(后摇) | 实际=24 期望=24 | 来源=BOSS-DATA-FINAL §3.1/§3.2、schema §3/E-2
  [PASS][组A] move_01_dagger_slash.total=startup+active+recovery(派生) | 实际=47 期望=47 | 来源=BOSS-DATA-FINAL §3.2 / schema E-2
  [PASS][组A] move_01_dagger_slash 判定区间 end=startup+active | 实际=23 期望=23 | 来源=schema §3/E-2
  [PASS][组A] move_02_staff_slam.startup_frames(前摇) | 实际=30 期望=30 | 来源=BOSS-DATA-FINAL §3.1/§3.2、schema §3/E-2
  [PASS][组A] move_02_staff_slam.active_frames(判定) | 实际=7 期望=7 | 来源=BOSS-DATA-FINAL §3.1/§3.2、schema §3/E-2
  [PASS][组A] move_02_staff_slam.recovery_frames(后摇) | 实际=34 期望=34 | 来源=BOSS-DATA-FINAL §3.1/§3.2、schema §3/E-2
  [PASS][组A] move_02_staff_slam.total=startup+active+recovery(派生) | 实际=71 期望=71 | 来源=BOSS-DATA-FINAL §3.2 / schema E-2
  [PASS][组A] move_02_staff_slam 判定区间 end=startup+active | 实际=37 期望=37 | 来源=schema §3/E-2
  [PASS][组A] move_03_holy_hammer.startup_frames(前摇) | 实际=42 期望=42 | 来源=BOSS-DATA-FINAL §3.1/§3.2、schema §3/E-2
  [PASS][组A] move_03_holy_hammer.active_frames(判定) | 实际=9 期望=9 | 来源=BOSS-DATA-FINAL §3.1/§3.2、schema §3/E-2
  [PASS][组A] move_03_holy_hammer.recovery_frames(后摇) | 实际=40 期望=40 | 来源=BOSS-DATA-FINAL §3.1/§3.2、schema §3/E-2
  [PASS][组A] move_03_holy_hammer.total=startup+active+recovery(派生) | 实际=91 期望=91 | 来源=BOSS-DATA-FINAL §3.2 / schema E-2
  [PASS][组A] move_03_holy_hammer 判定区间 end=startup+active | 实际=51 期望=51 | 来源=schema §3/E-2
  [PASS][组A] roll.startup_frames | 实际=4 期望=4 | 来源=motion-mapping §4.1 / 战斗系统设计 §2 / schema §7
  [PASS][组A] roll.active_frames(无敌段) | 实际=9 期望=9 | 来源=motion-mapping §4.1 / 战斗系统设计 §2 / schema §7
  [PASS][组A] roll.recovery_frames | 实际=9 期望=9 | 来源=motion-mapping §4.1 / 战斗系统设计 §2 / schema §7
  [PASS][组A] roll.invulnerable_start_frame | 实际=4 期望=4 | 来源=motion-mapping §4.1 / 战斗系统设计 §2 / schema §7
  [PASS][组A] roll.invulnerable_end_frame | 实际=13 期望=13 | 来源=motion-mapping §4.1 / 战斗系统设计 §2 / schema §7
  [PASS][组A] roll.logic_fps(@60) | 实际=60 期望=60 | 来源=schema §7 / E-6
  [PASS][组A] roll.total=4+9+9 | 实际=22 期望=22 | 来源=战斗系统设计 §2.2 / schema E-7
  [PASS][组A] E-7 inv_start==startup | 实际=4 期望=4 | 来源=schema E-7
  [PASS][组A] E-7 inv_end==startup+active | 实际=13 期望=13 | 来源=schema E-7
  [PASS][组A] E-7 inv_len(end-start)==active | 实际=9 期望=9 | 来源=战斗系统设计 §2.2 / schema E-7
  [PASS][组A] E-7 0<=start<end<=total | 实际=true 期望=true | 来源=schema E-7
  [PASS][组A] action_05_attack_light.startup_frames(前摇) | 实际=8 期望=8 | 来源=motion-mapping §4.1 / schema §7/E-2
  [PASS][组A] action_05_attack_light.active_frames(判定) | 实际=5 期望=5 | 来源=motion-mapping §4.1 / schema §7/E-2
  [PASS][组A] action_05_attack_light.recovery_frames(后摇) | 实际=14 期望=14 | 来源=motion-mapping §4.1 / schema §7/E-2
  [PASS][组A] action_05_attack_light.total(派生) | 实际=27 期望=27 | 来源=schema E-2
  [PASS][组A] action_05_attack_light 判定区间 end=startup+active | 实际=13 期望=13 | 来源=schema §3/E-2
  [PASS][组A] action_06_attack_heavy.startup_frames(前摇) | 实际=20 期望=20 | 来源=motion-mapping §4.1 / schema §7/E-2
  [PASS][组A] action_06_attack_heavy.active_frames(判定) | 实际=8 期望=8 | 来源=motion-mapping §4.1 / schema §7/E-2
  [PASS][组A] action_06_attack_heavy.recovery_frames(后摇) | 实际=26 期望=26 | 来源=motion-mapping §4.1 / schema §7/E-2
  [PASS][组A] action_06_attack_heavy.total(派生) | 实际=54 期望=54 | 来源=schema E-2
  [PASS][组A] action_06_attack_heavy 判定区间 end=startup+active | 实际=28 期望=28 | 来源=schema §3/E-2
  [PASS][组A] E-6 8 条动作齐全(actions==8) | 实际=8 期望=8 | 来源=schema §7 / E-6
  [PASS][组A] E-6 8 条 logic_fps 全=60(@60) | 实际=true 期望=true | 来源=schema §7 / E-6
  [PASS][组A] E-6 state_priority 互异 | 实际=true 期望=true | 来源=schema E-6
  [PASS][组A] E-6 logic_fps==Engine.physics_ticks_per_second | 实际=60 期望=60 | 来源=schema §7
---- [4] 组B 与 R19 裁决值「4/9/9=22、无敌[4,13)」逐项核对 ----
  [PASS][组B] roll.startup_frames | 实际=4 期望=4 | 来源=R19 裁决 4/9/9=22、无敌[4,13)
  [PASS][组B] roll.active_frames | 实际=9 期望=9 | 来源=R19 裁决 4/9/9=22、无敌[4,13)
  [PASS][组B] roll.recovery_frames | 实际=9 期望=9 | 来源=R19 裁决 4/9/9=22、无敌[4,13)
  [PASS][组B] roll.total | 实际=22 期望=22 | 来源=R19 裁决 4/9/9=22、无敌[4,13)
  [PASS][组B] roll.invulnerable_end_frame(按E-7:4+9=13) | 实际=13 期望=13 | 来源=R19 裁决 4/9/9=22、无敌[4,13)
  [PASS][组B] roll.logic_fps(@60) | 实际=60 期望=60 | 来源=R19 裁决 4/9/9=22、无敌[4,13)
==== [R19 FRAME DATA VERIFY] SUMMARY ====
  组A 文档核对 | DOC_PASS=40 DOC_FAIL=0 -> DOC_CONSISTENCY=PASS
  组B 裁决值 | VERDICT_PASS=6 VERDICT_FAIL=0 -> MATCH
  合计 | PASS_COUNT=46 FAIL_COUNT=0
  RESULT=ALL_MATCH
  NOTE: quit(0)=脚本执行/读取成功；PASS/FAIL 由实际值 vs 期望值真实计算，不预设结论；不写 courtyard.tscn。
==== [R19 FRAME DATA VERIFY] END ====
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G4_RUN_EXIT=0
```

### 2.3 PASS/FAIL 结论

| 组 | 项数 | 结果 |
|---|---|---|
| 组A 文档核对（Boss 三招 15 + 翻滚 11 + 攻击 10 + E-6 4 = 40 项） | 40 | `DOC_PASS=40 DOC_FAIL=0 -> DOC_CONSISTENCY=PASS` |
| 组B R19 裁决值（翻滚 6 项） | 6 | `VERDICT_PASS=6 VERDICT_FAIL=0 -> MATCH` |
| **合计** | **46** | **`PASS_COUNT=46 FAIL_COUNT=0`、`RESULT=ALL_MATCH`** |

- `SCRIPT ERROR` / `Parse Error` / `ERROR:` / `[FAIL]` / `FAIL_COUNT=[1-9]`：Grep 扫描 `R19-verify-run.log` **0 匹配**。
- 主真跑 `quit(0)`；PASS/FAIL 由「实际值 vs 期望值」逐项真实计算，未预设结论、未伪造输出。

### 2.4 翻滚帧逐项（全部 PASS）

`startup=4 / active=9 / recovery=9 / inv=[4,13) / logic_fps=60 / total(derived)=22`；E-7 四项自洽式 `inv_start==startup`、`inv_end==startup+active`、`inv_len==active`、`0<=start<end<=total` 全 PASS；组B 6 项裁决值核对全 PASS。

### 2.5 Boss 三招帧数据未受影响（核对）

| 招式 | R19 实际（本轮 stdout） | 组A 期望（未改） | 结果 |
|---|---|---|---|
| `move_01_dagger_slash` | `18/5/24` → `total=47`，`hit=[18,23)` | `18/5/24/47/23` | 5/5 PASS |
| `move_02_staff_slam` | `30/7/34` → `total=71`，`hit=[30,37)` | `30/7/34/71/37` | 5/5 PASS |
| `move_03_holy_hammer` | `42/9/40` → `total=91`，`hit=[42,51)` | `42/9/40/91/51` | 5/5 PASS |

与 R18 历史日志 `R18-verify-run.log` 第 37–39 行逐项一致；本轮 `boss_01_margit.tres` 与验证脚本 `BOSS_MOVES` 期望值**均未改动**。

### 2.6 `courtyard.tscn` 未改动

G1~G4 全程前后 MD5 比对：`b5be0adb2c6cbaf90b52074c094b40ba`（before） == `b5be0adb2c6cbaf90b52074c094b40ba`（after），Rank-1 独占件未被触碰。

### 2.7 既有 WARNING（非 ERROR、非本轮问题，如实登记）

- G3 / G4 各 1 条 `2 ObjectDB instances were leaked at exit`；
- G4 另有 1 条 `[ChunkManager] 未找到 ChunkRoot`（`res://scripts/world/chunk_streaming.gd:51`）。

与 R16 / R18 历史日志同类告警，非 `ERROR`、EXIT 仍为 0，未处理、未越界修改。

---

## ③ 未完成项与阻塞

- **阻塞：无**。本轮任务 4 项（改 `.tres`、同步 5 份文档口径、更新验证脚本并真跑复跑、三段门禁）全部完成。
- **残留旧口径登记（按派单点名范围与「不伪造输出」原则有意保留，非阻塞，供上级决定是否追加同步）**：

| 文件 | 残留位置 | 性质 | 未改原因 |
|---|---|---|---|
| `DONE-R18.md` | 第 89 / 169 / 170 / 193 / 194 / 196 / 204 / 221 行 | R18 历史真跑 stdout + 待裁决差异登记（当时真实状态） | 历史记录，改之即伪造输出；R19 裁决结论已在 `DONE-R19.md` 落地 |
| `DONE-R16.md` | 第 277 行 `帧=4/12/12 | invul=[4,16]` | R16 历史 stdout | 历史真实输出；已在**附录 B** 追加裁决修正注记说明，不篡改原文 |
| `teamwork/Rank-2/player_actions.tres` | 第 95 / 98 行 `active_frames=12` / `invulnerable_end_frame=16` | R2 时代历史规格件副本，**非运行权威件**（运行权威为 `godot/data/combat/player_actions.tres`） | 派单任务 1 仅点名 `godot/data/combat/player_actions.tres`，可写范围亦只列该份；未越界改历史副本 |
| `README.md` 第 105 行 / `COMBAT-BUILD.md` 第 143 行 / `E8-裁决建议表.md` 第 41 行 | `[4,16)` | 历史文档旧口径 | 派单任务 2 未点名，不改 |
| `调度任务单-latest.json` 第 6 行 | 旧口径描述 | 调度中枢派单文件 | 非本工位交付件，不改 |
| 本轮 7 个改动文件中的各裁决注记 | 「改前 `4/12/12=28`、无敌 `[4,16)`」引用 | 本轮有意保留的「改前值→改后值」注记 | 按任务要求「注明按裁决」，属正确内容，非残留 |

- **未改**：Boss 数值（`boss_01_margit.tres` 及验证脚本 `BOSS_MOVES`）、`courtyard.tscn`（Rank-1 独占）、其它工位文件、群聊总线 / 总纲 / 协作契约 / 进度台账、`project.godot`；未自行 git commit / push。
- **并发状态**：本实例独立派单会话；outbox 写前为空（已只读确认），仅写本轮回执 1 份，写后被中枢即时消费归档（见 ④ 送达态），未重复写第二份。

---

## ④ 回执

写入 `teamwork/command_center/ai/2/outbox/cmd-20261109-102334-084-A2.json`：

```json
{"task_id":"cmd-20261109-102334-084-A2","ai":2,"status":"done","result":"引用 DONE-R19.md 实际结论"}
```

**送达态（写后只读核验）**：回执写入 outbox 后已被调度中枢即时消费并归档为 `teamwork/command_center/dispatcher/receipts/cmd-20261109-102334-084-A2.json`（107 字节，内容与上式逐字一致，10:47）；`teamwork/command_center/ai/2/status.json` 现为 `state=idle` / `current_task` 为空 / `completed=21` → 中枢已确认本轮 `done`、完成数 +1、ai=2 转空闲。故 outbox 现为空是「回执已送达中枢」的正常终态，非「回执未写」；按并发保护「不重复写第二份回执」，本实例不重复写 outbox 回执。
