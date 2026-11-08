extends SceneTree
# 由总指挥于 2026-11-09 07:46 追加：把已交付的精灵表构建为 Godot 可直接加载的 SpriteFrames 资源。
# 真跑：godot --headless --path godot --script res://scripts/build_spriteframes.gd

const FRAME_PX: int = 128


func _initialize() -> void:
	_build_player()
	_build_boss()
	_verify("res://assets/generated/chars/player_spriteframes.tres", 8)
	_verify("res://assets/generated/boss/boss_spriteframes.tres", 3)
	quit(0)


func _build_player() -> void:
	var tex: Texture2D = load("res://assets/generated/chars/player_spritesheet.png") as Texture2D
	if tex == null:
		push_error("[PLAYER_SF] spritesheet missing")
		return
	var sf: SpriteFrames = SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	var poses: PackedStringArray = PackedStringArray([
		"idle", "walk", "run", "roll", "attack_light", "attack_heavy", "hitstun", "death"
	])
	for i: int in range(poses.size()):
		var nm: String = poses[i]
		sf.add_animation(nm)
		sf.set_animation_speed(nm, 1.0)
		sf.set_animation_loop(nm, nm == "idle" or nm == "walk" or nm == "run")
		var at: AtlasTexture = AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(float(i * FRAME_PX), 0.0, float(FRAME_PX), float(FRAME_PX))
		sf.add_frame(nm, at)
	var err: Error = ResourceSaver.save(sf, "res://assets/generated/chars/player_spriteframes.tres")
	print("[PLAYER_SF] save_err=", err, " animations=", sf.get_animation_names())


func _build_boss() -> void:
	var tex: Texture2D = load("res://assets/generated/boss/boss_spritesheet.png") as Texture2D
	if tex == null:
		push_error("[BOSS_SF] spritesheet missing")
		return
	var sf: SpriteFrames = SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	# 与 boss_import.json 的 pose_prefix / phase_hint 一致
	var poses: PackedStringArray = PackedStringArray([
		"p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"
	])
	for i: int in range(poses.size()):
		var nm: String = poses[i]
		sf.add_animation(nm)
		sf.set_animation_speed(nm, 1.0)
		sf.set_animation_loop(nm, false)
		var at: AtlasTexture = AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(float(i * FRAME_PX), 0.0, float(FRAME_PX), float(FRAME_PX))
		sf.add_frame(nm, at)
	var err: Error = ResourceSaver.save(sf, "res://assets/generated/boss/boss_spriteframes.tres")
	print("[BOSS_SF] save_err=", err, " animations=", sf.get_animation_names())


func _verify(path: String, expected: int) -> void:
	var sf: SpriteFrames = load(path) as SpriteFrames
	if sf == null:
		push_error("[VERIFY] load failed: " + path)
		return
	var names: PackedStringArray = sf.get_animation_names()
	print("[VERIFY] ", path, " anim_count=", names.size(), " expected=", expected,
			" ok=", names.size() == expected)
	for nm: String in names:
		print("[VERIFY]   ", nm, " frames=", sf.get_frame_count(nm),
				" speed=", sf.get_animation_speed(nm), " loop=", sf.get_animation_loop(nm))
