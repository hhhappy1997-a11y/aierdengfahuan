# DONE-R15 · Rank-2 战斗系统与数据驱动

> 命令：`cmd-20261109-083628-782-A2` ｜ `[ROUND=R15]` ｜ AI=2 ｜ 2026-11-09 08:36 派单
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（真跑版本头 `4.7.2.stable.official.ed1daf0bf`）
> 工程根：`F:/Game/aierdengfahuan/godot`
> **结论：pose 名称一致性真跑比对 31 项断言全 PASS（`PASS_COUNT=31` / `FAIL_COUNT=0` / `RESULT=PASS`）；三段门禁 `--import` / `--check-only --script verify_pose_names.gd` / `--quit` 均 `EXIT=0`，`--script` 真跑 `VERIFY_RC=0`。四项任务全部通过，未发现不一致，故未改任何既有资源。**

---

## ① 交付清单

| # | 文件 | 位置 | 说明 |
|---|---|---|---|
| 1 | `verify_pose_names.gd` | `godot/scripts/verify_pose_names.gd` | 新建 `extends SceneTree` 真跑比对脚本：从 `HybridSpriteRig.FROZEN_POSES` / `POSE_PREFIXES` 常量、两个 `.tres`、`boss_import.json` 真读数据；统一转 `String` 后逐项比对，打印 `[PASS]`/`[FAIL]`，末尾输出 `PASS_COUNT`/`FAIL_COUNT`/`RESULT` 并 `quit(0 if _fail_count == 0 else 1)` |
| 2 | `DONE-R15.md` | `teamwork/Rank-2/DONE-R15.md` | 本文件：①交付清单 ②自检含完整实际 stdout ③未完成项与阻塞 |
| 3 | 回执 JSON | `teamwork/command_center/ai/2/outbox/cmd-20261109-083628-782-A2.json` | `{"task_id":"cmd-20261109-083628-782-A2","ai":2,"status":"done","result":"…引用本文件实际结论…"}` |

### 改动范围核对

- **唯一新增的 Godot 工程内文件**：`godot/scripts/verify_pose_names.gd`（授权可写范围）。另写 `Rank-2/DONE-R15.md` 与 `outbox/` 回执。
- **未改动任何既有资源**：`player_spriteframes.tres` / `boss_spriteframes.tres` / `boss_import.json` / `hybrid_2d3d_animated_sprite.gd` 全部只读、保持原样（本单未发现不一致，按「只如实登记、不擅自改既有资源」执行）。
- **未碰** `godot/scenes/courtyard.tscn`（Rank-1 本轮独占）、未改任何战斗数值、未写其它工位、未写群聊总线 / 总纲 / 协作契约、**未自行 git**。
- **回执投递口径（如实登记）**：回执按 `task_id` 写入 `command_center/ai/2/outbox/cmd-20261109-083628-782-A2.json`（本轮实写 1 次）。中枢 `dispatcher` 对 outbox 实时监控，写入即被消费并归档到 `command_center/dispatcher/receipts/cmd-20261109-083628-782-A2.json`。本轮完工自检实测：`outbox/` 已空、`receipts/` 存在该归档副本，`python json.load` 校验合法，`task_id`/`ai`/`status`/`result` 四字段与写入内容一致（`result_len=729`）。故核验时 outbox 为空属「已投递并被消费」的正常终态，而非未写回执，归档副本即为可核对证据；与 R13/R14 及总线既有口径一致，未伪造、未绕过、未重复派单。

---

## ② 自检（真跑实际输出，不以结论代替）

### 复跑命令（一条 Bash 串行执行，4 段）

```bash
GODOT="/d/Godot/Godot_v4.7.2-stable_win64.exe"
ROOT="F:/Game/aierdengfahuan/godot"
"$GODOT" --headless --path "$ROOT" --import
"$GODOT" --headless --path "$ROOT" --check-only --script res://scripts/verify_pose_names.gd
"$GODOT" --headless --path "$ROOT" --quit
"$GODOT" --headless --path "$ROOT" --script res://scripts/verify_pose_names.gd
```

> 三段门禁对应任务书：`--import` / `--check-only --script verify_pose_names.gd`（工程内实际路径 `res://scripts/verify_pose_names.gd`） / `--quit`；末段为 `--script` 真跑以产出逐项 PASS/FAIL 的 stdout（`--check-only` 只静态解析、不执行 `_initialize()`）。

### 实际 stdout（原样粘贴，未删改）

```text
### SEG1 --import ###
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

SEG1_RC=0
### SEG2 --check-only --script ###
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

SEG2_RC=0
### SEG3 --headless --quit ###
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
SEG3_RC=0
### VERIFY --script real-run ###
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

==== [R15 POSE NAMES VERIFY] START ====
[源] HybridSpriteRig.FROZEN_POSES (常量) | count=11 | values=["idle", "walk", "run", "roll", "attack_light", "attack_heavy", "hitstun", "death", "dagger_slash", "staff_slam", "holy_hammer"]
[源] HybridSpriteRig.POSE_PREFIXES (常量) | count=2 | values=["p1_", "p2_"]
[源] player_spriteframes.tres | animation_count=8 | names=["attack_heavy", "attack_light", "death", "hitstun", "idle", "roll", "run", "walk"]
[源] boss_spriteframes.tres | animation_count=3 | names=["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]
[源] boss_import.json | pose_names=["dagger_slash", "staff_slam", "holy_hammer"]
[源] boss_import.json | pose_prefix.values=["p1_", "p2_"]
[源] boss_import.json | phase_hint.keys=["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]
---- 项1: player_spriteframes.tres 8 个动画名 vs HybridSpriteRig.FROZEN_POSES (常量) ----
  [PASS] [1.1] player 动画数 == 8（实际 8）
[1] FROZEN_POSES.count=11 | 基础 8=["idle", "walk", "run", "roll", "attack_light", "attack_heavy", "hitstun", "death"] | Boss 3=["dagger_slash", "staff_slam", "holy_hammer"]
  [PASS] [1.2.1] player 动画名 'attack_heavy' 在 FROZEN_POSES 内（表内接受）
  [PASS] [1.2.2] player 动画名 'attack_light' 在 FROZEN_POSES 内（表内接受）
  [PASS] [1.2.3] player 动画名 'death' 在 FROZEN_POSES 内（表内接受）
  [PASS] [1.2.4] player 动画名 'hitstun' 在 FROZEN_POSES 内（表内接受）
  [PASS] [1.2.5] player 动画名 'idle' 在 FROZEN_POSES 内（表内接受）
  [PASS] [1.2.6] player 动画名 'roll' 在 FROZEN_POSES 内（表内接受）
  [PASS] [1.2.7] player 动画名 'run' 在 FROZEN_POSES 内（表内接受）
  [PASS] [1.2.8] player 动画名 'walk' 在 FROZEN_POSES 内（表内接受）
  [PASS] [1.3] player 8 名集合 == FROZEN_POSES 基础 8 集合（player=["attack_heavy", "attack_light", "death", "hitstun", "idle", "roll", "run", "walk"] / base8=["idle", "walk", "run", "roll", "attack_light", "attack_heavy", "hitstun", "death"]）
  [PASS] [1.4] player 8 名无重复
---- 项2: boss_spriteframes.tres 3 个动画名 vs boss_import.json 的 pose_names + pose_prefix / phase_hint ----
  [PASS] [2.1] boss 动画数 == 3（实际 3）
  [PASS] [2.2] pose_names 数量 == 3（实际 3）
  [PASS] [2.3] phase_hint 键数量 == 3（实际 3）
  [PASS] [2.4] boss 3 动画名集合 == phase_hint 键集合（boss=["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"] / hint=["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]）
[2.5.1] 动画名 'p1_dagger_slash' | 前缀='p1_' | 去前缀='dagger_slash'
  [PASS] [2.5.1] 'p1_dagger_slash' 的前缀属于 pose_prefix 值集合 ["p1_", "p2_"]
  [PASS] [2.5.1] 'p1_dagger_slash' 去前缀后 'dagger_slash' 属于 pose_names ["dagger_slash", "staff_slam", "holy_hammer"]
  [PASS] [2.5.1] 'p1_dagger_slash' 属于 phase_hint 键集合 ["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]
[2.5.2] 动画名 'p1_staff_slam' | 前缀='p1_' | 去前缀='staff_slam'
  [PASS] [2.5.2] 'p1_staff_slam' 的前缀属于 pose_prefix 值集合 ["p1_", "p2_"]
  [PASS] [2.5.2] 'p1_staff_slam' 去前缀后 'staff_slam' 属于 pose_names ["dagger_slash", "staff_slam", "holy_hammer"]
  [PASS] [2.5.2] 'p1_staff_slam' 属于 phase_hint 键集合 ["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]
[2.5.3] 动画名 'p2_holy_hammer' | 前缀='p2_' | 去前缀='holy_hammer'
  [PASS] [2.5.3] 'p2_holy_hammer' 的前缀属于 pose_prefix 值集合 ["p1_", "p2_"]
  [PASS] [2.5.3] 'p2_holy_hammer' 去前缀后 'holy_hammer' 属于 pose_names ["dagger_slash", "staff_slam", "holy_hammer"]
  [PASS] [2.5.3] 'p2_holy_hammer' 属于 phase_hint 键集合 ["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]
  [PASS] [2.6.1] pose_names 'dagger_slash' 亦在 FROZEN_POSES 冻结表内（Boss 3 名口径）
  [PASS] [2.6.2] pose_names 'staff_slam' 亦在 FROZEN_POSES 冻结表内（Boss 3 名口径）
  [PASS] [2.6.3] pose_names 'holy_hammer' 亦在 FROZEN_POSES 冻结表内（Boss 3 名口径）
---- 项3: HybridSpriteRig.POSE_PREFIXES 是否 == ["p1_","p2_"] ----
  [PASS] [3.1] POSE_PREFIXES[0] == 'p1_'（实际 'p1_'）
  [PASS] [3.2] POSE_PREFIXES[1] == 'p2_'（实际 'p2_'）
  [PASS] [3.3] POSE_PREFIXES 整体 == ["p1_", "p2_"]（实际 ["p1_", "p2_"]）
  [PASS] [3.4] (交叉) 常量 POSE_PREFIXES 集合 == boss_import.json pose_prefix 值集合（常量=["p1_", "p2_"] / json=["p1_", "p2_"]）
==== [R15 POSE NAMES VERIFY] PASS_COUNT=31 FAIL_COUNT=0 ====
==== [R15 POSE NAMES VERIFY] RESULT=PASS ====
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
VERIFY_RC=0
```

### 逐项比对结论（依据以上实际读数）

| 任务项 | 实际读数 | 判定 |
|---|---|---|
| ① `player_spriteframes.tres` 8 个动画名 vs `HybridSpriteRig.FROZEN_POSES` | player 8 名 `attack_heavy, attack_light, death, hitstun, idle, roll, run, walk`；`FROZEN_POSES` 常量 count=11；8 名逐一全部 `has()` 命中冻结表（`[1.2.1]`~`[1.2.8]` 全 PASS）；集合恰等于冻结表「基础 8」`idle, walk, run, roll, attack_light, attack_heavy, hitstun, death`（`[1.3]` PASS），8 名无重复（`[1.4]` PASS） | **PASS** |
| ② `boss_spriteframes.tres` 3 个动画名 vs `boss_import.json` 的 `pose_names` + `pose_prefix`/`phase_hint` | boss 3 名 `p1_dagger_slash, p1_staff_slam, p2_holy_hammer` == `phase_hint.keys`（`[2.4]` PASS）；逐个拆前缀 `p1_/p1_/p2_` 全 ∈ `pose_prefix.values=["p1_","p2_"]`、去前缀 `dagger_slash/staff_slam/holy_hammer` 全 ∈ `pose_names`（`[2.5.*]` 9 条全 PASS）；`pose_names` 的 3 名亦在 `FROZEN_POSES` 内（`[2.6.*]` 3 条 PASS） | **PASS** |
| ③ `POSE_PREFIXES` 是否为 `["p1_","p2_"]` | 常量实际 `["p1_", "p2_"]`：逐元素 `[3.1]`/`[3.2]`、整体 `[3.3]` 均 PASS；与 json `pose_prefix` 值集合交叉一致（`[3.4]` PASS） | **PASS** |
| ④ 三段门禁 `--import` / `--check-only --script verify_pose_names.gd` / `--quit` | `SEG1_RC=0`、`SEG2_RC=0`、`SEG3_RC=0`；另 `--script` 真跑 `VERIFY_RC=0` | **PASS** |
| 汇总 | `PASS_COUNT=31` / `FAIL_COUNT=0` / `RESULT=PASS` / `VERIFY_RC=0` | **PASS** |

> **口径如实登记（非不一致）**：`FROZEN_POSES` 常量共 **11** 项，按脚本 `hybrid_2d3d_animated_sprite.gd:24` 注释为「基础 8 + Boss 3」。`player_spriteframes.tres` 对应**基础 8**，Boss 3 招对应 `boss_spriteframes.tres`（由任务项 ② 以 `pose_names`/`phase_hint` 口径覆盖）。故「player 8 名」与「冻结表 11 项」不是集合相等关系，而是「player 8 名 ⊆ 冻结表、且恰等于其基础 8 子集」；本单按此口径逐项验证并全部通过，**未发现任何表外动作名或错配**，因此按约束「只如实登记，不擅自改既有资源」——本轮未改动两个 `.tres`、`boss_import.json` 与 `hybrid_2d3d_animated_sprite.gd`。

### 三段门禁 + 真跑结论（硬性约束要求贴结论）

| 段 | 命令 | EXIT | 结论 |
|---|---|---|---|
| G1 | `--headless --path <root> --import` | `SEG1_RC=0` | `first_scan_filesystem` / `loading_editor_layout` 全 `DONE`，无 `ERROR`；全局类缓存刷新（`HybridSpriteRig` 常量在后续 `--check-only` 可解析） |
| G2 | `--headless --path <root> --check-only --script res://scripts/verify_pose_names.gd` | `SEG2_RC=0` | **只静态解析、不执行**：`verify_pose_names.gd` 为 Godot 4 合法语法；`HybridSpriteRig.FROZEN_POSES` / `POSE_PREFIXES` 常量引用、`SpriteFrames.get_animation_names()`、`JSON.parse_string()`、`FileAccess` 等解析通过；即任务第 4 项第二段门禁覆盖本脚本 |
| G3 | `--headless --path <root> --quit` | `SEG3_RC=0` | 主场景 + autoload 启动后正常退出；仅既有 `ObjectDB leaked` WARNING（非 ERROR） |
| 真跑 | `--headless --path <root> --script res://scripts/verify_pose_names.gd` | `VERIFY_RC=0` | `PASS_COUNT=31`、`FAIL_COUNT=0`、`RESULT=PASS`，`quit(0)` 以 0 退出 |

---

## ③ 未完成项与阻塞

**本单 4 项验证全部真实通过，无待补跑、无待裁决项、无付费 / 外部依赖阻塞。** 以下为如实登记的观察项与范围外事项，不影响本单结论：

1. **运行期 WARNING（既有、非 ERROR、非阻塞）**
   - `--headless --quit` 与 `--script` 真跑均出现 `WARNING: 2 ObjectDB instances were leaked at exit`，与 R9/R10/R13/R14 基线一致（历史 DONE 已登记为 `RefCounted` 残留），非 `SCRIPT ERROR` / `Parse Error` / `ERROR`，不影响 31 项断言与 `EXIT=0`。
   - `--script` 真跑时 autoload `chunk_streaming.gd:51` 另打印 `WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。`，来自工程 autoload 启动链，与 pose 名称比对无关、非 ERROR。
2. **口径登记（非不一致、未改资源）**
   - `FROZEN_POSES` 11 项 = 基础 8 + Boss 3，player 对应基础 8、Boss 3 由 `boss_spriteframes.tres` 覆盖，详见 §② 口径说明。本单未发现不一致，故**未改任何既有资源**。
3. **范围外 / 未处理（按契约不擅改、不越工位）**
   - 未碰 `godot/scenes/courtyard.tscn`（Rank-1 本轮独占）、未改任何战斗数值、未写其它工位、未写群聊总线 / 总纲 / 协作契约、**未自行 git**。
   - 本单只做「名称一致性」静态/运行期比对，**未**做非 headless 渲染验收 / 人工试玩 / 手感与审美判断；逐帧动作仍依赖 GDExtension 节点 / 4 号 spritesheet 到位（与既有 DONE 口径一致）。
4. **刺探口径**：仅完成本单必要的只读（必读文件、两个 `.tres`、`boss_import.json`、`hybrid_2d3d_animated_sprite.gd` 常量、引擎版本、R13/R14 交付物与回执格式、outbox 现状）与真跑，未做进度巡检、未写探针 / 测量 / preflight 脚本。

> 硬约束核对：默认不刺探 ｜ 零付费 ｜ 不伪造输出（以上 stdout 为原样粘贴）｜ 中文 UTF-8 ｜ Godot 4 合法语法（`--check-only` EXIT=0、`--script` 实跑成功）｜ 三段门禁 `--import` / `--check-only --script` / `--quit` 复跑并贴结论 ｜ 若发现不一致只如实登记、不擅自改既有资源（本单未发现不一致、未改资源）｜ 不碰 `courtyard.tscn` ｜ 不改战斗数值 ｜ 不自行 git。
