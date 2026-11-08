# DONE-R2.md —— 2 号工位（战斗系统与数据驱动）R2 完成标志

> HOST 监测只认本文件。本轮为 R2 **收尾**：已有交付件不重做，只核对缺项、真跑三段门禁、补完成标志与中枢回执。
> 生成日期：2026-11-09（本机日期）。中文 UTF-8。
> 唯一写入：`Rank-2\` + 中枢回执 `command_center\ai\2\outbox\`（任务书 §0 的唯一例外）。
> 未写总线 / 台账 / git；R3 排队包 `任务书-R3.md` 保留不改、本轮不执行；零付费、未写探针 / 测量 / preflight 脚本、开工只读一次 `00-群聊总线.md`。

---

## 0. 结论速览

- **状态：完成（收尾）**。任务书 §2 全部文件已产出（含本轮补的 `README.md` §8「R2 交付清单」章节与本文件），字段一致性静态自检与三段门禁真跑结论已记录（§6 完成标准达成）。
- **三段门禁真跑通过**：引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`，`--version` / `--headless --import` / 13 个 `--check-only --script` / `--headless --quit` 全部 EXIT=0；全日志 grep `SCRIPT ERROR` 等 **0 命中**。
- **如实登记的未完成项**：I-2 `GameEvents` autoload 挂载口径偏差、`combat_data_validator._ready()` 运行时自检未实跑 / E-8 待复核、M5 Boss 控制器按任务书 §6 本轮不含。详见 §4，不冒充完成、不谎报。

---

## 1. 实际交付清单（对照 `任务书-R2.md` §2）

| # | 任务书要求 | 实际文件 | 状态 |
|---|---|---|---|
| 1 | 8 个 `schema_*.gd`（BossData / PhaseData / MoveData / PoiseConfig / StatusBuildup / EnemyData / PlayerActionData / SpawnRequest） | `schema_boss_data.gd`、`schema_phase_data.gd`、`schema_move_data.gd`、`schema_poise_config.gd`、`schema_status_buildup.gd`、`schema_enemy_data.gd`、`schema_player_action_data.gd`、`schema_spawn_request.gd` | 已有 8/8 |
| 附 | （任务书未单列）动作表容器 | `schema_player_action_table.gd`（`class_name PlayerActionTable`），支撑 `player_actions.tres` 的 `script_class` | 已有，合理补件 |
| 2 | `player_actions.tres`（8 条 `PlayerActionData`，数值取 `战斗系统设计.md` §1.1） | `player_actions.tres` | 已有 |
| 3 | `enemy_director.gd`（I-3 `spawn_from_request` / 感知丢失滞回 / 追击速度 / 攻击距离 / 轮询间隔 / 加权抽取） | `enemy_director.gd` | 已有 |
| 4 | `combat_resolver.gd`（伤害 `A×M×P×S−D` / 削韧 / 处决 / 出血中毒冻伤积累） | `combat_resolver.gd` | 已有 |
| 5 | `combat_data_validator.gd`（`_ready()` 跑 E-1/E-3/E-4/E-5/E-8/E-9） | `combat_data_validator.gd` | 已有 |
| 6 | `enemy_01_limgrave_soldier.tres`（M1 追击敌，无占位符） | `enemy_01_limgrave_soldier.tres` | 已有 |
| 7 | `player_state_machine.gd`（收敛：删 `_resolve_world_flag_signature()` 兼容分支，统一双参 `get_flag(key, default)`，其余不变） | `player_state_machine.gd` | 已有，已收敛 |
| 8 | `README.md` 追加「R2 交付清单」章节（首轮不改、只追加） | `README.md` §8 | **本轮补**（原先缺失） |
| 9 | `DONE-R2.md`（交付清单 / 自检结果含真跑 / 未完成项与阻塞） | 本文件 | **本轮补**（原先缺失） |
| 附 | `boss_01_margit.tres`（R1 已交，本轮校验 `load_steps` / 引用） | `boss_01_margit.tres` | 已有，校验通过 |

只读保留未改：`任务书.md`（首轮）、`任务书-R2.md`、`任务书-R3.md`（R3 排队包）、`战斗系统设计.md`、`数据表schema.md`、`接口契约.md`、`调度任务单-R2.json`。

> **缺项核对结论**：任务书 §2 的 9 项中，前 7 项已在工位；缺 **README 追加章节** 与 **DONE-R2.md**，本轮补齐。无其它缺件，已有文件一律未重做。

---

## 2. 真跑：引擎三段门禁（任务书 §4 硬验收）

**引擎**：`D:\Godot\Godot_v4.7.2-stable_win64.exe`
**实测版本**：`4.7.2.stable.official.ed1daf0bf`
**临时工程**：系统临时目录 `C:\Users\62668\AppData\Local\Temp\r2_gate_r2close\`（不在 teamwork 内、不提交、用完即删）。按 `res://data/schemas/*.gd`（9 个，去掉 `schema_` 前缀）/ `res://data/*.tres`（3 个）/ `res://scripts/*.gd`（4 个）平铺；`project.godot` 的 `config_version=5` 经 `--headless --import` 实测接受（无版本报错）。未写任何探针 / 测量 / preflight 脚本；`main.tscn` 是让引擎能「打开并加载资源引用」的最小场景配置，非脚本。

### 2.1 命令与退出码

| 段 | 命令 | 退出码 | 结论 |
|---|---|---|---|
| 0 | `Godot_v4.7.2-stable_win64.exe --version` | 0 | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `... --headless --path <gate> --import` | 0 | 首次扫描 + 注册 13 个全局类成功，导入 3 份 `.tres` 无报错 |
| 2 | `... --headless --path <gate> --check-only --script res://<各 .gd>`（13 个） | 13/13 = 0 | 9 个 schema + 4 个逻辑脚本全部解析通过 |
| 3 | `... --headless --path <gate> --quit` | 0 | 打开工程、加载 `main.tscn` 及其 3 份 `.tres` 场景依赖后退出 |

段 2 的 13 个脚本：`data/schemas/{boss_data,phase_data,move_data,poise_config,status_buildup,enemy_data,player_action_data,player_action_table,spawn_request}.gd`、`scripts/{combat_resolver,combat_data_validator,enemy_director,player_state_machine}.gd`。

### 2.2 关键过程记录（如实，含一次真实阻塞）

- 段 1 `--import` 日志：`first_scan_filesystem` 5 步 DONE；`update_scripts_classes` 13 步 DONE，逐个注册 `BossData / EnemyData / MoveData / PhaseData / PlayerActionData / PlayerActionTable / PoiseConfig / SpawnRequest / StatusBuildup / CombatDataValidator / CombatResolver / EnemyDirector / PlayerStateMachine`；`loading_editor_layout` DONE。无 `ERROR` / `SCRIPT ERROR`。
- 段 3 **首轮按任务书字面 `--headless --quit` 在「无 `main_scene`」的最小工程里报 `Error: Can't run project: no main scene defined in the project.` 且进程不退出**（`timeout` 终止，EXIT=124，并伴 `Pages in use exist at exit in PagedAllocator` 退出警告）。这是最小工程缺 `main_scene` 所致，**非交付件错误，已如实记录、不隐去**。补一个最小 `main.tscn`（`load_steps=4` = 3 `ext_resource` + 1；声明 `boss_01_margit.tres` / `enemy_01_limgrave_soldier.tres` / `player_actions.tres` 为场景依赖）并在 `project.godot` 设 `run/main_scene` 后重跑：`--headless --quit` **EXIT=0**、日志仅一行版本头、无报错。3 份 `.tres` 作为场景依赖被引擎加载校验，无解析 / 悬空引用报错。
- 三段全部输出日志已 grep：`SCRIPT ERROR` / `Parse Error` / `ERROR:` / `Failed` / `Cannot` / `warning` —— **0 命中**；退出码全 0。
- 按 `00-工具链接入说明.md` §4.2「运行时 `SCRIPT ERROR` 只中断当前函数、退出码仍为 0，**必须 grep 日志**才算通过」：本轮以 grep 结果为准，不以退出码冒充通过。

### 2.3 `boss_01_margit.tres` 的 `load_steps` 与 ext/sub 自洽、无悬空引用

| `.tres` | `load_steps` | `ext_resource` | `sub_resource` | 期望 `ext+sub+1` | 结论 |
|---|---|---|---|---|---|
| `boss_01_margit.tres` | 16 | 5 | 10 | 16 | **PASS** |
| `player_actions.tres` | 11 | 2 | 8 | 11 | **PASS** |
| `enemy_01_limgrave_soldier.tres` | 7 | 4 | 2 | 7 | **PASS** |

`boss_01_margit.tres` 的 5 个 `ext_resource`（`1_boss` / `2_phase` / `3_move` / `4_poise` / `5_status`）与 10 个 `sub_resource`（2 韧性 + 3 异常 + 3 招式 + 2 阶段）全部声明齐备；所有 `ExtResource("...")` / `SubResource("...")` 引用（含 `Array[ExtResource(...)]` 类型标注）逐一比对声明，**未声明引用 0 个、悬空引用 0 个**。`phase_01.poise_override = null`、`status_buildups` 类型化空数组均为合法写法。3 份 `.tres` 同法核对均 0 悬空。

### 2.4 静态自检（任务书 §4.4）

| 检查 | 结果 |
|---|---|
| `.tres` 字段键命中 schema | 3 份 `.tres` 唯一键 86 个 ⊆ schema `@export` 唯一字段名 102 个；排除 Godot 内建 `script` 后 **越界字段名 0** → **PASS** |
| `.gd` 战斗数值硬编码 | 全仓 `const` 仅 2 处 `const MIN_DAMAGE: float = 1.0`（`combat_resolver.gd:20`、`player_state_machine.gd:42`）；逻辑脚本数字字面量仅 `0.0 / 1.0 / -1.0 / 0.5 / 2 / 8 / 48` 等归零、哨兵、几何常量与 `@export` 可配校验口径（`resistance_sample_triggers`），**命中本案战斗数值 0 项**（无 420 / 96 速度 / 2.1 倍率 / 0.5 阈值 等数据表数值） → **PASS** |
| 数值全部留在表里 | 全部实例数值（HP / 攻防 / 帧数 / 倍率 / 半径 / 阈值 / 权重 / 冷却）均落在 3 份 `.tres`；`schema_*.gd` 只含 `@export` 字段声明与默认值（Resource 规格件），逻辑代码不含战斗数值 → **PASS**（「数据表改数值不改代码」核心验收） |

### 2.5 R2 §6 统一执行口径核对

| 编号 | 口径 | 核对结果 |
|---|---|---|
| I-1 | 只用 `WorldState.get_flag/set_flag`，双参 `get_flag(key, default)`、删兼容分支 | **符合**：`player_state_machine.gd:287` / `enemy_director.gd:327` 均双参调用，注释明确已删 `_resolve_world_flag_signature()`；不读写存档 / SaveDelta |
| I-2 | 挂 `GameEvents` autoload、参数单个 `String`、击杀 flag 只由 3 号写 | **部分**：参数单个 `String`（`enemy_defeated(enemy_id: String)` / `boss_defeated(boss_id: String)`）✓；2 号不写 `.defeated` flag、只发信号不双写（`.defeated` 硬拦截 `push_error`）✓；**但信号定义在 `PlayerStateMachine` 节点自身，未挂 `GameEvents` autoload（全 Rank-2 交付件无 `GameEvents` 字样）** → 见 §4 第 1 项 |
| I-3 | `SpawnRequest` 以 Rank-3 接口契约 §3 的 17 字段为准 | **符合**：`schema_spawn_request.gd` 编号 1~17 完整 17 字段；`enemy_director.gd` 按 17 字段消费；文件头注释明确以 3 号《接口契约.md》§3 为唯一定义、R1 的 10 字段最小假设按此收口 |
| I-4 | 只调 `set_pose()`、pose 名加 `p1_` / `p2_` 前缀 | **符合**：仅 `player_state_machine.gd:273` / `enemy_director.gd:284` 调 `set_pose()`；Boss 阶段 `pose_prefix` = `p1_`（`phase_01`）/ `p2_`（`phase_02`），`enemy_director.gd` 用 `prefix + move.pose_name` 拼名；不写 billboard / 锚定 / 缩放 / `SpriteFrames`。玩家 8 个 pose 名按 Q5 冻结表不带前缀 |

---

## 3. 自检结果汇总

- 三段门禁：**真跑 PASS**（命令 / 退出码 / grep 见 §2）。首轮 `README.md` §4「本机未检出 godot、只做静态字段核对」的旧结论按 MSG-20261108-2324-HOST 作废。
- `boss_01_margit.tres` `load_steps` 与 ext/sub 自洽、无悬空引用：**PASS**（§2.3）。
- 静态自检（字段越界 / 硬编码 / 数值在表里）：**全 PASS**（§2.4）。
- 口径核对：I-1 / I-3 / I-4 符合；I-2 有 1 项 `GameEvents` 挂载偏差（§4）。
- 交付件齐全性：任务书 §2 的 9 项，7 项已在、2 项本轮补齐。

---

## 4. 未完成项与阻塞（诚实标注，不冒充完成）

1. **I-2 `GameEvents` autoload 挂载偏差**：R2 §3 口径 3 要求信号挂 `GameEvents` autoload。现有 2 号交付件把 `enemy_defeated` / `boss_defeated` 定义在 `PlayerStateMachine` 节点自身（参数单个 `String`、击杀 flag 不双写均符合），但未显式挂到 `GameEvents`。本轮按 HOST「已有交付件不要重做」未改代码，登记为集成收口 / 待裁决项（`GameEvents` autoload 由哪一路提供、2 号如何 connect / emit 需主 AI 裁决）。
2. **`combat_data_validator.gd` 运行时 `_ready()` 自检未实跑**：本轮三段门禁为 `--import` / `--check-only --script` / `--quit`，`main.tscn` 仅声明 3 份 `.tres` 为场景依赖、未挂载 `CombatDataValidator` 触发 `_ready()`，故「启动即报」未在本轮真跑中执行（脚本本身 `--check-only` 已通过）。另**静态观察**（非真跑结论）：默认 `resistance_sample_triggers=8` 时 E-8「抗性不溢出」口径与 `boss_01_margit.tres` 的 3 组 `StatusBuildup` 数值需复核（例：bleed `180 + 25×8 = 380 > max_resistance 330`；poison `210 + 30×8 = 450 > 360`；frost `160 + 30×8 = 400 > 320`）。**此为静态推算、未实跑，不冒充真跑结论**，建议集成时挂载 validator 复核或由主 AI 裁决数值 / 口径。
3. **M5 `boss_controller.gd` / `PhaseTransition`**：任务书 §6 明确本轮不含，待 M1 实跑后排入 R3；`任务书-R3.md` 为排队包，本轮保留不改、不执行。
4. **跨模块待裁决 Q1~Q7**（`README.md` §5）：`WorldState` Autoload 名、3 号 `SpawnRequest` 最终字段表、`frame_index` clamp 责任、pose 名与 4 号 `import.json` 映射等仍归总指挥裁决；2 号不改别人文件、不改契约。
5. **`调度任务单-latest.json`**：Rank-2 工位当前只有 `调度任务单-R2.json`（`id = cmd-20261109-002446-436-A2`），未见 `latest.json`（中枢文件桥接钩子尚未对本工位派新单）。本轮回执 `task_id` 取自 `调度任务单-R2.json`，如实记录。

> 第 1、3、4 项为口径 / 排期 / 裁决项，第 2 项为需挂载后复核项，均**不阻塞本轮收尾**（交付件齐、`DONE-R2.md` 存在、字段一致性与真跑结论已记录）。无付费 / 外部依赖 / 探针脚本 / git 操作。

---

## 5. 收尾动作

- 本文件 `DONE-R2.md` 已写（HOST 监测标志）。
- `README.md` 已追加 §8「R2 交付清单」，首轮 §1~§7 原文未改。
- 中枢回执已写：`command_center\ai\2\outbox\receipt_R2_A2.json`，`task_id = cmd-20261109-002446-436-A2`、`ai = 2`、`status = done`，`result` 引用本文件实际结论（含 §4 未完成项）。写入后中枢 600ms 轮询已回收至 `dispatcher\receipts\receipt_R2_A2.json`（JSON 已复核合法），`ai\2\status.json` 转 `idle / completed=1`、`dispatcher\ledger.jsonl` 中 A2 记 `done`（`finished_at 00:55:28`）；**`outbox` 现为空是中枢回收后的正常终态，非回执丢失**。
- 系统临时工程位于 `%TEMP%\r2_gate_r2close`，未落入 teamwork、不提交，收尾时清理删除。
- 未写总线 / 台账 / git；R3 排队包 `任务书-R3.md` 保留不动。
