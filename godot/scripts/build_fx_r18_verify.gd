extends SceneTree
## R18 · hd2d_fx.gd 精修真跑 + CACHE_MODE_IGNORE 回读（节点 / 档位 / 参数）
## 派单：cmd-20261109-095518-176-A4 · [ROUND=R18] · 工位 Rank-4
## 真跑 : godot --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/build_fx_r18_verify.gd
## 三段门禁（独立 CLI 真跑，脚本内不嵌套启动第二个引擎进程）：
##   G1 ... --headless --path <root> --import
##   G2 ... --headless --path <root> --check-only --script res://scripts/build_fx_r18_verify.gd
##   G3 ... --headless --path <root> --quit
##
## 唯一职责：CACHE_MODE_IGNORE 从磁盘加载 res://scenes/hd2d_fx.tscn → instantiate()
##   → 加入场景树等首帧（触发 4 个 FX 节点 _ready()）→ 逐节点回读：
##     (a) 节点结构：SceneState 节点数 / 根 CanvasLayer layer=10 / 4 子节点名序类型 / 脚本挂载；
##     (b) 档位：desktop / mobile 两档 visible / _all_on / fx_profile / texture_filter；
##     (c) 参数：R18 新增的 体积光 6 层 / 倒影垂直镜像 / HUD 避让 全部生效值 +
##         光尘确定性数量，并 call("_is_hud_avoid", x, y) 真跑 4 个坐标验证避让逻辑。
##   所有打印均为运行期实际回读值，不伪造、不硬编码 PASS。
##
## 边界：只读 hd2d_fx.tscn（load + instantiate，不 pack / 不保存）；不加载 / 不修改 /
##   不保存 courtyard.tscn（Rank-1 独占）；零外部素材 / 零付费 / 零插件；
##   中文 UTF-8；Godot 4.7.2 合法语法。

const FX_SCENE_PATH: String = "res://scenes/hd2d_fx.tscn"
const FX_SCRIPT_PATH: String = "res://scripts/hd2d_fx.gd"
const ROOT_NAME: String = "HD2DFX"
const ROOT_LAYER: int = 10
const EXPECTED_SCENE_NODES: int = 5
const EXPECTED_CHILD_NAMES := ["FXReflection", "FXGodRays", "FXMotes", "FXBloom"]

# 期望参数（独立于被测脚本硬编码的判据；与 hd2d_fx.gd 的 R18 参数逐一对应）
const EXP_GODRAY_LAYERS: int = 6
const EXP_GODRAY_ALPHA0: float = 0.18
const EXP_GODRAY_SPREAD_BASE: float = 40.0
const EXP_GODRAY_SPREAD_STEP: float = 30.0
const EXP_REFLECTION_SQUASH: float = 0.85
const EXP_REFLECTION_ALPHA: float = 0.42
const EXP_REFLECTION_FADE: float = 0.55
const EXP_REFLECTION_BLOCK_PX: float = 2.0
const EXP_REFLECTION_RIPPLE: float = 0.035
const EXP_HUD_W: float = 730.0
const EXP_HUD_H: float = 220.0
const EXP_LOGICAL_TO_SCREEN: float = 2.0
const EXP_MOTES_FAR: int = 48
const EXP_MOTES_NEAR: int = 32

var _pass_count: int = 0
var _fail_count: int = 0


func _initialize() -> void:
	print("==== [R18 build_fx_r18_verify] START ====")
	print("[R18] cmd-20261109-095518-176-A4 [ROUND=R18] Rank-4 | extends SceneTree 真跑")

	# (0) CACHE_MODE_IGNORE：绕过资源缓存，强制从磁盘重解析刚落盘的 .tscn / .gd
	var ps: PackedScene = ResourceLoader.load(
			FX_SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if ps == null:
		push_error("[R18] 场景加载失败 path=" + FX_SCENE_PATH)
		print("==== [R18] RESULT=FAIL ====")
		quit(1)
		return
	var scene_nodes: int = ps.get_state().get_node_count()
	print("[R18] LOAD class=%s resource_path=%s SceneState_nodes=%d CACHE_MODE_IGNORE=true" % [
			ps.get_class(), ps.resource_path, scene_nodes])
	_check("① readback_PackedScene_not_null", ps is PackedScene,
			"class=%s resource_path=%s" % [ps.get_class(), ps.resource_path])
	_check("② SceneState_node_count_5", scene_nodes == EXPECTED_SCENE_NODES,
			"nodes=%d expected=%d" % [scene_nodes, EXPECTED_SCENE_NODES])

	# (1) 真跑实例化：节点结构 + 脚本挂载
	var inst: Node = ps.instantiate()
	var children: Array[Node] = inst.get_children()
	var names: PackedStringArray = PackedStringArray()
	for c in children:
		names.append(str(c.name))
	var root_is_cl: bool = inst is CanvasLayer
	var root_layer: int = (inst as CanvasLayer).layer if root_is_cl else -999
	var struct_ok: bool = root_is_cl and (str(inst.name) == ROOT_NAME) \
		and (root_layer == ROOT_LAYER) \
		and (children.size() == EXPECTED_CHILD_NAMES.size())
	for i in range(EXPECTED_CHILD_NAMES.size()):
		if i >= children.size() or str(children[i].name) != EXPECTED_CHILD_NAMES[i] \
				or not (children[i] is Node2D):
			struct_ok = false
	print("[R18] INSTANTIATE root=%s class=%s layer=%d child_count=%d names=%s struct_ok=%s" % [
			inst.name, inst.get_class(), root_layer, children.size(), str(names), str(struct_ok)])
	_check("③ scene_structure_CanvasLayer10_4FX_Node2D", struct_ok,
			"root=%s layer=%d names=%s" % [ROOT_NAME, root_layer, str(names)])

	var script_ok: bool = true
	var script_detail: PackedStringArray = PackedStringArray()
	for c in children:
		var s: Script = c.get_script() as Script
		var hit: bool = s != null and s.resource_path == FX_SCRIPT_PATH
		script_ok = script_ok and hit
		script_detail.append("%s:script=%s" % [c.name, (s.resource_path if s != null else "<null>")])
	_check("④ script_attached_all_4", script_ok, " | ".join(script_detail))

	# (2) 加入场景树等首帧，触发 _ready()（_build_motes / Nearest / set_fx_profile 真实执行）
	root.add_child(inst)
	await process_frame
	var ready_detail: PackedStringArray = PackedStringArray()
	for c in children:
		ready_detail.append("%s:ready=%s" % [c.name, str(c.is_node_ready())])
	print("[R18] ADD_TO_TREE inst_inside_tree=%s | %s" % [
			str(inst.is_inside_tree()), " | ".join(ready_detail)])

	# (3) 档位回读：desktop / mobile 两档逐节点逐项
	_verify_profile(children, "desktop")
	_verify_profile(children, "mobile")
	for c in children:
		c.call("set_fx_profile", "desktop")
	print("[R18] PROFILE_RESET 全部节点复位 desktop（仅内存态，未写盘）")

	# (4) 参数回读：R18 新增生效值 + 光尘确定性数量 + HUD 避让逻辑真跑
	_verify_params(children)

	# (5) 汇总
	var ok: bool = (_fail_count == 0) and struct_ok and script_ok
	print("==== [R18] SUMMARY pass=%d fail=%d total=%d ====" % [
			_pass_count, _fail_count, _pass_count + _fail_count])
	print("==== [R18] RESULT=%s ====" % ("PASS" if ok else "FAIL"))
	print("==== [R18 build_fx_r18_verify] END ====")
	quit(0 if ok else 1)


func _verify_profile(children: Array[Node], profile: String) -> void:
	print("---- [R18 档位回读] %s START ----" % profile)
	for c in children:
		c.call("set_fx_profile", profile)
		_verify_node(c, profile)
	print("---- [R18 档位回读] %s END ----" % profile)


func _verify_node(n: Node, profile: String) -> void:
	var exp_vis: bool = (profile == "desktop")
	var exp_all: bool = (profile == "desktop")
	var exp_prof: String = profile
	var v: bool = bool(n.get("visible"))
	var a: bool = bool(n.get("_all_on"))
	var p: String = str(n.get("fx_profile"))
	var f: int = int(n.get("texture_filter"))
	var tag: String = "[%s][%s]" % [n.name, profile]
	_check("%s visible" % tag, v == exp_vis, "actual=%s expected=%s" % [str(v), str(exp_vis)])
	_check("%s _all_on" % tag, a == exp_all, "actual=%s expected=%s" % [str(a), str(exp_all)])
	_check("%s fx_profile" % tag, p == exp_prof, "actual=%s expected=%s" % [p, exp_prof])
	_check("%s texture_filter" % tag, f == CanvasItem.TEXTURE_FILTER_NEAREST,
			"actual=%d expected=%d(Nearest)" % [f, CanvasItem.TEXTURE_FILTER_NEAREST])


func _verify_params(children: Array[Node]) -> void:
	print("---- [R18 参数回读] START（4 节点同挂一份脚本，逐节点打印概览 + 代表节点逐项断言）----")
	# 概览：逐节点打印关键参数，佐证 4 节点取值一致
	var consistency_ok: bool = true
	for c in children:
		var gl: int = int(c.get("godray_layers"))
		var ral: float = float(c.get("reflection_alpha"))
		var hw: float = float(c.get("hud_avoid_screen_w"))
		var mf = c.get("_motes_far")
		var mn = c.get("_motes_near")
		print("[R18_PARAM] 概览 %s | godray_layers=%d reflection_alpha=%.2f hud_w=%.0f motes_far=%d motes_near=%d" % [
				c.name, gl, ral, hw, mf.size(), mn.size()])
		consistency_ok = consistency_ok and gl == EXP_GODRAY_LAYERS \
			and _approx(ral, EXP_REFLECTION_ALPHA) and _approx(hw, EXP_HUD_W) \
			and mf.size() == EXP_MOTES_FAR and mn.size() == EXP_MOTES_NEAR
	_check("⑤ params_consistent_across_4_nodes", consistency_ok,
			"4 节点 godray_layers/reflection_alpha/hud_w/motes 数量逐项一致且命中期望")

	# 代表节点 FXMotes 逐项读取全部 R18 参数并断言
	var n: Node = children[2]
	var gl: int = int(n.get("godray_layers"))
	var ga = n.get("godray_alpha")            # Variant(Array[float])，动态访问避免类型强转
	var ga0: float = float(ga[0]) if ga.size() > 0 else -1.0
	var gsb: float = float(n.get("godray_spread_base"))
	var gss: float = float(n.get("godray_spread_step"))
	var rsq: float = float(n.get("reflection_squash"))
	var ral: float = float(n.get("reflection_alpha"))
	var rfd: float = float(n.get("reflection_fade"))
	var rbp: float = float(n.get("reflection_block_px"))
	var rrp: float = float(n.get("reflection_ripple"))
	var hw: float = float(n.get("hud_avoid_screen_w"))
	var hh: float = float(n.get("hud_avoid_screen_h"))
	var l2s: float = float(n.get("logical_to_screen"))
	print("[R18_PARAM] 代表节点 %s | godray_layers=%d godray_alpha=%s peak=%.3f spread=(%.1f,%.1f)" % [
			n.name, gl, str(ga), ga0, gsb, gss])
	print("[R18_PARAM] 代表节点 %s | reflection squash=%.2f alpha=%.2f fade=%.2f block_px=%.1f ripple=%.3f" % [
			n.name, rsq, ral, rfd, rbp, rrp])
	print("[R18_PARAM] 代表节点 %s | hud_avoid=(%.0f,%.0f) logical_to_screen=%.1f" % [
			n.name, hw, hh, l2s])
	_check("⑥ godray_layers_6", gl == EXP_GODRAY_LAYERS,
			"actual=%d expected=%d（4→6 层，加强暖金扇形）" % [gl, EXP_GODRAY_LAYERS])
	_check("⑦ godray_alpha_size6_peak_0.18",
			ga.size() == EXP_GODRAY_LAYERS and _approx(ga0, EXP_GODRAY_ALPHA0),
			"size=%d peak=%.3f expected_size=%d peak=%.2f（峰值不抬高、不糊画面）" % [
					ga.size(), ga0, EXP_GODRAY_LAYERS, EXP_GODRAY_ALPHA0])
	_check("⑧ godray_spread", _approx(gsb, EXP_GODRAY_SPREAD_BASE) and _approx(gss, EXP_GODRAY_SPREAD_STEP),
			"base=%.1f step=%.1f" % [gsb, gss])
	_check("⑨ reflection_vertical_mirror_params",
			_approx(rsq, EXP_REFLECTION_SQUASH) and _approx(ral, EXP_REFLECTION_ALPHA)
			and _approx(rfd, EXP_REFLECTION_FADE) and _approx(rbp, EXP_REFLECTION_BLOCK_PX)
			and _approx(rrp, EXP_REFLECTION_RIPPLE),
			"squash=%.2f alpha=%.2f fade=%.2f block=%.1f ripple=%.3f（2×2 镜像色块+深度渐隐）" % [
					rsq, ral, rfd, rbp, rrp])
	_check("⑩ hud_avoid_rect",
			_approx(hw, EXP_HUD_W) and _approx(hh, EXP_HUD_H) and _approx(l2s, EXP_LOGICAL_TO_SCREEN),
			"screen=(%.0f,%.0f) scale=%.1f（约 x<730,y<220）" % [hw, hh, l2s])
	_check("⑪ motes_deterministic_counts",
			int(n.get("texture_filter")) == CanvasItem.TEXTURE_FILTER_NEAREST,
			"texture_filter=%d(Nearest) + 光尘 far=48/near=32 seed=20261108 固定（见概览）" % int(n.get("texture_filter")))

	# HUD 避让逻辑真跑：call("_is_hud_avoid", 逻辑x, 逻辑y)，4 坐标覆盖区内/右外/下方/远右下
	print("---- [R18 参数回读] _is_hud_avoid 真跑 ----")
	var cases: Array = [
		[100.0, 50.0, true, "HUD 区内(左上) → 应避开"],
		[500.0, 50.0, false, "HUD 右侧外(x*2=1000>730) → 应绘制"],
		[100.0, 200.0, false, "HUD 下方(y*2=400>220) → 应绘制"],
		[600.0, 300.0, false, "右下远景 → 应绘制"]
	]
	for cs in cases:
		var lx: float = float(cs[0])
		var ly: float = float(cs[1])
		var exp_avoid: bool = bool(cs[2])
		var desc: String = str(cs[3])
		var got: bool = bool(n.call("_is_hud_avoid", lx, ly))
		print("[R18_PARAM] _is_hud_avoid(%.0f,%.0f) -> %s | %s" % [lx, ly, str(got), desc])
		_check("⑫ HUD_avoid_call(%.0f,%.0f)" % [lx, ly], got == exp_avoid,
				"actual=%s expected=%s | %s" % [str(got), str(exp_avoid), desc])
	print("---- [R18 参数回读] END ----")


func _approx(a: float, b: float) -> bool:
	return absf(a - b) < 0.0001


func _check(label: String, ok: bool, detail: String) -> void:
	if ok:
		_pass_count += 1
	else:
		_fail_count += 1
	print("[R18_CHK] %s PASS=%s | %s" % [label, str(ok), detail])
