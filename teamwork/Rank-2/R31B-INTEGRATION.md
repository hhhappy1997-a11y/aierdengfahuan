# R31B-INTEGRATION.md · 试炼词条运行时接线清单（R31B 遗留由 R32 合并补齐）

> 归属：Rank-2（战斗系统与数据驱动）。本文件只描述「接线清单 / broken 判据 / 待裁决项」，
> 不改任何其它 Rank 文件、不改契约、不改既有 `.tres` 数值。
> 真源：`teamwork/Rank-2/调度任务单-latest.json`（R32 id `cmd-20261112-074023-393-A2` ④）
> 与 R31B 补回执 id `cmd-20261111-141611-501-A2`。
> 背景：上一轮四条 R31B 派单因执行进程通道故障未接单，本轮由 R32 合并补齐，
> 结论详见 `teamwork/Rank-2/DONE-R31B.md`。

---

## 1. 本轮补齐产物（可落地件）

| 文件 | 归属 | 作用 |
|---|---|---|
| `godot/scripts/combat/verify_trial_modifier_runtime_v090b.gd` | Rank-2 | 用 `ResourceLoader.load(..., CACHE_MODE_IGNORE)` 回读真实 `trial_modifiers.tres` 与 `wave_trial.tres`，实例化 `TrialModifierService` 做三词条结算回归，并做 md5 前后对比证明既有 `.tres` 零改动 |
| `teamwork/Rank-2/R31B-INTEGRATION.md`（本文件） | Rank-2 | 接线清单 + broken 判据 + 待裁决项 |

既有只读依赖（本轮**零改动**）：`godot/scripts/combat/trial_modifier_config.gd` /
`trial_modifier_service.gd` / `godot/data/rpg/trial_modifiers.tres` /
`godot/scripts/combat/wave_trial_config.gd` / `godot/data/rpg/wave_trial.tres` /
`godot/scripts/combat/verify_trial_modifier_v090.gd`。

---

## 2. 接线清单（谁调用 / 数据从哪来 / 谁落盘）

### 2.1 service 由谁调用

- `TrialModifierService`（RefCounted 纯逻辑）**不自己接线、不自己触发**。运行时代理由
  **Rank-1 波次导演层**（`wave_trial_director.gd` / `encounter_director.gd`，A44 唯一写入方）
  在「每波清波结算」时实例化并注入 `TrialModifierConfig`（从
  `res://data/rpg/trial_modifiers.tres` 读），按词条编排调用：
  - `select(id)`：选择本局词条（合法性 / 互斥组由服务判定，拒绝产物交回编排层）；
  - `clear()`：切换 / 取消词条；
  - `settle(base_points, stats)`：产出 `total_points / bonus_points / balance / modifier_id /
    reward_multiplier / condition_met / reason`。
- 编排层把 `settle()` 的 `total_points` 交给**点数结算链路**（见 2.4），把
  `modifier_id` 交给 HUD / 打击反馈层（Rank-1 消费）做画面呈现。
- Rank-2 只交付纯逻辑与数据表，**不写运行时接线代码**（`encounter_director.gd` 本轮
  Rank-2 只读不改，唯一写入方 Rank-1）。

### 2.2 stats 来源

`settle(base_points, stats)` 两个入参：

- `base_points`（int）：来自 **`wave_trial.tres` 每波 `reward_points`**（首版
  `[PLACEHOLDER]` 100 / 150 / 200，经 `WaveTrialConfig.get_wave(i).reward_points` 读），
  或导演层本波实际奖励基数；须 `>= 0`。
- `stats`（Dictionary）字段（与 `trial_modifier_service.gd::_condition_met` 一致）：
  - `damage_taken`：运行时受击次数（`no_hit` 判定 `<= 0`）——来自玩家受击事件累计；
  - `elapsed_sec` / `time_limit_sec`：本波已用时 / 时限（`time_pressure` 判定
    `elapsed_sec <= time_limit_sec × time_limit_scale`）；`time_limit_sec` 取自
    `wave_trial.tres` 每波 `time_limit_sec`（首版 30.0）；
  - `hp_ratio`：玩家当前血量比例（`low_vigor` 判定 `<= hp_scale`）——来自玩家生命组件。
- 缺字段 / 类型异常一律判「条件未达成」→ 回落基础结算，不崩、不惩罚。

### 2.3 词条参数真源

三词条的 `reward_multiplier / time_limit_scale / hp_scale / exclusive_group` 全在
`godot/data/rpg/trial_modifiers.tres`（首版 `[PLACEHOLDER]`：1.5 / 1.3 / 1.4、
1.0 / 0.6 / 1.0、1.0 / 1.0 / 0.5、survival / tempo / survival）。
**调参唯一入口 = 该 `.tres`，只改表不改代码**；校准需同步
`verify_trial_modifier_v090.gd` 与 `verify_trial_modifier_runtime_v090b.gd` 的 `EXPECT_*`。

### 2.4 落盘责任 Rank（I-1）

- **写方唯一权威 = Rank-3**（契约 §3.3 R31 段）：词条编排在 Rank-2 服务判定通过后，
  由 Rank-3 经 `set_flag("grace.trial.modifier_active", <id 或 "">)` 与
  `commit("trial_modifier_applied")` **同一原子写先落盘**，再更新运行时实例、emit
  `flag_changed`。`grace.trial.points` 只增不减、绝不写 `removals`。
- **Rank-2 纯逻辑边界（I-1）**：`TrialModifierService` 不继承 Node、不碰场景树、
  不 `add_child`、不调用 `get_tree()` / `/root/...`、不 `open(user://)`、不 `load`
  生产 `delta.json`、不调用 `set_flag` / `commit`、不碰渲染、不落盘。
- README「先落盘再改运行时实例」五步顺序沿用契约 §3.3（R26 §6.4 / R27 §9.9 / R31）。

---

## 3. broken 判据（回归机器判定）

| 判据 | 含义 / 触发条件 | 机器判定入口 |
|---|---|---|
| **词条失效** | `select(id)` 后 `settle()` 不按倍率结算；条件判定（无伤 / 限时 / 低血量）失效；`reason` 异常；`clear()` 后未回落基础 | `verify_trial_modifier_v090.gd`（结构 / 条件 / 单调）+ `verify_trial_modifier_runtime_v090b.gd`（真表回读结算） |
| **奖励通胀** | 多词条生效倍率被**叠乘**而非取 `max`；`total_points < base_points`；`bonus_points < 0`；重复 `settle` 重复给点；倍率 `< 1.0` | `verify_trial_modifier_v090.gd` F 组（`max_not_multiply`）+ `verify_trial_modifier_runtime_v090b.gd`（`settle_max_not_multiply`）+ `is_multiplier_set_valid()` |
| **存档越权** | Rank-2 服务出现 `set_flag` / `commit` / `FileAccess.open(user://)` / `load` 生产存档 / `add_child` / `get_tree()` 等越界调用 | 代码审查（服务头注纯逻辑边界）+ 本轮两个 verify 全程只读；`verify_v090_save_readback.gd`（Rank-3）负责落盘读回 |
| **表被意外改写** | `trial_modifiers.tres` / `wave_trial.tres` 的 md5 前后不一致，或回读数值偏离首版 `[PLACEHOLDER]` | `verify_trial_modifier_runtime_v090b.gd` 的 `md5_*_zero_change` + `mult_ph[*]` / `wave_reward[*]` |

> 本轮实测：`trial_modifiers.tres` md5 `7e9e5ac7d35d8d15171e69975ac3356d`、
> `wave_trial.tres` md5 `793b6daa7c7730feed1a3f849701d58a`，前后一致，零改动。

---

## 4. 待裁决项（交总指挥 / 相关 Rank，不私自改契约）

1. **运行时接线落地方与时机**：词条编排层（谁实例化 `TrialModifierService`、
   `select(id)` 由哪个 UI / 时机触发、`settle()` 在 `wave_cleared` 哪一步调用）属
   **Rank-1 导演层**接线。本轮 Rank-2 未改 `encounter_director.gd`（A44 唯一写入方
   Rank-1），仅交付纯逻辑 + 数据表 + 验证；接线未落地前词条在运行时不生效，
   请总指挥确认由 Rank-1 本轮或后续回合接入。
2. **词条 UI / 打击反馈消费**：`modifier_active` 的 HUD 呈现与打击反馈门控由
   Rank-1（`hud.gd` / `impact_feedback.gd`）消费，Rank-2 不碰渲染；展示口径以
   契约 §3.3 R31 段为准。
3. **`stats` 的 `damage_taken` / `hp_ratio` 统计口径**：由玩家受击 / 生命组件提供，
   属跨模块运行时数据，具体由哪一层汇总（导演层 / 玩家组件）待 Rank-1 编排时确认；
   Rank-2 服务只按字段判定、不采集。
4. **三词条倍率 / 时限 / 血量 `[PLACEHOLDER]` 校准**：首版 1.5 / 1.3 / 1.4、
   0.6、0.5 待人工试玩校准；校准只改 `trial_modifiers.tres`，同步两个 verify 的
   `EXPECT_*` 与 DONE 数值表。
5. **R31B 与 R32 回执合并不消歧**：R31B 四条历史派单未接单的事实与本轮合并补齐
   结论分开登记（另写回执 `cmd-20261111-141611-501-A2.json` + `DONE-R31B.md`），
   不与 R32 回执合成一条，口径以本任务单为准。
