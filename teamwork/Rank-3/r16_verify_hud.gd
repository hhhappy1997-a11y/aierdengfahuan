extends SceneTree

## R16 回读校验载体（临时，仅用于本轮真跑；落在 Rank-3 工位，不写工程内其它文件）。
## CACHE_MODE_IGNORE 强制从磁盘重读 res://scenes/hud.tscn → instantiate()，
## 确认根节点已挂 hud.gd、TitleLabel 可寻址、4 信号与草案方法可寻址。
## 只读：不 pack、不 save、不改任何场景。

const HUD_PATH: String = "res://scenes/hud.tscn"
const SCRIPT_PATH: String = "res://scripts/hud.gd"

func _initialize() -> void:
	var pass_count: int = 0
	var fail_count: int = 0

	var packed: PackedScene = ResourceLoader.load(HUD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		print("[R16_VERIFY] ① scene_loaded FAIL=true | 无法加载 %s" % HUD_PATH)
		print("[R16_VERIFY] VERIFY_SUMMARY pass=0 fail=1 ok=false")
		quit(1)
		return
	var root: Node = packed.instantiate()

	# ① 根节点类型与 hud.gd 的 extends CanvasLayer 一致
	var root_is_canvas: bool = root is CanvasLayer
	print("[R16_VERIFY] ① root_is_CanvasLayer PASS=%s | name=%s class=%s" % [str(root_is_canvas), str(root.name), root.get_class()])
	if root_is_canvas:
		pass_count += 1
	else:
		fail_count += 1

	# ② 脚本已挂到根节点，且指向 res://scripts/hud.gd
	var scr: Script = root.get_script() as Script
	var script_ok: bool = scr != null and scr.resource_path == SCRIPT_PATH
	var scr_path: String = "<null>"
	if scr != null:
		scr_path = scr.resource_path
	print("[R16_VERIFY] ② script_attached PASS=%s | path=%s" % [str(script_ok), scr_path])
	if script_ok:
		pass_count += 1
	else:
		fail_count += 1

	# ③ TitleLabel 可寻址且为 Label
	var label: Node = root.get_node_or_null("TitleLabel")
	var label_ok: bool = label != null and label is Label
	var label_text: String = ""
	var label_class: String = "<null>"
	if label != null:
		label_class = label.get_class()
		if label is Label:
			label_text = (label as Label).text
	print("[R16_VERIFY] ③ TitleLabel PASS=%s | class=%s text=%s" % [str(label_ok), label_class, label_text])
	if label_ok:
		pass_count += 1
	else:
		fail_count += 1

	# ④ 4 个信号存在
	var signals_ok: bool = true
	for s in ["grace_selected", "travel_confirmed", "rest_requested", "hud_refreshed"]:
		if not root.has_signal(String(s)):
			signals_ok = false
			print("[R16_VERIFY] ④ signal MISSING %s" % String(s))
	print("[R16_VERIFY] ④ four_signals PASS=%s" % str(signals_ok))
	if signals_ok:
		pass_count += 1
	else:
		fail_count += 1

	# ⑤ 草案 15 方法 + grace_fast_travel + 附加方法可寻址
	var methods: Array = [
		"bind_world_state", "load_grace_network", "refresh_all", "refresh_label",
		"_on_flag_changed", "_on_delta_committed", "set_title_from_grace", "apply_lit_state",
		"build_grace_menu", "is_grace_unlocked", "are_flags_satisfied", "get_reachable_targets",
		"on_grace_selected", "request_travel", "grace_fast_travel",
		"request_rest", "set_fast_travel_committer"
	]
	var miss: Array = []
	for m in methods:
		if not root.has_method(String(m)):
			miss.append(String(m))
	var methods_ok: bool = miss.is_empty()
	print("[R16_VERIFY] ⑤ methods PASS=%s | total=%d missing=%s" % [str(methods_ok), methods.size(), str(miss)])
	if methods_ok:
		pass_count += 1
	else:
		fail_count += 1

	# ⑥ 真实触发 _ready()（加入场景树），验证全量刷新后 TitleLabel 仍有可显示文本
	get_root().add_child(root)
	var lbl_after: Label = root.get_node_or_null("TitleLabel") as Label
	var after_text: String = ""
	if lbl_after != null:
		after_text = lbl_after.text
	var ready_ok: bool = not after_text.is_empty()
	print("[R16_VERIFY] ⑥ ready_refresh PASS=%s | TitleLabel.text=%s" % [str(ready_ok), after_text])
	if ready_ok:
		pass_count += 1
	else:
		fail_count += 1

	print("[R16_VERIFY] VERIFY_SUMMARY pass=%d fail=%d ok=%s" % [pass_count, fail_count, str(fail_count == 0)])
	quit(0 if fail_count == 0 else 1)
