extends Resource
class_name DialogueChoice

## 对话选项。执行顺序固定（不可调换）：
## consume_items → set_flags → advance_quest → grant_items → 跳转。
## 字段与 RPG系统设计.md §1.3、dialogue_and_quest.tres 逐字一致。

@export var choice_id: String = ""
@export var text: String = ""
@export var gates: Array = []              # 元素 DialogueGate；不满足则隐藏（非灰显）该选项
@export var next_node_id: String = ""      # 空串表示结束对话
@export var set_flags: Dictionary = {}     # {flag_key: 值}，逐条走 WorldState.set_flag（I-1）
@export var grant_items: Dictionary = {}   # {item_id: int}
@export var consume_items: Dictionary = {} # {item_id: int}；不足则整个选项不显示
@export var advance_quest: Dictionary = {} # {quest_id, stage_id, reward_key?}
@export var end_dialogue: bool = false
