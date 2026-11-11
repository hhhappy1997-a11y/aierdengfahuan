# TECHNICAL-ART-DEPTH-v060.md · gl_compatibility 下真 3D 光效可行性与零付费替代方案评估

> 派单 `cmd-20261111-095602-831-A4` · `[ROUND=R28]` · Rank-4（美术管线与工具链）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable）
> **本文只是评估文档：不改任何工程渲染件、不新增素材、不启 GPU job、不谎称已实现真 3D 光效。**
> 本轮未写 `courtyard.tscn` / `project.godot` / `hd2d_fx.gd` / `hd2d_parallax.gd` / 任何 `.tres`；下列方案均为「可落地建议 + 优先级」，实现与否交由总指挥/后续派单决定。
> 依据：工程内真跑配置（§1）、R22~R28 历史实测、`capture/V060-RUNTIME-REVIEW.md` 三帧目视、Godot 4.x Compatibility(OpenGL) 后端能力边界（凡涉及后端支持度的判断，均标注「需真跑验证」，不把推断当实测）。

---

## 0. 一句话结论

在 `rendering_method="gl_compatibility"` 下，**真 3D 景深 / 真体积光 / 真湿地倒影 / 真 bloom 当前都不可直接依赖**：本工程 `Environment` 只启用了传统深度雾，`glow` 历史显式关闭且未验证通过，体积雾 / DoF / SSR 属 Compatibility 后端能力缺口或需切换渲染后端（代价高、回归风险大）。**可落地的零付费路径是继续强化既有 2D `draw_*` 近似层 + 分层视差/伪景深 + 传统深度雾**，按 P0→P3 渐进；切换渲染后端（P3）列为不推荐。

---

## 1. 工程渲染基线（实测，非推断）

| 项 | 实测值 / 出处 |
|---|---|
| 渲染后端 | `project.godot:145-146` `renderer/rendering_method="gl_compatibility"`、`...mobile="gl_compatibility"`（桌面与移动同一 OpenGL Compatibility 后端） |
| 窗口 / 缓冲 | `1280×720`；低分辨率缓冲 `640×360`(desktop) / `480×270`(mobile)，`integer_upscale_factor=2`（`quality_preset_*.tres`） |
| MSAA | `project.godot:151-152` `msaa_2d=0` / `msaa_3d=0` |
| WorldEnvironment | `courtyard.tscn:39-48` `Environment_e34af`：`background_mode=1`、`ambient_light_source=2`、`tonemap_mode=2`、**`fog_enabled=true` `fog_density=0.02` `fog_light_color=(0.12,0.22,0.4)`**；**无** `glow_*` / `volumetric_fog_*` / `ssr_*` / `dof_*` 任何属性 |
| glow 历史 | `build_courtyard.gd:201` **`env.glow_enabled = false`** —— 装配脚本显式关闭，工程从未在 `gl_compatibility` 下真跑验证过开启效果 |
| 3D 结构 | `SubViewportContainer/SubViewport` 内放 3D 世界（相机/光/地形/角色 billboard），外部 `CanvasLayer` 叠 HUD；`WetReflection` 节点 `visible=false`（R27 隐藏） |
| 「光效」真实实现 | `hd2d_fx.gd` 的 `FXReflection / FXGodRays / FXMotes / FXBloom` 四节点全部是 **`CanvasItem._draw()` 2D 近似**：倒影 `draw_rect()` 垂直镜像色块、体积光 `draw_colored_polygon()×6 + draw_line()`、光尘 `draw_circle()`、bloom `draw_circle()` 同心圆（见 `hd2d_fx.gd:26-29, 328-402`） |
| 「光效」开关真身 | `quality_preset_*.tres` 的 `volumetric_fog_enabled / glow_enabled / wet_reflection_enabled` 与 `render_profiles.tres` 的 `desktop_volumetric / desktop_bloom / desktop_wet_reflection` 是**自定义 `QualityPreset`/`RenderProfiles` 字段，经 `render_profiles.gd` 映射到上述 2D FX 节点的开关**（desktop 四项全开 / mobile 四项全关），**不是** Godot `Environment` 的 3D 属性 |

> 关键澄清：工程口中的「体积光 / bloom / 湿地倒影」目前**全部是 2D `draw_*` 绘制的伪光效**，不是真 3D 光效。本轮三帧目视也印证：desktop 段可见暖金光柱/光池，mobile 段四项全关即消失。`capture/V060-RUNTIME-REVIEW.md §4.5` 据此把「HD-2D 全绿」如实写为未达。

---

## 2. 四项真 3D 光效逐项可行性评估

### 2.1 真 3D 景深（Depth of Field / DoF）

- **Godot 4 机制**：由 `CameraAttributesPractical` / `CameraAttributesPhysical` 的 `dof_blur_near/far`、`dof_far_distance` 等经相机后处理实现；本质是屏幕空间模糊，需深度缓冲与多 pass 后处理。
- **gl_compatibility 支持度**：Compatibility(OpenGL) 后端对相机后处理 DoF 的支持不完整/缺失（无 Forward+ 的 depth prepass + compute 后处理链）。**结论：不可直接依赖**（需真跑验证：`Camera3D.attributes = CameraAttributesPractical.new()` 后置 `dof_blur_far_enabled=true`，录屏观察远景是否真的失焦；本轮未跑，不下断言）。
- **工程现状**：`Camera3D` 只用静态 `fov=40`、`pos=(0,8,15)`、`rot=(-20,0,0)`；R22 实测 `--script` 模式对相机写任何属性都会破坏 `SubViewport` 的 3D 注册导致主体消失，故相机仅静态、脚本只读。
- **可行性**：低。即便后端支持，也会与「R22 相机只读」「整数放大 `integer_upscale_factor=2`」「低分辨率缓冲 640×360」冲突——模糊在低分辨率缓冲上会被放大成块状，且 `msaa_3d=0` 无抗锯齿缓冲可用。

### 2.2 体积光 / `volumetric_fog`（是否可用）

- **Godot 4 机制**：`Environment.volumetric_fog_enabled` + `volumetric_fog_density/albedo/length` + `fog_volume` 体积雾，需 Froxel 体积纹理与 compute/3D 纹理步进，属 Forward+/Mobile 后端能力。
- **gl_compatibility 支持度**：**Compatibility(OpenGL) 后端不支持 volumetric_fog**（Godot 4.x 官方能力边界：体积雾在 Compatibility 渲染器不可用；开启后通常无效果或产生告警）。**结论：当前后端不可用**，需真跑验证（在 `courtyard.tscn` 的 `Environment` 上临时加 `volumetric_fog_enabled=true` 跑一段录屏看是否有 SCRIPT ERROR / 画面变化；本轮未改渲染件，未跑，不把「不可用」当本工程实测）。
- **可用替代**：工程**已启用传统 `fog_enabled=true` 深度雾**（`fog_density=0.02`），这是 Compatibility 后端支持的、零成本的近远层次手段；`hd2d_parallax.gd` 又按波次改 2D 雾带密度/色（冷蓝 → 深紫 → 暖紫）。两者叠加是当前「伪体积感」的全部来源。
- **若强行要真体积雾**：唯一路径是切 `rendering_method` 到 `forward_plus`（Vulkan），代价见 §4，列 P3 不推荐。

### 2.3 湿地倒影（SSR / Planar Reflection）

- **Godot 4 机制**：`Environment.ssr_enabled`（屏幕空间反射）或另起 `Camera3D` + `SubViewport` 做平面反射（Planar Reflection），或 `ReflectionProbe`。
- **gl_compatibility 支持度**：SSR 属 Forward+ 后处理，Compatibility 后端不支持；`ReflectionProbe` 在 Compatibility 下能力受限；Planar 反射需第二次场景渲染，Compatibility 下可行但代价是「每帧多一次 3D 渲染」。
- **工程现状**：`WetReflection` 节点自 R27 起 `visible=false`；画面里的「倒影」是 `hd2d_fx.gd` 的 `draw_rect()` 垂直镜像色块（带 `reflection_squash=0.85` / `alpha=0.42` / 逐行波纹），逐帧 2D 重绘，零 GPU job。
- **可行性**：Planar 反射理论上可做，但会与 §3 的 SubViewport 分层代价叠加，且本工程是 `AnimatedSprite3D` billboard，镜像反射对 billboard 不成立（会穿帮）。**结论：不建议做真反射，继续用 2D 镜像近似**。

### 2.4 bloom / `Environment.glow`（历史实测专题）

- **题设与工程史实**：任务单明确「Environment glow 历史实测不支持」；工程内 `build_courtyard.gd:201` 亦 `env.glow_enabled = false` 显式关闭。R27/R28 录屏中「暖金 bloom」是 `hd2d_fx.gd:397-402` 的 `draw_circle()` 同心圆 + 核心过阈，不是 `Environment.glow`。
- **gl_compatibility 支持度**：Compatibility 后端对 `Environment.glow` 的支持有版本/配置差异（依赖 half-res 后处理链、`glow_blend_mode`、`glow_hdr_threshold` 等），且本工程 `tonemap_mode=2`、`msaa_3d=0`、低分辨率整数放大缓冲会放大 glow 的块状伪影。**结论：不直接依赖**；若要验证需单独真跑（临时在 Environment 上置 `glow_enabled=true` 并录屏，检查 SCRIPT ERROR=0 + 目视 + 帧时间），本轮未跑、未改渲染件。
- **判定**：`glow` 属「历史实测不支持/未验证通过」，**不列为可落地方案**；bloom 继续由 2D `draw_circle()` 近似承担。

---

## 3. SubViewport 分层方案的代价（专题）

设想：为做「近/中/远分层景深」「真倒影」「分层泛光」，再加 2~3 个 `SubViewport`（不同 `Camera3D`、不同 `WorldEnvironment`、不同渲染层），最后合成到主画面。工程**已经**用了一层 `SubViewportContainer/SubViewport` 承载 3D 世界，再加层并非从零开始，但代价明确：

| 维度 | 代价 / 风险 | 本工程实证 |
|---|---|---|
| 显存 / 带宽 | 每多一个 1280×720（或 640×360）render target，多一份 color+depth 纹理；`quality_preset_desktop.tres` 内存预算 `memory_limit_mb=1536`、移动档 `512`，多 SubViewport 对移动档是硬约束 | — |
| Draw call / 帧时间 | 每个 SubViewport 每帧独立跑一遍 3D 渲染（地形 4×4 砖平铺、Boss/玩家 billboard、灯光），N 层 ≈ N 倍 3D draw call；桌面档 `target_frame_time_ms=16.67` 无余量 | — |
| 录制（Movie Maker） | `--write-movie` 只录主视口链；R22 实测「脚本 `instantiate()+add_child()` 加载场景时 SubViewport 的 3D 世界不进入录制」，必须靠命令行位置参数主场景才完整渲染。多层 SubViewport 会放大这一录制不确定性 | `presentation.gd` 头注 ① |
| 相机 / 分层同步 | R22 实测 `--script` 模式对 `Camera3D` 写任何属性（含 `current`/transform/deferred）都会破坏 3D 注册导致主体消失；多层相机必须全静态、同步一致 | `presentation.gd` 头注 ② |
| 输入穿透 | 多层 `SubViewport` 需显式配 `SubViewportContainer` 的鼠标/输入转发；当前 HUD `CanvasLayer` 在 SubViewport **内部**，输入路由已耦合一层，再加层易与 `hud._unhandled_input` / `EncounterDirector._unhandled_input` 抢输入 | `courtyard.tscn:174-178` |
| 画质档缩放 | `quality_settings.set_quality(low/high)` 改 `SubViewport` 低分辨率 / shrink；**本轮实证**：段 B `low/mobile` 下 `SubViewport` 缩放使 `Hud/GraceShopLabel` 兑换面板文字在画面中不可清晰辨认（`capture/r28_panel_mid.png`），而段 C `high/desktop` 清晰（`r28_panel_tail.png`）。分层越多，这类「不同层不同缩放 → 叠合错位」越难控 | `V060-RUNTIME-REVIEW.md §4.2 / §4.5` |
| 回归风险 | 场景 `[node` 数变化会触发 `verify_wave_runtime_v040` 的 `courtyard_node_count` 断言（本轮已因 Rank-1 新增 3 教学节点出现 36/1 FAILED）；加 SubViewport 必然再改场景节点数，牵动既有 PASS 基线 | `capture/r28_verify_wave_runtime_v040.log` |

**结论**：SubViewport 分层能换来「层次」，但在本工程的 Compatibility + 低分辨率整数放大 + 既有回归耦合下，**代价（帧时间、录制确定性、输入、缩放错位、断言回归）大于收益**，不列为近期方案。

---

## 4. 切换渲染后端（`forward_plus`）的代价（为什么列 P3 不推荐）

真 3D 体积雾 / DoF / SSR / glow 的「正统」解法是把 `renderer/rendering_method` 从 `gl_compatibility` 换成 `forward_plus`（Vulkan）。零付费（无需购买素材/服务），但工程代价高：
1. 全工程回归（`47/34/20/45/53/58/650` + v060 教学 181 PASS）需在 Vulkan 后端重跑，R22 相机/SubViewport 录制踩坑结论可能全部失效；
2. Android 导出兼容、`msaa_*`、低分辨率整数放大、`QualityPreset` 双档策略需重校；
3. `hd2d_fx.gd` 的 2D 近似层与新 3D 光效叠合会重复上光，需重新定调；
4. 本轮公共契约「零 GPU job、三段门禁不回退」下，属高回归风险动作。
→ **不推荐本轮或近期执行**，仅作为「若产品明确要求真 3D 光效」时的长期选项登记。

---

## 5. 零付费可落地替代方案与优先级

全部满足：零付费、零外部素材服务、零新增 GPU job、只用工程既有节点/2D 绘制/程序化参数、不改渲染后端。所有新数值标 `[PLACEHOLDER]` 待试玩校准，并写 rationale。

### P0 · 立即（零改动，只定调与登记）
- **承认现状、停止把 2D 近似叫「真 3D 光效」**：`hd2d_fx.gd` 四项（倒影/体积光/光尘/bloom）+ `hd2d_parallax.gd` 三波色带 + `Environment.fog_enabled` 传统深度雾，共同构成当前「伪景深/伪体积/伪倒影/伪 bloom」。文档层面把「HD-2D 全绿」口径写清（`V060-RUNTIME-REVIEW.md §4.5` 已写未达）。
- **rationale**：零风险、零成本，先消除「已实现真 3D」的误判，符合本轮「不谎称已实现」。

### P1 · 低风险（只调既有参数/2D `_draw()`，不动场景节点与后端）
- **伪景深分层**：远景（`BackdropFar / BackdropMid / ParallaxBackdrop`）按深度降饱和 / 降对比 / 叠冷色雾 alpha；近景玩家与 Boss 保持高对比。`[PLACEHOLDER]` 远景 alpha `0.15~0.35` 随波次递进（rationale：`hd2d_parallax.gd` 已有按 `wave_index` 的雾密度/色带查表，复用同一驱动，零新增节点）。
- **分层体积光锥**：把现有 `FXGodRays` 的 `draw_colored_polygon()×6` 按「远/中/近」分 2~3 组不同 alpha 与宽度，配合 `fog_density` 做近浓远淡。`[PLACEHOLDER]` 组数 3、alpha 梯度 `0.10/0.16/0.24`（rationale：纯 2D 绘制，零 GPU job，视觉上比单层光锥更像纵深体积光）。
- **湿地倒影加强**：在 `FXReflection` 的 `draw_rect()` 镜像色块上叠一层低 alpha 冷色渐变 + 随波次变化的波纹幅度，模拟「湿」而不做真反射。`[PLACEHOLDER]` 冷色 alpha `0.08`（rationale：现有 `reflection_ripple=0.035` / `alpha=0.42` 参数表可复用）。
- **代价**：仅改 `hd2d_fx.gd` / `hd2d_parallax.gd` 的绘制参数（**这两支不属本轮授权，需后续派单**），零后端/场景风险，回归面最小。

### P2 · 中风险（需真跑评估帧时间，仍零付费）
- **全屏后处理 shader（`BackBufferCopy` + `ColorRect` shader）**：在 `CanvasLayer` 上做一次 screen-reading，实现「按屏幕 Y/亮度」的轻景深模糊 + 泛光扩散 + 倒影扰动，一 pass 覆盖三项观感。零外部素材、不改 3D 后端。
  - **代价/验收**：增加一次全屏采样，须在桌面档 `target_frame_time_ms=16.67` 与移动档 `33.33` 预算内真跑 `perframe` 日志确认；低分辨率整数放大下模糊半径需按 `integer_upscale_factor=2` 缩放；须先目视再接入、三段门禁 `SCRIPT ERROR=0`、全 PASS 不回退。
  - `[PLACEHOLDER]` 模糊半径 `1.5px`（低分辨率缓冲）/ 泛光阈值 `0.75`（rationale：与现有 `FXBloom` 的「仅 warm_gold_key 过阈」口径对齐，避免全屏泛白）。
- **风险**：全屏 shader 与 `--write-movie` Movie Maker、CanvasLayer 层级（HUD layer=20/21、画质 layer=40）叠加顺序需受控，避免遮 HUD（工程已有「光尘逐粒 HUD 避让」经验可复用）。

### P3 · 不推荐（登记，不执行）
- 切 `forward_plus` 启用真 `volumetric_fog / glow / DoF / SSR`（§4）；或多 SubViewport 分层（§3）。仅当产品明确要求「真 3D 光效」且接受回归重跑时再评估。

### 优先级汇总

| 优先级 | 方案 | 零付费 | 改后端 | 改场景节点 | 回归风险 | 本轮是否执行 |
|---|---|---|---|---|---|---|
| P0 | 定调「2D 近似、全绿未达」 | 是 | 否 | 否 | 无 | **是（仅文档）** |
| P1 | 伪景深 / 分层光锥 / 倒影参数 | 是 | 否 | 否 | 低 | 否（需后续派单，脚本不属本轮授权） |
| P2 | 全屏 `BackBufferCopy` shader | 是 | 否 | 否 | 中（须真跑帧时间） | 否 |
| P3 | 切 `forward_plus` / 多 SubViewport | 是 | 是 | 是 | 高 | 否（不推荐） |

---

## 6. 验证方法与验收口径（避免「纸面达标」）

任何后续实现 P1/P2 后，按本轮同一纪律验收，不靠 clean build：
1. **先目视再接入**：先出 1~3 帧受控预览 ViewImage 通过，才改参数/接线；
2. **三段门禁**：`--headless --import` → `--headless --check-only --script res://test/presentation.gd` → `--headless --quit`，`grep SCRIPT ERROR=0`；
3. **15 秒 450 帧录屏 + MP4**：`--write-movie --fixed-fps 30 --quit-after 450`，首/中/尾三帧 ViewImage + 像素采样对比；
4. **帧时间**：P2 需 `perframe` 日志确认桌面 `≤16.67ms` / 移动 `≤33.33ms`；
5. **全 PASS 回归不回退**：`47/34/20/45/53/58/650` + v060 教学 181 PASS 复跑；
6. **零 GPU job / 零付费 / 不自行 git**（总指挥收尾）。

---

## 7. 结论与「本轮没做什么」

- **可行性结论**：`gl_compatibility` 下真 3D 景深 / 体积光 / 湿地倒影 / bloom **当前均不可直接依赖**；`Environment.glow` 历史实测/显式关闭不支持，`volumetric_fog` 属 Compatibility 后端能力缺口，SubViewport 分层与切后端代价大于收益。
- **可落地结论**：零付费路径是 P0 定调 → P1 强化既有 2D `draw_*` 近似与伪景深 →（可选）P2 一次全屏 shader；P3 不推荐。
- **本轮严格只写评估文档**：未改 `project.godot` / `courtyard.tscn` / `hd2d_fx.gd` / `hd2d_parallax.gd` / `.tres` / 任何渲染件；**未实现、未谎称实现任何真 3D 光效**；未新增 `[PLACEHOLDER]` 数值到工程代码（本文所列均为建议值，待试玩校准）。
- 未完成项与画面差距见 `capture/V060-RUNTIME-REVIEW.md §4.5 / §8`。
