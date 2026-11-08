extends Resource
class_name PlayerActionData

## ===========================================================================
## 2 号工位 · R3 落工程规格件：PlayerActionData（玩家 8 个状态各 1 条）
##
## 【R3 定位】按 任务书-R3.md §2 落到本工位 schema\ 子目录，文件名为工程名（去掉 R2
##   平铺规格件的 schema_ 前缀）。等 HOST 汇总时并入工程 data\schemas\；本轮不越界写
##   工程目录。R2 平铺的 schema_player_action_data.gd 等规格件一律保留不改、不重做。
## 【字段唯一真源】teamwork/Rank-2/数据表schema.md §7：字段名 / 类型 / 默认值逐字一致。
##   数值实例：player_actions.tres 的 8 条子资源（落工程时指向 res://data/player/）。
## 【落工程路径】res://data/schemas/player_action_data.gd
##   依据：数据表schema.md §0.1 路径表 + 3 份 .tres 的 ext_resource 均为 res://data/schemas/。
##   【口径差异·待 HOST 裁决】任务书-R3.md §2 字面写 res://data/schema/（单数），与
##   唯一真源 / R2 规格件 / 3 份 .tres 的 res://data/schemas/（复数）不一致。为保证
##   .tres 不悬空、真跑自洽，本轮按复数声明；差异如实登记在 DONE-R3.md，不擅改他人文档。
## 【硬约束】E-6：8 条齐全 / state_name 不重复 / state_priority 互异 / logic_fps 全等；
##   E-7：无敌区间 [invulnerable_start_frame, invulnerable_end_frame) 左闭右开；数值全部
##   留在 .tres 实例。
## 引擎：Godot 4 标准版 / GDScript，全静态类型。
## ===========================================================================

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
