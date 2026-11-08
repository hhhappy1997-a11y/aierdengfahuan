extends Resource
class_name PoiseConfig

## ===========================================================================
## 2 号工位 · R3 落工程规格件：PoiseConfig（韧性 / 姿态崩坏 / 处决）
##
## 【R3 定位】按 任务书-R3.md §2 落到本工位 schema\ 子目录，文件名为工程名（去掉 R2
##   平铺规格件的 schema_ 前缀）。等 HOST 汇总时并入工程 data\schemas\；本轮不越界写
##   工程目录。R2 平铺的 schema_poise_config.gd 等规格件一律保留不改、不重做。
## 【字段唯一真源】teamwork/Rank-2/数据表schema.md §4：字段名 / 类型 / 默认值逐字一致。
##   数值实例：boss_01_margit.tres、enemy_01_limgrave_soldier.tres 的 poise 子资源。
## 【落工程路径】res://data/schemas/poise_config.gd
##   依据：数据表schema.md §0.1 路径表 + 3 份 .tres 的 ext_resource 均为 res://data/schemas/。
##   【口径差异·待 HOST 裁决】任务书-R3.md §2 字面写 res://data/schema/（单数），与
##   唯一真源 / R2 规格件 / 3 份 .tres 的 res://data/schemas/（复数）不一致。为保证
##   .tres 不悬空、真跑自洽，本轮按复数声明；差异如实登记在 DONE-R3.md，不擅改他人文档。
## 【硬约束】处决触发条件（数据表schema.md §4）全部满足才生效；数值全部留在 .tres 实例。
## 引擎：Godot 4 标准版 / GDScript，全静态类型。
## ===========================================================================

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
