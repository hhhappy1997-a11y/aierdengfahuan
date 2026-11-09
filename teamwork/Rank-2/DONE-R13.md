# DONE-R13 · Rank-2 战斗系统与数据驱动

> 命令：`cmd-20261109-080019-794-A2` ｜ `[ROUND=R13]` ｜ AI=2 ｜ 2026-11-09 08:00 派单
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（本轮 `--version` 实测 `4.7.2.stable.official.ed1daf0bf`）
> 工程根：`F:/Game/aierdengfahuan/godot`
> **结论：4 项运行期断言全 PASS（`FAIL_COUNT=0` / `RESULT=PASS`），三段门禁 `--import` / `--check-only` / `--quit` 复跑均 EXIT=0。**

---

## ① 交付清单

| # | 文件 | 位置 | 说明 |
|---|---|---|---|
| 1 | `verify_boss_runtime.gd` | `godot/scripts/verify_boss_runtime.gd` | 最小 `extends SceneTree` 运行期自检脚本，4 项断言：场景 load+instantiate 与根节点名 / `AnimatedSprite2D.sprite_frames` 3 动画与当前 animation / `boss_spriteframes.tres` 独立加载 / `HybridSpriteRig.set_pose()` 调用链 |
| 2 | `DONE-R13.md` | `teamwork/Rank-2/DONE-R13.md` | 本文件：①交付清单 ②自检含真跑实际输出 ③未完成项与阻塞 |
| 3 | `BOSS-RUNTIME-CHECK.md` | `teamwork/Rank-2/BOSS-RUNTIME-CHECK.md` | 验证记录：命令、逐项实际读数、门禁结论、观察项、复现方式 |
| 4 | 回执 JSON | `teamwork/command_center/ai/2/outbox/` | `{"task_id":"cmd-20261109-080019-794-A2","ai":2,"status":"done","result":"…"}` |

> 改动范围核对：唯一新增的 Godot 工程内文件为 `godot/scripts/verify_boss_runtime.gd`（授权可写范围）；另写 `Rank-2/` 两份文档与 `outbox/` 回执。
> **未改动**：既有战斗数值 / 战斗脚本 / `boss_01_margit.tscn` / `boss_spriteframes.tres` / 其它工位文件 / 群聊总线 / 总纲 / 协作契约。**未自行 git**。
>
> **回执投递与中枢消费（如实登记）**：回执按 `task_id` 写入 `command_center/ai/2/outbox/cmd-20261109-080019-794-A2.json`（本轮写入 2 次，内容一致）；中枢 `dispatcher` 对 outbox 实时监控，写入即被消费并归档到 `command_center/dispatcher/receipts/cmd-20261109-080019-794-A2.json`（800 B，内容经读取核对一字一致）。因此核验时 `outbox/` 为空是「已投递并被消费」的正常终态，而非未写回执；`dispatcher/receipts/` 归档副本即为可核对证据。按总线既有口径（如 `MSG-20261109-0500-HOST`「回执按各自 id 写入并被消费」），此为设计内行为，未伪造、未绕过、未重复派单。

---

## ② 自检（真跑实际输出，不以结论代替）

### 复跑命令（一条 Bash 串行执行，4 段 + 缓存佐证）

```bash
GODOT="/d/Godot/Godot_v4.7.2-stable_win64.exe"
ROOT="F:/Game/aierdengfahuan/godot"
"$GODOT" --headless --path "$ROOT" --import
"$GODOT" --headless --path "$ROOT" --check-only --script res://scripts/verify_boss_runtime.gd
"$GODOT" --headless --path "$ROOT" --quit
"$GODOT" --headless --path "$ROOT" --script res://scripts/verify_boss_runtime.gd
grep -n "HybridSpriteRig" "$ROOT/.godot/global_script_class_cache.cfg"
```

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

[   0% ] reimport | Started 正在导入或重新导入资产 (1 steps)
[   0% ] reimport | 正在准备重新导入文件……
[   0% ] reimport | 正在执行重新导入的前置操作……
[   0% ] reimport | ground_tile.png
[  50% ] reimport | 正在结束资产导入……
[ DONE ] reimport

[   0% ] reimport | Started 正在导入或重新导入资产 (1 steps)
[   0% ] reimport | 正在执行重新导入的后置操作……
[ DONE ] reimport

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

==== [R13 BOSS RUNTIME VERIFY] START ====
[1] load()+instantiate() OK | root.name=Boss01Margit | root.class=CharacterBody2D | child_count=1
  [PASS] [1] 根节点名 == 'Boss01Margit'（实际 'Boss01Margit'）
[2] sprite_frames 非 null | animation_count=3 | names=["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"] | current_animation=p1_dagger_slash
  [PASS] [2] 动画数 == 3（实际 3）
  [PASS] [2] 含动画 'p1_dagger_slash'
  [PASS] [2] 含动画 'p1_staff_slam'
  [PASS] [2] 含动画 'p2_holy_hammer'
  [PASS] [2] 当前 animation == 'p1_dagger_slash'（实际 'p1_dagger_slash'）
[3] .tres 独立加载 OK | resource.class=SpriteFrames | animation_count=3 | names=["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]
  [PASS] [3] .tres 动画数 == 3（实际 3）
  [PASS] [3] .tres 含动画 'p1_dagger_slash'
  [PASS] [3] .tres 含动画 'p1_staff_slam'
  [PASS] [3] .tres 含动画 'p2_holy_hammer'
  [PASS] [3] .tres 与场景 sprite_frames 动画数一致（tres=3 scene=3）
[4] HybridSpriteRig 解析 OK | class_name=HybridSpriteRig | has_method(set_pose)=true
  [PASS] [4] HybridSpriteRig 存在可调用方法 set_pose
[4] set_pose('p1_dagger_slash', 0) 实调 OK | current_pose=p1_dagger_slash | current_frame=0
  [PASS] [4] set_pose 后 current_pose == 'p1_dagger_slash'（实际 'p1_dagger_slash'）
==== [R13 BOSS RUNTIME VERIFY] FAIL_COUNT=0 ====
==== [R13 BOSS RUNTIME VERIFY] RESULT=PASS ====
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
VERIFY_RC=0
### global class cache HybridSpriteRig ###
123:"class": &"HybridSpriteRig",
```

### 逐项判定（依据以上实际读数）

| 任务项 | 实际读数 | 判定 |
|---|---|---|
| ① `boss_01_margit.tscn` 可 `load()`+`instantiate()`、根节点名 `Boss01Margit` | `root.name=Boss01Margit`、`root.class=CharacterBody2D`、`child_count=1` | **PASS** |
| ② `AnimatedSprite2D.sprite_frames` 非 null、含 3 动画、当前 animation 正确 | `animation_count=3`、`names=["p1_dagger_slash","p1_staff_slam","p2_holy_hammer"]`、`current_animation=p1_dagger_slash` | **PASS** |
| ③ `boss_spriteframes.tres` 可独立加载且动画数一致 | `resource.class=SpriteFrames`、`animation_count=3`、`tres=3 scene=3` | **PASS** |
| ④ `HybridSpriteRig.set_pose()` 静态解析可调用（`--check-only` 覆盖）+ 运行期实调 | `SEG2_RC=0`（静态解析通过）；`class_name=HybridSpriteRig`、`has_method(set_pose)=true`；实调后 `current_pose=p1_dagger_slash`、`current_frame=0`；缓存第 123 行 `"class": &"HybridSpriteRig"` | **PASS** |

### 三段门禁 + 真跑结论（硬性约束要求贴结论）

| 段 | 命令 | EXIT | 结论 |
|---|---|---|---|
| G1 | `--headless --path <root> --import` | `SEG1_RC=0` | `first_scan_filesystem` / `reimport` / `loading_editor_layout` 全 `DONE`，无 `ERROR`，全局类缓存已刷新 |
| G2 | `--check-only --script res://scripts/verify_boss_runtime.gd` | `SEG2_RC=0` | **只静态解析、不执行**：脚本语法为 Godot 4 合法；其中 `var rig: HybridSpriteRig` 与 `rig.set_pose("p1_dagger_slash", 0)` 被解析通过 → 证明 `class_name HybridSpriteRig` 全局类已注册、`set_pose(String, int)` 在静态解析中可调用（任务第 4 项由本段覆盖） |
| G3 | `--headless --path <root> --quit` | `SEG3_RC=0` | 主场景 + 5 个 autoload 启动后正常退出；仅既有 `ObjectDB leaked` WARNING（非 ERROR） |
| 真跑 | `--headless --path <root> --script res://scripts/verify_boss_runtime.gd` | `VERIFY_RC=0` | `FAIL_COUNT=0`、`RESULT=PASS`，4 项断言全 PASS，`quit(0)` 以 0 退出 |

---

## ③ 未完成项与阻塞

**本单 4 项验证全部真实通过，无待补跑、无待裁决项、无付费 / 外部依赖阻塞。** 以下为如实登记的观察项与范围外事项，不影响本单结论：

1. **运行期 WARNING（既有、非 ERROR、非阻塞）**
   - `--headless --quit` 与 `--script` 真跑均出现 `WARNING: 2 ObjectDB instances were leaked at exit`，与 R9/R10 基线一致（历史 DONE 已登记为 `RefCounted` 残留），非 `SCRIPT ERROR` / `Parse Error` / `ERROR`，不影响 4 项断言与 `EXIT=0`。
   - `--script` 真跑时 autoload `chunk_streaming.gd:51` 另打印 `WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。`，来自工程 autoload 启动链，与 Boss 运行期验证无关、非 ERROR。
2. **范围外 / 未处理（按契约不擅改、不越工位）**
   - `capture/CAPTURE-REPORT.md` 的美术差距（地形无贴图、冷灰蓝、缺暖金光 / 体积光 / 光尘 / 倒影 / bloom / UI / 镜头构图）属 Rank-1 / Rank-4 画面整改，不在本单「战斗系统与数据驱动」可写范围。
   - `boss_spriteframes.tres` 每个动画当前仅 1 帧（`AtlasTexture` 单 region），`set_pose()` 的逐帧动作仍依赖 GDExtension 节点 / 4 号 spritesheet 到位；本单只验证装配与调用链，**未改任何帧数据或战斗数值**。
   - 本单**未**做非 headless 渲染验收 / 人工试玩 / 手感与审美判断（按协作契约 §5「WorkBuddy 不替人做手感与审美判断」、`§1` 目录所有权）。
3. **刺探口径**：仅完成本单必要的只读（必读文件、`.tres` / `.tscn` 实际内容、引擎版本、全局类缓存佐证）与真跑，未做进度巡检、未写探针 / 测量 / preflight 脚本。

> 硬约束核对：默认不刺探 ｜ 零付费 ｜ 不伪造输出（以上 stdout 为原样粘贴） ｜ 三段门禁 `--import` / `--check-only` / `--quit` 复跑并贴结论 ｜ 中文 UTF-8 ｜ Godot 4 合法语法（`--check-only` EXIT=0、`--script` 实跑成功） ｜ 不擅改战斗数值或其它工位 ｜ 不自行 git。
