# DONE-R16 · Rank-1 引擎架构与渲染

> 命令 `cmd-20261109-085736-022-A1` · `[ROUND=R16]` · AI=1
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（日志版本行 `v4.7.2.stable.official.ed1daf0bf`）
> 工程根 `F:/Game/aierdengfahuan/godot`
> **真源**：`teamwork/Rank-1/调度任务单-latest.json`（`id=cmd-20261109-085736-022-A1`、task 含 `[ROUND=R16]`），与 `command_center/ai/1/inbox/task_cmd-20261109-085736-022-A1.json` 同 id 同文；**未**读 R15 或更早任务书当作本轮任务。
> 开工另只读：`00-协作契约.md`、`00-群聊总线.md`（各一次，未轮询、未追加）。
> 依据：`capture/r15*.png`（砖块铺满画面 / 透视与天空被压 / 角色偏小）、`Rank-4/GROUND-MATERIAL.md` §4 / §5、本工位 `tune_visual.gd` / `tune_env.gd` / `assemble_r15.gd`（SceneTree pack / owner / CACHE_MODE_IGNORE 回读模式）。
> 本轮**只有本工位写 `godot/scenes/courtyard.tscn`**；其它三路、总线、总纲、契约、台账、别人工位一律未写。

---

## ① 实际交付文件清单

| 类别 | 文件 | 说明 |
|---|---|---|
| 新增脚本 | `godot/scripts/tune_r16.gd` | `extends SceneTree`，幂等；①~⑤ 串行于一个脚本（15716 B） |
| 引擎产物 | `godot/scripts/tune_r16.gd.uid` | 20 B，`--import` 自动生成（非手工） |
| 修改场景 | `godot/scenes/courtyard.tscn` | 23 节点不变；相机 transform / `pixel_size` / 三处 `material_override` 改动，sha256 `1bba3071…` |
| 分档材质副本 1 | `godot/assets/generated/terrain/ground_tile_mat_plate.tres` | `uv1_scale = Vector3(16, 16, 1)`，251 B，Godot `ResourceSaver.save()` 真跑生成 |
| 分档材质副本 2 | `godot/assets/generated/terrain/ground_tile_mat_low.tres` | `uv1_scale = Vector3(3, 3, 1)`，249 B |
| 分档材质副本 3 | `godot/assets/generated/terrain/ground_tile_mat_high.tres` | `uv1_scale = Vector3(2, 2, 1)`，249 B |
| 改动前备份 | `_archived_20261108/courtyard.tscn.bak-pre-r16` | 5112 B；sha256 `709f05bd1e754e0999bfe8a933828c52a3974b83c0643d43476aaa6970642fc6`，与 DONE-R15 记录的 R15 终态逐字一致（改造前源） |
| 抓帧产物 | `capture/r1600000000.png` ~ `r1600000005.png` | 6 帧，各 99739 B；PNG 头 `89504e470d0a1a0a`、IHDR `00000500×000002d0`=1280×720 |
| 抓帧产物 | `capture/r16.wav` | 76844 B，Movie Maker 音频轨 |
| 日志留档 | `teamwork/Rank-1/r16_tune_first_fail.log` | **首次真跑失败** stdout（如实保留，未删除） |
| 日志留档 | `teamwork/Rank-1/r16_tune.log` | 修正后 `--script` 调优自检 + CACHE_MODE_IGNORE 回读 stdout |
| 日志留档 | `teamwork/Rank-1/r16_tune_idempotent.log` | 幂等重跑（复核模式）stdout |
| 日志留档 | `teamwork/Rank-1/r16_gate_import.log` / `r16_gate_checkonly.log` / `r16_gate_quit.log` | 三段门禁 stdout |
| 日志留档 | `teamwork/Rank-1/r16_capture.log` | Movie Maker 抓帧 stdout |
| 交付文档 | `teamwork/Rank-1/DONE-R16.md` | 本文件 |
| 回执 | `teamwork/command_center/ai/1/outbox/cmd-20261109-085736-022-A1.json` | 按本轮 id 写入，只写一份 |

### courtyard.tscn 落盘文本实证（Grep 实读）

```
3 :[ext_resource type="Material" path="res://assets/generated/terrain/ground_tile_mat_plate.tres" id="1_k5tdy"]
6 :[ext_resource type="Material" path="res://assets/generated/terrain/ground_tile_mat_low.tres"   id="2_p30c5"]
8 :[ext_resource type="Material" path="res://assets/generated/terrain/ground_tile_mat_high.tres"  id="3_tihrx"]
55:transform = Transform3D(1, 0, 0, 0, 0.9396926, 0.34202012, 0, -0.34202012, 0.9396926, 0, 8, 15)   # Camera3D
73:material_override = ExtResource("1_k5tdy")     # GroundPlate
78:material_override = ExtResource("2_p30c5")     # TerraceLow
83:material_override = ExtResource("3_tihrx")     # TerraceHigh
88:material_override = SubResource("StandardMaterial3D_p30c5")  # CliffRim（派单未点名，保持原样）
106:pixel_size = 0.05                              # PixelSprite
```

- ② 相机：俯角 `rotation.x` **-30° → -20°**（抬平 10°，地平线回落、天空带与远景重新露出），origin `(0, 9.6, 14.4) → (0, 8, 15)`；绝对目标值赋值。
- ③ 角色：`AnimatedSprite3D.pixel_size` **0.03125 → 0.05**（×1.6）。
- ④ 三档 UV：`ground_material.tres` 的三份副本各设 `uv1_scale` **16 / 3 / 2**（`GROUND-MATERIAL.md` §4「每 tile = 4 米」分档表，第三分量固定 1）；`albedo_texture` 指向 `ground_tile.png`、`texture_filter = 0`、默认白 `albedo_color`、默认 `texture_repeat=true` 四项成组沿用模板；**只改 `material_override`，三个 Mesh 一字未动**。
- `pack()` 从活节点树重序列化：原共用 `ground_material.tres` 的 1 行 ext 被三行分档 ext 取代（另由 Godot 自身带出 `hud.gd` 一行 ext），`[node` 段数保持 **23**，CliffRim 原内嵌材质保留。

---

## ② 真跑实际 stdout、三段门禁逐段 EXIT、节点数 / CACHE_MODE_IGNORE 回读结论

### 2.1 首次真跑（失败，如实登记，未伪造）

命令：`--headless --path <root> --script res://scripts/tune_r16.gd` → **EXIT=1**。完整 stdout 见 `r16_tune_first_fail.log`，关键段：

```
[R16] STEP1 BACKUP 写入 5112 字节 -> F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r16
[R16] STEP2 CACHE_MODE_IGNORE load OK, SceneState node_count(before)=23
[R16] STEP6 MAT 生成: res://assets/generated/terrain/ground_tile_mat_plate.tres uv1_scale=(16.0, 16.0, 1.0) save_err=0
[R16] STEP7 NODE_COUNT before=23 after=23 expected=23 pack_err=0 probe_runtime=25 count_ok=true
[R16] STEP7 SAVE path=res://scenes/courtyard.tscn save_err=0
[R16_VERIFY] UV node=SubViewportContainer/SubViewport/Terrain/GroundPlate res=res://scenes/courtyard.tscn::StandardMaterial3D_k5tdy uv1_scale=(16.0, 16.0, 1.0) path_ok=false uv_ok=true
[R16_VERIFY] UV node=SubViewportContainer/SubViewport/Terrain/TerraceLow  res=res://scenes/courtyard.tscn::StandardMaterial3D_tihrx uv1_scale=(3.0, 3.0, 1.0)   path_ok=false uv_ok=true
[R16_VERIFY] UV node=SubViewportContainer/SubViewport/Terrain/TerraceHigh res=res://scenes/courtyard.tscn::StandardMaterial3D_qkeqr uv1_scale=(2.0, 2.0, 1.0)   path_ok=false uv_ok=true
[R16_VERIFY] CACHE_MODE_IGNORE 磁盘回读 OK=false
[R16] === TUNE R16 END verify_ok=false ===
```

**根因（真跑定位，非猜测）**：把 `ResourceSaver.save()` / `duplicate()` 得到的运行时材质对象直接赋给 `material_override`，`PackedScene.pack()` 会将其序列化为**场景内嵌 `SubResource`**（path 变成 `res://scenes/courtyard.tscn::StandardMaterial3D_xxx`）而非 `ExtResource`；R15 `assemble_r15.gd` 用普通 `load()` 才能写成 `ExtResource`。**修正**：`_ensure_mat()` 存盘后统一用普通 `load(path)` 取「已注册 ResourceCache、`resource_path` 正确」的对象再赋值；`.tres` 已存在则复用不覆盖。修正后重跑通过（§2.2）。备份与三份 `.tres` 首次已生成，未被覆盖。

### 2.2 修正后 `--script` 真跑（调优自检 + 磁盘回读）· EXIT=0

`r16_tune.log` 实际 stdout（原样）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[R16] === TUNE R16 START (cmd-20261109-085736-022-A1) ===
[R16] STEP1 BACKUP 已存在，跳过（幂等，绝不覆盖）: F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r16
[R16] STEP2 CACHE_MODE_IGNORE load OK, SceneState node_count(before)=23
[R16] STEP3 ALREADY_TUNED=false，开始串行调优 ②③④⑤
[R16] STEP4 CAMERA BEFORE rot_x=-19.9999980926514 origin=(0.0, 8.0, 15.0)
[R16] STEP4 CAMERA AFTER  rot_x=-19.9999980926514 origin=(0.0, 8.0, 15.0) target_pitch=-20.0
[R16] STEP5 SPRITE BEFORE pixel_size=0.05000000074506
[R16] STEP5 SPRITE AFTER  pixel_size=0.05000000074506 target=0.05
[R16] STEP6 MAT 复用既有（不覆盖）: res://assets/generated/terrain/ground_tile_mat_plate.tres
[R16] STEP6 MAT 装载缓存对象: res://assets/generated/terrain/ground_tile_mat_plate.tres uv1_scale=(16.0, 16.0, 1.0) resource_path=res://assets/generated/terrain/ground_tile_mat_plate.tres
[R16] STEP6 UV node=SubViewportContainer/SubViewport/Terrain/GroundPlate mat=res://assets/generated/terrain/ground_tile_mat_plate.tres uv1_scale=(16.0, 16.0, 1.0)
[R16] STEP6 MAT 复用既有（不覆盖）: res://assets/generated/terrain/ground_tile_mat_low.tres
[R16] STEP6 MAT 装载缓存对象: res://assets/generated/terrain/ground_tile_mat_low.tres uv1_scale=(3.0, 3.0, 1.0) resource_path=res://assets/generated/terrain/ground_tile_mat_low.tres
[R16] STEP6 UV node=SubViewportContainer/SubViewport/Terrain/TerraceLow mat=res://assets/generated/terrain/ground_tile_mat_low.tres uv1_scale=(3.0, 3.0, 1.0)
[R16] STEP6 MAT 复用既有（不覆盖）: res://assets/generated/terrain/ground_tile_mat_high.tres
[R16] STEP6 MAT 装载缓存对象: res://assets/generated/terrain/ground_tile_mat_high.tres uv1_scale=(2.0, 2.0, 1.0) resource_path=res://assets/generated/terrain/ground_tile_mat_high.tres
[R16] STEP6 UV node=SubViewportContainer/SubViewport/Terrain/TerraceHigh mat=res://assets/generated/terrain/ground_tile_mat_high.tres uv1_scale=(2.0, 2.0, 1.0)
[R16] STEP7 NODE_COUNT before=23 after=23 expected=23 pack_err=0 probe_runtime=25 count_ok=true
[R16] STEP7 SAVE path=res://scenes/courtyard.tscn save_err=0
[R16_VERIFY] NODES SceneState=23 expected=23 ok=true
[R16_VERIFY] CAMERA rot_x=-19.9999980926514 origin=(0.0, 8.0, 15.0) pitch_ok=true origin_ok=true
[R16_VERIFY] SPRITE pixel_size=0.05000000074506 target=0.05 ok=true
[R16_VERIFY] UV node=SubViewportContainer/SubViewport/Terrain/GroundPlate res=res://assets/generated/terrain/ground_tile_mat_plate.tres uv1_scale=(16.0, 16.0, 1.0) path_ok=true uv_ok=true
[R16_VERIFY] UV node=SubViewportContainer/SubViewport/Terrain/TerraceLow res=res://assets/generated/terrain/ground_tile_mat_low.tres uv1_scale=(3.0, 3.0, 1.0) path_ok=true uv_ok=true
[R16_VERIFY] UV node=SubViewportContainer/SubViewport/Terrain/TerraceHigh res=res://assets/generated/terrain/ground_tile_mat_high.tres uv1_scale=(2.0, 2.0, 1.0) path_ok=true uv_ok=true
[R16_VERIFY] CACHE_MODE_IGNORE 磁盘回读 OK=true
[R16] === TUNE R16 END verify_ok=true ===
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

> 说明：`STEP4/STEP5 BEFORE` 已显示目标值，是因为首次真跑（§2.1）已把相机 / pixel_size 写入；本轮为修正材质引用方式的重跑，故 ②③ 为幂等再赋值，值不变。两条 WARNING 为工程既有现象（autoload ChunkManager、退出时 ObjectDB leaked），与 R9~R15 一致，**非 ERROR / 非 SCRIPT ERROR**，如实登记、未冒充全绿。

### 2.3 幂等重跑（复核模式）· EXIT=0

`r16_tune_idempotent.log` 实际 stdout：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[R16] === TUNE R16 START (cmd-20261109-085736-022-A1) ===
[R16] STEP1 BACKUP 已存在，跳过（幂等，绝不覆盖）: F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r16
[R16] STEP2 CACHE_MODE_IGNORE load OK, SceneState node_count(before)=23
[R16] STEP3 ALREADY_TUNED=true，跳过场景写入（尊重并发/既有产出），仅 CACHE_MODE_IGNORE 复核
[R16_VERIFY] NODES SceneState=23 expected=23 ok=true
[R16_VERIFY] CAMERA rot_x=-19.9999980926514 origin=(0.0, 8.0, 15.0) pitch_ok=true origin_ok=true
[R16_VERIFY] SPRITE pixel_size=0.05000000074506 target=0.05 ok=true
[R16_VERIFY] UV node=SubViewportContainer/SubViewport/Terrain/GroundPlate res=res://assets/generated/terrain/ground_tile_mat_plate.tres uv1_scale=(16.0, 16.0, 1.0) path_ok=true uv_ok=true
[R16_VERIFY] UV node=SubViewportContainer/SubViewport/Terrain/TerraceLow res=res://assets/generated/terrain/ground_tile_mat_low.tres uv1_scale=(3.0, 3.0, 1.0) path_ok=true uv_ok=true
[R16_VERIFY] UV node=SubViewportContainer/SubViewport/Terrain/TerraceHigh res=res://assets/generated/terrain/ground_tile_mat_high.tres uv1_scale=(2.0, 2.0, 1.0) path_ok=true uv_ok=true
[R16_VERIFY] CACHE_MODE_IGNORE 磁盘回读 OK=true
[R16] === TUNE R16 END (复核模式) verify_ok=true ===
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

- `ALREADY_TUNED=true` → **跳过场景写入**（并发保护：绝不覆盖并发实例既有产出），仅做 CACHE_MODE_IGNORE 复核；`verify_ok=true`。
- sha256：修正后 `1bba30719581b0964e66c6c014b9aa4cf7df71a8541dd9c2c83f020b03af2ccf`；幂等重跑后 **同一值**，字节级幂等成立；备份 `bak-pre-r16` 始终未被覆盖。

### 2.4 三段门禁（逐段真实 EXIT + stdout + grep）

| 段 | 命令 | **EXIT** |
|---|---|---|
| G1 | `--headless --path F:/Game/aierdengfahuan/godot --import` | **0** |
| G2 | `--headless --path F:/Game/aierdengfahuan/godot --check-only --script res://scripts/tune_r16.gd` | **0** |
| G3 | `--headless --path F:/Game/aierdengfahuan/godot --quit` | **0** |

G1 `r16_gate_import.log` stdout（原日志含 ANSI 颜色控制符，下列为逐行剥离控制符后的可读抄录，行数与内容一致）：

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
[   0% ] update_scripts_classes | Started 正在注册全局类…… (2 steps)
[  33% ] update_scripts_classes |
[ DONE ] update_scripts_classes
[   0% ] loading_editor_layout | Started 正在加载编辑器 (5 steps)
[   0% ] loading_editor_layout | 正在加载编辑器布局……
[  16% ] loading_editor_layout | 正在加载停靠面板……
[ DONE ] loading_editor_layout
```

G2 `r16_gate_checkonly.log` stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

```

> `check-only` 仅解析、未执行 `_initialize()`，**未误触发场景二次修改**；门禁后复查场景 sha256 仍 `1bba3071…`、节点数 23。

G3 `r16_gate_quit.log` stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

> 唯一 WARNING 为工程既有的 `2 ObjectDB instances were leaked`（R9~R15 门禁即有），WARNING 级、非 ERROR、不改退出码（G3 EXIT=0）；按契约 §10 固定 `--headless --quit`，未擅自换 `--quit-after`、不宣称 WARNING 清零。

**grep 结论**：对 `teamwork/Rank-1/r16_*.log` 全部日志执行 `grep -n -E "SCRIPT ERROR|Parse Error|ERROR"` → **`No matches found`（0 条）**。三段门禁日志均 0 条。

### 2.5 节点数 23 / CACHE_MODE_IGNORE 回读结论

| 校验点 | 实际值 | 结论 |
|---|---|---|
| pack 前 `src.get_state().get_node_count()` | 23 | 符合硬门槛 `EXPECTED_NODES=23` |
| pack 后 `packed.get_state().get_node_count()` | 23 | 符合，且与 pack 前一致（`count_ok=true`） |
| pack→instantiate 往返探针运行期整树 | 25 | HUD 实例展开（23 段 + 实例内部 2），属正常实例展开 |
| `grep -c "^\[node "` 落盘文本 | **23** | 与 SceneState 一致 |
| `CACHE_MODE_IGNORE` 磁盘回读 | `NODES SceneState=23 ok=true` | 绕过进程缓存强制重读磁盘 |
| 回读相机 / 角色 / 三档 UV | `pitch_ok=true origin_ok=true`、`ok=true`、三项 `path_ok=true uv_ok=true` | **`OK=true`** |

> `count_ok` 为保存硬门槛：`before==23 && after==23 && before==after` 任一不满足即 `push_error + quit(1)` 中止 `ResourceSaver.save()`（本轮满足，未触发）。脚本用 `CACHE_MODE_IGNORE` 读磁盘最新场景，避免命中进程缓存 / 并发旧副本。

### 2.6 Movie Maker 抓帧 · EXIT=0

命令（任务给定绝对路径 + `.png` 后缀，沿用 R15 已验证形式）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot --write-movie F:/Game/aierdengfahuan/capture/r16.png --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn
```

> 该命令**不带 `--headless`**（Movie Maker 需渲染设备）；末尾带 `res://scenes/courtyard.tscn` 覆盖 `project.godot` 的 `Main.tscn` 主场景，与 R14 / R15 抓帧口径一致。

`r16_capture.log` 实际 stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 616.92 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Ti

Movie Maker mode enabled, recording movie in 1280×720 @ 30 FPS...
--------------------------------------------------------------------------------
Done recording movie at path: F:/Game/aierdengfahuan/capture/r16.png
6 frames at 30 FPS (movie length: 00:00:00:06), recorded in 00:00:01 (100% of real-time speed).
CPU render time: 0.00 seconds (average: 0.02 ms/frame)
GPU render time: 0.00 seconds (average: 0.00 ms/frame)
Encoding time: 0.18 seconds (average: 29.18 ms/frame)
--------------------------------------------------------------------------------
```

- 产出 `r1600000000.png` ~ `r1600000005.png`（6 帧，各 99739 B）+ `r16.wav`（76844 B）；6 张 PNG 头全部 `89504e470d0a1a0a…4948445200000500000002d0` = **1280×720**，签名合法。
- 对照 R15 `r1500000002.png`（74069 B）：R16 帧更大、画面内容确有变化；抓帧日志 `ERROR` grep 0 条。
- 注：任务文字写「抓帧产物 `capture/r16.png`」，`--write-movie` 以该 `.png` 为前缀实际输出 PNG 序列（`r160000000*.png`）+ wav，与 R14 / R15 一致，如实登记。

### 2.7 画面定性（实际查看 `r1600000002.png`，非像素精确测量，**不夸大**）

| 观察项 | R15 `r1500000002.png` | R16 `r1600000002.png` |
|---|---|---|
| 天空 / 远景 | 顶部仅极窄一条蓝带，地面占满画面 | **蓝色天空带明显变宽（约画面上 1/4），地平线与远景交界线清晰露出** |
| 地面砖块 | 砖块巨大、铺满整幅 | **分档 UV 生效：砖块明显变小、近大远小透视正常，密度均匀，不再铺满整幅** |
| 角色 | 蓝红像素骑士偏小 | 放大 1.6 倍后略大，但相对画面占比仍偏小 |
| HUD | 深蓝金边面板「赐福 · 宁姆格福」 | 同左，静态可见 |

- **诚实结论**：派单点名的三个问题（砖块铺满画面 / 透视与天空被压 / 角色偏小）在本轮抓帧中**均有可见改善**：天空带与远景重新露出、砖块分档后大小一致、角色放大生效。但地面仍占画面约 3/4、远处砖块密集呈高频纹理，角色占比仍偏小；BoxMesh 薄侧面纹理拉伸仍可见；整体仍无体积光 / 光尘 / 湿地倒影 / bloom、背景冷蓝，HUD 仍为静态大字。**不宣称 HD-2D 全绿达标**，运行期观感与手感仍需人工试玩 / 后续轮次。

---

## ③ 未完成项与阻塞（如实）

1. **首次真跑失败已如实登记并修复**：`--script` 首跑因运行时材质对象被 `pack()` 内嵌为 `SubResource` 导致 `verify_ok=false` / EXIT=1，未伪造；已定位根因、修正 `_ensure_mat()`（改用普通 `load(path)` 缓存对象）、重跑 EXIT=0 且三项 `path_ok=true`。失败日志 `r16_tune_first_fail.log` 保留留档。
2. **画质未达总纲 HD-2D 强对比**：无体积光 / 光尘 / 倒影 / bloom，背景仍冷蓝；`gl_compatibility`（OpenGL 3.3）后端不支持 Environment glow（承 R14 结论）。属后续轮次 / Rank-4 范围，本轮未做、不冒充全绿。
3. **角色占比仍偏小**：`pixel_size` 已放大 1.6 倍，但抓帧中相对画面仍不算「合理占比」的终态；是否继续放大或配合相机二次构图，需人工审美判断，本轮不擅自反复调。
4. **BoxMesh 薄侧面纹理拉伸**：`GROUND-MATERIAL.md` §4 已知取舍（单一 `uv1_scale` 对六面一视同仁）；三平面映射 `uv1_triplanar` 及移动端性能预算属 Rank-1 后续评估，本轮按「只改 material 不改网格」未启用。
5. **CliffRim 未点名、保持原材质** `SubResource("StandardMaterial3D_p30c5")`：严格守住派单「三个 MeshInstance3D」范围。
6. **HUD 仍静态、未绑数据**：承 R15 结论，`WorldState` 三段式 flag 绑定 / 赐福菜单数据驱动属后续轮次，本轮未写 `hud.gd` / 未改 `hud.tscn`。
7. **既有 WARNING（非本轮引入、非 ERROR）**：`ChunkManager 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`，与 R9~R15 一致，未处理、未冒充全绿。
8. **并发保护执行记录**：开工只读检查 `DONE-R16.md` / `tune_r16.gd` / courtyard.tscn / outbox / receipts → 全部不存在；写 DONE 与回执前再次复核 → 仍不存在、outbox 空、无 receipts 归档 → 本实例自行写入。脚本内 `ALREADY_TUNED` 分支、`CACHE_MODE_IGNORE` 读取、备份/材质「已存在则不覆盖」三重保护，避免与并发主会话互相踩踏；**未覆盖任何并发产出、未写第二份回执**。
9. **按约束未做 / 边界**：默认不刺探（仅本单必要只读，未扫目录 / 未做进度巡检 / 未写探针或 preflight）；零付费 / 零外部素材 / 零外部生成服务；既有件不重做（`tune_visual.gd` / `tune_env.gd` / `assemble_r15.gd` / `ground_material.tres` 仅作参考，未改）；不伪造输出、不冒充全绿；中文 UTF-8、Godot 4.7.2 合法语法；不写其它工位 / 总线 / 总纲 / 契约 / 台账 / `00-汇总.md`；不自行 `git commit` / `git push`；`00-群聊总线.md` 开工只读一次、未追加（本轮无接口变更 / 里程碑 / 阻塞求助 / 回应 @ 事件，且总线不在可写范围）。

---

## 结论

主任务闭环：`tune_r16.gd` 落盘并真跑（首次失败已如实修复后 **EXIT=0**），**节点数 pack 前 23 / pack 后 23 / `CACHE_MODE_IGNORE` 磁盘回读 23**；相机俯角 -30°→-20° + origin(0,8,15)、`PixelSprite.pixel_size` 0.03125→0.05、三份分档材质 `uv1_scale 16/3/2` 以 `ExtResource` 挂载，回读 `pitch_ok / origin_ok / 三项 path_ok / uv_ok` 全部 true、`OK=true`；幂等重跑走复核模式、场景 sha256 字节不变、备份未被覆盖。三段门禁真实 EXIT **0 / 0 / 0**，`grep "SCRIPT ERROR|Parse Error|ERROR"` 全日志 **0 条**。抓帧按绝对路径命令**一次成功产出 6 帧 1280×720 PNG**（`EXIT=0`），画面中天空带与远景重新露出、砖块分档后大小一致、角色放大生效。未完成项（画质未 HD-2D 全绿、角色占比仍偏小、BoxMesh 侧面拉伸、HUD 静态、既有 WARNING）如实登记。

`status=done` 指**本轮构图 / UV 调优主任务闭环**，不代表「画面 HD-2D 全绿达标」或「运行期观感已验收」。

> 证据：`r16_tune_first_fail.log`、`r16_tune.log`、`r16_tune_idempotent.log`、`r16_gate_import.log` / `r16_gate_checkonly.log` / `r16_gate_quit.log`、`r16_capture.log`、`capture/r16000000*.png`、`godot/assets/generated/terrain/ground_tile_mat_*.tres`、`_archived_20261108/courtyard.tscn.bak-pre-r16`、`godot/scenes/courtyard.tscn`。

---

## ④ 回执路由状态（收尾复核追加，不改动上文结论）

- 回执按本轮 id 写入 `command_center/ai/1/outbox/cmd-20261109-085736-022-A1.json` **仅一份**；写入后被调度中枢正常消费，outbox 现为空，归档到 `command_center/dispatcher/receipts/cmd-20261109-085736-022-A1.json`（1903 B，`task_id=cmd-20261109-085736-022-A1` / `ai=1` / `status=done`，内容与本工位写入的逐字一致，`json.load` 解析通过）。
- 按派单「若回执已被送达中枢（outbox 空但 receipts 归档存在）→ 不再写第二份」，**未写第二份回执、未改写归档件**；上文 ① 表格中回执路径为写入时的初始位置，实际路由以本节为准。
