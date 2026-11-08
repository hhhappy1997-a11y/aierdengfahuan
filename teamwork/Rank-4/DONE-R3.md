# DONE-R3 · Rank-4（美术管线与工具链）完成标志

> 轮次：**R3**（HOST 全闭环调度自动启动）｜派单：`cmd-20261109-005741-239-A4`（`调度任务单-latest.json` / `command_center\ai\4\inbox\`）
> 主任务书：`Rank-4\任务书-R3.md`｜必读：`DONE-R2.md`、`资产交付契约.md`、`美术管线.md`、`00-协作契约.md`、`00-群聊总线.md`（开工只读一次，读到末尾）、`00-工具链接入说明.md`
> 口径：`00-协作契约.md` §9.3 / §10（128px + ≤256 色、ComfyUI 主路线、零付费）、R2 冻结 §6 第 6 条 pose 名 / 第 7 条像素规格
> **HOST 监测只认本文件。** 唯一可写 `Rank-4\`；唯一例外 `command_center\ai\4\outbox\` 回执 JSON。
> 本轮定位：**按本次 HOST 指令补齐 R3 新增 / 缺失项 + `ASSET-PROOF.md` 实跑记录**；R2 已产出的一律不重做。

---

## ① 实际交付清单

### 1.1 本轮实际新建 / 改动文件（5 个，全部真实落盘）

| # | 文件（绝对路径） | 动作 | 内容 |
|---|---|---|---|
| 1 | `F:\Game\aierdengfahuan\teamwork\Rank-4\ASSET-PROOF.md` | **新建** | R3 实跑验证记录：环境、命令与 `--quant nf4` 参数链、截至成文时的真实观测、出图后校验阻塞、管线分工与调用规范、未完成项 |
| 2 | `F:\Game\aierdengfahuan\teamwork\Rank-4\DONE-R3.md` | **新建** | 本文件（完成标志） |
| 3 | `F:\Game\aierdengfahuan\teamwork\Rank-4\asset_proof_stdout.txt` | **新建** | qwen-image 真跑 stdout 重定向（当前 0 字节，`--json` 结果尚未产生，如实保留为证据） |
| 4 | `F:\Game\aierdengfahuan\teamwork\Rank-4\asset_proof_stderr.log` | **新建** | qwen-image 真跑 stderr 重定向（含 `[load] text_encoder (nf4)` 与权重加载进度，保留为证据） |
| 5 | `F:\Game\aierdengfahuan\teamwork\command_center\ai\4\outbox\receipt_R3_A4.json` | **新建** | 中枢回执（唯一例外写范围） |

### 1.2 对照 `任务书-R3.md` §2 交付清单（逐项处理，含「不重做」依据）

| # | 任务书 §2 要求 | R2 实际状态 | 本轮处理 |
|---|---|---|---|
| 1 | `import.json`（模板，全字段） | R2 已产出，31 键：`frame_width/height=32`、`columns/rows`、`anchor={x:16,y:31}`、`actions`、`pose_names`（`p1_`/`p2_` 冻结名）、`palette`、`canvas_base_px=128`、`palette_id=hd2d_index_256_v1`、`layer_type`、`aligned_with`、`seed`、`expected_import_settings{compress_mode=lossless, mipmaps=false, texture_filter=Nearest, project_default_texture_filter=0}`、`pipeline_tier` 等 | **不重做**（本次 HOST 指令）；字段覆盖见 §2.4 核对 |
| 2 | `delivery_manifest.json`（模板） | R2 已产出，20 键：`batch_id`、`fallback_route`、`palette_id`、`canvas_base_px`、`human_refine`、`items[]`、`item_count`、`m0_validation`、`expected_import_settings`、`notes` | **不重做**；字段名差异见 §3 第 6 项 |
| 3 | `prompt_skeleton.json`（更新） | R2 已产出，`frozen=true`；`single_slot` 只留 `[SUBJECT]` 一槽已满足；`DONE-R2.md` §2.7 登记 `seed_lock.action_offset` 与 R2 冻结 pose 不一致、须 HOST 裁决后整体升 v2 | **不重做 / 不热改**（冻结件 + 硬性约束「遵守 R2 口径 pose 冻结表」） |
| 4 | `美术管线.md`（增一节，不删原文） | R2 已产出 **§10.4**「qwen-image 本地备选的调用边界（不取代 ComfyUI）」，已含 ComfyUI 主路线 / qwen-image 备选分工 / `grid_slice.py`·`find_loop_frame.py`·`rembg_matting.py` 后处理位置 / 单 GPU job 规范 / `quantize.py` 易混澄清；§7 显存分级降级表 | **不改动原文**（本次 HOST「一律不重做」）；R3 需补记的文字（`loop_audio.py` 位置、三条经验、完整调用规范）由 **R3 新增文件 `ASSET-PROOF.md` §5** 承载，不碰冻结件 |
| 5 | `ASSET-PROOF.md` | R2 无 | **本轮新建 ✅** |
| 6 | `DONE-R3.md` | R2 无 | **本轮新建 ✅** |

**结论**：`任务书-R3.md` §2 六类中，4 类已由 R2 交付（按本次 HOST 指令不重做）、2 类为 R3 新增且本轮补齐 → 交付件齐备。

### 1.3 明确未改动的文件（R2 产出原样保留）

`import.json`、`delivery_manifest.json`、`palette_256.json`、`pose_names.json`、`hd2d_placeholder_params.json`、`player_idle_v1.import.json`、`prompt_skeleton.json`、`美术管线.md`、`资产交付契约.md`、`HD-2D视觉规范.md`、`README.md`、`工具链配置.md`、`接口契约.md`、`DONE-R2.md`、`任务书.md` / `任务书-R2.md` / `任务书-R3.md`、`调度任务单-R2.json` / `调度任务单-latest.json` —— **一个字节都未改**。

### 1.4 回执落位说明

回执按任务单 id 写入 `command_center\ai\4\outbox\receipt_R3_A4.json`。开工前实测该 outbox 为空（中枢 `AierdengfahuanCommander.exe` 消费后正常回收，见 `DONE-R2.md` §1.2 同一机制）；`command_center\ai\4\status.json` 实测 `state=working / current_task=cmd-20261109-005741-239-A4 / completed=3`。回执写入后由中枢自行消费，本轮不轮询、不伪造「已被接收」之外的状态。

---

## ② 自检结果（真跑 / 解析的实际输出结论）

### 2.1 真跑方式

- 用**内联 `python`**（`python - <<'PY'`，不落任何脚本文件）做交付自检：`json.load` 解析 `Rank-4\*.json` 全部独立文件、`json.loads` 解析 `Rank-4\*.md` 全部内嵌 JSON 代码块（以 json 语言标记）。依据 `任务书-R2.md` §4.4 / `DONE-R2.md` §2.1 口径（交付自检，**不是探针 / 测量 / preflight 脚本**）。
- 实际执行了解析器（非人工目视）；零付费、无外部调用、未扫别人工位、未写探针。
- 另外真跑了 **1 次 qwen-image 出图 GPU job**（见 §2.5），不是脚本自检。

### 2.2 独立 JSON 真跑解析（最终自检实际 stdout 结论）

```text
=== [1] 独立 JSON 文件真跑解析 ===
  OK   delivery_manifest.json                     dict(20)
  OK   hd2d_placeholder_params.json               dict(18)
  OK   import.json                                dict(31)
  OK   palette_256.json                           dict(12)
  OK   player_idle_v1.import.json                 dict(31)
  OK   pose_names.json                            dict(14)
  OK   prompt_skeleton.json                       dict(20)
  OK   调度任务单-R2.json                              dict(9)
  OK   调度任务单-latest.json                          dict(9)
  -> 独立 JSON: 9/9 解析通过
```

> 本次 HOST 点名的 `import.json` / `delivery_manifest.json` / `palette_256.json` / `pose_names.json` / `hd2d_placeholder_params.json` / `player_idle_v1.import.json` / `prompt_skeleton.json` 全部在内，**9/9 合法可解析**（比 R2 的 8/8 多出 `调度任务单-latest.json`，因本轮派单落地）。

### 2.3 文档内嵌 JSON 块真跑解析（最终自检实际 stdout 结论）

```text
=== [2] 文档内嵌 json 块真跑解析 ===
  OK   ASSET-PROOF.md               block#1 dict(20)
  OK   HD-2D视觉规范.md                 block#1 dict(12)
  OK   工具链配置.md                     block#1 dict(1)
  OK   工具链配置.md                     block#2 dict(1)
  OK   美术管线.md                      block#1 dict(23)
  OK   美术管线.md                      block#2 dict(15)
  OK   美术管线.md                      block#3 dict(2)
  OK   美术管线.md                      block#4 dict(5)
  OK   资产交付契约.md                    block#1 dict(24)
  OK   资产交付契约.md                    block#2 dict(24)
  OK   资产交付契约.md                    block#3 dict(15)
  OK   资产交付契约.md                    block#4 dict(8)
  -> 内嵌 JSON 块: 12/12 解析通过
```

> R2 为 11 块；本轮新增 `ASSET-PROOF.md` §2.1 的实跑参数 JSON 块 → **12 块，12/12 解析通过**。本 `DONE-R3.md` 内所有代码块用 `text` / `bat` 标记、不含以 json 语言标记的代码块，故写完后统计仍为 12/12（自检口径自洽，与 `DONE-R2.md` §2.3 做法一致）。

### 2.4 R2 冻结口径字段覆盖核对（不重做但已校验）

- `palette_256.json`：`spec.canvas_base_px=128` / `indexed=true` / `max_colors=256` / `color_count=32`，L0~L8 九级明度、8 语义分组齐备；`usage` 第 4 条已写明「`image/quantize.py` 是 DiT 权重量化器，不是 256 色调色板量化器」。
- `pose_names.json`：`frozen_name_count=22`，8 core + 3 boss、`p1_`/`p2_` 前缀；`r1_discrepancy` 已登记 `prompt_skeleton.json` 待整体升 v2（本轮沿用、不擅改）。
- `import.json`：`canvas_base_px=128`、`palette_id=hd2d_index_256_v1`、`pose_names=p1_idle/p1_dagger_slash/p2_idle/p2_holy_hammer`（全在冻结表内且带前缀）、四项 `expected_import_settings`（lossless / mipmaps:false / Nearest / `project_default_texture_filter=0`）齐备 → 与 R2 口径 §6 第 6/7 条一致。
- `美术管线.md` §10.4：ComfyUI 主路线 / qwen-image 备选 / 后处理脚本 / 单 GPU job / `quantize.py` 易混澄清均已存在 → 佐证本轮「不重做」合理。

### 2.5 qwen-image 出图真跑（本轮唯一未验证环节，如实记录）

**实际执行**（单 GPU job、后台、长 timeout、stdout 收 JSON / stderr 存文件）：

```bat
python D:\godogen_assets\bin\godogen_win.py --cmd qwen-image generate "pixel art game sprite, a lone tarnished knight in weathered golden armor, full body, front facing view, flat shading, hard pixel edges, 128px base canvas, 256 color indexed palette, transparent background, centered, feet on ground" --quant nf4 --resolution 512 --steps 10 -o F:\Game\aierdengfahuan\teamwork\Rank-4\asset_proof_qwen_nf4.png --json
```

**前置实测**（只读路径存在性确认，非巡检）：`env.cmd` / `godogen_win.py` / `image/cli.py` / `image/.venv/Scripts/python.exe` 均存在；HF 缓存 `models--Qwen--Qwen-Image-2.1` = **31G**（8 个 safetensors）；`nvidia-smi` = RTX 4060 Ti 16380 MiB；调度端 Python 3.13.14。`--quant nf4` 经 `cli.py::build_generate_argv` 转 `--dit-quant nf4`（bitsandbytes 4-bit），`--te-quant` 默认 nf4、`--offload=model`，无预量化目录故走加载时量化；`HF_ENDPOINT=https://hf-mirror.com` 由 `tool_env()` 注入，**未设 `HF_HUB_OFFLINE=1`**。

**真跑实际观测**（成文时，后台 job `xhKNq7` 已运行约 12 分钟、仍在运行）：

```text
stderr 首行:  [load] text_encoder (nf4) from Qwen/Qwen-Image-2.1 ...
平台告警:    UserWarning: expandable_segments not supported on this platform  (Windows 提示，非失败)
加载进度:    Loading weights: 49%|████▉ | 364/750 [07:19<...]   (text_encoder 750 分片逐片 4-bit 量化)
GPU 显存:    nvidia-smi = 14203 MiB, 0 %   (加载阶段实测，非最终峰值)
stdout:      asset_proof_stdout.txt = 0 字节  (--json 结果对象未产生)
PNG:         ls Rank-4\*.png = No files found  (asset_proof_qwen_nf4.png 未产出)
报错:        stderr 无 Traceback / Error / OOM
```

**结论（如实，不谎报）**：本机 `qwen-image` 全量 30.84 GiB 权重 > RTX 4060 Ti 显存，`--quant nf4` 首次冷加载需逐片量化 + CPU offload，耗时远超分钟级常规预期；本轮交付窗口内该 job **未跑完、未产 PNG、未打印结果 JSON**。按任务书 §3 与本次 HOST 指令「跑不通就如实写阻塞，**不得宣称已能出图、不得伪造输出**」：
- **不宣称已能出图**（本机至今只跑通过 `qwen-tts`、没跑出过图，本轮不改此事实）；
- **不伪造输出**（无 PNG、无假结果 JSON、无假耗时 / 假峰值显存 / 假看图结论）；
- 详见 `ASSET-PROOF.md` §0 / §3 / §4 / §6，后台 job 未杀、最终以 `asset_proof_stdout.txt` / `asset_proof_stderr.log` 为准。
- 出图后校验（alpha 在对比色上判定 / 降 128px 是否发糊 / 256 色收敛 / 装饰层一致性）因无源 PNG **无法执行，如实写阻塞**，不编造。
- ComfyUI 本机路径 / 工作流 JSON 未登记 → 6 类节点核对 **阻塞**，未臆造地址、未尝试连接、未绕过。

### 2.6 Godot 三段构建门禁（如实说明适用边界）

任务单正文含「真跑引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe` 三段门禁并 grep SCRIPT ERROR」字样；但本工位按 `README.md` §1 / `资产交付契约.md` §1 **不产出 `.gd` / `.tscn` / `.tres` / shader、不建 Godot 工程**，交付件为 JSON + Markdown，三段门禁在本工位**无可校验对象、本轮未跑**，不谎报跑过（与 `DONE-R2.md` §2.6 同一口径）。本轮「真跑」= §2.2~§2.4 的 JSON 解析自检 + §2.5 的 qwen-image 出图实跑。

---

## ③ 未完成项与阻塞（如实，全部非谎报）

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| 1 | `qwen-image --quant nf4` 首次出图实跑结论 | **未完成 / 阻塞（进行中）** | 已真跑启动、单 GPU job、权重加载中；本轮窗口内未产 PNG / 未出结果 JSON。不宣称已能出图、不伪造输出；最终以两份日志为准 |
| 2 | ComfyUI `GET /object_info` 6 类节点核对 | **阻塞** | 本机路径 / 工作流 JSON 未登记（`00-工具链接入说明.md` §7），不臆造、不连接、不绕过 |
| 3 | `style_anchor.png` / 128px 精灵表 / OpenPose 骨架库 | **未产出** | 本机未跑出图，Rank-4 下无任何图片文件；不伪造 |
| 4 | 256 色收敛 / alpha 人眼判定 / 降 128px 发糊检查 / 装饰层一致性 | **无法执行（阻塞）** | 无源 PNG；收敛路线已写明（ComfyUI / Aseprite / ImageMagick），不混用 `image/quantize.py` |
| 5 | 显存档位 A~D 实测 | **未实测** | `pipeline_tier=D` 仅为 R2 采用的降级路线；本轮只实测到加载阶段 14203 MiB（非最终峰值） |
| 6 | 任务书-R3 §2 字段名与 R2 冻结口径差异 | **待 HOST 裁决，不擅改** | R3 为 23:40 排队包（早于 R2 落地），其 `base_canvas_px` / `filter` / `mipmaps` / `default_texture_filter` / `pipeline` / `fallback_level` / `comfyui_seed` / `consumption` 与 R2 实际 `canvas_base_px` / `expected_import_settings{...}` / `pipeline_tier` / `fallback_route` / `m0_validation` 口径不同。按本次「R2 一律不重做」不改写冻结件，登记差异待裁决 |
| 7 | `prompt_skeleton.json` 的 `seed_lock.action_offset` 与 R2 冻结 pose 不一致 | **待裁决（沿用 R2 登记）** | 冻结件不擅改，须 HOST 裁决后整体升 v2；`pose_names.json::r1_discrepancy` 已登记 |
| 8 | `128bit` 原词歧义 | **待裁决** | 仍按 128px 基准画布理解，不自行改口径 |
| 9 | 主角 / Boss / 关键场景 Aseprite 人工精修 | 未开始 | 人工环节（M1 / M5），`human_refine=done` 才允许交付 |
| 10 | Godot 三段构建门禁 | **不适用 / 未跑** | 本工位无 `.gd/.tscn/.tres`，如实说明，不谎报 |
| 11 | `任务书-R3.md` §5「在 `00-群聊总线.md` 末尾追加一条 `TYPE=交付完成` 消息」 | **本轮不执行（依据登记）** | 本次 HOST 硬性约束明确「**不写总线**」，且「唯一可写范围」仅 `Rank-4\` + 回执 outbox，`00-群聊总线.md` 不在其中。以 HOST 最新指令为准，不写、不擅自扩大写范围 |
| 12 | 付费 API / `stable-audio`(gated 403) / `gen3d` / `mia-rig` | **禁用 / 不碰** | 不申请、不补装、不碰 WSL、不绕过；不列「确认花费」为待办 |

---

## ④ 完成标准判定

| 判据 | 结论 |
|---|---|
| `任务书-R3.md` §2 交付件齐备 | ✓ 4 类由 R2 交付（按本次 HOST 指令不重做）+ `ASSET-PROOF.md` / `DONE-R3.md` 本轮新建 = 6/6 |
| 所有 JSON 合法可解析（独立 + 内嵌） | ✓ 独立 **9/9** + 内嵌 **12/12** 真跑解析通过（实际 stdout 见 §2.2 / §2.3） |
| `ASSET-PROOF.md` 实跑记录 | ✓ 已写；真跑已启动、如实记阻塞、不宣称已能出图、不伪造输出 |
| `DONE-R3.md` 存在 | ✓ 本文件 |
| 中枢回执 | ✓ `command_center\ai\4\outbox\receipt_R3_A4.json`（`status=done`，`result` 引用本文件实际结论） |
| 未完成项如实降级 | ✓ 出图 / ComfyUI 路径 / 显存实测均如实写阻塞，不伪造、不谎报 |

**本轮 R3 达成**：按本次 HOST 指令补齐 R3 新增 / 缺失项、`ASSET-PROOF.md` 实跑记录、完成标志与中枢回执；R2 产出全部原样保留。未完成项均属任务书允许的「尽力而为 / 如实降级」范围，不影响 R3 完成判定（与 `DONE-R2.md` §4 同一判据）。

---

## ⑤ 合规声明

- 只写 `Rank-4\`；唯一例外 `command_center\ai\4\outbox\` 回执 JSON。**未写群聊总线**（本次 HOST「不写总线」优先于任务书 §5，见 §3 第 11 项）；未写其它工位 / teamwork 根目录 / 总纲 / 契约 / 任务书；未自行 `git commit` / `git push`。
- 零付费 / 零外部依赖：付费 API 一律禁用，不列云服务、不列花费确认项；`HF_ENDPOINT` 走镜像 + 本地 31G 缓存，未设 `HF_HUB_OFFLINE=1`。
- **ComfyUI 仍是主美术路线**；`qwen-image` 仅为同为零付费的本地备选（姿势基准图 / kit 图 / 装饰层底稿），不取代。
- `image/quantize.py` 是 **DiT 权重量化器**，**未**用作 256 色调色板量化器；调色板收敛走 ComfyUI / Aseprite / ImageMagick。
- `stable-audio`（gated 403）/ `gen3d` / `mia-rig` 不可用：不申请、不补装、不碰 WSL、不绕过。
- 默认不刺探：未扫别人工位、未轮询、未写探针 / 测量 / preflight 脚本；开工只读一次 `00-群聊总线.md`。真跑为单 GPU job，未并行。
- 中文 UTF-8；所有独立 JSON 与文档内嵌 JSON 块合法可解析。
- **不宣称已能出图、不伪造输出**：本轮最重要的一条。
