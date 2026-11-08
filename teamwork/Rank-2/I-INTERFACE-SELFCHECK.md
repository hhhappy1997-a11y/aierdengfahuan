# I-INTERFACE-SELFCHECK.md —— 战斗侧 I-1 / I-2 / I-3 / I-4 一致性自检结论（Rank-2 · R9）

> 轮次：R9「M5 Boss 最终数据表与汇总材料」，任务单 `cmd-20261109-033148-250-A2`。
> 用途：为 `00-汇总.md` 准备**战斗侧**接口一致性自检结论（附真跑证据）。
> 契约口径：`00-协作契约.md` §3 I-1~I-4、`teamwork\Rank-2\接口契约.md`、总指挥裁决
> `MSG-20261109-0309-HOST`（I-3 `SpawnRequest` 权威件）。
> **证据分层（诚实口径）**：① 本轮 R9 全量 grep 实证（贴实际输出）；② 本轮 R9 三段门禁
> **真跑**（贴实际 stdout）；③ 引用的既有真跑记录 `R7\I2-WIRING.md`（**明确标注非本轮新跑、
> 不冒充**）。中文 UTF-8。

---

## 0. 结论速览

| 编号 | 契约方向 | 战斗侧自检结论 | 主要证据 |
|---|---|---|---|
| **I-1** | 3 → 2 `WorldState.get_flag/set_flag` | **一致**：战斗层只读 `get_flag(key, default)`，全目录 `set_flag(` 实际调用 **0 命中**；2 号不读写存档 / 不碰 SaveDelta | ① 本轮 grep；③ R7 实跑 C5 |
| **I-2** | 2 → 3 击败信号 | **一致**：`enemy_defeated` / `boss_defeated` 均为**单个 String** 参数；`CombatEventBus.report_defeat()` 为唯一发射点；**击杀 flag 只由 3 号写、2 号不双写** | ① 本轮 grep；② R9 段 3 真跑；③ R7 实跑 C1~C6 `RESULT=PASS checks=6 fail=0` |
| **I-3** | 3 → 2 `SpawnRequest` | **一致**：`^class_name SpawnRequest` 全工程**仅 1 处** = `scripts/rpg/spawn_request.gd`（权威件）；combat 版已按 R8 裁决去掉 `class_name`；战斗层 11 条 ext 无一指向它 | ① 本轮 grep；② R9 段 1/段 3 真跑 `hides a global=0` / `Failed to load=0`；③ R8 门禁 |
| **I-4** | 1 → 2 `set_pose()` | **一致**：`call("set_pose", pose_name, frame_index)` 全战斗层**单点 1 处**，带 `has_method` 守卫；pose 名 = `pose_prefix + pose_name`；不写 billboard / 锚定 / 缩放 / SpriteFrames | ① 本轮 grep；② R9 段 3 真跑；③ R7 实跑 I-4 替身桩降级 |

> 四项均**一致**；I-3 存在一处「schema §8 最小字段假设 vs 权威件 17 字段」的**字面差异**，
> 已在 §3.4 如实登记为待汇总对齐项（schema 已声明不是定义权声明，**不构成契约违反**）。

---

## 1. I-1（3 → 2）：世界状态只经 `WorldState`，战斗层只读

| 项 | 契约口径 | 落位件实际 |
|---|---|---|
| 唯一入口 | `get_flag(key[, default])` 读；`set_flag(key, value)` 仅运行时战斗态缓存 | `boss_controller.gd:338-341` `_read_world_flag(key, default_value)` → `_world_state.call("get_flag", key, default_value)`（双参、调用方自行 cast） |
| 禁止写 flag | 2 号不写 `.defeated` flag、不碰 `SaveDelta`、不 `FileAccess` / `ResourceSaver` | 全 `scripts\combat\` `set_flag(` 实际调用 **0 命中** |
| 用途 | 读 `world.player.alive`、M4 起扩为战斗态门控 | `boss_controller.gd:99-100` 只读 `defeated_flag_key` 判「是否已击败」 |
| autoload 名 | `/root/WorldState` | `boss_controller.gd:57` `world_state_path = ^"/root/WorldState"`；`project.godot:43` 注册 `WorldState="*res://scripts/rpg/world_state.gd"` |

**本轮 grep 实际输出**

```
=== [I-1] combat 侧 set_flag( 实际调用（排除注释） ===
命中数: 0
```

> 说明：`boss_controller.gd:26` / `:335` 出现的 `set_flag` 字样均为注释「不 set_flag」，
> 非调用。真跑佐证见 §6 引用的 R7 实跑 **C5**（击杀 flag 由 3 号订阅方写入）。

**结论：I-1 一致。**

---

## 2. I-2（2 → 3）：单 String 信号、击杀 flag 不双写

### 2.1 链路（源码行号）

```
BossController.apply_damage() → _die()                          boss_controller.gd:296-302
  → _report_defeat(boss_data.id, true)                          :305-309
  → _event_bus.call("report_defeat", defeat_id, is_boss)       :306-307
       │
CombatEventBus.report_defeat(defeat_id: String, is_boss: bool)  combat_event_bus.gd:42  ← 2 号唯一对外发射点
  → signal_name = "boss_defeated" | "enemy_defeated"           :47
  → bus.emit_signal(signal_name, defeat_id)                    :51  ← 单个 String
       │  /root/GameEvents（3 号 game_events.gd autoload）
       v
signal enemy_defeated(enemy_id: String)                         game_events.gd:8   ← 单个 String
signal boss_defeated(boss_id: String)                           game_events.gd:9   ← 单个 String
       │
SaveDeltaWriter._on_enemy_defeated / _on_boss_defeated          save_delta_writer.gd:48-56
  → _set_flag("combat.%s.defeated" % id, true)                 :49 / :54  ← 击杀 flag 只由 3 号写
  → _ws.call("set_flag", key, value)                           :58-60
```

### 2.2 本轮 grep 实际输出

```
=== [I-2] 唯一发射点 / 单 String emit ===
combat_event_bus.gd:42:func report_defeat(defeat_id: String, is_boss: bool) -> void:
combat_event_bus.gd:51:	bus.emit_signal(signal_name, defeat_id)

=== [I-2] 3 号信号定义（单 String） ===
game_events.gd:8:signal enemy_defeated(enemy_id: String)
game_events.gd:9:signal boss_defeated(boss_id: String)

=== [I-2] 3 号 flag 写入方 ===
49:    _set_flag("combat.%s.defeated" % enemy_id, true)
54:    _set_flag("combat.%s.defeated" % boss_id, true)
55:    _set_flag("combat.%s.phase_two_ready" % boss_id, false)
58:func _set_flag(key: String, value: Variant) -> void:
```

**逐项判定**

| I-2 口径 | 落位件实际 | 结论 |
|---|---|---|
| 信号挂 `GameEvents` autoload、参数**单个 String** | `game_events.gd:8-9` 均 1 个 `String`；`combat_event_bus.gd:51` `emit_signal(signal_name, defeat_id)` 只带 1 个实参 | **一致** |
| 2 号不定义 I-2 信号、只转发 | `combat_event_bus.gd` 全文无 `signal` 声明，仅 `has_signal` + `emit_signal`（`:48-51`） | **一致** |
| 唯一发射点 | `combat_event_bus.gd:42` `report_defeat()`；`boss_controller.gd:305-309` 只调它 | **一致** |
| **击杀 flag 不双写** | 战斗层 `set_flag(` **0 命中**；写方为 3 号 `save_delta_writer.gd:48-60`，key 全部 `combat.*` 格式 | **一致** |
| autoload 缺失降级、不双出口 | `combat_event_bus.gd:44-46` 缺失时 `push_warning` 并 return，**不回退本地信号** | **一致** |

### 2.3 真跑证据

- **既有真跑记录（R7，非本轮新跑）**：`teamwork\Rank-2\I2-WIRING.md` §4 四段门禁
  `SEG0/1/3_RC=0`、`SEG2_SCRIPTS=16 SEG2_FAIL=0`；段 3 原文 6 项检查
  **C1**（运行时信号表单 String）/ **C2**（单形参 Callable 连接）/ **C3**（`report_defeat(enemy)`）/ 
  **C4**（`BossController` 击杀）/ **C5**（击杀 flag 由 3 号写）/ **C6**（2 号落位件源码零 `set_flag(`）
  全 `PASS`，`[I2-VERIFY] RESULT=PASS checks=6 fail=0`；`SCRIPT ERROR` 专项与宽口径 grep 均 **0 命中**。
  该文件是 R7 交付件，本轮**未重跑、未重做**，引用其既有结论。
- **本轮 R9 真跑（运行期无回归佐证）**：段 3 `--headless --path godot --quit` 真实实例化
  `Main.tscn` + 5 个 autoload（含 `GameEvents`）后正常退出，`FINAL_SEG3_RC=0`、
  `SCRIPT ERROR=0` / `ERROR=0` / `Failed to load=0`（实际输出见 §5）。证明 I-2 承载体
  `GameEvents` 在完整工程根下可加载、无解析 / 加载错误。

**结论：I-2 一致（单 String 信号、击杀 flag 不双写）。**

---

## 3. I-3（3 → 2）：`SpawnRequest` 权威件在 `rpg/`

### 3.1 契约与裁决

| 项 | 内容 |
|---|---|
| 契约 | `00-协作契约.md` §3 I-3：「3 号通过 `SpawnRequest` 资源传入敌人 / 精英配置，2 号消费」 |
| 总指挥裁决 | `MSG-20261109-0309-HOST`：「裁定 `godot\scripts\rpg\spawn_request.gd` 为**唯一权威件**；`godot\scripts\combat\spawn_request.gd` 须移除重复 `class_name` 注册」 |
| 2 号立场 | 消费侧，不定义、不新增 / 删除 / 重命名字段；`数据表schema.md` §8 是「最小字段假设，不是定义权声明」 |

### 3.2 本轮 grep 实际输出

```
=== [I-3] SpawnRequest 全局类声明唯一性 ===
F:/Game/aierdengfahuan/godot/scripts/rpg/spawn_request.gd:2:class_name SpawnRequest
```

- 全 `godot\` 下 `^class_name SpawnRequest` **仅 1 处**，位于 **`scripts/rpg/`**（Rank-3 权威件，
  17 字段、`class_name SpawnRequest`，2 号零改动、只读核对）。
- `scripts\combat\spawn_request.gd:1-4` 已按 R8 裁决改为 3 行注释、`extends Resource` 无
  `class_name`（`DONE-R8.md` §2），保留为 2 号消费侧 17 字段对照规格件。
- 战斗层 3 份 `.tres` 的 **11 条 `ext_resource`** 全部指向
  `scripts/combat/{boss_data,phase_data,move_data,poise_config,status_buildup,enemy_data,player_action_data,player_action_table}.gd`，
  **无一指向 `spawn_request.gd`**（`DONE-R8.md` §3.1）；工程根代码级 `SpawnRequest.new` /
  `: SpawnRequest` / `as/is SpawnRequest` 强类型引用 **0 命中**。

### 3.3 真跑证据

| 来源 | 实际输出 | 结论 |
|---|---|---|
| 本轮 R9 段 1 `--import` | `hides a global: 0`、`dangling/not found/Failed to load: 0`、`FINAL_SEG1_RC=0` | 同名全局类冲突未复现 |
| 本轮 R9 段 3 `--quit` | `FINAL_SEG3_RC=0`、`SCRIPT ERROR=0`、`Failed to load=0`；`WorldState._ready()` 链路加载 `res://data/rpg/spawn_bellvault_elite_01.tres` 无报错 | 权威件被正确解析、战斗层无悬空引用 |
| 既有 R8 门禁（`DONE-R8.md` §4） | `Class "SpawnRequest" hides a global script class` → **0（消失）**、`ERROR=0` | 裁决目标达成（既有记录，非本轮新跑） |

### 3.4 差异登记（如实，不擅改）

- `数据表schema.md` §8 列的 2 号消费侧**10 字段最小假设**（`request_id` / `enemy_data_path` /
  `enemy_instance_id` / `spawn_position` / `spawn_facing_deg` / `chunk_id` / `is_boss` /
  `respawn_on_rest` / `level_offset` / `initial_flags`）与 3 号权威件**17 字段**
  （`request_id` / `enemy_id` / `spawn_point_id` / `position` / `facing_degrees` / `level` /
  `hp_override` / `stance_override` / `aggro_radius` / `leash_radius` / `respawn_policy` /
  `defeated_flag` / `loot_table_id` / `patrol_route` / `is_boss` / `spawn_group_id` / `metadata`）
  **字面不同**。
- schema §8 已明文「本节是 2 号消费侧所需的**最小字段假设，不是定义权声明**；字段最终以
  3 号交付为准」，`接口契约.md` §3 / `schema\spawn_request.gd` 头注释亦把定义权归 3 号
  → **不构成契约违反**；但消费侧若按 §8 鸭子类型读取，须以权威件字段名为准。
- 实际消费件 `enemy_director.gd`（含 `request: SpawnRequest` 强类型注解）**未落位工程根**
  （`COMBAT-ASSEMBLY.md` §6.7），不参与门禁；是否落位 / 字段口径对齐待后续轮次裁决。
- 本轮**未改** schema §8、未改权威件、未改任何 `.tres` ext 路径。

**结论：I-3 一致（权威件唯一且位于 `rpg/`）；§3.4 字面差异登记为待汇总对齐项。**

---

## 4. I-4（1 → 2）：只调 `set_pose(pose_name, frame_index)`

| 项 | 契约口径 | 落位件实际 |
|---|---|---|
| 唯一调用点 | 2 号**只**调 `set_pose(pose_name, frame_index)` | `boss_controller.gd:348-351` `_apply_pose()` 单点，`has_method("set_pose")` 判空守卫 |
| 调用形式 | `_sprite.call("set_pose", pose_name, frame_index)` | `boss_controller.gd:351` 逐字一致 |
| pose 名来源 | `PhaseData.pose_prefix + MoveData.pose_name` | `p1_dagger_slash` / `p2_holy_hammer` 等；`boss_controller.gd:300` 死亡演出 `_phase.pose_prefix + death_pose_name` |
| 明确不做 | 不写 billboard / 底部中心锚定 / 像素→米缩放 / 自定义 AABB / `SpriteFrames` 赋值 / texture_filter / 光照 / 后处理 | 战斗层全目录无相关实现 |

**本轮 grep 实际输出**

```
=== [I-4] combat 侧 set_pose 调用点 ===
boss_controller.gd:351:	_sprite.call("set_pose", pose_name, frame_index)
```

> 全战斗层 `call("set_pose"` **仅 1 处**。真跑佐证：R7 `I2-WIRING.md` §2.3 用纯 `Node3D`
> 作 I-4 替身桩（无 `set_pose`），`_apply_pose()` 经 `has_method` 守卫降级不报错；
> 本轮 R9 段 3 `--quit` `FINAL_SEG3_RC=0`、`SCRIPT ERROR=0`，完整工程根下加载无 I-4 相关错误。
> 阶段动画 Q1（`SpriteFrames` 替换 vs `set_pose`）仍按 `接口契约.md` §4 Q1 登记待裁决，
> 本轮不私改接口、不宣称已渲染可见（契约 §5）。

**结论：I-4 一致。**

---

## 5. 本轮 R9 真跑实际输出（三段门禁 + `SCRIPT ERROR` grep）

> 引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`；工程根 `F:/Game/aierdengfahuan/godot`；
> 日志 `C:\Users\62668\AppData\Local\Temp\r9_gate_a2\`（系统临时目录，收尾删除，不落工位 / 工程根）。
> 口径与 `Rank-1\GATE-FINAL.md` §1 / `DONE-R8.md` §4.1 一致：G1 `--import`、G2 全量
> `--check-only --script`、G3 `--quit`，合并日志 grep。

### 5.1 FINAL 稳定快照实际 stdout（逐字）

```
=== FINAL GATE_TS_START=2026-11-09 03:37:51 +0800 ===
FINAL_SEG0_RC=0
--- seg0 ---
4.7.2.stable.official.ed1daf0bf
FINAL_SEG1_RC=0
final_seg1.log 行数: 16
FINAL_SEG2_SCRIPTS=52 FINAL_SEG2_FAIL=0
FINAL_SEG3_RC=0
--- seg 3 原文 ---
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
=== FINAL all.log 行数: 125 ===
SCRIPT ERROR: 0
Parse Error: 0
ERROR lines: 0
WARNING lines: 1
leaked lines: 1
hides a global: 0
dangling/not found/Failed to load: 0
=== ERROR/WARNING 原文 ===
124:WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
=== FINAL GATE_TS_END=2026-11-09 03:38:07 +0800 ===
```

| 段 | 命令 | 退出码 | 实际输出 |
|---|---|---|---|
| 0 | `--version` | `FINAL_SEG0_RC=0` | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `--headless --path <root> --import` | `FINAL_SEG1_RC=0` | 16 行；`first_scan_filesystem` / `loading_editor_layout` DONE；无 ERROR |
| 2 | `--check-only --script`（全工程 **52** 个 `.gd`） | `FINAL_SEG2_SCRIPTS=52 FINAL_SEG2_FAIL=0` | 52 个脚本全部解析通过，`FAIL` 列表为空 |
| 3 | `--headless --path <root> --quit` | `FINAL_SEG3_RC=0` | 主场景 + 5 个 autoload 启动后正常退出；仅 1 条 leaked WARNING |

### 5.2 `SCRIPT ERROR` 专项与宽口径 grep（工具链 §4.2：运行时错误不改退出码，必须 grep）

合并 4 段日志 `final_all.log`（**125 行**）：`SCRIPT ERROR: 0`、`Parse Error: 0`、
`ERROR lines: 0`、`hides a global: 0`、`dangling/not found/Failed to load: 0`；
唯一告警 `WARNING lines: 1 / leaked lines: 1`，逐字为
`WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).`
（`all.log:124`）——与 `GATE-FINAL.md` §6 / `DONE-R8.md` §4.4 一致，为 ChunkManager 在途
`load_threaded_request` 遇 `--headless --quit` 的 `RefCounted` 残留，**WARNING 级、非 ERROR、
非 SCRIPT ERROR、不改退出码**，2 号不越界修复。

### 5.3 并行时序如实登记（不冒充全程无冲突）

| 时点 | 实际输出 | 归因 |
|---|---|---|
| 首次门禁 `03:36:29` 段 1 `--import` | **8 条 `ERROR:`**：`Couldn't find the given section "preset.0" ... export_filter/include_filter/exclude_filter` ×2 轮 + `Cannot get keys from nonexistent section "preset.0.options"` ×2 轮；合并 `SCRIPT ERROR: 0`、`Parse Error: 0`、`ERROR lines: 8` | `godot\export_presets.cfg`（**Rank-1 R10 交付件**，`03:35:51` 落盘、457 B）当时为**未完成版**，缺 3 个 preset 级键与 `[preset.0.options]` 键 → Godot `--import` 读导出预设报错 |
| 第二次复跑 `--import`（约 `03:37`） | `RE_IMPORT_RC=0`、`RE_IMPORT ERROR 计数: 0`、`SCRIPT ERROR: 0`、`Parse Error: 0` | Rank-1 并行把该文件补全为 **768 B 有效版**（补入 `export_filter="all_resources"` / `include_filter` / `exclude_filter` 与 `[preset.0.options] binary_format/embed_pck=false`） |
| FINAL 完整三段 `03:37:51` | `ERROR lines: 0`（§5.1） | 稳定快照 |

> 这 8 条 ERROR 是**配置层读取错误**（`export_presets.cfg`，Rank-1 范围）、**非脚本层**
> （`SCRIPT ERROR=0` / `Parse Error=0`、52 个 `.gd` 全 EXIT=0）、**非战斗层**、**非本轮 2 号改动**
> （本轮 2 号不改任何工程根文件）。属四路并行写同一工程根的时序现象，已由 Rank-1 自行收口；
> 2 号**不改他人文件、不越界修复、不冒充全绿**，按实际输出如实登记。
> **I-1~I-4 战斗侧结论不受该时序影响**（脚本层 / 加载层始终 0 SCRIPT ERROR）。

### 5.4 判定

| 层 | 结论 |
|---|---|
| 脚本层 | **PASS**：52/52 `--check-only` EXIT=0，`SCRIPT ERROR=0`、`Parse Error=0` |
| 资源 / 加载层 | **PASS**：G1 `--import` EXIT=0、G3 `--quit` EXIT=0，`hides a global=0`、`Failed to load=0`、`dangling=0`、`not found=0` |
| 数据自洽层 | **E-8 三项 FAIL 仍在**（`CombatDataValidator` 未落位工程根，门禁日志无 E-8 字样 ≠ 已解决）；见 `BOSS-DATA-FINAL.md` §6.3 / `E8-裁决建议表.md` |
| 整体 | **非「全绿」**：`ERROR=0` 但 1 条跨工位 / 引擎时序 `leaked` WARNING；E-8 与其余待裁决项仍在；段 3 只做加载门禁，**未做渲染 / 运行时 / 手感验收** |

---

## 6. 引用的既有真跑记录（明确标注：非本轮新跑）

| 记录 | 内容 | 本轮处置 |
|---|---|---|
| `Rank-2\I2-WIRING.md`（R7） | 四段门禁 `SEG0/1/3_RC=0`、`SEG2_SCRIPTS=16 SEG2_FAIL=0`；段 3 实跑 C1~C6 全 `PASS`、`RESULT=PASS checks=6 fail=0`；`SCRIPT ERROR` 专项与宽口径 grep 均 0 命中 | **引用既有结论**，本轮未重跑 runner、未重做（既有件不重做） |
| `DONE-R8.md` §4（R8） | 全工程门禁 `hides a global script class=0`、`ERROR=0`、`SEG2_SCRIPTS=51 SEG2_FAIL=0` | 引用作 I-3 裁决达成的历史佐证 |
| `Rank-1\GATE-FINAL.md`（R9） | `ERROR 18→4→0`、`SCRIPT ERROR=0`、51/51 `.gd` EXIT=0、1 条 leaked WARNING | 引用作 ERROR 归零基线对照 |

> 本轮 R9 的 `.gd` 计数为 **52**（R8 / GATE-FINAL 基线为 51），差 1 件来自四路并行写入
> 同一工程根；按「默认不刺探」未逐一追查归属，只登记数量差异，门禁窗口内 `ERROR=0`
> 且未出现因并行时序产生的脚本层 ERROR（§5.3 的 8 条为配置层，已归因）。

---

## 7. 未完成 / 待裁决 / 边界（只登记，不擅改）

1. **I-3 字段口径字面差异**：schema §8 的 10 字段最小假设 vs 权威件 17 字段（§3.4）；
   消费件 `enemy_director.gd` 未落位工程根，字段对齐待后续轮次裁决。
2. **E-8 三项数值冲突**：见 `E8-裁决建议表.md`，本轮只给建议不改数值。
3. **历史 signal 去留 / I-2 唯一发射点收敛**：`player_state_machine.gd` 既有 `signal` 与旧
   `report_defeat` 本地 emit 属既有件，`COMBAT-ASSEMBLY.md` §6.3 登记待裁决；本轮未改。
4. **`res://data/schema` 单复数口径**：`COMBAT-ASSEMBLY.md` §6.2 登记，裁决归总指挥。
5. **`CombatDataValidator` / `enemy_director.gd` / `player_state_machine.gd` 未落位工程根**：
   `COMBAT-ASSEMBLY.md` §6.7，是否落位待裁决。
6. **Q1（`SpriteFrames` 替换 vs `set_pose`）**：`接口契约.md` §4 Q1 登记，本轮不私改接口。
7. **ObjectDB leaked WARNING / 手感与渲染验收**：跨工位 / 引擎时序与契约 §5 边界，不越界修复、不宣称可见。

---

## 8. 边界声明

- 本轮 R9 新增：**仅本文件**；未改任何 `.gd` / `.tres` / `project.godot` / `export_presets.cfg` /
  权威件 / 总线 / 总纲 / 契约 / 台账 / 其它工位。
- 三段门禁在**真实工程根**复跑，`--import` 更新的是既有 `godot\.godot\` 引擎缓存
  （`.gitignore` 排除、非 2 号交付件），未覆盖任何源码 / 既有文件。
- 零付费 / 零外部依赖；中文 UTF-8；Godot 4 合法语法；未自行 git commit / push；
  默认不刺探（仅按任务要求做一次门禁与定点 grep，未巡检）。
- **所有 grep / 真跑输出如实贴出，未伪造、未冒充全绿、未把既有真跑记录冒充本轮新跑。**
