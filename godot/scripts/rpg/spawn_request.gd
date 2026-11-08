extends Resource
class_name SpawnRequest

## I-3 唯一权威定义（接口契约.md §3）。17 字段，2 号不得新增 / 删除 / 重命名字段。
## 全部战斗数值（HP、削韧、招式倍率、异常积累、阶段阈值）只从 2 号数据表取；
## 本资源只提供摆位与 7~10 项覆盖位，不改数据表。
## patrol_route 刻意声明为非类型化 Array（元素 Vector3），保证手写 .tres 零歧义。

@export var request_id: String = ""                       # 1  spawn_<slug>
@export var enemy_id: String = ""                         # 2  <类别>_<序号>_<slug>，2 号据此查表
@export var spawn_point_id: String = ""                   # 3  Marker3D 节点名，1 号提供
@export var position: Vector3 = Vector3.ZERO              # 4  生成坐标兜底
@export var facing_degrees: float = 0.0                   # 5  初始朝向（绕 Y 轴）
@export var level: int = 1                                # 6  敌人等级，交 2 号查表
@export var hp_override: int = -1                         # 7  -1 = 用数据表 HP
@export var stance_override: float = -1.0                 # 8  -1.0 = 用数据表韧性
@export var aggro_radius: float = 8.0                     # 9  接战半径覆盖
@export var leash_radius: float = 16.0                    # 10 脱战回位半径覆盖
@export var respawn_policy: String = "on_grace_rest"      # 11 never / on_grace_rest / on_area_reload
@export var defeated_flag: String = ""                    # 12 三段式 combat.<对象>.defeated；2 号不写
@export var loot_table_id: String = ""                    # 13 loot_<序号>_<slug>
@export var patrol_route: Array = []                      # 14 元素 Vector3；空数组 = 原地待机
@export var is_boss: bool = false                         # 15 是否 Boss（血条 / 二阶段）
@export var spawn_group_id: String = ""                   # 16 group_<slug>
@export var metadata: Dictionary = {}                     # 17 非战斗元数据；不得塞战斗数值
