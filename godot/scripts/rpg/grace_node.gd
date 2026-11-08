extends Resource
class_name GraceNode

## 赐福节点。字段与 RPG系统设计.md §4.1 一致。
## 解锁 flag 严格三段式：grace.<对象>.lit / .unlocked / .visited。

@export var grace_id: String = ""                # grace_<区域>_<地点>
@export var display_name: String = ""
@export var area_id: String = ""
@export var scene_path: String = ""              # res:// 场景路径（1 号 chunk / 地牢场景）
@export var spawn_marker: String = ""
@export var lit_flag: String = ""
@export var unlocked_flag: String = ""
@export var requires_flags: Dictionary = {}      # 该节点可被发现的前置
@export var neighbors: Array = []                # 元素为 grace_id String，用于菜单排序
@export var is_dungeon: bool = false
@export var discover_radius: float = 12.0
