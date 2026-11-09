extends SceneTree
## R16 · 独立 HD-2D 光效场景真跑生成 + CACHE_MODE_IGNORE 回读校验
## 派单：cmd-20261109-085736-029-A4 · [ROUND=R16] · 工位 Rank-4
## 真跑：godot --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/build_hd2d_fx.gd
## 门禁：godot --headless --path ... --check-only --script res://scripts/build_hd2d_fx.gd
##
## 唯一职责：程序化构造 → PackedScene.pack() → instantiate() 节点数比对 →
##   ResourceSaver.save() 落 res://scenes/hd2d_fx.tscn →
##   ResourceLoader.load(..., CACHE_MODE_IGNORE) 从磁盘重读并校验「节点结构 + 脚本挂载」。
##
## 生成结构（根节点直接子节点数 = 4，SceneState 节点数 = 5）：
##   HD2DFX (CanvasLayer, layer=10)        ← 对齐方案 §2.1 既有 FXLayer 冻结值 10
##   ├── FXReflection (Node2D, script=hd2d_fx.gd, fx_profile="desktop")  倒影（最下）
##   ├── FXGodRays    (Node2D, script=hd2d_fx.gd, fx_profile="desktop")  体积光
##   ├── FXMotes      (Node2D, script=hd2d_fx.gd, fx_profile="desktop")  光尘
##   └── FXBloom      (Node2D, script=hd2d_fx.gd, fx_profile="desktop")  bloom（最上）
##
## 四个节点同挂一份 hd2d_fx.gd，由节点名分派 _draw() 只画对应一项；fx_profile 档位
## 统一控制四项全开/全关（desktop/mobile）。同 CanvasLayer 内靠子节点顺序叠加，
## 对齐 HD-2D视觉规范.md §10 层序（fx_0_back → fx_1_front）。
##
## 边界：只写 res://scenes/hd2d_fx.tscn；不加载 / 不修改 / 不保存 courtyard.tscn
##       （Rank-1 本轮独占）；零外部素材（.tscn 内 ext_resource 仅 1 个 Script）；
##       不自行 git；中文 UTF-8；Godot 4.7.2 合法语法；不伪造输出，全部打印为运行期实际值。

const OUT_PATH: String = "res://scenes/hd2d_fx.tscn"
const FX_SCRIPT_PATH: String = "res://scripts/hd2d_fx.gd"
const ROOT_NAME: String = "HD2DFX"
const ROOT_LAYER: int = 10
const EXPECTED_CHILD_NAMES := ["FXReflection", "FXGodRays", "FXMotes", "FXBloom"]
const EXPECTED_CHILD_COUNT: int = 4
const EXPECTED_SCENE_NODES: int = 5          # 根 + 4 子节点（SceneState 层）

var _pass_count: int = 0
var _fail_count: int = 0


func _initialize() -> void:
	print("==== [R16 build_hd2d_fx] START ====")

	# (0) 加载光效脚本（来自 res://，pack 时会序列化为 ext_resource Script）
	var fx_script: Script = load(FX_SCRIPT_PATH) as Script
	if fx_script == null:
		push_error("[R16] 光效脚本加载失败，拒绝生成：" + FX_SCRIPT_PATH)
		print("==== [R16] RESULT=FAIL ====")
		quit(1)
		return
	print("[R16] LOAD_SCRIPT path=%s resource_path=%s class=%s" % [
			FX_SCRIPT_PATH, fx_script.resource_path, fx_script.get_class()])

	# (1) 构造：CanvasLayer 根 + 4 个挂脚本的 Node2D 光效节点
	var root: CanvasLayer = CanvasLayer.new()
	root.name = ROOT_NAME
	root.layer = ROOT_LAYER
	for nm in EXPECTED_CHILD_NAMES:
		var n: Node2D = Node2D.new()
		n.name = nm
		n.set_script(fx_script)
		n.set("fx_profile", "desktop")
		n.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		root.add_child(n)
		n.owner = root                      # 纳入 owner 链，否则 pack 会丢弃子节点
		print("[R16] MAKE_NODE name=%s script_set=%s fx_profile=%s" % [
				nm, str(n.get_script() != null), str(n.get("fx_profile"))])

	# (2) pack + instantiate 往返节点数比对
	var packed: PackedScene = PackedScene.new()
	var pack_err: int = packed.pack(root)
	if pack_err != OK:
		push_error("[R16] PackedScene.pack() 失败 err=%d，拒绝保存" % pack_err)
		_free_tree(root)
		quit(1)
		return
	var packed_nodes: int = packed.get_state().get_node_count()
	var probe: Node = packed.instantiate()
	var probe_nodes: int = _count_nodes(probe)
	_free_tree(probe)
	var node_count_ok: bool = (root.get_child_count() == EXPECTED_CHILD_COUNT) \
		and (packed_nodes == EXPECTED_SCENE_NODES) \
		and (probe_nodes == EXPECTED_SCENE_NODES)
	print("[R16] PACK pack_err=%d child_count=%d SceneState_nodes=%d probe_nodes=%d ok=%s" % [
			pack_err, root.get_child_count(), packed_nodes, probe_nodes, str(node_count_ok)])
	if not node_count_ok:
		push_error("[R16] 节点数比对失败，拒绝保存（不伪造输出）")
		_free_tree(root)
		quit(1)
		return

	# (3) 保存（仅此一处写盘；不碰 courtyard.tscn）
	var save_err: int = ResourceSaver.save(packed, OUT_PATH)
	_free_tree(root)
	if save_err != OK:
		push_error("[R16] ResourceSaver.save() 失败 err=%d path=%s" % [save_err, OUT_PATH])
		quit(1)
		return
	print("[R16] SAVE_OK path=%s save_err=%d (OK=%d)" % [OUT_PATH, save_err, OK])

	# (4) CACHE_MODE_IGNORE 回读校验：绕过本进程缓存，强制从磁盘重新解析刚保存的 .tscn
	var ok: bool = _verify()
	print("[R16] VERIFY_SUMMARY pass=%d fail=%d ok=%s" % [_pass_count, _fail_count, str(ok)])
	print("==== [R16] RESULT=%s ====" % ("PASS" if ok else "FAIL"))
	print("==== [R16 build_hd2d_fx] END ====")
	quit(0 if ok else 1)


func _verify() -> bool:
	print("==== [R16 回读 CACHE_MODE_IGNORE] START ====")
	var ps: PackedScene = ResourceLoader.load(
			OUT_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if ps == null:
		push_error("[R16_VERIFY] CACHE_MODE_IGNORE 回读失败 path=%s" % OUT_PATH)
		return false
	var disk_nodes: int = ps.get_state().get_node_count()
	print("[R16_VERIFY] readback class=%s resource_path=%s SceneState_nodes=%d" % [
			ps.get_class(), ps.resource_path, disk_nodes])
	_check("① readback_not_null_and_PackedScene", ps is PackedScene,
			"class=%s" % ps.get_class())
	_check("② SceneState_node_count", disk_nodes == EXPECTED_SCENE_NODES,
			"nodes=%d expected=%d" % [disk_nodes, EXPECTED_SCENE_NODES])

	var inst: Node = ps.instantiate()

	# ③ 根节点为 CanvasLayer 且 layer=10
	var root_is_cl: bool = inst is CanvasLayer
	var root_layer: int = (inst as CanvasLayer).layer if root_is_cl else -999
	_check("③ root_is_CanvasLayer_layer10", root_is_cl and root_layer == ROOT_LAYER,
			"name=%s class=%s layer=%d expected=%d" % [
					inst.name, inst.get_class(), root_layer, ROOT_LAYER])

	# ④ 节点结构：4 个直接子节点，名字 / 顺序 / 类型全部一致
	var children: Array[Node] = inst.get_children()
	var names: PackedStringArray = PackedStringArray()
	for c in children:
		names.append(str(c.name))
	var struct_ok: bool = children.size() == EXPECTED_CHILD_COUNT
	for i in range(EXPECTED_CHILD_NAMES.size()):
		if i >= children.size():
			struct_ok = false
			break
		struct_ok = struct_ok \
			and (str(children[i].name) == EXPECTED_CHILD_NAMES[i]) \
			and (children[i] is Node2D)
	_check("④ children_structure", struct_ok,
			"child_count=%d names=%s expected=%s" % [
					children.size(), str(names), str(EXPECTED_CHILD_NAMES)])

	# ⑤ 脚本挂载：每个子节点都挂 res://scripts/hd2d_fx.gd
	var script_ok: bool = true
	var script_detail: PackedStringArray = PackedStringArray()
	for c in children:
		var s: Script = c.get("script") as Script
		var hit: bool = s != null and s.resource_path == FX_SCRIPT_PATH
		script_ok = script_ok and hit
		script_detail.append("%s:script=%s" % [c.name, (s.resource_path if s != null else "<null>")])
	_check("⑤ script_attached_all_4", script_ok, " | ".join(script_detail))

	# ⑥ fx_profile 档位默认值 = desktop（四项全开）
	var profile_ok: bool = true
	var profile_detail: PackedStringArray = PackedStringArray()
	for c in children:
		var p: String = str(c.get("fx_profile"))
		profile_ok = profile_ok and (p == "desktop")
		profile_detail.append("%s:%s" % [c.name, p])
	_check("⑥ fx_profile_default_desktop", profile_ok, " | ".join(profile_detail))

	# ⑦ 档位派生真跑：mobile 四项全关 / desktop 四项全开
	#    回读实例是游离节点（未进树，_ready 不执行），显式调用公共 set_fx_profile 验证派生逻辑。
	var mobile_ok: bool = true
	var desktop_ok: bool = true
	for c in children:
		c.call("set_fx_profile", "mobile")
		var m_vis: bool = (c.get("visible") == false)
		var m_all: bool = (c.get("_all_on") == false)
		mobile_ok = mobile_ok and m_vis and m_all
		c.call("set_fx_profile", "desktop")
		var d_vis: bool = (c.get("visible") == true)
		var d_all: bool = (c.get("_all_on") == true)
		desktop_ok = desktop_ok and d_vis and d_all
	_check("⑦a mobile_all_off", mobile_ok,
			"set_fx_profile(mobile) -> visible=false / _all_on=false (4 节点)")
	_check("⑦b desktop_all_on", desktop_ok,
			"set_fx_profile(desktop) -> visible=true / _all_on=true (4 节点)")

	# ⑧ Nearest 过滤（禁线性放大）
	var filter_ok: bool = true
	for c in children:
		filter_ok = filter_ok and (c.get("texture_filter") == CanvasItem.TEXTURE_FILTER_NEAREST)
	_check("⑧ texture_filter_Nearest", filter_ok,
			"expected=%d" % CanvasItem.TEXTURE_FILTER_NEAREST)

	# ⑨ 零外部素材：打印 .tscn 全文并审计 ext_resource 只有 1 个 Script、无 PNG / 贴图 / 子资源
	var text: String = FileAccess.get_file_as_string(OUT_PATH)
	print("---- [R16] hd2d_fx.tscn 全文（磁盘实际内容）----")
	print(text)
	print("---- [R16] hd2d_fx.tscn 全文 END ----")
	var ext_lines: PackedStringArray = PackedStringArray()
	for line in text.split("\n"):
		if line.begins_with("[ext_resource"):
			ext_lines.append(line)
	var ext_ok: bool = ext_lines.size() == 1 \
		and ext_lines[0].find("type=\"Script\"") != -1 \
		and ext_lines[0].find(FX_SCRIPT_PATH) != -1
	var no_assets: bool = text.find(".png") == -1 \
		and text.find("Texture2D") == -1 \
		and text.find("GradientTexture") == -1 \
		and text.find("[sub_resource") == -1
	_check("⑨ zero_external_assets", ext_ok and no_assets,
			"ext_resource_lines=%d lines=%s no_png_texture_subres=%s" % [
					ext_lines.size(), str(ext_lines), str(no_assets)])

	_free_tree(inst)
	print("==== [R16 回读 CACHE_MODE_IGNORE] END ====")
	return _fail_count == 0


func _check(label: String, ok: bool, detail: String) -> void:
	if ok:
		_pass_count += 1
	else:
		_fail_count += 1
	print("[R16_VERIFY] %s PASS=%s | %s" % [label, str(ok), detail])


func _count_nodes(n: Node) -> int:
	var total: int = 1
	for c in n.get_children():
		total += _count_nodes(c)
	return total


func _free_tree(n: Node) -> void:
	for c in n.get_children():
		_free_tree(c)
	n.free()
