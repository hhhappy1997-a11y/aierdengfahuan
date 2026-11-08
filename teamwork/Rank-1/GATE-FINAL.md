# GATE-FINAL.md · Rank-1 R9 最终门禁计数与工程可运行状态结论

> 轮次：R9「全工程 ERROR 归零回归 + HD-2D 占位画面接入」
> 任务单 id：`cmd-20261109-030933-289-A1`（派单 `Rank-1\任务书-R9.md` / `调度任务单-latest.json`）
> 授权：`00-群聊总线.md` `MSG-20261109-0309-HOST`（03:09 裁决 I-3 权威件 `scripts/rpg/spawn_request.gd`、由 Rank-2 移除重复 `class_name`，并续派 R9）
> 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe` —— 本轮 `--version` 实测 `4.7.2.stable.official.ed1daf0bf`（EXIT=0）
> 工程根：`<root>` = `F:/Game/aierdengfahuan/godot`
> 日志留存：`C:/Users/62668/AppData/Local/Temp/r1_r9_gate/`（`pre_import.log` / `attach_checkonly.log` / `attach_run.log` / `g1.log` / `g2_all.log` / `g3.log` / `all.log` / `final_*`）
> 全部计数来自真跑实际输出 grep，**未伪造、未冒充全绿**；完整自检见 `DONE-R9.md` §2。

---

## 1. 门禁命令口径（三段，与 R7/R8 同口径）

| 段 | 实际命令 |
|---|---|
| G1 | `<godot> --headless --path <root> --import` |
| G2 | 对工程根全部 `.gd` 逐个 `<godot> --headless --path <root> --check-only --script res://<f>` |
| G3 | `<godot> --headless --path <root> --quit` |
| 判据 | 合并日志 `grep -c "SCRIPT ERROR"` / `"Parse Error"` / `"ERROR"` / `"WARNING"` / `"leaked"` |

- 本轮**完整三段复跑两次**（ROUND1 首次、FINAL 最终稳定快照），两次结果一致。
- 计数口径：`grep -c "ERROR"` 会把 `SCRIPT ERROR: ...` 行一并计入（与 GATE-REPORT-R8.md §2 同口径）；本轮两类均为 0，无计入差异。

## 2. 最终门禁逐段实际输出

| 段 | ROUND1（`all.log`） | FINAL（`final_all.log`） |
|---|---|---|
| G1 `--import` EXIT | 0 | 0 |
| G2 全量 `.gd` | `G2_TOTAL=51 G2_FAIL=0` | `FINAL_G2_TOTAL=51 FINAL_G2_FAIL=0` |
| G3 `--quit` EXIT | 0 | 0 |

合并日志 grep 实际计数（逐字）：

```text
=== ROUND1 all.log ===
SCRIPT ERROR: 0
Parse Error: 0
ERROR lines: 0
WARNING lines: 1
leaked lines: 1
=== FINAL final_all.log ===
SCRIPT ERROR: 0
Parse Error: 0
ERROR lines: 0
WARNING lines: 1
leaked lines: 1
```

- `ERROR` 实际行：**(none)**（两次均无）。
- `WARNING` 实际行（两次均为同一行）：
  `121:WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).`
- `G2_FAIL_LIST=<none>`（51 个 `.gd` 全部 EXIT=0，含本轮新增 `scripts/render/attach_hd2d_placeholder.gd`）。

## 3. ERROR 计数前后对照（核心）

| 判据 | R8 修正前 `before_all.log` | R8 最终 `final_all.log` | R9 ROUND1 `all.log` | R9 FINAL `final_all.log` |
|---|---|---|---|---|
| `SCRIPT ERROR` | 0 | 2 | **0** | **0** |
| `Parse Error` | 0 | 2 | **0** | **0** |
| **`ERROR` 行数** | **18** | **4** | **0** | **0** |
| `WARNING` 行数 | 9 | 1 | 1 | 1 |
| `leaked` | 0 | 1 | 1 | 1 |
| G1 / G3 EXIT | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| G2 `.gd` | 基线未跑（R7：34 全 0） | 50 个，49 EXIT=0 + 1 FAIL | 51 个全 EXIT=0 | 51 个全 EXIT=0 |

链路：**R7 18 → R8 4 → R9 0**。
R8 已把 18 条 autoload ERROR 清零并暴露 4 行跨工位 `class_name SpawnRequest` 同名全局类冲突；本轮 Rank-2 依裁决移除重复注册后，4 行归零 → `ERROR=0` 达成。

## 4. ERROR 归零归因（只读核对，未改任何跨工位文件）

- 开工只读核对：`godot/scripts/combat/spawn_request.gd:2` **仍有** `class_name SpawnRequest`（Rank-2 并行移除尚未落位）；`godot/scripts/rpg/spawn_request.gd:2` 为 I-3 权威定义。
- 接入脚本真跑后复核：combat 版第 2 行已改为裁决注释 `## [R8 裁决 · MSG-20261109-0309-HOST] 去除重复的 class_name SpawnRequest 全局类注册。`，全文已无 `class_name` 代码声明；rpg 版 `class_name SpawnRequest` 保留。工程根 `.gd` 由 50 → **51**（+1 为本轮新增接入脚本，Rank-2 未增删 `.gd`）。
- 归零直接原因：全局类只剩唯一 `SpawnRequest` → `WorldState._ready()` → `_register_baseline()`（`world_state.gd:110`）加载 `res://data/rpg/spawn_bellvault_elite_01.tres` 不再触发 `hides a global script class`；G2 唯一失败件消失、G3 无 `Failed to load script`。
- **本工位未改** `scripts/combat/`、`scripts/rpg/`、任何 `.tres`；冲突消除由 Rank-2 在自身工位完成，R9 只做门禁回归验收。

## 5. 并行时序如实登记（不冒充全程无冲突）

| 时点 | 日志 | 实际计数 | 说明 |
|---|---|---|---|
| 接入前置 `--import` | `pre_import.log` | `SCRIPT_ERROR=0 ERROR=0 WARNING=0` | `--import` 不实例化 autoload 运行时，冲突未暴露 |
| 接入脚本真跑 `--script` | `attach_run.log` | `SCRIPT_ERROR=1 ERROR=2 WARNING=2` | 自定义 MainLoop 会实例化 autoload；该时点 Rank-2 移除**尚未落位**，逐字为 `Class "SpawnRequest" hides a global script class.` + `Failed to load script "res://scripts/rpg/spawn_request.gd"` + `[ChunkManager] 未找到 ChunkRoot` + `leaked`。脚本本身 `ATTACH_RUN_EXIT=0` 且 `ATTACH_OK`，冲突非接入脚本缺陷 |
| 正式 ROUND1 三段 | `all.log` | `ERROR=0` | Rank-2 移除已落位 |
| 正式 FINAL 三段 | `final_all.log` | `ERROR=0` | 与 ROUND1 一致，结论稳定 |

> 按用户「若并行时序导致首轮仍有冲突，如实登记并说明，不冒充全绿」：本轮**正式门禁首轮即 0**，但仍如实保留并说明上述 `--script` 时点的冲突，不抹去、不伪造输出、不把前置时点算进最终门禁计数。

## 6. WARNING 说明（1 条，非 ERROR）

- 唯一 WARNING：`WARNING: 2 ObjectDB instances were leaked at exit`。与 `ObjectDB-leak-定位与消除-R5.md` / `GATE-REPORT-R8.md` §5 结论一致：ChunkManager 在途 `load_threaded_request` 遇 `--headless --quit` 立即退出时的 `RefCounted` 残留。
- **WARNING 级、非 `ERROR`、非 `SCRIPT ERROR`、不改退出码（G3 EXIT=0）**。按契约 §10 固定 `--headless --quit`，未擅自换 `--quit-after`、未改 R2 既有件 `chunk_streaming.gd`。本轮**不宣称 WARNING 清零**。

## 7. 工程可运行状态结论

- **G1 `--import` EXIT=0**：全工程资源扫描 / 脚本类注册无 ERROR；含本轮新增 `attach_hd2d_placeholder.gd` 与重写后的 `courtyard.tscn`（22 节点）。
- **G2 51 个 `.gd` 全 `--check-only --script` EXIT=0**：全工程 GDScript 静态解析零错误。
- **G3 `--quit` EXIT=0**：主场景 `Main.tscn` + 5 个 autoload 完整启动并正常退出，无 `ERROR` / `SCRIPT ERROR`。
- **画面接入**：`courtyard.tscn` 20 → 22 节点，既有 20 节点声明逐字一致（`EXISTING_20_NODE_DECLARATIONS_IDENTICAL=true`），新增层 / 节点经 `pack` → `instantiate` 往返复核（`probe_count=22`、`preserved_existing=true`）。
- **结论**：工程根 `F:/Game/aierdengfahuan/godot` 在 Godot 4.7.2 下**可导入、可静态检查、可启动退出，`ERROR=0`，处于可运行状态**。
- **边界**：以上均为 `--headless` 门禁结论；**未做窗口渲染 / 人工试玩 / 画面可见性验收**。HD-2D 占位实际遮挡层序按 `Rank-4\scene_integration.md` §4 登记为 Rank-1 裁决点，本轮**不宣称「已渲染可见」**、**不宣称「已能出图」**。

## 8. 达标判定

- ✅ **总目标 `ERROR=0`：达成**（ROUND1 / FINAL 两次一致，`SCRIPT ERROR=0` / `ERROR 行数=0`）。
- ✅ 全量三段门禁复跑：达成（G1/G3 EXIT=0，G2 51/51 EXIT=0）。
- ✅ HD-2D 占位画面接入：达成（一行调用 + 追加式构建脚本，既有 20 节点未破坏）。
- ✅ `save_system.gd` 与 Rank-3 `save_delta_writer.gd` 归属复核：只登记、未越界改。
- ⚠ 1 条 leaked WARNING 仍在（WARNING 级、非 ERROR，R8 已定位，按约束未消除，如实登记）。

---

## 边界声明

- 本轮实际写入：`godot\scripts\render\attach_hd2d_placeholder.gd`（新增）、`godot\scenes\courtyard.tscn`（追加式重写）、`Rank-1\GATE-FINAL.md`、`Rank-1\DONE-R9.md`、`command_center\ai\1\outbox\` 回执。
- 未写：`godot\project.godot`、`build_courtyard.gd`、`build_main.gd`、`hd2d_placeholder.gd`、`hd2d_placeholder_attach.gd`、`scripts\combat\`、`scripts\rpg\`、`scripts\world\save_system.gd`、`data\*`、Rank-2/3/4 子目录、`00-群聊总线.md` / 总纲 / 契约 / 任务书。
- 未自行 `git commit` / `git push`；未调用付费 API / 外部服务；未写探针 / 测量 / preflight 脚本；既有件未重做；中文 UTF-8；GDScript 为 Godot 4 合法语法（`--check-only` 通过）。
- 引擎产物 `.godot\` 缓存由 G1 `--import` 生成/更新，保留。
- 本报告全部结论来自真跑实际输出，**未伪造输出、未冒充全绿**；并行时序冲突已如实登记。
