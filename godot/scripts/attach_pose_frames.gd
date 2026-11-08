extends SceneTree
# 由总指挥于 2026-11-09 07:51 追加：把 courtyard.tscn 的单帧 Sprite3D 换为
# AnimatedSprite3D 并绑定 player_spriteframes.tres，让 HybridSpriteRig.set_pose() 真正切帧。
# 真跑：godot --headless --path godot --script res://scripts/attach_pose_frames.gd

const PIXEL_SPRITE_PATH: String = "SubViewportContainer/SubViewport/Player/Hybrid2D3DAnimatedSprite/PixelSprite"
const FRAMES_PATH: String = "res://assets/generated/chars/player_spriteframes.tres"


func _initialize() -> void:
	var ps: PackedScene = load("res://scenes/courtyard.tscn") as PackedScene
	if ps == null:
		push_error("[POSE] courtyard.tscn load failed")
		quit(1)
		return
	var root: Node = ps.instantiate()
	var old_spr: Node = root.get_node_or_null(PIXEL_SPRITE_PATH)
	if old_spr == null:
		push_error("[POSE] PixelSprite missing")
		root.free()
		quit(1)
		return
	if old_spr is AnimatedSprite3D:
		print("[POSE] already AnimatedSprite3D, skip replace")
		root.free()
		_verify()
		quit(0)
		return
	var frames: SpriteFrames = load(FRAMES_PATH) as SpriteFrames
	if frames == null:
		push_error("[POSE] SpriteFrames missing")
		root.free()
		quit(1)
		return
	var parent_node: Node = old_spr.get_parent()
	var idx: int = old_spr.get_index()
	var spr: AnimatedSprite3D = AnimatedSprite3D.new()
	spr.name = "PixelSprite"
	spr.sprite_frames = frames
	spr.animation = "idle"
	spr.centered = false
	spr.offset = Vector2(-16, -48)
	spr.pixel_size = 0.03125
	parent_node.remove_child(old_spr)
	parent_node.add_child(spr)
	parent_node.move_child(spr, idx)
	old_spr.free()
	_set_owner(root, root)
	var before: int = _count(root)
	var packed: PackedScene = PackedScene.new()
	var err_pack: Error = packed.pack(root)
	var test: Node = packed.instantiate()
	var after: int = _count(test)
	print("[POSE] pack_err=", err_pack, " nodes_before=", before, " nodes_after=", after,
			" match=", before == after)
	if before != after:
		push_error("[POSE] node count mismatch, abort save")
		test.free()
		root.free()
		quit(1)
		return
	var err_save: Error = ResourceSaver.save(packed, "res://scenes/courtyard.tscn")
	print("[POSE] save_err=", err_save)
	test.free()
	root.free()
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
	# 绕过本进程缓存，重新从磁盘读取刚保存的场景
	var ps: PackedScene = ResourceLoader.load(
			"res://scenes/courtyard.tscn", "PackedScene",
			ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var root: Node = ps.instantiate()
	var spr: Node = root.get_node_or_null(PIXEL_SPRITE_PATH)
	var is_anim: bool = spr is AnimatedSprite3D
	var count: int = -1
	var anim: String = ""
	if is_anim:
		var asp: AnimatedSprite3D = spr as AnimatedSprite3D
		count = asp.sprite_frames.get_animation_names().size() if asp.sprite_frames != null else -1
		anim = asp.animation
	print("[POSE_VERIFY] nodes=", _count(root), " is_AnimatedSprite3D=", is_anim,
			" frames_anims=", count, " anim=", anim,
			" ok=", (is_anim and count == 8 and anim == "idle"))
	root.free()
