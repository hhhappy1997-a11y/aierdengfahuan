extends SceneTree
## R13 / cmd-20261109-080019-794-A2 · Rank-2 战斗系统运行期最小自检
## 真跑验证：boss_01_margit.tscn 加载与实例化、AnimatedSprite2D 的 sprite_frames
## 与 3 个动画、boss_spriteframes.tres 独立加载、HybridSpriteRig.set_pose() 调用链。
## 运行：godot --headless --path godot --script res://scripts/verify_boss_runtime.gd
## 静态：godot --headless --path godot --check-only --script res://scripts/verify_boss_runtime.gd

const BOSS_SCENE_PATH := "res://scenes/boss_01_margit.tscn"
const BOSS_TRES_PATH := "res://assets/generated/boss/boss_spriteframes.tres"
const EXPECTED_ROOT_NAME := "Boss01Margit"
const EXPECTED_ANIMATIONS = ["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]
const EXPECTED_CURRENT_ANIMATION := "p1_dagger_slash"

var _boss: Node = null
var _scene_anim_names: Array = []
var _fail_count: int = 0


func _initialize() -> void:
	print("==== [R13 BOSS RUNTIME VERIFY] START ====")
	_step1_load_and_instantiate()
	_step2_sprite_frames()
	_step3_standalone_tres()
	_step4_hybrid_rig_set_pose()
	if _boss != null and is_instance_valid(_boss):
		_boss.free()
	print("==== [R13 BOSS RUNTIME VERIFY] FAIL_COUNT=%d ====" % _fail_count)
	print("==== [R13 BOSS RUNTIME VERIFY] RESULT=%s ====" % ("PASS" if _fail_count == 0 else "FAIL"))
	quit(0 if _fail_count == 0 else 1)


func _step1_load_and_instantiate() -> void:
	var packed: PackedScene = load(BOSS_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("[1] load() 返回 null 或非 PackedScene: %s" % BOSS_SCENE_PATH)
		return
	var inst: Node = packed.instantiate()
	if inst == null:
		_fail("[1] instantiate() 返回 null")
		return
	_boss = inst
	var root_name := String(inst.name)
	print("[1] load()+instantiate() OK | root.name=%s | root.class=%s | child_count=%d" % [root_name, inst.get_class(), inst.get_child_count()])
	_assert(root_name == EXPECTED_ROOT_NAME, "[1] 根节点名 == '%s'（实际 '%s'）" % [EXPECTED_ROOT_NAME, root_name])


func _step2_sprite_frames() -> void:
	if _boss == null:
		_fail("[2] 依赖 _boss 为空（step1 未成功）")
		return
	var asp: AnimatedSprite2D = _boss.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if asp == null:
		_fail("[2] 未找到子节点 AnimatedSprite2D")
		return
	var sf: SpriteFrames = asp.sprite_frames
	if sf == null:
		_fail("[2] AnimatedSprite2D.sprite_frames 为 null")
		return
	_scene_anim_names = Array(sf.get_animation_names())
	var current := String(asp.animation)
	print("[2] sprite_frames 非 null | animation_count=%d | names=%s | current_animation=%s" % [_scene_anim_names.size(), str(_scene_anim_names), current])
	_assert(_scene_anim_names.size() == 3, "[2] 动画数 == 3（实际 %d）" % _scene_anim_names.size())
	for expected in EXPECTED_ANIMATIONS:
		_assert(sf.has_animation(StringName(expected)), "[2] 含动画 '%s'" % expected)
	_assert(current == EXPECTED_CURRENT_ANIMATION, "[2] 当前 animation == '%s'（实际 '%s'）" % [EXPECTED_CURRENT_ANIMATION, current])


func _step3_standalone_tres() -> void:
	var res: Resource = load(BOSS_TRES_PATH)
	var sf: SpriteFrames = res as SpriteFrames
	if sf == null:
		_fail("[3] load(%s) 返回 null 或非 SpriteFrames" % BOSS_TRES_PATH)
		return
	var names: Array = Array(sf.get_animation_names())
	print("[3] .tres 独立加载 OK | resource.class=%s | animation_count=%d | names=%s" % [res.get_class(), names.size(), str(names)])
	_assert(names.size() == 3, "[3] .tres 动画数 == 3（实际 %d）" % names.size())
	for expected in EXPECTED_ANIMATIONS:
		_assert(sf.has_animation(StringName(expected)), "[3] .tres 含动画 '%s'" % expected)
	_assert(names.size() == _scene_anim_names.size(), "[3] .tres 与场景 sprite_frames 动画数一致（tres=%d scene=%d）" % [names.size(), _scene_anim_names.size()])


func _step4_hybrid_rig_set_pose() -> void:
	## 静态类型化引用：--check-only 解析期会校验全局类 HybridSpriteRig(class_name)
	## 是否存在、set_pose(String, int) 是否可调用；运行时再真调一次并读回状态。
	var rig: HybridSpriteRig = HybridSpriteRig.new()
	if rig == null:
		_fail("[4] HybridSpriteRig.new() 返回 null")
		return
	var global_name := "<n/a>"
	var scr: Script = rig.get_script() as Script
	if scr != null and scr.has_method("get_global_name"):
		global_name = String(scr.call("get_global_name"))
	print("[4] HybridSpriteRig 解析 OK | class_name=%s | has_method(set_pose)=%s" % [global_name, str(rig.has_method("set_pose"))])
	_assert(rig.has_method("set_pose"), "[4] HybridSpriteRig 存在可调用方法 set_pose")
	rig.set_pose("p1_dagger_slash", 0)
	var pose_after := rig.get_current_pose()
	var frame_after := rig.get_current_frame()
	print("[4] set_pose('p1_dagger_slash', 0) 实调 OK | current_pose=%s | current_frame=%d" % [pose_after, frame_after])
	_assert(pose_after == "p1_dagger_slash", "[4] set_pose 后 current_pose == 'p1_dagger_slash'（实际 '%s'）" % pose_after)
	rig.free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("  [PASS] %s" % message)
	else:
		_fail(message)


func _fail(message: String) -> void:
	_fail_count += 1
	print("  [FAIL] %s" % message)
