# DONE-R38.md · R38 / v0.15.0「大地图 · 2.5D 尺度重构」大地图野外遭遇交付报告（Rank-2）

> 轮次：`R38 / v0.15.0` ｜ 任务单 id：`cmd-20261112-234238-650-A2` ｜ 执行 AI：`2（Rank-2 战斗系统与数据驱动）`
> 真源：`teamwork/Rank-2/调度任务单-latest.json`（`task` 全文 + 公共契约 + 大改特别条款 + A48 硬要求 + 目录所有权）
>   + `teamwork/Rank-2/DONE-R37.md §3`（既有 FlaskService / DeathService 稳定签名 + wave_trial_director 接线模式）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> 结论：**三段门禁最终统一 `SCRIPT ERROR=0`（GATE-1 / 2a / 2b / 3 全 `EXIT=0`）、两份自测 `RESULT=ALL_MATCH`（49 + 78 = 127 PASS / 0 FAIL）、10 份既有 `.tres` md5 前后一致（零改动）、A48① 4 个新信号生产订阅者落地（GATE-3 日志实证）、A54 唯一实例、A77 既有三波入口可达、A55/A57 一次入账不二次、回执已中枢归档**。
> 如实登记：本轮 Rank-2 三段门禁期间 **未遇到其它 Rank 半成品 `Parse Error`**（GATE-1 `--import` 注册 2 个新全局类、GATE-3 主场景 `courtyard.tscn` 真跑回读 `node_count=41` 可解析）；Rank-1 本轮 A74 改节点/uv 的最终基线由 Rank-1 自行同步 `verify_wave_runtime_v040.gd`，Rank-2 不越界改。
> 如实登记（Rank-2 自有中间态，已修复复跑取最终全绿）：① GATE-2a 首检 `verify_world_encounter_v150.gd` 出现 1 条 `SCRIPT ERROR`（`PackedStringArray(String,String,...)` 多参数构造非法，本轮自有验证脚本引入，非其它 Rank）；② GATE-2b 首跑 `pure_logic_no_save_api` 1 条 `FAIL`（断言误伤 service 头注里「不 add_child / 不调用 get_tree()」等否定声明）。两处均为 Rank-2 自有文件、已修复并复跑，最终 `SCRIPT ERROR=0` / `RESULT=ALL_MATCH`（详见 §4.1 / §4.2）。

---

## 1. 交付清单（实际落地文件）

### 机制 ① · 大地图野外遭遇（新增 3 件，均归 Rank-2）

| 文件 | 类型 | 作用 |
|---|---|---|
| `godot/data/rpg/world_encounters.tres` | 新增数据表 | 4 个分区（与既有 `m6_area_bindings.tres` 的 `region` 字段对齐）+ 6 个遭遇点，每行 7 字段 `id / region_id / position / enemy_group / trigger_radius / cleared_flag / reward_points`；表级 `region_ids / invalid_input_policy`；全部 `[PLACEHOLDER]`、数值真源 / 调参唯一入口 |
| `godot/scripts/combat/world_encounter_config.gd` | 新增 Resource（`extends Resource`, `class_name WorldEncounterConfig`） | 表结构 / 7 字段契约 / `is_valid()` 纯函数 / 逐项 rationale / 降级基线（刻意 != 表值） / 调参唯一入口 |
| `godot/scripts/combat/world_encounter_service.gd` | 新增 RefCounted（`class_name WorldEncounterService`）纯逻辑 | `enter_region()` / `try_trigger()` / `on_encounter_cleared()` / `reset()` / `get_snapshot()`；进入触发 / 距离判定 / 已清除区域不重复触发 / 重复触发幂等 / 异常输入拒绝 / 区域进度单调递增 + **4 个公开信号** |

### 结算接线 ③（修改 1 件，本轮唯一写入方 = Rank-2）

| 文件 | 改动 | 边界 |
|---|---|---|
| `godot/scripts/combat/wave_trial_director.gd` | 10 处精确插入：`WORLD_ENCOUNTERS_PATH` 常量 / 11 个 R38 记录字段 / `_init_combat_services()` 装配 `WorldEncounterService` 唯一实例 + `_bind_world_encounter_signals()`（A48① 生产订阅者）/ `_reset_r34_records()` 清记录并新局 `reset()` / `_clear_wave()` 把 `_world_reward_acc` 并入 `base_for_combo` 后清零 / 清波后 `_mark_world_cleared_on_wave()` 标记区域已清除 / `get_settlement_snapshot()` 追加 2 个只读 key / `get_snapshot()` 追加 10 个只读 key / 新增 `get_world_encounter_service()` + 4 个生产回调 + 3 个真实输入驱动口 | **既有判定分支 / 帧数据 / 输出格式（`wave_cleared(index,pts)` 签名与值、`_refresh_hud()` 文本、既有 27 + R34 8 + R35 8 + R36 11 + R37 14 个 key）/ 既有 `.tres` 数值一律逐字未动**；野外遭遇奖励只并入既有 `base_for_combo` 一次 → 经既有 `combo.settle()` 得唯一最终结算值 → HUD 经 `get_last_settlement()` 取该值发 `points_awarded` 一次入账（A55/A57，**不二次入账**）；无野外遭遇时 `_world_reward_acc` 恒 0、`_mark_world_cleared_on_wave()` 空转，既有三波试炼结算逐字等价（**A77 入口不废**） |

### 自测脚本（新增 2 件，均在 `godot/scripts/combat/`）

| 文件 | 作用 | 结果 |
|---|---|---|
| `verify_world_encounter_v150.gd` | 机制 ① 正常 / 边界 / 异常三类：读表 4 分区 6 遭遇点 + 7 字段 + `[PLACEHOLDER]` 数值 + 分区 id 对齐 + 4 信号、进入触发、距离判定（半径内/边缘/半径外）、已清除区域不重复触发、重复触发幂等、清除/重复清除幂等、区域进度单调递增、config=null、异常 enter/position/clear 全拒绝、8 类非法表、异常后正常流程、reset、纯逻辑边界（I-1）、A48① 静态证据 | `pass=49 fail=0 RESULT=ALL_MATCH` |
| `verify_world_settlement_v150.gd` | 遭遇奖励并入结算（真实生产脚本驱动） + 点数单调 + 区域清除单调（含多区域序列 `[0,1,2,3,4]`）+ 不二次入账 + A57 取源一致 + A77 既有入口可达 + **md5 前后对比证明 10 份既有表零改动** + 既有输出格式零改动 + A48① 运行时实证 + A54 唯一实例 | `pass=78 fail=0 RESULT=ALL_MATCH` |

### 文档 / 回执 / 门禁日志（新增）

| 文件 | 作用 |
|---|---|
| `teamwork/Rank-2/DONE-R38.md` | 本交付报告 |
| `teamwork/command_center/ai/2/outbox/cmd-20261112-234238-650-A2.json` | 本轮回执，中枢归档见 §10 |
| `teamwork/Rank-2/_gates_R38/*.log` | 三段门禁 9 份真跑日志原文（GATE-1 / GATE-2a×5 / GATE-2b×2 / GATE-3），供复核 |

### 只读未改（硬约束）

`godot/scenes/courtyard.tscn` / `godot/scripts/hud.gd` / `godot/test/presentation.gd`（三者本轮唯一写入方 Rank-1，Rank-2 只读）、
`godot/scripts/rpg/points_commit_orchestrator.gd` / `godot/project.godot`（Rank-3 所有 / A56 autoload）、
`godot/scripts/render/impact_feedback.gd`、场景 / 素材 / 其它 Rank 文件、既有 `.tres` 数值
（`wave_trial.tres` / `boon_draft.tres` / `trial_modifiers.tres` / `combo_rules.tres` / `stagger_rules.tres` / `player_actions.tres` / `boss_01_margit.tres` / `enemy_01_limgrave_soldier.tres` / `parry_rules.tres` / `focus_rules.tres` 等，见 §9）。

---

## 2. 玩法拆解表（需求 → 机制 → 数值 → 状态 → 验收）

| 需求 | 机制 | 数值（`[PLACEHOLDER]` 首版） | 状态（实例内、不持久化） | 验收 |
|---|---|---|---|---|
| 4 个分区与 Rank-1 对齐 | `region_ids` 取既有 `m6_area_bindings.tres` 的 `region` 字段 | `limgrave / weeping_peninsula / stormveil / siofra_well` | — | `region_count_4` / `region_ids_aligned` |
| 按分区配置遭遇点 | `encounters: Array[Dictionary]`，每行 7 字段 | 6 个遭遇点（4 区，limgrave/siofra 各 2 个） | — | `encounter_count_6` / `encounter_fields_all_7` / `placeholder_*` |
| 进入触发 | `enter_region(region_id)`：config/输入/注册三重门；成功置当前分区、发 `region_entered` | — | `_current_region` | `enter_region_ok` / `region_entered_signal_once` |
| 距离判定 | `try_trigger(position)`：当前区域未清除遭遇中取 `distance_to <= trigger_radius` 的**最近**一个 | `trigger_radius = 96/80/112/96/128/128` | `_active_id` | `distance_inside_trigger_ok` / `distance_edge_inside_ok` / `distance_outside_no_encounter` |
| 重复触发幂等 | `_active_id` 非空 → `duplicate` 拒绝，不二次发信号 / 不改状态 | — | `_active_id` | `duplicate_trigger_idempotent` / `duplicate_no_second_signal` |
| 已清除区域不重复触发 | 单遭遇区域全清 → `already_cleared`；已清遭遇在遍历中跳过 | — | `_cleared` | `cleared_region_no_retrigger` |
| 标记区域已清除 | `on_encounter_cleared(id)`：仅清当前 active；`_cleared_count += 1` 单调递增、发 `encounter_cleared` | — | `_cleared` / `_cleared_count` | `on_encounter_cleared_ok` / `encounter_cleared_signal_once` / `duplicate_clear_idempotent` |
| 区域进度单调递增 | `_cleared_count` 只增不减（除显式 `reset`） | — | `_cleared_count` | `cleared_count_monotonic` `[0,1,2,3,4]` / `multi_region_clear_monotonic` |
| 异常输入拒绝 | `invalid_input_policy="reject"`：null / 非 Vector2 / NaN / Inf / 未注册 region / 未进区域 / 非 active 清除一律拒绝且不改状态 | `invalid_input_policy="reject"` | 状态不变 | `invalid_*_all_rejected`(15 类) / `no_config_reject` / `illegal_tables_all_rejected`(8 类) / `invalid_then_normal_ok` |
| 每场重置 | `reset()` 回构造初始态（清除态按表 `cleared_flag` 初始化） | `cleared_flag=false`（全表） | 全状态 | `reset_clears_all` |
| 奖励并入结算一次入账 | 触发 → `encounter_triggered` → 导演层 `_world_reward_acc` → `_clear_wave()` 并入 `base_for_combo` → `combo.settle()` → `points_awarded` 一次；并入后清零 | `reward_points = 80/100/120/150/160/200` | `_world_reward_acc` | `reward_into_settled_180` / `a57_awarded_source_consistent` / `no_double_settle_one` / `reward_acc_cleared_after_settle` |
| 清波后标记区域已清除 | 导演层 `_mark_world_cleared_on_wave()` 取 service active 调 `on_encounter_cleared()` | — | `_cleared_count` | `region_cleared_after_wave` / `clear_not_repeated` |
| 点数单调 / 余额非负 | `base_for_combo = maxi(0, ...)`、既有 `_persist_settle` max 保护、既有 `WAVE_ACTIVE` 门控 | — | `points_total` | `points_monotonic_increase`(0→180) / `balance_nonneg` / `no_double_settle` |
| 既有三波入口可达（A77） | 无野外遭遇时 `_world_reward_acc` 恒 0、`_mark` 空转，`start_trial()/on_encounter_finished()` 逐字等价 | — | — | `a77_trial_entry_reachable` / `baseline_no_world_reward` / `baseline_wave_cleared_format` |

### 结算值两组实证（均 `RESULT=ALL_MATCH`）

| 组合 | base 推导 | 倍率 | 最终结算值 | 断言 |
|---|---|---|---|---|
| 基线（无野外遭遇，A77） | `100` | D 1.0 | **100** | `a77_trial_entry_reachable` / `baseline_settled` |
| 野外遭遇 gatefront 触发 → 清波 | `100 + 80 = 180` | D 1.0 | **180** | `reward_into_settled_180` / `points_total_180` / `a57_awarded_source_consistent` |

### 数值拆解 / rationale（完整版见 `world_encounter_config.gd` 头注）

- **调参唯一入口（只改表不改代码）**：`godot/data/rpg/world_encounters.tres`。代码内 `WorldEncounterConfig.DEFAULT_*` 是**非法降级基线**（刻意 `!=` 表值，`verify_world_encounter_v150.gd` 的 `default_is_not_design_*` 机器判定），不是设计数值。校准同步清单：`.tres` → 两份 verify 的 `EXPECT_*` → 本文数值表 → 三段门禁；不静默改数。
- **分区 id `[PLACEHOLDER]`**：`limgrave / weeping_peninsula / stormveil / siofra_well` 逐字取自既有 `godot/data/rpg/m6_area_bindings.tres` 的 `region` 字段（4 个 `is_dungeon=false` 的地表/野外区域），是工程内既有稳定命名来源、不臆造。★ 仍标 `[PLACEHOLDER]`：A76（大地图逻辑尺寸 / 分区 id / 相机边界口径）由 Rank-1 `world_scale.tres` 与 Rank-3 `grace_sites.tres` 最终落定；若最终口径不同，**只改 `.tres` 的 `region_ids` / `region_id` 两处即可对齐，不改代码、不改 service / director**。
- **`position`（(512,384)…(3072,896)）`[PLACEHOLDER]`**：落在 Rank-1 建议的 4096×2304 逻辑像素大地图内，4 区沿 X 由西到东分散，使相机随玩家位移时各区遭遇点有可辨识间隔；纯 2.5D 俯视 XZ 平面坐标，不含渲染信息。
- **`trigger_radius`（96/80/112/96/128/128）`[PLACEHOLDER]`**：取 80~128 逻辑像素，配合角色 40% 缩放后的可视范围；各区略有差异便于肉眼区分「半径内触发 / 半径外 `no_encounter`」；`<=0` 或非有限值被 `is_valid()` 判非法。
- **`reward_points`（80/100/120/150/160/200）`[PLACEHOLDER]`**：随分区推进递增（对标「越深入奖励越高」）；★ 奖励**不直接落盘、不二次入账**，只在既有清波结算（A55/A57）里并入 `base_for_combo` 一次，经 `combo.settle()` → `points_awarded` 一次入账，不造成点数通胀。
- **`enemy_group`**：引用既有 `enemy_01_limgrave_soldier` / `boss_01_margit` 的 id 字符串，数据驱动、不改动任何既有 enemy/boss `.tres` 数值。
- **`cleared_flag = false`（全表）`[PLACEHOLDER]`**：首版所有遭遇初始未清除；`service.reset()` 按本字段初始化本局清除态（可只改表配置「初始已清区域」）。
- **`invalid_input_policy = "reject"` `[PLACEHOLDER]`**：异常输入一律拒绝且不改状态，避免 clamp / ignore 造成「隐式触发 / 隐式二次清除」不可测分支；首版唯一合法值。

---

## 3. 供 Rank-1 与 Rank-3 使用的公开方法与信号完整签名（本轮重点）

> `WorldEncounterService` 是 `RefCounted` 纯逻辑，**信号是 Object 级能力**：Rank-1 / Rank-3 / Rank-4 直接 `connect` 到本服务实例即可，无需场景树、无需 `add_child`、无需 `/root/...`。以下签名**稳定、不再改动**。
> **A54 唯一实例**：由 `wave_trial_director.gd` 装配，Rank-1 / Rank-3 / Rank-4 经 `get_world_encounter_service()` 复用，绝不另建第二个。
> **★ GATE-3 实证**：`[R38][WaveTrial] 大地图野外遭遇生产订阅者已装配：WorldEncounterService 唯一实例 + 4 信号 connect（A48①/A54）`（主场景真跑，非验证脚本）。

### 3.1 公开信号（`godot/scripts/combat/world_encounter_service.gd`，4 个）

```
signal region_entered(region_id: String)
    # enter_region() 成功时发；payload = 进入的分区 id。
    # ★ A48①：生产订阅者 = wave_trial_director._on_world_region_entered()（计数 + 记录当前区域）。
    # 供 Rank-1 大地图进入反馈 / Rank-3 区域发现口径 / Rank-4 分区转场演出。
signal encounter_triggered(encounter_id: String, region_id: String, reward_points: int)
    # try_trigger() 成功（进入半径且未清除）时发；reward_points 供生产订阅者并入既有
    # 清波点数结算基数（A55/A57 经 points_awarded 一次入账，不二次入账）。
    # ★ A48①：生产订阅者 = wave_trial_director._on_world_encounter_triggered()（acc 累计 + active 记录）。
signal encounter_cleared(encounter_id: String, region_id: String, cleared_count: int)
    # on_encounter_cleared() 成功、标记区域已清除时发；cleared_count 单调递增。
    # ★ A48①：生产订阅者 = wave_trial_director._on_world_encounter_cleared()（计数 + 清 active）。
    # 供 Rank-3 落盘「区域已清除 / 地图进度」三段式 flag 口径。
signal trigger_rejected(reason: String, encounter_id: String)
    # 异常输入 / 未进入区域 / 距离外 / 已清除 / 重复触发 / 无活跃遭遇被拒时发。
    # ★ A48①：生产订阅者 = wave_trial_director._on_world_trigger_rejected()（计数 + 最近 reason）。
    # 供 Rank-4 失败反馈 / Rank-3 决定是否落盘（建议拒绝事件不写盘、只走 HUD 反馈）。
```

### 3.2 `WorldEncounterService` 公开方法（全静态类型）

```
class_name WorldEncounterService (extends RefCounted)
_init(config: WorldEncounterConfig = null)          # 构造注入规则表，自动 reset()
set_config(config: WorldEncounterConfig) -> void    # 替换表并 reset()（含 null 降级验证）
get_config() -> WorldEncounterConfig
reset() -> void                                   # 回构造初始态（清除态按表 cleared_flag 初始化；每场新一局）
enter_region(region_id: Variant) -> Dictionary     # 进入分区；config/输入/注册三重门，成功发 region_entered
try_trigger(position: Variant) -> Dictionary        # 进入触发 + 距离判定 + 已清除不重复 + 重复触发幂等 + 异常拒绝
on_encounter_cleared(encounter_id: Variant) -> Dictionary
                                                  # 标记区域已清除；仅清当前 active，进度单调递增、重复清除幂等

get_current_region() -> String
get_active_encounter_id() -> String                # 当前活跃（已触发未清除）遭遇 id，供导演层清波标记清除
get_active_region() -> String
get_cleared_count() -> int                         # 已清除遭遇总数（单调递增，除显式 reset）
is_cleared(encounter_id: String) -> bool
get_enter_count() -> int
get_trigger_count() -> int
get_clear_count() -> int
get_reject_count() -> int
get_last_result() -> Dictionary                    # 最近一次成功结果（Dictionary 副本）
get_last_reject_reason() -> String
get_invalid_input_policy() -> String
is_config_valid() -> bool
get_snapshot() -> Dictionary                       # 全状态快照（见 §3.3）
```

**接线注意**：① 本服务**不持有玩家坐标**，`position` 由 Rank-1 输入层传入（Vector2，2.5D 俯视平面）；② `start_trial()` 会经 `_reset_r34_records()` 复位 service，因此 `enter_world_region()` / `try_world_encounter()` 必须在 `start_trial()` 之后调用；③ 清波由既有 `on_encounter_finished(true)` → `_clear_wave()` 完成，清波后导演层**自动**标记区域已清除，Rank-1 无需再调 `on_world_encounter_cleared()`（该驱动口供 Rank-1 主动清除 / 验证用）；④ 相邻 `try_trigger` 在 active 未清除时幂等拒绝；⑤ 纯逻辑无 `tick`，不依赖每帧转发；⑥ 不读写存档、不写 `.tres`、不碰渲染。

### 3.3 `WorldEncounterService` 返回 Dictionary 字段（供 Rank-1 / Rank-3 消费）

```
enter_region        : {ok, reason, region_id, enter_count, cleared_count, config_present}
try_trigger         : {ok, reason, encounter_id, region_id, enemy_group, reward_points,
                      distance, trigger_radius, trigger_count, cleared_count, config_present}
                      拒绝体 {ok, reason, encounter_id, current_region, active_id,
                              cleared_count, config_present}
on_encounter_cleared: {ok, reason, encounter_id, region_id, cleared_count, clear_count, config_present}
get_snapshot        : {current_region, active_encounter, active_region, cleared_count,
                      cleared_ids, enter_count, trigger_count, clear_count, reject_count,
                      region_count, encounter_count, config_present, invalid_input_policy,
                      last_result, last_reject_reason}
```

成功恒 `reward_points>=0` / `distance>=0` / `cleared_count` 单增；拒绝时 `reward_points=0`、不改清除态与 active。

### 3.4 `WorldEncounterService` / `WorldEncounterConfig` 公开常量（签名稳定）

```
WorldEncounterService reason:
    REASON_OK              = "ok"
    REASON_NO_CONFIG       = "no_config"        # config 缺失 / 非法表
    REASON_INVALID_INPUT   = "invalid_input"    # 异常 id / 非 Vector2 / NaN / Inf
    REASON_NO_REGION       = "no_region"        # 未进入区域 / region 未注册
    REASON_NO_ENCOUNTER    = "no_encounter"     # 半径外 / 区域无遭遇
    REASON_ALREADY_CLEARED = "already_cleared"  # 已清除区域不重复触发
    REASON_DUPLICATE       = "duplicate"        # 重复触发幂等拒绝
    REASON_NO_ACTIVE       = "no_active"        # 无活跃遭遇 / 重复清除幂等
    ID_NONE                = "<none>"           # 非 String id 在 trigger_rejected payload 的占位
WorldEncounterConfig:
    POLICY_REJECT              = "reject"       # 唯一合法 invalid_input_policy
    ENCOUNTER_FIELDS           : PackedStringArray  # 7 字段契约（见 §3.5）
    DEFAULT_REGION_IDS / DEFAULT_ENCOUNTERS / DEFAULT_INVALID_INPUT_POLICY
                                                  # 降级基线（刻意 != 表值，非设计数值）
```

### 3.5 `WorldEncounterConfig` 公开接口（`extends Resource` / `class_name WorldEncounterConfig`）

```
@export var region_ids: PackedStringArray          # 分区 id 集合（表值 [PLACEHOLDER]，与 Rank-1 对齐）
@export var encounters: Array[Dictionary]          # 遭遇点数组，每行 7 字段（表值 [PLACEHOLDER]）
@export var invalid_input_policy: String           # 唯一合法值 POLICY_REJECT="reject"
is_valid() -> bool                                # 分区集合非空无重复 / 每行 7 字段类型合法 /
                                                  # region_id ∈ region_ids / position 为 Vector2 且有限 /
                                                  # trigger_radius>0 且有限 / cleared_flag 为 bool /
                                                  # reward_points>=0 且为整数 / policy==reject；异常一律 false（不崩）
get_region_ids() -> PackedStringArray
get_encounters() -> Array[Dictionary]             # 深拷贝（外层数组 + 每行 Dictionary duplicate），★ 绝不写回表
get_region_count() -> int / get_encounter_count() -> int
get_invalid_input_policy() -> String
has_region(region_id: String) -> bool
```

### 3.6 `wave_trial_director.gd` 本轮新增公开接口（供 Rank-1 / Rank-3 / 验证 / HUD）

```
get_world_encounter_service() -> WorldEncounterService   # ★ A54 唯一实例（Rank-1 / Rank-3 / Rank-4 复用）

# 真实输入驱动口（转调 A54 唯一实例，供 Rank-1 输入层 / 验证调用）
enter_world_region(region_id: Variant) -> Dictionary
try_world_encounter(position: Variant) -> Dictionary
on_world_encounter_cleared(encounter_id: Variant) -> Dictionary

get_settlement_snapshot() 追加 2 个只读 key（既有 key 逐字不动）：
    world_reward_bonus / world_cleared_count
get_snapshot() 追加 10 个只读 key（既有 27 + R34 8 + R35 8 + R36 11 + R37 14 个 key 逐字不动）：
    world_current_region / world_active_encounter / world_active_region /
    world_reward_acc / world_cleared_count / world_enter_count /
    world_trigger_count / world_clear_count / world_reject_count /
    world_last_reject_reason
```

### 3.7 Rank-1 接线示意（伪代码，供输入层 / 大地图 / HUD）

```gdscript
# A54 唯一实例：从波次导演复用，绝不 new 第二个 WorldEncounterService
var world: WorldEncounterService = wave_trial_director.get_world_encounter_service()
world.connect("region_entered",       Callable(self, "_on_region_entered"))
world.connect("encounter_triggered",   Callable(self, "_on_encounter_triggered"))
world.connect("encounter_cleared",     Callable(self, "_on_encounter_cleared"))
world.connect("trigger_rejected",      Callable(self, "_on_trigger_rejected"))

# 玩家在大地图移动：按所属分区进入 + 按当前坐标尝试触发
func _on_player_entered_region(region_id: String) -> void:
    wave_trial_director.enter_world_region(region_id)
func _on_player_moved(player_pos: Vector2) -> void:
    var r: Dictionary = wave_trial_director.try_world_encounter(player_pos)
    if r.ok:
        # 触发后复用既有三波 / 导演层结算：战斗胜利由既有
        # on_encounter_finished(true) 驱动 _clear_wave() 结算
        # （奖励已由生产订阅者累计、清波后自动标记区域已清除）
        pass
# 注意：enter/try 必须在 start_trial() 之后（start_trial 会复位 service）
```

### 3.8 Rank-3 落盘接线示意（订阅同一实例，不经场景树）

```gdscript
world.connect("encounter_cleared", Callable(self, "_on_region_cleared"))
func _on_region_cleared(encounter_id: String, region_id: String, cleared_count: int) -> void:
    # 建议三段式 flag（严格匹配 ^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$）：
    #   world.map.region_<id>.cleared  bool / world.map.progress  int
    #   cleared_count 单调递增，可作进度真值；遵守既有 SaveDelta 十字段 / schema_version=3 冻结、
    #   不写 removals / grace.trial.points 只增不减 / commit(reason) 原子写 / 先落盘再改运行时实例。
    # ★ reward_points 已由 wave_trial_director 生产订阅者并入既有清波结算（A55/A57），
    #   Rank-3 不再对奖励二次入账；trigger_rejected 建议「拒绝事件不写盘、只走 HUD 反馈」。
```

### 3.9 A48① 生产运行时订阅者清单（不能只在验证脚本里）

| 服务 | 信号 | 生产订阅者（生产节点，非验证脚本） | 真实职责 |
|---|---|---|---|
| WorldEncounterService | `region_entered` | `wave_trial_director._on_world_region_entered()` | 进入区域计数 / 记录当前区域 |
| WorldEncounterService | `encounter_triggered` | `wave_trial_director._on_world_encounter_triggered()` | reward 累计到 `_world_reward_acc` / 记录 active 遭遇与区域（A55/A57） |
| WorldEncounterService | `encounter_cleared` | `wave_trial_director._on_world_encounter_cleared()` | 清除计数 / 清 active 镜像（区域清除单调） |
| WorldEncounterService | `trigger_rejected` | `wave_trial_director._on_world_trigger_rejected()` | 拒绝计数 / 最近 reason 记录 |

装配入口 `_init_combat_services()` → `_bind_world_encounter_signals()`，GATE-3 主场景日志实证（§4.4）；回调有真实职责（acc 累计 / 计数 / active 记录 / 清除），非空订阅。

---

## 4. 真跑输出原文（三段门禁，最终统一 `SCRIPT ERROR=0`）

命令前缀统一为 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；引擎版本行：`Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org`。日志全文留存 `teamwork/Rank-2/_gates_R38/*.log`。

### GATE-1 `--headless --import`（注册 2 个新全局类）

```
[   0% ] update_scripts_classes | Started 正在注册全局类…… (5 steps)
[  50% ] update_scripts_classes | WorldEncounterConfig
[  66% ] update_scripts_classes | WorldEncounterService
[ DONE ] update_scripts_classes
GATE1_EXIT=0   SCRIPT_ERROR=0
```

**归属核验**：`SCRIPT ERROR` 无一条指向 Rank-2 本轮 3 个新文件 / `wave_trial_director.gd`；本轮 Rank-2 门禁期间**未遇到其它 Rank 半成品 Parse Error**（GATE-3 `courtyard.tscn` 回读 `node_count=41` 可解析；Rank-1 本轮 A74 最终基线由其自行同步）。

### GATE-2a `--check-only --script`（语法门禁，5 件）

```
CHECK_ONLY world_encounter_config          EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY world_encounter_service         EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY wave_trial_director             EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY verify_world_encounter_v150     EXIT=0  SCRIPT_ERROR=0
CHECK_ONLY verify_world_settlement_v150    EXIT=0  SCRIPT_ERROR=0
```

**如实登记（Rank-2 自有中间态，已修复复跑）**：首检 `verify_world_encounter_v150.gd` 曾出 1 条 `SCRIPT ERROR`：`Parse Error: No constructor of "PackedStringArray" matches the signature "PackedStringArray(String, String, String, String)"`（`at: ... verify_world_encounter_v150.gd:422`）—— 验证脚本里用了 `.tres` 文本格式的多参数 `PackedStringArray(...)` 构造，GDScript 不合法；改为 `PackedStringArray([...])` 后复跑 `EXIT=0 SCRIPT_ERROR=0`。归属 = Rank-2 本轮自有验证脚本、非其它 Rank。

### GATE-2b `--headless --script <verify>`（实跑，两份逐条 `PASS=true`）

`verify_world_encounter_v150.gd`（49 条全 `PASS=true`，正常 / 边界 / 异常三类，代表行与汇总）：

```
[V150-WE] === SELFTEST START ===
[V150-WE] table_load_cache_ignore PASS=true | path=res://data/rpg/world_encounters.tres（CACHE_MODE_IGNORE 回读真值）
[V150-WE] config_is_valid PASS=true | WorldEncounterConfig.is_valid()=true
[V150-WE] region_count_4 PASS=true | region_count=4 [PLACEHOLDER]（至少 4 个区域）
[V150-WE] encounter_count_6 PASS=true | encounter_count=6 [PLACEHOLDER]
[V150-WE] region_ids_aligned PASS=true | 分区 id 与既有 m6_area_bindings.tres 的 region 字段逐字对齐：["limgrave", "weeping_peninsula", "stormveil", "siofra_well"] [PLACEHOLDER]
[V150-WE] encounter_fields_all_7 PASS=true | 6 行遭遇点均含 id/region_id/position/enemy_group/trigger_radius/cleared_flag/reward_points
[V150-WE] placeholder_radius PASS=true | 6 个 trigger_radius 与 [PLACEHOLDER] 期望一致（96/80/112/96/128/128）
[V150-WE] placeholder_reward PASS=true | 6 个 reward_points 与 [PLACEHOLDER] 期望一致（80/100/120/150/160/200）
[V150-WE] default_is_not_design_regions PASS=true | DEFAULT_REGION_IDS 为空 != 表值 4（调参唯一入口在 .tres）
[V150-WE] signal_region_entered_exists PASS=true / signal_encounter_triggered_exists PASS=true
[V150-WE] signal_encounter_cleared_exists PASS=true / signal_trigger_rejected_exists PASS=true
[V150-WE] enter_region_ok PASS=true | enter_region(limgrave) 成功、当前分区置位
[V150-WE] distance_inside_trigger_ok PASS=true | try_trigger(512,384) 命中 gatefront、reward=80 [PLACEHOLDER]
[V150-WE] distance_edge_inside_ok PASS=true | try_trigger(602,384) distance=90 <= radius=96 仍命中
[V150-WE] distance_outside_no_encounter PASS=true | try_trigger(612,384) distance=100 > 96 -> no_encounter
[V150-WE] duplicate_trigger_idempotent PASS=true | active 未清除时重复 try_trigger -> duplicate 拒绝（幂等）
[V150-WE] duplicate_no_second_signal PASS=true | 重复触发不二次发信号 / trigger_count 恒 1
[V150-WE] on_encounter_cleared_ok PASS=true | 标记区域已清除：cleared_count=1、is_cleared=true
[V150-WE] duplicate_clear_idempotent PASS=true | 重复清除 -> no_active、进度不二次增加（幂等）
[V150-WE] cleared_region_no_retrigger PASS=true | 区域全部遭遇已清除 -> already_cleared（已清除区域不重复触发）
[V150-WE] cleared_count_monotonic PASS=true | 区域清除进度序列 [0, 1, 2, 3, 4] 单调递增（只增不减）
[V150-WE] no_config_reject PASS=true | config=null -> enter_region / try_trigger 均 no_config 拒绝（不崩）
[V150-WE] invalid_enter_region_all_rejected PASS=true | enter_region(null/int/空串/未注册) 全部拒绝（4 类）
[V150-WE] invalid_position_all_rejected PASS=true | try_trigger(null/字符串/Vector3/NaN/Inf) 全部 invalid_input 拒绝（6 类）
[V150-WE] invalid_cleared_all_rejected PASS=true | on_encounter_cleared(null/int/空/不存在/非 active) 全部拒绝（5 类）
[V150-WE] invalid_then_normal_ok PASS=true | 异常输入拒绝后正常 enter+trigger 仍命中 gatefront、reward=80
[V150-WE] illegal_tables_all_rejected PASS=true | 8 类非法表 is_valid()=false
[V150-WE] reset_clears_all PASS=true | reset() 回构造初始态
[V150-WE] pure_logic_no_save_api PASS=true | service 源码（去注释）不含 set_flag/commit/add_child/get_tree()/root/removals/open（I-1 不读写存档）
[V150-WE] config_no_design_numbers PASS=true | config 源码不写死设计数值（调参唯一入口在 .tres）
[V150-WE] production_subscriber_in_source PASS=true | 生产源码含 4 信号订阅者 + 唯一实例 getter + 奖励并入结算 + 清波标记清除 + 驱动口（A48①/A54/A57）
[V150-WE] SUMMARY pass=49 fail=0
[V150-WE] OVERALL=PASS
[V150-WE] RESULT=ALL_MATCH
[V150-WE] === SELFTEST END ===
verify_world_encounter_v150_EXIT=0   SCRIPT_ERROR=0
```

**如实登记（Rank-2 自有中间态，已修复复跑）**：首跑 `pure_logic_no_save_api` 1 条 `FAIL`（断言检查整份源码文本，误伤 service 头注里「不 `add_child` / 不调用 `get_tree()` / 不用 `/root/`」等**否定声明**）。改为剥离 `#` 注释后只检查代码，复跑 `PASS=true`。归属 = Rank-2 本轮自有验证脚本、非其它 Rank。

`verify_world_settlement_v150.gd`（78 条全 `PASS=true`，关键行 + md5 + 汇总）：

```
[V150-WS] === SELFTEST START ===
[V150-WS] md5_before_wave_trial.tres_nonempty PASS=true | wave_trial.tres md5(before)=793b6daa7c7730feed1a3f849701d58a
[V150-WS] md5_before_world_encounters.tres_nonempty PASS=true | world_encounters.tres md5(before)=a36085c8b3abff719ac0f7dbb62a195f
[V150-WS] persist_explicitly_downgraded PASS=true | bind_persistence(null,null) -> persist_available=false（不写生产存档）
[V150-WS] a77_trial_entry_reachable PASS=true | ★ A77：无野外遭遇时既有 start_trial()/on_encounter_finished() 入口仍可达、结算=100
[V150-WS] baseline_no_world_reward PASS=true | 基线无野外遭遇奖励凭空出现 / 区域清除进度=0
[V150-WS] baseline_wave_cleared_format PASS=true | wave_cleared(index=0, points=100) 既有输出格式/语义未改
[V150-WS] enter_region_via_driver PASS=true | 真实输入驱动口 enter_world_region(limgrave) 成功
[V150-WS] try_world_encounter_via_driver PASS=true | 真实输入驱动口 try_world_encounter(512,384) -> 命中、reward=80 [PLACEHOLDER]
[V150-WS] a48_trigger_subscriber_runtime PASS=true | 生产订阅者实证：encounter_triggered 已把 reward 累计到待结算 acc=80（A48①）
[V150-WS] reward_into_settled_180 PASS=true | 野外遭遇奖励 80 并入清波结算基数：100+80 -> settled=180（D 级 1.0）[PLACEHOLDER]
[V150-WS] points_total_180 PASS=true | points_total=180（遭遇奖励已并入既有清波点数结算）
[V150-WS] reward_acc_cleared_after_settle PASS=true | 并入结算后 _world_reward_acc 清零（不二次入账）
[V150-WS] region_cleared_after_wave PASS=true | ★ 清波后标记区域已清除：world_cleared_count=1（A48① encounter_cleared 生产订阅者）
[V150-WS] a57_awarded_source_consistent PASS=true | A57：最终结算值 180 经 points_awarded 发出的取源与导演层一致（唯一最终值）
[V150-WS] no_double_settle_one PASS=true | 本波仅结算 1 次（不二次入账）
[V150-WS] wave_cleared_format_unchanged PASS=true | wave_cleared(index=0, points=100) 仍发基础 pts，既有输出格式/语义未改
[V150-WS] duplicate_trigger_idempotent PASS=true / duplicate_no_double_acc PASS=true
[V150-WS] no_double_settle PASS=true | 重复 on_encounter_finished -> 拒绝（points 不变、不二次入账）
[V150-WS] clear_not_repeated PASS=true | 重复清波不二次标记区域已清除
[V150-WS] points_monotonic_increase PASS=true | 清波后 points_total 0 -> 180（只增不减、非负）
[V150-WS] balance_nonneg PASS=true | last_settled_points / grace_trial_points 均 >= 0（余额非负、不回退）
[V150-WS] clear_count_monotonic PASS=true | ★ 区域清除进度 0 -> 1 单调递增（只增不减）
[V150-WS] multi_region_clear_monotonic PASS=true | 4 个区域连续清除 world_cleared_count 序列 [0, 1, 2, 3, 4] 单调递增
[V150-WS] legacy_snapshot_keys_all_present PASS=true | get_snapshot() 既有 27 个 key 逐字仍在
[V150-WS] r34/r35/r36/r37_snapshot_keys_intact PASS=true | R34 8 + R35 8 + R36 11 + R37 14 个 key 逐字仍在
[V150-WS] r38_snapshot_keys_present PASS=true / r38_settlement_keys_present PASS=true
[V150-WS] real_production_director PASS=true | 驱动对象 = 真实生产脚本 wave_trial_director.gd（非验证脚本内自建替身/模拟编排）
[V150-WS] a54_single_instance PASS=true | A54：两次 get_world_encounter_service() 返回同一实例
[V150-WS] a54_world_service_present PASS=true | WorldEncounterService 唯一实例已装配（表回读成功、不降级）
[V150-WS] production_subscriber_in_source PASS=true | 生产源码含 4 信号订阅者 + 唯一实例 getter + 奖励并入结算 + 清波标记清除 + 3 驱动口（A48①/A54/A57）
[V150-WS] existing_tables_zero_change PASS=true | 10 份既有 .tres 前后 md5 全部一致（零改动）
[V150-WS] SUMMARY pass=78 fail=0
[V150-WS] OVERALL=PASS
[V150-WS] RESULT=ALL_MATCH
[V150-WS] === SELFTEST END ===
verify_world_settlement_v150_EXIT=0   SCRIPT_ERROR=0
```

### GATE-3 `--headless --quit`（主场景实证，不加载 `presentation.gd`）

```
[WaveTrial] 持久化基线读回：dungeon.wave_trial.best_wave=3 / dungeon.wave_trial.completed=true / grace.trial.points=1372（经 WorldState.get_flag）
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（如实回读，不冒充 A74 后新基线）
[R35][WaveTrial] 精准弹反生产订阅者已装配：ParryService 唯一实例 + 4 信号 connect（A48①/A54）
[R36][WaveTrial] 专注值/战技生产订阅者已装配：FocusService 唯一实例 + 4 信号 connect（A48①/A54）
[R37][WaveTrial] 元素瓶生产订阅者已装配：FlaskService 唯一实例 + 3 信号 connect（A48①/A54）
[R37][WaveTrial] 死亡轮回生产订阅者已装配：DeathService 唯一实例 + 4 信号 connect（A48①/A54）
[R38][WaveTrial] 大地图野外遭遇生产订阅者已装配：WorldEncounterService 唯一实例 + 4 信号 connect（A48①/A54）
GATE3_EXIT=0   SCRIPT_ERROR=0
```

### 4.5 最终统一三段门禁（`grep SCRIPT ERROR=0`）

```
=== 最终统一三段门禁 grep SCRIPT ERROR=0 ===
  g1.log: SCRIPT_ERROR=0
  g2a_world_encounter_config.log: SCRIPT_ERROR=0      g2a_world_encounter_service.log: SCRIPT_ERROR=0
  g2a_wave_trial_director.log: SCRIPT_ERROR=0
  g2a_verify_world_encounter_v150.log: SCRIPT_ERROR=0 g2a_verify_world_settlement_v150.log: SCRIPT_ERROR=0
  g2b_verify_world_encounter_v150.log: SCRIPT_ERROR=0 g2b_verify_world_settlement_v150.log: SCRIPT_ERROR=0
  g3.log: SCRIPT_ERROR=0
FINAL SCRIPT_ERROR_LINES=0
[V150-WE] SUMMARY pass=49 fail=0   OVERALL=PASS   RESULT=ALL_MATCH
[V150-WS] SUMMARY pass=78 fail=0   OVERALL=PASS   RESULT=ALL_MATCH
```

**PASS/FAIL 汇总**：`49 + 78 = 127 PASS / 0 FAIL`，两份 `RESULT=ALL_MATCH`，`SCRIPT ERROR=0`。

**既有 autoload WARNING（如实登记）**：`--script` / `--headless` 工具模式尾部另有 `[SaveSystem] --script 工具模式…跳过自动读回`、`[ChunkManager] 未找到 ChunkRoot…`、`[R34C][PCO] HUD 未就绪…绑定降级`、`[R36][PCO] A66：FocusService 未就绪…`、`[R37][PCO] A70/A71…`、`[WaveTrial] 未找到 EncounterDirector…降级`、`2 ObjectDB instances were leaked at exit` —— 均为 `WARNING`、**非 `SCRIPT ERROR`、非本轮引入、不影响断言与门禁（`EXIT=0`）**。

---

## 5. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 机制 ① 3 个新文件 + 结算接线 `wave_trial_director.gd` 最小接线 + 2 个 verify + DONE + 回执落地；② 三段门禁 GATE-1 / 2a / 2b / 3 全 `EXIT=0`、最终统一 `SCRIPT ERROR=0`（9 份日志全 0）；③ 两份自测 `RESULT=ALL_MATCH`（127 PASS / 0 FAIL）；④ **10 份既有 `.tres` md5 前后一致（零改动）**，只新增 1 张新表；⑤ `courtyard.tscn` 零改动，GATE-3 实证 `node_count=41`（Rank-1 本轮 A74 改基线由其自行同步）；⑥ A48① 共 4 个新信号**生产订阅者** = `wave_trial_director._bind_world_encounter_signals()`（生产节点）+ GATE-3 装配日志 + 运行时实证（`world_trigger_count` / `world_clear_count` / `world_reward_acc`）；⑦ A54 唯一实例：`get_world_encounter_service()` 两次返回同一实例；⑧ A55/A57 结算闭合：遭遇奖励并入唯一最终结算值、`points_awarded` 取源一致、不二次入账、acc 并入后清零、输出格式零改动；⑨ **A77 既有三波试炼入口可达**：无野外遭遇时结算逐字等价 100；⑩ 纯逻辑边界（I-1 不读写存档 / 不碰渲染 / 不写生产 `delta.json`）——验证脚本显式 `bind_persistence(null,null)` 降级；⑪ 点数只增不减 / 余额非负 / 不重复结算 / 区域清除单调 / 重复触发幂等 / 已清除区域不重复触发 / 异常输入拒绝 机器判定；⑫ 回执已中枢归档（§11） |
| **失败** | 无（Rank-2 自有交付最终无失败项）。如实另记两处 Rank-2 自有中间态：GATE-2a 首检 `verify_world_encounter_v150.gd` 1 条 `Parse Error`（`PackedStringArray` 多参数构造，已修）、GATE-2b 首跑 `pure_logic_no_save_api` 1 条 `FAIL`（断言误伤头注否定声明，已修）；两处均为本轮自有验证脚本、修复复跑后最终全绿（§4.2 / §4.3）。本轮**未遇到其它 Rank 半成品 Parse Error** |
| **需用户确认** | ① 全部 `[PLACEHOLDER]` 数值（分区 id / position / trigger_radius / reward_points / enemy_group / cleared_flag / invalid_input_policy）待人工试玩校准（只改表）；② **分区 id 最终对齐口径**（A76：Rank-1 `world_scale.tres` / Rank-3 `grace_sites.tres` 落定后，只改 `.tres` 的 `region_ids` / `region_id` 两处）；③ Rank-1 运行时输入接线（大地图移动 → `enter_world_region` / `try_world_encounter` 的键位与玩家坐标注入，最终手感需总指挥目视）；④ Rank-3 落盘 flag 命名与 `encounter_cleared` payload 逐项对齐、拒绝事件是否写盘；⑤ headless 真跑无渲染画面，未做 15~20 秒实机录屏回看；⑥ A48③ 完整「真实输入 → 磁盘 / 画面」全链断言回归归 Rank-1 / Rank-3（目录所有权），待四路收尾后由总指挥统一复跑取最终全绿；⑦ 「野外遭遇触发复用既有三波」口径 / 「清波后标记区域已清除」粒度 / cleared_flag 是否跨局持久化（§7） |

---

## 6. 未完成项 / 阻塞

- **A48③ 完整真实可达回归脚本归 Rank-1 / Rank-3**（目录所有权）：本轮提供 GATE-3 主场景实证（不加载 `presentation.gd`、真实 autoload）+ 两份 verify 驱动**真实生产脚本** `wave_trial_director.gd`（非替身 / 不模拟编排）+ 生产订阅者 / 唯一实例 / 结算闭合接口 + 4 信号 + 3 驱动口供接线；完整「真实大地图移动输入 → 生产链路 → 磁盘 flag / 画面」全链断言由 Rank-1（输入层）/ Rank-3（落盘）收尾后由总指挥统一复跑。Rank-2 不越界写。
- **Rank-1 运行时输入接线未由 Rank-2 落地（授权边界，非缺陷）**：`courtyard.tscn` / `hud.gd` / `presentation.gd` 本轮唯一写入方 Rank-1，Rank-2 只读。野外遭遇的**运行时驱动（玩家坐标 / 分区切换 / 触发键位）由 Rank-1 完成**；本轮 Rank-2 已提供稳定签名（§3）+ 3 个驱动口 + 生产订阅者 + 结算闭合链路。接线前导演层不主动触发野外遭遇，清波点数与既有等价（安全降级，正是「不改既有判定分支 / 输出格式」的保证）。
- **分区 id 最终对齐（A76）**：本轮以既有 `m6_area_bindings.tres` 的 `region` 字段为对齐真源（4 个 `[PLACEHOLDER]` id）；Rank-1 `world_scale.tres` / Rank-3 `grace_sites.tres` 本轮门禁期间尚未落盘，最终口径待其收敛后**只改表**对齐（不改代码）。
- **README 状态段 / 迭代文档归 Rank-3**：公共契约「README 长期维护已做/还差什么/资产表」与 `迭代-v0.15.0-大地图与2.5D.md` 由 Rank-3 唯一写入，Rank-2 不越界写；已在本 DONE 完整登记，待总指挥统一同步。
- **实机录屏目视**（公共契约要求 15~20 秒回看）：本轮交付为纯逻辑 + 数据表 + 最小接线 + headless 真跑，无渲染帧缓冲，未录屏；不伪造、列为后续 / 需用户确认。
- **A74~A78 新裁决由 Rank-3 登记**（任务单目录所有权），Rank-2 不越界写；本 DONE 只在 §7 反映接口影响。
- 无阻塞；所有硬约束内工作已完成。

---

## 7. 待总指挥裁决项（只登记、不擅改）

1. **数值校准**：4 个分区 id / 6 个遭遇点的 `position` / `trigger_radius` / `reward_points` / `enemy_group` / `cleared_flag` / `invalid_input_policy` 全部 `[PLACEHOLDER]`，待人工试玩校准；调参唯一入口 `godot/data/rpg/world_encounters.tres`，同步两份 verify 的 `EXPECT_*` 与本文数值表。
2. **分区 id 对齐口径（A76）**：本轮取既有 `m6_area_bindings.tres` 的 `region` 字段（`limgrave / weeping_peninsula / stormveil / siofra_well`）；请裁决是否与 Rank-1 `world_scale.tres` / Rank-3 `grace_sites.tres` 的最终分区 id 完全一致，若不同则只改表两处对齐（不改代码）。
3. **「野外遭遇触发时复用既有三波 / 导演层结算」语义口径（A77）**：本轮实现为「触发只标记 active 遭遇 + 累计奖励来源，战斗胜利仍走既有 `on_encounter_finished(true)` → `_clear_wave()` 结算，清波后自动标记区域已清除」，**不改动既有三波试炼入口与分支**。请裁决是否符合「野外遭遇触发时复用既有三波」预期，或需改为「触发时显式 `start_trial()` 起一轮」（注：后者会与既有自动开始 / 演示序列双驱动，需先定口径再改代码 + 回归）。
4. **「清波后标记区域已清除」粒度**：本轮以**遭遇点级** `cleared_flag` 为准（单遭遇区域全清即「区域已清除、不重复触发」）；请裁决是否需改为「区域级一次性标记」（需新增区域状态字段）。
5. **`cleared_flag` 是否跨局持久化**：本轮 I-1 不读写存档，`reset()` 每场新一局清空清除态（与 v0.1~v0.14 纯逻辑服务一致）；请裁决是否需由 Rank-3 落盘跨局保留（需新增 flag + 重启读回，属 Rank-3 目录所有权）。
6. **Rank-3 落盘 flag 口径**：建议订阅 `encounter_cleared(encounter_id, region_id, cleared_count)` 登记 `world.map.region_<id>.cleared` / `world.map.progress` 三段式 flag；请裁决 payload 与 flag 命名逐项对齐，以及 `trigger_rejected` 是否需要落盘（Rank-2 建议「拒绝事件不写盘、只走 HUD 反馈」），`reward_points` 已由导演层并入结算、Rank-3 不二次入账。
7. **实机录屏回看 / 既有 autoload WARNING**：headless 真跑无帧缓冲，按公共契约如实登记为后续动作 / 需用户确认（不冒充目视通过）；既有 WARNING 非本轮引入，是否纳入后续清理由总指挥裁决。
8. **四路收尾后最终统一复跑**：本轮 Rank-2 三段门禁最终统一 `SCRIPT ERROR=0`；请裁决 Rank-1（A74 改 `courtyard.tscn` / HUD）/ Rank-3（落盘）/ Rank-4（录屏）全部收尾后由总指挥统一复跑三段门禁取最终全绿。

---

## 8. A48 硬要求落地声明（逐条）

| A48 | 落地 | 证据 |
|---|---|---|
| ① 新信号必须有**生产运行时订阅者**（不能只在验证脚本） | `wave_trial_director.gd`（挂 `courtyard.tscn` 的生产节点）在 `_init_combat_services()` 装配时调 `_bind_world_encounter_signals()`，connect 全部 4 信号到 `_on_world_*` 生产回调；回调有真实职责（acc 累计 / active 记录 / 计数 / 清 active / 拒绝记录），非空订阅 | `production_subscriber_in_source`（两份 verify）/ `a48_trigger_subscriber_runtime` / `region_cleared_after_wave`（`world_trigger_count` / `world_clear_count` / `world_reward_acc`）/ GATE-3 `[R38][WaveTrial]` 装配日志 |
| ② 遵守 A54 唯一实例（从既有导演层 `get_*_service()` 复用） | `_world` 唯一实例由 `wave_trial_director.gd` 装配，`get_world_encounter_service()` 暴露；Rank-1 / Rank-3 / Rank-4 经该 getter 复用，绝不 new 第二个 | `a54_single_instance`（两次 getter 同一实例）/ `a54_world_service_present` / GATE-3 装配日志 / §3.7 接线示意 |
| ③ 一条**不加载 `presentation.gd`、不在验证脚本内模拟编排**的真实可达回归 | GATE-3 `--headless --quit` 主场景真跑（真实 autoload `PointsCommitOrchestrator`、不加载 `presentation.gd`）实证生产链路；两份 verify 驱动的是**真实生产脚本** `wave_trial_director.gd`（`real_production_director`），结算值经真实 `_clear_wave()` 产出，不在验证脚本内自建替身 / 模拟编排 | GATE-3 R38 装配日志 + `node_count=41`；`real_production_director` / `production_subscriber_in_source`；完整「真实输入 → 磁盘 / 画面」断言脚本归 Rank-1 / Rank-3（目录所有权），见 §6 / 裁决项 8（如实登记，不冒充） |
| ④ 纯逻辑 + 单元断言不算可玩交付 | 本轮交付纯逻辑 + 数据表 + 最小接线 + headless 真跑；**未做 15~20 秒实机录屏回看**，如实列为未完成 / 需用户确认，不冒充可玩交付 | §5 需用户确认 / §6 未完成项 |

---

## 9. 硬约束遵守声明

- `courtyard.tscn` / `hud.gd` / `presentation.gd` / `points_commit_orchestrator.gd` / `project.godot` / `impact_feedback.gd` / 场景 / 素材 / 其它 Rank 文件**只读未改**；`courtyard.tscn` 节点数 `41` 未破坏（GATE-3 实证，A74 后新基线由 Rank-1 同步）。
- 既有 `.tres` 数值零改动（10 份 md5 前后一致），只新增 `world_encounters.tres` 一张新表。
- 纯逻辑（I-1）：`WorldEncounterService`（RefCounted）/ `WorldEncounterConfig`（Resource）均不 `add_child` / 不 `get_tree()` / 不 `/root/...` / 不 `open(user://)` / 不 `set_flag` / 不 `commit` / 不写 `removals` / 不写 `.tres` / 不回退 `grace.trial.points` / 不碰渲染；`wave_trial_director.gd` 接线只在 `_clear_wave()` / `_reset_r34_records()` / 生产订阅回调 / 驱动口几处消费数据、不写盘；验证脚本显式 `bind_persistence(null,null)` 降级，全程不触碰 `user://slot_01/delta.json`。
- 不改既有判定分支 / 帧数据 / 输出格式 / 既有 `.tres` 数值：`wave_cleared.emit(_index, pts)` 第二参仍为基础 `pts`；`get_snapshot()` 既有 27 + R34 8 + R35 8 + R36 11 + R37 14 个 key 逐字不动，只追加 10 个只读 key；`get_settlement_snapshot()` 只追加 2 个只读 key；无野外遭遇时 `_world_reward_acc=0` 使结算逐字等价（A77）。
- Godot4 自测纪律：`extends SceneTree` 用 `Engine.get_main_loop() as SceneTree` 取 root，`add_child(d)` 后显式 `d.call("_ready")`（不依赖自动 flush），资源回读 `CACHE_MODE_IGNORE`；不用 `get_tree()`、不用 `/root/...` 绝对路径。
- 零付费、零外部依赖、不启 GPU job；不伪造产物、不谎报成功、不自行 git；未删除 `.workbuddy`。
- 默认不刺探：未扫目录做进度巡检、未写只读探针 / 巡检脚本；仅按任务单要求读必做文件、为对齐分区 id 读既有 `m6_area_bindings.tres` / `world_baseline.tres` 与同轮任务单、按 SCRIPT ERROR `at:` 行核验归属、核对回执目录与中枢归档结构。

---

## 10. md5 零改动结论（既有表）

`verify_world_settlement_v150.gd` 在**同一进程内**于全部接线 / 结算断言之前记录 `before`、之后记录 `after`，逐份 `FileAccess.get_md5()` 对比，10 份既有 `.tres` 全部 `PASS=true`：

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
| 10 | `focus_rules.tres` | `289fd4f08424658d9625fd3ac3d93bfd` | 同 | 零改动 |

**`existing_tables_zero_change PASS=true | 10 份既有 .tres 前后 md5 全部一致（零改动）`。** 10 份 md5 与 `DONE-R37.md §10` 登记值逐字一致 —— 交叉佐证既有表数值零改动。
本轮只新增 1 张表：`world_encounters.tres`（`a36085c8b3abff719ac0f7dbb62a195f`），验证脚本同样前后一致、未写入。**既有 `.tres` 数值零改动。**

---

## 11. 回执与中枢归档确认（写后已确认）

- 回执写入 Rank-2 授权路径（**`teamwork/command_center/`，非工程根**）：
  `teamwork/command_center/ai/2/outbox/cmd-20261112-234238-650-A2.json`，
  四字段 `{"task_id", "ai":2, "status":"done", "result"}`。

### 归档确认（写后回读确认，如实登记、不伪造）

- 回执写入 `teamwork/command_center/ai/2/outbox/cmd-20261112-234238-650-A2.json` 后，经中枢轮询**已归档**：`ai/2/outbox/` 按中枢流程归档后已清空（回执移入 `dispatcher/receipts/`）；不重放、不伪造。
- **归档副本**：`teamwork/command_center/dispatcher/receipts/cmd-20261112-234238-650-A2.json`，回读 **VALID_JSON**，`keys=['ai','result','status','task_id']` 四字段齐全，`task_id=cmd-20261112-234238-650-A2` / `ai=2` / `status=done` / `result_len=1673`，与 outbox 回执逐字一致。
- `teamwork/command_center/ai/2/status.json` 更新为 `{"ai":2,"state":"idle","current_task":"","completed":46,"last_seen":"2026-11-13 00:01:32"}`（`completed` 由 45 → 46、`current_task` 清空、`state` → idle）。
- `dispatcher/ledger.jsonl` 本任务单 `cmd-20261112-234238-650-A2` 已登记（派单 `issued_at=2026-11-12 23:42:39` 与任务单一致）。
- `dispatcher/dispatcher.log` 尾部：`[2026-11-13 00:01:32] ← 2 号 AI 回执 <cmd-20261112-234238-650-A2> 完成：见 teamwork/Rank-2/DONE-R38.md 实际结论…`（回收验证 `done`）。
