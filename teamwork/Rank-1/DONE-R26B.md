# DONE-R26B · Rank-1 交付（cmd-20261111-080359-707-A1 / [ROUND=R26B] / v0.4.0 三处 P0 缺口收口）

- 执行 AI：Rank-1（引擎架构与渲染）
- 工程根：`F:/Game/aierdengfahuan`；Godot 工程 `F:/Game/aierdengfahuan/godot`；引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）
- **结论速览**：三个 P0 缺口全部收口并真跑实证 —— ① 自动开始（`auto_start=true` + `_ready` 后延迟帧 `start_trial()`，courtyard 真跑日志出现「进入第 1 波」，演示序列优先不双驱动）；② 历史最佳 / ③ 赐福点数与存档对齐（三 flag 经 `WorldState.get_flag/set_flag` + `SaveDeltaWriter.commit` 真实落盘，严格「先落盘再改运行时实例」，重启读回一致）。新 `verify_wave_persist_v040.gd` **44 PASS / 0 FAIL / RESULT=ALL_PASS**；全回归 **37 / 58 / 23 / 53 / 45 / 20 / 34 / 47 / 19 / 31 PASS 全不回退**；三段门禁 **19 份 `r26b_*.log` `TOTAL_SCRIPT_ERROR=0`**；校对 `WAVE-TRIAL-GDD.md` 引用键名与 `.tres` **7/7 一致、差异数 0**。未完成项见 §8。

---

## 1. 实际交付清单（只写自有文件）

| 文件 | 动作 | 说明 |
|---|---|---|
| `godot/scripts/combat/wave_trial_director.gd` | **改写** | 增 `auto_start` / `has_external_driver` 两个 `@export`、`is_trial_active()` / `set_external_driver()` / `restart_trial()` / `interact_restart()` / `bind_persistence()`；`_ready` 后延迟帧自动开始；三 flag 相对探活 + 读回 + 先落盘再改运行时实例；既有状态机 / 3 信号 / 降级 / HUD / `get_snapshot()` 既有 key 逐字不动 |
| `godot/scripts/combat/verify_wave_persist_v040.gd` | **新写** | `extends SceneTree`，44 条断言（A 自动开始 / B 不双驱动 / C 三波推进与落盘顺序 / D 落盘证据与重启读回 / E 依赖缺失降级 / F 兼容开关与重开） |
| `godot/scenes/courtyard.tscn` | **精确编辑** | `WaveTrialDirector` 节点末尾追加 `auto_start = true` / `has_external_driver = false` 两行属性；**节点数仍 36（未增删节点）**，既有节点 / instance 覆盖段 / uv / HUD 文本一字未动 |
| `teamwork/Rank-3/WAVE-TRIAL-GDD.md` / `teamwork/Rank-2/WAVE-TRIAL-TUNING.md` | **未改** | 校对结果 7/7 键名一致、差异数 0，任务单「不一致则只改引用文字」条件未触发，任何引用文字与数值均未改动（详见 §5） |
| `teamwork/Rank-1/DONE-R26B.md` | 本文 | 实际交付 / 真跑结论 / 校对差异 / 未完成项 |
| `teamwork/Rank-1/r26b_*.log` | 真跑日志 | G1 ×1 / G2 ×3 / G3 ×1 / 新 verify ×1 / 全回归 ×13，共 **19 份** |
| `teamwork/command_center/ai/1/outbox/cmd-20261111-080359-707-A1.json` | 回执 | 严格按任务单 id 写到精确路径 |

**零写入**：任何素材 PNG / `.tres`（含 Rank-2 的 `wave_trial.tres`、`wave_trial_config.gd`）、`project.godot`、契约 §3.3 / `00-协作契约.md`、`存档与flag规范.md`、GDD/TUNING 正文、`godot/test/presentation.gd`、`README.md`、其它 Rank 目录既有文件、其它 `.tscn`、`scripts/rpg/*`、`scripts/save_delta_writer.gd`。

---

## 2. ① 自动开始实现与双驱动兼容

### 2.1 自动开始方式

- `@export var auto_start: bool = true`（默认 true）；`courtyard.tscn` 的 `WaveTrialDirector` 节点显式落 `auto_start = true` 作接线证据。
- `_ready()` 末尾置 `_auto_start_pending = true`；`_process(delta)` 先 `_tick_auto_start()` 再 `_advance(delta)`，`_tick_auto_start()` 计数到 `AUTO_START_DELAY_FRAMES = 2`（**一帧延迟的稳健版**）后执行 `start_trial()`。
- 用帧延迟而非 `call_deferred` 的理由：`--script` 注入的孤立导演由验证脚本 `set_process(false)` / 同步 `_initialize()` 驱动时不会误触发自动开始；真实场景由引擎帧驱动，天然「_ready 之后」。
- **真跑实证**（`--headless --quit-after 90 res://scenes/courtyard.tscn`，日志 `r26b_g3_courtyard_autostart.log`）：
  ```
  [WaveTrial] 持久化基线读回：dungeon.wave_trial.best_wave=0 / dungeon.wave_trial.completed=false / grace.trial.points=0（经 WorldState.get_flag）
  [WaveTrial] 自动开始：_ready 后延迟 2 帧 start_trial()=true → 进入第 1 波（state=TELEGRAPH index=1/3）
  ```
  `EXIT=0`、`SCRIPT ERROR=0`。玩家打开 exe 默认即进入第 1 波。

### 2.2 赐福休息 / E 键 interact 重开

- 导演 `_ready()` 显式 `set_process_unhandled_input(true)`；`_unhandled_input()` 收到 `interact` action → `interact_restart()` → `restart_trial()`。
- `restart_trial()`：仅在非 `is_trial_active()` 时可重开；`TRIAL_COMPLETED` 先回 `IDLE` 再 `start_trial()`；一局进行中拒绝（不打断、不重复计数）。
- 既有 `EncounterDirector._unhandled_input()` 的 `interact → _grace_rest()` 链路一字未动，E 键同时完成「赐福休息 + 重开一轮」。

### 2.3 双驱动兼容（演示序列优先）

| 接口 | 语义 |
|---|---|
| `is_trial_active() -> bool` | `TELEGRAPH / WAVE_ACTIVE / WAVE_CLEARED / NEXT_WAVE` 为 true；`IDLE / TRIAL_COMPLETED` 为 false |
| `@export has_external_driver: bool = false` + `set_external_driver(bool)` | 兼容开关：装配层 / 演示序列已显式驱动时置 true，自动开始让位 |
| `_tick_auto_start()` | 延迟帧到点后，若 `has_external_driver=true` 或 `is_trial_active()=true` → 打印让位日志并跳过 `start_trial()`，**不重复计数、不重复发信号** |

- 演示序列（`presentation.gd`，本轮未改）在 frame 0 经公开接口 `start_trial()` 驱动；导演延迟 2 帧后检测到 `is_trial_active()=true` → 让位。真跑日志：
  `[WaveTrial] 自动开始让位：演示序列/外部已驱动（is_trial_active=true，不重复计数、不重复发信号）`
- verify B1~B4 断言：`start_rejects=0`、`wave_started` 仅 1 次、`started_waves=[0]`、仍停在第 1 波 `TELEGRAPH`。

---

## 3. ②③ 三 flag 持久化落盘证据

### 3.1 三个三段式 flag（Rank-3 GDD §6.1 / 契约 §3.3 登记）

| key | 类型 | 单调性 | 落盘点（reason） |
|---|---|---|---|
| `dungeon.wave_trial.best_wave` | int | 单调递增、只增不减 | P1 清波 / P2 全清 / P3 失败结算 |
| `dungeon.wave_trial.completed` | bool | `false → true` 单向 | P2 三波全清（从不写 false） |
| `grace.trial.points` | int | 单调递增、永不清除 | P1 清波累加 |

- 理由字面量 `wave_trial_cleared` / `wave_trial_completed` / `wave_trial_settled` 仅进 `meta.last_commit_reason`，**不是新顶层字段**。
- **不新增顶层字段 / 不动 `schema_version=3` / 不用 `removals`**：只经 `set_flag`（`flags` 字典内新 key）+ `commit(reason)`，不碰十字段结构本身。

### 3.2 读写入口与相对探活

- `_resolve_persistence()`：`Engine.get_main_loop()` 取 `SceneTree` → `root.get_node_or_null(NodePath("WorldState"))` / `NodePath("SaveDeltaWriter")` **相对探活**，全程不用 `/root/...` 绝对路径；取不到时 `_persist_available=false`，如实 `push_warning` 降级、不崩。
- 读：`_load_persisted_baseline()` 经 `WorldState.get_flag(key, default)` 读回三 flag 作为运行时镜像（`_best_wave` / `_grace_points` / `_completed_flag`），HUD「历史最佳」显示跨局值。
- 写：`_persist_settle(reason, ...)` 经 `WorldState.set_flag` 入队 `SaveDelta` → `SaveDeltaWriter.commit(reason)` 强制原子写（`.tmp → flush → rename → delta.json.bak`）。

### 3.3 顺序「先落盘再改运行时实例」

- 既有 I-1 架构下 `set_flag` 是唯一写入口（同时入队 delta 与刷新 WorldState 内存 flags），无法拆开；本导演把 **`set_flag → commit` 整体作为「先落盘」步骤**，落盘成功后才更新导演运行时镜像 / 累计本局点数 / 发信号 / 刷 HUD。不谎称能拆开 I-1 内部。
- 导演维护 `_persist_events: Array[String]`，`get_snapshot()["persist_events"]` 可回读，事件序列逐组：
  `stage_flags:<reason> → disk_write:<reason>（commit 完成）→ runtime_update:<reason>`。
- verify C10 断言 4 组（3×cleared + 1×completed）× 3 事件 = 12 个，逐组顺序全部 PASS；C11 `commit_count=4`。
- **单调保护**：每次结算先经 `get_flag` 读回当前值，对 `best_wave` / `points` 取 `max` 后才 `set_flag`，保证只增不减、绝不因运行时镜像与磁盘态脱节把历史值写回退；`completed` 仅在全清置 `true`。

### 3.4 落盘实证（`verify_wave_persist_v040.gd` D 段，真实 `user://saves/slot_01/delta.json`）

- 首轮基线 `best=0 / points=0 / completed=false` → 三波全清后落盘：
  ```
  dungeon.wave_trial.best_wave = 3
  grace.trial.points          = 450      （100 + 150 + 200）
  dungeon.wave_trial.completed = true
  ```
- D1 delta.json 存在且可解析；D6 十字段齐全、无额外顶层字段；D7 `schema_version=3`；D8 `removals=[]`；D9 落盘 flags 全通过三段式正则；**既有 7 个 flag 全部保留**（落盘前 `WorldState._load()` 回放，未覆盖）。
- D10 / D11 **重启读回一致**：新建独立 `WorldState` 实例（空内存）`_ready()` + `_load()` 从磁盘回放，`best_wave / points / completed` 逐项 == 落盘期望，不回退、不翻转。
- C3 / C4 断言三次清波 `points` 序列 `[100, 250, 450]` 严格单调递增、`best_wave` 序列 `[1, 2, 3]` 只增不减；C7 `completed` `false→true` 单向。

### 3.5 依赖缺失降级与既有踩坑

- `bind_persistence(null, null)` → `persist_available=false`：三波仍推进完成、`points_total=450`，`persist_events` 空、`commit_count=0`、运行时镜像保持 `_ready` 读回基线（verify E1~E5 全 PASS）；数据表缺失路径 → 单波降级不硬编码三波（E6）。
- **`--script` 模式 `/root/...` 绝对路径不可用**：实测既有 `SaveDeltaWriter._ready()` 内 `/root/WorldState` 探活结果 `writer._ws_probe=false`，`commit()` 因此不落盘（首轮 7 FAIL 的根因，如实登记）。verify 做**一次性测试装配修正**：用相对探活的 `WorldState` 补齐 writer 内部委托、并让 `WorldState._load()` 回放既有存档（不改任何工程文件）。修正后 44 PASS 全通过。
- `--script` 模式 `add_child` 不 flush `_ready`：验证脚本显式 `call("_ready")`，注入在 `_ready` 之后；场景回读仍用 `CACHE_MODE_IGNORE`、不 flush `_ready`。

---

## 4. 自动开始 / 双驱动 / 落盘的 PASS 明细

新 `verify_wave_persist_v040.gd`：**44 PASS / 0 FAIL / RESULT=ALL_PASS / EXIT=0**，`pid=8520`（末次真跑）。

| 组 | 条数 | 覆盖 |
|---|---|---|
| A | 4 | `auto_start` 默认 true / `_ready` 后 IDLE / 延迟帧进入第 1 波 TELEGRAPH / 只发一次 `wave_started` |
| B | 4 | 演示序列优先：不重复 start、信号仅 1 次、`started_waves` 无重复、仍停第 1 波 |
| C | 12 | 持久化依赖可用、三波推进、两序列单调、运行时镜像、3 信号、**先落盘再改运行时实例** 4 组顺序、`commit_count=4` |
| D | 11 | delta.json 落盘、三 flag 值/单调/单向、十字段、schema_version=3、removals 空、flags 正则、新实例 `_load()` 重启读回一致 |
| E | 6 | 依赖缺失降级、不写 flag 不落盘、镜像保持基线、数据表缺失单波降级 |
| F | 7 | `is_trial_active()` / `has_external_driver` / `restart_trial()` 重开、`completed` 单向不翻转 |

---

## 5. ③ 校对：GDD 引用键名 vs `.tres` 实际字段（差异与修正）

校对对象：`teamwork/Rank-3/WAVE-TRIAL-GDD.md` §0.1「引用 TUNING.md `[PLACEHOLDER]` 键」、`teamwork/Rank-2/WAVE-TRIAL-TUNING.md` §1 表头，对照 `godot/data/rpg/wave_trial.tres` 实际字段。

| 来源 | 键名 |
|---|---|
| GDD §0.1 引用键（7） | `waves`、`enemy_id`、`hp_multiplier`、`move_weight`、`reward_points`、`telegraph_sec`、`time_limit_sec` |
| TUNING §1 表头（6） | `enemy_id`、`hp_multiplier`、`move_weight`、`reward_points`、`telegraph_sec`、`time_limit_sec` |
| `.tres` 每行字段（6） | `enemy_id`、`hp_multiplier`、`move_weight`、`reward_points`、`telegraph_sec`、`time_limit_sec` |
| `.tres` 顶层字段（2） | `waves`、`script` |

逐键比对（GDD 引用键 → `.tres`）：

| GDD 引用键 | `.tres` 命中位置 | 结果 |
|---|---|---|
| `waves` | 顶层 `waves = Array[Dictionary](...)` | OK |
| `enemy_id` | 每行字段 | OK |
| `hp_multiplier` | 每行字段 | OK |
| `move_weight` | 每行字段 | OK |
| `reward_points` | 每行字段 | OK |
| `telegraph_sec` | 每行字段 | OK |
| `time_limit_sec` | 每行字段 | OK |

- **差异数 = 0**（GDD 7/7 全命中；TUNING 表头 6/6 全在 `.tres` 每行字段；GDD 全文无 `telegraph` / `time_limit` / `reward` 等裸字段名误写）。
- **修正：无**。任务单口径为「**不一致则**只改 GDD/TUNING 的引用文字（不改数值）」，条件未触发，故 GDD / TUNING 的引用文字、键名、数值、结构**一字未动**。GDD §7 V7「待落地后校对」在该文档内仍为 R26 时的历史登记，本轮 R26B 的实际校对结论以本文 §5 为准（如实登记，不擅改 Rank-3 历史状态行）。

---

## 6. 真跑输出结论（三段门禁 + 全回归）

引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--headless --path F:/Game/aierdengfahuan/godot`，串行执行（一次一个引擎进程）。

| 段 | 命令要点 | EXIT | `SCRIPT ERROR` |
|---|---|---|---|
| G1 | `--headless --import` | 0 | 0 |
| G2 | `--headless --check-only --script` ×3（`wave_trial_director` / `verify_wave_persist_v040` / `verify_wave_runtime_v040`） | 全 0 | 全 0 |
| G3 | `--headless --quit-after 90 res://scenes/courtyard.tscn`（自动开始日志出现） | 0 | 0 |

**19 份 `r26b_*.log` 逐份 `grep SCRIPT ERROR / Parse Error` 全 0，`TOTAL_SCRIPT_ERROR = 0`。**

| verify 脚本 | 期望 | 实测 | 结论 |
|---|---|---|---|
| **`verify_wave_persist_v040.gd`（新）** | — | **`pass=44 fail=0 RESULT=ALL_PASS`** | 本轮新增 |
| `verify_wave_runtime_v040.gd` | 37 | `pass=37 fail=0 RESULT=ALL_MATCH` | 不回退 |
| `verify_wave_trial_v040.gd` | 58 | `pass=58 fail=0 RESULT=ALL_MATCH` | 不回退 |
| `verify_wave_flags_v040.gd` | 23 | selftest 17 + write 3 + read 3（三进程 pid 25916 / 6940 / 4864 全不同） | 不回退 |
| `verify_encounter_v030.gd` / `v020` / `v010` | 53 / 45 / 20 | 53 / 45 / 20，全 `RESULT=ALL_MATCH` | 不回退 |
| `verify_fx_profile.gd` / `verify_fx_mobile.gd` / `verify_quality_interaction.gd` | 34 / 47 / 19 | 34 / 47 / 19，全 `RESULT=PASS` | 不回退 |
| 31 PASS 回归 | 31 | `r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11 | 不回退 |

> 全 13 项回归与三段门禁均在**最终版 `wave_trial_director.gd`（含「落盘前 `get_flag` 当前值 max 保护」重构）**下复跑，逐份 `EXIT=0`、`SCRIPT ERROR=0`；19 份 `r26b_*.log` `TOTAL_SCRIPT_ERROR=0`。

门禁 / 运行仅有既有 WARNING（`[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`）、波次降级 / 失败登记 / 未绑定 EncounterDirector 的 `push_warning`，**均非 `SCRIPT ERROR`**，与 R23/R24/R25/R26 日志一致。

---

## 7. 关键运行日志（均在 `teamwork/Rank-1/`）

| 日志 | 内容 |
|---|---|
| `r26b_g1_import.log` / `r26b_g2a_director_checkonly.log` / `r26b_g2b_persist_checkonly.log` / `r26b_g2c_runtime_checkonly.log` | 三段门禁 G1 / G2 |
| `r26b_g3_courtyard_autostart.log` | **自动开始日志**：`_ready 后延迟 2 帧 start_trial()=true → 进入第 1 波（state=TELEGRAPH index=1/3）` |
| `r26b_run_verify_wave_persist_v040.log` | 新 verify 44 PASS / RESULT=ALL_PASS；含三 flag 落盘 `3 / 450 / true`、事件顺序、重启读回 |
| `r26b_regress_*.log`（13 份） | 全回归逐份 SUMMARY / RESULT |

---

## 8. 未完成项与如实边界

1. **跨 exe 重启的自动读回链路未接线**：工程 `SaveSystem` 是 R8 装配占位件，autoload `WorldState._ready()` 不自动 `_load()` 磁盘（全工程仅本轮 verify 调用过 `_load()`）。本轮导演按契约经 `get_flag` 公开入口读回、经 `set_flag`+`commit` 落盘；落盘前用 `get_flag` 当前值做 `max` 保护保证单进程 / 已加载态单调不回退；**重启读回一致**由 verify 用「新 `WorldState` 实例 `_load()`」实证（与 Rank-3 `verify_wave_flags_v040.gd` 同口径）。若要玩家重启 exe 后 HUD 直接读出历史最佳，需 Rank-3 接线 `WorldState._load()` / `SaveSystem` —— 该文件不在本轮可写清单内，未擅改。
2. **HUD「赐福点数」显示口径**：仍显示本局累计 `_points_total`（既有口径，回归不回退）；跨局累计以 `grace.trial.points` flag 为准。GDD §6.1 把「波次 HUD 赐福点数」列为该 flag 读方，本轮未改 HUD 显示口径（不改 `presentation.gd` / 既有 HUD 文本），登记为后续对齐项。
3. **`--script` 模式既有 writer 绝对路径探活失效**：由 verify 一次性测试装配修正（§3.5），未改 `scripts/save_delta_writer.gd` / `world_state.gd` 等既有工程文件。
4. **未做 15~20 秒实机录屏 / 目视回看**：本轮约束「不启 GPU job」；自动开始、双驱动兼容、三波推进以运行日志 + 44 条断言判定。
5. **波次 HUD 布局 / 降级时序 / Rank-2 数值仍为 `[PLACEHOLDER]`**：待人工试玩校准，rationale 见 R26 `DONE-R26.md`；本轮未改任何数值。
6. 未自行 `git`（总指挥收尾）；零付费、零外部依赖、未新建只读探针 / 巡检脚本（新 verify 是任务单 ④ 明确要求的正式验证载体）。

---

## 9. 契约与所有权遵守

- 目录所有权：只写 `wave_trial_director.gd` / `verify_wave_persist_v040.gd` / `courtyard.tscn`（2 行 `@export` 属性，不改节点数）/ `teamwork/Rank-1/`（本文 + 19 份日志）；**未写**任何素材 PNG / `.tres`（含 `wave_trial.tres`）/ `project.godot` / 契约 §3.3 / GDD/TUNING 正文 / `presentation.gd` / `README.md` / 其它 Rank 目录 / 其它 `.tscn` / `.gd`。
- 公共契约：直接改、直接真跑；不伪造产物、不谎报成功；`--script` 模式不用 `/root/...` 绝对路径，用 `Engine.get_main_loop()` + `root.get_node_or_null()` 相对探活；`add_child` 显式 `call("_ready")`；零付费、零外部依赖、不启 GPU job；不自行 git。
- 回执 JSON 按任务单 id 写到精确路径 `F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/cmd-20261111-080359-707-A1.json`（`status=done`，`result` 引用本文实际结论）。
- **写后实测（如实登记）**：回执写入成功后 `outbox/` 被中枢**实时消费清空**（目录现 0 文件，与 `DONE-R26.md §⑤` / Rank-3 `DONE-R26.md §⑤` 同一消费时序现象），直接读精确路径 `exists=False`，未隐藏。归档件 `teamwork/command_center/dispatcher/receipts/cmd-20261111-080359-707-A1.json`（3404 字节）读回校验：`json_valid=True`、`keys=['ai','result','status','task_id']`、`task_id=cmd-20261111-080359-707-A1` / `ai=1` / `status=done`、`result_len=2230`、`result` 引用 `DONE-R26B.md` 且含 `44 PASS` / `差异数 0`。按幂等 / 并发保护**不重复写第二份回执**。
