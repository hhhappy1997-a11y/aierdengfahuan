extends Resource
class_name PlayerActionData

## 2 号工位 · 战斗数据表 Resource 类：PlayerActionData（玩家 8 个状态各 1 条）
## 字段唯一真源：teamwork/Rank-2/数据表schema.md §7；数值实例：player_actions.tres（数值见《战斗系统设计.md》§1.1）。
## 设计约束：8 条必须齐全且 state_name 不重复、state_priority 互异、logic_fps 全等（E-6）；
##           无敌区间 [invulnerable_start_frame, invulnerable_end_frame) 左闭右开（E-7）。
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

@export var id: String = ""                              # 取值 action_\d{2}_[a-z0-9_]+
@export var action_name: String = ""                     # ≤ 64 字；与 state_name 同名，便于日志
@export var state_name: String = "idle"                  # 取值 idle|walk|run|roll|attack_light|attack_heavy|hitstun|death（E-6）
@export var pose_name: String = "idle"                   # 非空；I-4 set_pose(pose_name, frame_index) 的 pose 名
@export var pose_frame_offset: int = 0                   # 范围 [0, 255]；进入状态时锁定的帧索引基准
@export var startup_frames: int = 0                      # 范围 [0, 600]；起手帧
@export var active_frames: int = 1                       # 范围 [1, 600]；主体段帧数；判定区间 [startup, startup+active)
@export var recovery_frames: int = 0                     # 范围 [0, 600]；恢复帧
@export var invulnerable_start_frame: int = -1           # 范围 [-1, 600]；无敌区间左端（闭）；-1 = 无无敌
@export var invulnerable_end_frame: int = -1             # 范围 [-1, 600]；无敌区间右端（开）；-1 = 无无敌
@export var logic_fps: int = 60                          # 范围 [30, 240]；8 条必须全等（E-6），且等于 Engine.physics_ticks_per_second
@export var move_speed_px_per_sec: float = 0.0           # 范围 [0, 2048]；状态内位移速度（翻滚冲刺 / walk / run）
@export var base_attack: float = 0.0                     # 范围 [0, 1e5]；玩家侧伤害公式攻击力 A；非攻击状态为 0
@export var motion_multiplier: float = 0.0               # 范围 [0, 100]；玩家招式倍率 M；非攻击状态为 0
@export var poise_damage: float = 0.0                    # 范围 [0, 1e5]；玩家攻击造成的削韧值
@export var damage_type: String = "physical"             # 取值 physical|fire|holy|bleed
@export var hitbox_reach_px: float = 0.0                 # 范围 [0, 4096]；玩家攻击判定半径
@export var status_buildup_bleed: float = 0.0            # 范围 [0, 1e5]；玩家武器附带异常积累
@export var status_buildup_poison: float = 0.0           # 范围 [0, 1e5]；同上
@export var status_buildup_frost: float = 0.0            # 范围 [0, 1e5]；同上
@export var state_priority: int = 0                      # 范围 [0, 100]；状态转移优先级，越大越优先；8 条互不相同（E-6）
@export var can_cancel_into: Array[String] = []          # 元素为 state_name；允许直接转移到的目标状态白名单
@export var stamina_cost: float = 0.0                    # 范围 [0, 1e4]；精力消耗；M1 未启用，全部 0.0
@export var cancel_window_frames: int = 0                # 范围 [0, 600]；后摇中允许取消的帧数窗口（从 recovery 起点算）
