extends SceneTree
## R14 · HUD 接入件（可复用；本轮 R14 不执行写入主场景）
##
## 作用：把 res://scenes/hud.tscn 以「实例」形式追加挂到
##   res://scenes/courtyard.tscn 的 SubViewportContainer/SubViewport/FXLayer 下，
##   重新 PackedScene.pack()、比对节点数、CACHE_MODE_IGNORE 回读校验 HUD 存在。
##
## 【本轮边界 · 必读】
##   R14 只用 `--check-only --script` 验证语法，不执行脚本逻辑
##   （Rank-1 本轮并发改同一 courtyard.tscn，避免写冲突）。
##   --check-only 只解析脚本、不调用 _initialize()，因此不会产生任何写入。
##   R15 串行改场景时才去掉 --check-only 真跑；真跑会 ResourceSaver.save()
##   覆盖 courtyard.tscn，执行前必须先备份，回退见 Rank-3/HUD-ATTACH.md。
##   本脚本不自行 git、不写其它工位、不加载任何外部素材 / 付费服务。
##
## 【节点数口径 · 为什么预期 22→23】
##   统计的是 PackedScene.get_state().get_node_count()，即 .tscn 内 [node]
##   段的数量（SceneState 层），不是运行期递归节点数。
##   hud.tscn 以 instance=ExtResource(...) 挂入：实例根节点在本场景里只占
##   1 个节点段，其内部 HudPanel / TitleLabel 属于被实例的场景，不计入本场景
##   SceneState，故 22 + 1 = 23。运行期 instantiate() 会展开实例，届时整树
##   为 22 + 3 = 25 个节点，属正常实例展开，不是错误。
##   实例标记用 Node 的 scene_file_path 属性（Object.set 按名写入）；若引擎
##   未按实例写出，真实 get_node_count() 会是 25，本脚本会如实 push_error
##   + quit(1)，绝不伪造 23。
##
## 引擎 Godot 4.7.2.stable · 纯程序化 · 零外部素材 · 中文 UTF-8
## 本轮 R14：godot --headless --path <工程根> --check-only --script res://scripts/attach_hud.gd
## R15 执行：godot --headless --path <工程根> --script res://scripts/attach_hud.gd

const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"
const HUD_PATH: String = "res://scenes/hud.tscn"
const FXLAYER_PATH: String = "SubViewportContainer/SubViewport/FXLayer"
const HUD_NODE_NAME: String = "Hud"
const EXPECTED_NODES_BEFORE: int = 22
const EXPECTED_NODES_AFTER: int = 23


func _initialize() -> void:
	var src: PackedScene = load(COURTYARD_PATH) as PackedScene
	if src == null:
		push_error("[HUD_ATTACH] 无法加载既有场景 %s，拒绝接入" % COURTYARD_PATH)
		quit(1)
		return

	var root: Node = src.instantiate()
	var before_nodes: int = src.get_state().get_node_count()

	var fx: Node = root.get_node_or_null(FXLAYER_PATH)
	if fx == null:
		push_error("[HUD_ATTACH] 未找到接入点 %s，拒绝接入" % FXLAYER_PATH)
		_free_tree(root)
		quit(1)
		return
	if fx.get_node_or_null(HUD_NODE_NAME) != null:
		push_error("[HUD_ATTACH] %s/%s 已存在，避免重复挂入，拒绝接入" % [FXLAYER_PATH, HUD_NODE_NAME])
		_free_tree(root)
		quit(1)
		return

	var hud_ps: PackedScene = load(HUD_PATH) as PackedScene
	if hud_ps == null:
		push_error("[HUD_ATTACH] 无法加载 HUD 场景 %s，拒绝接入" % HUD_PATH)
		_free_tree(root)
		quit(1)
		return

	var hud: Node = hud_ps.instantiate()
	hud.name = HUD_NODE_NAME
	# 标记为「实例根」，让 PackedScene.pack() 写成 instance=ExtResource(...)，
	# 使本场景 SceneState 只新增 1 个节点段（22→23）。
	hud.set("scene_file_path", HUD_PATH)
	fx.add_child(hud)
	# 只给新节点及其子节点设 owner=root；既有节点 owner 由 instantiate() 自带，不改动
	_assign_owner_added(hud, root)

	var packed: PackedScene = PackedScene.new()
	var pack_err: int = packed.pack(root)
	if pack_err != OK:
		push_error("[HUD_ATTACH] PackedScene.pack() 失败 err=%d" % pack_err)
		_free_tree(root)
		quit(1)
		return

	var after_nodes: int = packed.get_state().get_node_count()
	var count_ok: bool = (before_nodes == EXPECTED_NODES_BEFORE) \
		and (after_nodes == EXPECTED_NODES_AFTER)
	print("[HUD_ATTACH] NODE_COUNT before=%d after=%d expected=%d→%d ok=%s" % [
		before_nodes, after_nodes, EXPECTED_NODES_BEFORE, EXPECTED_NODES_AFTER, str(count_ok)])

	# pack → instantiate 往返：确认 HUD 实例被展开且内部节点完整
	var probe: Node = packed.instantiate()
	var probe_hud: Node = probe.get_node_or_null(FXLAYER_PATH + "/" + HUD_NODE_NAME)
	var probe_ok: bool = probe_hud != null \
		and probe_hud.get_node_or_null("HudPanel") != null \
		and probe_hud.get_node_or_null("TitleLabel") != null
	var probe_nodes: int = _count_nodes(probe)
	_free_tree(probe)
	print("[HUD_ATTACH] PROBE hud_present=%s runtime_nodes=%d" % [str(probe_ok), probe_nodes])

	if not count_ok or not probe_ok:
		push_error("[HUD_ATTACH] 节点数/结构比对失败，拒绝保存（不伪造输出）")
		_free_tree(root)
		quit(1)
		return

	_free_tree(root)

	# 以下为 R15 串行改场景时才执行的写入；R14 --check-only 不会到达此处。
	var save_err: int = ResourceSaver.save(packed, COURTYARD_PATH)
	if save_err != OK:
		push_error("[HUD_ATTACH] ResourceSaver.save() 失败 err=%d path=%s" % [save_err, COURTYARD_PATH])
		quit(1)
		return
	print("[HUD_ATTACH] SAVE_OK path=%s" % COURTYARD_PATH)

	var verify_ok: bool = _verify_hud_exists()
	print("[HUD_ATTACH] VERIFY_SUMMARY hud_exists=%s ok=%s" % [str(verify_ok), str(verify_ok)])
	quit(0 if verify_ok else 1)


func _verify_hud_exists() -> bool:
	## CACHE_MODE_IGNORE：不走资源缓存，强制从磁盘重读刚保存的 courtyard.tscn，
	## 确保校验对象是真正落盘的场景文件，而非内存里刚 pack 出的对象。
	var ps: PackedScene = ResourceLoader.load(
			COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if ps == null:
		push_error("[HUD_VERIFY] CACHE_MODE_IGNORE 回读失败 path=%s" % COURTYARD_PATH)
		return false
	var inst: Node = ps.instantiate()
	var hud: Node = inst.get_node_or_null(FXLAYER_PATH + "/" + HUD_NODE_NAME)
	var found: bool = hud != null
	var detail: String = "hud_missing"
	if found:
		detail = "hud=%s class=%s panel=%s label=%s" % [
			hud.name, hud.get_class(),
			str(hud.get_node_or_null("HudPanel") != null),
			str(hud.get_node_or_null("TitleLabel") != null)]
	print("[HUD_VERIFY] CACHE_MODE_IGNORE 回读 HUD 存在 PASS=%s | %s" % [str(found), detail])
	_free_tree(inst)
	return found


func _assign_owner_added(node: Node, root: Node) -> void:
	## 只给追加的子树设 owner=root，使 PackedScene.pack() 能包含新节点；
	## 既有场景节点 owner 已由 instantiate() 指向 root，不改动。
	var children: Array[Node] = node.get_children()
	var i: int = 0
	while i < children.size():
		_assign_owner_added(children[i], root)
		i += 1
	node.owner = root


func _count_nodes(node: Node) -> int:
	## 运行期递归节点数（会把 instance 展开后的内部节点也计入）。
	var total: int = 1
	var children: Array[Node] = node.get_children()
	var i: int = 0
	while i < children.size():
		total += _count_nodes(children[i])
		i += 1
	return total


func _free_tree(node: Node) -> void:
	## 后序释放游离节点树，避免 --script 自定义 MainLoop 退出时残留 ObjectDB 实例。
	var children: Array[Node] = node.get_children()
	var i: int = 0
	while i < children.size():
		_free_tree(children[i])
		i += 1
	node.free()
