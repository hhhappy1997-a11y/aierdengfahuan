# DONE-R3.md —— 2 号工位（战斗系统与数据驱动）R3 完成标志

> HOST 监测只认本文件。**R3 由 HOST 全闭环调度自动启动**（任务单 `cmd-20261109-005741-236-A2`）。
> 生成日期：2026-11-09（本机日期）。中文 UTF-8。
> 唯一写入：`Rank-2\` + 中枢回执 `command_center\ai\2\outbox\`（本轮指令的唯一例外）。
> **本轮指令明确「不写总线」**，故未追加 `00-群聊总线.md` 交付消息（该文件在 teamwork 根目录、超出唯一可写范围），如实登记。
> R2 已产出的 `schema_*.gd`、`combat_resolver.gd`、`enemy_director.gd`、`combat_data_validator.gd`、`player_actions.tres`、`enemy_01_limgrave_soldier.tres`、`boss_01_margit.tres`、`player_state_machine.gd` 等**一律不重做、未改动**，只补齐 R3 新增/缺失项并核对。

---

## 0. 结论速览

- **状态：完成**。任务书-R3.md §2 交付清单 5 项全部落地（其中 `boss_01_margit.tres` 按要求为**只读校验、不改动**），另写中枢回执。
- **三段门禁真跑 PASS**：引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`），`--version` / `--headless --import` / 9 个 `--check-only --script` / `--headless --quit` **全部 EXIT=0**；全日志 49 行 grep `SCRIPT ERROR` 等 **0 命中**。
- **字段 / `.tres` 校验 PASS**：7 类 119 行 `@export` 与 `数据表schema.md` 逐字一致、`SpawnRequest` 17 字段与 Rank-3 §3 逐字一致；3 份 `.tres` `load_steps` 自洽、悬空引用 0、字段越界 0；「改数值不改代码」实测全 PASS。
- **如实登记的未完成项**：本机无预置 `rootmotion.json` 实例、未生成本作 clip（映射为字段契约级）；`res://data/schema/`（单数）vs `res://data/schemas/`（复数）口径差异；I-2 `GameEvents` 挂载偏差等 R2 遗留项；validator 运行时 `_ready()` 自检未实跑。详见 §4，**不冒充完成、不谎报**。

---

## 1. 实际交付清单（对照 `任务书-R3.md` §2）

| # | 任务书要求 | 实际文件 | 状态 |
|---|---|---|---|
| 1 | `schema/*.gd` 共 **8 个 Resource 类脚本**，字段与 `数据表schema.md` 逐字一致，路径按 `res://` 声明、本轮落工位 `schema\` | `schema/boss_data.gd`、`schema/phase_data.gd`、`schema/move_data.gd`、`schema/poise_config.gd`、`schema/status_buildup.gd`、`schema/enemy_data.gd`、`schema/player_action_data.gd`、`schema/spawn_request.gd` | **本轮新建 8/8** |
| 2 | `boss_01_margit.tres`：落到工程时指向 `res://data/bosses/`；本轮校验字段与 schema 一致、`load_steps` 与 ext/sub 自洽、无悬空引用 | `boss_01_margit.tres`（R2 既有）+ 校验结论写入 `COMBAT-BUILD.md` §3 | **只读校验、未改动**（R2 件按指令不重做；另同法校验 `player_actions.tres` / `enemy_01_limgrave_soldier.tres`） |
| 3 | `motion-mapping.md`：`rootmotion.json` 字段 → 翻滚/攻击判定帧时序映射；loop 末帧重复首帧、`loop_mode = LINEAR`、脚步声落 `footContact` 0→1 帧 | `motion-mapping.md` | **本轮新建** |
| 4 | `COMBAT-BUILD.md`：三段门禁真跑实际输出结论（含 `SCRIPT ERROR` grep）+「改数值不改代码」校验清单 | `COMBAT-BUILD.md` | **本轮新建** |
| 5 | `DONE-R3.md`：① 交付清单 ② 自检结果（含真跑）③ 未完成项与阻塞 | 本文件 | **本轮新建** |
| 附 | 中枢回执 JSON（按任务单 id） | `command_center/ai/2/outbox/receipt_R3_A2.json` | **本轮新建** |

### 1.1 8 个 Resource 类脚本字段口径

- `BossData` / `PhaseData` / `MoveData` / `PoiseConfig` / `StatusBuildup` / `EnemyData` / `PlayerActionData` 共 7 类：字段名 / 类型 / 默认值**逐字复制** `数据表schema.md` §1~§7（119 行 `@export` diff 无差异）。
- `SpawnRequest`：按任务书-R3 §4 / 用户指令 I-3 / R2 口径 §6 第 4 条，**以 Rank-3《接口契约.md》§3 的 17 字段为唯一定义**（非 `数据表schema.md` §8 的 10 字段最小假设），17 行与 R2 规格件 / Rank-3 §3 逐字一致。
- 8 个脚本均为**纯数据规格件**（`func` 定义数 0，仅 `@export` 字段声明 + 默认值），不写战斗数值、不调 `WorldState` / `GameEvents` / `set_pose()`。
- 落工程路径：头部声明 `res://data/schemas/*.gd`（与 `数据表schema.md` §0.1 及 3 份 `.tres` 的 ext_resource 一致，保证真跑不悬空）；任务书 §2 字面的单数 `res://data/schema/` 差异见 §4。

### 1.2 R2 既有件（只读保留、未改动）

`schema_boss_data.gd` 等 9 个平铺规格件、`combat_resolver.gd`、`enemy_director.gd`、`combat_data_validator.gd`、`player_state_machine.gd`、`player_actions.tres`、`enemy_01_limgrave_soldier.tres`、`boss_01_margit.tres`、`README.md`、`DONE-R2.md`、`任务书*.md`、`数据表schema.md`、`接口契约.md`、`战斗系统设计.md`、`调度任务单*.json` —— **一律未重做、未改写**。

---

## 2. 自检结果（含真跑输出结论）

完整命令、日志摘录、grep 原文见 `COMBAT-BUILD.md` §2 / §3 / §5；以下为结论。

### 2.1 三段门禁真跑（引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`）

| 段 | 命令 | 退出码 | 结论 |
|---|---|---|---|
| 0 | `--version` | 0 | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `--headless --path <gate> --import` | 0 | 扫描 5 步 DONE；**9 个全局类注册成功**（BossData/EnemyData/MoveData/PhaseData/PlayerActionData/PlayerActionTable/PoiseConfig/SpawnRequest/StatusBuildup） |
| 2 | `--headless --check-only --script res://data/schemas/<各 .gd>`（9 个） | **9/9 = 0** | 8 个 R3 新增 + 1 个 R2 配套 `player_action_table.gd` 全部解析通过 |
| 3 | `--headless --path <gate> --quit` | 0 | 加载 `main.tscn` 及 3 份 `.tres` 场景依赖后退出；未复现 R2 首轮「无 main_scene 不退出」（本轮已声明 `run/main_scene`） |

**`SCRIPT ERROR` grep**：4 段日志合并 49 行，`grep -nEi "SCRIPT ERROR|Parse Error|ERROR:|Failed|Cannot|dangling|悬空|Invalid|not found|Can't"` → **0 命中**。按工具链 §4.2「运行时 `SCRIPT ERROR` 不改退出码、必须 grep 日志」的口径，以 grep 结果判定通过。
临时工程 `C:\Users\62668\AppData\Local\Temp\r3_gate_a2\` 在系统临时目录，不落 teamwork、不提交、收尾即删；未写任何探针 / 测量 / preflight 脚本。

### 2.2 `.tres` 校验（3 份，只读）

| `.tres` | `load_steps` | ext | sub | 期望 | 悬空引用 | 字段越界 |
|---|---|---|---|---|---|---|
| `boss_01_margit.tres` | 16 | 5 | 10 | 16 ✓ | 0 | 0 |
| `player_actions.tres` | 11 | 2 | 8 | 11 ✓ | 0 | 0 |
| `enemy_01_limgrave_soldier.tres` | 7 | 4 | 2 | 7 ✓ | 0 | 0 |

字段全集 = 8 类 101 个唯一 `@export` + `PlayerActionTable.actions` = **102**（与 DONE-R2.md §2.4 一致）；排除内建 `script` 后 3 份 `.tres` 唯一键越界 **0**。

### 2.3 字段逐字一致 /「改数值不改代码」

| 校验 | 实际输出 | 结论 |
|---|---|---|
| 7 类 119 行 `@export` vs `数据表schema.md` §1~§7 | 119 = 119，diff 无差异 | PASS |
| `SpawnRequest` 17 行 vs Rank-3 §3 / R2 规格件 | 17 = 17，diff 无差异 | PASS |
| 全仓 `.gd` 的 `const` | 仅 2 处 `MIN_DAMAGE: float = 1.0`（`combat_resolver.gd:20`、`player_state_machine.gd:42`） | PASS |
| 4 个逻辑脚本代码体（去注释）数据表特征数值 | 命中 **0** | PASS |
| 数值实例分布 | 全部在 3 份 `.tres`（带数值字段行 boss 125 / player_actions 153 / enemy 34） | PASS |
| R3 8 个 schema 脚本 `func` 数 | 0（纯字段声明） | PASS |

### 2.4 R2 口径 §6 核对

- **I-1**：R3 新增件为纯数据规格件、不读写 flag；沿用 R2 双参 `get_flag(key, default)` / `set_flag(key, value)` 结论。符合。
- **I-2**：R3 新增件不含信号定义、不新增偏差；沿用 R2「参数单个 `String`、击杀 flag 只由 Rank-3 写、2 号不双写」。**遗留偏差**：现有件信号定义在 `PlayerStateMachine` 节点自身、未挂 `GameEvents` autoload，按「已有件不重做」未改（§4）。
- **I-3**：`SpawnRequest` 17 字段以 Rank-3 §3 为唯一定义，逐字一致。符合。
- **I-4**：R3 新增件只声明 pose 字段、不调 `set_pose()`；沿用 R2 仅 2 处调用、`p1_`/`p2_` 前缀、不写 billboard/锚定/缩放/`SpriteFrames`。符合。

---

## 3. 自检结果汇总

- 三段门禁：**真跑 PASS**（命令 / 退出码 / grep 见 §2.1、`COMBAT-BUILD.md` §2）。
- `boss_01_margit.tres` 等 3 份 `.tres` `load_steps` 自洽、无悬空引用、字段与 schema 一致：**PASS**（§2.2）。
- 8 个 Resource 类脚本字段逐字一致、纯数据件：**PASS**（§2.3）。
- 「改数值不改代码」：**全 PASS**（§2.3）。
- 交付件齐全性：任务书 §2 的 5 项 + 回执，全部落地；R2 既有件未重做、未改动。

---

## 4. 未完成项与阻塞（诚实标注，不冒充完成）

1. **`rootmotion.json` 无预置实例、未生成本作翻滚/攻击 clip**：`D:\godogen_assets\motion\` 下只有 `basic.json`（`idle/walk/run/jump` 规格）、`README.md` 与生成脚本，`rootmotion.json` 是 `add-moves` 的运行时产物（`<name>_rootmotion.json`）。本轮**未实跑** `gen-moves` / `add-moves`（前置 `mia-rig` rig / 权重本机不可用；任务书 §4 明确 `gen3d`/`mia-rig` 不补装、不碰 WSL）。`motion-mapping.md` 是**字段契约级映射**（依据 `motion/README.md:25-32`、`add_moves.py:457-465` 的真实字段定义 + 本工位 3 份 `.tres` 的真实帧号），**不含任何真实 clip 帧数据、不冒充已对齐产物**。真跑不了如实写阻塞，未伪造输出。
2. **路径口径差异待 HOST 裁决**：任务书-R3 §2 字面 `res://data/schema/`（单数）与 `数据表schema.md` §0.1 / R2 规格件 / 3 份 `.tres` 的 `res://data/schemas/`（复数）不一致。本轮按唯一真源取复数以保证 `.tres` 不悬空、真跑自洽；已在 8 个脚本头注释登记，**未擅改他人文档**。若 HOST 裁决用单数，需同步改 3 份 `.tres` 的 ext_resource（届时由汇总统一处理）。
3. **I-2 `GameEvents` autoload 挂载偏差**（R2 遗留）：2 号现有交付件把 `enemy_defeated`/`boss_defeated` 定义在 `PlayerStateMachine` 节点自身，未显式挂 `GameEvents`。按「已有交付件不重做」未改，登记为集成收口 / 待裁决（autoload 由哪一路提供、2 号如何 connect/emit 需主 AI 裁决）。
4. **`combat_data_validator._ready()` 运行时自检未实跑**：本轮三段门禁校验的是脚本解析与 `.tres` 加载，未挂载 validator 触发 `_ready()`（E-1/E-3/E-4/E-5/E-8/E-9 运行时资源自检）；脚本本身 `--check-only` 已通过。另 E-8「抗性不溢出」口径与 `boss_01_margit.tres` 的 3 组异常数值需集成时复核（DONE-R2.md §4 第 2 项静态推算，非真跑结论，不冒充）。
5. **M5 `boss_controller.gd` / `PhaseTransition`**：任务书 §6 明确 R2 本轮不含，R3 排队包未列入本工位 8 类 / 映射 / 构建文档交付范围，仍待排期。
6. **跨模块待裁决 Q1~Q7**（`README.md` §5）：`WorldState` Autoload 名、`frame_index` clamp 责任、pose 名与 4 号 `import.json` 映射、米→px 换算系数（`motion-mapping.md` §6 第 4 项）等仍归总指挥裁决；2 号不改别人文件、不改契约。
7. **未写总线**：任务书-R3 §5 要求写 `DONE-R3.md` 后在 `00-群聊总线.md` 追加一条交付消息，但**本轮 HOST 指令明确「不写总线」**且总线文件在 teamwork 根目录、超出唯一可写范围，故未追加，如实登记；完成标志以本文件 + 中枢回执为准。

> 第 2、3、4、5、6 项为口径 / 排期 / 裁决项，第 1 项为工具链本机条件限制，均**不阻塞本轮收尾**（交付件齐、真跑结论已记录）。无付费 / 外部依赖 / 探针脚本 / git 操作。

---

## 5. 收尾动作

- 本文件 `DONE-R3.md` 已写（HOST 监测标志）。
- `COMBAT-BUILD.md` / `motion-mapping.md` / `schema/*.gd`（8 个）已写；`boss_01_margit.tres` 等 3 份 `.tres` 只读校验、未改动。
- 中枢回执已写：`command_center\ai\2\outbox\receipt_R3_A2.json`，`task_id = cmd-20261109-005741-236-A2`、`ai = 2`、`status = done`，`result` 引用本文件实际结论（含 §4 未完成项）。**写入后中枢 600ms 轮询已回收**至 `command_center\dispatcher\receipts\receipt_R3_A2.json`（JSON 复核合法、result 1438 字），`ai\2\status.json` 转 `idle / completed=2`、`dispatcher\ledger.jsonl` 中 `cmd-20261109-005741-236-A2` 记 `done`（`finished_at 01:18:18`）；**`outbox` 现为空是中枢回收后的正常终态，非回执丢失**（与 DONE-R2.md §5 同）。
- 系统临时工程 `%TEMP%\r3_gate_a2` 不落入 teamwork、不提交，收尾时清理删除。
- 未写总线 / 台账 / git；未自行 commit / push；零付费、未写探针 / 测量 / preflight 脚本；开工只读一次 `00-群聊总线.md`。
