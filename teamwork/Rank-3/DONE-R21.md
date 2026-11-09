# DONE-R21.md · Rank-3 交付报告（R21 · 统一存档快旅口径）

- 任务：`cmd-20261109-115818-643-A3`，`[ROUND=R21]`，Rank-3 执行 AI（RPG / 世界 / 存档）
- 日期：2026-11-09
- 任务单：`teamwork/Rank-3/调度任务单-latest.json`（开工只读，已读 ✓）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`，实测 `--version` = `4.7.2.stable.official.ed1daf0bf`（`EXIT=0`）
- 工程根（`--path`）：`F:/Game/aierdengfahuan/godot`

> **真跑结论（总览，均为实际 stdout）**：
> ① `hud.gd` 最终态：`grace_fast_travel()` 与 `travel_to()` 统一优先取 `/root/SaveDeltaWriter`，注入 committer 仅在取不到时兜底，顺序保持 `commit → travel_confirmed → travel_requested`；赐福菜单 8 节点 / 7 边数据绑定与 R20 的 16 条断言**无一回退**。
> ② 既有验证载体 `r19_verify_hud.gd` 追加 4 条断言（⑰⑱⑲⑳）后真跑 **`SUMMARY pass=20 fail=0 ok=true`**（`VERIFY_RUN_EXIT=0`）＝ R20 既有 **16 PASS** ＋ R21 新增 **4 PASS**。
> ③ R17 回归 **`pass=11 fail=0 ok=true`**（`R17_EXIT=0`）。
> ④ 三段门禁 G1 `--import` / G2 `--check-only --script` ×3 / G3 `--quit` 每段 `EXIT=0`，`grep SCRIPT ERROR / Parse Error / ERROR` **全为 0**。
> ⑤ **两个入口口径一致性：成立**（autoload 源 / 不降级 / 顺序 / 登记字段逐项一致，⑲⑳ 实测）。
> ⑥ **是否还有其它入口走旧口径：没有**（见 §3.1）。
> ⑦ **是否影响既有存档读档：不影响**（§4.4 十字段 / `schema_version=3` / 三段式 flag 均未改，见 §3.2）。
> 合计 **31 PASS / 0 FAIL**（20 ＋ 11）。

---

## ① 实际交付清单（本轮真正写入的文件）

| # | 文件 | 动作 | 说明 |
|---|------|------|------|
| 1 | `godot/scripts/hud.gd` | **修改** | 统一两入口落盘口径（本单指定工程文件），详见 §1.1 / §1.2 的如实登记 |
| 2 | `teamwork/Rank-3/r19_verify_hud.gd` | **修改 2 处** | 既有验证载体复用、**不新建探针脚本**：头注释补 R21 说明；在 `⑯` 之后、`SUMMARY` 之前追加 `⑰⑱⑲⑳` 四条断言 + 1 行 R21 打印。`①~⑯` 检测项与编号逐字保留 |
| 3 | `teamwork/Rank-3/R21-*.log` | **新建 · 运行输出留档（11 个）** | 引擎版本 / 3 段语法预检 / 验证真跑 / R17 回归 / G1 / G2×3 / G3 的实际 stdout，非工程源文件、非脚本 |
| 4 | `teamwork/Rank-3/DONE-R21.md` | **新建** | 本报告 |
| 5 | `teamwork/command_center/ai/3/outbox/cmd-20261109-115818-643-A3.json` | **新建** | 回执 JSON，按本单 id 写在 `teamwork/command_center/` 下的精确路径（**未**写到工程根 `command_center/`） |

### 1.1 `hud.gd` 最终态（真跑基准，逐行核对）

| 位置 | 最终态 | 与 R20 对比 |
|------|--------|------------|
| `:4-5` | 头注释补「R21 · 统一存档快旅口径」 | 新增注释 |
| `:37-39` | 常量注释补「供 travel_to() / grace_fast_travel() 两入口统一优先解析真实节点」 | **本实例轮 1 直接写入** |
| `:59` | `commit_degraded` 注释改为「最近一次落盘（travel_to / grace_fast_travel 共用）」 | 注释同步 |
| `:300-306` | `grace_fast_travel()` 文档注释：与 `travel_to()` 统一走 `_commit_before_travel(reason)`，优先 `/root/SaveDeltaWriter`、注入 committer 仅兜底 | 更新注释 |
| `:307-331` | `grace_fast_travel()`：校验逻辑（unlocked / requires_flags / 沿 edges 可达性）逐字未动；**`:325` 改为 `if not _commit_before_travel(reason):`**（R20 为 `:321` 调 `_delegate_commit()` 注入优先）；后发 `travel_confirmed`（`:328`）与 `GameEvents.travel_requested`（`:331`）逐字未动 | **核心改动** |
| `:339-344` | `_delegate_commit()` 改为薄委托 `return _commit_before_travel(reason)`，函数体内**不再有「注入 committer 优先」旧口径**；保留方法名以不破坏 R17 `⑥` 的 17 方法可寻址 | **核心改动** |
| `:400-401` | §7 约束补「R21：grace_fast_travel() 亦统一走 _commit_before_travel()」 | 新增注释 |
| `:419-437` | `travel_to()` **逐字未动**（`:432` 仍 `_commit_before_travel(REASON_FAST_TRAVEL)`） | 未动 |
| `:443-468` | `_commit_before_travel()` **逐字未动**（R20 的 autoload 优先 / 注入兜底 / 如实登记逻辑） | 未动 |
| §1~§4 / §6 | 4 信号、8 节点 7 边数据绑定（数据取自 `.tres`）、`get_flag(key, default)` 显式默认值、事件驱动增量刷新、`open_grace_menu()`、私有工具：逐字未动 | 未动 |

**实测顺序证据**：`R21-RUN-verify.log` 中 `⑳` 的降级 warning 回溯为
`[0] _commit_before_travel (res://scripts/hud.gd:460) → [1] grace_fast_travel (res://scripts/hud.gd:325)`，
直接证明 `grace_fast_travel()` 走的是 `_commit_before_travel()`（而非旧的注入优先 `_delegate_commit` 实现）。

### 1.2 关于本轮观测到的并发写入（如实登记，不谎报成功）

本轮编辑窗口内，`hud.gd` 存在**同工位并发写入**，本实例如实登记，不冒充全部逐行手改、也不否认最终成果：

1. 开工首读时 `hud.gd` 为 R20 态（`grace_fast_travel()` → `_delegate_commit()` 注入 committer 优先，22876 字节）。
2. 本实例先写入了常量注释补充（现 `:38-39`，A1），该注释在并发后被保留合并。
3. 随后准备改 `_delegate_commit()` 时重读，发现该文件已被并发写入并落地了 R21 功能统一改动（新增 R21 头注释、`commit_degraded` 注释措辞变更、`grace_fast_travel()` 直接调 `_commit_before_travel()`、`_delegate_commit()` 薄委托、§7 约束注释），文件 mtime `12:06:30` / 23554 字节。本实例针对已被改写的注释行做的一次替换因此未命中（`old_string` 已变），**如实记录为一次未命中的 Edit、未覆盖并发成果、未重复改写**。
4. 本实例逐行核对并发后的最终态，确认其**完全满足本单 ①**（两入口统一 autoload 优先、注入兜底、顺序不变、8/7 与 R20 断言不回退），遂以该最终态为真跑基准，**不覆盖、不打架**。
5. 真跑前后 `hud.gd` md5 均为 `ff0751bc1079cb1bf43416eb628a3d0a`、`r19_verify_hud.gd` 均为 `b35ccbb97cebde1e149dce401beffc0c`，证明门禁期间文件稳定、结果基于同一份磁盘内容。

> 归纳：本实例**直接写入**的是 `hud.gd` 常量注释补充 + `r19_verify_hud.gd` 头注释与 4 条断言；`hud.gd` 函数体的统一改写由本轮同工位并发写入落地，本实例已核对、保留、并以三段门禁与验证脚本真跑验证。结论以**最终磁盘状态 + 实际 stdout** 为准，不谎报、不伪造。

**可写范围核对**：仅上述文件落在允许范围（`godot/scripts/hud.gd` 为本单指定工程文件；`teamwork/Rank-3/` 为本 Rank 目录；回执例外 `teamwork/command_center/ai/3/outbox/`）。

**硬约束核对（绝对未碰）**：`project.godot`（本轮无人可写）、`courtyard.tscn`、`quality_settings.gd/tscn`（Rank-1）、`verify_frame_data.gd`（Rank-2）、`hd2d_fx.gd/tscn`（Rank-4）—— 本轮**零写入**。另未写 `hud.tscn`、`grace_network.tres`、`world_state.gd`、`save_delta.gd`、`save_delta_writer.gd`（R20 已注册的 autoload 件）、其它工位与契约/台账，未自行 `git` 提交。

---

## ② 真跑输出结论（实际 stdout，未删改、未补写）

### 2.1 命令清单

| 段 | 命令（`--headless --path F:/Game/aierdengfahuan/godot`） |
|----|--------------------------------------------------------|
| 引擎版本 | `--version` |
| 语法预检 | `--check-only --script res://scripts/save_delta_writer.gd` / `res://scripts/hud.gd` / `<abs>/r19_verify_hud.gd` |
| 验证真跑 | `--script F:/Game/aierdengfahuan/teamwork/Rank-3/r19_verify_hud.gd`（不带 `--check-only`，实执行 `_initialize()`） |
| R17 回归 | `--script res://scripts/verify_hud_binding.gd` |
| 门禁 G1 | `--import` |
| 门禁 G2 | `--check-only --script` ×3（同语法预检） |
| 门禁 G3 | `--quit` |

### 2.2 语法预检 / 退出码（实际 stdout 摘要）

```
VERSION_EXIT=0   PRE_WRITER_EXIT=0   PRE_HUD_EXIT=0   PRE_R19_EXIT=0
VERIFY_RUN_EXIT=0   R17_EXIT=0
G1_EXIT=0   G2a_EXIT=0   G2b_EXIT=0   G2c_EXIT=0   G3_EXIT=0
```

> 11 次引擎调用全部 `EXIT=0`；`--check-only` 只解析不执行，证明改动后的 `hud.gd` 与追加断言后的 `r19_verify_hud.gd` 均为 Godot 4.7.2 合法语法。

### 2.3 验证脚本真跑（`R21-RUN-verify.log`，20 条断言全 PASS）

```
[R19] ⓪ /root children = ["WorldState", "GameEvents", "SaveSystem", "ChunkManager", "SceneRouter", "SaveDeltaWriter"]
[R19] ⓪ ProjectSettings.has_setting("autoload/SaveDeltaWriter") = true | /root/SaveDeltaWriter exists = true
[R19] ① scene_instantiate(CACHE_MODE_IGNORE) PASS=true | class=CanvasLayer name=Hud
[R19] ② script_attached PASS=true | path=res://scripts/hud.gd
[R19] ③ TitleLabel PASS=true | text=赐福 · 宁姆格福
[R19] ④ four_signals_exist PASS=true
[R19] ⑤ four_signals_connectable PASS=true | connect_errs=[0, 0, 0, 0]
[R19] ⑥ new_methods_addressable PASS=true | total=3 missing=[]
[R19] ⑦ grace_network_8nodes_7edges PASS=true | nodes=8 edges=7 (期望 8/7)
[R19] ⑧ ready_full_refresh_baseline PASS=true | hud_refreshed_count=1
[R19] ⑨ open_grace_menu_call PASS=true | return_type=28 menu_open=true node_count=8 edge_count=7 (期望 8/7)
[R19] ⑩ R17_flag_incremental_intact PASS=true | ws_ok=true hud_refreshed_count=1(基线=1)
[R19] ⑪ commit_status 实测 | degraded=false source=autoload reason=grace_fast_travel ok=true writer_autoload=true
[R19] ⑪ 调用顺序实测 | order=["commit", "signal:travel_confirmed", "signal:travel_requested"]
[R19] ⑪ commit_before_signal_order PASS=true
[R19] ⑫ autoload_registration_readback PASS=true | degraded=false source=autoload ok=true
[R19] ⑬ four_signals_intact_after_extension PASS=true
[R19] ⑭ autoload_registered_and_root_node PASS=true | script=res://scripts/save_delta_writer.gd
[R19] ⑮ autoload_commit_before_signal_order PASS=true | commit_count=1 last_reason=grace_fast_travel
[R19] ⑯ fallback_to_injected_when_writer_missing PASS=true | degraded=true source=injected
[R21] ==== 追加 ⑰⑱⑲⑳：两落盘编排入口 autoload 优先级 / commit 顺序一致性 ====
[R19] ⑰ grace_fast_travel_autoload_priority PASS=true | degraded=false source=autoload reason=grace_fast_travel ok=true writer_registered=true writer_root_exists=true
[R19] ⑱ grace_fast_travel_commit_before_signal_order PASS=true | order=["commit", "signal:travel_confirmed", "signal:travel_requested"] committed_reason=grace_fast_travel
[R19] ⑲ two_entries_autoload_and_order_consistent PASS=true | travel_to[order=["commit","signal:travel_confirmed","signal:travel_requested"] source=autoload degraded=false] grace_fast_travel[order=["commit","signal:travel_confirmed","signal:travel_requested"] source=autoload degraded=false]
[R19] ⑳ grace_fast_travel_fallback_to_injected PASS=true | writer_removed=true order=["commit","signal:travel_confirmed","signal:travel_requested"] degraded=true source=injected
[R19] ---- 回读汇总 ----
[R19] SUMMARY pass=20 fail=0 ok=true
[R19] ==== r19_verify_hud 真跑结束 ====
```

| 断言组 | 结论 | 实际值 |
|--------|------|--------|
| `①~⑯` **R20 既有 16 条** | **16/16 PASS** | 脚本挂载 / 4 信号 / 新方法 / **8 节点 7 边**（⑦⑨ 实测 `nodes=8 edges=7`、`node_count=8 edge_count=7`）/ `open_grace_menu()` / R17 flag 增量 / commit 顺序 / 登记读回 / autoload 存在性 / 回退 —— **无一回退** |
| `⑰` **新增** grace_fast_travel autoload 优先级 | **PASS** | `degraded=false source=autoload ok=true reason=grace_fast_travel writer_root_exists=true` |
| `⑱` **新增** grace_fast_travel commit 顺序 | **PASS** | `["commit","signal:travel_confirmed","signal:travel_requested"]`、`committed_reason=grace_fast_travel` |
| `⑲` **新增** 两入口口径一致性 | **PASS** | travel_to 与 grace_fast_travel 的 `_order` / `source` / `degraded` / `ok` / `reason` 逐项相等 |
| `⑳` **新增** grace_fast_travel 取不到 writer 回退 | **PASS** | 临时移走 `/root/SaveDeltaWriter` 后 `degraded=true source=injected`，顺序仍 `commit→confirmed→requested`，测毕恢复现场 |
| **SUMMARY** | **PASS** | **`pass=20 fail=0 ok=true`**，`VERIFY_RUN_EXIT=0` |

> `⑯` / `⑳` 的降级 `push_warning` 是**预期输出、如实保留**；退出残留为工程既有 WARNING（`[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked`，`DONE-R17/R18/R19/R20` 已登记），均非 `ERROR`。

### 2.4 R17 回归真跑（`R21-RUN-r17.log`）

```
[R17] ⑥ 关键方法可寻址 PASS=true | total=17 missing=[]
[R17] ---- MODE=AUTOLOAD_OK：验证 flag→TitleLabel 增量刷新 ----
[R17] A0 flag_changed 已连 HUD PASS=true
[R17] A1 text 增量(flag_changed) PASS=true | after=[赐福 · 关卡前] hud_refreshed=1(基线=1)
[R17] A2 点亮态增量(flag_changed) PASS=true | GOLD命中=true hud_refreshed=1(基线=1)
[R17] A3 无关 flag 不误刷(增量命中) PASS=true
[R17] SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true
R17_EXIT=0
```

> R21 统一口径后，4 信号、`get_flag(key, default)` 显式默认值、三段式 flag 与事件驱动增量刷新链路**未被破坏**（`pass=11 fail=0`、`missing=[]`、A1/A2/A3 全 PASS）。

### 2.5 三段门禁（`grep` 统计 + 退出码，实际 stdout）

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
===== G3 --quit =====
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
```

> G1「正在创建自动加载脚本……」`[ DONE ]` 无 ERROR；G3 的 `ObjectDB leaked` 是工程既有退出 WARNING，非 ERROR。含语法预检 / 真跑在内 11 份 `R21-*.log` 逐份 `grep`：`SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_LINES=0` **全为 0**。**三段门禁 `grep SCRIPT ERROR=0` 达成**。

### 2.6 PASS / FAIL / EXIT 汇总

| 项 | 数值 |
|----|------|
| R20 既有断言（①~⑯） | **16 PASS / 0 FAIL** |
| R21 新增断言（⑰⑱⑲⑳） | **4 PASS / 0 FAIL** |
| 验证脚本 SUMMARY | **`pass=20 fail=0 ok=true`**，`VERIFY_RUN_EXIT=0` |
| R17 回归 | **`pass=11 fail=0 ok=true`**，`R17_EXIT=0` |
| **合计** | **31 PASS / 0 FAIL** |
| 三段门禁 | 5 段全 `EXIT=0`，`SCRIPT ERROR / Parse Error / ERROR = 0` |

---

## ③ 专项说明（任务单 ④）

### 3.1 是否还有其它入口走旧口径

**没有。hud.gd 内两个落盘编排入口已统一，其余相关入口均不属「注入 committer 优先、autoload 兜底」旧口径。** 逐项如实核对：

| 入口 | 位置 | 口径 | 是否旧口径 |
|------|------|------|:---:|
| `grace_fast_travel()` | `hud.gd:307` | **本轮改**：直接调 `_commit_before_travel()`，autoload 优先 / 注入兜底 | 否（已统一） |
| `travel_to()` | `hud.gd:419` | R20 起即 `_commit_before_travel()`，autoload 优先 / 注入兜底 | 否 |
| `_delegate_commit()` | `hud.gd:343` | **本轮改**：薄委托 `return _commit_before_travel(reason)`，函数体内无注入优先逻辑 | 否 |
| `request_travel()` | `hud.gd:277` | 草案接口：校验后仅 `travel_confirmed.emit()`，**HUD 不自行落盘**（I-1 / `HUD-BINDING.md §2.4`） | 否（设计如此，不涉及 committer 优先级） |
| `ChunkWorldBridge._on_travel_requested` | `scripts/rpg/chunk_world_bridge.gd:123,141` | 既有订阅兜底链路：直接 `SaveDeltaWriter.commit("grace_fast_travel")` → `WorldState._commit_delta` | 否（直接调 autoload 真实节点） |
| `SceneRouter.travel_to_grace()` | `scripts/core/scene_router.gd:104` | 1 号场景切换入口，非 HUD 落盘编排 | 否 |

> 结论：**`/root/SaveDeltaWriter` 优先、注入 committer 仅兜底** 已是 `grace_fast_travel()` 与 `travel_to()` 的唯一口径；旧的「注入 committer 优先」在 `hud.gd` 内已无实现残留。`get_commit_status()` 的 `degraded / source / reason / ok / writer_registered_as_autoload / writer_root_exists / log` 两个入口共用、如实可读回，不伪造落盘与 autoload 状态。

### 3.2 是否影响既有存档读档

**不影响。** 依据（代码事实 + 本轮真跑实证）：

1. **落盘实现与格式未改**：本轮只改 HUD 编排（落盘入口的优先级 / 调用点），**未改** `godot/scripts/save_delta_writer.gd`（R20 autoload）、`scripts/rpg/world_state.gd`、`scripts/rpg/save_delta.gd`、存档格式与迁移逻辑。
2. **口径仍符合 §4.4**：`_commit_before_travel()` 仍委托 `WorldState._commit_delta(reason)` 做 §4.9 原子写（`.tmp → flush → rename_absolute → delta.json`，单槽 `user://saves/slot_01/`）；产物仍是 **§4.4 十字段 SaveDelta**（`baseline / flags / inventory / meta / quests / removals / schema_version / seq / slot / spawns`）、**`schema_version=3`**、**三段式 flag**（正则 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`）；reason 仍 `grace_fast_travel`（既有 `REASON_FAST_TRAVEL` 常量 / `chunk_world_bridge.gd:43`）；`meta.last_commit_reason` 为既有字段（非新增顶层字段）；`committed(reason)` 只是内存信号、不进磁盘。
3. **本轮真跑实证**：`⑪` / `⑰` / `⑲` 均经 autoload 真实 `commit` 触发原子写（writer `commit_count=1 last_reason=grace_fast_travel`）；R17 回归在读档后的 WorldState 上验证 flag→TitleLabel 增量链路 `pass=11`；三段门禁 `--quit` `EXIT=0`。读档链路 `_load → _migrate → _replay_log → _apply_snapshot`（`world_state.gd:320-347`）未改，可正常解析既有格式。
4. **副作用边界**：`grace_fast_travel()` 现在与 `travel_to()` 一样会经 autoload 触发一次真实原子写（这正是「先 commit 后发信号」应有之义），写的是标准 `delta.json`，不改变读档兼容性。

> **如实边界**：本轮**未额外执行**「写盘 → 重启独立进程 → `_load` 回放 → `get_flag` 读回」的端到端读档脚本（该完整链路 `DONE-R9.md` / `RPG-WIRING.md` 已实证）。按公共契约「不新建只读探针 / 巡检脚本」，本轮不新建此类脚本、不冒充本轮重跑；结论基于上述代码事实、本轮真跑（含 autoload 真实落盘）与历轮实证，不谎报。

---

## ④ 未完成项与阻塞

**阻塞：无功能性阻塞。** 派单 5 项（①改 `hud.gd` 统一两入口、顺序不变、8/7 与 R20 16 断言不回退；②既有载体追加断言、真跑 16＋11＋新断言、输出 pass/fail 总数；③三段门禁 `grep SCRIPT ERROR=0`；④DONE 如实说明旧口径 / 读档；⑤不碰禁写文件）均真实达成。

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 1 | `hud.gd:466` source=none 兜底 warning 沿用 R20「本次 travel_to 未能先落盘」措辞 | **如实保留 · 文案边界** | `grace_fast_travel()` 复用 `_commit_before_travel()` 后，该文案在 `source=none` 极端兜底态会略失精确；仅为文案、不影响行为与任何断言、本轮验证未触发该分支（始终有注入 committer），为避免为文案再动 R20 函数体而未改，如实登记 |
| 2 | `hud.gd` 编辑窗口内并发写入 | **如实登记 · 未覆盖 / 未谎报** | 见 §1.2；本实例直接写入的是常量注释补充 + 验证载体断言，函数体统一改写由同工位并发落地，已核对并以最终态真跑 |
| 3 | 端到端读档回放脚本 | 未做 · 按契约不新建只读探针 / 巡检脚本 | 见 §3.2 边界；读档链路历轮已实证、格式未改，不冒充本轮重跑 |
| 4 | 赐福菜单 UI 画面 / 运行期试玩验收 | 未做 · 历轮长期项 · 不阻塞 | `hud.tscn` 仍为 `HudPanel`+`TitleLabel`，菜单 `Array[Dictionary]` 数据快照供 UI 消费；画面 / 人工试玩不在本单范围 |
| 5 | 既有 WARNING（`[ChunkManager] 未找到 ChunkRoot` / `2 ObjectDB instances were leaked`） | 如实保留 · 非本轮引入 | 工程既有退出 WARNING，非 ERROR，未隐藏、未宣称零 WARNING |
| 6 | 重导双产物 | 不在本轮 · 另单 | 任务单注明「重导双产物另以 R21B 补单在工程冻结后执行」，本轮不做 |

**约束对照**：直接改、直接真跑 ✓（未新建任何只读探针 / 巡检脚本，验证载体复用既有 `r19_verify_hud.gd`）；只写本 Rank 目录与本单指定工程文件 ✓；不主动扫目录做进度巡检 ✓（仅对本单 ④ 所需的入口引用做定向 `Grep`）；零付费零外部依赖 ✓（纯本地 Godot 4.7.2）；不伪造产物、不谎报成功 ✓（并发写入、降级 warning、既有 WARNING、文案边界均原样留档）；目录所有权 ✓（未碰 `project.godot` / `courtyard.tscn` / `quality_settings.*` / `verify_frame_data.gd` / `hd2d_fx.*`）；三段门禁 `grep SCRIPT ERROR=0` ✓；中文 UTF-8 无 BOM ✓；不自行 `git` 提交 ✓（由总指挥收尾）。

---

## ⑤ 回执

按本轮 `task_id` 写 `F:/Game/aierdengfahuan/teamwork/command_center/ai/3/outbox/cmd-20261109-115818-643-A3.json`（在 `teamwork/command_center/` 下，**未**写到工程根 `command_center/`），内容 `{"task_id":"cmd-20261109-115818-643-A3","ai":3,"status":"done","result":"引用 DONE-R21.md 实际结论：..."}`。

**实测（本轮）**：回执写入成功后 `outbox/` 被中枢实时消费清空（目录 mtime `12:11`），归档件 `teamwork/command_center/dispatcher/receipts/cmd-20261109-115818-643-A3.json`（1046 字节）读回校验 `json_valid=True`、`task_id=cmd-20261109-115818-643-A3 / ai=3 / status=done`、`result_len=643`、`result` 以「引用 DONE-R21.md 实际结论：」开头；工程根 `command_center/` 不存在（未误写）。按幂等 / 并发保护**不重复写第二份回执**，与 `DONE-R20.md §⑤` / `DONE-R19.md §2.10` 同一消费时序现象，如实登记，未隐藏首次核对 `outbox/` 时的 `FileNotFoundError`。
