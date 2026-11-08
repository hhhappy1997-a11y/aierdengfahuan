extends Resource
class_name BossData

## 2 号工位 · 战斗数据表 Resource 类：BossData（Boss 顶层数据表）
## 字段唯一真源：teamwork/Rank-2/数据表schema.md §1；数值实例：boss_01_margit.tres。
## 设计约束：一切战斗数值只写在 .tres 实例里，本文件只声明类型 / 默认值 / 取值范围。
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

@export var id: String = ""                              # 取值 boss_\d{2}_[a-z0-9_]+；全局唯一；I-2 boss_defeated 传此值
@export var display_name: String = ""                    # ≤ 64 字；UI 显示名，不参与逻辑
@export var max_hp: float = 1.0                          # 范围 (0, 1e6]；阶段阈值按此值比例计算
@export var base_attack: float = 0.0                     # 范围 [0, 1e5]；伤害公式 A
@export var base_defense: float = 0.0                    # 范围 [0, 1e5]；Boss 受击防御 D
@export var phases: Array[PhaseData] = []                # 长度 [1, 8]；按 phase_index 升序；阶段唯一真源
@export var phase_thresholds: Array[float] = []          # 每项 (0, 1) 且严格递减；长度 = phases.size() - 1（E-1）
@export var poise: PoiseConfig = null                    # 非空；PhaseData.poise_override 非空时按阶段覆盖
@export var status_buildups: Array[StatusBuildup] = []  # 长度 [0, 3]；status_type 不重复（E-8）
@export var aggro_radius_px: float = 300.0               # 范围 (0, 4096]；进入追击的感知半径
@export var lose_radius_px: float = 450.0                # 范围 (0, 8192]；必须 > aggro_radius_px（E-5 滞回）
@export var chase_speed_px_per_sec: float = 80.0         # 范围 [0, 2048]；追击移动速度
@export var attack_range_px: float = 64.0                # 范围 [0, 2048]；进入出招权重抽取的距离
@export var ai_poll_interval_sec: float = 0.20           # 范围 [0.05, 2.0]；AI 轮询 / 加权抽取间隔
@export var rng_seed: int = 0                            # 范围 [0, 2147483647]；加权抽取随机种子
@export var defeated_flag_key: String = ""               # 三段式 flag；仅经 WorldState.get_flag 读取，写入归 3 号（I-2）
@export var death_pose_name: String = "death"            # 非空；I-4 set_pose() 的 pose 名
@export var phase_transition_enabled: bool = true        # 关闭则退化为单阶段，用于调试
