# SAVE-SPEC-FINAL.md · 存档规范汇总（Rank-3 · R9 · 为 `00-汇总.md` 准备）

> 工位：3 号（RPG / 世界 / 存档）｜轮次：**R9**｜中文 UTF-8
> 权威源：`存档与flag规范.md`（**I-1 唯一权威定义 v1.0**）、`接口契约.md` §1、`world_state.gd` / `save_delta.gd` / `save_delta_writer.gd` 工程根落位件。
> 本件是**汇总整理件**，不新增、不修改任何规范条文或代码；条文以 `存档与flag规范.md` 为准。三项交付口径：**SaveDelta 十字段**、**flag 三段式命名空间**、**任务阶段存档口径**。

---

## 1. SaveDelta 十字段（顶层字段，**冻结，不得新增**）

`存档与flag规范.md` §4.1。当前 `schema_version = 3`，单槽 `slot_01`。

| # | 字段 | 类型 | 必需 | 语义 |
|---|---|---|---|---|
| 1 | `schema_version` | int | ✅ | 当前 **3**；只允许逐版本迁移（§4.7：1→2→3，禁止跳级；未知更高版本拒绝加载） |
| 2 | `slot` | String | ✅ | 固定 `"slot_01"`，**单槽**，不做多槽 UI |
| 3 | `seq` | int | ✅ | 单调递增强制落盘序号，用于回放排序与 LWW |
| 4 | `baseline` | Dictionary | ✅ | `manifest` / `manifest_hash` / `baseline_version` / `resource_ids`；只读 Resource 基线清单 |
| 5 | `flags` | Dictionary | ✅ | **相对基线的变化 flag**；key 三段式，value 白名单；门 / 单向门 / 隐藏墙 / 升降机状态全收敛于此 |
| 6 | `quests` | Dictionary | ✅ | 任务 id → `{ "stage_id": String, "flags": Dictionary }`，**只存变化的任务** |
| 7 | `inventory` | Dictionary | ✅ | `{ "grants": {...}, "consumed": {...} }`，item_id → int 数量 |
| 8 | `spawns` | Dictionary | ✅ | `{ "defeated": [String], "epoch": int }`，赐福休息刷新用 |
| 9 | `removals` | Array[String] | ✅ | 要从结果删除的 flag key（撤销 / 迁移纠偏），可为空数组 |
| 10 | `meta` | Dictionary | ✅ | `playtime_seconds` / `area_id` / `last_grace_id` / `written_at_unix` / `game_version` / `last_commit_reason`（非玩法元数据） |

**禁止出现的顶层字段**（INV-6）：`doors` / `shortcuts` / `lifts` / `chests` / `graces` / `hidden_walls` / `player_position` / `enemies`。这些状态一律编码进 `flags`。玩家精确坐标不进存档（法环式：死亡回上次赐福，`last_grace_id` 即复活锚点）。

**核心不变式**：`基线 + 变化 = 当前世界`（INV-1）——Resource 数据表是只读基线（未变化的默认值不进存档），`SaveDelta` 只记录相对基线的变化；把 flag 写回基线值时保留显式值（不删 key），需真正抹除用 `removals`。

**文件与原子写**（§4.5 / §4.9）：`user://saves/slot_01/delta.json`（权威快照）+ `delta.log`（增量补偿）+ `delta.json.bak` + `delta.json.tmp`；写入顺序 `.tmp → flush → rename_absolute → delta.json`，任一步失败不删旧文件。单文件 < 64 KB，主线程同步写一次 < 1 帧。

**回放 9 步**（§4.4）：读基线 → 读快照 → 按 `seq` 升序回放日志（仅 `seq > 快照.seq`，半截末行丢弃）→ 应用 `removals` → **`quests` 覆盖** → `inventory` 累加 → `spawns` 按 epoch → compact 写新快照并清空日志 → `_apply_snapshot` 注入 WorldState。冲突一律 **LWW by seq**。

---

## 2. flag 三段式命名空间

`存档与flag规范.md` §3.1 / §3.2，`world_state.gd:24` `FLAG_KEY_REGEX` 与之逐字一致。

```
key   := <模块> "." <对象> "." <状态>
模块  := world | quest | combat | grace | dungeon
对象  := [a-z0-9_]+          # 不含点号；数据表 id 可直接作对象段
状态  := [a-z0-9_]+
正则  := ^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$
```

- 全小写 snake_case，**禁止**大写、点号嵌套、驼峰、中文。
- 对象段优先用数据表 id（如 `elite_01_bell_warden`、`grace_limgrave_gatefront`），保证与 2 号数据表、3 号房间表可对账。
- **value 白名单**：`bool / int / float / String`；`null` 不是合法 value（"未设置"用 `get_flag(key, false)` 表达）。
- `get_flag` 纯读（不创建 key / 不发信号 / 不写盘 / 返回值拷贝）；`set_flag` 幂等（同 key 同值不产生 Delta、不发 `flag_changed`、不增 `seq`），且**从不在调用内同步落盘**。

### 5 个前缀命名空间表（§3.2）

| 前缀 | 语义 | 归属写入方 | 典型对象 | 典型状态 | 生命周期 |
|---|---|---|---|---|---|
| `world.` | 世界可交互物：宝箱、门、单向门、隐藏墙、升降机、拾取物、NPC 首见 | 3 号（1 号可写自己触发的拾取） | `bellvault_chest_01`、`bellvault_shortcut_door_01`、`bellvault_lift_01` | `opened`、`unlocked`、`revealed`、`position`、`taken`、`met` | 永久，随 Delta 持久 |
| `quest.` | 任务状态 / 阶段 / 分支 / 交付 | 3 号任务状态机 | `bell_of_return` | `stage`(int)、`accepted`、`completed`、`betrayed`、`reward_claimed` | 永久 |
| `combat.` | 击杀 / 阶段 / 遭遇 | **3 号**（I-2 订阅后写）；2 号只读 | `elite_01_bell_warden`、`boss_01_margit` | `defeated`、`encounter_started`、`phase_two_ready` | `defeated` 永久；`encounter_started` 可休息重置 |
| `grace.` | 赐福点亮 / 解锁 / 传送网络 | 3 号 | `limgrave_gatefront`、`bellvault_entry` | `lit`、`unlocked`、`visited`、`last_rest_epoch` | 永久 |
| `dungeon.` | 地牢级结构：捷径 / 层数 / 入口 | 3 号 | `bellvault`、`sunless_tomb` | `shortcut_opened`、`entered`、`deepest_floor` | 永久 |

**收敛落地（INV-6）**：升降机停靠层用 `world.bellvault_lift_01.position = 2`（int，0=B1/1=B2/2=B3），不用 float 坐标、不用嵌套结构。新增 flag 必须先在 §3.3 登记表追加一行再用，禁止代码里临时拼接未登记 key。

> ⚠️ **待裁决 A8（只登记不擅改）**：契约 §2 表格给三段式规则，但示例写作 `world.grace_limgrave_lit`（两段式）；本规范按任务书 §5「严格三段式」采用 `grace.limgrave_gatefront.lit`。3 号不自行修改契约，交 HOST 在 `00-汇总.md` 裁决。工程根 `world_state.gd` 正则与本规范一致。

---

## 3. 任务阶段存档口径

任务阶段是 M4「flag 变化驱动对话分支」的持久化前提，也是 M6 探索线不断线的关键。

| 项 | 口径 | 出处 |
|---|---|---|
| 存储位置 | `SaveDelta.quests`（第 6 字段）：`quest_id → { "stage_id": String, "flags": Dictionary }`，只存变化的任务 | §4.1 |
| 阶段 flag | `quest.bell_of_return.stage`（int，基线 `0`）：`0`未接 / `1`取碎片 / `2`可交付 / `3`完成；另有 `accepted` / `completed` / `betrayed` / `reward_claimed`（bool） | §3.3 登记表 |
| 回放优先级 | 回放第 5 步 `quests` **覆盖**：任务 stage 与 flags **以快照为准**，日志中同任务取 `seq` 最大者 | §4.4 |
| 冲突修复 | `quests.stage_id` 与 `flags["quest.x.stage"]` 不一致 → **以 `flags` 的 int 阶段为准**，回写 `stage_id`，并记 `meta.stage_repaired = true` | §4.4 LWW 表 |
| 只进不退 | `SaveDelta.replay` M3 规则：同一 quest `stage_index = max(旧, 新)`，阶段只前进不回退 | `world_state.gd` 头部 R2 落地 5 条 |
| **写入时机** | 对话选择改变任务阶段 → **强制同步落盘**，`reason = "quest_stage"`；不进 0.5 s 合并窗口 | §4.8 |
| 写入方 | 3 号 `DialogueRunner` / `QuestStateMachine` 逐条 `set_flag` 后写 `quests` 的 stage；1 / 2 号**不得**构造 / 解析 SaveDelta，只经 `get_flag / set_flag` | §5 / I-1 |
| 崩溃恢复 | 任务阶段属「赐福、击杀、任务阶段、拾取、传送」五类**零丢失**强制同步点之一 | §4.8 末 |
| 迁移 | v1（仅 flags+quests）→ v2（+spawns.epoch / inventory.consumed / baseline.manifest_hash）→ v3（+removals / meta.game_version / last_rest_epoch）；逐级、迁移前备份、迁移后 `meta.migrated_from` 记录原版本 | §4.7 |

> **I-1 边界**：`quests` 与 `SaveDelta` 细节对 1 / 2 号**不可见**；1 / 2 号只依赖 `WorldState.get_flag / set_flag`，不得 `FileAccess.open("user://saves/...")`、不得 `ResourceLoader.load` 存档、不得 `JSON.parse` 存档。

---

## 4. 不变式速查（INV-1 ~ INV-7，供 `00-汇总.md` 裁决引用）

| # | 不变式 |
|---|---|
| INV-1 | 基线 + 变化 = 当前世界；Resource 只读基线，Delta 只记相对变化 |
| INV-2 | 1 / 2 号与世界状态的**唯一**通道是 `WorldState.get_flag / set_flag` |
| INV-3 | `get_flag` 纯读：不发信号、不写盘、不产生副作用、不隐式创建 key |
| INV-4 | `set_flag` 幂等：同 key 同 value 不产生 Delta、不发 `flag_changed`、不增 `seq` |
| INV-5 | flag key 严格三段式；value 仅 `bool / int / float / String` |
| INV-6 | 门 / 单向门 / 隐藏墙 / 升降机 / 宝箱 / 赐福 / 捷径状态全部收敛进 `flags`，不新增 SaveDelta 顶层字段 |
| INV-7 | 单槽、单文件落盘，写入原子化；任何时刻磁盘上都存在一份可加载的完整存档 |

---

## 5. 供 `00-汇总.md` 直接引用的结论

1. **SaveDelta 十字段已冻结**：`schema_version / slot / seq / baseline / flags / quests / inventory / spawns / removals / meta`，当前 `schema_version=3`、单槽 `slot_01`；禁止 8 类顶层状态字段，全部收敛进 `flags`。
2. **flag 三段式**：`^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`，5 个前缀命名空间；`world_state.gd:24` 正则、8 赐福节点 `lit/unlocked` flag 均通过（R9 真跑 W7 `T3_FLAGS_3SEG` PASS）。
3. **任务阶段**：`quests` 快照为准 + `quest.x.stage` int 只进不退 + 冲突以 int 阶段回写 `stage_id` + 对话选择 `reason="quest_stage"` 强制落盘；属零丢失五类之一。
4. **I-1 边界**：1 / 2 号只见 `get_flag / set_flag`；击杀 flag 由 3 号订阅 I-2 写，2 号不双写（避免 `seq` 重复）。
5. **三项待裁决 / 登记项**：A8（契约两段式示例 vs 三段式）、`chunk.<id>.loaded` 归一最终口径 A/B/C、6 条 `res://scenes/*` 未实机换场景与 `chunk_origin` 全 0 —— 均**只登记不擅改**，交 HOST 裁决（详见 `DONE-R9.md` ③）。

> 本件与 `M6-TOPOLOGY.md`、`I-INTERFACE-SELFCHECK.md` 同为 R9 汇总材料，供主 AI 汇总时按 I-1 / I-2 / I-3 编号逐项核对。
