extends SceneTree
## R24 · Rank-1（引擎架构与渲染）：把 v0.1.0 遭遇战场景以 instance 占位接进 courtyard.tscn。
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path <godot> \
##        --script res://scripts/combat/build_courtyard_v020.gd
##
## 唯一写入的既有场景：res://scenes/courtyard.tscn（覆写）；串行备份落在 teamwork/Rank-1/。
## 不写 project.godot / encounter_v010.tscn / encounter_director.gd / 既有战斗件 / 任何美术资源。
##
## 串行流程：备份 → instantiate → 把 encounter_v010.tscn 以 instance 占位挂进合适父节点
##   → owner 链 → PackedScene.pack() 前后节点数比对 → ResourceSaver.save
##   → CACHE_MODE_IGNORE 磁盘回读校验。
##
## 父节点选择：根节点 Courtyard（主视口 1280x720 层级）。encounter 自带 HUD 是 CanvasLayer，
##   只有挂在主视口层级，StatusLabel 的 (24,660) 才是 1280x720 屏幕底部；若挂进
##   SubViewport(640x360)，y=660 会落到低分辨率视口外而不可见。
##
## HUD 重叠处理：用 instance 属性覆盖把战斗状态 Label 从 (24,20) 移到屏幕底部
##   (24,660)-(1224,692)，y>=660 既不落进赐福 HUD 矩形 x<730,y<220，也不落进
##   右上画质面板 x>760,y<180；encounter_v010.tscn 源文件零改动。
##
## owner 链口径（沿用 build_courtyard.gd / attach_boss_to_courtyard.gd）：只给实例根节点
##   设 owner=courtyard 根，实例内部节点保持 owner=实例根，PackedScene.pack() 才会把整棵
##   子树识别为 instance 占位而非内联展开。
## 【Godot 4.7 真跑结论，如实登记】--script 模式下 PackedScene.pack() 会正确写出
##   instance 占位（disk_nodes 27→28、4 个 instance 引用齐全、原有 3 个 instance 未内联），
##   但**不会**把实例内部子节点 StatusLabel 的属性差异写成 instance 内部覆盖段
##   （把该 Label 的 owner 改指主场景根也不生效，回读 label_y 仍是源值 20）。
##   因此本脚本在 ResourceSaver.save() 之后，按 Godot 4 .tscn 标准格式追加一条
##   instance 内部覆盖段（parent="EncounterRoot/HUD"），再用 CACHE_MODE_IGNORE 真跑回读
##   校验 label_y=660；encounter_v010.tscn 源文件始终零改动。
## 引擎：Godot 4.7.2 标准版 / GDScript，全静态类型；中文 UTF-8。

const SRC_SCENE: String = "res://scenes/courtyard.tscn"
const ENCOUNTER_SCENE: String = "res://scenes/encounter_v010.tscn"
const BACKUP_PATH: String = "F:/Game/aierdengfahuan/teamwork/Rank-1/courtyard.tscn.r24.bak"
const INSTANCE_NODE_NAME: String = "EncounterRoot"
const STATUS_LABEL_PATH: String = "HUD/StatusLabel"
const ENCOUNTER_RUNTIME_NODES: int = 6

# 战斗 HUD 目标矩形（屏幕底部，避开顶部两个既有 HUD 区域）
const HUD_LEFT: float = 24.0
const HUD_TOP: float = 660.0
const HUD_RIGHT: float = 1224.0
const HUD_BOTTOM: float = 692.0
# 既有 HUD 保护区（用于如实登记「不遮挡」判定）
const BLESSING_HUD_MAX_Y: float = 220.0
const QUALITY_PANEL_MAX_Y: float = 180.0

# Godot 4 .tscn 标准「instance 内部属性覆盖段」：parent 指向实例根内路径，
# 只写与源场景不同的 Control 偏移属性；不新增运行时节点，只覆盖实例内既有 StatusLabel。
const OVERRIDE_MARKER: String = "[node name=\"StatusLabel\" parent=\"EncounterRoot/HUD\""
const OVERRIDE_BLOCK: String = "[node name=\"StatusLabel\" parent=\"EncounterRoot/HUD\" index=\"0\"]\n" \
		+ "offset_left = 24.0\n" \
		+ "offset_top = 660.0\n" \
		+ "offset_right = 1224.0\n" \
		+ "offset_bottom = 692.0\n"


func _initialize() -> void:
	print("[BUILD_V020] START")

	# ---- (1) 串行备份：先完整备份既有场景，再允许任何改动 ----
	if not _backup():
		push_error("[BUILD_V020] 备份失败，拒绝改场景")
		quit(1)
		return

	# ---- (2) 读源场景（CACHE_MODE_IGNORE 取磁盘基线，如实登记当前 courtyard 节点数）----
	var src: PackedScene = ResourceLoader.load(
			SRC_SCENE, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if src == null:
		push_error("[BUILD_V020] 加载 courtyard.tscn 失败")
		quit(1)
		return
	var baseline_disk_nodes: int = src.get_state().get_node_count()
	print("[BUILD_V020] BASELINE disk_nodes=%d（当前 courtyard 如实登记，未冒充）" % baseline_disk_nodes)

	var root: Node = src.instantiate()
	var before: int = _count(root)
	print("[BUILD_V020] INSTANTIATE runtime_nodes_before=%d" % before)

	# ---- (3) 遭遇战场景以 instance 占位挂进合适父节点 ----
	var enc_ps: PackedScene = ResourceLoader.load(
			ENCOUNTER_SCENE, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if enc_ps == null:
		push_error("[BUILD_V020] 加载 encounter_v010.tscn 失败")
		_free_tree(root)
		quit(1)
		return
	var enc: Node = enc_ps.instantiate()

	# HUD 重叠处理：instance 属性覆盖（只改实例内 Label 的 Control 偏移，不改 encounter 源文件）。
	var label: Label = enc.get_node_or_null(STATUS_LABEL_PATH) as Label
	if label == null:
		push_error("[BUILD_V020] encounter 缺少 %s" % STATUS_LABEL_PATH)
		_free_tree(enc)
		_free_tree(root)
		quit(1)
		return
	label.position = Vector2(HUD_LEFT, HUD_TOP)
	label.size = Vector2(HUD_RIGHT - HUD_LEFT, HUD_BOTTOM - HUD_TOP)
	var no_overlap: bool = label.offset_top >= BLESSING_HUD_MAX_Y \
			and label.offset_top >= QUALITY_PANEL_MAX_Y
	print("[BUILD_V020] HUD_OVERRIDE %s offset=(%.0f,%.0f)-(%.0f,%.0f) no_overlap=%s" % [
			STATUS_LABEL_PATH, label.offset_left, label.offset_top,
			label.offset_right, label.offset_bottom, str(no_overlap)])

	# 幂等：同脚本重跑不叠加遭遇战实例。
	var existing: Node = root.get_node_or_null(INSTANCE_NODE_NAME)
	if existing != null:
		root.remove_child(existing)
		_free_tree(existing)
	root.add_child(enc)
	# ---- (4) owner 链：只给实例根设 owner=root，实例内部节点保持 owner=实例根 ----
	enc.owner = root
	var after_add: int = _count(root)
	print("[BUILD_V020] ATTACH parent=%s instance_path=%s runtime_nodes_after_add=%d added=%d" % [
			str(root.name), str(enc.scene_file_path), after_add, after_add - before])

	# ---- (5) PackedScene.pack() 前后节点数比对（防静默丢节点）----
	var packed: PackedScene = PackedScene.new()
	var pack_err: Error = packed.pack(root)
	if pack_err != OK:
		push_error("[BUILD_V020] pack 失败 err=%d" % pack_err)
		_free_tree(root)
		quit(1)
		return
	var probe: Node = packed.instantiate()
	var after_pack: int = _count(probe)
	_free_tree(probe)
	print("[BUILD_V020] NODE_COUNT before=%d after_add=%d after_pack=%d pack_err=%d" % [
			before, after_add, after_pack, pack_err])
	if after_pack != after_add:
		push_error("[BUILD_V020] pack 前后运行时节点数不符，拒绝保存")
		_free_tree(root)
		quit(1)
		return

	# ---- (6) ResourceSaver.save 覆写唯一可写的既有场景 ----
	var save_err: Error = ResourceSaver.save(packed, SRC_SCENE)
	_free_tree(root)
	if save_err != OK:
		push_error("[BUILD_V020] 保存失败 err=%d" % save_err)
		quit(1)
		return
	print("[BUILD_V020] SAVED path=%s err=%d" % [SRC_SCENE, save_err])

	# ---- (6b) 追加 Godot 4 标准 instance 内部属性覆盖段（pack() 不生成，见顶部结论）----
	if not _append_instance_override():
		push_error("[BUILD_V020] 追加 instance 内部覆盖段失败")
		quit(1)
		return

	# ---- (7) CACHE_MODE_IGNORE 磁盘回读校验 ----
	var check: PackedScene = ResourceLoader.load(
			SRC_SCENE, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if check == null:
		push_error("[BUILD_V020] CACHE_MODE_IGNORE 回读失败")
		quit(1)
		return
	var st: SceneState = check.get_state()
	var disk_nodes: int = st.get_node_count()
	# 枚举 SceneState 的 instance 占位：原有 3 个 + 新增 encounter，确认未被内联展开。
	var instances: PackedStringArray = PackedStringArray()
	var enc_instance_found: bool = false
	for i: int in range(disk_nodes):
		var inst_ps: PackedScene = st.get_node_instance(i)
		if inst_ps != null:
			var p: String = inst_ps.resource_path
			instances.append("%s:%s" % [str(st.get_node_name(i)), p])
			if p == ENCOUNTER_SCENE:
				enc_instance_found = true
	print("[BUILD_V020] READBACK disk_nodes=%d baseline=%d instances=[%s]" % [
			disk_nodes, baseline_disk_nodes, " | ".join(instances)])

	var rt: Node = check.instantiate()
	var rt_count: int = _count(rt)
	var enc_node: Node = rt.get_node_or_null(INSTANCE_NODE_NAME)
	var rt_label: Label = null
	if enc_node != null:
		rt_label = enc_node.get_node_or_null(STATUS_LABEL_PATH) as Label
	var label_y: float = rt_label.position.y if rt_label != null else -1.0
	var hud_ok: bool = rt_label != null and is_equal_approx(label_y, HUD_TOP) and no_overlap
	# 原有 3 个 instance 占位仍在（scene_file_path 非空 = 未被内联展开）
	var hud_inst: Node = rt.find_child("Hud", true, false)
	var fx_inst: Node = rt.find_child("HD2DFX", true, false)
	var qs_inst: Node = rt.find_child("QualitySettings", true, false)
	var legacy_ok: bool = hud_inst != null and not hud_inst.scene_file_path.is_empty() \
			and fx_inst != null and not fx_inst.scene_file_path.is_empty() \
			and qs_inst != null and not qs_inst.scene_file_path.is_empty()
	var enc_subtree_count: int = -1
	if enc_node != null:
		enc_subtree_count = _count(enc_node)
	_free_tree(rt)
	print("[BUILD_V020] READBACK runtime_nodes=%d enc_instance=%s enc_subtree=%d label_y=%.0f hud_bottom_ok=%s legacy_instances_intact=%s" % [
			rt_count, str(enc_instance_found), enc_subtree_count, label_y,
			str(hud_ok), str(legacy_ok)])

	# 与 pack 前内存树 after_add 比对（而非固定 before+6），使脚本从任一基线重跑都成立。
	var ok: bool = enc_instance_found and hud_ok and legacy_ok \
			and enc_subtree_count == ENCOUNTER_RUNTIME_NODES \
			and rt_count == after_add
	print("[BUILD_V020] END ok=%s" % str(ok))
	quit(0 if ok else 1)


func _backup() -> bool:
	# 串行备份只做一次：已存在则保留原始 27 节点基线，避免重跑把备份覆盖成中间态。
	if FileAccess.file_exists(BACKUP_PATH):
		print("[BUILD_V020] BACKUP already_exists keep_original_baseline path=%s" % BACKUP_PATH)
		return true
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(SRC_SCENE)
	if bytes.is_empty():
		return false
	var f: FileAccess = FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(bytes)
	f.close()
	var ok: bool = FileAccess.file_exists(BACKUP_PATH)
	print("[BUILD_V020] BACKUP path=%s bytes=%d ok=%s" % [BACKUP_PATH, bytes.size(), str(ok)])
	return ok


func _append_instance_override() -> bool:
	## 追加 Godot 4 标准 instance 内部属性覆盖段。ResourceSaver.save() 产出的 .tscn
	## 已含 instance 占位，但 --script 模式下 pack() 不写实例内部子节点的覆盖，故补此段。
	## 幂等：已含 OVERRIDE_MARKER 则跳过。
	var text: String = FileAccess.get_file_as_string(SRC_SCENE)
	if text.is_empty():
		return false
	if text.find(OVERRIDE_MARKER) != -1:
		print("[BUILD_V020] OVERRIDE_SEGMENT already_present skip")
		return true
	if not text.ends_with("\n"):
		text += "\n"
	text += "\n" + OVERRIDE_BLOCK
	var f: FileAccess = FileAccess.open(SRC_SCENE, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.close()
	var ok: bool = FileAccess.get_file_as_string(SRC_SCENE).find(OVERRIDE_MARKER) != -1
	print("[BUILD_V020] OVERRIDE_SEGMENT appended ok=%s" % str(ok))
	return ok


func _count(node: Node) -> int:
	var total: int = 1
	for child: Node in node.get_children():
		total += _count(child)
	return total


func _free_tree(node: Node) -> void:
	for child: Node in node.get_children():
		_free_tree(child)
	node.free()
