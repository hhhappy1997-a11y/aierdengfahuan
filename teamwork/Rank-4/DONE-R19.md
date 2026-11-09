# DONE-R19.md · 移动档降级实跑（verify_fx_mobile.gd）+ Movie Maker 抓帧

> 轮次：**R19**｜派单：`cmd-20261109-102334-091-A4`｜命令：`[ROUND=R19]`｜工位：**Rank-4 美术管线与工具链**｜日期：2026-11-09
> 定位：**验证件 + 抓帧件**。新建 `godot/scripts/verify_fx_mobile.gd`（`extends SceneTree`）真跑：4 个 FX 节点切 `mobile` 回读 `visible=false` / `_all_on=false` / `texture_filter=Nearest` + 四项绘制门全关；再切 `desktop` 做对比回读并打印两档实际值与差异表；三段门禁真跑；Movie Maker 抓帧 `--fixed-fps 30 --quit-after 4` 并如实说明「关掉四项光效后画面仍可读」及边界。
> 必读（已读）：`godot/scenes/hd2d_fx.tscn`、`godot/scripts/hd2d_fx.gd`、`Rank-4/HD2D-FX-PLAN.md`（移动档性能预算 §4）、`00-群聊总线.md`（**开工只读一次、未追加**）。
> 只读参考（均未改）：`godot/scenes/courtyard.tscn`（Rank-1 独占，仅只读核对 HD2DFX 默认档位/接线）、`godot/project.godot`、`Rank-1/FX-PROFILE-WIRING.md`、`godot/scripts/build_fx_r18_verify.gd` / `verify_fx_profile.gd` / `attach_fx_r17.gd` / `wire_profile_r18.gd`、`teamwork/Rank-4/DONE-R18.md`（成熟真跑口径）、`capture/r19_mobile00000000.png` / `r19_mobile00000002.png`（ViewImage 真实查看）。
> 合规：零付费 / 零外部素材 / 零插件 / 零云服务；**ComfyUI 仍是主美术路线**，本脚本是 2D 程序化零依赖兜底，不取代主路线；不碰 `courtyard.tscn`（Rank-1 独占，PRE/POST sha256 一致）；不自行 `git commit` / `git push`；中文 UTF-8；Godot 4.7.2 合法语法；不伪造输出 / 不冒充全绿 / 不臆造引擎常量。

---

## 0. 一句话结论

`verify_fx_mobile.gd` 真跑 **`RESULT=PASS` / `pass=47 fail=0`**：4 个 FX 节点（`FXReflection`/`FXGodRays`/`FXMotes`/`FXBloom`）切 `mobile` 后回读 `visible=false`、`_all_on=false`、`fx_profile=mobile`、`texture_filter=1(Nearest)`、四项绘制门 `_on_reflection/_on_godrays/_on_motes/_on_bloom` **全 false**；再切 `desktop` 对比回读 `visible=true` / `_all_on=true` / 四门 **全 true** / Nearest，两档实际值与差异表逐项打印。结构真跑核实 `hd2d_fx.tscn` 整树仅 `CanvasLayer(根)+4×Node2D`，是**纯叠加 FX 层、不含画面主体节点**。三段门禁 `G1 --import` / `G2 --check-only` / `G3 --quit` 与 `RUN` **EXIT 全 0**、`SCRIPT ERROR|Parse Error|ERROR` **0 条**；`courtyard.tscn` PRE/POST sha256 一致（**零写入**）。Movie Maker 抓帧 `--write-movie F:/Game/aierdengfahuan/capture/r19_mobile.png --fixed-fps 30 --quit-after 4` **EXIT=0**，产出 4 帧 1280×720 PNG。

**「移动档关掉四项光效后画面仍可读」——如实结论 + 诚实边界**：抓帧主场景 `courtyard.tscn` 的 `HD2DFX` 默认 `desktop`（四项全开，`courtyard.tscn:124-131` 的 6 项 `metadata` 接线仅为数据、`Rank-1/FX-PROFILE-WIRING.md §5` 明确「运行时自动切换逻辑未落盘实现」）；本轮受「**不碰 courtyard.tscn**」与可写范围（不含 `hd2d_fx.tscn`）约束，未改默认档 → **抓到的 4 帧严格说是「桌面档（四项光效开）」画面，并非「移动档（四项全关）」画面**。故本轮**未直接用 Movie Maker 抓到移动档画面**，此结论由三条真证据支撑，而非直接画面验收：① 真跑回读证明 `mobile` 四项门全关、`_draw()` 中 `if not _all_on: return` → 四项光效**确实不绘制任何像素**；② 结构真跑核实 `hd2d_fx.tscn` 是纯叠加 FX 层，主场景画面主体（3D 地形 `Terrain` / 角色 `Player` / HUD `Hud` / 背景 `HD2DPlaceholderLayer`）是 `courtyard.tscn` 中 HD2DFX 的**兄弟节点**，不依赖 FX 层；③ 真实查看抓帧画面：蓝天、左上角深蓝 HUD 面板「赐福·宁姆格福」文字、中央骑士像素剪影、大片暖金横砖地面纹理均**清晰可读**，Nearest 像素网格锐利、无泛白糊屏；四项光效只是低对比叠加氛围（天空零星光尘点、地平线附近淡金光斑、脚下数条细亮线、淡锥形光），移除后上述主体元素全部保留 → **移动档画面仍可读**。

**如实登记「看不清 / 偏弱」的地方**（属光效可见度弱，非画面主体不可读）：暖金体积光锥形叠在同色暖金地面上对比很弱、几乎难辨（沿用 `DONE-R18.md §3 #1`）；角色脚下倒影仅数条细亮线 + 少量深色块，非成片清晰镜像；天空光尘点很淡。详见 §3。

---

## 1. 交付清单（①）

| # | 文件 | 字节 | sha256（前缀） | 说明 |
|---|---|---|---|---|
| 1 | `godot/scripts/verify_fx_mobile.gd` | 12393 | `b5c0dda33edd895a…` | **新建**：`extends SceneTree` 真跑 + `CACHE_MODE_IGNORE` 回读（mobile 四项全关 / desktop 对比 / 差异表 / 纯叠加层结构 / 47 项 PASS-FAIL）；tab 缩进 / UTF-8 / Godot 4.7.2 合法 |
| 2 | `teamwork/Rank-4/DONE-R19.md` | 见文件 | 见文件 | 本文件（①交付清单 ②自检含完整实际 stdout ③未完成项与阻塞） |
| 3 | `teamwork/command_center/ai/4/outbox/cmd-20261109-102334-091-A4.json` → 中枢归档 `teamwork/command_center/dispatcher/receipts/cmd-20261109-102334-091-A4.json` | 1852（归档件） | — | 回执 JSON（四字段齐备，`result` 引用本文件实际结论）；写入 outbox 后被中枢**实时消费**归档，见 §2.7 |
| 4 | `capture/r19_mobile.png` | 120532 | — | Movie Maker **第 3 帧展示图**（由 `r19_mobile00000002.png` 真实复制，非伪造、非重新渲染；`--write-movie …/r19_mobile.png` 按 Godot 约定 `r19_mobile.png` 是路径前缀而非单文件） |
| 5 | `capture/r19_mobile00000000.png` … `r19_mobile00000003.png` | 4 帧（约 120.5 KB/帧） | — | `--write-movie …/r19_mobile.png` 真实产出的 **4 帧 PNG 序列**（1280×720） |
| 6 | `capture/r19_mobile.wav` | 51244 | — | Movie Maker 同时产出的音频流（引擎自动产物，非手写，如实登记） |
| 7 | `capture/r19_verify_run.log`、`r19_gate_import.log`、`r19_gate_checkonly.log`、`r19_gate_quit.log`、`r19_capture.log` | 9602 / 1087 / 75 / 208 / 881 | — | 真跑 / 三段门禁 / 抓帧的**实际 stdout** 日志 |

> **可写范围核对**：以上均在派单授权范围内（`godot/scripts/verify_fx_mobile.gd`、`Rank-4\`、`capture\`、回执例外 `command_center/ai/4/outbox/`）。
> **引擎自动缓存 / 产物（非手写源件，如实登记）**：`godot/scripts/verify_fx_mobile.gd.uid`（20 字节）由 `G1 --import` 引擎自动生成；`capture/r19_mobile.wav` 由 Movie Maker 自动产出；`godot/.godot/` 缓存 mtime 变化同理。
> **未写（零改动）**：`godot/scenes/courtyard.tscn`（Rank-1 独占，§2.6 PRE/POST sha256 一致）、`godot/scenes/hd2d_fx.tscn`（不在可写范围、零写入）、任何 `.tres` / `.import` / 其它 `.gd` / 其它工位 / `00-群聊总线.md` / 总纲 / 契约 / 任务书；未自行 git。

---

## 2. 自检（② 含完整实际 stdout）

### 2.1 真跑命令（Windows Git Bash，一次连跑；引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`）

```text
GODOT="D:/Godot/Godot_v4.7.2-stable_win64.exe"; PROJ="F:/Game/aierdengfahuan/godot"; CAP="F:/Game/aierdengfahuan/capture"
sha256sum "$PROJ/scenes/courtyard.tscn"                                                        # PRE
"$GODOT" --headless --path "$PROJ" --import                                                      # G1
"$GODOT" --headless --path "$PROJ" --script res://scripts/verify_fx_mobile.gd                    # RUN 真跑
"$GODOT" --headless --path "$PROJ" --check-only --script res://scripts/verify_fx_mobile.gd      # G2
"$GODOT" --headless --path "$PROJ" --quit                                                        # G3
sha256sum "$PROJ/scenes/courtyard.tscn"                                                        # POST
# 四段 stdout 分别重定向到 r19_gate_import.log / r19_verify_run.log / r19_gate_checkonly.log / r19_gate_quit.log
# 抓帧（独立 CLI）：
"$GODOT" --path "$PROJ" --write-movie F:/Game/aierdengfahuan/capture/r19_mobile.png \
  --fixed-fps 30 --quit-after 4 res://scenes/courtyard.tscn
```

> 三段门禁 = `G1 --import` / `G2 --check-only --script` / `G3 --quit`；`RUN --script` 为脚本主体的额外真跑。四段与抓帧均为**独立 CLI**，脚本内不嵌套启动第二个引擎进程（沿用 R18 口径）。

### 2.2 RUN 真跑完整实际 stdout（`r19_verify_run.log`，`RESULT=PASS` / `pass=47 fail=0`，`RUN_EXIT=0`）

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

==== [R19 verify_fx_mobile] START ====
[R19] cmd-20261109-102334-091-A4 [ROUND=R19] Rank-4 | extends SceneTree 真跑
[R19] LOAD class=PackedScene resource_path=res://scenes/hd2d_fx.tscn SceneState_nodes=5 CACHE_MODE_IGNORE=true
[R19_CHK] ① readback_PackedScene_not_null PASS=true | class=PackedScene resource_path=res://scenes/hd2d_fx.tscn
[R19_CHK] ② SceneState_node_count_5 PASS=true | nodes=5 expected=5
[R19] INSTANTIATE root=HD2DFX class=CanvasLayer layer=10 child_count=4 names=["FXReflection", "FXGodRays", "FXMotes", "FXBloom"] struct_ok=true
[R19_CHK] ③ scene_structure_CanvasLayer10_4FX_Node2D PASS=true | root=HD2DFX layer=10 names=["FXReflection", "FXGodRays", "FXMotes", "FXBloom"]
[R19_CHK] ④ script_attached_all_4 PASS=true | FXReflection:script=res://scripts/hd2d_fx.gd | FXGodRays:script=res://scripts/hd2d_fx.gd | FXMotes:script=res://scripts/hd2d_fx.gd | FXBloom:script=res://scripts/hd2d_fx.gd
[R19] STRUCTURE_TREE HD2DFX:CanvasLayer | FXReflection:Node2D | FXGodRays:Node2D | FXMotes:Node2D | FXBloom:Node2D
[R19_CHK] ⑤ pure_fx_overlay_layer_5nodes PASS=true | 整树 5 节点=CanvasLayer(根)+4×Node2D(FX)，无 3D/背景/角色/HUD 主体节点 → 画面主体不依赖 FX 层
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
[R19] ADD_TO_TREE inst_inside_tree=true | FXReflection:ready=true | FXGodRays:ready=true | FXMotes:ready=true | FXBloom:ready=true
[R19][INIT][FXReflection] fx_profile=desktop visible=true _all_on=true texture_filter=1
[R19][INIT][FXGodRays] fx_profile=desktop visible=true _all_on=true texture_filter=1
[R19][INIT][FXMotes] fx_profile=desktop visible=true _all_on=true texture_filter=1
[R19][INIT][FXBloom] fx_profile=desktop visible=true _all_on=true texture_filter=1
[R19_CHK] ⑥ initial_desktop_all_on_after_ready PASS=true | 4 节点默认 desktop：visible/_all_on=true / fx_profile=desktop / texture_filter=Nearest
---- [R19 档位回读] mobile START ----
[R19_READ][FXReflection][mobile] visible=false _all_on=false fx_profile=mobile texture_filter=1(Nearest=1) | _on_reflection=false _on_godrays=false _on_motes=false _on_bloom=false
[R19_CHK] [FXReflection][mobile] visible PASS=true | actual=false expected=false
[R19_CHK] [FXReflection][mobile] _all_on PASS=true | actual=false expected=false
[R19_CHK] [FXReflection][mobile] fx_profile PASS=true | actual=mobile expected=mobile
[R19_CHK] [FXReflection][mobile] texture_filter PASS=true | actual=1 expected=1(Nearest)
[R19_CHK] [FXReflection][mobile] four_draw_gates PASS=true | 四项绘制门实际=_on_reflection=false _on_godrays=false _on_motes=false _on_bloom=false expected=false（mobile 全 false / desktop 全 true）
[R19_READ][FXGodRays][mobile] visible=false _all_on=false fx_profile=mobile texture_filter=1(Nearest=1) | _on_reflection=false _on_godrays=false _on_motes=false _on_bloom=false
[R19_CHK] [FXGodRays][mobile] visible PASS=true | actual=false expected=false
[R19_CHK] [FXGodRays][mobile] _all_on PASS=true | actual=false expected=false
[R19_CHK] [FXGodRays][mobile] fx_profile PASS=true | actual=mobile expected=mobile
[R19_CHK] [FXGodRays][mobile] texture_filter PASS=true | actual=1 expected=1(Nearest)
[R19_CHK] [FXGodRays][mobile] four_draw_gates PASS=true | 四项绘制门实际=_on_reflection=false _on_godrays=false _on_motes=false _on_bloom=false expected=false（mobile 全 false / desktop 全 true）
[R19_READ][FXMotes][mobile] visible=false _all_on=false fx_profile=mobile texture_filter=1(Nearest=1) | _on_reflection=false _on_godrays=false _on_motes=false _on_bloom=false
[R19_CHK] [FXMotes][mobile] visible PASS=true | actual=false expected=false
[R19_CHK] [FXMotes][mobile] _all_on PASS=true | actual=false expected=false
[R19_CHK] [FXMotes][mobile] fx_profile PASS=true | actual=mobile expected=mobile
[R19_CHK] [FXMotes][mobile] texture_filter PASS=true | actual=1 expected=1(Nearest)
[R19_CHK] [FXMotes][mobile] four_draw_gates PASS=true | 四项绘制门实际=_on_reflection=false _on_godrays=false _on_motes=false _on_bloom=false expected=false（mobile 全 false / desktop 全 true）
[R19_READ][FXBloom][mobile] visible=false _all_on=false fx_profile=mobile texture_filter=1(Nearest=1) | _on_reflection=false _on_godrays=false _on_motes=false _on_bloom=false
[R19_CHK] [FXBloom][mobile] visible PASS=true | actual=false expected=false
[R19_CHK] [FXBloom][mobile] _all_on PASS=true | actual=false expected=false
[R19_CHK] [FXBloom][mobile] fx_profile PASS=true | actual=mobile expected=mobile
[R19_CHK] [FXBloom][mobile] texture_filter PASS=true | actual=1 expected=1(Nearest)
[R19_CHK] [FXBloom][mobile] four_draw_gates PASS=true | 四项绘制门实际=_on_reflection=false _on_godrays=false _on_motes=false _on_bloom=false expected=false（mobile 全 false / desktop 全 true）
---- [R19 档位回读] mobile END ----
---- [R19 档位回读] desktop START ----
[R19_READ][FXReflection][desktop] visible=true _all_on=true fx_profile=desktop texture_filter=1(Nearest=1) | _on_reflection=true _on_godrays=true _on_motes=true _on_bloom=true
[R19_CHK] [FXReflection][desktop] visible PASS=true | actual=true expected=true
[R19_CHK] [FXReflection][desktop] _all_on PASS=true | actual=true expected=true
[R19_CHK] [FXReflection][desktop] fx_profile PASS=true | actual=desktop expected=desktop
[R19_CHK] [FXReflection][desktop] texture_filter PASS=true | actual=1 expected=1(Nearest)
[R19_CHK] [FXReflection][desktop] four_draw_gates PASS=true | 四项绘制门实际=_on_reflection=true _on_godrays=true _on_motes=true _on_bloom=true expected=true（mobile 全 false / desktop 全 true）
[R19_READ][FXGodRays][desktop] visible=true _all_on=true fx_profile=desktop texture_filter=1(Nearest=1) | _on_reflection=true _on_godrays=true _on_motes=true _on_bloom=true
[R19_CHK] [FXGodRays][desktop] visible PASS=true | actual=true expected=true
[R19_CHK] [FXGodRays][desktop] _all_on PASS=true | actual=true expected=true
[R19_CHK] [FXGodRays][desktop] fx_profile PASS=true | actual=desktop expected=desktop
[R19_CHK] [FXGodRays][desktop] texture_filter PASS=true | actual=1 expected=1(Nearest)
[R19_CHK] [FXGodRays][desktop] four_draw_gates PASS=true | 四项绘制门实际=_on_reflection=true _on_godrays=true _on_motes=true _on_bloom=true expected=true（mobile 全 false / desktop 全 true）
[R19_READ][FXMotes][desktop] visible=true _all_on=true fx_profile=desktop texture_filter=1(Nearest=1) | _on_reflection=true _on_godrays=true _on_motes=true _on_bloom=true
[R19_CHK] [FXMotes][desktop] visible PASS=true | actual=true expected=true
[R19_CHK] [FXMotes][desktop] _all_on PASS=true | actual=true expected=true
[R19_CHK] [FXMotes][desktop] fx_profile PASS=true | actual=desktop expected=desktop
[R19_CHK] [FXMotes][desktop] texture_filter PASS=true | actual=1 expected=1(Nearest)
[R19_CHK] [FXMotes][desktop] four_draw_gates PASS=true | 四项绘制门实际=_on_reflection=true _on_godrays=true _on_motes=true _on_bloom=true expected=true（mobile 全 false / desktop 全 true）
[R19_READ][FXBloom][desktop] visible=true _all_on=true fx_profile=desktop texture_filter=1(Nearest=1) | _on_reflection=true _on_godrays=true _on_motes=true _on_bloom=true
[R19_CHK] [FXBloom][desktop] visible PASS=true | actual=true expected=true
[R19_CHK] [FXBloom][desktop] _all_on PASS=true | actual=true expected=true
[R19_CHK] [FXBloom][desktop] fx_profile PASS=true | actual=desktop expected=desktop
[R19_CHK] [FXBloom][desktop] texture_filter PASS=true | actual=1 expected=1(Nearest)
[R19_CHK] [FXBloom][desktop] four_draw_gates PASS=true | 四项绘制门实际=_on_reflection=true _on_godrays=true _on_motes=true _on_bloom=true expected=true（mobile 全 false / desktop 全 true）
---- [R19 档位回读] desktop END ----
---- [R19 desktop vs mobile 差异对照] START（均为运行期实际回读值）----
[R19_DIFF][FXReflection] desktop{visible=true _all_on=true fx_profile=desktop filter=1 gates=[true true true true]} | mobile{visible=false _all_on=false fx_profile=mobile filter=1 gates=[false false false false]}
[R19_DIFF][FXGodRays] desktop{visible=true _all_on=true fx_profile=desktop filter=1 gates=[true true true true]} | mobile{visible=false _all_on=false fx_profile=mobile filter=1 gates=[false false false false]}
[R19_DIFF][FXMotes] desktop{visible=true _all_on=true fx_profile=desktop filter=1 gates=[true true true true]} | mobile{visible=false _all_on=false fx_profile=mobile filter=1 gates=[false false false false]}
[R19_DIFF][FXBloom] desktop{visible=true _all_on=true fx_profile=desktop filter=1 gates=[true true true true]} | mobile{visible=false _all_on=false fx_profile=mobile filter=1 gates=[false false false false]}
[R19_CHK] ⑦ desktop_vs_mobile_diff_all_4 PASS=true | 4 节点两档实际值对照：desktop 四项全开(visible/_all_on/四门=true) / mobile 四项全关(全=false)，两档 texture_filter 均 Nearest
---- [R19 desktop vs mobile 差异对照] END ----
[R19] PROFILE_RESET 全部节点复位 desktop（仅内存态，未写盘；hd2d_fx.tscn / courtyard.tscn 均零写入）
==== [R19] SUMMARY pass=47 fail=0 total=47 ====
==== [R19] RESULT=PASS ====
==== [R19 verify_fx_mobile] END ====
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

> 47 项构成：结构/脚本/初始态 6 项（①~⑥）+ 档位 `4 节点 × 2 档 × 5 属性 = 40` 项 + 两档差异对照 1 项（⑦）= 47。`CACHE_MODE_IGNORE` 强制绕过缓存从磁盘重解析；`root.add_child()` + `await process_frame` 实证 `inst_inside_tree=true` 且四节点 `ready=true`（`_ready()` 真执行，非游离节点默认值）。`ChunkManager` 告警与 `2 ObjectDB instances were leaked` 均为既有 autoload / 退出期 WARNING，**非 SCRIPT ERROR / 非 ERROR**，R17/R18 已有，如实登记、不隐瞒。

### 2.3 三段门禁实际 stdout 与 EXIT（`r19_gate_*.log`）

```text
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
===== G2 --check-only --script res://scripts/verify_fx_mobile.gd =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

G2_EXIT=0
===== G3 --quit =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G3_EXIT=0
```

> 本轮 G1 无 `update_scripts_classes` 段（脚本全局类已在既有缓存注册），真实输出照贴，未臆造补齐。

门禁检索实际 stdout（对 4 段日志 `grep -nE "SCRIPT ERROR|Parse Error|ERROR"`）：

```text
--- r19_gate_import.log ---
No matches found (0 条)
--- r19_verify_run.log ---
No matches found (0 条)
--- r19_gate_checkonly.log ---
No matches found (0 条)
--- r19_gate_quit.log ---
No matches found (0 条)
```

**门禁汇总**：`G1_EXIT=0` / `RUN_EXIT=0` / `G2_EXIT=0` / `G3_EXIT=0`；`SCRIPT ERROR|Parse Error|ERROR` **0 条**。未冒充全绿：上述既有 WARNING 已如实登记。

### 2.4 Movie Maker 抓帧实际 stdout 与产物（`r19_capture.log`）

抓帧命令（绝对路径 + `.png` + `--fixed-fps 30 --quit-after 4`）：

```text
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/r19_mobile.png \
  --fixed-fps 30 --quit-after 4 res://scenes/courtyard.tscn
```

实际 stdout：

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 616.92 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Ti

Movie Maker mode enabled, recording movie in 1280×720 @ 30 FPS...
--------------------------------------------------------------------------------
Done recording movie at path: F:/Game/aierdengfahuan/capture/r19_mobile.png
4 frames at 30 FPS (movie length: 00:00:00:04), recorded in 00:00:01 (100% of real-time speed).
CPU render time: 0.00 seconds (average: 0.02 ms/frame)
GPU render time: 0.00 seconds (average: 0.00 ms/frame)
Encoding time: 0.13 seconds (average: 31.36 ms/frame)
--------------------------------------------------------------------------------
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
CAPTURE_EXIT=0
```

产物实际 stdout：

```text
-rw-r--r-- 1 admin 197121 120500 ... r19_mobile00000000.png
-rw-r--r-- 1 admin 197121 120475 ... r19_mobile00000001.png
-rw-r--r-- 1 admin 197121 120532 ... r19_mobile00000002.png
-rw-r--r-- 1 admin 197121 120538 ... r19_mobile00000003.png
```

`--write-movie …/r19_mobile.png` 按 Godot Movie Maker 约定产出**编号 PNG 序列**（4 帧 / 1280×720），`r19_mobile.png` 为路径前缀而非单文件；为让派单指定的文件名真实存在，把**第 3 帧 `r19_mobile00000002.png` 原样复制**为 `capture/r19_mobile.png`（真实帧、非伪造、非重新渲染，沿用 R18 §2.4 先例）。`r19_mobile.wav` 为 Movie Maker 自动产出的音频流。

### 2.5 画面核验（ViewImage 真实查看 `r19_mobile00000000.png` / `r19_mobile00000002.png`，逐项如实描述）

| 项 | 真实所见 |
|---|---|
| 整体色调 / 构图 | 1280×720；上方约 1/4 为纯净浅蓝天空，下方约 3/4 为大片暖金 / 米黄色横砖地面（带透视向地平线延伸），地平线约 y≈180–190 处有一条竖向砖纹/栅栏结构 |
| HUD 面板 | 左上角深蓝（近黑）面板 + 细金边，内为暖金中文「**赐福 · 宁姆格福**」，**文字清晰可辨**；面板干净、无点状遮挡 |
| 角色 | 画面中央偏下（约 x≈780,y≈400）有一名像素骑士剪影：蓝色头盔/盔甲、红色围巾、暖金色调，**轮廓清晰** |
| 地面砖纹 | 黄 / 橙 / 棕 / 白相间的横砖纹理，砖缝与像素块**锐利清晰**（Nearest 网格），无糊屏 |
| 四项光效 | 天空散布**零星暖金/白光尘小点**（较淡）；地平线附近（约 x≈900,y≈180）有**淡金 bloom 亮斑**与很淡的向下暖金锥形光（叠在同色地面上对比很弱、几乎难辨）；角色脚下有**数条细水平亮线 + 少量深色小块**（倒影），非成片镜像 |
| 可读性 | **无黑屏、无纯色空白、无大面积泛白/过曝、无整体糊屏**；主体（天空 / HUD 文字 / 角色 / 砖纹）全部清晰可读；首帧与第 3 帧一致，4 帧均可读 |

**「移动档关掉四项光效后画面仍可读」的论证（基于真实画面 + 真跑回读 + 结构，不伪造）**：四项光效在本画面里都是**低对比叠加氛围**（零星光尘点、淡金光斑、脚下细亮线、淡锥形光），画面主体全部由 `courtyard.tscn` 中 HD2DFX 的兄弟节点绘制（3D 地形 / 角色 / HUD / 背景层），与纯叠加 FX 层无关。`verify_fx_mobile.gd` 真跑证明切 `mobile` 后 4 节点 `visible=false`、`_all_on=false`、四项门全 false，`_draw()` 直接 `return` 不绘制任何像素 → 移动档只是**移除这层低对比叠加**，上述主体元素全部保留 → **画面仍可读**。

**诚实边界（重点，不谎报）**：`courtyard.tscn` 的 `HD2DFX` 默认 `fx_profile=desktop`（四项全开，`courtyard.tscn:124-131` 的 6 项 `metadata` 仅为接线数据；`Rank-1/FX-PROFILE-WIRING.md §5 #1/#6` 明确「运行时自动切换逻辑未落盘实现、未在运行期真跑切档」），且本轮受「不碰 `courtyard.tscn`」与可写范围（不含 `hd2d_fx.tscn`）约束未改默认档 → **抓帧 4 帧严格为桌面档画面，不是移动档画面**；本轮**未直接用 Movie Maker 抓到「移动档（四项全关）」画面**。上述「移动档仍可读」是基于桌面档真实画面 + 结构回读 + mobile 四项全关回读的推理，非移动档画面的直接验收，已按派单「或如实登记看不清的地方」的精神如实登记，见 §3 #1。

### 2.6 零写入 / 编码 / 字节核对（实际 stdout）

```text
===== PRE courtyard.tscn sha256 =====
461f19c74686acb9fd92aa4ed0aaa023d60fad604d874684634cecb64261f5fa *F:/Game/aierdengfahuan/godot/scenes/courtyard.tscn
===== POST courtyard.tscn sha256 =====
461f19c74686acb9fd92aa4ed0aaa023d60fad604d874684634cecb64261f5fa *F:/Game/aierdengfahuan/godot/scenes/courtyard.tscn
===== 文件字节数 =====
 12393 F:/Game/aierdengfahuan/godot/scripts/verify_fx_mobile.gd
120532 F:/Game/aierdengfahuan/capture/r19_mobile.png
===== 文件 sha256 =====
b5c0dda33edd895ae1ba5ec7aca02e2587f2adbc11e5d7e9365e3b256bed58b1 *F:/Game/aierdengfahuan/godot/scripts/verify_fx_mobile.gd
===== UTF-8 校验 =====
UTF8_OK: verify_fx_mobile.gd 合法 UTF-8
```

> `courtyard.tscn` PRE/POST sha256 逐字一致 → **本轮零写入**（Rank-1 独占未被触碰）。`hd2d_fx.tscn` 亦零写入（脚本 `PROFILE_RESET` 仅内存态复位 desktop，未 `pack` / 未 `save`）。

### 2.7 回执落地核验（实际 stdout）

回执按派单写入 `command_center/ai/4/outbox/cmd-20261109-102334-091-A4.json` 后，被中枢**实时消费**并从 outbox 移走（与 `DONE-R18.md §2.6`、`MSG-20261109-0916`「回执按各自 id 写入并被消费」「不重复写第二份回执」一致），归档于 `command_center/dispatcher/receipts/cmd-20261109-102334-091-A4.json`。**首次按 outbox 路径解析报 `FileNotFoundError: .../outbox/cmd-20261109-102334-091-A4.json`（真实发生，证明已被消费移走），改核验归档件**，不重写第二份回执。归档件解析与内容核验实际 stdout：

```text
=== 归档件路径确认 ===
-rw-r--r-- 1 admin 197121 1852 Nov  9 10:30 F:/Game/aierdengfahuan/teamwork/command_center/dispatcher/receipts/cmd-20261109-102334-091-A4.json
=== 归档回执 JSON 解析 + 四字段核验 ===
JSON_OK keys= ['ai', 'result', 'status', 'task_id']
  task_id= cmd-20261109-102334-091-A4
  ai= 4  status= done
  result 长度= 1080
  引用 DONE-R19.md= True
  含 RESULT=PASS= True
  含 pass=47 fail=0= True
  含移动档诚实边界= True
=== outbox 终态 ===
  (outbox 为空 → 已被中枢消费)
```

归档件 `result` 逐字引用本文件 §0 / §2 / §3 实际结论；四字段齐备、UTF-8 合法、JSON 可解析。

---

## 3. 未完成项与阻塞（③ 如实登记，不冒充全绿）

| # | 项 | 性质 / 归属 |
|---|---|---|
| 1 | **未直接抓到「移动档（四项全关）」画面** | 抓帧主场景 `courtyard.tscn` 的 HD2DFX 默认 `desktop` 四项全开、R18 接线仅 metadata 且运行时自动切档逻辑未落盘；本轮受「不碰 `courtyard.tscn`」与可写范围（不含 `hd2d_fx.tscn`）约束未改默认档。故 4 帧为桌面档画面；「移动档仍可读」由「mobile 回读四项全关不绘制 + 纯叠加层结构 + 桌面档真实画面主体清晰」三条真证据支撑，**非移动档画面直接验收**。要直接验收须 Rank-1 落盘运行时切档逻辑或总指挥授权改默认档，**超本轮范围 / 登记为待办，未擅自做** |
| 2 | 暖金体积光可见度弱 | 锥形光叠在同色暖金地面砖上、对比被削弱，画面中几乎难辨（沿用 `DONE-R18.md §3 #1`）；若要戏剧性加强需调地面色温或引入 `CanvasItemMaterial` Add 混合（枚举须 `ClassDB` 真跑核对，PLAN §3.6 已登记），待 Rank-1 裁决 |
| 3 | 倒影仍偏弱 | 角色脚下仅数条细亮线 + 少量深色块，非成片清晰镜像；2D/3D 遮挡固有限制（PLAN §6 #2）仍待 Rank-1 裁决 |
| 4 | 光尘点很淡 | 天空零星光尘小点较淡；属光效可见度偏弱，**不是画面主体不可读**；HUD 面板内已无点状遮挡（R18 避让生效） |
| 5 | 移动档「降级而非全关」 | PLAN §4.3 待裁决建议，本轮**保持冻结口径**（mobile 四项全关），未擅改 `render_profiles.tres` / `quality_preset_mobile.tres` |
| 6 | 静态层逐帧重绘未节流 | PLAN §4.4 给 Rank-1 的落地建议（体积光/bloom 仅档位变化时重绘、移动档节流），本轮沿用 `hd2d_fx.gd::_process()` 逐帧 `queue_redraw()` 口径，未擅改运行中脚本 |
| 7 | 画面验收范围 | 基于 Movie Maker 4 帧**静态真实像素查看**（首帧/第 3 帧）；未做逐帧动态验收 / 人工试玩 / 运行期帧时间实测（PLAN §4.1 基线不含 FX，不冒充本轮性能结果） |
| 8 | 长期阻塞（沿用既有登记） | ComfyUI 正式 spritesheet 接入、`128bit` 口径、apk 产物、运行期可见性人工验收仍未解决；**ComfyUI 仍是主美术路线**，本脚本是零外部依赖 2D 程序化兜底，不取代主路线、不宣称已能出图 / 已实现 3D 后处理 / 原生 HDR bloom |
| 9 | 合规边界 | 未写 `hd2d_fx.tscn` / `courtyard.tscn` / 其它工位 / 总线 / 总纲 / 契约；未自行 `git commit` / `git push`；零付费 / 零外部素材 / 零插件 / 零云服务；中文 UTF-8；Godot 4.7.2 合法语法 |

---

## 4. 合规声明

本轮**只写**派单授权范围内的 4 类产物：`godot/scripts/verify_fx_mobile.gd`（新建）、`teamwork/Rank-4/DONE-R19.md` 与回执例外 `teamwork/command_center/ai/4/outbox/cmd-20261109-102334-091-A4.json`（已被中枢消费归档）、`capture/` 下抓帧序列 / 展示图 / 实际 stdout 日志。**未写** `godot/scenes/courtyard.tscn`（Rank-1 独占，PRE/POST sha256 一致）、`godot/scenes/hd2d_fx.tscn`、任何 `.tres` / `.import` / 其它 `.gd` / 其它 Rank 工位 / `00-群聊总线.md`（开工只读一次、未追加）/ 总纲 / 契约 / 任务书；未自行 git。所有 stdout 均为 Godot 4.7.2 真跑 / grep / Python 解析的实际输出，未伪造、未臆造引擎常量、未冒充全绿（既有 WARNING 已登记）；画面描述基于 ViewImage 真实查看，未谎报抓到移动档画面。零付费 / 零外部生成服务 / 零外部素材增量 / 零插件；ComfyUI 仍是主美术路线。
