extends CanvasLayer
## R21 · 画质设置菜单 UI 化（真实可操作控件 + 去掉自动演示序列）
## 派单 cmd-20261109-115818-630-A1 · [ROUND=R21] · AI=1（Rank-1）
##
## 相对 R20 的改动：
##   ① quality_settings.tscn 在 CanvasLayer 下补齐真实可见控件（PanelContainer + 标题 Label
##      + 三个 Button「低/中/高」），金线深蓝风格（深蓝底 / 金色 1px 边框 / 金色中文 Label），
##      位置 offset=(760,32)-(1244,176) 落在 x>730 右侧，避开 HUD 主面板矩形 x<730,y<220；
##   ② 去掉 _ready() 的 low→high 自动演示序列；保留 set_quality(preset)/apply()/
##      get_quality_preset() 三 API 原样（含 R20 运行期改写渲染低分辨率 / 缩放 + controller 重判）。
##      _ready() 改为：注册 provider → 连接三个 Button.pressed → 打印 [R21_QUALITY] UI 就绪日志
##      → CACHE_MODE_IGNORE 真跑回读 courtyard.tscn 的 SceneState 节点数并如实打印（不冒充 25）。
##      按钮回调 _on_quality_button_pressed(preset)：set_quality → apply → 显式通知
##      fx_profile_controller.re_evaluate() → 打印 [R21_QUALITY] 选择日志。
##
## 边界：零外部素材 / 零付费 / 零 autoload；不写 project.godot、hud.gd、save_delta_writer.gd、
##       hd2d_fx.gd / hd2d_fx.tscn、verify_frame_data.gd（其它 Rank 并发写入）；
##       中文 UTF-8 / Godot 4.7.2 合法语法。

const TAG: String = "[R20_CTRL]"          # R20 apply / set_quality 既有日志标签，逐字保留
const TAG21: String = "[R21_QUALITY]"     # R21 UI 就绪 / 选择日志标签
const GROUP_CTRL: String = "fx_profile_controller_r20"
const SCALE_SETTING: String = "rendering/scaling_3d/scale"
const KEY_LOW_W: String = "hd2d/render/low_resolution_width"
const KEY_LOW_H: String = "hd2d/render/low_resolution_height"
const KEY_UPSCALE: String = "hd2d/render/integer_upscale_factor"
const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"

# 三个 Button 的节点路径（与 quality_settings.tscn 内节点逐字对齐）
const BTN_PATHS: Dictionary = {
	"low":    "QualityPanel/VBox/ButtonRow/BtnLow",
	"medium": "QualityPanel/VBox/ButtonRow/BtnMedium",
	"high":   "QualityPanel/VBox/ButtonRow/BtnHigh",
}

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
	# R21：不再自动演示 low→high；改为连接真实 UI 按钮 + 打印 UI 就绪日志 + 回读节点数。
	_bind_buttons()
	_log_ui_ready()


## 连接 quality_settings.tscn 内三个 Button 的 pressed 信号到统一回调（bind 档位名）。
func _bind_buttons() -> void:
	for k in BTN_PATHS.keys():
		var preset: String = String(k)
		var path: String = String(BTN_PATHS[k])
		var btn: Button = get_node_or_null(path) as Button
		if btn == null:
			push_warning("%s 按钮节点未找到 path=%s，跳过信号连接" % [TAG21, path])
			continue
		btn.pressed.connect(_on_quality_button_pressed.bind(preset))
		print("%s 已连接按钮 %s -> 档位 %s" % [TAG21, path, preset])


## 按钮回调：set_quality → apply → 通知 fx_profile_controller.re_evaluate() → [R21_QUALITY] 选择日志。
func _on_quality_button_pressed(preset: String) -> void:
	set_quality(preset)
	apply()
	_notify_re_evaluate()
	print("%s 选择画质档 preset=%s | 链路 set_quality→apply→re_evaluate 完成 | get_quality_preset()=%s" % [
			TAG21, preset, get_quality_preset()])


## 显式通知 controller 重判档（apply() 内 R20 已内置一次通知；此处按 R21 契约再显式调用，幂等）。
func _notify_re_evaluate() -> void:
	if _controller == null or not is_instance_valid(_controller):
		_controller = _find_controller()
	if _controller != null and _controller.has_method("re_evaluate"):
		_controller.call("re_evaluate")
		print("%s 已通知 fx_profile_controller.re_evaluate() -> %s" % [TAG21, str(_controller.name)])
	else:
		print("%s 未找到 controller，跳过 re_evaluate 通知" % TAG21)


## UI 就绪日志：回读真实控件（路径 / 可见性 / 文本）+ CACHE_MODE_IGNORE 回读 courtyard 节点数。
func _log_ui_ready() -> void:
	var panel: PanelContainer = get_node_or_null("QualityPanel") as PanelContainer
	var title: Label = get_node_or_null("QualityPanel/VBox/TitleLabel") as Label
	var btn_desc: PackedStringArray = PackedStringArray()
	for k in BTN_PATHS.keys():
		var b: Button = get_node_or_null(String(BTN_PATHS[k])) as Button
		btn_desc.append("%s{text=%s visible=%s}" % [
				String(k), (b.text if b != null else "<null>"), (str(b.visible) if b != null else "n/a")])
	print("%s 画质设置菜单 UI 就绪 | panel=%s rect=(%.0f,%.0f)-(%.0f,%.0f) | title=%s | buttons=[%s]" % [
			TAG21, str(panel != null),
			(panel.offset_left if panel != null else -1.0), (panel.offset_top if panel != null else -1.0),
			(panel.offset_right if panel != null else -1.0), (panel.offset_bottom if panel != null else -1.0),
			(title.text if title != null else "<null>"), " | ".join(btn_desc)])
	var n: int = _readback_courtyard_node_count()
	print("%s courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=%d（R20 登记 25，如实回读不冒充）" % [TAG21, n])


## CACHE_MODE_IGNORE 从磁盘强制重解析 courtyard.tscn，只读 SceneState 节点数（不 instantiate / 不写盘）。
func _readback_courtyard_node_count() -> int:
	var ps: PackedScene = ResourceLoader.load(
			COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if ps == null:
		return -1
	return ps.get_state().get_node_count()


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


## 运行期改写渲染低分辨率/缩放，并通知 controller 重判档（R20 逻辑逐字保留）。
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

	# ⑤ 重判日志：记录档位切换（R21 去掉自动演示后仅由真实按钮点击触发）
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
