extends Resource
class_name QuestData

## 任务定义。R2 任务书 §2 称其为 QuestDefinition；本工位权威定名为 QuestData，
## 与 RPG系统设计.md §6 的脚本路径及 dialogue_and_quest.tres 的 ext_resource 逐字一致
## （res://scripts/rpg/quest_data.gd）。字段与 §1.6 逐字一致。

@export var quest_id: String = ""                # quest_<序号>_<slug>
@export var display_name: String = ""
@export var prerequisite_flags: Dictionary = {}  # 前置 flag，不满足不激活任务
@export var start_stage_id: String = ""
@export var stages: Array = []                   # 元素 QuestStage
@export var rewards: Dictionary = {}             # 全任务完成奖励，结构同 QuestStage.rewards
