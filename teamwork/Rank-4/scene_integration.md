# scene_integration.md · R7 程序化画面接入场景（Rank-4 交付 · 供 Rank-1 构建脚本直接消费）

> 轮次：**R7（程序化画面接入场景）**｜派单：`cmd-20261109-024906-804-A4`｜主任务书：`Rank-4\任务书-R7.md`
> 授权：`MSG-20261109-0249-HOST` 续派、`MSG-20261109-0223-HOST` 工程根落位裁决（`godot\assets\generated\` 与 `godot\scripts\render\` 属 Rank-4 可写）
> 唯一可写：`Rank-4\`（本文档、`DONE-R7.md`）+ `godot\scripts\render\hd2d_placeholder_attach.gd`；回执例外 `teamwork\command_center\ai\4\outbox\`
> **不写 `godot\project.godot`（Rank-1 独占）**、**不写 `godot\scenes\`（Rank-1 独占场景）**、不覆盖既有文件、不写其它工位 / 总线 / 总纲 / 契约、不自行 git
> 本轮定位：**因为 `scenes\` 归 Rank-1 独占，本轮不直接改 `courtyard.tscn`**，改为产出「挂载辅助脚本 + 可直接被构建脚本消费的接入说明」，由 1 号在自己的构建脚本里用**一行调用**完成挂载；出图仍无 PNG、ComfyUI 路径仍未登记 → 如实记阻塞，不宣称已能出图

---

## 0. 结论速览（先读这里）

| 项 | 本轮结论 |
|---|---|
| 为什么不直接改 `courtyard.tscn` | `godot\scenes\` 与 `godot\project.godot` 均为 **Rank-1 独占**；按「不得写 scenes / 不覆盖既有文件」硬约束，本轮不碰场景文件，只交付接入件 |
| 交付件 1 | `godot\scripts\render\hd2d_placeholder_attach.gd`（新建，Godot 4 合法 GDScript，3776 字节 / 76 行，`class_name HD2DPlaceholderAttach`，三个静态方法） |
| 交付件 2 | 本文档 `Rank-4\scene_integration.md`（接入语义 + API 契约 + 一行调用 + 导入验证结论） |
| **Rank-1 一行接入调用** | `HD2D_ATTACH.attach(root, {"canvas_layer": -10, "integer_scale": 2})`（详见 §2） |
| 是否宣称已渲染可见 | **否**。本轮只做 `--check-only --script` 语法门禁 + 静态审阅，**未做场景实例化渲染验收**（`scenes\` 归 1 号、本轮不写场景、未启动额外 Godot 运行实例）；实际挂载与可见性由 Rank-1 在其构建脚本真跑后确认 |
| 出图 / ComfyUI | 无 PNG、日志停在 shard 1/2、ComfyUI 路径未登记 → 如实记阻塞，**不宣称已能出图、不伪造输出**（详见 §6） |
| 路线优先级 | **ComfyUI 仍是主美术路线**；`qwen-image` 仅本地零付费备选；程序化 `_draw()` 仅 M0 占位 / 显存不足降级，不取代二者 |

---

## 1. 场景只读结构与「背景层」语义

开工对 `godot\scenes\courtyard.tscn` 做了**只读**查看（本轮一个字节未改）。其实际结构（R4 `build_courtyard.gd` 程序化生成）为：

```text
Courtyard (Node3D)                                  ← 场景根
└── SubViewportContainer (texture_filter=1 / stretch_shrink=2)
    └── SubViewport (640×360, own_world_3d=true)
        ├── Camera3D / SunLight / WorldEnvironment
        ├── Terrain (GroundPlate / TerraceLow / TerraceHigh / CliffRim)
        ├── BackdropFar / BackdropMid        ← 既有「背景层」占位（Node3D，空）
        ├── WetReflection (visible=false)
        ├── Player → Hybrid2D3DAnimatedSprite → PixelSprite
        ├── ChunkRoot
        └── FXLayer (CanvasLayer, layer=10) → LightDust (Node2D, visible=false)
```

- 既有 `BackdropFar` / `BackdropMid` / `WetReflection` 是 **Node3D 空占位**，本轮不往里塞节点（那是 1 号场景结构，不覆盖既有节点）。
- `hd2d_placeholder.gd`（R6 装配，`extends Node2D`）是 **CanvasItem**：单节点、单次 `_draw()` 按 10 步顺序画完 9 视差层 + 1 步湿地倒影、体积光、光尘、bloom、32×32 像素实体、金线深蓝 UI；零外部依赖、纯程序化绘制。
- 因此「背景层」在本轮落地为：**在传入的 parent 下新建一个专用 `CanvasLayer`，再把挂了 `hd2d_placeholder.gd` 的 `Node2D` 挂进该层**。不建场景树分支到 1 号既有节点、不改场景文件。

---

## 2. Rank-1 的一行接入调用方式

### 2.1 主推（与 `build_courtyard.gd` 既有 `const HYBRID_SCRIPT_PATH` 风格一致）

在 `godot\scripts\build_courtyard.gd` 头部常量区追加**一行声明**：

```gdscript
const HD2D_ATTACH = preload("res://scripts/render/hd2d_placeholder_attach.gd")
```

在 `_build_tree()` 中 `root(Courtyard)` 创建完成、`viewport` 组装之后追加**一行调用**（这就是本轮交付的「一行接入调用方式」）：

```gdscript
HD2D_ATTACH.attach(root, {"canvas_layer": -10, "integer_scale": 2})
```

> 说明：`preload` 常量 + 静态方法调用是 Godot 4 标准写法，**不依赖 `.godot/global_script_class_cache.cfg` 是否已注册新脚本**，适合 `--script` 首次构建运行。`attach.gd` 自身已通过 `--check-only --script` 语法门禁（见 §7）。

### 2.2 备选（class_name 全局类，需全局类缓存已注册 `HD2DPlaceholderAttach`）

```gdscript
HD2DPlaceholderAttach.attach(root, {"canvas_layer": -10, "integer_scale": 2})
```

两种写法**语义完全相同、都只一行调用**：在 `root` 下新建 `HD2DPlaceholderLayer`(CanvasLayer, layer=-10) → `HD2DPlaceholder`(Node2D, 挂 `hd2d_placeholder.gd`)。返回的 `Node2D` 可由 1 号持有，用于后续绑定 `cam_x / cam_y` 或退出时 `detach()`。

### 2.3 运行时场景脚本同样可用（不局限于构建脚本）

```gdscript
var bg: Node2D = HD2DPlaceholderAttach.attach(self, {"cam_x": 0.0, "cam_y": 0.0})
```

### 2.4 边界（必须遵守）

- 1 号只**在自己文件里**追加上述两行；`courtyard.tscn` 由 `build_courtyard.gd` 重新 `pack/save` 生成，本工位不写、不覆盖。
- `attach()` **不设 `owner`**：构建脚本场景树的 owner 链仍由 1 号既有 `_assign_owner(root, root)` 统一处理；运行时挂载无需 owner。
- 本轮**未**修改 `build_courtyard.gd`、`courtyard.tscn`、`project.godot` 任何一个字节。

---

## 3. `hd2d_placeholder_attach.gd` API 契约

### 3.1 常量

| 常量 | 值 | 含义 |
|---|---|---|
| `PLACEHOLDER_SCRIPT_PATH` | `res://scripts/render/hd2d_placeholder.gd` | 被挂载的既有占位脚本（R6 冻结件，本轮只 `load`、不改、不覆盖） |
| `LAYER_NAME` | `HD2DPlaceholderLayer` | 新建的 CanvasLayer 节点名 |
| `NODE_NAME` | `HD2DPlaceholder` | 新建的 Node2D 节点名 |
| `DEFAULT_CANVAS_LAYER` | `-10` | 背景层绘制序（靠前；见 §4 取舍） |
| `DEFAULT_INTEGER_SCALE` | `2` | 对齐 `project.godot` 的 `render/integer_upscale_factor=2` 与 1280×720 窗口 |

### 3.2 静态方法

| 方法 | 签名 | 行为 |
|---|---|---|
| `attach` | `static func attach(parent: Node, config: Dictionary = {}) -> Node2D` | 新建 CanvasLayer + 挂好脚本的 Node2D 并 `add_child`；返回占位 Node2D。`parent == null` 或脚本 `load` 失败 → `push_warning` 并返回 `null`（**不伪造输出**） |
| `find_placeholder` | `static func find_placeholder(parent: Node) -> Node2D` | 查已挂载的占位节点；未挂载返回 `null` |
| `detach` | `static func detach(parent: Node) -> bool` | 退出条件辅助：移除背景层及其占位节点，`queue_free`；不存在返回 `false` |

- **幂等**：`attach()` 先 `find_placeholder(parent)`，若同名背景层已存在则**复用并返回**其中节点，不重复挂载、不覆盖既有节点。
- **零外部依赖**：只用 `load()` 加载工程内既有 `.gd`，不加载任何 PNG / 贴图 / 插件 / 云服务 / 付费 API；占位脚本自身也零外部依赖。
- 新建 Node2D 显式设 `texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST`，与项目级 Nearest 口径对齐。

### 3.3 `config` 可覆盖键

| 键 | 类型 | 默认 | 落到 `hd2d_placeholder.gd` 的属性 |
|---|---|---|---|
| `canvas_layer` | int | `-10` | `CanvasLayer.layer` |
| `integer_scale` | int | `2` | `@export integer_scale`（脚本内 clamp 2~4） |
| `placeholder_enabled` | bool | `true` | `@export placeholder_enabled` |
| `cam_x` | float | `0.0` | `@export cam_x`（视差水平位移） |
| `cam_y` | float | `0.0` | `@export cam_y`（sky/far 垂直位移） |
| `light_pos` | Vector2 | 脚本默认 `(452, 92)` | `@export light_pos`（体积光 / bloom 光源） |

> 全部用 `int()/float()/bool()` 显式转换后 `set()`，避免 Godot 4 静态检查把 Variant 推断当错误（R6 §2.3 的同类处置）。

---

## 4. 挂载点 / 缩放 / 遮挡取舍（如实登记为 Rank-1 裁决点，不擅改）

| # | 事项 | 本轮结论 |
|---|---|---|
| 1 | `hd2d_placeholder.gd` 的 `_apply_integer_scale()` 用 `clampi(integer_scale, 2, 4)`，**无法设为 1** | 这是 R6 冻结件既有行为，本轮**不覆盖、不改写**。故默认 `integer_scale=2`（640×360×2 = 1280×720，正好对齐窗口尺寸 / `stretch_shrink=2` / `integer_upscale_factor=2`） |
| 2 | 若 1 号把占位挂进 `SubViewport`(640×360) 内部 | `scale≥2` 会把 640×360 缓冲放大出界 → **需 Rank-1 裁决**（或纹理层接入时整体替换为 SubViewport 方案）。本轮不擅改冻结脚本、不代 1 号决定 |
| 3 | 遮挡顺序 | `courtyard.tscn` 的 `SubViewportContainer` 承载不透明 3D 背景（`WorldEnvironment.background_color`）+ `FXLayer`(layer=10) 前景。`layer=-10` 的 2D 背景层绘制序靠前，**实际是否可见由 1 号结合场景 layer 顺序裁决**；本轮不宣称「已渲染可见」、不改场景 |
| 4 | 退出条件 | `assets/generated/bg_layers/` 与 `chars/` 有首批合规 spritesheet 且 1 号完成纹理层接入后，调用 `HD2DPlaceholderAttach.detach(root)` 移除本背景层，逐层替换为 `draw_texture_rect()` / Sprite；`placeholder_enabled` 保留为调试开关 |

> 以上 4 项均属「跨工位 / 场景归属」裁决点，按契约 §7 只登记、不擅自改别人的文件，写入本文档供 1 号接入时核对。

---

## 5. 128px 基准画布 + ≤256 色索引调色板「工程根内导入验证」结论

### 5.1 口径 12/12（内联 python 真跑解析，实际 stdout 见 `DONE-R7.md` §2.2）

| 口径 | 冻结值来源 | 工程根落位件实际值 | 结论 |
|---|---|---|---|
| lossless | `import.json::expected_import_settings.compress_mode` | `"lossless"` | PASS |
| 关 mipmaps | `...mipmaps` | `false` | PASS |
| Nearest | `...texture_filter` | `"Nearest"` | PASS |
| 项目级 `default_texture_filter=0` | `...project_default_texture_filter` | `0` | PASS |
| 128px 基准画布 | `import.json::canvas_base_px` | `128` | PASS |
| 128px 基准画布 | `palette_256.json::spec.canvas_base_px` | `128` | PASS |
| ≤256 色索引调色板 | `palette_256.json::spec` | `indexed=true` / `max_colors=256` / `color_count=32` | PASS |

一致性附带：`palette_id=hd2d_index_256_v1` 与 `import.json::palette_id` 一致；`import.json::pose_names` 4 个全在 `pose_names.json::all_frozen_names`（`frozen_name_count=22`）。**12/12 逐项 PASS**。

### 5.2 工程实际 `project.godot` 只读核对（本轮「在工程根内」的加强验证）

- `godot\project.godot` 实际为 `textures/canvas_textures/default_texture_filter=0`（02:52 只读快照第 132 行 / 复核时第 141 行，Rank-1 R8 并行更新使行号下移、键值未变），与 `import.json` 期望值 `0` **一致（True）**。本轮**只读核对、未改一个字节**；并行更新差异如实登记，不冒充。
- 口径纠正如实登记：任务书字面写 `default_texture_filter=0`，Godot 4 合法键为 `textures/canvas_textures/default_texture_filter`（R6 §2.2 / `project.godot` 头注释已纠正，历史误写 `canvas_items` 不写回）。本轮**只读核对、未改 `project.godot` 一个字节**（Rank-1 独占）。
- `import.json` 为 `sample_only=true`（字段样例、非真实资产交付）；其 `palette_ref` 指向 `res://assets/generated/_palette/palette_256.json` 与实际落位 `res://assets/generated/palette_256.json` 平级差异，沿用 R6 §1 登记为「1 号导入时对齐」，本轮不擅改冻结 JSON 字段。

### 5.3 所有 JSON 内联真跑解析结论

落位件 **4/4** + 源 `Rank-4` 独立 JSON **10/10** + `Rank-4\*.md` 行首 `json` 围栏块 **16/16** 全部 `json.load` / `json.loads` 真跑解析通过。本文档与 `DONE-R7.md` 的所有代码块均用 `text` / `gdscript` 标记、不含行首 ```json 围栏，故写完复核仍为 **16/16**（口径自洽，与 R6 §2.6 做法一致）。

---

## 6. 出图 / ComfyUI 阻塞（如实，不臆造）

- **只读**验收（02:52）：`Rank-4\*.png` **无**；`asset_proof_stdout.txt` **0 字节**（mtime 01:05:48）；`asset_proof_stderr.log` **25320 字节**（mtime 01:21:30）停在 `Loading checkpoint shards: 50%|█████ | 1/2 [05:35<05:35, 335.95s/it]`；检查时刻 02:52，约 **91 分钟无新增**；报错类关键字 **0**、完成类关键字 **0**。
- 单一后台 `qwen-image --quant nf4` 出图 job 仍卡在 transformer checkpoint shard 1/2 加载，**无 PNG / 无结果 JSON / 无报错**，未进入去噪 / 写图。
- **未启动第二个 GPU job、未杀 / 未重启 / 未并行**现有 job（本轮所有 Godot 调用均为 `--check-only --script` 静态语法门禁，非 GPU 出图 job）。
- 因此：alpha / 128px / ≤256 色收敛、装饰层逐像素对齐、风格锚图 / 精灵表、显存档位 A~D 峰值实测 **均无法执行 / 阻塞**，不编造校验数据、不伪造 PNG。
- ComfyUI 本机路径与工作流 JSON：沿用 `00-工具链接入说明.md` §7 与本轮 HOST 指令，仍为「待用户提供 / 待刺探指令」，未给出路径 → **登记阻塞，不臆造地址、不尝试连接 `GET /object_info`、不主动扫盘、不绕过**。**ComfyUI 仍是主美术路线**。
- **不宣称已能出图**：本轮交付的是「接入辅助脚本 + 说明文档 + 规格 JSON 口径核对」，不是美术资产产出。

---

## 7. 真跑 / 自检结论（实际输出摘录，完整版见 `DONE-R7.md` §2）

```text
=== 引擎 --headless --path godot --check-only --script（grep SCRIPT ERROR）===
  res://scripts/render/hd2d_placeholder.gd         EXIT=0 | SCRIPT_ERROR_count=0 | Parse_Error_count=0 | ERROR_count=0
  res://scripts/render/hd2d_placeholder_attach.gd  EXIT=0 | SCRIPT_ERROR_count=0 | Parse_Error_count=0 | ERROR_count=0
  输出均仅 Godot Engine v4.7.2.stable.official.ed1daf0bf 版本横幅
=== 内联 python 真跑解析 ===
  落位 JSON 4/4 ｜ 独立 JSON 10/10 ｜ 内嵌 JSON 块 16/16 ｜ 导入口径 12/12
  project.godot default_texture_filter=0 与期望一致 : True
  冻结 9 视差系数 == GDScript 系数 : True ｜ _pass_ 步数 10 ｜ 零外部依赖 : True
  attach 静态方法 ['attach','detach','find_placeholder'] ｜ 幂等 : True ｜ 无 PNG 依赖 : True
```

> 处置：两个脚本均**首次即全绿**，无需像 R6 那样改 `round()` Variant 推断；本轮未改任何既有 `.gd`。`attach.gd` 的 `class_name` 与 `extends` 顺序、静态方法、`set()` 显式类型转换均通过 Godot 4.7.2 静态检查。

---

## 8. 合规声明

- 只写 `Rank-4\`（本文档、`DONE-R7.md`）+ `godot\scripts\render\hd2d_placeholder_attach.gd`（新建，不覆盖既有 `hd2d_placeholder.gd`）；回执例外 `teamwork\command_center\ai\4\outbox\`。**未写 `godot\project.godot`、未写 `godot\scenes\`、未写其它工位 / 工程根其它子目录 / 群聊总线 / 总纲 / 契约 / 任务书**；未自行 `git commit` / `git push`。
- 零付费 / 零外部依赖；付费 API 一律禁用；`stable-audio` / `gen3d` / `mia-rig` 不申请、不补装、不碰 WSL、不绕过。
- 既有件（`hd2d_placeholder.gd`、R2~R6 全部冻结 JSON / DONE / 规范文档、`courtyard.tscn`、`build_courtyard.gd`、`project.godot`）一律**引用、不重做、一个字节未改**。
- 默认不刺探：仅执行任务明确要求的 `Rank-4\*.png` 与两份日志**只读**检查 + 两段 `--check-only --script` 语法门禁，未扫别人工位、未轮询、未写探针 / 测量 / preflight 脚本；`00-群聊总线.md` 开工只读一次。
- 中文 UTF-8；所有独立 JSON 与文档内嵌 `json` 围栏块合法可解析；GDScript 为 Godot 4 合法语法（`--check-only` 通过）。
- **不宣称已能出图、不伪造输出、不拉起第二个 GPU job、不臆造 ComfyUI 路径、不宣称场景已渲染可见**：这是本轮最重要的一条。
