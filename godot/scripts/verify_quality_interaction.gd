extends SceneTree
## R22 · 画质菜单「真实交互」可复现验证（脚本注入 Button.pressed 信号，非鼠标点击）
## 派单 cmd-20261109-124640-130-A1 · [ROUND=R22] · AI=1（Rank-1）
##
## 相对 R21 的补强：R21 的 [R21_QUALITY] 仅为 _ready() 的「UI 就绪 / 按钮连接」日志，
##   quality_settings.gd 已去掉自动演示序列，Movie Maker 无交互录制时按钮回调从未触发。
##   本脚本真跑加载 courtyard.tscn → 找到 QualitySettings 实例的三个 Button →
##   用脚本 `Button.pressed.emit()`（Signal 注入，如实声明：非 InputEventMouseButton 鼠标点击）
##   依次切 low / medium / high，每次切换读回 fx_profile_controller 实际档位与四项渲染参数，
##   stdout 打印 [R22_QUALITY] 每档证据，并可与 Movie Maker (--write-movie) 同跑录制三档画面。
##
## 真跑命令（三段门禁 + 交互验证 + 抓帧，见 QUALITY-INTERACTION-R22.md）：
##   G1 ... --headless --path <root> --import
##   G2 ... --headless --path <root> --check-only --script res://scripts/verify_quality_interaction.gd
##   G3 ... --headless --path <root> --quit
##   交互验证 ... --headless --path <root> --script res://scripts/verify_quality_interaction.gd
##   抓帧（GPU，一次只跑一个）... --path <root> --script res://scripts/verify_quality_interaction.gd \
##        --write-movie F:/Game/aierdengfahuan/capture/r22_quality_.png --fixed-fps 30
##
## 边界：零外部素材 / 零付费 / 零 autoload / 零探针脚本 / 只读 courtyard.tscn（load + instantiate，
##   不 pack / 不保存）；不写 project.godot、hud.gd、hd2d_fx.*、verify_frame_data.gd、
##   capture/CAPTURE-REPORT.md、godot/test/（其它 Rank 独占 / 工程冻结）；
##   中文 UTF-8 / Godot 4.7.2 合法语法 / GDScript 类型标注完整；所有值均为运行期实际回读，不伪造。

const TAG: String = "[R22_QUALITY]"
const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"
const QS_NAME: String = "QualitySettings"
const CTRL_NAME: String = "HD2DFX"
const GROUP_CTRL: String = "fx_profile_controller_r20"
const M_ACTIVE: String = "fx_profile_active"
const BTN_PATHS: Dictionary = {
	"low": "QualityPanel/VBox/ButtonRow/BtnLow",
	"medium": "QualityPanel/VBox/ButtonRow/BtnMedium",
	"high": "QualityPanel/VBox/ButtonRow/BtnHigh",
}
const KEY_LOW_W: String = "hd2d/render/low_resolution_width"
const KEY_LOW_H: String = "hd2d/render/low_resolution_height"
const KEY_SCALE: String = "rendering/scaling_3d/scale"
# 每档停留的渲染帧数：让 apply() 的渲染参数生效 + Movie Maker 录到该档稳定帧
const SETTLE_FRAMES: int = 4

# 独立 oracle：quality_settings.gd 的 PRESETS 冻结值（验证脚本不从被测脚本 import，避免同源自证）
var _expect: Dictionary = {
	"low":    {"size": Vector2i(480, 270), "scale": 0.75, "shrink": 3, "fx": "mobile"},
	"medium": {"size": Vector2i(640, 360), "scale": 0.85, "shrink": 2, "fx": "desktop"},
	"high":   {"size": Vector2i(960, 540), "scale": 1.0,  "shrink": 1, "fx": "desktop"},
}
var _order: Array[String] = ["low", "medium", "high"]

var _pass_count: int = 0
var _fail_count: int = 0
var _frame_cursor: int = 0
var _qs: Node = null
var _controller: Node = null
var _vpc: SubViewportContainer = null
var _vp: SubViewport = null
var _buttons: Dictionary = {}
# 每档实际回读值，供末尾三档对照表打印（键=preset）
var _readbacks: Dictionary = {}


func _initialize() -> void:
	print("==== [R22 verify_quality_interaction] START ====")
	print("[R22] cmd-20261109-124640-130-A1 [ROUND=R22] Rank-1 | extends SceneTree 真跑")
	print("[R22] 交互方式=脚本 Signal.emit() 注入 Button.pressed | 如实声明：非 InputEventMouseButton 鼠标点击")

	# (0) CACHE_MODE_IGNORE：绕过资源缓存，强制从磁盘重解析 courtyard.tscn
	var ps: PackedScene = ResourceLoader.load(
			COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if ps == null:
		push_error("[R22] courtyard.tscn 加载失败 path=" + COURTYARD_PATH)
		print("==== [R22] RESULT=FAIL ====")
		quit(1)
		return
	var node_count: int = ps.get_state().get_node_count()
	print("[R22] LOAD path=%s class=%s SceneState_node_count=%d CACHE_MODE_IGNORE=true" % [
			COURTYARD_PATH, ps.get_class(), node_count])

	# (1) 真跑实例化并加入场景树；await 首帧触发 _ready()
	#     （quality_settings._bind_buttons 连接三按钮 / fx_profile_controller 注册 group）
	var inst: Node = ps.instantiate()
	root.add_child(inst)
	await _settle(1)
	print("[R22] ADD_TO_TREE inst=%s inside_tree=%s" % [str(inst.name), str(inst.is_inside_tree())])

	# (2) 结构性事实自己验：找 QualitySettings 实例 / 三个 Button / controller / 容器 / 视口
	_resolve_nodes(inst)
	var struct_ok: bool = _check_structure()
	if not struct_ok:
		print("==== [R22] RESULT=FAIL（结构核实未通过，终止，避免后续空引用）====")
		quit(1)
		return

	# (3) 依次注入 pressed 信号切 low / medium / high（真实触发按钮回调链路）
	for preset: String in _order:
		await _drive_one(preset)

	# (4) 三档 SubViewport 实际渲染分辨率对照（运行期真回读，引擎级低分辨率证据）
	_print_resolution_table()

	# (5) 汇总
	var ok: bool = (_fail_count == 0) and struct_ok
	print("==== [R22] SUMMARY pass=%d fail=%d total=%d ====" % [
			_pass_count, _fail_count, _pass_count + _fail_count])
	print("==== [R22] RESULT=%s ====" % ("PASS" if ok else "FAIL"))
	print("[R22] 声明：本轮三档切换均由脚本 Signal.pressed.emit() 注入触发（非鼠标点击）；"
			+ "抓帧由同跑的 --write-movie Movie Maker 真实录制，stdout 值均为运行期实际回读。")
	print("==== [R22 verify_quality_interaction] END ====")
	quit(0 if ok else 1)


## 等待 n 个渲染帧（process_frame），同时推进脚本内帧游标，供标注各档在 Movie Maker 序列中的区间。
func _settle(frames: int) -> void:
	for _i: int in range(frames):
		await process_frame
		_frame_cursor += 1


## 解析被测节点：QualitySettings 实例、三个 Button、fx_profile_controller、SubViewportContainer、SubViewport。
func _resolve_nodes(inst: Node) -> void:
	_qs = inst.find_child(QS_NAME, true, false)
	# 脚本本身 extends SceneTree，group 查询走 SceneTree 自身方法（root 是 Window，无此方法）
	_controller = get_first_node_in_group(GROUP_CTRL)
	if _controller == null:
		_controller = inst.find_child(CTRL_NAME, true, false)
	_vpc = inst.find_child("SubViewportContainer", true, false) as SubViewportContainer
	_vp = inst.find_child("SubViewport", true, false) as SubViewport
	for preset: String in _order:
		var btn: Button = null
		if _qs != null:
			btn = _qs.get_node_or_null(String(BTN_PATHS[preset])) as Button
		_buttons[preset] = btn


## 结构核实：节点存在 / 类型正确 / 三个 Button.pressed 已连线（保证 emit 能触发回调）。
func _check_structure() -> bool:
	var qs_ok: bool = _qs != null and _qs is CanvasLayer
	_check("structure_quality_settings_instance", qs_ok,
			"QualitySettings found=%s is_CanvasLayer=%s" % [str(_qs != null), str(_qs is CanvasLayer)])

	var ctrl_ok: bool = _controller != null and _controller.has_method("switch_profile") \
			and _controller.has_method("re_evaluate")
	_check("structure_fx_profile_controller", ctrl_ok,
			"HD2DFX found=%s has_switch_profile=%s has_re_evaluate=%s" % [
					str(_controller != null),
					str(_controller != null and _controller.has_method("switch_profile")),
					str(_controller != null and _controller.has_method("re_evaluate"))])

	var vp_ok: bool = _vpc != null and _vp != null
	_check("structure_subviewport", vp_ok,
			"SubViewportContainer=%s SubViewport=%s" % [str(_vpc != null), str(_vp != null)])

	var btn_all_ok: bool = true
	var btn_desc: PackedStringArray = PackedStringArray()
	for preset: String in _order:
		var b: Button = _buttons.get(preset, null) as Button
		var conns: int = 0
		if b != null:
			conns = b.pressed.get_connections().size()
		var hit: bool = b != null and conns > 0
		btn_all_ok = btn_all_ok and hit
		btn_desc.append("%s{text=%s pressed_connections=%d}" % [
				preset, (b.text if b != null else "<null>"), conns])
	_check("structure_three_buttons_bound", btn_all_ok, " | ".join(btn_desc))
	print("[R22] STRUCTURE QualitySettings=%s controller=%s vpc=%s vp=%s | buttons=[%s]" % [
			str(_qs != null), str(_controller != null), str(_vpc != null), str(_vp != null),
			" | ".join(btn_desc)])
	return qs_ok and ctrl_ok and vp_ok and btn_all_ok


## 单档驱动：注入 pressed 信号 → 停留渲染帧 → 回读四项参数 → PASS/FAIL 判定 → [R22_QUALITY] 证据。
func _drive_one(preset: String) -> void:
	var btn: Button = _buttons.get(preset, null) as Button
	var frame_start: int = _frame_cursor
	# 信号注入：直接 emit pressed，触发 quality_settings._on_quality_button_pressed.bind(preset)
	# → set_quality → apply（改写低分辨率/缩放/shrink）→ re_evaluate（controller 重判档）。
	btn.pressed.emit()
	print("[R22] SIGNAL_INJECT preset=%s button=%s method=Button.pressed.emit() | 非鼠标点击" % [
			preset, str(btn.name)])
	await _settle(SETTLE_FRAMES)
	var frame_end: int = _frame_cursor - 1

	var rb: Dictionary = _readback()
	_readbacks[preset] = rb
	_check_preset(preset, rb)
	_print_evidence(preset, rb, frame_start, frame_end)


## 运行期实际回读：controller 档位 / low_resolution_size / scaling_3d / stretch_shrink / 视口实际尺寸。
func _readback() -> Dictionary:
	var fx: String = "<missing>"
	if _controller != null and _controller.has_meta(M_ACTIVE):
		fx = str(_controller.get_meta(M_ACTIVE))
	var w: int = int(ProjectSettings.get_setting(KEY_LOW_W, -1))
	var h: int = int(ProjectSettings.get_setting(KEY_LOW_H, -1))
	var scale_v: float = float(ProjectSettings.get_setting(KEY_SCALE, -1.0))
	var shrink: int = -1
	var stretch: bool = false
	if _vpc != null:
		shrink = _vpc.stretch_shrink
		stretch = _vpc.stretch
	var vps: Vector2i = Vector2i(-1, -1)
	if _vp != null:
		vps = _vp.size
	return {
		"fx": fx,
		"size": Vector2i(w, h),
		"scale": scale_v,
		"shrink": shrink,
		"stretch": stretch,
		"vp_size": vps,
	}


## 与独立 oracle 逐项比对（5 项/档），所有判定基于运行期实际回读值，不硬编码 PASS。
func _check_preset(preset: String, rb: Dictionary) -> void:
	var e: Dictionary = _expect[preset]
	var exp_size: Vector2i = e["size"]
	var exp_scale: float = float(e["scale"])
	var exp_shrink: int = int(e["shrink"])
	var exp_fx: String = String(e["fx"])
	_check("%s fx_profile_active" % preset, String(rb["fx"]) == exp_fx,
			"actual=%s expected=%s" % [String(rb["fx"]), exp_fx])
	_check("%s low_resolution_size" % preset, rb["size"] == exp_size,
			"actual=%s expected=%s" % [str(rb["size"]), str(exp_size)])
	var scale_ok: bool = is_equal_approx(float(rb["scale"]), exp_scale)
	_check("%s scaling_3d/scale" % preset, scale_ok,
			"actual=%s expected=%s" % [str(rb["scale"]), str(exp_scale)])
	_check("%s stretch_shrink" % preset, int(rb["shrink"]) == exp_shrink,
			"actual=%s expected=%d" % [str(rb["shrink"]), exp_shrink])
	# 运行期佐证：SubViewport 实际渲染尺寸 > 0 且随档位切换真实存在（stretch=true 时由 shrink 驱动）
	var vps: Vector2i = rb["vp_size"]
	_check("%s subviewport_size_valid" % preset, vps.x > 0 and vps.y > 0,
			"actual=%s stretch=%s（引擎级低分辨率由该尺寸体现）" % [str(vps), str(rb["stretch"])])


## [R22_QUALITY] 每档证据 stdout（运行期实际回读值）。
func _print_evidence(preset: String, rb: Dictionary, frame_start: int, frame_end: int) -> void:
	print("%s 档位=%s | 触发=Signal.pressed.emit()（脚本注入，非鼠标点击） | fx_profile_controller.fx_profile_active=%s" % [
			TAG, preset, String(rb["fx"])])
	print("%s 档位=%s | low_resolution_size=%s | scaling_3d/scale=%s | stretch_shrink=%s | SubViewportContainer.stretch=%s | SubViewport.size(实际渲染)=%s" % [
			TAG, preset, str(rb["size"]), str(rb["scale"]), str(rb["shrink"]),
			str(rb["stretch"]), str(rb["vp_size"])])
	print("%s 档位=%s | 脚本渲染帧区间=[%d..%d] 停留=%d帧（Movie Maker --write-movie 序列中本档对应帧段）" % [
			TAG, preset, frame_start, frame_end, SETTLE_FRAMES])


## 三档 SubViewport 实际渲染分辨率对照表（运行期真回读，证明画面档位真实变化）。
func _print_resolution_table() -> void:
	print("---- [R22] 三档 SubViewport 实际渲染分辨率对照（运行期真回读）START ----")
	for preset: String in _order:
		var rb: Dictionary = _readbacks.get(preset, {})
		print("[R22_RES] 档位=%s shrink=%s SubViewport.size=%s fx=%s low_resolution_size=%s scale=%s" % [
				preset, str(rb.get("shrink", "n/a")), str(rb.get("vp_size", "n/a")),
				str(rb.get("fx", "n/a")), str(rb.get("size", "n/a")), str(rb.get("scale", "n/a"))])
	print("---- [R22] 三档 SubViewport 实际渲染分辨率对照 END ----")


func _check(label: String, ok: bool, detail: String) -> void:
	if ok:
		_pass_count += 1
	else:
		_fail_count += 1
	print("[R22_CHK] %s PASS=%s | %s" % [label, str(ok), detail])
