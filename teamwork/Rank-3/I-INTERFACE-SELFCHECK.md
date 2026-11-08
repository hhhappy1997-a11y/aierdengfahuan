# I-INTERFACE-SELFCHECK.md · RPG 侧 I-1 / I-2 / I-3 一致性自检（Rank-3 · R9）

> 工位：3 号（RPG / 世界 / 存档）｜轮次：**R9**｜中文 UTF-8｜**为 `00-汇总.md` 准备**
> 依据：`00-协作契约.md` §3（I-1 / I-2 / I-3）、`接口契约.md`、`存档与flag规范.md`、`godot\scripts\rpg\*.gd` 工程根落位件、`godot\data\rpg\*.tres`。
> 证据来源：**本轮（R9）亲自真跑** Godot 4.7.2 三段门禁 + `W7_SUMMARY` + `R8_NORM_SUMMARY`（实际 stdout 见 §5）；对照基线 `DONE-R7.md` / `RPG-WIRING.md` §5 / `DONE-R8.md` ②。
> 结论口径：**如实登记，不冒充全绿、不伪造输出**。

---

## 1. 真跑环境与命令族（实际输出）

- 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`，G0 实测 `4.7.2.stable.official.ed1daf0bf`。
- 载体：**完整工程根** `F:\Game\aierdengfahuan\godot\`（`res://` 根 = `godot\`），非临时最小工程。
- 日志置于系统临时目录 `C:\Users\62668\AppData\Local\Temp\r9_final_logs\`，收尾删除；**未启动任何 GPU job**。

| 段 | 实际命令 | EXIT | 实际输出结论 |
|---|---|---|---|
| G0 | `--version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| G1 | `--headless --path godot --import` | `0` | `g1.log` 32 行；`first_scan_filesystem` 5 steps / `loading_editor_layout` 全 `[ DONE ]`；**无 Parse Error / Failed loading**；含 8 条 `preset.0` 配置读取 ERROR（见 §6.1，跨工位、非脚本错误） |
| G2 | `--headless --path godot --check-only --script res://scripts/rpg/<f>.gd` × 24 | `0` | `G2_TOTAL=24 G2_FAIL=0`（24 个 rpg `.gd` 全 EXIT=0） |
| G3 | `--headless --path godot --quit` | `0` | `g3.log` 4 行：版本行 + 1 条 `ObjectDB leaked` WARNING；**无 autoload 路径 ERROR、无 `scene_missing` WARNING** |
| W7 | `--headless --path godot --quit-after 5 res://scripts/rpg/r7_wiring_test.tscn` | `0` | `w7.log` 70 行，`W7_SUMMARY pass=45 fail=0`，`W7_FAIL` 0 条 |
| R8 | `--headless --path godot --script res://scripts/rpg/r8_neg_chunk_test.gd` | `0` | `r8norm.log` 27 行，`R8_NORM_SUMMARY pass=18 fail=0`，`R8_NORM_FAIL` 0 条 |

合并 `g0+g1+g2_*+g3+w7+r8norm → all.log`（**182 行**），`grep -nEi "SCRIPT ERROR|Parse Error|ERROR|Failed loading|WARNING"` 专项计数：

```
SCRIPT_ERROR=0    Parse_Error=0    Failed_loading=0
ERROR=8           WARNING=9
```

---

## 2. I-1 一致性自检（3 → 1 / 2：`WorldState` + `SaveDelta`）

| 契约点（`00-协作契约.md` §3 / `接口契约.md` §1） | 核对结果 |
|---|---|
| 对外仅 `get_flag(key, default) -> Variant`、`set_flag(key, value) -> void` | ✅ `world_state.gd:51 / :63` 签名逐字一致；`接口契约.md` §1.1、`存档与flag规范.md` §2.2 三处一致 |
| `get_flag` 纯读 / 返回值拷贝 / 未命中返回 default | ✅ `world_state.gd:51-59`，非法 key `push_warning` 后返回 default |
| `set_flag` 幂等（同值不增 seq / 不发信号 / 不入 Delta） | ✅ `world_state.gd:70-72`；变化顺序「更新内存 → `flag_changed.emit` → 入队 Delta → `seq += 1`」= :73-79 |
| flag key 三段式正则 | ✅ `world_state.gd:24` = `^(world\|quest\|combat\|grace\|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`，与 `存档与flag规范.md` §3.1 逐字一致 |
| value 白名单 bool/int/float/String | ✅ `world_state.gd:67-69` `_is_scalar` 校验，越界 `push_error` 忽略写入 |
| SaveDelta 十字段冻结 / 门状态收敛进 `flags` | ✅ 见 `SAVE-SPEC-FINAL.md` §1 / §2；工程根 `save_delta.gd`（静态合并类）+ `world_state.gd`（内联）均经 G2 `--check-only` EXIT=0 |
| 1 / 2 号不得读写存档文件 / 构造解析 SaveDelta | ✅ 权威规范 §2.4 禁止清单；本轮未变更 |

**真跑证据（W7 实际输出）**：
- `W7_DIAG /root/WorldState resolvable: bridge=true writer=true runner=true`、`W7_DIAG members bridge.ws=true bridge.writer=true writer.ws=true writer.bus=true runner.ws=true` → autoload 单例在完整工程根可解析、无同名双实例。
- `T2_RAW_INVALID` / `T2_NORM_VALID` / `T2_NORM_WRITTEN`（`get_flag(norm,false)=true`）/ `T2_COLLECT` → 三段式校验 + `set_flag/get_flag` 写入读回闭环。
- `T2_DELTA_WRITTEN` / `T2_RAW_ABSENT` / `T2_NORM_PRESENT` / `T2_COMMIT_REASON`（`reason=dungeon_enter`）→ 加载边界强制落盘、原始 `chunk.*` 非法 key 未持久化。
- `T3_FLAGS_3SEG`（8 节点 lit/unlocked 全三段式）/ `T3_LANDING_FLAG` / `T3_DELTA_EXISTS` / `T3_COMMIT_REASON`（`reason=grace_fast_travel`）/ `T3_DELTA_FLAGS`。
- `T3_GATE_BEFORE` / `T3_GATE_AFTER` / `T3_GATE_EDGE_PASS` / `T3_GATE_LOCKED` → 边条件运行期经 `get_flag` 求值、不缓存。
- `T4_ONENTER_FLAG`（`on_enter_flags wrote world.npc_01_bellkeeper.met=true via I-1`）。

**结论**：I-1 契约 ↔ 实现 ↔ 运行期三者一致，**无回归**（`W7_SUMMARY pass=45 fail=0` 与 R7 / R8 基线逐字一致）。

---

## 3. I-2 一致性自检（2 → 3：击杀信号 → 写 Delta）

| 契约点（`00-协作契约.md` §3 / `接口契约.md` §2） | 核对结果 |
|---|---|
| 2 号发 `enemy_defeated(enemy_id: String)` / `boss_defeated(boss_id: String)`，**单 String** | ✅ `game_events.gd:8-9` 两条 signal 声明，参数单 String；注释明确「不是 StringName / Dictionary / 不带第二参数」 |
| 3 号订阅并写 `combat.<对象>.defeated` | ✅ `save_delta_writer.gd:19-22` `_ready()` 订阅两信号；`:48-50` `_on_enemy_defeated` 写 `combat.%s.defeated=true` + `commit("enemy_defeated")`；`:53-56` `_on_boss_defeated` 写 defeated + `phase_two_ready=false` + `commit("boss_defeated")` |
| 2 号只读不写 flag / 不碰 SaveDelta（避免 `seq` 双写） | ✅ `game_events.gd:6`「本节点只承载信号，不写任何 flag」；`save_delta_writer.gd:4`「击杀 flag 只由本节点写，2 号只发信号不双写」 |
| 击杀强制落盘 | ✅ `commit(reason)` → `_commit` → `WorldState._commit_delta(reason)`（`save_delta_writer.gd:38-45`），与 `存档与flag规范.md` §4.8 `enemy_defeated` / `boss_defeated` 强制同步点一致 |

**真跑证据（W7 实际输出）**：
- `W7_DIAG spawn /root/SaveDeltaWriter from res://scripts/rpg/save_delta_writer.gd` + `W7_DIAG members ... writer.bus=true` → writer 已实例化且持有信号总线。
- W7 经同一总线 emit `dungeon_transition_requested` / `travel_requested`，实证 `ChunkWorldBridge → SaveDeltaWriter.commit(reason) → WorldState._commit_delta → delta.json` 原子写链路：`T2_DELTA_WRITTEN` + `T2_COMMIT_REASON(reason=dungeon_enter)`、`T3_DELTA_EXISTS` + `T3_COMMIT_REASON(reason=grace_fast_travel)`。
- `G2_TOTAL=24 G2_FAIL=0`：`save_delta_writer.gd` / `game_events.gd` 静态解析通过。

**如实登记（不夸大）**：W7 载体的 45 项断言分组为 T2（flag / Delta）、T3（M6 网络）、T4（语音绑定），**未直接 emit `enemy_defeated` / `boss_defeated` 信号**，即 I-2「击杀 → flag」链路本轮为**静态实现逐行核对 + 同一 `commit()` 强制落盘通道的运行期实证**，并非运行期直接对击杀信号做断言。此口径与 `DONE-R8.md` ② 一致，不冒充"运行期击杀断言已覆盖"。

**结论**：I-2 契约 ↔ 实现一致、订阅链路在完整工程根可解析、强制落盘通道运行期实证通过，**无回归**；击杀信号端到端运行期断言仍待后续联调补强（见 §6.3 登记）。

---

## 4. I-3 一致性自检（3 → 2：`SpawnRequest` 17 字段）

| 契约点（`00-协作契约.md` §3 / `接口契约.md` §3） | 核对结果 |
|---|---|
| `SpawnRequest` 由 3 号定义、2 号消费，**17 字段** | ✅ `godot\scripts\rpg\spawn_request.gd:9-25` 逐行 17 个 `@export`，与 `接口契约.md` §3 17 行表格字段名 / 类型 / 默认值逐项一致 |
| 唯一权威件 = `res://scripts/rpg/spawn_request.gd` | ✅ `spawn_request.gd:2` `class_name SpawnRequest`；按 `MSG-20261109-0309-HOST` 裁决，`godot\scripts\combat\spawn_request.gd:2-4` **已去除重复 `class_name`**（保留为 2 号消费侧 17 字段对照规格件，不注册全局类） |
| 2 号不得增 / 删 / 重命名字段；字段类型以 3 号表为准 | ✅ combat 侧对照件 17 字段逐项一致；`patrol_route` 两侧均为**非类型化 `Array`**（`spawn_request.gd:22`） |
| 实例可被 2 号消费 | ✅ `godot\data\rpg\spawn_bellvault_elite_01.tres` 用 `spawn_request.gd` 脚本，17 字段齐备（`respawn_policy="never"`、`defeated_flag="combat.elite_01_bell_warden.defeated"`、`patrol_route` 3 个 Vector3） |

**真跑证据**：
- `G2_TOTAL=24 G2_FAIL=0`：含 `spawn_request.gd` 在内 24 个 rpg `.gd` 全 `--check-only` EXIT=0 → **R7 的 `SpawnRequest` 同名类 Parse Error 已清零、无回归**（R7 `G2_FAIL=1`，R8/R9 均 `=0`）。
- W7 全量日志无 `SpawnRequest` 冲突 ERROR（专项 `ERROR` 8 条全部为 `preset.0` 配置读取，见 §6.1）。

**结论**：I-3 权威字段集 ↔ 权威实现 ↔ 2 号对照件 ↔ `.tres` 实例四者一致，同名类冲突已按裁决闭环，**无回归**。

---

## 5. 真跑证据（实际 stdout 摘录，未伪造）

### 5.1 门禁与汇总标记
```
G0_EXIT=0
4.7.2.stable.official.ed1daf0bf
G1_EXIT=0        G1_LINES=32
G2_TOTAL=24 G2_FAIL=0
G3_EXIT=0        G3_LINES=4
W7_EXIT=0        W7_LINES=70
R8_EXIT=0        R8_LINES=27
68:W7_SUMMARY pass=45 fail=0
W7_FAIL_COUNT=0  W7_PASS_COUNT=45
21:R8_NORM_SUMMARY pass=18 fail=0
R8_NORM_FAIL_COUNT=0  R8_NORM_PASS_COUNT=18
ALL_LINES=182
SCRIPT_ERROR=0   ERROR=8   Parse_Error=0   Failed_loading=0   WARNING=9
```

### 5.2 W7 关键断言（`w7.log` 逐字）
```
W7_DIAG /root/WorldState resolvable: bridge=true writer=true runner=true
W7_DIAG members bridge.ws=true bridge.writer=true writer.ws=true writer.bus=true runner.ws=true
W7_PASS T2_NORM_WRITTEN | get_flag(norm,false)=true
W7_PASS T2_DELTA_WRITTEN | delta.json parsed after dungeon_enter commit
W7_PASS T2_COMMIT_REASON | reason=dungeon_enter
W7_PASS T3_NODES_8 | grace_nodes=8
W7_PASS T3_EDGES_7 | edges=7
W7_PASS T3_AREAS_6 | area_bindings=6
W7_PASS T3_COVER_AREAS | 6/6 areas cover every node.area_id
W7_PASS T3_COVER_GRACES | 8/8 graces bound=8
W7_PASS T3_FLAGS_3SEG | all lit/unlocked flags are I-1 three-segment
W7_PASS T3_EDGE_OPEN | grace_limgrave_gatefront -> grace_limgrave_chapel edge has no prerequisites
W7_PASS T3_COMMIT_REASON | reason=grace_fast_travel
W7_PASS T3_GATE_EDGE_PASS | conditional edge now passable
W7_PASS T3_GATE_LOCKED | boss-gated edge stays locked
W7_PASS T4_BIND_COUNT | key_table_bound=3 (expect 3)
W7_PASS T4_WAV_BYTES | line_bellkeeper_01 bytes=308800 expect=308800
W7_PASS T4_WAV_BYTES | line_bellkeeper_02 bytes=206022 expect=206022
W7_PASS T4_WAV_BYTES | line_memory_01 bytes=249644 expect=249644
W7_PASS T4_ONENTER_FLAG | on_enter_flags wrote world.npc_01_bellkeeper.met=true via I-1
W7_SUMMARY pass=45 fail=0
```

### 5.3 R8 归一载体（`r8norm.log` 逐字，摘要）
```
R8_NORM_PASS R8_NORM_KEY_chunk_limgrave_-1_-1 | ... -> world.chunk_limgrave_neg1_neg1.loaded
R8_NORM_PASS R8_NORM_POS_REGRESSION | pos=world.chunk_limgrave_0_0.loaded (R7 baseline)
R8_NORM_PASS R8_NORM_RAW_STILL_INVALID | chunk.* raw first-segment still invalid (I-1 whitelist unchanged)
R8_NORM_SUMMARY pass=18 fail=0
```

> `W7_SUMMARY pass=45 fail=0` 与 R7 基线（`RPG-WIRING.md` §5 / `DONE-R7.md` ②）、R8 复跑（`DONE-R8.md` ②）**逐字一致**；`R8_NORM_SUMMARY pass=18 fail=0` 与 R8 基线一致；正坐标产物 `world.chunk_limgrave_0_0.loaded` 未变 → **I-1~I-3 联调断言与负坐标归一增强均零回归**。

---

## 6. 无回归判定与如实登记

### 6.1 8 条 `preset.0` ERROR（本轮新出现，跨工位、非脚本错误）
G1 `--import` 在 `g1.log:3/5/7/9` 与 `:20/22/24/26` 输出 8 条：
```
ERROR: Couldn't find the given section "preset.0" and key "export_filter", and no default was given.
ERROR: Couldn't find the given section "preset.0" and key "include_filter", and no default was given.
ERROR: Couldn't find the given section "preset.0" and key "exclude_filter", and no default was given.
ERROR: Cannot get keys from nonexistent section "preset.0.options".
```
归因：来源为 `godot\export_presets.cfg`（**Rank-1 R10 交付件**，mtime `2026-11-09 03:35`，文件头自述「先按最小必需字段集落盘，再以 `--headless --export-release` 的实际报错校正」），当前只有 `[preset.0]` 的 `name` / `platform` / `runnable` / `export_path` 与空的 `[preset.0.options]`，缺 `export_filter` / `include_filter` / `exclude_filter` 键 → `ConfigFile.get_value` 报错。
- 性质：**导出预设配置读取错误**，不是 `SCRIPT ERROR` / `Parse Error` / `Failed loading`（三者均 0）；G1 本身 `EXIT=0` 且 `first_scan_filesystem` / `loading_editor_layout` 全 `[ DONE ]`。
- 归属：`export_presets.cfg` 属 Rank-1 独占的导出配置，R8 时该文件尚未出现（`ERROR=0`），本轮为 **R10 产物交付阶段并行写入的中间态**；3 号**不擅改、不裁决**，只登记。
- 对结论的影响：**不影响 I-1 / I-2 / I-3 一致性自检与「无回归」判定**（脚本门禁 `SCRIPT_ERROR=0`、G2 全 0、W7/R8 断言与基线一致）。

### 6.2 9 条 WARNING 逐条归因（沿用 R8 口径，非脚本错误）
| 命中 | 归因 |
|---|---|
| `ObjectDB instances were leaked at exit` × 3（G3 / W7 / R8） | headless 退出噪音 |
| `[ChunkManager] 未找到 ChunkRoot` × 2（W7 / R8） | Rank-1 `ChunkManager` autoload 无 `ChunkRoot` 场景节点、降级（跨工位） |
| `I-1: 非法 flag key，写入忽略：chunk.chunk_limgrave_0_0.loaded`（W7） | **联调预期拒绝**，验证原始 `chunk.*` 被 I-1 拒绝，非缺陷 |

### 6.3 自检边界 / 待裁决登记（只登记不擅改）
| # | 项 | 性质 |
|---|---|---|
| 1 | I-2 击杀信号 `enemy_defeated` / `boss_defeated` 的运行期端到端断言 | W7 未直接 emit，本轮为静态核对 + 同一 `commit()` 通道运行期实证；待后续联调补强 |
| 2 | 8 条 `preset.0` ERROR（`export_presets.cfg`） | 跨工位 R10 并行中间态，Rank-1 归属，3 号不擅改 |
| 3 | A8：契约 §2 两段式示例 vs §3.1 三段式 | 已登记 `README.md` A8，HOST 裁决 |
| 4 | `chunk.<id>.loaded` 归一最终口径 A/B/C / `SaveSystem` autoload 归属 / `_present_line` UI 归属(D2) / §4.4 九项 | 沿用 `DONE-R8.md` ③ 待裁决，本轮未推进 |

---

## 7. 自检总结论（供 `00-汇总.md` 引用）

> **RPG 侧 I-1 / I-2 / I-3 一致性自检通过，且真跑确认无回归。**
> 依据：三段门禁 G0/G1/G2/G3/W7/R8 全 `EXIT=0`、`G2_TOTAL=24 G2_FAIL=0`、`SCRIPT_ERROR=0` / `Parse_Error=0` / `Failed_loading=0`；`W7_SUMMARY pass=45 fail=0`（与 R7 / R8 基线逐字一致）、`R8_NORM_SUMMARY pass=18 fail=0`（与 R8 基线一致）。I-1 签名 / 三段式 / SaveDelta 十字段、I-2 信号参数与订阅写入、I-3 十七字段与同名类裁决均契约 ↔ 实现 ↔ 运行期一致。
> **如实登记不冒充全绿**：本轮 G1 出现 8 条 `preset.0` 配置读取 ERROR（跨工位 R10 `export_presets.cfg` 中间态、非脚本错误），另有 9 条退出 / 跨工位 / 预期拒绝 WARNING；均不影响上述接口结论，逐条归因见 §6。
