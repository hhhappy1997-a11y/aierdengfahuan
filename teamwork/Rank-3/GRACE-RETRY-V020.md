# GRACE-RETRY-V020.md · v0.2.0 重复挑战 / Boss 永久击败 / 赐福休息落盘口径

> 工位：Rank-3（RPG / 世界 / 存档）｜轮次：**R24**｜任务 `cmd-20261109-205253-730-A3`｜版本锚点 **v0.2.0**｜中文 UTF-8
> 定位：**实现口径（可直接落地）**，不是实现件。目标读者 **R25**（及 Rank-1 / Rank-2 / Rank-4 对接人）：凡本文件给出的 key、类型、时序、`commit(reason)` 字面量、断言，均可逐条转成代码 / verify 断言，不需要再向 Rank-3 追问"到底怎么存"。
> 本轮 Rank-3 **未写任何 `godot/` 工程文件**（目录所有权：`godot/` 本轮归 Rank-1 / Rank-2 并发写入；Rank-4 管 `perf_encounter_v020.gd` 与 `capture/`）；本文件与 `README.md`、`DONE-R24.md` 是 Rank-3 本轮唯一产出。

---

## 0. 权威源与口径溯源（先对齐，不新造条款）

| 锚点 | 权威真源（只读） | 本文件的关系 |
|---|---|---|
| flag 三段式命名 | `teamwork/00-协作契约.md` **§2**（flag `<模块>.<对象>.<状态>`，A6 已由主 AI 回改为严格三段式） | 新 flag 全部遵守，见 §2 |
| `WorldState` / `SaveDelta` 定义权 | `00-协作契约.md` **§3 I-1**：「`SaveDelta` 结构由 **3 号**定义；1/2 号不得直接读写存档文件」；**§3 I-2**：击杀信号 2→3 | 本文件是 3 号对该定义权的一次具体行使；1/2 号仍只经 `get_flag/set_flag` |
| **SaveDelta 十字段（冻结）** | `teamwork/Rank-3/存档与flag规范.md` **§4.1**；汇总件 `SAVE-SPEC-FINAL.md` **§1** | 见 §5 逐字段影响表；**不新增顶层字段** |
| flag 正则 / 命名空间 / 登记表 | `存档与flag规范.md` **§3.1 / §3.2 / §3.3**；`world_state.gd:24` `FLAG_KEY_REGEX` 与之逐字一致 | 见 §2；新 key 须先追加 §3.3 登记行 |
| **§4.4 合并与回放** | `存档与flag规范.md` **§4.4**（原 R1 措辞已按 `00-汇总.md` **§4 A4** 裁决于 R10 回改为 R2 落地 5 条口径） | 见 §5「§4.4 九步核对」；本文件**不改其中任何一条** |
| 赐福休息 / 敌人刷新 | `存档与flag规范.md` **§4.6** | 见 §1 / §3 规则 5 |
| 强制落盘点 / `reason` | `存档与flag规范.md` **§4.8**；原子写 **§4.5**；单槽路径 **§4.9** | 见 §4（本文件唯一新增物是一个 reason 字面量） |
| `schema_version=3` / 迁移链 | `存档与flag规范.md` **§4.1 / §4.7**；`SAVE-SPEC-FINAL.md` §1 | 见 §5；**保持 3，不迁移** |
| 单槽 `slot_01` | `存档与flag规范.md` **§4.1 / §4.9**；`RUNTIME-STATUS-R22.md` §3 真跑实证 | 见 §5；**保持 slot_01** |
| v0.2.0 backlog 来源 | `teamwork/迭代-v0.1.0-遭遇战闭环.md` **§2 漏洞表 / §9 backlog**：P1「赐福休息不重置 Boss」、P1「Boss 每帧重复抽招」、P2「L4 泄漏曲线」 | 见 §6 四项接口边界 |

**如实溯源说明（不粉饰）**：任务单措辞「`00-协作契约.md` §4.4 十字段」需按真源链理解 —— 契约 §4 是「每个文件夹的强制交付格式」（其第 4 条为 `接口契约.md`），**不列十字段**；十字段由 I-1 授权 3 号定义、落在 `存档与flag规范.md` §4.1；§4.4 的回放口径经 `00-汇总.md` §4 A4 裁决回改。本文件按这条真源链与四者（三段式命名 / 十字段 / `schema_version=3` / `slot_01`）全部对齐，不硬套章节号、不私改契约。

---

## 1. 问题与结论：三层模型（冲突为什么不成立）

v0.1.0 遗留 P1：「赐福休息不重置 Boss（击杀后保持 DEATH）」；v0.2.0 把 `EncounterRoot` 接进 `courtyard.tscn` 后，Boss 会在庭院内被反复遭遇。若把「重置 Boss」实现成清 `combat.<id>.defeated`，会直接破坏 I-2 永久击败语义与 §4.4「击杀不可回滚」。

| 层 | 载体 | 写入方 | 是否落盘 | 生命周期 |
|---|---|---|---|---|
| **L1 世界持久层** | `combat.<id>.defeated`（`SaveDelta.flags` 内一个 key） | Rank-3 订阅 I-2（`SaveDeltaWriter._on_boss_defeated`） | **是**（强制点） | 永久、只增不减、永不回退 |
| **L2 赐福业务层** | `grace.encounter_01.*`、`grace.network.last_rest_epoch`（`SaveDelta.flags` 内 key） | Rank-3 赐福菜单 / 休息回调 | **是**（强制点） | `retried` 持久计数；`retry_active` 会话回合标记 |
| **L3 遭遇运行时层** | `BossController` 的 HP / 阶段 / 抽招游标 / 同招冷却；`EncounterDirector` 的 outcome / 玩家 HP | Rank-2 导演层 | **否**（严禁进存档） | 单次遭遇实例，进出场景重建 / 释放 |

> **结论（一句话）**：重置**只发生在 L3**；L1 永不回退；L2 只记录「曾发起过重复挑战」与「当前是否处于回合内」，**不表达 Boss 生死**。三层不写同一个 key、不改同一个字段，故「Boss 永久击败」与「重复挑战」不冲突。

---

## 2. 三段式 flag 定义（R25 可直接登记 / 使用）

### 2.1 三段式与正则（§3.1，逐字沿用）

```
key   := <模块> "." <对象> "." <状态>
正则  := ^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$
value := bool | int | float | String        # null 非法；"未设置"用 get_flag(key, default)
```

以任务单示例 `grace.encounter_01.retried` 逐段拆解：

| 段 | 值 | 依据 / 语义 |
|---|---|---|
| 模块 | `grace` | 重复挑战由**赐福菜单**发起，属赐福业务动作，不是击杀 / 遭遇状态；故归 `grace.` 而非 `combat.`。**这是与 `combat.<id>.defeated` 不冲突的第一层保证：不同命名空间、不同语义域** |
| 对象 | `encounter_01` | v0.2.0 遭遇实例 id；须与 Rank-2 `encounter_rules_v020.gd` / 导演层所用遭遇 id **同一字面量**（§2.3 对齐约定） |
| 状态 | `retried` | 完成态 / 过去式，符合契约 §2「过去式或事件语义」 |

### 2.2 新增 flag 表（本轮口径新定义 2 个；后 3 行为既有登记项，列出以给全读取/清除语义）

| key | 类型 | 基线 | 写入方 | 写入时机 | 读取方 | 清除 / 回退策略 | 落盘点 |
|---|---|---|---|---|---|---|---|
| `grace.encounter_01.retried` | **int** | `0` | Rank-3（赐福菜单「重复挑战」回调） | 每次**成功发起**一次：`set_flag(key, get_flag(key,0)+1)` | HUD 次数 / L4 计数 / 回放断言 | **永不清除**，单调递增；休息不清零、重启不丢 | 强制 `commit("grace_retry")` |
| `grace.encounter_01.retry_active` | **bool** | `false` | Rank-3 | 发起置 `true`；结算（胜 / 败 / 主动退出）或重启恢复置 `false` | 导演层门控（一次回合内防重复发起） | 每回合结束必置 false；`_load()` 后若为 true 且无活跃遭遇实例，判为上次异常中断并置 false | 随 `commit("grace_retry")` |
| `combat.boss_01_margit.defeated` | bool | `false` | Rank-3 订阅 I-2（既有 `SaveDeltaWriter._on_boss_defeated`） | **首次**击杀置 true | 世界是否自然刷出该 Boss / 赐福解锁 / 首杀奖励 | **永不清除、永不回退**；重复挑战不改 | 强制 `commit("boss_defeated")` |
| `combat.boss_01_margit.encounter_started` | bool | `false` | Rank-3 | 进入遭遇 true；赐福休息 / 遭遇结束置 false | 导演层 | 按 §4.6 休息置 false | 随强制点 |
| `grace.network.last_rest_epoch` | int | `0` | Rank-3 | 每次赐福休息 `+1`，同步 `spawns.epoch` | 普通敌人刷新 | 不回退 | 强制 `commit("grace_rest")` |

> 既有三行分别对应 `存档与flag规范.md` §3.3 第 156 行（精英 `defeated` 同型）、第 157 行（`encounter_started`）、第 164 行（`last_rest_epoch`）；**本轮不新增、不改它们**，列出仅为消除「休息 / 击杀 / 重复挑战」三动作读取时的歧义。

### 2.3 §3.3 登记表待追加行（R25 落地时逐字追加，本轮不擅自改既有规范件）

```
| `grace.encounter_01.retried` | int | `0` | 赐福菜单发起「重复挑战」 | 累计次数，单调递增，永不清除；与 combat.<id>.defeated 无关 |
| `grace.encounter_01.retry_active` | bool | `false` | 发起 / 结算重复挑战 | 回合内防重复发起；结算或重启恢复置 false |
```

- 追加后 **`world_state.gd` 的 `FLAG_KEY_REGEX` 无需修改**（`grace` 前缀 / `encounter_01` 对象 / `retried`、`retry_active` 状态均合法）；无需迁移、无需改 `schema_version`。
- **对象段 id 对齐约定**：`encounter_01` 是任务单给定的示例字面量。R25 必须以 Rank-2 `encounter_rules_v020.gd` 中实际遭遇 id 为准，两边统一；若不一致，**改本口径文档的对象段**（如 `grace.boss_01_margit.retried`），**不改 Rank-2 数据表 id**（数据表 id 是 §3.1 的对账基准）。禁止两边各起一个 id。
- 禁止项：两段式 `grace.encounter_01_retried`、语义错位 `combat.encounter_01.retried`、驼峰 / 大写 / 中文 / 点号嵌套、代码里临时拼接未登记 key（§3.3 末行硬约束）。

---

## 3. 「Boss 永久击败」与「重复挑战」不冲突口径（逐条可执行）

1. `combat.<id>.defeated` 是**世界永久状态**：由 I-2 击杀链唯一写入，`respawn_policy = "never"`（§4.6 第 3 条），**不进 `spawns.defeated` 清空列表**，**不进 `removals`**。
2. 「重复挑战」是**赐福菜单发起的一次临时遭遇**：只让 L3 运行时实例重新可战斗（HP 满 / 阶段 1 / 抽招游标与同招冷却清零 / outcome 复位），**不写、不清、不改读** `combat.<id>.defeated`。
3. **I-2 信号照常发**（既有 `BossController` / `CombatEventBus` / `GameEvents` 零改动）：重复挑战里再次击杀 Boss 仍触发 `boss_defeated`；`SaveDeltaWriter` 收到后 `set_flag("combat.<id>.defeated", true)` 因 **INV-4 幂等**（同 key 同 value 不产生 Delta、不发 `flag_changed`、不增 `seq`）而不改变存档世界状态；`commit` 仍执行一次但内容等价，仅 `meta.last_commit_reason` 变 `boss_defeated`。**不得**为「避免重复写」去改既有 writer 或屏蔽信号。
4. 「赐福休息重置 Boss」（v0.1.0 P1 backlog）的口径 = **只重置 L3 运行时实例**。若 `combat.<id>.defeated = true`，世界里**不再自然刷出**该 Boss（法环式），只有显式「重复挑战」才生成临时实例；若尚未击败，休息后世界 Boss 照常存在且为满状态。
5. **普通敌人刷新照旧**（§4.6）：清 `spawns.defeated` 中对应 id、`combat.<id>.encounter_started = false`；**精英 / Boss 不在清空列表**。
6. 重复挑战**不**发首杀奖励、**不**改 `quests`、**不**改 `inventory`、**不**重复解锁赐福；`spawns` 零变化。
7. **`removals` 硬禁令**：任何代码不得把 `combat.<id>.defeated`（或任何 `*.defeated` key）写进 `SaveDelta.removals`；§4.4 规则表「`spawns.defeated` 与 `combat.*.defeated` 不一致 → 以 `combat.*.defeated = true` 为准补齐，**反向不减**」。

### 3.1 读写分离矩阵（照表实现即不会冲突）

| 动作 | 写 `combat.<id>.defeated` | 写 `grace.encounter_01.*` | 动 `spawns.defeated` | 动 L3 运行时 |
|---|---|---|---|---|
| 首次击杀 | `true`（I-2，强制落盘） | 不变 | 不变 | outcome = win |
| 赐福休息 | **不变** | 不变（`retried` 不清零） | 普通敌人清空；**Boss 不动** | 玩家 / Boss 实例重置（未击败则世界 Boss 满血复活；已击败则世界不刷出） |
| 发起重复挑战 | **不变** | `retried + 1` / `retry_active = true` | **不变** | 新建 / 重置**临时** Boss 实例 |
| 重复挑战中再次击杀 | 幂等 `true`（不产生 Delta） | `retry_active = false`（结算步） | **不变** | outcome = win |
| 重复挑战失败 / 主动退出 | **不变** | `retry_active = false` | **不变** | 实例 `queue_free` |
| `_load()` 回放 | 从 `slot_01` 读回 | 从 `slot_01` 读回 | 并集只增不减 | — |

### 3.2 R25 禁止的反例（写进 code review 清单）

- `set_flag("combat.boss_01_margit.defeated", false)` 或 `removals.append("combat.boss_01_margit.defeated")` 来「重置 Boss」→ 破坏击杀不可回滚。
- 用 `grace.encounter_01.retried` 的值判断「Boss 是否活着」→ 语义错位；该 flag 只计数。
- 把同招冷却 / 抽招游标 / Boss HP / outcome 写进任何 flag 或 SaveDelta 字段 → 运行时状态污染存档（见 §6）。
- 为重复挑战新建 `slot_02`、`delta_retry.json` 或第二份快照 → 违反单槽。

---

## 4. 赐福休息的强制落盘点 `commit(reason)`（时序可直接照抄）

**权威**：§4.8「点燃 / 休息赐福 → **强制同步** → `grace_lit` / `grace_rest`」「订阅 I-2 击杀（尤其 Boss）→ **强制同步** → `boss_defeated`」；崩溃恢复「赐福、击杀、任务阶段、拾取、传送五类**零丢失**」；§4.5 原子写七步（`.tmp → flush → rename_absolute → delta.json`）。

### 4.1 reason 字面量表

| 触发点 | `reason` | 落盘方式 | 相对 L3 的先后 | 依据 |
|---|---|---|---|---|
| 点燃赐福 | `grace_lit` | 强制同步，**不进 0.5 s 合并窗口** | — | §4.8 既有 |
| 赐福休息（回血 / 刷新 / `epoch + 1`） | `grace_rest` | 强制同步 | **先于**任何 L3 实例重置 | §4.8 既有；复活锚点必须先落盘 |
| 从赐福菜单发起「重复挑战」 | **`grace_retry`** | 强制同步 | 在 `grace_rest` 之后、`retry_active = true` 与 L3 实例创建**之前** | **本文件新增**（见 4.2） |
| 首次击杀 Boss | `boss_defeated` | 强制同步 | I-2 回调内 | §4.8 既有 |
| 重复挑战里再次击杀 | `boss_defeated`（I-2 幂等）／结算清理 `grace_retry` | 强制同步 | 结算回调内 | §3 规则 3 |
| 传送 / 退出 | `grace_fast_travel` / `quit` | 强制同步 | — | §4.8 既有 |

**`grace_retry` 的边界（重要）**：它只是写进 `meta.last_commit_reason` 的**字符串字面量**，不是新顶层字段、不是新 `spawns` / `quests` 结构 → **不触发 `schema_version` 迁移、不违反十字段冻结**（§4.1「冻结，不得新增」约束的是**顶层字段**）。复用既有 `SaveDeltaWriter.commit(reason)`，**R25 不改**其签名与 §4.5 原子写流程。若总指挥裁决「复用 `grace_rest`、不新增字面量」，R25 直接替换字符串即可，其余时序不变。

### 4.2 时序（★ = 强制落盘点；纪律：**先把世界 / 业务状态写进 `slot_01`，再改运行时实例**）

```
[赐福休息]
 1  set_flag("grace.network.last_rest_epoch", epoch + 1)          # 写侧业务动作，seq +1
 2  set_flag("grace.network.last_grace_id", <grace_id>)           # 复活锚点
 3  set_flag("combat.<普通敌人>.encounter_started", false)         # 仅普通敌人；Boss 不动
 4  SaveDeltaWriter.commit("grace_rest")                          # ★ 强制落盘点 A（先落盘）
 5  才重置 L3：玩家 HP / 状态机、Boss 运行时实例（世界内仍存在时）、抽招与同招冷却清零

[发起重复挑战]  前置：get_flag("grace.encounter_01.retry_active", false) == false
 6  if get_flag("combat.boss_01_margit.defeated", false):
        仅记录「世界已击败」；不清 flag、不解锁、不发奖（§3 规则 6）
 7  set_flag("grace.encounter_01.retried", get_flag(key, 0) + 1)
 8  set_flag("grace.encounter_01.retry_active", true)
 9  SaveDeltaWriter.commit("grace_retry")                          # ★ 强制落盘点 B（先落盘）
10  才创建 / 重置 L3 临时 Boss 实例（HP 满 / 阶段 1 / 同招冷却清零 / outcome = -1）

[回合结算：胜 / 败 / 主动退出]
11  (胜且首次) I-2 → boss_defeated → set_flag("combat.<id>.defeated", true)
                + commit("boss_defeated")                        # ★ 强制落盘点 C
    (胜且非首次) I-2 仍触发；set_flag 幂等、不增 seq；commit 内容等价
12  set_flag("grace.encounter_01.retry_active", false)
13  SaveDeltaWriter.commit("grace_retry")                         # ★ 强制落盘点 D（结算清理先落盘）
14  释放 L3 临时实例（queue_free）→ 供 L4 泄漏曲线取节点数 / 内存

[重启恢复]
15  _load() 从 slot_01 回放 → 若 retry_active == true 且当前无活跃遭遇实例：
        set_flag("grace.encounter_01.retry_active", false)
        commit("grace_retry")                                    # 修正上次异常中断的残留标记
```

- 一个触发点内可连续 `set_flag` 多次，最后一次 `commit` 一次落盘；**`seq` 只在值变化时递增**（INV-4），`commit` 本身不直接增 `seq`。
- **崩溃恢复口径**：重复挑战的「发起」（B）与「结算」（D）同属赐福 / 击杀类**零丢失强制点**；崩溃时磁盘上是「已发起」或「已结算」的一致态，绝不会出现「临时 Boss 在跑但存档说没发起」。`retry_active` 残留由步骤 15 修正，不靠 0.5 s 合并窗口。
- 幂等补充：`set_flag` 幂等保证同一回合内重复点「重复挑战」不会二次 +1 —— 门控靠 `retry_active`，不靠去重表。

---

## 5. 与十字段 / `schema_version=3` / 单槽 `slot_01` / §4.4 的关系

### 5.1 十字段逐字段影响表（唯一被改的是第 5 个字段 `flags`）

| # | 顶层字段 | 本口径是否改动 | 具体内容 |
|---|---|---|---|
| 1 | `schema_version` | **否** | 保持 **3**。新增 flag 是 `flags` 字典内新增 key（相对基线的变化，INV-1 允许），**不是新顶层字段**，不触发 §4.7 迁移链 |
| 2 | `slot` | **否** | 固定 **`slot_01`**；所有 `commit` 仍写 `user://saves/slot_01/delta.json` + `delta.log` |
| 3 | `seq` | 间接 | 由 `set_flag` **值变化**递增；幂等的同值 `set_flag` 不增；不由 `commit` 直接增 |
| 4 | `baseline` | **否** | 只读 Resource 基线清单零变化 |
| 5 | `flags` | **是（唯一）** | 新增 2 个三段式 key `grace.encounter_01.retried` / `.retry_active`；`combat.<id>.defeated` 保持 true 不回退；`combat.<id>.encounter_started` 按 §4.6 复位 |
| 6 | `quests` | **否** | 重复挑战不发任务阶段（`stage_index` 不变） |
| 7 | `inventory` | **否** | 不发首杀奖励（数量快照不变） |
| 8 | `spawns` | **否** | `defeated` 取**集合并集、只增不减**（§4.4 第 3 条）；Boss 永不进该列表；`epoch` 仅由赐福休息 `+1` 并同步（既有 §4.6） |
| 9 | `removals` | **否（硬禁令）** | 禁止塞入任何 `*.defeated` key；保持空 / 原有迁移纠偏用途 |
| 10 | `meta` | 仅既有子键 | `last_commit_reason` 由 `commit` 写（含新字面量 `grace_retry`）；`last_grace_id` 休息时写；**不新增 meta 子键**，避免 schema 语义漂移 |

### 5.2 §4.4 九步回放核对（本口径不新增任何回放步骤）

新增 flag 在 `flags` 内 → 第 2 步读 `delta.json` 快照覆盖 → 第 3 步 `delta.log` 按 `written_at_unix` **升序 LWW**（`seq` 仅作候选行筛选）→ 第 4 步 `removals`（本口径不用它删 retry / defeated key）→ 第 5~8 步（`quests` / `inventory` / `spawns` 零变化、compact）→ 第 9 步 `_apply_snapshot` 注入内存。**不改排序键、不改 compact 时机、不改 LWW 规则**。首次读档时 `retried` / `retry_active` / `defeated` 均从同一 `slot_01` 读回，重复挑战次数跨会话保持。

### 5.3 单槽核对

- **不新建** `slot_02` / `delta_retry.json` / 第二份快照 / 第二套 `user://` 目录。
- `retry_active` 是**同一存档内一个 bool flag**，不是另一份存档或另一份内存快照。
- `_load()` 仍只从 `user://saves/slot_01/delta.json`（+ `delta.log` 补偿）单文件回放；R22 / R23 / R24 的 `r22_save_e2e.gd` 两独立进程「写盘 → 重启 → 读回」实证该路径成立（见 `DONE-R24.md`）。

---

## 6. 与 v0.2.0 四项的接口边界（Rank-3 只定口径，不改 `godot/`）

| v0.2.0 项 | 归属（本轮并发写入） | Rank-3 口径约束 |
|---|---|---|
| **主场景接线** | Rank-1 `courtyard.tscn` + `build_courtyard_v020.gd` | 接线 = 把 `EncounterRoot` 接进 **courtyard**，**不是**改 `project.godot` 的 `run/main_scene`；接线后场景树仍不得直读写存档文件，只经 I-1 `get_flag/set_flag`。`main_scene` 缺口见 README「还差什么」第 9 项 |
| **Boss 重置** | Rank-2 `encounter_director.gd` / `encounter_rules_v020.gd` | 重置 = **仅 L3 运行时实例**；禁止清 `combat.<id>.defeated`、禁止用 `removals`、禁止把 Boss 加进 `spawns.defeated`（§3） |
| **同招冷却** | Rank-2 `encounter_rules_v020.gd` | 冷却游标 / `last_move_id` / `cooldown_frames` / 抽招游标 / 距离门槛 **全是 L3 纯运行时状态，禁止编码进 `flags` / `spawns` / `meta` / 任何 SaveDelta 字段**；进出场景重建时清零、不持久化（否则 §4.4 LWW 会把上一回合的冷却值回放进新回合） |
| **L4 泄漏曲线** | Rank-4 `perf_encounter_v020.gd` + `capture/` | 曲线须覆盖「重复挑战 N 次」：每回合按 §4.2 步骤 14 `queue_free` 释放临时实例，节点数 / 内存回到基线；断言 `retry_active` 每回合结束为 false、不泄漏 true；Rank-3 不改 perf 脚本 |

> `verify_encounter_v020.gd` 归 Rank-2；本节与 §7 的断言是给它的**口径输入**，Rank-3 本轮不写 `godot/` 下任何验证脚本（目录所有权硬约束）。

---

## 7. R25 落地清单与验收断言（可直接转成代码 / verify）

### 7.1 落地清单（按顺序）

1. 在 `存档与flag规范.md` **§3.3 登记表**追加 §2.3 的 2 行（追加后才可在代码里使用新 key）。
2. Rank-2 在 `encounter_director.gd` / `encounter_rules_v020.gd` 实现 §3 规则 1~7 与 §4.2 时序 1~15；**只经** `WorldState.get_flag / set_flag` + `SaveDeltaWriter.commit(reason)`；**不改** `save_delta_writer.gd` / `world_state.gd` / `save_delta.gd` 的既有签名与 §4.5 原子写流程。
3. HUD 若显示「重复挑战」次数，只读 `grace.encounter_01.retried`（`get_flag` 纯读，不写盘）。
4. `verify_encounter_v020.gd` 追加 §7.2 断言；`perf_encounter_v020.gd` 追加 A9 / A10 的 L4 对照。

### 7.2 验收断言（逐条 machine-check）

| # | 断言 | 期望 |
|---|---|---|
| A1 | 2 个新 key 全部匹配 `^(world\|quest\|combat\|grace\|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$` | 2/2 PASS |
| A2 | 落盘 `delta.json` 顶层字段集合 == 十字段 | `missing=[] extra=[]` |
| A3 | `schema_version == 3` 且 `slot == "slot_01"` | true |
| A4 | 首次击杀后 `combat.boss_01_margit.defeated == true` 且 `meta.last_commit_reason == "boss_defeated"` | true |
| A5 | 赐福休息后 `defeated` 仍 true；`spawns.defeated` 不含 `boss_01_margit`；`removals` 为空 | 全 true |
| A6 | 发起一次重复挑战：`retried` 0→1、`retry_active = true`、`defeated` 不变、`spawns` / `quests` / `inventory` 不变 | 全 true |
| A7 | 对 `defeated` 单独做一次同值 `set_flag(k, true)`：`seq` 不变、不发 `flag_changed`、不产生 Delta（INV-4） | true |
| A8 | 结算后 `retry_active == false` 且 `meta.last_commit_reason == "grace_retry"` | true |
| A9 | N 次重复挑战后 `retried == N`、`retry_active == false`、节点数 / 内存回到基线（L4 无泄漏）；同招冷却值不出现在存档任何字段 | 全 true |
| A10 | 写盘 → **重启独立引擎进程** → `_load()` → `get_flag` 读回 `retried` / `retry_active` / `defeated` 一致（pid 不同） | 3/3 一致 |
| A11 | 重启时 `retry_active == true` 且无活跃遭遇实例 → 恢复为 false 并 `commit("grace_retry")` | true |
| A12 | 三段门禁 `grep SCRIPT ERROR / Parse Error / ERROR` 全 0；R21/R22 的 31 PASS 回归不回退 | 全 0 / 31 PASS |

---

## 8. 未决项与如实边界

- **本文件是口径，不是落盘实现**：R24 未写任何 `godot/` 工程文件、未改既有规范件（§2.3 的登记行由 R25 追加）、未新增任何落盘 flag / `godot/` 验证脚本；R24 真跑只覆盖既有 31 PASS / 16 PASS E2E 与三段门禁（见 `DONE-R24.md`）。
- **`encounter_01` 对象段**须与 Rank-2 实际遭遇 id 对齐（§2.3）；本轮按任务单示例写，R25 若采用其它 id，按 §2.3 改本文件对象段，不另起 id。
- **`grace_retry` reason 字面量**为新增（仅 `meta.last_commit_reason` 使用）；若裁决要求复用 `grace_rest`，替换字符串即可，时序不变。
- **玩法边界（不编造）**：v0.2.0 的重复挑战**不设次数门槛、不发奖励**，`retried` 只计数不门控；若后续要「每次休息限一次」或「再战奖励」，另开裁决，不塞进本口径。
- **可运行性缺口（与 README 一致，不粉饰）**：`project.godot` 的 `run/main_scene` 仍指向 `scenes/Main.tscn` 骨架；完整画面目前只在 `courtyard.tscn` 与 `encounter_v010.tscn` 等独立场景中可跑；**改 `main_scene` 属 v0.3.0**，本轮四路均不写 `project.godot`。
- **不动的历史裁决**：A4（§4.4 回改）、A6（三段式）、A8（契约两段式示例）等保持既有状态；本文件不重新裁决、不私改 `00-协作契约.md`。

---

> 关联：`teamwork/Rank-3/DONE-R24.md`（本轮交付 / 真跑结论）、`teamwork/Rank-3/存档与flag规范.md`（I-1 权威）、`teamwork/Rank-3/SAVE-SPEC-FINAL.md`（十字段汇总）、`teamwork/Rank-3/RUNTIME-STATUS-R22.md`（端到端真跑）、`teamwork/迭代-v0.1.0-遭遇战闭环.md`（v0.2.0 backlog）、`F:/Game/aierdengfahuan/README.md`（v0.2.0 状态表与缺口）。
