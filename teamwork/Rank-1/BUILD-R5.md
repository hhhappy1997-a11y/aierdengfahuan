# BUILD-R5.md · Rank-1 R5（M1 垂直切片联调 + 工程根落地 · 真跑记录）

> 派单：`Rank-1\任务书-R5.md` ｜ 任务单 id：`cmd-20261109-013419-300-A1`
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（标准版 4.7.2，`--version` 实测 `4.7.2.stable.official.ed1daf0bf`）
> 口径：`00-协作契约.md` §10 三段构建门禁；运行时 `SCRIPT ERROR` 不改退出码，**必须 grep 日志**才算通过。
> 本文件所有结论均来自本轮真跑实际输出，未伪造、未沿用历史轮次结论。

---

## 0. 本轮开工盘点（只补缺口、不重做）

开工时完整盘点 `Rank-1\`，确认**本工位此前已有一次未收尾的 R5 执行**留下两个真实产出：

| 既有产出 | 状态 | 本轮处置 |
|---|---|---|
| `Rank-1\project_root\`（`project.godot` + `res://` 完整目录树） | 已存在 | **保留不改**；本轮首次对其做三段门禁真跑验证 |
| `Rank-1\chunk_streaming_r5.gd`（档位驱动 9↔4 常驻 chunk） | 已存在（410 行） | **保留不改**；本轮首次对其做功能真跑验证 |
| R2/R3/R4 及更早全部产出 | 已存在 | **一律保留不改**（`DONE-R2/3/4.md`、`BUILD.md`、`M1-M2-BUILD.md`、`courtyard.tscn` 等） |

这两个既有 R5 产出此前**从未做过三段门禁真跑、也无 `DONE-R5.md` 与回执**，正是本轮缺口。本轮补齐：`跨模块联调-R5.md`、`ObjectDB-leak-定位与消除-R5.md`、本 `BUILD-R5.md`、`DONE-R5.md`、outbox 回执，并完成全部真跑。**未新建/未覆盖任何既有代码件**。

---

## 1. 验证载体（系统临时目录，独立、用完即删）

- 位置：`C:\Users\62668\AppData\Local\Temp\r1_r5_verify`（Git Bash `/c/Users/62668/AppData/Local/Temp/r1_r5_verify`，Godot 传参 `C:/Users/62668/AppData/Local/Temp/r1_r5_verify`）。**独立于 R2/R3/R4 历史验证目录，不与并发工位冲突，记录结论后删除。**
- 放入：
  - `Rank-1\project_root\` 全文拷贝（既有工程根 `res://` 目录树：`project.godot` + `scripts/` + `scenes/` + `data/render/`）；
  - 3 个 Rank-3 契约替身 stub：`scripts/world/world_state.gd`（实提供 `get_flag`/`set_flag` + 调用计数）、`scripts/core/game_events.gd`、`scripts/world/save_system.gd`——因 Rank-3 真实实现未到位，仅让 5 个 autoload 能加载；
  - 25 个占位 chunk 场景 `scenes/world/chunks/chunk_limgrave_<x>_<y>.tscn`（`x,y ∈ {-2,-1,0,1,2}`，纯 `Node3D`），覆盖 R5 档位 4/9/25 邻域；
  - 一次性功能验证驱动 `scripts/r5_verify_scene.gd` + `scenes/r5_verify.tscn`（最终采纳，真实场景生命周期）；
  - `logs/`：各段 stdout+stderr 重定向落盘，供 grep。
- stub / 占位场景 / 驱动**均非探针 / 测量 / preflight / 常驻监听脚本**（不扫别人工位、不轮询、不反复核对文件状态），与 R3/R4 的 stub / `m2_verify.gd` 同口径；不进交付清单，用完即删。

命令占位：`<godot>` = `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`<tmp>` = `C:/Users/62668/AppData/Local/Temp/r1_r5_verify`。

---

## 2. 三段构建门禁（最终清缓存全量复跑，契约 §10）

> 首轮门禁通过后，因修正功能驱动（见 §4）改动了验证工程脚本集合，故 `rm -rf .godot` **清缓存全量复跑**，以下为最终结论。

| 段 | 实际命令 | EXIT | 真跑实际输出结论 |
|---|---|---|---|
| G0 | `<godot> --version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| **G1** | `<godot> --headless --path <tmp> --import` | `0` | `first_scan_filesystem` 5 步 DONE；`update_scripts_classes` 15 步 DONE；全局类 `QualityPreset` / `RenderProfiles` / `HybridSpriteRig` 注册成功；**无 Parse Error** |
| **G2** | `<godot> --headless --path <tmp> --check-only --script res://<f>.gd`（15 个 `.gd` 逐个） | **15 条全 `0`** | 见下方逐个清单，全部静态解析通过 |
| **G3** | `<godot> --headless --path <tmp> --quit` | `0` | 打开主场景 `res://scenes/Main.tscn` 成功；5 个 autoload 加载成功 |

### G2 逐个 `--check-only --script` 清单（15 个 `.gd`，全部 EXIT=0）

```
res://scripts/build_courtyard.gd                        EXIT=0
res://scripts/build_main.gd                             EXIT=0
res://scripts/core/game_events.gd                       EXIT=0   (stub)
res://scripts/core/quality_preset.gd                    EXIT=0
res://scripts/core/render_profiles.gd                   EXIT=0
res://scripts/core/scene_router.gd                      EXIT=0
res://scripts/r5_verify_scene.gd                        EXIT=0   (验证驱动)
res://scripts/render/camera_rig.gd                      EXIT=0
res://scripts/render/hybrid_2d3d_animated_sprite.gd     EXIT=0
res://scripts/ui/performance_hud.gd                     EXIT=0
res://scripts/world/chunk_streaming.gd                  EXIT=0
res://scripts/world/chunk_streaming_r4.gd               EXIT=0
res://scripts/world/chunk_streaming_r5.gd               EXIT=0   (本轮重点验证件)
res://scripts/world/save_system.gd                      EXIT=0   (stub)
res://scripts/world/world_state.gd                      EXIT=0   (stub)
```

> 覆盖面大于最低要求：本工位**全部 11 个交付件 `.gd`** + 3 个 Rank-3 stub + 1 个验证驱动，共 15 个逐个 check，无遗漏。

---

## 3. grep 校验（关键：运行时 SCRIPT ERROR 不改退出码）

对最终采纳的 `<tmp>/logs/*.log`（含 G1/G2/G3、G4 verbose、G5 功能驱动、E1~E5 对照实验）：

```
grep -rn   "SCRIPT ERROR"               logs/*.log   → NONE
grep -rniE "parse error|\berror\b|failed" logs/*.log   → NONE
grep -rn   "WARNING"                    logs/*.log   → 命中 4 行
```

- **SCRIPT ERROR：NONE**。
- **ERROR / Parse Error / Failed：NONE**。
- WARNING 命中 4 行，全部为同一条 `WARNING: 2 ObjectDB instances were leaked at exit`（G3 / G4 / E1 / E4），**WARNING 级、非 SCRIPT ERROR / ERROR、不改退出码（对应段均 EXIT=0）**。定位与消除见 §5 与 `ObjectDB-leak-定位与消除-R5.md`。

### 如实留存：首轮功能驱动的废弃尝试

首轮 G5 采用 `extends SceneTree` + `--script` 自定义 MainLoop，真跑 **FAILED(EXIT=1)** 且产生 3 条错误，已归档到 `logs/discarded/G5_failed_attempt_scriptmode.log`，**不隐瞒、不删除**：

```
ERROR: Can't use get_node() with absolute paths from outside the active scene tree.
ERROR: Parameter "data.tree" is null.
SCRIPT ERROR: Invalid access to property or key 'root' on a base object of type 'null instance'.
... [r5_verify] R5_FAIL ... flag_ok=false set_calls=0
```

根因：自定义 MainLoop 下 autoload 未加载、场景树未激活、`get_node_or_null("/root/WorldState")` / `get_tree().root` 不可用——**是验证驱动载体缺陷，非任何交付件缺陷**。处置：废弃该驱动，改用真实场景生命周期（`r5_verify.tscn` 挂 `r5_verify_scene.gd`），清缓存全量复跑后 §4 通过。上述 SCRIPT ERROR 仅存在于废弃日志，不属于采纳日志，未计入 §3 的 grep=NONE 结论（口径如实区分）。

---

## 4. R5 功能真跑（真实场景生命周期，`--quit` 由驱动自行调用）

命令：`<godot> --headless --path <tmp> res://scenes/r5_verify.tscn` → **EXIT=0**

真实输出全文（`logs/G5_scene_verify.log`）：

```
[r5_verify] desktop resident=9 wanted=9 loaded=9 frames=5
[r5_verify] frame_logic_us samples=5 avg=249.2 max=508.0 (target_desktop_ms=16.67 target_mobile_ms=33.33, CPU逻辑耗时非GPU渲染帧时间)
[r5_verify] mobile resident=4 wanted=4 loaded=4 root_children=13
[r5_verify] i1_bridge set_calls=9 get_calls=0 read_loaded_flag=true
[r5_verify] R5_PASS desktop_9=ok mobile_4=ok i1_bridge=ok chunks_instantiated=ok
```

逐条如实解读（不淡化、不过度解读）：

- **桌面档 9 / 移动档 4 运行时落地**：`get_wanted_ids()` / `get_loaded_chunk_ids()` 在桌面档均 9、切移动档后均 4，证明 `chunk_streaming_r5.gd` 的「按 `resident_chunk_count` 档位动态决定常驻集合」真实生效，补齐 R2/R4「固定 3×3=9、移动端 4 只写在 `.tres` 里」的遗留。
- **帧时间实测（如实标注口径）**：`Time.get_ticks_usec()` 包裹 `pump()` 采得 **CPU 逻辑帧处理耗时 samples=5 avg=249.2µs max=508.0µs**（约 0.25 / 0.51 ms）。这是 `load_threaded_*` 轮询 + 三态去重 + 延迟卸载的**逻辑处理耗时**；**headless 无渲染管线，不含 GPU 绘制/合成/VSync，不是端到端渲染帧时间**。资源表目标 `16.67 / 33.33 ms` 仍是静态目标值。真实帧时间 / p99 / spike 需 F3 性能 HUD + 人工试玩，本轮未做、未伪造（见 `DONE-R5.md` ③）。
- **I-1 跨模块联调桥接**：`set_calls=9`（9 块加载各经 `WorldState.set_flag` 写 `chunk.<id>.loaded`）、`read_loaded_flag=true`（经 `WorldState.get_flag` 读回成功），双向链路真跑通过。`get_calls=0` 为驱动采样时点早于末次 `read_loaded_flag` 读取所致，非缺陷；flag 读回 `true` 已证明 `get_flag` 生效。
- **`root_children=13`（如实登记，不隐瞒）**：为 `ChunkRoot` 物理子节点数，含 `queue_free()` 延迟卸载尚未回收的实例（桌面 9 块 + 档位切换期间残留），故大于逻辑常驻 4。**验收以交付件公开接口 `get_loaded_chunk_ids()` = 4 为准**，`root_children` 未纳入 PASS 断言（PASS 断言为 `wanted/loaded=9→4` + `flag_ok` + `set_calls>=9`），此处如实说明其数值来源，未谎报为 4。
- `chunks_instantiated=ok`：占位 chunk 场景 `PackedScene.instantiate()` 入树成功（有物理子节点）；如上，数量断言以逻辑状态为准。

---

## 5. ObjectDB leaked WARNING 定位/消除对照实验（真跑）

G4 `<godot> --headless --path <tmp> --quit --verbose` 全文关键行：

```
Loading resource: res://scenes/world/chunks/chunk_limgrave_-1_-1.tscn remapped: ...
Loading resource: res://scenes/world/chunks/chunk_limgrave_0_-1.tscn remapped: ...
XR: Clearing primary interface
Leaked instance: RefCounted:9223372066718221806 - Reference count: 1
Leaked instance: RefCounted:9223372066785330690 - Reference count: 1
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
```

5 组对照（临时工程内改 `project.godot` autoload 段，实验后原样恢复）：

| 实验 | 命令 / 配置 | EXIT | leaked 实例数 |
|---|---|---|---|
| E1 | `--quit`（完整 5 autoload，基线） | 0 | **2** |
| E2 | `--quit-after 60`（给足帧让在途加载完成） | 0 | **0** |
| E3 | 去 `ChunkManager` autoload + `--quit` | 0 | **0** |
| E4 | 去 `SceneRouter` autoload + `--quit` | 0 | **2** |
| E5 | 去 `ChunkManager`+`SceneRouter` + `--quit` | 0 | **0** |

**定位结论（钉死根因）**：2 个 `RefCounted`(refcount=1) 来自 autoload `ChunkManager`（R2 `chunk_streaming.gd`，`auto_start=true` + `call_deferred("_bootstrap")` → `load_threaded_request`）在 headless `--quit` **立即退出**时尚未回收的**在途线程加载请求**，紧跟在途 chunk 场景 remap 日志之后出现。E3（去 ChunkManager）→ 0、E4（去 SceneRouter 仍 2）→ 排除 SceneRouter；E2（给足 60 帧让 `load_threaded_get` 完成）→ 0，证明「在途请求完成即消除」。**非 R5 交付件引入，属验证载体 / headless 立即退出的固有现象。**

**消除结论（如实，不谎称已彻底消除）**：消除手段（`--quit-after` 给足帧 / 不在立即退出时留未完成在途请求）经 E2/E3/E5 真跑验证有效（0 leaked）。但三段门禁第三段按契约 §10 固定为 `--headless --quit`（立即退出），且本轮硬约束「R2/R3/R4 既有产出保留不改」不允许修改 `chunk_streaming.gd` autoload，故**固定门禁 G3 命令下该 WARNING 仍存在（2 leaked，WARNING 级、EXIT=0）**。详见 `ObjectDB-leak-定位与消除-R5.md` 与 `DONE-R5.md` ③，如实登记为残留、未淡化。

---

## 6. 工程根 `res://` 目录树落位核对

`Rank-1\project_root\`（既有 R5 产出，本轮保留不改）结构，本轮以 `--path <tmp>` 真跑验证可作为 Godot 工程根打开：

```
project_root/
├── project.godot                         ← 5 autoload / 15 input action / [hd2d] / [rendering] Nearest
├── scripts/
│   ├── build_main.gd / build_courtyard.gd
│   ├── core/    scene_router.gd  quality_preset.gd  render_profiles.gd
│   ├── render/  hybrid_2d3d_animated_sprite.gd  camera_rig.gd
│   ├── ui/      performance_hud.gd
│   └── world/   chunk_streaming.gd  chunk_streaming_r4.gd  chunk_streaming_r5.gd
├── scenes/
│   ├── Main.tscn / courtyard.tscn
│   └── world/chunks/   (占位 chunk 场景在验证工程补齐；交付树留空供 3 号落位)
└── data/render/
    ├── quality_preset_desktop.tres (9 / 16.67ms / 640×360)
    ├── quality_preset_mobile.tres  (4 / 33.33ms / 480×270)
    └── render_profiles.tres        (桌面 9 / 移动 4 两列对照)
```

G1 `--import` 与 G3 `--quit` 均以 `<tmp>`（该树全文拷贝）为工程根，EXIT=0、全局类注册成功、主场景打开成功，证明 `res://` 路径 / autoload / `ext_resource` 引用自洽、可直接整体拷贝为工程根使用。

> **边界如实登记**：真实工程根 `F:\Game\aierdengfahuan\` 不在本工位唯一可写目录内，本轮**未写入**；`project_root\` 是工位内可整体拷贝的目录树镜像。见 `DONE-R5.md` ③。

---

## 7. 临时工程清理

全部真跑结论已记录于本文件 / `跨模块联调-R5.md` / `ObjectDB-leak-定位与消除-R5.md` 后，`r1_r5_verify` 系统临时目录 `rm -rf` 删除（`DONE-R5.md` 记录删除确认）。未写入 teamwork、未提交。

---

**总自检结论**：Godot 4.7.2 三段门禁（G1/G2/G3）清缓存全量复跑全 `EXIT=0`、15 个 `.gd` 逐个 `--check-only` 全 0、采纳日志 `SCRIPT ERROR = NONE` 且 `ERROR/ParseError/Failed = NONE`；`chunk_streaming_r5.gd` 场景生命周期真跑 `R5_PASS`（桌面 9 / 移动 4 / I-1 桥接 / chunk 实例化通过），CPU 逻辑帧耗时实测 avg 249.2µs / max 508µs（如实标注非 GPU 渲染帧时间）；ObjectDB leaked 定位钉死为 ChunkManager autoload 在途请求，消除手段真跑 0 leaked 验证有效、固定门禁下残留 WARNING 如实登记。所有输出与退出码均为本轮真实结果，未伪造；首轮失败的驱动尝试如实归档留存。
