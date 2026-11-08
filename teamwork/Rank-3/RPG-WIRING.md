# RPG-WIRING.md · R7：RPG 层跨模块联调记录

> 轮次：**R7**（HOST 全闭环调度续派）｜工位：**3 号（RPG / 世界 / 存档）**｜派单 task_id `cmd-20261109-024906-803-A3`
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（G0 实测 `4.7.2.stable.official.ed1daf0bf`）。中文 UTF-8。
> 真跑载体：**完整工程根** `F:\Game\aierdengfahuan\godot\`（`--path` 指向该目录，`res://` 根 = `godot\`），非 R6 的临时最小工程；所有 `.gd` / `.tres` / `.json` / WAV 均为工程根落位件。
> 本件记录五项任务的联调方法、实际输出与归因；`DONE-R7.md` 为交付结论主件。

---

## 0. 边界与真跑载体

| 项 | 实际 |
|---|---|
| 本轮写入 | `godot\scripts\rpg\r7_wiring_test.gd` + `r7_wiring_test.tscn`（新建验证载体）、`Rank-3\RPG-WIRING.md`、`Rank-3\DONE-R7.md`、`command_center\ai\3\outbox\` 回执 |
| 引擎产物 | `r7_wiring_test.gd.uid`（G1 `--import` 自动生成，非手工写入） |
| 未写 | `godot\project.godot`（**Rank-1 独占**）、其它工位子目录（core / render / ui / world / combat / scenes / data\render 等）、总线 / 总纲 / 契约 / 任务书 / 进度台账 |
| 既有件 | 22 个 `.gd` + 6 份 `.tres` + 2 份 `voice_*.json` + 3 个 WAV **一字未改**（mtime 保持 02:28~02:30，见 §6 diff 审计） |
| 真跑命令族 | G0 `--version`；G1 `--headless --path godot --import`；G2 `--check-only --script res://scripts/rpg/<f>.gd` × 23；G3 `--headless --path godot --quit`；W7 `--headless --path godot --quit-after 5 res://scripts/rpg/r7_wiring_test.tscn` |
| 日志 | 系统临时目录 `C:\Users\62668\AppData\Local\Temp\r7_logs\`（非交付件，合并 `all.log` 180 行，收尾清理） |

**载体设计**：`r7_wiring_test.tscn` 挂一个 `extends Node` 脚本，在 `_ready()` 里 `call_deferred("_run_all")` 延迟到场景树初始化完成后再装配（Godot 4 在 `_ready()` 阶段对 root 直接 `add_child` / 绝对路径 `get_node` 会报 `Parent node is busy setting up children`，试跑 v1/v2 实测确认）。`_run_all()` 用 `_spawn(path, nm)` **优先复用 Rank-1 已注册的 autoload 单例**，缺失才按正确落位路径补位：`WorldState` / `GameEvents` 复用，`SaveDeltaWriter` / `ChunkWorldBridge` / `DialogueRunner` 按 `res://scripts/rpg/*.gd` 补位；再 `await get_tree().process_frame` 等各节点 `_ready()` 完成后执行联调。全程不改 `project.godot`、不改既有交付件。

> 试跑迭代（如实登记，未伪造）：v1 `--script + extends SceneTree` → 4 FAIL（`/root/WorldState` 解析不到）；v2 `extends Node + .tscn` → `add_child` 被拒；v3 加 `call_deferred` → 仍 4 FAIL（节点 `_ready()` 延迟）；v4 加 `await` + 诊断 → 定位为「同名双实例」；v5 改为复用 autoload 单例 → `W7_SUMMARY pass=45 fail=0`。各次均为真实输出，最终结论以正式门禁的 v5 载体为准。

---

## 1. 任务 1 · autoload 落位与注册一致性核对（只核对与登记，不写 project.godot）

### 1.1 开工首次读取的 `project.godot`（旧口径）

`[autoload]` 段 5 项与 3 号实际落位（`res://scripts/rpg/`）对照：

| 单例名 | 首次读到的注册路径 | 3 号实际落位 | 一致性 |
|---|---|---|---|
| `WorldState` | `*res://scripts/world/world_state.gd` | `res://scripts/rpg/world_state.gd` | **不一致**（注册文件不存在） |
| `GameEvents` | `*res://scripts/core/game_events.gd` | `res://scripts/rpg/game_events.gd` | **不一致**（注册文件不存在） |
| `SaveSystem` | `*res://scripts/world/save_system.gd` | 3 号交付 `res://scripts/rpg/save_delta_writer.gd`，**未交付 `save_system.gd`** | **不一致**（名称 + 路径双重） |
| `ChunkManager` | `*res://scripts/world/chunk_streaming.gd` | 同路径（Rank-1 件，存在） | 一致 |
| `SceneRouter` | `*res://scripts/core/scene_router.gd` | 同路径（Rank-1 件，存在） | 一致 |

**摸底实跑证据**（开工初 `godot --headless --path godot --quit`，`r7_logs/g3_quit_probe.log` 83 行，EXIT=0）：3 组 × 3 条 = **9 条 autoload ERROR**，逐字如 `ERROR: Attempt to open script 'res://scripts/world/world_state.gd' resulted in error 'File not found'.` / `ERROR: Failed to instantiate an autoload, can't load from path: ...`；另有 **9 条** `[ChunkManager] chunk_limgrave_* 加载跳过：scene_missing` WARNING。与上轮 Rank-1 `ASSEMBLY-REPORT.md` 登记的「18 条 ERROR 源于 3 号 autoload 路径与注册不一致」同源。

### 1.2 正式门禁复核（Rank-1 R8 并行修正后）

本轮期间 Rank-1 并行修正了 `project.godot`（复核时 `[autoload]` 段实读）：

```
WorldState="*res://scripts/rpg/world_state.gd"        ← 已改为 rpg 正确路径
GameEvents="*res://scripts/rpg/game_events.gd"        ← 已改为 rpg 正确路径
SaveSystem="*res://scripts/world/save_system.gd"      ← 仍为旧值
ChunkManager="*res://scripts/world/chunk_streaming.gd" ← 不变
SceneRouter="*res://scripts/core/scene_router.gd"     ← 不变
```

**运行期实证**（正式 W7 日志逐字）：

```
W7_DIAG reuse /root/WorldState (autoload already registered)
W7_DIAG reuse /root/GameEvents (autoload already registered)
W7_DIAG spawn /root/SaveDeltaWriter from res://scripts/rpg/save_delta_writer.gd
W7_DIAG spawn /root/ChunkWorldBridge from res://scripts/rpg/chunk_world_bridge.gd
W7_DIAG spawn /root/DialogueRunner from res://scripts/rpg/dialogue_runner.gd
W7_DIAG /root/WorldState resolvable: bridge=true writer=true runner=true
W7_DIAG members bridge.ws=true bridge.writer=true writer.ws=true writer.bus=true runner.ws=true
```

正式 G3 `--quit`（`g3.log` 14 行，EXIT=0）**不再出现 autoload 路径 ERROR、也不再出现 9 条 `scene_missing` WARNING**（Rank-1 已并行修正路径 / 补齐 chunk 场景）。

### 1.3 核对结论

- `world_state.gd` / `game_events.gd` **落位与注册现已一致**：注册路径 = `res://scripts/rpg/*.gd` = 实际落位；autoload 单例可被 3 号 `SaveDeltaWriter` / `ChunkWorldBridge` / `DialogueRunner` 经 `/root/` 命中（W7 实测 `resolvable=true` / `members=true`）。
- `SaveSystem` 仍注册 `res://scripts/world/save_system.gd`，而 3 号交付的是 `res://scripts/rpg/save_delta_writer.gd`（无 `save_system.gd`）——**名称 / 路径口径不一致，残留跨工位待裁决项**。3 号本轮不改既有件、不新建 `save_system.gd`、不写 `project.godot`。
- 本核对**只核对与登记，未写 `project.godot` 一字**。

---

## 2. 任务 2 · SaveDelta / WorldState 与 ChunkManager 的 flag 读写联调实跑（三段式、只经 I-1）

链路：`ChunkManager` 侧原始 key → `ChunkWorldBridge.normalize_*` 三段式归一 → 只经 `WorldState.get_flag / set_flag`（I-1）→ `SaveDelta` 内存快照 → `GameEvents` 加载边界信号 → `ChunkWorldBridge` → `SaveDeltaWriter.commit(reason)` → `WorldState._commit_delta` → `.tmp → rename` 原子写盘。**测试脚本不直接读写存档文件做业务依赖**（`delta.json` 仅在 commit 后作验收读取）。

实际输出逐字（`w7.log`）：

```
W7_PASS T2_RAW_INVALID | raw=chunk.chunk_limgrave_0_0.loaded I-1_three_segment=false
W7_PASS T2_NORM_VALID | norm=world.chunk_limgrave_0_0.loaded I-1_three_segment=true
W7_PASS T2_NORM_WRITTEN | get_flag(norm,false)=true
W7_PASS T2_COLLECT | collected={ "world.chunk_limgrave_0_0.loaded": true, "world.dot.key": <null> } norm_val=true
W7_PASS T2_SD_TS_ORDER | timestamp ascending beats seq order
W7_PASS T2_SD_UNION | defeated union=["e1", "e2"] epoch=2
W7_DIAG after_dungeon_emit delta_exists=true user_dir=C:/Users/62668/AppData/Roaming/Godot/app_userdata/艾尔登法环 · HD-2D
W7_PASS T2_DELTA_WRITTEN | delta.json parsed after dungeon_enter commit
W7_PASS T2_RAW_ABSENT | chunk.* raw key NOT persisted (I-1 rejected)
W7_PASS T2_NORM_PRESENT | world.*.loaded present in delta flags
W7_PASS T2_COMMIT_REASON | reason=dungeon_enter
```

逐项结论：

| 检查 | 实际结论 |
|---|---|
| 三段式校验 | 原始 `chunk.<id>.loaded` 首段非法（I-1 正则首段白名单仅 `world/quest/combat/grace/dungeon`）；归一产物 `world.<id>.loaded` 合法 |
| 原始 key 写入 | `WorldState.set_flag` 对非法 key `push_warning` 并忽略（`w7.log:26` 预期 WARNING），`delta.json` 中 `T2_RAW_ABSENT` 证实未进存档 |
| 归一 key 写入 | `get_flag(norm,false)=true`；`ChunkWorldBridge.collect_world_flags()`（ChunkManager `_apply_world_flags` 只读收集入口）经 `get_flag` 收集到 `true` |
| `SaveDelta` 静态类一致性 | M4 timestamp 升序回放（seq 与 timestamp 反序时以 timestamp 为准）、M1 `spawns.defeated` 集合并集只增不减 + `epoch=max` 实跑通过 |
| 强制落盘链路 | `GameEvents.dungeon_transition_requested` → `reason=dungeon_enter` → `delta_exists=true`，落盘 `flags` 含归一 key、不含原始 key |

**跨模块信号实证**：正式 W7 日志 `w7.log:79-92` 的 backtrace 显示 **Rank-1 `chunk_streaming.gd:243 _finish_load` → `chunk_loaded.emit` → 3 号 `chunk_world_bridge.gd:96 _on_chunk_loaded`** 真实触发（非模拟）：

```
WARNING: [ChunkWorldBridge] 归一后仍非法：world.chunk_limgrave_-1_-1.loaded
   [0] _on_chunk_loaded (res://scripts/rpg/chunk_world_bridge.gd:96)
   [1] _finish_load (res://scripts/world/chunk_streaming.gd:243)
   [2] _poll_loads (res://scripts/world/chunk_streaming.gd:213)
```

**本轮新发现（只登记不擅改）**：Rank-1 `ChunkManager` 的 chunk_id 含负坐标（如 `chunk_limgrave_-1_-1`），连字符 `-` 不在 I-1 三段式第二段 `[a-z0-9_]+` 允许范围，故 `normalize_chunk_flag()` 产物 `world.chunk_limgrave_-1_-1.loaded` **仍非法**，bridge 按既有逻辑 `push_warning` 但不写 flag。这是「`chunk.<id>.loaded` 三段式归一口径」待裁决项（R5-待裁决登记 §2 / RPG-ASSEMBLY §4.2）的**延伸事实**，非 3 号可单方修改的实现缺陷；最终口径（A 改前缀 / B 扩白名单含 `chunk` / C 不进存档）仍待总指挥裁决。本轮**未改 Rank-1 文件、未改 §3.1 正则、未改 `world_state.gd:24` `FLAG_KEY_REGEX`**。

---

## 3. 任务 3 · M6 赐福传送网络工程根内实跑一次传送流程（6 区域 / 8 赐福覆盖）

资源均为工程根落位件：`res://data/rpg/grace_network.tres`（`GraceNetwork`，8 节点 / 7 边）、`res://data/rpg/m6_area_bindings.tres`（`M6AreaBindings`，6 区域）。实际输出逐字：

```
W7_PASS T3_LOAD | grace_network=true m6_bindings=true
W7_PASS T3_NODES_8 | grace_nodes=8
W7_PASS T3_EDGES_7 | edges=7
W7_PASS T3_AREAS_6 | area_bindings=6
W7_PASS T3_COVER_AREAS | 6/6 areas cover every node.area_id
W7_PASS T3_COVER_GRACES | 8/8 graces bound=8
W7_PASS T3_FLAGS_3SEG | all lit/unlocked flags are I-1 three-segment
W7_PASS T3_EDGE_OPEN | grace_limgrave_gatefront -> grace_limgrave_chapel edge has no prerequisites
W7_DIAG after_travel_emit delta_exists=true
W7_PASS T3_LANDING_FLAG | last_grace_id=grace_limgrave_chapel
W7_PASS T3_DELTA_EXISTS | delta.json parsed after grace_fast_travel commit
W7_PASS T3_COMMIT_REASON | reason=grace_fast_travel
W7_PASS T3_DELTA_FLAGS | delta flags=["grace.network.last_grace_id", "world.chunk_limgrave_0_0.loaded"]
W7_PASS T3_GATE_BEFORE | before: world.limgrave_bridge_01.crossed=false
W7_PASS T3_GATE_AFTER | after set_flag: world.limgrave_bridge_01.crossed=true
W7_PASS T3_GATE_EDGE_PASS | conditional edge now passable
W7_PASS T3_GATE_LOCKED | boss-gated edge stays locked
```

一次完整传送流程（`grace_limgrave_gatefront → grace_limgrave_chapel`，该边 `requires_flags={}`）：

1. 覆盖率校验：**6/6 区域**（`area_limgrave` / `area_weeping_peninsula` / `area_stormveil_outskirts` / `underground_01_siofra_well` / `dungeon_01_bellvault` / `dungeon_02_sunless_tomb`）、**8/8 赐福**（`grace_limgrave_gatefront` / `_chapel` / `_weeping_shore` / `_stormveil_gate` / `_bellvault_entry` / `_bellvault_deep` / `_sunless_tomb_entry` / `_siofra_well`）；所有 `lit_flag` / `unlocked_flag` 均为合法三段式。
2. 落点 flag `grace.network.last_grace_id` 经 I-1 写入 → 读回 `grace_limgrave_chapel`。
3. 传送边界信号 `GameEvents.travel_requested` → `ChunkWorldBridge._on_travel_requested` → `SaveDeltaWriter.commit(reason=grace_fast_travel)` → `WorldState._commit_delta` → 原子写盘，`delta_exists=true`、`T3_COMMIT_REASON` 与 `T3_DELTA_FLAGS` 实测落盘内容一致。
4. 带前置边门控（运行期求值、不缓存）：`world.limgrave_bridge_01.crossed` false → 不可传送；经 `set_flag` 置 true 后 → 边可传送；`combat.boss_01_margit.defeated` 未满足 → `grace_stormveil_gate` 边保持锁定。

**边界如实登记**：6 条 `scene_path`（`res://scenes/areas/*.tscn` / `res://scenes/dungeons/*.tscn`）属 Rank-1 场景，本轮只做「数据表 + flag + 信号 + 强制落盘」流程实跑，**未调用 `SceneRouter`/`change_scene_to_file` 做实机换场景**（SceneRouter 属 1 号，超 3 号范围）；`m6_area_bindings.tres` 的 `chunk_origin_x/y` 仍全 0（待 Rank-1 场景布局数据回填，RPG-ASSEMBLY §4.4 第 2 项），不擅改。

---

## 4. 任务 4 · 语音键表与对话节点运行期触发验证（沿用 3 个 WAV，不启动 GPU job）

组件：`VoiceLineBinder`（`res://scripts/rpg/voice_line_binder.gd`，`KEY_TABLE_PATH = res://data/rpg/voice_key_table.json`）、`DialogueRunner`（`res://scripts/rpg/dialogue_runner.gd`）、`res://data/rpg/dialogue_and_quest.tres`（`DialogueGraph` 主图 + `linked_graphs` 赐福回忆图）、3 个 WAV。实际输出逐字：

```
W7_PASS T4_BIND_COUNT | key_table_bound=3 (expect 3)
W7_PASS T4_GRAPH_LOAD | dialogue_and_quest.tres loaded=true
W7_PASS T4_KEYTABLE_OPEN | voice_key_table.json opened=true
W7_PASS T4_CROSS_LINES | missing_lines=[]
W7_PASS T4_CROSS_GRAPHS | missing_graphs=[]
W7_PASS T4_RESOLVE | line_bellkeeper_01 -> res://assets/audio/voice/vo_bellkeeper_01.wav
W7_PASS T4_NODE_LINE | line_bellkeeper_01 exists in graph=graph_npc_bellkeeper node=node_first_meet
W7_PASS T4_WAV_LOAD | res://assets/audio/voice/vo_bellkeeper_01.wav loaded_as=AudioStream
W7_PASS T4_WAV_BYTES | line_bellkeeper_01 bytes=308800 expect=308800
W7_PASS T4_RESOLVE | line_bellkeeper_02 -> res://assets/audio/voice/vo_bellkeeper_02.wav
W7_PASS T4_NODE_LINE | line_bellkeeper_02 exists in graph=graph_npc_bellkeeper node=node_first_meet
W7_PASS T4_WAV_LOAD | res://assets/audio/voice/vo_bellkeeper_02.wav loaded_as=AudioStream
W7_PASS T4_WAV_BYTES | line_bellkeeper_02 bytes=206022 expect=206022
W7_PASS T4_RESOLVE | line_memory_01 -> res://assets/audio/voice/vo_grace_memory_01.wav
W7_PASS T4_NODE_LINE | line_memory_01 exists in graph=graph_grace_bellkeeper_memory node=node_grace_memory
W7_PASS T4_WAV_LOAD | res://assets/audio/voice/vo_grace_memory_01.wav loaded_as=AudioStream
W7_PASS T4_WAV_BYTES | line_memory_01 bytes=249644 expect=249644
W7_EVT dialogue_opened graph=graph_npc_bellkeeper trigger=npc_talk
W7_PASS T4_RUNNER_OPEN | dialogue_opened emitted (trigger_source=npc_talk)
W7_PASS T4_ONENTER_FLAG | on_enter_flags wrote world.npc_01_bellkeeper.met=true via I-1
```

| vo_id | 触发源 | graph / node / line | 运行期 WAV 加载 | 字节（实测 / 键表） |
|---|---|---|---|---|
| `vo_bellkeeper_01` | `npc_talk` (`npc_01_bellkeeper`) | `graph_npc_bellkeeper` / `node_first_meet` / `line_bellkeeper_01` | `AudioStream` | 308800 / 308800 |
| `vo_bellkeeper_02` | `npc_talk` (`npc_01_bellkeeper`) | `graph_npc_bellkeeper` / `node_first_meet` / `line_bellkeeper_02` | `AudioStream` | 206022 / 206022 |
| `vo_grace_memory_01` | `grace_memory` (`grace_bellvault_entry`) | `graph_grace_bellkeeper_memory` / `node_grace_memory` / `line_memory_01` | `AudioStream` | 249644 / 249644 |

- `cross_check` 对真实 `DialogueGraph` 抽出的合法 `line_id` / `graph_id` 集合校验 3 条键表条目：`missing_lines=[]` / `missing_graphs=[]`。
- `DialogueRunner.open_graph()` 运行期触发 `dialogue_opened` 信号，`on_enter_flags` 经 I-1 写回 `world.npc_01_bellkeeper.met=true`（门控求值瞬时不缓存）。
- 3 个 WAV 沿用 **R3 qwen-tts 本地真跑产物**（24 kHz / mono / 16-bit PCM），`ResourceLoader.load` 运行期加载为 `AudioStream` 成功、字节逐条一致；**本轮未启动任何 GPU job / qwen-tts**，`stable-audio` gated 403 不申请不绕过、零付费 / 零外部依赖。
- **边界如实登记**：`dialogue_runner.gd:154 _present_line` 仍为 `pass`（UI 呈现属 Rank-1，接入点 `VoiceLineBinder → DialogueRunner._present_line` 待裁决 D2）。本轮验证的是「语音键表 ↔ 真实对话节点 / line ↔ WAV」在 **Godot 运行期**的解析、命中与加载，不是 UI 实际播放；**未改 `_present_line`、未改任何既有交付件**。

---

## 5. 任务 5 · 三段门禁真跑 + `SCRIPT ERROR` grep（实际输出，不冒充全绿）

| 段 | 实际命令 | 退出码 | 实际输出结论 |
|---|---|---|---|
| G0 | `<godot> --version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| G1 | `<godot> --headless --path godot --import` | `0` | `g1.log` 21 行：`first_scan_filesystem` 5 steps `[ DONE ]`、`update_scripts_classes` `[ DONE ]`、`loading_editor_layout` `[ DONE ]`；**无 Parse Error / ERROR / WARNING** |
| G2 | `<godot> --headless --path godot --check-only --script res://scripts/rpg/<各 .gd>` × 23 | **22 条 `0` / 1 条 `1`** | `G2_TOTAL=23 G2_FAIL=1`；失败项 `res://scripts/rpg/spawn_request.gd`：`SCRIPT ERROR: Parse Error: Class "SpawnRequest" hides a global script class.` |
| G3 | `<godot> --headless --path godot --quit` | `0` | `g3.log` 14 行：版本行 + 2 条 `SpawnRequest` 冲突 ERROR + 1 条 `ObjectDB leaked` WARNING；**无 autoload 路径 ERROR、无 `scene_missing` WARNING** |
| W7 | `<godot> --headless --path godot --quit-after 5 res://scripts/rpg/r7_wiring_test.tscn` | `0` | `w7.log` 94 行，`W7_SUMMARY pass=45 fail=0`（`W7_FAIL` 0 条） |

合并 `g0.log + g1.log + g2_*.log + g3.log + w7.log` → `all.log`（**180 行**）。Bash `grep -nEi "SCRIPT ERROR|Parse Error|ERROR|Failed loading|WARNING" all.log` 与 **Grep 工具**对 `all.log` 同模式复核，结果一致，逐条归因如下（**如实登记，不冒充全绿**）：

| 行 | 命中 | 归因 |
|---|---|---|
| 63 / 65 | `SCRIPT ERROR: Class "SpawnRequest" hides a global script class.` / `ERROR: Failed to load script "res://scripts/rpg/spawn_request.gd"` | **G2**：`spawn_request.gd` `--check-only` EXIT=1（跨工位冲突，见 §6） |
| 75 / 80 | 同上 2 条 | **G3**：autoload `WorldState._ready() → _register_baseline → ResourceLoader.load(spawn_bellvault_elite_01.tres)` 触发 |
| 89 / 94 | 同上 2 条 | **W7**：autoload `WorldState` 同上 |
| 85 / 179 | `WARNING: 2 ObjectDB instances were leaked at exit` | headless 退出噪音（G3 / W7 各 1 条），非脚本错误 |
| 99 | `WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。` | Rank-1 ChunkManager autoload 无 `ChunkRoot` 场景节点，降级（跨工位） |
| 112 | `WARNING: I-1: 非法 flag key，写入忽略：chunk.chunk_limgrave_0_0.loaded` | **联调预期拒绝**：验证原始 `chunk.*` key 被 I-1 拒绝，非缺陷 |
| 165 / 172 | `WARNING: [ChunkWorldBridge] 归一后仍非法：world.chunk_limgrave_-1_-1.loaded` / `world.chunk_limgrave_0_-1.loaded` | **本轮新发现**：负坐标 chunk_id 含 `-`，三段式第二段非法（§2），待裁决 |
| 164 | `W7_SUMMARY pass=45 fail=0` | 联调断言全通过 |

**`SpawnRequest` 冲突根因（跨工位，只登记不擅改）**：Grep 复核 `class_name SpawnRequest` 命中两处——

```
godot/scripts/combat/spawn_request.gd:2:class_name SpawnRequest      ← Rank-2 件
godot/scripts/rpg/spawn_request.gd:2:class_name SpawnRequest        ← 3 号工位件
```

工程根装配后两文件同处一个 Godot 工程，全局类 `SpawnRequest` 重复注册 → `rpg/spawn_request.gd` 解析为 Parse Error（G2 EXIT=1），并在 `WorldState._register_baseline` 加载 `spawn_bellvault_elite_01.tres`（其 `[ext_resource]` 指向 rpg 的 spawn_request.gd）时连带 2 条 ERROR。R6 临时最小工程只复制 rpg 目录、未含 combat 目录，故未暴露；**完整工程根跨模块联调才暴露**。按契约 §7 与用户约束「跨工位 ERROR 如实登记、不擅改对方文件、既有件不重做」，本轮**未改 combat 目录、未改 rpg 既有件、未移除 / 改名任何 `class_name`**，交总指挥裁决归属与方案。

---

## 6. 待裁决项保留登记（只登记、不擅改）

| # | 项 | 状态 | 来源 / 说明 |
|---|---|---|---|
| 1 | §4.4 九项对照（旧措辞回改）+ 方案 A/B/C | **待裁决 · 未改原文一字** | `R5-待裁决登记.md` §1、RPG-ASSEMBLY §4.1；`存档与flag规范.md` 属 Rank-1 文档 |
| 2 | `chunk.<id>.loaded` 三段式归一口径（A/B/C）、是否同步改 §3.1 正则与 `world_state.gd:24` | **待裁决 · 未改** | `R5-待裁决登记.md` §2、RPG-ASSEMBLY §4.2；本轮实跑新增「负坐标 chunk_id 含 `-` 归一后仍非法」证据（§2） |
| 3 | `SaveSystem` autoload 注册 `res://scripts/world/save_system.gd` vs 3 号交付 `res://scripts/rpg/save_delta_writer.gd` | **残留跨工位 · 只登记** | §1.2；`project.godot` 属 Rank-1 独占 |
| 4 | `class_name SpawnRequest` 重复注册（combat / rpg 两处） | **跨工位冲突 · 只登记** | §5；G2 `G2_FAIL=1`、6 条 ERROR 全部源于此 |
| 5 | `dialogue_runner.gd:154 _present_line` 为 `pass`；`VoiceLineBinder` 接入 Runner | **待裁决 · 未改** | `R5-待裁决登记.md` §4.2 D2、RPG-ASSEMBLY §4.4 第 5 项 |
| 6 | 6 条 `res://scenes/*` `scene_path`、`m6_area_bindings.tres` `chunk_origin_x/y` 全 0 | **跨工位 · 保留未改** | RPG-ASSEMBLY §4.4 第 1/2 项 |
| 7 | `save_delta.gd`（独立静态类）与 `world_state.gd`（内联）最终归属 | **沿用未决** | `DONE-R3.md` §3.1、`DONE-R4.md` §3.3 |
| 8 | `[ChunkManager] 未找到 ChunkRoot` / `ObjectDB leaked at exit` WARNING | **跨工位 / 引擎退出噪音 · 如实登记** | §5 |

---

## 7. 合规声明

- **只写** `godot\scripts\rpg\`（2 个新建载体）、`Rank-3\`（本件 + `DONE-R7.md`）、`command_center\ai\3\outbox\`（唯一回执例外）；**未写 `godot\project.godot`**、未写其它工位 / 子目录、未覆盖任何既有文件（既有件 mtime 保持 02:28~02:30）。
- **不写总线 / 总纲 / 契约 / 任务书 / 进度台账**；不自行 `git commit` / `git push`。
- **既有件不重做**：22 个 `.gd` / 6 份 `.tres` / 2 json / 3 WAV 一字未改；3 个 WAV 沿用 R3 真跑产物，未启动 GPU job / qwen-tts。
- **待裁决项只登记不擅改**；**零付费 / 零外部依赖**；`stable-audio` gated 403 不申请不绕过；默认不刺探（仅目的性读取联调所需文件；`r7_wiring_test.gd` 是本轮联调验证载体而非刺探探针，未写进度巡检 / 测量 / preflight 脚本）；中文 UTF-8；Godot 4 合法语法。
- **未伪造任何真跑输出**：G2 `G2_FAIL=1`、6 条 `SpawnRequest` ERROR、6 条 WARNING 全部如实登记并归因；联调 `pass=45 fail=0` 为 W7 实测输出；运行时 `user://` 存档产物由载体 `_cleanup()` 清理，日志置于系统临时目录、收尾删除。
