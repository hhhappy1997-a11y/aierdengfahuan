extends Resource
class_name DialogueGraph

## 对话图。linked_graphs 把同一 .tres 内的其它图挂到主资源上，
## 避免子资源孤立被丢弃（赐福回忆图即由此被访问）。
## 字段与 RPG系统设计.md §1.5、dialogue_and_quest.tres 逐字一致。

@export var graph_id: String = ""
@export var trigger_source: String = "npc_talk"  # npc_talk / grace_talk / grace_memory
@export var trigger_owner_id: String = ""
@export var start_node_id: String = ""
@export var nodes: Array = []                    # 元素 DialogueNode
@export var linked_quest: Resource = null        # 元素 QuestData，可为 null（纯闲聊图）
@export var linked_graphs: Array = []            # 元素 DialogueGraph
