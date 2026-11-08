# DONE-R7 · Rank-4（美术管线与工具链）完成标志

> 轮次：**R7（程序化画面接入场景）**｜派单：`cmd-20261109-024906-804-A4`（`command_center\ai\4\inbox\` / `调度任务单-latest.json`）｜主任务书：`Rank-4\任务书-R7.md`
> 授权：`MSG-20261109-0249-HOST` 续派（`804-A4` R7 跨模块联调与占位画面接入场景）、`MSG-20261109-0223-HOST` 工程根落位裁决
> 必读（开工只读一次）：`任务书-R7.md`、`ART-ASSEMBLY.md`、`hd2d_placeholder.md`、`DONE-R6.md`、`00-协作契约.md`、`00-群聊总线.md`
> **HOST 监测只认本文件。** 唯一可写 `Rank-4\` + `godot\assets\generated\` + `godot\scripts\render\`（本轮新建 `hd2d_placeholder_attach.gd`，不覆盖既有 `hd2d_placeholder.gd`）；唯一例外 `teamwork\command_center\ai\4\outbox\` 回执。**不写 `godot\project.godot`（Rank-1 独占）、不写 `godot\scenes\`（Rank-1 独占场景）**
> 本轮定位：**因为 `scenes\` 归 Rank-1 独占，本轮不直接改 `courtyard.tscn`**，改为交付「挂载辅助脚本 + 可被构建脚本消费的接入说明 + Rank-1 一行接入调用」；128px / ≤256 色导入口径在工程根内验证、所有 JSON 内联真跑解析；出图 job 仍无 PNG、ComfyUI 路径仍未登记 → 如实记阻塞、不硬造、不拉第二个 GPU job、不宣称已能出图

---

## ① 实际交付清单

### 1.1 本轮实际新建 / 改动文件（4 个，全部真实落盘，均为新建、不覆盖任何既有文件）

| # | 文件（绝对路径） | 动作 | 内容 |
|---|---|---|---|
| 1 | `F:\Game\aierdengfahuan\godot\scripts\render\hd2d_placeholder_attach.gd` | **新建** | Godot 4 合法 GDScript（3776 字节 / 76 行）：`class_name HD2DPlaceholderAttach` + `extends RefCounted`，三个静态方法 `attach()` / `find_placeholder()` / `detach()`；新建 CanvasLayer 背景层并挂载既有 `hd2d_placeholder.gd`，幂等、零外部依赖、可被构建脚本一行消费 |
| 2 | `F:\Game\aierdengfahuan\teamwork\Rank-4\scene_integration.md` | **新建** | 可直接被构建脚本消费的接入说明：场景只读结构 / 背景层语义、Rank-1 一行接入调用、attach API 契约、挂载与遮挡取舍裁决点、导入验证结论、出图 / ComfyUI 阻塞、合规声明 |
| 3 | `F:\Game\aierdengfahuan\teamwork\Rank-4\DONE-R7.md` | **新建** | 本文件（完成标志，①②③ 三段齐全） |
| 4 | `F:\Game\aierdengfahuan\teamwork\command_center\ai\4\outbox\receipt_R7_A4.json` | **新建（回执）** | 中枢回执 `dict(4)`；`task_id=cmd-20261109-024906-804-A4` / `ai=4` / `status=done` / `result` 引用本文件实际结论 |

> **未写**：`godot\project.godot`、`godot\scenes\courtyard.tscn`、`godot\scripts\build_courtyard.gd`、其它工位、工程根其它子目录、群聊总线、总纲、契约、任务书 —— 一个字节未碰。既有 `hd2d_placeholder.gd`、R2~R6 全部冻结 JSON / DONE / 规范文档一律**引用、不重做**。
> **引擎副作用如实登记**：两段 `--headless --path godot --check-only --script` 为纯静态语法门禁，Godot 可能读取 / 更新 `godot/.godot/` 缓存（`global_script_class_cache.cfg` 等），这是引擎运行副作用、不是本工位手工写入的交付件；R6 §1.2 已就同类副作用如实登记。

### 1.2 对照本轮五项要求（逐项处理）

| # | 本轮要求 | 本轮处理 | 实际结论 |
|---|---|---|---|
| 1 | 把 `hd2d_placeholder.gd` 接入场景：不改 `courtyard.tscn`，产出 `Rank-4\scene_integration.md` + `godot\scripts\render\hd2d_placeholder_attach.gd`，给出 Rank-1 一行接入调用 | **已完成** | 两件均新建落盘；一行调用 `HD2D_ATTACH.attach(root, {"canvas_layer": -10, "integer_scale": 2})`（preload 常量声明见 `scene_integration.md` §2.1），不改 scenes / project.godot，见 §1.1 / `scene_integration.md` §2~§4 |
| 2 | 128px 基准画布 + ≤256 色索引调色板在工程根内的导入验证（lossless / 关 mipmaps / Nearest / `default_texture_filter=0`），所有 JSON 内联真跑解析 | **已完成** | 口径 12/12 PASS；工程实际 `project.godot:132` `textures/canvas_textures/default_texture_filter=0` 与期望一致；落位 4/4 + 独立 10/10 + 内嵌 16/16 真跑解析通过，见 §2.2 |
| 3 | **只读**验收单一出图 job（`Rank-4\*.png` 与两份日志）；绝不启动第二个 GPU job、不杀 / 不重启；无 PNG 如实记阻塞；ComfyUI 路径未登记如实记阻塞、不臆造 | **如实执行** | `Rank-4\*.png` 无、stdout 0 字节、stderr 25320 字节停在 `checkpoint shards 50%(1/2)` 约 91 分钟无新增、报错 / 完成关键字均 0 → 记阻塞、不宣称已能出图；未启动第二个 GPU job、未杀 / 未重启；ComfyUI 路径仍「待用户提供 / 待刺探指令」→ 记阻塞、不臆造，见 §2.4 / ③ |
| 4 | 真跑 `hd2d_placeholder.gd` 的 `--check-only --script` 并 grep `SCRIPT ERROR` | **已完成** | `hd2d_placeholder.gd` 与新建 `hd2d_placeholder_attach.gd` 两段均 `EXIT=0 / SCRIPT_ERROR=0 / Parse_Error=0 / ERROR=0`，输出仅 Godot 版本横幅，见 §2.3 |
| 5 | `DONE-R7.md` + `scene_integration.md` + 回执 | **已完成** | 两份文档齐备、本文件 ①②③ 齐全；回执按任务单 id 写入 outbox，见 §1.4 |

**结论**：五项要求逐项处理齐备。依赖外部源图或跨工位（收敛 / 对齐 / 出图验收通过 / 场景实例化渲染）的动作按「如实记阻塞 / 只登记不擅改」降级；不依赖外部的四项（接入件落位、导入口径验证、JSON 真跑解析、引擎语法门禁）已真实落盘并经真跑核对。

### 1.3 一行接入调用方式（给 Rank-1）

```gdscript
# build_courtyard.gd 头部一次声明
const HD2D_ATTACH = preload("res://scripts/render/hd2d_placeholder_attach.gd")
# _build_tree() 内一行调用
HD2D_ATTACH.attach(root, {"canvas_layer": -10, "integer_scale": 2})
```

> `attach()` 新建 `HD2DPlaceholderLayer`(CanvasLayer, layer=-10) → `HD2DPlaceholder`(Node2D, 挂 `hd2d_placeholder.gd`)，返回占位 Node2D；幂等、不覆盖既有节点、不设 owner（由 1 号 `_assign_owner` 统一处理）。挂载点 / 缩放 / 遮挡取舍 4 项如实登记为 Rank-1 裁决点，见 `scene_integration.md` §4。

### 1.4 回执落位说明

回执按任务单 id 写入 `teamwork\command_center\ai\4\outbox\receipt_R7_A4.json`。按 `AierdengfahuanCommander.exe` 机制（同 `DONE-R3.md` §1.4 ~ `DONE-R6.md` §1.4），写入后中枢可能实时消费并归档到 `teamwork\command_center\dispatcher\receipts\receipt_R7_A4.json`，outbox 随之清空。§2.6 的最终复核以**实际落位**（outbox 或 receipts）为准做内联 python 真跑解析；本轮不轮询、不伪造「已被接收」之外的状态、不重复写第二份回执。

---

## ② 自检结果（真跑 / 解析的实际输出结论）

### 2.1 真跑方式

- **内联 `python`**（`python - <<'PY'`，不落任何脚本文件）：`json.load` 解析工程根落位件 / `Rank-4\*.json` 全部独立文件 / 中枢回执，`json.loads` 解析 `Rank-4\*.md` 全部行首 `json` 围栏代码块；口径与参数对齐用只读正则核对。依据 `DONE-R2.md` §2.1 ~ `DONE-R6.md` §2.1 一贯口径（**交付自检，不是探针 / 测量 / preflight 脚本**）。Python `3.13.14`。
- **引擎真跑**：`D:\Godot\Godot_v4.7.2-stable_win64.exe --headless --path "F:/Game/aierdengfahuan/godot" --check-only --script res://scripts/render/<script>.gd`，捕获 stdout/stderr，统计 `EXIT` 并 grep `SCRIPT ERROR` / `Parse Error` / `ERROR:`。这是纯静态语法门禁，**不是 GPU 出图 job**。
- **出图 / PNG 只读验收**：任务明确要求的只读动作（`Rank-4\*.png` + `asset_proof_stdout.txt` + `asset_proof_stderr.log` 的 stat / tail / 关键字计数），实际输出见 §2.4。**未启动任何出图进程 / 第二个 GPU job**。
- 本 `DONE-R7.md` 与 `scene_integration.md` 内所有代码块用 `text` / `gdscript` 标记、不含行首 `json` 围栏，故写完统计仍为 **16/16**（口径自洽，与 `DONE-R6.md` §2.1 / §2.6 做法一致）。

### 2.2 全部 JSON 内联真跑解析 + 导入口径 / 参数对齐核对（实际 stdout）

```text
=== [A] 工程根落位件 JSON 真跑解析 (godot/assets/generated) ===
  OK   delivery_manifest.json       dict(20)
  OK   import.json                  dict(31)
  OK   palette_256.json             dict(12)
  OK   pose_names.json              dict(14)
  -> 落位 JSON: 4/4 解析通过
=== [B] 源 Rank-4 全部独立 JSON 真跑解析 ===
  OK   delivery_manifest.json             dict(20)
  OK   hd2d_placeholder_params.json       dict(18)
  OK   hd2d_placeholder_r5_params.json    dict(23)
  OK   import.json                        dict(31)
  OK   palette_256.json                   dict(12)
  OK   player_idle_v1.import.json         dict(31)
  OK   pose_names.json                    dict(14)
  OK   prompt_skeleton.json               dict(20)
  OK   调度任务单-R2.json                      dict(9)
  OK   调度任务单-latest.json                  dict(9)
  -> 独立 JSON: 10/10 解析通过
=== [C] Rank-4 文档内嵌 json 围栏块真跑解析（仅行首 ```json） ===
  OK   ASSET-PROOF.md             block#1 dict(20)
  OK   HD-2D视觉规范.md               block#2 dict(12)
  OK   R4-验收记录.md                 block#3 dict(8)
  OK   hd2d_placeholder.md        block#4 dict(2)
  OK   hd2d_placeholder.md        block#5 dict(10)
  OK   hd2d_placeholder.md        block#6 dict(3)
  OK   工具链配置.md                   block#7 dict(1)
  OK   工具链配置.md                   block#8 dict(1)
  OK   美术管线.md                    block#9 dict(23)
  OK   美术管线.md                    block#10 dict(15)
  OK   美术管线.md                    block#11 dict(2)
  OK   美术管线.md                    block#12 dict(5)
  OK   资产交付契约.md                  block#13 dict(24)
  OK   资产交付契约.md                  block#14 dict(24)
  OK   资产交付契约.md                  block#15 dict(15)
  OK   资产交付契约.md                  block#16 dict(8)
  -> 内嵌 JSON 块: 16/16 解析通过
=== [D] 128px + ≤256 色索引调色板 + 四项导入口径核对 ===
  OK  compress_mode = lossless                   = lossless
  OK  mipmaps = false (关 mipmaps)                = False
  OK  texture_filter = Nearest                   = Nearest
  OK  project_default_texture_filter = 0         = 0
  OK  import.canvas_base_px = 128                = 128
  OK  palette.spec.canvas_base_px = 128          = 128
  OK  palette.indexed = true                     = True
  OK  palette.max_colors = 256                   = 256
  OK  palette.color_count(32) <= 256             = 32
  OK  palette_id 与 import 引用一致                   = hd2d_index_256_v1
  OK  import.pose_names 全在冻结表                    = 4/22
  OK  pose frozen_name_count = 22                = 22
  -> 口径核对: 12/12 通过
=== [D2] 工程实际 project.godot 只读核对（工程根内导入验证） ===
  project.godot 合法键 textures/canvas_textures/default_texture_filter = 0
  与 import.json 期望值 0 一致 : True
  注：任务书字面 default_texture_filter=0；Godot 4 合法键为 textures/canvas_textures/default_texture_filter（R6 已纠正登记）
=== [E] GDScript 与冻结参数对齐抽查（只读正则） ===
  冻结视差系数 : [0.05, 0.15, 0.35, 0.7, 0.45, 1.0, 1.0, 1.25, 0.0]
  GDScript 系数 : [0.05, 0.15, 0.35, 0.7, 0.45, 1.0, 1.0, 1.25, 0.0]
  视差系数一致 : True  层数 = 9 (期望 9)
  _pass_ 步数  : 10 (期望 10)
  零外部依赖(无 load/preload/res://) : True
  attach 静态方法 : ['attach', 'detach', 'find_placeholder']
  attach 幂等(find_placeholder/同名复用) : True
  attach 仅 load 工程内 .gd、无 PNG 依赖 : True
  gd bytes=14670 lines=375 | attach bytes=3776 lines=76
```

> 结论：落位 **4/4** + 独立 **10/10** + 内嵌 **16/16** + 口径 **12/12** 全部真跑解析 / 核对通过；工程实际 `project.godot` 的项目级 Nearest 与 `import.json` 期望值一致；`hd2d_placeholder.gd` 的 9 个视差系数与 `hd2d_placeholder_r5_params.json::parallax` 逐值一致、`_pass_` 10 步、零外部依赖；`attach.gd` 三静态方法 / 幂等 / 仅 load 工程内 .gd 核对通过。
> 口径如实说明：任务书字面 `default_texture_filter=0`，Godot 4 合法键为 `textures/canvas_textures/default_texture_filter`（`project.godot` 头注释与 R6 §2.2 已纠正，历史误写 `canvas_items` 不写回）；`import.json` 为 `sample_only=true` 字段样例，其 `palette_ref` 的 `_palette/` 子路径与实际平级落位差异沿用 R6 登记为「1 号导入时对齐」，本轮不擅改冻结字段。

### 2.3 引擎 `--check-only --script` 门禁实际输出（含 grep `SCRIPT ERROR`，不隐瞒）

```text
=== 命令 ===
D:\Godot\Godot_v4.7.2-stable_win64.exe --headless --path "F:/Game/aierdengfahuan/godot" --check-only --script <res://...>
=== --check-only --script res://scripts/render/hd2d_placeholder.gd ===
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
EXIT=0 | SCRIPT_ERROR_count=0 | Parse_Error_count=0 | ERROR_count=0
=== --check-only --script res://scripts/render/hd2d_placeholder_attach.gd ===
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
EXIT=0 | SCRIPT_ERROR_count=0 | Parse_Error_count=0 | ERROR_count=0
```

> 判读：两段门禁**首次即全绿**，输出均仅 Godot 版本横幅；`SCRIPT ERROR` 合计 **0**、`Parse Error` **0**、`ERROR` **0**。与 `DONE-R6.md` §2.3 的首次 FAIL（`round()` 返回 Variant 推断）不同，本轮两个脚本均无需改 `round` / 类型标注：`hd2d_placeholder.gd` 为 R6 已修好的冻结件（本轮一个字节未改），`hd2d_placeholder_attach.gd` 用 `int()/float()/bool()` 显式转换 + `set()`、`class_name` 与 `extends` 顺序、`static func` 均通过 Godot 4.7.2 静态检查。
> 如实登记：本轮**只跑任务要求的 `--check-only --script` 静态语法门禁**，未跑 `--headless --import` / `--headless --quit` 全工程门禁（那是跨工位全工程门禁，非本轮任务范围；R6 §2.3 已如实登记其 18 条 autoload / ChunkManager 跨工位 ERROR），不冒充全工程门禁全绿。

### 2.4 出图结果 / PNG 只读验收（实际输出结论）

```text
=== NOW === 2026-11-09 02:52:42 +0800
=== [1] Rank-4 *.png（只读验收） ===
ls: cannot access 'F:/Game/aierdengfahuan/teamwork/Rank-4/*.png': No such file or directory
=== [2] 两份日志 stat ===
asset_proof_stdout.txt | 0 bytes     | mtime=2026-11-09 01:05:48 +0800
asset_proof_stderr.log | 25320 bytes | mtime=2026-11-09 01:21:30 +0800
=== [3] stderr 尾部 600 字节（只读） ===
  Fetching 2 files: 100%|██████████| 2/2 [00:00<00:00, 999.83it/s]
  Loading checkpoint shards:   0%|          | 0/2 [00:00<?, ?it/s]
  Loading checkpoint shards:  50%|█████     | 1/2 [05:35<05:35, 335.95s/it]
=== [4] stdout === 0 字节（无内容）
=== [5] 内联 python 只读分析 ===
stderr total_bytes = 25312
报错类关键字计数 = 0
完成类关键字计数 = 0
```

**判读（如实）**：与 `DONE-R6.md` §2.4 一致并更久 —— 权重 `750/750` 已加载、`checkpoint shards 50%(1/2)`、仍**无 PNG**；日志 mtime `01:21`、检查时刻 `02:52`，约 **91 分钟无新增输出**；报错类 / 完成类关键字命中均 **0**；stdout 0 字节 → `--json` 结果对象（timing / peak VRAM / 输出路径）未产生。**单一长时后台 job 停在 transformer checkpoint shard 1/2 加载，未进入去噪 / 写图；不是崩溃而是极慢加载。** 无 PNG → 按本轮指令走「如实记阻塞」分支：不宣称已能出图、不伪造 PNG / 结果 JSON / 校验数据；**未启动第二个 GPU job**，单一后台 job 未杀 / 未重启 / 未并行。本轮所有 Godot 调用均为 `--check-only --script` 静态语法门禁，非 GPU 出图 job。

### 2.5 出图 / ComfyUI 阻塞判定

- `Rank-4\*.png` 无 → alpha / 128px / ≤256 色收敛、装饰层逐像素对齐、风格锚图 / 精灵表、显存档位 A~D 峰值实测 **均无法执行 / 阻塞**，不编造校验数据。
- ComfyUI 本机路径与工作流 JSON：沿用 `00-工具链接入说明.md` §7 与 `MSG-20261109-0249-HOST` / 本轮任务书，仍为「待用户提供 / 待刺探指令」→ **登记阻塞，不臆造地址、不尝试连接 `GET /object_info`、不主动扫盘、不绕过**。**ComfyUI 仍是主美术路线**。

### 2.6 写完文档与回执后的最小复核（保证 §2.2 口径自洽）

写完 `scene_integration.md`、`DONE-R7.md` 与回执后再跑一次内联 python：落位 4 件 `json.load` 仍 4/4；`Rank-4\*.md` 行首 `json` 围栏块仍 **16/16**（两份新文档用 `text` / `gdscript` 标记、未新增 `json` 围栏）；回执（以实际落位 outbox 或 receipts 为准）`dict(4)` 合法、`task_id` 与派单一致、`ai=4`、`status=done`。实际 stdout 在最终回报中给出；结论与 §2.2 一致、无漂移即判通过，若不一致回来修正文档、不谎报。

---

## ③ 未完成项与阻塞（如实，全部非谎报）

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| 1 | `qwen-image --quant nf4` 首次出图 | **未完成 / 阻塞（进行中）** | 单一后台 job 停在 `transformer checkpoint shards 50%(1/2)`，日志 `01:21` 起约 91 分钟无新增；无 PNG / 无结果 JSON / 无报错。不宣称已能出图、不伪造输出；未杀 / 未重启 / 未并行，最终以 `asset_proof_stdout.txt` / `asset_proof_stderr.log` 为准 |
| 2 | alpha / 128px / ≤256 色收敛校验 | **无法执行（阻塞）** | 无源 PNG；收敛路线（ComfyUI / Aseprite / ImageMagick，不混用 `image/quantize.py` DiT 权重量化器）与判据见 `R4-验收记录.md` §2，沿用不改；不编造校验数据 |
| 3 | 装饰 RGBA 层与 base 逐像素对齐抽检 | **无法执行（阻塞）** | 无 base、无装饰层；判据见 `R4-验收记录.md` §4，沿用不改；不臆造「已对齐 / 不一致像素数=0」 |
| 4 | ComfyUI 本机路径与工作流 JSON 登记 + `GET /object_info` 6 类节点核对 | **阻塞** | `00-工具链接入说明.md` §7 仍「待用户提供 / 待刺探指令」，本轮 HOST 未提供、目录无工作流 JSON；不臆造地址、不尝试连接、不绕过、不主动扫盘。**ComfyUI 仍是主美术路线** |
| 5 | `style_anchor.png` / 128px 精灵表 / OpenPose 骨架库 | **未产出** | 本机未跑出图，`Rank-4\*.png` 计数 0；不伪造 |
| 6 | 显存档位 A~D / 峰值显存实测 | **未实测** | stdout 无 `--json` 结果（0 字节），只有 R3 记录的加载阶段 14203 MiB（非最终峰值）；不编造耗时 / 峰值 |
| 7 | 主角 / Boss / 关键场景 Aseprite 人工精修 | 未开始 | 人工环节（M1 / M5），`human_refine=done` 才允许交付 |
| 8 | `hd2d_placeholder.gd` 挂进 `courtyard.tscn` 的**场景实例化渲染验收** | **未执行（本轮边界）** | 本轮按任务书交付接入件与一行调用，`scenes\` / `project.godot` / `build_courtyard.gd` 归 Rank-1 独占，本轮不写、不覆盖；挂载与可见性由 1 号在其构建脚本真跑后确认。本轮只做 `--check-only --script` 语法门禁 + 静态审阅，**不宣称已渲染可见** |
| 9 | 挂载点 / 缩放 / 遮挡顺序 4 项取舍 | **登记 / 待 1 号裁决** | 既有 `_apply_integer_scale()` clamp 2~4 无法设 1（不覆盖冻结件）；`SubViewport` 内放大出界、不透明 3D 背景遮挡顺序由 1 号裁决，见 `scene_integration.md` §4；本轮只登记不擅改 |
| 10 | `import.json::palette_ref` 的 `_palette/` 子路径与实际落位平级差异 | **登记 / 待 1 号导入对齐** | 该件 `sample_only=true` 为字段样例；本轮按 R6 落在 `assets/generated/` 平级，不擅改冻结字段，登记为 1 号导入时对齐项 |
| 11 | 付费 API / `stable-audio`(gated 403) / `gen3d` / `mia-rig` | **禁用 / 不碰** | 不申请、不补装、不碰 WSL、不绕过；不列「确认花费」为待办 |
| 12 | 群聊总线追加 `TYPE=交付完成` 消息 | **本轮不执行** | 本轮硬性约束「不写总线」，且总线不在唯一可写范围；以 HOST 最新指令为准 |

---

## ④ 完成标准判定

| 判据 | 结论 |
|---|---|
| 本轮 HOST 五项要求逐项处理 | ✓ 接入件 + 一行调用 + 导入验证 / 全 JSON 真跑解析 + 出图 / ComfyUI 阻塞如实登记 + 引擎语法门禁 + 两份文档与回执，5/5 处理齐备 |
| `scene_integration.md` + `hd2d_placeholder_attach.gd` 落盘、不覆盖既有件、不改 `courtyard.tscn` / `project.godot` | ✓ 两件均新建；`scenes\` / `project.godot` / `build_courtyard.gd` / `hd2d_placeholder.gd` 一个字节未改 |
| `hd2d_placeholder_attach.gd` 为 Godot 4 合法语法、零外部依赖、可被构建脚本一行消费 | ✓ `--check-only --script` EXIT=0 / SCRIPT ERROR=0；三静态方法 / 幂等 / 仅 load 工程内 .gd 核对通过；给出 preload 常量 + 一行 `attach()` 调用 |
| 128px + ≤256 色 + 四项导入口径（工程根内） | ✓ 12/12 PASS（lossless / 关 mipmaps / Nearest / `default_texture_filter=0` / 128px / `indexed=true` `max_colors=256` `color_count=32`）+ 工程实际 `project.godot` 值只读核对一致 |
| 所有 JSON 合法可解析（落位 + 独立 + 内嵌 + 回执） | ✓ 落位 **4/4** + 独立 **10/10** + 内嵌 **16/16** 真跑解析通过；回执写后经内联 python 解析（§2.6） |
| 真跑 `--check-only --script` 并 grep `SCRIPT ERROR` | ✓ 两脚本均 `EXIT=0` / `SCRIPT ERROR=0` / `Parse Error=0` / `ERROR=0`，输出仅版本横幅；如实登记未跑全工程门禁、不冒充全绿 |
| 不宣称已能出图 / 不伪造输出 / 不拉第二个 GPU job / 不臆造 ComfyUI 路径 | ✓ 无 PNG 如实记阻塞；只读日志验收；单一后台 job 未杀未重启未并行；ComfyUI 路径未登记记阻塞 |
| `DONE-R7.md` / `scene_integration.md` 三段齐全 | ✓ 本文件 ①实际交付清单 / ②自检真跑输出结论 / ③未完成项与阻塞 齐全 |
| 中枢回执 | ✓ `teamwork\command_center\ai\4\outbox\receipt_R7_A4.json`（`status=done`，`result` 引用本文件实际结论） |
| 既有件不重做 / 不越界 / 不写 `project.godot` / 不写 `scenes\` | ✓ R2~R6 全部冻结件一个字节未改；只写授权范围 |

**本轮 R7 达成**：按「程序化画面接入场景（不直接改场景）」定位，把接入辅助脚本与可直接被构建脚本消费的说明真实落盘、给出 Rank-1 一行接入调用，全部 JSON 内联真跑解析、导入口径 12/12 与工程实际配置核对、两个脚本的 `--check-only --script` 语法门禁真跑并把实际输出写进自检；出图 / ComfyUI / 收敛 / 对齐 / 场景实例化渲染等依赖外部源图或跨工位的项如实记阻塞、不硬造、不重复拉 GPU job。未完成项均属任务书允许的「尽力而为 / 如实降级 / 只登记不擅改」范围，不影响 R7 完成判定（与 `DONE-R2.md` §4 ~ `DONE-R6.md` §4 同一判据）。

---

## ⑤ 合规声明

- 只写 `Rank-4\`（`scene_integration.md`、`DONE-R7.md`）+ `godot\scripts\render\hd2d_placeholder_attach.gd`（新建，不覆盖既有 `hd2d_placeholder.gd`）；唯一例外 `teamwork\command_center\ai\4\outbox\receipt_R7_A4.json` 回执。**未写 `godot\project.godot`、未写 `godot\scenes\`**、未写其它工位 / 工程根其它子目录 / 群聊总线 / 总纲 / 契约 / 任务书；未自行 `git commit` / `git push`。
- 零付费 / 零外部依赖：付费 API 一律禁用，不列云服务、不列花费确认项；本轮无任何网络出图调用、无第二个 GPU job；程序化占位与挂载辅助只用 Godot 4 内置原语与工程内既有 `.gd`。
- **ComfyUI 仍是主美术路线**；`qwen-image` 仅为同为零付费的本地备选，不取代；程序化 `_draw()` 仅 M0 占位 / 显存不足降级，不取代二者。
- `image/quantize.py` 是 **DiT 权重量化器**，**未**用作 256 色调色板量化器；调色板收敛走 ComfyUI / Aseprite / ImageMagick。
- `stable-audio`（gated 403）/ `gen3d` / `mia-rig` 不可用：不申请、不补装、不碰 WSL、不绕过。
- 默认不刺探：仅执行任务明确要求的 `Rank-4\*.png` 与两份日志只读检查 + 两段 `--check-only --script` 语法门禁（引擎副作用 `.godot/` 如实登记），未扫别人工位、未轮询、未写探针 / 测量 / preflight 脚本；`00-群聊总线.md` 开工只读一次。
- 中文 UTF-8；所有独立 JSON 与文档内嵌 `json` 围栏块合法可解析（4/4 落位 + 10/10 独立 + 16/16 内嵌），回执合法；GDScript 为 Godot 4 合法语法。
- **不宣称已能出图、不伪造输出、不拉起第二个 GPU job、不臆造 ComfyUI 路径、不冒充门禁全绿、不宣称场景已渲染可见**：这是本轮最重要的一条。
