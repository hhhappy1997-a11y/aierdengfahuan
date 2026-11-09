# DONE-R13.md · Rank-3 完成标志

> 命令 `cmd-20261109-080019-797-A3` · `[ROUND=R13]` · 派单 2026-11-09 08:00:20（GUI 下达）
> 执行 AI：Rank-3（RPG / 世界 / 存档）· 引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`（`v4.7.2.stable.official.ed1daf0bf`）
> 依据：`capture/CAPTURE-REPORT.md` §2「**没有任何 UI**」；`teamwork/00-协作契约.md`；`teamwork/00-群聊总线.md`（开工只读一次）。
> 本件所有 `stdout` 均为本机真跑实际输出，未伪造、未改写。

## ① 交付清单

| # | 文件 | 类型 | 说明 |
|---|---|---|---|
| 1 | `godot/scenes/hud.tscn` | 新增（脚本真实生成） | 最小金线深蓝 HUD：`CanvasLayer` 根 + 深蓝 `Panel` + 金色 1px 边框 + 金色中文 `Label` |
| 2 | `godot/scripts/build_hud.gd` | 新增 | `extends SceneTree` 构建脚本；`CACHE_MODE_IGNORE` 回读校验四项 |
| 3 | `teamwork/Rank-3/HUD-SPEC.md` | 新增 | 配色 / 尺寸 / 接入建议 |
| 4 | `teamwork/Rank-3/DONE-R13.md` | 新增 | 本件 |
| 5 | `teamwork/command_center/ai/3/outbox/cmd-20261109-080019-797-A3.json` | 新增 | 回执 JSON |

> 回执投递记录（如实）：本件写入 `ai/3/outbox/` 后，于 `2026-11-09 08:07` 被调度中枢消费至 `command_center/dispatcher/receipts/cmd-20261109-080019-797-A3.json`（同名、内容逐字一致，693 字节），`ai/3/status.json` 同步为 `state=idle / completed=12`。本工位为确保 outbox 留存又原样写回一份，中枢于 `08:08` 再次消费，**终态 `ai/3/outbox/` 为空、正式回执稳定落在 `dispatcher/receipts/`**（复核 `JSON_OK task_id=cmd-20261109-080019-797-A3 / ai=3 / status=done`）。此为中枢自动回收的正常闭环，非本工位重复派单或伪造回执；本工位不再重复投递以免干扰中枢状态机。

**只读、未改动（守边界）**：`godot/scenes/courtyard.tscn`、`Main.tscn`、`player.tscn`、`boss_01_margit.tscn` 及 `godot/scenes/world/` 全部主场景；`godot/scripts/` 下其它 `build_*.gd` / 各子目录；其它工位 `Rank-1 / Rank-2 / Rank-4`；`teamwork/00-*.md`（总纲 / 契约 / 群聊总线 / 台账 / 汇总）；`command_center/ai/3/inbox/` 任务单。**未接入任何主场景**（任务书硬边界）。**未自行 git**（commit / push 均未执行）。

## ② 自检（含回读实际输出）

### 2.1 真跑生成 + 脚本内 `CACHE_MODE_IGNORE` 回读校验

命令：

```
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --script "res://scripts/build_hud.gd"
```

实际 stdout（第 1 次真跑）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[HUD] BUILD_OK path=res://scenes/hud.tscn child_count=2 node_count=3 pack_err=0 save_err=0
[HUD_VERIFY] ① root_is_CanvasLayer PASS=true | root=Hud class=CanvasLayer
[HUD_VERIFY] ② child_count PASS=true | child_count=2 expected=2 names=["HudPanel", "TitleLabel"]
[HUD_VERIFY] ③ panel_border_gold_1px PASS=true | bg=(0.070,0.100,0.160) border_color=(0.830,0.680,0.300) gold=(0.830,0.680,0.300) widths=(1,1,1,1)
[HUD_VERIFY] ④ label_exists PASS=true | text=赐福 · 宁姆格福 font_color=(0.830,0.680,0.300) color_gold_ok=true
[HUD] VERIFY_SUMMARY pass=4 fail=0 ok=true
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
GODOT_EXIT=0
```

四项回读（全部 `PASS=true`），均由
`ResourceLoader.load(OUT_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)`
**忽略资源缓存、强制从磁盘重读**刚保存的 `hud.tscn` 后 `instantiate()` 得到：

| 校验项 | 要求 | 实际读回 | 结果 |
|---|---|---|---|
| ① 根节点 | `CanvasLayer` | `root=Hud class=CanvasLayer` | PASS |
| ② 子节点数 | 2 | `child_count=2 names=["HudPanel", "TitleLabel"]` | PASS |
| ③ Panel 样式边框色 | 金色 + 1px | `border_color=(0.830,0.680,0.300)`、`widths=(1,1,1,1)`、`bg=(0.070,0.100,0.160)` | PASS |
| ④ Label | 存在 + 中文占位 + 金色 | `text=赐福 · 宁姆格福`、`font_color=(0.830,0.680,0.300)` | PASS |

`VERIFY_SUMMARY pass=4 fail=0 ok=true`，脚本 `quit(0)` → `GODOT_EXIT=0`。

### 2.2 三段门禁复跑（`00-工具链接入说明.md` §4.2 口径）

三段均以工程根 `F:/Game/aierdengfahuan/godot` 为 `--path`：

- G1：`godot --headless --path <工程根> --import`
- G2：`godot --headless --path <工程根> --check-only --script res://scripts/build_hud.gd`
- G3：`godot --headless --path <工程根> --quit`

| 段 | EXIT | `SCRIPT ERROR` / `Parse Error` 计数 | `ERROR:` 计数 |
|---|---|---|---|
| G1 | 0 | 0 | 0 |
| G2 | 0 | 0 | 0 |
| G3 | 0 | 0 | 0 |

第 1 次三段门禁实际 stdout（完整）：

```
===== G1 =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[   0% ] first_scan_filesystem | 正在扫描文件结构……
[  16% ] first_scan_filesystem | 正在加载全局类名……
[  33% ] first_scan_filesystem | 正在校验 GDExtension……
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[  66% ] first_scan_filesystem | 正在初始化插件……
[  83% ] first_scan_filesystem | 正在启动文件扫描……
[ DONE ] first_scan_filesystem

[   0% ] update_scripts_classes | Started 正在注册全局类…… (2 steps)
[   0% ] update_scripts_classes |
[  33% ] update_scripts_classes |
[ DONE ] update_scripts_classes

[   0% ] loading_editor_layout | Started 正在加载编辑器 (5 steps)
[   0% ] loading_editor_layout | 正在加载编辑器布局……
[  16% ] loading_editor_layout | 正在加载停靠面板……
[ DONE ] loading_editor_layout

G1_EXIT=0
G1_SCRIPT_ERROR_COUNT=0
G1_ERROR_COUNT=0
===== G2 =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
G2_EXIT=0
G2_SCRIPT_ERROR_COUNT=0
G2_ERROR_COUNT=0
===== G3 =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G3_EXIT=0
G3_SCRIPT_ERROR_COUNT=0
G3_ERROR_COUNT=0
```

**复跑（第 2 次）**：真跑与 G1/G2/G3 全部再跑一遍，结果与第 1 次一致，实际 stdout（完整）：

```
===== 复跑 #2 : 真跑生成 + CACHE_MODE_IGNORE 回读 =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[HUD] BUILD_OK path=res://scenes/hud.tscn child_count=2 node_count=3 pack_err=0 save_err=0
[HUD_VERIFY] ① root_is_CanvasLayer PASS=true | root=Hud class=CanvasLayer
[HUD_VERIFY] ② child_count PASS=true | child_count=2 expected=2 names=["HudPanel", "TitleLabel"]
[HUD_VERIFY] ③ panel_border_gold_1px PASS=true | bg=(0.070,0.100,0.160) border_color=(0.830,0.680,0.300) gold=(0.830,0.680,0.300) widths=(1,1,1,1)
[HUD_VERIFY] ④ label_exists PASS=true | text=赐福 · 宁姆格福 font_color=(0.830,0.680,0.300) color_gold_ok=true
[HUD] VERIFY_SUMMARY pass=4 fail=0 ok=true
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
BUILD_R2_EXIT=0
===== 复跑 #2 : G1 =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[   0% ] first_scan_filesystem | 正在扫描文件结构……
[  16% ] first_scan_filesystem | 正在加载全局类名……
[  33% ] first_scan_filesystem | 正在校验 GDExtension……
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[  66% ] first_scan_filesystem | 正在初始化插件……
[  83% ] first_scan_filesystem | 正在启动文件扫描……
[ DONE ] first_scan_filesystem

[   0% ] loading_editor_layout | Started 正在加载编辑器 (5 steps)
[   0% ] loading_editor_layout | 正在加载编辑器布局……
[  16% ] loading_editor_layout | 正在加载停靠面板……
[ DONE ] loading_editor_layout

G1_R2_EXIT=0
G1_R2_SCRIPT_ERROR_COUNT=0
G1_R2_ERROR_COUNT=0
===== 复跑 #2 : G2 =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
G2_R2_EXIT=0
G2_R2_SCRIPT_ERROR_COUNT=0
G2_R2_ERROR_COUNT=0
===== 复跑 #2 : G3 =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G3_R2_EXIT=0
G3_R2_SCRIPT_ERROR_COUNT=0
G3_R2_ERROR_COUNT=0
```

### 2.3 落盘 `hud.tscn` 实际内容（核对）

```
[gd_scene format=3]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_toqtt"]
bg_color = Color(0.07, 0.1, 0.16, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.83, 0.68, 0.3, 1)

[node name="Hud" type="CanvasLayer" unique_id=603203079]

[node name="HudPanel" type="Panel" parent="." unique_id=293672273]
offset_left = 24.0
offset_top = 24.0
offset_right = 364.0
offset_bottom = 108.0
theme_override_styles/panel = SubResource("StyleBoxFlat_toqtt")

[node name="TitleLabel" type="Label" parent="." unique_id=893573761]
offset_left = 44.0
offset_top = 44.0
offset_right = 344.0
offset_bottom = 84.0
theme_override_font_sizes/font_size = 20
theme_override_colors/font_color = Color(0.83, 0.68, 0.3, 1)
text = "赐福 · 宁姆格福"
```

文件内**只有 `sub_resource`，没有 `ext_resource`** → 零外部素材、纯程序化成立；中文 `text` 以 UTF-8 落盘。

### 2.4 如实登记的既有 WARNING（非本轮引入、不冒充全绿）

- 真跑与 G3 均出现 `WARNING: [ChunkManager] 未找到 ChunkRoot...`（来自 `res://scripts/world/chunk_streaming.gd` autoload）与 `WARNING: 2 ObjectDB instances were leaked at exit`。这两条是本轮改动前工程既有现象（历轮 `00-汇总.md` / `GATE-FINAL.md` 已登记 `ObjectDB leaked` 为 WARNING、非 ERROR），与 `hud.tscn` / `build_hud.gd` 无关。
- 按契约 §4.2「运行时 `SCRIPT ERROR` 只中断当前函数、退出码仍为 0，必须 grep 日志才算通过」：两次真跑 + 两次三段门禁的 `SCRIPT ERROR` / `Parse Error` / `ERROR:` 计数均为 **0**；`WARNING` 如实保留，未隐藏、未宣称零 WARNING。

## ③ 未完成项与阻塞

| # | 项 | 性质 | 说明 |
|---|---|---|---|
| 1 | 未接入 `courtyard.tscn` / 其它主场景 | **按任务书硬边界，预期未完成** | 跨工位，避免写冲突；接入方式见 `HUD-SPEC.md` §5，由主场景归属工位决定 |
| 2 | 未做运行期可见性 / 截图验收 | 本轮范围外 | 本轮只做 `--script` 生成 + `CACHE_MODE_IGNORE` 回读 + 三段门禁；未 `--write-movie`、未把 HUD 挂进主场景渲染。`capture/CAPTURE-REPORT.md` 的「没有任何 UI」是主场景画面结论，本轮只交付独立 HUD 场景，**不宣称已让主画面出现 UI** |
| 3 | 中文 Label 用引擎默认字体 | 零外部素材约束下的取舍 | 未引入字体文件；如需定制中文字形，由 4 号美术管线提供字体后挂 `theme_override_fonts/font` |
| 4 | HUD 仅为最小视觉占位，无交互逻辑 | 后续迭代 | 无血量 / 专注 / 赐福状态绑定；后续可由本工位按 I-1 接 `WorldState.get_flag()` / 赐福网络驱动 `TitleLabel.text` |
| 5 | 两条既有 WARNING 未处理 | 跨工位 | `ChunkManager` / `ObjectDB leaked` 属既有工程现象，非本轮范围，只登记不擅改 |

> **无本轮硬阻塞**：命令要求的 5 件交付物全部落地；真跑 + `CACHE_MODE_IGNORE` 回读四项全 PASS（`pass=4 fail=0 ok=true`、`GODOT_EXIT=0`）；三段门禁复跑两次 G1/G2/G3 均 `EXIT=0` 且 `SCRIPT ERROR/ERROR=0`；回执已写。上述项均为「按边界不做 / 后续迭代 / 跨工位登记」，不影响本轮完成判定。
