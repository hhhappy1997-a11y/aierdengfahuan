# HD2D-NIGHT-R23.md · R23 夜景与景深整改 · 与《八方旅人》HD-2D 目标口径差距登记

> 命令 `cmd-20261109-133602-469-A1` · `[ROUND=R23]` · AI=1（Rank-1 引擎架构与渲染）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`）
> 工程根 `F:/Game/aierdengfahuan/godot`；抓帧 `F:/Game/aierdengfahuan/capture/r23_night_*.png`
> 判定方式：**Movie Maker 真抓帧 + ViewImage 目视回看**（用画面判断进度，非 clean build）
> 本文件按派单要求「未达全绿就写未达」：**结论 = 未达 HD-2D 全绿**（详见 §4）

---

## ① 本轮夜景 / 景深具体参数（落盘值）

### 1.1 `godot/scenes/courtyard.tscn` · `Environment_e34af`（WorldEnvironment 内嵌环境）

| 参数 | R22 值 | R23 值 | 意图 |
|---|---|---|---|
| `background_color` | `Color(0.07, 0.1, 0.16, 1)` | `Color(0.02, 0.035, 0.08, 1)` | 深蓝夜空底色（另由 2D 远景层覆盖保证） |
| `ambient_light_color` | `Color(1, 0.82, 0.6, 1)`（暖金） | `Color(0.2, 0.3, 0.52, 1)`（冷蓝） | 暖金环境光改冷夜蓝，去掉白天暖底 |
| `ambient_light_energy` | `0.8` | `0.4` | 环境光减半，画面整体压暗成夜景 |
| `fog_light_color` | `Color(0.4, 0.55, 0.72, 1)`（亮蓝） | `Color(0.12, 0.22, 0.4, 1)`（冷夜蓝） | 消除「亮蓝白天调」的雾染源 |
| `fog_density` | `0.008` | `0.02` | 冷雾 density 提升 2.5×（在 R14 温和上限 0.02 内） |
| `fog_enabled` | `true` | `true` | 不回退 |
| `tonemap_mode` | `2` | `2` | 不回退 |
| `background_mode` / `ambient_light_source` | `1` / `2` | 不变 | 不回退 |

### 1.2 `godot/scenes/courtyard.tscn` · `SunLight`（DirectionalLight3D 暖金主光）

| 参数 | R22 值 | R23 值 |
|---|---|---|
| `light_color` | `Color(1, 0.78, 0.45, 1)` | `Color(1, 0.72, 0.32, 1)`（更金） |
| `light_energy` | `1.8` | `1.5`（首版精修曾取 2.4，目视过曝后回落） |
| `shadow_enabled` | `true` | `true`（不回退） |

> 首版 `light_energy=2.4` 经 ViewImage 目视判定地面过亮、白天感残留，按「目视回看 → 迭代」闭环回落到 1.5，并叠加 2D 地面冷夜压暗。

### 1.3 新增 `godot/scripts/render/hd2d_parallax.gd`（程序化多层视差远景 · CanvasLayer _draw()）

零外部依赖（仅 `draw_rect` / `draw_colored_polygon` / `draw_circle` / `draw_line`，零 PNG / 零贴图 / 零插件 / 零云服务 / 零付费 API）：

| 层 | 参数 | 作用 |
|---|---|---|
| 深蓝夜空 | 64 条色带 `#04081A → #142B56` + 28 颗冷白星点 | 平滑景深底 |
| 远雾带 | y=28/44/60，alpha 0.06/0.08/0.10，`#7E96BF` | 山影之上的空气透视 |
| 远景山影 3 层 | base=78/90/102，amp=18/20/14，`#14294C`/`#0C1C36`/`#050D1E`，alpha 0.75/0.85/0.95，视差系数 0.06/0.14/0.26 | 深蓝剪影多层景深（如实：时间漂移近似视差，非真实相机视差） |
| 近雾带 | y=100/110，alpha 0.14/0.18 | 压山脚 + 地平线冷雾衔接 |
| 地面冷夜压暗 | 8 条渐变 `#0A1836`，alpha 0.06→0.26（越靠画面底部越浓） | 3D 暖金砖地压成冷夜暗金，砖纹保留 |
| 分层光尘 | 远景冷白 40 粒（size 0.7~1.6）+ 近景暖金 20 粒（size 1.0~2.4），seed=20261109 | 光尘分层；沿用 HUD 屏幕矩形 x<730,y<220 逐粒避让 |
| 自适应 | `draw_set_transform(scale = viewport.size / (640,360))` | low/medium/high 三档铺满、输出位置尺寸一致 |

### 1.4 `godot/scenes/hud.tscn`（low 档 HUD 面板放大修复）

`HudPanel` / `TitleLabel` 由固定 `offset_*` 改为**纯 anchor 比例布局**（`HudPanel` anchor=(0.025,0.06)-(0.40,0.26)，`TitleLabel` anchor=(0.05,0.10)-(0.37,0.22)，offset 全 0，`vertical_alignment=1`）。
根因：HUD 挂在 SubViewport 内，SubViewport 逻辑分辨率随画质档变化（low 426×240 / medium 640×360 / high 1280×720），固定 24~364 逻辑像素的面板在 low 档被相对放大到约 67% 屏宽。纯 anchor 时 rect = anchor×viewport，纹理再被拉伸到 1280×720 输出，故三档输出尺寸**完全一致**（约 480px 宽），角色始终可见。
HUD `layer=20` / `quality_settings layer=40` 原样保留、不回退。

---

## ② 真跑与目视证据

### 2.1 门禁 / 回归（最终版，9 份 `teamwork/Rank-1/r23_*.log`）

- 三段门禁：`--headless --import` / `--check-only --script`（3 份） / `--headless --quit`，EXIT 全 0
- 逐文件 `grep -E "SCRIPT ERROR|Parse Error"` **全部 0**，汇总 **SCRIPT ERROR=0**；`ERROR_TOTAL=0`
- `verify_fx_profile.gd` **34 PASS / 0 FAIL**、`verify_fx_mobile.gd` **47 PASS / 0 FAIL**（34/47 不回退）
- `verify_quality_interaction.gd` **19 PASS / 0 FAIL**（三档信号注入链路）
- 节点数 `CACHE_MODE_IGNORE` 两处真跑回读 **= 27**（R22 为 25，新增 2 个视差层节点，如实登记不冒充）
  - `[R22] LOAD ... SceneState_node_count=27 CACHE_MODE_IGNORE=true`
  - `[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=27`
  - 注：日志中「R20 登记 25」为 `quality_settings.gd` 内静态提示文本（本轮未改），非本轮回读值。

### 2.2 Movie Maker 抓帧

```
--path <root> --script res://scripts/verify_quality_interaction.gd \
  --write-movie F:/Game/aierdengfahuan/capture/r23_night_.png --fixed-fps 30
```
`13 frames at 30 FPS`，产出 `capture/r23_night_00000000.png` ~ `r23_night_00000012.png`（13 张，1280×720）+ 引擎自动音频轨 `r23_night_.wav`。最终版为**目视回看精修后重抓覆盖**（mtime 13:53），非首版帧、非改名伪帧。

### 2.3 ViewImage 目视结论（三档代表帧）

| 帧 | 档位 | 目视结论 |
|---|---|---|
| `r23_night_00000000.png` | low / mobile | 深蓝冷夜天空 + 星点 + 水平雾带 + 地平线远山剪影；地面暖金砖压暗成冷夜暗金；HUD 面板约 480px 宽、与 medium/high 一致；像素骑士完整可见；mobile 四项光效全关（无光柱），符合冻结口径 |
| `r23_night_00000005.png` | medium / desktop | 同上夜景；暖金体积光柱、近景光尘、角色脚下湿地倒影、bloom 光晕均可见；HUD 面板一致、角色可见 |
| `r23_night_00000010.png` | high / desktop | 同上夜景，山影剪影层次较首版明显；光柱/光尘/倒影最锐利；HUD 面板一致、角色可见；首版 high 档「左右双光源错位」已消除（去掉视差层独立辉光点后全场单一光源） |

**相对 R22 判定「亮蓝白天调 / 无平滑多层景深 / low 档 HUD 面板放大遮挡角色」三项：均已由画面实证改善。**

---

## ③ 与《八方旅人》HD-2D 目标口径逐项对照

| HD-2D 口径 | 本轮状态 | 依据 / 差距 |
|---|---|---|
| 深蓝夜空 + 冷夜雾 | ✅ 达成 | `background_color` 深蓝、`fog_light_color` 冷夜蓝、`fog_density 0.008→0.02`、2D 远景层深蓝渐变 + 星点 + 冷雾带；三档目视均为冷夜调，不再亮蓝白天 |
| 暖金主光与冷夜雾强对比 | 🟡 部分 | 暖金 `SunLight (1,0.72,0.32)` + 冷蓝 ambient `0.4` + 暖金体积光柱（HD2DFX）vs 冷夜天空/雾带，对比成立；但地面仍大面积暖金砖（占画面约 70%），冷夜雾向地面渗透不足，未达「暗场景 + 局部强光」的原作强度 |
| 平滑多层景深 | 🟡 部分 | 新增 3 层山影剪影 + 远/近雾带 + 64 色带天空渐变 + 8 段地面冷夜渐变，目视可见层次；但为 2D 程序化几何近似，非 3D 深度雾 / 景深模糊（DoF），山影偏几何化、缺真实远景纹理 |
| 像素精灵 vs 平滑景深 | 🟡 部分 | 像素骑士（AnimatedSprite3D 像素贴图）与平滑渐变远景形成对比；但角色是 3D 精灵节点而非纯 2D 像素合成，且景深层为程序化兜底而非美术贴图 |
| 体积光 | ✅ 保留（近似） | `hd2d_fx.gd` 6 层扇形 + 中心高光（Rank-4 独占，本轮未改）；2D `draw_colored_polygon` 近似，非引擎体积光后处理 |
| 光尘 | ✅ 保留 + 新增分层 | 既有 48 远 + 32 近光尘（Rank-4）；本轮远景层另加 40 远 + 20 近分层光尘，HUD 避让沿用 |
| 湿地倒影 | ✅ 保留（近似） | `hd2d_fx.gd` 垂直镜像色块 + 波纹 + 深度渐隐；2D 近似，非真实平面反射 |
| bloom | ✅ 保留（近似） | `hd2d_fx.gd` 同心圆 + 暖金核心；`gl_compatibility` 后端不支持 Environment glow（R13 已登记），非引擎后处理 |
| 金线深蓝 UI | ✅ 达成 | `hud.tscn` / `quality_settings.tscn` 深蓝底 + 金色 1px 边框 + 金色中文 Label 原样保留；本轮只改 HUD 面板锚点，不动配色 |
| 真实多层视差 | ❌ 未达 | 无相机输入，视差用分层时间漂移近似（脚本注释已如实声明），非随相机位移的多层视差 |

---

## ④ 结论：**未达 HD-2D 全绿**

按派单「未达全绿就写未达」：**本轮结论为「未达全绿」**。R22 三项具体判定（亮蓝白天调 / 无平滑多层景深 / low 档 HUD 放大遮挡角色）已由画面实证整改，门禁与 34/47 PASS 全部不回退；但与《八方旅人》HD-2D 的完整口径仍有下列差距，如实登记、不冒充完成：

1. **景深为 2D 程序化近似**：3 层山影 / 雾带 / 渐变均为 `_draw()` 几何绘制，非 3D 深度雾、非景深模糊（DoF）、非美术贴图远景；山影轮廓偏几何化。
2. **无真实相机视差**：视差由时间漂移近似，未接相机位移；脚本内已注明。
3. **地面白天感仍有残留**：暖金砖地大面积偏亮，冷夜雾主要停留在天空/远景，未达原作「暗场景 + 局部强光池」的对比强度。
4. **4 项光效仍是 2D 近似**：体积光/光尘/倒影/bloom 是 `hd2d_fx.gd` 的程序化绘制（Rank-4 独占，本轮不改）；`gl_compatibility` 后端不支持 Environment glow / 真实 bloom 后处理（R13 已登记）。
5. **角色为 3D `AnimatedSprite3D`**：像素贴图贴在 3D 精灵节点上，非纯 2D 像素精灵与 2D 场景合成。
6. **光源位置随画质档漂移**：`hd2d_fx.gd` 的 `LIGHT_POS=(452,92)` 为固定 640×360 逻辑坐标、不随 SubViewport 尺寸缩放（Rank-4 独占、冻结口径），故 low/medium/high 光柱横向位置不同；本轮已去掉视差层的重复辉光点、消除「双光源错位」，但无法在不动 Rank-4 脚本的前提下统一三档光源位置。
7. **零真实鼠标点击 / 真机试玩**：三档切换沿用 `Button.pressed.emit()` 信号注入（R22 已如实声明），非 `InputEventMouseButton`；未做 GUI 人工点击 / 逐帧动态试玩。

---

## ⑤ 边界与如实声明

- **未改禁写清单**：`project.godot`（mtime 11:14）、`hud.gd`（12:06）、`verify_frame_data.gd`（12:07）、`README.md`（13:46，其它 Rank 并发）、`00-协作契约.md`（13:43）、`00-汇总.md`（13:43）、`capture/CAPTURE-REPORT.md`（13:15）、`godot/assets/generated/r23/`（Rank-4 独占，13:55 由其写入 `player_idle.png`）均非本轮写入；`hd2d_fx.gd` / `hd2d_fx.tscn` 亦零改动。
- **零付费 / 零外部素材 / 零付费生成服务 / 零插件 / 零新增 autoload / 零新增 class_name**。
- **不新建只读探针 / 巡检脚本、不主动扫目录做进度巡检**：抓帧沿用 R22 既有 `verify_quality_interaction.gd` 作渲染驱动（非只读探针），新增的 `hd2d_parallax.gd` 是画面渲染脚本本体。
- **不伪造产物**：13 张 PNG 为 Movie Maker 真实输出、`.wav` 为引擎自动音频轨；最终版为精修后重抓覆盖（非首版帧改名）。
- **不谎报成功**：节点数 27 如实回读登记（R22=25，不冒充）；HD-2D 全绿未达，见 §4。
- **不自行 git**：未执行任何 git 命令。
