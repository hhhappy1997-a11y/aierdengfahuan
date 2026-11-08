extends Resource
class_name InteractableSpec

## 统一交互件规格。字段与 RPG系统设计.md §3.1 一致。
## 隐藏墙硬约束：kind="hidden_wall"、prompt_enabled=false、prompt_icon=""，零提示。

@export var spec_id: String = ""                 # 与 flag 对象段一致
@export var kind: String = ""                    # pickup/door/one_way_door/hidden_wall/lift/grace/npc_talk/grace_memory
@export var flag_key: String = ""                # 三段式 key
@export var flag_value: Variant = true
@export var prompt_enabled: bool = true         # hidden_wall 必须 false
@export var prompt_icon: String = ""
@export var prompt_offset: Vector3 = Vector3.ZERO
@export var area_size: Vector3 = Vector3.ONE
@export var item_id: String = ""
@export var item_count: int = 0
@export var open_side: String = ""              # one_way_door：允许开启的一侧（b3_side）
@export var target_floor: int = 0
@export var delta_checkpoint: bool = false      # 触发后是否强制落盘
@export var graph_id: String = ""
