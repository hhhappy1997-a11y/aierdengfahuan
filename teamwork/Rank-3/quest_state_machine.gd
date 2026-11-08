extends Node

## 任务状态机（3 号节点，M4）。信号 + 状态机；阶段只前进不回退。
## 与 SaveDelta 的 M3「quest_stages 取较大值」同源：advance_quest 用 maxi(cur, incoming)。
## 阶段推进统一走 WorldState.set_flag（I-1），因此所有阶段变化天然进 Delta。

signal quest_started(quest_id: String)
signal quest_stage_changed(quest_id: String, stage_id: String, stage_index: int)
signal quest_completed(quest_id: String, rewards: Dictionary)

var _ws: Node = null
var _stages: Dictionary = {}     # quest_id -> int stage_index

func _ready() -> void:
    _ws = get_node_or_null("/root/WorldState")
    var bus: Node = get_node_or_null("/root/GameEvents")
    if bus != null and bus.has_signal("item_acquired"):
        bus.connect("item_acquired", Callable(self, "_on_item_acquired"))

func get_stage_index(quest_id: String) -> int:
    return int(_stages.get(quest_id, 0))

## 阶段只前进不回退：收到更早 / 重复的 stage_index 时忽略并 warning，防对话重复触发刷奖励。
func advance_quest(quest_id: String, stage_id: String, stage_index: int, reward_key: String = "") -> void:
    var cur: int = get_stage_index(quest_id)
    var next: int = maxi(cur, stage_index)
    if next <= cur and cur > 0:
        push_warning("M4: 任务阶段回退 / 重复推进被忽略：%s %d" % [quest_id, stage_index])
        return
    _stages[quest_id] = next
    _set_flag("quest.%s.stage" % _object_of(quest_id), next)
    if cur == 0:
        quest_started.emit(quest_id)
    quest_stage_changed.emit(quest_id, stage_id, next)
    if next >= 3:
        var rewards: Dictionary = {"runes": 800, "items": {}, "flags": {}, "reward_key": reward_key}
        quest_completed.emit(quest_id, rewards)

## M3/M4 交叉：拾取 item_bell_fragment 时把 stage 1 → 2 自动推进，并强制落盘 reason="quest_stage"。
func _on_item_acquired(item_id: String, count: int) -> void:
    if item_id == "item_bell_fragment" and get_stage_index("quest_01_bell_of_return") == 1:
        advance_quest("quest_01_bell_of_return", "stage_02_return", 2)
        var writer: Node = get_node_or_null("/root/SaveDeltaWriter")
        if writer != null and writer.has_method("commit"):
            writer.call("commit", "quest_stage")

func _object_of(quest_id: String) -> String:
    var parts: PackedStringArray = quest_id.split("_")
    if parts.size() > 2:
        var rest: PackedStringArray = PackedStringArray()
        for i in range(2, parts.size()):
            rest.append(parts[i])
        return "_".join(rest)
    return quest_id

func _set_flag(key: String, value: Variant) -> void:
    if _ws != null and _ws.has_method("set_flag"):
        _ws.call("set_flag", key, value)
