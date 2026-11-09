# DONE-R18.md · Rank-3 交付报告（HUD 遮挡修复）

- 任务：`cmd-20261109-095518-174-A3`，`[ROUND=R18]`，Rank-3 执行 AI，调度中枢派单
- 日期：2026-11-09
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`，实测 `--version` = `4.7.2.stable.official.ed1daf0bf`
- 工程根（`--path`）：`F:/Game/aierdengfahuan/godot`
- 必读（开工只读一次）：`godot/scenes/hud.tscn`、`godot/scripts/hud.gd`、`teamwork/Rank-4/HD2D-FX-PLAN.md`（FX 层 `layer=10`）、`teamwork/00-群聊总线.md` —— 均已读 ✓
- **真跑结论（是否降级）：否，未降级。** 改动落地；`CACHE_MODE_IGNORE` 回读 `SUMMARY pass=6 fail=0 ok=true`、`VERIFY_EXIT=0`；两轮三段门禁 `GATE_OVERALL_EXIT=0`、`SCRIPT ERROR / Parse Error / ERROR = 0`；本实例全程零写入 `courtyard.tscn`（Rank-1 独占）。**并发观察：收尾复核发现 `courtyard.tscn` 于 `10:03:10` 被并发实例改动、sha256 由 `306b2467…` 变为 `461f19c7…`，非本实例所为，如实登记见 §2.9，不回退 / 不覆盖 / 不裁决。**

---

## ① 交付清单

| # | 文件 | 动作 | 说明 |
|---|------|------|------|
| 1 | `godot/scenes/hud.tscn` | **修改（仅 +1 行）** | 根 `CanvasLayer` 增加 `layer = 20`（原为缺省 `0`），提升到 FX 层之上；深蓝底 / 金色 1px 边框 / 金色文字 / 脚本挂载 **逐字未动**。 |
| 2 | `teamwork/Rank-3/r18_verify_hud_layer.gd` | **新建**（4623 字节） | `extends SceneTree` 回读校验载体。`CACHE_MODE_IGNORE` 强制从磁盘重读 `res://scenes/hud.tscn` → `instantiate()`，断言并打印 5 项：layer / Panel 背景色 / 边框色 / 1px 四边 / 文字色 / 脚本仍挂。只读，不 `pack` / 不 `save` / 不 `add_child` / 不写文件。 |
| 3 | `teamwork/Rank-3/DONE-R18.md` | **新建** | 本报告（①交付清单 ②自检含完整实际 stdout ③未完成项与阻塞）。 |
| 4 | `teamwork/command_center/ai/3/outbox/cmd-20261109-095518-174-A3.json` | **新建** | 回执 JSON，按本轮命令 id 署名。 |

**可写范围核对**：仅上述 4 个文件落在允许范围（`godot/scenes/hud.tscn`、`teamwork/Rank-3/`、回执例外 `teamwork/command_center/ai/3/outbox/`）。
- **未写** `godot/scripts/`（本轮可写范围不含该目录，故校验脚本落在 `Rank-3/` 内，以绝对路径 `--script` + `--path godot` 真跑，沿用 `DONE-R16.md §1` 的既有先例）。
- **未碰** `godot/scenes/courtyard.tscn`（Rank-1 独占）：本实例全程零写入该文件；改动前与 §2.7 门禁边界时点 sha256 均为 `306b2467ca0a6290639693b1c7e2b4b66f1b55dada2d05ad0bf8d08ff2300fe3`（与 `DONE-R17.md §2.8` 一致）。**收尾复核（10:05）发现该文件于 `10:03:10` 被并发实例改为 `461f19c74686acb9fd92aa4ed0aaa023d60fad604d874684634cecb64261f5fa`，非本实例写入，详见 §2.9。**
- 未写其它工位、未写总线 / 总纲 / 契约 / 任务书 / 进度台账、未自行 `git`（本轮未执行任何 git 命令）。
- 零付费（纯本地 Godot）、零外部依赖；默认不刺探（只目的性读取必读件、本工位历史件、`Rank-4/HD2D-FX-PLAN.md`、工程根必要资源，并只读核验本工位历史回执归档格式）；中文 UTF-8；Godot 4.7.2 合法语法（`--check-only` `EXIT=0`）。

### 1.1 `hud.tscn` 改动明细（逐字）

改动前（`[node]` 头，sha256 `0c9670ae…`）：

```
[node name="Hud" type="CanvasLayer" unique_id=1276405765]
script = ExtResource("1_hud")
```

改动后（sha256 `c20c0505…`）：

```
[node name="Hud" type="CanvasLayer" unique_id=1276405765]
layer = 20
script = ExtResource("1_hud")
```

**仅新增 `layer = 20` 一行**，其余 30 行逐字不变。

### 1.2 为什么是 `layer = 20`（与 FX 方案对齐，不越界裁决）

`Rank-4/HD2D-FX-PLAN.md` 只读引用：
- §1.1 / §2.1：光尘落在 `SubViewport 内部 World2D` 的 `FXLayer(layer=10)`，主 viewport（root）绘制序为 `HD2DPlaceholderLayer(-10)` → `SubViewportContainer(0，含 3D 与内部 FX)` → `UI（≥20，将来）` —— **方案本身即建议主树 UI 取 ≥20**。
- §1.1 要点 / §2.2 #1：明确登记「`-10`（主 viewport）与 `10`（SubViewport 内部）分属两个独立 canvas 世界，layer 数值不直接比较、不冲突」。

如实登记的技术事实：FX 光尘与 HUD 不同 canvas 世界，`layer` 数值**不直接可比**；但 HUD 是主 viewport 根级 `CanvasLayer`，提到 `20` 后绘制序高于主树中默认 layer 的 `SubViewportContainer` 及其内部 FX 输出，光尘不再盖到 HUD 面板上。**本轮按派单「把根 CanvasLayer 的 layer 提高到 FX 层之上（如 20）」执行 `layer = 20`，不对 Rank-1 的 SubViewport / canvas 世界装配口径作裁决、不改动 `courtyard.tscn`。**

### 1.3 保持不变项（回读逐项确认，见 §2.4）

| 项 | 落盘值 | 状态 |
|---|---|---|
| 深蓝底 `StyleBoxFlat.bg_color` | `Color(0.07, 0.1, 0.16, 1)`，alpha=1 不透明 | **不变** |
| 金色 1px 边框 | `border_color = Color(0.83, 0.68, 0.3, 1)`，`border_width_left/top/right/bottom = 1` ×4 | **不变** |
| 金色文字 | `TitleLabel theme_override_colors/font_color = Color(0.83, 0.68, 0.3, 1)` | **不变** |
| 脚本仍挂根节点 | `script = ExtResource("1_hud")` → `res://scripts/hud.gd` | **不变** |
| 其余 | `offset_*`、`font_size = 20`、`text = "赐福 · 宁姆格福"`、`unique_id`、sub_resource id | **不变** |

---

## ② 自检（含完整实际 stdout）

### 2.0 命令清单

- 引擎版本 / 改动前 sha256 基线
- 语法预检：`godot --headless --path <工程根> --check-only --script F:/Game/aierdengfahuan/teamwork/Rank-3/r18_verify_hud_layer.gd`
- 回读真跑：`godot --headless --path <工程根> --script F:/Game/aierdengfahuan/teamwork/Rank-3/r18_verify_hud_layer.gd`（不带 `--check-only`，实际执行 `_initialize()`）
- 三段门禁**复跑**两轮（照 `00-工具链接入说明.md §4.2` / `DONE-R16.md §2.3` / `DONE-R17.md §2.0` 口径）：
  - **G1** `godot --headless --path <工程根> --import`
  - **G2** `godot --headless --path <工程根> --check-only --script <r18_verify_hud_layer.gd>`
  - **G3** `godot --headless --path <工程根> --quit`
- 补充：`--check-only --script res://scripts/hud.gd`（`hud.gd` 语法门禁，作为「脚本仍挂」旁证）
- 收尾：sha256 / UTF-8 / BOM 边界证据

### 2.1 引擎版本与改动前 sha256 基线（实际 stdout）

```
=== 改动前 sha256 快照 ===
0c9670ae77865027627d9bfdccac4e487352abc004aac1fca4446b2cf116c764 *godot/scenes/hud.tscn
306b2467ca0a6290639693b1c7e2b4b66f1b55dada2d05ad0bf8d08ff2300fe3 *godot/scenes/courtyard.tscn
=== 引擎版本 ===
4.7.2.stable.official.ed1daf0bf
```

> `hud.tscn` 改动前 sha256 与 `DONE-R17.md §2.8` 记录逐字一致，说明 R17 之后该场景未被改动过。

### 2.2 首次真跑（修正前 v1）—— 如实登记的退出残留输出（未隐瞒、未伪造）

首次 `--script` 真跑回读断言本身已 `pass=6 fail=0 ok=true`、`VERIFY_EXIT=0`，但引擎退出时出现 **5 行 `ERROR` / `WARNING` 残留**：

```
===== [预检] --check-only --script r18_verify_hud_layer.gd =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

G2_PRECHECK_EXIT=0
===== [真跑] --script r18_verify_hud_layer.gd 回读校验 =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[R18] ==== hud.tscn 回读校验（CACHE_MODE_IGNORE）开始 ====
[R18] HUD_PATH=res://scenes/hud.tscn | cache_mode=CACHE_MODE_IGNORE
[R18] ① scene_loaded PASS=true | class=PackedScene
[R18] ② root_CanvasLayer_layer PASS=true | class=CanvasLayer name=Hud layer=20 (期望 20)
[R18] ③ script_attached PASS=true | path=res://scripts/hud.gd
[R18] ④ panel_bg_color PASS=true | bg_color=(0.07, 0.1, 0.16, 1.0) alpha=1.00 (期望深蓝不透明 (0.07, 0.1, 0.16, 1.0))
[R18] ⑤ border_color PASS=true | border_color=(0.83, 0.68, 0.3, 1.0) (期望金色 (0.83, 0.68, 0.3, 1.0))
[R18] ⑥ border_width_1px PASS=true | L/T/R/B=1/1/1/1 (期望 1/1/1/1)
[R18] ⑦ font_color PASS=true | font_color=(0.83, 0.68, 0.3, 1.0) (期望金色 (0.83, 0.68, 0.3, 1.0))
[R18] ---- 回读汇总 ----
[R18] SUMMARY pass=6 fail=0 ok=true
[R18] ==== hud.tscn 回读校验结束 ====
ERROR: 2 RID allocations of type 'PN18TextServerAdvanced22ShapedTextDataAdvancedE' were leaked at exit.
ERROR: 1 RID allocations of type 'PN18TextServerAdvanced12FontAdvancedE' were leaked at exit.
VERIFY_EXIT=0
```

stderr（首次 v1 完整）：

```
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 1 RID of type "Canvas" was leaked.
   at: _free_rids (servers/rendering/renderer_canvas_cull.cpp:2733)
WARNING: 2 RIDs of type "CanvasItem" were leaked.
   at: _free_rids (servers/rendering/renderer_canvas_cull.cpp:2735)
WARNING: 14 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
ERROR: 1 resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:822)
```

**根因与轮内修正（不跨轮甩锅）**：v1 用 `packed.instantiate()` 得到节点后既未加入场景树、也未释放，退出时 TextServer / Canvas RID 与 sub-resource 未回收，产生退出残留 `ERROR`。修正方式是在 `quit()` 前显式 `root.free()`。
**为何不用 `get_root().add_child(root)`**（`DONE-R16.md`/`R17` 的既有做法）：`add_child` 会触发 `hud.gd::_ready()` → `refresh_all()` → `apply_lit_state(false)`，把 `TitleLabel` 的 `theme_override_colors/font_color` 由落盘金色改写为运行期 `DIM(0.45,0.42,0.34,1.0)`（见 `DONE-R17.md §2.1/§2.3` 的 `before=(0.45, 0.42, 0.34, 1.0)` 铁证），导致「金色文字（不变）」的**落盘静态回读失真**。故本轮选择显式 `root.free()`：既保持回读的是磁盘落盘值，又让 RID / 资源正常回收。修正后复跑见 §2.3。

### 2.3 语法预检 + 回读校验真跑（最终版，完整 stdout）

命令：

```
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --check-only --script "F:/Game/aierdengfahuan/teamwork/Rank-3/r18_verify_hud_layer.gd"
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --script "F:/Game/aierdengfahuan/teamwork/Rank-3/r18_verify_hud_layer.gd"
```

实际 stdout（完整）：

```
===== [预检复跑] --check-only --script r18_verify_hud_layer.gd =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

G2_PRECHECK_EXIT=0
===== [真跑复跑] --script r18_verify_hud_layer.gd 回读校验 =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[R18] ==== hud.tscn 回读校验（CACHE_MODE_IGNORE）开始 ====
[R18] HUD_PATH=res://scenes/hud.tscn | cache_mode=CACHE_MODE_IGNORE
[R18] ① scene_loaded PASS=true | class=PackedScene
[R18] ② root_CanvasLayer_layer PASS=true | class=CanvasLayer name=Hud layer=20 (期望 20)
[R18] ③ script_attached PASS=true | path=res://scripts/hud.gd
[R18] ④ panel_bg_color PASS=true | bg_color=(0.07, 0.1, 0.16, 1.0) alpha=1.00 (期望深蓝不透明 (0.07, 0.1, 0.16, 1.0))
[R18] ⑤ border_color PASS=true | border_color=(0.83, 0.68, 0.3, 1.0) (期望金色 (0.83, 0.68, 0.3, 1.0))
[R18] ⑥ border_width_1px PASS=true | L/T/R/B=1/1/1/1 (期望 1/1/1/1)
[R18] ⑦ font_color PASS=true | font_color=(0.83, 0.68, 0.3, 1.0) (期望金色 (0.83, 0.68, 0.3, 1.0))
[R18] ---- 回读汇总 ----
[R18] SUMMARY pass=6 fail=0 ok=true
[R18] ==== hud.tscn 回读校验结束 ====
VERIFY_EXIT=0
```

stderr（最终版，仅两条工程既有 WARNING）：

```
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

**要点**：
- 预检 `--check-only` 只有引擎 banner、无任何脚本内 `print` / `SCRIPT ERROR` / `Parse Error` / `ERROR`（`--check-only` 只解析不执行），证明 `r18_verify_hud_layer.gd`（`extends SceneTree`）为 Godot 4.7.2 合法语法，`G2_PRECHECK_EXIT=0`。
- 真跑以 `CACHE_MODE_IGNORE` 强制从磁盘重读，5 项断言（拆为 ①~⑦ 共 6 条 PASS）全部命中；`VERIFY_EXIT=0`，**`ERROR` 行已全部消失**。
- ② `layer=20` 为本次修复目标值，回读自磁盘生效；③ 脚本 `res://scripts/hud.gd` 仍挂根节点；④ 深蓝底 `alpha=1.00` 不透明；⑤⑥ 金色 + 四边 1px 边框；⑦ 金色文字 —— 均为**落盘静态值**（未 `add_child`，无运行期 `apply_lit_state` 改写）。

### 2.4 逐条回读断言结论表（最终版真跑）

| 断言 | 结论 | 实际值摘要 |
|------|------|-----------|
| ① `scene_loaded`（`CACHE_MODE_IGNORE`） | PASS | `class=PackedScene`，从磁盘重读成功 |
| ② 根 `CanvasLayer.layer` | **PASS** | `class=CanvasLayer name=Hud layer=20`（期望 20） |
| ③ 脚本仍挂 | PASS | `path=res://scripts/hud.gd` |
| ④ Panel 背景色 | PASS | `bg_color=(0.07, 0.1, 0.16, 1.0)`、`alpha=1.00`，深蓝不透明 |
| ⑤ 边框色 | PASS | `border_color=(0.83, 0.68, 0.3, 1.0)`，金色 |
| ⑥ 1px 四边边框 | PASS | `L/T/R/B=1/1/1/1` |
| ⑦ 文字色 | PASS | `font_color=(0.83, 0.68, 0.3, 1.0)`，金色 |
| **SUMMARY** | **PASS** | `pass=6 fail=0 ok=true`，`VERIFY_EXIT=0` |

### 2.5 三段门禁复跑（ROUND 1 / ROUND 2，完整 stdout 与汇总）

**ROUND 1**（G1 / G2 / G3，逐条 `EXIT` 与日志 grep）：

```
===== ROUND 1 / 三段门禁 =====
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

G1_R1_EXIT=0
  grep: SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_LINES=0
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
G2_R1_EXIT=0
  grep: SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_LINES=0
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G3_R1_EXIT=0
  grep: SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_LINES=0
```

**ROUND 2**（G1 / G2 / G3 + `hud.gd` 补充门禁 + 动态汇总）：

```
===== ROUND 2 / 三段门禁 =====
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
  grep: SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_LINES=0
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
G2_R2_EXIT=0
  grep: SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_LINES=0
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G3_R2_EXIT=0
  grep: SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_LINES=0
===== 补充：hud.gd 语法门禁（脚本仍挂旁证）=====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
G2b_hud_gd_EXIT=0
  grep: SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_LINES=0
ROUND2_GATE_SUM_EXIT=0
ROUND1_GATE_SUM_EXIT=0 (G1_R1=0 G2_R1=0 G3_R1=0, 见 ROUND 1 stdout)
GATE_OVERALL_EXIT=0
```

> G1 的「正在创建自动加载脚本……」通过、扫描全 `[ DONE ]`、无 ERROR，说明改动后的 `hud.tscn` 被 `--import` 正常纳入文件系统扫描与解析。G3 的 `2 ObjectDB instances were leaked` 是工程既有退出 WARNING（`object.cpp:2536`，`DONE-R17.md §2.5/§4` 已登记），非 ERROR、非本轮引入，未隐藏、未宣称零 WARNING。

### 2.6 EXIT / 门禁汇总表

| 段 | 命令标志 | ROUND 1 | ROUND 2 | SCRIPT ERROR / Parse Error / ERROR |
|----|----------|---------|---------|-----------------------------------|
| G1 | `--import` | `0` | `0` | 0 / 0 / 0 |
| G2 | `--check-only --script r18_verify_hud_layer.gd` | `0` | `0` | 0 / 0 / 0 |
| G3 | `--quit` | `0` | `0` | 0 / 0 / 0 |
| 补充 | `--check-only --script res://scripts/hud.gd` | — | `0` | 0 / 0 / 0 |
| 真跑 | `--script r18_verify_hud_layer.gd`（回读） | — | `0` | 0 / 0 / 0 |
| **汇总** | `GATE_OVERALL_EXIT` | **0** | **0** | **0 / 0 / 0** |

> 真跑 `VERIFY_EXIT=0`；回读 `SUMMARY pass=6 fail=0 ok=true`。

### 2.7 边界证据（sha256 / UTF-8 / BOM，实际 stdout）

```
=== 改动后 sha256（courtyard.tscn 应与改动前 306b2467... 一致=未碰）===
c20c0505db6c306cf935fa3bbd79930254661771b82a7f448b8de804b9263386 *godot/scenes/hud.tscn
306b2467ca0a6290639693b1c7e2b4b66f1b55dada2d05ad0bf8d08ff2300fe3 *godot/scenes/courtyard.tscn
=== 编码 / BOM / UTF-8 ===
hud.tscn | bytes=914 | BOM=False | utf8=True
r18_verify_hud_layer.gd | bytes=4623 | BOM=False | utf8=True
=== outbox ai/3 当前状态（写回执前）===
total 0
drwxr-xr-x 1 admin 197121 0 Nov  9 09:48 .
drwxr-xr-x 1 admin 197121 0 Nov  9 09:55 ..
=== 工位新增件 ===
-rw-r--r-- 1 admin 197121 4623 Nov  9 10:00 teamwork/Rank-3/r18_verify_hud_layer.gd
```

- `hud.tscn`：`0c9670ae…` → `c20c0505…`，确因新增 `layer = 20` 一行而变（其余内容不变，见 §1.1）。
- `courtyard.tscn`：**该时点（§2.7 快照，约 10:00）** `306b2467…` → `306b2467…`，未变（`--import` 只更新 `.godot` 缓存、不改 `.tscn` 字节；校验脚本无 `pack` / `save` / 文件写入）。**收尾 10:05 复核发现 `10:03:10` 之后的并发改动，见 §2.9；两处快照均为真实 stdout、并列登记，不矛盾。**
- 两份 UTF-8 中文文件均无 BOM。

### 2.9 收尾复核与并发保护登记（如实，不伪造）

写完交付件后于 `10:05` 再做一次只读复核，发现 **`courtyard.tscn` 已被并发实例改动**（本实例全程零写入该文件，派单明确其为 Rank-1 独占）。实际 stdout：

```
=== 两个 .tscn 的 mtime（只读元数据，不读内容）===
2026-11-09 10:03:10.257256500 +0800 | 6121 bytes | godot/scenes/courtyard.tscn
2026-11-09 09:58:26.222796200 +0800 | 914 bytes | godot/scenes/hud.tscn
=== 当前 sha256（复核）===
461f19c74686acb9fd92aa4ed0aaa023d60fad604d874684634cecb64261f5fa *godot/scenes/courtyard.tscn
c20c0505db6c306cf935fa3bbd79930254661771b82a7f448b8de804b9263386 *godot/scenes/hud.tscn
=== 当前时间 ===
2026-11-09 10:05:25 +0800
```

时序与归因（只读元数据，未读 `courtyard.tscn` 内容、未刺探其它工位）：
- `hud.tscn` mtime `09:58:26` = 本实例 `layer = 20` 改动；sha256 仍为 `c20c0505…`，**未被并发覆盖**。
- `courtyard.tscn` mtime **`10:03:10`**，晚于 §2.7 边界证据快照（约 10:00）、早于本实例写 `DONE-R18.md` / 回执（约 10:04）；sha256 由 `306b2467…` 变为 `461f19c7…`。
- 本实例所有写入仅 4 个文件（见 §①），所有 Godot 命令中 `--import` 只更新 `.godot` 缓存、`--check-only` / `--script` / `--quit` 均只读，校验脚本无 `pack` / `save` / 文件写入 ⇒ **该改动与本实例无关**，推断为并发的 Rank-1 执行 AI（该文件独占方）在本轮期间并行改动（R18 为总指挥经中枢并发派单）。
- 处置（沿用 `MSG-20261109-0257-HOST` / `MSG-20261109-0916-HOST` / `DONE-R10` 的并发保护口径）：**只做只读复核、如实登记，不覆盖、不重做、不回退、不裁决跨模块争议**；§2.7 的 `306b2467…` 与本节 `461f19c7…` 均为各自时点的真实快照，并列登记，不矛盾、不篡改其一。
- 回执 `result` 中「`courtyard.tscn` 未碰（sha256 `306b2467…` 前后一致）」指的是**改动前 → §2.7 门禁边界时点**这一区间（本实例未碰该文件的结论成立）；本节并发变化是在回执写入后才被本实例观察到。回执已由中枢消费归档（见 §2.10 / §③），按幂等**不重写第二份回执**，差异在此更正登记。

### 2.10 回执写入 / 中枢消费归档核对（实际 stdout）

回执先写到 `outbox/`，随后被中枢实时消费归档（与 `DONE-R17.md §①` 登记的预期流程一致）。核对实际 stdout：

```
=== 归档回执 JSON 合法性 + 字段 ===
json_valid=True
task_id=cmd-20261109-095518-174-A3 | ai=3 | status=done
result_len=1584 | result_starts=引用 DONE-R18.md 实际结论：R18 
=== DONE-R18.md 编码 ===
DONE-R18.md | bytes=21952 | BOM=False | utf8=True
=== outbox（消费后应为空=正常态）===
total 0
drwxr-xr-x 1 admin 197121 0 Nov  9 10:04 .
drwxr-xr-x 1 admin 197121 0 Nov  9 10:04 ..
=== 归档回执 sha256 ===
cb834eb8c1119dd5810ad23bfb406ae7f8d4c58529a99e0ed83ad4151cf2008d *teamwork/command_center/dispatcher/receipts/cmd-20261109-095518-174-A3.json
=== 最终 sha256 边界 ===
c20c0505db6c306cf935fa3bbd79930254661771b82a7f448b8de804b9263386 *godot/scenes/hud.tscn
461f19c74686acb9fd92aa4ed0aaa023d60fad604d874684634cecb64261f5fa *godot/scenes/courtyard.tscn
```

- 归档回执 `dispatcher/receipts/cmd-20261109-095518-174-A3.json` 经 `json.load` 验证合法，`task_id` / `ai` / `status` 三字段与派单模板逐字一致，`result` 引用 `DONE-R18.md` 实际结论；`outbox/` 为空是中枢已消费的正常态（非未写、非丢失），**不重复写第二份回执**（幂等 / 并发保护）。
- 首次核对命令因回执已被消费移走而报 `FileNotFoundError`（`Exit Code 2`）—— **如实登记，未隐藏、未伪装成全绿**：这是消费时序所致，随后定位到归档文件并读回验证通过（见上）。

---

## ③ 未完成项与阻塞（明确是否降级）

**是否降级：否。** 本轮未设降级分支；改动落地，`CACHE_MODE_IGNORE` 回读 5 项全 PASS、`SUMMARY pass=6 fail=0 ok=true`、`VERIFY_EXIT=0`，两轮三段门禁 `GATE_OVERALL_EXIT=0`，未伪造输出、未冒充。

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 1 | 根 `CanvasLayer.layer` → 20 | **已完成** | 回读磁盘生效 `layer=20`；深蓝底 / 金色 1px 边框 / 金色文字 / 脚本挂载逐字不变。 |
| 2 | 5 项回读校验（`extends SceneTree` + `CACHE_MODE_IGNORE`） | **已完成** | ①~⑦ 全 PASS，完整实际 stdout 见 §2.3 / §2.4。 |
| 3 | 三段门禁复跑 | **已完成** | 两轮 G1/G2/G3 + `hud.gd` 补充门禁 + 真跑，全 `EXIT=0`，`SCRIPT ERROR/Parse Error/ERROR=0`，见 §2.5 / §2.6。 |
| 4 | 首次真跑 v1 退出残留 `ERROR`（RID / resource leaked） | **轮内已修复** | 显式 `root.free()` 后复跑 `ERROR=0`；首次输出（含 5 行残留）原样留档于 §2.2，未删除、未掩盖。 |
| 5 | `[ChunkManager] 未找到 ChunkRoot` WARNING | 如实保留 · 非本轮引入 | 工程既有现象（`chunk_streaming.gd:51 _bootstrap`），真跑 stderr 出现，非 ERROR，历轮已登记。 |
| 6 | `2 ObjectDB instances were leaked at exit` WARNING | 如实保留 · 非本轮引入 | 工程既有现象（`object.cpp:2536 cleanup`），G3 / 真跑均出现，非 ERROR，`DONE-R17.md §2.5/§4` 已登记，未隐藏、未宣称零 WARNING。 |
| 7 | 光尘遮挡的**运行期画面验收** | 未做 · 既有长期项 · 不阻塞本轮 | 本轮按派单只做静态 `layer` 修复 + `CACHE_MODE_IGNORE` 落盘回读 + 三段门禁；「光尘是否还落在 HUD 面板上」需抓帧 / 人工试玩验证，属历轮登记的长期视觉验收项，未在派单范围，如实登记不冒充已验收画面。 |
| 8 | canvas 世界口径 | 只登记 · 不裁决 | `FXLayer(layer=10)` 在 SubViewport 内、HUD 在主 viewport，两者 layer 数值不直接可比（`HD2D-FX-PLAN.md §1.1/§2.2 #1`）；本轮按派单执行 `layer=20`，不越界裁决 Rank-1 场景装配、不改 `courtyard.tscn`。 |
| 9 | `courtyard.tscn` 收尾并发改动 | 如实登记 · 非本实例所为 | `10:03:10` 并发实例改动使 sha256 `306b2467…`→`461f19c7…`；本实例零写入、不回退 / 不覆盖 / 不裁决（并发保护，见 §2.9）；回执按幂等不重写，差异已在本报告更正登记。 |

**阻塞：无功能性阻塞。** 本轮无跨工位依赖、无待总指挥裁决项、无外部输入缺失。派单四项要求（提高根 `CanvasLayer.layer` 到 20；保持深蓝底不透明 / 金色 1px 边框 / 金色文字不变；`CACHE_MODE_IGNORE` 回读 layer / 背景色 / 边框色 / 文字色 / 脚本仍挂并贴实际 stdout；三段门禁复跑）均真实达成，本实例未碰 `courtyard.tscn`。§2.9 的并发改动属 Rank-1 独占文件的并行行为，非本实例写入、非本轮交付缺陷，只登记不回退，不影响本轮完成判定。

**约束对照**：默认不刺探 ✓（只读必读件 / 本工位历史件 / FX 方案件 / 工程根必要资源 / 本工位历史回执归档格式，未读中枢状态或其它 AI outbox）；零付费 ✓；不伪造输出 ✓（含首次 v1 残留输出原样留档）；中文 UTF-8 无 BOM ✓；Godot 4 合法语法 ✓（预检 / G2 / `hud.gd` 门禁 `EXIT=0`）；不碰 `courtyard.tscn` ✓；只写可写范围 4 个文件 ✓；不自行 git ✓。

**回执**：按本轮 `task_id` 写 `teamwork/command_center/ai/3/outbox/cmd-20261109-095518-174-A3.json`，已由中枢实时消费归档至 `teamwork/command_center/dispatcher/receipts/cmd-20261109-095518-174-A3.json`（`json_valid=True`、`task_id` / `ai` / `status` 三字段逐字一致、内容逐字相同，见 §2.10）；`outbox/` 为空是正常消费态、非未写、非丢失（`DONE-R17.md §①` 已登记的预期流程）。不重复写第二份回执（并发保护 / 幂等）。
