extends Resource
class_name PhaseData

## ===========================================================================
## 2 号工位 · R3 落工程规格件：PhaseData（Boss 阶段）
##
## 【R3 定位】按 任务书-R3.md §2 落到本工位 schema\ 子目录，文件名为工程名（去掉 R2
##   平铺规格件的 schema_ 前缀）。等 HOST 汇总时并入工程 data\schemas\；本轮不越界写
##   工程目录。R2 平铺的 schema_phase_data.gd 等规格件一律保留不改、不重做。
## 【字段唯一真源】teamwork/Rank-2/数据表schema.md §2：字段名 / 类型 / 默认值逐字一致。
##   数值实例：boss_01_margit.tres 的 phase_01 / phase_02 子资源。
## 【落工程路径】res://data/schemas/phase_data.gd
##   依据：数据表schema.md §0.1 路径表 + 3 份 .tres 的 ext_resource 均为 res://data/schemas/。
##   【口径差异·待 HOST 裁决】任务书-R3.md §2 字面写 res://data/schema/（单数），与
##   唯一真源 / R2 规格件 / 3 份 .tres 的 res://data/schemas/（复数）不一致。为保证
##   .tres 不悬空、真跑自洽，本轮按复数声明；差异如实登记在 DONE-R3.md，不擅改他人文档。
## 【硬约束】阶段切换只换资源引用与运行时数值、不换场景；pose_prefix 用 p1_ / p2_ 前缀，
##   实际 pose 名 = pose_prefix + MoveData.pose_name 送 set_pose()（I-4）。
## 引擎：Godot 4 标准版 / GDScript，全静态类型。
## ===========================================================================

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
