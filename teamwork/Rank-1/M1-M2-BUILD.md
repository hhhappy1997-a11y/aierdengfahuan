# M1-M2-BUILD.md · Rank-1 R4（M1 垂直切片可跑 + M2 流式加载可测 · 真跑记录）

> 派单：`Rank-1\任务书-R4.md` ｜ 任务单 id：`cmd-20261109-005741-232-A1`
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（标准版 4.7.2，`--version` 实测 `4.7.2.stable.official.ed1daf0bf`）
> 口径：`00-协作契约.md` §10 / `00-工具链接入说明.md` §4.2 三段构建门禁；运行时 `SCRIPT ERROR` 不改退出码，**必须 grep 日志**才算通过。
> 本文件所有结论均来自真跑实际输出，未伪造、未写「未找到 godot、无法真跑」的旧结论。

---

## 1. 验证载体（系统临时工程，不在 teamwork 内、不提交、用完即删）

- 位置：`C:\Users\62668\AppData\Local\Temp\r1_r4_verify`（Git Bash 路径 `/c/Users/62668/AppData/Local/Temp/r1_r4_verify`，Godot 传参用 `C:/Users/62668/AppData/Local/Temp/r1_r4_verify`）。
- 放入：本工位 `project.godot` + R2/R3 全部既有 `.gd` / `.tres` / 占位 `scenes/Main.tscn`（R2 `场景树骨架.tscn`）+ 本轮 R4 `build_courtyard.gd` / `chunk_streaming_r4.gd`，按各自 `res://` 落位铺开。
- 3 个最小依赖替身 stub（`world_state.gd` / `game_events.gd` / `save_system.gd`）：因 3 号 `WorldState` / `GameEvents` / `SaveSystem` 真实实现未到位，仅让 5 个 autoload 能加载；`world_state.gd` 实提供 `get_flag` / `set_flag`，供 R4 flag 桥接真跑。**非探针 / 测量 / preflight 脚本，不进交付清单，用完即删。**
- 12 个占位 chunk 场景（`chunk_limgrave_<x>_<y>.tscn`，`x ∈ {-1,0,1,2}`、`y ∈ {-1,0,1}`，纯 `Node3D` + `BoxMesh`，覆盖 `(0,0)→(1,0)→(0,0)` 往返）：让 M2 的 `load_threaded_request` 有真实 `PackedScene` 可加载；3 号真实 chunk 场景到位后需回归。
- 1 个临时 M2 验收驱动 `scripts/m2_verify.gd`（`extends SceneTree`）：实例化 R4 `chunk_streaming_r4.gd`、`set_process(false)` 后显式 `pump()` 做确定性帧步进，喂往返走输入并断言。**性质为对本轮交付件的一次性功能验证，与 R3 的 stub 同口径；不扫别人工位、不轮询、不反复核对状态，非探针 / 测量 / preflight 脚本；不进交付清单，用完即删。**
- `logs/`：各段命令 stdout+stderr 重定向落盘，供 grep。

命令占位：`<godot>` = `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`<tmp>` = `C:/Users/62668/AppData/Local/Temp/r1_r4_verify`。

---

## 2. 三段门禁 + 额外真跑（全部实际命令与输出结论）

| 段 | 实际命令 | EXIT | 真跑实际输出结论 |
|---|---|---|---|
| G0 | `<godot> --version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| **G1** | `<godot> --headless --path <tmp> --import` | `0` | `first_scan_filesystem` 五步 DONE；`update_scripts_classes` 14 步 DONE；全局类 `QualityPreset` / `RenderProfiles` / `HybridSpriteRig` 注册成功；无 Parse Error |
| **G2** | `<godot> --headless --path <tmp> --check-only --script res://<f>.gd`（循环 14 个 `.gd`） | **14 条均 `0`** | `build_main.gd`、`build_courtyard.gd`、`m2_verify.gd`、`core/scene_router.gd`、`core/quality_preset.gd`、`core/render_profiles.gd`、`core/game_events.gd`、`render/hybrid_2d3d_animated_sprite.gd`、`render/camera_rig.gd`、`ui/performance_hud.gd`、`world/chunk_streaming.gd`、`world/chunk_streaming_r4.gd`、`world/world_state.gd`、`world/save_system.gd` 全部静态解析通过。**本轮 changed = `build_courtyard.gd` + `chunk_streaming_r4.gd`，均 `0`；余下为覆盖面更广的全量复核** |
| **G3** | `<godot> --headless --path <tmp> --quit` | `0` | 打开占位主场景 `scenes/Main.tscn` 成功；`SceneRouter._ready()` 加载两份 `quality_preset_*.tres` 成功（无缺失警告） |
| G4 | `<godot> --headless --path <tmp> --script res://scripts/build_courtyard.gd` | `0` | `[courtyard] BUILD_OK output=res://scenes/courtyard.tscn nodes=20`；`PackedScene.pack()` → `instantiate()` 节点数比对 `20 = 20` 通过 → 才 `ResourceSaver.save()`；`grep -c '^\[node ' courtyard.tscn` = `20` 双重印证 |
| G5 | `<godot> --headless --path <tmp> --quit`（生成 courtyard 后复开） | `0` | 工程仍可正常启动退出，生成物未破坏工程 |
| G6 | `<godot> --headless --path <tmp> --script res://scripts/m2_verify.gd` | `0` | `[m2_verify] seen=12 loaded_now=12 max_load_count=1 center_ok=true chunk_loaded_events=12 chunk_unloaded_events=0 flags_ok=true`；`[m2_verify] M2_PASS 往返走不重复加载（3x3 常驻，get_load_count 恒为 1）`；无 warning |
| G7 | `<godot> --headless --path <tmp> --quit-after 2 res://scenes/courtyard.tscn` | `0` | 直接打开 R4 主场景 `courtyard.tscn` 成功；G7 日志 `SCRIPT ERROR = NONE` |

**G4 与工位交付件的一致性**：工位 `Rank-1\courtyard.tscn` 由 G4 真跑生成的 `<tmp>/scenes/courtyard.tscn` 原样拷回，`diff -q` 结论 `与生成物一致: YES`，工位内 `grep -c '^\[node '` = `20`。`.tscn` 含 `ext_resource` 指向 `res://scripts/render/hybrid_2d3d_animated_sprite.gd`、`Environment` 冷夜雾子资源、4 份 `StandardMaterial3D`、`PlaneMesh` 地面 + 3 份 `BoxMesh` 高低差，`Hybrid2D3DAnimatedSprite` 节点 `script = ExtResource(...)` 正确落位。

---

## 3. grep 校验（关键：运行时 SCRIPT ERROR 不改退出码）

对 `<tmp>/logs/` 全部日志（含 G7）：

```
grep -rn   "SCRIPT ERROR"              <logs>   → NONE
grep -rniE "parse error|\berror\b|failed" <logs> → NONE
grep -rni  "warning"                   <logs>   → 命中 6 行
```

- **SCRIPT ERROR：NONE**（含 G7 打开 courtyard.tscn 的日志单独复核 `G7 SCRIPT ERROR: NONE`）。
- **ERROR / Parse Error / Failed：NONE**（无 `ERROR: RID allocations leaked`，也无任何 Parse Error / Failed）。
- WARNING 命中 6 行，其中 WARNING 级消息 **5 条**，逐条归类：
  1. `2 ObjectDB instances were leaked at exit` × **4 条**（G3 / G4 / G5 / G7）—— 见 §3.1。
  2. `[ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。` × **1 条**（G4）—— R2 既有 `chunk_streaming.gd` autoload 在构建脚本自定义 MainLoop 里找不到 `ChunkRoot` 的降级提示（构建脚本新建的树未挂进 SceneTree.root，属预期）。
  - 余 1 行为 `at: push_warning (...)` 的 backtrace 定位行，非独立消息。
  - G6（自定义 MainLoop、节点挂在 `root` 树中、不打开场景）**无**任何 warning。

### 3.1 ObjectDB leaked WARNING 的如实说明（未隐瞒、未消除）

`WARNING: 2 ObjectDB instances were leaked at exit` 出现在所有「打开场景后 headless 快速退出」的段（G3 / G4 / G5 / G7），G6 无。判为 headless `--quit` / `--quit-after` 快速退出时 autoload 单例与 `SubViewport(own_world_3d=true)` 相关资源的清理残留，**WARNING 级、非 SCRIPT ERROR、非 ERROR、不改退出码**（四段均 EXIT=0），且不影响 `courtyard.tscn` 生成物与 G6 的 M2 结论。R3 曾遇到的 `ERROR: RID allocations leaked` 在本轮未出现（R4 `build_courtyard.gd` 沿用 R3 的 `_free_tree()` 后序释放，游离树已清理）。该残留来自验证工程的既有 autoload / 场景打开方式，未在 R2/R3 交付件基础上额外引入 R4 交付件缺陷；按「如实写阻塞、不伪造输出」原则登记，未在 R4 范围内强行改动 autoload 或场景打开方式去消除。

---

## 4. 桌面 / 移动双档帧时间核对

| 档 | 低分辨率缓冲 | 常驻 chunk | 目标帧时间 | 显存上限 | FX（体积光/光尘/湿地倒影/bloom） |
|---|---|---|---|---|---|
| 桌面 | `640×360` @2x | `9`（3×3） | `16.67 ms`（60 fps） | `1536 MB` | 全开 |
| 移动 | `480×270` @2x | `4` | `33.33 ms`（30 fps） | `512 MB` | 全关 |

来源：`render_profiles.tres`（R3 两列对照 `desktop_target_frame_time_ms=16.67` / `mobile_target_frame_time_ms=33.33`、`desktop_resident_chunk_count=9` / `mobile=4`、`desktop_vram_limit_mb=1536` / `mobile=512`）+ `quality_preset_desktop.tres`（`target_frame_time_ms=16.67`、`resident_chunk_count=9`、`640×360`）+ `quality_preset_mobile.tres`（`target_frame_time_ms=33.33`、`resident_chunk_count=4`、`480×270`）。

核对结论：
- 三份资源数值**一致**，无冲突；G1 `--import` 解析通过、全局类 `QualityPreset` / `RenderProfiles` 注册成功；G3 / G5 `--quit` 时 `SceneRouter._ready()` 实际 `ResourceLoader.load` 两份 `quality_preset_*.tres` 成功（无缺失警告）。
- M1 主场景 `courtyard.tscn` 的 `SubViewport` = `640×360`、`SubViewportContainer.stretch_shrink = 2`、`texture_filter = 1`（`CanvasItem.TEXTURE_FILTER_NEAREST`，与 R3 `build_main.gd` 同口径；R2 手写骨架 `texture_filter = 0` 为 `PARENT_NODE` 继承、靠项目级 `default_texture_filter=0` 兜底，两者等效 Nearest）。
- **headless 真跑无渲染管线，无法实测帧时间 / p99 / spike**；`16.67 / 33.33 ms` 为资源表目标值的静态核对，不是实测值。M2 验收「性能监视器无 spike」及 `p99 ≤ 20 ms` / `单帧 ≤ 33.3 ms`（`架构设计.md` §4）需 F3 性能 HUD + 人工试玩，本轮未做、未伪造（见 `DONE-R4.md` ③）。

---

## 5. R4 交付件 → M1 / M2 验收口径映射

| 交付件 | M1 垂直切片 | M2 流式加载 |
|---|---|---|
| `build_courtyard.gd` + `courtyard.tscn` | 3D 庭院（`PlaneMesh` 地面 + 3 处 `BoxMesh` 高低差 / 崖边）、`Camera3D` + `SubViewport` 像素化、暖金 `DirectionalLight3D` + 冷色 `Environment` 夜雾、`Player` 挂 `Hybrid2D3DAnimatedSprite`（I-4）、`ChunkRoot`；20 节点 pack/instantiate 比对通过 | `ChunkRoot` 为空 `Node3D`，供流式管理器挂载，避免与 autoload 双实例 |
| `chunk_streaming_r4.gd` | — | `load_threaded_request → load_threaded_get_status → load_threaded_get` 完整时序；`UNLOADED/LOADING/LOADED` 三态去重；`chunk_loaded/chunk_unloaded` 信号；只经 `WorldState.get_flag/set_flag` 读写 flag（I-1）；`pump()` / `get_state()` / `get_load_count()` / `get_seen_chunk_ids()` 可测接口 |
| G6 M2 驱动 | — | `(0,0)→(1,0)→(0,0)` 往返：`seen=12`、`max_load_count=1`（每个 chunk 仅加载一次）、`center_ok=true`（3×3 常驻）、`flags_ok=true`（flag 桥接真实生效）、`M2_PASS` |

---

## 6. 口径说明（与任务书字面的差异，如实登记）

- 任务书 R4 §真跑要求 `--check-only --script <changed>.gd`：本轮 changed 为 `build_courtyard.gd` + `chunk_streaming_r4.gd`，两者均 `EXIT=0`；另对验证工程全量 14 个 `.gd` 都跑了 `--check-only`，覆盖面大于最低要求，未遗漏。
- 任务书 R4 交付清单 `courtyard.tscn`「由构建脚本真跑生成」：由 G4 实跑 `<godot> --script build_courtyard.gd` 生成 `<tmp>/scenes/courtyard.tscn`，再原样拷回 `Rank-1\courtyard.tscn`（`diff` 一致）。工位目录内**未**直接跑引擎写文件（避免在 teamwork 内生成 `.godot` 缓存、遵守「唯一可写 Rank-1 + outbox」）；构建脚本产出路径按 `res://scenes/courtyard.tscn` 落位。
- `m2_verify.gd` / 3 个 stub / 12 个占位 chunk 场景均在临时验证工程内，不进交付清单、用完即删；性质说明见 §1。
- R2/R3 既有交付件一律保留、不重做；本轮未改 `project.godot`、未改 `chunk_streaming.gd`、未改任何 R2/R3 件。

---

**总自检结论**：Godot 4.7.2 三段构建门禁（G1/G2/G3）真跑全 `EXIT=0`、全量日志 `SCRIPT ERROR = NONE` 且 `ERROR/ParseError/Failed = NONE`；`build_courtyard.gd` 实跑生成 20 节点 `courtyard.tscn` 并完成 `pack()/instantiate()` 节点数 `20 = 20` 比对，G7 直接打开该场景成功；G6 M2 往返走驱动 `M2_PASS`（不重复加载、flag 桥接生效）。5 条 WARNING 均逐条归类、无一是 SCRIPT ERROR / ERROR，其中 `2 ObjectDB instances leaked` 为 headless 快速退出的 WARNING 级残留，已如实登记未隐瞒。桌面 / 移动双档目标帧时间 `16.67 / 33.33 ms` 完成资源表一致性静态核对；运行期帧时间 / spike 实测按契约留给人工试玩，未伪造。
