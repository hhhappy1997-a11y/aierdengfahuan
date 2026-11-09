# DONE-R21.md —— Rank-2 交付（cmd-20261109-115818-641-A2 / ROUND=R21）

> **派单**：调度中枢 `cmd-20261109-115818-641-A2`，`[ROUND=R21]`，`【R21 · Rank-2 CombatDataValidator 类落位与类级实例化真跑】`。
> **定位**：R20 如实登记「`CombatDataValidator` 类自 R2 起未落位工程根、组C 495 项只是 §9 等价校验同跑」。本轮**补上真实类**、把组C 改为**类级实例化真跑**并替换等价同跑。
> **硬约束遵守**：直接改、直接真跑；不新建只读探针 / 巡检脚本，不主动扫目录做进度巡检；只写 `teamwork/Rank-2/`、`godot/scripts/verify_frame_data.gd`、`godot/scripts/combat/`；**不注册 autoload**（本轮 `project.godot` 冻结、无人可写）；引擎三段门禁 `--headless --import → --check-only --script → --headless --quit`（+ G4 主真跑），`grep SCRIPT ERROR=0`；零付费 / 零外部依赖；不伪造产物、不谎报成功、不自行 git 提交。
> **绝对未碰**：`project.godot` / `courtyard.tscn` / `quality_settings.*` / `hud.gd` / `hd2d_fx.*`；Boss 数值（`boss_01_margit.tres`）、`player_actions.tres`、`enemy_01_limgrave_soldier.tres` 一字未改；其它 Rank 独占文件未碰。

---

## ① 实际交付清单

### 1.1 新增文件（5 份手动交付 + 1 份引擎元数据）

| # | 文件 | 用途 |
|---|---|---|
| 1 | `godot/scripts/combat/combat_data_validator.gd` | **本轮核心**：`class_name CombatDataValidator` / `extends RefCounted` 真实类，`validate_all() -> Dictionary` 实现 §9 + 帧数据专项断言 |
| 2 | `teamwork/Rank-2/R21-verify-run.log` | 四段门禁 G1~G4 完整实际 stdout 原始留档（含 WARNING、EXIT、逐项 PASS 行、SUMMARY） |
| 3 | `teamwork/Rank-2/VALIDATOR-CLASS-R21.md` | 类路径 / 接口签名 / 断言覆盖 / 可复跑命令 / 真跑 stdout / PASS 变化说明 |
| 4 | `teamwork/Rank-2/DONE-R21.md` | 本文件 |
| 5 | `teamwork/command_center/ai/2/outbox/cmd-20261109-115818-641-A2.json` | 本轮回执（精确路径，位于 `teamwork/command_center/` 下） |
| 6 | `godot/scripts/combat/combat_data_validator.gd.uid` | **引擎 `--import` 自动生成的元数据**（19 B），非手动新建、非脚本、非探针/巡检件；如实登记 |

### 1.2 修改文件（1 份）

| # | 文件 | 改前 → 改后 |
|---|---|---|
| 7 | `godot/scripts/verify_frame_data.gd` | **组C**：由「按 §9 校验式的等价校验同跑」改为 `const VALIDATOR_SCRIPT = preload("res://scripts/combat/combat_data_validator.gd")` + `VALIDATOR_SCRIPT.new().validate_all()` **真实实例化类并调用**，组C 数字取自返回的 `checks/pass/fail/errors`；删除等价同跑死代码（`_validator_collect` / `_check_group_c` / `_max_move_range` / `_e8_actual_string` / `E8_MAX_RESISTANCE` / `_v_*` 采集容器）；`SUMMARY` 的 `VALIDATOR_CHECKS` 与 `E-8` 行改取类返回；**组A / 组B 全部函数与期望值常量逐字保留、未回退**；脚本头注释更新为 R21 并去掉「类未落位」的诚实声明（该缺口本轮已补） |

### 1.3 未改动的工程文件（契约核对）

- `godot/project.godot`：**未写**（mtime 仍为 `2026-11-09 11:14:04`，早于本轮 12:04 改动；autoload 段一字未动，未注册 `CombatDataValidator`）。
- `godot/scenes/courtyard.tscn`、`quality_settings.*`、`hud.gd`、`hd2d_fx.*`：均**未碰**（其它 Rank 独占）。
- 3 份运行权威 `.tres`：`boss_01_margit.tres` / `player_actions.tres` / `enemy_01_limgrave_soldier.tres`：本轮**未改**（只读取断言）。

---

## ② 真跑输出结论（不伪造，逐字见 `R21-verify-run.log`）

### 2.1 引擎与门禁

```
Godot : D:/Godot/Godot_v4.7.2-stable_win64_console.exe（4.7.2.stable.official.ed1daf0bf，
        与派单所指 D:/Godot/Godot_v4.7.2-stable_win64.exe 同版本；console 版用于捕获 stdout，
        沿用 R20 既定口径，见 DONE-R20.md §2.1）
ROOT  : F:/Game/aierdengfahuan/godot
G1    : --headless --path <root> --import
G2    : --headless --path <root> --check-only --script res://scripts/verify_frame_data.gd
G3    : --headless --path <root> --quit
G4    : --headless --path <root> --script res://scripts/verify_frame_data.gd   （主真跑）
```

四段 EXIT：`G1_IMPORT_EXIT=0` / `G2_CHECKONLY_EXIT=0` / `G3_QUIT_EXIT=0` / `G4_RUN_EXIT=0`。
（过程中 G2 曾因 `preload` 常量被推断为类类型而无 `resource_path` 成员报 `Parse Error`，已修正打印行后复跑通过；该中间态如实登记，未伪造。）

### 2.2 SUMMARY（主真跑 G4，逐字）

```
==== [R21 VALIDATOR-CLASS VERIFY] SUMMARY ====
  组A 文档/帧数据核对 | DOC_PASS=111 DOC_FAIL=0 -> DOC_CONSISTENCY=PASS
  组B R19 裁决值 | VERDICT_PASS=6 VERDICT_FAIL=0 -> MATCH
  组C CombatDataValidator.validate_all()（类级真实实例化） | VALIDATOR_CHECKS=533 VALIDATOR_PASS=533 VALIDATOR_FAIL=0 -> VALIDATOR_ERROR=0
  合计 | PASS_COUNT=650 FAIL_COUNT=0
  E-8 max_resistance (bleed/poison/frost) = 400.0 / 480.0 / 420.0
  RESULT=ALL_MATCH
==== [R21 VALIDATOR-CLASS VERIFY] END ====
```

类被真实实例化并执行的 stdout 证据（逐字）：

```
[CombatDataValidator] validate_all() | checks=533 pass=533 fail=0 errors=0 | E-8 max_resistance(bleed/poison/frost)=400.0 / 480.0 / 420.0
[C][类实例] preload=res://scripts/combat/combat_data_validator.gd | 实例有效=true | validate_all() -> checks=533 pass=533 fail=0 errors=0 status=OK
```

### 2.3 PASS / FAIL 结论

| 组 | 项数 | 结果 |
|---|---|---|
| 组A（Boss 三招 24 + 玩家 8 帧动作 72 + 翻滚 E-7/自洽 11 + E-6 4 = 111） | 111 | `DOC_PASS=111 DOC_FAIL=0 -> DOC_CONSISTENCY=PASS` |
| 组B（R19 裁决值 6 项） | 6 | `VERDICT_PASS=6 VERDICT_FAIL=0 -> MATCH` |
| 组C（`CombatDataValidator.validate_all()`：§9 495 + 帧数据专项断言 38） | 533 | `VALIDATOR_CHECKS=533 VALIDATOR_PASS=533 VALIDATOR_FAIL=0 -> VALIDATOR_ERROR=0` |
| **合计** | **650** | **`PASS_COUNT=650 FAIL_COUNT=0`、`RESULT=ALL_MATCH`** |

- **`VALIDATOR_ERROR=0`**、**`RESULT=ALL_MATCH`**、**`SCRIPT ERROR=0`** 三项均真跑达成。
- **任务③ 全部数值由类实际断言且全 PASS**：
  - `player_actions.tres` 的 `4/9/9=22 帧@60`、无敌 `[4,13)`（14 项）；
  - Boss 三招 `p1_dagger_slash` / `p1_staff_slam` / `p2_holy_hammer` 的 `47 / 71 / 91` 与 hit 区间 `[18,23)` / `[30,37)` / `[42,51)`（24 项）；
  - `E-8 max_resistance` `400 / 480 / 420`（§9 E-8 内逐项断言，并由类返回 `e8_max_resistance` 字符串）。
- 类内部逐项断言静默计数（避免 §9 E-9 的 456 个字段实例逐行刷屏），以 `validate_all()` 返回的 `checks/pass/fail/errors` 核验；帧数据实际值另由 `[ACTUAL]` 行与 `SUMMARY` 的 `E-8` 行打印，二者同源。`errors` 为空、`fail=0`。

### 2.4 三段门禁 grep（对 `R21-verify-run.log` 全文，全部 0）

```
SCRIPT ERROR      匹配数: 0
Parse Error       匹配数: 0
ERROR:            匹配数: 0
[FAIL]            匹配数: 0
FAIL_COUNT=[1-9]  匹配数: 0
```

主真跑 `quit(0)`；PASS/FAIL 由「实际值 vs 期望值」逐项真实计算，未预设结论、未伪造输出。

### 2.5 既有 WARNING（非 ERROR、非本轮问题，如实登记）

- G3 / G4 各 1 条 `2 ObjectDB instances were leaked at exit`；
- G4 另有 1 条 `[ChunkManager] 未找到 ChunkRoot`（`res://scripts/world/chunk_streaming.gd:51`）。

与 R16 / R18 / R19 / R20 历史日志同类告警，EXIT 仍为 0，未处理、未越界修改。

---

## ③ PASS 数字变化说明（可增不可减，若变化说明原因）

| 组 | R20 | R21 | 变化 | 原因 |
|---|---|---|---|---|
| 组A | 111 | **111** | 0 | 逐字保留，未回退 |
| 组B | 6 | **6** | 0 | 逐字保留，未回退 |
| 组C | 495（§9 等价同跑） | **533**（类级实例化） | **+38** | 类内新增帧数据专项断言：PLAYER 14 + BOSS 三招 24；§9 的 495 项逐字复刻、不回退 |
| **合计** | **612** | **650** | **+38** | `650 > 612`，可增不可减；`612 PASS` 口径不回退 |

`+38` 分解：PLAYER `4/9/9=22@60 / 无敌[4,13)` 14 项（1 存在 + 11 逐项 + 2 汇总）＋ Boss 三招 pose key 的 `47/71/91` 与 hit 区间 24 项（3 × 8）。组A / 组B 的 `111 / 6` 一字未改；组C 由「等价同跑」升级为「真实类实例化」，495 项基数不回退、额外增加 38 项类级专项断言，故总数只增不减。

---

## ④ 未完成项与阻塞

- **阻塞：无**。本轮任务 4 项（① 新写真实类；② 改 `verify_frame_data.gd` 类级实例化替换等价同跑、组A/组B 与 612 口径不回退；③ 真跑 `VALIDATOR_ERROR=0` / `RESULT=ALL_MATCH` / `SCRIPT ERROR=0` 且类实际断言全部点名数值；④ `VALIDATOR-CLASS-R21.md` 登记）全部完成。
- **待后续（非本轮、不擅自执行，沿用派单口径）**：
  - `CombatDataValidator` 的 **autoload 注册 / Main.tscn 挂载**：本轮 `project.godot` 冻结、无人可写，按要求**未注册**；类不依赖 autoload，由 `verify_frame_data.gd` 实例化即可真跑。是否注册待总指挥在工程冻结后裁决。
  - **R21B 重导双产物**：派单注明「重导双产物另以 R21B 补单在工程冻结后执行」，本轮不涉及。
- **口径说明（如实登记，非失败）**：组C 内部逐项断言静默计数，stdout 不逐行打印 §9 明细（避免 456 行刷屏），以 `validate_all()` 返回的 `checks/pass/fail/errors` 核验；R20 组C 的逐行打印口径在 stdout 信息量上不再逐项呈现，但 PASS 项数（495 基数）与结论不回退，帧数据实际值由组A `[ACTUAL]` 行打印。
- **既有历史 stdout 不改写**：R16 / R18 / R19 / R20 的历史输出、回执与 `*.log` 原始日志按「不伪造输出」原则原样保留；本轮只新增 `R21-verify-run.log`。
- **既有 WARNING**（ObjectDB leaked / ChunkManager）非 ERROR、非本轮问题，如实登记、未处理、未越界修改。
- **未改**：Boss 数值、`project.godot`、`courtyard.tscn` / `quality_settings`（Rank-1 独占）、`hud.gd`（Rank-3 独占）、`hd2d_fx.*`（Rank-4 独占）、其它工位文件；未自行 git commit / push。
- **并发状态**：本实例独立派单会话；写回执前只读确认 `command_center/ai/2/outbox/` 为空、`dispatcher/receipts/` 无本轮回执，故仅写本轮回执 1 份，未重复写第二份；未写到工程根 `F:/Game/aierdengfahuan/command_center/`。

---

## ⑤ 回执

写入 **精确路径** `F:/Game/aierdengfahuan/teamwork/command_center/ai/2/outbox/cmd-20261109-115818-641-A2.json`（注意在 `teamwork/command_center/` 下，非工程根 `command_center/`）：

**送达态（写后只读核验，12:11）**：回执写入上述精确路径后已被调度中枢即时消费并归档为 `teamwork/command_center/dispatcher/receipts/cmd-20261109-115818-641-A2.json`（967 B，JSON 解析通过：`task_id=cmd-20261109-115818-641-A2` / `ai=2` / `status=done`，`result` 引用 DONE-R21.md 实际结论）；`teamwork/command_center/ai/2/status.json` 现为 `state=idle` / `current_task=""` / `completed=23`（R20 为 22 → +1）；工程根 `F:/Game/aierdengfahuan/command_center/` 不存在（未误写）。故 outbox 现为空是「回执已送达中枢」的正常终态，非「回执未写 / 写错路径」。按并发保护「不重复写第二份回执」，本实例不再重写 outbox。

> **并发注记**：定点只读核验时 `godot/scripts/quality_settings.gd`(12:05) / `godot/scripts/hud.gd`(12:06) 的 mtime 晚于本轮新类文件(12:04)，系本轮其它 Rank 并发实例写入（Rank-1 / Rank-3 独占件，本轮多实例并行），**本实例未写这两个文件**，仅对其做只读 `stat` 核验；`project.godot`(11:14) / `courtyard.tscn`(11:17) / `hd2d_fx.gd`(11:12) 均早于本轮改动、未被触动。

```json
{"task_id":"cmd-20261109-115818-641-A2","ai":2,"status":"done","result":"引用 DONE-R21.md 实际结论：R21 已新写 CombatDataValidator 类（godot/scripts/combat/combat_data_validator.gd，class_name CombatDataValidator，extends RefCounted，validate_all()->Dictionary 返回 checks/pass/fail/errors），verify_frame_data.gd 组C 改为 preload+new 真实实例化调用、替换 R20 的 §9 等价同跑；真跑四段门禁 EXIT 全 0，RESULT=ALL_MATCH，VALIDATOR_ERROR=0，SCRIPT ERROR=0，组A=111/组B=6 不回退，组C=533（含 38 项新增类级专项断言），合计 PASS_COUNT=650 FAIL_COUNT=0，E-8 max_resistance=400/480/420，player 4/9/9=22@60 无敌[4,13)、Boss 三招 47/71/91 与 hit 区间均由类实际断言且全 PASS；未注册 autoload（本轮 project.godot 冻结），未碰 project.godot/courtyard.tscn/quality_settings/hud.gd/hd2d_fx；未完成项：无阻塞，autoload 注册与 R21B 重导双产物待后续补单。"}
```
