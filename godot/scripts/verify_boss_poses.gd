extends SceneTree
## R14 / cmd-20261109-082141-608-A2 · Rank-2 Boss 三招动画切换运行期自检
## 真跑验证：boss_01_margit.tscn 加载与实例化、取 AnimatedSprite2D；
## 依次把 animation 设为 3 个招式并回读断言一致，打印每招的
## sprite_frames.get_frame_count(anim) 与 get_animation_loop(anim)。
## 运行：godot --headless --path godot --script res://scripts/verify_boss_poses.gd
## 静态：godot --headless --path godot --check-only --script res://scripts/verify_boss_poses.gd

const BOSS_SCENE_PATH := "res://scenes/boss_01_margit.tscn"
const EXPECTED_ROOT_NAME := "Boss01Margit"
const POSES = ["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]

var _boss: Node = null
var _pass_count: int = 0
var _fail_count: int = 0


func _initialize() -> void:
	print("==== [R14 BOSS POSES VERIFY] START ====")
	var asp: AnimatedSprite2D = _step1_load_and_get_sprite()
	if asp != null:
		_step2_switch_poses(asp)
	if _boss != null and is_instance_valid(_boss):
		_boss.free()
	print("==== [R14 BOSS POSES VERIFY] PASS_COUNT=%d FAIL_COUNT=%d ====" % [_pass_count, _fail_count])
	print("==== [R14 BOSS POSES VERIFY] RESULT=%s ====" % ("PASS" if _fail_count == 0 else "FAIL"))
	quit(0 if _fail_count == 0 else 1)


func _step1_load_and_get_sprite() -> AnimatedSprite2D:
	var packed: PackedScene = load(BOSS_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("[1] load() 返回 null 或非 PackedScene: %s" % BOSS_SCENE_PATH)
		return null
	var inst: Node = packed.instantiate()
	if inst == null:
		_fail("[1] instantiate() 返回 null")
		return null
	_boss = inst
	var root_name := String(inst.name)
	print("[1] load()+instantiate() OK | root.name=%s | root.class=%s | child_count=%d" % [root_name, inst.get_class(), inst.get_child_count()])
	_assert(root_name == EXPECTED_ROOT_NAME, "[1] 根节点名 == '%s'（实际 '%s'）" % [EXPECTED_ROOT_NAME, root_name])
	var asp: AnimatedSprite2D = inst.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if asp == null:
		_fail("[1] 未找到子节点 AnimatedSprite2D")
		return null
	print("[1] 取到 AnimatedSprite2D | node.class=%s | sprite_frames_null=%s" % [asp.get_class(), str(asp.sprite_frames == null)])
	_assert(asp.sprite_frames != null, "[1] AnimatedSprite2D.sprite_frames 非 null")
	if asp.sprite_frames == null:
		return null
	return asp


func _step2_switch_poses(asp: AnimatedSprite2D) -> void:
	var sf: SpriteFrames = asp.sprite_frames
	var names: Array = Array(sf.get_animation_names())
	print("[2] sprite_frames 动画清单 | animation_count=%d | names=%s" % [names.size(), str(names)])
	for i in range(POSES.size()):
		var pose: String = POSES[i]
		var anim := StringName(pose)
		print("[2.%d] ---- 切换招式 '%s' ----" % [i + 1, pose])
		_assert(sf.has_animation(anim), "[2.%d] sprite_frames 含动画 '%s'" % [i + 1, pose])
		asp.animation = anim
		var read_back := String(asp.animation)
		print("[2.%d] 设置 animation='%s' 后回读 | animation='%s'" % [i + 1, pose, read_back])
		_assert(read_back == pose, "[2.%d] animation 回读一致（期望 '%s' / 实际 '%s'）" % [i + 1, pose, read_back])
		var frame_count: int = sf.get_frame_count(anim)
		var loop: bool = sf.get_animation_loop(anim)
		print("[2.%d] sprite_frames.get_frame_count('%s')=%d" % [i + 1, pose, frame_count])
		print("[2.%d] sprite_frames.get_animation_loop('%s')=%s" % [i + 1, pose, str(loop)])


func _assert(condition: bool, message: String) -> void:
	if condition:
		_pass_count += 1
		print("  [PASS] %s" % message)
	else:
		_fail(message)


func _fail(message: String) -> void:
	_fail_count += 1
	print("  [FAIL] %s" % message)
