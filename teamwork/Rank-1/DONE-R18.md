# DONE-R18 · Rank-1 引擎架构与渲染（分档接线）

> 命令 `cmd-20261109-095518-171-A1` · `[ROUND=R18]` · AI=1
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（日志版本行 `v4.7.2.stable.official.ed1daf0bf`）
> 工程根 `F:/Game/aierdengfahuan/godot`
> 必读（开工只读）：`godot/scripts/attach_fx_r17.gd`、`godot/scenes/hd2d_fx.tscn`、`godot/scripts/hd2d_fx.gd`（`fx_profile`）、`godot/data/render/quality_preset_desktop.tres` / `quality_preset_mobile.tres`、`Rank-4/HD2D-FX-PLAN.md` §4.2、`00-群聊总线.md`（**开工只读一次，未追加**）。
> 本轮**只有本工位写 `godot/scenes/courtyard.tscn`**；其它工位、总线 / 总纲 / 契约 / 台账一律未写，未自行 git。

---

## ① 实际交付文件清单

| 类别 | 文件 | 说明 |
|---|---|---|
| 新增脚本 | `godot/scripts/wire_profile_r18.gd` | `extends SceneTree`，幂等；备份 → preset 真跑判档 → `CACHE_MODE_IGNORE` 读场景 → 实例化找 `HD2DFX` 写 6 项 `metadata` 接线表 → pack 前/后节点数硬门槛 → pack→instantiate 探针 → save → `CACHE_MODE_IGNORE` 磁盘回读，9 步串行 |
| 引擎产物 | `godot/scripts/wire_profile_r18.gd.uid` | 19 B，`--import` 自动生成（非手工） |
| 修改场景 | `godot/scenes/courtyard.tscn` | **节点数保持 24**，sha256 `461f19c74686acb9fd92aa4ed0aaa023d60fad604d874684634cecb64261f5fa`；仅在 R17 的 `HD2DFX` 实例段下新增 **6 行 `metadata/fx_profile_*`**，未增/删任何节点、未改既有段 |
| 改动前备份 | `_archived_20261108/courtyard.tscn.bak-pre-r18` | 5736 B；sha256 `306b2467ca0a6290639693b1c7e2b4b66f1b55dada2d05ad0bf8d08ff2300fe3`，**与 DONE-R17.md 记录的 R17 终态场景 sha256 逐字一致**（改造前源，未被覆盖）；`bak-pre-r17` = `21fce538…`（R16 终态）亦未被覆盖 |
| 交付文档 | `teamwork/Rank-1/FX-PROFILE-WIRING.md` | 桌面档 `fx_profile=desktop` / 移动档 `fx_profile=mobile` 的**切换时机与调用方式方案**（给方案即可，运行时自动切换本轮未落盘） |
| 交付文档 | `teamwork/Rank-1/DONE-R18.md` | 本文件 |
| 抓帧产物 | `capture/r18_scene00000000.png` ~ `r18_scene00000005.png` | 6 帧，117572~117779 B（各帧字节不同=逐帧动画生效）；PNG 头 `89504e470d0a1a0a…49484452 00000500 000002d0` = **1280×720** |
| 抓帧产物 | `capture/r18_scene.wav` | 76844 B，Movie Maker 音频轨 |
| 真跑日志 | `capture/r18_wire_run.log` / `r18_wire_idempotent.log` | 首跑 / 幂等复核 实际 stdout |
| 门禁日志 | `capture/r18_gate_import.log` / `r18_gate_checkonly.log` / `r18_gate_quit.log` / `r18_capture.log` | 三段门禁 + 抓帧 实际 stdout |
| 回执 | `teamwork/command_center/ai/1/outbox/cmd-20261109-095518-171-A1.json` | 按本轮 id 写入，只写一份 |

### courtyard.tscn 落盘文本实证（Grep 实读，第 124–131 行）

```
124:[node name="HD2DFX" type="CanvasLayer" parent="SubViewportContainer/SubViewport" unique_id=80156914 instance=ExtResource("8_p30c5")]
125-layer = 10
126-metadata/fx_profile_source = "res://data/render/quality_preset_desktop.tres"
127-metadata/fx_profile_active = "desktop"
128-metadata/fx_profile_desktop_preset = "res://data/render/quality_preset_desktop.tres"
129-metadata/fx_profile_mobile_preset = "res://data/render/quality_preset_mobile.tres"
130-metadata/fx_profile_desktop_value = "desktop"
131-metadata/fx_profile_mobile_value = "mobile"
```

- `HD2DFX` 仍是 `instance=ExtResource("8_p30c5")` 占位的 `CanvasLayer`（`layer=10`），**节点数不变**；6 行 `metadata` 是实例根的属性覆盖，非新增节点。
- 接线表把「档位 → quality preset 路径 → fx_profile 值」绑定：`fx_profile_source` 为运行时读取入口（默认桌面），`*_preset` 两档路径，`*_value` 两档取值（桌面 `desktop` 四项全开 / 移动 `mobile` 四项全关），`fx_profile_active` 为当前档（默认 `desktop`）。切换时机与调用方式见 `FX-PROFILE-WIRING.md`。
- `fx_profile` 本体在 `hd2d_fx.tscn` 的 4 个子节点所挂 `hd2d_fx.gd` 上（既有件），本轮**未改写运行中脚本 / 未改子场景 / 未增删节点**。
- `grep -c "^\[node "` 落盘文本 = **24**，与 `SceneState.get_node_count()` 一致。

---

## ② 自检（真跑实际 stdout、节点数、CACHE_MODE_IGNORE 回读、门禁、抓帧）

### 2.1 `wire_profile_r18.gd` 首跑 `--script` · **EXIT=0**

命令：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/wire_profile_r18.gd`

`capture/r18_wire_run.log` 实际 stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[R18] === WIRE PROFILE R18 START (cmd-20261109-095518-171-A1) ===
[R18] STEP1 BACKUP 写入 5736 字节 -> F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r18
[R18] STEP2 PRESET desktop.low_resolution_size=(640, 360) mobile=(480, 270) desktop_gt_mobile=true
[R18] STEP2 档位→fx_profile 映射: desktop->desktop / mobile->mobile（§4.2 冻结口径）
[R18] STEP3 CACHE_MODE_IGNORE load OK, SceneState node_count(before)=24
[R18] STEP4 HD2DFX name=HD2DFX class=CanvasLayer layer=10 scene_file_path=res://scenes/hd2d_fx.tscn
[R18] STEP5 set_meta 写入 6 项接线: fx_profile_source=res://data/render/quality_preset_desktop.tres | fx_profile_active=desktop | fx_profile_desktop_preset=res://data/render/quality_preset_desktop.tres | fx_profile_mobile_preset=res://data/render/quality_preset_mobile.tres | fx_profile_desktop_value=desktop | fx_profile_mobile_value=mobile
[R18] STEP6 scene_file_path / owner 链就绪（跳过实例化节点，不展开）
[R18] STEP7 NODE_COUNT before=24 after=24 expected=24 pack_err=0 count_ok=true
[R18] STEP7 PACK_PROBE meta_ok=true instance=true children_ok=true runtime_nodes=30 probe_ok=true
[R18] STEP8 SAVE_OK path=res://scenes/courtyard.tscn save_err=0
==== [R18 回读 CACHE_MODE_IGNORE] START ====
[R18_VERIFY] readback class=PackedScene resource_path=res://scenes/courtyard.tscn SceneState_nodes=24
[R18_VERIFY] ① readback_not_null_and_PackedScene PASS=true | class=PackedScene
[R18_VERIFY] ② SceneState_node_count_24 PASS=true | nodes=24 expected=24
[R18_VERIFY] ③ FX_instance_present PASS=true | path=SubViewportContainer/SubViewport/HD2DFX found=true
[R18_VERIFY] ④ FX_root_CanvasLayer_layer10 PASS=true | class=CanvasLayer layer=10 expected=10
[R18_VERIFY] ⑤ FX_is_instance_placeholder PASS=true | scene_file_path=res://scenes/hd2d_fx.tscn
[R18_VERIFY] ⑥ wiring[fx_profile_source] PASS=true | actual=res://data/render/quality_preset_desktop.tres expected=res://data/render/quality_preset_desktop.tres
[R18_VERIFY] ⑥ wiring[fx_profile_active] PASS=true | actual=desktop expected=desktop
[R18_VERIFY] ⑥ wiring[fx_profile_desktop_preset] PASS=true | actual=res://data/render/quality_preset_desktop.tres expected=res://data/render/quality_preset_desktop.tres
[R18_VERIFY] ⑥ wiring[fx_profile_mobile_preset] PASS=true | actual=res://data/render/quality_preset_mobile.tres expected=res://data/render/quality_preset_mobile.tres
[R18_VERIFY] ⑥ wiring[fx_profile_desktop_value] PASS=true | actual=desktop expected=desktop
[R18_VERIFY] ⑥ wiring[fx_profile_mobile_value] PASS=true | actual=mobile expected=mobile
[R18_VERIFY] ⑦ script_attached_all_4 PASS=true | FXReflection:script=res://scripts/hd2d_fx.gd fx_profile=desktop | FXGodRays:script=res://scripts/hd2d_fx.gd fx_profile=desktop | FXMotes:script=res://scripts/hd2d_fx.gd fx_profile=desktop | FXBloom:script=res://scripts/hd2d_fx.gd fx_profile=desktop
[R18_VERIFY] ⑧ fx_profile_default_desktop_all_4 PASS=true | FXReflection:script=res://scripts/hd2d_fx.gd fx_profile=desktop | FXGodRays:script=res://scripts/hd2d_fx.gd fx_profile=desktop | FXMotes:script=res://scripts/hd2d_fx.gd fx_profile=desktop | FXBloom:script=res://scripts/hd2d_fx.gd fx_profile=desktop
[R18_VERIFY] ⑨ preset_resolution_gt_and_mapping PASS=true | desktop=(640, 360) mobile=(480, 270) / desktop_value=desktop mobile_value=mobile
[R18_VERIFY] RUNTIME_NODES=30（实例展开后整树，含 HUD 内部 2 + HD2DFX 内部 4）
[R18_VERIFY] VERIFY_SUMMARY pass=14 fail=0 OK=true
==== [R18 回读 CACHE_MODE_IGNORE] END ====
[R18] === WIRE PROFILE R18 END verify_ok=true ===
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

> 2 条 WARNING 为工程既有现象（autoload `ChunkManager`、`ObjectDB leaked`），与 R9~R17 一致，**非 ERROR / 非 SCRIPT ERROR**，如实登记、未冒充全绿。

### 2.2 幂等重跑 · **EXIT=0**（`capture/r18_wire_idempotent.log`）

```
[R18] === WIRE PROFILE R18 START (cmd-20261109-095518-171-A1) ===
[R18] STEP1 BACKUP 已存在，跳过（幂等，绝不覆盖）: F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r18
[R18] STEP2 PRESET desktop.low_resolution_size=(640, 360) mobile=(480, 270) desktop_gt_mobile=true
[R18] STEP3 CACHE_MODE_IGNORE load OK, SceneState node_count(before)=24
[R18] STEP4 HD2DFX name=HD2DFX class=CanvasLayer layer=10 scene_file_path=res://scenes/hd2d_fx.tscn
[R18] STEP5 ALREADY_WIRED=true，6 项接线值已全部到位，跳过写盘（复核模式）
[R18] STEP6 scene_file_path / owner 链就绪（跳过实例化节点，不展开）
[R18] STEP7 NODE_COUNT before=24 after=24 expected=24 pack_err=0 count_ok=true
[R18] STEP7 PACK_PROBE meta_ok=true instance=true children_ok=true runtime_nodes=30 probe_ok=true
[R18] STEP8 SKIP_SAVE（复核模式，不写盘）
==== [R18 回读 CACHE_MODE_IGNORE] START ====
  ... （14 项逐项 PASS，与 2.1 逐字一致）
[R18_VERIFY] VERIFY_SUMMARY pass=14 fail=0 OK=true
==== [R18 回读 CACHE_MODE_IGNORE] END ====
[R18] === WIRE PROFILE R18 END verify_ok=true ===
```

- `ALREADY_WIRED=true` → **跳过写盘**（并发保护，绝不覆盖既有产出），仅 `CACHE_MODE_IGNORE` 复核；备份「已存在则不覆盖」。
- 重跑前 / 后场景 sha256 均 `461f19c7…`、备份 sha256 均 `306b2467…` → **字节级幂等成立，备份未被覆盖**。

### 2.3 节点数 / `CACHE_MODE_IGNORE` 回读结论

| 校验点 | 实际值 | 结论 |
|---|---|---|
| pack 前 `src.get_state().get_node_count()` | **24** | 符合 `EXPECTED_NODES=24` |
| pack 后 `packed.get_state().get_node_count()` | **24** | 符合 `after == before == 24`（本轮不增删节点） |
| `count_ok`（保存硬门槛） | `before==24 && after==24 && after==before` → **true** | 任一不符即 `push_error + quit(1)` **中止 `ResourceSaver.save()`**（本轮满足，未触发） |
| pack→instantiate 往返探针 | `probe_ok=true`、`meta_ok=true`、`instance=true`、`runtime_nodes=30` | **接线 metadata 确实被 pack 保留**（核心前提）、HD2DFX 仍是 instance 占位、4 子节点完整 |
| `grep -c "^\[node "` 落盘文本 | **24** | 与 SceneState 一致 |
| `CACHE_MODE_IGNORE` 磁盘回读 | `SceneState_nodes=24`、`VERIFY_SUMMARY pass=14 fail=0 OK=true` | 绕过进程缓存强制重读磁盘 |
| 回读 6 项接线值 | `fx_profile_source` / `fx_profile_active` / `fx_profile_desktop_preset` / `fx_profile_mobile_preset` / `fx_profile_desktop_value` / `fx_profile_mobile_value` 逐项 `PASS=true` | **接线值全部可回读校验** |
| preset 真跑值 | desktop `(640,360)` > mobile `(480,270)`；映射 `desktop->desktop` / `mobile->mobile` | 接线值来源真实、非臆造（§4.2 冻结口径） |
| R17 结构未破坏 | 根 CanvasLayer / layer=10 / instance 占位 / 4 子节点脚本已挂 / `fx_profile` 默认 desktop 4/4 | 全部 PASS |

> 脚本用 `CACHE_MODE_IGNORE` 读磁盘最新场景，避免命中进程缓存 / 并发旧副本；STEP6 沿用 R17 的 `scene_file_path` 标记 + `_reset_owner`（跳过实例化节点），确保 pack 把 HD2DFX 折叠成 `instance` 占位且**节点数不变**。接线只写实例根 `metadata`，不改 owner 结构语义、不改运行中 `hd2d_fx.gd`。

### 2.4 三段门禁（逐段真实 EXIT + stdout）

| 段 | 命令 | **EXIT** |
|---|---|---|
| G1 | `--headless --path F:/Game/aierdengfahuan/godot --import` | **0** |
| G2 | `--headless --path F:/Game/aierdengfahuan/godot --check-only --script res://scripts/wire_profile_r18.gd` | **0** |
| G3 | `--headless --path F:/Game/aierdengfahuan/godot --quit` | **0** |

G1 `r18_gate_import.log` stdout（实际，含扫描进度行）：

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

G2 `r18_gate_checkonly.log` stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

```

> `check-only` 仅解析、未执行 `_initialize()`，**未误触发场景二次修改**；门禁后复查场景 sha256 仍 `461f19c7…`、节点数 24。

G3 `r18_gate_quit.log` stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

> 唯一 WARNING 为工程既有的 `2 ObjectDB instances were leaked`（R9~R17 门禁即有），WARNING 级、非 ERROR、不改退出码（G3 EXIT=0）；按契约 §10 固定 `--headless --quit`，未擅自换 `--quit-after`、不宣称 WARNING 清零。

`grep -n -E 'SCRIPT ERROR|ERROR' capture/r18_*.log` 实际输出：

```
No matches found (0 条)
```

### 2.5 Movie Maker 抓帧 · **EXIT=0**

命令（任务给定**绝对路径 + `.png`** 后缀，沿用 R14~R17 口径；**不带 `--headless`**，Movie Maker 需渲染设备）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot --write-movie F:/Game/aierdengfahuan/capture/r18_scene.png --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn
```

`capture/r18_capture.log` 实际 stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 616.92 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Ti

Movie Maker mode enabled, recording movie in 1280×720 @ 30 FPS...
--------------------------------------------------------------------------------
Done recording movie at path: F:/Game/aierdengfahuan/capture/r18_scene.png
6 frames at 30 FPS (movie length: 00:00:00:06), recorded in 00:00:00 (100% of real-time speed).
CPU render time: 0.00 seconds (average: 0.01 ms/frame)
GPU render time: 0.00 seconds (average: 0.00 ms/frame)
Encoding time: 0.17 seconds (average: 29.16 ms/frame)
--------------------------------------------------------------------------------
```

- 产出 `r18_scene00000000.png` ~ `r18_scene00000005.png`（**6 帧**）+ `r18_scene.wav`；6 张 PNG 前 24 字节均为 `89 50 4e 47 0d 0a 1a 0a 00 00 00 0d 49 48 44 52 00 00 05 00 00 00 02 d0` = PNG 签名合法、**1280×720**；6 帧字节各不相同（逐帧动画生效，与 R17 一致）。抓帧日志 `SCRIPT ERROR|ERROR` grep **0 条**。
- 注：任务文字写「抓帧 `capture/r18_scene.png`」，`--write-movie` 以该 `.png` 为前缀实际输出 PNG 序列（`r18_scene0000000*.png`）+ wav，与 R14 / R15 / R16 / R17 一致，如实登记。

---

## ③ 未完成项与阻塞（如实）

1. **运行时自动切换逻辑未落盘实现**：本轮只建立并验证「接线表数据」（6 项 `metadata`，`CACHE_MODE_IGNORE` 回读 14 项全 PASS）；任务明确「切换时机与调用方式（给方案即可）」，方案见 `FX-PROFILE-WIRING.md` §3/§4。未加 autoload、未新增节点、未改运行中 `hd2d_fx.gd`。**未在运行期真跑切档，不宣称已实现 / 已验收运行时切换**。
2. **冻结件未改**：`quality_preset_desktop.tres` / `quality_preset_mobile.tres` / `render_profiles.tres` 归 Rank-1 装配权且需总指挥裁决（HD2D-FX-PLAN §4.3/§4.4），本轮**只读其 `low_resolution_size` 判档，零写入**；R17 的 4 个 FX 子节点脚本默认 `fx_profile=desktop` 未改写。
3. **§4.3「移动档降级而非全关」/ §4.4「逐层 visible 接线」为待裁决建议**：本方案沿用 §4.2 冻结口径（移动档 `fx_profile=mobile` 四项全关），未擅自实现降级或逐层读字段设 `visible`。
4. **既有 WARNING（非本轮引入、非 ERROR）**：`ChunkManager 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`，与 R9~R17 一致，未处理、未冒充全绿。
5. **R17 遗留画质 / 交互承前**：倒影不清晰、四项是 2D 程序化近似非原生后处理、光尘覆盖 HUD、HUD 仍静态未绑数据、地面占画面约 3/4 等，本轮未扩展、不擅自反复调构图；运行期观感 / 手感仍需人工试玩。
6. **抓帧仅验证「抓帧成功 / PNG 合法 / 节点数」**：本轮未做 R17↔R18 像素级画面差异验收，不宣称画面 HD-2D 全绿达标。
7. **并发保护执行记录**：开工只读检查 `bak-pre-r18` / `DONE-R18.md` / `FX-PROFILE-WIRING.md` / `wire_profile_r18.gd` / outbox 本轮回执 / receipts 归档 → **全部不存在**，写 DONE 与回执前再次复核 → 仍不存在、outbox 空、无同 id 归档 → 本实例自行写入；脚本内「备份已存在不覆盖」+「`ALREADY_WIRED` 跳过写盘」+ `CACHE_MODE_IGNORE` 读取三重保护，避免与并发主会话互相踩踏；**未覆盖任何并发产出、未写第二份回执**。
8. **按约束未做 / 边界**：默认不刺探（仅本单必要只读，未扫无关目录 / 未做进度巡检）；零付费 / 零外部素材 / 零外部生成服务 / 零插件；既有件不重做（`hd2d_fx.tscn` / `hd2d_fx.gd` / `attach_fx_r17.gd` / `assemble_r15.gd` / `tune_r16.gd` / `verify_fx_profile.gd` 仅作参考，未改）；不伪造输出、不冒充全绿；中文 UTF-8、Godot 4.7.2 合法语法（`--check-only` EXIT=0）；不写其它工位 / 总线 / 总纲 / 契约 / 台账；不自行 `git commit` / `git push`；`00-群聊总线.md` 开工只读一次、未追加（本轮无接口变更 / 里程碑 / 阻塞求助 / 回应 @ 事件，且总线不在可写范围）。

---

## 结论

主任务闭环：`wire_profile_r18.gd` 落盘并真跑（**EXIT=0 / verify_ok=true**），备份 `bak-pre-r18`（= R17 终态）生成且未被覆盖；在 `HD2DFX` 实例根写入 6 项 `metadata/fx_profile_*` 接线表，把桌面/移动画质档（`quality_preset_desktop.tres` 640×360 / `quality_preset_mobile.tres` 480×270）与 `fx_profile`（桌面 `desktop` 四项全开 / 移动 `mobile` 四项全关）建立**可切换接线**；**节点数 pack 前 24 / pack 后 24 / `CACHE_MODE_IGNORE` 磁盘回读 24**，回读 **14 项全 PASS**（含 6 项接线值逐项回读、preset 真跑判档、R17 结构未破坏），`OK=true`；幂等重跑走复核模式、`SKIP_SAVE`、场景与备份 sha256 字节不变。三段门禁真实 EXIT **0 / 0 / 0**，`grep "SCRIPT ERROR|ERROR"` 全 r18 日志 **0 条**。按任务给定绝对路径命令抓帧 **EXIT=0**，产出 6 帧 1280×720 PNG + wav。切换时机与调用方式方案见 `FX-PROFILE-WIRING.md`。未完成项（运行时自动切换未落盘、冻结件未改、§4.3/§4.4 待裁决建议、既有 WARNING、R17 遗留画质、并发保护记录）如实登记。

`status=done` 指**本轮分档接线与验证主任务闭环**，**不代表**「运行时自动切换已实现」或「画面 HD-2D 全绿达标 / 运行期观感已验收」。

> 证据：`capture/r18_wire_run.log`、`r18_wire_idempotent.log`、`r18_capture.log`、`r18_gate_*.log`、`capture/r18_scene0000000*.png`、`capture/r18_scene.wav`、`_archived_20261108/courtyard.tscn.bak-pre-r18`、`godot/scenes/courtyard.tscn`、`godot/scripts/wire_profile_r18.gd`、`teamwork/Rank-1/FX-PROFILE-WIRING.md`。

---

## ④ 回执

- 按本轮 id 写入 `teamwork/command_center/ai/1/outbox/cmd-20261109-095518-171-A1.json` **仅一份**，内容：
  `{"task_id":"cmd-20261109-095518-171-A1","ai":1,"status":"done","result":"见 DONE-R18.md：wire_profile_r18.gd 真跑 EXIT=0/verify_ok=true，HD2DFX 实例根写入 6 项 metadata/fx_profile_* 接线表（桌面 quality_preset_desktop.tres 640x360→fx_profile=desktop 四项全开 / 移动 quality_preset_mobile.tres 480x270→mobile 四项全关），节点数 pack 前24/pack 后24/CACHE_MODE_IGNORE 回读24、回读14项全 PASS（含6项接线值逐项回读）；幂等重跑 ALREADY_WIRED/SKIP_SAVE、字节级一致、备份(=R17终态)未覆盖；三段门禁 EXIT 0/0/0、SCRIPT ERROR|ERROR grep 0 条；Movie Maker 抓帧 EXIT=0 产出6帧1280x720 PNG+wav；切换时机/调用方式方案见 FX-PROFILE-WIRING.md；未完成项：运行时自动切换未落盘(给方案即可)、冻结件未改、§4.3/§4.4 待裁决、既有WARNING，详见 DONE-R18.md ③。"}`
- 写入前复核 outbox 为空、无同 id receipts 归档；未写第二份回执、未改写任何归档件。

---

## ⑤ 回执路由状态（收尾复核追加，不改动上文结论）

- 回执按本轮 id 写入 `command_center/ai/1/outbox/cmd-20261109-095518-171-A1.json` **仅一份**；写入后被调度中枢**即时消费**，outbox 现为空，归档到 `command_center/dispatcher/receipts/cmd-20261109-095518-171-A1.json`（896 B，`task_id=cmd-20261109-095518-171-A1` / `ai=1` / `status=done`，`json.load` 解析通过，字段与本工位写入的逐字一致）。
- 按派单「若回执已被送达中枢（outbox 空但 receipts 归档存在）→ 不再写第二份」，**未写第二份回执、未改写归档件**；上文 ④ 中的回执路径为写入时的初始位置，实际路由以本节为准。
- `dispatcher/receipts/` 不在本轮可写范围，全程未改写任何归档件，未在 outbox 重复投递。
