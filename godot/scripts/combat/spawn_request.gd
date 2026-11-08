extends Resource
class_name SpawnRequest

## ===========================================================================
## 2 号工位 · R3 落工程规格件：SpawnRequest（I-3 消费侧字段对照，3 号定义）
##
## 【R3 定位】按 任务书-R3.md §2 落到本工位 schema\ 子目录，文件名为工程名（去掉 R2
##   平铺规格件的 schema_ 前缀）。等 HOST 汇总时并入工程 data\schemas\；本轮不越界写
##   工程目录。R2 平铺的 schema_spawn_request.gd 规格件一律保留不改、不重做。
##
## 【权威定义 · 17 字段】字段集 / 类型 / 默认值 / 取值范围一律以 **Rank-3《接口契约.md》
##   §3 的 17 字段** 为唯一定义（任务书-R3.md §4、R2 口径 §6 第 4 条、用户指令 I-3）。
##   本工位《数据表schema.md》§8 的 10 字段「最小字段假设」按本文件收口，不再主张定义权。
##   3 号实现路径：res://scripts/rpg/spawn_request.gd（同名全局类）。落完整工程时 2 号
##   **不重复挂载本文件**，以免 class_name SpawnRequest 重复注册；本文件只在 2 号独立
##   临时工程内用于字段对齐与真跑核对，并作为 EnemyDirector.spawn_from_request() 读字段的对照规格。
## 【落工程路径】res://data/schemas/spawn_request.gd（2 号对照件；与 3 号实现分离）
##   【口径差异·待 HOST 裁决】任务书-R3.md §2 字面写 res://data/schema/（单数），与
##   数据表schema.md §0.1 / R2 规格件 / 3 份 .tres 的 res://data/schemas/（复数）不一致，
##   本轮按复数声明；差异如实登记在 DONE-R3.md。
## 【2 号消费硬约束】（Rank-3 §3）
##   1. 全部战斗数值只从 2 号自己的数据表取；SpawnRequest 只提供第 7~10 项覆盖位，不改数据表。
##   2. 不得新增 / 删除 / 重命名字段；需要新字段写进 README 待裁决，由主 AI 裁决后 3 号统一加。
##   3. 不得写 combat.* flag 或 SaveDelta；击杀只发 I-2 信号、flag 只由 3 号写、2 号不双写。
##   4. patrol_route 是非类型化 Array（元素 Vector3），不是 Array[Vector3]。
##   5. 数组字段为空时按默认值处理，不抛异常。
## 引擎：Godot 4 标准版 / GDScript，全静态类型。
## ===========================================================================

# 1  请求唯一 id（对账与日志键）
@export var request_id: String = ""
# 2  数据表 id：2 号据此查 EnemyData / BossData 表，查不到则 push_error 不生成
@export var enemy_id: String = ""
# 3  生成挂点（由 1 号场景提供，2 号只按名取位置）
@export var spawn_point_id: String = ""
# 4  生成坐标兜底（spawn_point_id 找不到时使用）
@export var position: Vector3 = Vector3.ZERO
# 5  初始朝向（绕 Y 轴）
@export var facing_degrees: float = 0.0
# 6  敌人等级
@export var level: int = 1
# 7  HP 覆盖位：-1 = 用数据表 HP；>= 0 时覆盖本次生成 HP，不改数据表
@export var hp_override: int = -1
# 8  韧性覆盖位：-1.0 = 用数据表韧性；>= 0.0 时覆盖，不改数据表
@export var stance_override: float = -1.0
# 9  AI 感知半径覆盖位（不改数据表）
@export var aggro_radius: float = 8.0
# 10 脱战回位半径（含滞回）
@export var leash_radius: float = 16.0
# 11 刷新策略：2 号不自行刷新，由 3 号按此字段写 Delta
@export var respawn_policy: String = "on_grace_rest"
# 12 击杀后 3 号要写的 flag：2 号不写此 flag
@export var defeated_flag: String = ""
# 13 掉落表 id
@export var loot_table_id: String = ""
# 14 巡逻点：非类型化 Array（元素 Vector3），空数组 = 原地待机
@export var patrol_route: Array = []
# 15 是否 Boss（血条 / 二阶段）
@export var is_boss: bool = false
# 16 同组敌人共享重置 / 计数
@export var spawn_group_id: String = ""
# 17 非战斗元数据（房间 id / 镜头 / 音频开关）：只读，不得塞战斗数值
@export var metadata: Dictionary = {}
