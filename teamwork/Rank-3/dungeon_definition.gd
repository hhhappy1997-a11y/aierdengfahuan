extends Resource
class_name DungeonDefinition

## 箱庭地牢定义（箱庭地牢模板.md 全文的数据化）。R2 新增，供 dungeon_01_bellvault.tres 加载。
## 严格「1 赐福 + 1 精英 + 1 单向门捷径」；井底赐福属 M6 增量，M3 不放置。

@export var dungeon_id: String = ""
@export var scene_path: String = ""
@export var floor_count: int = 3
@export var floor_height_m: float = 6.0
@export var grace_ids: Array = []                 # 元素 grace_id String（M3 仅 1 个）
@export var elite_spawn_ids: Array = []           # 元素 SpawnRequest.request_id String
@export var room_ids: Array = []                  # 元素 room_id String
@export var interactable_specs: Array = []        # 元素 InteractableSpec
@export var shortcut_door_id: String = ""
@export var shortcut_flag: String = ""
@export var hidden_wall_ids: Array = []           # 隐藏墙零提示
@export var delta_checkpoint_reasons: Array = []  # 元素 reason String
@export var entry_load_boundary: String = ""
@export var exit_load_boundary: String = ""
@export var short_load_budget_sec: float = 0.8
