# CODEX-GDD.md — 赐福图鉴 · 成就系统（v0.8.0 / R30 / Rank-3）

> Game Designer 格式六项齐全：`purpose / player experience goal / inputs / outputs / edge cases / failure states`。
> 本文是 **Rank-3 设计规格文档**：只写设计口径、不实现、不写任何 `godot/` 工程业务文件、不新建探针 / 巡检脚本。
> **数值真源**：Rank-2 `teamwork/Rank-2/CODEX-TUNING.md` §1 `[PLACEHOLDER]` 数值假设表 / `godot/scripts/combat/codex_config.gd` / `godot/data/rpg/codex_entries.tres`（R30 并发产出，`codex_entries.tres` / `codex_config.gd` 于 **12:55:40**、`verify_codex_reward_v080.gd` 于 **12:57**、`CODEX-TUNING.md` 于 **12:59:34** 落盘、Rank-2 本轮 **13:01:35 done**）。**本 GDD 已按落地表校对引用键名 / 数值 / 语义，逐项一致**（§11 C-V1）。**Rank-3 不另造任何数值**：文中 `reward_points` 30 / 50 / 80 / 120、合计 280、`threshold=3`、教学 20/30/50、三波 100/150/200、成长成本 100/200/300、单轮三波产出 450 均逐字引用 Rank-2 落地表 `[PLACEHOLDER]` 值，全部待人工试玩校准。
> **运行时真源**：Rank-1 `godot/scripts/combat/codex_director.gd` / `hud.gd` 最小接线 / `presentation.gd` 演示序列注入 / `verify_codex_v080.gd`；均属 Rank-1 并发实现，Rank-3 不代验、不宣称已接通。
> **沿用不改**：`WAVE-TRIAL-GDD.md` §9.8 目标梯度与留存钩子 / §10.5 edge cases / §10.7 奖励节奏与留存钩子 / §10.8 三段式 flag 与 `commit(reason)` 先落盘口径、`TUTORIAL-BLOCKOUT.md` 不惩罚原则、`00-协作契约.md` §3.3 三段式 flag 登记表。**既有条款一律不回改、既有四条留存钩子一律不回退**。

---

## 0. 定调（先说清「不是什么」）

- 图鉴**不是**新战斗系统、不是新的时间梯度层、不是新的刷点循环：不新增敌人、不改三波倍率 / 时限 / 奖励梯度、不新增 `SaveDelta` 顶层字段、不改 `schema_version=3`、不改 `project.godot` / `courtyard.tscn` 节点。
- 图鉴是**横切既有四层目标梯度的「收集」留存钩子**：把玩家在教学 / 三波 / 成长里**已经达成**的里程碑，沉淀为可读、可回顾、跨局不丢的成就完成度 `n/4`。
- 只做 2D 面板呈现（Rank-1 运行时建独立 CanvasLayer，裁决 A35），默认隐藏、半透明底 `alpha ≤ 0.35`、不遮角色、避开既有五套 HUD 占位、不改既有 HUD 文本；零付费、零外部依赖。
- **不惩罚**：未解锁不扣点、不死亡、不写脏 flag、不重置进度；重复领取被拒属幂等门控而非惩罚；Tab 开关不影响战斗与三波推进。

---

## 1. purpose

给「已经做过的事」一个**永久、可读、可回顾**的落点，补上核心循环里缺失的「收集」留存钩子。

既有 `WAVE-TRIAL-GDD.md` 的四条留存钩子（「我学会了」不可撤销 / 开局即正反馈 / 可重开但不惩罚 / 历史最佳·赐福点数·永久增益·重复挑战更轻松）回答的都是「还能变多强 / 还能打多高」；但抽象 flag 与分散在五套 HUD 里的进度**没有一处能被摊开清点**，跨局回顾缺一个展示位。图鉴把四层梯度的关键里程碑钉成 4 项单向成就 + 完成度 `n/4`，把留存动机从「单一数值追逐」扩展为「清单式收集」，且**不惩罚未完成**（§9）。设计上刻意不改任何既有数值 / 时序 / 场景，保证 v0.8.0 是纯增量、既有回归不回退。

---

## 2. player experience goal

- **可清点**：按 Tab 一屏看到 4 项成就的名称 / 描述 / 已达成高亮 / 进度 `n/4`，「还差哪一项」一眼可读。
- **不撤销**：达成即 `grace.codex_<id>.unlocked` 单向置 `true`（裁决 A36），跨局 / 跨重启 / 退出 / 重复挑战均不丢，给「已完成」一个永久确认。
- **开局即有正反馈、且不被逼迫**：第一项成就锚定教学完成（`grace.tutorial.completed`），玩家在「学会操作」的同一刻就收到第一枚收集确认；未解锁项只显示「未达成」，不催促、不惩罚、不弹阻断式提示。
- **带着成长回去看**：三波全清 / 三项增益全解锁 / 最高波次达标依次点亮，把「变强 → 验证 → 再变强」的既有动机链变成可回看的完成度曲线；老玩家由单向存档直接看到历史成就，不被强制重打。

---

## 3. inputs

| 输入 | 内容 | 归属 / 真源 | 口径 |
|---|---|---|---|
| 数据输入 | 4 项成就表 `codex_entries.tres`（`id / title / description / condition_kind / condition_value / reward_points`） | **Rank-2** `codex_config.gd` / `CODEX-TUNING.md` §1（**已落盘**） | 全 `[PLACEHOLDER]`；4 项实例 `tutorial_complete` / `wave_trial_clear` / `all_grace_upgrades` / `best_wave_3`，`condition_kind` **只用既有 flag 语义** `bool_true / int_at_least / all_of`，`reward_points` 30/50/80/120 严格单调递增合计 280；空表 / 字段缺失 / 非法 `condition_kind` / 引用未登记 flag 按 §5 C-E3 降级。Rank-3 只引用落地表、不填自造数值 |
| 存档输入（订阅，纯读） | `grace.tutorial.completed`（bool）/ `dungeon.wave_trial.completed`（bool）/ `dungeon.wave_trial.best_wave`（int）/ `grace.upgrade_<id>.unlocked`（bool ×3） | 既有三段式 flag（契约 §3.3 / R26 / R27 / R28 已登记） | 经 `get_flag(key, default)` **纯读**、图鉴**只读不写**这些 flag；判定由 Rank-1 `codex_director.gd` 订阅完成 |
| 存档输入（自身态） | `grace.codex_<id>.unlocked`（bool 单向，A36）/ 既有 `grace.trial.points`（int 单调递增） | Rank-1 `codex_director.gd` | false→true 单向、跨重启不回退；`points` 只增不减、绝不写 `removals` |
| 交互输入 | Tab 键（`KEY_TAB`，**不与教学 `T` 键冲突**）开关图鉴面板 | Rank-1 `hud.gd` 最小接线 | 默认隐藏；独立 CanvasLayer（A35）避开赐福 / 画质 / 波次 / 教学 / 兑换 / 底部战斗 HUD 占位；不遮角色 |
| 演示输入 | 15 秒演示序列注入**一次** Tab，走真实输入路由 | Rank-1 `presentation.gd` | 只用于录屏证明面板可打开，不参与成就判定、不重复驱动 |
| 衔接输入 | 既有四层梯度的里程碑 flag（§8） | 既有导演层 | 图鉴**不推进三波、不起 `time_limit_sec` 倒计时、不生成伤害判定、不冻结波次**（沿用 `tutorial_director.gd` / `wave_trial_director.gd` 既有口径） |

---

## 4. outputs

| 输出 | 内容 | 去向 | 口径 |
|---|---|---|---|
| 屏幕反馈 | 图鉴面板：4 项成就名称 / 描述 / 已达成高亮 / 进度 `n/4` | 玩家 | Rank-1 独立 CanvasLayer（A35）；避开既有五套 HUD 占位、不改既有 HUD 文本、半透明底 `alpha ≤ 0.35`、不遮角色 |
| 即时反馈 | 成就达成 → `codex_entry_unlocked(id,title)` / `codex_progress_changed(unlocked,total)` 信号 → 面板高亮 + 进度 `+1` + 一次性奖励入账 | 玩家 / HUD | 由 Rank-1 运行时驱动，Rank-3 不实现、不代验 |
| 存档输出 | `grace.codex_<id>.unlocked`（bool false→true 单向、A36）、`grace.trial.points`（int 单调递增，既有） | `WorldState.flags` → `SaveDelta` → `delta.json` | 经 I-1 `set_flag`、**强制 `commit("codex_unlocked")` 先落盘**（沿用 §10.8「先落盘再改运行时实例」五步顺序）；**图鉴奖励只累加 `points`、不写 `removals`、不回退 `points`** |
| 系统输出 | **无**：图鉴不推进三波、不改倍率 / 时限 / 波次数值 / `cost` / `effect_value`、不切场景、不新增顶层字段 | 导演层 | 只读订阅 + 单向落 flag；`schema_version` 保持 `3`、不触发迁移 |
| 奖励节奏输出 | 一次性 `reward_points`（Rank-2 `[PLACEHOLDER]`）→ `grace.trial.points` → 成长 `cost` 出口 | 玩家 / 成长界面 | 与教学每步、三波清波奖励连成一条不断裂的积累曲线（§9） |

---

## 5. edge cases

| # | 情形 | 处理（不惩罚 / 不写脏 flag） | 归属 |
|---|---|---|---|
| C-E1 | 已有存档 `grace.codex_<id>.unlocked = true` | **跳过重复解锁**：不重发奖励、不二次改进度、不重复 emit；老玩家直接看到历史成就 | Rank-1 门控 / Rank-3 基线 |
| C-E2 | 同一成就重复触发 / 重复领取 | 幂等门控：单向 flag + 领取标记保证 `points` 不二次累加、`n/4` 不二次推进；重复领取**拒绝但不惩罚**（不扣点、不回退已入账点数、如实告警） | Rank-1 / Rank-2 `verify_codex_reward_v080.gd` |
| C-E3 | 依赖 flag 缺失 / 类型不符 / `condition_kind` 非法 / `condition_value` 越界 / 表字段缺失 | 按 Rank-2 `verify_codex_reward_v080.gd` 降级口径**拒绝该条**、不写脏 flag、安全停在「未解锁」、**不把降级态判为通过**；异常输入拒绝 | Rank-2 数据校验 / Rank-1 / Rank-3 |
| C-E4 | `codex_entries.tres` 空表 / 表未落盘 / 资源加载失败 | 图鉴面板仍可打开、显示 `0/4` + 降级提示，不崩、不臆造条目、不阻断主循环 | Rank-1 / 契约「依赖缺失降级」 |
| C-E5 | 面板与既有 HUD 重叠 / 遮挡角色 | 按 A35 独立 CanvasLayer + 安全区约束让位；`alpha ≤ 0.35`、默认隐藏、不遮角色判定区 | Rank-1 |
| C-E6 | Tab 与教学 `T` 键冲突 / 战斗中打开 | `KEY_TAB` 与 `KEY_T` 分离；开面板**不冻结三波、不暂停伤害判定、不吞输入**（沿用 §3 衔接口径） | Rank-1 |
| C-E7 | 中途退出 / 主动退出 / 进程被杀 | 已 `commit("codex_unlocked")` 的解锁与点数不丢；未落盘的运行时增量允许丢弃（**以磁盘为唯一权威**，沿用 §10.8 顺序） | Rank-3 落盘口径 |
| C-E8 | 重启读回 | 新实例 `_load()` 从磁盘重建；`unlocked` / `points` / 进度 `n/4` 逐项一致、不回退、不重置 | Rank-1 / Rank-2 回放断言 |
| C-E9 | 余额约束 | `points − spent_points ≥ 0` 硬约束沿用 §9.9；图鉴**只增 `points`**、不触碰 `spent_points` / `removals` | Rank-2 购买门控 / Rank-3 基线 |

---

## 6. failure states

| # | 失败态 | 降级行为（如实、不伪造通过） | 归属 |
|---|---|---|---|
| C-F1 | 成就表 / `codex_config.gd` 未落盘或加载失败 | 面板打开但显示 `0/4` + 降级提示，**不崩、不阻断主循环、不臆造成就**，如实登记为未接通 | Rank-1 / Rank-2 并发产出 |
| C-F2 | `commit("codex_unlocked")` 落盘失败 | **不执行**「更新运行时 flag 实例 / 面板高亮 / 发奖」，运行时保持旧值、如实告警，绝不「内存已改、磁盘未改」（§10.8 五步第 ⑤ 步） | Rank-1 / Rank-3 落盘口径 |
| C-F3 | 条件不可达（Rank-2 broken 定义之一） | 如实登记、不伪造解锁、不静默改条件 / 门槛；保留「未达成」 | Rank-2 `CODEX-TUNING.md` |
| C-F4 | 奖励通胀 / 重复领取 / 余额被击穿 | 门控拒绝、如实告警；**不回退已入账 `points`**、不写 `removals` | Rank-2 `verify_codex_reward_v080.gd` |
| C-F5 | 面板遮挡 / 与既有 HUD 冲突 | 按 C-E5 降级（隐藏 / 让位），不遮角色、不改既有 HUD 文本 | Rank-1 |
| C-F6 | 演示序列与真实输入双驱动 | 只由 Rank-1 `presentation.gd` 注入**一次** Tab，图鉴不自行开面板、不重复驱动（沿用 §10「教学 + 演示序列」双驱动规避口径） | Rank-1 |
| C-F7 | 人工试玩手感 / 审美 / 15~20 秒录屏目视回看 | **属用户侧 / Rank-4，Rank-3 不代做、不宣称完成**；headless 真跑无真实帧缓冲 | 用户侧 / Rank-4 |

> 与 `WAVE-TRIAL-GDD.md` §10.6 / `TUTORIAL-BLOCKOUT.md` 一致：**任何失败态都不死亡、不扣点、不写脏 flag、不回退持久化进度**，回退粒度仅到「本次运行时判定」。

---

## 7. 「收集」留存钩子（本轮新增第五条，既有四条不回退）

**断点**：既有四条钩子（§10.7（4））都指向未来——「还能打多高 / 还能变多强」；玩家**没有一处能把「已经做过的事」摊开清点**。三段式 flag 是抽象的、进度分散在五套 HUD 里、跨局回顾缺一个落点，导致「已完成的里程碑」在体感上被稀释。

**图鉴怎么补**：

1. **抽象 flag → 可读清单**：4 项成就把四层梯度的关键里程碑钉成「名称 / 描述 / 已达成高亮 / 进度 `n/4`」，玩家按 Tab 一屏清点「还差哪一项」。
2. **单向不可撤销**：`grace.codex_<id>.unlocked` false→true 单向（A36），跨局 / 跨重启 / 退出 / 重复挑战不丢，给「已完成」一个永久展示位（同 §10.7「我学会了」不可撤销的心理学，但作用于全部四层）。
3. **清单式动机，不惩罚未完成**：从「再高点」扩到「还差哪一项」，未解锁项只显示「未达成」、不催促、不弹阻断式提示、不扣点（§9）；完成度是**展示**而非新的限时压力层。
4. **不抢跑 / 不稀释**：图鉴不新增时间目标、不改三波 / 成长数值、不改写 §2 / §9 核心循环；既有四条钩子**原样保留、不回退**（§10.7（4）逐条沿用）。

> 与「成就系统」通用套路的差别（如实）：本图鉴**不设排行榜、不设时限、不设可反复刷的兑换**，4 项成就各只领一次、条件全部取自**既有**持久化 flag，不引入新数值域。

---

## 8. 与「教学→三波→成长」四层目标梯度的衔接

> 口径：沿用 `WAVE-TRIAL-GDD.md` §9.8 四层（短期 / 中期 / 长期 / 成长）与 §10.7 引导层；任务单「教学→三波→成长四层」为其归并表述 —— **教学引导**单列最前置一层，**三波**含短期（单波时限）与中期/长期（三波全清 / 最高波次）两个时间尺度，**成长**沿用 §9.8 不改。图鉴**不新增梯度层**，只把每层里程碑订阅为成就条件。

| 层（任务单归并） | 时间尺度 | 目标 | 既有持久化量 | 对应图鉴成就（`condition_kind`） | 衔接方式（不抢跑） |
|---|---|---|---|---|---|
| **① 教学 / 引导**（§10.7） | 开局前置、无 `time_limit_sec` 压迫 | 做对三步最小操作集 | `grace.tutorial.step_index` / `grace.tutorial.completed` | 成就 1「教学完成」`bool_true` | 教学 `COMPLETED` 后自动进第 1 波 `TELEGRAPH`；图鉴**只订阅 `completed`**、不读运行时游标、不改教学状态机 |
| **② 三波 · 短期**（§9.8） | 30 秒级 `time_limit_sec [PLACEHOLDER]` | 在时限内清掉当前波 | 无（局内进度由导演层持有） | **—（不设成就）** | 图鉴**不订阅局内短期量**，避免把「收集」变成逐波打卡、避免抢跑（如实登记，非遗漏） |
| **③ 三波 · 中期 / 长期**（§9.8） | 一局三波 / 跨局跨重启 | 三波全清 / 刷新最高波次 | `dungeon.wave_trial.completed`（bool 单向）/ `dungeon.wave_trial.best_wave`（int 单调递增） | 成就 2「三波全清」`bool_true` + 成就 4「最高波次 ≥3」`int_at_least` | 沿用 R26 波次结算与单调递增 flag，图鉴只读阈值判定、**不改任何波次数值 / 倍率 / 时限** |
| **④ 成长**（§9.8） | 跨局 / 跨重启 | 攒够点数 → 兑换永久增益 → 带增益挑战更高 | `grace.trial.spent_points` / `grace.upgrade_<id>.unlocked`（bool 单向 ×3） | 成就 3「三项增益全解锁」`all_of` | 沿用 §9 点数出口 / `spent_points` 单调镜像 / 余额 `points − spent_points ≥ 0`，**不改 `cost` / `effect_value` / `id`** |

**衔接三条结论**：

- **教学是「开始被计时」的前置条件、图鉴是「已学会」的确认位**：二者共用 `grace.tutorial.completed`，一个进第 1 波、一个点第一枚成就，互不干扰（沿用 §10.7（2）「不抢跑」）。
- **图鉴奖励回流成长出口**：成就 `reward_points` 一次性入账 `grace.trial.points`，最终仍由 `cost` 出口兑现为永久增益（§9 既有闭环），图鉴不是孤立奖励、也不构成新刷点循环。
- **四层梯度原样保留**：§9.8 四层 / §10.7 五层展开 / 三条留存钩子 / 核心循环「行动→反馈→目标→消费成长→再行动」**一律不因加图鉴而改写**。

---

## 9. 奖励节奏与不惩罚原则

**（1）三段连续 → 图鉴里程碑确认（全程只增不减）**

| 段 | 奖励 | 数值真源 | 语义 |
|---|---|---|---|
| 教学每步 | `reward_points` | Rank-2 `tutorial_steps.tres`（已落地，引用键名） | 开局即小额入账 |
| 三波清波 | `reward_points` 递增 | Rank-2 `WAVE-TRIAL-TUNING.md`（已落地，引用键名） | 试炼递增 |
| 成长出口 | `cost` | Rank-2 `GRACE-UPGRADE-TUNING.md`（已落地，引用键名） | 兑现为永久增益 |
| **图鉴成就（v0.8.0 新增）** | 一次性 `reward_points` | **Rank-2 `CODEX-TUNING.md` §1 / `codex_entries.tres` `[PLACEHOLDER]`**（已落地：30 / 50 / 80 / 120，合计 280） | 里程碑确认 |

- 全程只累加既有 `grace.trial.points`、**绝不写 `removals`、绝不回退 `points`**（沿用 R26 §6.2 / R27 §9.9 / R28 §10.8）。
- 图鉴奖励是**一次性里程碑确认，不是新刷点循环**：每项成就单向解锁、只领一次、重复领取拒绝（Rank-2 `verify_codex_reward_v080.gd` 断言），不与教学 / 波次奖励叠加成可反复刷的通道；防「奖励通胀」broken（§10 表）。

**（2）不惩罚原则（沿用 `TUTORIAL-BLOCKOUT.md` / `WAVE-TRIAL-GDD.md` §10.5 T-E3）**

- 未解锁：不扣点、不死亡、不写脏 flag、不重置进度、不弹阻断式提示。
- 重复领取被拒：属幂等门控，**不是惩罚**，不回退已入账点数。
- Tab 面板：默认隐藏、开关不影响战斗 / 三波推进 / 伤害判定（§3 C-E6）。
- 失败 / 超时 / 主动退出 / 进程被杀 / 重启：`unlocked` 与 `points` 均不回退（§5 C-E7 / C-E8），以磁盘为唯一权威。
- 余额：`points − spent_points ≥ 0` 沿用，图鉴只增 `points`、不触碰 `spent_points` / `removals`（§5 C-E9）。

---

## 10. 数值引用表（Rank-2 `[PLACEHOLDER]` 落地表，Rank-3 不另造数值）

> 真源：`teamwork/Rank-2/CODEX-TUNING.md` §1（12:59:34 落盘）/ `godot/data/rpg/codex_entries.tres`（12:55:40 落盘）/ `godot/scripts/combat/codex_config.gd`（12:55 落盘）。**全部为 `[PLACEHOLDER]`、待人工试玩校准**；Rank-3 只引用、不造数、不改表。

| 量 | Rank-2 落地表 `[PLACEHOLDER]` 键 / 值 | 本文引用方式 | rationale（逐字引用 Rank-2 `CODEX-TUNING.md`） |
|---|---|---|---|
| 4 项成就结构 | `id / title / description / condition_kind / condition_value / reward_points`（`codex_config.gd`）；实例 `tutorial_complete` / `wave_trial_clear` / `all_grace_upgrades` / `best_wave_3` | **引用键名与实例 id** | 结构对齐 Rank-2 数据表；已校对一致（§11 C-V1），不一致改本文引用段、不改数据表 |
| 奖励点数 | `reward_points` = **30 / 50 / 80 / 120**，严格单调递增、合计 **280**（`codex_entries.tres` / `CODEX-TUNING.md` §1） | **引用落地表 `[PLACEHOLDER]`，不另造** | 梯度与达成难度同向递增；合计 280 刻意低于既有单轮三波产出 450，使图鉴是「留存钩子 / 小额补贴」而非第二套点数来源（防 B2 奖励通胀）；与教学 20/30/50、成长成本 100/200/300 同量级校准 |
| 条件种类 / 参数 | `bool_true`（`grace.tutorial.completed` / `dungeon.wave_trial.completed`）、`all_of`（3 个 `grace.upgrade_<id>.unlocked`）、`int_at_least`（`dungeon.wave_trial.best_wave`，`threshold=3`） | 引用 | 只用既有 flag 语义三态、4 项覆盖全部 3 种；`condition_value` 只引用 `REGISTERED_FLAGS` 白名单保证「条件可达」；对应 §8 四层里程碑 |
| 成就数 / 进度 | **4 项 / `n/4`**（Rank-1 / Rank-2 任务单结构） | 引用 | 与 4 类成就、4 个订阅 flag 一一对应；非 Rank-3 新造数值 |
| broken 定义 | **B1 门槛过高 / B2 奖励通胀 / B3 条件不可达 / B4 重复领取**（`CODEX-TUNING.md` §5） | 引用 | 沿用 Rank-2 校准判据与回调方向（下调 `threshold` / 下调 `reward_points` 梯度且保持单调 / 回白名单 / `_claimed` 幂等 + commit 先落盘）；对应 §5 / §6 降级行为 |
| 既有数值（教学 / 三波 / 成长） | 教学 `reward_points` 20/30/50、三波 100/150/200、成长 `cost` 100/200/300、单轮三波产出 450（`CODEX-TUNING.md` §1 rationale / §6） | 引用落地表登记值 | 与图鉴 `reward_points` **同名不同语义域**（教学表 / 波次表 / 图鉴表三域），沿用 §10.7 T-V6 校对口径；Rank-3 不改数值 |

> **如实登记（不伪造）**：Rank-2 本轮 `CODEX-TUNING.md` / `codex_config.gd` / `codex_entries.tres` / `verify_codex_reward_v080.gd` 属 R30 **并发产出**，Rank-3 早期探查（12:5x）时为未落盘、按历轮 R26 / R27 / R28 先例采用字段名引用式占位；**Rank-2 表已于 12:55~12:59 落盘、13:01:35 done，本 GDD 交付前已按落地表校对引用键名 / 数值 / 语义并逐项一致**（§11 C-V1），故本表改列为「已落地表引用」。**Rank-1 本轮 `codex_director.gd` / `hud.gd` 最小接线 / `presentation.gd` / `verify_codex_v080.gd` 仍为 `dispatched`、尚未 done**，运行时接线 / Tab 面板 / 演示序列 Rank-3 **不代验、不宣称已接通**（§11 C-V2 / C-V4）。**Rank-3 不填任何自造数值、不改 Rank-2 数据表**。

---

## 11. 校对清单（本轮未达 / 待办，如实登记）

| # | 项 | 状态 |
|---|---|---|
| C-V1 | **Rank-2 图鉴表落地校对**：`codex_config.gd` / `codex_entries.tres` / `CODEX-TUNING.md` 的引用键名（`id / title / description / condition_kind / condition_value / reward_points`）、`reward_points` 与波次 / 教学 `reward_points` **同名不同语义域**、rationale / broken 定义与 Rank-2 实际表一致；不一致**改本文引用段、不改数据表** | **已完成（R30）**：Rank-2 表 12:55~12:59 落盘、13:01:35 done，本 GDD 交付前已按 §1 / §5 / §6 逐项校对 —— 4 项实例 id / `condition_kind` 三态 / `condition_value` 白名单 / `reward_points` 30<50<80<120 合计 280 / B1~B4 broken 定义**逐项一致**，§10 已改列为落地表引用；剩余「人工试玩校准具体值」归 C-V5 |
| C-V2 | 4 项成就与 4 个订阅 flag 的 `condition_kind` / `condition_value` 对齐、依赖缺失降级 | **属 Rank-1 / Rank-2 运行时与数据表，Rank-3 不代验、不宣称已接通** |
| C-V3 | `grace.codex_<id>.unlocked` 单向 / `commit("codex_unlocked")` 先落盘 / 重复领取拒绝 / 余额非负 / `points` 只增不减 / 异常输入拒绝 | 属 `verify_codex_v080.gd` / `verify_codex_reward_v080.gd`（Rank-1 / Rank-2），Rank-3 不代验 |
| C-V4 | Tab 面板安全区 / 不遮角色 / 15 秒演示序列注入一次 Tab / 15~20 秒录屏目视回看 | **属 Rank-1 / Rank-4 / 用户侧，Rank-3 不代做、不宣称完成** |
| C-V5 | 人工试玩校准全部 `[PLACEHOLDER]` 数值、HD-2D 全绿 | **属用户侧，Rank-3 不代做、不宣称完成**（工程根 `README.md`「还差什么」） |
| C-V6 | 31 PASS 存档 / HUD 回归不回退 + 三段门禁 `grep SCRIPT ERROR=0` | **R30 真跑**（见 `teamwork/Rank-3/DONE-R30.md`） |

---

## 12. 关联

- `teamwork/Rank-3/WAVE-TRIAL-GDD.md` §9.8（四层目标梯度 / 三条留存钩子）· §10.5（edge cases）· §10.7（前 30 秒断点 / 梯度衔接 / 奖励节奏 / 四条留存钩子）· §10.8（三段式 flag / `commit(reason)` / 先落盘顺序）—— **沿用不改**
- `teamwork/Rank-3/TUTORIAL-BLOCKOUT.md`（失败回退与不惩罚原则）—— 沿用不改
- `teamwork/00-协作契约.md` §3.3（三段式 flag 登记表）—— 沿用不改
- `teamwork/Rank-2/CODEX-TUNING.md` §1 / §5 / §6 · `godot/scripts/combat/codex_config.gd` · `godot/data/rpg/codex_entries.tres` · `verify_codex_reward_v080.gd`（**Rank-2 本轮并发产出，12:55~12:59 已落盘、13:01:35 done；本 GDD 已校对引用一致**）
- `godot/scripts/combat/codex_director.gd` · `presentation.gd` · `hud.gd` 最小接线 · `verify_codex_v080.gd`（**Rank-1 本轮并发产出，Rank-3 不代验**）
- `teamwork/Rank-3/DONE-R30.md`（本轮实际交付 / 真跑输出 / 未完成项）· 工程根 `README.md`（v0.8.0 条目与「还差什么」）
