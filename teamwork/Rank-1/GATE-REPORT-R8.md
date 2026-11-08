# GATE-REPORT-R8.md · Rank-1 R8 全工程门禁前后对照

> 派单：`Rank-1\任务书-R8.md` ｜ 任务单 id：`cmd-20261109-024906-799-A1`
> 授权：`00-群聊总线.md` `MSG-20261109-0249-HOST`（02:49 续派 R8；`project.godot` 仍由 Rank-1 独占、本轮明确授权修正 autoload 注册路径）
> 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe` —— 本轮 `--version` 实测 `4.7.2.stable.official.ed1daf0bf`（EXIT=0）
> 工程根：`<root>` = `F:/Game/aierdengfahuan/godot`
> 日志留存：`C:/Users/62668/AppData/Local/Temp/r1_r8_gate/`（`before_*` / `after_*` / `final_*`）
> 全部计数来自真跑实际输出 grep，**未伪造、未冒充全绿**。完整自检见 `DONE-R8.md` §2。

---

## 1. 门禁命令口径（三段）

| 段 | 实际命令 |
|---|---|
| G1 | `<godot> --headless --path <root> --import` |
| G2 | 对工程根全部 `.gd` 逐个 `<godot> --headless --path <root> --check-only --script res://<f>` |
| G3 | `<godot> --headless --path <root> --quit` |
| 判据 | 合并日志 `grep -c "SCRIPT ERROR"` / `"Parse Error"` / `"ERROR"` / `"WARNING"` / `"leaked"` |

- 修正前基线（before）：跑 G1 + G3 取 ERROR/WARNING 计数（R7 §3 已确认 18 条 ERROR / 9 条 WARNING 全部来自这两段），**未跑 G2**（静态检查段不产生运行时 ERROR）；R7 §3 已记录当时 34 个 `.gd` 全 `--check-only` EXIT=0。
- 修正后：**完整三段跑两次**（after 首次、final 最终稳定快照），两次结果一致。

## 2. 前后对照总表（核心）

| 指标 | 修正前 `before_all.log` | 修正后 `final_all.log`（最终快照） | 变化 |
|---|---|---|---|
| G1 `--import` EXIT | 0 | 0 | — |
| G2 `.gd` 静态检查 | 基线未跑（R7：34 个全 0） | 50 个，49 个 EXIT=0、1 个 EXIT=1 | 见 §6 |
| G3 `--quit` EXIT | 0 | 0 | — |
| `SCRIPT ERROR` 行数 | **0** | **2** | 新增暴露（跨工位，见 §4） |
| `Parse Error` 行数 | 0 | 2 | 新增暴露（跨工位，见 §4） |
| **`ERROR` 行数** | **18** | **4** | **18 → 4（未到 0，如实登记）** |
| `WARNING` 行数 | **9** | **1** | 9 条 `scene_missing` 全清 → 剩 1 条 leaked |
| `leaked` 行数 | 0 | 1 | R5 已定位现象随 chunk 场景落位复现 |

> 计数口径：`grep -c "ERROR"` 会把 `SCRIPT ERROR: ...` 行一并计入（与 R7 同口径）。修正后 4 行 = 2 行 `SCRIPT ERROR: Parse Error:` + 2 行 `ERROR: Failed to load script`，实为 **2 个错误事件**在 G2 与 G3 各出现一次。

---

## 3. 修正前 18 条 ERROR（全部消除）

`before_all.log` 逐字 18 行，全部指向 3 个 autoload 注册路径不存在：

- G1 9 行（第 8/10/12、14/16/18、20/22/24 行）：`world_state.gd` / `game_events.gd` / `save_system.gd` 各 3 行 ——
  `ERROR: Attempt to open script 'res://scripts/world/world_state.gd' resulted in error 'File not found'.`、
  `ERROR: Failed loading resource: res://...`、
  `ERROR: Failed to create an autoload, can't load from UID or path: res://...`
- G3 9 行（第 42/44/46、48/50/52、54/56/58 行）：同 3 个脚本各 3 行 ——
  `ERROR: Attempt to open script ... 'File not found'.`、`ERROR: Failed loading resource: ...`、
  `ERROR: Failed to instantiate an autoload, can't load from path: ...`

根因（R7 `ASSEMBLY-REPORT.md` §2 已定位）：`project.godot` 把 WorldState / GameEvents / SaveSystem 注册在 `scripts/world|core/`，而 Rank-3 实际落在 `scripts/rpg/`，且 `save_system.gd` 全工程根缺失。

**修正后这 18 行全部消失**（`final_all.log` 中 0 条 autoload 相关 ERROR）。

---

## 4. 修正后 4 行 ERROR（新增暴露 · 跨工位 · 未冒充全绿）

`final_all.log` 逐字 4 行：

```
143:SCRIPT ERROR: Parse Error: Class "SpawnRequest" hides a global script class.
145:ERROR: Failed to load script "res://scripts/rpg/spawn_request.gd" with error "Parse error".
173:SCRIPT ERROR: Parse Error: Class "SpawnRequest" hides a global script class.
178:ERROR: Failed to load script "res://scripts/rpg/spawn_request.gd" with error "Parse error".
```

G3 完整 backtrace（实际输出，`final_g3.log`）：

```
SCRIPT ERROR: Parse Error: Class "SpawnRequest" hides a global script class.
   at: GDScript::reload (res://scripts/rpg/spawn_request.gd:2)
   GDScript backtrace (most recent call first):
       [0] _register_baseline (res://scripts/rpg/world_state.gd:110)
       [1] _ready (res://scripts/rpg/world_state.gd:35)
ERROR: Failed to load script "res://scripts/rpg/spawn_request.gd" with error "Parse error".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _register_baseline (res://scripts/rpg/world_state.gd:110)
       [1] _ready (res://scripts/rpg/world_state.gd:35)
```

### 4.1 根因（只读定位，未改任何跨工位文件）

`grep "class_name SpawnRequest"` 命中 **2 处**：

- `godot/scripts/combat/spawn_request.gd:2`（Rank-2）
- `godot/scripts/rpg/spawn_request.gd:2`（Rank-3，I-3 权威定义）

两个脚本都声明 `class_name SpawnRequest`，全局类名冲突。修正 autoload 后 WorldState 首次成功实例化，`_ready()` → `_register_baseline()`（`world_state.gd:110`）加载 `res://data/rpg/spawn_bellvault_elite_01.tres` 触发 `scripts/rpg/spawn_request.gd` reload，于是报 `hides a global script class`。

**修正前为何没有这 4 行**：WorldState autoload 加载失败 → `_ready()` 从未执行 → 从不加载 `.tres` → 冲突处于休眠。属**修正成功后暴露的既有跨工位缺陷**，不是 Rank-1 本轮脚本缺陷、不是 `save_system.gd` / chunk 占位件引起。

Rank-2 文件自身第 14-17 行注释已写明：「落完整工程时 2 号**不重复挂载本文件**，以免 `class_name SpawnRequest` 重复注册；本文件只在 2 号独立临时工程内用于字段对齐与真跑核对……【落工程路径】`res://data/schemas/spawn_request.gd`（2 号对照件；与 3 号实现分离）」。即 Rank-2 已自述该件不应落在统一工程根 `scripts/combat/`。

### 4.2 为何本轮未自行消除

按任务书与契约 §1 / §7 / 用户本轮「可写范围」：`scripts/combat/`（Rank-2）、`scripts/rpg/`（Rank-3）**均不在 Rank-1 可写范围**，冲突需由 HOST 裁决由哪一方改名 / 迁走。按用户「若仍有跨工位 ERROR，如实登记、不冒充全绿、不伪造输出」，本轮只登记，**未改任何跨工位文件、未用占位件掩盖真实实现**。

### 4.3 裁决建议（只登记，不擅改）

保留 `scripts/rpg/spawn_request.gd`（I-3 权威定义，Rank-2 注释亦认 3 号权威）；由 Rank-2 把 `scripts/combat/spawn_request.gd` 移除 / 去掉 `class_name` / 迁到其自述的 `res://data/schemas/`。裁决后回归三段门禁，预期这 4 行消失 → `ERROR=0`。

---

## 5. WARNING 前后对照

| 类 | 修正前 | 修正后 | 说明 |
|---|---|---|---|
| `scene_missing`（9 条） | 9 | **0** | 落位 9 个 `chunk_limgrave_<x>_<y>.tscn` 占位场景后全清 |
| `ObjectDB instances leaked` | 0 | **1** | `WARNING: 2 ObjectDB instances were leaked at exit` |

9 条 `scene_missing` 原为 `[ChunkManager] chunk_limgrave_-1_-1 ~ 1_1 加载跳过：scene_missing`（`before_all.log` 第 60/67/74/81/88/95/102/109/116 行），根因 `res://scenes/world/chunks/` 无真实 chunk 场景（R7 §3.2）。

leaked 为 **WARNING 级、非 `ERROR`、非 `SCRIPT ERROR`、不改退出码（final G3 EXIT=0）**，与 `ObjectDB-leak-定位与消除-R5.md` 结论一致：ChunkManager 在途 `load_threaded_request` 遇 `--headless --quit` 立即退出时的 `RefCounted` 残留；R7 因 chunk 场景缺失、请求未发起故为 0，本轮落位占位场景后按 D1 对照复现。按契约 §10 门禁第三段固定 `--headless --quit`，**未擅自换成 `--quit-after`**、未改 R2 既有件 `chunk_streaming.gd`。

---

## 6. G2 全量 `.gd` 静态检查对照

| 时点 | `.gd` 总数 | EXIT=0 | EXIT=1 |
|---|---|---|---|
| R7（`ASSEMBLY-REPORT.md` §3） | 34（主跑 33 + 补跑 1） | 34 | 0 |
| R8 after 首次 | 49 | 48 | 1（`res://scripts/rpg/spawn_request.gd`） |
| R8 final 最终快照 | **50** | **49** | **1**（同上，同一冲突） |

唯一失败件 `res://scripts/rpg/spawn_request.gd` 的 `--check-only` 实际输出（`after_g2_41.log` / `final_g2_42.log`）：

```
SCRIPT ERROR: Parse Error: Class "SpawnRequest" hides a global script class.
   at: GDScript::reload (res://scripts/rpg/spawn_request.gd:2)
ERROR: Failed to load script "res://scripts/rpg/spawn_request.gd" with error "Parse error".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
```

与 §4 同一根因（跨工位同名全局类），非语法错误、非 Rank-1 交付件。

---

## 7. 门禁快照时序（诚实标注）

本轮门禁期间其它工位（Rank-2/3/4 R7）**并行落位**：工程根 `.gd` 由开工核对时的 46 → after 跑时 49 → final 跑时 **50**；新增可见件含 `scripts/combat/attach_boss_to_courtyard.gd`、`scripts/render/hd2d_placeholder_attach.gd`、`scripts/rpg/r7_wiring_test.gd`。after 与 final 两次完整三段跑的 ERROR/WARNING 计数**完全一致**（4 / 1），结论稳定。`final_all.log` 为 50 个 `.gd` 时点的最终快照。

---

## 8. 达标判定（不冒充全绿）

- ✅ 本轮直接目标「18 条 autoload ERROR 清零」：**达成**（18 → 0）。
- ✅ 本轮直接目标「9 条 `scene_missing` WARNING 清零」：**达成**（9 → 0）。
- ✅ 三段 EXIT（G1 / G3）全 0；G2 50 个 `.gd` 中 49 个 EXIT=0。
- ❌ 总目标 `ERROR=0`：**未达成**。`final_all.log` 仍有 4 行 ERROR（§4 跨工位 `SpawnRequest` 同名全局类冲突），按用户口径如实登记、待 HOST 裁决，**不冒充全绿、不伪造输出**。

---

## 边界声明

- 本轮只写 `godot\project.godot`（独占）、`godot\scripts\world\save_system.gd`、`godot\scenes\world\chunks\` 9 件，以及本工位两份报告与 outbox 回执；未写 Rank-2/3/4 子目录、总线 / 总纲 / 契约、其它工位文件。
- 未自行 git commit/push、未调用付费 API / 外部服务、未写探针 / 测量脚本；既有件未重做；中文 UTF-8；Godot 4 合法语法。
- 引擎产物 `.godot\` 缓存由 G1 `--import` 生成/更新，保留。
