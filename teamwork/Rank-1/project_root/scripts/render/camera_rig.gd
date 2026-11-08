extends Node3D
## 相机跟随 + SubViewport 低分辨率缓冲 / 整数倍放大（1 号 R2 交付件）。
## 落位：res://scripts/render/camera_rig.gd，M1 起挂到 Main.tscn 的相机链路。
##
## 冻结值（R2，供 4 号 A4 / A8 使用，见 DONE-R2.md「给 4 号的冻结值」）：
##   LOW_RESOLUTION_WIDTH   = 640
##   LOW_RESOLUTION_HEIGHT  = 360
##   INTEGER_UPSCALE_FACTOR = 2        （窗口基准 1280x720 / 2 = 640x360）
##   PIXELS_PER_METER       = 32.0     （32 px = 1 m）
## 4 号 A8 假设 640x360 @3x；本工位按 R1 场景骨架 stretch_shrink=2 冻结为 @2x，
## 3x / 2x 分歧登记在 README.md §7「待主 AI 裁决」，由 HOST 转交 4 号，不擅自改骨架。

const LOW_RESOLUTION_WIDTH: int = 640
const LOW_RESOLUTION_HEIGHT: int = 360
const INTEGER_UPSCALE_FACTOR: int = 2
const PIXELS_PER_METER: float = 32.0
const PIXEL_WORLD_STEP_M: float = 1.0 / PIXELS_PER_METER

@export var sub_viewport_container_path: NodePath = NodePath("")
@export var sub_viewport_path: NodePath = NodePath("")
@export var follow_target_path: NodePath = NodePath("")
@export var follow_rate: float = 8.0
@export var deadzone_m: float = 0.1
@export var shake_offset: Vector3 = Vector3.ZERO

var _container: SubViewportContainer = null
var _viewport: SubViewport = null
var _camera: Camera3D = null
var _target: Node3D = null
var _smoothed_position: Vector3 = Vector3.ZERO
var _initialized: bool = false


func _ready() -> void:
	_resolve_nodes()
	apply_viewport_preset(LOW_RESOLUTION_WIDTH, LOW_RESOLUTION_HEIGHT, INTEGER_UPSCALE_FACTOR)


func _resolve_nodes() -> void:
	if sub_viewport_container_path != NodePath(""):
		_container = get_node_or_null(sub_viewport_container_path) as SubViewportContainer
	if sub_viewport_path != NodePath(""):
		_viewport = get_node_or_null(sub_viewport_path) as SubViewport
	if follow_target_path != NodePath(""):
		_target = get_node_or_null(follow_target_path) as Node3D
	_camera = get_node_or_null("Camera3D") as Camera3D
	if _camera == null:
		_camera = get_parent() as Camera3D
	if _target != null:
		_smoothed_position = _target.global_position
		_initialized = true


func apply_viewport_preset(width: int, height: int, upscale_factor: int) -> void:
	## 按档位设置低分辨率缓冲与整数倍放大；只允许整数倍，禁止 1.5x 之类非整数比。
	var factor: int = maxi(1, upscale_factor)
	if _viewport != null:
		_viewport.size = Vector2i(width, height)
	if _container != null:
		_container.stretch = true
		_container.stretch_shrink = factor
		_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	if _target == null or not _initialized or _camera == null:
		return
	var goal: Vector3 = _target.global_position
	if _smoothed_position.distance_to(goal) < deadzone_m:
		return
	var alpha: float = 1.0 - exp(-follow_rate * delta)
	_smoothed_position = _smoothed_position.lerp(goal, clampf(alpha, 0.0, 1.0))
	# 相机位移量化到 1 像素（1/32 m）整数步进，消除亚像素抖动；物理与玩法坐标保持浮点连续。
	var quantized: Vector3 = _snap_to_pixel(_smoothed_position)
	_camera.global_position = quantized + shake_offset


func _snap_to_pixel(pos: Vector3) -> Vector3:
	## 用 Vector3 成员方法 snapped() 做整像素步进，不依赖全局 snappedf 之类变体函数。
	return pos.snapped(Vector3(PIXEL_WORLD_STEP_M, PIXEL_WORLD_STEP_M, PIXEL_WORLD_STEP_M))


func get_pixels_per_meter() -> float:
	## 给 4 号 A4 的像素→米缩放比（与 project.godot [hd2d]/render/pixels_per_meter 一致）。
	return PIXELS_PER_METER


func get_low_resolution_size() -> Vector2i:
	return Vector2i(LOW_RESOLUTION_WIDTH, LOW_RESOLUTION_HEIGHT)


func get_integer_upscale_factor() -> int:
	return INTEGER_UPSCALE_FACTOR
