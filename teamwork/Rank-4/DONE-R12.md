# DONE-R12.md · Rank-4 R12 完成报告

> 轮次：**R12（ComfyUI 出图就绪核验）**｜派单：`cmd-20261109-044100-997-A4`｜工位：Rank-4 美术管线与工具链
> 本轮定位：**只读核验、绝不出图**。完成标志：`DONE-R12.md` 已写 + 已按本任务单 id 向 `command_center\ai\4\outbox\` 投递 `status=done` 回执（中枢即时回收后权威件在 `dispatcher\receipts\`，见 §2.5）。
> 只读边界：仅 `GET /system_stats`、`GET /object_info` 与本地 `json.load`；**未 POST `/prompt`、未出图、未启动第二个 GPU job、未杀/重启旧 job**；`128bit` 仍待用户确认、不自行改口径；零付费 / 零外部依赖；默认不刺探；中文 UTF-8。

---

## 1. 实际交付清单

| # | 文件 | 动作 | 实际内容 |
|---|---|---|---|
| 1 | `teamwork\Rank-4\COMFYUI-READINESS.md` | **新建**（29,832 字节，UTF-8 无 BOM） | ① SDXL checkpoint 与 SD1.5 系 LoRA/ControlNet **不兼容**的结论 / 三层依据 / 后果 / 精确化更正 / 路线 A·B（只登记不裁决）；② 512 latent 对 SDXL 的影响与建议（**只给建议、不改骨架**）；③ 出图前置清单 7 项（GPU 空闲判定、`ckpt_name`、单 `[SUBJECT]` 槽、seed、128px/≤256 色收敛、产物落 `assets/generated/chars/`、边界合规）；④ 用户说「出图」后的一键命令与 8 条验收口径；⑤ 旧 job 现状与为何不并行；另含 `comfyui_workflow_pixel.json` 改动判定（before==after） |
| 2 | `teamwork\Rank-4\comfyui_workflow_pixel.json` | **保持不动**（无改动） | `EmptyLatentImage` `width:512→512` / `height:512→512`；`bytes=2529`、`sha256=98d6d722...` 改动前后一致（**无 `/object_info` 依据升 1024**，按硬边界「除非有 `/object_info` 依据否则不改骨架」判定；改动前后与依据已写入 READINESS §3.3 / §7） |
| 3 | `teamwork\Rank-4\DONE-R12.md` | **新建**（本文件） | ① 实际交付清单 ② 自检（含只读核对**实际输出**）③ 未完成项与阻塞 |
| 4 | `teamwork\command_center\ai\4\outbox\receipt_cmd-20261109-044100-997-A4.json` | **新建投递**（2,347 字节）→ 中枢即时回收 | `task_id=cmd-20261109-044100-997-A4` / `ai=4` / `status=done` / `result` 引用本文件实际结论；权威回收件 `command_center\dispatcher\receipts\receipt_cmd-20261109-044100-997-A4.json`（§2.5） |

**未写（本轮无落位改动 / 不越界）**：`godot\`（含 `godot\assets\generated\import.json`、`chars\`）、总线 `00-群聊总线.md`、总纲、契约、任务书、其它工位、任何 `.gd` / `.tscn` / `.tres`；未自行 `git commit` / `git push`。既有件（`comfyui_workflow_pixel.json`、`COMFYUI-WORKFLOW.md`、`prompt_skeleton.json`、`ART-SPEC-FINAL.md`、`I5-DELIVERY-CHECKLIST.md` 等）一律引用、不重做。

---

## 2. 自检（含只读核对的实际输出，非推测、非伪造）

### 2.1 `GET http://127.0.0.1:8188/system_stats` 实际 stdout

```text
=== python 检测 ===
Python 3.13.14

=== GET /system_stats（只读） ===
comfyui_version = 0.33.2
required_frontend_version = 1.49.6
pytorch_version = 2.9.1+cu130
argv = ['main.py', '--listen', '127.0.0.1', '--port', '8188', '--cuda-device', '0', '--disable-auto-launch']
device_count = 1
device[0] name=cuda:0 NVIDIA GeForce RTX 4060 Ti : cudaMallocAsync vram_total=17175150592 vram_free=8959269586 torch_vram_total=33554432 torch_vram_free=22256338
```

- 与 04:39 实测一致。**关键只读证据**：`torch_vram_total=33554432`（32 MiB）≈ 空转 → ComfyUI 自身 PyTorch 未在跑 GPU job；整机差额 `17175150592 − 8959269586 = 8215801006` 字节 ≈ **7.65 GiB** 由外部旧 `qwen-image` 进程持有 → GPU **未空闲**、不并行、不 POST。

### 2.2 `GET http://127.0.0.1:8188/object_info` 实际 stdout（针对性提取，未落盘、未刷全量）

```text
node_count = 2724
CheckpointLoaderSimple.ckpt_name : list len=15
    count sdxl/xl-named = 3
    count sd15/15v/v1-named = 2
      - ... / juggernautXL_version6Rundiffusion.safetensors
      - pixelArtDiffusionXL_spriteShaper.safetensors
      - rundiffusionXL_beta.safetensors / anything-v5-PrtRE.safetensors / cyberrealistic_v40.safetensors / ...
LoraLoader.lora_name : list len=34
    count sdxl/xl-named = 3
    count sd15/15v/v1-named = 7
      - PixelArtRedmond15V-PixelArt-PIXARFK.safetensors
      - pixel-art-xl.safetensors
      - sdxl_lightning_4step_lora.safetensors
      - illustriousXLv01_stabilizer_v1.121.safetensors
      （另有 30 项 Wan / Qwen-Image / Minimax 等视频·编辑模型 LoRA）
ControlNetLoader.control_net_name : list len=19
    count sdxl/xl-named = 1
    count sd15/15v/v1-named = 19
      - control_v11p_sd15_openpose_fp16.safetensors 等 18 项 control_v11*_sd15_*
      - illustriousXL_openposev10.safetensors  （唯一非 sd15 项）
EmptyLatentImage.width  : type=INT opts={'default': 512, 'min': 16, 'max': 16384, 'step': 8, ...}
EmptyLatentImage.height : type=INT opts={'default': 512, 'min': 16, 'max': 16384, 'step': 8, ...}
--- 工作流骨架 8 类节点存在性 ---
  exists CheckpointLoaderSimple = True / CLIPTextEncode = True / EmptyLatentImage = True / KSampler = True
  exists VAEDecode = True / ImageScale = True / ImageQuantize = True / SaveImage = True
```

> 完整 15 / 34 / 19 项候选清单见 `COMFYUI-READINESS.md` §1.2。要点：① `pixelArtDiffusionXL` 存在（SDXL），② ControlNet **18/19** 为 `sd15` 系、③ LoRA **并非全 SD1.5**（存在 `pixel-art-xl` / `sdxl_lightning` 等 SDXL 系，但冻结引用的 `PixelArtRedmond15V` 是 SD1.5 系），④ `EmptyLatentImage` 的 `/object_info` **只有参数元信息、无「SDXL 需 1024」依据**。

### 2.3 本地 `json.load` 自检实际 stdout（`comfyui_workflow_pixel.json`，改动前基线）

```text
=== comfyui_workflow_pixel.json 本地自检（改动前基线） ===
bytes = 2529
sha256 = 98d6d722972137898f391591f8f5d38f265cf25df2ff988b3f2c0723aca82ddd
top_keys = ['prompt']
node_count = 9
node_ids = ['1', '2', '3', '4', '5', '6', '7', '8', '9']
  node 1 = CheckpointLoaderSimple / 2 = CLIPTextEncode / 3 = CLIPTextEncode
  node 4 = EmptyLatentImage / 5 = KSampler / 6 = VAEDecode
  node 7 = ImageScale / 8 = ImageQuantize / 9 = SaveImage
[SUBJECT]_occurrences_raw = 1
  [SUBJECT] located in node 2
ckpt_name = pixelArtDiffusionXL_spriteShaper.safetensors
EmptyLatentImage inputs = {'width': 512, 'height': 512, 'batch_size': 1}
KSampler seed/steps/cfg/sampler/scheduler/denoise = 20261108 28 7.0 euler_ancestral normal 1.0
ImageScale inputs = {'image': ['6', 0], 'upscale_method': 'nearest-exact', 'width': 128, 'height': 128, 'crop': 'disabled'}
ImageQuantize inputs = {'image': ['7', 0], 'colors': 256, 'dither': 'none'}
SaveImage inputs = {'images': ['8', 0], 'filename_prefix': 'aierdengfahuan_hd2d_r11'}
width/height within object_info range(16..16384,step8) = True
has LoraLoader node = False
has ControlNetLoader node = False
```

- 9 节点合法、`[SUBJECT]` 全文件仅 1 处（node 2）、512 在 `/object_info` 合法范围内、**无 `LoraLoader` / `ControlNetLoader` 节点** → 印证「不兼容只在补扩展件时兑现，当前骨架本身不受影响」。
- 本地冻结骨架 `prompt_skeleton.json` 逐字核对：`controlnet.model=control_v11p_sd15_openpose.pth`、`ip_adapter.model=ip-adapter_sd15.bin`、`layerdiffuse.method=SD15 Attention Injection (transparent)`、`single_slot.count=1`、`seed_lock.base_seed=20261108`（四件扩展全 SD1.5 系，见 READINESS §1.4 / §2.2）。

### 2.4 收尾复核实际 stdout（workflow 未改动 / 文件 UTF-8）

```text
=== R12 收尾复核（纯本地只读，不联网、不 POST） ===
workflow bytes = 2529
workflow sha256 = 98d6d722972137898f391591f8f5d38f265cf25df2ff988b3f2c0723aca82ddd
workflow sha256 == baseline(98d6d722...) = True
workflow json.load OK = True
COMFYUI-READINESS.md exists=True bytes= 29837 utf8_decode=OK bom= False
DONE-R12.md exists=False (pending)
READINESS has-json-fence = True
READINESS [SUBJECT] section mentions = 8
```

> 如实登记：首轮收尾复核报 `READINESS has-json-fence = True`，逐行 grep 核实所有 5 个代码块均以 ` ```text ` 开头（行 26/40/102/125/232）、闭合为 ` ``` `，唯一带 json 字样的围栏出现在 §9 合规声明里**引用**「不含该围栏」的措辞（自指）。已把该措辞改为「行首围栏不标注 json」，最终复核见 §2.5 `has-json-fence = False`。`DONE-R12.md exists=False` 是复核发生在本文件写入前的真实状态。

### 2.5 回执落位与最终自检实际 stdout

```text
=== R12 回执落位 + 最终自检（纯本地只读） ===
outbox receipt exists = False
dispatcher receipt exists = True
authoritative file = dispatcher\receipts\receipt_cmd-20261109-044100-997-A4.json
receipt bytes = 2347
json.load OK = True
task_id = cmd-20261109-044100-997-A4 | ai = 4 | status = done
task_id match = True
result references DONE-R12.md = True
--- 交付件最终核对 ---
COMFYUI-READINESS.md exists= True bytes=29832
DONE-R12.md exists= False
comfyui_workflow_pixel.json exists= True bytes=2529
workflow sha256 = 98d6d722972137898f391591f8f5d38f265cf25df2ff988b3f2c0723aca82ddd
workflow sha256 == baseline = True
READINESS utf8 OK = True | has-json-fence = False
```

```text
=== outbox / dispatcher 目录实况 ===
[outbox]  total 0（空）
[dispatcher/receipts 本次 id]  receipt_cmd-20261109-044100-997-A4.json  2347 字节
```

- **回执落位如实登记（不伪造「outbox 稳定存在」）**：已按任务书向 `command_center\ai\4\outbox\` **投递** `status=done` 回执；中枢即时回收（与 `DONE-R11.md` §2.7 登记的既定行为一致），权威件落在 `command_center\dispatcher\receipts\receipt_cmd-20261109-044100-997-A4.json`，`task_id` 与派单一致、`ai=4`、`status=done`、`result` 引用本文件实际结论、`json.load` 通过。不反复重投、不宣称 outbox 稳定留存。
- `DONE-R12.md exists= False` 同为「写本文件之前」的真实快照；写完本文件后三份交付件 + 权威回执均齐备。
- 所有独立 JSON 真跑 `json.load` 通过；回执为合法 JSON；`comfyui_workflow_pixel.json` sha256 改动前后一致 → **确无改动**。

### 2.6 自检结论汇总

| 自检项 | 结果 |
|---|---|
| 只读端点 | `GET /system_stats` / `GET /object_info` 各 1 次，HTTP 真跑、输出贴上文；**零 POST** |
| 兼容性结论 | SDXL ckpt vs 冻结 SD1.5 扩展件 **不兼容**（本机清单 + 本地冻结 JSON + 架构原理三层依据）；当前 9 节点骨架不含扩展节点、不受影响 |
| `EmptyLatentImage` | 保持 512×512，sha256 未变；无 `/object_info` 依据升 1024，判定与依据已写报告 |
| 单 `[SUBJECT]` 槽 | `occurrences_raw=1`、位于 node 2 |
| 128px / ≤256 色 | `nearest-exact 128×128` / `colors=256,dither=none` 均在位 |
| GPU / 旧 job | 未空闲（~7.65 GiB 被占）；不并行、不杀/不重启、不 POST |
| 回执 | 已投递、中枢回收、字段与派单一致、合法 JSON |
| 边界 | 只写 `Rank-4\` + 回执例外；未写 `godot\` / 总线 / 契约 / 其它工位；未自行 git |

---

## 3. 兼容性结论（供 HOST / 回执引用的一句话口径）

> `pixelArtDiffusionXL_spriteShaper.safetensors`（**SDXL 系**）与 `prompt_skeleton.json` 冻结的 **4 件 SD1.5 系扩展**（`pixel-art-lora.safetensors`、`control_v11p_sd15_openpose.pth`、`ip-adapter_sd15.bin`、`SD15 Attention Injection`）**跨架构不兼容、不能配套加载**；本机 `/object_info` 实测 ControlNet 18/19 为 `control_v11*_sd15_*`、冻结 LoRA `PixelArtRedmond15V` 为 SD1.5 系（另有 SDXL 系候选 `pixel-art-xl` / `sdxl_lightning`，如实登记）。**当前 9 节点最小骨架不含 `LoraLoader` / `ControlNetLoader`，骨架本身不受影响**；冲突只在补扩展件时以 `node_errors` 的 `size mismatch` / 静默失效兑现。路线 A（保 SDXL 换 SDXL 扩展件）/ 路线 B（改选本机 SD1.5 ckpt）**只登记不裁决**。因此「完整冻结骨架 + 扩展件」链路在裁决前**不能宣称可出图**。

---

## 4. 未完成项与阻塞（只登记，不擅改）

| # | 项 | 状态 |
|---|---|---|
| 1 | 实际出图 / 真实 PNG | **本轮不做**，`真实 PNG = 0`；POST `/prompt` 须 GPU 空闲 + 用户明确「出图」授权 |
| 2 | GPU 空闲 | ❌ 旧 `qwen-image` job 占 ~7.65 GiB（日志停 01:21、`checkpoint shards 50%`、3 小时+ 无 PNG）；不杀/不重启/不并行 |
| 3 | SDXL ckpt 与冻结 SD1.5 扩展件配套 | ⛔ **本轮已判定不兼容**；路线 A/B 待用户/HOST 裁决 + 真跑 |
| 4 | 冻结 LoRA 名 `pixel-art-lora.safetensors` ≠ 本机文件名 | 已如实登记（`object_info` 34 项中无此名），待对齐 |
| 5 | `EmptyLatentImage` 是否升 1024 / 768 | 只给建议（无 `/object_info` 依据 → 未改骨架），待用户说「出图」后真跑 A/B + HOST 裁决 |
| 6 | `128bit` 确切含义 | ⏸ 待用户确认（暂按 128px 基准画布），**不自行改口径** |
| 7 | ComfyUI 安装目录 | 未确认（`argv` 无绝对路径、进程命令行查询被安全策略阻止、未绕过）；API 端点已足够接入 |
| 8 | lora trigger 追加 / ControlNet / IPAdapter / LayerDiffuse 接入 | 链路无对应节点且兼容性未裁决，留待扩展轮次 |
| 9 | `seed_lock.action_offset` 与 R2 冻结枚举不一致 | 待 HOST 裁决后整体升 v2，本轮不擅改 |
| 10 | alpha / ≤256 色 / 装饰层逐像素抽检 | 无 PNG 无法执行，**不编造校验数据** |
| 11 | 产物落 `godot/assets/generated/chars/` 与 `import.json` 登记 | 出图后步骤；本轮不写 `godot\`、无落位改动 |

---

## 5. 完成标志与合规声明

- **完成标志**：`DONE-R12.md` 已写；已按 `task_id=cmd-20261109-044100-997-A4` 向 `command_center\ai\4\outbox\` **投递** `status=done` 回执，中枢即时回收后权威件在 `command_center\dispatcher\receipts\receipt_cmd-20261109-044100-997-A4.json`（落位经过与真跑输出见 §2.5）。
- **只读边界**：仅 `GET /system_stats`、`GET /object_info`、本地 `json.load`；**未 POST `/prompt`、未出图、未启动第二个 GPU job、未杀/重启旧 job、未写探针 / 未扫盘 / 未重复刺探进程命令行**。
- **唯一可写范围**：`Rank-4\COMFYUI-READINESS.md`、`Rank-4\DONE-R12.md` + 回执例外 `command_center\ai\4\outbox\`；`comfyui_workflow_pixel.json` **保持不动**；未写 `godot\`、总线 / 总纲 / 契约 / 任务书 / 其它工位；未自行 `git commit` / `git push`。
- 零付费 / 零外部依赖；付费 API 一律禁用；`128bit` 待用户确认、不自行改口径；**不伪造输出 / 画面 / 截图 / 安装路径、不宣称已出图**。
- 中文 UTF-8；本文件代码块一律 `text` 标记、行首围栏不标注 json；所有独立 JSON 真跑 `json.load` 通过、回执为合法 JSON。

---

## 6. 并发实例复核补记（本实例独立真跑 · 只追加、不改既有内容）

> 开工时 `COMFYUI-READINESS.md` 已由并发实例先写；核对过程中 `DONE-R12.md` 亦由并发实例先写，二者均完整（①交付清单 ②自检实际输出 ③未完成项与阻塞）。按并发保护「不覆盖、不重做、不重复写第二份回执」，本实例仅做独立只读复核并追加本段留痕，**未改动上列既有文件的任何既有内容、未写第二份回执**。

### 6.1 独立真跑实际输出（与 §2 结论一致）

```text
[GET /system_stats]  HTTP_CODE=200 BYTES=1172
  comfyui_version=0.33.2 | argv 不含绝对路径
  vram_total=17175150592 vram_free=8959269586 torch_vram_total=33554432 torch_vram_free=22256338
[GET /object_info]   BYTES=4625272 node_count=2724
  ckpt_len=15 pixelXL_in=True XL_named=3
  lora_len=34 15V_named=['PixelArtRedmond15V-PixelArt-PIXARFK.safetensors'] xl_named=3
  cn_len=19 sd15_count=18
  width_type=INT width_opts={'default':512,'min':16,'max':16384,'step':8,...}
  height_type=INT height_opts={'default':512,'min':16,'max':16384,'step':8,...}
  workflow_nodes_all_exist=True
[本地 JSON 解析]
  独立件 Rank-4/*.json            PASS=11 FAIL=0
  落位件 godot/assets/generated  PASS=4  FAIL=0
  workflow bytes=2529 sha256=98d6d722972137898f391591f8f5d38f265cf25df2ff988b3f2c0723aca82ddd
  node_count=9 SUBJECT_occurrences=1 has_LoraLoader=False has_ControlNetLoader=False
  EmptyLatentImage={'width':512,'height':512,'batch_size':1}
  ImageScale=128x128 nearest-exact | ImageQuantize=colors 256 dither none
  内嵌字段(.md 围栏,以 {/[ 开头) 候选=21 严格JSON_PASS=17 示意文本_FAIL=4
    FAIL 位于 COMFYUI-WORKFLOW.md / DONE-R4.md / R4-验收记录.md（非严格 JSON 的枚举·示意块）
[PNG 只读计数] Rank-4=0 | godot/assets/generated=0
```

- 复核结论：SDXL ckpt 与 SD1.5 系扩展件不兼容、`/object_info` 无「SDXL 需 1024」依据、512 骨架 sha256 未变、GPU 未空闲（~7.65 GiB 被旧 job 占）、真实 PNG=0 —— 与 §2 / §3 及 `COMFYUI-READINESS.md` 全部一致。4 项内嵌 FAIL 为示意文本块（本实例扫描口径），非解析错误、不伪造。

### 6.2 只读核对（Glob 实际结果）

```text
command_center/ai/4/outbox/*      : No files found（空）
Rank-4/**/*.png                   : No files found
godot/**/*.png                    : No files found
Rank-4/asset_proof*               : 仅 asset_proof_stdout.txt（内容为空）；未见 asset_proof_stderr.log
godot/scripts/render/*.gd         : hd2d_placeholder.gd / hd2d_placeholder_attach.gd 等 5 个 .gd 均在
D:/Godot/Godot_v4.7.2-stable_win64.exe : 存在
```

### 6.3 回执核实（不重复写第二份）

```text
dispatcher/receipts/receipt_cmd-20261109-044100-997-A4.json : 存在
task_id=cmd-20261109-044100-997-A4 | ai=4 | status=done
result 引用 DONE-R12.md 实际结论=True | json.load OK
```

- 回执已由并发实例投递、经中枢回收到 `dispatcher/receipts/`（与 `DONE-R11.md` §2.7 既定行为一致），字段与派单 id 完全一致、合法 JSON。按并发保护「不重复写第二份回执」，本实例**未再写**；outbox 为空属回收后正常状态，不伪造「outbox 稳定留存」。

### 6.4 未实测项（如实登记）

- 两段占位 `.gd` 引擎门禁 `--check-only --script`：**未实测**。原因：`任务书-R12.md`（本轮唯一执行依据）§交付 / §边界 / §完成标志均未要求该门禁，用户清单亦标注「若任务书要求」；本轮为兼容性核验与就绪报告，按最小交付不擅自扩大动作。仅只读核对两段 `.gd` 与 Godot exe 存在（§6.2）。
- `asset_proof_stderr.log`：只读 Glob 未见该文件（仅 `asset_proof_stdout.txt` 空文件），如实登记、不臆造日志内容。
