extends SceneTree

## v0.4.0 R26 · 赐福试炼「运行时」验证（Rank-1，cmd-20261111-073556-918-A1）。
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path <godot> \
##       --script res://scripts/combat/verify_wave_runtime_v040.gd
## 断言：三波推进 / 超时 / 失败 / 重复触发 / 依赖缺失降级 / encounter_finished 接线 /
##       失败回赐福休息 / courtyard.tscn 节点数改动前后比对 + CACHE_MODE_IGNORE 回读
##       （三个地面 uv1_scale 4/2/1、波次 HUD、既有 HUD 文本、instance 覆盖段）。
## 逐条输出 PASS/FAIL 与 RESULT，失败 quit(1)，不伪造 PASS。
## 装配惯例同 v010/v020/v030：--script 模式 add_child 不 flush _ready，需显式 call("_ready")；
##   /root/... 绝对路径不可用，用 root.get_node_or_null() 与相对 NodePath。
## 三波推进用 configure_waves() 注入「占位桩时序」（非 Rank-2 设计数值），
##   保证 Rank-2 表落盘与否都能确定性验证状态机；真实表加载结果单独如实登记。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

const DIRECTOR_SCRIPT: String = "res://scripts/combat/wave_trial_director.gd"
const ENCOUNTER_DIRECTOR_SCRIPT: String = "res://scripts/combat/encounter_director.gd"
const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"
const TABLE_PATH: String = "res://data/rpg/wave_trial.tres"
const MISSING_TABLE_PATH: String = "res://data/rpg/__missing_wave_trial__.tres"
const FIELDLESS_TABLE_PATH: String = "res://data/rpg/grace_network.tres"  # 存在但无 waves 字段

# 节点数改动前后基线：改前 33（R25 DONE 登记 + R26 改前 grep "^[node " 实测），
# R26 改后 36（+ WaveTrialHud / WaveLabel / WaveTrialDirector 三个真实节点）。
# R27B 补单（cmd-20261111-091349-628-A1）授权在 courtyard.tscn 再加 2 个真实节点：
#   GraceUpgradeRuntime（WaveTrialDirector 下，裁决 A24 增益运行时挂载）
#   GraceShopLabel（Hud 下，赐福成长购买 HUD）
# 故改后基线同步为 38（+5）。属「断言与当前实现的真实口径差异 → 修断言」：
#   只同步精确期望值，断言仍严格检查 node_count 与 delta，不删断言、不放宽、不掩盖。
const NODE_COUNT_BEFORE: int = 33
const NODE_COUNT_AFTER: int = 38
const NODE_COUNT_DELTA: int = 5

var _pass: int = 0
var _fail: int = 0
var _started: Array = []
var _cleared: Array = []
var _completed: Array = []


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V040] %s PASS=%s | %s" % [tag, str(ok), detail])


func _on_wave_started(index: int, total: int) -> void:
	_started.append([index, total])


func _on_wave_cleared(index: int, points: int) -> void:
	_cleared.append([index, points])


func _on_trial_completed(best_wave: int) -> void:
	_completed.append(best_wave)


func _reset_signals() -> void:
	_started.clear()
	_cleared.clear()
	_completed.clear()


## --script 模式装配：add_child 不 flush _ready，显式 call 一次；关掉 _process 以免自动推进。
func _make_director() -> Node:
	var d: Node = Node.new()
	d.set_script(load(DIRECTOR_SCRIPT) as Script)
	root.add_child(d)
	d.call("_ready")
	d.set_process(false)
	d.connect("wave_started", Callable(self, "_on_wave_started"))
	d.connect("wave_cleared", Callable(self, "_on_wave_cleared"))
	d.connect("trial_completed", Callable(self, "_on_trial_completed"))
	return d


func _free_node(n: Node) -> void:
	if n != null and is_instance_valid(n):
		n.free()


func _uv_of(mi: MeshInstance3D) -> Vector3:
	if mi == null or not (mi.material_override is StandardMaterial3D):
		return Vector3.ZERO
	return (mi.material_override as StandardMaterial3D).uv1_scale


func _stub_waves() -> Array:
	# [PLACEHOLDER-桩] 纯时序桩：只用于验证状态机推进逻辑，不是 Rank-2 设计数值。
	return [
		{"telegraph": 1.0, "time_limit": 10.0, "points": 1},
		{"telegraph": 1.0, "time_limit": 10.0, "points": 2},
		{"telegraph": 1.0, "time_limit": 10.0, "points": 3},
	]


func _initialize() -> void:
	print("[V040] === SELFTEST START ===")
	print("[V040] cmd-20261111-073556-918-A1 [ROUND=R26] Rank-1 | extends SceneTree 真跑")
	_test_real_table()
	_test_three_wave_progression()
	_test_timeout()
	_test_failure()
	_test_duplicate_triggers()
	_test_degrade_paths()
	_test_encounter_wiring()
	_test_courtyard_readback()
	print("[V040] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	print("[V040] RESULT=%s" % ("ALL_MATCH" if _fail == 0 else "FAILED"))
	print("[V040] === SELFTEST END ===")
	quit(0 if _fail == 0 else 1)


# ---------------------------------------------------------------------------
# A) 真实 Rank-2 表加载结果（如实登记；表存在→3 波，缺失→单波降级，两者皆符合预期）
# ---------------------------------------------------------------------------
func _test_real_table() -> void:
	_reset_signals()
	var d: Node = _make_director()
	var s: Dictionary = d.call("get_snapshot")
	var exists: bool = ResourceLoader.exists(TABLE_PATH)
	var consistent: bool = (exists and int(s["total"]) == 3 and not bool(s["degraded"])) \
			or (not exists and int(s["total"]) == 1 and bool(s["degraded"]))
	_ck("real_table_load_consistent", consistent,
			"table_exists=%s total=%s degraded=%s reason=%s（真实表读取，不硬编码三波数值）" % [
				str(exists), str(s["total"]), str(s["degraded"]), str(s["degrade_reason"])])
	_free_node(d)


# ---------------------------------------------------------------------------
# B) 三波推进（注入 3 波占位时序，确定性验证完整状态机与三个信号）
# ---------------------------------------------------------------------------
func _test_three_wave_progression() -> void:
	_reset_signals()
	var d: Node = _make_director()
	var injected: bool = bool(d.call("configure_waves", _stub_waves()))
	var s0: Dictionary = d.call("get_snapshot")
	_ck("inject_three_waves", injected and int(s0["total"]) == 3 and not bool(s0["degraded"]),
			"injected=%s total=%s degraded=%s" % [str(injected), str(s0["total"]), str(s0["degraded"])])

	var started_ok: bool = bool(d.call("start_trial"))
	var s1: Dictionary = d.call("get_snapshot")
	_ck("start_enters_telegraph", started_ok and int(s1["state"]) == 1 and int(s1["index"]) == 0 \
			and _started.size() == 1 and _started[0] == [0, 3],
			"started=%s state=%s index=%s wave_started=%s" % [
				str(started_ok), str(s1["state_name"]), str(s1["index"]), str(_started)])

	d.call("debug_advance", 1.0)
	var s2: Dictionary = d.call("get_snapshot")
	_ck("telegraph_to_active", int(s2["state"]) == 2 and is_equal_approx(float(s2["remaining"]), 10.0),
			"state=%s remaining=%s" % [str(s2["state_name"]), str(s2["remaining"])])

	var win1: bool = bool(d.call("on_encounter_finished", true))
	var s3: Dictionary = d.call("get_snapshot")
	_ck("wave1_cleared", win1 and int(s3["state"]) == 3 and int(s3["points_total"]) == 1 \
			and _cleared.size() == 1 and _cleared[0] == [0, 1],
			"win=%s state=%s points_total=%s wave_cleared=%s" % [
				str(win1), str(s3["state_name"]), str(s3["points_total"]), str(_cleared)])

	# 重复触发门控：WAVE_CLEARED 期再次结算必须被拒，不重复计点
	var dup: bool = bool(d.call("on_encounter_finished", true))
	var s3b: Dictionary = d.call("get_snapshot")
	_ck("duplicate_finish_rejected", not dup and int(s3b["rejected_finishes"]) == 1 \
			and int(s3b["points_total"]) == 1,
			"dup=%s rejected=%s points_total=%s" % [
				str(dup), str(s3b["rejected_finishes"]), str(s3b["points_total"])])

	d.call("debug_advance", 0.0)
	var s4a: Dictionary = d.call("get_snapshot")
	d.call("debug_advance", 0.0)
	var s4b: Dictionary = d.call("get_snapshot")
	_ck("next_wave_transition", int(s4a["state"]) == 4 and int(s4b["state"]) == 1 \
			and int(s4b["index"]) == 1 and _started.size() == 2,
			"cleared→%s→%s index=%s started=%s" % [
				str(s4a["state_name"]), str(s4b["state_name"]), str(s4b["index"]), str(_started)])

	d.call("debug_advance", 1.0)
	d.call("on_encounter_finished", true)
	var s5: Dictionary = d.call("get_snapshot")
	_ck("wave2_cleared", int(s5["state"]) == 3 and int(s5["points_total"]) == 3 \
			and _cleared.size() == 2 and _cleared[1] == [1, 2],
			"state=%s points_total=%s wave_cleared=%s" % [
				str(s5["state_name"]), str(s5["points_total"]), str(_cleared)])

	d.call("debug_advance", 0.0)   # WAVE_CLEARED → NEXT_WAVE
	d.call("debug_advance", 0.0)   # NEXT_WAVE → TELEGRAPH(index=2)
	d.call("debug_advance", 1.0)   # TELEGRAPH → WAVE_ACTIVE
	d.call("on_encounter_finished", true)
	var s6: Dictionary = d.call("get_snapshot")
	_ck("wave3_cleared", int(s6["state"]) == 3 and int(s6["points_total"]) == 6 \
			and _cleared.size() == 3 and _cleared[2] == [2, 3],
			"state=%s points_total=%s wave_cleared=%s" % [
				str(s6["state_name"]), str(s6["points_total"]), str(_cleared)])

	d.call("debug_advance", 0.0)   # 最后一波 → TRIAL_COMPLETED
	var s7: Dictionary = d.call("get_snapshot")
	_ck("trial_completed", int(s7["state"]) == 5 and _completed.size() == 1 and _completed[0] == 3,
			"state=%s trial_completed=%s" % [str(s7["state_name"]), str(_completed)])

	_ck("best_wave_and_history", int(s7["best_wave"]) == 3 \
			and (s7["started_waves"] as Array) == [0, 1, 2] \
			and (s7["cleared_waves"] as Array) == [0, 1, 2],
			"best=%s started=%s cleared=%s" % [
				str(s7["best_wave"]), str(s7["started_waves"]), str(s7["cleared_waves"])])

	var start_again: bool = bool(d.call("start_trial"))
	var s8: Dictionary = d.call("get_snapshot")
	_ck("duplicate_start_rejected", not start_again and int(s8["start_rejects"]) == 1,
			"start_again=%s start_rejects=%s" % [str(start_again), str(s8["start_rejects"])])
	_free_node(d)


# ---------------------------------------------------------------------------
# C) 超时：WAVE_ACTIVE 倒计时归零 → 回 IDLE / 赐福休息 / 不推进波次
# ---------------------------------------------------------------------------
func _test_timeout() -> void:
	_reset_signals()
	var d: Node = _make_director()
	d.call("configure_waves", [{"telegraph": 1.0, "time_limit": 5.0, "points": 0}])
	d.call("start_trial")
	d.call("debug_advance", 1.0)
	d.call("debug_advance", 5.0 + 1.0)
	var s: Dictionary = d.call("get_snapshot")
	_ck("timeout_returns_to_idle", int(s["state"]) == 0 and int(s["timeouts"]) == 1 \
			and int(s["grace_rests"]) == 1,
			"state=%s timeouts=%s grace_rests=%s" % [
				str(s["state_name"]), str(s["timeouts"]), str(s["grace_rests"])])
	_ck("timeout_no_wave_progress", int(s["points_total"]) == 0 and (s["cleared_waves"] as Array).is_empty(),
			"points_total=%s cleared=%s" % [str(s["points_total"]), str(s["cleared_waves"])])
	_free_node(d)


# ---------------------------------------------------------------------------
# D) 失败：encounter_finished(false) → 回 IDLE / 赐福休息 / 不推进波次
# ---------------------------------------------------------------------------
func _test_failure() -> void:
	_reset_signals()
	var d: Node = _make_director()
	d.call("configure_waves", _stub_waves())
	d.call("start_trial")
	d.call("debug_advance", 1.0)
	var lost: bool = bool(d.call("on_encounter_finished", false))
	var s: Dictionary = d.call("get_snapshot")
	_ck("failure_returns_to_idle", lost and int(s["state"]) == 0 and int(s["failures"]) == 1 \
			and int(s["grace_rests"]) == 1,
			"lost=%s state=%s failures=%s grace_rests=%s" % [
				str(lost), str(s["state_name"]), str(s["failures"]), str(s["grace_rests"])])
	_ck("failure_no_progress", int(s["index"]) == 0 and (s["cleared_waves"] as Array).is_empty(),
			"index=%s cleared=%s" % [str(s["index"]), str(s["cleared_waves"])])
	_free_node(d)


# ---------------------------------------------------------------------------
# E) 重复触发：IDLE 期结算被拒 / 同一实例二次 start_trial 被拒
# ---------------------------------------------------------------------------
func _test_duplicate_triggers() -> void:
	_reset_signals()
	var d: Node = _make_director()
	var idle_finish: bool = bool(d.call("on_encounter_finished", true))
	var a: bool = bool(d.call("start_trial"))
	var b: bool = bool(d.call("start_trial"))
	var s: Dictionary = d.call("get_snapshot")
	_ck("idle_finish_rejected", not idle_finish and int(s["rejected_finishes"]) == 1,
			"idle_finish=%s rejected=%s" % [str(idle_finish), str(s["rejected_finishes"])])
	_ck("double_start_rejected", a and not b and int(s["start_rejects"]) == 1,
			"first=%s second=%s start_rejects=%s" % [str(a), str(b), str(s["start_rejects"])])
	_free_node(d)


# ---------------------------------------------------------------------------
# F) 依赖缺失降级：资源不存在 / 存在但无 waves 字段 / 单波仍能跑完不崩
# ---------------------------------------------------------------------------
func _test_degrade_paths() -> void:
	_reset_signals()
	var d: Node = _make_director()
	d.set("table_path", MISSING_TABLE_PATH)
	d.call("reload_table")
	var s1: Dictionary = d.call("get_snapshot")
	_ck("missing_resource_degrades", bool(s1["degraded"]) and int(s1["total"]) == 1 \
			and String(s1["degrade_reason"]).contains("资源不存在"),
			"degraded=%s total=%s reason=%s" % [
				str(s1["degraded"]), str(s1["total"]), str(s1["degrade_reason"])])

	d.set("table_path", FIELDLESS_TABLE_PATH)
	d.call("reload_table")
	var s2: Dictionary = d.call("get_snapshot")
	_ck("missing_field_degrades", bool(s2["degraded"]) and int(s2["total"]) == 1 \
			and String(s2["degrade_reason"]).contains("字段缺失"),
			"degraded=%s total=%s reason=%s" % [
				str(s2["degraded"]), str(s2["total"]), str(s2["degrade_reason"])])

	var started_ok: bool = bool(d.call("start_trial"))
	d.call("debug_advance", 1.5)
	d.call("debug_advance", 30.0 + 1.0)   # 单波超时也不会崩
	var s3: Dictionary = d.call("get_snapshot")
	_ck("degraded_single_wave_no_crash", started_ok and int(s3["total"]) == 1 \
			and int(s3["timeouts"]) >= 1 and s3.has("state_name"),
			"started=%s total=%s timeouts=%s state=%s" % [
				str(started_ok), str(s3["total"]), str(s3["timeouts"]), str(s3["state_name"])])
	_ck("degraded_no_three_wave_hardcode", int(s3["total"]) == 1,
			"降级后 total=%s（不得出现硬编码三波）" % str(s3["total"]))
	_free_node(d)


# ---------------------------------------------------------------------------
# G) 接既有 EncounterDirector.encounter_finished(won)：真实脚本实例作信号源
# ---------------------------------------------------------------------------
func _test_encounter_wiring() -> void:
	_reset_signals()
	var d: Node = _make_director()
	var e: Node = Node.new()
	e.set_script(load(ENCOUNTER_DIRECTOR_SCRIPT) as Script)
	root.add_child(e)
	e.call("_ready")
	var bound: bool = bool(d.call("bind_encounter_director", e))
	_ck("bind_encounter_finished_signal", bound,
			"bound=%s has_signal=%s" % [str(bound), str(e.has_signal("encounter_finished"))])

	d.call("configure_waves", _stub_waves())
	d.call("start_trial")
	d.call("debug_advance", 1.0)
	e.emit_signal("encounter_finished", true)
	var s1: Dictionary = d.call("get_snapshot")
	_ck("signal_win_advances_wave", int(s1["state"]) == 3 and _cleared.size() == 1,
			"state=%s wave_cleared=%s（既有 encounter_finished(true) 真实转发）" % [
				str(s1["state_name"]), str(_cleared)])

	d.call("debug_advance", 0.0)   # → NEXT_WAVE
	d.call("debug_advance", 0.0)   # → 下一波 TELEGRAPH
	d.call("debug_advance", 1.0)   # → WAVE_ACTIVE
	e.emit_signal("encounter_finished", false)
	var s2: Dictionary = d.call("get_snapshot")
	var e_snap: Dictionary = e.call("get_snapshot")
	_ck("signal_loss_returns_grace_rest", int(s2["state"]) == 0 and int(s2["failures"]) == 1 \
			and int(e_snap["grace_rests"]) >= 1,
			"director_state=%s failures=%s encounter_grace_rests=%s（失败回赐福休息真调用）" % [
				str(s2["state_name"]), str(s2["failures"]), str(e_snap["grace_rests"])])
	_free_node(d)
	_free_node(e)


# ---------------------------------------------------------------------------
# H) courtyard.tscn：改动前后节点数比对 + CACHE_MODE_IGNORE 回读
#    （uv 4/2/1、波次 HUD、既有 HUD 文本、instance 覆盖段）
# ---------------------------------------------------------------------------
func _test_courtyard_readback() -> void:
	var ps: PackedScene = ResourceLoader.load(
			COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	_ck("courtyard_scene_loaded", ps != null, "path=%s CACHE_MODE_IGNORE=true" % COURTYARD_PATH)
	if ps == null:
		return
	var disk_nodes: int = ps.get_state().get_node_count()
	print("[V040] NODE_COUNT before=%d after=%d delta=+%d（改前基线来自 R25 登记与 R26 改前 grep 实测）" % [
			NODE_COUNT_BEFORE, disk_nodes, disk_nodes - NODE_COUNT_BEFORE])
	_ck("courtyard_node_count", disk_nodes == NODE_COUNT_AFTER \
			and disk_nodes - NODE_COUNT_BEFORE == NODE_COUNT_DELTA,
			"node_count=%d expected=%d（+%d：R26 三波 HUD/导演 + R27B 增益运行时/购买 HUD）" % [
				disk_nodes, NODE_COUNT_AFTER, NODE_COUNT_DELTA])

	# instantiate 不 add_child → 不触发 _ready，纯结构/属性回读
	var inst: Node = ps.instantiate()
	_ck("courtyard_instantiated", inst != null, "instantiate 不进树、不 flush _ready")

	# 波次 HUD（同层 layer=20，文本四项，位置避开三处既有 HUD）
	var hud_layer: CanvasLayer = inst.get_node_or_null("WaveTrialHud") as CanvasLayer
	var label: Label = inst.get_node_or_null("WaveTrialHud/WaveLabel") as Label
	_ck("wave_hud_present", hud_layer != null and label != null and hud_layer.layer == 20,
			"layer=%s label=%s" % [str(hud_layer.layer if hud_layer != null else -1), str(label != null)])
	var avoids_grace: bool = label != null and label.offset_top >= 220.0
	var avoids_quality: bool = label != null and (label.offset_top >= 180.0 or label.offset_right <= 760.0)
	var avoids_bottom: bool = label != null and label.offset_bottom < 640.0
	_ck("wave_hud_position_safe", avoids_grace and avoids_quality and avoids_bottom,
			"rect=(%s,%s)-(%s,%s) 避开 赐福y<220/画质x>760y<180/底部y≈660" % [
				str(label.offset_left if label != null else -1), str(label.offset_top if label != null else -1),
				str(label.offset_right if label != null else -1), str(label.offset_bottom if label != null else -1)])
	var txt: String = label.text if label != null else ""
	_ck("wave_hud_text_items", txt.contains("波") and txt.contains("赐福点数") \
			and txt.contains("倒计时") and txt.contains("历史最佳"),
			"text=%s" % txt)

	# 三个地面 MeshInstance3D 的 uv1_scale：16/3/2 → 4/2/1（只改这三处属性）
	var tpath: String = "SubViewportContainer/SubViewport/Terrain/"
	var gp: MeshInstance3D = inst.get_node_or_null(tpath + "GroundPlate") as MeshInstance3D
	var tl: MeshInstance3D = inst.get_node_or_null(tpath + "TerraceLow") as MeshInstance3D
	var th: MeshInstance3D = inst.get_node_or_null(tpath + "TerraceHigh") as MeshInstance3D
	var uv_p: Vector3 = _uv_of(gp)
	var uv_l: Vector3 = _uv_of(tl)
	var uv_h: Vector3 = _uv_of(th)
	_ck("uv_groundplate_4", uv_p.is_equal_approx(Vector3(4, 4, 1)), "uv1_scale=%s expected=(4,4,1)" % str(uv_p))
	_ck("uv_terracelow_2", uv_l.is_equal_approx(Vector3(2, 2, 1)), "uv1_scale=%s expected=(2,2,1)" % str(uv_l))
	_ck("uv_terracehigh_1", uv_h.is_equal_approx(Vector3(1, 1, 1)), "uv1_scale=%s expected=(1,1,1)" % str(uv_h))

	# 既有 HUD 文本与 instance 内部属性覆盖段未回退
	var status: Label = inst.find_child("StatusLabel", true, false) as Label
	var title: Label = inst.find_child("TitleLabel", true, false) as Label
	_ck("existing_status_label_unchanged", status != null \
			and status.text == "遭遇战 v0.1.0 载入中…" and status.offset_top == 660.0,
			"text=%s offset_top=%s" % [str(status.text if status != null else "<null>"),
				str(status.offset_top if status != null else -1)])
	_ck("existing_grace_title_unchanged", title != null and title.text == "赐福 · 宁姆格福",
			"text=%s" % str(title.text if title != null else "<null>"))
	var boss: Node = inst.get_node_or_null("EncounterRoot/Boss")
	var sp: String = str(boss.get("sprite_path")) if boss != null else ""
	_ck("instance_override_preserved", boss != null and sp.contains("BossVisual/Hybrid2D3DAnimatedSprite"),
			"sprite_path=%s（pack 丢失覆盖段的坑已用文本精确编辑规避，CACHE_MODE_IGNORE 回读生效）" % sp)

	_free_node(inst)
