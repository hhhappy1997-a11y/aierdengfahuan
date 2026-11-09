# DONE-R17.md · hd2d_fx.tscn 光效档位验证（验证轮次）

> 轮次：**R17**｜派单：`cmd-20261109-093050-722-A4`｜命令：`[ROUND=R17]`｜工位：**Rank-4 美术管线与工具链**｜日期：2026-11-09
> 定位：**验证件**。对 R16 交付的独立光效场景 `godot/scenes/hd2d_fx.tscn` 做**真跑实例化 + 档位回读验证**：写 `godot/scripts/verify_fx_profile.gd`（`extends SceneTree`），`ResourceLoader.load(CACHE_MODE_IGNORE)` 从磁盘加载 → `instantiate()` → 加入场景树并等待首帧触发 4 个 FX 节点 `_ready()` → 用公共入口 `set_fx_profile()` 把 `FXReflection` / `FXGodRays` / `FXMotes` / `FXBloom` 分别切到 `desktop` 与 `mobile`，逐项回读 `visible` / `_all_on` / `fx_profile` / `texture_filter` 并逐项 PASS/FAIL。
> 必读（已读）：`godot/scenes/hd2d_fx.tscn`、`godot/scripts/hd2d_fx.gd`（`fx_profile` / `_all_on` / `visible`）、`Rank-4/DONE-R16.md`、`00-群聊总线.md`（**开工只读一次、未追加**）。
> 只读参考（均未改）：`godot/scripts/build_hd2d_fx.gd`（`extends SceneTree` + `_initialize()` + `CACHE_MODE_IGNORE` + `set_fx_profile()` 已验证合法模式）、`godot/project.godot`、`Rank-4/调度任务单-latest.json`（本轮唯一真源：`id=cmd-20261109-093050-722-A4` / `[ROUND=R17]` / `ai=4`）。
> 合规：零付费 / 零外部素材 / 零插件 / 零云服务；**ComfyUI 仍是主美术路线**；不碰 `courtyard.tscn`（Rank-1 独占、sha256 前后一致）；不伪造输出、不臆造引擎常量（期望值用 `CanvasItem.TEXTURE_FILTER_NEAREST` 枚举，未写死魔法数字判定）；中文 UTF-8；Godot 4.7.2 合法语法；不自行 `git commit` / `git push`。

---

## 0. 一句话结论

R17 把 R16 的 `fx_profile` 档位开关做了**真跑实例化回读验证**：`verify_fx_profile.gd` 从磁盘加载并实例化 `hd2d_fx.tscn`（`CACHE_MODE_IGNORE`），`root.add_child()` + `await process_frame` 让 4 个 FX 节点 `_ready()` 真正触发（`inst_inside_tree=true` / 四节点 `ready=true`），再用 `set_fx_profile()` 分别切 `desktop` / `mobile` 并逐项回读 4 个属性——**共 34 项校验全 `PASS=true`、`pass=34 fail=0`、`RESULT=PASS`**：`desktop` 四项全开（`visible=true` / `_all_on=true` / `fx_profile=desktop`）、`mobile` 四项全关（`visible=false` / `_all_on=false` / `fx_profile=mobile`），`texture_filter` 两档均为 `CanvasItem.TEXTURE_FILTER_NEAREST(=1)`。三段门禁 `G1 --import` / `G2 --check-only --script verify_fx_profile.gd` / `G3 --quit` 与 `RUN` 真跑**实际 `EXIT` 全 0**；`courtyard.tscn` sha256 前后逐字一致，证明**零写入**。**本轮只做档位程序化验证，独立场景仍未挂主场景 / 未抓帧验收画面。**

---

## 1. 交付清单（①）

| # | 文件 | 字节 | sha256（前缀） | 说明 |
|---|---|---|---|---|
| 1 | `godot/scripts/verify_fx_profile.gd` | 6625 | `4f48d67ca92524b3…` | `extends SceneTree` 档位回读验证脚本；`CACHE_MODE_IGNORE` 加载 + 真跑实例化 + 进树 + 两档切换 + 34 项逐项 PASS/FAIL |
| 2 | `teamwork/Rank-4/DONE-R17.md` | 见文件 | 见文件 | 本文件（①交付清单 ②自检含完整实际 stdout ③未完成项与阻塞） |
| 3 | `teamwork/command_center/ai/4/outbox/cmd-20261109-093050-722-A4.json` | 见回执 | — | 回执 JSON（四字段齐备，`result` 引用本文件实际结论） |

**脚本验证设计（对照派单「4 个 FX 节点 × desktop/mobile × 回读 4 属性、逐项 PASS/FAIL」）**：

| 校验组 | 项数 | 内容 |
|---|---|---|
| ① 场景结构 | 1 | `SceneState_nodes=5`、根 `HD2DFX(CanvasLayer, layer=10)`、4 个 FX 子节点名 / 顺序 / 数量 |
| ② 初始态（真跑实例化佐证） | 1 | 进树等待首帧后 4 节点默认 `desktop`：`visible/_all_on=true` / `fx_profile=desktop` / `texture_filter=Nearest` |
| ③ `desktop` 档逐项 | 16 | 4 节点 × (`visible` / `_all_on` / `fx_profile` / `texture_filter`) 各 1 项 |
| ④ `mobile` 档逐项 | 16 | 4 节点 × (`visible` / `_all_on` / `fx_profile` / `texture_filter`) 各 1 项 |
| **合计** | **34** | `pass=34 fail=0` |

- 切档方式：用脚本公共入口 `set_fx_profile(profile)`（内部 `_apply_profile()` 派生四项门 + `visible`），而非直接 `set("fx_profile", ...)`——后者只改字段、不会重算 `_all_on` / `visible`。
- 期望值：按冻结口径 `HD2D-FX-PLAN.md §4.2` 在脚本内**硬编码**（独立于被测 `_apply_profile()` 逻辑）：`desktop → (true, true, "desktop")` / `mobile → (false, false, "mobile")`；`texture_filter` 期望 `CanvasItem.TEXTURE_FILTER_NEAREST`（合法引擎枚举，未臆造常量）。
- 真跑成色：`root.add_child(inst)` 后 `await process_frame` 等待首帧；实证 `inst_inside_tree=true`、4 节点 `is_node_ready()=true`，即 `_ready()` 内 `_build_motes()` / `texture_filter=Nearest` / `set_fx_profile(fx_profile)` 真实执行，而非仅回读游离节点默认值。

> **可写范围核对**：本轮写入仅上述 3 处，均在派单授权范围内（`godot/scripts/verify_fx_profile.gd`、`Rank-4/`、回执例外 `command_center/ai/4/outbox/`）。
> **引擎自动缓存（非本工位手写源件，如实登记）**：`godot/scripts/verify_fx_profile.gd.uid`（20 B，mtime 09:37）由 `G1 --import` 引擎自动生成；`godot/.godot/` 下缓存 mtime 变化同理（与 `DONE-R16.md §1` / `DONE-R14.md §1` 既有登记一致）。未写 `courtyard.tscn` / 其它 `.tscn` / `.tres` / `.import` / `hd2d_fx.gd` / `hd2d_fx.tscn` / 其它工位 / 总线 / 总纲 / 契约 / 任务书。

---

## 2. 自检（② 含完整实际 stdout）

### 2.1 迭代过程如实登记（不伪造、不隐瞒首次结果）

- **首次 RUN**：脚本仅在 `_initialize()` 里 `root.add_child(inst)`，实际 stdout 为 `ADD_TO_TREE inst_inside_tree=false | FXReflection:ready=false | …`——因 `_initialize()` 阶段 `root` 尚未进树，`_ready()` 未触发，此时 `texture_filter=1` 来自 `.tscn` 序列化值而非 `_ready()` 设置。该版 34 项虽也全 PASS，但脚本注释「触发 `_ready()`」与实际不符。
- **修正**：在 `add_child()` 后加 `await process_frame` 等待首帧，并把注释改为诚实描述；**最终版**重跑实证 `inst_inside_tree=true`、四节点 `ready=true`，`ChunkManager` autoload 告警亦在首帧出现（佐证场景树 / 主循环真跑）。**下方 §2.2 贴出的完整 stdout 为最终版一次连跑的实际输出**，首次中间态不冒充交付结果。

### 2.2 完整实际 stdout（最终版一次连跑）

命令（Windows Git Bash，一次连跑；引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`）：

```text
GODOT="D:/Godot/Godot_v4.7.2-stable_win64.exe"; PROJ="F:/Game/aierdengfahuan/godot"; TS=".../godot/scenes/courtyard.tscn"; VF=".../godot/scripts/verify_fx_profile.gd"; echo "===== PRE courtyard.tscn sha256 ====="; sha256sum "$TS"; echo "===== G1 --import ====="; "$GODOT" --headless --path "$PROJ" --import 2>&1; echo "G1_EXIT=$?"; echo "===== RUN --script res://scripts/verify_fx_profile.gd ====="; "$GODOT" --headless --path "$PROJ" --script res://scripts/verify_fx_profile.gd 2>&1; echo "RUN_EXIT=$?"; echo "===== G2 --check-only --script res://scripts/verify_fx_profile.gd ====="; "$GODOT" --headless --path "$PROJ" --check-only --script res://scripts/verify_fx_profile.gd 2>&1; echo "G2_EXIT=$?"; echo "===== G3 --quit ====="; "$GODOT" --headless --path "$PROJ" --quit 2>&1; echo "G3_EXIT=$?"; echo "===== POST courtyard.tscn sha256 ====="; sha256sum "$TS"; echo "===== verify_fx_profile.gd 字节数 ====="; wc -c "$VF"; echo "===== verify_fx_profile.gd sha256 ====="; sha256sum "$VF"; echo "===== UTF-8 校验 ====="; python -c '...'; echo "===== .uid 引擎自动缓存（如实登记）====="; ls -la ".../verify_fx_profile.gd.uid"
```

以下为上述命令的**完整实际 stdout（Stderr: (empty)）**：

```text
===== PRE courtyard.tscn sha256 =====
306b2467ca0a6290639693b1c7e2b4b66f1b55dada2d05ad0bf8d08ff2300fe3 *F:/Game/aierdengfahuan/godot/scenes/courtyard.tscn
===== G1 --import =====
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

G1_EXIT=0
===== RUN --script res://scripts/verify_fx_profile.gd =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

==== [R17 verify_fx_profile] START ====
[R17] LOAD class=PackedScene resource_path=res://scenes/hd2d_fx.tscn SceneState_nodes=5
[R17] INSTANTIATE root=HD2DFX class=CanvasLayer layer=10 child_count=4 names=["FXReflection", "FXGodRays", "FXMotes", "FXBloom"] struct_ok=true
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
[R17] ADD_TO_TREE inst_inside_tree=true | FXReflection:ready=true | FXGodRays:ready=true | FXMotes:ready=true | FXBloom:ready=true
[R17][INIT][FXReflection] fx_profile=desktop visible=true _all_on=true texture_filter=1
[R17][INIT][FXGodRays] fx_profile=desktop visible=true _all_on=true texture_filter=1
[R17][INIT][FXMotes] fx_profile=desktop visible=true _all_on=true texture_filter=1
[R17][INIT][FXBloom] fx_profile=desktop visible=true _all_on=true texture_filter=1
[R17_CHK] ① scene_structure_5nodes_canvaslayer10_4fx PASS=true | SceneState_nodes=5 root=HD2DFX layer=10 children=["FXReflection", "FXGodRays", "FXMotes", "FXBloom"]
[R17_CHK] ② initial_desktop_all_on_after_ready PASS=true | 4 节点默认 desktop：visible/_all_on=true / fx_profile=desktop / texture_filter=Nearest（打印值见上）
---- [R17 档位回读] desktop START ----
[R17_CHK] [FXReflection][desktop] visible PASS=true | actual=true expected=true
[R17_CHK] [FXReflection][desktop] _all_on PASS=true | actual=true expected=true
[R17_CHK] [FXReflection][desktop] fx_profile PASS=true | actual=desktop expected=desktop
[R17_CHK] [FXReflection][desktop] texture_filter PASS=true | actual=1 expected=1(CanvasItem.TEXTURE_FILTER_NEAREST)
[R17_CHK] [FXGodRays][desktop] visible PASS=true | actual=true expected=true
[R17_CHK] [FXGodRays][desktop] _all_on PASS=true | actual=true expected=true
[R17_CHK] [FXGodRays][desktop] fx_profile PASS=true | actual=desktop expected=desktop
[R17_CHK] [FXGodRays][desktop] texture_filter PASS=true | actual=1 expected=1(CanvasItem.TEXTURE_FILTER_NEAREST)
[R17_CHK] [FXMotes][desktop] visible PASS=true | actual=true expected=true
[R17_CHK] [FXMotes][desktop] _all_on PASS=true | actual=true expected=true
[R17_CHK] [FXMotes][desktop] fx_profile PASS=true | actual=desktop expected=desktop
[R17_CHK] [FXMotes][desktop] texture_filter PASS=true | actual=1 expected=1(CanvasItem.TEXTURE_FILTER_NEAREST)
[R17_CHK] [FXBloom][desktop] visible PASS=true | actual=true expected=true
[R17_CHK] [FXBloom][desktop] _all_on PASS=true | actual=true expected=true
[R17_CHK] [FXBloom][desktop] fx_profile PASS=true | actual=desktop expected=desktop
[R17_CHK] [FXBloom][desktop] texture_filter PASS=true | actual=1 expected=1(CanvasItem.TEXTURE_FILTER_NEAREST)
---- [R17 档位回读] desktop END ----
---- [R17 档位回读] mobile START ----
[R17_CHK] [FXReflection][mobile] visible PASS=true | actual=false expected=false
[R17_CHK] [FXReflection][mobile] _all_on PASS=true | actual=false expected=false
[R17_CHK] [FXReflection][mobile] fx_profile PASS=true | actual=mobile expected=mobile
[R17_CHK] [FXReflection][mobile] texture_filter PASS=true | actual=1 expected=1(CanvasItem.TEXTURE_FILTER_NEAREST)
[R17_CHK] [FXGodRays][mobile] visible PASS=true | actual=false expected=false
[R17_CHK] [FXGodRays][mobile] _all_on PASS=true | actual=false expected=false
[R17_CHK] [FXGodRays][mobile] fx_profile PASS=true | actual=mobile expected=mobile
[R17_CHK] [FXGodRays][mobile] texture_filter PASS=true | actual=1 expected=1(CanvasItem.TEXTURE_FILTER_NEAREST)
[R17_CHK] [FXMotes][mobile] visible PASS=true | actual=false expected=false
[R17_CHK] [FXMotes][mobile] _all_on PASS=true | actual=false expected=false
[R17_CHK] [FXMotes][mobile] fx_profile PASS=true | actual=mobile expected=mobile
[R17_CHK] [FXMotes][mobile] texture_filter PASS=true | actual=1 expected=1(CanvasItem.TEXTURE_FILTER_NEAREST)
[R17_CHK] [FXBloom][mobile] visible PASS=true | actual=false expected=false
[R17_CHK] [FXBloom][mobile] _all_on PASS=true | actual=false expected=false
[R17_CHK] [FXBloom][mobile] fx_profile PASS=true | actual=mobile expected=mobile
[R17_CHK] [FXBloom][mobile] texture_filter PASS=true | actual=1 expected=1(CanvasItem.TEXTURE_FILTER_NEAREST)
---- [R17 档位回读] mobile END ----
==== [R17] SUMMARY pass=34 fail=0 total=34 ====
==== [R17] RESULT=PASS ====
==== [R17 verify_fx_profile] END ====
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
RUN_EXIT=0
===== G2 --check-only --script res://scripts/verify_fx_profile.gd =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

G2_EXIT=0
===== G3 --quit =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G3_EXIT=0
===== POST courtyard.tscn sha256 =====
306b2467ca0a6290639693b1c7e2b4b66f1b55dada2d05ad0bf8d08ff2300fe3 *F:/Game/aierdengfahuan/godot/scenes/courtyard.tscn
===== verify_fx_profile.gd 字节数 =====
6625 F:/Game/aierdengfahuan/godot/scripts/verify_fx_profile.gd
===== verify_fx_profile.gd sha256 =====
4f48d67ca92524b3cfcf1aac16d60b666ce495b284b01224580463eb77739734 *F:/Game/aierdengfahuan/godot/scripts/verify_fx_profile.gd
===== UTF-8 校验 =====
utf8_ok=True chars=5871 has_cjk=True
===== .uid 引擎自动缓存（如实登记）=====
-rw-r--r-- 1 admin 197121 20 Nov  9 09:37 F:/Game/aierdengfahuan/godot/scripts/verify_fx_profile.gd.uid
```

> 结论：34 项 `PASS=true`、`pass=34 fail=0`、`RESULT=PASS`；`RUN_EXIT=0`。`WARNING` 2 类（`ChunkManager` autoload `ChunkRoot` 缺失告警 + 退出时 `ObjectDB leaked` 2 实例）为**工程既有、非 ERROR、非本轮脚本引入**，与 `DONE-R16.md §2.1` / `DONE-R14.md §2.2` 同类登记一致，如实登记、不冒充「零 WARNING」。

### 2.3 三段门禁实际 EXIT（派单点名）

| 段 | 命令 | 实际 EXIT |
|---|---|---|
| PRE | `sha256sum godot/scenes/courtyard.tscn` | `306b2467…2300fe3`（前） |
| **G1** | `--headless --path … --import` | **`G1_EXIT=0`**（`first_scan_filesystem` / `loading_editor_layout` 两段 `[ DONE ]`） |
| RUN | `--headless --path … --script res://scripts/verify_fx_profile.gd` | `RUN_EXIT=0`（见 §2.2 完整 stdout） |
| **G2** | `--headless --path … --check-only --script res://scripts/verify_fx_profile.gd` | **`G2_EXIT=0`** |
| **G3** | `--headless --path … --quit` | **`G3_EXIT=0`** |
| POST | `sha256sum godot/scenes/courtyard.tscn` | `306b2467…2300fe3`（后） |

> 派单点名的三段 `--import` / `--check-only --script verify_fx_profile.gd` / `--quit` **全 `EXIT=0`**；另补 `RUN` 真跑亦 `EXIT=0`。全部输出内 `SCRIPT ERROR` / `Parse Error` / `ERROR` 均 0（仅 2 类既有 `WARNING`）。

### 2.4 档位验证结果矩阵（从 §2.2 stdout 逐项汇总）

| FX 节点 | desktop: visible / _all_on / fx_profile / texture_filter | mobile: visible / _all_on / fx_profile / texture_filter |
|---|---|---|
| FXReflection | `true / true / desktop / 1` ✅ | `false / false / mobile / 1` ✅ |
| FXGodRays | `true / true / desktop / 1` ✅ | `false / false / mobile / 1` ✅ |
| FXMotes | `true / true / desktop / 1` ✅ | `false / false / mobile / 1` ✅ |
| FXBloom | `true / true / desktop / 1` ✅ | `false / false / mobile / 1` ✅ |

> `texture_filter=1` 即 `CanvasItem.TEXTURE_FILTER_NEAREST`（Nearest，禁线性放大）；两档一致，符合 `_ready()` 内一次性设置 + `.tscn` 序列化 `texture_filter = 1` 的冻结口径。**逐项 `PASS=true` 明细见 §2.2 完整 stdout（共 32 行档位回读 + 2 行结构 / 初始态）。**

### 2.5 `courtyard.tscn` 零写入证据（sha256 前后逐字一致）

```text
===== PRE  ===== 306b2467ca0a6290639693b1c7e2b4b66f1b55dada2d05ad0bf8d08ff2300fe3
===== POST ===== 306b2467ca0a6290639693b1c7e2b4b66f1b55dada2d05ad0bf8d08ff2300fe3
```

> 本轮 `G1 --import` 只导入资源、不写 `.tscn`；`verify_fx_profile.gd` 只 `load()` `hd2d_fx.tscn` + `instantiate()` + `add_child()` 到内存场景树，从脚本层面**不加载 / 不修改 / 不保存** `courtyard.tscn`。**Rank-1 独占该文件，本工位零写入。**
> **时点差异如实登记（不伪造、不裁决）**：本轮读数 `306b2467…` 与 `DONE-R16.md §2.3`（`709f05bd…`）、`§6.2(e)`（`07766ced…`）登记值均不同。该文件由 Rank-1 独占、并发轮次持续推进，属**跨时点的并发改动差异**；本工位全程仅 `sha256sum` 只读，前后一致即证明本轮零写入，不对跨模块差异做裁决、不伪造任何哈希。

### 2.6 交付件字节数 / sha256 / UTF-8

```text
6625 F:/Game/aierdengfahuan/godot/scripts/verify_fx_profile.gd
4f48d67ca92524b3cfcf1aac16d60b666ce495b284b01224580463eb77739734 *F:/Game/aierdengfahuan/godot/scripts/verify_fx_profile.gd
utf8_ok=True chars=5871 has_cjk=True
```

> `verify_fx_profile.gd` 中文注释 UTF-8 合法（`has_cjk=True`）。本文件 `DONE-R17.md` 与回执 JSON 均为中文 UTF-8；文档内**不含行首 json 围栏**（回执是独立 `.json` 文件），沿用 `ART-SPEC-FINAL.md §5` / `DONE-R16.md §2.4` 一贯口径。

### 2.7 合规自检表

| 项 | 实际核对 | 结论 |
|---|---|---|
| 默认不刺探 | 只读必读 4 件 + 任务直接相关的 `build_hd2d_fx.gd` / `project.godot` / 本工位 `调度任务单-latest.json` / 工位与 outbox 目录；未做进度巡检、未写探针、未追加总线 | 通过 |
| 零付费 / 零外部素材 | 脚本只 `load()` 工程内 `.tscn` 与内置 GDScript 原语，无 PNG / Texture / 网络 / 云服务 / 付费 API | 通过 |
| 不碰 `courtyard.tscn` | sha256 PRE=POST 一致（§2.5）；脚本不加载 / 不修改 / 不保存该场景 | 通过 |
| 不伪造输出 | §2.1 如实登记首版 `ready=false` 与修正过程；§2.2 完整实际 stdout 逐字粘贴；`WARNING` / 哈希时点差异如实登记 | 通过 |
| 中文 UTF-8 | 交付脚本 `utf8_ok=True / has_cjk=True`（§2.6）、本文件与回执中文 UTF-8 | 通过 |
| Godot 4 合法语法 | `G2 --check-only EXIT=0`、`G1 --import` 无 Parse Error、`RUN EXIT=0`；期望值用 `CanvasItem.TEXTURE_FILTER_NEAREST` 引擎枚举，未臆造常量（沿用 `DONE-R14.md §2.1` 教训） | 通过 |
| 不自行 git | 未执行 `git commit` / `git push` / 任何写 git 操作 | 通过 |
| 总线开工只读一次 | 已读 `00-群聊总线.md` 一次，无接口变更 / 里程碑交付 / 阻塞求助 / @ 回应四类事件，未追加 | 通过 |
| 回执按 `task_id` 写 outbox | `cmd-20261109-093050-722-A4.json`（见 §4） | 通过 |

### 2.8 交付后最终只读复核（本段补记前采样，回执消费 / 零写入终态 / DONE 三段）

```text
outbox_exists = False
checked_path = F:/Game/aierdengfahuan/teamwork/command_center/dispatcher/receipts/cmd-20261109-093050-722-A4.json
receipt_bytes=1587 utf8_ok=True json_load_ok=True
task_id=cmd-20261109-093050-722-A4 match=True
ai=4 is4=True
status=done done=True
result_len=1077 refs_DONE_R17=True has_RESULT_PASS=True
DONE_utf8_ok=True chars=18778 has_cjk=True
  DONE_has[## 1.] = True
  DONE_has[## 2.] = True
  DONE_has[## 3.] = True
  DONE_has[完整实际 stdout] = True
  DONE_has[RESULT=PASS] = True
  DONE_has[pass=34 fail=0] = True
===== courtyard.tscn 终态 sha256 =====
306b2467ca0a6290639693b1c7e2b4b66f1b55dada2d05ad0bf8d08ff2300fe3 *F:/Game/aierdengfahuan/godot/scenes/courtyard.tscn
```

> 回执写入 outbox 后已被中枢**实时消费**移入 `dispatcher/receipts/`（与 `DONE-R16.md §2.5` 同一既有正常流程，`outbox_exists=False` **不是未写、不是失败**）：归档件即回执本体，`json.load` 通过、四字段齐备、`task_id` 正确、`ai=4` / `status=done`、`result` 引用 `DONE-R17.md` 且含 `RESULT=PASS`。`courtyard.tscn` 终态 sha256 与 §2.5 PRE/POST 逐字一致，零写入成立。本文件 `DONE-R17.md` 三段（①②③）齐备、中文 UTF-8、含完整实际 stdout 与 `RESULT=PASS` / `pass=34 fail=0`。`chars=18778` 为**本段补记前**的只读采样值，补记后文件增大不回改该读数（不伪造）。

---

## 3. 未完成项与阻塞（③）

> **最首要一条：独立场景仍未挂主场景。** 本轮按派单只做「档位回读验证」，**未把 `hd2d_fx.tscn` 挂进 `courtyard.tscn`**（Rank-1 独占、本工位零写入）；R17 由 Rank-1 挂进主场景。`status=done` 指「档位验证脚本交付 + 程序化自检闭环」，**不是**「已挂主场景 / 已验收画面」。

| # | 未完成项 / 阻塞 | 性质 | 说明 / 去向 |
|---|---|---|---|
| 1 | **独立场景未挂主场景** | 派单明确的本轮边界 | `hd2d_fx.tscn` 独立可挂载；本轮只做档位回读验证、未写 `courtyard.tscn`；R17 由 Rank-1 挂进主场景 SubViewport 的 `FXLayer(layer=10)` 一侧 |
| 2 | 未运行期抓帧 / 未验收画面 | 未验证 | 本轮自检是**实例化 + 档位派生属性**的程序化回读（34 项），未渲染抓帧、未验收四项可见性 / 暖金×冷雾对比 / 冷雾区不过阈；待挂载后由 Rank-1 抓帧复核 |
| 3 | 移动档「降级而非全关」未实现 | 待裁决建议（不擅改冻结值） | `HD2D-FX-PLAN.md §4.3` 的「体积光 2 层 / 光尘 16~24 粒 / bloom 3 层 / 倒影保持关」为待总指挥裁决建议；本轮按 §4.2 冻结口径验证 `mobile` 四项全关，未改任何 `.tres`（沿用 R15 / R16 登记） |
| 4 | 2 条 `WARNING`（RUN / G3） | 非阻塞（既有） | `ChunkManager` autoload `ChunkRoot` 缺失告警 + 退出时 `ObjectDB leaked`（2 实例），非 ERROR、非本轮脚本引入，与历轮 DONE 一致 |
| 5 | `courtyard.tscn` sha256 与 R16 登记值不同 | 并发时点差异（如实登记） | §2.5 已说明：Rank-1 独占、并发轮次改动，本工位只读、前后一致、不裁决 |
| 6 | 回执被中枢实时消费，outbox 不常驻 | 非阻塞（已送达） | 按 `DONE-R16.md §2.5` 既有流程：写入 outbox 后可能被中枢移入 `dispatcher/receipts/`；若需常驻副本由 HOST 决定 |
| 7 | 长期项 | 沿用既有登记 | `128bit` 歧义（`ART-SPEC-FINAL.md §6`）、ComfyUI 正式素材接入、后台出图 job 长期阻塞（`DONE-R16.md §6.3`：无 PNG、未拉第二个 GPU job）、性能预算未实测、静态层逐帧重绘 / Add 混合枚举未使用等；本轮零改动、不自行裁决 |

---

## 4. 合规声明 / 写入清单

- 本工位**写入**仅限：`godot/scripts/verify_fx_profile.gd`、`teamwork/Rank-4/DONE-R17.md`、回执例外 `teamwork/command_center/ai/4/outbox/cmd-20261109-093050-722-A4.json`。
- **未写**：`godot/scenes/courtyard.tscn`（Rank-1 独占，sha256 前后一致）、`godot/scripts/hd2d_fx.gd` / `godot/scripts/build_hd2d_fx.gd` / `godot/scenes/hd2d_fx.tscn`（只读引用）、任何 `.tres` / `.import` / 其它 `.gd` / 其它工位 / `00-群聊总线.md`（开工只读一次、未追加）/ 总纲 / 契约 / 任务书；未自行 `git commit` / `git push`。
- `verify_fx_profile.gd.uid`（20 B）为 `G1 --import` 引擎自动生成的缓存文件（§1 已如实登记），非本工位手写源件。
- 零付费 / 零外部生成服务 / 零外部素材增量 / 零插件；**ComfyUI 仍是主美术路线**；中文 UTF-8；不伪造输出 / 不臆造引擎常量 / 不夸大画面已达标 / 不宣称已实现 3D 后处理或真 bloom / 真体积光。

---

## 5. 结论

R17 主任务闭环：按派单写 `godot/scripts/verify_fx_profile.gd`（`extends SceneTree`），**真跑实例化** `hd2d_fx.tscn`（`CACHE_MODE_IGNORE` 加载 + `instantiate()` + 进树等待首帧触发 `_ready()`），用 `set_fx_profile()` 把 4 个 FX 节点分别切到 `desktop` / `mobile` 并逐项回读 `visible` / `_all_on` / `fx_profile` / `texture_filter`，**34 项全 `PASS=true`、`pass=34 fail=0`、`RESULT=PASS`**（`desktop` 四项全开 / `mobile` 四项全关 / 两档 `texture_filter=Nearest`）；三段门禁（`--import` / `--check-only --script verify_fx_profile.gd` / `--quit`）与 `RUN` 真跑实际 `EXIT` 全 0；`courtyard.tscn` 零写入（sha256 前后一致）；`DONE-R17.md` 三段齐备；回执按 `task_id` 写入 outbox、四字段齐备且 `result` 引用本文件实际结论。

> 证据：`godot/scripts/verify_fx_profile.gd`（6625 B / sha256 `4f48d67ca92524b3…` / UTF-8）、§2.2 完整实际 stdout、§2.3 门禁 EXIT 表、§2.5 零写入 sha256、回执 `cmd-20261109-093050-722-A4.json`。
> **明确边界：本轮为档位程序化验证，独立场景未挂主场景 / 未抓帧验收画面** —— R17 由 Rank-1 挂进 `courtyard.tscn`；本轮 `status=done` 不含「已挂主场景 / 已验收画面」，未完成项与阻塞见 §3。
