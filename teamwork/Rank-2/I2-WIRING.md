# I2-WIRING.md —— I-2 接线实跑验证记录（Rank-2 · R7）

> 2 号工位 · 战斗系统与数据驱动 · R7 交付件（任务书 `任务书-R7.md` / 调度任务单
> `cmd-20261109-024906-801-A2` 交付项 1）。
> 目标：`combat_event_bus.gd` 与 Rank-3 `GameEvents` autoload 的 I-2 接线**实跑验证**
> ——「单 String 信号」「击杀 flag 不由 2 号双写」。
> 本文所有数字 / 输出均来自本机 Godot 4.7.2 实跑日志，不引用旧结论冒充、不伪造。
> 中文 UTF-8。

---

## 0. 结论速览

- **I-2 接线实跑 PASS**：临时最小工程四段门禁 `SEG0/1/3_RC=0`、
  `SEG2_SCRIPTS=16 SEG2_FAIL=0`；段 3 `--quit` 触发接线验证 runner 输出
  `[I2-VERIFY] RESULT=PASS checks=6 fail=0`。
- **6 项检查全 PASS**（真跑输出见 §4）：GameEvents 运行时信号表单 String 参数、
  单形参 Callable 连接、`report_defeat(enemy)` 单 String、
  `BossController._die()` 经唯一发射点发单 String、击杀 flag 只由 3 号订阅方写、
  2 号落位件源码零 `set_flag(`。
- **`SCRIPT ERROR` 专项 grep 0 命中（RC=1）**；宽口径
  `SCRIPT ERROR|Parse Error|ERROR:|Failed|Cannot|dangling|悬空|Invalid|not found|Can't`
  **0 命中（RC=1）**，全 60 行日志零 ERROR / WARNING。
- **真实件接线**：2 号 `combat_event_bus.gd` / `boss_controller.gd` / `boss_01_margit.tres`、
  3 号 `game_events.gd`（autoload）/ `save_delta_writer.gd`（订阅方）均为工程根**逐字复制**；
  仅 I-1 与 I-4 用替身桩（§2.3）。
- **方式边界**：验证在系统临时最小工程完成（§2.1），不写真实工程根 `.godot\`
  缓存、不越界；真实工程根的 autoload 目标路径不一致（R6 §6.5 / COMBAT-ASSEMBLY.md
  §3.4）属 1/3 号跨工位集成项，2 号**只登记不擅改**（§6）。

---

## 1. 接线链路（真实件，静态核对 + 运行时验证）

### 1.1 链路图

```
BossController.apply_damage() -> _die()
  -> _report_defeat(boss_data.id, true)                        boss_controller.gd:296-309
  -> _event_bus.call("report_defeat", defeat_id, is_boss)      event_bus_path=^"../CombatEventBus" (:56)
       |
CombatEventBus.report_defeat(defeat_id: String, is_boss: bool) combat_event_bus.gd:42  ← 2号唯一对外发射点
  -> _resolve_bus() -> /root/GameEvents                        game_events_path=^"/root/GameEvents" (:32)
  -> bus.emit_signal(signal_name, defeat_id)                   combat_event_bus.gd:51（单个 String）
       |  signal_name = "boss_defeated" | "enemy_defeated"    (:47)
       v
/root/GameEvents (Rank-3 game_events.gd autoload)
  signal enemy_defeated(enemy_id: String)                     game_events.gd:8
  signal boss_defeated(boss_id: String)                       game_events.gd:9
       |
SaveDeltaWriter._on_boss_defeated(boss_id: String)            save_delta_writer.gd:19-22 / 53-56
  -> _set_flag("combat.%s.defeated" % boss_id, true)          :54
  -> _ws.call("set_flag", key, value)                         :58-60 → world_state.gd:63 双参
  -> commit("boss_defeated")                                 :56
       => 击杀 flag 只由 3 号写
```

### 1.2 三个 NodePath 约束（决定接入点的兄弟节点结构）

| 落位件 | NodePath | 含义 |
|---|---|---|
| `boss_controller.gd:55` | `sprite_path = ^"../Hybrid2D3DAnimatedSprite"` | I-4 精灵节点须为**兄弟** |
| `boss_controller.gd:56` | `event_bus_path = ^"../CombatEventBus"` | 唯一发射点须为**兄弟** |
| `boss_controller.gd:57` | `world_state_path = ^"/root/WorldState"` | I-1 autoload（只读 `get_flag`） |
| `combat_event_bus.gd:32` | `game_events_path = ^"/root/GameEvents"` | I-2 autoload（只 `emit_signal`） |

### 1.3 契约口径逐项核对

| I-2 口径 | 落位件实际 | 结论 |
|---|---|---|
| 信号挂 `GameEvents` autoload、参数单个 `String` | `combat_event_bus.gd:51` `bus.emit_signal(signal_name, defeat_id)`；`game_events.gd:8-9` 均单 String | **一致**（C1/C3/C4 实跑） |
| 2 号不定义 I-2 信号、只转发 | `combat_event_bus.gd` 无 `signal` 声明，仅 `has_signal` + `emit_signal`（:48-51） | **一致** |
| 唯一发射点 | `combat_event_bus.gd:42` `report_defeat()` 为 2 号唯一对外出口；`boss_controller.gd:305-309` 只调它 | **一致**（C3/C4 各 1 次） |
| 击杀 flag 只由 3 号写、2 号不双写 | `boss_controller.gd:338-341` 仅 `_read_world_flag` 调 `get_flag`；`combat_event_bus.gd` 无 flag 操作；`save_delta_writer.gd:53-56` 才是写方 | **一致**（C5/C6 实跑） |
| autoload 缺失降级、不双出口 | `combat_event_bus.gd:44-46` 缺失时 `push_warning` 并 return，**不回退本地信号**、不改既有件 | **一致** |

---

## 2. 真跑环境与方式

### 2.1 为何用系统临时最小工程

沿用 R5 / R6（`R5-待裁决登记.md` §2.1、`COMBAT-ASSEMBLY.md` §4.1）同一口径：

- 真实工程根 `godot\project.godot` 的 `[autoload]` 仍指向
  `res://scripts/core/game_events.gd` / `res://scripts/world/world_state.gd` /
  `res://scripts/world/save_system.gd`（`project.godot:34-36`），而 3 号实现实际落在
  `res://scripts/rpg/`（`game_events.gd` / `world_state.gd`；`scripts/core` 与
  `scripts/world` 下无对应文件）。该不一致由 `COMBAT-ASSEMBLY.md` §6.5 登记为
  1/3 号跨工位集成项，**R7 开工复查仍未修**，2 号不写 `project.godot`（Rank-1 独占）。
- 在真实工程根 `--headless --import` 会写 `.godot\` 缓存（超出 2 号唯一可写范围），
  且四路工位并行写同一工程根。故 I-2 接线验证在系统临时最小工程**镜像布局**完成；
  落位成果本身在真实工程根，临时工程只是验证环境。
- 临时工程：`C:\Users\62668\AppData\Local\Temp\r7_i2_gate_a2\`（收尾删除，见 §7）；
  日志：`C:\Users\62668\AppData\Local\Temp\r7_i2_gate_a2_logs\seg_all.txt`。

### 2.2 临时工程布局（全部真实件逐字复制 + 3 个真跑挂载件）

| 类别 | 文件 | 来源 |
|---|---|---|
| 2 号落位件 | `scripts/combat/` 12 个 `.gd` | `godot\scripts\combat\` 逐字复制 |
| 2 号数据表 | `data/combat/` 3 份 `.tres` | `godot\data\combat\` 逐字复制 |
| 3 号 autoload | `rpg/game_events.gd` | `godot\scripts\rpg\game_events.gd` 逐字复制 |
| 3 号订阅方 | `rpg/save_delta_writer.gd` | `godot\scripts\rpg\save_delta_writer.gd` 逐字复制 |
| 真跑挂载件 | `rpg/world_state_stub.gd` | 新建，I-1 替身桩（§2.3） |
| 真跑挂载件 | `verify.gd` / `verify.tscn` | 新建，I-2 接线验证 runner（§3） |
| 门禁配置 | `project.godot` | 新建，`GameEvents` / `WorldState` autoload、`run/main_scene=res://verify.tscn` |

> 门禁配置与 runner 仅存在于临时工程，为**I-2 接线真跑挂载件**（触发链路并核对实际
> 输出），非探针 / 非测量 / 非 preflight 脚本；收尾随临时工程删除。工位落位件与既有件零改动。

### 2.3 两个替身桩（明确边界，不冒充真实件）

- **I-1 替身桩 `world_state_stub.gd`**：只实现契约 I-1 的双参
  `get_flag(key, default)` / `set_flag(key, value)` 并记录 `set_flag` 调用 key；
  **刻意不实现 `_commit_delta`**，使 3 号 `SaveDeltaWriter.commit()` 不触发落盘、零副作用。
  用于核对「击杀 flag 只由 3 号订阅方写」。
- **I-4 替身桩**：runner 里 `Hybrid2D3DAnimatedSprite` 为纯 `Node3D`（无 `set_pose`）；
  `BossController._apply_pose()`（`boss_controller.gd:348-351`）有 `has_method` 守卫，
  降级不报错。I-4 不是本轮验证目标，故不引入跨工位 `scripts/render/` 依赖。
- 真实工程根里这两处均由 1/3 号真实件承担，R7 不改动它们。

---

## 3. 验证 runner 的 6 项检查（`verify.gd`）

| 编号 | 检查内容 | 手段 |
|---|---|---|
| C1 | `GameEvents` **运行时**信号表 `enemy_defeated` / `boss_defeated` 各 1 个 `TYPE_STRING` 参数 | `ge.get_signal_list()` 遍历 `args` |
| C2 | 单形参 `Callable` 能连接两信号（若带第 2 参数则 `connect` 失败） | `ge.connect(..., Callable(self, "_on_*"))` |
| C3 | 直接调唯一发射点 `report_defeat("enemy_09_i2_probe", false)` → `enemy_defeated` 收到 1 个 String 且值相等 | 回调记录 `_enemy_args` |
| C4 | `BossController.apply_damage(1e9)` → `_die()` → `boss_defeated` 收到 1 个 String 且 = `boss_data.id` | 回调记录 `_boss_args` |
| C5 | 击杀 flag `combat.<boss_id>.defeated` 由 3 号订阅方写入、且所有 flag key 均为 3 号 `combat.*` 格式 | 桩 `set_flag_calls` |
| C6 | 2 号两个落位件源码零 `set_flag(` 调用（不双写） | 运行时读源码文本 `String.contains` |

节点树（runner `_ready()` 内 `add_child` 追加，全部为兄弟关系，满足 §1.2 的 `../` 路径）：

```
I2Verify (verify.tscn 根, 挂 verify.gd)
├── EnemyAnchor
│   ├── Hybrid2D3DAnimatedSprite   (I-4 替身桩, Node3D)
│   ├── CombatEventBus             (挂真实 combat_event_bus.gd)
│   └── BossController            (挂真实 boss_controller.gd, boss_data=boss_01_margit.tres)
└── SaveDeltaWriter               (挂真实 save_delta_writer.gd, 订阅 /root/GameEvents)
```

---

## 4. 四段门禁实际输出（本机 Godot 4.7.2）

引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`。

| 段 | 命令 | 退出码 | 实际输出 |
|---|---|---|---|
| 0 | `--version` | **0** | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `--headless --path <gate> --import` | **0** | `first_scan_filesystem` 5 步 DONE；`update_scripts_classes (16 steps)` 注册 **13 个全局类名**（`BossController` / `BossData` / `CombatEventBus` / `CombatResolver` / `EnemyData` / `MoveData` / `PhaseData` / `PlayerActionData` / `PlayerActionTable` / `PoiseConfig` / `SpawnRequest` / `StatusBuildup`，另 3 个无 `class_name` 桩件）；`loading_editor_layout` DONE；无 ERROR |
| 2 | `--headless --path <gate> --check-only --script res://<各 .gd>`（16 个） | `SEG2_SCRIPTS=16 SEG2_FAIL=0` | 12 个 2 号落位件 + 3 个 3 号 / 桩件 + 1 个 runner 全部解析通过，EXIT=0 |
| 3 | `--headless --path <gate> --quit` | **0** | 打开工程、注册 2 个 autoload、加载 `verify.tscn`，触发 `verify._ready()` 实跑 6 项检查后退出 |

### 4.1 段 3 原文（如实保留）

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

> 说明：C3 的 `enemy_09_i2_probe` 除被 runner 记录外，也被 3 号 `SaveDeltaWriter` 按 I-2
> 写成 `combat.enemy_09_i2_probe.defeated`；`boss_01_margit` 被写成
> `combat.boss_01_margit.defeated` + `combat.boss_01_margit.phase_two_ready`（3 号
> `save_delta_writer.gd:53-56` 既定行为）。三个 key 全部为 3 号订阅方写入、全部 `combat.*`
> 格式；2 号链路（C6）源码零 `set_flag(`，故**击杀 flag 不由 2 号双写**成立。

### 4.2 `SCRIPT ERROR` grep（工具链 §4.2：运行时错误不改退出码，必须 grep）

合并 4 段日志为 `seg_all.txt`（**60 行**）后：

| 检查 | 范围 | 结果 |
|---|---|---|
| [A] `SCRIPT ERROR` 专项 `grep -nEi "SCRIPT ERROR"` | 全 60 行 | **0 命中（RC=1）** |
| [B] 宽口径 `SCRIPT ERROR\|Parse Error\|ERROR:\|Failed\|Cannot\|dangling\|悬空\|Invalid\|not found\|Can't` | 全 60 行 | **0 命中（RC=1）** |
| [C] 6 项检查 / 退出码行 | 全 60 行 | `SEG0_RC=0` / `SEG1_RC=0` / `SEG2_SCRIPTS=16 SEG2_FAIL=0` / `SEG3_RC=0`；C1~C6 全 `PASS`；`RESULT=PASS checks=6 fail=0` |

---

## 5. 与既有登记的对照

| 既有登记 | 本轮实跑 |
|---|---|
| `R5-待裁决登记.md` §5「I-2 口径静态核对结论」：两个 R4 新增件与 I-2 一致 | 本轮由**静态升级为实跑**：C1/C2 运行时信号表、C3/C4 真实 emit、C5/C6 flag 写入方，6/6 PASS |
| `COMBAT-ASSEMBLY.md` §3.4「I-2 一致（收敛链路）」 | 本轮确认收敛链路在 `GameEvents` autoload 真实件上可跑通，且 2 号不双写 |
| `COMBAT-ASSEMBLY.md` §6.5「1/3 号 autoload 目标路径不一致」 | R7 开工复查**仍存在**（`project.godot:34-36` 指向 `scripts/core` / `scripts/world`），见 §6 |

---

## 6. 如实登记的边界 / 未完成项（不擅改）

1. **跨工位 autoload 路径不一致（1/3 号集成项）**：真实工程根 `project.godot:34-36`
   仍指向 `res://scripts/core/game_events.gd`、`res://scripts/world/world_state.gd`、
   `res://scripts/world/save_system.gd`；3 号实现实际在 `res://scripts/rpg/`。
   本轮 I-2 验证在镜像临时工程注册正确路径完成；**真实工程根直接启动仍会因此报
   autoload 缺失 ERROR**（见 `DONE-R7.md` 全工程门禁段）。2 号不写 `project.godot`
   （Rank-1 独占）、不移动 3 号文件，只登记。
2. **I-1 / I-4 用替身桩**：验证目标是 I-2 信号与 flag 归属，替身桩边界见 §2.3；
   真实工程根由 1/3 号真实件承担，本轮不改动。
3. **历史 signal / 唯一发射点收敛**：`player_state_machine.gd` 仍未落位工程根
   （`COMBAT-ASSEMBLY.md` §6.7），其历史 `signal` 与旧 `report_defeat` 本地 emit 属
   既有件，R7 不重做、不擅改，沿用待裁决登记。
4. **E-8 三项冲突**：与 I-2 无关，本轮未在临时工程挂载 `CombatDataValidator`，
   不产生 E-8 的 4 条 `ERROR:`；处置见 `DONE-R7.md` §E-8。

---

## 7. 收尾口径

- 临时工程 `C:\Users\62668\AppData\Local\Temp\r7_i2_gate_a2\` 与日志目录
  `..._logs\` 在系统临时目录，不落 teamwork / 工程根、不提交，**收尾删除**；
  结论已抄录进本文件与 `DONE-R7.md`。
- 零付费 / 零外部依赖；未写总线 / 总纲 / 契约 / 台账；未自行 commit / push；
  未覆盖任何既有文件；中文 UTF-8；Godot 4 合法语法。
- **真实件逐字复制、真跑输出如实保留，未伪造全绿结论。**
