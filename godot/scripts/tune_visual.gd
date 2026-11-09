extends SceneTree
# R13 画面整改（cmd-20261109-080019-791-A1）：补暖金主光 + 相机温和拉近。
# 参考 attach_pose_frames.gd 的 SceneTree 构建 / pack / 回读模式。
# 真跑：godot --headless --path godot --script res://scripts/tune_visual.gd
# 门禁：godot --headless --path godot --check-only --script res://scripts/tune_visual.gd

const SCENE_PATH: String = "res://scenes/courtyard.tscn"
const SUN_PATH: String = "SubViewportContainer/SubViewport/SunLight"
const CAM_PATH: String = "SubViewportContainer/SubViewport/Camera3D"

# 1) 暖金主光：比原 Color(1, 0.82, 0.55) 更暖、更金；能量 1.6 -> 1.8
const WARM_COLOR: Color = Color(1.0, 0.78, 0.45)
const WARM_ENERGY: float = 1.8

# 2) 相机温和拉近：把 origin 从 (0, 12, 18) 沿指向场景中心的方向移到 (0, 9.6, 14.4)
#    （约 20% 拉近，角色占比约 +25%）。只改 origin，保持 basis/朝向与 fov=40 不变，
#    注视点仍落在 (0, 0, ~-2) 附近，构图不破坏。用绝对目标值保证脚本幂等。
const CAM_TARGET_ORIGIN: Vector3 = Vector3(0.0, 9.6, 14.4)

# 节点数硬门槛：pack 前 / 后都必须为 22，且彼此一致，否则中止保存
const EXPECTED_NODES: int = 22

# 关于 glow（任务第 4 点「仅能真跑验证时做」）：
# 本工程 project.godot renderer/rendering_method = "gl_compatibility"，
# GL Compatibility 渲染后端不支持 Environment glow 后处理，无法真跑验证效果。
# 按任务口径登记为「未做」，不写入在该后端下无效的 glow 属性以免冒充完成。


func _initialize() -> void:
	var ps: PackedScene = load(SCENE_PATH) as PackedScene
	if ps == null:
		push_error("[TUNE] courtyard.tscn load failed")
		quit(1)
		return
	var root: Node = ps.instantiate()

	var sun: Node = root.get_node_or_null(SUN_PATH)
	var cam: Node = root.get_node_or_null(CAM_PATH)
	if sun == null or not (sun is DirectionalLight3D):
		push_error("[TUNE] SunLight missing / not DirectionalLight3D")
		root.free()
		quit(1)
		return
	if cam == null or not (cam is Camera3D):
		push_error("[TUNE] Camera3D missing / not Camera3D")
		root.free()
		quit(1)
		return

	var sun_light: DirectionalLight3D = sun as DirectionalLight3D
	var camera: Camera3D = cam as Camera3D
	print("[TUNE] BEFORE sun_color=", sun_light.light_color,
			" sun_energy=", sun_light.light_energy,
			" cam_origin=", camera.transform.origin, " fov=", camera.fov)

	# 1) 暖金主光
	sun_light.light_color = WARM_COLOR
	sun_light.light_energy = WARM_ENERGY

	# 2) 相机温和拉近（只改 origin，保持朝向 / 构图 / fov）
	var t: Transform3D = camera.transform
	t.origin = CAM_TARGET_ORIGIN
	camera.transform = t

	print("[TUNE] AFTER  sun_color=", sun_light.light_color,
			" sun_energy=", sun_light.light_energy,
			" cam_origin=", camera.transform.origin, " fov=", camera.fov)

	# 3) 重设 owner 链（pack 前必须，否则子场景节点不会被序列化）
	_set_owner(root, root)

	# 4) pack 前节点数
	var before: int = _count(root)

	# 5) pack + 重新 instantiate 比对节点数
	var packed: PackedScene = PackedScene.new()
	var err_pack: Error = packed.pack(root)
	var test: Node = packed.instantiate()
	var after: int = _count(test)
	print("[TUNE] pack_err=", err_pack, " nodes_before=", before,
			" nodes_after=", after, " expect=", EXPECTED_NODES)
	if err_pack != OK or before != EXPECTED_NODES or after != EXPECTED_NODES or before != after:
		push_error("[TUNE] node count / pack guard failed, abort save")
		test.free()
		root.free()
		quit(1)
		return
	test.free()

	# 6) 保存（覆盖 courtyard.tscn；改动前已备份到 _archived_20261108/）
	var err_save: Error = ResourceSaver.save(packed, SCENE_PATH)
	print("[TUNE] save_err=", err_save)
	root.free()
	if err_save != OK:
		push_error("[TUNE] save failed")
		quit(1)
		return

	# 7) 绕过本进程资源缓存，从磁盘回读确认光色 / 相机变更确实落盘
	_verify()
	quit(0)


func _set_owner(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		if child.scene_file_path != "":
			continue
		child.owner = owner_node
		_set_owner(child, owner_node)


func _count(node: Node) -> int:
	var n: int = 1
	for child: Node in node.get_children():
		n += _count(child)
	return n


func _verify() -> void:
	# CACHE_MODE_IGNORE 强制重新从磁盘读取刚保存的场景，不命中本进程缓存
	var ps: PackedScene = ResourceLoader.load(
			SCENE_PATH, "PackedScene",
			ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if ps == null:
		push_error("[TUNE_VERIFY] re-load from disk failed")
		return
	var root: Node = ps.instantiate()
	var sun_light: DirectionalLight3D = root.get_node_or_null(SUN_PATH) as DirectionalLight3D
	var camera: Camera3D = root.get_node_or_null(CAM_PATH) as Camera3D
	var nodes: int = _count(root)
	var color_ok: bool = sun_light != null and sun_light.light_color.is_equal_approx(WARM_COLOR)
	var energy_ok: bool = sun_light != null and is_equal_approx(sun_light.light_energy, WARM_ENERGY)
	var cam_ok: bool = camera != null and camera.transform.origin.is_equal_approx(CAM_TARGET_ORIGIN)
	print("[TUNE_VERIFY] nodes=", nodes,
			" sun_color=", (sun_light.light_color if sun_light != null else Color(0, 0, 0)),
			" sun_energy=", (sun_light.light_energy if sun_light != null else -1.0),
			" cam_origin=", (camera.transform.origin if camera != null else Vector3.ZERO),
			" color_ok=", color_ok, " energy_ok=", energy_ok, " cam_ok=", cam_ok,
			" nodes_ok=", nodes == EXPECTED_NODES,
			" OK=", (color_ok and energy_ok and cam_ok and nodes == EXPECTED_NODES))
	root.free()
