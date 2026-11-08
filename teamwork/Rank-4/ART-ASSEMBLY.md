# ART-ASSEMBLY.md · R6 美术资产与程序化占位装配

> 轮次：**R6（装配）**｜派单：`cmd-20261109-022337-016-A4`｜主任务书：`Rank-4\任务书-R6.md`
> 授权：`MSG-20261109-0223-HOST` 总指挥裁决（空转保护解除、工程根落位授权）；`任务书-R6.md` 首段总指挥授权（02:23）
> 唯一可写：`teamwork\Rank-4\` + `godot\assets\generated\` + `godot\scripts\render\hd2d_placeholder.gd`；回执例外 `command_center\ai\4\outbox\`
> 不写 `godot\project.godot`（Rank-1 独占）、不写其它工位 / 总线 / 总纲 / 契约、不覆盖既有文件、不自行 git
> 本轮定位：**把 R2/R5 冻结的 JSON 规格件装配落位到工程根 `assets/generated/`，并把 R5 的 `_draw()` 占位方案真正落成可被引擎校验的 GDScript**；出图仍无 PNG、ComfyUI 路径仍未登记 → 如实记阻塞，不宣称已能出图

---

## 1. 资产清单（落位 `godot/assets/generated/`）

| # | 文件 | 动作 | 源（冻结件，未改） | 字节 | 内容 |
|---|---|---|---|---|---|
| 1 | `palette_256.json` | 复制落位 | `Rank-4\palette_256.json` | 3575 | ≤256 色索引调色板（`palette_id=hd2d_index_256_v1`），当前冻结 32 色、128px 基准画布、L0~L8 明度阶梯 |
| 2 | `pose_names.json` | 复制落位 | `Rank-4\pose_names.json` | 3274 | 22 个冻结 pose 名（8 core + 3 boss，`p1_`/`p2_` 前缀），I-4 接口集合 |
| 3 | `import.json` | 复制落位 | `Rank-4\import.json` | 2349 | 像素导入规格样例（`canvas_base_px=128`、四项 `expected_import_settings`、32×32 交付帧 / 8×4=32 帧、锚点 (16,31)） |
| 4 | `delivery_manifest.json` | 复制落位 | `Rank-4\delivery_manifest.json` | 2722 | I-5 交付清单（M0 零 PNG 占位批次、降级路线 `procedural_draw_placeholder`、阻塞登记） |

- 四件均用 `cp -n` 复制，`cmp -s` 逐件校验**字节一致**（sha256 见 `DONE-R6.md` §2）：源冻结件一个字节未改，落位件不覆盖任何既有文件（落位前 `godot/assets/generated/` 不存在、无既有件）。
- 装配语义：`import.json::palette_ref` 指向 `res://assets/generated/_palette/palette_256.json`，本轮按任务书把 `palette_256.json` 落在 `res://assets/generated/` 平级；该 `_palette/` 子路径差异**登记为待 1 号导入时对齐**，不擅改冻结 JSON 字段（该件 `sample_only=true`，非真实资产交付）。
- `delivery_manifest.json::items=[] / item_count=0` 与 `style_anchor.status=not_produced` 如实保留，不伪造 PNG 交付。

## 2. 程序化占位方案落位（`godot/scripts/render/hd2d_placeholder.gd`）

- **从 R5 的「说明文档」落成「可被引擎校验的 .gd」**：`hd2d_placeholder.md`（R5）明确「本工位不产 .gd、落地归 1 号」；R6 任务书第 2 项与总指挥 02:23 授权（Rank-4 可写 `scripts/render/hd2d_placeholder.gd`）解除了该边界，本轮据此产出，不回头改写 R5 冻结文档。
- 单 `Node2D`，单次 `_draw()` 内按 **10 步**顺序调用：9 个视差层 + 1 步湿地倒影（reflection 挂 `bg_3_near` 内、不单独计层），与 `hd2d_placeholder.md` §2 / `hd2d_placeholder_r5_params.json::draw_pass_count=10` 一致。
- 四类重点效果全部有 `_draw()` 原语：
  - **多层视差**：`draw_set_transform` + 9 个冻结系数 `[0.05, 0.15, 0.35, 0.70, 0.45, 1.00, 1.00, 1.25, 0.00]`，`ox=round(-cam_x*k)`、sky/far 附加 `oy=round(-cam_y*k*0.3)`，UI 前复位；`ui` 系数 0 屏幕固定。
  - **光尘**：固定 `seed=20261108`，远 48 个 `#BFD0EA`/0.25、近 32 个 `#FFD27A`/0.45，上飘 2~6 px/s + 正弦横摆 ±3 px，`Time.get_ticks_msec()` 驱动。
  - **湿地倒影**：实体块垂直镜像 `y_mirror=2*GROUND_Y-sy-1`，高度压缩 0.70、alpha 0.35、逐行 ripple 0.03，脚底 Y 对齐、同一像素网格、`round()` 取整。
  - **体积光**：以光源为顶点的 4 层向下扩散扇形，alpha `[0.18, 0.12, 0.07, 0.04]`，色 `#FFD27A`。
  - 附带 bloom 同心圆 `[4,8,14,22,32]` / `[0.20,0.12,0.07,0.04,0.02]`、32×32 像素实体色板索引阵列（锚点 (16,31)、1px 轮廓 `#0B1226`、≤16 色）、金线深蓝 UI。
- 零外部依赖：只用 Godot 4 内置 `_draw()` 原语（`draw_rect` / `draw_colored_polygon` / `draw_circle` / `draw_line` / `draw_set_transform`），不加载任何 PNG / 贴图 / 插件 / 云服务 / 付费 API。
- 像素网格：640×360 逻辑缓冲 + 整数倍 `integer_scale`（clamp 到 2/3/4）Nearest 放大；实体坐标全部 `round()`，禁止亚像素位移与非整数缩放。
- 退出条件与路线优先级写入脚本头注释：**ComfyUI 仍是主美术路线**，`qwen-image` 仅本地零付费备选，占位仅 M0 / 显存不足降级；`assets/generated/bg_layers/` 与 `chars/` 有首批合规 spritesheet 且 1 号完成纹理层接入后逐层替换为 `draw_texture_rect()` / Sprite，`placeholder_enabled` 保留为调试开关。
- 引擎门禁实际结果见 `DONE-R6.md` §2.3：`--check-only --script` **EXIT=0 / SCRIPT ERROR=0**（首次因 `round()` 返回 Variant 的推断警告报 1 个 Parse Error，已按 Godot 4 静态检查要求改为 `float(round(...))` 并显式标注 String 后复跑全绿，过程如实登记）。

## 3. 像素导入口径核对（内联 python 真跑解析结论）

| 口径 | 冻结值来源 | 落位件实际值 | 结论 |
|---|---|---|---|
| lossless | `import.json::expected_import_settings.compress_mode` | `"lossless"` | PASS |
| 关 mipmaps | `...mipmaps` | `false` | PASS |
| Nearest | `...texture_filter` | `"Nearest"` | PASS |
| 项目级 `default_texture_filter=0` | `...project_default_texture_filter` | `0` | PASS |
| 128px 基准画布 | `import.json::canvas_base_px` / `palette_256.json::spec.canvas_base_px` | `128` / `128` | PASS |
| ≤256 色索引调色板 | `palette_256.json::spec` | `indexed=true` / `max_colors=256` / 当前 `color_count=32` | PASS |

- 附带一致性：`palette_id` 引用一致、`import.json::pose_names` 全在 `pose_names.json::all_frozen_names`（`frozen_name_count=22`）。**12/12 逐项 PASS**，实际 stdout 见 `DONE-R6.md` §2.2。
- 契约 §9.3 的 `128bit` 歧义仍按「128px 基准画布 + 256 色索引调色板」理解，登记不擅改；`image/quantize.py` 是 DiT 权重量化器，**未**用作调色板量化器。

## 4. 出图 / ComfyUI 阻塞（如实登记）

- 只读检查（02:27）：`Rank-4\*.png` 无、全工程 `find -iname '*.png'` 空；`asset_proof_stdout.txt` **0 字节**、`asset_proof_stderr.log` **25320 字节**停在 `Loading checkpoint shards: 50%|1/2`，mtime `01:21`、检查时刻 `02:27` 约 **66 分钟无新增**；报错类 / 完成类关键字命中均 **0**。
- 单一后台 `qwen-image --quant nf4` 出图 job 仍卡在 transformer checkpoint shard 1/2 加载，**无 PNG / 无结果 JSON / 无报错**。本轮**未启动第二个 GPU job、未杀 / 未重启 / 未并行**现有 job。
- 因此：alpha / 128px / ≤256 色收敛、装饰层逐像素对齐、风格锚图 / 精灵表、显存档位 A~D 峰值实测 **均无法执行 / 阻塞**，不编造校验数据、不伪造 PNG。
- ComfyUI 本机路径与工作流 JSON：`00-工具链接入说明.md` §7 表格仍为「待用户提供 / 待刺探指令」，总线 `MSG-20261109-0223-HOST` 未给出路径 → **登记阻塞，不臆造地址、不尝试连接 `GET /object_info`、不主动扫盘、不绕过**。**ComfyUI 仍是主美术路线**。
- **不宣称已能出图**：本轮装配的是「规格 JSON + 程序化占位」，不是美术资产产出。

## 5. 合规声明

- 只写 `Rank-4\`（本文件、`DONE-R6.md`）+ `godot\assets\generated\` 4 件 + `godot\scripts\render\hd2d_placeholder.gd`；回执例外 `command_center\ai\4\outbox\`。**未写 `godot\project.godot`**（Rank-1 独占）、未写其它工位 / 工程根其它子目录 / 总线 / 总纲 / 契约 / 任务书、未自行 git commit/push。
- 零付费 / 零外部依赖；付费 API 一律禁用；`stable-audio` / `gen3d` / `mia-rig` 不申请、不补装、不碰 WSL。
- 既有冻结件（`HD-2D视觉规范.md`、`hd2d_placeholder.md`、`hd2d_placeholder_params.json`、`hd2d_placeholder_r5_params.json`、`ASSET-PROOF.md`、`R4-验收记录.md`、R2~R5 全部 JSON / DONE）一律**引用、不重做、一个字节未改**。
- 默认不刺探：仅执行任务明确要求的 `Rank-4\*.png` 与两份日志只读检查，未扫别人工位、未写探针 / 测量 / preflight 脚本。
- 中文 UTF-8；所有 JSON 经内联 python 真跑解析；GDScript 为 Godot 4 合法语法（`--check-only` 通过）。
