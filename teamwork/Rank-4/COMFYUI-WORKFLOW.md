# COMFYUI-WORKFLOW.md · ComfyUI 主路线 API 工作流接入说明（Rank-4 R11 交付）

> 轮次：**R11（ComfyUI 主路线 API 工作流骨架落地）**｜派单：`cmd-20261109-042711-618-A4`｜工位：Rank-4 美术管线与工具链
> 定位：本机 ComfyUI 主美术路线的**可调用 API 工作流骨架**接入说明。本轮**不实际出图**：绝不 POST `/prompt`，绝不启动第二个 GPU job。
> 口径来源：`任务书-R11.md`、`00-工具链接入说明.md` §4/§6/§7、`ART-SPEC-FINAL.md`、`I5-DELIVERY-CHECKLIST.md`、`00-协作契约.md` §9.3、`prompt_skeleton.json`、`import.json`，以及 `GET http://127.0.0.1:8188/object_info` 实测。
> `00-群聊总线.md` 开工只读一次；既有件一律引用、不重做、不擅改。

---

## 0. 一句话结论

`comfyui_workflow_pixel.json` 是 9 节点（8 类）API 工作流骨架，顶层即完整 `/prompt` 请求体 `{"prompt": {...}}`；**节点名与每个节点的必需输入键 100% 取自真实 `GET /object_info` 返回，零臆造、无节点缺失、无替代替换**。**ComfyUI 仍是主美术路线**，`qwen-image` 为本地零付费备选（长期阻塞），程序化 `_draw()` 为零外部依赖兜底；主次关系不因本轮落地而改变。

---

## 1. 端点与版本（只读实测，非推测）

| 项 | 实测值 | 来源 |
|---|---|---|
| 服务地址 | `http://127.0.0.1:8188` | 04:24 HOST 定位 + 本轮只读复核 |
| `GET /system_stats` | HTTP 200 | 本轮 `curl -s` 真跑 |
| ComfyUI 版本 | `0.33.2` | `system.comfyui_version` |
| frontend | `1.49.6`（required=installed） | `system.required_frontend_version` / `comfy_package_versions` |
| PyTorch / Python | `2.9.1+cu130` / `3.12.9` | `system.pytorch_version` / `python_version` |
| 设备 | `cuda:0 NVIDIA GeForce RTX 4060 Ti`（`vram_total=17175150592` ≈ 16 GB，`vram_free=8959269586`） | `devices[0]` |
| 启动参数 | `main.py --listen 127.0.0.1 --port 8188 --cuda-device 0 --disable-auto-launch` | `system.argv`（**不含绝对路径**，见 §9） |
| `GET /object_info` | 共 **2724 节点** | 本轮 `curl -s` + `json.load` 真跑 |
| 提交端点 | `POST http://127.0.0.1:8188/prompt` | 登记备用，**本轮不调用** |

调用形态（说明，未执行、不代表已出图）：

```text
curl -s -X POST -H "Content-Type: application/json" \
  -d @comfyui_workflow_pixel.json http://127.0.0.1:8188/prompt
```

> 本文件顶层即完整请求体 `{"prompt": {...}}`，可直接作为 POST body；若下游工具要的是 ComfyUI「Export (API)」纯工作流字典，取顶层 `.prompt` 即可（两种口径在 `DONE-R11.md` §2 真跑同时验证）。

---

## 2. 节点清单与实测存在性（`GET /object_info` 逐项）

`object_info` 中每个节点的定义结构为 `input.required`（必需输入键）/ `input.optional` / `output` / `output_name`。下表 `required` 列即**实测原样返回的键名**，工作流的 `inputs` 与之逐键对齐。

| 实例 id | `class_type` | 实测存在 | category | `input.required`（真实键名） | `output` |
|---|---|---|---|---|---|
| 1 | `CheckpointLoaderSimple` | ✅ | `model/loaders` | `ckpt_name` | `MODEL`, `CLIP`, `VAE` |
| 2 | `CLIPTextEncode`（正） | ✅ | `model/conditioning` | `text`, `clip` | `CONDITIONING` |
| 3 | `CLIPTextEncode`（负） | ✅ | `model/conditioning` | `text`, `clip` | `CONDITIONING` |
| 4 | `EmptyLatentImage` | ✅ | `model/latent` | `width`, `height`, `batch_size` | `LATENT` |
| 5 | `KSampler` | ✅ | `model/sampling` | `model`, `seed`, `steps`, `cfg`, `sampler_name`, `scheduler`, `positive`, `negative`, `latent_image`, `denoise` | `LATENT` |
| 6 | `VAEDecode` | ✅ | `model/latent` | `samples`, `vae` | `IMAGE` |
| 7 | `ImageScale` | ✅ | `image/upscaling` | `image`, `upscale_method`, `width`, `height`, `crop` | `IMAGE` |
| 8 | `ImageQuantize` | ✅ | `image/filters` | `image`, `colors`, `dither` | `IMAGE` |
| 9 | `SaveImage` | ✅ | `image` | `images`, `filename_prefix` | `IMAGE` |

**结论：8 类节点全部命中，无缺失、无需「改用实际可用节点」的替代方案。** `ImageQuantize` 属 `image/filters` 类自定义节点，本机真实存在，正好承担 ≤256 色收敛。

关键枚举 / 边界（`object_info` 实测原样）：

```text
ckpt_name                 : 15 个候选；像素风唯一项 pixelArtDiffusionXL_spriteShaper.safetensors 存在=True
KSampler.sampler_name    : 44 项；euler_ancestral 存在=True
KSampler.scheduler       : [simple, sgm_uniform, karras, exponential, ddim_uniform, beta, normal, linear_quadratic, kl_optimal]；normal 存在=True
ImageScale.upscale_method : [nearest-exact, bilinear, area, bicubic, lanczos]；nearest-exact 存在=True
ImageScale.crop          : [disabled, center]；disabled 存在=True
ImageQuantize.dither     : [none, floyd-steinberg, bayer-2, bayer-4, bayer-8, bayer-16]；none 存在=True
ImageQuantize.colors     : {default:256, min:1, max:256, step:1}   ← 天然满足「≤256 色」
EmptyLatentImage.width   : {default:512, min:16, max:16384, step:8}；512 合法
```

> `object_info` 中另有 `LoraLoader`(8) / `ControlNetLoader`(8) / IPAdapter 系(43) / `CLIPTextEncode`(14) 等扩展节点（04:24 实测清单）。本骨架按 R11 任务书指定的 **9 节点最小链路**落地，未纳入扩展节点，不臆造、不擅自加节点；扩展留待后续轮次，见 §5 / §10。

---

## 3. 链路与连线（拓扑）

```text
[1] CheckpointLoaderSimple ──MODEL(0)──────────────┐
      ├──CLIP(1)──→ [2] CLIPTextEncode(+)          │
      ├──CLIP(1)──→ [3] CLIPTextEncode(-)          │
      └──VAE(2)────────────────────────→ [6] VAEDecode
[4] EmptyLatentImage ──LATENT(0)──→ [5] KSampler ──LATENT(0)──→ [6] VAEDecode
[2]/[3] CONDITIONING(0) ──→ [5] KSampler (positive / negative)
[6] IMAGE(0) ──→ [7] ImageScale ──IMAGE(0)──→ [8] ImageQuantize ──IMAGE(0)──→ [9] SaveImage
```

| 节点 | 输入取值 | 上游引用（实测输出索引） |
|---|---|---|
| 1 | `ckpt_name = pixelArtDiffusionXL_spriteShaper.safetensors` | — |
| 2 | `text` = `prompt_skeleton.positive`（含唯一 `[SUBJECT]`）；`clip` | `["1", 1]` = CLIP |
| 3 | `text` = `prompt_skeleton.negative`；`clip` | `["1", 1]` = CLIP |
| 4 | `width=512, height=512, batch_size=1` | — |
| 5 | `seed=20261108, steps=28, cfg=7.0, sampler_name=euler_ancestral, scheduler=normal, denoise=1.0` | `model=["1",0]`、`positive=["2",0]`、`negative=["3",0]`、`latent_image=["4",0]` |
| 6 | `samples`, `vae` | `["5",0]`、`["1",2]` = VAE |
| 7 | `upscale_method=nearest-exact, width=128, height=128, crop=disabled` | `image=["6",0]` |
| 8 | `colors=256, dither=none` | `image=["7",0]` |
| 9 | `filename_prefix=aierdengfahuan_hd2d_r11` | `images=["8",0]` |

> `CheckpointLoaderSimple.output_name = ["MODEL","CLIP","VAE"]`，故索引 `0/1/2` 分别为 MODEL/CLIP/VAE；其余均为单输出索引 `0`。连线索引已在 `DONE-R11.md` §2 内联真跑核对。

---

## 4. 关键参数口径

- **`128bit` 暂按 128px 理解**：`ImageScale` 的 `width/height = 128`，`upscale_method = nearest-exact`（保留硬边 1px 轮廓、无抗锯齿），`crop = disabled`（不裁切主体）。按 `ART-SPEC-FINAL.md` §1，`128px` 是**生成端设计基准画布**，不把交付端单帧改成 128px、也不改 640×360 渲染缓冲；交付端仍为 `32×32 px` / Point / 16 色 / 底部中心锚点 `(16,31)`。`128bit` 的确切含义（画布尺寸 vs 位宽 / 色深）**仍待用户确认**，只登记不自行改口径（契约 §9.3、`ART-SPEC-FINAL.md` §6 第 1 项）。
- **≤256 色**：`ImageQuantize.colors = 256`（实测 `max=256`）、`dither = none`。本节点做「≤256 色索引容量」粗收敛；单角色 ≤16 色、取色限 `hd2d_index_256_v1` 32 色共享板，由 `downsample` / Aseprite 手工精修完成（`ART-SPEC-FINAL.md` §2.2、`prompt_skeleton.downsample`）。`image/quantize.py` 是 **DiT 权重量化器（int8/nf4）**，不是调色板量化器，绝不混用（`00-工具链接入说明.md` §4.1）。
- **`ckpt_name`**：取 `object_info` 枚举中真实存在的 `pixelArtDiffusionXL_spriteShaper.safetensors`（15 个候选中唯一像素风 checkpoint）。**如实登记**：`prompt_skeleton.json` 冻结的 `controlnet` / `lora_triggers` / `ip_adapter` / `layerdiffuse` 均为 SD15 系（`control_v11p_sd15_openpose.pth`、`ip-adapter_sd15.bin`、SD15 Attention Injection），与该 XL checkpoint 的配套兼容性**未实测**；后续接入扩展节点时须核对兼容性或改选 SD1.5 checkpoint，本轮不擅自裁决、不宣称可出图。
- **sampling**：`steps=28 / cfg=7.0 / sampler_name=euler_ancestral / scheduler=normal` 逐字取自 `prompt_skeleton.json::sampling`（`fixed=true`），且真跑确认四个值均在 `object_info` 枚举内。`denoise=1.0` —— 本骨架从 `EmptyLatentImage` 起为纯文生图，必须满幅去噪；`prompt_skeleton.sampling.denoise=0.55` 属 img2img / 局部重绘档位值，拓扑不同，**不覆盖骨架字段、不擅改**。
- **`EmptyLatentImage` 512×512×1**：生成端出图分辨率（`object_info` 默认 512、`min=16 / step=8`，512 合法），避免过低分辨率直接生成导致结构崩坏；SDXL 档位可选 1024×1024。无论生成分辨率取值，统一经 `ImageScale` 收敛到 **128px 基准画布**。
- **`SaveImage.filename_prefix`**：固定值 `aierdengfahuan_hd2d_r11`，**不含 `[SUBJECT]`**（保证唯一槽位计数，见 §5）。

---

## 5. 固定 Prompt 骨架只换 `[SUBJECT]`

- 骨架 id：`hd2d_pixel_skeleton_v1`（`prompt_skeleton.json`，`frozen=true`）。
- `single_slot.count=1`、`occurrences_in_positive=1`：整份骨架唯一可替换槽位是方括号包裹的 `[SUBJECT]`，**只出现在节点 `2` 的 `text`（positive）中一次**；节点 `3`（negative）及 `filename_prefix` 均不含占位符。
- 骨架 JSON 中节点 `2` / 节点 `3` 的 `text` **逐字复制**自 `prompt_skeleton.json` 的 `positive` / `negative`，未追加、未改写、未省略（`DONE-R11.md` §2 内联真跑逐字比对）。
- 调用方**只允许**把 `[SUBJECT]` 替换为品类内主体名（如 `player_tarnished` / `hollow_soldier` / `grace_site` / `stone_ruins`）；`single_slot.forbidden_in_slot` 明令不得写入风格词、光照词、色号 / 色彩词、分辨率 / 尺寸词、在世艺术家姓名、受版权保护的角色名或 IP 名称，避免污染风格锚点。
- `negative` / `style` / `lighting` / `palette` / `lora_triggers` / `controlnet` / `ip_adapter` / `layerdiffuse` / `downsample` / `seed_lock` / `sampling` **一律不得改写、追加或省略**。
- **如实登记（未做，不伪造）**：`prompt_skeleton.usage_notes[3]` 要求「提交 ComfyUI 前把 `lora_triggers` 的 trigger 追加到正向提示词末尾」，且需 `LoraLoader` 节点配合。本 R11 骨架是任务书指定的 9 节点最小链路，**不含 `LoraLoader`**，故骨架文本未追加 trigger（追加会改动骨架文本、且链路无对应节点，属两套不同阶段）；该步骤与 ControlNet / IPAdapter / LayerDiffuse 扩展一并留待后续轮次，不臆造、不宣称已完成。

---

## 6. seed 锁定

- `KSampler.seed = 20261108` = `prompt_skeleton.json::seed_lock.base_seed`（`enabled=true`），骨架内为**固定值**，不是随机数。
- 实值按 `seed_lock.derivation`：`seed = base_seed + category_offset * 10000 + action_offset * 100 + frame_index`；实际出图时把派生实值覆盖到本节点，并写入 `import.json::seed` 供复核（`cross_prompt_reuse=true`，同一 seed 跨 prompt 复用为风格一致性第三层约束）。
- `decor_layer_rule`：装饰层必须复用其 base 层**完全相同**的 seed，禁止重新抽种子；`control_after_generate` 是前端 UI 属性（在 `seed` 定义的 options 内、不是独立必需输入键），本 API 骨架不传、不随机改写。
- 既有 `import.json` 样例 `seed=20271308` 是**资产级实值示例**，与骨架基准 seed 属不同层级，不互相覆盖、本轮未改动。
- **如实登记**：`ART-SPEC-FINAL.md` §6 第 5 项已把 `seed_lock.action_offset` 与 R2 冻结枚举不一致登记为「待回改，须 HOST 裁决后整体升 v2」，本轮不擅改。

---

## 7. 与 `qwen-image` 备选 / 程序化 `_draw()` 兜底的关系（三层，主次不变）

| 层 | 角色 | 本轮现状 | 依据 |
|---|---|---|---|
| **主路线** | 本地 ComfyUI `http://127.0.0.1:8188` + 本骨架 | 服务已定位（04:24）、API 骨架已落地；**本轮未出图、未 POST `/prompt`** | 契约 §9.3、`00-工具链接入说明.md` §6 |
| **本地备选** | `qwen-image`（Godogen，零付费） | **长期阻塞**：约 3 小时停在 `Loading checkpoint shards 50%`、无 PNG、stdout 0 字节；仅作姿势基准图 / kit 图 / 装饰层底稿，不取代主路线 | `00-工具链接入说明.md` §7、`I5-DELIVERY-CHECKLIST.md` §6.1 |
| **兜底** | 程序化 `_draw()` 占位 `hd2d_placeholder.gd` | 工程内唯一可真实运行、零外部依赖的**正式兜底**；不宣称占位是正式素材、不取代 ComfyUI | `I5-DELIVERY-CHECKLIST.md` §6.2、`ART-SPEC-FINAL.md` §3.3 |

- **主路线不因备选阻塞或兜底正式化而变更**：`qwen-image` 只是同为零付费的本地备选 / 补充；`_draw()` 兜底正式化 ≠ 主路线变更。
- 兜底退出条件（`scene_integration.md` §4）：`assets/generated/bg_layers/` 与 `chars/` 有首批合规 spritesheet 且 1 号完成纹理层接入后，`HD2DPlaceholderAttach.detach(root)` 移除背景层、逐层替换为 `draw_texture_rect()` / Sprite，`placeholder_enabled` 保留为调试开关。
- **硬边界**：本轮绝不 POST `/prompt`、绝不启动第二个 GPU job；现有单一 `qwen-image` job **不杀 / 不重启 / 不并行**。付费 API 一律禁用，零外部依赖。

---

## 8. `import.json` 的 `pipeline` 字段更新（两份逐键一致）

- 两份 `import.json`（`teamwork\Rank-4\` 与 `godot\assets\generated\`）**新增** `pipeline` 对象：`primary_route = comfyui_local_api_workflow`、`comfyui_endpoint = http://127.0.0.1:8188`、`comfyui_version = 0.33.2`、`workflow_json = comfyui_workflow_pixel.json`，明确指向 ComfyUI 主路线。
- 顶层 `fallback_route` **原值 `procedural_draw_placeholder` 保留、一字未改**；`pipeline_tier = "D"` 是显存档位（`美术管线.md` §7），与 `pipeline` 是不同字段，未改。
- 既有两份原本**无** `pipeline` 键，本轮按 R11 任务书**定点新增**（31 → 32 键），其余字段逐字不动；改后两份 **逐键一致**（`DONE-R11.md` §2 内联真跑比对）。

---

## 9. 安装目录未确认的原因（如实，不臆造）

- `GET /system_stats` 的 `argv` 只有 `["main.py", "--listen", "127.0.0.1", "--port", "8188", "--cuda-device", "0", "--disable-auto-launch"]`，**不含可执行文件绝对路径**。
- 通过进程命令行（`wmic` / `Get-CimInstance Win32_Process.CommandLine` 一类）查询 ComfyUI 安装目录，**被本机安全策略阻止**；**未绕过、未重试、未改走其它通道**（`00-工具链接入说明.md` §7 已登记同一事实，本轮沿用、不重复刺探）。
- 按契约 §5「默认不刺探」，不扫盘、不臆造安装路径。**API 端点 `http://127.0.0.1:8188` 已足够接入本骨架**，安装目录不是本轮交付前置条件。

---

## 10. 未完成项与阻塞（只登记，不擅改）

| # | 项 | 状态 |
|---|---|---|
| 1 | 实际出图 | **本轮不做**：无 PNG、不宣称已能出图；POST `/prompt` 须 HOST 明确授权且 GPU 空闲后执行 |
| 2 | 现有单一 `qwen-image` job | 长期阻塞（`checkpoint shards 50%`、无 PNG）；不杀 / 不重启 / 不并行、不拉第二个 GPU job |
| 3 | `ckpt` 与 SD15 系 ControlNet / LoRA / IPAdapter / LayerDiffuse 配套兼容性 | 未实测；扩展节点未纳入 9 节点最小骨架 |
| 4 | `usage_notes[3]` 的 lora trigger 追加 | 未落到骨架文本（链路无 `LoraLoader`），留待扩展轮次 |
| 5 | `128bit` 确切含义 | 待用户确认（暂按 128px 基准画布） |
| 6 | ComfyUI 安装目录 | 未确认（进程命令行查询被安全策略阻止，未绕过） |
| 7 | `seed_lock.action_offset` 与 R2 冻结枚举不一致 | 待 HOST 裁决后整体升 v2，本轮不擅改 |
| 8 | 真实 PNG = 0 | `alpha` / ≤256 色收敛 / 装饰层逐像素对齐抽检**无法执行**，不编造校验数据 |

---

## 11. 合规声明

- 只写 `Rank-4\`（`comfyui_workflow_pixel.json`、`COMFYUI-WORKFLOW.md`、`import.json`、`DONE-R11.md`）+ `godot\assets\generated\import.json` + 回执例外 `teamwork\command_center\ai\4\outbox\`；**未写** `project.godot`、`scenes\`、其它工位、总线 / 总纲 / 契约 / 任务书；未自行 `git commit` / `git push`。
- 节点名与必需输入键 100% 取自真实 `GET /object_info`（2724 节点），零臆造；所有独立 JSON 内联真跑 `json.load` 通过（输出见 `DONE-R11.md` §2）。
- 零付费 / 零外部依赖；付费 API 一律禁用；`stable-audio`（gated 403）/ `gen3d` / `mia-rig` 不申请、不补装、不碰 WSL、不绕过；既有件引用不重做。
- 中文 UTF-8；本文档代码块一律 `text` 标记、**不含行首 ```json 围栏**（与 `ART-SPEC-FINAL.md` / `I5-DELIVERY-CHECKLIST.md` / `DONE-R9.md` 一贯做法一致）。
- **不 POST `/prompt`、不启动第二个 GPU job、不伪造输出 / 画面 / 截图、不宣称已出图、不臆造 ComfyUI 安装路径、不夸大纹理级导入已生效**。
