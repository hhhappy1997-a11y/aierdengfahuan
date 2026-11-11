# WAVE-TRIAL-GDD.md · 赐福波次试炼核心循环设计（v0.4.0 / R26）

> 工位：Rank-3（RPG / 世界 / 存档）｜轮次：`[ROUND=R26]`｜任务单：`cmd-20261111-073556-928-A3`｜日期：2026-11-11
> 文档性质：**Game Designer 核心循环文档 + Level Designer blockout 说明**。是设计口径，不是实现件、不是数值表、不是存档实现；不产生任何 `godot/` 工程文件写入。
> 公共契约：所有新数值标 `[PLACEHOLDER]` 待人工试玩校准、写清 rationale、不拍脑袋写死；本 GDD **不写任何具体数值**，一律引用 Rank-2 `teamwork/Rank-2/WAVE-TRIAL-TUNING.md` 的 `[PLACEHOLDER]` 表；零付费、零外部依赖、不伪造产物、不谎报成功、不自行 git。

---

## 0. 口径、所有权与数值纪律

| 层 | 归属 | 交付件（本轮并发） | 本 GDD 的关系 |
|---|---|---|---|
| 运行时 / 状态机 / 波次 HUD | **Rank-1** | `wave_trial_director.gd`、`encounter_director.gd`、`courtyard.tscn`、波次 HUD | §1.3 inputs / §1.4 outputs / §2 循环 / §4 blockout 对齐其状态机与信号，不定义其实现 |
| 数值表 / 数据表 | **Rank-2** | `wave_trial_config.gd`、`data/rpg/wave_trial.tres`、`WAVE-TRIAL-TUNING.md` | **本 GDD 全部数值的唯一真源**；§0.1 引用表逐项对齐 |
| 存档 flag / 契约 / 验证 | **Rank-3** | `00-协作契约.md` §3.3、`存档与flag规范.md` §3.3、`verify_wave_flags_v040.gd`、本 GDD | §1.4 outputs / §6 落盘口径由 Rank-3 定义并登记 |
| 美术 / 录屏 | **Rank-4** | PNG / SpriteFrames / `presentation.gd` / `capture/` | §4 可见性依赖其像素形象，本轮不代验 |

### 0.1 数值引用表（本 GDD 唯一允许的数值来源）

> 全部条目引用 `teamwork/Rank-2/WAVE-TRIAL-TUNING.md` 的 `[PLACEHOLDER]` 表；**Rank-3 不填数字、不另造数值、不改 Rank-2 数据表**。引用键名按 Rank-2 本轮 `wave_trial_config.gd` 约定字段。

| 设计维度 | 引用 TUNING.md `[PLACEHOLDER]` 键 | 本 GDD 用法 | rationale（待人工试玩校准，不写死） |
|---|---|---|---|
| 波次结构 | `waves`（三波） | §2 循环次数、§3 中期目标「一局三波全清」、§4 三波空间节奏 | 一局时长与重复挑战节奏的平衡点；过短无积累、过长疲劳 |
| 每波敌人 | `enemy_id` | §1.3 输入、§4 敌人可见预告内容 | 复用既有数据表 id（不新增数据表），预告可读性依赖敌人辨识度 |
| 逐波血量倍率 | `hp_multiplier` | §5 难度曲线斜率 | 逐波抬压但保留可退避窗口；与 `time_limit_sec` 联动校准 |
| 招式权重 | `move_weight` | §4 预告与出招节奏、§5 曲线 | 高频招式须先可见可判，避免「看不见就死」 |
| 每波点数奖励 | `reward_points` | §1.4 反馈、§3 留存钩子 `grace.trial.points` | 与通关耗时、风险匹配；防点数通胀（见 §1.6） |
| 入场预告时长 | `telegraph_sec` | §4「入场读秒 + 敌人可见预告」 | 给玩家读场 / 定位退避带的时间，过短不公平、过长拖节奏 |
| 单波时限 | `time_limit_sec` | §3「30 秒短期目标梯度」、§1.5 超时边界 | 制造短期压迫感；与倍率共同决定 broken 阈值 |

> **如实登记（不伪造）**：Rank-3 产出本 GDD 时，`WAVE-TRIAL-TUNING.md` 属 Rank-2 本轮并发产出、尚未落地，故上表为**字段名引用式占位**，不引用具体数值、不猜数字；待其落地后按 §7 校对清单核对键名 / rationale / broken 定义一致性，若键名不一致**改本 GDD 引用段、不改 Rank-2 数据表**。
> 文中「三波」「30 秒」为 R26 任务单给定的**结构 / 目标梯度描述**（一局中期三波全清、30 秒短期目标），不是 Rank-3 新造数值；其具体秒数、波次数值仍以 TUNING.md 的 `time_limit_sec` / `waves` `[PLACEHOLDER]` 为准。

---

## 1. 六项核心规格（Game Designer 核心循环文档格式）

### 1.1 purpose

在既有赐福「重复挑战」之上，提供一个**可反复进入、单局自洽、结果可持久化**的三波试炼：把零散的遭遇战收束成一条有读秒、有预告、有梯度、有结算的目标链。设计目的有三：① 给玩家一个 30 秒级就能完成的短期目标与一局内可达成中期目标；② 用「历史最高波次 / 赐福点数 / 全清完成」三个持久化量制造跨局积累；③ 为 v0.4.0 提供一条不依赖新战斗系统、只读既有数据表即可校准的难度曲线（数值全在 Rank-2 表内，改数值不改代码）。

### 1.2 player experience goal

玩家每一刻都清楚三件事：**我在第几波 / 还剩多少时间 / 打完能拿到什么**。理想体验是「读秒时看清敌人与退避位 → 交战中靠翻滚与走位在时限内清波 → 清波瞬间 HUD 数字跳动、点数入账 → 下一波倍率抬升、直觉上更紧但仍可读 → 三波全清时历史最佳与完成标记同时定格」。核心情绪是**「可预期的紧张 + 可累积的成就」**，而不是被看不见的伤害劝退；失败也应是「我读懂了但没打过」，而非「不知道发生了什么」。

### 1.3 inputs

| 类别 | 输入 | 来源 | 口径 |
|---|---|---|---|
| 玩家输入 | 移动 / 翻滚 / 攻击 | 既有玩家状态机、既有 input action | 不新增输入、不改既有战斗件 |
| 时序输入 | `IDLE → TELEGRAPH → WAVE_ACTIVE → WAVE_CLEARED → NEXT_WAVE / TRIAL_COMPLETED` | **Rank-1** `wave_trial_director.gd` 状态机 | 只读编排，不定义战斗数值 |
| 事件输入 | `wave_started(index,total)` / `wave_cleared(index,points)` / `trial_completed(best_wave)` / `encounter_finished(won)` | **Rank-1** 导演层信号 | Rank-3 订阅信号写 flag（I-1），Rank-1 不写 flag |
| 数据输入 | 三波 `wave_trial.tres`（`enemy_id / hp_multiplier / move_weight / reward_points / telegraph_sec / time_limit_sec`） | **Rank-2** 数据表 | 全 `[PLACEHOLDER]`，见 §0.1；空表 / 字段缺失按 §1.5 降级 |
| 存档输入 | 三段式 flag 基线 `dungeon.wave_trial.best_wave` / `dungeon.wave_trial.completed` / `grace.trial.points` | **Rank-3** 契约 §3.3 / 全局登记表 | `get_flag(key, default)` 纯读，见 §6 |

### 1.4 outputs

| 类别 | 输出 | 消费方 | 口径 |
|---|---|---|---|
| 屏幕反馈 | 波次 HUD「第 N/3 波 ｜ 赐福点数 ｜ 倒计时 ｜ 历史最佳」只读标签 | 玩家 | Rank-1 波次 HUD；避开既有赐福 / 画质 / 底部战斗 HUD 占位（见 Rank-1 任务单） |
| 即时反馈 | 命中 / 击杀 / 清波 / 倒计时 / 入场预告 | 玩家 | 由既有战斗件 + Rank-1 状态机驱动，Rank-3 不实现 |
| 存档输出 | `best_wave`（int 单调递增）、`completed`（bool 只增不减）、`points`（int 单调递增） | `WorldState.flags` → `SaveDelta` → `delta.json` | 三段式、经 I-1 `set_flag`，见 §6 |
| 系统输出 | `trial_completed(best_wave)` 结算 / 失败回赐福休息 | Rank-1 导演层 | 三波全清触发；失败不写 `completed` 回退 |

### 1.5 edge cases

| # | 边界 | 期望处理 | 归属 |
|---|---|---|---|
| E1 | 单波 `time_limit_sec` 超时未清 | 判本局失败，回赐福休息；`best_wave` 按已抵达波次取 `max` 后落盘，`completed` 保持原值（不因失败回退） | Rank-1 判定 → Rank-3 写盘 |
| E2 | 同一波重复触发 `wave_cleared` | 幂等门控：同一 index 只结算一次点数，不重复累加 `points` | Rank-1 门控 / Rank-3 登记口径 |
| E3 | `wave_trial.tres` 空表 / 字段缺失 / 第 0 或第 4 波越界 | 按 Rank-2 `verify_wave_trial_v040.gd` 的降级口径拒绝，试炼不启动或安全停在 IDLE，不写脏 flag | Rank-2 数据校验 |
| E4 | 依赖缺失（导演层 / 数据表 / WorldState 未就绪） | 降级到只读探活结果、不写 flag、不崩；不把降级态判为通过 | Rank-1 / Rank-3 |
| E5 | 中途退出 / 主动退出 / 进程被杀 | 已 `commit(reason)` 的波次与点数不丢；未落盘的运行时增量允许丢弃（以磁盘为准，见 §6 顺序） | Rank-3 |
| E6 | 重启读回 | 新实例 `_load()` 从磁盘重建；`best_wave` / `completed` / `points` 逐项一致，不回退、不重置 | Rank-3 `verify_wave_flags_v040.gd` |
| E7 | 三波全清后再次进入试炼 | 可重复挑战；`completed` 已为 `true` 不再翻转，`best_wave` 只按历史最高保留 | Rank-3 |
| E8 | 点数 / 波次数值溢出或 `null` / 类型不符 | 按三段式 value 白名单（bool/int/float/String）与 §3.3 登记类型为准，非法行丢弃并告警，不写脏 key | Rank-3 |
| E9 | 跨波读秒与清波同帧竞争 | 以导演层状态机单帧仲裁为准，Rank-3 只消费最终 `wave_cleared` / `trial_completed` 结果 | Rank-1 |
| E10 | HUD 读三个 flag 时存档未加载完 | `get_flag(key, default)` 给基线值，不阻塞、不显示未定义值 | Rank-1 HUD / Rank-3 基线 |

### 1.6 failure states

| # | 失败 / 失衡态 | 判据 | 处置 |
|---|---|---|---|
| F1 | **玩家失败态**：单波超时或玩家死亡 | Rank-1 `encounter_finished(false)` / 倒计时归零 | 回赐福休息；不写 `completed=true`；`best_wave` 按已抵达波次 `max` 落盘 |
| F2 | **数值 broken · 难度过高** | 引用 Rank-2 `WAVE-TRIAL-TUNING.md` `broken` 定义（首波在 `time_limit_sec` 内打不完等） | 只调 TUNING.md `[PLACEHOLDER]` 数值，不改代码、不改 GDD 结构；待人工试玩校准 |
| F3 | **数值 broken · 难度过低** | 同上（三波全清耗时过短等），阈值以 TUNING.md 为准 | 同上 |
| F4 | **数值 broken · 奖励失衡（点数通胀）** | 同上（`reward_points` 与耗时 / 风险不匹配） | 同上；`points` 只增不减，通胀靠调表而非回滚存档 |
| F5 | **系统降级态**：依赖缺失 / 数据表非法 / 存档不可用 | §1.5 E3/E4/E8 | 安全停在 IDLE 或只读降级，不写 flag、不谎报通过；如实登记日志 |
| F6 | **视觉未达态**：Boss 无可见像素形象 / 战斗数值停摆 / HD-2D 全绿未达 | 工程根 `README.md`「还差什么」第 12 项（R24 目视回看实证） | 属 Rank-4 素材 / Rank-1 画面与用户侧人工试玩，Rank-3 不代验、不宣称完成 |

> F2~F4 的具体阈值**全部引用 Rank-2 `WAVE-TRIAL-TUNING.md` 的 `broken` 定义与 `[PLACEHOLDER]` 表**，本 GDD 不写数字、不另造判据。

---

## 2. 核心循环（行动 → 反馈 → 目标 → 再行动）

```
  ┌───────────────────────────────────────────────────────────────┐
  │                                                               │
  ▼                                                               │
【目标】第 N/3 波 · 时限内清波 · 刷新历史最高波次                      │
  │                                                               │
  ▼                                                               │
【行动】入场读秒(telegraph_sec) → 看清敌人与退避带 → 移动/翻滚/攻击    │
  │                                                               │
  ▼                                                               │
【反馈】命中/击杀 · HUD(第N/3波|赐福点数|倒计时|历史最佳) · 清波结算    │
  │                                                               │
  ├─ 清波 ──> 【目标更新】wave_cleared → 点数入账 → NEXT_WAVE ─────────┤
  │            （下一波倍率/招式权重抬升，重新读场）                    │
  ├─ 三波全清 ─> trial_completed → best_wave/completed 落盘 ──────────┤
  │              → 回赐福，可再次挑战（长期循环）                       │
  └─ 超时/死亡 ─> 失败回赐福休息 → 再次挑战（不回退历史量） ───────────┘
```

- **行动**：读秒结束后玩家在退避带与敌人间做位置 / 时机决策；输入沿用既有战斗件，不新增。
- **反馈**：每一次行动都有可见回执 —— 命中 / 击杀表现、HUD 四个只读数字、清波结算的点数跳动、下一波预告抬压。
- **目标**：短期 = 在 `time_limit_sec`（任务单口径 30 秒级）内清掉当前波；中期 = 一局三波全清；长期 = 刷新 `dungeon.wave_trial.best_wave` 历史最高波次。
- **再行动**：清波 → 下一波（更紧但可读）；失败 / 全清 → 回赐福 → 重复挑战。三波循环与跨局循环共用同一套 flag，不产生「局内临时变量跨场景携带」（`存档与flag规范.md` §2.4 禁止项）。

---

## 3. 目标梯度与留存钩子

| 梯度 | 时间尺度 | 目标 | 对应持久化量 | 反馈位置 |
|---|---|---|---|---|
| **短期** | 30 秒级（`time_limit_sec` `[PLACEHOLDER]`，任务单口径「30 秒短期」） | 在时限内清掉当前波 | 无（局内进度由导演层持有） | 倒计时 / 第 N/3 波 |
| **中期** | 一局（三波） | 三波全清 | `dungeon.wave_trial.completed`（bool，只增不减） | HUD 历史最佳 / 结算 |
| **长期** | 跨局 / 跨重启 | 刷新最高波次、累计赐福点数 | `dungeon.wave_trial.best_wave`（int 单调递增）、`grace.trial.points`（int 单调递增） | HUD 历史最佳 / 赐福点数 |

**留存钩子**：

1. **历史最佳**（`best_wave`）：每局都把「这次能到第几波」变成可比较的数字；只增不减，重启不丢（§6 / `verify_wave_flags_v040.gd` D 类断言）。
2. **赐福点数**（`grace.trial.points`）：清波即入账、累计不清除，把单局收益沉淀为跨局资产；具体 `reward_points` 以 TUNING.md 为准。
3. **全清完成标记**（`completed`）：三波全清是一次性永久成就，后续失败 / 重复挑战不翻转，给「通关」一个不可撤销的确认。
4. **重复挑战入口**：复用既有赐福菜单「重复挑战」链路（`grace.encounter_01.retried` 等 R25 flag 同命名空间），不新增 UI；一局失败不惩罚历史量，降低重试成本。
5. **可校准难度曲线**：数值全在 Rank-2 `[PLACEHOLDER]` 表，人工试玩后只调表不改码，让「再打一局」持续优化手感（§5）。

---

## 4. Level Designer blockout 说明

> 本节按 Level Designer 标准给出**空间与节奏**口径，不写坐标数值、不改 `courtyard.tscn`（归 Rank-1）。四条硬要求：**入场读秒 + 敌人可见预告 + 退避空间 + 三波空间节奏**。

### 4.1 入场读秒（telegraph）

- 进入试炼先 `IDLE → TELEGRAPH`，时长引用 `telegraph_sec` `[PLACEHOLDER]`（§0.1）。
- 读秒期间**不生成伤害判定**，玩家可自由移动、定位退避带；HUD 倒计时与「第 N/3 波」同时点亮。
- 读秒归零才进 `WAVE_ACTIVE`；读秒被中断（退出 / 依赖缺失）按 §1.5 E4/E5 降级，不写 flag。

### 4.2 敌人可见预告

- 读秒窗口内把本波 `enemy_id` 对应敌人**提前可见**（轮廓 / 生成点 / 招式起手预告），预告内容与 Rank-2 数据表 `enemy_id` / `move_weight` 对齐。
- 预告须「可判」：玩家在受击前能读出敌人类型与出招方向；高频招式（`move_weight` 高）必须先有可见前摇，避免「看不见就死」。
- 复用既有 `enemy_01_limgrave_soldier` / `boss_01_margit` 数据表 id，不新增数据表、不新增敌人资源（Rank-2 口径）。

### 4.3 退避空间

- 战斗区须留出**连续可退避带**：玩家从敌人近身位能靠翻滚 / 走位脱离到安全距离再回场；不带即死死角、不靠隐藏墙提示（契约 §5「隐藏墙不给任何提示」不适用于此处：试炼区必须可读）。
- 退避带与生成点分离：预告位在视野内、退避位在威胁范围外，二者不重叠。
- HUD 四标签放在既有占位之外（避开赐福 HUD / 画质面板 / 底部战斗 HUD，见 Rank-1 任务单），不遮挡退避带与敌人预告位。

### 4.4 三波空间节奏（blockout 表）

| 波 | 空间节奏 | 预告 | 退避 | 数值引用 |
|---|---|---|---|---|
| 第 1 波 | **教学 / 读场**：单方向来敌、空间最宽，让玩家熟悉读秒与退避带 | 最完整（类型 + 起手） | 最宽裕 | `hp_multiplier` / `move_weight` / `reward_points` / `telegraph_sec` / `time_limit_sec` 第 1 波 `[PLACEHOLDER]` 行 |
| 第 2 波 | **加压 / 换向**：来敌方向或组合变化，退避带略收，逼玩家重新读场 | 保留起手预告 | 中等 | 同表第 2 波行 |
| 第 3 波 | **收束 / 结算**：空间最紧、倍率与招式权重最高，清完即 `TRIAL_COMPLETED` | 起手预告仍可见（不取消公平性） | 最窄但连续 | 同表第 3 波行 |

- 三波共用同一战斗区（不切场景），靠**生成点 / 预告位 / 退避带宽度 / 倍率**做节奏差异，避免加载打断循环。
- 波间 `WAVE_CLEARED → NEXT_WAVE` 保留一个短结算窗口（点数入账 + 下一波预告），具体节奏由 Rank-1 状态机编排、Rank-3 不定义时序数值。

---

## 5. 难度曲线

- 曲线形态：**逐波单调抬压、但每波都保留可读窗口**。`hp_multiplier` / `move_weight` 逐波上升，`time_limit_sec` 与 `telegraph_sec` 维持可读下限，`reward_points` 与风险同步上升 —— 全部引用 TUNING.md `[PLACEHOLDER]` 表（§0.1），本 GDD 不写斜率、不写倍率数字。
- 三条约束：① 第 1 波必须可在时限内完成（否则 F2 难度过高）；② 三波全清不得过快（否则 F3 难度过低）；③ 点数增速与耗时 / 风险匹配（否则 F4 通胀）。
- 校准方式：**只调 Rank-2 `WAVE-TRIAL-TUNING.md` / `wave_trial.tres` 的 `[PLACEHOLDER]` 数值，不改代码、不改本 GDD 结构**（契约 §5「数据表改数值不改代码」）。broken 判据与阈值以 TUNING.md 的 `broken` 定义为准，待人工试玩校准。
- 曲线与存档解耦：难度调整不影响 `best_wave` / `completed` / `points` 的单调语义；调表后旧存档不迁移、不重置（§6）。

---

## 6. 存档落盘口径（与契约 §3.3 对齐）

### 6.1 三段式 flag 定义

| key | 类型 | 读写方 | 单调性 |
|---|---|---|---|
| `dungeon.wave_trial.best_wave` | int（基线 `0`） | 写：Rank-3（订阅 `trial_completed` / 波次推进，按 `max(旧值, 本局最高波次)` 更新）／读：波次 HUD「历史最佳」、回放断言 | **单调递增、只增不减**：不清零、不回退、重启不丢 |
| `dungeon.wave_trial.completed` | bool（基线 `false`） | 写：Rank-3（三波全清置 `true`）／读：HUD / 成就门控 / 回放断言 | **只增不减（false → true 单向）**：失败 / 重启 / 重复挑战均不置回 `false` |
| `grace.trial.points` | int（基线 `0`） | 写：Rank-3（订阅 `wave_cleared(index,points)` 累加，具体 `reward_points` 读 Rank-2 表）／读：波次 HUD「赐福点数」、回放断言 | **单调递增、永不清除**：清波即入账、休息不清零、重启不丢 |

- 三 key 均通过 §2 三段式正则 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`：`dungeon` / `grace` 前缀合法，`wave_trial` / `trial` 对象段合法，`best_wave` / `completed` / `points` 状态段合法；`world_state.gd` 的 `FLAG_KEY_REGEX` 无需修改。

### 6.2 与 §4.4 十字段、`schema_version=3` 的关系

- 项目 `SaveDelta` 十字段（`schema_version / slot / seq / baseline / flags / quests / inventory / spawns / removals / meta`，`存档与flag规范.md` §4.1 定义、§4.4 回放合并消费）**冻结、不得新增顶层字段**。
- 三个新 flag **只作为 `flags` 字典内的新 key** 落进既有结构，不新增顶层字段、不改字段类型、不引入嵌套结构（`存档与flag规范.md` §3.2 收敛规则 INV-6）。
- 因此 **`schema_version` 保持 `3`、不触发 §4.7 迁移链**：新 key 属「相对基线的变化 flag」，回放时按 §4.4「LWW by timestamp / 写入顺序」合并，同 key 多行取后写覆盖；与 R25 两个 `grace.encounter_01.*` flag 同机制。
- 类型冲突按 §4.4「以 §3.3 登记表声明类型为准，无法转换则丢弃该行并 `push_warning`」处理（§1.5 E8）。

### 6.3 `commit(reason)` 强制落盘点

| # | 落盘点 | reason（写入 `meta.last_commit_reason`） | 写入内容 |
|---|---|---|---|
| P1 | 每波 `wave_cleared` 结算 | `wave_trial_cleared` | `grace.trial.points` 累加、必要时 `best_wave` 取 `max` |
| P2 | 三波全清 `trial_completed` | `wave_trial_completed` | `completed=true`、`best_wave=max`、末波点数 |
| P3 | 失败 / 超时 / 主动退出结算 | `wave_trial_settled` | `best_wave` 按已抵达波次取 `max`；`completed` 不动 |
| P4 | 重启恢复 | `load`（既有口径） | 只读 `_load()` 回放，不新增写盘 |

> reason 字面量仅进 `meta.last_commit_reason`，**不是新顶层字段**、不触发迁移；与 R25 `grace_retry` 同机制（是否复用既有 reason 由总指挥裁决，不影响时序）。

### 6.4「先落盘再改运行时实例」顺序

每一次 P1~P3 的写入严格按以下顺序，不得颠倒：

```
1. 由 Rank-1 信号得到结算结果（本局最高波次 / 本波点数 / 是否全清）
2. 计算新值：best_wave = max(旧, 本局最高)；points = 旧 + 本波点数；completed 仅在全清置 true
3. ★ 强制 commit(reason)：SaveDeltaWriter 按十字段结构原子写（.tmp → flush → rename → delta.json）
4. ★ 落盘成功后，才更新 WorldState 运行时 flag 实例并 emit flag_changed（HUD 增量刷新）
5. 若第 3 步失败：不执行第 4 步，运行时保持旧值，如实告警，绝不「内存已改、磁盘未改」
```

理由：磁盘是唯一权威（§1.5 E5 / E6）。若先改运行时再落盘，进程被杀会产生「HUD 显示已到账、重启后丢失」的不一致；先落盘再改实例保证任何时刻运行时实例都是磁盘态的镜像。`verify_wave_flags_v040.gd` 的 E1 断言以事件序列 `disk_write → runtime_update` 机器判定该顺序。

---

## 7. 验证与校对清单

| # | 项 | 载体 / 状态 |
|---|---|---|
| V1 | 三段式正则（3 key 通过 + 六类反例拒绝） | `verify_wave_flags_v040.gd` A 类 |
| V2 | `best_wave` 单调递增、不回退、多次挑战取历史最高 | 同 B 类 |
| V3 | `completed` 只增不减、`points` 单调递增 | 同 C 类 |
| V4 | 重启读回一致（落盘 → 新实例 `_load()` → 逐项比对；write/read 两独立引擎进程实证） | 同 D 类 |
| V5 | commit 顺序、十字段齐全 / `schema_version=3`、落盘 flags 全合法 | 同 E 类 |
| V6 | 31 PASS 存档 / HUD 回归不回退 + 三段门禁 `grep SCRIPT ERROR=0` | R26 真跑（见 `DONE-R26.md`） |
| V7 | **`WAVE-TRIAL-TUNING.md` 落地后校对**：§0.1 引用键名 / rationale / broken 定义与 Rank-2 实际表一致；不一致改本 GDD 引用段、不改数据表 | **待 Rank-2 并发产出落地后执行（本轮未达，如实登记）** |
| V8 | 人工试玩校准 `[PLACEHOLDER]` 数值、15~20 秒实机录屏回看、HD-2D 全绿 | **属用户侧 / Rank-1 / Rank-4，Rank-3 不代做、不宣称完成**（工程根 `README.md`「还差什么」） |

---

## 8. 关联

- `teamwork/Rank-2/WAVE-TRIAL-TUNING.md`（数值唯一真源，`[PLACEHOLDER]` 表 / `broken` 定义）、`wave_trial_config.gd` / `data/rpg/wave_trial.tres`（Rank-2 并发产出）
- `wave_trial_director.gd` / `courtyard.tscn` / 波次 HUD（Rank-1 并发产出）
- `teamwork/00-协作契约.md` §3.3（三段式 flag 登记表）、`teamwork/Rank-3/存档与flag规范.md` §3.1 / §3.3 / §4.1 / §4.4 / §4.7 / §4.8（flag 与十字段真源）
- `teamwork/Rank-3/GRACE-RETRY-V020.md`（R25 重复挑战口径）、`verify_grace_flags_v030.gd`（R25 自测先例）
- `teamwork/Rank-3/verify_wave_flags_v040.gd`（本轮验证载体）、`teamwork/Rank-3/DONE-R26.md`（真跑结论）、工程根 `README.md`（状态表）
