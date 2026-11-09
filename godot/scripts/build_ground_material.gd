extends SceneTree
## R14 / cmd-20261109-082141-612-A4 · Rank-4 地面材质资源真跑生成与回读自检
## 运行：godot --headless --path godot --script res://scripts/build_ground_material.gd
## 静态：godot --headless --path godot --check-only --script res://scripts/build_ground_material.gd
##
## 唯一职责：构造 StandardMaterial3D → ResourceSaver.save() 落
##   res://assets/generated/terrain/ground_material.tres →
##   ResourceLoader.load(..., CACHE_MODE_IGNORE) 从磁盘重读并校验四项。
## 只写该 .tres；不加载 / 不修改 / 不保存 courtyard.tscn（Rank-1 本轮并发改同一场景）。
## 沿用工程内既有 extends SceneTree 统一口径：_initialize() 一次性执行 + quit(code)。
## 中文 UTF-8；Godot 4.7.2 合法语法；不伪造输出，全部打印为运行期实际值。

const TILE_PATH: String = "res://assets/generated/terrain/ground_tile.png"
const MAT_PATH: String = "res://assets/generated/terrain/ground_material.tres"
const UV_SCALE: Vector3 = Vector3(4, 4, 4)


func _initialize() -> void:
	print("==== [R14 build_ground_material] START ====")

	# (0) 枚举常量真跑验证：合法性与整数值，不臆造序列化值
	var nearest_filter: int = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var ignore_mode: int = ResourceLoader.CACHE_MODE_IGNORE
	print("[enum] BaseMaterial3D.TEXTURE_FILTER_NEAREST = %d" % nearest_filter)
	print("[enum] ResourceLoader.CACHE_MODE_IGNORE = %d" % ignore_mode)
	# 枚举名核对：不引用未经核实的成员名（4.7.2 实测 BaseMaterial3D.TEXTURE_REPEAT_ENABLED 不存在）
	print("[enum] BaseMaterial3D integer constants = ", ClassDB.class_get_integer_constant_list("BaseMaterial3D"))

	# (1) 贴图加载（.import 与 .godot/imported 已由 Godot 导入，load 走 res:// remap）
	var tex: Texture2D = load(TILE_PATH) as Texture2D
	print("[load] %s -> %s" % [TILE_PATH, str(tex)])
	if tex == null:
		push_error("[R14] 贴图加载失败，拒绝保存：" + TILE_PATH)
		print("==== [R14] RESULT=FAIL ====")
		quit(1)
		return

	# (2) 构造材质：严格按派单设置三项
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = nearest_filter
	mat.uv1_scale = UV_SCALE
	# 默认值如实打印：用于判断「uv1_scale 平铺 / 贴图不被压暗」是否成立，本轮不擅自改其它字段
	print("[set] albedo_texture = %s" % str(mat.albedo_texture))
	print("[set] texture_filter = %d" % mat.texture_filter)
	print("[set] uv1_scale = %s" % str(mat.uv1_scale))
	print("[set][default] albedo_color = %s" % str(mat.albedo_color))
	print("[set][default] texture_repeat = ", mat.texture_repeat)

	# (3) 保存
	var save_err: int = ResourceSaver.save(mat, MAT_PATH)
	print("[save] ResourceSaver.save(%s) err = %d (OK=%d)" % [MAT_PATH, save_err, OK])
	if save_err != OK:
		push_error("[R14] 保存失败，err=%d" % save_err)
		print("==== [R14] RESULT=FAIL ====")
		quit(1)
		return
	print("[save] path = %s" % MAT_PATH)

	# (4) CACHE_MODE_IGNORE 回读：绕过本进程缓存，强制从磁盘重新解析
	var r: Resource = ResourceLoader.load(MAT_PATH, "StandardMaterial3D", ignore_mode)
	print("==== [回读 CACHE_MODE_IGNORE] ====")
	if r == null:
		push_error("[R14] 回读为空：" + MAT_PATH)
		print("==== [R14] RESULT=FAIL ====")
		quit(1)
		return
	var m: StandardMaterial3D = r as StandardMaterial3D
	print("[readback] class = %s" % r.get_class())
	print("[readback] resource_path = %s" % r.resource_path)
	print("[readback] is StandardMaterial3D = %s" % str(r is StandardMaterial3D))
	if m == null:
		push_error("[R14] 回读类型不是 StandardMaterial3D")
		print("==== [R14] RESULT=FAIL ====")
		quit(1)
		return
	print("[readback] albedo_texture non-null = %s" % str(m.albedo_texture != null))
	if m.albedo_texture != null:
		print("[readback] albedo_texture class = %s" % m.albedo_texture.get_class())
		print("[readback] albedo_texture resource_path = %s" % m.albedo_texture.resource_path)
	print("[readback] texture_filter = %d" % m.texture_filter)
	print("[readback] texture_filter == TEXTURE_FILTER_NEAREST = %s" % str(m.texture_filter == nearest_filter))
	print("[readback] uv1_scale = %s" % str(m.uv1_scale))
	print("[readback][default] texture_repeat = ", m.texture_repeat)
	print("[readback][default] albedo_color = %s" % str(m.albedo_color))
	print("[readback] same-instance-as-saved = %s (false 表示确实绕过缓存重读)" % str(r == mat))

	# (5) 派单四项自检
	var ok: bool = true
	ok = ok and (m is StandardMaterial3D)
	ok = ok and (m.albedo_texture != null)
	ok = ok and (m.texture_filter == nearest_filter)
	ok = ok and (m.uv1_scale == UV_SCALE)
	print("==== [R14] ASSERT = %s ====" % ("ALL PASS" if ok else "FAIL"))
	print("==== [R14] RESULT=%s ====" % ("PASS" if ok else "FAIL"))
	print("==== [R14 build_ground_material] END ====")
	quit(0 if ok else 1)
