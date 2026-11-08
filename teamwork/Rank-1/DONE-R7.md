# DONE-R7.md · Rank-1（引擎架构与渲染）· R7 完成标志

> 轮次：R7「工程根正式落位 + 全量装配门禁」
> 任务单 id：`cmd-20261109-022336-996-A1`（派单 `Rank-1\调度任务单-latest.json` / `任务书-R7.md`）
> 授权：`MSG-20261109-0223-HOST` 总指挥 02:23 裁决 —— 解除空转保护，正式授权在 `F:\Game\aierdengfahuan\godot\` 建立统一工程根
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（`--version` 实测 `4.7.2.stable.official.ed1daf0bf`，EXIT=0）
> 完成标志：本文件 + `ASSEMBLY-REPORT.md` + `command_center\ai\1\outbox\` 回执 JSON
> 本文件结论全部来自真跑实际输出，未伪造、未冒充全绿。

---

## ① 实际交付清单

| # | 交付件 | 落位 | 说明 |
|---|---|---|---|
| 1 | `godot\project.godot` | `F:\Game\aierdengfahuan\godot\` | 建立工程根配置文件；**原样落位** `Rank-1\project_root\project.godot`，`config_version=5` 沿用 R5/R6 已实测口径，未硬编码新值、未改一字 |
| 2 | 工程根授权目录树 | `godot\scripts\core|render|ui|world`、`godot\scenes`、`godot\data\render` | 随 17 件落位一并建立；含空目录 `godot\scenes\world\chunks\`（供 3 号真实 chunk 场景） |
| 3 | 17 件按 `res://` 映射落位 | `godot\` | 依 `PROJECT_ROOT_LAYOUT.md` §2 映射表逐件拷贝，逐件核对「存在 / 非空 / 与源逐字节一致」全通过；`godot\` 落位前不存在、`cp -rn` 无覆盖任何既有文件 |
| 4 | 三段门禁 + grep | `godot\` 全量 | G1 `--headless --import` → G2 全量 `.gd` `--check-only --script` → G3 `--headless --quit` + 合并日志 `grep SCRIPT ERROR`，另补跑 1 个并行落位件 |
| 5 | `Rank-1\ASSEMBLY-REPORT.md` | 本工位 | 工程树 / autoload 汇总 / 门禁结论 / 待接入项 / 边界声明 |
| 6 | `Rank-1\DONE-R7.md` | 本工位 | 本文件（完成标志） |
| 7 | 回执 JSON | `command_center\ai\1\outbox\` | 按任务单 id `cmd-20261109-022336-996-A1` 写 `status: done`，`result` 引用本文件实际结论 |

17 件明细（`res://` 相对 `godot\`）：`project.godot`；`scripts/core/{scene_router,quality_preset,render_profiles}.gd`；`scripts/render/{camera_rig,hybrid_2d3d_animated_sprite}.gd`；`scripts/ui/performance_hud.gd`；`scripts/world/{chunk_streaming,chunk_streaming_r4,chunk_streaming_r5}.gd`；`scripts/{build_main,build_courtyard}.gd`；`scenes/{Main,courtyard}.tscn`；`data/render/{quality_preset_desktop,quality_preset_mobile,render_profiles}.tres`。合计 17 件 / 11 个 `.gd`，与映射表逐件一致。

---

## ② 自检（真跑命令与实际输出结论）

引擎与工程根：`<godot>` = `D:/Godot/Godot_v4.7.2-stable_win64.exe`；`<root>` = `F:/Game/aierdengfahuan/godot`；门禁日志留存 `C:/Users/62668/AppData/Local/Temp/r1_r7_gate/`。

### 2.1 落位自检（实际输出）

`--version` 实测：`4.7.2.stable.official.ed1daf0bf`，`VERSION_EXIT=0`（与 R5/R6 一致）。

落位前只读核对：`godot\` 输出 `No such file or directory`（全新建立，无覆盖风险）；`project_root\` 实体文件 **17** 个、`.gd` **11** 个，与映射表一致。

落位后逐件核对实际输出（节选格式，17 行全部 `OK`）：

```
OK[1] project.godot (5318 bytes)
OK[2] scripts/core/scene_router.gd (5078 bytes)
...
OK[17] data/render/render_profiles.tres (685 bytes)
核对通过件数=17
```

`cmp -s` 逐件比对源与目标**全部一致**，17 件未被改动。

### 2.2 三段门禁实际输出结论

| 段 | 实际命令 | 实际 EXIT | 实际输出结论 |
|---|---|---|---|
| G1 | `<godot> --headless --path <root> --import` | **0** | `first_scan_filesystem` 5 步 `[ DONE ]`；`update_scripts_classes` **33 步** `[ DONE ]`（注册 `QualityPreset` / `RenderProfiles` / `HybridSpriteRig` / `ChunkWorldBridge` / `SaveDelta` / `WorldBaseline` / `GraceNetwork` / `GraceNode` / `Dialogue*` / `Quest*` / `SpawnRequest` / `M6AreaBindings` / `VoiceLineBinder` 等全局类）；`_update_scan_actions` 与 `reimport` 导入 `vo_bellkeeper_01/02.wav`、`vo_grace_memory_01.wav`；**9 条 autoload `ERROR`**（详见 2.4），无 Parse Error |
| G2 | 对 33 个 `.gd` 逐个 `<godot> --headless --path <root> --check-only --script res://<f>.gd` | **33 条均 0** | Rank-1 11 个 + Rank-3 22 个 `.gd` 全部静态解析通过，日志仅引擎版本行，无 Parse Error |
| G2' | 补跑 `res://scripts/render/hd2d_placeholder.gd` | **0** | 门禁后并行落位件的补充静态检查通过（当前工程根 `.gd` 共 34 个，全部 `--check-only` EXIT=0） |
| G3 | `<godot> --headless --path <root> --quit` | **0** | **9 条** `Failed to instantiate an autoload` ERROR + **9 条** `[ChunkManager] chunk_limgrave_* 加载跳过：scene_missing` WARNING；**无 `ObjectDB instances leaked`** |

### 2.3 合并日志 `grep` 判据（实际计数，逐字）

```
SCRIPT ERROR 命中数(最终合并): 0
Parse Error 命中数(最终合并): 0
ERROR 行数(最终合并): 18
WARNING 行数(最终合并): 9
leaked 行数(最终合并): 0
```

**门禁判据：`SCRIPT ERROR = NONE`，通过**（运行时 SCRIPT ERROR 不改退出码，必须 grep）。三段 EXIT 全 0；工程根当前 34 个 `.gd` 静态检查全 0。

### 2.4 如实登记：不冒充全绿

18 条 ERROR 全部为**跨工位依赖未对齐**，不是 `SCRIPT ERROR`、不是 Rank-1 17 件缺陷：

- G1 9 条：`world_state.gd` / `game_events.gd` / `save_system.gd` 各 3 条 —— `Attempt to open script ... 'File not found'.` / `Failed loading resource: ...` / `Failed to create an autoload, can't load from UID or path: ...`
- G3 9 条：同 3 个脚本各 3 条 —— `Attempt to open script ... 'File not found'.` / `Failed loading resource: ...` / `Failed to instantiate an autoload, can't load from path: ...`（`at: start (main/main.cpp:4533)`）

只读核对确认根因：`project.godot` 的 3 个 3 号 autoload 注册在 `res://scripts/world/world_state.gd`、`res://scripts/core/game_events.gd`、`res://scripts/world/save_system.gd`，三者 **MISSING**；而 3 号实际把 `world_state.gd` / `game_events.gd` 落在 `scripts/rpg/`，`save_system.gd` 全工程根不存在 —— **跨工位路径口径不一致 + 依赖缺失**。按硬约束「待裁决项只登记不擅改」，**未改 `project.godot`、未移动 3 号文件**。

9 条 WARNING 为 G3 中 `chunk_limgrave_-1_-1 ~ 1_1` 共 9 个 chunk 场景 `scene_missing`（backtrace 指向 `res://scripts/world/chunk_streaming.gd`），根因是 `res://scenes/world/chunks/` 真实 chunk 场景（3 号 I-1/I-6）未落位；空目录已保留。

`leaked = 0` 与 `PROJECT_ROOT_LAYOUT.md` §5 对照实验 D1 一致（chunk 场景缺失 → `load_threaded_request` 未发起 → 无在途 `RefCounted` 残留），本轮按契约 §10 固定 `--headless --quit` 跑，未重复实证 R5 的 `--quit-after 10` 消除方案、未改 R2 既有件。

### 2.5 门禁时点说明（诚实标注覆盖范围）

三段门禁为 **02:30 时点快照**，其它工位并行落位：G1 全局类注册达 33 步、G2 扫到 33 个 `.gd`（不止 Rank-1 的 11 个），说明 Rank-3 的 `scripts/rpg/*.gd`、`data/rpg/*`、`assets/audio/voice/*` 与 Rank-4 的 `assets/generated/*` 已落位；Rank-4 的 `scripts/render/hd2d_placeholder.gd` 在 G2 主跑**之后**落位，已补跑静态检查 EXIT=0；Rank-2 的 `scripts/combat/` / `data/combat/` 在门禁时点实际树中未出现（仅登记路径观察，不读内容、不刺探、不臆测进度）。门禁后引擎产物 `.godot\` 缓存与 33 个 `.gd.uid` 保留，17 件源件内容未改动。

---

## ③ 未完成项与阻塞

1. **【本轮新增·需 HOST 裁决】3 号 autoload 路径口径不一致**：`world_state.gd` / `game_events.gd` 在 `scripts/rpg/` 而 autoload 注册在 `scripts/world/` / `scripts/core/`，`save_system.gd` 全工程根缺失 → 18 条 ERROR。请裁决：① 由 3 号 / 主 AI 把文件补/移到 autoload 已登记路径（`R6-待裁决登记.md` §3 建议口径）；② 或授权改 `project.godot` autoload 路径指向 `scripts/rpg/`。裁决后回归门禁，预期 18 条 ERROR 消失。本轮未擅改。
2. **真实 chunk 场景未落位**：`res://scenes/world/chunks/chunk_limgrave_<x>_<y>.tscn`（3 号 I-1/I-6）→ 9 条 `scene_missing` WARNING。
3. **Rank-2 子目录未见落位**：`scripts/combat/` / `data/combat/`（HOST 02:23 授权归 2 号）门禁时点未出现，仅登记、不刺探。
4. **门禁非「全绿」**：三段 EXIT 全 0、`SCRIPT ERROR`=NONE、34 个 `.gd` 静态检查全 0 均属实，但 18 条 ERROR / 9 条 WARNING 如实存在，均为跨工位依赖问题，**本轮不冒充全绿、不伪造输出**。
5. **R5 件接入正式装配层**：`chunk_streaming_r5.gd` 注册 autoload / 装配层实例化需改既有件，待裁决（沿用 `R6-待裁决登记.md` §4 / `PROJECT_ROOT_LAYOUT.md` §7-2）。
6. **运行期帧时间 / p99 / spike 实测**：三段全 headless，无渲染管线，未做、未伪造；`16.67 / 33.33 ms` 仅为 `.tres` 目标值静态核对，需 F3 HUD + 人工试玩。
7. **任务书 §交付清单第 3 行「`build_courtyard.gd` 场景生成」口径差异**：本轮按用户本轮「本轮任务」第 3 条与任务书 §真跑要求执行三段门禁，未额外执行场景生成；`courtyard.tscn` 已落位并经 G1 `--import` 校验、`build_courtyard.gd` 经 G2 `--check-only` EXIT=0。如实登记，不擅自扩展、不硬造新功能。
8. **R2/R3/R4 遗留待裁决（延续，未擅改）**：4 号 A8 `@3x` vs `@2x` 冻结值、负坐标 chunk id、`GameEvents` 归属、`canvas_items` vs `canvas_textures` 合法键、`HybridSpriteRig` 全局类同名风险、`128bit` 含义、Rank-2 E-8 数值冲突。
9. **git 收尾**：按契约 §9.1 由主 AI 统一 commit + push，执行 AI 本轮未自行 git。

---

## 附：本轮改动文件清单

**工程根 `F:\Game\aierdengfahuan\godot\`（新建）**
- `project.godot`（独占，原样落位）
- `scripts/core/`：3 件 ｜ `scripts/render/`：2 件 ｜ `scripts/ui/`：1 件 ｜ `scripts/world/`：3 件 ｜ `scripts/`：2 件（`build_*.gd`）
- `scenes/`：`Main.tscn`、`courtyard.tscn` + 空目录 `world\chunks\`
- `data/render/`：3 件
- 引擎产物（非交付件）：`.godot\` 缓存、33 个 `.gd.uid`（G1 `--import` 生成，保留）

**Rank-1 工位 `F:\Game\aierdengfahuan\teamwork\Rank-1\`（新建）**
- `ASSEMBLY-REPORT.md`、`DONE-R7.md`

**回执例外 `F:\Game\aierdengfahuan\teamwork\command_center\ai\1\outbox\`（新建）**
- `cmd-20261109-022336-996-A1.json` —— 写入 `status: done` 后由中枢按既定流程回收至 `command_center\dispatcher\receipts\cmd-20261109-022336-996-A1.json`（内容逐字一致，`python -m json.tool` 校验语法合法、字段 `task_id/ai/status` 正确）；`ai\1\status.json` 同步转 `idle` / `completed=12`（02:37:26）。outbox 消费后为空是中枢回收回执的正常状态，与 R2~R6 一致，**非写入失败、非漏交**。

**未改动**：`project_root\` 17 件源件、任何既有交付件、其它工位文件、总线 / 总纲 / 契约；未写其它工位子目录、未自行 git、未付费 / 未外部依赖、未写探针脚本。
