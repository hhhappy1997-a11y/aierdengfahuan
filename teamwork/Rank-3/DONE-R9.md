# DONE-R9.md · Rank-3（RPG / 世界 / 存档）R9：M6 探索线闭环与汇总材料

> 轮次：**R9**｜工位：**3 号**｜派单 task_id **`cmd-20261109-033148-252-A3`**｜中文 UTF-8
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（G0 实测 `4.7.2.stable.official.ed1daf0bf`）
> 真跑载体：**完整工程根** `F:\Game\aierdengfahuan\godot\`（`--path` 指向该目录，`res://` 根 = `godot\`）
> 依据：`任务书-R9.md`、`00-协作契约.md`、`00-群聊总线.md`（开工只读一次，`MSG-20261109-0331-HOST`）、`m6_area_bindings.tres` / `grace_network.tres`、`存档与flag规范.md`、`接口契约.md`、`DONE-R8.md` / `RPG-WIRING.md`。

**结论摘要**：四项任务全部执行并真跑完成。任务 1 / 2 / 3 产出三份汇总材料（M6 拓扑表 / 存档规范汇总 / I-1~I-3 一致性自检），均为**整理件**，不新增不修改任何既有 `.tres` / `.gd`；任务 4 在完整工程根亲自真跑三段门禁 + `W7_SUMMARY` + `R8_NORM_SUMMARY`：**G0/G1/G2/G3/W7/R8 全 `EXIT=0`**、`G2_TOTAL=24 G2_FAIL=0`、`W7_SUMMARY pass=45 fail=0`、`R8_NORM_SUMMARY pass=18 fail=0`，与 R7 / R8 基线**逐字一致 → 确认无回归**；`SCRIPT_ERROR=0` / `Parse_Error=0` / `Failed_loading=0`。如实登记：本轮 G1 出现 **8 条 `preset.0` 配置读取 ERROR**（Rank-1 R10 `export_presets.cfg` 并行中间态、非脚本错误），另有 9 条退出 / 跨工位 / 预期拒绝 WARNING，逐条归因、不冒充全绿。回执按本任务单 id 写入 `command_center\ai\3\outbox\` 后由中枢即时消费归档至 `command_center\dispatcher\receipts\cmd-20261109-033148-252-A3.json`（内容逐字一致、JSON 解析通过 `task_id` / `ai` / `status` 正确），`ai\3\status.json` 置 `state=idle / completed=9 / last_seen=2026-11-09 03:41:36`（与 R8 回执消费路径一致）。**未伪造任何真跑输出**、**未启动任何 GPU job**。

---

## ① 实际交付清单

| # | 文件 | 类型 | 说明 |
|---|---|---|---|
| 1 | `teamwork\Rank-3\M6-TOPOLOGY.md` | **新建** | 任务 1：3 地表区域 + 1 地下入口 + 2 地牢（6 area binding）、8 赐福节点、7 条连接边、6 个解锁 flag、单向门捷径专节、探索线闭环、待登记项。数据源 `m6_area_bindings.tres` / `grace_network.tres` / `dungeon_01_bellvault.tres` / `箱庭地牢模板.md`，与 W7 `T3_*` 实证一致 |
| 2 | `teamwork\Rank-3\SAVE-SPEC-FINAL.md` | **新建** | 任务 2：SaveDelta 十字段（冻结）、flag 三段式命名空间（5 前缀 + 正则 + INV-6 收敛）、任务阶段存档口径（`quests` / 回放 / 冲突 / `reason=quest_stage` 强制落盘）、INV-1~7 速查、供 `00-汇总.md` 直接引用的 5 条结论 |
| 3 | `teamwork\Rank-3\I-INTERFACE-SELFCHECK.md` | **新建** | 任务 3：RPG 侧 I-1 / I-2 / I-3 一致性自检结论 + W7_SUMMARY 等真跑证据（实际 stdout 摘录）+ 8 条 ERROR / 9 条 WARNING 逐条归因 + 自检边界登记 |
| 4 | `teamwork\Rank-3\DONE-R9.md` | **新建** | 本件（①实际交付清单 ②自检含真跑实际输出结论 ③未完成项与阻塞） |
| 5 | `command_center\ai\3\outbox\cmd-20261109-033148-252-A3.json` | **回执** | 唯一回执例外，按本任务单 id 写入，`status=done`、`result` 引用本件实际结论；中枢即时消费归档至 `command_center\dispatcher\receipts\cmd-20261109-033148-252-A3.json`（2256 B，逐字一致），`ai\3\status.json` 置 `state=idle / completed=9` |

**汇总材料间交叉引用**：`M6-TOPOLOGY.md` ↔ `I-INTERFACE-SELFCHECK.md` §5 的 `T3_*` 实证；`SAVE-SPEC-FINAL.md` ↔ `I-INTERFACE-SELFCHECK.md` §2（I-1）；三者统一供主 AI `00-汇总.md` 按 I-1 / I-2 / I-3 编号核对。

**未写**：`godot\project.godot`（**Rank-1 独占**）、`godot\scripts\combat\`、其它工位子目录、总线 / 总纲 / 契约 / 任务书 / 进度台账；不自行 `git commit` / `git push`。
**既有件不重做、不覆盖**：`godot\scripts\rpg\` 24 个 `.gd`、`godot\data\rpg\` 8 件（含 `m6_area_bindings.tres` / `grace_network.tres` / `dungeon_01_bellvault.tres`）、`teamwork\Rank-3\` 全部既有件一字未改；本轮 4 个 md + 1 个回执均为新建，未触碰任何既有交付件。

---

## ② 自检（真跑实际输出结论）

### 2.1 任务 4 · 三段门禁 + `W7_SUMMARY` + `R8_NORM_SUMMARY`（实际 stdout）

**命令族**（引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`，`--path F:\Game\aierdengfahuan\godot`；日志置于系统临时目录 `C:\Users\62668\AppData\Local\Temp\r9_final_logs\`、收尾删除）：

| 段 | 实际命令 | EXIT | 实际输出结论 |
|---|---|---|---|
| G0 | `--version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| G1 | `--headless --path godot --import` | `0` | `g1.log` 32 行；`first_scan_filesystem` 5 steps / `loading_editor_layout` 全 `[ DONE ]`；**无 Parse Error / Failed loading**；含 8 条 `preset.0` 配置读取 ERROR（见 2.3，跨工位、非脚本错误） |
| G2 | `--headless --path godot --check-only --script res://scripts/rpg/<f>.gd` × 24 | `0` | `G2_TOTAL=24 G2_FAIL=0`（24 个 rpg `.gd` 全 EXIT=0） |
| G3 | `--headless --path godot --quit` | `0` | `g3.log` 4 行：版本行 + 1 条 `ObjectDB leaked` WARNING；**无 autoload 路径 ERROR、无 `scene_missing` WARNING** |
| W7 | `--headless --path godot --quit-after 5 res://scripts/rpg/r7_wiring_test.tscn` | `0` | `w7.log` 70 行，`W7_SUMMARY pass=45 fail=0`，`W7_FAIL` 0 条 / `W7_PASS` 45 条 |
| R8 | `--headless --path godot --script res://scripts/rpg/r8_neg_chunk_test.gd` | `0` | `r8norm.log` 27 行，`R8_NORM_SUMMARY pass=18 fail=0`，`R8_NORM_FAIL` 0 条 / `R8_NORM_PASS` 18 条 |

**实际 stdout（汇总标记，逐字）**：
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

**W7 关键断言（`w7.log` 逐字，与 M6 拓扑表 / I-1 自检直接对应）**：
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
W7_PASS T4_WAV_BYTES | line_bellkeeper_01 bytes=308800 expect=308800
W7_PASS T4_ONENTER_FLAG | on_enter_flags wrote world.npc_01_bellkeeper.met=true via I-1
W7_SUMMARY pass=45 fail=0
```

### 2.2 无回归判定

- `W7_SUMMARY pass=45 fail=0` 与 **R7 基线**（`RPG-WIRING.md` §5 / `DONE-R7.md` ②）、**R8 复跑**（`DONE-R8.md` ②）**逐字一致**；`R8_NORM_SUMMARY pass=18 fail=0` 与 R8 基线一致；正坐标产物 `world.chunk_limgrave_0_0.loaded` 未变（`R8_NORM_POS_REGRESSION` PASS）→ **I-1~I-3 联调断言与负坐标归一增强均零回归**。
- 脚本门禁口径：`SCRIPT_ERROR=0`、`Parse_Error=0`、`Failed_loading=0`、`G2_FAIL=0`、6 段全 `EXIT=0` → **RPG 侧脚本无回归**（与 `MSG-20261109-0331-HOST` 全工程 `ERROR=0` / 51 个 `.gd` 验收线一致）。
- I-1 / I-2 / I-3 静态一致性与运行期证据逐项见 `I-INTERFACE-SELFCHECK.md` §2~§4；总结论：**一致性自检通过且真跑确认无回归**。

### 2.3 `SCRIPT ERROR` / `ERROR` grep 与逐条归因（如实登记，不冒充全绿）

合并 `g0+g1+g2_*+g3+w7+r8norm → all.log`（**182 行**），`grep -nEi "SCRIPT ERROR|Parse Error|ERROR|Failed loading|WARNING"` 命中 **17 行**：

| 行 | 命中 | 归因 |
|---|---|---|
| 4 / 6 / 8 / 10、21 / 23 / 25 / 27 | `ERROR: Couldn't find the given section "preset.0" and key ...` / `ERROR: Cannot get keys from nonexistent section "preset.0.options"`（**8 条**） | **G1 `--import`**：`godot\export_presets.cfg`（Rank-1 **R10** 交付件，mtime 03:35，文件头自述「先按最小必需字段集落盘，再以 `--headless --export-release` 实际报错校正」）当前只有 `[preset.0]` 的 `name/platform/runnable/export_path` 与空 `[preset.0.options]`，缺 `export_filter/include_filter/exclude_filter` → `ConfigFile.get_value` 报错。**配置读取错误、非脚本错误**，属跨工位并行中间态；G1 本身 `EXIT=0`、扫描全 `[ DONE ]`；3 号不擅改、不裁决 |
| 84 / 154 / 181 | `WARNING: 2 ObjectDB instances were leaked at exit` × 3 | G3 / W7 / R8 headless 退出噪音 |
| 88 / 89、177 / 178 | `WARNING: [ChunkManager] 未找到 ChunkRoot` × 2 | Rank-1 `ChunkManager` autoload 无 `ChunkRoot` 场景节点、降级（跨工位） |
| 101 / 102 | `WARNING: I-1: 非法 flag key，写入忽略：chunk.chunk_limgrave_0_0.loaded` | W7 **联调预期拒绝**（验证原始 `chunk.*` 被 I-1 拒绝），非缺陷 |

**专项计数**：`SCRIPT ERROR` **0**、`Parse Error` **0**、`Failed loading` **0**、`SpawnRequest` 冲突 ERROR **0**、`归一后仍非法` WARNING **0**；`ERROR` **8**（全部为上述 `preset.0` 配置读取，非脚本）、`WARNING` **9**（全部归因如上）。
> R8 时 `ERROR=0`；本轮 8 条 ERROR 来自 Rank-1 R10 导出预设并行写入，与 3 号产出无关，不影响「RPG 侧无回归」判定。

### 2.4 任务 1 / 2 / 3 交付自检

| 任务 | 自检结论 | 证据 |
|---|---|---|
| 1 M6 拓扑表 | 6 区域 / 8 赐福 / 7 边 / 6 解锁 flag 与两份 `.tres` 逐项一致；单向门捷径字段（`world.bellvault_shortcut_door_01.unlocked` + `dungeon.bellvault.shortcut_opened`）与 `dungeon_01_bellvault.tres` / `箱庭地牢模板.md` §3 一致 | `T3_NODES_8` / `T3_EDGES_7` / `T3_AREAS_6` / `T3_COVER_*` / `T3_FLAGS_3SEG` 全 PASS |
| 2 存档汇总 | SaveDelta 十字段、三段式正则、任务阶段口径均取自 `存档与flag规范.md`，与 `world_state.gd:24` / `接口契约.md` §1 一致 | G2 24 个 `.gd` 全 EXIT=0；`T2_*` / `T3_FLAGS_3SEG` PASS |
| 3 接口自检 | I-1 / I-2 / I-3 契约 ↔ 实现 ↔ 运行期一致 | `I-INTERFACE-SELFCHECK.md` §2~§5 |

### 2.5 合规自检

- **只写**授权范围：`teamwork\Rank-3\`（4 个新建 md）+ `command_center\ai\3\outbox\`（回执例外）。**未写** `godot\project.godot`（Rank-1 独占）、`godot\scripts\combat\`、其它工位、总线 / 总纲 / 契约 / 任务书 / 进度台账；不自行 `git commit` / `git push`。
- **既有件不重做**：24 个 `.gd` / 8 份 `godot\data\rpg\` 件 / 工位既有件一字未改；三份汇总材料均为**整理件**，不新增 / 不修改任何 `.tres` / `.gd`。
- **待裁决项只登记不擅改**：A8（两段式 vs 三段式）、chunk flag 归一 A/B/C、`SaveSystem` autoload 归属、`_present_line` UI(D2)、§4.4 九项、6 条 `scene_path` 未实机换场景均沿用既有登记。
- 零付费 / 零外部依赖；`stable-audio` gated 403 **不申请不绕过**；3 个 WAV 沿用 R3 qwen-tts 既有产物，**未启动任何 GPU job**；默认不刺探（仅目的性读取必读件与真跑所需文件）。
- 运行时 `user://saves/slot_01/` 产物由 W7 载体 `_cleanup()` 清空；日志置于系统临时目录、收尾删除；中文 UTF-8；**Godot 4 合法语法**（24 个 `.gd` 全 `--check-only` EXIT=0）；**未伪造任何真跑输出**。

---

## ③ 未完成项与阻塞

| # | 项 | 性质 / 阻塞 | 归属 |
|---|---|---|---|
| 1 | `SaveSystem` autoload 归属最终口径（保留 Rank-1 占位 / 改指向 3 号正式件） | **待裁决**；R8 只登记 + 建议保留现状，本轮沿用，未写 `project.godot`、未新建 `save_system.gd` | HOST 裁决；`project.godot` 属 Rank-1 独占 |
| 2 | `chunk.<id>.loaded` 三段式归一最终口径（A / B / C）+ 是否同步改 §3.1 正则与 `world_state.gd:24` | **待裁决**；R8 只在 3 号归一函数内做负坐标编码，本轮未选定、未改正则 / 白名单 | HOST 裁决（`R5-待裁决登记.md` §2） |
| 3 | `_present_line` 仍为 `pass`；`VoiceLineBinder → DialogueRunner` 接入点；语音「UI 实际播放」未验证 | **待裁决 D2**；UI 呈现属 Rank-1，本轮只登记未改 | HOST 裁决接入方 / 轮次；Rank-1 UI |
| 4 | §4.4 九项回改（旧措辞）、`save_delta.gd`（独立静态类）与 `world_state.gd`（内联）最终归属 | 沿用待裁决，本轮未推进 | HOST 裁决（`R5-待裁决登记.md` §1 / §5） |
| 5 | 6 条 `res://scenes/*` `scene_path` 未实机换场景；`m6_area_bindings.tres` `chunk_origin_x/y` 全 0；`dungeon_02_sunless_tomb` 无独立箱庭模板 | `SceneRouter` / 场景布局 / 内容密度属 Rank-1 或后续排期，超 3 号范围 | Rank-1 / 后续轮次 |
| 6 | A8：契约 §2 两段式示例 `world.grace_limgrave_lit` vs §3.1 严格三段式 | 口径差异，只登记不擅改契约 | HOST 在 `00-汇总.md` 裁决 |
| 7 | I-2 击杀信号 `enemy_defeated` / `boss_defeated` 的**运行期端到端断言** | W7 载体 45 项断言未直接 emit 这两条信号；本轮为静态实现逐行核对 + 同一 `commit()` 强制落盘通道运行期实证，**不冒充已覆盖** | 后续联调补强 |
| 8 | 8 条 `preset.0` ERROR（`export_presets.cfg`）、`[ChunkManager] 未找到 ChunkRoot` WARNING × 2、`ObjectDB leaked` × 3 | 跨工位 R10 并行中间态 / 场景侧 / headless 退出噪音，**非脚本错误**；3 号不擅改、不裁决 | 如实登记；Rank-1（导出配置 / 场景侧） |
| 9 | 负坐标归一「运行期经 `ChunkManager` 真实 `chunk_loaded` 触发」端到端实证 | R8 已登记：W7 运行期 Rank-1 未触发负坐标 chunk 加载，归一生效由 R8 载体主动断言证明 | 跨工位时序，待后续联调 |

> **无本轮硬阻塞**：四项任务 4/4 完成，三段门禁与 W7 / R8 真跑通过、无回归；上述项均为「待裁决 / 跨工位 / 时序受限 / 后续补强」，不影响本轮交付与真跑结论。裁决前保持既有状态；本轮实际交付与真跑结论以本件 ①② 为准。

---

## 合规声明

- 本轮**只写** `teamwork\Rank-3\`（`M6-TOPOLOGY.md` / `SAVE-SPEC-FINAL.md` / `I-INTERFACE-SELFCHECK.md` / `DONE-R9.md` 四份新建）与 `command_center\ai\3\outbox\`（回执例外）；**未写 `godot\project.godot`**、未写其它工位 / 子目录、未覆盖任何并发产出。
- 不写总线 / 总纲 / 契约 / 任务书 / 进度台账；不自行 `git commit` / `git push`。
- 既有件不重做；待裁决项只登记不擅改；零付费 / 零外部依赖；`stable-audio` gated 403 不申请不绕过；**不启动任何 GPU job**；默认不刺探；中文 UTF-8；Godot 4 合法语法；**未伪造任何真跑输出、未谎报成功**（8 条 `preset.0` ERROR 与 9 条 WARNING 均如实登记并归因）。
