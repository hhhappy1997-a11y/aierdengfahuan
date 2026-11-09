# DONE-R18.md —— R18 · Rank-2 战斗帧数据核对

> 派单：`cmd-20261109-095518-173-A2`，`[ROUND=R18]`，调度中枢 GUI 下达（`2026-11-09 09:55:19`）。
> 角色：Rank-2 执行 AI。轮次标志：`DONE-R18.md`。
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（`v4.7.2.stable.official.ed1daf0bf`）。
> 工程根：`F:\Game\aierdengfahuan\godot\`（`--path` 实参）。
> 本轮**全部命令真跑、贴实际 stdout、未伪造输出**；**发现不一致只如实登记，不擅改任何数值**。中文 UTF-8。

---

## ① 交付清单

| # | 文件 | 类型 | 说明 |
|---|---|---|---|
| 1 | `godot\scripts\verify_frame_data.gd` | 新建 | `extends SceneTree` 核对脚本。真读 `res://data/combat/boss_01_margit.tres` 与 `res://data/combat/player_actions.tres`，逐项打印实际值 / 期望值 / PASS\|FAIL。Godot 4 合法语法（`--check-only` EXIT=0 实证） |
| 2 | `Rank-2\R18-verify-run.log` | 新建 | 三段门禁 + 主真跑的**完整实际 stdout 与各段 EXIT** 原始留档（含终端 ANSI 着色控制码字节） |
| 3 | `Rank-2\DONE-R18.md` | 新建 | 本文件：①交付清单 ②自检含完整实际 stdout ③未完成项与阻塞 |
| 4 | `command_center\ai\2\outbox\cmd-20261109-095518-173-A2.json` | 新建 | 回执 JSON，`task_id` 取本轮派单 id，`result` 引用本文件实际结论 |

**边界声明**
- 未碰 `courtyard.tscn`；未改任何 `.tres` 数值；未改 `boss_01_margit.tres` / `player_actions.tres` / `数据表schema.md` / `BOSS-DATA-FINAL.md` 一字。
- 只写 `Rank-2\`、`godot\scripts\verify_frame_data.gd`、`command_center\ai\2\outbox\` 回执三处（均在可写范围内）。
- 未写其它工位 / 总线 / 总纲 / 契约 / 台账；未自行 git commit / push。
- 零付费、零外部依赖；默认不刺探（`00-群聊总线.md` 开工只读一次）；中文 UTF-8。
- 附注：G1 `--import` 由引擎刷新了 `.godot\` 导入缓存（Godot 正常行为），非人工改动任何数值文件。

---

## ② 自检（含完整实际 stdout）

### 2.1 三段门禁 + 主真跑（实际执行命令）

`--path` 实参均为 `F:\Game\aierdengfahuan\godot`（下记 `<root>`）；`--check-only --script` 与 `--script` 的脚本参数按 Godot 合法 `res://` 路径传入（`res://scripts/verify_frame_data.gd`）。

| 段 | 命令 | 实际 EXIT |
|---|---|---|
| G1 | `--headless --path <root> --import` | `G1_IMPORT_EXIT=0` |
| G2 | `--headless --path <root> --check-only --script res://scripts/verify_frame_data.gd` | `G2_CHECKONLY_EXIT=0` |
| G3 | `--headless --path <root> --quit` | `G3_QUIT_EXIT=0` |
| G4 | `--headless --path <root> --script res://scripts/verify_frame_data.gd`（主真跑，产出逐项 PASS/FAIL 与汇总） | `G4_RUN_EXIT=0` |

**三段门禁 G1 / G2 / G3 与主真跑 G4 全部 EXIT=0**；脚本自身 `quit(0)` 表示执行与读取成功（详见 2.3 组B 说明）。

### 2.2 完整实际 stdout

> 下为 `Rank-2\R18-verify-run.log` 全文转录：**仅剔除 G1 进度行的终端 ANSI 着色控制码（`ESC[…m`）与由此产生的纯控制码空行**，文字与数值逐字未改；原始带控制码字节见同名 `.log` 文件。`==== … ====` 汇总行、每一项 `[PASS]/[FAIL]`、WARNING、EXIT 均为引擎/脚本原样输出。

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

==== [R18 FRAME DATA VERIFY] START ====
---- [0] 加载两份运行权威 .tres ----
[0] BOSS   load() OK | path=res://data/combat/boss_01_margit.tres | phases=2
[0] PLAYER load() OK | path=res://data/combat/player_actions.tres | actions=8
---- [1] 实际值快照：Boss 三招（phases[*].moves 按 id 去重）----
[ACTUAL][BOSS] id=move_01_dagger_slash | startup=18 active=5 recovery=24 | total(derived)=47 | hit=[18,23)
[ACTUAL][BOSS] id=move_02_staff_slam | startup=30 active=7 recovery=34 | total(derived)=71 | hit=[30,37)
[ACTUAL][BOSS] id=move_03_holy_hammer | startup=42 active=9 recovery=40 | total(derived)=91 | hit=[42,51)
---- [2] 实际值快照：player_actions 关键动作 ----
[ACTUAL][PLAYER] id=action_04_roll | startup=4 active=12 recovery=12 | inv=[4,16) | logic_fps=60 | total(derived)=28 | hit=[4,16)
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
  [PASS][组A] roll.active_frames(无敌段) | 实际=12 期望=12 | 来源=motion-mapping §4.1 / 战斗系统设计 §2 / schema §7
  [PASS][组A] roll.recovery_frames | 实际=12 期望=12 | 来源=motion-mapping §4.1 / 战斗系统设计 §2 / schema §7
  [PASS][组A] roll.invulnerable_start_frame | 实际=4 期望=4 | 来源=motion-mapping §4.1 / 战斗系统设计 §2 / schema §7
  [PASS][组A] roll.invulnerable_end_frame | 实际=16 期望=16 | 来源=motion-mapping §4.1 / 战斗系统设计 §2 / schema §7
  [PASS][组A] roll.logic_fps(@60) | 实际=60 期望=60 | 来源=schema §7 / E-6
  [PASS][组A] roll.total=4+12+12 | 实际=28 期望=28 | 来源=战斗系统设计 §2.2 / schema E-7
  [PASS][组A] E-7 inv_start==startup | 实际=4 期望=4 | 来源=schema E-7
  [PASS][组A] E-7 inv_end==startup+active | 实际=16 期望=16 | 来源=schema E-7
  [PASS][组A] E-7 inv_len(end-start)==active | 实际=12 期望=12 | 来源=战斗系统设计 §2.2 / schema E-7
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
---- [4] 组B 与派单字面期望「4/9/9、22 帧@60」逐项核对（差异如实登记）----
  [PASS][组B] roll.startup_frames | 实际=4 期望=4 | 来源=派单字面 4/9/9、22帧@60
  [FAIL][组B] roll.active_frames | 实际=12 期望=9 | 来源=派单字面 4/9/9、22帧@60
  [FAIL][组B] roll.recovery_frames | 实际=12 期望=9 | 来源=派单字面 4/9/9、22帧@60
  [FAIL][组B] roll.total | 实际=28 期望=22 | 来源=派单字面 4/9/9、22帧@60
  [FAIL][组B] roll.invulnerable_end_frame(按E-7:4+9=13) | 实际=16 期望=13 | 来源=派单字面 4/9/9、22帧@60
  [PASS][组B] roll.logic_fps(@60) | 实际=60 期望=60 | 来源=派单字面 4/9/9、22帧@60
==== [R18 FRAME DATA VERIFY] SUMMARY ====
  组A 文档核对 | DOC_PASS=40 DOC_FAIL=0 -> DOC_CONSISTENCY=PASS
  组B 派单字面 | DISPATCH_PASS=2 DISPATCH_FAIL=4 -> MISMATCH_REGISTERED
  合计 | PASS_COUNT=42 FAIL_COUNT=4
  RESULT=DATA_CONSISTENT_WITH_DOCS__DISPATCH_LITERAL_MISMATCH_REGISTERED
  NOTE: quit(0)=脚本执行/读取成功；组B FAIL 为派单字面值与实际 .tres 既有差异的如实登记，非脚本/数据错误；不擅改数值。
==== [R18 FRAME DATA VERIFY] END ====
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G4_RUN_EXIT=0
```

### 2.3 逐项核对结论

脚本把核对拆成两组，**期望值出处逐项标注在 stdout 的「来源」列**：

**组A —— 与 `BOSS-DATA-FINAL.md` / `数据表schema.md`（并落到本工位权威件 `motion-mapping.md`、`战斗系统设计.md`）逐项核对：40 项全 PASS，`DOC_CONSISTENCY=PASS`**

| 核对对象 | 期望来源 | 实际值（真跑读取） | 结论 |
|---|---|---|---|
| Boss 三招 前摇/判定/后摇 | `BOSS-DATA-FINAL.md` §3.1 / §3.2、`数据表schema.md` §3 | m1 `18/5/24`、m2 `30/7/34`、m3 `42/9/40` | 9/9 PASS |
| Boss 三招 派生 total / 判定区间 | `BOSS-DATA-FINAL.md` §3.2、`数据表schema.md` E-2 | `47/[18,23)`、`71/[30,37)`、`91/[42,51)` | 6/6 PASS |
| 翻滚无敌帧 `action_04_roll` | `motion-mapping.md` §4.1、`战斗系统设计.md` §2、`数据表schema.md` §7 | `4/12/12=28`，无敌 `[4,16)`，`logic_fps=60` | 7/7 PASS |
| 翻滚 E-7 等式自洽 | `数据表schema.md` E-7 | `inv_start=4=startup`、`inv_end=16=4+12`、`inv_len=12=active`、`0<=4<16<=28` | 4/4 PASS |
| 攻击帧 `attack_light` / `attack_heavy` | `motion-mapping.md` §4.1、`数据表schema.md` E-2 | light `8/5/14=27 [8,13)`、heavy `20/8/26=54 [20,28)` | 10/10 PASS |
| E-6 全局（8 状态） | `数据表schema.md` §7 / E-6 | 8 条齐全、`logic_fps` 全 `60`、`state_priority` 互异、`Engine.physics_ticks_per_second=60` | 4/4 PASS |

**组B —— 与派单字面期望「4/9/9、22 帧@60」逐项核对：2 PASS / 4 FAIL，`MISMATCH_REGISTERED`**

| 项 | 派单字面期望 | `.tres` 实际 | 结论 |
|---|---|---|---|
| `roll.startup_frames` | 4 | 4 | PASS |
| `roll.active_frames` | 9 | **12** | **FAIL** |
| `roll.recovery_frames` | 9 | **12** | **FAIL** |
| `roll.total` | 22 | **28** | **FAIL** |
| `roll.invulnerable_end_frame`（按 E-7 = startup4 + active9 = 13） | 13 | **16** | **FAIL** |
| `roll.logic_fps`（@60） | 60 | 60 | PASS |

**汇总（实际 stdout）**：`PASS_COUNT=42 FAIL_COUNT=4`；`RESULT=DATA_CONSISTENT_WITH_DOCS__DISPATCH_LITERAL_MISMATCH_REGISTERED`。

> 退出码说明：脚本 `quit(0)` 仅表示「脚本正常执行、两份 `.tres` 成功读取、与权威文档逐项一致」；组B 的 4 个 FAIL 为**派单字面输入值与运行权威件既有差异**的如实登记产物，不是脚本错误、解析失败或数据损坏，故不据此置非 0 退出码。所有 FAIL 已在上方 stdout 与 §2.4 完整登记，未隐藏、未改写。

### 2.4 关键不一致（如实登记，不擅改数值）

派单括号给出的翻滚口径「**4/9/9、22 帧@60**」与 `godot\data\combat\player_actions.tres` 的 `action_04_roll` 实际值存在 **4 项差异**（见 §2.3 组B 表）：

- 实际 `startup/active/recovery = 4/12/12`，合计 **28 帧**；派单字面 `4/9/9`，合计 **22 帧**。
- 实际无敌帧 `invulnerable_start_frame=4` / `invulnerable_end_frame=16`，即 `[4,16)`；若按派单 `active=9` 且依 `数据表schema.md` E-7（`inv_end = startup + active`）应为 `13`，即 `[4,13)`。

**本工位全部权威件口径一致为 4/12/12=28、无敌 `[4,16)`**（均非本轮改动）：`motion-mapping.md` §4.1、`战斗系统设计.md` §2.1/§2.2、`DONE-R16.md`、`接口契约.md` M1 验收项，以及 `数据表schema.md` E-7 等式（实际数据 `inv_start=4=startup`、`inv_end=16=4+12` 自洽）。即：**运行权威件与文档彼此一致，差异仅存在于「派单字面值」与「运行权威件/文档」之间**。

按硬性约束「**发现不一致只如实登记，不擅改数值**」：本轮**未改** `.tres` 任何数值、**未改**任何文档口径、**未**为了凑 PASS 而调整期望值或数据。差异定性为**待总指挥裁决的输入口径差**（派单字面值疑为旧值/笔误，或是否要求据其改表），本执行 AI 不自行裁决、不擅改。

---

## ③ 未完成项与阻塞

1. **待总指挥裁决 · 派单字面 4/9/9、22 帧@60 vs 运行权威件 4/12/12=28 `[4,16)`**：二者取哪套为准（派单字面是否笔误、或是否要求据派单修改 `.tres`）。本轮只登记 4 项差异、未改数值。这是本轮唯一实质未决项。
2. **E-8 三项抗性数值冲突**（`BOSS-DATA-FINAL.md` §6.3 / §8 历史待裁决项，`380>330` / `450>360` / `400>320`）：属异常积累数值，不在本轮「帧数据」核对范围，未触碰、未沿用旧裁决。
3. **引擎侧 2 条历史 WARNING**：G3 / G4 的 `2 ObjectDB instances were leaked at exit` 与 G4 的 `[ChunkManager] 未找到 ChunkRoot`。均为工程历史已知的非 ERROR 告警（R17 同类日志同样出现），非 `verify_frame_data.gd` 引入，不影响任何门禁 EXIT（全 0）；非本工位可自行处置，如实留档。
4. **运行期可见性 / 人工试玩 / apk / Android SDK / ComfyUI 等长期阻塞**：沿用历史登记，非本轮范围，未推进、未谎报。
5. 无其它阻塞：三段门禁与主真跑均真实完成、stdout 完整、交付件齐备。

---

## ④ 回执

已写 `command_center\ai\2\outbox\cmd-20261109-095518-173-A2.json`：

```json
{
  "task_id": "cmd-20261109-095518-173-A2",
  "ai": 2,
  "status": "done",
  "result": "见 Rank-2/DONE-R18.md 实际结论：verify_frame_data.gd 真跑，三段门禁 G1(--import)/G2(--check-only --script)/G3(--quit) 与主真跑 G4(--script) EXIT 全=0；组A 与 BOSS-DATA-FINAL.md/数据表schema.md 逐项核对 DOC_PASS=40 DOC_FAIL=0（Boss 三招 18/5/24、30/7/34、42/9/40；翻滚 4/12/12=28 无敌[4,16)；攻击 8/5/14、20/8/26）；派单字面 4/9/9、22帧@60 与实际 .tres 存在 4 项差异（active 12≠9、recovery 12≠9、total 28≠22、inv_end 16≠13）已如实登记、不擅改数值，待总指挥裁决；RESULT=DATA_CONSISTENT_WITH_DOCS__DISPATCH_LITERAL_MISMATCH_REGISTERED。"
}
```

> 中枢消费留痕（如实补记）：回执写入 `outbox\` 后已被调度中枢即时读取并归档至
> `command_center\dispatcher\receipts\cmd-20261109-095518-173-A2.json`（内容与上方逐字一致，已复核），
> `command_center\ai\2\status.json` 由 `working / completed=19` 转为 `idle / completed=20 / current_task=""`
> （`last_seen 2026-11-09 10:10:08`）。因此 `outbox\` 当前为空是**消费后的正常终态**，非未写或丢失；
> 本轮不重复写第二份回执，避免重复计数。

---

## ⑤ 边界复核

- 改动文件仅 4 个新建件（见 ①）：`godot\scripts\verify_frame_data.gd`、`Rank-2\R18-verify-run.log`、`Rank-2\DONE-R18.md`、`command_center\ai\2\outbox\cmd-20261109-095518-173-A2.json`。
- 未碰 `courtyard.tscn`、未改任何 `.tres` 数值、未自行 git、未写其它工位 / 总线 / 总纲 / 契约 / 台账。
- 零付费、零外部依赖、默认不刺探、中文 UTF-8、Godot 4 合法语法（`--check-only` EXIT=0 实证）。
- 全部数值与 PASS/FAIL 来自本机实际文件读取与引擎真跑，**未伪造输出、未冒充全绿**：组B 4 项 FAIL 如实保留并登记。
