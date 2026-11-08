# 存档与 flag 规范（I-1 权威定义 v1.0）

> 工位：3 号（RPG / 世界 / 存档）
> 本文件是契约 **I-1** 的**唯一权威定义方**。1 号（引擎渲染）、2 号（战斗）只依赖本文第 2 节的 `WorldState` 两个方法，**不得**读写存档文件、**不得**构造或解析 `SaveDelta`、**不得**调用本文第 2.5 节列出的内部方法。
> 冲突处理：本文与契约第 3 节 I-1 一致；若其它工位产出与本文不一致，一律由主 AI 在 `00-汇总.md` 裁决，3 号不越界修改他人文件。
> 技术前提：Godot 4 标准版 / GDScript，中文 UTF-8，零外部依赖。

---

## 1. 不变式（任何实现都必须满足）

| # | 不变式 |
|---|---|
| INV-1 | **基线 + 变化 = 当前世界**。Resource 数据表是只读基线（未变化的默认值不进存档），`SaveDelta` 只记录相对基线的变化。 |
| INV-2 | 1 号 / 2 号与世界状态的**唯一**通道是 `WorldState.get_flag / set_flag`；存档文件、Delta、任务状态机对它们不可见。 |
| INV-3 | `get_flag` 是**纯读**：不发信号、不写盘、不产生副作用、不隐式创建 key。 |
| INV-4 | `set_flag` **幂等**：同 key 同 value 重复调用不产生 Delta、不发 `flag_changed`、不增加 `seq`。 |
| INV-5 | flag key 严格三段式 `<模块>.<对象>.<状态>`；value 仅 `bool / int / float / String`。 |
| INV-6 | 门、单向门、隐藏墙、升降机、宝箱、赐福、捷径的状态**全部收敛进 flags**，不新增 SaveDelta 顶层字段。 |
| INV-7 | 单槽、单文件落盘，写入原子化；任何时刻磁盘上都存在一份可加载的完整存档。 |

---

## 2. WorldState —— I-1 对外签名（精确）

### 2.1 注册信息（交给 1 号写进 autoload 表）

| 项 | 值 |
|---|---|
| 单例名 | `WorldState` |
| 脚本路径 | `res://autoload/world_state.gd` |
| Autoload 顺序 | 早于 `CombatEvents`、`ChunkManager`、`SceneRouter`（在 1 号 autoload 表中排在它们之前） |
| 节点类型 | `Node` |
| 归属工位 | **3 号**（1 号只负责在 `project.godot` 注册，不实现逻辑） |

> 1 号任务书 §3 的 autoload 清单里含 `WorldState / GameEvents / SaveSystem / ChunkManager / SceneRouter`。本规范只占用 `WorldState`；`SaveSystem` 与 `WorldState` 是否合并、`GameEvents` 是否为 I-2 的信号总线，见 `README.md`「待主 AI 裁决」条目 A4 / A2。

### 2.2 对外方法（1 号 / 2 号**仅此两个**）

```gdscript
## 纯读。key 不存在或类型不合法时返回 default，不创建 key、不发信号、不写盘。
func get_flag(key: String, default: Variant = null) -> Variant

## 幂等写入。value 仅允许 bool / int / float / String。
## 仅当值真正变化时：更新内存 → 发 flag_changed → 入队 Delta → seq += 1。
func set_flag(key: String, value: Variant) -> void
```

**`get_flag` 行为细则**

1. `key` 不匹配 §3.1 正则时返回 `default`，并 `push_warning`（不抛异常、不中断游戏）。
2. 命中返回基线值或 Delta 覆盖值，返回的是**值拷贝**；调用方修改返回值不影响世界状态。
3. `default` 可以是任意 Variant，但建议与 flag 登记类型一致；`default = null` 时未命中返回 `null`。
4. 允许在 `_ready()`、`_process()`、`_physics_process()`、动画回调里任意调用，无锁、无 IO。

**`set_flag` 行为细则**

1. 幂等判定用 `typeof(old) == typeof(new) and old == new`；`1` 与 `1.0` 视为**不同**（类型不同），登记时应固定类型。
2. value 类型越界（Array / Dictionary / Vector3 / Object …）→ `push_error` 并**忽略本次写入**，不写盘。
3. 变化时按固定顺序执行：更新内存表 → 发信号 → 追加内存 Delta 队列 → `seq += 1` → 按 §4.8 的合并窗口安排落盘。
4. 从**不在** `set_flag` 内同步落盘（避免拾取 / 击杀帧卡顿）。只有 §4.8 的强制落盘点才同步写。

**对外信号（1 号 / 2 号可只读订阅，不依赖其内部实现）**

```gdscript
signal flag_changed(key: String, old_value: Variant, new_value: Variant)
signal delta_committed(seq: int, reason: String)
```

> 订阅是可选的。1 号做 UI（赐福提示、门状态刷新）、2 号做战斗门控时，用 `get_flag` 轮询即可；**禁止**订阅后回调里再调 `set_flag` 造成递归，需要链式更新时用一次性 `call_deferred()`。

### 2.3 1 号 / 2 号调用示例

```gdscript
# 1 号：宝箱网格显隐，只读
func _refresh_chest() -> void:
    var opened: bool = bool(WorldState.get_flag("world.bellvault_chest_01.opened", false))
    $ChestLid.visible = not opened

# 2 号：Boss 二阶段条件，只读
func _should_enter_phase_two() -> bool:
    return bool(WorldState.get_flag("combat.boss_01_margit.phase_two_ready", false))

# 1 号 / 2 号：写入世界状态（唯一合法写法）
WorldState.set_flag("world.bellvault_chest_01.opened", true)
```

### 2.4 禁止清单（硬约束）

- ❌ `FileAccess.open("user://saves/...")`、`ResourceLoader.load` 存档、`JSON.parse` 存档。
- ❌ 直接访问 `WorldState._flags`、`WorldState._delta`、`WorldState.save()`、`WorldState.load()`、`WorldState.commit()`。
- ❌ 自己维护一份"门开了 / Boss 死了"的布尔变量并跨场景携带，绕开 flag。
- ❌ 依赖 `get_flag` / `set_flag` 之外的 WorldState 方法（内部方法见 §2.5，签名可能随版本变）。
- ❌ 用 Array / Dictionary / Vector3 当 flag value 塞世界状态。

### 2.5 3 号内部 API（**不对外**，仅列出以划清边界）

```gdscript
# 以下方法只允许 3 号自己的节点调用；1/2 号依赖它们即视为违约。
func _commit_delta(reason: String) -> void          # 强制落盘
func _apply_snapshot(delta: Dictionary) -> void     # 加载 / 回放
func _begin_grace_rest(grace_id: String) -> void    # 赐福休息，刷新敌人（§4.6）
func _register_baseline(manifest: Dictionary) -> void
func _validate_flag_key(key: String) -> bool
```

---

## 3. flag 命名空间

### 3.1 命名规则

```
key   := <模块> "." <对象> "." <状态>
模块  := world | quest | combat | grace | dungeon
对象  := [a-z0-9_]+        # 不含点号；数据表 id 可直接作为对象段
状态  := [a-z0-9_]+
正则  := ^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$
```

- 全小写 snake_case，**禁止**大写、点号嵌套、驼峰、中文。
- 对象段优先使用数据表 id（如 `elite_01_bell_warden`、`grace_limgrave_gatefront`），保证与 2 号数据表、3 号房间表可对账。
- value 白名单：`bool / int / float / String`；`null` 不是合法 value（"未设置"用 `get_flag(key, false)` 表达）。

> ⚠️ 契约 §2 表格给的规则是三段式，但示例写作 `world.grace_limgrave_lit`（两段式）。本规范按任务书 §5「严格三段式」执行，示例统一为 `grace.limgrave_gatefront.lit`。该差异已列入 `README.md` 待裁决 A1，3 号不自行修改契约。

### 3.2 命名空间表

| 前缀 | 语义 | 归属写入方 | 典型对象 | 典型状态 | 生命周期 |
|---|---|---|---|---|---|
| `world.` | 世界可交互物件：宝箱、门、单向门、隐藏墙、升降机、拾取物、NPC 首次会面 | 3 号（交互物脚本）；1 号可写自己触发的拾取 | `bellvault_chest_01`、`bellvault_shortcut_door_01`、`bellvault_hidden_wall_01`、`bellvault_lift_01`、`npc_01_bellkeeper` | `opened`、`unlocked`、`revealed`、`position`、`taken`、`met` | 永久，随 Delta 持久 |
| `quest.` | 任务状态、阶段、分支结果、交付标记 | 3 号任务状态机 | `bell_of_return` | `stage`(int)、`accepted`、`completed`、`betrayed`、`reward_claimed` | 永久 |
| `combat.` | 击杀 / 阶段 / 遭遇状态 | **3 号**（I-2 订阅后写）；2 号只读 | `elite_01_bell_warden`、`boss_01_margit` | `defeated`、`encounter_started`、`phase_two_ready` | `defeated` 永久；`encounter_started` 可被休息重置 |
| `grace.` | 赐福点亮、解锁、传送网络节点状态 | 3 号 | `limgrave_gatefront`、`bellvault_entry` | `lit`、`unlocked`、`visited`、`last_rest_epoch` | 永久 |
| `dungeon.` | 地牢级结构状态：捷径、层数、入口 | 3 号 | `bellvault`、`sunless_tomb` | `shortcut_opened`、`entered`、`deepest_floor` | 永久 |

**收敛规则（INV-6 落地）**：门 / 单向门 / 隐藏墙 / 升降机**不设** `doors`、`shortcuts`、`lifts` 之类顶层字段，一律以 `world.<对象>.<状态>` / `dungeon.<对象>.<状态>` 存进 `flags` 字典。例如升降机停靠层用 `world.bellvault_lift_01.position = 2`（int，-1/0/1/2 表示层），不用 `float` 坐标、不用嵌套结构。

### 3.3 全局 flag 登记表（M3 / M4 / M6 首批，示例值取基线）

| key | 类型 | 基线 | 写入时机 | 说明 |
|---|---|---|---|---|
| `world.bellvault_chest_01.opened` | bool | `false` | 开箱 | 钟舌碎片所在箱 |
| `world.bellvault_chest_02.opened` | bool | `false` | 开箱 | 隐藏墙后锻石 |
| `world.bellvault_shortcut_door_01.unlocked` | bool | `false` | 从 B3 侧开门 | 单向门，只能由井底侧操作 |
| `world.bellvault_hidden_wall_01.revealed` | bool | `false` | 攻击隐藏墙 | **不给任何提示** |
| `world.bellvault_lift_01.position` | int | `0` | 升降机到达 | `0`=B1，`1`=B2，`2`=B3 |
| `world.bellvault_lift_01.unlocked` | bool | `false` | 从 B2 侧合闸 | 合闸后全层可用 |
| `world.bellvault_key_01.taken` | bool | `false` | 拾取 | 井底锈钥匙 |
| `world.npc_01_bellkeeper.met` | bool | `false` | 首次对话 | 对话节点门控 |
| `quest.bell_of_return.stage` | int | `0` | 任务状态机推进 | `0`未接/`1`取碎片/`2`可交付/`3`完成 |
| `quest.bell_of_return.accepted` | bool | `false` | 选择「接下委托」 | |
| `quest.bell_of_return.completed` | bool | `false` | 交付或私藏结算 | |
| `quest.bell_of_return.betrayed` | bool | `false` | 选择「私藏碎片」 | 影响赐福回忆台词 |
| `quest.bell_of_return.reward_claimed` | bool | `false` | 奖励入包 | 防重复发奖 |
| `combat.elite_01_bell_warden.defeated` | bool | `false` | 订阅 I-2 `enemy_defeated` | 精英不随休息刷新 |
| `combat.elite_01_bell_warden.encounter_started` | bool | `false` | 进入钟厅 | 休息时清空 |
| `grace.limgrave_gatefront.lit` | bool | `false` | 首次点燃 | 地表初始赐福 |
| `grace.limgrave_gatefront.unlocked` | bool | `false` | 点燃即解锁 | 传送网络节点 |
| `grace.bellvault_entry.lit` | bool | `false` | 地牢内点燃 | |
| `grace.bellvault_entry.unlocked` | bool | `false` | 点燃即解锁 | |
| `dungeon.bellvault.shortcut_opened` | bool | `false` | 单向门开启 | 与 `world...unlocked` 同批写 |
| `dungeon.bellvault.deepest_floor` | int | `0` | 抵达新层 | M3 密度统计用 |
| `grace.network.last_rest_epoch` | int | `0` | 每次赐福休息 | 见 §4.6 |
| `grace.network.last_grace_id` | String | `""` | 休息 / 传送落点 | 死亡后复活点 |

> 新增 flag 必须在本文登记表追加一行后再使用；禁止在代码里临时拼接未登记 key。

---

## 4. SaveDelta —— JSON 结构（I-1 权威）

### 4.1 顶层字段（**冻结**，不得新增）

```json
{
  "schema_version": 3,
  "slot": "slot_01",
  "seq": 1842,
  "baseline": {
    "manifest": "res://data/world_baseline.tres",
    "manifest_hash": "sha256:9f2c1d7ab4e05c3f",
    "baseline_version": 1,
    "resource_ids": ["res://data/quests/quest_01_bell_of_return.tres"]
  },
  "flags": { "grace.limgrave_gatefront.lit": true },
  "quests": {
    "quest_01_bell_of_return": { "stage_id": "stage_00_offer", "flags": {} }
  },
  "inventory": { "grants": {}, "consumed": {} },
  "spawns": { "defeated": [], "epoch": 0 },
  "removals": ["world.bellvault_chest_99.opened"],
  "meta": {
    "playtime_seconds": 4217,
    "area_id": "area_limgrave",
    "last_grace_id": "grace_limgrave_gatefront",
    "written_at_unix": 1762610000,
    "game_version": "0.3.0-m3",
    "last_commit_reason": "grace_lit"
  }
}
```

| 字段 | 类型 | 必需 | 语义 |
|---|---|---|---|
| `schema_version` | int | ✅ | 当前 **3**；只允许逐版本迁移（§4.7） |
| `slot` | String | ✅ | 固定 `"slot_01"`，单槽 |
| `seq` | int | ✅ | 单调递增强制落盘序号，用于回放排序与 LWW |
| `baseline` | Dictionary | ✅ | 基线 Resource 清单 + 校验信息（§4.2） |
| `flags` | Dictionary | ✅ | **相对基线的变化 flag**，key 三段式，value 白名单 |
| `quests` | Dictionary | ✅ | 任务 id → `{ "stage_id": String, "flags": Dictionary }`，只存变化的任务 |
| `inventory` | Dictionary | ✅ | `{ "grants": {...}, "consumed": {...} }`，item_id → int 数量 |
| `spawns` | Dictionary | ✅ | `{ "defeated": [String], "epoch": int }`，见 §4.6 |
| `removals` | Array[String] | ✅ | 要从结果中删除的 flag key（用于撤销 / 版本迁移纠偏），可为空数组 |
| `meta` | Dictionary | ✅ | 非玩法元数据：`playtime_seconds`、`area_id`、`last_grace_id`、`written_at_unix`、`game_version` |

**禁止出现的顶层字段**：`doors` / `shortcuts` / `lifts` / `chests` / `graces` / `hidden_walls` / `player_position` / `enemies`。这些状态一律编码进 `flags`（INV-6）。玩家精确坐标不进存档（法环式：死亡回上次赐福，`last_grace_id` 即复活锚点）。

### 4.2 基线（baseline）

```json
"baseline": {
  "manifest": "res://data/world_baseline.tres",
  "manifest_hash": "sha256:9f2c...（由构建期写入，运行期只读校验）",
  "baseline_version": 1,
  "resource_ids": [
    "res://data/quests/quest_01_bell_of_return.tres",
    "res://data/dialogue/dialogue_and_quest.tres",
    "res://data/grace/grace_network.tres",
    "res://data/dungeons/dungeon_01_bellvault.tres"
  ]
}
```

- 基线是**只读 Resource 集合**：所有 flag 默认值为 `false / 0 / 0.0 / ""`，所有任务处于 `stage_00`，所有敌人 `defeated = false`。
- `flags` 中只出现**与基线不同**的 key。把某个 flag 写回基线值时不删除 key，而是保留显式值（避免回放歧义）；需要真正抹除时用 `removals`。
- `manifest_hash` 不匹配时：不拒绝加载，但 `push_warning` 并在 `meta` 里记 `baseline_mismatch = true`（便于换表后排查，不阻塞玩家）。

### 4.3 完整示例 JSON

```json
{
  "schema_version": 3,
  "slot": "slot_01",
  "seq": 1842,
  "baseline": {
    "manifest": "res://data/world_baseline.tres",
    "manifest_hash": "sha256:9f2c1d7ab4e05c3f",
    "baseline_version": 1,
    "resource_ids": [
      "res://data/quests/quest_01_bell_of_return.tres",
      "res://data/dialogue/dialogue_and_quest.tres",
      "res://data/grace/grace_network.tres",
      "res://data/dungeons/dungeon_01_bellvault.tres"
    ]
  },
  "flags": {
    "world.bellvault_chest_01.opened": true,
    "world.bellvault_shortcut_door_01.unlocked": true,
    "world.bellvault_hidden_wall_01.revealed": true,
    "world.bellvault_lift_01.position": 2,
    "world.bellvault_lift_01.unlocked": true,
    "world.npc_01_bellkeeper.met": true,
    "quest.bell_of_return.stage": 2,
    "quest.bell_of_return.accepted": true,
    "combat.elite_01_bell_warden.defeated": true,
    "grace.limgrave_gatefront.lit": true,
    "grace.limgrave_gatefront.unlocked": true,
    "grace.bellvault_entry.lit": true,
    "grace.bellvault_entry.unlocked": true,
    "dungeon.bellvault.shortcut_opened": true,
    "dungeon.bellvault.deepest_floor": 2,
    "grace.network.last_rest_epoch": 12,
    "grace.network.last_grace_id": "grace_bellvault_entry"
  },
  "quests": {
    "quest_01_bell_of_return": {
      "stage_id": "stage_02_return",
      "flags": {
        "quest.bell_of_return.accepted": true,
        "quest.bell_of_return.reward_claimed": false
      }
    }
  },
  "inventory": {
    "grants": {
      "item_bell_fragment": 1,
      "item_smithing_stone_01": 2
    },
    "consumed": {
      "item_rusted_key": 1
    }
  },
  "spawns": {
    "defeated": ["elite_01_bell_warden"],
    "epoch": 12
  },
  "removals": [],
  "meta": {
    "playtime_seconds": 4217,
    "area_id": "dungeon_01_bellvault",
    "last_grace_id": "grace_bellvault_entry",
    "written_at_unix": 1762610000,
    "game_version": "0.3.0-m3",
    "last_commit_reason": "grace_rest"
  }
}
```

> 该示例对应「已点燃两处赐福、开单向门捷径、找到隐藏墙、击杀精英、拿到碎片但尚未交付」的 M3/M4 交叉状态，可直接作为联调基准。

### 4.4 合并与回放顺序

单槽采用 **「一个快照主文件 + 追加日志」**：`delta.json` 是最新完整快照，`delta.log` 是上次快照之后的增量行（每行一个 `{"seq":…, "flags":{…}, …}`）。加载流程严格按序：

1. **读基线** → 构造 `state0`（§4.2）。
2. **读 `delta.json`** → 校验 `schema_version`（§4.7）、`slot`、`seq` → 覆盖到 `state0` 得到 `state1`。
3. **读 `delta.log`** → 按 `seq` **升序**逐行回放，仅回放 `seq > delta.json.seq` 的行；损坏或半截的最后一行**丢弃**（日志是尽力而为的补偿，不是权威）。
4. **应用 `removals`** → 从 `flags` 删除列出的 key，回落到基线值。
5. **`quests` 覆盖**：任务 stage 与 flags 以快照为准，日志中同任务取 `seq` 最大者。
6. **`inventory` 累加**：`grants` 求和、`consumed` 求和，再按 `grants - consumed` 结算；负数夹到 0。
7. **`spawns` 按 epoch 处理**：日志 `epoch > 快照 epoch` 时清空 `defeated`（赐福休息刷新，§4.6）后再并入。
8. **压缩（compact）**：回放完成后立即把 `state` 写成新 `delta.json`，清空 `delta.log`，并更新 `seq`。
9. **注入 WorldState**：`_apply_snapshot(state)` → 内存 flag 表就绪 → 发 `delta_committed(seq, "load")`。

**冲突覆盖规则（LWW by seq）**

| 场景 | 规则 |
|---|---|
| 同 flag key 在快照与日志都出现 | `seq` 大者胜；`seq` 相同取快照 |
| 同 flag key 在日志多行出现 | 最后一行（最大 seq）胜 |
| 类型冲突（如 bool vs int） | 迁移完成后以**登记表 §3.3 声明类型**为准；无法转换则丢弃该日志行并 `push_warning` |
| `removals` 与 `flags` 同时含同 key | `removals` 优先（先删后不加） |
| `quests.stage_id` 与 `flags["quest.x.stage"]` 不一致 | 以 `flags` 的 int 阶段为准，回写 `stage_id`，并记 `meta.stage_repaired = true` |
| `spawns.defeated` 与 `combat.*.defeated` 不一致 | 以 `combat.*.defeated = true` 为准补齐，反向不减（击杀不可回滚） |

### 4.5 原子写

```
_commit_delta(reason):
  1  冻结内存状态 → 序列化为 JSON 文本 json_text
  2  FileAccess.open("user://saves/slot_01/delta.json.tmp", WRITE)
  3  store_string(json_text) → flush() → close()          # 必须 flush 后再 close
  4  DirAccess.rename_absolute(tmp, delta.json)            # 同一文件系统内原子替换
  5  成功后追加一行 delta.log（可选，失败不影响主文件）
  6  保留 delta.json.bak（上次成功快照），仅在本次成功后覆盖
  7  发 delta_committed(seq, reason)
```

- 任一步失败：**不删除**旧 `delta.json`，`delta.json.tmp` 保留供排查，`push_error` 并继续游戏（内存状态仍正确）。
- `user://` 在桌面端不保证目录 fsync；用 `rename` 而非"先写空再写内容"来避免半文件。
- 主线程执行，JSON 体积上限按 M6 全量估算 **< 64 KB**，同步写一次 < 1 帧；不引入线程写盘。

### 4.6 赐福休息与 `respawn_epoch`

- `grace.network.last_rest_epoch` 每次休息 `+1`，并同步写入 `spawns.epoch`。
- 休息时刷新**普通敌人**（`respawn_policy = "on_grace_rest"`）：清空 `spawns.defeated` 中对应 id，并把 `combat.<id>.encounter_started` 置回 `false`。
- **精英 / Boss 不刷新**（`respawn_policy = "never"`）：`combat.elite_01_bell_warden.defeated` 与 `combat.boss_01_margit.defeated` 永久保留，不进 `spawns.defeated` 的清空列表，只留在 `flags`。
- 休息回血、补瓶、重置异常积累由 2 号处理；3 号只负责写 epoch 与刷新标记，**不碰战斗数值**。
- `epoch` 只在休息时递增，`seq` 在每次 `set_flag` 变化时递增，两者独立。

### 4.7 `schema_version` 迁移链

| 版本 | 变更 | 迁移函数 |
|---|---|---|
| 1 | 初版：只有 `flags` + `quests` | `migrate_v1_to_v2()` |
| 2 | 增加 `spawns.epoch`、`inventory.consumed`、`baseline.manifest_hash` | `migrate_v2_to_v3()` |
| **3（当前）** | 增加 `removals`、`meta.game_version`、`grace.network.last_rest_epoch` 约定 | — |

- **禁止跳级**：`1 → 2 → 3` 逐级执行；每级迁移前先备份原文件为 `delta.v<n>.bak`。
- 未知更高版本（`schema_version > 3`）→ **拒绝加载**，提示"存档来自更新版本"，保留文件不动，允许玩家选择新档；绝不猜测字段。
- 缺失 `schema_version` 视为 v1。
- 迁移后 `seq` 不变，`meta.migrated_from` 记录原版本号。

### 4.8 写入时机

| 触发 | 落盘方式 | `reason` | 理由 |
|---|---|---|---|
| `set_flag` 变化 | 入队，**0.5 s 合并窗口**，同窗口内多次变化合并为一次写 | `"flag_batch"` | 避免拾取连点 / 连击刷盘 |
| 点燃 / 休息赐福 | **强制同步** | `"grace_lit"` / `"grace_rest"` | 复活锚点必须先落盘 |
| 传送前（离开当前区域） | **强制同步** | `"grace_fast_travel"` | 防止跨场景丢状态 |
| 地牢短加载边界（进 / 出） | **强制同步** | `"dungeon_enter"` / `"dungeon_exit"` | 与 1 号加载边界对齐 |
| 订阅 I-2 击杀（尤其 Boss） | **强制同步** | `"enemy_defeated"` / `"boss_defeated"` | 击杀不可回滚 |
| 拾取关键任务物品 / 开箱 | **强制同步** | `"loot"` | 防止重复拾取 |
| 开单向门 / 升降机合闸 / 隐藏墙 | 入队合并 | `"flag_batch"` | 结构性状态，随下一次强制点落盘 |
| 对话选择改变任务阶段 | **强制同步** | `"quest_stage"` | M4「flag 变化驱动对话分支」的持久化前提 |
| 玩家主动退出 / `NOTIFICATION_WM_CLOSE_REQUEST` | **强制同步** | `"quit"` | 退出即完整存档 |
| 死亡复活 | 不额外写（休息与击杀已落盘） | — | 复活点由 `last_grace_id` 决定 |

> 崩溃恢复口径：最多丢失合并窗口内（0.5 s）的非关键 flag 变化；赐福、击杀、任务阶段、拾取、传送这五类**零丢失**，因为它们是强制同步点。

### 4.9 单槽路径与文件清单

```
user://saves/
└── slot_01/
    ├── delta.json          # 权威快照（INV-7）
    ├── delta.log           # 增量补偿日志，回放后清空
    ├── delta.json.bak      # 上一次成功快照
    ├── delta.json.tmp      # 原子写临时文件（成功后消失）
    └── delta.v1.bak / delta.v2.bak   # 迁移前备份
```

- 固定单槽 `slot_01`；`slot` 字段写死，不做多槽选择 UI。
- 新游戏：删除 `slot_01/` 内 `delta.json` 与 `delta.log`，从基线重建，`seq = 0`。
- 存档不写入 `res://`（打包后只读），也不写 teamwork 目录。

---

## 5. 与 I-2 / 任务 / 赐福的衔接

| 来源 | 3 号处理 | 写入内容 |
|---|---|---|
| I-2 `enemy_defeated(enemy_id: String)` | `_on_enemy_defeated()`：查 SpawnRequest 的 `defeated_flag` | `set_flag("combat.<enemy_id>.defeated", true)`；若 `respawn_policy != "never"` 追加到 `spawns.defeated`；强制落盘 |
| I-2 `boss_defeated(boss_id: String)` | `_on_boss_defeated()` | `set_flag("combat.<boss_id>.defeated", true)` + `set_flag("combat.<boss_id>.phase_two_ready", false)`；解锁对应赐福 / 区域 flag；强制落盘 |
| 对话选择 `set_flags` | 逐条 `set_flag`，再写 `quests` 的 stage | 见 `dialogue_and_quest.tres` |
| 赐福点燃 | 写 `grace.<对象>.lit/unlocked` + `grace.network.last_grace_id` | 传送网络节点即时可用 |
| 赐福休息 | `last_rest_epoch += 1`、刷新敌人、回血由 2 号读 flag 后处理 | §4.6 |

> 击杀 flag 归属 3 号（契约 I-2「3 号订阅并写 Delta」）。2 号**只发信号不写 flag**，避免双写导致 `seq` 重复。该口径已列入 `README.md` 待裁决 A3 供主 AI 确认。

---

## 6. 验收口径

| 项 | 判定 |
|---|---|
| I-1 签名 | 1/2 号代码中出现 `WorldState.` 时，只允许 `get_flag(` / `set_flag(`；全文检索无 `FileAccess` + `saves` 组合 |
| 幂等 | 连续 `set_flag(k, true)` 100 次，`seq` 只 +1，`delta_committed` 只发 1 次 |
| 纯读 | `get_flag("不存在的.key.x", false)` 前后 `seq` 不变、文件 mtime 不变 |
| Delta 最小化 | 全新档 `flags` 为空 `{}`；只点 1 个赐福后 `flags` 恰好 3 个 key（`lit` / `unlocked` / `last_grace_id`） |
| 回放 | 制造 3 行日志（含 1 行半截 JSON），加载后状态 == 前 2 行合并结果，`delta.log` 已清空 |
| 原子写 | 写盘过程中强杀进程，重启后 `delta.json` 仍是上一次完整快照，可正常加载 |
| 迁移 | 手工放入 v1 存档，加载后 `schema_version == 3` 且 `spawns.epoch == 0`、`inventory.consumed == {}` |
| 三段式 | 全量 key 通过 §3.1 正则；value 类型全部落在白名单 |
| M3 / M4 联动 | 开箱→休息→退出→重进，宝箱保持已开、精英保持已死、任务阶段保持、对话分支随 flag 切换 |
