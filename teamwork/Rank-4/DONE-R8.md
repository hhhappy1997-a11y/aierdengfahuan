# DONE-R8 · Rank-4（美术管线与工具链）完成标志

> 轮次：**R8（出图终态与调色板落地）**｜派单：`cmd-20261109-030933-295-A4`（`command_center\ai\4\inbox\` / `调度任务单-latest.json`）｜主任务书：`Rank-4\任务书-R8.md`
> 授权：`MSG-20261109-0309-HOST` 续派（`295-A4` R8 出图终态与调色板落地）、`MSG-20261109-0223-HOST` 工程根落位裁决、`MSG-20261109-0249-HOST` 续派
> 必读（开工只读一次）：`任务书-R8.md`、`scene_integration.md`、`DONE-R7.md`、`00-协作契约.md`、`00-群聊总线.md`
> **HOST 监测只认本文件。** 可写范围：`Rank-4\` + `godot\assets\generated\` + `godot\scripts\render\hd2d_placeholder*.gd`；唯一例外 `teamwork\command_center\ai\4\outbox\` 回执。**不写 `godot\project.godot`（Rank-1 独占）、不写 `godot\scenes\`、不写其它工位 / 总线 / 总纲 / 契约 / 任务书、不自行 git commit/push**
> 本轮定位：**零改动验收轮** —— 出图 job 只读验收 + 调色板工程根内实际生效验证 + 全 JSON 内联真跑解析 + Rank-1 接入产物核对 + 引擎语法门禁；本轮**未新建 / 未改动任何既有 `.gd` / `.png` / 规格 JSON**，既有件一律引用、不重做、一个字节未改
> 出图 `115.9` 分钟无新增 → **长期阻塞**；给出「程序化 `_draw()` 占位为正式零依赖兜底」明确结论；ComfyUI 路径未登记 → 记阻塞；Rank-1 开工快照未见接入、复核时刻并行 R9 按 `scene_integration.md` 接入产物出现 → 补做只读结构画面自检 8/8 PASS、渲染可见性仍未验收（§2.5）。不宣称已能出图、不伪造输出、不拉第二个 GPU job

---

## ① 实际交付清单

### 1.1 本轮实际新建 / 改动文件（2 个，均为新建；既有件零改动）

| # | 文件（绝对路径） | 动作 | 内容 |
|---|---|---|---|
| 1 | `F:\Game\aierdengfahuan\teamwork\Rank-4\DONE-R8.md` | **新建** | 本文件（完成标志，①交付清单 / ②自检含解析与真跑实际输出结论 / ③未完成项与阻塞 三段齐全） |
| 2 | `F:\Game\aierdengfahuan\teamwork\command_center\ai\4\outbox\receipt_R8_A4.json` | **新建（回执）** | 中枢回执 `dict(4)`；`task_id=cmd-20261109-030933-295-A4` / `ai=4` / `status=done` / `result` 引用本文件实际结论 |

> **本轮未改动任何既有件**：`godot\scripts\render\hd2d_placeholder.gd`（R6 冻结，14670 字节）、`godot\scripts\render\hd2d_placeholder_attach.gd`（R7 冻结，3776 字节）、`godot\assets\generated\` 下 4 份 JSON、`Rank-4\` 既有 10 份独立 JSON 与全部 `.md` 规范 / DONE 文档、`godot\project.godot`、`godot\scenes\*.tscn`、`godot\scripts\build_courtyard.gd` —— 一律只读引用、不覆盖、不重做、一个字节未改。
> **引擎副作用如实登记**：两段 `--headless --path godot --check-only --script` 为纯静态语法门禁，Godot 可能读取 / 更新 `godot\.godot\` 缓存（`global_script_class_cache.cfg`、`.uid` 等），这是引擎运行副作用、非本工位手工写入的交付件；R6 §1.2 / `DONE-R7.md` §1.1 已就同类副作用如实登记。

### 1.2 对照本轮五项要求（逐项处理）

| # | 本轮要求 | 本轮处理 | 实际结论 |
|---|---|---|---|
| 1 | **只读**验收单一后台 `qwen-image --quant nf4` 出图 job（`Rank-4\*.png`、`asset_proof_stdout.txt` / `asset_proof_stderr.log`）；绝不启动第二个 GPU job、不杀 / 不重启；约 90+ 分钟仍无 PNG → 登记长期阻塞并给出「程序化 `_draw()` 占位为正式零依赖兜底」明确结论；不宣称已能出图、不伪造输出 | **已完成** | PNG=0、stdout=0 字节、stderr 25320 字节停在 `checkpoint shards 50%(1/2)`、报错 / 完成关键字均 0；`01:21:30 → 03:17:23` **115.9 分钟无新增**（>90）→ **长期阻塞**。明确结论见 §1.3。未启动第二个 GPU job、未杀 / 未重启 / 未并行；本轮所有 Godot 调用均为 `--check-only --script` 静态语法门禁，非 GPU 出图 job |
| 2 | `palette_256.json`（32 色）在工程根内的**实际生效**验证：Nearest / 关 mipmaps / `default_texture_filter=0` / 128px / `indexed=true`；所有 JSON 内联真跑解析 | **已完成（含如实边界）** | 项目级 `project.godot:141` 实际 `textures/canvas_textures/default_texture_filter=0` 与期望一致（True）、`integer_upscale_factor=2`、`attach.gd:44` 实际 Nearest 代码落地；128px / `indexed=true` / `max_colors=256` / `color_count=32` / 32 色 hex6 去重 / 语义组覆盖 0~31 / luma 一致 全部 PASS；落位 **4/4** + 独立 **10/10** + 内嵌 **16/16** + 口径 **15/15** 真跑通过。**如实边界**：工程根真实 PNG=0、真实 `.import`=0，两份 `import.json` 均 `sample_only=true` 字段样例 → lossless / 关 mipmaps / Nearest 对**真实纹理的运行时导入生效无法实测**，不夸大「已在真实纹理上生效」，见 §2.2 |
| 3 | 若 Rank-1 本轮已按 `scene_integration.md` 接入占位画面，做一次画面自检（**有产物才做，无则如实登记未验收**） | **如实执行（两阶段）** | ①开工只读快照 `03:14:45`：`build_courtyard.gd` 无 `HD2D_ATTACH` 命中、`godot\scenes\` 下 11 个 `.tscn` 含 HD2D 节点者 **0** → 无产物、不做画面自检、如实登记未验收；②复核时刻 `03:17:51` 后：Rank-1 **并行 R9** 按 `scene_integration.md` §2.1 追加式接入产物落盘（`courtyard.tscn` +2 节点 = 22、自建 `attach_hd2d_placeholder.gd` 用一行调用）→ 按「有产物才做」补做**只读结构画面自检 8/8 PASS**（§2.5 [复核5]）。**渲染可见性自检仍未验收**（未启动渲染实例 / 截图，`scenes\` / `project.godot` 归 Rank-1 独占）；不冒充已渲染可见、不越界改 Rank-1 文件 |
| 4 | ComfyUI 路径未登记如实记阻塞，不臆造、不连接、不绕过 | **已完成** | `00-工具链接入说明.md` §7 第 103 行仍为「ComfyUI 本机路径与工作流 JSON ｜ 待用户提供 / 待『刺探』指令」（只读核对 True / True）→ 记阻塞；不臆造地址、不尝试连接 `GET /object_info`、不主动扫盘、不绕过。**ComfyUI 仍是主美术路线** |
| 5 | 产出 `DONE-R8.md`（①交付清单 ②自检含解析 / 真跑实际输出结论 ③未完成项与阻塞）；按任务单 id 写回执 | **已完成** | 本文件 ①②③（+④完成判定 +⑤合规声明）齐全，实际 stdout 见 §2；回执写入 `command_center\ai\4\outbox\receipt_R8_A4.json`，复核见 §2.5 |

**结论**：五项要求逐项处理齐备。依赖外部源图或跨工位（出图验收通过 / 场景实例化渲染 / 真实纹理导入实测）的动作按「如实记阻塞 / 只登记不擅改」降级；不依赖外部的四项（出图只读验收与终态判定、调色板实际生效与全 JSON 真跑解析、Rank-1 接入核对、引擎语法门禁）已真实执行并把实际输出写进 §2。

### 1.3 出图终态判定与「程序化 `_draw()` 占位为正式零依赖兜底」明确结论

**终态判定（只读、不伪造）**：单一后台 `qwen-image --quant nf4` 出图 job 自 `2026-11-09 01:21:30 +0800` 停在 `Loading checkpoint shards: 50%|█████ | 1/2 [05:35<05:35, 335.95s/it]`；经 `03:17:23 +0800` 只读复核 **115.9 分钟无新增输出**（超过 90 分钟阈值）；`Rank-4\*.png` = 0、`asset_proof_stdout.txt` = 0 字节、报错类 / 完成类关键字命中行数均 0 → **登记为长期阻塞**（不是崩溃、也不是完成，未进入去噪 / 写图）。本轮不宣称已能出图、不伪造 PNG / 结果 JSON / 校验数据；**未启动第二个 GPU job、未杀 / 未重启 / 未并行**现有 job。

**明确结论（本轮交付）**：在「`qwen-image` 出图长期阻塞 + ComfyUI 本机路径与工作流 JSON 仍未登记」的双重现状下，**正式确立 `godot\scripts\render\hd2d_placeholder.gd` 的程序化 `_draw()` 占位为工程内唯一可真实运行、零外部依赖的正式兜底画面方案**，要点如下：

- 它是**兜底（fallback）路线的正式化**，**不是美术主路线变更**：**ComfyUI 仍是主美术路线**；`qwen-image` 仅为本地零付费备选；`import.json::fallback_route` 已登记 `procedural_draw_placeholder`，`scene_integration.md` §0 / `DONE-R7.md` §5 一以贯之。
- 它已真实具备零依赖可运行性（本轮真跑核对）：`hd2d_placeholder.gd`（R6 冻结，14670 字节，单次 `_draw()` 按 10 步绘完 9 视差层 + 湿地倒影 / 体积光 / 光尘 / bloom / 32×32 像素实体 / 金线深蓝 UI，零外部依赖）、`hd2d_placeholder_attach.gd`（R7 挂载辅助，三静态方法、幂等、仅 `load()` 工程内 `.gd`）；本轮两段 `--check-only --script` 门禁均 `EXIT=0 / SCRIPT ERROR=0`（§2.4）；项目级 Nearest / `default_texture_filter=0` / `integer_upscale_factor=2` 已在 `project.godot` 实际落地（§2.2 [E]）。
- 启用方式沿用 `scene_integration.md` §2 的 Rank-1 一行调用（开工快照未见接入；复核时刻 Rank-1 并行 R9 已按 §2.1 用该调用追加式落地，见 §2.3 / §2.5）：
  ```gdscript
  const HD2D_ATTACH = preload("res://scripts/render/hd2d_placeholder_attach.gd")
  HD2D_ATTACH.attach(root, {"canvas_layer": -10, "integer_scale": 2})
  ```
- 退出条件沿用 `scene_integration.md` §4：`assets/generated/bg_layers/` 与 `chars/` 有首批合规 spritesheet 且 1 号完成纹理层接入后，调用 `HD2DPlaceholderAttach.detach(root)` 移除背景层、逐层替换为 `draw_texture_rect()` / Sprite；占位不取代正式美术资产。
- **本结论不等于**「已能出图」「已渲染可见」「场景已接入」「真实纹理导入已生效」：无 PNG、无真实纹理资产、无场景实例化渲染，逐项如实登记在 ③。

> 与契约的相容性：`00-协作契约.md` §9.3「程序化 `_draw()` 仅作 M0 占位与显存不足时的降级」——本结论把「降级」在出图 / ComfyUI 双阻塞期间**明确为正式兜底并启用**，未改变「所有美术素材统一用本地 ComfyUI 制作」的主路线，也未宣称占位为正式素材；措辞为「正式零依赖兜底」而非「正式素材路线」。

### 1.4 回执落位说明

回执按任务单 id 写入 `teamwork\command_center\ai\4\outbox\receipt_R8_A4.json`。按 `AierdengfahuanCommander.exe` 机制（同 `DONE-R3.md` §1.4 ~ `DONE-R7.md` §1.4），写入后中枢可能实时消费并归档到 `teamwork\command_center\dispatcher\receipts\receipt_R8_A4.json`、outbox 随之清空。§2.5 的最终复核以**实际落位**（outbox 或 receipts）为准做内联 python 真跑解析；本轮不轮询、不伪造「已被接收」之外的状态、不重复写第二份回执。

---

## ② 自检结果（解析 / 真跑的实际输出结论）

### 2.1 真跑方式

- **内联 `python`**（`python - <<'PY'`，不落任何脚本文件）：`json.load` 解析工程根落位件 / `Rank-4\*.json` 全部独立文件 / 中枢回执，`json.loads` 解析 `Rank-4\*.md` 全部行首 `json` 围栏代码块；口径与实际生效用只读正则 / 只读文件核对。依据 `DONE-R2.md` §2.1 ~ `DONE-R7.md` §2.1 一贯口径（**交付自检，不是探针 / 测量 / preflight 脚本**）。Python `3.13.14`。
- **引擎真跑**：`D:\Godot\Godot_v4.7.2-stable_win64.exe --headless --path "F:/Game/aierdengfahuan/godot" --check-only --script res://scripts/render/<script>.gd`，捕获 stdout/stderr，统计 `EXIT` 并 grep `SCRIPT ERROR` / `Parse Error` / `ERROR:`。纯静态语法门禁，**不是 GPU 出图 job**。
- **出图 / PNG 只读验收**：任务明确要求的只读动作（`Rank-4\*.png` + 两份日志的 stat / tail / 关键字计数），实际输出见 §2.3。**未启动任何出图进程 / 第二个 GPU job**。
- 本 `DONE-R8.md` 内所有代码块用 `text` / `gdscript` 标记、不含行首 `json` 围栏，故写完统计仍为 **16/16**（口径自洽，与 `DONE-R6.md` §2.1 / `DONE-R7.md` §2.1 做法一致）。

### 2.2 全部 JSON 内联真跑解析 + 调色板工程根内「实际生效」核对（实际 stdout）

```text
=== [A] 工程根落位件 JSON 真跑解析 (godot/assets/generated) ===
  OK  delivery_manifest.json       dict(20)
  OK  import.json                  dict(31)
  OK  palette_256.json             dict(12)
  OK  pose_names.json              dict(14)
  -> 落位 JSON: 4/4 解析通过
=== [B] 源 Rank-4 全部独立 JSON 真跑解析 ===
  OK  delivery_manifest.json             dict(20)
  OK  hd2d_placeholder_params.json       dict(18)
  OK  hd2d_placeholder_r5_params.json    dict(23)
  OK  import.json                        dict(31)
  OK  palette_256.json                   dict(12)
  OK  player_idle_v1.import.json         dict(31)
  OK  pose_names.json                    dict(14)
  OK  prompt_skeleton.json               dict(20)
  OK  调度任务单-R2.json                      dict(9)
  OK  调度任务单-latest.json                  dict(9)
  -> 独立 JSON: 10/10 解析通过
=== [C] Rank-4 文档内嵌 json 围栏块真跑解析（仅行首 ```json） ===
  OK  ASSET-PROOF.md               block#1  dict(20)
  OK  HD-2D视觉规范.md                 block#2  dict(12)
  OK  R4-验收记录.md                   block#3  dict(8)
  OK  hd2d_placeholder.md          block#4  dict(2)
  OK  hd2d_placeholder.md          block#5  dict(10)
  OK  hd2d_placeholder.md          block#6  dict(3)
  OK  工具链配置.md                     block#7  dict(1)
  OK  工具链配置.md                     block#8  dict(1)
  OK  美术管线.md                      block#9  dict(23)
  OK  美术管线.md                      block#10 dict(15)
  OK  美术管线.md                      block#11 dict(2)
  OK  美术管线.md                      block#12 dict(5)
  OK  资产交付契约.md                    block#13 dict(24)
  OK  资产交付契约.md                    block#14 dict(24)
  OK  资产交付契约.md                    block#15 dict(15)
  OK  资产交付契约.md                    block#16 dict(8)
  -> 内嵌 JSON 块: 16/16 解析通过
=== [D] 128px / 32 色索引调色板 + 四项导入口径 + 源落位一致核对 ===
  OK  compress_mode = lossless                       = lossless
  OK  mipmaps = false (关 mipmaps)                    = False
  OK  texture_filter = Nearest                       = Nearest
  OK  project_default_texture_filter = 0             = 0
  OK  import.canvas_base_px = 128                    = 128
  OK  palette.spec.canvas_base_px = 128              = 128
  OK  palette.indexed = true                         = True
  OK  palette.max_colors = 256                       = 256
  OK  palette.color_count = 32 (<=256)               = 32
  OK  colors 数组长度 == color_count == 32               = 32
  OK  colors 全为 #RRGGBB 且去重                          = 32
  OK  palette_id 与 import 引用一致                       = hd2d_index_256_v1
  OK  源 palette_256 == 落位 palette_256 (逐键)           = True
  OK  import.pose_names 全在冻结表                        = 4/22
  OK  player_idle 样例四项期望与 import 一致                  = True
  -> 口径核对: 15/15 通过
=== [E] 工程根内「实际生效」核对（只读 project.godot / 占位脚本）===
  project.godot 合法键 default_texture_filter = 0
  与 import.json 期望值 0 一致 : True
  project.godot integer_upscale_factor = 2 (128px 基准画布 ×2 对齐 1280×720)
  attach.gd 实际 Nearest 代码落地 : True
  attach.gd 三静态方法 : ['attach', 'find_placeholder', 'detach']
  attach.gd 无 PNG 贴图依赖 : True
  占位脚本零外部依赖(无 load/preload res://) : True
  工程根 generated 下真实 PNG : 0
  工程根 generated 下真实 .import 元数据 : 0
  注: import.json / player_idle_v1.import.json 均 sample_only=true 字段样例；无真实纹理资产 → Godot 运行时导入生效无法实测
=== [F] palette_256.json 32 色功能板结构核对 ===
  semantic_groups 覆盖索引数 : 32  覆盖 0~31 完整 : True
  luma L0~L8 hex 均落在 colors : True
  luma L0~L8 index 与 colors 一致 : True
```

> **判读（分层、不夸大）**：
> - **实际生效 PASS**：项目级 `project.godot:141` 的 `textures/canvas_textures/default_texture_filter=0` 与 `import.json` 期望值一致（只读核对 True）、`integer_upscale_factor=2`（128px 基准画布 ×2 对齐 1280×720）；`attach.gd:44` 的 `placeholder.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST` 为真实代码落地；源 `Rank-4\palette_256.json` 与工程根落位 `godot\assets\generated\palette_256.json` **逐键一致**（`pal == pal_src` = True），128px / `indexed=true` / `max_colors=256` / `color_count=32` / 32 色 `#RRGGBB` 去重 / 语义组覆盖索引 0~31 完整 / luma L0~L8 hex 与 index 均落在 `colors` —— 规格在落位件内真实生效。
> - **无法实测、如实登记**：`lossless` / 关 `mipmaps` / `Nearest` 对**真实纹理**的运行时导入生效 —— 工程根 `godot\assets\generated\` 真实 PNG = 0、真实 `.import` 元数据 = 0（Godot 未对任何纹理生成导入元数据）；`import.json` 与 `player_idle_v1.import.json` 均为 `sample_only=true` 字段样例，其 `expected_import_settings` 是**期望值**而非运行时实测值。本轮**不夸大**「已在真实纹理上生效」，该实测随首批合规 PNG 资产落地后由 1 号导入时完成。
> - 口径如实说明：任务书字面 `default_texture_filter=0`，Godot 4 合法键为 `textures/canvas_textures/default_texture_filter`（`project.godot` 头注释与 R6 §2.2 已纠正，历史误写 `canvas_items` 不写回）；`import.json::palette_ref` 的 `_palette/` 子路径与实际平级落位差异沿用 R6 / R7 登记为「1 号导入时对齐」，本轮不擅改冻结字段。
> - 落位 **4/4** + 独立 **10/10** + 内嵌 **16/16** + 口径 **15/15** 全部真跑通过（本轮口径在 R7 的 12/12 上增补「colors 长度/格式去重、源=落位逐键一致、player_idle 样例一致」3 项，均为真跑新增、非沿用旧结论）。

### 2.3 出图 / ComfyUI / Rank-1 接入 只读验收（实际 stdout）

```text
=== NOW === 2026-11-09 03:14:45 +0800
=== [1] Rank-4 *.png（只读验收）===
ls: cannot access '.../Rank-4/*.png': No such file or directory
(无 PNG 文件)
PNG_COUNT=0
=== [2] 两份日志 stat ===
asset_proof_stdout.txt | 0 bytes | mtime=2026-11-09 01:05:48 +0800
asset_proof_stderr.log | 25320 bytes | mtime=2026-11-09 01:21:30 +0800
=== [3] stderr 尾部 900 字节（只读）===
  Loading weights: 100%|██████████| 750/750 [08:47<00:00,  1.42it/s]
  [load] transformer (nf4) from Qwen/Qwen-Image-2.1 ...
  Fetching 2 files: 100%|██████████| 2/2 [00:00<00:00, 999.83it/s]
  Loading checkpoint shards:   0%|          | 0/2 [00:00<?, ?it/s]
  Loading checkpoint shards:  50%|█████     | 1/2 [05:35<05:35, 335.95s/it]
=== [4] stdout 字节数与内容 === 0 字节（无内容）
=== [5] stderr 报错/完成类关键字计数（只读）===
ERROR/Traceback/Exception/Failed 计数 = 0
完成类(saved/image/png/denoise/done/finished) 计数 = 0
```

```text
=== [G] 出图 job 两份日志内联 python 只读分析 ===
  stdout bytes = 0  stderr bytes = 25320
  报错类关键字命中行数 = 0  完成类关键字命中行数 = 0
  Rank-4 目录 PNG 计数 = 0
  stderr 末行 = Loading checkpoint shards:  50%|█████     | 1/2 [05:35<05:35, 335.95s/it]
  stderr mtime = 2026-11-09 01:21:30 +0800
  检查时刻 NOW = 2026-11-09 03:17:23 +0800
  无新增时长(分钟) = 115.9
=== [H] ComfyUI 路径登记只读核对 ===
  §7 含「ComfyUI 本机路径与工作流 JSON」待登记项 : True
  状态仍为「待用户提供 / 待刺探指令」: True
=== [I] Rank-1 占位画面接入只读核对（scene_integration.md 一行调用）===
  build_courtyard.gd 含 HD2D_ATTACH 一行调用 : False
  scenes 下 .tscn 总数 = 11  含 HD2D 占位节点的 .tscn 数 = 0
  -> 判定: 无接入产物 → 画面自检未验收（如实登记，不冒充）
```

```text
=== Rank-1 接入 / project.godot / 占位脚本 只读核对（补充）===
build_courtyard.gd 存在: 9214 bytes, mtime=2026-11-09 02:28
  (build_courtyard.gd 无 HD2D/attach/placeholder 命中)
  (scenes 无 HD2D 节点命中)
  (全工程无 HD2D_ATTACH 一行调用)
project.godot:141  textures/canvas_textures/default_texture_filter=0
project.godot:65   render/integer_upscale_factor=2
hd2d_placeholder_attach.gd:44  placeholder.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
00-工具链接入说明.md:93  ComfyUI 仍是主美术路线；qwen-image 是同为零付费的本地备选
00-工具链接入说明.md:103 ComfyUI 本机路径与工作流 JSON | 待用户提供 / 待「刺探」指令
```

> **判读（如实）**：
> - 出图：权重 `750/750` 已加载、`checkpoint shards 50%(1/2)` 仍**无 PNG**；日志 mtime `01:21:30`、复核时刻 `03:17:23`，**115.9 分钟无新增**；报错类 / 完成类关键字命中行数均 **0**；stdout 0 字节 → `--json` 结果对象（timing / peak VRAM / 输出路径）未产生。**单一长时后台 job 停在 transformer checkpoint shard 1/2 加载，未进入去噪 / 写图；不是崩溃而是极慢加载 → 长期阻塞**。按本轮指令走「如实记阻塞 + 正式兜底结论」分支（§1.3）：不宣称已能出图、不伪造 PNG / 结果 JSON / 校验数据；**未启动第二个 GPU job**，单一 job 未杀 / 未重启 / 未并行。
> - ComfyUI：§7 仍「待用户提供 / 待刺探指令」→ **登记阻塞**，不臆造地址、不尝试连接 `GET /object_info`、不主动扫盘、不绕过；**ComfyUI 仍是主美术路线**。
> - Rank-1 接入（**两阶段，如实**）：①开工只读基准时刻 `03:14:45`：`build_courtyard.gd` 无一行调用、`godot\scenes\` 下 11 个 `.tscn`（`Main.tscn` / `courtyard.tscn` / 9 个 chunk）含 HD2D 占位节点者 0 → 无产物、按「有产物才做」不做画面自检、如实登记未验收（上方 [I] 实际输出即此快照，真实、非伪造）；②复核时刻 `03:17:51` 后：Rank-1 并行 R9 用 `scene_integration.md` §2.1 一行调用追加式落地接入产物（`courtyard.tscn` +2 节点 = 22、自建 `attach_hd2d_placeholder.gd`）→ 按「有产物才做」**补做只读结构画面自检 8/8 PASS**（§2.5 [复核5]）。**渲染可见性自检仍未验收**：未启动渲染实例 / 截图、未运行会写回场景的 Rank-1 脚本，不冒充已渲染可见、不越界改 `scenes\` / `project.godot` / Rank-1 文件。开工快照与复核时刻的差异是 Rank-1 并行产出，非本工位写入，如实登记、不冒充。

### 2.4 引擎 `--check-only --script` 门禁实际输出（含 grep `SCRIPT ERROR`，不隐瞒）

```text
=== 命令 ===
D:\Godot\Godot_v4.7.2-stable_win64.exe --headless --path "F:/Game/aierdengfahuan/godot" --check-only --script <res://...>
引擎存在性: /d/Godot/Godot_v4.7.2-stable_win64.exe 180858888 bytes
python: Python 3.13.14
=== --check-only --script res://scripts/render/hd2d_placeholder.gd ===
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
EXIT=0 | SCRIPT_ERROR_count=0 | Parse_Error_count=0 | ERROR_count=0
=== --check-only --script res://scripts/render/hd2d_placeholder_attach.gd ===
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
EXIT=0 | SCRIPT_ERROR_count=0 | Parse_Error_count=0 | ERROR_count=0
```

> 判读：两段门禁**首次即全绿**，输出均仅 Godot 版本横幅；`SCRIPT ERROR` 合计 **0**、`Parse Error` **0**、`ERROR:` **0**。两个脚本均为 R6 / R7 已冻结件，本轮**一个字节未改**，故无需像 `DONE-R6.md` §2.3 那样修 `round()` Variant 推断。
> **如实登记（不冒充全工程门禁全绿）**：本轮按任务约束只跑可写范围内两个占位脚本的 `--check-only --script` 静态语法门禁；**未跑** `--headless --import` / `--headless --quit` 全工程门禁（那是 Rank-1 独占的跨工位全工程门禁，R6 §2.3 / `DONE-R7.md` §2.3 已登记为非本轮范围，其 18 条 autoload / ChunkManager 跨工位 ERROR 由 Rank-1 在 R8/R9 处理）。任务书-R8「真跑要求：引擎三段门禁」本轮按「不越界 / 不写 `project.godot` / 不写 `scenes\`」分解为两段占位脚本语法门禁；全工程三段门禁的归零回归属 Rank-1 R9（`MSG-20261109-0309-HOST` 派 `289-A1`），本工位不代跑、不冒充。

### 2.5 写完文档与回执后的最小复核（实际 stdout）

写完 `DONE-R8.md` 与回执后跑内联 python 复核，实际输出：

```text
=== [复核1] 落位件 4 件 json.load（写完文档后）===
  OK  delivery_manifest.json       dict(20)
  OK  import.json                  dict(31)
  OK  palette_256.json             dict(12)
  OK  pose_names.json              dict(14)
  -> 落位 JSON: 4/4
=== [复核2] Rank-4*.md 行首 json 围栏块（含 DONE-R8.md）===
  -> 内嵌 JSON 块: 16/16 解析通过（DONE-R8.md 用 text/gdscript 标记、未新增 json 围栏）
=== [复核3] 回执 JSON 真跑解析（以实际落位为准）===
  实际落位 : F:/Game/aierdengfahuan/teamwork/command_center/dispatcher/receipts/receipt_R8_A4.json | exists = True
  dict(4)
  task_id = cmd-20261109-030933-295-A4
  ai      = 4
  status  = done
  result_len = 1172
  task_id_matches_dispatch = True
  result_引用_DONE-R8      = True
=== [复核4] DONE-R8.md 三段齐全 + 交付件存在性 + 既有件未改只读核对（复核时刻快照）===
  DONE-R8.md ①实际交付清单 = True
  DONE-R8.md ②自检结果     = True
  DONE-R8.md ③未完成项与阻塞 = True
  DONE-R8.md 不含行首 ```json 围栏 = True
  exists DONE-R8.md               = True
  exists receipt(outbox)          = False
  exists receipt(receipts)        = True
  既有件(未改) project.godot                  mtime=2026-11-09 02:57:32 bytes=6063
  既有件(未改) courtyard.tscn                 mtime=2026-11-09 03:17:51 bytes=5054
  既有件(未改) hd2d_placeholder.gd            mtime=2026-11-09 02:33:38 bytes=14670
  既有件(未改) hd2d_placeholder_attach.gd     mtime=2026-11-09 02:55:17 bytes=3776
  既有件(未改) build_courtyard.gd             mtime=2026-11-09 02:28:35 bytes=9214
  既有件(未改) palette_256.json(落位)           mtime=2026-11-09 02:29:23 bytes=3575
```

> **回执落位**：写入 outbox 后已被中枢实时消费归档到 `dispatcher\receipts\receipt_R8_A4.json`、outbox 随之清空（与 `DONE-R7.md` §1.4 机制一致），属正常、非失败；未重复写第二份回执。回执 `dict(4)` 合法、`task_id` 与派单 `调度任务单-latest.json` 一致、`ai=4` / `status=done` / `result_len=1172` 且引用本文件。

**复核暴露的并行更新（如实登记、不冒充、不越界）**：[复核4] 显示 `courtyard.tscn` 的 mtime / 字节数由开工检查时的 `02:28:35 / 4701` 变为 `03:17:51 / 5054` —— 系 **Rank-1 并行 R9「画面接入」**（`MSG-20261109-0309-HOST` 派 `289-A1`）在我方复核窗口内落盘，并非本工位写入（本轮从未写 `scenes\` / `project.godot` 一个字节）。因出现「按 `scene_integration.md` 接入的占位画面产物」，按本轮任务「有产物才做」补做一次**只读画面自检**，实际输出：

```text
=== [复核5] 并行接入产物只读画面自检（结构核对 · 非渲染 · 不运行 Rank-1 写回脚本）===
  scene_integration.md §3.2 契约常量: LAYER_NAME=HD2DPlaceholderLayer NODE_NAME=HD2DPlaceholder layer=-10 integer_scale=2
  OK  ext_resource 指向 res://scripts/render/hd2d_placeholder.gd
  OK  HD2DPlaceholderLayer 为 CanvasLayer 且 layer=-10
  OK  HD2DPlaceholder 为 Node2D 挂在 HD2DPlaceholderLayer 下
  OK  texture_filter = 1 (TEXTURE_FILTER_NEAREST)
  OK  script = ExtResource(...) 挂占位脚本
  OK  integer_scale = 2
  OK  落位 tscn 与 scene_integration.md 契约逐项一致
  OK  既有 FXLayer(CanvasLayer, layer=10) 未被动
  tscn 节点总数 [node 行数] = 22（R4 既有 20 + 追加式 +2 = 22 口径）
  -> 只读结构自检: 8/8 通过
=== 接入方式与边界（只读静态审阅，不代跑）===
  Rank-1 追加脚本用 scene_integration.md §2.1 一行调用 HD2D_ATTACH.attach : True
  Rank-1 追加脚本声明沿用 scene_integration.md 口径 : True
  Rank-1 追加脚本不宣称已渲染可见 : True
  build_courtyard.gd 仍无 attach 调用(未改, 9214 bytes) : True
  本轮未运行 attach_hd2d_placeholder.gd（其 ResourceSaver.save 会写回 courtyard.tscn，属 Rank-1 独占）: True
  场景实例化渲染 / 截图 : 未执行（scenes\ / project.godot 归 Rank-1 独占，本轮不启动渲染实例）
```

> **画面自检结论（两阶段、如实）**：
> - **开工只读基准时刻 `03:14:45`**：无接入产物 → 按「有产物才做」不做画面自检、如实登记未验收（§2.3 [I] 与回执 `result` 第③点即此快照，真实、非伪造）。
> - **复核时刻 `03:17:51` 后**：Rank-1 并行 R9 用 `scene_integration.md` §2.1 的一行调用 `HD2D_ATTACH.attach(root, {"canvas_layer": -10, "integer_scale": 2})` 追加式落地 `HD2DPlaceholderLayer(-10)` → `HD2DPlaceholder(Nearest / integer_scale=2 / script=hd2d_placeholder.gd)`，节点总数 22（既有 20 + 2）、既有 `FXLayer` 未被动 → 按「有产物才做」补做**只读结构画面自检 8/8 PASS**（节点名 / 层级 / 层序 / Nearest / 脚本引用 / 整数缩放与 §3.2 契约逐项一致）。
> - **仍未验收、不冒充**：本轮**未做场景实例化渲染 / 截图**（`scenes\` / `project.godot` 归 Rank-1 独占、未启动渲染实例、未运行会写回场景的 `attach_hd2d_placeholder.gd`），故**渲染可见性自检仍未验收**；占位画面实际是否可见由 Rank-1 在其构建脚本真跑后确认。本轮不宣称「已渲染可见」、不冒充全工程门禁全绿、不越界改 Rank-1 文件。
> - **HOST 口径**：`00-群聊总线.md` / 派单规则下 HOST 监测只认 `DONE-R8.md`；回执 `result` 引用本文件实际结论，其中第③点为开工基准快照，完整两阶段结论以本文件 §2.3 / §2.5 / ③ 为准。未因并行更新重复写第二份回执、未改已归档回执、未写总线。

---

## ③ 未完成项与阻塞（如实，全部非谎报）

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| 1 | `qwen-image --quant nf4` 首次出图 | **长期阻塞（本轮终态判定）** | 单一后台 job 停在 `transformer checkpoint shards 50%(1/2)`，`01:21:30 → 03:17:23` **115.9 分钟无新增**；无 PNG / 无结果 JSON / 无报错。不宣称已能出图、不伪造输出；未杀 / 未重启 / 未并行、未拉第二个 GPU job，最终以 `asset_proof_stdout.txt` / `asset_proof_stderr.log` 为准。正式兜底结论见 §1.3 |
| 2 | 程序化 `_draw()` 占位挂进场景 / 画面自检 | **只读结构自检 PASS / 渲染可见性未验收（两阶段）** | 开工 `03:14:45` 无接入产物 → 不做画面自检、如实登记；复核 `03:17:51` 后 Rank-1 并行 R9 按 §2.1 落地 22 节点接入产物 → 补做只读结构画面自检 **8/8 PASS**（§2.5 [复核5]）。**场景实例化渲染 / 截图仍未验收**：`scenes\` / `project.godot` / `build_courtyard.gd` 归 Rank-1 独占，本轮不写、不覆盖、不运行其写回脚本；可见性由 1 号真跑确认 |
| 3 | lossless / 关 mipmaps / Nearest 对**真实纹理**的运行时导入生效实测 | **无法实测（阻塞）** | 工程根真实 PNG=0、真实 `.import`=0；两份 `import.json` 均 `sample_only=true` 字段样例。项目级 `default_texture_filter=0` 与 `attach.gd` Nearest 代码已实际生效（§2.2 [E]），纹理级实测随首批合规 PNG 落地后由 1 号导入完成；不夸大「已在真实纹理上生效」 |
| 4 | alpha / 128px / ≤256 色收敛校验 | **无法执行（阻塞）** | 无源 PNG；收敛路线（ComfyUI / Aseprite / ImageMagick，不混用 `image/quantize.py` DiT 权重量化器）与判据见 `R4-验收记录.md` §2，沿用不改；不编造校验数据 |
| 5 | 装饰 RGBA 层与 base 逐像素对齐抽检 | **无法执行（阻塞）** | 无 base、无装饰层；判据见 `R4-验收记录.md` §4，沿用不改；不臆造「已对齐 / 不一致像素数=0」 |
| 6 | ComfyUI 本机路径与工作流 JSON 登记 + `GET /object_info` 6 类节点核对 | **阻塞** | `00-工具链接入说明.md` §7 仍「待用户提供 / 待刺探指令」，本轮 HOST 未提供、目录无工作流 JSON；不臆造地址、不尝试连接、不绕过、不主动扫盘。**ComfyUI 仍是主美术路线** |
| 7 | `style_anchor.png` / 128px 精灵表 / OpenPose 骨架库 | **未产出** | 本机未跑出图，`Rank-4\*.png` 计数 0；不伪造 |
| 8 | 显存档位 A~D / 峰值显存实测 | **未实测** | stdout 无 `--json` 结果（0 字节），只有 R3 记录的加载阶段 14203 MiB（非最终峰值）；不编造耗时 / 峰值 |
| 9 | 主角 / Boss / 关键场景 Aseprite 人工精修 | 未开始 | 人工环节（M1 / M5），`human_refine=done` 才允许交付 |
| 10 | 挂载点 / 缩放 / 遮挡顺序 4 项取舍 | **登记 / 待 1 号裁决** | 既有 `_apply_integer_scale()` clamp 2~4 无法设 1（不覆盖冻结件）；`SubViewport` 内放大出界、不透明 3D 背景遮挡顺序由 1 号裁决，见 `scene_integration.md` §4；本轮只登记不擅改 |
| 11 | `import.json::palette_ref` 的 `_palette/` 子路径与实际落位平级差异 | **登记 / 待 1 号导入对齐** | 该件 `sample_only=true` 为字段样例；本轮按 R6 落在 `assets/generated/` 平级，不擅改冻结字段 |
| 12 | 付费 API / `stable-audio`(gated 403) / `gen3d` / `mia-rig` | **禁用 / 不碰** | 不申请、不补装、不碰 WSL、不绕过；不列「确认花费」为待办 |
| 13 | 群聊总线追加 `TYPE=交付完成` 消息 | **本轮不执行** | 本轮硬性约束「不写总线」，且总线不在唯一可写范围；以 HOST 最新指令为准 |

---

## ④ 完成标准判定

| 判据 | 结论 |
|---|---|
| 本轮 5 项要求逐项处理 | ✓ 出图只读验收与终态判定 / 调色板实际生效 + 全 JSON 真跑解析 / Rank-1 接入核对 / ComfyUI 阻塞登记 / DONE-R8.md 与回执，5/5 处理齐备 |
| 只读验收单一出图 job、绝不启动第二个 GPU job、不杀 / 不重启 | ✓ 仅 stat / tail / 关键字计数与 `--check-only --script` 静态门禁；单一 job 未动 |
| 90+ 分钟无 PNG → 登记长期阻塞 + 「程序化 `_draw()` 占位为正式零依赖兜底」明确结论 | ✓ 115.9 分钟 → 长期阻塞；§1.3 给出明确结论并厘清「兜底正式化 ≠ 主路线变更」；不宣称已能出图、不伪造输出 |
| `palette_256.json` 32 色工程根内实际生效（Nearest / 关 mipmaps / `default_texture_filter=0` / 128px / `indexed=true`） | ✓ 项目级 `project.godot:141=0` 与期望一致、`attach.gd:44` Nearest 代码落地、`integer_upscale_factor=2`；128px / `indexed=true` / `max_colors=256` / `color_count=32` / 32 色 hex6 去重 / 语义组 0~31 / luma 一致 全部 PASS；纹理级运行时导入生效无法实测已如实登记 |
| 所有 JSON 合法可解析（落位 + 独立 + 内嵌 + 回执） | ✓ 落位 **4/4** + 独立 **10/10** + 内嵌 **16/16** + 口径 **15/15** 真跑通过；回执写后经内联 python 解析（§2.5） |
| 画面自检「有产物才做，无则如实登记未验收」 | ✓ 开工无产物 → 不做画面自检、如实登记；复核时刻 Rank-1 并行接入产物出现 → 按「有产物才做」补做只读结构画面自检 8/8 PASS、渲染可见性仍未验收、不冒充已渲染可见（§2.5） |
| ComfyUI 路径未登记如实记阻塞，不臆造 / 不连接 / 不绕过 | ✓ §7 只读核对仍「待用户提供 / 待刺探指令」→ 记阻塞 |
| 真跑 `--check-only --script` 并 grep `SCRIPT ERROR` | ✓ 两脚本均 `EXIT=0` / `SCRIPT ERROR=0` / `Parse Error=0` / `ERROR=0`，输出仅版本横幅；如实登记未跑全工程门禁、不冒充全绿 |
| `DONE-R8.md` 三段齐全 + 回执 | ✓ ①交付清单 / ②自检含解析与真跑实际输出 / ③未完成项与阻塞（+④完成判定 +⑤合规声明）齐全；回执 `status=done` 引用本文件实际结论 |
| 既有件不重做 / 不越界 / 不写 `project.godot` / 不写 `scenes\` / 不自行 git | ✓ R2~R7 全部冻结件与工程根落位件一个字节未改；只写 `Rank-4\DONE-R8.md` 与回执例外 |

**本轮 R8 达成**：按「出图终态与调色板落地」定位，把单一出图 job 的只读验收、115.9 分钟长期阻塞判定与「程序化 `_draw()` 占位正式零依赖兜底」明确结论真实落盘；调色板 32 色在工程根内的实际生效（项目级配置 / 占位脚本 Nearest 代码 / 规格落位件）与全 JSON 内联真跑解析、Rank-1 接入核对、引擎语法门禁均真跑并把实际输出写进 §2；出图 / ComfyUI / 收敛 / 对齐 / 场景实例化渲染 / 真实纹理导入实测等依赖外部源图或跨工位的项如实记阻塞、不硬造、不重复拉 GPU job。未完成项均属任务书允许的「尽力而为 / 如实降级 / 只登记不擅改」范围，不影响 R8 完成判定（与 `DONE-R2.md` §4 ~ `DONE-R7.md` §4 同一判据）。

---

## ⑤ 合规声明

- 只写 `Rank-4\DONE-R8.md`（新建）+ 唯一例外 `teamwork\command_center\ai\4\outbox\receipt_R8_A4.json` 回执；**未写 `godot\project.godot`、未写 `godot\scenes\`**、未写 `godot\assets\generated\` / `godot\scripts\render\` 任何既有件、未写其它工位 / 工程根其它子目录 / 群聊总线 / 总纲 / 契约 / 任务书；未自行 `git commit` / `git push`。
- **本轮为「零改动验收轮」**：既有件（`hd2d_placeholder.gd`、`hd2d_placeholder_attach.gd`、4 份落位 JSON、R2~R7 全部冻结 JSON / DONE / 规范文档、`courtyard.tscn`、`build_courtyard.gd`、`project.godot`）一律**引用、不重做、一个字节未改**。
- 零付费 / 零外部依赖：付费 API 一律禁用，不列云服务、不列花费确认项；本轮无任何网络出图调用、无第二个 GPU job；程序化占位与挂载辅助只用 Godot 4 内置原语与工程内既有 `.gd`。
- **ComfyUI 仍是主美术路线**；`qwen-image` 仅为同为零付费的本地备选、本轮判长期阻塞；程序化 `_draw()` 占位为**正式零依赖兜底**（§1.3），是兜底路线正式化，不取代 ComfyUI 主路线、不宣称占位为正式素材。
- `image/quantize.py` 是 **DiT 权重量化器**，**未**用作 256 色调色板量化器；调色板收敛走 ComfyUI / Aseprite / ImageMagick。
- `stable-audio`（gated 403）/ `gen3d` / `mia-rig` 不可用：不申请、不补装、不碰 WSL、不绕过。
- 默认不刺探：仅执行任务明确要求的 `Rank-4\*.png` 与两份日志只读检查、`palette_256.json` / `import.json` / `project.godot` / `scene_integration.md` 接入痕迹的定向只读核对、两段 `--check-only --script` 语法门禁（引擎副作用 `.godot/` 如实登记），未扫别人工位、未轮询、未写探针 / 测量 / preflight 脚本；`00-群聊总线.md` 开工只读一次。复核因 [复核4] 暴露 `courtyard.tscn` 被并行更新才做**一次**事件驱动的定向只读核对，非反复巡检。
- **并行更新如实登记**：复核时刻发现 `courtyard.tscn` 由 Rank-1 并行 R9 更新（mtime `02:28:35 → 03:17:51`、4701 → 5054 字节）并新增 `attach_hd2d_placeholder.gd`，均非本工位写入；本轮未写 `scenes\` / `project.godot` / Rank-1 文件一个字节，未运行其写回脚本，未重复写第二份回执、未改已归档回执。
- 中文 UTF-8；所有独立 JSON 与文档内嵌 `json` 围栏块合法可解析（4/4 落位 + 10/10 独立 + 16/16 内嵌），回执合法；GDScript 为 Godot 4 合法语法（`--check-only` 通过）。
- **不宣称已能出图、不伪造输出、不拉起第二个 GPU job、不臆造 ComfyUI 路径、不冒充全工程门禁全绿、不宣称场景已渲染可见、不夸大纹理级导入已生效**：这是本轮最重要的一条。
