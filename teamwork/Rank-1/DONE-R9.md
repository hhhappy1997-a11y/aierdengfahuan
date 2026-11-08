# DONE-R9.md · Rank-1（引擎架构与渲染）· R9 完成标志

> 轮次：R9「全工程 ERROR 归零回归 + HD-2D 占位画面接入」
> 任务单 id：`cmd-20261109-030933-289-A1`（派单 `Rank-1\任务书-R9.md` / `调度任务单-latest.json`）
> 授权：`MSG-20261109-0309-HOST`（03:09 裁决 I-3 权威件 `scripts/rpg/spawn_request.gd`、由 Rank-2 移除重复 `class_name`，并续派 R9）
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（`--version` 实测 `4.7.2.stable.official.ed1daf0bf`，EXIT=0）
> 完成标志：本文件 + `GATE-FINAL.md` + `command_center\ai\1\outbox\` 回执 JSON
> 本文件全部结论来自真跑实际输出，**未伪造、未冒充全绿**；总目标 `ERROR=0` **已达成**（18 → 4 → 0），见 §2.5 / `GATE-FINAL.md`。

---

## ① 实际交付清单

| # | 交付件 | 落位 | 说明 |
|---|---|---|---|
| 1 | 全量三段门禁复跑 ×2 | 日志 `g1/g2_all/g3/all.log`、`final_*` | G1 → G2（51 个 `.gd`）→ G3，ROUND1 与 FINAL 两次结果一致 |
| 2 | `ERROR=0` 验收 | `GATE-FINAL.md` | `SCRIPT ERROR=0 / Parse Error=0 / ERROR 行数=0`；18→4→0 链路与归因 |
| 3 | HD-2D 追加式接入构建脚本 | `godot\scripts\render\attach_hd2d_placeholder.gd`（新增） | `extends SceneTree`；一行调用 `HD2D_ATTACH.attach(root, {...})`；节点保留校验 + pack/save |
| 4 | 画面接入落位 | `godot\scenes\courtyard.tscn` | 20 → 22 节点，既有 20 节点逐字保留，新增 2 节点 + 1 条 `ext_resource` |
| 5 | 接入点记录 | 脚本真跑输出 + 本文档 §2.3 | `root=Courtyard → HD2DPlaceholderLayer(layer=-10) → HD2DPlaceholder(integer_scale=2)` |
| 6 | save 归属复核结论登记 | 本文档 §2.6 | 只读复核 `save_system.gd` / `save_delta_writer.gd`，**只登记不越界改** |
| 7 | `GATE-FINAL.md` | 本工位 | 最终门禁计数与工程可运行状态结论 |
| 8 | `DONE-R9.md` | 本工位 | 本文件（完成标志） |
| 9 | 回执 JSON | `command_center\ai\1\outbox\` | 按任务单 id `cmd-20261109-030933-289-A1` 写 `status: done`，`result` 引用本文件实际结论 |

### 改动文件逐件清单

| 文件 | 动作 | 内容 |
|---|---|---|
| `godot\scripts\render\attach_hd2d_placeholder.gd` | 新增 | 追加式接入构建脚本：`preload` 常量 + 一行 `attach()`；`load` 既有场景 → `instantiate` → 追加 2 节点 → 设 `owner` → 既有节点路径/类型校验 → `pack` → `instantiate` 复核 → `ResourceSaver.save` |
| `godot\scenes\courtyard.tscn` | 追加式重写 | 既有 20 节点声明 / 属性逐字保留；新增 `[ext_resource]` 指向 `hd2d_placeholder.gd`、`HD2DPlaceholderLayer`(CanvasLayer, `layer=-10`)、`HD2DPlaceholder`(Node2D, `script=hd2d_placeholder.gd`, `integer_scale=2`, `texture_filter=1`)；sha256 `217b2f4a…` → `e37f1c0c…` |
| `teamwork\Rank-1\GATE-FINAL.md` | 新增 | 最终门禁计数与工程可运行状态结论 |
| `teamwork\Rank-1\DONE-R9.md` | 新增 | 本文件 |
| `teamwork\command_center\ai\1\outbox\cmd-20261109-030933-289-A1.json` | 新增 | 回执 |

**未改动**：`godot\project.godot`、`build_courtyard.gd`、`build_main.gd`、`hd2d_placeholder.gd`、`hd2d_placeholder_attach.gd`、`scripts\combat\`、`scripts\rpg\`（含 `save_delta_writer.gd`）、`scripts\world\save_system.gd`、`data\*`、9 个 chunk 占位场景、`Main.tscn`、Rank-2/3/4 子目录、总线 / 总纲 / 契约 / 任务书、`project_root\` 源件。

---

## ② 自检（真跑命令与实际输出结论）

`<godot>` = `D:/Godot/Godot_v4.7.2-stable_win64.exe`；`<root>` = `F:/Game/aierdengfahuan/godot`；日志留存 `C:/Users/62668/AppData/Local/Temp/r1_r9_gate/`。

### 2.1 开工只读核对（一次）

- 必读 6 份开工只读一次：`任务书-R9.md`、`GATE-REPORT-R8.md`、`DONE-R8.md`、`Rank-4\scene_integration.md`、`00-协作契约.md`、`00-群聊总线.md`。
- 引擎 `--version` → `4.7.2.stable.official.ed1daf0bf`，EXIT=0。
- `godot\scripts\combat\spawn_request.gd:2` 开工时**仍有** `class_name SpawnRequest`（Rank-2 并行移除未落位）；`godot\scripts\rpg\spawn_request.gd:2` 为 I-3 权威件。`project.godot` `[autoload]` 5 项；`courtyard.tscn` 20 节点；工程根 50 个 `.gd`。
- `save_system.gd`（Rank-1 装配占位）、`save_delta_writer.gd`（Rank-3 内部节点）读取用于归属复核；`hd2d_placeholder_attach.gd`（Rank-4 交付）读取确认 `attach/find_placeholder/detach` API。

### 2.2 HD-2D 接入脚本语法门禁 + 真跑（实际输出）

| 步 | 命令 / 日志 | 实际输出结论 |
|---|---|---|
| 备份 | `courtyard_before.tscn` | sha256 `217b2f4ade3ba21b9166ba9b3fd368d0d7726f1c4756977ebb524d0c99fb6d34`，`[node` 段落数 = 20 |
| 语法门禁 | `attach_checkonly.log` | `CHECK_ONLY_EXIT=0`；`SCRIPT_ERROR=0 ERROR=0 Parse=0`；输出仅 Godot 版本横幅 |
| 前置导入 | `pre_import.log` | `PRE_IMPORT_EXIT=0`；`SCRIPT_ERROR=0 ERROR=0 WARNING=0` |
| 真跑接入 | `attach_run.log` | `ATTACH_RUN_EXIT=0`，逐字输出见下 |

`attach_run.log` 关键输出（逐字）：

```text
[R9-HD2D] ATTACH_OK scene=res://scenes/courtyard.tscn before_nodes=20 after_nodes=22 preserved_existing=true
[R9-HD2D] ATTACH_POINT root=Courtyard -> HD2DPlaceholderLayer(CanvasLayer,layer=-10) -> HD2DPlaceholder(Node2D,script=hd2d_placeholder.gd,integer_scale=2)
```

该时点另含 `SCRIPT_ERROR=1 ERROR=2 WARNING=2`（`SpawnRequest` 冲突 + `[ChunkManager] 未找到 ChunkRoot` + `leaked`），属并行时序，见 §2.4。

接入结果核验（真跑）：

```text
before=20 after=22
EXISTING_20_NODE_DECLARATIONS_IDENTICAL=true
既有正文（剔除新增 ext_resource 行与新增 2 节点段）diff：仅 119a120 多 1 个尾部空行
新增节点：[node name="HD2DPlaceholderLayer" type="CanvasLayer" parent="." unique_id=1016476096] (layer=-10)
          [node name="HD2DPlaceholder" type="Node2D" parent="HD2DPlaceholderLayer" unique_id=735159753] (integer_scale=2)
新增资源：[ext_resource type="Script" path="res://scripts/render/hd2d_placeholder.gd" id="2_w844m"]
sha256 217b2f4a… -> e37f1c0c…
```

结论：既有 20 节点声明（含 `unique_id`）逐字一致、属性 / 层级未变；仅追加 2 节点 + 1 条资源引用 + 1 个尾部空行，**未破坏既有 20 节点**。

### 2.3 接入点（一行调用 + 落位）

按 `Rank-4\scene_integration.md` §2.1 主推写法，在新增脚本中：

```gdscript
const HD2D_ATTACH = preload("res://scripts/render/hd2d_placeholder_attach.gd")
# _initialize() 内、既有 root 由 PackedScene.instantiate() 取回之后追加一行：
var bg: Node2D = HD2D_ATTACH.attach(root, {"canvas_layer": -10, "integer_scale": 2})
```

- **接入点**：`root`(Courtyard) → `HD2DPlaceholderLayer`(CanvasLayer, `layer=-10`) → `HD2DPlaceholder`(Node2D, `script=hd2d_placeholder.gd`, `integer_scale=2`, `texture_filter=1`)。
- **追加语义**：脚本 `load` 既有 `courtyard.tscn` → `instantiate` → 仅追加 2 节点 → 补设 `owner` → 校验既有节点 → `pack` → `instantiate` 复核 → `ResourceSaver.save` 写回；**不重做 `build_courtyard.gd`、不覆盖既有节点、不动 `project.godot`**。
- 幂等由 Rank-4 `attach()` 自身保证；`attach()` 不设 `owner` 的契约由本脚本补设（§2.4 边界一致）。
- 遮挡层序 / `integer_scale` 无法设 1 等 4 项按 `scene_integration.md` §4 **只登记、不擅改**；本轮**不宣称「已渲染可见」**、未做窗口渲染 / 人工试玩验收。

### 2.4 并行时序如实登记（不冒充全程无冲突）

| 时点 | 日志 | 实际计数 | 说明 |
|---|---|---|---|
| 接入前置 `--import` | `pre_import.log` | `SCRIPT_ERROR=0 ERROR=0 WARNING=0` | `--import` 不实例化 autoload 运行时，冲突未暴露 |
| 接入脚本真跑 `--script` | `attach_run.log` | `SCRIPT_ERROR=1 ERROR=2 WARNING=2` | 自定义 MainLoop 会实例化 autoload；该时点 Rank-2 移除**尚未落位**，逐字为 `Class "SpawnRequest" hides a global script class.` + `Failed to load script "res://scripts/rpg/spawn_request.gd" with error "Parse error".` + `[ChunkManager] 未找到 ChunkRoot` + `leaked`。脚本 `ATTACH_RUN_EXIT=0` 且 `ATTACH_OK`，冲突非接入脚本缺陷 |
| 正式 ROUND1 三段 | `all.log` | `ERROR=0` | 复核时 `combat/spawn_request.gd` 第 2 行已改为裁决注释、无 `class_name` 代码声明；移除已落位 |
| 正式 FINAL 三段 | `final_all.log` | `ERROR=0` | 与 ROUND1 一致，结论稳定 |

> 按用户「若并行时序导致首轮仍有冲突，如实登记并说明，不冒充全绿」：本轮**正式门禁首轮即 `ERROR=0`**，但仍如实保留并说明上述 `--script` 时点的冲突，不抹去、不伪造输出、不把前置时点算进最终门禁计数。

### 2.5 三段门禁真跑 ×2 与 ERROR 计数前后对比（核心）

`<godot> --headless --path <root> --import` → 全部 `.gd` 逐个 `--check-only --script` → `--headless --quit`：

| 段 | ROUND1 | FINAL |
|---|---|---|
| G1 EXIT | 0 | 0 |
| G2 | `G2_TOTAL=51 G2_FAIL=0` | `FINAL_G2_TOTAL=51 FINAL_G2_FAIL=0` |
| G3 EXIT | 0 | 0 |
| `SCRIPT ERROR` | 0 | 0 |
| `Parse Error` | 0 | 0 |
| **`ERROR` 行数** | **0** | **0** |
| `WARNING` 行数 | 1（leaked） | 1（leaked） |

合并日志 `ERROR` 实际行：**(none)**；唯一 WARNING：`121:WARNING: 2 ObjectDB instances were leaked at exit`。两段对照 `ROUND1: 0 ERROR / 1 WARNING`、`FINAL : 0 ERROR / 1 WARNING`；最终 `.gd` 计数 51。

| 判据 | R8 修正前 | R8 最终 | R9 ROUND1 | R9 FINAL |
|---|---|---|---|---|
| `SCRIPT ERROR` | 0 | 2 | **0** | **0** |
| `Parse Error` | 0 | 2 | **0** | **0** |
| **`ERROR` 行数** | **18** | **4** | **0** | **0** |
| `WARNING` 行数 | 9 | 1 | 1 | 1 |
| G1 / G3 EXIT | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| G2 `.gd` | 基线未跑 | 50 个，49+1 FAIL | 51 全 0 | 51 全 0 |

- ✅ **总目标 `ERROR=0` 达成**：链路 R7 18 → R8 4 → R9 0，两次完整三段结果一致。
- 归零归因（§4 / `GATE-FINAL.md` §4）：Rank-2 依 `MSG-20261109-0309-HOST` 裁决移除 `scripts/combat/spawn_request.gd` 的重复 `class_name`，I-3 权威件 `scripts/rpg/spawn_request.gd` 保留；全局类唯一后 `WorldState._register_baseline()` 加载 `.tres` 不再报 `hides a global script class`。**本工位未改任何跨工位文件**。

### 2.6 `save_system.gd` 与 Rank-3 `save_delta_writer.gd` 归属复核（只登记，不越界改）

| 件 | 工位 / 落位 | 实际内容 | 归属结论 |
|---|---|---|---|
| `godot\scripts\world\save_system.gd` | Rank-1 可写 `scripts\world\` | `extends Node` + 空 `func _ready(): pass`；R8 装配占位。文件头写明「让 5 个 autoload 全部指向实际存在的脚本」，**不实现任何存档功能** | 装配层闭合件，**非存档实现**；存档（SaveDelta 持久化、delta.json 原子写、schema 迁移、单槽回放）按契约 I-1 / §6 归 **Rank-3**。注册于 `project.godot:45` `[autoload] SaveSystem="*res://scripts/world/save_system.gd"` |
| `godot\scripts\rpg\save_delta_writer.gd` | Rank-3 所有 `scripts\rpg\` | `extends Node`；注释「3 号内部节点」「对外（1/2 号）不暴露任何方法」。订阅 `GameEvents.enemy_defeated` / `boss_defeated`（I-2），击杀 flag 只由本节点写；`mark_flag_changed()` / `commit(reason)` / `_commit()` 经 `WorldState._commit_delta(reason)` 落盘；0.5 s 合并窗口 | Rank-3 **真实存档写入逻辑**；**不是 autoload**（`project.godot [autoload]` 无此项） |

**复核结论**：两件职责 / 工位 / 落位路径互不相同，**不存在同名冲突或重复定义**。`SaveSystem` autoload 当前指向 Rank-1 装配占位；真实存档能力由 Rank-3 的 `world_state.gd` + `save_delta_writer.gd` 提供，尚未合并 / 替换。文件头与 `DONE-R8.md` ③ 第 2 项已写明「真实实现由 Rank-3 落位后，由 HOST 裁决把本 autoload 改指向 3 号正式件」——该指向变更属 **HOST 裁决**，本轮按任务书「只登记不越界改」**未改 `save_system.gd`、未改 `scripts/rpg/` 任何件、未改 `project.godot` autoload**。

### 2.7 WARNING 说明

唯一 WARNING 为 `2 ObjectDB instances were leaked at exit`，与 `ObjectDB-leak-定位与消除-R5.md` / `GATE-REPORT-R8.md` §5 一致：ChunkManager 在途 `load_threaded_request` 遇 `--headless --quit` 立即退出时的 `RefCounted` 残留。**WARNING 级、非 ERROR、不改退出码（G3 EXIT=0）**；按契约 §10 固定 `--headless --quit`，未擅自换 `--quit-after`、未改 R2 既有件 `chunk_streaming.gd`；本轮不宣称 WARNING 清零。

---

## ③ 未完成项与阻塞

1. **1 条 leaked WARNING**：R5 已定位根因与消除条件，受「契约 §10 固定 `--headless --quit`」+「既有件不重做」双重约束，本轮未在交付件层面消除，如实登记。属 WARNING 级，不影响 `ERROR=0` 结论。
2. **`save_system.gd` 仍为装配占位**：`extends Node` + 空 `_ready`，不实现存档读写（I-1 / 契约 §6 归 Rank-3）。真实实现落位后是否把 `SaveSystem` autoload 改指向 3 号正式件，需 **HOST 裁决**（延续 `DONE-R8.md` ③ 第 2 项）；本轮只登记、未擅改。
3. **9 个 chunk 场景仍为占位**（延续 `DONE-R8.md` ③ 第 3 项）：各 1 个 `Node3D` 根节点，无地形 / POI / 脚本；真实 chunk 场景待接入。
4. **HD-2D 占位仅 M0 构图 / 显存不足降级**：Rank-4 出图仍无 PNG、ComfyUI 本机路径未登记（R7/R8 阻塞延续）；本轮**不宣称已能出图、未拉第二个 GPU job、未臆造 ComfyUI 路径**。占位实际遮挡层序 / 可见性按 `scene_integration.md` §4 登记为 Rank-1 裁决点，未做窗口渲染 / 人工试玩验收，**不宣称「已渲染可见」**。
5. **门禁快照为并行落位时点**：其它工位 R8 仍可能继续落位；若后续改变同名类 / autoload / 资源引用状态，需回归门禁。本轮未刺探其它工位进度，仅按任务前置条件对 `combat/spawn_request.gd` 做只读核对。
6. **R7 遗留待裁决（延续 `DONE-R8.md` ③ 第 6 项）**：`chunk_streaming_r5.gd` 接入正式装配层、运行期帧时间 / p99 / spike 实测（需 F3 HUD + 人工试玩）、`build_courtyard.gd` 场景生成口径差异、R2/R3/R4 遗留待裁决项，均只登记不擅改。
7. **git 收尾**：按契约 §9.1 由主 AI 统一 commit + push，本轮执行 AI 未自行 git。

---

## 附：边界与合规声明

- **实际写入**：`godot\scripts\render\attach_hd2d_placeholder.gd`（新增）、`godot\scenes\courtyard.tscn`（追加式重写）、`Rank-1\GATE-FINAL.md`、`Rank-1\DONE-R9.md`、`command_center\ai\1\outbox\cmd-20261109-030933-289-A1.json`。
- **未写入**：`godot\project.godot`（独占件本轮未改）、Rank-2/3/4 子目录（`scripts/combat`、`scripts/rpg`、`data/combat`、`data/rpg`、`assets/generated`、`assets/audio/voice`）、总线 / 总纲 / 契约 / 任务书 / 其它工位文件；未 `git commit` / `git push`、未调用付费 API / 外部服务、未写探针 / 测量 / preflight 脚本。
- 既有件（`build_courtyard.gd`、`hd2d_placeholder.gd`、`hd2d_placeholder_attach.gd`、`save_system.gd`、`save_delta_writer.gd`、9 个 chunk 占位场景、`Main.tscn`、`project_root\` 源件）一律**引用、不重做、除 `courtyard.tscn` 追加式重写外一个字节未改**。
- 零付费 / 零外部依赖；默认不刺探（只读核对任务明确的前置条件与自身交付件）；中文 UTF-8；所有 GDScript 为 Godot 4 合法语法（`--check-only` 通过）。
- 引擎产物 `.godot\` 缓存由 G1 `--import` 生成/更新，保留。
- 本文件全部结论来自真跑实际输出（日志路径见 §2 开头），**未伪造输出、未冒充全绿**；并行时序冲突已如实登记；`ERROR=0` 已达成但 1 条 leaked WARNING 与出图 / 渲染可见性阻塞仍如实登记。
