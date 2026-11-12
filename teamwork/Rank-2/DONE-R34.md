# DONE-R34.md · R34 / v0.11.0「玩法闭合 · 连击评价」交付报告（Rank-2）

> 轮次：`R34 / v0.11.0` ｜ 任务单 id：`cmd-20261112-091304-451-A2` ｜ 执行 AI：`2（Rank-2 战斗系统与数据驱动）`
> 真源：`teamwork/Rank-2/调度任务单-latest.json`（`task` 全文 + 公共契约 + 目录所有权）+ `teamwork/00-协作契约.md` + `teamwork/Rank-2/DONE-R32.md`（既有服务接口）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> 结论：**三段门禁全绿、`SCRIPT ERROR=0`、两份自测 `RESULT=ALL_MATCH`（169 PASS / 0 FAIL）、既有 4 份 `.tres` md5 零改动、`courtyard.tscn node_count=41` 保持、回执已中枢归档**。

---

## 1. 交付清单（实际落地文件）

### 机制 ① · 连击评价 Combo Rank（新增 3 件，均归 Rank-2）

| 文件 | 类型 | 作用 |
|---|---|---|
| `godot/data/rpg/combo_rules.tres` | 新增数据表 | `rank_thresholds / multiplier / timeout_sec / reset_on_hit_taken` 四个 `[PLACEHOLDER]` 字段，数值真源 |
| `godot/scripts/combat/combo_config.gd` | 新增 Resource（`class_name ComboConfig`，`extends Resource`） | 表结构 / 5 档白名单 / `is_valid()` 纯函数 / 降级基线 / 逐项 rationale / 调参唯一入口 |
| `godot/scripts/combat/combo_service.gd` | 新增 RefCounted（`class_name ComboService`）纯逻辑 | 连击累积 / D→C→B→A→S 评级 / 倍率结算 / 受击·超时重置 / Boss 死亡结算 / 异常拒绝 + **4 个公开信号** |

### 完善功能 ② · 抉择消费方接线（修改 1 件，本轮唯一写入方 = Rank-2）

| 文件 | 改动 | 边界 |
|---|---|---|
| `godot/scripts/combat/wave_trial_director.gd` | 8 处精确 Edit：新增 2 个表路径常量 / 11 个记录字段 / `_ready()` 装配 2 个服务 / `start_trial()` 清零记录 / `_enter_telegraph()` 波次开始消费 `cost_key`·`effect_key` / `_clear_wave()` 消费 `BoonDraftService.apply()`·`settle()` 并把 ComboService 倍率并入结算 / 新增 5 个公开·辅助方法 / `get_snapshot()` 追加 8 个只读 key | **既有判定分支 / 帧数据 / 输出格式（`wave_cleared(index,pts)` 签名与值、`_refresh_hud()` 文本、`get_snapshot()` 既有 27 个 key）/ 既有 `.tres` 数值一律逐字未动**；点数只增不减、余额非负、不重复结算 |

### 自测脚本（新增 2 件，均在 `godot/scripts/combat/`）

| 文件 | 作用 | 结果 |
|---|---|---|
| `verify_combo_v110.gd` | 机制 ① 正常 / 边界 / 异常三类输入：0 连击、超长间隔、恰好超时、受击重置、门槛边界、同帧多次、负数伤害、null、0、字符串、NaN/Inf、config=null、重复结算、Boss 死亡结算、4 信号订阅与 payload | `pass=110 fail=0 RESULT=ALL_MATCH` |
| `verify_production_settlement_v110.gd` | 抉择代价生效 + 连击倍率 + 两者组合 + 点数单调 + 不重复结算 + 既有输出格式零改动 + md5 前后对比证明既有表零改动 | `pass=59 fail=0 RESULT=ALL_MATCH` |

### 文档 / 回执（新增 2 件）

| 文件 | 作用 |
|---|---|
| `teamwork/Rank-2/DONE-R34.md` | 本交付报告（交付清单 / 真跑输出原文 / 验收三态 / 公开方法与信号完整签名 / 未完成项 / 待裁决项） |
| `teamwork/command_center/ai/2/outbox/cmd-20261112-091304-451-A2.json` | 本轮回执，中枢已归档至 `dispatcher/receipts/` |

### 只读未改（硬约束）

`godot/scripts/combat/encounter_director.gd`、`godot/scripts/hud.gd`、`godot/test/presentation.gd`（三者本轮唯一写入方 Rank-1）、
`godot/scenes/courtyard.tscn`、场景 / 素材 / 其它 Rank 文件、既有 `.tres`
（`wave_trial.tres` / `boon_draft.tres` / `trial_modifiers.tres` / `stagger_rules.tres`）、`teamwork/00-协作契约.md`（不私改）。

---

## 2. 玩法拆解表（需求 → 机制 → 数值 → 状态 → 验收）

### 机制 ① · 连击评价

| 需求 | 机制 | 数值（`[PLACEHOLDER]` 首版） | 状态（实例内、不持久化） | 验收 |
|---|---|---|---|---|
| 连续命中不中断累积 combo | `register_hit(damage)` 每次 +1、刷新「距上次命中」计时 | — | `_combo` | `rank_at_1_D` / `rank_at_22_S` / `same_frame_hits_accumulate` |
| 按门槛评级 D/C/B/A/S | 遍历低→高门槛取最高达成档 | `D:0 C:4 B:8 A:14 S:22` | `_rank` | `threshold_*_ph` / 5 个门槛边界断言 |
| 评级影响赐福点数结算倍率 | `settle(base)` → `round(base × multiplier[D/C/B/A/S])` | `1.0 / 1.15 / 1.35 / 1.6 / 2.0` | `_settled` / `_last_settlement` | `settle_zero_combo_D_100` / `settle_A_160` / `settle_S_200` |
| 超时重置 | `tick(delta)` 确定性推进，`≥timeout_sec` 归零 | `2.5` | `_elapsed` | `bnd_overlong_interval_timeout` / `bnd_exact_timeout` / `bnd_within_timeout_decrement` |
| 受击重置 | `on_hit_taken()`，`reset_on_hit_taken=true` 时归零 | `true` | — | `bnd_hit_taken_reset` / `bnd_reset_disabled_no_reset` |
| Boss 死亡结算 | `on_boss_defeated()` 定格评级、此后拒绝命中，`settle()` 做一次结算 | — | `_boss_defeated` | `boss_defeated_settle_ok` / `boss_defeated_service_flag` |
| 重复 / 负数 / null 输入拒绝 | 重复 `settle` / `on_boss_defeated` 幂等；负数·null·0·字符串·NaN/Inf 全拒绝且不改状态 | — | — | `duplicate_settle_rejected` / `invalid_*` 组（约 25 条） |
| 余额非负 / 只增不减 | `balance=max(0,total)`、`bonus=max(0,total-base)`、倍率恒 `>0`、D 级 `1.0` | — | — | `balance_all_nonneg` / `duplicate_settle_no_points` |

### 完善功能 ② · 抉择消费方接线

| 需求 | 落地位置 | 效果 | 验收 |
|---|---|---|---|
| 真实 `wave_cleared` 消费 `apply()` / `settle()` 的 `cost_key` / `effect_key` | `_clear_wave()`：`has_selection()` 时调 `apply()` + `settle(pts)`，取 `total_points` 作结算基数，`cost_key/effect_key/cost_value` 挂起到 `_pending_*`，随后 `_boon.reset()` | 抉择点数加成并入结算、代价待「下一波」生效 | `boon_points_bonus_160` / `boon_consumed_and_reset` |
| 波次开始消费 `cost_key` / `effect_key` | `_enter_telegraph()` → `_consume_pending_boon()`：把 `_pending_*` 转 `_active_*`（可读快照），并 `combo.reset()` 让连击从本波重算 | 抉择代价作用到下一波 | `boon_cost_key_active_next_wave`（`hp_scale`）/ `boon_effect_key_active_next_wave`（`points_bonus`）/ `boon_cost_value_1_20` |
| ComboService 评级倍率并入清波点数结算 | `_clear_wave()`：末波先 `on_boss_defeated()`，再 `settle(base_for_combo)`，`settled_points` 用于 `new_points`（落盘）与 `_points_total += settled_points` | 14 连击 A 级 → `100×1.6=160`；boon +60 且 A 级 → `256` | `combo_mult_settled_160` / `combo_plus_boon_256` / `boss_defeated_settle_S_200` |
| 点数只增不减 / 余额非负 / 不重复结算 | `settled_points` 恒 `>=0`、`_persist_settle` 既有 `max` 保护、既有 `WAVE_ACTIVE` 门控拒绝重复 `on_encounter_finished`、`settle` 幂等 | — | `points_monotonic_increase` / `balance_nonneg` / `no_double_settle` / `monotonic_after_duplicate` |
| 既有输出格式零改动 | `wave_cleared.emit(_index, pts)` 第二参数仍为基础 `pts`；`get_snapshot()` 既有 27 个 key 逐字不动，只追加 8 个只读 key | — | `wave_cleared_format_unchanged` / `legacy_snapshot_keys_all_present` |

### 数值拆解 / rationale（完整版见 `combo_config.gd` 头注）

- **调参唯一入口（只改表不改代码）**：`godot/data/rpg/combo_rules.tres`。代码内 `ComboConfig.DEFAULT_*` 是**非法降级基线**（刻意 `!=` 表值，`verify_combo_v110.gd` 的 `default_is_not_design_*` 机器判定），不是设计数值。校准同步清单：`.tres` → `verify_combo_v110.gd` 的 `EXPECT_*` → 本文数值表 → 三段门禁；不静默改数。
- `rank_thresholds {D:0 C:4 B:8 A:14 S:22}` `[PLACEHOLDER]`：D=0 保证 0 连击不惩罚、结算不低于基础点数；C=4「一小段无伤连打」、B=8、A=14、S=22 逐级拉开，S 取「一波 30s 内近乎全程不被打断」量级，避免两三下就 S 使评级失去区分度。
- `multiplier {D:1.0 C:1.15 B:1.35 A:1.6 S:2.0}` `[PLACEHOLDER]`：D=1.0 不额外奖励；逐级 +0.15/+0.20/+0.25/+0.40，S 封顶 2.0（翻倍）而非继续放大，防高评级把赐福点数通胀到破坏 R27 成长出口节奏；单调递增且**绝不叠乘其它倍率**（导演层清波只取 ComboService 一个倍率，沿用 R31「取单一倍率、防通胀」口径）。
- `timeout_sec = 2.5` `[PLACEHOLDER]`：两次命中间隔 >2.5s 判连击中断；与 R32 处决窗口 3.0s 同量级、略短以强调「连续」；纯逻辑不读真实时钟、由导演层每帧 `tick(delta)` 推进。
- `reset_on_hit_taken = true` `[PLACEHOLDER]`：受击立即中断连击，把「贪刀」与「保连击」做成取舍；置 `false` 可作「宽松连击」对照档（`bnd_reset_disabled_no_reset` 已验证）。

---

## 3. 供 Rank-1 与 Rank-4 使用的公开方法与信号完整签名（本轮重点）

> `ComboService` 是 `RefCounted` 纯逻辑，**信号是 Object 级能力**：Rank-1 / Rank-4 直接 `connect` 到本服务实例即可，
> 无需场景树、无需 `add_child`、无需 `/root/...`。以下签名**稳定、不再改动**。

### 3.1 公开信号（`godot/scripts/combat/combo_service.gd`）

```
signal combo_changed(count: int, rank: String)
    # combo 数变化时发（命中累积 / 重置）；count=当前连击数，rank=当前评级。
    # 供 Rank-1 HUD 连击数、Rank-4 连击条 / 评级色。
signal rank_changed(from_rank: String, to_rank: String, multiplier: float)
    # 评级跨 D/C/B/A/S 档时发（升档与降档都发）；to_rank=新档，multiplier=新档倍率。
    # 供 Rank-4 评级跨档演出（升档闪光 / 降档收光）与倍率角标。
signal combo_reset(reason: String)
    # combo 归零时发；reason 取 §3.4 的 RESET_* 常量之一。
    # 供 Rank-4 收起连击特效 / 断连提示。
signal combo_settled(total_points: int, base_points: int, rank: String, multiplier: float)
    # 结算（清波 / Boss 死亡）完成时发；total=倍率后点数、base=基础点数、rank=定格评级。
    # 供 Rank-1 接线到点数结算层 / Rank-4 结算演出（点数从 base 滚到 total）。
```

### 3.2 公开方法（全静态类型）

```
class_name ComboService (extends RefCounted)
_init(config: ComboConfig = null)                 # 构造注入规则表，自动 reset()
set_config(config: ComboConfig) -> void           # 替换表并 reset()（含 null 降级验证）
get_config() -> ComboConfig
reset() -> void                                  # 归零 combo / 评级回 D / 清计时·死亡·结算标志（每波·每场 Boss 战开始调用）

register_hit(damage: Variant) -> Dictionary       # 玩家命中：combo+1、刷新计时、重算评级；异常拒绝
on_hit_taken() -> Dictionary                      # 玩家受击：按 reset_on_hit_taken 归零连击或 no-op
tick(delta_sec: Variant) -> Dictionary            # 每帧推进连击计时；>= timeout_sec 超时归零；异常拒绝
on_boss_defeated() -> Dictionary                  # Boss 死亡：置标志·定格评级；此后拒绝命中·不再超时；幂等
settle(base_points: Variant) -> Dictionary        # 按当前评级倍率结算赐福点数；幂等；异常拒绝

get_combo() -> int                               # 当前连击数
get_rank() -> String                             # 当前评级（"D"/"C"/"B"/"A"/"S"）
get_multiplier() -> float                        # 当前评级倍率（D=1.0 ... S=2.0 [PLACEHOLDER]）
get_elapsed_since_hit() -> float                 # 距上次命中的累计秒数（HUD 连击计时条）
get_timeout_sec() -> float                       # 当前表 timeout_sec
get_reset_on_hit_taken() -> bool                 # 当前表 reset_on_hit_taken
is_boss_defeated() -> bool
is_settled() -> bool
get_last_settlement() -> Dictionary              # 最近一次成功结算结果（Dictionary 副本）
get_snapshot() -> Dictionary                     # 全状态快照（见 §3.3）
```

### 3.3 返回 Dictionary 字段（供 Rank-1 / Rank-4 消费）

```
register_hit      : {ok, reason, damage, combo, rank, multiplier, rank_up}
on_hit_taken      : {ok, reason, reset, combo, rank}
tick              : {ok, reason, delta_sec, combo, rank, elapsed_since_hit, timed_out}
on_boss_defeated  : {ok, reason, combo, rank, multiplier, boss_defeated}
settle            : {ok, reason, base_points, total_points, bonus_points, balance,
                     rank, multiplier, combo, settled}
get_snapshot      : {combo, rank, multiplier, elapsed_since_hit, timeout_sec,
                     reset_on_hit_taken, boss_defeated, settled, config_present,
                     last_settlement}
```

成功结算恒 `total_points = round(base_points × multiplier)`、`balance = max(0,total) >= 0`、
`bonus_points = max(0,total-base) >= 0`；拒绝时 `total_points=bonus_points=balance=0`、不改状态。

### 3.4 公开常量（reason 取值，签名稳定）

```
combo_reset(reason):
    RESET_HIT_TAKEN     = "hit_taken"        # 受击中断
    RESET_TIMEOUT       = "timeout"          # 超时中断
    RESET_BOSS_DEFEATED = "boss_defeated"    # Boss 死亡定格
    RESET_MANUAL        = "manual"           # reset() / 新一局

方法 reason:
    REASON_OK                = "ok"
    REASON_NO_CONFIG         = "no_config"
    REASON_INVALID_HIT       = "invalid_hit"        # 负数 / 0 / null / 字符串 / NaN / Inf 伤害
    REASON_INVALID_POINTS    = "invalid_points"     # 负数 / null / 非数值 base_points
    REASON_INVALID_DELTA     = "invalid_delta"      # 负数 / null / 非数值 delta
    REASON_BOSS_DEFEATED     = "boss_defeated"      # Boss 死亡后命中
    REASON_ALREADY_DEFEATED  = "already_defeated"   # 重复 on_boss_defeated
    REASON_ALREADY_SETTLED   = "already_settled"    # 重复 / 同帧多次 settle
    REASON_RESET_DISABLED    = "reset_disabled"     # reset_on_hit_taken=false 时受击 no-op
```

### 3.5 `ComboConfig` 公开接口（`extends Resource` / `class_name ComboConfig`）

```
const RANK_ORDER: PackedStringArray = ["D", "C", "B", "A", "S"]
@export var rank_thresholds: Dictionary      # rank -> 最小 combo 数（表值 [PLACEHOLDER]）
@export var multiplier: Dictionary           # rank -> 点数结算倍率（表值 [PLACEHOLDER]）
@export var timeout_sec: float               # 连击中断间隔（表值 [PLACEHOLDER]）
@export var reset_on_hit_taken: bool        # 受击是否中断（表值 [PLACEHOLDER]）
is_valid() -> bool                           # 5 档齐全 / 门槛严格递增且 D=0 / 倍率非递减且 >0 / timeout>0
get_rank_for_combo(combo: int) -> String
get_threshold_for_rank(rank: String) -> int
get_multiplier_for_rank(rank: String) -> float
rank_count() -> int
get_ranks() -> PackedStringArray
# 降级基线（不是设计数值）：DEFAULT_RANK_THRESHOLDS / DEFAULT_MULTIPLIER /
#   DEFAULT_TIMEOUT_SEC / DEFAULT_RESET_ON_HIT_TAKEN
```

### 3.6 Rank-1 接线示意（伪代码，供 `encounter_director.gd` / HUD / 输入层）

```gdscript
# 装配（规则表从 res://data/rpg/combo_rules.tres 读，CACHE_MODE_IGNORE 回读真值）
var combo := ComboService.new(
    ResourceLoader.load("res://data/rpg/combo_rules.tres", "",
                        ResourceLoader.CACHE_MODE_IGNORE) as ComboConfig)
combo.connect("combo_changed",  Callable(self, "_on_combo_changed"))    # HUD 连击数
combo.connect("rank_changed",   Callable(self, "_on_rank_changed"))     # 评级 / 倍率角标
combo.connect("combo_reset",   Callable(self, "_on_combo_reset"))      # 收起提示
combo.connect("combo_settled", Callable(self, "_on_combo_settled"))    # 结算演出

func _on_player_hit_landed(damage: float) -> void:
    combo.register_hit(damage)          # 连续命中累积 combo、跨档自动 emit rank_changed
func _on_player_hit_taken() -> void:
    combo.on_hit_taken()                # 受击中断（按 reset_on_hit_taken）
func _process(delta: float) -> void:
    combo.tick(delta)                   # ★ 每帧必须调用，否则连击永不超时（纯逻辑不读真实时钟）
func _on_boss_defeated() -> void:
    combo.on_boss_defeated()            # 定格评级，此后拒绝命中
# 清波 / 结算（本轮已由 wave_trial_director.gd 的 _clear_wave() 最小接线落地）：
var r: Dictionary = combo.settle(base_points)
# r["total_points"] 并入清波点数结算；点数落盘责任归 Rank-3（I-1），Rank-2 不写 user:// / set_flag / commit
```

**接线注意**：① `tick(delta)` 必须每帧调用；② 每波 / 每场 Boss 战开始调一次 `combo.reset()`
（本轮 `wave_trial_director.gd` 的 `_consume_pending_boon()` 已在每波 `_enter_telegraph()` 调用）；
③ `settle()` 幂等，重复 / 同帧多次请求只第一次生效；④ 结算点数的落盘由 Rank-3（I-1）接线，
Rank-2 只产出 `total_points`；⑤ 未接线时 combo 恒 0 连击 → D 级倍率 `1.0`，清波点数与既有**完全等价**（安全降级）。

### 3.7 Rank-4 视觉反馈接线示意（订阅同一实例，不经场景树）

```gdscript
# 持有 Rank-1 装配的同一 ComboService 引用，直接 connect 4 个公开信号
func _on_combo_changed(count: int, rank: String) -> void:
    # 连击数字 = count；连击条长度 / 评级色 = rank（D..S）
func _on_rank_changed(from_rank: String, to_rank: String, multiplier: float) -> void:
    # D/C/B/A/S 跨档演出：升档闪光、降档收光；multiplier 供「×1.6」角标
func _on_combo_reset(reason: String) -> void:
    # reason ∈ hit_taken / timeout / boss_defeated / manual：收起连击特效 + 断连提示
func _on_combo_settled(total_points: int, base_points: int, rank: String, multiplier: float) -> void:
    # 结算演出：评级定格 + 点数从 base_points 滚动到 total_points
```

### 3.8 `wave_trial_director.gd` 本轮新增公开接口（供 Rank-1 / 验证 / HUD）

```
get_combo_service() -> ComboService          # 取本导演装配的 ComboService 实例（供接线 / 注入）
get_boon_service() -> BoonDraftService       # 取本导演装配的 BoonDraftService 实例
select_boon(index: Variant) -> Dictionary    # 抉择三选一注入口（未来 UI / 验证调用；不替玩家选择）
get_settlement_snapshot() -> Dictionary      # {last_settled_points, combo_rank, combo_multiplier,
                                            #  combo_count, boon_cost_key, boon_effect_key,
                                            #  boon_cost_value, settlement_count}
get_snapshot() 追加 8 个只读 key（既有 27 个 key 逐字不动）：
    last_settled_points / combo_rank / combo_multiplier / combo_count /
    boon_cost_key / boon_effect_key / boon_cost_value / settlement_count
```

---

## 4. 真跑输出原文（三段门禁，`SCRIPT ERROR=0`）

命令前缀统一为 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；
引擎版本行：`Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org`。

### GATE-1 `--headless --import`

```
[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
... [ DONE ] first_scan_filesystem
[   0% ] update_scripts_classes | Started 正在注册全局类…… (5 steps)
[   0% ] update_scripts_classes | ComboConfig
[  16% ] update_scripts_classes | ComboService
[  33% ] update_scripts_classes |
[  50% ] update_scripts_classes |
[  66% ] update_scripts_classes |
[ DONE ] update_scripts_classes
[ DONE ] loading_editor_layout
GATE-1 EXIT=0   SCRIPT_ERROR=0
```

### GATE-2a `--check-only --script`（语法门禁，5 件）

```
GATE-2a check-only combo_config                           EXIT=0 SCRIPT_ERROR=0
GATE-2a check-only combo_service                          EXIT=0 SCRIPT_ERROR=0
GATE-2a check-only wave_trial_director                    EXIT=0 SCRIPT_ERROR=0
GATE-2a check-only verify_combo_v110                      EXIT=0 SCRIPT_ERROR=0
GATE-2a check-only verify_production_settlement_v110      EXIT=0 SCRIPT_ERROR=0
```

### GATE-2b `--headless --script <verify>`（实跑）

`verify_combo_v110.gd`（共 110 条逐条 `PASS=true` 原文，含正常 / 边界 / 异常三类，此处列代表行与汇总）：

```
[V110-CB] === SELFTEST START ===
[V110-CB] scene_tree_root_via_main_loop PASS=true | Engine.get_main_loop() as SceneTree -> root，不用 get_tree()/绝对路径
[V110-CB] table_load_cache_ignore PASS=true | path=res://data/rpg/combo_rules.tres
[V110-CB] ruleset_valid PASS=true | is_valid=true
[V110-CB] rank_count_5 PASS=true | 5 档 D/C/B/A/S
[V110-CB] threshold_D_ph PASS=true | got=0 expect=0 [PLACEHOLDER]
[V110-CB] threshold_C_ph PASS=true | got=4 expect=4 [PLACEHOLDER]
[V110-CB] threshold_B_ph PASS=true | got=8 expect=8 [PLACEHOLDER]
[V110-CB] threshold_A_ph PASS=true | got=14 expect=14 [PLACEHOLDER]
[V110-CB] threshold_S_ph PASS=true | got=22 expect=22 [PLACEHOLDER]
[V110-CB] multiplier_S_ph PASS=true | got=2.0 expect=2.0 [PLACEHOLDER]
[V110-CB] timeout_sec_ph PASS=true | got=2.5 expect=2.5 [PLACEHOLDER]
[V110-CB] reset_on_hit_taken_ph PASS=true | got=true expect=true [PLACEHOLDER]
[V110-CB] signal_combo_changed_exists PASS=true | signal combo_changed(count: int, rank: String)
[V110-CB] signal_rank_changed_exists PASS=true | signal rank_changed(from_rank: String, to_rank: String, multiplier: float)
[V110-CB] signal_combo_reset_exists PASS=true | signal combo_reset(reason: String)
[V110-CB] signal_combo_settled_exists PASS=true | signal combo_settled(total_points: int, base_points: int, rank: String, multiplier: float)
[V110-CB] rank_at_4_C PASS=true | 第 4 击 -> C（跨档）
[V110-CB] rank_at_14_A PASS=true | 第 14 击 -> A（跨档）
[V110-CB] rank_at_22_S PASS=true | 第 22 击 -> S（跨档）
[V110-CB] signal_rank_changed_4 PASS=true | rank_changed 恰好 4 次（D→C→B→A→S）
[V110-CB] settle_zero_combo_D_100 PASS=true | 0 连击 -> total=100 mult=1.0（基础结算）[PLACEHOLDER]
[V110-CB] settle_A_160 PASS=true | A 级 -> total=160 mult=1.6 bonus=60 [PLACEHOLDER]
[V110-CB] settle_S_200 PASS=true | S 级 -> total=200 mult=2.0 [PLACEHOLDER]
[V110-CB] duplicate_settle_rejected PASS=true | 同帧/重复 settle -> already_settled 拒绝（防刷点）
[V110-CB] boss_defeated_settle_ok PASS=true | Boss 死亡结算仍得 A 级 160 点
[V110-CB] bnd_overlong_interval_timeout PASS=true | 超长间隔 delta=999 > 2.5 -> 超时重置 combo=0 / D 级
[V110-CB] bnd_exact_timeout PASS=true | delta=2.5（恰好 timeout）-> 超时重置
[V110-CB] bnd_hit_taken_reset PASS=true | 受击 -> 中断连击归零、评级回 D
[V110-CB] bnd_reset_disabled_no_reset PASS=true | reset_on_hit_taken=false -> 受击不中断（REASON_RESET_DISABLED）
[V110-CB] same_frame_settle_once PASS=true | 同帧多次 settle 只第 1 次生效（C 级 100*1.15=115）
[V110-CB] invalid_hit_negative_rejected PASS=true | register_hit(-5) 负数伤害拒绝
[V110-CB] invalid_hit_null_rejected PASS=true | register_hit(null) 拒绝
[V110-CB] invalid_hit_nan_rejected PASS=true | register_hit(NaN) 拒绝
[V110-CB] invalid_points_negative_rejected PASS=true | settle(-1) 拒绝
[V110-CB] invalid_no_config_hit_rejected PASS=true | config=null 命中拒绝
[V110-CB] invalid_then_normal_ok PASS=true | 异常拒绝后正常流程仍得 A 级 160（状态未被污染）
...（共 110 条逐条 PASS=true 原文）...
[V110-CB] SUMMARY pass=110 fail=0
[V110-CB] OVERALL=PASS
[V110-CB] RESULT=ALL_MATCH
GATE-2b run verify_combo_v110 EXIT=0
```

`verify_production_settlement_v110.gd`（共 59 条逐条 `PASS=true` 原文，此处列全量关键行与汇总）：

```
[V110-PS] === SELFTEST START ===
[V110-PS] scene_tree_root_via_main_loop PASS=true | Engine.get_main_loop() as SceneTree -> root
[V110-PS] md5_before_wave_trial.tres_nonempty PASS=true | wave_trial.tres md5(before)=793b6daa7c7730feed1a3f849701d58a
[V110-PS] md5_before_boon_draft.tres_nonempty PASS=true | boon_draft.tres md5(before)=44d8b941f8b28dfa2931984707b5c53e
[V110-PS] md5_before_trial_modifiers.tres_nonempty PASS=true | trial_modifiers.tres md5(before)=7e9e5ac7d35d8d15171e69975ac3356d
[V110-PS] md5_before_stagger_rules.tres_nonempty PASS=true | stagger_rules.tres md5(before)=49ce964e7c268804efbf2f20bec6565d
[V110-PS] md5_before_combo_rules.tres_nonempty PASS=true | combo_rules.tres md5(before)=a1ad4635ae0342c696fe650eb13d4930
[V110-PS] persist_explicitly_downgraded PASS=true | bind_persistence(null,null) -> persist_available=false（不写生产存档）
[V110-PS] baseline_settled_100 PASS=true | 无抉择 / 0 连击 -> settled=100（D 级 mult=1.0，与既有等价）
[V110-PS] baseline_combo_rank_D PASS=true | combo_rank=D / combo_multiplier=1.0 [PLACEHOLDER]
[V110-PS] baseline_combo_service_present PASS=true | 两个纯逻辑服务已装配（combo_rules.tres / boon_draft.tres 真表回读）
[V110-PS] baseline_no_boon_cost PASS=true | 未抉择 -> 无 cost_key / effect_key 生效（抉择代价未凭空出现）
[V110-PS] combo_mult_settled_160 PASS=true | 14 连击 A 级 1.6 -> settled=160（100*1.6）[PLACEHOLDER]
[V110-PS] combo_rank_A PASS=true | combo_rank=A / multiplier=1.6 / combo_count=14
[V110-PS] combo_points_total_160 PASS=true | points_total=160（评级倍率已并入清波点数结算）
[V110-PS] wave_cleared_format_unchanged PASS=true | wave_cleared(index=0, points=100) 仍发基础 pts，既有输出格式/语义未改
[V110-PS] settlement_count_1 PASS=true | 本波仅结算 1 次（不重复结算）
[V110-PS] boon_select_2_ok PASS=true | select_boon(2) 选中恩典供奉（points_bonus / hp_scale）
[V110-PS] boon_points_bonus_160 PASS=true | points_bonus=60 -> settled=160（100+60，combo D 级 1.0）[PLACEHOLDER]
[V110-PS] boon_consumed_and_reset PASS=true | apply()/settle() 已消费并 reset（本波抉择不重复结算、可重新三选一）
[V110-PS] boon_cost_key_active_next_wave PASS=true | 下一波波次开始消费 cost_key=hp_scale（抉择代价生效）
[V110-PS] boon_effect_key_active_next_wave PASS=true | 下一波波次开始消费 effect_key=points_bonus
[V110-PS] boon_cost_value_1_20 PASS=true | cost_value=1.20 [PLACEHOLDER]（作用到下一波的乘性修正）
[V110-PS] boon_state_after_wave2 PASS=true | 已进入第 2 波（index=1）
[V110-PS] combo_plus_boon_256 PASS=true | boon +60 -> base=160，A 级 1.6 -> settled=256（两机制都并入、不叠乘其它层）
[V110-PS] points_monotonic_increase PASS=true | 清波后 points_total 0 -> 100（只增不减、非负）
[V110-PS] balance_nonneg PASS=true | last_settled_points=100 >= 0（余额非负）
[V110-PS] no_double_settle PASS=true | 重复 on_encounter_finished -> 拒绝（points 不变、settlement_count=1、rejected_finishes+1）
[V110-PS] monotonic_after_duplicate PASS=true | 重复触发后点数仍不回退
[V110-PS] boss_defeated_settle_S_200 PASS=true | 单波（Boss 波）死亡结算：S 级 2.0 -> 100*2.0=200 [PLACEHOLDER]
[V110-PS] boss_defeated_service_flag PASS=true | ComboService 已定格并结算（Boss 死亡后不再接受命中 / 不重复结算）
[V110-PS] legacy_snapshot_keys_all_present PASS=true | get_snapshot() 既有 27 个 key 逐字仍在（只新增 R34 只读 key，不改既有）
[V110-PS] settlement_snapshot_api PASS=true | get_settlement_snapshot() 新增只读接口可用
[V110-PS] MD5 wave_trial.tres before=793b6daa7c7730feed1a3f849701d58a after=793b6daa7c7730feed1a3f849701d58a
[V110-PS] MD5 boon_draft.tres before=44d8b941f8b28dfa2931984707b5c53e after=44d8b941f8b28dfa2931984707b5c53e
[V110-PS] MD5 trial_modifiers.tres before=7e9e5ac7d35d8d15171e69975ac3356d after=7e9e5ac7d35d8d15171e69975ac3356d
[V110-PS] MD5 stagger_rules.tres before=49ce964e7c268804efbf2f20bec6565d after=49ce964e7c268804efbf2f20bec6565d
[V110-PS] MD5 combo_rules.tres before=a1ad4635ae0342c696fe650eb13d4930 after=a1ad4635ae0342c696fe650eb13d4930
[V110-PS] md5_zero_change_wave_trial.tres PASS=true | wave_trial.tres 前后 md5 一致（零改动）
[V110-PS] md5_zero_change_boon_draft.tres PASS=true | boon_draft.tres 前后 md5 一致（零改动）
[V110-PS] md5_zero_change_trial_modifiers.tres PASS=true | trial_modifiers.tres 前后 md5 一致（零改动）
[V110-PS] md5_zero_change_stagger_rules.tres PASS=true | stagger_rules.tres 前后 md5 一致（零改动）
[V110-PS] md5_zero_change_combo_rules.tres PASS=true | combo_rules.tres 前后 md5 一致（零改动）
[V110-PS] existing_tables_zero_change PASS=true | 4 份既有 .tres（wave_trial / boon_draft / trial_modifiers / stagger_rules）前后 md5 全部一致
[V110-PS] SUMMARY pass=59 fail=0
[V110-PS] OVERALL=PASS
[V110-PS] RESULT=ALL_MATCH
[V110-PS] === SELFTEST END ===
GATE-2b run verify_production_settlement_v110 EXIT=0
```

### GATE-3 `--headless --quit`（主场景实证）

```
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
[WaveTrial] 持久化基线读回：dungeon.wave_trial.best_wave=3 / dungeon.wave_trial.completed=true / grace.trial.points=450（经 WorldState.get_flag）
[WaveTrial] 增益运行时接线：checked=3 applied=1 degraded=0 reasons=[]
[WaveTrial]   · hp_max_bonus hp_max status=applied before=100.0 after=120.0 via=@export player_max_hp + trial_grace_rest()
...（既有 HUD / FX / CODEX / SHOP / QUALITY 装配日志，均既有行为）...
GATE-3 EXIT=0
```

### 统一统计（`grep SCRIPT ERROR=0`）

```
########## SUMMARY ##########
SCRIPT ERROR TOTAL = 0  (grep SCRIPT ERROR=0 期望)
ERROR(exact 'SCRIPT ERROR') lines:
(none)
GATE-1 EXIT=0 / 5×GATE-2a EXIT=0 / 2×GATE-2b EXIT=0 / GATE-3 EXIT=0
```

**PASS/FAIL 汇总**：`110 + 59 = 169 PASS / 0 FAIL`，两份 `RESULT=ALL_MATCH`，`SCRIPT ERROR=0`。

**md5 零改动结论（既有表）**：`wave_trial.tres` `793b6daa…` / `boon_draft.tres` `44d8b941…` /
`trial_modifiers.tres` `7e9e5ac7…` / `stagger_rules.tres` `49ce964e…` 四份前后完全一致（完整值见上），
本轮只新增 `combo_rules.tres`（`a1ad4635…`，验证脚本同样未写入），**既有 `.tres` 数值零改动**。

> 如实登记（不冒充全绿、不谎报）：`--script` / `--headless` 工具模式尾部有既有 autoload 告警
> `[SaveSystem] --script 工具模式…跳过自动读回（降级，不崩）`、`[ChunkManager] 未找到 ChunkRoot…`、
> `2 ObjectDB instances were leaked at exit`；验证夹具因 `--script` 无主场景另有既有降级打印
> `[WaveTrial] 未找到 EncounterDirector…`、`[WaveTrial] 增益运行时节点缺失 → 数据已落、效果待接`。
> 这些均为 `WARNING`、**非 `SCRIPT ERROR`、非本轮引入、不影响断言与门禁（EXIT=0）**；本轮未改这些文件（越界），如实登记。

---

## 5. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 机制 ① 3 个新文件 + 完善功能 ② `wave_trial_director.gd` 最小接线 + 2 个 verify + DONE + 回执落地；② 三段门禁 GATE-1 / 2a / 2b / 3 全 `EXIT=0`；③ 两份自测 `RESULT=ALL_MATCH`（110 + 59 = 169 PASS / 0 FAIL）；④ `grep SCRIPT ERROR=0`；⑤ 既有 4 份 `.tres` md5 前后一致（零改动），只新增 `combo_rules.tres`；⑥ `courtyard.tscn` 零改动，GATE-3 实证 `node_count=41`（uv `2/1/1` 因零改动保持）；⑦ 纯逻辑边界（I-1 不读写存档 / 不碰渲染 / 不写生产 `delta.json`）——验证脚本显式 `bind_persistence(null,null)` 降级；⑧ 既有输出格式零改动：`wave_cleared(index,pts)` 仍发基础 pts、`get_snapshot()` 既有 27 key 逐字仍在；⑨ 点数只增不减 / 余额非负 / 不重复结算机器判定；⑩ 回执已中枢归档（`dispatcher/receipts/` + `status.json` idle/completed=42 + `dispatcher.log` 登记） |
| **失败** | 无 |
| **需用户确认** | ① 全部 `[PLACEHOLDER]` 数值待人工试玩校准（只改表）；② Rank-1 运行时接线（订阅 4 信号 / 命中 `register_hit` / 每帧 `tick` / 受击 / Boss 死亡 / 结算）——本轮 Rank-2 未改 `encounter_director.gd` / `hud.gd`；③ Rank-3 点数落盘与 `wave_cleared` 订阅口径（见 §7 第 2 条）；④ 抉择 UI（`select_boon` 注入口）未接线；⑤ headless 真跑无渲染画面，未做 15~20 秒实机录屏回看；⑥ 既有 autoload 3 条 WARNING 是否纳入后续清理 |

---

## 6. 未完成项 / 阻塞

- **Rank-1 运行时接线未由 Rank-2 落地**（授权边界，非缺陷）：`encounter_director.gd` / `hud.gd` / `presentation.gd`
  本轮唯一写入方 Rank-1，Rank-2 只读。`combo` 的命中累积 / 每帧 `tick` / 受击 / 死亡 / 4 信号订阅的
  **运行时驱动由 Rank-1 完成**；接线前导演层 combo 恒 0 连击 → D 级倍率 `1.0`，清波点数与既有等价
  （安全降级，正是「不改既有判定分支 / 输出格式」的保证）。纯逻辑 + 数据表 + 最小接线 + 自测均已就绪。
- **`cost_key` / `effect_key` 消费边界（如实登记）**：本轮把 `BoonDraftService.apply()` / `settle()` 的
  `cost_key` / `effect_key` / `cost_value` **消费到导演层运行时记录**（`_active_*` / `get_snapshot()` /
  `get_settlement_snapshot()`，波次开始生效），并让 `points_bonus` 并入点数结算；但 `hp_scale` /
  `telegraph_scale` **尚未真正乘到下一波敌人 HP / 前摇实例**（属 Rank-1 导演层生成敌人时的消费，
  且受「不改既有帧数据 / 既有 `.tres` 数值」约束），见 §7 第 3 条（DONE-R32 裁决项 4 延续）。
- **抉择三选一的玩家 UI 未接线**：本轮只提供 `select_boon(index)` 注入口，不替玩家选择、不含数值。
- **实机录屏目视**（公共契约要求 15~20 秒回看）：本轮交付为纯逻辑 + 数据表 + 最小接线 + headless 真跑，
  无渲染帧缓冲，未录屏；不伪造、列为后续 / 需用户确认。
- 无阻塞；所有硬约束内工作已完成。

---

## 7. 待总指挥裁决项（只登记、不擅改）

1. **数值校准**：`rank_thresholds {0,4,8,14,22}` / `multiplier {1.0,1.15,1.35,1.6,2.0}` /
   `timeout_sec=2.5` / `reset_on_hit_taken=true` 全部 `[PLACEHOLDER]`，待人工试玩校准；
   调参唯一入口 `godot/data/rpg/combo_rules.tres`，同步 `verify_combo_v110.gd` 的 `EXPECT_*` 与本文数值表。
2. **`wave_cleared` 信号值与落盘点数口径一致性（本轮重点口径）**：为严守「不改输出格式」，
   `wave_cleared(index, points)` 第二参数**保持基础 `pts`**；ComboService 倍率并入的是导演层
   `_persist_settle(...)` 的 `new_points` 与本局 `points_total`。但契约 §3.3 登记 Rank-3 订阅
   `wave_cleared(index,points)` 累加 `grace.trial.points`——当 combo 倍率 >1 时，Rank-3 按信号累加值
   与导演层落盘值会分叉。请裁决：是否把结算点数也发进 `wave_cleared`、或明确以导演层落盘为唯一权威、
   或由 Rank-3 改订阅 `combo_settled` / `get_settlement_snapshot()`。本轮按既有产出格式落地、不擅改。
3. **Boon「代价作用于下一波」的落地位置（DONE-R32 裁决项 4 延续）**：`hp_scale` / `telegraph_scale`
   由谁、乘到 `wave_trial.tres` 的 `hp_multiplier` / `telegraph_sec` 还是独立叠加层，避免与既有倍率重复放大。
4. **Combo 运行时接线归属**：命中 `register_hit` / 每帧 `tick` / 受击 `on_hit_taken` / Boss 死亡
   `on_boss_defeated` / 清波 `settle` 的接线归 Rank-1；**每帧 `tick(delta)` 必须调用**，否则连击永不超时。
   4 个信号的 HUD / 视觉反馈订阅由 Rank-1（呈现）与 Rank-4（视觉机制）分工。
5. **结算点数的落盘点与 reason / 是否新增三段式 flag**：`combo` 倍率后的点数由 Rank-3 经
   `grace.trial.points`（只增不减）与 `commit(...)` 落盘，Rank-2 不写；具体 reason / 是否需新 flag 由 Rank-3 口径登记。
6. **「重复输入拒绝」口径收敛**：本轮「连续命中」允许 `register_hit` 连续累积（机制本身），
   重复拒绝落在 `settle` 幂等、`on_boss_defeated` 幂等、Boss 死亡后命中拒绝；
   若需「同一 hit id 去重」或「同帧命中去重」请裁决，本轮不擅自加去重逻辑。
7. **既有 autoload 的 3 条 WARNING**（SaveSystem 工具模式降级 / ChunkManager / ObjectDB 泄漏）：
   非本轮引入，是否纳入后续清理由总指挥裁决。
8. **实机录屏回看**：headless 真跑无帧缓冲，按公共契约如实登记为后续动作 / 需用户确认（不冒充目视通过）。

---

## 8. 设计漏洞主动识别（P0 / P1 / P2）

| 级别 | 漏洞 | 缓解 / 现状 |
|---|---|---|
| **P0** | 无 | 纯逻辑层已覆盖幂等 / 非负 / 异常 / 存档越权 / Boss 死亡 / 超时 / 重复结算，自测机器判定 |
| **P1** | `tick(delta)` 依赖外部每帧调用；导演层若漏接，连击永不超时 → 评级虚高 | 头注 / §3.6 接线示意显式强调，与 R32 `StaggerService.tick` 同款接线约束；需 Rank-1 保证 |
| **P1** | 命中累积信号未接时 combo 恒 0 → 倍率恒 `1.0`，机制在运行时「不可见」 | 本轮安全降级（清波点数与既有等价），接线后才产生 >1 倍率；已登记为未完成项 |
| **P1** | `cost_key` 只消费到导演层记录，未真正乘到下一波敌人实例 → 代价尚未变成实际难度 | `apply()` 强制 `paired=true` 且成对返回 cost 元数据；实际作用到敌人实例待裁决项 3 |
| **P2** | `wave_cleared` 信号值与导演层落盘点数分叉（见裁决项 2） | 本轮严守既有输出格式；列为待裁决，不擅改 |
| **P2** | `settle()` 用 `roundf` 取整（避免 `100×1.6` 浮点截断成 159） | 首版倍率结果均为整数；校准时避免非整倍率造成期望漂移 |
| **P2** | 全部 `[PLACEHOLDER]` 未经手感校准 | 调参唯一入口 + 校准同步清单，待人工试玩 |

---

## 9. 硬约束遵守声明

- `encounter_director.gd` / `hud.gd` / `presentation.gd` / `courtyard.tscn` / 场景 / 素材 /
  其它 Rank 文件**只读未改**；`courtyard.tscn` 节点数 `41` / uv `2/1/1` 未破坏（GATE-3 实证）。
- 既有 `.tres` 数值零改动（`wave_trial.tres` / `boon_draft.tres` / `trial_modifiers.tres` /
  `stagger_rules.tres` md5 前后一致），只新增 `combo_rules.tres` 一张新表。
- 纯逻辑（I-1）：`ComboService`（RefCounted）/ `ComboConfig`（Resource）均不 `add_child` /
  不 `get_tree()` / 不 `/root/...` / 不 `open(user://)` / 不 `set_flag` / 不 `commit` / 不碰渲染 /
  不写生产存档；`wave_trial_director.gd` 接线只在 `wave_cleared` / 波次开始两处消费数据、不写盘，
  验证脚本显式 `bind_persistence(null,null)` 降级，全程不触碰 `user://slot_01/delta.json`。
- Godot4 自测纪律：`extends SceneTree` 用 `Engine.get_main_loop() as SceneTree` 取 root（只读断言），
  `add_child` 后显式 `call("_ready")`（不依赖自动 flush），资源回读 `CACHE_MODE_IGNORE`；
  不用 `get_tree()`、不用 `/root/...` 绝对路径。
- 零付费、零外部依赖、不启 GPU job；不伪造产物、不谎报成功、不自行 git；未删除 `.workbuddy`。
- 默认不刺探：未扫目录做进度巡检、未写只读探针 / 巡检脚本；仅按任务单要求确认回执目录与中枢归档结构。

---

## 10. 回执与中枢归档确认（写后已确认）

- 回执写入 Rank-2 授权路径（**`teamwork/command_center/`，非工程根**）：
  `teamwork/command_center/ai/2/outbox/cmd-20261112-091304-451-A2.json`，
  四字段 `{"task_id", "ai":2, "status":"done", "result"}`。
- 中枢已归档（`poll_ms=600`），`dispatcher.log` 尾部原文：
  ```
  [2026-11-12 09:39:59] ← 2 号 AI 回执 <cmd-20261112-091304-451-A2> 完成：见 teamwork/Rank-2/DONE-R34.md 实际结论：R34 / v0.11.0「玩法闭合 · 连击评价…
  ```
- 归档副本：`dispatcher/receipts/cmd-20261112-091304-451-A2.json`，回读确认 **VALID_JSON**、
  `task_id` / `ai=2` / `status=done` / `result` 四字段齐全且与回执一致。
- `ai/2/status.json` 更新为 `{"ai":2,"state":"idle","current_task":"","completed":42,"last_seen":"2026-11-12 09:39:59"}`
  （`completed` 由 41 → 42、`current_task` 清空）。
- `ai/2/outbox/` 按中枢流程归档后已清空（回执已移入 `dispatcher/receipts/`），与历史其它 AI 一致，
  属中枢正常处理；不重放、不伪造。
