# GRACE-UPGRADE-TUNING.md · R27 / v0.5.0 赐福点数兑换数值假设、防刷判据与人工校准手册

> 工位 **Rank-2（战斗系统与数据驱动）**｜命令 `cmd-20261111-083350-239-A2` `[ROUND=R27]`
> 真源：`teamwork/Rank-2/调度任务单-latest.json`｜引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（v4.7.2.stable）
> 定位：**人工试玩校准**用的数值假设表 + **防刷判据** + 「broken」定义 + 效果接线边界如实登记。
> 所有首版数值取自任务单建议/示例，一律标 `[PLACEHOLDER]`，不拍脑袋写死；本文件与 `.tres` / verify 期望常量三者需同步维护。

---

## 0. 一句话口径与文件分工

| 职责 | 文件 | 谁改 |
|---|---|---|
| **数值唯一真源**（3 项实例） | `godot/data/rpg/grace_upgrades.tres` 的 `upgrades` 数组 | 人工试玩后只改这里 |
| 结构 / effect_key 白名单 / 降级 / 静态类型视图 | `godot/scripts/combat/grace_upgrade_config.gd`（`class_name GraceUpgradeConfig`） | Rank-2，不写设计数值 |
| 购买判定 / 幂等防刷纯逻辑 | `godot/scripts/combat/grace_upgrade_service.gd`（`class_name GraceUpgradeService`） | Rank-2 |
| 三段式 flag 读取 + 运行时接线 + 购买落盘 | `godot/scripts/combat/grace_upgrade_runtime.gd`（`class_name GraceUpgradeRuntime`，**独立节点脚本**） | Rank-2 |
| 自测断言（PASS/FAIL/RESULT） | `godot/scripts/combat/verify_grace_upgrade_v050.gd`（`extends SceneTree`，127 条） | Rank-2，校准后同步 `EXPECT_*` |
| 读表 / 组织战斗 / 波次 HUD / 场景装配 | `wave_trial_director.gd` / `encounter_director.gd` / `courtyard.tscn`（**Rank-1 独占**） | Rank-1，本轮不碰（裁决 A22） |

> 改数值**只改 `.tres`**，不改代码 / 导演层 / 场景 / 素材 / 契约 / README（目录所有权硬约束）。

---

## 1. 三项首版数值表（全部 `[PLACEHOLDER]`）

| # | `id` | `display_name` | `cost` | `effect_key` | `effect_value` | 既有落点（文件:行） |
|---|---|---|---|---|---|---|
| 1 | `hp_max_bonus` | 赐福·生命上限 | **100** | `hp_max` | **+20.0** | `encounter_director.gd:30` `@export player_max_hp=100.0` |
| 2 | `roll_iframe_bonus` | 赐福·翻滚余韵 | **200** | `roll_iframe` | **+1.0** | `player_actions.tres:97-98` `action_04_roll.invulnerable_end_frame=13`（`PlayerActionState.is_invulnerable()` 读） |
| 3 | `attack_power_bonus` | 赐福·攻击强化 | **300** | `attack_power` | **+5.0** | `player_actions.tres:128,155` `action_05/06.base_attack=85.0`（`EncounterDirector._compute_damage()` 读） |

- 3 项 `cost` **严格递增** `100<200<300`，与「三波试炼累积点数」经济曲线同向；3 个 `effect_key` **全部命中既有落点**，无「找不到落点」降级项（任务单 ② 硬要求已核对，逐项见上表右侧）。
- 点数来源：`wave_trial.tres` 三波 `reward_points = 100/150/200`，一轮全清累计 **450** 点（既有 `grace.trial.points`，由 Rank-1 波次导演累计）。

### 逐字段 rationale（为什么是这个值 / 待校准什么）

| 字段 | 首版来源 | `[PLACEHOLDER]` rationale / 待校准点 |
|---|---|---|
| `cost=100` | 任务单建议 100/200/300 | 与第 1 波奖励 100 对齐，「一轮试炼换一项」；若一轮全清 450 仍买不起第 1 项则门槛过高（B1）。 |
| `cost=200` | 任务单建议 | 落在前两波奖励之和（100+150=250）内，定位中期兑换；与第 1 项拉开梯度。 |
| `cost=300` | 任务单建议 | 约为一轮全清 450 的大头，定位后期兑换/跨局累积；若一局即可买齐三项且余点过多则门槛过低（B2）。 |
| `effect_value=20.0`（hp_max） | 任务单示例 +20 | 约为既有 `player_max_hp=100.0` 的 +20%，「可感知但不破坏一击线」的保守首版；`incoming_damage=12.0` 下约多扛 1~2 下。 |
| `effect_value=1.0`（roll_iframe） | 任务单示例 +1 | 60fps 下约 16.7ms，无敌窗口 `[4,13)` → `[4,14)`，是最小可读增量；避免翻滚过强破坏 Boss 招式压力。 |
| `effect_value=5.0`（attack_power） | 任务单示例 +5 | 约为 `base_attack=85.0` 的 +5.9%，对 `A×M×P×S−D` 伤害式是温和增幅；重击 `motion_multiplier=1.65` 会同步放大，试玩需复核。 |
| `display_name` | 本轮自拟 | 仅展示用中文文案，不参与任何数值/判定；可随 UI 文案调整，无需改代码。 |

> 三项 `cost` 与 `effect_value` 全部为任务单建议/示例的 `[PLACEHOLDER]` 首版，**不是定论**，待人工试玩按 §4 broken 判据校准。

---

## 2. 代码里的 `[PLACEHOLDER]` 降级基线（**不是设计数值**）

`grace_upgrade_config.gd` 的 `DEFAULT_*` 常量只在「Dictionary 缺 key / 空表」时兜底，保证不崩、且能被 `is_upgrade_valid()` 判非法。

| 常量 | 值 | rationale |
|---|---|---|
| `DEFAULT_ID` | `""` | 缺 id 判非法，强制人工补，绝不静默塞一项增益 |
| `DEFAULT_DISPLAY_NAME` | `""` | 缺名称判非法（避免展示空白项） |
| `DEFAULT_COST` | `0` | 0 成本判非法，避免凭空免费刷增益 |
| `DEFAULT_EFFECT_KEY` | `""` | 空 key 不在白名单，判非法（不伪造生效） |
| `DEFAULT_EFFECT_VALUE` | `0.0` | 0 增益判非法，避免无效兑换 |

降级路径：`upgrade_from_dict(d)` 对缺 key / 类型异常回落到上述基线；`get_upgrade(index)` 越界返回 `null`；空表 `get_upgrade(0)` 返回 `null` 不崩。均由 verify「空表/字段缺失降级」断言覆盖。

---

## 3. 防刷判据（本轮核心，逐条可机器判定）

点数消费模型：**余额 = `grace.trial.points` − `grace.trial.spent_points`**；消费**只增 `spent_points`**，绝不减少总点数、绝不 `removals`。

| # | 判据 | 实现落点 | 违反时的表现 | verify 断言 |
|---|---|---|---|---|
| F1 | **重复购买同一 id 必须被拒绝** | `GraceUpgradeService._purchased_ids` 一旦置位，`can_purchase()` 恒 false；`purchase()` 返回 `reason=duplicate_id`，`spent_points` 不变 | 同一 id 第二次购买仍扣点、或 `_purchased_ids` 被 erase | `dup_*` 8 条 + `flag_buy_hp_duplicate_*` 2 条 |
| F2 | **`spent_points` 单调递增、绝不回退** | `purchase()` 以 `max(内部累计, 外部传入) + cost` 为基准；外部传入落后值不把累计拉回退 | 传入 `spent=0` 而内部已 500 时新值应为 600 而非 100 | `spent_monotonic_no_rollback` / `flag_spent_points_monotonic_600` |
| F3 | **余额非负 + 余额 < cost 拒绝** | `can_purchase()` 校验 `points>=0 / spent_points>=0` 且 `balance>=cost`；成功购买后 `balance = points - spent >= 0` | 余额为负仍放行、或成功购买后余额为负 | `insufficient_*` / `balance_all_nonneg` / `balance_spent_le_points` |
| F4 | **绝不 `removals`** | 服务只增 `_purchased_ids`、不 erase；接线只 `set_flag(bought_<id>, true)`，从不删除任何 flag；`_delta.removals` 恒空 | 购买后 `bought_*` 消失、`_delta.removals` 非空 | `no_removals_flags_intact` / `no_removals_array_empty` |
| F5 | **绝不回退 `grace.trial.points`** | 该 key 在 service / runtime 中**只读**；`purchase()` 返回的 `points` 是原值；`try_purchase()` 从不 `set_flag(FLAG_POINTS, ...)` | 购买把总点数改小、或 `set_flag` 写了该 key | `flag_points_never_rolled_back` / `normal_buy_hp_points_unchanged` |
| F6 | **异常输入一律拒绝、不崩** | `null / 非 Dictionary / 缺字段 / 空 id / 负或 0 cost / 未知 effect_key / 负 effect_value / 类型错 / 负点数` → `can_purchase=false`、`purchase(ok=false)` 且不扣点 | 抛异常、或非法输入被放行 | `abnormal_*` 15 条 |
| F7 | **同进程重复 apply 不叠加** | `GraceUpgradeRuntime._applied_ids` 防重复叠加（HP/iframe/attack 不会被叠两次） | 同进程再次 `apply_purchased()` 把 +20 叠成 +40 | `wiring_idempotent_no_double_stack` |
| F8 | **先置 flag 再 commit，且仅成功时落盘** | `try_purchase()`：`set_flag(spent_points)` → `set_flag(bought_<id>)` → `writer.commit("grace_upgrade_purchased")`；购买失败直接 return，不 commit | 失败也 commit、或先改运行时再落盘 | `flag_buy_hp_committed` / `flag_buy_hp_commit_reason` |

**三段式 flag key（全部符合 `WorldState` 正则 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`，verify 断言）**：

| key | 方向 | 语义 |
|---|---|---|
| `grace.trial.points` | **只读**（既有，Rank-1 波次导演累计） | 累积赐福点数，绝不回退 |
| `grace.trial.spent_points` | **只增**（本轮新增） | 消费累计；余额 = points − spent |
| `grace.trial.bought_<id>` | **只置 true**（本轮新增，每项一个） | 已购标记，F1 重复购买判定的落盘真值 |

> 重启进程后 `GraceUpgradeService.load_state(spent, purchased_ids)` 从上述 flag 恢复，跨局仍拒绝重复购买（`dup_across_load_state_*`）。
> `value` 均为 `bool/int` 标量，符合 `WorldState.set_flag` 的 `_is_scalar` 约束。

---

## 4. 「broken」定义（人工试玩校准判据）

| # | 现象（试玩观测） | 判定 | 优先回调动作 |
|---|---|---|---|
| B1 | **兑换门槛过高**：一轮三波全清（450 点）仍买不起最便宜项，或需反复刷多局才换 1 项 | 成本失衡 | 下调 `cost` 梯度（100/200/300）；或复核 `wave_trial.tres` 的 `reward_points`（Rank-1 表，须协调整改，本轮不越界改）。 |
| B2 | **点数通胀 / 门槛过低**：一局就能买齐 3 项且仍余大量点数，`grace.trial.points` 只涨不花 | 经济失衡 | 上调 `cost` 梯度；或增加兑换项（需改 `.tres` 与 config 白名单，属后续内容）。 |
| B3 | **增益过强**：+20 HP 让 Boss 战几乎无死亡压力；+1 帧无敌让翻滚可无脑躲；+5 攻击让重击（`×1.65`）明显破坏节奏 | 数值过强 | 下调对应 `effect_value`；优先回调 `roll_iframe`（对帧窗口最敏感）与 `attack_power`（被重击倍率放大）。 |
| B4 | **增益无感**：三项买齐后 HP/翻滚/伤害手感无变化 | 数值过弱 **或接线未装配** | **先按 §5 确认运行时接线已装配**；本轮裁决 A22 下接线节点无挂载点，未装配时「无感」是装配问题、不是数值问题，不得据此调数值。装配确认后再上调 `effect_value`。 |

补充说明（如实边界，不冒充）：

- 上表阈值（450 点 / 一局 / +20% HP / +1 帧）本身都是 `[PLACEHOLDER]`，来自任务单示例与既有数据表，试玩后需同步本文与 verify。
- B1/B2 的「一轮全清 450 点」依赖 Rank-1 `wave_trial.tres`，**本轮未改该表**；若奖励调整，须同步复算本文 §1。
- verify **只校验数据合法性、防刷与接线代码路径**，不测手感/时长（属用户侧试玩与 Rank-1 HUD 观测）。
- 人工试玩手感与审美判断由用户侧完成（契约 §5），本文件只给判据与调参入口，**不冒充已完成试玩校准**。

---

## 5. 效果接线边界（裁决 A22 · 如实登记，不伪造生效）

本轮**三项 effect_key 全部命中既有落点**（§1），接线脚本 `grace_upgrade_runtime.gd` 也已实现「读三段式 flag → 经既有公开方法 / @export 作用到运行时」，并在 verify 中**显式调用**实证有效：

| 效果 | 经既有接口 | verify 实证（apply 前 → 后） |
|---|---|---|
| HP 上限 | `@export player_max_hp` + 公开方法 `trial_grace_rest()` | `100.0 → 120.0` |
| 翻滚无敌窗口 | `@export PlayerActionData.invulnerable_end_frame`（player_actions.tres 进程内实例） | `13 → 14`；`PlayerActionState` 在 frame=13 时 `is_invulnerable()` 由 false → true |
| 攻击力 | `@export PlayerActionData.base_attack`（light + heavy 同步） | `85.0 → 90.0`；`PlayerActionState.get_current().base_attack=90.0` |

**但按裁决 A22 必须如实登记如下**：

1. 裁决 A22 禁止写 `encounter_director.gd` / `wave_trial_director.gd`（Rank-1 独占）；目录所有权同时禁止改场景 / `project.godot` autoload 注册。
2. 因此新增的独立接线节点 `GraceUpgradeRuntime` **在真机运行时没有挂载点**：不会随 `courtyard.tscn` 自动实例化，也不会被两份导演调用。
3. 结论：**「数据已落、效果待接」** —— `.tres` 三项数值、flag 记账、接线 API 均已落盘且 verify 实证可生效，但**真机自动生效未接通**，本轮不谎报生效。
4. 解除阻塞所需动作（**属 Rank-1 / 总指挥装配层，本轮不越界实施**）：在 `courtyard.tscn` 挂一个 `GraceUpgradeRuntime` 节点，或在 Rank-1 导演 `_ready()` 中调用一次 `apply_purchased(encounter)`；购买入口由 UI/装配层调用 `try_purchase(id, ws, writer)`。
5. 接线脚本对「未注入 EncounterDirector / WorldState 不可用 / 表缺失 / 未知 effect_key」均降级登记并携带 `数据已落、效果待接` reason（verify `wiring_degrade_*` 断言），不伪造生效。
6. `roll_iframe` / `attack_power` 修改的是 `load()` 得到的**进程内 Resource 实例**（既有 @export 字段），**绝不写 `player_actions.tres` 文件**；进程重启后回落表内原值，需重新 apply。

---

## 6. 调参位置（唯一入口 + 同步清单）

1. **改数值**：编辑 `godot/data/rpg/grace_upgrades.tres` 的 `upgrades`（3 个 Dictionary，各 5 个 key）。改完真跑 `verify_grace_upgrade_v050.gd`。
2. **改结构 / 降级 / 白名单**：编辑 `grace_upgrade_config.gd`（不写设计数值）；若新增 `effect_key`，须同步 `grace_upgrade_service.gd` 的 `KNOWN_EFFECT_KEYS` 与 `grace_upgrade_runtime.gd` 的 `_dispatch`。
3. **校准后必须同步三处**：`.tres` 数值 → `verify_grace_upgrade_v050.gd` 的 `EXPECT_IDS/EXPECT_NAMES/EXPECT_COSTS/EXPECT_KEYS/EXPECT_VALUES` → 本文 §1 与 §4 阈值。**不静默改数**。
4. **不碰**：Rank-1 `wave_trial_director.gd` / `encounter_director.gd` / `courtyard.tscn` / HUD / `00-协作契约.md` / `README.md` / `project.godot` / 既有 `.tres`（目录所有权 + 裁决 A22）。

---

## 7. 真跑校验入口（命令）

```bash
ENGINE="D:/Godot/Godot_v4.7.2-stable_win64.exe"
PROJ="F:/Game/aierdengfahuan/godot"

# ① 注册新增 class_name（GraceUpgradeConfig / GraceUpgradeService / GraceUpgradeRuntime）
"$ENGINE" --headless --path "$PROJ" --import

# ② 四脚本解析门禁
for s in grace_upgrade_config grace_upgrade_service grace_upgrade_runtime verify_grace_upgrade_v050; do
  "$ENGINE" --headless --path "$PROJ" --check-only --script "res://scripts/combat/$s.gd"
done

# ③ 自测（127 PASS / 0 FAIL / RESULT=ALL_MATCH）
"$ENGINE" --headless --path "$PROJ" --script res://scripts/combat/verify_grace_upgrade_v050.gd

# ④ 主场景加载退出
"$ENGINE" --headless --path "$PROJ" --quit
```

---

## 8. 未完成项 / 如实边界

- **效果真机自动生效未接通**（§5）：受裁决 A22 与目录所有权限制，独立接线节点无挂载点，已如实登记「数据已落、效果待接」，需 Rank-1 装配层挂载/调用；本轮不伪造生效、不越界改导演/场景。
- **购买落盘真机链路未接通 UI 入口**：`try_purchase(id, ws, writer)` 已实现并经 verify 用内存 WorldState + FakeWriter 实证（不污染 user:// 盘），但真机无 UI/装配层调用入口（不改 hud.gd / 场景）；`grace.trial.spent_points` 与 `bought_<id>` 在真机尚未被写入。
- **人工试玩校准（B1~B4）未执行**，属用户侧；本文只给判据与调参入口。
- `effect_value` 对重击 `motion_multiplier=1.65` 的放大效果、以及 `+1` 帧无敌与既有 `MoveData.startup_frames` 的量纲关系，尚未经试玩/导演层实接复核。
- 未改任何 Rank-1 / Rank-3 / Rank-4 文件，未自行 `git`，零付费、零外部依赖、未启 GPU job；未新建只读探针 / 巡检脚本（`verify_grace_upgrade_v050.gd` 是正式自测件，非探针）。
