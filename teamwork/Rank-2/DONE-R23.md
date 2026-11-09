# DONE-R23 · Rank-2 交付完成登记

- 任务单：`cmd-20261109-133602-471-A2`（[ROUND=R23]）
- AI：2（战斗系统与数据驱动）
- 状态：**完成（done）**，无阻塞
- 契约文档：`teamwork/Rank-2/ASSET-SPEC-R23.md`
- 真跑日志：`teamwork/Rank-2/R23-gate1-import.log` / `R23-gate2-checkonly.log` / `R23-gate3-quit.log` / `R23-verify650-run.log`
- 回执：`teamwork/command_center/ai/2/outbox/cmd-20261109-133602-471-A2.json`

---

## ① 实际交付清单

| 文件 | 类型 | 说明 |
|---|---|---|
| `teamwork/Rank-2/ASSET-SPEC-R23.md` | **新增** | R23 新素材 I-5 接入契约：**58 条可执行校验条目**（A/B/C/D/E 可校验 56 条 + F 挂起 2 条），每条「文件 / 字段 / 期望值 / 判定方法」；含 ≤256→≥256 变更登记、`128bit` 歧义挂起、player 8 / boss 3 pose 帧序表、import.json 字段清单、R23B 接入流程 |
| `teamwork/Rank-2/R23-gate1-import.log` | **新增**（真跑日志） | G1 `--headless --import`（16 行） |
| `teamwork/Rank-2/R23-gate2-checkonly.log` | **新增**（真跑日志） | G2 `--check-only --script res://scripts/verify_frame_data.gd`（2 行） |
| `teamwork/Rank-2/R23-gate3-quit.log` | **新增**（真跑日志） | G3 `--headless --quit`（4 行） |
| `teamwork/Rank-2/R23-verify650-run.log` | **新增**（真跑日志） | 真跑 `verify_frame_data.gd` 的 650 回归 stdout（163 行） |
| `teamwork/Rank-2/DONE-R23.md` | **新增** | 本文件 |
| `teamwork/command_center/ai/2/outbox/cmd-20261109-133602-471-A2.json` | **新增**（回执） | 本单精确路径回执 |

**未写 / 未改**：`project.godot`（BEFORE/AFTER stat 均 `1794194044 6664`，完全一致）、任何 `godot/` 工程源文件（脚本 / 场景 / `.tres`）、`godot/assets/generated/chars/import.json` 等既有 import.json（**只读引用作基线证据**）、`verify_frame_data.gd`（**只调用、未修改**）、`combat_data_validator.gd`（**只调用、未修改**）、其它 Rank 文档、工程根 `command_center/`。未新建只读探针/巡检脚本；未主动扫目录做进度巡检；未自行 git commit / push。

> 三段门禁中 `--headless --import` 由引擎自动维护 `.godot/` 缓存（class/uid cache）；本轮**无新增 class_name、无人工新增/修改任何工程源文件**，`project.godot` 定点 stat 前后一致。

---

## ② ASSET-SPEC-R23.md 契约条目摘要

`ASSET-SPEC-R23.md` §3 共 **58 条**，按组：

| 组 | 条目 | 条数 | 覆盖 |
|---|---|---:|---|
| A 几何/画布 | I-5-A01~A10 | 10 | 128px 基准画布、128×128 单帧、禁 32 交付尺寸、nearest/lossless/无 mipmaps |
| B 色彩/alpha | I-5-B01~B13 | 13 | 色数 ≥256、废止 ≤256、RGBA8、保留 alpha（声明+PNG 实测双重校验） |
| C pose/帧序/坐标系 | I-5-C01~C15 | 15 | 对齐 player_spriteframes.tres(8) / boss_spriteframes.tres(3) |
| D import.json 字段 | I-5-D01~D12 | 12 | 必填 22 字段集合、废止字段集合、frames 结构、声明/实测交叉核对 |
| E 零付费/DNF | I-5-E01~E06 | 6 | 零付费、DNF 仅参考不进发布包 |
| F `128bit` 挂起 | I-5-F01~F02 | 2 | 待用户确认，不计 PASS/FAIL |

**任务① 七项要求 → 条目落点（逐项可校）**：

| 任务要求 | 落点条目 | 期望值（可执行） |
|---|---|---|
| 128px 基准画布 | A01~A06 | `base_canvas_px=128`、`frame_width=frame_height=128`、`region=Rect2(index*128,0,128,128)`、`frame_width/height!=32` |
| 色数 ≥256（不再 ≤256） | B01~B08 | `min_colors=256`、`unique_opaque_rgb>=256`、`frames[].colors>=256`、废止 `max_colors(≤256)`/`indexed:true`/`quality_gate<=256色`/`ImageQuantize(256)`/`MEDIANCUT 256`/`hd2d_index_256_v1`/`shared_sheet_256` |
| RGBA 保留 alpha | B09~B13 | `pixel_format="RGBA8"`、`alpha_preserved=true`、PNG IHDR color type=6、alpha 通道实测非全 255 且含透明像素、声明值与实测一致 |
| pose 名/帧序/坐标系与既有 tres 一致 | C01~C15 | player 8 pose `[idle,walk,run,roll,attack_light,attack_heavy,hitstun,death]` region.x=0/128/…/896；boss 3 pose `[p1_dagger_slash,p1_staff_slam,p2_holy_hammer]` region.x=0/128/256；`columns/rows=8/1` 与 `3/1`；`anchor=[0.5,1.0]`；C14 禁扩成 5 帧、C15 与 `BOSS_POSE_MOVES` 键集合交叉核对 |
| import.json 字段清单 | D01~D12 | 必填 22 字段逐 key 存在、废止字段逐 key/子串不存在、`frames[]`/`actions[]` 结构合法、合法 JSON |
| `128bit` 歧义保留待用户确认 | §2 + F01~F02 | `bit_depth_128_spec="PENDING_USER_CONFIRMATION"`；不编码进任何字段期望值；挂起不计 PASS/FAIL；候选 (a)~(d) 登记不裁决 |
| 零付费 / DNF 仅参考不进发布包 | E01~E06 | `paid_service=false`、`zero_external_dependency=true`、`dnf_reference_only=true`/`dnf_in_release=false`、发布包无 DNF 贴片、`pipeline` 无付费服务标识 |
| 供 R23B 接入时逐项校验 | §4 | 逐条输出 `ID/实际值/期望值/PASS|FAIL/来源`；全 PASS 才接入；接入后复跑 650/533 回归 + 三段门禁 |

---

## ③ 真跑 PASS 数字（逐字关键行，来源 `R23-verify650-run.log`）

`verify_frame_data.gd` 单跑一次，内部组C 已真实实例化 `CombatDataValidator.validate_all()`，一次覆盖 650 与 533 两个数字：

```
[CombatDataValidator] validate_all() | checks=533 pass=533 fail=0 errors=0 | E-8 max_resistance(bleed/poison/frost)=400.0 / 480.0 / 420.0
  组A 文档/帧数据核对 | DOC_PASS=111 DOC_FAIL=0 -> DOC_CONSISTENCY=PASS
  组B R19 裁决值 | VERDICT_PASS=6 VERDICT_FAIL=0 -> MATCH
  组C CombatDataValidator.validate_all()（类级真实实例化） | VALIDATOR_CHECKS=533 VALIDATOR_PASS=533 VALIDATOR_FAIL=0 -> VALIDATOR_ERROR=0
  合计 | PASS_COUNT=650 FAIL_COUNT=0
  E-8 max_resistance (bleed/poison/frost) = 400.0 / 480.0 / 420.0
  RESULT=ALL_MATCH
```

| 项 | 真跑值 | 结论 |
|---|---|---|
| `verify_frame_data.gd` 合计 | `PASS_COUNT=650 FAIL_COUNT=0` | **`RESULT=ALL_MATCH`**（111+6+533=650） |
| `CombatDataValidator.validate_all()` | `checks=533 pass=533 fail=0 errors=0` | **`VALIDATOR_ERROR=0`** |
| 翻滚 `action_04_roll` | `startup=4 active=9 recovery=9 inv=[4,13) logic_fps=60 total=22` | **4/9/9=22 帧@60、无敌 [4,13) 不回退** |
| 玩家 8 动作 | `logic_fps=[60,60,60,60,60,60,60,60]` | @60 不回退 |
| Boss 三招 | `p1_dagger_slash=47` / `p1_staff_slam=71` / `p2_holy_hammer=91` | hit `[18,23)/[30,37)/[42,51)` **不回退** |
| E-8 max_resistance | `400.0 / 480.0 / 420.0` | bleed/poison/frost **不回退** |

`[ACTUAL]` 实际值快照（逐字）亦记录翻滚、8 动作、Boss 五 pose_keys、E-8 数值，与上表一致；均从 `res://data/combat/*.tres` 真实读取、非硬编码。

---

## ④ 门禁结果（`D:/Godot/Godot_v4.7.2-stable_win64.exe`）

| 段 | 命令 | EXIT |
|---|---|---|
| G1 | `--headless --path F:/Game/aierdengfahuan/godot --import` | `G1_IMPORT_EXIT=0` |
| G2 | `--headless --path ... --check-only --script res://scripts/verify_frame_data.gd` | `G2_CHECKONLY_EXIT=0` |
| G3 | `--headless --path ... --quit` | `G3_QUIT_EXIT=0` |
| 真跑 | `--headless --path ... --script res://scripts/verify_frame_data.gd` | `G4_VERIFY650_EXIT=0` |

四段日志 grep（全部 0）：

```
R23-gate1-import.log    | SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_COLON=0 FAIL_TAG=0 FAILCOUNT_GT0=0
R23-gate2-checkonly.log | SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_COLON=0 FAIL_TAG=0 FAILCOUNT_GT0=0
R23-gate3-quit.log      | SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_COLON=0 FAIL_TAG=0 FAILCOUNT_GT0=0
R23-verify650-run.log   | SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_COLON=0 FAIL_TAG=0 FAILCOUNT_GT0=0
```

- **`SCRIPT ERROR=0` 三段门禁全部成立**，四段 `EXIT=0`，`FAIL_COUNT>0` 命中数 0。
- `project.godot` BEFORE/AFTER stat 均 `1794194044 6664`，**未写**。
- **既有 WARNING（非 ERROR、非本轮问题，如实登记）**：`R23-gate3-quit.log` 1 条 `2 ObjectDB instances were leaked at exit`；`R23-verify650-run.log` 2 条（`[ChunkManager] 未找到 ChunkRoot` + `2 ObjectDB instances were leaked at exit`）。与 R16/R18/R19/R20/R21/R22 历史日志同类，`ERROR_COLON=0`、EXIT 仍为 0，未处理、未越界修改。

---

## ⑤ 未完成项与阻塞

- **阻塞：无**。本轮 4 项（① ASSET-SPEC-R23.md 契约、② 650/533 数据回归真跑、③ 三段门禁 grep SCRIPT ERROR=0、④ 只写 Rank-2 不改工程文件）全部完成。
- **待用户确认（非本轮、不擅自解释）**：`128bit` 歧义（候选 128px 画布笔误 / 128-bit 位深 / 拆分指画布+位深 / 其它）。已登记于 `ASSET-SPEC-R23.md §2`，`bit_depth_128_spec="PENDING_USER_CONFIRMATION"` 挂起，确认后补条目。
- **待 R23B 执行（本轮素材未产出，不伪造校验结果）**：§3 的 56 条可校验条目本轮**未执行**（无 R23 新素材可校），须 R23B 产出后按 §4 逐条校验；`godot/assets/generated/r23/` 归 Rank-4，本轮未创建、未写入。
- **待 Rank-4 / 总指挥确认**：R23 新增字段命名（`min_colors` / `pixel_format` / `alpha_preserved` / `paid_service` / `dnf_*` / `bit_depth_128_spec`），确认后锁定再执行校验（ASSET-SPEC §3 D 末）。
- **不回改既有基线**：`chars/import.json` 等既有 ≤256 交付保持原值（本轮只读作证据），R23 新口径只作用于 R23 新素材，避免污染既有回归。
- **口径边界**：R23 变更仅作用于 I-5 素材规格，不触碰任何 `godot/data/combat/*.tres` 数据层；接入后仍须按 §4 第 5 步复跑 650/533 回归确认不回退。
- **零付费 / 未引入付费素材生成服务**；未新建只读探针/巡检脚本；未主动扫目录做进度巡检；未伪造产物、未谎报成功、未自行 git 提交。

---

## ⑥ 回执

写入精确路径 `F:/Game/aierdengfahuan/teamwork/command_center/ai/2/outbox/cmd-20261109-133602-471-A2.json`（在 `teamwork/command_center/` 下，**非**工程根 `command_center/`），keys 恰为 4 个必需字段：

```json
{"task_id":"cmd-20261109-133602-471-A2","ai":2,"status":"done","result":"引用 DONE-R23.md 实际结论：R23 已新写 teamwork/Rank-2/ASSET-SPEC-R23.md，定义 I-5 接入契约共 58 条可执行校验条目（A 几何10/B 色彩alpha13/C pose帧序坐标系15/D import.json字段12/E 零付费DNF6/F 128bit挂起2），逐条含文件/字段/期望值/判定方法：128px 基准画布、色数>=256（废止 <=256 上限与 ImageQuantize(256)）、RGBA8 保留 alpha、player 8 pose 与 boss 3 pose 帧序 region.x=index*128 对齐既有 tres、import.json 必填22字段与废止字段清单、128bit 歧义挂起待用户确认（bit_depth_128_spec=PENDING_USER_CONFIRMATION、不编码进期望值）、零付费与 DNF 仅参考不进发布包；供 R23B 逐项校验。真跑 verify_frame_data.gd 确认 PASS_COUNT=650 FAIL_COUNT=0 RESULT=ALL_MATCH，CombatDataValidator.validate_all() checks=533 pass=533 fail=0 errors=0、VALIDATOR_CHECKS=533 VALIDATOR_ERROR=0；翻滚 4/9/9=22 帧@60、无敌[4,13)、Boss 三招 47/71/91、E-8 400/480/420 全部不回退。引擎 4.7.2 三段门禁 G1 --import / G2 --check-only --script / G3 --quit 加真跑 EXIT 全 0、四段 grep SCRIPT ERROR=0/Parse Error=0/ERROR:=0/[FAIL]=0/FAIL_COUNT>0=0，project.godot BEFORE/AFTER stat 1794194044 6664 一致未写。本轮只写 teamwork/Rank-2/（ASSET-SPEC-R23.md / DONE-R23.md / R23-*.log）与 outbox 回执，未改任何 godot/ 工程文件与其它 Rank 文档、未自行 git。未完成项：128bit 歧义待用户确认、R23 新素材未产出故 56 条校验条目待 R23B 执行、R23 新增字段命名待 Rank-4/总指挥确认；既有 WARNING（ObjectDB leaked / ChunkManager 未找到 ChunkRoot）非 ERROR 未处理。"}
```

**送达态（写后只读核验，13:47）**：回执写入上述精确路径后已被调度中枢即时消费并归档为 `teamwork/command_center/dispatcher/receipts/cmd-20261109-133602-471-A2.json`（1736 B，JSON 解析通过：`keys=['ai','result','status','task_id']` 恰 4 个必需字段、`task_id=cmd-20261109-133602-471-A2` / `ai=2` / `status=done`，`result` 1138 字符引用 DONE-R23.md 实际结论）；`teamwork/command_center/ai/2/status.json` 现为 `state=idle` / `current_task=""` / `completed=25`（R22 为 24 → +1）；工程根 `F:/Game/aierdengfahuan/command_center/` 不存在（未误写）。故 outbox 现为空是「回执已送达中枢」的正常终态，非「回执未写 / 写错路径」。按并发保护「不重复写第二份回执」，本实例不再重写 outbox。
