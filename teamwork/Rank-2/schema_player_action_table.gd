extends Resource
class_name PlayerActionTable

## 2 号工位 · R2 配套容器类：PlayerActionTable
## 目的：Godot 4 单个 .tres 只能有一个 [resource] 主资源；要把「8 条 PlayerActionData
##   实例」装进单个 player_actions.tres，必须有一个顶层 Resource 以数组属性持有它们。
## 本类**不属于** R1《数据表schema.md》的 8 类 Resource，仅为 R2 交付 player_actions.tres
##   所需的工程配套件；不引入任何战斗数值，只做数据装配。
## 落工程映射：res://data/schemas/player_action_table.gd
## 用法：工程挂载时把 PlayerActionTable.actions 一次性赋给
##   PlayerStateMachine.actions（Array[PlayerActionData]）；状态机本轮「其余逻辑不变」不修改。
## 引擎：Godot 4 标准版 / GDScript，全静态类型。

## 8 条动作，须满足 E-6：state_name 覆盖 8 状态全集、state_priority 互异、logic_fps 全等。
@export var actions: Array[PlayerActionData] = []
