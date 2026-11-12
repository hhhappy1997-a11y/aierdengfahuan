# DONE-R34C.md · R34C「生产落盘订阅者补齐」交付报告（Rank-3）

> 轮次：`R34C / v0.11.0` ｜ 派单 id：`cmd-20261112-120028-972-A3` ｜ 执行 AI：`3（Rank-3 RPG / 世界 / 存档）`
> 真源：`teamwork/Rank-3/调度任务单-latest.json`（`task` 全文 + 公共契约 + 目录所有权）+ `teamwork/Rank-1/DONE-R34B.md` §4（信号签名逐字）+ `teamwork/00-协作契约.md` §3.3（A49~A55 / I-1~I-6）。以任务单为准。
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> 结论：**裁决 A56 落地：`PointsCommitOrchestrator` autoload 作为「生产落盘订阅者唯一入口」常驻，A55 落盘通道由「口径」升级为「已实现的生产链路」。真实输入（命中 / 清波 / 处决）→ 生产 autoload 订阅 → 磁盘 `user://` 实际落盘全链由 `verify_points_commit_production_v110.gd` 在独立 PID 临时槽机器判定：`28 PASS / 0 FAIL / RESULT=ALL_MATCH`，磁盘 `grace.trial.points=150`（清波 100 + 处决 50）、`grace.execution.performed=1`、重复领取被拒、生产 `slot_01` md5 前后一致。三段门禁全 `EXIT=0`、全工程 `SCRIPT ERROR=0 / Parse Error=0 / ERROR=0`、3 份既有 v110 回归全 `ALL_MATCH` 不回退、A38 节点 41 / uv `2/1/1` 不变。真跑迭代 2 次修复（惰性初始化 + 去重键口径）后全绿，如实登记、不冒充一次通过。**

---

## 1. 实际交付清单（本轮唯一写入方 = Rank-3）

| 文件 | 类型 | 实际改动 |
|---|---|---|
| `godot/scripts/rpg/points_commit_orchestrator.gd` | 新增 | **任务①生产编排层**（`extends Node`）：订阅 4 信号 / A55 唯一权威通道 / 去重键 / I-1 权威写入 / 「先落盘再改运行时实例」/ 十字段冻结 / 延迟绑定 + 重试 + 失败降级 + 去重 connect + 兜底释放 / 惰性初始化安全降级。 |
| `godot/scripts/rpg/verify_points_commit_production_v110.gd` | 新增 | **任务②生产可达回归**（A49 真实验收）：不加载 `presentation.gd`、不在验证脚本内模拟编排；实例化主场景 + 真实命中 / 清波 / 处决输入 → 读磁盘独立 PID 临时槽 → 28 条断言 + `RESULT=ALL_MATCH`。 |
| `godot/project.godot` | 修改 | **裁决 A56**：`[autoload]` 段**只新增 1 条** `PointsCommitOrchestrator="*res://scripts/rpg/points_commit_orchestrator.gd"`（+1 行注释）。既有 6 项 autoload、`run/main_scene`、`config/icon`、输入映射、渲染设置**逐字不动**（§5 贴段逐字核对）。 |
| `teamwork/00-协作契约.md` §3.3 | 追加 | **任务③口径登记**：仅追加 R34C 说明段（登记 A56 / 生产落盘订阅者唯一入口 / A55 升级为已实现生产链路）；不改历史条款 / I-1~I-6 / §3.1 §3.2 缺号。 |
| `teamwork/Rank-3/DONE-R34C.md` | 新增 | 本报告 |
| `teamwork/command_center/ai/3/outbox/cmd-20261112-120028-972-A3.json` | 新增 | 回执（§10 确认归档） |

### 只读未改（硬约束）
`hud.gd`（本轮 Rank-1 在改）、`encounter_director.gd`、`wave_trial_director.gd`、`presentation.gd`、`courtyard.tscn`（节点 41 / uv 2/1/1 / 节点名）、既有 `.tres`、素材、`world_state.gd` / `save_delta_writer.gd` 生产逻辑、其它 Rank 产出、既有验证脚本。回执写 `teamwork/command_center/`（非工程根）。未删除 `.workbuddy`。

---

## 2. 生产编排层落地详情（任务①）

### ① A55 点数落盘唯一权威通道
`_on_points_awarded(reason: String, points: int, source: String)`：`points` **原样累加一次**写 `grace.trial.points`（不臆断是否含倍率、不二次加工、不叠乘 `[PLACEHOLDER]` 倍率）；`reason=="execution"` 同一次原子写 `grace.execution.performed += 1`。`wave_cleared(index, points)` 基础值 / `combo_settled` 绝不入账。

### ② 四信号订阅 + 去重键（防重复领取）
| 信号 | 编排层用途 | 去重键 |
|---|---|---|
| `points_awarded(reason, points, source)` | ★ 点数落盘唯一权威通道 | 由配对信号解析 |
| `execution_performed(window_id, bonus_points)` | 配对键（保留不消费，同一次重放仍同键） | `exe:<window_id>` |
| `boon_draft_applied(index, ...)` | 防重复领取 + 登记 `grace.boon_draft.selected` / `cost_applied`（不碰 points / spent） | `boon:<index>` |
| `production_wave_modifier(wave_index, ...)` | 波次开始广播配对键 | `wave:<index>` |

去重表 `_claimed` 为**运行时门控态、不落盘**（不引入 Array / Dictionary 类 flag value、不破坏 §2 标量白名单与十字段冻结）。无配对键时以 `(reason, points, source)` 指纹去重（同一事件重放 → 同键 → 拒绝二次领取）。

### ③ I-1 权威写入 + 「先落盘再改运行时实例」（五步，不得颠倒）
① 由生产信号取结算 → ② 计算新值（`grace.trial.points` 单调递增、只增不减、绝不写 `removals`；余额 `points − spent_points ≥ 0` 前置门控；三段式正则 + 标量白名单校验）→ ③ ★ `commit(reason)` 按 **SaveDelta 十字段冻结 / `schema_version=3`** 原子写（`.tmp → flush → rename_absolute → delta.json + .bak`）→ ④ ★ **落盘成功后**才更新 WorldState 运行时实例（`_apply_snapshot` 注入磁盘真值）并 `emit committed` / `points_committed` → ⑤ ③ 失败则不改内存、如实 `push_warning`、不写盘、不 emit。reason 仅写 `meta.last_commit_reason`、不新增顶层字段、不触发迁移；旧档缺 key 由 `get_flag(key, default)` 回落基线、不升级不重置。磁盘为唯一权威。

### ④ 延迟绑定 / 重试 / 失败降级 / 兜底释放
- autoload 早于主场景入树 → `_ready()` 用 `call_deferred("_deferred_bind")` 延迟绑定；`_scan_hud()` 递归扫 root，按「script `resource_path == hud.gd`」或「4 个 R34 信号特征」鸭子类型识别 HUD（不静态引用 `class_name`）；`bind_hud()` 为确定性显式入口。
- 重试：未找到 HUD 时递归 `call_deferred`，最多 `MAX_BIND_RETRY=6` 次；耗尽 → `push_warning` 降级（**不订阅 / 不写盘 / 不报错**）。
- connect 前用 `get_signal_connection_list()` 去重；`_exit_tree` / `NOTIFICATION_WM_CLOSE_REQUEST` 兜底释放。
- **安全降级**：`--script` 模式下 autoload `_ready()` 可能不被 flush（引擎退出阶段才补跑），编排层对 `RegEx` / 运行时镜像做**惰性初始化**兜底，绝不 null 解引用；无 HUD 的纯 `--headless --import` / `--check-only --script` 与无输入的 GATE-3 均不报错、不写盘（真跑实证）。

### ⑤ 独立 PID 临时槽
生产默认 `user://saves/slot_01/delta.json`；验证经 `configure_slot(user://saves/verify_r34c_<pid>)` 注入独立临时槽（**只改落盘目标路径、不改十字段结构、不改 `project.godot`**），生产 `slot_01` 全程只读 md5 前后对照。

---

## 3. 生产可达回归（任务② · A49 真实验收）

**与 R34 三态夹具（`verify_v110_save_commit.gd`）的根本区别（不自模拟冒充）**：本件不加载 `presentation.gd`；点数累加 / 去重 / 落盘全部由**生产脚本** `res://scripts/rpg/points_commit_orchestrator.gd`（`project.godot` 注册的同一文件）执行；验证脚本只做「实例化主场景 → 注入真实输入 → 读磁盘存档 → 断言」。真跑实证 `--script` 模式下引擎**已装配 autoload**（`编排层实例来源=autoload`），验证脚本另对 autoload 显式补 `_ready()`；若引擎未装配则按注册项挂载**同一生产脚本**（不在验证脚本内另写编排逻辑，如实登记）。

真实输入链（复用 R34B 生产链驱动口径）：
```
真实 light_attack 命中(debug_request_action + debug_step)
  → start_trial → debug_advance(999) → on_encounter_finished(true)
      → HUD._r34_on_wave_cleared → points_awarded("wave_cleared", 100, ...)  → 编排层落盘 +100
  → close_boon_draft（清波卡片 open 时 HUD 键路径吞 F，关闭后 F 才走 _try_execution_input）
  → 连续命中削韧开窗 → 真实 F 键 process_key_event
      → execution_performed + points_awarded("execution", 50, ...)          → 编排层落盘 +50 / performed=1
  → 重放同一 points_awarded("execution", 50) ×2 → exe: 去重键命中 → 拒绝（不二次加点）
```
读磁盘 `user://saves/verify_r34c_<pid>/delta.json` 的 `grace.trial.points`，断言全链落盘 / 只增不减 / 重复不加点 / 旧档缺 key 回落基线 / 生产 `slot_01` 不污染 / 十字段冻结 / `schema_version=3` / `removals` 空 / 余额 ≥ 0 / 三段式正则 / A38 / 生产订阅者存在性。

---

## 4. 真跑输出原文（三段门禁 + 全工程 G3）

统一命令前缀：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`
引擎版本行：`4.7.2.stable.official.ed1daf0bf` / `Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org`
纯引擎日志：`/tmp/r34c_g1.log` / `/tmp/r34c_co.log` / `/tmp/r34c_verify3.log` / `/tmp/r34c_engine.log`（系统临时目录，未写入工程内）。

### GATE-1 `--headless --import`
```
GATE1_EXIT=0
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[ DONE ] first_scan_filesystem
[ DONE ] update_scripts_classes
[ DONE ] loading_editor_layout
```

### GATE-2a `--check-only --script`（2 件，全 `EXIT=0`）
```
check-only res://scripts/rpg/points_commit_orchestrator.gd         EXIT=0
check-only res://scripts/rpg/verify_points_commit_production_v110.gd EXIT=0
```

### GATE-2b `--headless --script <verify>`（本轮新增生产可达回归，完整 `[V110-PROD]` 输出）
```
[V110-PROD] ==== verify_points_commit_production_v110 真跑开始 | R34C / v0.11.0 | cmd-20261112-120028-972-A3 ====
[V110-PROD] A49：不加载 presentation.gd；不在验证脚本内模拟编排；编排层=生产 autoload 同一脚本
[V110-PROD] RUN=5284 pid=5284 slot=user://saves/verify_r34c_5284 production_md5_before=52a32248122a05fb6eda0687ee1ba5b9
[V110-PROD] P00 独立 PID 临时槽与生产 slot_01 物理隔离 PASS=true | slot=user://saves/verify_r34c_5284
[V110-PROD] S01 project.godot 已注册 PointsCommitOrchestrator autoload（A56） PASS=true | 注册行存在
[V110-PROD] S02 生产编排层脚本文件存在（验证脚本不另写编排逻辑） PASS=true | path=res://scripts/rpg/points_commit_orchestrator.gd
[V110-PROD] S03 生产编排层源码含 points_awarded 订阅回调（静态存在性证据） PASS=true | _on_points_awarded + BOUND_SIGNALS 均在
[V110-PROD] A38-1 courtyard.tscn 静态 [node] 行数 == 41（只读不改） PASS=true | count=41 expected=41
[V110-PROD] A38-2 uv 2/1/1 原样（Vector3(2,2,1)×1 + Vector3(1,1,1)×2） PASS=true | uv_2x=1 uv_1x=2
[V110-PROD] 编排层实例来源=autoload（--script 模式 autoload 未装配时按注册项挂同一生产脚本）
[V110-PROD] P02 生产编排层实例就位（与 project.godot 注册同一脚本） PASS=true | source=autoload
[V110-PROD] P01 编排层已注入独立 PID 临时槽（落盘前） PASS=true | slot=user://saves/verify_r34c_5284
[V110-PROD] 主场景已实例化入树 | name=Courtyard（未加载 presentation.gd）
[V110-PROD] P03 主场景关键节点可寻址（Hud / EncounterRoot / WaveTrialDirector） PASS=true | hud=true enc=true wave=true
[R34C][PCO] 生产订阅者已绑定 HUD | signals=4 slot=user://saves/verify_r34c_5284（A55 唯一权威通道）
[V110-PROD] P04 生产编排层 bind_hud 成功（4 信号订阅） PASS=true | bound=true
[V110-PROD] P05 ★ 生产订阅者存在性（运行时）：4 信号 connection_list 均含编排层回调 PASS=true | subs={ "points_awarded": true, "execution_performed": true, "boon_draft_applied": true, "production_wave_modifier": true }
[V110-PROD] P06 get_status 反映已绑定 + 独立槽 PASS=true | bound=true slot=user://saves/verify_r34c_5284
[V110-PROD] R01 真实 light_attack 命中输入已注入（debug_request_action + debug_step） PASS=true | steps=3
[V110-PROD] R02 真实清波输入（start_trial → debug_advance → on_encounter_finished(true)） PASS=true | finished=true
[V110-PROD] 磁盘回读 | after_wave | grace.trial.points=100 delta_exists=true
[V110-PROD] R03 真实 F 处决输入（破韧开窗 → process_key_event(F) → request_execution） PASS=true | window_open=true
[V110-PROD] 磁盘回读 | after_exec | grace.trial.points=150 delta_exists=true
[V110-PROD] R03b 真实处决 → 编排层落 grace.execution.performed（非重放贡献） PASS=true | performed=1
[V110-PROD] 编排层观测：commit_count=2 points=150 performed=1 claimed=["auto:wave_cleared:100:wave_trial_director.wave_cleared", "exe:"]
[V110-PROD] R04 生产编排层真实 commit 次数 > 0（非验证脚本自模拟） PASS=true | commit_count=2
WARNING: [R34C][PCO] 重复领取拒绝 | event_key=exe: reason=execution points=50 source=stagger_service.try_execute
WARNING: [R34C][PCO] 重复领取拒绝 | event_key=exe: reason=execution points=50 source=stagger_service.try_execute
[V110-PROD] R05 同一事件重复触发不二次加点（编排层去重键门控） PASS=true | points a=150 b=150 c=150（b→c 重复触发被拒）
[V110-PROD] 磁盘回读 | after_dup | grace.trial.points=150 delta_exists=true
[V110-PROD] D01 ★ 真实输入 → 生产 autoload 订阅 → 实际落盘：磁盘 delta.json 存在可解析 PASS=true | path=user://saves/verify_r34c_5284/delta.json
[V110-PROD] D02 ★ grace.trial.points 已落盘且 > 0（A55 唯一权威通道） PASS=true | points=150.0
[V110-PROD] D03 grace.execution.performed 等已登记三段式 flag 已落盘 PASS=true | performed=1.0
[V110-PROD] D04 点数只增不减（磁盘逐次回读序列单调不减） PASS=true | trace=[100, 150, 150]
[V110-PROD] D05 SaveDelta 十字段齐全、无额外顶层字段（冻结） PASS=true | extra=[] missing=[]
[V110-PROD] D06 schema_version=3、removals 恒空、绝不写 removals PASS=true | schema=3.0 removals=[]
[V110-PROD] D07 全部落盘 flag key 通过三段式正则 PASS=true | keys=2 bad=[]
[V110-PROD] D08 余额 points - spent_points >= 0 PASS=true | points=150 spent=0 balance=150
[V110-PROD] D09 旧档缺 grace.trial.points → get_flag 回落基线 0（不升级/不重置/不迁移） PASS=true | get_flag=0 default=0
[V110-PROD] D10 生产 slot_01 md5 前后一致（全程不写 slot_01） PASS=true | md5=52a32248122a05fb6eda0687ee1ba5b9
[V110-PROD] SUMMARY pid=5284 slot=user://saves/verify_r34c_5284 pass=28 fail=0 total=28
[V110-PROD] RESULT=ALL_MATCH
[V110-PROD] ==== 真跑结束 ====
VERIFY_EXIT=0
```

> **生产落盘真实发生的证据**：磁盘 `user://saves/verify_r34c_5284/delta.json` 存在可解析，`flags.grace.trial.points=150`（清波 100 + 处决 50，逐次回读 `100 → 150 → 150`）、`grace.execution.performed=1`；`commit_count=2`；重复领取 2 条 `WARNING` 实证去重门控生效；生产 `slot_01` md5 `52a32248122a05fb6eda0687ee1ba5b9` 前后一致（未被污染）。

### GATE-3 `--headless --quit` + 既有回归复跑（全工程 G3 · 纯引擎日志 `/tmp/r34c_engine.log`）
```
G3_QUIT_EXIT=0
REG_V110_EXIT=0      verify_production_chains_v110.gd
REG_CBR_EXIT=0      verify_combo_runtime_v110.gd
REG_SAVE_EXIT=0     verify_v110_save_commit.gd

=== 统计 ===
SCRIPT_ERROR_COUNT=0        （grep SCRIPT ERROR=0 期望，达标）
PARSE_ERROR_COUNT=0
ERROR_PREFIX_COUNT=0

=== 回归 SUMMARY / RESULT ===
[V110]     SUMMARY pass=38 fail=0 total=38 ok=true   / RESULT=ALL_MATCH
[V110-CBR] SUMMARY pass=28 fail=0 total=28 ok=true   / RESULT=ALL_MATCH
[V110]     SUMMARY mode=all pid=26268 slot=user://saves/verify_v110_26268 pass=64 fail=0 / RESULT=PASS

=== GATE-3 编排层 / 主场景关键行 ===
[WaveTrial] 持久化基线读回：dungeon.wave_trial.best_wave=3 / dungeon.wave_trial.completed=true / grace.trial.points=450（经 WorldState.get_flag）
[R34C][PCO] 生产订阅者已绑定 HUD | signals=4 slot=user://saves/slot_01（A55 唯一权威通道）
[R34][HUD] 生产链装配完成 | stagger_bound=true boon_bound=true combo_bound=true combo_signals=true wave_cleared=true wave_started=true visible=true
WARNING: [R34C][PCO] HUD 未就绪（重试 6 次）→ 绑定降级：不订阅、不写盘
```
> 最后 1 条 `WARNING` 来自「无主场景 HUD」的 `--script` 回归进程，正是任务单要求的**安全降级**（不报错、不写盘）；GATE-3 主场景有 HUD 且无玩家输入 → 绑定成功但不写盘（`slot_01` 基线保持 450）。所有 `WARNING` / 降级均非 `SCRIPT ERROR`、非 `Parse Error`、非 `ERROR:` 前缀。

### A38 不变
`courtyard.tscn` 静态 `[node]` 行数 `41` / `Vector3(2,2,1)×1 + Vector3(1,1,1)×2`（uv 2/1/1）由 `A38-1 / A38-2` 真跑断言 + GATE-3 `SceneState node_count=41` 实证，文件只读未改。

### project.godot `[autoload]` 段逐字核对（既有 6 项未动，新增 1 项）
```
[autoload]
WorldState="*res://scripts/rpg/world_state.gd"
GameEvents="*res://scripts/rpg/game_events.gd"
SaveSystem="*res://scripts/world/save_system.gd"
ChunkManager="*res://scripts/world/chunk_streaming.gd"
SceneRouter="*res://scripts/core/scene_router.gd"
SaveDeltaWriter="*res://scripts/save_delta_writer.gd"
; R34C / 裁决 A56：生产落盘编排层 autoload（points_awarded 唯一权威通道订阅者），其余配置逐字不动。
PointsCommitOrchestrator="*res://scripts/rpg/points_commit_orchestrator.gd"
```

---

## 5. 生产订阅者存在性证据（Grep 结果 + 运行时日志）

### 5.1 静态 Grep（对照总指挥核实的「改前缺口」）
改前（总指挥 Grep 核实）：`points_awarded` 仅出现在 `hud.gd`（发射）、`encounter_director.gd`（注释）、`verify_production_chains_v110.gd` 与 `verify_v110_save_commit.gd`（两份验证脚本）—— **生产运行时零订阅者**。

改后本轮 Grep（`godot/scripts` 全量 `points_awarded` 命中，节选新增的生产订阅点）：
```
godot/scripts/rpg/points_commit_orchestrator.gd:49:  "points_awarded", "execution_performed",        # BOUND_SIGNALS 订阅清单
godot/scripts/rpg/points_commit_orchestrator.gd:148: var sig_ok: bool = n.has_signal("points_awarded") \   # HUD 鸭子类型识别
godot/scripts/rpg/points_commit_orchestrator.gd:258: # ① A55 唯一权威通道：points_awarded(reason, points, source)
godot/scripts/rpg/points_commit_orchestrator.gd:261: func _on_points_awarded(reason: String, points: int, source: String) -> void:   # ★ 生产订阅回调（新增）
godot/scripts/rpg/points_commit_orchestrator.gd:280: if _commit("points_awarded_" + reason, writes, points, new_points):            # ★ 落盘点（新增）
```
> 由「发射 / 注释 / 验证脚本」补齐为「**生产编排层订阅 → 原子落盘**」，`PointsCommitOrchestrator` autoload 常驻（A56 注册行见 §4）。

### 5.2 运行时日志 / 机器判定
```
[R34C][PCO] 生产订阅者已绑定 HUD | signals=4 slot=user://saves/verify_r34c_5284（A55 唯一权威通道）
P05 ★ 生产订阅者存在性（运行时）：4 信号 connection_list 均含编排层回调 PASS=true
    subs={ "points_awarded": true, "execution_performed": true, "boon_draft_applied": true, "production_wave_modifier": true }
S01 project.godot 已注册 PointsCommitOrchestrator autoload（A56） PASS=true
R04 生产编排层真实 commit 次数 > 0（非验证脚本自模拟） PASS=true | commit_count=2
D01 ★ 真实输入 → 生产 autoload 订阅 → 实际落盘 PASS=true
```

---

## 6. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 裁决 A56：只新增 1 条 autoload、其余配置逐字不动（GATE-1 / GATE-3 `EXIT=0` + §4 逐字核对）；② 任务①：`points_commit_orchestrator.gd` 订阅 4 信号、A55 唯一权威通道、`wave/exe/boon` 去重键、I-1 权威写入 `grace.trial.points` / `grace.execution.performed`、严格「先落盘再改运行时实例」（commit 原子写成功后 `_apply_snapshot` + emit，失败不改内存）、SaveDelta 十字段冻结 + `schema_version=3`、延迟绑定 / 重试 / 失败降级 / 去重 connect / 兜底释放 / 惰性初始化安全降级；③ 任务②：`verify_points_commit_production_v110.gd` 在不加载 `presentation.gd`、不自模拟编排的进程里真跑 `28 PASS / 0 FAIL / RESULT=ALL_MATCH`，**磁盘实际落盘 `grace.trial.points=150`**，点数只增不减、重复触发不二次加点、旧档缺 key 回落基线、生产 `slot_01` 不被污染；④ 任务③：契约 §3.3 只追加 R34C 段，登记 A56 / 唯一入口 / A55 升级为已实现生产链路；⑤ 任务④：三段门禁全 `EXIT=0`、全工程 `SCRIPT ERROR=0 / Parse Error=0 / ERROR=0`、3 份既有 v110 回归 `38+28+64=130 PASS` 全 `ALL_MATCH`、A38 节点 41 / uv 2/1/1 不变；⑥ 目录所有权：只写 2 个新工程脚本 + `project.godot` 1 行 + 契约追加段 + Rank-3 文档 + 回执。 |
| **失败** | 无（最终真跑门禁与断言全通过）。**如实登记过程**：首轮真跑 `VERIFY_EXIT=1`（`--script` 模式 autoload `_ready()` 未 flush → `_re==null` 合法 flag key 被误判、不落盘）；次轮 `VERIFY_EXIT=1`（递增 fallback 去重键导致同事件重放二次加点、且清波卡片 open 吞 F 令真实处决未触发）。两轮均已按实际输出定位根因并修复（惰性初始化 / `(reason,points,source)` 指纹去重 / `close_boon_draft()` 后真实处决），第三轮全绿；不冒充一次通过。 |
| **需用户确认** | ① 点数落盘权威口径分叉（R34B §4.4 延续，见 §8 第 1 条）；② 处决 `window_id` 为空串导致不同窗口 `exe:` 键合并；③ 无配对键时参数指纹去重的保守合并口径；④ `grace.trial.spent_points` 抉择扣费是否由编排层接管；⑤ 15~20 秒实机录屏目视由总指挥本轮亲自重跑（headless 无像素级目视，本轮不重复录屏）；⑥ 全部 `[PLACEHOLDER]` 数值待人工试玩校准；⑦ 既有 `WARNING` / 降级日志是否纳入后续清理。 |

---

## 7. 未完成项（如实登记，交总指挥排期）

1. **`grace.trial.spent_points` 抉择扣费出口**：本轮 `boon_draft_applied` 只登记 `grace.boon_draft.selected` / `cost_applied` 两个已登记 flag 与 `boon:<index>` 去重键，**未**把抉择代价映射进 `spent_points`（涉及 `[PLACEHOLDER]` cost→points 映射与余额门控）。契约 R27 §9.9 / R34 的 spent 出口仍由其它链路负责，本轮不擅自扩大写入面。
2. **`points_awarded` 与导演层倍率后值分叉**：真实链路里 `points_awarded("wave_cleared", 100, ...)` 携带的是基础 pts，ComboService 倍率后值（160）在导演层；A55 要求「原样采信、不二次加工」，故落盘值 = 100。口径分叉延续 R34B §4.4，待裁决。
3. **处决 `window_id` 上游数据**：真跑实证 HUD `execution_performed` 的 `window_id` 为空串 → 编排层 `exe:` 键；同一次处决重放去重正确，但不同处决窗口会合并，需 Rank-1 侧提供唯一 `window_id` 或另定配对键。
4. **实机录屏目视**：headless 真跑无帧缓冲，15~20 秒实机目视按公共契约由总指挥本轮亲自重跑，本轮不重复录屏、不冒充目视通过。
5. `[PLACEHOLDER]` 数值与演示帧点校准（调参只改表 / 常量）；HD-2D 全绿（A41 未达）、`128bit` 歧义（A43 保留）沿用既有登记。

---

## 8. 待总指挥裁决项（只登记、不擅改）

1. **点数落盘权威口径（重点，R34B §4.4 / DONE-R34 §8 第 1 条延续）**：`points_awarded` 的 `points` 在真实生产链路里是基础 pts（100），而 combo 倍率并入导演层落盘值（160）。A55 裁决「原样采信、不二次加工」，本轮按此落地（落盘 100 / 处决 50 = 150）。是否统一 `points_awarded` 与导演层倍率后值、或明确「基础 pts 即权威」，请裁决。
2. **`wave_cleared(index, points)` / `combo_settled(total, base, rank, mult)` 是否仅作 HUD 展示 / 对账**（A55 ②③ 已定「绝不入账」），是否需额外对账日志，请裁决。
3. **去重键配对口径**：`points_awarded` 本身不带 `window_id` / `wave_index`，本轮按任务①从 `execution_performed` / `production_wave_modifier` / `boon_draft_applied` 取 `exe:/wave:/boon:` 键；无配对键时回落 `(reason, points, source)` 指纹（连续同参事件保守合并）。该回落口径是否满足「同一清波不二次加点」的长期语义，请裁决。
4. **处决 `window_id` 为空串**：是否要求 Rank-1 在 `execution_performed` 提供唯一窗口 id，避免不同窗口 `exe:` 键合并。
5. **`grace.trial.spent_points` 抉择扣费归属**：是否由 `PointsCommitOrchestrator` 接管（带余额门控 + `[PLACEHOLDER]` cost→points 映射），还是维持跨 Rank 既有编排。
6. **既有 autoload / 降级 `WARNING`**：本轮 `ERROR_PREFIX_COUNT=0`，但 `--script` 无 HUD 场景有「绑定降级」`WARNING`、`SaveSystem` 工具模式 `WARNING`、`ObjectDB instances leaked` 等既有日志，是否纳入后续清理由总指挥裁决。
7. **实机录屏回看**：headless 真跑无帧缓冲，如实登记为后续动作 / 需用户确认（不冒充目视通过）。

---

## 9. 硬约束遵守声明

- 唯一写入方 = Rank-3：仅 `godot/scripts/rpg/points_commit_orchestrator.gd`（新增）、`godot/scripts/rpg/verify_points_commit_production_v110.gd`（新增）、`godot/project.godot`（**A56 特别授权：只新增 1 条 autoload + 1 行注释，既有 autoload / `run/main_scene` / `config/icon` / 输入映射 / 渲染设置逐字不动**）、`teamwork/00-协作契约.md` §3.3 追加段、`teamwork/Rank-3/DONE-R34C.md`、回执；其余文件（`hud.gd` / `encounter_director.gd` / `wave_trial_director.gd` / `presentation.gd` / `courtyard.tscn` / 既有 `.tres` / 素材 / 其它 Rank 产出 / `world_state.gd` / `save_delta_writer.gd` 生产逻辑）只读未改。
- `courtyard.tscn` 静态节点数 `41` / uv `2/1/1` / 节点名（A38）未破坏（A38-1/2 真跑断言 + GATE-3 `SceneState node_count=41` 实证）。
- 纯逻辑边界（I-1 / A50）：落盘唯一写入方 = Rank-3 编排层；Rank-1 只发信号不写盘（既有）、Rank-2 不写存档；验证脚本不写生产 `slot_01`、不在验证脚本内模拟编排逻辑。
- Godot4 `--script` 纪律：`Engine.get_main_loop() as SceneTree` 取 root、不用 `get_tree()` / 不用 `/root/...` 绝对路径字符串、显式 `call("_ready")` / `_r34_bootstrap()`、资源 `CACHE_MODE_IGNORE` 回读、connect 前 `get_signal_connection_list()` 去重 + `_exit_tree` / `NOTIFICATION_WM_CLOSE_REQUEST` 断开释放路径；独立 PID 临时槽三态 / 生产验证不碰 `slot_01`。
- 零付费、零外部依赖、不启 GPU job；不伪造产物、不谎报成功、不自行 git；未删除 `.workbuddy`。
- 默认不刺探：未扫目录做进度巡检、未写只读探针 / 巡检脚本；仅按任务单要求读取接口文件与回执目录，真跑日志落在系统临时目录（`/tmp`），未写入工程内。

---

## 10. 回执与中枢归档

- 回执路径（**`teamwork/command_center/`，非工程根**）：
  `teamwork/command_center/ai/3/outbox/cmd-20261112-120028-972-A3.json`
- 四字段：`{"task_id":"cmd-20261112-120028-972-A3","ai":3,"status":"done","result":"引用本报告实际结论"}`。
### 回执写后确认（中枢归档 · 实测，非推断、不伪造、不重放）

```
[中枢自动处理] 回执 <cmd-20261112-120028-972-A3> 由 ai/3/outbox/ 归档至 dispatcher/receipts/
· ai/3/outbox/ 写后已清空（中枢正常回收，与 DONE-R34B §10 口径一致）
· dispatcher/receipts/cmd-20261112-120028-972-A3.json  VALID_JSON=True
  keys=['ai','result','status','task_id'] | task_id 正确 | ai=3 | status=done | result 引用 DONE-R34C.md 实际结论
· dispatcher/ledger.jsonl 新增 1 条：id=cmd-20261112-120028-972-A3 status=done finished_at=2026-11-12 12:21:42，result 与回执逐字一致
· ai/3/status.json：state=idle / current_task="" / completed=39 / last_seen=2026-11-12 12:21:42
```

> 回执写后确认归档到 `teamwork/command_center/dispatcher/receipts/`（**是 teamwork/command_center/，不是工程根**）；
> 归档与台账更新由中枢流程完成，Rank-3 只写 outbox、未自建 / 未伪造归档、未重放。
