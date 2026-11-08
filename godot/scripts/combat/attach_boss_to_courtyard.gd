extends SceneTree
## R7 · 追加式接入脚本：把 BossController 接进 courtyard.tscn 的敌人节点（Rank-2）。
## 运行：godot --headless --path <工程根> --script res://scripts/combat/attach_boss_to_courtyard.gd
##
## 【不覆盖既有场景】本脚本只读 load() 既有 courtyard.tscn 并 instantiate()，
##   全部接线以 add_child() 追加在实例上；既不 ResourceSaver.save() 回原路径、也不改动
##   任何既有节点。产物另存为新场景 res://data/combat/courtyard_with_boss.tscn
##   （独立场景实例化产物，落在 2 号唯一可写范围 godot\data\combat\）。
##
## 【接入点】res://scenes/courtyard.tscn 实例树里
##   SubViewportContainer/SubViewport/ChunkRoot
##   理由：build_courtyard.gd:173-176 把 ChunkRoot 定义为「空 Node3D，脚本由 ChunkManager
##   autoload 持有，避免双实例」，是 I-3 敌人 / chunk 动态生成的预留锚点；它与 Player 同为
##   SubViewport 直接子节点，3D 世界层级正确。R7 开工实测 courtyard.tscn 原文
##   grep enemy|boss|spawn|defeat = 0 命中（无现成敌人节点），故敌人节点由本脚本追加，
##   不是修改既有节点；接入点即 ChunkRoot，追加节点名 BossEnemy_01。
##
## 【追加的节点树】三个逻辑子节点互为兄弟，满足 boss_controller.gd:55-56 的
##   ../Hybrid2D3DAnimatedSprite 与 ../CombatEventBus 相对 NodePath：
##   ChunkRoot
##   └── BossEnemy_01 (Node3D)
##       ├── Hybrid2D3DAnimatedSprite (Node3D, 挂 Rank-1 hybrid_2d3d_animated_sprite.gd)
##       │   └── PixelSprite (Sprite3D)          ← HybridSpriteRig.sprite_node_path 所需
##       ├── CombatEventBus (Node, 挂 res://scripts/combat/combat_event_bus.gd)  ← I-2 唯一发射点
##       └── BossController (Node, 挂 res://scripts/combat/boss_controller.gd,
##                           boss_data = res://data/combat/boss_01_margit.tres)   ← M5 控制器
##
## 【边界】不改既有 .gd / .tres 数值（E-8 三项阈值一字未动）、不写 project.godot、
##   不写其它工位；其余两处跨工位文件均为只读 load() 引用。
## 引擎：Godot 4 标准版 / GDScript，全静态类型；中文 UTF-8。

const SOURCE_SCENE: String = "res://scenes/courtyard.tscn"
const OUTPUT_SCENE: String = "res://data/combat/courtyard_with_boss.tscn"
const ENEMY_ANCHOR: String = "SubViewportContainer/SubViewport/ChunkRoot"
const BOSS_NODE_NAME: String = "BossEnemy_01"
const BOSS_DATA_PATH: String = "res://data/combat/boss_01_margit.tres"
const COMBAT_BUS_PATH: String = "res://scripts/combat/combat_event_bus.gd"
const BOSS_CTRL_PATH: String = "res://scripts/combat/boss_controller.gd"
const HYBRID_SCRIPT_PATH: String = "res://scripts/render/hybrid_2d3d_animated_sprite.gd"


func _initialize() -> void:
	var src: PackedScene = load(SOURCE_SCENE) as PackedScene
	if src == null:
		push_error("[attach-boss] 无法加载既有场景 %s" % SOURCE_SCENE)
		quit(1)
		return
	var root: Node = src.instantiate()
	var anchor: Node = root.get_node_or_null(ENEMY_ANCHOR)
	if anchor == null:
		push_error("[attach-boss] 未找到接入点 %s" % ENEMY_ANCHOR)
		_free_tree(root)
		quit(1)
		return

	var before_count: int = _count_nodes(root)
	var boss_node: Node3D = _build_boss_enemy()
	anchor.add_child(boss_node)
	_assign_owner_added(boss_node, root)
	var after_count: int = _count_nodes(root)

	# 真跑验证：pack -> instantiate -> 节点数 / 结构比对
	var packed: PackedScene = PackedScene.new()
	var pack_err: int = packed.pack(root)
	if pack_err != OK:
		push_error("[attach-boss] PackedScene.pack() 失败 err=%d" % pack_err)
		_free_tree(root)
		quit(1)
		return
	var probe: Node = packed.instantiate()
	var probe_count: int = _count_nodes(probe)
	var probe_boss: Node = probe.get_node_or_null(ENEMY_ANCHOR + "/" + BOSS_NODE_NAME)
	var probe_ok: bool = probe_boss != null \
		and probe_boss.get_node_or_null("BossController") != null \
		and probe_boss.get_node_or_null("CombatEventBus") != null \
		and probe_boss.get_node_or_null("Hybrid2D3DAnimatedSprite") != null
	_free_tree(probe)
	if probe_count != after_count or not probe_ok:
		push_error("[attach-boss] 节点数/结构比对失败 before=%d after=%d probe=%d probe_ok=%s" % [
			before_count, after_count, probe_count, str(probe_ok)])
		_free_tree(root)
		quit(1)
		return

	# 另存新场景（不写回 courtyard.tscn，不覆盖既有场景）
	var save_err: int = ResourceSaver.save(packed, OUTPUT_SCENE)
	if save_err != OK:
		push_error("[attach-boss] 另存新场景失败 err=%d path=%s" % [save_err, OUTPUT_SCENE])
		_free_tree(root)
		quit(1)
		return
	_free_tree(root)

	print("[attach-boss] ATTACH_OK source=%s (只读加载, 未覆盖) output=%s" % [SOURCE_SCENE, OUTPUT_SCENE])
	print("[attach-boss] 接入点=%s/%s before_nodes=%d after_nodes=%d added=%d probe_nodes=%d probe_ok=%s" % [
		ENEMY_ANCHOR, BOSS_NODE_NAME, before_count, after_count,
		after_count - before_count, probe_count, str(probe_ok)])
	quit(0)


func _build_boss_enemy() -> Node3D:
	var enemy: Node3D = Node3D.new()
	enemy.name = BOSS_NODE_NAME

	# I-4 精灵节点：只读引用 Rank-1 真实 HybridSpriteRig（不改他人文件）
	var rig: Node3D = Node3D.new()
	rig.name = "Hybrid2D3DAnimatedSprite"
	var hybrid: Script = load(HYBRID_SCRIPT_PATH) as Script
	if hybrid != null:
		rig.set_script(hybrid)
	var pixel: Sprite3D = Sprite3D.new()
	pixel.name = "PixelSprite"
	pixel.centered = false
	pixel.offset = Vector2(-16.0, -48.0)
	pixel.pixel_size = 1.0 / 32.0
	rig.add_child(pixel)
	enemy.add_child(rig)

	# I-2 唯一对外发射点
	var bus: Node = Node.new()
	bus.name = "CombatEventBus"
	var bus_script: Script = load(COMBAT_BUS_PATH) as Script
	if bus_script != null:
		bus.set_script(bus_script)
	enemy.add_child(bus)

	# M5 Boss 控制器 + 数据表注入（数值一字未改）
	var ctrl: Node = Node.new()
	ctrl.name = "BossController"
	var ctrl_script: Script = load(BOSS_CTRL_PATH) as Script
	if ctrl_script != null:
		ctrl.set_script(ctrl_script)
	var data: Resource = load(BOSS_DATA_PATH)
	ctrl.set("boss_data", data)
	enemy.add_child(ctrl)

	return enemy


func _assign_owner_added(node: Node, root: Node) -> void:
	## 只给追加的子树设 owner=root，使 PackedScene.pack() 能包含新节点；
	## 既有场景节点 owner 已由 instantiate() 指向 root，不改动。
	var children: Array[Node] = node.get_children()
	var i: int = 0
	while i < children.size():
		_assign_owner_added(children[i], root)
		i += 1
	node.owner = root


func _count_nodes(node: Node) -> int:
	var total: int = 1
	var children: Array[Node] = node.get_children()
	var i: int = 0
	while i < children.size():
		total += _count_nodes(children[i])
		i += 1
	return total


func _free_tree(node: Node) -> void:
	## 后序释放内存节点树，避免 --script 自定义 MainLoop 退出时残留 RID / ObjectDB 实例。
	var children: Array[Node] = node.get_children()
	var i: int = 0
	while i < children.size():
		_free_tree(children[i])
		i += 1
	node.free()
