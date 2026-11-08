# COMBAT-ASSEMBLY.md —— R6 战斗层装配进工程根（Rank-2）

> 2 号工位 · 战斗系统与数据驱动 · R6 交付件（任务书-R6.md / 调度任务单 `cmd-20261109-022336-998-A2`）。
> 总指挥 02:23 裁决（MSG-20261109-0223-HOST）解除空转保护、授权在 `F:\Game\aierdengfahuan\godot\` 建立统一工程根，
> 2 号独占 `godot\scripts\combat\` + `godot\data\combat\`。
> 中文 UTF-8。本文所有数字均来自本轮本机 Godot 4.7.2 实际输出 / 机器化核对，不引用旧结论冒充、不伪造。

---

## 0. 结论速览

- **落位完成**：`godot\scripts\combat\` 12 个 `.gd`（8 个 Resource 类 + 3 个逻辑件 + 1 个装配闭合补位件）；
  `godot\data\combat\` 3 份 `.tres`。全部为新建文件，未覆盖任何既有文件。
- **ext 路径修正**：3 份 `.tres` 共 11 条 `ext_resource` 由 `res://data/schemas/xxx.gd` 统一修正为
  `res://scripts/combat/xxx.gd`（有效 `res://` 绝对路径）；8 个唯一目标脚本落位存在、缺失 0。
- **数值零改动**：12 个 `.gd` 与工位原件逐字一致（差异 0）；3 份 `.tres` 差异行 10/4/8 全部为
  `ext_resource path` 行，E-8 三项阈值 / 增益 / 上限数值一字未改。
- **真跑四段门禁**：`--version` / `--headless --import` / 15 个 `--check-only --script` /
  `--headless --quit` 全部 EXIT=0；`SCRIPT ERROR` 专项 grep **0 命中**。
- **如实登记**：段 3 `--quit` 由 `CombatDataValidator._ready()` 稳定复现 **4 条 `ERROR:`**（E-8 抗性不溢出
  3 项 FAIL + 1 条汇总，`检查项 491，错误 3`），性质为**数据表自洽校验 `push_error()`**，
  **非 GDScript 解析错误、非运行时 `SCRIPT ERROR`**；不冒充全绿、不伪造输出。
- **待裁决项一律只登记不擅改**：E-8 数值、schema 单复数口径、历史 signal / I-2 唯一发射点收敛、
  `SpawnRequest` 同名全局类并存、1/3 号 autoload 目标路径不一致。

---

## 1. 授权与可写范围（先说清边界）

| 项 | 内容 |
|---|---|
| 授权来源 | MSG-20261109-0223-HOST（02:23 裁决「空转保护解除、任务池重新填充」）+ 任务书-R6.md |
| 唯一可写 | `teamwork\Rank-2\`、`godot\scripts\combat\`、`godot\data\combat\`；回执例外 `command_center\ai\2\outbox\` |
| 明确不写 | `godot\project.godot`（Rank-1 独占）、其它工位 / 其它子目录、总线 / 总纲 / 契约 / 台账；不覆盖既有文件；不自行 git |
| 真跑方式 | 系统临时最小工程（用完即删），理由见 §4.1 |

> 回执路径解析：任务书字面 `command_center\ai\2\outbox\`，工程根下无 `command_center\`；
> 中枢真实空间为 `teamwork\command_center\`（总线 MSG-20261109-0024-HOST「空间切到真实项目
> teamwork/command_center」）。本轮回执写入实际存在的 `teamwork\command_center\ai\2\outbox\`，
> 未在根下另建目录（避免越界写与双份回执）。

---

## 2. `res://` 映射表

### 2.1 A 组：8 个 Resource 类脚本（`Rank-2\schema\` → `godot\scripts\combat\`）

| # | 工位源 | 工程根落位 | `res://` 路径 | `class_name` |
|---|---|---|---|---|
| 1 | `schema/boss_data.gd` | `godot/scripts/combat/boss_data.gd` | `res://scripts/combat/boss_data.gd` | `BossData` |
| 2 | `schema/phase_data.gd` | `godot/scripts/combat/phase_data.gd` | `res://scripts/combat/phase_data.gd` | `PhaseData` |
| 3 | `schema/move_data.gd` | `godot/scripts/combat/move_data.gd` | `res://scripts/combat/move_data.gd` | `MoveData` |
| 4 | `schema/poise_config.gd` | `godot/scripts/combat/poise_config.gd` | `res://scripts/combat/poise_config.gd` | `PoiseConfig` |
| 5 | `schema/status_buildup.gd` | `godot/scripts/combat/status_buildup.gd` | `res://scripts/combat/status_buildup.gd` | `StatusBuildup` |
| 6 | `schema/enemy_data.gd` | `godot/scripts/combat/enemy_data.gd` | `res://scripts/combat/enemy_data.gd` | `EnemyData` |
| 7 | `schema/player_action_data.gd` | `godot/scripts/combat/player_action_data.gd` | `res://scripts/combat/player_action_data.gd` | `PlayerActionData` |
| 8 | `schema/spawn_request.gd` | `godot/scripts/combat/spawn_request.gd` | `res://scripts/combat/spawn_request.gd` | `SpawnRequest` |

### 2.2 B 组：3 个逻辑脚本（`Rank-2\` → `godot\scripts\combat\`）

| # | 工位源 | 工程根落位 | `res://` 路径 | `class_name` |
|---|---|---|---|---|
| 1 | `boss_controller.gd` | `godot/scripts/combat/boss_controller.gd` | `res://scripts/combat/boss_controller.gd` | `BossController` |
| 2 | `combat_event_bus.gd` | `godot/scripts/combat/combat_event_bus.gd` | `res://scripts/combat/combat_event_bus.gd` | `CombatEventBus` |
| 3 | `combat_resolver.gd` | `godot/scripts/combat/combat_resolver.gd` | `res://scripts/combat/combat_resolver.gd` | `CombatResolver` |

### 2.3 C 组：1 个装配闭合补位件（决策登记见 §6.6）

| 工位源 | 工程根落位 | `res://` 路径 | `class_name` |
|---|---|---|---|
| `schema_player_action_table.gd`（R2 既有配套容器类） | `godot/scripts/combat/player_action_table.gd` | `res://scripts/combat/player_action_table.gd` | `PlayerActionTable` |

> **补位理由**：`player_actions.tres` 的 `[resource] script = ExtResource("2_table")` 指向该容器类；
> 若不补落位，则该 `ext_resource` 悬空、`.tres` 不可加载，装配不成立。该件是 R2 既有配套件（非 R3 八类之一），
> 本轮为**只读复制**（内容零改动、不重做），不是新增设计。

### 2.4 D 组：3 份 `.tres`（`Rank-2\` → `godot\data\combat\`）

| 工位源 | 工程根落位 | `res://` 路径 | `script_class` |
|---|---|---|---|
| `boss_01_margit.tres` | `godot/data/combat/boss_01_margit.tres` | `res://data/combat/boss_01_margit.tres` | `BossData` |
| `player_actions.tres` | `godot/data/combat/player_actions.tres` | `res://data/combat/player_actions.tres` | `PlayerActionTable` |
| `enemy_01_limgrave_soldier.tres` | `godot/data/combat/enemy_01_limgrave_soldier.tres` | `res://data/combat/enemy_01_limgrave_soldier.tres` | `EnemyData` |

### 2.5 `ext_resource` 路径修正明细（11 条）

| `.tres` | 条数 | id | 原 `ext_resource path` | 修正后 `ext_resource path` |
|---|---|---|---|---|
| `boss_01_margit.tres` | 5 | `1_boss` / `2_phase` / `3_move` / `4_poise` / `5_status` | `res://data/schemas/*.gd` | `res://scripts/combat/*.gd` |
| `player_actions.tres` | 2 | `1_pa` / `2_table` | `res://data/schemas/*.gd` | `res://scripts/combat/*.gd` |
| `enemy_01_limgrave_soldier.tres` | 4 | `1_enemy` / `2_poise` / `3_move` / `4_status` | `res://data/schemas/*.gd` | `res://scripts/combat/*.gd` |
| **合计** | **11** | — | — | 残留 `data/schemas` 计数 **0** |

修正后 8 个唯一目标脚本（`boss_data` / `phase_data` / `move_data` / `poise_config` /
`status_buildup` / `enemy_data` / `player_action_data` / `player_action_table`）全部落位存在，缺失 0（§4.3 [D]）。

> **口径边界说明**：此修正是依据 R6 授权指定的落位布局（脚本 → `scripts/combat`、数据 → `data/combat`）
> 做的**装配必需动作**，不等于对「单数 / 复数」的裁决。8 个脚本头注释里 `res://data/schemas/` 的旧目标
> 说明、`任务书-R3.md` / `数据表schema.md` 的口径文档**一律未改**；§6.2 的单复数裁决仍归总指挥。
> `.tres` 内 `sprite_frames_path = "res://assets/generated/bosses/..."` 等为资源字段值（非 `ext_resource`），
> 且已是 `res://` 口径，本轮不动。

---

## 3. 装配自检

### 3.1 落位件清单（15 个工程根文件，全部新建）

- `godot\scripts\combat\`：12 个 `.gd`（A 组 8 + B 组 3 + C 组 1）。
- `godot\data\combat\`：3 份 `.tres`（D 组）。
- 落位前两个目录均不存在，故为全新创建；未覆盖任何既有文件。
- **引擎伴随文件（非本轮写入）**：真实工程根 `godot\scripts\combat\` 下除 12 个 `.gd` 外，另有 12 个同名
  `.gd.uid`（Godot 4.4+ 脚本 UID 伴随文件），由引擎扫描工程时自动生成（实测时间 02:34，晚于本轮落位
  02:33:43），非 2 号写入、非本轮交付件、属引擎管理；本轮不删除、不改动，不计入交付清单。

### 3.2 `.gd` 逐字一致（既有件零改动）

`diff -q` 对 12 个落位 `.gd` 与其工位原件逐件比对：**差异数 = 0**。
（8 个对照 `Rank-2\schema\`、3 个对照 `Rank-2\` 平铺、1 个对照 `schema_player_action_table.gd`。）

### 3.3 `.tres` 数值零改动

| `.tres` | diff 变化行 | 其中 `ext_resource path` 行 | 数值字段变化 |
|---|---|---|---|
| `boss_01_margit.tres` | 10（5 删 + 5 增） | 10 | 0 |
| `player_actions.tres` | 4（2 删 + 2 增） | 4 | 0 |
| `enemy_01_limgrave_soldier.tres` | 8（4 删 + 4 增） | 8 | 0 |

`load_steps`（16 / 11 / 7）、`sub_resource` 声明、`ExtResource` / `SubResource` 引用 id、全部数值字段一字未改。
E-8 三项数值实测仍为 `180.0/25.0/330.0`、`210.0/30.0/360.0`、`160.0/30.0/320.0`（与 R5 登记一致）。

### 3.4 I-1~I-4 接线核对（对 3 个落位逻辑件）

| 编号 | 契约口径 | 落位件实际 | 结论 |
|---|---|---|---|
| I-1 | 只用 `WorldState.get_flag(key, default)` / `set_flag(key, value)`，双参、调用方自行 cast；2 号不写存档 / 不碰 SaveDelta | `boss_controller.gd:338-341` `_read_world_flag(key, default_value)` 双参 `call("get_flag", key, default_value)`；全件无 `set_flag`；`combat_event_bus.gd` / `combat_resolver.gd` 无 flag 操作 | **一致** |
| I-2 | 信号挂 `GameEvents` autoload、参数单个 `String`、击杀 flag 只由 3 号写、2 号不双写、唯一发射点 | `combat_event_bus.gd` 不定义 I-2 信号；`report_defeat(defeat_id: String, is_boss: bool)` 为唯一对外发射点，`bus.emit_signal(signal_name, defeat_id)` 单 `String` 到 `/root/GameEvents`；`boss_controller.gd:296-309` `_die() → _report_defeat() → _event_bus.call("report_defeat", ...)`；autoload 缺失降级 `push_warning` 且不回退本地信号 | **一致（收敛链路）** |
| I-3 | `SpawnRequest` 17 字段以 3 号《接口契约.md》§3 为唯一定义，2 号消费不定义 | `boss_controller.gd:30-31` 头注释「本控制器不定义 / 不读取 SpawnRequest 字段」；3 个落位逻辑件无 `SpawnRequest` 强类型引用；`spawn_request.gd` 头注释声明定义权归 3 号、落完整工程不重复挂载同名全局类 | **一致**（同名全局类并存见 §6.4） |
| I-4 | 只调 `set_pose(pose_name, frame_index)`，pose 名按冻结表加 `p1_`/`p2_` 前缀 | `boss_controller.gd:348-351` `_apply_pose()` 单点 `set_pose`；pose 名 = `PhaseData.pose_prefix + MoveData.pose_name`（`:128/:149/:215/:225/:300`），前缀取 `p1_`/`p2_`；不写 billboard / 锚定 / 缩放 / `SpriteFrames` | **一致** |

**跨工位只读核对（支撑 I-1 / I-2）**：

- Rank-1 `godot\project.godot` `[autoload]`（32-38 行）注册 `WorldState` / `GameEvents` / `SaveSystem` /
  `ChunkManager` / `SceneRouter`，autoload 名与 2 号落位件 NodePath `/root/WorldState`
  （`boss_controller.gd:57`）、`/root/GameEvents`（`combat_event_bus.gd:32`）一致。
- Rank-3 `godot\scripts\rpg\game_events.gd:8-9` 定义 `signal enemy_defeated(enemy_id: String)` /
  `signal boss_defeated(boss_id: String)`（均单 `String`）；`godot\scripts\rpg\world_state.gd:51,63`
  定义 `get_flag(key, default)` / `set_flag(key, value)`（双参）—— 与 2 号调用侧一致。
- **路径不一致（跨工位集成项，只登记不擅改，见 §6.5）**：`project.godot` autoload 指向
  `res://scripts/core/game_events.gd` / `res://scripts/world/world_state.gd` / `res://scripts/world/save_system.gd`，
  而上述实现实际落在 `res://scripts/rpg/`；`godot\scripts\core\` 与 `godot\scripts\world\` 下未见对应文件。
  属 1/3 号集成收口，2 号不写 `project.godot`、不移动他人文件。

---

## 4. 真跑（三段门禁 + `--version`，本机实际输出）

### 4.1 环境与方式选择

- 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`，`--version` 实测 `4.7.2.stable.official.ed1daf0bf`（EXIT=0）。
- 临时工程：`C:\Users\62668\AppData\Local\Temp\r6_gate_a2\`，**收尾已删除**（复查确认目录不存在）。
- **为何仍用临时工程**：任务书假设 `godot\project.godot` 尚未就位并授权「可在系统临时最小工程验证，
  用完即删」；实际开工核查发现 Rank-1 已于 02:28 落位 `project.godot`。但 `--headless --import` 会在真实
  工程根写 `.godot\` 缓存（超出 2 号唯一可写范围），且四路工位正并行写入同一工程根、真实工程根当前还存在
  §3.4 的跨工位 autoload 目标缺失。故本轮按授权采用临时最小工程、**镜像落位布局**验证，避免越界写缓存与
  跨工位干扰；**落位成果本身在真实工程根**，临时工程只是验证环境。
- 布局：`scripts/combat/` 12 个落位 `.gd` + `combat_data_validator.gd`（既有件只读复制，E-8 复现用）；
  `data/combat/` 3 份修正后的 `.tres`；`autoload/game_events.gd`（I-2 接口桩）、`gate/r6_gate_runner.gd`
  （段 3 挂载件）、`main.tscn`（声明 3 份 `.tres` 为场景依赖）、`project.godot`（`config_version=5`、
  `run/main_scene="res://main.tscn"`、`GameEvents` autoload）。
- 门禁件（`autoload` 桩 / runner / `main.tscn` / `project.godot`）仅存在于临时工程，为门禁配置与真跑挂载件，
  **非探针 / 非测量 / 非 preflight 脚本**，收尾随临时工程删除；工位落位件与既有件零改动。

### 4.2 四段门禁实际输出

| 段 | 命令 | 退出码 | 实际输出 |
|---|---|---|---|
| 0 | `Godot_v4.7.2-stable_win64.exe --version` | **0** | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `... --headless --path <gate> --import` | **0** | 34 行；`first_scan_filesystem` 5 步 DONE；`update_scripts_classes`（15 steps）注册 **13 个全局类名**（`BossController` / `BossData` / `CombatDataValidator` / `CombatEventBus` / `CombatResolver` / `EnemyData` / `MoveData` / `PhaseData` / `PlayerActionData` / `PlayerActionTable` / `PoiseConfig` / `SpawnRequest` / `StatusBuildup`；另 2 个无 `class_name` 门禁件）；`loading_editor_layout` DONE；无 ERROR |
| 2 | `... --headless --path <gate> --check-only --script res://<各 .gd>`（15 个） | `SEG2_SCRIPTS=15 SEG2_FAIL=0` | 15 个脚本全部解析通过（其中 **12 个落位件全部 EXIT=0**） |
| 3 | `... --headless --path <gate> --quit` | **0** | 打开工程、加载 `main.tscn` 及 3 份 `.tres`、触发 `CombatDataValidator._ready()` 实跑后退出 |

### 4.3 `SCRIPT ERROR` grep 与机器化核对（工具链 §4.2：运行时错误不改退出码，必须 grep）

合并 4 段日志为 `log_all.txt`（**95 行**）后：

| 检查 | 范围 | 结果 |
|---|---|---|
| [A] `SCRIPT ERROR` 专项 `grep -nEi "SCRIPT ERROR"` | 全 95 行 | **0 命中（RC=1）** |
| [B] 宽口径 `SCRIPT ERROR\|Parse Error\|ERROR:\|Failed\|Cannot\|dangling\|悬空\|Invalid\|not found\|Can't` | 全 95 行 | **4 条 `ERROR:`**（行 68 / 75 / 82 / 90，全部来自段 3），见 §4.4 |
| [C] 宽口径（排除段 3） | 段 0 + 段 1 + 段 2 日志 | **0 命中（RC=1）** |
| [D] ext 路径存在性 | 8 个唯一目标脚本 | **8/8 存在，缺失 0** |
| [E] E-8 数值 | `boss_01_margit.tres` | `180/25/330`、`210/30/360`、`160/30/320`，与 R5 一致、**未改** |
| [F] 12 个落位 `.gd` vs 工位原件 | `diff -q` | **差异 0** |
| [G] 3 份 `.tres` diff 性质 | 变化行 10 / 4 / 8 | **全部为 `ext_resource path` 行**，数值字段变化 0 |

### 4.4 段 3 E-8 实际 ERROR 输出（如实保留原文）

```
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_01_bleed
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ok (res://scripts/combat/combat_data_validator.gd:86)
       [1] _validate_e8 (res://scripts/combat/combat_data_validator.gd:213)
       [2] _ready (res://scripts/combat/combat_data_validator.gd:75)
       [3] _ready (res://gate/r6_gate_runner.gd:14)
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_02_poison
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ok (res://scripts/combat/combat_data_validator.gd:86)
       [1] _validate_e8 (res://scripts/combat/combat_data_validator.gd:213)
       [2] _ready (res://scripts/combat/combat_data_validator.gd:75)
       [3] _ready (res://gate/r6_gate_runner.gd:14)
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_03_frost
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ok (res://scripts/combat/combat_data_validator.gd:86)
       [1] _validate_e8 (res://scripts/combat/combat_data_validator.gd:213)
       [2] _ready (res://scripts/combat/combat_data_validator.gd:75)
       [3] _ready (res://gate/r6_gate_runner.gd:14)
[CombatDataValidator] E-1/E-3/E-4/E-5/E-8/E-9 检查项 491，错误 3
ERROR: [CombatDataValidator] 数据表自洽校验失败，错误 3 项
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/combat/combat_data_validator.gd:79)
       [1] _ready (res://gate/r6_gate_runner.gd:14)
[R6-GATE] CombatDataValidator._ready() 已触发，挂载 3 份 .tres（boss/enemy/player_actions）
```

> **性质判定**：4 条均由 `CombatDataValidator` 的 `push_error()` 输出（backtrace 指向
> `core/variant/variant_utility.cpp:1023`），是**数据表自洽校验 FAIL**，
> **不是 GDScript 解析错误、不是运行时 `SCRIPT ERROR`**（专项 grep 0 命中、段 3 退出码仍为 0）。
> E-1 / E-3 / E-4 / E-5 / E-9 通过，E-8「抗性不溢出」3 项 FAIL。
> 脚本层通过、数据层 3 项冲突如实保留，**不冒充全 PASS**。

### 4.5 自检判定

| 层 | 结论 |
|---|---|
| 脚本层 | **PASS**：零 `SCRIPT ERROR` / `Parse Error`，15 个 `check-only` 全 EXIT=0（12 个落位件全在其中） |
| 数据层装配 | **PASS**：3 份 `.tres` 修正后段 3 成功加载（无 `Failed` / `not found` / `dangling`），ext 路径不悬空；段 1 13 个全局类注册成功 |
| 数据自洽 | **E-8 FAIL（3 项）如实保留为待裁决项**，不冒充全 PASS |

---

## 5. E-8 待裁决项 · 保留登记（本轮真跑再次实证，沿用 `R5-待裁决登记.md`）

校验式（`combat_data_validator.gd:212-213`）：
`threshold + resistance_gain_per_trigger × resistance_sample_triggers(默认 8) <= max_resistance`

| 异常 id | threshold | gain | ×8 后 | max_resistance | 结论 |
|---|---|---|---|---|---|
| `status_01_bleed` | 180.0 | 25.0 | **380.0** | 330.0 | 380 > 330 → **FAIL** |
| `status_02_poison` | 210.0 | 30.0 | **450.0** | 360.0 | 450 > 360 → **FAIL** |
| `status_03_frost` | 160.0 | 30.0 | **400.0** | 320.0 | 400 > 320 → **FAIL** |

数值来源：落位后 `godot\data\combat\boss_01_margit.tres` 的 `Resource_status_bleed` /
`Resource_status_poison` / `Resource_status_frost` 三个 sub_resource（本轮 [E] 实测未改）。

- 候选方向 A（改 3 组 `max_resistance` 使其 ≥ 380/450/400）/ B（调小 `@export resistance_sample_triggers`）
  / C（修订 `数据表schema.md` §9 E-8 校验式）**一律不选定、不排序、不推荐、不实施**。
- 本轮处置：**只登记**；未改任何 `.tres` 数值、未改 `combat_data_validator.gd` 的 `@export` 默认值、
  未改 `数据表schema.md` §9 口径。任何方向都需总指挥明确数值 / 口径后由后续轮次执行。

---

## 6. 其余待裁决 / 超范围项（一律只登记不擅改）

### 6.1 E-8 数值冲突
见 §5。待总指挥定数值，本轮未改 `.tres`。

### 6.2 `res://data/schema`（单数） vs `res://data/schemas`（复数）口径
- 差异事实（沿用 `R4-口径与阻塞登记.md` §1 / `R5-待裁决登记.md` §6.2，未改动）：
  `任务书-R3.md` §2 字面单数；`数据表schema.md` §0.1、8 个脚本头注释、3 份 `.tres` 原 11 条
  `ext_resource` 均为复数。
- 本轮按 R6 授权把 `.tres` 的 `ext_resource` 修正为 `res://scripts/combat/`（装配必需的有效路径），
  **未改** 8 个脚本头注释旧说明、未改 `任务书-R3.md` / `数据表schema.md`。单复数裁决仍归总指挥。

### 6.3 历史 signal 去留 / I-2 唯一发射点收敛
- 现状：既有 `player_state_machine.gd:29-30` 仍声明 `signal enemy_defeated` / `signal boss_defeated`、
  `:304-310` 仍保留旧 `report_defeat` 本地 `emit`；R4 新增 `CombatEventBus`（本轮落位）收敛对外发射，
  既有件零改动。
- 另：落位的 `combat_resolver.gd:16` 头注释仍写「击杀由 `PlayerStateMachine.report_defeat()` 唯一发射点
  处理」（R2 历史口径，与 R4 收敛为 `CombatEventBus` 不一致）—— 属注释层历史差异，既有件零改动。
- 删除 / 保留该历史声明与旧发射点、统一注释口径需改既有件，超出「既有件不重做、不擅改」边界，**登记待裁决**。

### 6.4 `SpawnRequest` 同名全局类与 3 号并存（I-3 集成收口）
- `spawn_request.gd`（`class_name SpawnRequest`）随 8 个 Resource 类按授权落位 `scripts/combat/`；
  其头注释声明「定义权归 3 号、落完整工程时 2 号不重复挂载同名全局类」。
- 真实工程根若 3 号也在 `scripts/rpg/` 挂 `class_name SpawnRequest`，`--import` 会触发全局类重复注册。
- 属 I-3 跨工位集成待裁决；本轮按「8 个 Resource 类脚本落位」照单落位，未删该文件、未改 3 号文件。

### 6.5 1/3 号 autoload 目标路径不一致（跨工位集成项）
见 §3.4：`project.godot` autoload 指向 `scripts/core` / `scripts/world`，Rank-3 实现实际落在 `scripts/rpg`。
2 号只做只读核对登记，不写 `project.godot`（Rank-1 独占）、不移动他人文件。

### 6.6 补位件 `player_action_table.gd` 决策（需总指挥知悉 / 可回退）
- 任务书字面为「8 个 Resource 类脚本」；本轮为让 `player_actions.tres` 不悬空，另补落位 1 个 R2 既有
  配套容器类（只读复制、内容零改动、不覆盖既有文件）。
- 若总指挥判定超出字面清单，可**单独删除** `godot\scripts\combat\player_action_table.gd` 并回退
  `player_actions.tres` 的第 `2_table` 条 `ext_resource`，不影响其余 8 + 3 + 3 件；本轮不自行回退。

### 6.7 未纳入本轮落位清单的既有逻辑件
`combat_data_validator.gd` / `enemy_director.gd` / `player_state_machine.gd` 仍保留在 `Rank-2\` 工位，
按「既有件不重做」本轮未落位工程根；真跑临时工程只读复制 validator 用于 E-8 复现（收尾已删）。
是否落位待后续轮次裁决。

### 6.8 手感调校 / M5 集成
契约 §5「WorkBuddy 不替人做手感与审美判断」；本轮不调手感、不做 M5 场景接线。

---

## 7. 未完成项与阻塞

- §5 / §6 全部为「需总指挥裁决 / 跨工位集成 / 超本工位范围」项，**均不阻塞本轮收尾**。
- 真实工程根直接 `--quit` 尚存 §6.5 跨工位 autoload 目标缺失（1/3 号之间），2 号不越界修复；
  本轮真跑在镜像临时工程完成，已如实说明方式选择（§4.1）。
- E-8 冲突在集成前必须裁决，否则数据层 3 项错误会随启动持续出现；本轮不擅改。

---

## 8. 收尾口径

- 本轮新增 / 落位：工程根 15 个文件（12 `.gd` + 3 份 `.tres`）、`COMBAT-ASSEMBLY.md`（本文件）、
  `DONE-R6.md`、中枢回执；**工位既有交付件零改动**。
- **回执流转（如实登记）**：回执 `{"task_id":"cmd-20261109-022336-998-A2","ai":2,"status":"done"}`
  已写入 `teamwork\command_center\ai\2\outbox\` 并被中枢正常消费，归档于
  `teamwork\command_center\dispatcher\receipts\cmd-20261109-022336-998-A2.json`（内容一致、JSON 解析通过、
  `result` 714 字）；中枢 `ai\2\status.json` 实测更新为 `state=idle / completed=7 / last_seen 02:46:18`。
  因中枢持续轮询消费导致 `outbox\` 再度为空，本轮曾补写一份留档，中枢二次归档为带时间戳备份
  `cmd-...json.20261109-024618-805`（同内容，1237 字节）。回执已生效，不再重复补写；该备份由中枢生成，
  不在 2 号可写范围，未删除、未改动。
- 临时工程 `C:\Users\62668\AppData\Local\Temp\r6_gate_a2\` 与全部日志收尾已删除（复查确认目录不存在）；
  结论已抄录进本文件与 `DONE-R6.md`。
- 零付费 / 零外部依赖；未写总线 / 台账 / 总纲 / 契约；未自行 commit / push；中文 UTF-8；
  Godot 4 合法语法；开工必读只读一次。
- **待裁决项一律未擅改、未选定、未伪造输出。**
