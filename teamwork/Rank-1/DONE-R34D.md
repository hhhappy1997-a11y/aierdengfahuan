# DONE-R34D.md · R34D「让连击评级真正影响赐福点数」交付报告（Rank-1）

> 轮次：`R34D / v0.11.0` ｜ 派单 id：`cmd-20261112-122524-297-A1` ｜ 执行 AI：`1（Rank-1 引擎架构与渲染执行）`
> 真源：`teamwork/Rank-1/调度任务单-latest.json`（`task` 全文 + 公共契约 + 目录所有权）+ `teamwork/Rank-2/DONE-R34.md` §3（ComboService 接口签名）+ `teamwork/Rank-3/DONE-R34C.md`（生产落盘现状）。**以任务单为准**。
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org`）
> 结论：**裁决 A57 落地——`points_awarded(reason, points, source)` 的 `points` 改为携带 ComboService 倍率后最终结算值（A54 唯一实例 `get_last_settlement()` / `settle()`），无有效结算回落基础值并 `push_warning` 告警、每条事件只发一次；`wave_cleared(index, points)` 保留基础值、`combo_settled` 绝不二次入账、Rank-3 `PointsCommitOrchestrator` 继续「原样采信」（A55 不变、文件未改）。真实回归实证 `100 × A级1.6 = 160` 落在 `points_awarded` 与磁盘 `grace.trial.points`（`verify_combo_runtime_v110.gd`），另 `150 × 1.6 = 240` 落在 `points_awarded` 与磁盘（`verify_production_chains_v110.gd` 第 2 波）；R34C 既有生产回归 `150`（清波 100 D 级 + 处决 50）不回退。三段门禁全 `EXIT=0`、全工程 `SCRIPT ERROR=0 / Parse Error=0 / ERROR=0`、两份扩展自测 `51+39=90 PASS / 0 FAIL` 均 `RESULT=ALL_MATCH`、A38 节点 41 / uv `2/1/1` 不变、5 份既有 `.tres` md5 与 R34 基线逐字一致。真跑迭代 2 次（首轮 6 FAIL → 定位根因修复 → 全绿），如实登记、不冒充一次通过。**

---

## 1. 交付清单（实际落地文件，本轮唯一写入方 = Rank-1）

| 文件 | 类型 | 实际改动 |
|---|---|---|
| `godot/scripts/hud.gd` | 修改（**1 处精确 Edit**：`_r34_on_wave_cleared`） | **任务① 发射值修正**：从 `get_combo_service()` 的 A54 唯一 ComboService 实例取最终结算值（`get_last_settlement()` 的 `total_points`）作为 `points_awarded` 的 `points`；无有效结算 → 回落基础值 + `push_warning` 告警（失败降级、不静默吞掉）；每条 `wave_cleared` 只发 **1 次** `points_awarded`；处决 / 抉择分支逐字未动；`wave_cleared(index, points)` 第二参仍为基础值；不改 `combo_settled` 入账路径。 |
| `godot/scripts/render/verify_production_chains_v110.gd` | 修改（**追加** A57 全链组 + 3 处接线） | **任务②**：`_initialize()` 追加 `_t_a57_full_chain()`、`_finish()` 追加编排层释放、文件尾追加 A57 常量/变量/辅助函数/全链组（13 条断言）。既有 38 条断言**逐字不删不放宽**。 |
| `godot/scripts/render/verify_combo_runtime_v110.gd` | 修改（**追加** A57 全链组 + 6 处接线） | **任务②**：常量/变量/探针（`_on_points_awarded`）、`_initialize()` 追加 `_a57_bind_orchestrator()` 与 `_a57_assert_full_chain()`、`_bind_combo_probes()` 追加探针连接、`_finish()` 追加释放、文件尾追加 A57 辅助/全链组（11 条断言）。既有 28 条断言**逐字不删不放宽**。 |
| `teamwork/Rank-1/DONE-R34D.md` | 新增 | 本报告（交付清单 / 真跑输出原文 / 验收三态 / 倍率后值实证 / 未完成项 / 待裁决项）。 |
| `teamwork/command_center/ai/1/outbox/cmd-20261112-122524-297-A1.json` | 新增 | 本轮回执（§10 确认中枢归档）。 |

### 只读未改（硬约束，逐字核对）
`points_commit_orchestrator.gd`（Rank-3）、`project.godot`（Rank-3）、`teamwork/00-协作契约.md`（Rank-3）、`encounter_director.gd`（本轮只读）、`wave_trial_director.gd`（Rank-2）、`presentation.gd`、`courtyard.tscn`、5 份既有 `.tres`、`verify_points_commit_production_v110.gd`（Rank-3 既有回归，只读复跑）、`combo_service.gd` / `combo_config.gd` / `boon_draft_service.gd`、素材、其它 Rank 产出。未删除 `.workbuddy`。

---

## 2. 任务① · 发射值修正详情（裁决 A57）

### 2.1 分叉根因（读源码实证，非推断）
`wave_trial_director.gd::_clear_wave()` 顺序（只读核对）：
```
604:  var combo_result: Dictionary = _combo.settle(base_for_combo)   # A 级 → 100×1.6=160
609:  settled_points = maxi(0, int(combo_result.get("total_points", ...)))
611:  _last_settled_points = settled_points
618:  _points_total += settled_points
620:  wave_cleared.emit(_index, pts)                                  # 第二参仍是基础 pts=100
```
即 **导演层已按倍率结算 160，但 `wave_cleared` 信号只带基础 100**；HUD 旧代码 `points_awarded.emit("wave_cleared", pts, ...)` 直接取了信号的基础值 → Rank-3 编排层「原样采信」落盘 100，倍率机制在生产链路上失效（R34C §7 第 2 条登记的分叉）。**`settle()` 先于 `wave_cleared.emit()`**，故 HUD 回调触发时 `get_last_settlement()` 已是本次清波的倍率后结算，取源成立。

### 2.2 改后逻辑（`hud.gd::_r34_on_wave_cleared`）
1. `base_pts = int(points)`（基础值，仍用于 `on_wave_cleared()` 卡片展示 / 事件键，A57 口径）。
2. `combo = get_combo_service()`（A54 唯一实例 `_r34_combo`，由 `_r34_bootstrap()` 经 `wave.get_combo_service()` 复用，与导演层 `_combo` 同一 Object）。
3. `last = combo.get_last_settlement()`；当 `ok && settled && total_points > 0` 时 `final_pts = total_points`（**倍率后最终结算值**）。
4. 否则回落：尝试一次 `combo.settle(base_pts)`（幂等，异常/未结算时补结算）；仍无有效结算 → `final_pts = base_pts` 且 `push_warning("[R34D][HUD] A57 降级：…回落基础值…（失败降级，不静默吞掉）")`。
5. **只发一次** `points_awarded.emit("wave_cleared", final_pts, "wave_trial_director.wave_cleared")`，随后 `_r34_points_count += 1` / 刷新可见层 / 打印 `index / base / final / settled` 便于对账。

### 2.3 口径保持
- **A46**（Tab 单一仲裁者）、**A48**（玩家真实可达命中链）、**A50**（Rank-1 只发信号不写盘）逐字未动：本函数不含 `set_flag` / `commit` / `FileAccess.open`，既有静态断言 `e3`（`verify_production_chains_v110.gd`）与 `w1`（`verify_combo_runtime_v110.gd`）真跑 `PASS=true`。
- **处决分支**（`hud.gd:1546` `points_awarded.emit("execution", bonus, ...)`）与**抉择分支**逐字未动。
- **`wave_cleared(index, points)`** 仍发基础值（HUD 展示 / 事件键）；**`combo_settled`** 只订阅更新 `_r34_combo_view` 视图，绝不触发 `points_awarded`；编排层 `BOUND_SIGNALS` 不含 `combo_settled` / `wave_cleared`，绝不二次入账。
- **Rank-3 `PointsCommitOrchestrator` 不改动**（A55 不变）：仍「原样采信」`points_awarded.points` 累加一次写 `grace.trial.points`。

---

## 3. 任务② · 真实回归（两份脚本扩展）

- **保留既有断言**：`verify_production_chains_v110.gd` 既有 `38 PASS`、`verify_combo_runtime_v110.gd` 既有 `28 PASS` 全部逐字保留、不删不放宽；A57 组为**追加**，输出仍 PASS/FAIL + `SUMMARY` + `RESULT=ALL_MATCH`。
- **不模拟编排 / 不重复挂载**：两份脚本均优先取引擎已装配的 `PointsCommitOrchestrator` autoload（`--script` 模式显式补 `_ready()`），仅在未装配的极端降级时按 `project.godot` 注册项挂**同一生产脚本**；`configure_slot(user://saves/verify_r34d_<tag>_<pid>)` 注入独立 PID 临时槽，`bind_hud(_hud)` 订阅 4 信号；点数累加 / 去重 / 原子落盘全部由**生产脚本**执行，验证只注入真实输入 + 读磁盘断言。生产 `slot_01` 全程只读 md5 前后对照。
- **A57 断言链**（`verify_combo_runtime_v110.gd` 天然在第 1 波，实证 160；`verify_production_chains_v110.gd` 由既有 a~f 链推进到第 2 波，实证 240）：
  `真实命中(14 击) → combo 增长 → 评级 D→A(1.6) → 清波按倍率结算 → points_awarded 携带倍率后值 → 编排层原样采信落盘 → 磁盘 grace.trial.points` 全链一致；且 `combo_settled` 不二次入账、同一清波重复 `on_encounter_finished` 被 Rank-2 门控拒绝、重放同一 `points_awarded` 被编排层去重键拒绝、点数只增不减、`wave_cleared` 保留基础值、生产 `slot_01` 不污染。
- **动态期望（如实登记的设计决策）**：`wave_trial.tres` 各波基础点数不同（第 1 波 100 / 第 2 波 150 / 第 3 波 200 `[PLACEHOLDER]`）。`verify_production_chains_v110.gd` 的 A57 组不硬编码 160、不篡改状态机，改由 `ComboService` 本次结算真值 `base_points × multiplier` 动态推导期望（`roundf`），重放亦使用同一真值以正确命中去重键。`verify_combo_runtime_v110.gd` 在第 1 波硬编码 160 作为 A57「倍率后值实证」核心证据。两份脚本合起来覆盖 160 与 240 两个波次口径。

---

## 4. 真跑输出原文（三段门禁 + 全工程 G3）

统一命令前缀：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；纯引擎日志落系统临时目录 `/tmp/r34d_*.log`（未写入工程内）。

### GATE-1 `--headless --import`
```
GATE1_EXIT=0
[ DONE ] first_scan_filesystem
[ DONE ] update_scripts_classes
[ DONE ] loading_editor_layout
```

### GATE-2a `--check-only --script`（3 件，全 `EXIT=0`）
```
CHECK_ONLY res://scripts/hud.gd EXIT=0
CHECK_ONLY res://scripts/render/verify_production_chains_v110.gd EXIT=0
CHECK_ONLY res://scripts/render/verify_combo_runtime_v110.gd EXIT=0
```

### GATE-2b `--headless --script`（2 份扩展自测 + R34C 既有生产回归）
```
V1_PROD_CHAINS_EXIT=0      verify_production_chains_v110.gd
V2_COMBO_RUNTIME_EXIT=0    verify_combo_runtime_v110.gd
R34C_PROD_REG_EXIT=0       verify_points_commit_production_v110.gd（Rank-3 既有，只读复跑）
```

`verify_production_chains_v110.gd`（`[V110]`，51 条逐条 PASS，A57 组节选 + 汇总）：
```
[V110][A57] ==== 裁决 A57 全链组开始（R34D / 独立临时槽）====
[V110] A57-0 生产编排层实例就位（优先 autoload，不重复挂载；降级时挂同一生产脚本） PASS=true | source=autoload
[V110] A57-1 独立 PID 临时槽与生产 slot_01 物理隔离（落盘前注入） PASS=true | slot=user://saves/verify_r34d_chains_3904
[V110] A57-2 PointsCommitOrchestrator.bind_hud 成功（4 信号订阅、A55 唯一权威通道） PASS=true | bound=true
[V110] A57-3 真实命中 → combo 增长 → 评级变化：14 击到 A 级 1.6（A48 玩家真实可达） PASS=true | combo=14 rank=A mult=1.60
[V110][A57] 本次清波真值：基础 pts=150 × 评级倍率 1.60 → 倍率后值=240（波次基础点数来自 wave_trial.tres）
[V110] A57-4 清波按倍率结算：导演层 / ComboService 结算值均为倍率后值 base×mult（严格大于基础值） PASS=true | finished=true base=150 mult=1.60 expect=240 settled=240 combo_total=240
[V110] A57-5 ★ points_awarded 携带倍率后值（wave_cleared 分支发射值修正，每条清波只发一次、不再是基础值） PASS=true | wave_events=[{ "reason": "wave_cleared", "points": 240, "source": "wave_trial_director.wave_cleared" }] expect=240
[V110] A57-6 ★ PointsCommitOrchestrator 原样采信落盘倍率后值（运行时 get_status + 磁盘真值一致） PASS=true | runtime=240 disk=240 expect=240 commit_count=1
[V110] A57-7 ★ 全链一致：导演层结算 / combo 结算 / points_awarded / 编排层 / 磁盘 均为同一倍率后值 PASS=true | settled=240 combo=240 pa=240 runtime=240 disk=240 expect=240
[V110] A57-8 combo_settled 绝不二次入账（编排层不订阅 + 磁盘=expect 而非 2×expect + points_awarded 恰 1 次） PASS=true | orch_subs_combo_settled=false disk=240 expect=240
[V110] A57-9a 同一清波重复 on_encounter_finished 被 Rank-2 WAVE_ACTIVE 门控拒绝（不重复结算） PASS=true | dup_accepted=false settlement_count 2 -> 2
[V110] A57-9b 重放同一 points_awarded 被编排层去重键拒绝（磁盘不增、不二次入账） PASS=true | disk 240 -> 240（重放被拒）
[V110] A57-10 点数只增不减（磁盘逐次回读序列单调不减） PASS=true | trace=[240, 240]
[V110] A57-11 生产 slot_01 md5 前后一致（全程不写 slot_01） PASS=true | md5=9ebe2147e6245b83cb20a2703894da9b
[V110][A57] ==== 裁决 A57 全链组结束 ====
[V110] SUMMARY pass=51 fail=0 total=51 ok=true
[V110] RESULT=ALL_MATCH
```

`verify_combo_runtime_v110.gd`（`[V110-CBR]`，39 条逐条 PASS，A57 组全量 + 汇总）：
```
[V110-CBR] A57-0 生产编排层实例就位（优先 autoload，不重复挂载；降级时挂同一生产脚本） PASS=true | source=autoload
[V110-CBR] A57-0b 独立 PID 临时槽与生产 slot_01 物理隔离（落盘前注入） PASS=true | slot=user://saves/verify_r34d_combo_22560
[V110-CBR] A57-0c PointsCommitOrchestrator.bind_hud 成功（4 信号订阅、A55 唯一权威通道） PASS=true | bound=true
[V110-CBR][A57] ==== 裁决 A57 全链组开始（第 1 波 100×A级1.6=160）====
[V110-CBR] A57-1 ★ points_awarded 携带倍率后值 160（wave_cleared 分支，每条清波只发一次、不再是基础 pts=100） PASS=true | wave_events=[{ "reason": "wave_cleared", "points": 160, "source": "wave_trial_director.wave_cleared" }]
[V110-CBR][A57] 全链真值 | base=100 mult=1.6 combo_total=160 导演层=160 points_awarded=160 编排层=160 磁盘=160
[V110-CBR] A57-2 ★ 全链一致 100×1.6=160：导演层结算 / combo 结算 / points_awarded / 编排层 / 磁盘 均为 160 PASS=true | settled=160 points_total=160 combo=160 pa=160 runtime=160 disk=160
[V110-CBR] A57-3 wave_cleared(index, points) 保留基础值 100 只作 HUD 展示 / 事件键（A57 裁决、既有 s4 不变） PASS=true | wave_cleared_pts=[100]
[V110-CBR] A57-4 combo_settled 绝不二次入账（编排层不订阅 + 磁盘=160 非 320 + points_awarded 恰 1 次 + combo_settled 已发 total=160） PASS=true | orch_subs=false disk=160 settled_log={ "total_points": 160, "base_points": 100, "rank": "A", "multiplier": 1.6 }
[V110-CBR] A57-5a 同一清波重复 on_encounter_finished 被 Rank-2 WAVE_ACTIVE 门控拒绝（不重复结算） PASS=true | dup_accepted=false settlement_count 1 -> 1
[V110-CBR] A57-5b 重放同一 points_awarded 被编排层去重键拒绝（磁盘不增、不二次入账） PASS=true | disk 160 -> 160（重放被拒）
[V110-CBR] A57-6 点数只增不减（磁盘逐次回读序列单调不减） PASS=true | trace=[160, 160]
[V110-CBR] A57-7 生产 slot_01 md5 前后一致（全程不写 slot_01） PASS=true | md5=9ebe2147e6245b83cb20a2703894da9b
[V110-CBR][A57] ==== 裁决 A57 全链组结束 ====
[V110-CBR] SUMMARY pass=39 fail=0 total=39 ok=true
[V110-CBR] RESULT=ALL_MATCH
```

R34C 既有生产回归（**A57 后既有 150 口径不回退**，D 级 1.0 安全降级实证）：
```
[V110-PROD] 磁盘回读 | after_wave | grace.trial.points=100 delta_exists=true
[V110-PROD] 磁盘回读 | after_exec | grace.trial.points=150 delta_exists=true
[V110-PROD] R04 生产编排层真实 commit 次数 > 0（非验证脚本自模拟） PASS=true | commit_count=2
[V110-PROD] 磁盘回读 | after_dup | grace.trial.points=150 delta_exists=true
[V110-PROD] D02 ★ grace.trial.points 已落盘且 > 0（A55 唯一权威通道） PASS=true | points=150.0
[V110-PROD] D04 点数只增不减（磁盘逐次回读序列单调不减） PASS=true | trace=[100, 150, 150]
[V110-PROD] SUMMARY pid=32108 slot=user://saves/verify_r34c_32108 pass=28 fail=0 total=28
[V110-PROD] RESULT=ALL_MATCH
```
> 说明：R34C 验证脚本在 `start_trial()` 时 `wave_started → combo.reset()` 把连击归零到 D 级（倍率 1.0），清波结算 `100×1.0=100` 与基础值等价，A57 修正后 `points_awarded` 仍为 100 → 落盘 100 + 处决 50 = 150，既有 28 条断言全绿。这正是 DONE-R34 §3.6 注解⑤ 的「安全降级」实证。

### GATE-3 `--headless --quit`（主场景实证）+ 全工程 G3 统计
```
GATE3_EXIT=0
[SaveSystem] 自动读回完成 | dungeon.wave_trial.best_wave=3 | grace.trial.points=450 | dungeon.wave_trial.completed=true
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
[WaveTrial] 持久化基线读回：dungeon.wave_trial.best_wave=3 / dungeon.wave_trial.completed=true / grace.trial.points=450（经 WorldState.get_flag）
[R34C][PCO] 生产订阅者已绑定 HUD | signals=4 slot=user://saves/slot_01（A55 唯一权威通道）
[R34][HUD] 生产链装配完成 | stagger_bound=true boon_bound=true combo_bound=true combo_signals=true wave_cleared=true wave_started=true visible=true

=== 全工程 G3 统计（本轮所有引擎日志 /tmp/r34d_*.log）===
SCRIPT_ERROR_COUNT=0        （grep SCRIPT ERROR=0 期望，达标）
PARSE_ERROR_COUNT=0
ERROR_PREFIX_COUNT=0
GATE-1 EXIT=0 / 3×GATE-2a EXIT=0 / 3×GATE-2b EXIT=0 / GATE-3 EXIT=0
```

### A38 / 既有 `.tres` 零改动
```
[V110] A38-1 courtyard.tscn 静态 [node] 行数 == 41（只读不改） PASS=true | count=41 expected=41
[V110] A38-2 uv 2/1/1 原样（Vector3(2,2,1)×1 + Vector3(1,1,1)×2） PASS=true | uv_2x=1 uv_1x=2
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41

既有 .tres md5（与 DONE-R34 基线逐字对照，全部一致、零改动）：
793b6daa7c7730feed1a3f849701d58a  data/rpg/wave_trial.tres
44d8b941f8b28dfa2931984707b5c53e  data/rpg/boon_draft.tres
7e9e5ac7d35d8d15171e69975ac3356d  data/rpg/trial_modifiers.tres
49ce964e7c268804efbf2f20bec6565d  data/combat/stagger_rules.tres
a1ad4635ae0342c696fe650eb13d4930  data/rpg/combo_rules.tres
```

### WARNING 如实登记（非 `SCRIPT ERROR`、非本轮引入、不影响门禁 `EXIT=0`）
```
WARNING: [R34B][ENC] 波次开始无 cost_key/effect_key（未抉择或记录缺失）→ 运行时敌人参数回落中性基线（失败降级，不崩）
WARNING: [R34C][PCO] 重复领取拒绝 | event_key=auto:wave_cleared:240:wave_trial_director.wave_cleared reason=wave_cleared points=240 ...
WARNING: [R34C][PCO] 重复领取拒绝 | event_key=auto:wave_cleared:160:wave_trial_director.wave_cleared reason=wave_cleared points=160 ...
WARNING: [R34C][PCO] 重复领取拒绝 | event_key=exe: reason=execution points=50 ...
WARNING: [SaveSystem] --script 工具模式（未带 v050_read 标记）：跳过自动读回（降级，不崩，保护回归基线）
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
```
> 前两组「重复领取拒绝」正是 A57 全链组注入的**去重门控生效证据**；其余为既有 `--script` 降级 / ObjectDB 泄漏，与 DONE-R34 / DONE-R34C 登记一致。全部为 `WARNING`，非 `SCRIPT ERROR` / `Parse Error` / `ERROR:` 前缀。

---

## 5. 倍率后值实证（本轮核心，缺一不可）

**A57 之前**：`points_awarded` 携带基础 pts（100），导演层倍率后值（160）分叉，Rank-3 原样采信落盘 100 → 连击倍率机制在生产链路上不生效（R34C §7 第 2 条）。

**A57 之后（真跑实证）**：

| 证据 | 输出原文 | 说明 |
|---|---|---|
| ★ **160 落在 `points_awarded` 与磁盘** | `[V110-CBR][A57] 全链真值 \| base=100 mult=1.6 combo_total=160 导演层=160 points_awarded=160 编排层=160 磁盘=160` + `A57-2 … settled=160 points_total=160 combo=160 pa=160 runtime=160 disk=160 PASS=true` | `verify_combo_runtime_v110.gd` 第 1 波，A 级 1.6，`100×1.6=160` 全链一致落盘 |
| ★ **240 落在 `points_awarded` 与磁盘** | `[V110][A57] 本次清波真值：基础 pts=150 × 评级倍率 1.60 → 倍率后值=240` + `A57-5 … "points": 240 …` + `A57-6 … runtime=240 disk=240 …` + `A57-7 … settled=240 combo=240 pa=240 runtime=240 disk=240` | `verify_production_chains_v110.gd` 第 2 波（既有 a~f 链真实推进），按 `wave_trial.tres` 真值动态推导，证明倍率在任意波次生效 |
| **既有 150 口径不回退** | `[V110-PROD] 磁盘回读 \| after_exec \| grace.trial.points=150` + `D02 … points=150.0` + `D04 … trace=[100, 150, 150]` | R34C 既有生产回归：D 级 1.0 安全降级，A57 不改变无连击时的点数 |

**结论**：`points_awarded` 现携带最终结算值（含连击倍率），`PointsCommitOrchestrator` 仍「原样采信」不二次加工（A55 不变），倍率后值 **真实进入磁盘** `user://saves/verify_r34d_<tag>_<pid>/delta.json` 的 `flags.grace.trial.points`；`wave_cleared` 保留基础值（HUD 展示 / 事件键），`combo_settled` 只作对账展示、绝不二次入账，同一清波重复触发被去重拒绝，点数只增不减。**R34B §4.4 / DONE-R34 §7 第 2 条 / DONE-R34C §7 第 2 条 & §8 第 1 条 的「最后一处玩法分叉」已按裁决 A57 闭合。**

---

## 6. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 任务①：`hud.gd` 1 处精确 Edit，取 A54 唯一实例 `get_last_settlement()` 倍率后值、失败降级告警、每条事件只发一次 `points_awarded`、处决/抉择分支不动、`wave_cleared` 保留基础值、`combo_settled` 绝不二次入账、A46/A48/A50 与既有静态断言 `e3`/`w1` 不变；② 任务②：两份 v110 自测「保留既有断言不删不放宽」并追加全链断言，`51 + 39 = 90 PASS / 0 FAIL`、两份 `RESULT=ALL_MATCH`；③ **倍率后值实证 160（第 1 波）与 240（第 2 波）落在 `points_awarded` 与磁盘**；④ 任务③：三段门禁全 `EXIT=0`、全工程 `SCRIPT ERROR=0 / Parse Error=0 / ERROR=0`、`A38` 节点 41 / uv `2/1/1`、5 份既有 `.tres` md5 零改动；⑤ R34C 既有生产回归 `150` 口径 28 PASS 不回退；⑥ 目录所有权：只写 3 个工程脚本 + Rank-1 文档 + 回执，`points_commit_orchestrator.gd` / `project.godot` / 契约 / `encounter_director.gd` / `wave_trial_director.gd` / `courtyard.tscn` / `.tres` 一律只读未改。 |
| **失败** | 无（最终门禁与断言全通过）。**如实登记过程**：首轮真跑 `verify_production_chains_v110.gd` 为 `45 PASS / 6 FAIL / RESULT=MISMATCH`（`RUN_EXIT=1`）——根因 ① A57 组硬编码 160，但既有 a~f 链把 wave 推进到**第 2 波**（`wave_trial.tres` 基础 150），实际 `150×1.6=240` → A57-4/5/6/7/8 五条失败；② 重放硬编码 160 与实际 240 参数指纹不同，编排层去重键未命中 → 磁盘 `240 -> 400` → A57-9b 失败。修复：改为「按 ComboService 结算真值 `base_points × multiplier` 动态推导倍率后值」、重放用同一真值、描述通用化，不硬编码、不篡改状态机；第二轮全绿。**不冒充一次通过。** |
| **需用户确认** | ① 15~20 秒实机录屏目视由总指挥本轮亲自重跑（headless 无像素级目视，本 AI 不重复录屏、不冒充目视通过）；② 全部 `[PLACEHOLDER]` 数值待人工试玩校准（只改表）；③ 既有 `WARNING` / 降级日志是否纳入后续清理；④ HD-2D 全绿（A41 未达）、`128bit` 歧义（A43 保留）沿用既有登记。 |

---

## 7. 未完成项（如实登记，交总指挥排期）

1. **实机录屏目视**：headless 真跑无帧缓冲，按公共契约由总指挥本轮亲自重跑 15~20 秒并目视，本 AI 不重复录屏、不冒充目视通过。
2. **`[PLACEHOLDER]` 数值校准**：`rank_thresholds / multiplier / timeout_sec / reset_on_hit_taken` 待人工试玩；调参唯一入口 `godot/data/rpg/combo_rules.tres`，同步 `verify_combo_v110.gd` 的 `EXPECT_*` 与本文数值表。
3. **契约口径文字未同步**（Rank-3 所有、本轮只读未改）：`teamwork/00-协作契约.md` §3.3 R34C 段及 DONE-R34C §7 第 2 条 / §8 第 1 条仍登记「`points_awarded` 携带基础 pts 分叉」；A57 已在代码层闭合该分叉，是否由 Rank-3 口径登记同步，请裁决（见 §8 第 1 条）。
4. **处决 `window_id` 为空串**：R34C §7 第 3 条延续，编排层 `exe:` 键合并不同处决窗口，需 Rank-1 侧提供唯一窗口 id 或另定配对键。
5. **`grace.trial.spent_points` 抉择扣费出口**：R34C §7 第 1 条延续，本轮不扩大写入面。
6. **既有 autoload / 降级 `WARNING`**（SaveSystem 工具模式 / ChunkManager / ObjectDB 泄漏 / ENC 中性基线降级）：非本轮引入，是否纳入后续清理由总指挥裁决。

---

## 8. 待总指挥裁决项（只登记、不擅改）

1. **契约与历史 DONE 口径同步**：A57 把 `points_awarded` 统一为「最终结算值（含连击倍率）」，`wave_cleared` 保留基础值、`combo_settled` 绝不入账。是否更新 `teamwork/00-协作契约.md` §3.3（R34C 段）与 DONE-R34C 的「分叉」表述，避免后续 Rank 误读为仍分叉；文件归 Rank-3，本轮只读未改。
2. **`wave_cleared(index, points)` / `combo_settled(total, base, rank, mult)` 是否需额外对账日志**（A55 ②③ 已定「绝不入账」），供后续审计。
3. **去重键回落口径**（R34C §8 第 3 条延续）：`points_awarded` 不带 `window_id` / `wave_index`，无配对键时以 `(reason, points, source)` 指纹去重。A57 后点数变为倍率后值（可能逐波不同），指纹随波次变化；「同一清波重放」已实证拒绝，但「不同清波是否应视为不同事件」请裁决。
4. **处决 `window_id` 为空串**（R34C §8 第 4 条延续）：是否要求 Rank-1 在 `execution_performed` 提供唯一窗口 id。
5. **`grace.trial.spent_points` 抉择扣费归属**（R34C §8 第 5 条延续）。
6. **既有 `WARNING` 清理**（R34C §8 第 6 条延续）。
7. **实机录屏回看**（R34C §8 第 7 条延续）。

---

## 9. 硬约束遵守声明

- **唯一写入方 = Rank-1**：仅 `godot/scripts/hud.gd`、`godot/scripts/render/verify_production_chains_v110.gd`、`godot/scripts/render/verify_combo_runtime_v110.gd`、`teamwork/Rank-1/DONE-R34D.md`、回执；`points_commit_orchestrator.gd` / `project.godot` / 契约 / `encounter_director.gd` / `wave_trial_director.gd` / `presentation.gd` / `courtyard.tscn` / 既有 `.tres` / 素材 / 其它 Rank 产出只读未改（R34C 既有验证脚本仅只读复跑）。
- `courtyard.tscn` 静态 `[node]` 行数 `41` / uv `2/1/1`（A38-1/2 真跑 + GATE-3 `SceneState node_count=41`）未破坏；5 份既有 `.tres` md5 与 R34 基线逐字一致。
- **A50 / I-1 / A55 边界**：Rank-1 只发信号不写盘；`hud.gd` R34 追加段无 `set_flag` / `commit` / `FileAccess.open`（既有 `e3` / `w1` 静态断言真跑 PASS）；落盘唯一写入方仍为 Rank-3 编排层，A55「原样采信」代码未改；验证脚本不写生产 `slot_01`（md5 前后一致）、不在验证脚本内模拟编排逻辑。
- **Godot 4 `--script` 纪律**：`extends SceneTree` 用 `Engine.get_main_loop() as SceneTree` 取 root、不用 `get_tree()` / 不用 `/root/...` 绝对路径；`add_child` 后显式 `call("_ready")` / `_r34_bootstrap()`；对已装配 autoload 显式补 `_ready()`、不重复挂载第二个编排层实例；资源 `CACHE_MODE_IGNORE` 回读；connect 前 `get_signal_connection_list()` 去重、`_finish()` 有 `disconnect` / `_release()` 释放路径；独立 PID 临时槽与生产 `slot_01` 物理隔离。
- **零付费、零外部依赖、不启 GPU job**；不伪造产物、不谎报成功、不自行 git（总指挥收尾）；未删除 `.workbuddy`。
- **默认不刺探**：未扫目录做进度巡检、未写只读探针 / 巡检脚本；仅按任务单要求读取必读的任务单 / 两份 DONE / 目标文件 / 必要的只读接口源码，真跑日志落系统临时目录 `/tmp`，未写入工程内。

---

## 10. 回执与中枢归档

- 回执路径（**`teamwork/command_center/`，非工程根**）：
  `teamwork/command_center/ai/1/outbox/cmd-20261112-122524-297-A1.json`
- 四字段：`{"task_id":"cmd-20261112-122524-297-A1","ai":1,"status":"done","result":"引用 DONE-R34D.md 实际结论：…（含 160/240 倍率后值实证、门禁结论）"}`。

### 回执写后确认（中枢归档 · 实测，非推断、不伪造、不重放）
```
· 回执写入 ai/1/outbox/ 后由中枢自动回收：写后 outbox 已清空（中枢正常处理，
  与 DONE-R34B §10 / DONE-R34C §10 口径一致）
· dispatcher/receipts/cmd-20261112-122524-297-A1.json  VALID_JSON=True
  keys=['ai','result','status','task_id'] | task_id 正确 | ai=1 | status=done
· dispatcher/ledger.jsonl 新增 1 条：
  id=cmd-20261112-122524-297-A1 status=done finished_at=2026-11-12 12:47:47，
  result 与回执逐字一致
· ai/1/status.json：state=idle / current_task="" / completed=63（62→63）
  / last_seen=2026-11-12 12:47:47
· dispatcher/dispatcher.log 尾部原文：
  [2026-11-12 12:47:47] ← 1 号 AI 回执 <cmd-20261112-122524-297-A1> 完成：引用 DONE-R34D.md 实际结论：…
```
> 回执写后确认归档到 `teamwork/command_center/dispatcher/receipts/`（**是 teamwork/command_center/，不是工程根**）；归档与台账 / 状态更新由中枢流程完成，Rank-1 只写 outbox、未自建 / 未伪造归档、未重放。
