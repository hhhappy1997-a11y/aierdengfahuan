# DEPTH-PROFILE-TUNING.md · 景深强化层数据驱动参数调参说明

> 轮次 **R29** ｜命令 `cmd-20261111-112803-988-A2`（`[ROUND=R29]`，v0.7.0 新内容）｜工位 **Rank-2（战斗系统与数据驱动）**
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`）
> 工程根 `F:/Game/aierdengfahuan`，Godot 工程 `F:/Game/aierdengfahuan/godot`｜中文 UTF-8
> 依据：`TECHNICAL-ART-DEPTH-v060.md` §5 **P1** ／ `HD2D-STYLE-ANCHOR-v2.md`（Rank-3，R29 并发落盘）§2.2 / §5.3
> **本文是调参说明：不改任何工程渲染件；全部数值 `[PLACEHOLDER]` 首版、待人工试玩校准。**

---

## 0. 一句话：是什么 / 不是什么

- **是什么**：`godot/data/render/depth_profile.tres` 是 P1「多层视差景深 + 边缘暗角 + 冷夜雾 + 暖金光晕」的**唯一数据源**，含 `desktop` / `mobile` 两档，供 Rank-4 的 shader / `hd2d_parallax.gd` 按画质档读取；`depth_profile.gd` 定义字段结构与合法性自检 `is_valid()`；`verify_depth_profile_v070.gd` 真跑校验。
- **不是什么**：不是 shader、不改场景节点、不改渲染后端（仍 `gl_compatibility`）、不做真 3D 光效（A30 裁决）、不写 `hud.gd` / `presentation.gd` / 素材 / 契约 / README。headless 数据件无真实帧缓冲，**不能替代人眼目视与录屏**。
- **落盘时间（文件 mtime 真值）**：`depth_profile.gd` / `depth_profile.tres` 首版 **2026-11-11 11:46** 落盘（尽早落盘供 Rank-4 读取）；依 Rank-3 锚点文档复核修正色号与暗角后 **11:47** 定稿；`verify_depth_profile_v070.gd` **11:48** 落盘。

---

## 1. 调参唯一入口

| 角色 | 精确路径 | 说明 |
|---|---|---|
| **唯一调参入口** | `godot/data/render/depth_profile.tres` | 两档 **7 个字段的全部设计数值只在这里**；改数值只改此文件 |
| 结构定义 | `godot/scripts/render/depth_profile.gd` | `class_name DepthProfile extends Resource`；其默认值全为 `[PLACEHOLDER]` **非法占位基线**（`is_valid()` 恒 false），不是设计值 |
| 校验 | `godot/scripts/verify_depth_profile_v070.gd` | `extends SceneTree`，46 条断言，`CACHE_MODE_IGNORE` 真读盘 |
| 说明 | `teamwork/Rank-2/DEPTH-PROFILE-TUNING.md` | 本文件（数值假设表 / broken 定义 / 档位关系） |

**校准同步清单（不静默改数）**：`.tres` 数值 → `verify_depth_profile_v070.gd` 的期望与色板常量 → 本文假设表 → 真跑三段门禁。**任何一处改数，四处必须同步，并重新真跑。**

**Rank-4 读取约定（仅约定，非本轮真跑代码）**：`load("res://data/render/depth_profile.tres")` 得到顶层 `DepthProfile` 容器，其 `desktop` / `mobile` 两个字段各是一份 `DepthProfile` 子资源；按画质档取其一，读 7 个字段。色号为 `#RRGGBB` 字符串，由消费方自行转 `Color`；本轮不接线、不改 `project.godot` / 场景 / autoload / shader。

---

## 2. 数值假设表（两档 7 字段 · 全部 `[PLACEHOLDER]` 首版）

| # | 字段 | 语义 | `desktop` | `mobile` | 合法域 | rationale |
|---:|---|---|---|---|---|---|
| 1 | `layer_depths` | 层深：多层视差各层归一化深度（远→近），数组长度=层数 | `[0.25, 0.55, 0.90]`（3 层） | `[0.35, 0.80]`（2 层） | 每个 `0<d<=1`、`>0` | 复用 `hd2d_parallax.gd:47-49` 三层视差概念（`P_RIDGE_FAR/MID/NEAR=0.06/0.14/0.26`）；以数组表达「几层 + 各层纵深」，零新增节点即可驱动 2D `_draw()` 分层；mobile 减到 2 层降低合成层数＝不糊。层数对齐 v2 §2.1 建议 `[PLACEHOLDER]=3`（desktop 取 3，mobile 降级取 2）。 |
| 2 | `parallax_coefficients` | 视差系数：与层深一一对应，远小近大 | `[0.06, 0.14, 0.26]` | `[0.05, 0.12]` | 每个 `0<c<=1`、严格递增 | desktop 逐字对齐 `hd2d_parallax.gd` 既有三层山影漂移幅度，避免另起一套数值；mobile 少一层且逐项更小＝降级不糊。 |
| 3 | `fog_density` | 冷夜雾密度 | `0.035` | `0.018` | `0~1` | 工程 `Environment.fog_density=0.02`（`TECHNICAL-ART-DEPTH-v060.md` §1）；desktop 略抬强化纵深，mobile 取 `0.018` 低于基线＝雾更淡不糊。Compatibility 后端传统深度雾，零 GPU job。 |
| 4 | `vignette_strength` | 边缘暗角强度 | `0.24` | `0.12` | `0~1` | 对齐 `HD2D-STYLE-ANCHOR-v2.md` §2.3 建议区间 `0.10~0.25`；2D 低 alpha 冷色压暗，低分辨率整数放大下过强会压掉 HUD 面板文字（R28B 实证），故留上限且 mobile 减半＝不黑。 |
| 5 | `warm_glow_strength` | 暖金光晕强度 | `0.45` | `0.22` | `0~1` | 对齐 `hd2d_fx.gd` `FXBloom`「仅 `warm_gold_key` 过阈」口径；单标量总强度（与 v2 §2.3 的逐圈 `alpha 0.20/0.12/...` 不是同一量，是乘数），避免全屏泛白；mobile 减半＝不亮不过曝。 |
| 6 | `cold_night_fog_color` | 冷夜雾色号 | `#1B2A4A` | `#1B2A4A` | `#RRGGBB`，须 ∈ 色板 | 逐字引用 `HD2D-STYLE-ANCHOR-v2.md` §2.2 唯一锚点 `cold_night_fog_hex`（L≈22）；两档同色号保证画质切换不改冷暖对冲，降级只动强度/层数/密度、不动色相。 |
| 7 | `warm_gold_key_color` | 暖金主光色号 | `#C99A3A` | `#C99A3A` | `#RRGGBB`，须 ∈ 色板 | 逐字引用 v2 §2.2 唯一锚点 `warm_gold_key_hex`（L≈65，唯一允许过 bloom 阈的色族）；与冷夜雾锚点明度差 43≈4 档，满足 v2 J2「主体与背景明度差 ≥2 档」。 |

**容器字段（不计入 7 参数）**：顶层 `depth_profile.tres` 的 `desktop` / `mobile` 是两份 `DepthProfile` 子资源引用；单档实例的这两个字段为 `null`。

**mobile 降级关系（verify 降级①~⑥ 硬断言，全 PASS）**：`warm_glow_strength` `0.22<=0.45`（不更亮）、`fog_density` `0.018<=0.035`（雾不更浓）、层数 `2<=3`、`layer_depths` 最大 `0.80<=0.90`、视差系数逐项 `<=` desktop 对应层、`vignette_strength` `0.12<=0.24`（不更黑）。

---

## 3. 色号依据与降级登记（如实）

- **本轮未降级**：Rank-3 的 `HD2D-STYLE-ANCHOR-v2.md` 已在本轮并发落盘（工程根，与 `TECHNICAL-ART-DEPTH-v060.md` 同级）。采用其 **§5.3 `colors_16`（16 色受控板，v1 §2 真源）** 与 **§2.2 唯一锚点色** `#1B2A4A` / `#C99A3A`（文档明示「供 `depth_profile.tres` 字段逐字引用」），两档色号逐字取锚点并断言相等。
- **真跑佐证**：`R29-run-verify_depth_profile_v070.log` 的 `[R29][ANCHOR]` 行 `exists=true / 不降级 / 采用 ... colors_16（16 色受控板）`；⓪ 断言 `strict_anchor=true / palette=16 色`。
- **降级分支仍在（任务单要求）**：`verify_depth_profile_v070.gd` 运行期 `FileAccess.file_exists` 检查锚点文档；**若尚未落盘**则降级为自带色板常量 —— 工程冻结色板 `godot/assets/generated/palette_256.json` 的 32 色及其 `cold_night_fog` / `warm_gold_key` 语义组，并打印 `[DEGRADE]` 如实登记。本轮真跑未触发该分支。
- **如实纠错登记（不掩盖）**：早期用 Glob `**/HD2D-STYLE-ANCHOR*` 未匹配到工程**根级**文件，一度误判「未落盘」并采用 `palette_256.json` 的 `#2B3A5C` / `#F0A94C`；真跑 `FileAccess.file_exists` 返回 `exists=true` 后复核确认文档确实存在，随即把色号改为 v2 锚点 `#1B2A4A` / `#C99A3A`、暗角 `0.32→0.24` 对齐 v2 §2.3 建议区间，并重写 verify 为「已落盘→v2 板 / 未落盘→降级板」双分支。首版 46 PASS 是在错误色板依据下取得的，**不作为最终结论**；最终结论以修正后重跑的 46 PASS 为准。
- **两套色板不混用**：v2 §5.1 明言 16 色受控板（v1 §2 真源）与 `palette_256.json` 32 色板是「历史两套口径并存、不擅自合并」。本轮按任务单与 v2 指定用前者，后者**仅在降级时**使用。

---

## 4. broken 定义（试玩 / 目视判据，headless 无法判定）

| broken | 定义（画面表现） | 主要嫌疑字段 | 排查方向 |
|---|---|---|---|
| **过暗** | 整体亮度不足、暗部沉进背景、灰度下主体与背景明度差 <2 档、HUD 文字被压暗 | `vignette_strength` ↑ / `fog_density` ↑ / `warm_glow_strength` ↓ | 先降 `vignette_strength`（须仍 ≥0.10 且 ≤0.25 建议区间），再降 `fog_density`，最后小幅抬 `warm_glow_strength`；mobile 尤甚 |
| **过曝** | 暖金区泛白、全屏发亮、冷暖对冲消失、高饱和强调色溢出（超 3 种白名单） | `warm_glow_strength` ↑ | 降 `warm_glow_strength`；确认仍只有 `warm_gold_key` 色族过 bloom 阈，冷雾区不得过阈 |
| **景深分层不可辨** | 远 / 中 / 近三层糊成一片或反差不足，10% 缩略图剪影不可读（v2 J1） | `layer_depths` 跨度太小 / `parallax_coefficients` 梯度太小 / `fog_density` 过高盖住分层 | 拉开 `layer_depths` 层间差、加大 `parallax_coefficients` 梯度（仍须严格递增且 ≤1）、或降 `fog_density`；层数不足时 desktop 回到 3 层 |
| **移动端糊成一片** | `mobile` 档 `480×270` 低分辨率整数放大下，雾/层数/暗角叠合使远景与主体黏连、HUD 文字不可辨（R28B 已实证 low 档缩放伤面板文字） | `mobile` 的 `fog_density` / 层数 / `vignette_strength` 未充分降级 | 继续下调 mobile 的 `fog_density` / `vignette_strength` / 层数；**verify 降级①~⑥ 只保证「不比 desktop 更亮/更糊/更黑」，不能保证目视清晰**，须录屏回看 |

> **归属边界**：以上 4 类 broken 均须 **Rank-4 录屏目视 + 用户人工试玩**判定（v2 §4 J1、§2.3 与 `TECHNICAL-ART-DEPTH-v060.md` §6 口径）。`verify_depth_profile_v070.gd` 的 46 条断言只覆盖「数值 / 结构 / 色板 / 降级关系 / 边界拒绝」，**不冒充画面验收、不谎报 HD-2D 全绿**。

---

## 5. 与既有画质档 `quality_preset_*.tres` 的关系

| 维度 | `quality_preset_desktop.tres` / `quality_preset_mobile.tres` | `render_profiles.tres` | `depth_profile.tres`（本轮新） |
|---|---|---|---|
| 资源类 | `QualityPreset`（`scripts/core/quality_preset.gd`） | `RenderProfiles`（`scripts/core/render_profiles.gd`） | `DepthProfile`（`scripts/render/depth_profile.gd`） |
| 职责 | 渲染**预算与 2D FX 开关**：低分辨率缓冲 / 整数放大 / 常驻 chunk / `volumetric_fog_enabled` / `glow_enabled` / `dust_particle_cap` / `wet_reflection_enabled` / 阴影图 / `target_frame_time_ms` / `memory_limit_mb` | 同一资源内 `desktop_*` / `mobile_*` 前缀的两档映射字段 | 景深 **P1 七参数**两档（层深 / 视差 / 雾密度 / 暗角 / 暖金光晕 / 两色号） |
| 两档口径 | desktop 四项全开、640×360、16.67ms、1536MB；mobile 四项全关、480×270、33.33ms、512MB | desktop 四项 true / mobile 四项 false | desktop 3 层 / mobile 2 层，mobile 各强度更低 |
| 本轮动作 | **只读参考、未改一字** | **只读参考、未改一字** | **新写**（`godot/data/render/` 下第 4 个 .tres） |

**关系要点（正交、互不覆盖）**：

1. **零字段重名、零脚本改动**：`depth_profile.tres` 不复制、不覆盖、不改写 `quality_preset_*.tres` 的 10 个字段，也不改 `quality_preset.gd` / `render_profiles.gd` / `render_profiles.tres`。`project.godot` / 场景 / autoload / shader 本轮一律未动。
2. **职责分层**：`quality_preset_*.tres` 管「渲染预算 + FX 开关」；`depth_profile.tres` 管「景深观感的强度 / 层数 / 色号」，是新增的一层数据，二者由运行时分别读取、互不推导。
3. **mobile 降级同向、不冲突**：`quality_preset_mobile.tres` 把四项 2D FX 全关（减少叠光），`depth_profile.tres` 的 mobile 又降低层数 / 雾 / 暗角 / 光晕 —— 二者叠加让移动端更清爽，正是「mobile 档降级不糊不黑」的实现路径；不存在一处降级、另一处反向加亮。
4. **不重复定义预算**：帧时间（16.67 / 33.33ms）、内存（1536 / 512MB）、缓冲尺寸（640×360 / 480×270）仍由 `quality_preset_*.tres` 单独负责；本资源**不引入**任何帧时间 / 内存 / 缓冲字段，避免双源与数值漂移。
5. **选档约定（本轮不接线）**：建议运行时按既有 `QualitySettings` 画质档 `low→mobile` / `high→desktop` 取对应子资源；档位判定仍归既有画质体系，本轮只交付数据源与校验，**不改任何接线代码**。
6. **数值对齐**：`fog_density` 以工程 `Environment.fog_density=0.02` 为基线微调（desktop 0.035 / mobile 0.018），与 `quality_preset` 的 `glow_enabled=false`（mobile）同向；`quality_preset` 的 `volumetric_fog_enabled / glow_enabled` 是**自定义 FX 开关**（`TECHNICAL-ART-DEPTH-v060.md` §1 澄清），与 `Environment` 的 3D 属性无关 —— 本轮参数亦全部落在 2D 近似层，不谎称真 3D 光效。

---

## 6. 真跑自测结论（引用，详见 `DONE-R29.md`）

- `verify_depth_profile_v070.gd`：**46 PASS / 0 FAIL / `RESULT=PASS` / `EXIT=0`**（`R29-run-verify_depth_profile_v070.log`）。
- 三段门禁：`--headless --import`（新增 `class_name DepthProfile` 已注册 `global_script_class_cache.cfg:51`）→ `--check-only --script` + `--script` 真跑 → `--headless --quit`，**四段 EXIT 全 0**，逐段 `grep -cE "SCRIPT ERROR|Parse Error"` = **0**（`R29-gate*.log`）。
- 色板：`[ANCHOR]` 未降级，采用 v2 16 色受控板 + 逐字锚点色。
- 边界：负强度 / 超 1 系数 / 空表 / 字段缺失共 12 类非法构造，全部经 `is_valid()` 返回 `false` 且未抛异常、未崩溃。

---

## 7. 未完成 / 阻塞 / 如实边界

1. **所有数值 `[PLACEHOLDER]` 首版，待人工试玩校准**（用户侧）。本文只给假设表与 rationale，不冒充已校准。
2. **Rank-4 shader / `hd2d_parallax.gd` 真机读取接线未做**：本轮只交付数据源 + 结构 + 校验，读取接线属 Rank-4 所有权，不越界。
3. **未做 15~20 秒实机录屏回看**：本轮为 headless 数据 / 门禁任务，无渲染管线可录；§4 的 4 类 broken 画面判定归 Rank-4 录屏目视 + 用户试玩，不伪造画面证据。
4. **未触发降级分支**：锚点文档本轮已落盘，降级常量（`palette_256.json` 32 色）保留但真跑未使用；若后续文档被移走，verify 会自动降级并打印 `[DEGRADE]`。
5. **未改 / 未写**：`hud.gd` / `presentation.gd` / 场景 / shader / 素材 / 契约 / README / `project.godot` / 既有 `quality_preset_*.tres` / `render_profiles.tres` / 既有战斗件；**未自行 git**。零付费、零外部依赖、未启 GPU job、未新建只读探针 / 巡检脚本（verify 是正式自测件）。
6. `R29-gate3-quit.log` 中出现的 `[R29][SHOP] 兑换面板迁出 SubViewport ...` 等日志为**其它工位并发改动**，非本轮所为，如实登记。
