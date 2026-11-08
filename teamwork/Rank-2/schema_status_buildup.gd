extends Resource
class_name StatusBuildup

## 2 号工位 · 战斗数据表 Resource 类：StatusBuildup（一条 = 一种异常：出血 / 中毒 / 冻伤）
## 字段唯一真源：teamwork/Rank-2/数据表schema.md §5；数值实例：boss_01_margit.tres。
## 结算顺序：命中 → 按 MoveData.status_buildup_<type> 累加 → 重置衰减计时 →
##   积累值 >= (threshold + 累计抗性) × PhaseData.status_resistance_multiplier 则触发 → 积累值归零。
## 触发伤害不吃招式倍率与阶段倍率，直接由 trigger_damage_ratio × max_hp + trigger_damage_flat 给出。
## 引擎：Godot 4 标准版 / GDScript，全静态类型。
##
## ---------------------------------------------------------------------------
## res://data/schemas/*.gd 落工程对照表（本目录 schema_*.gd 为工位内规格件）
##   schema_boss_data.gd          -> res://data/schemas/boss_data.gd           class_name BossData
##   schema_phase_data.gd         -> res://data/schemas/phase_data.gd          class_name PhaseData
##   schema_move_data.gd          -> res://data/schemas/move_data.gd           class_name MoveData
##   schema_poise_config.gd       -> res://data/schemas/poise_config.gd        class_name PoiseConfig
##   schema_status_buildup.gd     -> res://data/schemas/status_buildup.gd      class_name StatusBuildup
##   schema_enemy_data.gd         -> res://data/schemas/enemy_data.gd          class_name EnemyData
##   schema_player_action_data.gd -> res://data/schemas/player_action_data.gd  class_name PlayerActionData
##   schema_spawn_request.gd      -> res://data/schemas/spawn_request.gd       class_name SpawnRequest（字段以 3 号《接口契约.md》§3 的 17 字段为准）
## ---------------------------------------------------------------------------

@export var id: String = ""                              # 取值 status_\d{2}_[a-z0-9_]+
@export var status_type: String = "bleed"                # 取值 bleed|poison|frost；同一 BossData.status_buildups 内不可重复（E-8）
@export var threshold: float = 100.0                     # 范围 (0, 1e5]；基础触发阈值
@export var decay_per_sec: float = 6.0                   # 范围 [0, 1e4]；积累值衰减速率（每秒）
@export var decay_delay_sec: float = 2.0                 # 范围 [0, 60]；最后积累后延迟多久开始衰减
@export var trigger_damage_ratio: float = 0.12           # 范围 [0, 10]；触发瞬间按 max_hp 比例的伤害
@export var trigger_damage_flat: float = 0.0             # 范围 [0, 1e5]；触发瞬间固定伤害
@export var trigger_poise_damage: float = 0.0            # 范围 [0, 1e5]；触发瞬间额外削韧
@export var trigger_pose_name: String = "status_bleed"   # 非空；I-4 pose 名
@export var trigger_frame: int = 0                       # 范围 [0, 255]；I-4 锁帧索引
@export var duration_sec: float = 0.0                    # 范围 [0, 300]；触发后持续时长；0.0 = 纯瞬发
@export var tick_damage_per_sec: float = 0.0             # 范围 [0, 1e4]；持续期每秒伤害；duration_sec==0 时必须为 0
@export var resistance_gain_per_trigger: float = 20.0    # 范围 [0, 1e4]；每触发一次累计抗性增量
@export var max_resistance: float = 300.0                # 范围 [0, 1e5]；累计抗性上限（E-8）
