# DONE-R17.md · Rank-3 交付报告

- 任务：`cmd-20261109-093050-719-A3`，`[ROUND=R17]`，Rank-3 执行 AI，调度中枢派单
- 日期：2026-11-09
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`，实测 `--version` = `4.7.2.stable.official.ed1daf0bf`
- 工程根（`--path`）：`F:/Game/aierdengfahuan/godot`
- 必读（开工只读一次）：`godot/scripts/hud.gd`、`godot/scenes/hud.tscn`、`godot/scripts/rpg/world_state.gd`（I-1 autoload）、`teamwork/00-群聊总线.md` —— 均已读 ✓
- **真跑输出结论（是否降级）：否，未降级。`MODE=AUTOLOAD_OK`，`degraded=false`，`flag_chain_verified=true`，`pass=11 fail=0 ok=true`，四段命令 `EXIT=0`。**

---

## ① 交付清单

| # | 文件 | 动作 | 说明 |
|---|------|------|------|
| 1 | `godot/scripts/verify_hud_binding.gd` | **新建**（278 行） | `extends SceneTree` 验证载体。`CACHE_MODE_IGNORE` 从磁盘实例化 `hud.tscn` → 取 `hud.gd` 实例；实测 `/root/WorldState`；按 autoload/链路连通性如实分 `AUTOLOAD_OK` / `DEGRADED` 两支。工程内唯一写入的脚本。 |
| 2 | `teamwork/Rank-3/DONE-R17.md` | **新建** | 本报告（①交付清单 ②自检含完整实际 stdout ③未完成项与阻塞，明确是否降级）。 |
| 3 | `teamwork/command_center/ai/3/outbox/cmd-20261109-093050-719-A3.json` | **新建 → 被中枢消费归档** | 回执 JSON，按本轮命令 id 署名。写入 `outbox\` 后即由中枢消费，归档至 `teamwork/command_center/dispatcher/receipts/cmd-20261109-093050-719-A3.json`（回读核对：内容逐字一致、JSON 合法）；`outbox\` 为空是正常消费态，**非未写、非丢失**。未重复写第二份回执（并发保护 / 幂等）。 |

**可写范围核对**：仅上述 3 个文件落在允许范围（`Rank-3\`、`godot\scripts\verify_hud_binding.gd`、回执 `outbox\`）。
- 未碰 `courtyard.tscn`、未改 `hud.tscn` 结构：脚本仅 `ResourceLoader.load(...)` + `instantiate()` + `add_child()`，全程无 `pack()` / `save()` / 文件写入；`--import` 只更新 `.godot` 缓存、不改 `.tscn` 字节。
- 未写其它工位、未写总线/总纲/契约、未自行 `git`（本轮未执行任何 git 命令）。
- 零付费（纯本地 Godot）、零外部依赖；默认不刺探（只目的性读取必读件、本工位历史件、工程根 `project.godot` 与 `grace_network.tres`，并只读核验本轮回执归档）；中文 UTF-8；Godot 4.7.2 合法语法（G2 `--check-only` EXIT=0）。
- 回执去向：见 ① 第 3 行；中枢消费归档属预期流程，未重写第二份、未改中枢台账。

### 1.1 脚本设计要点

- **实例化取 `hud.gd` 实例**：② 校验 `get_script().resource_path == "res://scripts/hud.gd"`；③ 校验 `TitleLabel` 可寻址。
- **时序修正**：在 `SceneTree._initialize()` 内 `add_child()` 时 `_ready()` 不同步 flush（见 2.1 首次真跑实证），故挂 `process_frame` 帧状态机 `WAIT_FRAMES=3`，待 `_ready()` 在帧循环执行后再验证 —— ⑦ 实测 `hud_refreshed_count=1`（全量刷新发生）。
- **增量 vs 全量判据**：`hud_refreshed` 仅由 `refresh_all()` emit，`flag_changed` 增量走 `refresh_label()` 不 emit。A1/A2/A3 期间 `hud_refreshed` 计数恒为基线 1 而 TitleLabel 属性变化 ⇒ 证明是**增量刷新**而非全量重算。
- **分支判据（不冒充）**：`MODE=AUTOLOAD_OK` 需同时满足 `/root/WorldState` 存在 + `get_flag/set_flag/flag_changed` 齐全 + **flag 链路已连通**（`ws.flag_changed` 已连 `hud._on_flag_changed`）。任一不满足 → `MODE=DEGRADED`，如实声明「未验证 flag→TitleLabel 增量链路、未冒充 autoload 可访问/链路通过」，并至少验证 4 信号可连接 + 关键方法 `has_method` 且实际 `call`。
- **三段式 flag**：`grace.network.last_grace_id`（text 增量）、`grace.limgrave_gatefront.lit`（任务书举例，点亮态 font_color 增量）、`world.verify_probe.changed`（不在绑定集合，验证不误刷），均匹配 I-1 正则 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`。

---

## ② 自检（含完整实际 stdout）

### 2.0 命令清单

三段门禁（照 `00-工具链接入说明.md §4.2` / `DONE-R16.md §2.3` 口径，工程根为 `--path`）：

- **G1** `godot --headless --path <工程根> --import`
- **G2** `godot --headless --path <工程根> --check-only --script res://scripts/verify_hud_binding.gd`
- **G3** `godot --headless --path <工程根> --quit`

> G2 `--check-only` 只解析脚本、不执行 `_initialize()`（见 2.2 输出仅 banner），故「实例化 `hud.tscn` → 取 `hud.gd` 实例」的**真跑**由额外一条不带 `--check-only` 的 `--script` 完成（2.3）。四段均为实际执行、实际 stdout。

### 2.1 首次真跑（修复前 · 脚本 v1）—— 如实登记的失败输出

首次 `--script` 真跑即暴露真实时序问题，未隐瞒、未伪造，原样留档：

```
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --script "res://scripts/verify_hud_binding.gd"
```

实际 stdout（完整）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[R17] ==== verify_hud_binding 真跑开始 ====
[R17] extends SceneTree | 只读实例化 hud.tscn，不改任何场景文件
[R17] ⓪ /root children = ["WorldState", "GameEvents", "SaveSystem", "ChunkManager", "SceneRouter"]
[R17] ① scene_instantiate PASS=true | class=CanvasLayer name=Hud
[R17] ② hud.gd 实例 PASS=true | script=res://scripts/hud.gd
[R17] ③ TitleLabel PASS=true | text=赐福 · 宁姆格福
[R17] ④ 4 信号存在 PASS=true | signals=["grace_selected", "travel_confirmed", "rest_requested", "hud_refreshed"]
[R17] ⑤ 4 信号可连接 PASS=true | connect_errs=[0, 0, 0, 0] hud_refreshed_is_connected=true
[R17] ⑥ 关键方法可寻址 PASS=true | total=17 missing=[]
[R17] ⑦ _ready 全量刷新 PASS=false | hud_refreshed_count=0 TitleLabel.text=赐福 · 宁姆格福
[R17] ⑧ autoload 实测 | /root/WorldState exists=true script=res://scripts/rpg/world_state.gd api(get_flag/set_flag/flag_changed)=true
[R17] ---- MODE=AUTOLOAD_OK：验证 flag→TitleLabel 增量刷新 ----
[R17] A0 flag_changed 已连 HUD PASS=false | ws.flag_changed -> hud._on_flag_changed connected=false
[R17] A1 text 增量(flag_changed) PASS=false | flag=grace.network.last_grace_id before=[赐福 · 宁姆格福] after=[赐福 · 宁姆格福] display_name命中=false hud_refreshed=0(基线=0)
[R17] A2 点亮态增量(flag_changed) PASS=false | flag=grace.limgrave_gatefront.lit before=(0.83, 0.68, 0.3, 1.0) after=(0.83, 0.68, 0.3, 1.0) GOLD命中=true hud_refreshed=0(基线=0)
[R17] A3 无关 flag 不误刷(增量命中) PASS=true | flag=world.verify_probe.changed text不变=true color不变=true hud_refreshed=0(基线=0)
[R17] A4 关键方法经 flag_changed 链路实际调用：refresh_label -> set_title_from_grace / apply_lit_state 均已被 A1/A2 间接触发
[R17] ==== verify_hud_binding 真跑结束 ====
[R17] SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=7 fail=4 ok=false
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
VERIFY_EXIT=1
```

**根因与修复（轮内完成，不跨轮甩锅）**：
1. `_initialize()` 里 `add_child(hud)` 后 `_ready()` 尚未在帧循环 flush，故 `hud_refreshed_count=0`、`bind_world_state()` 未执行、`ws.flag_changed` 未连到 `hud._on_flag_changed`（A0=false），A1/A2 自然无从刷新（A2 的 `before` 仍是 `.tscn` 落盘金色 `0.83,0.68,0.3` 而非 `apply_lit_state(false)` 后的 DIM，即为铁证）。
2. v1 的分支判据只看「autoload 存在」，链路不通时仍误标 `MODE=AUTOLOAD_OK/flag_chain_verified=true`。
3. **修复**：① 改 `process_frame` 帧状态机等 `_ready()` flush；② 把「flag 链路连通」纳入 `AUTOLOAD_OK` 判据，链路不通一律按任务书第 2 条如实降级。修复后复跑见 2.3，`pass=11 fail=0 ok=true`、`VERIFY_EXIT=0`。
4. 旁证：`R16` 的 `r16_verify_hud.gd` ⑥ 仅断言 `TitleLabel.text` 非空，而该文本来自 `.tscn` 落盘占位，即使 `_ready()` 未执行也非空，故未暴露此时序；本轮以 `hud_refreshed` 信号计数替代文本非空作为「`_ready()` 已执行」判据。**该观察仅登记，未改动 R16 任何交付件。**

### 2.2 G2 `--check-only --script` 语法门禁（最终版，完整 stdout）

```
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --check-only --script "res://scripts/verify_hud_binding.gd"
```

实际 stdout（完整）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

G2_EXIT=0
```

> 仅引擎 banner、无任何脚本内 `print` / `SCRIPT ERROR` / `Parse Error` / `ERROR` —— `--check-only` 只解析不执行，证明 `verify_hud_binding.gd`（`extends SceneTree`）为 Godot 4.7.2 合法语法。

### 2.3 核心真跑 `--script`（最终版，完整 stdout）

```
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --script "res://scripts/verify_hud_binding.gd"
```

实际 stdout（完整）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[R17] ==== verify_hud_binding 真跑开始 ====
[R17] extends SceneTree | 只读实例化 hud.tscn，不改任何场景文件
[R17] ⓪ /root children = ["WorldState", "GameEvents", "SaveSystem", "ChunkManager", "SceneRouter"]
[R17] ① scene_instantiate PASS=true | class=CanvasLayer name=Hud
[R17] ② hud.gd 实例 PASS=true | script=res://scripts/hud.gd
[R17] ③ TitleLabel PASS=true | text=赐福 · 宁姆格福
[R17] ④ 4 信号存在 PASS=true | signals=["grace_selected", "travel_confirmed", "rest_requested", "hud_refreshed"]
[R17] ⑤ 4 信号可连接 PASS=true | connect_errs=[0, 0, 0, 0] hud_refreshed_is_connected=true
[R17] ⑥ 关键方法可寻址 PASS=true | total=17 missing=[]
[R17] 已 add_child(hud) | 等待 _ready() 在帧循环 flush（WAIT_FRAMES=3）
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
[R17] ⑦ _ready 全量刷新 PASS=true | frames_waited=3 hud_refreshed_count=1 TitleLabel.text=赐福 · 宁姆格福
[R17] ⑧ autoload 实测 | /root/WorldState exists=true script=res://scripts/rpg/world_state.gd api(get_flag/set_flag/flag_changed)=true
[R17] ⑧b flag 链路连通 | ws.flag_changed -> hud._on_flag_changed connected=true
[R17] ---- MODE=AUTOLOAD_OK：验证 flag→TitleLabel 增量刷新 ----
[R17] A0 flag_changed 已连 HUD PASS=true | ws.flag_changed -> hud._on_flag_changed connected=true
[R17] A1 text 增量(flag_changed) PASS=true | flag=grace.network.last_grace_id before=[赐福 · 宁姆格福] after=[赐福 · 关卡前] display_name命中=true hud_refreshed=1(基线=1)
[R17] A2 点亮态增量(flag_changed) PASS=true | flag=grace.limgrave_gatefront.lit before=(0.45, 0.42, 0.34, 1.0) after=(0.83, 0.68, 0.3, 1.0) GOLD命中=true hud_refreshed=1(基线=1)
[R17] A3 无关 flag 不误刷(增量命中) PASS=true | flag=world.verify_probe.changed text不变=true color不变=true hud_refreshed=1(基线=1)
[R17] A4 关键方法经 flag_changed 链路实际调用：refresh_label -> set_title_from_grace / apply_lit_state 均已被 A1/A2 间接触发
[R17] ==== verify_hud_binding 真跑结束 ====
[R17] SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
VERIFY_EXIT=0
```

**要点**：
- `①~⑥` 静态校验全 PASS：实例化 `hud.tscn` 得 `CanvasLayer` 根节点、脚本 `res://scripts/hud.gd`、`TitleLabel` 可寻址、4 信号存在且可实际连接（`connect_errs=[0,0,0,0]`）、17 个关键方法可寻址。
- `⑦` 等 3 帧后 `hud_refreshed_count=1`，证明 `_ready()` 已真实执行全量刷新。
- `⑧` `/root/WorldState` autoload 实测存在且 `get_flag/set_flag/flag_changed` 齐全；`⑧b` flag 链路已连通 ⇒ 进入 `MODE=AUTOLOAD_OK`（**未降级**）。
- `A1`：`set_flag("grace.network.last_grace_id","grace_limgrave_gatefront")` → `flag_changed` → TitleLabel.text `赐福 · 宁姆格福` → `赐福 · 关卡前`（命中 `.tres` 的 `display_name`）。
- `A2`：`set_flag("grace.limgrave_gatefront.lit", true)`（任务书举例的三段式 flag）→ TitleLabel font_color `DIM(0.45,0.42,0.34)` → `GOLD(0.83,0.68,0.3)`。
- `A3`：无关三段式 flag 不触发任何刷新。
- A1/A2/A3 期间 `hud_refreshed` 恒为 `1`（基线 1，**未发生额外全量**）⇒ **TitleLabel 经 `flag_changed` 增量刷新成立**。

### 2.4 G1 `--import` 完整 stdout

```
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --import
```

实际 stdout（完整）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[   0% ] first_scan_filesystem | 正在扫描文件结构……
[  16% ] first_scan_filesystem | 正在加载全局类名……
[  33% ] first_scan_filesystem | 正在校验 GDExtension……
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[  66% ] first_scan_filesystem | 正在初始化插件……
[  83% ] first_scan_filesystem | 正在启动文件扫描……
[ DONE ] first_scan_filesystem

[   0% ] loading_editor_layout | Started 正在加载编辑器 (5 steps)
[   0% ] loading_editor_layout | 正在加载编辑器布局……
[  16% ] loading_editor_layout | 正在加载停靠面板……
[ DONE ] loading_editor_layout

G1_EXIT=0
```

> `正在创建自动加载脚本……` 通过、无 ERROR，新脚本被正常纳入文件系统扫描。

### 2.5 G3 `--quit` 完整 stdout

```
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --quit
```

实际 stdout（完整）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G3_EXIT=0
```

### 2.6 逐条断言结论表（最终版真跑）

| 断言 | 结论 | 实际值摘要 |
|------|------|-----------|
| ⓪ /root children | （证据行） | `["WorldState","GameEvents","SaveSystem","ChunkManager","SceneRouter"]` |
| ① scene_instantiate | PASS | `class=CanvasLayer name=Hud` |
| ② hud.gd 实例 | PASS | `script=res://scripts/hud.gd` |
| ③ TitleLabel | PASS | `text=赐福 · 宁姆格福` |
| ④ 4 信号存在 | PASS | 4/4 |
| ⑤ 4 信号可连接 | PASS | `connect_errs=[0,0,0,0]` |
| ⑥ 关键方法可寻址 | PASS | `total=17 missing=[]` |
| ⑦ _ready 全量刷新 | PASS | `hud_refreshed_count=1`（WAIT_FRAMES=3） |
| ⑧ autoload 实测 | （证据行） | `exists=true script=res://scripts/rpg/world_state.gd api=true` |
| ⑧b flag 链路连通 | （判据行） | `connected=true` |
| A0 flag_changed 已连 HUD | PASS | `connected=true` |
| A1 text 增量(flag_changed) | PASS | `赐福 · 宁姆格福 → 赐福 · 关卡前`，`hud_refreshed=1` |
| A2 点亮态增量(flag_changed) | PASS | `DIM → GOLD`，`hud_refreshed=1` |
| A3 无关 flag 不误刷(增量命中) | PASS | text/color 不变，`hud_refreshed=1` |
| A4 关键方法经链路调用 | （说明行） | `refresh_label → set_title_from_grace / apply_lit_state` 已被 A1/A2 间接触发 |
| **SUMMARY** | **PASS** | `mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true` |

> 降级分支 `MODE=DEGRADED` 及其 `D1` 在本轮**未触发**（因 autoload 与 flag 链路均通，走情形 A）。脚本内该分支保留可用（用于 autoload 不可访问或链路不通时如实登记）。

### 2.7 三段门禁 + 真跑 EXIT 汇总

| 段 | 命令标志 | EXIT | SCRIPT ERROR / Parse Error / ERROR |
|----|----------|------|-----------------------------------|
| G1 | `--import` | `0` | 0 / 0 / 0 |
| G2 | `--check-only --script res://scripts/verify_hud_binding.gd` | `0` | 0 / 0 / 0 |
| 真跑 | `--script res://scripts/verify_hud_binding.gd` | `0` | 0 / 0 / 0 |
| G3 | `--quit` | `0` | 0 / 0 / 0 |

### 2.8 只读边界证据（sha256 快照，收尾实测）

```
0c9670ae77865027627d9bfdccac4e487352abc004aac1fca4446b2cf116c764  godot/scenes/hud.tscn
306b2467ca0a6290639693b1c7e2b4b66f1b55dada2d05ad0bf8d08ff2300fe3  godot/scenes/courtyard.tscn
54bc23f43be58399b1a49e7b4356cb2b2ce93b8852b0f0325537f0e7580612a6  godot/scripts/verify_hud_binding.gd
```

> 两个 `.tscn` 本轮零写入（脚本无 `pack`/`save`，`--import` 不改 `.tscn` 字节）；`courtyard.tscn` 未触碰、`hud.tscn` 结构未改。以上为收尾只读快照留档。

---

## ③ 未完成项与阻塞（明确是否降级）

**是否降级：否。** 最终真跑 `MODE=AUTOLOAD_OK`、`degraded=false`、`flag_chain_verified=true`、`pass=11 fail=0 ok=true`、`VERIFY_EXIT=0`；`WorldState` autoload 可访问且 `set_flag → flag_changed → HUD 增量刷新 → TitleLabel` 链路实测全通，**未走降级分支、未伪造输出、未冒充**。

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 1 | flag→TitleLabel 增量刷新验证 | **已完成** | 情形 A 全 PASS（A1 text / A2 点亮态 / A3 不误刷），`hud_refreshed` 计数证明为增量而非全量。 |
| 2 | 三段门禁 + 真跑 | **已完成** | G1/G2/G3/真跑 4 段 `EXIT=0`，完整 stdout 见 §2。 |
| 3 | 首次真跑时序失败（2.1） | **轮内已修复** | 帧状态机等待 `_ready()` flush + 链路连通纳入判据；复跑 2.3 通过。失败输出如实保留，未删除、未掩盖。 |
| 4 | `ChunkManager` 未找到 `ChunkRoot` WARNING | 如实保留 · 非本轮引入 | 工程既有现象（`chunk_streaming.gd:51 _bootstrap`），G3/真跑均出现，非 ERROR，历轮已登记，未隐藏、未宣称零 WARNING。 |
| 5 | `2 ObjectDB instances were leaked at exit` WARNING | 如实保留 · 非本轮引入 | 工程既有现象（`object.cpp:2536 cleanup`），G3/真跑均出现，非 ERROR，历轮已登记，未隐藏、未宣称零 WARNING。 |
| 6 | 降级分支 `D1` 本轮未执行 | 预期未触发 | autoload 与链路均通，按设计走情形 A；分支代码保留可用，未以降级冒充、也未以 PASS 冒充降级。 |

**阻塞：无功能性阻塞。** 本轮无跨工位依赖、无待总指挥裁决项、无外部输入缺失。任务书三项要求（实例化取 `hud.gd` 实例；autoload 可访问时验证三段式 flag 的 `flag_changed` 增量刷新并打印实际 stdout 与 PASS/FAIL；三段门禁）均真实达成。

**约束对照**：默认不刺探 ✓（只读必读件/本工位/工程根必要资源，未读中枢状态或其它 AI outbox）；零付费 ✓；不伪造输出 ✓（含首次失败输出原样留档）；中文 UTF-8 ✓；Godot 4 合法语法 ✓（G2 EXIT=0）；不碰 `courtyard.tscn`、不改 `hud.tscn` 结构 ✓；不自行 git ✓。
