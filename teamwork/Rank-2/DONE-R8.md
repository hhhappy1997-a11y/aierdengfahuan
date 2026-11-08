# DONE-R8.md —— Rank-2（战斗系统与数据驱动）R8 执行 SpawnRequest 裁决

> 2 号工位 · R8 完成标志（任务书 `任务书-R8.md` / 调度任务单 `cmd-20261109-030933-291-A2`，
> HOST 派单与裁决见 `00-群聊总线.md` MSG-20261109-0309-HOST）。
> 唯一可写：`teamwork\Rank-2\`、`godot\scripts\combat\`、`godot\data\combat\`；
> 回执例外 `command_center\ai\2\outbox\`。**不写 `godot\project.godot`（Rank-1 独占）、
> `godot\scripts\rpg\`（Rank-3 权威件）、其它工位 / 子目录**、总线 / 总纲 / 契约 / 台账；
> 不自行 git commit / push；不覆盖既有交付件（本轮仅对 1 个既有落位件做裁决授权的 1 行级改动）。
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（`--version` 实测
> `4.7.2.stable.official.ed1daf0bf`，EXIT=0）。
> 本文所有数字 / 输出均来自本轮本机 Godot 4.7.2 实际输出与机器化核对（门禁时间戳
> `2026-11-09 03:19:20 ~ 03:19:36 +0800`），不引用旧结论冒充、不伪造、不冒充全绿。中文 UTF-8。

---

## 0. 结论速览

| 交付项 | 状态 | 实际结论 |
|---|---|---|
| ① 消除重复全局类注册 | **完成** | 选「去掉 `class_name`」方案；`godot\scripts\combat\spawn_request.gd:2` 的 `class_name SpawnRequest` 改为 3 行裁决注释；全工程 `class_name SpawnRequest` 声明语句剩 **1 处**（`scripts/rpg/spawn_request.gd:2` 权威件，未改） |
| ② 修正所有引用其的 `.tres`/`.gd` ext 路径，战斗层无悬空引用 | **完成（核对结论：0 处需修正）** | 全量 grep 实证：工程根 `.tres` 中指向 `scripts/combat/spawn_request.gd` 的 `ext_resource` **0 条**、代码级强类型引用 **0 命中**；唯一引用 SpawnRequest 资源的 `.tres` 已正确指向权威件。真跑门禁 `dangling/not found/Failed to load` 全 0 |
| ③ `godot\` 全量门禁复跑 | **完成** | 三段 RC 全 0、51 个 `.gd` `SEG2_FAIL=0`；`Class "SpawnRequest" hides a global script class` **消失（计数 0）**、`SCRIPT ERROR`/`ERROR` 全 0；战斗层零新增 ERROR |
| ④ E-8 数值冲突 | **只登记、不擅改** | 三组数值与 R7 登记逐字一致、零改动 |
| `DONE-R8.md` / 回执 | **完成** | 本文件 + `cmd-20261109-030933-291-A2.json` 写入 `teamwork\command_center\ai\2\outbox\` |

**不冒充全绿**：本轮门禁 `ERROR=0`，但仍有 1 条跨工位/引擎退出时序
`WARNING: 2 ObjectDB instances were leaked at exit`；E-8 数据层冲突与其余待裁决项仍在；
段 3 只做加载门禁、未做渲染 / 运行时验收。跨工位并行时序（`.gd` 50→51）如实登记于 §4.4。

完成标志：`status=done`，回执 `task_id=cmd-20261109-030933-291-A2`。

---

## 1. 实际交付清单

### 1.1 改动文件（共 3 个：1 改 + 2 新建）

| # | 文件 | 落位 / 性质 | 说明 |
|---|---|---|---|
| 1 | `godot\scripts\combat\spawn_request.gd` | 战斗层 **改动**（唯一代码改动） | 第 2 行 `class_name SpawnRequest` → 3 行 R8 裁决注释（去除重复全局类注册）；4008 B → 4315 B；其余 62 行（含 17 字段 `@export`）逐字不动。Godot 4 合法（`extends Resource` 无 `class_name`） |
| 2 | `teamwork\Rank-2\DONE-R8.md` | 工位（新建，本文件） | ①实际交付清单 ②自检含真跑实际输出结论 ③未完成项与阻塞 |
| 3 | `teamwork\command_center\ai\2\outbox\cmd-20261109-030933-291-A2.json` | 回执例外（新建） | 完成回执 JSON |

### 1.2 明确未改动（机器化核对）

- `godot\scripts\rpg\spawn_request.gd`（**I-3 唯一权威件**）：2015 B，`class_name SpawnRequest` 与 17 字段**零改动、只读核对**。
- `godot\data\combat\` 3 份 `.tres`：11 条 `ext_resource` 与全部数值字段**零改动**（E-8 三组数值见 §5）。
- `godot\data\rpg\spawn_bellvault_elite_01.tres`（Rank-3 范围）：`ext_resource path="res://scripts/rpg/spawn_request.gd"` 与 `script_class="SpawnRequest"` **零改动、只读核对**；该文件在 Rank-3 可写范围外，2 号不写。
- `godot\scripts\combat\` 其余 12 个 `.gd`、全部 `.gd.uid`（引擎伴随文件）：零改动。
- `godot\project.godot`（Rank-1 独占）、`godot\scenes\`、Rank-1/3/4 子目录：零改动、只读引用。
- 工位既有交付件（`schema\spawn_request.gd` / `schema_spawn_request.gd` / `enemy_director.gd` / `COMBAT-ASSEMBLY.md` / `DONE-R*.md` / `I2-WIRING.md` / 3 份工位 `.tres` 等）：**零改动**（既有件不重做、待裁决只登记）。
- 总线 / 总纲 / 契约 / 台账：零改动；未自行 git commit / push；零付费 / 零外部依赖。

---

## 2. 交付项 ①：消除重复全局类注册

### 2.1 二选一决策：**去掉 `class_name`（不改名 `CombatSpawnRequestRef`）**

依据（写清楚）：

1. **契约 I-3 + 总指挥裁决（唯一真源）**：`00-协作契约.md` §3 I-3「3 号通过 `SpawnRequest` 资源传入敌人/精英配置，2 号消费」；`00-群聊总线.md` MSG-20261109-0309-HOST 明文「裁定 `godot\scripts\rpg\spawn_request.gd` 为唯一权威件；`godot\scripts\combat\spawn_request.gd` 须移除重复 `class_name` 注册」；`任务书-R8.md` §交付清单同口径。`SpawnRequest` 定义权归 3 号，2 号不得注册同名全局类。
2. **被改文件自身头注释即如此声明**：原 `spawn_request.gd:14-16`「3 号实现路径：`res://scripts/rpg/spawn_request.gd`（同名全局类）。落完整工程时 2 号**不重复挂载本文件**，以免 `class_name SpawnRequest` 重复注册；本文件只在 2 号独立临时工程内用于字段对齐与真跑核对……」——去掉 `class_name` 与该声明、与 `GATE-REPORT-R8.md` §4.3 裁决建议（「保留 rpg 权威件；由 Rank-2 把 combat 件去掉 `class_name` / 移除 / 迁走」）完全一致。
3. **静态核对：工程根无任何 ext 路径 / 强类型引用指向 2 号文件**（§3）：去掉注册不产生任何悬空引用；而改名 `CombatSpawnRequestRef` 会新增一个全工程（含工位未来落位件）**无任何消费者**的全局类，语义不符且非必要。
4. **最小改动 + 不引入新全局类**：仅把 1 行 `class_name` 换为 3 行裁决注释，`extends Resource` 无 `class_name` 为 Godot 4 合法语法；文件与 17 字段规格完整保留，作为 2 号消费侧对照规格件。

### 2.2 改动明细（逐字）

改动前（`godot\scripts\combat\spawn_request.gd:1-2`）：
```gdscript
extends Resource
class_name SpawnRequest
```
改动后（`:1-4`）：
```gdscript
extends Resource
## [R8 裁决 · MSG-20261109-0309-HOST] 去除重复的 class_name SpawnRequest 全局类注册。
## 按契约 I-3，SpawnRequest 唯一权威件 = res://scripts/rpg/spawn_request.gd（Rank-3 定义）。
## 本文件保留为 2 号消费侧 17 字段对照规格件，不注册全局类；工程根无 ext_resource 引用它。
```
其余 62 行（含 17 个 `@export` 字段、历史头注释）**逐字不动**。

### 2.3 消除结果（grep 实证）

| 核对 | 口径 | 结果 |
|---|---|---|
| 全局类声明唯一性 | `grep "^class_name SpawnRequest"` 全 `godot\` | **仅 1 处**：`scripts/rpg/spawn_request.gd:2`（权威件）；2 号文件内 2 处 `SpawnRequest` 字样均为注释文字 |
| 重复注册消除 | 2 号文件内 `class_name` 语句 | **无声明语句**（仅裁决注释 / 历史注释） |
| 单件解析 | `--check-only --script res://scripts/combat/spawn_request.gd` 与 `.../rpg/spawn_request.gd` | 各 `rc=0`（输出仅 Godot 版本横幅，无错误） |

---

## 3. 交付项 ②：ext 路径修正与「战斗层无悬空引用」核对

### 3.1 全量 grep 静态核对结论：**0 处 ext 路径需修正**

裁决要求「修正所有引用其的 `.tres`/`.gd` ext 路径」。本轮对 `godot\` 全量核对后，**实际不存在指向被消除 `class_name` 的 2 号文件的 ext 路径**，故 0 处需修正（如实登记，不伪造「改了 N 处」）：

| # | 核对项 | grep 证据 | 结论 |
|---|---|---|---|
| 1 | 工程根 `.tres` 的 `ext_resource` 指向 `scripts/combat/spawn_request.gd` | 全 `godot\` 下所有 `.tres` 的 `ext_resource` 逐条核对 | **0 条** |
| 2 | 战斗层 3 份 `.tres` 的 11 条 ext | 全部指向 `scripts/combat/{boss_data,phase_data,move_data,poise_config,status_buildup,enemy_data,player_action_data,player_action_table}.gd` | **无一指向 spawn_request.gd**；去掉 class_name 不影响这 11 条 |
| 3 | 代码级强类型 / 加载引用 | `SpawnRequest.new` / `: SpawnRequest` / `as/is SpawnRequest` / `preload\|load(...spawn...)` 全 `godot\` | **0 命中** |
| 4 | 唯一引用 SpawnRequest 资源的 `.tres` | `godot\data\rpg\spawn_bellvault_elite_01.tres:1` `script_class="SpawnRequest"`、`:3` `ext_resource path="res://scripts/rpg/spawn_request.gd"` | **已正确指向 I-3 权威件**；属 Rank-3 `data\rpg\` 范围，2 号不写、无需改 |
| 5 | `.gd` 中 `SpawnRequest` 字样 | `boss_controller.gd:30-31,355`、`dungeon_definition.gd:12` | 全部为**注释文字**（I-3 定义权说明 / 字段说明），非代码引用 |

> 附：工位 `Rank-2\schema\spawn_request.gd`、`schema_spawn_request.gd` 仍声明 `class_name SpawnRequest`，
> `enemy_director.gd:53/79/89` 仍有 `request: SpawnRequest` 强类型注解，但三者**均不在 Godot 工程根
> `godot\` 扫描范围、不参与门禁**（`COMBAT-ASSEMBLY.md` §6.7 已登记未落位工程根）。按「既有件不重做、
> 待裁决项只登记不擅改」本轮未动，如实登记于 §7.2；若后续落位工程根，消费侧 `SpawnRequest` 引用会解析到
> 3 号权威件（符合 I-3），届时按同一裁决去掉这 2 个规格件的 `class_name` 即可。

### 3.2 真跑验证「无悬空引用」

- 段 1 `--headless --path godot --import`：`first_scan_filesystem` 5 步 DONE（含「正在加载全局类名」）、
  `loading_editor_layout` DONE，合并日志 `dangling` / `not found` / `Failed to load` **全 0**（§4.2）。
- 段 3 `--headless --path godot --quit`：加载 `Main.tscn` + 5 个 autoload；链路
  `WorldState._ready()` → `_register_baseline()` 加载 `res://data/rpg/spawn_bellvault_elite_01.tres`
  （`GATE-REPORT-R8.md` §4 已定位）本轮**无任何 `SCRIPT ERROR` / `Parse Error` / `Failed to load`**——
  证明该 `.tres` 的 `script_class="SpawnRequest"` 经 ext 正确解析到权威件、战斗层无悬空引用。
- 段 2：51 个 `.gd` 全 `--check-only` EXIT=0（§4.2）。

---

## 4. 交付项 ③：`godot\` 全量门禁复跑（真实工程根）

### 4.1 四段门禁实际输出

> 方式：任务书 §真跑要求「三段门禁」+ 本项「对 `godot\` 全工程门禁复跑」→ 在**真实工程根**
> `F:\Game\aierdengfahuan\godot` 执行（与 R7 口径一致）。`--import` 更新的是已存在的
> `godot\.godot\` 引擎缓存（`.gitignore` 排除、非 2 号交付件），未覆盖任何源码 / 既有文件。
> 日志留存 `C:\Users\62668\AppData\Local\Temp\r8_gate_a2\`（收尾已删，§8）。

| 段 | 命令 | 退出码 | 实际输出 |
|---|---|---|---|
| 0 | `Godot_v4.7.2-stable_win64.exe --version` | **0** | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `--headless --path godot --import` | **0** | `first_scan_filesystem` 5 步 DONE（含「正在加载全局类名」）、`loading_editor_layout` DONE；日志无 `SpawnRequest` / `hides a global` / 冲突字样 |
| 2 | `--check-only --script`（全工程 **51 个 `.gd`**） | `SEG2_SCRIPTS=51 SEG2_FAIL=0` | 51 个脚本全部解析通过；段 2 合并日志仅 102 行 Godot 版本横幅（51×2），无解析错误 |
| 3 | `--headless --path godot --quit` | **0** | 打开工程、加载 `Main.tscn` + autoload 后退出；输出仅 1 条 `WARNING: 2 ObjectDB instances were leaked at exit` |

门禁时间戳：`GATE_TS_START=2026-11-09 03:19:20 +0800` → `GATE_TS_END=2026-11-09 03:19:36 +0800`（耗时 17s）。

段 3 逐字原文（`seg3.log`，如实保留）：
```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

### 4.2 grep 与机器化核对（合并 4 段日志 `all.log` **123 行**）

| 检查 | 结果 |
|---|---|
| `Class "SpawnRequest" hides a global script class` | **0 命中（消失）** ← 裁决目标 |
| `SCRIPT ERROR` 专项 | **0** |
| `Parse Error` | **0** |
| `ERROR:` / 宽口径 `ERROR` | **0 / 0** |
| `Failed to load` / `dangling` / `not found` | **0 / 0 / 0** |
| `WARNING:` / `leaked` | **1 / 1**（唯一 1 条，见 §4.4） |
| 段 0/1/3 退出码 | `SEG0_RC=0` / `SEG1_RC=0` / `SEG3_RC=0` |
| 单件 check-only（combat / rpg 两个 spawn_request.gd） | 各 `rc=0` |

合并日志唯一告警行（`all.log:122`）：
```
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
```

### 4.3 与 R8 基线对比（基线为历史记录，非本轮输出，仅作对照）

`Rank-1\GATE-REPORT-R8.md` §2/§6 登记的 R8 final 基线：`50 个 .gd / FAIL=1`、`SCRIPT ERROR=2`、
`Parse Error=2`、`ERROR=4`（4 行全为 `SpawnRequest` 同名全局类冲突，2 个错误事件在段 2/段 3 各一次）、
`WARNING=1`（ObjectDB leaked）。本轮改后实测：`51 个 .gd / FAIL=0`、`SCRIPT ERROR=0`、
`Parse Error=0`、`ERROR=0`、`hides a global script class=0`、`WARNING=1`。
**裁决预期（`GATE-REPORT-R8.md` §4.3「4 行消失 → ERROR=0」）达成**；段 2 唯一 FAIL 件
`res://scripts/rpg/spawn_request.gd` 已恢复 EXIT=0。

### 4.4 跨工位并行时序与 WARNING **如实登记（不冒充全绿）**

1. **并行时序（数量差异）**：R8 final 时点全工程 `.gd` = **50**，本轮门禁时点 = **51**
   （`SEG2_SCRIPTS=51`），差 1 件来自四路工位并行写入同一工程根（R8 各路仍在并行）。按「默认不刺探」
   本轮**未逐一追查该件归属**，只登记数量差异；门禁窗口内 `ERROR=0`，**未出现因并行时序产生的 ERROR**。
2. **唯一 WARNING**：`WARNING: 2 ObjectDB instances were leaked at exit`（`all.log:122`；段 3
   `core/object/object.cpp:2536 cleanup`）。`GATE-REPORT-R8.md` §5 已定位为 ChunkManager 在途
   `load_threaded_request` 遇 `--headless --quit` 立即退出时的 `RefCounted` 残留，`DONE-R7.md` §5.3 亦
   登记为跨工位 / 引擎时序告警；**WARNING 级、非 `ERROR`、非 `SCRIPT ERROR`、不改退出码（段 3 EXIT=0）**，
   2 号不越界修复。
3. **不冒充全绿**：`ERROR=0` 仅指脚本 / 加载 / 解析层。仍有 1 条跨工位时序 WARNING；E-8 数据自洽
   冲突仍在（§5，validator 未落位工程根，门禁日志无 E-8 字样 ≠ 已解决）；其余待裁决项见 §7；
   段 3 只做 `--headless --quit` 加载门禁，**未做渲染 / 运行时 / 手感验收**（契约 §5）。
4. **战斗层零新增 ERROR**：本轮战斗层仅改 1 个既有件（`scripts/combat/spawn_request.gd`，去掉 1 行
   `class_name`），未新增任何战斗层文件；51 个 `.gd` 全 EXIT=0、`dangling/not found/Failed to load` 全 0，
   现存 1 条 WARNING 与战斗层无引用关系。→ **战斗层零新增 ERROR 成立**。

---

## 5. 交付项 ④：E-8 数值冲突 · 只登记、不擅改

沿用 `R5-待裁决登记.md` / `COMBAT-ASSEMBLY.md` §5 / `DONE-R7.md` §4 的处置口径：
MSG-20261109-0223-HOST / 0249-HOST / 0309-HOST 均「待裁决项只登记不擅改」，
`00-协作契约.md` §7「跨模块需求冲突 → 只写进待裁决，任何执行 AI 不得自行修改」。
本轮无新的总指挥数值裁决，**继续只登记、不擅改**。

`godot\data\combat\boss_01_margit.tres` 三组数值实测（本轮 grep 原文）：
```
:39 threshold = 180.0   :49 resistance_gain_per_trigger = 25.0   :50 max_resistance = 330.0
:56 threshold = 210.0   :66 resistance_gain_per_trigger = 30.0   :67 max_resistance = 360.0
:73 threshold = 160.0   :83 resistance_gain_per_trigger = 30.0   :84 max_resistance = 320.0
```
与 `DONE-R7.md` §4.3 登记的 `180/25/330`、`210/30/360`、`160/30/320` **逐字一致、数值行差异=0**；
未改任何 `.tres` 数值、未改 `combat_data_validator.gd` 的 `@export` 默认值、未改 `数据表schema.md` §9 口径。
`CombatDataValidator` 未落位工程根（`COMBAT-ASSEMBLY.md` §6.7），故本轮门禁日志 grep `E-8` **0 命中**，
**不代表 E-8 已解决**；落位 validator 后数据层 3 项 FAIL 会随启动持续出现。A/B/C 三方向
（改 3 组 `max_resistance` / 调小 `resistance_sample_triggers` / 修订 E-8 校验式）
**一律不选定、不排序、不推荐、不实施**。

---

## 6. 自检汇总（真跑实际输出结论）

| 层 | 结论 |
|---|---|
| 重复全局类注册 | **消除**：`^class_name SpawnRequest` 全工程仅 1 处（rpg 权威件）；2 号件改后 `--check-only` rc=0 |
| ext 路径 / 悬空引用 | **0 处需修正**（grep 实证）；真跑 `dangling/not found/Failed to load` 全 0、段 3 加载 `.tres` 无报错 |
| 段 0/1/2/3 退出码 | **全 0**；`SEG2_SCRIPTS=51 SEG2_FAIL=0` |
| `hides a global script class` | **0（消失）**；`SCRIPT ERROR=0`、`Parse Error=0`、`ERROR=0`、`Failed to load=0` |
| 战斗层 | **零新增 ERROR**（仅 1 个既有件去掉 1 行 class_name，全 51 件解析通过） |
| 全工程整体 | **非「全绿」**：`ERROR=0` 但 1 条跨工位/引擎 `WARNING: 2 ObjectDB instances were leaked at exit`；E-8 与其余待裁决项仍在；`.gd` 50→51 并行时序如实登记 |
| E-8 数值 | **零改动**（数值行差异=0）；继续登记待裁决 |
| 边界 | 未写 `project.godot` / `scripts/rpg` 权威件 / 总线 / 总纲 / 契约 / 台账 / 其它工位；未覆盖既有交付件；未自行 git；零付费 / 零外部依赖 |

---

## 7. 未完成项与阻塞

> 以下均为「需总指挥裁决 / 跨工位集成 / 超本工位范围」项，**均不阻塞本轮收尾**。

1. **E-8 三项数值冲突**：继续只登记（§5）；需总指挥给出明确数值 / 口径后由后续轮次执行；
   未落位的 `CombatDataValidator` 落位后会稳定复现 4 条 `ERROR:`。
2. **工位内 2 个 `class_name SpawnRequest` 规格件 / `enemy_director.gd` 强类型引用**：
   `Rank-2\schema\spawn_request.gd`、`Rank-2\schema_spawn_request.gd`、`Rank-2\enemy_director.gd:53/79/89`
   仍含同名类声明 / `SpawnRequest` 引用，但**不在工程根扫描范围、不参与门禁**（§6.7 未落位）。
   按「既有件不重做、待裁决只登记」本轮未动；若后续落位工程根，须按同一裁决去掉这 2 个规格件的
   `class_name`（消费侧引用会解析到 3 号权威件，符合 I-3）。**登记待后续轮次裁决，非本轮遗漏**。
3. **`res://data/schema`（单数） vs `schemas`（复数）口径**：`COMBAT-ASSEMBLY.md` §6.2 登记，
   裁决归总指挥；本轮未改脚本头注释 / 任务书 / 口径文档。
4. **历史 signal 去留 / I-2 唯一发射点收敛注释口径**：`COMBAT-ASSEMBLY.md` §6.3 登记，需改既有件注释，
   超「既有件不重做」边界。
5. **战斗层既有件未落位工程根**：`combat_data_validator.gd` / `enemy_director.gd` /
   `player_state_machine.gd` 仍在 `Rank-2\`（§6.7），是否落位待后续轮次裁决。
6. **`SaveSystem` autoload 占位件**：`project.godot:45` 指向 Rank-1 装配占位
   `res://scripts/world/save_system.gd`，真实存档实现按 I-1 归 3 号，2 号不越界。
7. **ObjectDB leaked / ChunkManager 时序 WARNING**：跨工位 / 引擎行为（§4.4），2 号不越界修复。
8. **M5 手感调校 / 渲染与运行时验收**：契约 §5「WorkBuddy 不替人做手感与审美判断」；本轮只做
   语法 / 加载门禁，**不宣称已渲染可见**、不调手感。

---

## 8. 收尾口径

- 本轮改动：`godot\scripts\combat\spawn_request.gd`（1 行级裁决改动）；新建 `teamwork\Rank-2\DONE-R8.md`、
  `teamwork\command_center\ai\2\outbox\cmd-20261109-030933-291-A2.json`。**其余既有件零改动、零覆盖**。
- 门禁日志 `C:\Users\62668\AppData\Local\Temp\r8_gate_a2\`（`seg0~3.log` / `seg2_*.log` /
  `seg2_all.log` / `all.log` / `scripts.txt` / `probe_o.txt`）在系统临时目录、不落工程根 / 工位 / 不提交，
  结论已抄录进本文件，**收尾已删除**（复查确认目录不存在）。
- 全工程门禁在真实 `godot\` 工程根按任务书要求复跑；`hides a global script class` 消失、
  `SCRIPT ERROR`/`ERROR` 全 0、战斗层零新增 ERROR；跨工位并行时序（`.gd` 50→51）与 1 条
  ObjectDB leaked WARNING 逐条如实登记，**不冒充全绿、不伪造输出**。
- 回执路径解析：任务书字面 `command_center\ai\2\outbox\`，工程根下无 `command_center\`；
  中枢真实空间为 `teamwork\command_center\`（沿用 `COMBAT-ASSEMBLY.md` §1 / `DONE-R7.md` §8 口径），
  回执写入 `teamwork\command_center\ai\2\outbox\`，未在根下另建目录（避免越界写与双份回执）。
- **回执流转（如实登记）**：回执 `{"task_id":"cmd-20261109-030933-291-A2","ai":2,"status":"done",...}`
  写入 `teamwork\command_center\ai\2\outbox\` 后被中枢即时轮询消费，归档于
  `teamwork\command_center\dispatcher\receipts\cmd-20261109-030933-291-A2.json`（2151 B）；
  实跑复核 `python json.load` 解析通过（`task_id` / `ai=2` / `status=done` / `result` 1329 字），
  `ai\2\status.json` 实测 `state=idle / completed=9 / last_seen 2026-11-09 03:24:10`
  （R7 收尾为 `completed=8`，本轮 +1）。`outbox\` 因中枢消费再度为空属 `DONE-R6.md` §8 /
  `DONE-R7.md` §8 已记录的正常现象，**回执已生效、不重复补写**；该归档件由中枢生成，
  不在 2 号可写范围，未删除、未改动。
- 零付费 / 零外部依赖；未写总线 / 总纲 / 契约 / 台账；未自行 commit / push；中文 UTF-8；
  Godot 4 合法语法；开工必读只读一次；待裁决项一律**未擅改、未选定、未伪造输出**。
