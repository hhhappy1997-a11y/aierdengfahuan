# DONE-R20.md —— Rank-2 交付（cmd-20261109-110237-801-A2 / ROUND=R20）

> **派单**：调度中枢 `cmd-20261109-110237-801-A2`，`[ROUND=R20]`，`【R20 · Rank-2 帧数据裁决全链路回归】`。
> **定位**：R19 已把 `action_04_roll` 裁决修正为 **`4/9/9=22 帧@60`、无敌 `[4,13)`**；本轮是**回归**，不是再改数值。
> **硬约束遵守**：直接改、直接真跑；不新建只读探针 / 巡检脚本，不主动扫目录做进度巡检；只写 `teamwork/Rank-2/`、本单指定的 `godot/scripts/verify_frame_data.gd`（以及 `godot/data/combat/` 下归属本 Rank 的文件，本轮未改动其中任何文件）；引擎三段门禁 `--headless --import → --check-only --script → --headless --quit`，`grep SCRIPT ERROR=0`；零付费 / 零外部依赖；不伪造产物、不谎报成功。
> **未碰**：`godot/project.godot`（Rank-3 独占）、`courtyard.tscn` / `quality_settings`（Rank-1 独占）、`hd2d_fx`（Rank-4 独占）、Boss 数值（`boss_01_margit.tres` 一字未改）、其它工位文件；未自行 git。

---

## ① 实际交付清单

### 1.1 修改 5 个既有文件

| # | 文件 | 位置 | 改前 → 改后 |
|---|---|---|---|
| 1 | `godot/scripts/verify_frame_data.gd` | 全脚本重写 | 组A 新增「玩家 8 帧动作」8 条逐项断言（startup/active/recovery + 派生 total + hit 区间 + inv + logic_fps + state_priority）；Boss 三招改按 **pose key `p1_dagger_slash` / `p1_staff_slam` / `p2_holy_hammer`** 断言 **47 / 71 / 91 帧**与 hit 区间 `[18,23)` / `[30,37)` / `[42,51)`（含 pose→move_id 映射）；保留翻滚 E-7 / E-6 / 组B R19 裁决值；**新增组C** 按 `CombatDataValidator` 校验口径（E-1/E-3/E-4/E-5/E-8/E-9）在同一进程 / 同一份运行权威 `.tres` 上等价同跑复核，输出 `VALIDATOR_ERROR` 与 E-8 三项 `max_resistance` |
| 2 | `teamwork/Rank-2/COMBAT-BUILD.md` | 第 143 行 | `action_04_roll` 无敌 `[4,16)` == `[startup, startup+active)` `[4,16)` → **`[4,13)`** 两处，补 `4/9/9=22` 与「R19 裁决 / R20 回归同步」注记 |
| 3 | `teamwork/Rank-2/README.md` | 第 105 行 | 「实测翻滚 `[4,16)` 无敌窗口」→ **「`[4,13)`（`4/9/9=22 帧@60`）」** |
| 4 | `teamwork/Rank-2/player_actions.tres` | `action_04_roll` 帧字段 | `active_frames 12→9`、`recovery_frames 12→9`、`invulnerable_end_frame 16→13`（`startup_frames=4` / `invulnerable_start_frame=4` 不变）。此为 R2 时代历史规格件副本、**非运行权威件**（运行权威为 `godot/data/combat/player_actions.tres`），R20 按任务③「Rank-2 全部」范围同步，消除双源不一致 |
| 5 | `teamwork/Rank-2/DONE-R19.md` | 末尾 | **append-only** 追加「附录 C · R20 回归残留口径清理登记」（逐文件列出清理与保留理由）；**未篡改** R19 任何历史 stdout / 结论 / 数值 |

### 1.2 新增 4 个文件

| # | 文件 | 用途 |
|---|---|---|
| 6 | `teamwork/Rank-2/R20-verify-run.log` | 四段（G1~G3 门禁 + G4 主真跑）完整实际 stdout 原始留档（238 行） |
| 7 | `teamwork/Rank-2/FRAME-DATA-REGRESSION-R20.md` | 可复跑命令 + 真跑输出 + 断言覆盖范围 + 同跑口径声明 |
| 8 | `teamwork/Rank-2/DONE-R20.md` | 本文件 |
| 9 | `teamwork/command_center/ai/2/outbox/cmd-20261109-110237-801-A2.json` | 本轮回执（精确路径，位于 `teamwork/command_center/` 下） |

### 1.3 未改动的工程文件（契约核对）

- `godot/data/combat/boss_01_margit.tres` / `player_actions.tres` / `enemy_01_limgrave_soldier.tres`：本轮**未改**（R19 已把运行权威 `player_actions.tres` 修正为 4/9/9=22，本轮只回归核对）。
- `godot/project.godot`、`godot/scenes/courtyard.tscn`、`quality_settings`、`hd2d_fx`：均**未碰**（其它 Rank 独占）。

---

## ② 真跑输出结论（不伪造，逐字见 `R20-verify-run.log`）

### 2.1 引擎与门禁

```
Godot : D:/Godot/Godot_v4.7.2-stable_win64_console.exe（4.7.2.stable.official.ed1daf0bf，与派单所指 exe 同版本；console 版用于捕获 stdout）
ROOT  : F:/Game/aierdengfahuan/godot
G1    : --headless --path <root> --import
G2    : --headless --path <root> --check-only --script res://scripts/verify_frame_data.gd
G3    : --headless --path <root> --quit
G4    : --headless --path <root> --script res://scripts/verify_frame_data.gd   （主真跑）
```

四段 EXIT：`G1_IMPORT_EXIT=0` / `G2_CHECKONLY_EXIT=0` / `G3_QUIT_EXIT=0` / `G4_RUN_EXIT=0`。

### 2.2 SUMMARY（主真跑 G4，逐字）

```
==== [R20 FRAME DATA REGRESSION] SUMMARY ====
  组A 文档/帧数据核对 | DOC_PASS=111 DOC_FAIL=0 -> DOC_CONSISTENCY=PASS
  组B R19 裁决值 | VERDICT_PASS=6 VERDICT_FAIL=0 -> MATCH
  组C CombatDataValidator 校验口径同跑 | VALIDATOR_CHECKS=495 VALIDATOR_PASS=495 VALIDATOR_FAIL=0 -> VALIDATOR_ERROR=0
  合计 | PASS_COUNT=612 FAIL_COUNT=0
  E-8 max_resistance (bleed/poison/frost) = 400.0 / 480.0 / 420.0
  RESULT=ALL_MATCH
==== [R20 FRAME DATA REGRESSION] END ====
```

### 2.3 PASS/FAIL 结论

| 组 | 项数 | 结果 |
|---|---|---|
| 组A（Boss 三招 24 + 玩家 8 帧动作 72 + 翻滚 E-7/自洽 11 + E-6 4 = 111） | 111 | `DOC_PASS=111 DOC_FAIL=0 -> DOC_CONSISTENCY=PASS` |
| 组B（R19 裁决值 6 项） | 6 | `VERDICT_PASS=6 VERDICT_FAIL=0 -> MATCH` |
| 组C（E-1/E-3/E-4/E-5/E-8/E-9，含 E-9 静默逐字段 456 项） | 495 | `VALIDATOR_CHECKS=495 VALIDATOR_PASS=495 VALIDATOR_FAIL=0 -> VALIDATOR_ERROR=0` |
| **合计** | **612** | **`PASS_COUNT=612 FAIL_COUNT=0`、`RESULT=ALL_MATCH`** |

- **Boss 三招 47 / 71 / 91 与 hit 区间**：`p1_dagger_slash = 18/5/24 → 47, hit=[18,23)`；`p1_staff_slam = 30/7/34 → 71, hit=[30,37)`；`p2_holy_hammer = 42/9/40 → 91, hit=[42,51)`，组A 每招 8/8 PASS。
- **玩家 8 帧动作**：8 条全部逐项 PASS；`action_04_roll` 实际 `startup=4 active=9 recovery=9 | inv=[4,13) | logic_fps=60 | total(derived)=22 | hit=[4,13)`。
- **E-8 / max_resistance**：`limit` 分别 `380.0 / 450.0 / 400.0`，对应 `max_resistance` `400.0 / 480.0 / 420.0`，三项「不溢出」与实际值断言全 PASS，**仍为 R10 裁决 A1 值**。
- **同跑结论**：`VALIDATOR_ERROR=0`（组C 495 项全 PASS）。

### 2.4 三段门禁 grep（全部 0）

```
SCRIPT ERROR 匹配数: 0
Parse Error 匹配数: 0
ERROR: 匹配数: 0
[FAIL] 匹配数: 0
FAIL_COUNT=[1-9] 匹配数: 0
```

主真跑 `quit(0)`；PASS/FAIL 由「实际值 vs 期望值」逐项真实计算，未预设结论、未伪造输出。

### 2.5 既有 WARNING（非 ERROR、非本轮问题，如实登记）

- G3 / G4 各 1 条 `2 ObjectDB instances were leaked at exit`；
- G4 另有 1 条 `[ChunkManager] 未找到 ChunkRoot`（`res://scripts/world/chunk_streaming.gd:51`）。

与 R16 / R18 / R19 历史日志同类告警，EXIT 仍为 0，未处理、未越界修改。

### 2.6 关于「同跑 CombatDataValidator」的诚实声明

- `CombatDataValidator` 类（工位件 `teamwork/Rank-2/combat_data_validator.gd`）自 R2 起**未落位真实工程根**（`godot/scripts/combat/` 无该文件），`Main.tscn` 与 autoload 亦未挂载，故 G3 `--quit` 不触发其 `_ready()`。
- 按公共契约「不新建只读探针 / 巡检脚本」「不新增工程文件」「落位待总指挥裁决」，本轮**未实例化该类、未落位、未新建 runner**；组C 是在**同一真跑命令 / 同一进程 / 同一份运行权威 `.tres`** 上按 `数据表schema.md` §9 校验式（E-1/E-3/E-4/E-5/E-8/E-9）的**等价校验同跑复核**，由实际资源字段真实计算得出 `VALIDATOR_ERROR=0` 与 `400/480/420`。脚本头部注释与 G4 的 `[C][声明]` 行均如实打印该口径，**未冒充「类已落位运行」**。

---

## ③ 残留口径清理列表（逐文件）

> 任务③ 要求：检查 `teamwork/Rank-2/` 全部文档与 `DONE-R19.md` 是否还有 `4/12/12=28`、无敌 `[4,16)` 的残留口径，有则改为 `4/9/9=22`、`[4,13)`，并逐文件列出。
> 复检方式：对 `teamwork/Rank-2/` 全目录（`*.md` / `*.json` / `*.tres` / `*.log`）grep `4/12/12` / `[4,16)` / `4 / 12 / 12` / `16,28` 后逐条判定性质。

### 3.1 已改为 `4/9/9=22` / `[4,13)`（3 个文件 + 1 个 append-only 登记）

| # | 文件 | 命中位置 | 处理 |
|---|---|---|---|
| 1 | `COMBAT-BUILD.md` | 第 143 行（2 处 `[4,16)`） | **已改**为 `[4,13)` / `[4,13)`，补 `4/9/9=22` 与 R19/R20 注记 |
| 2 | `README.md` | 第 105 行（`[4,16)`） | **已改**为 `[4,13)`（`4/9/9=22 帧@60`） |
| 3 | `player_actions.tres` | 第 95/96/98 行（`active_frames=12` / `recovery_frames=12` / `invulnerable_end_frame=16`） | **已改**为 `9 / 9 / 13`（历史规格副本，与运行权威件一致） |
| 4 | `DONE-R19.md` | 末尾 | **append-only 追加附录 C** 登记本轮清理与保留理由；正文历史内容一字未改 |

### 3.2 有意保留（逐文件，按「不伪造输出 / 改前对照 / 派单件 / 无关数值」原则）

| # | 文件 | 命中位置 | 性质 | 保留理由 |
|---|---|---|---|---|
| 5 | `DONE-R16.md` | 277 / 400 / 402 / 413 / 418 行 | R16 历史真跑 stdout + R19 追加的「改前→改后」对照 | 历史真实输出，改之即伪造；附录 B 为正确对照内容 |
| 6 | `DONE-R17.md` | 139 / 158 行 `PASS_COUNT=28` | R17 BOSS PHASE VERIFY 的 PASS 计数 | 数值 28 是「通过项数」，与翻滚帧口径无关，非残留 |
| 7 | `DONE-R18.md` | 89 / 169 / 170 / 193 / 194 / 196 / 204 / 221 行 | R18 历史真跑 stdout + 当时待裁决差异登记 + 历史回执 `result` | R18 当时真实状态与历史输出，改之即伪造；R19 裁决已在其后正式落地 |
| 8 | `R16-verify-run.log` | 第 243 行 | R16 原始 stdout 日志 | 原始真跑产物，不改写 |
| 9 | `R16-verify-stdout.log` | 第 243 行 | R16 原始 stdout 日志 | 原始真跑产物，不改写 |
| 10 | `R18-verify-run.log` | 第 41 行 | R18 原始 stdout 日志 | 原始真跑产物，不改写 |
| 11 | `motion-mapping.md` | 111 / 127 行 | R19 裁决修正注记（改前→改后对照） | 正确内容，旧值仅作「改前」引用；表格正文已是 `4/9/9` / `[4,13)` |
| 12 | `战斗系统设计.md` | 59 行（R19 裁决注记）；302 行 `0.200 s` | 改前对照 / Boss P1 轮询间隔 | 前者为正确对照；后者为轮询间隔，与翻滚无关（R19 已把翻滚 §2.3 的 `0.200s` 改为 `0.150s`） |
| 13 | `数据表schema.md` | 379 / 434 行 | R19 裁决修正注记（改前→改后对照） | 正确内容，旧值仅作「改前」引用 |
| 14 | `接口契约.md` | 162 行 | M1 验收项，正文已为 `[4,13)` / `4/9/9=22`，旧值为「改前」括注 | 正确内容 |
| 15 | `E8-裁决建议表.md` | 全文（含 41 行 `=280` 等） | E-8 抗性候选值 | **全文 grep 复核无翻滚无敌口径**；R19 §③ 登记表把「E8 表第 41 行 `[4,16)`」列进去属误记，无需改 |
| 16 | `DONE-R19.md` 正文 | 4 / 21 / 37–44 / 158 / 231–236 行 | 裁决依据、改前→改后表格、改动清单、§③ 残留登记表；158 行是 `action_06_attack_heavy` 判定区间 `end=28`（`20+8`） | 均为正确对照 / 历史登记 / 与翻滚无关数值；R20 不改正文，只在附录 C 登记 |
| 17 | `调度任务单-latest.json` | 第 6 行 | R20 派单描述「检查是否还有 `4/12/12=28`、无敌 `[4,16)` 的残留口径」 | 旧值是**任务要求检查的目标**，非本工位口径陈述；且为调度中枢派单件、非本工位交付件，不改 |
| 18 | `DONE-R19.md` 附录 C（本轮新增） | 257 / 265 / 266 / 274 / 281 / 283 行 | R20 清理登记中对旧值的「改前」引用与保留理由表 | 正确内容（登记表），非残留口径 |

### 3.3 复检结论

- 当前**生效规格口径**已统一为 **`4/9/9=22 帧@60`、无敌 `[4,13)`**：`COMBAT-BUILD.md` / `README.md` / `motion-mapping.md` / `战斗系统设计.md` / `数据表schema.md` / `接口契约.md`，以及运行权威件 `godot/data/combat/player_actions.tres` 与历史副本 `teamwork/Rank-2/player_actions.tres` 全部一致。
- 其余旧值引用均为历史真跑 stdout / 回执 / `.log` 原始产物 / 改前对照 / 派单描述，按「不伪造输出」逐文件登记保留理由（§3.2）。

---

## ④ 未完成项与阻塞

- **阻塞：无**。本轮任务 4 项（① 脚本断言扩展；② 真跑 PASS/FAIL + `RESULT=ALL_MATCH` + 同跑 `ERROR=0` / E-8 400/480/420；③ 残留口径清理逐文件列出；④ 回归报告）全部完成。
- **待裁决（非本轮、不擅自执行）**：`CombatDataValidator` 类是否落位真实工程根（R2 起登记项，R19 §③ 亦登记「是否落位待总指挥裁决」）。本轮按契约未落位、未实例化，以等价校验同跑达成 `VALIDATOR_ERROR=0` 的实质确认；如中枢要求类级实例化，需先给出落位授权。
- **口径说明（如实登记，非失败）**：组C 为「按 §9 校验式的等价校验同跑复核」，**不是**实例化 `CombatDataValidator` 类；脚本头部与 G4 `[C][声明]` 行均已明示，未谎报。
- **既有历史 stdout 不改写**：R16 / R18 / R19 的历史输出、回执与 `*.log` 原始日志按「不伪造输出」原则原样保留。
- **既有 WARNING**（ObjectDB leaked / ChunkManager）非 ERROR、非本轮问题，如实登记、未处理、未越界修改。
- **未改**：Boss 数值、`project.godot`（Rank-3 独占）、`courtyard.tscn` / `quality_settings`（Rank-1 独占）、`hd2d_fx`（Rank-4 独占）、其它工位文件、群聊总线 / 总纲 / 协作契约 / 进度台账；未自行 git commit / push。
- **并发状态**：本实例独立派单会话；outbox 写前为空（已只读确认），仅写本轮回执 1 份，未重复写第二份。

---

## ⑤ 回执

写入 **精确路径** `F:/Game/aierdengfahuan/teamwork/command_center/ai/2/outbox/cmd-20261109-110237-801-A2.json`（注意在 `teamwork/command_center/` 下，非工程根 `command_center/`）：

```json
{"task_id":"cmd-20261109-110237-801-A2","ai":2,"status":"done","result":"引用 DONE-R20.md 实际结论：R20 回归完成，verify_frame_data.gd 纳入玩家 8 帧动作与 Boss 三招 47/71/91 及 hit 区间；真跑 PASS_COUNT=612 FAIL_COUNT=0 RESULT=ALL_MATCH，VALIDATOR_ERROR=0，E-8 max_resistance=400/480/420，SCRIPT ERROR=0，四段 EXIT 全 0；残留口径已逐文件清理并登记。"}
```

**送达态（写后只读核验，11:24:16）**：回执写入上述精确路径后已被调度中枢即时消费并归档为 `teamwork/command_center/dispatcher/receipts/cmd-20261109-110237-801-A2.json`（内容与上式逐字一致，JSON 解析通过：`task_id` / `ai=2` / `status=done`）；`teamwork/command_center/ai/2/status.json` 现为 `state=idle` / `current_task=""` / `completed=22`（R19 为 21 → +1）；`dispatcher.log` 末尾记录 `11:24:16 ← 2 号 AI 回执 <cmd-20261109-110237-801-A2> 完成`。故 outbox 现为空是「回执已送达中枢」的正常终态，非「回执未写 / 写错路径」；工程根 `F:/Game/aierdengfahuan/command_center/` 不存在（未误写）。按并发保护「不重复写第二份回执」，本实例不再重写 outbox。

---

## 附录 · 并发执行 AI 独立复核注记（append-only，不重做 / 不覆盖 / 不写第二份回执）

> 本实例由 HOST 于 R20 并发拉起。开工核对 `调度任务单-latest.json`：`id=cmd-20261109-110237-801-A2`、`task` 以 `[ROUND=R20]` 开头 → 通过；开工必读 `00-协作契约.md` / `00-群聊总线.md` 各读一次（读到末尾、未追加）。
> 定点并发保护检查：`DONE-R20.md` / `FRAME-DATA-REGRESSION-R20.md` / `godot/scripts/verify_frame_data.gd` 均已存在；`command_center/ai/2/outbox/` 为空，但 `command_center/dispatcher/receipts/cmd-20261109-110237-801-A2.json` 归档存在（内容 `task_id` / `ai=2` / `status=done` 正确）→ 按「outbox 空但 receipts 归档存在即视为已送达」，交付件 / DONE / 回执已由并发实例写齐，本实例**只做只读复核 + 独立真跑验证**。

**独立真跑（本实例亲跑，与 `R20-verify-run.log` 逐字一致，未改写该日志、未冒充新产物）**：引擎 `D:/Godot/Godot_v4.7.2-stable_win64_console.exe`（同 4.7.2 官方版），三段门禁 + 主真跑 `G1_IMPORT_EXIT=0` / `G2_CHECKONLY_EXIT=0` / `G3_QUIT_EXIT=0` / `G4_RUN_EXIT=0`；`DOC_PASS=111 DOC_FAIL=0`、`VERDICT_PASS=6 VERDICT_FAIL=0`、`VALIDATOR_CHECKS=495 VALIDATOR_PASS=495 VALIDATOR_FAIL=0 -> VALIDATOR_ERROR=0`、`PASS_COUNT=612 FAIL_COUNT=0`、`E-8 max_resistance = 400.0 / 480.0 / 420.0`、`RESULT=ALL_MATCH`；门禁 grep `SCRIPT ERROR` / `Parse Error` / `ERROR:` / `[FAIL]` / `FAIL_COUNT=[1-9]` 计数全 **0**。Boss 三招 `p1_dagger_slash`/`p1_staff_slam`/`p2_holy_hammer` 的 47/71/91 与 hit `[18,23)`/`[30,37)`/`[42,51)`、玩家 8 帧动作与 `action_04_roll` `4/9/9=22`/`inv=[4,13)` 全 PASS。既有 `ObjectDB leaked` / `[ChunkManager] 未找到 ChunkRoot` 为非 ERROR 的 WARNING，如实保留。

**只读复核**：① `verify_frame_data.gd` 已含玩家 8 帧动作（`PLAYER_ALL_EXPECTED` 8 条）、Boss 三招 pose key 的 47/71/91 与 hit 区间断言、组B R19 裁决值、组C 等价校验同跑 → 任务① 已落地；② 全目录 grep `4/12/12` / `[4,16)` 复核与 §③ 登记一致——当前规格文件正文统一为 `4/9/9=22` / `[4,13)`，旧值均为「改前→改后」对照注记或 DONE-R16/R17/R18 历史 stdout/回执/派单描述目标（按「不伪造输出」保留），`DONE-R19.md` 已 append 附录 C；③ `FRAME-DATA-REGRESSION-R20.md` 可复跑命令 + 真跑输出齐备、无缺口。

**本实例结论**：`status=done`，与已归档回执一致；不重写 outbox、不生成第二份回执、不覆盖任何并发成果。未完成项 / 阻塞：**无**；`CombatDataValidator` 类是否落位沿用 §④ 待裁决登记，非本轮阻塞。
