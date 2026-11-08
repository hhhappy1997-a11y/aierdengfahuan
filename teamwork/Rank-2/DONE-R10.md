# DONE-R10.md —— Rank-2 执行 `00-汇总.md` §4 A1 裁决（E-8 数值回改）

> 轮次：R10「执行总指挥裁决 A1」；任务单 `cmd-20261109-040336-521-A2`；执行 AI：Rank-2。
> 裁决来源：`teamwork\00-汇总.md` §4 A1（总指挥 04:00 裁决），建议依据 `Rank-2\E8-裁决建议表.md`，
> 数值真源 `Rank-2\BOSS-DATA-FINAL.md`，开工只读一次 `teamwork\00-群聊总线.md`。
> 引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`（`--version` 实测 `4.7.2.stable.official.ed1daf0bf`）。
> 中文 UTF-8。本文件所有数值与日志均来自本机实际文件与实际 stdout/grep 输出，未伪造、未冒充全绿。

---

## 0. 结论速览

| 项 | 结论 |
|---|---|
| 裁决 A1 | **已执行**：`boss_01_margit.tres` 三个 `StatusBuildup.max_resistance` 由 `330/360/320` 回改为 `400/480/420`（bleed / poison / frost），留余量满足 `threshold + gain×8 ≤ max_resistance` |
| 两份副本同步 | **完成**：`teamwork\Rank-2\` 与 `godot\data\combat\` 两份改后数值逐字节一致（排除 `ext_resource` 后全字段 `DIFF_RC=0`） |
| 最小改动 | **完成**：改前副本 vs 改后运行件 diff **恰好 3 行**；threshold / gain / 触发伤害 / 削韧 / N=8 / `数据表schema.md` 口径 / `combat_data_validator.gd` 校验式全部未动 |
| 真跑 A（`_ready()`） | **完成**：改前复现 `检查项 491，错误 3` + 4 条 `ERROR:`；改后 `检查项 491，错误 0`、`ERROR=0`，E-8 三项 FAIL 与由此产生的 4 条 ERROR 全部消失 |
| 真跑 B（三段门禁） | **完成、无回归**：复跑稳定快照 `52/52 --check-only EXIT=0`、`SCRIPT ERROR=0`、`ERROR=0`、`hides a global=0`、`Failed to load=0`，仅 1 条既有 `ObjectDB leaked` WARNING，与 R9 基线一致 |
| 如实登记 | 首轮门禁合并日志曾出现 **1 条** `ERROR: Failed to open 'user://logs/godot2026-11-09T04.08.31.log'`（引擎文件日志偶发写入失败），复跑不再现，非本轮改动引起；不冒充首轮全绿 |
| 交付件 / 回执 | `DONE-R10.md`、`E8-VERDICT-LOG.md` 已写；回执写入 `ai\2\outbox\` 后由中枢即时消费归档（`dispatcher\receipts\` + `ledger.jsonl` 记 `status=done`），outbox 终态为空属协议正常回收（§4.1） |

---

## 1. 实际交付清单（① 改动前后数值）

### 1.1 改动明细（共 6 处编辑 = 两份副本 × 3 个数值）

| # | 文件（两份同改） | 行 | sub_resource | 字段 | 改前 | 改后 |
|---|---|---|---|---|---|---|
| 1 | `teamwork\Rank-2\boss_01_margit.tres` | 50 | `Resource_status_bleed` | `max_resistance` | `330.0` | **`400.0`** |
| 2 | `teamwork\Rank-2\boss_01_margit.tres` | 67 | `Resource_status_poison` | `max_resistance` | `360.0` | **`480.0`** |
| 3 | `teamwork\Rank-2\boss_01_margit.tres` | 84 | `Resource_status_frost` | `max_resistance` | `320.0` | **`420.0`** |
| 4 | `godot\data\combat\boss_01_margit.tres` | 50 | `Resource_status_bleed` | `max_resistance` | `330.0` | **`400.0`** |
| 5 | `godot\data\combat\boss_01_margit.tres` | 67 | `Resource_status_poison` | `max_resistance` | `360.0` | **`480.0`** |
| 6 | `godot\data\combat\boss_01_margit.tres` | 84 | `Resource_status_frost` | `max_resistance` | `320.0` | **`420.0`** |

其余字段、行号、`load_steps=16`、`sub_resource` 声明、`ExtResource`/`SubResource` 引用、字符串字段值一字未动。

### 1.2 余量校验（保持 N=8、`threshold` / `gain` 不变）

| 异常 | `threshold` | `gain` | `threshold + gain×8` | 改前 `max_resistance` | 改后 `max_resistance` | 结论（余量） |
|---|---|---|---|---|---|---|
| bleed | `180.0` | `25.0` | `380.0` | `330.0`（380>330 FAIL） | `400.0` | ✓ 通过，余量 `20.0` |
| poison | `210.0` | `30.0` | `450.0` | `360.0`（450>360 FAIL） | `480.0` | ✓ 通过，余量 `30.0` |
| frost | `160.0` | `30.0` | `400.0` | `320.0`（400>320 FAIL） | `420.0` | ✓ 通过，余量 `20.0` |

### 1.3 改后逐字节核对（两份副本一致）

实际输出：

```
=== 改后 · 工位稿 三个 max_resistance ===
50:max_resistance = 400.0
67:max_resistance = 480.0
84:max_resistance = 420.0
=== 改后 · 运行件 三个 max_resistance ===
50:max_resistance = 400.0
67:max_resistance = 480.0
84:max_resistance = 420.0
=== 改后 · 三数值行两份逐字节比对 ===
VAL_DIFF_RC=0
=== 改后 · 排除 ext_resource 后 diff（数值/字段/sub_resource 逐字） ===
DIFF_RC=0
=== 改后 · 全文件 cmp ===
... differ: byte 119, line 3
CMP_RC=1
=== 改前副本(临时工程) vs 改后运行件 diff（预期恰好 3 行数值差异） ===
50c50
< max_resistance = 330.0
---
> max_resistance = 400.0
67c67
< max_resistance = 360.0
---
> max_resistance = 480.0
84c84
< max_resistance = 320.0
---
> max_resistance = 420.0
```

**结论**：
- 三个 `max_resistance` 数值行两份**逐字节一致**（`VAL_DIFF_RC=0`）；排除 `ext_resource` 行后全部数值 / 字段 / `sub_resource` 声明**逐字一致**（`DIFF_RC=0`）。
- 全文件 `cmp` 不一致（`byte 119, line 3`），差异**仅为既有 5 条 `ext_resource path`**（工位稿 `res://data/schemas/*.gd` vs 运行件 `res://scripts/combat/*.gd`）——这是 R6 装配必需的路径修正（见 `COMBAT-ASSEMBLY.md` §2.5、`BOSS-DATA-FINAL.md` §0/§7），非数值、改前即存在、本轮不动；**不伪造「全文件逐字节相同」**。
- 「改前副本 vs 改后运行件」diff **恰好 3 行**，证明两份改动严格只有 3 个数值。

### 1.4 严禁改动项复核（全部保持原值，实际 grep）

```
39:threshold = 180.0          42:trigger_damage_ratio = 0.12   43:trigger_damage_flat = 0.0
44:trigger_poise_damage = 25.0 49:resistance_gain_per_trigger = 25.0
56:threshold = 210.0          59:trigger_damage_ratio = 0.0      60:trigger_damage_flat = 40.0
61:trigger_poise_damage = 0.0  66:resistance_gain_per_trigger = 30.0
73:threshold = 160.0          76:trigger_damage_ratio = 0.08     77:trigger_damage_flat = 0.0
78:trigger_poise_damage = 40.0 83:resistance_gain_per_trigger = 30.0
96:poise_damage = 22.0  120:poise_damage = 45.0  144:poise_damage = 70.0
147:status_buildup_frost = 35.0   （m3 唯一施加值）
```

- N=8：`combat_data_validator.gd:17` `@export var resistance_sample_triggers: int = 8` 未改。
- E-8 校验式：`combat_data_validator.gd:212-213` `var limit = threshold + gain × N` / `_ok(limit <= buildup.max_resistance, ...)` 未改；validator 工位件与临时工程副本 `cmp` → `VALIDATOR_CMP_RC=0`（一字未改）。
- `数据表schema.md:427` §9 E-8 口径 `threshold + resistance_gain_per_trigger × 8 <= max_resistance` 未写、未改。

---

## 2. 自检含真跑实际输出（②）

### 2.1 真跑方式说明

`CombatDataValidator` 未落位真实工程根（`godot\scripts\combat\` 无该文件，见 `BOSS-DATA-FINAL.md` §8.3），故沿用 R5 §2.1 既有口径：在**系统临时最小工程**
`C:\Users\62668\AppData\Local\Temp\r10_gate_a2\`（不落 teamwork / 真实工程根、不提交、收尾删除）复制
8 个 `scripts\combat\*.gd`（`class_name` 齐全）+ 工位 `combat_data_validator.gd` + 3 份 `.tres`，
由 `gate\r10_gate_runner.gd` 挂载 `CombatDataValidator` 并赋值 3 份 `.tres`，`add_child()` 触发其
`_ready()` 实跑；`main.tscn` 为主场景。跑 `--headless --import` + `--headless --quit`。
改前 / 改后使用**同一临时工程**，仅把改后的 `boss_01_margit.tres` 覆盖进 `data\combat\` 后再跑。

### 2.2 真跑 A：改前复现 / 改后消失（实际 stdout/grep，逐字）

**改前（`330/360/320`）** —— `SEG0_RC=0` `4.7.2.stable.official.ed1daf0bf`、`SEG1_RC=0`（29 行）、`SEG3_RC=0`：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_01_bleed
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ok (res://scripts/combat/combat_data_validator.gd:86)
       [1] _validate_e8 (res://scripts/combat/combat_data_validator.gd:213)
       [2] _ready (res://scripts/combat/combat_data_validator.gd:75)
       [3] _ready (res://gate/r10_gate_runner.gd:18)
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_02_poison
   at: push_error (core/variant/variant_utility.cpp:1023)
   ... [同栈：_ok / _validate_e8 / _ready / _ready] ...
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_03_frost
   at: push_error (core/variant/variant_utility.cpp:1023)
   ... [同栈：_ok / _validate_e8 / _ready / _ready] ...
[CombatDataValidator] E-1/E-3/E-4/E-5/E-8/E-9 检查项 491，错误 3
ERROR: [CombatDataValidator] 数据表自洽校验失败，错误 3 项
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/combat/combat_data_validator.gd:79)
       [1] _ready (res://gate/r10_gate_runner.gd:18)
[R10-GATE] CombatDataValidator._ready() 已触发，挂载 3 份 .tres（boss/enemy/player_actions）
```

```
all_before.log 行数: 59
ERROR: 行数: 4
SCRIPT ERROR: 行数: 0
Parse Error: 行数: 0
32:ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_01_bleed
39:ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_02_poison
46:ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_03_frost
54:ERROR: [CombatDataValidator] 数据表自洽校验失败，错误 3 项
53:[CombatDataValidator] E-1/E-3/E-4/E-5/E-8/E-9 检查项 491，错误 3
```

**改后（`400/480/420`）** —— `SEG1_RC=0`（16 行）、`SEG3_RC=0`：

```
=== 把改后 .tres 同步进临时工程（覆盖改前验证副本） ===
临时工程 boss .tres 三个 max_resistance:
50:max_resistance = 400.0
67:max_resistance = 480.0
84:max_resistance = 420.0
=== seg3 完整 stdout/stderr 原文 ===
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[CombatDataValidator] E-1/E-3/E-4/E-5/E-8/E-9 检查项 491，错误 0
[R10-GATE] CombatDataValidator._ready() 已触发，挂载 3 份 .tres（boss/enemy/player_actions）
=== 合并日志与 grep 统计 ===
all_after.log 行数: 20
ERROR: 行数: 0
FAIL 行数: 0
SCRIPT ERROR: 行数: 0
Parse Error: 行数: 0
--- ERROR: / FAIL 原文（预期 0 命中） ---
GREP_ERR_RC=1
--- 检查项汇总 / R10-GATE 标记（证明 _ready 确实触发） ---
19:[CombatDataValidator] E-1/E-3/E-4/E-5/E-8/E-9 检查项 491，错误 0
20:[R10-GATE] CombatDataValidator._ready() 已触发，挂载 3 份 .tres（boss/enemy/player_actions）
```

**结论**：改前 **E-8 三项 FAIL + 4 条 `ERROR:`**（`检查项 491，错误 3`）；改后 `检查项 491，错误 0`、
`ERROR: 行数 0`、`FAIL 行数 0`、`grep` 0 命中（`GREP_ERR_RC=1`）—— **4 条 ERROR 全部消失**。
`R10-GATE` 标记与 491 项证明 `_ready()` 确实全量跑完（不是未加载导致的假绿）；
`SCRIPT ERROR=0` / `Parse Error=0` / `EXIT=0` 前后一致，脚本层无缺陷。

### 2.3 真跑 B：真实工程根三段门禁（确认无回归）

工程根 `F:/Game/aierdengfahuan/godot`。命令口径同 `DONE-R9.md` §2.1。

**首轮实际输出**：

```
SEG0_RC=0                     4.7.2.stable.official.ed1daf0bf
SEG1_RC=0                     final_seg1.log 行数: 16
SEG2_SCRIPTS=52 SEG2_FAIL=0
SEG3_RC=0
--- seg3 原文 ---
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
=== 合并 FINAL 日志与 grep 统计 ===
final_all.log 行数: 127
SCRIPT ERROR: 0
Parse Error: 0
ERROR: 行数: 1
WARNING 行数: 1
hides a global: 0
Failed to load: 0
--- ERROR/WARNING 原文 ---
78:ERROR: Failed to open 'user://logs/godot2026-11-09T04.08.31.log'.
126:WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
```

**首轮 1 条 ERROR 定位与归因（如实登记、不冒充全绿）**：

```
=== 该 ERROR 落在哪个分段日志 ===
--- final_seg0.log ---  (无)
--- final_seg1.log ---  (无)
--- final_seg2.log ---
61:ERROR: Failed to open 'user://logs/godot2026-11-09T04.08.31.log'.
--- final_seg3.log ---  (无)
=== final_all.log 第 72~84 行上下文 ===
72:Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
74:Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
76:Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
78:ERROR: Failed to open 'user://logs/godot2026-11-09T04.08.31.log'.
79:   at: copy (core/io/dir_access.cpp:429)
80:Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
=== 工程根是否有 file_logging 配置 ===
(project.godot 无 file_logging 配置)
=== 复跑 SEG3 单独一次 ===
RECHECK_SEG3_RC=0
RECHECK ERROR 行数: 0
```

- 仅出现在 `final_seg2.log`（52 次连续 `--check-only --script` 启动中的某一次），是 Godot 引擎写
  `user://logs/godot<时间戳>.log` 的**偶发文件日志写入失败**（`at: copy (core/io/dir_access.cpp:429)`）；
- 工程根 `project.godot` 无 `file_logging` 配置；**与 `.tres` 数值改动无关、非脚本层、非战斗层、非 SCRIPT ERROR**；
- 单独复跑 SEG3 → `ERROR 行数: 0`。

**复跑完整三段稳定快照（实际输出）**：

```
RE_SEG1_RC=0
RE_SEG2_SCRIPTS=52 RE_SEG2_FAIL=0
RE_SEG3_RC=0
re_all.log 行数: 124
SCRIPT ERROR: 0
Parse Error: 0
ERROR: 行数: 0
WARNING 行数: 1
hides a global: 0
Failed to load: 0
--- ERROR/WARNING 原文 ---
123:WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
```

**结论**：稳定快照 `52/52 --check-only EXIT=0`、`SCRIPT ERROR=0`、`Parse Error=0`、**`ERROR=0`**、
`hides a global=0`、`Failed to load=0`，仅 1 条既有 `ObjectDB leaked` WARNING（ChunkManager 在途加载时序，
与 `GATE-FINAL.md` §6 / `DONE-R9.md` §2.2 一致，非 ERROR）—— **与 R9 FINAL 基线一致，无回归**。
首轮那 1 条偶发 `user://logs` ERROR 复跑不再现，判定为引擎文件日志时序现象，非本轮改动引起。

---

## 3. 未完成项与阻塞（③ 只登记，不擅改）

| # | 项 | 现状 / 归属 | 本轮处置 |
|---|---|---|---|
| 1 | `00-汇总.md` §4 **A4**（`存档与flag规范.md` §4.4 旧措辞回改）、**A6**（契约 §2 两段式示例回改） | 总指挥裁决已出口径、写明「待后续轮次回改文档」；属主 AI / 跨工位文档 | **只登记不擅改**（任务书硬性约束：其余待裁决项只登记） |
| 2 | `CombatDataValidator` / `enemy_director.gd` / `player_state_machine.gd` 未落位真实工程根 | `BOSS-DATA-FINAL.md` §8.3 已登记；是否落位待总指挥裁决 | 本轮 `_ready()` 验证在系统临时最小工程实跑（R5 既有口径）；未落位、未改工程根脚本目录 |
| 3 | `res://data/schema`（单数） vs `schemas`（复数）口径 | `COMBAT-ASSEMBLY.md` §6.2 / `R5-待裁决登记.md` §6.2 登记，裁决归总指挥 | 只登记，未改两份 `.tres` 的 `ext_resource` 路径与任何文档口径 |
| 4 | 历史 signal 去留 / I-2 唯一发射点收敛注释口径、Q1（`SpriteFrames` vs `set_pose`） | `COMBAT-ASSEMBLY.md` §6.3、`BOSS-DATA-FINAL.md` §8 登记 | 只登记，未改既有脚本 |
| 5 | 首轮门禁 1 条 `user://logs` 偶发 ERROR | 已定位归因、复跑不再现（§2.3） | 如实登记，**未冒充首轮全绿**，未越界「修复」引擎日志行为 |
| 6 | 1 条 `ObjectDB leaked` WARNING | 既有、非 ERROR、ChunkManager 在途加载时序 | 如实保留，不越界修复 |
| 7 | 手感调校 / 渲染与运行期可见性 / 人工试玩 | 契约 §5、总汇 §5「需人工项」 | 超本轮范围，未宣称已验收 |
| 8 | 窗口渲染 / apk / ComfyUI / qwen-image 出图 / 仓库推送 | 总汇 §6.2 风险项，需用户输入或外部条件 | 与本轮无关，未触碰 |

**本轮无阻塞项**：裁决 A1 指定的数值回改、两副本同步、真跑验证、交付与回执均已完成。

---

## 4. 边界声明

- **实际写入**：两份 `boss_01_margit.tres`（各 3 个数值，共 6 处编辑）+ 新建 `DONE-R10.md`、
  `E8-VERDICT-LOG.md` + 回执 `teamwork\command_center\ai\2\outbox\cmd-20261109-040336-521-A2.json`；
  系统临时工程与日志（收尾删除）。
- **未写**：`project.godot`（Rank-1 独占）、`godot\scripts\combat\`、其它工位、总线 / 总纲 / 契约 / 台账；
  **未自行 git commit / push**；未写 `command_center` 其它目录。
- **未改**：任何 `.gd`（含 `combat_data_validator.gd` 校验式与 N=8）、`数据表schema.md` 口径、
  threshold / gain / 触发伤害 / 削韧 / 招式施加值 / `status_type` / 阶段与招式数值。
- 零付费 / 零外部依赖；默认不刺探；既有件不重做（仅 3 个数值 + 同步）；中文 UTF-8；Godot 4 合法语法
  （52/52 `--check-only` EXIT=0）。
- 真跑日志在系统临时目录，关键 stdout/grep 原文已逐字抄录于本文 §2，可复核；**未伪造输出、未冒充全绿**。

### 4.1 回执消费时序（如实登记）

回执按任务单 id 写入 `teamwork\command_center\ai\2\outbox\cmd-20261109-040336-521-A2.json` 后，
调度中枢 dispatcher **持续监听、写入即消费并归档**（文件协议正常回收，非写失败、非未完成），实际证据：

```
=== 归档回执（dispatcher/receipts/，权威落点） ===
{ "task_id": "cmd-20261109-040336-521-A2", "ai": 2, "status": "done", "result": "引用 DONE-R10.md 实际结论：..." }
=== ledger.jsonl:35 终态 ===
{"id": "cmd-20261109-040336-521-A2", ..., "status": "done",
 "finished_at": "2026-11-09 04:12:24", "result": "引用 DONE-R10.md 实际结论：..."}
=== dispatcher.log（两次写入两次消费） ===
193:[2026-11-09 04:11:07] ← 2 号 AI 回执 <cmd-20261109-040336-521-A2> 完成：引用 DONE-R10.md 实际结论：...
195:[2026-11-09 04:12:24] ← 2 号 AI 回执 <cmd-20261109-040336-521-A2> 完成：引用 DONE-R10.md 实际结论：...
=== outbox 终态 ===
total 0 （空目录）
```

- 归档件 `dispatcher\receipts\cmd-20261109-040336-521-A2.json` 与写入件逐字一致
  （`task_id` / `ai=2` / `status=done` / `result` 引用本文实际结论，`result_len=726`）。
- `outbox\` **终态为空**属既有各轮同一现象（历史 outbox 一直为空），**非写失败、非未完成**：
  本轮两次向 `outbox\` 写入内容相同的 `status=done` 回执，均被中枢即时消费
  （`dispatcher.log:193` / `:195`），后者把 `ledger.jsonl:35` 的 `finished_at` 刷新为
  `2026-11-09 04:12:24`，命令 `status=done` 不变；**权威回执落点**为
  `dispatcher\receipts\cmd-20261109-040336-521-A2.json`。
- 中枢 `ai\2\status.json`：`state=idle`、`completed=11`、`last_seen=2026-11-09 04:11:07`。

---

> 完成标志：按任务单 `cmd-20261109-040336-521-A2` 在 `teamwork\command_center\ai\2\outbox\` 写
> `status=done` 回执，`result` 引用本文实际结论；中枢已收并记 `done`。

---

## 5. 并发实例复核补记（本实例 · 只追加 / 不覆盖 / 不重做）

> 本实例由 HOST 全闭环自动化启动后，发现 `DONE-R10.md`（本文 §0~§4）、`E8-VERDICT-LOG.md`、
> 两份 `boss_01_margit.tres` 数值（已为 `400/480/420`）、以及归档回执
> `dispatcher\receipts\cmd-20261109-040336-521-A2.json` / `ledger.jsonl:35 status=done`
> **已被并发实例先写**。按本轮「并发保护」硬约束：只补缺口 / 追加复核，不覆盖、不重做，
> 数值核对一致即可、不回退再改。以下为本实例**亲自实际执行**的复核输出，非引用旧结论、未伪造。

### 5.1 数值与副本复核（实际输出）

```
=== 工位稿 / 运行件 max_resistance ===
50:max_resistance = 400.0   67:max_resistance = 480.0   84:max_resistance = 420.0  （两份相同）
=== 三数值行两份逐字节 diff ===       VAL_DIFF_RC=0
=== 排除 ext_resource 后全字段 diff === DIFF_RC=0
=== 全文件 cmp ===                     differ: byte 119, line 3 ; CMP_RC=1
=== 差异原文 === 仅 5 条 ext_resource path：
  工位稿 res://data/schemas/*.gd  ←→  运行件 res://scripts/combat/*.gd（R6 装配既有差异、非数值、改前即存在）
```

结论与 §1.3 一致：三数值行逐字节一致、全字段（排除 ext_resource）一致；全文件差异仅为既有 5 条路径，不伪造「全文件逐字节相同」。

### 5.2 严禁改动项复核（实际 grep，均保持原值）

```
39:threshold = 180.0   49:gain = 25.0    56:threshold = 210.0   66:gain = 30.0
73:threshold = 160.0   83:gain = 30.0
42/43/44: trigger_damage_ratio = 0.12 / trigger_damage_flat = 0.0 / trigger_poise_damage = 25.0
59/60/61: 0.0 / 40.0 / 0.0        76/77/78: 0.08 / 0.0 / 40.0
96/120/144: poise_damage = 22.0 / 45.0 / 70.0    147:status_buildup_frost = 35.0
validator:17   @export var resistance_sample_triggers: int = 8            （N=8 未改）
validator:212  var limit: float = threshold + gain * float(resistance_sample_triggers)
validator:213  _ok(limit <= buildup.max_resistance, "E-8 抗性不溢出 -> %s" ... )（校验式未改）
数据表schema.md:427  §9 E-8 口径 `threshold + resistance_gain_per_trigger × 8 <= max_resistance`（未写未改）
```

### 5.3 真跑 A 复核：`CombatDataValidator._ready()` 改前 / 改后（本实例实际 stdout）

系统临时最小工程 `C:\Users\62668\AppData\Local\Temp\r10_recheck_validator\`（沿用 R5 既有口径，
不落 teamwork / 工程根、收尾删除）：复制 8 个 `class_name` 脚本 + 工位 `combat_data_validator.gd`
+ 3 份 `.tres`，`gate\validator_runner.gd` 挂载 validator 并 `add_child()` 触发 `_ready()`，
`main.tscn` 为主场景；改前 / 改后用同一工程，仅替换临时副本的 3 个 `max_resistance`。
三份 `.tres` 的 11 条 `ext_resource` 全部指向已复制的 `res://scripts/combat/*.gd`，无悬空。

| 段 | 改前 `330/360/320` | 改后 `400/480/420` |
|---|---|---|
| `--import` / `--quit` | `IMPORT_RC=0`(29 行) / `QUIT_RC=0` | `IMPORT_RC=0`(16 行) / `QUIT_RC=0` |
| 检查项汇总 | `E-1/E-3/E-4/E-5/E-8/E-9 检查项 491，错误 3` | `检查项 491，错误 0` |
| E-8 FAIL | 3 条（bleed / poison / frost） | 0 |
| `ERROR:` 行数 | **4**（3 条 FAIL + 1 条「数据表自洽校验失败，错误 3 项」） | **0** |
| `FAIL` / `SCRIPT ERROR` / `Parse Error` | 3 / 0 / 0 | 0 / 0 / 0 |
| `_ready()` 触发标记 | `[R10-RECHECK] CombatDataValidator._ready() 已触发，挂载 3 份 .tres` | 同左 |

结论：`4 条 ERROR → 0`、E-8 三项 FAIL 全部消失；491 项全量跑完 + 触发标记证明 `_ready()` 确实执行
（非未加载假绿）。与 §2.2 / `E8-VERDICT-LOG.md` §7 并发实例结论一致，且为本实例独立复跑。

### 5.4 真跑 B 复核：真实工程根三段门禁（本实例实际 stdout）

工程根 `F:/Game/aierdengfahuan/godot`，引擎 `4.7.2.stable.official.ed1daf0bf`（`G0_RC=0`）：

```
G1 --headless --import              G1_RC=0            (16 行)
G2 --check-only --script 全量 .gd   G2_SCRIPTS=52 G2_FAIL=0
G3 --headless --quit                G3_RC=0
--- 合并日志 ALL_LINES=125，grep 统计 ---
SCRIPT ERROR: 0    Parse Error: 0    ERROR: 行数: 0    WARNING 行数: 1
hides a global: 0    Failed to load: 0
--- ERROR/WARNING 原文 ---
124:WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
```

结论：`52/52 --check-only EXIT=0`、`SCRIPT ERROR=0`、`Parse Error=0`、`ERROR=0`，仅 1 条既有
`ObjectDB leaked` WARNING（非 ERROR、ChunkManager 在途加载时序），与 R9 FINAL 基线一致、无回归。
本实例未复现 §2.3 首轮那 1 条偶发 `user://logs` ERROR，如实记录、不冒充、也不否认其历史登记。

### 5.5 本实例补的缺口 / 未动项 / 未完成项

- **补缺口**：`command_center\ai\2\outbox\` 在本实例开工时为空（并发回执已被中枢即时消费归档，
  见 §4.1），按本任务单「完成标志 2」在 outbox 补写 `receipt_R10_A2.json`（`status=done`，
  `result` 引用本文实际结论），不覆盖并发件、不重做 DONE 主体。
- **未动**：本文 §0~§4 全部既有内容、`E8-VERDICT-LOG.md`、两份 `.tres`（数值已正确，不回退再改）、
  `project.godot` / `scenes\` / 其它工位 / 总线 / 总纲 / 契约 / 台账 / `00-汇总.md`；未自行 git。
- **未完成项**：与 §3 一致（A4/A6 文档回改、validator 落位工程根、`schema` 单复数口径、
  历史 signal / Q1、手感与运行期可见性验收、apk / ComfyUI / 出图 / 仓库推送）—— 只登记不擅改，
  无新增阻塞。
