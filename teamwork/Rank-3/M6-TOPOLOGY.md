# M6 探索线拓扑表（Rank-3 · R9 汇总材料）

> 工位：3 号（RPG / 世界 / 存档）｜轮次：**R9**｜中文 UTF-8｜**为 `00-汇总.md` 准备**
> 数据源（开工只读一次）：`godot\data\rpg\m6_area_bindings.tres`、`godot\data\rpg\grace_network.tres`（与 `teamwork\Rank-3\` 同名副本逐字一致）、`godot\data\rpg\dungeon_01_bellvault.tres`、`godot\data\rpg\spawn_bellvault_elite_01.tres`、`箱庭地牢模板.md` §3 / §7、`存档与flag规范.md` §3.3 / §4.8、`接口契约.md` §5（I-6 M6 行）。
> 运行期实证：R9 真跑 `W7_SUMMARY pass=45 fail=0`，其中 `T3_NODES_8` / `T3_EDGES_7` / `T3_AREAS_6` / `T3_COVER_AREAS 6/6` / `T3_COVER_GRACES 8/8` / `T3_FLAGS_3SEG` 全 PASS（实际输出见 `I-INTERFACE-SELFCHECK.md` §5 与 `DONE-R9.md` ②）。
> 本表为**整理件**，不新增、不修改任何 `.tres` / `.gd`；数据源即权威定义。

---

## 0. 规模总览

| 类别 | 数量 | 明细 |
|---|---|---|
| 地表区域 | **3** | `area_limgrave`、`area_weeping_peninsula`、`area_stormveil_outskirts` |
| 地下入口 | **1** | `underground_01_siofra_well`（`is_underground = true`） |
| 地牢 | **2** | `dungeon_01_bellvault`、`dungeon_02_sunless_tomb`（`is_dungeon = true`） |
| **area binding 合计** | **6** | `m6_area_bindings.tres` 的 `bindings` 数组长度 = 6（W7 `T3_AREAS_6` / `T3_COVER_AREAS 6/6`） |
| **赐福节点** | **8** | `grace_network.tres` 的 `nodes` 数组长度 = 8（W7 `T3_NODES_8` / `T3_COVER_GRACES 8/8`） |
| **传送连接边** | **7** | `grace_network.tres` 的 `edges` 数组长度 = 7（W7 `T3_EDGES_7`） |
| `network_id` | 1 | `network_01_lands_between`（两份 `.tres` 一致） |

> 任务书「3~4 区域 + 2 地牢 + 1 地下入口」在本表中落为 **3 地表区域 + 1 地下入口（合计 4 个区域/入口类）+ 2 地牢 = 6 个 area binding**。

---

## 1. 区域 / 地牢 / 地下入口表（6 行，含解锁 flag）

来自 `m6_area_bindings.tres`。`boundary_flags` 即进入该区域所需的**解锁 flag**（与对应赐福节点的 `requires_flags` 逐项一致，见 §2 / §3）。

| # | area_id | region | 类型 | scene_path | grace_ids | boundary_flags（解锁 flag） |
|---|---|---|---|---|---|---|
| A1 | `area_limgrave` | `limgrave` | 地表区域 | `res://scenes/areas/Limgrave.tscn` | `grace_limgrave_gatefront`、`grace_limgrave_chapel` | `[]`（**初始可达，无前置**） |
| A2 | `area_weeping_peninsula` | `weeping_peninsula` | 地表区域 | `res://scenes/areas/WeepingShore.tscn` | `grace_weeping_shore` | `world.limgrave_bridge_01.crossed` |
| A3 | `area_stormveil_outskirts` | `stormveil` | 地表区域 | `res://scenes/areas/StormveilGate.tscn` | `grace_stormveil_gate` | `combat.boss_01_margit.defeated` |
| A4 | `underground_01_siofra_well` | `siofra_well` | **地下入口**（`is_underground=true`） | `res://scenes/areas/SiofraWell.tscn` | `grace_siofra_well` | `world.siofra_well_lift_01.unlocked` |
| A5 | `dungeon_01_bellvault` | `bellvault` | **地牢**（`is_dungeon=true`） | `res://scenes/dungeons/Bellvault.tscn` | `grace_bellvault_entry`、`grace_bellvault_deep` | `dungeon.bellvault.entered` |
| A6 | `dungeon_02_sunless_tomb` | `sunless_tomb` | **地牢**（`is_dungeon=true`） | `res://scenes/dungeons/SunlessTomb.tscn` | `grace_sunless_tomb_entry` | `dungeon.sunless_tomb.entered` |

> `chunk_origin_x` / `chunk_origin_y` 六行全为 `0`（占位），scene_path 六条均为 `res://scenes/...` 声明路径，未实机换场景；属 Rank-1 `SceneRouter` / 场景布局，超 3 号范围（沿用 `DONE-R8.md` ③ 第 5 项登记，只登记不擅改）。

---

## 2. 8 赐福节点表

来自 `grace_network.tres` 的 8 个 `GraceNode` 子资源。`lit_flag` / `unlocked_flag` 全部通过 I-1 三段式正则（W7 `T3_FLAGS_3SEG`）。

| # | grace_id | 名称 | area_id | lit_flag | unlocked_flag | requires_flags（节点级） | neighbors | is_dungeon |
|---|---|---|---|---|---|---|---|---|
| G1 | `grace_limgrave_gatefront` | 关卡前 | `area_limgrave` | `grace.limgrave_gatefront.lit` | `grace.limgrave_gatefront.unlocked` | `{}` | G2、G3、G5、G8 | false |
| G2 | `grace_limgrave_chapel` | 巡礼教堂 | `area_limgrave` | `grace.limgrave_chapel.lit` | `grace.limgrave_chapel.unlocked` | `{}` | G1、G4 | false |
| G3 | `grace_weeping_shore` | 啜泣海岸 | `area_weeping_peninsula` | `grace.weeping_shore.lit` | `grace.weeping_shore.unlocked` | `world.limgrave_bridge_01.crossed=true` | G1、G7 | false |
| G4 | `grace_stormveil_gate` | 史东薇尔城门 | `area_stormveil_outskirts` | `grace.stormveil_gate.lit` | `grace.stormveil_gate.unlocked` | `combat.boss_01_margit.defeated=true` | G2 | false |
| G5 | `grace_bellvault_entry` | 钟窖入口 | `dungeon_01_bellvault` | `grace.bellvault_entry.lit` | `grace.bellvault_entry.unlocked` | `dungeon.bellvault.entered=true` | G1、G6 | true |
| G6 | `grace_bellvault_deep` | 钟窖井底 | `dungeon_01_bellvault` | `grace.bellvault_deep.lit` | `grace.bellvault_deep.unlocked` | `dungeon.bellvault.shortcut_opened=true` | G5 | true |
| G7 | `grace_sunless_tomb_entry` | 无日之墓门厅 | `dungeon_02_sunless_tomb` | `grace.sunless_tomb_entry.lit` | `grace.sunless_tomb_entry.unlocked` | `dungeon.sunless_tomb.entered=true` | G3 | true |
| G8 | `grace_siofra_well` | 希芙拉河井底 | `underground_01_siofra_well` | `grace.siofra_well.lit` | `grace.siofra_well.unlocked` | `world.siofra_well_lift_01.unlocked=true` | G1 | false |

> G1 是**网络枢纽**（4 个邻居，唯一 `requires_flags={}` 且 `is_dungeon=false` 的入口）；G6 钟窖井底是 **M6 增量**（M3 不放置，见 `箱庭地牢模板.md` §7）。

---

## 3. 7 条连接边表（含解锁 flag / 单向门捷径标注）

来自 `grace_network.tres` 的 `edges`。`requires_flags` 在运行期经 `WorldState.get_flag` 求值、不缓存（W7 `T3_GATE_EDGE_PASS` / `T3_GATE_LOCKED`）。

| # | from → to | requires_flags（解锁 flag） | 边类型 | 关联区域 / 说明 |
|---|---|---|---|---|
| E1 | `grace_limgrave_gatefront` → `grace_limgrave_chapel` | `{}` | **无条件 · 初始开放** | 同 A1 内，W7 `T3_EDGE_OPEN` 实证 |
| E2 | `grace_limgrave_gatefront` → `grace_weeping_shore` | `world.limgrave_bridge_01.crossed=true` | 桥门控 | A1→A2，W7 `T3_GATE_EDGE_PASS` 实证（set_flag 后即通行） |
| E3 | `grace_limgrave_chapel` → `grace_stormveil_gate` | `combat.boss_01_margit.defeated=true` | **Boss 门控** | A1→A3，W7 `T3_GATE_LOCKED` 实证（未击杀保持锁定） |
| E4 | `grace_limgrave_gatefront` → `grace_bellvault_entry` | `dungeon.bellvault.entered=true` | 地牢入口 | A1→A5 |
| E5 | `grace_bellvault_entry` → `grace_bellvault_deep` | `dungeon.bellvault.shortcut_opened=true` | **单向门捷径（M6 增量）** | A5 内部，详见 §4 |
| E6 | `grace_weeping_shore` → `grace_sunless_tomb_entry` | `dungeon.sunless_tomb.entered=true` | 地牢入口 | A2→A6 |
| E7 | `grace_limgrave_gatefront` → `grace_siofra_well` | `world.siofra_well_lift_01.unlocked=true` | 升降机门控 | A1→A4（地下入口） |

**解锁 flag 去重汇总（6 个，全部三段式、全部 `grace`/`world`/`combat`/`dungeon` 前缀）**：

| 解锁 flag | 语义 | 出现位置 |
|---|---|---|
| `world.limgrave_bridge_01.crossed` | 断桥已过 | A2 boundary / G3 / E2 |
| `combat.boss_01_margit.defeated` | Boss「玛尔基特」击杀 | A3 boundary / G4 / E3 |
| `world.siofra_well_lift_01.unlocked` | 希芙拉河升降机解锁 | A4 boundary / G8 / E7 |
| `dungeon.bellvault.entered` | 进入钟窖 | A5 boundary / G5 / E4 |
| `dungeon.sunless_tomb.entered` | 进入无日之墓 | A6 boundary / G7 / E6 |
| `dungeon.bellvault.shortcut_opened` | 钟窖单向门捷径已开 | G6 / E5（**非 area boundary**，M6 增量） |

> A1 无 boundary_flag，E1 无 requires_flags → **初始可达**，保证探索线有起点，不会全图锁死。

---

## 4. 单向门捷径（专节）

任务书点名要求项。唯一实例落在 `dungeon_01_bellvault`（钟窖，3 层 / 14 房间），定义于 `dungeon_01_bellvault.tres` + `箱庭地牢模板.md` §3 / §7。

| 项 | 值 / 口径 |
|---|---|
| 门 id | `bellvault_shortcut_door_01` |
| `InteractableSpec.kind` | `one_way_door` |
| 房间位置 | B3 `room_b3_02_shortcut_door` → B1 `room_b1_02_grace_hall`（赐福厅，捷径终点） |
| `open_side` | `b3_side`（**只能从 B3 井底侧开启**；判定靠 `open_side` + 玩家所在房间 id 双条件，不靠碰撞体朝向） |
| 交互物 flag | `world.bellvault_shortcut_door_01.unlocked = true`（`Spec_shortcut_door.flag_key`） |
| 结构 flag | `dungeon.bellvault.shortcut_opened = true`（`dungeon_definition.shortcut_flag`） |
| 开启写入 | 两 flag **同批** `set_flag`（一次 `seq` 合并窗口，见 `存档与flag规范.md` §3.3 / `箱庭地牢模板.md` §3） |
| 落盘 | `delta_checkpoint = true`，`reason = "shortcut_opened"`，**强制同步**（`存档与flag规范.md` §4.8；`箱庭地牢模板.md` §3 / §5 #10） |
| 单向语义 | B1 侧靠近无提示、按键无响应（反侧「无响应但可见门体」）；开门后 `⑬ → ⑭ → ②` 一步回 B1 赐福厅，**不可重新锁上** |
| 网络耦合 | `dungeon.bellvault.shortcut_opened` 是 **E5**（G5 → G6 `grace_bellvault_deep`）的 `requires_flags`，也是 **G6 节点**的 `requires_flags`；M3 井底赐福不放置，属 **M6 增量** |
| 与隐藏墙区别 | 隐藏墙 `prompt_enabled = false`（零提示、零可见提示）；单向门反侧只是无响应，**仍可看见门体**，两者不可混为一谈 |
| 收敛（INV-6） | 无 `doors` / `shortcuts` 顶层字段，门状态全部收敛进 `flags` 字典 |

> 相关但非捷径：`world.bellvault_lift_01.position`（int，0=B1/1=B2/2=B3）、`world.bellvault_lift_01.unlocked`、`world.bellvault_hidden_wall_01.revealed`（`prompt_enabled=false`），见 `存档与flag规范.md` §3.3 登记表。

---

## 5. 探索线闭环（M6 完整跑通路径）

基准路径取自 `接口契约.md` §5（I-6 M6 行）：**关卡前 → 钟窖 → 交付 → 啜泣海岸 → 无日之墓 → 史东薇尔 → 希芙拉河井底**。按本表拓扑展开为可执行序列：

| 步 | 动作 | 触发 / 解锁 flag | 落点 |
|---|---|---|---|
| 0 | 初始点燃「关卡前」 | `grace.limgrave_gatefront.lit/unlocked`（无前置） | G1 / A1 |
| 1 | 走 E1 到「巡礼教堂」 | `{}`（W7 实证传送链路 `reason=grace_fast_travel`） | G2 / A1 |
| 2 | 进钟窖（E4） | `dungeon.bellvault.entered=true` | G5 / A5 |
| 3 | 下到 B3 开单向门，解锁井底赐福（E5，§4） | `world.bellvault_shortcut_door_01.unlocked=true` + `dungeon.bellvault.shortcut_opened=true` | G6 / A5 |
| 4 | 取钟舌碎片 → 交付 / 私藏（任务阶段推进） | `quest.bell_of_return.stage` → `2`/`3`，`reason=quest_stage` 强制落盘 | 回到地表 |
| 5 | 过桥（E2）到「啜泣海岸」 | `world.limgrave_bridge_01.crossed=true` | G3 / A2 |
| 6 | 进无日之墓（E6） | `dungeon.sunless_tomb.entered=true` | G7 / A6 |
| 7 | 击杀玛尔基特（E3） | `combat.boss_01_margit.defeated=true`（I-2 → 3 号写 flag，强制落盘 `boss_defeated`） | G4 / A3 |
| 8 | 解锁升降机（E7）下希芙拉河井底 | `world.siofra_well_lift_01.unlocked=true` | G8 / A4 |

> 中途退出重进：赐福 / 门 / 单向门 / 任务阶段 / 击杀均为 `存档与flag规范.md` §4.8 的**强制同步点**，复活锚点由 `grace.network.last_grace_id` 决定 → 探索线不断线（M6 验收口径，见 `接口契约.md` §5 M6 行）。

---

## 6. 待裁决 / 未实机项（只登记，不擅改）

| # | 项 | 性质 | 归属 |
|---|---|---|---|
| 1 | 6 条 `scene_path` 未实机换场景、`chunk_origin_x/y` 全 0 | 场景布局 / `SceneRouter`，超 3 号范围 | Rank-1（沿用 `DONE-R8.md` ③ 第 5 项） |
| 2 | `dungeon_02_sunless_tomb` 仅有拓扑绑定 + 1 赐福，无独立箱庭模板 | 内容密度待补 | 3 号后续 / HOST 排期 |
| 3 | 契约 §2 示例 `world.grace_limgrave_lit`（两段式）vs §3.1 严格三段式 | 口径差异，已登记 `README.md` **A8** | HOST 裁决，3 号不自行改契约 |
| 4 | `chunk.<id>.loaded` 三段式归一最终口径 A/B/C | 只登记不擅改（`R5-待裁决登记.md` §2） | HOST 裁决 |
| 5 | 8 条 `preset.0` ERROR（`export_presets.cfg`，R10 并行） | 配置读取错误、非脚本错误、跨工位时序 | Rank-1；见 `DONE-R9.md` ②，3 号不擅改 |

> 以上均**未在本轮改动**；本表只依据既有权威件整理，供 `00-汇总.md` 直接引用。
