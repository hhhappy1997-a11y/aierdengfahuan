# DONE-R36.md · R36 / v0.13.0「专注值与战技 · 画面补齐」交付报告（Rank-2）

> 轮次：`R36 / v0.13.0` ｜ 任务单 id：`cmd-20261112-154132-912-A2` ｜ 执行 AI：`2（Rank-2 战斗系统与数据驱动）`
> 真源：`teamwork/Rank-2/调度任务单-latest.json`（`task` 全文 + 公共契约 + 目录所有权 + A48 硬要求）
>   + `teamwork/Rank-2/DONE-R35.md` §3（既有服务接口签名）+ `teamwork/00-群聊总线.md` MSG-20261112-1535-HOST（A39~A64 裁决）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> 结论：**三段门禁最终统一 `SCRIPT ERROR=0`（GATE-1/2a/2b/3 全 `EXIT=0`）、两份自测 `RESULT=ALL_MATCH`（92 + 85 = 177 PASS / 0 FAIL）、9 份既有 `.tres` md5 零改动、`courtyard.tscn node_count=41` 保持、A48①/A54/A57 落地、回执已中枢归档**。
> 如实登记：GATE-1 / GATE-3 在 **Rank-1 并行写入 `encounter_director.gd`（R35 `window_id` 半成品中间态）** 期间曾间歇出现 1 条 `SCRIPT ERROR: Parse Error: Identifier "_r35_last_parry_wid" not declared`，`at:` 行全部指向 `res://scripts/combat/encounter_director.gd:232`（Rank-1 唯一写入方文件，非本轮 Rank-2 文件引入、Rank-2 只读无权改）；Rank-1 收敛后的**复跑 + 最终统一三段门禁 `SCRIPT ERROR=0`**（详见 §4.4 / §4.5）。

---

## 1. 交付清单（实际落地文件）

### 机制 ① · 专注值 FP 与战技（新增 3 件，均归 Rank-2）

| 文件 | 类型 | 作用 |
|---|---|---|
| `godot/data/combat/focus_rules.tres` | 新增数据表 | `fp_max / fp_regen_on_rest / arts(2×6) / rest_refill / invalid_input_policy` 全部 `[PLACEHOLDER]` 字段，数值真源 / 调参唯一入口 |
| `godot/scripts/combat/focus_config.gd` | 新增 Resource（`class_name FocusConfig`，`extends Resource`） | 表结构 / 5 字段契约 / `is_valid()` 纯函数 / 战技行白名单校验 / 逐项 rationale / 降级基线 / 调参唯一入口 |
| `godot/scripts/combat/focus_service.gd` | 新增 RefCounted（`class_name FocusService`）纯逻辑 | FP 扣减 / 冷却 / 赐福休息 / 幂等 / 异常拒绝 + **4 个公开信号** |

### 完善功能 ②/③ · 结算与生产接线（修改 1 件，本轮唯一写入方 = Rank-2）

| 文件 | 改动 | 边界 |
|---|---|---|
| `godot/scripts/combat/wave_trial_director.gd` | 11 处精确插入：`FOCUS_RULES_PATH` 常量 / 11 个记录字段 / `_process` 每帧 `tick(delta)` 转发 / `_enter_telegraph()` 每波清本波累计（**不回满 FP**）/ `_clear_wave()` 把 `_focus_points_acc` 并入 `base_for_combo` / `_request_grace_rest()` 接赐福休息回满 / `_init_combat_services()` 装配唯一实例并 `_bind_focus_signals()`（A48① 生产订阅者）/ `_reset_r34_records()` 清记录并新局 `reset()` / 新增 `get_focus_service()` + 4 个生产回调 + `_clear_focus_wave_records()` + 2 个真实输入驱动口 + `get_settlement_snapshot()` 追加 5 key / `get_snapshot()` 追加 11 key | **既有判定分支 / 帧数据 / 输出格式（`wave_cleared(index,pts)` 签名与值、`_refresh_hud()` 文本、既有 27 + R34 8 + R35 8 个 key）/ 既有 `.tres` 数值一律逐字未动**；战技 `damage` 只并入 `base_for_combo` 一次 → 经既有 `combo.settle()` 得唯一最终结算值 → HUD 经 `get_last_settlement()` 取该值发 `points_awarded` 一次入账（A57，**不二次入账**）；`poise_damage` 经生产订阅者并入既有 `StaggerService.apply_hit()` |

### 自测脚本（新增 2 件，均在 `godot/scripts/combat/`）

| 文件 | 作用 | 结果 |
|---|---|---|
| `verify_focus_v130.gd` | 机制 ① 正常 / 边界 / 异常三类：读表 5 字段 + arts(2×6)、4 信号、spend 成功与 payload、FP 扣减、两战技各自效果、FP 不足拒绝且不扣、冷却期拒绝、重复按键幂等、冷却推进就绪、赐福休息回满、`rest_refill=false` 增量回复（含封顶）、FP 只减不增 / 非负 / 不超上限、reset、异常 id（null/负数/浮点/数组/空串/未知 id）、tick 异常 delta、config=null、set_config(null)、6 类非法表、异常后正常流程、A48① 静态证据 | `pass=92 fail=0 RESULT=ALL_MATCH` |
| `verify_focus_settlement_v130.gd` | 战技 damage 并入结算（118 / 163 两组合）+ A57 取源一致 + 不二次入账 + 点数单调 / 余额非负 + **FP 只减不增除休息（含跨波不回满）** + 每波累计清零 + 既有输出格式零改动 + A48① 运行时实证 + A54 唯一实例 + 真实生产脚本驱动 + md5 前后对比证明既有表零改动 | `pass=85 fail=0 RESULT=ALL_MATCH` |

### 文档 / 回执（新增 2 件）

| 文件 | 作用 |
|---|---|
| `teamwork/Rank-2/DONE-R36.md` | 本交付报告（交付清单 / 真跑输出原文 / 验收三态 / 公开方法与信号完整签名 / md5 零改动结论 / 未完成项 / 待裁决项） |
| `teamwork/command_center/ai/2/outbox/cmd-20261112-154132-912-A2.json` | 本轮回执，中枢归档见 §11 |

### 只读未改（硬约束）

`godot/scripts/combat/encounter_director.gd`、`godot/scripts/hud.gd`、`godot/test/presentation.gd`（三者本轮唯一写入方 Rank-1，Rank-2 只读）、
`godot/scripts/rpg/points_commit_orchestrator.gd`、`godot/project.godot`（Rank-3 所有 / A56 autoload）、
`godot/scenes/courtyard.tscn`、场景 / 素材 / 其它 Rank 文件、既有 `.tres`
（`wave_trial.tres` / `boon_draft.tres` / `trial_modifiers.tres` / `stagger_rules.tres` / `combo_rules.tres` / `player_actions.tres` / `boss_01_margit.tres` / `enemy_01_limgrave_soldier.tres` / `parry_rules.tres`）。

---

## 2. 玩法拆解表（需求 → 机制 → 数值 → 状态 → 验收）

### 机制 ① · 专注值 FP 与战技状态机

| 需求 | 机制 | 数值（`[PLACEHOLDER]` 首版） | 状态（实例内、不持久化） | 验收 |
|---|---|---|---|---|
| 专注值上限 / 初始满 | 构造 / `reset()` 置 `fp = fp_max` | `fp_max=100.0` | `_fp` | `initial_fp_full` / `focus_initial_fp_full` |
| 施放战技扣 FP | `spend_fp(art_id)`：config/art_id/冷却/FP 四道门；成功扣 `fp_cost`、置该 art 冷却、发 `focus_spent` | 魔砾 `fp_cost=12.0` / 狮子斩 `fp_cost=35.0` | `_fp` / `_cooldowns` / `_spend_count` | `spend_pebble_ok` / `spend_lion_ok` / `spend_both_fp` / `focus_spent` payload |
| FP 不足拒绝且不扣 | `_fp < fp_cost` → `REASON_INSUFFICIENT_FP`，不扣 FP、不给效果、不增计数 | — | `_fp` 不变 | `fp_insufficient_reject` / `fp_insufficient_no_deduct` |
| 冷却期拒绝 | 同战技冷却未归零 → `REASON_COOLDOWN`；`tick(delta)` 确定性推进 | 魔砾 `0.6` / 狮子斩 `1.8` | `_cooldowns[art_id]` | `cooldown_reject` / `cooldown_then_ready` |
| 重复按键幂等 | 成功后冷却期内重复 `spend_fp` 同 id → 拒绝、不二次扣 FP / 不二次给效果 | — | `_spend_count` 恒 1 | `duplicate_key_idempotent` |
| 赐福休息回满 | `on_grace_rest()`：`rest_refill=true` 回满 `fp_max`、清全部冷却、发 `focus_restored`；`false` 按 `fp_regen_on_rest` 增量（封顶） | `rest_refill=true` / `fp_regen_on_rest=40.0` | `_fp` / `_restore_count` | `grace_rest_refill` / `rest_regen_increment` / `rest_regen_capped` / `grace_rest_is_only_increase` |
| FP 只减不增除休息 | 一局内连续施放 FP 单调不增、非负、不超上限；跨波不回满（只清本波累计） | — | `_fp` | `fp_only_decreases` / `fp_monotonic_decrease_in_run` / `fp_not_refilled_next_wave` |
| 异常输入拒绝 | `spend_fp(null/负数/浮点/数组/空串/未知 id)` → `REASON_INVALID_ART`；`tick(null/负/字符串/NaN/Inf)` → `REASON_INVALID_DELTA`；config=null/非法表 → `REASON_NO_CONFIG`；拒绝不改状态 | `invalid_input_policy="reject"` | 状态不变 | `invalid_art_*` / `invalid_tick_*` / `no_config_spend_reject` / `invalid_table_*` / `invalid_then_normal_ok` |
| 每场 / 每波重置 | `reset()` 回满 FP、清冷却/计数/最近结果（**每场新一局**）；每波 `_clear_focus_wave_records()` 只清本波累计 | — | 全状态 | `reset_clears_all` / `focus_acc_cleared_next_wave` |

### 完善功能 ②/③ · 结算接线（沿用 A57：最终结算值经 `points_awarded` 发出，不二次入账）

| 需求 | 落地位置 | 效果 | 验收 |
|---|---|---|---|
| 战技 `damage` 并入清波点数结算 | `_clear_wave()`：`base_for_combo = maxi(0, base_for_combo + _focus_points_acc)`（在 R35 弹反并入之后、既有 `combo.settle(base_for_combo)` 之前插入一行） | 唯一最终结算值 `settled_points` 含战技伤害；HUD 经 `combo.get_last_settlement()` 取同值发 `points_awarded` 一次 | `focus_damage_into_settled_118` / `both_arts_into_settled_163` / `a57_awarded_source_consistent` / `no_double_settle_one` |
| 战技 `poise_damage` 并入既有削韧 | 生产订阅者 `_on_focus_spent()`：经 `_encounter.get_stagger_service()` 取同一 StaggerService → 既有 `apply_hit(poise_damage)`；`--script` / 依赖缺失时只记录、不崩 | 战技削韧真实并入既有韧性结算，不改既有判定分支 | `focus_success_recorded` / `both_arts_damage_acc` |
| 点数只增不减 / 余额非负 / 不重复结算 / 每波累计清零 | `settled_points` 恒 `>=0`、既有 `_persist_settle` max 保护、既有 `WAVE_ACTIVE` 门控拒绝重复 `on_encounter_finished`、`_clear_focus_wave_records()` 每波清 acc | 不二次入账、不把第 1 波战技伤害带进第 2 波 | `points_monotonic_increase` / `balance_nonneg` / `no_double_settle` / `focus_acc_cleared_next_wave` / `no_repeat_focus_damage_wave2` |
| 既有输出格式零改动 | `wave_cleared.emit(_index, pts)` 第二参仍为基础 `pts`；`get_snapshot()` 既有 27 + R34 8 + R35 8 个 key 逐字不动，只追加 11 个只读 key | 回归不回退 | `wave_cleared_format_unchanged` / `legacy_snapshot_keys_all_present` / `r34_snapshot_keys_intact` / `r35_snapshot_keys_intact` |

### 数值拆解 / rationale（完整版见 `focus_config.gd` 头注）

- **调参唯一入口（只改表不改代码）**：`godot/data/combat/focus_rules.tres`。代码内 `FocusConfig.DEFAULT_*` 是**非法降级基线**（刻意 `!=` 表值，`verify_focus_v130.gd` 的 `default_is_not_design_*` 机器判定），不是设计数值。校准同步清单：`.tres` → `verify_focus_v130.gd` 的 `EXPECT_*` → 本文数值表 → 三段门禁；不静默改数。
- `fp_max = 100.0` `[PLACEHOLDER]`：与既有 `stagger_rules.tres` 的 `stagger_max=100.0` 同量级，便于「专注值条」与「韧性条」统一量纲；取整百便于实机录屏肉眼观察消耗/回复。
- `fp_regen_on_rest = 40.0` `[PLACEHOLDER]`：`rest_refill=false` 时的增量回复量（fp_max 的 40%）；默认 `rest_refill=true` 不启用，保留供裁决切换回满/增量策略，不改代码。
- `rest_refill = true` `[PLACEHOLDER]`：赐福休息是唯一 FP 回复出口（守住「FP 只减不增除休息」）；置 false 可切换增量对照档。
- `invalid_input_policy = "reject"` `[PLACEHOLDER]`：异常输入一律拒绝且不改状态，避免 clamp / ignore 造成隐式扣 FP / 污染冷却；首版唯一合法值，任何策略扩展须先补回归用例再改代码 + 表 + 验证。
- **辉石魔砾** `glintstone_pebble`（低耗远程）：`fp_cost=12.0`（约 fp_max 的 1/8，一局约 8 次）/ `cooldown_sec=0.6`（短冷却防连发刷结算）/ `damage=18.0`（明显小于 R35 弹反 `points_bonus=50`，不改点数通胀口径 A51/A60）/ `poise_damage=8.0`（小于既有 `reference_poise_damage=25.0`，远程低削韧）。
- **狮子斩** `lion_slash`（高耗高削韧）：`fp_cost=35.0`（约 1/3，一局 2~3 次）/ `cooldown_sec=1.8` / `damage=45.0`（与 R35 弹反 50 同量级）/ `poise_damage=40.0`（`stagger_max=100` 的 40%、标准命中的 1.6 倍，体现高削韧；仍经既有 `apply_hit`，不改判定分支）。

### 结算值两组实证（均 `RESULT=ALL_MATCH`）

| 组合 | base 推导 | 倍率 | 最终结算值 | 断言 |
|---|---|---|---|---|
| 辉石魔砾（无抉择 / 0 连击） | `100 + 18 = 118` | D 1.0 | **118** | `focus_damage_into_settled_118` / `a57_awarded_source_consistent` |
| 辉石魔砾 + 狮子斩 | `100 + 18 + 45 = 163` | D 1.0 | **163** | `both_arts_into_settled_163` / `both_arts_awarded_source` |

---

## 3. 供 Rank-1 与 Rank-4 使用的公开方法与信号完整签名（本轮重点）

> `FocusService` 是 `RefCounted` 纯逻辑，**信号是 Object 级能力**：Rank-1 / Rank-4 直接 `connect` 到本服务实例即可，
> 无需场景树、无需 `add_child`、无需 `/root/...`。以下签名**稳定、不再改动**。
> **A54 唯一实例**：由 `wave_trial_director.gd` 装配，Rank-1 / Rank-4 经 `get_focus_service()` 复用，绝不另建第二个。

### 3.1 公开信号（`godot/scripts/combat/focus_service.gd`）

```
signal focus_spent(art_id: String, fp_cost: float, damage: float, poise_damage: float, fp_remaining: float)
    # spend_fp(art_id) 成功时发；payload = 战技 id / 消耗 / 并入结算的两项效果 / 施放后余额。
    # 供 Rank-1 结算接线 / Rank-4 战技演出（辉石魔砾 / 狮子斩）。
    # ★ A48①：生产订阅者 = wave_trial_director._bind_focus_signals()（生产节点，非验证脚本）。
signal focus_rejected(art_id: String, reason: String)
    # 施放被拒时发；reason ∈ {no_config, invalid_art, insufficient_fp, cooldown}。
    # 供 Rank-4「FP 不足 / 冷却中」失败反馈 / HUD 提示。
signal focus_restored(fp_before: float, fp_after: float, policy: String)
    # on_grace_rest() 回复 FP 时发；policy ∈ {REST_REFILL="rest_refill", REST_REGEN="rest_regen"}。
    # 供 Rank-4 赐福休息演出 / HUD 专注值条回满。
signal focus_cooldown_ready(art_id: String)
    # tick() 把某战技冷却从 >0 推到 0 时发（每次冷却结束恰 1 次）。
    # 供 Rank-4 收起「冷却中」角标 / 战技图标点亮。
```

### 3.2 公开方法（全静态类型）

```
class_name FocusService (extends RefCounted)
_init(config: FocusConfig = null)                 # 构造注入规则表，自动 reset()（FP 回满）
set_config(config: FocusConfig) -> void           # 替换表并 reset()（含 null 降级验证）
get_config() -> FocusConfig
reset() -> void                                  # 回满 FP、清冷却 / 计数 / 最近结果（每场新一局调用）
                                                 # ★ 每波开始不调 reset()：导演层只清本波累计，FP 跨波保留
spend_fp(art_id: Variant) -> Dictionary           # 施放战技；FP 不足 / 冷却 / 异常 id / 无 config 一律拒绝
tick(delta_sec: Variant) -> Dictionary            # 每帧推进冷却；冷却归零发 focus_cooldown_ready；异常拒绝
on_grace_rest() -> Dictionary                     # 赐福休息：回满或增量回复 FP、清冷却、发 focus_restored
                                                 # ★ 本服务唯一允许 FP 增加的出口

get_fp() -> float
get_fp_remaining() -> float                      # 同义，供 HUD 鸭子类型
get_fp_max() -> float
get_cooldown_remaining(art_id: String) -> float
get_spend_count() -> int
get_reject_count() -> int
get_restore_count() -> int
get_last_result() -> Dictionary                  # 最近一次成功结果（Dictionary 副本）
get_last_reject_reason() -> String
get_art_ids() -> PackedStringArray
get_invalid_input_policy() -> String
is_config_valid() -> bool
get_snapshot() -> Dictionary                     # 全状态快照（见 §3.3）
```

**接线注意**：① `tick(delta)` 必须每帧调用（本轮已由 `wave_trial_director._process()` 转发，纯逻辑不读真实时钟）；② 每场新一局开始调一次 `reset()`（本轮 `start_trial()` 已接）；③ 每波开始**只清本波累计**（`_clear_focus_wave_records()`），不回满 FP，专注值跨波保留；④ 赐福休息由 `_request_grace_rest()` 生产链路调 `on_grace_rest()`，或由 Rank-1 经 `focus_grace_rest()` 驱动口调用；⑤ `spend_fp()` 成功后同战技进入冷却，重复按键幂等拒绝；⑥ 结算点数落盘由 Rank-3（I-1 / A55 `points_awarded` 唯一权威通道）接线，Rank-2 只产出最终结算值。

### 3.3 返回 Dictionary 字段（供 Rank-1 / Rank-4 消费）

```
spend_fp        : {ok, reason, art_id, title, fp_cost, damage, poise_damage,
                   fp_remaining, cooldown_remaining, spend_count, config_present}
tick            : {ok, reason, delta_sec, ready_arts, fp, cooldowns}
on_grace_rest   : {ok, reason, fp_before, fp_after, fp_max, policy,
                   restore_count, config_present}
get_snapshot    : {fp, fp_max, fp_remaining, rest_refill, fp_regen_on_rest,
                   invalid_input_policy, art_count, art_ids, cooldowns,
                   spend_count, reject_count, restore_count, config_present,
                   last_result, last_reject_reason}
```

成功恒 `damage>=0` / `poise_damage>=0` / `fp_cost>0` / `fp_remaining>=0`；拒绝时 `damage=poise_damage=fp_cost=0`、不改状态。

### 3.4 公开常量（reason / policy 取值，签名稳定）

```
方法 reason:
    REASON_OK                = "ok"
    REASON_NO_CONFIG         = "no_config"        # config 缺失 / 非法表
    REASON_INVALID_ART       = "invalid_art"      # 异常 id / 负数 / null / 空串 / 未知 id
    REASON_INSUFFICIENT_FP   = "insufficient_fp"  # FP 不足（拒绝且不扣）
    REASON_COOLDOWN          = "cooldown"         # 冷却期 / 重复按键幂等
    REASON_INVALID_DELTA     = "invalid_delta"    # tick(null/负/非数值/NaN/Inf)

focus_restored.policy:
    REST_REFILL              = "rest_refill"      # 表 rest_refill=true：回满 fp_max
    REST_REGEN               = "rest_regen"       # 表 rest_refill=false：按 fp_regen_on_rest 增量（封顶）

ART_ID_NONE                  = "<none>"           # 非 String art_id 在 focus_rejected payload 的统一占位
```

### 3.5 `FocusConfig` 公开接口（`extends Resource` / `class_name FocusConfig`）

```
@export var fp_max: float                       # 专注值上限（表值 [PLACEHOLDER]）
@export var fp_regen_on_rest: float             # 赐福休息增量回复量（表值 [PLACEHOLDER]）
@export var arts: Array[Dictionary]             # 2 个战技，每行 6 字段：
                                                #   id / title / fp_cost / cooldown_sec / damage / poise_damage
@export var rest_refill: bool                   # true=回满 / false=增量（表值 [PLACEHOLDER]）
@export var invalid_input_policy: String       # 异常输入策略，唯一合法值 POLICY_REJECT="reject"

const POLICY_REJECT: String = "reject"
const ART_FIELDS: PackedStringArray = ["id","title","fp_cost","cooldown_sec","damage","poise_damage"]
# 降级基线（不是设计数值）：DEFAULT_FP_MAX / DEFAULT_FP_REGEN_ON_REST /
#   DEFAULT_REST_REFILL / DEFAULT_INVALID_INPUT_POLICY

is_valid() -> bool                              # 5 字段类型合法 / fp_max>0 / 回复与各战技数值>=0 /
                                                # fp_cost>0 / policy==reject / arts 非空且 id 唯一且无 NaN/Inf
get_fp_max() -> float / get_fp_regen_on_rest() -> float / get_rest_refill() -> bool /
get_invalid_input_policy() -> String / get_art_count() -> int /
get_art_ids() -> PackedStringArray / get_art(index: int) -> Dictionary /
get_art_by_id(id: String) -> Dictionary        # 越界 / 找不到返回空 Dictionary（不崩）
```

### 3.6 Rank-1 接线示意（伪代码，供 `encounter_director.gd` / `hud.gd` / 输入层）

```gdscript
# A54 唯一实例：从波次导演复用，绝不 new 第二个 FocusService
var focus: FocusService = wave_trial_director.get_focus_service()
focus.connect("focus_spent",          Callable(self, "_on_focus_spent"))
focus.connect("focus_rejected",       Callable(self, "_on_focus_rejected"))
focus.connect("focus_restored",       Callable(self, "_on_focus_restored"))
focus.connect("focus_cooldown_ready", Callable(self, "_on_focus_cooldown_ready"))

func _on_art_key_pressed(art_id: String) -> void:
    var r: Dictionary = focus.spend_fp(art_id)   # 或 wave_trial_director.spend_focus(art_id)
    if r.ok:  # r.damage / r.poise_damage 已由生产订阅者并入结算
        pass
func _process(delta: float) -> void:
    # 导演层 _process 已转发 focus.tick(delta)；若 Rank-1 另持实例，务必复用同一实例、只转发一次
    pass
func _on_grace_rest() -> void:
    focus.on_grace_rest()                        # 或 wave_trial_director.focus_grace_rest()
# HUD 专注值条：focus.get_snapshot() 的 fp / fp_max / fp_remaining / cooldowns 直接可读
# 结算：focus_spent 的 damage 已由 wave_trial_director 生产订阅者并入
#       base_for_combo → combo.settle() 唯一最终值 → HUD points_awarded 一次入账（A57）
```

### 3.7 Rank-4 视觉反馈接线示意（订阅同一实例，不经场景树）

```gdscript
func _on_focus_spent(art_id: String, fp_cost: float, damage: float,
        poise_damage: float, fp_remaining: float) -> void:
    # 辉石魔砾 / 狮子斩 演出；damage / poise_damage 供飘字；fp_remaining 供专注值条递减
func _on_focus_rejected(art_id: String, reason: String) -> void:
    # reason ∈ no_config / invalid_art / insufficient_fp / cooldown：
    # 「FP 不足」「冷却中」失败反馈 / 图标置灰
func _on_focus_restored(fp_before: float, fp_after: float, policy: String) -> void:
    # 赐福休息回满演出；fp_before/fp_after 供专注值条补间
func _on_focus_cooldown_ready(art_id: String) -> void:
    # 收起冷却角标 / 战技图标点亮
```

### 3.8 `wave_trial_director.gd` 本轮新增公开接口（供 Rank-1 / 验证 / HUD）

```
get_focus_service() -> FocusService            # ★ A54 唯一实例（Rank-1 / Rank-4 复用）
spend_focus(art_id: Variant) -> Dictionary     # 真实输入驱动口（转调唯一实例）
focus_grace_rest() -> Dictionary                # 赐福休息回满驱动口（转调唯一实例）

get_settlement_snapshot() 追加 5 个只读 key（既有 key 逐字不动）：
    focus_points_bonus / focus_poise_bonus / focus_poise_applied /
    focus_spend_count / focus_last_art_id
get_snapshot() 追加 11 个只读 key（既有 27 + R34 8 + R35 8 个 key 逐字不动）：
    focus_fp / focus_fp_max / focus_points_acc / focus_poise_acc / focus_poise_applied /
    focus_spend_count / focus_reject_count / focus_restore_count /
    focus_cooldown_ready_count / focus_last_art_id / focus_last_reject_reason
```

---

## 4. 真跑输出原文（三段门禁，最终统一 `SCRIPT ERROR=0`）

命令前缀统一为 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；
引擎版本行：`Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org`。

### GATE-1 `--headless --import`（本轮首次，注册 2 个新全局类）

```
[   0% ] update_scripts_classes | Started 正在注册全局类…… (2 steps)
[   0% ] update_scripts_classes | FocusConfig
[  33% ] update_scripts_classes | FocusService
[ DONE ] update_scripts_classes
IMPORT_EXIT=0   SCRIPT_ERROR=0（该次首跑）
```

### GATE-2a `--check-only --script`（语法门禁，5 件）

```
CHECK_ONLY focus_config                    EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY focus_service                   EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY wave_trial_director             EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY verify_focus_v130               EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY verify_focus_settlement_v130    EXIT=0  SCRIPT_ERROR=0
```

### GATE-2b `--headless --script <verify>`（实跑）

`verify_focus_v130.gd`（共 92 条逐条 `PASS=true` 原文，正常 / 边界 / 异常三类，此处列代表行与汇总）：

```
[V130-FP] === SELFTEST START ===
[V130-FP] scene_tree_root_via_main_loop PASS=true | Engine.get_main_loop() as SceneTree -> root，不用 get_tree()/绝对路径
[V130-FP] table_load_cache_ignore PASS=true | path=res://data/combat/focus_rules.tres
[V130-FP] ruleset_valid PASS=true | FocusConfig.is_valid()=true
[V130-FP] fp_max_ph PASS=true | got=100.0 expect=100.0 [PLACEHOLDER]
[V130-FP] fp_regen_on_rest_ph PASS=true | got=40.0 expect=40.0 [PLACEHOLDER]
[V130-FP] rest_refill_ph PASS=true | got=true expect=true [PLACEHOLDER]
[V130-FP] invalid_input_policy_ph PASS=true | got=reject expect=reject [PLACEHOLDER]
[V130-FP] art_count_2 PASS=true | arts 恰 2 个战技 [PLACEHOLDER]
[V130-FP] art_ids_unique PASS=true | art id 唯一：["glintstone_pebble", "lion_slash"]
[V130-FP] pebble_fp_cost_ph PASS=true | fp_cost=12.0 [PLACEHOLDER] 低耗
[V130-FP] pebble_poise_ph PASS=true | poise_damage=8.0 [PLACEHOLDER] 并入既有削韧
[V130-FP] lion_fp_cost_ph PASS=true | fp_cost=35.0 [PLACEHOLDER] 高耗
[V130-FP] lion_poise_ph PASS=true | poise_damage=40.0 [PLACEHOLDER] 高削韧
[V130-FP] signal_spent_exists PASS=true | signal focus_spent(art_id, fp_cost, damage, poise_damage, fp_remaining)
[V130-FP] signal_rejected_exists PASS=true | signal focus_rejected(art_id, reason)
[V130-FP] signal_restored_exists PASS=true | signal focus_restored(fp_before, fp_after, policy)
[V130-FP] signal_ready_exists PASS=true | signal focus_cooldown_ready(art_id)
[V130-FP] default_is_not_design_fp_max PASS=true | DEFAULT_FP_MAX != 表值（调参唯一入口在 .tres）
[V130-FP] spend_pebble_ok PASS=true | spend_fp(辉石魔砾) -> ok
[V130-FP] spend_fp_remaining PASS=true | fp_remaining=100-12=88
[V130-FP] signal_spent_1 PASS=true | focus_spent 恰 1 次，payload=(id,12.0,18.0,8.0,88.0)
[V130-FP] spend_lion_ok PASS=true | spend_fp(狮子斩) -> ok，payload=(35.0,45.0,40.0) [PLACEHOLDER]
[V130-FP] spend_both_fp PASS=true | 两战技合计扣 12+35=47 -> FP=53
[V130-FP] cooldown_reject PASS=true | 成功后再次施放同战技 -> cooldown 拒绝（冷却期拒绝）
[V130-FP] duplicate_key_idempotent PASS=true | 重复按键幂等：不二次扣 FP / 不二次给效果 / spend_count 仍 1
[V130-FP] cooldown_then_ready PASS=true | tick(0.6) 冷却归零 -> focus_cooldown_ready 恰 1 次
[V130-FP] fp_exhaust_8_spends PASS=true | 100/12 -> 连续 8 次成功、FP 余 4
[V130-FP] fp_insufficient_reject PASS=true | 第 9 次 FP=4 < fp_cost=12 -> insufficient_fp 拒绝
[V130-FP] fp_insufficient_no_deduct PASS=true | FP 不足拒绝且不扣 FP / 不给效果 / 不增 spend_count
[V130-FP] grace_rest_refill PASS=true | on_grace_rest() -> 赐福休息回满 fp_max=100
[V130-FP] signal_restored_1 PASS=true | focus_restored(53.0, 100.0, rest_refill) 恰 1 次
[V130-FP] rest_regen_increment PASS=true | rest_refill=false -> 53+40=93 增量回复（未封顶）[PLACEHOLDER]
[V130-FP] rest_regen_capped PASS=true | 增量回复封顶 fp_max=100（不超上限）
[V130-FP] fp_only_decreases PASS=true | FP 序列 [100.0, 88.0, 53.0, 41.0, 6.0, 6.0] 单调不增 / 非负 / 不超上限
[V130-FP] reset_clears_all PASS=true | reset() -> FP 回满 / 清冷却 / 清三类计数 / 清最近结果
[V130-FP] invalid_art_null PASS=true | spend_fp(null) -> invalid_art 拒绝
[V130-FP] invalid_art_negative PASS=true | spend_fp(负数 -1) -> invalid_art 拒绝
[V130-FP] invalid_art_array PASS=true | spend_fp(数组) -> invalid_art 拒绝
[V130-FP] invalid_tick_nan PASS=true | tick(NaN) -> invalid_delta 拒绝
[V130-FP] invalid_tick_inf PASS=true | tick(Inf) -> invalid_delta 拒绝
[V130-FP] no_config_spend_reject PASS=true | config=null -> spend_fp 拒绝 REASON_NO_CONFIG（不崩）
[V130-FP] invalid_table_bad_policy PASS=true | invalid_input_policy=clamp（非 reject）-> is_valid()=false
[V130-FP] invalid_table_duplicate_id PASS=true | art id 重复 -> is_valid()=false
[V130-FP] invalid_then_normal_ok PASS=true | 异常输入拒绝后正常施放仍得 damage=18.0（状态未被污染）
[V130-FP] production_subscriber_in_source PASS=true | wave_trial_director.gd 生产源码含 4 信号 connect + get_focus_service() + 战技并入结算（A48①/A54/A57）
[V130-FP] SUMMARY pass=92 fail=0
[V130-FP] OVERALL=PASS
[V130-FP] RESULT=ALL_MATCH
[V130-FP] === SELFTEST END ===
verify_focus_v130_EXIT=0
```

`verify_focus_settlement_v130.gd`（共 85 条逐条 `PASS=true` 原文，此处列全量关键行与汇总）：

```
[V130-FS] === SELFTEST START ===
[V130-FS] scene_tree_root_via_main_loop PASS=true | Engine.get_main_loop() as SceneTree -> root
[V130-FS] md5_before_wave_trial.tres_nonempty PASS=true | wave_trial.tres md5(before)=793b6daa7c7730feed1a3f849701d58a
[V130-FS] md5_before_parry_rules.tres_nonempty PASS=true | parry_rules.tres md5(before)=5d560e57c5c0fdfdec3f20b3f3535728
[V130-FS] md5_before_focus_rules.tres_nonempty PASS=true | focus_rules.tres md5(before)=289fd4f08424658d9625fd3ac3d93bfd
[V130-FS] persist_explicitly_downgraded PASS=true | bind_persistence(null,null) -> persist_available=false（不写生产存档）
[V130-FS] baseline_settled_100 PASS=true | 无战技 / 0 连击 -> settled=100（D 级 mult=1.0，与既有等价）
[V130-FS] a54_focus_service_present PASS=true | 4 个纯逻辑服务均已装配（A54：唯一实例经 get_*_service() 复用）
[V130-FS] focus_initial_fp_full PASS=true | focus_fp=100.0 / focus_fp_max=100.0 [PLACEHOLDER]
[R36][WaveTrial] 专注值/战技生产订阅者已装配：FocusService 唯一实例 + 4 信号 connect（A48①/A54）
[V130-FS] a48_production_subscriber_runtime PASS=true | 生产订阅者实证：focus_spent 已被 wave_trial_director 接收（A48①，非验证脚本订阅）
[V130-FS] spend_focus_ok PASS=true | 真实输入入口 spend_focus(辉石魔砾) -> 成功
[V130-FS] focus_success_recorded PASS=true | 生产订阅者已把 damage/poise_damage 记入导演层
[V130-FS] focus_damage_into_settled_118 PASS=true | 战技 damage=18 并入清波结算基数：100+18 -> settled=118（D 级 1.0）[PLACEHOLDER]
[V130-FS] a57_awarded_source_consistent PASS=true | A57：最终结算值 118 经 points_awarded 发出的取源与导演层一致（唯一最终值）
[V130-FS] no_double_settle_one PASS=true | 本波仅结算 1 次（不二次入账）
[V130-FS] wave_cleared_format_unchanged PASS=true | wave_cleared(index=0, points=100) 仍发基础 pts，既有输出格式/语义未改
[V130-FS] both_arts_damage_acc PASS=true | damage 累加 18+45=63 / poise_damage 累加 8+40=48 [PLACEHOLDER]
[V130-FS] both_arts_into_settled_163 PASS=true | 两战技 damage 并入清波结算基数：100+18+45 -> settled=163（既有单一倍率，不叠乘）
[V130-FS] both_arts_awarded_source PASS=true | A57 取源 = 163（含两战技伤害的最终值，一次入账）
[V130-FS] points_monotonic_increase PASS=true | 清波后 points_total 0 -> 118（只增不减、非负）
[V130-FS] no_double_settle PASS=true | 重复 on_encounter_finished -> 拒绝（points 不变、settlement_count=1、不二次入账）
[V130-FS] fp_monotonic_decrease_in_run PASS=true | 一局内 FP 100.0 -> 88.0 -> 53.0 只减不增 / 非负 / 不超上限
[V130-FS] grace_rest_is_only_increase PASS=true | 赐福休息回满 53.0 -> 100.0（唯一允许 FP 增加的出口）
[V130-FS] fp_not_refilled_next_wave PASS=true | 第 2 波开始不回满 FP（专注值跨波资源，只有赐福休息 / 新局 reset 回满）
[V130-FS] focus_acc_cleared_next_wave PASS=true | 第 2 波波次开始清 focus_points_acc（不把第 1 波战技伤害带进第 2 波）
[V130-FS] no_repeat_focus_damage_wave2 PASS=true | 第 2 波无战技 -> settled=150（第 2 波基础 pts，不含第 1 波 +18，不重复并入）
[V130-FS] legacy_snapshot_keys_all_present PASS=true | get_snapshot() 既有 27 个 key 逐字仍在
[V130-FS] r34_snapshot_keys_intact PASS=true | get_snapshot() R34 新增 8 个 key 逐字仍在（不回退）
[V130-FS] r35_snapshot_keys_intact PASS=true | get_snapshot() R35 新增 8 个 key 逐字仍在（不回退）
[V130-FS] r36_snapshot_keys_present PASS=true | get_snapshot() R36 新增 11 个只读 key 可用
[V130-FS] real_production_director PASS=true | 驱动对象 = 真实生产脚本 wave_trial_director.gd（非验证脚本内自建替身/模拟编排）
[V130-FS] a54_single_instance PASS=true | A54：两次 get_focus_service() 返回同一实例（绝不自建第二个）
[V130-FS] production_subscriber_in_source PASS=true | 生产源码含 4 信号订阅者 + 唯一实例 getter + 战技并入结算 + 赐福休息回满（A48①/A57）
[V130-FS] MD5 wave_trial.tres before=793b6daa7c7730feed1a3f849701d58a after=793b6daa7c7730feed1a3f849701d58a
[V130-FS] MD5 boon_draft.tres before=44d8b941f8b28dfa2931984707b5c53e after=44d8b941f8b28dfa2931984707b5c53e
[V130-FS] MD5 trial_modifiers.tres before=7e9e5ac7d35d8d15171e69975ac3356d after=7e9e5ac7d35d8d15171e69975ac3356d
[V130-FS] MD5 stagger_rules.tres before=49ce964e7c268804efbf2f20bec6565d after=49ce964e7c268804efbf2f20bec6565d
[V130-FS] MD5 combo_rules.tres before=a1ad4635ae0342c696fe650eb13d4930 after=a1ad4635ae0342c696fe650eb13d4930
[V130-FS] MD5 player_actions.tres before=75390f71c002ef3cea6392a397ec267c after=75390f71c002ef3cea6392a397ec267c
[V130-FS] MD5 boss_01_margit.tres before=f2f71c7019c64e6c631c553887376c7d after=f2f71c7019c64e6c631c553887376c7d
[V130-FS] MD5 enemy_01_limgrave_soldier.tres before=9de25e0229d1c2c55a1740d2f838ad79 after=9de25e0229d1c2c55a1740d2f838ad79
[V130-FS] MD5 parry_rules.tres before=5d560e57c5c0fdfdec3f20b3f3535728 after=5d560e57c5c0fdfdec3f20b3f3535728
[V130-FS] MD5 focus_rules.tres before=289fd4f08424658d9625fd3ac3d93bfd after=289fd4f08424658d9625fd3ac3d93bfd
[V130-FS] existing_tables_zero_change PASS=true | 9 份既有 .tres 前后 md5 全部一致（零改动）
[V130-FS] SUMMARY pass=85 fail=0
[V130-FS] OVERALL=PASS
[V130-FS] RESULT=ALL_MATCH
[V130-FS] === SELFTEST END ===
verify_focus_settlement_v130_EXIT=0
```

### GATE-3 `--headless --quit`（主场景实证，不加载 `presentation.gd`）

```
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
[WaveTrial] 持久化基线读回：dungeon.wave_trial.best_wave=0 / dungeon.wave_trial.completed=false / grace.trial.points=0（经 WorldState.get_flag）
[R35][WaveTrial] 精准弹反生产订阅者已装配：ParryService 唯一实例 + 4 信号 connect（A48①/A54）
[R36][WaveTrial] 专注值/战技生产订阅者已装配：FocusService 唯一实例 + 4 信号 connect（A48①/A54）
GATE3_EXIT=0   SCRIPT_ERROR=0
```

### 4.5 最终统一三段门禁（`grep SCRIPT ERROR=0`）

```
=== GATE-1 ===   GATE1_EXIT=0
=== GATE-2a (5 件) ===   focus_config / focus_service / wave_trial_director /
                         verify_focus_v130 / verify_focus_settlement_v130  全部 EXIT=0
=== GATE-2b (2 份) ===   verify_focus_v130 EXIT=0 / verify_focus_settlement_v130 EXIT=0
=== GATE-3 ===   GATE3_EXIT=0
FINAL SCRIPT_ERROR_LINES=0
  g1.log: SCRIPT_ERROR=0
  g2a_focus_config.log / g2a_focus_service.log / g2a_wave_trial_director.log /
  g2a_verify_focus_v130.log / g2a_verify_focus_settlement_v130.log: 全部 SCRIPT_ERROR=0
  g2b_fp.log: SCRIPT_ERROR=0   g2b_fs.log: SCRIPT_ERROR=0   g3.log: SCRIPT_ERROR=0
[V130-FP] SUMMARY pass=92 fail=0   OVERALL=PASS   RESULT=ALL_MATCH
[V130-FS] SUMMARY pass=85 fail=0   OVERALL=PASS   RESULT=ALL_MATCH
[R21_QUALITY] courtyard.tscn ... node_count=41
[R36][WaveTrial] 专注值/战技生产订阅者已装配：FocusService 唯一实例 + 4 信号 connect（A48①/A54）
```

**PASS/FAIL 汇总**：`92 + 85 = 177 PASS / 0 FAIL`，两份 `RESULT=ALL_MATCH`，`SCRIPT ERROR=0`。

### 4.4 如实登记：并发中间态（不冒充全绿、不谎报）

- 本轮为多 Rank 并行轮次。首次 GATE-1 / GATE-3 在 **Rank-1 并行写入 `encounter_director.gd`（R35 `window_id` 半成品中间态）** 期间，各出现 1 条
  `SCRIPT ERROR: Parse Error: Identifier "_r35_last_parry_wid" not declared in the current scope.`
  `at: GDScript::reload (res://scripts/combat/encounter_director.gd:232)` +
  `ERROR: Failed to load script "res://scripts/combat/encounter_director.gd" with error "Parse error"`。
- 归属核验：`at:` 行全部指向 `res://scripts/combat/encounter_director.gd:232`（**Rank-1 唯一写入方文件**，R35 A58 `window_id` 相关成员尚未定义），**无一条指向 Rank-2 本轮 5 个文件**；Rank-2 的 GATE-2a / GATE-2b 三段在全过程恒为 `SCRIPT ERROR=0`；GATE-3 中 Rank-2 的 `[R36][WaveTrial] 专注值/战技生产订阅者已装配` / `node_count=41` 日志始终正常打印。
- Rank-1 收敛后**立即复跑**：`GATE1_EXIT=0 SCRIPT_ERROR=0` / `GATE3_EXIT=0 SCRIPT_ERROR=0`；随后**最终统一三段门禁**（§4.5）`FINAL SCRIPT_ERROR_LINES=0`、四段 `EXIT=0`。
- 按硬约束 Rank-2 对 `encounter_director.gd` **只读不改**、未越界修复；如实登记，不自行 git、不伪造产物。
- `--script` / `--headless` 工具模式尾部另有既有 autoload 告警（`[SaveSystem] --script 工具模式…跳过自动读回`、`[ChunkManager] 未找到 ChunkRoot…`、`[PCO] HUD 未就绪…绑定降级`、`[WaveTrial] 未找到 EncounterDirector…降级`、`2 ObjectDB instances were leaked at exit`）：均为 `WARNING`、**非 `SCRIPT ERROR`、非本轮引入、不影响断言与门禁（EXIT=0）**，如实登记。

**md5 零改动结论（既有表）**：`wave_trial.tres 793b6daa…` / `boon_draft.tres 44d8b941…` / `trial_modifiers.tres 7e9e5ac7…` / `stagger_rules.tres 49ce964e…` / `combo_rules.tres a1ad4635…` / `player_actions.tres 75390f71…` / `boss_01_margit.tres f2f71c70…` / `enemy_01_limgrave_soldier.tres 9de25e02…` / `parry_rules.tres 5d560e57…` **9 份前后完全一致**（完整值见上），本轮只新增 `focus_rules.tres`（`289fd4f0…`，验证脚本同样未写入），**既有 `.tres` 数值零改动**。

---

## 5. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 机制 ① 3 个新文件 + 完善功能 ②/③ `wave_trial_director.gd` 最小接线 + 2 个 verify + DONE + 回执落地；② 三段门禁 GATE-1 / 2a / 2b / 3 全 `EXIT=0`、最终统一 `SCRIPT ERROR=0`（Rank-2 三段全过程恒为 0）；③ 两份自测 `RESULT=ALL_MATCH`（92 + 85 = 177 PASS / 0 FAIL）；④ 9 份既有 `.tres` md5 前后一致（零改动），只新增 `focus_rules.tres`；⑤ `courtyard.tscn` 零改动，GATE-3 实证 `node_count=41`（uv `2/1/1` 因零改动保持）；⑥ A48① 4 信号**生产订阅者** = `wave_trial_director._bind_focus_signals()`（生产节点）+ 运行时实证 `focus_spend_count=1` + GATE-3 装配日志；⑦ A54 唯一实例：`get_focus_service()` 两次返回同一实例；⑧ A57 结算闭合：战技伤害并入唯一最终结算值、`points_awarded` 取源一致、不二次入账、输出格式零改动；⑨ 纯逻辑边界（I-1 不读写存档 / 不碰渲染 / 不写生产 `delta.json`）——验证脚本显式 `bind_persistence(null,null)` 降级；⑩ 点数只增不减 / 余额非负 / 不重复结算 / 每波累计清零 / **FP 只减不增除休息（含跨波不回满）** 机器判定；⑪ 回执已中枢归档（§11） |
| **失败** | 无（Rank-2 自有交付无失败项）。如实另记：首次 GATE-1 / GATE-3 在 Rank-1 并行写入中间态曾各出现 1 条 `SCRIPT ERROR: Parse Error`（归属 `encounter_director.gd:232`，Rank-1 文件、非本轮引入；复跑 + 最终统一门禁 `SCRIPT ERROR=0`），见 §4.4 |
| **需用户确认** | ① 全部 `[PLACEHOLDER]` 数值待人工试玩校准（只改表）；② Rank-1 运行时接线（`encounter_director.gd` / `hud.gd` 本轮并行写入、只读边界）；③ Rank-3 点数落盘与 `points_awarded` 订阅口径（A55/A57）；④ headless 真跑无渲染画面，未做 15~20 秒实机录屏回看；⑤ A48③ 完整「真实输入→磁盘/画面」断言脚本 `verify_focus_runtime_v130.gd` 归 Rank-1（目录所有权），待其收尾后复跑 GATE-3 取最终全绿；⑥ 每波是否回满 FP / `rest_refill` 是否切增量档 / `invalid_input_policy` 是否扩展策略（§7） |

---

## 6. 未完成项 / 阻塞

- **Rank-1 运行时接线未由 Rank-2 落地（授权边界，非缺陷）**：`encounter_director.gd` / `hud.gd` / `presentation.gd` 本轮唯一写入方 Rank-1，Rank-2 只读。战技键 `spend_fp(art_id)` / 赐福休息 `on_grace_rest()` 的**运行时驱动由 Rank-1 完成**；本轮 Rank-2 已提供稳定签名（§3）+ 2 个驱动口 + 生产订阅者 + 每帧 `tick(delta)` 转发 + 生产赐福休息链路。接线前导演层不主动施放战技，奖励恒 0（清波点数与既有等价，安全降级，正是「不改既有判定分支 / 输出格式」的保证）。
- **A48③ 完整真实可达回归脚本归 Rank-1**：`godot/scripts/render/verify_focus_runtime_v130.gd`（目录所有权 Rank-1）；Rank-2 不越界写。本轮提供 GATE-3 主场景实证（不加载 `presentation.gd`、真实 autoload）+ 两份 verify 驱动真实生产脚本（非替身 / 不模拟编排）+ 生产订阅者 / 唯一实例 / 结算闭合接口。
- **README 状态段归 Rank-3**：公共契约「README 长期维护已做/还差什么/资产表」由 Rank-3 唯一写入（`README.md` 状态段），Rank-2 不越界写；已在本 DONE 完整登记，待总指挥统一同步。
- **实机录屏目视**（公共契约要求 15~20 秒回看）：本轮交付为纯逻辑 + 数据表 + 最小接线 + headless 真跑，无渲染帧缓冲，未录屏；不伪造、列为后续 / 需用户确认。
- **`poise_damage` 并入既有削韧的降级口径**：真实主场景经 `_encounter.get_stagger_service().apply_hit()` 生效；`--script` / 依赖缺失时只记录到 `focus_poise_acc`、不崩；StaggerService 窗口期幂等拒绝是否影响战技削韧待裁决（§7）。
- **A65~A68 新裁决由 Rank-3 登记**（任务单目录所有权），Rank-2 不越界写。
- 无阻塞；所有硬约束内工作已完成。

---

## 7. 待总指挥裁决项（只登记、不擅改）

1. **数值校准**：`fp_max=100.0` / `fp_regen_on_rest=40.0` / `rest_refill=true` / `invalid_input_policy="reject"` / 两战技 12 项数值全部 `[PLACEHOLDER]`，待人工试玩校准；调参唯一入口 `godot/data/combat/focus_rules.tres`，同步 `verify_focus_v130.gd` 的 `EXPECT_*` 与本文数值表。
2. **每波是否回满 FP**：本轮设计为「专注值跨波资源」——每波只清本波累计、不回满，仅赐福休息 / 新一局 `reset()` 回满（守住「FP 只减不增除休息」）。请裁决是否改为每波回满，以及 `rest_refill=true/false` 的最终档位。
3. **`invalid_input_policy` 策略扩展**：首版唯一合法值 `reject`；是否允许 `clamp` / `ignore` 等策略（需同步改代码 + 表 + 回归用例，防止隐式扣 FP / 污染冷却），及归属。
4. **`damage` 语义口径**：本轮把 `damage` 作为「并入清波点数结算基数的点数伤害量」（与 R35 `points_bonus` 同口径，进 `base_for_combo` → 单一 combo 倍率 → 唯一最终值），不新增独立 HP 伤害通道（不改既有判定分支）。请裁决是否需另接 Boss HP / 独立伤害结算，及归属。
5. **`poise_damage` 并入既有削韧的落点**：真实主场景经 `encounter_director.get_stagger_service().apply_hit(poise_damage)` 生效；StaggerService 在处决窗口开启期间对 `apply_hit` 幂等拒绝（`REASON_WINDOW_OPEN`），可能影响战技削韧入账。请裁决是否需独立削韧通道 / 由 Rank-1 调整调用顺序。
6. **Rank-1 并行写入与 GATE-3 最终复跑**：本轮首次 GATE-1 / GATE-3 观测到 Rank-1 `encounter_director.gd` 半成品中间态 Parse Error（§4.4），复跑 + 最终统一门禁已 `SCRIPT ERROR=0`；请裁决 Rank-1 收尾后由总指挥统一复跑三段门禁取最终全绿，并明确 `focus_spent`（服务信号，订阅者 wave_trial_director）与 Rank-1 HUD 自有信号 / Rank-4 视觉反馈的职责分工 / 是否重复入账。
7. **A48③ 完整真实可达回归**：`verify_focus_runtime_v130.gd` 归 Rank-1（目录所有权），Rank-2 不越界写；请裁决 Rank-1 收尾后「真实输入 → 生产链路 → 磁盘 / 画面」全链断言的复跑与口径。
8. **实机录屏回看 / 既有 autoload WARNING**：headless 真跑无帧缓冲，按公共契约如实登记为后续动作 / 需用户确认（不冒充目视通过）；既有 WARNING 非本轮引入，是否纳入后续清理由总指挥裁决。
9. **A65~A68 登记**：本轮新增裁决由 Rank-3 登记（任务单目录所有权），Rank-2 只在本 DONE 反映接口影响，不越界写协作契约。

---

## 8. 设计漏洞主动识别（P0 / P1 / P2）

| 级别 | 漏洞 | 缓解 / 现状 |
|---|---|---|
| **P0** | 无 | 纯逻辑层覆盖幂等 / 非负 / 异常 / 存档越权 / 冷却 / FP 耗尽 / 重复结算 / 赐福休息 / 跨波资源，自测机器判定 |
| **P1** | `tick(delta)` 依赖外部每帧调用；导演层若漏接，冷却永不归零 | 本轮已由 `wave_trial_director._process()` 转发（不改既有分支）；§3.2 接线示意显式强调，与 R32 `StaggerService.tick` / R34 `ComboService.tick` / R35 `ParryService.tick` 同款约束 |
| **P1** | 战技输入未接时奖励恒 0 → 机制运行时「不可见」 | 本轮安全降级（清波点数与既有等价）；Rank-1 接线后才产生 >0 奖励，已登记为未完成项 |
| **P1** | 多 Rank 并行写入中间态使首次 GATE-1 / GATE-3 短暂不绿 | 归属核验（全在 Rank-1 `encounter_director.gd:232`）+ 复跑 + 最终统一门禁 `SCRIPT ERROR=0`；如实登记 §4.4 / 裁决项 6，不越界改他人文件 |
| **P2** | `rest_refill=false` 增量档 / `invalid_input_policy` 扩展未经手感校准 | 增量封顶已回归；策略首版固定 reject，列为裁决项 2/3 |
| **P2** | 全部 `[PLACEHOLDER]` 未经手感校准 | 调参唯一入口 + 校准同步清单，待人工试玩 |
| **P2** | `poise_damage` 经既有 StaggerService 可能遇窗口期幂等拒绝 | 生产订阅者只在 `apply_hit` 返回 ok 时计入 `focus_poise_applied`；裁决项 5 |

---

## 9. A48 硬要求落地声明（逐条）

| A48 | 落地 | 证据 |
|---|---|---|
| ① 新信号必须有**生产运行时订阅者**（不能只在验证脚本） | `wave_trial_director.gd`（挂 `courtyard.tscn` 的生产节点）在 `_init_combat_services()` 装配时调 `_bind_focus_signals()`，connect 全部 4 信号（`focus_spent` / `focus_rejected` / `focus_restored` / `focus_cooldown_ready`）到 `_on_focus_*` 生产回调；回调有真实职责（并入结算 / 削韧 / 计数），非空订阅 | `production_subscriber_in_source` / `a48_production_subscriber_runtime`（`focus_spend_count=1`）/ GATE-3 `[R36][WaveTrial] 专注值/战技生产订阅者已装配` |
| ② 遵守 A54 唯一实例（从既有导演层 `get_*_service()` 复用） | `_focus` 唯一实例由 `wave_trial_director.gd` 装配，`get_focus_service()` 暴露；Rank-1 / Rank-4 经该 getter 复用，绝不 new 第二个 | `a54_single_instance`（两次 getter 同一实例）/ `a54_focus_service_present` / GATE-3 装配日志 / §3.6 接线示意 |
| ③ 一条**不加载 `presentation.gd`、不在验证脚本内模拟编排**的真实可达回归 | GATE-3 `--headless --quit` 主场景真跑（真实 autoload `PointsCommitOrchestrator`、不加载 `presentation.gd`）实证生产链路；两份 verify 驱动的是**真实生产脚本** `wave_trial_director.gd`（`real_production_director`），结算值经真实 `_clear_wave()` 产出，不在验证脚本内自建替身 / 模拟编排 | GATE-3 R36 装配日志 + `node_count=41`；`real_production_director` / `production_subscriber_in_source`；完整「真实输入→磁盘/画面」断言脚本 `verify_focus_runtime_v130.gd` 归 Rank-1（目录所有权），见 §6 / 裁决项 7（如实登记，不冒充） |
| ④ 纯逻辑 + 单元断言不算可玩交付 | 本轮交付纯逻辑 + 数据表 + 最小接线 + headless 真跑；**未做 15~20 秒实机录屏回看**，如实列为未完成 / 需用户确认，不冒充可玩交付 | §5 需用户确认 / §6 未完成项 |

---

## 10. 硬约束遵守声明

- `encounter_director.gd` / `hud.gd` / `presentation.gd` / `points_commit_orchestrator.gd` / `project.godot` / `courtyard.tscn` / 场景 / 素材 / 其它 Rank 文件**只读未改**；`courtyard.tscn` 节点数 `41` / uv `2/1/1` 未破坏（GATE-3 实证）。
- 既有 `.tres` 数值零改动（9 份 md5 前后一致），只新增 `focus_rules.tres` 一张新表。
- 纯逻辑（I-1）：`FocusService`（RefCounted）/ `FocusConfig`（Resource）均不 `add_child` / 不 `get_tree()` / 不 `/root/...` / 不 `open(user://)` / 不 `set_flag` / 不 `commit` / 不碰渲染 / 不写生产存档；`wave_trial_director.gd` 接线只在 `_enter_telegraph()` / `_clear_wave()` / `_request_grace_rest()` / 生产订阅回调四处消费数据、不写盘；验证脚本显式 `bind_persistence(null,null)` 降级，全程不触碰 `user://slot_01/delta.json`。
- Godot4 自测纪律：`extends SceneTree` 用 `Engine.get_main_loop() as SceneTree` 取 root（只读断言），`add_child` 后显式 `call("_ready")`（不依赖自动 flush），资源回读 `CACHE_MODE_IGNORE`；不用 `get_tree()`、不用 `/root/...` 绝对路径。
- 零付费、零外部依赖、不启 GPU job；不伪造产物、不谎报成功、不自行 git；未删除 `.workbuddy`。
- 默认不刺探：未扫目录做进度巡检、未写只读探针 / 巡检脚本；仅按任务单要求读必做文件、按 SCRIPT ERROR `at:` 行核验归属、核对回执目录与中枢归档结构。

---

## 11. 回执与中枢归档确认（写后已确认）

- 回执写入 Rank-2 授权路径（**`teamwork/command_center/`，非工程根**）：
  `teamwork/command_center/ai/2/outbox/cmd-20261112-154132-912-A2.json`，
  四字段 `{"task_id", "ai":2, "status":"done", "result"}`。
- 中枢已归档（写后回读确认，如实登记、不伪造）：
  - **归档副本**：`teamwork/command_center/dispatcher/receipts/cmd-20261112-154132-912-A2.json`，回读 **VALID_JSON**，`keys=['ai','result','status','task_id']` 四字段齐全，`task_id=cmd-20261112-154132-912-A2` / `ai=2` / `status=done` / `result_len=488`，与 outbox 回执逐字一致。
  - `ai/2/outbox/` 按中枢流程归档后已清空（回执移入 `dispatcher/receipts/`）；`ai/2/inbox/` 仅余 `task_cmd-20261112-154132-912-A2.json` 派单任务单，属中枢正常处理；不重放、不伪造。
  - `teamwork/command_center/ai/2/status.json` 更新为 `{"ai":2,"state":"idle","current_task":"","completed":44,"last_seen":"2026-11-12 16:04:37"}`（`completed` 由 43 → 44、`current_task` 清空、`state` working → idle）。
  - `dispatcher/ledger.jsonl` 第 **151** 行为本任务单 `cmd-20261112-154132-912-A2` 登记：`status=done` / `finished_at=2026-11-12 16:04:37` / `result` 与回执逐字一致；派单 `issued_at=2026-11-12 15:41:33` 与任务单一致。
  - `dispatcher/dispatcher.log` 尾部：`[2026-11-12 16:04:37] ← 2 号 AI 回执 <cmd-20261112-154132-912-A2> 完成：R36/v0.13.0 交付完成…`（回收验证 `done`）。
  - 注：本轮中枢归档副本文件名为 `receipts/<id>.json`（非 `receipt_<id>.json` 前缀），`status.json` / `ledger.jsonl` / `dispatcher.log` 三处均实证回收；如实登记，不臆造文件名。
