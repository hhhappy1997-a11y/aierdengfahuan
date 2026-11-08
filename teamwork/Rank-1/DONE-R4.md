# DONE-R4 · Rank-1（引擎架构与渲染）完成标志

> 轮次：R4（HOST 全闭环调度自动启动）｜派单：`Rank-1\任务书-R4.md`｜任务单 id：`cmd-20261109-005741-232-A1`
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`｜`--version` 实测：`4.7.2.stable.official.ed1daf0bf`（EXIT=0）
> HOST 监测只认本文件。本轮只写 `F:\Game\aierdengfahuan\teamwork\Rank-1\`，并按中枢协议另写 `command_center\ai\1\outbox\` 回执 JSON；未写其它工位 / teamwork 根目录 / 总纲 / 契约 / 任务书 / 群聊总线；未自行 git commit / push。
> 真跑结论全部来自实际输出，完整命令与日志结论见 `M1-M2-BUILD.md`（R3 的 `BUILD.md` 保留不改）。

---

## ① 本轮实际交付 / 更新文件清单

| # | 文件（绝对路径） | 动作 | 工程落位（`res://`） |
|---|---|---|---|
| 1 | `F:\Game\aierdengfahuan\teamwork\Rank-1\build_courtyard.gd` | **新建** | `scripts/build_courtyard.gd` |
| 2 | `F:\Game\aierdengfahuan\teamwork\Rank-1\courtyard.tscn` | **新建**（由 ① 构建脚本真跑生成，原样拷回） | `scenes/courtyard.tscn` |
| 3 | `F:\Game\aierdengfahuan\teamwork\Rank-1\chunk_streaming_r4.gd` | **新建** | `scripts/world/chunk_streaming_r4.gd` |
| 4 | `F:\Game\aierdengfahuan\teamwork\Rank-1\M1-M2-BUILD.md` | **新建** | `docs/` |
| 5 | `F:\Game\aierdengfahuan\teamwork\Rank-1\DONE-R4.md` | **新建**（本文件） | — |
| 6 | `F:\Game\aierdengfahuan\teamwork\command_center\ai\1\outbox\` 回执 JSON | **新建**（中枢协议例外） | — |

**对照任务书 R4 §交付清单 5 类**：`build_courtyard.gd` ✓、`courtyard.tscn` ✓、`chunk_streaming_r4.gd` ✓、`M1-M2-BUILD.md` ✓、`DONE-R4.md` ✓ —— **5 类全部产出**。

**各件要点**

- `build_courtyard.gd`：`extends SceneTree`，仅 `_initialize()` 一次性构建后 `quit()`。搭 20 节点树——`Courtyard` 根 → `SubViewportContainer`（`stretch=true` / `stretch_shrink=2` / Nearest）→ `SubViewport`（`640×360` / `own_world_3d=true` / `UPDATE_ALWAYS`）→ `Camera3D`（斜俯视 `fov=40`）、`SunLight`（暖金 `Color(1,0.82,0.55)` + 阴影）、`WorldEnvironment`（冷色环境 + 冷夜雾）、`Terrain`（`PlaneMesh` 地面 + `TerraceLow` / `TerraceHigh` / `CliffRim` 三处 `BoxMesh` 高低差）、`BackdropFar` / `BackdropMid` / `WetReflection`、`Player` → `Hybrid2D3DAnimatedSprite`（`set_script` 挂 I-4 `hybrid_2d3d_animated_sprite.gd`）→ `PixelSprite`、`ChunkRoot`（空 `Node3D`）、`FXLayer` → `LightDust`。先叶子后父级设 owner 链（跳过 `scene_file_path` 非空的实例化节点）→ `PackedScene.pack()` → `instantiate()` 比对节点数 → **比对通过才** `ResourceSaver.save()` → `_free_tree()` 后序释放游离树。无 `_ready` / `_process` / 信号连接 / 游戏状态；全静态类型。
- `courtyard.tscn`：G4 真跑生成物，`20` 个 `[node]`、`ext_resource` 指向 I-4 脚本、`Environment` + 4 份 `StandardMaterial3D` + `PlaneMesh` + 3 份 `BoxMesh` 子资源；G7 直接打开成功。
- `chunk_streaming_r4.gd`：`extends Node`，M2「3×3 常驻流式加载」可测实现。完整时序 `load_threaded_request → load_threaded_get_status → load_threaded_get`；`UNLOADED/LOADING/LOADED` **三态去重**（延迟卸载为 `LOADED` 上的待释放标记、不引入第四态，折返取消以复用实例）；`chunk_loaded` / `chunk_unloaded`（另带 `chunk_load_failed` / `player_chunk_changed`）信号；**只经 `WorldState.get_flag` / `set_flag` 读写 flag**（I-1，不碰存档 / 不构造 SaveDelta）；`pump()` / `get_state()` / `get_load_count()` / `get_seen_chunk_ids()` / `read_loaded_flag()` 可测接口。与 R2 `chunk_streaming.gd` 并存、不替换、接口对齐。
- `M1-M2-BUILD.md`：三段门禁 + 构建脚本 + M2 驱动 + 打开场景的全部实际命令与输出结论（含 `SCRIPT ERROR` grep 逐条归类、5 条 WARNING 归类、双档帧时间核对）。
- `DONE-R4.md`（本文件）：① 实际交付清单 ② 自检结果（含真跑输出结论）③ 未完成项与阻塞。

**R2/R3 已产出、本轮明确一律保留、不重做**：`project.godot`、`scene_router.gd`、`camera_rig.gd`、`performance_hud.gd`、`quality_preset.gd`、`quality_preset_desktop.tres`、`quality_preset_mobile.tres`、`build_main.gd`、`render_profiles.gd`、`render_profiles.tres`、`场景树骨架.tscn`、`chunk_streaming.gd`、`hybrid_2d3d_animated_sprite.gd`、`BUILD.md`、`README.md`、`接口契约.md`、`架构设计.md`、`目录与命名规范.md`、`DONE-R2.md`、`DONE-R3.md`，以及历史 `任务书*.md` / `调度任务单*.json`。本轮未改动上述任何一件。

---

## ② 自检结果（含真跑的实际输出结论）

### 2.1 临时验证工程（真跑载体）

- 位置：系统临时目录 `C:\Users\62668\AppData\Local\Temp\r1_r4_verify`（**不在 teamwork 内、不提交、用完即删**）。
- 放入：本工位 `project.godot` + R2/R3 全部既有 `.gd` / `.tres` + 占位 `scenes/Main.tscn` + R4 两个新脚本；3 个最小依赖替身 stub（`world_state.gd` 实提供 `get_flag` / `set_flag`）；12 个占位 chunk 场景；1 个临时 M2 验收驱动 `m2_verify.gd`；`logs/`。
- stub / 驱动 / 占位场景**均非探针 / 测量 / preflight 脚本**（不扫别人工位、不轮询、不反复核对状态），与 R3 的验证工程 stub 同口径；记录结论后删除，未留在 teamwork 内。

### 2.2 三段构建门禁（契约 §10，真跑）

`<godot>` = `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`<tmp>` = `C:/Users/62668/AppData/Local/Temp/r1_r4_verify`。

| 段 | 实际命令 | 退出码 | 实际输出结论 |
|---|---|---|---|
| 0 | `<godot> --version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `<godot> --headless --path <tmp> --import` | `0` | `first_scan_filesystem` 五步 DONE；`update_scripts_classes` 14 步 DONE；全局类 `QualityPreset` / `RenderProfiles` / `HybridSpriteRig` 注册成功；无 Parse Error |
| 2 | `<godot> --headless --path <tmp> --check-only --script res://<f>.gd`（14 个 `.gd`） | **14 条均 `0`** | 含本轮 changed `build_courtyard.gd` / `chunk_streaming_r4.gd` 在内，全部静态解析通过 |
| 3 | `<godot> --headless --path <tmp> --quit` | `0` | 打开占位主场景 `scenes/Main.tscn` 成功；`SceneRouter._ready()` 加载两份 `quality_preset_*.tres` 成功 |

### 2.3 R4 构建脚本实跑（三段门禁之外，任务书 R4 §真跑要求）

| 步 | 实际命令 | 退出码 | 实际输出结论 |
|---|---|---|---|
| 4 | `<godot> --headless --path <tmp> --script res://scripts/build_courtyard.gd` | `0` | `[courtyard] BUILD_OK output=res://scenes/courtyard.tscn nodes=20`；`pack()` → `instantiate()` 节点数比对 `20 = 20` 通过 → 才 `save()`；`grep -c '^\[node ' courtyard.tscn` = `20` 双重印证；工位交付件与生成物 `diff -q` 一致 |
| 5 | `<godot> --headless --path <tmp> --quit`（生成 courtyard 后复开） | `0` | 工程仍正常启动退出，生成物未破坏工程 |
| 7 | `<godot> --headless --path <tmp> --quit-after 2 res://scenes/courtyard.tscn` | `0` | 直接打开 R4 主场景 `courtyard.tscn` 成功；G7 日志 `SCRIPT ERROR = NONE` |

### 2.4 M2 流式加载实跑（往返走可测）

| 步 | 实际命令 | 退出码 | 实际输出结论 |
|---|---|---|---|
| 6 | `<godot> --headless --path <tmp> --script res://scripts/m2_verify.gd` | `0` | `[m2_verify] seen=12 loaded_now=12 max_load_count=1 center_ok=true chunk_loaded_events=12 chunk_unloaded_events=0 flags_ok=true`；`[m2_verify] M2_PASS 往返走不重复加载（3x3 常驻，get_load_count 恒为 1）`；无 warning |

驱动喂 `(0,0) → (1,0) → (0,0)` 往返：`12` 个 chunk 各 `get_load_count` 恒为 `1`（无重复加载）、3×3 中心 `9` 块全部 `LOADED`、`chunk_loaded` 事件 `12` 次、flag 桥接经 `WorldState.set_flag/get_flag` 真实生效（`flags_ok=true`）。证明 `load_threaded_request/get_status/get` 完整时序、三态去重、折返复用、`chunk_loaded/chunk_unloaded` 信号、I-1 flag 桥接均真跑可用。

### 2.5 grep 校验（关键：运行时 SCRIPT ERROR 不改退出码，必须 grep 才算通过）

对 `<tmp>/logs/` 全部日志（含 G7）：

```
grep -rn   "SCRIPT ERROR"                <logs>   → NONE
grep -rniE "parse error|\berror\b|failed" <logs>   → NONE
grep -rni  "warning"                     <logs>   → 命中 6 行
```

- **SCRIPT ERROR：NONE**（含 G7 打开 `courtyard.tscn` 单独复核 `G7 SCRIPT ERROR: NONE`）。
- **ERROR / Parse Error / Failed：NONE**（无 `ERROR: RID allocations leaked`，无任何 Parse Error / Failed）。
- WARNING 命中 6 行，其中 WARNING 级消息 **5 条**，逐条归类、无一是 SCRIPT ERROR / ERROR：
  1. `2 ObjectDB instances were leaked at exit` × 4 条（G3 / G4 / G5 / G7）—— **headless 快速退出的 WARNING 级资源清理残留**，见 2.6。
  2. `[ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。` × 1 条（G4）—— R2 既有 `chunk_streaming.gd` autoload 在构建脚本自定义 MainLoop 里找不到 `ChunkRoot` 的降级提示（新建树未挂进 `SceneTree.root`，属预期）。
  - 余 1 行为 `at: push_warning (...)` 的 backtrace 定位行，非独立消息。
  - G6（自定义 MainLoop、节点挂 `root` 树、不打开场景）无任何 warning。

### 2.6 关于 `ObjectDB leaked` WARNING（如实记录，未隐瞒、未消除）

`WARNING: 2 ObjectDB instances were leaked at exit` 出现在所有「打开场景后 headless 快速退出」的段（G3 / G4 / G5 / G7），G6 无。判为 headless `--quit` / `--quit-after` 快速退出时 autoload 单例与 `SubViewport(own_world_3d=true)` 相关资源的清理残留：**WARNING 级、非 SCRIPT ERROR、非 ERROR、不改退出码**（四段均 EXIT=0），不影响 `courtyard.tscn` 生成物与 G6 的 M2 结论。R3 曾出现的 `ERROR: RID allocations leaked` 在本轮未出现（R4 `build_courtyard.gd` 沿用 R3 `_free_tree()` 后序释放，游离树已清理）。该残留来自验证工程既有 autoload / 场景打开方式，未在 R2/R3 交付件基础上额外引入 R4 交付件缺陷；按「不伪造输出」原则如实登记，未在 R4 范围内强行改动 autoload 或场景打开方式去消除。

### 2.7 桌面 / 移动双档帧时间核对

`render_profiles.tres`（R3 两列）+ `quality_preset_desktop.tres` / `mobile.tres`（R2 单档运行参数）三份资源数值一致：桌面 `640×360` @2x / 常驻 `9` / 目标 `16.67 ms`（60 fps）/ `1536 MB` / FX 全开；移动 `480×270` @2x / 常驻 `4` / 目标 `33.33 ms`（30 fps）/ `512 MB` / FX 全关。G1 `--import` 解析通过、G3 / G5 `--quit` 时 `SceneRouter._ready()` 实际加载两份 `quality_preset_*.tres` 成功。`courtyard.tscn` 的 `SubViewport` 为 `640×360` / `stretch_shrink=2` / `texture_filter=1`（`TEXTURE_FILTER_NEAREST`，与 R3 `build_main.gd` 同口径；R2 手写骨架 `0` 为 `PARENT_NODE` 继承、靠项目级 `default_texture_filter=0` 兜底，等效 Nearest）。**headless 真跑无渲染管线，帧时间为资源表目标值静态核对、非实测**；运行期帧时间 / p99 / spike 需人工试玩，见 ③。

### 2.8 总自检结论

**三段门禁真跑通过（含 `SCRIPT ERROR` grep = NONE、`ERROR/ParseError/Failed` grep = NONE）**；`build_courtyard.gd` 实跑生成 20 节点 `courtyard.tscn` 并完成 `pack()/instantiate()` 节点数 `20 = 20` 比对、G7 直接打开成功；G6 M2 往返走驱动 `M2_PASS`（不重复加载、三态去重、flag 桥接生效）；桌面 / 移动双档资源经 `--import` 与 `--quit` 加载校验。本工位新增的 `.gd` / `.tscn` 均为 Godot 4.7.2 合法语法、可解析可打开，全静态类型。5 条 WARNING 全部逐条归类、无一是 SCRIPT ERROR / ERROR。真跑可用，未伪造输出。

### 2.9 回执投递与中枢接收

`cmd-20261109-005741-232-A1.json` 于 `2026-11-09 01:24` 写入 `command_center\ai\1\outbox\`（`status=done`，`result` 引用本文件实际结论），随后被运行中中枢即时消费回收（outbox 清空，与 R2/R3 回执「写完即回收」行为一致）。**中枢确已接收并登记**的直接证据：

- `command_center/dispatcher/ledger.jsonl` 中 `cmd-20261109-005741-232-A1` 一条 `status=done`、`finished_at=2026-11-09 01:25:51`，其 `result` 与本回执 `result` **逐字一致**（证明 JSON 被成功解析、`task_id` 匹配、内容未丢）。
- `command_center/ai/1/status.json` 由本轮开工时的 `state=working / current_task=cmd-20261109-005741-232-A1 / completed=2` 更新为 `state=idle / current_task=""` 并清空当前任务（`completed` 在 `01:24:07` 为 `3`、`01:25:51` 后续处理累计为 `4`，属中枢累计计数，不影响本轮 `done` 判定），即中枢已判定 R4 完成。

收尾时为保障 HOST 复核可见，曾按同一内容在 outbox 重写该回执，同样被中枢即时消费回收 —— 故复核时 outbox 为空是中枢正常回收状态，**非未写回执**；以 `ledger.jsonl` 的 `done` 记录与 `status.json` 为准。回执内容合法 JSON（UTF-8），`task_id` / `ai` / `status` 三键与 `00-调度中枢接入说明.md` §3 格式一致。

---

## ③ 未完成项与阻塞（含待 HOST 裁决 / 口径登记）

### 3.1 未完成项（均如实登记，非阻塞本轮完成标志）

| 项 | 说明 |
|---|---|
| 工程根 `F:\Game\aierdengfahuan\` 未建立 | 交付件为工位内文本件，供建工程根时拷贝（R3 遗留，延续） |
| 3 号 `WorldState` / `GameEvents` / `SaveSystem` 真实实现 | 未到位，验证工程用 stub；R4 flag 桥接经 stub + M2 驱动实测 `flags_ok=true`，真实实现到位后需回归 |
| 3 号 chunk 场景 / 地牢场景 / 赐福网络 | 未到位，验证工程用 12 个占位 chunk 场景（纯 `Node3D` + `BoxMesh`）让 M2 可测；真实 chunk 场景到位后需回归 M2 |
| 4 号 `import.json` / spritesheet / ≤256 色索引调色板 | I-5 未联调；`PixelSprite` 无贴图、`pose_frame_counts` 待导入流程回填；像素 128px + ≤256 色规格由 4 号落位 |
| GDExtension `Hybrid2D3D-Renderer` 装入与 `set_custom_aabb` 真实 API 校准 | 待 M0；`hybrid_2d3d_animated_sprite.gd` 已有 `has_method` / 属性守卫，扩展不在时静默降级（R2 件，未改） |
| 移动端常驻 chunk 数 `4` 的运行时落地 | **R2 遗留，本轮未实现、未伪造**：`render_profiles.tres` / `quality_preset_mobile.tres` 写 `4`，R2 `chunk_streaming.gd` 固定 `RADIUS=1` → 9 块；R4 新增 `chunk_streaming_r4.gd` 亦固定 3×3 = 9 块，未实现按档位调整半径 |
| 桌面 / 移动双档运行期帧时间 / p99 / spike 实测 | headless 无渲染管线，本轮仅做资源表 `16.67 / 33.33 ms` 静态核对；「性能监视器无 spike」「p99 ≤ 20 ms / 单帧 ≤ 33.3 ms」需 F3 性能 HUD + 人工试玩，本轮未做、未伪造 |
| `build_courtyard.gd`「跳过实例化节点」分支真实验证 | 逻辑已在 `_assign_owner()` 实现；本轮构建的树全为 `new` 节点（`scene_file_path` 为空），跳过分支未被真实触发，待 M0 真实 GLB 实例化装入后验证（同 R3 `build_main.gd` 遗留） |
| `ObjectDB leaked` WARNING（G3/G4/G5/G7 各 2 实例） | headless 快速退出的 WARNING 级残留，非 SCRIPT ERROR / ERROR、不影响 EXIT 与生成物；如实登记未消除（见 2.6），未在 R4 范围改动 autoload / 场景打开方式 |
| exe / apk 导出 | 未实跑；导出模板 / Android SDK·NDK·JDK / keystore 的 D 盘具体路径待登记（前置清单见 R3 `BUILD.md` §5），本轮不主动扫盘 |
| 人工试玩 / 手感 / 审美判断 | 按总纲与契约由用户亲自兜底，本轮未做 |

### 3.2 需 HOST 裁决 / 口径登记的分歧项

1. **`courtyard.tscn` 落地方式**：任务书 R4 要求「由构建脚本真跑生成的主场景」。本轮由 G4 实跑 `build_courtyard.gd` 生成 `<tmp>/scenes/courtyard.tscn` 后**原样拷回**工位（`diff` 一致）；工位目录内未直接跑引擎写文件（避免在 teamwork 内生成 `.godot` 缓存、遵守「唯一可写 Rank-1 + outbox」）。构建脚本产出路径按 `res://scenes/courtyard.tscn` 落位。请 HOST 确认此解释。
2. **`--check-only --script <changed>.gd` 覆盖面**：本轮 changed = `build_courtyard.gd` + `chunk_streaming_r4.gd`，均 `EXIT=0`；另对验证工程全量 14 个 `.gd` 都跑了 `--check-only`，覆盖面大于最低要求。
3. **临时 M2 驱动脚本 `m2_verify.gd` 的口径**：位于系统临时验证工程、不进交付清单、用完即删；性质为「对本轮交付件的一次性功能验证」，与 R3 的 stub 同口径，非探针 / 测量 / preflight（不扫别人工位、不轮询、不反复核对状态）。如实登记，若 HOST 判定此类驱动亦属禁写范围，删除即可不影响三段门禁与 G4 结论，但 M2「往返走不重复加载」将只剩静态解析 + 接口可测、无运行期实证。
4. **任务书 R4 §完成标志的群聊总线**：任务书 R3 曾要求追加 `TYPE=交付完成` 消息，R4 未再要求；本轮用户硬性约束明确「不写群聊总线、唯一可写 Rank-1 + outbox 回执」。按用户指令**未写总线**，由 HOST 统一收尾，如实登记。
5. R2/R3 遗留待裁决（延续，未擅自改）：4 号 A8 `@3x` vs 本工位 `@2x` 冻结值、负坐标 chunk id 命名、`GameEvents` 最终归属、`canvas_items` vs `canvas_textures` 合法键、`config_version`「实测填写」口径、`HybridSpriteRig` 类名与 GDExtension 全局类同名风险、`128bit` 确切含义。

---

## ④ 合规声明

- 只写 `F:\Game\aierdengfahuan\teamwork\Rank-1\`；唯一例外为按中枢协议在 `command_center\ai\1\outbox\` 写回执 JSON。未写 `Rank-2/3/4\`、未写 teamwork 根目录、未改总纲 / 契约 / 历史任务书。
- **未写群聊总线**（用户硬性约束，见 ③ 3.2 第 4 条）；未自行 `git commit` / `git push`；未打开或改动 R4 之外的历史派单。
- 零付费 / 零外部依赖：未引用付费素材、未调用 `asset-gen/api.md` 付费 API、未列云服务或花费确认项。
- 默认不刺探：开工只读一次必读清单（`任务书-R4.md` / `调度任务单-latest.json` / `DONE-R3.md` / `build_main.gd` / `project.godot` / `00-协作契约.md` / `00-群聊总线.md` / `00-工具链接入说明.md` / `00-项目总纲.md`）；未扫别人工位、未轮询、未写探针 / 测量 / preflight 脚本；临时验证工程在系统临时目录，用完即删。
- 遵守 I-4：`set_pose(pose_name, frame_index)` 不扩展接口、pose 名冻结、`frame_index` 为动作内帧索引且 clamp 归 1 号；像素素材 128px + ≤256 色；负坐标 chunk id 按契约字面保留负号。
- R2/R3 既有交付件一律保留、不重做；中文 UTF-8；`.gd` / `.tscn` 均经 Godot 4.7.2 真跑验证为合法语法，GDScript 全静态类型。

## ⑤ 完成标准

`任务书-R4.md` §交付清单的 5 类固定文件全部产出、`DONE-R4.md` 存在、三段门禁真跑结论（含 `SCRIPT ERROR` grep = NONE）已记录、outbox 回执 JSON 已写 —— **达成**。
