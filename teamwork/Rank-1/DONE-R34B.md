# DONE-R34B.md · R34B「新机制真实可达补接线」交付报告（Rank-1）

> 轮次：`R34B / v0.11.0` ｜ 派单 id：`cmd-20261112-104355-084-A1` ｜ 执行 AI：`1（Rank-1 引擎架构与渲染）`
> 真源：`teamwork/Rank-1/调度任务单-latest.json`（`task` 全文 + 公共契约 + 目录所有权）+ `teamwork/Rank-2/DONE-R34.md` §3（ComboService 接口签名）+ `teamwork/Rank-1/DONE-R34.md`（6 条链现状）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> 结论：**裁决 A54 唯一实例收敛完成（combo 恒 0 根因修复）；连击评价 4 驱动 + 4 信号全接进真实玩法；抉择 cost_key/effect_key 真正作用到波次开始时运行时敌人参数；点数信号口径逐字固定给 Rank-3。三段门禁全 `EXIT=0`、纯引擎日志 `SCRIPT ERROR=0 / Parse Error=0`、两份验证 `28 + 38 PASS / 0 FAIL` 全 `RESULT=ALL_MATCH`、既有 8 份回归全 `ALL_MATCH` 不回退、A38 节点数 41 / uv 2/1/1 / 节点名不变、5 份 `.tres` md5 零改动、回执已中枢归档。**

---

## 1. 实际交付清单（本轮唯一写入方 = Rank-1）

| 文件 | 类型 | 实际改动 |
|---|---|---|
| `godot/scripts/combat/encounter_director.gd` | 修改 | 任务1 c/d 驱动：`_on_boss_move_landed()` 玩家受击 → `_r34b_combo_on_hit_taken()` → `ComboService.on_hit_taken()`；`_finish(won)` 胜利 → `_r34b_combo_on_boss_defeated()` → `on_boss_defeated()`。任务2 消费：`_resolve_poise_on_hit()` 按运行时敌人参数 `poise_damage_bonus` 放大真实削韧（无修正时乘 `1.0` 逐字等价）。新增 R34B 段：`apply_wave_enemy_params()` / `get_enemy_runtime_params()` / 运行时敌人参数字典 / 2 个鸭子类型转发方法 / `[PLACEHOLDER]` 中性基线与告警降级。**既有 20/45/53 断言、`debug_*` 签名、`get_snapshot()` 键、`emit` 行逐字不动**（仅 3 处插入调用 + 追加段）。 |
| `godot/scripts/hud.gd` | 修改 | **A54**：`_r34_create_boon_service()` 删除全部 `cs.new()`/`bs.new(bc)` 自建（绝不另建第二实例）；`_r34_bootstrap()` 经 `wave.get_combo_service()`/`get_boon_service()` 复用唯一实例并 `bind_combo_service()`/`bind_boon_draft_service()`。任务1 e：`_r34_connect_combo_signals()` 订阅 4 信号 + 4 回调 → `get_combo_hud_view()`（评级/倍率/连击数按状态显示）供 Rank-4 读取；`_r34_combo_text()` 兼容真实 `get_snapshot()["combo"]`。任务2：`_r34_on_wave_started()` → `_r34b_apply_wave_enemy_params()` 把「导演层记录」推到 ENC 运行时敌人参数。`_r34_settle_boon_draft()` 的 `forwarded` 判定改为 `has_selection()`（兼容唯一实例幂等）。`get_production_status()` 追加 2 个只读 key。`_r34_release()` 追加 4 信号 disconnect 释放路径。**既有 1~15 节逻辑 / 6 信号 / 19+5 断言逐字不动**。 |
| `godot/scripts/render/verify_combo_runtime_v110.gd` | 新增 | **任务4 验收件**：在**不加载 `presentation.gd`** 的独立进程里 `instantiate()` 主场景 + 显式 `_ready()`/`_r34_bootstrap()`，真实输入/真实信号/真实服务断言「真实命中 → combo 增长 → 评级变化 → 清波点数按倍率结算 → 受击重置 → Boss 死亡结算」全链 + A54 唯一实例 + 任务2 敌人参数 + 失败降级 + 零写盘。`28 PASS / 0 FAIL / RESULT=ALL_MATCH`。 |
| `godot/scripts/render/verify_production_chains_v110.gd` | 修改（扩展） | `_inject_combo()` 删除 `cs.new()` 自建（A54 合规，改为沿用/复用/契约替身）；`_initialize()` 追加 `_t_combo_static()`（7 条只读 + 真实命中/受击断言：A54 唯一实例、4 信号订阅、HUD 视图、任务2 敌人参数、combo 增长跨档、受击归零）。**既有 31 条断言逐字不删不放宽**（`38 PASS / 0 FAIL`）。 |
| `teamwork/Rank-1/DONE-R34B.md` | 新增 | 本报告 |
| `teamwork/command_center/ai/1/outbox/cmd-20261112-104355-084-A1.json` | 新增 | 回执（§10 确认归档） |

### 只读未改（硬约束）
`wave_trial_director.gd`（Rank-2 所有）、Rank-2/3/4 全部产出、`combo_service.gd` / `combo_config.gd` / `boon_draft_service.gd` / `boon_draft_config.gd` / `stagger_service.gd`、`courtyard.tscn`、`godot/test/presentation.gd`、全部 `.tres` 数据表、素材、`teamwork/00-协作契约.md`。
A38：`courtyard.tscn` 静态节点数 `41` / uv `2/1/1` / 节点名均未破坏（GATE-3 真跑回读 + `verify_production_chains_v110.gd` A38-1/A38-2 实证）。

---

## 2. 四块任务落地详情

### ① 裁决 A54 · 唯一实例（根因修复）
见 §3 专章。核心：Rank-1 **删除** HUD 自建的 ComboService / BoonDraftService，`_r34_bootstrap()` 经 Rank-2 暴露的 `get_combo_service()` / `get_boon_service()` 复用 `wave_trial_director.gd` 装配的唯一实例；`EncounterDirector` 不自建，由 HUD `bind_combo_service()` 转注入。验证进程亦不另建第二个 ComboService 实例。

### ② 连击评价接进真实玩法（任务1，签名以 `DONE-R34.md` §3 为准）
| 项 | 落点 | 签名/方法 |
|---|---|---|
| a) 命中 | `encounter_director.gd:_on_player_hit_landed()` 既有转发链（R34 a） | `ComboService.register_hit(damage: int)` — 收敛后命中转发与清波结算命中**同一实例** |
| b) 帧驱动 | `encounter_director.gd:_r34_tick()` 既有（R34 b），与 `StaggerService.tick(delta)` **同一逻辑拍、不重复建计时器** | `ComboService.tick(delta: float)` |
| c) 玩家受击 | `encounter_director.gd:_on_boss_move_landed()` → `_r34b_combo_on_hit_taken()` | `ComboService.on_hit_taken()` |
| d) Boss 死亡 | `encounter_director.gd:_finish(true)` → `_r34b_combo_on_boss_defeated()`（另 wave 末波 `_clear_wave()` 亦调，二者同一实例幂等） | `ComboService.on_boss_defeated()` |
| e) 4 信号订阅 | `hud.gd:_r34_connect_combo_signals()` → 4 回调 → `get_combo_hud_view()` → `ProductionMechanismsLayer` 连击 Label 按状态显示 | `combo_changed` / `rank_changed` / `combo_reset` / `combo_settled` |

> 清波结算 `settle(base_points)` 由 Rank-2 `wave_trial_director.gd:_clear_wave()` 消费（只读未改）；本轮 A54 收敛后其 `_combo` 与命中转发为**同一实例**，故 combo 不再恒 0 → 评级倍率真实并入点数（`verify_combo_runtime_v110.gd` s2：A 级 1.6 → 160；b2：B 级 1.35 → 270）。Rank-1 不写盘。

### ③ 抉择代价真正作用到下一波敌人实例（任务2）
**作用链路（全链可回读）**：
```
玩家抉择（数字键 1/2/3）→ HUD._r34_settle_boon_draft()
  → BoonDraftService.apply() 成对 effect_key/effect_value + cost_key/cost_value（数值源 boon_draft.tres [PLACEHOLDER]）
  → HUD._r34_pending_wave_modifier（待作用于下一波）
  → 下一波 wave_started → HUD._r34_on_wave_started()
      ├─ production_wave_modifier 广播（既有 d 链，不动）
      └─ HUD._r34b_apply_wave_enemy_params(wave_index)
           ├─ 数据源①：wave_trial_director.get_snapshot() 的 boon_cost_key/boon_effect_key/boon_cost_value（导演层记录）
           ├─ 数据源②：HUD._r34_active_wave_modifier（BoonDraftConfig.apply 真实成对数据，字段齐全，①为空时回落）
           └─ EncounterDirector.apply_wave_enemy_params(index, effect_key, effect_value, cost_key, cost_value)
                ├─ 基础值从 wave_trial.tres（CACHE_MODE_IGNORE）读当前波 hp_multiplier / telegraph_sec
                ├─ hp_scale = cost_value(if cost_key=="hp_scale") / telegraph_scale = cost_value(if "telegraph_scale")
                ├─ poise_damage_bonus = effect_value(if "poise_damage_bonus") / hp_restore = effect_value(if "hp_restore")
                ├─ effective_hp_scale = base_hp_multiplier × hp_scale；effective_telegraph_scale = base_telegraph_sec × telegraph_scale
                ├─ ① _r34b_enemy_params（运行时敌人参数权威字典，get_enemy_runtime_params() 只读回读）
                ├─ ② Boss 运行时实例标注（set_meta 有效倍率，不写 .tres / 不改判定分支）
                ├─ ③ 削韧真实消费：_resolve_poise_on_hit() 按 (1.0 + poise_damage_bonus) 放大真实削韧
                └─ ④ hp_restore 作用到玩家运行时 HP
```
**失败降级（参数缺失回落基础值并告警）**：`cost_key/effect_key` 为空、数值非法、表读取失败 → 回落中性基线（`hp_scale=telegraph_scale=1.0`、`poise_damage_bonus=0.0`）+ `push_warning` 告警 + `degraded=true`；真跑可观测（第 1 波未抉择 / `p5` 独立确定性调用均实证）。
**边界**：不改既有 `.tres` 数值、不改 `courtyard.tscn`、不改判定分支；数值全从 `[PLACEHOLDER]` 表读（代码零战斗数值硬编码）；Rank-1 不写存档。

### ④ 点数信号口径固定给 Rank-3（任务3）
见 §4 专章（逐字签名）。Rank-1 **只发不写**（A50 / I-1），`verify_combo_runtime_v110.gd` w1 与 `verify_production_chains_v110.gd` e3 静态断言 R34B 追加段零 `set_flag` / `commit` / `FileAccess` 写盘点。

---

## 3. ComboService 唯一实例证据（裁决 A54 专章）

### 3.1 改前根因（Rank-2 DONE-R34.md §6 / 本方 DONE-R34.md §7 登记的「双实例归属」）
`hud.gd:_r34_create_boon_service()` 自建 `ComboService`（`cs.new()`）与 `BoonDraftService`（`bs.new(bc)`）；`ency/_r34_combo` 由 HUD 注入 → **命中 `register_hit` / 每帧 `tick` 累积在 HUD 实例**；而 `wave_trial_director.gd:_clear_wave()` 结算用 **wave 自建 `_combo` 实例**（恒 `0` 连击 → D 级倍率 `1.0`）。两实例不共享，正是 Rank-2 登记的「接线前 combo 恒 0 → D 级 1.0，清波点数与既有等价（安全降级）」根因。

### 3.2 改后收敛（唯一写入方 Rank-1，绝不另建第二实例）
- `hud.gd:_r34_create_boon_service()`：**删除** `cs.new()` / `bs.new(bc)` 全部自建，仅打印 A54 唯一实例声明（生产 `_ready` 不再 `new` 任何服务）。
- `hud.gd:_r34_bootstrap()`：经 `wave.get_combo_service()` / `wave.get_boon_service()` 取 Rank-2 装配的唯一实例 → `bind_combo_service(combo)`（内部经 `EncounterRoot.bind_combo_service(svc)` 转注入 enc 命中/tick 转发链）+ `bind_boon_draft_service(boon)`。
- `encounter_director.gd`：**不自建** Combo/Boon 服务（R34 段鸭子类型转发链原样，只换实例来源）。
- `verify_production_chains_v110.gd:_inject_combo()`：删除 `cs.new()` 自建分支，改为「直接沿用 / 从 wave 复用唯一实例 / 契约替身（FakeCombo，非 ComboService 实例）」。
- 唯一实例归属仍为 `godot/scripts/combat/wave_trial_director.gd`（Rank-2 所有，只读未改）。

### 3.3 机器判定证据（真跑原文）
```
[V110-CBR] u1 A54 唯一实例：enc / hud / wave.get_combo_service() 为【同一】ComboService（绝不另建第二实例） PASS=true | enc=true hud=true wave=true same=true
[V110-CBR] u2 A54 唯一实例：hud._boon_draft_service 复用 wave.get_boon_service() 同一 BoonDraftService PASS=true | hud=true wave=true same=true
[V110] cb-unique A54：enc / hud / wave.get_combo_service() 为同一 ComboService 唯一实例（绝不另建第二实例） PASS=true | enc=true hud=true wave=true same=true
[V110] cb-unique-boon A54：hud._boon_draft_service 复用 wave.get_boon_service() 唯一实例 PASS=true | hud=true wave=true same=true
[R34][HUD] 生产链装配完成 | stagger_bound=true boon_bound=true combo_bound=true combo_signals=true wave_cleared=true wave_started=true visible=true   （GATE-3 主场景）
[R34B][HUD] A54 唯一实例：不自建 Combo/Boon 服务，由 _r34_bootstrap() 经 get_combo_service()/get_boon_service() 绑定 wave_trial_director 唯一实例
```
> 三方 getter 返回**同一 Object**：`enc.get_combo_service() == hud.get_combo_service() == wave.get_combo_service()`；`hud._boon_draft_service == wave.get_boon_service()`。命中累积与清波结算命中同一实例 → combo 真实可达（`h1`：0→14、`h2`：D→A；`s2`：A 级 160 点）。Rank-2 登记的「双实例归属」待裁决项消除。

---

## 4. 点数信号逐字签名（任务3 · 供 Rank-3 的 I-1 落盘订阅）

> 以下签名为 **Rank-1 侧口径固定、稳定不再改动**；Rank-1 **只发信号 / 只传参，不写存档文件**（A50 / I-1，落盘唯一写入方 = Rank-3）。

### 4.1 e 链主点数信号（Rank-1 `hud.gd` 定义，只发不写）
```
signal points_awarded(reason: String, points: int, source: String)
```
| 参数 | 类型 | 携带字段 / 取值 |
|---|---|---|
| `reason` | `String` | 点数来源原因：`"wave_cleared"`（清波）、`"execution"`（处决） |
| `points` | `int` | 本次点数（清波基础 pts / 处决 bonus） |
| `source` | `String` | 来源标识：`"wave_trial_director.wave_cleared"` / `"stagger_service.try_execute"` |

发出点：`hud.gd:_r34_on_wave_cleared()`（清波）、`hud.gd:request_execution()`（处决）。

### 4.2 关联生产信号（Rank-1 `hud.gd` 定义，R34 既有，逐字不动）
```
signal execution_performed(window_id: String, bonus_points: int)
signal boon_draft_selected(index: int, choice_id: String)
signal boon_draft_applied(index: int, choice_id: String, effect_key: String, effect_value: float, cost_key: String, cost_value: float)
signal production_wave_modifier(wave_index: int, effect_key: String, effect_value: float, cost_key: String, cost_value: float)
```

### 4.3 Rank-2 既有信号（只读，Rank-3 契约 §3.3 登记的订阅点）
```
signal wave_cleared(index: int, points: int)                                  # wave_trial_director.gd（Rank-2 所有，只读）
signal combo_settled(total_points: int, base_points: int, rank: String, multiplier: float)   # combo_service.gd（Rank-2 所有，只读）
```
- `wave_cleared(index, points)`：**第二参数保持基础 `pts`，既有输出格式零改动**（`verify_combo_runtime_v110.gd` s4 实证 `wave_cleared_pts=[100]`）。
- `combo_settled(total_points, base_points, rank, multiplier)`：ComboService 结算完成信号，携带倍率后点数（s3 实证 `{total_points=160, base_points=100, rank="A", multiplier=1.6}`）。

### 4.4 口径分叉（如实登记，裁决项延续，本轮不擅改）
`wave_cleared(index, points)` 第二参仍是**基础 pts**；ComboService 倍率并入的是导演层 `_persist_settle(...)` 的 `new_points` 与 `points_total`（s4 实证 `points_total=160`）。当 combo 倍率 `>1` 时，Rank-3 若按 `wave_cleared` 累加 `grace.trial.points`，与导演层落盘值会**分叉**。请裁决 Rank-3 订阅 `points_awarded` / `wave_cleared` / `combo_settled` / `get_settlement_snapshot()` 的权威口径；本轮按既有产出格式落地、不擅改（DONE-R34.md §7 第 2 条 / 本方 DONE-R34.md §7 第 1 条延续）。

### 4.5 零写盘实证
`verify_combo_runtime_v110.gd` w1 + `verify_production_chains_v110.gd` e3：R34B 追加段源码不含 `.call("set_flag"` / `.call("commit"` / `FileAccess.open`（`no_write=true`）；验证全程 `wave.bind_persistence(null, null)` 显式降级，不触碰 `user://slot_01/delta.json`。

---

## 5. 真跑输出原文（三段门禁 + 全工程 G3）

统一命令前缀：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`
引擎版本行：`Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org`
纯引擎日志：`/tmp/r34b_engine.log`（引擎输出与统计标题分离，避免自写标题被 grep 命中）。

### GATE-1 `--headless --import`
```
[ DONE ] update_scripts_classes
[ DONE ] loading_editor_layout
GATE1_EXIT=0
```

### GATE-2a `--check-only --script`（9 件，全 `EXIT=0`）
```
check-only encounter_director.gd EXIT=0 | check-only hud.gd EXIT=0
check-only verify_combo_runtime_v110.gd EXIT=0 | check-only verify_production_chains_v110.gd EXIT=0
check-only verify_hud_layout_v100.gd EXIT=0 | check-only verify_stagger_v100.gd EXIT=0
check-only verify_impact_feedback_v090.gd EXIT=0 | check-only verify_encounter_v030.gd EXIT=0
check-only presentation.gd EXIT=0（本轮只读）
```

### GATE-2b `--headless --script <verify>`（本轮 2 份 + 既有 6 份复跑）
`verify_combo_runtime_v110.gd`（新增，28 条逐条 PASS，节选关键行 + 汇总）：
```
[V110-CBR] ==== verify_combo_runtime_v110 真跑开始 | R34B v0.11.0 Rank-1 ====
[V110-CBR] A49：本进程不加载 presentation.gd；自行 instantiate 主场景 + 显式 _ready()/bootstrap()
[V110-CBR] 主场景已实例化入树 | name=Courtyard is_inside_tree=false（未加载 presentation.gd）
[V110-CBR] u1 A54 唯一实例：enc / hud / wave.get_combo_service() 为【同一】ComboService PASS=true | enc=true hud=true wave=true same=true
[V110-CBR] u2 A54 唯一实例：hud._boon_draft_service 复用 wave.get_boon_service() 同一 BoonDraftService PASS=true | same=true
[V110-CBR] u3 唯一实例为真实 ComboService（4 信号 + settle/get_snapshot 公开接口齐全） PASS=true
[V110-CBR] h1 真实 light_attack 命中 → 唯一实例 combo 增长（player_hit_landed → register_hit） PASS=true | combo 0 -> 14
[V110-CBR] h2 combo 增长驱动评级变化 D→C→B→A（rank_changed 跨档信号真实发出） PASS=true | rank D -> A | rank_changed += 3
[V110-CBR] h3 4 信号订阅生效：combo_changed 探针随真实命中递增 PASS=true | combo_changed=16
[V110-CBR] s1 真实 wave 状态机清波（on_encounter_finished(true)）→ combo.settle() 结算 PASS=true | finished=true settlement_count=1
[V110-CBR] s2 清波点数按评级倍率结算：A 级 1.6 → settled=160（100×1.6 [PLACEHOLDER]） PASS=true | settled=160 rank=A mult=1.6
[V110-CBR] s3 combo_settled 信号真实发出且携带 total=160 > base=100 PASS=true | settled_log={ "total_points": 160, "base_points": 100, "rank": "A", "multiplier": 1.6 }
[V110-CBR] s4 wave_cleared 第二参仍为基础 pts=100 PASS=true | wave_cleared_pts=[100] settled=160 points_total=160
[V110-CBR] s5 真实数字键 2 → 抉择 apply() 成对 effect/cost 生效 PASS=true | effect=poise_damage_bonus cost=telegraph_scale
[R34B][ENC] 运行时敌人参数已刷新 | wave=1 hp_scale=1.00(base 1.30→eff 1.30) telegraph_scale=0.85(eff 1.27) poise_bonus=0.25 annotated=true degraded=false
[R34B][HUD] 任务2 作用链路：wave_started(index=1) → apply_wave_enemy_params → 运行时敌人参数 | cost=telegraph_scale(0.85) effect=poise_damage_bonus(0.25) applied=true degraded=false
[V110-CBR] r1 玩家受击 → ComboService.on_hit_taken() → combo 归零 PASS=true | combo 3 -> 0
[V110-CBR] r2 combo_reset(hit_taken) 信号真实发出 PASS=true | reset_reasons=["manual","manual","manual","hit_taken"]
[V110-CBR] p1 运行时敌人参数已由波次开始作用链路刷新 PASS=true | applied=true，字段齐全
[V110-CBR] p2 cost_key=telegraph_scale(0.85) / effect_key=poise_damage_bonus(0.25) 真实来自 boon_draft.tres PASS=true
[V110-CBR] p3 基础值从 wave_trial.tres 读取，有效倍率 = base × cost PASS=true | base_hp=1.30 base_telegraph=1.50 eff_telegraph=1.275
[V110-CBR] p4 代价真正作用到敌人运行时实例（Boss 元数据标注） PASS=true | annotated=true meta_ok=true
WARNING: [R34B][ENC] 波次开始无 cost_key/effect_key → 运行时敌人参数回落中性基线（失败降级，不崩）
[V110-CBR] p5 失败降级可观测：空 key → 回落中性基线 + degraded 告警 PASS=true
[V110-CBR] b1 末波（Boss 波）真实清波 → ComboService.on_boss_defeated() 定格评级 PASS=true | boss_defeated=true rank_before=B
[V110-CBR] b2 Boss 死亡结算按定格评级倍率：B 级 1.35 → settled=270（200×1.35 [PLACEHOLDER]） PASS=true | settled=270 rank=B mult=1.35
[V110-CBR] b3 Boss 死亡后 combo_settled 信号再发一次 PASS=true | settled_logs=2 -> 3
[V110-CBR] b4 ENC 任务1 d：Boss 死亡（_finish(true)）→ on_boss_defeated() 转发到唯一实例生效 PASS=true | enc_path boss_defeated=true
[V110-CBR] v1 HUD 已订阅 4 个 combo 信号 PASS=true | connected=true
[V110-CBR] v2 生产 HUD 可见层视图含评级/倍率/连击数 PASS=true | changed=33 rank_changed=5 settled=3
[V110-CBR] v3 4 信号探针累计全链有真实回调 PASS=true | changed=33 rank_changed=5 reset=6 settled=3
[V110-CBR] w1 R34B 追加段源码零写盘 PASS=true | enc_r34b_len=6845 hud_r34b_len=21189 no_write=true
[V110-CBR] w2 ENC 任务1 c/d + 任务2 削韧真实消费接线关键字齐全 PASS=true
[V110-CBR] SUMMARY pass=28 fail=0 total=28 ok=true
[V110-CBR] RESULT=ALL_MATCH
EXIT_CBR=0
```

`verify_production_chains_v110.gd`（扩展，38 条，既有 31 条全保留 + 新增 7 条，节选）：
```
[V110] A38-1 courtyard.tscn 静态 [node] 行数 == 41 PASS=true | count=41 expected=41
[V110] A38-2 uv 2/1/1 原样 PASS=true | uv_2x=1 uv_1x=2
[V110] a1 注入真实 light_attack 命中 → player_hit_landed 递增 PASS=true | hit_chain 0 -> 1
[V110] a2 命中 → StaggerService.apply_hit(真实 poise_damage) → 韧性快照下降 PASS=true | stagger 100.0 -> 82.0 (last_poise=18.0)
[V110] b1 导演层 _step 每逻辑拍驱动 tick(delta) PASS=true | tick_count 0 -> 36
[V110] ab-combo 命中 → 真实 ComboService 连击状态变化 PASS=true | combo_forward 0 -> 1 real_combo 0 -> 1 rank=D
[V110] d4b 抉择已注入 Rank-2 下游消费方 PASS=true | boon_forward_ok=true rank2_has_selection=true
[V110] e1 窗口内真实 F 处决 → execution_performed + points_awarded(execution, bonus) PASS=true | exec_bonus=50
[V110] e3 R34 生产链源码零写盘 PASS=true | no_write=true
[V110] tab1 HUD 真实键处理路径消费 Tab 并翻转图鉴（A46） PASS=true | codex false -> true
[V110] cb-unique A54：enc / hud / wave.get_combo_service() 为同一 ComboService 唯一实例 PASS=true | same=true
[V110] cb-unique-boon A54：hud._boon_draft_service 复用 wave.get_boon_service() 唯一实例 PASS=true | same=true
[V110] cb-signals HUD 已订阅 combo_changed/rank_changed/combo_reset/combo_settled PASS=true | connected=true
[V110] cb-hud-view get_combo_hud_view() 提供评级/倍率/连击数 PASS=true | rank=C mult=1.15 count=5
[V110] cb-enemy-params 任务2：波次开始已把 cost/effect 推到运行时敌人参数 PASS=true | cost=telegraph_scale effect=poise_damage_bonus telegraph_scale=0.85 poise_bonus=0.25 degraded=false
[V110] cb-real-hit 真实 light_attack 命中 → 唯一实例 ComboService combo 增长 + 跨档 PASS=true | combo 0 -> 4 rank=C
[V110] cb-hit-taken 玩家受击 → ComboService.on_hit_taken() → combo 归零 PASS=true | combo 4 -> 0
[V110] SUMMARY pass=38 fail=0 total=38 ok=true
[V110] RESULT=ALL_MATCH
EXIT_V110=0
```

既有 6 份回归复跑（综合日志，确认不回退）：
```
[V090]     SUMMARY pass=42 fail=0  total=42 ok=true   / RESULT=ALL_MATCH
[V100HUD]  SUMMARY pass=24 fail=0  total=24 ok=true   / RESULT=ALL_MATCH
[V100-ST]  SUMMARY pass=62 fail=0                     / OVERALL=PASS / RESULT=ALL_MATCH
[V030]     SUMMARY pass=53 fail=0                     / RESULT=ALL_MATCH
[V110-CB]  SUMMARY pass=110 fail=0                    / OVERALL=PASS / RESULT=ALL_MATCH
[V110-PS]  SUMMARY pass=59 fail=0                     / OVERALL=PASS / RESULT=ALL_MATCH
[V110]     SUMMARY pass=38 fail=0  total=38 ok=true   / RESULT=ALL_MATCH
[V110-CBR] SUMMARY pass=28 fail=0  total=28 ok=true   / RESULT=ALL_MATCH
```

### GATE-3 `--headless --quit`（主场景实证）
```
[R34B][HUD] A54 唯一实例：不自建 Combo/Boon 服务，由 _r34_bootstrap() 经 get_combo_service()/get_boon_service() 绑定 wave_trial_director 唯一实例
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41
[WaveTrial] 持久化基线读回：dungeon.wave_trial.best_wave=3 / completed=true / grace.trial.points=450
[WaveTrial] 增益运行时接线：checked=3 applied=1 degraded=0 reasons=[]
[R34][HUD] f 链：生产常驻可见层 ProductionMechanismsLayer 入树 is_inside_tree=true（按状态显示，非 presentation.gd 构造）
[R34][HUD] 生产链装配完成 | stagger_bound=true boon_bound=true combo_bound=true combo_signals=true wave_cleared=true wave_started=true visible=true
[R34][ENC] 同一 StaggerService 已推给 HUD（命中削韧 ↔ 韧性条单一事实源）
GATE3_EXIT=0
```

### 统一统计（全工程 G3 · 纯引擎日志 `/tmp/r34b_engine.log`）
```
SCRIPT_ERROR_COUNT=0        （grep SCRIPT ERROR=0 期望，达标）
PARSE_ERROR_COUNT=0
ERROR_PREFIX_COUNT=2
```
> 如实登记（不冒充全绿）：2 条 `ERROR:` 前缀行均为**既有件、非 `SCRIPT ERROR`、非本轮引入、不影响 `EXIT=0` 与断言**：
> ① `ERROR: Can't use get_node() with absolute paths from outside the active scene tree.` — `verify_encounter_v030.gd:123` → `boss_controller.gd:102` / `combat_event_bus.gd:38` 的既有 `--script` 工具模式 `/root/...` 绝对路径降级；
> ② `ERROR: Signal 'boss_defeated' is already connected to given callable 'Node(save_delta_writer.gd)::_on_boss_defeated'` — 既有 autoload `save_delta_writer.gd:49 _ready()` 重复 connect。
> 另有既有 autoload `WARNING`（`[SaveSystem] --script 工具模式…跳过自动读回`、任务2 无抉择时的 `[R34B][ENC] …回落中性基线` 失败降级告警、`2 ObjectDB instances were leaked at exit`），均为 `WARNING`、非 `SCRIPT ERROR`、非本轮引擎错误。

### 既有 `.tres` 数值零改动（md5 与 DONE-R34.md 逐字一致）
```
wave_trial.tres       793b6daa7c7730feed1a3f849701d58a  （前后一致）
boon_draft.tres       44d8b941f8b28dfa2931984707b5c53e  （前后一致）
trial_modifiers.tres  7e9e5ac7d35d8d15171e69975ac3356d  （前后一致）
stagger_rules.tres    49ce964e7c268804efbf2f20bec6565d  （前后一致，位于 data/combat/）
combo_rules.tres      a1ad4635ae0342c696fe650eb13d4930  （R34 新增表，验证脚本同样未写入）
```

**PASS/FAIL 汇总**：本轮 `28 + 38 = 66 PASS / 0 FAIL`，两份 `RESULT=ALL_MATCH`；既有 6 份回归 `42+24+62+53+110+59 = 350 PASS / 0 FAIL` 全 `ALL_MATCH`；`SCRIPT ERROR=0`。

---

## 6. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 裁决 A54：唯一实例收敛，三方 getter 同一 Object 机器判定，`combo 恒 0` 根因修复；② 任务1：4 驱动（register_hit / on_hit_taken / 同帧 tick / on_boss_defeated）+ 4 信号订阅 + 生产 HUD 可见层（评级/倍率按状态显示，供 Rank-4 读取）全接进真实玩法；③ 任务2：cost/effect 真正作用到波次开始运行时敌人参数（hp_scale/telegraph_scale/削韧）+ Boss 实例标注 + 失败降级告警，数值全从 `[PLACEHOLDER]` 表读；④ 任务3：点数信号签名逐字固定（§4），Rank-1 只发不写（A50）；⑤ 任务4：`verify_combo_runtime_v110.gd`（不加载 presentation.gd）28 PASS + 扩展 `verify_production_chains_v110.gd` 38 PASS（既有 31 不删不放宽），全链真实可达；⑥ 三段门禁全 `EXIT=0`、`SCRIPT ERROR=0 / Parse Error=0`、8 份回归全 `ALL_MATCH`；⑦ A38 节点数 41 / uv 2/1/1 / 节点名不变、5 份 `.tres` md5 零改动；⑧ 目录所有权：只写 2 个授权工程文件 + 2 个验证脚本 + Rank-1 文档 + 回执；⑨ 回执已中枢归档。 |
| **失败** | 无（真跑门禁与断言全通过；口径分叉与末端生成方边界如实登记，不计失败） |
| **需用户确认** | ① 点数落盘口径分叉（§4.4）请裁决 Rank-3 订阅权威通道；② 任务2「按波生成敌人实例」工程内 spawn 末端消费方归属（§7 第 3 条）；③ `hp_scale` 是否改写 Boss 运行时 HP 上限（§7 第 4 条）；④ 总指挥亲自重跑 15~20 秒实机录屏目视回看（headless 无像素级目视，按公共契约由 Rank-4/总指挥负责，本轮不重复录屏）；⑤ 全部 `[PLACEHOLDER]` 数值待人工试玩校准（只改表）；⑥ 既有 autoload 2 条 `ERROR:` + 3 条 `WARNING` 是否纳入后续清理；⑦ 演示未覆盖项（R34 登记的破韧开窗→F 处决 15s 内未自然触发）延续。 |

---

## 7. 未完成项 / 仍缺的接线（如实登记，交总指挥排期）

1. **点数真正落盘**：Rank-1 只发 `points_awarded` / `execution_performed` / `boon_draft_applied` / `production_wave_modifier` 信号；`grace.trial.points` 等 flag 的 `set_flag` + `commit` 落盘归 Rank-3 I-1（A50），本轮未写、未验落盘（越界）。
2. **点数落盘口径分叉**：`wave_cleared(index, points)` 第二参仍为基础 pts，ComboService 倍率并入导演层落盘口径；Rank-3 按信号累加值与导演层落盘值分叉（§4.4 / 裁决项 1），本轮按既有格式落地、不擅改。
3. **任务2 末端生成方**：本轮已把 cost/effect 从「导演层记录」推到**运行时敌人参数**（`get_enemy_runtime_params()` 权威字典 + Boss 实例元数据标注 + 削韧/HP 真实消费），但工程内「按波 `spawn` 敌人并消费 `hp_scale`/`telegraph_scale`」的生成方尚未落地（受「不改既有帧数据 / 不写 `courtyard.tscn`」约束），属跨 Rank 末端，如实登记。`hp_scale` 目前落到 Boss 实例标注与参数字典，未改写 `BossController._hp` / `boss_data.max_hp`（避免破坏 `get_hp_ratio` 与 20/45/53 断言）。
4. **`hp_scale` 是否真正改写 Boss 运行时 HP 上限**：涉及 BossController 私有态 / `boss_data` 运行时副本，待裁决（裁决项 4）。
5. **抉择 UI**：仍为数字键 1/2/3 注入既有 `_process_r32_keys`，无独立三选一 UI 面板（既有）。
6. **实机录屏目视**：headless 真跑无帧缓冲，按公共契约列为后续动作 / 需用户确认（不冒充目视通过）。
7. `[PLACEHOLDER]` 数值与演示帧点校准（调参只改表/常量，不改数据表 `.tres`）；HD-2D 全绿（A41 未达）、`128bit` 歧义（A43 保留）沿用既有登记。

---

## 8. 待总指挥裁决项（只登记、不擅改）

1. **点数落盘权威口径（重点）**：Rank-3 应订阅 `points_awarded(reason, points, source)` / `wave_cleared(index, points)` / `combo_settled(total, base, rank, mult)` / `get_settlement_snapshot()` 中哪一路作为 `grace.trial.points` 唯一权威？`wave_cleared` 保持基础 pts 时与导演层倍率后落盘值分叉（§4.4）。本轮按既有产出格式落地、逐字固定签名、不擅改。
2. **点数信号是否统一为单一订阅通道**：现为「`points_awarded` 广播 + `wave_cleared` 既有契约」双通道，是否满足 I-1~I-6 / A50，请裁决。
3. **任务2 敌人参数末端生成方归属**：按波 `spawn` 敌人时消费 `hp_scale`/`telegraph_scale`/`poise_damage_bonus` 由哪个 Rank 落地（§7 第 3 条）。
4. **`hp_scale` 作用深度**：是否应真正改写 Boss 运行时 HP 上限（涉及 `BossController._hp` / `boss_data` 运行时副本），还是维持「运行时参数字典 + 实例标注」（本轮口径）。
5. **Boon「代价作用于下一波」落地位置**（DONE-R32 裁决项 4 / DONE-R34 §7 第 3 条延续）：`hp_scale`/`telegraph_scale` 与 `wave_trial.tres` 的 `hp_multiplier`/`telegraph_sec` 是独立叠加层还是合并，避免重复放大（本轮为独立乘性层，不与既有倍率叠乘其它层）。
6. **演示未覆盖项处置**（R34 §2.1）：接受「真实链路已接线但 15s 演示未覆盖」，还是延长演示 / 调整按键密度（不改 `[PLACEHOLDER]` 战斗数值）。
7. **既有 autoload 的 2 条 `ERROR:` + 3 条 `WARNING`**：非本轮引入、非 `SCRIPT ERROR`，是否纳入后续清理由总指挥裁决。
8. **实机录屏回看**：headless 真跑无帧缓冲，按公共契约如实登记为后续动作 / 需用户确认（不冒充目视通过）。

---

## 9. 硬约束遵守声明

- 唯一写入方 = Rank-1：仅 `encounter_director.gd`、`hud.gd`、`scripts/render/verify_combo_runtime_v110.gd`、`scripts/render/verify_production_chains_v110.gd`、`teamwork/Rank-1/`、回执；`wave_trial_director.gd` / Rank-2/3/4 产出 / `courtyard.tscn` / `presentation.gd`（本轮只读）/ 既有 `.tres` / 素材只读未改。
- `courtyard.tscn` 静态节点数 `41` / uv `2/1/1` / 节点名（A38）未破坏（GATE-3 + v110 A38-1/2 实证）；5 份 `.tres` md5 与 DONE-R34 逐字一致。
- 纯逻辑边界（I-1 / A50）：R34B 追加段零 `set_flag` / `commit` / `FileAccess` 写盘点（w1 / e3 机器判定）；Combo/Boon 唯一实例由 Rank-2 装配、Rank-1 只复用与方法调用，不写存档、不碰渲染数据文件。
- Godot4 `--script` 纪律：`Engine.get_main_loop() as SceneTree` 取 root、不用 `get_tree()` / 不用 `/root/...` 绝对路径、显式 `call("_ready")` / `call("_r34_bootstrap")`、资源 `CACHE_MODE_IGNORE` 回读、信号 connect 前 `get_signal_connection_list()` 去重 + `_r34_release()` / `_finish()` 断开释放路径；`tick(delta)` 与 `StaggerService.tick` 同一逻辑拍、不重复建计时器。
- 既有 42/24/62/53/110/59 断言逐字不删不放宽；`hud.gd` 1~15 节、`encounter_director.gd` 既有各行逐字未动（仅插入调用 + 追加 R34B 段）。
- 零付费、零外部依赖、不启 GPU job；不伪造产物、不谎报成功、不自行 git；未删除 `.workbuddy`。
- 默认不刺探：未扫目录做进度巡检、未写只读探针 / 巡检脚本；仅按任务单要求读取接口文件与回执目录，真跑日志落在系统临时目录（`/tmp`），未写入工程内。

---

## 10. 回执与中枢归档

- 回执路径（**`teamwork/command_center/`，非工程根**）：
  `teamwork/command_center/ai/1/outbox/cmd-20261112-104355-084-A1.json`
- 四字段：`{"task_id":"cmd-20261112-104355-084-A1","ai":1,"status":"done","result":"引用 DONE-R34B.md 实际结论"}`，
  `result` 引用本报告实际结论。
### 回执写后确认（中枢归档 · 实测，非推断、不伪造、不重放）

```
[中枢自动处理] 回执 <cmd-20261112-104355-084-A1> 由 ai/1/outbox/ 归档至 dispatcher/receipts/
· ai/1/outbox/ 写后已清空（中枢正常回收，与 DONE-R34 §10 口径一致）
· dispatcher/receipts/cmd-20261112-104355-084-A1.json  VALID_JSON=True
  keys=['ai','result','status','task_id'] | task_id 正确 | ai=1 | status=done | result 引用 DONE-R34B.md 实际结论
· dispatcher/ledger.jsonl 新增 1 条：id=cmd-20261112-104355-084-A1 status=done finished_at=2026-11-12 11:19:37，result 与回执逐字一致
· ai/1/status.json：state=idle / current_task="" / completed=61（60→61）/ last_seen=2026-11-12 11:19:37
```

> 回执写后确认归档到 `teamwork/command_center/dispatcher/receipts/`（**是 teamwork/command_center/，不是工程根**）；
> 归档与台账更新由中枢流程完成，Rank-1 只写 outbox、未自建/未伪造归档、未重放。
