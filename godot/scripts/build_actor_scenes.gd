extends SceneTree
# 由总指挥于 2026-11-09 07:48 追加：把 SpriteFrames 资源挂到 AnimatedSprite2D，
# 生成可直接 instantiate 的玩家 / Boss 场景（不改动既有 courtyard.tscn）。
# 真跑：godot --headless --path godot --script res://scripts/build_actor_scenes.gd


func _initialize() -> void:
	_build(
		"Player",
		"res://assets/generated/chars/player_spriteframes.tres",
		"idle",
		"res://scenes/player.tscn",
		8
	)
	_build(
		"Boss01Margit",
		"res://assets/generated/boss/boss_spriteframes.tres",
		"p1_dagger_slash",
		"res://scenes/boss_01_margit.tscn",
		3
	)
	quit(0)


func _build(root_name: String, frames_path: String, default_anim: String, out_path: String, expected: int) -> void:
	var frames: SpriteFrames = load(frames_path) as SpriteFrames
	if frames == null:
		push_error("[ACTOR] SpriteFrames missing: " + frames_path)
		return
	var root: CharacterBody2D = CharacterBody2D.new()
	root.name = root_name
	var spr: AnimatedSprite2D = AnimatedSprite2D.new()
	spr.name = "AnimatedSprite2D"
	spr.sprite_frames = frames
	spr.animation = default_anim
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(spr)
	spr.owner = root
	var packed: PackedScene = PackedScene.new()
	var err_pack: Error = packed.pack(root)
	var err_save: Error = ResourceSaver.save(packed, out_path)
	print("[ACTOR] ", root_name, " pack_err=", err_pack, " save_err=", err_save,
			" anims=", frames.get_animation_names().size(), " expected=", expected)
	root.free()
	_verify(out_path, default_anim, expected)


func _verify(path: String, default_anim: String, expected: int) -> void:
	var ps: PackedScene = load(path) as PackedScene
	if ps == null:
		push_error("[ACTOR_VERIFY] load failed: " + path)
		return
	var inst: Node = ps.instantiate()
	var spr: AnimatedSprite2D = inst.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr == null:
		push_error("[ACTOR_VERIFY] AnimatedSprite2D missing: " + path)
		inst.free()
		return
	var count: int = spr.sprite_frames.get_animation_names().size() if spr.sprite_frames != null else -1
	print("[ACTOR_VERIFY] ", path, " root=", inst.name,
			" child_count=", inst.get_child_count(),
			" anim=", spr.animation, " expected_anim=", default_anim,
			" frames_anims=", count, " ok=", (spr.animation == default_anim and count == expected))
	inst.free()
