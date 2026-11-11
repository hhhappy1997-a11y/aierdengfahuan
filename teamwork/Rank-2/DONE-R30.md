# DONE-R30.md · Rank-2（战斗系统与数据驱动）

> 轮次 **R30**｜命令 `cmd-20261111-125001-351-A2`（`[ROUND=R30]`，v0.8.0 新内容）｜派单 `cmd-20261111-125001-351`
> 真源：`teamwork/Rank-2/调度任务单-latest.json`（`id` / `ai=2` / 正文完整核对）
> 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`）
> 工程根 `F:/Game/aierdengfahuan`，Godot 工程 `F:/Game/aierdengfahuan/godot`｜中文 UTF-8
> 结论：**任务单 ①~⑤ 全部落地并经真跑验证**。核心资源 `codex_config.gd` / `codex_entries.tres`
> **12:55:40 尽早落盘**供 Rank-1 读取（新增 `class_name CodexConfig` 已 `--headless --import`
> 注册，`godot/.godot/global_script_class_cache.cfg:27`）。
> `verify_codex_reward_v080.gd` **124 PASS / 0 FAIL / `RESULT=PASS` / EXIT=0**；
> step_index 三态全流程 **21 PASS / 0 FAIL**（三进程 pid 28336 / 24800 / 9396）；
> 三段门禁 G1/G2/G3 全 `EXIT=0`，11 份 `R30-*.log` 逐份 `grep SCRIPT ERROR|Parse Error = 0`、
> `PASS=false = 0`。零付费、零外部依赖、未启 GPU job、未自行 git。

---

## 1. 实际交付清单

| # | 文件 | 动作 | 大小 | 内容 |
|---|---|---|---|---|
| 1 | `godot/scripts/combat/codex_config.gd` | **新写** | 12326 B | `extends Resource` / `class_name CodexConfig`；4 项成就 6 字段静态类型视图 `CodexEntry`、`@export entries: Array[Dictionary]`；`condition_kind` 白名单 3 态（bool_true / int_at_least / all_of）+ `REGISTERED_FLAGS` 既有登记 flag 表（条件可达）+ `evaluate_condition()` 纯求值 + `is_entry_valid()` / `is_reward_monotonic()` / `total_reward_points()`；`DEFAULT_*` 全为 `[PLACEHOLDER]` 非法占位基线并逐项写 rationale；头注写明**调参唯一入口**。 |
| 2 | `godot/data/rpg/codex_entries.tres` | **新写** | 1334 B | 顶层 `CodexConfig` + `entries = Array[Dictionary]` 4 项；`condition_kind` 只用 bool_true / int_at_least / all_of；奖励点数 **30 / 50 / 80 / 120**；嵌套 `condition_value` 真读盘回读成功（见 §3 cond_detail）。 |
| 3 | `godot/scripts/combat/verify_codex_reward_v080.gd` | **新写** | 27111 B | `extends SceneTree`，**124 条断言**：4 项条件 / 奖励单调 / 重复领取拒绝 / 余额非负 / points 只增不减 / commit 先落盘 / 异常输入拒绝，另附条件求值边界、A36 解锁 key、空表降级；逐条 PASS/FAIL + SUMMARY + RESULT，失败 `quit(1)`。 |
| 4 | `teamwork/Rank-2/CODEX-TUNING.md` | **新写** | 12039 B | 数值假设表（4 项 6 字段 `[PLACEHOLDER]` + rationale）/ condition 3 语义与「条件可达」保证 / 降级基线 / 调参唯一入口与同步清单 / **broken 4 定义**（门槛过高 / 奖励通胀 / 条件不可达 / 重复领取）/ 与既有系统关系。 |
| 5 | `teamwork/Rank-2/DONE-R30.md` | **新写** | 本文件 | 本文件。 |
| 6 | `teamwork/command_center/ai/2/outbox/cmd-20261111-125001-351-A2.json` | **新写** | — | 按本命令 id 的回执（**teamwork 下 `command_center/ai/2/outbox`，非工程根 `command_center/`**）。 |

另有 `teamwork/Rank-2/R30-*.log` **11 份真跑日志**：`R30-gate1-import`（尽早落盘后的首次 import）、
`R30-gate2-checkonly-codex_reward`、`R30-run-verify_codex_reward_v080`、`R30-gate3-quit`、
`R30-tristate-{selftest,write,read}`（三态 21 PASS）、
`R30-final-gate{1,2,3}-*`（最终三段门禁串联）。均为真实执行输出，非推断。

**未写 / 未改**（目录所有权硬约束）：`hud.gd` / `codex_director.gd` / `presentation.gd` /
`verify_codex_v080.gd` / 场景 / 素材 / shader / 契约 / README / `CODEX-GDD.md` /
`world_state.gd` / 生产存档逻辑 / `project.godot` / 其余 `.tres` / 导演脚本 / `teamwork/Rank-3/`；
**未自行 git**。零付费、零外部依赖、未启 GPU job、未新建只读探针 / 巡检脚本（verify 为正式自测件）。

---

## 2. 按任务单正文逐项落实

### ① `codex_config.gd` + `codex_entries.tres`（尽早落盘 / 4 项成就）

`class_name CodexConfig extends Resource`，4 项成就字段 `id / title / description /
condition_kind / condition_value / reward_points`，数值全标 `[PLACEHOLDER]` 并写 rationale（见 `.gd` 头注
「设计数值 [PLACEHOLDER] rationale」块与 `CODEX-TUNING.md §1`）。

| # | `id`（A36 下划线） | `condition_kind` | `condition_value`（只引用既有登记 flag） | `reward_points` |
|---|---|---|---|---|
| 1 | `tutorial_complete` | `bool_true` | `{"flag": "grace.tutorial.completed"}` | **30** |
| 2 | `wave_trial_clear` | `bool_true` | `{"flag": "dungeon.wave_trial.completed"}` | **50** |
| 3 | `all_grace_upgrades` | `all_of` | `{"flags": [grace.upgrade_hp_max_bonus.unlocked, grace.upgrade_roll_iframe_bonus.unlocked, grace.upgrade_attack_power_bonus.unlocked]}` | **80** |
| 4 | `best_wave_3` | `int_at_least` | `{"flag": "dungeon.wave_trial.best_wave", "threshold": 3}` | **120** |

- 与 Rank-1 任务单 `cmd-20261111-125001-344-A1` ① 的 4 类成就判定口径逐项对齐：
  教学完成 / 三波全清 / 三项增益全解锁 / 最高波次 ≥3；订阅的既有三段式 flag 一致。
- **奖励严格单调** `30<50<80<120`，合计 **280**（刻意低于既有单轮三波产出 450，防奖励通胀）。
- **condition_kind 只用既有 flag 语义三态**，未发明新条件类型；4 项覆盖全部 3 种语义。
- **调参唯一入口**：`godot/data/rpg/codex_entries.tres`；`.gd` 的 `DEFAULT_*` 只是字段缺失时的非法占位基线；
  校准同步清单 `.tres → verify 的 EXPECT_* → CODEX-TUNING.md → 本文 → 三段门禁`，不静默改数。
- **落盘时间（文件 mtime 真值）**：`codex_config.gd` / `codex_entries.tres` **2026-11-11 12:55:40**（尽早落盘，
  Rank-1 可读）；落盘后**立刻** `--headless --import` 注册 `class_name CodexConfig`（`R30-gate1-import.log`，
  EXIT=0 / SCRIPT ERROR=0），`global_script_class_cache.cfg:27` 有 `"class": &"CodexConfig"` 铁证。
- 沿用 R26/R27/R28 实证结论：Godot 4.7.2 内部类 Resource 无法正确序列化进 `.tres`，故存储层用
  `Array[Dictionary]`，运行时 `get_entry()` 包装成静态类型视图 `CodexEntry`；嵌套 `condition_value`
  Dictionary 真读盘回读成功（见 §3 cond_detail 四行）。

### ② `verify_codex_reward_v080.gd`（124 PASS / 7 类断言）

`extends SceneTree`，真读 `codex_entries.tres` 走 `CACHE_MODE_IGNORE`（校验落盘真值而非缓存），
**124 PASS / 0 FAIL / `RESULT=PASS` / EXIT=0**。分组：

| 组 | 条数 | 内容 | 结果 |
|---|---:|---|---|
| A 表结构 | 30 | 4 项存在 / 每项 6 字段齐全 / id·title·description·kind·reward 逐项 / is_entry_valid / kind 只用 3 态且全覆盖 / 越界拒绝 / 空表降级 / make_entry 6 字段 | 全 PASS |
| B 4 项条件 | 21 | `condition_value` 结构合法 / flag key 与期望逐项一致 / 三段式正则 / 引用既有登记 flag（条件可达）/ A36 `grace.codex_<id>.unlocked` / threshold=3 | 全 PASS |
| C 条件求值 | 15 | 未达成快照 4 项全 false / 达成快照 4 项全 true / best_wave=2 false·=4 true / all_of 缺一 false / bool_true false / 未知 kind·非 Dictionary·缺 flag·四段非法 key·负阈值·空 all_of·空 key 数组一律 false 不崩 | 全 PASS |
| D 奖励单调 | 5 | `is_reward_monotonic` / 30·50·80·120 逐项 / 严格递增 / 合计 280 / 非单调表被识别 | 全 PASS |
| E 重复领取拒绝 | 11 | 首次 +30 / 二次拒绝 reason=duplicate / 连领 4 次仍拒 / points 不变 / commit=1 / is_claimed / 条件未达成拒绝且不置位不落盘 | 全 PASS |
| F 余额非负 | 8 | 初始 0 / 4 项领取全成功 / 全程 balance≥0 / 终值 280 / spend(100)→180 / `GraceUpgradeService.balance` 一致 / spend(1000) 超支拒绝 / 超支后仍≥0 | 全 PASS |
| G points 只增不减 | 8 | WorldState 实例逐次读回 / 序列非递减 / 终值 280 / 失败操作不改 points / spent 只增 / 无 removals / key 三段式 | 全 PASS |
| H commit 先落盘 | 11 | `stage_flags < disk_write < runtime_update` / commit=1 / reason=`codex_reward_claimed` / 失败不新增事件·不新增 commit / set_flag 在 commit 前入队 / writer 缺失如实登记降级 | 全 PASS |
| I 异常输入拒绝 | 15 | 空 id / 0·负奖励 / 不写 points·不 commit / 未知 kind / null·缺 flag·非法 key·负阈值·空 all_of 结构拒绝 / 未登记 flag（条件不可达）·0 奖励行判非法 | 全 PASS |

- **夹具**：`CodexLedger`（纯内存，points 只增、_claimed 防重复）+ `FakeWriter`（只记 commit 时序、
  不写 user:// 盘）+ 手动 `new()` 的 `WorldState` 实例（不 add_child、不污染生产存档），
  与 `verify_tutorial_reward_v060.gd` 口径一致。
- **commit 先落盘**：严格 `stage_flags（set_flag 入队）→ disk_write（commit 原子落盘）→
  runtime_update（后改运行时实例）`，同时满足 v060 奖励件「先 set_flag 后 commit」与 v060 flags 件
  D1「先落盘再改运行时实例」两种口径，逐条打印事件序列。
- **4 项条件回读真值（落盘 `cond_detail`）**：见 §3。

### ③ step_index 三态全流程 21 PASS 补跑（三进程三态）

复用既有 `teamwork/Rank-3/verify_tutorial_flags_v060.gd`（Rank-3 所有，绝对路径 `--script` +
环境变量 `TUTORIAL_V060_PHASE` 直接真跑，**未复制 / 未改写 / 未越界写 Rank-3 目录**，
与 Rank-1 R29B 已实证的命令格式一致）。**三个独立引擎进程串行完整跑一次**：

| 态 | 环境变量 | PASS | FAIL | RESULT | 进程 pid |
|---|---|---:|---:|---|---:|
| selftest | `TUTORIAL_V060_PHASE=selftest` | **15** | 0 | `ALL_PASS` | **28336** |
| write | `TUTORIAL_V060_PHASE=write` | **3** | 0 | `ALL_PASS` | **24800** |
| read | `TUTORIAL_V060_PHASE=read` | **3** | 0 | `ALL_PASS` | **9396** |
| **合计** | — | **21** | **0** | — | 三个不同 pid（三个独立引擎进程） |

- `read` 态跨进程读回铁证：`R1 新进程 _load() 从磁盘重建内存 PASS=true`、
  `R2 跨进程读回 3/3 一致 ... readback={grace.trial.points:3.0, grace.tutorial.completed:true,
  grace.tutorial.step_index:3.0} mism=[]`、`R3 重启恢复：completed/step_index/points 均不回退 PASS=true`。
- **如实登记 · 隔离口径**：该脚本 `STATE_PATH = user://tutorial_flags_v060_state.json` 是**独立 user://
  文件**，头注明示「不碰 `slot_01/delta.json`」；三进程**串行**执行（selftest → write 写种子 →
  read 独立进程 `_load()` 读回），共享状态文件天然一致，实测 `21 PASS / 0 FAIL / 无 PASS=false`、
  未出现任何抖动。故任务单条件句「**若**共享存档初态导致抖动」**未触发** →
  **R29 独立 PID 临时槽隔离本轮未启用**，保留为预案（即 R28 `verify_save_isolation_v060.gd`
  的 `user://saves/isolated_r28_<pid>/delta.json` 唯一槽方案）。
  本轮**未改 `world_state.gd`、未改生产存档逻辑、未写 `slot_01/delta.json`**，如实登记、不谎报"已隔离"。
- 三态日志：`R30-tristate-{selftest,write,read}.log`，逐份 `SCRIPT ERROR|Parse Error = 0`。

### ④ `CODEX-TUNING.md`（数值假设表 + broken 4 定义）

- **数值假设表**：4 项 6 字段逐项 `[PLACEHOLDER]` + 语义 + rationale（§1）；另含 condition 3 语义 /
  `REGISTERED_FLAGS` 条件可达保证（§2）、`DEFAULT_*` 降级基线（§3）、调参唯一入口与同步清单（§4）、
  与既有系统关系（§6，共用 `grace.trial.points`、`GraceUpgradeService.balance`、A36 flag、三段式正则）。
- **调参唯一入口**：`godot/data/rpg/codex_entries.tres`；校准同步四处，不静默改数。
- **broken 4 定义**（§5）：**B1 门槛过高**（合理时长内解锁寥寥，`threshold` 3 与三波上限对齐、
  三项增益需 600 点成本；优先下调阈值 / 复核 cost）／**B2 奖励通胀**（280 相对三波 450 产出过大、
  点数产出快于消耗；下调 reward 梯度、保持严格单调、不回滚 points）／**B3 条件不可达**
  （引用未登记 flag、阈值超上限、all_of 含不存在 id；由 `is_entry_valid()` + verify 静态拦截）／
  **B4 重复领取**（同 id 二次累加 / 二次落盘；由 _claimed 幂等 + commit 先落盘 + verify 断言覆盖）。
  并如实说明四类观测阈值本身也是 `[PLACEHOLDER]`、verify 不测运行时 flag 写入与画面。

### ⑤ 三段门禁真跑（`grep SCRIPT ERROR=0`）

```bash
ENG="D:/Godot/Godot_v4.7.2-stable_win64.exe"
PROJ="F:/Game/aierdengfahuan/godot"
S="res://scripts/combat/verify_codex_reward_v080.gd"
# G1 新增 class_name CodexConfig 必须先 --headless --import（已注册 global_script_class_cache.cfg:27）
"$ENG" --headless --path "$PROJ" --import
# G2 解析门禁 + 真跑自测
"$ENG" --headless --path "$PROJ" --check-only --script "$S"
"$ENG" --headless --path "$PROJ" --script "$S"
# G3 主场景加载退出
"$ENG" --headless --path "$PROJ" --quit
```

- **最终串联**：`FINAL_G1_IMPORT_EXIT=0 / FINAL_G2_CHECKONLY_EXIT=0 / FINAL_G2_RUN_EXIT=0 /
  FINAL_G3_QUIT_EXIT=0`；最终 `G2 run` 仍 `124 PASS / 0 FAIL / RESULT=PASS`。
- **全部 11 份 `R30-*.log` 汇总**：`TOTAL_SCRIPT_ERROR_PARSE_ERROR=0`、`TOTAL_PASS_FALSE=0`。
  逐份 `grep -cE "SCRIPT ERROR|Parse Error"` 均为 **0**（含 3 份三态日志、4 份首次门禁日志、
  4 份最终门禁日志）。`G3 --headless --quit` 日志中的 SaveSystem / ChunkManager `WARNING` 为
  既有 `--script` 工具模式降级提示，非 `ERROR`，如实保留（不谎报"零 WARNING"）。
- 新增 `class_name CodexConfig` 已 `--headless --import` 注册，`codex_config.gd.uid` /
  `verify_codex_reward_v080.gd.uid` 已生成。

---

## 3. 真跑输出结论汇总（最终态）

| 脚本 / 门禁 | PASS | FAIL | RESULT | EXIT |
|---|---:|---:|---|---:|
| `verify_codex_reward_v080.gd`（本轮新） | **124** | 0 | `PASS` | 0 |
| step_index 三态 selftest（pid 28336） | **15** | 0 | `ALL_PASS` | 0 |
| step_index 三态 write（pid 24800） | **3** | 0 | `ALL_PASS` | 0 |
| step_index 三态 read（pid 9396） | **3** | 0 | `ALL_PASS` | 0 |
| **三态合计** | **21** | 0 | — | 0 |
| G1 `--headless --import` | — | — | `SCRIPT ERROR / Parse Error = 0` | 0 |
| G2 `--check-only --script` | — | — | `SCRIPT ERROR / Parse Error = 0` | 0 |
| G2 `--script`（真跑，含 124 断言） | 124 | 0 | `PASS` | 0 |
| G3 `--headless --quit` | — | — | `SCRIPT ERROR / Parse Error = 0` | 0 |

- **4 项条件落盘真值回读（`cond_detail`，`CACHE_MODE_IGNORE`）**：
  - `[0] id=tutorial_complete kind=bool_true value={"flag": "grace.tutorial.completed"} reward=30`
  - `[1] id=wave_trial_clear kind=bool_true value={"flag": "dungeon.wave_trial.completed"} reward=50`
  - `[2] id=all_grace_upgrades kind=all_of value={"flags": [3 个 grace.upgrade_<id>.unlocked]} reward=80`
  - `[3] id=best_wave_3 kind=int_at_least value={"flag": "dungeon.wave_trial.best_wave", "threshold": 3} reward=120`
- 三段门禁 / 三态 / 首次落盘日志均为真实执行输出；未伪造产物、未谎报成功。

---

## 4. 未完成项 / 阻塞 / 如实边界

1. **所有数值 `[PLACEHOLDER]` 首版，人工试玩校准未执行**（用户侧）：本文与 CODEX-TUNING 只给假设表
   与 rationale，不冒充已校准。
2. **Rank-1 `codex_director.gd` 运行时接线未做**：本轮只交付数据源 + 结构 + 校验；真实 flag 订阅、
   判定解锁、写 `grace.codex_<id>.unlocked`（A36）+ `commit("codex_unlocked")`、Tab 面板（A35 运行时建层）
   归 Rank-1，不越界、不谎报已生效。`verify` 用构造 flags 快照证明条件可求值，**静态「条件可达」
   保证 ≠ 运行时 flag 真实写入保证**。
3. **未做 15~20 秒实机录屏回看**：本轮为 headless 数据 / 门禁任务，无渲染管线可录；CODEX-TUNING §5
   的 4 类 broken 画面 / 手感判定归 Rank-4 录屏目视 + 用户试玩，不伪造画面证据、不宣称 HD-2D 全绿。
4. **未做既有全量回归复跑**：本轮为新增数据 / 自测件，未改任何既有脚本；`G3 --headless --quit`
   主场景加载 `EXIT=0 / SCRIPT ERROR=0`，但未逐一重跑 v060 64/86/21/48/37、v070 6/46 等基线
   （Rank-1 本轮任务单 ④ 会跑全回归，不代跑、不谎报"全部回归 PASS"）。
5. **step_index 三态补跑复用 Rank-3 既有脚本**：绝对路径 `--script` + 环境变量直接真跑，未复制 /
   未改写 / 未写 `teamwork/Rank-3/`；R29 独立 PID 临时槽隔离因抖动条件未触发而**未启用**，
   如实登记（见 §2③）。
6. **只写自有文件**：`hud.gd` / 场景 / 素材 / 契约 / README / `world_state.gd` / 生产存档逻辑 /
   `project.godot` / 其余 `.tres` / 导演脚本 / `CODEX-GDD.md` 一律未改；未自行 git。零付费、
   零外部依赖、未启 GPU job、未新建只读探针 / 巡检脚本。
7. `git status` 中若显示其它文件 modified，系其它工位（Rank-1 / Rank-3 / Rank-4）R30 并发改动，
   非本轮所为。
8. **无功能性阻塞**。

---

## 5. 回执

- **精确路径（任务单指定）**：`F:/Game/aierdengfahuan/teamwork/command_center/ai/2/outbox/cmd-20261111-125001-351-A2.json`
  （`teamwork` 下 `command_center/ai/2/outbox`，非工程根 `command_center/`）。
- 内容：`{"task_id":"cmd-20261111-125001-351-A2","ai":2,"status":"done","result":"引用 DONE-R30.md 实际结论（①~⑤ 全部落地并经真跑验证；核心资源 12:55:40 尽早落盘；4 项成就 30/50/80/120；verify 124 PASS；三态 21 PASS pid 28336/24800/9396；CODEX-TUNING broken 4 定义；三段门禁 EXIT=0 且 grep SCRIPT ERROR=0；未完成项如实登记）"}`
- **调度中枢自动收件实证（13:01，如实登记）**：回执写入精确 `outbox` 路径后被 dispatcher「收件即归档」
  移入 `command_center/dispatcher/receipts/cmd-20261111-125001-351-A2.json`（1829 B，JSON 合法，
  `task_id` / `ai=2` / `status=done` / `result` 与本轮写入逐字一致），`outbox` 当前为空属标准流程
  （非交付缺失）。本轮未改调度中枢任何脚本 / 配置、未自行 git；不代写 dispatcher 行为、不谎报。
