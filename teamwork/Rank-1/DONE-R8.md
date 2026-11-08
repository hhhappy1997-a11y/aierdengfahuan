# DONE-R8.md · Rank-1（引擎架构与渲染）· R8 完成标志

> 轮次：R8「全工程门禁清零 + 装配层闭合」
> 任务单 id：`cmd-20261109-024906-799-A1`（派单 `Rank-1\任务书-R8.md` / `调度任务单-latest.json`）
> 授权：`MSG-20261109-0249-HOST`（02:49 续派；`project.godot` 仍由 Rank-1 独占，本轮明确授权修正 autoload 注册路径）
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（`--version` 实测 `4.7.2.stable.official.ed1daf0bf`，EXIT=0）
> 完成标志：本文件 + `GATE-REPORT-R8.md` + `command_center\ai\1\outbox\` 回执 JSON
> 本文件全部结论来自真跑实际输出，**未伪造、未冒充全绿**；总目标 `ERROR=0` 未达成，见 §2.5 / ③。

---

## ① 实际交付清单

| # | 交付件 | 落位 | 说明 |
|---|---|---|---|
| 1 | `project.godot` autoload 路径修正 | `godot\project.godot` | 独占件；`WorldState` / `GameEvents` 改指向实际落位 `scripts/rpg/`；新增 9 行 R8 裁决注释；`SaveSystem` 行保持指向补件路径 |
| 2 | `save_system.gd` 装配占位 | `godot\scripts\world\save_system.gd` | 补 R7 全工程缺失件；`extends Node` + 空 `_ready`，不实现存档读写（I-1 归 3 号），归属声明写入文件头 |
| 3 | 9 个 chunk 场景占位 | `godot\scenes\world\chunks\chunk_limgrave_<x>_<y>.tscn` | x,y ∈ {-1,0,1}；合法 `format=3` `PackedScene`（`Node3D` 根节点），消除 9 条 `scene_missing` |
| 4 | 修正前门禁基线真跑 | 日志 `before_*` | G1 + G3，取 ERROR/WARNING 计数基线 |
| 5 | 修正后全量三段门禁 ×2 | 日志 `after_*` / `final_*` | 完整 G1 → G2（全量 `.gd`）→ G3 两次，结果一致 |
| 6 | `GATE-REPORT-R8.md` | 本工位 | 门禁前后对照（前后计数、逐条 ERROR、根因、裁决建议、时序） |
| 7 | `DONE-R8.md` | 本工位 | 本文件（完成标志） |
| 8 | 回执 JSON | `command_center\ai\1\outbox\` | 按任务单 id `cmd-20261109-024906-799-A1` 写 `status: done`，`result` 引用本文件实际结论（含 ERROR 未清零事实） |

### 改动文件逐件清单

| 文件 | 动作 | 内容 |
|---|---|---|
| `godot\project.godot` | 修改 | `[autoload]`：`WorldState` `scripts/world/world_state.gd` → `scripts/rpg/world_state.gd`；`GameEvents` `scripts/core/game_events.gd` → `scripts/rpg/game_events.gd`；`SaveSystem` 保持 `scripts/world/save_system.gd`；文件头新增 9 行 R8 裁决注释 |
| `godot\scripts\world\save_system.gd` | 新增 | 装配占位（中文注释 + `extends Node` + `func _ready(): pass`） |
| `godot\scenes\world\chunks\chunk_limgrave_-1_-1.tscn` … `1_1.tscn` | 新增 ×9 | 各 3 行：`[gd_scene format=3]` + `Node3D` 根节点 |
| `teamwork\Rank-1\GATE-REPORT-R8.md` | 新增 | 门禁前后对照 |
| `teamwork\Rank-1\DONE-R8.md` | 新增 | 本文件 |
| `teamwork\command_center\ai\1\outbox\cmd-20261109-024906-799-A1.json` | 新增 | 回执 |

未改动：任何 Rank-2/3/4 子目录（`scripts/combat`、`scripts/rpg`、`data/combat`、`data/rpg`、`assets/generated`、`assets/audio/voice`）、其它工位文件、总线 / 总纲 / 契约、`project_root\` 源件、`chunk_streaming.gd` / `Main.tscn` 等既有件。

---

## ② 自检（真跑命令与实际输出结论）

`<godot>` = `D:/Godot/Godot_v4.7.2-stable_win64.exe`；`<root>` = `F:/Game/aierdengfahuan/godot`；日志留存 `C:/Users/62668/AppData/Local/Temp/r1_r8_gate/`（`before_g1/g3/all.log`、`after_*`、`final_*`）。

### 2.1 开工核对（只读，一次）

- 引擎 `--version` 实测 `4.7.2.stable.official.ed1daf0bf`，`VERSION_EXIT=0`。
- `project.godot` `[autoload]` 5 项现状：WorldState `scripts/world/world_state.gd`、GameEvents `scripts/core/game_events.gd`、SaveSystem `scripts/world/save_system.gd`、ChunkManager `scripts/world/chunk_streaming.gd`、SceneRouter `scripts/core/scene_router.gd`。
- 存在性核对：`scripts/world/world_state.gd` / `scripts/core/game_events.gd` / `scripts/world/save_system.gd` / `scripts/rpg/save_system.gd` 全部 **MISSING**；`scripts/rpg/world_state.gd`、`scripts/rpg/game_events.gd` **EXIST**；`save_system.gd` 全工程根 `find` 无命中；`scenes/world/chunks/` 为空目录。
- 目标脚本兼容性：`scripts/rpg/world_state.gd` / `game_events.gd` 均 `extends Node`（可作 autoload）；`world_state.gd._ready()` → `_register_baseline()` 用 `ResourceLoader.exists` + `push_warning` 加载 `res://data/rpg/*.tres`（5 件经核对齐全），不依赖 SaveSystem 方法。
- chunk 路径口径（读本工位 `chunk_streaming.gd`）：`CHUNK_SCENE_DIR = "res://scenes/world/chunks/"`，`_make_id(x,y) = "chunk_%s_%d_%d" % [region,x,y]`（region 默认 `limgrave`），`RADIUS=1` → 需 9 个 `chunk_limgrave_<x>_<y>.tscn`（x,y ∈ {-1,0,1}）；`Main.tscn:97` 有 `ChunkRoot`，不会新增「未找到 ChunkRoot」WARNING。

### 2.2 修正前基线（真跑，`before_*`）

| 段 | 实际命令 | EXIT | 实际输出 |
|---|---|---|---|
| G1 | `<godot> --headless --path <root> --import` | 0 | `first_scan_filesystem` 5 步 DONE；9 条 autoload ERROR |
| G3 | `<godot> --headless --path <root> --quit` | 0 | 9 条 `Failed to instantiate an autoload` ERROR + 9 条 `[ChunkManager] ... scene_missing` WARNING |

合并 `before_all.log` grep 实际计数（逐字）：

```
SCRIPT ERROR: 0
Parse Error: 0
ERROR lines: 18
WARNING lines: 9
leaked lines: 0
```

18 条 ERROR 逐条与 R7 `ASSEMBLY-REPORT.md` §3.1 一致，全部为 3 个 autoload 路径（G1 9 + G3 9）；9 条 WARNING 全为 `scene_missing`。**与 R7 报告口径完全一致**。基线只跑 G1+G3（ERROR/WARNING 全部源于这两段），未跑 G2；R7 §3 已记录当时 34 个 `.gd` 全 `--check-only` EXIT=0。

### 2.3 修正后首次完整三段（真跑，`after_*`）

| 段 | EXIT / 计数 | 实际结论 |
|---|---|---|
| G1 `--import` | 0 | 无 autoload ERROR；`update_scripts_classes` 3 步 DONE |
| G2 全量 `.gd` | `G2_TOTAL=49 G2_FAIL=1` | 48 个 EXIT=0；`res://scripts/rpg/spawn_request.gd` EXIT=1 |
| G3 `--quit` | 0 | 2 条 `SCRIPT ERROR: Parse Error: Class "SpawnRequest" hides a global script class.` + 2 条 `ERROR: Failed to load script ...`；1 条 leaked WARNING |

合并 `after_all.log` grep：`SCRIPT ERROR=2 / Parse Error=2 / ERROR 行数=4 / WARNING=1 / leaked=1`。

### 2.4 最终稳定快照（真跑，`final_*`）

因其它工位并行落位（`.gd` 46 → 49 → 50），完整重跑三段覆盖当前全部 50 个 `.gd`：

| 段 | EXIT / 计数 | 实际结论 |
|---|---|---|
| G1 | 0 | 无 autoload ERROR |
| G2 | `FINAL_G2_TOTAL=50 FINAL_G2_FAIL=1` | 49 个 EXIT=0；唯一失败件仍为 `res://scripts/rpg/spawn_request.gd` |
| G3 | 0 | 同 after：2 条 SCRIPT ERROR + 2 条 ERROR + 1 条 leaked WARNING |

合并 `final_all.log` grep（逐字）：

```
SCRIPT ERROR: 2
Parse Error: 2
ERROR lines: 4
WARNING lines: 1
leaked lines: 1
```

`after` 与 `final` 两次完整三段结果**一致**，结论稳定。

### 2.5 ERROR 计数前后对比（核心）

| 判据 | 修正前 `before_all.log` | 修正后 `final_all.log` | 变化 |
|---|---|---|---|
| `SCRIPT ERROR` | 0 | 2 | 新增暴露（跨工位，见 2.6） |
| `Parse Error` | 0 | 2 | 新增暴露（跨工位，见 2.6） |
| **`ERROR` 行数** | **18** | **4** | **18 → 4，未到 0** |
| `WARNING` 行数 | 9 | 1 | 9 条 `scene_missing` 全清 → 剩 1 条 leaked |
| `leaked` | 0 | 1 | R5 已定位 WARNING 级现象随 chunk 场景落位复现 |
| G1 / G3 EXIT | 0 / 0 | 0 / 0 | — |
| G2 `.gd` | 基线未跑（R7：34 全 0） | 50 个，49 个 EXIT=0 | 1 个跨工位失败件 |

计数口径：`grep -c "ERROR"` 会把 `SCRIPT ERROR: ...` 行一并计入（与 R7 同口径）。修正后 4 行 = 2 行 `SCRIPT ERROR: Parse Error:` + 2 行 `ERROR: Failed to load script`，实为 **2 个错误事件**在 G2 与 G3 各出现一次。

- ✅ **18 条 autoload ERROR 全部消除**（`final_all.log` 中 0 条 autoload 相关 ERROR）。
- ✅ **9 条 `scene_missing` WARNING 全部消除**。
- ❌ **总目标 `ERROR=0` 未达成**：剩余 4 行均为跨工位 `SpawnRequest` 同名全局类冲突，按用户口径如实登记、不冒充全绿。

### 2.6 如实登记：不冒充全绿（4 行 ERROR 归类）

`final_all.log` 逐字 4 行（`final_g3.log` 完整 backtrace 见 `GATE-REPORT-R8.md` §4）：

```
143:SCRIPT ERROR: Parse Error: Class "SpawnRequest" hides a global script class.
145:ERROR: Failed to load script "res://scripts/rpg/spawn_request.gd" with error "Parse error".
173:SCRIPT ERROR: Parse Error: Class "SpawnRequest" hides a global script class.
178:ERROR: Failed to load script "res://scripts/rpg/spawn_request.gd" with error "Parse error".
```

根因（只读定位）：`grep "class_name SpawnRequest"` 命中 2 处 —— `godot/scripts/combat/spawn_request.gd:2`（Rank-2）与 `godot/scripts/rpg/spawn_request.gd:2`（Rank-3，I-3 权威定义），**同名全局类冲突**。修正 autoload 后 WorldState 首次成功实例化 → `_ready()` → `_register_baseline()`（`world_state.gd:110`）加载 `.tres` 触发 rpg 版脚本 reload → `hides a global script class`。修正前 WorldState 加载失败、`_ready()` 从未执行，冲突休眠；属**修正成功后暴露的既有跨工位缺陷**，不是 Rank-1 本轮脚本缺陷、不是 `save_system.gd` / chunk 占位件引起。

Rank-2 文件自身第 14-17 行注释已写明「落完整工程时 2 号**不重复挂载本文件**，以免 `class_name SpawnRequest` 重复注册……【落工程路径】`res://data/schemas/spawn_request.gd`」。

按「可写范围」`scripts/combat` / `scripts/rpg` 均不在 Rank-1 可写范围、契约 §1/§7 冲突由主 AI 裁决，本轮**未改任何跨工位文件、未用占位件掩盖真实实现**，只登记并给出裁决建议（保留 3 号权威件、由 2 号移除/改名/迁走其对照件）；裁决后回归门禁预期这 4 行消失 → `ERROR=0`。

### 2.7 WARNING 说明

9 条 `scene_missing` 已清零；剩 1 条 `WARNING: 2 ObjectDB instances were leaked at exit`（`final_all.log:183`），**WARNING 级、非 ERROR、不改退出码（G3 EXIT=0）**。与 `ObjectDB-leak-定位与消除-R5.md` 一致：ChunkManager 在途 `load_threaded_request` 遇 `--headless --quit` 立即退出时的 `RefCounted` 残留；R7 因场景缺失、请求未发起故为 0，本轮落位占位场景后按 D1 对照复现。按契约 §10 固定 `--headless --quit`，未擅自换 `--quit-after`、未改 R2 既有件 `chunk_streaming.gd`。

### 2.8 门禁快照时序

门禁期间其它工位（Rank-2/3/4 R7）并行落位：工程根 `.gd` 46 → 49 → **50**（新增可见件含 `scripts/combat/attach_boss_to_courtyard.gd`、`scripts/render/hd2d_placeholder_attach.gd`、`scripts/rpg/r7_wiring_test.gd`）。`final_all.log` 为 50 个 `.gd` 时点最终快照；两次完整三段跑计数一致。

---

## ③ 未完成项与阻塞

1. **【最高优先 · 需 HOST 裁决】总目标 `ERROR=0` 未达成**：剩余 4 行 ERROR 为跨工位 `class_name SpawnRequest` 同名全局类冲突（`scripts/combat/` vs `scripts/rpg/`），越出 Rank-1 可写范围。裁决建议见 §2.6 / `GATE-REPORT-R8.md` §4.3；裁决后回归门禁预期清零。**本轮未擅改、未冒充全绿。**
2. **`save_system.gd` 仅为装配占位**：`extends Node` + 空 `_ready`，不实现存档读写（I-1 / 契约 §6 归 Rank-3）。真实实现落位后由 HOST 裁决把 `SaveSystem` autoload 改指向 3 号正式件。
3. **9 个 chunk 场景仅为占位**：各为 1 个 `Node3D` 根节点，无地形 / POI / 脚本；真实 chunk 场景（Rank-3 I-1 / I-6）仍待接入。占位件已消除 9 条 `scene_missing`，`_apply_world_flags` / `_check_density` 因占位无对应方法直接跳过，未产生额外 WARNING。
4. **1 条 leaked WARNING**：R5 已定位根因与消除条件（`--quit-after` / 改 R2 件），受「契约 §10 固定 `--headless --quit`」+「既有件不重做」双重约束，本轮未在交付件层面消除，如实登记。
5. **门禁快照为并行落位时点**：其它工位 R7 仍在落位，`final_all.log` 为 50 个 `.gd` 快照；若后续落位改变同名类状态，需回归门禁。本轮未刺探其它工位进度、只读记录可见路径。
6. **R7 遗留待裁决（延续，未擅改）**：R5 件 `chunk_streaming_r5.gd` 接入正式装配层、运行期帧时间 / p99 / spike 实测（需 F3 HUD + 人工试玩）、`build_courtyard.gd` 场景生成口径差异、R2/R3/R4 遗留 8 项（见 `DONE-R7.md` §③ 第 5~8 项）。
7. **git 收尾**：按契约 §9.1 由主 AI 统一 commit + push，本轮执行 AI 未自行 git。

---

## 附：边界与合规声明

- **实际写入**：`godot\project.godot`（独占，2 行路径 + 注释）、`godot\scripts\world\save_system.gd`（新增）、`godot\scenes\world\chunks\` 9 个 `.tscn`（新增）、`Rank-1\GATE-REPORT-R8.md`、`Rank-1\DONE-R8.md`、`command_center\ai\1\outbox\cmd-20261109-024906-799-A1.json`。
- **回执回收（正常状态，非写入失败）**：回执写入 outbox 后由中枢按既定流程即时消费并回收至 `command_center\dispatcher\receipts\cmd-20261109-024906-799-A1.json` —— `python -m json.tool` EXIT=0、字段 `task_id` / `ai=1` / `status=done` 正确、`result` 引用本文件实际结论且如实标注 `ERROR=0` 未达成；`ai\1\status.json` 同步转 `idle` / `completed=13`（03:06:09）。outbox 消费后为空属正常状态，与 R2~R7 一致，**非漏交**。
- **未写入**：Rank-2/3/4 子目录（`scripts/combat`、`scripts/rpg`、`data/combat`、`data/rpg`、`assets/generated`、`assets/audio/voice`）、`00-群聊总线.md` / 总纲 / 契约 / 其它工位文件；未 git commit/push、未调用付费 API / 外部服务、未写探针 / 测量 / preflight 脚本。
- 既有件未重做；`chunk_streaming.gd`、`Main.tscn`、`project_root\` 源件均未改动。
- 引擎产物 `.godot\` 缓存由 G1 `--import` 生成/更新，保留。
- 本报告全部结论来自真跑实际输出（日志路径见 §2 开头），**未伪造输出、未冒充全绿**；`ERROR=0` 未达成已如实登记。
