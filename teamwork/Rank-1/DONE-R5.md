# DONE-R5 · Rank-1（引擎架构与渲染）完成标志

> 轮次：R5（HOST 全闭环调度续派；兜底循环，因每小时自动化 01:36 未触发）
> 派单：`Rank-1\任务书-R5.md` ｜ 任务单 id：`cmd-20261109-013419-300-A1`
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`｜`--version` 实测 `4.7.2.stable.official.ed1daf0bf`（EXIT=0）
> HOST 监测只认本文件。本轮只写 `F:\Game\aierdengfahuan\teamwork\Rank-1\`，唯一例外为
> `command_center\ai\1\outbox\` 回执 JSON；未写其它工位 / teamwork 根目录 / 总纲 / 契约 / 群聊总线 / 历史任务书；
> 未自行 git commit / push。
> 真跑结论全部来自实际输出，未伪造、未写「未找到 godot、无法真跑」的旧结论。

---

## ① 本轮实际交付 / 新增文件清单

| # | 文件（绝对路径） | 动作 | 工程落位（`res://`） |
|---|---|---|---|
| 1 | `F:\Game\aierdengfahuan\teamwork\Rank-1\project_root\`（整目录，17 件） | **新建** | 工程根实体目录树：`project.godot` + `scripts/`（core / render / ui / world / 2 个构建脚本）+ `scenes/`（Main.tscn / courtyard.tscn）+ `data/render/`（3 份 .tres） |
| 2 | `F:\Game\aierdengfahuan\teamwork\Rank-1\chunk_streaming_r5.gd` | **新建** | `scripts/world/chunk_streaming_r5.gd`（工程树内同名副本，内容一致） |
| 3 | `F:\Game\aierdengfahuan\teamwork\Rank-1\PROJECT_ROOT_LAYOUT.md` | **新建** | `docs/`（工程树映射表 / 跨工位依赖 / 真跑证据 / 落位步骤 / 待裁决） |
| 4 | `F:\Game\aierdengfahuan\teamwork\Rank-1\DONE-R5.md` | **新建**（本文件） | — |
| 5 | `F:\Game\aierdengfahuan\teamwork\command_center\ai\1\outbox\cmd-20261109-013419-300-A1.json` | **新建**（中枢协议例外） | — |

**对照 `任务书-R5.md` §交付清单 4 类**：
- 工程根 `project.godot` 与 `res://` 目录树实际落位 → `project_root\` 17 件 ✓（物理工程根在 teamwork 外，见 ③）
- 与 Rank-3 的 WorldState / chunk 场景跨模块联调 → G4 联调驱动 `I1 ... applied_flags_ok=true`、`flag_ok=true` ✓
- 移动端 4 chunk 运行时落地 → `chunk_streaming_r5.gd` + G4 `resident=4 wanted=4 loaded=4` ✓（帧时间实测见 ③）
- ObjectDB leaked WARNING 定位与消除 → 9 组对照实证定位 + G3' 消除方案 ✓

**各件要点**

- `project_root\`：**R2/R3/R4 既有件一律原样拷贝、未改一字**（含 `project.godot`、`chunk_streaming.gd`、
  `chunk_streaming_r4.gd`、`courtyard.tscn` 等），按 `project.godot` 的 `res://` 引用路径实际分目录铺开。
  `scenes/Main.tscn` 由 R2 手写骨架 `场景树骨架.tscn` 占位（对应 `run/main_scene`）。完整 17 件映射表见
  `PROJECT_ROOT_LAYOUT.md` §2。工位目录内未跑引擎写文件，避免生成 `.godot` 缓存。
- `chunk_streaming_r5.gd`：`extends Node`，新增「按画质档位调整常驻 chunk 数」的运行时实现。
  以 R4 `chunk_streaming_r4.gd` 接口为基准（三态去重、`load_threaded_request → get_status → get` 完整时序、
  折返复用、`chunk_loaded/chunk_unloaded` 信号、只经 `WorldState.get_flag/set_flag` 读写 flag 的 I-1 桥接、
  `pump()` / `get_state()` / `get_load_count()` / `get_seen_chunk_ids()` / `read_loaded_flag()` 可测接口）。
  新增档位联动：`set_resident_chunk_count(count)` / `configure_from_preset(preset)` /
  `apply_preset_path(path)` / `get_resident_chunk_count()` / `get_wanted_ids()`，以及
  `resident_chunk_count_changed` 信号。邻域在 `[-2,2]²` 25 个候选中按「平方距离 → dx → dy」确定性排序取前 N 个：
  **N=9 恰为完整 3×3（桌面档行为不变），N=4 为最近 4 块（移动档降级）**，任意 1..25 档位数值直接生效
  （总纲「数据表改数值不改代码」）。与 `SceneRouter.set_quality_preset()` / `active_preset_path` 联动。
  **不替换 R2 `ChunkManager` autoload、不修改 R2/R4 件**，四者并存、接口对齐。
- `PROJECT_ROOT_LAYOUT.md`：完整映射表 + 3 号跨工位依赖说明 + 三段门禁真跑证据 + ObjectDB 定位表 +
  落位操作步骤 + 待 HOST 裁决项。
- `DONE-R5.md`（本文件）：① 实际交付清单 ② 自检结果（含真跑实际输出结论）③ 未完成项与阻塞。

**R2/R3/R4 已产出、本轮一律保留、不重做**：`project.godot`、`scene_router.gd`、`camera_rig.gd`、
`performance_hud.gd`、`quality_preset.gd`、`quality_preset_desktop.tres`、`quality_preset_mobile.tres`、
`build_main.gd`、`render_profiles.gd`、`render_profiles.tres`、`场景树骨架.tscn`、`chunk_streaming.gd`、
`hybrid_2d3d_animated_sprite.gd`、`build_courtyard.gd`、`courtyard.tscn`、`chunk_streaming_r4.gd`、
`BUILD.md`、`M1-M2-BUILD.md`、`README.md`、`接口契约.md`、`架构设计.md`、`目录与命名规范.md`、
`DONE-R2.md`、`DONE-R3.md`、`DONE-R4.md`，以及历史 `任务书*.md` / `调度任务单*.json`。
本轮未改动上述任何一件（`project_root\` 内为原样拷贝，非修改）。

---

## ② 自检结果（含真跑的实际输出结论）

### 2.1 临时验证工程（真跑载体）

- 位置：系统临时目录 `C:\Users\62668\AppData\Local\Temp\r1_r5_verify`（**不在 teamwork 内、不提交、用完即删**）。
- 构成：`project_root\` 整体拷入 + 3 个最小依赖替身 stub（`world_state.gd` 实提供 `get_flag/set_flag`、
  `game_events.gd`、`save_system.gd`）+ 30 个纯 `Node3D` 占位 chunk 场景 +
  联调驱动 `scripts/r5_verify.gd`（`extends Node`）+ 验证场景 `scenes/Verify.tscn` + `logs/`。
- stub / 驱动 / 占位场景**均非探针 / 测量 / preflight 脚本**（不扫别人工位、不轮询、不反复核对文件状态），
  与 R3/R4 验证工程同口径；记录结论后删除，未留在 teamwork 内。
- 口径修正（如实登记）：首轮占位场景曾带 `ext_resource` 引用共享脚本，9 个场景并发加载触发
  `Parse Error: Failed`（`_parse_node_tag`）；改为纯 `Node3D` 占位场景后 Parse Error 归零。
  首轮联调驱动用 `extends SceneTree` 自定义 MainLoop，`get_tree()` 返回 null；改为「验证场景 +
  `extends Node` + `_ready` 里 `call_deferred` 延后一帧」后正常。两处均为临时验证工程自身问题，
  非工位交付件缺陷，修正后重跑通过。

### 2.2 三段构建门禁（契约 §10 / `00-工具链接入说明.md` §4.2，真跑）

`<godot>` = `D:/Godot/Godot_v4.7.2-stable_win64.exe`；`<tmp>` = `C:/Users/62668/AppData/Local/Temp/r1_r5_verify`。

| 段 | 实际命令 | EXIT | 实际输出结论 |
|---|---|---|---|
| G0 | `<godot> --version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| **G1** | `<godot> --headless --path <tmp> --import` | `0` | `first_scan_filesystem` 五步 DONE；`update_scripts_classes` 16 步 DONE；全局类 `QualityPreset` / `RenderProfiles` / `HybridSpriteRig` 注册成功；无 Parse Error |
| **G2** | `<godot> --headless --path <tmp> --check-only --script res://<f>.gd`（循环 16 个 `.gd`） | **16 条均 `0`** | 含本轮新增 `chunk_streaming_r5.gd`、改动后 `r5_verify.gd` 在内，全部静态解析通过；覆盖面大于「changed 件」最低要求 |
| **G3** | `<godot> --headless --path <tmp> --quit` | `0` | 打开占位主场景 `scenes/Main.tscn` 正常启动退出；仅 `WARNING: 2 ObjectDB instances were leaked at exit`（定位 / 消除见 2.5） |

### 2.3 额外真跑（M1 联调 / 移动档 / 主场景 / 消除方案）

| 段 | 实际命令 | EXIT | 实际输出结论 |
|---|---|---|---|
| G4 | `<godot> --headless --path <tmp> --quit-after 300 res://scenes/Verify.tscn` | `0` | 联调驱动 `R5_PASS`（逐字输出见 2.4） |
| G5 | `<godot> --headless --path <tmp> --quit-after 2 res://scenes/courtyard.tscn` | `0` | 直接打开 R4 M1 主场景 `courtyard.tscn` 成功 |
| G3' | `<godot> --headless --path <tmp> --quit-after 10` | `0` | 消除方案实证：全日志 `SCRIPT ERROR / ERROR / WARNING / leaked = NONE` |

### 2.4 G4 联调驱动实际输出（逐字，未伪造）

```
[r5_verify] M1 courtyard_nodes=20 chunkroot_found=true
[r5_verify] I1 chunkroot_bound=true get_flag_calls=1 applied_flags_ok=true
[r5_verify] desktop apply=true resident=9 wanted=9 loaded=9
[r5_verify] mobile active=res://data/render/quality_preset_mobile.tres resident=4 wanted=4 loaded=4
[r5_verify] roam wanted=4 seen=7 max_load_count=1 all_one=true set_flag_calls=16 flag_ok=true
[r5_verify] SUMMARY m1=true i1=true chunk=true
[r5_verify] R5_PASS M1 垂直切片 + I-1 跨模块联调 + 移动端 4 chunk 运行时落地全部通过
```

逐项含义：
- **M1 垂直切片联调**：`courtyard.tscn` 实例化 20 节点，`ChunkRoot` 存在；R2 `ChunkManager` 与 R5 管理器
  均绑定到同一 `ChunkRoot`（`chunkroot_bound=true`）。
- **I-1 跨模块联调**：R2 `ChunkManager._apply_world_flags` 经 `WorldState.get_flag` 读 flag 并回灌 chunk 实例
  （`get_flag_calls=1`、`applied_flags_ok=true`）；R5 加载 chunk 经 `WorldState.set_flag` 写
  `chunk.*.loaded`（`set_flag_calls=16`），`read_loaded_flag` 读回 `flag_ok=true`。
- **桌面档**：`apply_preset_path(quality_preset_desktop.tres)` → `resident=9`、`wanted=9`、`loaded=9`。
- **移动档 4 chunk 运行时落地**：经 `SceneRouter.set_quality_preset(true)` 切到
  `res://data/render/quality_preset_mobile.tres` → `resident=4`、`wanted=4`、`loaded=4`
  （档位切换后多余 5 块经延迟卸载收敛，实测常驻 4 块）。
- **往返走**：独立移动档实例 `(0,0)→(1,0)→(0,0)`，`seen=7`、`max_load_count=1`、`all_one=true`
  （折返复用、不重复加载）。

### 2.5 `ObjectDB leaked` WARNING 定位与消除（R5 重点，9 组对照实证）

`--verbose` 明细：泄漏对象为 **2 个裸 `RefCounted`（Reference count: 1）**，非 Node / Resource 子类。

| 对照 | 配置 | leaked |
|---|---|---|
| C0 | 完整工程 `--quit --verbose` | 2 |
| C1 | 最简空工程（无 autoload / 无脚本 / 纯 Node 主场景）`--quit` | 0 |
| C2 | 完整工程去掉 `[autoload]` 段 `--quit` | 0 |
| C3 | 完整工程主场景换纯 Node（无 SubViewport）`--quit` | 2 |
| C4 | 仅 1 个最简 autoload stub `--quit` | 0 |
| C5 | 完整工程 `--quit-after 60 --verbose` | 0 |
| 帧数扫描 | `--quit-after N`：N=1/2/3/5 → 2；N=10/20/60 → 0 | 临界 5~10 帧 |
| 单 autoload | 5 个 autoload 逐个单独注册：仅 `ChunkManager` → 2，其余 4 个 → 0 | 命中 ChunkManager |
| D1 | 仅 ChunkManager 但移除占位 chunk 场景（9 次 `scene_missing`，`load_threaded_request` 未发起） | 0 |
| G3' | 完整工程 `--quit-after 10` | 0，且全日志无任何 WARNING |

**定位结论**：R2 `chunk_streaming.gd`（`ChunkManager` autoload）在 `auto_start=true` 下，
`--quit` 单帧快速退出时其发起的 `load_threaded_request` 在途异步任务（受 `max_concurrent_loads=2` 限制，
恰好 2 个）未完成清理，导致 2 个裸 `RefCounted` 残留。与 `SubViewport` / `own_world_3d` / 主场景内容 /
其它 autoload / R5 新增件均无关。**实证纠正 R4「autoload 单例与 SubViewport 相关资源清理残留」的判定**。
对照实验均为引擎真跑门禁变体（改临时工程配置 / 退出帧数），非探针 / 测量 / preflight 脚本。

**消除结论**：退出方式由 `--quit`（1 帧）改为 `--quit-after N`（N≥10），让在途任务完成 → WARNING 消失
（G3' 实证 EXIT=0、全日志 `SCRIPT ERROR / ERROR / WARNING / leaked = NONE`）；非 headless 正常运行不存在。
根因在 R2 既有交付件，受本轮「不改既有交付件内容（只追加 / 补齐）」与「R2/R3/R4 件一律保留」约束，
**未修改** `chunk_streaming.gd` / `project.godot`；契约 §10 第三段门禁固定 `--headless --quit`，
G3 仍按契约跑并如实登记 WARNING，另附 G3' 作消除方案实证。若 HOST 授权改 R2 件，可在 `_bootstrap`
加 headless 门禁守卫或把 `auto_start` 默认置 false 彻底消除 —— 本轮不擅自改。

### 2.6 grep 校验（关键：运行时 SCRIPT ERROR 不改退出码，必须 grep 才算通过）

对主门禁日志（`g1_import` / `g2_checkonly` / `g3_quit` / `g4_verify` / `g5_courtyard` / `g3p_quit10`）：

```
grep -n   "SCRIPT ERROR"                    → NONE
grep -niE "parse error|\berror\b|failed"    → NONE
grep -ni  "WARNING"                        → 4 条消息（+1 行 backtrace 定位）
```

- **SCRIPT ERROR：NONE**；**ERROR / Parse Error / Failed：NONE**（首轮占位场景 Parse Error 已修复归零）。
- WARNING 4 条逐条归类、无一是 SCRIPT ERROR / ERROR：
  1. `2 ObjectDB instances were leaked at exit` × 3（G3 / G4 / G5）—— 见 2.5，已定位并给出消除方案。
  2. `[ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。` × 1（G4）—— R2 autoload 的
     deferred `_bootstrap` 早于验证场景挂 courtyard 的降级提示；驱动随后手动 `_bootstrap` 重新绑定成功
     （`chunkroot_bound=true`），属预期、同 R4 G4 口径。
  - 余 1 行为 `at: push_warning (...)` backtrace 定位行，非独立消息。
- G3'（`--quit-after 10`）单独复核：全日志 `SCRIPT ERROR / ERROR / WARNING / leaked = NONE`。

### 2.7 桌面 / 移动双档与帧时间核对（如实登记，未伪造）

`render_profiles.tres` + `quality_preset_desktop.tres` / `mobile.tres` 数值一致：桌面 `640×360` @2x /
常驻 `9` / 目标 `16.67 ms`（60 fps）/ `1536 MB` / FX 全开；移动 `480×270` @2x / 常驻 `4` /
目标 `33.33 ms`（30 fps）/ `512 MB` / FX 全关。G1 `--import` 解析通过、全局类注册成功；
G4 运行时**实测**桌面 `resident=9 loaded=9`、移动 `resident=4 loaded=4`（不再是 R2/R4 的固定 9 块）。
**headless 真跑无渲染管线，帧时间 / p99 / spike 无法实测**：`16.67 / 33.33 ms` 为资源表目标值静态核对，
运行期帧时间需 F3 性能 HUD + 人工试玩，本轮未做、未伪造（见 ③）。

### 2.8 总自检结论

三段门禁真跑通过（G1/G2/G3 全 `EXIT=0`，16 个 `.gd` 全静态解析通过）；
`SCRIPT ERROR = NONE`、`ERROR/ParseError/Failed = NONE`；`R5_PASS` 实证 M1 垂直切片 20 节点联调、
I-1 双向 flag 桥接、桌面 9 / **移动 4 chunk 运行时落地**、往返走不重复加载；
G5 直接打开 `courtyard.tscn` 成功；`ObjectDB leaked` 经 9 组对照精确定位并给出可复现消除方案（G3' 无 WARNING）。
R5 新增 `.gd` 经 Godot 4.7.2 真跑验证为合法语法、全静态类型。真跑可用，未伪造输出。

### 2.9 回执投递

`cmd-20261109-013419-300-A1.json` 写入 `command_center\ai\1\outbox\`，`status=done`，
`result` 引用本文件实际结论；按 `00-调度中枢接入说明.md` §3 格式（`task_id` / `ai` / `status` / `result`），
合法 JSON（UTF-8）。写出后被运行中中枢**即时消费回收**（outbox 清空），与 R2/R3/R4「写完即回收」行为一致。
**中枢确已接收并登记**的直接证据（本轮收尾只读取一次中枢状态，非刺探别人工位）：
- `command_center/dispatcher/ledger.jsonl` 第 10 行 `cmd-20261109-013419-300-A1` 一条
  `status=done`、`finished_at=2026-11-09 02:01:27`，其 `result` 与本回执 `result` **逐字一致**
  （证明 JSON 被成功解析、`task_id` 匹配、内容未丢）。
- `command_center/ai/1/status.json` 为 `state=idle` / `current_task=""` / `completed=5`
  （收尾重写回执被中枢再次消费后累计为 `6`，属中枢累计计数，不影响本轮 `done` 判定）/
  `last_seen` 同步更新，即中枢已判定 R5 完成。
收尾时按同一内容在 outbox 重写该回执一份以保障 HOST 复核可见；若复核时 outbox 仍为空，
属中枢正常回收状态、**非未写回执**，以 `ledger.jsonl` 的 `done` 记录与 `status.json` 为准。

---

## ③ 未完成项与阻塞（含待 HOST 裁决 / 口径登记）

### 3.1 未完成项（均如实登记，非阻塞本轮完成标志）

| 项 | 说明 |
|---|---|
| 工程根物理路径 `F:\Game\aierdengfahuan\` 未写入 | 位于 `teamwork\` 外，超出本轮「唯一可写 Rank-1 + outbox」硬约束；已交付工位内 `project_root\` 完整 `res://` 工程树（17 件）并真跑验证，物理拷贝落位由 HOST / 主 AI 收尾执行（见 `PROJECT_ROOT_LAYOUT.md` §6） |
| 3 号 `WorldState` / `GameEvents` / `SaveSystem` 真实实现 | 未到位，验证工程用 stub；R5 已实证 I-1 双向桥接（读 `get_flag` / 写 `set_flag`）可用，真实实现到位后需回归 |
| 3 号真实 chunk 场景 / 地牢场景 / 赐福网络 | 未到位，验证工程用 30 个纯 `Node3D` 占位 chunk 场景让流式加载可测；真实 chunk 场景到位后需回归 |
| `chunk_streaming_r5.gd` 接入正式工程装配层 | 本轮以临时验证场景实例化并真跑验证可用；正式注册为 autoload 或由装配层实例化需改 `project.godot` / `scene_router.gd`（既有件），超出本轮「只补齐」范围，未改，待 HOST 裁决接入方式 |
| 移动端 4 chunk 的运行期**帧时间 / p99 / spike 实测** | headless 无渲染管线，本轮实测的是常驻 chunk 数 / 加载次数 / flag 桥接等运行时行为；`16.67 / 33.33 ms` 为资源表目标值静态核对。需 F3 性能 HUD + 人工试玩，本轮未做、未伪造 |
| 契约门禁 `--quit` 的 2 leaked WARNING | 已精确定位（R2 ChunkManager 在途线程加载任务 + 快速退出时序）并给出消除方式（`--quit-after 10` 实证消失）；因根因在既有件且契约固定 `--quit`，本轮按契约跑 G3 并如实登记，未擅自改交付件 |
| 4 号 `import.json` / spritesheet / ≤256 色索引调色板 | I-5 未联调；`PixelSprite` 无贴图、`pose_frame_counts` 待导入流程回填 |
| GDExtension `Hybrid2D3D-Renderer` 装入与 `set_custom_aabb` 真实 API 校准 | 待 M0；`hybrid_2d3d_animated_sprite.gd` 已有 `has_method` / 属性守卫，扩展不在时静默降级（R2 件，未改） |
| `build_courtyard.gd`「跳过实例化节点」分支真实验证 | 逻辑已实现；本轮构建的树全为 `new` 节点，跳过分支未被真实触发，待 M0 真实 GLB 实例化装入后验证（同 R3/R4 遗留） |
| exe / apk 导出 | 未实跑；导出模板 / Android SDK·NDK·JDK / keystore 的 D 盘具体路径待登记，本轮不主动扫盘 |
| 人工试玩 / 手感 / 审美判断 | 按总纲与契约由用户亲自兜底，本轮未做 |

### 3.2 需 HOST 裁决 / 口径登记的分歧项

1. **工程根落地口径**：任务书 R5 要求「工程根 `project.godot` 与 `res://` 目录树实际落位」。本轮在
   `Rank-1\project_root\` 建立 17 件实体工程树并用临时验证工程真跑验证可用；`F:\Game\aierdengfahuan\`
   物理路径在 `teamwork\` 外，按用户硬性约束本轮未写。请 HOST 确认此解释并执行拷贝落位。
2. **`ObjectDB leaked` 与 R4 判定的分歧**：R4 判为「autoload 单例与 `SubViewport(own_world_3d=true)`
   相关资源清理残留」；本轮 9 组对照实证为「R2 ChunkManager 的 `load_threaded_request` 在途任务 +
   `--quit` 单帧快速退出时序」，与 SubViewport 无关（C3 换纯 Node 场景仍泄漏、D1 不发请求即无泄漏）。
   属对历史结论的实证纠正，如实登记。
3. **联调驱动 / 对照实验的口径**：验证场景 `Verify.tscn` + `r5_verify.gd`、3 个 stub、30 个占位 chunk 场景、
   以及 C1~C4/D1/帧数扫描等对照工程均位于系统临时验证工程、不进交付清单、用完即删；性质为「对本轮交付件的
   一次性功能验证 + 引擎门禁变体定位」，与 R3/R4 stub 同口径，非探针 / 测量 / preflight 脚本。如实登记。
4. **群聊总线**：用户硬性约束明确「不写群聊总线」，本轮未写，由 HOST 统一收尾。
5. R2/R3/R4 遗留待裁决（延续，未擅自改）：4 号 A8 `@3x` vs 本工位 `@2x` 冻结值、负坐标 chunk id 命名、
   `GameEvents` 最终归属、`canvas_items` vs `canvas_textures` 合法键、`config_version`「实测填写」口径、
   `HybridSpriteRig` 类名与 GDExtension 全局类同名风险、`128bit` 确切含义。

---

## ④ 合规声明

- 只写 `F:\Game\aierdengfahuan\teamwork\Rank-1\`（`project_root\` 为其子目录）；唯一例外为按中枢协议
  在 `command_center\ai\1\outbox\` 写回执 JSON。未写 `Rank-2/3/4\`、未写 teamwork 根目录、未改总纲 / 契约 /
  历史任务书 / 群聊总线。
- **未写群聊总线**（用户硬性约束）；未自行 `git commit` / `git push`；未打开或改动 R5 之外的历史派单。
- 零付费 / 零外部依赖：未引用付费素材、未调用付费 API、未列云服务或花费确认项；未调用 Godogen / ComfyUI
  等外部工具链（本轮任务不涉及素材 / 语音生成）。
- 默认不刺探：开工只读一次必读清单（`任务书-R5.md` / `调度任务单-latest.json` / `DONE-R4.md` /
  `00-协作契约.md` / `00-群聊总线.md` / `00-工具链接入说明.md` / `00-项目总纲.md` §4）与本工位关键既有件；
  未扫别人工位、未轮询、未写探针 / 测量 / preflight 脚本；临时验证工程在系统临时目录，用完即删。
  对照实验为「改临时工程配置 / 退出帧数后跑同一引擎门禁」，属定位根因的必要真跑，非文件巡检。
- 遵守 I-4：`set_pose(pose_name, frame_index)` 不扩展接口、pose 名冻结、`frame_index` clamp 归 1 号；
  像素素材 128px + ≤256 色；负坐标 chunk id 按契约字面保留负号。
- R2/R3/R4 既有交付件一律保留、不重做、未改内容（`project_root\` 内为原样拷贝）；中文 UTF-8；
  新增 `.gd` 经 Godot 4.7.2 真跑验证为合法语法、全静态类型。

## ⑤ 完成标准

`任务书-R5.md` §交付清单 4 类全部产出 / 补齐、`DONE-R5.md` 存在、三段门禁真跑结论
（含 `SCRIPT ERROR` grep = NONE）已记录、ObjectDB leaked 已定位并给出消除实证、
outbox 回执 JSON 已写 —— **达成**（工程根物理落位与帧时间实测按 ③ 如实登记为超范围 / headless 限制阻塞，未伪造）。
