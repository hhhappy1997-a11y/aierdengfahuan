extends Resource
class_name EnemyData

## 2 号工位 · 战斗数据表 Resource 类：EnemyData（普通 / 精英敌人）
## 字段唯一真源：teamwork/Rank-2/数据表schema.md §6；数值实例：enemy_01_limgrave_soldier.tres。
## 设计约束：与 Boss 共用加权抽取器；M1 杂兵不带异常时 status_buildups 留空数组。
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

@export var id: String = ""                              # 取值 enemy_\d{2}_[a-z0-9_]+；I-2 enemy_defeated 传此值
@export var display_name: String = ""                    # ≤ 64 字；UI 显示名
@export var max_hp: float = 180.0                        # 范围 (0, 1e6]
@export var base_attack: float = 55.0                    # 范围 [0, 1e5]；伤害公式攻击力 A
@export var base_defense: float = 12.0                   # 范围 [0, 1e5]；受击防御 D
@export var poise: PoiseConfig = null                    # 非空；韧性配置
@export var moves: Array[MoveData] = []                  # 长度 [1, 16]；攻击表，与 Boss 共用加权抽取器
@export var status_buildups: Array[StatusBuildup] = []  # 长度 [0, 3]；可为空（M1 杂兵不带异常）
@export var aggro_radius_px: float = 260.0               # 范围 (0, 4096]；感知半径
@export var lose_radius_px: float = 380.0                # 范围 (0, 8192]；丢失半径，> aggro_radius_px（E-5）
@export var chase_speed_px_per_sec: float = 84.0         # 范围 [0, 2048]；追击速度
@export var attack_range_px: float = 56.0                # 范围 [0, 2048]；出招距离
@export var ai_poll_interval_sec: float = 0.25           # 范围 [0.05, 2.0]；轮询间隔
@export var rng_seed: int = 0                            # 范围 [0, 2147483647]；加权抽取种子
@export var defeated_flag_key: String = ""               # 三段式 flag；只读（I-1），写入归 3 号（I-2）
@export var death_pose_name: String = "death"            # 非空；I-4 pose 名
@export var pose_prefix: String = "enemy_"               # 非空；拼在 MoveData.pose_name 前
