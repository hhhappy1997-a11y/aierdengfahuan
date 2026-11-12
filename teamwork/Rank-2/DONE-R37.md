# DONE-R37.md · R37 / v0.14.0「元素瓶与死亡轮回 · 画面补齐」交付报告（Rank-2）

> 轮次：`R37 / v0.14.0` ｜ 任务单 id：`cmd-20261112-184157-082-A2` ｜ 执行 AI：`2（Rank-2 战斗系统与数据驱动）`
> 真源：`teamwork/Rank-2/调度任务单-latest.json`（`task` 全文 + 公共契约 + 目录所有权 + A48 硬要求）
>   + `teamwork/Rank-2/DONE-R36.md` §3（既有服务接口签名）+ `teamwork/00-群聊总线.md` MSG-20261112-1840-HOST（A39~A69 裁决）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> 结论：**三段门禁最终统一 `SCRIPT ERROR=0`（GATE-1/2a/2b/3 全 `EXIT=0`）、三份自测 `RESULT=ALL_MATCH`（49 + 50 + 86 = 185 PASS / 0 FAIL）、10 份既有 `.tres` md5 零改动、`courtyard.tscn node_count=41` 保持、A48①/A54/A55/A57 落地、回执已中枢归档**。
> 如实登记：首次 GATE-1 预检在 **Rank-1 并行写入 `hud.gd` / `encounter_director.gd`（R37 半成品中间态）** 期间出现 2 条 `SCRIPT ERROR`（`at:` 行分别指向 `res://scripts/hud.gd:2459`、`res://scripts/combat/encounter_director.gd:869`，Rank-1 唯一写入方文件、非本轮 Rank-2 文件引入、Rank-2 只读无权改）；Rank-1 收敛后的**正式复跑 + 最终统一三段门禁 `SCRIPT ERROR=0`**（详见 §4.1 / §4.5）。

---

## 1. 交付清单（实际落地文件）

### 机制 ① · 元素瓶（新增 3 件，均归 Rank-2）

| 文件 | 类型 | 作用 |
|---|---|---|
| `godot/data/rpg/flask_rules.tres` | 新增数据表 | `flask_max / heal_amount / rest_refill / invalid_input_policy` 4 个 `[PLACEHOLDER]` 字段，数值真源 / 调参唯一入口 |
| `godot/scripts/combat/flask_config.gd` | 新增 Resource（`class_name FlaskConfig`，`extends Resource`） | 表结构 / 4 字段契约 / `is_valid()` 纯函数 / 逐项 rationale / 降级基线 / 调参唯一入口 |
| `godot/scripts/combat/flask_service.gd` | 新增 RefCounted（`class_name FlaskService`）纯逻辑 | 瓶数扣减 / HP 回复封顶 / 赐福休息补满 / 幂等 / 异常拒绝 + **3 个公开信号** |

### 机制 ② · 死亡轮回（新增 3 件，均归 Rank-2）

| 文件 | 类型 | 作用 |
|---|---|---|
| `godot/data/rpg/death_rules.tres` | 新增数据表 | `drop_ratio / drop_cap / invalid_input_policy` 3 个 `[PLACEHOLDER]` 字段，数值真源 / 调参唯一入口 |
| `godot/scripts/combat/death_config.gd` | 新增 Resource（`class_name DeathConfig`，`extends Resource`） | 表结构 / 3 字段契约 / `is_valid()` 纯函数 / 逐项 rationale / 降级基线 / 调参唯一入口 |
| `godot/scripts/combat/death_service.gd` | 新增 RefCounted（`class_name DeathService`）纯逻辑 | HP 归零→死亡态→记录掉落（独立 dropped/reclaimed 单向 flag）→赐福重生→一次性回收 + **4 个公开信号** |

### 完善功能 ③/④ · 结算与生产接线（修改 1 件，本轮唯一写入方 = Rank-2）

| 文件 | 改动 | 边界 |
|---|---|---|
| `godot/scripts/combat/wave_trial_director.gd` | 9 处精确插入：`FLASK_RULES_PATH` / `DEATH_RULES_PATH` 常量 / 13 个记录字段 / `_init_combat_services()` 装配两个唯一实例并 `_bind_flask_signals()` + `_bind_death_signals()`（A48① 生产订阅者）/ `_reset_r34_records()` 清记录并新局 `reset()` / `_request_grace_rest()` 赐福休息补满瓶 / `_clear_wave()` 回收点数并入 `base_for_combo` 后清零 acc / `get_settlement_snapshot()` 追加 5 个只读 key / `get_snapshot()` 追加 14 个只读 key / 新增 `get_flask_service()` + `get_death_service()` + 7 个生产回调 + 6 个真实输入驱动口 | **既有判定分支 / 帧数据 / 输出格式（`wave_cleared(index,pts)` 签名与值、`_refresh_hud()` 文本、既有 27 + R34 8 + R35 8 + R36 11 个 key）/ 既有 `.tres` 数值一律逐字未动**；回收点数只并入既有 `base_for_combo` 一次 → 经既有 `combo.settle()` 得唯一最终结算值 → HUD 经 `get_last_settlement()` 取该值发 `points_awarded` 一次入账（A57，**不二次入账**）；死亡只做只读记录，**绝不回退 `grace.trial.points`、绝不写 `removals`**（A59） |

### 自测脚本（新增 3 件，均在 `godot/scripts/combat/`）

| 文件 | 作用 | 结果 |
|---|---|---|
| `verify_flask_v140.gd` | 机制 ① 正常 / 边界 / 异常三类：读表 4 字段 + 3 信号、use_flask 成功与 payload、HP 封顶、瓶尽/满血拒绝不扣、赐福休息补满、`REST_KEEP` 对照档、重复按键幂等、瓶数只减不增除休息、reset、12 类异常输入、config=null、set_config(null)、6 类非法表、异常后正常流程、A48① 静态证据 | `pass=49 fail=0 RESULT=ALL_MATCH` |
| `verify_death_v140.gd` | 机制 ② 正常 / 边界 / 异常三类：读表 3 字段 + 4 信号、死亡态与掉落比例、独立 flag、重复死亡不二次掉落、已有未回收掉落不二次掉落、drop_cap 封顶、赐福重生、一次性回收、回收后新周期、死亡期间拒绝行动、6 类异常点数 + 5 类异常 action_id、config=null、5 类非法表、A48① 静态证据 | `pass=50 fail=0 RESULT=ALL_MATCH` |
| `verify_life_settlement_v140.gd` | 掉落 / 一次性回收 / 点数单调 / 瓶数单调 / **md5 前后对比证明 10 份既有表零改动**：真实生产脚本驱动、死亡掉落只读记录（不回退 points / 不写 removals）、回收并入结算（100+100→settled=200）、A57 取源一致、不二次入账、acc 并入后清零、重复回收拒绝、死亡期间拒绝行动、赐福重生复位、既有输出格式零改动、A48① 运行时实证、A54 唯一实例、既有 27+R34 8+R35 8+R36 11 key 逐字仍在 | `pass=86 fail=0 RESULT=ALL_MATCH` |

### 文档 / 回执 / 门禁日志（新增）

| 文件 | 作用 |
|---|---|
| `teamwork/Rank-2/DONE-R37.md` | 本交付报告（交付清单 / 真跑输出原文 / 验收三态 / 公开方法与信号完整签名 / md5 零改动结论 / 未完成项 / 待裁决项） |
| `teamwork/command_center/ai/2/outbox/cmd-20261112-184157-082-A2.json` | 本轮回执，中枢归档见 §11 |
| `teamwork/Rank-2/_gates_R37/*.log` | 三段门禁 13 份真跑日志原文（GATE-1 / GATE-2a×8 / GATE-2b×3 / GATE-3），供复核 |

### 只读未改（硬约束）

`godot/scripts/combat/encounter_director.gd`、`godot/scripts/hud.gd`、`godot/test/presentation.gd`（三者本轮唯一写入方 Rank-1，Rank-2 只读）、
`godot/scripts/rpg/points_commit_orchestrator.gd`、`godot/project.godot`（Rank-3 所有 / A56 autoload）、
`godot/scenes/courtyard.tscn`、场景 / 素材 / 其它 Rank 文件、既有 `.tres`
（`wave_trial.tres` / `boon_draft.tres` / `trial_modifiers.tres` / `stagger_rules.tres` / `combo_rules.tres` / `player_actions.tres` / `boss_01_margit.tres` / `enemy_01_limgrave_soldier.tres` / `parry_rules.tres` / `focus_rules.tres`）。

---

## 2. 玩法拆解表（需求 → 机制 → 数值 → 状态 → 验收）

### 机制 ① · 元素瓶状态机

| 需求 | 机制 | 数值（`[PLACEHOLDER]` 首版） | 状态（实例内、不持久化） | 验收 |
|---|---|---|---|---|
| 携带上限 / 初始满 | 构造 / `reset()` 置 `_flasks = flask_max` | `flask_max=3` | `_flasks` | `initial_flask_full` / `flask_initial_full` |
| 使用回复 HP | `use_flask(current_hp,max_hp)`：config/输入/满血/瓶尽/重复按键五道门；成功 `healed=minf(heal_amount,max_hp-current_hp)`、`hp_after` 封顶 | `heal_amount=50.0` | `_flasks` / `_use_count` / `_duplicate_sig` | `use_flask_ok` / `use_flask_payload` / `flask_used` |
| HP 不超过上限 | `hp_after = minf(max_hp, current_hp + heal_amount)` | — | 返回值 | `hp_not_exceed_max`（80→100 / healed=20） |
| 瓶尽拒绝不扣 | `_flasks <= 0` → `REASON_NO_FLASK`，不扣瓶、不回复 | — | `_flasks` 恒 0 | `no_flask_reject` / `no_flask_no_deduct` |
| 满血拒绝不扣 | `current_hp >= max_hp` → `REASON_FULL_HP`，不扣瓶、不回复 | — | `_flasks` 不变 | `full_hp_reject` / `full_hp_no_deduct` |
| 赐福休息补满 | `on_grace_rest()`：`rest_refill=true` 补满 `flask_max`、清幂等签名、发 `flask_restored`；`false` 保持当前瓶数（`REST_KEEP`） | `rest_refill=true` | `_flasks` / `_restore_count` | `grace_rest_refill` / `rest_keep_policy` / `grace_rest_is_only_increase` |
| 重复按键幂等 | 成功后记录输入签名 `[current_hp,max_hp]`；相邻同签名调用 → `REASON_DUPLICATE` 拒绝、不二次扣瓶、拒绝后清签名 | — | `_duplicate_sig` | `duplicate_key_idempotent` / `duplicate_no_double_deduct` / `different_hp_allowed` |
| 瓶数只减不增除休息 | 一局内连续使用瓶数单调不增、非负、不超上限 | — | `_flasks` | `flask_monotonic_decrease` / `flask_monotonic_decrease_in_run` |
| 异常输入拒绝 | `use_flask(null/非数值/NaN/Inf/负 HP/max_hp<=0/current_hp>max_hp)` → `REASON_INVALID_INPUT`；config=null/非法表 → `REASON_NO_CONFIG`；拒绝不改状态 | `invalid_input_policy="reject"` | 状态不变 | `invalid_input_all_rejected`(12 类) / `invalid_table_*`(6 类) / `invalid_then_normal_ok` |
| 每场重置 | `reset()` 回满瓶、清三类计数 / 最近结果 / 幂等签名 | — | 全状态 | `reset_clears_all` |

### 机制 ② · 死亡轮回状态机

| 需求 | 机制 | 数值（`[PLACEHOLDER]` 首版） | 状态（实例内、不持久化） | 验收 |
|---|---|---|---|---|
| HP 归零 → 死亡态 → 记录掉落 | `on_death(grace_points)`：`dropped=floor(grace_points*drop_ratio)`（受 cap 封顶）；`_is_dead=true` / `_dropped=true` / `_reclaimed=false`；发 `death_occurred` | `drop_ratio=0.5` / `drop_cap=500` | `_is_dead` / `_dropped` / `_reclaimed` / `_dropped_points` / `_grace_snapshot` | `on_death_ok` / `drop_ratio_applied` / `drop_cap_enforced` / `independent_flags` |
| ★ 不回退 points / 不写 removals | 服务**根本不接触存档**，只记只读快照 `_grace_snapshot` 与派生值，用**独立 dropped / reclaimed 单向 flag** 表达（A59） | — | 独立 flag | `no_points_rollback` / `pure_logic_no_save_api` / `no_points_rollback_in_production` |
| 重复死亡不二次掉落 | `_is_dead` → `REASON_ALREADY_DEAD`；`_dropped and not _reclaimed` → `REASON_DROP_PENDING`；均不改本轮掉落 | — | `_dropped_points` 不变 | `duplicate_death_no_second_drop` / `pending_drop_no_second_drop` |
| 赐福重生 | `on_grace_respawn()`：仅死亡态有效 → 置存活、保持掉落 pending、发 `respawn_performed`（携带待回收点数）；**生产订阅者复位 FP / 瓶 / 连击 / 窗口** | — | `_is_dead=false` | `grace_respawn_ok` / `respawn_can_act` / `respawn_resets_runtime` |
| 一次性回收 | `reclaim_dropped()`：死亡期间拒绝（须先重生）、无掉落拒绝、已回收拒绝（`REASON_ALREADY_RECLAIMED`）；成功置 `_reclaimed=true`、发 `points_reclaimed` | — | `_reclaimed` / `_reclaim_count` | `reclaim_once_ok` / `reclaim_only_once` / `reclaim_second_rejected` / `settled_200_after_duplicate_reclaim` |
| 死亡期间拒绝行动 | `request_action(action_id)` / `can_act()`：死亡期间 `REASON_DEAD`；异常 id `REASON_INVALID_INPUT` | — | `_is_dead` | `dead_action_rejected` / `dead_action_rejected_in_production` / `dead_reclaim_rejected` |
| 回收后新周期 | `_reclaimed=true` 时允许再次 `on_death`（新掉落周期，不二次回收旧掉落） | — | flag 复位 | `new_cycle_after_reclaim` |
| 异常输入拒绝 | `on_death(null/负/字符串/数组/NaN/Inf)` → `REASON_INVALID_INPUT`；config=null/非法表 → `REASON_NO_CONFIG` | `invalid_input_policy="reject"` | 状态不变 | `invalid_points_all_rejected`(6 类) / `invalid_action_all_rejected`(5 类) / `invalid_table_*`(5 类) |
| 每场重置 | `reset()` 清死亡态 / 两个单向 flag / 掉落记录 / 三类计数 | — | 全状态 | `reset_clears_all` |

### 结算接线（沿用 A55/A57：最终结算值经 `points_awarded` 发出，不二次入账）

| 需求 | 落地位置 | 效果 | 验收 |
|---|---|---|---|
| 回收点数并入清波点数结算 | `_clear_wave()`：`base_for_combo = maxi(0, base_for_combo + _death_reclaim_acc)`（在 R36 战技并入之后、既有 `combo.settle(base_for_combo)` 之前插入一行）；随即 `_death_reclaim_acc = 0` | 唯一最终结算值 `settled_points` 含回收点数；HUD 经 `combo.get_last_settlement()` 取同值发 `points_awarded` 一次 | `reclaim_into_settled_200`（100+100→200）/ `a57_awarded_source_consistent` / `no_double_settle_one` / `reclaim_acc_cleared_after_settle` |
| 赐福休息补满瓶 | `_request_grace_rest()`：`if _flask != null: _flask.on_grace_rest()`（与 R36 `_focus.on_grace_rest()` 同构） | 生产链路补瓶，不改既有分支 | `flask_grace_rest_refill` |
| 死亡 / 重生复位运行时状态 | 生产订阅者 `_on_respawn_performed()`：`_flask.on_grace_rest()`（回满瓶）/ `_focus.on_grace_rest()`（回满 FP / 清冷却）/ `_combo.reset()`（重置连击）/ `_parry.reset()`（重置窗口）/ 清本波累计 / 相对探活调既有 `trial_grace_rest()`（HP 回满归 Rank-1） | 重生后运行时干净态，不把死亡前加成带进重生后清波结算 | `respawn_resets_runtime` / `respawn_refills_flask` |
| 点数只增不减 / 余额非负 / 不重复结算 / acc 清零 | `settled_points` 恒 `>=0`、既有 `_persist_settle` max 保护、既有 `WAVE_ACTIVE` 门控拒绝重复 `on_encounter_finished`、并入后 `_death_reclaim_acc=0` | 不二次入账 | `points_monotonic_increase` / `balance_nonneg` / `no_double_settle` / `monotonic_after_duplicate` |
| 既有输出格式零改动 | `wave_cleared.emit(_index, pts)` 第二参仍为基础 `pts`；`get_snapshot()` 既有 27 + R34 8 + R35 8 + R36 11 个 key 逐字不动，只追加 14 个只读 key | 回归不回退 | `wave_cleared_format_unchanged` / `legacy_snapshot_keys_all_present` / `r34/r35/r36_snapshot_keys_intact` |

### 数值拆解 / rationale（完整版见 `flask_config.gd` / `death_config.gd` 头注）

- **调参唯一入口（只改表不改代码）**：`godot/data/rpg/flask_rules.tres` 与 `godot/data/rpg/death_rules.tres`。代码内 `FlaskConfig.DEFAULT_*` / `DeathConfig.DEFAULT_*` 是**非法降级基线**（刻意 `!=` 表值，`verify_*_v140.gd` 的 `default_is_not_design_*` 机器判定），不是设计数值。校准同步清单：`.tres` → `verify_*_v140.gd` 的 `EXPECT_*` → 本文数值表 → 三段门禁；不静默改数。
- `flask_max = 3` `[PLACEHOLDER]`：对标原作「元素瓶」初始携带数，取 3 便于 15~20 秒录屏里肉眼观察「3→2→1→0→休息回满 3」离散递减；与既有 `focus fp_max=100.0` / `stagger_max=100.0` 不同量纲（离散次数 vs 连续量），不混用。
- `heal_amount = 50.0` `[PLACEHOLDER]`：以 `max_hp=100.0` 为参照，一次回复半血；实际恒 `minf(heal_amount, max_hp-current_hp)` 封顶保证「HP 不超过上限」；纯恢复量、不并入结算，不造成点数通胀（A51/A60 精神）。
- `rest_refill = true` `[PLACEHOLDER]`：赐福休息是**唯一**允许瓶数增加的出口（守住「瓶数只减不增除休息」）；置 false 切「保持当前瓶数」对照档（`REST_KEEP`），不改代码。
- `drop_ratio = 0.5` `[PLACEHOLDER]`：死亡掉落取当前赐福点数的 50%，对标原作「死亡掉落卢恩、回死亡点可捡回」叙事张力；但**磁盘 `grace.trial.points` 绝不回退、绝不写 `removals`**（A59），掉落只是 `DeathService` 实例内的记录 + 两个独立单向 flag。回收时该点数经既有清波结算链路（A55/A57 `points_awarded`）**一次入账**，点数只增不减、余额非负。
- `drop_cap = 500` `[PLACEHOLDER]`：单次掉落上限，防极端存档下按比例掉落过大、回收时点数跳变造成通胀观感（A51/A60 精神）；`0` = 不封顶，供裁决切换。
- `invalid_input_policy = "reject"`（两表同值）`[PLACEHOLDER]`：异常输入一律拒绝且不改状态，避免 clamp / ignore 造成「隐式扣瓶 / 隐式二次回收」的不可测分支；首版唯一合法值。

### 结算值两组实证（均 `RESULT=ALL_MATCH`）

| 组合 | base 推导 | 倍率 | 最终结算值 | 断言 |
|---|---|---|---|---|
| 基线（无死亡 / 0 连击） | `100` | D 1.0 | **100** | `baseline_settled_100` |
| 死亡(200)→重生→回收(100)→清波 | `100 + 100 = 200` | D 1.0 | **200** | `reclaim_into_settled_200` / `a57_awarded_source_consistent` / `points_total_200` |

---

## 3. 供 Rank-1 与 Rank-4 使用的公开方法与信号完整签名（本轮重点）

> `FlaskService` / `DeathService` 是 `RefCounted` 纯逻辑，**信号是 Object 级能力**：Rank-1 / Rank-4 直接 `connect` 到本服务实例即可，
> 无需场景树、无需 `add_child`、无需 `/root/...`。以下签名**稳定、不再改动**。
> **A54 唯一实例**：由 `wave_trial_director.gd` 装配，Rank-1 / Rank-4 经 `get_flask_service()` / `get_death_service()` 复用，绝不另建第二个。
> **★ GATE-3 实证**：Rank-1 的 `hud.gd` / `encounter_director.gd` 已按本节签名复用唯一实例（`[R37][HUD] 生产装配 | flask_unique=true death_unique=true grace_subscribed=true`、`[R37][ENC] 生产装配 | flask_unique=true death_unique=true flask_signal_subscribed=true`）。

### 3.1 公开信号（`godot/scripts/combat/flask_service.gd`，3 个）

```
signal flask_used(flask_before: int, flask_after: int, hp_before: float, hp_after: float, healed: float)
    # use_flask() 成功时发；payload = 使用前后瓶数 / 使用前后 HP / 实际回复量。
    # 供 Rank-1 结算接线 / Rank-4 元素瓶演出（回复光晕、血条补间、瓶数递减）。
    # ★ A48①：生产订阅者 = wave_trial_director._bind_flask_signals()（生产节点，非验证脚本）。
signal flask_rejected(reason: String, flask_remaining: int)
    # 使用被拒时发；reason ∈ {no_config, invalid_input, full_hp, no_flask, duplicate}。
    # 供 Rank-4「无瓶 / 满血 / 重复按键」失败反馈 / HUD 提示。
signal flask_restored(flask_before: int, flask_after: int, policy: String)
    # on_grace_rest() 补瓶时发；policy ∈ {REST_REFILL="rest_refill", REST_KEEP="rest_keep"}。
    # 供 Rank-4 赐福休息演出 / HUD 瓶数回满。
```

### 3.2 `FlaskService` 公开方法（全静态类型）

```
class_name FlaskService (extends RefCounted)
_init(config: FlaskConfig = null)                 # 构造注入规则表，自动 reset()（瓶回满）
set_config(config: FlaskConfig) -> void           # 替换表并 reset()（含 null 降级验证）
get_config() -> FlaskConfig
reset() -> void                                  # 回满瓶、清三类计数 / 最近结果 / 幂等签名（每场新一局）
use_flask(current_hp: Variant, max_hp: Variant) -> Dictionary
                                                 # 使用元素瓶；config/输入/满血/瓶尽/重复按键五道门，
                                                 # 成功扣 1 瓶并返回 hp_after（HP 封顶 max_hp）
on_grace_rest() -> Dictionary                     # 赐福休息：补满瓶或保持（唯一允许瓶数增加的出口）
                                                 # ★ 本服务唯一允许 _flasks 增加的出口

get_flasks() -> int
get_flask_remaining() -> int                      # 同义，供 HUD 鸭子类型
get_flask_max() -> int
get_use_count() -> int
get_reject_count() -> int
get_restore_count() -> int
get_last_result() -> Dictionary                  # 最近一次成功结果（Dictionary 副本）
get_last_reject_reason() -> String
get_invalid_input_policy() -> String
is_config_valid() -> bool
get_snapshot() -> Dictionary                     # 全状态快照（见 §3.3）
```

**接线注意**：① 本服务**不持有 HP**，`current_hp` / `max_hp` 由 Rank-1 输入层传入，成功返回的 `hp_after` 由 Rank-1 作用到真实 HP 实例；② 每场新一局调一次 `reset()`（本轮 `start_trial()` 已接）；③ 赐福休息由 `_request_grace_rest()` 生产链路调 `on_grace_rest()`，或由 Rank-1 经 `flask_grace_rest()` 驱动口调用；④ 相邻同签名 `use_flask` 幂等拒绝（不二次扣瓶）；⑤ 纯逻辑无 `tick`，不依赖每帧转发；⑥ 不读写存档、不碰渲染。

### 3.3 `FlaskService` 返回 Dictionary 字段（供 Rank-1 / Rank-4 消费）

```
use_flask      : {ok, reason, flask_before, flask_after, hp_before, hp_after, healed,
                 use_count, config_present}
on_grace_rest  : {ok, reason, flask_before, flask_after, flask_max, policy,
                 restore_count, config_present}
get_snapshot   : {flasks, flask_max, flask_remaining, heal_amount, rest_refill,
                 invalid_input_policy, use_count, reject_count, restore_count,
                 config_present, last_result, last_reject_reason}
```

成功恒 `healed>0` / `hp_after<=max_hp` / `flask_after=flask_before-1`；拒绝时 `healed=0` / `hp_before=hp_after=0`、不改瓶数。

### 3.4 `FlaskService` / `FlaskConfig` 公开常量（签名稳定）

```
FlaskService reason:
    REASON_OK              = "ok"
    REASON_NO_CONFIG       = "no_config"        # config 缺失 / 非法表
    REASON_INVALID_INPUT   = "invalid_input"    # 异常 HP / null / NaN / Inf / 负 / 超上限
    REASON_FULL_HP         = "full_hp"          # 满血拒绝且不扣
    REASON_NO_FLASK        = "no_flask"         # 瓶尽拒绝且不扣
    REASON_DUPLICATE       = "duplicate"        # 相邻同签名重复按键幂等拒绝
flask_restored.policy:
    REST_REFILL            = "rest_refill"      # 表 rest_refill=true：补满 flask_max
    REST_KEEP              = "rest_keep"        # 表 rest_refill=false：保持当前瓶数
FlaskConfig:
    POLICY_REJECT          = "reject"           # 唯一合法 invalid_input_policy
    DEFAULT_FLASK_MAX / DEFAULT_HEAL_AMOUNT / DEFAULT_REST_REFILL /
    DEFAULT_INVALID_INPUT_POLICY                # 降级基线（刻意 != 表值，非设计数值）
```

### 3.5 `FlaskConfig` 公开接口（`extends Resource` / `class_name FlaskConfig`）

```
@export var flask_max: int                     # 瓶数上限（表值 [PLACEHOLDER]）
@export var heal_amount: float                 # 单次回复量（表值 [PLACEHOLDER]）
@export var rest_refill: bool                  # true=补满 / false=保持（表值 [PLACEHOLDER]）
@export var invalid_input_policy: String      # 异常输入策略，唯一合法值 POLICY_REJECT="reject"
is_valid() -> bool                            # 4 字段类型合法 / flask_max 为正整数 / heal_amount>0 且有限 /
                                              # policy==reject；异常一律 false（不崩）
get_flask_max() -> int / get_heal_amount() -> float / get_rest_refill() -> bool /
get_invalid_input_policy() -> String
```

### 3.6 公开信号（`godot/scripts/combat/death_service.gd`，4 个）

```
signal death_occurred(dropped_points: int, grace_points_snapshot: int)
    # on_death() 成功、进入死亡态并记录掉落时发；payload 只是【只读记录】，
    # ★ 绝不回退 grace.trial.points、绝不写 removals（A59）。
    # 供 Rank-1 结算接线 / Rank-3 落盘 flag / Rank-4 死亡演出（冷夜雾收束 / 画面压暗）。
    # ★ A48①：生产订阅者 = wave_trial_director._bind_death_signals()（生产节点，非验证脚本）。
signal respawn_performed(pending_dropped_points: int)
    # on_grace_respawn() 成功、赐福重生复位时发；携带待回收掉落点数。
    # 供生产订阅者复位 FP / 瓶 / 连击 / 窗口、Rank-4 重生演出（暖金扩散环）。
signal points_reclaimed(points: int, grace_points_snapshot: int)
    # reclaim_dropped() 成功、一次性回收时发；points 供生产订阅者并入既有清波点数结算基数
    # （A55/A57 经 points_awarded 一次入账，不二次入账）。
signal action_rejected(reason: String, action_id: String)
    # 死亡期间行动 / 异常输入 / 重复死亡 / 重复回收被拒时发；reason 供 Rank-4 反馈。
```

### 3.7 `DeathService` 公开方法（全静态类型）

```
class_name DeathService (extends RefCounted)
_init(config: DeathConfig = null)             # 构造注入规则表，自动 reset()
set_config(config: DeathConfig) -> void       # 替换表并 reset()（含 null 降级验证）
get_config() -> DeathConfig
reset() -> void                              # 清死亡态 / 两个单向 flag / 掉落记录 / 三类计数（每场新一局）
on_death(grace_points: Variant) -> Dictionary
                                             # HP 归零 → 死亡态 → 记录掉落点数（只读，不回退 points）
on_grace_respawn() -> Dictionary             # 赐福重生：仅死亡态有效，置存活、保持掉落 pending
reclaim_dropped() -> Dictionary               # 一次性回收；死亡期间 / 无掉落 / 已回收一律拒绝
request_action(action_id: Variant) -> Dictionary
                                             # 死亡期间 / 异常 id 拒绝；存活且合法才放行（纯逻辑门禁）
can_act() -> bool                            # not _is_dead
is_dead() -> bool
has_pending_drop() -> bool                   # _dropped and not _reclaimed
is_reclaimed() -> bool
get_dropped_points() -> int
get_grace_snapshot() -> int                  # 死亡时 grace.trial.points 的只读快照
get_death_count() -> int
get_respawn_count() -> int
get_reclaim_count() -> int
get_reject_count() -> int
get_last_result() -> Dictionary
get_last_reject_reason() -> String
get_invalid_input_policy() -> String
is_config_valid() -> bool
get_snapshot() -> Dictionary                 # 全状态快照（见 §3.8）
```

**接线注意**：① 掉落是**叙事层记录 + 独立单向 flag**，磁盘 `grace.trial.points` 绝不回退、绝不写 `removals`；② 回收点数由生产订阅者 `_on_points_reclaimed()` 累计到 `_death_reclaim_acc`，在 `_clear_wave()` 并入既有 `base_for_combo` → `combo.settle()` → HUD `points_awarded` 一次入账，并入后 acc 清零；③ 死亡期间 `can_act()=false` / `request_action` 拒绝 / `reclaim_dropped` 拒绝（须先 `on_grace_respawn()`）；④ 回收只生效一次；⑤ 不读写存档、不碰渲染。

### 3.8 `DeathService` 返回 Dictionary 字段（供 Rank-1 / Rank-4 消费）

```
on_death          : {ok, reason, dropped_points, grace_points_snapshot, is_dead,
                     dropped, reclaimed, death_count, config_present}
on_grace_respawn  : {ok, reason, is_dead, dropped, reclaimed,
                     pending_dropped_points, respawn_count, config_present}
reclaim_dropped   : {ok, reason, points, dropped_points, grace_points_snapshot,
                     reclaimed, reclaim_count, config_present}
request_action    : {ok, reason, action_id, is_dead, config_present}
                    或拒绝体 {ok, reason, action_id, is_dead, dropped, reclaimed,
                             dropped_points, grace_points_snapshot, points=0,
                             death_count, respawn_count, reclaim_count, config_present}
get_snapshot      : {is_dead, dropped, reclaimed, dropped_points, grace_points_snapshot,
                     drop_ratio, drop_cap, invalid_input_policy, can_act, has_pending_drop,
                     death_count, respawn_count, reclaim_count, reject_count,
                     config_present, last_result, last_reject_reason}
```

成功恒 `dropped_points>=0` / `points>=0`；拒绝时 `points=0`、不改本轮掉落记录与两个单向 flag。

### 3.9 `DeathService` / `DeathConfig` 公开常量（签名稳定）

```
DeathService reason:
    REASON_OK                 = "ok"
    REASON_NO_CONFIG          = "no_config"        # config 缺失 / 非法表
    REASON_INVALID_INPUT      = "invalid_input"    # 异常点数 / 异常 action_id
    REASON_ALREADY_DEAD       = "already_dead"     # 死亡期间重复死亡（不二次掉落）
    REASON_DROP_PENDING       = "drop_pending"     # 已有未回收掉落（不二次掉落）
    REASON_NOT_DEAD           = "not_dead"         # 非死亡态调用 on_grace_respawn
    REASON_NO_DROP            = "no_drop"          # 无掉落可回收
    REASON_ALREADY_RECLAIMED  = "already_reclaimed"# 回收只生效一次
    REASON_DEAD               = "dead"             # 死亡期间拒绝行动 / 回收
    ACTION_ID_NONE            = "<none>"           # 非 String action_id 在 action_rejected payload 的占位
DeathConfig:
    POLICY_REJECT             = "reject"
    DEFAULT_DROP_RATIO / DEFAULT_DROP_CAP / DEFAULT_INVALID_INPUT_POLICY  # 降级基线（!= 表值）
```

### 3.10 `DeathConfig` 公开接口（`extends Resource` / `class_name DeathConfig`）

```
@export var drop_ratio: float                  # 掉落比例，0<=r<=1（表值 [PLACEHOLDER]）
@export var drop_cap: int                      # 单次掉落上限，0=不封顶（表值 [PLACEHOLDER]）
@export var invalid_input_policy: String      # 异常输入策略，唯一合法值 POLICY_REJECT="reject"
is_valid() -> bool                            # 3 字段类型合法 / 0<=ratio<=1 且有限 / cap 非负整数 /
                                              # policy==reject；异常一律 false（不崩）
get_drop_ratio() -> float / get_drop_cap() -> int / get_invalid_input_policy() -> String
```

### 3.11 `wave_trial_director.gd` 本轮新增公开接口（供 Rank-1 / 验证 / HUD / Rank-4）

```
get_flask_service() -> FlaskService            # ★ A54 唯一实例（Rank-1 / Rank-4 / Rank-3 复用）
get_death_service() -> DeathService            # ★ A54 唯一实例（Rank-1 / Rank-4 / Rank-3 复用）

# 真实输入驱动口（转调 A54 唯一实例，供 Rank-1 输入层 / 验证调用）
use_flask(current_hp: Variant, max_hp: Variant) -> Dictionary
flask_grace_rest() -> Dictionary
on_player_death(grace_points: Variant) -> Dictionary
on_grace_respawn() -> Dictionary
reclaim_dropped_points() -> Dictionary
guard_life_action(action_id: Variant) -> Dictionary

get_settlement_snapshot() 追加 5 个只读 key（既有 key 逐字不动）：
    life_reclaim_bonus / life_reclaim_count / flask_use_count /
    life_death_count / life_respawn_count
get_snapshot() 追加 14 个只读 key（既有 27 + R34 8 + R35 8 + R36 11 个 key 逐字不动）：
    flask_remaining / flask_max / flask_use_count / flask_reject_count / flask_restore_count /
    life_is_dead / life_dropped_points / life_grace_snapshot / life_death_count /
    life_respawn_count / life_reclaim_count / life_reclaim_acc / life_reject_count /
    life_last_reject_reason
```

### 3.12 Rank-1 接线示意（伪代码，供 `encounter_director.gd` / `hud.gd` / 输入层）

```gdscript
# A54 唯一实例：从波次导演复用，绝不 new 第二个 FlaskService / DeathService
var flask: FlaskService = wave_trial_director.get_flask_service()
var death: DeathService = wave_trial_director.get_death_service()
flask.connect("flask_used",           Callable(self, "_on_flask_used"))
flask.connect("flask_rejected",       Callable(self, "_on_flask_rejected"))
flask.connect("flask_restored",       Callable(self, "_on_flask_restored"))
death.connect("death_occurred",       Callable(self, "_on_death_occurred"))
death.connect("respawn_performed",    Callable(self, "_on_respawn_performed"))
death.connect("points_reclaimed",     Callable(self, "_on_points_reclaimed"))
death.connect("action_rejected",      Callable(self, "_on_action_rejected"))

func _on_flask_key_pressed() -> void:
    var r: Dictionary = flask.use_flask(current_hp, max_hp)   # 或 wave_trial_director.use_flask(current_hp, max_hp)
    if r.ok:
        player_hp = r.hp_after        # Rank-1 把回满后的 HP 作用到真实实例
func _on_player_hp_zero(grace_points: int) -> void:
    death.on_death(grace_points)       # 或 wave_trial_director.on_player_death(grace_points)
    # 死亡期间据 death.can_act() / guard_life_action() 拒绝行动
func _on_grace_rest() -> void:
    flask.on_grace_rest()              # 或 wave_trial_director.flask_grace_rest()
    death.on_grace_respawn()           # 或 wave_trial_director.on_grace_respawn()
    # 回到死亡点一次性回收：wave_trial_director.reclaim_dropped_points()
# HUD 瓶数条：flask.get_snapshot() 的 flasks / flask_max / flask_remaining 直接可读
# 结算：points_reclaimed 的 points 已由 wave_trial_director 生产订阅者并入
#       base_for_combo → combo.settle() 唯一最终值 → HUD points_awarded 一次入账（A57）
```

### 3.13 Rank-4 视觉反馈接线示意（订阅同一实例，不经场景树）

```gdscript
func _on_flask_used(flask_before: int, flask_after: int, hp_before: float,
        hp_after: float, healed: float) -> void:
    # 元素瓶短促翠绿/暖金回复光晕；hp_before/hp_after 供血条补间；flask_before/after 供瓶数递减
func _on_flask_rejected(reason: String, flask_remaining: int) -> void:
    # reason ∈ no_config / invalid_input / full_hp / no_flask / duplicate：「无瓶」「满血」图标置灰
func _on_flask_restored(flask_before: int, flask_after: int, policy: String) -> void:
    # 赐福休息回满演出；policy ∈ rest_refill / rest_keep
func _on_death_occurred(dropped_points: int, grace_points_snapshot: int) -> void:
    # 死亡瞬间冷夜雾收束 + 画面压暗（不过黑、HUD 文字仍可读）；dropped_points 供掉落飘字
func _on_respawn_performed(pending_dropped_points: int) -> void:
    # 赐福重生暖金扩散环；pending_dropped_points 供「待回收」提示
func _on_points_reclaimed(points: int, grace_points_snapshot: int) -> void:
    # 一次性回收演出 / 飘字；points 已由导演层并入结算（Rank-4 不再结算）
func _on_action_rejected(reason: String, action_id: String) -> void:
    # 死亡期间行动 / 异常输入反馈
```

### 3.14 A48① 生产运行时订阅者清单（不能只在验证脚本里）

| 服务 | 信号 | 生产订阅者（生产节点，非验证脚本） | 真实职责 |
|---|---|---|---|
| FlaskService | `flask_used` | `wave_trial_director._on_flask_used()` | `_flask_use_count` 计数 / A48① 运行时实证 |
| FlaskService | `flask_rejected` | `wave_trial_director._on_flask_rejected()` | 拒绝计数 / 最近 reason 记录 |
| FlaskService | `flask_restored` | `wave_trial_director._on_flask_restored()` | 补瓶计数 |
| DeathService | `death_occurred` | `wave_trial_director._on_death_occurred()` | 只读记录掉落 / 快照（**不回退 points、不写 removals**） |
| DeathService | `respawn_performed` | `wave_trial_director._on_respawn_performed()` | 复位 FP / 瓶 / 连击 / 窗口 + 清本波累计 |
| DeathService | `points_reclaimed` | `wave_trial_director._on_points_reclaimed()` | 累计 `_death_reclaim_acc` → 清波一次入账（A55/A57） |
| DeathService | `action_rejected` | `wave_trial_director._on_life_action_rejected()` | 拒绝计数 / 最近 reason 记录 |

装配入口 `_init_combat_services()` → `_bind_flask_signals()` / `_bind_death_signals()`，GATE-3 主场景日志实证（§4.4）；Rank-1 `hud.gd` / `encounter_director.gd` 亦已按 §3 复用同一实例订阅（GATE-3 `[R37][HUD]` / `[R37][ENC]` 行）。

---

## 4. 真跑输出原文（三段门禁，最终统一 `SCRIPT ERROR=0`）

命令前缀统一为 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；
引擎版本行：`Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org`。日志全文留存 `teamwork/Rank-2/_gates_R37/*.log`。

### GATE-1 `--headless --import`（首次预检：注册 4 个新全局类）

```
[   0% ] update_scripts_classes | Started 正在注册全局类…… (7 steps)
[   0% ] update_scripts_classes | DeathConfig
[  12% ] update_scripts_classes | DeathService
[  25% ] update_scripts_classes | EncounterDirector
[  37% ] update_scripts_classes | FlaskConfig
[  50% ] update_scripts_classes | FlaskService
[ DONE ] update_scripts_classes
GATE1_EXIT=0
```

**如实登记（并发中间态，与 R36 §4.4 同类）**：首次预检另有 2 条 `SCRIPT ERROR`，`at:` 行分别指向 `res://scripts/hud.gd:2459`（`There is already a variable named "dl" declared in this scope.`）与 `res://scripts/combat/encounter_director.gd:869`（`Function "_r37_bootstrap()" not found in base self.`）—— 均为 **Rank-1 并行写入 R37 半成品中间态**（Rank-1 唯一写入方文件、非本轮 Rank-2 文件引入、Rank-2 只读无权改）。归属核验：`SCRIPT ERROR` 无一条指向 Rank-2 本轮 6 个新文件 / `wave_trial_director.gd`。Rank-1 收敛后**立即复跑**：

```
GATE1_EXIT=0   SCRIPT ERROR=0（正式复跑，类已注册不再重复打印注册行）
```

### GATE-2a `--check-only --script`（语法门禁，8 件）

```
CHECK_ONLY flask_config                    EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY flask_service                   EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY death_config                    EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY death_service                   EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY wave_trial_director             EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY verify_flask_v140               EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY verify_death_v140               EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY verify_life_settlement_v140     EXIT=0  SCRIPT_ERROR=0
```

### GATE-2b `--headless --script <verify>`（实跑，3 份逐条 `PASS=true`）

`verify_flask_v140.gd`（49 条全 `PASS=true`，正常 / 边界 / 异常三类，代表行与汇总）：

```
[V140-FL] === SELFTEST START ===
[V140-FL] scene_tree_root_via_main_loop PASS=true | Engine.get_main_loop() as SceneTree -> root，不用 get_tree()/绝对路径
[V140-FL] table_load_cache_ignore PASS=true | path=res://data/rpg/flask_rules.tres
[V140-FL] ruleset_valid PASS=true | FlaskConfig.is_valid()=true
[V140-FL] flask_max_ph PASS=true | got=3 expect=3 [PLACEHOLDER]
[V140-FL] heal_amount_ph PASS=true | got=50.0 expect=50.0 [PLACEHOLDER]
[V140-FL] rest_refill_ph PASS=true | got=true expect=true [PLACEHOLDER]
[V140-FL] invalid_input_policy_ph PASS=true | got=reject expect=reject [PLACEHOLDER]
[V140-FL] default_is_not_design_flask_max PASS=true | DEFAULT_FLASK_MAX=1 != 表值 3（调参唯一入口在 .tres）
[V140-FL] signal_used_exists PASS=true | signal flask_used(flask_before, flask_after, hp_before, hp_after, healed)
[V140-FL] use_flask_ok PASS=true | use_flask(50,100) -> 成功
[V140-FL] use_flask_payload PASS=true | payload=(3->2, 50->100, healed=50) [PLACEHOLDER]
[V140-FL] hp_not_exceed_max PASS=true | use_flask(80,100) -> hp_after=100 / healed=20（封顶不超上限）
[V140-FL] full_hp_reject PASS=true | 满血 use_flask(100,100) -> full_hp 拒绝
[V140-FL] full_hp_no_deduct PASS=true | 满血拒绝且不扣瓶 / 不增 use_count
[V140-FL] no_flask_reject PASS=true | 瓶尽 use_flask -> no_flask 拒绝且不扣（瓶数恒 0）
[V140-FL] grace_rest_refill PASS=true | 赐福休息补满 0->3 / policy=rest_refill [PLACEHOLDER]
[V140-FL] rest_keep_policy PASS=true | rest_refill=false -> REST_KEEP，瓶数保持 2（对照档，不改代码）
[V140-FL] duplicate_key_idempotent PASS=true | 相邻同签名重复按键 -> duplicate 拒绝（幂等）
[V140-FL] duplicate_no_double_deduct PASS=true | 重复按键不二次扣瓶 / 不二次回复（瓶数恒 2、use_count 恒 1）
[V140-FL] flask_monotonic_decrease PASS=true | 一局内瓶数序列 [3, 2, 1, 0] 只减不增 / 非负 / 不超上限
[V140-FL] invalid_input_all_rejected PASS=true | 12 类异常输入全部 invalid_input 拒绝（null/字符串/数组/NaN/Inf/负/超上限）
[V140-FL] invalid_then_normal_ok PASS=true | 异常输入拒绝后正常使用仍得 hp_after=100（状态未被污染）
[V140-FL] no_config_reject PASS=true | config=null -> use_flask 拒绝 REASON_NO_CONFIG（不崩）
[V140-FL] production_subscriber_in_source PASS=true | 生产源码含 3 信号订阅者 + 唯一实例 getter + 赐福休息补满 + 驱动口（A48①/A54）
[V140-FL] SUMMARY pass=49 fail=0
[V140-FL] OVERALL=PASS
[V140-FL] RESULT=ALL_MATCH
[V140-FL] === SELFTEST END ===
verify_flask_v140_EXIT=0   SCRIPT_ERROR=0
```

`verify_death_v140.gd`（50 条全 `PASS=true`，代表行与汇总）：

```
[V140-DT] === SELFTEST START ===
[V140-DT] table_load_cache_ignore PASS=true | path=res://data/rpg/death_rules.tres
[V140-DT] drop_ratio_ph PASS=true | got=0.50 expect=0.50 [PLACEHOLDER]
[V140-DT] drop_cap_ph PASS=true | got=500 expect=500 [PLACEHOLDER]
[V140-DT] signal_death_exists PASS=true | signal death_occurred(dropped_points, grace_points_snapshot)
[V140-DT] signal_respawn_exists PASS=true | signal respawn_performed(pending_dropped_points)
[V140-DT] signal_reclaimed_exists PASS=true | signal points_reclaimed(points, grace_points_snapshot)
[V140-DT] drop_ratio_applied PASS=true | dropped=floor(200*0.5)=100 / 只读快照=200 [PLACEHOLDER]
[V140-DT] independent_flags PASS=true | 独立单向 flag：dropped=true / reclaimed=false / is_dead=true
[V140-DT] no_points_rollback PASS=true | ★ 只读快照=200 / 掉落记录=100：绝不回退 grace.trial.points、绝不写 removals（A59）
[V140-DT] pure_logic_no_save_api PASS=true | 纯逻辑服务不暴露 set_flag / commit / removals / add_child / get_tree（I-1）
[V140-DT] duplicate_death_no_second_drop PASS=true | 死亡期间重复 on_death(500) -> already_dead，不二次掉落（掉落恒 100）
[V140-DT] pending_drop_no_second_drop PASS=true | 已有未回收掉落时再死亡 -> drop_pending，不二次掉落
[V140-DT] drop_cap_enforced PASS=true | floor(2000*0.5)=1000 -> drop_cap=500 封顶 [PLACEHOLDER]
[V140-DT] signal_respawn_once PASS=true | respawn_performed(100) 恰 1 次（供生产订阅者复位 FP/瓶/连击/窗口）
[V140-DT] reclaim_once_ok PASS=true | reclaim_dropped() -> points=100 / reclaimed=true（一次性回收）
[V140-DT] reclaim_only_once PASS=true | ★ 回收只生效一次：第二次 -> already_reclaimed / points=0 / 计数恒 1
[V140-DT] dead_action_rejected PASS=true | 死亡期间 request_action(attack) -> dead 拒绝、can_act=false
[V140-DT] new_cycle_after_reclaim PASS=true | 回收完成后再死亡 -> 新掉落周期 dropped=200（不二次回收旧掉落）
[V140-DT] invalid_points_all_rejected PASS=true | 6 类异常点数全部 invalid_input 拒绝（null/负/字符串/数组/NaN/Inf）
[V140-DT] invalid_action_all_rejected PASS=true | 5 类异常 action_id 全部 invalid_input 拒绝
[V140-DT] invalid_then_normal_ok PASS=true | 异常输入拒绝后正常死亡仍得 dropped=100（状态未被污染）
[V140-DT] production_subscriber_in_source PASS=true | 生产源码含 4 信号订阅者 + 唯一实例 getter + 回收并入结算 + 赐福休息补满（A48①/A54/A57）
[V140-DT] SUMMARY pass=50 fail=0
[V140-DT] OVERALL=PASS
[V140-DT] RESULT=ALL_MATCH
[V140-DT] === SELFTEST END ===
verify_death_v140_EXIT=0   SCRIPT_ERROR=0
```

`verify_life_settlement_v140.gd`（86 条全 `PASS=true`，关键行与汇总）：

```
[V140-LS] === SELFTEST START ===
[V140-LS] scene_tree_root_via_main_loop PASS=true | Engine.get_main_loop() as SceneTree -> root
[V140-LS] md5_before_wave_trial.tres_nonempty PASS=true | wave_trial.tres md5(before)=793b6daa7c7730feed1a3f849701d58a
[V140-LS] md5_before_focus_rules.tres_nonempty PASS=true | focus_rules.tres md5(before)=289fd4f08424658d9625fd3ac3d93bfd
[V140-LS] md5_before_flask_rules.tres_nonempty PASS=true | flask_rules.tres md5(before)=13071ccf0574ddbbc45117044547976d
[V140-LS] md5_before_death_rules.tres_nonempty PASS=true | death_rules.tres md5(before)=e5ad808f555c51b9df1e9bf8ab95c9f3
[V140-LS] persist_explicitly_downgraded PASS=true | bind_persistence(null,null) -> persist_available=false（不写生产存档）
[V140-LS] baseline_settled_100 PASS=true | 无死亡 / 0 连击 -> settled=100（D 级 mult=1.0，与既有等价）
[V140-LS] a54_all_services_present PASS=true | 6 个纯逻辑服务均已装配（A54：唯一实例经 get_*_service() 复用）
[V140-LS] flask_initial_full PASS=true | flask_remaining=3 / flask_max=3 [PLACEHOLDER]
[V140-LS] flask_use_via_driver PASS=true | 真实输入入口 use_flask(50,100) -> 成功、瓶数 3->2
[V140-LS] a48_flask_subscriber_runtime PASS=true | 生产订阅者实证：flask_used 已被 wave_trial_director 接收（A48①，非验证脚本订阅）
[V140-LS] death_via_driver PASS=true | 真实输入入口 on_player_death(200) -> dropped=100 / 只读快照=200 [PLACEHOLDER]
[V140-LS] a48_death_subscriber_runtime PASS=true | 生产订阅者实证：death_occurred 已被接收（只做只读记录）
[V140-LS] no_points_rollback_in_production PASS=true | ★ 不回退 grace.trial.points / 不写 removals：只读快照=200、磁盘镜像不减（A59）
[V140-LS] dead_action_rejected_in_production PASS=true | 死亡期间 guard_life_action(attack) -> dead 拒绝（死亡期间拒绝行动）
[V140-LS] respawn_resets_runtime PASS=true | 赐福重生复位运行时状态：瓶回满 3（生产订阅者 _on_respawn_performed）
[V140-LS] reclaim_via_driver PASS=true | 真实输入入口 reclaim_dropped_points() -> points=100（一次性回收）
[V140-LS] a48_reclaim_subscriber_runtime PASS=true | 生产订阅者实证：points_reclaimed 已累计到待结算 acc=100（A48①）
[V140-LS] reclaim_into_settled_200 PASS=true | 回收点数 100 并入清波结算基数：100+100 -> settled=200（D 级 1.0）[PLACEHOLDER]
[V140-LS] points_total_200 PASS=true | points_total=200（回收点数已并入既有清波点数结算）
[V140-LS] reclaim_acc_cleared_after_settle PASS=true | 并入结算后 _death_reclaim_acc 清零（不二次入账）
[V140-LS] a57_awarded_source_consistent PASS=true | A57：最终结算值 200 经 points_awarded 发出的取源与导演层一致（唯一最终值）
[V140-LS] no_double_settle_one PASS=true | 本波仅结算 1 次（不二次入账）
[V140-LS] wave_cleared_format_unchanged PASS=true | wave_cleared(index=0, points=100) 仍发基础 pts，既有输出格式/语义未改
[V140-LS] reclaim_second_rejected PASS=true | 第二次 reclaim -> already_reclaimed / points=0（回收只生效一次）
[V140-LS] reclaim_no_double_acc PASS=true | 重复回收不二次累计 acc / reclaim_count 恒 1
[V140-LS] settled_200_after_duplicate_reclaim PASS=true | 重复回收后清波仍只结算 200（不二次入账）
[V140-LS] points_monotonic_increase PASS=true | 清波后 points_total 0 -> 200（只增不减、非负）
[V140-LS] balance_nonneg PASS=true | last_settled_points / grace_trial_points 均 >= 0（余额非负、不回退）
[V140-LS] no_double_settle PASS=true | 重复 on_encounter_finished -> 拒绝（points 不变、不二次入账）
[V140-LS] flask_monotonic_decrease_in_run PASS=true | 一局内瓶数序列 [3, 2, 1, 0] 只减不增 / 非负 / 不超上限
[V140-LS] flask_grace_rest_refill PASS=true | 赐福休息补满瓶 0->3（唯一允许增加的出口）[PLACEHOLDER]
[V140-LS] respawn_refills_flask PASS=true | 死亡 / 重生时重置运行时状态：瓶回满 3（生产订阅者）
[V140-LS] legacy_snapshot_keys_all_present PASS=true | get_snapshot() 既有 27 个 key 逐字仍在（只新增只读 key，不改既有）
[V140-LS] r34_snapshot_keys_intact PASS=true | get_snapshot() R34 新增 8 个 key 逐字仍在（不回退）
[V140-LS] r35_snapshot_keys_intact PASS=true | get_snapshot() R35 新增 8 个 key 逐字仍在（不回退）
[V140-LS] r36_snapshot_keys_intact PASS=true | get_snapshot() R36 新增 11 个 key 逐字仍在（不回退）
[V140-LS] r37_snapshot_keys_present PASS=true | get_snapshot() R37 新增 14 个只读 key 可用
[V140-LS] real_production_director PASS=true | 驱动对象 = 真实生产脚本 wave_trial_director.gd（非验证脚本内自建替身/模拟编排）
[V140-LS] a54_single_instance PASS=true | A54：两次 get_flask_service() / get_death_service() 各返回同一实例（绝不自建第二个）
[V140-LS] production_subscriber_in_source PASS=true | 生产源码含 3+4 信号订阅者 + 两个唯一实例 getter + 回收并入结算 + 赐福休息补满 + 重生复位（A48①/A54/A57）
[V140-LS] MD5 wave_trial.tres before=793b6daa7c7730feed1a3f849701d58a after=793b6daa7c7730feed1a3f849701d58a
[V140-LS] MD5 boon_draft.tres before=44d8b941f8b28dfa2931984707b5c53e after=44d8b941f8b28dfa2931984707b5c53e
[V140-LS] MD5 trial_modifiers.tres before=7e9e5ac7d35d8d15171e69975ac3356d after=7e9e5ac7d35d8d15171e69975ac3356d
[V140-LS] MD5 combo_rules.tres before=a1ad4635ae0342c696fe650eb13d4930 after=a1ad4635ae0342c696fe650eb13d4930
[V140-LS] MD5 stagger_rules.tres before=49ce964e7c268804efbf2f20bec6565d after=49ce964e7c268804efbf2f20bec6565d
[V140-LS] MD5 player_actions.tres before=75390f71c002ef3cea6392a397ec267c after=75390f71c002ef3cea6392a397ec267c
[V140-LS] MD5 boss_01_margit.tres before=f2f71c7019c64e6c631c553887376c7d after=f2f71c7019c64e6c631c553887376c7d
[V140-LS] MD5 enemy_01_limgrave_soldier.tres before=9de25e0229d1c2c55a1740d2f838ad79 after=9de25e0229d1c2c55a1740d2f838ad79
[V140-LS] MD5 parry_rules.tres before=5d560e57c5c0fdfdec3f20b3f3535728 after=5d560e57c5c0fdfdec3f20b3f3535728
[V140-LS] MD5 focus_rules.tres before=289fd4f08424658d9625fd3ac3d93bfd after=289fd4f08424658d9625fd3ac3d93bfd
[V140-LS] MD5 flask_rules.tres before=13071ccf0574ddbbc45117044547976d after=13071ccf0574ddbbc45117044547976d
[V140-LS] MD5 death_rules.tres before=e5ad808f555c51b9df1e9bf8ab95c9f3 after=e5ad808f555c51b9df1e9bf8ab95c9f3
[V140-LS] existing_tables_zero_change PASS=true | 10 份既有 .tres 前后 md5 全部一致（零改动）
[V140-LS] SUMMARY pass=86 fail=0
[V140-LS] OVERALL=PASS
[V140-LS] RESULT=ALL_MATCH
[V140-LS] === SELFTEST END ===
verify_life_settlement_v140_EXIT=0   SCRIPT_ERROR=0
```

### GATE-3 `--headless --quit`（主场景实证，不加载 `presentation.gd`）

```
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
[WaveTrial] 持久化基线读回：dungeon.wave_trial.best_wave=3 / dungeon.wave_trial.completed=true / grace.trial.points=1207（经 WorldState.get_flag）
[R35][WaveTrial] 精准弹反生产订阅者已装配：ParryService 唯一实例 + 4 信号 connect（A48①/A54）
[R36][WaveTrial] 专注值/战技生产订阅者已装配：FocusService 唯一实例 + 4 信号 connect（A48①/A54）
[R37][WaveTrial] 元素瓶生产订阅者已装配：FlaskService 唯一实例 + 3 信号 connect（A48①/A54）
[R37][WaveTrial] 死亡轮回生产订阅者已装配：DeathService 唯一实例 + 4 信号 connect（A48①/A54）
[R37][HUD] 生产装配 | flask_unique=true death_unique=true grace_subscribed=true（A48①/A54，不自建第二实例）
[R37][ENC] 生产装配 | flask_unique=true death_unique=true flask_signal_subscribed=true（A48① 生产运行时订阅者，A54 不自建第二实例）
GATE3_EXIT=0   SCRIPT_ERROR=0
```

### 4.5 最终统一三段门禁（`grep SCRIPT ERROR=0`）

```
=== 最终统一三段门禁 grep SCRIPT ERROR=0 ===
  g1.log: SCRIPT_ERROR=0
  g2a_death_config.log: SCRIPT_ERROR=0      g2a_death_service.log: SCRIPT_ERROR=0
  g2a_flask_config.log: SCRIPT_ERROR=0      g2a_flask_service.log: SCRIPT_ERROR=0
  g2a_verify_death_v140.log: SCRIPT_ERROR=0
  g2a_verify_flask_v140.log: SCRIPT_ERROR=0
  g2a_verify_life_settlement_v140.log: SCRIPT_ERROR=0
  g2a_wave_trial_director.log: SCRIPT_ERROR=0
  g2b_verify_death_v140.log: SCRIPT_ERROR=0
  g2b_verify_flask_v140.log: SCRIPT_ERROR=0
  g2b_verify_life_settlement_v140.log: SCRIPT_ERROR=0
  g3.log: SCRIPT_ERROR=0
FINAL SCRIPT_ERROR_LINES=0
  G3 非 SCRIPT ERROR 的 ERROR 行：(none)
[V140-FL] SUMMARY pass=49 fail=0   OVERALL=PASS   RESULT=ALL_MATCH
[V140-DT] SUMMARY pass=50 fail=0   OVERALL=PASS   RESULT=ALL_MATCH
[V140-LS] SUMMARY pass=86 fail=0   OVERALL=PASS   RESULT=ALL_MATCH
```

**PASS/FAIL 汇总**：`49 + 50 + 86 = 185 PASS / 0 FAIL`，三份 `RESULT=ALL_MATCH`，`SCRIPT ERROR=0`。

**既有 autoload WARNING（如实登记）**：`--script` / `--headless` 工具模式尾部另有 `[SaveSystem] --script 工具模式…跳过自动读回`、`[ChunkManager] 未找到 ChunkRoot…`、`[R34C][PCO] HUD 未就绪…绑定降级`、`[R36][PCO] A66：FocusService 未就绪…绑定降级`、`[WaveTrial] 未找到 EncounterDirector…降级`、`2 ObjectDB instances were leaked at exit` —— 均为 `WARNING`、**非 `SCRIPT ERROR`、非本轮引入、不影响断言与门禁（EXIT=0）**。

---

## 5. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 机制 ① 3 个新文件 + 机制 ② 3 个新文件 + 完善功能 ③/④ `wave_trial_director.gd` 最小接线 + 3 个 verify + DONE + 回执落地；② 三段门禁 GATE-1 / 2a / 2b / 3 全 `EXIT=0`、最终统一 `SCRIPT ERROR=0`（Rank-2 三段全过程恒为 0）；③ 三份自测 `RESULT=ALL_MATCH`（185 PASS / 0 FAIL）；④ **10 份既有 `.tres` md5 前后一致（零改动）**，只新增 2 张新表；⑤ `courtyard.tscn` 零改动，GATE-3 实证 `node_count=41`（uv `2/1/1` 因零改动保持）；⑥ A48① 共 7 个新信号**生产订阅者** = `wave_trial_director._bind_flask_signals()` / `_bind_death_signals()`（生产节点）+ 运行时实证（`flask_use_count` / `life_death_count` / `life_reclaim_count` / `life_respawn_count`）+ GATE-3 装配日志 + Rank-1 HUD/ENC 复用唯一实例；⑦ A54 唯一实例：`get_flask_service()` / `get_death_service()` 两次各返回同一实例；⑧ A55/A57 结算闭合：回收点数并入唯一最终结算值、`points_awarded` 取源一致、不二次入账、acc 并入后清零、输出格式零改动；⑨ 纯逻辑边界（I-1 不读写存档 / 不碰渲染 / 不写生产 `delta.json`）——验证脚本显式 `bind_persistence(null,null)` 降级；⑩ 点数只增不减 / 余额非负 / 不重复结算 / 瓶数只减不增除休息 / 回收只生效一次 / 死亡期间拒绝行动 机器判定；⑪ **不回退 `grace.trial.points`、绝不写 `removals`**（独立 dropped / reclaimed 单向 flag + 纯逻辑不暴露存档 API）；⑫ 回执已中枢归档（§11） |
| **失败** | 无（Rank-2 自有交付无失败项）。如实另记：首次 GATE-1 预检在 Rank-1 并行写入中间态曾出现 2 条 `SCRIPT ERROR`（归属 `hud.gd:2459` / `encounter_director.gd:869`，Rank-1 文件、非本轮引入；收敛后复跑 + 最终统一门禁 `SCRIPT ERROR=0`），见 §4.1 / §4.5 |
| **需用户确认** | ① 全部 `[PLACEHOLDER]` 数值待人工试玩校准（只改表）；② Rank-1 运行时输入接线（元素瓶 G 键 / HP 回满 / 死亡触发 / 赐福重生，本轮 Rank-1 已收敛并复用唯一实例，最终手感需总指挥目视）；③ Rank-3 点数落盘与 `points_awarded` 订阅口径（A55/A57）、新增 flag 规范（`combat.flask.*` / `grace.death.*`）由 Rank-3 登记；④ headless 真跑无渲染画面，未做 15~20 秒实机录屏回看；⑤ A48③ 完整「真实输入→磁盘/画面」断言脚本 `verify_life_runtime_v140.gd` 归 Rank-1（目录所有权），待其收尾后由总指挥统一复跑取最终全绿；⑥ 重复按键幂等语义边界 / `rest_refill` 与 `drop_cap` 档位 / `invalid_input_policy` 是否扩展（§7） |

---

## 6. 未完成项 / 阻塞

- **A48③ 完整真实可达回归脚本归 Rank-1**：`godot/scripts/render/verify_life_runtime_v140.gd`（目录所有权 Rank-1）；Rank-2 不越界写。本轮提供 GATE-3 主场景实证（不加载 `presentation.gd`、真实 autoload）+ 三份 verify 驱动**真实生产脚本** `wave_trial_director.gd`（非替身 / 不模拟编排）+ 生产订阅者 / 唯一实例 / 结算闭合接口；GATE-3 日志已实证 Rank-1 HUD/ENC 复用唯一实例并生产订阅。
- **Rank-1 运行时输入接线未由 Rank-2 落地（授权边界，非缺陷）**：`encounter_director.gd` / `hud.gd` / `presentation.gd` 本轮唯一写入方 Rank-1，Rank-2 只读。元素瓶按键 / HP 归零触发 / 赐福重生 / 死亡点回收的**运行时驱动由 Rank-1 完成**；本轮 Rank-2 已提供稳定签名（§3）+ 6 个驱动口 + 生产订阅者 + 生产赐福休息链路 + 重生复位链路。接线前导演层不主动使用瓶 / 不主动死亡，清波点数与既有等价（安全降级，正是「不改既有判定分支 / 输出格式」的保证）。
- **HP 回满归属**：`respawn_performed` 生产订阅者只复位 Rank-2 手里的 FP / 瓶 / 连击 / 窗口与波次累计，并经 `has_method("trial_grace_rest")` 相对探活调用既有 `EncounterDirector` 赐福休息接口；**真实 HP 实例的回满口径归 Rank-1**（Rank-2 不持有 HP、不碰渲染、不写存档）。
- **README 状态段归 Rank-3**：公共契约「README 长期维护已做/还差什么/资产表」由 Rank-3 唯一写入，Rank-2 不越界写；已在本 DONE 完整登记，待总指挥统一同步。
- **实机录屏目视**（公共契约要求 15~20 秒回看）：本轮交付为纯逻辑 + 数据表 + 最小接线 + headless 真跑，无渲染帧缓冲，未录屏；不伪造、列为后续 / 需用户确认。
- **A70~A73 新裁决由 Rank-3 登记**（任务单目录所有权），Rank-2 不越界写；本 DONE 只在 §7 反映接口影响。
- 无阻塞；所有硬约束内工作已完成。

---

## 7. 待总指挥裁决项（只登记、不擅改）

1. **数值校准**：`flask_max=3` / `heal_amount=50.0` / `rest_refill=true` / `drop_ratio=0.5` / `drop_cap=500` / `invalid_input_policy="reject"` 全部 `[PLACEHOLDER]`，待人工试玩校准；调参唯一入口 `godot/data/rpg/flask_rules.tres` + `godot/data/rpg/death_rules.tres`，同步 `verify_flask_v140.gd` / `verify_death_v140.gd` 的 `EXPECT_*` 与本文数值表。
2. **死亡掉落语义口径**：本轮「掉落」是**叙事层记录 + 独立 dropped / reclaimed 单向 flag**，磁盘 `grace.trial.points` 绝不回退、绝不写 `removals`（A59）；回收点数经既有 `points_awarded` 一次入账，点数只增不减。请裁决是否需改为「真正扣除再捡回」口径（注：与 A59「不回退 points」直接冲突，需先裁决口径再改代码 + 表 + 回归）。
3. **重复按键幂等语义边界**：首版为「相邻两次同签名 `[current_hp,max_hp]` 调用只挡一次」；HP 被外部更新为不同值后可再次使用。请裁决是否改为「短冷却窗口」（需新增表字段 + 导演层每帧 `tick` 转发，与 R36 FocusService 同款），或维持现状。
4. **`rest_refill` / `drop_cap` 档位**：`rest_refill=true`（补满）与 `false`（`REST_KEEP` 保持）对照档、`drop_cap=500`（封顶）与 `0`（不封顶）切换，待手感校准后定档。
5. **`invalid_input_policy` 策略扩展**：首版唯一合法值 `reject`；是否允许 `clamp` / `ignore`（需同步改代码 + 表 + 回归用例，防止隐式扣瓶 / 隐式二次回收），及归属。
6. **赐福重生 HP 回满归属**：本轮生产订阅者只在 Rank-2 服务层复位 + 探活调用既有 `trial_grace_rest()`；请裁决 Rank-1 `EncounterDirector` 是否需独立 HP 回满通道 / 与既有赐福休息是否重复复位。
7. **Rank-3 落盘 flag 口径**：Rank-3 本轮将订阅元素瓶 / 死亡 / 重生 / 回收信号并登记 `combat.flask.remaining` / `grace.death.dropped` / `grace.death.reclaimed` / `grace.death.count` 等三段式 flag；请裁决信号 payload 与 flag 命名的逐项对齐，以及 `flask_rejected` / `action_rejected` 是否需要落盘（Rank-3 建议「拒绝事件不写盘、只走 HUD 反馈」）。
8. **A48③ 完整真实可达回归**：`verify_life_runtime_v140.gd` 归 Rank-1（目录所有权），Rank-2 不越界写；请裁决 Rank-1 收尾后「真实输入 → 生产链路 → 磁盘 / 画面」全链断言的复跑与口径。
9. **实机录屏回看 / 既有 autoload WARNING**：headless 真跑无帧缓冲，按公共契约如实登记为后续动作 / 需用户确认（不冒充目视通过）；既有 WARNING 非本轮引入，是否纳入后续清理由总指挥裁决。
10. **Rank-1 并行写入与最终统一复跑**：首次 GATE-1 预检观测到 Rank-1 `hud.gd` / `encounter_director.gd` 半成品中间态 Parse Error（§4.1），收敛后复跑 + 最终统一门禁已 `SCRIPT ERROR=0`；请裁决四路全部收尾后由总指挥统一复跑三段门禁取最终全绿。

---

## 8. A48 硬要求落地声明（逐条）

| A48 | 落地 | 证据 |
|---|---|---|
| ① 新信号必须有**生产运行时订阅者**（不能只在验证脚本） | `wave_trial_director.gd`（挂 `courtyard.tscn` 的生产节点）在 `_init_combat_services()` 装配时调 `_bind_flask_signals()` / `_bind_death_signals()`，connect 全部 3+4=7 信号到 `_on_flask_*` / `_on_death_*` / `_on_points_reclaimed` / `_on_life_action_rejected` 生产回调；回调有真实职责（只读计数 / 不回退 points 的记录 / 复位运行时 / 并入结算），非空订阅。Rank-1 HUD/ENC 亦已复用同一实例订阅 | `production_subscriber_in_source`（两份 verify）/ `a48_*_subscriber_runtime`（`flask_use_count` / `life_death_count` / `life_reclaim_count` / `life_respawn_count`）/ GATE-3 `[R37][WaveTrial]` + `[R37][HUD]` + `[R37][ENC]` |
| ② 遵守 A54 唯一实例（从既有导演层 `get_*_service()` 复用） | `_flask` / `_death` 唯一实例由 `wave_trial_director.gd` 装配，`get_flask_service()` / `get_death_service()` 暴露；Rank-1 / Rank-4 / Rank-3 经该 getter 复用，绝不 new 第二个 | `a54_single_instance`（两次 getter 同一实例）/ `a54_all_services_present` / GATE-3 装配日志 / §3.12 接线示意 |
| ③ 一条**不加载 `presentation.gd`、不在验证脚本内模拟编排**的真实可达回归 | GATE-3 `--headless --quit` 主场景真跑（真实 autoload `PointsCommitOrchestrator`、不加载 `presentation.gd`）实证生产链路；三份 verify 驱动的是**真实生产脚本** `wave_trial_director.gd`（`real_production_director`），结算值经真实 `_clear_wave()` 产出，不在验证脚本内自建替身 / 模拟编排 | GATE-3 R37 装配日志 + `node_count=41`；`real_production_director` / `production_subscriber_in_source`；完整「真实输入→磁盘/画面」断言脚本 `verify_life_runtime_v140.gd` 归 Rank-1（目录所有权），见 §6 / 裁决项 8（如实登记，不冒充） |
| ④ 纯逻辑 + 单元断言不算可玩交付 | 本轮交付纯逻辑 + 数据表 + 最小接线 + headless 真跑；**未做 15~20 秒实机录屏回看**，如实列为未完成 / 需用户确认，不冒充可玩交付 | §5 需用户确认 / §6 未完成项 |

---

## 9. 硬约束遵守声明

- `encounter_director.gd` / `hud.gd` / `presentation.gd` / `points_commit_orchestrator.gd` / `project.godot` / `courtyard.tscn` / 场景 / 素材 / 其它 Rank 文件**只读未改**；`courtyard.tscn` 节点数 `41` / uv `2/1/1` 未破坏（GATE-3 实证）。
- 既有 `.tres` 数值零改动（10 份 md5 前后一致），只新增 `flask_rules.tres` / `death_rules.tres` 两张新表。
- 纯逻辑（I-1）：`FlaskService` / `DeathService`（RefCounted）/ `FlaskConfig` / `DeathConfig`（Resource）均不 `add_child` / 不 `get_tree()` / 不 `/root/...` / 不 `open(user://)` / 不 `set_flag` / 不 `commit` / 不写 `removals` / 不回退 `grace.trial.points` / 不碰渲染；`wave_trial_director.gd` 接线只在 `_clear_wave()` / `_request_grace_rest()` / 生产订阅回调 / `_reset_r34_records()` 四处消费数据、不写盘；验证脚本显式 `bind_persistence(null,null)` 降级，全程不触碰 `user://slot_01/delta.json`。
- Godot4 自测纪律：`extends SceneTree` 用 `Engine.get_main_loop() as SceneTree` 取 root，`add_child` 后显式 `call("_ready")`（不依赖自动 flush），资源回读 `CACHE_MODE_IGNORE`；不用 `get_tree()`、不用 `/root/...` 绝对路径。
- 零付费、零外部依赖、不启 GPU job；不伪造产物、不谎报成功、不自行 git；未删除 `.workbuddy`。
- 默认不刺探：未扫目录做进度巡检、未写只读探针 / 巡检脚本；仅按任务单要求读必做文件、按 SCRIPT ERROR `at:` 行核验归属、核对回执目录与中枢归档结构。

---

## 10. md5 零改动结论（既有表）

`verify_life_settlement_v140.gd` 在**同一进程内**于全部接线 / 结算断言之前记录 `before`、之后记录 `after`，逐份 `FileAccess.get_md5()` 对比，12 份全部 `PASS=true`：

| # | 既有 `.tres` | md5 before | md5 after | 结论 |
|---|---|---|---|---|
| 1 | `wave_trial.tres` | `793b6daa7c7730feed1a3f849701d58a` | 同 | 零改动 |
| 2 | `boon_draft.tres` | `44d8b941f8b28dfa2931984707b5c53e` | 同 | 零改动 |
| 3 | `trial_modifiers.tres` | `7e9e5ac7d35d8d15171e69975ac3356d` | 同 | 零改动 |
| 4 | `combo_rules.tres` | `a1ad4635ae0342c696fe650eb13d4930` | 同 | 零改动 |
| 5 | `stagger_rules.tres` | `49ce964e7c268804efbf2f20bec6565d` | 同 | 零改动 |
| 6 | `player_actions.tres` | `75390f71c002ef3cea6392a397ec267c` | 同 | 零改动 |
| 7 | `boss_01_margit.tres` | `f2f71c7019c64e6c631c553887376c7d` | 同 | 零改动 |
| 8 | `enemy_01_limgrave_soldier.tres` | `9de25e0229d1c2c55a1740d2f838ad79` | 同 | 零改动 |
| 9 | `parry_rules.tres` | `5d560e57c5c0fdfdec3f20b3f3535728` | 同 | 零改动 |
| 10 | `focus_rules.tres`（R36 新增、R37 视角已存在） | `289fd4f08424658d9625fd3ac3d93bfd` | 同 | 零改动 |

**`existing_tables_zero_change PASS=true | 10 份既有 .tres 前后 md5 全部一致（零改动）`。** 前 9 份 md5 与 `DONE-R36.md` §4.4 登记值逐字一致，第 10 份与 R36 新增表登记值逐字一致 —— 交叉佐证既有表数值零改动。
本轮只新增 2 张表：`flask_rules.tres`（`13071ccf0574ddbbc45117044547976d`）/ `death_rules.tres`（`e5ad808f555c51b9df1e9bf8ab95c9f3`），验证脚本同样前后一致、未写入。**既有 `.tres` 数值零改动。**

---

## 11. 回执与中枢归档确认（写后已确认）

- 回执写入 Rank-2 授权路径（**`teamwork/command_center/`，非工程根**）：
  `teamwork/command_center/ai/2/outbox/cmd-20261112-184157-082-A2.json`，
  四字段 `{"task_id", "ai":2, "status":"done", "result"}`。
- 中枢已归档（写后回读确认，如实登记、不伪造）：
  - **归档副本**：`teamwork/command_center/dispatcher/receipts/cmd-20261112-184157-082-A2.json`，回读 **VALID_JSON**，`keys=['ai','result','status','task_id']` 四字段齐全，`task_id=cmd-20261112-184157-082-A2` / `ai=2` / `status=done` / `result_len=1856`，与 outbox 回执逐字一致。
  - `ai/2/outbox/` 按中枢流程归档后已清空（回执移入 `dispatcher/receipts/`）；不重放、不伪造。
  - `teamwork/command_center/ai/2/status.json` 更新为 `{"ai":2,"state":"idle","current_task":"","completed":45,"last_seen":"2026-11-12 19:13:58"}`（`completed` 由 44 → 45、`current_task` 清空、`state` → idle）。
  - `dispatcher/ledger.jsonl` 本任务单 `cmd-20261112-184157-082-A2` 登记：`status=done` / `finished_at=2026-11-12 19:13:58` / `result_len=1856`，与回执逐字一致；派单 `issued_at=2026-11-12 18:41:58` 与任务单一致。
  - `dispatcher/dispatcher.log` 尾部：`[2026-11-12 19:13:58] ← 2 号 AI 回执 <cmd-20261112-184157-082-A2> 完成：R37/v0.14.0 交付完成…`（回收验证 `done`）。
