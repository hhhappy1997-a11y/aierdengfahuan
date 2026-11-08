extends Resource
class_name DialogueLine

## 单行台词。字段与 RPG系统设计.md §1.2、dialogue_and_quest.tres 逐字一致。

@export var line_id: String = ""          # line_<graph短名>_<序号>
@export var speaker: String = ""          # 赐福回忆用 "记忆的余响"，而非 NPC 名
@export var text: String = ""             # 中文正文，一句不超过 42 字
@export var gates: Array = []             # 元素 DialogueGate；单行级门控，不满足则跳过该行
@export var portrait_id: String = ""      # 由 4 号资产清单提供；grace_memory 图统一留空
