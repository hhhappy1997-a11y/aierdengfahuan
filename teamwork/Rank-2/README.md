# 2 号工位 README —— 战斗系统与数据驱动

> 5-AI 协作执行 AI #2 的交付说明。输入源：本目录 `任务书.md` + 根目录 `00-项目总纲.md` + `00-协作契约.md`（只读）。
> 唯一写入目录：`F:\Game\aierdengfahuan\teamwork\Rank-2\`（见「待主 AI 裁决」Q6）。
> 所有文件中文 UTF-8；零外部依赖；未写任何探针 / 测量 / preflight 脚本。

---

## 1. 模块目标

把总纲 **3.4 战斗系统：数据驱动** 落成「**改数据表数值不改代码**」的可复核规格与可拷贝落地件：

- Boss 的削韧、异常积累、阶段阈值、招式倍率、判定帧、AI 半径全部存成 Godot 4 `Resource` 数据表，运行时查表结算；
- Boss 多阶段 = 状态机 `PhaseTransition` + 切换攻击表 / 数值 / 阶段姿态，**不换整个场景**；
- 支撑 **M1**（移动 / 翻滚 / 轻攻击 + 追击敌人，翻滚无敌帧可复核）与 **M5**（恶兆妖鬼二阶段 + 3 个核心招式）；
- 跨模块只走契约 I-1 / I-2 / I-3 / I-4 / I-6，不私改接口、不碰别人文件。

---

## 2. 交付清单（任务书 §3 的 6 个固定文件，全部齐全）

| # | 文件 | 内容 | 状态 |
|---|---|---|---|
| 1 | `README.md` | 本文件：模块目标 / 交付清单 / 接口摘要 / 未完成项 / 待主 AI 裁决 | ✅ |
| 2 | `战斗系统设计.md` | 任务书 §4 全部 7 个要点：8 状态状态机与优先级、翻滚无敌帧等式、韧性 / 处决 / 三种异常、伤害公式与禁止硬编码清单、追击 AI 滞回与加权抽取、不换场景的 `PhaseTransition` 状态图、改数值不改代码保障机制 | ✅ |
| 3 | `数据表schema.md` | **8 类 Resource / 129 处字段定义（94 个唯一字段名，多类复用同名）**，每字段给类型、默认值、取值范围、说明、id 命名规范、`res://data/...` 脚本路径；含 E-1~E-9 共 9 条校验等式 | ✅ |
| 4 | `boss_01_margit.tres` | 合法 Godot 4 文本资源：2 阶段 + 阈值 0.5 + 3 核心招式 + 2 套韧性配置 + 3 种异常配置；`load_steps=16` = 5 `ext_resource` + 10 `sub_resource` + 1 | ✅ |
| 5 | `player_state_machine.gd` | 合法 GDScript 骨架：8 状态枚举、enter/exit、优先级转移、左闭右开无敌帧判定、I-4 `set_pose()`、I-2 信号、I-1 只走 `WorldState`；**零战斗数值字面量**（唯一常量 `MIN_DAMAGE = 1.0`） | ✅ |
| 6 | `接口契约.md` | I-1/I-2/I-3/I-4/I-6 对齐、对外信号 9 个 / 方法 11 个 / 资源字段清单、对 1 号与 3 号的依赖、**M0~M6 分阶段交付表** | ✅ |

**可核实的量**：8 类 Resource、129 字段、9 条校验等式、8 个玩家状态（8 条 `PlayerActionData` 具体数值见设计文档 §1.1）、Boss 2 阶段 / 3 招式 / 3 异常 / 2 韧性配置、M0~M6 共 7 行交付表、待裁决 7 项。

### 2.1 本轮完成标准自检（任务书 §7）

| 完成标准 | 结果 |
|---|---|
| `2\` 下 6 个文件齐全 | ✅ 全部产出在 `Rank-2\`（Q6 说明路径差异），未写其它任何目录 |
| schema 与 `.tres` 字段一致 | ✅ 静态核对 **PASS**：`.tres` 内 74 个字段键（73 个业务字段 + 1 个 Godot 内建 `script`）全部命中 schema 的 94 个唯一字段名，越界字段名 **0**；每个 sub_resource 与 `[resource]` 的字段均按 schema 逐字写出 |
| `.gd` 数值全部查表 | ✅ 静态核对 **PASS**：帧数、速度、倍率、优先级、pose 名、无敌区间端点一律读 `PlayerActionData`；代码内数字字面量集合仅 `{0, 0.0, 1, 1.0, 2, 3, 6, 7}`（`MIN_DAMAGE=1.0`、帧计数起点/步长、签名参数个数、节点名与错误信息中的编号），命中本案战斗数值 **0 项** |
| M0~M6 表可汇总 | ✅ `接口契约.md` §6，每行给交付物 / 依赖接口 / 验收口径 / 状态，可直接并入主 AI 排期 |

---

## 3. 对外接口摘要

| 编号 | 方向 | 2 号提供 / 消费 | 关键内容 |
|---|---|---|---|
| I-1 | 3 → 2 | 消费 | `WorldState.get_flag(key[, default])` 只读；`set_flag` 仅用于运行时战斗态缓存，**禁止写 `.defeated` flag**（代码内硬拦截） |
| I-2 | 2 → 3 | **提供** | `enemy_defeated(enemy_id)` / `boss_defeated(boss_id)`，全模块唯一发射点 `PlayerStateMachine.report_defeat()`；3 号订阅写 Delta |
| I-3 | 3 → 2 | 消费 | `SpawnRequest`（字段以 3 号定义为准），`EnemyDirector.spawn_from_request()` 消费；`chunk_id` 透传给 1 号，2 号不管理 chunk |
| I-4 | 1 → 2 | 消费 | **只**调 `set_pose(pose_name, frame_index)`；pose 名全部来自数据表；不写 billboard / 锚定 / 缩放 / SpriteFrames 赋值 |
| I-6 | 2 → 主 AI | **提供** | `接口契约.md` §6 的 M0~M6 交付表 |

另有 7 个模块内信号（`state_changed` / `invulnerability_changed` / `damage_dealt` / `poise_damage_dealt` / `status_buildup_applied` / `stance_broken` / `death_confirmed`）供 1 号与 UI 可选订阅，详见 `接口契约.md` §2.1。

### 3.1 主 AI 汇总时需读的实际文件路径

```
F:\Game\aierdengfahuan\teamwork\Rank-2\README.md
F:\Game\aierdengfahuan\teamwork\Rank-2\战斗系统设计.md
F:\Game\aierdengfahuan\teamwork\Rank-2\数据表schema.md
F:\Game\aierdengfahuan\teamwork\Rank-2\boss_01_margit.tres
F:\Game\aierdengfahuan\teamwork\Rank-2\player_state_machine.gd
F:\Game\aierdengfahuan\teamwork\Rank-2\接口契约.md
```

（目录内另有只读的 `任务书.md`，不计入交付。）

> 按契约第 1 节，2 号**不写 teamwork 根目录**（含任何总线 / 导航 / 汇总文件）。若协作机制要求通报交付，请由 HOST / 主 AI 代发，本 §3.1 路径列表与 §2.1 自检表即为通报内容源。git 收尾（commit + push）交主 AI，2 号不自行提交。

---

## 4. 未完成项（诚实标注，不冒充已完成）

| 项 | 归属 | 说明 |
|---|---|---|
| 8 个 `res://data/schemas/*.gd` Resource 类脚本 | M0 工程落地 | 本轮只交付字段定义与路径规范；脚本未写入工程（工程根 `F:\Game\aierdengfahuan\` 尚未建立） |
| `res://data/player/player_actions.tres`（8 条动作实例） | M1 | 具体数值已在 `战斗系统设计.md` §1.1 给全，可按 schema 直接生成，无需再设计 |
| `enemy_director.gd` / `combat_resolver.gd` / `boss_controller.gd` / `combat_data_validator.gd` | M1 / M5 | 本轮交付骨架 `player_state_machine.gd` + 完整设计，实体控制器待工程落地 |
| `EnemyData` 实例 `.tres`（M1 追击敌 1 个、M3 精英 1 个） | M1 / M3 | schema 已定义，默认数值已给出 |
| Godot 4 工程内实跑验证 | M1 / M5 | 当前只有 teamwork 文本工位、无 Godot 工程，且本机未检出 `godot` / `godot4` 命令行；`.tres` / `.gd` 按 Godot 4 语法书写，**只完成静态字段一致性核对，尚未在引擎中解析 / 导入 / 运行**，不标「已运行通过」 |
| Q1 裁决后的阶段精灵替换入口 | M5 | 需 1 号 / 主 AI 决定，见下 |

---

## 5. 待主 AI 裁决（只在此登记，不改契约、不改别人文件）

| 编号 | 涉及 | 问题 | 2 号当前做法 | 请主 AI 裁决 |
|---|---|---|---|---|
| **Q1** | 总纲 3.4 vs 契约 I-4 | 总纲要求「Boss 阶段**替换 `SpriteFrames` 资源**」，但 I-4 只约定 `set_pose(pose_name, frame_index)` 一个方法，没有精灵表替换入口 | `PhaseData.sprite_frames_path` 仅登记两阶段路径、**不调用**；实际用 `pose_prefix`（`p1_` / `p2_`）让 1 号在同一套 `SpriteFrames` 预置两组 pose，`set_pose("p2_holy_hammer", f)` 即切阶段动画 —— **零接口扩展、改数据表不改代码** | 选 A：维持 `pose_prefix` 方案，不改契约（推荐）；选 B：扩展 I-4，由 1 号新增 `set_sprite_frames(frames)` / `set_pose_set(id)` 入口，2 号再接 `sprite_frames_path`。**在裁决前 2 号不会私加调用** |
| **Q2** | I-1 | 契约写 `WorldState.get_flag(key)`（单参），任务书 §5 写 `get_flag(key, default)`（双参） | `_resolve_world_flag_signature()` 在 `_ready()` 读方法参数个数，用 `callv` 兼容两种口径，不私改接口 | 以哪个签名为准？确定后 2 号删掉兼容分支 |
| **Q3** | I-1 / I-3 | `WorldState` 的 Autoload 节点名、`SpawnRequest` 的**最终字段表**与脚本路径未由 3 号发布 | `world_state_path` 用 `@export NodePath` 可配（`^"/root/WorldState"` 为默认假设）；`数据表schema.md` §8 是 2 号消费侧**最小字段假设**，明确不主张定义权 | 请 3 号发布最终字段表；2 号按 Q3 结果改 schema §8 与 `EnemyDirector` |
| **Q4** | I-4 | `set_pose()` 第二参数 `frame_index` 是「动作内帧索引」还是「SpriteFrames 全局帧索引」？由谁 clamp 到实际帧数？ | 按「动作内帧索引、`pose_frame_offset + state_frame` 从 0 递增」实现，clamp 交给 1 号 | 明确语义与 clamp 责任；若 1 号要求全局帧，2 号改 `_apply_pose()` 一处 |
| **Q5** | I-5（间接） | 4 号 `import.json` 的动作名与 2 号数据表 `pose_name` 的映射关系 | pose 名以数据表为准：`idle/walk/run/roll/attack_light/attack_heavy/hitstun/death`，Boss 招式 `dagger_slash/staff_slam/holy_hammer`，加 `p1_`/`p2_` 前缀 | 请 4 号 / 1 号按此清单对齐动作名，或给出映射表 |
| **Q6** | 目录所有权 | 任务书 §0 与契约第 1 节写唯一可写目录 `teamwork\2\`，但实际工位目录是 `teamwork\Rank-2\`；用户本轮明确指定「只负责 `Rank-2` 文件夹」 | 严格按用户指令只写 `Rank-2\`，未创建 `2\`、未改根目录与其它工位任何文件 | 请主 AI 在 `00-汇总.md` 统一工位路径口径；若需迁到 `2\`，由主 AI 决定，2 号不自行搬动 |
| **Q7** | I-2 | 3 号是否需要 2 号在发击败信号前做本地幂等缓存（防 chunk 重载重复发） | 当前不缓存：HP<=0 单次判定 + `register_hit` 去重 + M2 的 `request_id` 去重共同保证 | 请 3 号确认 `enemy_defeated` / `boss_defeated` 是否需幂等；需要则 2 号在 `report_defeat()` 加去重 |

> 跨模块冲突一律只登记在此，未修改 `00-项目总纲.md`、`00-协作契约.md`、`README.md`（根目录）或 1/3/4 号工位的任何文件。

---

## 6. 可做的更新方向或增量内容（按价值排序，全部零外部依赖、不引入付费素材 / 外部生成服务）

1. **补 8 个 `res://data/schemas/*.gd` Resource 类脚本 + `player_actions.tres`**：把本轮 schema 与 8 条动作数值变成工程内可直接 `@export` 挂载的资源，M1 立刻可跑；这是解锁后续所有实跑验证的前提。
2. **落地 M1 实体三件套**：`enemy_director.gd`（含 I-3 `spawn_from_request` + 滞回追击 + 加权抽取）、`combat_resolver.gd`（伤害 / 削韧 / 异常结算）、`enemy_01_limgrave_soldier.tres`；随后在 Godot 里按设计文档 §2.3 实测翻滚 `[4,16)` 无敌窗口。
3. **落地 M5 `boss_controller.gd` + `PhaseTransition`**：接 `boss_01_margit.tres`，跑通「HP 1750 触发 → 换攻击表 / 韧性 / pose 前缀 → 48 帧过渡 → 不换场景」，并执行 §7.4 的「改 `2.1→3.0`，伤害 `315→450`」验收。
4. **补 `combat_data_validator.gd`**：在 `_ready()` 跑 E-1/E-3/E-4/E-5/E-8/E-9，把「数据表自洽」变成编辑器启动即报的事实（E-6/E-7 已在 `player_state_machine.gd` 实现）。
5. **等 Q1~Q5 裁决后做一次接口收口**：删掉签名兼容分支、确认 `frame_index` 语义、对齐 pose 名映射，把 7 项待裁决收敛为 0。
6. **补 M3 精英 / M6 批量数据表实例**：按 schema 复制 `EnemyData` / `BossData` 实例，接 `level_offset`，仍不改任何代码。
7. **HD-2D 表现联动（与 1 号协作）**：`stance_broken` / `status_*` / `phase_transition` 的 pose 与体积光、光尘、湿地倒影、bloom 的触发时机表；2 号只出信号与帧号，表现归 1 号。

---

## 7. 本轮产出 / 未完成 / 建议下一步（三段式小结）

- **本轮产出**：6 个固定文件齐全；8 类 / 129 字段的 Resource 规格；一份字段逐字一致的 Godot 4 `.tres`（2 阶段 / 3 招 / 2 韧性 / 3 异常）；一份零战斗数值硬编码的 GDScript 骨架；9 条校验等式与全部可复算的伤害 / 韧性 / 异常 / 无敌帧极值；M0~M6 交付表；7 项待裁决。
- **未完成**：工程内 8 个 schema 脚本、动作实例 `.tres`、M1/M5 实体控制器、Godot 编辑器实跑验证；均已在 §4 标注，不冒充完成。
- **建议下一步**：主 AI 先裁决 Q1（阶段精灵替换）与 Q6（工位路径口径），随后按 §6 第 1 项补 schema 脚本与 `player_actions.tres`，即可进入 M1 实跑。
