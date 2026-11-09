# HUD-SPEC.md · R13 最小金线深蓝 HUD 规格

> 命令 `cmd-20261109-080019-797-A3` · `[ROUND=R13]` · Rank-3（RPG / 世界 / 存档）
> 依据 `capture/CAPTURE-REPORT.md` §2「**没有任何 UI**」补一处最小 HUD 占位。
> 引擎 Godot 4.7.2.stable · 纯程序化、零外部素材 · 中文 UTF-8

## 1. 定位与边界

- 交付件：`godot/scenes/hud.tscn`，由 `godot/scripts/build_hud.gd`（`extends SceneTree`）真跑生成。
- 场景是**独立 HUD**，根为 `CanvasLayer`，不依赖任何主场景，也不引用任何外部资源（`.tscn` 内只有 `sub_resource`，无 `ext_resource`）。
- **本轮不接入 `courtyard.tscn` / `Main.tscn` 或其它主场景**（跨工位、避免写冲突）。接入方式见 §5，由主场景归属工位（Rank-1）决定何时挂。

## 2. 节点结构

| 节点 | 类型 | 父 | 作用 |
|---|---|---|---|
| `Hud` | `CanvasLayer` | （根） | HUD 绘制层 |
| `HudPanel` | `Panel` | `Hud` | 深蓝底 + 金色 1px 边框卡片 |
| `TitleLabel` | `Label` | `Hud` | 金色中文文字占位 |

根节点直接子节点数 = 2；总节点数 = 3。

## 3. 配色

| 用途 | Color() | 近似 HEX | 说明 |
|---|---|---|---|
| 深蓝底（`bg_color`） | `Color(0.07, 0.10, 0.16, 1)` | `#121A29` | 冷夜蓝，任务书给定值 |
| 金线边框（`border_color`） | `Color(0.83, 0.68, 0.30, 1)` | `#D4AD4D` | 暖金，对齐 HD-2D「暖金光 × 冷夜雾」基调 |
| 文字色（`font_color`） | `Color(0.83, 0.68, 0.30, 1)` | `#D4AD4D` | 与边框同金，保持金线一致性 |
| 边框宽度 | 四边各 `1` px | — | `StyleBoxFlat.border_width_left/top/right/bottom` |

> 金色数值为本轮自定义取值，任务书只要求「金色」。如需与 4 号美术调色板统一，后续按 4 号 HD-2D 视觉规范对齐即可（只改 `build_hud.gd` 顶部 `GOLD` 常量重跑）；本轮不跨工位引用任何调色板文件。

## 4. 尺寸与布局（像素，1280×720 参考视口）

| 项 | 值 |
|---|---|
| `HudPanel.position` | `(24, 24)` |
| `HudPanel.size` | `340 × 84` |
| `TitleLabel.position` | `(44, 44)` |
| `TitleLabel.size` | `300 × 40` |
| `TitleLabel` 字号 | `20` |
| `TitleLabel.text` | `赐福 · 宁姆格福`（中文占位） |
| 边框 | 1 px，四边 |
| `CanvasLayer.layer` | 引擎默认（未显式改） |

布局为左上角 HUD 卡片；`Label` 与 `Panel` 同为 `CanvasLayer` 直接子节点，按添加顺序叠加，文字落在卡片内。落盘 `.tscn` 中表现为 `offset_left/top/right/bottom`（例：`offset_right = 364.0` = 24+340）。

## 5. 接入建议（**本轮不执行**）

以下仅供主场景归属工位（Rank-1 / 总指挥）后续装配参考，Rank-3 本轮不写任何主场景：

- 方式 A（推荐，`.tscn` 静态挂载）：在目标主场景里把 `hud.tscn` 作为实例子节点挂到根节点下，例如追加
  `[node name="Hud" parent="." instance=ExtResource("...")]`，并把 `res://scenes/hud.tscn` 登记为 `ext_resource`。
  因 HUD 根是 `CanvasLayer`，它天然独立于 3D/2D 世界坐标系，挂在任意主场景根下都能铺满视口。
- 方式 B（运行期挂载）：在主场景 `_ready()` 里
  `var hud: Node = load("res://scenes/hud.tscn").instantiate(); add_child(hud)`。
- 方式 C（全局 HUD）：把 `res://scenes/hud.tscn` 注册为 autoload（注意 autoload 常驻，切场景不销毁）。

装配注意：

1. **不要修改 `courtyard.tscn` 的既有节点**（历轮追加式装配口径：既有节点逐字一致）；新增 HUD 只做追加。
2. `TitleLabel` 当前是静态中文占位，正式版可改为从 `WorldState.get_flag(...)` / 赐福网络读取当前赐福名（对齐契约 I-1），由本工位后续 RPG 逻辑接管。
3. 当前用引擎**默认字体**渲染中文；本轮「零外部素材」不引入字体文件。若后续要定制中文字形，由 4 号美术管线提供字体资源后在 `build_hud.gd` 里挂 `theme_override_fonts/font`，本轮不预留外部依赖。
4. `CanvasLayer` 默认 `layer=1`；若与既有 UI 层级冲突，由主场景工位统一调 `layer`，本场景不硬编码。

## 6. 零外部素材声明

- 仅使用 Godot 内置节点（`CanvasLayer` / `Panel` / `Label`）与内置资源（`StyleBoxFlat`）。
- 无贴图、无音频、无字体文件、无 shader、无第三方插件、无付费/外部服务。
- 生成物 `hud.tscn` 内只有一个 `StyleBoxFlat` 子资源，不含 `ext_resource`。
- 配色 / 尺寸 / 文字全部写在 `build_hud.gd` 常量里，改常量重跑即可再生成，无隐藏二进制依赖。
