extends SceneTree
## R17 / cmd-20261109-093050-716-A2 · Rank-2 Boss 阶段切换运行期验证（真跑）
##
## 项1：load()/instantiate() boss_01_margit.tscn，取 AnimatedSprite2D。
## 项2：模拟阶段切换，依次设 animation 为
##      p1_dagger_slash → p1_staff_slam → p2_holy_hammer（p1_ 两招 → p2_ 一招），
##      逐次回读断言一致，并打印每招 frame_count / loop / 阶段前缀。
## 项3：核对 HybridSpriteRig._resolve_full_pose() 的 pose_prefix 拼接（p1_/p2_）
##      与 FROZEN_POSES 校验（合法基础名接受 / 非法名拒绝），
##      并用公开接口 set_pose() + get_current_pose() 端到端佐证。
## 项4：三段门禁 --import / --check-only --script verify_boss_phase.gd / --quit
##      由外部命令执行（EXIT 与完整实际 stdout 见 DONE-R17.md / R17-verify-run.log）；
##      本脚本不自检门禁本身。
##
## 运行（真跑）：godot --headless --path godot --script res://scripts/verify_boss_phase.gd
## 静态（门禁）：godot --headless --path godot --check-only --script res://scripts/verify_boss_phase.gd
##
## 说明：HybridSpriteRig 为工程内 class_name 全局类，常量/方法访问前须先 --import
##       刷新全局类缓存。_resolve_full_pose() 为下划线私有方法，GDScript 无真正访问控制，
##       本脚本用 call("_resolve_full_pose", ...) 动态调用以兼顾 --check-only 静态解析。
##       名称统一转 String 后再比较，避免 StringName / String 跨 Variant 类型比较歧义。

const BOSS_SCENE_PATH := "res://scenes/boss_01_margit.tscn"
const EXPECTED_ROOT_NAME := "Boss01Margit"
const PHASE_POSES: Array = ["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]
const BOSS_BASE_POSES: Array = ["dagger_slash", "staff_slam", "holy_hammer"]

var _boss: Node = null
var _rig: HybridSpriteRig = null
var _pass_count: int = 0
var _fail_count: int = 0


func _initialize() -> void:
	print("==== [R17 BOSS PHASE VERIFY] START ====")
	var asp: AnimatedSprite2D = _step1_instantiate()
	if asp != null:
		_step2_phase_switch(asp)
	_step3_hybrid_rig()
	if _rig != null and is_instance_valid(_rig):
		_rig.free()
	if _boss != null and is_instance_valid(_boss):
		_boss.free()
	print("==== [R17 BOSS PHASE VERIFY] PASS_COUNT=%d FAIL_COUNT=%d ====" % [_pass_count, _fail_count])
	print("==== [R17 BOSS PHASE VERIFY] RESULT=%s ====" % ("PASS" if _fail_count == 0 else "FAIL"))
	quit(0 if _fail_count == 0 else 1)


# ---------------------------------------------------------------- 项1 实例化
func _step1_instantiate() -> AnimatedSprite2D:
	print("---- [1] 实例化 boss_01_margit.tscn / 取 AnimatedSprite2D ----")
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
	print("[1] 取到 AnimatedSprite2D | class=%s | sprite_frames_null=%s | initial_animation='%s'" % [asp.get_class(), str(asp.sprite_frames == null), String(asp.animation)])
	_assert(asp.sprite_frames != null, "[1] AnimatedSprite2D.sprite_frames 非 null")
	if asp.sprite_frames == null:
		return null
	return asp


# ---------------------------------------------------------------- 项2 阶段切换
func _step2_phase_switch(asp: AnimatedSprite2D) -> void:
	print("---- [2] 模拟阶段切换：p1_ 两招 → p2_ 一招，逐次设 animation 并回读 ----")
	var sf: SpriteFrames = asp.sprite_frames
	var names: Array = Array(sf.get_animation_names())
	print("[2] sprite_frames 动画清单 | animation_count=%d | names=%s" % [names.size(), str(names)])
	for i in range(PHASE_POSES.size()):
		var pose: String = String(PHASE_POSES[i])
		var anim := StringName(pose)
		var expected_prefix: String = "p1_" if i < 2 else "p2_"
		print("[2.%d] ---- 切招 '%s'（阶段前缀期望 '%s'）----" % [i + 1, pose, expected_prefix])
		_assert(pose.begins_with(expected_prefix), "[2.%d] '%s' 带阶段前缀 '%s'" % [i + 1, pose, expected_prefix])
		_assert(sf.has_animation(anim), "[2.%d] sprite_frames 含动画 '%s'" % [i + 1, pose])
		asp.animation = anim
		var read_back := String(asp.animation)
		print("[2.%d] 设置 animation='%s' 后回读 | animation='%s'" % [i + 1, pose, read_back])
		_assert(read_back == pose, "[2.%d] animation 回读一致（期望 '%s' / 实际 '%s'）" % [i + 1, pose, read_back])
		var frame_count: int = sf.get_frame_count(anim)
		var loop: bool = sf.get_animation_loop(anim)
		print("[2.%d] get_frame_count('%s')=%d | get_animation_loop('%s')=%s" % [i + 1, pose, frame_count, pose, str(loop)])
	_assert(String(asp.animation) == "p2_holy_hammer", "[2] 阶段切换末态 animation == 'p2_holy_hammer'（实际 '%s'）" % String(asp.animation))


# ---------------------------------------------------------------- 项3 HybridSpriteRig
func _step3_hybrid_rig() -> void:
	print("---- [3] HybridSpriteRig.pose_prefix 拼接 / FROZEN_POSES 校验 ----")
	_rig = HybridSpriteRig.new()
	if _rig == null:
		_fail("[3] HybridSpriteRig.new() 返回 null")
		return
	var frozen: Array = _to_string_array(HybridSpriteRig.FROZEN_POSES)
	var prefixes: Array = _to_string_array(HybridSpriteRig.POSE_PREFIXES)
	print("[3] HybridSpriteRig.FROZEN_POSES | count=%d | values=%s" % [frozen.size(), str(frozen)])
	print("[3] HybridSpriteRig.POSE_PREFIXES | count=%d | values=%s" % [prefixes.size(), str(prefixes)])

	# [3.1] FROZEN_POSES 冻结表：11 项（基础8+Boss3），Boss 3 基础名在表内
	_assert(frozen.size() == 11, "[3.1] FROZEN_POSES 数量 == 11（基础8+Boss3，实际 %d）" % frozen.size())
	for base in BOSS_BASE_POSES:
		_assert(frozen.has(String(base)), "[3.1] FROZEN_POSES 含 Boss 基础名 '%s'" % String(base))
	_assert(_same_set(prefixes, ["p1_", "p2_"]), "[3.2] POSE_PREFIXES == ['p1_','p2_']（实际 %s）" % str(prefixes))

	# [3.3] pose_prefix 拼接：传基础名 → 前缀由 pose_prefix 提供
	print("[3.3] -- pose_prefix 拼接（传冻结基础名）--")
	_rig.pose_prefix = "p1_"
	_check_resolve("dagger_slash", "p1_dagger_slash", "[3.3.a] pose_prefix='p1_'+'dagger_slash'")
	_check_resolve("staff_slam", "p1_staff_slam", "[3.3.b] pose_prefix='p1_'+'staff_slam'")
	_rig.pose_prefix = "p2_"
	_check_resolve("holy_hammer", "p2_holy_hammer", "[3.3.c] pose_prefix='p2_'+'holy_hammer'")

	# [3.4] 自带前缀完整名：不受 pose_prefix 影响（_resolve_full_pose 优先识别入参前缀）
	print("[3.4] -- 自带 p1_/p2_ 前缀完整名（忽略 pose_prefix）--")
	_rig.pose_prefix = "p2_"
	_check_resolve("p1_dagger_slash", "p1_dagger_slash", "[3.4.a] pose_prefix='p2_' 但入参 'p1_dagger_slash'")
	_rig.pose_prefix = "p1_"
	_check_resolve("p2_holy_hammer", "p2_holy_hammer", "[3.4.b] pose_prefix='p1_' 但入参 'p2_holy_hammer'")

	# [3.5] FROZEN_POSES 校验：表内 11 个基础名全部接受；表外名一律拒绝（返回空串）
	print("[3.5] -- FROZEN_POSES 校验（合法接受 / 非法拒绝）--")
	_rig.pose_prefix = "p1_"
	var accepted: int = 0
	for base in frozen:
		var expected_full: String = "p1_" + String(base)
		if _resolve(String(base)) == expected_full:
			accepted += 1
	print("[3.5] 冻结表 %d 项以 pose_prefix='p1_' 拼接 | accepted=%d" % [frozen.size(), accepted])
	_assert(accepted == frozen.size(), "[3.5.a] FROZEN_POSES 全部基础名被 _resolve_full_pose 接受（accepted=%d/%d）" % [accepted, frozen.size()])
	_check_resolve("not_a_pose", "", "[3.5.b] 表外基础名 'not_a_pose' 应被拒绝")
	_check_resolve("p1_not_a_pose", "", "[3.5.c] 表外带前缀名 'p1_not_a_pose' 应被拒绝")
	_check_resolve("holy_hammer_extra", "", "[3.5.d] 近似名 'holy_hammer_extra' 应被拒绝")

	# [3.6] 公开接口端到端佐证：set_pose() → get_current_pose()
	print("[3.6] -- 公开接口 set_pose() + get_current_pose() 端到端 --")
	_rig.pose_prefix = "p1_"
	_rig.set_pose("dagger_slash", 0)
	var p1_pose := _rig.get_current_pose()
	print("[3.6] set_pose('dagger_slash',0) @ pose_prefix='p1_' | current_pose='%s' | current_frame=%d" % [p1_pose, _rig.get_current_frame()])
	_assert(p1_pose == "p1_dagger_slash", "[3.6.a] set_pose('dagger_slash') 后 current_pose == 'p1_dagger_slash'（实际 '%s'）" % p1_pose)
	_rig.pose_prefix = "p2_"
	_rig.set_pose("holy_hammer", 0)
	var p2_pose := _rig.get_current_pose()
	print("[3.6] set_pose('holy_hammer',0) @ pose_prefix='p2_' | current_pose='%s' | current_frame=%d" % [p2_pose, _rig.get_current_frame()])
	_assert(p2_pose == "p2_holy_hammer", "[3.6.b] set_pose('holy_hammer') 后 current_pose == 'p2_holy_hammer'（实际 '%s'）" % p2_pose)


func _resolve(pose_name: String) -> String:
	return String(_rig.call("_resolve_full_pose", pose_name))


func _check_resolve(pose_name: String, expected: String, label: String) -> void:
	var got := _resolve(pose_name)
	_assert(got == expected, "%s | 入参='%s' 实际='%s' 期望='%s'" % [label, pose_name, got, expected])


# ---------------------------------------------------------------- 工具
func _to_string_array(src: Variant) -> Array:
	var out: Array = []
	if src is Array:
		for item in src:
			out.append(String(item))
	elif src is PackedStringArray:
		for item in src:
			out.append(String(item))
	return out


func _same_set(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for x in a:
		if not b.has(x):
			return false
	return true


func _assert(condition: bool, message: String) -> void:
	if condition:
		_pass_count += 1
		print("  [PASS] %s" % message)
	else:
		_fail(message)


func _fail(message: String) -> void:
	_fail_count += 1
	print("  [FAIL] %s" % message)
