# I5-DELIVERY-CHECKLIST.md · I-5 资产交付清单（Rank-4 → Rank-1 · R9 交付 · 为 `00-汇总.md` 准备）

> 轮次：**R9（占位画面运行期自检与汇总材料）**｜派单：`cmd-20261109-033148-270-A4`｜工位：Rank-4 美术管线与工具链
> 定位：契约 I-5（4 → 1）的**资产交付清单 + 验收口径 + 出图长期阻塞结论**，供 `00-汇总.md` 与 1 号导入时直接核对。
> 口径来源：`00-协作契约.md` §3 / I-5、`资产交付契约.md` §1 ~ §6 / §8、`import.json`、`palette_256.json`、`HD-2D视觉规范.md`、`DONE-R8.md` §1.3、`00-工具链接入说明.md` §6 / §7。
> **如实前置（最重要）**：本清单是「交付规格与验收口径」，**当前不是「已交付资产」** —— 工程根 `godot\assets\generated\` 下真实 PNG = **0**、品类子目录 = **0**、真实 `.import` 元数据 = **0**；4 份 JSON 均为规格落位件 / 字段样例（`sample_only=true`）。本轮不伪造资产、不宣称已能出图。

---

## 0. 速览

| 项 | 结论 |
|---|---|
| I-5 最小交付单元 | **1 张 RGBA PNG + 1 个同级 `import.json`**；批次用 1 个 `delivery_manifest.json` 汇总 |
| `assets/generated/` 品类 | 固定 **6 个**（`chars` / `decor_layers` / `fx` / `bg_layers` / `props` / `ui`）+ 2 个辅助目录（`_style_anchor` / `_pose`） |
| `import.json` 全字段 | **31 键**（契约 §2 的 24 字段 + R2 §8 新增 6 字段 + 1 个 `r2_note` 说明键） |
| Godot 导入四项 | `lossless` / 关 mipmaps / `Nearest` / 项目级 `default_texture_filter=0`（4 号声明期望值、1 号落地） |
| 出图状态 | **长期阻塞**（本轮 `142.2` 分钟无新增，R8 为 `115.9` 分钟）；程序化 `_draw()` 占位为正式零依赖兜底，**ComfyUI 仍是主美术路线** |
| 当前实际资产 | **0 张 PNG、0 品类子目录**；清单为「待首批资产」状态 |

---

## 1. I-5 接口与三件套

| 编号 | 提供方 → 消费方 | 契约内容 |
|---|---|---|
| I-5 | 4 → 1 | 4 号交付 `assets/generated/<品类>/` 下 spritesheet + `import.json`（帧尺寸 / 锚点 / 帧数 / 动作名），1 号按清单导入 |
| I-4 | 1 → 2 | 1 号封装 `Hybrid2D3DAnimatedSprite`，2 号只调 `set_pose(pose_name, frame_index)`（本清单的 `pose_names` 注册到此处） |

每次交付，4 号向 1 号提供以下三项（缺一不可，契约 §6）：

| # | 交付物 | 格式 | 1 号的动作 |
|---|---|---|---|
| 1 | `res://assets/generated/<品类>/*.png` | RGBA PNG32 帧条 | 按 `import.json` 切帧，注册进 `SpriteFrames` / `Hybrid2D3DAnimatedSprite` |
| 2 | 同级 `*.import.json` | 合法 JSON，字段见 §3 | 读 `frame_width/height/columns/rows/anchor/actions/pose_names`，把 `pose_names` 注册到 I-4 的 `set_pose(pose_name, frame_index)` |
| 3 | `delivery_manifest.json` | 合法 JSON，`items[]` 逐项列出 | 按 `items[]` 批量导入；`layer_type=decor` 的按 `aligned_with` 叠加 |

> 每次交付附带的说明（契约 §6.1）：批次 id / 里程碑 / 品类 / 档位与降级路线 / 本批次资产数 / 哪些是 AI 底稿、哪些已人工精修 / 需 1 号核对的期望导入值 / 已知未完成项 / 风格锚点版本。
> 4 号**不产出** `.gd` / `.tscn` / `.tres`（属 1 号）；不写 Godot 工程根目录之外任何文件；路径一律 `res://` + snake_case。

---

## 2. `assets/generated/` 品类与目录规范

### 2.1 冻结的目录结构（契约 §1）

```text
res://assets/generated/
├── _style_anchor/            ← 全项目唯一风格锚点图 style_anchor.png，任何批次不得替换
├── _pose/                    ← 共享 OpenPose 骨架库 <action>_<frame>.json，跨角色复用
├── chars/                    ← 角色 / 敌人 / Boss 基础帧条
│   └── _pose/                ← （可选）chars 专用骨架副本
├── decor_layers/             ← hair / eyes / cloth 独立 RGBA 装饰层
├── fx/                       ← 光尘 / 打击 / 赐福 / 体积光贴图
├── bg_layers/                ← 7 层视差背景（bg_0_sky ~ fg_0_occl）
├── props/                    ← 道具 / 环境瓦片 / 碎石
├── ui/                       ← 九宫格 / 角饰 / 图标 / 分隔线
└── delivery_manifest.json    ← 当前批次总清单（每批次一份，批次 id 唯一）
```

| 规则 | 说明 |
|---|---|
| 品类固定 6 个 | `chars` / `decor_layers` / `fx` / `bg_layers` / `props` / `ui`，**不新增品类**；需新增报主 AI 裁决 |
| 三件套 | 每个 spritesheet = 1 个 `RGBA PNG` + 1 个**同级同名** `import.json`；批次 1 个 `delivery_manifest.json` |
| 路径 | 一律 `res://assets/generated/<品类>/<文件>`，snake_case，禁止中文 / 空格 / 大写 / 连字符 |
| 命名 | PNG / import.json 形如 `<subject>_<action>_v1.png` / `<subject>_<action>_v1.import.json`；装饰层 `<subject>_<layer>_<action>_v1.png`（`layer` ∈ `hair` / `eyes` / `cloth`）；背景层 `bg_<index>_<slug>_v1.png` |
| `asset_id` | `<品类短名>_<两位序号>_<slug>_<版本>`，全局唯一 |
| 批次 id | `batch_<YYYYMMDD>_<milestone>_<品类>` |
| 版本 | 文件名带 `_vN`；同资产迭代升 `_vN+1`，**不覆盖旧版**，便于回滚与复核 |
| 帧条形态 | 形态 A（M0 推荐）：单动作横向帧条 `rows=1`；形态 B（M2+ 合表）：多动作按行，`start/end_frame` 用全局线性索引 `row*columns+col` |

### 2.2 当前工程根实际（只读，如实）

```text
godot/assets/generated/ 目录下（2026-11-09 03:36 只读快照）：
  delivery_manifest.json    dict(20)   规格落位件
  import.json               dict(31)   字段样例 sample_only=true
  palette_256.json          dict(12)   32 色索引调色板规格
  pose_names.json           dict(14)   冻结 pose 名表
  品类子目录数 = 0   真实 PNG = 0   真实 .import 元数据 = 0
```

> 即：上述 6 品类目录目前**尚未建立**（无首批合规 spritesheet），4 份 JSON 是**规格 / 字段样例**，不是 I-5 资产交付。真实资产的切帧、装饰层叠加、逐像素对齐抽检随首批 PNG 落地后执行，见 `ART-SPEC-FINAL.md` §3.3 与 `R4-验收记录.md` §2 / §4。

---

## 3. `import.json` 全字段（31 键）

> 权威定义：`资产交付契约.md` §2（首轮 24 字段）+ §8.1（R2 新增 6 字段）；当前 `Rank-4\import.json` / `godot\assets\generated\import.json` 均为 **31 键字段样例**（`sample_only=true`）。真实资产删去 `sample_only` 或置 `false`，并按 §2 命名落 `<name>_vN.import.json`。

| # | 字段 | 类型 | 必填 | 说明 / 冻结值 |
|---|---|---|---|---|
| 1 | `schema_version` | string | ✅ | 契约版本，当前 `"1.0"` |
| 2 | `asset_id` | string | ✅ | `<品类短名>_<序号>_<slug>_<版本>`，全局唯一 |
| 3 | `res_path` | string | ✅ | `res://` 开头的 PNG 路径 |
| 4 | `sprite_sheet` | string | ✅ | PNG 文件名（含扩展名） |
| 5 | `frame_width` | int | ✅ | 单帧宽，角色固定 `32` |
| 6 | `frame_height` | int | ✅ | 单帧高，角色固定 `32` |
| 7 | `columns` | int | ✅ | 帧条列数 |
| 8 | `rows` | int | ✅ | 帧条行数（单动作帧条为 `1`） |
| 9 | `frame_count` | int | ✅ | 有效帧数，≤ `columns * rows` |
| 10 | `anchor` | object | ✅ | `{"x":16,"y":31}` 底部中心脚贴地；全帧共用，禁止逐帧偏移 |
| 11 | `actions` | array | ✅ | 每项 `{name, start_frame, end_frame, fps, loop}`；帧索引为全局线性 `row*columns+col` |
| 12 | `pose_names` | array[string] | ✅ | 与 `actions[].name` 一致；取自 `pose_names.json::all_frozen_names`（22 个），**不得出现清单外的名字** |
| 13 | `palette` | array[string] | ✅ | 实际取用色号 hex；必须 ⊆ `palette_256.json.colors` 且 ≤ 16 色/角色 |
| 14 | `canvas_base_px` | int | ✅ | **R2 新增**：固定 `128`（生成端设计基准画布），不改 `frame_width/height=32` |
| 15 | `palette_id` | string | ✅ | **R2 新增**：固定 `hd2d_index_256_v1` |
| 16 | `palette_ref` | string | ✅ | **R2 新增**：调色板路径；样例写 `res://assets/generated/_palette/palette_256.json`，与实际平级落位差异登记为「1 号导入时对齐」 |
| 17 | `pose_prefix_in_use` | string | ✅ | **R2 新增**：本表实际使用的前缀 `p1_` 或 `p2_` |
| 18 | `phase2_pose_prefix` | string | ✅ | **R2 新增**：阶段切换对应的另一前缀，不扩展 I-4 接口 |
| 19 | `layer_type` | string | ✅ | `base` / `decor` / `bg` / `fx` / `ui` |
| 20 | `aligned_with` | string\|null | 装饰层必填 | 装饰层填对应 base 的 `res_path`；非装饰层填 `null`；缺字段直接退回 |
| 21 | `seed` | int | ✅ | 由 `prompt_skeleton.json::seed_lock.derivation` 派生；**装饰层必须与 base 完全相同** |
| 22 | `downsample` | object | ✅ | `filter` / `colors` / `dither` / `target_size`；冻结 `Point` / `16` / `None` / `[32,32]`，装饰层须与 base 一致 |
| 23 | `expected_import_settings` | object | ✅ | 4 号声明**期望值**（见 §4），由 1 号在工程侧落地并核对 |
| 24 | `pipeline_tier` | string | ✅ | `A` / `B` / `C` / `D`（`美术管线.md` §7） |
| 25 | `fallback_route` | string | ✅ | `none` / `single_frame_hand_interpolation` / `procedural_draw_placeholder` |
| 26 | `prompt_skeleton` | string | ✅ | 固定骨架 id，当前 `hd2d_pixel_skeleton_v1` |
| 27 | `human_refine` | string | ✅ | `required` / `done` / `not_required`；**主角 / Boss / 关键场景必须 `done` 才允许交付** |
| 28 | `sample_only` | bool | 样例必填 | **R2 新增**：`true` = 字段演示样例、非真实交付；真实资产删去或置 `false` |
| 29 | `r2_note` | string | 样例 | R2 字段样例说明（128px 与 32px 层级关系、`sample_only` 定位等） |
| 30 | `generated_at` | string | ✅ | `YYYY-MM-DD` |
| 31 | `version` | string | ✅ | 与文件名 `_vN` 一致 |

> 本轮真跑核对（`DONE-R9.md` §2 [D]）：31 键 JSON `dict(31)` 合法、四项导入期望值 / 128px / 32×32 帧 / anchor / downsample / pose 子集 / palette 子集 / `sample_only` / `fallback_route` 等 **24/24** 口径通过；`import.pose_names` 4/4 全在冻结表（22 个名字内）。

---

## 4. Godot 导入四项设置（4 号声明期望值，1 号落地）

| 设置 | 期望值 | 责任 |
|---|---|---|
| `compress_mode` | `lossless`（无损） | 1 号落地 |
| `mipmaps` | `false`（关闭） | 1 号落地 |
| `texture_filter` | `Nearest` | 1 号落地 |
| 项目级 `default_texture_filter` | `0`（Nearest） | **1 号落地**（契约 §5）；Godot 4 合法键 `textures/canvas_textures/default_texture_filter` |
| `fix_alpha_border` | `true` | 1 号落地，防透明边杂色 |
| `process_fix_alpha_border` | `true` | 1 号落地 |
| `srgb` | `disabled_or_as_configured_by_engine` | 1 号落地 |
| 图集分组 | 同品类 + 同动作优先合图集；`bg_layers` 单独分组 | 1 号定，4 号在 manifest 备注 |
| 像素化后处理 | 640×360 低分辨率缓冲 + 整数倍 Nearest 放大 | 1 号落地（视觉规范 §3） |

**实际生效核对（只读，分层、不夸大）**：

- 项目级 `godot\project.godot:141` 实际 `textures/canvas_textures/default_texture_filter=0` 与 `import.json` 期望值一致（本轮真跑 `True`）；`render/integer_upscale_factor=2` 已落地。
- `godot\scripts\render\hd2d_placeholder_attach.gd:44` 的 `placeholder.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST` 为真实代码落地；`courtyard.tscn` 占位节点 `texture_filter = 1`、`integer_scale = 2`。
- **纹理级运行时导入生效无法实测**：工程根真实 PNG = 0、真实 `.import` 元数据 = 0（Godot 未对任何纹理生成导入元数据），两份 `import.json` 均 `sample_only=true` 字段样例。本轮**不夸大**「已在真实纹理上生效」，该实测随首批合规 PNG 落地后由 1 号导入时完成。
- 口径纠正如实登记：任务书字面 `default_texture_filter=0`，Godot 4 合法键为 `textures/canvas_textures/default_texture_filter`（`project.godot` 头注释 / R6 §2.2 已纠正，历史误写 `canvas_items` 不写回）。4 号**不改**工程设置、不写 `.gd` / `.tscn`。

---

## 5. 1 号的验收动作与退回条件（契约 §6.2 / §6.3）

**验收动作（真跑，不写探针）**：

1. 按 `delivery_manifest.json` 导入全部 PNG，确认无导入报错。
2. 读一张 `import.json`，按 `columns/rows/frame_width/frame_height` 切帧，确认帧数与 `frame_count` 一致。
3. 把角色放到 3D 地面，确认**脚贴地**（anchor `(16,31)` 生效）、像素清晰无锯齿、无 z-fighting。
4. 调一次 `set_pose("walk", 2)`，确认停在 walk 第 2 帧（I-4 通路打通）。
5. 叠一个 `decor` 层，确认**无 1px 偏移**、非装饰区完全透明；如有偏移，退回 4 号重做，不在引擎侧补偿。
6. 核对 `expected_import_settings` 与工程实际值，差异写回 4 号记录。

**退回条件（任一命中即整批次退回）**：JSON 解析失败或字段缺失；`aligned_with` 缺失（装饰层）；`pose_names` 与 `actions` 不一致；帧尺寸不等宽、脚底 Y 漂移、非透明区有杂边、色数 > 16、色号不在共享板内；装饰层与 base 的 seed / 降采样 / 尺寸 / 帧序任一不一致；主角 / Boss / 关键场景 `human_refine != "done"`；出现任何付费素材 / 外部生成服务产物，或来源 / seed / 版本号标注缺失。

---

## 6. 出图长期阻塞结论（本轮终态判定）

### 6.1 单一出图 job 只读验收（本轮实际输出，见 `DONE-R9.md` §2）

```text
Rank-4 *.png                 = 0（No such file）
asset_proof_stdout.txt       = 0 字节，mtime 2026-11-09 01:05:48
asset_proof_stderr.log       = 25320 字节，mtime 2026-11-09 01:21:30
stderr 末行                  = Loading checkpoint shards:  50%|█████     | 1/2 [05:35<05:35, 335.95s/it]
报错类关键字命中行数          = 0
完成类关键字命中行数          = 0
本轮检查时刻                  = 2026-11-09 03:43:40
无新增时长                    = 142.2 分钟（R8 为 115.9 分钟，持续恶化）
```

- 单一后台 `qwen-image --quant nf4` 出图 job 停在 `transformer checkpoint shards 50%(1/2)` 加载，**权重 `750/750` 已加载完但未进入去噪 / 写图**；stdout 0 字节 → `--json` 结果对象（timing / peak VRAM / 输出路径）未产生。
- **不是崩溃、也不是完成**：无 `Traceback` / `Error` / `OOM` / `Killed`，是首次全量 30.84 GiB 权重 `--quant nf4` 逐片量化 + CPU offload 的极慢加载 → **登记为长期阻塞**（`DONE-R8.md` §1.3 已终态判定，本轮 142.2 分钟进一步确认）。
- **未启动第二个 GPU job、未杀 / 未重启 / 未并行**现有 job；本轮所有 Godot 调用均为 `--headless` 静态语法门禁 / 场景实例化，非 GPU 出图 job。最终结果仍以 `asset_proof_stdout.txt` / `asset_proof_stderr.log` 为准，本轮不回头改写、不谎报。

### 6.2 明确结论：程序化 `_draw()` 占位为正式零依赖兜底，ComfyUI 仍主路线

在「`qwen-image` 出图长期阻塞 + ComfyUI 本机路径与工作流 JSON 仍未登记」的双重现状下（沿用 `DONE-R8.md` §1.3，本轮 R9 引擎门禁与场景实例化再次验证）：

- **正式确立** `godot\scripts\render\hd2d_placeholder.gd` 的程序化 `_draw()` 占位为工程内唯一可真实运行、零外部依赖的正式兜底画面方案：单次 `_draw()` 按 10 步绘完 9 视差层 + 湿地倒影 / 体积光 / 光尘 / bloom / 32×32 像素实体 / 金线深蓝 UI；零外部依赖（本轮真跑核对：无 `load/preload res://`、无 `ResourceSaver` / `FileAccess` 写回）；`hd2d_placeholder_attach.gd` 三静态方法、幂等、仅 `load()` 工程内 `.gd`。
- 本轮 R9 引擎真跑：两段 `--check-only --script` 门禁 `EXIT=0 / SCRIPT ERROR=0`；`--headless --quit` 与直接运行 `courtyard.tscn` 均 `EXIT=0 / SCRIPT ERROR=0`（仅 2 条 `ObjectDB leaked` WARNING，非 ERROR）；`courtyard.tscn` 22 节点含 `HD2DPlaceholderLayer(-10)` → `HD2DPlaceholder(Nearest / integer_scale=2 / script=hd2d_placeholder.gd)`。
- **兜底正式化 ≠ 主路线变更**：**ComfyUI 仍是主美术路线**（契约 §9.3 / `00-工具链接入说明.md` §6）；`qwen-image` 仅为同为零付费的本地备选、本轮判长期阻塞；程序化 `_draw()` 是兜底路线正式化，**不宣称占位为正式素材**、不取代 ComfyUI。`import.json::fallback_route` 已登记 `procedural_draw_placeholder`，`scene_integration.md` §0 / `DONE-R7.md` §5 / `DONE-R8.md` §1.3 一以贯之。
- **退出条件**（`scene_integration.md` §4）：`assets/generated/bg_layers/` 与 `chars/` 有首批合规 spritesheet 且 1 号完成纹理层接入后，调用 `HD2DPlaceholderAttach.detach(root)` 移除背景层、逐层替换为 `draw_texture_rect()` / Sprite；`placeholder_enabled` 保留为调试开关。
- **本结论不等于**「已能出图」「场景已渲染可见」「真实纹理导入已生效」：无 PNG、无真实纹理资产、headless 无真实帧缓冲输出（运行期可见性未验收，见 `DONE-R9.md` §2.5），逐项如实登记。

### 6.3 ComfyUI 路径与工作流 JSON（阻塞，不臆造）

- `00-工具链接入说明.md` §7 仍为「ComfyUI 本机路径与工作流 JSON ｜ 待用户提供 / 待『刺探』指令」（本轮只读核对 `True` / `True`），本轮 HOST 未提供、目录无工作流 JSON → **登记阻塞**。
- 不臆造地址、不尝试连接 `GET /object_info`、不主动扫盘、不绕过；6 类自定义节点核对随路径登记后再办。**ComfyUI 仍是主美术路线**。
- 收敛路线（待产物到位后执行）：调色板收敛走 ComfyUI 主管线 + Aseprite / ImageMagick；`image/quantize.py` 是 DiT 权重量化器，不作 256 色板量化器。

---

## 7. 当前实际交付状态（如实）

| 项 | 状态 |
|---|---|
| `assets/generated/<品类>/*.png` | **0 张**（无首批合规 spritesheet） |
| 品类子目录 | **0 个**（6 品类目录尚未建立） |
| 真实 `.import` 元数据 | **0 个** |
| 规格 / 字段样例 JSON | 4 份（落位件 `delivery_manifest.json` / `import.json` / `palette_256.json` / `pose_names.json`） |
| `alpha` / 128px / ≤256 色收敛校验 | **无法执行（阻塞）**：无源 PNG，不编造校验数据 |
| 装饰 RGBA 与 base 逐像素对齐抽检 | **无法执行（阻塞）**：无 base、无装饰层，不臆造「不一致像素数=0」 |
| `style_anchor.png` / 128px 精灵表 / OpenPose 骨架库 | **未产出**，不伪造 |
| 显存档位 A~D / 峰值显存实测 | **未实测**：stdout 无 `--json` 结果（0 字节），不编造耗时 / 峰值 |
| 主角 / Boss / 关键场景 Aseprite 人工精修 | 未开始，`human_refine=done` 才允许交付 |
| 运行期可见性自检 | **未验收**：headless 为 Dummy 接口、无真实帧缓冲 / 截图，场景实例化成功 ≠ 可见（见 `DONE-R9.md` §2.5） |

> 本清单随首批合规 PNG 落地后转为「已交付」状态；本轮仅交付「规格 + 验收口径 + 阻塞结论」，不伪造资产。

---

## 8. 合规声明

- 只写 `Rank-4\`（本文档、`ART-SPEC-FINAL.md`、`DONE-R9.md`）+ 回执例外 `teamwork\command_center\ai\4\outbox\`；**未写 `godot\project.godot`、未写 `godot\scenes\`**、未写其它工位 / 总线 / 总纲 / 契约 / 任务书，未自行 `git commit` / `git push`。
- 既有件（契约 / 视觉规范 / 验收记录 / `import.json` / `palette_256.json` / `courtyard.tscn` / `project.godot` / 占位 `.gd`）一律**引用、不重做、一个字节未改**。
- 零付费 / 零外部依赖；付费 API 一律禁用，不列云服务 / 花费确认项；`stable-audio` / `gen3d` / `mia-rig` 不申请、不补装、不碰 WSL、不绕过。
- 默认不刺探：仅执行任务明确要求的 `Rank-4\*.png` 与两份日志只读检查、规格 / 配置 / 场景定向只读核对，未扫别人工位、未轮询、未写探针 / 测量 / preflight 脚本；`00-群聊总线.md` 开工只读一次。
- 中文 UTF-8；所有独立 JSON 与文档内嵌 `json` 围栏块合法可解析；本文档代码块用 `text` 标记、不含行首 ```json 围栏。
- **不宣称已能出图、不伪造输出 / 画面 / 截图、不拉起第二个 GPU job、不臆造 ComfyUI 路径、不夸大纹理级导入已生效、不冒充场景已渲染可见**：这是本轮最重要的一条。
