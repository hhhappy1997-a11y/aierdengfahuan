# ART-SPEC-FINAL.md · 美术规格终稿（Rank-4 R9 交付 · 为 `00-汇总.md` 准备）

> 轮次：**R9（占位画面运行期自检与汇总材料）**｜派单：`cmd-20261109-033148-270-A4`｜工位：Rank-4 美术管线与工具链
> 定位：**汇总材料** —— 把「128px 基准画布 / ≤256 色索引调色板 / 装饰 RGBA 逐像素对齐」三项已冻结规格整理成一份可直接被 `00-汇总.md` 引用的终稿。
> 口径来源：`HD-2D视觉规范.md` §2 / §6 / §10、`palette_256.json`、`import.json`、`资产交付契约.md` §2 / §4 / §5 / §8、`R4-验收记录.md` §4、`00-协作契约.md` §9.3。
> **不新增口径、不改冻结值、不替代既有件**：本文件只做整理与引用；既有冻结件一律保持原样。工程根 `project.godot` / `scenes\` 归 Rank-1 独占，本轮未改一个字节。
> 本轮真跑核对结论见 `DONE-R9.md` §2：规格字段口径 **24/24** 内联 python 真跑通过、落位 **4/4** + 独立 **10/10** + 内嵌 **16/16** 全部 `json.load` / `json.loads` 通过。

---

## 0. 速览（给 `00-汇总.md` 的一句话）

| 项 | 冻结值 | 权威件 |
|---|---|---|
| 生成端设计基准画布 | `canvas_base_px = 128` | `import.json` / `palette_256.json::spec` |
| 全项目索引调色板 | `hd2d_index_256_v1`；`indexed=true` / `max_colors=256` / 当前冻结 `color_count=32` | `palette_256.json` |
| 单角色色数 | ≤ 16 色，取色限 32 色共享板 | `HD-2D视觉规范.md` §2.2 / §6 |
| 交付端单帧 | `32×32 px`，Point 降采样，底部中心锚点 `(16,31)` | `import.json` / `资产交付契约.md` §2 |
| 装饰 RGBA 对齐 | 生产阶段逐像素对齐、禁止运行时偏移校准 | `资产交付契约.md` §4 / `R4-验收记录.md` §4 |
| Godot 导入四项 | `lossless` / 关 mipmaps / `Nearest` / 项目级 `default_texture_filter=0` | `import.json::expected_import_settings` / `00-协作契约.md` §5 |

---

## 1. 128px 基准画布（三层尺寸关系，互不覆盖）

| 层级 | 值 | 归属 | 说明 |
|---|---|---|---|
| ① 生成端设计基准画布 | **128 px** | 4 号（出图规格） | `canvas_base_px=128`；本地 ComfyUI / `qwen-image` 备选出图的设计基准 ≥128px，避免 1024px 直接降到 32px 糊掉（对齐 `00-工具链接入说明.md` §4.1「设计显示尺寸 ≥128px」） |
| ② 低分辨率渲染缓冲 | 640×360，整数倍 2x/3x/4x Nearest 放大 | 1 号落地 | 工程 `project.godot` 实际 `render/integer_upscale_factor=2`、窗口 1280×720；`courtyard.tscn` / `Main.tscn` 的 `SubViewport` 为 640×360、`stretch_shrink=2` |
| ③ 交付端单帧尺寸 | **32×32 px** | 4 号（资产契约） | `frame_width/height=32`、`downsample.target_size=[32,32]`、`filter=Point` / `colors=16` / `dither=None` |

> 三者是「设计基准 → 渲染缓冲 → 交付帧」的不同层级；**128px 是生成端基准，不是把交付帧改成 128px**，也不改 640×360 渲染缓冲（`HD-2D视觉规范.md` §10.2 已冻结）。
> 角色 32×32 px 上下左右各留 2px 透明安全边（实际绘制区 28×28）；锚点底部中心 `(16,31)` 脚贴地、全帧共用，禁止逐帧偏移。
> **`128bit` 原词歧义仍登记在 `README.md` 待裁决**：落地按「128px 基准画布 + 256 色索引调色板」理解（契约 §9.3 / `palette_256.json::pending`），**不自行改口径**；若与用户本意不符以用户为准。

---

## 2. ≤256 色索引调色板（全项目共用一份）

### 2.1 冻结参数（`palette_256.json`）

| 键 | 冻结值 |
|---|---|
| `palette_id` | `hd2d_index_256_v1` |
| `spec.canvas_base_px` | `128` |
| `spec.indexed` | `true` |
| `spec.max_colors` | `256`（索引容量上限） |
| `spec.color_count` | `32`（当前冻结色数） |
| `spec.encoding` | `hex6 uppercase #RRGGBB` |
| `version` / `status` | `r2.0` / `frozen_temporary_R2` |

- **32 色功能板**，与 `HD-2D视觉规范.md` §2.2 逐字一致、去重；本轮真跑核对 `len(colors)==32`、全为 `#RRGGBB`、去重后仍 32。
- **8 个语义组覆盖索引 0~31 完整**：`warm_gold_key`(0~4)、`cold_night_fog`(5~10)、`deep_blue_ui`(11~14)、`gold_line`(15~17)、`stone_earth`(18~22)、`vegetation`(23~26)、`ui_text`(27~29)、`status`(30~31)。
- **明度阶梯 L0~L8**：`luma_l0_l8` 的 hex 与 index 均落在 `colors` 内（本轮真跑 9/9 一致）；灰度模式下角色（L6~L8）与背景（L1~L4）须跨越 ≥2 级、10% 缩放剪影可辨。
- **源 / 落位一致**：`Rank-4\palette_256.json` 与工程根 `godot\assets\generated\palette_256.json` **逐键一致**（本轮真跑 `True`）。

### 2.2 取色与收敛规则

| 规则 | 内容 |
|---|---|
| 引用方式 | 每个 `import.json` 用 `palette_id` 引用本板，`palette` 数组只列本资产实际取用色号 |
| 子集校验 | `palette ⊆ palette_256.json.colors`，且 `len(palette) ≤ 16`（单角色） |
| 降采样收敛 | `downsample.colors=16` 收敛后色号仍须属于本板 |
| 扩展新色 | 须主 AI 裁决后统一并入，**单资产不得私加** |
| 工具边界 | `image/quantize.py` 是 **DiT 权重量化器（int8/nf4）**，**不是** 256 色板量化器；调色板收敛走 **ComfyUI 主管线 + Aseprite / ImageMagick**，绝不混用（`00-工具链接入说明.md` §4.1、`R4-验收记录.md` §2） |

> 唯一的 bloom 过阈色族是 `warm_gold_key`（暖金主光）；冷夜雾区亮度不得过阈，否则冷暖对比失效。

---

## 3. 装饰 RGBA 逐像素对齐规范（硬约束）

> 结论：**对齐是生产阶段的责任，不是运行时的工作**。1 号只做叠加，禁止任何运行时偏移校准（`资产交付契约.md` §4、`HD-2D视觉规范.md` §6 / §8）。

### 3.1 九条逐项判据

| # | 约束 | 校验方式 |
|---|---|---|
| 1 | 尺寸一致 | `frame_width` / `frame_height` / `columns` / `rows` / `frame_count` 与 base 完全相同 |
| 2 | 帧序一致 | 第 N 帧装饰对应第 N 帧 base，`actions` 的 `start_frame` / `end_frame` / `fps` / `loop` 完全相同 |
| 3 | 坐标系一致 | 同一 `anchor`（`{x:16, y:31}`）、同一原点、同一帧网格，禁止逐帧偏移 |
| 4 | seed 一致 | 装饰层 `seed` 必须**等于** base 的 `seed` |
| 5 | 降采样参数一致 | `downsample.filter` / `colors` / `dither` / `target_size` 完全相同（Point / 16 / None / 32×32） |
| 6 | 非装饰区全透明 | mask 外 alpha 必须为 `0`（`(0,0,0,0)`）；`RGBAAlphaMask` 强制；不得有半透明脏边 |
| 7 | 色板一致 | 装饰层取色限共享 32 色板，与 base 不冲突 |
| 8 | `aligned_with` 必填 | 指向 base 的 `res_path`；缺字段直接判不合格退回 |
| 9 | **禁止运行时校准** | 1 号不得为装饰层加 offset / pivot 补偿；若叠加出现 1px 偏移，判装饰层**重做**，不在引擎侧打补丁 |

### 3.2 叠加顺序与逐像素比对方法

- 叠加顺序（从下到上）：`base` → `cloth` → `hair` → `eyes`；同帧同坐标直接相加，不缩放、不旋转、不平移。
- 逐像素比对：两张同尺寸 RGBA 逐通道比对，记录不一致像素坐标与数量；非装饰区须与 base 对应区一致且 alpha=0；判据见 `R4-验收记录.md` §4。
- 退回条件（任一命中即整批次退回）：JSON 解析失败 / 字段缺失、`aligned_with` 缺失、`pose_names` 与 `actions` 不一致、帧尺寸不等宽、脚底 Y 漂移、非透明区有杂边、色数 > 16、色号不在共享板内、seed / 降采样 / 尺寸 / 帧序任一不一致、主角 / Boss / 关键场景 `human_refine != "done"`（契约 §6.3）。

### 3.3 当前状态（如实，不臆造）

- 工程根 `godot\assets\generated\` 下**真实 PNG = 0**、真实 `.import` 元数据 = 0、品类子目录 = 0；`Rank-4\*.png` = 0。
- 因此「装饰层与 base 逐像素对齐抽检」**无对象、无法执行**，本轮**不伪造**「已对齐 / 不一致像素数=0」之类结论；判据与路线（`R4-验收记录.md` §4）沿用不改，待首批合规 PNG 落地后执行。
- 装饰层底稿可由 ComfyUI 主管线 LayerDiffuse 产出，或 `qwen-image` 本地备选产出；`import.json` 对齐字段口径本轮已 24/24 真跑核对通过（字段级，非像素级）。

---

## 4. Godot 导入四项设置（4 号声明期望值，1 号落地）

| 设置 | 期望值 | 责任 |
|---|---|---|
| `compress_mode` | `lossless`（无损） | 1 号落地 |
| `mipmaps` | `false`（关闭） | 1 号落地 |
| `texture_filter` | `Nearest` | 1 号落地 |
| 项目级 `default_texture_filter` | `0`（Nearest） | **1 号落地**（契约 §5）；Godot 4 合法键为 `textures/canvas_textures/default_texture_filter` |
| `fix_alpha_border` | `true` | 1 号落地，防透明边杂色 |
| `process_fix_alpha_border` | `true` | 1 号落地 |
| `srgb` | `disabled_or_as_configured_by_engine` | 1 号落地 |
| 像素化后处理 | 640×360 低分辨率缓冲 + 整数倍 Nearest 放大 | 1 号落地（视觉规范 §3） |

**本轮实际生效核对（只读，不夸大）**：

- 项目级 `godot\project.godot:141` 实际 `textures/canvas_textures/default_texture_filter=0` 与 `import.json` 期望值一致（本轮真跑 `True`）；`render/integer_upscale_factor=2` 已落地。
- `godot\scripts\render\hd2d_placeholder_attach.gd:44` 的 `placeholder.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST` 为真实代码落地；`courtyard.tscn` 占位节点 `texture_filter = 1`（TEXTURE_FILTER_NEAREST）、`integer_scale = 2`。
- **无法实测、如实登记**：`lossless` / 关 `mipmaps` / `Nearest` 对**真实纹理**的运行时导入生效 —— 工程根真实 PNG = 0、真实 `.import` 元数据 = 0，两份 `import.json` 均 `sample_only=true` 字段样例，其 `expected_import_settings` 是**期望值**而非运行时实测值。本轮**不夸大**「已在真实纹理上生效」，该实测随首批合规 PNG 资产落地后由 1 号导入时完成。
- 4 号**不改** Godot 工程设置、不写 `.gd` / `.tscn`；`expected_import_settings` 只是核对基准，差异由 1 号反馈、冲突写进 `README.md`「待主 AI 裁决」。

---

## 5. 本轮真跑核对结论（引用 `DONE-R9.md` §2，不重复造数）

| 分组 | 结论 |
|---|---|
| 落位 JSON | `delivery_manifest.json` / `import.json` / `palette_256.json` / `pose_names.json` **4/4** `json.load` 通过 |
| 独立 JSON | `Rank-4\*.json` **10/10** 通过 |
| 内嵌 JSON 围栏 | `Rank-4\*.md` 行首 ```json 块 **16/16** `json.loads` 通过 |
| 规格字段口径 | **24/24** 通过（128px / 四项导入 / 32 色板 / 语义组 / luma / 32×32 帧 / anchor / downsample / pose / sample_only / fallback 等） |
| 源 = 落位 | `palette_256.json` 逐键一致 `True` |
| 工程实际 | `project.godot` 三项 `True`、`courtyard.tscn` 22 节点占位结构 `True`、占位脚本零外部依赖 / 无写回 `True` |

> 本文档与 `I5-DELIVERY-CHECKLIST.md` / `DONE-R9.md` 的所有代码块均用 `text` / `gdscript` 标记、**不含行首 ```json 围栏**，故写完复核内嵌 JSON 块仍为 **16/16**（口径自洽，与 `DONE-R6` ~ `DONE-R8` 一贯做法一致）。

---

## 6. 待裁决 / 未决项（只登记，不擅改）

| # | 项 | 状态 |
|---|---|---|
| 1 | `128bit` 确切含义（128px 画布 vs 位宽 / 色深） | 登记在 `README.md` 待裁决，暂按 128px 理解，不自行改口径 |
| 2 | `import.json::palette_ref` 的 `_palette/` 子路径与实际平级落位差异 | 该件 `sample_only=true` 字段样例，登记为「1 号导入时对齐」，不擅改冻结字段 |
| 3 | 设计基准分辨率 / 像素→米缩放比 / 自定义 AABB | `HD-2D视觉规范.md` §9 / §10.3 标为「待 HOST 转交」，不臆造数字 |
| 4 | 占位画面挂载点 / 缩放 / 遮挡顺序 4 项取舍 | `scene_integration.md` §4 登记为 Rank-1 裁决点（既有 `_apply_integer_scale()` clamp 2~4 无法设 1、`SubViewport` 内放大出界、不透明 3D 背景遮挡顺序），不擅改 |
| 5 | `prompt_skeleton.json::seed_lock.action_offset` 与 R2 冻结枚举不一致 | `资产交付契约.md` §8.5 登记为待回改，须 HOST 裁决后整体升 `v2`，不擅改 |

---

## 7. 合规声明

- 只写 `Rank-4\`（本文档、`I5-DELIVERY-CHECKLIST.md`、`DONE-R9.md`）+ 回执例外 `teamwork\command_center\ai\4\outbox\`；**未写 `godot\project.godot`、未写 `godot\scenes\`**、未写其它工位 / 总线 / 总纲 / 契约 / 任务书，未自行 `git commit` / `git push`。
- 既有件（`HD-2D视觉规范.md`、`资产交付契约.md`、`R4-验收记录.md`、`palette_256.json`、`import.json`、`courtyard.tscn`、`project.godot`、占位 `.gd`）一律**引用、不重做、一个字节未改**。
- 零付费 / 零外部依赖；付费 API 一律禁用；`stable-audio`（gated 403）/ `gen3d` / `mia-rig` 不申请、不补装、不碰 WSL、不绕过。
- **ComfyUI 仍是主美术路线**；`qwen-image` 仅本地零付费备选（本轮判长期阻塞）；程序化 `_draw()` 占位为零外部依赖兜底，不取代主路线、不宣称占位为正式素材。
- 中文 UTF-8；所有独立 JSON 与文档内嵌 `json` 围栏块合法可解析；**不伪造画面 / 截图 / 校验数据、不宣称已能出图、不夸大纹理级导入已生效**。
