# ASSEMBLY-REPORT.md · Rank-1 R7（工程根正式落位 + 全量装配门禁）

> 派单：`Rank-1\任务书-R7.md` ｜ 任务单 id：`cmd-20261109-022336-996-A1`
> 授权：`00-群聊总线.md` `MSG-20261109-0223-HOST`（总指挥 02:23 裁决：空转保护解除，正式授权在 `F:\Game\aierdengfahuan\godot\` 建立统一工程根，四路各写互不重叠子目录）
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe` —— 本轮 `--version` 实测 `4.7.2.stable.official.ed1daf0bf`（EXIT=0），与 R5/R6 结论一致
> 唯一可写：`teamwork\Rank-1\` + `godot\` 工程根中 `project.godot`（独占）/`scripts/core|render|ui|world`/`scenes`/`data/render` + 回执例外 `command_center\ai\1\outbox\`
> 本报告全部结论来自真跑实际输出，未伪造、未冒充全绿；完整自检见 `DONE-R7.md` §2。

---

## 1. 工程根目录树

### 1.1 Rank-1 本轮实际落位（17 件，逐件核对通过）

落位方式：`Rank-1\project_root\` 整目录内容以 `cp -rn`（no-clobber）拷到全新建立的 `godot\`，保持 `PROJECT_ROOT_LAYOUT.md` §2 的 `res://` 相对结构；落位前 `godot\` **不存在**，无覆盖任何既有文件。逐件核对「存在 / 非空 / 与源逐字节一致（`cmp -s`）」全部通过。

| # | `res://` 落位 | 字节 | # | `res://` 落位 | 字节 |
|---|---|---|---|---|---|
| 1 | `project.godot` | 5318 | 10 | `scripts/world/chunk_streaming_r5.gd` | 15009 |
| 2 | `scripts/core/scene_router.gd` | 5078 | 11 | `scripts/build_main.gd` | 6034 |
| 3 | `scripts/core/quality_preset.gd` | 882 | 12 | `scripts/build_courtyard.gd` | 9214 |
| 4 | `scripts/core/render_profiles.gd` | 1806 | 13 | `scenes/Main.tscn` | 3393 |
| 5 | `scripts/render/camera_rig.gd` | 3781 | 14 | `scenes/courtyard.tscn` | 4701 |
| 6 | `scripts/render/hybrid_2d3d_animated_sprite.gd` | 7262 | 15 | `data/render/quality_preset_desktop.tres` | 478 |
| 7 | `scripts/ui/performance_hud.gd` | 2588 | 16 | `data/render/quality_preset_mobile.tres` | 478 |
| 8 | `scripts/world/chunk_streaming.gd` | 10490 | 17 | `data/render/render_profiles.tres` | 685 |
| 9 | `scripts/world/chunk_streaming_r4.gd` | 11326 | | **合计** | **17 件 / 11 个 `.gd`** |

`project.godot` **原样落位、未改一字**：`config_version=5` 是 Godot 4.x 工程配置格式版本（整数，非引擎版本号），沿用 R5/R6 已落位并经三段门禁实测被 4.7.2 引擎接受的口径；本轮未硬编码新值，`--version` 实测仅用于确认引擎版本字符串与 R5/R6 一致。

目录树（Rank-1 授权范围）：

```
F:/Game/aierdengfahuan/godot/
├── project.godot                                   [Rank-1 独占]
├── scripts/
│   ├── core/    scene_router.gd / quality_preset.gd / render_profiles.gd
│   ├── render/  camera_rig.gd / hybrid_2d3d_animated_sprite.gd
│   ├── ui/      performance_hud.gd
│   ├── world/   chunk_streaming.gd / chunk_streaming_r4.gd / chunk_streaming_r5.gd
│   ├── build_main.gd            [映射表 #11，落 scripts/ 根]
│   └── build_courtyard.gd       [映射表 #12，落 scripts/ 根]
├── scenes/
│   ├── Main.tscn
│   ├── courtyard.tscn
│   └── world/chunks/            [空目录，供 3 号真实 chunk 场景落位]
└── data/render/ quality_preset_desktop.tres / quality_preset_mobile.tres / render_profiles.tres
```

边界说明：`build_main.gd` / `build_courtyard.gd` 按 `PROJECT_ROOT_LAYOUT.md` §2 映射表落在 `scripts/` 根，属 Rank-1 自有交付件，不与任何工位授权子目录（`combat` / `rpg` / `render` 具体文件）重叠；`scripts/render/` 与 Rank-4 的 `hd2d_placeholder.gd` 共享父路径，本轮用 `cp -n` 保证不覆盖他人文件。

### 1.2 门禁时点工程根实际全树（按 HOST 02:23 授权分工分组，只读观察）

三段门禁为 **02:30 时点快照**。此时其它工位已并行落位下列文件（归属按 `MSG-20261109-0223-HOST` 授权的目录分工与路径推断，**未读取文件内容、未扫其它工位 `teamwork\Rank-N\` 目录**）：

- **Rank-3**（`scripts/rpg` + `data/rpg` + `assets/audio/voice`）：22 个 `scripts/rpg/*.gd`（`chunk_world_bridge` / `dialogue_choice` / `dialogue_gate` / `dialogue_graph` / `dialogue_line` / `dialogue_node` / `dialogue_runner` / `dungeon_definition` / `game_events` / `grace_network` / `grace_node` / `interactable_spec` / `m6_area_bindings` / `quest_data` / `quest_stage` / `quest_state_machine` / `save_delta` / `save_delta_writer` / `spawn_request` / `voice_line_binder` / `world_baseline` / `world_state`）；`data/rpg/` 8 件（5 个 `.tres` + `voice_key_table.json` / `voice_manifest.json` / 等）；`assets/audio/voice/` 3 个 `.wav` + 对应 `.import`。
- **Rank-4**（`assets/generated` + `scripts/render/hd2d_placeholder.gd`）：`assets/generated/` 4 个 `.json`（`delivery_manifest` / `import` / `palette_256` / `pose_names`）；`scripts/render/hd2d_placeholder.gd`。
- **Rank-2**（`scripts/combat` + `data/combat`）：门禁时点实际树中**未出现**这两个目录，仅登记路径观察，不臆测进度、不刺探。
- **引擎产物**：G1 `--import` 生成 `godot\.godot\` 缓存与 33 个 `.gd.uid`（对应主跑快照的 33 个 `.gd`）。属正式 Godot 工程根正常产物，本轮保留；17 件 Rank-1 源件内容未被改动。

门禁后只读核对：工程根当前 `.gd` 共 **34 个** = Rank-1 11 + Rank-3 22 + Rank-4 1。Rank-4 的 `hd2d_placeholder.gd` 落位晚于 G2 主跑，已单独补跑 `--check-only`（EXIT=0，见 §3）。

---

## 2. autoload 汇总（`project.godot` `[autoload]` 段，5 项）

| autoload | `project.godot` 注册路径 | 归属 | 门禁时点工程根实际 | G1 / G3 表现 |
|---|---|---|---|---|
| WorldState | `res://scripts/world/world_state.gd` | 3 号 | **该路径 MISSING**；同名文件实际在 `scripts/rpg/world_state.gd` | 各 3 条 ERROR，共 6 条 |
| GameEvents | `res://scripts/core/game_events.gd` | 3 号 | **该路径 MISSING**；同名文件实际在 `scripts/rpg/game_events.gd` | 各 3 条 ERROR，共 6 条 |
| SaveSystem | `res://scripts/world/save_system.gd` | 3 号 | **全工程根无 `save_system.gd`** | 各 3 条 ERROR，共 6 条 |
| ChunkManager | `res://scripts/world/chunk_streaming.gd` | 1 号 | 已在树中 | 正常加载；9 条 `scene_missing` WARNING（chunk 场景未落位） |
| SceneRouter | `res://scripts/core/scene_router.gd` | 1 号 | 已在树中 | 正常加载 |

**核心发现（本轮新增，须 HOST 裁决）**：3 号已把 `world_state.gd` / `game_events.gd` 落在 `scripts/rpg/`，而 `project.godot` 的 autoload 注册在 `scripts/world/` / `scripts/core/`；`save_system.gd` 则完全未落位。这是**跨工位路径口径不一致 + 依赖缺失**，不是 Rank-1 17 件的脚本缺陷、不是 `SCRIPT ERROR`。按硬约束「待裁决项只登记不擅改」、`R6-待裁决登记.md` §3 建议（「落位到 `project.godot` 已登记路径，通常只需补文件，无需改配置」）与契约 §7（跨模块冲突由主 AI 统一裁决），**本轮未改 `project.godot`、未移动 3 号文件**。

`run/main_scene="res://scenes/Main.tscn"`；`[rendering]` 用 Godot 4 合法键 `textures/canvas_textures/default_texture_filter=0`（Nearest）；`[physics]` Jolt Physics + 60 tick；`[input]` 15 个 action；`[hd2d]` 冻结值 `640×360@2x` / `pixels_per_meter=32.0`；双档 `.tres` 路径登记在 `data/render/`。

---

## 3. 三段门禁结论（真跑实际输出）

`<godot>` = `D:/Godot/Godot_v4.7.2-stable_win64.exe`；`<root>` = `F:/Game/aierdengfahuan/godot`；日志留存 `C:/Users/62668/AppData/Local/Temp/r1_r7_gate/`（`g1.log` / `g2_all.log` / `g3.log` / `g2_extra.log` / `all_final.log`）。

| 段 | 实际命令 | EXIT | 实际输出结论 |
|---|---|---|---|
| G0 | `<godot> --version` | 0 | `4.7.2.stable.official.ed1daf0bf` |
| G1 | `<godot> --headless --path <root> --import` | **0** | `first_scan_filesystem` 5 步 DONE；`update_scripts_classes` **33 步** DONE（注册 `QualityPreset` / `RenderProfiles` / `HybridSpriteRig` 及 3 号 `ChunkWorldBridge` / `SaveDelta` / `WorldBaseline` / `GraceNetwork` / `SpawnRequest` / `DialogueGraph` / `QuestData` / `M6AreaBindings` / `VoiceLineBinder` 等全局类）；`_update_scan_actions` / `reimport` 导入 3 个 WAV；**9 条 autoload ERROR**（无 Parse Error） |
| G2 | 对工程内 33 个 `.gd` 逐个 `<godot> --headless --path <root> --check-only --script res://<f>.gd` | **33 条均 0** | Rank-1 11 个 + Rank-3 22 个 `.gd` 全部静态解析通过，无 Parse Error |
| G2' | 补跑 `res://scripts/render/hd2d_placeholder.gd` | **0** | 门禁后并行落位件的补充静态检查通过 |
| G3 | `<godot> --headless --path <root> --quit` | **0** | 9 条 `Failed to instantiate an autoload` ERROR + 9 条 `[ChunkManager] chunk_limgrave_* 加载跳过：scene_missing` WARNING；**无 `ObjectDB instances leaked`** |

合并 4 段日志 `grep` 判据（实际计数）：

```
SCRIPT ERROR 命中数(最终合并): 0
Parse Error 命中数(最终合并): 0
ERROR 行数(最终合并): 18
WARNING 行数(最终合并): 9
leaked 行数(最终合并): 0
```

**判据：`SCRIPT ERROR = NONE` 通过**（运行时 SCRIPT ERROR 不改退出码，必须 grep）。三段 EXIT 全 0、34 个 `.gd` 静态检查全 0。但**不冒充全绿**：18 条 ERROR + 9 条 WARNING 如实登记并归类如下。

### 3.1 18 条 ERROR 逐条归类（全部为跨工位依赖，非脚本错误）

- G1（9 条，`g1.log` 第 8/10/12、14/16/18、20/22/24 行）：`world_state.gd` / `game_events.gd` / `save_system.gd` 各 3 条 ——
  `ERROR: Attempt to open script 'res://scripts/world/world_state.gd' resulted in error 'File not found'.`、
  `ERROR: Failed loading resource: ...`、`ERROR: Failed to create an autoload, can't load from UID or path: ...`。
- G3（9 条，`g3.log` / 合并日志第 160/162/164、166/168/170、172/174/176 行）：同 3 个脚本各 3 条 ——
  `ERROR: Attempt to open script ... 'File not found'.`、`ERROR: Failed loading resource: ...`、
  `ERROR: Failed to instantiate an autoload, can't load from path: ...`（`at: start (main/main.cpp:4533)`）。

结论：18 条全部指向 §2 的 3 个 3 号 autoload 路径 —— 路径口径不一致（文件在 `scripts/rpg/` 而注册在 `scripts/world|core/`）+ `save_system.gd` 缺失。属 `PROJECT_ROOT_LAYOUT.md` §8.3 / `R6-待裁决登记.md` §3 已预判的跨工位依赖未对齐，**不是 `SCRIPT ERROR`、不是 Rank-1 交付件缺陷**。

### 3.2 9 条 WARNING 归类

G3 中 `[ChunkManager] chunk_limgrave_-1_-1 / 0_-1 / 1_-1 / -1_0 / 0_0 / 1_0 / -1_1 / 0_1 / 1_1 加载跳过：scene_missing`（`at: push_warning`，backtrace 指向 `res://scripts/world/chunk_streaming.gd:196 _report_failure_once` ← `:172 _request_chunk` ← `:90 set_player_chunk` ← `:54 _bootstrap`）。根因：`res://scenes/world/chunks/chunk_limgrave_<x>_<y>.tscn` 真实 chunk 场景（3 号 I-1 / I-6）未落位，我已保留该空目录。

### 3.3 关于 `ObjectDB instances leaked`

本轮 `leaked` 命中数 **0**（G3 未出现 R5 记录的 `2 ObjectDB instances leaked`）。与 `PROJECT_ROOT_LAYOUT.md` §5 对照实验 **D1** 一致：chunk 场景缺失时 `load_threaded_request` 未发起，无在途异步 `RefCounted` 残留 → 0。R5 已定位根因并给出 `--quit-after 10` 消除方案，本轮按契约 §10 固定 `--headless --quit` 跑，未重复实证消除方案、未改 R2 既有件。

---

## 4. 待接入项 / 未完成项（只登记，不擅改）

1. **【本轮新增·最高优先】3 号 autoload 路径口径不一致**：见 §2。`world_state.gd` / `game_events.gd` 在 `scripts/rpg/` 而 autoload 注册在 `scripts/world/` / `scripts/core/`，`save_system.gd` 全工程根缺失。请 HOST 裁决：① 由 3 号 / 主 AI 把文件补/移到 autoload 已登记路径（R6 §3 建议口径）；② 或授权改 `project.godot` 的 autoload 路径指向 `scripts/rpg/`。裁决后回归门禁，预期 18 条 ERROR 消失，作为接入成功判据。**本轮未改 `project.godot`、未动 3 号文件。**
2. **真实 chunk 场景未落位**：`res://scenes/world/chunks/chunk_limgrave_<x>_<y>.tscn`（3 号 I-1 / I-6）→ 9 条 `scene_missing` WARNING。空目录已保留。
3. **Rank-2 子目录未见落位**：门禁时点实际树中未出现 `scripts/combat/` / `data/combat/`（HOST 02:23 授权归 2 号）。仅登记路径观察，不读内容、不刺探、不臆测进度。
4. **门禁快照时序**：三段门禁为 02:30 时点快照，其它工位并行落位；`scripts/render/hd2d_placeholder.gd`（4 号）在 G2 主跑后落位，已补跑静态检查 EXIT=0。当前 34 个 `.gd` 全部 `--check-only` EXIT=0。
5. **R5 件接入正式装配层**：`chunk_streaming_r5.gd` 是否注册 autoload / 由装配层实例化并调用 `apply_preset_path(...)`，需改既有件，待裁决（沿用 `R6-待裁决登记.md` §4 / `PROJECT_ROOT_LAYOUT.md` §7-2）。
6. **运行期帧时间 / p99 / spike 实测**：三段全 `--headless`，无渲染管线，未做、未伪造（沿用 `R6-待裁决登记.md` §2）；`16.67 / 33.33 ms` 仅为 `.tres` 目标值静态核对，需 F3 HUD + 人工试玩。
7. **任务书 §交付清单第 3 行的「`build_courtyard.gd` 场景生成」**：本轮按用户本轮「本轮任务」第 3 条与任务书 §真跑要求口径执行三段门禁，未额外执行场景生成；`courtyard.tscn` 已作为 17 件之一落位并经 G1 `--import` 校验、`build_courtyard.gd` 经 G2 `--check-only` EXIT=0。如实登记口径差异，不擅自扩展、不硬造新功能。
8. **R2/R3/R4 遗留待裁决（延续，未擅改）**：4 号 A8 `@3x` vs 本工位 `@2x` 冻结值、负坐标 chunk id 命名、`GameEvents` 最终归属、`canvas_items` vs `canvas_textures` 合法键（后者已为合法键）、`HybridSpriteRig` 类名与 GDExtension 全局类同名风险、`128bit` 确切含义、Rank-2 E-8 数值冲突。

---

## 5. 边界与合规声明

- **实际写入**：`godot\project.godot` + 授权目录 + 17 件（原样拷贝，逐字节一致，无覆盖）；`Rank-1\ASSEMBLY-REPORT.md`、`Rank-1\DONE-R7.md`；`command_center\ai\1\outbox\cmd-20261109-022336-996-A1.json` 回执 JSON（写入成功后由中枢按既定流程回收至 `command_center\dispatcher\receipts\cmd-20261109-022336-996-A1.json`，内容逐字一致、语法校验合法；`ai\1\status.json` 转 `idle` / `completed=12`；outbox 消费后为空属正常状态，非写入失败）。
- **未写入**：其它工位子目录（`scripts/combat`、`scripts/rpg`、`data/combat`、`data/rpg`、`assets/generated`、`assets/audio/voice`）、`00-群聊总线.md` / 总纲 / 契约 / 其它工位文件；未 git commit/push、未调用任何付费 API / 外部服务、未写探针 / 测量 / preflight 脚本。
- **`project.godot` 未因门禁 ERROR 做任何修改**（待裁决项只登记不擅改）；17 件源件内容未改动、未重做。
- 引擎产物 `.godot\` 缓存与 33 个 `.gd.uid` 为 G1 `--import` 生成，属正式工程根正常产物，保留。
- 本报告全部结论来自真跑实际输出（日志留存路径见 §3），**未伪造输出、未冒充全绿**。
