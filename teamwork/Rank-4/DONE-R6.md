# DONE-R6 · Rank-4（美术管线与工具链）完成标志

> 轮次：**R6（美术资产与程序化占位装配）**｜派单：`cmd-20261109-022337-016-A4`（`command_center\ai\4\inbox\`）｜主任务书：`Rank-4\任务书-R6.md`
> 授权：`MSG-20261109-0223-HOST` 总指挥裁决（空转保护解除、工程根落位授权，Rank-4 可写 `godot\assets\generated\` 与 `godot\scripts\render\hd2d_placeholder.gd`）
> 必读（开工只读一次）：`任务书-R6.md`、`hd2d_placeholder.md`、`hd2d_placeholder_r5_params.json`、`DONE-R5.md`、`00-协作契约.md`、`00-群聊总线.md`
> 口径：`00-协作契约.md` §5 / §9.3 / §10（像素导入四值、128px + ≤256 色、ComfyUI 主路线、零付费）；R2 冻结 18 键参数表；R5 `_draw()` 十步方案
> **HOST 监测只认本文件。** 唯一可写 `Rank-4\` + `godot\assets\generated\` + `godot\scripts\render\hd2d_placeholder.gd`；唯一例外 `command_center\ai\4\outbox\` 回执。**不写 `godot\project.godot`（Rank-1 独占）**
> 本轮定位：**装配**。把 R2/R5 冻结的 4 份规格 JSON 落位工程根 `assets/generated/`，把 R5 的「程序化 `_draw()` 占位方案」真正落成可被引擎校验的 GDScript；出图 job 仍无 PNG、ComfyUI 路径仍未登记 → 如实记阻塞，不硬造、不重复拉 GPU job、不宣称已能出图。

---

## ① 实际交付清单

### 1.1 本轮实际新建 / 改动文件（8 个，全部真实落盘）

| # | 文件（绝对路径） | 动作 | 内容 |
|---|---|---|---|
| 1 | `F:\Game\aierdengfahuan\godot\assets\generated\palette_256.json` | **新建（复制落位）** | ≤256 色索引调色板规格件，`cmp` 与 `Rank-4\` 源件字节一致 |
| 2 | `F:\Game\aierdengfahuan\godot\assets\generated\pose_names.json` | **新建（复制落位）** | 22 个冻结 pose 名，字节一致 |
| 3 | `F:\Game\aierdengfahuan\godot\assets\generated\import.json` | **新建（复制落位）** | 像素导入规格（四项 `expected_import_settings` + 128px），字节一致 |
| 4 | `F:\Game\aierdengfahuan\godot\assets\generated\delivery_manifest.json` | **新建（复制落位）** | I-5 M0 零 PNG 占位批次清单，字节一致 |
| 5 | `F:\Game\aierdengfahuan\godot\scripts\render\hd2d_placeholder.gd` | **新建** | Godot 4 合法 GDScript：单 `Node2D._draw()` 十步顺序（9 视差层 + 1 步湿地倒影）、多层视差 / 光尘 / 倒影 / 体积光 / bloom / 32×32 像素实体 / 金线深蓝 UI，零外部依赖、纯程序化绘制（14670 字节 / 375 行） |
| 6 | `F:\Game\aierdengfahuan\teamwork\Rank-4\ART-ASSEMBLY.md` | **新建** | 资产清单、占位方案落位说明、导入口径核对、出图 / ComfyUI 阻塞如实登记、合规声明 |
| 7 | `F:\Game\aierdengfahuan\teamwork\Rank-4\DONE-R6.md` | **新建** | 本文件（完成标志，①②③ 三段齐全） |
| 8 | `F:\Game\aierdengfahuan\teamwork\command_center\ai\4\outbox\receipt_R6_A4.json` | **新建（回执）** | 中枢回执 `dict(4)`；写入后被中枢实时消费归档到 `command_center\dispatcher\receipts\receipt_R6_A4.json`（见 §1.4 / §2.5） |

> 四份落位件用 `cp -n`（no-clobber）+ `cmp -s` 逐件校验字节一致，sha256：
> `palette_256.json` = `59c5c5bb…5fdd626f905bd5`｜`pose_names.json` = `935bc6c5…ed5fc868f1cfc16adae221fc687ba`
> `import.json` = `adc4b203…a646aaab750a49bd98df2688`｜`delivery_manifest.json` = `2ca3d0f6…fed5ffdd626f905bd5`
> 落位前 `godot/assets/generated/` 不存在、无既有件 → 未覆盖任何文件；源冻结件一个字节未改。

### 1.2 引擎门禁自动产物与非本工位文件（如实登记，非手工写入）

- 任务书 §真跑要求执行 `--headless --import` 时，Godot 4.7.2 在 `godot/` 自动生成 `.godot/` 导入缓存与 `scripts/render/hd2d_placeholder.gd.uid`。**这是引擎运行三段门禁的副作用，不是本工位手工写入的交付件**，且 `.godot` 属工程本地缓存（通常在 `.gitignore` 内）。
- 开工时 `godot/` 工程根不存在，本工位为落位 `mkdir -p` 了 `assets/generated` 与 `scripts/render` 两个子目录（在授权可写范围内）。**`godot\project.godot` 由 Rank-1 并行落位，本工位未写、未改、未覆盖**；`scripts/core|combat|rpg|ui|world`、`scenes`、`data/*`、`assets/audio/voice` 等均为其它工位并行产出，本工位一个字节未碰。
- 出图日志 `asset_proof_stdout.txt` / `asset_proof_stderr.log` 本轮**只读检查、未写入**（R3 产出原样保留）。

### 1.3 对照 HOST 本轮五项要求（逐项处理）

| # | 本轮要求 | 本轮处理 | 实际结论 |
|---|---|---|---|
| 1 | 4 份 JSON 落位 `godot\assets\generated\` | **已完成** | 4/4 落位、`cmp` 字节一致、解析通过，见 §1.1 / §2.2 |
| 2 | `_draw()` 方案落成合法 GDScript `hd2d_placeholder.gd`（零外部依赖、纯程序化） | **已完成** | 10 步 + 9 视差系数 + 四效 + bloom + 像素实体 + UI；`--check-only` EXIT=0 / SCRIPT ERROR=0，见 §2.2 / §2.3 |
| 3 | 核对像素导入口径 + 128px / ≤256 色，所有 JSON 内联真跑解析 | **已完成** | 口径 12/12 PASS；落位 4/4 + 独立 10/10 + 内嵌 16/16 + 回执 `dict(4)` 真跑解析通过，见 §2.2 / §2.5 |
| 4 | 只读检查出图 PNG / 两份日志；绝不启动第二个 GPU job；无 PNG 如实记阻塞；ComfyUI 未登记如实记阻塞 | **如实执行** | 全工程无 PNG、日志停在 `checkpoint shards 50%` 约 66 分钟无新增 → 记阻塞、不宣称已能出图、不伪造；未启动第二个 GPU job、未杀 / 未重启；ComfyUI 路径 / 工作流 JSON 仍「待用户提供 / 待刺探指令」→ 记阻塞、不臆造，见 §2.4 / ③ |
| 5 | `ART-ASSEMBLY.md` 与 `DONE-R6.md`（三段齐全）+ 回执 | **已完成** | 两份文档齐备、本文件 ①②③ 齐全；回执写入并被消费归档且验证合法 |

**结论**：五项要求逐项处理齐备。唯一依赖外部源图的动作（收敛 / 对齐 / 出图验收通过）按「如实记阻塞」降级；不依赖外部的两项（JSON 装配、程序化占位落地）已真实落盘并经引擎 / 解析器真跑核对。

### 1.4 回执落位说明

回执按任务单 id 写入 `command_center\ai\4\outbox\receipt_R6_A4.json`。写入后中枢（`AierdengfahuanCommander.exe` 机制，同 `DONE-R3.md` §1.4 / `DONE-R4.md` §1.4 / `DONE-R5.md` §1.4）**实时消费**并归档到 `command_center\dispatcher\receipts\receipt_R6_A4.json`，outbox 随之清空。§2.5 的最终真跑解析指向实际落位（`receipts`）→ `dict(4)`、`task_id` 与派单一致、`ai=4`、`status=done`、`result` 引用本文件实际结论。本轮不轮询、不伪造「已被接收」之外的状态、不重复写第二份回执。

---

## ② 自检结果（真跑 / 解析的实际输出结论）

### 2.1 真跑方式

- 用**内联 `python`**（`python - <<'PY'`，不落任何脚本文件）做交付自检：`json.load` 解析落位件 / `Rank-4\*.json` 全部独立文件 / 中枢回执，`json.loads` 解析 `Rank-4\*.md` 全部行首 `json` 围栏代码块；口径与参数对齐用只读正则核对。依据 `DONE-R2.md` §2.1 ~ `DONE-R5.md` §2.1 一贯口径（**交付自检，不是探针 / 测量 / preflight 脚本**）。Python `3.13.14`。
- 引擎真跑：`D:\Godot\Godot_v4.7.2-stable_win64.exe` 三段门禁（`--headless --import` → `--check-only --script` → `--headless --quit`）并 grep `SCRIPT ERROR`；实际 stdout 见 §2.3。
- 出图 / PNG 只读验收：任务明确要求的只读动作，实际输出见 §2.4。**未启动任何出图进程 / 第二个 GPU job**。
- 本 `DONE-R6.md` 与 `ART-ASSEMBLY.md` 内所有代码块用 `text` 标记、不含以 `json` 语言标记的行首围栏代码块，故写完统计仍为 **16/16**（自检口径自洽，与 `DONE-R5.md` §2.3 做法一致）；写文档后已再跑一次最小复核确认（§2.6）。

### 2.2 全部 JSON 内联真跑解析 + 口径 / 参数对齐核对（最终自检实际 stdout）

```text
=== [A] 落位件 4 个 JSON 真跑解析 (godot/assets/generated) ===
  OK   palette_256.json             dict(12)
  OK   pose_names.json              dict(14)
  OK   import.json                  dict(31)
  OK   delivery_manifest.json       dict(20)
  -> 落位 JSON: 4/4 解析通过
=== [B] 源 Rank-4 全部独立 JSON 真跑解析 ===
  OK   delivery_manifest.json               dict(20)
  OK   hd2d_placeholder_params.json         dict(18)
  OK   hd2d_placeholder_r5_params.json      dict(23)
  OK   import.json                          dict(31)
  OK   palette_256.json                     dict(12)
  OK   player_idle_v1.import.json           dict(31)
  OK   pose_names.json                      dict(14)
  OK   prompt_skeleton.json                 dict(20)
  OK   调度任务单-R2.json                        dict(9)
  OK   调度任务单-latest.json                    dict(9)
  -> 独立 JSON: 10/10 解析通过
=== [C] Rank-4 文档内嵌 json 围栏块真跑解析（仅行首 ```json） ===
  OK   ASSET-PROOF.md                 block#1 dict(20)
  OK   HD-2D视觉规范.md                   block#2 dict(12)
  OK   R4-验收记录.md                     block#3 dict(8)
  OK   hd2d_placeholder.md            block#4 dict(2)
  OK   hd2d_placeholder.md            block#5 dict(10)
  OK   hd2d_placeholder.md            block#6 dict(3)
  OK   工具链配置.md                       block#7 dict(1)
  OK   工具链配置.md                       block#8 dict(1)
  OK   美术管线.md                        block#9 dict(23)
  OK   美术管线.md                        block#10 dict(15)
  OK   美术管线.md                        block#11 dict(2)
  OK   美术管线.md                        block#12 dict(5)
  OK   资产交付契约.md                      block#13 dict(24)
  OK   资产交付契约.md                      block#14 dict(24)
  OK   资产交付契约.md                      block#15 dict(15)
  OK   资产交付契约.md                      block#16 dict(8)
  -> 内嵌 JSON 块: 16/16 解析通过
=== [D] 像素导入口径 + 128px / ≤256 色索引调色板核对 ===
  OK   compress_mode = lossless
  OK   mipmaps = false (关 mipmaps)
  OK   texture_filter = Nearest
  OK   project_default_texture_filter = 0
  OK   import.canvas_base_px = 128
  OK   palette.spec.canvas_base_px = 128
  OK   palette.indexed = true
  OK   palette.max_colors = 256
  OK   palette.color_count(32) <= 256
  OK   palette_id 与 import 引用一致
  OK   import.pose_names 全在冻结表
  OK   pose frozen_name_count = 22
  -> 口径核对: 12/12 通过
=== [E] GDScript 与冻结参数对齐抽查（只读正则） ===
  冻结视差系数 : [0.05, 0.15, 0.35, 0.7, 0.45, 1.0, 1.0, 1.25, 0.0]
  GDScript 系数 : [0.05, 0.15, 0.35, 0.7, 0.45, 1.0, 1.0, 1.25, 0.0]
  视差系数一致 : True  层数 = 9 (期望 9)
  _pass_ 步数  : 10 (期望 10)
  四类效果原语 : True
  零外部依赖   : True
  gd bytes=14670 lines=375
```

> 结论：落位 **4/4** + 独立 **10/10** + 内嵌 **16/16** + 口径 **12/12** 全部真跑解析 / 核对通过；GDScript 的 9 个视差系数与 `hd2d_placeholder_r5_params.json::parallax` 逐值一致、`_pass_` 10 步、四类效果原语齐备、无 `load/preload/res://`（零外部依赖）。

### 2.3 引擎三段门禁实际输出结论（含首次 FAIL 与处置，不隐瞒）

**段 2 `--headless --check-only --script hd2d_placeholder.gd`（针对本轮 .gd 的核心门禁）**：

- 首次真跑 **FAIL**：`EXIT=1`、`SCRIPT ERROR: Parse Error: The variable type is being inferred from a Variant value, so it will be typed as Variant. (Warning treated as error.)`，定位 `hd2d_placeholder.gd:157` → `var ox := round(-cam_x * coefficient)`，全局 `round()` 返回 Variant，`:=` 推断为 Variant 触发 Godot 4 静态检查的「警告当错误」。
- 处置（只改本轮新建的 .gd，不碰任何冻结件）：把 6 处 `round()` 结果统一包 `float()`（`float(round(...))`）、把 `var ch := row[px]` 显式标注为 `var ch: String = row[px]`，消除 Variant 推断。
- 复跑 **全绿**：`EXIT=0`、`SCRIPT_ERROR_count = 0`、`Parse_Error_count = 0`、`ERROR_count = 0`，输出仅 Godot 版本横幅。

**段 1 `--headless --import --path godot` 与 段 3 `--headless --quit --path godot`（关键行摘录，未删改结论）**：

```text
=== [段1] --headless --import --path godot ===
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
[ DONE ] first_scan_filesystem
ERROR: Attempt to open script 'res://scripts/world/world_state.gd' resulted in error 'File not found'.
ERROR: Failed to create an autoload, can't load from UID or path: res://scripts/world/world_state.gd.
ERROR: Attempt to open script 'res://scripts/core/game_events.gd' resulted in error 'File not found'.
ERROR: Failed to create an autoload, can't load from UID or path: res://scripts/core/game_events.gd.
ERROR: Attempt to open script 'res://scripts/world/save_system.gd' resulted in error 'File not found'.
ERROR: Failed to create an autoload, can't load from UID or path: res://scripts/world/save_system.gd.
[ DONE ] update_scripts_classes / loading_editor_layout
EXIT=0
=== [段3] --headless --quit --path godot ===
ERROR: Failed to instantiate an autoload, can't load from path: res://scripts/world/world_state.gd.
ERROR: Failed to instantiate an autoload, can't load from path: res://scripts/core/game_events.gd.
ERROR: Failed to instantiate an autoload, can't load from path: res://scripts/world/save_system.gd.
WARNING: [ChunkManager] chunk_limgrave_* 加载跳过：scene_missing  (共 9 条，9 个 chunk)
EXIT=0
=== 三段 SCRIPT ERROR / ERROR 计数（内联 python） ===
SCRIPT_ERROR_count = 0
ERROR_count = 18
combined_bytes = 8715
```

> 判读（如实、不冒充全绿）：三段门禁 **SCRIPT ERROR 合计 0**；段 1 / 段 3 各 `EXIT=0`，但各有 **9 条 ERROR**（合计 18），全部是 `res://scripts/world/world_state.gd`、`res://scripts/core/game_events.gd`、`res://scripts/world/save_system.gd` 三个 autoload 路径在 Rank-1 的 `project.godot` 里指向尚未就位 / 路径不同的脚本；段 3 另有 9 条 `ChunkManager scene_missing` WARNING。**均为 Rank-1 / Rank-3 跨工位依赖未就位，与本轮 `hd2d_placeholder.gd` 无关**（该脚本未被挂进 Main 场景，段 2 单独校验全绿）。按任务书「跨工位依赖未就位导致的 ERROR 如实登记，不冒充全绿、不伪造输出」执行，不擅自改 autoload 路径、不改 `project.godot`、不改别人工位脚本。

### 2.4 出图结果 / PNG 只读验收（实际输出结论）

```text
=== NOW === 2026-11-09 02:27:33 +0800
=== [1] Rank-4 *.png ===
ls: cannot access '.../Rank-4/*.png': No such file or directory
=== [2] 全工程 PNG (find -iname '*.png') ===  （空，无输出）
=== [3] 两份日志 stat ===
asset_proof_stdout.txt | 0 bytes     | mtime=2026-11-09 01:05:48 +0800
asset_proof_stderr.log | 25320 bytes | mtime=2026-11-09 01:21:30 +0800
=== [7] 日志内容只读分析 (内联 python) ===
stdout bytes = 0
stderr total_bytes = 25320
stderr tail = '... Fetching 2 files: 100%|██████████| 2/2 [00:00<00:00, 999.83it/s]
  Loading checkpoint shards:   0%|          | 0/2 [00:00<?, ?it/s]
  Loading checkpoint shards:  50%|█████     | 1/2 [05:35<05:35, 335.95s/it]'
报错类关键字计数 = 0
完成类关键字计数 = 0
```

**判读（如实）**：与 `DONE-R5.md` §2.6 一致并更久 —— 权重 `750/750` 已加载、`checkpoint shards 50%(1/2)`、仍无 PNG；日志 mtime `01:21`、检查时刻 `02:27`，约 **66 分钟无新增输出**；报错类 / 完成类关键字命中均 **0**；stdout 0 字节 → `--json` 结果对象（timing / peak VRAM / 输出路径）未产生。**单一长时后台 job 停在 transformer checkpoint shard 1/2 加载，未进入去噪 / 写图；不是崩溃而是极慢加载。** 无 PNG → 按本轮指令走「如实记阻塞」分支：不宣称已能出图、不伪造 PNG / 结果 JSON / 校验数据；**未启动第二个 GPU job**，单一后台 job 未杀 / 未重启 / 未并行。

### 2.5 中枢回执 JSON 真跑解析（最终自检实际 stdout）

```text
=== [F] 中枢回执 JSON 真跑解析 ===
  OK   receipts  dict(4)
       task_id = cmd-20261109-022337-016-A4
       ai      = 4
       status  = done
       result_len = 1240
       task_id_matches_dispatch = True
       result_引用_DONE-R6 = True
```

> `receipts`：写入 outbox 后中枢实时消费并归档到 `command_center\dispatcher\receipts\receipt_R6_A4.json`（§1.4）。解析指向实际落位 → `dict(4)`、`task_id` 与派单一致、`ai=4`、`status=done`、`result` 1240 字、引用本文件实际结论。

### 2.6 写完文档后的最小复核（保证 §2.2 口径自洽）

写完 `ART-ASSEMBLY.md` 与 `DONE-R6.md` 后再跑一次内联 python：落位 4 件 `json.load` 仍 4/4；`Rank-4\*.md` 行首 `json` 围栏块仍 **16/16**（两份新文档用 `text` 标记、未新增 `json` 围栏）；回执 `receipts` 仍 `dict(4)` 合法。结论与 §2.2 / §2.5 一致，无漂移。

---

## ③ 未完成项与阻塞（如实，全部非谎报）

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| 1 | `qwen-image --quant nf4` 首次出图 | **未完成 / 阻塞（进行中）** | 单一后台 job 停在 `transformer checkpoint shards 50%(1/2)`，日志 `01:21` 起约 66 分钟无新增；无 PNG / 无结果 JSON / 无报错。不宣称已能出图、不伪造输出；未杀 / 未重启 / 未并行，最终以 `asset_proof_stdout.txt` / `asset_proof_stderr.log` 为准 |
| 2 | alpha / 128px / ≤256 色收敛校验 | **无法执行（阻塞）** | 无源 PNG；收敛路线（ComfyUI / Aseprite / ImageMagick，不混用 `image/quantize.py` DiT 权重量化器）与判据见 `R4-验收记录.md` §2，沿用不改；不编造校验数据 |
| 3 | 装饰 RGBA 层与 base 逐像素对齐抽检 | **无法执行（阻塞）** | 无 base、无装饰层（全工程图片计数 0）；判据见 `R4-验收记录.md` §4，沿用不改；不臆造「已对齐 / 不一致像素数=0」 |
| 4 | ComfyUI 本机路径与工作流 JSON 登记 + `GET /object_info` 6 类节点核对 | **阻塞** | `00-工具链接入说明.md` §7 / 第 103 行仍「待用户提供 / 待刺探指令」，本轮 HOST 未提供、目录无工作流 JSON；不臆造地址、不尝试连接、不绕过、不主动扫盘。**ComfyUI 仍是主美术路线** |
| 5 | `style_anchor.png` / 128px 精灵表 / OpenPose 骨架库 | **未产出** | 本机未跑出图，全工程图片类文件计数 0；不伪造 |
| 6 | 显存档位 A~D / 峰值显存实测 | **未实测** | stdout 无 `--json` 结果（0 字节），只有 R3 记录的加载阶段 14203 MiB（非最终峰值）；不编造耗时 / 峰值 |
| 7 | 主角 / Boss / 关键场景 Aseprite 人工精修 | 未开始 | 人工环节（M1 / M5），`human_refine=done` 才允许交付 |
| 8 | 引擎三段门禁「全绿」 | **未达成（如实登记）** | 段 2 `--check-only` 全绿；段 1 / 段 3 各 9 条 ERROR（合计 18）为 Rank-1/3 autoload 脚本与 ChunkManager 场景未就位，SCRIPT ERROR 合计 0。按任务书如实登记，不冒充全绿、不擅自改 `project.godot` 或别人工位 |
| 9 | `import.json::palette_ref` 的 `_palette/` 子路径与实际落位平级差异 | **登记 / 待 1 号导入对齐** | 该件 `sample_only=true` 为字段样例；本轮按任务书落在 `assets/generated/` 平级，不擅改冻结字段，登记为 1 号导入时对齐项 |
| 10 | `hd2d_placeholder.gd` 挂入 Main 场景实渲染 | **未执行** | 场景树 / Main.tscn 归 Rank-1；本轮只交付可被引擎校验的脚本，不建场景、不改 1 号文件 |
| 11 | 付费 API / `stable-audio`(gated 403) / `gen3d` / `mia-rig` | **禁用 / 不碰** | 不申请、不补装、不碰 WSL、不绕过；不列「确认花费」为待办 |
| 12 | 群聊总线追加 `TYPE=交付完成` 消息 | **本轮不执行** | 本轮硬性约束「不写总线」，且总线不在唯一可写范围；以 HOST 最新指令为准 |

---

## ④ 完成标准判定

| 判据 | 结论 |
|---|---|
| 本轮 HOST 五项要求逐项处理 | ✓ 装配 4 JSON + 落成 `.gd` + 口径核对 / 全 JSON 真跑解析 + 出图 / ComfyUI 阻塞如实登记 + 两份文档与回执，5/5 处理齐备 |
| `godot\assets\generated\` 4 件落位、不覆盖既有件、源冻结件不改 | ✓ `cp -n` + `cmp -s` 字节一致，落位前目录无既有件 |
| `hd2d_placeholder.gd` 为 Godot 4 合法语法、零外部依赖、纯程序化 | ✓ `--check-only` EXIT=0 / SCRIPT ERROR=0；10 步 / 9 视差系数与冻结表一致 / 四效原语齐备 / 无 `load/preload/res://` |
| 像素导入口径 + 128px / ≤256 色核对 | ✓ 12/12 PASS（lossless / 关 mipmaps / Nearest / `default_texture_filter=0` / 128px / `indexed=true` `max_colors=256`） |
| 所有 JSON 合法可解析（落位 + 独立 + 内嵌 + 回执） | ✓ 落位 **4/4** + 独立 **10/10** + 内嵌 **16/16** + 回执 `dict(4)`（`task_id` 匹配 / `ai=4` / `status=done`）真跑解析通过 |
| 三段门禁并 grep `SCRIPT ERROR` | ✓ 已跑；SCRIPT ERROR 合计 0；18 条跨工位 ERROR / 9 条 WARNING 如实登记，不冒充全绿 |
| 不宣称已能出图 / 不伪造输出 / 不拉第二个 GPU job / 不臆造 ComfyUI 路径 | ✓ 无 PNG 如实记阻塞；只读日志验收；单一后台 job 未杀未重启未并行；ComfyUI 路径未登记记阻塞 |
| `ART-ASSEMBLY.md` / `DONE-R6.md` 三段齐全 | ✓ 两份文档齐备，本文件 ①实际交付清单 / ②自检真跑输出结论 / ③未完成项与阻塞 齐全 |
| 中枢回执 | ✓ `command_center\ai\4\outbox\receipt_R6_A4.json`（`status=done`，`result` 引用本文件实际结论），已被中枢消费归档并验证合法 |
| 既有件不重做 / 不越界 / 不写 `project.godot` | ✓ R2~R5 全部冻结件一个字节未改；只写授权范围；`project.godot` 未写未改（Rank-1 并行落位） |

**本轮 R6 达成**：按「装配」定位，把 4 份冻结规格 JSON 真实落位工程根、把 R5 的 `_draw()` 方案真实落成可被引擎校验的 GDScript，全部 JSON 内联真跑解析、导入口径 12/12 核对、三段门禁真跑并把实际输出（含首次 FAIL 与处置、跨工位 ERROR）写进自检；出图 / ComfyUI / 收敛 / 对齐等依赖外部源图或跨工位的项如实记阻塞、不硬造、不重复拉 GPU job。未完成项均属任务书允许的「尽力而为 / 如实降级」范围，不影响 R6 完成判定（与 `DONE-R2.md` §4 ~ `DONE-R5.md` §4 同一判据）。

---

## ⑤ 合规声明

- 只写 `Rank-4\`（`ART-ASSEMBLY.md`、`DONE-R6.md`）+ `godot\assets\generated\` 4 件 + `godot\scripts\render\hd2d_placeholder.gd`；唯一例外 `command_center\ai\4\outbox\receipt_R6_A4.json` 回执。**未写 `godot\project.godot`**（Rank-1 独占）、未写其它工位 / 工程根其它子目录 / 群聊总线 / 总纲 / 契约 / 任务书；未自行 `git commit` / `git push`。
- 零付费 / 零外部依赖：付费 API 一律禁用，不列云服务、不列花费确认项；本轮无任何网络出图调用、无第二个 GPU job；程序化占位只用 Godot 4 内置 `_draw()` 原语。
- **ComfyUI 仍是主美术路线**；`qwen-image` 仅为同为零付费的本地备选（姿势基准图 / kit 图 / 装饰层底稿），不取代；程序化 `_draw()` 仅 M0 占位 / 显存不足降级，不取代二者。
- `image/quantize.py` 是 **DiT 权重量化器**，**未**用作 256 色调色板量化器；调色板收敛走 ComfyUI / Aseprite / ImageMagick。
- `stable-audio`（gated 403）/ `gen3d` / `mia-rig` 不可用：不申请、不补装、不碰 WSL、不绕过。
- 默认不刺探：仅执行任务明确要求的 `Rank-4\*.png` 与两份日志只读检查 + 三段门禁（引擎副作用 `.godot/` 如实登记），未扫别人工位、未轮询、未写探针 / 测量 / preflight 脚本；`00-群聊总线.md` 开工只读一次。
- 中文 UTF-8；所有独立 JSON 与文档内嵌 `json` 围栏块合法可解析（4/4 落位 + 10/10 独立 + 16/16 内嵌），回执合法；GDScript 为 Godot 4 合法语法。
- **不宣称已能出图、不伪造输出、不拉起第二个 GPU job、不臆造 ComfyUI 路径、不冒充门禁全绿**：这是本轮最重要的一条。
