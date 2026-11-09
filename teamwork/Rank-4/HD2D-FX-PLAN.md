# HD2D-FX-PLAN.md · gl_compatibility 下 HD-2D 光效的程序化 CanvasLayer 近似方案

> 轮次：**R15**｜派单：`cmd-20261109-083628-786-A4`｜命令：`[ROUND=R15]`｜工位：Rank-4 美术管线与工具链｜日期：2026-11-09
> 定位：**方案件（只给方案，未实现）**。在 `gl_compatibility` 后端不支持 `Environment` glow / 屏幕空间后处理的前提下，把「体积光 / 光尘 / 湿地倒影 / bloom」四项 HD-2D 光效改用 **2D `CanvasLayer` + `CanvasItem` 原语**程序化近似。
> 前提（既有结论，不重做）：R13 / R14 已确认 `godot/project.godot:139-140` 桌面 / 移动双档 `renderer/rendering_method="gl_compatibility"`，该后端不支持 `Environment` glow；`Rank-1/DONE-R14.md` §③ #1 与 `capture/CAPTURE-REPORT.md` §2 均登记画面「无体积光 / 光尘 / 湿地倒影 / bloom」。
> 只读引用（均未改）：`capture/CAPTURE-REPORT.md`、`Rank-4/ART-SPEC-FINAL.md`、`godot/scripts/render/hd2d_placeholder.gd`、`Rank-1/DONE-R14.md`、`00-群聊总线.md`（**开工只读一次**）、`godot/scenes/courtyard.tscn`（只读核对节点与 layer，零写入）、`Rank-4/HD-2D视觉规范.md` §3 / §7 / §10、`Rank-4/scene_integration.md`、`godot/scripts/render/hd2d_placeholder_attach.gd`、`godot/scripts/core/render_profiles.gd`、`godot/data/render/render_profiles.tres`、`quality_preset_desktop.tres` / `quality_preset_mobile.tres`、`godot/project.godot`。
> 合规：零付费 / 零外部素材 / 零插件 / 零云服务；**ComfyUI 仍是主美术路线**，本方案是零外部依赖的 2D 程序化兜底，不取代主路线、不宣称已能出图；不改运行中 `.gd`、不写 `godot/scenes/courtyard.tscn`（Rank-1 本轮独占）、不自行 git；中文 UTF-8；不伪造输出、不臆造引擎常量。

---

## 0. 一句话结论

`gl_compatibility` 下 `Environment.glow`、3D 体积雾、屏幕空间反射都不可用；但 **2D `CanvasLayer` 上的 `CanvasItem` 绘制属纯 2D 管线，在该后端完全可用**。因此把四项光效从「3D 后处理 / 焊死在占位层里的单节点 `_draw()`」**外提**为 SubViewport 内 `FXLayer(layer=10)` 一侧的一套独立 FX CanvasLayer 栈：体积光用 `Polygon2D` + `Line2D`、光尘用 `Node2D._draw()` + `draw_circle()`、湿地倒影用 `_draw()` + `draw_rect()` 垂直镜像、bloom 用同心圆 / `GradientTexture2D` 渐变 + `CanvasItemMaterial` Add 混合近似过阈；以既有 `quality_preset_*.tres` / `render_profiles.tres` 的「桌面四项全开 / 移动四项全关」为冻结分档口径，另给「移动档降级而非全关」的待裁决建议。**本轮只交付方案，未实现、未真跑、未验收画面。**

---

## 1. 现状盘点（只读核对，不臆造）

### 1.1 两个 canvas 世界与既有 CanvasLayer

`courtyard.tscn` 现有 22 节点中与 FX 直接相关的部分（只读核对，逐字）：

| 节点路径 | 类型 | layer | 关键属性 | 角色 |
|---|---|---|---|---|
| `HD2DPlaceholderLayer` | `CanvasLayer` | **-10** | parent=`.`（根节点级，主 viewport canvas） | 既有 10 步 `_draw()` 占位背景层（A9 冻结） |
| `HD2DPlaceholderLayer/HD2DPlaceholder` | `Node2D` | — | `script=hd2d_placeholder.gd`、`texture_filter=1`(Nearest)、`integer_scale=2` | 单节点画完 9 视差层 + 实体 + UI |
| `SubViewportContainer/SubViewport/FXLayer` | `CanvasLayer` | **10** | 在 SubViewport **内部** World2D | 预留的前景 FX 层（叠加在 3D 之上） |
| `SubViewportContainer/SubViewport/FXLayer/LightDust` | `Node2D` | — | `visible=false` | **光尘的既有预留落点**（当前空 / 隐藏） |
| `SubViewportContainer/SubViewport/WetReflection` | `Node3D` | — | 空占位 | 湿地倒影的既有 3D 锚点 |

要点：

- `-10`（主 viewport canvas，最底）与 `10`（SubViewport 内部 World2D）**分属两个独立 canvas 世界**，layer 数值不直接比较、不冲突。
- 主树绘制序：`HD2DPlaceholderLayer(-10)` → `SubViewportContainer`（默认 layer 0，承载 3D 渲染纹理）→ 将来 UI（正 layer）。
- SubViewport 内部：3D 内容先渲染，其后所有 2D CanvasLayer 按 layer 从小到大叠加（**都覆盖在 3D 之上**，这是 2D/3D 混合的固有限制，见 §6 #2）。

### 1.2 现有 10 步 `_draw()` 占位里已有的四项近似（本方案的基线）

`hd2d_placeholder.gd` 单次 `_draw()` 10 步（对齐 `HD-2D视觉规范.md` §10 层序）：

| 步 | 既有近似实现 | 对应本方案 FX |
|---|---|---|
| step5 `_pass_05_fx_back` | `draw_colored_polygon()` ×4 扇形，alpha `[0.18,0.12,0.07,0.04]`；`draw_circle()` ×48 远景冷白光尘 | 体积光 + 远景光尘 |
| step6 `_pass_06_reflection` | 逐像素块 `draw_rect()` 垂直镜像、压缩 0.70、逐行波纹 `sin(t+y_ref)*0.03*BUFFER_W`、alpha 0.35 | 湿地倒影 |
| step8 `_pass_08_fx_front` | `draw_circle()` ×32 近景暖金光尘 + 同心圆 ×5 半径 `[4,8,14,22,32]` alpha `[0.20,0.12,0.07,0.04,0.02]` | 近景光尘 + bloom |

脚本注释已明确两处技术事实（本方案沿用）：「`_draw()` 无逐调用 Add 混合参数，用低 alpha 多次叠加近似径向光束衰减」「同心圆是 `threshold=0.95` 的几何近似，只让暖金高光过阈、冷夜雾保持不发亮」。

### 1.3 为什么必须「外提」到独立 FX CanvasLayer（三条理由）

1. **后端不支持 3D 后处理**：`gl_compatibility` 无 `Environment.glow` / 3D 体积雾 / SSR，bloom 不能靠 `WorldEnvironment`，体积光 / 倒影也不能靠 3D；2D `CanvasItem` 是唯一零依赖可行路径。
2. **占位层可见性不足**：`CAPTURE-REPORT.md` §2 登记「程序化占位层的视觉贡献不明显」；`scene_integration.md` §4 #3 已登记 `layer=-10` 背景层被不透明 3D 背景遮挡、遮挡顺序待 Rank-1 裁决。把 FX 放到 SubViewport 内 `FXLayer(layer=10)` 一侧（3D 之上）才可稳定可见。
3. **可独立分档 / 开关 / 替换**：焊死在单节点 `_draw()` 里的 FX 无法按桌面 / 移动逐项开关，也无法在占位层 `detach()` 退出后保留；拆成独立 CanvasLayer 后各层 `visible` 可由双档画像直接驱动（§4.4）。

---

## 2. 总体架构与叠加顺序

### 2.1 叠加顺序总表（从底 → 顶）

主 viewport（root）：`HD2DPlaceholderLayer(-10)` → `SubViewportContainer(0，3D 及其内部 FX)` → UI（≥20，将来）。

SubViewport 内部 World2D（**本方案新增 / 启用的 FX 栈**）：

| 序 | layer | CanvasLayer（建议名） | 承载 FX | 相对位置 |
|---|---|---|---|---|
| 0 | （3D 基准） | SubViewport 3D：Terrain / Player / WetReflection | 基底 | 最先渲染 |
| 1 | **1** | `FXReflection`（新增） | 湿地倒影 | 贴地、最靠下 |
| 2 | **2** | `FXGodRays`（新增） | 体积光 | 倒影之上 |
| 3 | **10** | `FXLayer`（**既有，冻结值保留**） | 光尘：启用其 `LightDust`（远景冷白 + 近景暖金两组） | 中段 |
| 4 | **11** | `FXBloom`（新增） | bloom 光晕 | 靠上，光晕覆盖一切 |
| 5 | **12** | `FXModulate`（新增，可选） | `CanvasModulate` 全局冷暖调制 | 最上、默认关 / 移动关 |

> 倒影(1) / 体积光(2) 属 `fx_0_back` 类（靠下），光尘(10) / bloom(11) 属 `fx_1_front` 类（靠上），与 `HD-2D视觉规范.md` §10 层序（`fx_0_back` 层序 4 → entity 层序 5 → `fx_1_front` 层序 6）一致。layer 值 1 / 2 / 11 / 12 避开既有 `FXLayer=10`（冻结，不动），无需连续。

### 2.2 与 `HD2DPlaceholderLayer(layer=-10)` 的关系（五条）

| # | 关系 | 说明 |
|---|---|---|
| 1 | **数值不冲突** | `-10` 属主 viewport canvas 最底；新 FX 层是 SubViewport 内部正 layer（1 / 2 / 11 / 12），分属不同 canvas 世界；既有 `FXLayer=10` 冻结值保留不改 |
| 2 | **本轮零改动** | `HD2DPlaceholderLayer` / `HD2DPlaceholder` / `hd2d_placeholder.gd` / `integer_scale=2` / `texture_filter=1` 一个字节不动（只给方案，不改运行中脚本、不碰场景） |
| 3 | **参照基线** | 占位脚本 step5 / 6 / 8 已是四项 FX 的 `_draw()` 近似；本方案沿用其参数（alpha 序列、半径序列、seed、色值、GROUND_Y / light_pos）作为视觉基线，把同类效果外提到独立层，不重造口径 |
| 4 | **功能互补** | 占位层继续承担 9 层视差背景 + 实体 + UI 的 M0 构图兜底；FX 栈只负责叠加在真实 3D 画面之上的光效，两者可同时存在、互不覆盖 |
| 5 | **退出独立** | 占位层按 `scene_integration.md` §4 #4 / `hd2d_placeholder_attach.gd::detach()` 在 ComfyUI 正式 spritesheet 接入后退出；FX 栈是纯 2D、不依赖背景层，**可独立保留**——这比把 FX 焊死在占位层里更可持续 |

---

## 3. 逐项方案

> 共用冻结口径（引用 `ART-SPEC-FINAL.md` §2.2、`HD-2D视觉规范.md` §2 / §7 / §10、`hd2d_placeholder.gd`）：逻辑缓冲 `640×360` + `integer_scale=2` + Nearest；`warm_gold_key`（`#FFF0C2` / `#FFD27A` / `#F0A94C` / `#C97A2E` / `#8A5A22`）是**唯一允许过 bloom 阈的色族**，冷夜雾区不得过阈；实体坐标 `round()` 到整数、禁亚像素；光尘 seed `PLACEHOLDER_SEED=20261108`；`light_pos=(452,92)`、`GROUND_Y=250`、`BUFFER_W=640`。

### 3.1 体积光 God Rays → `Polygon2D` + `Line2D`（`FXGodRays`，layer=2）

- **原语选择**：`Polygon2D` ×4（每束一个节点）作扇形光束主体；`Line2D` ×1~2 作光束中心高光带。
  - `Polygon2D` 优于 `_draw()` 之处：支持 `vertex_colors`（逐顶点颜色），**一个多边形即可做「光源端亮 → 地面端透明」渐隐**，不必像 `_draw()` 那样用 4 层低 alpha 叠加近似，减少 draw call。
  - `Line2D` 的 `gradient`（`Gradient` 资源）+ `width_curve`（`Curve`）可做沿长度渐隐与宽度收束，补出光束锐利核心。
- **关键参数**（沿用 `_pass_05_fx_back` / `HD-2D视觉规范.md` §7）：

| 参数 | 值 | 来源 |
|---|---|---|
| 光束层数 | 4（移动档可降 2，见 §4.3） | 脚本 `godray_alpha` 4 元素 |
| 顶点 | `light_pos=(452,92)` | `@export light_pos` |
| 底边 spread | `40 + i*46` → 40 / 86 / 132 / 178 | 脚本 `spread` |
| 底边 y | `GROUND_Y+30 = 280` | 脚本 `bottom` |
| 填色 / alpha | `#FFD27A` / `[0.18,0.12,0.07,0.04]` | 脚本 / 规范 §10 |
| 规范级参数 | samples 48（32~64）、density 0.75（0.6~0.9）、decay 0.95、weight 0.40（0.3~0.5）、exposure 0.32（0.25~0.4） | `HD-2D视觉规范.md` §7 |
| 视差系数 | `P_FX_BACK = 0.45` | 脚本视差表 |
| 混合 | `CanvasItemMaterial` 的 Add 混合（见 §3.6）；退化方案为低 alpha 多次叠加 | 脚本注释 |

- **约束**：只在暖金主光方向出现；冷雾区不得出现金色光束；不得盖住角色剪影 → 低 layer(2) 且 alpha ≤ 0.18。

### 3.2 光尘 Motes → `Node2D._draw()` + `draw_circle()`（`FXLayer`，layer=10，复用既有 `LightDust`）

- **原语选择**：`draw_circle()` ×40~120（1 个 `_draw()` 节点内批量）；**不**用 `PointLight2D`（大量点光源开销高，且本后端无 2D 光照后处理增益）。既有 `FXLayer/LightDust`（Node2D，`visible=false`）是天然落点 → 建议**启用并挂一段 `_draw()` 光尘脚本**；远景 / 近景两组可用两个子节点分别控制 `visible`。
- **关键参数**（沿用 `_build_motes()` / `HD-2D视觉规范.md` §7）：

| 参数 | 远景（冷白） | 近景（暖金） |
|---|---|---|
| 数量 | 48（桌面 40~120） | 32 |
| 色 / alpha | `#BFD0EA` / 0.25 | `#FFD27A` / 0.45 |
| 尺寸 | 1~3 px（`rng.randf_range(1.0, 3.0)`） | 同左 |
| 上飘速度 | 2~6 px/s | 同左 |
| 横摆 | `sin(t*freq+phase)*3`，freq `TAU/4 ~ TAU/2`（周期 2~4 s） | 同左 |
| 循环 | `fposmod(y0 - speed*t, BUFFER_H)` | 同左 |
| 视差 | `P_FX_BACK=0.45` | `P_FX_FRONT=1.00` |
| seed | `20261108`（确定性） | 同左 |
| 坐标 | `round()` 到整数 | 同左 |
| 生命周期 | 4~8 s（规范），脚本用 `fposmod` 循环等价 | 同左 |

- **刷新**：`_process()` → `queue_redraw()`（与占位脚本一致）；移动档节流见 §4.3。
- **纵深说明**：由于 2D 层无法插到 3D 角色之下（§6 #2），远景 / 近景的纵深靠**色温（冷白 vs 暖金）+ 尺寸 + alpha** 差异近似，而非严格前后分层；两组同处 layer=10，用子节点绘制顺序区分。
- **约束**：不得密集到遮挡判定信息；不得用线性过滤放大（Nearest）。

### 3.3 湿地倒影 → `_draw()` + `draw_rect()` 垂直镜像（`FXReflection`，layer=1）

- **原语选择**：`Node2D._draw()` 逐像素块 `draw_rect()` 垂直镜像（沿用脚本 step6，最贴合「倒影必须降采样到与主体同一像素网格」）；可选升级为「当前帧 `TextureRect` 垂直翻转 + `GradientTexture2D` 渐隐遮罩」，但逐帧波纹仍需 `_draw()` / `ShaderMaterial`，**本方案以沿用 `_draw()` 为主**。既有 `WetReflection`（Node3D）可作屏幕投影锚点参考。
- **关键参数**（沿用 `_pass_06_reflection` / `HD-2D视觉规范.md` §7）：

| 参数 | 值 |
|---|---|
| 镜像公式 | `y_mirror = 2*GROUND_Y - sy - 1`（脚底 Y 对齐） |
| 垂直压缩 | `0.70`（`y_ref = GROUND_Y + (y_mirror-GROUND_Y)*0.70`，范围 0.6~0.8） |
| 强度 / alpha | `0.35`（范围 0.25~0.45） |
| 波纹扰动 | `sin(t + y_ref)*0.03*BUFFER_W` 逐行横向错位（范围 0.02~0.06） |
| 取色 | 实体色板索引 `_palette[idx]`（32×32 阵列） |
| 混合 | 普通 Mix（**非** Add；倒影是半透明减色） |
| 视差 | `P_NEAR = 0.70`（挂 `bg_3_near` 湿地区） |
| 菲涅尔 | 规范列为参数；近似版以「湿地 mask 区域 + 统一 alpha 0.35」代替，不臆造曲线 |

- **约束**：与角色脚底对齐、不得半像素错位；干地无倒影；只在湿地 mask 区域有效。

### 3.4 Bloom / Glow → 同心圆 / `GradientTexture2D` 渐变（`FXBloom`，layer=11）★ 核心替代项

> 这是 `gl_compatibility` 不支持 `Environment.glow` 后最需要替代的一项。`quality_preset_*.tres` 里的 `glow_enabled` 语义必须从「3D 后处理 glow」迁移为「2D CanvasLayer bloom 近似层的可见性开关」——这是本方案与既有双档配置的关键衔接点。

- **原语选择（两选一或叠加）**：
  - **A（沿用基线）**：`Node2D._draw()` `draw_circle()` ×5 同心圆（半径 `[4,8,14,22,32]`、alpha `[0.20,0.12,0.07,0.04,0.02]`）——与占位脚本 step8 完全一致，零新依赖。
  - **B（更省，推荐移动档）**：`TextureRect` + `GradientTexture2D`（径向渐变，`Gradient` 从 `#FFF0C2` 高中心到透明）做单张静态光晕，零逐帧重绘。**`ColorRect` 本身只能填纯色**，要做渐变须挂 2D `ShaderMaterial`，或改用 `TextureRect` + `GradientTexture2D`（如实说明，不臆造 `ColorRect` 渐变 API）。
  - 两者都只在 `light_pos` 与暖金高光色族处放置；**冷夜雾区不放置任何光晕**（几何近似 `threshold=0.95`）。
- **关键参数**（`HD-2D视觉规范.md` §7 / §10）：

| 参数 | 值 |
|---|---|
| 过阈 threshold | 0.95（0.85~1.05）；几何近似：仅 `warm_gold_key`（`#FFF0C2` / `#FFD27A`）放行 |
| intensity | 0.50（0.35~0.7） |
| 半径 | 6（4~8）；近似序列 `[4,8,14,22,32]` |
| 色 | `#FFD27A`，核心 `#FFF0C2`（L8 96%） |
| 混合 | Add（`CanvasItemMaterial`）或低 alpha 叠加 |
| 视差 | `P_FX_FRONT = 1.00` |
| 冷雾区 | 亮度不得过阈（否则冷暖对比失效） |

- **呼吸动画**：可选 `intensity` 随 `Time.get_ticks_msec()` 轻微正弦（脚本 step8 未做，登记为可选增强，非基线）。
- **不宣称**：这是 2D 几何 / 加色近似，**不是**真正的 HDR 亮度阈值 bloom 后处理。

### 3.5 `CanvasModulate` 的定位（`FXModulate`，layer=12，可选 / 默认关）

- `CanvasModulate` 给它**所在 canvas 的全部下层 `CanvasItem`** 乘一个颜色（常做昼夜 / 受击闪白）。本方案用途：作为「暖金主光 × 冷夜雾」的**整体氛围调制**——放一个接近白色的暖调（设计建议 `Color(1.0, 0.98, 0.94)`）轻微提暖，强化冷暖对比。
- **必须限域**：只能放在 **SubViewport 内部**的 `FXModulate` 层（layer=12），避免乘到主树 UI / 占位层；`CanvasModulate` 影响同 canvas 所有内容，误放到主树会污染 UI 与金线底板。
- **代价 / 风险**：全屏乘色 pass + 易误伤 → **桌面档可选、默认关；移动档强制关**（§4.3）。属增强项，不是四项必需 FX 的组成部分。
- 色值属**设计建议，非冻结口径**；落地前须由 Rank-1 结合 R14 已落盘的暖金 ambient（`Color(1,0.82,0.6)`）与冷雾（`Color(0.4,0.55,0.72)`）裁决，避免叠加过曝。

### 3.6 Add 混合与 `gl_compatibility` 原语可用性

| 事实 | 说明 |
|---|---|
| 不可用 | `Environment.glow` / 3D 体积雾 / SSR / SSAO / DOF 等屏幕空间后处理（Compatibility 渲染器） |
| 可用 | 全部 `CanvasItem` 2D 绘制：`_draw()` 的 `draw_*`、`Polygon2D`、`Line2D`、`TextureRect` / `ColorRect`、`CanvasModulate`、`CanvasItemMaterial` 混合 |
| `_draw()` 局限 | 单次 `draw_*` 无法逐调用设 Add 混合 → 占位脚本用「低 alpha 多次叠加」近似 |
| 独立节点优势 | `Polygon2D` / `Line2D` / `TextureRect` 可设 `material = CanvasItemMaterial`，用 Add 混合（`BLEND_MODE_ADD`）→ 更接近 HD-2D 加色光效，且 `vertex_colors` / `gradient` 一次成渐隐 |
| **引擎常量核对** | `CanvasItemMaterial.BLEND_MODE_ADD` 等枚举名 / 值，落地时须用 `ClassDB.class_get_integer_constant_list("CanvasItemMaterial")` 真跑核对（沿用 `DONE-R14.md` §2.1「`TEXTURE_REPEAT_ENABLED` 臆造致 Parse Error」教训）；**本方案不写死、不臆造常量值** |
| `ColorRect` 渐变 | `ColorRect` 仅纯色；径向 / 线性渐变须 `TextureRect` + `GradientTexture2D` 或 `ColorRect` + 2D `ShaderMaterial`（如实说明，不臆造 API） |

---

## 4. 性能预算

### 4.1 基线（既有实测，非本轮）

`capture/CAPTURE-REPORT.md`：1280×720 @30fps、12 帧静态，GPU 平均 **0.37 ms/帧**、CPU **0.49 ms/帧**（RTX 4060 Ti / OpenGL 3.3）。**该基线不含任何 FX**，不能当作本方案的实测结果。

### 4.2 既有双档冻结口径（权威件，引用不改）

`godot/data/render/quality_preset_desktop.tres` / `quality_preset_mobile.tres` 与 `godot/scripts/core/render_profiles.gd`、`render_profiles.tres` 已冻结「桌面 / 移动各开关哪项」：

| FX 项 | `quality_preset` 字段 | 桌面档 | 移动档 | `render_profiles.tres` 布尔 |
|---|---|---|---|---|
| 体积光 | `volumetric_fog_enabled` | **true** | **false** | `desktop_volumetric=true` / `mobile=false` |
| 光尘 | `dust_particle_cap` | **120** | **0** | `desktop_motes=true` / `mobile=false` |
| 湿地倒影 | `wet_reflection_enabled` | **true** | **false** | `desktop_wet_reflection=true` / `mobile=false` |
| bloom | `glow_enabled` | **true** | **false** | `desktop_bloom=true` / `mobile=false` |

其余冻结约束：桌面 640×360 / 60fps=16.67 ms / 1536 MB / shadow 4096；移动 480×270 / 30fps=33.33 ms / 512 MB / shadow 1024；两档 `integer_upscale_factor=2`、后端均 `gl_compatibility`。

> **结论（直接回答派单的「各开关哪项」）**：按既有冻结口径，**桌面档四项全开、移动档四项全关**。本方案不改这两份 `.tres`（越界），只把 `glow_enabled` / `volumetric_fog_enabled` 的语义从「3D 后处理」桥接到「2D FX CanvasLayer 的 `visible`」。

### 4.3 逐项开销与「移动档降级而非全关」建议（**待裁决，不擅改冻结值**）

| FX 项 | 桌面档（冻结：开） | 逐帧开销特征 | 移动档（冻结：关） | **建议的降级替代（待裁决）** |
|---|---|---|---|---|
| 体积光 | 4 层 `Polygon2D` + Add | 静态几何、仅 `light_pos` 变时重绘 | 关 | **保留 2 层**（合并 spread），开销近乎为零 |
| 光尘 | 80 粒 `draw_circle()`、每帧 `queue_redraw()` | **主要 CPU 来源**（80 次 draw / 帧） | 关 | 仅近景、减到 16~24 粒；刷新节流到 30fps |
| 湿地倒影 | 逐像素块镜像 + 逐行波纹 | **最重**（可达约 1024 `draw_rect` / 帧 + 逐帧波纹） | 关 | **保持关**；或改静态低分辨率镜像贴图、去逐帧波纹 |
| bloom | 5 层同心圆 / 渐变 | 静态、开销低 | 关 | **保留 3 层静态 `GradientTexture2D`**（零逐帧重绘），保住「暖金发光」观感 |
| `CanvasModulate` | 可选、默认关 | 全屏乘色 pass + 易误伤 UI | 强制关 | 保持关 |

> 理由：本方案四项全是 **2D 程序化绘制**，开销远低于被 `gl_compatibility` 禁用的 3D 后处理；移动档「全关」是当年按 3D 后处理成本定的，2D 近似下可低成本保留体积光 / bloom 的观感。但**这是方案建议，不是本轮改动**：`render_profiles.tres` / `quality_preset_mobile.tres` 归 Rank-1 装配权，须总指挥裁决后方可调整，本轮只登记、不写、不改。

### 4.4 分档落地建议（给 Rank-1，不越界执行）

- FX 各 CanvasLayer 的 `_ready()` 读取 `SceneRouter` 当前档（`quality_preset_*.tres` 既有管线）或 `RenderProfiles` 资源，逐层设 `visible`：`FXGodRays.visible = volumetric_fog_enabled`、`LightDust.visible = (dust_particle_cap > 0)`、`FXReflection.visible = wet_reflection_enabled`、`FXBloom.visible = glow_enabled`、`FXModulate.visible = false`。
- 光尘数量取 `dust_particle_cap`（桌面 120 / 移动 0）作为上限钳制，与既有字段对齐，不新增口径。
- 静态层（体积光 / bloom 渐变）用「仅在 `light_pos` 或档位变化时 `queue_redraw()`」代替每帧重绘；只有光尘 / 倒影波纹需要逐帧刷新。
- 目标帧时间沿用冻结值：桌面 ≤16.67 ms、移动 ≤33.33 ms；FX 增量预算建议桌面 ≤1.5 ms / 移动 ≤0.5 ms（**设计目标，非本轮实测**，运行期由 Rank-1 抓帧复核）。

---

## 5. 落地步骤建议（仅供方案，本轮不执行）

1. Rank-1 在 `courtyard.tscn`（本轮其独占）于 `SubViewport` 内新增 `FXReflection(1)` / `FXGodRays(2)` / `FXBloom(11)` / `FXModulate(12)` 四个 `CanvasLayer`，保留既有 `FXLayer(10)` 与 `HD2DPlaceholderLayer(-10)` 不动。
2. 启用 `FXLayer/LightDust`（`visible=true`）并挂光尘 `_draw()` 脚本；各新增层挂对应 FX 脚本（参数取 §3 表）。
3. 脚本内只 `load()` 工程内既有 `.gd` / 色板常量，零 PNG / 零插件 / 零网络。
4. 分档接线按 §4.4；`CanvasItemMaterial` 枚举用 `ClassDB` 真跑核对后再写常量。
5. 三段门禁 + 抓帧复核（沿用 R14 口径），确认四项可见、冷雾区不过阈、暖金 × 冷雾对比增强。
6. 占位层 `detach()` 退出后，FX 栈按 §2.2 #5 独立保留。

---

## 6. 约束、未验证项与边界（如实登记）

| # | 项 | 性质 |
|---|---|---|
| 1 | **只交付方案，未实现** | 本轮未写任何 `.gd`、未改 `courtyard.tscn`、未真跑、未抓帧、未验收画面；所有参数均为沿用冻结件的设计值 |
| 2 | 2D / 3D 遮挡固有限制 | SubViewport 内所有 2D CanvasLayer 天然覆盖在 3D 内容之上，无法把 2D 倒影插到 3D 角色「之下」；本方案用「半透明镜像 + 仅湿地区 + alpha 0.35」近似，真实遮挡顺序仍待 Rank-1 结合场景裁决（`scene_integration.md` §4 #3 既有登记） |
| 3 | 引擎枚举未核对 | `CanvasItemMaterial.BLEND_MODE_ADD` 等须 `ClassDB` 真跑；沿用 `DONE-R14.md` §2.1 教训，不臆造 |
| 4 | 性能预算是设计目标 | §4.4 的 1.5 / 0.5 ms 非实测；`CAPTURE-REPORT` 0.37 / 0.49 ms 是不含 FX 的静态基线，不冒充本方案结果 |
| 5 | 双档口径未改 | 桌面全开 / 移动全关为既有冻结；「移动降级」只是建议，须总指挥裁决，本轮未写 `.tres` |
| 6 | `CanvasModulate` 与 `ColorRect` 渐变 | 已如实说明作用范围与 API 边界（非必要项 / 需 `TextureRect` + `GradientTexture2D` 或 shader） |
| 7 | 不宣称实现后处理 | 只给 2D 几何 / 加色近似，不宣称「已实现 Environment glow / 真 bloom / 真体积光」 |
| 8 | 长期项 | `128bit` 歧义（`ART-SPEC-FINAL.md` §6）、ComfyUI 正式素材接入、出图长期阻塞，沿用既有登记，不自行改 |
| 9 | 回执 | 按 `task_id` 写 `command_center/ai/4/outbox/`，中枢实时消费后见 `dispatcher/receipts/`（`DONE-R14.md` §2.6 既有正常流程） |

---

## 7. 合规声明

- 本轮**只写** `teamwork/Rank-4/HD2D-FX-PLAN.md`、`teamwork/Rank-4/DONE-R15.md` 与回执例外 `teamwork/command_center/ai/4/outbox/cmd-20261109-083628-786-A4.json`。
- **未写**：`godot/scripts/render/hd2d_placeholder.gd`（不改运行中脚本）、`godot/scenes/courtyard.tscn`（Rank-1 本轮独占，仅只读核对）、任何其它 `.gd` / `.tres` / `.import`、`00-群聊总线.md`（开工只读一次、未追加）、总纲 / 契约 / 任务书 / 其它 Rank 工位；未自行 `git commit` / `git push`。
- 零付费 / 零外部生成服务 / 零外部素材增量 / 零插件；**ComfyUI 仍是主美术路线**，本方案是 2D 程序化零依赖兜底，不取代主路线、不宣称已能出图；中文 UTF-8；不伪造输出 / 不臆造引擎常量 / 不夸大画面已达标。
