extends CanvasLayer
## R19 · HD2DFX 实例根「画质档运行期控制器」
## 派单 cmd-20261109-102334-086-A1 · [ROUND=R19] · AI=1（Rank-1）
## 依据：R18 的 6 项 metadata/fx_profile_* 接线表、hd2d_fx.gd 的 set_fx_profile() 公共入口、
##       quality_preset_desktop.tres / quality_preset_mobile.tres（low_resolution_size 判档）、
##       Rank-1/FX-PROFILE-WIRING.md（切换时机 / 调用方式方案）。
##
## 作用：把 R18「只写了接线元数据」升级为「运行期可切换」：
##   ① _ready() 读 quality preset 的 low_resolution_size 判桌面/移动，遍历 4 个 FX 子节点
##      调用既有 set_fx_profile("desktop"|"mobile") 完成切档；
##   ② 提供 switch_profile(p: String) 公共入口，供运行期（画质菜单 / 平台自适应）随时切档。
##
## 类型：extends CanvasLayer —— HD2DFX 根是 CanvasLayer（layer=10），脚本基类与节点类型一致。
## 冻结口径：desktop 四项全开 / mobile 四项全关（HD2D-FX-PLAN §4.2）；不改 hd2d_fx.gd / 子场景。
## 边界：零外部素材 / 零付费 / 零 autoload / 不增删节点 / 中文 UTF-8 / Godot 4 合法语法。

const PRESET_DESKTOP: String = "res://data/render/quality_preset_desktop.tres"
const PRESET_MOBILE: String = "res://data/render/quality_preset_mobile.tres"
const PROFILE_DESKTOP: String = "desktop"
const PROFILE_MOBILE: String = "mobile"
const FX_CHILD_NAMES := ["FXReflection", "FXGodRays", "FXMotes", "FXBloom"]

const M_SOURCE: String = "fx_profile_source"
const M_ACTIVE: String = "fx_profile_active"
const M_DESKTOP_PRESET: String = "fx_profile_desktop_preset"
const M_MOBILE_PRESET: String = "fx_profile_mobile_preset"
const M_DESKTOP_VALUE: String = "fx_profile_desktop_value"
const M_MOBILE_VALUE: String = "fx_profile_mobile_value"


func _ready() -> void:
    # 启动 / 场景就绪后：读接线表 + 真跑 load preset 判档，再切 4 个 FX 子节点。
    var profile: String = _detect_profile_from_preset()
    switch_profile(profile)


## 读 quality preset 的 low_resolution_size 判断桌面/移动，返回 fx_profile 值。
func _detect_profile_from_preset() -> String:
    var desktop_preset: String = _meta_str(M_DESKTOP_PRESET, PRESET_DESKTOP)
    var mobile_preset: String = _meta_str(M_MOBILE_PRESET, PRESET_MOBILE)
    var source: String = _meta_str(M_SOURCE, PRESET_DESKTOP)

    var desk: Resource = load(desktop_preset) as Resource
    var mob: Resource = load(mobile_preset) as Resource
    var active: Resource = load(source) as Resource
    var fallback: String = _meta_str(M_DESKTOP_VALUE, PROFILE_DESKTOP)
    if desk == null or mob == null or active == null:
        push_warning("[R19_CTRL] preset load 失败，回退默认档 %s" % fallback)
        return fallback
    var desk_res = desk.get("low_resolution_size")
    var mob_res = mob.get("low_resolution_size")
    var active_res = active.get("low_resolution_size")
    if not (desk_res is Vector2i) or not (mob_res is Vector2i) or not (active_res is Vector2i):
        push_warning("[R19_CTRL] low_resolution_size 非 Vector2i，回退默认档 %s" % fallback)
        return fallback
    print("[R19_CTRL] _detect source=%s" % source)
    print("[R19_CTRL] low_resolution_size active=%s desktop=%s mobile=%s" % [
            str(active_res), str(desk_res), str(mob_res)])
    # 判据：当前激活档分辨率达到桌面档 → 桌面；否则 → 移动。
    # R18 真跑冻结值：桌面 (640, 360) > 移动 (480, 270)。
    var is_desktop: bool = (active_res.x >= desk_res.x) and (active_res.y >= desk_res.y)
    var value: String = _meta_str(M_DESKTOP_VALUE, PROFILE_DESKTOP) if is_desktop \
            else _meta_str(M_MOBILE_VALUE, PROFILE_MOBILE)
    print("[R19_CTRL] 判档 active>=desktop=%s -> fx_profile=%s" % [str(is_desktop), value])
    return value


## 运行期切档公共入口：给 4 个 FX 子节点调用既有 set_fx_profile()，并同步当前档 metadata。
func switch_profile(p: String) -> void:
    if p != PROFILE_DESKTOP and p != PROFILE_MOBILE:
        push_warning("[R19_CTRL] switch_profile 非法档位 '%s'（仅 desktop/mobile），忽略" % p)
        return
    var applied: int = 0
    for c in get_children():
        if c.has_method("set_fx_profile"):
            c.call("set_fx_profile", p)
            applied += 1
    set_meta(M_ACTIVE, p)
    print("[R19_CTRL] switch_profile(%s) set_fx_profile 命中 %d/%d 子节点 | fx_profile_active=%s" % [
            p, applied, FX_CHILD_NAMES.size(), p])


func _meta_str(key: String, fallback: String) -> String:
    if has_meta(key):
        return str(get_meta(key))
    return fallback
