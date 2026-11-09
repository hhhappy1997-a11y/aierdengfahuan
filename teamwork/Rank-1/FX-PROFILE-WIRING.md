# FX-PROFILE-WIRING · 桌面/移动画质档 ↔ fx_profile 可切换接线方案

> 命令 `cmd-20261109-095518-171-A1` · `[ROUND=R18]` · AI=1（Rank-1）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（`v4.7.2.stable.official.ed1daf0bf`）
> 工程根 `F:/Game/aierdengfahuan/godot`
> 本文件是**方案说明（给方案即可）**：说明「桌面档 `fx_profile=desktop`、移动档 `fx_profile=mobile`」的**切换时机与调用方式**。
> 本轮在场景里真正落盘、并被 `CACHE_MODE_IGNORE` 回读验证的改动，是 `godot/scenes/courtyard.tscn` 里 `HD2DFX` 实例根上的 **6 项 `metadata/` 接线表**（由 `godot/scripts/wire_profile_r18.gd` 写入，真跑 EXIT=0）。**运行时自动切换逻辑本轮未落盘实现**，不臆造 API、不改运行中脚本、不加 autoload、不增删节点。

---

## 1. 为什么用 metadata 接线（不臆造 API）

- `HD2DFX` 是 R17 挂入的 `instance=ExtResource("8_p30c5")` 占位实例（`godot/scenes/hd2d_fx.tscn` 的实例化），根是 `CanvasLayer`（`layer=10`），**根本身没有 `fx_profile` 属性**。
- 真正的 `fx_profile`（`@export_enum("desktop","mobile")`）与公共入口 `set_fx_profile()` 在 `hd2d_fx.tscn` 的 **4 个 FX 子节点**（`FXReflection` / `FXGodRays` / `FXMotes` / `FXBloom`）所挂的 `godot/scripts/hd2d_fx.gd` 上；这些子节点归属子场景，不在 `courtyard.tscn` 的节点段里，**本轮不改写它们**（既有件不重做）。
- 因此把「档位 → quality preset 路径 → fx_profile 值」的**接线表**以 `Node.set_meta()` 写在 `HD2DFX` 实例根上：`.tscn` 落盘为 `metadata/<key> = "..."`，运行时由 `Node.get_meta()` / `has_meta()` 读取。`set_meta`/`get_meta`/`load`/`get_children`/`has_method`/`call` 均为 Godot 4 既有 API，`set_fx_profile()` 是 `hd2d_fx.gd` 既有公共方法（已由 `godot/scripts/verify_fx_profile.gd` 真跑验证 desktop/mobile 两档切换），**没有臆造任何 API**。
- 接线值是**真跑读出来的**，不是硬编码臆造：`wire_profile_r18.gd` 在 STEP2 `load()` 两份 preset 并 `get("low_resolution_size")`，得桌面 `(640, 360)` > 移动 `(480, 270)`，据此判档，再按 `Rank-4/HD2D-FX-PLAN.md` §4.2 冻结口径映射到 `fx_profile` 值（桌面四项全开 → `desktop`、移动四项全关 → `mobile`）。

---

## 2. 落盘接线表（courtyard.tscn:126–131，CACHE_MODE_IGNORE 已回读校验）

| `metadata` 键 | 落盘值 | 含义 |
|---|---|---|
| `fx_profile_source` | `res://data/render/quality_preset_desktop.tres` | **当前激活档的 quality preset 路径**（运行时读取入口；R18 默认桌面，保持 R17 `fx_profile=desktop` 四项全开） |
| `fx_profile_active` | `desktop` | **当前激活档的 fx_profile 值**（HD2DFX 的「默认档位」以元数据形式表达；根是 CanvasLayer 无 fx_profile 属性） |
| `fx_profile_desktop_preset` | `res://data/render/quality_preset_desktop.tres` | 桌面档 preset 路径 |
| `fx_profile_mobile_preset` | `res://data/render/quality_preset_mobile.tres` | 移动档 preset 路径 |
| `fx_profile_desktop_value` | `desktop` | **桌面档 → fx_profile 值**（四项全开） |
| `fx_profile_mobile_value` | `mobile` | **移动档 → fx_profile 值**（四项全关） |

真跑真值（来自 `capture/r18_wire_run.log`）：

```
[R18] STEP2 PRESET desktop.low_resolution_size=(640, 360) mobile=(480, 270) desktop_gt_mobile=true
[R18] STEP2 档位→fx_profile 映射: desktop->desktop / mobile->mobile（§4.2 冻结口径）
[R18] STEP5 set_meta 写入 6 项接线: fx_profile_source=res://data/render/quality_preset_desktop.tres | fx_profile_active=desktop | fx_profile_desktop_preset=res://data/render/quality_preset_desktop.tres | fx_profile_mobile_preset=res://data/render/quality_preset_mobile.tres | fx_profile_desktop_value=desktop | fx_profile_mobile_value=mobile
[R18] STEP7 PACK_PROBE meta_ok=true instance=true children_ok=true runtime_nodes=30 probe_ok=true
[R18_VERIFY] VERIFY_SUMMARY pass=14 fail=0 OK=true
```

**核心映射（一句话）**：桌面档 `fx_profile=desktop`（四项全开）；移动档 `fx_profile=mobile`（四项全关）。依据 `quality_preset_desktop.tres` / `quality_preset_mobile.tres` 的冻结开关（体积光 / 光尘 / 湿地倒影 / bloom 桌面 true / 移动 false，HD2D-FX-PLAN §4.2）。

---

## 3. 切换时机（方案）

接线表只提供「数据」，**何时调用**由上层既有画质管线决定（本轮不实现、不臆造具体 autoload）：

1. **启动 / 场景就绪后**：`courtyard.tscn` 实例化进场景树、4 个 FX 子节点 `_ready()` 跑完后，由画质初始化处读 `SceneRouter` 当前档（或 `RenderProfiles` 资源 / 导出平台判定：桌面导出 → desktop、移动导出 → mobile），把 `HD2DFX` 的 `metadata/fx_profile_source` 设为对应档的 preset 路径，再调用一次下方 §4 的 `apply_fx_profile_for_current_quality()`。
2. **用户切换画质档 / 平台自适应触发时**：设置菜单改动画质档、或运行期设备档位变更 → 更新 `fx_profile_source` → 再调用一次 §4 函数（幂等，重复设同一档结果一致）。
3. **每次切档同步**：把 `metadata/fx_profile_active` 同步为本次生效的 `fx_profile` 值（`desktop` / `mobile`），便于运行期回读当前档。

> 切换动作建议落在**首帧之后**（FX 子节点 `_ready()` 已执行 `set_fx_profile(fx_profile)` 默认 desktop），避免与初始化竞态；`set_fx_profile()` 本身会立即重算四项绘制门与 `visible`，无需重建节点。

---

## 4. 调用方式（方案伪代码，非本轮落盘实现）

```gdscript
# 方案：运行时切换入口（调用方在 §3 的时机调用；用既有 API，不新建类/不改 hd2d_fx.gd）
const FX_PATH := "SubViewportContainer/SubViewport/HD2DFX"

func apply_fx_profile_for_current_quality(scene_root: Node) -> void:
    var fx := scene_root.get_node_or_null(FX_PATH)
    if fx == null or not fx.has_meta("fx_profile_source"):
        return
    var source          := str(fx.get_meta("fx_profile_source"))           # 当前激活档 preset 路径
    var mobile_preset   := str(fx.get_meta("fx_profile_mobile_preset"))
    # 判档（亦可改为 load(source).get("low_resolution_size") 按分辨率判：640x360→desktop / 480x270→mobile）
    var value: String
    if source == mobile_preset:
        value = str(fx.get_meta("fx_profile_mobile_value"))                # 移动档 → "mobile"（四项全关）
    else:
        value = str(fx.get_meta("fx_profile_desktop_value"))               # 桌面档 → "desktop"（四项全开）
    fx.set_meta("fx_profile_active", value)
    for c in fx.get_children():                                            # 4 个 FX 子节点
        if c.has_method("set_fx_profile"):
            c.call("set_fx_profile", value)                                # hd2d_fx.gd 既有公共入口，立即重算四项门/visible
```

切到移动档示例（把「当前激活档」切到 mobile，再调用入口）：

```gdscript
fx.set_meta("fx_profile_source", "res://data/render/quality_preset_mobile.tres")
apply_fx_profile_for_current_quality(scene_root)
# 结果：4 个 FX 子节点 fx_profile="mobile"、visible=false、四项全关
```

切回桌面档：

```gdscript
fx.set_meta("fx_profile_source", "res://data/render/quality_preset_desktop.tres")
apply_fx_profile_for_current_quality(scene_root)
# 结果：4 个 FX 子节点 fx_profile="desktop"、visible=true、四项全开
```

> 注：`set_fx_profile()` 的两档行为已由 `godot/scripts/verify_fx_profile.gd`（R17 Rank-4 交付）在真跑实例化下逐节点逐项回读验证（desktop 四项全开 / mobile 四项全关 / `texture_filter` 两档均 Nearest）；本方案只是**从接线表取值去调用它**，不改写该脚本。

---

## 5. 边界与未完成项（如实）

1. **本轮只建立「接线表数据」**：6 项 `metadata` 已落盘且 `CACHE_MODE_IGNORE` 回读 14 项全 PASS；**运行时自动切换逻辑未落盘实现**（任务要求「给方案即可」），未加 autoload、未新增节点、未改 `hd2d_fx.gd` / `hd2d_fx.tscn` / `quality_preset_*.tres` / `render_profiles.tres`。
2. **不擅改冻结件**：`quality_preset_desktop.tres` / `quality_preset_mobile.tres` / `render_profiles.tres` 归 Rank-1 装配权且需总指挥裁决（HD2D-FX-PLAN §4.3/§4.4），本轮**只读其 `low_resolution_size` 判档，零写入**。
3. **§4.3「移动档降级而非全关」是待裁决建议**：本方案沿用 §4.2 冻结口径（移动档四项全关 = `fx_profile=mobile`），未擅自实现降级。
4. **§4.4「逐层 visible 接线」是建议**：本方案用 `set_fx_profile()` 整体切档（四项门 + visible 由 `_apply_profile()` 派生），未逐层读 `volumetric_fog_enabled` / `dust_particle_cap` 等字段逐层设 `visible`。
5. **默认档位**：R18 落盘 `fx_profile_source` 指向 desktop preset、`fx_profile_active=desktop`，与 R17 的 `fx_profile=desktop` 四项全开一致；`courtyard.tscn` 的 4 个 FX 子节点脚本默认 `fx_profile` 仍为 `desktop`（未改写）。
6. **真跑验证边界**：本方案的接线值可回读验证（metadata 逐项回读 + preset 真跑值 + 节点数 24）；但「运行时按档位自动切换生效」属方案层，本轮**未在运行期真跑切档**，不宣称已实现/已验收。

---

## 6. 证据索引

- 接线落盘：`godot/scenes/courtyard.tscn` 第 126–131 行（`metadata/fx_profile_*`）。
- 写入脚本：`godot/scripts/wire_profile_r18.gd`（`extends SceneTree`，幂等）。
- 真跑日志：`capture/r18_wire_run.log`（首跑 EXIT=0）、`capture/r18_wire_idempotent.log`（幂等复核 EXIT=0）。
- 依据件：`godot/data/render/quality_preset_desktop.tres` / `quality_preset_mobile.tres`、`godot/scripts/core/quality_preset.gd`、`godot/scripts/hd2d_fx.gd`、`godot/scenes/hd2d_fx.tscn`、`godot/scripts/verify_fx_profile.gd`、`Rank-4/HD2D-FX-PLAN.md` §4.2/§4.3/§4.4。
- 详见 `Rank-1/DONE-R18.md` ② 自检（真跑实际 stdout、节点数、门禁、抓帧）。
