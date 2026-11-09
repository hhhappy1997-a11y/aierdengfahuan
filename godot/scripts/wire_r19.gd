extends SceneTree
## R19 · 把 R18「接线元数据」升级为「运行期可切换」：给 HD2DFX 实例根挂控制器脚本
## 派单 cmd-20261109-102334-086-A1 · [ROUND=R19] · AI=1（Rank-1）
## 依据：wire_profile_r18.gd（SceneTree 备份 / CACHE_MODE_IGNORE / pack / owner 模式）、
##       attach_fx_r17.gd（instance 占位 / owner 链 / pack 折叠）、
##       courtyard.tscn 的 Hud 段（instance 根 + script 覆盖共存的现成范例）、
##       hd2d_fx.gd（set_fx_profile 公共入口）、quality_preset_*.tres、00-群聊总线.md（开工只读一次）。
##
## 真跑   : D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/wire_r19.gd
## 三段门禁: ... --headless --path <root> --import
##           ... --headless --path <root> --check-only --script res://scripts/fx_profile_controller.gd
##           ... --headless --path <root> --quit
## 抓帧   : ... --path <root> --write-movie F:/Game/aierdengfahuan/capture/r19_scene.png --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn
##       （抓帧与三段门禁为独立 CLI 真跑，脚本内不嵌套启动第二个引擎进程）
##
## 幂等：备份已存在则跳过（绝不覆盖 pre-r19 原件）；HD2DFX 已挂 controller 脚本 → 复核模式
##       （不写盘、仅 pack 探针 + CACHE_MODE_IGNORE 磁盘回读）。所有赋值均为绝对目标值。
## 节点数硬门槛：pack 前 24 → pack 后 24（只给实例根加 script 属性覆盖，不增删节点），
##       任一不符即 push_error + quit(1) 中止保存（场景零改动、不伪造输出）。

const SCENE_PATH: String = "res://scenes/courtyard.tscn"
const FX_SCENE_PATH: String = "res://scenes/hd2d_fx.tscn"
const FX_SCRIPT_PATH: String = "res://scripts/hd2d_fx.gd"
const CONTROLLER_PATH: String = "res://scripts/fx_profile_controller.gd"
const PRESET_DESKTOP: String = "res://data/render/quality_preset_desktop.tres"
const PRESET_MOBILE: String = "res://data/render/quality_preset_mobile.tres"
const BACKUP_ABS: String = "F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r19"
const FX_FULL_PATH: String = "SubViewportContainer/SubViewport/HD2DFX"
const FX_CHILDREN := ["FXReflection", "FXGodRays", "FXMotes", "FXBloom"]
const EXPECTED_NODES: int = 24
const EXPECTED_LAYER: int = 10
const PROFILE_DESKTOP: String = "desktop"
const PROFILE_MOBILE: String = "mobile"

var _pass_count: int = 0
var _fail_count: int = 0


func _wiring_map() -> Dictionary:
    return {
        "fx_profile_source": PRESET_DESKTOP,
        "fx_profile_active": PROFILE_DESKTOP,
        "fx_profile_desktop_preset": PRESET_DESKTOP,
        "fx_profile_mobile_preset": PRESET_MOBILE,
        "fx_profile_desktop_value": PROFILE_DESKTOP,
        "fx_profile_mobile_value": PROFILE_MOBILE,
    }


func _initialize() -> void:
    print("[R19] === WIRE R19 START (cmd-20261109-102334-086-A1) ===")

    # --- 1) 备份（幂等：已存在则跳过，绝不覆盖 pre-r19 原件） ---
    if not _backup():
        push_error("[R19] STEP1 BACKUP 失败，拒绝继续（场景零改动）")
        quit(1)
        return

    # --- 2) 预检 controller 脚本可加载；真跑 load 两份 preset 读 low_resolution_size 佐证判档口径 ---
    var ctrl: Script = load(CONTROLLER_PATH) as Script
    if ctrl == null:
        push_error("[R19] STEP2 load %s 失败，拒绝继续" % CONTROLLER_PATH)
        quit(1)
        return
    print("[R19] STEP2 controller load OK path=%s class=%s" % [ctrl.resource_path, ctrl.get_class()])
    var desk: Resource = load(PRESET_DESKTOP) as Resource
    var mob: Resource = load(PRESET_MOBILE) as Resource
    var desk_res = desk.get("low_resolution_size") if desk != null else null
    var mob_res = mob.get("low_resolution_size") if mob != null else null
    var preset_ok: bool = (desk_res is Vector2i) and (mob_res is Vector2i) \
            and (desk_res.x > mob_res.x) and (desk_res.y > mob_res.y)
    print("[R19] STEP2 PRESET desktop.low_resolution_size=%s mobile=%s desktop_gt_mobile=%s" % [
            str(desk_res), str(mob_res), str(preset_ok)])
    if not preset_ok:
        push_error("[R19] STEP2 preset 分辨率判档不成立，拒绝继续")
        quit(1)
        return

    # --- 3) 读磁盘最新场景（CACHE_MODE_IGNORE，避免命中进程缓存 / 并发旧副本） ---
    var src: PackedScene = ResourceLoader.load(
            SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
    if src == null:
        push_error("[R19] STEP3 CACHE_MODE_IGNORE load courtyard.tscn 失败，拒绝继续")
        quit(1)
        return
    var before_nodes: int = src.get_state().get_node_count()
    print("[R19] STEP3 CACHE_MODE_IGNORE load OK, SceneState node_count(before)=%d" % before_nodes)
    if before_nodes != EXPECTED_NODES:
        push_error("[R19] STEP3 pack 前节点数 %d != 24，拒绝继续（场景零改动）" % before_nodes)
        quit(1)
        return

    # --- 4) 实例化，找到 R17 挂入的 HD2DFX 实例并硬校验结构 ---
    var scene_root: Node = src.instantiate()
    var fx: Node = scene_root.get_node_or_null(FX_FULL_PATH)
    if fx == null:
        push_error("[R19] STEP4 HD2DFX 实例缺失 path=%s，拒绝继续" % FX_FULL_PATH)
        _free_tree(scene_root)
        quit(1)
        return
    var fx_is_cl: bool = fx is CanvasLayer
    var fx_layer: int = -999
    if fx_is_cl:
        fx_layer = (fx as CanvasLayer).layer
    var fx_is_instance: bool = fx.scene_file_path == FX_SCENE_PATH
    print("[R19] STEP4 HD2DFX name=%s class=%s layer=%d scene_file_path=%s" % [
            fx.name, fx.get_class(), fx_layer, fx.scene_file_path])
    if not fx_is_cl or fx_layer != EXPECTED_LAYER or not fx_is_instance:
        push_error("[R19] STEP4 HD2DFX 结构校验失败（需 CanvasLayer / layer=10 / instance 占位），拒绝继续")
        _free_tree(scene_root)
        quit(1)
        return

    # --- 5) 幂等判断 + 给 HD2DFX 实例根挂 controller 脚本（set_script / script 属性覆盖） ---
    var prev: Script = fx.get_script() as Script
    var already: bool = prev != null and prev.resource_path == CONTROLLER_PATH
    if already:
        print("[R19] STEP5 ALREADY_ATTACHED=true，controller 已挂载，跳过写盘（复核模式）")
    else:
        fx.set_script(ctrl)
        print("[R19] STEP5 set_script(controller) 写入脚本属性覆盖 path=%s" % CONTROLLER_PATH)
    var attached: Script = fx.get_script() as Script
    var attach_ok: bool = attached != null and attached.resource_path == CONTROLLER_PATH
    print("[R19] STEP5 get_script()=%s attach_ok=%s" % [
            (attached.resource_path if attached != null else "<null>"), str(attach_ok)])
    if not attach_ok:
        push_error("[R19] STEP5 controller 脚本挂载回读失败，拒绝继续")
        _free_tree(scene_root)
        quit(1)
        return

    # --- 6) pack 前准备：实例根标记 + owner 链（沿用 R18，保证折叠成 instance 占位、节点数不变） ---
    fx.set("scene_file_path", FX_SCENE_PATH)
    fx.owner = scene_root
    _reset_owner(scene_root, scene_root)
    print("[R19] STEP6 scene_file_path / owner 链就绪（跳过实例化节点，不展开）")

    # --- 7) pack 前 / 后节点数比对（硬门槛 24→24，不一致则中止保存） ---
    var packed: PackedScene = PackedScene.new()
    var pack_err: Error = packed.pack(scene_root)
    if pack_err != OK:
        push_error("[R19] STEP7 PackedScene.pack() 失败 err=%d，拒绝保存" % pack_err)
        _free_tree(scene_root)
        quit(1)
        return
    var after_nodes: int = packed.get_state().get_node_count()
    var count_ok: bool = (before_nodes == EXPECTED_NODES) \
            and (after_nodes == EXPECTED_NODES) and (after_nodes == before_nodes)
    print("[R19] STEP7 NODE_COUNT before=%d after=%d expected=%d pack_err=%d count_ok=%s" % [
            before_nodes, after_nodes, EXPECTED_NODES, pack_err, str(count_ok)])

    # pack -> instantiate 内存探针：脚本覆盖真的被 pack 保留、节点仍 instance 占位、4 子节点完整
    var probe: Node = packed.instantiate()
    var pfx: Node = probe.get_node_or_null(FX_FULL_PATH)
    var pscript: Script = null
    if pfx != null:
        pscript = pfx.get_script() as Script
    var probe_script_ok: bool = pscript != null and pscript.resource_path == CONTROLLER_PATH
    var probe_instance: bool = pfx != null and pfx.scene_file_path == FX_SCENE_PATH
    var probe_children_ok: bool = pfx != null
    if pfx != null:
        for nm in FX_CHILDREN:
            if pfx.get_node_or_null(str(nm)) == null:
                probe_children_ok = false
    var probe_runtime_nodes: int = _count(probe)
    var probe_ok: bool = probe_script_ok and probe_instance and probe_children_ok
    print("[R19] STEP7 PACK_PROBE script_ok=%s instance=%s children_ok=%s runtime_nodes=%d probe_ok=%s" % [
            str(probe_script_ok), str(probe_instance), str(probe_children_ok),
            probe_runtime_nodes, str(probe_ok)])
    _free_tree(probe)

    if not count_ok or not probe_ok:
        push_error("[R19] STEP7 节点数 / 脚本探针比对失败，中止保存（场景零改动，不伪造输出）")
        _free_tree(scene_root)
        quit(1)
        return
    _free_tree(scene_root)

    # --- 8) 保存（复核模式跳过，尊重并发 / 既有产出） ---
    if already:
        print("[R19] STEP8 SKIP_SAVE（复核模式，不写盘）")
    else:
        var save_err: Error = ResourceSaver.save(packed, SCENE_PATH)
        if save_err != OK:
            push_error("[R19] STEP8 ResourceSaver.save() 失败 err=%d，拒绝继续" % save_err)
            quit(1)
            return
        print("[R19] STEP8 SAVE_OK path=%s save_err=%d" % [SCENE_PATH, save_err])

    # --- 9) CACHE_MODE_IGNORE 从磁盘回读验证（脚本已挂 + 档位可切换 + 接线表仍在 + 节点数） ---
    var verify_ok: bool = _verify()
    print("[R19] === WIRE R19 END verify_ok=%s ===" % str(verify_ok))
    quit(0 if verify_ok else 1)


func _backup() -> bool:
    if FileAccess.file_exists(BACKUP_ABS):
        print("[R19] STEP1 BACKUP 已存在，跳过（幂等，绝不覆盖）: %s" % BACKUP_ABS)
        return true
    var bytes: PackedByteArray = FileAccess.get_file_as_bytes(SCENE_PATH)
    if bytes.is_empty():
        push_error("[R19] STEP1 读取源场景字节失败 path=%s" % SCENE_PATH)
        return false
    var f: FileAccess = FileAccess.open(BACKUP_ABS, FileAccess.WRITE)
    if f == null:
        push_error("[R19] STEP1 打开备份路径失败 err=%d path=%s" % [
                FileAccess.get_open_error(), BACKUP_ABS])
        return false
    f.store_buffer(bytes)
    f.close()
    print("[R19] STEP1 BACKUP 写入 %d 字节 -> %s" % [bytes.size(), BACKUP_ABS])
    return true


func _verify() -> bool:
    # CACHE_MODE_IGNORE：不走资源缓存，强制从磁盘重读刚保存的 courtyard.tscn
    print("==== [R19 回读 CACHE_MODE_IGNORE] START ====")
    _pass_count = 0
    _fail_count = 0
    var ps: PackedScene = ResourceLoader.load(
            SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
    if ps == null:
        push_error("[R19_VERIFY] CACHE_MODE_IGNORE 回读失败 path=%s" % SCENE_PATH)
        return false
    var disk_nodes: int = ps.get_state().get_node_count()
    print("[R19_VERIFY] readback class=%s resource_path=%s SceneState_nodes=%d" % [
            ps.get_class(), ps.resource_path, disk_nodes])
    _check("① readback_not_null_and_PackedScene", ps is PackedScene, "class=%s" % ps.get_class())
    _check("② SceneState_node_count_24", disk_nodes == EXPECTED_NODES,
            "nodes=%d expected=%d" % [disk_nodes, EXPECTED_NODES])

    var inst: Node = ps.instantiate()
    var fx: Node = inst.get_node_or_null(FX_FULL_PATH)

    # ③ FX 实例存在
    _check("③ FX_instance_present", fx != null,
            "path=%s found=%s" % [FX_FULL_PATH, str(fx != null)])

    # ④ 根为 CanvasLayer / layer=10
    var is_cl: bool = fx != null and fx is CanvasLayer
    var layer: int = -999
    if is_cl:
        layer = (fx as CanvasLayer).layer
    _check("④ FX_root_CanvasLayer_layer10", is_cl and layer == EXPECTED_LAYER,
            "class=%s layer=%d expected=%d" % [
                    (fx.get_class() if fx != null else "<null>"), layer, EXPECTED_LAYER])

    # ⑤ 仍是 instance 占位（未展开成普通节点段 → 节点数不变）
    var is_inst: bool = fx != null and fx.scene_file_path == FX_SCENE_PATH
    _check("⑤ FX_is_instance_placeholder", is_inst,
            "scene_file_path=%s" % (fx.scene_file_path if fx != null else "<null>"))

    # ⑥ controller 脚本已挂（核心：运行期可切换的前提）
    var s: Script = null
    if fx != null:
        s = fx.get_script() as Script
    var script_ok: bool = s != null and s.resource_path == CONTROLLER_PATH
    _check("⑥ controller_script_attached", script_ok,
            "script=%s expected=%s" % [
                    (s.resource_path if s != null else "<null>"), CONTROLLER_PATH])

    # ⑦ switch_profile 公共入口可用
    var method_ok: bool = fx != null and fx.has_method("switch_profile")
    _check("⑦ switch_profile_method_available", method_ok,
            "has_method=%s" % str(method_ok))

    # ⑧ R18 6 项接线表仍在（运行期切换的判档数据源未破坏）
    var wiring: Dictionary = _wiring_map()
    for k in wiring.keys():
        var key: String = str(k)
        var expected: String = str(wiring[key])
        var actual: String = "<missing>"
        if fx != null and fx.has_meta(key):
            actual = str(fx.get_meta(key))
        _check("⑧ wiring[%s]" % key, actual == expected,
                "actual=%s expected=%s" % [actual, expected])

    # ⑨ 4 个 FX 子节点脚本仍是 hd2d_fx.gd（既有件未重做 / 未破坏）
    var script4_ok: bool = fx != null
    var script4_detail: PackedStringArray = PackedStringArray()
    for nm in FX_CHILDREN:
        var c: Node = null
        if fx != null:
            c = fx.get_node_or_null(str(nm))
        var cs: Script = null
        if c != null:
            cs = c.get_script() as Script
        script4_ok = script4_ok and (cs != null and cs.resource_path == FX_SCRIPT_PATH)
        script4_detail.append("%s:script=%s" % [str(nm), (cs.resource_path if cs != null else "<null>")])
    _check("⑨ child_script_hd2d_fx_all_4", script4_ok, " | ".join(script4_detail))

    # ===== 运行期档位可切换：直接真跑 controller 的 _ready() 判档 + switch_profile 两档。
    #   不把任何节点加入 SceneTree.root，避免与 autoload ChunkManager 的异步 chunk 加载
    #   交互：其 deferred _bootstrap 用 find_child("ChunkRoot") 绑定 _chunk_root，若绑定到
    #   临时验证场景、释放后 _finish_load 会对已释放实例 add_child（两次实测均产生 ERROR，
    #   见 r19_wire_run_first/second_attempt.log）。_ready() / switch_profile() 均为普通方法，
    #   fx.call() 即可真跑其判档/切档逻辑；引擎在抓帧等真实运行场景时会自动调用 _ready()
    #   （见 capture/r19_capture.log 的 [R19_CTRL] 打印佐证）。=====
    if fx != null:
        fx.call("_ready")   # 真跑启动判档：读 preset.low_resolution_size → 切 desktop
        var p0: Array = _read_profiles(fx)
        _check("⑩ _ready 自动判档 desktop 4/4 四项全开",
                _profiles_match(p0, PROFILE_DESKTOP, true), _fmt_profiles("after_ready", p0))
        fx.call("switch_profile", PROFILE_MOBILE)
        var pm: Array = _read_profiles(fx)
        _check("⑪ switch_profile(mobile) 4/4 四项全关",
                _profiles_match(pm, PROFILE_MOBILE, false), _fmt_profiles("mobile", pm))
        fx.call("switch_profile", PROFILE_DESKTOP)
        var pd: Array = _read_profiles(fx)
        _check("⑫ switch_profile(desktop) 4/4 四项全开",
                _profiles_match(pd, PROFILE_DESKTOP, true), _fmt_profiles("desktop", pd))
    else:
        _check("⑩ _ready 自动判档 desktop 4/4 四项全开", false, "FX 缺失，跳过")
        _check("⑪ switch_profile(mobile) 4/4 四项全关", false, "FX 缺失，跳过")
        _check("⑫ switch_profile(desktop) 4/4 四项全开", false, "FX 缺失，跳过")

    _free_tree(inst)
    var all_ok: bool = (_fail_count == 0)
    print("[R19_VERIFY] VERIFY_SUMMARY pass=%d fail=%d OK=%s" % [_pass_count, _fail_count, str(all_ok)])
    print("==== [R19 回读 CACHE_MODE_IGNORE] END ====")
    return all_ok


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


func _check(label: String, ok: bool, detail: String) -> void:
    if ok:
        _pass_count += 1
    else:
        _fail_count += 1
    print("[R19_VERIFY] %s PASS=%s | %s" % [label, str(ok), detail])


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
