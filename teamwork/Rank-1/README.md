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
