# TRIAL-MODIFIER-TUNING.md — 试炼词条数值假设表 + broken 定义（R31 / v0.9.0 / Rank-2）

> 真源：`teamwork/Rank-2/调度任务单-latest.json`（id `cmd-20261111-133549-883-A2`）任务单 ①⑤。
> 数值真源：`godot/data/rpg/trial_modifiers.tres`（3 项实例）；结构/降级/纯函数在 `godot/scripts/combat/trial_modifier_config.gd`；纯逻辑结算在 `godot/scripts/combat/trial_modifier_service.gd`。
> 目录所有权·R31：本文件与上述 3 个 `godot/` 文件、2 个 `verify_*_v090.gd`、`DONE-R31.md` 归 Rank-2；既有 `.tres` / 导演层 / `hud.gd` / 场景 / 素材 / 其它 Rank 文件**一律只读、不改**。
> 所有新数值均为 **`[PLACEHOLDER]` 首版假设、待人工试玩校准**；**调参唯一入口只改 `.tres` 不改代码**（`trial_modifier_config.gd` 的 `DEFAULT_*` 是非法输入降级基线，不是设计数值）。
> 关联：`CODEX-GDD.md` §9/§10（图鉴奖励回流 `grace.trial.points`）、`00-协作契约.md` §3.3（三段式 flag / 余额 `points − spent_points ≥ 0`）。

---

## 1. 数值假设表（`[PLACEHOLDER]`，唯一真源 `trial_modifiers.tres`）

| id | title | reward_multiplier | time_limit_scale | hp_scale | exclusive_group | 条件语义（`stats`） |
|---|---|---|---|---|---|---|
| `no_hit` | 试炼词条·无伤 | **1.5** | 1.0 | 1.0 | `survival` | `damage_taken <= 0` |
| `time_pressure` | 试炼词条·限时 | **1.3** | **0.6** | 1.0 | `tempo` | `elapsed_sec <= time_limit_sec * time_limit_scale` |
| `low_vigor` | 试炼词条·低血量 | **1.4** | 1.0 | **0.5** | `survival` | `hp_ratio <= hp_scale` |

> `title` / `description` 为展示文案，非数值；三项均落在 `.tres` 一处。

### 1.1 rationale（为什么是这组数）

- **倍率梯度 1.3（限时） < 1.4（低血量） < 1.5（无伤）**，与达成难度同向；三者**互异且均 ≥ 1.0**，保证「奖励单调不减 / 余额非负」——词条只加成、绝不扣减基础点数。
- `no_hit` 1.5：无伤是最高操作门槛，给最高档；不改时限/血量（`time_limit_scale=hp_scale=1.0`），避免与其它难度叠加把条件推到不可达。
- `time_pressure` 1.3：把既有波次 `time_limit_sec=30.0` 压缩到 60%（0.6 → 18 秒），属「节奏」压力；倍率低于无伤（限时可背板熟悉路线），单独成 `tempo` 组允许与 `survival` 词条共存。
- `low_vigor` 1.4：起始血量压到 50%（0.5），风险介于无伤与限时之间，倍率居中；与 `no_hit` 同属 `survival` 组**互斥**，避免「无伤 + 半血」双重生存限制叠加导致条件不可达。
- `time_limit_scale` / `hp_scale` 取值域 **(0, 1]**；`1.0` 表示「不改动该维度」；压缩比例是**阈值本身**，改表即改判定，不改代码。

### 1.2 `stats` 字段约定（`settle(base_points, stats)` 入参）

| 字段 | 类型 | 语义 | 缺失/类型异常时 |
|---|---|---|---|
| `damage_taken` | int/float | 本局受击次数 | 该词条判「未达成」→ 回落基础结算，不崩、不惩罚 |
| `elapsed_sec` | int/float | 本局用时（秒） | 同上 |
| `time_limit_sec` | int/float | 波次时限基准（既有 30.0） | 同上 |
| `hp_ratio` | int/float | 结算时剩余血量比例 [0,1] | 同上 |

### 1.3 结算规则（写进 `trial_modifier_service.gd`，数值全来自表）

1. 未选词条 → `total = base_points`（基础结算）；`clear()` 清空选择态。
2. 已选但条件未达成 → `total = base_points`（**回落基础，绝不惩罚**）。
3. 已选且条件达成 → 生效倍率取「**达成词条中的最大 `reward_multiplier`**」（`max`，**不叠乘**），`total = floor(base_points * 倍率)`。
4. 成功结算恒 `total >= base_points`（单调不减）、`balance = total >= 0`（余额非负）、`bonus = total − base >= 0`。
5. 异常输入（负 `base_points` / `stats` 非 Dictionary / 表缺失 / 非法表项）→ `ok=false`，不产出任何点数（`total=0 / balance=0 / bonus=0`）。

> 既有数值（**只读引用，不在本表内、不得改动**）：教学 `reward_points` 20/30/50（合计 100）、三波 100/150/200（合计 450）、成长 `cost` 100/200/300（合计 600）、图鉴 `reward_points` 30/50/80/120（合计 280）。`verify_codex_full_wish_v090.gd` 按这些真值动态聚合判定满愿 4/4 可达性。

---

## 2. broken 定义（4 类校准判据）

> 判据全部由 `verify_trial_modifier_v090.gd` / `verify_codex_full_wish_v090.gd` 机器判定；命中任一即「broken」，如实登记、不静默改数、不伪造通过。

### B1 词条互斥失效

- **定义**：同一 `exclusive_group` 的两个词条被同时选中，或跨组共存时倍率被**叠乘**（而非取 max），使挑战难度/奖励突破设计上限。
- **判据**：`select("no_hit")` 后再 `select("low_vigor")` 未被 `REASON_EXCLUSIVE` 拒绝；或 `no_hit + time_pressure` 双达成时 `total > 150`（出现 1.5×1.3=1.95 叠乘）。
- **回调方向**：修 `select()` 的「同组拒绝」门控与 `settle()` 的「取 max 不叠乘」；调表时核对 `exclusive_group` 分组（本轮 `survival` = no_hit + low_vigor，`tempo` = time_pressure）。

### B2 奖励通胀

- **定义**：词条或图鉴奖励产生「超过设计倍率的额外点数」或「可反复刷的二次入账」，破坏 `grace.trial.points` 的经济平衡。
- **判据**：任一 `reward_multiplier < 1.0`；成功结算 `total < base_points` / `bonus < 0` / `balance < 0`；多词条倍率叠乘；图鉴成就奖励合计 280 明显高于单轮三波产出 450（第二套点数来源）。
- **回调方向**：下调 `.tres` 的 `reward_multiplier`（保持互异、≥1.0、梯度单调）；`settle` 取 max；图鉴奖励维持一次性、合计低于单轮三波产出。

### B3 条件不可达

- **定义**：词条条件在正常游玩路径下**恒为 false**，或图鉴 `all_grace_upgrades` 的循环依赖被绕过（买成长前预支其 80 点奖励），导致「满愿 4/4」被伪造。
- **判据**：`time_limit_scale` / `hp_scale` 过小使 `elapsed_sec` / `hp_ratio` 永远无法满足；条件引用的 `stats` 字段生产侧从不写入；`verify_codex_full_wish_v090.gd` 中「买成长前 `all_grace_upgrades` 条件=false」断言被打破；按真值算出 `SHORTFALL_POINTS > 0` 却仍报 4/4。
- **回调方向**：在 `.tres` 上调 `time_limit_scale` / `hp_scale` / 阈值（不静默改既有表）；模拟严格分「买成长前 / 买成长后」两阶段领取；若真不可达，**如实输出 `UNREACHABLE` + 缺口点数**，不改既有表数值、不伪造 4/4，交总指挥裁决。

### B4 重复领取

- **定义**：同一图鉴成就 / 词条奖励被二次入账，`points` 二次累加、`n/4` 二次推进，破坏单向成就与 `points` 只增不减的语义。
- **判据**：`_claimed` 幂等门控失效（同 id 二次 `claim` 成功）；4 项二次领取后 `points` 变化；`commit` 次数异常；`grace.codex_<id>.unlocked` 出现 `true → false` 回写。
- **回调方向**：`_claimed` 单向置位 + 三段式 `grace.codex_<id>.unlocked` 只 `false→true` + `commit` 先落盘；`verify_codex_full_wish_v090.gd` 的「无重复领取」断言守护。

---

## 3. 校准同步清单（不静默改数）

`godot/data/rpg/trial_modifiers.tres`（**唯一入口**）→ `verify_trial_modifier_v090.gd` 的 `EXPECT_*` → 本文件 §1 数值表 → `DONE-R31.md` → 三段门禁 `--headless --import` → `--check-only --script` / `--headless --script <verify>` → `--headless --quit` + `grep SCRIPT ERROR=0`。

> 既有 4 张 `.tres`（教学 / 三波 / 成长 / 图鉴）数值**本轮一律只读**；若 `verify_codex_full_wish_v090.gd` 判定不可达，缺口如实登记、由总指挥裁决是否调表，Rank-2 不擅自改数。
