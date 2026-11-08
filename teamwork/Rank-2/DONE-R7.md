# DONE-R7.md —— Rank-2（战斗系统与数据驱动）R7 战斗层跨模块联调

> 2 号工位 · R7 完成标志（任务书 `任务书-R7.md` / 调度任务单 `cmd-20261109-024906-801-A2`，
> HOST 派单见 `00-群聊总线.md` MSG-20261109-0249-HOST）。
> 唯一可写：`teamwork\Rank-2\`、`godot\scripts\combat\`、`godot\data\combat\`；
> 回执例外 `command_center\ai\2\outbox\`。**不写 `godot\project.godot`（Rank-1 独占）**、
> 不写其它工位 / 子目录、不覆盖既有文件、不写总线 / 总纲 / 契约 / 台账、不自行 git。
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（`--version` 实测
> `4.7.2.stable.official.ed1daf0bf`，EXIT=0）。
> 本文所有数字 / 输出均来自本轮本机 Godot 4.7.2 实际输出与机器化核对，不引用旧结论冒充、
> 不伪造、不冒充全绿。中文 UTF-8。

---

## 0. 结论速览

| 交付项 | 状态 | 实际结论 |
|---|---|---|
| ① I-2 接线实跑验证 | **完成** | 临时镜像工程四段门禁全 EXIT=0，接线 runner `[I2-VERIFY] RESULT=PASS checks=6 fail=0`；`SCRIPT ERROR` 专项 / 宽口径 grep 均 **0 命中** |
| ② `boss_controller.gd` 追加式接入 `courtyard.tscn` | **完成** | 追加式构建脚本真跑 `ATTACH_OK`，20→25 节点、probe 25=25、`courtyard.tscn` sha256 前后**完全一致（未覆盖）** |
| ③ E-8 三项冲突二选一 | **完成（选择「继续如实登记待裁决」）** | 选择依据见 §4；三字段数值与工位原件**差异=0**，未改任何 `.tres` / 脚本 / 口径文档 |
| ④ `godot\` 全工程门禁复跑 | **完成** | 三段门禁 EXIT=0（段 2 `50 个 .gd / FAIL=1`）；**战斗层 R7 新增件零新增 ERROR**；现存跨工位 `SCRIPT ERROR` 逐条如实登记，不冒充全绿 |
| `DONE-R7.md` / `I2-WIRING.md` / 回执 | **完成** | 本文件 + `I2-WIRING.md` 已写；回执按任务单 id 写入 `teamwork\command_center\ai\2\outbox\` |

完成标志：`status=done`，回执 `task_id=cmd-20261109-024906-801-A2`。

---

## 1. 实际交付清单

### 1.1 本轮新建文件（全部新建，未覆盖任何既有文件）

| # | 文件 | 落位 / 大小 | 说明 |
|---|---|---|---|
| 1 | `teamwork\Rank-2\I2-WIRING.md` | 工位 | I-2 接线验证记录：链路、真跑环境、6 项检查原文、grep 结论、时间线更正 |
| 2 | `teamwork\Rank-2\DONE-R7.md` | 工位（本文件） | ①实际交付清单 ②自检含真跑输出结论 ③未完成项与阻塞 |
| 3 | `godot\scripts\combat\attach_boss_to_courtyard.gd` | 战斗层（新建） | 追加式构建脚本（`extends SceneTree`）：只读加载既有 `courtyard.tscn` → 在 `ChunkRoot` 追加 Boss 敌人节点 → pack/instantiate 校验 → 另存新场景 |
| 4 | `godot\data\combat\courtyard_with_boss.tscn` | 战斗层数据目录（新建，5825 B） | 由 #3 真跑生成的独立场景产物，25 节点；含 `BossController` + `CombatEventBus` + `Hybrid2D3DAnimatedSprite` 兄弟节点与 `boss_data` 注入 |
| 5 | `teamwork\command_center\ai\2\outbox\cmd-20261109-024906-801-A2.json` | 回执例外 | 完成回执 JSON |

### 1.2 明确未改动（机器化核对）

- `godot\scripts\combat\` 既有 12 个 `.gd`、`godot\data\combat\` 既有 3 份 `.tres`：**零改动**（`.tres` E-8 三字段数值行 `diff` 差异=0）。
- `godot\scenes\courtyard.tscn`：sha256 跑前 / 跑后同为
  `217b2f4ade3ba21b9166ba9b3fd368d0d7726f1c4756977ebb524d0c99fb6d34` → `HASH_EQUAL=YES`。
- `godot\scenes\Main.tscn`、`godot\project.godot`、`godot\scripts\render\hybrid_2d3d_animated_sprite.gd`、
  Rank-3 `scripts\rpg\*`：**只读引用 / 只读核对，未写**。
- 工位既有交付件（`R5-待裁决登记.md` / `COMBAT-ASSEMBLY.md` / `DONE-R*.md` / `schema\` / `*.tres` /
  `*.gd` / `motion-mapping.md` 等）：**零改动**。
- 未写总线 / 总纲 / 契约 / 台账；未自行 commit / push；零付费 / 零外部依赖。

---

## 2. 交付项 ①：I-2 接线实跑验证（详见 `I2-WIRING.md`）

### 2.1 验证内容

`combat_event_bus.gd` 与 Rank-3 `GameEvents` autoload 的 I-2 接线，两个硬指标：
**单 String 信号**、**击杀 flag 不由 2 号双写**。

真实链路（`I2-WIRING.md` §1）：
`BossController._die()`（`boss_controller.gd:296-309`）→
`CombatEventBus.report_defeat(defeat_id: String, is_boss: bool)`（`combat_event_bus.gd:42`，2 号唯一发射点）
→ `bus.emit_signal(signal_name, defeat_id)` 到 `/root/GameEvents`（单 String）→
Rank-3 `game_events.gd:8-9` 的 `enemy_defeated(String)` / `boss_defeated(String)` →
Rank-3 `save_delta_writer.gd:53-56` 订阅并 `set_flag`（击杀 flag 只由 3 号写）。
2 号链路仅 `boss_controller.gd:338-341` 的只读 `get_flag(key, default)`，**无 `set_flag`**。

### 2.2 真跑实际输出（临时镜像工程，`C:\Users\62668\AppData\Local\Temp\r7_i2_gate_a2\`）

| 段 | 命令 | 退出码 | 实际输出 |
|---|---|---|---|
| 0 | `--version` | **0** | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `--headless --path <gate> --import` | **0** | `first_scan_filesystem` 5 步 DONE；`update_scripts_classes (16 steps)` 注册 13 个全局类名；`loading_editor_layout` DONE；无 ERROR |
| 2 | `--check-only --script`（16 个 `.gd`） | `SEG2_SCRIPTS=16 SEG2_FAIL=0` | 12 个 2 号落位件 + 3 个 3 号件 / 桩 + 1 个 runner 全 EXIT=0 |
| 3 | `--headless --path <gate> --quit` | **0** | 触发 runner，6 项检查后退出 |

段 3 原文（如实保留）：

```
[I2-DETAIL] signal enemy_defeated args=1
[I2-DETAIL] signal boss_defeated args=1
[I2-CHECK] C1 GameEvents 运行时信号表单 String 参数 -> PASS
[I2-CHECK] C2 单形参 Callable 连接 enemy/boss_defeated -> PASS
[BossController] 阶段装载 -> phase_index=1 pose_prefix=p1_ 招式数=2
[I2-CHECK] C3 report_defeat(enemy) -> enemy_defeated 单 String=数据表 id -> PASS
[I2-DETAIL] enemy_defeated args=1 value=["enemy_09_i2_probe"]
[BossController] Boss 被击败 -> id=boss_01_margit（I-2 交给 CombatEventBus）
[I2-CHECK] C4 BossController 击杀 -> boss_defeated 单 String=数据表 id -> PASS
[I2-DETAIL] boss_defeated args=1 value=["boss_01_margit"] (boss_data.id=boss_01_margit)
[I2-CHECK] C5 击杀 flag combat.<boss_id>.defeated 由 3 号订阅方写入 -> PASS
[I2-DETAIL] WorldState.set_flag 调用 keys=["combat.enemy_09_i2_probe.defeated", "combat.boss_01_margit.defeated", "combat.boss_01_margit.phase_two_ready"]（写入方=3号 SaveDeltaWriter）
[I2-CHECK] C6 2 号落位件源码零 set_flag( 调用（不双写） -> PASS
[I2-VERIFY] RESULT=PASS checks=6 fail=0
```

grep（合并 4 段日志 **60 行**）：
`SCRIPT ERROR` 专项 **0 命中（RC=1）**；
宽口径 `SCRIPT ERROR|Parse Error|ERROR:|Failed|Cannot|dangling|悬空|Invalid|not found|Can't`
**0 命中（RC=1）**。

> 临时工程用 I-1 / I-4 替身桩（`I2-WIRING.md` §2.3）以避免落盘与跨工位依赖；
> 2 号 / 3 号真实件逐字复制。验证在系统临时目录完成、收尾已删除，
> 不写真实工程根 `.godot\` 缓存、不越界。

---

## 3. 交付项 ②：`boss_controller.gd` 追加式接入 `courtyard.tscn`

### 3.1 接入点（明确说明）

- **既有场景**：`res://scenes/courtyard.tscn`（`godot\scenes\courtyard.tscn`），20 节点。
  R7 开工实测 `grep -niE "enemy|boss|spawn|defeat"` **0 命中**——**场景里没有现成的敌人节点**。
- **接入点**：`SubViewportContainer/SubViewport/ChunkRoot`。
  依据 `godot\scripts\build_courtyard.gd:173-176`：`ChunkRoot` 是「空 Node3D，脚本由
  `ChunkManager` autoload 持有，避免双实例」，即 I-3 敌人 / chunk 动态生成的预留锚点；
  它与 `Player` 同为 `SubViewport` 直接子节点，3D 世界层级正确。
- **追加方式**：不改既有节点、不写回 `courtyard.tscn`。`attach_boss_to_courtyard.gd`
  只读 `load()` + `instantiate()`，以 `add_child()` 在 `ChunkRoot` 下追加 `BossEnemy_01`，
  另存为**新场景** `res://data/combat/courtyard_with_boss.tscn`（落在 2 号可写范围）。
  即「追加式构建脚本 + 独立场景实例化产物」，二者都不覆盖既有场景。

追加节点树（三个逻辑子节点互为兄弟，满足 `boss_controller.gd:55-56` 的 `../` 相对 NodePath）：

```
ChunkRoot
└── BossEnemy_01 (Node3D)                       ← 追加的敌人根节点
    ├── Hybrid2D3DAnimatedSprite (Node3D)      ← 只读挂 Rank-1 hybrid_2d3d_animated_sprite.gd
    │   └── PixelSprite (Sprite3D)
    ├── CombatEventBus (Node)                  ← 挂 combat_event_bus.gd（I-2 唯一发射点）
    └── BossController (Node)                  ← 挂 boss_controller.gd，boss_data=boss_01_margit.tres
```

### 3.2 真跑实际输出（真实 `godot\` 工程根）

```
[attach-boss] ATTACH_OK source=res://scenes/courtyard.tscn (只读加载, 未覆盖) output=res://data/combat/courtyard_with_boss.tscn
[attach-boss] 接入点=SubViewportContainer/SubViewport/ChunkRoot/BossEnemy_01 before_nodes=20 after_nodes=25 added=5 probe_nodes=25 probe_ok=true
```

- `ATTACH_RC=0`；`pack → instantiate` 节点数 **25=25**、结构 `probe_ok=true`。
- `courtyard.tscn` sha256 跑前 / 跑后同为
  `217b2f4ade3ba21b9166ba9b3fd368d0d7726f1c4756977ebb524d0c99fb6d34` → **HASH_EQUAL=YES（未覆盖）**。
- 新场景 25 节点，4 条 `ext_resource` 目标机器化核对 **4/4 EXIST**：
  `scripts/render/hybrid_2d3d_animated_sprite.gd`、`scripts/combat/combat_event_bus.gd`、
  `scripts/combat/boss_controller.gd`、`data/combat/boss_01_margit.tres`；
  `BossController` 节点 `boss_data = ExtResource("4_7hl0m")` 注入成功。
- 该脚本单独 `--check-only --script` **EXIT=0**。
- 接入脚本真跑（真实工程根 `--script` 模式）另产生的跨工位 ERROR / WARNING 见 §5.3，
  不影响 `ATTACH_OK` 结论。

---

## 4. 交付项 ③：E-8 三项冲突 · 二选一决策

### 4.1 选择：**继续如实登记待裁决**（不采纳「修正方案并改数据表阈值常量」）

### 4.2 选择依据（写清楚）

1. **总线裁决（唯一真源，优先级最高）**：`00-群聊总线.md`
   MSG-20261109-0223-HOST（02:23 总指挥裁决）明文「待裁决项（**E-8 数值**、schema 路径、
   §4.4 措辞、chunk flag 口径）只登记不擅改」；MSG-20261109-0249-HOST（02:49，本轮派单来源）
   再次「待裁决项只登记不擅改」。`00-群聊总线.md` 头部声明本文件是**唯一真源**。
2. **本轮任务书自身硬约束**：`任务书-R7.md` §硬性约束 与用户 R7 指令的「硬性约束」
   均明确「**待裁决项只登记不擅改**」；契约 `00-协作契约.md` §1「三者冲突时以本契约为准」、
   §7「跨模块需求冲突 → 只写进待裁决，任何执行 AI 不得自行修改」。
3. **总指挥从未给出具体数值 / 口径**：`R5-待裁决登记.md` §4 明确 A/B/C 三方向
   「不选定、不排序、不推荐、不实施」，且「无论选哪个方向，执行前均须明确：
   改哪些具体数值 / 是否同步改 E-8 式文档 / 是否连带改 `resistance_sample_triggers` 默认值」。
   R7 任务书虽给出「只改数据表阈值常量」的选项，但**未指定**改哪个字段、改成多少、
   是否同步改校验口径；`COMBAT-ASSEMBLY.md` §5 亦在 R6 再次「只登记」。
4. **属数值设计裁决，2 号不代为判断**：`R5-待裁决登记.md` §3.3「数值如何落定会改变
   bleed / poison / frost 的异常触发难度曲线，属数值设计裁决」；契约 §5
   「WorkBuddy 不替人做手感与审美判断」。契约 §5「数据表改数值不改代码」是一般开发原则，
   **不覆盖**「待裁决项须总指挥明确数值 / 口径后方可执行」的前置条件。
5. **「修正方案」选项与更高优先级约束冲突**：若本轮实施「只改数据表阈值常量」，
   等价于把 HOST 明令「只登记不擅改」的待裁决项擅自裁决并执行；括号里「不擅改脚本或
   伤害数值」只排除了脚本 / 伤害，未解除「不擅改待裁决数值」这一核心约束。
   R5 / R6 已连续两轮如实登记，R7 无新的总指挥数值裁决，2 号不改变处置口径。
6. **改数值可能连带改口径文档**：E-8 校验式见 `数据表schema.md` §9 与
   `combat_data_validator.gd:212-213`，`R5-待裁决登记.md` 候选方向 C 明确修订校验式
   需总指挥裁决、需同步复核 validator 实现，超出「只改数据表阈值常量」的字面授权。

### 4.3 本轮实际处置（零改动实证）

- 工程根 `godot\data\combat\boss_01_margit.tres` 三组数值实测：
  `threshold=180.0 / gain=25.0 / max_resistance=330.0`、
  `210.0 / 30.0 / 360.0`、`160.0 / 30.0 / 320.0`
  （与 `R5-待裁决登记.md` §2.5、`COMBAT-ASSEMBLY.md` §5 一致）。
- 与工位原件 `Rank-2\boss_01_margit.tres` 的 `threshold / gain / max_resistance`
  数值行 `diff` → **数值行差异=0**；未改任何 `.tres` 数值、未改 `combat_data_validator.gd`
  的 `@export` 默认值、未改 `数据表schema.md` §9 口径。
- `combat_data_validator.gd` **未落位工程根**（`COMBAT-ASSEMBLY.md` §6.7），
  故本轮全工程门禁日志 `grep -nEi "CombatDataValidator|E-8|检查项"` **0 命中（RC=1）**，
  未复现 R5/R6 段 3 的 4 条 `ERROR:`；**这不代表 E-8 已解决**，只是 validator 未随工程启动。
  该冲突在集成前仍需总指挥裁决，否则落位 validator 后数据层 3 项错误会随启动持续出现。
- 沿用 `R5-待裁决登记.md` §4 三方向登记（A 改 3 组 `max_resistance` /
  B 调小 `resistance_sample_triggers` / C 修订 E-8 校验式），**一律不选定、不排序、
  不推荐、不实施、非本轮新裁决**。

---

## 5. 交付项 ④：`godot\` 全工程门禁复跑 + 跨工位 ERROR 如实登记

### 5.1 四段门禁实际输出（真实 `godot\` 工程根，非临时镜像）

| 段 | 命令 | 退出码 | 实际输出 |
|---|---|---|---|
| 0 | `--version` | **0** | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `--headless --path godot --import` | **0** | `first_scan_filesystem` 5 步 DONE、`update_scripts_classes (3 steps)`、`loading_editor_layout` DONE；无 ERROR（含新 `.tscn` 扫描，无 dangling / not found） |
| 2 | `--check-only --script` 全工程 **50 个 `.gd`** | `SEG2_SCRIPTS=50 SEG2_FAIL=1` | 唯一 FAIL：`res://scripts/rpg/spawn_request.gd`（见 §5.3） |
| 3 | `--headless --path godot --quit` | **0** | 打开工程、加载 `Main.tscn`、autoload `_ready()` 实跑；输出见 §5.3 |

> 方式说明：任务书 §真跑要求明确「三段门禁」且本项要求「对 `godot\` 全工程门禁复跑」，
> 故本项在**真实工程根**执行（与交付项 ① 的临时镜像验证分开）。`--import` 更新的是
> 已存在的 `godot\.godot\` 引擎缓存（`.gitignore` 排除、Rank-1 同工程根亦在跑），
> 属引擎管理文件、非 2 号交付件、未覆盖任何源码 / 既有文件。

### 5.2 grep 与机器化核对（日志 **51 行**）

| 检查 | 结果 |
|---|---|
| [A] `SCRIPT ERROR` 专项 `grep -nEi` | **2 命中**（行 31 / 39），均为 `Class "SpawnRequest" hides a global script class.` |
| [B] 宽口径（含 `ERROR:` / `WARNING:` / `Failed` / `not found` 等） | **5 命中**：2 条 `SCRIPT ERROR` + 2 条 `ERROR: Failed to load script ...` + 1 条 `WARNING: 2 ObjectDB instances were leaked at exit` |
| [C] 退出码 / 汇总 | `SEG0_RC=0` / `SEG1_RC=0` / `SEG2_SCRIPTS=50 SEG2_FAIL=1` / `SEG3_RC=0` |
| [D] R7 新增件 `attach_boss_to_courtyard.gd` 单独 `--check-only` | **EXIT=0**（无输出错误） |
| [E] 新场景 4 条 `ext_resource` 目标存在性 | **4/4 EXIST** |
| [F] 交付项 ① 临时镜像工程（战斗层单独，无 3 号 `rpg/spawn_request.gd`） | `SCRIPT ERROR\|ERROR:` 计数 **0** |

### 5.3 跨工位 ERROR / WARNING 逐条如实登记（不冒充全绿）

1. **`SCRIPT ERROR: Parse Error: Class "SpawnRequest" hides a global script class.`**
   （`res://scripts/rpg/spawn_request.gd:2`；段 3 backtrace：
   `_register_baseline (res://scripts/rpg/world_state.gd:110)` → `_ready (world_state.gd:35)`）
   根因：2 号 `godot\scripts\combat\spawn_request.gd` 与 3 号
   `godot\scripts\rpg\spawn_request.gd` 均 `class_name SpawnRequest`，同名全局类并存。
   `COMBAT-ASSEMBLY.md` **§6.4 已在 R6 登记为 I-3 跨工位集成待裁决**（当时预测
   「`--import` 会触发全局类重复注册」）。本轮段 2 / 段 3 稳定复现。
   **属 R6 既有落位件并存、非 R7 新增件引入**；2 号不擅自删除 / 改名既有落位件、
   不改 3 号文件、不写 `project.godot`，只登记待裁决。
2. **`ERROR: Failed to load script "res://scripts/rpg/spawn_request.gd" with error "Parse error".`**
   —— 上一条的连带（段 2 FAIL 行 + 段 3 各 1 条）。
3. **`WARNING: 2 ObjectDB instances were leaked at exit`** —— 引擎退出时序告警；
   总线 MSG-20261109-0203-HOST 已把同类 ObjectDB leaked 定位于 ChunkManager 在途加载时序，
   属跨工位 / 引擎行为，2 号不越界修复。
4. 接入脚本真跑（`--script` 模式）另有
   **`WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。`**
   （`res://scripts/world/chunk_streaming.gd:51`）—— `--script` 自定义 MainLoop 下无
   `Main.tscn` 实例所致，跨工位降级 warning；段 3 加载 `Main.tscn` 后未复现。

### 5.4 「战斗层不引入新增 ERROR」判定

- 本轮战斗层仅新增 2 个文件：`attach_boss_to_courtyard.gd`、`courtyard_with_boss.tscn`。
- 二者：`--check-only` EXIT=0（[D]）、段 1 `--import` 扫描无 dangling、4 条
  `ext_resource` 4/4 EXIST（[E]）、`courtyard.tscn` sha256 未变、真跑 `ATTACH_OK`。
- 现存 2 条 `SCRIPT ERROR` 的 backtrace 全部指向 3 号 `rpg/spawn_request.gd` /
  `rpg/world_state.gd`，与 R7 新增件**无引用关系**；同名全局类冲突源于 R6 落位的
  2 号 `scripts/combat/spawn_request.gd`（既有件，本轮未改）与 3 号文件并存。
- 结论：**战斗层 R7 新增件零新增 ERROR**；全工程并非全绿，现存跨工位
  `SCRIPT ERROR` 已按 §5.3 如实登记、不隐瞒、不冒充。

### 5.5 并行工位状态更正（时间线，不伪造）

- **开工时**读到的 `godot\project.godot:34-36`：`GameEvents` → `scripts/core/game_events.gd`、
  `WorldState` / `SaveSystem` → `scripts/world/*.gd`，与 `COMBAT-ASSEMBLY.md` §6.5
  在 R6 登记的「1/3 号 autoload 目标路径不一致」一致。`I2-WIRING.md` 开工段落据此写成。
- **全工程门禁复跑前复查** `project.godot:41-47`：Rank-1 **R8 已把 `WorldState` / `GameEvents`
  收口到 `res://scripts/rpg/world_state.gd` / `res://scripts/rpg/game_events.gd`**
  （`SceneRouter` → `scripts/core/scene_router.gd`、`ChunkManager` → `scripts/world/chunk_streaming.gd`、
  `SaveSystem` → `scripts/world/save_system.gd`）。该登记项由 1 号解决；2 号不写
  `project.godot`、不移动他人文件。`I2-WIRING.md` §8 已按时间线补记更正，
  I-2 实跑结论（临时镜像工程自行注册 autoload）不受影响。

---

## 6. 自检汇总（真跑实际输出结论）

| 层 | 结论 |
|---|---|
| I-2 接线 | **PASS**：6/6 检查；`RESULT=PASS checks=6 fail=0`；单 String 信号（`args=1`）、击杀 flag 只由 3 号写（C5/C6） |
| I-2 脚本层 | **PASS**：16 个 `--check-only` 全 EXIT=0；`SCRIPT ERROR` 专项 / 宽口径 0 命中（60 行日志） |
| 追加式接入 | **PASS**：`ATTACH_OK`、20→25、probe 25=25、`probe_ok=true`、原场景 sha256 未变 |
| 战斗层 R7 新增件 | **PASS（零新增 ERROR）**：`--check-only` EXIT=0、ext 4/4 EXIST、段 1 无 dangling |
| 全工程脚本层 | **段 2 `50 个 .gd / FAIL=1`**（唯一 FAIL 为跨工位 `rpg/spawn_request.gd`，非战斗层）；段 0/1/3 EXIT=0 |
| 全工程整体 | **非全绿**：2 条 `SCRIPT ERROR` + 2 条连带 `ERROR:` + 1 条 WARNING，逐条登记于 §5.3 |
| E-8 数值 | **零改动**（数值行差异=0）；validator 未落位，门禁日志无 E-8 字样；继续登记待裁决 |
| 边界 | 未写 `project.godot` / 总线 / 总纲 / 契约 / 台账；未覆盖既有文件；未自行 git；零付费 / 零外部依赖 |

---

## 7. 未完成项与阻塞

> 以下均为「需总指挥裁决 / 跨工位集成 / 超本工位范围」项，**均不阻塞本轮收尾**。

1. **E-8 三项数值冲突**：本轮选择继续登记待裁决（§4）。需总指挥给出明确数值 / 口径后
   由后续轮次执行；未落位的 `CombatDataValidator` 落位后会稳定复现 4 条 `ERROR:`。
2. **`SpawnRequest` 同名全局类并存（I-3）**：全工程现存 `SCRIPT ERROR` 的根因，
   `COMBAT-ASSEMBLY.md` §6.4 已登记；需 1/3 号集成收口（谁保留 `class_name SpawnRequest`），
   2 号不擅改既有落位件。
3. **`res://data/schema`（单数） vs `schemas`（复数）口径**：`COMBAT-ASSEMBLY.md` §6.2
   登记，裁决归总指挥；本轮未改 8 个脚本头注释 / 任务书 / 口径文档。
4. **历史 signal 去留 / I-2 唯一发射点收敛注释口径**：`COMBAT-ASSEMBLY.md` §6.3 登记；
   需改既有 `player_state_machine.gd` / `combat_resolver.gd` 注释，超「既有件不重做」边界。
5. **`SaveSystem` autoload 目标**：现 `project.godot:45` 指向
   `res://scripts/world/save_system.gd`；该目录下 R7 开工时未见对应文件，段 3 未见其
   加载报错（未深究、不刺探）。属 1/3 号集成收口，2 号不越界。
6. **未落位工程根的战斗层既有件**：`combat_data_validator.gd` / `enemy_director.gd` /
   `player_state_machine.gd` 仍在 `Rank-2\` 工位（`COMBAT-ASSEMBLY.md` §6.7），
   是否落位待后续轮次裁决。
7. **M5 手感调校 / 场景实例化后的渲染与运行时验收**：契约 §5「WorkBuddy 不替人做手感与
   审美判断」；本轮只做语法门禁、节点结构与 pack/instantiate 校验，**不宣称已渲染可见**、
   不调手感。真实工程根 `Main.tscn` 未引用 `courtyard_with_boss.tscn`（`scenes\` 归 Rank-1
   独占），运行时挂载由 1 号 / 集成层决定，接入点已在 §3.1 说明。
8. **ObjectDB leaked / ChunkManager warning**：跨工位 / 引擎时序，见 §5.3，不越界修复。

---

## 8. 收尾口径

- 本轮新建：`I2-WIRING.md`、`DONE-R7.md`（工位）；`attach_boss_to_courtyard.gd`、
  `courtyard_with_boss.tscn`（战斗层）；`cmd-20261109-024906-801-A2.json`（回执）。
  **既有件零改动、零覆盖**。
- I-2 验证临时工程 `C:\Users\62668\AppData\Local\Temp\r7_i2_gate_a2\` 与日志目录
  `..._logs\` 在系统临时目录，不落 teamwork / 工程根、不提交，**收尾已删除**
  （复查确认目录不存在）；结论已抄录进 `I2-WIRING.md` 与本文件。
- 全工程门禁在真实 `godot\` 工程根按任务书要求复跑；跨工位 ERROR / WARNING 逐条如实登记，
  **不冒充全绿、不伪造输出**。
- 零付费 / 零外部依赖；未写总线 / 总纲 / 契约 / 台账；未自行 commit / push；
  中文 UTF-8；Godot 4 合法语法；开工必读只读一次。
- **回执流转（如实登记）**：回执
  `{"task_id":"cmd-20261109-024906-801-A2","ai":2,"status":"done"}` 写入
  `teamwork\command_center\ai\2\outbox\`（任务书字面 `command_center\ai\2\outbox\`，
  工程根下无该目录；中枢真实空间为 `teamwork\command_center\`，沿用
  `COMBAT-ASSEMBLY.md` §1 的回执路径解析）后，被中枢即时轮询消费，归档于
  `teamwork\command_center\dispatcher\receipts\cmd-20261109-024906-801-A2.json`。
  实跑复核：`python json.load` 解析通过（`task_id` / `ai=2` / `status=done` /
  `result` 1474 字）；`ai\2\status.json` 实测 `state=idle / completed=8 /
  last_seen 2026-11-09 03:07:45`。`outbox\` 因中枢消费再度为空属 R6 §8
  已记录的正常现象，回执已生效，不重复补写。
- 待裁决项一律**未擅改、未选定、未实施**。
