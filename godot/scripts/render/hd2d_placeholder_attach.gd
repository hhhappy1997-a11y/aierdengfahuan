class_name HD2DPlaceholderAttach
extends RefCounted
## R7 挂载辅助脚本（Rank-4 交付 · 可被 Rank-1 构建脚本一行消费）
## 定位：把 godot/scripts/render/hd2d_placeholder.gd 挂进场景的「背景层」。
## 因为 godot/scenes/ 归 Rank-1 独占，本脚本不写 courtyard.tscn、不改 project.godot，
## 只提供 attach() / find_placeholder() / detach() 三个静态方法，由 1 号在
## build_courtyard.gd（或运行时场景脚本）里显式调用一行完成挂载。
## 零外部依赖：只用 load() 加载工程内既有 .gd，不加载 PNG / 贴图 / 插件 / 云服务 / 付费 API。
## 路线优先级：ComfyUI 仍是主美术路线；qwen-image 仅本地零付费备选；
## 本占位仅 M0 构图验证 / 显存不足降级，不取代二者、不宣称已能出图。
## 退出：assets/generated/bg_layers/ 与 chars/ 有首批合规 spritesheet 且 1 号完成
##       纹理层接入后，调用 detach() 移除本背景层，逐层替换为 draw_texture_rect() / Sprite。

const PLACEHOLDER_SCRIPT_PATH: String = "res://scripts/render/hd2d_placeholder.gd"
const LAYER_NAME: String = "HD2DPlaceholderLayer"
const NODE_NAME: String = "HD2DPlaceholder"
const DEFAULT_CANVAS_LAYER: int = -10     # 背景层（绘制序靠前；实际遮挡由 1 号结合场景裁决）
const DEFAULT_INTEGER_SCALE: int = 2      # 对齐 project.godot render/integer_upscale_factor=2 / 1280×720


## 把程序化占位挂到 parent 下新建的 CanvasLayer 背景层，返回占位 Node2D。
## config 可覆盖：canvas_layer(int) / integer_scale(int) / placeholder_enabled(bool) /
##   cam_x(float) / cam_y(float) / light_pos(Vector2)。
## 幂等：若同名背景层已存在，复用并返回其中的占位节点，不重复挂载、不覆盖既有节点。
static func attach(parent: Node, config: Dictionary = {}) -> Node2D:
	if parent == null:
		push_warning("[HD2DPlaceholderAttach] parent 为 null，跳过挂载。")
		return null
	var existing: Node2D = find_placeholder(parent)
	if existing != null:
		return existing
	var placeholder_script: Script = load(PLACEHOLDER_SCRIPT_PATH) as Script
	if placeholder_script == null:
		push_warning("[HD2DPlaceholderAttach] 未找到 %s，占位未挂载（不伪造输出）。" % PLACEHOLDER_SCRIPT_PATH)
		return null
	var layer_index: int = int(config.get("canvas_layer", DEFAULT_CANVAS_LAYER))
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = LAYER_NAME
	layer.layer = layer_index
	parent.add_child(layer)
	var placeholder: Node2D = Node2D.new()
	placeholder.name = NODE_NAME
	placeholder.set_script(placeholder_script)
	placeholder.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	placeholder.set("integer_scale", int(config.get("integer_scale", DEFAULT_INTEGER_SCALE)))
	placeholder.set("placeholder_enabled", bool(config.get("placeholder_enabled", true)))
	placeholder.set("cam_x", float(config.get("cam_x", 0.0)))
	placeholder.set("cam_y", float(config.get("cam_y", 0.0)))
	if config.has("light_pos"):
		placeholder.set("light_pos", config["light_pos"])
	layer.add_child(placeholder)
	return placeholder


## 查找已挂载的占位节点（未挂载返回 null）。
static func find_placeholder(parent: Node) -> Node2D:
	if parent == null:
		return null
	var layer: Node = parent.get_node_or_null(LAYER_NAME)
	if layer == null:
		return null
	var placeholder: Node = layer.get_node_or_null(NODE_NAME)
	return placeholder as Node2D


## 退出条件辅助：移除背景层及其占位节点（占位被纹理层替换后调用）。
static func detach(parent: Node) -> bool:
	if parent == null:
		return false
	var layer: Node = parent.get_node_or_null(LAYER_NAME)
	if layer == null:
		return false
	parent.remove_child(layer)
	layer.queue_free()
	return true
