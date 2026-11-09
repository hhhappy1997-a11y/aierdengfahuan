extends SceneTree
## R20 · Rank-1 回归验证件（补真跑缺口，写入 Rank-1 目录，不改并发实例既写的 4 个工程件）
## 派单 cmd-20261109-110237-775-A1 · [ROUND=R20] · AI=1（Rank-1）
## 真跑: D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path <root> \
##        --script F:/Game/aierdengfahuan/teamwork/Rank-1/verify_r20.gd
##
## 背景: wire_r19.gd 冻结 EXPECTED_NODES=24（R19 口径）。本轮 ③ 把 quality_settings.tscn
##       实例化进 courtyard.tscn 后，节点数如实为 25（不冒充 24）。本件逐字复现
##       wire_r19.gd 的 17 项 VERIFY 逻辑，仅把节点数期望按 R20 实际值 25 更新，
##       证明 fx_profile_controller.gd 的 R20 追加式扩展「不破坏 R19 的 17 PASS」；
##       另增 R20 重判链路真跑项（set_quality low→high + controller.re_evaluate）。
## 不入树: 沿用 wire_r19.gd 最终修正的教训 —— 不把实例加进 SceneTree.root，避免 autoload
##         ChunkManager 的异步 _finish_load 对已释放 ChunkRoot add_child 产生 SCRIPT ERROR；
##         _ready / switch_profile / re_evaluate / set_quality 均为普通方法，用 call() 真跑。
## 边界: 只读回读，不改任何场景/脚本；零付费 / 零外部依赖 / 中文 UTF-8 / Godot 4.7.2 合法语法。

const SCENE_PATH := "res://scenes/courtyard.tscn"
const FX_SCENE_PATH := "res://scenes/hd2d_fx.tscn"
const FX_SCRIPT_PATH := "res://scripts/hd2d_fx.gd"
const CONTROLLER_PATH := "res://scripts/fx_profile_controller.gd"
const QS_SCRIPT_PATH := "res://scripts/quality_settings.gd"
const PRESET_DESKTOP := "res://data/render/quality_preset_desktop.tres"
const PRESET_MOBILE := "res://data/render/quality_preset_mobile.tres"
const FX_FULL_PATH := "SubViewportContainer/SubViewport/HD2DFX"
const QS_NAME := "QualitySettings"
const FX_CHILDREN := ["FXReflection", "FXGodRays", "FXMotes", "FXBloom"]
const EXPECTED_NODES_R20 := 25
const EXPECTED_LAYER := 10
const PROFILE_DESKTOP := "desktop"
const PROFILE_MOBILE := "mobile"

var _compat_pass := 0
var _compat_fail := 0
var _pass := 0
var _fail := 0


func _initialize() -> void:
    print("[R20_VERIFY] === R20 回归验证 START (cmd-20261109-110237-775-A1) ===")
    var ps: PackedScene = ResourceLoader.load(
            SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
    if ps == null:
        push_error("[R20_VERIFY] CACHE_MODE_IGNORE 回读 courtyard.tscn 失败")
        quit(1)
        return
    var disk_nodes: int = ps.get_state().get_node_count()
    print("[R20_VERIFY] readback class=%s resource_path=%s SceneState_nodes=%d (R20 实际，非 24)" % [
            ps.get_class(), ps.resource_path, disk_nodes])

    var inst: Node = ps.instantiate()
    var fx: Node = inst.get_node_or_null(FX_FULL_PATH)
    var qs: Node = inst.get_node_or_null(QS_NAME)

    # ===== ① ~ ⑫：逐字复现 wire_r19.gd 的 17 项 VERIFY（节点数期望按 R20=25 如实更新）=====
    _compat("① readback_not_null_and_PackedScene", ps is PackedScene, "class=%s" % ps.get_class())
    _compat("② SceneState_node_count (R20=25 如实登记)", disk_nodes == EXPECTED_NODES_R20,
            "nodes=%d expected=%d" % [disk_nodes, EXPECTED_NODES_R20])
    _compat("③ FX_instance_present", fx != null,
            "path=%s found=%s" % [FX_FULL_PATH, str(fx != null)])
    var is_cl: bool = fx != null and fx is CanvasLayer
    var layer: int = -999
    if is_cl:
        layer = (fx as CanvasLayer).layer
    _compat("④ FX_root_CanvasLayer_layer10", is_cl and layer == EXPECTED_LAYER,
            "class=%s layer=%d expected=%d" % [
                    (fx.get_class() if fx != null else "<null>"), layer, EXPECTED_LAYER])
    var is_inst: bool = fx != null and fx.scene_file_path == FX_SCENE_PATH
    _compat("⑤ FX_is_instance_placeholder", is_inst,
            "scene_file_path=%s" % (fx.scene_file_path if fx != null else "<null>"))
    var s: Script = null
    if fx != null:
        s = fx.get_script() as Script
    _compat("⑥ controller_script_attached", s != null and s.resource_path == CONTROLLER_PATH,
            "script=%s expected=%s" % [
                    (s.resource_path if s != null else "<null>"), CONTROLLER_PATH])
    var method_ok: bool = fx != null and fx.has_method("switch_profile")
    _compat("⑦ switch_profile_method_available", method_ok, "has_method=%s" % str(method_ok))
    var wiring := {
        "fx_profile_source": PRESET_DESKTOP,
        "fx_profile_active": PROFILE_DESKTOP,
        "fx_profile_desktop_preset": PRESET_DESKTOP,
        "fx_profile_mobile_preset": PRESET_MOBILE,
        "fx_profile_desktop_value": PROFILE_DESKTOP,
        "fx_profile_mobile_value": PROFILE_MOBILE,
    }
    for k in wiring.keys():
        var key := str(k)
        var expected := str(wiring[key])
        var actual := "<missing>"
        if fx != null and fx.has_meta(key):
            actual = str(fx.get_meta(key))
        _compat("⑧ wiring[%s]" % key, actual == expected,
                "actual=%s expected=%s" % [actual, expected])
    var script4_ok: bool = fx != null
    var detail4: PackedStringArray = PackedStringArray()
    for nm in FX_CHILDREN:
        var c: Node = null
        if fx != null:
            c = fx.get_node_or_null(str(nm))
        var cs: Script = null
        if c != null:
            cs = c.get_script() as Script
        script4_ok = script4_ok and (cs != null and cs.resource_path == FX_SCRIPT_PATH)
        detail4.append("%s:script=%s" % [str(nm), (cs.resource_path if cs != null else "<null>")])
    _compat("⑨ child_script_hd2d_fx_all_4", script4_ok, " | ".join(detail4))

    # ⑩⑪⑫：真跑 controller 的 _ready / switch_profile（不进树，沿用 wire_r19.gd 最终修正）
    if fx != null:
        fx.call("_ready")
        var p0 := _read_profiles(fx)
        _compat("⑩ _ready 自动判档 desktop 4/4 四项全开",
                _profiles_match(p0, PROFILE_DESKTOP, true), _fmt_profiles("after_ready", p0))
        fx.call("switch_profile", PROFILE_MOBILE)
        var pm := _read_profiles(fx)
        _compat("⑪ switch_profile(mobile) 4/4 四项全关",
                _profiles_match(pm, PROFILE_MOBILE, false), _fmt_profiles("mobile", pm))
        fx.call("switch_profile", PROFILE_DESKTOP)
        var pd := _read_profiles(fx)
        _compat("⑫ switch_profile(desktop) 4/4 四项全开",
                _profiles_match(pd, PROFILE_DESKTOP, true), _fmt_profiles("desktop", pd))
    else:
        _compat("⑩ _ready 自动判档 desktop 4/4 四项全开", false, "FX 缺失")
        _compat("⑪ switch_profile(mobile) 4/4 四项全关", false, "FX 缺失")
        _compat("⑫ switch_profile(desktop) 4/4 四项全开", false, "FX 缺失")

    print("[R20_VERIFY] ---- R19_COMPAT (17 项；节点数项按 R20 实际 25 如实更新，不冒充 24) ----")
    print("[R20_VERIFY] VERIFY_SUMMARY_R19_COMPAT pass=%d fail=%d OK=%s" % [
            _compat_pass, _compat_fail, str(_compat_fail == 0)])

    # ===== R20 新增验证项 =====
    print("[R20_VERIFY] ---- R20 重判链路 ----")
    _check("R20-① QualitySettings 节点已实例化进 courtyard", qs != null,
            "path=%s found=%s" % [QS_NAME, str(qs != null)])
    var qss: Script = null
    if qs != null:
        qss = qs.get_script() as Script
    _check("R20-② quality_settings.gd 脚本已挂", qss != null and qss.resource_path == QS_SCRIPT_PATH,
            "script=%s expected=%s" % [
                    (qss.resource_path if qss != null else "<null>"), QS_SCRIPT_PATH])
    var api_ok: bool = qs != null and qs.has_method("set_quality") and qs.has_method("apply") \
            and qs.has_method("get_quality_preset")
    _check("R20-③ set_quality/apply/get_quality_preset 三方法可用", api_ok,
            "has_all=%s" % str(api_ok))
    var ctrl_api: bool = fx != null and fx.has_method("register_quality_provider") \
            and fx.has_method("re_evaluate")
    _check("R20-④ controller 新增 register_quality_provider/re_evaluate", ctrl_api,
            "has_all=%s" % str(ctrl_api))
    var presets: Dictionary = {}
    if qs != null:
        var pv = qs.get("PRESETS")
        if pv is Dictionary:
            presets = pv
    var has3: bool = presets.has("low") and presets.has("medium") and presets.has("high")
    _check("R20-⑤ 三档 low/medium/high 齐备", has3, "keys=%s" % str(presets.keys()))

    # 手动建 provider（实例不入树，get_tree() 为 null，故绕过 quality_settings._ready 的查找；
    # 引擎真实加载场景时 group/find_child 查找由抓帧 stdout 的 [R20_CTRL] 佐证）
    if fx != null and qs != null and ctrl_api:
        fx.call("register_quality_provider", qs)
        qs.call("set_quality", "low")
        fx.call("re_evaluate")
        var pl := _read_profiles(fx)
        _check("R20-⑥ re_evaluate(low) -> mobile 四项全关",
                _profiles_match(pl, PROFILE_MOBILE, false), _fmt_profiles("re_low", pl))
        qs.call("set_quality", "high")
        fx.call("re_evaluate")
        var ph := _read_profiles(fx)
        _check("R20-⑦ re_evaluate(high) -> desktop 四项全开 (low→high 重判)",
                _profiles_match(ph, PROFILE_DESKTOP, true), _fmt_profiles("re_high", ph))
        var preset_now: String = str(qs.call("get_quality_preset"))
        _check("R20-⑧ provider 当前档=high（重判终态）", preset_now == "high",
                "get_quality_preset=%s" % preset_now)
    else:
        _check("R20-⑥ re_evaluate(low) -> mobile 四项全关", false, "节点/API 缺失")
        _check("R20-⑦ re_evaluate(high) -> desktop 四项全开 (low→high 重判)", false, "节点/API 缺失")
        _check("R20-⑧ provider 当前档=high（重判终态）", false, "节点/API 缺失")

    _free_tree(inst)
    print("[R20_VERIFY] VERIFY_SUMMARY_R20 pass=%d fail=%d OK=%s" % [
            _pass, _fail, str(_fail == 0)])
    print("[R20_VERIFY] VERIFY_SUMMARY_TOTAL compat=%d/%d r20=%d/%d" % [
            _compat_pass, _compat_pass + _compat_fail, _pass, _pass + _fail])
    print("[R20_VERIFY] === R20 回归验证 END ===")
    quit(0 if (_compat_fail == 0 and _fail == 0) else 1)


func _compat(label: String, ok: bool, detail: String) -> void:
    if ok:
        _compat_pass += 1
    else:
        _compat_fail += 1
    print("[R20_COMPAT] %s PASS=%s | %s" % [label, str(ok), detail])


func _check(label: String, ok: bool, detail: String) -> void:
    if ok:
        _pass += 1
    else:
        _fail += 1
    print("[R20_VERIFY] %s PASS=%s | %s" % [label, str(ok), detail])


func _read_profiles(fx: Node) -> Array:
    var out: Array = []
    for nm in FX_CHILDREN:
        var c: Node = fx.get_node_or_null(str(nm))
        if c == null:
            continue
        out.append({
            "name": str(nm),
            "p": str(c.get("fx_profile")),
            "v": bool(c.get("visible")),
            "on": bool(c.get("_all_on")),
        })
    return out


func _profiles_match(arr: Array, profile: String, on: bool) -> bool:
    if arr.size() != FX_CHILDREN.size():
        return false
    for d in arr:
        if str(d["p"]) != profile or bool(d["v"]) != on or bool(d["on"]) != on:
            return false
    return true


func _fmt_profiles(tag: String, arr: Array) -> String:
    var parts: PackedStringArray = PackedStringArray()
    for d in arr:
        parts.append("%s:fx_profile=%s visible=%s _all_on=%s" % [
                str(d["name"]), str(d["p"]), str(d["v"]), str(d["on"])])
    return "[%s] %s" % [tag, " | ".join(parts)]


func _free_tree(node: Node) -> void:
    for child in node.get_children():
        _free_tree(child)
    node.free()
