# PROJECT_ROOT_LAYOUT.md · Rank-1 R5（工程根 `res://` 目录树实际落位）

> 派单：`Rank-1\任务书-R5.md` ｜ 任务单 id：`cmd-20261109-013419-300-A1`
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（`--version` 实测 `4.7.2.stable.official.ed1daf0bf`，EXIT=0）
> 本文件所有真跑结论来自实际输出，未伪造；完整自检见 `DONE-R5.md`。

---

## 1. 落地范围与边界（如实登记）

R2/R3/R4 的交付件均为 `Rank-1\` 根目录下的**平铺文本件**，未按 `res://` 路径分目录。
R5 在工位内新建 **`F:\Game\aierdengfahuan\teamwork\Rank-1\project_root\`**，把全部正式交付件按
Godot 4 工程根结构**实际铺开**，形成「拷到工程根即可直接跑」的实体目录树（共 17 件）。

- 约定中的 Godot 工程根物理路径是 `F:\Game\aierdengfahuan\`，位于 `teamwork\` **之外**，
  超出本轮「唯一可写 `Rank-1\`、回执例外写 `outbox\`」的硬约束，**本轮未写入该路径**。
  工程根的物理拷贝落位由 HOST / 主 AI 在收尾时执行，本轮只交付工位内已落位、已真跑验证的工程树。
- 工位目录内**未直接跑引擎写文件**（避免生成 `.godot` 缓存，沿用 R3/R4 口径）：真跑时把
  `project_root\` 整体拷到系统临时验证工程 `C:\Users\62668\AppData\Local\Temp\r1_r5_verify`，
  补齐临时依赖后跑三段门禁，用完即删。

## 2. 目录树与映射表（17 件）

| # | `res://` 落位（project_root 内） | 来源工位平铺件 | 轮次 |
|---|---|---|---|
| 1 | `project.godot` | `project.godot` | R2/R3 |
| 2 | `scripts/core/scene_router.gd` | `scene_router.gd` | R2 |
| 3 | `scripts/core/quality_preset.gd` | `quality_preset.gd` | R2 |
| 4 | `scripts/core/render_profiles.gd` | `render_profiles.gd` | R3 |
| 5 | `scripts/render/camera_rig.gd` | `camera_rig.gd` | R2 |
| 6 | `scripts/render/hybrid_2d3d_animated_sprite.gd` | `hybrid_2d3d_animated_sprite.gd` | R2 |
| 7 | `scripts/ui/performance_hud.gd` | `performance_hud.gd` | R2 |
| 8 | `scripts/world/chunk_streaming.gd` | `chunk_streaming.gd` | R2（ChunkManager autoload） |
| 9 | `scripts/world/chunk_streaming_r4.gd` | `chunk_streaming_r4.gd` | R4 |
| 10 | `scripts/world/chunk_streaming_r5.gd` | `chunk_streaming_r5.gd` | **R5 新增** |
| 11 | `scripts/build_main.gd` | `build_main.gd` | R3 |
| 12 | `scripts/build_courtyard.gd` | `build_courtyard.gd` | R4 |
| 13 | `scenes/Main.tscn` | `场景树骨架.tscn`（占位主场景，对应 `run/main_scene`） | R2 |
| 14 | `scenes/courtyard.tscn` | `courtyard.tscn`（M1 垂直切片主场景） | R4 |
| 15 | `data/render/quality_preset_desktop.tres` | 同名件 | R2 |
| 16 | `data/render/quality_preset_mobile.tres` | 同名件 | R2 |
| 17 | `data/render/render_profiles.tres` | 同名件 | R3 |

所有映射均为**原样拷贝**，未改动 R2/R3/R4 既有件内容；第 10 件为 R5 新增，
在工位根目录与工程树内各一份（内容一致）。

## 3. 跨工位依赖（落工程根时由对应工位补齐，非 Rank-1 交付）

`project.godot` 的 `[autoload]` 共 5 项，其中 3 项属 3 号工位，真实实现尚未到位：

| autoload | 路径 | 归属 | 工程树内状态 |
|---|---|---|---|
| WorldState | `res://scripts/world/world_state.gd` | 3 号 | 待落位；验证工程用最小 stub（`get_flag` / `set_flag`） |
| GameEvents | `res://scripts/core/game_events.gd` | 3 号 | 待落位；验证工程用最小 stub |
| SaveSystem | `res://scripts/world/save_system.gd` | 3 号 | 待落位；验证工程用最小 stub |
| ChunkManager | `res://scripts/world/chunk_streaming.gd` | 1 号 | 已在树中 |
| SceneRouter | `res://scripts/core/scene_router.gd` | 1 号 | 已在树中 |

另有 `res://scenes/world/chunks/chunk_limgrave_<x>_<y>.tscn`（I-1 / I-6 的 chunk 场景，
3 号产出）未到位，验证工程用 30 个纯 `Node3D` 占位场景让流式加载可测。

上述 stub / 占位场景 / 联调驱动 `r5_verify.gd` / 验证场景 `Verify.tscn` **均只在系统临时验证工程内**，
不进交付清单、用完即删，与 R3/R4 口径一致。

## 4. 工程树真跑证据（R5，实际输出）

`<godot>` = `D:/Godot/Godot_v4.7.2-stable_win64.exe`；`<tmp>` = `C:/Users/62668/AppData/Local/Temp/r1_r5_verify`
（由 `project_root\` 整体拷贝 + 补齐临时依赖而成）。

| 段 | 实际命令 | EXIT | 实际输出结论 |
|---|---|---|---|
| G0 | `<godot> --version` | 0 | `4.7.2.stable.official.ed1daf0bf` |
| G1 | `<godot> --headless --path <tmp> --import` | 0 | `first_scan_filesystem` 五步 DONE；`update_scripts_classes` 16 步 DONE；全局类 `QualityPreset` / `RenderProfiles` / `HybridSpriteRig` 注册成功；无 Parse Error |
| G2 | `<godot> --headless --path <tmp> --check-only --script res://<f>.gd`（16 个 `.gd`） | 16 条均 0 | 含 R5 新增 `chunk_streaming_r5.gd` 在内全部静态解析通过 |
| G3 | `<godot> --headless --path <tmp> --quit` | 0 | 打开 `scenes/Main.tscn` 正常启动退出；仅 `2 ObjectDB instances leaked` WARNING（定位与消除见 §5） |
| G4 | `<godot> --headless --path <tmp> --quit-after 300 res://scenes/Verify.tscn` | 0 | 联调驱动 `R5_PASS`（详见 §4.1） |
| G5 | `<godot> --headless --path <tmp> --quit-after 2 res://scenes/courtyard.tscn` | 0 | 直接打开 M1 主场景 `courtyard.tscn` 成功 |
| G3' | `<godot> --headless --path <tmp> --quit-after 10` | 0 | 消除方案实证：全日志 `SCRIPT ERROR / ERROR / WARNING / leaked = NONE` |

主日志 `grep`：`SCRIPT ERROR = NONE`、`ERROR / Parse Error / Failed = NONE`；WARNING 共 4 条
（3 条 `2 ObjectDB instances leaked` + 1 条 `[ChunkManager] 未找到 ChunkRoot` 降级提示），逐条归类见 `DONE-R5.md`。

### 4.1 G4 联调驱动实际输出（逐字）

```
[r5_verify] M1 courtyard_nodes=20 chunkroot_found=true
[r5_verify] I1 chunkroot_bound=true get_flag_calls=1 applied_flags_ok=true
[r5_verify] desktop apply=true resident=9 wanted=9 loaded=9
[r5_verify] mobile active=res://data/render/quality_preset_mobile.tres resident=4 wanted=4 loaded=4
[r5_verify] roam wanted=4 seen=7 max_load_count=1 all_one=true set_flag_calls=16 flag_ok=true
[r5_verify] SUMMARY m1=true i1=true chunk=true
[r5_verify] R5_PASS M1 垂直切片 + I-1 跨模块联调 + 移动端 4 chunk 运行时落地全部通过
```

证明：工程树内 `courtyard.tscn` 20 节点可实例化、ChunkRoot 被 R2 ChunkManager 与 R5 管理器共同绑定；
I-1 桥接经 `WorldState.get_flag` / `set_flag` 真实生效；桌面档 9 块 / 移动档 4 块运行时落地；
移动档往返走 `get_load_count` 恒为 1。

## 5. `ObjectDB leaked` WARNING 定位与消除（R5 实证）

`WARNING: 2 ObjectDB instances were leaked at exit`（G3/G4/G5）经 `--verbose` 与对照实验定位：

- `--verbose` 明细：泄漏对象为 **2 个裸 `RefCounted`（Reference count: 1）**，非 Node / Resource 子类。
- 对照（均为引擎真跑门禁变体，非探针 / 测量 / preflight 脚本）：

| 对照 | 配置 | 结果 |
|---|---|---|
| C1 | 最简空工程（无 autoload / 无脚本 / 纯 Node 主场景）`--quit` | 0 |
| C2 | 完整工程去掉 `[autoload]` 段 `--quit` | 0 |
| C3 | 完整工程主场景换纯 Node（无 SubViewport）`--quit` | 仍 2 |
| C4 | 仅 1 个最简 autoload stub `--quit` | 0 |
| 帧数扫描 | `--quit-after N`：N=1/2/3/5 → 2；N=10/20/60 → 0 | 临界在 5~10 帧之间 |
| 单 autoload | 5 个 autoload 逐个单独注册：仅 `ChunkManager` → 2，其余 4 个 → 0 | 精确定位到 ChunkManager |
| D1 | 仅 ChunkManager 但移除占位 chunk 场景（9 次 `scene_missing`，`load_threaded_request` 未发起）| 0 |
| G3' | 完整工程 `--quit-after 10` | 0，且全日志无任何 WARNING |

**结论**：R2 `chunk_streaming.gd`（ChunkManager autoload）在 `auto_start=true` 下，`--quit` 单帧快速退出时
其发起的 `load_threaded_request` 在途异步任务（受 `max_concurrent_loads=2` 限制，恰好 2 个）未完成清理，
导致 2 个裸 `RefCounted` 残留。与 `SubViewport` / `own_world_3d` / 主场景内容 / 其它 autoload /
R5 新增件均无关 —— **实证纠正了 R4「autoload 单例与 SubViewport 相关资源清理残留」的判定**。

**消除**：退出方式由 `--quit`（1 帧）改为 `--quit-after N`（N≥10），让在途任务完成，
WARNING 消失（G3' 实证 EXIT=0、全日志 `SCRIPT ERROR / ERROR / WARNING / leaked = NONE`）；
非 headless 正常运行不存在该问题。

**约束遵守**：根因在 R2 既有交付件，R5 硬约束「不改既有交付件内容（只追加 / 补齐）」且
「R2/R3/R4 件一律保留、不重做」，故**未修改** `chunk_streaming.gd` / `project.godot`；
契约 §10 第三段门禁固定 `--headless --quit`，G3 仍按契约跑并如实登记 WARNING，另附 G3' 作消除方案实证。
若 HOST 后续授权修改 R2 件，可在 `_bootstrap` 加 headless 门禁守卫或把 `auto_start` 默认置 false 以彻底消除 —— 本轮不擅自改。

## 6. 落位操作步骤（供 HOST / 主 AI 收尾）

1. 把 `Rank-1\project_root\` 整目录内容拷到 `F:\Game\aierdengfahuan\`（工程根）。
2. 由 3 号工位补齐 3 个 autoload 真实实现（`world_state.gd` / `game_events.gd` / `save_system.gd`）与真实 chunk 场景。
3. 由 4 号工位按 I-5 落位 `import.json` / spritesheet / ≤256 色索引调色板。
4. 用 `<godot> --headless --path <工程根> --import` → 全量 `--check-only --script` → `--headless --quit` 复核；
   若需规避快速退出 WARNING，第三段可用 `--quit-after 10`（见 §5）。
5. 装配层把 `chunk_streaming_r5.gd` 挂到世界并调用 `apply_preset_path(...)` 与档位联动
   （见 §7 待裁决项）。

## 7. 待 HOST 裁决 / 口径登记

1. **工程根物理落位**：`F:\Game\aierdengfahuan\` 在 `teamwork\` 外，本轮唯一可写范围未覆盖，
   由 HOST / 主 AI 执行拷贝；本轮只交付工位内已落位并真跑验证的 `project_root\`。
2. **R5 件接入正式装配层**：`chunk_streaming_r5.gd` 提供 `apply_preset_path` / `configure_from_preset` /
   `set_resident_chunk_count` 与 SceneRouter 档位联动，本轮以临时验证场景实例化并真跑验证可用；
   正式工程里把它注册为 autoload 或由装配层实例化需改 `project.godot` / `scene_router.gd`（既有件），
   超出本轮「只补齐」范围，本轮未改，请 HOST 裁决接入方式。
3. **帧时间实测**：headless 无渲染管线，无法实测帧时间 / p99 / spike；`16.67 / 33.33 ms` 为
   `render_profiles.tres` + `quality_preset_*.tres` 目标值静态核对。需 F3 性能 HUD + 人工试玩，本轮未做、未伪造。
4. R2/R3/R4 遗留待裁决（延续，未擅自改）：4 号 A8 `@3x` vs 本工位 `@2x` 冻结值、负坐标 chunk id 命名、
   `GameEvents` 最终归属、`canvas_items` vs `canvas_textures` 合法键、`config_version`「实测填写」口径、
   `HybridSpriteRig` 类名与 GDExtension 全局类同名风险、`128bit` 确切含义。

---

## 8. 落位步骤补充（R6 边界收口，纯追加，不改既有 §1~§7）

> 本轮 R6 为边界收口：只核对目录树、补齐落位步骤说明、登记待裁决项、真跑门禁；
> **落位本身需 HOST 授权，本轮未执行**，未把 `project_root\` 拷到 `teamwork\` 外、未伪造已落位。
> 四项待裁决项依据与建议见 `R6-待裁决登记.md`，真跑实际输出结论见 `DONE-R6.md` §2。

### 8.1 目录树核对结论（R6 实测）

对 `F:\Game\aierdengfahuan\teamwork\Rank-1\project_root\` 只读核对：

- 实体文件 **17 个**（其中 `.gd` 11 个），与 §2 映射表 17 件**逐件一致**：`project.godot` 1、`scripts/` 11（core 3 / render 2 / ui 1 / world 3 / build 2）、`scenes/` 2、`data/render/` 3；无遗漏、无多余实体文件。
- 目录含 1 个 §2 表未列的空目录 `scenes/world/chunks/`，对应 §3 预留的 3 号 `res://scenes/world/chunks/chunk_limgrave_<x>_<y>.tscn` 真实 chunk 场景路径，与文档一致，非多余文件。
- 真跑三段门禁后引擎生成的 `.godot\` 缓存与 11 个 `.gd.uid` 已清理，交付树恢复 17 件原样。

### 8.2 落位前逐件校验清单（供 HOST / 主 AI 执行拷贝前核对）

拷贝源 `Rank-1\project_root\`，目标 `F:\Game\aierdengfahuan\`（工程根）。落位前逐件确认下列 17 个相对路径均存在且非空：

```
project.godot
scripts/core/scene_router.gd
scripts/core/quality_preset.gd
scripts/core/render_profiles.gd
scripts/render/camera_rig.gd
scripts/render/hybrid_2d3d_animated_sprite.gd
scripts/ui/performance_hud.gd
scripts/world/chunk_streaming.gd
scripts/world/chunk_streaming_r4.gd
scripts/world/chunk_streaming_r5.gd
scripts/build_main.gd
scripts/build_courtyard.gd
scenes/Main.tscn
scenes/courtyard.tscn
data/render/quality_preset_desktop.tres
data/render/quality_preset_mobile.tres
data/render/render_profiles.tres
```

校验建议（只读）：`find Rank-1\project_root -type f | wc -l` 应为 `17`；`find ... -name '*.gd' | wc -l` 应为 `11`。
拷贝时保持 `res://` 相对目录结构；`scenes/world/chunks/` 空目录一并带过去，供 3 号后续落真实 chunk 场景。

### 8.3 落位后门禁复核步骤

`<godot>` = `D:/Godot/Godot_v4.7.2-stable_win64.exe`；`<工程根>` = `F:/Game/aierdengfahuan`。

1. `<godot> --headless --path <工程根> --import`
2. 对工程内全部 `.gd` 循环：`<godot> --headless --path <工程根> --check-only --script res://<f>.gd`（逐条记录 EXIT）
3. `<godot> --headless --path <工程根> --quit`
4. 合并三段日志后 `grep -n "SCRIPT ERROR"`，判据：**NONE 为通过**（运行时 SCRIPT ERROR 不改退出码，必须 grep）。
5. 若需规避 `--quit` 单帧快速退出的 `ObjectDB leaked` WARNING，第三段可用 `--quit-after 10`（见 §5）。

**复核口径提醒（R6 真跑实证）**：在 3 号 3 个 autoload 真实实现（`world_state.gd` / `game_events.gd` / `save_system.gd`）与真实 chunk 场景落位前，G1 / G3 会出现 `Attempt to open script ... File not found` / `Failed to create/instantiate an autoload` 等 `ERROR` 与 `scene_missing` `WARNING` —— 属**跨工位依赖未到位**，不是 `SCRIPT ERROR`、不是本工位交付件缺陷。R6 对 `project_root\` 直接真跑的结论即三段 EXIT 全 0、`SCRIPT ERROR` = NONE、11 个 `.gd` 静态检查全过，同时如实登记上述依赖缺失（逐字见 `DONE-R6.md` §2）。3 号依赖到位后这些 ERROR / WARNING 应消失，可作为接入成功的回归判据。

### 8.4 落位权限与收尾

- 落位动作写 `teamwork\` 外的工程根，超出 Rank-1 唯一可写范围，**须 HOST 授权、由主 AI 执行**；Rank-1 本轮未执行、未伪造已落位。
- 落位后由主 AI 统一 `git commit` + `push`（契约 §9.1）；执行 AI 不自行 git。
- 3 号 / 4 号跨工位依赖补齐见 §3、§6 第 2~3 步；R5 件接入装配层的裁决见 §7-2 与 `R6-待裁决登记.md` §4。
