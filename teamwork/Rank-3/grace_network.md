# 赐福网络（R3 补齐说明 · 对应 `任务书-R3.md` §2 `grace_network.tres` 行）

> 工位：3 号（RPG / 世界 / 存档）｜轮次：R3｜中文 UTF-8
> **边界**：`grace_network.tres`（8 个 `GraceNode` 子资源 + 7 条带条件边）为 **R2 已产出、Godot 4 合法 `.tres`**，已满足 M6 口径；按用户 R3「R2 产出不重做」约束，本轮**不重做、不改写**该 `.tres` 及 `grace_network.gd` / `grace_node.gd`。
> 本文只补齐 `任务书-R3.md` §2 要求「必须写清」的三项：**3~4 区域 + 2 地牢 + 1 地下入口（M6 口径）拓扑、解锁 flag 命名、休息回血 / 刷新敌人与 Delta 的关系**，并逐条引用现有 `.tres` 与 `存档与flag规范.md`，供主 AI 汇总与 1 / 2 号联调对账。

---

## 1. 现状核对（R3 不重做）

| 项 | R2 现有 `grace_network.tres` | 对照 `任务书-R3.md` §2 |
|---|---|---|
| 资源类型 | `GraceNetwork`（`network_id = "network_01_lands_between"`） | ✓ |
| 节点 | 8 个 `GraceNode` 子资源（`GraceNode_01`~`08`） | 3~4 区域 + 2 地牢 + 1 地下入口 ✓ |
| 边 | 7 条 `edges`（`{from, to, requires_flags}`） | 带条件解锁 ✓ |
| 脚本 | `grace_network.gd` / `grace_node.gd`（R2） | 字段与 `RPG系统设计.md` §4.1 一致 ✓ |

> 结论：`grace_network.tres` 已是 M6 口径的完整节点图，R3 无需新增节点 / 边 / 第二座地牢数据表内容（R2 `DONE-R2.md` §3.1 记为「留待 R3」的 8 赐福数据表，经核对其实已在 R2 `.tres` 落地，R3 只补本说明文档）。

---

## 2. M6 拓扑：3~4 区域 + 2 地牢 + 1 地下入口

按 `.tres` 的 `area_id` / `is_dungeon` 归类：

| # | `grace_id` | `display_name` | `area_id` | 归类 | `is_dungeon` | 发现前置 `requires_flags` |
|---|---|---|---|---|---|---|
| 1 | `grace_limgrave_gatefront` | 关卡前 | `area_limgrave` | 地表区域 A | `false` | `{}` |
| 2 | `grace_limgrave_chapel` | 巡礼教堂 | `area_limgrave` | 地表区域 A | `false` | `{}` |
| 3 | `grace_weeping_shore` | 啜泣海岸 | `area_weeping_peninsula` | 地表区域 B | `false` | `world.limgrave_bridge_01.crossed = true` |
| 4 | `grace_stormveil_gate` | 史东薇尔城门 | `area_stormveil_outskirts` | 地表区域 C | `false` | `combat.boss_01_margit.defeated = true` |
| 5 | `grace_bellvault_entry` | 钟窖入口 | `dungeon_01_bellvault` | **地牢 ①** | `true` | `dungeon.bellvault.entered = true` |
| 6 | `grace_bellvault_deep` | 钟窖井底 | `dungeon_01_bellvault` | **地牢 ①** | `true` | `dungeon.bellvault.shortcut_opened = true` |
| 7 | `grace_sunless_tomb_entry` | 无日之墓门厅 | `dungeon_02_sunless_tomb` | **地牢 ②** | `true` | `dungeon.sunless_tomb.entered = true` |
| 8 | `grace_siofra_well` | 希芙拉河井底 | `underground_01_siofra_well` | **地下入口** | `false` | `world.siofra_well_lift_01.unlocked = true` |

**归类统计**：地表区域 3 个（`area_limgrave` / `area_weeping_peninsula` / `area_stormveil_outskirts`）+ 地下区域 1 个（`underground_01_siofra_well`）= **4 区域**；**2 座地牢**（`dungeon_01_bellvault` / `dungeon_02_sunless_tomb`）；**1 个地下入口**（希芙拉河井底，经升降机接入）。满足 §2「3~4 区域 + 2 地牢 + 1 地下入口」。

**7 条带条件边（探索线）**：关卡前→巡礼教堂（无条件）；关卡前→啜泣海岸（过桥）；巡礼教堂→史东薇尔城门（击杀 Margit）；关卡前→钟窖入口（进入钟窖）；钟窖入口→钟窖井底（开单向门捷径）；啜泣海岸→无日之墓门厅（进入无日之墓）；关卡前→希芙拉河井底（升降机解锁）。完整探索线：关卡前 → 钟窖 → 交付 → 啜泣海岸 → 无日之墓 → 史东薇尔 → 希芙拉河井底（接口契约 §5 M6 行）。

---

## 3. 解锁 flag 命名（严格三段式）

### 3.1 节点级 / 网络级 flag

| 类别 | 命名 | 类型 | 写入时机 | 说明 |
|---|---|---|---|---|
| 点亮 | `grace.<对象>.lit` | bool | 首次点燃 | 对象段 = `grace_id` 去 `grace_` 前缀（如 `limgrave_gatefront`） |
| 解锁 | `grace.<对象>.unlocked` | bool | 点燃即解锁 | 传送网络节点即时可用；`neighbors` 仅用于菜单排序 |
| 到访 | `grace.<对象>.visited` | bool | 首次传送落点 | 与 `.tres` 的 `lit_flag` / `unlocked_flag` 字段一致 |
| 网络 | `grace.network.last_rest_epoch` | int | 每次赐福休息 | 与 `spawns.epoch` 同步递增（§4） |
| 网络 | `grace.network.last_grace_id` | String | 休息 / 传送落点 | 死亡后复活锚点，`meta.last_grace_id` 后写覆盖 |

> 例：`.tres` 节点 1 的 `lit_flag = "grace.limgrave_gatefront.lit"`、`unlocked_flag = "grace.limgrave_gatefront.unlocked"`；全部 key 满足 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`，value 仅 `bool / int / float / String`（存档规范 §3.1 / INV-5）。

### 3.2 边条件 flag（7 条，均三段式，来自其它命名空间）

| 边 `from → to` | `requires_flags` |
|---|---|
| 关卡前 → 啜泣海岸 | `world.limgrave_bridge_01.crossed = true` |
| 巡礼教堂 → 史东薇尔城门 | `combat.boss_01_margit.defeated = true` |
| 关卡前 → 钟窖入口 | `dungeon.bellvault.entered = true` |
| 钟窖入口 → 钟窖井底 | `dungeon.bellvault.shortcut_opened = true` |
| 啜泣海岸 → 无日之墓门厅 | `dungeon.sunless_tomb.entered = true` |
| 关卡前 → 希芙拉河井底 | `world.siofra_well_lift_01.unlocked = true` |
| 关卡前 → 巡礼教堂 | `{}`（无条件） |

> 点燃一处赐福的 Delta 最小化：只写 3 个 key —— `grace.<对象>.lit` / `grace.<对象>.unlocked` / `grace.network.last_grace_id`（存档规范 §6「点 1 个赐福后 flags 恰好 3 个 key」）。后续统一登记进 §3.3 全局登记表后再使用，禁止代码临时拼接未登记 key。

---

## 4. 休息回血 / 刷新敌人 与 SaveDelta 的关系（核心）

### 4.1 赐福休息（`WorldState._begin_grace_rest` / 存档规范 §4.6）

| 动作 | 3 号写入 | Delta 落点 |
|---|---|---|
| 递增休息纪元 | `grace.network.last_rest_epoch += 1`，同步 `spawns.epoch` | `flags` + `spawns.epoch` |
| 刷新普通敌人（`respawn_policy = "on_grace_rest"`） | 清空 `spawns.defeated` 中对应 id、`combat.<id>.encounter_started = false` | `spawns.defeated` + `flags` |
| 精英 / Boss（`respawn_policy = "never"`） | **不刷新**：`combat.*.defeated` 永久保留，不进 `spawns.defeated` 清空列表 | 仅 `flags`（不可回滚） |
| 回血 / 补瓶 / 清异常积累 | **3 号不碰战斗数值**：发 `rest_completed(grace_id, epoch)` 信号，由 **2 号**订阅处理 | 不进 3 号 Delta |

> `epoch` 只在休息时递增，`seq` 在每次 `set_flag` 变化时递增，两者独立（存档规范 §4.6）。

### 4.2 与 SaveDelta 合并 / 落盘规则的对应（R3 `save_delta.gd` 7 规则）

| 赐福侧行为 | 对应合并规则 |
|---|---|
| `unlocked` / `defeated` 点亮后不可回退 | **R1 集合并集只增不减**（`merge_set_union`） |
| `meta.last_grace_id`（复活锚点）/ `area_id` 传送落点 | **R4 transform / last_grace 后写覆盖**（`merge_lww_scalars`，LWW by timestamp） |
| 多次休息 / 传送的增量日志行 | **R5 timestamp 升序回放**（`replay`，按 `written_at_unix` 升序、后写覆盖先写） |
| 复活锚点必须先落盘 | **R6 `.tmp` → rename 原子写**（`atomic_write`） |
| 旧版本存档含新赐福网络字段 | **R7 schema_version 迁移链 / 拒绝加载回退基线**（`migrate` / `load_or_baseline`） |

### 4.3 落盘时机（存档规范 §4.8，由 `save_delta_writer.gd` 强制同步）

| 触发 | 信号 / 方法 | `reason` | 落盘方式 |
|---|---|---|---|
| 点燃 / 休息赐福 | 3 号内部 | `"grace_lit"` / `"grace_rest"` | **强制同步**（复活锚点零丢失） |
| 传送前（离开当前区域） | `travel_requested(target_grace_id)` → 1 号 SceneRouter | `"grace_fast_travel"` | **强制同步**；`meta.last_grace_id` 后写覆盖 |
| 地牢进 / 出 | `dungeon_transition_requested(dungeon_id, direction)` | `"dungeon_enter"` / `"dungeon_exit"` | **强制同步**（与 1 号加载边界对齐） |

> 所有 flag 变化只经 `WorldState.set_flag(key, value)`（三段式、幂等、value 白名单），由 `save_delta_writer.gd` 在 0.5 s 合并窗口 / 上述强制点调用 `WorldState._commit_delta(reason)` 落盘；1 / 2 号不读写 `user://saves/`、不构造 SaveDelta（I-1）。玩家精确坐标不进存档，死亡回 `meta.last_grace_id`（法环式）。

---

## 5. 一致性自检

| 检查项 | 结果 |
|---|---|
| 8 节点 / 7 边与 `grace_network.tres` 逐字对齐 | ✓ 本文 §2 / §3.2 全部取自 `.tres` |
| 3~4 区域 + 2 地牢 + 1 地下入口 | ✓ 4 区域 / 2 地牢 / 1 地下入口 |
| 解锁 flag 严格三段式 | ✓ `grace.<对象>.lit/unlocked/visited` + `grace.network.*`，边条件均为三段式 |
| 休息 / 刷新 / Delta 关系与 `存档与flag规范.md` §4.6 / §4.8 一致 | ✓ |
| 与 `接口契约.md` §5 M6 行、I-1 / I-2 口径一致 | ✓ 击杀 flag 仍只由 3 号写；2 号只发信号 / 处理回血 |
| R2 文件不重做 | ✓ 未改 `grace_network.tres` / `grace_network.gd` / `grace_node.gd` |
| 零付费 / 零外部依赖 / 无探针脚本 | ✓ 纯说明文档 + 引用现有资源 |
