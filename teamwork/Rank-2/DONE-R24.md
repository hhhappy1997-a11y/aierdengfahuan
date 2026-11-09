# DONE-R24 · Rank-2 交付（赐福重置 Boss + 同招冷却 + 重复挑战，v0.2.0 P1）

- 任务单：`cmd-20261109-205253-725-A2`（`[ROUND=R24]`，v0.2.0 P1，priority=high）
- 执行 AI：Rank-2（战斗系统与数据驱动）
- 工程根：`F:/Game/aierdengfahuan`；引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（v4.7.2.stable）
- 结论：**5 项任务全部完成，真跑 v020=45 PASS / 0 FAIL、v010=20 PASS / 0 FAIL 不回退，三段门禁 `SCRIPT ERROR=0`。未完成项均为既有件边界/跨工位裁决，已在 §7 如实登记，无阻塞。**

---

## ① 交付清单（实际写入）

| 文件 | 动作 | 内容 |
|---|---|---|
| `godot/scripts/combat/encounter_director.gd` | **独占扩展** | 赐福休息真正重置 Boss；接规则层；重复挑战计数、胜负快照进 `get_snapshot()`；保持 v0.1.0 的 20 条断言与 `debug_*` 签名不变 |
| `godot/scripts/combat/encounter_rules_v020.gd` | **新写** | `RefCounted` 纯逻辑，`should_allow_move(last_id, candidate, cooldown_sec, fps)` + `retry_count`，数据驱动、不硬编码帧数 |
| `godot/scripts/combat/verify_encounter_v020.gd` | **新写** | `extends SceneTree`，45 条断言，逐条 PASS/FAIL + RESULT |
| `teamwork/Rank-2/DONE-R24.md` | **新写** | 本文件 |
| `teamwork/Rank-2/R24-*.log`（8 个） | **新写** | 三段门禁 + v010/v020 真跑日志（见 §5） |
| `teamwork/command_center/ai/2/outbox/cmd-20261109-205253-725-A2.json` | **新写** | 回执 JSON（精确路径，非工程根 `command_center/`） |

引擎自动维护（**非手写**）：3 个新 `.gd` 的 `.uid`，以及 G1 `--import` 刷新的 `.godot/global_script_class_cache.cfg`（新增 `class_name EncounterRulesV020`）。

**硬约束核对（未写）**：`godot/scenes/courtyard.tscn`（Rank-1 独占）、`project.godot`、`godot/scenes/encounter_v010.tscn`、全部既有战斗件（`boss_controller.gd` / `move_data.gd` / `boss_data.gd` / `phase_data.gd` / `combat_event_bus.gd` / `combat_resolver.gd` / `player_action_state.gd` / `combat_data_validator.gd` 等）、`verify_encounter_v010.gd`（**只读真跑，未改一字**）、全部 PNG/tres 美术资源，本轮一律未写。`git status --short` 中出现的 `courtyard.tscn` / `README.md` / `build_courtyard_v020.gd` / `perf_encounter_v020.gd` / `capture/*` / `command_center/status.json` / `ledger.jsonl` / 各 Rank 的 `调度任务单-latest.json` 等 M/?? 条目，均为 Rank-1/3/4 与调度中枢**并行产物**，非本 AI 改动；本 AI 可归属的仅上表 3 个 `.gd` 与 Rank-2 文档/日志/回执。

---

## ② 重置做法与边界（任务 ①，如实写明）

### 采用做法：**重新实例化 Boss 子节点替换（做法 B）**，不是「既有公开方法组合」

理由（如实）：`BossController` 没有任何重置 HP / 阶段 / 击败态的公开方法；`_die()` 把 `_defeated=true`、`_state=DEATH` 后，`apply_damage()` 与 `advance()` 会永久 no-op，且 `_ready()` 不重置 `_defeated`。因此**纯公开方法组合无法清除击败态**，若走「公开方法组合」就必须用 `set("_defeated", ...)` 之类反射改私有状态，反而更脏。故按任务单给出的第二个选项，采用**重新实例化**：全新实例天然 `_defeated=false / _hp=max_hp / 阶段 1 / 冷却字典与招式帧清空`。

实现要点（`encounter_director.gd::_respawn_boss()`）：
1. 从旧 Boss 节点**先**读取 4 个公开 `@export`：`boss_data` / `sprite_path` / `event_bus_path` / `world_state_path`（不碰任何私有状态字段）。
2. 断开旧 `move_landed` 信号 → `parent.remove_child(old)` → `old.free()`（节点类型 `is_3d` 在 `free()` **之前**取，避免 use-after-free）。
3. 新建同类节点（旧 Boss 为 `Node3D` 则 `Node3D.new()`，否则 `Node.new()`；`BossController extends Node`，逻辑不依赖 `Node3D`，降级等价），`set_script` 同一 `boss_controller.gd`，回填 4 个 `@export`，`name` 沿用 `Boss`，`parent.add_child(fresh)`。
4. `_bind_boss(fresh)`：关自带 `_physics_process`、摆位归零、重连 `move_landed`、更新 `_connected_boss`（供 `_exit_tree` 统一断开）。
5. 每次成功重建 → `rematch_count += 1`；`_rules.reset_for_rematch()` 清上一招。

### 边界（如实登记，不掩饰）

1. **不碰私有状态**：只复制公开 `@export`，未用 `set("_defeated"/"_hp"/"_state"…)` 改 BossController 内部；`BossController` 既有件零改动。
2. **`--script` 模式 add_child 不 flush `_ready`**：用 `is_node_ready()` 判断，为假时显式 `fresh.call("_ready")`；真实运行时 `add_child` 已触发 `_ready` 则跳过，避免重复初始化。已按任务单「踩坑」提示处理。
3. **`--script` 模式 `/root/...` 绝对路径不可解析**：`_inject_boss_deps()` 从 `Engine.get_main_loop().root.get_node_or_null("WorldState")` 与场景兄弟节点回填 `_world_state` / `_event_bus`（与 v010 既有装配惯例一致，**不改既有件文件**，但耦合了既有件的私有字段名，若其改名需同步）。回填在 `call("_ready")` **之后**，故 `_ready` 内的就绪 flag 检查读到 null→false，正常进阶段 1。
4. **击败 flag 边界（重要）**：`BossController._ready()` 会读 `BossData.defeated_flag_key`（本数据为 `world.boss_01_margit.defeated`）。若真实运行时该 flag 为 true（玩家曾击败 Boss），新实例会保持 `IDLE` 不进入战斗，即「重复挑战可玩」在存档层不清除 flag 时受限。I-1 契约规定 BossController 只读不写、**2 号不写 flag**，本轮不改既有件、不清 flag、不双写，故如实登记为边界；清除该 flag 属存档层 / 3 号职责，需总指挥裁决。验证模式（v010/v020）已把两个 flag 临时置 false 并在结尾 `_restore_all()` 恢复，且重建时 `_world_state` 尚未注入，flag 读 false，不受影响。
5. **信号生命周期**：旧 Boss 的 `move_landed` 连接随旧节点释放消失，必须对新节点重连；已由 `_bind_boss()` 统一处理，`_exit_tree()` 只断当前 `_connected_boss`。
6. **节点类型契约**：按 `encounter_v010.tscn` 既有 `Boss=Node3D` 重建；若将来场景 Boss 节点类型变更，需同步 `old is Node3D` 判断。
7. **既有件固有 ERROR 文本**：`fresh.call("_ready")` 会再触发既有 `BossController` 的 `/root/WorldState` 绝对路径报错（v010 日志 1 条、v020 日志 2 条），见 §5 登记；非 `SCRIPT ERROR`、非断言失败、EXIT 仍为 0，未越界改既有件故未消除。

---

## ③ 规则层设计（任务 ②，`encounter_rules_v020.gd`）

- `extends RefCounted` / `class_name EncounterRulesV020`，**纯逻辑**：不进场景树、不依赖 autoload、不读 `.tres`、不改既有件。
- **数据驱动、不硬编码帧数**：冷却窗口 = `max(MoveData.cooldown_sec, BossData.ai_poll_interval_sec) × fps`，帧数完全由「秒 × 帧率」换算。代码里无任何固定帧数常量；`DEFAULT_FPS=60.0` 仅是 `fps<=0` 时的**降级帧率基准**（帧率，非帧数），保证 0 值 / 负 fps 不除零、不崩。
  - `cooldown_sec` 由 `should_allow_move` 参数传入（来自 `MoveData`）；`ai_poll_interval_sec` 由导演层按 `BossData.ai_poll_interval_sec`（本数据 0.2）在 `_init` 注入，作为数据表 `cooldown_sec=0` 时的冷却下限兜底（Boss 至少隔一个 AI 轮询周期才可能再出同一招）。
- **按帧记录上一招 id**：`tick_frame()` 每逻辑帧推进 `_elapsed_frames`；`last_move_id` 记录最近一次放行 id。
- **`should_allow_move(last_id, candidate, cooldown_sec, fps) -> bool`**：同名且仍在窗口内 → 抑制，`retry_count += 1`、`total_suppressed += 1`、返回 false（不更新帧基准，下一帧可重试）；其余（不同名 / 窗口已过 / 空 id / 0 值降级）→ 放行，记录 id、帧基准归零。
- **`retry_count`**：公开字段，连续同名被抑制累计次数；`reset_for_rematch()` 清上一招与帧基准但**保留累计**，`reset_all()` 完全清零。
- 辅助：`configure()` / `window_frames()` / `get_elapsed_frames()` / `get_active_window_frames()` / `get_ai_poll_interval_sec()` / `total_allowed` / `total_suppressed`。

---

## ④ 导演层接入与快照（任务 ③）

- `_ready()`：`EncounterRulesV020.new(_boss_data.ai_poll_interval_sec, PlayerActionState.LOGIC_FPS)`；缺失 `boss_data` 时 `ai_poll=0` 降级。
- `_step()`：`simulate_boss` 真且 Boss 存在时每逻辑帧 `_rules.tick_frame(delta)`。
- **放行门**：`report_boss_move(move_id, cooldown_sec, fps=-1.0)` 包 `should_allow_move`；`_on_boss_move_landed()` 仅在 `_move is MoveData`（真实落地）时接入，被抑制则 `_suppressed_moves += 1` 且不计扣血；**`debug_boss_hit()` 传 `move=null`，完全走 v0.1.0 既有结算** —— 这是保证 20 条断言不回退的关键隔离。
- **重复挑战计数**：`rematch_count`（仅在 `_respawn_boss()` 成功时 +1，依赖缺失降级不虚增）。
- **胜负快照**：`_finish()` 累加 `wins` / `losses` / `outcome_history`。
- `get_snapshot()` **追加 9 个键，既有 10 个键名与取值口径逐字不变**：`rematch_count` / `wins` / `losses` / `outcome_history` / `retry_count` / `last_move_id` / `suppressed_moves` / `boss_phase` / `boss_defeated`（`boss_hp_ratio<=0` 推断，不读私有字段）。
- `debug_*` 5 个接口签名**逐字不变**：`debug_request_action` / `debug_boss_hit` / `debug_step` / `debug_kill_boss` / `debug_grace_rest`。

**接入边界（如实）**：`BossController` 只暴露 `move_landed`（落地帧）信号，未暴露抽招钩子，导演层不能改写既有件内部 `_poll_move()` 加权抽招。因此抑制判定在**规则层**实现并独立验证，导演层把判定作用于**落地招式的效果门 + 记录/计数**（`report_boss_move` 为显式入口），未侵入既有抽招。若要「抽招侧硬性拦截」，需既有件未来开放钩子 —— 不越界改既有件，登记为边界（§7）。

---

## ⑤ 真跑结论（`D:/Godot/Godot_v4.7.2-stable_win64.exe`）

命令口径（与 R21/R22/R23 一致）：G1 `--headless --path F:/Game/aierdengfahuan/godot --import` → G2 `--headless --path ... --check-only --script <script>` → G3 `--headless --path ... --quit`；真跑 `--headless --path ... --script <verify>`。

| 段 | 命令 | 结果 |
|---|---|---|
| G1 | `--headless --import` | `EXIT=0` |
| G2 | `--check-only --script`（4 个：rules_v020 / director / verify_v020 / verify_v010） | 全部 `EXIT=0` |
| G3 | `--headless --quit` | `EXIT=0` |
| 真跑回归 | `--script res://scripts/combat/verify_encounter_v010.gd` | `EXIT=0`，**20 PASS / 0 FAIL**， `RESULT=ALL_MATCH` |
| 真跑自测 | `--script res://scripts/combat/verify_encounter_v020.gd` | `EXIT=0`，**45 PASS / 0 FAIL**， `RESULT=ALL_MATCH` |

**全量日志 grep 汇总**（`teamwork/Rank-2/R24-*.log`）：

```
R24-gate1-import.log                           SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_COLON=0 FAIL_TAG=0
R24-gate2-checkonly-encounter_director.log     SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_COLON=0 FAIL_TAG=0
R24-gate2-checkonly-encounter_rules_v020.log   SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_COLON=0 FAIL_TAG=0
R24-gate2-checkonly-verify_encounter_v010.log  SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_COLON=0 FAIL_TAG=0
R24-gate2-checkonly-verify_encounter_v020.log  SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_COLON=0 FAIL_TAG=0
R24-gate3-quit.log                             SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_COLON=0 FAIL_TAG=0
R24-verify-v010-run.log                        SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_COLON=4 FAIL_TAG=0
R24-verify-v020-run.log                        SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_COLON=5 FAIL_TAG=0
```

- **三段门禁 `grep SCRIPT ERROR=0` 成立**（G1/G2/G3 全 0），四段 `EXIT=0`，`PASS=false` 命中 0，v010/v020 真跑 `SCRIPT ERROR=0` 亦成立。
- **v020 关键断言均为 PASS=true**：`dir_reset_boss_full ratio=1.0`、`dir_reset_phase_1 phase=1`、`dir_reset_not_defeated defeated=false`、`dir_rematch_inc_1 rematch=1`、`dir_rematch_inc_2 rematch=2 ratio=1.0`、`rules_same_suppressed retry=1`、`rules_spam_all_suppressed spam=20 retry=20`、`dir_rules_same_suppressed a1=true a2=false`、`dir_boss_zero_hp ratio=0.0 defeated=true`、`dir_missing_deps_degrade hp=100.0 rematch=0`。
- **既有 `ERROR:` 文本如实登记（非 `SCRIPT ERROR`、非断言失败、EXIT=0，未处理、未越界修改）**：
  - v010 4 条 / v020 5 条，两类：① `Can't use get_node() with absolute paths from outside the active scene tree.` —— 既有件（`BossController.world_state_path="/root/WorldState"`、`CombatEventBus.game_events_path="/root/GameEvents"`、`SaveDeltaWriter` autoload）在 `--script` 模式下的固有报错；v020 比 v010 多出的 2 条由本轮 `_respawn_boss` 新建 Boss 时 `fresh.call("_ready")` 触发（§2 边界 7）。② `Signal 'boss_defeated' is already connected ...` —— v010 既有装配逻辑与 `--script` 模式 autoload `_ready` 时序重复连接，出现在 `SELFTEST END` 之后，两条日志各 1 条。
  - 本轮新写代码已按踩坑提示规避：`_commit()` 用 `Engine.get_main_loop()`，`_inject_boss_deps()` 用 `root.get_node_or_null()`，验证脚本用 `root.get_node_or_null()`；既有件不得修改，故其固有文本保留。

---

## ⑥ v010 不回退机理（逐条核对）

`verify_encounter_v010.gd` **只读真跑，未改一字**，20 条断言全 PASS。导演层改动对其无影响的原因：
- `get_snapshot()` 只**追加**键，既有 10 键取值不变；v010 读取的 `player_hp / outcome / hits_taken / dodges / hits_landed / grace_rests / frame / pose / boss_hp_ratio` 全保留。
- `debug_*` 5 个签名逐字不变；`debug_boss_hit()` 传 `move=null`，规则层分支 `if _move is MoveData` 不进入 → iframe / hp_floor_zero / no_double_settle 原样。
- `simulate_boss=false`（v010 自测隔离）→ `_step` 不推进 Boss AI、不 tick 规则时钟。
- `debug_grace_rest()` 重建 Boss 后，新 Boss 仍是满血/阶段1/可受击；`player_hit_lands`（轻攻击命中）与 `debug_kill_boss` → I-2 → GameEvents → SaveDeltaWriter → `i2_defeat_flag` 全链路仍成立（新 Boss 的 `../CombatEventBus` 相对路径可解析，其 `_game_events` 已由 v010 装配注入）。真跑 `20 PASS / 0 FAIL ALL_MATCH` 已确认。

---

## ⑦ 未完成项 / 边界 / 阻塞

1. **击败 flag 边界**（§2-4）：真实运行时若 `world.boss_01_margit.defeated` 为 true，重建的新 Boss 会保持 `IDLE`，重复挑战需存档层清 flag。受 I-1「2 号不写 flag」+「不改既有件」约束，本轮未清、未双写，**待总指挥/3 号裁决**。验证模式不受影响。
2. **抽招侧硬性拦截**（§4 接入边界）：`BossController` 未暴露抽招钩子，导演层只能在落地招式做效果门；「抽招即拦截连续同名」需既有件未来开放钩子，**待既有件 owner 裁决**，本轮不越界改既有件。规则层抑制判定本身已完整实现并 45 条断言验证。
3. **美术锚点 v1 未确认**：按任务单本轮未重做素材、未改任何 PNG/tres 美术资源。
4. **既有 ERROR:/WARNING 文本**（§5）：登记不处理；`ObjectDB instances were leaked at exit` 类 G3 WARNING 与历史 R16~R23 同类，非 ERROR。
5. **并行协作说明**：`git status --short` 中其它 M/?? 条目为 Rank-1/3/4 与调度中枢并行产物，非本 AI 改动；本 AI 未自行 git（提交/暂存/改历史），仅做一次只读 `git status --short` 核对目录所有权。
6. **阻塞：无。** 本轮 5 项任务全部完成，真跑结论如上。

---

## 回执（已写到精确路径）

`F:/Game/aierdengfahuan/teamwork/command_center/ai/2/outbox/cmd-20261109-205253-725-A2.json`：
```json
{"task_id":"cmd-20261109-205253-725-A2","ai":2,"status":"done","result":"引用 DONE-R24.md 实际结论：R24 已独占扩展 encounter_director.gd（赐福休息采用重新实例化 Boss 子节点替换，HP 回满/阶段回1/清击败态，只复制公开 @export、不改 BossController 既有件；如实写明 is_node_ready+显式 _ready、/root 绝对路径回填、击败 flag 保持 IDLE、信号重连等边界），新写 RefCounted 纯逻辑 encounter_rules_v020.gd（should_allow_move(last_id,candidate,cooldown_sec,fps) 与 retry_count，冷却窗口=max(MoveData.cooldown_sec,BossData.ai_poll_interval_sec)×fps 数据驱动、不硬编码帧数），导演层接规则并加 rematch_count/wins/losses/outcome_history/retry_count/last_move_id/suppressed_moves/boss_phase/boss_defeated 到 get_snapshot()（既有 10 键与 5 个 debug_* 签名逐字不变），新写 verify_encounter_v020.gd 45 条断言覆盖重置后 Boss HP 比例回 1.0、连续同名抑制、重复挑战计数递增、0 血与连点边界、依赖缺失降级。引擎 4.7.2 真跑：v020=45 PASS/0 FAIL RESULT=ALL_MATCH，v010 回归=20 PASS/0 FAIL RESULT=ALL_MATCH 不回退；三段门禁 G1 --import / G2 --check-only --script(4 个脚本) / G3 --quit 全 EXIT=0 且 grep SCRIPT ERROR=0，v010/v020 真跑亦 SCRIPT ERROR=0。真跑日志存在既有件 /root 绝对路径 ERROR: 文本(v010 4 条/v020 5 条)与 boss_defeated 重复连接 1 条，非 SCRIPT ERROR、非断言失败、EXIT=0，如实登记未处理。只写 3 个自有 .gd 与 teamwork/Rank-2/ 及 outbox 回执，未改 courtyard.tscn/project.godot/encounter_v010.tscn/既有战斗件/美术资源/verify_encounter_v010.gd，未自行 git。未完成项：击败 flag 保持 IDLE 需存档层裁决、抽招侧硬性拦截需既有件开放钩子、美术锚点 v1 未确认；阻塞：无。"}
```

### 回执投递状态（如实）

- 本 AI 已把上述 JSON 写到**精确路径** `teamwork/command_center/ai/2/outbox/cmd-20261109-205253-725-A2.json`（写文件成功），未写到工程根 `command_center/`。
- 调度中枢 dispatcher 以 `poll_ms=600` 轮询消费 outbox，随即把回执归档到 `teamwork/command_center/dispatcher/receipts/cmd-20261109-205253-725-A2.json`（`json.load` 校验合法：`task_id/ai=2/status=done`，result 1348 字），并清空 4 个 ai 的 outbox（21:10 时刻全为空）—— 这是 R24 既定消费机制，非写入失败。
- `teamwork/command_center/dispatcher/dispatcher.log` 末尾 `[2026-11-09 21:10:20] ← 2 号 AI 回执 <cmd-20261109-205253-725-A2> 完成：引用 DONE-R24.md 实际结论：R24 已独占扩展 encounter_director.gd…` 明确记录调度中枢**已成功接收**。
- 为避免制造重复回执（dispatcher.log 中 Rank-1/4 已出现多条同名回执），本 AI 未重复重写 outbox；验收以 dispatcher.log 接收记录 + receipts 归档 JSON 为准，不谎报「outbox 当前仍有文件」。
