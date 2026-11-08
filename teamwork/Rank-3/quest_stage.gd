extends Resource
class_name QuestStage

## 任务阶段。奖励在离开该阶段时发放。
## 字段与 RPG系统设计.md §1.6、dialogue_and_quest.tres 逐字一致。

@export var stage_id: String = ""                # stage_<序号>_<slug>
@export var title: String = ""
@export var entry_flags: Dictionary = {}         # 进入该阶段要写入的 flag
@export var on_complete_flags: Dictionary = {}   # 离开该阶段写入的 flag
@export var rewards: Dictionary = {}             # {runes, items, flags, branch_overrides?}
@export var next_stage_id: String = ""           # 空串 = 终态
