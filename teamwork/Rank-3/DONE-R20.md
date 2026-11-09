# DONE-R20.md · Rank-3 交付报告（R20 · 裁决 A9：SaveDeltaWriter 注册 autoload 落地）

- 任务：`cmd-20261109-110237-805-A3`，`[ROUND=R20]`，Rank-3 执行 AI，调度中枢派单
- 日期：2026-11-09
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`，实测 `--version` = `4.7.2.stable.official.ed1daf0bf`（`EXIT=0`）
- 工程根（`--path`）：`F:/Game/aierdengfahuan/godot`
- 必读（开工只读一次）：`Rank-3/调度任务单-latest.json`、`command_center/ai/3/inbox/task_cmd-20261109-110237-805-A3.json`、`teamwork/00-协作契约.md`、`Rank-3/SAVE-SPEC-FINAL.md`、`Rank-3/存档规范-4.4口径同步.md`、`godot/scripts/hud.gd`、`godot/project.godot`、`godot/scripts/rpg/world_state.gd`、`godot/scripts/rpg/game_events.gd`、`Rank-3/r19_verify_hud.gd`、`godot/scripts/verify_hud_binding.gd`、`Rank-3/DONE-R19.md` —— 均已读 ✓

> **真跑结论（总览，均为实际 stdout）**：
> ① 新写 `godot/scripts/save_delta_writer.gd` 并正式注册 autoload；② `travel_to()` 兑现「先 commit 后发信号」；③ R20 验证脚本真跑 `SUMMARY pass=16 fail=0 ok=true`（`VERIFY_RUN_EXIT=0`）＝R19 既有 13 条断言全 PASS ＋ 新增 3 条 autoload/顺序/回退断言全 PASS；④ R17 回归 `mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true`（`R17_EXIT=0`）；⑤ 三段门禁 G1 `--import` / G2 `--check-only --script` ×3 / G3 `--quit` 每段 `EXIT=0`，`SCRIPT ERROR=0 / Parse Error=0 / ERROR=0`。
> **降级是否仍保留**：**保留，但降级为「容错回退」而非默认路径**。正常 autoload 态实测 `degraded=false source=autoload`（⑪⑫）；仅在 `get_node_or_null("/root/SaveDeltaWriter")` 取不到节点时才回退注入 committer（⑯ 真跑 `degraded=true source=injected`）。R19「注入 committer 降级为主路径」已结束。
> **是否影响既有存档读档**：**不影响**（有落盘产物实证，见 §3.2）。

---

## ① 实际交付清单（本轮真正写入的文件）

| # | 文件 | 动作 | 说明 |
|---|------|------|------|
| 1 | `godot/scripts/save_delta_writer.gd` | **新建** | autoload 单例。`commit(reason: String) -> void` 签名与 R19 HUD 注入 committer 逐字一致；订阅 I-2 击杀信号写三段式 `combat.<id>.defeated`；强制落盘委托 `WorldState._commit_delta(reason)`（§4.4/§4.9 原子写）；flag 三段式正则校验；发 `committed(reason)` 供顺序自检。 |
| 2 | `godot/project.godot` | **修改** | `[autoload]` 段追加 `SaveDeltaWriter="*res://scripts/save_delta_writer.gd"`（第 52 行）+ 4 行注释；**既有 5 项 autoload 逐字保留**；`[rendering] textures/vram_compression/import_etc2_astc=true` 逐字保留（第 141 行）。本轮只有 Rank-3 写此文件。 |
| 3 | `godot/scripts/hud.gd` | **修改 4 处** | ① 常量注释（`:35-36`）；② §7 约束注释（`:397-400`）；③ `travel_to()` 注释（`:413-417`）；④ `_commit_before_travel()` 函数体（`:439-467`）：改为**优先取 `/root/SaveDeltaWriter` 真实节点，取不到才回退注入 committer**（去掉旧 `ProjectSettings.has_setting` 门槛）。`1~6 节既有逻辑逐字未动`；4 信号、三段式 flag、`get_flag(key, default)` 显式默认值、事件驱动增量刷新、`open_grace_menu()` 的 8 节点/7 边数据驱动逻辑**逐字未动**；`travel_to()` 顺序仍 `commit → travel_confirmed → travel_requested`。 |
| 4 | `teamwork/Rank-3/r19_verify_hud.gd` | **修改 5 处**（既有验证载体复用，**不新建脚本**） | 头注释补 R20 说明；`_initialize()` 加 R20 打印并连 `SaveDeltaWriter.committed → _on_commit`；⑫ 登记期望随裁决 A9 反转；新增 ⑭ autoload 存在性 / ⑮ autoload commit 顺序 / ⑯ 取不到 writer 回退注入 committer 三条断言。①~⑪⑬ 检测项与编号逐字保留。 |
| 5 | `teamwork/Rank-3/DONE-R20.md` | **新建** | 本报告（①交付清单 ②真跑输出结论 ③降级与读档专项 ④未完成项与阻塞）。 |
| 6 | `teamwork/command_center/ai/3/outbox/cmd-20261109-110237-805-A3.json` | **新建** | 回执 JSON，按本轮任务单 id 署名，写在 `teamwork/command_center/` 下的精确路径（未写到工程根 command_center/）。 |

**可写范围核对**：仅上述 6 个文件落在允许范围（`godot/scripts/save_delta_writer.gd`、`godot/project.godot`、`godot/scripts/hud.gd` 为本单指定工程文件；`teamwork/Rank-3/` 为本 Rank 目录；回执例外 `teamwork/command_center/ai/3/outbox/`）。

**硬约束核对（绝对未碰）**：`godot/scenes/courtyard.tscn`、`quality_settings.gd/tscn`（Rank-1 独占）、`hd2d_fx.*`（Rank-4 独占）、`godot/scripts/verify_frame_data.gd`（Rank-2 独占）—— 本轮零写入。另未写 `godot/scenes/hud.tscn`（脚本挂载 `res://scripts/hud.gd` 未动）、`godot/data/rpg/grace_network.tres`（8/7 只读数据源）、`godot/scripts/rpg/world_state.gd`、`godot/scripts/rpg/save_delta.gd`（存档权威实现）、其它工位与总线/总纲/契约/任务书/台账，未自行 `git`。

> 附：`godot/scripts/rpg/save_delta_writer.gd` 与 `Rank-3/save_delta_writer.gd`（R2 既有 3 号设计件 / R8 装配拷贝）保持不动、未被 autoload 引用；本轮注册件为新建的 `godot/scripts/save_delta_writer.gd`，二者路径不同、互不覆盖。

---

## ② 真跑输出结论（实际 stdout，未删改、未补写）

### 2.1 命令清单

| 段 | 命令（`--headless --path F:/Game/aierdengfahuan/godot`） |
|----|--------------------------------------------------------|
| 引擎版本 | `--version` |
| 语法预检 | `--check-only --script res://scripts/save_delta_writer.gd` / `res://scripts/hud.gd` / `<abs>/r19_verify_hud.gd` |
| R20 验证真跑 | `--script F:/Game/aierdengfahuan/teamwork/Rank-3/r19_verify_hud.gd`（不带 `--check-only`，实执行 `_initialize()`） |
| R17 回归 | `--script res://scripts/verify_hud_binding.gd` |
| 三段门禁 G1 | `--import` |
| 三段门禁 G2 | `--check-only --script res://scripts/save_delta_writer.gd` / `res://scripts/hud.gd` / `<abs>/r19_verify_hud.gd` |
| 三段门禁 G3 | `--quit` |

### 2.2 语法预检（实际 stdout）

```
===== PRE-1 --check-only --script res://scripts/save_delta_writer.gd =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
WRITER_CHECK_EXIT=0
===== PRE-2 --check-only --script res://scripts/hud.gd =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
HUD_CHECK_EXIT=0
===== PRE-3 --check-only --script r19_verify_hud.gd =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
PRE_EXIT=0
```

> `--check-only` 只解析不执行，故仅引擎 banner；三处 `EXIT=0` 证明新 writer、改动后的 hud.gd、更新后的验证脚本均为 Godot 4.7.2 合法语法。

### 2.3 R20 验证脚本真跑（关键 stdout，完整 16 条断言均 PASS）

```
[R19] ==== r19_verify_hud 真跑开始 ====
[R20] ==== 裁决 A9 复用：SaveDeltaWriter 已注册 autoload，⑫ 期望反转 + 新增 ⑭⑮⑯ ====
[R19] ⓪ /root children = ["WorldState", "GameEvents", "SaveSystem", "ChunkManager", "SceneRouter", "SaveDeltaWriter"]
[R19] ⓪ ProjectSettings.has_setting("autoload/SaveDeltaWriter") = true | /root/SaveDeltaWriter exists = true
[R19] ① scene_instantiate(CACHE_MODE_IGNORE) PASS=true | class=CanvasLayer name=Hud
[R19] ② script_attached PASS=true | path=res://scripts/hud.gd
[R19] ③ TitleLabel PASS=true | text=赐福 · 宁姆格福
[R19] ④ four_signals_exist PASS=true | signals=["grace_selected", "travel_confirmed", "rest_requested", "hud_refreshed"]
[R19] ⑤ four_signals_connectable PASS=true | connect_errs=[0, 0, 0, 0]
[R19] ⑥ new_methods_addressable PASS=true | total=3 missing=[]
[R19] ⑦ grace_network_8nodes_7edges PASS=true | nodes=8 edges=7 (期望 8/7)
[R20] 已连 SaveDeltaWriter.committed -> _on_commit | writer=true
[R19] ⑧ ready_full_refresh_baseline PASS=true | hud_refreshed_count=1
[R19] ⑨ open_grace_menu_call PASS=true | return_type=28 menu_open=true node_count=8 edge_count=7 (期望 8/7)
[R19] ⑩ R17_flag_incremental_intact PASS=true | ws_ok=true hud_refreshed_count=1(基线=1) text_unchanged=true color_unchanged=true
[R19] ⑪ commit_status 实测 | degraded=false source=autoload reason=grace_fast_travel ok=true writer_autoload=true log=["source=autoload reason=grace_fast_travel ok=true degraded=false"]
[R19] ⑪ 调用顺序实测 | order=["commit", "signal:travel_confirmed", "signal:travel_requested"] committed_reason=grace_fast_travel
[R19] ⑪ commit_before_signal_order PASS=true | 先commit=true 后travel_requested=true
[R19] ⑫ autoload_registration_readback PASS=true | degraded=false source=autoload ok=true writer_registered_as_autoload=true writer_root_exists=true
[R19] ⑬ four_signals_intact_after_extension PASS=true
[R19] ⑭ autoload_registered_and_root_node PASS=true | has_setting=true root_node=true has_commit=true script=res://scripts/save_delta_writer.gd
[R19] ⑮ autoload_commit_before_signal_order PASS=true | order=["commit", "signal:travel_confirmed", "signal:travel_requested"] commit_count=1 last_reason=grace_fast_travel
WARNING: [HUD] 降级登记：未取到 /root/SaveDeltaWriter，改用 set_fast_travel_committer() 注入的 committer 完成 commit(reason=grace_fast_travel)
   GDScript backtrace (most recent call first):
       [0] _commit_before_travel (res://scripts/hud.gd:459)
       [1] travel_to (res://scripts/hud.gd:431)
[R19] ⑯ fallback_to_injected_when_writer_missing PASS=true | writer_removed=true order=["commit", "signal:travel_confirmed", "signal:travel_requested"] degraded=true source=injected
[R19] ---- 回读汇总 ----
[R19] SUMMARY pass=16 fail=0 ok=true
[R19] ==== r19_verify_hud 真跑结束 ====
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
V_RUN_EXIT=0
```

| 断言 | 结论 | 实际值 |
|------|------|--------|
| ①~⑬ **R19 既有 13 条** | **13/13 PASS** | 脚本挂载 / 4 信号可连接 / 新方法 / 8 节点 7 边 / `open_grace_menu()` 实调 / R17 flag 增量 / commit 顺序 / 登记读回 / 4 信号完整 |
| ⑫ 登记读回（**期望随裁决 A9 反转**） | **PASS** | 由 R19 的 `degraded=true source=injected writer_autoload=false` 改为 R20 的 `degraded=false source=autoload writer_autoload=true writer_root_exists=true`；检测项仍是 `get_commit_status()` 如实读回，**非放宽、非伪造**：契约已从「非 autoload 降级」变为「已注册 autoload」，期望值随之对齐 |
| ⑭ **新增** autoload 存在性 | **PASS** | `has_setting=true root_node=true has_commit=true script=res://scripts/save_delta_writer.gd` |
| ⑮ **新增** autoload commit 顺序 | **PASS** | `order=["commit","signal:travel_confirmed","signal:travel_requested"]`，`commit_count=1 last_reason=grace_fast_travel`（观测的是 autoload writer 的 `committed` 信号与真实 `_commit_delta`） |
| ⑯ **新增** 取不到 writer 回退 | **PASS** | 临时移走 `/root/SaveDeltaWriter` 后 `travel_to` 回退注入 committer，`degraded=true source=injected`，顺序仍 `commit→confirmed→requested`；测毕把节点加回 root 恢复现场 |
| **SUMMARY** | **PASS** | **`pass=16 fail=0 ok=true`，`V_RUN_EXIT=0`** |

> 退出残留仅 2 条工程既有 `WARNING`（`[ChunkManager] 未找到 ChunkRoot` 见 `chunk_streaming.gd:51`；`2 ObjectDB instances were leaked` 见 `object.cpp:2536`，`DONE-R17/R18/R19` 已登记），⑯ 的 `push_warning` 降级登记是**预期输出、如实保留**，均非 `ERROR`。

### 2.4 R17 回归真跑（实际 stdout 摘要）

```
[R17] ⓪ /root children = ["WorldState", "GameEvents", "SaveSystem", "ChunkManager", "SceneRouter", "SaveDeltaWriter"]
[R17] ⑥ 关键方法可寻址 PASS=true | total=17 missing=[]
[R17] ---- MODE=AUTOLOAD_OK：验证 flag→TitleLabel 增量刷新 ----
[R17] A0 flag_changed 已连 HUD PASS=true
[R17] A1 text 增量(flag_changed) PASS=true | after=[赐福 · 关卡前] hud_refreshed=1(基线=1)
[R17] A2 点亮态增量(flag_changed) PASS=true | GOLD命中=true hud_refreshed=1(基线=1)
[R17] A3 无关 flag 不误刷(增量命中) PASS=true
[R17] SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true
R17_EXIT=0
```

> 新增第 6 个 autoload 后，R17 的 4 信号、`get_flag(key, default)` 显式默认值、三段式 flag 与事件驱动增量刷新链路**未被破坏**（`pass=11 fail=0 ok=true`、`missing=[]`、A1/A2/A3 全 PASS）。

### 2.5 三段门禁（每段 `grep` 统计 + 退出码，实际 stdout）

| 段 | 命令标志 | `SCRIPT ERROR` | `Parse Error` | `ERROR` | `EXIT` |
|----|----------|:---:|:---:|:---:|:---:|
| G1 | `--import` | 0 | 0 | 0 | 0 |
| G2a | `--check-only --script res://scripts/save_delta_writer.gd` | 0 | 0 | 0 | 0 |
| G2b | `--check-only --script res://scripts/hud.gd` | 0 | 0 | 0 | 0 |
| G2c | `--check-only --script r19_verify_hud.gd` | 0 | 0 | 0 | 0 |
| G3 | `--quit` | 0 | 0 | 0 | 0 |

```
===== G1 --import =====
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[ DONE ] first_scan_filesystem
  grep: SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_LINES=0 | EXIT=0
===== G2a / G2b / G2c =====
  grep: SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_LINES=0 | EXIT=0   （各段）
===== G3 --quit =====
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
  grep: SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_LINES=0 | EXIT=0
```

> G1「正在创建自动加载脚本……」`[ DONE ]`、无 ERROR，说明第 6 个 autoload 被 `--import` 正常纳入扫描与解析；G3 的 `ObjectDB leaked` 是工程既有退出 WARNING，非 ERROR、非本轮引入。三段门禁 `grep SCRIPT ERROR` **全为 0**。

### 2.6 PASS / EXIT 汇总

| 项 | 数值 |
|----|------|
| R20 验证脚本既有 13 条用例 | **13 PASS / 0 FAIL** |
| R20 新增断言（autoload 存在性 / commit 顺序 / 回退） | **3 PASS / 0 FAIL** |
| R20 验证脚本 SUMMARY | **`pass=16 fail=0 ok=true`**，`V_RUN_EXIT=0` |
| R17 回归 | **`pass=11 fail=0 ok=true`**，`R17_EXIT=0` |
| 三段门禁 | 5 段全 `EXIT=0`，`SCRIPT ERROR / Parse Error / ERROR = 0` |

---

## ③ 专项说明（任务单 ⑤）

### 3.1 降级是否仍保留

**仍保留，但语义已从「默认主路径」降为「容错回退」。** 如实分两层：

- **正常 autoload 态（R20 起默认）不再降级**：`project.godot [autoload]` 已正式注册 `SaveDeltaWriter`（实测 `ProjectSettings.has_setting("autoload/SaveDeltaWriter")=true`、`/root/SaveDeltaWriter exists=true`）。`hud.gd:_commit_before_travel()` 优先 `get_node_or_null("/root/SaveDeltaWriter")` 并 `writer.call("commit", reason)`，登记 `degraded=false / source="autoload" / ok=true`（⑪⑫ 实测），R19 的「注入 committer 降级」**已结束**。
- **降级分支仍保留作回退**：仅当取不到 `/root/SaveDeltaWriter` 节点时，才用 `set_fast_travel_committer()` 注入的 committer 完成 `commit(reason)`，并如实登记 `degraded=true / source="injected"` + `push_warning`（⑯ 通过临时移走 autoload 节点真跑验证，顺序仍 `commit → travel_confirmed → travel_requested`）；连注入 committer 都没有则登记 `source="none" ok=false`，**不冒充已落盘**。
- 因此 `get_commit_status()` 的 `degraded / source / reason / ok / writer_registered_as_autoload / writer_root_exists / log` 全部保留可读回；R19 的降级实现未被删除，只是不再默认触发。

### 3.2 是否影响既有存档读档

**不影响。** 依据（代码事实 + 本轮落盘产物实证）：

1. **落盘入口未改**：新 writer 的 `commit(reason)` 委托既有 `WorldState._commit_delta(reason)`（`world_state.gd:254`），本轮**未改** `world_state.gd` / `save_delta.gd` / 存档格式 / 迁移逻辑。
2. **口径符合 §4.4**：仍是 §4.5/§4.9 的 `.tmp → flush → rename_absolute → delta.json` 原子写、单槽 `user://saves/slot_01/`、SaveDelta 十字段、`schema_version=3`；`committed(reason)` 只是内存信号不进磁盘；`meta.last_commit_reason = "grace_fast_travel"` 是既有字段（非新增顶层字段）；flag key 经三段式正则 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$` 校验。
3. **落盘产物实证**（本轮 ⑪ 经 autoload 真实 `commit` 写出的 `user://saves/slot_01/delta.json`，791 字节，逐字回读）：
```json
{
	"baseline": {"baseline_version": 1, "manifest": "res://data/rpg/world_baseline.tres", "manifest_hash": "", "resource_ids": [ ... 5 项 ... ]},
	"flags": {"grace.limgrave_gatefront.unlocked": true, "world.verify_r19.changed": 1},
	"inventory": {},
	"meta": {"area_id": "", "game_version": "", "last_commit_reason": "grace_fast_travel", "last_grace_id": "", "playtime_seconds": 0, "written_at_unix": 1794194408},
	"quests": {},
	"removals": [],
	"schema_version": 3,
	"seq": 2,
	"slot": "slot_01",
	"spawns": {"defeated": [], "epoch": 0}
}
```
   十字段齐全、`schema_version=3`、`slot="slot_01"`、三段式 flag key、`seq=2`，与既有格式逐字一致；读档链路 `_load → _migrate → _replay_log → _apply_snapshot`（`world_state.gd:320-347`）未改，可正常解析。
4. **副作用边界**：R20 起 `travel_to()` 会经 autoload 触发一次真实原子写（R19 用的是只记顺序的测试 Callable，不落盘）。这是「兑现先 commit 后发信号」的应有之义，写的是标准 `delta.json`，不改变读档兼容性；R17 回归（`pass=11`）与三段门禁（`--quit` `EXIT=0`）证明带新 autoload 的工程启动与 flag 链路正常。

> **如实边界**：本轮**未额外执行**「写盘 → 重启独立进程 → `_load` 回放 → `get_flag` 读回」的端到端读档脚本（该完整链路 `DONE-R9.md` / `RPG-WIRING.md` 已实证）。按公共契约「不新建只读探针/巡检脚本」，本轮不新建此类脚本、不冒充本轮重跑；结论基于上述代码事实与本轮落盘产物的实际回读，不谎报。

---

## ④ 未完成项与阻塞

**阻塞：无功能性阻塞。** 派单 5 项要求（①新写 writer 且遵守 §4.4/三段式；②注册 autoload 并保留既有设置；③改 `travel_to()` 优先 autoload、顺序不变、8/7 不回退；④真跑 13+11+新断言、三段门禁 `SCRIPT ERROR=0`；⑤DONE-R20 如实说明降级与读档）均真实达成。

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 1 | `grace_fast_travel()`（R16 既有接口）口径未统一 | **如实登记 · 不擅自扩大改动面** | `hud.gd` 内 `grace_fast_travel()` 仍走 `_delegate_commit()`（注入 committer 优先、autoload 兜底），与 `travel_to()` 的「autoload 优先」相反。本单只要求改 `travel_to()`，故未动 1~6 节既有逻辑；两个接口并存，如实登记，供总指挥后续裁决是否统一 |
| 2 | 端到端读档回放脚本 | 未做 · 按契约不新建只读探针/巡检脚本 | 见 §3.2 边界；读档链路历轮已实证、格式未改，不冒充本轮重跑 |
| 3 | 赐福菜单 UI 画面 / 运行期试玩验收 | 未做 · 历轮长期项 · 不阻塞 | `hud.tscn` 仍为 `HudPanel`+`TitleLabel`，菜单 `Array[Dictionary]` 数据快照供 UI 消费；画面 / 人工试玩属历轮长期项，未在本单范围，不冒充已验收 |
| 4 | 既有 WARNING（`[ChunkManager] 未找到 ChunkRoot` / `2 ObjectDB instances were leaked`） | 如实保留 · 非本轮引入 | 工程既有退出 WARNING，非 ERROR，未隐藏、未宣称零 WARNING |
| 5 | `scripts/rpg/save_delta_writer.gd` 等旧拷贝件 | 保持不动 · 不越界 | 未被 autoload 引用；本轮注册件为新建 `scripts/save_delta_writer.gd`，见 §① 附 |

**约束对照**：直接改、直接真跑 ✓（未新建任何只读探针/巡检脚本，验证载体复用既有 `r19_verify_hud.gd`）；只写本 Rank 目录与本单指定工程文件 ✓；零付费零外部依赖 ✓（纯本地 Godot）；不伪造产物、不谎报成功 ✓（⑫ 期望反转、⑯ 降级 warning、既有 WARNING、落盘产物均原样留档）；目录所有权 ✓（未碰 courtyard.tscn / quality_settings / hd2d_fx / verify_frame_data.gd）；三段门禁 `grep SCRIPT ERROR=0` ✓；中文 UTF-8 无 BOM ✓。

**回执**：按本轮 `task_id` 写 `F:/Game/aierdengfahuan/teamwork/command_center/ai/3/outbox/cmd-20261109-110237-805-A3.json`（在 `teamwork/command_center/` 下，未写到工程根 `command_center/`；已核实工程根无 `command_center/` 目录）。写入成功后被中枢实时消费归档至 `teamwork/command_center/dispatcher/receipts/cmd-20261109-110237-805-A3.json`，归档件读回校验（实际 stdout）：`json_valid=True`、`bytes=2360`、`BOM=False`、`task_id=cmd-20261109-110237-805-A3 / ai=3 / status=done`、`result_len=1477` 且 `result` 以「引用 DONE-R20.md 实际结论」开头。`outbox/` 为空是中枢已消费的正常态（非未写、非丢失），按幂等 / 并发保护**不重复写第二份回执**（与 `DONE-R19.md §2.10` 同一消费时序现象，如实登记，未隐藏首次核对的 `FileNotFoundError`）。
