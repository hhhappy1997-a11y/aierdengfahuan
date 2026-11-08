extends Resource
class_name StatusBuildup

## ===========================================================================
## 2 号工位 · R3 落工程规格件：StatusBuildup（一条 = 一种异常：出血 / 中毒 / 冻伤）
##
## 【R3 定位】按 任务书-R3.md §2 落到本工位 schema\ 子目录，文件名为工程名（去掉 R2
##   平铺规格件的 schema_ 前缀）。等 HOST 汇总时并入工程 data\schemas\；本轮不越界写
##   工程目录。R2 平铺的 schema_status_buildup.gd 等规格件一律保留不改、不重做。
## 【字段唯一真源】teamwork/Rank-2/数据表schema.md §5：字段名 / 类型 / 默认值逐字一致。
##   数值实例：boss_01_margit.tres 的 bleed / poison / frost 三个子资源。
## 【落工程路径】res://data/schemas/status_buildup.gd
##   依据：数据表schema.md §0.1 路径表 + 3 份 .tres 的 ext_resource 均为 res://data/schemas/。
##   【口径差异·待 HOST 裁决】任务书-R3.md §2 字面写 res://data/schema/（单数），与
##   唯一真源 / R2 规格件 / 3 份 .tres 的 res://data/schemas/（复数）不一致。为保证
##   .tres 不悬空、真跑自洽，本轮按复数声明；差异如实登记在 DONE-R3.md，不擅改他人文档。
## 【硬约束】结算顺序、触发伤害不吃招式/阶段倍率（数据表schema.md §5）；数值全部留在
##   .tres 实例；E-8 要求 threshold + resistance_gain_per_trigger × 8 <= max_resistance。
## 引擎：Godot 4 标准版 / GDScript，全静态类型。
## ===========================================================================

@export var id: String = ""
@export var status_type: String = "bleed"
@export var threshold: float = 100.0
@export var decay_per_sec: float = 6.0
@export var decay_delay_sec: float = 2.0
@export var trigger_damage_ratio: float = 0.12
@export var trigger_damage_flat: float = 0.0
@export var trigger_poise_damage: float = 0.0
@export var trigger_pose_name: String = "status_bleed"
@export var trigger_frame: int = 0
@export var duration_sec: float = 0.0
@export var tick_damage_per_sec: float = 0.0
@export var resistance_gain_per_trigger: float = 20.0
@export var max_resistance: float = 300.0
