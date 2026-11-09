# HUD-BINDING.md · R15 HUD ↔ WorldState / 赐福网络 数据绑定方案

> 命令 `cmd-20261109-083628-784-A3` · `[ROUND=R15]` · Rank-3（RPG / 世界 / 存档）
> 引擎 Godot 4.7.2.stable · 中文 UTF-8 · 零付费 · 默认不刺探 · 不伪造输出
> 配套件：`godot/scenes/hud.tscn`（R13 交付）、`godot/scripts/attach_hud.gd`（R14 交付）、`godot/data/rpg/grace_network.tres`

---

## 0. 定位与边界（先声明）

**本件是方案文档，不是实现。R15 按边界「只交付方案」，R16 再绑数据。**

| 项 | 本轮口径 |
|---|---|
| 本轮产出 | 仅 `Rank-3/HUD-BINDING.md`、`Rank-3/DONE-R15.md`、回执 JSON |
| 不写 | 不改 `godot/scenes/hud.tscn`、不改 `godot/scenes/courtyard.tscn`（Rank-1 本轮独占）、不落盘 `hud.gd`、不自行 git |
| 不跑 | 未调用 Godot、未真跑 `--script` / `pack()`、未取得任何运行期 stdout，本文无「真跑结论」可贴 |
| `hud.gd` | **只给方法签名 / 信号草案，不实现**（§3） |
| 菜单 UI | 当前 `hud.tscn` 只有 `HudPanel` + `TitleLabel`，**尚无菜单容器节点**；菜单节点的新增属 R16，本轮只在方案层描述数据驱动逻辑 |

**权威源（开工只读一次）**：`godot/scenes/hud.tscn`、`Rank-3/HUD-SPEC.md`、`Rank-3/HUD-ATTACH.md`、`godot/data/rpg/grace_network.tres`、`Rank-3/SAVE-SPEC-FINAL.md`、`teamwork/00-群聊总线.md`。
**口径佐证（本工位既有件，只读核对）**：`Rank-3/grace_network.md`、`Rank-3/RPG系统设计.md` §4.2、`Rank-3/chunk_world_bridge.gd`、`godot/scripts/rpg/world_state.gd`。

---

## 1. 金色 Label ↔ WorldState 三段式 flag 绑定

### 1.1 现状：`hud.tscn` 的金色 Label

`godot/scenes/hud.tscn` 共 3 个节点，根为 `CanvasLayer`：

| 节点 | 类型 | 金色相关 | 位置 |
|---|---|---|---|
| `Hud` | `CanvasLayer` | — | `hud.tscn:11` |
| `HudPanel` | `Panel` | 边框 `Color(0.83, 0.68, 0.3, 1)`（静态样式，不绑 flag） | `hud.tscn:13-18` |
| `TitleLabel` | `Label` | `theme_override_colors/font_color = Color(0.83, 0.68, 0.3, 1)`、`font_size = 20`、`text = "赐福 · 宁姆格福"` | `hud.tscn:20-27` |

**「金色 Label」= `TitleLabel`**：其字形色与 `HudPanel` 边框同为暖金 `#D4AD4D`（`HUD-SPEC.md` §3）。本轮 `TitleLabel.text` 是静态中文占位，`HUD-SPEC.md §5.2` 已预约「正式版改为从 `WorldState.get_flag(...)` / 赐福网络读取当前赐福名，由 3 号后续 RPG 逻辑接管」——本件即把这一条展开为可执行口径。

### 1.2 三段式 flag 口径（已裁决，直接沿用）

- 格式：`grace.<对象>.<状态>`，例 `grace.limgrave_gatefront.lit`；正则 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`（`SAVE-SPEC-FINAL.md` §2、INV-5）。
- **A8 争议已裁决为严格三段式**：`MSG-20261109-0400-HOST`（总指挥裁决 A6「A8 契约两段式示例回改为严格三段式」），`SAVE-SPEC-FINAL.md §2` 的 `world.grace_limgrave_lit` 两段式示例**不作准**。
- `grace.` 命名空间归属 3 号写入；典型状态 `lit` / `unlocked` / `visited` / `last_rest_epoch`（`SAVE-SPEC-FINAL.md §2` 5 前缀表）。
- 网络级锚点 `grace.network.last_grace_id`（String，复活 / 传送落点）、`grace.network.last_rest_epoch`（int）见 `grace_network.md §3.1`。
- **key 不拼接**：一律取 `.tres` 节点自带的 `lit_flag` / `unlocked_flag` 字段（已是 `grace.limgrave_gatefront.lit` 形式），网络级 key 用已登记常量。依据 `SAVE-SPEC-FINAL.md §2`：「新增 flag 必须先在 §3.3 登记表追加一行再用，禁止代码里临时拼接未登记 key」。

### 1.3 绑定映射表

| UI 属性 | 数据来源 | `get_flag(key, default)` 的 key | default | 说明 |
|---|---|---|---|---|
| `TitleLabel.text` | `grace.network.last_grace_id` → 查 `.tres` 节点 `display_name` | `grace.network.last_grace_id` | `""` | 文本 = `"赐福 · " + display_name`；空值回退占位 `"赐福 · 宁姆格福"` |
| `TitleLabel` 点亮高亮 | 当前赐福节点的 `lit_flag` | `grace.<对象>.lit` | `false` | `true` → 保持金色；`false` → 运行期降为暗色 / 半透明（`theme_override_colors/font_color`） |
| 菜单条目可选态 | 每个节点的 `unlocked_flag` | `grace.<对象>.unlocked` | `false` | 见 §2.2 |
| 边条件门控 | `edges[*].requires_flags` | `world.* / combat.* / dungeon.*` | `false` | 见 §2.3 |

> `default` 取值说明：`godot/scripts/rpg/world_state.gd:51` 的函数签名是 `get_flag(key: String, default: Variant = null) -> Variant`，但 `SAVE-SPEC-FINAL.md §2` 明确「`null` 不是合法 value」「未设置用 `get_flag(key, false)` 表达」。因此 **HUD 侧必须显式传业务默认值**（bool → `false`、String → `""`），不得依赖 `null` 形参默认，避免把 `null` 传播进 UI 分支。

### 1.4 `get_flag(key, default)` 调用时机

`get_flag` 是**纯读**：不创建 key / 不发信号 / 不写盘 / 返回值拷贝（`SAVE-SPEC-FINAL.md §2`、INV-3）。据此定 4 个调用时机：

| # | 时机 | 动作 | 读哪些 key |
|---|---|---|---|
| 1 | `_ready()`（`WorldState` 就绪、HUD 实例化后） | `refresh_all()` **一次全量刷新** | `grace.network.last_grace_id` + 8 节点 `lit_flag` / `unlocked_flag` |
| 2 | `WorldState.flag_changed(key, old, new)` 信号回调 | `_on_flag_changed()` 命中绑定集合时 `refresh_label(key)` **增量刷新** | 仅变化的那个 key |
| 3 | `WorldState.delta_committed(seq, reason)` 信号回调 | 存档回放 / 跨场景注入后兜底一次 `refresh_all()` | 全量（防信号丢失 / 回放注入不一致） |
| 4 | 场景切换完成 / HUD 常驻重新激活 | 重跑 `refresh_all()` | 全量（HUD 若为 autoload 或运行期挂载不销毁，见 `HUD-SPEC.md §5` 方式 B/C） |

> `flag_changed` / `delta_committed` 信号定义见 `godot/scripts/rpg/world_state.gd:15-16`：
> `signal flag_changed(key: String, old_value: Variant, new_value: Variant)`、`signal delta_committed(seq: int, reason: String)`。
> `set_flag` 幂等（同值不发信号、不增 seq，INV-4），因此信号驱动不会造成重复刷新。

### 1.5 刷新策略

1. **事件驱动 + 一次初始化全量**，**禁止**在 `_process()` / `_physics_process()` 里每帧 `get_flag` 轮询：`get_flag` 返回拷贝、有开销，且 flag 变化已有 `flag_changed` 信号，轮询无收益。
2. **只读不写**：HUD / `hud.gd` 绝不调用 `set_flag`、不调用 `commit`、不构造 `SaveDelta`（I-1 边界，`SAVE-SPEC-FINAL.md §3` / §4）。点亮、写 `last_grace_id` 由 3 号交互逻辑完成，HUD 只订阅结果。
3. **刷新幂等**：`refresh_all()` 可重复调用，内部以「读取 → 比对 → 赋值」实现，避免 `Label.text` 无谓重设。
4. **默认值兜底**：`last_grace_id` 为空 / 查不到 `display_name` 时回退静态占位文本，保证 HUD 在任何存档状态下都有可显示内容（不因缺 flag 空白）。
5. **不碰静态样式**：`HudPanel` 金边、`TitleLabel` 的 `.tscn` 内 `font_color` 常量本轮不动；R16 由 `hud.gd` 在**运行期**改 `font_color` 实现点亮态，`.tscn` 落盘值保持不变（`HUD-SPEC.md §3` 只改 `build_hud.gd` 常量重跑的口径适用于换配色，不用于运行期状态）。

---

## 2. 赐福菜单：`grace_network.tres` 8 节点 / 7 边数据驱动

### 2.1 数据源与字段

运行期唯一数据源：`res://data/rpg/grace_network.tres`（`godot/data/rpg/grace_network.tres`，工程根装配后 `res://data/* → res://data/rpg/*` 已修正）。工位内 `teamwork/Rank-3/grace_network.tres` 是 R2 快照，**不作运行期数据源**。

`load()` 一次并缓存，取两个字段（`grace_network.tres:130-174`）：

- `network_id = "network_01_lands_between"`
- `nodes`：8 个 `GraceNode` 子资源（`GraceNode_01`~`08`），每个含
  `grace_id` / `display_name` / `area_id` / `scene_path` / `spawn_marker` / `lit_flag` / `unlocked_flag` / `requires_flags` / `neighbors` / `is_dungeon` / `discover_radius`。
- `edges`：7 条 `{ "from": String, "to": String, "requires_flags": Dictionary }`。

8 节点 / 7 边与 M6 拓扑（4 区域 + 2 地牢 + 1 地下入口）逐字对齐，见 `grace_network.md §2`；本方案**不硬编码任何赐福名 / 边**，菜单条目、分组、排序、门控全部运行时从 `.tres` 读取。

### 2.2 菜单构建（数据驱动流程）

```
build_grace_menu():
    for node in _net.nodes:                       # 8 个节点，遍历而非枚举常量
        discovered = _all_flags(node.requires_flags)   # 发现前置，逐条 get_flag(k, false)
        unlocked   = WorldState.get_flag(node.unlocked_flag, false)
        if discovered and unlocked:
            条目 = { id: node.grace_id, text: node.display_name,
                     group: node.area_id, is_dungeon: node.is_dungeon,
                     order: node.neighbors }        # 文本/分组/排序全取自 .tres
```

- **文本**：`display_name`（如「关卡前」「巡礼教堂」），替代当前占位的区域名「宁姆格福」。
- **分组**：`area_id`（`grace_network.md §2` 归为 4 区域 + 2 地牢 + 1 地下入口）；`is_dungeon` 作地牢标记（纯文本，零素材）。
- **排序 / 插入**：`neighbors` 仅用于菜单排序（`grace_network.md §3.1`）；点亮新赐福后 `reason="grace_lit"` 落盘完成 → `flag_changed` 触发 `refresh_all()` → 菜单即时插入该节点（`RPG系统设计.md §4.2` 点亮流程末步）。
- **排序不依赖边**：`edges` 不参与菜单排序，只参与 §2.3 的目标合法性校验。

### 2.3 目标合法性校验（7 条带条件边）

选中目标后、发传送信号前（`RPG系统设计.md §4.2` 传送第 1 步）：

1. `WorldState.get_flag(target.unlocked_flag, false) == true`；
2. 从当前所在赐福到目标、沿 `edges` 的每条 `requires_flags` 逐条 `WorldState.get_flag(k, false) == expected` 全部满足。

7 条边条件来自跨命名空间（`grace_network.md §3.2`），均用 `get_flag(k, false)` 求值：

| 边 `from → to` | `requires_flags` |
|---|---|
| 关卡前 → 巡礼教堂 | `{}`（无条件） |
| 关卡前 → 啜泣海岸 | `world.limgrave_bridge_01.crossed = true` |
| 巡礼教堂 → 史东薇尔城门 | `combat.boss_01_margit.defeated = true` |
| 关卡前 → 钟窖入口 | `dungeon.bellvault.entered = true` |
| 钟窖入口 → 钟窖井底 | `dungeon.bellvault.shortcut_opened = true` |
| 啜泣海岸 → 无日之墓门厅 | `dungeon.sunless_tomb.entered = true` |
| 关卡前 → 希芙拉河井底 | `world.siofra_well_lift_01.unlocked = true` |

**落点数据交接**：校验通过后，`scene_path` + `spawn_marker` 随 `travel_requested(target_grace_id)` 交给 1 号 SceneRouter / ChunkManager；3 号**不负责场景切换实现**（`RPG系统设计.md §4.2` 第 5 步、`RPG-WIRING.md` §边界）。

### 2.4 `grace_fast_travel` 强制落盘口径（本件重点）

**定义与归属**

- `reason` 常量：`godot/scripts/rpg/chunk_world_bridge.gd:43` `const REASON_FAST_TRAVEL: String = "grace_fast_travel"`。
- 规范出处：`存档与flag规范.md §4.8`（经 `grace_network.md §4.3` 汇总）；属「赐福 / 击杀 / 任务阶段 / 拾取 / 传送」**五类零丢失强制同步点**之一（`SAVE-SPEC-FINAL.md §3` 崩溃恢复行）。
- 触发点：赐福菜单确认传送，**离开当前区域之前**（`grace_network.md §4.3`「传送前（离开当前区域）」）。

**不可颠倒的顺序**（`RPG系统设计.md §4.2` 传送 1~3 步 + `RPG-WIRING.md:148` 实证链路）：

```
1 校验目标 unlocked_flag == true 且 edges[*].requires_flags 全部满足   （§2.3）
2 先落盘：SaveDeltaWriter.commit(reason="grace_fast_travel")
          → WorldState._commit_delta(reason)
          → 原子写 .tmp → flush → rename_absolute → delta.json        （INV-7 / SAVE-SPEC §4.5 §4.9）
          并 meta.last_grace_id 后写覆盖（R4 merge_lww_scalars）
3 后发信号：GameEvents.travel_requested(target_grace_id)
          → 1 号 SceneRouter / ChunkManager 换场景、落到 spawn_marker
```

- **不进 0.5 s 合并窗口**：`save_delta_writer.gd` 在强制点立即 `commit`，`seq` 单调递增（`SAVE-SPEC-FINAL.md §3` 写入时机行）。
- **为何是强制点**：传送跨 1 号加载边界，是丢状态风险最高的一步（`RPG系统设计.md §4.2` 末）。
- **运行期实证（既有轮次，本文引用非本轮真跑）**：R7/W7 `T3_COMMIT_REASON reason=grace_fast_travel`、`T3_DELTA_EXISTS`、`T3_DELTA_FLAGS`（落盘 `flags=["grace.network.last_grace_id", "world.chunk_limgrave_0_0.loaded"]`），见 `RPG-WIRING.md:134-148`、`I-INTERFACE-SELFCHECK.md:50,69`、`DONE-R9.md:75`；`pass=45 fail=0`。

**I-1 边界（HUD 侧必须遵守）**

- `hud.gd` / 赐福菜单**只发 `travel_requested` 信号**，不调用 `SaveDeltaWriter.commit()`、不构造 / 解析 `SaveDelta`、不 `FileAccess.open("user://saves/…")`、不 `ResourceLoader.load` 存档、不 `JSON.parse` 存档（`SAVE-SPEC-FINAL.md §3` I-1）。
- 强制落盘由 3 号内部链路订阅完成：`ChunkWorldBridge._on_travel_requested → SaveDeltaWriter.commit("grace_fast_travel") → WorldState._commit_delta → delta.json`（`chunk_world_bridge.gd:123,141`）。
- 1 / 2 号与世界状态的唯一通道仍是 `WorldState.get_flag / set_flag`（INV-2）。

**reason 对照（勿混用）**

| 触发 | `reason` | 落盘方式 |
|---|---|---|
| 点燃赐福 | `grace_lit` | 强制同步；只写 3 key：`grace.<对象>.lit` / `.unlocked` / `grace.network.last_grace_id`（`grace_network.md §3.1`） |
| 休息 | `grace_rest` | 强制同步；`grace.network.last_rest_epoch` + `spawns.epoch` |
| **传送** | **`grace_fast_travel`** | **强制同步；`meta.last_grace_id` 后写覆盖** |
| 地牢进 / 出 | `dungeon_enter` / `dungeon_exit` | 强制同步（与 1 号加载边界对齐） |
| 任务阶段 | `quest_stage` | 强制同步 |
| 击杀 | `boss_defeated` / `enemy_defeated` | 强制同步（I-2，3 号订阅写 flag） |

---

## 3. `hud.gd` 接口草案（只给签名 / 信号，不实现）

### 3.1 定位

- 挂载点：`hud.tscn` 根节点 `Hud`（`CanvasLayer`），`extends CanvasLayer`。
- **R15 不落盘此脚本**；R16 实现后挂到 `hud.tscn`（届时才会改 `hud.tscn`，属 R16 范围）。
- `class_name`：**待定**，草案倾向不加全局类名（避免与既有 `class_name` 冲突），用节点路径 + `@export` 引用；如需注册由 R16 裁决。
- 归属目录建议 `godot/scripts/rpg/hud.gd`（3 号 `scripts/rpg` 独占目录，与 `world_state.gd` / `chunk_world_bridge.gd` 同侧）。

### 3.2 信号（HUD → 外部）

```gdscript
signal grace_selected(target_grace_id: String)      # 菜单选中某个已解锁赐福（仅 UI 事件）
signal travel_confirmed(target_grace_id: String)    # 确认传送；等价于触发 GameEvents.travel_requested
signal rest_requested(grace_id: String)             # 请求休息（→ grace_rest 落盘，由 3 号状态机处理）
signal hud_refreshed()                              # 一次完整 refresh_all() 完成（自检 / 调试）
```

> `travel_confirmed` / `rest_requested` 是**请求信号**，不携带落盘动作；`grace_fast_travel` 的 `commit` 由订阅方（3 号桥接 / `SaveDeltaWriter`）完成，符合 §2.4 的 I-1 边界。

### 3.3 方法签名（草案，无函数体）

```gdscript
extends CanvasLayer

# ---- 依赖注入（R16 装配；R15 未注入时走只读占位）----
@export var grace_network_path: String = "res://data/rpg/grace_network.tres"
var _world_state: Node = null                        # /root/WorldState（autoload）
var _net: Resource = null                           # GraceNetwork

func _ready() -> void
func bind_world_state(ws: Node) -> void              # R16 注入 WorldState 引用并连信号
func load_grace_network(path: String) -> void         # load .tres，取 nodes / edges，缓存 _net

# ---- flag 读取与刷新（对应 §1.4 / §1.5）----
func refresh_all() -> void                           # _ready / delta_committed / 场景切换后全量刷新
func refresh_label(key: String) -> void              # flag_changed 命中的单 key 增量刷新
func _on_flag_changed(key: String, old_value: Variant, new_value: Variant) -> void
func _on_delta_committed(seq: int, reason: String) -> void

# ---- 金色 Label 绑定（对应 §1.3）----
func set_title_from_grace(grace_id: String) -> void  # "赐福 · " + nodes[*].display_name
func apply_lit_state(lit: bool) -> void              # 运行期改 font_color 点亮 / 暗色；不改 .tscn

# ---- 赐福菜单（对应 §2，8 节点 / 7 边数据驱动）----
func build_grace_menu() -> Array[Dictionary]         # 遍历 nodes，过滤 unlocked + requires_flags
func is_grace_unlocked(node: Resource) -> bool        # get_flag(node.unlocked_flag, false)
func are_flags_satisfied(requires: Dictionary) -> bool # 逐条 get_flag(k, false) == expected
func get_reachable_targets(from_id: String) -> Array[String]  # 用 edges[*].requires_flags 求可达目标
func on_grace_selected(target_grace_id: String) -> void       # 菜单点击回调 → grace_selected 信号
func request_travel(target_grace_id: String) -> void          # 校验 → travel_confirmed 信号（不自行落盘）
```

### 3.4 草案边界注释

- 上述均为**签名草案**，R15 不写函数体、不落盘 `.gd`、不做 `--check-only`。
- HUD 只读 `WorldState.get_flag`；**不** `set_flag`、**不** `commit`、**不**读写 `user://saves/`。
- 菜单容器节点（`ItemList` / `VBoxContainer` 等）当前 `hud.tscn` 不存在，R16 新增；本轮不预设节点名以免与 R16 实装冲突，方案只约束「数据来源是 `.tres`」。
- 信号名与 `GameEvents`（`travel_requested` / `rest_completed` / `dungeon_transition_requested`）的衔接由 R16 定：草案用 HUD 自有信号，桥接层再转发，避免 HUD 直接依赖 1 号 SceneRouter。

---

## 4. 接入主场景的时机与依赖（R15 挂 HUD / R16 绑数据）

### 4.1 时间线

| 轮次 | 归属 | 动作 | 对 `courtyard.tscn` / `hud.tscn` 的影响 |
|---|---|---|---|
| R13 | Rank-3 | 交付独立 `hud.tscn`（3 节点，静态占位） | 新建 `hud.tscn`；不接主场景 |
| R14 | Rank-3 | 交付 `attach_hud.gd` + `HUD-ATTACH.md`，仅 `--check-only` 语法门禁 | **不写主场景** |
| **R15（本轮）** | **Rank-1 执行 / Rank-3 只写方案** | Rank-1 本轮对 `courtyard.tscn` 的并发修改结束、场景稳定后，**串行**去掉 `--check-only` 真跑 `attach_hud.gd`，把 `hud.tscn` 以 `instance=ExtResource(...)` 挂到 `SubViewportContainer/SubViewport/FXLayer` 下 | Rank-1 独占改 `courtyard.tscn`（追加式，既有 22 节点逐字一致，预期 22→23）；**`hud.tscn` 不变** |
| **R16** | **Rank-3** | 实现 `hud.gd`、接入 `WorldState` / `grace_network.tres` / `GameEvents`，把数据绑定跑通 | 届时改 `hud.tscn`（挂脚本 + 新增菜单容器）；`courtyard.tscn` 由 Rank-1 保持 |

R15 串行的原因（`HUD-ATTACH.md §2`）：Rank-1 本轮并发改同一 `courtyard.tscn`，`attach_hud.gd` 真跑会 `ResourceSaver.save()` 覆盖该文件，并行会互相覆盖；必须等 Rank-1 落盘完成且不再改动后执行，执行前后各留一次哈希。回读校验用 `CACHE_MODE_IGNORE` 强制从磁盘重读，确认 `FXLayer/Hud` 及 `HudPanel` / `TitleLabel` 完整（`HUD-ATTACH.md §4`）。

### 4.2 R16 绑数据的前置依赖（缺一不可）

| # | 依赖 | 现状 / 来源 | 校验方式 |
|---|---|---|---|
| 1 | R15 HUD 实例已稳定挂入主场景 | 待 Rank-1 本轮完成 | `attach_hud.gd` 回读 `PROBE hud_present`、节点数 23（`HUD-ATTACH.md §4`） |
| 2 | `WorldState` autoload 就绪 | 已注册（`DONE-R8.md` §2） | `/root/WorldState` 可解析；`flag_changed` / `delta_committed` 信号可连 |
| 3 | `grace_network.tres` 运行期可加载 | 工程根已装配（`MSG-20261109-0249-HOST` Rank-3 `res://data/* → res://data/rpg/*`） | `load("res://data/rpg/grace_network.tres")` 取到 `nodes.size()==8` / `edges.size()==7` |
| 4 | `hud.gd` 由草案转实现并挂到 `hud.tscn` | R16 本轮工作 | `--check-only` 通过后由脚本挂 `script = ExtResource(...)` |
| 5 | `travel_requested → commit("grace_fast_travel")` 链路就绪 | R7/R9 已实证 W7 PASS（`RPG-WIRING.md:148`） | 端到端断言 `T3_COMMIT_REASON` |
| 6 | `GameEvents` 信号总线可用 | `game_events.gd`（本工位既有） | `travel_requested` / `rest_completed` 可 emit / 可订阅 |

### 4.3 冲突规避

- **R15**：Rank-3 **不碰** `courtyard.tscn`（Rank-1 本轮独占）、**不碰** `hud.tscn`（R16 才改）；本轮可写范围仅 `Rank-3/` 与 `command_center/ai/3/outbox/`（回执），沿用 `HUD-ATTACH.md §7` 边界。
- **R16**：改 `hud.tscn` 前需确认 Rank-1 对 HUD 实例的挂载已稳定、不再改动该场景引用；菜单容器节点追加式新增，既有 `Hud` / `HudPanel` / `TitleLabel` 保持（`HUD-SPEC.md §5` 装配注意 1）。
- 不自行 git（commit / push 均由 HOST 收口）。

---

## 5. 口径对齐自检（方案层，非真跑）

| 检查项 | 结论 | 依据 |
|---|---|---|
| 金色 Label 定位为 `TitleLabel` | ✅ | `hud.tscn:20-27` / `HUD-SPEC.md §3` |
| 三段式 flag 与 A8 裁决一致 | ✅ 用 `grace.limgrave_gatefront.lit`，不用两段式 | `SAVE-SPEC-FINAL.md §2`、`MSG-20261109-0400-HOST` A6 |
| `get_flag(key, default)` 纯读、显式传业务默认值 | ✅ | `world_state.gd:51`、INV-3、`SAVE-SPEC-FINAL.md §2` |
| 刷新为事件驱动、无每帧轮询、HUD 只读不写 | ✅ | INV-2 / INV-3 / I-1 |
| 菜单 8 节点 / 7 边全部取自 `.tres`，无硬编码 | ✅ | `grace_network.tres:133-174`、`grace_network.md §2` |
| `grace_fast_travel` 先落盘后发信号、不进合并窗口 | ✅ | `RPG系统设计.md §4.2`、`grace_network.md §4.3`、`chunk_world_bridge.gd:43` |
| HUD 不 `commit` / 不构造 SaveDelta | ✅ | I-1（`SAVE-SPEC-FINAL.md §3`） |
| R15 挂 HUD 归 Rank-1、R16 绑数据归 Rank-3 | ✅ | `HUD-ATTACH.md §2`、任务书 `[ROUND=R15]` |
| 本轮未改任何场景 / 脚本 / 未跑 Godot / 未自行 git | ✅（如实登记） | 本件 §0 |

---

## 6. 未完成项与阻塞（详见 `DONE-R15.md` ③）

1. `hud.gd` 仅草案，未实现、未落盘、未做语法门禁 —— 按边界只交付方案，R16 实装。
2. `hud.tscn` 尚无赐福菜单容器节点 —— R16 追加式新增，本轮不改。
3. 金色 Label 的 `lit_flag` 点亮态、菜单 UI 与 `WorldState` / `GameEvents` 的端到端联调未做 —— 依赖 R15 HUD 挂载完成（Rank-1）+ R16 绑数据。
4. `grace.network.last_grace_id` 空值时的具体回退界面文案、菜单容器类型（`ItemList` / `VBoxContainer`）、`class_name` 是否注册 —— 留 R16 裁决，本轮只给默认 `""` + 占位文本回退口径，不擅自定死。
5. 运行期实证数据（节点数、真跑 stdout、断言）本轮**未产生、不贴、不伪造**；§2.4 引用的 `W7 PASS` 均为既有轮次结论，非本轮真跑。
