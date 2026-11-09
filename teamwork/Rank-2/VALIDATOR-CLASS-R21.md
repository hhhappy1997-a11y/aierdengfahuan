# VALIDATOR-CLASS-R21.md —— CombatDataValidator 类落位与类级实例化真跑登记

> **任务单**：`cmd-20261109-115818-641-A2`（`[ROUND=R21]`），Rank-2。
> **定位**：R20 如实登记「`CombatDataValidator` 类自 R2 起未落位工程根、组C 495 项只是 §9 等价校验同跑」。本轮补上真实类、把组C 改为类级实例化真跑。
> **真跑原始 stdout 全文**：`teamwork/Rank-2/R21-verify-run.log`（四段门禁 G1~G4 合并留档，190+ 行）；本文件摘录关键片段，逐字一致。

---

## ① 类路径

| 项 | 值 |
|---|---|
| 工程根绝对路径 | `F:/Game/aierdengfahuan/godot/scripts/combat/combat_data_validator.gd` |
| `res://` 路径 | `res://scripts/combat/combat_data_validator.gd` |
| `class_name` | `CombatDataValidator` |
| `extends` | `RefCounted` |
| autoload | **未注册**（本轮 `project.godot` 冻结，无人可写）。类不依赖场景树 / `_ready()` / autoload 挂载，由调用方 `preload(...).new()` 实例化并主动调用 |
| 引擎 `--import` 副作用 | `combat_data_validator.gd.uid`（19 B）由 `--import` 自动生成，属引擎元数据、非脚本、非手动新建探针/巡检脚本；`project.godot` 未被本轮写入（mtime 仍为 `2026-11-09 11:14:04`，早于本轮 12:04 改动） |

## ② 接口签名

```gdscript
class_name CombatDataValidator
extends RefCounted

# §9 校验式 + 帧数据专项断言的统一入口；自加载 3 份运行权威 .tres，真实计算，不预设结论。
func validate_all() -> Dictionary
```

返回 `Dictionary`（键 / 类型 / 含义）：

| 键 | 类型 | 含义 |
|---|---|---|
| `checks` | `int` | 总检查项数（= `pass` + `fail`） |
| `pass` | `int` | 通过项数 |
| `fail` | `int` | 失败项数 |
| `errors` | `Array[String]` | 失败项标签明细（`fail>0` 时非空，本轮为空） |
| `e8_max_resistance` | `String` | `E-8 max_resistance` 实际值，如 `"400.0 / 480.0 / 420.0"` |
| `status` | `String` | `"OK"` / `"LOAD_FAILED"` |

实例化调用范式（`verify_frame_data.gd` 组C 的真实写法）：

```gdscript
const VALIDATOR_SCRIPT = preload("res://scripts/combat/combat_data_validator.gd")
var validator = VALIDATOR_SCRIPT.new()
var result: Dictionary = validator.validate_all()
```

> **口径**：类内部逐项断言采用静默计数（避免 §9 E-9 的 456 个字段实例逐行刷屏），结果以 `validate_all()` 返回的 `checks/pass/fail/errors` 核验；帧数据实际值另由 `verify_frame_data.gd` 的 `[ACTUAL]` 行与 `SUMMARY` 的 `E-8` 行打印，二者同源。

## ③ 断言覆盖范围（任务③）

`validate_all()` 实际执行并断言：

1. **§9 校验式（E-1 / E-3 / E-4 / E-5 / E-8 / E-9）= 495 项**：与 R20 组C 等价校验逐字同口径（`数据表schema.md` §9，E-8 抗性溢出样本次数 = 8），采集集合 / 字段白名单逐字复刻，故项数不回退。
2. **`player_actions.tres` 的 `4/9/9=22 帧@60`、无敌 `[4,13)` = 14 项**：`action_04_roll` 存在、`startup=4/active=9/recovery=9/total=22/logic_fps=60`、`inv_start=4/inv_end=13`、E-7 四个派生式、8 条动作齐全且 `logic_fps` 全 60。
3. **Boss 三招 `47/71/91` 与 hit 区间 = 24 项**：按 pose key `p1_dagger_slash` / `p1_staff_slam` / `p2_holy_hammer` 各 8 项（存在 / `move_id` / 前摇 / 判定 / 后摇 / `total` / `hit_start` / `hit_end`）——`18/5/24=47, hit=[18,23)`；`30/7/34=71, hit=[30,37)`；`42/9/40=91, hit=[42,51)`。
4. **E-8 `max_resistance` `400 / 480 / 420`**：在 §9 E-8 内按 `E8_MAX_RESISTANCE` 逐项断言，并由类返回 `e8_max_resistance` 字符串供 `SUMMARY` 打印。

合计 `495 + 38 = 533` 项（组C）。

## ④ 可复跑命令

```bash
# 引擎：D:/Godot/Godot_v4.7.2-stable_win64.exe（派单指定）与
#       D:/Godot/Godot_v4.7.2-stable_win64_console.exe 同版本 4.7.2.stable.official.ed1daf0bf；
#       console 版用于 --headless 捕获 stdout（沿用 R20 既定口径，见 DONE-R20.md §2.1）。
ENG=/d/Godot/Godot_v4.7.2-stable_win64_console.exe
ROOT=F:/Game/aierdengfahuan/godot

# G1 导入（扫描新类、生成 .uid / 全局类名缓存）
$ENG --headless --path "$ROOT" --import
# G2 静态检查（解析 verify_frame_data.gd 及其 preload 的类）
$ENG --headless --path "$ROOT" --check-only --script res://scripts/verify_frame_data.gd
# G3 加载工程后退出
$ENG --headless --path "$ROOT" --quit
# G4 主真跑（组A / 组B / 组C 类级实例化 + SUMMARY）
$ENG --headless --path "$ROOT" --script res://scripts/verify_frame_data.gd
```

> 把 `ENG` 换成 `D:/Godot/Godot_v4.7.2-stable_win64.exe` 即为派单指定引擎的同一套门禁；Windows GUI 版 stdout 不便于管道捕获，grep 口径以 console 版留档 `R21-verify-run.log` 为准。

## ⑤ 真跑 stdout（关键片段，逐字）

### 5.1 四段门禁 EXIT

```
G1_IMPORT_EXIT=0
G2_CHECKONLY_EXIT=0
G3_QUIT_EXIT=0
G4_RUN_EXIT=0
```

### 5.2 加载与实际值快照（节选）

```
==== [R21 VALIDATOR-CLASS VERIFY] START ====
---- [0] 加载 3 份运行权威 .tres ----
[0] BOSS   load() OK | path=res://data/combat/boss_01_margit.tres | phases=2
[0] PLAYER load() OK | path=res://data/combat/player_actions.tres | actions=8
[0] ENEMY  load() OK | path=res://data/combat/enemy_01_limgrave_soldier.tres | id=enemy_01_limgrave_soldier
[ACTUAL][BOSS] pose=p1_dagger_slash | move_id=move_01_dagger_slash | startup=18 active=5 recovery=24 | total(derived)=47 | hit=[18,23)
[ACTUAL][BOSS] pose=p1_staff_slam | move_id=move_02_staff_slam | startup=30 active=7 recovery=34 | total(derived)=71 | hit=[30,37)
[ACTUAL][BOSS] pose=p2_holy_hammer | move_id=move_03_holy_hammer | startup=42 active=9 recovery=40 | total(derived)=91 | hit=[42,51)
[ACTUAL][PLAYER] id=action_04_roll | startup=4 active=9 recovery=9 | inv=[4,13) | logic_fps=60 | total(derived)=22 | hit=[4,13)
[ACTUAL][ENGINE] physics_ticks_per_second=60
```

### 5.3 组C 类级实例化（R21 核心，逐字）

```
---- [5] 组C 真实实例化 CombatDataValidator 类并调用 validate_all()（R21 落位）----
[CombatDataValidator] validate_all() | checks=533 pass=533 fail=0 errors=0 | E-8 max_resistance(bleed/poison/frost)=400.0 / 480.0 / 420.0
[C][类实例] preload=res://scripts/combat/combat_data_validator.gd | 实例有效=true | validate_all() -> checks=533 pass=533 fail=0 errors=0 status=OK
[C][声明] 组C 由 preload(res://scripts/combat/combat_data_validator.gd).new() 真实实例化 CombatDataValidator 并调用 validate_all() 取得，已替换 R20 的 §9 等价校验同跑；组A/组B 与 612 PASS 口径未回退。
```

### 5.4 SUMMARY（主真跑 G4，逐字）

```
==== [R21 VALIDATOR-CLASS VERIFY] SUMMARY ====
  组A 文档/帧数据核对 | DOC_PASS=111 DOC_FAIL=0 -> DOC_CONSISTENCY=PASS
  组B R19 裁决值 | VERDICT_PASS=6 VERDICT_FAIL=0 -> MATCH
  组C CombatDataValidator.validate_all()（类级真实实例化） | VALIDATOR_CHECKS=533 VALIDATOR_PASS=533 VALIDATOR_FAIL=0 -> VALIDATOR_ERROR=0
  合计 | PASS_COUNT=650 FAIL_COUNT=0
  E-8 max_resistance (bleed/poison/frost) = 400.0 / 480.0 / 420.0
  RESULT=ALL_MATCH
  NOTE: quit(0)=脚本执行/读取成功；PASS/FAIL 由实际值 vs 期望值真实计算，不预设结论；不写 courtyard.tscn / project.godot / 其它 Rank 独占件；组A/组B 不回退。
==== [R21 VALIDATOR-CLASS VERIFY] END ====
```

### 5.5 三段门禁 grep（对 `R21-verify-run.log` 全文，计数全 0）

```
SCRIPT ERROR      匹配数: 0
Parse Error       匹配数: 0
ERROR:            匹配数: 0
[FAIL]            匹配数: 0
FAIL_COUNT=[1-9]  匹配数: 0
```

`VALIDATOR_ERROR=0`（日志第 181 行）、`RESULT=ALL_MATCH`（第 184 行）均由 G4 真实打印。

### 5.6 既有 WARNING（非 ERROR、非本轮问题，如实登记）

```
WARNING: 2 ObjectDB instances were leaked at exit          (G3 / G4 各 1 条)
WARNING: [ChunkManager] 未找到 ChunkRoot                   (G4，res://scripts/world/chunk_streaming.gd:51)
```

与 R16 / R18 / R19 / R20 历史日志同类告警，EXIT 仍为 0，未处理、未越界修改。

## ⑥ PASS 数字变化说明（可增不可减，如实登记）

| 组 | R20 | R21 | 变化 | 原因 |
|---|---|---|---|---|
| 组A（文档/帧数据） | 111 | **111** | 0 | 逐字保留，未回退 |
| 组B（R19 裁决值） | 6 | **6** | 0 | 逐字保留，未回退 |
| 组C（校验） | 495（§9 等价同跑） | **533**（类级实例化） | **+38** | 类内新增帧数据专项断言：PLAYER 14 + BOSS 三招 24；§9 的 495 项逐字复刻、不回退 |
| **合计** | **612** | **650** | **+38** | `650 > 612`，可增不可减；`612 PASS` 口径不回退 |

`+38` 分解：PLAYER `4/9/9=22@60 / 无敌[4,13)` 14 项（1 存在 + 11 逐项 + 2 汇总）＋ Boss 三招 pose key 的 `47/71/91` 与 hit 区间 24 项（3 × 8）。组A / 组B 的 `111 / 6` 一字未改，故「612 PASS 口径不回退」成立。

---

**结论**：`CombatDataValidator` 类已真实落位工程根，`verify_frame_data.gd` 组C 已由「§9 等价同跑」替换为「`preload + new` 类级实例化调用」，四段门禁 EXIT 全 0，`VALIDATOR_ERROR=0` / `RESULT=ALL_MATCH` / `SCRIPT ERROR=0` 全部真跑达成；任务③点名的全部数值均由类实际断言且全 PASS。
