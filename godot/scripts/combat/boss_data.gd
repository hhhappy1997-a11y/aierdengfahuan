extends Resource
class_name BossData

## ===========================================================================
## 2 号工位 · R3 落工程规格件：BossData（Boss 顶层数据表）
##
## 【R3 定位】按 任务书-R3.md §2 落到本工位 schema\ 子目录，文件名为工程名（去掉 R2
##   平铺规格件的 schema_ 前缀）。等 HOST 汇总时并入工程 data\schemas\；本轮不越界写
##   工程目录。R2 平铺的 schema_boss_data.gd 等规格件一律保留不改、不重做。
## 【字段唯一真源】teamwork/Rank-2/数据表schema.md §1：字段名 / 类型 / 默认值逐字一致。
##   数值实例：boss_01_margit.tres（落工程时指向 res://data/bosses/）。
## 【落工程路径】res://data/schemas/boss_data.gd
##   依据：数据表schema.md §0.1 路径表 + 3 份 .tres 的 ext_resource 均为 res://data/schemas/。
##   【口径差异·待 HOST 裁决】任务书-R3.md §2 字面写 res://data/schema/（单数），与
##   唯一真源 / R2 规格件 / 3 份 .tres 的 res://data/schemas/（复数）不一致。为保证
##   .tres 不悬空、真跑自洽，本轮按复数声明；差异如实登记在 DONE-R3.md，不擅改他人文档。
## 【硬约束】数值全部留在 .tres 实例，本文件只声明 @export 字段 / 类型 / 默认值
##   （改数值不改代码）；逻辑代码仅允许 MIN_DAMAGE=1 类下限常量。
## 引擎：Godot 4 标准版 / GDScript，全静态类型。
## ===========================================================================

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: float = 1.0
@export var base_attack: float = 0.0
@export var base_defense: float = 0.0
@export var phases: Array[PhaseData] = []
@export var phase_thresholds: Array[float] = []
@export var poise: PoiseConfig = null
@export var status_buildups: Array[StatusBuildup] = []
@export var aggro_radius_px: float = 300.0
@export var lose_radius_px: float = 450.0
@export var chase_speed_px_per_sec: float = 80.0
@export var attack_range_px: float = 64.0
@export var ai_poll_interval_sec: float = 0.20
@export var rng_seed: int = 0
@export var defeated_flag_key: String = ""
@export var death_pose_name: String = "death"
@export var phase_transition_enabled: bool = true
