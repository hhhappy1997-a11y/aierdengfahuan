class_name HybridSpriteRig
extends Node3D
## I-4：1 号对 Hybrid2D3D-Renderer GDExtension 精灵节点的薄封装。
## 场景里对外节点名固定为 Hybrid2D3DAnimatedSprite（见 场景树骨架.tscn）。
##
## 边界（契约硬约束）：
##  - 2 号**只**调用 set_pose(pose_name, frame_index)，不自己写 billboard / 锚定 / AABB。
##  - 1 号也不实现 billboard / 锚定 / 剔除算法，只负责转发姿态、应用帧尺寸、配置扩展节点参数。
##  - 像素→米缩放、底部中心锚定、自定义 AABB 由 GDExtension 节点提供；扩展未装入时
##    用内置 Sprite3D 占位（M0 仍可跑，只是没有逐帧动作）。
##  - 类名用 HybridSpriteRig 而非 Hybrid2D3DAnimatedSprite：避免与 GDExtension 注册的
##    全局类同名导致 Godot 4 启动报 "hides a global script class"。命名差异已列入 README 待裁决项。
##
## R2 更新（续派规则 §6 口径 5 / 6，I-4 冻结口径）：
##  - pose 名冻结，set_pose 做名称校验；非法 pose 只 warn、不转发。
##  - frame_index = **动作内帧索引**，clamp 归 1 号（本模块），**不扩展 I-4 接口**（签名不变）。
##  - Boss 阶段切换沿用 2 号的 pose_prefix（p1_ / p2_），不新增参数或方法。

signal pose_changed(pose_name: String, frame_index: int)

const PIXELS_PER_METER: float = 32.0
const DEFAULT_AABB_SIZE: Vector3 = Vector3(1.5, 1.8, 1.5)

## 冻结 pose 枚举（R2 口径 6）：基础 8 + Boss 3，不接受表外动作名。
const FROZEN_POSES: Array = [
	"idle", "walk", "run", "roll",
	"attack_light", "attack_heavy", "hitstun", "death",
	"dagger_slash", "staff_slam", "holy_hammer",
]
const POSE_PREFIXES: Array = ["p1_", "p2_"]

@export var sprite_node_path: NodePath = NodePath("PixelSprite")
## 帧尺寸来自 4 号 import.json（I-5），1 号只消费，不定义。
@export var frame_size: Vector2i = Vector2i(32, 48)
@export var pose_prefix: String = ""
@export var auto_aabb: bool = true
## 每个冻结 pose 的动作内帧数，由 1 号 I-5 导入流程按 import.json 回填（改数值不改代码）。
## 缺省时 frame_index 只做下限 clamp，不臆测上限。
@export var pose_frame_counts: Dictionary = {}

var _sprite: Node = null
var _current_pose: String = ""
var _current_frame: int = -1

# ---------------------------------------------------------------- 生命周期

func _ready() -> void:
	_sprite = get_node_or_null(sprite_node_path)
	if _sprite == null:
		push_warning("[HybridSpriteRig] 未找到精灵节点 %s，姿态只记录不显示。" % sprite_node_path)
		return
	_configure_anchor()
	_configure_aabb()

# ---------------------------------------------------------------- I-4 对外唯一接口（R2 不扩展）

func set_pose(pose_name: String, frame_index: int) -> void:
	## 2 号状态机调用：pose_name 用冻结枚举里的动作名；frame_index 为**动作内帧索引**。
	## 1 号负责名称校验与 frame_index clamp（续派规则 §6 口径 5），不扩展接口、不新增参数。
	var full_pose: String = _resolve_full_pose(pose_name)
	if full_pose.is_empty():
		push_warning("[HybridSpriteRig] 非法 pose 名被拒绝：%s（冻结表见 FROZEN_POSES）" % pose_name)
		return
	var base_pose: String = _base_pose_of(pose_name)
	var clamped_frame: int = _clamp_frame_index(base_pose, frame_index)
	if full_pose == _current_pose and clamped_frame == _current_frame:
		return
	_current_pose = full_pose
	_current_frame = clamped_frame

	if _sprite != null:
		if _sprite != self and _sprite.has_method("set_pose"):
			# 扩展节点原生接口，直接转发（含 clamp 后的动作内帧索引）。
			_sprite.call("set_pose", full_pose, clamped_frame)
		elif _sprite is AnimatedSprite3D:
			var asp: AnimatedSprite3D = _sprite as AnimatedSprite3D
			if asp.sprite_frames != null and asp.sprite_frames.has_animation(full_pose):
				asp.play(full_pose)
			asp.set("frame", clamped_frame)
		# Sprite3D 单帧占位不切帧：动作帧等 4 号 spritesheet 到位后由扩展节点接管。
	pose_changed.emit(full_pose, clamped_frame)


func get_current_pose() -> String:
	return _current_pose


func get_current_frame() -> int:
	return _current_frame


func set_frame_profile(size: Vector2i) -> void:
	## 供 1 号的 import.json 导入流程回填帧尺寸（I-5），改数值不改代码。
	frame_size = size
	_configure_anchor()

# ---------------------------------------------------------------- R2：pose 冻结与 frame clamp

func _resolve_full_pose(pose_name: String) -> String:
	## 支持两种传入：冻结基础名（前缀由 pose_prefix 提供）或自带 p1_/p2_ 前缀的完整名。
	var base: String = _base_pose_of(pose_name)
	if base.is_empty():
		return ""
	for raw_prefix in POSE_PREFIXES:
		var prefix: String = String(raw_prefix)
		if pose_name.begins_with(prefix):
			return prefix + base
	return pose_prefix + base


func _base_pose_of(pose_name: String) -> String:
	var base: String = pose_name
	for raw_prefix in POSE_PREFIXES:
		var prefix: String = String(raw_prefix)
		if pose_name.begins_with(prefix):
			base = pose_name.substr(prefix.length())
			break
	if FROZEN_POSES.has(base):
		return base
	return ""


func _clamp_frame_index(base_pose: String, frame_index: int) -> int:
	## frame_index 是动作内帧索引：下限 0，上限由该 pose 的帧数决定（clamp 归 1 号）。
	var lower: int = maxi(0, frame_index)
	var frame_count: int = _frame_count_for(base_pose)
	if frame_count > 0:
		return mini(lower, frame_count - 1)
	return lower


func _frame_count_for(base_pose: String) -> int:
	if pose_frame_counts.has(base_pose):
		return maxi(1, int(pose_frame_counts[base_pose]))
	if _sprite is AnimatedSprite3D:
		var asp: AnimatedSprite3D = _sprite as AnimatedSprite3D
		if asp.sprite_frames != null and asp.sprite_frames.has_animation(base_pose):
			return maxi(1, asp.sprite_frames.get_frame_count(base_pose))
	return 0

# ---------------------------------------------------------------- 内部装配（非 billboard 实现）

func _configure_anchor() -> void:
	if _sprite == null:
		return
	# 32px = 1m；底部中心锚定使节点 origin 直接落在地面高度上，无需半身高补偿。
	if _has_property(_sprite, "pixel_size"):
		_sprite.set("pixel_size", 1.0 / PIXELS_PER_METER)
	if _has_property(_sprite, "centered"):
		_sprite.set("centered", false)
	if _has_property(_sprite, "offset"):
		_sprite.set("offset", Vector2(-float(frame_size.x) * 0.5, -float(frame_size.y)))


func _configure_aabb() -> void:
	## 固定 AABB 覆盖动作最大外接框，防止像素角色靠近屏幕边缘被整帧剔除。
	## 属性/方法名以本机装入的 GDExtension 实际 API 为准，M0 装入后校准；此处全部有守卫，
	## 扩展不在时静默跳过，不自己算剔除盒。
	if not auto_aabb or _sprite == null:
		return
	var box: AABB = AABB(Vector3(-0.75, 0.0, -0.75), DEFAULT_AABB_SIZE)
	if _sprite.has_method("set_custom_aabb"):
		_sprite.call("set_custom_aabb", box)
	elif _has_property(_sprite, "custom_aabb"):
		_sprite.set("custom_aabb", box)


func _has_property(node: Node, prop: String) -> bool:
	for entry in node.get_property_list():
		if String(entry.get("name", "")) == prop:
			return true
	return false
