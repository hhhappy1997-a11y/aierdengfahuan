# COMFYUI-READINESS.md · R12 ComfyUI 出图就绪核验报告（Rank-4）

> 轮次：**R12（ComfyUI 出图就绪核验）**｜派单：`cmd-20261109-044100-997-A4`｜工位：Rank-4 美术管线与工具链
> 定位：**只读核验**，产出「出图前的兼容性结论 + 就绪清单 + 一键命令 + 验收口径」。**本轮绝不实际出图**：绝不 POST `/prompt`、绝不启动第二个 GPU job、绝不杀/重启旧 job。
> 口径来源：`任务书-R12.md`、`comfyui_workflow_pixel.json`、`COMFYUI-WORKFLOW.md`（R11）、`00-工具链接入说明.md` §6/§7、`00-群聊总线.md`（开工只读一次）、`prompt_skeleton.json`，以及本轮 `GET /system_stats` / `GET /object_info` / 本地 `json.load` 真跑。
> 既有件一律引用、不重做、不擅改；`128bit` 仍待用户确认、不自行改口径；零付费 / 零外部依赖；默认不刺探；中文 UTF-8。

---

## 0. 一句话结论

**就绪判定：未就绪，不放行出图。** 三条硬结论：

1. **不兼容**：`pixelArtDiffusionXL_spriteShaper.safetensors` 是 **SDXL 系** checkpoint，而 `prompt_skeleton.json` 冻结的 LoRA / ControlNet / IPAdapter / LayerDiffuse **全部是 SD1.5 系**，二者架构不兼容、不能配套加载。但**当前 9 节点最小骨架不含任何这些扩展节点**，故「骨架本身」不受此冲突影响、仍是可提交的合法链路；冲突只在「按冻结骨架补齐扩展件」时兑现。
2. **骨架不动**：`EmptyLatentImage` 512×512 对 SDXL 有低于训练分辨率的结构性影响，但 `/object_info` 只给出 `{default:512, min:16, max:16384, step:8}` 的**参数元信息**，**未提供「SDXL checkpoint 需 1024」的任何映射或推荐值**，不构成任务书要求的「明确 `/object_info` 依据」。按「除非有 `/object_info` 依据否则不改骨架」，`comfyui_workflow_pixel.json` **保持不动**（before == after）。
3. **GPU 未空闲**：本轮 `GET /system_stats` 复核 `vram_free=8959269586 / vram_total=17175150592`，约 **7.65 GiB** 被外部旧 `qwen-image` job 持有；而 `torch_vram_total=33554432`（仅 32 MiB）说明 ComfyUI 自身并未在跑 GPU job。按「一次只跑一个 GPU job」硬约束，**不并行、不 POST**。

本轮零出图、零 PNG、零 POST、零落位改动、零 JSON 改动。

---

## 1. 只读核验实际输出（本轮真跑，非推测、非伪造）

### 1.1 `GET http://127.0.0.1:8188/system_stats`（04:41 复核）

```text
comfyui_version = 0.33.2
required_frontend_version = 1.49.6
pytorch_version = 2.9.1+cu130
argv = ['main.py', '--listen', '127.0.0.1', '--port', '8188', '--cuda-device', '0', '--disable-auto-launch']
device_count = 1
device[0] name=cuda:0 NVIDIA GeForce RTX 4060 Ti : cudaMallocAsync vram_total=17175150592 vram_free=8959269586 torch_vram_total=33554432 torch_vram_free=22256338
```

- 与 04:39 实测一致：`0.33.2`、`17175150592`（≈16 GiB）、`8959269586`；`argv` 不含安装绝对路径（进程命令行查询被安全策略阻止，R11 已登记，本轮未重复刺探、未绕过）。
- **新增只读证据**：`torch_vram_total=33554432`（32 MiB）≈ 空转量级 → ComfyUI 的 PyTorch 当前**没有**正在执行的 GPU job；整机差额 `17175150592 − 8959269586 = 8215801006` 字节 ≈ **7.65 GiB**（≈8.2 GB 十进制）由**外部独立进程**持有，即旧 `qwen-image` job。此条是 §4「GPU 空闲判定」与 §6「为何不并行」的硬依据。

### 1.2 `GET http://127.0.0.1:8188/object_info`（针对性提取，未落盘、未拉全量 2724 节点刷屏）

```text
node_count = 2724
CheckpointLoaderSimple.ckpt_name : list len=15
    count sdxl/xl-named = 3
    count sd15/15v/v1-named = 2
      - analogMadness_v60.safetensors
      - anything-v5-PrtRE.safetensors
      - cardosAnime_v20.safetensors
      - cyberrealistic_v40.safetensors
      - juggernautXL_version6Rundiffusion.safetensors
      - ltx-video-2b-v0.9.safetensors
      - majicMIX realistic 麦橘写实_v7.safetensors
      - majicmixRealistic_v7.safetensors
      - photo2chara_V12-000180.safetensors
      - photo2chara_V13_BG-000180.safetensors
      - pixelArtDiffusionXL_spriteShaper.safetensors
      - qwen_3_8b_fp8mixed.safetensors
      - rundiffusionXL_beta.safetensors
      - sdpose_wholebody_fp16.safetensors
      - svd_xt.safetensors
    opts = {'tooltip': 'The name of the checkpoint (model) to load.'}
LoraLoader.lora_name : list len=34
    count sdxl/xl-named = 3
    count sd15/15v/v1-named = 7
      - PixelArtRedmond15V-PixelArt-PIXARFK.safetensors
      - pixel-art-xl.safetensors
      - sdxl_lightning_4step_lora.safetensors
      - illustriousXLv01_stabilizer_v1.121.safetensors
      （另有 30 项 Wan2.1/2.2、Qwen-Image、Minimax、HunyuanVideo 等视频/编辑模型 LoRA，与 SDXL 无关，略）
ControlNetLoader.control_net_name : list len=19
    count sdxl/xl-named = 1
    count sd15/15v/v1-named = 19
      - control_v11e_sd15_ip2p_fp16.safetensors
      - control_v11e_sd15_shuffle_fp16.safetensors
      - control_v11f1e_sd15_tile_fp16.safetensors
      - control_v11f1p_sd15_depth_fp16.safetensors
      - control_v11p_sd15_canny_fp16.safetensors
      - control_v11p_sd15_inpaint_fp16.safetensors
      - control_v11p_sd15_lineart_fp16.safetensors
      - control_v11p_sd15_mlsd_fp16.safetensors
      - control_v11p_sd15_normalbae_fp16.safetensors
      - control_v11p_sd15_openpose_fp16.safetensors
      - control_v11p_sd15_scribble_fp16.safetensors
      - control_v11p_sd15_seg_fp16.safetensors
      - control_v11p_sd15_softedge_fp16.safetensors
      - control_v11p_sd15s2_lineart_anime_fp16.safetensors
      - illustriousXL_openposev10.safetensors
      （另有 4 项为上述 diffusion_pytorch_model.* 分卷文件，从略）
EmptyLatentImage.width  : type=INT opts={'default': 512, 'min': 16, 'max': 16384, 'step': 8, ...}
EmptyLatentImage.height : type=INT opts={'default': 512, 'min': 16, 'max': 16384, 'step': 8, ...}
--- 工作流骨架 8 类节点存在性 ---
  exists CheckpointLoaderSimple = True / CLIPTextEncode = True / EmptyLatentImage = True / KSampler = True
  exists VAEDecode = True / ImageScale = True / ImageQuantize = True / SaveImage = True
```

- ckpt 15 项中 `pixelArtDiffusionXL_spriteShaper.safetensors` 存在（工作流已采用）；同列表里**也有 SD1.5 系 checkpoint**（`anything-v5-PrtRE`、`cyberrealistic_v40`、`majicMIX ... v7`、`photo2chara_*` 等），是 §2.5 路线 B 的本机依据。
- ControlNet 19 项中 **18 项为 `control_v11*_sd15_*`（SD1.5 系）**，另有 1 项 `illustriousXL_openposev10.safetensors`（Illustrious XL 系，非 `sd15`、也非 `pixelArtDiffusionXL` 配套件，未经真跑不宣称可用）。
- LoRA 34 项中**并非全是 SD1.5 系**：确实存在 `pixel-art-xl.safetensors`、`sdxl_lightning_4step_lora.safetensors`（SDXL 系）与 `illustriousXLv01_stabilizer`（Illustrious 系）；但**冻结骨架引用的 `PixelArtRedmond15V` 属 SD1.5 系**（`15V`）。详见 §2.4 精确化更正。
- **`EmptyLatentImage` 的 `/object_info` 定义只有参数元信息**（INT + default/min/max/step/tooltip），**不含任何「按 checkpoint 推荐分辨率」的字段** → 无改 1024 的硬依据。

### 1.3 本地 JSON 解析（`comfyui_workflow_pixel.json`，改动前基线）

```text
bytes = 2529
sha256 = 98d6d722972137898f391591f8f5d38f265cf25df2ff988b3f2c0723aca82ddd
top_keys = ['prompt']
node_count = 9
node_ids = ['1','2','3','4','5','6','7','8','9']
  node 1 = CheckpointLoaderSimple / 2 = CLIPTextEncode / 3 = CLIPTextEncode
  node 4 = EmptyLatentImage / 5 = KSampler / 6 = VAEDecode
  node 7 = ImageScale / 8 = ImageQuantize / 9 = SaveImage
[SUBJECT]_occurrences_raw = 1   （位于 node 2）
ckpt_name = pixelArtDiffusionXL_spriteShaper.safetensors
EmptyLatentImage inputs = {'width': 512, 'height': 512, 'batch_size': 1}
KSampler seed/steps/cfg/sampler/scheduler/denoise = 20261108 28 7.0 euler_ancestral normal 1.0
ImageScale inputs = {'upscale_method': 'nearest-exact', 'width': 128, 'height': 128, 'crop': 'disabled'}
ImageQuantize inputs = {'colors': 256, 'dither': 'none'}
SaveImage inputs = {'filename_prefix': 'aierdengfahuan_hd2d_r11'}
width/height within object_info range(16..16384,step8) = True
has LoraLoader node = False
has ControlNetLoader node = False
```

### 1.4 本地冻结骨架 `prompt_skeleton.json`（扩展件引用，逐字）

```text
lora_triggers[0].file   = pixel-art-lora.safetensors        （本机 /object_info 34 个 LoRA 中无此名）
controlnet.model        = control_v11p_sd15_openpose.pth     （SD1.5 系）
ip_adapter.model        = ip-adapter_sd15.bin                （SD1.5 系）
layerdiffuse.method     = SD15 Attention Injection (transparent)  （SD1.5 系）
single_slot.count = 1 / occurrences_in_positive = 1
sampling  = steps 28 / cfg 7.0 / euler_ancestral / normal（fixed=true）
seed_lock.base_seed = 20261108，derivation = base + category_offset*10000 + action_offset*100 + frame_index
```

---

## 2. ① SDXL checkpoint 与 SD1.5 系 LoRA / ControlNet 不兼容

### 2.1 结论

`pixelArtDiffusionXL_spriteShaper.safetensors`（**SDXL / XL 系**）与 `prompt_skeleton.json` 冻结的 **4 件 SD1.5 系扩展**（LoRA `pixel-art-lora.safetensors`、ControlNet `control_v11p_sd15_openpose.pth`、IPAdapter `ip-adapter_sd15.bin`、LayerDiffuse `SD15 Attention Injection`）**架构不兼容，不能配套加载**。本机 `/object_info` 中 ControlNet 可用项 **18/19 为 SD1.5 系**，与 XL checkpoint 同样不兼容。

**重要边界**：当前 `comfyui_workflow_pixel.json` 是 **9 节点最小链路**（§1.3 实测 `has LoraLoader node = False`、`has ControlNetLoader node = False`），**不含任何扩展节点**，因此：
- 「骨架本身」是合法、可提交的链路，不受此冲突影响；
- 冲突在「按 `usage_notes[3]` 补 `LoraLoader` / 补 ControlNet / IPAdapter / LayerDiffuse」时才兑现；
- R11 之所以刻意落地 9 节点最小链路，正好规避了尚未裁决的配套兼容性（`COMFYUI-WORKFLOW.md` §4 / §10 第 3 项已把「未实测」登记为未完成项，本轮 R12 将其**收敛为明确的不兼容结论 + 本机清单证据**）。

### 2.2 依据（三层，逐层可核）

| 层 | 依据 | 来源 |
|---|---|---|
| **本机清单实测** | ckpt 名含 `XL`；ControlNet 18/19 名为 `control_v11*_sd15_*`；像素风 LoRA `PixelArtRedmond15V` 名含 `15V`（=SD 1.5）；冻结 ControlNet `control_v11p_sd15_openpose` 对上本机 `control_v11p_sd15_openpose_fp16.safetensors`（SD1.5） | §1.2 `GET /object_info`、§1.4 本地 JSON |
| **本地冻结契约** | `prompt_skeleton.json` 的 `controlnet.model` / `ip_adapter.model` / `layerdiffuse.method` 字段逐字含 `sd15` / `SD15`；`lora_triggers.file` 为 SD1.5 系像素 LoRA | §1.4 本地 JSON 真跑 |
| **架构原理（通用模型知识，非本机实测，仅作机理解释）** | SD1.5 用单一 CLIP ViT-L/14 文本编码（context dim **768**）、UNet ≈0.86B；SDXL 用双编码器（CLIP-L 768 + OpenCLIP ViT-bigG **1280**，拼接 **2048**）并引入 `added_cond_kwargs`（size/crop/time micro-conditioning）、UNet ≈2.6B、transformer depth 与通道数不同。**LoRA** 是针对特定 UNet 线性层（to_q/k/v/out、proj_in/out、ff）训练的低秩矩阵，其 in/out_features 与目标层形状绑定 → 跨架构 key 对不上会静默失效，形状对不上会抛 `size mismatch`。**ControlNet** 是对应 UNet encoder 的逐层通道拷贝，`control_v11*_sd15_*` 的 down-block 通道与 SD1.5 一一对应，无法挂到 SDXL UNet | 通用 Stable Diffusion 架构知识；**不作为「本机已实测」宣称** |

### 2.3 后果

1. **直接后果**：若在 SDXL checkpoint 上挂上述 SD1.5 扩展件，POST `/prompt` 后 `node_errors` 会出现加载/`size mismatch` 类错误，或扩展节点静默不生效（LoRA strength 无效、ControlNet 姿态控制失效、LayerDiffuse 不产 alpha）。结果是**出图报错**或**风格/姿态/透明底锚点全部失效**，`pixel art` 风格与 1px 硬边约束无法保证。
2. **对当前骨架**：无影响（无扩展节点），故本轮**不因为此冲突修改 `ckpt_name`、也不新增扩展节点**。
3. **对出图就绪**：`prompt_skeleton.usage_notes[3]`（提交前追加 lora trigger）与 ControlNet / IPAdapter / LayerDiffuse 接入**全部暂缓**；在裁决前，「完整冻结骨架 + 扩展件」这条链路**不能宣称可出图**。
4. **附带问题（如实登记，不伪造匹配）**：冻结的 `lora_triggers.file = pixel-art-lora.safetensors` 在 `/object_info` 的 34 个 LoRA 候选中**不存在**；本机存在的近似件是 `PixelArtRedmond15V-PixelArt-PIXARFK.safetensors`（SD1.5 系）与 `pixel-art-xl.safetensors`（SDXL 系）。即扩展件接入还存在「冻结引用名 ≠ 本机文件名」的对齐问题，须与架构路线**一并裁决**。

### 2.4 精确化更正（相对 04:39 摘要，如实而非照抄）

| 04:39 摘要 | 本轮 `/object_info` 精确实测 | 处理 |
|---|---|---|
| `LoraLoader.lora_name` 含 `PixelArtRedmond15V...` 等（SD1.5 系） | 34 项中**确实存在 SDXL 系** `pixel-art-xl.safetensors`、`sdxl_lightning_4step_lora.safetensors`，以及大量 Wan / Qwen-Image / Minimax 视频模型 LoRA；**冻结引用的 `PixelArtRedmond15V` 才是 SD1.5 系** | 不笼统写「LoRA 全部 SD1.5 系」，按实测如实分层 |
| `ControlNetLoader.control_net_name` 全部为 `control_v11*_sd15_*` | 19 项中 **18 项**为 `control_v11*_sd15_*`，**1 项**为 `illustriousXL_openposev10.safetensors`（Illustrious XL 系） | 如实写 18/19，并注明该 1 项也非 `pixelArtDiffusionXL` 配套件、未验证 |
| `CheckpointLoaderSimple` 有 SDXL 像素 checkpoint | 15 项同时含 SDXL 系（3 项 XL 命名）与 SD1.5 系 / 其它架构候选 | 补充：本机**有** SD1.5 checkpoint 可供路线 B 改选 |

### 2.5 两条候选路线（只登记，不裁决、不擅改）

| 路线 | 做法 | 本机依据 | 代价 |
|---|---|---|---|
| **A 保 SDXL** | 保留 `pixelArtDiffusionXL_spriteShaper.safetensors`，扩展件**一律改选 SDXL 系**：LoRA 候选 `pixel-art-xl.safetensors` / `sdxl_lightning_4step_lora.safetensors`（名称推断为 SDXL 系、**未经真跑验证与 XL ckpt 的兼容性，不宣称可用**）；ControlNet 需另找标准 SDXL ControlNet（本机 19 项无标准 SDXL 项，仅 1 个 Illustrious 系） | §1.2 | 与冻结 `prompt_skeleton.json` 冲突，须整体升 v2（骨架 `usage_notes[8]` 明令禁止局部热改）；SDXL ControlNet 本机缺件 |
| **B 改 SD1.5 ckpt** | 把 `ckpt_name` 改选本机 SD1.5 checkpoint（如 `anything-v5-PrtRE.safetensors` / `cyberrealistic_v40.safetensors` / `majicMIX realistic ... v7.safetensors`），则冻结的 SD1.5 LoRA / ControlNet / IPAdapter / LayerDiffuse 可直接配套 | §1.2 ckpt 列表 | 失去 `pixelArtDiffusionXL` 这一像素风专用 XL checkpoint；`ckpt_name` 属骨架字段，改动须 HOST 裁决 + 真跑 |

> 两条路线均属**跨轮次、需用户/HOST 裁决 + 真跑验证**的事项，本轮**不执行、不擅改 `ckpt_name`、不新增节点**。

---

## 3. ② `EmptyLatentImage` 512 对 SDXL 的影响与建议（只给建议，不改骨架）

### 3.1 影响机理（通用模型知识，非本机实测）

- `EmptyLatentImage.width/height` 是**像素空间**尺寸，经 VAE 8× 下采样为 latent：512px → **64×64** latent；1024px → **128×128** latent。
- `pixelArtDiffusionXL` 属 SDXL 系，SDXL 在 **≈1024×1024** 分辨率训练，并带 size/crop micro-conditioning。**512×512 低于训练分辨率**，典型影响：构图与比例失真、多肢/多头概率上升、主体偏小、细节与文本条件对齐变差、轮廓可读性下降。
- **本项目缓冲**：链路末端 `ImageScale` nearest-exact → **128×128** + `ImageQuantize` ≤256 色，生成端 512 的细节损失在 4× 降采样与调色板量化后**大部分被吸收**；且 512 的显存/算力约为 1024 的 **1/4**，在 RTX 4060 Ti 16 GiB（当前仅剩 ~8.9 GiB 可用、旧 job 占 ~7.65 GiB）上**更不易 OOM**。因此 512 对本「128px 像素精灵」目标并非不可用，属**质量/显存的权衡**而非硬性错误。

### 3.2 建议（只给建议，本轮不改）

1. **若追 SDXL 结构质量**：出图前把 `EmptyLatentImage` 升到 **1024×1024**（`step=8` 合法、`max=16384` 内），`batch_size` 保持 1；须在 **GPU 空闲、`vram_free` 回到高位**时执行，显存约增至 4×。
2. **折中**：**768×768**（`step=8` 合法），在质量与显存间取中。
3. **A/B 决定**：用户说「出图」后，建议先在 GPU 空闲时对同一 seed 各跑 512 / 1024 一张，按 §5.2 验收口径人眼比对，再定生成分辨率；**收敛到 128px / ≤256 色的下游链路不变**。
4. 上述「SDXL 推荐 1024」是**通用模型知识**，**不是 `/object_info` 实测事实**，仅作建议、**不作为改骨架依据**。

### 3.3 为何本轮不修改骨架（判定依据，对应交付 2）

| 判定项 | 事实 |
|---|---|
| 任务书规则 | 「若确认 SDXL 需要 1024 latent **且有 `/object_info` 依据**，可调整 `EmptyLatentImage`…**否则保持不动并说明**」；用户硬边界「**除非有 `/object_info` 依据否则不改骨架**」 |
| `/object_info` 实测 | `EmptyLatentImage.width/height` 仅 `INT {default:512, min:16, max:16384, step:8, tooltip:...}`，**无任何「按 checkpoint 推荐/要求分辨率」字段**；`default` 本身就是 **512**，512 在合法范围内 |
| 现状 | R11 已逐键验证该 9 节点骨架（`COMFYUI-WORKFLOW.md` §2）；本轮 §1.3 复核 `sha256` 一致、字段合法 |
| 结论 | **无 `/object_info` 依据 → 保持 `comfyui_workflow_pixel.json` 完全不动**；改 1024 属需真跑 A/B + HOST 裁决的调参，留待用户说「出图」后按 §5 执行 |

**改动前后（before == after，无改动）**：`width: 512 → 512`、`height: 512 → 512`；文件 `bytes=2529`、`sha256=98d6d722...` 收尾复核不变（见 `DONE-R12.md` §2）。

---

## 4. ③ 出图前置清单（Checklist，全部满足才放行 POST）

| # | 项 | 放行条件 | 本轮当前状态 | 依据 |
|---|---|---|---|---|
| 1 | **GPU 空闲** | POST 前重跑 `GET /system_stats`：`vram_free` 回到接近 `vram_total`（建议 ≥ ~14 GiB，即旧 job ~7.65 GiB 已释放）；`torch_vram_total` 无异常增长；**整机确认无第二个 GPU job** | ❌ 未满足：`vram_free=8959269586 / 17175150592`，~7.65 GiB 被旧 job 占用 | §1.1、§6、`00-工具链接入说明.md` §5.3 |
| 2 | **`ckpt_name`** | 仍为 `pixelArtDiffusionXL_spriteShaper.safetensors`（SDXL），且**不挂任何 SD1.5 扩展件**；若要接入扩展件，先按 §2.5 裁决路线 A/B | ✅ 骨架内正确；⚠️ 扩展件路线未裁决 → 完整冻结链路不放行 | §1.2 / §1.3 / §2 |
| 3 | **Prompt 骨架单 `[SUBJECT]` 槽** | 整份 JSON 中 `[SUBJECT]` **仅 1 处**（node 2 positive）；只替换为品类内主体名（如 `player_tarnished` / `hollow_soldier` / `grace_site` / `stone_ruins`）；不得写风格/光照/色号/尺寸/在世艺术家/受版权角色名；negative、style、lighting、palette、seed_lock、sampling 冻结不动；`filename_prefix` 不含槽位 | ✅ 实测 `occurrences_raw=1`、位于 node 2；出图时才替换 | §1.3 / §1.4、`prompt_skeleton.json` `single_slot` |
| 4 | **seed** | `KSampler.seed` 按 `seed_lock.derivation` 派生实值覆盖（`base_seed=20261108 + category_offset*10000 + action_offset*100 + frame_index`），并同步写 `import.json::seed` 供复核；装饰层复用 base 层**完全相同** seed；`control_after_generate` 不传、不随机 | ✅ 骨架基准值 `20261108` 合法；实值出图时计算 | §1.3 / §1.4、`COMFYUI-WORKFLOW.md` §6 |
| 5 | **128px / ≤256 色收敛** | `ImageScale` nearest-exact→128×128（`crop=disabled`）、`ImageQuantize` `colors=256` / `dither=none` 保持；交付端再经 downsample / Aseprite 精修到 `32×32` / `16 色` / Point / 锚点 `(16,31)`；**`128bit` 确切含义仍待用户确认，暂按 128px 基准画布、不自行改口径** | ✅ 骨架字段已就位；⏸ `128bit` 待确认 | §1.3、`00-工具链接入说明.md` §6、`ART-SPEC-FINAL.md` |
| 6 | **产物落地** | 出图后把 `SaveImage` 产物从 ComfyUI `output/` **取回并落到 `godot/assets/generated/chars/`**，登记 `import.json`（来源 / schema_version / seed / 版本号）；当前 `filename_prefix=aierdengfahuan_hd2d_r11` | ⏸ 出图后步骤；**本轮不写 `godot\`、无落位改动** | `任务书-R12.md` 唯一可写范围、`prompt_skeleton.json` `usage_notes[7]` |
| 7 | **边界与合规** | 全程仅 **1 个 GPU job**；不杀/不重启旧 job；零付费 / 零外部依赖；JSON 合法；不写总线/总纲/契约/其它工位；不自行 git | ✅ 本轮全程遵守 | `任务书-R12.md` 边界、`00-协作契约.md` |

> **总闸**：第 1 项（GPU 空闲）为硬前置；第 2 项的「扩展件路线裁决」决定是走「9 节点最小骨架」还是「完整冻结骨架 + 扩展件」。本轮两项均未放行，**不 POST、不出图**。

---

## 5. ④ 用户说「出图」后的一键命令与验收口径

> 以下为**说明性命令，本轮未执行、不代表已出图**。执行前必须先过 §4 全部前置项，尤其 GPU 空闲与 §2.5 路线裁决。

### 5.1 一键命令（零落盘：内存替换 `[SUBJECT]` 与 seed 后直接 POST）

```text
# 0) 前置：GPU 空闲复核（只读，必须满足 §4 第 1 项）
curl -s http://127.0.0.1:8188/system_stats | python -c "import sys,json; d=json.load(sys.stdin); v=d['devices'][0]; print('vram_free',v['vram_free'],'/',v['vram_total'],'torch_vram_total',v.get('torch_vram_total'))"

# 1) 一键出图：读骨架 -> 只替换唯一 [SUBJECT] -> 写入派生 seed -> POST /prompt
#    SUBJECT 与 seed 为示例占位，实际按品类/动作/帧代入（seed 公式见 §4 第 4 项）
python -c "import json,sys
d=json.load(open(r'F:/Game/aierdengfahuan/teamwork/Rank-4/comfyui_workflow_pixel.json',encoding='utf-8'))
d['prompt']['2']['inputs']['text']=d['prompt']['2']['inputs']['text'].replace('[SUBJECT]','player_tarnished')
d['prompt']['5']['inputs']['seed']=20261108+1*10000+1*100+0
json.dump(d,sys.stdout,ensure_ascii=False)" \
| curl -s -X POST -H "Content-Type: application/json" --data-binary @- http://127.0.0.1:8188/prompt

# 2) 取回产物（用上一步返回的 prompt_id）
curl -s http://127.0.0.1:8188/history/<prompt_id>
#    再将 SaveImage 输出 PNG 落到 godot/assets/generated/chars/ 并登记 import.json（§4 第 6 项）
```

- 顶层即完整请求体 `{"prompt": {...}}`，可直接 POST；若下游要 ComfyUI「Export (API)」纯工作流字典，取顶层 `.prompt`（`COMFYUI-WORKFLOW.md` §1）。
- **切勿原样 POST 未替换的骨架**：`positive` 含字面 `[SUBJECT]` 会污染提示词；必须先做唯一槽位替换。
- 一键命令只覆盖「9 节点最小骨架」；**不含** `LoraLoader` / trigger 追加 / ControlNet / IPAdapter / LayerDiffuse（§2 裁决前不接入）。

### 5.2 验收口径（逐条真跑，不得伪造）

| # | 验收项 | 通过标准 |
|---|---|---|
| 1 | `POST /prompt` 应答 | 返回 `prompt_id`，且 **`node_errors` 为空**（无 `size mismatch` / key 错误）→ 这是 §2 兼容性是否踩雷的第一道闸；若非空，回退 §2.5 裁决，**不谎报成功** |
| 2 | `GET /history/{prompt_id}` | `status_str=success`、`outputs` 含 `SaveImage` 图片项 |
| 3 | 产物真实存在 | PNG 字节数 > 0、文件头 `\x89PNG`；按 `00-工具链接入说明.md` §5.6 **每张 PNG 人眼看图**，不编造校验数据 |
| 4 | 尺寸 / 色数收敛 | `ImageScale`→128×128、`ImageQuantize`≤256 色；交付端 `32×32` / `16 色` / Point / 锚点 `(16,31)` 另验 |
| 5 | 画质锚点 | 透明背景 / alpha 存在、1px 硬边、无抗锯齿、有限色板（对照 `ART-SPEC-FINAL.md`、`prompt_skeleton.json`）；negative 项未出现 |
| 6 | 可复现登记 | 产物落到 `godot/assets/generated/chars/`、`import.json` 回写来源 / `schema_version` / seed / 版本号 |
| 7 | 运行边界 | 全程 **仅 1 个 GPU job**；不杀/不重启旧 job；零付费 / 零外部依赖 |
| 8 | 真实 PNG 计数 | 当前 `真实 PNG = 0`；出图前 alpha / ≤256 色 / 装饰层逐像素对齐抽检**无法执行**，不编造校验数据 |

---

## 6. ⑤ 旧 job 现状与为何不并行

### 6.1 现状（只读证据）

- 旧 `qwen-image --quant nf4` job：日志停在 **01:21** 的 `Loading checkpoint shards 50%`，已 **3 小时+** 无 PNG、stdout 0 字节（`00-工具链接入说明.md` §7、`00-群聊总线.md` MSG-0346 / MSG-0400 长期阻塞登记、`COMFYUI-WORKFLOW.md` §7）。
- 本轮 `GET /system_stats`（§1.1）：`vram_free=8959269586 / 17175150592`，差额 **8215801006 字节 ≈ 7.65 GiB** 被外部进程持有；而 **`torch_vram_total=33554432`（32 MiB）** 说明 ComfyUI 自身 PyTorch 几乎空转 → 这 ~7.65 GiB **不是 ComfyUI 在跑**，而是独立的旧 `qwen-image` 进程加载的模型权重常驻。两件事互相印证：ComfyUI 空闲、整机显存被旧 job 占。
- 处置状态：**不杀 / 不重启 / 不并行**（本轮硬边界）；程序化 `_draw()` 占位仍是零外部依赖正式兜底，不取代 ComfyUI 主路线（`00-工具链接入说明.md` §6）。

### 6.2 为何不并行

1. **契约硬约束**：`00-工具链接入说明.md` §5.3「**一次只跑一个 GPU job**」；`COMFYUI-WORKFLOW.md` §7 与 `任务书-R12.md` 边界明令「绝不启动第二个 GPU job」。
2. **显存物理上限**：RTX 4060 Ti 仅 16 GiB，旧 job 已占 ~7.65 GiB；SDXL 出图（尤其 1024 档）峰值再需数 GiB，并行极易 **OOM**，两个 job 互相拖死，得不偿失。
3. **旧 job 已停滞**：停在 `checkpoint shards 50%`、无 PNG，并行不会让它更快，只会叠加显存与调度风险。
4. **处置权限**：杀 / 重启旧 job 属**破坏性、跨工位、需用户/HOST 裁决**的动作，本轮**不擅自处理、只登记**。
5. **放行条件**：旧 job 自行退出或经授权处置后，重跑 `GET /system_stats` 见 `vram_free` 回到高位（§4 第 1 项），才允许 POST 出图。

---

## 7. `comfyui_workflow_pixel.json` 改动判定（交付 2）

| 项 | 内容 |
|---|---|
| 判定 | **保持不动**（无改动） |
| 改动前后 | `EmptyLatentImage.width: 512 → 512`、`height: 512 → 512`；`bytes=2529`、`sha256=98d6d722972137898f391591f8f5d38f265cf25df2ff988b3f2c0723aca82ddd`（收尾复核不变） |
| 依据 | `/object_info` 的 `EmptyLatentImage.width/height` 仅 `INT {default:512, min:16, max:16384, step:8}`，**无「SDXL 需 1024」的映射/推荐**，不构成任务书要求的「明确 `/object_info` 依据」；且 `default` 即 512、512 合法；R11 已验证骨架、用户硬边界「除非有 `/object_info` 依据否则不改骨架」 |
| 建议归属 | 「升 1024 / 768」只作 §3.2 建议，留待用户说「出图」后按 §5 真跑 A/B + HOST 裁决，**本轮不落笔** |

---

## 8. 未完成项与阻塞（只登记，不擅改）

| # | 项 | 状态 |
|---|---|---|
| 1 | 实际出图 / 真实 PNG | 本轮不做，`真实 PNG = 0`；POST `/prompt` 须 GPU 空闲 + HOST 明确「出图」授权 |
| 2 | GPU 空闲 | ❌ 旧 job 占 ~7.65 GiB，未满足；不杀/不重启/不并行 |
| 3 | SDXL ckpt 与冻结 SD1.5 扩展件配套 | ⛔ **本轮已判定不兼容**（§2）；路线 A/B 待用户/HOST 裁决 |
| 4 | 冻结 LoRA 引用名 `pixel-art-lora.safetensors` ≠ 本机文件名 | 已如实登记（§2.3 / §2.4），待对齐 |
| 5 | `EmptyLatentImage` 是否升 1024 | 只给建议（§3.2），无 `/object_info` 依据 → 未改骨架 |
| 6 | `128bit` 确切含义 | ⏸ 待用户确认（暂按 128px 基准画布），不自行改口径 |
| 7 | ComfyUI 安装目录 | 未确认（`argv` 无绝对路径、进程命令行查询被安全策略阻止、未绕过）；API 端点已足够接入 |
| 8 | `usage_notes[3]` 的 lora trigger 追加 / ControlNet / IPAdapter / LayerDiffuse | 链路无对应节点且兼容性未裁决，留待扩展轮次 |
| 9 | `seed_lock.action_offset` 与 R2 冻结枚举不一致 | 待 HOST 裁决后整体升 v2，本轮不擅改（`COMFYUI-WORKFLOW.md` §6） |
| 10 | alpha / ≤256 色 / 装饰层逐像素抽检 | 无 PNG 无法执行，不编造校验数据 |

---

## 9. 合规声明

- **只读边界**：仅 `GET /system_stats`、`GET /object_info` 与本地 `json.load`；**未 POST `/prompt`、未出图、未启动第二个 GPU job、未杀/重启旧 job、未写探针 / 未扫盘 / 未重复刺探进程命令行**。
- **唯一可写范围**：`Rank-4\COMFYUI-READINESS.md`、`Rank-4\DONE-R12.md` + 回执例外 `command_center\ai\4\outbox\`；`comfyui_workflow_pixel.json` **保持不动**；**未写** `godot\`（本轮无落位改动）、总线 / 总纲 / 契约 / 任务书 / 其它工位；未自行 `git commit` / `git push`。
- 既有件（`comfyui_workflow_pixel.json`、`COMFYUI-WORKFLOW.md`、`prompt_skeleton.json`、`ART-SPEC-FINAL.md`、`I5-DELIVERY-CHECKLIST.md` 等）一律引用、不重做。
- 零付费 / 零外部依赖；付费 API 一律禁用；`128bit` 待用户确认、不自行改口径；不伪造输出 / 画面 / 截图 / 安装路径、不宣称已出图。
- 中文 UTF-8；本文件代码块一律 `text` 标记、行首围栏不标注 json（与 `COMFYUI-WORKFLOW.md` / `ART-SPEC-FINAL.md` / `DONE-R9.md` 一贯做法一致）；所有独立 JSON 真跑 `json.load` 通过，回执为合法 JSON。
