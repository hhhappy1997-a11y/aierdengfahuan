# DONE-R38.md · R38 / v0.15.0「大地图 · 2.5D 尺度重构」交付报告（Rank-1）

> 轮次：`R38` ｜ 任务单 id：`cmd-20261112-234238-645-A1` ｜ 执行 AI：`1（Rank-1 引擎架构与渲染执行 AI）`
> 真源：`teamwork/Rank-1/调度任务单-latest.json`（task 全文 + 公共契约 + 大改特别条款 + A48 硬要求 + 目录所有权·R38 冻结，HOST 裁决 A74 特别授权）
> 前序：`teamwork/Rank-1/DONE-R37.md`（A38 节点 41 / uv 2/1/1 / 219 PASS 五份回归全绿）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
>
> **一句话结论**：R38 四块任务全部真跑完成 —— ① **A74 特别授权改 `courtyard.tscn`**：新增 `BigMapLayer/BigMapRoot` 分区世界层 + 4 层视差 + `WorldActors`(y-sort) + `Camera2D` + `CharacterScaleController` 共 **13 个真实节点**，既有 41 节点与全部相对路径不删不改（v0.1~v0.14 可玩闭环入口仍可达），**磁盘节点数 41→54、地面 uv 2/1/1→16/8/8**；② 新建 `world_scale.tres` 数据驱动 **4096×2304** 大地图 + zoom 0.5（可见 2560×1440）+ limit 边界 + 4 层视差不同系数 + 按层深度雾 + 落地阴影 + 前景遮挡，仍 `gl_compatibility` / CanvasItem 体系、不引入真 3D 网格；③ **人物 40% 实测**：`character_scale = 1.6 × 0.40 = 0.64` 写进配置并注明计算式，角色渲染脚本从配置读、不再硬编码 1.6，3 个真实角色节点 scale 实测 `[0.64, 0.64, 0.64]`，**画面像素高度 2.4000m → 0.9600m（ratio 0.4000）**；`hud.gd` 追加数据驱动角色包围盒（既有 6 分区布局逐字不动、worst_overlap=0.0000），`presentation.gd` 只追加真实 WASD/方向键注入 + 相机跟随只读回读；④ **A74 断言同步**：`verify_wave_runtime_v040.gd` 的 node_count 41→54 / delta 8→21 / uv 2/1/1→16/8/8 按真跑回读同步，不删断言、不放宽判定，复跑 **37/37 `RESULT=ALL_MATCH`**；⑤ 新写 `verify_bigmap_v150.gd`（**不加载 `presentation.gd`、不模拟编排**）**37/37 `RESULT=ALL_MATCH`**；⑥ 三段门禁 G1 / G2a(7) / G2b / G3 全 `EXIT=0`、450 帧演示逻辑真跑 `EXIT=0`、全工程 **20 份日志 `SCRIPT ERROR=0 / PARSE_ERROR=0`**。**如实登记**：额外复跑既有 5 份回归得 **211 PASS / 8 FAIL**，8 条 FAIL **全部且仅为 A38 旧基线（41 / 2-1-1）过期断言**、非本轮功能回归；这 5 份不在本轮 Rank-1 授权写入清单，按硬约束未越权同步，附精确同步清单列 **待总指挥裁决 #1**（§10）。

---

## 1. 交付清单（实际落地文件）

| # | 文件 | 类型 | 本轮改动 |
|---|---|---|---|
| ① | `godot/data/render/world_scale.tres` | **新建** | 世界尺度唯一配置表：4096×2304 地图 / 1280×720 单屏 / `character_scale_baseline=1.6` / `character_scale_ratio=0.40` / `character_scale=0.64`（注明计算式）/ 32×48 单帧 / ppm=32 / zoom(0.5,0.5) / limit(0,0,4096,2304) / 4 层视差系数 0.06/0.14/0.26/0.42 / 按层雾 0.30/0.18/0.09/0.02 / y_sort / 前景 z=10 / 移速 320 / 脉冲 0.05。全部 `[PLACEHOLDER]` + rationale（逐字段见 ②脚本注释），调参唯一入口 = 本表。 |
| ② | `godot/scripts/world/world_scale_config.gd` | **新建** | `class_name WorldScaleConfig extends Resource`：22 个 `@export` 字段（默认值为非法占位基线、`is_valid()` 必 false）+ 派生量 `computed_character_scale()` / `character_pixel_height()` / `camera_visible_size()` / `is_valid()` 自检。 |
| ③ | `godot/scripts/world/big_map_runtime.gd` | **新建** | `class_name BigMapRuntime extends Node2D`，挂 `BigMapRoot`：`Camera2D` 跟随玩家 + limit clamp + zoom 作为 2D 视图缩放、4 层视差按系数随相机滚动、y-sort、落地阴影、按层深度雾（`modulate`）、真实 WASD/方向键 `_unhandled_input`（点按脉冲 + 按住 `_process` 持续）、只读 `get_bigmap_snapshot()`。数值全部从 ①读，脚本不写 4096/0.5/0.06 等。 |
| ④ | `godot/scripts/render/character_scale.gd` | **新建** | `class_name CharacterScaleApplier extends Node`，挂 `CharacterScaleController`：`_ready` 从 ①读 `character_scale` 应用到 3 个真实角色节点（既有 Player / Boss 的 `PixelSprite` + 新增 2D `PlayerBody`），**不再硬编码 1.6 / 0.64**；`get_snapshot()` 回读真实 scale + 基线/比例/计算式/像素高度对比。 |
| ⑤ | `godot/scenes/courtyard.tscn` | 修改（**A74 特别授权**） | 新增 13 个真实节点（见 §3）；两处 `PixelSprite` transform `Transform3D(1.6,…)` → 中性 `(1.0,…)`（去硬编码）；3 个地面材质 `uv1_scale` (2,2,1)→(16,16,1) / (1,1,1)→(8,8,1) ×2；追加 2 条 `ext_resource`（③/④脚本）；追加 R38 注释块。**既有 41 个 `[node]` 条目与所有相对路径不删不改**（仅两处 `PixelSprite.transform` 按任务③去硬编码、三处地面 uv 按 A74 改值）。 |
| ⑥ | `godot/scripts/hud.gd` | 修改（Rank-1 唯一写入） | §11b 追加：`WORLD_SCALE_PATH` + `get_character_scale_ratio()`（从 ①读，配置缺失回落中性 1.0）/ `get_character_bbox_rect()`（按 ratio 缩小并居中的真实新尺寸包围盒）/ `get_character_bbox_view()`。**既有 12 信号 / 6 分区 ANCHOR_* / `get_layout_rects()` / `get_center_char_rect()` / `get_hud_layout()`（字典 key 不变）/ 全部 R34C~R37 独立分区逐字不动**。 |
| ⑦ | `godot/test/presentation.gd` | 修改（Rank-1 唯一写入） | 头部追加 R38 rationale；常量区追加 8 个移动键码 + `R38_MOVE_KEYS` / 节奏常量 / `BIGMAP_PATH` / `BIGMAP_EVIDENCE_FRAMES`；`_initialize` 追加 `_big_map` 只读解析；`_on_frame` 追加 `_drive_bigmap_explore(f)`；新增 `_drive_bigmap_explore()`（真实 `Input.parse_input_event` 注入）与 `_log_bigmap_evidence()`（只读快照回读）。**既有 J/Space/K/F/Q/R/G/E/Tab 注入节奏、全部 `[PLACEHOLDER]` 数值、R29 预热 / R34 移除演示驱动结论逐字不动**。 |
| ⑧ | `godot/scripts/combat/verify_wave_runtime_v040.gd` | 修改（A74 断言同步） | `NODE_COUNT_AFTER` 41→54、`NODE_COUNT_DELTA` 8→21；3 条 uv 断言期望 `(2,2,1)/(1,1,1)/(1,1,1)`→`(16,16,1)/(8,8,1)/(8,8,1)`、标签 `*_2/*_1/*_1`→`*_16/*_8/*_8`；头部/H 组/node_count detail 注释同步。**断言集合、`is_equal_approx` / `==` 严格判定逐字不动，未删断言、未放宽判定**。 |
| ⑨ | `godot/scripts/render/verify_bigmap_v150.gd` | **新建** | 本轮主回归（`extends SceneTree`，**不加载 `presentation.gd`**、不模拟编排）A~F 六组 37 条，见 §2.5。 |
| ⑩ | `teamwork/Rank-1/DONE-R38.md` | **新建** | 本交付报告。 |
| ⑪ | `teamwork/Rank-1/r38_*.log`（20 份） | **新建** | G1 import / 7 份 G2a / 7 份 G2b / G3 quit / 450 帧演示 / V040 回读与复跑 / V150 首跑与复跑真跑日志原文留档（授权目录内）。 |
| ⑫ | `teamwork/command_center/ai/1/outbox/cmd-20261112-234238-645-A1.json` | **新建** | 本轮回执（**`teamwork/command_center/`**，非工程根），写后经中枢归档（§11）。 |

**只读未改（硬约束）**：`project.godot`（既有 autoload / `run/main_scene` / `gl_compatibility`）/ `impact_feedback.gd` / `hd2d_fx.gd` / `hd2d_parallax.gd` / `wave_trial_director.gd`（Rank-2 所有）/ `points_commit_orchestrator.gd`（Rank-3 所有）/ 全部既有 `.tres` 数值 / 素材 / 既有 5 份 `verify_*` 回归脚本（见 §10 待裁决 #1）/ 其它 Rank 产出。

---

## 2. 四块任务实现说明

### 2.1 任务① 大地图场景层（A74 特别授权改 `courtyard.tscn`）

`BigMapLayer`(CanvasLayer, layer=1) 作为**新增并行层**挂根节点 `Courtyard` 下；`BigMapRoot`(Node2D, `y_sort_enabled`, 挂 `big_map_runtime.gd`) 下挂 4 层视差 `ParallaxLayer0~3`（各带 `metadata/parallax_index`，角色说明 = 远景色带 / 中景地形与地标 / 地面 tile 大范围平铺 / 前景遮挡层）+ `WorldActors`(y-sort，含 `PlayerMarker` / `PlayerShadow` / `PlayerBody` / `LandmarkA`) + `Camera2D`；根节点另挂 `CharacterScaleController`。**13 个新增节点全部为纯新增**，既有 41 节点（含 `SubViewportContainer` 3D 场景、`EncounterRoot`、`WaveTrialDirector`、`Hud`、教学/波次 HUD 等）逐一保留、相对路径不改 —— `Hud.grace_runtime_path`、`Boss.sprite_path`、`WaveTrialDirector.*_path` 等既有覆盖段全部有效（V040 `instance_override_preserved` 仍 PASS）。

地图逻辑尺寸与相机参数写进 `world_scale.tres`；`courtyard.tscn` 内 `Camera2D` 的 `zoom/limit/position` 为**静态声明初值**（与表一致，供 A74 静态回读断言），**运行时由 `BigMapRuntime._ready` 从表读取并覆盖**（数据驱动权威，调参只改表不改代码）。

### 2.2 任务② 2.5D 层次（不切后端 / 不引入真 3D 网格）

- **y-sort**：`BigMapRoot` 与 `WorldActors` 的 `y_sort_enabled=true`（V150 B4/B8/C4 实证）；角色 / 地标 / 遮挡同挂 `WorldActors` 按 Y 排序。
- **多层视差**：4 层系数 0.06/0.14/0.26/0.42（远小近大、严格递增），`_sync_camera_and_parallax()` 令各层 `position = camera.position × coefficient`，随相机位移按不同系数滚动（V150 D4 实测 4 个互不相同非零 offset）。
- **前景遮挡**：`ParallaxLayer3.z_index=10`（大于其它层），`metadata/layer_role="前景遮挡层"`。
- **角色落地阴影**：`PlayerShadow` 真实节点挂在 `PlayerMarker` 下，运行时定位脚下略偏。
- **按层深度雾**：雾密度 0.30/0.18/0.09/0.02（远浓近淡），以纯 2D `CanvasItem.modulate` 叠色近似（硬边无噪点、零 GPU job），不依赖 `Environment.glow` / `volumetric_fog`。
- **不切后端**：仍 `gl_compatibility`（`project.godot` 只读确认），全部为 Node2D + CanvasItem 体系，未新增任何 `MeshInstance3D` / 真 3D 网格；既有 3D 战斗场景原样保留。
- **2D 视图变换口径（如实登记）**：`zoom` 以 `BigMapRoot.scale = camera_zoom` 实现（zoom<1 → 同屏可见 2× 范围），`Camera2D` 不接管 root viewport 的 `canvas_transform`，避免影响既有 `SubViewportContainer` 的 3D 画面；此为"不破坏既有 3D 层"的取舍，标准 `Camera2D.current` 管线是否后续启用列为待裁决（§10）。

### 2.3 任务③ 人物显示尺寸 40% + HUD / 演示同步

- **计算式与唯一入口**：`world_scale.tres` 登记 `character_scale_baseline=1.6`、`character_scale_ratio=0.40`、`character_scale=0.64 = 1.6 × 0.40`；`WorldScaleConfig.computed_character_scale()` 与 `is_valid()` 强制三者一致（V150 A4/A5 实证）。
- **不再硬编码 1.6**：`courtyard.tscn` 两处 `PixelSprite` transform 改中性 `(1.0,…)`（V150 B9 实证 basis_x=1.000）；`CharacterScaleApplier` 只从表读 `character_scale` 应用（脚本内无 1.6 / 0.64 字面量）。
- **hud.gd 同步避让几何**：新增 `get_character_bbox_rect()` 以 `ANCHOR_CHAR` 为基线按 ratio（从表读）等比缩小并居中 → 真实新尺寸占位；既有 6 分区 / 独立分区 / `get_center_char_rect()` 保守保护区逐字不动。V150 E1~E5 实证：6 分区 `size()==6` 两两不相交、ratio=0.4000、bbox=(192.0×135.9994) vs guard=(480.0×339.9984)、13 块文字/面板 `worst_overlap=0.0000 px²`（**面板不遮角色、HUD 文字不重叠**）。
- **presentation.gd 演示构图**：追加 8 向真实移动键注入（W/A/S/D + 四方向键，450 帧内 33 次真实 `Input.parse_input_event`），关键帧只读回读 `BigMapRuntime.get_bigmap_snapshot()`；既有 J/Space/K/F/Q/R/G/E/Tab 注入与全部 `[PLACEHOLDER]` 数值逐字不动。450 帧真跑实证 `frame=0 camera/player=(2048,1152)` → `frame=225/449 (2048,1120)`（**相机跟随玩家同步位移**）。

### 2.4 任务④ A74 断言同步（改前 → 改后）

先改场景 → `--headless --import` → **真跑 `V040` 回读**（`r38_v040_readback.log` 原文）：

```
[V040] NODE_COUNT before=33 after=54 delta=+21
[V040] courtyard_node_count PASS=false | node_count=54 expected=41
[V040] uv_groundplate_2 PASS=false | uv1_scale=(16.0, 16.0, 1.0) expected=(2,2,1)
[V040] uv_terracelow_1 PASS=false | uv1_scale=(8.0, 8.0, 1.0) expected=(1,1,1)
[V040] uv_terracehigh_1 PASS=false | uv1_scale=(8.0, 8.0, 1.0) expected=(1,1,1)
[V040] SUMMARY pass=33 fail=4
```

据此**只改期望数字 / 标签 / 注释**（`NODE_COUNT_AFTER 41→54`、`NODE_COUNT_DELTA 8→21`、3 条 uv 期望与标签、头部/H 组/node_count detail 注释补 R38 说明），**断言集合与 `is_equal_approx` / `==` 严格判定逐字不动，未删断言、未放宽判定**；复跑 `r38_v040_final.log` / `r38_g2b_verify_wave_runtime_v040.log`：

```
[V040] NODE_COUNT before=33 after=54 delta=+21
[V040] courtyard_node_count PASS=true | node_count=54 expected=54（+21：… + R38 大地图 13 节点）
[V040] uv_groundplate_16 PASS=true | uv1_scale=(16.0, 16.0, 1.0) expected=(16,16,1)
[V040] uv_terracelow_8 PASS=true | uv1_scale=(8.0, 8.0, 1.0) expected=(8,8,1)
[V040] uv_terracehigh_8 PASS=true | uv1_scale=(8.0, 8.0, 1.0) expected=(8,8,1)
[V040] SUMMARY pass=37 fail=0
[V040] RESULT=ALL_MATCH
```

### 2.5 任务⑤ 真实可达回归 `verify_bigmap_v150.gd`

`extends SceneTree`，`Engine.get_main_loop() as SceneTree` 取 root（不用 `get_tree()` / 不用 `/root/...` 绝对路径）、`CACHE_MODE_IGNORE`、`add_child` 后以「快照 `config_loaded`」为守卫显式 `call("_ready")`；**不加载 `presentation.gd`**（A0 断言运行时树零 presentation 节点）、**不在验证脚本内模拟编排**：真实 `InputEventKey` 注入 → 显式送生产 `BigMapRuntime._unhandled_input` / `_process`（同 V140 `--script` 显式 call 口径）→ 读生产只读快照断言场景节点真实变化。六组 37 条：

- **A（配置回读 8 条）**：world_scale.tres 加载 / `is_valid()` / 地图尺寸 ≥ 阈值且 > 2× 单屏 / 计算式 / **人物 == 基线 × 0.40** / zoom 视野扩大 / limit 与地图一致 / 视差层数 ≥3 + 系数递增 + 雾递减。
- **B（场景静态回读 10 条）**：A74 新基线 54 / 既有战斗入口 / BigMapRoot y_sort / 视差层节点 / Camera2D limit+zoom / **uv 16/8/8** / 阴影+前景 z+Y-sort / PixelSprite 中性基线 1.0 / CharacterScaleController。
- **C（真实装配 5 条）**：显式 `_ready` / **3 个真实角色节点 scale 实测 0.64** / 像素高度比 0.40 / 运行时 y_sort+阴影+前景 / layer_scale == zoom。
- **D（★ A48③ 4 条）**：真实 W → 玩家位移 / 相机跟随 / 40 帧持续上移撞边界被 clamp / 4 层视差 offset 互不相同。
- **E（HUD 避让 5 条）**：6 分区不重叠 / ratio 数据驱动 / 新包围盒 == guard×ratio / `worst_overlap=0` / 保守保护区不回退。
- **F（既有闭环 4 条）**：战斗入口 / `encounter_finished` 信号 / `wave_trial.tres` 表 / A74 新基线一致。

**真跑修复（如实登记，非纸面设计）**：V150 首跑 36/37，唯一 FAIL = C2 `target_scales=[-1.0,-1.0,-1.0] applied_targets=0` —— `CharacterScaleApplier` 的 `TARGET_PATHS` 按根节点 `Courtyard` 写，但脚本挂在 `Courtyard/CharacterScaleController` 上、`get_node_or_null` 按自身解析导致全部寻址失败。修法：3 条路径加 `../` 前缀（相对本节点回到根），**未放宽任何断言**；复跑 37/37 全绿，`target_scales=[0.64,0.64,0.64] applied_targets=3`。

### 2.6 任务⑥ 三段门禁 + 全工程 `SCRIPT ERROR=0`

见 §6 真跑输出原文。

---

## 3. A74 改前 → 改后：节点数与 uv 对照（交付要求专节）

| 项 | 改前（R37 / A38 基线） | 改后（R38 / A74 新基线，真跑回读） |
|---|---|---|
| `courtyard.tscn` 磁盘节点数 | **41** | **54**（+13） |
| `NODE_COUNT_BEFORE`（R25 历史基线） | 33 | 33（不动） |
| `NODE_COUNT_DELTA` | +8 | **+21**（= 8 + 13） |
| `GroundPlate` `uv1_scale` | `Vector3(2, 2, 1)` | **`Vector3(16, 16, 1)`** |
| `TerraceLow` `uv1_scale` | `Vector3(1, 1, 1)` | **`Vector3(8, 8, 1)`** |
| `TerraceHigh` `uv1_scale` | `Vector3(1, 1, 1)` | **`Vector3(8, 8, 1)`** |
| uv 口径 | **2/1/1** | **16/8/8** |

**+13 新增节点清单**：`BigMapLayer`(CanvasLayer) / `BigMapRoot`(Node2D, y_sort) / `ParallaxLayer0`(远景色带) / `ParallaxLayer1`(中景地形与地标) / `ParallaxLayer2`(地面 tile 大范围平铺) / `ParallaxLayer3`(前景遮挡, z=10) / `WorldActors`(Node2D, y_sort) / `PlayerMarker` / `PlayerShadow` / `PlayerBody` / `LandmarkA` / `Camera2D` / `CharacterScaleController`。

**uv 变更 rationale**：地图逻辑尺寸 4096×2304 远大于单屏 1280×720，地面 tile 需大倍率平铺才不在扩大视野下拉伸 / 稀疏；三档仍成组、硬边无噪点、美术规格不变（`[PLACEHOLDER]` 待试玩校准）。

**既有 41 个 `[node]` 条目不删、全部相对路径不改**（仅两处 `PixelSprite.transform` 按任务③去硬编码、三处地面材质 `uv1_scale` 按 A74 改值，见上表）：`EncounterRoot` / `WaveTrialDirector` / `GraceUpgradeRuntime` / `TutorialDirector` / `Hud` / `HD2DFX` / `QualitySettings` / `SubViewportContainer` 全 3D 子树 / 波次·教学 HUD 等一个不删；`StatusLabel` / `Boss` 两个 instance 覆盖段有效（V040 `instance_override_preserved` PASS）。

---

## 4. 人物 40% 实测（交付要求专节：基线 1.6 → 0.64，画面像素高度对比）

| 项 | 改前（基线 1.6） | 改后（R38，实测） | 比值 |
|---|---|---|---|
| `character_scale`（配置/运行） | 1.6 | **0.64 = 1.6 × 0.40** | **0.40** |
| 单帧像素尺寸（I-5 / 128px 基准） | 32×48 px | 32×48 px | 1.0 |
| `pixels_per_meter` / `pixel_size` | 32 / 0.03125 m·px⁻¹ | 同左 | 1.0 |
| 未缩放像素高 = 48 ÷ 32 | 1.5 m | 1.5 m | 1.0 |
| **画面像素高度 = 1.5 × scale** | **2.4000 m** | **0.9600 m** | **0.4000** |

**真跑实测原文**（`r38_g2b_verify_bigmap_v150.log`）：

```
[V150] A4 … PASS=true | baseline=1.600 ratio=0.400 computed=0.6400 character_scale=0.6400
[V150] A5 ★ 人物显示尺寸 == 基线 × 0.40（±容差） PASS=true | 0.6400 == 1.600 × 0.40 = 0.6400 | tol=0.0010
[V150] B9 既有 PixelSprite 中性基线 1.0（不再硬编码 1.6） PASS=true | player_basis_x=1.000 boss_basis_x=1.000
[V150] C2 ★ 角色显示尺寸实测：真实节点 scale == 基线 × 0.40（±容差） PASS=true | target_scales=[0.63999998569489, 0.63999998569489, 0.63999998569489] expected=0.6400 applied_targets=3
[V150] C3 画面像素高度对比：new/old == 0.40（±容差） PASS=true | old=2.4000m new=0.9600m ratio=0.4000
```

**结论**：人物显示尺寸**实测为基线的 40%**（3 个真实角色节点 scale 均为 0.64，画面像素高度 2.4000m → 0.9600m），非纸面换算；缩放值只来自 `world_scale.tres`，脚本与场景不再硬编码 1.6 / 0.64。

---

## 5. 大地图尺寸与相机边界（交付要求专节）

| 参数（`world_scale.tres`） | 值 | rationale / 实测 |
|---|---|---|
| `map_logic_size` | **4096 × 2304** 逻辑像素 | 远大于单屏 1280×720（3.2× 宽 / 3.2× 高，16:9 同比例）；V150 A3 `PASS=true` |
| `viewport_logic_size` | 1280 × 720 | 既有单屏基准（对比 / 视野换算） |
| `camera_zoom` | (0.5, 0.5) | zoom<1 → `camera_visible_size = 2560 × 1440`（视野 2× 扩大）；V150 A6 / C5 `layer_scale==(0.5,0.5)` |
| `camera_limit_left/top/right/bottom` | **0 / 0 / 4096 / 2304** | 与地图尺寸一致；V150 A7 / B6 静态回读 PASS |
| 相机中心 clamp 区间 | x ∈ [1280, 2816]、y ∈ [720, 1584] | 半视口 1280×720；V150 D3 持续上移撞 `limit_top` → `camera=(2048, 720)` 被 clamp（`within=true clamped=true`） |
| 视差 4 层系数 | 0.06 / 0.14 / 0.26 / 0.42 | 远小近大；V150 D4 实测 offsets `[(122.88,43.2),(286.72,100.8),(532.48,187.2),(860.16,302.4)]` 互不相同 |
| 按层深度雾 | 0.30 / 0.18 / 0.09 / 0.02 | 远浓近淡，纯 2D `modulate` 近似 |

---

## 6. 真跑输出原文

命令前缀统一 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；日志留档 `teamwork/Rank-1/r38_*.log`。

### 6.1 三段门禁 EXIT（原文汇总）

```
G1_IMPORT_EXIT=0
G2A_hud_EXIT=0  G2A_presentation_EXIT=0  G2A_verify_wave_runtime_v040_EXIT=0
G2A_verify_bigmap_v150_EXIT=0  G2A_world_scale_config_EXIT=0
G2A_big_map_runtime_EXIT=0  G2A_character_scale_EXIT=0
G2B_verify_wave_runtime_v040_EXIT=0 | [V040] RESULT=ALL_MATCH | [V040] SUMMARY pass=37 fail=0
G2B_verify_bigmap_v150_EXIT=0      | [V150] RESULT=ALL_MATCH | [V150] SUMMARY pass=37 fail=0 total=37 ok=true
G3_QUIT_EXIT=0
PRESENTATION_LOGIC_EXIT=0（450 帧 headless 逻辑帧真跑，日志 1037 行，时间线完成 frame=450，33 次真实移动键注入）
```

### 6.2 全工程 `SCRIPT ERROR` / `PARSE ERROR` grep（20 段日志，原文）

```
LOG_COUNT=20
FINAL SCRIPT_ERROR_LINES=0  PARSE_ERROR_LINES=0
```

逐日志均为 `SCRIPT_ERROR=0 PARSE_ERROR=0`（`r38_g1_import` / 7 份 `r38_g2a_*` / 7 份 `r38_g2b_*` / `r38_g3_quit` / `r38_presentation_logic` / `r38_v040_readback` / `r38_v040_final` / `r38_v150.run`）。**既有 WARNING / ERROR 如实登记**（非本轮引入、非 `SCRIPT ERROR`、不影响 `EXIT=0`）：`--script` 工具模式 `SaveSystem` 跳过自动读回、`2 ObjectDB instances were leaked at exit`，与 DONE-R37 §4.2 尾注同口径。

### 6.3 V150 主回归 SUMMARY / 关键断言（原文）

```
[V150] A0 A48③ 运行时树零 presentation.gd 节点 PASS=true | presentation_in_tree=false
[V150] A3 地图尺寸 ≥ 配置阈值且远大于单屏 1280×720 PASS=true | map=(4096.0, 2304.0) viewport=(1280.0, 720.0)
[V150] A6 Camera2D zoom 使视野显著扩大 PASS=true | zoom=(0.5, 0.5) visible=(2560.0, 1440.0)
[V150] B2 ★ A74 新基线 node_count == 54（改前 41 → 改后 54） PASS=true | node_count=54 expected=54
[V150] B3 既有战斗入口 … 仍可达 PASS=true | enc=true wave=true hud=true cam3d=true
[V150] B7 ★ A74 新基线 uv 16/8/8（改前 2/1/1） PASS=true | plate=(16.0,16.0,1.0) low=(8.0,8.0,1.0) high=(8.0,8.0,1.0)
[V150] C2 ★ 角色显示尺寸实测 … PASS=true | target_scales=[0.64,0.64,0.64] applied_targets=3
[V150] C3 画面像素高度对比 … PASS=true | old=2.4000m new=0.9600m ratio=0.4000
[V150] D1 ★ 真实 W 输入 → 玩家位移 PASS=true | player (2048.0,1152.0) → (2048.0,1136.0)（Δ=16.00）
[V150] D2 ★ Camera2D 随玩家位移 PASS=true | camera (2048.0,1152.0) → (2048.0,1136.0)（Δ=16.00）
[V150] D3 ★ 相机随玩家位移且边界受限 PASS=true | camera=(2048.0,720.0) limit=[0,0,4096,2304] half=(1280.0,720.0) within=true clamped=true
[V150] D4 ★ 多层视差随相机位移按不同系数滚动 PASS=true | offsets=[(122.88,43.2),(286.72,100.8),(532.48,187.2),(860.16,302.4)]
[V150] E4 ★ 角色缩小后 HUD 面板/文字仍不遮角色 PASS=true | blocks=13 worst_overlap=0.0000 px²
[V150] F1 既有战斗入口 … 仍可达（大地图为新增层） PASS=true
[V150] SUMMARY pass=37 fail=0 total=37 ok=true
[V150] RESULT=ALL_MATCH
```

### 6.4 450 帧演示逻辑真跑（大地图可探索，原文抽样）

```
[R38][BIGMAP] 找到 BigMapRoot name=BigMapRoot（大地图可探索演示已接线）
[R38][BIGMAP][EVIDENCE] frame=0 camera=(2048.0, 1152.0) player=(2048.0, 1152.0) layers=4 zoom=(0.5, 0.5) map=(4096.0, 2304.0)（只读回读，不写）
[R38][INPUT] frame=30 真实按键 移动(KEY=87) -> Input.parse_input_event(InputEventKey) → BigMapRuntime._unhandled_input → 大地图玩家位移 / 相机跟随 / 4 层视差滚动（可探索）
[R38][INPUT] frame=78 真实按键 移动(KEY=4194320)（↑）… / frame=102 (KEY=4194322)（↓）… / frame=114 (KEY=4194319)（←）…
[R38][BIGMAP][EVIDENCE] frame=225 camera=(2048.0, 1120.0) player=(2048.0, 1120.0) layers=4 zoom=(0.5, 0.5) map=(4096.0, 2304.0)
[R38][BIGMAP][EVIDENCE] frame=449 camera=(2048.0, 1120.0) player=(2048.0, 1120.0) …
==== [R22 presentation] 时间线完成 frame=450（--quit-after 450 负责退出）====
```

> 如实登记：8 向轮转移动键互相抵消，450 帧内净位移仅 32px（1152→1120），演示只证明「真实移动键 → 生产运行时 → 相机跟随」链路；「相机随玩家位移且边界受限」的完整证明由 V150 D 组承担（不加载 `presentation.gd`）。headless 无帧缓冲，本轮**不含新录屏 / 目视帧**，由总指挥定稿录屏亲自目视。

### 6.5 额外复跑：既有 5 份回归（如实登记 8 条 A38 过期 FAIL）

```
[V140]   SUMMARY pass=25 fail=1 total=26  RESULT=MISMATCH  | A2 A38 节点数 == 41 | count=54 expected=41
[V100HUD]SUMMARY pass=47 fail=1 total=48  RESULT=MISMATCH  | F1 静态 [node] 行数 == 41 | count=54 expected=41
[V110]   SUMMARY pass=71 fail=4 total=75  RESULT=MISMATCH  | A38-1 行数 41 / A38-2 uv 2/1/1 / R36-5 节点 41 / R37-8 节点 41
[V130]   SUMMARY pass=38 fail=1 total=39  RESULT=MISMATCH  | F7 节点 41 / uv 2/1/1
[V120P]  SUMMARY pass=30 fail=1 total=31  RESULT=MISMATCH  | P5 节点 41 / uv 2/1/1
合计 211 PASS / 8 FAIL（8 条全部且仅为 A38 旧基线过期，非本轮功能回归；断言集合 219 条未变）
```

---

## 7. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 四块任务全真跑完成（大地图层 / 2.5D / 人物 40% / A74 断言同步 / V150 主回归）。② V040 37/37、V150 37/37 双 `RESULT=ALL_MATCH`；V150 覆盖地图尺寸 ≥ 阈值、视差层数 ≥3、y_sort、相机随玩家位移且边界受限、角色 == 基线 ×0.40、既有战斗入口可达、HUD 避让不失效。③ 三段门禁 G1 / G2a(7) / G2b / G3 全 `EXIT=0`，450 帧演示 `EXIT=0`，全工程 `SCRIPT ERROR=0 / PARSE_ERROR=0`（20 份日志）。④ A74 新基线 41→54 / uv 2/1/1→16/8/8 真跑回读并同步 V040，不删断言、不放宽判定。⑤ 人物 40% 实测（0.64 / 像素高 2.4m→0.96m / 3 节点 scale 实测）。⑥ 大地图是新增层、既有 41 节点与 v0.1~v0.14 入口不删不改；不切后端、不引入真 3D 网格、美术规格不变。⑦ 数值一律数据驱动（`world_scale.tres` 唯一入口）。⑧ 只写授权文件、其余只读。⑨ 回执写入并确认中枢归档（§11）。 |
| **失败 / 未达** | ① **既有 5 份回归 8 条 A38 旧基线断言 FAIL**（211 PASS / 8 FAIL，全部且仅 41 / 2-1-1 过期，非功能回归）—— 不在本轮授权写入清单，按硬约束未越权同步，见 §10 待裁决 #1。② **定稿录屏 / 目视帧**：headless 无帧缓冲，本轮不含新 MP4 / 抽帧 / 目视结论；大地图 2D 层与既有 3D `SubViewport` 的实机视觉叠加待总指挥目视。③ **演示净位移幅度小**（8 向抵消，Δ32px），完整可探索性由 V150 D 组证明，演示未覆盖长距离巡航。④ **HD-2D 全绿未达**（沿用 A41/A52/A61/A68）：仍 2D `_draw()` / screen-reading shader 近似、无真 DoF / 真体积光 / SSR / Forward+。 |
| **需用户确认 / 待裁决** | 见 §10（共 7 项，#1 为 A74 断言同步授权冲突）。 |

---

## 8. A48 四项逐条自查（硬要求）

| # | 条款 | 结论 | 实证 |
|---|---|---|---|
| ① | 新信号必须有**生产运行时订阅者** | **本轮 Rank-1 未新增任何信号**（大地图层用 `_unhandled_input` / `_process` 直接生产逻辑 + 只读快照，不引入事件广播），故无"无订阅者的新信号"，不构成违反；若总指挥要求大地图层改为信号驱动，列 §10 待裁决。（真跑日志中 `[R38][WaveTrial] 大地图野外遭遇生产订阅者已装配：WorldEncounterService 唯一实例 + 4 信号 connect（A48①/A54）` 为 Rank-2 本轮并行产出，非 Rank-1 文件。）| `r38_g3_quit.log` / `r38_presentation_logic.log` 生产装配日志 |
| ② | 遵守 A54 唯一实例 | **达标**。`world_scale.tres` 是唯一配置源（`Resource`），`BigMapRuntime` / `CharacterScaleApplier` / `hud.gd` / V150 一律 `CACHE_MODE_IGNORE` 读同一张表，不自建第二份配置、不新增全局服务单例。 | V150 A1/A2、C4 `config_valid=true` |
| ③ | 不加载 `presentation.gd`、不在验证脚本内模拟编排的**真实可达回归** | **达标**。V150 A0 断言运行时树零 presentation 节点；真实 `InputEventKey`（`Input.parse_input_event`）→ 显式送生产 `BigMapRuntime._unhandled_input` / `_process`（V140 同口径）→ 玩家位移 / 相机跟随 + clamp / 4 层视差滚动 / 真实节点 scale 与 rect 回读；既有战斗入口 / `wave_trial.tres` 真实存在。 | V150 A0/D1/D2/D3/D4/C2/F1~F3 全 PASS |
| ④ | 纯逻辑 + 单元断言不算可玩交付 | **达标**。交付含真实 54 节点场景、真实输入、生产运行时、生产 HUD 布局节点、450 帧演示逻辑真跑（33 次真实移动键注入、相机跟随实证）、三段门禁 + 主回归真跑；`presentation.gd` 仅作注入机会，真实可达由 V150 承担。 | §6.1 / §6.3 / §6.4 |

**SceneTree / `--script` 纪律**：V150 用 `Engine.get_main_loop() as SceneTree` 取 root（不用 `get_tree()` / 不用 `/root/...` 绝对路径）、`CACHE_MODE_IGNORE`、`add_child` 后以「快照 `config_loaded`」幂等守卫显式 `call("_ready")`；本脚本不 `connect` 任何信号，无 disconnect 欠账（connect 场景沿用 V140 的 `get_signal_connection_list()` 去重 + 释放口径）；`project.godot` 既有 `PointsCommitOrchestrator` autoload 直接复用、不重复挂载。场景改动后已跑 `--headless --import` 同步 `.import` / uid（G1 `EXIT=0`）。

---

## 9. 硬约束遵守声明

- **唯一写入方**：只写 ①~⑫（授权清单内）。**未改** `project.godot` / `impact_feedback.gd` / `hd2d_fx.gd` / `hd2d_parallax.gd` / `wave_trial_director.gd`（Rank-2）/ `points_commit_orchestrator.gd`（Rank-3）/ 全部既有 `.tres` 数值 / 素材 / 既有 5 份 `verify_*` 回归脚本 / 其它 Rank 产出。
- **大改特别条款**：① 既有可玩闭环全保留（V150 F1~F3 + V040 `instance_override_preserved` PASS）；② 不切渲染后端（`gl_compatibility`）、不引入真 3D 网格；③ 美术规格不变（128px / ≤16 色 / ≥256 色 / RGBA / 硬边无噪点，本轮未动任何素材与色库）；④ 人物缩放与地图尺寸数据驱动（`world_scale.tres` 唯一入口，脚本无 1.6 / 0.64 / 4096 / 2304 字面量）；⑤ V040 断言按新基线同步、不删不放宽（**其余 5 份脚本的 A38 断言因授权冻结未同步，如实登记为 §10 待裁决 #1**）。
- **零付费 / 零外部依赖 / 不启 GPU job**：仅本地 Godot 4.7.2；未 `--write-movie` 录屏 / 未调 ffmpeg / 未列任何付费项。
- **默认不刺探**：未主动扫目录做进度巡检、未新建只读探针 / 巡检脚本；读取均针对任务单指定契约 / 目标文件 / 门禁日志 / 回执归档确认所必需路径，用真跑输出判断。
- **不伪造产物、不谎报成功**：20 份日志非空；V150 首轮 1 条 FAIL（路径解析 bug）如实登记并修复复跑；既有 5 份 8 条 A38 过期 FAIL 如实登记、未隐瞒、未擅自改清单外文件；未冒称录屏目视通过 / 未冒称 HD-2D 全绿 / 未冒称演示覆盖长距离巡航。
- **不自行 git**（总指挥收尾）；**未删除 `.workbuddy` 目录**。

---

## 10. 未完成项 / 待总指挥裁决项（如实登记，不擅改）

**待裁决 #1（最高优先 · A74 断言同步授权冲突）**：既有 5 份回归共 8 条 A38 旧基线断言因 A74 新基线（节点 54 / uv 16-8-8）过期而 FAIL，**全部且仅**为静态基线期望值过期、非本轮功能回归（211 PASS / 8 FAIL，219 条断言集合未变）。这 5 份脚本**不在【目录所有权·R38 冻结】Rank-1 唯一写入清单内**（清单只授权 `verify_wave_runtime_v040.gd` 与 `verify_bigmap_v150.gd`），按【硬约束「只写任务单授权文件」】与目录所有权明文「各 Rank 只写自己授权范围，接口异议写进 DONE 的待总指挥裁决」，本轮**未越权同步**。请总指挥裁决：授权下轮（或本轮补单）由 Rank-1 按「只改期望数字 / 标签 / 注释、不删断言、不放宽判定」同步，或指定其它归属。**精确同步清单（可直接执行）**：

| 文件 | 断言 tag | 改前期望 | 改后期望 |
|---|---|---|---|
| `scripts/render/verify_life_runtime_v140.gd` | `A2 A38 courtyard.tscn 节点数 == 41` | 41 | **54** |
| `scripts/render/verify_hud_layout_v100.gd` | `F1 静态 [node] 行数 == 41` | 41 | **54** |
| `scripts/render/verify_production_chains_v110.gd` | `A38-1 行数 == 41` | 41 | **54** |
| `scripts/render/verify_production_chains_v110.gd` | `A38-2 uv 2/1/1` | `(2,2,1)×1 + (1,1,1)×2` | **`(16,16,1)×1 + (8,8,1)×2`** |
| `scripts/render/verify_production_chains_v110.gd` | `R36-5 A38 节点数 == 41` | 41 | **54** |
| `scripts/render/verify_production_chains_v110.gd` | `R37-8 A38 节点数 == 41` | 41 | **54** |
| `scripts/render/verify_focus_runtime_v130.gd` | `F7 节点 41 / uv 2/1/1` | 41 / 2-1-1 | **54 / 16-8-8** |
| `scripts/render/verify_parry_runtime_v120.gd` | `P5 节点 41 / uv 2/1/1` | 41 / 2-1-1 | **54 / 16-8-8** |

**其余未完成 / 待裁决项**
2. **定稿录屏 / 目视帧**：按公共契约由总指挥亲自重跑并目视首/中/尾三帧；本轮 headless 无帧缓冲、不含新 MP4 / 抽帧 / 目视结论。人物 40% 在大地图上实机可读性、HUD 不遮角色观感待目视（V150 只证明几何 `worst_overlap=0`）。
3. **大地图 2D 层与既有 3D 层的视觉融合 / 标准相机管线**：本轮 `Camera2D` 未接管 root viewport `canvas_transform`（以 `BigMapRoot.scale=zoom` + 脚本手动视差实现），是为「不破坏既有 `SubViewportContainer` 3D 画面」的取舍；是否改用标准 `Camera2D.current` + 独立 Viewport / `follow_viewport_enabled`，以及大地图是否应盖住 / 与 3D 战斗场景分层渲染，请裁决（涉及 `courtyard.tscn` 后续结构，可能影响 A74 节点基线再次变化）。
4. **`[PLACEHOLDER]` 试玩校准**：`world_scale.tres` 全部数值（地图尺寸 / zoom / limit / 4 层系数 / 雾 / 移速 / 脉冲）、`hud.gd` 角色包围盒基线 `ANCHOR_CHAR`、`presentation.gd` R38 注入节奏待人工试玩校准；调参唯一入口 = `world_scale.tres`（只改表不改代码）。
5. **演示长距离巡航覆盖**：450 帧 8 向轮转互相抵消、净位移仅 32px；是否需单向持续注入段 / 专门的相机巡航演示段，请裁决（本轮未擅改任何既有 `[PLACEHOLDER]` 节奏）。
6. **跨 Rank 接口对齐**：Rank-2（野外遭遇 `WorldEncounterService`）/ Rank-3（世界地图服务 / 赐福点 / 存档）/ Rank-4（大地图美术规格 / 40% 人物可读性 / 定稿录屏）本轮并行派单；大地图 `BigMapRoot` 节点路径、相机 / 玩家位置对外消费接口、野外遭遇触发点归属请总指挥在汇总时统一裁决，本轮未擅自新增跨 Rank 接口。
7. **沿用前序未完成项**：A38 §3.3 契约同步 / HD-2D 全绿路线 / `128bit` 歧义 / 真机 exe·apk 手感与移动端触控 / GitHub 补推 / A43 目视口径（同 DONE-R37 §8）。

---

## 11. 回执与中枢归档确认（写后实测，如实登记）

- 回执写入授权路径（**`teamwork/command_center/`**，非工程根）：`teamwork/command_center/ai/1/outbox/cmd-20261112-234238-645-A1.json`，四字段 `{"task_id":"…","ai":1,"status":"done","result":"…引用 DONE-R38.md 实际结论…"}`。
- **中枢归档回读确认（写后实测）**：
  - `ai/1/outbox/` 已清空（回执被中枢移走 → `dispatcher/receipts/`）：`outbox_count=0`。
  - 归档副本 `teamwork/command_center/dispatcher/receipts/cmd-20261112-234238-645-A1.json` 存在（**2942 字节**），回读 **VALID_JSON**，四字段齐全：`keys=['ai','result','status','task_id']` / `task_id=cmd-20261112-234238-645-A1` / `ai=1` / `status=done` / `result_len=1778`。
  - `ai/1/status.json`：`{"ai":1,"state":"idle","current_task":"","completed":69,"last_seen":"2026-11-13 00:21:33"}`（`completed` 68→69、`current_task` 清空、state working→idle）。
  - `dispatcher/dispatcher.log` 尾部原文：`[2026-11-13 00:21:33] ← 1 号 AI 回执 <cmd-20261112-234238-645-A1> 完成：R38 / v0.15.0「大地图 · 2.5D 尺度重构」四块任务全部真跑完成，实际结论见 teamwork/Rank…`，确认 id 与派单一致、中枢已回收验证 `done`。
  - `dispatcher/ledger.jsonl` 本任务行回读 **VALID_JSON**：`id=cmd-20261112-234238-645-A1 / command=cmd-20261112-234238-645 / ai=1 / status=done / issued_at=2026-11-12 23:42:39 / finished_at=2026-11-13 00:21:33 / result_len=1778`，`RESULT_MATCH=True`（与回执 result 逐字一致）。
