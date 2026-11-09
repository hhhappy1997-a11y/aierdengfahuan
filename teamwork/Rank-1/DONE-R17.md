# DONE-R17 · Rank-1 引擎架构与渲染

> 命令 `cmd-20261109-093050-714-A1` · `[ROUND=R17]` · AI=1
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（日志版本行 `v4.7.2.stable.official.ed1daf0bf`）
> 工程根 `F:/Game/aierdengfahuan/godot`
> 必读（开工只读）：`godot/scenes/hd2d_fx.tscn`、`Rank-4/HD2D-FX-PLAN.md`、`godot/scripts/assemble_r15.gd` / `tune_r16.gd`（SceneTree 追加式模式）、`00-群聊总线.md`（**开工只读一次，未追加**）。
> 依据：`capture/r16*.png`（R16 画面基线）、`Rank-4/HD2D-FX-PLAN.md` §2 / §3 / §4.2 / §6、`godot/scripts/hd2d_fx.gd`（fx_profile 默认 desktop 四项全开）。
> 本轮**只有本工位写 `godot/scenes/courtyard.tscn`**；其它工位、总线 / 总纲 / 契约 / 台账一律未写，未自行 git。

---

## ① 实际交付文件清单

| 类别 | 文件 | 说明 |
|---|---|---|
| 新增脚本 | `godot/scripts/attach_fx_r17.gd` | `extends SceneTree`，幂等；备份 → 挂载 → owner 重设 → 节点数硬门槛 → 保存 → `CACHE_MODE_IGNORE` 回读，9 步串行 |
| 引擎产物 | `godot/scripts/attach_fx_r17.gd.uid` | 19 B，`--import` 自动生成（非手工） |
| 修改场景 | `godot/scenes/courtyard.tscn` | **节点数 23 → 24**，5736 B；仅新增 1 个 `HD2DFX` 实例段 + 1 行 `ExtResource`，sha256 `306b2467ca0a6290639693b1c7e2b4b66f1b55dada2d05ad0bf8d08ff2300fe3` |
| 改动前备份 | `_archived_20261108/courtyard.tscn.bak-pre-r17` | 5511 B；sha256 `21fce538b4d14d465fb4f2cb267684aa1e88809cbcba2594fc5e798adee5d3b8`，**与 `DONE-R16.md` §5.4 记录的 R16 纠偏后场景 sha256 逐字一致**（改造前源，未被覆盖） |
| 抓帧产物 | `capture/r1700000000.png` ~ `r1700000005.png` | 6 帧，117841~118164 B；PNG 头 `89504e470d0a1a0a`、IHDR `00000500×000002d0` = **1280×720** |
| 抓帧产物 | `capture/r17.wav` | 76844 B，Movie Maker 音频轨 |
| 分析产物 | `capture/r17_diff_crop.png` | 本地 python/PIL 生成的 R16(左)/R17(右) 局部放大对照图，用于逐项判断光效可见性（零外部服务） |
| 真跑日志 | `capture/r17_pre_import.log` / `r17_attach_run.log` / `r17_attach_idempotent.log` / `r17_capture.log` | `--import` 前置 / 首跑 / 幂等重跑 / 抓帧 实际 stdout |
| 门禁日志 | `capture/r17_gate_import.log` / `r17_gate_import_clean.log` / `r17_gate_checkonly.log` / `r17_gate_quit.log` / `r17_gate_summary.log` | 三段门禁 stdout（clean 版为剥离 ANSI 控制符的可读抄录）+ grep 汇总 |
| 交付文档 | `teamwork/Rank-1/DONE-R17.md` | 本文件 |
| 回执 | `teamwork/command_center/ai/1/outbox/cmd-20261109-093050-714-A1.json` | 按本轮 id 写入，只写一份 |

### courtyard.tscn 落盘文本实证（Grep 实读）

```
11 :[ext_resource type="PackedScene" path="res://scenes/hd2d_fx.tscn" id="8_p30c5"]
123:[node name="HD2DFX" type="CanvasLayer" parent="SubViewportContainer/SubViewport" unique_id=80156914 instance=ExtResource("8_p30c5")]
```

- `HD2DFX` 是 `CanvasLayer`（`layer=10`，与既有 `FXLayer` 冻结值一致），**作为 `SubViewportContainer/SubViewport` 的直接子节点**，写成 `instance=ExtResource(...)` 占位 → 主场景只 +1 个 `[node]` 段。
- `load("res://scenes/hd2d_fx.tscn").instantiate()` 展开后 4 个子节点 `FXReflection` / `FXGodRays` / `FXMotes` / `FXBloom` 各挂 `res://scripts/hd2d_fx.gd`，`fx_profile` 沿用脚本默认 `"desktop"`（四项全开），本脚本**未改写运行中脚本、未改档位**。
- `grep -c "^\[node "` 落盘文本 = **24**，与 `SceneState.get_node_count()` 一致。
- owner 链 `_reset_owner(root, root)` 跳过 `scene_file_path != ""` 的实例化节点（既有 `Hud` 与本轮 `HD2DFX`），未递归进实例内部、未展开成普通节点段；`HD2DFX.owner` 显式设为场景根 `Courtyard`。

---

## ② 真跑实际 stdout、节点数 / CACHE_MODE_IGNORE 回读、抓帧与画面差异、三段门禁

### 2.1 `attach_fx_r17.gd` 首跑 `--script` · **EXIT=0**

命令：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/attach_fx_r17.gd`

`capture/r17_attach_run.log` 实际 stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[R17] === ATTACH FX R17 START (cmd-20261109-093050-714-A1) ===
[R17] STEP1 BACKUP 写入 5511 字节 -> F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r17
[R17] STEP2 CACHE_MODE_IGNORE load OK, SceneState node_count(before)=23
[R17] STEP3 接入点 OK path=SubViewportContainer/SubViewport class=SubViewport
[R17] STEP4 ALREADY_ATTACHED=false，开始挂载 FX 实例
[R17] STEP5 FX 实例已挂入 SubViewportContainer/SubViewport name=HD2DFX class=CanvasLayer scene_file_path=res://scenes/hd2d_fx.tscn
[R17] STEP5 FX 默认 fx_profile=desktop 四项全开（沿用脚本默认值）
[R17] STEP6 owner 链重设完成（跳过实例化节点）
[R17] STEP7 NODE_COUNT before=23 after=24 expected_before=23 expected_after=24 pack_err=0 probe_runtime=30 probe_ok=true count_ok=true
[R17] STEP8 SAVE_OK path=res://scenes/courtyard.tscn save_err=0
==== [R17 回读 CACHE_MODE_IGNORE] START ====
[R17_VERIFY] readback class=PackedScene resource_path=res://scenes/courtyard.tscn SceneState_nodes=24
[R17_VERIFY] ① readback_not_null_and_PackedScene PASS=true | class=PackedScene
[R17_VERIFY] ② FX_instance_present PASS=true | path=SubViewportContainer/SubViewport/HD2DFX found=true
[R17_VERIFY] ③ FX_root_is_CanvasLayer PASS=true | name=HD2DFX class=CanvasLayer layer=10 (expected=10)
[R17_VERIFY] ④ FX_is_instance_placeholder PASS=true | scene_file_path=res://scenes/hd2d_fx.tscn
[R17_VERIFY] ⑤ script_attached_all_4 PASS=true | FXReflection:script=res://scripts/hd2d_fx.gd | FXGodRays:script=res://scripts/hd2d_fx.gd | FXMotes:script=res://scripts/hd2d_fx.gd | FXBloom:script=res://scripts/hd2d_fx.gd
[R17_VERIFY] ⑥ fx_profile_desktop_all_on PASS=true | FXReflection:desktop | FXGodRays:desktop | FXMotes:desktop | FXBloom:desktop
[R17_VERIFY] ⑦ SceneState_node_count_24 PASS=true | nodes=24 expected=24
[R17_VERIFY] RUNTIME_NODES=30（实例展开后整树，含 HUD 内部 2 + HD2DFX 内部 4）
[R17_VERIFY] VERIFY_SUMMARY pass=7 fail=0 OK=true
==== [R17 回读 CACHE_MODE_IGNORE] END ====
[R17] === ATTACH FX R17 END verify_ok=true ===
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

> 2 条 WARNING 为工程既有现象（autoload `ChunkManager`、退出时 `ObjectDB leaked`），与 R9~R16 一致，**非 ERROR / 非 SCRIPT ERROR**，如实登记、未冒充全绿。

### 2.2 幂等重跑 · **EXIT=0**（`capture/r17_attach_idempotent.log`）

```
[R17] === ATTACH FX R17 START (cmd-20261109-093050-714-A1) ===
[R17] STEP1 BACKUP 已存在，跳过（幂等，绝不覆盖）: F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r17
[R17] STEP2 CACHE_MODE_IGNORE load OK, SceneState node_count(before)=24
[R17] STEP3 接入点 OK path=SubViewportContainer/SubViewport class=SubViewport
[R17] STEP4 ALREADY_ATTACHED=true，跳过场景写入（尊重并发/既有产出），仅 CACHE_MODE_IGNORE 复核
==== [R17 回读 CACHE_MODE_IGNORE] START ====
[R17_VERIFY] ① readback_not_null_and_PackedScene PASS=true | class=PackedScene
[R17_VERIFY] ② FX_instance_present PASS=true | path=SubViewportContainer/SubViewport/HD2DFX found=true
[R17_VERIFY] ③ FX_root_is_CanvasLayer PASS=true | name=HD2DFX class=CanvasLayer layer=10 (expected=10)
[R17_VERIFY] ④ FX_is_instance_placeholder PASS=true | scene_file_path=res://scenes/hd2d_fx.tscn
[R17_VERIFY] ⑤ script_attached_all_4 PASS=true | FXReflection:script=res://scripts/hd2d_fx.gd | FXGodRays:script=res://scripts/hd2d_fx.gd | FXMotes:script=res://scripts/hd2d_fx.gd | FXBloom:script=res://scripts/hd2d_fx.gd
[R17_VERIFY] ⑥ fx_profile_desktop_all_on PASS=true | FXReflection:desktop | FXGodRays:desktop | FXMotes:desktop | FXBloom:desktop
[R17_VERIFY] ⑦ SceneState_node_count_24 PASS=true | nodes=24 expected=24
[R17_VERIFY] RUNTIME_NODES=30（实例展开后整树，含 HUD 内部 2 + HD2DFX 内部 4）
[R17_VERIFY] VERIFY_SUMMARY pass=7 fail=0 OK=true
==== [R17 回读 CACHE_MODE_IGNORE] END ====
[R17] === ATTACH FX R17 END (复核模式) verify_ok=true ===
```

- `ALREADY_ATTACHED=true` → **跳过场景写入**（并发保护，绝不覆盖既有产出），仅 `CACHE_MODE_IGNORE` 复核。
- 重跑前 / 后场景 sha256 均 `306b2467…`、备份 sha256 均 `21fce538…` → **字节级幂等成立，备份未被覆盖**。

### 2.3 节点数 23→24 / `CACHE_MODE_IGNORE` 回读结论

| 校验点 | 实际值 | 结论 |
|---|---|---|
| pack 前 `src.get_state().get_node_count()` | **23** | 符合 `EXPECTED_BEFORE=23` |
| pack 后 `packed.get_state().get_node_count()` | **24** | 符合 `EXPECTED_AFTER=24`，且 `after == before + 1` |
| `count_ok`（保存硬门槛） | `before==23 && after==24 && after==before+1` → **true** | 任一不符即 `push_error + quit(1)` **中止 `ResourceSaver.save()`**（本轮满足，未触发） |
| pack→instantiate 往返探针 | `probe_ok=true`、`probe_runtime=30` | FX 实例能展开、4 个子节点完整、根为 CanvasLayer、实例标记有效（23 段 + HUD 内部 2 + HD2DFX 内部 4 = 30 运行期节点） |
| `grep -c "^\[node "` 落盘文本 | **24** | 与 SceneState 一致 |
| `CACHE_MODE_IGNORE` 磁盘回读 | `SceneState_nodes=24`、`VERIFY_SUMMARY pass=7 fail=0 OK=true` | 绕过进程缓存强制重读磁盘 |
| 回读 4 项派单要求 | ② FX 实例存在 `true` / ③ 根为 CanvasLayer `true`（layer=10）/ ⑤ 脚本已挂 4/4 `true` / ⑦ 节点数 24 `true` | **全部满足**（另加 ④ 实例占位、⑥ fx_profile=desktop 两项） |

> 脚本用 `CACHE_MODE_IGNORE` 读磁盘最新场景，避免命中进程缓存 / 并发旧副本；`load(FX_SCENE_PATH)` 用普通 `load()`（非 IGNORE）确保 `PackedScene` 在 ResourceCache 注册、`resource_path` 正确，pack 才能写成 `ExtResource` 占位（沿用 R15 的 HUD 与 R16 §2.1 的教训）。

### 2.4 Movie Maker 抓帧 · **EXIT=0**

命令（任务给定**绝对路径 + `.png`** 后缀，沿用 R14 / R15 / R16 口径；**不带 `--headless`**，Movie Maker 需渲染设备）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot --write-movie F:/Game/aierdengfahuan/capture/r17.png --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn
```

`capture/r17_capture.log` 实际 stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 616.92 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Ti

Movie Maker mode enabled, recording movie in 1280×720 @ 30 FPS...
--------------------------------------------------------------------------------
Done recording movie at path: F:/Game/aierdengfahuan/capture/r17.png
6 frames at 30 FPS (movie length: 00:00:00:06), recorded in 00:00:01 (100% of real-time speed).
CPU render time: 0.00 seconds (average: 0.01 ms/frame)
GPU render time: 0.00 seconds (average: 0.00 ms/frame)
Encoding time: 0.18 seconds (average: 29.39 ms/frame)
--------------------------------------------------------------------------------
```

- 产出 `r1700000000.png` ~ `r1700000005.png`（6 帧）+ `r17.wav`；抽验 3 张 PNG 头全部 `89504e470d0a1a0a…4948445200000500000002d0` = **1280×720**，签名合法；抓帧日志 `SCRIPT ERROR|ERROR` grep **0 条**。
- 注：任务文字写「抓帧 `capture/r17.png`」，`--write-movie` 以该 `.png` 为前缀实际输出 PNG 序列（`r170000000*.png`）+ wav，与 R14 / R15 / R16 一致，如实登记。

### 2.5 R16 → R17 画面差异（体积光 / 光尘 / 倒影 / bloom 是否可见）

对照 `capture/r1600000002.png`（R16 纠偏版）与 `capture/r1700000002.png`（R17），并辅以**本地像素差分 / 逐帧差分**（非像素精确测量，不夸大）：

| FX 项 | R16 | **R17** | 判据（实际证据） |
|---|---|---|---|
| **体积光** | 不可见 | **可见（柔和）**：暖金色扇形从地平线光源（约 x≈904、y≈184，即 `LIGHT_POS=(452,92)` ×2）向下铺开，画面整体暖金提亮 | 差分热区 row1-4 / col4-6 变化率 19%~**80.4%**、`brighter_px=22384`（变亮像素）；但 4 层低 alpha（0.18/0.12/0.07/0.04）叠加 → **光束边界柔和、非锐利射线** |
| **光尘** | 不可见 | **可见**：天空与画面上部散布冷白 / 暖金小亮点（含 HUD 深色面板上方，见下方限制说明） | 整图实看 + 逐帧差分：R17 相邻帧差 **808~2020 px**（上飘 / 横摆动画）；R16 相邻帧差 **全部 0** |
| **湿地倒影** | 不可见（角色脚下仅砖块接缝） | **部分可见 / 不够明显**：角色脚下新增水平波纹状亮线与暖色镜像条带（`draw_rect` 逐行波纹，逐帧变化） | 局部放大对照图 `r17_diff_crop.png`；但**清晰的「角色垂直镜像实体倒影」在整图中难以辨认** —— 色板倒影 alpha 0.35、锚点 `(320,250)` 与角色实际落点未完全对齐、与砖块高频纹理叠加，如实登记、不冒充 |
| **bloom** | 不可见 | **可见（几何近似）**：地平线光源处 (≈904,184) 有暖金圆形光晕 / 亮斑（同心圆 ×5 + 核心叠加），冷蓝夜雾区无光晕 | 整图实看 + 差分 row1 / col5 19%；系 2D 几何 / 加色近似，**不是** HDR 亮度阈值 bloom 后处理 |

**客观旁证**：
- R16 六帧 PNG 各 **106957 B 且字节完全相同**（静态）；R17 六帧 **117841~118164 B 且各不相同**（逐帧动画生效）。
- R16↔R17 同帧差分 `changed_px=63564`、占全幅 **6.897%**，`changed_bbox x=[20,1265] y=[0,713]`；变化集中于光源列（8×6 网格 col5）及其向下扇形区域，与 `HD2D-FX-PLAN.md` §3.1 的 `light_pos` / spread 口径吻合。
- 天空带、砖块地面、蓝红像素骑士、深蓝金边 HUD「赐福 · 宁姆格福」**均仍存在**，R17 未破坏 R16 构图。

**诚实结论与边界**：
- 四项光效由「无」变为「可见 / 部分可见」，是 `gl_compatibility` 下的 **2D `CanvasLayer` + `CanvasItem` 程序化近似**（`HD2D-FX-PLAN.md` §0 / §6 #7），**不是** `Environment.glow` / 真 3D 体积光 / SSR / HDR bloom；不宣称已实现原生后处理。
- 2D `CanvasLayer` 天然绘制在 SubViewport 内 3D 内容与既有 `FXLayer/HUD` 之上 → **光尘小点会落在 HUD 面板上**（§6 #2 固有限制），本轮未调整层级顺序。
- **不宣称 HD-2D 全绿达标**；倒影不清晰、光效偏柔和、地面仍占约 3/4、远处砖块高频纹理、HUD 仍静态未绑数据，运行期观感与手感仍需人工试玩 / 后续轮次。

### 2.6 三段门禁（逐段真实 EXIT + stdout + grep）

| 段 | 命令 | **EXIT** |
|---|---|---|
| G1 | `--headless --path F:/Game/aierdengfahuan/godot --import` | **0** |
| G2 | `--headless --path F:/Game/aierdengfahuan/godot --check-only --script res://scripts/attach_fx_r17.gd` | **0** |
| G3 | `--headless --path F:/Game/aierdengfahuan/godot --quit` | **0** |

G1 `r17_gate_import_clean.log`（剥离 ANSI 控制符后的可读抄录，行数与内容一致）：

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

G2 `r17_gate_checkonly.log` stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

```

> `check-only` 仅解析、未执行 `_initialize()`，**未误触发场景二次修改**；门禁后复查场景 sha256 仍 `306b2467…`、节点数 24。

G3 `r17_gate_quit.log` stdout（全文）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

> 唯一 WARNING 为工程既有的 `2 ObjectDB instances were leaked`（R9~R16 门禁即有），WARNING 级、非 ERROR、不改退出码（G3 EXIT=0）；按契约 §10 固定 `--headless --quit`，未擅自换 `--quit-after`、不宣称 WARNING 清零。

`capture/r17_gate_summary.log` 实际内容：

```
G1_IMPORT_EXIT=0
G2_CHECKONLY_EXIT=0
G3_QUIT_EXIT=0
########## grep -n -E 'SCRIPT ERROR|ERROR' 三段门禁日志 ##########
No matches found (0 条)
########## 逐份 R17 日志 grep ##########
r17_pre_import.log : 0 条
r17_attach_run.log : 0 条
r17_attach_idempotent.log : 0 条
r17_capture.log : 0 条
r17_gate_import.log : 0 条
r17_gate_checkonly.log : 0 条
r17_gate_quit.log : 0 条
```

**grep 结论**：`SCRIPT ERROR` / `ERROR` 在三段门禁日志及全部 R17 日志中 **0 条**。

---

## ③ 未完成项与阻塞（如实）

1. **倒影不够清晰**：角色脚下可见新增水平波纹亮线 / 暖色镜像条带，但清晰的「角色垂直镜像实体倒影」在整图中难以辨认（色板 alpha 0.35、锚点 `(320,250)` 与角色实际落点未对齐、与砖块高频纹理叠加）。属 `HD2D-FX-PLAN.md` §6 #2 已登记的 2D/3D 遮挡固有限制与既有近似口径，本轮未擅自改口径 / 未改运行中 `hd2d_fx.gd`。
2. **非原生后处理**：四项是 2D 程序化 `CanvasLayer` 近似，不是 `Environment.glow` / 真 3D 体积光 / SSR / HDR bloom（`gl_compatibility` 后端不支持）；承 R14 / HD2D-FX-PLAN §0 / §6 #7，**不宣称已实现原生后处理、不宣称 HD-2D 全绿达标**。
3. **光尘覆盖 HUD**：2D `CanvasLayer` 天然绘制在 SubViewport 内 3D 与 `FXLayer/HUD` 之上，光尘小点会落在 HUD 面板上（§6 #2）。层级顺序调整需结合场景裁决，本轮未改。
4. **分档接线未做**：`fx_profile` 沿用脚本默认 `desktop`（四项全开）；§4.4「按 `SceneRouter` / `RenderProfiles` 逐层 `visible` 接线」、§4.3「移动档降级而非全关」均为**待裁决建议**，本轮未接线、未写 / 未改 `quality_preset_*.tres`、`render_profiles.tres`（越界，归 Rank-1 装配权且需总指挥裁决）。
5. **既有 WARNING（非本轮引入、非 ERROR）**：`ChunkManager 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`，与 R9~R16 一致，未处理、未冒充全绿。
6. **画质与交互承 R16 遗留**：地面仍占画面约 3/4、远处砖块密集呈高频纹理、角色占比、BoxMesh 薄侧面纹理拉伸、HUD 仍静态未绑 `WorldState` flag 数据；本轮未扩展、不擅自反复调构图。运行期观感 / 手感仍需人工试玩。
7. **并发保护执行记录**：开工只读检查 `DONE-R17.md` / `attach_fx_r17.gd` / `courtyard.tscn.bak-pre-r17` / outbox / receipts → **全部不存在**，写 DONE 与回执前再次复核 → 仍不存在、outbox 空、无同 id 归档 → 本实例自行写入；脚本内 `ALREADY_ATTACHED` 幂等分支、`CACHE_MODE_IGNORE` 读取、备份「已存在则不覆盖」三重保护，避免与并发主会话互相踩踏；**未覆盖任何并发产出、未写第二份回执**。
8. **按约束未做 / 边界**：默认不刺探（仅本单必要只读，未扫无关目录 / 未做进度巡检）；零付费 / 零外部素材 / 零外部生成服务 / 零插件；既有件不重做（`hd2d_fx.tscn` / `hd2d_fx.gd` / `assemble_r15.gd` / `tune_r16.gd` / `hud.tscn` 仅作参考，未改）；不伪造输出、不冒充全绿；中文 UTF-8、Godot 4.7.2 合法语法；不写其它工位 / 总线 / 总纲 / 契约 / 台账；不自行 `git commit` / `git push`；`00-群聊总线.md` 开工只读一次、未追加（本轮无接口变更 / 里程碑 / 阻塞求助 / 回应 @ 事件，且总线不在可写范围）。

---

## 结论

主任务闭环：`attach_fx_r17.gd` 落盘并真跑（**EXIT=0 / verify_ok=true**），备份 `bak-pre-r17`（= R16 终态）生成且未被覆盖；`HD2DFX`（CanvasLayer，layer=10）以 `instance=ExtResource` 占位挂到 `SubViewportContainer/SubViewport` 下，`fx_profile=desktop` 四项全开；owner 链重设跳过实例化节点；**节点数 pack 前 23 / pack 后 24 / `CACHE_MODE_IGNORE` 磁盘回读 24**，回读 7 项全 PASS（FX 实例存在 / 根为 CanvasLayer / 4 节点脚本已挂 / 节点数 24 等），`OK=true`；幂等重跑走复核模式、场景与备份 sha256 字节不变。三段门禁真实 EXIT **0 / 0 / 0**，`grep "SCRIPT ERROR|ERROR"` 全日志 **0 条**。按任务给定绝对路径命令抓帧 **EXIT=0**，产出 6 帧 1280×720 PNG；R16→R17 画面由「静态、无四项光效」变为「暖金体积光扇形 / 光尘上飘 / 地平线 bloom 光晕可见、角色脚下波纹与暖色镜像部分可见、6 帧逐帧动画」，差分 6.897% 像素变化、热区与光源口径吻合。未完成项（倒影不清晰、非原生后处理、光尘覆盖 HUD、分档未接线、既有 WARNING、遗留画质与 HUD 静态）如实登记。

`status=done` 指**本轮 FX 实例挂载与验证主任务闭环**，**不代表**「画面 HD-2D 全绿达标」或「运行期观感已验收」。

> 证据：`capture/r17_attach_run.log`、`r17_attach_idempotent.log`、`r17_capture.log`、`r17_gate_*.log`、`r17_gate_summary.log`、`capture/r17000000*.png`、`capture/r17.wav`、`capture/r17_diff_crop.png`、`_archived_20261108/courtyard.tscn.bak-pre-r17`、`godot/scenes/courtyard.tscn`、`godot/scripts/attach_fx_r17.gd`。

---

## ④ 回执

- 按本轮 id 写入 `teamwork/command_center/ai/1/outbox/cmd-20261109-093050-714-A1.json` **仅一份**，内容：
  `{"task_id":"cmd-20261109-093050-714-A1","ai":1,"status":"done","result":"见 DONE-R17.md：attach_fx_r17.gd 真跑 EXIT=0/verify_ok=true，HD2DFX 以 instance 占位挂入 SubViewport 下（fx_profile=desktop 四项全开），节点数 pack 前23/pack 后24/CACHE_MODE_IGNORE 回读24、回读7项全 PASS；幂等重跑字节级一致、备份(=R16终态)未覆盖；三段门禁 EXIT 0/0/0、SCRIPT ERROR|ERROR grep 0 条；Movie Maker 抓帧 EXIT=0 产出6帧1280x720 PNG，R16→R17 暖金体积光/光尘/bloom 可见、脚下波纹与暖色镜像部分可见、逐帧动画生效；未完成项：倒影不清晰、非原生后处理、分档未接线、既有WARNING，详见 DONE-R17.md ③。"}`
- 写入前复核 outbox 为空、无同 id receipts 归档；未写第二份回执、未改写任何归档件。

---

## ⑤ 回执路由状态（收尾复核追加，不改动上文结论）

- 回执按本轮 id 写入 `command_center/ai/1/outbox/cmd-20261109-093050-714-A1.json` **仅一份**；写入后被调度中枢**即时消费**，outbox 现为空，归档到 `command_center/dispatcher/receipts/cmd-20261109-093050-714-A1.json`（705 B，`task_id=cmd-20261109-093050-714-A1` / `ai=1` / `status=done`，`json.load` 解析通过，内容与本工位写入的逐字一致）。
- 按派单「若回执已被送达中枢（outbox 空但 receipts 归档存在）→ 不再写第二份」，**未写第二份回执、未改写归档件**；上文 ④ 中的回执路径为写入时的初始位置，实际路由以本节为准。
- `dispatcher/receipts/` 不在本轮可写范围，全程未改写任何归档件，未在 outbox 重复投递。
