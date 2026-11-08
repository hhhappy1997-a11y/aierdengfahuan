# SPEC-VERDICT-CHECK.md · A8/A9 定型核对记录（Rank-4 R10 交付）

> 轮次：**R10（规格定型核对）**｜派单：`cmd-20261109-040336-525-A4`｜工位：Rank-4 美术管线与工具链
> 依据：`任务书-R10.md`、`00-汇总.md` §4（A8/A9 总指挥裁决）、`ART-SPEC-FINAL.md`、`scene_integration.md`、`DONE-R9.md`、`00-群聊总线.md`（开工只读一次）
> 定位：**只核对、不裁决、不回改**。A9 只确认定型参数一致性、不再反复改挂载取舍；A8 只确认歧义仍登记为「待用户确认、暂按 128px 基准画布理解」、不自行改口径。
> 本轮未新建 / 未改动任何既有 `.gd` / `.tscn` / 规格 JSON / `project.godot`；既有件一律只读引用、一个字节未改。

---

## 0. 结论速览

| 裁决项 | 核对结论 | 真跑 |
|---|---|---|
| **A9** HD-2D 占位画面挂载定型 | `layer=-10` / `integer_scale=2` / `Nearest` 在「接入说明 `scene_integration.md` → 挂载脚本 `hd2d_placeholder_attach.gd` → 场景实例 `courtyard.tscn`」三处逐项一致；`00-汇总.md` §4 A9 记「✅ 已定型」 | 内联 python 只读核对 **11/11 True** |
| **A8** `128bit` 原词歧义 | 6 处登记仍为「待用户确认、暂按 128px 基准画布 + 256 色索引调色板理解」，本轮未改一个字节 | 内联 python 只读核对 **10/10 True** |
| 是否反复改挂载取舍 / 自行改口径 | **否**。4 项取舍仍按 `scene_integration.md` §4 登记为 Rank-1 裁决点，只核对不擅改 | — |

---

## 1. A9 定型参数一致性核对

### 1.1 裁决原文

> `00-汇总.md` §4 A9：按 `scene_integration.md` §3.2 已落地值定型：`layer=-10`、`integer_scale=2`、Nearest；遮挡/缩放 4 项不再反复改 —— ✅ 已定型。
> `00-群聊总线.md` MSG-20261109-0400-HOST：A9 占位画面挂载按 `layer=-10` / `integer_scale=2` / Nearest 定型。

### 1.2 三处逐项核对（只读，实际值均从文件正则提取）

| 参数 | `scene_integration.md` | `godot\scripts\render\hd2d_placeholder_attach.gd` | `godot\scenes\courtyard.tscn` | 一致 |
|---|---|---|---|---|
| `layer` | §2.1 一行调用 `{"canvas_layer": -10, "integer_scale": 2}`；§3.1 `DEFAULT_CANVAS_LAYER=-10`；§3.3 config 默认 `-10` | `:17` `const DEFAULT_CANVAS_LAYER: int = -10`；`:36/:39` `layer.layer = layer_index` | `:122~123` `HD2DPlaceholderLayer` → `layer = -10` | ✅ `-10 / -10 / -10` |
| `integer_scale` | §2.1 一行调用 `"integer_scale": 2`；§3.1 `DEFAULT_INTEGER_SCALE=2`；§3.3 config 默认 `2` | `:18` `const DEFAULT_INTEGER_SCALE: int = 2`；`:45` `set("integer_scale", ...默认 2)` | `:128` `integer_scale = 2` | ✅ `2 / 2 / 2` |
| Nearest | §3.2「新建 Node2D 显式设 `texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST`」；§3.3 同口径 | `:44` `placeholder.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST` | `:126` `texture_filter = 1`（Godot `TEXTURE_FILTER_NEAREST` 枚举值 = 1）；`SubViewportContainer:48` 亦 `texture_filter = 1` | ✅ Nearest / Nearest / 枚举 1 |

> 补充（项目级，只读佐证）：`godot\project.godot` 的 `textures/canvas_textures/default_texture_filter=0` 与 `render/integer_upscale_factor=2`（`DONE-R9.md` §2.4 [E] 已核对 `True`），与 `integer_scale=2` / Nearest 口径一致；本轮未改 `project.godot` 一个字节。

### 1.3 如实登记：脚本导出默认值 `3` 与定型值 `2` 的关系（不是冲突）

- `godot\scripts\render\hd2d_placeholder.gd:23` 为 `@export var integer_scale: int = 3` —— 这是 **R6 冻结件的导出默认值**；`_apply_integer_scale()` 在 `:98~100` 用 `clampi(integer_scale, 2, 4)` 缩放，允许 2/3/4。
- 定型值 `2` 落在**实例化层**：`courtyard.tscn:128` 显式写 `integer_scale = 2`（场景实例覆盖导出默认），`hd2d_placeholder_attach.gd:45` 也用 `set("integer_scale", 2)` 显式覆盖。`scene_integration.md` §4 第 1 项已载明「`clampi` 无法设为 1，故默认 `2`（640×360×2 = 1280×720 对齐窗口）」。
- 因此三处**生效值均为 2**，脚本默认 `3` 只在「未被场景实例 / config 覆盖」时才起作用；本工程已被覆盖。**属「脚本默认 vs 实例覆盖」关系，不构成 A9 参数冲突**，本轮不改写冻结脚本、不反复改挂载取舍。
- 遮挡顺序 / `SubViewport` 内放大出界 / 退出条件等 **4 项取舍**仍按 `scene_integration.md` §4 登记为 Rank-1 裁决点，本轮只核对、不擅改、不代 1 号决定（`ART-SPEC-FINAL.md` §6 #4 同口径）。

### 1.4 真跑实际输出（内联 python 只读；完整一次 stdout 见 `DONE-R10.md` §2.3 [E]）

```text
=== [E] A9 定型参数只读一致性核对（scene_integration.md / 工程根脚本 / courtyard.tscn）===
  [courtyard.tscn] HD2DPlaceholderLayer.layer = -10              = -10  -> True
  [courtyard.tscn] HD2DPlaceholder.texture_filter = 1 (Nearest)  = 1  -> True
  [courtyard.tscn] HD2DPlaceholder.integer_scale = 2             = 2  -> True
  [attach.gd] DEFAULT_CANVAS_LAYER = -10                         = -10  -> True
  [attach.gd] DEFAULT_INTEGER_SCALE = 2                          = 2  -> True
  [attach.gd] placeholder.texture_filter = TEXTURE_FILTER_NEAREST = True  -> True
  [attach.gd] set('integer_scale', config 默认 2) 显式覆盖             = True  -> True
  [scene_integration.md] 一行调用 {canvas_layer:-10, integer_scale:2} = True  -> True
  [scene_integration.md] §3.1 DEFAULT_CANVAS_LAYER=-10 / SCALE=2 = True  -> True
  [scene_integration.md] §3.2 新建 Node2D 显式 TEXTURE_FILTER_NEAREST = True  -> True
  [00-汇总.md §4 A9] layer=-10/integer_scale=2/Nearest/已定型         = True  -> True
  -> A9 定型三值在「接入说明 / 挂载脚本 / 场景实例」三处一致 : True
  [如实登记] hd2d_placeholder.gd:23 @export integer_scale 默认 = 3（R6 冻结件既有默认）
              被 courtyard.tscn:128 实例值 2 与 attach.gd:45 set() 覆盖为 2；_apply_integer_scale clamp 2~4
              -> 属「脚本默认 vs 实例覆盖」关系，不是参数冲突；本轮只核对、不改挂载取舍、不反复改口径 : True
```

---

## 2. A8 `128bit` 歧义口径核对

### 2.1 裁决原文

> `00-汇总.md` §4 A8：**暂按「128px 基准画布 + 256 色索引调色板」理解**（契约 §9.3）；该词来自用户原文，**不自行改口径，以用户为准** —— ⏸ 待用户确认。
> `00-群聊总线.md` MSG-20261109-0400-HOST：A8 `128bit` 歧义不自行改口径、待用户确认（暂按 128px 基准画布理解）。

### 2.2 登记位置逐项核对（只读）

| # | 文件 | 登记口径 | 核对 |
|---|---|---|---|
| 1 | `00-汇总.md` §4 A8（:59） | 「暂按 128px 基准画布理解」/「待用户确认」/「不自行改口径，以用户为准」 | ✅ True |
| 2 | `ART-SPEC-FINAL.md` §1（:34） | 「`128bit` 原词歧义仍登记在 `README.md` 待裁决……不自行改口径」 | ✅ True |
| 3 | `ART-SPEC-FINAL.md` §6 #1（:144） | 「暂按 128px 理解，不自行改口径」 | ✅ True |
| 4 | `README.md` §8.3 #7（:154） | 「仍登记在 §5 待裁决，不自行改口径」 | ✅ True |
| 5 | `DONE-R9.md` §3 #12（:360） | 「待用户确认」「不自行改口径」 | ✅ True |
| 6 | `00-群聊总线.md` MSG-0400 | A8 裁决口径原文在册 | ✅ True |
| 7 | 本轮对上述文件 | **只读核对、未做任何写入** | ✅ True |

> 结论：`128bit` 歧义**仍登记为「待用户确认、暂按 128px 基准画布理解」**，与 A8 裁决逐字一致；本轮**未自行改口径**、未把「128px」改成「128bit = 位宽 / 色深」之类新解释、未回改任何登记文件。若与用户本意不符，以用户为准。

### 2.3 真跑实际输出（完整一次 stdout 见 `DONE-R10.md` §2.3 [F]）

```text
=== [F] A8 128bit 歧义登记口径只读核对（不自行改口径）===
  00-汇总.md §4 A8 含「暂按 128px 基准画布理解」                                : True
  00-汇总.md §4 A8 含「待用户确认」                                          : True
  00-汇总.md §4 A8 含「不自行改口径，以用户为准」                                   : True
  ART-SPEC-FINAL.md 含「128bit 原词歧义仍登记」                              : True
  ART-SPEC-FINAL.md 含「不自行改口径」                                      : True
  ART-SPEC-FINAL.md §6 含「暂按 128px 理解」                              : True
  README.md §8.3 #7 含「不自行改口径」                                      : True
  DONE-R9.md §3 #12 含「待用户确认」                                       : True
  00-群聊总线 MSG-0400 含 A8 裁决口径                                       : True
  本轮未对上述文件做任何写入（只读核对）                                              : True
  -> A8 仍登记为「待用户确认、暂按 128px 基准画布理解」且未改口径 : True
```

---

## 3. 核对方法与边界

- **只读**：所有核对用内联 `python` 读文件 + 正则 / 字符串包含判断；未对 `scene_integration.md`、`hd2d_placeholder*.gd`、`courtyard.tscn`、`project.godot`、`00-汇总.md`、`ART-SPEC-FINAL.md`、`README.md`、`DONE-R9.md`、群聊总线调用任何写操作。
- **真跑**：`DONE-R10.md` §2.3 [E] / [F] 为一次完整内联 python 真跑 stdout，非摘抄、非沿用旧结论；A9 参数值由文件正则提取后打印实际值再比较，不是硬编码 `True`。
- **不越界**：`project.godot` / `scenes\` 归 Rank-1 独占，本轮只读引用；总线 / 总纲 / 契约 / 任务书 / 其它工位未写；未自行 git。
- **首次脚本失败如实登记**：[E] 段正则两次因 `re.search` 未带 `re.M` / 行首锚点导致提取 `None` 中断（`AttributeError` / `TypeError`，属自检脚本自身问题、非工程缺陷），第 3 次加 `re.M` + 空值防护后完整跑通；详见 `DONE-R10.md` §2.4，不隐瞒、不沿用中断前的半截输出作为最终依据。

---

## 4. 合规声明

- 只写 `Rank-4\SPEC-VERDICT-CHECK.md`（本文件）；`DONE-R10.md` 与回执的落位见其自身声明。
- 既有件（全部冻结 JSON / 规范 / DONE / 占位 `.gd` / `courtyard.tscn` / `project.godot` / 总线 / 总纲 / 契约）一律引用、不重做、一个字节未改。
- 零付费 / 零外部依赖；付费 API 一律禁用；**ComfyUI 仍是主美术路线**、`qwen-image` 仅本地零付费备选；程序化 `_draw()` 仅零依赖兜底、不取代主路线。
- 默认不刺探：仅执行任务明确要求的只读核对；`00-群聊总线.md` 开工只读一次。
- 中文 UTF-8；本文档所有代码块用 `text` 标记、**不含行首 json 围栏**，故 `Rank-4\*.md` 内嵌 JSON 块仍为 16/16（与 `DONE-R6` ~ `DONE-R9` 一贯做法一致）。
- 不宣称已能出图、不伪造输出 / 画面 / 截图、不拉第二个 GPU job、不臆造 ComfyUI 路径、不冒充全工程门禁全绿。
