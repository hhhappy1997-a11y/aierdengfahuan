# DONE-R19 · Rank-1 引擎架构与渲染（分档接线升级为运行期可切换）

> 命令 `cmd-20261109-102334-086-A1` · `[ROUND=R19]` · AI=1（Rank-1）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（`v4.7.2.stable.official.ed1daf0bf`）
> 工程根 `F:/Game/aierdengfahuan/godot`
> 必读（开工只读）：`Rank-1/FX-PROFILE-WIRING.md`、`godot/scripts/wire_profile_r18.gd`、`godot/scripts/hd2d_fx.gd`（`set_fx_profile`）、`godot/data/render/quality_preset_desktop.tres` / `quality_preset_mobile.tres`、`00-群聊总线.md`（**开工只读一次，未追加**）。
> **本轮只有本工位写 `godot/scenes/courtyard.tscn`**；其它工位、总线 / 总纲 / 契约 / 台账一律未写，未自行 git。

---

## ① 实际交付文件清单

| 类别 | 文件 | 说明 |
|---|---|---|
| 新增脚本 | `godot/scripts/fx_profile_controller.gd` | 4672 B，`extends CanvasLayer`（与 HD2DFX 根类型一致）；`_ready()` 读 quality preset 的 `low_resolution_size` 判桌面/移动，遍历 4 个 FX 子节点调用既有 `set_fx_profile("desktop"|"mobile")`；提供公共入口 `switch_profile(p: String)` 供运行期切档 |
| 引擎产物 | `godot/scripts/fx_profile_controller.gd.uid` | 20 B，`--import` 自动生成（非手工） |
| 新增脚本 | `godot/scripts/wire_r19.gd` | 18432 B，`extends SceneTree` 幂等：备份 → 预检 → `CACHE_MODE_IGNORE` 读场景 → 实例化 → 给 `HD2DFX` 实例根挂 controller（`set_script`）→ 节点数硬门槛 → owner 链 → pack 前/后比对 → pack→instantiate 探针 → save → `CACHE_MODE_IGNORE` 磁盘回读（脚本已挂 + 档位可切换） |
| 引擎产物 | `godot/scripts/wire_r19.gd.uid` | 20 B，`--import` 自动生成 |
| 修改场景 | `godot/scenes/courtyard.tscn` | **节点数保持 24**，sha256 `0d429ab7b66d95b55b12982f49e5bcaef90747b8594f50a0cd1aae4a7d321878`；仅新增 1 行 `script = ExtResource("9_tihrx")` + 顶部 1 行 ext_resource，R18 的 6 项 `metadata/fx_profile_*` 逐字保留 |
| 改动前备份 | `_archived_20261108/courtyard.tscn.bak-pre-r19` | 6121 B，sha256 `461f19c7…`（= R18 终态，与开工检查 / DONE-R18.md 一致），**全程未被覆盖** |
| 真跑日志 | `capture/r19_wire_run.log` / `r19_wire_idempotent.log` | 最终首跑 / 幂等重跑 实际 stdout |
| 迭代留档 | `capture/r19_wire_run_first_attempt.log` / `r19_wire_run_second_attempt.log` | 两次真实失败/带 ERROR 的 stdout **如实留档**（见 2.6），未隐藏 |
| 预检日志 | `capture/r19_precheck_controller.log` / `r19_precheck_wire.log` | 两个新脚本 `--check-only` 语法自检，EXIT 均 0 |
| 门禁日志 | `capture/r19_gate_import.log` / `r19_gate_checkonly.log` / `r19_gate_quit.log` | 三段门禁 实际 stdout |
| 抓帧日志 | `capture/r19_capture.log` | 抓帧 实际 stdout（含 `[R19_CTRL]` 运行期自动切档打印） |
| 抓帧产物 | `capture/r19_scene00000000.png` ~ `r19_scene00000005.png` + `capture/r19_scene.wav` | 6 帧 1280×720 PNG（120671~120784 B，各帧字节不同）+ wav 76844 B |
| 交付文档 | `teamwork/Rank-1/DONE-R19.md` | 本文件 |
| 回执 | `teamwork/command_center/ai/1/outbox/cmd-20261109-102334-086-A1.json` | 按本轮 id 写入，仅一份 |

### courtyard.tscn 落盘文本实证（Grep 实读）

```
12:[ext_resource type="Script" path="res://scripts/fx_profile_controller.gd" id="9_tihrx"]
...
125:[node name="HD2DFX" type="CanvasLayer" parent="SubViewportContainer/SubViewport" unique_id=80156914 instance=ExtResource("8_p30c5")]
126-layer = 10
127-script = ExtResource("9_tihrx")
128-metadata/fx_profile_source = "res://data/render/quality_preset_desktop.tres"
129-metadata/fx_profile_active = "desktop"
130-metadata/fx_profile_desktop_preset = "res://data/render/quality_preset_desktop.tres"
131-metadata/fx_profile_mobile_preset = "res://data/render/quality_preset_mobile.tres"
132-metadata/fx_profile_desktop_value = "desktop"
133-metadata/fx_profile_mobile_value = "mobile"
```

- `HD2DFX` 仍是 `instance=ExtResource("8_p30c5")` 占位的 `CanvasLayer`（`layer=10`），**节点数不变 24**；新增的 `script` 是实例根的属性覆盖（现成范例：`Hud` 节点同为 instance + script 共存），非新增节点、未展开子场景。
- R18 的 6 项 `metadata` 接线表逐字保留，作为 controller `_ready()` 判档的数据源；`fx_profile` 本体仍在 `hd2d_fx.tscn` 的 4 个子节点 `hd2d_fx.gd` 上，本轮**未改写运行中脚本 / 未改子场景**。
- `grep -c "^\[node "` 落盘文本 = **24**，与 `SceneState.get_node_count()` 一致。

---

## ② 自检（真跑实际 stdout、节点数、CACHE_MODE_IGNORE 回读、门禁、抓帧）

### 2.1 `wire_r19.gd` 最终首跑 `--script` · **EXIT=0 / verify_ok=true**

命令：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/wire_r19.gd`

`capture/r19_wire_run.log` 实际 stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[R19] === WIRE R19 START (cmd-20261109-102334-086-A1) ===
[R19] STEP1 BACKUP 已存在，跳过（幂等，绝不覆盖）: F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r19
[R19] STEP2 controller load OK path=res://scripts/fx_profile_controller.gd class=GDScript
[R19] STEP2 PRESET desktop.low_resolution_size=(640, 360) mobile=(480, 270) desktop_gt_mobile=true
[R19] STEP3 CACHE_MODE_IGNORE load OK, SceneState node_count(before)=24
[R19] STEP4 HD2DFX name=HD2DFX class=CanvasLayer layer=10 scene_file_path=res://scenes/hd2d_fx.tscn
[R19] STEP5 set_script(controller) 写入脚本属性覆盖 path=res://scripts/fx_profile_controller.gd
[R19] STEP5 get_script()=res://scripts/fx_profile_controller.gd attach_ok=true
[R19] STEP6 scene_file_path / owner 链就绪（跳过实例化节点，不展开）
[R19] STEP7 NODE_COUNT before=24 after=24 expected=24 pack_err=0 count_ok=true
[R19] STEP7 PACK_PROBE script_ok=true instance=true children_ok=true runtime_nodes=30 probe_ok=true
[R19] STEP8 SAVE_OK path=res://scenes/courtyard.tscn save_err=0
==== [R19 回读 CACHE_MODE_IGNORE] START ====
[R19_VERIFY] readback class=PackedScene resource_path=res://scenes/courtyard.tscn SceneState_nodes=24
[R19_VERIFY] ① readback_not_null_and_PackedScene PASS=true | class=PackedScene
[R19_VERIFY] ② SceneState_node_count_24 PASS=true | nodes=24 expected=24
[R19_VERIFY] ③ FX_instance_present PASS=true | path=SubViewportContainer/SubViewport/HD2DFX found=true
[R19_VERIFY] ④ FX_root_CanvasLayer_layer10 PASS=true | class=CanvasLayer layer=10 expected=10
[R19_VERIFY] ⑤ FX_is_instance_placeholder PASS=true | scene_file_path=res://scenes/hd2d_fx.tscn
[R19_VERIFY] ⑥ controller_script_attached PASS=true | script=res://scripts/fx_profile_controller.gd expected=res://scripts/fx_profile_controller.gd
[R19_VERIFY] ⑦ switch_profile_method_available PASS=true | has_method=true
[R19_VERIFY] ⑧ wiring[fx_profile_source] PASS=true | actual=res://data/render/quality_preset_desktop.tres expected=res://data/render/quality_preset_desktop.tres
[R19_VERIFY] ⑧ wiring[fx_profile_active] PASS=true | actual=desktop expected=desktop
[R19_VERIFY] ⑧ wiring[fx_profile_desktop_preset] PASS=true | actual=res://data/render/quality_preset_desktop.tres expected=res://data/render/quality_preset_desktop.tres
[R19_VERIFY] ⑧ wiring[fx_profile_mobile_preset] PASS=true | actual=res://data/render/quality_preset_mobile.tres expected=res://data/render/quality_preset_mobile.tres
[R19_VERIFY] ⑧ wiring[fx_profile_desktop_value] PASS=true | actual=desktop expected=desktop
[R19_VERIFY] ⑧ wiring[fx_profile_mobile_value] PASS=true | actual=mobile expected=mobile
[R19_VERIFY] ⑨ child_script_hd2d_fx_all_4 PASS=true | FXReflection:script=res://scripts/hd2d_fx.gd | FXGodRays:script=res://scripts/hd2d_fx.gd | FXMotes:script=res://scripts/hd2d_fx.gd | FXBloom:script=res://scripts/hd2d_fx.gd
[R19_CTRL] _detect source=res://data/render/quality_preset_desktop.tres
[R19_CTRL] low_resolution_size active=(640, 360) desktop=(640, 360) mobile=(480, 270)
[R19_CTRL] 判档 active>=desktop=true -> fx_profile=desktop
[R19_CTRL] switch_profile(desktop) set_fx_profile 命中 4/4 子节点 | fx_profile_active=desktop
[R19_VERIFY] ⑩ _ready 自动判档 desktop 4/4 四项全开 PASS=true | [after_ready] FXReflection:fx_profile=desktop visible=true _all_on=true | FXGodRays:fx_profile=desktop visible=true _all_on=true | FXMotes:fx_profile=desktop visible=true _all_on=true | FXBloom:fx_profile=desktop visible=true _all_on=true
[R19_CTRL] switch_profile(mobile) set_fx_profile 命中 4/4 子节点 | fx_profile_active=mobile
[R19_VERIFY] ⑪ switch_profile(mobile) 4/4 四项全关 PASS=true | [mobile] FXReflection:fx_profile=mobile visible=false _all_on=false | FXGodRays:fx_profile=mobile visible=false _all_on=false | FXMotes:fx_profile=mobile visible=false _all_on=false | FXBloom:fx_profile=mobile visible=false _all_on=false
[R19_CTRL] switch_profile(desktop) set_fx_profile 命中 4/4 子节点 | fx_profile_active=desktop
[R19_VERIFY] ⑫ switch_profile(desktop) 4/4 四项全开 PASS=true | [desktop] FXReflection:fx_profile=desktop visible=true _all_on=true | FXGodRays:fx_profile=desktop visible=true _all_on=true | FXMotes:fx_profile=desktop visible=true _all_on=true | FXBloom:fx_profile=desktop visible=true _all_on=true
[R19_VERIFY] VERIFY_SUMMARY pass=17 fail=0 OK=true
==== [R19 回读 CACHE_MODE_IGNORE] END ====
[R19] === WIRE R19 END verify_ok=true ===
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

> 2 条 WARNING 为工程既有现象（autoload `ChunkManager`、`ObjectDB leaked`），与 R9~R18 一致，**非 ERROR / 非 SCRIPT ERROR**，如实登记、未冒充全绿。

### 2.2 幂等重跑 · **EXIT=0**（`capture/r19_wire_idempotent.log`）

```
[R19] === WIRE R19 START (cmd-20261109-102334-086-A1) ===
[R19] STEP1 BACKUP 已存在，跳过（幂等，绝不覆盖）: .../courtyard.tscn.bak-pre-r19
[R19] STEP2 controller load OK path=res://scripts/fx_profile_controller.gd class=GDScript
[R19] STEP3 CACHE_MODE_IGNORE load OK, SceneState node_count(before)=24
[R19] STEP5 ALREADY_ATTACHED=true，controller 已挂载，跳过写盘（复核模式）
[R19] STEP5 get_script()=res://scripts/fx_profile_controller.gd attach_ok=true
[R19] STEP7 NODE_COUNT before=24 after=24 expected=24 pack_err=0 count_ok=true
[R19] STEP7 PACK_PROBE script_ok=true instance=true children_ok=true runtime_nodes=30 probe_ok=true
[R19] STEP8 SKIP_SAVE（复核模式，不写盘）
  ... （17 项逐项 PASS，与 2.1 逐字一致）
[R19_VERIFY] VERIFY_SUMMARY pass=17 fail=0 OK=true
[R19] === WIRE R19 END verify_ok=true ===
```

- `ALREADY_ATTACHED=true` → **跳过写盘**（并发保护，绝不覆盖既有产出），仅 `CACHE_MODE_IGNORE` 复核；备份「已存在则不覆盖」。
- 重跑前 / 后场景 sha256 均 `0d429ab7…`、备份 sha256 均 `461f19c7…` → **字节级幂等成立，备份未被覆盖**。

### 2.3 节点数 / `CACHE_MODE_IGNORE` 回读结论

| 校验点 | 实际值 | 结论 |
|---|---|---|
| pack 前 `src.get_state().get_node_count()` | **24** | 符合 `EXPECTED_NODES=24` |
| pack 后 `packed.get_state().get_node_count()` | **24** | `after == before == 24`（本轮不增删节点，只加实例根 script 覆盖） |
| `count_ok`（保存硬门槛） | `before==24 && after==24 && after==before` → **true** | 任一不符即 `push_error + quit(1)` 中止 `ResourceSaver.save()`（本轮满足，未触发） |
| pack→instantiate 往返探针 | `probe_ok=true`、`script_ok=true`、`instance=true`、`children_ok=true`、`runtime_nodes=30` | **controller 脚本覆盖确实被 pack 保留**，HD2DFX 仍是 instance 占位、4 子节点完整 |
| `grep -c "^\[node "` 落盘文本 | **24** | 与 SceneState 一致 |
| `CACHE_MODE_IGNORE` 磁盘回读 | `SceneState_nodes=24`、`VERIFY_SUMMARY pass=17 fail=0 OK=true` | 绕过进程缓存强制重读磁盘 |
| ⑥ 脚本已挂 | `get_script()=res://scripts/fx_profile_controller.gd`、`has_method("switch_profile")=true` | 运行期可切换的前提成立 |
| ⑧ R18 6 项接线值逐项回读 | `fx_profile_source` / `_active` / `_desktop_preset` / `_mobile_preset` / `_desktop_value` / `_mobile_value` 全 `PASS=true` | 接线表未被破坏，仍是判档数据源 |
| ⑩⑫ `switch_profile`/`_ready` 切档 | desktop 4/4 `visible=true _all_on=true fx_profile=desktop`；⑪ mobile 4/4 `visible=false _all_on=false fx_profile=mobile` | **档位可切换，逐节点逐项真跑回读** |
| preset 真跑值 | desktop `(640,360)` > mobile `(480,270)`；`active>=desktop` 判 desktop | 判档来源真实、非臆造（§4.2 冻结口径） |

> 脚本用 `CACHE_MODE_IGNORE` 读磁盘最新场景；STEP6 沿用 R17/R18 的 `scene_file_path` 标记 + `_reset_owner`（跳过实例化节点），确保 pack 把 HD2DFX 折叠成 `instance` 占位且**节点数不变**。

### 2.4 三段门禁（逐段真实 EXIT + stdout）

| 段 | 命令 | **EXIT** |
|---|---|---|
| G1 | `--headless --path F:/Game/aierdengfahuan/godot --import` | **0** |
| G2 | `--headless --path F:/Game/aierdengfahuan/godot --check-only --script res://scripts/fx_profile_controller.gd` | **0** |
| G3 | `--headless --path F:/Game/aierdengfahuan/godot --quit` | **0** |

G1 `r19_gate_import.log` stdout（实际，含扫描进度行）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[   0% ] first_scan_filesystem | 正在扫描文件结构……
[  16% ] first_scan_filesystem | 正在加载全局类名……
[  33% ] first_scan_filesystem | 正在校验 GDExtension……
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[  66% ] first_scan_filesystem | 正在初始化插件……
[  83% ] first_scan_filesystem | 正在启动文件扫描……
[ DONE ] first_scan_filesystem

[   0% ] loading_editor_layout | Started 正在加载编辑器 (5 steps)
[   0% ] loading_editor_layout | 正在加载编辑器布局……
[  16% ] loading_editor_layout | 正在加载停靠面板……
[ DONE ] loading_editor_layout
```

G2 `r19_gate_checkonly.log` stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

```

> `check-only` 仅解析、未执行 `_initialize()`，**未误触发场景二次修改**；门禁后复查场景 sha256 仍 `0d429ab7…`、节点数 24。

G3 `r19_gate_quit.log` stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

> 唯一 WARNING 为工程既有的 `2 ObjectDB instances were leaked`（R9~R18 门禁即有），WARNING 级、非 ERROR、不改退出码（G3 EXIT=0）；按契约 §10 固定 `--headless --quit`，不宣称 WARNING 清零。

正式 6 份日志（`r19_wire_run.log` / `r19_wire_idempotent.log` / `r19_gate_import.log` / `r19_gate_checkonly.log` / `r19_gate_quit.log` / `r19_capture.log`）`grep -n -E 'SCRIPT ERROR|Parse Error|ERROR:'` 实际输出 **0 条**：

```
正式 6 份日志：无 ERROR / SCRIPT ERROR / Parse Error
```

### 2.5 Movie Maker 抓帧 · **EXIT=0**

命令（任务给定**绝对路径 + `.png`** 后缀，沿用 R14~R18 口径；**不带 `--headless`**，Movie Maker 需渲染设备）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot --write-movie F:/Game/aierdengfahuan/capture/r19_scene.png --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn
```

`capture/r19_capture.log` 实际 stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 616.92 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Ti

Movie Maker mode enabled, recording movie in 1280×720 @ 30 FPS...
[R19_CTRL] _detect source=res://data/render/quality_preset_desktop.tres
[R19_CTRL] low_resolution_size active=(640, 360) desktop=(640, 360) mobile=(480, 270)
[R19_CTRL] 判档 active>=desktop=true -> fx_profile=desktop
[R19_CTRL] switch_profile(desktop) set_fx_profile 命中 4/4 子节点 | fx_profile_active=desktop
--------------------------------------------------------------------------------
Done recording movie at path: F:/Game/aierdengfahuan/capture/r19_scene.png
6 frames at 30 FPS (movie length: 00:00:00:06), recorded in 00:00:05 (20% of real-time speed).
CPU render time: 0.00 seconds (average: 0.02 ms/frame)
GPU render time: 0.00 seconds (average: 0.00 ms/frame)
Encoding time: 0.25 seconds (average: 42.33 ms/frame)
--------------------------------------------------------------------------------
```

- **关键证据**：抓帧是引擎真实加载 `courtyard.tscn` 运行，stdout 直接出现 4 行 `[R19_CTRL]` —— 证明挂在 HD2DFX 实例根的 controller `_ready()` **被引擎自动调用**：读 preset `low_resolution_size` 判档 desktop → `switch_profile(desktop)` 命中 4/4 子节点。即「R18 接线元数据 → R19 运行期自动切换」在真跑运行期生效，非仅脚本层方案。
- 产出 `r19_scene00000000.png` ~ `r19_scene00000005.png`（**6 帧**）+ `r19_scene.wav`；首帧 PNG 头 24 字节 `89 50 4e 47 0d 0a 1a 0a 00 00 00 0d 49 48 44 52 00 00 05 00 00 00 02 d0` = PNG 签名合法、**1280×720**；6 帧字节各不相同（逐帧动画生效，与 R17/R18 一致）。抓帧日志 `SCRIPT ERROR|ERROR` grep **0 条**。
- 注：任务文字写「抓帧 `capture/r19_scene.png`」，`--write-movie` 以该 `.png` 为前缀实际输出 PNG 序列（`r19_scene0000000*.png`）+ wav，与 R14~R18 一致，如实登记。

### 2.6 迭代留痕（如实，未隐藏失败日志）

1. **首次真跑**（`r19_wire_run_first_attempt.log`）：验证阶段把整个 `courtyard` 实例加入 `SceneTree.root` 以触发 `_ready()`，收尾 `free` 整树后，autoload `ChunkManager` 的 `_finish_load`（`godot/scripts/world/chunk_streaming.gd:237`）对已释放的 `ChunkRoot` 调 `add_child`，产生 **2 条 `SCRIPT ERROR: Cannot call method 'add_child' on a previously freed instance`**。
2. **二次真跑**（`r19_wire_run_second_attempt.log`）：改为只把 `HD2DFX` 加进 root，但 `Node.add_child()` 不自动移出旧父，产生 **2 条 `ERROR: Can't add child 'HD2DFX' to 'root', already has a parent 'SubViewport'` / `Condition "p_child->data.parent != this" is true`**，且 ⑩ 因节点未进树成为假阳性。
3. **根因定位**：只读 `chunk_streaming.gd:43-68 / 201-243`，确认 `_resolve_chunk_root()` 用 `get_tree().root.find_child("ChunkRoot")` 绑定 `_chunk_root`，`_finish_load()` 对其 `add_child`；R18 从不把场景加进 root 故无此错。
4. **最终修正**：验证阶段**不把任何节点加入 `SceneTree.root`**，改用 `fx.call("_ready")` 真跑 controller 判档 + `switch_profile` 两档真跑（均为普通方法，不依赖进树）；引擎自动调用 `_ready()` 由 2.5 抓帧 stdout 的 `[R19_CTRL]` 佐证。每次迭代均从 `bak-pre-r19`（R18 终态，sha256 `461f19c7…`）恢复场景后重跑，最终首跑 / 幂等重跑 / 三段门禁 / 抓帧 6 份正式日志 `grep ERROR|SCRIPT ERROR|Parse Error` = **0 条**。两次迭代 stdout **全文留档**，未删除、未伪造。

---

## ③ 未完成项与阻塞（如实）

1. **运行期切档触发源仍依赖上层**：本轮落盘的是「启动自动判档（controller `_ready()`）+ 运行期公共入口 `switch_profile(p)`」。当前 `fx_profile_source` 默认指向 desktop preset，故场景实例化时自动判为 desktop；**未接入设置菜单 / 画质切换 UI，也未实现「运行期改写 `fx_profile_source` 后自动重判」的监听**。要切到 mobile 需外部调用 `HD2DFX.switch_profile("mobile")`，或改写 `fx_profile_source` 指向 mobile preset 后重新实例化场景。切换时机见 `FX-PROFILE-WIRING.md` §3。
2. **冻结口径未擅改**：判档沿用 R18 / HD2D-FX-PLAN §4.2（桌面四项全开 `desktop` / 移动四项全关 `mobile`）；§4.3「移动档降级而非全关」、§4.4「逐层 visible 接线」仍为待裁决建议，未擅自实现。
3. **冻结件零写入**：`quality_preset_desktop.tres` / `quality_preset_mobile.tres` / `render_profiles.tres` / `hd2d_fx.gd` / `hd2d_fx.tscn` / `attach_fx_r17.gd` / `wire_profile_r18.gd` 均**只读其 `low_resolution_size` / 结构作依据，零写入**（既有件不重做）；4 个 FX 子节点默认 `fx_profile=desktop` 未改写。
4. **既有 WARNING（非本轮引入、非 ERROR）**：wire 真跑 2 份各 1 条 `ChunkManager 未找到 ChunkRoot` + 1 条 `2 ObjectDB instances were leaked`，G3 1 条 `ObjectDB leaked`；import / check-only / 抓帧 0 条。与 R9~R18 一致，未处理、未冒充全绿。
5. **并发保护执行记录**：本轮 R19 为多工位并行，`Rank-2/3/4/DONE-R19.md`、`Rank-4` 的 `capture/r19_mobile*.png` / `r19_verify_run.log`（派单 `cmd-20261109-102334-091-A4`）、`Rank-3/r19_verify_hud.gd` 均为其它工位产物，文件名前缀与本工位（`r19_scene` / `r19_wire` / `r19_gate` / `r19_precheck`）不重叠。开工只读检查 Rank-1 目标产物（`bak-pre-r19` / `DONE-R19.md` / 两个 `.gd` / outbox 本轮回执）**全部 ABSENT**，写 DONE 与回执前再次复核 outbox 为空、无同 id receipts 归档 → 本实例自行写入；仅只读确认 `r19_verify_run.log` 的来源（Rank-4）以排除踩踏，**未覆盖任何并发产出、未写第二份回执**。
6. **抓帧仅验证「抓帧成功 / PNG 合法 / 运行期 `_ready()` 自动切换打印」**：本轮改动是脚本挂载，画面应与 R18 一致；未做 R18↔R19 像素级差异验收，不宣称画面 HD-2D 全绿达标 / 运行期观感已人工验收。R17 遗留画质（倒影不清晰、2D 程序化近似非原生后处理、HUD 静态未绑数据等）本轮未扩展。
7. **按约束未做 / 边界**：默认不刺探（仅本单必要只读，未扫无关目录 / 未做进度巡检）；零付费 / 零外部素材 / 零外部生成服务 / 零插件 / 未新增 autoload；不伪造输出、不冒充全绿；中文 UTF-8、Godot 4.7.2 合法语法（G2 `--check-only` EXIT=0）；不写其它工位 / 总线 / 总纲 / 契约 / 台账；不自行 `git commit` / `git push`；`00-群聊总线.md` 开工只读一次、未追加（本轮无接口变更 / 里程碑 / 阻塞求助 / 回应 @ 事件，且总线不在可写范围）。

---

## 结论

主任务闭环：`fx_profile_controller.gd`（`extends CanvasLayer`）与 `wire_r19.gd`（`extends SceneTree`，幂等）落盘并真跑（**EXIT=0 / verify_ok=true**）；在 R18 的 6 项 `metadata` 接线表基础上，把 `HD2DFX` 实例根**挂上控制器脚本**，实现「`_ready()` 读 quality preset `low_resolution_size` 判桌面/移动 → `set_fx_profile` 切 4 个 FX 子节点」与「运行期 `switch_profile(p)` 公共入口」；**节点数 pack 前 24 / pack 后 24 / `CACHE_MODE_IGNORE` 磁盘回读 24**，回读 **17 项全 PASS**（含脚本已挂、6 项接线值逐项回读、`_ready` 判档 desktop 与 `switch_profile` mobile/desktop 两档逐节点逐项切换）。幂等重跑 `ALREADY_ATTACHED` / `SKIP_SAVE`、场景与备份 sha256 字节不变。三段门禁真实 EXIT **0 / 0 / 0**，正式 6 份日志 `grep "ERROR|SCRIPT ERROR|Parse Error"` **0 条**。按任务给定绝对路径命令抓帧 **EXIT=0**，产出 6 帧 1280×720 PNG + wav，且抓帧 stdout 的 `[R19_CTRL]` 打印实证**引擎自动调用 `_ready()` 完成运行期自动切档**。

`status=done` 指**本轮「分档接线升级为运行期可切换」与验证主任务闭环**，**不代表**「已接入画质设置菜单 / 运行期改写 preset 后自动重判」，或「画面 HD-2D 全绿达标 / 运行期观感已验收」。

> 证据：`capture/r19_wire_run.log`、`r19_wire_idempotent.log`、`r19_wire_run_first_attempt.log`、`r19_wire_run_second_attempt.log`、`r19_gate_*.log`、`r19_capture.log`、`r19_precheck_*.log`、`capture/r19_scene0000000*.png`、`capture/r19_scene.wav`、`_archived_20261108/courtyard.tscn.bak-pre-r19`、`godot/scenes/courtyard.tscn`、`godot/scripts/fx_profile_controller.gd`、`godot/scripts/wire_r19.gd`。

---

## ④ 回执

- 按本轮 id 写入 `teamwork/command_center/ai/1/outbox/cmd-20261109-102334-086-A1.json` **仅一份**，内容见该文件（`result` 引用本文件实际结论）。
- 写入前复核 outbox 为空、无同 id receipts 归档；未写第二份回执、未改写任何归档件。

---

## ⑤ 回执路由状态（收尾复核追加，不改动上文结论）

- 回执按本轮 id 写入 `command_center/ai/1/outbox/cmd-20261109-102334-086-A1.json` **仅一份**；写入后被调度中枢**即时消费**，outbox 现为空，归档到 `command_center/dispatcher/receipts/cmd-20261109-102334-086-A1.json`（1209 B）。只读复核归档件：`task_id=cmd-20261109-102334-086-A1` / `ai=1` / `status=done`，字段与本工位写入的逐字一致（`result` 引用 DONE-R19.md 实际结论），JSON 合法。
- 按派单「若回执已被送达中枢（outbox 空但 receipts 归档存在）→ 不再写第二份」，**未写第二份回执、未改写归档件**；上文 ④ 中的回执路径为写入时的初始位置，实际路由以本节为准。
- `dispatcher/receipts/` 不在本轮可写范围，全程未改写任何归档件，未在 outbox 重复投递。
