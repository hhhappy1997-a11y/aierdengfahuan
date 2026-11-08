extends RefCounted
class_name VoiceLineBinder

## R4 补齐件：语音键表（voice_key_table.json，R3 真跑产物）与对话节点（dialogue_and_quest.tres）联调绑定器。
## **不重做 / 不改写** voice_key_table.json / voice_manifest.json / dialogue_*.gd / dialogue_and_quest.tres / 3 个 WAV。
## 解决「有 WAV 但游戏不知道在哪句台词播」：把 vo_id → (graph_id, node_id, line_id) → res_path 建索引，
## 供 DialogueRunner._present_line(line) 后续按 line.line_id 取 res_path 播放（本轮不改 Runner，见 R4 联调说明）。
##
## 绑定关系（与 dialogue_and_quest.tres 逐条对齐，R4 静态自检已核对）：
##   vo_bellkeeper_01   → graph_npc_bellkeeper / node_first_meet / line_bellkeeper_01
##   vo_bellkeeper_02   → graph_npc_bellkeeper / node_first_meet / line_bellkeeper_02
##   vo_grace_memory_01 → graph_grace_bellkeeper_memory / node_grace_memory / line_memory_01
## 三个 graph_id / node_id / line_id / text 均在 dialogue_and_quest.tres 中真实存在且台词逐字一致；
## trigger_source / trigger_owner_id 亦与两张 DialogueGraph 的字段一致。
##
## 中文 UTF-8；Godot 4 全静态类型；零付费 / 零外部依赖。

const KEY_TABLE_PATH: String = "res://data/voice/voice_key_table.json"

var _by_line_id: Dictionary = {}      # line_id -> entry Dictionary
var _by_triple: Dictionary = {}       # "graph_id|node_id|line_id" -> entry Dictionary
var _entries: Array = []

func _init(key_table_path: String = KEY_TABLE_PATH) -> void:
	load_key_table(key_table_path)

## 载入语音键表并建两级索引。文件缺失 / 解析失败时 push_warning 降级为空索引（不抛异常、不中断游戏）。
func load_key_table(path: String) -> bool:
	_by_line_id.clear()
	_by_triple.clear()
	_entries.clear()
	if not FileAccess.file_exists(path):
		push_warning("[VoiceLineBinder] 语音键表未落地：%s（工程根建立后按 res 路径拷贝）" % path)
		return false
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("[VoiceLineBinder] 无法打开语音键表：%s" % path)
		return false
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[VoiceLineBinder] 语音键表不是合法 JSON 对象：%s" % path)
		return false
	var root: Dictionary = parsed as Dictionary
	var arr: Array = root.get("entries", []) as Array
	for raw in arr:
		var e: Dictionary = raw as Dictionary
		var line_id: String = String(e.get("line_id", ""))
		var res_path: String = String(e.get("res_path", ""))
		if line_id.is_empty() or res_path.is_empty():
			continue
		_entries.append(e)
		_by_line_id[line_id] = e
		var triple: String = "%s|%s|%s" % [String(e.get("graph_id", "")), String(e.get("node_id", "")), line_id]
		_by_triple[triple] = e
	return true

## 按 line_id 取 WAV 的 res:// 路径；未绑定返回 ""（由 UI 侧静默跳过语音，不弹错误）。
func resolve_voice(line_id: String) -> String:
	if not _by_line_id.has(line_id):
		return ""
	var e: Dictionary = _by_line_id[line_id] as Dictionary
	return String(e.get("res_path", ""))

## 严格三元组匹配（graph_id + node_id + line_id），避免同 line_id 在不同图里串音。
func resolve_voice_for(graph_id: String, node_id: String, line_id: String) -> String:
	var triple: String = "%s|%s|%s" % [graph_id, node_id, line_id]
	if not _by_triple.has(triple):
		return ""
	var e: Dictionary = _by_triple[triple] as Dictionary
	return String(e.get("res_path", ""))

## 已绑定条目数（联调自检用）。
func bound_count() -> int:
	return _entries.size()

## 校验键表条目是否与对话资源对齐：传入从 dialogue_and_quest.tres 抽出的合法 line_id / graph_id 集合，
## 返回未命中清单（供联调静态自检 / 文档引用；本函数是交付件的纯逻辑方法，不是独立探针脚本）。
static func cross_check(entry_list: Array, valid_line_ids: Array, valid_graph_ids: Array) -> Dictionary:
	var missing_lines: Array = []
	var missing_graphs: Array = []
	for raw in entry_list:
		var e: Dictionary = raw as Dictionary
		var lid: String = String(e.get("line_id", ""))
		var gid: String = String(e.get("graph_id", ""))
		if not valid_line_ids.has(lid):
			missing_lines.append(lid)
		if not valid_graph_ids.has(gid):
			missing_graphs.append(gid)
	return {"entries": entry_list.size(), "missing_lines": missing_lines, "missing_graphs": missing_graphs}
