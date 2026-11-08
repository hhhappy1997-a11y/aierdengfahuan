extends Resource
class_name MoveData

## 2 号工位 · 战斗数据表 Resource 类：MoveData（招式）
## 字段唯一真源：teamwork/Rank-2/数据表schema.md §3；数值实例：boss_01_margit.tres。
## 设计约束：total_frames 不设字段，由 startup + active + recovery 派生（E-2）；
##           判定区间 [startup, startup + active) 左闭右开。
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

@export var id: String = ""                              # 取值 move_\d{2}_[a-z0-9_]+；跨阶段可复用
@export var display_name: String = ""                    # ≤ 64 字；招式名，仅 UI / 日志
@export var pose_name: String = "attack_light"           # 非空；I-4 基础 pose 名，实际传 pose_prefix + pose_name
@export var startup_frames: int = 12                     # 范围 [0, 600]；前摇帧，期间无判定
@export var active_frames: int = 4                       # 范围 [1, 600]；判定帧数，区间 [startup, startup+active)
@export var recovery_frames: int = 18                    # 范围 [0, 600]；后摇帧，期间无判定
@export var motion_multiplier: float = 1.0               # 范围 [0.0, 100.0]；招式倍率 M
@export var damage_type: String = "physical"             # 取值 physical|fire|holy|bleed；供 1 号特效与抗性查表
@export var poise_damage: float = 0.0                    # 范围 [0, 1e5]；命中削韧值
@export var status_buildup_bleed: float = 0.0            # 范围 [0, 1e5]；命中施加的出血积累
@export var status_buildup_poison: float = 0.0           # 范围 [0, 1e5]；同上，中毒
@export var status_buildup_frost: float = 0.0            # 范围 [0, 1e5]；同上，冻伤
@export var hitbox_reach_px: float = 64.0                # 范围 [0, 4096]；判定扇形半径
@export var hitbox_arc_deg: float = 90.0                 # 范围 (0, 360]；判定扇形张角（度）
@export var hitbox_offset_px: Vector2 = Vector2.ZERO     # 各分量 [-4096, 4096]；判定原点相对角色底部中心的偏移
@export var min_range_px: float = 0.0                    # 范围 [0, 4096]；加权抽取可被选中的最小距离
@export var max_range_px: float = 96.0                   # 范围 [min_range_px, 4096]；最大距离（E-4）
@export var weight: float = 1.0                         # 范围 [0, 1000]；加权抽取权重，0 = 禁用
@export var cooldown_sec: float = 0.0                    # 范围 [0, 60]；冷却中权重临时记 0
@export var can_cancel_frames: int = 0                   # 范围 [0, 600]；后摇可取消窗口起点后 N 帧；0 = 不可取消（E-3）
@export var breaks_guard: bool = false                   # 是否无视举盾减伤（M1 未实现盾，预留）
