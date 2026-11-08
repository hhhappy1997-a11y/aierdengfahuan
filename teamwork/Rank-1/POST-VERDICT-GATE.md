# POST-VERDICT-GATE.md · Rank-1 R11 裁决执行后的全量门禁回归

> 轮次：R11「裁决执行后的全量门禁回归」
> 任务单 id：`cmd-20261109-040336-519-A1`（派单 `Rank-1\任务书-R11.md` / `调度任务单-latest.json`）
> 依据：`00-汇总.md` §4 总指挥裁决、`GATE-FINAL.md`（R9 门禁口径与计数）、`任务书-R11.md`
> 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe` —— 本轮 `--version` 实测 `4.7.2.stable.official.ed1daf0bf`（`VERSION_EXIT=0`）
> 工程根：`<root>` = `F:/Game/aierdengfahuan/godot`
> 日志留存：`C:/Users/62668/AppData/Local/Temp/r1_r11_gate/`（`r1_g1.log` / `r1_g2_all.log` / `r1_g3.log` / `r1_all.log` / `final_g1.log` / `final_g2_all.log` / `final_g3.log` / `final_all.log`）
> **全部计数来自真跑实际输出 grep，未伪造、未冒充全绿**；完整自检见 `DONE-R11.md` §2。

---

## 1. 裁决执行状态（门禁时序前提）

`00-汇总.md` §4 共 9 项裁决。本轮 R11 的可写/核对范围只覆盖 `godot\` 工程根，逐项登记如下：

| 裁决 | 结论 | 与本轮门禁的关系 / 落位状态 |
|---|---|---|
| **A1** | E-8 采用方向 A：`boss_01_margit.tres` 的 `max_resistance` 330/360/320 → **400/480/420** | **已落位**（Rank-2 R10 执行，本轮只读核对），落 `godot\data\combat\boss_01_margit.tres`，纳入本轮全量门禁 |
| A2 | `SpawnRequest` 权威件 `scripts/rpg/` | 已执行（R8），非本轮变更 |
| **A3** | `SaveSystem` 保留 Rank-1 装配占位、不指向 `save_delta_writer.gd` | **已定型，本轮只读确认未改动**（§5.1） |
| A4 | §4.4 以 R2 落地 5 条口径为准，旧措辞回改 | 文档措辞回改，由主 AI / 后续轮次执行；不属 `godot\` 工程根，不属本轮门禁范围，不越界核对/改动 |
| **A5** | chunk flag 采用 `-` → `neg` 转义，不改正则与白名单 | **已定型，本轮只读确认未改动**（§5.2） |
| A6 | 契约 §2 两段式示例回改为严格三段式 | 契约示例回改由主 AI 自行执行（`任务书-R11.md` 明确「A6 契约示例由主 AI 自行回改」）；不属 `godot\` 工程根，不越界 |
| A7 | `schema`/`schemas` 路径已统一 | 已执行（R6），非本轮变更 |
| A8 | `128bit` 暂按 128px 理解、待用户确认 | 口径待用户确认，非本轮变更（不自行改口径） |
| **A9** | 占位画面 `layer=-10` / `integer_scale=2` / Nearest 定型 | **已定型，本轮只读确认未改动**（§5.3） |

> 结论：本轮门禁的时序前提「Rank-2 数值回改落位」**已满足**。A4/A6 为文档/契约文字回改，不落 `godot\` 工程根，本轮不越界核对、不擅改，如实登记为边界。

### 1.1 A1 落位时序（如实登记并行写入，不抹去中间态）

Rank-2 R10（`任务书-R10.md` / `调度任务单-latest.json` 均 04:03 下发）与本轮 R11 为同批并行派单。四次**只读**复核 `godot/data/combat/boss_01_margit.tres`：

| 次序 | 时点 | `max_resistance`（bleed / poison / frost） | mtime | 判读 |
|---|---|---|---|---|
| 1 | 开工首次 | 330 / 360 / 320 | 02:33:51 | **尚未落位**（R7 装配原值） |
| 2 | 引擎 `--version` 前后（04:07:23） | **400 / 480 / 320** | 04:07:23 | **写入中间态**：bleed/poison 已改、frost 未改 |
| 3 | ROUND1 之后（04:07:27） | **400 / 480 / 420** | 04:07:27 | **完整落位** |
| 4 | FINAL 之后 | **400 / 480 / 420** | 04:07:27 | **稳定** |

- 第 2 次复核时 Rank-2 仍在逐项写入（该次只读核对的是工程根副本）；第 3 次复核同时核对工位副本 `teamwork/Rank-2/boss_01_margit.tres`，其 `max_resistance` 三项亦为 400/480/420（mtime 04:07:27），与工程根副本数值一致。
- ROUND1 的 G1 `--import` 恰落在第 2 次的中间态（ frost=320 ）附近；故按 `GATE-FINAL.md`（R9 §5）先例，**不把 ROUND1 当作最终计数依据，另跑稳定态 FINAL 作为最终结论**，两轮结果均如实保留。
- 数值回改只改 `max_resistance` 三个数值；`threshold` / `resistance_gain_per_trigger` / `trigger_damage*` / `trigger_poise_damage` / N=8 / 校验式 / schema 文档口径均未改动（对照本轮首次全文读取 `boss_01_margit.tres` 214 行）。

---

## 2. 门禁命令口径（三段，与 R7/R8/R9 同口径）

| 段 | 实际命令 |
|---|---|
| G1 | `<godot> --headless --path <root> --import` |
| G2 | 对工程根**全部** `.gd` 逐个 `<godot> --headless --path <root> --check-only --script res://<f>` |
| G3 | `<godot> --headless --path <root> --quit` |
| 判据 | 合并日志 `grep -c "SCRIPT ERROR"` / `"Parse Error"` / `"ERROR"` / `"WARNING"` / `"leaked"` |

- 本轮**完整三段复跑两次**：ROUND1（首次，含 A1 写入中间态）、FINAL（A1 稳定落位后最终快照），两次结果一致。
- 计数口径：`grep -c "ERROR"` 会把 `SCRIPT ERROR: ...` 行一并计入（与 `GATE-FINAL.md` §1、`GATE-REPORT-R8.md` §2 同口径）；本轮两类均为 0，无计入差异。
- 本轮工程根全量 `.gd` = **52** 个（R9 `GATE-FINAL.md` 为 51 个；R9 之后 Rank-3 联调新增 `godot/scripts/rpg/r8_neg_chunk_test.gd` 一件，mtime 03:25:57，非本轮新增）。本轮对 52 个**全量**逐个真跑，未抽样。

---

## 3. 逐段实际输出（ROUND1 / FINAL，逐字贴 stdout）

### 3.1 ROUND1 三段 + 合并日志 grep

```text
=== R11 ROUND1 G1 --headless --import ===
G1_EXIT=0
=== R11 ROUND1 G2 全量 .gd --check-only --script ===
G2_TOTAL=52 G2_FAIL=0
G2_FAIL_LIST=<none>
=== R11 ROUND1 G3 --headless --quit ===
G3_EXIT=0
=== R11 ROUND1 合并日志 r1_all.log grep 计数 ===
SCRIPT ERROR: 0
Parse Error: 0
ERROR lines: 0
WARNING lines: 1
leaked lines: 1
--- ERROR 实际行 ---
(none)
--- WARNING 实际行 ---
123:WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
```

### 3.2 FINAL 三段 + 合并日志 grep（含 A1 副本核对）

```text
=== A1 落位两份副本逐字节核对 ===
godot/data/combat/boss_01_margit.tres teamwork/Rank-2/boss_01_margit.tres differ: byte 119, line 3
CMP_IDENTICAL=false
=== R11 FINAL G1 --headless --import ===
FINAL_G1_EXIT=0
=== R11 FINAL G2 全量 .gd --check-only --script ===
FINAL_G2_TOTAL=52 FINAL_G2_FAIL=0
FINAL_G2_FAIL_LIST=<none>
=== R11 FINAL G3 --headless --quit ===
FINAL_G3_EXIT=0
=== R11 FINAL 合并日志 final_all.log grep 计数 ===
SCRIPT ERROR: 0
Parse Error: 0
ERROR lines: 0
WARNING lines: 1
leaked lines: 1
--- ERROR 实际行 ---
(none)
--- WARNING 实际行 ---
123:WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
=== 日志行数/大小留档 ===
   16 /c/Users/62668/AppData/Local/Temp/r1_r11_gate/r1_g1.log
  104 /c/Users/62668/AppData/Local/Temp/r1_r11_gate/r1_g2_all.log
    4 /c/Users/62668/AppData/Local/Temp/r1_r11_gate/r1_g3.log
  124 /c/Users/62668/AppData/Local/Temp/r1_r11_gate/r1_all.log
   16 /c/Users/62668/AppData/Local/Temp/r1_r11_gate/final_g1.log
  104 /c/Users/62668/AppData/Local/Temp/r1_r11_gate/final_g2_all.log
    4 /c/Users/62668/AppData/Local/Temp/r1_r11_gate/final_g3.log
  124 /c/Users/62668/AppData/Local/Temp/r1_r11_gate/final_all.log
  496 total
```

> `CMP_IDENTICAL=false` 说明见 §7.1，属 Rank-2 工位交付件观察项，只登记不擅改，**不影响 `godot\` 工程根本轮门禁结论**（工位副本不在工程根内，G1/G2/G3 均不加载它）。

---

## 4. 最终门禁计数与前后对照（核心）

| 判据 | R9 `GATE-FINAL.md` FINAL | **R11 ROUND1** `r1_all.log` | **R11 FINAL** `final_all.log` |
|---|---|---|---|
| G1 `--import` EXIT | 0 | **0** | **0** |
| G2 全量 `.gd` | 51/51 EXIT=0 | **52/52 EXIT=0** | **52/52 EXIT=0** |
| G3 `--quit` EXIT | 0 | **0** | **0** |
| `SCRIPT ERROR` | 0 | **0** | **0** |
| `Parse Error` | 0 | **0** | **0** |
| **`ERROR` 行数** | **0** | **0** | **0** |
| `WARNING` 行数 | 1 | 1 | 1 |
| `leaked` 行数 | 1 | 1 | 1 |
| `G2_FAIL_LIST` | `<none>` | **`<none>`** | **`<none>`** |

- `ERROR` 实际行：**(none)**（ROUND1 / FINAL 两次均无）。
- `WARNING` 实际行（两次均为同一行）：`123:WARNING: 2 ObjectDB instances were leaked at exit (run with \`--verbose\` for details).`
- **验收结论：裁决 A1 数值回改落位后，全量三段门禁 `ERROR=0`、`SCRIPT ERROR=0`、`Parse Error=0`，G1/G3 EXIT=0、G2 52/52 EXIT=0，与 R9 基线一致，无回归。**

---

## 5. 三项定型只读确认（A3 / A5 / A9，均未改动）

### 5.1 A3 · `SaveSystem` 保留 Rank-1 装配占位 ✅

- `godot/project.godot:45`：`SaveSystem="*res://scripts/world/save_system.gd"` —— **仍指向 Rank-1 装配占位件**，未指向 `scripts/rpg/save_delta_writer.gd`。
- `godot/scripts/world/save_system.gd`（19 行）：`extends Node`，文件头注释「SaveSystem autoload 装配占位（R8 · Rank-1）」「不实现任何存档功能」，`_ready(): pass`；注释明确「真实实现由 Rank-3 落位后，由 HOST 裁决把本 autoload 改指向 3 号正式件」。
- 结论：与 `00-汇总.md` §4 A3 定型一致，**本轮未改动**。

### 5.2 A5 · chunk flag `-` → `neg` 归一 ✅

- `godot/scripts/rpg/chunk_world_bridge.gd:37`：`const NEG_TOKEN: String = "neg"`（`-1 → neg1`）。
- `:65-73` `sanitize_flag_segment()`：每个 `'-'` 编码为 `NEG_TOKEN`，其余 `[a-z0-9_]` 保留。
- `:93-94` `normalize_chunk_flag()`：`chunk_limgrave_-1_-1 → world.chunk_limgrave_neg1_neg1.loaded`；`:91-92` 注释含 `chunk_limgrave_0_-1 → world.chunk_limgrave_0_neg1.loaded`。
- `:38` `FLAG_KEY_REGEX = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"` —— **正则与白名单未改**（`:28-30` 注释明确「不改 world_state.gd:24 FLAG_KEY_REGEX、不改存档与flag规范.md §3.1 正则、不改 Rank-1 chunk_streaming*.gd 命名」）。
- 结论：与 §4 A5 定型一致，**本轮未改动**。

### 5.3 A9 · 占位画面 `layer=-10` / `integer_scale=2` / Nearest ✅

- `godot/scripts/render/hd2d_placeholder_attach.gd:17-18`：`DEFAULT_CANVAS_LAYER = -10`、`DEFAULT_INTEGER_SCALE = 2`；`:44` `placeholder.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST`。
- `godot/scripts/render/attach_hd2d_placeholder.gd:32`：`HD2D_ATTACH.attach(root, {"canvas_layer": -10, "integer_scale": 2})`（R9 接入调用，值未改）。
- `godot/scenes/courtyard.tscn:123` `layer = -10`、`:126` `texture_filter = 1`（Nearest）、`:128` `integer_scale = 2` —— 场景落位值三项齐备。
- `godot/project.godot:141`：`textures/canvas_textures/default_texture_filter=0`（项目级 Nearest 兜底，未改）。
- 结论：与 §4 A9 定型一致，**本轮未改动**；遮挡/缩放 4 项未反复改。

---

## 6. ERROR 归零 / 无回归结论

- **G1 `--import` EXIT=0**：全工程资源扫描、脚本类注册、`.tres` 资源加载（含 A1 回改后的 `boss_01_margit.tres`）无 ERROR。
- **G2 52 个 `.gd` 全 `--check-only --script` EXIT=0**：全工程 GDScript 静态解析零错误，`FINAL_G2_FAIL_LIST=<none>`。
- **G3 `--quit` EXIT=0**：主场景 `Main.tscn` + 5 个 autoload 完整启动并正常退出，无 `ERROR` / `SCRIPT ERROR`。
- **结论**：`F:/Game/aierdengfahuan/godot` 在 Godot 4.7.2 下、`00-汇总.md` §4 裁决（A1 数值回改落位、A3/A5/A9 定型保持）之后，**可导入、可静态检查、可启动退出，`ERROR=0`、`SCRIPT ERROR=0`，与 R9 基线一致，无回归**。
- **边界**：以上均为 `--headless` 门禁结论；**未做窗口渲染 / 人工试玩 / HD-2D 运行期画面可见性验收**，不宣称「已渲染可见」、不宣称「已能出图」。
- 唯一 `WARNING`（1 条 `ObjectDB instances were leaked at exit`）为 WARNING 级、非 ERROR、非 SCRIPT ERROR、不改退出码（G3 EXIT=0）；与 `ObjectDB-leak-定位与消除-R5.md` / `GATE-FINAL.md` §6 结论一致（ChunkManager 在途 `load_threaded_request` 遇 `--headless --quit` 立即退出的 `RefCounted` 残留）。按契约 §10 固定 `--headless --quit`，**本轮不宣称 WARNING 清零、未擅自改既有件**。

---

## 7. 观察项（只登记，不擅改，不冒充全绿）

### 7.1 Rank-2 工位副本与工程根副本 `cmp` 不一致

- 真跑输出：`godot/data/combat/boss_01_margit.tres teamwork/Rank-2/boss_01_margit.tres differ: byte 119, line 3` / `CMP_IDENTICAL=false`。
- `diff` 逐字结果（仅前 5 行 ext_resource 路径不同）：

```text
3,7c3,7
< [ext_resource type="Script" path="res://scripts/combat/boss_data.gd" id="1_boss"]
< [ext_resource type="Script" path="res://scripts/combat/phase_data.gd" id="2_phase"]
< [ext_resource type="Script" path="res://scripts/combat/move_data.gd" id="3_move"]
< [ext_resource type="Script" path="res://scripts/combat/poise_config.gd" id="4_poise"]
< [ext_resource type="Script" path="res://scripts/combat/status_buildup.gd" id="5_status"]
---
> [ext_resource type="Script" path="res://data/schemas/boss_data.gd" id="1_boss"]
> [ext_resource type="Script" path="res://data/schemas/phase_data.gd" id="2_phase"]
> [ext_resource type="Script" path="res://data/schemas/move_data.gd" id="3_move"]
> [ext_resource type="Script" path="res://data/schemas/poise_config.gd" id="4_poise"]
> [ext_resource type="Script" path="res://data/schemas/status_buildup.gd" id="5_status"]
```

- 判读：两件 `max_resistance` 三项**均已同步为 400/480/420**；全文件 `cmp` 差异**仅为 5 条既有 `ext_resource path`**（工位稿 `res://data/schemas/*.gd` vs 运行件 `res://scripts/combat/*.gd`），是 R6 装配必需的路径修正，**改前即存在、非 A1 数值回改引入**。
- 复核 Rank-2 `DONE-R10.md` §1.3 / §84-85：已如实登记该差异——三个数值行逐字节一致（`VAL_DIFF_RC=0`）、排除 `ext_resource` 后全字段一致（`DIFF_RC=0`）、全文件 `CMP_RC=1` 且明确「不伪造『全文件逐字节相同』」，并登记为「只登记，未改两份 `.tres` 的 `ext_resource` 路径与任何文档口径」。**故此项属既有跨工位路径口径差异的如实登记，非本轮回归、也非 Rank-2 A1 交付缺陷**；收口复核（04:12）两份副本仍保持 `CMP_IDENTICAL=false`，数值三项仍一致。
- **处置**：该副本在 `teamwork\Rank-2\`，**不属本工位可写范围，本轮只登记不擅改**；其不在 `godot\` 工程根内，G1/G2/G3 均不加载，**不影响本轮门禁 `ERROR=0` 结论**。是否需要 HOST 裁决统一两份副本路径，本轮不裁定。
- 旁证：Rank-2 `DONE-R10.md` §19 亦独立真跑三段门禁 `52/52 --check-only EXIT=0`、`SCRIPT ERROR=0`、`ERROR=0`、仅 1 条既有 leaked WARNING，与本轮 FINAL 结论互相印证。

### 7.2 并行完成标志时序

- 门禁真跑时点（04:07~04:08）`teamwork/Rank-2/DONE-R10.md` 与 `ai/2` 回执尚未落盘；收口复核（04:12）二者均已就位——`DONE-R10.md` 已落盘（18472 B）、`ai/2` 回执已被 dispatcher 消费归档（`dispatcher.log` 04:11:07 / 04:12:24 留痕）。
- **A1 数值回改本身在 04:07:27 即已稳定落位**（§1.1 第 3/4 次复核），本轮门禁时序前提已满足，未因完成标志晚落盘而等待或代写。
- 按「默认不刺探」，本轮未轮询、未等待、未代写 Rank-2 完成标志；仅按落盘事实登记。

### 7.3 其余

- 1 条 leaked WARNING 仍在（见 §6），非 ERROR，未消除、未冒充清零。
- A4/A6 文档/契约措辞回改不属本轮范围（§1），本轮未越界核对或改动。

---

## 边界声明

- 本轮**实际写入**：`Rank-1\POST-VERDICT-GATE.md`、`Rank-1\DONE-R11.md`、`command_center\ai\1\outbox\cmd-20261109-040336-519-A1.json` 回执（写入后于 04:12:06 被中枢 dispatcher 正常消费归档至 `command_center\dispatcher\receipts\cmd-20261109-040336-519-A1.json`）；以及 `godot\.godot\` 缓存由 G1 `--import` 生成/更新（引擎产物，保留）。
- 本轮**未写** `godot\` 下任何源文件（`project.godot` / `scenes\` / `scripts\` / `data\` 全部只读，未改动一字）；收口 `find godot -newermt "2026-11-09 04:03:37"` 显示本轮 `godot\` 唯一改动的源文件是 Rank-2 执行 A1 的 `data\combat\boss_01_margit.tres`（mtime 04:07:27），非本工位所写；未写 Rank-2/3/4 子目录、`00-群聊总线.md` / 总纲 / 契约 / 任务书 / `00-汇总.md`。
- 未自行 `git commit` / `git push`；未调用付费 API / 外部服务；未写探针 / 测量 / preflight 脚本；既有件未重做；中文 UTF-8。
- 本报告全部结论来自真跑实际输出（ROUND1 / FINAL 两次完整三段），**未伪造输出、未冒充全绿**；A1 并行写入中间态、两份副本 `cmp` 不一致、1 条 leaked WARNING 均如实登记。
