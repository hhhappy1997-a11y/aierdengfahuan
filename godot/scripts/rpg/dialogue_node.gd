extends Resource
class_name DialogueNode

## 对话节点。is_entry 决定是否参与入口解析（false 的节点只能由 Choice 跳转到达）。
## 字段与 RPG系统设计.md §1.4、dialogue_and_quest.tres 逐字一致。

@export var node_id: String = ""
@export var gates: Array = []              # 元素 DialogueGate；节点级门控，不满足跳过整个节点
@export var lines: Array = []              # 元素 DialogueLine，≥1 行
@export var choices: Array = []            # 元素 DialogueChoice；空数组表示无分支
@export var on_enter_flags: Dictionary = {} # 进入节点即写（如 world.npc_01_bellkeeper.met = true）
@export var is_entry: bool = false
@export var end_dialogue: bool = true
