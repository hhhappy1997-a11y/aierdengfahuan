# DONE-R4.md —— 2 号工位（战斗系统与数据驱动）R4 完成标志

> HOST 监测只认本文件。**R4 由 HOST 全闭环调度兜底循环启动**（每小时自动化 01:36 未触发，
> 本轮按任务单 `cmd-20261109-013419-323-A2` 执行）。生成日期：2026-11-09（本机日期）。中文 UTF-8。
> 唯一写入：`Rank-2\` + 中枢回执 `command_center\ai\2\outbox\`（本轮指令的唯一例外）。
> **本轮指令明确「不写总线」**，故未追加 `00-群聊总线.md`（该文件在 teamwork 根目录、超出唯一可写范围），如实登记。
> R2/R3 已产出的 `schema/`、`*.tres`、`combat_*.gd`、`enemy_director.gd`、`player_state_machine.gd`、
> `motion-mapping.md`、`COMBAT-BUILD.md` 等**一律不重做、未改动（既有件零改动）**，只补齐本轮新增 / 缺失项。

---

## 0. 结论速览

- **状态：完成（done）**。任务书-R4.md §交付清单 4 项全部落地，另写 `R4-口径与阻塞登记.md`
  （路径差异登记）、`DONE-R4.md`（本文件）与中枢回执。
- **三段门禁真跑 PASS**：引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`
  （`4.7.2.stable.official.ed1daf0bf`），`--version` / `--headless --import` /
  17 个 `--check-only --script` / `--headless --quit` **全部 EXIT=0**；
  `--import` 注册 15 个 `class_name`（含本轮新增 `BossController` / `CombatEventBus`）。
- **`SCRIPT ERROR` grep**：合并日志 304 行，`grep -nEi "SCRIPT ERROR"` → **0 命中**（RC=1）；
  段 1 `+` 段 2 宽口径 **0 命中**。**段 3 实跑宽口径 4 条 `ERROR:` 命中**，全部为
  `CombatDataValidator` 的 E-8 数据表自洽校验 FAIL（3 条具体 + 1 条汇总），
  是既有 `.tres` 数值与 E-8 口径的真实冲突，**不是脚本解析 / 运行时错误**；如实记录，不掩盖。
- **`combat_data_validator._ready()` 已实跑**（R2/R3 只做 `--check-only` 解析、未挂载触发）：
  输出 `检查项 491，错误 3`，E-8 三组异常抗性溢出（与 `DONE-R2.md` §4 第 2 项静态推算吻合），
  本轮由真跑实证，登记为待 HOST 裁决，不冒充完成。
- **M5 Boss 控制器实跑**：P1（`phase_index=1` / `pose_prefix=p1_` / 2 招）→ 按数据表阈值切
  P2（`phase_index=2` / `pose_prefix=p2_` / 3 招），过渡 48 帧，加权抽取命中
  `dagger_slash` / `staff_slam` / `holy_hammer` 三招（`total=5.60`），击杀经 I-2 发出。
- **I-2 改挂实跑**：`/root/GameEvents` autoload 收到 **3 条**单 `String` 击杀信号，2 号未写 flag。
- **「数值留表里」**：全仓 `.gd` 的 `const` 仅既有 2 处 `MIN_DAMAGE: float = 1.0`；
  本轮 2 个新增件无 `const`、无本案战斗数值字面量（仅 0.0 / 0.5 / -1.0 / 1.0 归零、几何、数学常量）。

---

## 1. 实际交付清单（对照 `任务书-R4.md` §交付清单）

| # | 任务书要求 | 实际文件 | 状态 |
|---|---|---|---|
| 1 | M5 Boss 控制器：数据驱动二阶段 + 2~3 招式实跑 | `boss_controller.gd`（本轮新建） | **已交付 + 已真跑** |
| 2 | I-2 信号改挂 `GameEvents` autoload（R2/R3 登记偏差） | `combat_event_bus.gd`（本轮新建） | **已交付 + 已真跑** |
| 3 | `combat_data_validator._ready()` 实跑 | 既有 `combat_data_validator.gd`（**未改动**）+ 临时工程运行时挂载件 | **已实跑**（结论见 §2.4） |
| 4 | `res://data/schema` vs `res://data/schemas` 路径待裁决项登记 | `R4-口径与阻塞登记.md`（本轮新建） | **已登记** |
| — | `DONE-R4.md`：① 交付清单 ② 自检结果（含真跑）③ 未完成项与阻塞 | 本文件 | **本轮新建** |
| 附 | 中枢回执 JSON（按任务单 id） | `command_center/ai/2/outbox/receipt_R4_A2.json` | **本轮新建** |

### 1.1 交付件 1 `boss_controller.gd`（M5 Boss 控制器）

- `class_name BossController`，`extends Node`；数值全部来自 `BossData` / `PhaseData` /
  `MoveData` / `PoiseConfig` 资源字段（3 份 `.tres`），本文件零战斗数值硬编码。
- 二阶段：`phase_thresholds` 为唯一阈值真源，HP 比例低于阈值且 `phase_transition_enabled`
  时进 `PhaseTransition`；只换资源引用与运行时数值（`pose_prefix` `p1_`→`p2_`、
  `moves` 表、伤害 / 防御 / 韧性 / 抗性 / `aggression`），不换场景、不 `queue_free` 整个节点；
  过渡帧数与免伤来自 `transition_frames` / `transition_invulnerable`；
  招式判定帧内命中先挂起 `_pending_phase`（`战斗系统设计.md` §6.2 公平性约束）。
- 招式：当前阶段 `moves` 按 `weight` 加权抽取（`rng_seed` 播种），过滤 `min/max_range_px`
  与 `cooldown`；`startup → active → recovery` 三段帧推进，`active` 区间发模块内
  `move_landed`（带 `MoveData`）交 `CombatResolver` 结算。
- 数值实例：`boss_01_margit.tres` 的 P1 2 招（`dagger_slash` / `staff_slam`）、
  P2 3 招（+ `holy_hammer`），正好覆盖任务书「2~3 招式」，招式数量由表决定、代码不写死。

### 1.2 交付件 2 `combat_event_bus.gd`（I-2 改挂）

- `class_name CombatEventBus`，`extends Node`；按「既有交付件不重做、只补齐新增 / 缺失项」，
  **不改 `player_state_machine.gd` 一行**，新增本件作为 2 号唯一 I-2 对外发射点：
  `report_defeat(defeat_id: String, is_boss: bool)` 直接 `emit_signal` 到
  `/root/GameEvents` autoload 的 `enemy_defeated` / `boss_defeated`（参数单个 `String`）。
- 本节点不定义 I-2 信号、不写 flag、不碰 SaveDelta、不双写；autoload 缺失时降级
  `push_warning` 且不回退本地信号。提供 `bind_director()` 供集成层一根线接
  `EnemyDirector.target_defeated`。收敛方式与接线契约详见 `R4-口径与阻塞登记.md` §2。

### 1.3 既有件零改动（核对）

`schema/*.gd`（8 个）+ 平铺 `schema_*.gd`（9 个）、`boss_01_margit.tres` /
`enemy_01_limgrave_soldier.tres` / `player_actions.tres`、`combat_resolver.gd` /
`combat_data_validator.gd` / `enemy_director.gd` / `player_state_machine.gd`、
`motion-mapping.md` / `COMBAT-BUILD.md` / `数据表schema.md` / `接口契约.md` /
`README.md` / `DONE-R2.md` / `DONE-R3.md` / `任务书*.md` / `调度任务单*.json`
—— **一律未重做、未改写**。本轮只新增 4 个工位文件（含本文件）+ 1 个回执。

---

## 2. 自检结果（含真跑输出结论）

### 2.1 真跑环境（任务书-R4 §真跑要求 / 契约 §10 / 工具链 §4.2）

| 项 | 值 |
|---|---|
| 引擎 | `D:\Godot\Godot_v4.7.2-stable_win64.exe`，`--version` 实测 `4.7.2.stable.official.ed1daf0bf` |
| 临时工程 | 系统临时目录 `C:\Users\62668\AppData\Local\Temp\r4_gate_a2\`（不在 teamwork 内、不提交、收尾即删） |
| `project.godot` | `config_version=5`，`run/main_scene="res://main.tscn"`，`[autoload] GameEvents="*res://autoload/game_events.gd"`，`physics_ticks_per_second=60` |
| 布局 | `res://data/schemas/*.gd`（9 个）、`res://data/{bosses,enemies,player}/*.tres`（3 份）、`res://scripts/combat/*.gd`（6 个逻辑件）、`res://autoload/game_events.gd`、`res://gate/r4_gate_runner.gd`（运行时验证件）、`res://main.tscn` |
| 未做 | 未写探针 / 测量 / preflight 脚本到工位；`r4_gate_runner.gd` 是临时工程内的运行时功能验证件，随临时工程删除；零付费 / 零外部依赖；未碰 WSL |

> 段 3 的 `--quit` 主场景挂载 `r4_gate_runner.gd`，从而**真跑** `CombatDataValidator._ready()`
> 与新增的 `BossController` / `CombatEventBus`，这是本轮相对 R3「只加载不挂载」的补齐。

### 2.2 三段门禁 · 实际输出结论

| 段 | 命令 | 退出码 | 实际输出结论 |
|---|---|---|---|
| 0 | `... --version` | **0** | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `... --headless --path <gate> --import` | **0** | 首次扫描 5 步 DONE；`正在注册全局类…… (17 steps)`，15 个 `class_name` 全部注册成功，含新增 `BossController` / `CombatEventBus`；加载编辑器 DONE；无 `ERROR` |
| 2 | `... --headless --path <gate> --check-only --script res://<各 .gd>`（17 个） | **17/17 = 0** | 9 个 schema + 6 个逻辑 + 1 个 autoload + 1 个 runner 全部解析通过（`SEG2_SCRIPTS=17 SEG2_FAIL=0`） |
| 3 | `... --headless --path <gate> --quit` | **0** | 打开工程、加载 3 份 `.tres`、触发 `r4_gate_runner._ready()`，实跑 validator / Boss / I-2 后退出 |

段 2 的 17 个脚本：`data/schemas/{boss_data,phase_data,move_data,poise_config,status_buildup,enemy_data,player_action_data,player_action_table,spawn_request}.gd`、
`scripts/combat/{combat_resolver,enemy_director,player_state_machine,combat_data_validator,boss_controller,combat_event_bus}.gd`、
`autoload/game_events.gd`、`gate/r4_gate_runner.gd`。

### 2.3 `SCRIPT ERROR` grep 结果（工具链 §4.2 要求：必须 grep，不以退出码冒充通过）

把 4 段日志合并为 `log_all.txt`（**304 行**）后执行：

```
grep -nEi "SCRIPT ERROR|Parse Error|ERROR:|Failed|Cannot|dangling|悬空|Invalid|not found|Can't" log_all.txt
```

| 范围 | 命中 | 结论 |
|---|---|---|
| `SCRIPT ERROR` **专项**（全 304 行） | **0 命中**（grep RC=1） | **脚本层零 SCRIPT ERROR / Parse Error** |
| 段 1 `--import` + 段 2 全部 `--check-only` 宽口径 | **0 命中**（grep RC=1） | 脚本解析与全局类注册零错误 |
| 段 3 `--quit` 实跑宽口径 | **4 条 `ERROR:`** | 全部来自 `CombatDataValidator`：`FAIL E-8 抗性不溢出 -> status_01_bleed / status_02_poison / status_03_frost` 共 3 条 + `数据表自洽校验失败，错误 3 项` 汇总 1 条 |

> **如实说明**：这 4 条是 `push_error()` 输出的**数据表自洽校验 FAIL**，属于既有
> `boss_01_margit.tres` 数值与 E-8 校验式的冲突（见 §2.4），**不是 GDScript 解析错误、
> 不是运行时 `SCRIPT ERROR`、不是本轮新增件引入的偏差**。按工具链 §4.2「运行时
> `SCRIPT ERROR` 不改退出码、必须 grep」的口径，本轮以 grep 结果分别判定：
> **脚本层 0 命中通过；数据层 E-8 FAIL 如实登记为待裁决，不掩盖、不谎报全 PASS。**

### 2.4 `combat_data_validator._ready()` 实跑（交付件 3）

```
[CombatDataValidator] E-1/E-3/E-4/E-5/E-8/E-9 检查项 491，错误 3
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_01_bleed
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_02_poison
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_03_frost
ERROR: [CombatDataValidator] 数据表自洽校验失败，错误 3 项
[R4-GATE] CombatDataValidator._ready() 已触发
```

- E-1 / E-3 / E-4 / E-5 / E-9 **通过**；E-8 **3 项 FAIL**。
- E-8 式 `threshold + resistance_gain_per_trigger × 8 <= max_resistance`：
  bleed `180 + 25×8 = 380 > 330`、poison `210 + 30×8 = 450 > 360`、
  frost `160 + 30×8 = 400 > 320`。与 `DONE-R2.md` §4 第 2 项静态推算完全一致，本轮真跑实证。
- 本轮不改 `.tres`（一律不重做）、不改 validator（`combat_*.gd` 一律不重做）、不改 E-8 口径，
  **登记为待 HOST 裁决**（详见 `R4-口径与阻塞登记.md` §3），不冒充完成。

### 2.5 M5 Boss 控制器实跑（交付件 1，段 3 日志摘录）

```
[BossController] 阶段装载 -> phase_index=1 pose_prefix=p1_ 招式数=2
[R4-GATE] Boss 初始：phase_index=1 pose_prefix=p1_ 招式数=2 hp_ratio=1.000
[BossController] PhaseTransition 开始 -> phase_index=2 id=phase_02_margit_p2 pose_prefix=p2_ frames=48
[BossController] 阶段装载 -> phase_index=2 pose_prefix=p2_ 招式数=3
[BossController] PhaseTransition 结束 -> phase_index=2 pose_prefix=p2_ 招式数=3
[BossController] 抽中招式 -> phase=2 move=move_01_dagger_slash pose=p2_dagger_slash weight=3.00 total=5.60
[BossController] 抽中招式 -> phase=2 move=move_02_staff_slam pose=p2_staff_slam weight=1.60 total=5.60
[BossController] 抽中招式 -> phase=2 move=move_03_holy_hammer pose=p2_holy_hammer weight=1.00 total=5.60
[BossController] Boss 被击败 -> id=boss_01_margit（I-2 交给 CombatEventBus）
```

- 伤害由 `phase_thresholds[0]` 从表派生（真跑件不写死本案数值），HP 比例落到切换点后
  自动进过渡；过渡帧数取 `PhaseData.transition_frames`；轮询间隔按
  `ai_poll_interval_sec / aggression` 计算，全部查表。
- P2 加权抽取 `total=5.60`，3 种招式均被抽中，pose 名一律 `p2_` 前缀（I-4）。

### 2.6 I-2 改挂 `GameEvents` autoload 实跑（交付件 2，段 3 日志摘录）

```
[R4-GATE] 已连接 /root/GameEvents 的 I-2 信号
[R4-GATE] GameEvents.boss_defeated 收到 -> boss_01_margit (单 String)      ← Boss 击杀
[R4-GATE] GameEvents.enemy_defeated 收到 -> enemy_01_limgrave_soldier (单 String)  ← 直发
[R4-GATE] GameEvents.boss_defeated 收到 -> boss_01_margit (单 String)      ← 直发
[R4-GATE] I-2 累计收到信号数=3 明细=["boss_defeated:boss_01_margit", "enemy_defeated:enemy_01_limgrave_soldier", "boss_defeated:boss_01_margit"]
```

- 信号承载体为 `/root/GameEvents` autoload（Rank-3 `game_events.gd`），参数单个 `String`；
  2 号全程未 `set_flag`、未写存档、未双写。与 3 号《接口契约.md》§2.2 的
  `/root/GameEvents` 兼容发现顺序一致。

### 2.7 「数值全部留表里」/ R2 口径 §6 核对

| 校验 | 实际输出 | 结论 |
|---|---|---|
| 全仓 `.gd` 的 `const` | 仅 2 处 `const MIN_DAMAGE: float = 1.0`（`combat_resolver.gd:20`、`player_state_machine.gd:42`，均为 R2 既有） | **PASS**（本轮新增 2 件无 `const`） |
| 本轮 2 个新增件数字字面量 | 仅 `0.0` / `0.5` / `-1.0` / `1.0`（归零、计时起点、半角、clamp 边界等几何 / 数学常量），无 `3500 / 420 / 2.1 / 0.5 阈值 / 48 / 96 / 620` 等本案战斗数值 | **PASS** |
| I-1 | `boss_controller.gd` 只读 `get_flag(key, default)` 双参、自行 cast，无 `set_flag`；新增件不碰存档 / SaveDelta | **符合** |
| I-2 | 新增件不定义 `enemy_defeated` / `boss_defeated` 信号、不写 flag、不双写；只 emit 到 `GameEvents` autoload，参数单 `String`；击杀由 `CombatEventBus` 唯一发射点处理 | **符合（偏差已收敛）** |
| I-3 | `SpawnRequest` 17 字段以 3 号《接口契约.md》§3 为唯一定义；新增件不定义 / 不新增 / 不读取其字段 | **符合** |
| I-4 | `boss_controller.gd` 仅 1 处 `set_pose` 调用（`_apply_pose`），pose 名 = `pose_prefix + pose_name`，前缀 `p1_` / `p2_` 来自数据表；不写 billboard / 锚定 / 缩放 / `SpriteFrames` | **符合** |

---

## 3. 自检汇总

- 三段门禁：**真跑 PASS**（`SEG0/1/3_EXIT=0`、`SEG2_SCRIPTS=17 SEG2_FAIL=0`；命令 / 退出码 / 日志见 §2.2）。
- `SCRIPT ERROR` 专项：**0 命中**；段 1 / 段 2 宽口径：**0 命中**（§2.3）。
- `combat_data_validator._ready()`：**已实跑**，检查项 491、错误 3（E-8 既有数据冲突，如实登记、待裁决）（§2.4）。
- M5 Boss 控制器数据驱动二阶段 + 2~3 招式：**已实跑**（P1→P2、48 帧过渡、3 招加权抽取、击杀 I-2）（§2.5）。
- I-2 改挂 `GameEvents` autoload：**已实跑**（3 条单 String 信号、2 号不写 flag）（§2.6）。
- 「改数值不改代码」/ R2 口径 §6：**全 PASS**（§2.7）。
- 交付件齐全性：任务书 §交付清单 4 项 + `DONE-R4.md` + 回执，全部落地；既有件零改动。

---

## 4. 未完成项与阻塞（诚实标注，不冒充完成）

1. **E-8 三组异常抗性溢出（真跑实证、待 HOST 裁决）**：`boss_01_margit.tres` 的
   `bleed / poison / frost` 三组 `max_resistance` 与 `数据表schema.md` §9 E-8 校验式冲突，
   validator `_ready()` 实跑报 3 项错误。本轮按「既有件不重做」未改 `.tres`、未改 validator、
   未改 E-8 口径；可选方向（改 `max_resistance` / 调 `resistance_sample_triggers` / 修订 E-8 式）
   见 `R4-口径与阻塞登记.md` §3。**集成前必须裁决**，否则 validator 启动即报 3 项错误。
2. **路径口径差异待裁决**：`res://data/schema/`（单数，`任务书-R3.md` §2 字面）vs
   `res://data/schemas/`（复数，`数据表schema.md` §0.1 / 8 个 schema 脚本 / 3 份 `.tres` 的
   11 条 `ext_resource`）。本轮按真源取复数以保证 `.tres` 不悬空、真跑自洽，
   **未擅改他人文档、未改 `.tres`**；若裁决单数需同步改 11 条 `ext_resource` 与头注释。
   详见 `R4-口径与阻塞登记.md` §1。
3. **`PlayerStateMachine` 既有 I-2 signal 声明去留待裁决**：本轮以新增 `CombatEventBus`
   收敛发射点、既有件零改动；既有 `signal enemy_defeated` / `signal boss_defeated` 声明
   降级为模块内历史声明。若 HOST 要求删除该声明，属改既有件，本轮不擅改，登记待裁决。
   `GameEvents` autoload 由 1 号注册、3 号实现，2 号只负责 emit。
4. **`rootmotion.json` 无预置实例、未生成本作 clip**（R2/R3 遗留）：`motion-mapping.md`
   为字段契约级映射，非真跑产物；`gen3d` / `mia-rig` 本机不可用、不补装、不碰 WSL
   （任务书 §4 / 工具链 §3）。不冒充已对齐产物。
5. **M5 阶段精灵表仅登记不调用**：`PhaseData.sprite_frames_path` 本轮仍按 Q1 待裁决
   处理，阶段动画走 `pose_prefix`（`p1_` / `p2_`）零接口扩展；真替换 `SpriteFrames`
   需 1 号新增入口，归总指挥裁决。
6. **跨模块待裁决 Q1~Q7**（`README.md` §5）：`WorldState` Autoload 名、`frame_index` clamp
   责任、pose 名与 4 号 `import.json` 映射、米→px 换算系数等仍归总指挥裁决；2 号不改别人文件。
7. **未写总线**：任务书-R4 未要求写总线，且 `00-群聊总线.md` 在 teamwork 根目录、超出
   唯一可写范围，本轮 HOST 指令亦明确「不写总线」，故未追加，如实登记；完成标志以本文件
   + 中枢回执为准。

> 第 1、2、3、5、6 项为口径 / 排期 / 裁决项，第 4 项为工具链本机条件限制，第 7 项为范围约束，
> 均**不阻塞本轮收尾**（4 项交付齐、真跑结论如实记录、阻塞逐条登记）。
> 无付费 / 外部依赖 / 探针脚本落工位 / git 操作。

---

## 5. 收尾动作

- 本文件 `DONE-R4.md` 已写（HOST 监测标志）。
- `boss_controller.gd` / `combat_event_bus.gd` / `R4-口径与阻塞登记.md` 已写；
  既有 `schema/`、`*.tres`、`combat_*.gd`、`motion-mapping.md` 等一律未重做、未改动。
- 中枢回执已写：`command_center\ai\2\outbox\receipt_R4_A2.json`，
  `task_id = cmd-20261109-013419-323-A2`、`ai = 2`、`status = done`，
  `result` 引用本文件实际结论（含 §4 未完成项与阻塞）。
  **写入后已被中枢 600ms 轮询回收**至
  `command_center\dispatcher\receipts\receipt_R4_A2.json`（`json.load` 复核合法、
  `result` 1265 字），`ai\2\status.json` 转 `idle / completed=3`、`last_seen 01:53:24`，
  `dispatcher\ledger.jsonl` 中 `cmd-20261109-013419-323-A2` 记 `done`
  （`finished_at 01:53:24`）；**`outbox` 现为空是中枢回收后的正常终态，非回执丢失**
  （与 `DONE-R3.md` §5 同）。
- 系统临时工程 `C:\Users\62668\AppData\Local\Temp\r4_gate_a2\` 不落入 teamwork、不提交，
  收尾时清理删除；真跑日志（`log_all.txt` 等）随临时工程删除，结论已抄录进本文件 §2。
- 未写总线 / 台账 / git；未自行 commit / push；零付费、未写探针 / 测量 / preflight 脚本到工位；
  开工只读一次 `00-群聊总线.md`。

---

## 6. 本轮执行实例独立真跑复核（`cmd-20261109-013419-323-A2` 实例）

> 本节由本轮 HOST 全闭环调度启动的 Rank-2 执行实例追加，**既有 §0~§5 一字未改**（只追加、不重做）。
> 前序并发实例已落盘本轮 4 项交付件，本实例按「只补缺口、不重做」全部保留；但 §2 的真跑结论
> 是前序实例文本，本实例**重新搭建独立系统临时工程、用 Godot 4.7.2 自己跑一遍**三段门禁，
> 以下退出码 / grep / 实跑输出均为本实例当场真实输出，非照抄、非伪造。

### 6.1 本实例实际交付清单（只补缺，未重做既有件）

| 文件 | 本实例处置 |
|---|---|
| `boss_controller.gd`（M5 Boss 控制器：数据驱动二阶段 + 2~3 招式实跑） | 前序实例已落盘、内容完整 → **保留不改**；本实例独立真跑复验（§6.3） |
| `combat_event_bus.gd`（I-2 信号改挂 `GameEvents` autoload） | 前序实例已落盘、内容完整 → **保留不改**；本实例独立真跑复验（§6.3） |
| `combat_data_validator.gd`（既有 R2 件，交付件 3 的宿主） | **未改动**；本实例在临时工程运行时挂载触发 `_ready()` 实跑（§6.3） |
| `R4-口径与阻塞登记.md`（`res://data/schema` vs `schemas` 待裁决登记） | 前序实例已落盘、内容完整 → **保留不改** |
| `DONE-R4.md`（本文件） | 前序实例已写 §0~§5 → **只追加本 §6**，既有内容零改动 |
| `command_center/ai/2/outbox/receipt-R4.json`（中枢回执） | **本实例补齐**：`task_id=cmd-20261109-013419-323-A2` / `ai=2` / `status=done` |

R2/R3 及更早轮次产出（`schema/`、`schema_*.gd`、`*.tres`、`combat_*.gd`、`enemy_director.gd`、
`player_state_machine.gd`、`motion-mapping.md`、`COMBAT-BUILD.md`、`接口契约.md`、`README.md`、
`DONE-R2.md`、`DONE-R3.md`、`任务书*.md`、`调度任务单*.json` 等）**一律保留、未改动**。

### 6.2 本实例真跑环境与三段门禁 · 实际退出码

| 项 | 值 |
|---|---|
| 引擎 | `D:\Godot\Godot_v4.7.2-stable_win64.exe`，`--version` 实测 `4.7.2.stable.official.ed1daf0bf` |
| 临时工程 | 系统临时目录 `C:\Users\62668\AppData\Local\Temp\r4_recheck_013419_323_A2\`（独立命名避免与并发实例 / 其它工位冲突，不落 teamwork、不提交，收尾即删） |
| 布局 | `main/`：9 个 `res://data/schemas/*.gd` + 6 个 `res://scripts/combat/*.gd` + 3 份 `.tres` + `autoload/{game_events,world_state}.gd` + `gate/{mock_sprite,r4_gate_runner}.gd` + `main.tscn` + `project.godot`（`GameEvents` / `WorldState` 两个 autoload、`main_scene=res://main.tscn`）；`flat/`：9 个平铺 `schema_*.gd` 单独工程（**因平铺 8 个与子目录 8 个 `class_name` 同名，必须拆两工程避免重复注册冲突**） |
| 临时占位件性质 | `game_events.gd` / `world_state.gd` / `mock_sprite.gd` 是 1 号 / 3 号依赖的临时工程内等价物；`r4_gate_runner.gd` 是段 3 挂载触发 `_ready()` 的运行时功能验证件；**均随临时工程删除、不落工位**，非探针 / 测量 / preflight 脚本 |

| 段 | 命令 | 本实例退出码 | 实际输出结论 |
|---|---|---|---|
| 0 | `--version` | **0** | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `--headless --path <main> --import` | **0** | `update_scripts_classes (19 steps)`，15 个 `class_name`（9 schema 类 + 6 逻辑类）全部注册成功，含 `BossController` / `CombatEventBus`；`[ DONE ] first_scan_filesystem` / `[ DONE ] update_scripts_classes` / `[ DONE ] loading_editor_layout` |
| 1b | `--headless --path <flat> --import` | **0** | 平铺 9 个 `schema_*.gd` 单独工程注册成功（避免与主工程同名类冲突） |
| 2 | 对**本工位所有 `.gd`** 逐个 `--headless --check-only --script` | **24/24 = 0**（`SEG2_TOTAL=24 SEG2_FAIL=0`） | 主工程 15 个（9 schema + 6 逻辑）+ 4 个临时工程件 + 平铺工程 9 个，全部 `EXIT=0`；本工位 23 个唯一 `.gd` 全覆盖（子目录 8 + 平铺 9 + 逻辑 6），其中 `PlayerActionTable` 规格件在主 / 平铺两工程各解析一次 |
| 3 | `--headless --path <main> --quit` | **0** | 加载 3 份 `.tres`、触发 `r4_gate_runner._ready()`，实跑 validator / Boss / I-2 后退出 |

### 6.3 `SCRIPT ERROR` grep 与段 3 实跑证据（本实例当场输出）

把 5 段日志合并为 `log_all.txt`（**280 行**）后执行：

```
grep -nEi "SCRIPT ERROR" log_all.txt                              # 专项
grep -nEi "SCRIPT ERROR|Parse Error|ERROR:" log_all.txt         # 宽口径
```

| 范围 | 本实例命中 | 结论 |
|---|---|---|
| `SCRIPT ERROR` 专项（全 280 行） | **0 命中**（`SCRIPT_ERROR_GREP_RC=1`） | **脚本层零 SCRIPT ERROR / Parse Error** |
| 宽口径（全 280 行） | **4 条 `ERROR:`**（`WIDE_GREP_RC=0`，命中于 log_all.txt 第 127/134/141/149 行） | 全部来自 `CombatDataValidator` 的 E-8 数据表自洽校验 FAIL（3 条具体 + 1 条汇总），**不是 GDScript 解析错误、不是运行时 SCRIPT ERROR、不是本轮新增件引入** |

段 3 实跑输出（逐字摘录；中间连续 `[BossController] 抽中招式` 日志行与 `at: push_error` 回溯行已省略）：

```
[CombatDataValidator] E-1/E-3/E-4/E-5/E-8/E-9 检查项 491，错误 3
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_01_bleed
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_02_poison
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_03_frost
ERROR: [CombatDataValidator] 数据表自洽校验失败，错误 3 项
[R4-RECHECK] CombatDataValidator._ready() 已触发
[BossController] 阶段装载 -> phase_index=1 pose_prefix=p1_ 招式数=2
[R4-RECHECK] Boss 初始：phase_index=1 pose_prefix=p1_ 招式数=2 hp_ratio=1.000
[BossController] PhaseTransition 开始 -> phase_index=2 id=phase_02_margit_p2 pose_prefix=p2_ frames=48
[BossController] 阶段装载 -> phase_index=2 pose_prefix=p2_ 招式数=3
[BossController] PhaseTransition 结束 -> phase_index=2 pose_prefix=p2_ 招式数=3
[BossController] 抽中招式 -> phase=2 move=move_03_holy_hammer pose=p2_holy_hammer weight=1.00 total=5.60
[R4-RECHECK] 切阶段后：phase_index=2 pose_prefix=p2_ 招式数=3 hp_ratio=0.500
[BossController] Boss 被击败 -> id=boss_01_margit（I-2 交给 CombatEventBus）
[R4-RECHECK] GameEvents.boss_defeated 收到 -> boss_01_margit (单 String)
[R4-RECHECK] GameEvents.enemy_defeated 收到 -> enemy_01_limgrave_soldier (单 String)
[R4-RECHECK] I-4 set_pose 调用次数=1182
[R4-RECHECK] I-2 累计收到信号数=3 明细=["boss_defeated:boss_01_margit", "enemy_defeated:enemy_01_limgrave_soldier", "boss_defeated:boss_01_margit"]
[R4-RECHECK] 段3 实跑完成
```

- 交付件 3 `combat_data_validator._ready()`：**本实例已实跑**（491 项检查跑完、错误 3）。
- 交付件 1 M5 Boss 控制器：P1（2 招，`total=4.60`）→ 按 `phase_thresholds[0]=0.5` 切 P2（3 招，`total=5.60`）→ 48 帧过渡 → 击杀；阈值 / 权重 / 帧数 / pose 前缀全部查 `.tres`，代码零硬编码。
- 交付件 2 I-2 改挂：`/root/GameEvents` autoload 收到 3 条单 `String` 信号，2 号不写 flag、不双写。

### 6.4 「数值留 `.tres`」/ I-1~I-4 口径核对（按 `00-协作契约.md` §3）

| 校验 | 本实例证据 | 结论 |
|---|---|---|
| 数值留表 | 3 份 `.tres` 承载全部战斗数值；逻辑 `.gd` 的 `const` 仅既有 2 处 `MIN_DAMAGE: float = 1.0`（`combat_resolver.gd:20`、`player_state_machine.gd:42`）；R4 新增 `boss_controller.gd` / `combat_event_bus.gd` 无战斗数值 `const`，仅 `0.0/0.5/-1.0/1.0` 几何 / 数学常量 | **PASS** |
| I-1 | `boss_controller.gd` / `enemy_director.gd` 均双参 `get_flag(key, default)`、自行 cast、无 `set_flag`；`player_state_machine.gd` 的 `_write_world_flag` 明确禁止 `.defeated`（既有件未改）；真跑 `WorldState` autoload 双参被真实调用 | **符合** |
| I-2 | 新增 `CombatEventBus` 为唯一对外发射点，emit 到 `/root/GameEvents`、参数单 `String`；既有 `PlayerStateMachine` 的 signal 声明保留不改（去留待裁决，既有件零改动）；真跑 3 条单 String 信号、2 号不写 flag | **符合（偏差已收敛，声明去留待裁决）** |
| I-3 | `enemy_director.spawn_from_request(request: SpawnRequest)` 消费 3 号 17 字段；`SpawnRequest` 规格件既有、未改 | **符合** |
| I-4 | 逻辑件仅 `set_pose(pose_name, frame_index)` 调用，pose 名 `pose_prefix + pose_name`（`p1_`/`p2_`）；不写 billboard / 锚定 / 缩放 / `SpriteFrames`；真跑 `set_pose` 被调用 1182 次 | **符合** |

### 6.5 本实例未完成项与阻塞（如实登记，不隐瞒、不淡化）

1. **E-8 三组异常抗性溢出（本实例真跑实证、待 HOST 裁决）**：validator `_ready()` 实跑报 3 项错误
   （bleed `180+25×8=380>330`、poison `210+30×8=450>360`、frost `160+30×8=400>320`），
   与既有 `.tres` 数值 / E-8 校验式冲突。按「既有件不重做、不对跨模块争议做最终裁决」，
   本实例**未改 `boss_01_margit.tres`、未改 `combat_data_validator.gd`、未改 E-8 口径**，
   只如实登记待裁决；候选方案见 `R4-口径与阻塞登记.md` §3。集成前必须裁决。
2. **路径口径 `res://data/schema` vs `schemas` 待裁决**：3 份 `.tres` 的 11 条 `ext_resource`
   全写死复数 `res://data/schemas/`，本实例真跑按复数自洽（`--import` / `--quit` 均 EXIT=0、
   无悬空引用）；差异登记见 `R4-口径与阻塞登记.md` §1，**未擅改他人文档 / `.tres`**。
3. **既有 `PlayerStateMachine` I-2 signal 声明去留待裁决**：本轮以新增 `CombatEventBus` 收敛
   发射点、既有件零改动；删除该声明属改既有件，本实例不擅改，登记待裁决。
4. **M5 阶段精灵表 `sprite_frames_path` 仅登记不调用**（Q1 待裁决）；`rootmotion.json` 无预置
   实例、未生成本作 clip（`gen3d`/`mia-rig` 本机不可用，不补装、不碰 WSL）；跨模块 Q1~Q7
   仍归总指挥裁决 —— 均为 R2/R3 遗留，详见 §4 与 `R4-口径与阻塞登记.md` §4。
5. **未写总线 / 台账 / `00-汇总.md`**：总线文件在 teamwork 根目录、超出唯一可写范围，
   本轮 HOST 指令亦明确「不写总线」，如实登记；完成标志以本文件 + 中枢回执为准。

> 上述第 1/2/3/4 项为口径 / 裁决 / 工具链限制项，第 5 项为范围约束，**均不阻塞本轮收尾**：
> 4 项交付齐、三段门禁真跑全 EXIT=0、`SCRIPT ERROR` 专项 0 命中、阻塞逐条登记。
> 无付费 / 外部依赖 / 探针脚本落工位 / git 操作。

### 6.6 本实例收尾动作

- `DONE-R4.md` 既有 §0~§5 零改动，仅追加本 §6。
- 中枢回执补齐：`command_center/ai/2/outbox/receipt-R4.json`，
  `task_id=cmd-20261109-013419-323-A2`、`ai=2`、`status=done`，`result` 引用本文件实际结论。
- 临时工程 `C:\Users\62668\AppData\Local\Temp\r4_recheck_013419_323_A2\` 已 `rm -rf` 删除，
  真跑日志随临时工程删除，结论已抄录进本 §6。
- 开工只读一次 `00-群聊总线.md`；未自行 commit / push；零付费、零外部依赖。

### 6.7 回执落地与中枢回收（本实例实测，如实登记）

- 回执先写到 `command_center/ai/2/outbox/receipt-R4.json`；随后中枢 600ms 轮询**已回收**至
  `command_center/dispatcher/receipts/receipt-R4.json`（本实例用 `python json.load` 复核合法：
  `task_id=cmd-20261109-013419-323-A2`、`ai=2`、`status=done`、`result` 1030 字）。
- 因此 `outbox/` 现为空是**中枢回收后的正常终态，非回执丢失**（与 `DONE-R3.md` §5、
  本文件 §5 记载的同一机制一致）；本实例未重复写第二份、未改 `ledger` / `status.json`。
- 本实例只读核实了 `outbox/`、`dispatcher/receipts/` 与回执内容各一次（因回执校验报
  `FileNotFoundError` 触发的去向核实），**未做进度巡检、未写探针 / 测量脚本**。
