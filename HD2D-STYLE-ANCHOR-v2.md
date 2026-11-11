# HD2D-STYLE-ANCHOR-v2.md · 风格锚点 v2（Technical Artist / Game Designer 的 P0 定调）

> 轮次 `[ROUND=R29]` · 派单 `cmd-20261111-112803-992-A3` · Rank-3（RPG / 世界 / 存档）· 2026-11-11
> **文件落点（明示，供 Rank-2 引用）**：`F:/Game/aierdengfahuan/HD2D-STYLE-ANCHOR-v2.md`（工程根，与 `TECHNICAL-ART-DEPTH-v060.md` 同级）
> 依据：`teamwork/艾尔登法环HD2D-美术风格提案.md` v1 §1 八字段（A15 已确认）｜ `TECHNICAL-ART-DEPTH-v060.md` P0/P1/P2 分级与 A30 裁决 ｜ `teamwork/00-协作契约.md` §9.3（A15 两层色数口径）｜ `teamwork/Rank-4/palette_256.json` / `HD-2D视觉规范.md` §2.2（项目级色库现有载体）
> **本文是文档级 P0 定调：不写任何 `godot/` 工程业务文件、不改渲染后端、不新增 shader / 素材、不启 GPU job、零付费。**

---

## 0. 一句话结论与定调边界（先说清「不是什么」）

风格锚点 **v2 = v1 八字段（冻结继承，逐字不改） + 4 个新增字段（景深分层 / 光色规范 / 暗角与光晕 / 三波色带节奏）**，并补齐三件可校验物：① 与《八方旅人》式 HD-2D 的**差距清单**（如实登记，非待办承诺）；② **三条验收判据**（缩略图 10% 剪影可读 / 主体与背景明度差 ≥2 档 / 同屏高饱和色 ≤3 种）；③ **可逐字复用的 16 色受控色板 + 项目级色库 ≥256 两层口径**（沿用 A15）。

**A30 裁决口径（本版严格遵守，不得越线）**：
- **本版只做 2D 近似强化、不切后端、不做真 3D 光效**。工程渲染后端仍是 `gl_compatibility`（`project.godot:145-146`），`glow` 历史显式关闭且未验证通过，`volumetric_fog` / DoF / SSR 属 Compatibility 后端能力缺口（见 `TECHNICAL-ART-DEPTH-v060.md` §2 / §4）。
- 工程口中的「体积光 / bloom / 湿地倒影 / 景深」**全部是 `hd2d_fx.gd` 的 `CanvasItem._draw()` 2D 近似**（倒影 `draw_rect()` 垂直镜像色块、体积光 `draw_colored_polygon()×6 + draw_line()`、光尘 / bloom `draw_circle()` 同心圆）+ `hd2d_parallax.gd` 三波色带 + `Environment.fog_enabled` 传统深度雾。**本文凡出现「景深 / 光晕 / 暗角 / 色带 / 体积光 / bloom」一律指这层 2D 程序化近似，不谎称真 3D 光效、不把 2D 近似包装成「HD-2D 全绿已达成」**（README「还差什么」第 2 / 12 项保持未达）。
- 若后续 P2 的 Compatibility 后端 `screen texture`（`hint_screen_texture` / `SCREEN_TEXTURE`）不可用，**降级为程序化 `_draw()` 强化并如实登记，不得谎称 shader 生效**（A30 裁决原文）。

**P0 → P1 → P2 分工（Rank-3 只交付本文）**：

| 级 | 内容 | 归属 |
|---|---|---|
| **P0（本版）** | 承认现状、停止把 2D 近似叫「真 3D 光效」；补齐四字段 + 差距清单 + 验收判据 + 16 色板 | **Rank-3（本文，仅文档）** |
| P1 | 景深强化层数据驱动参数 `depth_profile.tres`（层深 / 视差 / 雾密度 / 暗角 / 暖金光晕 / 冷夜雾色号 / 暖金主光色号） | Rank-2（本轮并发，`verify_depth_profile_v070.gd` 校验「色号落在本文色板内」） |
| P1 | HUD 景深 / 光色呈现 | Rank-1 |
| P2 | 全屏 `BackBufferCopy + ColorRect` shader 小样（或等价 `_draw()` 强化）+ 录屏目视 | Rank-4 |

> **所有 v2 新增数值一律标 `[PLACEHOLDER]`、逐项写 rationale、待人工试玩校准**（公共契约 v0.7.0 纪律）；本文不把建议值写进任何工程代码。

---

## 1. v1 八字段 · 冻结继承（逐字复用，v2 不改动）

以下为 `teamwork/艾尔登法环HD2D-美术风格提案.md` v1 §1 原文，**v2 逐字继承、不改一个字**；八个字段为「画风 / 视角 / 光照 / 线宽 / 质感 / 比例 / 色彩倾向 / 禁忌」，「3D 补充」为附属行。

```
【风格锚点 v1 · HD-2D 受控像素】
画风：受控索引色像素画 —— 单帧 ≤16 色，128×128 原生逻辑画布（64×64 逻辑像素 ×2 nearest 放大），
      每个像素为有意识放置的硬边色块，禁止任何降采样与抗锯齿。
视角：正交 45° 俯视场景 + 正面四分之三角色，角色只做朝右单方向，左向由代码镜像。
光照：左上暖金主光 + 右下冷夜蓝补光，全项目光源方向统一；每种材质只做 3 阶明度（暗 / 中 / 亮）
      + 1 阶高光，禁止渐变光晕与多光源错位。
线宽：外轮廓统一 1 逻辑像素深色描边 #0A1020；内部靠色块分界，不重复描边；UI 金线固定 1px。
质感：哑光硬边平涂，无渐变、无 dithering、无纹理噪声、无高光反射、无半透明脏边。
比例：角色 5 头身，头部占整体 20%，肩宽约头宽 2.2 倍；武器与盾不得与躯干同明度同色相。
色彩倾向：深蓝夜景为底（背景 L 10–35），暖金只用于主光 / 金属 / UI 边框（L 60–95），
      冷蓝用于主体中间调（L 40–60）；同屏高饱和色 ≤3 种。
禁忌：① 禁止 512→128 或任何中间分辨率降采样路径；② 禁止单帧 >16 色、渐变、dithering、
      高频磨损噪点；③ 禁止把受版权保护 IP 的具体贴片或角色当作生成目标；
      ④ 禁止 UI 与特效明度高于角色高光，禁止贴图盖住判定区。
3D 补充：低多边形硬边、哑光材质、无 PBR 反射；地面只用 1 张 ≤12 色 tile，
      不做逐像素法线 / AO / 粗糙度通道。
```

> 注意：v1 §1 已有「同屏高饱和色 ≤3 种」「单帧 ≤16 色」「主体 / 背景明度错开」三处判据雏形，v2 §4 把它们**升级为可执行验收判据并补 10% 剪影判据**，不新增与 v1 冲突的口径。

---

## 2. v2 新增四字段（逐字复用块）

以下四字段为 v2 增量，与 §1 八字段合起来即「风格锚点 v2」完整复用块（生成 / 校验时整段复制）。

```
【风格锚点 v2 · HD-2D 受控像素 · 2D 近似强化】
景深分层：只做 2D 伪景深 —— 远 / 中 / 近三层背景按深度降饱和、降对比、叠冷夜雾 alpha，
      近景玩家与 Boss 保持高对比；靠分层色带 + 视差 + 传统深度雾（Environment.fog_enabled，
      fog_density=0.02）制造纵深，绝不是真 DoF / 相机后处理。层数 [PLACEHOLDER]=3（远/中/近），
      远景冷雾 alpha [PLACEHOLDER]=0.15~0.35 随波次递进，复用 hd2d_parallax.gd 既有 wave_index
      驱动、零新增节点。实体层永远最高对比、零模糊；背景层禁止出现像素块感。
光色规范：光源方向全项目统一（左上暖金主光 + 右下冷夜蓝补光，继承 v1 光照）；暖金只打主体 /
      近景，远景一律偏冷去饱和；每种材质 3 阶明度 + 1 阶高光，禁止渐变光晕与多光源错位。
      冷夜雾色号 = #1B2A4A（L≈22）；暖金主光色号 = #C99A3A（L≈65），二者为本版唯一指定的
      「冷暖对冲」锚点色号，供 depth_profile.tres 字段逐字引用。同屏高饱和色 ≤3 种（白名单见 §5）。
暗角与光晕：暗角 = 屏幕四角 2D 叠低 alpha 冷色压暗 [PLACEHOLDER] 强度 0.10~0.25；
      光晕 / bloom = 仅暖金主光过阈、用 draw_circle() 同心圆 2D 近似 [PLACEHOLDER]
      半径 4/8/14/22/32、alpha 0.20/0.12/0.07/0.04/0.02。二者均为 CanvasItem._draw() 近似，
      不是 Environment.glow / 真体积光；冷雾区不得过 bloom 阈、不得出现暖金光束；
      暗角与光晕不得盖 HUD 矩形（x<730,y<220）与角色判定区（继承 v1 禁忌 ④）。
三波色带节奏：三波雾带色相按 wave_index 递进 冷蓝 → 深紫 → 暖紫，对应色号 [PLACEHOLDER]
      #24406B / #3B2E5A / #5A3B52（均在 16 色受控板内）；每波只用 3 段明度色带 + 剪影，
      禁止光尘噪点与渐变光晕（继承 v1 §4「场景远景」约定）；只改色彩节奏、不改波次数值，
      与 WAVE-TRIAL-SPATIAL.md「教学 / 加压 / 收束」空间节奏对齐。
```

### 2.1 景深分层（Depth Layering）

| 层 | 内容 | 处理 | 与主体关系 |
|---|---|---|---|
| 远 | 天空 / 远山 / 废墟剪影 | 冷调降饱和、最低对比、冷雾 alpha 最高 | 明度压到 L 10–35 |
| 中 | 中景林地 / 崖体 | 冷调降饱和、中对比 | 明度 L 22–45 |
| 近 | 近景地形 / 可站立面 | 中性、接近原色 | 明度 L 40–60 |
| 实体 | 玩家 / Boss / 道具 | **纯像素硬边、原色板、零模糊、最高对比** | 亮面 L 65–92 |

- **伪景深三件套**：分层色带 + 视差位移 + 传统深度雾（`fog_enabled=true` / `fog_density=0.02`）。**真 DoF 需相机后处理与深度缓冲，`gl_compatibility` 下不可直接依赖**（`TECHNICAL-ART-DEPTH-v060.md` §2.1）——本版明确不碰、不谎称。
- 分层**结构**沿用 `HD-2D视觉规范.md` §3 的「背景 / 特效 / 实体 / 前景 / UI」层序思想，但**只取层序与色温处理，不承诺 Rank-4 早期规格里的真模糊半径 / 多 SubViewport**；多 SubViewport 分层在 `TECHNICAL-ART-DEPTH-v060.md` §3 已判「代价大于收益、不列近期方案」。
- 层数 `[PLACEHOLDER]=3` · **rationale**：复用 `hd2d_parallax.gd` 既有按 `wave_index` 的雾密度 / 色带查表，零新增节点、零后端改动，回归面最小（`TECHNICAL-ART-DEPTH-v060.md` §5 P1）。
- 远景 alpha `[PLACEHOLDER]=0.15~0.35` · **rationale**：三波递进制造「越远越冷越淡」的空气透视，数值待录屏目视校准，不写进代码。

### 2.2 光色规范（Light & Color Discipline）

- 光源方向、3 阶明度 + 1 阶高光、禁止渐变光晕与多光源错位：**逐字继承 v1 光照 / 质感字段**。
- 暖金主光只作用于主体与近景；远景一律偏冷去饱和——这是「暖金 × 冷夜雾强对比」的唯一来源，也是与《八方旅人》式 HD-2D **已对齐**的一项。
- **两个语义色号显式钉死**（供 Rank-2 `depth_profile.tres` 的「冷夜雾色号 / 暖金主光色号」字段逐字引用）：
  - `cold_night_fog_hex = #1B2A4A`（v1 §2「辅色 深蓝夜」，L≈22，背景 / 暗部 / 砖缝阴影）
  - `warm_gold_key_hex = #C99A3A`（v1 §2「强调色 暖金」，L≈65，主光 / 肩甲 / UI 金线 / 金属装饰）
  - 二者明度差 = 65 − 22 = **43（约 4 档）**，满足「主体与背景明度差 ≥2 档」判据。
- 同屏高饱和色 ≤3 种：白名单见 §5.3，判定方法见 §4。

### 2.3 暗角与光晕（Vignette & Bloom，2D 近似）

- **暗角**：屏幕四角用 2D `_draw()` 叠低 alpha 冷色（`cold_night_fog_hex` 系）压暗，把视线收向中心主体。`[PLACEHOLDER]` 强度 `0.10~0.25` · **rationale**：纯 2D 矩形 / 径向色块，零 GPU job；数值待目视校准，过强会压掉 HUD 可读性（R28B 已实证 `low/mobile` 档缩放会伤面板文字，见 `TECHNICAL-ART-DEPTH-v060.md` §3）。
- **光晕 / bloom**：仅 `warm_gold_key` 色族允许过阈，用 `draw_circle()` 同心圆近似。`[PLACEHOLDER]` 半径 `4/8/14/22/32`、alpha `0.20/0.12/0.07/0.04/0.02` · **rationale**：与工程既有 `FXBloom`「仅暖金过阈」口径对齐，避免全屏泛白破坏冷暖对比（沿用 `HD-2D视觉规范.md` §7.4 占位默认参数）。
- **不谎称声明（A30 硬要求）**：`Environment.glow` 历史实测 / 显式关闭不支持（`build_courtyard.gd:201` `env.glow_enabled=false`），Compatibility 后端对 glow 支持有版本差异且本工程低分辨率整数放大会放大块状伪影；当前 bloom 与体积光全是 `hd2d_fx.gd` 的 2D `draw_circle()` / `draw_colored_polygon()` 近似。**本版定调不含任何「真 3D 光效已实现」的表述。**
- 冷雾区不得过 bloom 阈、不得出现暖金光束；暗角 / 光晕 / 光尘不得盖 HUD 矩形 `x<730,y<220` 与角色判定区（v1 禁忌 ④）。

### 2.4 三波色带节奏（Three-Wave Color Band Rhythm）

| 波 | 雾带色相 | 色号 `[PLACEHOLDER]` | 空间节奏（`WAVE-TRIAL-SPATIAL.md`） |
|---|---|---|---|
| 波 1 | 冷蓝 | `#24406B`（L≈30） | 教学 / 入场读秒，冷而克制 |
| 波 2 | 深紫 | `#3B2E5A`（L≈25） | 加压，去饱和压暗 |
| 波 3 | 暖紫 | `#5A3B52`（L≈32） | 收束，略回温但不抢主体暖金 |

- 驱动：`hd2d_parallax.gd` 既有按 `wave_index` 的雾密度 / 色带查表（冷蓝 → 深紫 → 暖紫，`TECHNICAL-ART-DEPTH-v060.md` §2.2 已登记），**复用同一驱动、零新增节点**。
- 每波只用 **3 段明度色带 + 剪影**，禁止光尘噪点与渐变光晕（v1 §4「场景远景」约定）。
- 三色均为 v2 新增 `[PLACEHOLDER]` · **rationale**：只在既有冷蓝 ↔ 暖紫区间做低饱和色相位移，不引入新色族、不新增 IP 风险色；数值待录屏目视校准，**只改色彩节奏、不改任何波次数值 / 奖励 / 时限**（Rank-2 数值域，不越界）。

---

## 3. 与《八方旅人》式 HD-2D 的差距清单（如实登记，非待办承诺）

> 参考坐标只取《八方旅人》HD-2D 的**构成逻辑**（像素点阵实体 vs 平滑多层景深），不复制任何具体角色 / 场景 / UI 资产（v1 §6）。下表「本工程现状」依据 `TECHNICAL-ART-DEPTH-v060.md` §1 实测，不把推断当实测。

| # | 维度 | 《八方旅人》式 HD-2D 参考特征 | 本工程 v0.7.0 现状（实测） | 差距 | 本版处置（A30） |
|---|---|---|---|---|---|
| 1 | 景深 | 真 DoF / 平滑多层虚化，背景失焦、角色绝对清晰 | 2D 分层色带 + 视差 + 传统深度雾（`fog_density=0.02`），无相机后处理 | **明显** | 只做 P1 2D 近似强化，不切后端 |
| 2 | 体积光 | 真 `volumetric_fog` / Froxel 体积步进 | `FXGodRays` 的 `draw_colored_polygon()×6 + draw_line()` 光锥近似 | **明显** | 保持 2D 近似，不谎称真体积光 |
| 3 | 湿地倒影 | SSR / Planar Reflection / ReflectionProbe | `FXReflection` 的 `draw_rect()` 垂直镜像色块（带波纹）；`WetReflection` 节点 R27 起 `visible=false` | **明显** | 保持 2D 镜像，不做真反射（billboard 会穿帮） |
| 4 | Bloom / Glow | `Environment.glow` 后处理，仅高光过阈 | `FXBloom` 的 `draw_circle()` 同心圆；`env.glow_enabled=false`（历史显式关闭、未验证通过） | **明显** | 保持 2D 近似；P0 定调停止误称「真 3D 光效」 |
| 5 | 3D 地形 / 缓冲 | 真 3D 网格 + 平滑景深 + 高质量后处理 | `SubViewport` 内 3D 世界 + `AnimatedSprite3D` billboard；`640×360` 低分辨率缓冲整数放大、`msaa_3d=0` | 部分 | 不新增 SubViewport、不改缓冲（§3 代价大于收益） |
| 6 | 像素精灵 | 2D 像素点阵角色、有限色板、Nearest | 受控索引色、单帧 ≤16 色、1px `#0A1020` 描边、Nearest（A15 口径） | **已对齐（口径级）** | 冻结继承 v1 八字段 |
| 7 | 光色关系 | 暖金主光 × 冷夜雾强对比 | 同一套暖金 / 冷夜蓝色板、光源方向全项目统一 | **已对齐（口径级）** | §2.2 钉死两个语义色号 |
| 8 | UI | 金线深蓝、1px 硬边 | 深蓝底 + 金线 1px + 亮钢文字（v1 §4） | **已对齐（口径级）** | 冻结继承，暗角 / 光晕须避让 HUD |
| 9 | 渲染后端 | Forward+ / Vulkan（上述 1~4 的正统前提） | `gl_compatibility`（OpenGL） | **根因** | **A30 裁决：不切后端**；切 `forward_plus` 列 P3 不推荐 |

> **差距清单是如实登记，不是「待补齐」承诺。** A30 已裁决「不切渲染后端、不做真 3D 光效」，故 1~5、9 保持为「2D 近似 vs 真 3D」的**已知差距**，本版不把 2D 近似包装成「HD-2D 全绿已达成」；README「还差什么」第 2 项（真 HDR bloom / 3D 体积光 / SSR）、第 12 项（HD-2D 全绿未达）**保持未达**。

---

## 4. 验收判据（三条硬判据 + 工程级补充，含判定方法）

| # | 判据 | 阈值 | 判定方法 | 失败表现 | 判定归属 |
|---|---|---|---|---|---|
| **J1** | **缩略图 10% 剪影可读** | 画面缩到 10% 时主体剪影仍可辨认 | 成品导出 PNG → 缩到 10% / 25% 两级 → 转灰度 → 目视 / ViewImage 看骑士 / 盾 / 剑 / 红缨结构（v1 §3 / 评审报告）；**须录屏首 / 中 / 尾三帧目视** | 10% 糊成一团、主体与背景黏连 | **Rank-4 录屏目视 + 用户试玩**；Rank-3 不代验、不宣称 |
| **J2** | **主体与背景明度差 ≥2 档** | 灰度下主体与背景跨越 ≥2 个明度档 | 转灰度后取主体亮面（L 65–92，如 `#C99A3A` / `#E8EDF2`）与背景（L 10–35，如 `#1B2A4A`）比对；本版锚点色对 65−22=43 ≈ 4 档，**静态查色板即可判** | 灰度下主体沉进背景、剪影不可分 | **Rank-3 文档静态查表可判**（色板 §5）；画面实证归 Rank-4 |
| **J3** | **同屏高饱和色 ≤3 种** | 单帧出现的高饱和强调色 hex ⊆ 白名单且种类 ≤3 | 白名单 = `#B33A3A` / `#C99A3A` / `#35D0C0`（§5.3）；逐帧统计高饱和色 hex 去重计数；其余受光 / 过渡色（`#F2D07A` / `#79B4E8` / `#C9D2E0` 等）不计入强调计数 | 同屏出现 ≥4 种抢眼色、主体被状态色淹没 | **Rank-3 文档静态查表可判**（色板 §5）；画面实证归 Rank-4 |

补充判据（继承，不新增冲突）：

| # | 判据 | 来源 |
|---|---|---|
| J4 | 转灰度后主体 / 背景仍清晰可分 | v1 §3 / `HD-2D视觉规范.md` §2.3 |
| J5 | 单帧取色 ⊆ 16 色受控表且数量 ≤16（A15 硬规则） | 契约 §9.3 / 本文 §5 |
| J6 | 状态不能只靠颜色区分，须带形状 / 图标差异 | v1 §2 硬规则 |
| J7 | 暗角 / 光晕 / 光尘不遮 HUD 矩形与角色判定区 | v1 禁忌 ④ / 本文 §2.3 |
| J8 | 三段门禁 `--headless --import → --check-only --script → --headless --quit`，`grep SCRIPT ERROR=0`，31 PASS 存档 / HUD 回归不回退 | 公共契约 v0.7.0 / 本轮 README R29 回归真跑行 |

> **归属边界**：J2 / J3 / J5 / J6 可由本文色板静态查表判定（Rank-2 `verify_depth_profile_v070.gd` 的「色号落在色板内」即属此类）；**J1 及暗角 / 光晕 / 三波色带的画面观感必须靠 Rank-4 录屏目视与用户人工试玩**，headless 真跑无真实帧缓冲，Rank-3 不代做手感 / 审美判断、不谎报通过。

---

## 5. 可逐字复用的色板色号（16 色受控 + 项目级色库 ≥256 · 两层口径沿用 A15）

### 5.1 两层口径（逐字沿用 `00-协作契约.md` §9.3 / 裁决 A15）

- **项目级色库 ≥256 色**：全项目共用一份项目级色库 / 统一调色板，色库规模 ≥256 色；这是**项目级下限**，不再以「≤256」封顶压缩色域。
- **单帧强制 ≤16 色索引**：每一帧像素素材只允许使用不超过 16 个色索引（受控色板，消除 R23 / R24 马赛克观感）；这是**单帧上限**，与项目级色库下限不矛盾 —— 色库大全项目共享、单帧从中取 ≤16 色。
- 原「256 色以上 / 单帧 ≥256」口径**废止**；**128px 基准画布不变**、**RGBA 保 alpha**；**`128bit` 歧义显式保留、待用户确认（A15 不消歧）**，不编码进任何期望值。
- **载体如实登记**：项目级色库现有载体为 `teamwork/Rank-4/palette_256.json`（`palette_id=hd2d_index_256_v1`，当前**冻结 32 色**、容量上限 256，与 `HD-2D视觉规范.md` §2.2 的 32 色功能板逐字一致）。**该 32 色板与美术提案 v1 §2 的色号不是同一套（历史两套口径并存）**，v2 **不擅自合并、不伪造一致**：下面的 16 色受控表以 **A15 已确认的美术提案 v1 §2 为真源**，项目级色库 ≥256 沿用 A15 / `palette_256.json`，二者是「单帧受控板」与「项目色库」两层、互不覆盖。扩展新色须经裁决统一并入，单资产不得私加。

### 5.2 16 色受控表（sRGB，hex6 大写，逐字复用）

> 13 色**逐字继承 v1 §2**（6 主色 + 7 派生色，冻结不改）；3 个雾带色为 **v2 新增 `[PLACEHOLDER]`**，待试玩校准。任一单帧取色必须全部落在本表内、数量 ≤16（不要求全用）。

| # | 色号 | 明度 L | 语义角色 | 用途 | 来源 |
|---:|---|---:|---|---|---|
| 1 | `#0A1020` | ≈8 | 阴影 / 描边 | 统一 1px 外轮廓、砖缝、接触阴影 | v1 §2 主色 |
| 2 | `#1B2A4A` | ≈22 | **冷夜雾色号 `cold_night_fog_hex`** | 暗部、背景天空、砖缝阴影 | v1 §2 主色 |
| 3 | `#6B4226` | ≈30 | 暗棕 | 皮革 / 木 / 暗部过渡 | v1 §2 派生 |
| 4 | `#B33A3A` | ≈40 | **危险暗红（高饱和白名单 ①）** | Boss、伤害、披风、红缨 | v1 §2 主色 |
| 5 | `#2C4C8C` | ≈45 | 主色 钴蓝 | 主体中间调：盔甲、盾底、砖面 | v1 §2 主色 |
| 6 | `#3F6FC4` | ≈55 | 亮钴蓝 | 亮面 / 高光过渡 | v1 §2 派生 |
| 7 | `#C99A3A` | ≈65 | **暖金主光色号 `warm_gold_key_hex`（高饱和白名单 ②）** | 主光、肩甲、UI 金线、金属装饰；唯一允许过 bloom 阈的色族 | v1 §2 主色 |
| 8 | `#35D0C0` | ≈70 | **青绿（高饱和白名单 ③）** | 增益 / 回复 / 状态 | v1 §2 派生 |
| 9 | `#79B4E8` | ≈72 | 亮蓝 | 主体亮面 / 受光面 | v1 §2 派生 |
| 10 | `#E8B98C` | ≈75 | 肤色 | 角色皮肤 | v1 §2 派生 |
| 11 | `#F2D07A` | ≈82 | 暖金高光 | 亮面 / 高光过渡（受光色，不计入高饱和强调计数） | v1 §2 派生 |
| 12 | `#C9D2E0` | ≈82 | 冷亮钢 | 亮面 / 高光过渡 | v1 §2 派生 |
| 13 | `#E8EDF2` | ≈92 | 最高亮 亮钢 | 武器、面甲高光、文字、强调 | v1 §2 主色 |
| 14 | `#24406B` | ≈30 | **波 1 冷蓝雾带** `[PLACEHOLDER]` | 三波色带节奏 第 1 波 | **v2 新增** |
| 15 | `#3B2E5A` | ≈25 | **波 2 深紫雾带** `[PLACEHOLDER]` | 三波色带节奏 第 2 波 | **v2 新增** |
| 16 | `#5A3B52` | ≈32 | **波 3 暖紫雾带** `[PLACEHOLDER]` | 三波色带节奏 第 3 波 | **v2 新增** |

- **高饱和色白名单（J3 用）**：`#B33A3A` / `#C99A3A` / `#35D0C0` 共 3 种；同屏高饱和强调色必须 ⊆ 此白名单且 ≤3 种。其余色（含 `#F2D07A` 暖金高光、`#79B4E8` 亮蓝、`#C9D2E0` 冷亮钢）归为「受光 / 过渡色」，不计入强调计数。状态区分仍须带形状 / 图标（J6）。
- **明度差锚点（J2 用）**：背景 `#1B2A4A`（L≈22）↔ 主体亮面 `#C99A3A`（L≈65）/ `#E8EDF2`（L≈92），差 43~70 ≈ **4 档以上**，≥2 档判据满足。
- 3 个 `[PLACEHOLDER]` 雾带色 **rationale**：复用 `hd2d_parallax.gd` 既有 `wave_index` 驱动、零新增节点、只在既有冷蓝 ↔ 暖紫区间做低饱和色相位移、不引入新色族 / IP 风险色；数值待录屏目视校准，未写进任何工程代码。

### 5.3 可机器解析的色板常量块（供 Rank-2 / 校验脚本整段逐字复制）

```json
{
  "anchor_id": "HD2D-STYLE-ANCHOR-v2",
  "file": "F:/Game/aierdengfahuan/HD2D-STYLE-ANCHOR-v2.md",
  "palette_layer": "16_color_controlled",
  "encoding": "hex6 uppercase #RRGGBB",
  "max_colors_per_frame": 16,
  "colors_16": [
    "#0A1020", "#1B2A4A", "#6B4226", "#B33A3A",
    "#2C4C8C", "#3F6FC4", "#C99A3A", "#35D0C0",
    "#79B4E8", "#E8B98C", "#F2D07A", "#C9D2E0",
    "#E8EDF2", "#24406B", "#3B2E5A", "#5A3B52"
  ],
  "cold_night_fog_hex": "#1B2A4A",
  "warm_gold_key_hex": "#C99A3A",
  "high_saturation_allowlist": ["#B33A3A", "#C99A3A", "#35D0C0"],
  "wave_band_hex": ["#24406B", "#3B2E5A", "#5A3B52"],
  "placeholder_hex": ["#24406B", "#3B2E5A", "#5A3B52"],
  "two_layer_a15": {
    "project_library_min_colors": 256,
    "project_library_source": "teamwork/Rank-4/palette_256.json",
    "project_library_palette_id": "hd2d_index_256_v1",
    "project_library_frozen_colors": 32,
    "per_frame_max_color_indices": 16,
    "canvas_base_px": 128,
    "rgba_keep_alpha": true,
    "note": "项目级色库 ≥256 与单帧 ≤16 色索引为两层口径、沿用裁决 A15；128bit 歧义保留待用户确认"
  }
}
```

> **本块仅供逐字复制 / 静态校验，不代表已写入任何 `godot/` 工程文件**。Rank-2 `verify_depth_profile_v070.gd` 若引用，请在其 `DEPTH-PROFILE-TUNING.md` 如实登记来源；若本文尚未落盘则按其任务单降级为自带色板常量并如实登记。

### 5.4 色板使用硬规则（继承 v1 §2 + 本版 J2 / J3 / J5）

1. 单帧取色 ⊆ 上表 16 色、数量 ≤16（A15 / J5）。
2. 主体与背景明度差 ≥2 档（背景 L 22 vs 主体亮面 L 65–92，v1 §2 硬规则 / J2）。
3. 同屏高饱和色 ⊆ 3 色白名单且 ≤3 种（v1 §1 / J3）。
4. 同族对象共用同一组辅色，只换主色区分个体；状态不能只靠颜色区分，须带形状 / 图标差异（v1 §2 / J6）。
5. 禁止降采样路径 / 渐变 / dithering / 高频磨损噪点 / UI 与特效明度高于角色高光 / 贴图盖判定区（v1 §1 禁忌 ① ② ③ ④）。

---

## 6. `[PLACEHOLDER]` 新数值汇总（全部待人工试玩校准，均未写进工程代码）

| 数值 | 建议值 | rationale | 校准归属 |
|---|---|---|---|
| 景深层数 | 3（远 / 中 / 近） | 复用 `hd2d_parallax.gd` 既有 `wave_index` 驱动、零新增节点 | Rank-2 `depth_profile.tres` / 录屏目视 |
| 远景冷雾 alpha | 0.15~0.35 随波次递进 | 三波空气透视，避免过强压掉 HUD 可读性 | 录屏目视 / 用户试玩 |
| 暗角强度 | 0.10~0.25 | 2D 低 alpha 冷色压暗，过强伤面板文字（R28B 实证） | 录屏目视 / 用户试玩 |
| bloom 半径 / alpha | `4/8/14/22/32` / `0.20/0.12/0.07/0.04/0.02` | 与既有 `FXBloom`「仅暖金过阈」口径对齐、避免全屏泛白 | 录屏目视 / 用户试玩 |
| 三波雾带色号 | `#24406B` / `#3B2E5A` / `#5A3B52` | 只在既有冷蓝↔暖紫区间低饱和位移、不新增色族 / IP 风险色 | 录屏目视 / 用户试玩 |

---

## 7. 本版没做什么（如实边界，供 DONE-R29.md 引用）

- **未切渲染后端、未做真 3D 光效、未谎称 shader 生效**（A30 / `TECHNICAL-ART-DEPTH-v060.md` §7）；本文所有光效措辞均指 2D `_draw()` 近似。
- **未写任何 `godot/` 工程业务文件**：未改 `project.godot` / `courtyard.tscn` / `hd2d_fx.gd` / `hd2d_parallax.gd` / `depth_profile.tres` / 任何 `.tres` / 素材 PNG / shader；未新增 `[PLACEHOLDER]` 数值到工程代码。
- **未代验 Rank-2 景深参数 / Rank-1 HUD / Rank-4 全屏 shader 与录屏**；J1（10% 剪影）及暗角 / 光晕 / 三波色带的画面观感不属 Rank-3 判定范围，不宣称 HD-2D 全绿。
- **未擅自合并两套历史色板**（v1 §2 与 Rank-4 32 色板），如实登记并存、以 A15 确认的 v1 §2 为 16 色受控表真源。
- **未消歧 `128bit`**（A15 保留）、未自行 git、零付费、零外部依赖、未启 GPU job、未新建只读探针 / 巡检脚本。
- 差距清单（§3）为**如实登记**，不是「已排期补齐」；README「还差什么」第 2 / 12 项保持未达。

---

## 8. 派生色说明（R29C · 裁决 A32 追加；只追加本段，不改任何 `godot/` 工程文件）

> 触发：`capture/CAPTURE-REPORT.md` §12.2 / `capture/V070-RUNTIME-REVIEW.md` §3 / `teamwork/Rank-4/DONE-R29.md` §2 的 R29 shader 报告把 `cool_fog_color` 标为 `#2B3A5C`、`warm_glow_color` 标为 `#F0A94C`，与本文 §2.2 / §5 钉死的锚点 `#1B2A4A` / `#C99A3A` **不同**。本节钉死 uniform 真源、给出派生显示色的来源公式与 rationale，并立下「不得冒充新色板」硬规则。**本段为文档级登记，未改 `depth_profile.tres` / `v070_depth_grade.gdshader` / `hd2d_parallax.gd` / `palette_256.json` 任何 `godot/` 文件。**

### 8.1 uniform 真源 = `godot/data/render/depth_profile.tres` 的锚点色

| shader uniform（`v070_depth_grade.gdshader`） | 真源字段（`depth_profile.tres`，desktop / mobile 两档同值） | 锚点值 | 与本文对应 |
|---|---|---|---|
| `cool_fog_color : vec3` | `cold_night_fog_color = "#1B2A4A"` | **`#1B2A4A`** | §2.2 `cold_night_fog_hex` / §5.2 第 2 色 |
| `warm_glow_color : vec3` | `warm_gold_key_color = "#C99A3A"` | **`#C99A3A`** | §2.2 `warm_gold_key_hex` / §5.2 第 7 色 |

- `depth_profile.tres` 是 P1 景深参数的**唯一数据源**（Rank-2 所有），两档色号逐字引用本文 §2.2 唯一锚点；依据 `teamwork/Rank-2/DEPTH-PROFILE-TUNING.md` §2 第 6 / 7 行与 §3「色号依据与降级登记」。
- shader 内 `cool_fog_color` / `warm_glow_color` 及全部 uniform **一律不带默认值**（`v070_depth_grade.gdshader` 文件头注释），由 `godot/scripts/render/hd2d_parallax.gd::_r29_map_profile()` 经 `set_shader_parameter` 注入，**生效数值不硬编码于 shader**。

**来源公式（色号为逐字直取、零数值派生）**：

```
cool_fog_color  = Color(depth_profile.cold_night_fog_color)   # Color(String(v))，"#1B2A4A" → vec3
warm_glow_color = Color(depth_profile.warm_gold_key_color)     # Color(String(v))，"#C99A3A" → vec3
```

即 `#RRGGBB` 字符串 → Godot `Color(String(v))` → `vec3`，**色号本身不做任何数学运算 / 不做明度或色相派生**；hex→颜色空间转换由 Godot `Color` 构造完成。真正带量纲派生的是**强度类** uniform（非色号）：`cool_fog_strength = clamp(fog_density × 5, 0, 1)`、`depth_far_strength = clamp(layer_depths[0] × 0.4, 0, 1)`、`blur_radius = clamp(parallax_coefficients[0] × 25, 0, 4)`，系数 `×5 / ×0.4 / ×25` 均标 `[PLACEHOLDER]` 待试玩校准，rationale 见 `hd2d_parallax.gd:430-434` 注释（「参数表字段语义 → shader uniform 量纲换算」）。**结论：shader 色 uniform 的真源是 `.tres` 锚点色，不是任何派生色。**

### 8.2 派生显示色 `#2B3A5C` / `#F0A94C` 的来源公式与 rationale（如实登记）

- **它们不是锚点色的代码派生**，而是 `godot/assets/generated/palette_256.json`（Rank-4 32 色项目级色库）的**灰阶档**：`L3 = #2B3A5C`（`gray_pct 28`，冷夜雾中间调）/ `L7 = #F0A94C`（`gray_pct 85`，暖金受光主色）；同一组值亦为 `godot/scripts/verify_depth_profile_v070.gd` 的 `FALLBACK_COLD_GROUP` / `FALLBACK_WARM_GROUP` 降级常量。
- **来源公式（可复算）**：取 32 色板「冷夜雾族」按灰阶排序的中间档 L3 与「暖金族」受光档 L7；**属本文 §5.1 已如实登记的「另一套历史色板」**（32 色板与 v1 §2 的 16 色受控板历史两套并存、不擅自合并），与锚点 `#1B2A4A` / `#C99A3A` **无逐字派生关系**（锚点 L≈22 / L≈65，派生显示色 L≈28 / L≈85，是各自色板独立灰阶档，非同一公式产物）。
- **为何出现在 shader 报告（rationale，依据 Rank-2 如实纠错登记）**：`teamwork/Rank-2/DONE-R29.md` 文首 / `DEPTH-PROFILE-TUNING.md` §3 记载 —— Rank-2 早期用 Glob `**/HD2D-STYLE-ANCHOR*` 未匹配到工程**根级**文件，一度误判锚点文档「未落盘」，`depth_profile.tres` **首版**曾采用 `palette_256.json` 的 `#2B3A5C` / `#F0A94C`（暗角 `0.32`）；真跑 `FileAccess.file_exists` 返回 `exists=true` 纠正后，**最终 `.tres` 色号改回锚点 `#1B2A4A` / `#C99A3A`**、暗角改 `0.24`，verify 重写为「已落盘→v2 板 / 未落盘→降级板」双分支，首版 46 PASS 不作最终结论。Rank-4 录屏 / shader 报告的显示色沿该**历史首版 / 降级分支**口径，故与最终 `.tres` 真源不一致。**这是如实登记的历史显示色，不是 v2 新增色、不是锚点色派生。**

### 8.3 硬规则：shader 派生色必须写明来源公式与 rationale，不得冒充新色板

1. **四要素齐全**：今后任何 shader 派生 / 显示色若要登记为「由锚点色派生」，必须逐色写明 **① 来源锚点 hex ② 派生公式**（明度档 / 色相 / 混合的具体算式与系数）**③ 结果 hex ④ rationale**，并登记于本段或经总指挥裁决；四要素不全者一律按「历史显示色 / 非 v2 受控色板成员」如实登记，不得升格为色板色。
2. **不得冒充新色板（A32 裁决核心）**：不得把 `#2B3A5C` / `#F0A94C`（或任何派生显示色）宣称为「v2 新色板 / 第三套色板 / 锚点色的合法派生」；**不得并入 §5.2 16 色受控表**；**不得改写 §5.3 可机器解析常量块**（`colors_16` / `cold_night_fog_hex=#1B2A4A` / `warm_gold_key_hex=#C99A3A` / `high_saturation_allowlist` / `wave_band_hex` 逐字冻结）；不得改写 §2.2 唯一锚点色号或 `depth_profile.tres` 的色号语义。派生色若确需纳入受控板，须先补齐四要素、走「扩展新色须经裁决统一并入、单资产不得私加」（§5.1）流程。
3. **真源唯一**：`cool_fog_color` / `warm_glow_color` 等色 uniform 的取值以 `depth_profile.tres` 锚点色为准（§8.1 公式）；`hd2d_parallax.gd::_r29_base_defaults()` 的 `cool_fog_color=Color(0.12,0.22,0.40)` / `warm_glow_color=Color(1.0,0.72,0.32)` 是参数表未落盘时的 `[PLACEHOLDER]` 安全默认、非色板色，不得当作新色号引用。
4. **不得改 `godot/` 工程文件**：本段为文档级登记；`depth_profile.tres` / `v070_depth_grade.gdshader` / `hd2d_parallax.gd` / `palette_256.json` / `verify_depth_profile_v070.gd` 的修正与派生公式补登记属 Rank-2 / Rank-4 工程写入、经总指挥裁决，Rank-3 本轮一律未动。

### 8.4 派生显示色四要素登记（R30 · A34 补齐；如实、非 v2 新色板）

> 触发：R29C / 裁决 A32 在 §8.3 第 1 条立下「派生 / 显示色登记须写明 **① 来源锚点 hex ② 派生公式 ③ 结果 hex ④ rationale** 四要素」，并把本子节登记为「未完成 / 待登记」。本轮 A34 按任务单把 `#2B3A5C` / `#F0A94C` 的四要素补齐。**只改写本子节，不改 §8.1 / §8.2 / §8.3 逐字结论、不改 §2.2 / §5.2 / §5.3 / §7、不改任何 `godot/` 工程文件**（`depth_profile.tres` / `v070_depth_grade.gdshader` / `hd2d_parallax.gd` / `palette_256.json` / `verify_depth_profile_v070.gd` 一律未动）。

#### ① 来源锚点 hex

| 系 | v2 语义锚点（§2.2 / §5.2 唯一锚点，逐字冻结） | 明度档 | 32 色板灰阶目标档（真源，`palette_256.json`） | `gray_pct` |
|---|---|---:|---|---:|
| 冷夜雾 | `cold_night_fog_hex = #1B2A4A` = sRGB `(27, 42, 74)`（§5.2 第 2 色） | L≈22 | `L3 = #2B3A5C` = `colors[8]`，属 `cold_night_fog` indices `[5,6,7,8,9,10]` | **28%** |
| 暖金主光 | `warm_gold_key_hex = #C99A3A` = sRGB `(201, 154, 58)`（§5.2 第 7 色） | L≈65 | `L7 = #F0A94C` = `colors[2]`，属 `warm_gold_key` indices `[0,1,2,3,4]` | **85%** |

- **真源补注（任务单要求明确）**：`#2B3A5C` / `#F0A94C` **来自** Rank-4 `teamwork/Rank-4/palette_256.json`（`palette_id = hd2d_index_256_v1`、`color_count = 32`、`status = frozen_temporary_R2`）的 `luma_l0_l8` 灰阶档 `L3 = {index:8, hex:#2B3A5C, gray_pct:28}` / `L7 = {index:2, hex:#F0A94C, gray_pct:85}`，两 hex 亦逐字落在 `colors[8]` / `colors[2]`。它们是 **32 色板历史显示色 / 独立灰阶档**，与 §8.2 如实登记一致（「与锚点 `#1B2A4A` / `#C99A3A` 无逐字派生关系」「各自色板独立灰阶档、非同一公式产物」）。同一组值亦为 `godot/scripts/verify_depth_profile_v070.gd` 的 `FALLBACK_COLD_GROUP` / `FALLBACK_WARM_GROUP` 降级常量。
- **v2 语义锚点只作「色族 / 明度档对照」**，不是结果色的生成源：`#1B2A4A` / `#C99A3A` 是 `depth_profile.tres` 的 `cold_night_fog_color` / `warm_gold_key_color`（§8.1 uniform 真源），desktop / mobile 两档同值。

#### ② 派生公式（锚点色 → 灰阶插值 / 亮度提升 → 结果色，含中间计算）

> 公式定位：**登记式表达**（把 v2 锚点明度档对齐到 32 色板 L3 / L7 冻结显示档），用于让四要素可复算、可核对；**不是**宣称「v2 锚点色经连续数学函数派生出结果色」。两套色板刻度独立、结果 hex 逐字取自 32 色板冻结档（见下方步骤 C 反证）。

**步骤 A · 明度档灰阶对齐（灰阶插值）**

- 冷：锚点明度档 `L≈22`（§2.2 / §5.2）→ 32 色板目标档 `L3 = 28%`；亮度提升 `ΔL = 28 − 22 = +6`。
- 暖：锚点明度档 `L≈65` → 32 色板目标档 `L7 = 85%`；亮度提升 `ΔL = 85 − 65 = +20`。
- 注：`L≈22 / L≈65` 是 v2 §5.2 的明度档编号，`28% / 85%` 是 32 色板 `luma_l0_l8.gray_pct`；**两套刻度独立、只做档位对齐、不做跨板数值换算**（§8.2「各自色板独立灰阶档」）。

**步骤 B · 亮度提升（逐通道 Δ，精确可复算）**

```
冷  A_cold = #1B2A4A = (27, 42, 74)
    Δ = L3 − A_cold = (43−27, 58−42, 92−74) = (+16, +16, +18)
    (27+16, 42+16, 74+18) = (43, 58, 92)
    → 0x2B 0x3A 0x5C = #2B3A5C   ✓ 精确复现 colors[8]

暖  A_warm = #C99A3A = (201, 154, 58)
    Δ = L7 − A_warm = (240−201, 169−154, 76−58) = (+39, +15, +18)
    (201+39, 154+15, 58+18) = (240, 169, 76)
    → 0xF0 0xA9 0x4C = #F0A94C   ✓ 精确复现 colors[2]
```

- `Δ` 是**两套历史色板色号的逐字通道差**（非连续函数的系数 / 非 `[PLACEHOLDER]` 调参量）。步骤 A + 步骤 B 合起来即「锚点色 → 灰阶插值 / 亮度提升 → 结果色」的登记式公式，中间计算如上、任何人可逐通道复算。

**步骤 C · 反证：冻结档不可由相邻灰阶档线性插值生成（如实登记，证明「非同一公式产物」）**

- 用 `luma_l0_l8` 相邻档按 `gray_pct` 插值 `L3(28%)`：`t = (28−18)/(40−18) = 10/22 ≈ 0.4545`；`L2 = #16233F = (22,35,63)` → `L4 = #4A6089 = (74,96,137)`：
  - `R = 22 + 52×0.4545 ≈ 45.6 → 0x2E`；`G = 35 + 61×0.4545 ≈ 62.7 → 0x3F`；`B = 63 + 74×0.4545 ≈ 96.6 → 0x61` ⇒ `#2E3F61`，与冻结档 `#2B3A5C` 差 `(3,5,5)`。
- `L7(85%)` 的相邻档 `L6(70%, #C6BBA4 中性石材族)` / `L8(96%, #FFF0C2 暖金高光)` **跨色族**，`luma_l0_l8` 是全局明度阶梯而非单色族连续灰阶；按 `t = 15/26 ≈ 0.5769` 插值得 `#E7DAB5`，与 `#F0A94C` 差更远。
- **结论**：32 色板是**手绘冻结色阶**，`L3` / `L7` 不能由相邻档线性插值精确复现，必须逐字取自 `palette_256.json`。这正好印证 §8.2「无逐字派生关系、非同一公式产物」，因此本公式只做档位对齐 + 逐字通道差登记，**不构成「锚点色经数学函数派生出结果色」的宣称**。

#### ③ 结果 hex

| 系 | 结果 hex | sRGB | 逐字来源 | 语义 |
|---|---|---|---|---|
| 冷夜雾 | **`#2B3A5C`** | `(43, 58, 92)` | `palette_256.json` `L3` / `colors[8]` / `luma_l0_l8.L3.hex` | 冷夜雾中间调（历史显示色 / 降级分支常量） |
| 暖金主光 | **`#F0A94C`** | `(240, 169, 76)` | `palette_256.json` `L7` / `colors[2]` / `luma_l0_l8.L7.hex` | 暖金受光主色（历史显示色 / 降级分支常量） |

#### ④ rationale

- **为什么出现在 shader 报告（§8.2 依据 Rank-2 如实纠错登记）**：`teamwork/Rank-2/DONE-R29.md` 文首 / `DEPTH-PROFILE-TUNING.md` §3 记载 —— Rank-2 早期用 Glob `**/HD2D-STYLE-ANCHOR*` 未匹配到工程**根级**文件，一度误判锚点文档「未落盘」，`depth_profile.tres` **首版**曾采用 `palette_256.json` 的 `#2B3A5C` / `#F0A94C`（暗角 `0.32`）；真跑 `FileAccess.file_exists` 返回 `exists=true` 纠正后，**最终 `.tres` 色号改回锚点 `#1B2A4A` / `#C99A3A`**、暗角改 `0.24`，verify 重写为「已落盘 → v2 板 / 未落盘 → 降级板」双分支，首版 46 PASS 不作最终结论。Rank-4 录屏 / shader 报告的显示色沿该**历史首版 / 降级分支**口径，故与最终 `.tres` 真源不一致。
- **本轮登记 rationale**：把「历史显示色」按 §8.3 第 1 条补齐四要素、钉死可复算公式，目的是**消除「派生色来源不明 / 可能被误升格为新色板」的歧义**，而非把它们纳入 v2 受控板。公式中的「亮度提升 / 灰阶插值」是**两套历史色板之间的档位对照**，不是 shader 内的数值运算（shader 色 uniform 按 §8.1 仍是 `Color(String(v))` 逐字直取、零数值派生）。
- **不升格 / 不并入 / 真源不变**（A32 裁决核心，本轮重申，见下三条声明）。

#### 三条声明（A32 裁决核心 · 本轮重申）

1. **不是 v2 新色板**：`#2B3A5C` / `#F0A94C` 是 `palette_256.json` 32 色板的历史显示色 / 独立灰阶档，**不是 v2 新增色板、不是第三套色板、不是 v2 锚点 `#1B2A4A` / `#C99A3A` 的合法派生**；不得改写 §2.2 唯一锚点色号、不得改写 §5.3 可机器解析常量块（`colors_16` / `cold_night_fog_hex=#1B2A4A` / `warm_gold_key_hex=#C99A3A` / `high_saturation_allowlist` / `wave_band_hex` 逐字冻结）。
2. **不并入 §5.2 16 色受控表**：§5.2 逐字冻结 13 色继承 + 3 个 `[PLACEHOLDER]` 雾带色，本轮**不增、不删、不改**任何一行；扩展新色须走「扩展新色须经裁决统一并入、单资产不得私加」（§5.1 / §8.3 第 2 条）流程，本登记**不触发**该流程、不请求并入。
3. **uniform 真源仍是 `depth_profile.tres` 锚点色**：`cool_fog_color` / `warm_glow_color` 等色 uniform 取值以 `godot/data/render/depth_profile.tres` 的 `cold_night_fog_color = "#1B2A4A"` / `warm_gold_key_color = "#C99A3A"`（desktop / mobile 两档同值）为准，按 §8.1 公式 `Color(String(v))` hex→vec3 逐字直取；`hd2d_parallax.gd::_r29_base_defaults()` 的 `Color(0.12,0.22,0.40)` / `Color(1.0,0.72,0.32)` 是参数表未落盘时的 `[PLACEHOLDER]` 安全默认、非色板色。**本段不改变 `depth_profile.tres` 的任何色号语义，也不改变 shader 的取色路径**。

#### 边界（不改其它历史条款）

- 与 A30「不谎称 shader 生效 / 不把 2D 近似包装成 HD-2D 全绿」纪律一致：本段不改变 §3 差距清单、§4 判据、§5 色板、§7 边界、§8.1 / §8.2 / §8.3 的任何既有结论；`README.md`「还差什么」第 2 项（真 HDR bloom / 3D 体积光 / SSR）/ 第 12 项（HD-2D 全绿未达）保持未达。
- 本段为文档级登记；`depth_profile.tres` / `v070_depth_grade.gdshader` / `hd2d_parallax.gd` / `palette_256.json` / `verify_depth_profile_v070.gd` 的修正与派生公式补登记属 Rank-2 / Rank-4 工程写入、经总指挥裁决，Rank-3 本轮一律未动、未新建任何探针 / 巡检脚本。
