# DONE-R17 · Rank-2 Boss 阶段切换运行期验证

- 轮次：`[ROUND=R17]`
- 命令 id：`cmd-20261109-093050-716-A2`（2026-11-09 09:30:51 派发，priority=normal / GUI 下达）
- 任务真源：`teamwork/Rank-2/调度任务单-latest.json` 字段 `task`；已与 `teamwork/command_center/ai/2/inbox/task_cmd-20261109-093050-716-A2.json` 核对，两者 `id`、`[ROUND=R17]` 标记及 task 文本逐字一致，以该任务单为唯一真源。未假定轮次、未沿用历史 id。
- 开工只读（各一次，未轮询）：`godot/scenes/boss_01_margit.tscn`、`godot/scripts/render/hybrid_2d3d_animated_sprite.gd`（`_resolve_full_pose()` / `pose_prefix` / `FROZEN_POSES`）、`teamwork/00-群聊总线.md`（append-only 唯一真源，仅在文件末尾读一次、未改任何历史条目）。
- 执行：Rank-2 执行 AI（本实例）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
- 工程根：`F:/Game/aierdengfahuan/godot`

## 并发保护执行记录

开工只读检查 `godot/scripts/verify_boss_phase.gd` / `teamwork/Rank-2/DONE-R17.md` / `command_center/ai/2/outbox/` / `command_center/dispatcher/receipts/cmd-20261109-093050-716-A2.json`：四者当时均缺（outbox 空、本轮回执未归档）→ 判定本轮交付未被并发实例写入，由本实例完整新建，各 1 份。写 DONE 与回执前再次只读复核 outbox 仍为空、回执仍未归档，方才写入，未覆盖任何已有件、未重复写第二份回执。

## ① 实际交付文件清单

| # | 文件 | 说明 | 本实例动作 |
|---|---|---|---|
| 1 | `godot/scripts/verify_boss_phase.gd` | `extends SceneTree` 验证脚本（新建）：实例化 `boss_01_margit.tscn` 取 `AnimatedSprite2D`；三招阶段切换逐次设 `animation` 并回读断言；核对 `HybridSpriteRig._resolve_full_pose()` 的 `pose_prefix` 拼接与 `FROZEN_POSES` 校验；逐项 `[PASS]/[FAIL]` 与汇总 `RESULT` | 新建 |
| 2 | `teamwork/Rank-2/R17-verify-run.log` | 四段命令完整实际 stdout（94 行，含 ANSI 原始控制码），真跑证据留档 | 新建 |
| 3 | `teamwork/Rank-2/DONE-R17.md` | 本文件（①交付清单 ②自检含完整实际 stdout ③未完成项与阻塞） | 新建 |
| 4 | `teamwork/command_center/ai/2/outbox/cmd-20261109-093050-716-A2.json` | 回执 JSON（task_id 用本轮 id，只 1 份） | 新建 |

**未改动**：`courtyard.tscn`（Rank-1 独占）及任何场景；`boss_01_margit.tscn`、`boss_spriteframes.tres`；任何战斗数值 / `.tres` / combat 脚本；`hybrid_2d3d_animated_sprite.gd`（仅只读核对）；其它 Rank 工位；群聊总线 / 总纲 / 协作契约 / 进度台账；`project.godot`。未 git commit / push；未生成汇总文档；未写探针 / 测量 / preflight 脚本。

## ② 自检：完整实际 stdout + 逐项 PASS/FAIL + 门禁 EXIT

### 命令与逐段 EXIT（真跑实测）

三段门禁按任务字面为 G1/G2/G3；另按 R13~R16 既有惯例执行 G4 主运行段（`--script` 不带 `--check-only`）——因 `--check-only` 仅静态解析、`--quit` 仅加载主场景后退出，二者都不执行脚本 `_initialize()`，实例化 / 断言 / 逐项 stdout 只能在 G4 产生。G4 是为满足本轮「真跑」实质而执行，未改任何场景与数值。

```
G1 导入门禁 : godot --headless --path <root> --import
G2 静态解析 : godot --headless --path <root> --check-only --script res://scripts/verify_boss_phase.gd
G3 加载退出 : godot --headless --path <root> --quit
G4 主真跑   : godot --headless --path <root> --script res://scripts/verify_boss_phase.gd
```

| 段 | 命令 | EXIT | 实测标记 |
|---|---|---|---|
| G1 | `--import` | **0** | `G1_IMPORT_EXIT=0` |
| G2 | `--check-only --script` | **0** | `G2_CHECKONLY_EXIT=0` |
| G3 | `--headless --quit` | **0** | `G3_QUIT_EXIT=0` |
| G4 | `--script` 主真跑 | **0** | `G4_RUN_EXIT=0` |

### grep 结论（硬约束项）

`grep "SCRIPT ERROR|Parse Error|ERROR" R17-verify-run.log` → **No matches found（0 条）**。

**WARNING（非 ERROR，如实登记）**：G3 有 1 条 `2 ObjectDB instances were leaked at exit`；G4 有 1 条 `[ChunkManager] 未找到 ChunkRoot`（`res://scripts/world/chunk_streaming.gd:51`）与 1 条 `2 ObjectDB instances were leaked at exit`。以上均属既有工程运行期告警、非本轮脚本问题、非 `ERROR`、四段 `EXIT` 仍全为 0，按「如实登记、不擅改」未处理、未越界修改。

### 四段完整实际 stdout（终端可读版，逐行原文；含 ANSI 原始字节见同目录 `R17-verify-run.log`）

```text
### G1 --headless --path <root> --import ###
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

G1_IMPORT_EXIT=0
### G2 --headless --path <root> --check-only --script res://scripts/verify_boss_phase.gd ###
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

G2_CHECKONLY_EXIT=0
### G3 --headless --path <root> --quit ###
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G3_QUIT_EXIT=0
### G4 --headless --path <root> --script res://scripts/verify_boss_phase.gd (主真跑) ###
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

==== [R17 BOSS PHASE VERIFY] START ====
---- [1] 实例化 boss_01_margit.tscn / 取 AnimatedSprite2D ----
[1] load()+instantiate() OK | root.name=Boss01Margit | root.class=CharacterBody2D | child_count=1
  [PASS] [1] 根节点名 == 'Boss01Margit'（实际 'Boss01Margit'）
[1] 取到 AnimatedSprite2D | class=AnimatedSprite2D | sprite_frames_null=false | initial_animation='p1_dagger_slash'
  [PASS] [1] AnimatedSprite2D.sprite_frames 非 null
---- [2] 模拟阶段切换：p1_ 两招 → p2_ 一招，逐次设 animation 并回读 ----
[2] sprite_frames 动画清单 | animation_count=3 | names=["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]
[2.1] ---- 切招 'p1_dagger_slash'（阶段前缀期望 'p1_'）----
  [PASS] [2.1] 'p1_dagger_slash' 带阶段前缀 'p1_'
  [PASS] [2.1] sprite_frames 含动画 'p1_dagger_slash'
[2.1] 设置 animation='p1_dagger_slash' 后回读 | animation='p1_dagger_slash'
  [PASS] [2.1] animation 回读一致（期望 'p1_dagger_slash' / 实际 'p1_dagger_slash'）
[2.1] get_frame_count('p1_dagger_slash')=1 | get_animation_loop('p1_dagger_slash')=false
[2.2] ---- 切招 'p1_staff_slam'（阶段前缀期望 'p1_'）----
  [PASS] [2.2] 'p1_staff_slam' 带阶段前缀 'p1_'
  [PASS] [2.2] sprite_frames 含动画 'p1_staff_slam'
[2.2] 设置 animation='p1_staff_slam' 后回读 | animation='p1_staff_slam'
  [PASS] [2.2] animation 回读一致（期望 'p1_staff_slam' / 实际 'p1_staff_slam'）
[2.2] get_frame_count('p1_staff_slam')=1 | get_animation_loop('p1_staff_slam')=false
[2.3] ---- 切招 'p2_holy_hammer'（阶段前缀期望 'p2_'）----
  [PASS] [2.3] 'p2_holy_hammer' 带阶段前缀 'p2_'
  [PASS] [2.3] sprite_frames 含动画 'p2_holy_hammer'
[2.3] 设置 animation='p2_holy_hammer' 后回读 | animation='p2_holy_hammer'
  [PASS] [2.3] animation 回读一致（期望 'p2_holy_hammer' / 实际 'p2_holy_hammer'）
[2.3] get_frame_count('p2_holy_hammer')=1 | get_animation_loop('p2_holy_hammer')=false
  [PASS] [2] 阶段切换末态 animation == 'p2_holy_hammer'（实际 'p2_holy_hammer'）
---- [3] HybridSpriteRig.pose_prefix 拼接 / FROZEN_POSES 校验 ----
[3] HybridSpriteRig.FROZEN_POSES | count=11 | values=["idle", "walk", "run", "roll", "attack_light", "attack_heavy", "hitstun", "death", "dagger_slash", "staff_slam", "holy_hammer"]
[3] HybridSpriteRig.POSE_PREFIXES | count=2 | values=["p1_", "p2_"]
  [PASS] [3.1] FROZEN_POSES 数量 == 11（基础8+Boss3，实际 11）
  [PASS] [3.1] FROZEN_POSES 含 Boss 基础名 'dagger_slash'
  [PASS] [3.1] FROZEN_POSES 含 Boss 基础名 'staff_slam'
  [PASS] [3.1] FROZEN_POSES 含 Boss 基础名 'holy_hammer'
  [PASS] [3.2] POSE_PREFIXES == ['p1_','p2_']（实际 ["p1_", "p2_"]）
[3.3] -- pose_prefix 拼接（传冻结基础名）--
  [PASS] [3.3.a] pose_prefix='p1_'+'dagger_slash' | 入参='dagger_slash' 实际='p1_dagger_slash' 期望='p1_dagger_slash'
  [PASS] [3.3.b] pose_prefix='p1_'+'staff_slam' | 入参='staff_slam' 实际='p1_staff_slam' 期望='p1_staff_slam'
  [PASS] [3.3.c] pose_prefix='p2_'+'holy_hammer' | 入参='holy_hammer' 实际='p2_holy_hammer' 期望='p2_holy_hammer'
[3.4] -- 自带 p1_/p2_ 前缀完整名（忽略 pose_prefix）--
  [PASS] [3.4.a] pose_prefix='p2_' 但入参 'p1_dagger_slash' | 入参='p1_dagger_slash' 实际='p1_dagger_slash' 期望='p1_dagger_slash'
  [PASS] [3.4.b] pose_prefix='p1_' 但入参 'p2_holy_hammer' | 入参='p2_holy_hammer' 实际='p2_holy_hammer' 期望='p2_holy_hammer'
[3.5] -- FROZEN_POSES 校验（合法接受 / 非法拒绝）--
[3.5] 冻结表 11 项以 pose_prefix='p1_' 拼接 | accepted=11
  [PASS] [3.5.a] FROZEN_POSES 全部基础名被 _resolve_full_pose 接受（accepted=11/11）
  [PASS] [3.5.b] 表外基础名 'not_a_pose' 应被拒绝 | 入参='not_a_pose' 实际='' 期望=''
  [PASS] [3.5.c] 表外带前缀名 'p1_not_a_pose' 应被拒绝 | 入参='p1_not_a_pose' 实际='' 期望=''
  [PASS] [3.5.d] 近似名 'holy_hammer_extra' 应被拒绝 | 入参='holy_hammer_extra' 实际='' 期望=''
[3.6] -- 公开接口 set_pose() + get_current_pose() 端到端 --
[3.6] set_pose('dagger_slash',0) @ pose_prefix='p1_' | current_pose='p1_dagger_slash' | current_frame=0
  [PASS] [3.6.a] set_pose('dagger_slash') 后 current_pose == 'p1_dagger_slash'（实际 'p1_dagger_slash'）
[3.6] set_pose('holy_hammer',0) @ pose_prefix='p2_' | current_pose='p2_holy_hammer' | current_frame=0
  [PASS] [3.6.b] set_pose('holy_hammer') 后 current_pose == 'p2_holy_hammer'（实际 'p2_holy_hammer'）
==== [R17 BOSS PHASE VERIFY] PASS_COUNT=28 FAIL_COUNT=0 ====
==== [R17 BOSS PHASE VERIFY] RESULT=PASS ====
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G4_RUN_EXIT=0
```

### 逐项结论汇总（对应本轮任务要求）

| 核对项 | 实测结论 |
|---|---|
| 1. 实例化 `boss_01_margit.tscn`、取 `AnimatedSprite2D` | `load()+instantiate()` OK：`root.name=Boss01Margit` / `class=CharacterBody2D` / `child_count=1`；取到 `AnimatedSprite2D`，`sprite_frames` 非 null，`initial_animation='p1_dagger_slash'` → **PASS** |
| 2. 阶段切换 `p1_dagger_slash` → `p1_staff_slam` → `p2_holy_hammer` 逐次设 `animation` 回读断言 | 三招前缀 `p1_`/`p1_`/`p2_`，`sprite_frames` 均含该动画，设后回读逐次一致，`frame_count=1` / `loop=false`，末态 `animation='p2_holy_hammer'` → **PASS** |
| 3a. `pose_prefix` 拼接（`p1_`/`p2_`） | `_resolve_full_pose()`：基础名 + `pose_prefix='p1_'` → `p1_dagger_slash`/`p1_staff_slam`，`pose_prefix='p2_'` → `p2_holy_hammer`；自带前缀完整名不受 `pose_prefix` 影响 → **PASS** |
| 3b. `FROZEN_POSES` 校验 | 冻结表 11 项（基础8+Boss3）全部被 `_resolve_full_pose` 接受（accepted=11/11）；`not_a_pose` / `p1_not_a_pose` / `holy_hammer_extra` 三个表外名均返回空串被拒绝；`set_pose()+get_current_pose()` 端到端佐证 `p1_dagger_slash` / `p2_holy_hammer` → **PASS** |
| 3c. 打印实际 stdout 与逐项 PASS/FAIL | 逐项 `[PASS]` 共 28 条、`[FAIL]` 0 条 → `PASS_COUNT=28 FAIL_COUNT=0 RESULT=PASS`，`quit(0)` → **PASS** |
| 4. 三段门禁 + grep | G1/G2/G3 `EXIT` 全 0（+G4 主真跑 `EXIT=0`）；`SCRIPT ERROR` / `Parse Error` / `ERROR` **0 匹配** |

## ③ 未完成项与阻塞（如实）

- **阻塞：无**。本轮任务范围内全部完成，四段 `EXIT` 全 0、主真跑 `RESULT=PASS`、脚本 `quit(0)`，未出现做不到或无法验证的项。
- **未完成项：无**（本轮交付范围内）。
- **如实登记项（WARNING，非 ERROR、非阻塞）**：G3 与 G4 各 1 条 `2 ObjectDB instances were leaked at exit`；G4 另有 1 条 `[ChunkManager] 未找到 ChunkRoot`（`res://scripts/world/chunk_streaming.gd:51`）。均属既有工程运行期告警、非本轮脚本问题、`EXIT` 仍全为 0，未处理、未越界修改。
- **口径说明**：本轮三段门禁按任务字面对应 G1/G2/G3；G4 主运行段为本轮「真跑实例化 / 断言 / 打印 stdout」的实质执行段（沿用 R13~R16 已验证惯例），未改任何场景、数值或工程配置。
- **并发状态**：4 件交付均由本实例新建，各 1 份，未覆盖并发产出、未重复写第二份回执。
- **约束声明**：默认不刺探（只读本工位、公开总线、必读三件与本轮回执命名约定）；零付费 / 零外部依赖；中文 UTF-8；Godot 4 合法语法（G2 `--check-only` `EXIT=0`）；不碰 `courtyard.tscn`、不改战斗数值、不自行 git。

## 回执

`teamwork/command_center/ai/2/outbox/cmd-20261109-093050-716-A2.json`：

```json
{"task_id":"cmd-20261109-093050-716-A2","ai":2,"status":"done","result":"引用 DONE-R17.md 实际结论"}
```

`task_id` 使用本轮 id `cmd-20261109-093050-716-A2`，未沿用历史 id；只写 1 份。

**送达态复核（写后立即只读）**：回执写入 `ai/2/outbox/` 后已被调度中枢即时消费，归档为 `teamwork/command_center/dispatcher/receipts/cmd-20261109-093050-716-A2.json`（107 字节，09:36），已只读核对其内容与上方 JSON 逐字一致（`task_id` / `ai` / `status=done` / `result` 均正确）。`ai/2/status.json` 现为 `state=idle` / `current_task` 为空 / `completed=19`（较派单时 +1）→ 中枢已确认本轮 done、ai=2 转空闲。故 `ai/2/outbox/` 当前为空是「回执已送达中枢」的正常终态，非「回执未写」；按并发保护「不重复写第二份回执、不代写回执」，不再向 outbox 写第二份。
