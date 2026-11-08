extends SceneTree
## R4 构建脚本：程序化生成 M1 垂直切片主场景「3D 庭院」PackedScene。
## 运行：godot --headless --path <工程根> --script res://scripts/build_courtyard.gd
##   _initialize() 搭节点树 → 先叶子后父级设 owner 链 → PackedScene.pack()
##   → instantiate() 比对节点数 → 比对通过才 ResourceSaver.save() 生成
##   res://scenes/courtyard.tscn。
##
## 任务书 R4 交付要点：
##  - 3D 庭院：MeshInstance3D 地形（PlaneMesh 地面）+ 高低差（BoxMesh 台地 / 崖边），非 TileMap。
##  - 像素化：SubViewport 低分辨率 640x360 + SubViewportContainer stretch_shrink=2 + Nearest。
##  - 光照：DirectionalLight3D 暖金主光 + WorldEnvironment 冷色环境 / 冷夜雾。
##  - Player(Node3D) 下挂 Hybrid2D3DAnimatedSprite（即 HybridSpriteRig 薄封装，I-4 冻结，
##    set_pose 不扩展、pose 名冻结）；ChunkRoot 保持空 Node3D，避免与 autoload 双实例。
##
## 约束（R3 build_main.gd 同口径 / 00-工具链接入说明.md §4.2）：
##  - 先叶子后父级设置 owner；scene_file_path 非空的实例化子场景整棵跳过，防 pack 内联。
##  - 脚本内不得出现 _ready / _process / 信号连接 / 游戏状态；仅 _initialize() 一次性构建后退出。
##  - GDScript 全静态类型；不使用 := 接收无类型表达式；退出前 _free_tree() 后序释放内存节点，
##    消除 --script 退出时的 RID / ObjectDB 残留。
##  - 像素 128px 基准画布 + ≤256 色索引调色板由 4 号 I-5 落位，本脚本不定义美术资源。

const OUTPUT_SCENE_PATH: String = "res://scenes/courtyard.tscn"
const HYBRID_SCRIPT_PATH: String = "res://scripts/render/hybrid_2d3d_animated_sprite.gd"
const LOW_RESOLUTION_WIDTH: int = 640
const LOW_RESOLUTION_HEIGHT: int = 360
const INTEGER_UPSCALE_FACTOR: int = 2
const PIXELS_PER_METER: float = 32.0


func _initialize() -> void:
	var root: Node3D = _build_tree()
	_assign_owner(root, root)
	var packed: PackedScene = PackedScene.new()
	var pack_err: int = packed.pack(root)
	if pack_err != OK:
		push_error("[courtyard] PackedScene.pack() 失败 err=%d，拒绝保存" % pack_err)
		_free_tree(root)
		quit(1)
		return
	var probe: Node = packed.instantiate()
	var expected_count: int = _count_nodes(root)
	var actual_count: int = _count_nodes(probe)
	_free_tree(probe)
	if expected_count != actual_count:
		push_error("[courtyard] 节点数比对失败 expected=%d actual=%d，拒绝保存" % [expected_count, actual_count])
		_free_tree(root)
		quit(1)
		return
	var save_err: int = ResourceSaver.save(packed, OUTPUT_SCENE_PATH)
	if save_err != OK:
		push_error("[courtyard] ResourceSaver.save() 失败 err=%d path=%s" % [save_err, OUTPUT_SCENE_PATH])
		_free_tree(root)
		quit(1)
		return
	_free_tree(root)
	print("[courtyard] BUILD_OK output=%s nodes=%d" % [OUTPUT_SCENE_PATH, expected_count])
	quit(0)


func _build_tree() -> Node3D:
	# ---- 根 / 像素化链路 ----
	var root: Node3D = Node3D.new()
	root.name = "Courtyard"

	var container: SubViewportContainer = SubViewportContainer.new()
	container.name = "SubViewportContainer"
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.stretch_shrink = INTEGER_UPSCALE_FACTOR
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(container)

	var viewport: SubViewport = SubViewport.new()
	viewport.name = "SubViewport"
	viewport.size = Vector2i(LOW_RESOLUTION_WIDTH, LOW_RESOLUTION_HEIGHT)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)

	# ---- 相机（HD-2D 斜俯视）----
	var camera: Camera3D = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0.0, 12.0, 18.0)
	camera.rotation_degrees = Vector3(-30.0, 0.0, 0.0)
	camera.current = true
	camera.fov = 40.0
	camera.near = 0.1
	camera.far = 400.0
	viewport.add_child(camera)

	# ---- 暖金主光 + 冷色环境 ----
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "SunLight"
	sun.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	sun.light_color = Color(1.0, 0.82, 0.55, 1.0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	viewport.add_child(sun)

	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = _make_environment()
	viewport.add_child(world_env)

	# ---- 3D 庭院地形（MeshInstance3D + 高低差）----
	var terrain: Node3D = Node3D.new()
	terrain.name = "Terrain"
	viewport.add_child(terrain)

	var ground_plane: PlaneMesh = PlaneMesh.new()
	ground_plane.size = Vector2(64.0, 64.0)
	terrain.add_child(_make_mesh_instance(
		"GroundPlate", ground_plane,
		_make_material(Color(0.14, 0.17, 0.20, 1.0)),
		Vector3(0.0, 0.0, 0.0)))

	var terrace_low_box: BoxMesh = BoxMesh.new()
	terrace_low_box.size = Vector3(12.0, 0.6, 12.0)
	terrain.add_child(_make_mesh_instance(
		"TerraceLow", terrace_low_box,
		_make_material(Color(0.20, 0.24, 0.27, 1.0)),
		Vector3(8.0, 0.3, -6.0)))

	var terrace_high_box: BoxMesh = BoxMesh.new()
	terrace_high_box.size = Vector3(8.0, 1.2, 8.0)
	terrain.add_child(_make_mesh_instance(
		"TerraceHigh", terrace_high_box,
		_make_material(Color(0.24, 0.28, 0.30, 1.0)),
		Vector3(-9.0, 0.6, -8.0)))

	var cliff_box: BoxMesh = BoxMesh.new()
	cliff_box.size = Vector3(64.0, 2.0, 2.0)
	terrain.add_child(_make_mesh_instance(
		"CliffRim", cliff_box,
		_make_material(Color(0.10, 0.12, 0.15, 1.0)),
		Vector3(0.0, -1.0, 20.0)))

	# ---- 视差背景 / 湿地倒影占位（R2/R3 既有结构，保留）----
	var backdrop_far: Node3D = Node3D.new()
	backdrop_far.name = "BackdropFar"
	viewport.add_child(backdrop_far)

	var backdrop_mid: Node3D = Node3D.new()
	backdrop_mid.name = "BackdropMid"
	viewport.add_child(backdrop_mid)

	var wet_reflection: Node3D = Node3D.new()
	wet_reflection.name = "WetReflection"
	wet_reflection.visible = false
	viewport.add_child(wet_reflection)

	# ---- Player + I-4 Hybrid2D3DAnimatedSprite ----
	var player: Node3D = Node3D.new()
	player.name = "Player"
	viewport.add_child(player)

	var rig: Node3D = Node3D.new()
	rig.name = "Hybrid2D3DAnimatedSprite"
	var hybrid_script: Script = load(HYBRID_SCRIPT_PATH) as Script
	if hybrid_script != null:
		rig.set_script(hybrid_script)
	else:
		push_warning("[courtyard] 未找到 %s，Hybrid2D3DAnimatedSprite 降级为纯 Node3D。" % HYBRID_SCRIPT_PATH)
	player.add_child(rig)

	var pixel_sprite: Sprite3D = Sprite3D.new()
	pixel_sprite.name = "PixelSprite"
	pixel_sprite.pixel_size = 1.0 / PIXELS_PER_METER
	pixel_sprite.centered = false
	pixel_sprite.offset = Vector2(-16.0, -48.0)
	rig.add_child(pixel_sprite)

	# ---- ChunkRoot（空 Node3D，脚本由 ChunkManager autoload 持有，避免双实例）----
	var chunk_root: Node3D = Node3D.new()
	chunk_root.name = "ChunkRoot"
	viewport.add_child(chunk_root)

	# ---- FX 层 ----
	var fx_layer: CanvasLayer = CanvasLayer.new()
	fx_layer.name = "FXLayer"
	fx_layer.layer = 10
	viewport.add_child(fx_layer)

	var light_dust: Node2D = Node2D.new()
	light_dust.name = "LightDust"
	light_dust.visible = false
	fx_layer.add_child(light_dust)

	return root


func _make_environment() -> Environment:
	## 冷色环境 / 冷夜雾（暖金主光 × 冷夜雾强对比）。数值沿用 R2 场景树骨架.tscn 已验证值。
	var env: Environment = Environment.new()
	env.background_mode = 1
	env.background_color = Color(0.07, 0.10, 0.16, 1.0)
	env.ambient_light_source = 2
	env.ambient_light_color = Color(0.28, 0.36, 0.52, 1.0)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = 2
	env.glow_enabled = false
	env.fog_enabled = true
	env.fog_light_color = Color(0.32, 0.42, 0.60, 1.0)
	env.fog_density = 0.008
	return env


func _make_material(color: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mat.metallic = 0.0
	return mat


func _make_mesh_instance(node_name: String, mesh: Mesh, mat: StandardMaterial3D, pos: Vector3) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	return mi


func _assign_owner(node: Node, root: Node) -> void:
	## 先叶子后父级；实例化子场景（scene_file_path 非空）整棵跳过，避免 GLB 内联成超大文本。
	if node != root and not node.scene_file_path.is_empty():
		return
	var children: Array[Node] = node.get_children()
	var i: int = 0
	while i < children.size():
		var child: Node = children[i]
		_assign_owner(child, root)
		i += 1
	if node != root and node.scene_file_path.is_empty():
		node.owner = root


func _count_nodes(node: Node) -> int:
	var total: int = 1
	var children: Array[Node] = node.get_children()
	var i: int = 0
	while i < children.size():
		var child: Node = children[i]
		total += _count_nodes(child)
		i += 1
	return total


func _free_tree(node: Node) -> void:
	## 后序递归释放内存节点树，避免 --script 自定义 MainLoop 退出时残留 RID / ObjectDB 实例。
	var children: Array[Node] = node.get_children()
	var i: int = 0
	while i < children.size():
		_free_tree(children[i])
		i += 1
	node.free()
