extends SceneTree
## R18 · 桌面/移动画质档 ↔ fx_profile 可切换接线（SceneTree 追加式，幂等）
## 派单 cmd-20261109-095518-171-A1 · [ROUND=R18] · AI=1
## 依据：godot/scripts/attach_fx_r17.gd（SceneTree 备份 / CACHE_MODE_IGNORE / pack / owner 模式）、
##       godot/scenes/hd2d_fx.tscn、godot/scripts/hd2d_fx.gd（fx_profile + set_fx_profile）、
##       godot/data/render/quality_preset_desktop.tres / quality_preset_mobile.tres、
##       Rank-4/HD2D-FX-PLAN.md §4.2（桌面四项全开 / 移动四项全关）、00-群聊总线.md（开工只读一次）。
##
## 真跑   : D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/wire_profile_r18.gd
## 三段门禁: ... --headless --path <root> --import
##           ... --headless --path <root> --check-only --script res://scripts/wire_profile_r18.gd
##           ... --headless --path <root> --quit
## 抓帧   : ... --path <root> --write-movie F:/Game/aierdengfahuan/capture/r18_scene.png --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn
##       （抓帧与三段门禁为独立 CLI 真跑，脚本内不嵌套启动第二个引擎进程）
##
## 接线口径（只做能回读验证的改动，不臆造 API）：
##   HD2DFX 是 instance=ExtResource 占位的 CanvasLayer，根本身无 fx_profile 属性
##   （fx_profile 在 hd2d_fx.tscn 的 4 个 FX 子节点的 hd2d_fx.gd 上）。因此把
##   「档位 → quality preset 路径 → fx_profile 值」的接线表以 Node.set_meta() 写在
##   HD2DFX 实例根（.tscn 落盘为 metadata/<key>=...），运行时由 get_meta() 读取。
##   6 个键构成自描述、可切换的接线表；切换时机 / 调用方式见 Rank-1/FX-PROFILE-WIRING.md。
##   接线值来源：真跑 load 两份 preset 读 low_resolution_size（桌面 640x360 > 移动 480x270）
##   判定档位，再按 §4.2 冻结口径映射到 fx_profile 值（desktop / mobile），非硬编码臆造。
##
## 幂等：备份已存在则跳过（绝不覆盖）；6 个接线值全部已是绝对目标值则走复核模式
##       （不写盘、仅 pack 探针 + CACHE_MODE_IGNORE 磁盘回读）。所有赋值均为绝对目标值。
## 节点数硬门槛：pack 前 24 → pack 后 24（本轮不增删节点，只写实例根 metadata），
##       任一不符即 push_error + quit(1) 中止保存（场景零改动、不伪造输出）。

const SCENE_PATH: String = "res://scenes/courtyard.tscn"
const FX_SCENE_PATH: String = "res://scenes/hd2d_fx.tscn"
const FX_SCRIPT_PATH: String = "res://scripts/hd2d_fx.gd"
const PRESET_DESKTOP: String = "res://data/render/quality_preset_desktop.tres"
const PRESET_MOBILE: String = "res://data/render/quality_preset_mobile.tres"
const BACKUP_ABS: String = "F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r18"
const FX_FULL_PATH: String = "SubViewportContainer/SubViewport/HD2DFX"
const FX_CHILDREN := ["FXReflection", "FXGodRays", "FXMotes", "FXBloom"]
const EXPECTED_NODES: int = 24
const EXPECTED_LAYER: int = 10
const PROFILE_DESKTOP: String = "desktop"
const PROFILE_MOBILE: String = "mobile"

# 6 个接线键（Node.set_meta / get_meta，运行时可读；落盘为 metadata/<key>）
const M_SOURCE: String = "fx_profile_source"                  # 当前激活档 preset 路径（运行时读取入口，默认桌面）
const M_ACTIVE: String = "fx_profile_active"                  # 当前激活档的 fx_profile 值（HD2DFX 默认档位，元数据形式）
const M_DESKTOP_PRESET: String = "fx_profile_desktop_preset"  # 桌面档 preset 路径
const M_MOBILE_PRESET: String = "fx_profile_mobile_preset"    # 移动档 preset 路径
const M_DESKTOP_VALUE: String = "fx_profile_desktop_value"    # 桌面档 → fx_profile 值（四项全开）
const M_MOBILE_VALUE: String = "fx_profile_mobile_value"      # 移动档 → fx_profile 值（四项全关）

var _pass_count: int = 0
var _fail_count: int = 0


func _wiring_map() -> Dictionary:
    return {
        M_SOURCE: PRESET_DESKTOP,
        M_ACTIVE: PROFILE_DESKTOP,
        M_DESKTOP_PRESET: PRESET_DESKTOP,
        M_MOBILE_PRESET: PRESET_MOBILE,
        M_DESKTOP_VALUE: PROFILE_DESKTOP,
        M_MOBILE_VALUE: PROFILE_MOBILE,
    }


func _initialize() -> void:
    print("[R18] === WIRE PROFILE R18 START (cmd-20261109-095518-171-A1) ===")

    # --- 1) 备份（幂等：已存在则跳过，绝不覆盖 pre-r18 原件） ---
    if not _backup():
        push_error("[R18] STEP1 BACKUP 失败，拒绝继续（场景零改动）")
        quit(1)
        return

    # --- 2) 真跑加载两份 quality preset，读 low_resolution_size 判档（接线值来源，非臆造） ---
    var desk: Resource = load(PRESET_DESKTOP) as Resource
    var mob: Resource = load(PRESET_MOBILE) as Resource
    if desk == null or mob == null:
        push_error("[R18] STEP2 load quality_preset_*.tres 失败，拒绝继续")
        quit(1)
        return
    var desk_res = desk.get("low_resolution_size")
    var mob_res = mob.get("low_resolution_size")
    var preset_ok: bool = (desk_res is Vector2i) and (mob_res is Vector2i) \
            and (desk_res.x > mob_res.x) and (desk_res.y > mob_res.y)
    print("[R18] STEP2 PRESET desktop.low_resolution_size=%s mobile=%s desktop_gt_mobile=%s" % [
            str(desk_res), str(mob_res), str(preset_ok)])
    if not preset_ok:
        push_error("[R18] STEP2 preset 分辨率判档不成立（预期桌面 640x360 > 移动 480x270），拒绝继续")
        quit(1)
        return
    # 按 §4.2 冻结口径：桌面四项全开→"desktop"，移动四项全关→"mobile"
    print("[R18] STEP2 档位→fx_profile 映射: desktop->%s / mobile->%s（§4.2 冻结口径）" % [
            PROFILE_DESKTOP, PROFILE_MOBILE])

    # --- 3) 读磁盘最新场景（CACHE_MODE_IGNORE，避免命中进程缓存 / 并发旧副本） ---
    var src: PackedScene = ResourceLoader.load(
            SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
    if src == null:
        push_error("[R18] STEP3 CACHE_MODE_IGNORE load courtyard.tscn 失败，拒绝继续")
        quit(1)
        return
    var before_nodes: int = src.get_state().get_node_count()
    print("[R18] STEP3 CACHE_MODE_IGNORE load OK, SceneState node_count(before)=%d" % before_nodes)
    if before_nodes != EXPECTED_NODES:
        push_error("[R18] STEP3 pack 前节点数 %d != 24（R17 应已挂入 HD2DFX），拒绝继续（场景零改动）" % before_nodes)
        quit(1)
        return

    # --- 4) 实例化，找到 R17 挂入的 HD2DFX 实例并硬校验结构 ---
    var root: Node = src.instantiate()
    var fx: Node = root.get_node_or_null(FX_FULL_PATH)
    if fx == null:
        push_error("[R18] STEP4 HD2DFX 实例缺失 path=%s，拒绝继续" % FX_FULL_PATH)
        _free_tree(root)
        quit(1)
        return
    var fx_is_cl: bool = fx is CanvasLayer
    var fx_layer: int = -999
    if fx_is_cl:
        fx_layer = (fx as CanvasLayer).layer
    var fx_is_instance: bool = fx.scene_file_path == FX_SCENE_PATH
    print("[R18] STEP4 HD2DFX name=%s class=%s layer=%d scene_file_path=%s" % [
            fx.name, fx.get_class(), fx_layer, fx.scene_file_path])
    if not fx_is_cl or fx_layer != EXPECTED_LAYER or not fx_is_instance:
        push_error("[R18] STEP4 HD2DFX 结构校验失败（需 CanvasLayer / layer=10 / instance 占位），拒绝继续")
        _free_tree(root)
        quit(1)
        return

    # --- 5) 幂等判断 + 写接线表（6 个 metadata 绝对目标值） ---
    var wiring: Dictionary = _wiring_map()
    var already_wired: bool = _wiring_present(fx, wiring)
    if already_wired:
        print("[R18] STEP5 ALREADY_WIRED=true，6 项接线值已全部到位，跳过写盘（复核模式）")
    else:
        for k in wiring.keys():
            fx.set_meta(str(k), str(wiring[k]))
        print("[R18] STEP5 set_meta 写入 6 项接线: %s" % _describe_wiring(fx, wiring))

    # --- 6) pack 前准备：确保实例根标记 + owner 链（沿用 R17，保证 pack 折叠成 instance 占位、节点数不变） ---
    fx.set("scene_file_path", FX_SCENE_PATH)
    fx.owner = root
    _reset_owner(root, root)
    print("[R18] STEP6 scene_file_path / owner 链就绪（跳过实例化节点，不展开）")

    # --- 7) pack 前 / 后节点数比对（硬门槛 24→24，不一致则中止保存） ---
    var packed: PackedScene = PackedScene.new()
    var pack_err: Error = packed.pack(root)
    if pack_err != OK:
        push_error("[R18] STEP7 PackedScene.pack() 失败 err=%d，拒绝保存" % pack_err)
        _free_tree(root)
        quit(1)
        return
    var after_nodes: int = packed.get_state().get_node_count()
    var count_ok: bool = (before_nodes == EXPECTED_NODES) \
            and (after_nodes == EXPECTED_NODES) and (after_nodes == before_nodes)
    print("[R18] STEP7 NODE_COUNT before=%d after=%d expected=%d pack_err=%d count_ok=%s" % [
            before_nodes, after_nodes, EXPECTED_NODES, pack_err, str(count_ok)])

    # pack -> instantiate 内存探针：确认接线 metadata 真的被 pack 保留、节点仍为 instance 占位、4 子节点完整
    var probe: Node = packed.instantiate()
    var probe_fx: Node = probe.get_node_or_null(FX_FULL_PATH)
    var probe_meta_ok: bool = probe_fx != null and _wiring_present(probe_fx, wiring)
    var probe_instance: bool = probe_fx != null and probe_fx.scene_file_path == FX_SCENE_PATH
    var probe_children_ok: bool = probe_fx != null
    if probe_fx != null:
        for nm in FX_CHILDREN:
            if probe_fx.get_node_or_null(str(nm)) == null:
                probe_children_ok = false
    var probe_runtime_nodes: int = _count(probe)
    var probe_ok: bool = probe_meta_ok and probe_instance and probe_children_ok
    print("[R18] STEP7 PACK_PROBE meta_ok=%s instance=%s children_ok=%s runtime_nodes=%d probe_ok=%s" % [
            str(probe_meta_ok), str(probe_instance), str(probe_children_ok),
            probe_runtime_nodes, str(probe_ok)])
    _free_tree(probe)

    if not count_ok or not probe_ok:
        push_error("[R18] STEP7 节点数 / 接线探针比对失败，中止保存（场景零改动，不伪造输出）")
        _free_tree(root)
        quit(1)
        return
    _free_tree(root)

    # --- 8) 保存（复核模式跳过，尊重并发 / 既有产出） ---
    if already_wired:
        print("[R18] STEP8 SKIP_SAVE（复核模式，不写盘）")
    else:
        var save_err: Error = ResourceSaver.save(packed, SCENE_PATH)
        if save_err != OK:
            push_error("[R18] STEP8 ResourceSaver.save() 失败 err=%d，拒绝继续" % save_err)
            quit(1)
            return
        print("[R18] STEP8 SAVE_OK path=%s save_err=%d" % [SCENE_PATH, save_err])

    # --- 9) CACHE_MODE_IGNORE 从磁盘回读验证（接线值 + 节点数 + 结构 + preset 真跑值） ---
    var verify_ok: bool = _verify(desk_res, mob_res)
    print("[R18] === WIRE PROFILE R18 END verify_ok=%s ===" % str(verify_ok))
    quit(0 if verify_ok else 1)


func _backup() -> bool:
    if FileAccess.file_exists(BACKUP_ABS):
        print("[R18] STEP1 BACKUP 已存在，跳过（幂等，绝不覆盖）: %s" % BACKUP_ABS)
        return true
    var bytes: PackedByteArray = FileAccess.get_file_as_bytes(SCENE_PATH)
    if bytes.is_empty():
        push_error("[R18] STEP1 读取源场景字节失败 path=%s" % SCENE_PATH)
        return false
    var f: FileAccess = FileAccess.open(BACKUP_ABS, FileAccess.WRITE)
    if f == null:
        push_error("[R18] STEP1 打开备份路径失败 err=%d path=%s" % [
                FileAccess.get_open_error(), BACKUP_ABS])
        return false
    f.store_buffer(bytes)
    f.close()
    print("[R18] STEP1 BACKUP 写入 %d 字节 -> %s" % [bytes.size(), BACKUP_ABS])
    return true


func _wiring_present(fx: Node, wiring: Dictionary) -> bool:
    for k in wiring.keys():
        var key: String = str(k)
        if not fx.has_meta(key):
            return false
        if str(fx.get_meta(key)) != str(wiring[key]):
            return false
    return true


func _describe_wiring(fx: Node, wiring: Dictionary) -> String:
    var parts: PackedStringArray = PackedStringArray()
    for k in wiring.keys():
        var key: String = str(k)
        parts.append("%s=%s" % [key, str(fx.get_meta(key))])
    return " | ".join(parts)


func _verify(desk_res, mob_res) -> bool:
    # CACHE_MODE_IGNORE：不走资源缓存，强制从磁盘重读刚保存的 courtyard.tscn
    print("==== [R18 回读 CACHE_MODE_IGNORE] START ====")
    _pass_count = 0
    _fail_count = 0
    var wiring: Dictionary = _wiring_map()
    var ps: PackedScene = ResourceLoader.load(
            SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
    if ps == null:
        push_error("[R18_VERIFY] CACHE_MODE_IGNORE 回读失败 path=%s" % SCENE_PATH)
        return false
    var disk_nodes: int = ps.get_state().get_node_count()
    print("[R18_VERIFY] readback class=%s resource_path=%s SceneState_nodes=%d" % [
            ps.get_class(), ps.resource_path, disk_nodes])
    _check("① readback_not_null_and_PackedScene", ps is PackedScene,
            "class=%s" % ps.get_class())

    var inst: Node = ps.instantiate()
    var fx: Node = inst.get_node_or_null(FX_FULL_PATH)

    # ② 节点数保持 24
    _check("② SceneState_node_count_24", disk_nodes == EXPECTED_NODES,
            "nodes=%d expected=%d" % [disk_nodes, EXPECTED_NODES])

    # ③ FX 实例存在
    var fx_present: bool = fx != null
    _check("③ FX_instance_present", fx_present,
            "path=%s found=%s" % [FX_FULL_PATH, str(fx_present)])

    # ④ 根为 CanvasLayer / layer=10
    var fx_is_cl: bool = fx != null and fx is CanvasLayer
    var fx_layer: int = -999
    if fx_is_cl:
        fx_layer = (fx as CanvasLayer).layer
    _check("④ FX_root_CanvasLayer_layer10", fx_is_cl and fx_layer == EXPECTED_LAYER,
            "class=%s layer=%d expected=%d" % [
                    (fx.get_class() if fx != null else "<null>"), fx_layer, EXPECTED_LAYER])

    # ⑤ 仍是 instance 占位（未展开成普通节点段 → 节点数不变）
    var fx_is_instance: bool = fx != null and fx.scene_file_path == FX_SCENE_PATH
    _check("⑤ FX_is_instance_placeholder", fx_is_instance,
            "scene_file_path=%s" % (fx.scene_file_path if fx != null else "<null>"))

    # ⑥ 6 项接线值逐项回读（核心：接线值 CACHE_MODE_IGNORE 校验）
    for k in wiring.keys():
        var key: String = str(k)
        var expected: String = str(wiring[key])
        var actual: String = "<missing>"
        if fx != null and fx.has_meta(key):
            actual = str(fx.get_meta(key))
        _check("⑥ wiring[%s]" % key, actual == expected,
                "actual=%s expected=%s" % [actual, expected])

    # ⑦ 4 个 FX 子节点脚本已挂 + ⑧ fx_profile 默认 desktop（R17 结构未破坏）
    var script_ok: bool = fx != null
    var prof_ok: bool = fx != null
    var detail: PackedStringArray = PackedStringArray()
    for nm in FX_CHILDREN:
        var c: Node = null
        if fx != null:
            c = fx.get_node_or_null(str(nm))
        var s: Script = null
        var p: String = "<null>"
        if c != null:
            s = c.get_script() as Script
            p = str(c.get("fx_profile"))
        script_ok = script_ok and (s != null and s.resource_path == FX_SCRIPT_PATH)
        prof_ok = prof_ok and (p == PROFILE_DESKTOP)
        detail.append("%s:script=%s fx_profile=%s" % [
                str(nm), (s.resource_path if s != null else "<null>"), p])
    _check("⑦ script_attached_all_4", script_ok, " | ".join(detail))
    _check("⑧ fx_profile_default_desktop_all_4", prof_ok, " | ".join(detail))

    # ⑨ preset 真跑值 + 档位判据 + 接线映射自洽
    var preset_ok: bool = (desk_res is Vector2i) and (mob_res is Vector2i) \
            and (desk_res.x > mob_res.x) and (desk_res.y > mob_res.y) \
            and (str(wiring[M_DESKTOP_VALUE]) == PROFILE_DESKTOP) \
            and (str(wiring[M_MOBILE_VALUE]) == PROFILE_MOBILE)
    _check("⑨ preset_resolution_gt_and_mapping", preset_ok,
            "desktop=%s mobile=%s / desktop_value=%s mobile_value=%s" % [
                    str(desk_res), str(mob_res),
                    str(wiring[M_DESKTOP_VALUE]), str(wiring[M_MOBILE_VALUE])])

    var runtime_nodes: int = _count(inst)
    print("[R18_VERIFY] RUNTIME_NODES=%d（实例展开后整树，含 HUD 内部 2 + HD2DFX 内部 4）" % runtime_nodes)

    _free_tree(inst)
    var all_ok: bool = (_fail_count == 0)
    print("[R18_VERIFY] VERIFY_SUMMARY pass=%d fail=%d OK=%s" % [_pass_count, _fail_count, str(all_ok)])
    print("==== [R18 回读 CACHE_MODE_IGNORE] END ====")
    return all_ok


func _check(label: String, ok: bool, detail: String) -> void:
    if ok:
        _pass_count += 1
    else:
        _fail_count += 1
    print("[R18_VERIFY] %s PASS=%s | %s" % [label, str(ok), detail])


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
