# E8-VERDICT-LOG.md —— 裁决 A1（E-8 数值回改）改动与验证记录

> 轮次：R10 · Rank-2 · 任务单 `cmd-20261109-040336-521-A2`。
> 记录 `00-汇总.md` §4 A1 裁决从「只读核对 → 落盘 → 真跑验证 → 门禁」的全过程。
> 与 `DONE-R10.md` 互补：本文按时间线记录**每一步实际命令与实际输出**；`DONE-R10.md` 是交付结论。
> 中文 UTF-8；所有输出来自本机 Godot 4.7.2 实际 stdout/grep，未伪造、未冒充全绿。

---

## 1. 裁决输入（只读核对）

| 来源 | 关键内容 |
|---|---|
| `teamwork\00-汇总.md` §4 A1 | 「采用方向 A：把 `boss_01_margit.tres` 的 `max_resistance` 提为 **400 / 480 / 420**（留余量），保持 N=8、触发阈值、伤害与削韧不变；不改校验式、不改 schema 文档口径」「数值改动由后续轮次执行」 |
| `Rank-2\E8-裁决建议表.md` §2 | 现状 `330/360/320`；校验阈值 `380/450/400`；方向 A 候选留余量示例 `400/480/420`；三项溢出量 `50/90/80` |
| `Rank-2\BOSS-DATA-FINAL.md` §5.1 / §6.3 / §7 | 三个 `StatusBuildup` 字段真值；E-8 三项 FAIL `380>330` / `450>360` / `400>320`；两份 `.tres` 数值逐字一致、仅 5 条 `ext_resource path` 不同 |
| `Rank-2\combat_data_validator.gd:212-213` | `limit = threshold + gain × resistance_sample_triggers(=8)`；`_ok(limit <= max_resistance, ...)` |
| `teamwork\00-群聊总线.md` | 开工只读一次；确认回执按任务单 id、默认不刺探、零付费、不自行 git |

---

## 2. 步骤 0：改前基线（只读）

```
=== 改前 · 工位稿 max_resistance ===
50:max_resistance = 330.0
67:max_resistance = 360.0
84:max_resistance = 320.0
=== 改前 · 运行件 max_resistance ===
50:max_resistance = 330.0
67:max_resistance = 360.0
84:max_resistance = 320.0
=== 改前 · E-8 三字段上下文（运行件） ===
38:status_type = "bleed"   39:threshold = 180.0   49:resistance_gain_per_trigger = 25.0   50:max_resistance = 330.0
55:status_type = "poison"  56:threshold = 210.0   66:resistance_gain_per_trigger = 30.0   67:max_resistance = 360.0
72:status_type = "frost"   73:threshold = 160.0   83:resistance_gain_per_trigger = 30.0   84:max_resistance = 320.0
=== 改前 · 排除 ext_resource 后 diff ===
DIFF_RC=0
=== 改前 · 全文件 cmp ===
... differ: byte 119, line 3
CMP_RC=1
=== 改前 · 两份 ext_resource 路径差异 ===
1,5c1,5
< ... path="res://data/schemas/*.gd" ...      （工位稿 5 条）
---
> ... path="res://scripts/combat/*.gd" ...     （运行件 5 条）
```

结论：两份数值逐字一致；全文件差异仅为既有 5 条 `ext_resource path`（R6 装配必需、非数值）。

---

## 3. 步骤 1：真跑环境（系统临时最小工程）

`CombatDataValidator` 未落位真实工程根（`godot\scripts\combat\` 无该文件），沿用 `R5-待裁决登记.md` §2.1 口径：

- 临时工程：`C:\Users\62668\AppData\Local\Temp\r10_gate_a2\`（不落 teamwork / 工程根、不提交、收尾删除）
- 复制：`godot\scripts\combat\` 8 个 `class_name` 脚本（boss_data / phase_data / move_data / poise_config /
  status_buildup / enemy_data / player_action_data / player_action_table）+ 工位 `combat_data_validator.gd`
  + `godot\data\combat\` 3 份 `.tres`
- 新建 3 件（临时验证件）：`project.godot`（主场景 `res://main.tscn`）、`main.tscn`、
  `gate\r10_gate_runner.gd`（`CombatDataValidator.new()` 赋值 3 份 `.tres` 后 `add_child()` 触发 `_ready()`），
  `resistance_sample_triggers` 保持默认 8。
- 3 份 `.tres` 的 11 条 `ext_resource` 全部指向已复制的 `res://scripts/combat/*.gd`，无悬空。

```
=== 临时工程已复制文件清单 ===
data/combat/{boss_01_margit, enemy_01_limgrave_soldier, player_actions}.tres
scripts/combat/{boss_data, phase_data, move_data, poise_config, status_buildup, enemy_data,
                player_action_data, player_action_table, combat_data_validator}.gd
=== 复制的 boss .tres 三个 max_resistance（确认改前旧值） ===
50:max_resistance = 330.0   67:max_resistance = 360.0   84:max_resistance = 320.0
```

---

## 4. 步骤 2：改前真跑（复现 3 FAIL / 4 ERROR）

命令：`--version` / `--headless --path <temp> --import` / `--headless --path <temp> --quit`（`2>&1` 合并）。

```
SEG0_RC=0   4.7.2.stable.official.ed1daf0bf
SEG1_RC=0   import_before.log 行数: 29
SEG3_RC=0
=== seg3 完整 stdout/stderr 原文 ===
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_01_bleed
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ok (res://scripts/combat/combat_data_validator.gd:86)
       [1] _validate_e8 (res://scripts/combat/combat_data_validator.gd:213)
       [2] _ready (res://scripts/combat/combat_data_validator.gd:75)
       [3] _ready (res://gate/r10_gate_runner.gd:18)
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_02_poison
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ok (...:86)  [1] _validate_e8 (...:213)  [2] _ready (...:75)  [3] _ready (r10_gate_runner.gd:18)
ERROR: [CombatDataValidator] FAIL E-8 抗性不溢出 -> status_03_frost
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ok (...:86)  [1] _validate_e8 (...:213)  [2] _ready (...:75)  [3] _ready (r10_gate_runner.gd:18)
[CombatDataValidator] E-1/E-3/E-4/E-5/E-8/E-9 检查项 491，错误 3
ERROR: [CombatDataValidator] 数据表自洽校验失败，错误 3 项
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/combat/combat_data_validator.gd:79)
       [1] _ready (res://gate/r10_gate_runner.gd:18)
[R10-GATE] CombatDataValidator._ready() 已触发，挂载 3 份 .tres（boss/enemy/player_actions）
=== 合并日志与 grep 统计 ===
all_before.log 行数: 59
ERROR: 行数: 4
SCRIPT ERROR: 行数: 0
Parse Error: 行数: 0
32:ERROR: ... status_01_bleed
39:ERROR: ... status_02_poison
46:ERROR: ... status_03_frost
54:ERROR: [CombatDataValidator] 数据表自洽校验失败，错误 3 项
53:[CombatDataValidator] E-1/E-3/E-4/E-5/E-8/E-9 检查项 491，错误 3
59:[R10-GATE] CombatDataValidator._ready() 已触发 ...
```

> 与 `R5-待裁决登记.md` §2.4 历史实证逐字一致，证明临时工程验证方法可靠、基线可信。
> 性质：4 条均为 `CombatDataValidator` 的 `push_error()`（数据表自洽校验 FAIL），非 GDScript 解析错误、
> 非运行时 `SCRIPT ERROR`（专项 grep 0 命中）。

---

## 5. 步骤 3：落盘改动（仅 3 个数值 × 2 份副本）

用带上下文的精确替换（`resistance_gain_per_trigger` 行保持不变），共 6 处编辑：

| 顺序 | 文件 | old → new |
|---|---|---|
| 1 | 工位稿 | `gain 25.0 / max_resistance = 330.0` → `gain 25.0 / max_resistance = 400.0` |
| 2 | 运行件 | 同上 |
| 3 | 工位稿 | `gain 30.0 / max_resistance = 360.0` → `gain 30.0 / max_resistance = 480.0` |
| 4 | 运行件 | 同上 |
| 5 | 工位稿 | `gain 30.0 / max_resistance = 320.0` → `gain 30.0 / max_resistance = 420.0` |
| 6 | 运行件 | 同上 |

---

## 6. 步骤 4：改后逐字节核对

```
=== 改后 · 工位稿 / 运行件 三个 max_resistance ===
50:max_resistance = 400.0   67:max_resistance = 480.0   84:max_resistance = 420.0  （两份相同）
=== 改后 · 三数值行两份逐字节比对 ===           VAL_DIFF_RC=0
=== 改后 · 排除 ext_resource 后 diff ===          DIFF_RC=0
=== 改后 · 全文件 cmp ===                        ... differ: byte 119, line 3 ; CMP_RC=1
=== 改前副本(临时工程) vs 改后运行件 diff ===
50c50  < 330.0  --- > 400.0
67c67  < 360.0  --- > 480.0
84c84  < 320.0  --- > 420.0
BEFORE_AFTER_DIFF_RC=1
=== 严禁改动字段复核（threshold / gain / 触发伤害 / 削韧 / 招式施加值） ===
39:threshold = 180.0  42:trigger_damage_ratio = 0.12  43:trigger_damage_flat = 0.0  44:trigger_poise_damage = 25.0  49:gain = 25.0
56:threshold = 210.0  59:trigger_damage_ratio = 0.0   60:trigger_damage_flat = 40.0  61:trigger_poise_damage = 0.0   66:gain = 30.0
73:threshold = 160.0  76:trigger_damage_ratio = 0.08  77:trigger_damage_flat = 0.0  78:trigger_poise_damage = 40.0  83:gain = 30.0
96/120/144:poise_damage = 22.0/45.0/70.0  147:status_buildup_frost = 35.0
=== N=8 / E-8 校验式复核 ===
17:@export var resistance_sample_triggers: int = 8
212:var limit: float = buildup.threshold + buildup.resistance_gain_per_trigger * float(resistance_sample_triggers)
213:_ok(limit <= buildup.max_resistance, "E-8 抗性不溢出 -> %s" % buildup.id)
=== validator 工位件 vs 临时工程副本 cmp ===  VALIDATOR_CMP_RC=0
=== schema §9 E-8 口径原文（文档未写） ===
427:| E-8 | ... `threshold + resistance_gain_per_trigger × 8 <= max_resistance` | 抗性溢出 |
```

- 三数值行两份**逐字节一致**；排除 `ext_resource` 后全字段**逐字一致**；
- 全文件 `cmp` 差异仍为 `byte 119, line 3`（仅既有 5 条 `ext_resource path`），**未扩大、未伪造全文件相同**；
- 改前副本 vs 改后运行件 **恰好 3 行差异** → 严格只有 3 个数值被改。

余量：`380 ≤ 400`（+20）、`450 ≤ 480`（+30）、`400 ≤ 420`（+20），三项 `limit <= max_resistance` 成立。

---

## 7. 步骤 5：改后真跑（4 ERROR 消失）

把改后运行件 `boss_01_margit.tres` 覆盖进临时工程 `data\combat\`，重跑 `--import` + `--quit`：

```
临时工程 boss .tres 三个 max_resistance:
50:max_resistance = 400.0   67:max_resistance = 480.0   84:max_resistance = 420.0
SEG1_RC=0   import_after.log 行数: 16
SEG3_RC=0
=== seg3 完整 stdout/stderr 原文 ===
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[CombatDataValidator] E-1/E-3/E-4/E-5/E-8/E-9 检查项 491，错误 0
[R10-GATE] CombatDataValidator._ready() 已触发，挂载 3 份 .tres（boss/enemy/player_actions）
=== 合并日志与 grep 统计 ===
all_after.log 行数: 20
ERROR: 行数: 0
FAIL 行数: 0
SCRIPT ERROR: 行数: 0
Parse Error: 行数: 0
--- ERROR: / FAIL 原文（预期 0 命中） ---   GREP_ERR_RC=1
--- 检查项汇总 / R10-GATE 标记 --- 19:检查项 491，错误 0 ; 20:[R10-GATE] ...
```

**前后对比**：`4 条 ERROR / 错误 3` → `0 条 ERROR / 错误 0`；491 项全量跑完（非未加载假绿）；脚本层
`SCRIPT ERROR=0` / `Parse Error=0` / EXIT=0 前后一致。

---

## 8. 步骤 6：真实工程根三段门禁（无回归）

工程根 `F:/Game/aierdengfahuan/godot`；命令口径同 `DONE-R9.md` §2.1。

**首轮**：

```
SEG0_RC=0  4.7.2.stable.official.ed1daf0bf
SEG1_RC=0  final_seg1.log 行数: 16
SEG2_SCRIPTS=52 SEG2_FAIL=0
SEG3_RC=0  （seg3 仅 1 条 ObjectDB leaked WARNING）
final_all.log 行数: 127
SCRIPT ERROR: 0  Parse Error: 0  ERROR: 行数: 1  WARNING 行数: 1
hides a global: 0  Failed to load: 0
78:ERROR: Failed to open 'user://logs/godot2026-11-09T04.08.31.log'.
126:WARNING: 2 ObjectDB instances were leaked at exit ...
```

**首轮 1 条 ERROR 归因（如实登记）**：

```
final_seg0/1/3.log: (无)   final_seg2.log:61:ERROR: Failed to open 'user://logs/...log'
79:   at: copy (core/io/dir_access.cpp:429)
project.godot 无 file_logging 配置
复跑 SEG3 单独一次: RECHECK_SEG3_RC=0, RECHECK ERROR 行数: 0
```

→ 52 次连续 `--check-only --script` 启动中引擎写 `user://logs/godot<时间戳>.log` 的**偶发文件日志写入失败**；
非脚本层、非战斗层、与 `.tres` 数值改动无关；不冒充首轮全绿。

**复跑完整三段稳定快照**：

```
RE_SEG1_RC=0
RE_SEG2_SCRIPTS=52 RE_SEG2_FAIL=0
RE_SEG3_RC=0
re_all.log 行数: 124
SCRIPT ERROR: 0  Parse Error: 0  ERROR: 行数: 0  WARNING 行数: 1
hides a global: 0  Failed to load: 0
123:WARNING: 2 ObjectDB instances were leaked at exit ...
```

→ 与 R9 FINAL 基线（`ERROR=0`、52/52、1 条 leaked WARNING）一致，**无回归**。

---

## 9. 步骤 7：交付与回执

| 件 | 路径 | 状态 |
|---|---|---|
| 交付结论 | `teamwork\Rank-2\DONE-R10.md` | 已写 |
| 本记录 | `teamwork\Rank-2\E8-VERDICT-LOG.md` | 已写 |
| 回执 | `teamwork\command_center\ai\2\outbox\cmd-20261109-040336-521-A2.json` | 已写（`status=done`） |
| 临时工程 / 日志 | `C:\Users\62668\AppData\Local\Temp\r10_gate_a2{,_logs}\` | 系统临时目录，收尾删除 |

**回执消费时序（如实登记）**：回执写入 `ai\2\outbox\` 后，调度中枢 dispatcher 持续监听、写入即消费归档，
故 `outbox\` **终态为空**（既有各轮同一现象、非写失败、非未完成）。实际证据：

```
归档件 dispatcher\receipts\cmd-20261109-040336-521-A2.json（权威落点）
  → task_id=cmd-20261109-040336-521-A2 ai=2 status=done result_len=726（result 引用 DONE-R10.md 实际结论）
ledger.jsonl:35  → "id": "cmd-20261109-040336-521-A2", "status": "done",
                    "finished_at": "2026-11-09 04:12:24"
dispatcher.log:193 → [04:11:07] ← 2 号 AI 回执 <cmd-20261109-040336-521-A2> 完成
dispatcher.log:195 → [04:12:24] ← 2 号 AI 回执 <cmd-20261109-040336-521-A2> 完成（第二次幂等写入同样被消费）
ai\2\status.json   → state=idle, completed=11, last_seen=2026-11-09 04:11:07
outbox 终态        → 空目录
```

本轮两次向 outbox 写入内容相同的 `status=done` 回执，均由中枢即时消费；**权威回执落点**为
`dispatcher\receipts\cmd-20261109-040336-521-A2.json`，中枢已记 `done`，状态不变。

---

## 10. 边界与未完成（只登记不擅改）

- 未写 `project.godot`、`godot\scripts\combat\`、其它工位、总线 / 总纲 / 契约 / 台账；未自行 git。
- 未改任何 `.gd`（含校验式与 N=8）、`数据表schema.md` 口径、threshold / gain / 触发伤害 / 削韧 / 招式施加值。
- 其余待裁决项（A4 / A6 文档回改、validator 落位工程根、`schema`/`schemas` 口径、历史 signal、Q1、手感与渲染验收）
  **只登记不擅改**，见 `DONE-R10.md` §3。
- 零付费 / 零外部依赖；默认不刺探；既有件不重做；中文 UTF-8；Godot 4 合法语法。
- **未伪造输出、未冒充全绿**：首轮门禁 1 条偶发 `user://logs` ERROR、1 条既有 leaked WARNING 均如实登记。
