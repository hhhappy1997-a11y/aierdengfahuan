extends SceneTree
## R19 · 移动档降级实跑验证（hd2d_fx.tscn 切 mobile + desktop 对比回读）
## 派单：cmd-20261109-102334-091-A4 · [ROUND=R19] · 工位 Rank-4
## 真跑：godot --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/verify_fx_mobile.gd
## 三段门禁（独立 CLI 真跑，脚本内不嵌套启动第二个引擎进程）：
##   G1 ... --headless --path <root> --import
##   G2 ... --headless --path <root> --check-only --script res://scripts/verify_fx_mobile.gd
##   G3 ... --headless --path <root> --quit
## 抓帧（独立 CLI）：... --write-movie F:/Game/aierdengfahuan/capture/r19_mobile.png --fixed-fps 30 --quit-after 4 res://scenes/courtyard.tscn
##
## 职责：
##   ① CACHE_MODE_IGNORE 从磁盘加载 hd2d_fx.tscn → instantiate() → root.add_child + await
##      process_frame（触发 4 个 FX 节点 _ready()：_build_motes / texture_filter=Nearest /
##      set_fx_profile 默认 desktop 真实执行）；
##   ② 4 节点逐一切到 mobile，回读 visible=false / _all_on=false / texture_filter=Nearest /
##      fx_profile=mobile，并回读四项绘制门 _on_reflection/_on_godrays/_on_motes/_on_bloom 全 false；
##   ③ 再逐一切回 desktop 做对比回读，打印两档实际值 + 差异对照表（桌面四项全开 / 移动四项全关）；
##   ④ 真跑核实结构：整棵树仅 CanvasLayer(根) + 4 个 Node2D FX 子节点，是纯叠加光效层，
##      不含背景 / 角色 / 地面 / HUD 等画面主体节点 → 支撑「关掉四项光效后画面主体仍可读」。
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
const GATE_KEYS := ["_on_reflection", "_on_godrays", "_on_motes", "_on_bloom"]

var _pass_count: int = 0
var _fail_count: int = 0
# 保存两档实际回读值供差异对照表打印：节点名 -> {prop: value}
var _mobile_vals: Dictionary = {}
var _desktop_vals: Dictionary = {}


func _initialize() -> void:
	print("==== [R19 verify_fx_mobile] START ====")
	print("[R19] cmd-20261109-102334-091-A4 [ROUND=R19] Rank-4 | extends SceneTree 真跑")

	# (0) CACHE_MODE_IGNORE：绕过资源缓存，强制从磁盘重解析 .tscn / .gd
	var ps: PackedScene = ResourceLoader.load(
			FX_SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if ps == null:
		push_error("[R19] 场景加载失败 path=" + FX_SCENE_PATH)
		print("==== [R19] RESULT=FAIL ====")
		quit(1)
		return
	var scene_nodes: int = ps.get_state().get_node_count()
	print("[R19] LOAD class=%s resource_path=%s SceneState_nodes=%d CACHE_MODE_IGNORE=true" % [
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
	print("[R19] INSTANTIATE root=%s class=%s layer=%d child_count=%d names=%s struct_ok=%s" % [
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

	# (2) 真跑核实「纯叠加 FX 层」结构：整棵树仅 CanvasLayer(根) + 4 个 Node2D FX 子节点，
	#     不含 3D / 背景 / 角色 / 地面 / HUD 等画面主体节点。
	#     据此：关掉四项光效只移除叠加层，主场景画面主体由 courtyard.tscn 的兄弟节点
	#     （Terrain / Player / Hud / HD2DPlaceholderLayer 等）绘制，不受本 FX 实例影响。
	var tree_types: PackedStringArray = PackedStringArray()
	tree_types.append("HD2DFX:CanvasLayer")
	var pure_fx: bool = true
	for c in children:
		tree_types.append("%s:%s" % [c.name, c.get_class()])
		for gc in c.get_children():
			tree_types.append("  +%s:%s" % [gc.name, gc.get_class()])
			pure_fx = false   # 任一 FX 节点下还有子节点，即不再是纯叠加叶子层
	var only_cl_and_n2d: bool = true
	for c in children:
		if not (c is Node2D):
			only_cl_and_n2d = false
	print("[R19] STRUCTURE_TREE %s" % " | ".join(tree_types))
	_check("⑤ pure_fx_overlay_layer_5nodes", struct_ok and pure_fx and only_cl_and_n2d,
			"整树 5 节点=CanvasLayer(根)+4×Node2D(FX)，无 3D/背景/角色/HUD 主体节点 → 画面主体不依赖 FX 层")

	# (3) 加入场景树等首帧，触发 _ready()（_build_motes / Nearest / 默认档位真实执行）
	root.add_child(inst)
	await process_frame
	var ready_detail: PackedStringArray = PackedStringArray()
	for c in children:
		ready_detail.append("%s:ready=%s" % [c.name, str(c.is_node_ready())])
	print("[R19] ADD_TO_TREE inst_inside_tree=%s | %s" % [
			str(inst.is_inside_tree()), " | ".join(ready_detail)])

	# (4) 初始态回读（_ready 后默认 desktop 全开），佐证「真跑实例化」
	var init_ok: bool = true
	for c in children:
		var p0: String = str(c.get("fx_profile"))
		var v0: bool = bool(c.get("visible"))
		var a0: bool = bool(c.get("_all_on"))
		var f0: int = int(c.get("texture_filter"))
		var hit: bool = (p0 == "desktop") and v0 and a0 \
			and (f0 == CanvasItem.TEXTURE_FILTER_NEAREST)
		init_ok = init_ok and hit
		print("[R19][INIT][%s] fx_profile=%s visible=%s _all_on=%s texture_filter=%d" % [
				c.name, p0, str(v0), str(a0), f0])
	_check("⑥ initial_desktop_all_on_after_ready", init_ok,
			"4 节点默认 desktop：visible/_all_on=true / fx_profile=desktop / texture_filter=Nearest")

	# (5) 任务①：4 节点切 mobile，回读 visible=false / _all_on=false / texture_filter=Nearest + 四项门
	_verify_profile(children, "mobile")

	# (6) 任务③：再切 desktop 做对比回读，打印实际值
	_verify_profile(children, "desktop")

	# (7) 两档差异对照表（打印实际回读值，不硬编码）
	_print_diff(children)

	# (8) 复位 desktop（仅内存态，未写盘）
	for c in children:
		c.call("set_fx_profile", "desktop")
	print("[R19] PROFILE_RESET 全部节点复位 desktop（仅内存态，未写盘；hd2d_fx.tscn / courtyard.tscn 均零写入）")

	# (9) 汇总
	var ok: bool = (_fail_count == 0) and struct_ok and script_ok and init_ok and pure_fx
	print("==== [R19] SUMMARY pass=%d fail=%d total=%d ====" % [
			_pass_count, _fail_count, _pass_count + _fail_count])
	print("==== [R19] RESULT=%s ====" % ("PASS" if ok else "FAIL"))
	print("==== [R19 verify_fx_mobile] END ====")
	quit(0 if ok else 1)


func _verify_profile(children: Array[Node], profile: String) -> void:
	print("---- [R19 档位回读] %s START ----" % profile)
	for c in children:
		c.call("set_fx_profile", profile)   # 公共入口：改档位并立即重算四项门 / visible
		_verify_node(c, profile)
	print("---- [R19 档位回读] %s END ----" % profile)


func _verify_node(n: Node, profile: String) -> void:
	var exp_vis: bool = (profile == "desktop")
	var exp_all: bool = (profile == "desktop")
	var exp_prof: String = profile
	var v: bool = bool(n.get("visible"))
	var a: bool = bool(n.get("_all_on"))
	var p: String = str(n.get("fx_profile"))
	var f: int = int(n.get("texture_filter"))
	# 四项绘制门实际值
	var gates: Dictionary = {}
	var gates_all: bool = true
	var gates_detail: PackedStringArray = PackedStringArray()
	for k in GATE_KEYS:
		var g: bool = bool(n.get(k))
		gates[k] = g
		gates_detail.append("%s=%s" % [k, str(g)])
		if g != (profile == "desktop"):
			gates_all = false
	var tag: String = "[%s][%s]" % [n.name, profile]
	# 保存实际值供差异对照表
	var rec: Dictionary = {
		"visible": v, "_all_on": a, "fx_profile": p, "texture_filter": f, "gates": gates
	}
	if profile == "mobile":
		_mobile_vals[str(n.name)] = rec
	else:
		_desktop_vals[str(n.name)] = rec
	print("[R19_READ][%s][%s] visible=%s _all_on=%s fx_profile=%s texture_filter=%d(Nearest=%d) | %s" % [
			n.name, profile, str(v), str(a), p, f, CanvasItem.TEXTURE_FILTER_NEAREST,
			" ".join(gates_detail)])
	_check("%s visible" % tag, v == exp_vis, "actual=%s expected=%s" % [str(v), str(exp_vis)])
	_check("%s _all_on" % tag, a == exp_all, "actual=%s expected=%s" % [str(a), str(exp_all)])
	_check("%s fx_profile" % tag, p == exp_prof, "actual=%s expected=%s" % [p, exp_prof])
	_check("%s texture_filter" % tag, f == CanvasItem.TEXTURE_FILTER_NEAREST,
			"actual=%d expected=%d(Nearest)" % [f, CanvasItem.TEXTURE_FILTER_NEAREST])
	_check("%s four_draw_gates" % tag, gates_all,
			"四项绘制门实际=%s expected=%s（mobile 全 false / desktop 全 true）" % [
					" ".join(gates_detail), str(profile == "desktop")])


func _print_diff(children: Array[Node]) -> void:
	print("---- [R19 desktop vs mobile 差异对照] START（均为运行期实际回读值）----")
	var diff_ok: bool = true
	for c in children:
		var nm: String = str(c.name)
		var m: Dictionary = _mobile_vals.get(nm, {})
		var d: Dictionary = _desktop_vals.get(nm, {})
		var mg: Dictionary = m.get("gates", {})
		var dg: Dictionary = d.get("gates", {})
		var m_gates: PackedStringArray = PackedStringArray()
		var d_gates: PackedStringArray = PackedStringArray()
		var gates_diff_ok: bool = true
		for k in GATE_KEYS:
			var gv_m: bool = bool(mg.get(k, true))
			var gv_d: bool = bool(dg.get(k, false))
			m_gates.append(str(gv_m))
			d_gates.append(str(gv_d))
			gates_diff_ok = gates_diff_ok and (not gv_m) and gv_d
		var mv: bool = bool(m.get("visible", false))
		var dv: bool = bool(d.get("visible", false))
		var ma: bool = bool(m.get("_all_on", false))
		var da: bool = bool(d.get("_all_on", false))
		var mp: String = str(m.get("fx_profile", "<null>"))
		var dp: String = str(d.get("fx_profile", "<null>"))
		var mf: int = int(m.get("texture_filter", -1))
		var df: int = int(d.get("texture_filter", -1))
		print("[R19_DIFF][%s] desktop{visible=%s _all_on=%s fx_profile=%s filter=%d gates=[%s]} | mobile{visible=%s _all_on=%s fx_profile=%s filter=%d gates=[%s]}" % [
				nm, str(dv), str(da), dp, df, " ".join(d_gates),
				str(mv), str(ma), mp, mf, " ".join(m_gates)])
		var hit: bool = dv and da and (dp == "desktop") \
			and (not mv) and (not ma) and (mp == "mobile") \
			and (mf == CanvasItem.TEXTURE_FILTER_NEAREST) \
			and (df == CanvasItem.TEXTURE_FILTER_NEAREST) and gates_diff_ok
		diff_ok = diff_ok and hit
	_check("⑦ desktop_vs_mobile_diff_all_4", diff_ok,
			"4 节点两档实际值对照：desktop 四项全开(visible/_all_on/四门=true) / mobile 四项全关(全=false)，两档 texture_filter 均 Nearest")
	print("---- [R19 desktop vs mobile 差异对照] END ----")


func _check(label: String, ok: bool, detail: String) -> void:
	if ok:
		_pass_count += 1
	else:
		_fail_count += 1
	print("[R19_CHK] %s PASS=%s | %s" % [label, str(ok), detail])
