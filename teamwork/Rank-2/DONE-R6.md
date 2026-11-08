# DONE-R6.md —— Rank-2 完成标志（R6：战斗层装配进工程根）

> 任务单 `cmd-20261109-022336-998-A2`｜2 号工位 · 战斗系统与数据驱动｜中文 UTF-8。
> 依据：`任务书-R6.md`、MSG-20261109-0223-HOST 总指挥 02:23 授权、`调度任务单-latest.json`。
> 本文所有真跑数字来自本机 Godot 4.7.2 实际输出，不伪造、不引用旧结论冒充。
> 详细映射表 / 装配自检 / 待裁决保留登记见同目录 `COMBAT-ASSEMBLY.md`。

---

## ① 实际交付清单

### 1.1 工程根落位（全部新建，未覆盖任何既有文件）

`F:\Game\aierdengfahuan\godot\scripts\combat\` —— **12 个 `.gd`**：

| 组 | 文件 |
|---|---|
| A · 8 个 Resource 类脚本 | `boss_data.gd`、`phase_data.gd`、`move_data.gd`、`poise_config.gd`、`status_buildup.gd`、`enemy_data.gd`、`player_action_data.gd`、`spawn_request.gd` |
| B · 3 个逻辑脚本（I-1~I-4 核对） | `boss_controller.gd`、`combat_event_bus.gd`、`combat_resolver.gd` |
| C · 1 个装配闭合补位件 | `player_action_table.gd`（R2 既有配套容器类只读复制，理由见 `COMBAT-ASSEMBLY.md` §2.3 / §6.6） |

`F:\Game\aierdengfahuan\godot\data\combat\` —— **3 份 `.tres`**：
`boss_01_margit.tres`、`player_actions.tres`、`enemy_01_limgrave_soldier.tres`。

> 引擎伴随文件（非本轮写入）：真实工程根 `godot\scripts\combat\` 下另有 12 个同名 `.gd.uid`
> （Godot 4.4+ 脚本 UID 伴随文件），由引擎扫描工程时自动生成（实测 02:34，晚于落位 02:33:43），
> 非 2 号写入、非本轮交付件、属引擎管理；未删除、未改动、不计入交付清单。

### 1.2 `ext_resource` 路径修正
3 份 `.tres` 共 **11 条** `ext_resource`：`res://data/schemas/xxx.gd` → `res://scripts/combat/xxx.gd`
（有效 `res://` 绝对路径）。残留 `data/schemas` 计数 **0**；8 个唯一目标脚本落位存在、缺失 **0**。
3 份 `.tres` 的 diff 变化行 10 / 4 / 8 **全部为 `ext_resource path` 行**，数值字段零改动。

### 1.3 本工位文档与回执
- `Rank-2\COMBAT-ASSEMBLY.md`（`res://` 映射表 / 装配自检 / E-8 待裁决保留登记）
- `Rank-2\DONE-R6.md`（本文件）
- `teamwork\command_center\ai\2\outbox\cmd-20261109-022336-998-A2.json`（回执 `status=done`）

> **回执流转（如实登记）**：回执写入 `outbox\` 后已被中枢正常消费，归档于
> `teamwork\command_center\dispatcher\receipts\cmd-20261109-022336-998-A2.json`（内容一致、JSON 解析通过）；
> 中枢 `ai\2\status.json` 实测 `state=idle / completed=7 / last_seen 02:46:18`，证明已接收处理。
> 因中枢持续轮询消费致 `outbox\` 再度为空，本轮曾补写一份留档，中枢二次归档为带时间戳备份
> `cmd-...json.20261109-024618-805`（同内容）。回执已生效，不再重复补写；备份由中枢生成、不在 2 号可写范围。

### 1.4 未落位 / 未改动（如实）
- **未写** `godot\project.godot`（Rank-1 独占）；未写其它工位 / 其它子目录；未写总线 / 总纲 / 契约 / 台账。
- 工位既有件零改动：12 个落位 `.gd` 与原件逐字一致（`diff -q` 差异 **0**）；3 份 `.tres` 数值一字未改。
- `combat_data_validator.gd` / `enemy_director.gd` / `player_state_machine.gd` 未纳入本轮落位清单
  （既有件不重做），仍保留在 `Rank-2\` 工位。

---

## ② 自检（真跑输出结论）

### 2.1 环境与方式
- 引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`，`--version` 实测 `4.7.2.stable.official.ed1daf0bf`（EXIT=0）。
- 真跑在系统临时最小工程 `C:\Users\62668\AppData\Local\Temp\r6_gate_a2\`，**镜像落位布局**（`scripts/combat` +
  `data/combat` + 修正后 3 份 `.tres`），**收尾已删除**、复查确认目录不存在。
- 方式选择理由：Rank-1 已于 02:28 落位 `project.godot`，但 `--headless --import` 会写真实工程根 `.godot\`
  缓存（超出 2 号可写范围），且四路工位正并行写入、真实工程根存在跨工位 autoload 目标缺失；故按任务书
  授权的「系统临时最小工程验证、用完即删」方案执行，避免越界与干扰。**落位成果本身在真实工程根。**

### 2.2 四段门禁实际输出

| 段 | 命令 | 退出码 | 结论 |
|---|---|---|---|
| 0 | `--version` | **0** | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `--headless --path <gate> --import` | **0** | 34 行；`first_scan_filesystem` 5 步 DONE；`update_scripts_classes`（15 steps）注册 **13 个全局类名**（含 `BossController` / `BossData` / `CombatEventBus` / `CombatDataValidator` / `PlayerActionTable` 等）；`loading_editor_layout` DONE；无 ERROR |
| 2 | `--headless --path <gate> --check-only --script res://<15 个 .gd>` | `SEG2_SCRIPTS=15 SEG2_FAIL=0` | 15 个脚本全部解析通过，其中 **12 个落位件全部 EXIT=0** |
| 3 | `--headless --path <gate> --quit` | **0** | 打开工程、加载 3 份 `.tres`、触发 `CombatDataValidator._ready()` 实跑后退出 |

### 2.3 `SCRIPT ERROR` grep 与机器化核对（合并日志 95 行）

| 检查 | 结果 |
|---|---|
| [A] `SCRIPT ERROR` 专项（全 95 行） | **0 命中（RC=1）** |
| [B] 宽口径（全 95 行） | **4 条 `ERROR:`**（行 68 / 75 / 82 / 90，全部来自段 3，见 2.4） |
| [C] 宽口径（段 0+1+2，排除段 3） | **0 命中（RC=1）** |
| [D] 8 个唯一 ext 路径落位存在性 | **8/8 存在，缺失 0** |
| [E] E-8 三项数值 | `180/25/330`、`210/30/360`、`160/30/320`，与 R5 一致、**未改** |
| [F] 12 个落位 `.gd` vs 工位原件 | **差异 0** |
| [G] 3 份 `.tres` diff 性质 | 变化行 10 / 4 / 8 **全部为 `ext_resource path` 行**，数值零改动 |

### 2.4 E-8 如实登记（不冒充全绿）
段 3 稳定复现 **4 条 `ERROR:`**：`FAIL E-8 抗性不溢出 -> status_01_bleed / status_02_poison /
status_03_frost` 三条 + `数据表自洽校验失败，错误 3 项` 汇总，并输出
`[CombatDataValidator] E-1/E-3/E-4/E-5/E-8/E-9 检查项 491，错误 3`。
**性质判定**：4 条均由 `CombatDataValidator` 的 `push_error()` 输出（backtrace 指向
`core/variant/variant_utility.cpp:1023`），是**数据表自洽校验 FAIL**，
**不是 GDScript 解析错误、不是运行时 `SCRIPT ERROR`**（专项 grep 0 命中、段 3 退出码仍为 0）。
E-1 / E-3 / E-4 / E-5 / E-9 通过，E-8 三项 FAIL。原文见 `COMBAT-ASSEMBLY.md` §4.4。

### 2.5 I-1~I-4 接线核对结论

| 编号 | 结论 |
|---|---|
| I-1 | **一致**：`boss_controller.gd:338-341` 双参 `get_flag(key, default)`、全件无 `set_flag`；3 个落位逻辑件无 flag / SaveDelta 操作 |
| I-2 | **一致（收敛链路）**：`combat_event_bus.gd` 不定义 I-2 信号，`report_defeat(defeat_id: String, is_boss: bool)` 唯一对外发射点、`emit_signal` 单 `String` 到 `/root/GameEvents`；`boss_controller.gd:296-309` `_die() → _report_defeat()` 交总线；不写 flag、不双写 |
| I-3 | **一致**：3 个落位逻辑件无 `SpawnRequest` 强类型引用；`spawn_request.gd` 头注释声明定义权归 3 号（同名全局类并存见 ③-4） |
| I-4 | **一致**：`boss_controller.gd:348-351` 单点 `set_pose`，pose 名 = `pose_prefix + pose_name`（`p1_`/`p2_`），不写 billboard / 锚定 / 缩放 / `SpriteFrames` |

跨工位只读支撑：Rank-1 `project.godot` `[autoload]` 注册 `WorldState` / `GameEvents`（名称与 2 号 NodePath 一致）；
Rank-3 `scripts/rpg/game_events.gd:8-9` 两信号单 `String`、`scripts/rpg/world_state.gd:51,63` 双参
`get_flag` / `set_flag`。详见 `COMBAT-ASSEMBLY.md` §3.4。

### 2.6 自检判定
- **脚本层 PASS**：零 `SCRIPT ERROR` / `Parse Error`，15 个 `check-only` 全 EXIT=0（12 个落位件全在其中）。
- **数据层装配 PASS**：3 份 `.tres` 修正后段 3 成功加载、ext 路径不悬空；段 1 13 个全局类注册成功。
- **数据自洽 E-8 FAIL（3 项）如实保留为待裁决项**，不冒充全 PASS、不伪造输出。

---

## ③ 未完成项与阻塞

| # | 项 | 性质 | 本轮处置 |
|---|---|---|---|
| 1 | E-8 三项数值冲突（抗性不溢出） | 待总指挥定数值 | **只登记**：未改 `.tres` 数值、未改 `@export` 默认值、未改 `数据表schema.md` §9 口径；A/B/C 方向一律不选定 |
| 2 | `res://data/schema` vs `res://data/schemas` 单复数口径 | 待裁决 | `.tres` 的 `ext_resource` 按 R6 授权修正为 `res://scripts/combat/` 有效路径（装配必需）；**未改** 8 个脚本头注释旧说明、未改任务书 / 文档口径 |
| 3 | 历史 signal 去留 / I-2 唯一发射点收敛 | 待裁决 | 既有 `player_state_machine.gd` 历史声明与旧发射点、`combat_resolver.gd:16` 历史注释差异，**既有件零改动**，登记 |
| 4 | `SpawnRequest` 同名全局类与 3 号并存 | I-3 集成收口待裁决 | 按「8 个 Resource 类脚本落位」照单落位；未删该文件、未改 3 号文件 |
| 5 | 1/3 号 autoload 目标路径不一致 | 跨工位集成项 | 只读核对登记（`project.godot` 指向 `scripts/core|world`、Rank-3 实现落 `scripts/rpg`）；不写 `project.godot`、不移动他人文件 |
| 6 | 补位件 `player_action_table.gd` | 装配必需补位决策 | 既有件只读复制；如总指挥判定超「8 个」字面清单，可**单独删除并回退 1 条 ext 引用**，不影响其余 8+3+3 件；本轮不自行回退 |
| 7 | 既有 3 个逻辑件未落位工程根 | 超本轮清单 / 既有件不重做 | 保留 `Rank-2\` 工位，待后续轮次裁决；真跑临时工程只读复制 validator（收尾已删） |
| 8 | 手感调校 / M5 场景接线 | 契约 §5 不替人做手感与审美判断 | 不调、不接 |

> 以上均为「需总指挥裁决 / 跨工位集成 / 超本工位范围」项，**均不阻塞本轮收尾**；
> 本轮未擅改任何待裁决项、未伪造输出、未覆盖既有文件。
> E-8 冲突在集成前必须裁决，否则数据层 3 项错误会随启动持续出现。

---

## 收尾

- 临时工程 `C:\Users\62668\AppData\Local\Temp\r6_gate_a2\` 及全部日志收尾已删除（复查确认目录不存在）。
- 零付费 / 零外部依赖；未写总线 / 台账 / 总纲 / 契约；未自行 commit / push；中文 UTF-8；
  Godot 4 合法语法；开工必读只读一次。
- **完成标志**：本文件 `DONE-R6.md` + 中枢回执 `{"task_id":"cmd-20261109-022336-998-A2","ai":2,"status":"done"}`
  （已写入 `outbox\` 并被中枢消费归档至 `dispatcher\receipts\`，`status=done` 已生效）。
