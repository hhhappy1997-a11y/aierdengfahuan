# 3 号工位交付说明：RPG / 世界 / 存档

> 5-AI 协作中的 **3 号执行 AI**。负责总纲 **3.3（RPG 交互）** + 赐福传送网络 + Delta 持久化存档，里程碑 **M3 / M4 / M6**。
> 输入源（只读）：本目录 `任务书.md`、根目录 `00-项目总纲.md`、`00-协作契约.md`；另只读参考了 1 / 2 号 `任务书.md` 用于跨模块接口口径对齐。按后发的 `00-接入指令.md` / `00-群组通信协议.md`，开工**只读一次**群组协议、群聊总线与进度台账；未读取其它工位产出内容。**未写入任何其它文件夹**。
> 唯一写入目录：`F:\Game\aierdengfahuan\teamwork\Rank-3\`（按用户派单；与任务书 §0 写的 `3\` 存在命名差异，见待裁决 A1）。

---

## 1. 模块目标

把法环的「对话 / 任务 / 拾取 / 赐福网络 / 箱庭地牢 / 只存变化的存档」翻译成 **Godot 4 Resource 驱动、可直接落地**的规格，并且**定义 I-1 与 I-3 两个权威接口**，让 1 号（引擎渲染）与 2 号（战斗）可以并行开发而不必猜签名。

三条主线：

1. **I-1 权威**：`WorldState.get_flag / set_flag` 精确签名 + `SaveDelta` JSON 结构（基线 + 变化、合并回放、原子写、schema 迁移）。
2. **I-3 权威**：`SpawnRequest` 17 字段集，2 号按此消费，数值仍归 2 号数据表。
3. **内容可落地**：一份能照着搭的钟窖地牢模板 + 一份合法 Godot 4 `.tres` 的 NPC 任务闭环，做到「改数据表不改代码」。

---

## 2. 交付清单（6 个文件，中文 UTF-8，全部在 `Rank-3\`）

| # | 文件 | 内容 | 状态 |
|---|---|---|---|
| 1 | `README.md` | 本文件：目标 / 清单 / 接口摘要 / 未完成项 / **待主 AI 裁决** | ✅ |
| 2 | `RPG系统设计.md` | Resource 结构总表、条件门控（flag + 背包）、任务信号 + 状态机、NPC 闭环时序图、拾取 / 门 / 隐藏墙 / 单向门、赐福传送网络（8 节点 7 边）、M6 拓扑 | ✅ |
| 3 | `存档与flag规范.md` | **I-1 权威**：SaveDelta 完整示例 JSON、顶层字段冻结表、9 步回放 / LWW 冲突、原子写、`1→2→3` 迁移链、写入时机、单槽路径、WorldState 精确签名、flag 三段式命名空间与 24 项登记表 | ✅ |
| 4 | `箱庭地牢模板.md` | 钟窖 `dungeon_01_bellvault`：14 房间清单、三层剖面 / 拓扑文字图、单向门捷径规则、加载边界与 ≤ 0.8 s 短加载、11 个 Delta 检查点、精英 `SpawnRequest` 完整参数 + `.tres` 片段、密度与 M3 验收口径 | ✅ |
| 5 | `dialogue_and_quest.tres` | **合法 Godot 4 `.tres`**：`quest_01_bell_of_return`「归乡之铃」完整闭环。9 个 Gate / 15 行台词 / 4 个 Choice / 9 个 Node / 4 个 Stage / 1 个 QuestData / 2 个 DialogueGraph；首见 3 段、2 组分支、flag + 背包门控、分支奖励字段、赐福回忆复用 | ✅ |
| 6 | `接口契约.md` | I-1 / I-2 / I-3 / I-6 对齐；订阅 I-2 信号的具体方式；`SpawnRequest` 17 字段完整表；3 号对外信号 / 方法 / 资源汇总；**M0~M6 分阶段交付表**；一致性自检 | ✅ |

**交给主 AI 的实际文件路径列表**

```
F:\Game\aierdengfahuan\teamwork\Rank-3\README.md
F:\Game\aierdengfahuan\teamwork\Rank-3\RPG系统设计.md
F:\Game\aierdengfahuan\teamwork\Rank-3\存档与flag规范.md
F:\Game\aierdengfahuan\teamwork\Rank-3\箱庭地牢模板.md
F:\Game\aierdengfahuan\teamwork\Rank-3\dialogue_and_quest.tres
F:\Game\aierdengfahuan\teamwork\Rank-3\接口契约.md
```

> 本目录另有主 AI 派单 `任务书.md`（只读，未修改）。总计 6 份交付件 + 1 份派单，未新建任何脚本 / 探针 / 测量 / preflight 文件，未修改 teamwork 根目录及 1 / 2 / 4 号文件夹任何内容。

---

## 3. 对外接口摘要

| 编号 | 方向 | 3 号提供 / 消费 | 一句话口径 |
|---|---|---|---|
| **I-1** | 3 → 1 / 2 | **定义并提供** | `WorldState.get_flag(key: String, default: Variant = null) -> Variant`（纯读）与 `set_flag(key: String, value: Variant) -> void`（幂等）；1 / 2 号**只经这两个方法**，禁止碰存档文件与 SaveDelta。SaveDelta 顶层 9 字段冻结，`schema_version = 3`，单槽 `user://saves/slot_01/delta.json` |
| **I-2** | 2 → 3 | **消费** | 订阅 `enemy_defeated(enemy_id: String)` / `boss_defeated(boss_id: String)`，写 `combat.<对象>.defeated` 并**强制落盘**；2 号不写 flag（防双写）。信号承载体用「节点组 `combat_signal_bus` 优先 + `/root/GameEvents` 兼容」发现，不要求 2 号改代码 |
| **I-3** | 3 → 2 | **定义** | `SpawnRequest` 17 字段：`request_id / enemy_id / spawn_point_id / position / facing_degrees / level / hp_override / stance_override / aggro_radius / leash_radius / respawn_policy / defeated_flag / loot_table_id / patrol_route / is_boss / spawn_group_id / metadata`。战斗数值仍归 2 号数据表，2 号不得增删字段 |
| **I-6** | 3 → 主 AI | **提供** | M0~M6 分阶段交付表见 `接口契约.md` §5，可直接汇总排期 |

**3 号对外主要信号**：`flag_changed` / `delta_committed` / `quest_started` / `quest_stage_changed` / `quest_completed` / `dialogue_opened` / `dialogue_closed` / `dungeon_transition_requested` / `travel_requested` / `rest_completed` / `item_acquired`。

**关键设计决策（供裁决时参考）**

- flag 严格三段式 `<模块>.<对象>.<状态>`，5 个前缀 `world. / quest. / combat. / grace. / dungeon.`，value 仅 4 种标量；门 / 单向门 / 隐藏墙 / 升降机状态全部收敛进 `flags`，不新增 SaveDelta 顶层字段。
- 交互物**不把"已用过"存在节点实例里**，一律 `get_flag` 判定，因此 1 号 chunk 卸载后重建不会丢状态（M2 / M3 共用机制）。
- 赐福「交谈 / 回忆」与 NPC 交谈**复用同一个 `DialogueRunner` 与同一套 Resource**，只换 `trigger_source` / `trigger_owner_id`；`.tres` 里两个图共用 Gate / Line / Node 子资源。
- 对话 Resource 的数组字段统一声明为**非类型化 `Array`**（运行时 `as` 断言），保证手写 `.tres` 在 Godot 4 下零歧义加载。
- 隐藏墙 `prompt_enabled = false`，零提示（无图标 / 文字 / 高亮 / 音效 / 小地图 / 任务日志明写），但背后有实物奖励。
- M3 严格「1 赐福 + 1 精英 + 1 单向门捷径」；井底赐福 `grace_bellvault_deep` 是 M6 增量。

---

## 4. 未完成项（如实列出，不含任何付费 / 外部依赖）

| # | 未完成项 | 原因 / 交接对象 |
|---|---|---|
| 1 | 7 个对话 / 任务 Resource 的 `.gd` 脚本实现 | 本工位交付清单固定为 6 份（文档 + 1 份 `.tres`），且契约规定只写自己文件夹；脚本路径已在 `RPG系统设计.md` §6 给出，待 1 号建工程后由主 AI 安排落地 |
| 2 | `WorldState.gd` / `SaveDeltaWriter.gd` / `DialogueRunner.gd` / `QuestStateMachine.gd` 等运行逻辑 | 同上，本文只给精确签名与行为契约 |
| 3 | `grace_network.tres` / `dungeon_01_bellvault.tres` / `world_baseline.tres` / `spawn_bellvault_elite_01.tres` | 结构已定义、实例已给，需在 Godot 工程内生成；地牢 `SpawnRequest` 片段可直接拷用 |
| 4 | `.tscn` 场景文件 | 场景树骨架文字已在 `箱庭地牢模板.md` §4.3 给出，实现属 1 号 |
| 5 | 真跑 Godot 4 验证 | Godot 工程根（`F:\Game\aierdengfahuan\`）尚未建立，本轮无法导入 `.tres` 实测；已做字段 / 引用 / 语法静态核对，待 1 号建工程后联调 |
| 6 | M6 的 8 赐福节点数据表与第二座地牢 | 拓扑与接入规则已给，内容填充属 M6 阶段 |
| 7 | 手感与审美判断 | 按总纲第 5 节与契约 §5，必须由人上手试玩判断，AI 不代判 |
| 8 | 群聊总线的 3 条消息（回应开通 / CLOSED / 交付完成） | 与目录所有权铁律冲突，3 号未写根目录；全文已备在 §5.1，待 HOST / OWNER 代发或授权后补发 |

---

## 5. 待主 AI 裁决项（**只记录，不越界修改**）

> 以下均为跨模块口径差异或契约未指定项。3 号已给出自己的可执行默认值，但**最终以主 AI 在 `00-汇总.md` 的裁决为准**；裁决前 3 号不改任何其它文件、不改契约。

| 编号 | 事项 | 3 号现状 / 建议 | 需裁决的点 |
|---|---|---|---|
| **A1** | **目录命名（已基本闭环）** | 本工位 `任务书.md` §0 副本仍写 `teamwork\3\`；但 `00-进度台账.md` §2 记载主 AI 已于 22:53 把契约目录树、README 与 4 份任务书统一为 `Rank-N\`，文件系统实际也只有 `Rank-1~Rank-4`。本工位按**用户派单 + 台账**落到 `Rank-3\` | 仅需把本工位 `任务书.md` §0 残留的旧路径同步为 `Rank-3\`（3 号不修改派单文件）；汇总时一律以 `Rank-3\` 为准 |
| **A2** | **I-2 信号承载主体与参数类型** | 契约只写「2 号发 `enemy_defeated(enemy_id)` / `boss_defeated(boss_id)`」，未说挂在哪个节点。3 号默认「节点组 `combat_signal_bus` 优先 + `/root/GameEvents` autoload 兼容」，参数按 **单个 String** | 2 号究竟在哪发（敌人节点自身 / `GameEvents` autoload / 独立总线）？参数是 `String` 还是 `StringName`？是否带第二参数？建议统一到 1 号 autoload 表里的 `GameEvents` 并明确挂名 |
| **A3** | **击杀 flag 归属与双写** | 契约 I-2 明确「3 号订阅并写 Delta」，3 号据此要求 **2 号只发信号、不写 `combat.*` flag**；但 2 号派单 §4.5 写「按 I-1 只走 WorldState」，可能被理解为 2 号也可写 flag | 明确「击杀 flag 只由 3 号写」，避免双写导致 `seq` 重复；同时确认 2 号是否允许为战斗门控写 `combat.*.phase_two_ready` 之类的临时 flag |
| **A4** | **autoload 清单合并** | 1 号派单 §3 的 autoload 表含 `WorldState / GameEvents / SaveSystem / ChunkManager / SceneRouter`；3 号只占用 `WorldState`（`res://autoload/world_state.gd`，1 号注册、3 号实现） | `SaveSystem` 是否与 `WorldState` 合并？`GameEvents` 是否为 A2 的信号总线？请给出最终 autoload 归属表，避免 1 号注册名与 3 号实现名不一致 |
| **A5** | **`SpawnRequest` 字段集双定义** | 3 号在 `接口契约.md` §3 定义 **17 字段**；2 号派单 §3 要求 `数据表schema.md` 也列 `SpawnRequest`，同时注明「最终字段以 3 号定义为准」 | 请主 AI 逐字段核对两份 schema，特别是 `hp_override / stance_override` 的哨兵值（`-1` / `-1.0`）、`respawn_policy` 枚举、`patrol_route` 非类型化 `Array`、以及 `metadata` 是否允许塞战斗数值。差异统一到 3 号表 |
| **A6** | **加载接口归属** | 3 号地牢短加载约定「3 号发 `dungeon_transition_requested(dungeon_id, direction)` → 1 号 `ChunkManager` 暂停 3x3 → 1 号调 `ResourceLoader`」；传送发 `travel_requested(target_grace_id)` | 1 号是否提供这两个信号的承载节点？`ChunkManager` 暂停 / 恢复的公开方法名是什么？短加载遮罩与淡入淡出由谁实现（3 号只给时序，实现倾向 1 号） |
| **A7** | **密度口径的移速基准** | `箱庭地牢模板.md` §7 按 M1 玩家基础移速 **3.5 m/s** 折算「30 秒 ≈ 105 m」，得出最长空窗 26 s 达标 | 2 号 M1 最终移速若不是 3.5 m/s，房间步行秒数需重算、密度结论需复核；请锁定一个基准值写进契约 |
| **A8** | **flag 三段式 vs 契约示例** | 契约 §2 表格规则为三段式 `<模块>.<对象>.<状态>`，但同表示例写「world.grace_limgrave_lit」（两段式，本工位不采用）；任务书 §5 硬性要求「严格三段式」 | 本工位按三段式（如 `grace.limgrave_gatefront.lit`）执行。请裁决是否把契约示例一并修正，避免 1 / 2 号照示例写出两段式 key |
| **A9** | **任务奖励 / 背包结算归属** | 3 号 `QuestStage.rewards` 与 `DialogueChoice.grant_items / consume_items` 只产出**奖励数据与 `item_acquired` 信号**；`runes` 与物品入包的具体结算未指定归属 | 背包 / 卢恩结算是 2 号职责还是 3 号自建 `Inventory`？若属 2 号，请给出结算方法名或信号；否则 3 号需补一个 `Inventory` 单例（会与 A4 autoload 表冲突） |
| **A10** | **M3「1 赐福」与 M6 井底赐福边界** | 3 号按 M3 严格只放 `grace_bellvault_entry`；`grace_bellvault_deep` 作为 M6 增量，边条件 `dungeon.bellvault.shortcut_opened` | 确认 M3 验收是否接受「井底只有单向门捷径、不放置第二个赐福」；若要求井底也点亮赐福，M3 的「1 赐福」口径需调整 |
| **A11** | **`get_flag` 的 `Variant` 返回值与静态类型** | 3 号签名返回 `Variant`，`default` 可为任意 Variant；1 / 2 号在静态类型 GDScript 里需显式 `bool(...)` / `int(...)` 转换 | 是否改为带类型重载（如 `get_flag_bool`）？3 号建议**不改**（契约 I-1 锁定两个方法），请在契约里补一句「调用方自行 cast」 |
| **A12** | **群聊总线 / 进度台账写入与目录所有权铁律冲突** | `00-接入指令.md` 与 `00-群组通信协议.md` §3 要求各路 AI 在「里程碑交付完成」「回应 TO 含自己 / ALL 的 OPEN 消息」时向根目录 `00-群聊总线.md` 追加消息；但契约 §1、任务书 §0、用户派单均规定「**不写 teamwork 根目录任何文件**」，且接入指令明确「原有任务书与契约约束全部不变」。3 号**未越界写根目录**，消息全文备在下方 §5.1 | 请 HOST / OWNER 代发，或明确授予「仅追加总线、不改其它根目录文件」的豁免后由 3 号补发；同时确认 `00-进度台账.md` §8 的 git 提交 / exe / apk 收尾由主 AI 执行，执行 AI 不碰仓库操作 |
| **A13** | **待裁决项的核对基础** | 按 `00-群组通信协议.md` §3「不扫别人工位」，3 号**未读取 1 / 2 / 4 号的实际产出内容**；A2~A11 是依据契约、派单与总纲得出的**契约层差异**，不是文件实测差异 | 请 HOST 按 `00-进度台账.md` §5 的汇总输入（各工位实际产出 + 本 README 待裁决项）逐项核对后裁决；若需要 3 号做一次跨工位只读比对，请用户明确说「刺探」 |

### 5.1 待代发的总线消息（3 号不写根目录，供 HOST / OWNER 直接追加）

开工只读一次总线，读到 2 条 HOST 通知；其中 `MSG-20261108-2259-HOST`（`TO=ALL`、`STATUS=OPEN`）按协议需回应，且本路 M3 / M4 / M6 交付完成需报一条。以下三条按「只增不改」格式备好，**未写入** `00-群聊总线.md`：

```
## MSG-20261108-2308-Rank-3 · 2026-11-08 23:08 · Rank-3 → HOST
- TYPE: 通知
- REF: MSG-20261108-2259-HOST
- BODY: Rank-3 已接入并读过总线；工位 Rank-3 的 6 份交付件已齐，I-1 与 I-3 定义不变，约束沿用任务书与契约。
- STATUS: OPEN

## MSG-20261108-2309-Rank-3 · 2026-11-08 23:09 · Rank-3 → ALL
- TYPE: 通知
- REF: MSG-20261108-2259-HOST
- BODY: 该编号对 Rank-3 已 CLOSED（原文不改）。
- STATUS: CLOSED

## MSG-20261108-2310-Rank-3 · 2026-11-08 23:10 · Rank-3 → HOST
- TYPE: 交付完成
- REF: M3/M4/M6, I-1/I-2/I-3/I-6, Rank-3/README.md
- BODY: Rank-3（RPG/世界/存档）交付完成：README.md、RPG系统设计.md、存档与flag规范.md、箱庭地牢模板.md、dialogue_and_quest.tres、接口契约.md 共 6 件；12 项待裁决见 README.md §5。
- STATUS: OPEN
```

> 按 `00-进度台账.md` §3「来件登记由用户发文件时追加、不主动填写」，3 号也不写台账；§2 的 6 个实际路径即为交给主 AI 的来件清单。

---

## 6. 完成标准自检

| 任务书 §8 要求 | 结果 |
|---|---|
| `Rank-3\` 下 6 个文件齐全 | ✅ 见 §2 |
| I-1 签名精确可依赖 | ✅ `存档与flag规范.md` §2 + `接口契约.md` §1.1，含禁止清单与内部 / 外部边界 |
| I-3 `SpawnRequest` 字段完整 | ✅ `接口契约.md` §3 共 17 字段，含类型 / 默认 / 取值 / 2 号消费规则 + `.tres` 实例 |
| M0~M6 表可汇总 | ✅ `接口契约.md` §5，7 行、每行含交付物 / 文件 / 依赖 / 验收 |
| 中文 UTF-8、`.tres` 合法 Godot 4 | ✅ `.tres` 为 `format=3`，无注释行、无类型化数组字面量，字段与文档逐字一致 |
| flag 严格三段式 | ✅ 正则 + 24 项登记表 |
| 零外部依赖、无付费 / 云服务项 | ✅ 全部规格走 Godot 4 内置 + 1/2/4 号已有产出 |
| 不写探针 / 测量 / preflight 脚本 | ✅ 本工位无 `.py` / `_probe.gd` / `_preflight` 类文件 |
| 跨模块冲突只记录不越界 | ✅ 全部集中在 §5，未改任何其它文件夹 |
