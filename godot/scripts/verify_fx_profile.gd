extends SceneTree
## R17 · hd2d_fx.tscn 光效档位回读验证（真跑实例化）
## 派单：cmd-20261109-093050-722-A4 · [ROUND=R17] · 工位 Rank-4
## 真跑：godot --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/verify_fx_profile.gd
## 门禁：godot --headless --path ... --check-only --script res://scripts/verify_fx_profile.gd
##
## 唯一职责：从磁盘加载 res://scenes/hd2d_fx.tscn → instantiate() → 加入场景树并等待
##   首帧（触发 4 个 FX 节点 _ready()）→ 用公共入口 set_fx_profile() 把每个 FX 节点分别切到
##   desktop / mobile 两档，逐节点逐项回读 visible / _all_on / fx_profile /
##   texture_filter 并逐项 PASS/FAIL 判定，最后汇总 RESULT。
##
## 冻结口径（HD2D-FX-PLAN.md §4.2）：desktop 四项全开 / mobile 四项全关；
## texture_filter 两档均应为 CanvasItem.TEXTURE_FILTER_NEAREST（禁线性放大）。
##
## 边界：只读 hd2d_fx.tscn（load + instantiate，不 pack / 不保存）；不加载 / 不修改 /
##   不保存 courtyard.tscn（Rank-1 独占）；零外部素材 / 零付费 / 零插件；
##   中文 UTF-8；Godot 4.7.2 合法语法；不伪造输出，所有值均为运行期实际回读。

const FX_SCENE_PATH: String = "res://scenes/hd2d_fx.tscn"
const ROOT_NAME: String = "HD2DFX"
const ROOT_LAYER: int = 10
const EXPECTED_SCENE_NODES: int = 5
const EXPECTED_CHILD_NAMES := ["FXReflection", "FXGodRays", "FXMotes", "FXBloom"]

var _pass_count: int = 0
var _fail_count: int = 0


func _initialize() -> void:
	print("==== [R17 verify_fx_profile] START ====")

	# (0) 从磁盘加载场景（CACHE_MODE_IGNORE 绕过缓存，强制重解析刚落盘的 .tscn）
	var ps: PackedScene = ResourceLoader.load(
			FX_SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if ps == null:
		push_error("[R17] 场景加载失败 path=" + FX_SCENE_PATH)
		print("==== [R17] RESULT=FAIL ====")
		quit(1)
		return
	var scene_nodes: int = ps.get_state().get_node_count()
	print("[R17] LOAD class=%s resource_path=%s SceneState_nodes=%d" % [
			ps.get_class(), ps.resource_path, scene_nodes])

	# (1) 真跑实例化，核对根节点结构（CanvasLayer / layer=10 / 4 个 FX 子节点 / 顺序）
	var inst: Node = ps.instantiate()
	var children: Array[Node] = inst.get_children()
	var names: PackedStringArray = PackedStringArray()
	for c in children:
		names.append(str(c.name))
	var root_is_cl: bool = inst is CanvasLayer
	var root_layer: int = (inst as CanvasLayer).layer if root_is_cl else -999
	var struct_ok: bool = root_is_cl and (str(inst.name) == ROOT_NAME) \
		and (root_layer == ROOT_LAYER) \
		and (scene_nodes == EXPECTED_SCENE_NODES) \
		and (children.size() == EXPECTED_CHILD_NAMES.size())
	for i in range(EXPECTED_CHILD_NAMES.size()):
		if i >= children.size() or str(children[i].name) != EXPECTED_CHILD_NAMES[i]:
			struct_ok = false
	print("[R17] INSTANTIATE root=%s class=%s layer=%d child_count=%d names=%s struct_ok=%s" % [
			inst.name, inst.get_class(), root_layer, children.size(), str(names), str(struct_ok)])

	# (2) 加入场景树。_initialize() 阶段 root 尚未进树，直接 add_child 不会触发 _ready()，
	#     故等待首帧 process_frame，让 _enter_tree / _ready() 真正执行（_build_motes /
	#     texture_filter=Nearest / set_fx_profile(fx_profile)）。
	root.add_child(inst)
	await process_frame
	var ready_flags: PackedStringArray = PackedStringArray()
	for c in children:
		ready_flags.append("%s:ready=%s" % [c.name, str(c.is_node_ready())])
	print("[R17] ADD_TO_TREE inst_inside_tree=%s | %s" % [
			str(inst.is_inside_tree()), " | ".join(ready_flags)])

	# (3) 初始态回读（_ready 后默认 desktop 全开），佐证「真跑实例化」
	var init_ok: bool = true
	for c in children:
		var p0: String = str(c.get("fx_profile"))
		var v0: bool = bool(c.get("visible"))
		var a0: bool = bool(c.get("_all_on"))
		var f0: int = int(c.get("texture_filter"))
		var hit: bool = (p0 == "desktop") and v0 and a0 \
			and (f0 == CanvasItem.TEXTURE_FILTER_NEAREST)
		init_ok = init_ok and hit
		print("[R17][INIT][%s] fx_profile=%s visible=%s _all_on=%s texture_filter=%d" % [
				c.name, p0, str(v0), str(a0), f0])
	_check("① scene_structure_5nodes_canvaslayer10_4fx", struct_ok,
			"SceneState_nodes=%d root=%s layer=%d children=%s" % [
					scene_nodes, ROOT_NAME, root_layer, str(names)])
	_check("② initial_desktop_all_on_after_ready", init_ok,
			"4 节点默认 desktop：visible/_all_on=true / fx_profile=desktop / texture_filter=Nearest（打印值见上）")

	# (4) 两档切换 + 逐节点逐项回读（4 节点 × 2 档 × 4 属性 = 32 项）
	_verify_profile(children, "desktop")
	_verify_profile(children, "mobile")

	# (5) 汇总
	var ok: bool = (_fail_count == 0) and struct_ok and init_ok
	print("==== [R17] SUMMARY pass=%d fail=%d total=%d ====" % [
			_pass_count, _fail_count, _pass_count + _fail_count])
	print("==== [R17] RESULT=%s ====" % ("PASS" if ok else "FAIL"))
	print("==== [R17 verify_fx_profile] END ====")
	quit(0 if ok else 1)


func _verify_profile(children: Array[Node], profile: String) -> void:
	print("---- [R17 档位回读] %s START ----" % profile)
	for c in children:
		c.call("set_fx_profile", profile)   # 公共入口：改档位并立即重算四项门 / visible
		_verify_node(c, profile)
	print("---- [R17 档位回读] %s END ----" % profile)


func _verify_node(n: Node, profile: String) -> void:
	# 期望值按冻结口径硬编码（独立于被测脚本的 _apply_profile 逻辑）
	var exp_vis: bool
	var exp_all: bool
	var exp_prof: String
	if profile == "desktop":
		exp_vis = true
		exp_all = true
		exp_prof = "desktop"
	else:
		exp_vis = false
		exp_all = false
		exp_prof = "mobile"

	var v: bool = bool(n.get("visible"))
	var a: bool = bool(n.get("_all_on"))
	var p: String = str(n.get("fx_profile"))
	var f: int = int(n.get("texture_filter"))
	var tag: String = "[%s][%s]" % [n.name, profile]

	_check("%s visible" % tag, v == exp_vis,
			"actual=%s expected=%s" % [str(v), str(exp_vis)])
	_check("%s _all_on" % tag, a == exp_all,
			"actual=%s expected=%s" % [str(a), str(exp_all)])
	_check("%s fx_profile" % tag, p == exp_prof,
			"actual=%s expected=%s" % [p, exp_prof])
	_check("%s texture_filter" % tag, f == CanvasItem.TEXTURE_FILTER_NEAREST,
			"actual=%d expected=%d(CanvasItem.TEXTURE_FILTER_NEAREST)" % [
					f, CanvasItem.TEXTURE_FILTER_NEAREST])


func _check(label: String, ok: bool, detail: String) -> void:
	if ok:
		_pass_count += 1
	else:
		_fail_count += 1
	print("[R17_CHK] %s PASS=%s | %s" % [label, str(ok), detail])
