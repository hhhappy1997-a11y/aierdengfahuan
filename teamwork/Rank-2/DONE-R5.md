# DONE-R5.md —— 2 号工位（战斗系统与数据驱动）R5 完成标志

> HOST 监测只认本文件。本轮 R5 由 HOST 全闭环调度续派，任务单 `cmd-20261109-020321-544-A2`。
> 生成日期 2026-11-09（本机日期）。中文 UTF-8。
> 唯一写入 `Rank-2\` + 中枢回执 `command_center\ai\2\outbox\`（本轮指令的唯一例外）。
> **本轮为「边界收口」**：任务书-R5 §交付清单 4 项经核对均为**待裁决项或超本工位范围项**，
> 只做「不越界、不需裁决」的部分（实际校验输出 / 影响面 / 候选方向登记、I-2 静态核对、
> 三段门禁真跑与如实自检）；**E-8 等项待总指挥裁决，本轮未擅改**。既有交付件零改动；
> 真跑如实保留 E-8 校验产生的 ERROR（非脚本错误），**不冒充全 PASS、不伪造输出**。

---

## 0. 结论速览

- **状态：done（边界收口完成）**。任务书-R5 §交付清单 4 项均按「待裁决 / 超范围」如实登记，
  未擅自改数、改路径、改既有件或接入工程根。
- **三段门禁真跑**：引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`
  （`4.7.2.stable.official.ed1daf0bf`），`--version` / `--headless --import` /
  17 个 `--check-only --script` / `--headless --quit` **全部 EXIT=0**；
  `--import` 注册 15 个 `class_name`。
- **`SCRIPT ERROR` grep**：合并日志 100 行，专项 `grep -nEi "SCRIPT ERROR"` → **0 命中（RC=1）**；
  段 1 + 段 2 宽口径 **0 命中（RC=1）**。**段 3 实跑宽口径 4 条 `ERROR:`**，全部为
  `CombatDataValidator` 的 E-8 数据表自洽校验 FAIL（3 条具体 + 1 条汇总），由 `push_error()`
  产生、backtrace 指向 `core/variant/variant_utility.cpp:1023`，**是既有 `.tres` 数值与 E-8
  口径的真实冲突，不是脚本解析 / 运行时错误**；如实保留，不掩盖、不谎报全 PASS。
- **E-8 实跑结论**：`检查项 491，错误 3`（bleed 380>330 / poison 450>360 / frost 400>320），
  与 `DONE-R2.md` 静态推算、`DONE-R4.md` / `R4-口径与阻塞登记.md` 一致，本轮真跑再次实证。
- **I-2 静态核对**：`boss_controller.gd` / `combat_event_bus.gd` 与 I-2 口径
  （信号名、单 `String` 参数、2 号不写 flag / 不双写、唯一发射点收敛）**一致**；
  历史 `signal` 声明与旧发射点仍在既有 `player_state_machine.gd`，去留**待裁决、本轮未改**。

---

## 1. 实际交付清单（对照 `任务书-R5.md` §交付清单）

| # | 任务书要求 | 性质（经核对） | 本轮实际交付 | 状态 |
|---|---|---|---|---|
| 1 | E-8 数据表校验三项冲突（bleed 380>330 / poison 450>360 / frost 400>320） | **待裁决**（需总指挥定数值） | `R5-待裁决登记.md` §2 实际校验输出、§3 影响面、§4 候选方向（**不选定**） | **已登记；未定数值、未改 `.tres`** |
| 2 | `res://data/schema` vs `res://data/schemas` 路径统一 | **待裁决**（路径口径） | `R5-待裁决登记.md` §6.2 登记差异事实与影响 | **已登记；未改口径、未改 11 条 `ext_resource`** |
| 3 | 历史 signal 去留与 I-2 唯一发射点收敛 | **待裁决**（需改既有件） | `R5-待裁决登记.md` §5 静态核对结论、§6.3 登记现状 | **已核对 / 登记；未改既有 `.gd`** |
| 4 | M5 Boss 控制器接入工程根与手感调校 | **超范围**（工程根不可写；手感不替人判断） | `R5-待裁决登记.md` §6.4 登记超范围与理由 | **未接入（超范围）** |
| — | `DONE-R5.md`：①交付清单 ②自检（含真跑）③未完成项与阻塞 | 完成标志 | 本文件 | **已写** |
| 附 | 中枢回执 JSON（按任务单 id） | 完成标志 | `command_center/ai/2/outbox/receipt_R5_A2.json` | **已写** |

### 1.1 本轮新增 / 改动文件（严格限定在唯一可写范围）

| 文件 | 位置 | 动作 |
|---|---|---|
| `R5-待裁决登记.md` | `Rank-2\` | **新建**（本轮主交付） |
| `DONE-R5.md` | `Rank-2\` | **新建**（本文件） |
| `receipt_R5_A2.json` | `command_center\ai\2\outbox\` | **新建**（回执例外） |

### 1.2 既有件零改动（核对）

`schema/` 8 个 + 平铺 `schema_*.gd` 9 个、`boss_01_margit.tres` /
`enemy_01_limgrave_soldier.tres` / `player_actions.tres`、`combat_resolver.gd` /
`combat_data_validator.gd` / `enemy_director.gd` / `player_state_machine.gd` /
`boss_controller.gd` / `combat_event_bus.gd`、`motion-mapping.md` / `COMBAT-BUILD.md` /
`数据表schema.md` / `接口契约.md` / `README.md` / `DONE-R2.md` / `DONE-R3.md` /
`DONE-R4.md` / `R4-口径与阻塞登记.md` / `任务书*.md` / `调度任务单*.json`
—— **一律未重做、未改写、未改数值、未改路径**。
（真跑临时工程内为这些文件的**复制件**，仅用于引擎验证，不落工位、收尾删除；原件未动。）

---

## 2. 自检（真跑输出结论）

### 2.1 真跑环境（任务书-R5 §真跑要求 / 契约 §10 / 工具链 §4.2）

| 项 | 值 |
|---|---|
| 引擎 | `D:\Godot\Godot_v4.7.2-stable_win64.exe`，`--version` 实测 `4.7.2.stable.official.ed1daf0bf` |
| 临时工程 | 系统临时目录 `C:\Users\62668\AppData\Local\Temp\r5_gate_a2\`（不在 teamwork / 工程根内、不提交、收尾即删） |
| 日志 | `C:\Users\62668\AppData\Local\Temp\r5_gate_a2_logs\`（合并为 `log_all.txt`，100 行） |
| `project.godot` | `config_version=5`，`run/main_scene="res://main.tscn"`，`[autoload] GameEvents="*res://autoload/game_events.gd"`，`physics_ticks_per_second=60` |
| 布局 | `res://data/schemas/*.gd`（9 个）、`res://data/{bosses,enemies,player}/*.tres`（3 份）、`res://scripts/combat/*.gd`（6 个逻辑件）、`res://autoload/game_events.gd`、`res://gate/r5_gate_runner.gd`、`res://main.tscn` |
| 路径口径 | 临时工程按 3 份 `.tres` 现有复数 `ext_resource` 搭建以保证不悬空；**复现既有引用，不构成口径裁决**（§4） |
| 未做 | 未写探针 / 测量 / preflight 脚本落工位；`r5_gate_runner.gd` 是临时工程内运行时验证件，随临时工程删除；零付费 / 零外部依赖；未碰 WSL；未写总线 / 台账 / git |

> 段 3 的 `--quit` 主场景挂载 `r5_gate_runner.gd`，在 `_ready()` 中 `new()` 出
> `CombatDataValidator`、赋值 3 份 `.tres` 后 `add_child()`，从而**真跑**
> `CombatDataValidator._ready()`，复现 E-8 三类异常抗性溢出校验。

### 2.2 三段门禁 · 实际输出结论

| 段 | 命令 | 退出码 | 实际输出结论 |
|---|---|---|---|
| 0 | `... --version` | **0** | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `... --headless --path <gate> --import` | **0** | 36 行；`first_scan_filesystem` 5 步 DONE；`update_scripts_classes (17 steps)` 注册 15 个 `class_name`（9 schema：`BossData/EnemyData/MoveData/PhaseData/PlayerActionData/PlayerActionTable/PoiseConfig/SpawnRequest/StatusBuildup` + 6 逻辑：`BossController/CombatDataValidator/CombatEventBus/CombatResolver/EnemyDirector/PlayerStateMachine`）；`loading_editor_layout` DONE；无 ERROR |
| 2 | `... --headless --path <gate> --check-only --script res://<各 .gd>`（17 个） | **17/17 = 0**（`SEG2_SCRIPTS=17 SEG2_FAIL=0`） | 9 schema + 6 逻辑 + 1 autoload + 1 runner 全部解析通过 |
| 3 | `... --headless --path <gate> --quit` | **0** | 30 行；打开工程、加载 3 份 `.tres`、触发 `CombatDataValidator._ready()` 实跑后退出 |

段 2 的 17 个脚本：`data/schemas/{boss_data,phase_data,move_data,poise_config,status_buildup,enemy_data,player_action_data,player_action_table,spawn_request}.gd`、
`scripts/combat/{combat_resolver,enemy_director,player_state_machine,combat_data_validator,boss_controller,combat_event_bus}.gd`、
`autoload/game_events.gd`、`gate/r5_gate_runner.gd`。

### 2.3 `SCRIPT ERROR` grep 结果（工具链 §4.2：必须 grep，不以退出码冒充通过）

合并 4 段日志为 `log_all.txt`（**100 行**）后执行：

```
grep -nEi "SCRIPT ERROR|Parse Error|ERROR:|Failed|Cannot|dangling|Invalid|not found|Can't" log_all.txt
```

| 范围 | 命中 | 结论 |
|---|---|---|
| `SCRIPT ERROR` **专项**（全 100 行） | **0 命中**（RC=1） | **脚本层零 SCRIPT ERROR / Parse Error** |
| 段 1 `--import` + 段 2 全部 `--check-only` 宽口径 | **0 命中**（RC=1） | 脚本解析与全局类注册零错误 |
| 全日志宽口径 | **4 条 `ERROR:`**（行号 73 / 80 / 87 / 95，全部在段 3） | 见 §2.4 |
| 段 3 `--quit` 实跑宽口径 | **4 条 `ERROR:`**（段 3 内行号 3 / 10 / 17 / 25） | 见 §2.4 |

> **如实说明**：这 4 条是 `push_error()` 输出的**数据表自洽校验 FAIL**，属于既有
> `boss_01_margit.tres` 数值与 E-8 校验式的冲突，**不是 GDScript 解析错误、不是运行时
> `SCRIPT ERROR`、不是本轮新增件引入的偏差**。本轮以 grep 结果分别判定：
> **脚本层 0 命中通过；数据层 E-8 FAIL 如实登记为待裁决，不掩盖、不谎报全 PASS。**

### 2.4 段 3 完整日志原文（E-8 校验 ERROR，如实保留）

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_01_bleed
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ok (res://scripts/combat/combat_data_validator.gd:86)
       [1] _validate_e8 (res://scripts/combat/combat_data_validator.gd:213)
       [2] _ready (res://scripts/combat/combat_data_validator.gd:75)
       [3] _ready (res://gate/r5_gate_runner.gd:13)
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_02_poison
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ok (res://scripts/combat/combat_data_validator.gd:86)
       [1] _validate_e8 (res://scripts/combat/combat_data_validator.gd:213)
       [2] _ready (res://scripts/combat/combat_data_validator.gd:75)
       [3] _ready (res://gate/r5_gate_runner.gd:13)
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_03_frost
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ok (res://scripts/combat/combat_data_validator.gd:86)
       [1] _validate_e8 (res://scripts/combat/combat_data_validator.gd:213)
       [2] _ready (res://scripts/combat/combat_data_validator.gd:75)
       [3] _ready (res://gate/r5_gate_runner.gd:13)
[CombatDataValidator] E-1/E-3/E-4/E-5/E-8/E-9 检查项 491，错误 3
ERROR: [CombatDataValidator] 数据表自洽校验失败，错误 3 项
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/combat/combat_data_validator.gd:79)
       [1] _ready (res://gate/r5_gate_runner.gd:13)
[R5-GATE] CombatDataValidator._ready() 已触发，挂载 3 份 .tres（boss/enemy/player_actions）
```

- E-1 / E-3 / E-4 / E-5 / E-9 **通过**；E-8 **3 项 FAIL**。
- E-8 式 `threshold + resistance_gain_per_trigger × 8 <= max_resistance`：
  bleed `180 + 25×8 = 380 > 330`、poison `210 + 30×8 = 450 > 360`、
  frost `160 + 30×8 = 400 > 320`。与 `DONE-R2.md` §4 第 2 项静态推算、`DONE-R4.md` §2.4
  / `R4-口径与阻塞登记.md` §3.2 一致，本轮真跑再次实证。
- 本轮**不改 `.tres`**（一律不重做）、**不改 validator**（`combat_*.gd` 一律不重做）、
  **不改 E-8 口径**，登记为**待 HOST 裁决**（`R5-待裁决登记.md` §4），不冒充完成。

### 2.5 I-2 口径静态核对（本轮可静态验证的自检，补齐项）

I-2 口径：`00-协作契约.md` §3 / `接口契约.md` §2 —— 2 号发
`enemy_defeated(enemy_id: String)` / `boss_defeated(boss_id: String)`，参数单个 `String`；
2 号不写 flag、不碰 `SaveDelta`、不双写；击杀由唯一发射点处理。

| 核对项 | `boss_controller.gd` | `combat_event_bus.gd` | 结论 |
|---|---|---|---|
| 不定义 I-2 信号 | 模块内信号仅 `phase_changed`/`transition_started`/`transition_finished`/`move_landed`（45-52 行） | 不定义信号，仅 `has_signal`+`emit_signal` 转发（48-51 行） | **一致** |
| 击杀出口 | `_die()`→`_report_defeat(boss_data.id, true)`→`_event_bus.call("report_defeat", …)`（296-309 行） | `report_defeat(defeat_id: String, is_boss: bool)` 唯一对外发射点（42 行） | **一致（收敛链路）** |
| 发射目标 / 参数 | 交 `CombatEventBus`，参数 `boss_data.id` 单 String | `bus.emit_signal(signal_name, defeat_id)` 到 `/root/GameEvents`，单 String（47-51 行） | **一致** |
| 不写 flag / 不双写 | 仅 `_read_world_flag` 读 `get_flag(key, default)`（338-341 行） | 无 flag / SaveDelta 操作；autoload 缺失降级 `push_warning` 且不回退本地信号（44-46 行） | **一致** |
| I-4 单点 | `set_pose` 仅 1 处调用（351 行） | 不涉及 | **一致** |

**静态自检实际输出**（Grep 全仓 `*.gd`）：

| 检查 | 命中 | 结论 |
|---|---|---|
| `^signal (enemy_defeated\|boss_defeated)` | 仅既有 `player_state_machine.gd:29-30`（R2 历史声明） | 两个新增件 0 命中，不另立 I-2 信号 |
| `report_defeat` | 既有 `player_state_machine.gd:304`（旧发射点）+ 新增 `combat_event_bus.gd:42` / `boss_controller.gd:302-307`（新收敛链路） | 唯一发射点收敛链路清晰 |
| `set_flag\|\.defeated` | `set_flag` 实际调用仅既有 `player_state_machine.gd:296-297`（`_write_world_flag`，293 行 `key.ends_with(".defeated")` 硬拦截） | 两个新增件无 `set_flag` 调用，符合 I-2 |
| `^const ` | 全仓仅 2 处既有 `const MIN_DAMAGE: float = 1.0`（`player_state_machine.gd:42`、`combat_resolver.gd:20`） | 两个新增件 0 命中；数值留表里 |

> 差异点：「唯一发射点」由 `接口契约.md` §2.2 原文的 `PlayerStateMachine.report_defeat`
> 收敛为 `CombatEventBus.report_defeat`（R4 既定收敛、既有件零改动），连同历史 signal
> 去留属**待裁决项**（§4 第 3 项），本轮不擅改。

### 2.6 「数值全部留表里」/ 既有件零改动核对

- 全仓 `.gd` 的 `const` 仅既有 2 处 `MIN_DAMAGE`（上表），两个 R4 新增件无 `const`、无本案战斗数值字面量。
- E-8 三组数值仍在 `boss_01_margit.tres` 的 3 个 `StatusBuildup` 子资源内，**本轮未改一个字节**。
- 3 份 `.tres` 的 11 条 `ext_resource` 复数路径**未改**；`任务书-R3.md` / `数据表schema.md` 路径口径**未改**。

---

## 3. 自检汇总

- 三段门禁：**真跑 PASS**（`SEG0/1/3_EXIT=0`、`SEG2_SCRIPTS=17 SEG2_FAIL=0`；命令 / 退出码 / 日志见 §2.2）。
- `SCRIPT ERROR` 专项：**0 命中**；段 1 / 段 2 宽口径：**0 命中**（§2.3）。
- 数据层：**如实保留 E-8 4 条 `ERROR:`（检查项 491、错误 3）**，是既有 `.tres` 数值与 E-8 口径冲突，
  非脚本错误；**脚本层通过、数据层待裁决，不冒充全 PASS**（§2.4）。
- `CombatDataValidator._ready()`：**已真跑**（491 项检查、3 项错误全部 E-8）。
- I-2 静态核对：`boss_controller.gd` / `combat_event_bus.gd` 与 I-2 口径**一致**；
  历史 signal / 旧发射点现状如实登记、待裁决（§2.5）。
- 既有件零改动 / 数值留表里：**全 PASS**（§2.6）。
- 交付件齐全性：任务书 §交付清单 4 项按「待裁决 / 超范围」如实登记 + `R5-待裁决登记.md`
  + `DONE-R5.md` + 回执，全部落地；既有件零改动。

---

## 4. 未完成项与阻塞（诚实标注，**明确标注待裁决项**）

> 本轮为边界收口：以下 1~4 项即任务书-R5 §交付清单 4 项，**均非本轮可自行完成**，
> 逐条标注性质；**均不冒充完成**。

1. **【待总指挥裁决】E-8 三组异常抗性溢出（真跑实证）**：`boss_01_margit.tres` 的
   `bleed / poison / frost` 三组 `max_resistance` 与 `数据表schema.md` §9 E-8 校验式冲突，
   validator `_ready()` 实跑报 `检查项 491，错误 3`（段 3 的 4 条 `ERROR:`）。
   本轮按「不擅改数值 / 不擅改口径」未改 `.tres`、未改 validator、未改 E-8 口径；
   候选方向（改 `max_resistance` / 调 `resistance_sample_triggers` / 修订 E-8 式）
   见 `R5-待裁决登记.md` §4，**未选定**。**集成前必须裁决**，否则 validator 启动即报 3 项错误。
2. **【待总指挥裁决】`res://data/schema`（单数） vs `res://data/schemas`（复数）路径口径**：
   `任务书-R3.md` §2 字面单数，`数据表schema.md` §0.1 / 8 个 schema 头注释 / 3 份 `.tres`
   的 11 条 `ext_resource` 为复数。本轮临时工程按既有复数引用搭建以保不悬空（段 1/段 3
   EXIT=0、无 dangling），**这只是复现既有引用、不是裁决**；未改他人文档、未改 `.tres`。
   若裁决单数需同步改 11 条 `ext_resource` 与头注释，由汇总统一处理。详见 `R5-待裁决登记.md` §6.2。
3. **【待总指挥裁决】历史 signal 去留 / I-2 唯一发射点收敛**：既有
   `player_state_machine.gd:29-30` 仍声明 `signal enemy_defeated` / `signal boss_defeated`、
   `:304-310` 仍保留旧 `report_defeat` 本地 `emit`；R4 新增 `CombatEventBus` 收敛对外发射，
   既有件零改动。删除 / 保留需改既有件，超出本轮「既有件不重做、不擅改」边界，
   **登记待裁决，本轮未改**。详见 `R5-待裁决登记.md` §5 / §6.3。
4. **【超本工位范围】M5 Boss 控制器接入工程根与手感调校**：工程根
   `F:\Game\aierdengfahuan\`（非 `teamwork\Rank-2\`）不在唯一可写范围；
   `boss_controller.gd` 目标路径 `res://scripts/combat/boss_controller.gd` 属工程落地，
   需工程根写入权限；手感调校属「WorkBuddy 不替人做手感与审美判断」（契约 §5）。
   **本轮不接入、不调手感、未在工程根写任何文件**。详见 `R5-待裁决登记.md` §6.4。
5. **【R2/R3 遗留，不阻塞收尾】`rootmotion.json` 无预置实例、未生成本作 clip**：
   `motion-mapping.md` 为字段契约级映射，非真跑产物；`gen3d` / `mia-rig` 本机不可用、
   不补装、不碰 WSL。不冒充已对齐产物。
6. **【R2/R3 遗留，不阻塞收尾】M5 阶段精灵表仅登记不调用**：`PhaseData.sprite_frames_path`
   仍按 Q1 待裁决处理，阶段动画走 `pose_prefix`（`p1_` / `p2_`）零接口扩展；真替换
   `SpriteFrames` 需 1 号新增入口，归总指挥裁决。
7. **【R2/R3 遗留，不阻塞收尾】跨模块待裁决 Q1~Q7**（`README.md` §5）：`WorldState`
   Autoload 名、`frame_index` clamp 责任、pose 名与 4 号 `import.json` 映射、米→px 换算
   系数等仍归总指挥裁决；2 号不改别人文件。
8. **【范围约束】未写总线**：`00-群聊总线.md` 在 teamwork 根目录、超出唯一可写范围，
   本轮 HOST 指令亦明确「不写总线 / 不写总纲 / 契约 / 台账」，故未追加；完成标志以本文件
   + 中枢回执为准。

> 第 1 / 2 / 3 项为**待裁决项**、第 4 项为**超范围项**、第 5~7 项为遗留 / 裁决项、
> 第 8 项为范围约束；**均不阻塞本轮收尾**（4 项按性质如实登记、真跑结论如实记录、
> 阻塞逐条标注），但第 1 项**集成前必须裁决**。
> 无付费 / 外部依赖 / 探针脚本落工位 / git 操作。

---

## 5. 收尾动作

- 本文件 `DONE-R5.md` 已写（HOST 监测标志）；`R5-待裁决登记.md` 已写。
- 中枢回执已写：`command_center\ai\2\outbox\receipt_R5_A2.json`，
  `task_id = cmd-20261109-020321-544-A2`、`ai = 2`、`status = done`，
  `result` 引用本文件实际结论并注明「E-8 等项待总指挥裁决，本轮未擅改」。
  **写入后已被中枢 600ms 轮询回收**至
  `command_center\dispatcher\receipts\receipt_R5_A2.json`（`json.load` 复核合法、
  `result` 1310 字，含「E-8 等项待总指挥裁决，本轮未擅改」与 `DONE-R5.md` 引用），
  `ai\2\status.json` 转 `idle / completed=4`、`last_seen 02:17:55`；
  **`outbox` 现为空是中枢回收后的正常终态，非回执丢失**（与 `DONE-R4.md` §5 同）。
- 系统临时工程 `C:\Users\62668\AppData\Local\Temp\r5_gate_a2\` 与日志
  `C:\Users\62668\AppData\Local\Temp\r5_gate_a2_logs\` 不落 teamwork / 工程根、不提交，
  **收尾时清理删除**；真跑日志（`log_all.txt` 等）随临时工程删除，结论已抄录进本文件 §2
  与 `R5-待裁决登记.md` §2。
- 既有 `schema/`、`*.tres`、`combat_*.gd`、`boss_controller.gd`、`combat_event_bus.gd`、
  `player_state_machine.gd`、`motion-mapping.md`、`接口契约.md` 等一律未重做、未改动、
  **未改数值、未改路径口径**。
- 未写总线 / 台账 / 总纲 / 契约 / git；未自行 commit / push；零付费 / 零外部依赖；
  未写探针 / 测量 / preflight 脚本落工位；开工必读只读一次；中文 UTF-8；Godot 4 合法语法。
