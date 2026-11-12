# DONE-R35.md · R35 / v0.12.0「精准弹反 · 消费闭合」交付报告（Rank-2）

> 轮次：`R35 / v0.12.0` ｜ 任务单 id：`cmd-20261112-125821-139-A2` ｜ 执行 AI：`2（Rank-2 战斗系统与数据驱动）`
> 真源：`teamwork/Rank-2/调度任务单-latest.json`（`task` 全文 + 公共契约 + 目录所有权 + A48 硬要求）
>   + `teamwork/Rank-2/DONE-R34.md` §3（既有服务接口签名）+ `teamwork/00-群聊总线.md` MSG-20261112-1255-HOST（A39~A57 裁决）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> 结论：**三段门禁全绿、`SCRIPT ERROR=0`、两份自测 `RESULT=ALL_MATCH`（58 + 80 = 138 PASS / 0 FAIL）、8 份既有 `.tres` md5 零改动、`courtyard.tscn node_count=41` 保持、A48①/A54 落地、回执已中枢归档**。
> 如实登记：GATE-3 在 **Rank-1 并行写入 `hud.gd` / `encounter_director.gd`（R35 半成品中间态）** 期间曾间歇出现 `SCRIPT ERROR: Parse Error`（46 条 / 4 条，全部 `at: GDScript::reload (res://scripts/hud.gd...)` 或 `res://scripts/combat/encounter_director.gd...`，非本轮 Rank-2 文件引入、Rank-2 只读无权改）；Rank-1 写入完成后的**最终统一门禁 `SCRIPT ERROR=0`**（详见 §4.4 / §7）。

---

## 1. 交付清单（实际落地文件）

### 机制 ① · 精准弹反 Parry（新增 3 件，均归 Rank-2）

| 文件 | 类型 | 作用 |
|---|---|---|
| `godot/data/combat/parry_rules.tres` | 新增数据表 | `window_sec / cooldown_sec / poise_bonus / points_bonus / combo_keep / fail_penalty` 六个 `[PLACEHOLDER]` 字段，数值真源 / 调参唯一入口 |
| `godot/scripts/combat/parry_config.gd` | 新增 Resource（`class_name ParryConfig`，`extends Resource`） | 表结构 / 6 字段契约 / `is_valid()` 纯函数 / 逐项 rationale / 降级基线 / 调参唯一入口 |
| `godot/scripts/combat/parry_service.gd` | 新增 RefCounted（`class_name ParryService`）纯逻辑 | 开窗 / 弹反判定 / 冷却 / 超时 / Boss 招式落地 / Boss 死亡 / 异常拒绝 + **4 个公开信号** |

### 完善功能 ② · 结算与生产接线（修改 1 件，本轮唯一写入方 = Rank-2）

| 文件 | 改动 | 边界 |
|---|---|---|
| `godot/scripts/combat/wave_trial_director.gd` | 10 处精确 Edit：新增 `PARRY_RULES_PATH` 常量 / 10 个记录字段 / `_process` 每帧 `tick(delta)` 转发 / `_enter_telegraph()` 波次开窗 / `_clear_wave()` 把 `_parry_points_acc` 并入 `base_for_combo` + 末波 `on_boss_defeated()` / `_init_combat_services()` 装配唯一实例并 `_bind_parry_signals()`（A48① 生产订阅者）/ `_reset_r34_records()` 清记录 / 新增 4 个回调 + `_open_parry_window_for_wave()` + 3 个真实输入驱动口 + `get_parry_service()` / `get_settlement_snapshot()` 追加 5 key / `get_snapshot()` 追加 8 key | **既有判定分支 / 帧数据 / 输出格式（`wave_cleared(index,pts)` 签名与值、`_refresh_hud()` 文本、既有 27 + R34 8 个 key）/ 既有 `.tres` 数值一律逐字未动**；弹反 `points_bonus` 只并入 `base_for_combo` 一次 → 经既有 `combo.settle()` 得唯一最终结算值 → HUD 经 `get_last_settlement()` 取该值发 `points_awarded` 一次入账（A57，**不二次入账**） |

### 自测脚本（新增 2 件，均在 `godot/scripts/combat/`）

| 文件 | 作用 | 结果 |
|---|---|---|
| `verify_parry_v120.gd` | 机制 ① 正常 / 边界 / 异常三类：开窗、窗口内成功、窗口外拒绝、重复按键幂等、重复开窗幂等、冷却期拒绝、冷却后可再开窗、恰好/超长超时关窗、窗口内递减、Boss 招式落地失败 / 成功后 no-op、Boss 死亡不再开窗 / 幂等、reset、tick(null/负/字符串/NaN/Inf)、config=null、set_config(null)、非法表、异常后正常流程、4 信号 payload、A48① 静态证据 | `pass=58 fail=0 RESULT=ALL_MATCH` |
| `verify_parry_settlement_v120.gd` | 弹反奖励并入结算（150 / 240 / 336 三组合）+ A57 取源一致 + 点数单调 / 余额非负 / 不重复结算 / 每波累计清零 + 既有输出格式零改动 + A48① 运行时实证 + A54 唯一实例 + 真实生产脚本驱动 + md5 前后对比证明既有表零改动 | `pass=80 fail=0 RESULT=ALL_MATCH` |

### 文档 / 回执（新增 2 件）

| 文件 | 作用 |
|---|---|
| `teamwork/Rank-2/DONE-R35.md` | 本交付报告（交付清单 / 真跑输出原文 / 验收三态 / 公开方法与信号完整签名 / md5 零改动结论 / 未完成项 / 待裁决项） |
| `teamwork/command_center/ai/2/outbox/cmd-20261112-125821-139-A2.json` | 本轮回执，中枢归档见 §10 |

### 只读未改（硬约束）

`godot/scripts/combat/encounter_director.gd`、`godot/scripts/hud.gd`、`godot/test/presentation.gd`（三者本轮唯一写入方 Rank-1，本轮并行写入中，Rank-2 只读）、
`godot/scripts/rpg/points_commit_orchestrator.gd`、`godot/project.godot`（Rank-3 所有 / A56 autoload）、
`godot/scenes/courtyard.tscn`、场景 / 素材 / 其它 Rank 文件、既有 `.tres`
（`wave_trial.tres` / `boon_draft.tres` / `trial_modifiers.tres` / `stagger_rules.tres` / `combo_rules.tres` / `player_actions.tres` / `boss_01_margit.tres` / `enemy_01_limgrave_soldier.tres`）。

---

## 2. 玩法拆解表（需求 → 机制 → 数值 → 状态 → 验收）

### 机制 ① · 精准弹反 Parry 状态机

| 需求 | 机制 | 数值（`[PLACEHOLDER]` 首版） | 状态（实例内、不持久化） | 验收 |
|---|---|---|---|---|
| Boss 出招 / 波次开始开精准弹反窗口 | `open_window()`：冷却期 / Boss 死亡 / 重复开窗一律拒绝 | `window_sec=0.35` | `_window_open` / `_window_remaining` | `window_open_ok` / `signal_opened_1` / `cooldown_reject_open` / `repeat_open_idempotent` |
| 窗口内按键成功给削韧 + 点数奖励 | `try_parry()`：关窗、进冷却、emit `parry_succeeded` | `poise_bonus=25.0` / `points_bonus=50` / `combo_keep=true` | `_consumed` / `_success_count` / `_cooldown_remaining` | `window_success_ok` / `success_poise_bonus` / `success_points_bonus` / `signal_succeeded_1` |
| 窗口外按键拒绝 | `try_parry()` 未开窗 → `REASON_NO_WINDOW` | — | — | `window_outside_reject` |
| 重复按键幂等 | 成功后（含冷却期）`_consumed` 优先 → `REASON_ALREADY_PARRIED`，不给奖励 | — | `_consumed` | `duplicate_key_idempotent` / `cooldown_reject_parry` |
| 冷却期拒绝 | 成功后 `open_window()` → `REASON_COOLDOWN`；`tick()` 推进冷却 | `cooldown_sec=1.2` | `_cooldown_remaining` | `cooldown_reject_open` / `cooldown_then_reopen` |
| 超时关闭 | `tick(delta)` 确定性推进，窗口归零关窗 + `parry_failed(timeout, fail_penalty)` | `fail_penalty=10` | `_fail_count` | `within_window_decrement` / `exact_timeout_close` / `overlong_delta_timeout` / `timeout_failed_signal` |
| Boss 招式落地 | `on_boss_move_landed()`：窗口仍开且未弹反 → 失败关窗；已成功 / 无窗口 → 幂等 no-op | — | — | `boss_move_landed_fail` / `boss_move_landed_noop_after_success` |
| Boss 死亡不再开窗 | `on_boss_defeated()` 置标志、关窗；此后 open/try 拒绝；幂等 | — | `_boss_defeated` | `boss_defeated_flag` / `boss_defeated_no_window` / `boss_defeated_no_parry` / `boss_defeated_idempotent` |
| 异常输入拒绝 | `tick(null/负/字符串/NaN/Inf)` → `REASON_INVALID_DELTA`；config=null / 非法表 → `REASON_NO_CONFIG`；拒绝不改状态 | — | — | `invalid_tick_*` / `no_config_*` / `invalid_table_*` / `invalid_then_normal_ok` |
| 每波 / 每场重置 | `reset()` 关窗、清冷却 / 死亡 / 消费标志与计数 | — | — | `reset_clears_all` |

### 完善功能 ② · 结算接线（沿用 A57：最终结算值经 `points_awarded` 发出，不二次入账）

| 需求 | 落地位置 | 效果 | 验收 |
|---|---|---|---|
| 波次 / Boss 出招开窗 | `_enter_telegraph()` → `_open_parry_window_for_wave()`：`_parry.reset()` + `open_window()`；`on_boss_move_telegraph()` 供 Rank-1 每次前摇调用 | 每波开窗、每波清本波累计 | `parry_window_open_at_wave_start` / `a48_production_subscriber_runtime` |
| 弹反成功 `points_bonus` 并入清波点数结算 | `_clear_wave()`：`base_for_combo = maxi(0, base_for_combo + _parry_points_acc)`（在 boon 结算之后、既有 `combo.settle(base_for_combo)` 之前插入一行） | 唯一最终结算值 `settled_points` 含弹反奖励；HUD 经 `combo.get_last_settlement()` 取同值发 `points_awarded` 一次 | `parry_points_into_settled_150` / `a57_awarded_source_consistent` / `no_double_settle_one` |
| 弹反成功 `poise_bonus` 并入既有削韧 | 生产订阅者 `_on_parry_succeeded()`：经 `_encounter.get_stagger_service()` 取同一 StaggerService → 既有 `apply_hit(poise_bonus)`；`--script` 依赖缺失时只记录、不崩 | 弹反削韧真实并入既有韧性结算，不改既有判定分支 | `parry_success_recorded` / `try_parry_reward_payload` |
| 点数只增不减 / 余额非负 / 不重复结算 / 每波清零 | `settled_points` 恒 `>=0`、既有 `_persist_settle` max 保护、既有 `WAVE_ACTIVE` 门控拒绝重复 `on_encounter_finished`、`_open_parry_window_for_wave()` 每波清 acc | 不二次入账、不把第 1 波奖励带进第 2 波 | `points_monotonic_increase` / `balance_nonneg` / `no_double_settle` / `parry_acc_cleared_next_wave` / `no_repeat_parry_bonus_wave2` |
| 既有输出格式零改动 | `wave_cleared.emit(_index, pts)` 第二参仍为基础 `pts`；`get_snapshot()` 既有 27 + R34 8 个 key 逐字不动，只追加 8 个只读 key | 回归不回退 | `wave_cleared_format_unchanged` / `legacy_snapshot_keys_all_present` / `r34_snapshot_keys_intact` |

### 数值拆解 / rationale（完整版见 `parry_config.gd` 头注）

- **调参唯一入口（只改表不改代码）**：`godot/data/combat/parry_rules.tres`。代码内 `ParryConfig.DEFAULT_*` 是**非法降级基线**（刻意 `!=` 表值，`verify_parry_v120.gd` 的 `default_is_not_design_*` 机器判定），不是设计数值。校准同步清单：`.tres` → `verify_parry_v120.gd` 的 `EXPECT_*` → 本文数值表 → 三段门禁；不静默改数。
- `window_sec = 0.35` `[PLACEHOLDER]`：精准弹反强调「窄窗口」，350ms 量级；与 R32 处决窗口 3.0s 拉开一个数量级，避免退化成常驻格挡；纯逻辑不读真实时钟、由导演层每帧 `tick(delta)` 推进。
- `cooldown_sec = 1.2` `[PLACEHOLDER]`：成功后 1.2s 冷却，防连续开窗把 `poise_bonus` / `points_bonus` 刷成奖励通胀；略大于 `window_sec`，保证一次出招节奏内至多成功弹反一次。
- `poise_bonus = 25.0` `[PLACEHOLDER]`：与既有 `stagger_rules.tres` 的 `reference_poise_damage=25.0` / `stagger_max=100.0` 同量级，等于「一次标准命中」的削韧，弹反成功约等于白送一次有效削韧，不改既有削韧判定分支。
- `points_bonus = 50` `[PLACEHOLDER]`：与既有 `execute_bonus_points=50` 同量级，避免弹反奖励盖过处决出口；并入清波结算基数后随既有**单一**连击倍率结算（A51 不叠乘其它层）。
- `combo_keep = true` `[PLACEHOLDER]`：弹反成功默认保留连击（防反不打断进攻节奏）；置 false 可作「弹反断连」对照档。本轮只广播该值 / 记录，**不擅自联动既有 ComboService**（避免破坏 A57 settle 口径），见 §7。
- `fail_penalty = 10` `[PLACEHOLDER]`：弹反失败的可观测惩罚记录量（供 Rank-4 失败反馈 / 未来对接），量级小于 `points_bonus=50`；本轮**不真正扣点**，守住既有「点数只增不减 / 余额非负」，见 §7。

### 结算值三组实证（均 `RESULT=ALL_MATCH`）

| 组合 | base 推导 | 倍率 | 最终结算值 | 断言 |
|---|---|---|---|---|
| 弹反（无抉择 / 0 连击） | `100 + 50 = 150` | D 1.0 | **150** | `parry_points_into_settled_150` / `a57_awarded_source_consistent` |
| 弹反 + 14 连击 | `150` | A 1.6 | **240** | `parry_plus_combo_240` |
| 弹反 + 抉择 +60 + 14 连击 | `100 + 60 + 50 = 210` | A 1.6 | **336** | `parry_plus_boon_plus_combo_336` |

---

## 3. 供 Rank-1 与 Rank-4 使用的公开方法与信号完整签名（本轮重点）

> `ParryService` 是 `RefCounted` 纯逻辑，**信号是 Object 级能力**：Rank-1 / Rank-4 直接 `connect` 到本服务实例即可，
> 无需场景树、无需 `add_child`、无需 `/root/...`。以下签名**稳定、不再改动**。
> **A54 唯一实例**：由 `wave_trial_director.gd` 装配，Rank-1 / Rank-4 经 `get_parry_service()` 复用，绝不另建第二个。

### 3.1 公开信号（`godot/scripts/combat/parry_service.gd`）

```
signal parry_window_opened(window_sec: float)
    # open_window() 成功开窗时发；window_sec=本次窗口时长（表值 0.35 [PLACEHOLDER]）。
    # 供 Rank-1 HUD「精准弹反」预兆 / 读秒、Rank-4 前摇高亮。
    # ★ A48①：生产订阅者 = wave_trial_director._bind_parry_signals()（生产节点，非验证脚本）。
signal parry_succeeded(poise_bonus: float, points_bonus: int, combo_keep: bool)
    # 窗口内 try_parry() 成功时发；payload 即并入结算的两项奖励 + 连击保持标志。
    # 供 Rank-1 结算接线 / Rank-4 弹反火花演出。
signal parry_failed(reason: String, fail_penalty: int)
    # 弹反失败（超时 / Boss 招式落地未弹反）时发；reason ∈ {CLOSE_TIMEOUT="timeout",
    #   CLOSE_MOVE_LANDED="move_landed"}，fail_penalty=表内记录量（10 [PLACEHOLDER]）。
    # 供 Rank-4 失败反馈。
signal parry_window_closed(reason: String)
    # 窗口关闭时发；reason ∈ {CLOSE_SUCCESS="success", CLOSE_TIMEOUT="timeout",
    #   CLOSE_MOVE_LANDED="move_landed", CLOSE_BOSS_DEFEATED="boss_defeated",
    #   CLOSE_MANUAL="manual"}。供 Rank-4 收起预兆 / 读秒。
```

### 3.2 公开方法（全静态类型）

```
class_name ParryService (extends RefCounted)
_init(config: ParryConfig = null)                 # 构造注入规则表，自动 reset()
set_config(config: ParryConfig) -> void           # 替换表并 reset()（含 null 降级验证）
get_config() -> ParryConfig
reset() -> void                                  # 关窗、清冷却/死亡/消费标志与计数（每波·每场 Boss 战开始调用）

open_window() -> Dictionary                       # 开精准弹反窗口；冷却期/死亡/重复开窗拒绝
try_parry() -> Dictionary                         # 玩家按弹反键；窗口内成功给奖励、其余幂等/拒绝
tick(delta_sec: Variant) -> Dictionary            # 每帧推进窗口/冷却；窗口归零超时失败关窗；异常拒绝
on_boss_move_landed() -> Dictionary               # Boss 招式落地；未弹反失败关窗、已成功幂等 no-op
on_boss_defeated() -> Dictionary                  # Boss 死亡：置标志·关窗·此后不再开窗；幂等

is_window_open() -> bool
get_window_remaining() -> float
get_cooldown_remaining() -> float
is_boss_defeated() -> bool
is_consumed() -> bool                            # 本次窗口是否已成功弹反（重复按键幂等）
get_success_count() -> int
get_fail_count() -> int
get_last_result() -> Dictionary                  # 最近一次成功弹反结果（Dictionary 副本）
get_last_fail_penalty() -> int
get_window_sec() -> float                        # 当前表 window_sec
get_cooldown_sec() -> float
get_poise_bonus() -> float
get_points_bonus() -> int
get_combo_keep() -> bool
get_fail_penalty() -> int
get_snapshot() -> Dictionary                     # 全状态快照（见 §3.3）
```

**接线注意**：① `tick(delta)` 必须每帧调用（本轮已由 `wave_trial_director._process()` 转发，纯逻辑不读真实时钟）；② 每波 / 每场 Boss 战开始调一次 `reset()`（本轮 `_open_parry_window_for_wave()` 已在每波 `_enter_telegraph()` 调用）；③ `try_parry()` 成功后 `_consumed` 幂等，重复 / 同帧多次不再给奖励；④ 「冷却期拒绝」由 `open_window()` 承载（`REASON_COOLDOWN`），`try_parry()` 在 `_consumed` 时优先返回 `REASON_ALREADY_PARRIED`；⑤ 结算点数落盘由 Rank-3（I-1 / A55 `points_awarded` 唯一权威通道）接线，Rank-2 只产出最终结算值。

### 3.3 返回 Dictionary 字段（供 Rank-1 / Rank-4 消费）

```
open_window        : {ok, reason, window_open, window_remaining, cooldown_remaining, boss_defeated}
try_parry          : {ok, reason, poise_bonus, points_bonus, combo_keep, window_open,
                     cooldown_remaining, success_count, boss_defeated}
tick               : {ok, reason, delta_sec, window_open, window_remaining,
                     cooldown_remaining, timed_out}
on_boss_move_landed: {ok, reason, window_open, fail_count, fail_penalty, boss_defeated}
on_boss_defeated   : {ok, reason, window_open, boss_defeated, success_count}
get_snapshot       : {window_open, window_remaining, cooldown_remaining, boss_defeated,
                     consumed, success_count, fail_count, window_sec, cooldown_sec,
                     poise_bonus, points_bonus, combo_keep, fail_penalty, config_present,
                     last_result}
```

成功恒 `poise_bonus>=0` / `points_bonus>=0` / `combo_keep` 取表值；拒绝时 `poise_bonus=points_bonus=0`、`combo_keep=false`、不改状态；`get_snapshot()` 的 `window_open` / `window_remaining` / `cooldown_remaining` / `ok` / `reason` / `points_bonus` / `poise_bonus` 与 Rank-1 `hud.gd` 的 `R35_KEY_*` 鸭子类型候选逐项命中（见 §3.7）。

### 3.4 公开常量（reason 取值，签名稳定）

```
方法 reason:
    REASON_OK                = "ok"
    REASON_NO_CONFIG         = "no_config"        # config 缺失 / 非法表
    REASON_NO_WINDOW         = "no_window"        # 未开窗按键
    REASON_ALREADY_PARRIED   = "already_parried"  # 重复按键幂等 / 重复开窗
    REASON_COOLDOWN          = "cooldown"         # 冷却期 open_window 拒绝
    REASON_BOSS_DEFEATED     = "boss_defeated"    # Boss 死亡后开窗/按键
    REASON_INVALID_DELTA     = "invalid_delta"    # tick(null/负/非数值/NaN/Inf)

parry_window_closed / parry_failed reason:
    CLOSE_SUCCESS            = "success"
    CLOSE_TIMEOUT            = "timeout"
    CLOSE_MOVE_LANDED        = "move_landed"
    CLOSE_BOSS_DEFEATED      = "boss_defeated"
    CLOSE_MANUAL             = "manual"           # reset() / 新一局
```

### 3.5 `ParryConfig` 公开接口（`extends Resource` / `class_name ParryConfig`）

```
@export var window_sec: float        # 精准弹反窗口时长（表值 [PLACEHOLDER]）
@export var cooldown_sec: float      # 弹反成功冷却（表值 [PLACEHOLDER]）
@export var poise_bonus: float       # 削韧加成（表值 [PLACEHOLDER]）
@export var points_bonus: int        # 点数加成（表值 [PLACEHOLDER]）
@export var combo_keep: bool         # 是否保留连击（表值 [PLACEHOLDER]）
@export var fail_penalty: int        # 失败惩罚记录量（表值 [PLACEHOLDER]）
is_valid() -> bool                   # 6 字段类型合法 / window_sec>0 / 其余>=0 / 无 NaN/Inf
get_window_sec() -> float / get_cooldown_sec() -> float / get_poise_bonus() -> float /
get_points_bonus() -> int / get_combo_keep() -> bool / get_fail_penalty() -> int
# 降级基线（不是设计数值）：DEFAULT_WINDOW_SEC / DEFAULT_COOLDOWN_SEC /
#   DEFAULT_POISE_BONUS / DEFAULT_POINTS_BONUS / DEFAULT_COMBO_KEEP / DEFAULT_FAIL_PENALTY
```

### 3.6 Rank-1 接线示意（伪代码，供 `encounter_director.gd` / `hud.gd` / 输入层）

```gdscript
# A54 唯一实例：从波次导演复用，绝不 new 第二个 ParryService
var parry: ParryService = wave_trial_director.get_parry_service()
parry.connect("parry_window_opened", Callable(self, "_on_parry_window_opened"))
parry.connect("parry_succeeded",     Callable(self, "_on_parry_succeeded"))
parry.connect("parry_failed",        Callable(self, "_on_parry_failed"))
parry.connect("parry_window_closed", Callable(self, "_on_parry_window_closed"))

func _on_boss_telegraph() -> void:
    parry.open_window()                       # 或 wave_trial_director.on_boss_move_telegraph()
func _on_parry_key_pressed() -> void:
    var r: Dictionary = parry.try_parry()     # 或 wave_trial_director.try_parry()
func _process(delta: float) -> void:
    # 导演层 _process 已转发 parry.tick(delta)；若 Rank-1 另持实例，务必复用同一实例、只转发一次
    pass
func _on_boss_move_hit_player() -> void:
    parry.on_boss_move_landed()               # 或 wave_trial_director.on_boss_move_landed()
func _on_boss_defeated() -> void:
    parry.on_boss_defeated()                  # 末波清波已由 _clear_wave() 调用
# 结算：parry_succeeded 的 points_bonus 已由 wave_trial_director 生产订阅者并入
#       base_for_combo → combo.settle() 唯一最终值 → HUD points_awarded 一次入账（A57）
```

**Rank-1 `hud.gd` 实际对齐情况（本轮回读确认）**：`hud.gd` 经 `wave.get_parry_service()` → `bind_parry_service()` 复用 A54 唯一实例；其 `R35_PARRY_SIGNAL_OPEN/CLOSE` 候选命中我的 `parry_window_opened` / `parry_window_closed`，`R35_PARRY_METHOD_TRY` 命中 `try_parry()`，`R35_KEY_OPEN/REMAINING/COOLDOWN/OK/REASON/POINTS/POISE` 分别命中 `get_snapshot()` 的 `window_open` / `window_remaining` / `cooldown_remaining` 与 `try_parry()` 返回的 `ok` / `reason` / `points_bonus` / `poise_bonus`。**唯一差异**：`R35_KEY_WID=["window_id","parry_window_id"]` 在我的 `get_snapshot()` 中不存在，Rank-1 已用 `_r35_make_window_id()` 本地生成兜底（不崩），见 §7 待裁决项 2。

### 3.7 Rank-4 视觉反馈接线示意（订阅同一实例，不经场景树）

```gdscript
func _on_parry_window_opened(window_sec: float) -> void:
    # 金色预兆：读秒从 window_sec 递减；前摇高亮
func _on_parry_succeeded(poise_bonus: float, points_bonus: int, combo_keep: bool) -> void:
    # 弹反火花 / 顿帧；poise_bonus、points_bonus 供奖励飘字；combo_keep 供连击条是否闪断
func _on_parry_failed(reason: String, fail_penalty: int) -> void:
    # reason ∈ timeout / move_landed：失败收光 / 断连提示；fail_penalty 供惩罚角标
func _on_parry_window_closed(reason: String) -> void:
    # reason ∈ success / timeout / move_landed / boss_defeated / manual：收起预兆 + 读秒
```

### 3.8 `wave_trial_director.gd` 本轮新增公开接口（供 Rank-1 / 验证 / HUD）

```
get_parry_service() -> ParryService          # ★ A54 唯一实例（Rank-1 / Rank-4 复用）
try_parry() -> Dictionary                    # 真实输入驱动口（转调唯一实例）
on_boss_move_telegraph() -> Dictionary       # Boss 出招前摇开窗（转调唯一实例）
on_boss_move_landed() -> Dictionary          # Boss 招式落地（转调唯一实例）

get_settlement_snapshot() 追加 5 个只读 key（既有 key 逐字不动）：
    parry_points_bonus / parry_poise_bonus / parry_poise_applied /
    parry_success_count / parry_combo_keep
get_snapshot() 追加 8 个只读 key（既有 27 + R34 8 个 key 逐字不动）：
    parry_poise_acc / parry_points_acc / parry_success_count / parry_fail_count /
    parry_window_opened_count / parry_poise_applied / parry_last_combo_keep /
    parry_last_close_reason
```

---

## 4. 真跑输出原文（三段门禁，`SCRIPT ERROR=0`）

命令前缀统一为 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；
引擎版本行：`Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org`。

### GATE-1 `--headless --import`

```
[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
... [ DONE ] first_scan_filesystem
[   0% ] update_scripts_classes | Started 正在注册全局类…… (2 steps)
[   0% ] update_scripts_classes | ParryConfig
[  33% ] update_scripts_classes | ParryService
[ DONE ] update_scripts_classes
GATE1_EXIT=0   SCRIPT_ERROR=0
```

### GATE-2a `--check-only --script`（语法门禁，5 件）

```
combat/parry_config                    EXIT=0  SCRIPT_ERROR=0
combat/parry_service                   EXIT=0  SCRIPT_ERROR=0
combat/wave_trial_director             EXIT=0  SCRIPT_ERROR=0
combat/verify_parry_v120               EXIT=0  SCRIPT_ERROR=0
combat/verify_parry_settlement_v120    EXIT=0  SCRIPT_ERROR=0
```

### GATE-2b `--headless --script <verify>`（实跑）

`verify_parry_v120.gd`（共 58 条逐条 `PASS=true` 原文，正常 / 边界 / 异常三类，此处列代表行与汇总）：

```
[V120-PR] === SELFTEST START ===
[V120-PR] scene_tree_root_via_main_loop PASS=true | Engine.get_main_loop() as SceneTree -> root，不用 get_tree()/绝对路径
[V120-PR] table_load_cache_ignore PASS=true | path=res://data/combat/parry_rules.tres
[V120-PR] ruleset_valid PASS=true | ParryConfig.is_valid()=true
[V120-PR] window_sec_ph PASS=true | got=0.35 expect=0.35 [PLACEHOLDER]
[V120-PR] cooldown_sec_ph PASS=true | got=1.20 expect=1.20 [PLACEHOLDER]
[V120-PR] poise_bonus_ph PASS=true | got=25.0 expect=25.0 [PLACEHOLDER]
[V120-PR] points_bonus_ph PASS=true | got=50 expect=50 [PLACEHOLDER]
[V120-PR] combo_keep_ph PASS=true | got=true expect=true [PLACEHOLDER]
[V120-PR] fail_penalty_ph PASS=true | got=10 expect=10 [PLACEHOLDER]
[V120-PR] signal_window_opened_exists PASS=true | signal parry_window_opened(window_sec: float)
[V120-PR] signal_succeeded_exists PASS=true | signal parry_succeeded(poise_bonus: float, points_bonus: int, combo_keep: bool)
[V120-PR] signal_failed_exists PASS=true | signal parry_failed(reason: String, fail_penalty: int)
[V120-PR] signal_window_closed_exists PASS=true | signal parry_window_closed(reason: String)
[V120-PR] window_open_ok PASS=true | open_window -> ok / window_open=true / remaining=0.35
[V120-PR] window_success_ok PASS=true | 窗口内 try_parry -> ok
[V120-PR] success_poise_bonus PASS=true | poise_bonus=25.0 [PLACEHOLDER]
[V120-PR] success_points_bonus PASS=true | points_bonus=50 [PLACEHOLDER]
[V120-PR] signal_succeeded_1 PASS=true | parry_succeeded 恰 1 次，payload=(25.0,50,true)
[V120-PR] window_outside_reject PASS=true | 未开窗 try_parry -> no_window 拒绝、不给奖励
[V120-PR] duplicate_key_idempotent PASS=true | 成功后重复按键 -> already_parried 幂等拒绝，success_count 仍 1（不刷点）
[V120-PR] repeat_open_idempotent PASS=true | 窗口已开再 open_window -> already_parried 幂等拒绝（不重复开窗）
[V120-PR] cooldown_reject_open PASS=true | 成功后冷却期 open_window -> cooldown 拒绝
[V120-PR] cooldown_reject_parry PASS=true | 成功后冷却期 try_parry -> 重复按键幂等拒绝（不给奖励、success_count 仍 1）
[V120-PR] cooldown_then_reopen PASS=true | tick(1.2) 冷却归零后可再次开窗
[V120-PR] within_window_decrement PASS=true | tick(0.1) -> remaining=0.25，未超时
[V120-PR] exact_timeout_close PASS=true | 累计恰好 window_sec -> 超时关窗
[V120-PR] timeout_failed_signal PASS=true | parry_failed(timeout, 10) 恰 1 次
[V120-PR] overlong_delta_timeout PASS=true | tick(999) 一次即超时关窗
[V120-PR] boss_move_landed_fail PASS=true | 招式落地未弹反 -> 失败关窗 + parry_failed(move_landed)
[V120-PR] boss_move_landed_noop_after_success PASS=true | 成功后招式落地 -> 幂等 no-op（不重复惩罚）
[V120-PR] boss_defeated_flag PASS=true | on_boss_defeated -> boss_defeated=true
[V120-PR] boss_defeated_no_window PASS=true | Boss 死亡后 open_window -> boss_defeated 拒绝（不再开窗）
[V120-PR] boss_defeated_no_parry PASS=true | Boss 死亡后 try_parry -> boss_defeated 拒绝
[V120-PR] boss_defeated_idempotent PASS=true | 重复 on_boss_defeated -> 幂等拒绝
[V120-PR] reset_clears_all PASS=true | reset() -> 关窗 / 清死亡 / 清计数 / 清冷却
[V120-PR] invalid_tick_null PASS=true | tick(null) -> invalid_delta 拒绝
[V120-PR] invalid_tick_nan PASS=true | tick(NaN) -> invalid_delta 拒绝
[V120-PR] invalid_tick_inf PASS=true | tick(Inf) -> invalid_delta 拒绝
[V120-PR] no_config_open_reject PASS=true | config=null -> open_window 拒绝 REASON_NO_CONFIG（不崩）
[V120-PR] invalid_table_nan_window PASS=true | window_sec=NaN -> ParryConfig.is_valid()=false
[V120-PR] invalid_then_normal_ok PASS=true | 异常输入拒绝后正常开窗/弹反仍得 points_bonus=50（状态未被污染）
[V120-PR] production_subscriber_in_source PASS=true | wave_trial_director.gd 生产源码含 4 信号 connect + get_parry_service()（A48①/A54）
[V120-PR] SUMMARY pass=58 fail=0
[V120-PR] OVERALL=PASS
[V120-PR] RESULT=ALL_MATCH
[V120-PR] === SELFTEST END ===
verify_parry_v120_EXIT=0
```

`verify_parry_settlement_v120.gd`（共 80 条逐条 `PASS=true` 原文，此处列全量关键行与汇总）：

```
[V120-PS] === SELFTEST START ===
[V120-PS] scene_tree_root_via_main_loop PASS=true | Engine.get_main_loop() as SceneTree -> root
[V120-PS] md5_before_wave_trial.tres_nonempty PASS=true | wave_trial.tres md5(before)=793b6daa7c7730feed1a3f849701d58a
[V120-PS] persist_explicitly_downgraded PASS=true | bind_persistence(null,null) -> persist_available=false（不写生产存档）
[V120-PS] baseline_settled_100 PASS=true | 无弹反 / 0 连击 -> settled=100（D 级 mult=1.0，与既有等价）
[V120-PS] a54_parry_service_present PASS=true | 3 个纯逻辑服务均已装配（A54：唯一实例经 get_*_service() 复用）
[V120-PS] a48_production_subscriber_runtime PASS=true | 生产订阅者实证：波次开窗信号已被 wave_trial_director 接收（A48①，非验证脚本订阅）
[V120-PS] parry_window_open_at_wave_start PASS=true | 波次 / Boss 出招时生产链路已开精准弹反窗口
[V120-PS] try_parry_ok PASS=true | 真实输入入口 try_parry() -> 窗口内成功
[V120-PS] try_parry_reward_payload PASS=true | 奖励 payload=(poise=25.0, points=50, combo_keep=true) [PLACEHOLDER]
[V120-PS] parry_success_recorded PASS=true | 生产订阅者已把 points_bonus/poise_bonus 记入导演层
[V120-PS] parry_points_into_settled_150 PASS=true | 弹反 points_bonus=50 并入清波结算基数：100+50 -> settled=150（D 级 1.0）[PLACEHOLDER]
[V120-PS] parry_points_total_150 PASS=true | points_total=150（弹反奖励已并入既有清波点数结算）
[V120-PS] a57_awarded_source_consistent PASS=true | A57：最终结算值 150 经 points_awarded 发出的取源与导演层一致（唯一最终值）
[V120-PS] no_double_settle_one PASS=true | 本波仅结算 1 次（不二次入账）
[V120-PS] wave_cleared_format_unchanged PASS=true | wave_cleared(index=0, points=100) 仍发基础 pts，既有输出格式/语义未改
[V120-PS] parry_plus_combo_240 PASS=true | 弹反 +50 -> base=150，14 连击 A 级 1.6 -> settled=240（既有单一倍率，不叠乘）
[V120-PS] parry_plus_boon_plus_combo_336 PASS=true | boon +60 -> 160，弹反 +50 -> 210，A 级 1.6 -> settled=336（三机制都并入、不叠乘其它层）
[V120-PS] points_monotonic_increase PASS=true | 清波后 points_total 0 -> 150（只增不减、非负）
[V120-PS] balance_nonneg PASS=true | last_settled_points=150 >= 0（余额非负）
[V120-PS] no_double_settle PASS=true | 重复 on_encounter_finished -> 拒绝（points 不变、settlement_count=1、不二次入账）
[V120-PS] parry_acc_cleared_next_wave PASS=true | 第 2 波波次开始清 parry_points_acc（不把第 1 波奖励带进第 2 波）
[V120-PS] no_repeat_parry_bonus_wave2 PASS=true | 第 2 波无弹反 -> settled=150（第 2 波基础 pts，不含第 1 波弹反 +50，不重复并入）
[V120-PS] legacy_snapshot_keys_all_present PASS=true | get_snapshot() 既有 27 个 key 逐字仍在（只新增 R34/R35 只读 key，不改既有）
[V120-PS] r34_snapshot_keys_intact PASS=true | get_snapshot() R34 新增 8 个 key 逐字仍在（不回退）
[V120-PS] r35_snapshot_keys_present PASS=true | get_snapshot() R35 新增 8 个只读 key 可用
[V120-PS] boss_defeated_parry_flag PASS=true | 最后一波清波 -> ParryService.on_boss_defeated() 已置标志
[V120-PS] boss_defeated_no_window PASS=true | Boss 死亡后 open_window -> boss_defeated 拒绝（不再开窗）
[V120-PS] real_production_director PASS=true | 驱动对象 = 真实生产脚本 wave_trial_director.gd（非验证脚本内自建替身/模拟编排）
[V120-PS] a54_single_instance PASS=true | A54：两次 get_parry_service() 返回同一实例（绝不自建第二个）
[V120-PS] production_subscriber_in_source PASS=true | 生产源码含 4 信号订阅者 + 唯一实例 getter + 弹反奖励并入结算接线（A48①/A57）
[V120-PS] MD5 wave_trial.tres before=793b6daa7c7730feed1a3f849701d58a after=793b6daa7c7730feed1a3f849701d58a
[V120-PS] MD5 boon_draft.tres before=44d8b941f8b28dfa2931984707b5c53e after=44d8b941f8b28dfa2931984707b5c53e
[V120-PS] MD5 trial_modifiers.tres before=7e9e5ac7d35d8d15171e69975ac3356d after=7e9e5ac7d35d8d15171e69975ac3356d
[V120-PS] MD5 stagger_rules.tres before=49ce964e7c268804efbf2f20bec6565d after=49ce964e7c268804efbf2f20bec6565d
[V120-PS] MD5 combo_rules.tres before=a1ad4635ae0342c696fe650eb13d4930 after=a1ad4635ae0342c696fe650eb13d4930
[V120-PS] MD5 player_actions.tres before=75390f71c002ef3cea6392a397ec267c after=75390f71c002ef3cea6392a397ec267c
[V120-PS] MD5 boss_01_margit.tres before=f2f71c7019c64e6c631c553887376c7d after=f2f71c7019c64e6c631c553887376c7d
[V120-PS] MD5 enemy_01_limgrave_soldier.tres before=9de25e0229d1c2c55a1740d2f838ad79 after=9de25e0229d1c2c55a1740d2f838ad79
[V120-PS] MD5 parry_rules.tres before=5d560e57c5c0fdfdec3f20b3f3535728 after=5d560e57c5c0fdfdec3f20b3f3535728
[V120-PS] md5_zero_change_wave_trial.tres PASS=true | wave_trial.tres 前后 md5 一致（零改动）
[V120-PS] md5_zero_change_boon_draft.tres PASS=true | boon_draft.tres 前后 md5 一致（零改动）
[V120-PS] md5_zero_change_trial_modifiers.tres PASS=true | trial_modifiers.tres 前后 md5 一致（零改动）
[V120-PS] md5_zero_change_stagger_rules.tres PASS=true | stagger_rules.tres 前后 md5 一致（零改动）
[V120-PS] md5_zero_change_combo_rules.tres PASS=true | combo_rules.tres 前后 md5 一致（零改动）
[V120-PS] md5_zero_change_player_actions.tres PASS=true | player_actions.tres 前后 md5 一致（零改动）
[V120-PS] md5_zero_change_boss_01_margit.tres PASS=true | boss_01_margit.tres 前后 md5 一致（零改动）
[V120-PS] md5_zero_change_enemy_01_limgrave_soldier.tres PASS=true | enemy_01_limgrave_soldier.tres 前后 md5 一致（零改动）
[V120-PS] md5_zero_change_parry_rules.tres PASS=true | parry_rules.tres 前后 md5 一致（零改动）
[V120-PS] existing_tables_zero_change PASS=true | 8 份既有 .tres 前后 md5 全部一致（零改动）
[V120-PS] SUMMARY pass=80 fail=0
[V120-PS] OVERALL=PASS
[V120-PS] RESULT=ALL_MATCH
[V120-PS] === SELFTEST END ===
verify_parry_settlement_v120_EXIT=0
```

### GATE-3 `--headless --quit`（主场景实证，不加载 `presentation.gd`）

```
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
[WaveTrial] 持久化基线读回：dungeon.wave_trial.best_wave=0 / dungeon.wave_trial.completed=false / grace.trial.points=0（经 WorldState.get_flag）
[R35][WaveTrial] 精准弹反生产订阅者已装配：ParryService 唯一实例 + 4 信号 connect（A48①/A54）
[R35][WaveTrial] 波次开始精准弹反开窗：index=1 window_sec=0.35（生产链路，非验证脚本模拟）
...（既有 HUD / FX / CODEX / SHOP / QUALITY 装配日志，均既有行为）...
GATE3_EXIT=0
```

### 统一统计（`grep SCRIPT ERROR=0`）

```
########## FINAL GATE STAT ##########
SCRIPT_ERROR_LINES=0
GATE1_EXIT=0 / 5×GATE-2a EXIT=0 / 2×GATE-2b EXIT=0 / GATE3_EXIT=0
[V120-PR] SUMMARY pass=58 fail=0   OVERALL=PASS   RESULT=ALL_MATCH
[V120-PS] SUMMARY pass=80 fail=0   OVERALL=PASS   RESULT=ALL_MATCH
```

**PASS/FAIL 汇总**：`58 + 80 = 138 PASS / 0 FAIL`，两份 `RESULT=ALL_MATCH`，`SCRIPT ERROR=0`。

### 4.4 如实登记：并发中间态（不冒充全绿、不谎报）

- 本轮为多 Rank 并行轮次。GATE-3 主场景在 **Rank-1 并行写入 `hud.gd` / `encounter_director.gd` 的 R35 半成品中间态** 期间，曾间歇出现 `SCRIPT ERROR: Parse Error`（观测到 46 条归属 `res://scripts/hud.gd`、4 条归属 `res://scripts/combat/encounter_director.gd`，均为 `_r35_*` / `bind_parry_service()` / `get_parry_hud_view()` 等 Rank-1 自有成员尚未定义），并伴随 `ERROR: Failed to load script "res://scripts/combat/encounter_director.gd" with error "Parse error"`。
- 归属核验：`at:` 行全部指向上述两个 **Rank-1 唯一写入方文件**，无一条指向 Rank-2 本轮 5 个文件；Rank-2 的 GATE-1 / GATE-2a / GATE-2b 三段在全过程恒为 `SCRIPT ERROR=0`；GATE-3 中 Rank-2 的 `[R35][WaveTrial] 精准弹反生产订阅者已装配` / 开窗日志始终正常打印。
- Rank-1 写入完成后的**最终统一三段门禁**（本文 §4 统一统计）`SCRIPT_ERROR_LINES=0`、四段 `EXIT=0`；中间态另有单独一次复核 `G3_SCRIPT_ERROR_TOTAL=0` / `node_count=41`。
- 按硬约束 Rank-2 对 `hud.gd` / `encounter_director.gd` **只读不改**、未越界修复；如实登记，不自行 git、不伪造产物。
- `--script` / `--headless` 工具模式尾部另有既有 autoload 告警（`[SaveSystem] --script 工具模式…跳过自动读回`、`[ChunkManager] 未找到 ChunkRoot…`、`[PCO] HUD 未就绪…绑定降级`、`2 ObjectDB instances were leaked at exit`）：均为 `WARNING`、**非 `SCRIPT ERROR`、非本轮引入、不影响断言与门禁（EXIT=0）**，如实登记。

**md5 零改动结论（既有表）**：`wave_trial.tres 793b6daa…` / `boon_draft.tres 44d8b941…` / `trial_modifiers.tres 7e9e5ac7…` / `stagger_rules.tres 49ce964e…` / `combo_rules.tres a1ad4635…` / `player_actions.tres 75390f71…` / `boss_01_margit.tres f2f71c70…` / `enemy_01_limgrave_soldier.tres 9de25e02…` **8 份前后完全一致**（完整值见上），本轮只新增 `parry_rules.tres`（`5d560e57…`，验证脚本同样未写入），**既有 `.tres` 数值零改动**。

---

## 5. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 机制 ① 3 个新文件 + 完善功能 ② `wave_trial_director.gd` 最小接线 + 2 个 verify + DONE + 回执落地；② 三段门禁 GATE-1 / 2a / 2b / 3 全 `EXIT=0`、最终统一 `SCRIPT ERROR=0`（Rank-2 三段全过程恒为 0）；③ 两份自测 `RESULT=ALL_MATCH`（58 + 80 = 138 PASS / 0 FAIL）；④ 8 份既有 `.tres` md5 前后一致（零改动），只新增 `parry_rules.tres`；⑤ `courtyard.tscn` 零改动，GATE-3 实证 `node_count=41`（uv `2/1/1` 因零改动保持）；⑥ A48① 4 信号**生产订阅者** = `wave_trial_director._bind_parry_signals()`（生产节点）+ 运行时实证 `parry_window_opened_count=1` + GATE-3 装配日志；⑦ A54 唯一实例：`get_parry_service()` 两次返回同一实例、Rank-1 `hud.gd` 经 `wave.get_parry_service()` 复用（鸭子类型候选命中）；⑧ A57 结算闭合：弹反奖励并入唯一最终结算值、`points_awarded` 取源一致、不二次入账、输出格式零改动；⑨ 纯逻辑边界（I-1 不读写存档 / 不碰渲染 / 不写生产 `delta.json`）——验证脚本显式 `bind_persistence(null,null)` 降级；⑩ 点数只增不减 / 余额非负 / 不重复结算 / 每波累计清零机器判定；⑪ 回执已中枢归档（§10） |
| **失败** | 无（Rank-2 自有交付无失败项）。如实另记：GATE-3 在 Rank-1 并行写入中间态曾间歇出现 `SCRIPT ERROR: Parse Error`（归属 Rank-1 文件，非本轮引入；最终统一门禁 `SCRIPT ERROR=0`），见 §4.4 / §7 第 5 条 |
| **需用户确认** | ① 全部 `[PLACEHOLDER]` 数值待人工试玩校准（只改表）；② Rank-1 运行时接线（`encounter_director.gd` / `hud.gd` 本轮并行写入、只读边界）；③ Rank-3 点数落盘与 `points_awarded` 订阅口径（A55/A57）；④ `window_id`（A58）/ `combo_keep` / `fail_penalty` 三处接口差异与实际作用（§7）；⑤ headless 真跑无渲染画面，未做 15~20 秒实机录屏回看；⑥ A48③ 完整「真实输入→磁盘/画面」断言脚本 `verify_parry_runtime_v120.gd` 归 Rank-1（目录所有权），待其收尾后复跑 GATE-3 取最终全绿 |

---

## 6. 未完成项 / 阻塞

- **Rank-1 运行时接线未由 Rank-2 落地（授权边界，非缺陷）**：`encounter_director.gd` / `hud.gd` / `presentation.gd` 本轮唯一写入方 Rank-1，Rank-2 只读。Boss 每次出招前摇 `open_window()` / 玩家弹反键 `try_parry()` / 招式落地 `on_boss_move_landed()` 的**运行时驱动由 Rank-1 完成**；本轮 Rank-2 已提供稳定签名（§3）+ 3 个驱动口 + 生产订阅者 + 每帧 `tick(delta)` 转发。接线前导演层只在波次开始开窗，弹反奖励恒 0（清波点数与既有等价，安全降级，正是「不改既有判定分支 / 输出格式」的保证）。
- **`window_id`（A58）服务侧未提供**：Rank-1 `hud.gd` 的 `R35_KEY_WID=["window_id","parry_window_id"]` 在 `ParryService.get_snapshot()` 中不存在，Rank-1 已用 `_r35_make_window_id()` 本地生成兜底（不崩）；是否由服务侧补 `window_id` 待裁决（§7 第 2 条）。
- **`combo_keep` 未联动既有 ComboService**：本轮只作为 `parry_succeeded` payload / 导演层记录（`parry_last_combo_keep`），不擅自改既有连击判定（避免破坏 A57 settle 口径）；是否联动待裁决（§7 第 3 条）。
- **`fail_penalty` 未真正生效**：本轮只作 `parry_failed` payload / 记录，不扣减既有点数（守住只增不减）；是否真正扣点 / 扣削韧待裁决（§7 第 4 条）。
- **poise_bonus 并入既有削韧的降级口径**：真实主场景经 `_encounter.get_stagger_service().apply_hit()` 生效；`--script` / 依赖缺失时只记录到 `parry_poise_acc`、不崩；StaggerService 窗口期幂等拒绝是否影响弹反削韧待裁决（§7 第 7 条）。
- **实机录屏目视**（公共契约要求 15~20 秒回看）：本轮交付为纯逻辑 + 数据表 + 最小接线 + headless 真跑，无渲染帧缓冲，未录屏；不伪造、列为后续 / 需用户确认。
- 无阻塞；所有硬约束内工作已完成。

---

## 7. 待总指挥裁决项（只登记、不擅改）

1. **数值校准**：`window_sec=0.35` / `cooldown_sec=1.2` / `poise_bonus=25.0` / `points_bonus=50` / `combo_keep=true` / `fail_penalty=10` 全部 `[PLACEHOLDER]`，待人工试玩校准；调参唯一入口 `godot/data/combat/parry_rules.tres`，同步 `verify_parry_v120.gd` 的 `EXPECT_*` 与本文数值表。
2. **`window_id`（A58）归属**：Rank-1 `hud.gd` 期望服务快照含 `window_id` / `parry_window_id`；本轮 `ParryService.get_snapshot()` 无此 key，Rank-1 已本地生成唯一 id 兜底。请裁决：是否由服务侧补「开窗即生成 `window_id`」并随 `parry_window_opened` / `parry_performed` 带出，或维持 Rank-1 本地生成（本轮按后者不擅改）。
3. **`combo_keep` 与 ComboService 联动**：true=保留连击、false=断连；本轮只广播 / 记录，不联动既有 `register_hit` / `on_hit_taken`（不改 A57 settle 取源）。请裁决是否由 Rank-1 在弹反成功时按该值调 ComboService，及归属。
4. **`fail_penalty` 是否真正生效**：本轮只作记录 / Rank-4 反馈，不扣既有点数（守住只增不减）。请裁决是否需要真正扣点 / 扣削韧，及落盘口径（Rank-3 I-1）。
5. **Rank-1 并行写入与 GATE-3 最终复跑**：本轮 GATE-3 观测到 Rank-1 `hud.gd` / `encounter_director.gd` 半成品中间态 Parse Error（§4.4），最终统一门禁已 `SCRIPT ERROR=0`；请裁决 Rank-1 收尾后由总指挥统一复跑三段门禁取最终全绿，并明确 `parry_performed`（HUD 自有信号，A48① 订阅者 EncounterDirector）与本轮 `parry_succeeded`（服务信号，订阅者 wave_trial_director）的职责分工 / 是否重复入账。
6. **Boss 出招开窗节拍**：本轮只在 `_enter_telegraph()`（波次开始）开窗，并暴露 `on_boss_move_telegraph()` 供 Rank-1 每次 Boss 出招前摇调用；每帧 `tick(delta)` 已由 `wave_trial_director._process()` 转发。请裁决是否每次前摇都开窗、以及 `cooldown_sec` 在多招式连段下的节拍。
7. **poise_bonus 并入既有削韧的落点**：真实主场景经 `encounter_director.get_stagger_service().apply_hit(poise_bonus)` 生效；StaggerService 在处决窗口开启期间对 `apply_hit` 幂等拒绝（`REASON_WINDOW_OPEN`），可能影响弹反削韧入账。请裁决是否需独立削韧通道 / 由 Rank-1 调整调用顺序。
8. **A48③ 完整真实可达回归**：`verify_parry_runtime_v120.gd` 归 Rank-1（目录所有权），Rank-2 不越界写；本轮提供 GATE-3 主场景实证（不加载 `presentation.gd`、真实 autoload）+ 两份 verify 驱动真实生产脚本（非替身 / 不模拟编排）+ 生产订阅者 / 唯一实例 / 结算闭合接口。请裁决 Rank-1 收尾后「真实输入 → 生产链路 → 磁盘 / 画面」全链断言的复跑与口径。
9. **实机录屏回看 / 既有 autoload 3 条 WARNING**：headless 真跑无帧缓冲，按公共契约如实登记为后续动作 / 需用户确认（不冒充目视通过）；既有 WARNING 非本轮引入，是否纳入后续清理由总指挥裁决。

---

## 8. 设计漏洞主动识别（P0 / P1 / P2）

| 级别 | 漏洞 | 缓解 / 现状 |
|---|---|---|
| **P0** | 无 | 纯逻辑层覆盖幂等 / 非负 / 异常 / 存档越权 / Boss 死亡 / 超时 / 重复结算 / 冷却，自测机器判定 |
| **P1** | `tick(delta)` 依赖外部每帧调用；导演层若漏接，窗口永不超时 | 本轮已由 `wave_trial_director._process()` 转发（不改既有分支）；§3.2 接线示意显式强调，与 R32 `StaggerService.tick` / R34 `ComboService.tick` 同款约束 |
| **P1** | 弹反输入未接时奖励恒 0 → 机制运行时「不可见」 | 本轮安全降级（清波点数与既有等价）；Rank-1 接线后才产生 >0 奖励，已登记为未完成项 |
| **P1** | 多 Rank 并行写入中间态使 GATE-3 短暂不绿 | 归属核验（全在 Rank-1 文件）+ 最终统一门禁 `SCRIPT ERROR=0`；如实登记 §4.4 / 裁决项 5，不越界改他人文件 |
| **P2** | `window_id` 缺失 / `combo_keep` / `fail_penalty` 未真正作用 | Rank-1 本地兜底 / 只作记录；列为裁决项 2/3/4 |
| **P2** | 全部 `[PLACEHOLDER]` 未经手感校准 | 调参唯一入口 + 校准同步清单，待人工试玩 |
| **P2** | `poise_bonus` 经既有 StaggerService 可能遇窗口期幂等拒绝 | 生产订阅者只在 `apply_hit` 返回 ok 时计入 `parry_poise_applied`；裁决项 7 |

---

## 9. A48 硬要求落地声明（逐条）

| A48 | 落地 | 证据 |
|---|---|---|
| ① 新信号必须有**生产运行时订阅者**（不能只在验证脚本） | `wave_trial_director.gd`（挂 `courtyard.tscn` 的生产节点）在 `_init_combat_services()` 装配时调 `_bind_parry_signals()`，connect 全部 4 信号到 `_on_parry_*` 生产回调 | `production_subscriber_in_source` / `a48_production_subscriber_runtime`（`parry_window_opened_count=1`）/ GATE-3 `[R35][WaveTrial] 精准弹反生产订阅者已装配`；`_on_parry_succeeded` 把奖励并入结算（生产职责，非空订阅） |
| ② 遵守 A54 唯一实例（从既有导演层 `get_*_service()` 复用） | `_parry` 唯一实例由 `wave_trial_director.gd` 装配，`get_parry_service()` 暴露；Rank-1 `hud.gd` 经 `wave.get_parry_service()` → `bind_parry_service()` 复用，绝不 new 第二个 | `a54_single_instance`（两次 getter 同一实例）/ `a54_parry_service_present` / GATE-3 装配日志 / §3.6 回读 hud.gd 对齐 |
| ③ 一条**不加载 `presentation.gd`、不在验证脚本内模拟编排**的真实可达回归 | GATE-3 `--headless --quit` 主场景真跑（真实 autoload `PointsCommitOrchestrator`、不加载 `presentation.gd`）实证生产链路；两份 verify 驱动的是**真实生产脚本** `wave_trial_director.gd`（`real_production_director`），结算值经真实 `_clear_wave()` 产出，不在验证脚本内自建替身 / 模拟编排 | GATE-3 R35 开窗 / 装配日志 + `node_count=41`；`real_production_director` / `production_subscriber_in_source`；完整「真实输入→磁盘/画面」断言脚本 `verify_parry_runtime_v120.gd` 归 Rank-1（目录所有权），见 §6 / 裁决项 8（如实登记，不冒充） |
| ④ 纯逻辑 + 单元断言不算可玩交付 | 本轮交付纯逻辑 + 数据表 + 最小接线 + headless 真跑；**未做 15~20 秒实机录屏回看**，如实列为未完成 / 需用户确认，不冒充可玩交付 | §5 需用户确认 / §6 未完成项 |

---

## 10. 硬约束遵守声明

- `encounter_director.gd` / `hud.gd` / `presentation.gd` / `points_commit_orchestrator.gd` / `project.godot` / `courtyard.tscn` / 场景 / 素材 / 其它 Rank 文件**只读未改**；`courtyard.tscn` 节点数 `41` / uv `2/1/1` 未破坏（GATE-3 实证）。
- 既有 `.tres` 数值零改动（8 份 md5 前后一致），只新增 `parry_rules.tres` 一张新表。
- 纯逻辑（I-1）：`ParryService`（RefCounted）/ `ParryConfig`（Resource）均不 `add_child` / 不 `get_tree()` / 不 `/root/...` / 不 `open(user://)` / 不 `set_flag` / 不 `commit` / 不碰渲染 / 不写生产存档；`wave_trial_director.gd` 接线只在 `_enter_telegraph()` / `_clear_wave()` / 生产订阅回调三处消费数据、不写盘；验证脚本显式 `bind_persistence(null,null)` 降级，全程不触碰 `user://slot_01/delta.json`。
- Godot4 自测纪律：`extends SceneTree` 用 `Engine.get_main_loop() as SceneTree` 取 root（只读断言），`add_child` 后显式 `call("_ready")`（不依赖自动 flush），资源回读 `CACHE_MODE_IGNORE`；不用 `get_tree()`、不用 `/root/...` 绝对路径。
- 零付费、零外部依赖、不启 GPU job；不伪造产物、不谎报成功、不自行 git；未删除 `.workbuddy`。
- 默认不刺探：未扫目录做进度巡检、未写只读探针 / 巡检脚本；仅按任务单要求读必做文件、核对回执目录与中枢归档结构。

---

## 11. 回执与中枢归档确认（写后已确认）

- 回执写入 Rank-2 授权路径（**`teamwork/command_center/`，非工程根**）：
  `teamwork/command_center/ai/2/outbox/cmd-20261112-125821-139-A2.json`，
  四字段 `{"task_id", "ai":2, "status":"done", "result"}`。
- 中枢已归档（写后回读确认，如实登记、不伪造）：
  - 归档副本：`teamwork/command_center/dispatcher/receipts/cmd-20261112-125821-139-A2.json`，回读 **VALID_JSON**，`task_id` / `ai=2` / `status=done` / `result` 四字段齐全且与 outbox 回执逐字一致。
  - `teamwork/command_center/ai/2/status.json` 更新为 `{"ai":2,"state":"idle","current_task":"","completed":43,"last_seen":"2026-11-12 13:21:40"}`（`completed` 由 42 → 43、`current_task` 清空）。
  - `ai/2/outbox/` 按中枢流程归档后已清空（回执移入 `dispatcher/receipts/`）；Glob 复查 `*cmd-20261112-125821-139-A2*` 仅命中 `ai/2/inbox/任务单` 与 `dispatcher/receipts/归档副本`，属中枢正常处理；不重放、不伪造。
  - `dispatcher/ledger.jsonl` 第 144 行为本任务单 `cmd-20261112-125821-139-A2` 派单登记（同批 143 = Rank-1、145 = Rank-3），确认 id 与派单一致；由同批 ledger 亦可确认 `verify_parry_runtime_v120.gd`（A48③ 完整真实可达回归）与 A58 `window_id` 归 Rank-1、A59/A60 归 Rank-3，与本文 §6 / §7 的分工登记一致。
  - 注：本轮中枢归档日志载体为 `dispatcher/ledger.jsonl`（非 `dispatcher.log`），如实登记，不臆造日志文件名。
