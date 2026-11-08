# Rank-1 · 引擎架构与渲染（1 号执行 AI 交付）

> 派单：`teamwork/Rank-1/任务书.md`；需求源：`00-项目总纲.md`；规则：`00-协作契约.md`（冲突以契约为准）。
> 本轮只在 `Rank-1\` 内产出，**未修改** teamwork 根目录、总纲、契约、其它工位任务书或任何其它编号文件夹。

---

## 1. 模块目标

Godot 4 标准版 / GDScript 下打通 2.5D HD-2D 的**工程侧底座**：

1. 640×360 低分辨率 SubViewport → 2× Nearest 整数放大，保证「像素精灵 vs 平滑景深」的对比；
2. 3D 地形 + `Hybrid2D3D-Renderer` 像素角色（缩放 / 底部中心锚定 / 自定义 AABB 由扩展负责，1 号不自造 billboard）；
3. 大地图 3×3 chunk 异步流式加载，三态去重 + 延迟卸载，M2 无帧尖峰；
4. 光照与 FX 挂点、性能分级、性能预算与可量化验收口径；
5. 给 2 号一个极简的 `set_pose` 接口，给 3 号一条只读 flag 桥，给 4 号一份导入规范，给主 AI 一张 M0~M6 排期表。

---

## 2. 交付清单

### 2.1 任务书固定的 6 个文件（齐全）

| # | 文件 | 内容 | 落位（`res://`） |
|---|---|---|---|
| 1 | `README.md` | 本文件 | `docs/` |
| 2 | `架构设计.md` | 渲染链路 / 缩放公式 / 锚定 / AABB / 遮挡排序、光照与 FX 挂点与性能分级、chunk 状态机与 `ResourceLoader` 完整时序、性能预算表与 M2 验收口径、I-1 存档对接、密度原则 | `docs/` |
| 3 | `目录与命名规范.md` | 完整工程目录树、`res://` 路径对照表、5 个 autoload 单例与归属、`project.godot` 关键配置、像素图导入规范、输入 action 映射表、命名检查清单 | `docs/` |
| 4 | `场景树骨架.tscn` | Godot 4 合法文本场景：Main → SubViewportContainer(stretch_shrink=2) → SubViewport → Camera3D + SunLight + WorldEnvironment + Ground + Backdrop + WetReflection + Player/Hybrid2D3DAnimatedSprite + ChunkRoot + FXLayer | `scenes/Main.tscn` |
| 5 | `chunk_streaming.gd` | `ChunkManager` autoload 脚本：3×3 加载/卸载、四态去重、延迟卸载、并发上限、`load_threaded_request/get_status/get` 完整时序、`chunk_loaded` / `chunk_unloaded` 信号、公开 `set_player_chunk(chunk)`、I-1 flag 桥、密度校验、M2 载入计数 | `scripts/world/chunk_streaming.gd` |
| 6 | `接口契约.md` | I-1 / I-4 / I-5 / I-6 对齐、对外信号 / 方法 / 资源字段、依赖降级矩阵、**M0~M6 分阶段交付表** | `docs/` |

### 2.2 附加可落地件（I-4 的实现，任务书 §5 要求 1 号「封装 `Hybrid2D3DAnimatedSprite`」）

| 文件 | 说明 | 落位 |
|---|---|---|
| `hybrid_2d3d_animated_sprite.gd` | `场景树骨架.tscn` 里 `Hybrid2D3DAnimatedSprite` 节点引用的脚本，只向 2 号暴露 `set_pose(pose_name, frame_index)`。若不交付，`Main.tscn` 会因 `ExtResource` 缺失而报红，故作为第 7 份一并给出。 | `scripts/render/hybrid_2d3d_animated_sprite.gd` |

> 6 个固定文件齐全，附加件不替代任何一项，也不需要 2/3/4 号改动自己的目录。

### 2.3 实际文件路径列表（交主 AI 汇总用）

```
F:\Game\aierdengfahuan\teamwork\Rank-1\README.md
F:\Game\aierdengfahuan\teamwork\Rank-1\架构设计.md
F:\Game\aierdengfahuan\teamwork\Rank-1\目录与命名规范.md
F:\Game\aierdengfahuan\teamwork\Rank-1\场景树骨架.tscn
F:\Game\aierdengfahuan\teamwork\Rank-1\chunk_streaming.gd
F:\Game\aierdengfahuan\teamwork\Rank-1\接口契约.md
F:\Game\aierdengfahuan\teamwork\Rank-1\hybrid_2d3d_animated_sprite.gd
F:\Game\aierdengfahuan\teamwork\Rank-1\任务书.md   ← 主 AI 派单，只读，本轮未改动
```

---

## 3. 对外接口摘要

| 接口 | 方向 | 摘要 |
|---|---|---|
| **I-1** | 3 → 1 | 只经 `WorldState.get_flag(key, default)`；chunk 加载时收集 `get_flag_keys()` 并转交 `apply_world_flags(flags)`；不碰存档文件 / SaveDelta / flag schema |
| **I-4** | 1 → 2 | `Hybrid2D3DAnimatedSprite` 节点唯一玩法接口 `set_pose(pose_name, frame_index)`；2 号不写 billboard / 锚定 / AABB |
| **I-5** | 4 → 1 | 按 `assets/generated/<品类>/` + `import.json`（帧尺寸 / 锚点 / 帧数 / 动作名）导入；lossless、无 mipmaps、Nearest 三条硬规范 |
| **I-6** | 1 → 主 AI | `接口契约.md` §5 的 M0~M6 表，含每阶段交付件、上游依赖、验收口径、当前状态 |

发出的信号：`chunk_loaded` / `chunk_unloaded` / `chunk_load_failed` / `player_chunk_changed`（`ChunkManager`）、`pose_changed`（`HybridSpriteRig`）。1 号**不订阅**任何玩法信号，避免与 3 号 Delta 形成双写。

---

## 4. 未完成项与验证状态

| 项 | 状态 | 说明 |
|---|---|---|
| 在 Godot 4 引擎内实际打开 / 运行 | **未运行** | 本机 PATH 与常见安装位置均未找到 `godot*.exe`，无法真跑。`.tscn` / `.gd` 按 Godot 4 语法静态编写，需在 M0 装入引擎后做首次打开验证 |
| `project.godot` 实体文件 | 本轮未产出 | 任务书把配置写进 `目录与命名规范.md`（§4 给出可直接粘贴的片段），未单独建工程根文件——工程根 `F:\Game\aierdengfahuan\` 尚未建立，且不在 1 号可写目录内 |
| `scene_router.gd` / `camera_rig.gd` / 性能 HUD / 画质档 `.tres` | 待 M1 / M2 | 本轮按任务书范围交付骨架与流式加载核心，其余按 `接口契约.md` §5 排期 |
| 3 个 chunk 场景、POI、地牢、Boss 场景 | 属 3 号 / 2 号 | 1 号只给 `ChunkMeta` 字段与密度校验钩子 |
| GDExtension 装入与 `set_custom_aabb` 实际 API 名校准 | 待 M0 | 脚本内已用 `has_method` / 属性检测做守卫，扩展不在时静默降级，不阻塞骨架 |
| 人工试玩与手感 / 审美判断 | 未做 | 按总纲与契约，手感与审美必须由用户亲自兜底 |

按契约「不写探针 / 测量 / preflight 脚本」，本轮**没有**产出任何探针或测量脚本；验证靠 M0 首次真跑与 M2 的 F3 性能 HUD（属交付件，不是临时脚本）。

---

## 5. 待主 AI 裁决项

> 以下均为跨模块 / 跨文件不一致或契约未定义处。1 号**没有**改任何人文件，只在自己范围内按最稳妥方式落地，请主 AI 在 `00-汇总.md` 统一裁决。

1. **目录名 `1\` vs `Rank-1\`（高优先）**
   总纲契约 §1、任务书 §0、根目录 README 均写 `teamwork\1\`，但磁盘实际为 `Rank-1\`（另有 Rank-2/3/4）。用户明确指定 1 号只写 `Rank-1\`，本轮按**实际磁盘 + 用户指令**写入。建议主 AI 统一契约与导航的目录名，或明确「Rank-N 即 N 号工位」。

2. **`project.godot` 键名字面差异（高优先）**
   1 号任务书 §3 写 `rendering/textures/canvas_items/default_texture_filter=0`；Godot 4 实际合法键是 `rendering/textures/canvas_textures/default_texture_filter`（`[rendering]` 段内为 `textures/canvas_textures/...`）。本轮按**引擎合法键**写入 `目录与命名规范.md` §4，否则工程会忽略该配置、M0 像素验收直接失败。建议更正任务书字面。

3. **I-4 封装类名与 GDExtension 全局类同名风险**
   契约写「封装 `Hybrid2D3DAnimatedSprite` 节点」。若扩展注册了同名全局类，GDScript 再写 `class_name Hybrid2D3DAnimatedSprite` 会触发 "hides a global script class" 启动报错。本轮：场景**节点名**保持 `Hybrid2D3DAnimatedSprite`（符合契约），脚本类名取 `HybridSpriteRig`。请裁决该命名是否可接受，或指定扩展实际注册的类名。

4. **autoload 归属未定义**
   任务书要求列出 `WorldState / GameEvents / SaveSystem / ChunkManager / SceneRouter` 并注明归属。契约 §3 只授权 3 号定义 `WorldState.get_flag/set_flag` 与 `SaveDelta`，未定义 `GameEvents` 归属，也未授权 1 号写 `scripts/core/game_events.gd`。本轮把 `GameEvents` 标为「待裁决，建议 3 号或主 AI」，`ChunkManager` / `SceneRouter` 归 1 号。请裁决并同步给 3 号。

5. **flag schema 与负坐标 chunk id 命名**
   I-1 只给方法不给键名。1 号建议 `world.chunk_limgrave_0_0.chest_01_opened` 形状；负坐标按契约 `chunk_<区域>_<x>_<y>` 会生成 `chunk_limgrave_-1_0`（含连字符），是否与 3 号存档键、4 号资产目录兼容需确认。1 号当前按契约字面生成负号形式，未擅自改为 `_m1_`。

6. **M2 验收的目标硬件**
   `架构设计.md` §4 给出 p99 ≤ 20 ms / 单帧 ≤ 33.3 ms / 内存 ±10% 的可量化口径，但目标机器未指定。本轮默认「本机集成显卡 + Low 档」。请用户或主 AI 确认验收机型。

7. **Godot MCP 在 M0 的验收权重**
   总纲 §1 与 §6 把「WorkBuddy 通过 Godot MCP 创建/修改节点」列为 M0 前置，而契约 §5 的技术约束未包含 MCP，且强调零外部依赖。1 号骨架是纯文本 `.tscn`，**不依赖 MCP 即可落地**。建议主 AI 把「MCP 连通」从 M0 硬验收降级为可选工具链验证，避免阻塞工程侧验收。

8. **总纲 §6「云 ComfyUI」与契约零外部依赖冲突**
   契约 §5 已明确该分支按项目既定决策废弃、改为纯本地降级；总纲 §6 仍保留「云 ComfyUI」待确认项。1 号按契约执行（零付费、零外部服务、程序化 `_draw()` 占位），请主 AI 在汇总中显式标注总纲该条已作废。

9. **密度校验的责任边界**
   1 号在 `chunk_streaming.gd` 里读 `get_poi_count()` 并打 `[density]` 警告，但「POI 摆放」属 3 号。请裁决该警告是「工程侧硬校验」还是「仅提示」；若 3 号不实现 `get_poi_count()`，1 号静默跳过、不阻塞加载（当前实现）。

10. **GDExtension 版本与 `Hybrid2D3DSprite` 真实 API**
    总纲只写 GDExtension 名称，未给版本与具体方法名。1 号脚本对 `set_custom_aabb` / `custom_aabb` 做了存在性守卫，M0 装入后需按实际 API 校准一次；此项需用户确认所用版本，1 号不擅自联网安装或声明版本。

---

## 6. 使用方式（给主 AI / 工程搭建者）

1. 按 `目录与命名规范.md` §2 的对照表，把 `场景树骨架.tscn` → `res://scenes/Main.tscn`，`chunk_streaming.gd`、`hybrid_2d3d_animated_sprite.gd` → 对应 `res://scripts/` 路径（三者必须一起拷，否则 `ExtResource` 报红）。
2. 按 §4 粘贴 `project.godot` 配置，按 §3 注册 5 个 autoload（注意 `chunk_streaming.gd` **不要**加 `class_name`）。
3. 按 §5 用编辑器 Input Map 生成 input actions（1 号只给映射表，避免手写序列化字段与小版本不一致）。
4. M0 在引擎里首次打开 `Main.tscn`，验证脚贴地、像素硬边、无 z-fighting；再按 `接口契约.md` §5 推进 M1/M2。

---

## 7. R2 交付清单（追加节；§1~§6 首轮内容原样不改）

> 派单：`任务书-R2.md`；临时口径：`00-续派与监测规则.md` §6；引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`（`--version` 实测 `4.7.2.stable.official.ed1daf0bf`）。
> 本轮把 §4 记录的「未运行 / `project.godot` 未产出 / `scene_router`、`camera_rig`、性能 HUD、画质档待 M1/M2」推进为**引擎可解析、可打开**的工程侧交付件，并按契约 §10 真跑三段构建门禁。R2 口径 §6 第 8 条已作废「本机未找到 godot、无法真跑」的旧结论。
> 完成标志另见本工位 `DONE-R2.md`（HOST 监测只认该文件）。

### 7.1 本轮实际交付 / 更新文件

| 文件 | 动作 | 内容 | 工程落位（`res://`） |
|---|---|---|---|
| `project.godot` | 新建 | 合法 Godot 4 工程配置：`config_version=5`、5 个 autoload、15 个 input action、`[hd2d]` 冻结值、双档画质路径、`[rendering]` 用 `textures/canvas_textures/default_texture_filter=0`、Jolt + 固定 ticks | 工程根 `project.godot` |
| `scene_router.gd` | 新建 | `SceneRouter` autoload：`pause_chunk_stream()` / `resume_chunk_stream()` / `request_short_load(dungeon_id, direction)` / `travel_to_grace(target_grace_id)` 及 6 个信号，回应 3 号 A6「加载接口归属」；`_ready()` 实际加载两份画质档 `.tres` | `scripts/core/scene_router.gd` |
| `camera_rig.gd` | 新建 | 相机跟随 + SubViewport 低分辨率缓冲 / 整数倍放大；冻结 `640×360 @2x`、`PIXELS_PER_METER = 32.0` 常量供 4 号 A4 | `scripts/render/camera_rig.gd` |
| `performance_hud.gd` | 新建 | M2 的 F3 性能 HUD：帧时间 / p99 / 常驻 chunk 数 / 静态内存（交付件，非临时测量脚本） | `scripts/ui/performance_hud.gd` |
| `quality_preset_desktop.tres` | 新建 | 桌面档：640×360、9 chunk、FX 全开、16.67 ms、1536 MB | `data/render/quality_preset_desktop.tres` |
| `quality_preset_mobile.tres` | 新建 | 移动降级档（契约 §9.2）：480×270、4 chunk、FX 全关、33.33 ms、512 MB | `data/render/quality_preset_mobile.tres` |
| `quality_preset.gd` | 新建（附加必要脚本） | `class_name QualityPreset extends Resource`，定义两档 `.tres` 的字段结构；不替代任何固定交付项 | `scripts/core/quality_preset.gd` |
| `hybrid_2d3d_animated_sprite.gd` | 更新 | 锁定 `set_pose(pose_name, frame_index)` 的 `frame_index` = 动作内帧索引、clamp 归 1 号；冻结 pose 枚举做名称校验；**不扩展 I-4 接口**，pose 前缀沿用 `p1_`/`p2_` | `scripts/render/hybrid_2d3d_animated_sprite.gd` |
| `场景树骨架.tscn` | 修正 R1 遗留缺陷 | 真跑暴露两处 `Transform3D(...)` 写成 13 参数（合法 12），已修正为 12 参数，`Main.tscn` 由此可被引擎打开 | `scenes/Main.tscn` |
| `README.md` | 追加 §7 | 本节，首轮内容不改 | `docs/` |
| `DONE-R2.md` | 新建 | 完成标志：交付清单 / 真跑输出结论 / 未完成项与阻塞 / 给 4 号的冻结值 | — |

> 任务书 §2 固定 8 类文件全部产出；`quality_preset.gd` 为让 `.tres` 可被引擎加载校验而附加的必要脚本，`场景树骨架.tscn` 为真跑暴露缺陷后的修正，二者均为附加，不替代任何固定项。

### 7.2 真跑结论（契约 §10 三段门禁）

引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`，`--version` 实测 `4.7.2.stable.official.ed1daf0bf`（EXIT=0）。
`config_version` 说明：该键是 Godot 工程配置**格式版本**（整数，Godot 4.x 为 5），**不是引擎版本号**；`--version` 实测值用于 `config/features=PackedStringArray("4.7", "GL Compatibility")`，`config_version=5` 通过下方 `--headless --import` / `--headless --quit` 真跑验证被 4.7.2 接受（日志无 config_version 相关警告、引擎未回写或拒绝），**非凭记忆硬编码**。

在系统临时目录 `C:\Users\62668\AppData\Local\Temp\r1_r2_verify` 建最小工程（放入本工位交付文本件；因 3 号 `WorldState` / `GameEvents` / `SaveSystem` 尚未交付，验证工程内放了 3 个最小 stub 让 5 个 autoload 能加载，stub **不进入交付件、用完即删**），逐条真跑：

| 段 | 命令 | 退出码 | 结论 |
|---|---|---|---|
| 0 | `<godot> --version` | 0 | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `<godot> --headless --path <tmp> --import` | 0 | 全局类 `QualityPreset` / `HybridSpriteRig` 注册成功，无 Parse Error |
| 2 | `<godot> --headless --path <tmp> --check-only --script <6 个 .gd>` | 6 条均 0 | 6 个本工位 `.gd` 全部静态解析通过 |
| 3 | `<godot> --headless --path <tmp> --quit` | 0 | 打开 `Main.tscn` + `SceneRouter._ready()` 加载两份 `.tres` 成功 |

- **首轮真跑（未修正前）暴露 3 个真实缺陷**：① `camera_rig.gd` 用了 Godot 4.7 不存在的 `expf()`（G2 SCRIPT ERROR）；② R1 `场景树骨架.tscn` 两处 `Transform3D` 参数个数错误（G1/G3 `Parse Error: [Resource file res://scenes/Main.tscn:53]`、G3 EXIT=1）；③ `.tres` 内 `;` 注释保守移除。三处均已修正后**清缓存全量复跑**上表结果。
- **grep 校验（关键：运行时 SCRIPT ERROR 不改退出码，必须 grep）**：`grep -rn "SCRIPT ERROR"` → **NONE**；`grep -rni "error"` → **NONE**；`Parse Error / ERROR: / Failed loading` → **NONE**。
- G3 日志仅有 9 条 `WARNING: [ChunkManager] chunk_limgrave_* 加载跳过：scene_missing`：因临时工程不含 3 号负责的 chunk 场景，属 `chunk_streaming.gd` 既有降级设计（每个 id 只 warn 一次），非 SCRIPT ERROR、不影响退出码。
- 临时验证工程已删除（`DELETE_OK`），只留上述结论；未写入 teamwork、未提交。
- **结论：三段门禁真跑通过**，本工位 `.gd` / `.tscn` / `.tres` / `project.godot` 均为 Godot 4.7.2 可解析、可打开的合法语法。

### 7.3 仍未完成项

| 项 | 状态 | 说明 |
|---|---|---|
| 工程根 `F:\Game\aierdengfahuan\` | 按任务书 §1 约定不建立 | 本轮所有工程根文件以「工位内文本件」产出，注明供建工程根时拷贝；非阻塞 |
| 3 号 `WorldState` / `GameEvents` / `SaveSystem` 真实实现 | 待 3 号 | 临时验证工程用 stub 代替；真工程落地前需 3 号交付（口径 §6 第 3 条：GameEvents 由 3 号实现、1 号注册） |
| 3 号 chunk 场景 / 地牢场景 / 赐福网络 | 待 3 号 | G3 的 9 条 `scene_missing` 即此；M2 验收需至少 3 个占位 chunk 场景；`request_short_load` 的 `change_scene_to_file` 目前走空跑降级 |
| 4 号 `import.json` / spritesheet / ≤256 色调色板 | 待 4 号 | I-5 未联调；`pose_frame_counts` 待导入流程回填，缺省时 `frame_index` 只做下限 clamp |
| GDExtension `Hybrid2D3D-Renderer` 装入与 `set_custom_aabb` API 校准 | 待 M0 | 脚本已有 `has_method` / 属性守卫，扩展不在时静默降级 |
| 移动端常驻 chunk 数降级落地 | 待 M2 | `.tres` 写 4，但 R1 `chunk_streaming.gd` 固定 `RADIUS=1` → 9 块，运行时按档位调整半径尚未实现（未伪造已实现） |
| 人工试玩 / 手感 / 审美判断 | 未做 | 按总纲与契约由用户亲自兜底 |
| R3 排队包 | 本轮不做 | 按 HOST 23:43 口径，未打开 `任务书-R3.md` |

### 7.4 本轮新增「待主 AI 裁决」（追加，不改 §5）

1. **4 号 A8 `@3x` vs 本工位冻结 `@2x`**：本工位按 R1 `场景树骨架.tscn` 的 `stretch_shrink=2` + 1280×720 窗口冻结 `640×360 @2x`；4 号 A8 假设 `640×360 @3x`。未擅自改骨架，冻结值经 `DONE-R2.md` 单列由 HOST 转交 4 号确认。
2. **负坐标 chunk id 字面**：真跑日志实证生成 `chunk_limgrave_-1_-1` / `chunk_limgrave_-1_0` 等含连字符形式，按任务书 §3 口径 7 保留契约字面 `chunk_<区域>_-1_0`，**未擅自改 `_m1_`**，与 3 号存档键、4 号资产目录兼容性待裁决。
3. **`GameEvents` 归属最终裁决**：本轮按口径 §6 第 3 条（3 号实现、1 号注册）推进，最终归属仍待主 AI 裁决后回改。
4. **移动端降级档的 chunk 半径实现方式**：见 §7.3，需裁决「改 `RADIUS`」还是「保持 9 块、只降分辨率/内存」。
5. **`config_version` 口径说明**：见 §7.2；若口径要求把 `4.7.2` 直接填入该整数键会产出非法 `project.godot`，已按引擎合法格式版本 5 落地并真跑验证，请主 AI 确认此解释。
