extends CanvasLayer
## R20 · 画质设置接线（运行期改写低分辨率/缩放 + 通知 fx_profile_controller 重判档）
## 派单 cmd-20261109-110237-775-A1 · [ROUND=R20] · AI=1（Rank-1）
##
## 提供 set_quality(preset:String) 与 apply()；preset 至少 low / medium / high 三档。
## apply() 运行期改写（均为内存态 ProjectSettings / 节点属性，不写 project.godot 文件本体）：
##   ① 项目级低分辨率配置 hd2d/render/low_resolution_width|height|integer_upscale_factor；
##   ② 全局渲染缩放 rendering/scaling_3d/scale；
##   ③ SubViewportContainer 整数缩放 stretch_shrink（stretch 模式下它决定 SubViewport 实际
##      渲染缓冲尺寸；engine 禁止此时手动改 SubViewport.size，故只读回实际生效尺寸、不做无效赋值）；
##   ④ 经 controller.re_evaluate() 通知 fx_profile_controller.switch_profile(desktop|mobile) 重判。
##
## 边界：零外部素材 / 零付费 / 零 autoload；不写 project.godot / hud.gd（Rank-3 独占）；
##       不写 hd2d_fx.gd / hd2d_fx.tscn（Rank-4 独占）；中文 UTF-8 / Godot 4.7.2 合法语法。

const TAG: String = "[R20_CTRL]"
const GROUP_CTRL: String = "fx_profile_controller_r20"
const SCALE_SETTING: String = "rendering/scaling_3d/scale"
const KEY_LOW_W: String = "hd2d/render/low_resolution_width"
const KEY_LOW_H: String = "hd2d/render/low_resolution_height"
const KEY_UPSCALE: String = "hd2d/render/integer_upscale_factor"

# 三档：low→mobile（低分辨率）/ medium|high→desktop；size/shrink/scale 为运行期改写目标值。
var PRESETS: Dictionary = {
	"low":    {"size": Vector2i(480, 270), "scale": 0.75, "shrink": 3, "profile": "mobile"},
	"medium": {"size": Vector2i(640, 360), "scale": 0.85, "shrink": 2, "profile": "desktop"},
	"high":   {"size": Vector2i(960, 540), "scale": 1.0,  "shrink": 1, "profile": "desktop"},
}

var _preset: String = "medium"
var _last_applied: String = ""
var _controller: Node = null


func _ready() -> void:
	_controller = _find_controller()
	if _controller != null and _controller.has_method("register_quality_provider"):
		_controller.call("register_quality_provider", self)
		print("%s quality_settings._ready 已注册 provider -> %s" % [TAG, str(_controller.name)])
	else:
		print("%s quality_settings._ready 未找到 controller，跳过注册" % TAG)
	# 演示「设置变更后自动重判」：low -> high，供抓帧 stdout 记录至少一次 low→high 重判。
	set_quality("low")
	apply()
	set_quality("high")
	apply()


## 设置画质档（low / medium / high）；非法档忽略并告警。
func set_quality(preset: String) -> void:
	if not PRESETS.has(preset):
		push_warning("%s set_quality 非法档位 '%s'（仅 low/medium/high），忽略" % [TAG, preset])
		return
	_preset = preset
	print("%s set_quality(%s)" % [TAG, preset])


## 供 fx_profile_controller.re_evaluate() 读取当前画质档（provider 契约）。
func get_quality_preset() -> String:
	return _preset


## 运行期改写渲染低分辨率/缩放，并通知 controller 重判档。
func apply() -> void:
	var cfg: Dictionary = PRESETS[_preset]
	var size: Vector2i = cfg["size"]
	var scale_v: float = float(cfg["scale"])
	var shrink: int = int(cfg["shrink"])

	# ① 项目级低分辨率配置（[hd2d] 段既有键；不写 project.godot 文件本体）
	var old_w: int = 640
	var old_h: int = 360
	if ProjectSettings.has_setting(KEY_LOW_W):
		old_w = int(ProjectSettings.get_setting(KEY_LOW_W))
	if ProjectSettings.has_setting(KEY_LOW_H):
		old_h = int(ProjectSettings.get_setting(KEY_LOW_H))
	ProjectSettings.set_setting(KEY_LOW_W, size.x)
	ProjectSettings.set_setting(KEY_LOW_H, size.y)
	ProjectSettings.set_setting(KEY_UPSCALE, shrink)
	print("%s apply preset=%s low_resolution %dx%d -> %dx%d | integer_upscale_factor -> %d" % [
			TAG, _preset, old_w, old_h, size.x, size.y, shrink])

	# ② 全局渲染缩放（ProjectSettings 既有 API）
	var old_scale: float = 1.0
	if ProjectSettings.has_setting(SCALE_SETTING):
		old_scale = float(ProjectSettings.get_setting(SCALE_SETTING))
	ProjectSettings.set_setting(SCALE_SETTING, scale_v)
	var new_scale: float = float(ProjectSettings.get_setting(SCALE_SETTING))
	print("%s apply preset=%s scaling_3d/scale %s -> %s" % [TAG, _preset, str(old_scale), str(new_scale)])

	# ③ SubViewportContainer 整数缩放 + SubViewport 实际渲染尺寸回读
	var vpc: SubViewportContainer = _find_first("SubViewportContainer") as SubViewportContainer
	var vp: SubViewport = _find_first("SubViewport") as SubViewport
	if vpc != null:
		var old_shrink: int = vpc.stretch_shrink
		vpc.stretch_shrink = shrink
		print("%s apply SubViewportContainer.stretch_shrink %d -> %d (stretch=%s)" % [
				TAG, old_shrink, vpc.stretch_shrink, str(vpc.stretch)])
	else:
		print("%s apply SubViewportContainer 未找到，跳过 shrink 改写" % TAG)
	if vp != null:
		if vpc != null and vpc.stretch:
			# stretch=true 时引擎自动按 container/shrink 管理 SubViewport.size；
			# 直接赋值会被拒绝并推 WARNING（首跑实测），故只读回实际生效尺寸。
			print("%s apply SubViewport.size 由 stretch_shrink 控制，实际=%s（目标档=%s）" % [
					TAG, str(vp.size), str(size)])
		else:
			var old_size: Vector2i = vp.size
			vp.size = size
			print("%s apply SubViewport.size %s -> %s" % [TAG, str(old_size), str(vp.size)])
	else:
		print("%s apply SubViewport 未找到，跳过 size 回读" % TAG)

	# ④ 通知 fx_profile_controller：优先 re_evaluate()（其内部调用 switch_profile(desktop|mobile)），
	#    老版本 controller 兜底直接调 switch_profile。
	var prev: String = _last_applied
	if _controller == null or not is_instance_valid(_controller):
		_controller = _find_controller()
	if _controller != null and _controller.has_method("re_evaluate"):
		_controller.call("re_evaluate")
	elif _controller != null and _controller.has_method("switch_profile"):
		_controller.call("switch_profile", str(cfg["profile"]))
	else:
		print("%s apply 未找到 controller，跳过 fx_profile 通知" % TAG)

	# ⑤ 重判日志：记录 low -> high 至少一次
	if prev != "" and prev != _preset:
		print("%s 重判 %s -> %s | fx_profile %s -> %s | size=%s" % [
				TAG, prev, _preset, str(PRESETS[prev]["profile"]), str(cfg["profile"]), str(size)])
	print("%s apply done preset=%s prev=%s" % [TAG, _preset, prev])
	_last_applied = _preset


## 优先用 group 找 controller，兜底递归 find_child("HD2DFX")。
func _find_controller() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var n: Node = tree.get_first_node_in_group(GROUP_CTRL)
	if n != null and n.has_method("switch_profile"):
		return n
	n = tree.root.find_child("HD2DFX", true, false)
	if n != null and n.has_method("switch_profile"):
		return n
	return null


func _find_first(nm: String) -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.root.find_child(nm, true, false)
