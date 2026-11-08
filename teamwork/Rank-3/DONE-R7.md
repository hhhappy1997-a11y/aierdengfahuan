# DONE-R7.md · Rank-3（RPG / 世界 / 存档）R7 跨模块联调

> 轮次：**R7**｜工位：**3 号**｜派单 task_id `cmd-20261109-024906-803-A3`｜中文 UTF-8
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（G0 实测 `4.7.2.stable.official.ed1daf0bf`）
> 真跑载体：**完整工程根** `F:\Game\aierdengfahuan\godot\`（非 R6 临时最小工程），所有资源为工程根落位件。
> 详细联调记录：`Rank-3\RPG-WIRING.md`。本件为交付结论主件。

**结论摘要**：五项任务全部执行并真跑完成；联调断言 `W7_SUMMARY pass=45 fail=0`；三段门禁 **G0/G1/G3/W7 均 EXIT=0，G2 23 个脚本 22 通过 / 1 失败**（`rpg/spawn_request.gd` 因跨工位 `class_name SpawnRequest` 重复注册 Parse Error）。合并日志 180 行，grep 命中 6 条 `SpawnRequest` ERROR 与 6 条 WARNING，全部如实登记并归因，**不冒充全绿、不伪造输出**。

---

## ① 实际交付清单

| # | 文件 | 类型 | 说明 |
|---|---|---|---|
| 1 | `godot\scripts\rpg\r7_wiring_test.gd` | **新建**（可写范围） | R7 跨模块联调验证载体，`extends Node`，Godot 4 合法语法，`--check-only` EXIT=0；优先复用 Rank-1 已注册 autoload 单例，缺失才按正确落位路径补位；只经 I-1、不启动 GPU job |
| 2 | `godot\scripts\rpg\r7_wiring_test.tscn` | **新建**（可写范围） | 最小场景载体（`--quit-after 5 res://scripts/rpg/r7_wiring_test.tscn` 运行） |
| — | `godot\scripts\rpg\r7_wiring_test.gd.uid` | 引擎产物 | G1 `--import` 自动生成，非手工写入 |
| 3 | `teamwork\Rank-3\RPG-WIRING.md` | **新建** | 联调记录（五项任务方法 / 实际输出 / 归因 / 待裁决登记） |
| 4 | `teamwork\Rank-3\DONE-R7.md` | **新建** | 本件 |
| 5 | `command_center\ai\3\outbox\cmd-20261109-024906-803-A3.json` | **回执** | 唯一回执例外，按本任务单 id |

**未写**：`godot\project.godot`（**Rank-1 独占，本轮由它修正 autoload 路径**）、其它工位 / 其它子目录、总线 / 总纲 / 契约 / 任务书 / 进度台账。
**既有件不重做、不覆盖**：22 个 `.gd` + 6 份 `.tres` + 2 份 `voice_*.json` + 3 个 WAV 一字未改（mtime 保持 02:28~02:30）；`data/rpg` 8 件、3 个 WAV 数量未变。

---

## ② 自检（真跑实际输出结论）

### 2.1 五项任务逐项结论

**任务 1 · autoload 落位与注册一致性核对（只核对与登记，未写 project.godot）**
- 开工首次读取 `project.godot`：`WorldState` → `res://scripts/world/world_state.gd`、`GameEvents` → `res://scripts/core/game_events.gd`、`SaveSystem` → `res://scripts/world/save_system.gd`，三者注册文件均不存在；3 号实际落位 `res://scripts/rpg/*.gd`。摸底 `--quit` 实测 **9 条 autoload ERROR**（逐字 `ERROR: Attempt to open script 'res://scripts/world/world_state.gd' resulted in error 'File not found'.`）+ **9 条** `scene_missing` WARNING。
- 正式门禁复核（Rank-1 R8 并行修正后）：`WorldState="*res://scripts/rpg/world_state.gd"`、`GameEvents="*res://scripts/rpg/game_events.gd"` **已与落位一致**；`SaveSystem` 仍为旧值 `res://scripts/world/save_system.gd`（3 号未交付该文件，交付的是 `res://scripts/rpg/save_delta_writer.gd`）。
- 运行期实证（W7 逐字）：`W7_DIAG reuse /root/WorldState (autoload already registered)` / `reuse /root/GameEvents` / `W7_DIAG /root/WorldState resolvable: bridge=true writer=true runner=true` / `W7_DIAG members bridge.ws=true bridge.writer=true writer.ws=true writer.bus=true runner.ws=true`；正式 G3 无 autoload ERROR、无 `scene_missing` WARNING。
- **结论**：`world_state.gd` / `game_events.gd` 落位与注册一致；`SaveSystem` 名称 / 路径口径不一致，**只登记、待裁决**；本轮未写 `project.godot` 一字。

**任务 2 · SaveDelta / WorldState 与 ChunkManager 的 flag 读写联调实跑（三段式、只经 I-1）**
- 实跑输出（逐字）：`T2_RAW_INVALID raw=chunk.chunk_limgrave_0_0.loaded I-1_three_segment=false` / `T2_NORM_VALID norm=world.chunk_limgrave_0_0.loaded I-1_three_segment=true` / `T2_NORM_WRITTEN get_flag(norm,false)=true` / `T2_COLLECT collected={ "world.chunk_limgrave_0_0.loaded": true, "world.dot.key": <null> } norm_val=true` / `T2_SD_TS_ORDER timestamp ascending beats seq order` / `T2_SD_UNION defeated union=["e1", "e2"] epoch=2` / `W7_DIAG after_dungeon_emit delta_exists=true` / `T2_DELTA_WRITTEN` / `T2_RAW_ABSENT chunk.* raw key NOT persisted (I-1 rejected)` / `T2_NORM_PRESENT` / `T2_COMMIT_REASON reason=dungeon_enter` —— **全 PASS**。
- 链路实跑通：`GameEvents.dungeon_transition_requested` → `ChunkWorldBridge` → `SaveDeltaWriter.commit` → `WorldState._commit_delta` → `.tmp → rename` 原子写盘；原始 `chunk.*` key 写不进存档、归一 `world.*.loaded` 才能写入（待裁决口径，只登记不擅改）。
- **跨模块信号实证**：`w7.log:79-92` backtrace `ChunkManager._finish_load (chunk_streaming.gd:243)` → `chunk_loaded.emit` → `ChunkWorldBridge._on_chunk_loaded (chunk_world_bridge.gd:96)` 真实触发。
- **本轮新发现（只登记）**：负坐标 chunk_id（`chunk_limgrave_-1_-1`）含 `-`，归一后 `world.chunk_limgrave_-1_-1.loaded` 因三段式第二段 `[a-z0-9_]+` 不含连字符仍非法 → bridge `push_warning 归一后仍非法`。

**任务 3 · M6 赐福传送网络工程根内实跑一次传送流程（6 区域 / 8 赐福覆盖）**
- 实跑输出（逐字）：`T3_LOAD grace_network=true m6_bindings=true` / `T3_NODES_8 grace_nodes=8` / `T3_EDGES_7 edges=7` / `T3_AREAS_6 area_bindings=6` / `T3_COVER_AREAS 6/6 areas cover every node.area_id` / `T3_COVER_GRACES 8/8 graces bound=8` / `T3_FLAGS_3SEG` / `T3_EDGE_OPEN` / `W7_DIAG after_travel_emit delta_exists=true` / `T3_LANDING_FLAG last_grace_id=grace_limgrave_chapel` / `T3_DELTA_EXISTS` / `T3_COMMIT_REASON reason=grace_fast_travel` / `T3_DELTA_FLAGS delta flags=["grace.network.last_grace_id", "world.chunk_limgrave_0_0.loaded"]` / `T3_GATE_BEFORE/AFTER/EDGE_PASS/LOCKED` —— **全 PASS**。
- 一次完整传送 `grace_limgrave_gatefront → grace_limgrave_chapel`：覆盖率 6/6 区域 + 8/8 赐福、落点 flag 经 I-1 写入并读回、传送边界信号触发 `grace_fast_travel` 强制落盘并校验落盘内容、带前置边门控运行期求值（false→true→可传送；boss 门控保持锁定）。
- 未做 `change_scene_to_file` 实机换场景（SceneRouter 属 1 号，超范围），如实登记。

**任务 4 · 语音键表与对话节点运行期触发验证（沿用 3 个 WAV，不启动任何 GPU job）**
- 实跑输出（逐字）：`T4_BIND_COUNT key_table_bound=3` / `T4_GRAPH_LOAD loaded=true` / `T4_CROSS_LINES missing_lines=[]` / `T4_CROSS_GRAPHS missing_graphs=[]`；三条触发链 `line_bellkeeper_01 → vo_bellkeeper_01.wav loaded_as=AudioStream bytes=308800/308800`、`line_bellkeeper_02 → vo_bellkeeper_02.wav AudioStream 206022/206022`、`line_memory_01 → vo_grace_memory_01.wav AudioStream 249644/249644`（对应 `npc_talk` / `grace_memory` 触发源与真实 graph/node/line）；`W7_EVT dialogue_opened graph=graph_npc_bellkeeper trigger=npc_talk` / `T4_RUNNER_OPEN` / `T4_ONENTER_FLAG world.npc_01_bellkeeper.met=true via I-1` —— **全 PASS**。
- 3 个 WAV 沿用 R3 qwen-tts 本地真跑产物，运行期 `ResourceLoader.load` 为 `AudioStream` 成功、字节逐条一致；**未启动任何 GPU job / qwen-tts**；`stable-audio` gated 403 不申请不绕过。
- 边界：`dialogue_runner.gd:154 _present_line` 仍为 `pass`（UI 属 Rank-1，接入点待裁决），本轮验证的是运行期解析 / 命中 / 加载链，不是 UI 实际播放；未改既有件。

**任务 5 · 三段门禁真跑 + grep `SCRIPT ERROR`**

| 段 | 退出码 | 实际输出结论 |
|---|---|---|
| G0 `--version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| G1 `--headless --path godot --import` | `0` | `g1.log` 21 行，`first_scan_filesystem` / `update_scripts_classes` / `loading_editor_layout` 全 `[ DONE ]`，**无 Parse Error / ERROR / WARNING** |
| G2 `--check-only --script res://scripts/rpg/<f>.gd` × 23 | **22 `0` / 1 `1`** | `G2_TOTAL=23 G2_FAIL=1`；失败 `res://scripts/rpg/spawn_request.gd`：`SCRIPT ERROR: Parse Error: Class "SpawnRequest" hides a global script class.` |
| G3 `--headless --path godot --quit` | `0` | `g3.log` 14 行：版本行 + 2 条 `SpawnRequest` ERROR + 1 条 `ObjectDB leaked` WARNING；**无 autoload 路径 ERROR、无 scene_missing WARNING** |
| W7 联调场景 | `0` | `w7.log` 94 行，`W7_SUMMARY pass=45 fail=0`，`W7_FAIL` 0 条 |

合并 `all.log` = **180 行**；Bash `grep -nEi "SCRIPT ERROR|Parse Error|ERROR|Failed loading|WARNING" all.log` + Grep 工具复核一致，命中逐条归因：
- **6 条 ERROR**（3 组 × 2 条，行 63/65 G2、75/80 G3、89/94 W7）：`Class "SpawnRequest" hides a global script class` + `Failed to load script "res://scripts/rpg/spawn_request.gd"`。根因 `godot/scripts/combat/spawn_request.gd:2` 与 `godot/scripts/rpg/spawn_request.gd:2` 都声明 `class_name SpawnRequest`，工程根同时落位 → 全局类重复注册；触发点 `WorldState._ready() → _register_baseline` 加载 `spawn_bellvault_elite_01.tres`。**跨工位冲突，只登记不擅改**（R6 临时最小工程未含 combat 目录故未暴露）。
- **6 条 WARNING**：`85/179` `2 ObjectDB instances were leaked at exit`（headless 退出噪音）；`99` `[ChunkManager] 未找到 ChunkRoot`（Rank-1 场景侧降级）；`112` `I-1: 非法 flag key，写入忽略`（**联调预期拒绝**，非缺陷）；`165/172` `[ChunkWorldBridge] 归一后仍非法：world.chunk_limgrave_-1_-1.loaded` / `world.chunk_limgrave_0_-1.loaded`（本轮新发现，负坐标 chunk_id）。
- `164` `W7_SUMMARY pass=45 fail=0`。

> **不冒充全绿**：G2 有 1 个脚本 EXIT=1、日志有 6 条 ERROR 与 6 条 WARNING，全部如实登记并归因；联调断言 45 项全通过但门禁整体非全绿。

### 2.2 合规自检
- 只写授权范围；未写 `project.godot`、其它工位、总线 / 总纲 / 契约 / 任务书 / 进度台账；不自行 git。
- 既有件一字未改；3 个 WAV 沿用 R3 产物，零付费 / 零外部依赖，未启动 GPU job。
- 待裁决项（§4.4 九项、chunk flag 口径、`SaveSystem`、`_present_line`、`SpawnRequest` 冲突、负坐标 chunk_id、`scene_path` / `chunk_origin`）**只登记不擅改**。
- 运行时 `user://` 存档产物由载体 `_cleanup()` 清理；日志在系统临时目录、收尾删除；未伪造任何真跑输出。

---

## ③ 未完成项与阻塞

| # | 项 | 性质 / 阻塞 | 归属 |
|---|---|---|---|
| 1 | `class_name SpawnRequest` 重复注册（combat / rpg 两处） | **唯一导致门禁非全绿的实质项**：G2 `G2_FAIL=1` + 6 条 ERROR。跨工位冲突，需裁决归属 / 改名 / 移除方案 | 总指挥裁决；3 号未改任何文件 |
| 2 | `SaveSystem` autoload 仍注册 `res://scripts/world/save_system.gd`（3 号未交付该文件，交付 `res://scripts/rpg/save_delta_writer.gd`） | 名称 / 路径口径不一致，残留跨工位项 | Rank-1 独占 `project.godot` / 总指挥裁决 |
| 3 | 负坐标 chunk_id 含 `-`，归一后三段式仍非法 | `chunk.<id>.loaded` 归一口径待裁决项的延伸事实，本轮仅登记 | 总指挥裁决（A/B/C） |
| 4 | `[ChunkManager] 未找到 ChunkRoot` WARNING | Rank-1 场景侧无 `ChunkRoot` 节点，降级 | Rank-1 |
| 5 | `_present_line` 仍为 `pass`；语音「UI 实际播放」未验证 | 接入点待裁决 D2；本轮只验证运行期解析 / 加载链 | Rank-1 UI / 总指挥裁决接入方与轮次 |
| 6 | 6 条 `scene_path` 未实机换场景；`m6_area_bindings.tres` `chunk_origin_x/y` 全 0 | SceneRouter / 场景布局属 Rank-1，超 3 号范围 | Rank-1 |
| 7 | §4.4 九项回改、chunk flag 归一口径、`save_delta.gd` 归属 | 沿用待裁决项，本轮未推进 | 总指挥裁决 |
| 8 | `ObjectDB instances were leaked at exit` × 2 | headless 退出噪音，非脚本错误 | 如实登记，无需 3 号处理 |

---

## 合规声明

- 本轮**只写** `godot\scripts\rpg\`（2 个新建载体）、`Rank-3\`（`RPG-WIRING.md` + `DONE-R7.md`）、`command_center\ai\3\outbox\`（回执例外）；**未写 `godot\project.godot`**、未写其它工位 / 子目录、未覆盖任何既有文件。
- 不写总线 / 总纲 / 契约 / 任务书 / 进度台账；不自行 `git commit` / `git push`。
- 既有件不重做；待裁决项只登记不擅改；零付费 / 零外部依赖；`stable-audio` gated 403 不申请不绕过；默认不刺探；中文 UTF-8；Godot 4 合法语法；**未伪造任何真跑输出**。
