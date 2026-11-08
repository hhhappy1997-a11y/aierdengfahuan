# DONE-R9 · Rank-4（美术管线与工具链）完成标志

> 轮次：**R9（占位画面运行期自检与汇总材料）**｜派单：`cmd-20261109-033148-270-A4`（`command_center\ai\4\inbox\` / `调度任务单-latest.json`）｜主任务书：`Rank-4\任务书-R9.md`
> 授权：`MSG-20261109-0331-HOST` 续派（`270-A4` R9 三路汇总材料）、`MSG-20261109-0223-HOST` 工程根落位裁决、`MSG-20261109-0309-HOST` 续派
> 必读（开工只读一次）：`任务书-R9.md`、`scene_integration.md`、`import.json`、`palette_256.json`、`DONE-R8.md`、`00-协作契约.md`、`00-群聊总线.md`；另按任务书定向只读核对 `00-项目总纲.md` §4、`00-工具链接入说明.md` §7、`Rank-1\GATE-FINAL.md`（该文件不在 `teamwork\` 根、在 Rank-1 工位，只读核对、不冒充本工位产出）
> **HOST 监测只认本文件。** 可写范围：`Rank-4\` + `godot\assets\generated\` + `godot\scripts\render\hd2d_placeholder*.gd`；唯一例外 `teamwork\command_center\ai\4\outbox\` 回执。**不写 `godot\project.godot`（Rank-1 独占）、不写 `godot\scenes\`、不写其它工位 / 总线 / 总纲 / 契约 / 任务书、不自行 git commit/push**
> 本轮定位：**汇总材料与运行期自检轮** —— 真跑引擎三段门禁 + 运行期场景实例化尝试 + 全 JSON 内联真跑解析 + 出图 job 只读验收 + 两份汇总材料；**本轮未新建 / 未改动任何既有 `.gd` / `.png` / 规格 JSON / `project.godot` / `scenes`**，既有件一律引用、不重做、一个字节未改
> 出图本轮 `142.2` 分钟无新增（R8 为 `115.9`，持续阻塞）→ 长期阻塞延续；headless 为 Dummy 接口、无真实帧缓冲 → **如实登记「运行期可见性未验收」**；ComfyUI 路径未登记 → 记阻塞；不宣称已能出图、不伪造输出 / 画面 / 截图、不拉第二个 GPU job

---

## ① 实际交付清单

### 1.1 本轮实际新建 / 改动文件（4 个，均为新建；既有件零改动）

| # | 文件（绝对路径） | 动作 | 内容 |
|---|---|---|---|
| 1 | `F:\Game\aierdengfahuan\teamwork\Rank-4\ART-SPEC-FINAL.md` | **新建** | 128px 基准画布 / ≤256 色索引调色板 / 装饰 RGBA 逐像素对齐规范终稿（三层尺寸关系、32 色板 8 语义组 / luma、九条对齐判据、四项导入设置、真跑结论、待裁决项），为 `00-汇总.md` 准备 |
| 2 | `F:\Game\aierdengfahuan\teamwork\Rank-4\I5-DELIVERY-CHECKLIST.md` | **新建** | I-5 资产交付清单（`assets/generated/` 6 品类 + 2 辅助目录、`import.json` 全 31 键、Godot 导入四项设置、1 号验收动作与退回条件）+ 出图长期阻塞结论（程序化 `_draw()` 零依赖兜底、ComfyUI 仍主路线） |
| 3 | `F:\Game\aierdengfahuan\teamwork\Rank-4\DONE-R9.md` | **新建** | 本文件（完成标志，①交付清单 / ②自检含解析与真跑实际输出 / ③未完成项与阻塞，+④完成判定 +⑤合规声明） |
| 4 | `F:\Game\aierdengfahuan\teamwork\command_center\ai\4\outbox\receipt_R9_A4.json` | **新建（回执）** | 中枢回执 `dict(4)`；`task_id=cmd-20261109-033148-270-A4` / `ai=4` / `status=done` / `result` 引用本文件实际结论 |

> **本轮既有件零改动**：`godot\scripts\render\hd2d_placeholder.gd`（R6 冻结，14670 字节）、`hd2d_placeholder_attach.gd`（R7 冻结，3776 字节）、`attach_hd2d_placeholder.gd`（Rank-1 R9 追加，4895 字节）、`godot\assets\generated\` 下 4 份 JSON、`Rank-4\` 既有 10 份独立 JSON 与全部 `.md` 规范 / DONE 文档、`godot\project.godot`、`godot\scenes\courtyard.tscn`（22 节点）、`godot\scenes\Main.tscn`、`godot\scripts\build_courtyard.gd` —— 一律只读引用、不覆盖、不重做、一个字节未改。
> **引擎副作用如实登记**：`--headless --import` / `--quit` 会读取 / 更新 `godot\.godot\` 缓存（`global_script_class_cache.cfg`、`.uid` 等），这是引擎运行副作用、非本工位手工写入的交付件（R6 §1.2 / `DONE-R7.md` §1.1 / `DONE-R8.md` §1.1 一贯口径）。**未运行** `attach_hd2d_placeholder.gd`（其 `ResourceSaver.save` 会写回 `courtyard.tscn`，属 Rank-1 独占；本轮真跑核对 `ResourceSaver.save` 命中 = True，故只做静态审阅、不执行）。

### 1.2 对照本轮四项要求（逐项处理）

| # | 本轮要求 | 本轮处理 | 实际结论 |
|---|---|---|---|
| 1 | 对已接入 `courtyard.tscn` 的 HD-2D 占位画面做**运行期可见性自检**：只有在能真实启动渲染实例时才做并贴实际输出；若 headless 无法验证，就如实登记「运行期可见性未验收」，**不伪造画面或截图** | **已完成（如实降级）** | 真跑引擎三段门禁（G1 `--import` / G2~G3 两占位脚本 `--check-only` / G4 `--quit`）+ **G5 直接运行 `courtyard.tscn`**（真实实例化 22 节点含占位层）全部 `EXIT=0 / SCRIPT ERROR=0 / Parse Error=0 / ERROR:=0`，仅 1 条 `2 ObjectDB instances were leaked` WARNING（与 `Rank-1\GATE-FINAL.md` §2 载明的唯一 WARNING 一致、非 ERROR）；G6 `--verbose` 实际输出 `TextServer: Added interface "Dummy"`、无真实 display / rendering driver 加载行，G7 工程根 PNG=0 / 无截图产物 → **headless 无真实帧缓冲输出，「运行期可见性未验收」**（§2.5）。不伪造画面 / 截图、不写 `scenes\` / `project.godot`、不运行 Rank-1 写回脚本、不冒充已渲染可见 |
| 2 | 把 128px 基准画布 / ≤256 色索引调色板 / 装饰 RGBA 逐像素对齐规范整理成 `ART-SPEC-FINAL.md`（为 `00-汇总.md` 准备） | **已完成** | §1 三层尺寸关系 / §2 32 色板（8 语义组 + luma L0~L8 + 取色收敛规则）/ §3 九条逐像素对齐判据 + 叠加顺序 + 退回条件 / §4 四项导入设置 / §5 真跑结论 / §6 待裁决 / §7 合规，齐全；规格字段口径 **24/24** 真跑通过，引用冻结件、不增口径、不改冻结值（§2.4） |
| 3 | 准备 `I5-DELIVERY-CHECKLIST.md`：I-5 资产交付清单（`assets/generated/` 品类、`import.json` 全字段、Godot 导入四项设置）+ 出图长期阻塞结论（程序化 `_draw()` 为零依赖兜底、ComfyUI 仍主路线） | **已完成** | 6 固定品类 + 2 辅助目录 / `import.json` 全 **31 键**逐字段表 / 四项导入设置（+ 3 辅助项、责任归属）/ 1 号 6 步验收动作 + 5 条退回条件 / 出图 142.2 分钟长期阻塞终态 + 「程序化 `_draw()` 正式零依赖兜底、ComfyUI 仍主美术路线」明确结论 / 当前实际交付状态（0 PNG、0 品类子目录，如实） |
| 4 | 继续**只读**验收单一出图 job（`Rank-4\*.png`、两份日志）；**绝不启动第二个 GPU job、不杀 / 不重启**；ComfyUI 路径未登记如实记阻塞、不臆造；所有 JSON 内联真跑解析 | **已完成** | PNG=0、stdout=0 字节、stderr=25320 字节停在 `checkpoint shards 50%(1/2)`、报错 / 完成关键字命中行数均 0、`01:21:30 → 03:43:40` **142.2 分钟无新增**；未启动第二个 GPU job、未杀 / 未重启 / 未并行（本轮所有 Godot 调用均为 `--headless` 静态门禁 / 场景实例化，非 GPU 出图 job）；`00-工具链接入说明.md` §7 仍「待用户提供 / 待刺探指令」→ 记阻塞；落位 **4/4** + 独立 **10/10** + 内嵌 **16/16** + 口径 **24/24** 全部内联真跑通过（§2.2 / §2.3 / §2.4） |

**结论**：四项要求逐项处理齐备。依赖外部源图或跨工位（真实渲染帧 / 真实纹理导入实测 / 首批 PNG 资产）的动作按「如实记阻塞 / 只登记不擅改」降级；不依赖外部的四项（引擎门禁与运行期实例化、全 JSON 真跑解析、出图只读验收、两份汇总材料）已真实执行并把实际输出写进 §2。

### 1.3 回执落位说明

回执按任务单 id 写入 `teamwork\command_center\ai\4\outbox\receipt_R9_A4.json`。按 `AierdengfahuanCommander.exe` 机制（同 `DONE-R3.md` §1.4 ~ `DONE-R8.md` §1.4），写入后中枢可能实时消费并归档到 `teamwork\command_center\dispatcher\receipts\receipt_R9_A4.json`、outbox 随之清空。写完文档与回执后由内联 python 真跑解析、以**实际落位**（outbox 或 receipts）为准，实际输出并入 §2；本轮不轮询、不伪造「已被接收」之外的状态、不重复写第二份回执。

---

## ② 自检结果（解析 / 真跑的实际输出结论）

### 2.1 真跑方式

- **内联 `python`**（`python - <<'PY'`，不落任何脚本文件）：`json.load` 解析工程根落位件 / `Rank-4\*.json` 全部独立文件 / 中枢回执，`json.loads` 解析 `Rank-4\*.md` 全部行首 `json` 围栏代码块；口径与实际生效用只读正则 / 只读文件核对。依据 `DONE-R2.md` §2.1 ~ `DONE-R8.md` §2.1 一贯口径（**交付自检，不是探针 / 测量 / preflight 脚本**）。Python `3.13.14`。
- **引擎真跑**：`D:\Godot\Godot_v4.7.2-stable_win64.exe --headless --path "F:/Game/aierdengfahuan/godot" ...`，捕获 stdout/stderr，统计 `EXIT` 并 grep `SCRIPT ERROR` / `Parse Error` / `ERROR:`。纯静态语法门禁 / 运行期场景实例化，**不是 GPU 出图 job**。
- **出图 / PNG 只读验收**：任务明确要求的只读动作（`Rank-4\*.png` + 两份日志的 stat / tail / 关键字计数），实际输出见 §2.3。**未启动任何出图进程 / 第二个 GPU job**。
- 本 `DONE-R9.md` 与 `ART-SPEC-FINAL.md` / `I5-DELIVERY-CHECKLIST.md` 内所有代码块用 `text` / `gdscript` 标记、不含行首 ```json 围栏，故写完统计仍为 **16/16**（口径自洽，与 `DONE-R6` ~ `DONE-R8` 做法一致）。
- **首次内联脚本失败如实登记、不隐瞒**：首次 [D] 分组因 `palette_256.json::luma_l0_l8` 含字符串说明键 `note`，遍历时触发 `TypeError: string indices must be integers, not 'str'`（第 77 行）；首次输出 [A]4/4 / [B]10/10 / [C]16/16 / [D] 前 24 项均 OK，[E]~[H] 未执行。修正为仅遍历 `L0~L8` 后**完整重跑**，下方 [A]~[H] 为修正后重跑的实际输出；不沿用旧结论、不隐瞒首次崩溃。

### 2.2 引擎三段门禁 + 运行期场景实例化 + headless 驱动证据（实际 stdout）

```text
=== 引擎版本（真跑）===
4.7.2.stable.official.ed1daf0bf
=== python ===
Python 3.13.14

----- [G1_三段门禁之 --headless --import] EXIT=0 -----
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[   0% ] first_scan_filesystem | 正在扫描文件结构……
[  16% ] first_scan_filesystem | 正在加载全局类名……
[  33% ] first_scan_filesystem | 正在校验 GDExtension……
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[  66% ] first_scan_filesystem | 正在初始化插件……
[  83% ] first_scan_filesystem | 正在启动文件扫描……
[ DONE ] first_scan_filesystem

[   0% ] loading_editor_layout | Started 正在加载编辑器 (5 steps)
[   0% ] loading_editor_layout | 正在加载编辑器布局……
[  16% ] loading_editor_layout | 正在加载停靠面板……
[ DONE ] loading_editor_layout

[统计] SCRIPT_ERROR=0 Parse_Error=0 ERROR:=0 WARNING=0 total_lines=16
----- [G2_check-only hd2d_placeholder.gd] EXIT=0 -----
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
[统计] SCRIPT_ERROR=0 Parse_Error=0 ERROR:=0 WARNING=0 total_lines=1
----- [G3_check-only hd2d_placeholder_attach.gd] EXIT=0 -----
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
[统计] SCRIPT_ERROR=0 Parse_Error=0 ERROR:=0 WARNING=0 total_lines=1
----- [G4_三段门禁之 --headless --quit (Main.tscn)] EXIT=0 -----
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
[统计] SCRIPT_ERROR=0 Parse_Error=0 ERROR:=0 WARNING=1 total_lines=4
----- [G5_运行期实例化 courtyard.tscn] EXIT=0 -----
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
[统计] SCRIPT_ERROR=0 Parse_Error=0 ERROR:=0 WARNING=1 total_lines=4

=== [G6] headless 渲染/显示驱动证据（--verbose 只读摘录）===
TextServer: Added interface "Dummy"
Using "default" pen tablet driver...
=== [G6b] --headless --quit --verbose 全量摘录 ===
TextServer: Added interface "Dummy"
TextServer: Added interface "ICU / HarfBuzz / Graphite (Built-in)"
Using "default" pen tablet driver...
TextServer: Primary interface set to: "ICU / HarfBuzz / Graphite (Built-in)".
Loading resource: res://scripts/render/hybrid_2d3d_animated_sprite.gd remapped: res://scripts/render/hybrid_2d3d_animated_sprite.gd
Completed load for: 'res://scripts/render/hybrid_2d3d_animated_sprite.gd' remapped 'res://scripts/render/hybrid_2d3d_animated_sprite.gd' at thread -1
Loading resource: res://data/render/quality_preset_desktop.tres remapped: res://data/render/quality_preset_desktop.tres
Completed load for: 'res://data/render/quality_preset_desktop.tres' remapped 'res://data/render/quality_preset_desktop.tres' at thread -1
Loading resource: res://data/render/quality_preset_mobile.tres remapped: res://data/render/quality_preset_mobile.tres
Completed load for: 'res://data/render/quality_preset_mobile.tres' remapped 'res://data/render/quality_preset_mobile.tres' at thread -1
=== [G7] 是否存在真实渲染产物/截图文件（只读）===
工程根 *.png 计数 = 0
Rank-4 *.png 计数 = 0
screenshots 目录 = ls: cannot access '/f/Game/aierdengfahuan/screenshots/': No such file or directory
```

> 判读：G1~G5 **全部 `EXIT=0`**，`SCRIPT ERROR` 合计 **0**、`Parse Error` **0**、`ERROR:` **0**；G4 / G5 唯一的 1 条 `WARNING` 为 `2 ObjectDB instances were leaked at exit`，与 `Rank-1\GATE-FINAL.md` §2 载明的「唯一 WARNING、非 ERROR」一致，不影响门禁。G2 / G3 输出仅版本横幅，两个占位脚本均为 R6 / R7 已冻结件、本轮一个字节未改、无需修 Variant 推断。
> **如实登记（不冒充全工程门禁全绿）**：本轮按任务约束只跑可写范围内**两个**占位脚本的 `--check-only --script` 静态语法门禁 + 三段门禁结构中的 `--import` / `--quit`；**未跑全量 51 个 `.gd` 的 `--check-only`**（那是 Rank-1 独占的跨工位全工程门禁，`Rank-1\GATE-FINAL.md` §2 已载明 `51/51 EXIT=0`、`ERROR=0`，本轮只做只读引用、不代跑、不冒充）。导出 exe / apk 属 Rank-1 R10（`cmd-20261109-033148-246-A1`），不在本工位范围，本轮未执行导出命令、不伪造产物。

### 2.3 出图 job / ComfyUI 只读验收（实际 stdout）

```text
=== NOW === 2026-11-09 03:36:37 +0800
=== Rank-4 PNG ===
ls: cannot access '/f/Game/aierdengfahuan/teamwork/Rank-4/*.png': No such file or directory
PNG_COUNT=0
=== 两份日志 stat ===
asset_proof_stdout.txt | 0 bytes | mtime=2026-11-09 01:05:48 +0800
asset_proof_stderr.log | 25320 bytes | mtime=2026-11-09 01:21:30 +0800
=== stderr tail 600 ===
(nf4) from Qwen/Qwen-Image-2.1 ...
D:\godogen_assets\image\.venv\Lib\site-packages\huggingface_hub\utils\_validators.py:206: UserWarning: The `local_dir_use_symlinks` argument is deprecated and ignored in `hf_hub_download`. Downloading to a local directory does not use symlinks anymore.
  warnings.warn(
Fetching 2 files:   0%|          | 0/2 [00:00<?, ?it/s]Fetching 2 files: 100%|██████████| 2/2 [00:00<00:00, 999.83it/s]
Loading checkpoint shards:   0%|          | 0/2 [00:00<?, ?it/s]Loading checkpoint shards:  50%|█████     | 1/2 [05:35<05:35, 335.95s/it]
=== 关键字计数(只读) ===
ERROR类=0
完成类=0
```

```text
=== [F] 出图 job 两份日志内联 python 只读分析 ===
  stdout bytes = 0  stderr bytes = 25320
  报错类关键字命中行数 = 0
  完成类关键字命中行数 = 0
  Rank-4 目录 PNG 计数 = 0
  stderr 末行 = Loading checkpoint shards:  50%|█████     | 1/2 [05:35<05:35, 335.95s/it]
  stderr mtime = 2026-11-09 01:21:30
  检查时刻 NOW = 2026-11-09 03:43:40
  无新增时长(分钟) = 142.2
=== [G] ComfyUI 路径登记只读核对 (00-工具链接入说明.md §7) ===
  §7 含「ComfyUI 本机路径与工作流 JSON」待登记项 : True
  状态仍为「待用户提供 / 待刺探指令」: True
  「ComfyUI 仍是主美术路线」口径在册 : True
=== [H] 派单 id 与回执只读核对 ===
  派单 id = cmd-20261109-033148-270-A4
  ai = 4  含 [ROUND=R9] : True
```

> **判读（如实）**：
> - 出图：权重 `750/750` 已加载完、`checkpoint shards 50%(1/2)` **仍无 PNG**；日志 mtime `01:21:30`、复核时刻 `03:43:40`，**142.2 分钟无新增**（R8 为 115.9 分钟，持续恶化）；报错类 / 完成类关键字命中行数均 **0**；stdout 0 字节 → `--json` 结果对象（timing / peak VRAM / 输出路径）未产生。**单一长时后台 job 停在 transformer checkpoint shard 1/2 加载，未进入去噪 / 写图；不是崩溃而是极慢加载 → 长期阻塞延续**（`DONE-R8.md` §1.3 终态判定，本轮进一步确认）。不宣称已能出图、不伪造 PNG / 结果 JSON / 校验数据；**未启动第二个 GPU job**，单一 job 未杀 / 未重启 / 未并行。
> - 明确结论（本轮写入 `I5-DELIVERY-CHECKLIST.md` §6.2）：正式确立 `hd2d_placeholder.gd` 的程序化 `_draw()` 占位为工程内唯一可真实运行、**零外部依赖的正式兜底画面方案**（兜底路线正式化，不是主路线变更）；**ComfyUI 仍是主美术路线**，`qwen-image` 仅本地零付费备选、本轮判长期阻塞；不宣称占位为正式素材、不等于「已能出图 / 场景已渲染可见 / 真实纹理导入已生效」。
> - ComfyUI：`00-工具链接入说明.md` §7 仍「待用户提供 / 待刺探指令」→ **登记阻塞**，不臆造地址、不尝试连接 `GET /object_info`、不主动扫盘、不绕过。

### 2.4 全部 JSON 内联真跑解析 + 规格口径 24/24 + 工程实际生效核对（实际 stdout）

```text
=== [A] 工程根落位件 JSON 真跑解析 (godot/assets/generated) ===
  OK  delivery_manifest.json       dict(20)
  OK  import.json                  dict(31)
  OK  palette_256.json             dict(12)
  OK  pose_names.json              dict(14)
  -> 落位 JSON: 4/4
=== [B] 源 Rank-4 全部独立 JSON 真跑解析 ===
  OK  delivery_manifest.json               dict(20)
  OK  hd2d_placeholder_params.json         dict(18)
  OK  hd2d_placeholder_r5_params.json      dict(23)
  OK  import.json                          dict(31)
  OK  palette_256.json                     dict(12)
  OK  player_idle_v1.import.json           dict(31)
  OK  pose_names.json                      dict(14)
  OK  prompt_skeleton.json                 dict(20)
  OK  调度任务单-R2.json                        dict(9)
  OK  调度任务单-latest.json                    dict(9)
  -> 独立 JSON: 10/10
=== [C] Rank-4 文档内嵌 json 围栏块真跑解析（仅行首 ```json）===
  OK  ASSET-PROOF.md             block#1  dict(20)
  OK  HD-2D视觉规范.md               block#2  dict(12)
  OK  R4-验收记录.md                 block#3  dict(8)
  OK  hd2d_placeholder.md        block#4  dict(2)
  OK  hd2d_placeholder.md        block#5  dict(10)
  OK  hd2d_placeholder.md        block#6  dict(3)
  OK  工具链配置.md                   block#7  dict(1)
  OK  工具链配置.md                   block#8  dict(1)
  OK  美术管线.md                    block#9  dict(23)
  OK  美术管线.md                    block#10 dict(15)
  OK  美术管线.md                    block#11 dict(2)
  OK  美术管线.md                    block#12 dict(5)
  OK  资产交付契约.md                  block#13 dict(24)
  OK  资产交付契约.md                  block#14 dict(24)
  OK  资产交付契约.md                  block#15 dict(15)
  OK  资产交付契约.md                  block#16 dict(8)
  -> 内嵌 JSON 块: 16/16 解析通过
=== [D] 128px 基准 / <=256 色索引板 / 四项导入 / 装饰对齐 字段口径真跑核对 ===
  OK  compress_mode = lossless                             = lossless
  OK  mipmaps = false (关 mipmaps)                          = False
  OK  texture_filter = Nearest                             = Nearest
  OK  project_default_texture_filter = 0                   = 0
  OK  import.canvas_base_px = 128                          = 128
  OK  palette.spec.canvas_base_px = 128                    = 128
  OK  palette.indexed = true                               = True
  OK  palette.max_colors = 256                             = 256
  OK  palette.color_count = 32 (<=256)                     = 32
  OK  colors 长度 == color_count == 32                       = 32
  OK  colors 全为 #RRGGBB 且去重 32                             = 32
  OK  palette_id 与 import 引用一致                             = hd2d_index_256_v1
  OK  源 palette_256 == 落位 palette_256 (逐键)                 = True
  OK  import.pose_names 全在冻结表                              = 4/22
  OK  player_idle 样例四项期望与 import 一致                        = True
  OK  frame_width/height = 32/32 (交付帧)                     = (32, 32)
  OK  anchor = {x:16,y:31} 底部中心共用                          = (16, 31)
  OK  downsample = Point/16/None/[32,32]                   = {'filter': 'Point', 'colors': 16, 'dither': 'None', 'target_size': [32, 32]}
  OK  frame_count <= columns*rows 且 end_frame 在界内          = 32<=32
  OK  palette(实际取用) 属于 palette_256.colors                  = 12/32
  OK  sample_only=true (字段样例,非真实交付)                        = True
  OK  fallback_route = procedural_draw_placeholder         = procedural_draw_placeholder
  OK  semantic_groups 覆盖索引 0~31 完整                         = 32
  OK  luma L0~L8 hex 与 index 落在 colors                     = 9
  -> 口径核对: 24/24 通过
=== [E] 工程根实际生效 / 场景接入 / 运行期自检支撑 只读核对 ===
  project.godot default_texture_filter = 0 : True
  project.godot integer_upscale_factor = 2 : True
  project.godot main_scene = Main.tscn : True
  courtyard.tscn node 行数 = 22
  ext_resource 指向 hd2d_placeholder.gd : True
  HD2DPlaceholderLayer CanvasLayer layer=-10 : True
  HD2DPlaceholder Nearest/scale=2/script : True
  占位脚本零外部依赖(无 load/preload res://) : True
  占位脚本无写回(无 ResourceSaver/FileAccess) : True
  Rank-1 attach 脚本含 ResourceSaver.save(故不运行) : True
  工程根 generated 下真实 PNG : 0
  工程根 generated 下真实 .import 元数据 : 0
  generated 下品类子目录数 : 0
  两份 import.json 均 sample_only=true : True
=== [F] 出图 job 两份日志内联 python 只读分析 === （同上 §2.3，不重复）
=== [G] ComfyUI 路径登记只读核对 === （同上 §2.3，不重复）
=== [H] 派单 id 与回执只读核对 === （同上 §2.3，不重复）
```

> **判读（分层、不夸大）**：
> - **实际生效 PASS**：项目级 `project.godot:141` 的 `textures/canvas_textures/default_texture_filter=0` 与 `import.json` 期望值一致（只读核对 `True`）、`render/integer_upscale_factor=2`（128px 基准画布 ×2 对齐 1280×720）；`hd2d_placeholder_attach.gd:44` 的 `TEXTURE_FILTER_NEAREST` 为真实代码落地；源 `Rank-4\palette_256.json` 与工程根落位件**逐键一致**；128px / `indexed=true` / `max_colors=256` / `color_count=32` / 32 色 `#RRGGBB` 去重 / 语义组覆盖 0~31 / luma L0~L8 一致 / 32×32 帧 / anchor / downsample / pose 子集 / palette 子集 —— 规格在落位件内真实生效，**24/24** 口径真跑通过（本轮在 R8 的 15/15 上增补 9 项：帧尺寸、anchor、downsample、frame_count、palette 子集、sample_only、fallback_route、语义组、luma，均为真跑新增、非沿用旧结论）。
> - **无法实测、如实登记**：`lossless` / 关 `mipmaps` / `Nearest` 对**真实纹理**的运行时导入生效 —— 工程根真实 PNG = 0、真实 `.import` 元数据 = 0、品类子目录 = 0，两份 `import.json` 均 `sample_only=true` 字段样例，其 `expected_import_settings` 是**期望值**而非运行时实测值。本轮不夸大「已在真实纹理上生效」，该实测随首批合规 PNG 落地后由 1 号导入时完成。
> - 口径如实说明：任务书字面 `default_texture_filter=0`，Godot 4 合法键为 `textures/canvas_textures/default_texture_filter`（`project.godot` 头注释 / R6 §2.2 已纠正，历史误写 `canvas_items` 不写回）；`import.json::palette_ref` 的 `_palette/` 子路径与实际平级落位差异沿用 R6 / R7 / R8 登记为「1 号导入时对齐」，本轮不擅改冻结字段。
> - 落位 **4/4** + 独立 **10/10** + 内嵌 **16/16** + 口径 **24/24** 全部真跑通过；新增 3 份 `.md` 均用 `text` 标记代码块、未新增行首 ```json 围栏，内嵌块仍为 16/16（写完复核见 §2.6）。

### 2.5 运行期可见性自检结论（如实，不伪造画面 / 截图）

**做了什么（真跑，贴实际输出见 §2.2）**：

1. 引擎三段门禁：`--headless --import`（G1）、`--check-only --script` 两个占位脚本（G2 / G3）、`--headless --quit` 主场景（G4），全部 `EXIT=0 / SCRIPT ERROR=0`。
2. **运行期场景实例化尝试**：直接以 `courtyard.tscn` 为运行场景 `godot --headless --path <root> res://scenes/courtyard.tscn --quit`（G5）—— 真实实例化 22 节点（含 `HD2DPlaceholderLayer(-10)` → `HD2DPlaceholder` 占位层），`EXIT=0 / SCRIPT ERROR=0`，占位脚本加载无运行时错误。
3. headless 渲染 / 显示驱动证据（G6 / G6b，`--verbose` 只读摘录）：`TextServer: Added interface "Dummy"`、`Primary interface set to: "ICU / HarfBuzz / Graphite (Built-in)"`、**无任何真实 display / rendering driver（Vulkan / OpenGL / D3D）加载行**。
4. 渲染产物只读核对（G7）：工程根 `*.png` = 0、`Rank-4\*.png` = 0、无截图产物。

**结论**：

- Godot `--headless` 使用 **Dummy 显示服务 / 无窗口 / 无 framebuffer / 无像素输出**。`可见性` 是需要真实渲染帧（像素）才能确认的属性；**headless 无法验证**。G5 的「场景实例化成功、脚本加载无运行时错误」只证明占位节点进入场景树且可运行，**不等于占位画面可见**。
- `HD2DPlaceholderLayer(layer=-10)` 相对 `SubViewportContainer` 不透明 3D 背景（`WorldEnvironment.background_color`）与 `FXLayer(layer=10)` 前景的**实际遮挡顺序 / 是否真正绘制出画面**，是 `scene_integration.md` §4 明确登记为 **Rank-1 裁决点**的跨工位事项；本轮只登记、不擅改、不代 1 号决定。
- 因此按本轮指令第二分支，**如实登记「运行期可见性未验收」**。**不伪造画面 / 截图、不宣称已渲染可见**；未启动带显示的渲染实例，`scenes\` / `project.godot` 归 Rank-1 独占，本轮不写、不覆盖、不运行 Rank-1 的 `attach_hd2d_placeholder.gd`（其 `ResourceSaver.save` 会写回 `courtyard.tscn`，真跑核对命中 = True）。占位画面实际是否可见由 Rank-1 在其构建 / 运行脚本真跑后确认。
- 附带只读结构自检（与 R8 §2.5 [复核5] 同口径，本轮 [E] 复核）：22 节点、`ext_resource` 指向 `hd2d_placeholder.gd`、`HD2DPlaceholderLayer(CanvasLayer, layer=-10)` → `HD2DPlaceholder(Node2D, texture_filter=1 / integer_scale=2 / script=ExtResource)`、既有 `FXLayer(layer=10)` 未被动 —— 逐项 `True`。**这是只读结构核对，不是渲染可见性验收，不冒充。**

### 2.6 写完文档与回执后的最小复核（实际 stdout）

写完 `ART-SPEC-FINAL.md` / `I5-DELIVERY-CHECKLIST.md` / `DONE-R9.md` 与回执后跑内联 python 复核，实际输出：

```text
=== [复核1] 落位件 4 件 json.load（写完文档后）===
  OK  delivery_manifest.json       dict(20)
  OK  import.json                  dict(31)
  OK  palette_256.json             dict(12)
  OK  pose_names.json              dict(14)
  -> 落位 JSON: 4/4
=== [复核2] Rank-4*.md 行首 json 围栏块（含 3 份新文档）===
  -> 内嵌 JSON 块: 16/16 解析通过（3 份新文档用 text 标记、未新增 json 围栏）
  ART-SPEC-FINAL.md            含行首 ```json 围栏 = False
  I5-DELIVERY-CHECKLIST.md     含行首 ```json 围栏 = False
  DONE-R9.md                   含行首 ```json 围栏 = False
=== [复核3] 回执 JSON 真跑解析（以实际落位为准）===
  实际落位 : F:/Game/aierdengfahuan/teamwork/command_center/dispatcher/receipts/receipt_R9_A4.json | exists = True
  dict(4)
  task_id = cmd-20261109-033148-270-A4
  ai      = 4
  status  = done
  result_len = 1244
  task_id_matches_dispatch = True
  result_引用_DONE-R9      = True
  exists receipt(outbox)   = False
  exists receipt(receipts) = True
=== [复核4] DONE-R9.md 三段齐全 + 交付件存在性 + 既有件未改只读快照 ===
  DONE-R9.md ①实际交付清单 = True
  DONE-R9.md ②自检结果     = True
  DONE-R9.md ③未完成项与阻塞 = True
  DONE-R9.md 不含行首 ```json 围栏 = True
  exists ART-SPEC-FINAL.md              = True
  exists I5-DELIVERY-CHECKLIST.md       = True
  exists DONE-R9.md                     = True
  既有件(未改) project.godot                  mtime=2026-11-09 02:57:32 bytes=6063
  既有件(未改) courtyard.tscn                 mtime=2026-11-09 03:17:51 bytes=5054
  既有件(未改) Main.tscn                      mtime=2026-11-09 02:28:35 bytes=3393
  既有件(未改) hd2d_placeholder.gd            mtime=2026-11-09 02:33:38 bytes=14670
  既有件(未改) hd2d_placeholder_attach.gd     mtime=2026-11-09 02:55:17 bytes=3776
  既有件(未改) attach_hd2d_placeholder.gd     mtime=2026-11-09 03:17:24 bytes=4895
  既有件(未改) build_courtyard.gd             mtime=2026-11-09 02:28:35 bytes=9214
  既有件(未改) palette_256.json(落位)           mtime=2026-11-09 02:29:23 bytes=3575
=== [复核5] 3 份新文档 UTF-8 可读 / 字节数 / 行数 ===
  ART-SPEC-FINAL.md            bytes=13313 lines=158 utf8=True
  I5-DELIVERY-CHECKLIST.md     bytes=20603 lines=230 utf8=True
  DONE-R9.md                   bytes=38129 lines=326 utf8=True
```

> **回执落位（正常、非失败）**：写入 outbox 后已被中枢实时消费归档到 `dispatcher\receipts\receipt_R9_A4.json`、outbox 随之清空（与 `DONE-R7.md` §1.4 / `DONE-R8.md` §2.5 机制一致），属正常、非失败；未重复写第二份回执、未改已归档回执。回执 `dict(4)` 合法、`task_id` 与派单 `调度任务单-latest.json` 一致、`ai=4` / `status=done` / `result_len=1244` 且引用本文件实际结论。
> **既有件未改印证**：[复核4] 的 mtime / bytes 与 `DONE-R8.md` §2.5 [复核4] 开工快照逐项一致（`project.godot 02:57:32 / 6063`、`courtyard.tscn 03:17:51 / 5054`、`hd2d_placeholder.gd 02:33:38 / 14670`、`hd2d_placeholder_attach.gd 02:55:17 / 3776`、`build_courtyard.gd 02:28:35 / 9214`、`palette_256.json 02:29:23 / 3575`），本轮从未对这些文件调用任何写操作，既有件一个字节未改。
> [复核2] 证明 3 份新文档均用 `text` 标记代码块、未新增行首 ```json 围栏，内嵌块口径仍为 **16/16**（与 §2.1 / §2.4 自洽）；3 份新文档 UTF-8 合法可读。

补入本 §2.6 后再次跑内联 python 最终复核（本小节自身不含行首 ```json 围栏），实际输出：

```text
=== [复核6] 补入 §2.6 后的最终复核（实际 stdout）===
  内嵌 JSON 块: 16/16 解析通过
  ART-SPEC-FINAL.md            含行首 ```json 围栏 = False
  I5-DELIVERY-CHECKLIST.md     含行首 ```json 围栏 = False
  DONE-R9.md                   含行首 ```json 围栏 = False
  回执 dict(4) status=done task_id_matches=True 引用DONE=True
  DONE-R9.md 三段齐全 = True
  DONE-R9.md 含 2.6 复核 = True
  DONE-R9.md 不含行首 ```json 围栏 = True
  DONE-R9.md bytes=41864 lines=379 utf8=True
```

> [复核6] 证明补入复核小节后口径自洽：内嵌块仍 **16/16**、3 份新文档均不含行首 ```json 围栏、回执 `dict(4)` 合法且 `status=done` / `task_id` 匹配 / 引用本文件、`DONE-R9.md` 三段齐全、UTF-8 合法。其中 `bytes=41864 / lines=379` 为**补入本 [复核6] 记录前**那次真跑的实际快照（本记录追加后文件字节数随之增大，不改写已贴出的实际输出、不冒充最终值）；补入后口径由下方最终确认复核，不再回写数字。

---

## ③ 未完成项与阻塞（如实，全部非谎报）

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| 1 | `qwen-image --quant nf4` 首次出图 | **长期阻塞（本轮延续）** | 单一后台 job 停在 `transformer checkpoint shards 50%(1/2)`，`01:21:30 → 03:43:40` **142.2 分钟无新增**（R8 为 115.9）；无 PNG / 无结果 JSON / 无报错。不宣称已能出图、不伪造输出；未杀 / 未重启 / 未并行、未拉第二个 GPU job，最终以 `asset_proof_stdout.txt` / `asset_proof_stderr.log` 为准。兜底结论见 `I5-DELIVERY-CHECKLIST.md` §6.2 |
| 2 | HD-2D 占位画面**运行期可见性**验收 | **未验收（本轮如实降级）** | 真跑三段门禁 + G5 运行期实例化 `EXIT=0 / SCRIPT ERROR=0`；headless Dummy 接口、无真实帧缓冲 / 截图 → 无法验证可见性；只读结构自检逐项 `True`（结构 ≠ 渲染）。不伪造画面 / 截图、不冒充已渲染可见；遮挡层序属 `scene_integration.md` §4 的 Rank-1 裁决点，只登记不擅改 |
| 3 | lossless / 关 mipmaps / Nearest 对**真实纹理**的运行时导入生效实测 | **无法实测（阻塞）** | 工程根真实 PNG=0、真实 `.import`=0、品类子目录=0；两份 `import.json` 均 `sample_only=true`。项目级 `default_texture_filter=0` 与 `attach.gd` Nearest 代码已实际生效（[E] 全 True），纹理级实测随首批合规 PNG 落地后由 1 号导入完成；不夸大「已在真实纹理上生效」 |
| 4 | alpha / 128px / ≤256 色收敛校验 | **无法执行（阻塞）** | 无源 PNG；收敛路线（ComfyUI / Aseprite / ImageMagick，不混用 `image/quantize.py` DiT 权重量化器）与判据见 `R4-验收记录.md` §2 / `ART-SPEC-FINAL.md` §2.2，沿用不改；不编造校验数据 |
| 5 | 装饰 RGBA 层与 base 逐像素对齐抽检 | **无法执行（阻塞）** | 无 base、无装饰层；九条判据与逐像素比对方法见 `ART-SPEC-FINAL.md` §3 / `R4-验收记录.md` §4，沿用不改；不臆造「已对齐 / 不一致像素数=0」 |
| 6 | ComfyUI 本机路径与工作流 JSON 登记 + `GET /object_info` 6 类节点核对 | **阻塞** | `00-工具链接入说明.md` §7 仍「待用户提供 / 待刺探指令」（本轮只读核对 True / True），本轮 HOST 未提供、目录无工作流 JSON；不臆造地址、不尝试连接、不绕过、不主动扫盘。**ComfyUI 仍是主美术路线** |
| 7 | `style_anchor.png` / 128px 精灵表 / OpenPose 骨架库 | **未产出** | 本机未跑出图，`Rank-4\*.png` 计数 0；不伪造 |
| 8 | 显存档位 A~D / 峰值显存实测 | **未实测** | stdout 无 `--json` 结果（0 字节），只有 R3 记录的加载阶段 14203 MiB（非最终峰值）；不编造耗时 / 峰值 |
| 9 | 主角 / Boss / 关键场景 Aseprite 人工精修 | 未开始 | 人工环节（M1 / M5），`human_refine=done` 才允许交付（契约 §6.3） |
| 10 | 挂载点 / 缩放 / 遮挡顺序 4 项取舍 | **登记 / 待 1 号裁决** | 既有 `_apply_integer_scale()` clamp 2~4 无法设 1（不覆盖冻结件）；`SubViewport` 内放大出界、不透明 3D 背景遮挡顺序由 1 号裁决，见 `scene_integration.md` §4；本轮只登记不擅改 |
| 11 | `import.json::palette_ref` 的 `_palette/` 子路径与实际落位平级差异 | **登记 / 待 1 号导入对齐** | 该件 `sample_only=true` 为字段样例；本轮按 R6 落在 `assets/generated/` 平级，不擅改冻结字段 |
| 12 | `128bit` 确切含义（128px 画布 vs 位宽 / 色深） | **待用户确认** | 落地按 128px 基准画布 + 256 色索引板理解，不自行改口径（契约 §9.3 / `ART-SPEC-FINAL.md` §6） |
| 13 | 付费 API / `stable-audio`(gated 403) / `gen3d` / `mia-rig` | **禁用 / 不碰** | 不申请、不补装、不碰 WSL、不绕过；不列「确认花费」为待办 |
| 14 | 群聊总线追加 `TYPE=交付完成` 消息 | **本轮不执行** | 本轮硬性约束「不写总线」，且总线不在唯一可写范围；以 HOST 最新指令为准 |
| 15 | 全量 51 个 `.gd` 门禁 / Windows exe + apk 导出 | **非本工位范围** | 全量门禁由 Rank-1 R9 完成（`Rank-1\GATE-FINAL.md` §2：`51/51 EXIT=0`、`ERROR=0`），导出属 Rank-1 R10（`cmd-20261109-033148-246-A1`）；本轮只跑可写范围两个占位脚本门禁、未执行任何导出命令，不冒充全量门禁全绿、不伪造产物 |

---

## ④ 完成标准判定

| 判据 | 结论 |
|---|---|
| 本轮 4 项要求逐项处理 | ✓ 运行期自检（如实降级）/ ART-SPEC-FINAL.md / I5-DELIVERY-CHECKLIST.md / 出图只读验收 + 全 JSON 真跑解析，4/4 处理齐备 |
| 运行期可见性自检「能真做才做，headless 无法验证则如实登记未验收」 | ✓ 真跑三段门禁 + G5 场景实例化 + G6 驱动证据 + G7 产物核对，全部贴实际输出；headless Dummy / 无帧缓冲 → **如实登记「运行期可见性未验收」**，不伪造画面 / 截图 |
| 只读验收单一出图 job、绝不启动第二个 GPU job、不杀 / 不重启 | ✓ 仅 stat / tail / 关键字计数与 `--headless` 静态门禁 / 场景实例化；单一 job 未动；142.2 分钟无新增 → 长期阻塞延续 |
| 128px / ≤256 色 / 装饰 RGBA 规范整理成 `ART-SPEC-FINAL.md` | ✓ 三层尺寸关系 / 32 色板 / 九条逐像素对齐判据 / 四项导入设置 / 待裁决项齐全，24/24 口径真跑通过 |
| `I5-DELIVERY-CHECKLIST.md`：品类 / 全字段 / 四项设置 + 阻塞结论 | ✓ 6 品类 + 2 辅助、`import.json` 全 31 键、四项导入设置、1 号验收与退回条件、出图长期阻塞与「程序化 `_draw()` 兜底 / ComfyUI 主路线」明确结论齐全 |
| ComfyUI 路径未登记如实记阻塞，不臆造 / 不连接 / 不绕过 | ✓ §7 只读核对仍「待用户提供 / 待刺探指令」→ 记阻塞 |
| 所有 JSON 合法可解析（落位 + 独立 + 内嵌 + 口径 + 回执） | ✓ 落位 **4/4** + 独立 **10/10** + 内嵌 **16/16** + 口径 **24/24** 真跑通过；首次 [D] `TypeError` 如实登记并修正重跑；回执写后经内联 python 解析（§2.6） |
| 真跑引擎三段门禁 + grep `SCRIPT ERROR` 并贴实际 stdout | ✓ G1 `--import` / G2~G3 `--check-only` / G4 `--quit` 全 `EXIT=0`、`SCRIPT ERROR=0` / `Parse Error=0` / `ERROR=0`；如实登记未跑全量 51 `.gd`、未代跑导出、不冒充全绿 |
| `DONE-R9.md` 三段齐全 + 回执 | ✓ ①交付清单 / ②自检含解析与真跑实际输出 / ③未完成项与阻塞（+④完成判定 +⑤合规声明）齐全；回执 `status=done` 引用本文件实际结论 |
| 既有件不重做 / 不越界 / 不写 `project.godot` / 不写 `scenes\` / 不自行 git | ✓ R2~R8 全部冻结件与工程根落位件一个字节未改；只写 `Rank-4\` 3 份 `.md` 与回执例外 |

**本轮 R9 达成**：按「占位画面运行期自检与汇总材料」定位，把引擎三段门禁 / 运行期场景实例化的**真实输出**、headless 无法验证可见性的**如实降级结论**、全 JSON 内联真跑解析（4/4 + 10/10 + 16/16 + 24/24）、出图 142.2 分钟长期阻塞的只读验收、以及 `ART-SPEC-FINAL.md` / `I5-DELIVERY-CHECKLIST.md` 两份为 `00-汇总.md` 准备的汇总材料真实落盘；出图 / ComfyUI / 收敛 / 对齐 / 渲染可见性 / 真实纹理导入实测等依赖外部源图或跨工位的项如实记阻塞、不硬造、不重复拉 GPU job。未完成项均属任务书允许的「尽力而为 / 如实降级 / 只登记不擅改」范围，不影响 R9 完成判定（与 `DONE-R2.md` §4 ~ `DONE-R8.md` §4 同一判据）。

---

## ⑤ 合规声明

- 只写 `Rank-4\ART-SPEC-FINAL.md` / `I5-DELIVERY-CHECKLIST.md` / `DONE-R9.md`（3 份新建）+ 唯一例外 `teamwork\command_center\ai\4\outbox\receipt_R9_A4.json` 回执；**未写 `godot\project.godot`、未写 `godot\scenes\`**、未写 `godot\assets\generated\` / `godot\scripts\render\` 任何既有件、未写其它工位 / 工程根其它子目录 / 群聊总线 / 总纲 / 契约 / 任务书；未自行 `git commit` / `git push`。
- **既有件零改动**：`hd2d_placeholder.gd`、`hd2d_placeholder_attach.gd`、`attach_hd2d_placeholder.gd`（Rank-1）、4 份落位 JSON、R2~R8 全部冻结 JSON / DONE / 规范文档、`courtyard.tscn`、`Main.tscn`、`build_courtyard.gd`、`project.godot` 一律**引用、不重做、一个字节未改**；`Rank-1\GATE-FINAL.md` 仅定向只读核对、未改、未冒充本工位产出。
- 零付费 / 零外部依赖：付费 API 一律禁用，不列云服务、不列花费确认项；本轮无任何网络出图调用、无第二个 GPU job；程序化占位与挂载辅助只用 Godot 4 内置原语与工程内既有 `.gd`。
- **ComfyUI 仍是主美术路线**；`qwen-image` 仅为同为零付费的本地备选、本轮判长期阻塞；程序化 `_draw()` 占位为**正式零依赖兜底**（`DONE-R8.md` §1.3 / 本轮 `I5-DELIVERY-CHECKLIST.md` §6.2），是兜底路线正式化，不取代 ComfyUI 主路线、不宣称占位为正式素材。
- `image/quantize.py` 是 **DiT 权重量化器**，**未**用作 256 色调色板量化器；调色板收敛走 ComfyUI / Aseprite / ImageMagick。
- `stable-audio`（gated 403）/ `gen3d` / `mia-rig` 不可用：不申请、不补装、不碰 WSL、不绕过。
- 默认不刺探：仅执行任务明确要求的 `Rank-4\*.png` 与两份日志只读检查、`palette_256.json` / `import.json` / `project.godot` / `scene_integration.md` 接入痕迹 / 工具链 §7 / `Rank-1\GATE-FINAL.md` 的定向只读核对、引擎 `--headless` 门禁与场景实例化（引擎副作用 `.godot/` 如实登记），未扫别人工位、未轮询、未写探针 / 测量 / preflight 脚本；`00-群聊总线.md` 开工只读一次。
- 中文 UTF-8；所有独立 JSON 与文档内嵌 `json` 围栏块合法可解析（4/4 落位 + 10/10 独立 + 16/16 内嵌），回执合法；GDScript 为 Godot 4 合法语法（`--check-only` 通过）。
- **不宣称已能出图、不伪造输出 / 画面 / 截图、不拉起第二个 GPU job、不臆造 ComfyUI 路径、不冒充全工程门禁全绿、不宣称场景已渲染可见、不夸大纹理级导入已生效、不运行 Rank-1 写回脚本**：这是本轮最重要的一条。
