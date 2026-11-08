extends SceneTree
## R3 构建脚本（唯一职责：程序化生成工程主场景 PackedScene）。
## 运行：godot --headless --path <工程根> --script res://scripts/build_main.gd
##   _initialize() 搭节点树 → 设置 owner 链 → PackedScene.pack() → instantiate() 比对节点数
##   → 比对通过才 ResourceSaver.save() 生成主场景 main.tscn（落位 res://scenes/Main.tscn，
##   即 project.godot 的 run/main_scene；手写 场景树骨架.tscn 保留为结构示意）。
##
## 约束（任务书 R3 §2 / 00-工具链接入说明.md §4.2）：
##  - 先叶子后父级设置 owner；scene_file_path 非空的实例化节点（GLB / 子场景）整棵跳过，
##    否则 pack() 会把子场景内联成上百 MB 文本。GLB 落地用 MeshInstance3D AABB 缩放 +
##    图元碰撞体，不用 create_trimesh_shape() / create_convex_shape()。
##  - 脚本内不得出现 _ready / _process / 信号连接 / 游戏状态；仅 _initialize() 一次性构建后退出。
##  - GDScript 全静态类型；不使用 := 接收无类型表达式。

const OUTPUT_SCENE_PATH: String = "res://scenes/Main.tscn"
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
        push_error("[build_main] PackedScene.pack() 失败 err=%d，拒绝保存" % pack_err)
        quit(1)
        return
    var probe: Node = packed.instantiate()
    var expected_count: int = _count_nodes(root)
    var actual_count: int = _count_nodes(probe)
    _free_tree(probe)
    if expected_count != actual_count:
        push_error("[build_main] 节点数比对失败 expected=%d actual=%d，拒绝保存" % [expected_count, actual_count])
        quit(1)
        return
    var save_err: int = ResourceSaver.save(packed, OUTPUT_SCENE_PATH)
    if save_err != OK:
        push_error("[build_main] ResourceSaver.save() 失败 err=%d path=%s" % [save_err, OUTPUT_SCENE_PATH])
        quit(1)
        return
    _free_tree(root)
    print("[build_main] BUILD_OK output=%s nodes=%d" % [OUTPUT_SCENE_PATH, expected_count])
    quit(0)


func _build_tree() -> Node3D:
    var root: Node3D = Node3D.new()
    root.name = "Main"

    var container: SubViewportContainer = SubViewportContainer.new()
    container.name = "SubViewportContainer"
    container.stretch = true
    container.stretch_shrink = INTEGER_UPSCALE_FACTOR
    container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    root.add_child(container)

    var viewport: SubViewport = SubViewport.new()
    viewport.name = "SubViewport"
    viewport.size = Vector2i(LOW_RESOLUTION_WIDTH, LOW_RESOLUTION_HEIGHT)
    viewport.own_world_3d = true
    container.add_child(viewport)

    var camera: Camera3D = Camera3D.new()
    camera.name = "Camera3D"
    camera.current = true
    camera.fov = 40.0
    viewport.add_child(camera)

    var sun: DirectionalLight3D = DirectionalLight3D.new()
    sun.name = "SunLight"
    sun.light_color = Color(1.0, 0.82, 0.55, 1.0)
    viewport.add_child(sun)

    var world_env: WorldEnvironment = WorldEnvironment.new()
    world_env.name = "WorldEnvironment"
    viewport.add_child(world_env)

    var ground: MeshInstance3D = MeshInstance3D.new()
    ground.name = "Ground"
    viewport.add_child(ground)

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

    var player: Node3D = Node3D.new()
    player.name = "Player"
    viewport.add_child(player)

    var rig: Node3D = Node3D.new()
    rig.name = "Hybrid2D3DAnimatedSprite"
    player.add_child(rig)

    var pixel_sprite: Sprite3D = Sprite3D.new()
    pixel_sprite.name = "PixelSprite"
    pixel_sprite.pixel_size = 1.0 / PIXELS_PER_METER
    pixel_sprite.centered = false
    rig.add_child(pixel_sprite)

    var chunk_root: Node3D = Node3D.new()
    chunk_root.name = "ChunkRoot"
    viewport.add_child(chunk_root)

    var fx_layer: CanvasLayer = CanvasLayer.new()
    fx_layer.name = "FXLayer"
    fx_layer.layer = 10
    viewport.add_child(fx_layer)

    var light_dust: Node2D = Node2D.new()
    light_dust.name = "LightDust"
    light_dust.visible = false
    fx_layer.add_child(light_dust)

    return root


func _assign_owner(node: Node, root: Node) -> void:
    ## 先叶子后父级；实例化子场景（scene_file_path 非空）整棵跳过，避免 GLB 内联成超大文本。
    ## 纯 new 出来的节点 scene_file_path 为空，全部纳入 owner 链。
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
    ## 构建脚本退出前递归释放内存节点树（后序：先子后父），避免 --script 自定义 MainLoop
    ## 退出时残留 RID / ObjectDB 实例。这是资源清理，不是游戏状态。
    var children: Array[Node] = node.get_children()
    var i: int = 0
    while i < children.size():
        _free_tree(children[i])
        i += 1
    node.free()
