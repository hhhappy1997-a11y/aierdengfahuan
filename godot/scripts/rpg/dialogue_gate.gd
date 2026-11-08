extends Resource
class_name DialogueGate

## 对话条件门控（I-1 纯读，不写世界状态）。
## 字段与 RPG系统设计.md §1.1、dialogue_and_quest.tres 逐字一致。
## 数组字段一律非类型化 Array，保证手写 .tres 在 Godot 4 下零歧义加载。

@export var gate_id: String = ""                 # gate_<slug>
@export var kind: String = "flag"                # "flag" / "item" / "quest_stage"
@export var key: String = ""                     # flag→三段式 key；item→item_id；quest_stage→quest_id
@export var op: String = "eq"                    # flag/quest_stage: eq/ne/gte/lte；item: has/not_has/gte
@export var value: Variant = true                # 仅 bool / int / float / String
@export var negate: bool = false                 # 结果取反
