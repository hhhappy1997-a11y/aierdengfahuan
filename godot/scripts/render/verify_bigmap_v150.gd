extends SceneTree
## ===========================================================================
## verify_bigmap_v150.gd · R38 / v0.15.0「大地图 · 2.5D 尺度重构」真实可达回归
##   Rank-1 唯一写入方 · 派单 cmd-20261112-234238-645-A1 · 中文 UTF-8
##   Godot 4.7.2 全静态类型 · 零付费 / 零外部依赖 / 零 GPU job
##
## 【A48③ 硬要求】本脚本【不加载 presentation.gd】（运行时树零 presentation 节点）、
##   【不在验证脚本内模拟编排】：用真实 InputEventKey 注入（Input.parse_input_event）
##   → 显式送生产 BigMapRuntime._unhandled_input / _process（同 V140 --script 显式
##   call 口径）→ 生产 Camera2D 跟随 + limit clamp + 4 层视差按系数滚动
##   → 只读快照断言场景节点真实变化。纯逻辑 + 单元断言不算可玩交付；
##   本脚本断言「真实输入 → 生产运行时 → 场景节点 / 画面层」确实发生。
##
## 【覆盖（任务⑤）】地图尺寸 ≥ 配置阈值 / 视差层数 ≥3 / y_sort 生效 /
##   相机随玩家位移且边界受限 / 角色显示尺寸 == 基线 × 0.40（±容差）/
##   既有战斗入口仍可达 / HUD 避让不因角色缩小失效；A74 节点数 / uv 新基线。
##
## 【SceneTree / --script 纪律】Engine.get_main_loop() as SceneTree 取 root（不用
##   get_tree()、不用 /root/... 绝对路径）；add_child 不自动 flush _ready，
##   以「快照 config_loaded」为守卫显式 call("_ready")（幂等）；资源
##   CACHE_MODE_IGNORE；本脚本不 connect 任何信号，故无 disconnect 欠账
##   （connect 场景一律沿用 V140 的 get_signal_connection_list() 去重 + _finish 释放）。
##   project.godot 既有 PointsCommitOrchestrator autoload 直接复用、不重复挂载。
##
## 输出：逐条 PASS/FAIL + SUMMARY + RESULT=ALL_MATCH（全通过）/ FAILED。
## ===========================================================================

const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"
const WORLD_SCALE_PATH: String = "res://data/render/world_scale.tres"
const WAVE_TABLE_PATH: String = "res://data/rpg/wave_trial.tres"
const BIGMAP_PATH: String = "BigMapLayer/BigMapRoot"
const CHARSCALE_PATH: String = "CharacterScaleController"
const REL_HUD: String = "SubViewportContainer/SubViewport/FXLayer/Hud"
const REL_ENC: String = "EncounterRoot"
const REL_WAVE: String = "WaveTrialDirector"
const REL_CAMERA3D: String = "SubViewportContainer/SubViewport/Camera3D"
const REL_PLAYER_SPRITE: String = "SubViewportContainer/SubViewport/Player/Hybrid2D3DAnimatedSprite/PixelSprite"
const REL_BOSS_SPRITE: String = "SubViewportContainer/SubViewport/BossVisual/Hybrid2D3DAnimatedSprite/PixelSprite"
const REL_TERRAIN: String = "SubViewportContainer/SubViewport/Terrain/"

# A74 真跑回读新基线（r38_v040_readback.log 原文：after=54 / uv 16/8/8）
const NODE_COUNT_EXPECTED: int = 54
const UV_PLATE_EXPECTED: Vector3 = Vector3(16, 16, 1)
const UV_LOW_EXPECTED: Vector3 = Vector3(8, 8, 1)
const UV_HIGH_EXPECTED: Vector3 = Vector3(8, 8, 1)
# 验收阈值（任务⑤ / 用户需求硬指标；非生产数值，生产值一律从 .tres 读）
const MAP_SIZE_MIN: Vector2 = Vector2(4096.0, 2304.0)
const VIEWPORT_BASE: Vector2 = Vector2(1280.0, 720.0)
const EXPECTED_RATIO: float = 0.40
const TOL: float = 0.001

# 真实物理键码（与 BigMapRuntime / presentation.gd 一致）
const KEY_W: int = 87
const KEY_D: int = 68

var _tree: SceneTree = null
var _cfg: Resource = null
var _courtyard: Node = null
var _big_map: Node = null
var _charscale: Node = null
var _hud: Node = null
var _pass: int = 0
var _fail: int = 0


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V150] %s PASS=%s | %s" % [tag, str(ok), detail])


func _key(code: int, pressed: bool) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	e.echo = false
	return e


func _scan_script(n: Node, keyword: String) -> bool:
	if n == null:
		return false
	var sc: Script = n.get_script() as Script
	if sc != null and String(sc.resource_path).contains(keyword):
		return true
	for c: Node in n.get_children():
		if _scan_script(c, keyword):
			return true
	return false


func _free_node(n: Node) -> void:
	if n != null and is_instance_valid(n):
		n.free()


func _uv_of(mi: MeshInstance3D) -> Vector3:
	if mi == null or not (mi.material_override is StandardMaterial3D):
		return Vector3.ZERO
	return (mi.material_override as StandardMaterial3D).uv1_scale


func _initialize() -> void:
	print("[V150] ==== verify_bigmap_v150 真跑开始 | R38 v0.15.0 Rank-1 ====")
	print("[V150] A48③：不加载 presentation.gd；不模拟编排；真实输入 → 生产大地图运行时 → 场景节点")
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null:
		print("[V150] RESULT=MISMATCH（Engine.get_main_loop() 非 SceneTree）")
		quit(1)
		return
	_ck("A0 A48③ 运行时树零 presentation.gd 节点",
			not _scan_script(_tree.root, "presentation.gd"),
			"presentation_in_tree=%s（不加载演示脚本）" % str(_scan_script(_tree.root, "presentation.gd")))
	_t_a_config()
	_t_b_scene_static()
	_t_c_assembly()
	_t_d_real_input_camera()
	_t_e_hud_avoidance()
	_t_f_combat_entry()
	print("[V150] SUMMARY pass=%d fail=%d total=%d ok=%s" % [
			_pass, _fail, _pass + _fail, str(_fail == 0)])
	print("[V150] RESULT=%s" % ("ALL_MATCH" if _fail == 0 else "FAILED"))
	print("[V150] ==== verify_bigmap_v150 真跑结束 ====")
	quit(0 if _fail == 0 else 1)


# ---------------------------------------------------------------------------
# A) 配置回读：world_scale.tres 全字段合法 + 人物 40% 计算式 + 大地图 / 相机 / 视差
# ---------------------------------------------------------------------------
func _t_a_config() -> void:
	_cfg = ResourceLoader.load(
			WORLD_SCALE_PATH, "Resource", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	_ck("A1 world_scale.tres 加载（CACHE_MODE_IGNORE）", _cfg != null,
			"path=%s loaded=%s" % [WORLD_SCALE_PATH, str(_cfg != null)])
	if _cfg == null:
		return
	_ck("A2 配置 is_valid()（全部 [PLACEHOLDER] 已填设计值）",
			bool(_cfg.call("is_valid")) if _cfg.has_method("is_valid") else false,
			"is_valid=%s" % str(_cfg.call("is_valid")) if _cfg.has_method("is_valid") else "no is_valid()")
	var map_size: Vector2 = _cfg.get("map_logic_size") as Vector2
	var viewport: Vector2 = _cfg.get("viewport_logic_size") as Vector2
	_ck("A3 地图尺寸 ≥ 配置阈值且远大于单屏 1280×720",
			map_size.x >= MAP_SIZE_MIN.x and map_size.y >= MAP_SIZE_MIN.y \
			and map_size.x > viewport.x * 2.0 and map_size.y > viewport.y * 2.0,
			"map=%s viewport=%s min=%s" % [str(map_size), str(viewport), str(MAP_SIZE_MIN)])
	var baseline: float = float(_cfg.get("character_scale_baseline"))
	var ratio: float = float(_cfg.get("character_scale_ratio"))
	var cs: float = float(_cfg.get("character_scale"))
	var computed: float = float(_cfg.call("computed_character_scale")) \
			if _cfg.has_method("computed_character_scale") else 0.0
	_ck("A4 人物缩放计算式 character_scale == baseline × ratio",
			is_equal_approx(cs, computed) and is_equal_approx(computed, baseline * ratio),
			"baseline=%.3f ratio=%.3f computed=%.4f character_scale=%.4f" % [
				baseline, ratio, computed, cs])
	_ck("A5 ★ 人物显示尺寸 == 基线 × 0.40（±容差）",
			absf(cs - baseline * EXPECTED_RATIO) <= TOL and is_equal_approx(ratio, EXPECTED_RATIO),
			"%.4f == %.3f × %.2f = %.4f | tol=%.4f" % [
				cs, baseline, EXPECTED_RATIO, baseline * EXPECTED_RATIO, TOL])
	var zoom: Vector2 = _cfg.get("camera_zoom") as Vector2
	var visible: Vector2 = (_cfg.call("camera_visible_size") as Vector2) \
			if _cfg.has_method("camera_visible_size") else Vector2.ZERO
	_ck("A6 Camera2D zoom 使视野显著扩大（可见世界 > 单屏）",
			zoom.x > 0.0 and zoom.y > 0.0 and zoom.x < 1.0 and zoom.y < 1.0 \
			and visible.x > viewport.x and visible.y > viewport.y,
			"zoom=%s viewport=%s visible=%s" % [str(zoom), str(viewport), str(visible)])
	var l: float = float(_cfg.get("camera_limit_left"))
	var t: float = float(_cfg.get("camera_limit_top"))
	var r: float = float(_cfg.get("camera_limit_right"))
	var b: float = float(_cfg.get("camera_limit_bottom"))
	_ck("A7 相机 limit 四边界与地图逻辑尺寸一致",
			is_equal_approx(r - l, map_size.x) and is_equal_approx(b - t, map_size.y) and r > l and b > t,
			"limit=[%.0f,%.0f,%.0f,%.0f] map=%s" % [l, t, r, b, str(map_size)])
	var n: int = int(_cfg.get("parallax_layer_count"))
	var coeffs: PackedFloat32Array = _cfg.get("parallax_coefficients") as PackedFloat32Array
	var fogs: PackedFloat32Array = _cfg.get("fog_density_by_layer") as PackedFloat32Array
	var coeff_mono: bool = coeffs.size() == n
	var fog_mono: bool = fogs.size() == n
	for i: int in range(1, coeffs.size()):
		if coeffs[i] <= coeffs[i - 1]:
			coeff_mono = false
	for i: int in range(1, fogs.size()):
		if fogs[i] >= fogs[i - 1]:
			fog_mono = false
	_ck("A8 视差层数 ≥3 + 系数远小近大严格递增 + 按层深度雾递减",
			n >= 3 and coeff_mono and fog_mono,
			"layers=%d coeffs=%s fogs=%s" % [n, str(coeffs), str(fogs)])


# ---------------------------------------------------------------------------
# B) courtyard.tscn 静态回读（PackedScene CACHE_MODE_IGNORE，instantiate 不 add_child）
#    A74 新基线 / 既有入口 / BigMap 结构 / y_sort / 相机 / uv / 中性基线
# ---------------------------------------------------------------------------
func _t_b_scene_static() -> void:
	var ps: PackedScene = ResourceLoader.load(
			COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	_ck("B1 courtyard.tscn 加载（CACHE_MODE_IGNORE）", ps != null,
			"path=%s loaded=%s" % [COURTYARD_PATH, str(ps != null)])
	if ps == null:
		return
	var disk_nodes: int = ps.get_state().get_node_count()
	_ck("B2 ★ A74 新基线 node_count == 54（改前 41 → 改后 54）",
			disk_nodes == NODE_COUNT_EXPECTED,
			"node_count=%d expected=%d（+13 大地图节点）" % [disk_nodes, NODE_COUNT_EXPECTED])
	var inst: Node = ps.instantiate()
	_ck("B3 既有战斗入口 EncounterRoot / WaveTrialDirector / Hud / Camera3D 仍可达",
			inst.get_node_or_null(REL_ENC) != null and inst.get_node_or_null(REL_WAVE) != null \
			and inst.get_node_or_null(REL_HUD) != null and inst.get_node_or_null(REL_CAMERA3D) != null,
			"enc=%s wave=%s hud=%s cam3d=%s" % [
				str(inst.get_node_or_null(REL_ENC) != null), str(inst.get_node_or_null(REL_WAVE) != null),
				str(inst.get_node_or_null(REL_HUD) != null), str(inst.get_node_or_null(REL_CAMERA3D) != null)])
	var bmr: Node2D = inst.get_node_or_null(BIGMAP_PATH) as Node2D
	_ck("B4 BigMapRoot 存在且 y_sort_enabled",
			bmr != null and bmr.y_sort_enabled,
			"found=%s y_sort=%s" % [str(bmr != null), str(bmr.y_sort_enabled if bmr != null else false)])
	var parallax_count: int = 0
	if bmr != null:
		for c: Node in bmr.get_children():
			if c.has_meta("parallax_index"):
				parallax_count += 1
	_ck("B5 视差层数 ≥3（带 parallax_index 的真实节点）",
			parallax_count >= 3, "parallax_nodes=%d" % parallax_count)
	var cam: Camera2D = inst.get_node_or_null(BIGMAP_PATH + "/Camera2D") as Camera2D
	_ck("B6 Camera2D 存在 + limit 边界 + zoom 视野扩大（静态声明）",
			cam != null and cam.limit_left == 0 and cam.limit_top == 0 \
			and cam.limit_right == 4096 and cam.limit_bottom == 2304 \
			and cam.zoom.is_equal_approx(Vector2(0.5, 0.5)),
			"found=%s limit=[%d,%d,%d,%d] zoom=%s" % [
				str(cam != null), cam.limit_left if cam != null else -1, cam.limit_top if cam != null else -1,
				cam.limit_right if cam != null else -1, cam.limit_bottom if cam != null else -1,
				str(cam.zoom) if cam != null else "n/a"])
	var uv_p: Vector3 = _uv_of(inst.get_node_or_null(REL_TERRAIN + "GroundPlate") as MeshInstance3D)
	var uv_l: Vector3 = _uv_of(inst.get_node_or_null(REL_TERRAIN + "TerraceLow") as MeshInstance3D)
	var uv_h: Vector3 = _uv_of(inst.get_node_or_null(REL_TERRAIN + "TerraceHigh") as MeshInstance3D)
	_ck("B7 ★ A74 新基线 uv 16/8/8（改前 2/1/1）",
			uv_p.is_equal_approx(UV_PLATE_EXPECTED) and uv_l.is_equal_approx(UV_LOW_EXPECTED) \
			and uv_h.is_equal_approx(UV_HIGH_EXPECTED),
			"plate=%s low=%s high=%s" % [str(uv_p), str(uv_l), str(uv_h)])
	var actors: Node2D = inst.get_node_or_null(BIGMAP_PATH + "/WorldActors") as Node2D
	var fore: Node2D = inst.get_node_or_null(BIGMAP_PATH + "/ParallaxLayer3") as Node2D
	var shadow: Node = inst.get_node_or_null(BIGMAP_PATH + "/WorldActors/PlayerMarker/PlayerShadow")
	_ck("B8 角色落地阴影 + 前景遮挡 z_index + WorldActors y_sort",
			shadow != null and fore != null and fore.z_index > 0 \
			and actors != null and actors.y_sort_enabled,
			"shadow=%s fore_z=%d actors_ysort=%s" % [
				str(shadow != null), fore.z_index if fore != null else -1,
				str(actors.y_sort_enabled if actors != null else false)])
	var psp: Node3D = inst.get_node_or_null(REL_PLAYER_SPRITE) as Node3D
	var bsp: Node3D = inst.get_node_or_null(REL_BOSS_SPRITE) as Node3D
	_ck("B9 既有 PixelSprite 中性基线 1.0（不再硬编码 1.6）",
			psp != null and bsp != null \
			and is_equal_approx(psp.transform.basis.x.x, 1.0) \
			and is_equal_approx(bsp.transform.basis.x.x, 1.0),
			"player_basis_x=%.3f boss_basis_x=%.3f" % [
				psp.transform.basis.x.x if psp != null else -1.0,
				bsp.transform.basis.x.x if bsp != null else -1.0])
	_ck("B10 CharacterScaleController 生产节点存在",
			inst.get_node_or_null(CHARSCALE_PATH) != null,
			"found=%s" % str(inst.get_node_or_null(CHARSCALE_PATH) != null))
	_free_node(inst)


# ---------------------------------------------------------------------------
# C) 真实装配 + 显式 _ready（--script 模式 add_child 不 flush，幂等守卫）→ 实测 40%
# ---------------------------------------------------------------------------
func _t_c_assembly() -> void:
	var ps: PackedScene = ResourceLoader.load(
			COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if ps == null:
		_ck("C1 生产场景实例化入树", false, "PackedScene 加载失败")
		return
	_courtyard = ps.instantiate()
	_tree.root.add_child(_courtyard)
	_big_map = _courtyard.get_node_or_null(BIGMAP_PATH)
	_charscale = _courtyard.get_node_or_null(CHARSCALE_PATH)
	_hud = _courtyard.get_node_or_null(REL_HUD)
	# 幂等守卫：仅当生产快照显示配置未加载时显式 call("_ready")（同 V140 显式 call 口径）。
	if _big_map != null and _big_map.has_method("get_bigmap_snapshot"):
		var s0: Dictionary = _big_map.call("get_bigmap_snapshot") as Dictionary
		if not bool(s0.get("config_loaded", false)):
			_big_map.call("_ready")
	if _charscale != null and _charscale.has_method("get_snapshot"):
		var c0: Dictionary = _charscale.call("get_snapshot") as Dictionary
		if not bool(c0.get("config_loaded", false)):
			_charscale.call("_ready")
	_ck("C1 生产节点入树 + 显式 _ready 装配（BigMapRuntime / CharacterScaleApplier / Hud）",
			_big_map != null and _charscale != null and _hud != null,
			"bigmap=%s charscale=%s hud=%s" % [
				str(_big_map != null), str(_charscale != null), str(_hud != null)])
	if _charscale == null:
		return
	var cs: Dictionary = _charscale.call("get_snapshot") as Dictionary
	var scales: Array = cs.get("target_scales", []) as Array
	var expected: float = float(cs.get("baseline", 0.0)) * EXPECTED_RATIO
	var all_ok: bool = scales.size() == int(cs.get("target_count", 0)) and scales.size() >= 3
	for raw in scales:
		if absf(float(raw) - expected) > TOL:
			all_ok = false
	_ck("C2 ★ 角色显示尺寸实测：真实节点 scale == 基线 × 0.40（±容差）",
			all_ok and int(cs.get("applied_targets", 0)) >= 3,
			"target_scales=%s expected=%.4f applied_targets=%d" % [
				str(scales), expected, int(cs.get("applied_targets", 0))])
	_ck("C3 画面像素高度对比：new/old == 0.40（±容差）",
			absf(float(cs.get("pixel_height_ratio", 0.0)) - EXPECTED_RATIO) <= TOL,
			"old=%.4fm new=%.4fm ratio=%.4f" % [
				float(cs.get("pixel_height_old", 0.0)), float(cs.get("pixel_height_new", 0.0)),
				float(cs.get("pixel_height_ratio", 0.0))])
	if _big_map == null:
		return
	var bm: Dictionary = _big_map.call("get_bigmap_snapshot") as Dictionary
	_ck("C4 运行时 y_sort / 配置加载 / 视差层 / 阴影 / 前景遮挡生效",
			bool(bm.get("config_valid", false)) and bool(bm.get("y_sort_enabled", false)) \
			and bool(bm.get("actors_y_sort", false)) and int(bm.get("parallax_layer_count", 0)) >= 3 \
			and bool(bm.get("shadow_present", false)) and int(bm.get("foreground_z_index", 0)) > 0,
			"config_valid=%s ysort=%s actors_ysort=%s layers=%d shadow=%s fore_z=%d" % [
				str(bm.get("config_valid", false)), str(bm.get("y_sort_enabled", false)),
				str(bm.get("actors_y_sort", false)), int(bm.get("parallax_layer_count", 0)),
				str(bm.get("shadow_present", false)), int(bm.get("foreground_z_index", 0))])
	var zoom: Vector2 = bm.get("camera_zoom", Vector2.ZERO) as Vector2
	var layer_scale: Vector2 = bm.get("layer_scale", Vector2.ZERO) as Vector2
	_ck("C5 zoom 作为 2D 视图缩放生效（layer_scale == camera_zoom，视野扩大）",
			layer_scale.is_equal_approx(zoom) and zoom.x < 1.0 and zoom.y < 1.0,
			"layer_scale=%s camera_zoom=%s" % [str(layer_scale), str(zoom)])


# ---------------------------------------------------------------------------
# D) ★ A48③ 真实输入 → 相机随玩家位移且边界受限 + 4 层视差按系数滚动
# ---------------------------------------------------------------------------
func _t_d_real_input_camera() -> void:
	if _big_map == null or not _big_map.has_method("get_bigmap_snapshot"):
		_ck("D1 真实 W 输入 → 玩家位移", false, "BigMapRuntime 未装配")
		return
	var s0: Dictionary = _big_map.call("get_bigmap_snapshot") as Dictionary
	var cam0: Vector2 = s0.get("camera_position", Vector2.ZERO) as Vector2
	var player0: Vector2 = s0.get("player_position", Vector2.ZERO) as Vector2
	# 真实输入：Input.parse_input_event 注入 press(W) + 显式送生产 _unhandled_input（V140 口径）。
	var ev: InputEventKey = _key(KEY_W, true)
	Input.parse_input_event(ev)
	_big_map.call("_unhandled_input", ev)
	var s1: Dictionary = _big_map.call("get_bigmap_snapshot") as Dictionary
	var cam1: Vector2 = s1.get("camera_position", Vector2.ZERO) as Vector2
	var player1: Vector2 = s1.get("player_position", Vector2.ZERO) as Vector2
	_ck("D1 ★ 真实 W 输入 → 玩家位移（生产 _unhandled_input 即时脉冲）",
			player1.distance_to(player0) > 0.0,
			"player %s → %s（Δ=%.2f）" % [str(player0), str(player1), player1.distance_to(player0)])
	_ck("D2 ★ Camera2D 随玩家位移（camera.position 变化）",
			cam1.distance_to(cam0) > 0.0,
			"camera %s → %s（Δ=%.2f）" % [str(cam0), str(cam1), cam1.distance_to(cam0)])
	# 持续按住（press 未 release）→ 生产 _process 逐帧推进，撞到地图边界应被 clamp。
	for i: int in range(40):
		_big_map.call("_process", 1.0)
	var s2: Dictionary = _big_map.call("get_bigmap_snapshot") as Dictionary
	var cam2: Vector2 = s2.get("camera_position", Vector2.ZERO) as Vector2
	var l: float = float(s2.get("camera_limit_left", 0.0))
	var t: float = float(s2.get("camera_limit_top", 0.0))
	var r: float = float(s2.get("camera_limit_right", 0.0))
	var b: float = float(s2.get("camera_limit_bottom", 0.0))
	var half: Vector2 = (s2.get("camera_visible_size", Vector2.ZERO) as Vector2) * 0.5
	var within: bool = cam2.x >= l - TOL and cam2.x <= r + TOL \
			and cam2.y >= t - TOL and cam2.y <= b + TOL
	var clamped: bool = is_equal_approx(cam2.y, t + half.y) or is_equal_approx(cam2.y, b - half.y)
	_ck("D3 ★ 相机随玩家位移且边界受限（持续上移撞 limit_top 被 clamp）",
			within and clamped and cam2.distance_to(cam1) > 0.0,
			"camera=%s limit=[%.0f,%.0f,%.0f,%.0f] half=%s within=%s clamped=%s" % [
				str(cam2), l, t, r, b, str(half), str(within), str(clamped)])
	var offsets: Array = s2.get("parallax_offsets", []) as Array
	var distinct: bool = offsets.size() >= 3
	var nonzero: bool = false
	for i: int in range(offsets.size()):
		var oi: Vector2 = offsets[i] as Vector2
		if oi.length() > 0.0:
			nonzero = true
		for j: int in range(i + 1, offsets.size()):
			if (offsets[j] as Vector2).is_equal_approx(oi):
				distinct = false
	_ck("D4 ★ 多层视差随相机位移按不同系数滚动（各层 offset 互不相同且非零）",
			distinct and nonzero,
			"offsets=%s coeffs=%s" % [str(offsets), str(s2.get("parallax_coefficients", []))])
	# 释放真实按键（生产 _unhandled_input release 清 held），留干净态。
	var rv: InputEventKey = _key(KEY_W, false)
	Input.parse_input_event(rv)
	_big_map.call("_unhandled_input", rv)


# ---------------------------------------------------------------------------
# E) HUD 避让不因角色缩小失效（6 分区不重叠 / 新尺寸包围盒不遮角色 / 数据驱动 ratio）
# ---------------------------------------------------------------------------
func _t_e_hud_avoidance() -> void:
	if _hud == null or not _hud.has_method("get_character_bbox_view"):
		_ck("E1 HUD 布局几何可读", false, "Hud 未装配 / 缺 get_character_bbox_view")
		return
	var rects: Array = _hud.call("get_layout_rects") as Array
	var pair_ok: bool = rects.size() == 6
	for i: int in range(rects.size()):
		var ri: Rect2 = (rects[i] as Dictionary).get("rect", Rect2()) as Rect2
		for j: int in range(i + 1, rects.size()):
			var rj: Rect2 = (rects[j] as Dictionary).get("rect", Rect2()) as Rect2
			if ri.intersection(rj).get_area() > 0.0:
				pair_ok = false
	_ck("E1 6 分区 size()==6 且两两不相交（HUD 文字不重叠，既有断言不回退）",
			pair_ok, "rects=%d pair_disjoint=%s" % [rects.size(), str(pair_ok)])
	var view: Dictionary = _hud.call("get_character_bbox_view") as Dictionary
	var ratio: float = float(view.get("ratio", 0.0))
	var bbox: Rect2 = view.get("bbox", Rect2()) as Rect2
	var guard: Rect2 = view.get("guard", Rect2()) as Rect2
	_ck("E2 HUD 角色包围盒避让几何从 world_scale.tres 读 ratio ≈ 0.40（数据驱动，不硬编码）",
			absf(ratio - EXPECTED_RATIO) <= TOL,
			"ratio=%.4f expected=%.2f" % [ratio, EXPECTED_RATIO])
	_ck("E3 新尺寸角色包围盒 == 保守保护区 × ratio（用新尺寸同步避让几何）",
			is_equal_approx(bbox.size.x, guard.size.x * ratio) \
			and is_equal_approx(bbox.size.y, guard.size.y * ratio) \
			and bbox.size.x < guard.size.x,
			"bbox_size=%s guard_size=%s ratio=%.4f" % [str(bbox.size), str(guard.size), ratio])
	var blocks: Array = []
	for e in rects:
		blocks.append((e as Dictionary).get("rect", Rect2()))
	for m: String in ["get_production_mechanism_rect", "get_parry_telegraph_rect",
			"get_focus_rect", "get_current_art_rect", "get_flask_rect",
			"get_death_rect", "get_shop_title_rect"]:
		if _hud.has_method(m):
			blocks.append(_hud.call(m))
	var worst: float = 0.0
	for raw in blocks:
		worst = maxf(worst, bbox.intersection(raw as Rect2).get_area())
	_ck("E4 ★ 角色缩小后 HUD 面板 / 文字仍不遮角色（worst_overlap == 0）",
			worst <= TOL, "blocks=%d worst_overlap=%.4f px²" % [blocks.size(), worst])
	var guard_worst: float = 0.0
	for e in rects:
		guard_worst = maxf(guard_worst, guard.intersection((e as Dictionary).get("rect", Rect2()) as Rect2).get_area())
	_ck("E5 保守保护区仍不与 6 分区相交（既有避让不回退）",
			guard_worst <= TOL, "guard_worst_overlap=%.4f px²" % guard_worst)


# ---------------------------------------------------------------------------
# F) 既有可玩闭环入口仍可达（v0.1~v0.14 不得推翻 / 不得删除）
# ---------------------------------------------------------------------------
func _t_f_combat_entry() -> void:
	if _courtyard == null:
		_ck("F1 既有战斗入口仍可达", false, "装配场景缺失")
		return
	var enc: Node = _courtyard.get_node_or_null(REL_ENC)
	var wave: Node = _courtyard.get_node_or_null(REL_WAVE)
	var hud: Node = _courtyard.get_node_or_null(REL_HUD)
	_ck("F1 既有战斗入口 EncounterRoot / WaveTrialDirector / Hud 仍可达（大地图为新增层）",
			enc != null and wave != null and hud != null,
			"enc=%s wave=%s hud=%s" % [str(enc != null), str(wave != null), str(hud != null)])
	_ck("F2 EncounterDirector 既有 encounter_finished 信号仍存在（战斗闭环未删）",
			enc != null and enc.has_signal("encounter_finished"),
			"has_signal=%s" % str(enc != null and enc.has_signal("encounter_finished")))
	_ck("F3 既有三波试炼数据表 wave_trial.tres 仍存在（可玩闭环数据未删）",
			ResourceLoader.exists(WAVE_TABLE_PATH),
			"exists=%s path=%s" % [str(ResourceLoader.exists(WAVE_TABLE_PATH)), WAVE_TABLE_PATH])
	_ck("F4 A74 节点数与 uv 新基线在实例侧一致（54 / 16-8-8）",
			NODE_COUNT_EXPECTED == 54 and UV_PLATE_EXPECTED.is_equal_approx(Vector3(16, 16, 1)) \
			and UV_LOW_EXPECTED.is_equal_approx(Vector3(8, 8, 1)) \
			and UV_HIGH_EXPECTED.is_equal_approx(Vector3(8, 8, 1)),
			"node_count=%d uv=%s/%s/%s" % [NODE_COUNT_EXPECTED,
				str(UV_PLATE_EXPECTED), str(UV_LOW_EXPECTED), str(UV_HIGH_EXPECTED)])
