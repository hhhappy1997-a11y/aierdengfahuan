extends Resource
class_name PoiseConfig

## 2 号工位 · 战斗数据表 Resource 类：PoiseConfig（韧性 / 姿态崩坏 / 处决）
## 字段唯一真源：teamwork/Rank-2/数据表schema.md §4；数值实例：boss_01_margit.tres。
## 处决触发（全部满足）：executable 且 当前韧性<=0 且 崩坏窗口>0 且 HP 比例<=阈值
##   且 攻击者处于轻/重击判定帧内 且 距离<=hitbox_reach_px 且 register_hit 通过。
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

@export var id: String = ""                              # 取值 poise_\d{2}_[a-z0-9_]+
@export var max_poise: float = 100.0                     # 范围 (0, 1e5]；韧性上限，归零触发姿态崩坏
@export var poise_regen_per_sec: float = 8.0             # 范围 [0, 1e4]；韧性回复速率
@export var poise_regen_delay_sec: float = 3.0           # 范围 [0, 60]；最后受击后延迟多久开始回复
@export var stance_break_duration_sec: float = 2.5       # 范围 [0, 30]；姿态崩坏硬直时长，即处决窗口
@export var stance_break_damage_multiplier: float = 1.4  # 范围 [1.0, 5.0]；崩坏窗口内伤害额外乘数 S
@export var executable: bool = true                      # 是否允许处决
@export var execute_hp_ratio_threshold: float = 0.0      # 范围 [0, 1]；HP 比例<=此值可一击处决；0.0 = 不启用
@export var poise_break_pose_name: String = "stance_break"  # 非空；I-4 pose 名
@export var poise_break_frame: int = 0                   # 范围 [0, 255]；I-4 锁帧索引
