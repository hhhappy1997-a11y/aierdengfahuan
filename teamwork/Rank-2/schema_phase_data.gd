extends Resource
class_name PhaseData

## 2 号工位 · 战斗数据表 Resource 类：PhaseData（Boss 阶段）
## 字段唯一真源：teamwork/Rank-2/数据表schema.md §2；数值实例：boss_01_margit.tres。
## 设计约束：阶段切换只换资源引用与运行时数值，不换场景（总纲 3.4）。
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

@export var id: String = ""                              # 取值 phase_\d{2}_[a-z0-9_]+；全库唯一
@export var phase_index: int = 1                         # 范围 [1, 8]；从 1 连续递增，与 phases 下标 +1 相等（E-1）
@export var hp_ratio_enter: float = 1.0                  # 范围 (0, 1]；进入本阶段时 HP 比例上界
@export var hp_ratio_exit: float = 0.0                   # 范围 [0, 1)；低于此值转下一阶段，末阶段为 0.0
@export var phase_damage_multiplier: float = 1.0         # 范围 [0.1, 10.0]；伤害公式阶段倍率 P
@export var phase_defense: float = 0.0                   # 范围 [0, 1e5]；额外防御，与 base_defense 加算
@export var sprite_frames_path: String = ""              # res://... 或空；本轮仅登记不调用（见 README Q1）
@export var pose_prefix: String = "p1_"                  # 非空且以 _ 结尾；拼在 MoveData.pose_name 前送 set_pose()（p1_ / p2_）
@export var moves: Array[MoveData] = []                  # 长度 [1, 16]；本阶段攻击表，切阶段只换这张表
@export var poise_override: PoiseConfig = null           # 可空；null = 用 BossData.poise，非空 = 阶段覆盖
@export var status_resistance_multiplier: float = 1.0    # 范围 [0.1, 10.0]；作用于 StatusBuildup.threshold
@export var transition_pose_name: String = "phase_transition"  # 非空；PhaseTransition 状态播放的 pose
@export var transition_frames: int = 48                  # 范围 [0, 600]；过渡总帧数，期间不出招
@export var transition_invulnerable: bool = true         # 过渡期是否免伤
@export var aggression: float = 1.0                      # 范围 [0.1, 5.0]；实际间隔 = ai_poll_interval_sec / aggression
