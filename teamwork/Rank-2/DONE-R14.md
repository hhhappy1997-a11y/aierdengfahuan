# DONE-R14 · Rank-2 战斗系统与数据驱动

> 命令：`cmd-20261109-082141-608-A2` ｜ `[ROUND=R14]` ｜ AI=2 ｜ 2026-11-09 08:21 派单
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（本轮 `--version` 实测 `4.7.2.stable.official.ed1daf0bf`）
> 工程根：`F:/Game/aierdengfahuan/godot`
> **结论：Boss 三招动画切换 8 项断言全 PASS（`PASS_COUNT=8` / `FAIL_COUNT=0` / `RESULT=PASS`）；三段门禁 `--import` / `--check-only --script` / `--quit` 复跑均 EXIT=0，真跑 `VERIFY_RC=0`。**

---

## ① 交付清单

| # | 文件 | 位置 | 说明 |
|---|---|---|---|
| 1 | `verify_boss_poses.gd` | `godot/scripts/verify_boss_poses.gd` | 新建 `extends SceneTree` 运行期自检脚本：load+instantiate `boss_01_margit.tscn`、取 `AnimatedSprite2D`；依次把 `animation` 设为 3 个招式并回读断言一致；每招打印 `sprite_frames.get_frame_count(anim)` 与 `get_animation_loop(anim)`；逐项 PASS/FAIL，末尾 `PASS_COUNT`/`FAIL_COUNT`/`RESULT` 与 `quit(0 if _fail_count == 0 else 1)` |
| 2 | `DONE-R14.md` | `teamwork/Rank-2/DONE-R14.md` | 本文件：①交付清单 ②自检含完整实际 stdout ③未完成项与阻塞 |
| 3 | 回执 JSON | `teamwork/command_center/ai/2/outbox/` | `{"task_id":"cmd-20261109-082141-608-A2","ai":2,"status":"done","result":"…"}` |

> 改动范围核对：唯一新增的 Godot 工程内文件为 `godot/scripts/verify_boss_poses.gd`（授权可写范围）；另写 `Rank-2/DONE-R14.md` 与 `outbox/` 回执。
> **未改动**：既有战斗数值 / 战斗脚本 / `boss_01_margit.tscn` / `boss_spriteframes.tres` / `verify_boss_runtime.gd` / 其它工位文件 / 群聊总线 / 总纲 / 协作契约。**未自行 git**。
>
> **回执投递与中枢消费（如实登记）**：回执按 `task_id` 写入 `command_center/ai/2/outbox/cmd-20261109-082141-608-A2.json`（本轮实写 1 次）。中枢 `dispatcher` 对 outbox 实时监控，写入即被消费并从 outbox 移走、归档到 `command_center/dispatcher/receipts/cmd-20261109-082141-608-A2.json`（637 B，本轮已用 `json.load` 校验合法、读取核对 `task_id`/`ai`/`status`/`result` 四字段与写入内容一致）。因此核验时 `outbox/` 为空是「已投递并被消费」的正常终态，而非未写回执；归档副本即为可核对证据。与 R13 及总线 `MSG-20261109-0500-HOST` 的既有口径一致，未伪造、未绕过、未重复派单。

---

## ② 自检（真跑实际输出，不以结论代替）

### 复跑命令（一条 Bash 串行执行，4 段）

```bash
GODOT="/d/Godot/Godot_v4.7.2-stable_win64.exe"
ROOT="F:/Game/aierdengfahuan/godot"
"$GODOT" --headless --path "$ROOT" --import
"$GODOT" --headless --path "$ROOT" --check-only --script res://scripts/verify_boss_poses.gd
"$GODOT" --headless --path "$ROOT" --quit
"$GODOT" --headless --path "$ROOT" --script res://scripts/verify_boss_poses.gd
```

> 三段门禁对应任务书：`--import` / `--check-only --script verify_boss_poses.gd`（工程内实际路径 `res://scripts/verify_boss_poses.gd`） / `--quit`；末段为真跑以产出逐项 PASS/FAIL 的 stdout。

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

==== [R14 BOSS POSES VERIFY] START ====
[1] load()+instantiate() OK | root.name=Boss01Margit | root.class=CharacterBody2D | child_count=1
  [PASS] [1] 根节点名 == 'Boss01Margit'（实际 'Boss01Margit'）
[1] 取到 AnimatedSprite2D | node.class=AnimatedSprite2D | sprite_frames_null=false
  [PASS] [1] AnimatedSprite2D.sprite_frames 非 null
[2] sprite_frames 动画清单 | animation_count=3 | names=["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]
[2.1] ---- 切换招式 'p1_dagger_slash' ----
  [PASS] [2.1] sprite_frames 含动画 'p1_dagger_slash'
[2.1] 设置 animation='p1_dagger_slash' 后回读 | animation='p1_dagger_slash'
  [PASS] [2.1] animation 回读一致（期望 'p1_dagger_slash' / 实际 'p1_dagger_slash'）
[2.1] sprite_frames.get_frame_count('p1_dagger_slash')=1
[2.1] sprite_frames.get_animation_loop('p1_dagger_slash')=false
[2.2] ---- 切换招式 'p1_staff_slam' ----
  [PASS] [2.2] sprite_frames 含动画 'p1_staff_slam'
[2.2] 设置 animation='p1_staff_slam' 后回读 | animation='p1_staff_slam'
  [PASS] [2.2] animation 回读一致（期望 'p1_staff_slam' / 实际 'p1_staff_slam'）
[2.2] sprite_frames.get_frame_count('p1_staff_slam')=1
[2.2] sprite_frames.get_animation_loop('p1_staff_slam')=false
[2.3] ---- 切换招式 'p2_holy_hammer' ----
  [PASS] [2.3] sprite_frames 含动画 'p2_holy_hammer'
[2.3] 设置 animation='p2_holy_hammer' 后回读 | animation='p2_holy_hammer'
  [PASS] [2.3] animation 回读一致（期望 'p2_holy_hammer' / 实际 'p2_holy_hammer'）
[2.3] sprite_frames.get_frame_count('p2_holy_hammer')=1
[2.3] sprite_frames.get_animation_loop('p2_holy_hammer')=false
==== [R14 BOSS POSES VERIFY] PASS_COUNT=8 FAIL_COUNT=0 ====
==== [R14 BOSS POSES VERIFY] RESULT=PASS ====
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
VERIFY_RC=0
```

### 逐项判定（依据以上实际读数）

| 任务项 | 实际读数 | 判定 |
|---|---|---|
| ① `boss_01_margit.tscn` 可 `load()`+`instantiate()`、取到 `AnimatedSprite2D` | `root.name=Boss01Margit`、`root.class=CharacterBody2D`、`child_count=1`；`node.class=AnimatedSprite2D`、`sprite_frames_null=false` | **PASS**（2 条 `[PASS]`） |
| ② 依次设置 `p1_dagger_slash` 并回读一致 | `animation='p1_dagger_slash'`；`get_frame_count=1`；`get_animation_loop=false` | **PASS**（含动画 + 回读一致 2 条 `[PASS]`） |
| ② 依次设置 `p1_staff_slam` 并回读一致 | `animation='p1_staff_slam'`；`get_frame_count=1`；`get_animation_loop=false` | **PASS**（2 条 `[PASS]`） |
| ② 依次设置 `p2_holy_hammer` 并回读一致 | `animation='p2_holy_hammer'`；`get_frame_count=1`；`get_animation_loop=false` | **PASS**（2 条 `[PASS]`） |
| ③ 每招打印 `get_frame_count(anim)` 与 `get_animation_loop(anim)` | `[2.1]/[2.2]/[2.3]` 各打印两行，值均为 `1` / `false` | **PASS**（已打印、见 stdout） |
| 汇总 | `PASS_COUNT=8 FAIL_COUNT=0`、`RESULT=PASS`、`VERIFY_RC=0` | **PASS** |

> 8 条 `[PASS]` 明细：`[1]` 根节点名、`[1]` sprite_frames 非 null、`[2.1]`/`[2.2]`/`[2.3]` 各「含动画」+「回读一致」= 6 条；`[FAIL]` 为 0。

### 三段门禁 + 真跑结论（硬性约束要求贴结论）

| 段 | 命令 | EXIT | 结论 |
|---|---|---|---|
| G1 | `--headless --path <root> --import` | `SEG1_RC=0` | `first_scan_filesystem` / `loading_editor_layout` 全 `DONE`，无 `ERROR`，全局类缓存刷新（本轮无新增资源，未触发 `reimport` 段，与 R13 差异属正常） |
| G2 | `--check-only --script res://scripts/verify_boss_poses.gd` | `SEG2_RC=0` | **只静态解析、不执行**：脚本为 Godot 4 合法语法；`get_frame_count()` / `get_animation_loop()` / `has_animation()` / `StringName()` 调用解析通过 |
| G3 | `--headless --path <root> --quit` | `SEG3_RC=0` | 主场景 + autoload 启动后正常退出；仅既有 `ObjectDB leaked` WARNING（非 ERROR） |
| 真跑 | `--headless --path <root> --script res://scripts/verify_boss_poses.gd` | `VERIFY_RC=0` | `PASS_COUNT=8`、`FAIL_COUNT=0`、`RESULT=PASS`，`quit(0)` 以 0 退出 |

---

## ③ 未完成项与阻塞

**本单 3 项验证全部真实通过，无待补跑、无待裁决项、无付费 / 外部依赖阻塞。** 以下为如实登记的观察项与范围外事项，不影响本单结论：

1. **运行期 WARNING（既有、非 ERROR、非阻塞）**
   - `--headless --quit` 与 `--script` 真跑均出现 `WARNING: 2 ObjectDB instances were leaked at exit`，与 R9/R10/R13 基线一致（历史 DONE 已登记为 `RefCounted` 残留），非 `SCRIPT ERROR` / `Parse Error` / `ERROR`，不影响 8 项断言与 `EXIT=0`。
   - `--script` 真跑时 autoload `chunk_streaming.gd:51` 另打印 `WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。`，来自工程 autoload 启动链，与 Boss 动画切换验证无关、非 ERROR。
2. **范围外 / 未处理（按契约不擅改、不越工位）**
   - `boss_spriteframes.tres` 三个动画当前各仅 1 帧（`AtlasTexture` 单 128×128 region）、`loop=0`（`get_animation_loop=false`）：本单只验证「切换 + 回读 + 帧数/loop 读取」，**未改任何帧数据或战斗数值**；逐帧动作仍依赖 GDExtension 节点 / 4 号 spritesheet 到位。
   - `verify_boss_runtime.gd`（R13）保持原样未改；本单为新建脚本 `verify_boss_poses.gd`，二者并存。
   - 本单**未**做非 headless 渲染验收 / 人工试玩 / 手感与审美判断（按协作契约 §5「WorkBuddy 不替人做手感与审美判断」、§1 目录所有权）。
3. **刺探口径**：仅完成本单必要的只读（必读文件、`.tres` / `.tscn` 实际内容、引擎版本、R13 交付物、任务单）与真跑，未做进度巡检、未写探针 / 测量 / preflight 脚本。

> 硬约束核对：默认不刺探 ｜ 零付费 ｜ 不伪造输出（以上 stdout 为原样粘贴） ｜ 三段门禁 `--import` / `--check-only --script` / `--quit` 复跑并贴结论 ｜ 中文 UTF-8 ｜ Godot 4 合法语法（`--check-only` EXIT=0、`--script` 实跑成功） ｜ 不擅改战斗数值或其它工位 ｜ 不自行 git。
