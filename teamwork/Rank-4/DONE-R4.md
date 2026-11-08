# DONE-R4 · Rank-4（美术管线与工具链）完成标志

> 轮次：**R4**（兜底循环：每小时自动化 01:36 未触发 / HOST 全闭环续派）｜派单：`cmd-20261109-013419-327-A4`（`调度任务单-latest.json` / `command_center\ai\4\inbox\`）
> 主任务书：`Rank-4\任务书-R4.md`｜必读（开工只读一次）：`任务书-R4.md`、`调度任务单-latest.json`、`DONE-R3.md`、`ASSET-PROOF.md`、`00-协作契约.md`、`00-群聊总线.md`、`00-工具链接入说明.md`
> 口径：`00-协作契约.md` §9.3 / §10（128px + ≤256 色、ComfyUI 主路线、零付费）；R2 冻结 §6 第 6/7 条 pose 名 / 像素规格
> **HOST 监测只认本文件。** 唯一可写 `Rank-4\`；唯一例外 `command_center\ai\4\outbox\` 回执 JSON。
> 本轮定位：**补齐 R4 新增 / 缺失项（出图结果验收 + 收敛 / 登记 / 对齐抽检结论）**；R2/R3 已产出的一律不重做、一个字节不改。

---

## ① 实际交付清单

### 1.1 本轮实际新建 / 改动文件（3 个，全部真实落盘）

| # | 文件（绝对路径） | 动作 | 内容 |
|---|---|---|---|
| 1 | `F:\Game\aierdengfahuan\teamwork\Rank-4\R4-验收记录.md` | **新建** | R4 新增验收记录：§1 出图 job 结果验收（只读 stdout/stderr 实测）｜§2 alpha/128px/≤256 色收敛校验（如实阻塞 + 收敛路线）｜§3 ComfyUI 路径与工作流 JSON 登记（如实阻塞）｜§4 装饰 RGBA 层与 base 逐像素对齐抽检（如实阻塞 + 对齐判据）｜§5 结构化验收 JSON（合法，已随自检解析）｜§6 合规声明 |
| 2 | `F:\Game\aierdengfahuan\teamwork\Rank-4\DONE-R4.md` | **新建** | 本文件（完成标志） |
| 3 | `F:\Game\aierdengfahuan\teamwork\command_center\ai\4\outbox\receipt_R4_A4.json` | **新建** | 中枢回执（唯一例外写范围）；写入后被中枢实时消费归档到 `command_center\dispatcher\receipts\receipt_R4_A4.json`，见 §1.4 / §2.4 |

> 出图日志 `asset_proof_stdout.txt` / `asset_proof_stderr.log` 本轮**只读检查、未写入**（R3 产出原样保留）。`ASSET-PROOF.md`（R3 实跑记录）本轮**未改动**，R4 验收结论另由新增文件承载，避免碰冻结件。

### 1.2 对照 `任务书-R4.md` §2 交付清单（逐项处理）

| # | 任务书 §2 要求 | 本轮处理 | 实际结论 |
|---|---|---|---|
| 1 | `qwen-image --quant nf4` 后台 job 结果验收（以 stdout/stderr 日志为准） | **已执行（只读）** | `Rank-4` 无任何 PNG、stdout 0 字节、stderr 停在 `transformer checkpoint shards 50%(1/2)`、无报错、无结果 JSON；详见 `R4-验收记录.md` §1 与本文件 §2.5。**未启动第二个 GPU job** |
| 2 | 出图后 alpha / 128px / ≤256 色收敛校验 | **如实阻塞** | 无源 PNG → 无法执行，不编造校验数据；收敛路线（ComfyUI / Aseprite / ImageMagick，不混用 `image/quantize.py`）与判据已写明，见 `R4-验收记录.md` §2 |
| 3 | ComfyUI 本机路径与工作流 JSON 登记 | **如实阻塞** | 未登记、用户未提供、默认不刺探；不臆造地址、不尝试连接、不绕过；ComfyUI 仍为主美术路线，见 `R4-验收记录.md` §3 |
| 4 | 装饰 RGBA 层与 base 逐像素对齐抽检 | **如实阻塞** | 无 base、无装饰层（图片计数 0）→ 无法执行，不臆造对齐结论；逐像素对齐判据已写明，见 `R4-验收记录.md` §4 |
| 5 | `Rank-4\DONE-R4.md` | **本轮新建 ✅** | 本文件（交付清单 / 自检 / 未完成项与阻塞） |

**结论**：任务书 §2 五类中，第 1 类已真跑只读验收、第 5 类完成标志已落盘；第 2/3/4 类因「无 PNG / 未登记」按本次 HOST 指令「无 PNG 如实记阻塞、不宣称已能出图、不伪造输出，继续完成其它可交付项」如实降级并写明路线与判据 → 逐项处理齐备，无遗漏、无谎报。

### 1.3 明确未改动的文件（R2/R3 产出原样保留）

`import.json`、`delivery_manifest.json`、`palette_256.json`、`pose_names.json`、`prompt_skeleton.json`、`hd2d_placeholder_params.json`、`player_idle_v1.import.json`、`美术管线.md`、`ASSET-PROOF.md`、`DONE-R2.md`、`DONE-R3.md`、`资产交付契约.md`、`HD-2D视觉规范.md`、`README.md`、`工具链配置.md`、`接口契约.md`、`任务书.md` / `任务书-R2.md` / `任务书-R3.md` / `任务书-R4.md`、`调度任务单-R2.json` / `调度任务单-latest.json`、`asset_proof_stdout.txt` / `asset_proof_stderr.log` —— **一个字节都未改**。

### 1.4 回执落位说明

回执按任务单 id 写入 `command_center\ai\4\outbox\receipt_R4_A4.json`。开工前实测该 outbox 为空（中枢 `AierdengfahuanCommander.exe` 消费后正常回收，见 `DONE-R3.md` §1.4 同一机制）。写入后中枢**实时消费**并归档到 `command_center\dispatcher\receipts\receipt_R4_A4.json`（`find` 实测，outbox mtime 由 01:34 变 01:43、再次为空）。回执 JSON 已在最终落位 `json.load` 验证合法（见 §2.4）。本轮不轮询、不伪造「已被接收」之外的状态。

---

## ② 自检结果（真跑 / 解析的实际输出结论）

### 2.1 真跑方式

- 用**内联 `python`**（`python - <<'PY'`，不落任何脚本文件）做交付自检：`json.load` 解析 `Rank-4\*.json` 全部独立文件、`json.loads` 解析 `Rank-4\*.md` 全部内嵌 `json` 代码块、`json.load` 解析中枢回执。依据 `DONE-R2.md` §2.1 / `DONE-R3.md` §2.1 口径（**交付自检，不是探针 / 测量 / preflight 脚本**）。
- 实际执行了解析器（非人工目视）；零付费、无外部调用、未扫别人工位、未写探针。
- 本轮「真跑」= §2.2~§2.4 的 JSON 解析自检 + §2.5 的**只读出图结果验收**（任务明确要求的动作）+ §2.4 回执验证。**未启动任何出图进程 / 第二个 GPU job**。
- 任务单正文含「真跑引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe` 三段门禁并 grep `SCRIPT ERROR`」字样；但本工位按 `README.md` §1 / `资产交付契约.md` §1 **不产出 `.gd` / `.tscn` / `.tres` / shader、不建 Godot 工程**，交付件为 JSON + Markdown，三段门禁在本工位**无可校验对象、本轮未跑**，不谎报跑过（与 `DONE-R2.md` §2.6 / `DONE-R3.md` §2.6 同一口径）。

### 2.2 独立 JSON 真跑解析（最终自检实际 stdout 结论）

```text
=== [1] 独立 JSON 文件真跑解析 (Rank-4/*.json) ===
  OK   delivery_manifest.json                   dict(20)
  OK   hd2d_placeholder_params.json             dict(18)
  OK   import.json                              dict(31)
  OK   palette_256.json                         dict(12)
  OK   player_idle_v1.import.json               dict(31)
  OK   pose_names.json                          dict(14)
  OK   prompt_skeleton.json                     dict(20)
  OK   调度任务单-R2.json                            dict(9)
  OK   调度任务单-latest.json                        dict(9)
  -> 独立 JSON: 9/9 解析通过
```

> 本次 HOST 点名的 `import.json` / `delivery_manifest.json` / `palette_256.json` / `pose_names.json` / `prompt_skeleton.json` / `美术管线.md` 等冻结件全部原样保留且解析通过：**9/9 合法可解析**（与 R3 的 9/9 一致，本轮未新增独立 JSON 文件）。

### 2.3 文档内嵌 JSON 块真跑解析（最终自检实际 stdout 结论）

```text
=== [2] 文档内嵌 json 块真跑解析 (Rank-4/*.md) ===
  OK   ASSET-PROOF.md               block#1 dict(20)
  OK   HD-2D视觉规范.md                 block#1 dict(12)
  OK   R4-验收记录.md                   block#1 dict(8)
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
  -> 内嵌 JSON 块: 13/13 解析通过
```

> R3 为 12 块；本轮新增 `R4-验收记录.md` §5 结构化验收 JSON 块 → **13 块，13/13 解析通过**。本 `DONE-R4.md` 内所有代码块用 `text` 标记、不含以 `json` 语言标记的代码块，故写完后统计仍为 **13/13**（自检口径自洽，与 `DONE-R2.md` §2.3 / `DONE-R3.md` §2.3 做法一致）。

### 2.4 中枢回执 JSON 真跑解析（最终自检实际 stdout 结论，含首次 FAIL 的如实处置）

```text
=== [3] 中枢回执 JSON 真跑解析 (outbox 写入 -> 中枢消费归档) ===
  OK   receipt_R4_A4.json  dict(4)  落位=dispatcher/receipts (中枢消费归档)
       task_id = cmd-20261109-013419-327-A4
       ai      = 4
       status  = done
       result_len = 385
       task_id_matches_dispatch = True
```

> **如实记录首次 FAIL 与处置**：第一次自检的 `[3]` 指向 outbox 路径时返回 `FAIL … [Errno 2] No such file or directory`，原因是中枢在我写入后**实时消费**把回执移出了 outbox（非写入失败、非内容缺失）。随即 `find` 实测归档落位 `command_center\dispatcher\receipts\receipt_R4_A4.json`，重跑完整解析指向实际落位 → `OK dict(4)`、`task_id` 与派单一致、`ai=4`、`status=done`、`result_len=385`。不隐瞒首次 FAIL、不伪造「一直在 outbox」。

### 2.5 出图结果验收（只读真跑，实际输出结论）

```text
[1] ls -la Rank-4/*.png                       -> ls: cannot access ... No such file or directory
[2] find Rank-4 -maxdepth 1 -type f (图片类) | wc -l -> 0
[3] asset_proof_stdout.txt : 0 字节（mtime 01:05，--json 结果对象未产生）
[4] asset_proof_stderr.log : 25320 字节 / 8 行（mtime 01:21）
[5] date                                     -> 2026-11-09 01:41:48
[6] stderr 末段: Loading weights 100% 750/750 [08:47] -> [load] transformer (nf4)
    -> Fetching 2 files 100% 2/2 -> Loading checkpoint shards 50% 1/2 [05:35, 335.95s/it]
[7] Grep 报错类 (Traceback|Error|Exception|CUDA out of memory|OOM|Killed|Assertion, -i) -> No matches found (0)
[8] Grep 完成类 (\.png|Saving|saved|output|generated|denois|steps|infer|Finished|Done, -i) -> No matches found (0)
```

**判读（如实）**：与 HOST `MSG-20261109-0135-HOST` 观测一致（权重 `750/750` 已加载、`checkpoint shards 50%`、**仍无 PNG**）。日志 mtime `01:21`、检查时刻 `01:41`，约 20 分钟无新增输出 → 单一长时后台 job 停在 `transformer` checkpoint shard 1/2 加载，未进入去噪 / 写图；无 Traceback / Error / OOM，不是崩溃而是首次全量 30.84 GiB 权重 nf4 逐片量化 + CPU offload 加载极慢。**无 PNG → 按本次 HOST 指令走「如实记阻塞」分支**：不宣称已能出图、不伪造 PNG / 结果 JSON / 校验数据；**未启动第二个 GPU job**，单一后台 job 未杀、未重启、未并行，最终结果仍以两份日志为准。

### 2.6 R2 冻结口径字段覆盖核对（不重做但已校验）

- `palette_256.json`：`canvas_base_px=128` / `indexed=true` / `max_colors=256`，已解析通过（§2.2）。
- `pose_names.json`：`frozen_name_count=22`、`p1_`/`p2_` 前缀，已解析通过（§2.2）。
- `import.json`：`canvas_base_px=128`、`palette_id=hd2d_index_256_v1`、四项 `expected_import_settings` 齐备，已解析通过（§2.2）。
- `美术管线.md` §10.4：ComfyUI 主路线 / qwen-image 备选 / 后处理脚本 / 单 GPU job / `quantize.py` 易混澄清，4 个 JSON 块解析通过（§2.3）→ 佐证本轮「不重做」合理。
- 本轮未复制、未改写、未重新生成任何上述冻结件。

---

## ③ 未完成项与阻塞（如实，全部非谎报）

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| 1 | `qwen-image --quant nf4` 首次出图 | **未完成 / 阻塞（进行中）** | 单一后台 job 停在 `transformer checkpoint shards 50%(1/2)`，日志 01:21 起约 20 分钟无新增；无 PNG / 无结果 JSON / 无报错。不宣称已能出图、不伪造输出；未杀 / 未重启 / 未并行，最终以 `asset_proof_stdout.txt` / `asset_proof_stderr.log` 为准 |
| 2 | alpha / 128px / ≤256 色收敛校验 | **无法执行（阻塞）** | 无源 PNG；收敛路线（ComfyUI / Aseprite / ImageMagick，不混用 `image/quantize.py` DiT 权重量化器）与判据已写明，不编造校验数据 |
| 3 | 装饰 RGBA 层与 base 逐像素对齐抽检 | **无法执行（阻塞）** | 无 base、无装饰层（图片计数 0）；尺寸 / 帧序 / 坐标系 / seed / 降采样参数 / 逐像素 RGBA 比对的判据已写明，不臆造「已对齐 / 不一致像素数 = 0」 |
| 4 | ComfyUI 本机路径与工作流 JSON 登记 + `GET /object_info` 6 类节点核对 | **阻塞** | `00-工具链接入说明.md` §7 仍「待用户提供 / 待刺探指令」，本轮 HOST 未提供、目录无工作流 JSON；不臆造地址、不尝试连接、不绕过、不主动扫盘 |
| 5 | `style_anchor.png` / 128px 精灵表 / OpenPose 骨架库 | **未产出** | 本机未跑出图，`Rank-4` 图片类文件计数 0；不伪造 |
| 6 | 显存档位 A~D / 峰值显存实测 | **未实测** | stdout 无 `--json` 结果（0 字节），只有 R3 记录的加载阶段 14203 MiB（非最终峰值）；本轮不编造耗时 / 峰值 |
| 7 | 任务书-R3 §2 字段名与 R2 冻结口径差异 / `prompt_skeleton.json` 的 `seed_lock.action_offset` / `128bit` 原词歧义 | **待 HOST 裁决（沿用 R2/R3 登记）** | 冻结件不擅改，须 HOST 裁决后整体升 v2；`pose_names.json::r1_discrepancy` 已登记 |
| 8 | 主角 / Boss / 关键场景 Aseprite 人工精修 | 未开始 | 人工环节（M1 / M5），`human_refine=done` 才允许交付 |
| 9 | Godot 三段构建门禁 | **不适用 / 未跑** | 本工位无 `.gd/.tscn/.tres`，如实说明，不谎报（§2.1） |
| 10 | `任务书-R3.md` §5「在 `00-群聊总线.md` 末尾追加一条 `TYPE=交付完成` 消息」 | **本轮不执行（依据登记）** | 本次 HOST 硬性约束「**不写总线**」，且唯一可写范围仅 `Rank-4\` + 回执 outbox，总线不在其中；以 HOST 最新指令为准 |
| 11 | 付费 API / `stable-audio`(gated 403) / `gen3d` / `mia-rig` | **禁用 / 不碰** | 不申请、不补装、不碰 WSL、不绕过；不列「确认花费」为待办 |

---

## ④ 完成标准判定

| 判据 | 结论 |
|---|---|
| `任务书-R4.md` §2 交付件逐项处理 | ✓ 第 1 类只读真跑验收 + 第 5 类 `DONE-R4.md` 落盘；第 2/3/4 类因无 PNG / 未登记如实阻塞并写明路线与判据 → 5/5 项处理齐备 |
| 所有 JSON 合法可解析（独立 + 内嵌 + 回执） | ✓ 独立 **9/9** + 内嵌 **13/13** + 回执 `dict(4)`（`task_id` 匹配 / `ai=4` / `status=done`）真跑解析通过（实际 stdout 见 §2.2 / §2.3 / §2.4） |
| 不宣称已能出图 / 不伪造输出 / 不拉起第二个 GPU job | ✓ 无 PNG 如实记阻塞；只读日志验收；单一后台 job 未杀未重启未并行 |
| `DONE-R4.md` 存在 | ✓ 本文件 |
| 中枢回执 | ✓ `command_center\ai\4\outbox\receipt_R4_A4.json`（`status=done`，`result` 引用本文件实际结论），已被中枢消费归档并验证合法 |
| 未完成项如实降级 | ✓ 出图 / 收敛 / 对齐 / ComfyUI 登记 / 显存实测均如实写阻塞，不伪造、不谎报 |

**本轮 R4 达成**：按本次 HOST 指令补齐 R4 新增 / 缺失项（4 类验收结论 + 完成标志 + 中枢回执），R2/R3 产出全部原样保留、一个字节未改。未完成项均属任务书允许的「尽力而为 / 如实降级」范围，不影响 R4 完成判定（与 `DONE-R2.md` §4 / `DONE-R3.md` §4 同一判据）。

---

## ⑤ 合规声明

- 只写 `Rank-4\`（`R4-验收记录.md`、`DONE-R4.md`）；唯一例外 `command_center\ai\4\outbox\receipt_R4_A4.json` 回执。**未写群聊总线**（本次 HOST「不写总线」优先于任务书-R3 §5）；未写其它工位 / teamwork 根目录 / 总纲 / 契约 / 任务书；未自行 `git commit` / `git push`。
- 零付费 / 零外部依赖：付费 API 一律禁用，不列云服务、不列花费确认项；本轮无任何网络出图调用。
- **ComfyUI 仍是主美术路线**；`qwen-image` 仅为同为零付费的本地备选（姿势基准图 / kit 图 / 装饰层底稿），不取代。
- `image/quantize.py` 是 **DiT 权重量化器**，**未**用作 256 色调色板量化器；调色板收敛走 ComfyUI / Aseprite / ImageMagick。
- `stable-audio`（gated 403）/ `gen3d` / `mia-rig` 不可用：不申请、不补装、不碰 WSL、不绕过。
- 默认不刺探：仅只读检查 `Rank-4\*.png` 与两份日志（本轮任务明确要求的验收动作），未扫别人工位、未轮询、未写探针 / 测量 / preflight 脚本；开工只读一次 `00-群聊总线.md`。
- 中文 UTF-8；所有独立 JSON 与文档内嵌 JSON 块合法可解析。
- **不宣称已能出图、不伪造输出、不拉起第二个 GPU job**：本轮最重要的一条。

---

## ⑥ 本轮（R4）复核补记 · 由本执行实例追加（主体 §1~§5 保留未改）

> 追加依据：本轮 HOST 派单 **R4** / `cmd-20261109-013419-327-A4`。开工盘点发现本轮 R4 主体交付件（`R4-验收记录.md`、`DONE-R4.md` §1~§5）**已由上一次并发实例完整写入**，且已使用正确 `task_id`。按本次 HOST「先盘点、只补缺口、不重做 / 一律保留」→ 主体一字不改，仅追加本节并补写唯一缺口（outbox 回执）。以下为本实例**自己真实跑出**的结论，非照抄历史输出。

### 6.1 本轮实际写入 / 补齐的文件（具体文件名）

| 文件 | 动作 | 说明 |
|---|---|---|
| `teamwork\command_center\ai\4\outbox\receipt-R4.json` | **补写（缺口）** | 开工盘点 outbox 为空（`Glob **/*` = No files found）；按 HOST 指定 `task_id=cmd-20261109-013419-327-A4` / `ai=4` / `status=done`，`result` 引用本 DONE 实际结论，4 字段 |
| `teamwork\Rank-4\DONE-R4.md` | **仅追加本节** | 主体 §1~§5 未改一个字节 |

> 未写（原样保留）：`R4-验收记录.md`、`ASSET-PROOF.md`、`asset_proof_stdout.txt` / `asset_proof_stderr.log`、`import.json` / `delivery_manifest.json` / `palette_256.json` / `pose_names.json` / `prompt_skeleton.json` / `hd2d_placeholder_params.json` / `hd2d_placeholder_r5_params.json` / `player_idle_v1.import.json`、`HD-2D视觉规范.md` / `资产交付契约.md` / `美术管线.md` / `工具链配置.md` / `接口契约.md` / `README.md`、R2/R3/R5/R6 全部 DONE 与任务书、`调度任务单-*.json`。**未写**群聊总线、总纲、协作契约、进度台账、`00-汇总.md`、其它 Rank 工位；未自行 `git commit` / `git push`。

### 6.2 本轮真跑 / 自检输出结论（内联 `python`，未落盘任何脚本）

```text
=== [1] 独立 JSON 真跑解析 (Rank-4/*.json) ===
  -> 独立 JSON: 10/10   (delivery_manifest / hd2d_placeholder_params /
      hd2d_placeholder_r5_params / import / palette_256 / player_idle_v1.import /
      pose_names / prompt_skeleton / 调度任务单-R2 / 调度任务单-latest)
=== [2] 内嵌 json 块真跑解析 (仅行首围栏, 与 R2/R5/R6 口径一致) ===
  -> 内嵌 JSON 块: 16/16
=== [3] 256 色索引调色板核对 ===
  palette_id=hd2d_index_256_v1  canvas_base_px=128  indexed=True
  max_colors=256  color_count=32  len(colors)=32  count_matches=True
  all_hex6_valid=True  unique=32  <=256=True
=== [4] import.json 与调色板引用一致性 ===
  palette_id_match=True  canvas_base_px=128  palette_subset_of_256=True missing=[]
  lossless=True  mipmaps_off=True  Nearest=True  default_filter_0=True
=== [5] 三段门禁适用对象 (.gd/.tscn/.tres) ===
  count=0  -> 无适用对象, 未跑
```

**如实记录两类口径差异（不隐瞒、不淡化）**：本实例首轮用宽口径正则得到内嵌块 **16/19**，3 个 `FAIL … Expecting value: line 1 column 1 (char 0)` 位于 `DONE-R2.md` / `DONE-R5.md` / `DONE-R6.md`。经一次性只读查证，这 3 处是**正文里行内反引号引用的 json 围栏字样**（例如「仅行首围栏」类标题文字、「解析全部 .md 内嵌 json 围栏块」类说明），被宽口径正则误纳为代码块起止，并非真实非法 JSON 块、也不是文件缺陷；历史各轮（R2/R5/R6）自检口径均为「**仅行首围栏**」。改用行首围栏严格口径重跑 → **16/16 全通过**，与历史结论一致。本补记所有代码块用 `text` 标记、不含行首 json 围栏，故写完后内嵌块统计仍为 **16/16**（口径自洽）。

**256 色收敛（本轮可做部分）**：无源 PNG，**无法对实际图像做 alpha / 128px 降采样 / 索引色收敛的实测**（如实阻塞，见主体 §3 第 2 项）；但调色板规格与引用一致性已按上表 [3][4] **真跑核对全 PASS**：`≤256` 色上限、`indexed=true`、`canvas_base_px=128`、32 色全为合法 `#RRGGBB` 且无重复、`import.json::palette` 全部落在索引板内、`palette_id` 一致、四项导入期望值（lossless / mipmaps:false / Nearest / `default_texture_filter=0`）齐备。

**三段构建门禁**：本工位 `Rank-4` 下 `.gd` / `.tscn` / `.tres` 计数 **0** → **无适用对象、未跑**，不编造门禁 stdout、不谎报 grep `SCRIPT ERROR` 结果（与主体 §2.1 / §3 第 9 项同口径，按本次 HOST「本工位无脚本/场景/资源文件则如实写无适用对象、未跑」执行）。

### 6.3 出图 job 只读检查结论（唯一一次，不重复）

```text
Glob "Rank-4/**/*" 唯一一次全量列举 -> 33 个文件, 无任何 .png (含子目录)
asset_proof_stdout.txt -> 1 行 / 空内容 (--json 结果对象未产生)
asset_proof_stderr.log -> [load] text_encoder (nf4), Loading weights 750/750,
                          [load] transformer (nf4), Fetching 2 files 100%,
                          Loading checkpoint shards: 50% (1/2, 335.95s/it)
```

→ **无 PNG，如实登记为阻塞**（与 HOST `MSG-20261109-0135-HOST`「权重 750/750 已加载、checkpoint shards 50%、仍无 PNG」一致）。**未启动第二个 GPU 出图 job、未重复执行 qwen-image / ComfyUI 出图命令、未 kill 现有 job**；最终结果仍以两份日志为准。按本次 HOST 指令「不把『无 PNG』当作本轮失败」，继续完成本轮其它交付。

### 6.4 未完成项与阻塞（如实，沿用主体 §3 并补充新增登记）

| # | 项 | 状态 |
|---|---|---|
| 1 | qwen-image --quant nf4 首次出图 / alpha / 128px / ≤256 色实测收敛 / 装饰 RGBA 逐像素对齐抽检 / 显存峰值实测 | **阻塞**（无源 PNG；收敛路线与对齐判据见 `R4-验收记录.md` §2 / §4，不编造校验数据、不伪造 PNG） |
| 2 | ComfyUI 本机路径与工作流 JSON 登记 + 6 类节点核对 | **阻塞**（未登记、默认不刺探，不臆造地址、不尝试连接、不绕过；ComfyUI 仍为主美术路线，qwen-image 仅本地零付费备选） |
| 3 | 三段构建门禁 | **无适用对象、未跑**（count=0，如实不编造） |
| 4 | `调度任务单-latest.json` 与本轮派单不一致 | **待 HOST 裁决**：该文件实为 `[ROUND=R6]` / `cmd-20261109-022337-016-A4`，而本轮 HOST 明确 R4 / `cmd-20261109-013419-327-A4`。本实例按 HOST 指令以 `327-A4` 执行、回执 `task_id=327-A4`（**未沿用历史 / 后续命令 id**），不擅自裁决、不修改 latest 任务单，仅如实登记 |
| 5 | 付费 API / `stable-audio`(gated 403) / `gen3d` / `mia-rig` | **禁用 / 不碰**（不申请、不补装、不碰 WSL、不列花费确认项） |

### 6.5 完成判定（复核结论）

交付清单按 `任务书-R4.md` 逐项处理齐备（能做的真跑 / 核对、不能做的如实阻塞）；本实例真跑自检 **10/10 + 16/16 + 256 色核对全 PASS + 门禁如实说明**；出图 PNG 无 → 如实阻塞且按 HOST 指令不算本轮失败；`DONE-R4.md` ①交付清单 / ②自检与真跑结论 + 出图只读检查结论 / ③未完成项与阻塞三段齐备；outbox 回执已补写（`task_id` 正确、`status=done`）。

→ **与主体 §4 一致：本轮 R4 达成，`status=done` 真实成立**，无谎报、无伪造输出、未拉起第二个 GPU job。

### 6.6 回执落位复核（收尾补充，如实登记；不改变 6.5 判定）

```text
=== [A] outbox 回执 json.load 复核 (写完 receipt-R4.json 后) ===
  INFO [Errno 2] No such file or directory: outbox/receipt-R4.json
  -> 写入动作已成功 (Write 返回 Successfully created), 中枢实时消费移出 outbox,
     与主体 §1.4 / §2.4 同一机制 (首次 FAIL + 消费归档), 非写入失败, 不伪造「一直在 outbox」
=== [B] DONE-R4.md 追加后内嵌块口径自洽复核 ===
  内嵌 json 块(行首围栏): 16/16   含复核补记=True   含正确 task_id=True
=== [C] 精确检索 command_center/**/receipt-R4.json ===
  hits=[dispatcher/receipts/receipt-R4.json]
  其内容: task_id=cmd-20261109-013419-323-A2  ai=2  status=done
          task_id_matches_dispatch=False  (是 Rank-2 的 R4 回执, 非本工位)
=== [D] 本工位唯一命名回执归档 (receipt_R4_A4.json, 主体 §1.1/§2.4 命名) ===
  archive exists=True   keys=[task_id, ai, status, result]
  task_id=cmd-20261109-013419-327-A4  ai=4  status=done
  task_id_matches_dispatch=True  ai_is_4=True
=== [E] outbox 当前内容 (一次) ===
  files=[]  (中枢消费后正常回收)
```

**如实判读**：

1. 本实例按本轮 HOST 派单示例名写入 `outbox/receipt-R4.json`（Write 成功），中枢实时消费后移出 outbox（`[A]` / `[E]`）；与主体 §1.4 / §2.4 记载的既有机制一致，**不隐瞒首次 `INFO`、不伪造「回执一直在 outbox」**。
2. `[C]`：`receipt-R4.json` 不带 ai 标识、4 路共用该名 → **跨工位同名冲突**：归档区同名文件是 Rank-2 的 R4 回执（`ai=2` / `323-A2`），本实例写入的该文件未在该同名归档路径出现（不臆测中枢去向、不伪造落位）。
3. `[D]`：本工位唯一命名回执 `dispatcher/receipts/receipt_R4_A4.json`（主体 §1.1 / §2.4 既有命名）**已正确落位**，4 字段齐全、`task_id=cmd-20261109-013419-327-A4`、`ai=4`、`status=done`、与派单 id 一致 → **中枢已持有本工位 R4 的 done 回执**。故**不再补写第三个回执**（避免冗余 / 重做），沿用既有唯一命名件。
4. 完成判定不变（6.5）：`DONE-R4.md` 三段齐备 + outbox 回执写入成功 + 唯一命名归档 `status=done` 字段正确 + 自检真跑全通过 + 出图无 PNG 如实阻塞 → **`status=done` 真实成立**。

**待 HOST 裁决（只登记、不擅改）**：`receipt-R4.json` 跨工位同名冲突（是否统一为带 ai 后缀命名、同名归档如何处置）。本实例不修改 Rank-2、中枢、`dispatcher/receipts` 下任何文件，不轮询、不伪造「已被接收」之外的状态。
