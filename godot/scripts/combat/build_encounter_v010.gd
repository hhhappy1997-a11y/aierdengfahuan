extends SceneTree

## v0.1.0 · 构建可独立运行的遭遇战场景（SceneTree 构建脚本，无运行时逻辑）。
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path <godot> --script res://scripts/combat/build_encounter_v010.gd
## 生成：res://scenes/encounter_v010.tscn
## 复用件零改动；先 set_script 再赋 @export，owner 链 + pack 前后节点数比对，
## 依据 docs.godotengine.org/en/stable/classes/class_packedscene.html（Godot 4.x）。

const OUTPUT_SCENE: String = "res://scenes/encounter_v010.tscn"
const DIRECTOR_SCRIPT: String = "res://scripts/combat/encounter_director.gd"
const BOSS_SCRIPT: String = "res://scripts/combat/boss_controller.gd"
const BUS_SCRIPT: String = "res://scripts/combat/combat_event_bus.gd"
const RESOLVER_SCRIPT: String = "res://scripts/combat/combat_resolver.gd"
const BOSS_DATA: String = "res://data/combat/boss_01_margit.tres"
const EXPECTED_NODES: int = 6


func _initialize() -> void:
	print("[BUILD_V010] START")
	var director_script: Script = load(DIRECTOR_SCRIPT) as Script
	var boss_script: Script = load(BOSS_SCRIPT) as Script
	var bus_script: Script = load(BUS_SCRIPT) as Script
	var resolver_script: Script = load(RESOLVER_SCRIPT) as Script
	var boss_data: Resource = load(BOSS_DATA) as Resource
	if director_script == null or boss_script == null or bus_script == null or resolver_script == null or boss_data == null:
		push_error("[BUILD_V010] 依赖脚本或 boss_data 加载失败，拒绝构建")
		quit(1)
		return

	var root: Node = Node.new()
	root.name = "EncounterRoot"
	root.set_script(director_script)

	var boss: Node = Node3D.new()
	boss.name = "Boss"
	boss.set_script(boss_script)
	boss.set("boss_data", boss_data)
	# ../CombatEventBus 是兄弟节点，符合 BossController 默认 event_bus_path。
	root.add_child(boss)

	var bus: Node = Node.new()
	bus.name = "CombatEventBus"
	bus.set_script(bus_script)
	root.add_child(bus)

	var resolver: Node = Node.new()
	resolver.name = "CombatResolver"
	resolver.set_script(resolver_script)
	root.add_child(resolver)

	var hud: CanvasLayer = CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 20
	root.add_child(hud)

	var label: Label = Label.new()
	label.name = "StatusLabel"
	label.position = Vector2(24.0, 20.0)
	label.text = "遭遇战 v0.1.0 载入中…"
	label.set("theme_override_font_sizes/font_size", 18)
	label.set("theme_override_colors/font_color", Color(0.95, 0.82, 0.5, 1.0))
	hud.add_child(label)

	_set_owner(root, root)
	var before: int = _count(root)
	var packed: PackedScene = PackedScene.new()
	var pack_err: Error = packed.pack(root)
	if pack_err != OK:
		push_error("[BUILD_V010] pack 失败 err=%d" % pack_err)
		_free_tree(root)
		quit(1)
		return
	var probe: Node = packed.instantiate()
	var after: int = _count(probe)
	_free_tree(probe)
	print("[BUILD_V010] NODE_COUNT before=%d after=%d expected=%d pack_err=%d" % [before, after, EXPECTED_NODES, pack_err])
	if before != EXPECTED_NODES or after != before:
		push_error("[BUILD_V010] 节点数不符，拒绝保存（防静默丢节点）")
		_free_tree(root)
		quit(1)
		return

	var save_err: Error = ResourceSaver.save(packed, OUTPUT_SCENE)
	_free_tree(root)
	if save_err != OK:
		push_error("[BUILD_V010] 保存失败 err=%d" % save_err)
		quit(1)
		return

	var check: PackedScene = ResourceLoader.load(OUTPUT_SCENE, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if check == null:
		push_error("[BUILD_V010] CACHE_MODE_IGNORE 回读失败")
		quit(1)
		return
	var disk_nodes: int = check.get_state().get_node_count()
	var instance: Node = check.instantiate()
	var has_director: bool = instance.get_script() != null and instance.get_script().resource_path == DIRECTOR_SCRIPT
	var has_boss: bool = instance.get_node_or_null("Boss") != null
	var has_bus: bool = instance.get_node_or_null("CombatEventBus") != null
	var has_label: bool = instance.get_node_or_null("HUD/StatusLabel") != null
	_free_tree(instance)
	print("[BUILD_V010] READBACK disk_nodes=%d director=%s boss=%s bus=%s label=%s" % [
		disk_nodes, str(has_director), str(has_boss), str(has_bus), str(has_label)])
	var ok: bool = disk_nodes == EXPECTED_NODES and has_director and has_boss and has_bus and has_label
	print("[BUILD_V010] END ok=%s" % str(ok))
	quit(0 if ok else 1)


func _set_owner(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner_node
		_set_owner(child, owner_node)


func _count(node: Node) -> int:
	var total: int = 1
	for child: Node in node.get_children():
		total += _count(child)
	return total


func _free_tree(node: Node) -> void:
	for child: Node in node.get_children():
		_free_tree(child)
	node.free()
