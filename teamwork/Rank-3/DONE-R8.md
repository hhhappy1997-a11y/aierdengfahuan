# DONE-R8.md · Rank-3（RPG / 世界 / 存档）R8：SaveSystem 口径与负坐标归一

> 轮次：**R8**｜工位：**3 号**｜派单 task_id `cmd-20261109-030933-293-A3`｜中文 UTF-8
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（G0 实测 `4.7.2.stable.official.ed1daf0bf`）
> 真跑载体：**完整工程根** `F:\Game\aierdengfahuan\godot\`（`--path` 指向该目录，`res://` 根 = `godot\`）
> 依据：`任务书-R8.md`、`RPG-WIRING.md`、`R5-待裁决登记.md`、`00-协作契约.md`（I-1 / I-3）、`00-群聊总线.md`（开工只读一次，`MSG-20261109-0309-HOST` 裁决）、`DONE-R7.md`。

**结论摘要**：四项任务全部执行并真跑完成。任务 1 / 3 **只登记 + 给建议，未越界改 Rank-1**；任务 2 负坐标归一**在本工位 / 本授权目录内落地**，真跑 `R8_NORM_SUMMARY pass=18 fail=0`；任务 4 复跑 `W7_SUMMARY pass=45 fail=0`（与 R7 基线逐字一致，**无新增失败**），三段门禁 G0/G1/G2/G3/W7/R8 全 `EXIT=0`、`G2_TOTAL=24 G2_FAIL=0`、`SCRIPT ERROR` / `ERROR` 均 0（仍余 4 类独立 WARNING，逐条归因、不冒充全绿）；跨工位并行时序问题如实登记。回执按本任务单 id 写入 `command_center\ai\3\outbox\` 后由中枢即时消费归档至 `command_center\dispatcher\receipts\cmd-20261109-030933-293-A3.json`（内容逐字一致），`ai\3\status.json` 已置 `state=idle / completed=8 / last_seen=2026-11-09 03:29:14`。**未伪造任何真跑输出**（含 R8 载体 v1 的 1 条 FAIL 迭代）。

---

## ① 实际交付清单

| # | 文件 | 类型 | 说明 |
|---|---|---|---|
| 1 | `godot\scripts\rpg\chunk_world_bridge.gd` | **修改**（授权既有件） | R8 归一增强：新增 `sanitize_flag_segment()`，增强 `normalize_chunk_flag()` / `normalize_flag_key()`；不改 `FLAG_KEY_REGEX` / `VALID_MODULES` / 对方文件 |
| 2 | `teamwork\Rank-3\chunk_world_bridge.gd` | **修改**（工位源副本） | 与 #1 同步，最终 `diff` = `IDENTICAL`（9217 B） |
| 3 | `godot\scripts\rpg\r8_neg_chunk_test.gd` | **新建**（可写范围） | R8 负坐标归一验证载体，`extends SceneTree`，`--script` 运行，18 条静态断言；**本轮联调验证载体，非刺探 / 巡检 / 测量 / preflight 脚本** |
| — | `godot\scripts\rpg\r8_neg_chunk_test.gd.uid` | 引擎产物 | G1 `--import` 自动生成，非手工写入 |
| 4 | `teamwork\Rank-3\DONE-R8.md` | **新建** | 本件（①交付清单 ②自检含真跑实际输出结论 ③未完成项与阻塞） |
| 5 | `command_center\ai\3\outbox\cmd-20261109-030933-293-A3.json` | **回执** | 唯一回执例外，按本任务单 id 写入；中枢即时消费归档至 `command_center\dispatcher\receipts\cmd-20261109-030933-293-A3.json`（内容逐字一致），`ai\3\status.json` 置 `state=idle / completed=8` |
| — | `SaveSystem` autoload 归属 / `_present_line` UI 归属 | **登记（无文件改动）** | 只登记事实与建议、不选定结论，见 §2.1 / §2.3 |

**未写**：`godot\project.godot`（**Rank-1 独占**）、`godot\scripts\combat\`、其它工位子目录、总线 / 总纲 / 契约 / 任务书 / 进度台账。
**既有件不重做、不覆盖**：22 个 `.gd` / 6 份 `.tres` / 2 份 `voice_*.json` / 3 个 WAV 一字未改（mtime 保持 02:28~02:30）；`r7_wiring_test.gd` 保持 03:03 未改；`data/rpg` 8 件未动。本轮唯一改动的既有代码件是 `chunk_world_bridge.gd`（两份副本），属 R8 授权归一增强。

---

## ② 自检（真跑实际输出结论）

### 2.1 任务 1 · `SaveSystem` autoload 归属（只登记 + 建议，不写 `project.godot`、不越界改 Rank-1）

**现状（只读核对，逐字）**：
- `project.godot`（Rank-1 独占）`[autoload]` 实读：`WorldState="*res://scripts/rpg/world_state.gd"`、`GameEvents="*res://scripts/rpg/game_events.gd"`（**均已与 3 号落位一致**）；`SaveSystem="*res://scripts/world/save_system.gd"`；`ChunkManager` / `SceneRouter` 不变。
- Rank-1 `godot\scripts\world\save_system.gd`（只读核对）：`extends Node`、`_ready(): pass`，注释明确「装配占位，不实现存档读写，存档按 I-1 / 契约 §6 仍归 Rank-3；真实实现由 Rank-3 落位后由 HOST 裁决改指向」。`project.godot` 第 22~29 行 R8 装配层闭合注释亦明确「SaveSystem 保留占位、注册路径不变」。
- 3 号存档真实实现（均 `res://scripts/rpg/`）：`world_state.gd` = I-1 权威（flag 合并 / schema / 原子写，**已作为 `WorldState` autoload 注册**）；`save_delta_writer.gd` = 写入时机 / 强制落盘 `commit(reason)`（订阅 I-2），**不是 autoload**，3 号内部节点由 bridge / 载体按路径实例化为 `/root/SaveDeltaWriter`；`chunk_world_bridge.gd` = 加载边界桥接。3 号**未交付** `save_system.gd`，也无同名 `SaveSystem` 单例。

**两个候选方案评估（只给建议、不选定、不执行）**：
- 方案 A「`SaveSystem` 改指向 `save_delta_writer.gd` 包装」：**不建议**。① `save_delta_writer.gd` 注释明确「对外（1/2 号）不暴露任何方法」，是 I-2 订阅 + `commit(reason)` 内部节点，不是存档门面；② 单例名会变成 `SaveSystem`，而 3 号内部与 W7 载体都按 `/root/SaveDeltaWriter` 命中，口径分裂；③ 需改 `project.godot`（Rank-1 独占）且可能要给 writer 补门面方法（重做既有件）。
- 方案 B「保留 Rank-1 占位」（现状，Rank-1 R8 已落地）：**建议保留**。① I-1 权威 `WorldState` 已是 autoload 且落位 / 注册一致（W7 实测 `resolvable=true`、`members=true`）；② 3 号无 `save_system.gd`、不新建、不越界写 `scripts/world/`；③ G3 真跑无 autoload ERROR，占位件可正常实例化，装配层已闭合；④ 与 `project.godot` R8 注释、占位件注释口径一致。
- 若将来 HOST 仍需统一门面：建议由 3 号在 `scripts/rpg/` 新建正式 `save_system.gd` 门面（委托 `WorldState` + `SaveDeltaWriter`），再由 Rank-1 改 `project.godot` 注册指向；属新交付 + 跨工位改注册，需 HOST 裁决执行方与轮次。**本轮不做**。

**本轮处置**：只登记事实与建议，**未写 `project.godot` 一字、未改 Rank-1 `save_system.gd`、未在 `scripts/rpg/` 新建 `save_system.gd`、未选定结论**，交 HOST 裁决。

### 2.2 任务 2 · 负坐标 chunk_id 归一方案落地（本工位 / 本授权目录内，不改对方文件）

**问题**（R7 §2 实测）：Rank-1 `ChunkManager` 生成负坐标 chunk_id（`chunk_limgrave_-1_-1`、`chunk_limgrave_0_-1`），`-` 不在 I-1 三段式第二段 `[a-z0-9_]+` 允许集；旧版 `normalize_chunk_flag()` 直接拼接 → `world.chunk_limgrave_-1_-1.loaded` 仍非法，bridge `push_warning「归一后仍非法」` 并丢弃（R7 `w7.log` 两条 WARNING）。

**方案（只在 `chunk_world_bridge.gd` 内落地）**：
- 新增 `sanitize_flag_segment(seg)`：逐字符把 `-` 编码为 `NEG_TOKEN = "neg"`（`-1 → neg1`），其余 `[a-z0-9_]` 原样保留，其它非法字符（大写 / `.` / 空格等）丢弃；结果只含 `[a-z0-9_]`，必定满足 I-1 三段式。
- 增强 `normalize_chunk_flag(chunk_id)`：`chunk_limgrave_-1_-1` → `world.chunk_limgrave_neg1_neg1.loaded`；`chunk_limgrave_0_-1` → `world.chunk_limgrave_0_neg1.loaded`；`chunk_limgrave_-12_-3` → `world.chunk_limgrave_neg12_neg3.loaded`。
- 增强 `normalize_flag_key(raw_key)`：obj / state 段同样清洗，`chunk.chunk_limgrave_0_-1.loaded` → `world.chunk_limgrave_0_neg1.loaded`（使 `collect_world_flags()` 对负坐标 key 也能收敛）。
- **不改**：`world_state.gd:24 FLAG_KEY_REGEX`、`存档与flag规范.md` §3.1 正则、`VALID_MODULES` 首段白名单、`is_valid_flag_key()` 实现、Rank-1 `chunk_streaming*.gd` 的 chunk_id / flag 命名。待裁决项 B（chunk flag A/B/C 最终口径）仍只登记不擅改。
- 定位：只生成「稳定 / 唯一 / 合法」的 flag 段，不做业务反解；**无 `-` 时输出与旧版逐字一致**（既有 45 项断言零回归）；对契约 §2 生成的 chunk_id（区域 slug `[a-z0-9_]`、坐标 `[0-9-]+`）稳定且无碰撞。

**落地件**：`godot\scripts\rpg\chunk_world_bridge.gd`（工程根落位件，真跑加载此件）+ `teamwork\Rank-3\chunk_world_bridge.gd`（工位源副本），最终 `diff` = `IDENTICAL`。

**真跑实证**：新建 `r8_neg_chunk_test.gd`（`--script` 运行，18 条纯静态断言）→ `R8_NORM_SUMMARY pass=18 fail=0`（逐条见 §2.4 `r8norm.log`）：3 组负坐标（含多位数 `-12/-3`）归一产物合法且无 `-`；正坐标 `chunk_limgrave_0_0` 产物与 R7 基线逐字一致；`normalize_flag_key` 负坐标收敛 / 4 段输入返回空 / 合法 key 不变；`sanitize_flag_segment` 负号转义 / 幂等 / 非法字符丢弃；**`chunk.*` 原始首段仍非法**（证明未擅自扩展 I-1 白名单）。`is_valid_flag_key()` 的正则与 `world_state.gd:24` 逐字一致，叠加 W7 `T2_NORM_WRITTEN`（合法三段式经 `WorldState.set_flag/get_flag` 写入读回）→ 归一产物经 I-1 可写入。

**迭代如实登记（未伪造）**：R8 载体 v1 曾 `pass=17 fail=1`，唯一 FAIL 为 `R8_NORM_FLAGKEY_4SEG`——断言自身把 `"no.dot.key"` 误判为 4 段（实为 3 段 `no/dot/key`，既有逻辑收敛为 `world.dot.key`，R7 `T2_COLLECT` 输出 `world.dot.key: <null>` 已佐证）。**归一实现未改**，仅把断言输入修正为真正的 4 段 `"a.b.c.d"`，v2 复跑 `pass=18 fail=0`。

### 2.3 任务 3 · `_present_line` 仍 `pass` 的 UI 归属登记（不越界改 Rank-1）

- `godot\scripts\rpg\dialogue_runner.gd:154-156`：`_present_line(line)` 函数体仍为 `pass`，注释「UI 呈现由 1 号负责；此处只按 trigger_source 决定是否显示立绘 / 覆盖 speaker」；`_present_choices()` 同为 `pass`。
- **归属**：UI 呈现层属 **Rank-1**（引擎架构与渲染 / 场景 UI）；`VoiceLineBinder → DialogueRunner._present_line` 接入点即 `R5-待裁决登记.md` §4.2 **D2**。
- 本轮 W7 任务 4 验证的是「语音键表 ↔ 真实对话节点 / line ↔ 3 个 WAV 在 Godot 运行期的解析、命中、加载」（`T4_*` 全 PASS，运行期加载为 `AudioStream`、字节逐条一致 308800 / 206022 / 249644），**不是 UI 实际播放**；3 个 WAV 沿用 R3 qwen-tts 本地真跑产物，未启动任何 GPU job，`stable-audio` gated 403 不申请不绕过。
- **本轮处置**：只登记，**未改 `dialogue_runner.gd` 一字、未改任何既有件**；接入执行方与轮次仍待 HOST 裁决（D2）。

### 2.4 任务 4 · I-1~I-3 联调断言复跑 + 三段门禁真跑 + `SCRIPT ERROR`/`ERROR` grep

**命令族**（引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`，`--path F:\Game\aierdengfahuan\godot`；日志置于系统临时目录 `C:\Users\62668\AppData\Local\Temp\r8_final_logs\`、收尾删除）：

| 段 | 实际命令 | EXIT | 实际输出结论 |
|---|---|---|---|
| G0 | `--version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| G1 | `--headless --path godot --import` | `0` | `g1.log` 16 行：`first_scan_filesystem` / `loading_editor_layout` 全 `[ DONE ]`，**无 Parse Error / ERROR / WARNING** |
| G2 | `--headless --path godot --check-only --script res://scripts/rpg/<f>.gd` × 24 | `0` | `G2_TOTAL=24 G2_FAIL=0`（24 个 rpg `.gd` 全 EXIT=0，含新建 R8 载体） |
| G3 | `--headless --path godot --quit` | `0` | `g3.log` 4 行：版本行 + 1 条 `ObjectDB leaked` WARNING；**无 autoload 路径 ERROR、无 `scene_missing` WARNING** |
| W7 | `--headless --path godot --quit-after 5 res://scripts/rpg/r7_wiring_test.tscn` | `0` | `w7.log` 70 行，`W7_SUMMARY pass=45 fail=0`，`W7_FAIL` 0 条 |
| R8 | `--headless --path godot --script res://scripts/rpg/r8_neg_chunk_test.gd` | `0` | `r8norm.log` 27 行，`R8_NORM_SUMMARY pass=18 fail=0`，`R8_NORM_FAIL` 0 条 |

**`W7_SUMMARY pass=45 fail=0` 与 R7 基线（`RPG-WIRING.md` §5 / `DONE-R7.md` ②）逐字一致 → 确认 I-1~I-3 联调断言复跑「无新增失败」**；归一增强后既有 45 项断言零回归（正坐标产物 `world.chunk_limgrave_0_0.loaded` 未变、`T2_COLLECT` / `T3_*` / `T4_*` 全 PASS）。

合并 `g0+g1+g2_*+g3+w7+r8norm → all.log`（**166 行**），`grep -nEi "SCRIPT ERROR|Parse Error|ERROR|Failed loading|WARNING"` 命中 **9 行**，逐条归因（**如实登记，不冒充全绿**：本轮 `ERROR` 确为 0，但仍有 WARNING）：

| 行 | 命中 | 归因 |
|---|---|---|
| 68 | `WARNING: 2 ObjectDB instances were leaked at exit` | G3 headless 退出噪音 |
| 72 / 73 | `WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。` + `at: push_warning` backtrace | W7，Rank-1 `ChunkManager` autoload 无 `ChunkRoot` 场景节点、降级（跨工位） |
| 85 / 86 | `WARNING: I-1: 非法 flag key，写入忽略：chunk.chunk_limgrave_0_0.loaded` + backtrace | W7，**联调预期拒绝**（验证原始 `chunk.*` 被 I-1 拒绝，非缺陷） |
| 138 | `WARNING: 2 ObjectDB instances were leaked at exit` | W7 退出噪音 |
| 161 / 162 | `WARNING: [ChunkManager] 未找到 ChunkRoot...` + backtrace | R8 `--script` 模式同样触发该 autoload 降级 |
| 165 | `WARNING: 2 ObjectDB instances were leaked at exit` | R8 退出噪音 |

**专项计数**：`SCRIPT ERROR` **0**、`ERROR` **0**、`Parse Error` **0**、`Failed loading` **0**、`SpawnRequest` 冲突 ERROR **0**、`归一后仍非法` WARNING **0**。

**跨工位并行时序问题（如实登记）**：
1. `SpawnRequest` 同名类冲突已由 **Rank-2 按 `MSG-20261109-0309-HOST` 裁决（裁定 `scripts/rpg/spawn_request.gd` 为唯一权威、combat 侧移除重复 `class_name`）在 R8 并行落地**：R7 的 `G2_FAIL=1` + 6 条 `SpawnRequest` ERROR 本轮全部清零（`G2_FAIL=0`、ERROR=0）。3 号本轮**未改** combat / rpg 任何 `spawn_request.gd`，该清零来自并行工位修正，**不冒充 3 号产出**。
2. **本轮 W7 运行期 Rank-1 `ChunkManager` 未触发负坐标 chunk 的 `chunk_loaded` 事件**（`w7.log` 无 `_finish_load → chunk_loaded.emit → _on_chunk_loaded` backtrace；R7 `w7.log:79-92` 有）。故「负坐标归一 WARNING 0 条」含并行时序因素，**不能单独作为归一生效的证据**；归一生效改由 R8 载体主动断言（18/0）证明，不伪造推断。
3. `project.godot` 本轮由 Rank-1 独占维护；G3 无 autoload ERROR 说明 `SaveSystem` 占位件存在且可实例化。3 号未写该文件。
4. `[ChunkManager] 未找到 ChunkRoot` WARNING 在 W7 与 R8 `--script` 两种运行模式均出现，属 Rank-1 场景侧持续状态，如实保留。
5. 真跑跨至 03:2x，期间其它工位可能并行写入；本轮只写授权目录、未覆盖任何并发产出、未自行裁决跨模块争议。

### 2.5 合规自检

- **只写**授权范围：`godot\scripts\rpg\`（改 1 既有件 + 新建 1 载体）、`teamwork\Rank-3\`（改 1 既有件 + 新建 `DONE-R8.md`）、`command_center\ai\3\outbox\`（回执例外）。**未写** `godot\project.godot`（Rank-1 独占）、`scripts\combat\`、其它工位、总线 / 总纲 / 契约 / 任务书 / 进度台账；不自行 `git commit` / `git push`。
- **既有件不重做**：22 个 `.gd` / 6 份 `.tres` / 2 份 `voice_*.json` / 3 个 WAV 一字未改（mtime 02:28~02:30）；`r7_wiring_test.gd` 保持 03:03 未改；`data/rpg` 8 件未动。唯一改动的既有代码件 `chunk_world_bridge.gd`（两份副本）属 R8 授权归一增强，`diff` 后仍逐字一致。
- 3 个 WAV 沿用 R3 qwen-tts 本地真跑产物，**未启动任何 GPU job / qwen-tts**；`stable-audio` gated 403 不申请不绕过；零付费 / 零外部依赖。
- **待裁决项只登记不擅改**：§4.4 九项、chunk flag A/B/C、`SaveSystem`、`_present_line`(D2)、`save_delta.gd` 归属、`scene_path` / `chunk_origin_x/y`、`SpawnRequest` 归属。
- `r8_neg_chunk_test.gd` 是本轮**联调验证载体**（非刺探 / 巡检 / 测量 / preflight 脚本）；默认不刺探，仅目的性读取必读件与联调所需文件。
- 运行时 `user://saves/slot_01/` 产物由 W7 载体 `_cleanup()` 清空（最终 `ls` 为空）；日志置于系统临时目录、收尾删除；中文 UTF-8；**Godot 4 合法语法**（24 个 `.gd` 全 `--check-only` EXIT=0）；**未伪造任何真跑输出**（含 R8 载体 v1 的 1 条 FAIL 迭代）。

---

## ③ 未完成项与阻塞

| # | 项 | 性质 / 阻塞 | 归属 |
|---|---|---|---|
| 1 | `SaveSystem` autoload 归属最终口径（保留 Rank-1 占位 / 改指向 3 号正式件） | **待裁决**；本轮只登记 + 建议保留现状，未写 `project.godot`、未新建 `save_system.gd` | HOST 裁决；`project.godot` 属 Rank-1 独占 |
| 2 | `chunk.<id>.loaded` 三段式归一最终口径（A / B / C）+ 是否同步改 §3.1 正则与 `world_state.gd:24` | **待裁决**；本轮只在 3 号归一函数内做负坐标编码，未选定口径、未改正则 / 白名单 / 对方文件 | HOST 裁决（`R5-待裁决登记.md` §2、`RPG-WIRING.md` §6） |
| 3 | `_present_line` 仍为 `pass`；`VoiceLineBinder → DialogueRunner` 接入点；语音「UI 实际播放」未验证 | **待裁决 D2**；UI 呈现属 Rank-1，本轮只登记未改 | HOST 裁决接入方 / 轮次；Rank-1 UI |
| 4 | §4.4 九项回改（旧措辞）、`save_delta.gd`（独立静态类）与 `world_state.gd`（内联）最终归属 | 沿用待裁决，本轮未推进 | HOST 裁决（`R5-待裁决登记.md` §1 / §5） |
| 5 | 6 条 `res://scenes/*` `scene_path` 未实机换场景；`m6_area_bindings.tres` `chunk_origin_x/y` 全 0 | `SceneRouter` / 场景布局属 Rank-1，超 3 号范围 | Rank-1 |
| 6 | `[ChunkManager] 未找到 ChunkRoot` WARNING、`ObjectDB instances were leaked at exit` × 3 | 跨工位场景侧 / headless 退出噪音，**非脚本错误** | 如实登记，无需 3 号处理 |
| 7 | 负坐标归一「运行期经 `ChunkManager` 真实 `chunk_loaded` 触发」的端到端实证 | 本轮 W7 运行期 Rank-1 未触发负坐标 chunk 加载（并行时序），已改由 R8 载体主动断言证明归一函数；端到端链路需 Rank-1 场景侧触发后联调 | 跨工位时序，待后续联调 |

> 裁决前，上述项保持「待裁决 / 跨工位 / 时序受限」状态；本轮实际交付与真跑结论以本件 ①② 为准。

---

## 合规声明

- 本轮**只写** `godot\scripts\rpg\`（`chunk_world_bridge.gd` 增强 + `r8_neg_chunk_test.gd` 新建）、`teamwork\Rank-3\`（`chunk_world_bridge.gd` 同步 + `DONE-R8.md`）、`command_center\ai\3\outbox\`（回执例外）；**未写 `godot\project.godot`**、未写其它工位 / 子目录、未覆盖任何并发产出。
- 不写总线 / 总纲 / 契约 / 任务书 / 进度台账；不自行 `git commit` / `git push`。
- 既有件不重做；待裁决项只登记不擅改；零付费 / 零外部依赖；`stable-audio` gated 403 不申请不绕过；不启动任何 GPU job；默认不刺探；中文 UTF-8；Godot 4 合法语法；**未伪造任何真跑输出**。
