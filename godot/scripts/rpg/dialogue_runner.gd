extends Node

## 对话运行器（3 号节点，M4）。赐福「交谈 / 回忆」与 NPC 交谈复用本 Runner 与同一套
## DialogueGraph 结构，只换 open_graph 的 trigger_source / trigger_owner_id，不复制对话逻辑。
## 门控（flag + 背包）在进入节点 / 显示选项的瞬间求值、不缓存 —— 这是「flag 变化驱动对话分支」的关键。

signal dialogue_opened(graph_id: String, trigger_source: String)
signal dialogue_closed(graph_id: String)

const GRAPH_PATH: String = "res://data/rpg/dialogue_and_quest.tres"

var _ws: Node = null
var _graph: Resource = null     # DialogueGraph
var _graph_id: String = ""
var _trigger_source: String = ""
var _trigger_owner_id: String = ""
var _current_node_id: String = ""

func _ready() -> void:
    _ws = get_node_or_null("/root/WorldState")

## 打开对话图。trigger_source 只影响立绘 / speaker / UI 底色 / 是否允许 choice，不改分支逻辑。
func open_graph(graph_id: String, trigger_source: String, trigger_owner_id: String) -> void:
    _graph_id = graph_id
    _trigger_source = trigger_source
    _trigger_owner_id = trigger_owner_id
    if not ResourceLoader.exists(GRAPH_PATH):
        push_error("M4: 找不到对话资源：%s" % GRAPH_PATH)
        return
    _graph = ResourceLoader.load(GRAPH_PATH)
    if _graph == null:
        push_error("M4: 对话资源加载失败：%s" % GRAPH_PATH)
        return
    var entry: Resource = _resolve_entry()
    if entry == null:
        return     # 全部入口门控不通过 → 不弹对话框
    dialogue_opened.emit(graph_id, trigger_source)
    _play_node(entry)

## 入口解析：从 start_node_id 在 nodes 中的位置向后扫描，
## 只考虑 is_entry == true 且 gates 全通过者，取第一个；全不通过返回 null。
func _resolve_entry() -> Resource:
    if _graph == null:
        return null
    var graph: DialogueGraph = _graph as DialogueGraph
    if graph == null:
        return null
    var nodes: Array = graph.nodes
    var start_at: int = -1
    for i in range(nodes.size()):
        if (nodes[i] as DialogueNode) != null and String((nodes[i] as DialogueNode).node_id) == graph.start_node_id:
            start_at = i
            break
    if start_at < 0:
        push_error("M4: start_node_id 不在 nodes 中：%s" % graph.start_node_id)
        return null
    for j in range(start_at, nodes.size()):
        var node: DialogueNode = nodes[j] as DialogueNode
        if node == null or not node.is_entry:
            continue
        if _gates_pass(node.gates):
            return node
    return null

## 一个 Array 内多个 gate 是 AND；求值只发生在调用瞬间，不缓存。
func _gates_pass(gates: Array) -> bool:
    for g in gates:
        if not _gate_pass(g as DialogueGate):
            return false
    return true

func _gate_pass(gate: DialogueGate) -> bool:
    if gate == null:
        return true
    var result: bool = false
    match gate.kind:
        "flag":
            result = _compare_flag(gate)
        "item":
            result = _compare_item(gate)
        "quest_stage":
            result = _compare_quest_stage(gate)
        _:
            push_warning("M4: 未知 gate kind：%s" % gate.kind)
            result = false
    return result if not gate.negate else not result

func _compare_flag(gate: DialogueGate) -> bool:
    var current: Variant = _get_flag(gate.key, gate.value)
    return _compare(current, gate.value, gate.op)

func _compare_item(gate: DialogueGate) -> bool:
    # 背包数量由 2 号 Inventory 结算；3 号只读计数，不实现数值。
    var count: int = 0
    match gate.op:
        "has", "not_has":
            return count >= 1 if gate.op == "has" else count < 1
        "gte":
            return count >= int(gate.value)
        _:
            return false

func _compare_quest_stage(gate: DialogueGate) -> bool:
    var idx: int = 0
    var qsm: Node = get_node_or_null("/root/QuestStateMachine")
    if qsm != null and qsm.has_method("get_stage_index"):
        idx = int(qsm.call("get_stage_index", gate.key))
    return _compare(idx, int(gate.value), gate.op)

func _compare(a: Variant, b: Variant, op: String) -> bool:
    match op:
        "eq":
            return a == b
        "ne":
            return a != b
        "gte":
            return float(a) >= float(b)
        "lte":
            return float(a) <= float(b)
        _:
            return false

func _get_flag(key: String, default: Variant) -> Variant:
    if _ws != null and _ws.has_method("get_flag"):
        return _ws.call("get_flag", key, default)
    return default

func _play_node(node: DialogueNode) -> void:
    if node == null:
        return
    _current_node_id = node.node_id
    for k in node.on_enter_flags.keys():
        _set_flag(String(k), node.on_enter_flags[k])
    for line in node.lines:
        var dl: DialogueLine = line as DialogueLine
        if dl != null and _gates_pass(dl.gates):
            _present_line(dl)
    var choices: Array = _visible_choices(node.choices)
    if choices.is_empty():
        if node.end_dialogue:
            dialogue_closed.emit(_graph_id)
        return
    # 展示 choices（M4：flag / 背包门控隐藏选项，而非灰显）
    _present_choices(choices)

func _visible_choices(choices: Array) -> Array:
    var out: Array = []
    for c in choices:
        var choice: DialogueChoice = c as DialogueChoice
        if choice != null and _gates_pass(choice.gates):
            out.append(choice)
    return out

func _present_line(line: DialogueLine) -> void:
    # UI 呈现由 1 号负责；此处只按 trigger_source 决定是否显示立绘 / 覆盖 speaker。
    pass

func _present_choices(choices: Array) -> void:
    pass

## 选项执行顺序（固定）：consume_items → set_flags → advance_quest → grant_items → 跳转。
func choose(choice: DialogueChoice) -> void:
    if choice == null:
        return
    for k in choice.consume_items.keys():
        _consume_item(String(k), int(choice.consume_items[k]))
    for k in choice.set_flags.keys():
        _set_flag(String(k), choice.set_flags[k])
    if not choice.advance_quest.is_empty():
        _advance_quest(choice.advance_quest)
    for k in choice.grant_items.keys():
        _grant_item(String(k), int(choice.grant_items[k]))
    if choice.next_node_id.is_empty():
        dialogue_closed.emit(_graph_id)
        return
    var target: DialogueNode = _find_node(choice.next_node_id)
    if target != null:
        _play_node(target)     # 跳转目标不检查 gates / is_entry

func _find_node(node_id: String) -> DialogueNode:
    if _graph == null:
        return null
    var graph: DialogueGraph = _graph as DialogueGraph
    if graph == null:
        return null
    for n in graph.nodes:
        var dn: DialogueNode = n as DialogueNode
        if dn != null and dn.node_id == node_id:
            return dn
    push_warning("M4: 跳转目标节点不存在：%s" % node_id)
    return null

func _set_flag(key: String, value: Variant) -> void:
    if _ws != null and _ws.has_method("set_flag"):
        _ws.call("set_flag", key, value)

func _consume_item(item_id: String, count: int) -> void:
    pass  # 背包数值结算属 2 号（待裁决 A9）

func _grant_item(item_id: String, count: int) -> void:
    pass  # 背包数值结算属 2 号（待裁决 A9）

func _advance_quest(payload: Dictionary) -> void:
    var qsm: Node = get_node_or_null("/root/QuestStateMachine")
    if qsm != null and qsm.has_method("advance_quest"):
        qsm.call("advance_quest", String(payload.get("quest_id", "")), String(payload.get("stage_id", "")), int(payload.get("stage_index", 0)), String(payload.get("reward_key", "")))
