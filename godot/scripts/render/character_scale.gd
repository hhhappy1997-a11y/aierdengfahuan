class_name CharacterScaleApplier
extends Node
## R38 / v0.15.0「人物显示尺寸 40%（硬指标）」· 角色缩放生产脚本（Rank-1 唯一写入）
## 挂点：courtyard.tscn → CharacterScaleController（根节点 Courtyard 下）。
##
## 【不再硬编码 1.6】既有 courtyard.tscn 两个 PixelSprite 的 transform 由
##   Transform3D(1.6, …) 改为中性 (1.0, …)；运行时缩放一律从
##   res://data/render/world_scale.tres 的 character_scale 读取
##   （= baseline × ratio = 1.6 × 0.40 = 0.64），本脚本不出现 1.6 / 0.64 字面量。
## 【数据驱动唯一入口】改缩放只改 .tres（只改表不改代码）；hud.gd 的角色包围盒
##   避让几何也从同一张表读 ratio，保证「缩放 → 避让」同源同步。
## 【不切后端 / 不引入真 3D 网格】只写既有 CanvasItem/Node3D 的 scale 属性，
##   不动 pose / AABB / billboard（HybridSpriteRig 既有职责逐字不动）。
## 【A48③ 真实可达】courtyard.tscn 静态挂载的生产运行时节点；verify_bigmap_v150.gd
##   显式 call("_ready") 后回读真实节点 scale（不加载 presentation.gd、不模拟编排）。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 / 零外部依赖 / 零 GPU job。

const WORLD_SCALE_PATH: String = "res://data/render/world_scale.tres"
# 目标节点路径（相对本节点 CharacterScaleController：`../` 回到根 Courtyard）：
#   既有 3D 角色 ×2 + 新增 2D 大地图角色 ×1。get_node_or_null 按【自身】解析，
#   故必须以 `../` 起（V150 C2 真跑实证：漏 `../` 会全部寻址失败 → applied_targets=0）。
# 路径是结构声明、不是数值，故不进 .tres（数值口径一律从表读）。
const TARGET_PATHS: Array = [
	"../SubViewportContainer/SubViewport/Player/Hybrid2D3DAnimatedSprite/PixelSprite",
	"../SubViewportContainer/SubViewport/BossVisual/Hybrid2D3DAnimatedSprite/PixelSprite",
	"../BigMapLayer/BigMapRoot/WorldActors/PlayerMarker/PlayerBody",
]

var _cfg: Resource = null
var _applied_scale: float = -1.0
var _applied_targets: int = 0


func _ready() -> void:
	_cfg = ResourceLoader.load(WORLD_SCALE_PATH, "Resource", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	if _cfg == null:
		push_warning("[R38][CharScale] world_scale.tres 未加载 → 保持中性 scale（如实告警，不伪造）")
		return
	apply_character_scale()


func apply_character_scale() -> void:
	if _cfg == null:
		return
	var s: float = float(_cfg.get("character_scale"))
	_applied_scale = s
	_applied_targets = 0
	for raw in TARGET_PATHS:
		var p: String = String(raw)
		var n: Node = get_node_or_null(NodePath(p))
		if n == null:
			continue
		if n is Node3D:
			(n as Node3D).scale = Vector3(s, s, s)
			_applied_targets += 1
		elif n is Node2D:
			(n as Node2D).scale = Vector2(s, s)
			_applied_targets += 1


## 只读快照：真实节点 scale 回读 + 基线/比例/计算式/画面像素高度对比（供 V150 断言）。
func get_snapshot() -> Dictionary:
	var scales: Array = []
	for raw in TARGET_PATHS:
		var p: String = String(raw)
		var n: Node = get_node_or_null(NodePath(p))
		if n is Node3D:
			scales.append((n as Node3D).scale.x)
		elif n is Node2D:
			scales.append((n as Node2D).scale.x)
		else:
			scales.append(-1.0)
	var baseline: float = float(_cfg.get("character_scale_baseline")) if _cfg != null else 0.0
	var computed: float = float(_cfg.call("computed_character_scale")) \
			if (_cfg != null and _cfg.has_method("computed_character_scale")) else 0.0
	var h_old: float = float(_cfg.call("character_pixel_height", baseline)) \
			if (_cfg != null and _cfg.has_method("character_pixel_height")) else 0.0
	var h_new: float = float(_cfg.call("character_pixel_height", _applied_scale)) \
			if (_cfg != null and _cfg.has_method("character_pixel_height")) else 0.0
	return {
		"config_loaded": _cfg != null,
		"applied_scale": _applied_scale,
		"applied_targets": _applied_targets,
		"target_count": TARGET_PATHS.size(),
		"target_scales": scales,
		"baseline": baseline,
		"ratio": float(_cfg.get("character_scale_ratio")) if _cfg != null else 0.0,
		"computed": computed,
		"pixel_height_old": h_old,
		"pixel_height_new": h_new,
		"pixel_height_ratio": (h_new / h_old) if h_old > 0.0 else 0.0,
	}
