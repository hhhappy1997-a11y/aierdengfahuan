extends SceneTree
## R15 · 地形材质挂载 + HUD 实例接入（SceneTree 追加式，幂等）
## 派单 cmd-20261109-083628-778-A1 · [ROUND=R15] · AI=1
## 依据：Rank-4/GROUND-MATERIAL.md、attach_hud.gd、tune_env.gd（SceneTree 追加式 pack /
##       owner 重设 / CACHE_MODE_IGNORE 回读模式）、capture/CAPTURE-REPORT.md、00-群聊总线.md
## 真跑：godot --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/assemble_r15.gd
## 门禁：godot --headless --path ... --check-only --script res://scripts/assemble_r15.gd
## 说明：所有赋值均为绝对目标值；HUD 已存在则不重复挂入；备份已存在则不覆盖 → 幂等。
##      节点数口径为 PackedScene.get_state().get_node_count()（.tscn 内 [node] 段数），
##      HUD 以 instance 占位写出故只 +1（22→23）；运行期 instantiate() 展开后整树为 25。

const SCENE_PATH: String = "res://scenes/courtyard.tscn"
const HUD_PATH: String = "res://scenes/hud.tscn"
const GROUND_MAT_PATH: String = "res://assets/generated/terrain/ground_material.tres"
const FXLAYER_PATH: String = "SubViewportContainer/SubViewport/FXLayer"
const HUD_NODE_NAME: String = "Hud"
const TERRAIN_PATHS := [
	"SubViewportContainer/SubViewport/Terrain/GroundPlate",
	"SubViewportContainer/SubViewport/Terrain/TerraceLow",
	"SubViewportContainer/SubViewport/Terrain/TerraceHigh",
]
const EXPECTED_BEFORE_FIRST: int = 22
const EXPECTED_AFTER: int = 23
# 备份位于工程根之外（res:// = godot/），用绝对 OS 路径写，幂等：已存在则跳过
const BACKUP_ABS: String = "F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r15"


func _initialize() -> void:
	print("[R15] === ASSEMBLE R15 START ===")

	# --- 1) 备份（幂等：已存在则跳过，绝不覆盖 pre-r15 原件） ---
	if not _backup():
		push_error("[R15] BACKUP 失败，拒绝继续（场景零改动）")
		quit(1)
		return

	# --- 2) load + instantiate ---
	var src: PackedScene = load(SCENE_PATH) as PackedScene
	if src == null:
		push_error("[R15] load courtyard.tscn 失败，拒绝继续")
		quit(1)
		return
	var root: Node = src.instantiate()
	var before_nodes: int = src.get_state().get_node_count()
	print("[R15] STEP2 load+instantiate OK, SceneState node_count(before)=", before_nodes)

	# --- 3) 三个 MeshInstance3D 挂同一 ground_material.tres（分档 uv 不追求差异） ---
	var mat: Material = load(GROUND_MAT_PATH) as Material
	if mat == null:
		push_error("[R15] load ground_material.tres 失败，拒绝继续")
		_free_tree(root)
		quit(1)
		return
	for p in TERRAIN_PATHS:
		var mi: MeshInstance3D = root.get_node_or_null(p) as MeshInstance3D
		if mi == null:
			push_error("[R15] 地形节点缺失: %s，拒绝继续" % p)
			_free_tree(root)
			quit(1)
			return
		mi.material_override = mat
		print("[R15] STEP3 material_override <- %s | node=%s" % [GROUND_MAT_PATH, str(p)])

	# --- 4) 实例化 hud.tscn 挂到 FXLayer 下，重设 owner 链（跳过实例化节点） ---
	var fx: Node = root.get_node_or_null(FXLAYER_PATH)
	if fx == null:
		push_error("[R15] 接入点 %s 缺失，拒绝继续" % FXLAYER_PATH)
		_free_tree(root)
		quit(1)
		return
	var hud: Node = fx.get_node_or_null(HUD_NODE_NAME)
	var had_hud: bool = hud != null
	if had_hud:
		# 幂等重跑：不重复挂入，仅确保实例标记与 owner
		hud.set("scene_file_path", HUD_PATH)
		hud.owner = root
		print("[R15] STEP4 HUD 已存在（幂等重跑），不重复挂入")
	else:
		var hud_ps: PackedScene = load(HUD_PATH) as PackedScene
		if hud_ps == null:
			push_error("[R15] load hud.tscn 失败，拒绝继续")
			_free_tree(root)
			quit(1)
			return
		hud = hud_ps.instantiate()
		hud.name = HUD_NODE_NAME
		# 标记实例根 -> pack 写成 instance=ExtResource(...)，本场景只 +1 个节点段
		hud.set("scene_file_path", HUD_PATH)
		fx.add_child(hud)
		hud.owner = root  # 实例根必须纳入 owner 链，否则 pack 会丢弃
		print("[R15] STEP4 HUD 实例已挂入 %s/%s" % [FXLAYER_PATH, HUD_NODE_NAME])
	# 重设 owner 链：跳过 scene_file_path 非空的实例化节点
	# （不递归进实例内部、不改实例内部子节点 owner，避免被展开成普通节点段）
	_reset_owner(root, root)

	# --- 5) pack 前后节点数比对 + 保存 + CACHE_MODE_IGNORE 回读 ---
	var packed: PackedScene = PackedScene.new()
	var pack_err: Error = packed.pack(root)
	if pack_err != OK:
		push_error("[R15] PackedScene.pack() 失败 err=%d，拒绝保存" % pack_err)
		_free_tree(root)
		quit(1)
		return
	var after_nodes: int = packed.get_state().get_node_count()

	# pack -> instantiate 往返探针：确认 HUD 实例能展开、内部节点完整
	var probe: Node = packed.instantiate()
	var probe_hud: Node = probe.get_node_or_null(FXLAYER_PATH + "/" + HUD_NODE_NAME)
	var probe_ok: bool = probe_hud != null \
		and probe_hud.get_node_or_null("HudPanel") != null \
		and probe_hud.get_node_or_null("TitleLabel") != null
	var probe_runtime_nodes: int = _count(probe)
	_free_tree(probe)

	var expected_before: int = EXPECTED_AFTER if had_hud else EXPECTED_BEFORE_FIRST
	var count_ok: bool = (before_nodes == expected_before) \
		and (after_nodes == EXPECTED_AFTER)
	print("[R15] STEP5 NODE_COUNT before=%d after=%d expected_before=%d expected_after=%d had_hud=%s count_ok=%s" % [
		before_nodes, after_nodes, expected_before, EXPECTED_AFTER, str(had_hud), str(count_ok)])
	print("[R15] STEP5 PROBE hud_present=%s runtime_nodes=%d (实例展开后整树)" % [
		str(probe_ok), probe_runtime_nodes])

	if not count_ok or not probe_ok:
		push_error("[R15] 节点数/结构比对失败，中止保存（场景零改动，不伪造输出）")
		_free_tree(root)
		quit(1)
		return
	_free_tree(root)

	var save_err: Error = ResourceSaver.save(packed, SCENE_PATH)
	if save_err != OK:
		push_error("[R15] ResourceSaver.save() 失败 err=%d，拒绝继续" % save_err)
		quit(1)
		return
	print("[R15] STEP5 SAVE_OK path=%s save_err=%d" % [SCENE_PATH, save_err])

	var verify_ok: bool = _verify()
	print("[R15] === ASSEMBLE R15 END verify_ok=%s ===" % str(verify_ok))
	quit(0 if verify_ok else 1)


func _backup() -> bool:
	if FileAccess.file_exists(BACKUP_ABS):
		print("[R15] STEP1 BACKUP 已存在，跳过（幂等）: %s" % BACKUP_ABS)
		return true
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(SCENE_PATH)
	if bytes.is_empty():
		push_error("[R15] STEP1 读取源场景字节失败 path=%s" % SCENE_PATH)
		return false
	var f: FileAccess = FileAccess.open(BACKUP_ABS, FileAccess.WRITE)
	if f == null:
		push_error("[R15] STEP1 打开备份路径失败 err=%d path=%s" % [
			FileAccess.get_open_error(), BACKUP_ABS])
		return false
	f.store_buffer(bytes)
	f.close()
	print("[R15] STEP1 BACKUP 写入 %d 字节 -> %s" % [bytes.size(), BACKUP_ABS])
	return true


func _verify() -> bool:
	# CACHE_MODE_IGNORE：不走资源缓存，强制从磁盘重读刚保存的 courtyard.tscn
	var ps: PackedScene = ResourceLoader.load(
			SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if ps == null:
		push_error("[R15_VERIFY] CACHE_MODE_IGNORE 回读失败 path=%s" % SCENE_PATH)
		return false
	var disk_nodes: int = ps.get_state().get_node_count()
	var inst: Node = ps.instantiate()
	var all_ok: bool = true

	# 三个材质非空
	for p in TERRAIN_PATHS:
		var mi: MeshInstance3D = inst.get_node_or_null(p) as MeshInstance3D
		var m: Material = mi.material_override if mi != null else null
		var ok: bool = m != null
		all_ok = all_ok and ok
		print("[R15_VERIFY] MATERIAL node=%s non_null=%s res=%s" % [
			str(p), str(ok), (m.resource_path if m != null else "<null>")])

	# HUD 实例存在（含 scene_file_path 标记与内部子节点）
	var hud: Node = inst.get_node_or_null(FXLAYER_PATH + "/" + HUD_NODE_NAME)
	var hud_present: bool = hud != null
	var hud_is_instance: bool = hud != null and hud.scene_file_path != ""
	var hud_children_ok: bool = hud != null \
		and hud.get_node_or_null("HudPanel") != null \
		and hud.get_node_or_null("TitleLabel") != null
	all_ok = all_ok and hud_present and hud_is_instance and hud_children_ok
	print("[R15_VERIFY] HUD present=%s is_instance=%s scene_file_path=%s children_ok=%s" % [
		str(hud_present), str(hud_is_instance),
		(hud.scene_file_path if hud != null else "<null>"), str(hud_children_ok)])

	# 节点数 23（SceneState 层）
	var nodes_ok: bool = (disk_nodes == EXPECTED_AFTER)
	all_ok = all_ok and nodes_ok
	var runtime_nodes: int = _count(inst)
	print("[R15_VERIFY] NODES SceneState=%d expected=%d ok=%s runtime=%d" % [
		disk_nodes, EXPECTED_AFTER, str(nodes_ok), runtime_nodes])
	print("[R15_VERIFY] CACHE_MODE_IGNORE 磁盘回读 OK=%s" % str(all_ok))
	_free_tree(inst)
	return all_ok


func _reset_owner(node: Node, owner_node: Node) -> void:
	# 重设 owner 链；跳过 scene_file_path 非空的实例化节点（不递归进其内部子节点）
	for child in node.get_children():
		if child.scene_file_path != "":
			continue
		child.owner = owner_node
		_reset_owner(child, owner_node)


func _count(node: Node) -> int:
	var n: int = 1
	for child in node.get_children():
		n += _count(child)
	return n


func _free_tree(node: Node) -> void:
	for child in node.get_children():
		_free_tree(child)
	node.free()
