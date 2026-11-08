extends Resource
class_name GraceNetwork

## 赐福传送网络：无向图 + 带条件的边。字段与 RPG系统设计.md §4.1 一致。

@export var network_id: String = ""              # network_01_lands_between
@export var nodes: Array = []                    # 元素 GraceNode
@export var edges: Array = []                    # 元素 Dictionary {from, to, requires_flags}
