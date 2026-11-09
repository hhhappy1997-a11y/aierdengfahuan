extends SceneTree
# R14 画面整改（cmd-20261109-082141-606-A1）：WorldEnvironment 暖金 ambient × 冷雾 fog 对比。
# 参考 tune_visual.gd / attach_pose_frames.gd 的 SceneTree 构建 / pack / 回读模式。
# 真跑：godot --headless --path godot --script res://scripts/tune_env.gd
# 门禁：godot --headless --path godot --check-only --script res://scripts/tune_env.gd

const SCENE_PATH: String = "res://scenes/courtyard.tscn"
const WE_PATH: String = "SubViewportContainer/SubViewport/WorldEnvironment"

# 1) 暖金环境光：任务给定色，替代原冷蓝 Color(0.28, 0.36, 0.52)
const AMBIENT_COLOR: Color = Color(1.0, 0.82, 0.6)
# 磁盘当前 ambient_light_energy=0.6（任务举例亦为 0.6）；为落实「提高」取 0.8，
# 仍低于默认 1.0，属温和提高，避免过曝 / 把画面糊掉。如需严格按举例 0.6，改此一行即可。
const AMBIENT_ENERGY: float = 0.8

# 2) 适度雾：启用 + 冷雾色，与暖金 ambient 形成「暖金 × 冷雾」对比。
#    fog_density 不显式改（沿用磁盘温和值 0.008），只在回读时校验未超过温和上限。
const FOG_ENABLED: bool = true
const FOG_LIGHT_COLOR: Color = Color(0.4, 0.55, 0.72)
const FOG_DENSITY_MAX: float = 0.02

# 节点数硬门槛：pack 前 / 后都必须为 22，且彼此一致，否则中止保存
const EXPECTED_NODES: int = 22


func _initialize() -> void:
	var ps: PackedScene = load(SCENE_PATH) as PackedScene
	if ps == null:
		push_error("[TUNE_ENV] courtyard.tscn load failed")
		quit(1)
		return
	var root: Node = ps.instantiate()

	var we_node: Node = root.get_node_or_null(WE_PATH)
	if we_node == null or not (we_node is WorldEnvironment):
		push_error("[TUNE_ENV] WorldEnvironment missing / not WorldEnvironment")
		root.free()
		quit(1)
		return
	var we: WorldEnvironment = we_node as WorldEnvironment

	# 复用现有内嵌 Environment（保留 background_mode/color、tonemap_mode 等，避免破坏画面）。
	# 对其 duplicate 一份干净实例：断开与原场景 sub_resource 缓存的关联，确保 pack
	# 把「修改后的值」序列化为新的 SubResource 真正写入磁盘，而非沿用旧内嵌引用。
	# 若原本为空则新建兜底，保证「给它设一个 Environment」。
	var env: Environment = we.environment
	if env == null:
		env = Environment.new()
	else:
		env = env.duplicate() as Environment
	we.environment = env

	print("[TUNE_ENV] BEFORE ambient_color=", env.ambient_light_color,
			" ambient_energy=", env.ambient_light_energy,
			" ambient_source=", env.ambient_light_source,
			" fog_enabled=", env.fog_enabled,
			" fog_color=", env.fog_light_color,
			" fog_density=", env.fog_density)

	# 全部用绝对目标值赋值 -> 重复真跑 / --check-only 均不会叠加，脚本幂等
	env.ambient_light_color = AMBIENT_COLOR
	env.ambient_light_energy = AMBIENT_ENERGY
	env.fog_enabled = FOG_ENABLED
	env.fog_light_color = FOG_LIGHT_COLOR

	print("[TUNE_ENV] AFTER  ambient_color=", env.ambient_light_color,
			" ambient_energy=", env.ambient_light_energy,
			" ambient_source=", env.ambient_light_source,
			" fog_enabled=", env.fog_enabled,
			" fog_color=", env.fog_light_color,
			" fog_density=", env.fog_density)

	# pack 前必须重设 owner 链，否则子场景节点不会被序列化
	_set_owner(root, root)
	var before: int = _count(root)

	var packed: PackedScene = PackedScene.new()
	var err_pack: Error = packed.pack(root)
	var test: Node = packed.instantiate()
	var after: int = _count(test)
	print("[TUNE_ENV] pack_err=", err_pack, " nodes_before=", before,
			" nodes_after=", after, " expect=", EXPECTED_NODES)
	if err_pack != OK or before != EXPECTED_NODES or after != EXPECTED_NODES or before != after:
		push_error("[TUNE_ENV] node count / pack guard failed, abort save")
		test.free()
		root.free()
		quit(1)
		return
	test.free()

	var err_save: Error = ResourceSaver.save(packed, SCENE_PATH)
	print("[TUNE_ENV] save_err=", err_save)
	root.free()
	if err_save != OK:
		push_error("[TUNE_ENV] save failed")
		quit(1)
		return

	# 绕过本进程资源缓存，从磁盘回读确认 Environment 参数确实落盘
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
	# CACHE_MODE_IGNORE 强制重新从磁盘读取刚保存的场景，不命中本进程缓存
	var ps: PackedScene = ResourceLoader.load(
			SCENE_PATH, "PackedScene",
			ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if ps == null:
		push_error("[TUNE_ENV_VERIFY] re-load from disk failed")
		return
	var root: Node = ps.instantiate()
	var we: WorldEnvironment = root.get_node_or_null(WE_PATH) as WorldEnvironment
	var env: Environment = we.environment if we != null else null
	var nodes: int = _count(root)
	var ambient_color_ok: bool = env != null and env.ambient_light_color.is_equal_approx(AMBIENT_COLOR)
	var ambient_energy_ok: bool = env != null and is_equal_approx(env.ambient_light_energy, AMBIENT_ENERGY)
	var fog_enabled_ok: bool = env != null and env.fog_enabled == FOG_ENABLED
	var fog_color_ok: bool = env != null and env.fog_light_color.is_equal_approx(FOG_LIGHT_COLOR)
	var fog_mild_ok: bool = env != null and env.fog_density <= FOG_DENSITY_MAX
	print("[TUNE_ENV_VERIFY] nodes=", nodes,
			" ambient_color=", (env.ambient_light_color if env != null else Color(0, 0, 0)),
			" ambient_energy=", (env.ambient_light_energy if env != null else -1.0),
			" ambient_source=", (env.ambient_light_source if env != null else -1),
			" fog_enabled=", (env.fog_enabled if env != null else false),
			" fog_color=", (env.fog_light_color if env != null else Color(0, 0, 0)),
			" fog_density=", (env.fog_density if env != null else -1.0),
			" ambient_color_ok=", ambient_color_ok,
			" ambient_energy_ok=", ambient_energy_ok,
			" fog_enabled_ok=", fog_enabled_ok,
			" fog_color_ok=", fog_color_ok,
			" fog_mild_ok=", fog_mild_ok,
			" nodes_ok=", nodes == EXPECTED_NODES,
			" OK=", (ambient_color_ok and ambient_energy_ok and fog_enabled_ok
					and fog_color_ok and fog_mild_ok and nodes == EXPECTED_NODES))
	root.free()
