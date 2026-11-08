# 4 号工位：美术管线与工具链（交付说明）

> 状态：**7 个交付文件齐全，JSON 全部合法可解析**。本目录为 4 号唯一写入位置，未改动总纲、协作契约、README 导航、其它工位任务书或其它编号文件夹。
> 派单依据：`Rank-4/任务书.md`；只读输入：`00-项目总纲.md`、`00-协作契约.md`。

---

## 1. 模块目标

负责总纲**第 1 章**（WorkBuddy 驱动层 / Godot MCP / 专家角色与使用边界）、**第 2 章**（ComfyUI 像素管线）、**HD-2D 视觉规范**、**资产交付契约**。

一句话：把《八方旅人》式的 HD-2D 视觉基调落成**可执行、可冻结、可核对**的色号 / 层数 / 系数 / 帧规格 / 参数区间，并给出两条可 API 调用的本地 ComfyUI 出图管线、I-5 资产交付格式、M0 工具链真跑验证步骤，以及 M0~M6 各阶段的资产供给表。

**明确不负责**：场景树与渲染实现（1 号）、战斗逻辑与数值（2 号）、存档与 RPG（3 号）。本工位不产出 `.gd` / `.tscn` / `.tres` / shader，不建 Godot 工程。

**零付费 / 零外部依赖**：全程只用本地 ComfyUI 与程序化 `_draw()` 占位，无云服务、无外部素材生成服务、无花费确认项。

---

## 2. 交付清单（7 个文件，均在 `F:\Game\aierdengfahuan\teamwork\Rank-4\`）

| # | 文件 | 内容 | 关键落地件 |
|---|---|---|---|
| 1 | `README.md` | 模块目标 / 交付清单 / 接口摘要 / 未完成项 / **待主 AI 裁决项** | 本文件 |
| 2 | `美术管线.md` | 两条管线 W1~W5 节点级说明、**可调用 ComfyUI API JSON 工作流骨架**（管线 1 / 管线 2 / 请求体各 1 份合法 JSON）、像素风格锁定具体参数、风格一致性三层约束、AI 量 / 人工魂边界表、**本地显存分级降级表（A~D 档）**、质量闸门 | 2 份完整工作流 JSON |
| 3 | `HD-2D视觉规范.md` | 32 色 hex 调色板 + 6 色主板 + L0~L8 明度阶梯、10 层景深与视差系数表、体积光 / 光尘 / 湿地倒影 / bloom 实现挂点与参数区间、金线深蓝 UI 规范、32px 角色与像素颗粒度硬约束、**程序化 `_draw()` 占位方案**（含可直接抄的默认参数表） | §7 占位方案，M0 零资产可跑 |
| 4 | `工具链配置.md` | 完整 `mcp.json`（Windows 主配置 + 跨平台版）、Godot 4 PATH、专家角色（节点通 / 游戏逻辑 / 游戏美术师）分工表、WorkBuddy「能做 / 不要让它做」边界表、**M0 连通性验证 10 步真跑**（创建节点 → 修改属性 → 读回确认）、Godot 4.x 小版本兼容性 12 项检查清单 | 2 份合法 `mcp.json` |
| 5 | `资产交付契约.md` | `res://assets/generated/<品类>/` 目录规范（6 品类）、`import.json` **15+ 完整字段定义 + 2 份合法示例**、`delivery_manifest.json` 合法示例、spritesheet 命名、装饰层 RGBA 逐像素对齐 9 条硬约束、Godot 导入期望值、I-5 对 1 号交付清单格式与退回条件 | 3 份合法 JSON 示例 |
| 6 | `prompt_skeleton.json` | 固定 Prompt 骨架（正向 / 负向 / 风格 / 光照 / 调色板 / LoRA 触发词 / ControlNet / IP-Adapter / LayerDiffuse / 降采样 / 采样 / seed 锁定），**全份只有一个可替换槽位 `[SUBJECT]`**（字面仅出现 1 次），附使用说明 9 条与合规声明 | 独立合法 JSON |
| 7 | `接口契约.md` | 对齐 I-5 / I-6 / I-4，列出 4 号对 1 号的依赖与交付物、对外资源字段表、**M0~M6 各阶段交付表**（含消费方 / 前置依赖 / 验收标准）、跨阶段常驻交付与排期依赖摘要 | M0~M6 可汇总表 |

### 2.1 JSON 合法性

独立 JSON 文件 1 份（`prompt_skeleton.json`）；文档内嵌 JSON 块共 8 份：`美术管线.md` 3 份、`工具链配置.md` 2 份、`资产交付契约.md` 3 份。**全部经解析校验通过，无注释、无尾逗号、引号均为 ASCII 直引号**。

### 2.2 未产出（按任务书硬性约束，非遗漏）

- 未写任何探针 / 测量 / preflight 脚本 —— 验证全部为人工操作或真跑一次 MCP 调用 / API 调用。
- 未产出 `.gd` / `.tscn` / `.tres` / shader —— 属 1 号范围。
- 未生成实际 PNG 资产 —— 本工位交付的是规格与契约，实际出图在 M0 真跑阶段按本目录文档执行。
- 未修改 Godot 工程设置 —— `import.json` 里只声明 `expected_import_settings` 供 1 号核对。

---

## 3. 对外接口摘要

| 编号 | 方向 | 4 号交付 | 消费方动作 |
|---|---|---|---|
| **I-5** | 4 → 1 | `assets/generated/<品类>/` 下 spritesheet + 同级 `import.json` + 批次 `delivery_manifest.json` | 1 号按清单切帧注册、把 `pose_names` 注册到 I-4 的 `set_pose()`、按 `aligned_with` 叠加装饰层（**禁止运行时偏移校准**） |
| **I-6** | 4 → 主 AI | `接口契约.md` §4 的 M0~M6 分阶段交付表 | 主 AI 汇总排期 |
| I-4 | 1 → 2（4 号间接消费） | 4 号的 `pose_names` 必须落在 I-4 可接受的 `pose_name` 集合内 | 1 号 / 2 号冻结枚举后通知 4 号 |

> 4 号**不提供运行时信号或方法**：对外接口全部是资源字段（`import.json` / `delivery_manifest.json` / `prompt_skeleton.json`）。字段清单见 `接口契约.md` §2.2。

---

## 4. 未完成项（如实列出）

| # | 项 | 状态 | 计划 |
|---|---|---|---|
| 1 | 实际 PNG 精灵表 / 风格锚点图 / OpenPose 骨架库 | 未产出 | M0 真跑阶段按 `美术管线.md` §3 工作流生成，落 `assets/generated/` |
| 2 | 本地 ComfyUI 自定义节点是否齐备（IP-Adapter / Openpose 预处理 / LayerDiffuse / AnimateDiff / SpritesheetAssembler / RGBAAlphaMask） | 未验证 | M0 用 `GET /object_info` 人工核对一次；缺节点按 `美术管线.md` §7 降级 |
| 3 | 本地显存档位实测（A/B/C/D 走哪一档） | 未验证 | M0 真跑时确认，写进 `delivery_manifest.json` 的 `pipeline_tier` / `fallback_route` |
| 4 | Godot 版本 / MCP 包版本 / `tools/list` 实际工具名 | 未验证 | M0 连通性验证第 0/2/3 步人工抄录，交主 AI 汇总 |
| 5 | `pose_name` 最终枚举、像素→米缩放比、导入设置实际值 | 待 1 号提供 | M0 内闭环，冻结后统一更新 `import.json` |
| 6 | 主角 / Boss / 关键场景的 Aseprite 人工精修 | 未开始（人工环节） | M1 / M5，`human_refine` 必须为 `done` 才允许交付 |
| 7 | 视觉规范中的 3 条「假设」（基准分辨率 / 缩放比 / 静态分层模糊） | 待确认 | 见 §5 裁决项 |

---

## 5. 待主 AI 裁决项（不改任何别人文件，仅上报）

> 按契约第 7 节，跨模块冲突一律在此登记，由主 AI 在 `00-汇总.md` 统一裁决。4 号不修改总纲、契约、其它工位文件。

| # | 冲突 / 待定 | 4 号当前处理 | 请主 AI 裁决 |
|---|---|---|---|
| **A1** | **目录命名不一致**：任务书 §0 与契约 §1 写「唯一可写目录 `teamwork\4\`」，但磁盘实际工位目录为 `Rank-1`~`Rank-4`，任务书文件本身在 `Rank-4\任务书.md`；用户派单也明确指定「只负责 Rank-4 文件夹」 | 按用户指令把 7 个文件落在 `teamwork\Rank-4\`，未新建 `teamwork\4\`、未写根目录 | 确认 `Rank-4` ≡ 逻辑 `4\` 的路径映射；汇总时按此路径读取，避免 4 路产出被判为缺件 |
| **A2** | **总纲 §6「云 ComfyUI」分支**：与项目既定决策（去掉付费素材线、零外部依赖）冲突 | 在 `美术管线.md` §7 明确标注该分支**已废弃**，替代方案为纯本地 A~D 档降级（跳过图生视频→单帧+手工补帧 / 程序化 `_draw()` 占位）；未修改总纲原文 | 确认是否在总纲中正式删除该分支，或仅以「既定决策覆盖」方式记录 |
| **A3** | **I-4 `pose_name` 最终枚举未定** | `import.json` 与 `prompt_skeleton.json` 用建议集合 `idle/walk/jump/roll/attack/hit/death`，标注「待冻结」 | 请 1 号 / 2 号给出最终枚举，主 AI 冻结后 4 号统一重出受影响 `import.json` |
| **A4** | **`Hybrid2D3D` 像素→米缩放比与 AABB 口径未定** | 视觉规范锁 32px + 底部中心锚点 (16,31)，缩放比标为假设 | 请 1 号给实际缩放比；若与 32px 假设冲突，需联合调整视觉规范 §6 |
| **A5** | **`default_texture_filter=0` 落地责任** | 契约 §5 明确由 1 号落地；4 号只在 `import.json.expected_import_settings` 声明期望值 | 确认责任归属与核对方式（1 号落地后是否需回报 4 号） |
| **A6** | **`@coding-solo/godot-mcp` 工具名随版本变化** | `工具链配置.md` §5 用语义名描述，明确要求以 `tools/list` 真跑返回为准；不写探针脚本 | 请主 AI 在 M0 汇总时记录实际包版本与工具名清单，作为后续工位统一口径 |
| **A7** | **`import.json` 文件命名** | 采用 `<name>_vN.import.json`（与 PNG 同级同名） | 若 1 号习惯 `<name>.json`，需统一后冻结，4 号再批量改名 |
| **A8** | **基准分辨率 640×360 / 整数倍 3x** | 视觉规范 §3 写为设计基准，标为假设 | 请 1 号按目标机型确认缓冲尺寸与放大倍数；变更只影响系数换算，不影响层数与色板 |
| **A9** | **风格锚点图 `style_anchor.png` 来源** | 规范定义为「全项目唯一、不得替换」，但未指定由谁产出 | 建议 M0 由 4 号本地 ComfyUI 出 1 张基准图 + 人工确认后冻结；请主 AI 确认归属 |
| **A10** | **契约 §4 要求「对外提供的信号、方法、资源字段」** | 4 号不产出 `.gd`，故只提供资源字段（`接口契约.md` §2.2），无运行时信号 / 方法 | 确认此口径满足契约；若要求必须有方法级接口，需主 AI 明确是否越界到 1 号范围 |

---

## 6. 交付给主 AI 的实际文件路径列表

```text
F:\Game\aierdengfahuan\teamwork\Rank-4\README.md
F:\Game\aierdengfahuan\teamwork\Rank-4\美术管线.md
F:\Game\aierdengfahuan\teamwork\Rank-4\HD-2D视觉规范.md
F:\Game\aierdengfahuan\teamwork\Rank-4\工具链配置.md
F:\Game\aierdengfahuan\teamwork\Rank-4\资产交付契约.md
F:\Game\aierdengfahuan\teamwork\Rank-4\prompt_skeleton.json
F:\Game\aierdengfahuan\teamwork\Rank-4\接口契约.md
```

（`Rank-4\任务书.md` 为主 AI 派单，只读，未修改。）

---

## 7. 汇总要点（给主 AI 快速取用）

1. **风格已冻结**：32 色 hex 色板、10 层景深与视差系数、32px 角色硬约束、金线深蓝 UI 规范，均可直接作为跨模块验收基准。
2. **M0 有零资产退路**：`HD-2D视觉规范.md` §7 的程序化 `_draw()` 占位方案可在没有任何 PNG / ComfyUI 的情况下跑通完整 HD-2D 画面，保证 M0「能自己上手玩」。
3. **两条出图管线可 API 调用**：`美术管线.md` §3 的两份完整 ComfyUI 工作流 JSON 节点/输入/输出齐全，不依赖手拖节点图。
4. **显存不足不引入云服务**：A~D 档纯本地降级表已给，总纲 §6 云分支标注废弃。
5. **I-5 可直接对接**：`import.json` 15+ 字段 + 3 份合法 JSON 示例 + 装饰层 9 条逐像素对齐约束 + 退回条件，1 号按清单导入即可。
6. **I-6 可汇总**：`接口契约.md` §4 的 M0~M6 表每行含交付物 / 消费方 / 前置依赖 / 验收标准；Boss 人工精修（M5）周期最长，建议提前 1 个里程碑启动。
7. **最大风险**：A1 目录命名映射与 A3 pose_name 枚举未冻结，可能影响 4 路产出汇总与 M0 资产注册。

---

## 8. R2 交付清单（2026-11-08 追加；§1~§7 首轮内容不改，只追加）

> 依据：`Rank-4/任务书-R2.md`（首轮 `任务书.md` 保留不改）。R3 为排队包，本轮不执行。只写 `Rank-4\`，未写总线 / 台账 / git（由 HOST 统一收尾）。

### 8.1 本轮实际交付 / 更新文件

| # | 文件 | 动作 | 说明 |
|---|---|---|---|
| 1 | `palette_256.json` | 新增 | ≤256 色索引调色板，冻结 32 色 + 语义分组 + L0~L8 |
| 2 | `pose_names.json` | 新增 | 冻结 pose 枚举 + `p1_`/`p2_` 前缀 + `import.json.actions[].name` 映射 |
| 3 | `import.json` | 新增 | R2 全字段样例（`canvas_base_px=128` / `palette_id` / 冻结 pose / 四项期望导入值） |
| 4 | `player_idle_v1.import.json` | 新增 | 按 `<name>_vN.import.json`（A7）命名的实例 |
| 5 | `delivery_manifest.json` | 新增 | M0 占位批次，含 `pipeline_tier` / `fallback_route` / `palette_id` / `canvas_base_px` / `human_refine` |
| 6 | `hd2d_placeholder_params.json` | 新增 | 程序化 `_draw()` 占位参数表（只出参数，不产 `.gd`/`.tscn`） |
| 7 | `HD-2D视觉规范.md` | 追加 §10 | R2 冻结口径：128px + 256 色板、三层尺寸、待 HOST 转交值 |
| 8 | `资产交付契约.md` | 追加 §8 | 新增字段 / A7 命名 / 调色板引用 / R1 不一致登记 |
| 9 | `美术管线.md` | 追加 §10 | M0 本地管线验证：节点清单 / 显存档位表 / 降级路径 / qwen-image 边界 |
| 10 | `README.md` | 追加 §8 | 本节 |
| 11 | `DONE-R2.md` | 新增 | 完成标志（HOST 监测只认此文件） |

### 8.2 本轮验证结论（详见 `DONE-R2.md`）

- 所有独立 JSON + 文档内嵌 JSON 块经解析器**真跑**，实际输出结论见 `DONE-R2.md` 自检。
- `import.json` 字段与 R2 §6 第 7 条（128px 基准画布 + ≤256 色索引板）、第 6 条（pose 冻结枚举含 `p1_`/`p2_`）**交叉核对一致**，实际核对输出见 `DONE-R2.md`。
- M0 本地出图 / ComfyUI 节点核对 / 显存档位实测：能跑的真跑、跑不通的如实写阻塞，见 `DONE-R2.md`。

### 8.3 仍未完成项与阻塞（如实）

| # | 项 | 状态 |
|---|---|---|
| 1 | 实际 PNG 精灵表 / `style_anchor.png` / OpenPose 骨架库 | 未产出（M0 本地出图未跑通，不伪造） |
| 2 | ComfyUI `GET /object_info` 6 类节点核对 | 阻塞：ComfyUI 本机路径未登记，不臆造 |
| 3 | 显存档位 A~D 实测 | 阻塞：未实测，`pipeline_tier=D` 仅为本轮降级路线 |
| 4 | `qwen-image --quant nf4` 首次出图 | 见 `DONE-R2.md`（本机至今只跑通过 `qwen-tts`） |
| 5 | 1 号的基准分辨率 / 放大倍数 / 像素→米缩放比 / AABB 冻结值 | **待 HOST 转交**，不臆断 |
| 6 | `prompt_skeleton.json` 的 `seed_lock.action_offset` 与 R2 冻结 pose 不一致 | 待 HOST 裁决后整体升 v2 回改（本轮不擅改冻结件） |
| 7 | `128bit` 原词歧义 | 仍登记在 §5 待裁决，**不自行改口径** |
| 8 | 主角 / Boss / 关键场景 Aseprite 人工精修 | 未开始（人工环节，M1/M5） |

### 8.4 硬约束遵守声明

- 只写 `Rank-4\`；未写 `Rank-1/2/3\`、未写 teamwork 根目录、未改总纲 / 契约 / 任务书 / 群聊总线。
- 开工总线只读一次；未扫别人工位、未轮询、未写探针 / 测量 / preflight 脚本。
- ComfyUI 仍是主美术路线，qwen-image 仅为本地备选；付费 API 一律禁用，不列「确认花费」为待办；`stable-audio`(gated 403) / `gen3d` / `mia-rig` 不申请、不补装、不碰 WSL、不绕过。
- `image/quantize.py` 未用作 256 色调色板量化器（它是 DiT 权重量化器）。
- 未产 `.gd` / `.tscn`；未自行 git commit / push；未写群聊总线（HOST 统一代发）。
- R3 排队包本轮未打开、未执行。
