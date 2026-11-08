extends Resource
class_name WorldBaseline

## 世界基线清单（存档与flag规范.md §4.2 的数据化）。R2 新增，供 world_baseline.tres 加载。
## 基线只读：所有 flag 默认 false / 0 / 0.0 / ""，任务处于 stage_00，敌人 defeated = false。
## SaveDelta.flags 只记录相对本基线的变化。

@export var baseline_version: int = 1
@export var manifest_hash: String = ""
@export var default_flags: Dictionary = {}       # 三段式 key -> 基线标量
@export var quest_ids: Array = []
@export var grace_ids: Array = []
@export var dungeon_ids: Array = []
@export var resource_ids: Array = []              # res:// 基线资源清单
@export var default_quest_stage_id: String = "stage_00_offer"
