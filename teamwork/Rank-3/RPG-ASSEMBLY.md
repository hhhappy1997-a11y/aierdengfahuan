# RPG-ASSEMBLY.md · R6：RPG 层装配进工程根

> 轮次：**R6**（HOST 全闭环调度续派）｜工位：**3 号（RPG / 世界 / 存档）**｜派单 task_id `cmd-20261109-022337-000-A3`
> 授权：**总指挥 02:23 裁决**（`00-群聊总线.md` MSG-20261109-0223-HOST / `任务书-R6.md`）：解除工程根落位阻塞，四路各写互不重叠子目录；本工位唯一可写 `F:\Game\aierdengfahuan\teamwork\Rank-3\` + `godot\scripts\rpg\`、`godot\data\rpg\`、`godot\assets\audio\voice\`，回执例外 `command_center\ai\3\outbox\`。
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（`--version` 实测 `4.7.2.stable.official.ed1daf0bf`）。中文 UTF-8。
> 本件内容：① res:// 映射表 ② 装配自检（真跑实际输出）③ §4.4 与 chunk flag 待裁决项**保留登记**（只登记、不擅改）。

---

## 0. 装配边界与真跑载体

| 项 | 实际 |
|---|---|
| 工程根 | `F:\Game\aierdengfahuan\godot\`（统一 Godot 工程根，由总指挥 02:23 授权建立） |
| 本轮写入 | 仅 `godot\scripts\rpg\`、`godot\data\rpg\`、`godot\assets\audio\voice\` 三个子目录 + `Rank-3\` 文档 + `outbox\` 回执 |
| 未写 | `godot\project.godot`（**Rank-1 独占**）、其它工位子目录（core / render / ui / world / combat / scenes / data\render 等）、总线 / 总纲 / 契约 / 任务书 / 进度台账 |
| 工位原件 | `teamwork\Rank-3\` 下 22 个 `.gd`、6 份 `.tres`、2 份 `voice_*.json`、3 个 WAV **一字未改**（mtime 保持旧值，见 §3.2 diff 审计）；只在工程根副本做 `res://` 路径适配 |
| 不覆盖 | 工程根三个子目录均为新建，全部 `cp -n` 落位，未覆盖任何既有文件 |
| 真跑载体 | 真跑开始时 `godot\project.godot` **未就位**（Rank-1 独占），按任务书「若 project.godot 未就位可在临时最小工程验证」，在系统临时目录 `C:\Users\62668\AppData\Local\Temp\r6_verify` 建最小验证工程（**非交付件、用完即删**），按落位后的目录布局复制 22 `.gd` / 6 `.tres` / 2 json / 3 WAV，加最小 `project.godot`（`config_version=5`、3 个 autoload `GameEvents` / `WorldState` / `SaveDeltaWriter`、`run/main_scene`）与空场景 `main.tscn` |
| 收尾复核 | 临时工程清理后复核，`godot\project.godot` 已由 **Rank-1 并行落位**（本轮未写、未改）；本轮**未**在全工程根跑 import（避免写入其它工位子目录 / 触发跨工位依赖 ERROR），三段门禁结论以临时最小工程真跑为准，如实登记 |

> 落位完成后，工程根三个子目录内出现 Godot 自动生成的 `*.gd.uid`（22 个）与 `*.wav.import`（3 个）元数据文件——为工程根被 Godot 导入后的引擎产物，**非本轮手工写入、未删除**，不计入本轮手工落位的 33 件交付清单。

---

## 1. res:// 映射表

### 1.1 目录映射（`res://` 根 = `godot\project.godot` 所在目录 `godot\`）

| 工位源 | 工程根落位 | 逻辑路径 |
|---|---|---|
| `Rank-3\*.gd`（22） | `godot\scripts\rpg\` | `res://scripts/rpg/` |
| `Rank-3\*.tres`（6）+ `voice_*.json`（2） | `godot\data\rpg\` | `res://data/rpg/` |
| `Rank-3\assets\audio\voice\*.wav`（3） | `godot\assets\audio\voice\` | `res://assets/audio/voice/` |

### 1.2 落位交付件清单（手工落位共 33 件）

**`godot\scripts\rpg\`（22 个 `.gd`）**：
`world_state.gd`、`save_delta.gd`、`save_delta_writer.gd`、`dialogue_choice.gd`、`dialogue_gate.gd`、`dialogue_graph.gd`、`dialogue_line.gd`、`dialogue_node.gd`、`dialogue_runner.gd`、`quest_data.gd`、`quest_stage.gd`、`quest_state_machine.gd`、`grace_network.gd`、`grace_node.gd`、`dungeon_definition.gd`、`interactable_spec.gd`、`spawn_request.gd`、`world_baseline.gd`、`game_events.gd`、`chunk_world_bridge.gd`、`m6_area_bindings.gd`、`voice_line_binder.gd`

**`godot\data\rpg\`（6 份 `.tres` + 2 份 `.json`）**：
`dialogue_and_quest.tres`、`dungeon_01_bellvault.tres`、`grace_network.tres`、`m6_area_bindings.tres`、`world_baseline.tres`、`spawn_bellvault_elite_01.tres`、`voice_key_table.json`、`voice_manifest.json`

**`godot\assets\audio\voice\`（3 个 WAV）**：
`vo_bellkeeper_01.wav`（308800 B）、`vo_bellkeeper_02.wav`（206022 B）、`vo_grace_memory_01.wav`（249644 B）

### 1.3 路径修正登记（逐处，仅工程根副本）

任务书要求「落位 `godot\data\rpg\` 并修正 ext 路径」。核对后：6 份 `.tres` 的 `[ext_resource type="Script" path="res://scripts/rpg/*.gd"]` 与落位后脚本位置**本就一致、无需改写**（`EXT_SCRIPT_OK missing=[]`）；真正需要修正的是**分散的资源引用路径**——工位原件把资源登记在 `res://data/dialogue/`、`res://data/grace/`、`res://data/dungeons/`、`res://data/spawns/`、`res://data/voice/` 及 `res://data/world_baseline.tres`，而本轮统一落位 `godot\data\rpg\`（= `res://data/rpg/`）。故把 **5 个文件、12 行、15 个字符串值**统一改为 `res://data/rpg/*`：

| # | 文件（工程根副本） | 行 | 工位原件值 | 落位副本值 |
|---|---|---|---|---|
| 1 | `scripts/rpg/world_state.gd` | 36 | `res://data/world_baseline.tres` | `res://data/rpg/world_baseline.tres` |
| 2 | 同上 | 38 | `res://data/dialogue/dialogue_and_quest.tres` | `res://data/rpg/dialogue_and_quest.tres` |
| 3 | 同上 | 39 | `res://data/grace/grace_network.tres` | `res://data/rpg/grace_network.tres` |
| 4 | 同上 | 40 | `res://data/dungeons/dungeon_01_bellvault.tres` | `res://data/rpg/dungeon_01_bellvault.tres` |
| 5 | 同上 | 41 | `res://data/world_baseline.tres` | `res://data/rpg/world_baseline.tres` |
| 6 | 同上 | 42 | `res://data/spawns/spawn_bellvault_elite_01.tres` | `res://data/rpg/spawn_bellvault_elite_01.tres` |
| 7 | 同上 | 116 | `res://data/world_baseline.tres`（`manifest.get` 默认值） | `res://data/rpg/world_baseline.tres` |
| 8 | 同上 | 125 | `res://data/world_baseline.tres`（`_new_delta`） | `res://data/rpg/world_baseline.tres` |
| 9 | `scripts/rpg/save_delta.gd` | 214 | `res://data/world_baseline.tres` | `res://data/rpg/world_baseline.tres` |
| 10 | `scripts/rpg/dialogue_runner.gd` | 10 | `res://data/dialogue/dialogue_and_quest.tres`（`GRAPH_PATH`） | `res://data/rpg/dialogue_and_quest.tres` |
| 11 | `scripts/rpg/voice_line_binder.gd` | 18 | `res://data/voice/voice_key_table.json`（`KEY_TABLE_PATH`） | `res://data/rpg/voice_key_table.json` |
| 12 | `data/rpg/world_baseline.tres` | 37 | `resource_ids` 4 条分散 `res://data/{dialogue,grace,dungeons,spawns}/*` | 4 条统一 `res://data/rpg/*` |

> 修正后 G3 `WorldState._ready()` 对 5 份 `.tres` 的 `ResourceLoader.exists` + `load` 全部成功、日志干净（未触发「基线资源不存在 / 加载失败」`push_warning`），即路径修正与落位布局自洽。

### 1.4 保持不改的 `res://` 引用（登记）

| 类别 | 引用 | 处置 |
|---|---|---|
| `.tres` 的 `[ext_resource]` 脚本路径 | `res://scripts/rpg/*.gd`（6 份 `.tres` 共 14 条） | 与落位一致，**未改** |
| 跨工位场景路径 | 6 条 `res://scenes/areas/*.tscn` / `res://scenes/dungeons/*.tscn`（`grace_network.tres` / `m6_area_bindings.tres` / `dungeon_01_bellvault.tres` 的 `scene_path` 字符串字段） | **保留不改、只登记**（属 Rank-1 场景，本轮不可写；字符串字段不影响 `.tres` 导入/加载） |
| 语音键表资源路径 | 3 条 `res://assets/audio/voice/vo_*.wav`（`voice_key_table.json`） | 与 WAV 落位一致，**未改** |
| 运行时存档路径 | `user://saves/slot_01/*`（`world_state.gd` / `save_delta.gd`） | 运行时路径，**未改** |
| 历史注释 | `world_state.gd:3`「脚本 `res://autoload/world_state.gd`，由 1 号注册」 | 注释措辞与实际落位 `res://scripts/rpg/world_state.gd` 不符，属 R2 历史措辞；**不改既有件注释**，登记见 §4.4 |

---

## 2. 语音键表登记

键表文件：`godot\data\rpg\voice_key_table.json`（3 条）、`godot\data\rpg\voice_manifest.json`（3 条）——**原样落位**（`diff -q` = `IDENTICAL`），`res_path` 与 WAV 落位逐条核对一致。

| vo_id | graph / node / line | trigger_source | res_path | 落位 WAV | 字节（键表 / 实际） |
|---|---|---|---|---|---|
| `vo_bellkeeper_01` | `graph_npc_bellkeeper` / `node_first_meet` / `line_bellkeeper_01` | `npc_talk` | `res://assets/audio/voice/vo_bellkeeper_01.wav` | `godot\assets\audio\voice\vo_bellkeeper_01.wav` | 308800 / 308800 |
| `vo_bellkeeper_02` | `graph_npc_bellkeeper` / `node_first_meet` / `line_bellkeeper_02` | `npc_talk` | `res://assets/audio/voice/vo_bellkeeper_02.wav` | `godot\assets\audio\voice\vo_bellkeeper_02.wav` | 206022 / 206022 |
| `vo_grace_memory_01` | `graph_grace_bellkeeper_memory` / `node_grace_memory` / `line_memory_01` | `grace_memory` | `res://assets/audio/voice/vo_grace_memory_01.wav` | `godot\assets\audio\voice\vo_grace_memory_01.wav` | 249644 / 249644 |

- 3 个 WAV 沿用 **R3 qwen-tts 本地真跑产物**（24 kHz / mono / 16-bit PCM，549.4 s、峰值显存 4.6 GB，见 `RPG-BUILD.md` §5），**本轮未启动任何 GPU job / qwen-tts**；`stable-audio` gated 403 不申请、不绕过、零付费、零外部依赖。
- `voice_line_binder.gd` 的 `KEY_TABLE_PATH` 已修正为 `res://data/rpg/voice_key_table.json`，与键表落位一致；`resolve_voice` / `resolve_voice_for` / `cross_check` 逻辑未改。
- **运行期触发验证未做**：`dialogue_runner.gd:154` `_present_line` 仍为 `pass`（UI 属 Rank-1），需工程根场景 + UI 接入后联调，登记见 §4.4。

---

## 3. 装配自检（实际输出，未伪造）

### 3.1 静态自检（内联 `python - <<'PY'`，非落盘探针 / 测量 / preflight 脚本）

实际输出逐字：

```
JSON_OK voice_key_table entries=3 voice_manifest items=3
VOICE vo_bellkeeper_01 -> res://assets/audio/voice/vo_bellkeeper_01.wav exists=True bytes=308800/308800 match=True
VOICE vo_bellkeeper_02 -> res://assets/audio/voice/vo_bellkeeper_02.wav exists=True bytes=206022/206022 match=True
VOICE vo_grace_memory_01 -> res://assets/audio/voice/vo_grace_memory_01.wav exists=True bytes=249644/249644 match=True
VOICE_BIND_OK 3/3 bad=[]
EXT_SCRIPT_OK missing=[]
RESOURCE_IDS_OK missing=[]
SCENE_PATH_KEPT count=6
  SCENE res://scenes/areas/Limgrave.tscn
  SCENE res://scenes/areas/SiofraWell.tscn
  SCENE res://scenes/areas/StormveilGate.tscn
  SCENE res://scenes/areas/WeepingShore.tscn
  SCENE res://scenes/dungeons/Bellvault.tscn
  SCENE res://scenes/dungeons/SunlessTomb.tscn
STALE_RES_PATH count=0 []
```

| 检查项 | 实际结论 |
|---|---|
| 语音键表 / manifest JSON | `json.load` 通过，3 / 3 条 |
| 语音绑定 | `VOICE_BIND_OK 3/3`，3 个 `res_path` 对应 WAV 全部存在且字节数逐条一致 |
| `.tres` ext 脚本引用 | `EXT_SCRIPT_OK missing=[]`，6 份 `.tres` 的 14 条 `ext_resource` 全部命中已落位 `.gd` |
| `resource_ids` 引用 | `RESOURCE_IDS_OK missing=[]`，`world_state.gd` 5 条 + `world_baseline.tres` 4 条全部命中 `data/rpg/*.tres` |
| 旧路径残留 | `STALE_RES_PATH count=0`；Grep 工具对 `godot\` 复核 `res://data/(dialogue\|grace\|dungeons\|spawns\|voice)/\|res://data/world_baseline.tres` → **No matches found** |
| 跨工位场景字段 | `SCENE_PATH_KEPT count=6`，6 条 `res://scenes/*` 原样保留、未改 |

### 3.2 diff 审计（工位原件未改、副本仅路径差异）

实际输出逐字（`diff` 工程根副本 vs 工位原件）：

```
GD_DIFF_FILES=4
--- dialogue_runner.gd      10c10  (GRAPH_PATH)
--- save_delta.gd           214c214 (baseline manifest)
--- voice_line_binder.gd    18c18  (KEY_TABLE_PATH)
--- world_state.gd          36c36, 38,42c38,42, 116c116, 125c125
TRES_DIFF_FILES=1
--- world_baseline.tres     37c37   (resource_ids 4 条)
voice_key_table.json IDENTICAL
voice_manifest.json IDENTICAL
gd=22 tres=6 json=2 wav=3
```

工位原件 `stat` mtime 全部为旧时间（`world_state.gd` 00:00、`world_baseline.tres` 00:02、`dialogue_runner.gd` 23:58、`voice_line_binder.gd` 01:48、`save_delta.gd` 01:09），**本轮未写入工位原件一字**；22 个 `.gd` 中仅 4 个、6 份 `.tres` 中仅 1 份的工程根副本有差异，且差异全部为 §1.3 登记的 `res://data/*` → `res://data/rpg/*` 路径字符串，无任何逻辑改动。

### 3.3 Godot 4.7.2 三段门禁真跑（临时最小工程，实际输出）

| 段 | 实际命令 | 退出码 | 实际输出结论 |
|---|---|---|---|
| G0 | `<godot> --version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| G1 | `<godot> --headless --path <tmp> --import` | `0` | 日志 62 行：`first_scan_filesystem` 5 steps `[ DONE ]`；`update_scripts_classes` **22 steps `[ DONE ]`**（17 个带 `class_name` 全局类显示类名：`ChunkWorldBridge` / `DialogueChoice` / `DialogueGate` / `DialogueGraph` / `DialogueLine` / `DialogueNode` / `DungeonDefinition` / `GraceNetwork` / `GraceNode` / `InteractableSpec` / `M6AreaBindings` / `QuestData` / `QuestStage` / `SaveDelta` / `SpawnRequest` / `VoiceLineBinder` / `WorldBaseline`，另 5 个无 `class_name` 显示空名）；`[ DONE ] _update_scan_actions` / `reimport` / `loading_editor_layout`；**无 Parse Error** |
| G2 | `<godot> --headless --path <tmp> --check-only --script res://scripts/rpg/<各 .gd>` × 22 | **22 条全 `0`**（`G2_TOTAL=22 G2_FAIL=0`） | 22 个 `.gd` 全部静态解析通过；`g2_check.log` 44 行 = 22 ×（版本行 + 空行），无错误行 |
| G3 | `<godot> --headless --path <tmp> --quit` | `0` | 日志 2 行 = 版本行 `Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org` + 1 空行；`WorldState._ready()` 对 5 份 `.tres` 实际 `ResourceLoader.exists` + `ResourceLoader.load`（含 `load_steps=51` 的 `dialogue_and_quest.tres`），**未触发**「基线资源不存在 / 加载失败」`push_warning`，即 5 份 `.tres` 全部实际加载成功 |

### 3.4 grep 强制校验（运行时 `SCRIPT ERROR` 不改退出码，必须 grep 才算通过）

- 合并 `g0_version.log` + `g1_import.log` + `g2_check.log` + `g3_quit.log` → `all.log`（**109 行**）。
- Bash `grep -nEi "SCRIPT ERROR|Parse Error|error:|ERROR|Failed loading|WARNING" all.log` → **`GREP_RESULT=NONE`**。
- Grep 工具对 `all.log` 正式复核同模式 → **No matches found**（双重复核）。

**三段门禁真跑通过**：全量日志无任何 `SCRIPT ERROR` / `Parse Error` / `ERROR` / `Failed loading` / `WARNING`；22 个 `.gd` 与 6 份 `.tres` 均为 Godot 4.7.2 合法语法、可注册、可解析、可被 `ResourceLoader.load` 打开。

**临时工程清理**：`DELETE_OK tmp_exists=0 logs_exists=0`（`r6_verify` 与 `r6_logs` 已删，系统临时目录、非交付件、未留在 teamwork 内、未提交）。

### 3.5 真跑口径边界（如实登记）

- 本轮「真跑」= **Godot 4.7.2 三段门禁 + 静态自检（内联 python）**，以上为实际输出。
- 真跑时 `godot\project.godot` 未就位（Rank-1 独占），按任务书许可在临时最小工程验证；收尾时该文件已由 Rank-1 并行落位，本轮**未**在全工程根跑门禁（避免写入其它工位子目录、避免跨工位依赖未就位导致的 ERROR 冒充全绿）。
- **传送实跑 / 语音运行期触发实跑 未做**：需工程根场景 + Rank-1 UI / autoload 实注册，超本工位范围；按任务书「跑不了如实写阻塞，绝不伪造输出」，不谎报这两项实跑。
- **未启动任何 GPU job**：3 个 WAV 沿用 R3 真跑产物；`stable-audio` gated 403 不申请、不绕过；零付费 / 零外部依赖。

---

## 4. 待裁决项保留登记（只登记、不擅改）

### 4.1 §4.4 九项对照（`存档与flag规范.md` 旧措辞回改）——沿用 `R5-待裁决登记.md` §1

权威口径按契约 I-1：3 号 `world_state.gd` / `save_delta.gd` 为运行时最高权威，文档措辞须向实现对齐。九项对照（逐字依据见 R4 草案 §2 / `R5-待裁决登记.md` §1.2）：

| # | 位置 | 旧措辞（摘要） | 实现口径 | 建议方向（不选定） |
|---|---|---|---|---|
| 1 | 步 3 | 按 `seq` 升序回放 | timestamp(`written_at_unix`) 升序回放，`seq` 仅作候选行筛选 | 回改步 3 |
| 2 | 规则表标题 / 两行 | LWW by seq / `seq` 大者胜 | LWW by timestamp / 写入顺序 | 回改标题与两行 |
| 3 | 步 5 | 任务同 ID 取 `seq` 最大者覆盖 | `stage_index = max(旧,新)`，阶段只前进 | 回改步 5 |
| 4 | 步 6 | `inventory` grants/consumed 累加结算 | `{item_id:count}` 快照后写覆盖，`count<=0` 移除 | 回改步 6 |
| 5 | 步 7 | `epoch` 变大时清空 `defeated` | 集合并集只增不减、`epoch=max` | 回改步 7 |
| 6 | 步 4 / 规则表 | `removals` 优先 | **一致，保留** | 不改 |
| 7 | 步 8 | 回放后立即压缩写盘 | `_load()` 只注入内存，落盘由 §4.8 合并窗口驱动 | 回改 / 标注「实现待补」 |
| 8 | 规则表 | `meta.stage_repaired` 跨字段回写 | 实现未落地 | 删除 / 保留为待补 |
| 9 | 规则表 | `spawns.defeated` 跨字段补齐 | 实现未在合并层落地 | 删除 / 保留为待补 |

关联未决 4 项（§4.1 / §4.3 示例 JSON 顶层结构、`seq` 字段语义、§4.6 分层措辞）。可选方案 **A**（按 R4 草案 §3 回改）/ **B**（原文不动、追加「运行时以实现为准」一句）/ **C**（暂不回改，维持「文档滞后」登记）。
**待总指挥裁决**：① 是否回改 + 范围（含第 7~9 条）② 方案 A/B/C ③ 执行方与轮次。**本轮未改 `存档与flag规范.md` 原文一字**。

### 4.2 `chunk.<id>.loaded` 三段式归一冲突——沿用 `R5-待裁决登记.md` §2

| 来源 | 内容 |
|---|---|
| `存档与flag规范.md:118` / 契约 §3 I-1 | flag 三段式白名单首段仅 `world / quest / combat / grace / dungeon` |
| Rank-1 `chunk_streaming_r4.gd:29~30,195` | `chunk.<chunk_id>.loaded`，经 `WorldState.set_flag` 写入 |
| 3 号 `chunk_world_bridge.gd:21~22,43~65` | `normalize_chunk_flag()` → `world.<chunk_id>.loaded` |

R5 静态自检佐证：`CHUNK_NORMALIZED world.chunk_limgrave_0_0.loaded valid_by_I1=True` / `R1_RAW_FLAG chunk.chunk_limgrave_0_0.loaded valid_by_I1=False`。性质为**跨工位口径冲突 + 需裁决**，非 3 号可单方修改的实现缺陷。可选方案 **A**（Rank-1 改用 `world.<chunk_id>.loaded` 或经归一后写入）/ **B**（扩展 I-1 白名单纳入 `chunk` 段，需同步多方正则）/ **C**（明确 `chunk.*` 仅为 1 号内存态、不进存档）。
**待总指挥裁决**：① 最终口径 ② 是否同步改 §3.1 正则与 `world_state.gd:24` `FLAG_KEY_REGEX` ③ 执行方与轮次。**本轮未改 Rank-1 任何文件、未改 §3.1、未选定结论**。

### 4.3 沿用未决项（R3 / R4 / R5 已登记，本轮未推进）

| 项 | 来源 |
|---|---|
| `save_delta.gd`（独立静态类）与 `world_state.gd`（内联）最终归属 / 是否统一 | `DONE-R3.md` §3.1、`DONE-R4.md` §3.3 |
| 交付完成总线消息由 HOST 代发（本轮「不写总线」） | `DONE-R5.md` §3.1 |
| M6 赐福网络接入工程根与传送实跑 | `R5-待裁决登记.md` §3 前置条件 C1~C6 |
| 语音运行期触发验证 | `R5-待裁决登记.md` §4 前置条件 D1~D4 |

### 4.4 本轮装配新增的「跨工位 / 待裁决」登记（只登记、不擅改）

| # | 项 | 状态 | 归属 / 说明 |
|---|---|---|---|
| 1 | 6 条 `res://scenes/areas/*.tscn` / `res://scenes/dungeons/*.tscn`（`scene_path`） | **跨工位 · 保留未改** | Rank-1 独占场景；本轮不可写，字符串字段不影响 `.tres` 导入/加载 |
| 2 | `m6_area_bindings.tres` 的 `chunk_origin_x/y` 当前全 0 | **待回填 · 未擅改** | 需 Rank-1 实际场景布局数据（`R5-待裁决登记.md` §3.2 C4）；数据表改数值不改代码 |
| 3 | `world_state.gd:3` 注释 `res://autoload/world_state.gd` 与实际落位 `res://scripts/rpg/world_state.gd` 不符 | **历史措辞 · 保留未改** | 注释不影响功能；autoload 注册（含 `project.godot`）属 Rank-1 独占，待其注册时统一 |
| 4 | `godot\project.godot` 与 3 个 autoload 实注册 | **跨工位 · 本轮未写** | Rank-1 独占；真跑用临时最小工程等价验证，收尾复核该文件已由 Rank-1 并行落位 |
| 5 | `dialogue_runner.gd:154` `_present_line` 为 `pass`；`VoiceLineBinder` 接入 `DialogueRunner` | **待裁决 · 未擅改** | 语音运行期触发接入点（`R5-待裁决登记.md` §4.2 D2），接入方与轮次待总指挥裁决 |
| 6 | `*.gd.uid`（22）/ `*.wav.import`（3）引擎元数据 | **引擎产物 · 未删** | 工程根被 Godot 导入后自动生成，非本轮手工写入、不计入 33 件交付清单 |
| 7 | 全工程根门禁（含其它工位脚本） | **本轮未跑** | 避免写入其它工位子目录、避免跨工位依赖未就位 ERROR 冒充全绿；三段门禁结论以临时最小工程为准 |

---

## 5. 合规声明

- **只写** `godot\scripts\rpg\` / `godot\data\rpg\` / `godot\assets\audio\voice\`（工程根落位）+ `Rank-3\`（本文档、`DONE-R6.md`）+ `command_center\ai\3\outbox\`（唯一回执例外）；未写 `godot\project.godot`、未写其它工位 / 子目录、未覆盖任何既有文件。
- **不写总线 / 总纲 / 契约 / 任务书 / 进度台账**；不自行 `git commit` / `git push`。
- **既有件不重做**：工位原件一字未改；工程根副本只做 §1.3 登记的 `res://` 路径适配，无任何逻辑改动；3 个 WAV 沿用 R3 真跑产物，未启动 GPU job / qwen-tts。
- **待裁决项只登记不擅改**：§4.4 九项、chunk flag 归一口径、M6 / 语音前置条件、跨工位场景与 autoload 一律保留登记。
- **零付费 / 零外部依赖**；`stable-audio` gated 403 不申请不绕过；默认不刺探（开工只读必读文件一次 + 装配所需的本工位文件，未写探针 / 测量 / preflight 脚本）；中文 UTF-8；Godot 4 合法语法；**未伪造任何真跑输出**。
