class_name BigMapRuntime
extends Node2D
## R38 / v0.15.0「大地图 · 2.5D 尺度重构」· 分区世界层生产运行时（Rank-1 唯一写入）
## 挂点：courtyard.tscn → BigMapLayer/BigMapRoot（Node2D，y_sort_enabled）。
##
## 职责（数值一律从 res://data/render/world_scale.tres 读，禁止散落硬编码）：
##   ① Camera2D 跟随玩家 + limit 边界 clamp + zoom 视野显著扩大；
##   ② 4 层视差按不同系数随相机位移滚动（远景色带/中景地形与地标/地面 tile/前景遮挡）；
##   ③ y-sort（BigMapRoot + WorldActors）+ 前景遮挡层 z_index；
##   ④ 角色落地阴影（PlayerShadow）+ 按层深度雾（各层 CanvasItem.modulate）；
##   ⑤ 真实 WASD / 方向键 _unhandled_input → 玩家位移（点按脉冲 + 按住持续）。
##
## 【不切后端 / 不引入真 3D 网格】本层为 Node2D + CanvasItem 体系（仍 gl_compatibility）；
##   2D 视图变换以 BigMapRoot.scale = camera_zoom 实现（zoom<1 → 同屏可见范围扩大），
##   不接管 root viewport 的 canvas_transform，避免影响既有 SubViewportContainer 的 3D 画面。
## 【A48③ 真实可达】verify_bigmap_v150.gd 注入真实 InputEventKey → 显式送本节点
##   _unhandled_input → 生产 _process 推进 → 相机 / 视差 / 角色层真实运行时变化，
##   不加载 presentation.gd、不在验证脚本内模拟编排。
## 【SceneTree --script 纪律】add_child 不自动 flush _ready，需显式 call("_ready")。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 / 零外部依赖 / 零 GPU job。

const WORLD_SCALE_PATH: String = "res://data/render/world_scale.tres"

# 真实物理键码（与 presentation.gd / V150 注入一致；WASD + 四方向键）
const KEY_W: int = 87
const KEY_A: int = 65
const KEY_S: int = 83
const KEY_D: int = 68
const KEY_UP: int = 4194320
const KEY_LEFT: int = 4194319
const KEY_DOWN: int = 4194322
const KEY_RIGHT: int = 4194321
const MOVE_KEYS: Array = [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_LEFT, KEY_DOWN, KEY_RIGHT]

var _cfg: Resource = null
var _camera: Camera2D = null
var _player: Node2D = null
var _shadow: Node2D = null
var _body: Node2D = null
var _actors: Node2D = null
var _parallax_layers: Array = []
var _foreground: Node2D = null
var _held: Dictionary = {}
var _pulse_dir: Vector2 = Vector2.ZERO
var _pulse_pending: int = 0


func _ready() -> void:
	_cfg = ResourceLoader.load(WORLD_SCALE_PATH, "Resource", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	if _cfg == null:
		push_warning("[R38][BigMap] world_scale.tres 未加载 → 大地图运行时降级为不推进（如实告警，不伪造）")
		return
	_resolve_nodes()
	_apply_static_configuration()
	_center_on_map()


func _resolve_nodes() -> void:
	_camera = get_node_or_null("Camera2D") as Camera2D
	_player = get_node_or_null("WorldActors/PlayerMarker") as Node2D
	_shadow = get_node_or_null("WorldActors/PlayerMarker/PlayerShadow") as Node2D
	_body = get_node_or_null("WorldActors/PlayerMarker/PlayerBody") as Node2D
	_actors = get_node_or_null("WorldActors") as Node2D
	_parallax_layers.clear()
	var n: int = int(_cfg.get("parallax_layer_count"))
	for i: int in range(n):
		var layer: Node2D = get_node_or_null("ParallaxLayer%d" % i) as Node2D
		if layer != null:
			_parallax_layers.append(layer)
	_foreground = get_node_or_null("ParallaxLayer%d" % (n - 1)) as Node2D


func _apply_static_configuration() -> void:
	# zoom<1 → 整层缩小 → 同屏可见 2× 范围（视野显著扩大），数据驱动。
	scale = _cfg.get("camera_zoom") as Vector2
	y_sort_enabled = bool(_cfg.get("y_sort_enabled"))
	if _actors != null:
		_actors.y_sort_enabled = true
	if _camera != null:
		_camera.zoom = _cfg.get("camera_zoom") as Vector2
		_camera.limit_left = int(_cfg.get("camera_limit_left"))
		_camera.limit_top = int(_cfg.get("camera_limit_top"))
		_camera.limit_right = int(_cfg.get("camera_limit_right"))
		_camera.limit_bottom = int(_cfg.get("camera_limit_bottom"))
	var fz: int = int(_cfg.get("foreground_z_index"))
	if _foreground != null:
		_foreground.z_index = fz
	# 按层深度雾：纯 2D CanvasItem.modulate 叠色（远浓近淡、硬边无噪点、零 GPU job）。
	var fog: PackedFloat32Array = _cfg.get("fog_density_by_layer") as PackedFloat32Array
	for i: int in range(_parallax_layers.size()):
		if i < fog.size():
			var d: float = clampf(1.0 - fog[i], 0.0, 1.0)
			(_parallax_layers[i] as Node2D).modulate = Color(d, d, d, 1.0)


func _center_on_map() -> void:
	if _cfg == null:
		return
	var size: Vector2 = _cfg.get("map_logic_size") as Vector2
	if _player != null:
		_player.position = size * 0.5
	_sync_camera_and_parallax()


func _clamp_camera(want: Vector2) -> Vector2:
	if _cfg == null:
		return want
	var half: Vector2 = Vector2.ZERO
	if _cfg.has_method("camera_visible_size"):
		half = (_cfg.call("camera_visible_size") as Vector2) * 0.5
	var l: float = float(_cfg.get("camera_limit_left"))
	var t: float = float(_cfg.get("camera_limit_top"))
	var r: float = float(_cfg.get("camera_limit_right"))
	var b: float = float(_cfg.get("camera_limit_bottom"))
	var min_x: float = l + half.x
	var max_x: float = maxf(min_x, r - half.x)
	var min_y: float = t + half.y
	var max_y: float = maxf(min_y, b - half.y)
	return Vector2(clampf(want.x, min_x, max_x), clampf(want.y, min_y, max_y))


func _clamp_player() -> void:
	if _player == null or _cfg == null:
		return
	var size: Vector2 = _cfg.get("map_logic_size") as Vector2
	_player.position = Vector2(clampf(_player.position.x, 0.0, size.x),
			clampf(_player.position.y, 0.0, size.y))


func _sync_camera_and_parallax() -> void:
	if _cfg == null or _player == null:
		return
	if _camera != null:
		# 相机跟随玩家 + 边界受限（数据驱动 clamp）。
		_camera.position = _clamp_camera(_player.position)
		var cam_pos: Vector2 = _camera.position
		var coeffs: PackedFloat32Array = _cfg.get("parallax_coefficients") as PackedFloat32Array
		# 多层视差：层世界位移 = 相机位移 × 各层系数（远小近大、互不相同）。
		for i: int in range(_parallax_layers.size()):
			if i < coeffs.size():
				(_parallax_layers[i] as Node2D).position = cam_pos * coeffs[i]
	# 角色落地阴影：挂在 PlayerMarker 下、脚下略偏（2D 椭圆由占位节点表达）。
	if _shadow != null:
		_shadow.position = Vector2(0.0, 4.0)


func _dir_for_key(code: int) -> Vector2:
	match code:
		KEY_W, KEY_UP:
			return Vector2(0.0, -1.0)
		KEY_S, KEY_DOWN:
			return Vector2(0.0, 1.0)
		KEY_A, KEY_LEFT:
			return Vector2(-1.0, 0.0)
		KEY_D, KEY_RIGHT:
			return Vector2(1.0, 0.0)
	return Vector2.ZERO


func _direction_from_held() -> Vector2:
	var d: Vector2 = Vector2.ZERO
	for raw in _held.keys():
		d += _dir_for_key(int(raw))
	return d


func _unhandled_input(event: InputEvent) -> void:
	if _cfg == null or _player == null:
		return
	if not (event is InputEventKey):
		return
	var k: InputEventKey = event as InputEventKey
	var code: int = int(k.physical_keycode)
	if not MOVE_KEYS.has(code):
		return
	if k.pressed and not k.echo:
		_held[code] = true
		_pulse_dir = _dir_for_key(code)
		_pulse_pending += 1
		# 点按脉冲：真实 press 事件即时走一步（演示 press+release 同帧配对也生效）。
		var step: float = float(_cfg.get("input_pulse_delta"))
		var speed: float = float(_cfg.get("player_move_speed"))
		_player.position += _pulse_dir * speed * step
		_clamp_player()
		_sync_camera_and_parallax()
	elif not k.pressed:
		_held.erase(code)


func _process(delta: float) -> void:
	if _cfg == null or _player == null:
		return
	var dir: Vector2 = _direction_from_held()
	var move: Vector2 = Vector2.ZERO
	var speed: float = float(_cfg.get("player_move_speed"))
	if dir != Vector2.ZERO:
		# 持续按住：按真实 delta 推进（实机探索）。
		move = dir.normalized() * speed * maxf(0.0, delta)
	elif _pulse_pending > 0:
		# 点按脉冲的兜底帧消费（press+release 同帧时 _held 已清空）。
		move = _pulse_dir * speed * float(_cfg.get("input_pulse_delta"))
		_pulse_pending -= 1
	if move != Vector2.ZERO:
		_player.position += move
		_clamp_player()
		_sync_camera_and_parallax()


## 只读运行时快照（供 verify_bigmap_v150.gd / presentation.gd 回读，不写任何状态）。
func get_bigmap_snapshot() -> Dictionary:
	var offsets: Array = []
	for raw in _parallax_layers:
		offsets.append((raw as Node2D).position)
	var coeffs: Array = []
	var fog: Array = []
	if _cfg != null:
		var c: PackedFloat32Array = _cfg.get("parallax_coefficients") as PackedFloat32Array
		for v: float in c:
			coeffs.append(v)
		var f: PackedFloat32Array = _cfg.get("fog_density_by_layer") as PackedFloat32Array
		for v: float in f:
			fog.append(v)
	return {
		"config_loaded": _cfg != null,
		"config_valid": bool(_cfg.call("is_valid")) if (_cfg != null and _cfg.has_method("is_valid")) else false,
		"map_logic_size": _cfg.get("map_logic_size") if _cfg != null else Vector2.ZERO,
		"viewport_logic_size": _cfg.get("viewport_logic_size") if _cfg != null else Vector2.ZERO,
		"character_scale": float(_cfg.get("character_scale")) if _cfg != null else 0.0,
		"character_scale_baseline": float(_cfg.get("character_scale_baseline")) if _cfg != null else 0.0,
		"character_scale_ratio": float(_cfg.get("character_scale_ratio")) if _cfg != null else 0.0,
		"camera_zoom": _cfg.get("camera_zoom") if _cfg != null else Vector2.ZERO,
		"camera_visible_size": (_cfg.call("camera_visible_size") as Vector2) if (_cfg != null and _cfg.has_method("camera_visible_size")) else Vector2.ZERO,
		"camera_limit_left": float(_cfg.get("camera_limit_left")) if _cfg != null else 0.0,
		"camera_limit_top": float(_cfg.get("camera_limit_top")) if _cfg != null else 0.0,
		"camera_limit_right": float(_cfg.get("camera_limit_right")) if _cfg != null else 0.0,
		"camera_limit_bottom": float(_cfg.get("camera_limit_bottom")) if _cfg != null else 0.0,
		"camera_position": _camera.position if _camera != null else Vector2.ZERO,
		"player_position": _player.position if _player != null else Vector2.ZERO,
		"parallax_layer_count": _parallax_layers.size(),
		"parallax_offsets": offsets,
		"parallax_coefficients": coeffs,
		"fog_density_by_layer": fog,
		"y_sort_enabled": y_sort_enabled,
		"actors_y_sort": _actors.y_sort_enabled if _actors != null else false,
		"foreground_z_index": _foreground.z_index if _foreground != null else 0,
		"shadow_present": _shadow != null,
		"body_present": _body != null,
		"layer_scale": scale,
	}
