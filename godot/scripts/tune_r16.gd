extends SceneTree
## R16 · 构图 / UV 分档调优（Rank-1 引擎架构与渲染，幂等 SceneTree 脚本）
## 派单 cmd-20261109-085736-022-A1 · [ROUND=R16] · AI=1
## 依据：capture/r15*.png 暴露的问题（砖块铺满画面 / 透视与天空被压 / 角色偏小）、
##       Rank-4/GROUND-MATERIAL.md §4 / §5（三档 uv1_scale 16/3/2、四项成组属性）、
##       tune_visual.gd / tune_env.gd / assemble_r15.gd（SceneTree pack / owner 重设 /
##       CACHE_MODE_IGNORE 磁盘回读模式）。
##
## 串行 ①~⑤ 在本脚本内完成；⑥ 抓帧与 ⑦ 三段门禁为独立 CLI 真跑
## （SceneTree 脚本内不嵌套启动第二个引擎进程；命令见下，实际 stdout 见 DONE-R16.md）：
##   真跑 : D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/tune_r16.gd
##   ⑥   : D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot --write-movie F:/Game/aierdengfahuan/capture/r16.png --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn
##   ⑦-1 : ... --headless --path <root> --import
##   ⑦-2 : ... --headless --path <root> --check-only --script res://scripts/tune_r16.gd
##   ⑦-3 : ... --headless --path <root> --quit
##
## 幂等：备份已存在则跳过（绝不覆盖）；三份分档材质 .tres 已存在则复用（绝不覆盖）；
##       所有属性用绝对目标值；检测到 R16 调优已由并发实例/前次真跑完成时跳过场景写入，
##       仅做 CACHE_MODE_IGNORE 复核。节点数硬门槛 23（pack 前 / 后 / 磁盘回读）。
##
## 【复核纠偏 · 补缺口】并发初版把「角色放大」实现为 pixel_size 0.03125→0.05，但
##   HybridSpriteRig._configure_anchor() 的 _ready() 会强制 set("pixel_size", 1/32)，
##   运行期（Movie Maker 抓帧）该值被覆盖回 0.03125 → 画面角色并未变大（落盘达标、
##   运行期失效）。本次复核改以 Node3D.scale=1.6 放大（不在重置清单内、运行期真正生效），
##   并把 pixel_size 显式恢复 0.03125，消除「落盘 0.05 / 运行期 0.03125」不一致；
##   相机 -20° 与三档 UV 的画面经 r16*.png 实拍已达标（天空带/远景露出、砖块分档一致），
##   沿用不改、不覆盖并发既有产出。DONE-R16.md 末尾追加复核章节登记本次纠偏。

const SCENE_PATH: String = "res://scenes/courtyard.tscn"
const BACKUP_ABS: String = "F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r16"
const GROUND_MAT_PATH: String = "res://assets/generated/terrain/ground_material.tres"

# ④ 三份分档材质副本（放 godot/assets/generated/terrain/，只改 material 不改 mesh）
const MAT_PLATE: String = "res://assets/generated/terrain/ground_tile_mat_plate.tres"
const MAT_LOW: String = "res://assets/generated/terrain/ground_tile_mat_low.tres"
const MAT_HIGH: String = "res://assets/generated/terrain/ground_tile_mat_high.tres"
const UV_PLATE: float = 16.0
const UV_LOW: float = 3.0
const UV_HIGH: float = 2.0

const CAM_PATH: String = "SubViewportContainer/SubViewport/Camera3D"
const SPRITE_PATH: String = "SubViewportContainer/SubViewport/Player/Hybrid2D3DAnimatedSprite/PixelSprite"
const FXLAYER_PATH: String = "SubViewportContainer/SubViewport/FXLayer"
const HUD_PATH: String = "res://scenes/hud.tscn"
const TERRAIN_PATHS := [
    "SubViewportContainer/SubViewport/Terrain/GroundPlate",
    "SubViewportContainer/SubViewport/Terrain/TerraceLow",
    "SubViewportContainer/SubViewport/Terrain/TerraceHigh",
]
const MAT_PATHS := [MAT_PLATE, MAT_LOW, MAT_HIGH]
const UV_SCALES := [UV_PLATE, UV_LOW, UV_HIGH]

# ② 相机：原 rotation.x=-30°、origin(0, 9.6, 14.4)，俯角过大导致砖块铺满画面、
#    天空被压成顶部窄带。抬平到 -20° 让地平线回落、天空带与远景重新露出；
#    origin 略降 / 略后移 (0, 8, 15) 配合更平的视角。绝对目标值保证幂等。
const CAM_PITCH_DEG: float = -20.0
const CAM_TARGET_ORIGIN: Vector3 = Vector3(0.0, 8.0, 15.0)
const ORIGIN_PITCH_DEG: float = -30.0
# ③ 角色放大：用 Node3D.scale ×1.6（运行期有效）。
#    不用 pixel_size：HybridSpriteRig._configure_anchor() 的 _ready() 会强制把
#    pixel_size 重置为 1/32=0.03125；改 pixel_size 落盘达标但 Movie Maker 运行期
#    被覆盖，画面角色不会变大（并发初版实测缺口，本次复核纠正）。
#    pixel_size 显式恢复原值，消除「落盘 0.05 / 运行期 0.03125」不一致。
const PIXEL_SCALE: Vector3 = Vector3(1.6, 1.6, 1.6)
const PIXEL_SIZE: float = 0.03125
const ORIGIN_PIXEL_SIZE: float = 0.03125  # 原始值，仅作对照登记
# ⑤ 节点数硬门槛：pack 前 / 后 / 磁盘回读都必须是 23。
const EXPECTED_NODES: int = 23


func _initialize() -> void:
    print("[R16] === TUNE R16 START (cmd-20261109-085736-022-A1) ===")

    # --- ① 备份 courtyard.tscn（幂等：已存在绝不覆盖） ---
    if not _backup():
        push_error("[R16] STEP1 BACKUP 失败，拒绝继续（场景零改动）")
        quit(1)
        return

    # --- 读磁盘最新场景：CACHE_MODE_IGNORE，避免命中进程缓存 / 并发旧副本 ---
    var src: PackedScene = ResourceLoader.load(
            SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
    if src == null:
        push_error("[R16] STEP2 load courtyard.tscn 失败，拒绝继续")
        quit(1)
        return
    var root: Node = src.instantiate()
    var before_nodes: int = src.get_state().get_node_count()
    print("[R16] STEP2 CACHE_MODE_IGNORE load OK, SceneState node_count(before)=", before_nodes)

    # 关键节点存在性硬校验（缺一即中止，不写盘）
    if not _structure_ok(root):
        push_error("[R16] STEP2 关键节点缺失，拒绝继续（场景零改动）")
        _free_tree(root)
        quit(1)
        return

    # --- 并发 / 幂等保护：R16 调优已由并发实例或前次真跑完成 → 不覆盖既有产出，仅复核 ---
    if _already_tuned(root):
        print("[R16] STEP3 ALREADY_TUNED=true，跳过场景写入（尊重并发/既有产出），仅 CACHE_MODE_IGNORE 复核")
        _free_tree(root)
        var ok: bool = _verify()
        print("[R16] === TUNE R16 END (复核模式) verify_ok=", str(ok), " ===")
        quit(0 if ok else 1)
        return
    print("[R16] STEP3 ALREADY_TUNED=false，开始串行调优 ②③④⑤")

    # --- ② 调 Camera3D 俯角 / 位置，让天空带与远景重新露出 ---
    var cam: Camera3D = root.get_node_or_null(CAM_PATH) as Camera3D
    print("[R16] STEP4 CAMERA BEFORE rot_x=", cam.rotation_degrees.x,
            " origin=", cam.transform.origin)
    var cam_basis: Basis = Basis.from_euler(
            Vector3(deg_to_rad(CAM_PITCH_DEG), 0.0, 0.0))
    cam.transform = Transform3D(cam_basis, CAM_TARGET_ORIGIN)
    print("[R16] STEP4 CAMERA AFTER  rot_x=", cam.rotation_degrees.x,
            " origin=", cam.transform.origin, " target_pitch=", CAM_PITCH_DEG)

    # --- ③ 放大 PixelSprite（Node3D.scale，运行期有效；pixel_size 恢复原值） ---
    var sp: AnimatedSprite3D = root.get_node_or_null(SPRITE_PATH) as AnimatedSprite3D
    print("[R16] STEP5 SPRITE BEFORE scale=", sp.scale, " pixel_size=", sp.pixel_size)
    sp.pixel_size = PIXEL_SIZE
    sp.scale = PIXEL_SCALE
    print("[R16] STEP5 SPRITE AFTER  scale=", sp.scale, " pixel_size=", sp.pixel_size,
            " target_scale=", PIXEL_SCALE)

    # --- ④ 三档 UV：ground_material.tres 的副本分别设 uv1_scale 16/3/2 ---
    var base: StandardMaterial3D = ResourceLoader.load(
            GROUND_MAT_PATH, "StandardMaterial3D", ResourceLoader.CACHE_MODE_IGNORE) as StandardMaterial3D
    if base == null:
        push_error("[R16] STEP6 load ground_material.tres 失败，拒绝继续")
        _free_tree(root)
        quit(1)
        return
    for i in range(TERRAIN_PATHS.size()):
        var m: Material = _ensure_mat(MAT_PATHS[i], float(UV_SCALES[i]), base)
        if m == null:
            push_error("[R16] STEP6 材质生成/复用失败: %s" % MAT_PATHS[i])
            _free_tree(root)
            quit(1)
            return
        var mi: MeshInstance3D = root.get_node_or_null(TERRAIN_PATHS[i]) as MeshInstance3D
        mi.material_override = m   # 只改 material_override，mesh 一字不动
        print("[R16] STEP6 UV node=", TERRAIN_PATHS[i], " mat=", MAT_PATHS[i],
                " uv1_scale=", (m as StandardMaterial3D).uv1_scale)

    # 保证 HUD 实例标记（不展开、不增删节点，节点数仍 23）
    var hud: Node = root.get_node_or_null(FXLAYER_PATH + "/Hud")
    if hud != null and hud.scene_file_path == "":
        hud.set("scene_file_path", HUD_PATH)
    # pack 前重设 owner 链：跳过 scene_file_path 非空的实例化节点，避免 HUD 被展开
    _reset_owner(root, root)

    # --- ⑤ pack 前 / 后节点数比对 + pack→instantiate 探针 ---
    var packed: PackedScene = PackedScene.new()
    var pack_err: Error = packed.pack(root)
    if pack_err != OK:
        push_error("[R16] STEP7 PackedScene.pack() 失败 err=%d，拒绝保存" % pack_err)
        _free_tree(root)
        quit(1)
        return
    var after_nodes: int = packed.get_state().get_node_count()
    var probe: Node = packed.instantiate()
    var probe_runtime: int = _count(probe)
    _free_tree(probe)
    var count_ok: bool = (before_nodes == EXPECTED_NODES) \
            and (after_nodes == EXPECTED_NODES) and (before_nodes == after_nodes)
    print("[R16] STEP7 NODE_COUNT before=", before_nodes, " after=", after_nodes,
            " expected=", EXPECTED_NODES, " pack_err=", pack_err,
            " probe_runtime=", probe_runtime, " count_ok=", str(count_ok))
    if not count_ok:
        push_error("[R16] STEP7 节点数比对失败，中止保存（场景零改动）")
        _free_tree(root)
        quit(1)
        return
    _free_tree(root)

    var save_err: Error = ResourceSaver.save(packed, SCENE_PATH)
    print("[R16] STEP7 SAVE path=", SCENE_PATH, " save_err=", save_err)
    if save_err != OK:
        push_error("[R16] STEP7 场景保存失败，拒绝继续")
        quit(1)
        return

    # CACHE_MODE_IGNORE 磁盘回读
    var verify_ok: bool = _verify()
    print("[R16] === TUNE R16 END verify_ok=", str(verify_ok), " ===")
    quit(0 if verify_ok else 1)


func _backup() -> bool:
    if FileAccess.file_exists(BACKUP_ABS):
        print("[R16] STEP1 BACKUP 已存在，跳过（幂等，绝不覆盖）: ", BACKUP_ABS)
        return true
    var bytes: PackedByteArray = FileAccess.get_file_as_bytes(SCENE_PATH)
    if bytes.is_empty():
        push_error("[R16] STEP1 读取源场景字节失败 path=%s" % SCENE_PATH)
        return false
    var f: FileAccess = FileAccess.open(BACKUP_ABS, FileAccess.WRITE)
    if f == null:
        push_error("[R16] STEP1 打开备份路径失败 err=%d path=%s" % [
                FileAccess.get_open_error(), BACKUP_ABS])
        return false
    f.store_buffer(bytes)
    f.close()
    print("[R16] STEP1 BACKUP 写入 ", bytes.size(), " 字节 -> ", BACKUP_ABS)
    return true


func _structure_ok(root: Node) -> bool:
    var cam: Camera3D = root.get_node_or_null(CAM_PATH) as Camera3D
    var sp: AnimatedSprite3D = root.get_node_or_null(SPRITE_PATH) as AnimatedSprite3D
    if cam == null or sp == null:
        return false
    for p in TERRAIN_PATHS:
        if (root.get_node_or_null(p) as MeshInstance3D) == null:
            return false
    return true


func _already_tuned(root: Node) -> bool:
    # 三份分档 .tres 均已落盘
    for p in MAT_PATHS:
        if not FileAccess.file_exists(p):
            return false
    # 三个地形节点已分别指向对应 .tres（④ 已完成）
    for i in range(TERRAIN_PATHS.size()):
        var mi: MeshInstance3D = root.get_node_or_null(TERRAIN_PATHS[i]) as MeshInstance3D
        if mi == null or mi.material_override == null:
            return false
        if mi.material_override.resource_path != MAT_PATHS[i]:
            return false
    # 相机俯角已离开原始 -30°（② 已完成）
    var cam: Camera3D = root.get_node_or_null(CAM_PATH) as Camera3D
    if cam == null or absf(cam.rotation_degrees.x - ORIGIN_PITCH_DEG) < 1.0:
        return false
    # 角色 scale 已放大到目标、pixel_size 已恢复原值（③ 已完成，运行期不再被覆盖）
    var sp: AnimatedSprite3D = root.get_node_or_null(SPRITE_PATH) as AnimatedSprite3D
    if sp == null:
        return false
    if not sp.scale.is_equal_approx(PIXEL_SCALE):
        return false
    if not is_equal_approx(sp.pixel_size, PIXEL_SIZE):
        return false
    return true


func _ensure_mat(path: String, scale: float, base: StandardMaterial3D) -> Material:
    # 首次：以 ground_material.tres 为模板 duplicate，仅改 uv1_scale，Godot 自己序列化落盘；
    # 已存在则复用（绝不覆盖并发/既有产出）。
    if not FileAccess.file_exists(path):
        var m: StandardMaterial3D = base.duplicate() as StandardMaterial3D
        m.uv1_scale = Vector3(scale, scale, 1.0)
        var err: Error = ResourceSaver.save(m, path)
        if err != OK:
            push_error("[R16] STEP6 MAT save 失败 err=%d path=%s" % [err, path])
            return null
        print("[R16] STEP6 MAT 生成: ", path, " uv1_scale=", m.uv1_scale, " save_err=", err)
    else:
        print("[R16] STEP6 MAT 复用既有（不覆盖）: ", path)
    # 关键：必须用普通 load(path) 取「已在 ResourceCache 注册、resource_path 正确」的对象。
    # 若把 duplicate() 对象或 CACHE_MODE_IGNORE 对象直接赋给 material_override，
    # PackedScene.pack() 会把它写成场景内嵌 SubResource（path 变成
    # res://scenes/courtyard.tscn::StandardMaterial3D_xxx）而非 ExtResource；
    # R15 用 load(GROUND_MAT_PATH) 能写成 ExtResource 正是此理。
    var loaded: StandardMaterial3D = load(path) as StandardMaterial3D
    if loaded == null:
        push_error("[R16] STEP6 MAT load 失败 path=%s" % path)
        return null
    print("[R16] STEP6 MAT 装载缓存对象: ", path, " uv1_scale=", loaded.uv1_scale,
            " resource_path=", loaded.resource_path)
    return loaded


func _verify() -> bool:
    var ps: PackedScene = ResourceLoader.load(
            SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
    if ps == null:
        push_error("[R16_VERIFY] CACHE_MODE_IGNORE 回读失败")
        return false
    var disk_nodes: int = ps.get_state().get_node_count()
    var inst: Node = ps.instantiate()
    var all_ok: bool = (disk_nodes == EXPECTED_NODES)
    print("[R16_VERIFY] NODES SceneState=", disk_nodes, " expected=", EXPECTED_NODES,
            " ok=", str(all_ok))

    var cam: Camera3D = inst.get_node_or_null(CAM_PATH) as Camera3D
    var cam_pitch_ok: bool = cam != null and is_equal_approx(cam.rotation_degrees.x, CAM_PITCH_DEG)
    var cam_origin_ok: bool = cam != null and cam.transform.origin.is_equal_approx(CAM_TARGET_ORIGIN)
    all_ok = all_ok and cam_pitch_ok and cam_origin_ok
    print("[R16_VERIFY] CAMERA rot_x=", (cam.rotation_degrees.x if cam != null else 0.0),
            " origin=", (cam.transform.origin if cam != null else Vector3.ZERO),
            " pitch_ok=", str(cam_pitch_ok), " origin_ok=", str(cam_origin_ok))

    var sp: AnimatedSprite3D = inst.get_node_or_null(SPRITE_PATH) as AnimatedSprite3D
    var scale_ok: bool = sp != null and sp.scale.is_equal_approx(PIXEL_SCALE)
    var size_ok: bool = sp != null and is_equal_approx(sp.pixel_size, PIXEL_SIZE)
    var sprite_ok: bool = scale_ok and size_ok
    all_ok = all_ok and sprite_ok
    print("[R16_VERIFY] SPRITE scale=", (sp.scale if sp != null else Vector3.ZERO),
            " scale_ok=", str(scale_ok),
            " pixel_size=", (sp.pixel_size if sp != null else -1.0),
            " size_ok=", str(size_ok))

    for i in range(TERRAIN_PATHS.size()):
        var mi: MeshInstance3D = inst.get_node_or_null(TERRAIN_PATHS[i]) as MeshInstance3D
        var m: Material = mi.material_override if mi != null else null
        var path_ok: bool = m != null and m.resource_path == MAT_PATHS[i]
        var sm: StandardMaterial3D = m as StandardMaterial3D
        var uv_ok: bool = sm != null and sm.uv1_scale.is_equal_approx(
                Vector3(float(UV_SCALES[i]), float(UV_SCALES[i]), 1.0))
        all_ok = all_ok and path_ok and uv_ok
        print("[R16_VERIFY] UV node=", TERRAIN_PATHS[i],
                " res=", (m.resource_path if m != null else "<null>"),
                " uv1_scale=", (sm.uv1_scale if sm != null else Vector3.ZERO),
                " path_ok=", str(path_ok), " uv_ok=", str(uv_ok))
    print("[R16_VERIFY] CACHE_MODE_IGNORE 磁盘回读 OK=", str(all_ok))
    _free_tree(inst)
    return all_ok


func _reset_owner(node: Node, owner_node: Node) -> void:
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
