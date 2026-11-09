extends SceneTree
## R17 · 挂载 HD-2D 光效实例到 courtyard.tscn（SceneTree 追加式，幂等）
## 派单 cmd-20261109-093050-714-A1 · [ROUND=R17] · AI=1
## 依据：godot/scenes/hd2d_fx.tscn、Rank-4/HD2D-FX-PLAN.md、
##       assemble_r15.gd / tune_r16.gd（SceneTree 追加式 pack / owner 重设 /
##       CACHE_MODE_IGNORE 回读模式）、00-群聊总线.md（开工只读一次）。
##
## 真跑   : D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/attach_fx_r17.gd
## 抓帧   : D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot --write-movie F:/Game/aierdengfahuan/capture/r17.png --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn
## 三段门禁: ... --headless --path <root> --import
##           ... --headless --path <root> --check-only --script res://scripts/attach_fx_r17.gd
##           ... --headless --path <root> --quit
##       （抓帧与三段门禁为独立 CLI 真跑，脚本内不嵌套启动第二个引擎进程）
##
## 幂等：备份已存在则跳过（绝不覆盖）；HD2DFX 已挂载则走复核模式（不写盘、不重复挂入）；
##       所有赋值均为绝对目标值。节点数硬门槛：pack 前 23 → pack 后 24，
##       任一不符即 push_error + quit(1) 中止保存（场景零改动、不伪造输出）。
##       fx_profile 沿用 hd2d_fx.gd 默认 "desktop"（四项全开），本脚本不改写。

const SCENE_PATH: String = "res://scenes/courtyard.tscn"
const FX_SCENE_PATH: String = "res://scenes/hd2d_fx.tscn"
const FX_SCRIPT_PATH: String = "res://scripts/hd2d_fx.gd"
const BACKUP_ABS: String = "F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r17"
const SV_PATH: String = "SubViewportContainer/SubViewport"
const FX_NODE_NAME: String = "HD2DFX"
const FX_FULL_PATH: String = "SubViewportContainer/SubViewport/HD2DFX"
const FX_CHILDREN := ["FXReflection", "FXGodRays", "FXMotes", "FXBloom"]
const EXPECTED_BEFORE: int = 23
const EXPECTED_AFTER: int = 24
const PROFILE_DESKTOP: String = "desktop"

var _pass_count: int = 0
var _fail_count: int = 0


func _initialize() -> void:
	print("[R17] === ATTACH FX R17 START (cmd-20261109-093050-714-A1) ===")

	# --- 1) 备份（幂等：已存在则跳过，绝不覆盖 pre-r17 原件） ---
	if not _backup():
		push_error("[R17] STEP1 BACKUP 失败，拒绝继续（场景零改动）")
		quit(1)
		return

	# --- 2) 读磁盘最新场景（CACHE_MODE_IGNORE，避免命中进程缓存 / 并发旧副本） ---
	var src: PackedScene = ResourceLoader.load(
			SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if src == null:
		push_error("[R17] STEP2 CACHE_MODE_IGNORE load courtyard.tscn 失败，拒绝继续")
		quit(1)
		return
	var root: Node = src.instantiate()
	var before_nodes: int = src.get_state().get_node_count()
	print("[R17] STEP2 CACHE_MODE_IGNORE load OK, SceneState node_count(before)=", before_nodes)

	# --- 3) 接入点 SubViewport 存在性硬校验 ---
	var sv: Node = root.get_node_or_null(SV_PATH)
	if sv == null:
		push_error("[R17] STEP3 接入点 %s 缺失，拒绝继续（场景零改动）" % SV_PATH)
		_free_tree(root)
		quit(1)
		return
	print("[R17] STEP3 接入点 OK path=%s class=%s" % [SV_PATH, sv.get_class()])

	# --- 4) 幂等保护：HD2DFX 已由并发实例 / 前次真跑挂入 → 不写盘，仅复核 ---
	var existing: Node = sv.get_node_or_null(FX_NODE_NAME)
	if existing != null:
		print("[R17] STEP4 ALREADY_ATTACHED=true，跳过场景写入（尊重并发/既有产出），仅 CACHE_MODE_IGNORE 复核")
		_free_tree(root)
		var ok: bool = _verify()
		print("[R17] === ATTACH FX R17 END (复核模式) verify_ok=", str(ok), " ===")
		quit(0 if ok else 1)
		return
	print("[R17] STEP4 ALREADY_ATTACHED=false，开始挂载 FX 实例")

	# --- 5) load + instantiate，挂到 SubViewport 下（HD2DFX 是 CanvasLayer） ---
	# 用普通 load()（非 CACHE_MODE_IGNORE）：确保对象在 ResourceCache 注册、resource_path 正确，
	# pack 时 FX 实例才能写成 ExtResource 占位（沿用 R15 的 HUD / R16 §2.1 的教训）。
	var fx_ps: PackedScene = load(FX_SCENE_PATH) as PackedScene
	if fx_ps == null:
		push_error("[R17] STEP5 load %s 失败，拒绝继续" % FX_SCENE_PATH)
		_free_tree(root)
		quit(1)
		return
	var fx: Node = fx_ps.instantiate()
	fx.name = FX_NODE_NAME
	# 标记实例根 -> pack 写成 instance=ExtResource(...)，本场景只 +1 个节点段
	fx.set("scene_file_path", FX_SCENE_PATH)
	sv.add_child(fx)
	fx.owner = root  # 实例根必须纳入 owner 链，否则 pack 会丢弃
	print("[R17] STEP5 FX 实例已挂入 %s name=%s class=%s scene_file_path=%s" % [
			SV_PATH, fx.name, fx.get_class(), fx.scene_file_path])
	# fx_profile 沿用 hd2d_fx.gd 默认 "desktop"（四项全开），本脚本不改写、不改运行中脚本
	print("[R17] STEP5 FX 默认 fx_profile=desktop 四项全开（沿用脚本默认值）")

	# --- 6) 重设 owner 链：跳过 scene_file_path 非空的实例化节点 ---
	# （不递归进 HUD / HD2DFX 实例内部，避免被展开成普通节点段）
	_reset_owner(root, root)
	print("[R17] STEP6 owner 链重设完成（跳过实例化节点）")

	# --- 7) pack 前 / 后节点数比对（硬门槛 23→24，不一致则中止保存） ---
	var packed: PackedScene = PackedScene.new()
	var pack_err: Error = packed.pack(root)
	if pack_err != OK:
		push_error("[R17] STEP7 PackedScene.pack() 失败 err=%d，拒绝保存" % pack_err)
		_free_tree(root)
		quit(1)
		return
	var after_nodes: int = packed.get_state().get_node_count()

	# pack -> instantiate 往返探针：确认 FX 实例能展开、4 个子节点完整、根为 CanvasLayer
	var probe: Node = packed.instantiate()
	var probe_fx: Node = probe.get_node_or_null(FX_FULL_PATH)
	var probe_children_ok: bool = probe_fx != null
	if probe_fx != null:
		for nm in FX_CHILDREN:
			if probe_fx.get_node_or_null(str(nm)) == null:
				probe_children_ok = false
	var probe_is_instance: bool = probe_fx != null and probe_fx.scene_file_path != ""
	var probe_runtime_nodes: int = _count(probe)
	var probe_ok: bool = probe_fx != null and (probe_fx is CanvasLayer) \
			and probe_children_ok and probe_is_instance
	_free_tree(probe)

	var count_ok: bool = (before_nodes == EXPECTED_BEFORE) \
			and (after_nodes == EXPECTED_AFTER) \
			and (after_nodes == before_nodes + 1)
	print("[R17] STEP7 NODE_COUNT before=%d after=%d expected_before=%d expected_after=%d pack_err=%d probe_runtime=%d probe_ok=%s count_ok=%s" % [
			before_nodes, after_nodes, EXPECTED_BEFORE, EXPECTED_AFTER, pack_err,
			probe_runtime_nodes, str(probe_ok), str(count_ok)])

	if not count_ok or not probe_ok:
		push_error("[R17] STEP7 节点数/结构比对失败，中止保存（场景零改动，不伪造输出）")
		_free_tree(root)
		quit(1)
		return
	_free_tree(root)

	# --- 8) 保存 ---
	var save_err: Error = ResourceSaver.save(packed, SCENE_PATH)
	if save_err != OK:
		push_error("[R17] STEP8 ResourceSaver.save() 失败 err=%d，拒绝继续" % save_err)
		quit(1)
		return
	print("[R17] STEP8 SAVE_OK path=%s save_err=%d" % [SCENE_PATH, save_err])

	# --- 9) CACHE_MODE_IGNORE 从磁盘回读验证 ---
	var verify_ok: bool = _verify()
	print("[R17] === ATTACH FX R17 END verify_ok=", str(verify_ok), " ===")
	quit(0 if verify_ok else 1)


func _backup() -> bool:
	if FileAccess.file_exists(BACKUP_ABS):
		print("[R17] STEP1 BACKUP 已存在，跳过（幂等，绝不覆盖）: %s" % BACKUP_ABS)
		return true
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(SCENE_PATH)
	if bytes.is_empty():
		push_error("[R17] STEP1 读取源场景字节失败 path=%s" % SCENE_PATH)
		return false
	var f: FileAccess = FileAccess.open(BACKUP_ABS, FileAccess.WRITE)
	if f == null:
		push_error("[R17] STEP1 打开备份路径失败 err=%d path=%s" % [
				FileAccess.get_open_error(), BACKUP_ABS])
		return false
	f.store_buffer(bytes)
	f.close()
	print("[R17] STEP1 BACKUP 写入 %d 字节 -> %s" % [bytes.size(), BACKUP_ABS])
	return true


func _verify() -> bool:
	# CACHE_MODE_IGNORE：不走资源缓存，强制从磁盘重读刚保存的 courtyard.tscn
	print("==== [R17 回读 CACHE_MODE_IGNORE] START ====")
	_pass_count = 0
	_fail_count = 0
	var ps: PackedScene = ResourceLoader.load(
			SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if ps == null:
		push_error("[R17_VERIFY] CACHE_MODE_IGNORE 回读失败 path=%s" % SCENE_PATH)
		return false
	var disk_nodes: int = ps.get_state().get_node_count()
	print("[R17_VERIFY] readback class=%s resource_path=%s SceneState_nodes=%d" % [
			ps.get_class(), ps.resource_path, disk_nodes])
	_check("① readback_not_null_and_PackedScene", ps is PackedScene,
			"class=%s" % ps.get_class())

	var inst: Node = ps.instantiate()
	var fx: Node = inst.get_node_or_null(FX_FULL_PATH)

	# ② FX 实例存在
	var fx_present: bool = fx != null
	_check("② FX_instance_present", fx_present,
			"path=%s found=%s" % [FX_FULL_PATH, str(fx_present)])

	# ③ 根为 CanvasLayer（layer=10 冻结值，仅打印比对、不改）
	var fx_is_cl: bool = fx != null and fx is CanvasLayer
	var fx_layer: int = -999
	if fx_is_cl:
		fx_layer = (fx as CanvasLayer).layer
	_check("③ FX_root_is_CanvasLayer", fx_is_cl,
			"name=%s class=%s layer=%d (expected=10)" % [
					(fx.name if fx != null else "<null>"),
					(fx.get_class() if fx != null else "<null>"), fx_layer])

	# ④ 实例标记（instance 占位，未展开成普通节点段 → 节点数只 +1）
	var fx_is_instance: bool = fx != null and fx.scene_file_path != ""
	_check("④ FX_is_instance_placeholder", fx_is_instance,
			"scene_file_path=%s" % (fx.scene_file_path if fx != null else "<null>"))

	# ⑤ 脚本已挂：4 个子节点各挂 res://scripts/hd2d_fx.gd
	var script_ok: bool = fx != null
	var script_detail: PackedStringArray = PackedStringArray()
	for nm in FX_CHILDREN:
		var c: Node = null
		if fx != null:
			c = fx.get_node_or_null(str(nm))
		var s: Script = null
		if c != null:
			s = c.get_script() as Script
		var hit: bool = s != null and s.resource_path == FX_SCRIPT_PATH
		script_ok = script_ok and hit
		script_detail.append("%s:script=%s" % [str(nm), (s.resource_path if s != null else "<null>")])
	_check("⑤ script_attached_all_4", script_ok, " | ".join(script_detail))

	# ⑥ fx_profile 默认 desktop（四项全开，沿用脚本默认值、本脚本不改写）
	var profile_ok: bool = fx != null
	var profile_detail: PackedStringArray = PackedStringArray()
	for nm in FX_CHILDREN:
		var c: Node = null
		if fx != null:
			c = fx.get_node_or_null(str(nm))
		var p: String = "<null>"
		if c != null:
			p = str(c.get("fx_profile"))
		profile_ok = profile_ok and (p == PROFILE_DESKTOP)
		profile_detail.append("%s:%s" % [str(nm), p])
	_check("⑥ fx_profile_desktop_all_on", profile_ok, " | ".join(profile_detail))

	# ⑦ 节点数 24（SceneState 层）
	var nodes_ok: bool = (disk_nodes == EXPECTED_AFTER)
	_check("⑦ SceneState_node_count_24", nodes_ok,
			"nodes=%d expected=%d" % [disk_nodes, EXPECTED_AFTER])
	var runtime_nodes: int = _count(inst)
	print("[R17_VERIFY] RUNTIME_NODES=%d（实例展开后整树，含 HUD 内部 2 + HD2DFX 内部 4）" % runtime_nodes)

	_free_tree(inst)
	var all_ok: bool = (_fail_count == 0)
	print("[R17_VERIFY] VERIFY_SUMMARY pass=%d fail=%d OK=%s" % [_pass_count, _fail_count, str(all_ok)])
	print("==== [R17 回读 CACHE_MODE_IGNORE] END ====")
	return all_ok


func _check(label: String, ok: bool, detail: String) -> void:
	if ok:
		_pass_count += 1
	else:
		_fail_count += 1
	print("[R17_VERIFY] %s PASS=%s | %s" % [label, str(ok), detail])


func _reset_owner(node: Node, owner_node: Node) -> void:
	# 重设 owner 链；跳过 scene_file_path 非空的实例化节点（不递归进其内部子节点）
	for child in node.get_children():
		if child.scene_file_path != "":
			continue
		child.owner = owner_node
		_reset_owner(child, owner_node)


func _count(node: Node) -> int:
	var n: int = 1
	for child in node.get_children():
		n += _count(child)
	return n


func _free_tree(node: Node) -> void:
	for child in node.get_children():
		_free_tree(child)
	node.free()
