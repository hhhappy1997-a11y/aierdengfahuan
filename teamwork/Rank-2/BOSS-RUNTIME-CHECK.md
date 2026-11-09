# BOSS-RUNTIME-CHECK · R13 Boss 运行期验证记录

> 命令 `cmd-20261109-080019-794-A2` ｜ `[ROUND=R13]` ｜ Rank-2 战斗系统与数据驱动 ｜ 2026-11-09
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe` = Godot `4.7.2.stable.official.ed1daf0bf`（本轮 `--version` 实测 EXIT=0）
> 工程根：`F:/Game/aierdengfahuan/godot`
> 配套自检：`Rank-2/DONE-R13.md`（含完整实际 stdout）

---

## 1. 验证目标与脚本内对应实现

脚本：`godot/scripts/verify_boss_runtime.gd`，`extends SceneTree`，入口 `_initialize()`，末尾 `quit(0 if _fail_count == 0 else 1)`。

| 任务项 | 实现函数 | 关键 API / 断言 |
|---|---|---|
| ① 场景可 `load()` + `instantiate()`、根节点名 `Boss01Margit` | `_step1_load_and_instantiate()` | `load(BOSS_SCENE_PATH) as PackedScene` → `instantiate()`；读 `inst.name` / `get_class()` / `get_child_count()`；断言 `name == "Boss01Margit"` |
| ② `AnimatedSprite2D.sprite_frames` 非 null、含 3 动画、当前 animation 正确 | `_step2_sprite_frames()` | `get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D`；`sprite_frames.get_animation_names()` / `has_animation()`；`String(asp.animation)`；断言数量=3、3 个名字齐备、`current == "p1_dagger_slash"` |
| ③ `boss_spriteframes.tres` 可独立加载且动画数一致 | `_step3_standalone_tres()` | `load(BOSS_TRES_PATH) as SpriteFrames`（不依赖场景实例）；断言数量=3、名字齐备、与 ② 的 `_scene_anim_names` 数量一致 |
| ④ `HybridSpriteRig.set_pose()` 静态解析可调用（`--check-only` 覆盖）+ 运行期实调 | `_step4_hybrid_rig_set_pose()` | 静态类型化 `var rig: HybridSpriteRig = HybridSpriteRig.new()` 与 `rig.set_pose("p1_dagger_slash", 0)` → 由 `--check-only` 解析期校验全局类与方法签名；运行期 `get_script().call("get_global_name")` / `has_method("set_pose")` / `get_current_pose()` / `get_current_frame()` 读回 |

期望值常量（与 `boss_01_margit.tscn` / `boss_spriteframes.tres` 文本一致）：

- `EXPECTED_ROOT_NAME = "Boss01Margit"`
- `EXPECTED_ANIMATIONS = ["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"]`
- `EXPECTED_CURRENT_ANIMATION = "p1_dagger_slash"`

> ② 与 ③ 的「独立」性：`_step3` 直接对 `res://assets/generated/boss/boss_spriteframes.tres` 调用 `load()`，不以 `_boss` 实例为前提；与场景 `ExtResource("1_kpfol")` 装配结果做数量比对（`tres=3 scene=3`）。

---

## 2. 实际执行的命令

```bash
GODOT="/d/Godot/Godot_v4.7.2-stable_win64.exe"
ROOT="F:/Game/aierdengfahuan/godot"

# G1 导入门禁
"$GODOT" --headless --path "$ROOT" --import
# G2 静态解析门禁（覆盖 HybridSpriteRig.set_pose 调用链）
"$GODOT" --headless --path "$ROOT" --check-only --script res://scripts/verify_boss_runtime.gd
# G3 加载退出门禁
"$GODOT" --headless --path "$ROOT" --quit
# 验证脚本真跑（产出 4 项断言实际 stdout）
"$GODOT" --headless --path "$ROOT" --script res://scripts/verify_boss_runtime.gd
# 佐证：全局类缓存中 class_name 已注册
grep -n "HybridSpriteRig" "$ROOT/.godot/global_script_class_cache.cfg"
```

顺序说明：先 `--import` 刷新 `.godot/global_script_class_cache.cfg`（全局类注册），再 `--check-only` 静态解析，再 `--quit` 加载门禁，最后 `--script` 真跑；`grep` 为 class_name 注册的只读佐证。

---

## 3. 实际 stdout（原样粘贴）

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

---

## 4. 门禁与真跑结论

| 段 | 命令 | EXIT | 结论 |
|---|---|---|---|
| G1 | `--headless --path <root> --import` | `SEG1_RC=0` | `first_scan_filesystem` / `reimport` / `loading_editor_layout` 全 `[ DONE ]`，无 `ERROR` |
| G2 | `--check-only --script res://scripts/verify_boss_runtime.gd` | `SEG2_RC=0` | 只静态解析不执行；Godot 4 语法合法；`HybridSpriteRig`(class_name) 与 `set_pose(String,int)` 在解析期可调用 → **任务第 4 项由本段覆盖** |
| G3 | `--headless --path <root> --quit` | `SEG3_RC=0` | 主场景 + autoload 启动后正常退出；仅既有 `ObjectDB leaked` WARNING |
| 真跑 | `--headless --path <root> --script res://scripts/verify_boss_runtime.gd` | `VERIFY_RC=0` | `FAIL_COUNT=0`、`RESULT=PASS`，4 项断言 14 条 `[PASS]`、`[FAIL]` 为 0，`quit(0)` |
| 佐证 | `grep -n "HybridSpriteRig" .../.godot/global_script_class_cache.cfg` | — | 第 123 行 `"class": &"HybridSpriteRig"`，全局类缓存已登记 |

> `--check-only` 与 G2 的关系：G2 只解析 `verify_boss_runtime.gd`，不会执行 `_initialize()`；脚本中对 `HybridSpriteRig` 的类型标注与 `rig.set_pose(...)` 调用若类未注册或方法签名不符，解析期即报错。实际 `SEG2_RC=0`，且缓存第 123 行佐证注册，故「静态解析中可调用」成立。G3 与真跑段是运行期证据，二者互相印证。

---

## 5. 逐项实际读数

| 项 | 打印行（实际值） | 结果 |
|---|---|---|
| ① | `[1] load()+instantiate() OK \| root.name=Boss01Margit \| root.class=CharacterBody2D \| child_count=1` | PASS |
| ② | `[2] sprite_frames 非 null \| animation_count=3 \| names=["p1_dagger_slash", "p1_staff_slam", "p2_holy_hammer"] \| current_animation=p1_dagger_slash` | PASS |
| ③ | `[3] .tres 独立加载 OK \| resource.class=SpriteFrames \| animation_count=3 \| names=[…]` + `tres=3 scene=3` | PASS |
| ④ | `SEG2_RC=0`（静态）+ `[4] class_name=HybridSpriteRig \| has_method(set_pose)=true` + `[4] current_pose=p1_dagger_slash \| current_frame=0` | PASS |
| 汇总 | `==== [R13 BOSS RUNTIME VERIFY] FAIL_COUNT=0 ====` / `RESULT=PASS` / `VERIFY_RC=0` | PASS |

---

## 6. 观察项（非阻塞，如实登记）

1. `WARNING: 2 ObjectDB instances were leaked at exit`（SEG3 与真跑段各 1 次）：与 R9/R10 基线一致的既有 `RefCounted` 残留，WARNING 级，非 `SCRIPT ERROR` / `Parse Error` / `ERROR`，不影响 `EXIT=0` 与 4 项断言。
2. `WARNING: [ChunkManager] 未找到 ChunkRoot`（真跑段）：来自 `res://scripts/world/chunk_streaming.gd:51` 的 autoload `_bootstrap`，`--script` 模式下 autoload 仍启动；与 Boss 运行期验证无关，非 ERROR。
3. `boss_spriteframes.tres` 每个动画当前 `frames` 数组仅 1 帧（`AtlasTexture` 单 128×128 region）：本单验证装配与调用链，未改帧数据；逐帧动作仍待 GDExtension / 4 号 spritesheet 到位。
4. 未做非 headless 渲染验收、人工试玩、手感与审美判断（按协作契约 §5）。

---

## 7. 复现方式

在 `F:/Game/aierdengfahuan/` 下（或任意目录用绝对 `--path`）：

```bash
"/d/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --import
"/d/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --check-only --script res://scripts/verify_boss_runtime.gd
"/d/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --quit
"/d/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --script res://scripts/verify_boss_runtime.gd
```

预期：4 段 EXIT 均为 0；末段 stdout 含 `FAIL_COUNT=0` 与 `RESULT=PASS`。

---

## 8. 范围与约束声明

- 可写范围仅用：`godot/scripts/verify_boss_runtime.gd`、`teamwork/Rank-2/`、`teamwork/command_center/ai/2/outbox/`。
- 未改战斗数值、未改 `.tscn` / `.tres` / 其它工位、未改群聊总线 / 总纲 / 协作契约、未自行 git。
- 默认不刺探、零付费、不伪造输出（第 3 节为原样 stdout）、三段门禁复跑并贴结论、中文 UTF-8、Godot 4 合法语法。
