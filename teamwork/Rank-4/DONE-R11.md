# DONE-R11.md · R11 完成报告（Rank-4 美术管线与工具链）

> 轮次：**R11（ComfyUI 主路线 API 工作流骨架落地）**｜派单：`cmd-20261109-042711-618-A4`｜工位：Rank-4｜结论：**done**
> 本轮定位：把本机 ComfyUI 主路线的**可调用 API 工作流骨架**落地。**本轮不实际出图**：未 POST `/prompt`、未启动第二个 GPU job、未杀 / 未重启现有单一 `qwen-image` job。
> 只读范围：`GET /system_stats`、`GET /object_info`、本地 `json.load`；`00-群聊总线.md` 开工只读一次；默认不刺探。
> 所有 curl 均为 **GET**；所有 JSON 均内联真跑 `json.load` 解析；以下 §2 全部为**实际 stdout 原样**，未加工、未补造。

---

## 1. 实际交付清单

| # | 文件 | 动作 | 实际内容 |
|---|---|---|---|
| 1 | `teamwork\Rank-4\comfyui_workflow_pixel.json` | **新建** | 可 POST `/prompt` 的 **9 节点（8 类）** API 工作流骨架，顶层即完整请求体 `{"prompt": {...}}`；节点名与每个节点必需输入键 100% 取自真实 `GET /object_info` |
| 2 | `teamwork\Rank-4\COMFYUI-WORKFLOW.md` | **新建** | 11 节接入说明：端点 / 版本、节点清单与实测存在性、128px 口径、固定 Prompt 骨架只换 `[SUBJECT]`、seed 锁定、与 `qwen-image` 备选及 `_draw()` 兜底的三层关系、安装目录未确认原因、未完成项 |
| 3 | `teamwork\Rank-4\import.json` | **定点更新** | 新增 `pipeline` 对象指向 ComfyUI 主路线；保留 `fallback_route=procedural_draw_placeholder`；31 → 32 键；其余字段逐字未动 |
| 4 | `godot\assets\generated\import.json` | **定点更新** | 同上；与工位版**逐键一致**（真跑 `True`） |
| 5 | `teamwork\Rank-4\DONE-R11.md` | **新建** | 本文件（① 交付清单 ② 自检含只读验证输出 ③ 未完成项与阻塞） |
| 6 | `teamwork\command_center\ai\4\outbox\` 回执 JSON（投递口）→ 中枢回收至 `teamwork\command_center\dispatcher\receipts\receipt_cmd-20261109-042711-618-A4.json` | **新建** | `task_id=cmd-20261109-042711-618-A4` / `ai=4` / `status=done`；投递当时两处内容 sha256 一致（落位经过见 §2.7） |

**链路（任务书指定，逐节点落地）**：
`CheckpointLoaderSimple` → `CLIPTextEncode`(正) / `CLIPTextEncode`(负) → `EmptyLatentImage` → `KSampler` → `VAEDecode` → `ImageScale`(128px 基准) → `ImageQuantize`(≤256 色) → `SaveImage`。

**「不存在的节点改用实际可用节点并说明」**：经 `GET /object_info` 逐个核对，**8 类节点全部真实命中，无缺失**，因此**未发生任何节点替换**，无需替代说明。`ImageQuantize`（`image/filters`）是本机真实存在的自定义节点，正好承担 ≤256 色收敛。

**未写**：`project.godot`、`scenes\`、其它工位、总线 / 总纲 / 契约 / 任务书；未自行 `git commit` / `git push`。既有件（`prompt_skeleton.json`、`ART-SPEC-FINAL.md`、`I5-DELIVERY-CHECKLIST.md`、`HD-2D视觉规范.md`、`资产交付契约.md`、`palette_256.json` 等）一律引用、不重做。

---

## 2. 自检（只读真跑 · 实际输出）

### 2.1 服务状态：`curl -s http://127.0.0.1:8188/system_stats`（HTTP 200，实际 stdout）

```text
{"system": {"os": "win32", "ram_total": 34185449472, "ram_free": 17141133312, "comfyui_version": "0.33.2", "required_frontend_version": "1.49.6", "installed_templates_version": "0.11.43", "required_templates_version": "0.11.43", "comfy_package_versions": [{"name": "comfyui-frontend-package", "installed": "1.49.6", "required": "1.49.6"}, {"name": "comfyui-workflow-templates", "installed": "0.11.43", "required": "0.11.43"}, {"name": "comfyui-embedded-docs", "installed": "0.5.9", "required": "0.5.9"}, {"name": "comfy-kitchen", "installed": "0.2.31", "required": "0.2.31"}, {"name": "comfy-aimdo", "installed": "0.4.13", "required": "0.4.13"}], "python_version": "3.12.9 (tags/v3.12.9:fdb8142, Feb  4 2025, 15:27:58) [MSC v.1942 64 bit (AMD64)]", "pytorch_version": "2.9.1+cu130", "embedded_python": false, "deploy_environment": "local-git", "argv": ["main.py", "--listen", "127.0.0.1", "--port", "8188", "--cuda-device", "0", "--disable-auto-launch"]}, "devices": [{"name": "cuda:0 NVIDIA GeForce RTX 4060 Ti : cudaMallocAsync", "type": "cuda", "index": 0, "vram_total": 17175150592, "vram_free": 8959269586, "torch_vram_total": 33554432, "torch_vram_free": 22256338}]}
```

> 实测：ComfyUI `0.33.2`、frontend `1.49.6`、PyTorch `2.9.1+cu130`、Python `3.12.9`、RTX 4060 Ti（≈16 GB）。`argv` **不含安装绝对路径**（见 §3 第 6 项）。

### 2.2 节点存在性与必需输入键：`curl -s http://127.0.0.1:8188/object_info | python -c ...`（实际 stdout）

```text
=== python ===
Python 3.13.14
=== GET /object_info -> 逐节点存在性/必需键核对 ===
TOTAL_NODES 2724
=== CheckpointLoaderSimple ===
  display_name: CheckpointLoaderSimple | category: model/loaders
  required_keys: ['ckpt_name']
  optional_keys: []
  output: ['MODEL', 'CLIP', 'VAE'] | output_name: ['MODEL', 'CLIP', 'VAE']
=== CLIPTextEncode ===
  display_name: CLIPTextEncode | category: model/conditioning
  required_keys: ['text', 'clip']
  optional_keys: []
  output: ['CONDITIONING'] | output_name: ['CONDITIONING']
=== EmptyLatentImage ===
  display_name: EmptyLatentImage | category: model/latent
  required_keys: ['width', 'height', 'batch_size']
  optional_keys: []
  output: ['LATENT'] | output_name: ['LATENT']
=== KSampler ===
  display_name: KSampler | category: model/sampling
  required_keys: ['model', 'seed', 'steps', 'cfg', 'sampler_name', 'scheduler', 'positive', 'negative', 'latent_image', 'denoise']
  optional_keys: []
  output: ['LATENT'] | output_name: ['LATENT']
=== VAEDecode ===
  display_name: VAEDecode | category: model/latent
  required_keys: ['samples', 'vae']
  optional_keys: []
  output: ['IMAGE'] | output_name: ['IMAGE']
=== ImageScale ===
  display_name: ImageScale | category: image/upscaling
  required_keys: ['image', 'upscale_method', 'width', 'height', 'crop']
  optional_keys: []
  output: ['IMAGE'] | output_name: ['IMAGE']
=== ImageQuantize ===
  display_name: ImageQuantize | category: image/filters
  required_keys: ['image', 'colors', 'dither']
  optional_keys: []
  output: ['IMAGE'] | output_name: ['IMAGE']
=== SaveImage ===
  display_name: SaveImage | category: image
  required_keys: ['images', 'filename_prefix']
  optional_keys: []
  output: ['IMAGE'] | output_name: ['images']
```

> 8 类节点全部命中、均无 `optional_keys`；工作流每个节点的 `inputs` 键集合与上表 `required_keys` **逐键相等**（见 2.5 [C]）。

### 2.3 required 定义详情：`curl -s .../object_info | python -c ...`（实际 stdout，长值按 500 字符截断显示，完整枚举另见 2.4）

```text
=== GET /object_info -> 关键节点 required 定义详情（枚举/默认/类型） ===
=== ImageQuantize REQUIRED_DETAIL ===
  image = ["IMAGE", {}]
  colors = ["INT", {"default": 256, "min": 1, "max": 256, "step": 1}]
  dither = ["COMBO", {"multiselect": false, "options": ["none", "floyd-steinberg", "bayer-2", "bayer-4", "bayer-8", "bayer-16"]}]
=== ImageScale REQUIRED_DETAIL ===
  image = ["IMAGE"]
  upscale_method = [["nearest-exact", "bilinear", "area", "bicubic", "lanczos"]]
  width = ["INT", {"default": 512, "min": 0, "max": 16384, "step": 1}]
  height = ["INT", {"default": 512, "min": 0, "max": 16384, "step": 1}]
  crop = [["disabled", "center"]]
=== KSampler REQUIRED_DETAIL ===
  model = ["MODEL", {"tooltip": "The model used for denoising the input latent."}]
  seed = ["INT", {"default": 0, "min": 0, "max": 18446744073709551615, "control_after_generate": true, "tooltip": "The random seed used for creating the noise."}]
  steps = ["INT", {"default": 20, "min": 1, "max": 10000, "tooltip": "The number of steps used in the denoising process."}]
  cfg = ["FLOAT", {"default": 8.0, "min": 0.0, "max": 100.0, "step": 0.1, "round": 0.01, "tooltip": "The Classifier-Free Guidance scale balances creativity and adherence to the prompt. Higher values result in images more closely matching the prompt however too high values will negatively impact quality."}]
  sampler_name = [["euler", "euler_cfg_pp", "euler_ancestral", "euler_ancestral_cfg_pp", "heun", "heunpp2", "exp_heun_2_x0", "exp_heun_2_x0_sde", "dpm_2", "dpm_2_ancestral", "lms", "dpm_fast", "dpm_adaptive", "dpmpp_2s_ancestral", "dpmpp_2s_ancestral_cfg_pp", "dpmpp_sde", "dpmpp_sde_gpu", "dpmpp_2m", "dpmpp_2m_cfg_pp", "dpmpp_2m_sde", "dpmpp_2m_sde_gpu", "dpmpp_2m_sde_heun", "dpmpp_2m_sde_heun_gpu", "dpmpp_3m_sde", "dpmpp_3m_sde_gpu", "ddpm", "lcm", "ipndm", "ipndm_v", "deis", "res_multistep", "res_multistep_cfg
  scheduler = [["simple", "sgm_uniform", "karras", "exponential", "ddim_uniform", "beta", "normal", "linear_quadratic", "kl_optimal"], {"tooltip": "The scheduler controls how noise is gradually removed to form the image."}]
  positive = ["CONDITIONING", {"tooltip": "The conditioning describing the attributes you want to include in the image."}]
  negative = ["CONDITIONING", {"tooltip": "The conditioning describing the attributes you want to exclude from the image."}]
  latent_image = ["LATENT", {"tooltip": "The latent image to denoise."}]
  denoise = ["FLOAT", {"default": 1.0, "min": 0.0, "max": 1.0, "step": 0.01, "tooltip": "The amount of denoising applied, lower values will maintain the structure of the initial image allowing for image to image sampling."}]
=== CheckpointLoaderSimple REQUIRED_DETAIL ===
  ckpt_name = [["analogMadness_v60.safetensors", "anything-v5-PrtRE.safetensors", "cardosAnime_v20.safetensors", "cyberrealistic_v40.safetensors", "juggernautXL_version6Rundiffusion.safetensors", "ltx-video-2b-v0.9.safetensors", "majicMIX realistic 麦橘写实_v7.safetensors", "majicmixRealistic_v7.safetensors", "photo2chara_V12-000180.safetensors", "photo2chara_V13_BG-000180.safetensors", "pixelArtDiffusionXL_spriteShaper.safetensors", "qwen_3_8b_fp8mixed.safetensors", "rundiffusionXL_beta.safetensors", "sdpose_who
=== EmptyLatentImage REQUIRED_DETAIL ===
  width = ["INT", {"default": 512, "min": 16, "max": 16384, "step": 8, "tooltip": "The width of the latent images in pixels."}]
  height = ["INT", {"default": 512, "min": 16, "max": 16384, "step": 8, "tooltip": "The height of the latent images in pixels."}]
  batch_size = ["INT", {"default": 1, "min": 1, "max": 4096, "tooltip": "The number of latent images in the batch."}]
=== CLIPTextEncode REQUIRED_DETAIL ===
  text = ["STRING", {"multiline": true, "dynamicPrompts": true, "tooltip": "The text to be encoded."}]
  clip = ["CLIP", {"tooltip": "The CLIP model used for encoding the text."}]
=== VAEDecode REQUIRED_DETAIL ===
  samples = ["LATENT", {"tooltip": "The latent to be decoded."}]
  vae = ["VAE", {"tooltip": "The VAE model used for decoding the latent."}]
=== SaveImage REQUIRED_DETAIL ===
  images = ["IMAGE", {"tooltip": "The images to save."}]
  filename_prefix = ["STRING", {"default": "ComfyUI", "tooltip": "The prefix for the file to save. This may include formatting information such as %date:yyyy-MM-dd% or %Empty Latent Image.width% to include values from nodes."}]
```

### 2.4 枚举值精确核对（消除 2.3 的 500 字符截断风险，实际 stdout）

```text
=== 枚举值精确核对（只读 GET /object_info） ===
ckpt_name options count: 15
ckpt target exists: True
pixel-ish ckpts: ['pixelArtDiffusionXL_spriteShaper.safetensors']
sampler_name count: 44 | euler_ancestral exists: True
scheduler options: ['simple', 'sgm_uniform', 'karras', 'exponential', 'ddim_uniform', 'beta', 'normal', 'linear_quadratic', 'kl_optimal'] | normal exists: True
upscale_method options: ['nearest-exact', 'bilinear', 'area', 'bicubic', 'lanczos'] | nearest-exact exists: True
crop options: ['disabled', 'center'] | disabled exists: True
dither options: ['none', 'floyd-steinberg', 'bayer-2', 'bayer-4', 'bayer-8', 'bayer-16'] | none exists: True
colors bounds: {'default': 256, 'min': 1, 'max': 256, 'step': 1}
EmptyLatentImage width bounds: {'default': 512, 'min': 16, 'max': 16384, 'step': 8, 'tooltip': 'The width of the latent images in pixels.'}
```

### 2.5 最终自检：`GET /object_info` + 内联 `json.load`（实际 stdout，**本轮权威自检**）

```text
=== R11 最终只读自检：GET /object_info + 内联 json.load（不 POST /prompt） ===
[A] JSON_LOAD
  workflow -> dict keys=1
  import_r4 -> dict keys=32
  import_gen -> dict keys=32
  prompt_skeleton -> dict keys=20
[B] TOP_LEVEL
  top keys: ['prompt']
  node count: 9
[C] NODE_CHECK (class_type + required keys + link indices)
  node 1 CheckpointLoaderSimple required_ok=True req=['ckpt_name'] links=[]
  node 2 CLIPTextEncode required_ok=True req=['text', 'clip'] links=['clip->1:1/3']
  node 3 CLIPTextEncode required_ok=True req=['text', 'clip'] links=['clip->1:1/3']
  node 4 EmptyLatentImage required_ok=True req=['width', 'height', 'batch_size'] links=[]
  node 5 KSampler required_ok=True req=['model', 'seed', 'steps', 'cfg', 'sampler_name', 'scheduler', 'positive', 'negative', 'latent_image', 'denoise'] links=['model->1:0/3', 'positive->2:0/1', 'negative->3:0/1', 'latent_image->4:0/1']
  node 6 VAEDecode required_ok=True req=['samples', 'vae'] links=['samples->5:0/1', 'vae->1:2/3']
  node 7 ImageScale required_ok=True req=['image', 'upscale_method', 'width', 'height', 'crop'] links=['image->6:0/1']
  node 8 ImageQuantize required_ok=True req=['image', 'colors', 'dither'] links=['image->7:0/1']
  node 9 SaveImage required_ok=True req=['images', 'filename_prefix'] links=['images->8:0/1']
  ALL_NODES_OK True
[D] ENUM_CHECK
  ckpt in options: True
  sampler in options: True
  scheduler in options: True
  upscale_method in options: True
  crop in options: True
  dither in options: True
  colors 256 within bounds: True
  latent width 512 within bounds: True
[E] PROMPT_VERBATIM
  positive verbatim: True
  negative verbatim: True
  [SUBJECT] in positive count: 1
  [SUBJECT] in whole workflow JSON count: 1
[F] SEED_LOCK
  KSampler seed: 20261108 | base_seed: 20261108 | equal: True
[G] IMPORT_JSON
  key-by-key equal: True
  key count: 32
  pipeline: {"comfyui_endpoint": "http://127.0.0.1:8188", "comfyui_version": "0.33.2", "primary_route": "comfyui_local_api_workflow", "workflow_json": "comfyui_workflow_pixel.json"}
  fallback_route: procedural_draw_placeholder | preserved: True
  pipeline_tier unchanged: D
[H] PIXEL_SPEC
  ImageScale width/height: 128 128
  ImageQuantize colors <= 256: True
[I] NO_POST
  check = GET /object_info + local json.load only; POST /prompt NOT called
```

### 2.6 自检结论汇总

| 检查项 | 实际结论 |
|---|---|
| `json.load` 内联解析 | 4 份 JSON 全部成功：`workflow`=dict(1)、两份 `import.json`=dict(32)、`prompt_skeleton`=dict(20) |
| 顶层结构 | `top keys=['prompt']`、9 个节点，与任务书 9 节点链路一致 |
| 节点存在性 | 8/8 类命中 `object_info`（共 2724 节点），**无缺失、无替换** |
| 必需输入键 | **9/9 节点 `required_ok=True`，`ALL_NODES_OK=True`**（键集合与 `object_info` 逐键相等、无多余键） |
| 连线索引 | 全部落在上游 `output` 范围内（MODEL/CLIP/VAE = 0/1/2，其余单输出 = 0） |
| 枚举 / 边界合法 | `ckpt` / `sampler` / `scheduler` / `upscale_method` / `crop` / `dither` 全 `True`；`colors=256 ∈ [1,256]`、`latent=512 ∈ [16,16384]` |
| 固定 Prompt 骨架 | `positive verbatim=True`、`negative verbatim=True`（逐字取自 `prompt_skeleton.json`）；`[SUBJECT]` 全工作流 JSON **仅 1 处** |
| seed 锁定 | `KSampler.seed=20261108 == seed_lock.base_seed` |
| 两份 `import.json` | **逐键一致 `True`**、32 键；`pipeline.primary_route=comfyui_local_api_workflow`；`fallback_route` 保留；`pipeline_tier=D` 未改 |
| 像素规格 | `ImageScale=128×128`、`ImageQuantize colors≤256` |
| **未出图 / 未 POST** | 自检仅 `GET /object_info` + 本地 `json.load`；**`POST /prompt` 未调用**、未启动第二个 GPU job、未杀 / 未重启 `qwen-image` job |

> 补充：2.5 [A] 中 `workflow -> dict keys=1` 指顶层只有 `prompt` 一个键（其值为 9 节点字典），不是「只有 1 个节点」；`node count: 9` 已单独确认。

### 2.7 收尾复核：全部 JSON 内联 `json.load` + 回执落位（实际 stdout）

> 首次收尾复核因 `outbox` 回执被中枢即时回收而报 `FileNotFoundError`（真实输出，非伪造失败）；改以中枢权威回收件为准重跑，全绿。回执落位经过见本节末。
> 注：下方 `[FINAL] MD_FENCE_CHECK` / `DELIVERABLE_FILES` 的行数与字节数为该次复核执行时刻的快照；本文件随后补写 §2.7 与 §4 登记，行数会增加，属正常追加，不影响结论。

```text
=== R11 收尾复核（不依赖 outbox；纯本地 json.load，不联网、不 POST） ===
[FINAL] JSON_LOAD_ALL
  workflow OK type=dict
  import_r4 OK type=dict
  import_gen OK type=dict
  prompt_skeleton OK type=dict
  receipt_dispatcher OK type=dict
[FINAL] RECEIPT_FIELDS
  task_id: cmd-20261109-042711-618-A4
  ai: 4 | status: done
  result chars: 795
  task_id matches dispatch: True
  authoritative receipt exists: True
  outbox receipt still present: False (collected by dispatcher)
[FINAL] MD_FENCE_CHECK
  COMFYUI-WORKFLOW.md lines=187 leading_json_fences=[]
  DONE-R11.md lines=244 leading_json_fences=[]
[FINAL] DELIVERABLE_FILES
  Rank-4/comfyui_workflow_pixel.json bytes=2529
  Rank-4/COMFYUI-WORKFLOW.md bytes=17774
  Rank-4/import.json bytes=2554
  Rank-4/DONE-R11.md bytes=19523
  generated/import.json bytes=2554
  dispatcher/receipt bytes=1342
[FINAL] IMPORT_EQUAL
  equal: True
```

**回执落位如实登记（不伪造「outbox 中稳定存在」）**：

```text
投递 #1：Write 到 ai/4/outbox/ → 实际落到 dispatcher/receipts/receipt_cmd-20261109-042711-618-A4.json
投递 #2：cp 补齐 ai/4/outbox/ → 立即被中枢回收，outbox 再次为空
两处内容曾一致：sha256 78edffd97772d9d861288a71e668b24fc4f90a3245d2a31b2bf09ed623a9c7fc（两路径相同）
最终权威件：teamwork/command_center/dispatcher/receipts/receipt_cmd-20261109-042711-618-A4.json（status=done，task_id 与派单一致）
历史惯例：dispatcher/receipts/ 下 receipt_R2~R10_A4 / receipt_R11_A1 等均在，ai/N/outbox/ 长期为空 → 中枢即时回收为既定行为
```

> 结论：已按任务书要求向 `command_center\ai\4\outbox\` **投递** `status=done` 回执；中枢即时回收后权威件落在 `dispatcher\receipts\`，内容 / `task_id` / `status` 均正确且与派单一致，两处曾逐字节相同。不反复重投、不宣称 outbox 稳定留存。

---

## 3. 未完成项与阻塞（只登记，不擅改）

| # | 项 | 状态 / 原因 |
|---|---|---|
| 1 | **实际出图** | **本轮按硬性边界不做**：无 PNG、不宣称已能出图；POST `/prompt` 须 HOST 明确授权且 GPU 空闲后执行。骨架已就绪但未运行 |
| 2 | 现有单一 `qwen-image` job | 长期阻塞：约 3 小时停在 `Loading checkpoint shards 50%`、无 PNG、stdout 0 字节；**不杀 / 不重启 / 不并行、不拉起第二个 GPU job** |
| 3 | `ckpt` 与 SD15 系 ControlNet / LoRA / IPAdapter / LayerDiffuse 配套兼容性 | **未实测**：骨架 `ckpt_name` 取 `object_info` 枚举中唯一像素风 XL 模型 `pixelArtDiffusionXL_spriteShaper.safetensors`，而 `prompt_skeleton` 冻结的扩展配置为 SD15 系；后续接入扩展节点时须核对兼容性或改选 SD1.5 checkpoint，本轮不擅自裁决 |
| 4 | `usage_notes[3]` 的 lora trigger 追加 | **未落到骨架文本**：链路无 `LoraLoader`（R11 指定的 9 节点最小链路），追加会改动骨架文本且无对应节点；留待扩展轮次，不伪造已完成 |
| 5 | `128bit` 确切含义 | 待用户确认（画布尺寸 vs 位宽 / 色深）；暂按 **128px 基准画布**理解，`ImageScale` 取 128×128；不改交付端 32×32 单帧与 640×360 渲染缓冲 |
| 6 | **ComfyUI 安装目录** | **未确认**：`/system_stats` 的 `argv` 不含绝对路径；通过进程命令行（`wmic` / `Get-CimInstance Win32_Process.CommandLine` 一类）查询**被本机安全策略阻止**，**未绕过、未重试、未改走其它通道**。API 端点 `http://127.0.0.1:8188` 已足够接入，安装目录非本轮交付前置 |
| 7 | `seed_lock.action_offset` 与 R2 冻结枚举不一致 | `ART-SPEC-FINAL.md` §6 第 5 项已登记为待回改（须 HOST 裁决后整体升 v2），本轮不擅改 |
| 8 | 真实 PNG = 0 | `alpha` 通道 / ≤256 色收敛 / 装饰 RGBA 与 base 逐像素对齐抽检**无对象、无法执行**，不编造校验数据 |

---

## 4. 完成标志与合规声明

- **完成标志**：`DONE-R11.md` 已写；已按 `task_id=cmd-20261109-042711-618-A4` 向 `command_center\ai\4\outbox\` **投递** `status=done` 回执，中枢即时回收后权威件在 `command_center\dispatcher\receipts\receipt_cmd-20261109-042711-618-A4.json`（`task_id` 与派单一致、`status=done`、`result` 引用本文件实际结论；落位经过与真跑输出见 §2.7）。
- 只写 `Rank-4\`（4 件）+ `godot\assets\generated\import.json` + 回执例外；**未写** `project.godot`、`scenes\`、其它工位、总线 / 总纲 / 契约 / 任务书；未自行 `git commit` / `git push`。
- **默认不刺探**：只有任务明确要求的只读核对（`GET /system_stats`、`GET /object_info`、本地 `json.load`、确认回执目录）；未扫盘、未轮询、未写探针 / 测量 / preflight 脚本、未重复查询进程命令行。
- 零付费 / 零外部依赖；付费 API 一律禁用；`stable-audio`（gated 403）/ `gen3d` / `mia-rig` 不申请、不补装、不碰 WSL、不绕过。
- **ComfyUI 仍是主美术路线**；`qwen-image` 仅本地零付费备选（长期阻塞）；程序化 `_draw()` 为零外部依赖兜底，不宣称占位为正式素材。
- 中文 UTF-8；所有独立 JSON 合法可解析；本文档代码块一律 `text` 标记、**不含行首 ```json 围栏**（与 `ART-SPEC-FINAL.md` / `I5-DELIVERY-CHECKLIST.md` / `DONE-R9.md` 一贯做法一致）。
- **最重要**：不 POST `/prompt`、不启动第二个 GPU job、不伪造输出 / 画面 / 截图、不宣称已出图、不臆造 ComfyUI 安装路径、不夸大纹理级导入已生效。
