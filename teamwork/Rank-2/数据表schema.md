# 战斗数据表 Schema v1.0（2 号工位 · 唯一字段真源）

> 适用范围：总纲 3.4「战斗系统：数据驱动」、M1（玩家动作 / 追击敌人）、M5（恶兆妖鬼二阶段）。
> **本文件是字段名、类型、默认值的唯一真源**；`boss_01_margit.tres` 与 `player_state_machine.gd` 中出现的一切资源字段必须与本文件逐字一致。
> 冲突优先级：`00-协作契约.md` > 本工位 `任务书.md` > 本文件。跨模块冲突不在此解决，见 `README.md`「待主 AI 裁决」。
> 引擎：Godot 4 标准版 / GDScript。所有类 `extends Resource`，用 `@export` 暴露字段以便 `.tres` 编辑。

---

## 0. 路径与 id 规范

### 0.1 脚本路径（一律 `res://` 开头，`snake_case`）

| 类名 | `class_name` | 脚本路径 |
|---|---|---|
| BossData | `BossData` | `res://data/schemas/boss_data.gd` |
| PhaseData | `PhaseData` | `res://data/schemas/phase_data.gd` |
| MoveData | `MoveData` | `res://data/schemas/move_data.gd` |
| PoiseConfig | `PoiseConfig` | `res://data/schemas/poise_config.gd` |
| StatusBuildup | `StatusBuildup` | `res://data/schemas/status_buildup.gd` |
| EnemyData | `EnemyData` | `res://data/schemas/enemy_data.gd` |
| PlayerActionData | `PlayerActionData` | `res://data/schemas/player_action_data.gd` |
| SpawnRequest | `SpawnRequest`（**3 号定义**） | `res://data/schemas/spawn_request.gd` |

数据实例路径：`res://data/bosses/`、`res://data/enemies/`、`res://data/player/`。本轮实际交付 `boss_01_margit.tres` 对应 `res://data/bosses/boss_01_margit.tres`。

### 0.2 id 命名规范（契约第 2 节：`<类别>_<序号>_<slug>`）

| 类别 | 前缀 | 示例 | 约束 |
|---|---|---|---|
| Boss | `boss_` | `boss_01_margit` | 两位序号 + 小写 slug，全库唯一 |
| 阶段 | `phase_` | `phase_02_margit_p2` | 同一 Boss 内 `phase_index` 严格递增且不重复 |
| 招式 | `move_` | `move_03_holy_hammer` | 跨阶段可复用同一 id |
| 韧性配置 | `poise_` | `poise_01_margit_base` | — |
| 异常配置 | `status_` | `status_01_bleed` | `status_type` 与 slug 对应 |
| 普通敌人 | `enemy_` | `enemy_01_limgrave_soldier` | — |
| 玩家动作 | `action_` | `action_04_roll` | `state_name` 8 选 1，8 条齐全且不重复 |
| 生成请求 | `spawn_` | `spawn_01_courtyard_guard` | **由 3 号定义，2 号只读** |
| flag key | `<模块>.<对象>.<状态>` | `world.boss_01_margit.defeated` | 2 号**只读**，写入归 3 号（I-2） |

### 0.3 单位与全局口径

| 量 | 单位 | 说明 |
|---|---|---|
| 帧 | 逻辑帧 @ `logic_fps` | 固定物理步长；所有帧区间一律**左闭右开** `[start, end)` |
| 距离 / 半径 | px（2.5D 世界投影像素） | 与 1 号像素→米缩放系数解耦，由 1 号在表现层换算 |
| 时间 | 秒（sec） | 仅用于 AI 轮询、衰减、冷却、过渡时长 |
| 比例 | `[0, 1]` 浮点 | HP 比例、阈值、倍率外的所有 ratio |
| 伤害 | 浮点 HP | 结算末端取整到整数由表现层负责 |

---

## 1. BossData

```gdscript
extends Resource
class_name BossData
@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: float = 1.0
@export var base_attack: float = 0.0
@export var base_defense: float = 0.0
@export var phases: Array[PhaseData] = []
@export var phase_thresholds: Array[float] = []
@export var poise: PoiseConfig = null
@export var status_buildups: Array[StatusBuildup] = []
@export var aggro_radius_px: float = 300.0
@export var lose_radius_px: float = 450.0
@export var chase_speed_px_per_sec: float = 80.0
@export var attack_range_px: float = 64.0
@export var ai_poll_interval_sec: float = 0.20
@export var rng_seed: int = 0
@export var defeated_flag_key: String = ""
@export var death_pose_name: String = "death"
@export var phase_transition_enabled: bool = true
```

| 字段 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `id` | String | `""` | `boss_\d{2}_[a-z0-9_]+` | 全局唯一；I-2 `boss_defeated(boss_id)` 传此值 |
| `display_name` | String | `""` | ≤ 64 字 | UI 显示名，不参与逻辑 |
| `max_hp` | float | `1.0` | `(0, 1e6]` | 阶段阈值按此值的比例计算 |
| `base_attack` | float | `0.0` | `[0, 1e5]` | 伤害公式中的攻击力 A |
| `base_defense` | float | `0.0` | `[0, 1e5]` | Boss 受击时的防御 D |
| `phases` | `Array[PhaseData]` | `[]` | 长度 `[1, 8]` | 按 `phase_index` 升序；**阶段唯一真源** |
| `phase_thresholds` | `Array[float]` | `[]` | 每项 `(0, 1)`，严格递减 | 显式阶段阈值表，长度 `= phases.size() - 1`；需满足下方 E-1 |
| `poise` | PoiseConfig | `null` | 非空 | 默认韧性配置；`PhaseData.poise_override` 非空时按阶段覆盖 |
| `status_buildups` | `Array[StatusBuildup]` | `[]` | 长度 `[0, 3]` | 出血 / 中毒 / 冻伤各至多 1 条，`status_type` 不重复 |
| `aggro_radius_px` | float | `300.0` | `(0, 4096]` | 进入追击的感知半径 |
| `lose_radius_px` | float | `450.0` | `(0, 8192]` | 丢失目标半径；**必须 `> aggro_radius_px`**（滞回，E-5） |
| `chase_speed_px_per_sec` | float | `80.0` | `[0, 2048]` | 追击移动速度 |
| `attack_range_px` | float | `64.0` | `[0, 2048]` | 进入出招权重抽取的距离 |
| `ai_poll_interval_sec` | float | `0.20` | `[0.05, 2.0]` | AI 轮询间隔；加权抽取也在此拍进行 |
| `rng_seed` | int | `0` | `[0, 2147483647]` | 加权抽取随机种子，固定以保证可复现 |
| `defeated_flag_key` | String | `""` | 三段式 flag | **仅经 `WorldState.get_flag(key, default)` 读取**（I-1）；写入由 3 号订阅 I-2 完成，2 号不写 |
| `death_pose_name` | String | `"death"` | 非空 | I-4 `set_pose()` 的 pose 名 |
| `phase_transition_enabled` | bool | `true` | — | 关闭则退化为单阶段，用于调试 |

---

## 2. PhaseData

```gdscript
extends Resource
class_name PhaseData
@export var id: String = ""
@export var phase_index: int = 1
@export var hp_ratio_enter: float = 1.0
@export var hp_ratio_exit: float = 0.0
@export var phase_damage_multiplier: float = 1.0
@export var phase_defense: float = 0.0
@export var sprite_frames_path: String = ""
@export var pose_prefix: String = "p1_"
@export var moves: Array[MoveData] = []
@export var poise_override: PoiseConfig = null
@export var status_resistance_multiplier: float = 1.0
@export var transition_pose_name: String = "phase_transition"
@export var transition_frames: int = 48
@export var transition_invulnerable: bool = true
@export var aggression: float = 1.0
```

| 字段 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `id` | String | `""` | `phase_\d{2}_[a-z0-9_]+` | 全库唯一 |
| `phase_index` | int | `1` | `[1, 8]` | 从 1 连续递增，与 `phases` 下标 +1 相等（E-1） |
| `hp_ratio_enter` | float | `1.0` | `(0, 1]` | 进入本阶段时 HP 比例上界 |
| `hp_ratio_exit` | float | `0.0` | `[0, 1)` | HP 比例**低于**此值转入下一阶段；末阶段为 `0.0` |
| `phase_damage_multiplier` | float | `1.0` | `[0.1, 10.0]` | 伤害公式中的阶段倍率 P |
| `phase_defense` | float | `0.0` | `[0, 1e5]` | **额外**防御（与 `base_defense` 加算），不覆盖 |
| `sprite_frames_path` | String | `""` | `res://...` 或空 | 阶段精灵表路径。总纲 3.4 要求「替换 SpriteFrames」；本轮**仅登记不调用**，实际切阶段动画走 `pose_prefix`（见 `README.md` Q1） |
| `pose_prefix` | String | `"p1_"` | 非空、以 `_` 结尾 | 拼在 `MoveData.pose_name` 前送 `set_pose()`，实现零契约扩展的阶段动画切换 |
| `moves` | `Array[MoveData]` | `[]` | 长度 `[1, 16]` | 本阶段攻击表；阶段切换只换这张表，不换场景 |
| `poise_override` | PoiseConfig | `null` | 可空 | `null` = 用 `BossData.poise`；非空 = 阶段覆盖 |
| `status_resistance_multiplier` | float | `1.0` | `[0.1, 10.0]` | 作用于 `StatusBuildup.threshold` 的乘数（越大越抗异常） |
| `transition_pose_name` | String | `"phase_transition"` | 非空 | `PhaseTransition` 状态播放的 pose |
| `transition_frames` | int | `48` | `[0, 600]` | 过渡总帧数；期间不出招 |
| `transition_invulnerable` | bool | `true` | — | 过渡期是否免伤，避免转阶段被秒 |
| `aggression` | float | `1.0` | `[0.1, 5.0]` | 出招轮询频率倍率：`实际间隔 = ai_poll_interval_sec / aggression` |

---

## 3. MoveData

```gdscript
extends Resource
class_name MoveData
@export var id: String = ""
@export var display_name: String = ""
@export var pose_name: String = "attack_light"
@export var startup_frames: int = 12
@export var active_frames: int = 4
@export var recovery_frames: int = 18
@export var motion_multiplier: float = 1.0
@export var damage_type: String = "physical"
@export var poise_damage: float = 0.0
@export var status_buildup_bleed: float = 0.0
@export var status_buildup_poison: float = 0.0
@export var status_buildup_frost: float = 0.0
@export var hitbox_reach_px: float = 64.0
@export var hitbox_arc_deg: float = 90.0
@export var hitbox_offset_px: Vector2 = Vector2.ZERO
@export var min_range_px: float = 0.0
@export var max_range_px: float = 96.0
@export var weight: float = 1.0
@export var cooldown_sec: float = 0.0
@export var can_cancel_frames: int = 0
@export var breaks_guard: bool = false
```

| 字段 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `id` | String | `""` | `move_\d{2}_[a-z0-9_]+` | 跨阶段可复用 |
| `display_name` | String | `""` | ≤ 64 字 | 招式名，仅 UI / 日志 |
| `pose_name` | String | `"attack_light"` | 非空 | I-4 `set_pose()` 基础 pose 名；实际传 `pose_prefix + pose_name`（见 Q1） |
| `startup_frames` | int | `12` | `[0, 600]` | 前摇（起手）帧数，期间无判定 |
| `active_frames` | int | `4` | `[1, 600]` | **判定帧**帧数；判定区间 `[startup, startup + active)` 左闭右开 |
| `recovery_frames` | int | `18` | `[0, 600]` | 后摇（恢复）帧数，期间无判定 |
| `motion_multiplier` | float | `1.0` | `[0.0, 100.0]` | 招式倍率 M，伤害公式乘数 |
| `damage_type` | String | `"physical"` | `physical\|fire\|holy\|bleed` | 类型标签，供 1 号特效与抗性查表 |
| `poise_damage` | float | `0.0` | `[0, 1e5]` | 命中时对目标造成的削韧值 |
| `status_buildup_bleed` | float | `0.0` | `[0, 1e5]` | 命中时施加的出血积累值 |
| `status_buildup_poison` | float | `0.0` | `[0, 1e5]` | 同上，中毒 |
| `status_buildup_frost` | float | `0.0` | `[0, 1e5]` | 同上，冻伤 |
| `hitbox_reach_px` | float | `64.0` | `[0, 4096]` | 判定扇形半径 |
| `hitbox_arc_deg` | float | `90.0` | `(0, 360]` | 判定扇形张角（度） |
| `hitbox_offset_px` | Vector2 | `Vector2.ZERO` | 各分量 `[-4096, 4096]` | 判定原点相对角色底部中心的偏移 |
| `min_range_px` | float | `0.0` | `[0, 4096]` | 加权抽取时该招式可被选中的最小距离 |
| `max_range_px` | float | `96.0` | `[min_range_px, 4096]` | 可被选中的最大距离（E-4） |
| `weight` | float | `1.0` | `[0, 1000]` | 加权抽取权重；`0` = 禁用该招式 |
| `cooldown_sec` | float | `0.0` | `[0, 60]` | 冷却，冷却中的招式权重临时记 0 |
| `can_cancel_frames` | int | `0` | `[0, 600]` | 后摇可取消窗口起点后 N 帧；`0` = 不可取消（E-3） |
| `breaks_guard` | bool | `false` | — | 是否无视玩家举盾减伤（M1 未实现盾，预留字段） |

> `total_frames` **不设字段**，由 `startup + active + recovery` 派生，避免双源不一致（E-2）。

---

## 4. PoiseConfig

```gdscript
extends Resource
class_name PoiseConfig
@export var id: String = ""
@export var max_poise: float = 100.0
@export var poise_regen_per_sec: float = 8.0
@export var poise_regen_delay_sec: float = 3.0
@export var stance_break_duration_sec: float = 2.5
@export var stance_break_damage_multiplier: float = 1.4
@export var executable: bool = true
@export var execute_hp_ratio_threshold: float = 0.0
@export var poise_break_pose_name: String = "stance_break"
@export var poise_break_frame: int = 0
```

| 字段 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `id` | String | `""` | `poise_\d{2}_[a-z0-9_]+` | — |
| `max_poise` | float | `100.0` | `(0, 1e5]` | 韧性上限；当前韧性归零触发姿态崩坏 |
| `poise_regen_per_sec` | float | `8.0` | `[0, 1e4]` | 韧性回复速率 |
| `poise_regen_delay_sec` | float | `3.0` | `[0, 60]` | 最后一次受击后，延迟多久开始回复 |
| `stance_break_duration_sec` | float | `2.5` | `[0, 30]` | 姿态崩坏硬直时长，即处决窗口 |
| `stance_break_damage_multiplier` | float | `1.4` | `[1.0, 5.0]` | 崩坏窗口内对目标伤害的额外乘数 |
| `executable` | bool | `true` | — | 是否允许处决 |
| `execute_hp_ratio_threshold` | float | `0.0` | `[0, 1]` | 处决附加条件：目标 HP 比例 ≤ 此值时可一击处决；`0.0` = 不启用该条件 |
| `poise_break_pose_name` | String | `"stance_break"` | 非空 | I-4 pose 名 |
| `poise_break_frame` | int | `0` | `[0, 255]` | I-4 锁帧索引 |

**处决触发条件（全部满足）**：`executable == true` 且 `当前韧性 <= 0` 且 `崩坏剩余时长 > 0` 且 `目标 HP 比例 <= execute_hp_ratio_threshold`（阈值 `0.0` 时该条视为恒真）且 `攻击者处于 attack_light / attack_heavy` 的判定帧内且 `距离 <= hitbox_reach_px`。

---

## 5. StatusBuildup（一条 = 一种异常）

```gdscript
extends Resource
class_name StatusBuildup
@export var id: String = ""
@export var status_type: String = "bleed"
@export var threshold: float = 100.0
@export var decay_per_sec: float = 6.0
@export var decay_delay_sec: float = 2.0
@export var trigger_damage_ratio: float = 0.12
@export var trigger_damage_flat: float = 0.0
@export var trigger_poise_damage: float = 0.0
@export var trigger_pose_name: String = "status_bleed"
@export var trigger_frame: int = 0
@export var duration_sec: float = 0.0
@export var tick_damage_per_sec: float = 0.0
@export var resistance_gain_per_trigger: float = 20.0
@export var max_resistance: float = 300.0
```

| 字段 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `id` | String | `""` | `status_\d{2}_[a-z0-9_]+` | — |
| `status_type` | String | `"bleed"` | `bleed\|poison\|frost` | 同一 `BossData.status_buildups` 内不可重复 |
| `threshold` | float | `100.0` | `(0, 1e5]` | 基础触发阈值；实际阈值 `= (threshold + 累计抗性) × PhaseData.status_resistance_multiplier` |
| `decay_per_sec` | float | `6.0` | `[0, 1e4]` | 积累值衰减速率（每秒） |
| `decay_delay_sec` | float | `2.0` | `[0, 60]` | 最后一次积累后延迟多久开始衰减 |
| `trigger_damage_ratio` | float | `0.12` | `[0, 10]` | 触发瞬间按目标 `max_hp` 比例造成的伤害 |
| `trigger_damage_flat` | float | `0.0` | `[0, 1e5]` | 触发瞬间固定伤害 |
| `trigger_poise_damage` | float | `0.0` | `[0, 1e5]` | 触发瞬间额外削韧 |
| `trigger_pose_name` | String | `"status_bleed"` | 非空 | I-4 pose 名 |
| `trigger_frame` | int | `0` | `[0, 255]` | I-4 锁帧索引 |
| `duration_sec` | float | `0.0` | `[0, 300]` | 触发后状态持续时长；`0.0` = 纯瞬发（出血） |
| `tick_damage_per_sec` | float | `0.0` | `[0, 1e4]` | 持续期每秒伤害（中毒）；`duration_sec == 0` 时必须为 `0` |
| `resistance_gain_per_trigger` | float | `20.0` | `[0, 1e4]` | 每触发一次，累计抗性增量（越触发越难） |
| `max_resistance` | float | `300.0` | `[0, 1e5]` | 累计抗性上限，`>= threshold + gain × 8` 建议 |

**结算顺序**：命中 → 按 `MoveData.status_buildup_<type>` 累加 → 重置衰减计时 → 若 `积累值 >= 实际阈值` 则触发（结算伤害 / 削韧 / pose / 抗性增量）→ 积累值归零。触发伤害**不再吃招式倍率与阶段倍率**（避免乘法套娃），直接由 `trigger_damage_ratio × max_hp + trigger_damage_flat` 给出。

---

## 6. EnemyData

```gdscript
extends Resource
class_name EnemyData
@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: float = 180.0
@export var base_attack: float = 55.0
@export var base_defense: float = 12.0
@export var poise: PoiseConfig = null
@export var moves: Array[MoveData] = []
@export var status_buildups: Array[StatusBuildup] = []
@export var aggro_radius_px: float = 260.0
@export var lose_radius_px: float = 380.0
@export var chase_speed_px_per_sec: float = 84.0
@export var attack_range_px: float = 56.0
@export var ai_poll_interval_sec: float = 0.25
@export var rng_seed: int = 0
@export var defeated_flag_key: String = ""
@export var death_pose_name: String = "death"
@export var pose_prefix: String = "enemy_"
```

| 字段 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `id` | String | `""` | `enemy_\d{2}_[a-z0-9_]+` | I-2 `enemy_defeated(enemy_id)` 传此值 |
| `display_name` | String | `""` | ≤ 64 字 | UI 显示名 |
| `max_hp` | float | `180.0` | `(0, 1e6]` | — |
| `base_attack` | float | `55.0` | `[0, 1e5]` | 伤害公式攻击力 A |
| `base_defense` | float | `12.0` | `[0, 1e5]` | 受击防御 D |
| `poise` | PoiseConfig | `null` | 非空 | M1 追击敌人的韧性配置 |
| `moves` | `Array[MoveData]` | `[]` | `[1, 16]` | 攻击表，与 Boss 共用加权抽取器 |
| `status_buildups` | `Array[StatusBuildup]` | `[]` | `[0, 3]` | 可为空（M1 杂兵不带异常） |
| `aggro_radius_px` | float | `260.0` | `(0, 4096]` | 感知半径 |
| `lose_radius_px` | float | `380.0` | `(0, 8192]` | 丢失半径，`> aggro_radius_px`（滞回） |
| `chase_speed_px_per_sec` | float | `84.0` | `[0, 2048]` | 追击速度 |
| `attack_range_px` | float | `56.0` | `[0, 2048]` | 出招距离 |
| `ai_poll_interval_sec` | float | `0.25` | `[0.05, 2.0]` | 轮询间隔 |
| `rng_seed` | int | `0` | `[0, 2147483647]` | 加权抽取种子 |
| `defeated_flag_key` | String | `""` | 三段式 flag | 只读（I-1）；写入归 3 号（I-2） |
| `death_pose_name` | String | `"death"` | 非空 | I-4 pose 名 |
| `pose_prefix` | String | `"enemy_"` | 非空 | 拼在 `MoveData.pose_name` 前 |

---

## 7. PlayerActionData（8 个状态各 1 条，M1 落地）

```gdscript
extends Resource
class_name PlayerActionData
@export var id: String = ""
@export var action_name: String = ""
@export var state_name: String = "idle"
@export var pose_name: String = "idle"
@export var pose_frame_offset: int = 0
@export var startup_frames: int = 0
@export var active_frames: int = 1
@export var recovery_frames: int = 0
@export var invulnerable_start_frame: int = -1
@export var invulnerable_end_frame: int = -1
@export var logic_fps: int = 60
@export var move_speed_px_per_sec: float = 0.0
@export var base_attack: float = 0.0
@export var motion_multiplier: float = 0.0
@export var poise_damage: float = 0.0
@export var damage_type: String = "physical"
@export var hitbox_reach_px: float = 0.0
@export var status_buildup_bleed: float = 0.0
@export var status_buildup_poison: float = 0.0
@export var status_buildup_frost: float = 0.0
@export var state_priority: int = 0
@export var can_cancel_into: Array[String] = []
@export var stamina_cost: float = 0.0
@export var cancel_window_frames: int = 0
```

| 字段 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `id` | String | `""` | `action_\d{2}_[a-z0-9_]+` | — |
| `action_name` | String | `""` | ≤ 64 字 | 与 `state_name` 同名，便于日志 |
| `state_name` | String | `"idle"` | `idle\|walk\|run\|roll\|attack_light\|attack_heavy\|hitstun\|death` | 对应 `PlayerStateMachine.State`，**8 条必须齐全且不重复**（E-6） |
| `pose_name` | String | `"idle"` | 非空 | I-4 `set_pose(pose_name, frame_index)` 的 pose 名，**来自数据表** |
| `pose_frame_offset` | int | `0` | `[0, 255]` | 进入状态时锁定的帧索引基准 |
| `startup_frames` | int | `0` | `[0, 600]` | 起手帧 |
| `active_frames` | int | `1` | `[1, 600]` | 主体段帧数；攻击判定区间 `[startup, startup + active)`；翻滚时此段即无敌段 |
| `recovery_frames` | int | `0` | `[0, 600]` | 恢复帧 |
| `invulnerable_start_frame` | int | `-1` | `[-1, 600]` | 无敌区间左端（**闭**）；`-1` = 无无敌 |
| `invulnerable_end_frame` | int | `-1` | `[-1, 600]` | 无敌区间右端（**开**）；`-1` = 无无敌 |
| `logic_fps` | int | `60` | `[30, 240]` | 帧数换算基准；8 条必须全等（E-6），且须等于 `Engine.physics_ticks_per_second` |
| `move_speed_px_per_sec` | float | `0.0` | `[0, 2048]` | 状态内位移速度（翻滚冲刺 / walk / run） |
| `base_attack` | float | `0.0` | `[0, 1e5]` | 玩家侧伤害公式的攻击力 A（动作自带武器基值）；非攻击状态为 `0`。Boss / 敌人侧 A 取自 `BossData.base_attack` / `EnemyData.base_attack` |
| `motion_multiplier` | float | `0.0` | `[0, 100]` | 玩家招式倍率 M；非攻击状态为 `0` |
| `poise_damage` | float | `0.0` | `[0, 1e5]` | 玩家攻击造成的削韧值 |
| `damage_type` | String | `"physical"` | `physical\|fire\|holy\|bleed` | 类型标签 |
| `hitbox_reach_px` | float | `0.0` | `[0, 4096]` | 玩家攻击判定半径 |
| `status_buildup_bleed` | float | `0.0` | `[0, 1e5]` | 玩家武器附带的异常积累 |
| `status_buildup_poison` | float | `0.0` | `[0, 1e5]` | 同上 |
| `status_buildup_frost` | float | `0.0` | `[0, 1e5]` | 同上 |
| `state_priority` | int | `0` | `[0, 100]` | **状态转移优先级**，数值越大越优先；8 条互不相同（E-6） |
| `can_cancel_into` | `Array[String]` | `[]` | 元素为 `state_name` | 允许从本状态直接转移到的目标状态白名单 |
| `stamina_cost` | float | `0.0` | `[0, 1e4]` | 精力消耗；M1 未启用精力系统，全部填 `0.0` |
| `cancel_window_frames` | int | `0` | `[0, 600]` | 后摇中允许取消的帧数窗口（从 recovery 起点算） |

> **R19 裁决修正 · 翻滚实例口径（cmd-20261109-102334-084-A2 / 总指挥裁决，依据 `00-汇总.md` §5 M1 验收）**：`action_04_roll` 的字段实例值改前 `startup_frames=4 / active_frames=12 / recovery_frames=12 / invulnerable_start_frame=4 / invulnerable_end_frame=16`（`total=28`、无敌 `[4,16)`）→ 改后 **`startup_frames=4 / active_frames=9 / recovery_frames=9 / invulnerable_start_frame=4 / invulnerable_end_frame=13`**（`total=4+9+9=22`、无敌 `[4,13)`，`logic_fps=60`）。本节字段定义 / 类型 / 取值范围不变；`total_frames` 依 E-2 **不设字段**，由 `startup+active+recovery` 派生，故 `total=22` 为派生值而非新增字段。运行权威件 `godot/data/combat/player_actions.tres` 已同步修正。

---

## 8. SpawnRequest（I-3，**3 号定义，2 号只读消费**）

> 本节是 2 号消费侧所需的**最小字段假设**，不是定义权声明。字段最终以 3 号交付为准，见 `README.md` Q3。
> 2 号不读写存档、不碰 `SaveDelta`、不实例化 `Area3D` 触发器（I-1 / I-3）。

```gdscript
extends Resource
class_name SpawnRequest
@export var request_id: String = ""
@export var enemy_data_path: String = ""
@export var enemy_instance_id: String = ""
@export var spawn_position: Vector3 = Vector3.ZERO
@export var spawn_facing_deg: float = 0.0
@export var chunk_id: String = ""
@export var is_boss: bool = false
@export var respawn_on_rest: bool = true
@export var level_offset: int = 0
@export var initial_flags: Dictionary = {}
```

| 字段 | 类型 | 默认值 | 取值范围 | 2 号消费方式 |
|---|---|---|---|---|
| `request_id` | String | `""` | `spawn_\d{2}_[a-z0-9_]+` | 去重键，重复请求直接丢弃 |
| `enemy_data_path` | String | `""` | `res://data/...` | `load()` 得到 `EnemyData` / `BossData` |
| `enemy_instance_id` | String | `""` | 非空 | 实例唯一 id；I-2 `enemy_defeated(enemy_id)` 优先传它 |
| `spawn_position` | Vector3 | `Vector3.ZERO` | — | 3D 地形上的落点（总纲 3.1：地形为 3D 网格） |
| `spawn_facing_deg` | float | `0.0` | `[0, 360)` | 初始朝向，决定判定扇形方向 |
| `chunk_id` | String | `""` | `chunk_<区域>_<x>_<y>` | 交由 1 号做流式加载归属；2 号只透传 |
| `is_boss` | bool | `false` | — | `true` → 走 `PhaseTransition` 分支；`false` → 走普通追击 AI |
| `respawn_on_rest` | bool | `true` | — | Boss / 已击败实体应为 `false`；实际是否复活由 3 号 Delta 决定，2 号不自行复活 |
| `level_offset` | int | `0` | `[-10, 10]` | 等级偏移，作用于 `max_hp` / `base_attack`（M6 用，M1 填 0） |
| `initial_flags` | Dictionary | `{}` | — | 3 号传入的初始 flag 快照；2 号只读，不回写 |

---

## 9. 字段级校验等式（可机器复核，随模块一起落地）

| 编号 | 等式 / 约束 | 违反后果 |
|---|---|---|
| E-1 | `phase_thresholds[i] == phases[i].hp_ratio_exit`，`i ∈ [0, phases.size()-2)`；`phases[i].phase_index == i+1`；`phases[i].hp_ratio_exit == phases[i+1].hp_ratio_enter` | 阶段阈值双源不一致 |
| E-2 | `MoveData.total = startup_frames + active_frames + recovery_frames`；判定区间 `[startup, startup + active)` | 判定帧越界 / 前后摇重叠 |
| E-3 | `can_cancel_frames <= recovery_frames`；`cancel_window_frames <= recovery_frames` | 取消窗口越出动作尾部 |
| E-4 | `min_range_px <= max_range_px`；`attack_range_px <= max(moves[*].max_range_px)` | 存在永远抽不中的招式 |
| E-5 | `lose_radius_px > aggro_radius_px` | 追击在边界抖动（无滞回） |
| E-6 | `PlayerActionData` 共 8 条，`state_name` 集合 = 8 状态全集，`state_priority` 互异，`logic_fps` 全等 | 状态机查表失败 / 优先级并列 |
| E-7 | `total = startup + active + recovery`；`invulnerable_start_frame == startup_frames`；`invulnerable_end_frame == startup_frames + active_frames`；`0 <= start < end <= total`（仅当 `end > start` 且二者 `>= 0` 时启用无敌） | 无敌帧错位，M1 验收失败 |
| E-8 | `BossData.status_buildups` 的 `status_type` 无重复；`threshold + resistance_gain_per_trigger × 8 <= max_resistance` | 抗性溢出 |
| E-9 | 所有 `.tres` 中出现字段名 ⊆ 本文件字段集合；`.tres` 中不出现任何字面数值参与逻辑（数值只能在资源字段内） | 破坏「改数值不改代码」 |

> 这些等式由 M5 的 `combat_data_validator.gd`（2 号模块内，非探针 / 非测量脚本，属运行时资源自检）在 `_ready()` 执行；本轮只交付定义与等式，不额外产出校验脚本文件（契约第 5 节：不写探针 / 测量 / preflight 脚本）。
>
> **R19 裁决 · E-7 校验口径（cmd-20261109-102334-084-A2）**：E-7 等式本身不变；翻滚实例由 `4/12/12=28、inv_end=16` 改为 **`4/9/9=22、inv_end=13`**（依据 `00-汇总.md` §5 M1 验收裁决）。改后 E-7 逐式仍成立：`total=4+9+9=22`；`invulnerable_start_frame == startup_frames`（`4==4`）；`invulnerable_end_frame == startup_frames + active_frames`（`13 == 4+9`）；`0 <= 4 < 13 <= 22`。`godot/scripts/verify_frame_data.gd` 组A 期望值已同步为裁决值并真跑复跑。
