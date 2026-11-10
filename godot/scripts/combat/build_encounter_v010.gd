extends SceneTree

## v0.1.0 · 构建可独立运行的遭遇战场景（SceneTree 构建脚本，无运行时逻辑）。
## R25 · Rank-1：给 Boss 补可见形象 —— Boss 节点下挂 Hybrid2D3DAnimatedSprite +
##   AnimatedSprite3D，绑定既有 res://assets/generated/boss/boss_spriteframes.tres，
##   并把 BossController.sprite_path 指向该 Hybrid 节点，使 set_pose(pose_name, frame_index)
##   真正有消费方。素材 PNG / .tres 零改动（只引用既有资源）。
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path <godot> \
##       --script res://scripts/combat/build_encounter_v010.gd
## 生成：res://scenes/encounter_v010.tscn
## 复用件零改动；先 set_script 再赋 @export，owner 链 + pack 前后节点数比对，
## 依据 docs.godotengine.org/en/stable/classes/class_packedscene.html（Godot 4.x）。
## 项目既有踩坑：SceneTree --script 模式 add_child 不 flush _ready，故全部用 set()/属性
##   直接赋值、不依赖 _ready；CACHE_MODE_IGNORE 磁盘回读校验（R24 经验）。
## R24 经验：instance 内部属性覆盖在 pack 时可能丢失，需追加覆盖段再回读验证；本脚本末尾
##   对 courtyard.tscn 的 EncounterRoot/Boss 覆盖段做等价只读回读（不写 courtyard）。
## 引擎：Godot 4.7.2 / GDScript / 全静态类型 / 中文 UTF-8。

const OUTPUT_SCENE: String = "res://scenes/encounter_v010.tscn"
const COURTYARD_SCENE: String = "res://scenes/courtyard.tscn"
const DIRECTOR_SCRIPT: String = "res://scripts/combat/encounter_director.gd"
const BOSS_SCRIPT: String = "res://scripts/combat/boss_controller.gd"
const BUS_SCRIPT: String = "res://scripts/combat/combat_event_bus.gd"
const RESOLVER_SCRIPT: String = "res://scripts/combat/combat_resolver.gd"
const BOSS_DATA: String = "res://data/combat/boss_01_margit.tres"
const HYBRID_SCRIPT: String = "res://scripts/render/hybrid_2d3d_animated_sprite.gd"
const BOSS_SPRITEFRAMES: String = "res://assets/generated/boss/boss_spriteframes.tres"
const EXPECTED_NODES: int = 8
const HYBRID_NODE_NAME: String = "Hybrid2D3DAnimatedSprite"
const PIXEL_NODE_NAME: String = "PixelSprite"
const BOSS_ANIMATION: StringName = &"p1_dagger_slash"
const BOSS_PIXEL_SCALE: float = 1.6
# courtyard.tscn 的 SubViewport 内可见 rig 路径（R25 接线目标）
const COURTYARD_BOSS_RIG: String = "SubViewportContainer/SubViewport/BossVisual/Hybrid2D3DAnimatedSprite"
# 从 EncounterRoot/Boss 出发指向上述 rig 的跨树相对路径
const COURTYARD_BOSS_SPRITE_PATH: String = "../../SubViewportContainer/SubViewport/BossVisual/Hybrid2D3DAnimatedSprite"


func _initialize() -> void:
	print("[BUILD_V010] START R25")
	var director_script: Script = load(DIRECTOR_SCRIPT) as Script
	var boss_script: Script = load(BOSS_SCRIPT) as Script
	var bus_script: Script = load(BUS_SCRIPT) as Script
	var resolver_script: Script = load(RESOLVER_SCRIPT) as Script
	var boss_data: Resource = load(BOSS_DATA) as Resource
	var hybrid_script: Script = load(HYBRID_SCRIPT) as Script
	var boss_frames: SpriteFrames = load(BOSS_SPRITEFRAMES) as SpriteFrames
	if director_script == null or boss_script == null or bus_script == null \
			or resolver_script == null or boss_data == null or hybrid_script == null or boss_frames == null:
		push_error("[BUILD_V010] 依赖脚本/资源加载失败，拒绝构建")
		quit(1)
		return

	var root: Node = Node.new()
	root.name = "EncounterRoot"
	root.set_script(director_script)

	var boss: Node = Node3D.new()
	boss.name = "Boss"
	boss.set_script(boss_script)
	boss.set("boss_data", boss_data)
	# I-4 接线：sprite_path 指向 Boss 子树下的 Hybrid 节点（独立场景运行时 set_pose 消费方）。
	boss.set("sprite_path", NodePath(HYBRID_NODE_NAME))
	root.add_child(boss)

	# Boss 可见形象：Hybrid2D3DAnimatedSprite + AnimatedSprite3D，绑定既有 boss_spriteframes.tres。
	var hybrid: Node = Node3D.new()
	hybrid.name = HYBRID_NODE_NAME
	hybrid.set_script(hybrid_script)
	# Boss 每个动画仅 1 帧；把动作内帧数钉死为 1，使 set_pose 的 frame_index clamp 到 0，
	# 避免 BossController 推进到数十帧时 AnimatedSprite3D.frame 越界。
	hybrid.set("pose_frame_counts", {"dagger_slash": 1, "staff_slam": 1, "holy_hammer": 1})
	# R25 真跑结论（如实登记）：精灵 quad 位置由 frame_size/offset/scale 组合决定。
	#   frame_size=128 时 _configure_anchor() 把 offset 设为 (-64,-128)，配合 scale=0.65
	#   会把 Boss quad 移出可见区域（画面不出现第二个角色）。改用与 Player 一致的可行配置
	#   （frame_size 默认 / scale 1.6 / offset (-16,-48)），并关闭 auto_aabb 避免
	#   custom_aabb 剔除；courtyard.tscn 的可见 rig 完全同口径。
	hybrid.set("auto_aabb", false)
	boss.add_child(hybrid)

	var pixel: AnimatedSprite3D = AnimatedSprite3D.new()
	pixel.name = PIXEL_NODE_NAME
	pixel.scale = Vector3(BOSS_PIXEL_SCALE, BOSS_PIXEL_SCALE, BOSS_PIXEL_SCALE)
	pixel.centered = false
	pixel.offset = Vector2(-16, -48)
	pixel.pixel_size = 0.03125
	pixel.sprite_frames = boss_frames
	pixel.animation = BOSS_ANIMATION
	hybrid.add_child(pixel)

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
	print("[BUILD_V010] NODE_COUNT before=%d after=%d expected=%d pack_err=%d" % [
		before, after, EXPECTED_NODES, pack_err])
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

	# CACHE_MODE_IGNORE 磁盘回读（含节点数、脚本、精灵资源、sprite_path 接线）
	var check: PackedScene = ResourceLoader.load(
			OUTPUT_SCENE, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if check == null:
		push_error("[BUILD_V010] CACHE_MODE_IGNORE 回读失败")
		quit(1)
		return
	var disk_nodes: int = check.get_state().get_node_count()
	var instance: Node = check.instantiate()
	var has_director: bool = instance.get_script() != null and instance.get_script().resource_path == DIRECTOR_SCRIPT
	var boss_rb: Node = instance.get_node_or_null("Boss")
	var hybrid_rb: Node = instance.get_node_or_null("Boss/" + HYBRID_NODE_NAME)
	var pixel_rb: Node = instance.get_node_or_null("Boss/" + HYBRID_NODE_NAME + "/" + PIXEL_NODE_NAME)
	var has_bus: bool = instance.get_node_or_null("CombatEventBus") != null
	var has_label: bool = instance.get_node_or_null("HUD/StatusLabel") != null
	var sprite_path_ok: bool = boss_rb != null \
			and NodePath(str(boss_rb.get("sprite_path"))) == NodePath(HYBRID_NODE_NAME)
	var rig_has_set_pose: bool = hybrid_rb != null and hybrid_rb.has_method("set_pose")
	var frames_ok: bool = pixel_rb != null and pixel_rb.get("sprite_frames") != null \
			and pixel_rb.get("sprite_frames").resource_path == BOSS_SPRITEFRAMES
	var anim_ok: bool = pixel_rb != null and StringName(str(pixel_rb.get("animation"))) == BOSS_ANIMATION
	var local_consumer: Node = null
	if boss_rb != null:
		local_consumer = boss_rb.get_node_or_null(NodePath(str(boss_rb.get("sprite_path"))))
	var local_consumer_ok: bool = local_consumer != null and local_consumer.has_method("set_pose")
	print("[BUILD_V010] READBACK disk_nodes=%d director=%s boss=%s bus=%s label=%s" % [
		disk_nodes, str(has_director), str(boss_rb != null), str(has_bus), str(has_label)])
	print("[BUILD_V010] WIRING hybrid=%s pixel=%s sprite_path=%s rig_has_set_pose=%s frames_bound=%s animation=%s local_consumer=%s" % [
		str(hybrid_rb != null), str(pixel_rb != null), str(sprite_path_ok), str(rig_has_set_pose),
		str(frames_ok), str(anim_ok), str(local_consumer_ok)])
	# ok 必须在 _free_tree(instance) 之前求值：释放后节点引用与 null 的比较结果不再可靠。
	var ok: bool = disk_nodes == EXPECTED_NODES and has_director and boss_rb != null \
			and has_bus and has_label and sprite_path_ok and rig_has_set_pose \
			and frames_ok and anim_ok and local_consumer_ok
	print("[BUILD_V010] OK_PARTS disk=%s director=%s boss=%s bus=%s label=%s sp=%s rig=%s frames=%s anim=%s consumer=%s" % [
		str(disk_nodes == EXPECTED_NODES), str(has_director), str(boss_rb != null),
		str(has_bus), str(has_label), str(sprite_path_ok), str(rig_has_set_pose),
		str(frames_ok), str(anim_ok), str(local_consumer_ok)])
	_free_tree(instance)

	# R24 经验：instance 内部属性覆盖在 pack 时可能丢失，需追加覆盖段再回读验证。
	# 这里对 courtyard.tscn 的 EncounterRoot/Boss 覆盖段做等价只读回读（不写 courtyard）。
	_verify_courtyard_override()

	print("[BUILD_V010] END ok=%s" % str(ok))
	quit(0 if ok else 1)


func _verify_courtyard_override() -> void:
	var ps: PackedScene = ResourceLoader.load(
			COURTYARD_SCENE, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if ps == null:
		print("[BUILD_V010] COURTYARD_READBACK skip load_failed")
		return
	var inst: Node = ps.instantiate()
	var boss: Node = inst.get_node_or_null("EncounterRoot/Boss")
	var visual_rig: Node = inst.get_node_or_null(COURTYARD_BOSS_RIG)
	var disk_nodes: int = ps.get_state().get_node_count()
	if boss == null or visual_rig == null:
		print("[BUILD_V010] COURTYARD_READBACK skip disk_nodes=%d boss=%s visual_rig=%s（courtyard 尚未接线）" % [
			disk_nodes, str(boss != null), str(visual_rig != null)])
		_free_tree(inst)
		return
	var sp: NodePath = NodePath(str(boss.get("sprite_path")))
	var resolved: Node = boss.get_node_or_null(sp)
	var override_ok: bool = str(sp) == COURTYARD_BOSS_SPRITE_PATH \
			and resolved != null and resolved == visual_rig and resolved.has_method("set_pose")
	var visual_pixel: Node = inst.get_node_or_null(COURTYARD_BOSS_RIG + "/" + PIXEL_NODE_NAME)
	var visual_frames_ok: bool = visual_pixel != null and visual_pixel.get("sprite_frames") != null \
			and visual_pixel.get("sprite_frames").resource_path == BOSS_SPRITEFRAMES
	print("[BUILD_V010] COURTYARD_READBACK disk_nodes=%d boss_sprite_path=%s resolved=%s override_ok=%s visual_frames_bound=%s" % [
		disk_nodes, str(sp), str(resolved != null), str(override_ok), str(visual_frames_ok)])
	# R25 渲染前置回读：--script 模式不 flush _ready，显式触发 rig 的 _ready 后核对
	# pose_frame_counts 是否生效、set_pose 后 frame 是否 clamp、帧纹理是否有效、节点可见性。
	if visual_rig != null and visual_pixel != null:
		visual_rig.call("_ready")
		var pfc: Dictionary = visual_rig.get("pose_frame_counts") as Dictionary
		var sf: SpriteFrames = visual_pixel.get("sprite_frames") as SpriteFrames
		var anims: PackedStringArray = sf.get_animation_names() if sf != null else PackedStringArray()
		var anim0: String = str(visual_pixel.get("animation"))
		var frame0: int = int(visual_pixel.get("frame"))
		var fc0: int = sf.get_frame_count(StringName(anim0)) if sf != null else -1
		var tex0_ok: bool = sf != null and frame0 >= 0 and frame0 < fc0 \
				and sf.get_frame_texture(StringName(anim0), frame0) != null
		visual_rig.call("set_pose", "p1_dagger_slash", 18)
		var anim1: String = str(visual_pixel.get("animation"))
		var frame1: int = int(visual_pixel.get("frame"))
		var fc1: int = sf.get_frame_count(StringName(anim1)) if sf != null else -1
		var tex1_ok: bool = sf != null and frame1 >= 0 and frame1 < fc1 \
				and sf.get_frame_texture(StringName(anim1), frame1) != null
		var bv: Node = inst.get_node_or_null("SubViewportContainer/SubViewport/BossVisual")
		print("[BUILD_V010] RENDER_PROBE pose_frame_counts=%s sf_anims=%s | before(anim=%s frame=%d fc=%d tex=%s) | after_set_pose18(anim=%s frame=%d fc=%d tex=%s)" % [
			str(pfc), str(anims), anim0, frame0, fc0, str(tex0_ok), anim1, frame1, fc1, str(tex1_ok)])
		print("[BUILD_V010] RENDER_NODE bossVisual_visible=%s bossVisual_pos=%s pixel_visible=%s pixel_scale=%s pixel_offset=%s pixel_centered=%s pixel_size=%s" % [
			str(bool(bv.get("visible"))) if bv != null else "n/a",
			str(bv.get("position")) if bv != null else "n/a",
			str(bool(visual_pixel.get("visible"))), str(visual_pixel.get("scale")),
			str(visual_pixel.get("offset")), str(bool(visual_pixel.get("centered"))),
			str(visual_pixel.get("pixel_size"))])
	_free_tree(inst)


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
