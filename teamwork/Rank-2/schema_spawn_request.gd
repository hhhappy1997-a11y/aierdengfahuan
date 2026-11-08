extends Resource
class_name SpawnRequest

## 2 号工位 · I-3 消费侧字段对照规格：SpawnRequest
##
## 【权威定义】字段集、类型、默认值、取值范围一律以 **3 号《接口契约.md》§3 的 17 字段**为唯一定义
##   （R2 任务书 §3 口径 4 / 00-续派与监测规则.md §6 第 4 条）。R1 本工位《数据表schema.md》§8
##   的 10 字段「最小字段假设」按本文件收口，不再主张定义权。
## 【3 号实现路径】res://scripts/rpg/spawn_request.gd（class_name SpawnRequest extends Resource）。
## 【集成注意】3 号已提供同名全局类实现；落完整工程时 2 号**不重复挂载本文件**，以免
##   class_name SpawnRequest 重复注册。本文件只在 2 号独立临时工程内用于字段对齐与真跑核对，
##   并作为 EnemyDirector.spawn_from_request() 读取字段的对照规格。
## 【2 号消费硬约束】（3 号 §3）
##   1. 全部战斗数值只从 2 号自己的数据表取；SpawnRequest 只提供第 7~10 项覆盖位，不改数据表。
##   2. 不得新增 / 删除 / 重命名字段；需要新字段写进 README 待裁决，由主 AI 裁决后 3 号统一加。
##   3. 不得写 combat.* flag 或 SaveDelta；击杀只发 I-2 信号。
##   4. patrol_route 是非类型化 Array（元素 Vector3），不是 Array[Vector3]。
##   5. 数组字段为空时按默认值处理，不抛异常。
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

# 1  请求唯一 id（对账与日志键）
@export var request_id: String = ""                      # 取值 spawn_<slug>；只读，作日志键
# 2  数据表 id：2 号据此查 EnemyData / BossData 表，查不到则 push_error 不生成
@export var enemy_id: String = ""                        # 取值 <类别>_<序号>_<slug>；必须据此查表
# 3  生成挂点（由 1 号场景提供，2 号只按名取位置）
@export var spawn_point_id: String = ""                  # Marker3D 节点名；只读
# 4  生成坐标兜底（spawn_point_id 找不到时使用）
@export var position: Vector3 = Vector3.ZERO             # Godot 世界坐标；只用于摆位，不改战斗数值
# 5  初始朝向（绕 Y 轴）
@export var facing_degrees: float = 0.0                  # 范围 [0, 360)；只用于摆位
# 6  敌人等级
@export var level: int = 1                               # 范围 >= 1；只读，不改数据表
# 7  HP 覆盖位：-1 = 用数据表 HP；>= 0 时覆盖本次生成 HP，不改数据表
@export var hp_override: int = -1                        # 取值 -1 或 >= 1
# 8  韧性覆盖位：-1.0 = 用数据表韧性；>= 0.0 时覆盖，不改数据表
@export var stance_override: float = -1.0                # 取值 -1.0 或 >= 0.0
# 9  AI 感知半径覆盖位（不改数据表）
@export var aggro_radius: float = 8.0                    # 范围 >= 0.0；覆盖 AI 感知半径
# 10 脱战回位半径（含滞回）
@export var leash_radius: float = 16.0                   # 范围 >= aggro_radius；覆盖 AI 丢失半径
# 11 刷新策略：2 号不自行刷新，由 3 号按此字段写 Delta
@export var respawn_policy: String = "on_grace_rest"     # 取值 never|on_grace_rest|on_area_reload
# 12 击杀后 3 号要写的 flag：2 号不写此 flag
@export var defeated_flag: String = ""                   # 三段式 combat.<对象>.defeated；2 号只读且不写
# 13 掉落表 id
@export var loot_table_id: String = ""                   # 取值 loot_<序号>_<slug>；2 号按表掉落
# 14 巡逻点：非类型化 Array（元素 Vector3），空数组 = 原地待机
@export var patrol_route: Array = []                     # 元素 Vector3；只读；数组为空按默认处理
# 15 是否 Boss（血条 / 二阶段）
@export var is_boss: bool = false                        # 只读
# 16 同组敌人共享重置 / 计数
@export var spawn_group_id: String = ""                  # 取值 group_<slug>；只读
# 17 非战斗元数据（房间 id / 镜头 / 音频开关）：只读，不得塞战斗数值
@export var metadata: Dictionary = {}                    # 任意标量键值；只读
