extends SceneTree
## R9 追加式构建脚本：把 Rank-4 HD-2D 占位画面「接入」既有 courtyard.tscn。
## 与 build_courtyard.gd（从头重建 20 节点）不同，本脚本是「追加式」：
##   1) load 既有 courtyard.tscn → instantiate 取回原样 20 节点树；
##   2) 用 Rank-4 scene_integration.md §2.1 的一行调用追加 HD-2D 背景层（+2 节点）；
##   3) 给追加节点设 owner，逐一校验既有 20 节点（路径 + 类型）未被改动；
##   4) pack → instantiate 复核节点数 → ResourceSaver.save 写回 courtyard.tscn。
## 不重做 build_courtyard.gd、不覆盖 / 不删除任何既有节点、不动 project.godot。
## 零外部依赖：仅 preload / load 工程内既有 .gd，不加载 PNG / 贴图 / 插件 / 云服务 / 付费 API。
## 路线口径沿用 scene_integration.md：ComfyUI 仍是主美术路线，本占位仅 M0 构图验证 / 降级，
##   不宣称已渲染可见、不宣称已能出图；遮挡层序由 Rank-1 结合场景裁决（登记，不擅改）。
## 运行：godot --headless --path <工程根> --script res://scripts/render/attach_hd2d_placeholder.gd

const SCENE_PATH: String = "res://scenes/courtyard.tscn"
const HD2D_ATTACH = preload("res://scripts/render/hd2d_placeholder_attach.gd")


func _initialize() -> void:
	var src: PackedScene = load(SCENE_PATH) as PackedScene
	if src == null:
		push_error("[R9-HD2D] 未找到既有场景 %s，拒绝接入" % SCENE_PATH)
		quit(1)
		return

	# 既有 20 节点树由 PackedScene 原样带入，不重建、不覆盖。
	var root: Node = src.instantiate()
	var before: Array[String] = []
	_collect_paths(root, root, before)
	var before_count: int = before.size()

	# ---- 一行接入调用（Rank-4 scene_integration.md §2.1 主推写法）----
	var bg: Node2D = HD2D_ATTACH.attach(root, {"canvas_layer": -10, "integer_scale": 2})
	if bg == null:
		push_error("[R9-HD2D] attach() 返回 null，占位未挂载，拒绝保存（不伪造输出）")
		_free_tree(root)
		quit(1)
		return

	# attach() 按契约不设 owner；pack 只序列化 owner 非 null 的节点，故此处补设。
	var layer: Node = bg.get_parent()
	if layer == null:
		push_error("[R9-HD2D] 追加层父节点为 null，拒绝保存")
		_free_tree(root)
		quit(1)
		return
	layer.owner = root
	bg.owner = root

	# ---- 校验 1：既有节点逐一保留（路径|类型），总数恰为 before + 2 ----
	var after: Array[String] = []
	_collect_paths(root, root, after)
	var preserved: bool = true
	var i: int = 0
	while i < before.size():
		if not after.has(before[i]):
			preserved = false
		i += 1
	if not preserved or after.size() != before_count + 2:
		push_error("[R9-HD2D] 既有节点校验失败 before=%d after=%d preserved=%s，拒绝保存" % [before_count, after.size(), str(preserved)])
		_free_tree(root)
		quit(1)
		return

	var packed: PackedScene = PackedScene.new()
	var pack_err: int = packed.pack(root)
	if pack_err != OK:
		push_error("[R9-HD2D] PackedScene.pack() 失败 err=%d，拒绝保存" % pack_err)
		_free_tree(root)
		quit(1)
		return

	# ---- 校验 2：pack/instantiate 往返后既有节点仍全在、总数 = before + 2 ----
	var probe: Node = packed.instantiate()
	var probe_paths: Array[String] = []
	_collect_paths(probe, probe, probe_paths)
	var probe_ok: bool = probe_paths.size() == before_count + 2
	var j: int = 0
	while j < before.size():
		if not probe_paths.has(before[j]):
			probe_ok = false
		j += 1
	var probe_count: int = probe_paths.size()
	_free_tree(probe)
	if not probe_ok:
		push_error("[R9-HD2D] 实例化复核失败 probe=%d，拒绝保存" % probe_count)
		_free_tree(root)
		quit(1)
		return

	var save_err: int = ResourceSaver.save(packed, SCENE_PATH)
	if save_err != OK:
		push_error("[R9-HD2D] ResourceSaver.save() 失败 err=%d" % save_err)
		_free_tree(root)
		quit(1)
		return
	_free_tree(root)
	print("[R9-HD2D] ATTACH_OK scene=%s before_nodes=%d after_nodes=%d preserved_existing=%s" % [SCENE_PATH, before_count, probe_count, str(preserved)])
	print("[R9-HD2D] ATTACH_POINT root=Courtyard -> HD2DPlaceholderLayer(CanvasLayer,layer=-10) -> HD2DPlaceholder(Node2D,script=hd2d_placeholder.gd,integer_scale=2)")
	quit(0)


func _collect_paths(node: Node, root: Node, out: Array[String]) -> void:
	## 记录「相对根路径|类名」，用于比对既有节点在追加前后是否逐条保留。
	out.append("%s|%s" % [str(root.get_path_to(node)), node.get_class()])
	var children: Array[Node] = node.get_children()
	var i: int = 0
	while i < children.size():
		_collect_paths(children[i], root, out)
		i += 1


func _free_tree(node: Node) -> void:
	## 后序释放游离节点树，避免 --script 自定义 MainLoop 退出时残留 RID / ObjectDB 实例。
	var children: Array[Node] = node.get_children()
	var i: int = 0
	while i < children.size():
		_free_tree(children[i])
		i += 1
	node.free()
