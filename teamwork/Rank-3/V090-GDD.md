# V090-GDD.md — 试炼词条 + 打击反馈 + 满愿闭环（v0.9.0 / R31 / Rank-3）

> 工位：3 号（RPG / 世界 / 存档）· `cmd-20261111-133549-886-A3` · `[ROUND=R31]` · v0.9.0
> 按 **game-development-pro / Game Designer 六项**（purpose / player experience goal / inputs / outputs / edge cases / failure states）编写；所有新数值标 `[PLACEHOLDER]` 待人工试玩校准并写 rationale，Rank-3 不另造数值、不改数据表、不写 `godot/` 业务代码。
> 本文是 R31 **新写**的设计口径文档；`WAVE-TRIAL-GDD.md` / `CODEX-GDD.md` / 工程根 `README.md` 只追加 R31 / v0.9.0 状态段、不改历史条款。
> 真跑结论见 `teamwork/Rank-3/DONE-R31.md`；机器判定载体见 `godot/scripts/rpg/verify_v090_save_readback.gd`。

---

## 0. 定调与边界（先定调再产出）

v0.9.0 是「**完善旧内容**」轮：把 v0.4 波次试炼 / v0.5 赐福成长 / v0.6 三步教学 / v0.8 赐福图鉴这条长期动机链，用三个子系统补齐三处断点 ——

1. **试炼词条（Trial Modifier）**：每局三波规则恒定、重复挑战只有数值累积没有单局变量 → 在**波间**注入一条可变的本局规则，用 `grace.trial.modifier_active`（String / 非单调·局内翻转）表达当前生效词条。
2. **打击反馈（Impact Feedback）**：命中 / 受击缺少即时可读的画面事件，玩家归因困难 → 用顿帧 / 震屏 / 粒子 / 音效把「打中了 / 该退了」变成可目视事件，**不改战斗数值、不改帧数据**。
3. **满愿闭环（Full Wish）**：四项图鉴成就全解锁后没有收束时刻 → 把「教学→三波→成长→图鉴」四级梯度收束为一次性、不可重复的里程碑，用 `grace.codex_full_wish.notified`（bool / false→true 单向）保证只触发一次。

**目录所有权（R31 任务单，Rank-3 严格不越界）**：

| 子系统 | 数据 / 纯逻辑 | 呈现 / 接线 | 口径 / 存档 / 验证 |
|---|---|---|---|
| 试炼词条 | **Rank-2**：`trial_modifiers.tres` / `trial_modifier_config.gd` / `trial_modifier_service.gd` / `verify_trial_modifier_v090.gd` | — | **Rank-3**：`grace.trial.modifier_active` 登记、本文、`verify_v090_save_readback.gd` |
| 打击反馈 | — | **Rank-1**：`impact_feedback.gd` / `hud.gd` / `presentation.gd` / `verify_impact_feedback_v090.gd` | — |
| 满愿闭环 | **Rank-2**：`verify_codex_full_wish_v090.gd` | **Rank-1**：演出 / HUD | **Rank-3**：`grace.codex_full_wish.notified` 登记、本文、`verify_v090_save_readback.gd` |
| 素材 | — | — | **Rank-4**：`assets/generated/r23/impact_fx.png` 等 |

> Rank-3 本轮只产出**设计口径 + 只读回读验证脚本**，不代验 Rank-1 打击反馈接线 / Rank-2 词条表与纯逻辑 / Rank-4 素材与录屏，不宣称运行时已接通。所有 `[PLACEHOLDER]` 数值待人工试玩校准（headless 真跑不做手感 / 审美判断）。

---

## 1. purpose（设计目的）

- **闭合单局变量断点**：v0.4 三波 `reward_points` 100/150/200 与三波结构固定，重复挑战只累积 `grace.trial.points`；词条在不新增第二套点数来源、不改三波结构的前提下，让「这局和上一局不同」成为可读信息。
- **闭合命中读感断点**：既有战斗有帧数据 / 无敌窗口 / 攻击力，但「打中了」只靠数值变化，缺即时反馈；打击反馈把命中事件变成可目视层，且**不碰战斗数值与判定**（沿用 R27「数据表改数值不改代码」）。
- **闭合长期动机末端断点**：R30 图鉴四项成就（`tutorial_complete` / `wave_trial_clear` / `all_grace_upgrades` / `best_wave_3`）全解锁后，玩家没有「我完成了」的确认时刻；满愿闭环给这条四级梯度一个不可重复的收束。
- **不惩罚原则沿用**：词条选择不扣点、失败 / 退出 / 重启不回退既有 flag、满愿不重复触发、旧存档缺 key 回落基线不升级。

## 2. player experience goal（玩家体验目标）

| 时间尺度 | 玩家应能回答 | 承载子系统 |
|---|---|---|
| 每局开局 30 秒内 | 「这局和上一局有什么不同」 | 试炼词条（HUD 词条条 + 波间选择） |
| 每次交锋瞬间 | 「我打中了 / 我被打中了 / 我该退了」 | 打击反馈（顿帧 / 震屏 / 粒子） |
| 一次三波周期内 | 「我现在攒了多少、能换什么」 | 既有 `points` / `spent_points` / `unlocked`（不改） |
| 全收集终点 | 「我完成了」 | 满愿闭环（一次性演出 + 永久标记） |

- 目标不是「更难的战斗」，而是「**更可读的战斗 + 有终点的收集**」；难度空间优先于数值缩放（沿用 `WAVE-TRIAL-SPATIAL.md`）。
- 不制造第二套点数经济：词条 / 反馈 / 满愿都不新增顶层字段、不写 `removals`、不回退 `points`。

## 3. inputs（输入）

| # | 输入 | 来源 | 消费方 | 口径 |
|---|---|---|---|---|
| I-1 | 词条数据表（id / 显示名 / 倍率 / 时长 `[PLACEHOLDER]`） | Rank-2 `trial_modifiers.tres` | Rank-2 `trial_modifier_service`（RefCounted 纯逻辑） | 只读；Rank-3 不写、不校对数值 |
| I-2 | 波间选择 / 系统施加词条 | 玩家输入 / 导演层 | `grace.trial.modifier_active`（String） | 三段式；空串 `""` = 无活跃词条 |
| I-3 | 命中 / 受击 / 格挡事件 | 既有战斗（Rank-2） | Rank-1 `impact_feedback.gd` | 不改帧数据 / 不改判定 |
| I-4 | 四项 `grace.codex_<id>.unlocked` | 既有 `flags` 字典 | 满愿条件门控 | 四项**全 true** 才达成 |
| I-5 | `grace.trial.points` / `grace.trial.spent_points` | 既有 `flags` 字典 | 余额门控 | `points − spent_points ≥ 0` 硬约束（R27 F1~F8 沿用） |
| I-6 | `grace.trial.modifier_active` / `grace.codex_full_wish.notified` | 本轮新 `flags` key | 词条 HUD / 满愿演出门控 / 回放断言 | 见 §11；纯读 `get_flag` |
| I-7 | `commit(reason)` 强制落盘点 | Rank-3 I-1 权威 | `meta.last_commit_reason`（既有字段） | `trial_modifier_applied` / `codex_full_wish_notified`；reason 不是新顶层字段 |

## 4. outputs（输出）

| # | 输出 | 落点 | 单调性 / 约束 |
|---|---|---|---|
| O-1 | 当前生效词条 id | `grace.trial.modifier_active`（String / 基线 `""`） | **非单调·局内翻转**：一局内可 `"" ↔ <id>` 翻转、可回写不同 id；结算 / 重启置 `""` |
| O-2 | 词条切换 / 生效落盘 | `commit("trial_modifier_applied")` → 十字段 `SaveDelta` 原子写 | 先落盘再改运行时实例；失败不执行运行时更新 |
| O-3 | 命中 / 受击画面反馈 | Rank-1 呈现层（**不写 flag**） | 不改战斗数值、不进存档 |
| O-4 | 满愿已通知 | `grace.codex_full_wish.notified`（bool / 基线 `false`） | **false→true 单向**：一次性永久标记，无 `false` 回写路径 |
| O-5 | 满愿达成落盘 | `commit("codex_full_wish_notified")`，与末次 `unlocked` 同一原子写 | 同上 |
| O-6 | 存档三态读回一致性 | `verify_v090_save_readback.gd`（write / load / assert） | 磁盘为唯一权威；11 项关键 flag 三方一致 |
| O-7 | 既有梯度 / 点数 / 永久增益 | `WAVE-TRIAL-GDD.md` §9 / §10、`CODEX-GDD.md` §8 | **沿用不改** |

## 5. edge cases（边界情况）

| # | 情况 | 处理 |
|---|---|---|
| E-1 | 词条 id 为空 / 未知 id / 数据表缺行 | 回落 `""`（无词条），不写非法 key、不崩、不落盘 |
| E-2 | 一局内多次切换词条 | `modifier_active` 按 §4.4「LWW 后写覆盖」取最后一次；重启读回以磁盘最后一次为准 |
| E-3 | 结算（胜 / 败 / 主动退出）或重启恢复 | `modifier_active` 置 `""`；`_load()` 后若非空且无活跃词条实例，判为上次异常中断并置 `""`（同 `grace.encounter_01.retry_active` 机制） |
| E-4 | 旧存档缺两个新 key | `get_flag(key, default)` 回落 `""` / `false`，**不升级、不重置、不写 `removals`**（`verify_v090_save_readback.gd` E 组 11 项已实证） |
| E-5 | 四项 `unlocked` 未全 true | 不置 `notified`、不触发满愿演出 |
| E-6 | 满愿重复达成 / 重启 / 重复挑战 | `notified` 无 `false` 回写；演出门控读 `notified`，不重播 |
| E-7 | 余额不足 / 超额消费 / 重复购买 | 落盘前由 Rank-2 `can_purchase` 门控拒绝，不写任何 flag（R27 F1~F8） |
| E-8 | 词条奖励叠加使 `points` 溢出或余额为负 | 拒绝该词条结算、不写 `removals`、不回退 `points` |
| E-9 | 打击反馈与既有 HUD 五套占位冲突 | 降级为「不改画面、只保留逻辑」，如实登记「数据已落、效果待接」，不伪造生效 |
| E-10 | `--script` 工具进程 / 依赖缺失 / writer 缺失 | 降级不崩：不写 flag、不落盘、如实登记（沿用 R26 §6.4 五步第 ⑤） |

## 6. failure states（失败状态）

| # | 失败态 | 行为 | 判据 |
|---|---|---|---|
| F-1 | 词条数据表缺失 / service 不可用 | 本局无词条，`modifier_active=""`，三波照常推进、不崩 | `get_flag` 返回 `""` |
| F-2 | 落盘失败（rename / flush 失败） | 不执行「改运行时实例」，运行时保持旧值、如实告警，绝不「内存已改、磁盘未改」 | 五步顺序第 ⑤ |
| F-3 | 打击反馈脚本不可用 / 解析失败 | 只丢弃画面反馈，不影响战斗与存档；如实登记（R31 首次 G3 的 5 条 `SCRIPT ERROR` 属 Rank-1 并发瞬时半成品、非本设计引入，见 `DONE-R31.md`） | 战斗 / 存档断言仍全绿 |
| F-4 | 满愿演出资源缺失 | `notified` 仍按条件置位（**数据已落、效果待接**），不伪造演出已播 | 单向断言 + 读回 |
| F-5 | 旧存档 `schema_version > 3` | 拒绝加载、保留文件不动（`存档与flag规范.md` §4.7） | 不猜测字段 |
| F-6 | 生产 `slot_01` 被并发方写入 | 验证走独立 PID 临时槽、只做 md5 只读前后对照；不同只登记 WARN、不误判 FAIL | `verify_v090_save_readback.gd` F 组 |
| F-7 | 人工试玩判定 `[PLACEHOLDER]` 数值失配 | 回调数据表 / 引用段、不改代码（沿用 R30 broken B1~B4 口径） | 试玩校准 |

## 7. broken 判据（可机器 / 目视判定）

| # | broken 定义 | 判定方式 | 回调方向 |
|---|---|---|---|
| **B1** | **词条不可辨**：切换后 HUD 词条条在 `[PLACEHOLDER]` 帧内读不到 `modifier_active`，或文案与 id 不一致 | 目视（15~20 秒录屏回看，归 Rank-4 / 用户侧）+ 读回断言 | 下调读秒 / 修 HUD 绑定，不改数据表 |
| **B2** | **词条瞬态落盘丢失**：局内翻转未经 `commit` 先落盘，重启读回与当局不符（破坏「磁盘唯一权威」） | **机器判定**：`verify_v090_save_readback.gd` B 组 11 项「读回 == 磁盘 == 期望」 | 修「先落盘再改运行时实例」顺序 |
| **B3** | **打击反馈遮蔽**：反馈特效遮挡角色 / 敌人判定框，或侵入既有 HUD 五套占位；或单次反馈时长 > `[PLACEHOLDER]` 秒造成操作迟滞 | 目视（录屏回看，归 Rank-4 / 用户侧） | 降强度 / 缩时长 / 挪安全区 |
| **B4** | **满愿重复触发**：`notified` 出现 `true→false` 回写，或重启后演出重播 | **机器判定**：单向断言 + 三态读回 | 去掉 false 回写路径、演出门控读 flag |
| **B5** | **满愿不可达 / 奖励通胀**：四项 `unlocked` 条件不可达、`reward_points` 梯度破坏 30<50<80<120 或合计 280（沿用 R30 B1~B4） | Rank-2 校验脚本 + 引用校对 | 回白名单 / 下调阈值 / 保持单调 |
| **B6** | **经济 / 结构破损**：`points − spent_points < 0`、`removals` 非空、`schema_version != 3`、顶层出现额外字段、或 flag key 未过三段式正则 | **机器判定**：`verify_v090_save_readback.gd` C / D 组 | 拒绝该次结算、回十字段结构 |

> B2 / B4 / B6 在 R31 已由 `verify_v090_save_readback.gd` 三进程三态真跑实证为「未 broken」（56 PASS / 0 FAIL，见 `DONE-R31.md`）；B1 / B3 / B5 属画面 / 数据表侧，Rank-3 不代验、不宣称已判定。

## 8. 空间节奏影响（Level Designer 视角，只写规格不改场景）

- **词条选择 / 切换的时序位置**：严格发生在**波间安全区**（沿用 `WAVE-TRIAL-SPATIAL.md` S5 连续退避带），不打断 TELEGRAPH 读秒、不新增敌人预告、不把选择窗口塞进 `on_encounter_finished` 同帧；词条 HUD 落在既有五套占位之外的新条带，`[PLACEHOLDER]` 位置待目视校准。既有占位实测（R29B / R30）：赐福 HUD `x<730, y<220` / 画质面板 `x>760, y<180` / 兑换面板 `rect=(740,358)-(1276,568)` / 图鉴面板 `rect=(24,272)-(380,508)`。
- **三波节奏与反馈强度**：顿帧 / 震屏强度随「教学 → 加压 → 收束」三段递增，但**难度空间优先于数值缩放**（沿用 R27）：反馈不新增退避带、不改变敌人站位、不给数值难度加成；反馈时长 `[PLACEHOLDER]` 秒，超过即判 B3。
- **不破坏 A38**：三子系统**不新增场景、不写 `courtyard.tscn`、不改 UV**；`courtyard.tscn` 节点数 41 与 `uv_groundplate_2` / `uv_terracelow_1` / `uv_terracehigh_1` 本轮不得破坏（R31 G3 真跑回读 `node_count=41` 已证，见 `R31-G3-quit-retry.log`）。
- **满愿演出的空间读秒**：在**最后一次赐福休息 / 图鉴全解锁结算后的静止帧**触发，不在战斗 TELEGRAPH / 敌人预告期间插入；演出期间冻结波次推进、不刷新敌人（沿用 `存档与flag规范.md` §4.6 休息语义），结束后回到既有循环。
- **密度优先于尺寸**（契约 §5）：不扩大庭院尺寸、不新增隐藏墙提示、不新增跨场景切镜。

## 9. 三个子系统逐项规格

### 9.1 试炼词条（Trial Modifier）

- 一局三波共享**一条**当前生效词条；波间可切换 / 系统施加，值域 = 数据表 id 或 `""`。
- 权威状态 = `grace.trial.modifier_active`（String）。切换严格走五步：① 取 Rank-2 service 判定结果 → ② 计算新值（id 或 `""`）→ ③ ★ `commit("trial_modifier_applied")` 十字段原子写 → ④ ★ 落盘成功后才更新运行时 flag 实例 + `emit flag_changed`（词条 HUD 增量刷新）→ ⑤ ③ 失败则不执行 ④、保持旧值、如实告警。
- **非单调合法性**：`String` 值走 `get_flag(key, "")`；`§4.4` LWW 后写覆盖使局内翻转在回放语义下合法，与 `grace.encounter_01.retry_active` 同机制；**不表达成就、不持久化累积**。
- 数据表 / 倍率 / 时长归 Rank-2；Rank-3 只登记 key 口径与落盘顺序。

### 9.2 打击反馈（Impact Feedback）

- 消费既有命中 / 受击 / 格挡事件，输出顿帧 / 震屏 / 粒子 / 音效；**只读事件、不写 flag、不进存档**。
- 与词条联动：不同词条可给反馈不同强度档（`[PLACEHOLDER]`），但强度档不写进存档、不改战斗数值。
- 归属 Rank-1；首次 G3 的 `cosf()/sinf()` 解析错误属 Rank-1 并发写入的瞬时半成品（见 §6 F-3 / `DONE-R31.md`），Rank-3 不代修。

### 9.3 满愿闭环（Full Wish）

- 达成条件：四项 `grace.codex_<id>.unlocked` 全为 `true`（R30 四项成就），且余额 `points − spent_points ≥ 0`。
- 首次达成：与末次 `unlocked` **同一原子 `commit("codex_full_wish_notified")`** 置 `grace.codex_full_wish.notified = true`，然后触发一次性收束演出。
- 演出门控读 `notified`：`true` 则不再重播；**false→true 单向**、无 false 回写路径、重启不丢。
- 闭环定位：教学（v0.6）→ 三波（v0.4）→ 成长（v0.5）→ 图鉴（v0.8）→ **满愿（v0.9）**，第五层是里程碑确认、不是新的点数来源或难度层。

## 10. `[PLACEHOLDER]` 数值表与 rationale（Rank-3 不填具体设计数值）

| 数值 | 值 | rationale |
|---|---|---|
| 词条条数 / 每条 id 与显示名 | `[PLACEHOLDER]` | 归 Rank-2 `trial_modifiers.tres`；Rank-3 只用示例 id `frost_bite` 做三态回读夹具、不冒充正式表 |
| 词条倍率 / 持续时长 / 生效波次 | `[PLACEHOLDER]` | 需人工试玩校准「单局变量是否可读且不破坏三波节奏」；不写进代码、不改既有 `reward_points` |
| 波间选择窗口 | `[PLACEHOLDER]` 秒 | 必须短于 TELEGRAPH 读秒、长于一次误触；由 `WAVE-TRIAL-SPATIAL.md` S5 退避带目视校准 |
| 打击反馈单次时长 | `[PLACEHOLDER]` 秒 | 超过即判 B3「操作迟滞」；需 15~20 秒录屏回看定档 |
| 震屏幅度 / 粒子数 | `[PLACEHOLDER]` px / 个 | 受 HD-2D 低分辨率 640×360 + Nearest 放大约束，过大破坏像素可读性 |
| 满愿演出时长 | `[PLACEHOLDER]` 秒 | 只在静止帧、不打断战斗；与 A38 节点数 / UV 无冲突 |
| 满愿额外奖励 | `[PLACEHOLDER]`（建议 0） | 防第二套点数来源 / 奖励通胀（R30 B2）；只作里程碑确认，不叠加既有 280 图鉴奖励 |
| 词条 HUD 安全区坐标 | `[PLACEHOLDER]` | 必须避开 §8 列出的五套既有占位；由目视校准 |
| 验证夹具 `points / spent_points / balance` | `1000 / 600 / 400` `[PLACEHOLDER]` | **非设计数值**：仅用于 `verify_v090_save_readback.gd` 三态确定性回读；`spent` 取既有 R27 三项 `cost` 100/200/300 之和保证余额非负，`points` 取足以覆盖消费的整数，均为整数不受 JSON int→float round-trip 影响；待校准时同步 `FIX_*` 常量与 `DONE-R31.md`、不静默改数 |
| `modifier_active` 示例值 | `frost_bite` `[PLACEHOLDER]` | 仅用于证明 String 类型 / 三段式正则 / 三方读回一致；正式词条 id 以 Rank-2 落地表为准 |
| `notified` 终值 | `true` `[PLACEHOLDER]` | 单向 bool 终值；基线 `false` 固定 |

## 11. 三段式 flag 与存档口径（真源链）

| key | 类型 / 基线 | 单调性 | 写入方 | 读方 |
|---|---|---|---|---|
| `grace.trial.modifier_active` | **String** / `""` | **非单调·局内翻转**（一局内 `"" ↔ <id>` 可翻转；结算 / 重启置 `""`） | Rank-3（I-1 `set_flag` 权威；词条编排在 Rank-2 service 判定通过后，与词条结算同一 `commit("trial_modifier_applied")` 原子先落盘） | 词条 HUD / 打击反馈层门控 / 回放断言（纯读 `get_flag`） |
| `grace.codex_full_wish.notified` | **bool** / `false` | **false→true 单向**（一次性永久标记，无 false 回写） | Rank-3（四项 `grace.codex_<id>.unlocked` 全 true 且首次达成时置 `true`，与末次 `unlocked` 同一 `commit("codex_full_wish_notified")` 原子先落盘） | 满愿一次性演出门控 / 回放断言 |

- **三段式合法性**：两 key 的 `grace` 前缀、`trial` / `codex_full_wish` 对象段、`modifier_active` / `notified` 状态段严格匹配 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`（契约 §2 / 规范 §3.1）；`world_state.gd` 的 `FLAG_KEY_REGEX` 无需修改、无需迁移、不改 `schema_version`。
- **十字段冻结**：`SaveDelta` 十字段（`schema_version / slot / seq / baseline / flags / quests / inventory / spawns / removals / meta`，`存档与flag规范.md` §4.1）**冻结、不得新增顶层字段**；两 flag **只作为 `flags` 字典新 key**（INV-6 / §3.2 收敛规则），不新增顶层字段、不改字段类型、不引入嵌套结构，**`schema_version` 保持 `3`、不触发 §4.7 迁移链**；**本轮不写 `removals`**、不回退 `grace.trial.points`。
- **回放 / 旧档**：按 §4.4「LWW by timestamp / 写入顺序」合并、同 key 多行取后写覆盖，类型冲突以登记表声明类型为准（无法转换丢弃该行并 `push_warning`）；`modifier_active` 非单调翻转在 LWW 下合法；**旧存档缺这两个 key 时 `get_flag(key, default)` 回落基线 `""` / `false`，不升级、不重置**。
- **落盘点**：词条切换 / 生效 `trial_modifier_applied`、满愿首次达成 `codex_full_wish_notified`、重启恢复 `load`（只读 `_load()`）；reason 仅写 `meta.last_commit_reason`，不是新顶层字段、不触发迁移。
- **真源链**：`teamwork/00-协作契约.md` §3.3 R31 说明段（登记）· `teamwork/Rank-3/存档与flag规范.md` §3.1 / §3.3 / §4.1 / §4.4 / §4.7（flag 与十字段权威）· `godot/scripts/rpg/verify_v090_save_readback.gd`（三态机器判定）· `teamwork/Rank-3/DONE-R31.md`（真跑结论）。

## 12. 校对清单 / 本轮未达项（如实登记）

| # | 项 | 状态 |
|---|---|---|
| V-1 | Rank-2 词条表落地校对：引用键名 / `[PLACEHOLDER]` 数值 / rationale / broken 定义与 Rank-2 `trial_modifiers.tres` 一致；不一致**改本文引用段、不改数据表** | **待 Rank-2 并发产出落地后执行（本轮未达，Rank-3 不代验）** |
| V-2 | Rank-1 打击反馈接线 / HUD 词条条 / `presentation.gd` 演示序列 / 满愿演出运行时接线 | **属 Rank-1 并发实现，Rank-3 不代验、不宣称已接通** |
| V-3 | Rank-4 素材 / 15~20 秒实机录屏目视回看（B1 / B3 判据） | **属 Rank-4 / 用户侧，Rank-3 不代做、不宣称完成** |
| V-4 | 全部 `[PLACEHOLDER]` 数值人工试玩校准、HD-2D 全绿 | **属用户侧，Rank-3 不代做、不宣称完成**（工程根 `README.md`「二、还差什么」） |
| V-5 | 三进程三态满愿存档回读（11 项 flag 三方一致 / 余额非负 / 旧档缺 key 回落基线） | **R31 真跑已完成**：`56 PASS / 0 FAIL`（write 9 / load 6 / assert 41），三 pid 互不相同，见 `DONE-R31.md` 与 `R31-{write,load,assert}.log` |
| V-6 | 三段门禁 `grep SCRIPT ERROR=0` | **R31 真跑**：G1 / G2 / G3 定向重跑 / 三态 5 份日志全 0；首次 G3 的 5 条 `SCRIPT ERROR` 来自 Rank-1 并发瞬时半成品、重跑归零，见 `DONE-R31.md` |
| V-7 | 契约 I-1~I-6 接口表 / §3.1·§3.2 缺号 / R25~R30 历史条款未改、A38 未破坏 | **R31 已核**（G3 `node_count=41` 回读保持） |
| V-8 | `verify_trial_modifier_v090.gd` / `verify_codex_full_wish_v090.gd` / `verify_impact_feedback_v090.gd`（Rank-2 / Rank-1 自测） | **属其它 Rank，Rank-3 不代验、不冒充其结论** |

## 13. 关联

- `teamwork/Rank-3/WAVE-TRIAL-GDD.md` §9（赐福成长 / 五环节核心循环）· §10（三步教学）· `WAVE-TRIAL-SPATIAL.md`（三波空间节奏 / S5 退避带）—— **沿用不改**
- `teamwork/Rank-3/CODEX-GDD.md` §8（四层目标梯度）· §10（落地表引用）· §11（C-V1~C-V6 校对清单）—— **沿用不改**
- `teamwork/00-协作契约.md` §2（三段式 flag）· §3.3 R31 说明段（两个新 flag 登记）· §5（技术约束 / 刺探规则 / 密度优先）
- `teamwork/Rank-3/存档与flag规范.md` §3.1 / §3.3 / §4.1 / §4.4 / §4.7 / §4.8（flag 与 SaveDelta 权威）
- `godot/scripts/rpg/world_state.gd`（I-1 `get_flag` / `set_flag` / `_apply_snapshot`，**本轮只读不改**）· `godot/scripts/world/save_system.gd`（**本轮只读不改**）
- `godot/scripts/rpg/verify_v090_save_readback.gd`（R31 三进程三态只读回读验证）· `teamwork/Rank-3/DONE-R31.md`（实际交付 / 真跑输出 / 未完成项）· 工程根 `README.md`（R31 状态段）
