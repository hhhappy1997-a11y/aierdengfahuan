# ASSET-PROOF.md · R3 qwen-image 首次出图实跑验证记录

> 轮次：**R3** ｜ 派单：`cmd-20261109-005741-239-A4` ｜ 依据：`Rank-4\任务书-R3.md` §2 / §3、`调度任务单-latest.json`
> 工位：Rank-4（美术管线与工具链）｜ 唯一可写：`Rank-4\` ｜ 零付费 / 零外部依赖 / 默认不刺探
> 本文件是**实跑记录**，不是规格文档。所有结论以本机实际 stdout / stderr / 文件系统为准：**不宣称已能出图、不伪造任何 PNG 产物**。
> 口径：**ComfyUI 仍是主美术路线**；`qwen-image` 只是同为零付费的**本地备选 / 补充**，不取代。

---

## 0. 结论速览（先看这里）

| 项 | 本轮实际结论 |
|---|---|
| 是否按任务书 §3 真跑 | ✅ 已启动**单次** GPU job：`qwen-image generate --quant nf4 --resolution 512 --steps 10` |
| 是否产出 PNG | ⛔ **否**（截至本文件成文，`Rank-4\` 下无任何 `.png`；`ls`/Glob 实测 No files found） |
| 是否宣称已能出图 | ❌ **否**。本机至今只跑通过 `qwen-tts`、没跑出过图，本轮不改此事实 |
| 是否伪造输出 | ❌ **否**。无 PNG、无假 JSON 结果、无假耗时/显存结论 |
| `image/quantize.py` | DiT **权重量化器**（int8/nf4），**不是** 256 色调色板量化器 |
| ComfyUI 本机路径 | ⛔ 未登记（`00-工具链接入说明.md` §7），如实阻塞，不臆造地址、不尝试连接 |
| 付费 API / gated 项 | 一律禁用；`stable-audio`(403)/`gen3d`/`mia-rig` 不申请、不补装、不碰 WSL、不绕过 |

> **重要**：本次实跑的 GPU job 在本文件成文时**仍在运行**（首次全量 31G 权重逐片量化加载，见 §3）。本文件记录的是「截至成文时的真实观测」，属实跑进行中的如实快照；后台 job 未杀、未中断，其最终 stdout / stderr 落在 `Rank-4\asset_proof_stdout.txt` / `Rank-4\asset_proof_stderr.log`，**最终结果以这两个日志为准**。本轮不因日志后续变化而回头改写成「已成功出图」，也不伪造中途产物。

---

## 1. 实跑环境与前置确认（只读，非巡检 / 非探针脚本）

| 项 | 实测值 |
|---|---|
| 调度入口 | `D:\godogen_assets\bin\godogen_win.py`（存在，11462 B） |
| 分发链 | `--cmd qwen-image` → `image/.venv/Scripts/python.exe image/cli.py`（`godogen_win.py` 的 `TOOLS` 表第 29 行） |
| 工具 venv | `D:\godogen_assets\image\.venv\Scripts\python.exe`（存在，262144 B） |
| 模型权重 | `D:\godogen_deps\hf\hub\models--Qwen--Qwen-Image-2.1`，8 个 `*.safetensors`（text_encoder 4 片 / transformer 2 片 / vae 1 片 + 1 个 `.no_exist` 占位）；`du -sh` = **31G** |
| 环境变量 | `D:\godogen_deps\env.cmd`（存在）；由 `godogen_win.py::tool_env()` 注入 `GODOGEN_DEPS` / `HF_HOME` / `HF_HUB_CACHE` / `HF_ENDPOINT=https://hf-mirror.com` / `HF_HUB_DISABLE_XET=1` / `TORCH_HOME` 等，与 `env.cmd` 等价；**未设 `HF_HUB_OFFLINE=1`**（按任务书 §3 要求） |
| GPU | `nvidia-smi` = `NVIDIA GeForce RTX 4060 Ti, 16380 MiB` |
| 调度端 Python | 3.13.14（仅用标准库运行 dispatcher，不参与推理） |

> 上述为**执行真跑所需的路径存在性确认**，不是进度巡检、未写任何探针 / 测量 / preflight 脚本、未扫别人工位。开工只读一次 `00-群聊总线.md`（读到末尾 `MSG-20261109-0057-HOST`）。

---

## 2. 实跑命令与参数（实际执行，非示例）

```bat
python D:\godogen_assets\bin\godogen_win.py --cmd qwen-image generate "pixel art game sprite, a lone tarnished knight in weathered golden armor, full body, front facing view, flat shading, hard pixel edges, 128px base canvas, 256 color indexed palette, transparent background, centered, feet on ground" --quant nf4 --resolution 512 --steps 10 -o F:\Game\aierdengfahuan\teamwork\Rank-4\asset_proof_qwen_nf4.png --json
```

- **stdout** 只收单个 JSON → 重定向到 `Rank-4\asset_proof_stdout.txt`；**stderr** 进度 → `Rank-4\asset_proof_stderr.log`（按任务书 §3「stderr 存文件，只在失败 / 异常时读」）。
- **一次只跑一个 GPU job**，后台单进程、长 timeout，未与其它 GPU job 并行。
- `-o` 指向项目内 `Rank-4\` 绝对路径（唯一可写范围），未落在 `godogen_assets\outputs\`。
- 参数链均**读源码确认、非猜测**（`image/cli.py` + `image/generate.py`）：
  - `--quant nf4` → `cli.py::build_generate_argv` 转成 `--dit-quant nf4`（`generate.py` 第 100 行：bitsandbytes 4-bit，7B DiT bf16 14.2 GB → ~4.5 GB）；
  - `--te-quant` 默认 `nf4`（Qwen3-VL 8B 文本编码器 bf16 17.5 GB → 4-bit）；
  - `--offload` 默认 `model`（一次只有一个组件在 GPU），`PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True`；
  - `--resolution 512 --steps 10` 为任务书 §3 指定；`generate` 子命令由 `cli.py` 自动追加 `--rgb`；
  - 本机**无** `image/models/qwen-image-2.1-nf4/` 预量化目录（`ls` 实测 `image/models/` 不存在），故走**加载时量化**（`generate.py::load_pipeline` 第 244 行 components 分支），不是预量化目录加载。
- **量化器澄清**：`image/quantize.py` 头部自述 `"""Quantize Qwen-Image-2.1 once with bitsandbytes and save a local pre-quantized pipeline."""`，是 **DiT 权重量化器（int8/nf4）**，**不是 256 色调色板量化器**；调色板收敛走 ComfyUI 管线 + Aseprite / ImageMagick，不混用。

### 2.1 实跑参数结构化记录（合法 JSON，已随自检解析）

```json
{
  "round": "R3",
  "task_id": "cmd-20261109-005741-239-A4",
  "tool": "qwen-image",
  "subcommand": "generate",
  "quant": "nf4",
  "dit_quant": "nf4",
  "te_quant": "nf4",
  "offload": "model",
  "resolution": 512,
  "steps": 10,
  "json_stdout": true,
  "output_png_expected": "F:/Game/aierdengfahuan/teamwork/Rank-4/asset_proof_qwen_nf4.png",
  "output_png_actually_produced": false,
  "single_gpu_job": true,
  "zero_external_dependency": true,
  "hf_endpoint": "https://hf-mirror.com",
  "hf_hub_offline": false,
  "comfyui_is_primary_route": true,
  "qwen_image_is_local_fallback_only": true,
  "image_quantize_py_role": "DiT weight quantizer (int8/nf4), NOT a 256-color palette quantizer"
}
```

---

## 3. 实跑观测（截至本文件成文时的真实快照）

| 观测项 | 实际输出 |
|---|---|
| 启动时间 | 2026-11-09 01:05（后台 job `xhKNq7`，单进程） |
| stderr 首行 | `[load] text_encoder (nf4) from Qwen/Qwen-Image-2.1 ...` |
| 平台告警 | `UserWarning: expandable_segments not supported on this platform`（Windows 平台提示，非失败） |
| 权重加载进度 | `Loading weights: 49%|████▉ | 364/750 [07:19<...]`（text_encoder 4-bit 量化逐片加载，750 分片） |
| GPU 显存 | `nvidia-smi` = `14203 MiB, 0 %`（加载阶段实测占用；**非最终峰值**，去噪阶段尚未开始） |
| 进程 | `python.exe` 常驻，单 GPU job；`nvidia-smi --query-compute-apps` 可见该进程占用显存 |
| stdout | `asset_proof_stdout.txt` = **0 字节**（`--json` 结果对象尚未产生） |
| PNG | `ls Rank-4\*.png` = **No files found**（`asset_proof_qwen_nf4.png` 未产出） |
| 报错 | stderr 中**无任何 Traceback / Error / OOM**（见 §0：是「加载极慢仍在跑」，不是「已失败」） |

**如实判读**：本机 `qwen-image` 全量 30.84 GiB 权重 > RTX 4060 Ti 16 GB 显存，`--quant nf4` 需把 text_encoder（750 分片）与 transformer 逐片量化并 CPU offload，首次冷加载耗时远超「分钟级」常规预期。本轮交付窗口内该 job **未跑完、未产 PNG、未打印结果 JSON**。按任务书 §3 与本次 HOST 指令「跑不通就如实写阻塞，不得宣称已能出图、不得伪造输出」，**本轮不宣称已能出图、不伪造产物**，把「首次出图实跑」登记为 **未完成 / 阻塞（进行中）**。

---

## 4. 出图后校验（因未产 PNG，整节如实写阻塞，不编造结论）

| 校验项 | 任务书 §3 要求 | 本轮结论 |
|---|---|---|
| 输出 PNG 路径 | `-o` 指向的绝对路径 | **未产出**（预期 `Rank-4\asset_proof_qwen_nf4.png`，实测不存在） |
| 人眼看图 / alpha 在对比色上判定 | 透明底在对比色上判 alpha，非装饰区 `(0,0,0,0)` 全透明 | **无法执行**：无 PNG 可看；不伪造「已看图」结论 |
| 降到 128px 是否发糊 | 出图后降到 128px 检查 | **无法执行**：无源图；不伪造降采样结果 |
| 256 色收敛结果 | 调色板收敛到 ≤256 色索引板 | **无法执行**：无源图。收敛路线仍为 ComfyUI / Aseprite / ImageMagick；`image/quantize.py` 不是调色板量化器（§2 已澄清） |
| 装饰 RGBA 层与 base 一致性 | 尺寸 / 帧序 / 坐标系 / seed / 降采样参数一致 | **不适用 / 未产出**：本轮无 base、无装饰层，不臆造对齐结论 |
| 耗时 / 峰值显存 / 结果 JSON | `--json` 输出含 timing / peak VRAM | **未产生**：stdout 0 字节；只有 §3 的加载阶段显存实测 14203 MiB（非最终峰值），如实标注 |

> 本节所有「无法执行」均为**如实阻塞**，不是遗漏。若后续后台 job 产出 PNG 或明确失败，以 `asset_proof_stdout.txt` / `asset_proof_stderr.log` 为准，由 HOST 在后续轮次决定是否补记；本轮不回头改写、不谎报。

---

## 5. R3 管线分工与调用规范（承载 `任务书-R3.md` §2「美术管线.md 增一节」内容）

> **为何写在这里、不写进 `美术管线.md`**：本次 HOST 指令明确「R2 已产出的 `…`、`美术管线.md` 等**一律不重做**，只补齐 R3 新增 / 缺失项与 `ASSET-PROOF.md` 实跑记录」。故本轮**不改动** R2 原文（含 `美术管线.md` §10 全部章节）。经核对，R2 的 `美术管线.md` §10.4 已写入「ComfyUI 主路线 / qwen-image 备选分工 / `grid_slice.py`·`find_loop_frame.py`·`rembg_matting.py` 后处理位置 / `quantize.py` 易混澄清 / 单 GPU job 规范」，§7 已有显存分级降级表。为满足 R3 交付清单的文字要求又不碰冻结件，把 R3 需补记的内容集中承载于本 R3 新增文件，并在 `DONE-R3.md` 如实登记该处理依据。

### 5.1 主路线与备选分工（不颠倒）

| 角色 | 定位 | 用途 |
|---|---|---|
| **ComfyUI（主美术路线）** | 用户 23:00 明确「所有美术素材可以用 ComfyUI 制作」；契约 §9.3 / §10、`00-工具链接入说明.md` §6 | W1~W5 主管线：LoRA 固定画风、ControlNet OpenPose 姿态锁定、LayerDiffuse 透明底、ImageMagick 降采样、Aseprite 手工修帧；`GET /object_info` 6 类自定义节点核对 |
| **qwen-image（本地备选 / 补充）** | 同为零付费的本地备选，**不取代** ComfyUI | 姿势基准图 / kit 图 / 装饰层底稿；本机 `D:\godogen_assets\image\`，权重 30.84 GiB，首次出图须 `--quant nf4` / CPU offload |

### 5.2 后处理脚本在管线中的位置（如实标注，不臆造）

| 脚本 | 位置 | 作用 |
|---|---|---|
| `asset-gen/tools/grid_slice.py` | **出图之后、切帧注册之前** | 把 kit 图切成等尺寸帧；对应 `import.json` 的 `columns` / `rows` / `frame_width` / `frame_height` |
| `find_loop_frame.py` | **帧条定版阶段** | 找循环帧，确定 `actions[].start_frame` / `end_frame` / `loop` |
| `rembg_matting.py` | **透明底兜底**（LayerDiffuse / RGBA 出图失败时） | 抠图补底，保证装饰层非装饰区 `(0,0,0,0)` 全透明 |
| `loop_audio.py` | **音频侧后处理**（与图像管线并行、非串联） | 本地音效循环拼接；`00-工具链接入说明.md` §6 明确音效走 `loop_audio.py` / 本地合成，`stable-audio`(gated 403) 不可用、不绕过。它**不是**图像处理节点，此处如实定位，不把它塞进图像管线 |

> 图像后处理链：ComfyUI 主产出（或 qwen-image 备选底稿）→ `grid_slice.py` 切帧 → `find_loop_frame.py` 定循环 → `rembg_matting.py` 兜底抠图 → Aseprite 人工精修 → 256 色索引板收敛（ComfyUI / Aseprite / ImageMagick）→ `import.json` + `delivery_manifest.json` 交付。

### 5.3 三条经验（`00-工具链接入说明.md` §4.1，与 128px 基准画布对齐）

1. **设计显示尺寸 ≥128px**：1024px 直接降到 64px 会糊；用粗平涂造型、硬边 1px 轮廓，按 `palette_256.json::spec.canvas_base_px=128` 设计，再降采样到 32×32 交付帧。
2. **kit 切片**：先出 kit 图，再用 `grid_slice.py` 切片，别指望单张图直接当帧条。
3. **只生成一个方向、运行时翻转**：一致性做法是先出一张 hero 素材、其余用 `qwen-image edit -i hero.png` 只改差异；方向左右会错，故只生成一个方向，左右由运行时翻转。

### 5.4 一次只跑一个 GPU job 的调用规范（任务书 §3 / `00-工具链接入说明.md` §5）

- `qwen-image` / `qwen-tts` / `gen-moves` 各自加载模型，**分钟级、禁止并行**；CPU 工具（`add-moves` / `grip-prop` / `lipsync`）可与一个 GPU job 重叠。
- 统一入口 `python D:\godogen_assets\bin\godogen_win.py --cmd <tool> ... --json`；`-o` **必须**指向项目内路径。
- stdout 只收路径 / 单个 JSON；进度走 stderr，**stderr 存文件、只在失败 / 异常时读**；用长 timeout 或后台。
- 不设 `HF_HUB_OFFLINE=1`；`huggingface.co` 直连被代理 502 挡，靠 `HF_ENDPOINT=https://hf-mirror.com` + 本地 31G 缓存命中。
- 每张 PNG 都要人眼看（alpha 在对比色上判）；本轮无 PNG，见 §4 如实阻塞。

---

## 6. 未完成项与阻塞（如实，非谎报）

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| 1 | `qwen-image --quant nf4` 首次出图实跑结论 | **未完成 / 阻塞（进行中）** | 已真跑启动、单 GPU job、权重 nf4 量化加载中（§3）；本轮窗口内未产 PNG / 未出结果 JSON。不宣称已能出图、不伪造输出；最终以 `asset_proof_stdout.txt` / `asset_proof_stderr.log` 为准 |
| 2 | ComfyUI `GET /object_info` 6 类节点核对 | **阻塞** | ComfyUI 本机路径 / 工作流 JSON 未登记（`00-工具链接入说明.md` §7），未臆造地址、未尝试连接、未绕过 |
| 3 | `style_anchor.png` / 128px 精灵表 / OpenPose 骨架库 | **未产出** | 本机未跑出图，Rank-4 下无任何图片文件；不伪造 |
| 4 | 256 色收敛 / alpha 人眼判定 / 降 128px 发糊检查 | **无法执行** | 无源 PNG，见 §4；收敛路线已写明，不混用 `image/quantize.py` |
| 5 | 付费 API / `stable-audio`(gated 403) / `gen3d` / `mia-rig` | **禁用 / 不碰** | 不申请、不补装、不碰 WSL、不绕过；音效走本地合成 / `loop_audio.py` |
| 6 | 显存档位 A~D 实测 | **未实测** | `pipeline_tier=D` 仅为 R2 采用的降级路线、非显存实测结论；本轮只实测到加载阶段 14203 MiB（非最终峰值） |
| 7 | Godot 三段构建门禁 | **不适用** | 本工位按 `README.md` §1 不产出 `.gd` / `.tscn` / `.tres` / shader、不建 Godot 工程；交付件为 JSON + Markdown，无门禁对象，不谎报跑过 |

---

## 7. 合规声明

- 只写 `Rank-4\`（本文件、`DONE-R3.md`、实跑日志与预期 PNG 均在此）；唯一例外 `command_center\ai\4\outbox\` 回执 JSON。**未写群聊总线**（本次 HOST 硬性约束「不写总线」优先于任务书 §5 的追加消息要求，已在 `DONE-R3.md` 登记）、未自行 `git commit` / `push`。
- 零付费 / 零外部依赖；ComfyUI 仍是主美术路线，qwen-image 仅为同为零付费的本地备选、不取代。
- `image/quantize.py` 是 DiT 权重量化器，**未**用作 256 色调色板量化器。
- 默认不刺探：未扫别人工位、未轮询、未写探针 / 测量 / preflight 脚本；开工只读一次总线。
- 中文 UTF-8；本文件内嵌 JSON 块合法可解析（见 `DONE-R3.md` 自检）。
- **不宣称已能出图、不伪造输出**：这是本文件最重要的一条。
