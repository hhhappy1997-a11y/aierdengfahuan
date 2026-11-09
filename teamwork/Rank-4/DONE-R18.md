# DONE-R18.md · hd2d_fx.gd 精修 + 真跑回读验证 + Movie Maker 抓帧

> 轮次：**R18**｜派单：`cmd-20261109-095518-176-A4`｜命令：`[ROUND=R18]`｜工位：**Rank-4 美术管线与工具链**｜日期：2026-11-09
> 定位：**精修件 + 验证件 + 抓帧件**。只改 `godot/scripts/hd2d_fx.gd`（独立脚本），新建 `godot/scripts/build_fx_r18_verify.gd`（`extends SceneTree`）真跑 + `CACHE_MODE_IGNORE` 回读节点/档位/参数，三段门禁真跑，Movie Maker 抓帧并写清 R17→R18 画面差异。
> 必读（已读）：`godot/scripts/hd2d_fx.gd`、`godot/scenes/hd2d_fx.tscn`、`Rank-4/HD2D-FX-PLAN.md`、`capture/r1700000003.png`（R17 画面，1280×720）、`00-群聊总线.md`（**开工只读一次、未追加**）。
> 只读参考（均未改）：`godot/scenes/courtyard.tscn`（仅只读核对坐标系 / 挂载，Rank-1 独占）、`godot/scripts/attach_fx_r17.gd`、`godot/scripts/build_hud.gd`、`godot/scripts/verify_fx_profile.gd`、`godot/scripts/build_hd2d_fx.gd`、`capture/r17_*.log`（三段门禁与抓帧口径）。
> 合规：零付费 / 零外部素材 / 零插件 / 零云服务；**ComfyUI 仍是主美术路线**，本脚本是 2D 程序化零依赖兜底，不取代主路线；不碰 `courtyard.tscn`（Rank-1 独占，sha256 前后一致）；不自行 `git commit` / `git push`；中文 UTF-8；Godot 4.7.2 合法语法；不伪造输出 / 不冒充全绿 / 不臆造引擎常量。

---

## 0. 一句话结论

R18 在 R16 独立场景 / R17 由 Rank-1 挂进主场景的基础上，**只精修 `hd2d_fx.gd`**：① 暖金体积光扇形 **4→6 层** + 中心「柔核+亮核」高光带，峰值 alpha 保持 `0.18` 不抬高（不糊画面）；② 倒影改为 **2×2 垂直镜像半透明色块**（压缩 `0.85` 向下延伸 + 深度渐隐 + 逐行波纹），不再是被地面横砖淹没成的一条水平亮线；③ 光尘**绘制时按 HUD 屏幕矩形（约 x<730、y<220）逐粒跳过**，`_is_hud_avoid()` 真跑 4 坐标命中；④ `fx_profile` desktop/mobile 档位开关与 `texture_filter=Nearest` 冻结口径零改动。`build_fx_r18_verify.gd` 真跑 **`RESULT=PASS` / `pass=47 fail=0`**，`CACHE_MODE_IGNORE` 回读节点/档位/参数全 PASS；三段门禁 `G1 --import` / `G2 --check-only` / `G3 --quit` **EXIT 全 0**、`SCRIPT ERROR|Parse Error|ERROR` **0 条**；`courtyard.tscn` sha256 前后一致（**零写入**）。Movie Maker 抓帧 `--fixed-fps 30 --quit-after 6` **EXIT=0**，产出 `r18_fx00000000..05.png`（第 3 帧另存 `r18_fx.png`），HUD 面板内光尘点 **R17 多个 → R18 归零**，画面未过曝、砖纹清晰。

---

## 1. 交付清单（①）

| # | 文件 | 字节 | sha256（前缀） | 说明 |
|---|---|---|---|---|
| 1 | `godot/scripts/hd2d_fx.gd` | 15130 | `9d8c380b0408388…` | **精修**：四项改动，见 §1.1；tab 缩进 / UTF-8 / Godot 4.7.2 合法 |
| 2 | `godot/scripts/build_fx_r18_verify.gd` | 11984 | `47c559ead2248f…` | **新建**：`extends SceneTree` 真跑 + `CACHE_MODE_IGNORE` 回读节点/档位/参数 + 47 项 PASS/FAIL |
| 3 | `teamwork/Rank-4/DONE-R18.md` | 见文件 | 见文件 | 本文件（①交付清单 ②自检含完整实际 stdout ③未完成项与阻塞） |
| 4 | `teamwork/command_center/ai/4/outbox/cmd-20261109-095518-176-A4.json` → 中枢归档 `teamwork/command_center/dispatcher/receipts/cmd-20261109-095518-176-A4.json` | 见回执 | — | 回执 JSON（四字段齐备，`result` 引用本文件实际结论）；已写入 outbox 并被中枢**实时消费**归档，见 §2.6 |
| 5 | `capture/r18_fx.png` | 120494 | — | Movie Maker 第 3 帧展示图（由 `r18_fx00000003.png` 真实复制，非伪造） |
| 6 | `capture/r18_fx00000000.png` … `r18_fx00000005.png` | 6 帧 | — | `--write-movie …/r18_fx.png` 按 Godot 约定产出的 **6 帧 PNG 序列**（1280×720） |
| 7 | `capture/r18_vs_r17.png` / `capture/r18_hud_vs_r17.png` | — | — | R17/R18 真实像素对比留痕（左R17右R18全图 / 上R17下R18 HUD 区） |
| 8 | `capture/r18_verify_run.log`、`r18_gate_import.log`、`r18_gate_checkonly.log`、`r18_gate_quit.log`、`r18_capture.log` | — | — | 真跑 / 三段门禁 / 抓帧的 `tee` 实际 stdout 日志 |

> **可写范围核对**：以上均在派单授权范围内（`godot/scripts/hd2d_fx.gd`、`godot/scripts/build_fx_r18_verify.gd`、`Rank-4\`、`capture\`、回执例外 `command_center/ai/4/outbox/`）。
> **引擎自动缓存（非手写源件，如实登记）**：`build_fx_r18_verify.gd.uid` 由 `G1 --import` 引擎自动生成，`godot/.godot/` 缓存 mtime 变化同理。
> **未写（零改动）**：`godot/scenes/courtyard.tscn`（Rank-1 独占，§2.5 sha256 前后一致）、`godot/scenes/hd2d_fx.tscn`、任何 `.tres` / `.import` / 其它 `.gd` / 其它工位 / `00-群聊总线.md` / 总纲 / 契约 / 任务书；未自行 git。

### 1.1 四项精修逐条（`hd2d_fx.gd`，均落在 `_draw()` 内、零外部素材）

| 项 | R17（基线） | R18（本轮） | 关键参数（运行期可 `get()` 回读） |
|---|---|---|---|
| ① 暖金体积光扇形 | `draw_colored_polygon` ×4，alpha `[0.18,0.12,0.07,0.04]`，spread `40+i*46`，单条中心高光 alpha 0.10 | **×6 层**（径向衰减更细腻）+ **两道中心高光**（柔核 `#FFD27A`/0.16/宽3 + 亮核 `#FFF0C2`/0.12/宽1）；**峰值 alpha 仍 `0.18` 不抬高**（不糊画面），总叠加约 0.41→0.56 | `godray_layers=6`、`godray_alpha=[0.18,0.14,0.1,0.07,0.045,0.025]`、`godray_spread_base=40`、`godray_spread_step=30` |
| ② 湿地倒影 | 逐块 `draw_rect` 1×1、alpha 0.35、压缩 0.70、逐行波纹，被暖金横砖淹没成「一条水平亮线」 | **垂直镜像近似**：2×2 半透明色块连成向下翻转的镜像轮廓 + 压缩 `0.85` 向下延伸 + **深度渐隐**（离脚底越远越淡）+ 逐行波纹 + 2 条极淡水纹线（仅质感） | `reflection_squash=0.85`、`reflection_alpha=0.42`、`reflection_fade=0.55`、`reflection_block_px=2.0`、`reflection_ripple=0.035` |
| ③ 光尘避开 HUD | 无避让；HD2DFX 与 Hud 同 `layer=10`、树序靠后，光尘画在 HUD 之上，面板内可见点状遮挡 | `_draw_motes()` **绘制时逐粒**调用 `_is_hud_avoid(x,y)`，命中屏幕矩形 `x<730 && y<220` 即 `continue` 跳过；生成逻辑 / seed / 数量不变，只在绘制层过滤（上飘过程中也实时避让） | `hud_avoid_screen_w=730`、`hud_avoid_screen_h=220`、`logical_to_screen=2`；`_is_hud_avoid()` 逻辑 `x*2<730 && y*2<220` |
| ④ 档位 / Nearest | `fx_profile` desktop 全开 / mobile 全关；`texture_filter=Nearest` | **零改动**（`_apply_profile()` / `_ready()` 原样保留） | `fx_profile=desktop`、`texture_filter=1(Nearest)` 两档均回读命中 |

**坐标系说明（避免臆造）**：`courtyard.tscn` 只读核对得 `SubViewport size=640×360` + `SubViewportContainer stretch=true / stretch_shrink=2` → 逻辑缓冲 ×2 放大到 Movie Maker 的 `1280×720`；FX 与 Hud 同处该 SubViewport 的逻辑坐标系。HUD 面板（`hud.tscn` Panel `(24,24)` size `(340,84)`）屏幕矩形约 `[48,728]×[48,216]`，与派单「约 x<730、y<220」一致，故 `logical_to_screen=2` 换算后判定。

**参数偏离冻结值的如实登记**：倒影 `alpha 0.35→0.42`、压缩 `0.70→0.85` 偏离 `HD2D-FX-PLAN.md §3.3` 冻结值，属派单第 2 条「倒影改为垂直镜像近似、不再只是一条水平亮线」的精修增强；已在 §3 登记，未改任何 `.tres`，待 Rank-1 / 总指挥复核。

---

## 2. 自检（② 含完整实际 stdout）

### 2.1 真跑命令（Windows Git Bash，一次连跑；引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`）

```text
GODOT="D:/Godot/Godot_v4.7.2-stable_win64.exe"; PROJ="F:/Game/aierdengfahuan/godot"; CAP="F:/Game/aierdengfahuan/capture"
sha256sum "$PROJ/scenes/courtyard.tscn"                                             # PRE
"$GODOT" --headless --path "$PROJ" --import                                         # G1
"$GODOT" --headless --path "$PROJ" --script res://scripts/build_fx_r18_verify.gd    # RUN 真跑
"$GODOT" --headless --path "$PROJ" --check-only --script res://scripts/build_fx_r18_verify.gd   # G2
"$GODOT" --headless --path "$PROJ" --quit                                           # G3
sha256sum "$PROJ/scenes/courtyard.tscn"                                             # POST
# 四段 stdout 分别 tee 到 r18_gate_import.log / r18_verify_run.log / r18_gate_checkonly.log / r18_gate_quit.log
# 抓帧（独立 CLI）：
"$GODOT" --path "$PROJ" --write-movie F:/Game/aierdengfahuan/capture/r18_fx.png --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn
```

### 2.2 RUN 真跑完整实际 stdout（`r18_verify_run.log`，`RESULT=PASS` / `pass=47 fail=0`）

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

==== [R18 build_fx_r18_verify] START ====
[R18] cmd-20261109-095518-176-A4 [ROUND=R18] Rank-4 | extends SceneTree 真跑
[R18] LOAD class=PackedScene resource_path=res://scenes/hd2d_fx.tscn SceneState_nodes=5 CACHE_MODE_IGNORE=true
[R18_CHK] ① readback_PackedScene_not_null PASS=true | class=PackedScene resource_path=res://scenes/hd2d_fx.tscn
[R18_CHK] ② SceneState_node_count_5 PASS=true | nodes=5 expected=5
[R18] INSTANTIATE root=HD2DFX class=CanvasLayer layer=10 child_count=4 names=["FXReflection", "FXGodRays", "FXMotes", "FXBloom"] struct_ok=true
[R18_CHK] ③ scene_structure_CanvasLayer10_4FX_Node2D PASS=true | root=HD2DFX layer=10 names=["FXReflection", "FXGodRays", "FXMotes", "FXBloom"]
[R18_CHK] ④ script_attached_all_4 PASS=true | FXReflection:script=res://scripts/hd2d_fx.gd | FXGodRays:script=res://scripts/hd2d_fx.gd | FXMotes:script=res://scripts/hd2d_fx.gd | FXBloom:script=res://scripts/hd2d_fx.gd
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
[R18] ADD_TO_TREE inst_inside_tree=true | FXReflection:ready=true | FXGodRays:ready=true | FXMotes:ready=true | FXBloom:ready=true
---- [R18 档位回读] desktop START ----
[R18_CHK] [FXReflection][desktop] visible PASS=true | actual=true expected=true
[R18_CHK] [FXReflection][desktop] _all_on PASS=true | actual=true expected=true
[R18_CHK] [FXReflection][desktop] fx_profile PASS=true | actual=desktop expected=desktop
[R18_CHK] [FXReflection][desktop] texture_filter PASS=true | actual=1 expected=1(Nearest)
[R18_CHK] [FXGodRays][desktop] visible PASS=true | actual=true expected=true
[R18_CHK] [FXGodRays][desktop] _all_on PASS=true | actual=true expected=true
[R18_CHK] [FXGodRays][desktop] fx_profile PASS=true | actual=desktop expected=desktop
[R18_CHK] [FXGodRays][desktop] texture_filter PASS=true | actual=1 expected=1(Nearest)
[R18_CHK] [FXMotes][desktop] visible PASS=true | actual=true expected=true
[R18_CHK] [FXMotes][desktop] _all_on PASS=true | actual=true expected=true
[R18_CHK] [FXMotes][desktop] fx_profile PASS=true | actual=desktop expected=desktop
[R18_CHK] [FXMotes][desktop] texture_filter PASS=true | actual=1 expected=1(Nearest)
[R18_CHK] [FXBloom][desktop] visible PASS=true | actual=true expected=true
[R18_CHK] [FXBloom][desktop] _all_on PASS=true | actual=true expected=true
[R18_CHK] [FXBloom][desktop] fx_profile PASS=true | actual=desktop expected=desktop
[R18_CHK] [FXBloom][desktop] texture_filter PASS=true | actual=1 expected=1(Nearest)
---- [R18 档位回读] desktop END ----
---- [R18 档位回读] mobile START ----
[R18_CHK] [FXReflection][mobile] visible PASS=true | actual=false expected=false
[R18_CHK] [FXReflection][mobile] _all_on PASS=true | actual=false expected=false
[R18_CHK] [FXReflection][mobile] fx_profile PASS=true | actual=mobile expected=mobile
[R18_CHK] [FXReflection][mobile] texture_filter PASS=true | actual=1 expected=1(Nearest)
[R18_CHK] [FXGodRays][mobile] visible PASS=true | actual=false expected=false
[R18_CHK] [FXGodRays][mobile] _all_on PASS=true | actual=false expected=false
[R18_CHK] [FXGodRays][mobile] fx_profile PASS=true | actual=mobile expected=mobile
[R18_CHK] [FXGodRays][mobile] texture_filter PASS=true | actual=1 expected=1(Nearest)
[R18_CHK] [FXMotes][mobile] visible PASS=true | actual=false expected=false
[R18_CHK] [FXMotes][mobile] _all_on PASS=true | actual=false expected=false
[R18_CHK] [FXMotes][mobile] fx_profile PASS=true | actual=mobile expected=mobile
[R18_CHK] [FXMotes][mobile] texture_filter PASS=true | actual=1 expected=1(Nearest)
[R18_CHK] [FXBloom][mobile] visible PASS=true | actual=false expected=false
[R18_CHK] [FXBloom][mobile] _all_on PASS=true | actual=false expected=false
[R18_CHK] [FXBloom][mobile] fx_profile PASS=true | actual=mobile expected=mobile
[R18_CHK] [FXBloom][mobile] texture_filter PASS=true | actual=1 expected=1(Nearest)
---- [R18 档位回读] mobile END ----
[R18] PROFILE_RESET 全部节点复位 desktop（仅内存态，未写盘）
---- [R18 参数回读] START（4 节点同挂一份脚本，逐节点打印概览 + 代表节点逐项断言）----
[R18_PARAM] 概览 FXReflection | godray_layers=6 reflection_alpha=0.42 hud_w=730 motes_far=48 motes_near=32
[R18_PARAM] 概览 FXGodRays | godray_layers=6 reflection_alpha=0.42 hud_w=730 motes_far=48 motes_near=32
[R18_PARAM] 概览 FXMotes | godray_layers=6 reflection_alpha=0.42 hud_w=730 motes_far=48 motes_near=32
[R18_PARAM] 概览 FXBloom | godray_layers=6 reflection_alpha=0.42 hud_w=730 motes_far=48 motes_near=32
[R18_CHK] ⑤ params_consistent_across_4_nodes PASS=true | 4 节点 godray_layers/reflection_alpha/hud_w/motes 数量逐项一致且命中期望
[R18_PARAM] 代表节点 FXMotes | godray_layers=6 godray_alpha=[0.18, 0.14, 0.1, 0.07, 0.045, 0.025] peak=0.180 spread=(40.0,30.0)
[R18_PARAM] 代表节点 FXMotes | reflection squash=0.85 alpha=0.42 fade=0.55 block_px=2.0 ripple=0.035
[R18_PARAM] 代表节点 FXMotes | hud_avoid=(730,220) logical_to_screen=2.0
[R18_CHK] ⑥ godray_layers_6 PASS=true | actual=6 expected=6（4→6 层，加强暖金扇形）
[R18_CHK] ⑦ godray_alpha_size6_peak_0.18 PASS=true | size=6 peak=0.180 expected_size=6 peak=0.18（峰值不抬高、不糊画面）
[R18_CHK] ⑧ godray_spread PASS=true | base=40.0 step=30.0
[R18_CHK] ⑨ reflection_vertical_mirror_params PASS=true | squash=0.85 alpha=0.42 fade=0.55 block=2.0 ripple=0.035（2×2 镜像色块+深度渐隐）
[R18_CHK] ⑩ hud_avoid_rect PASS=true | screen=(730,220) scale=2.0（约 x<730,y<220）
[R18_CHK] ⑪ motes_deterministic_counts PASS=true | texture_filter=1(Nearest) + 光尘 far=48/near=32 seed=20261108 固定（见概览）
---- [R18 参数回读] _is_hud_avoid 真跑 ----
[R18_PARAM] _is_hud_avoid(100,50) -> true | HUD 区内(左上) → 应避开
[R18_CHK] ⑫ HUD_avoid_call(100,50) PASS=true | actual=true expected=true | HUD 区内(左上) → 应避开
[R18_PARAM] _is_hud_avoid(500,50) -> false | HUD 右侧外(x*2=1000>730) → 应绘制
[R18_CHK] ⑫ HUD_avoid_call(500,50) PASS=true | actual=false expected=false | HUD 右侧外(x*2=1000>730) → 应绘制
[R18_PARAM] _is_hud_avoid(100,200) -> false | HUD 下方(y*2=400>220) → 应绘制
[R18_CHK] ⑫ HUD_avoid_call(100,200) PASS=true | actual=false expected=false | HUD 下方(y*2=400>220) → 应绘制
[R18_PARAM] _is_hud_avoid(600,300) -> false | 右下远景 → 应绘制
[R18_CHK] ⑫ HUD_avoid_call(600,300) PASS=true | actual=false expected=false | 右下远景 → 应绘制
---- [R18 参数回读] END ----
==== [R18] SUMMARY pass=47 fail=0 total=47 ====
==== [R18] RESULT=PASS ====
==== [R18 build_fx_r18_verify] END ====
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
RUN_EXIT=0
```

> 47 项构成：结构/脚本 4 项 + 档位 `4 节点 × 2 档 × 4 属性 = 32` 项 + 参数一致性/逐项 6 项 + Nearest/光尘 1 项 + `_is_hud_avoid()` 真跑 4 项 = 47。`CACHE_MODE_IGNORE` 强制绕过缓存从磁盘重解析；`root.add_child()` + `await process_frame` 实证 `inst_inside_tree=true` 且四节点 `ready=true`（`_ready()` 真执行，非游离节点默认值）。`ChunkManager` 告警与 `2 ObjectDB instances were leaked` 均为既有 autoload / 退出期 WARNING，**非 SCRIPT ERROR / 非 ERROR**，R17 已有，如实登记、不隐瞒。

### 2.3 三段门禁实际 stdout 与 EXIT（`r18_gate_*.log`）

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

[   0% ] update_scripts_classes | Started 正在注册全局类…… (2 steps)
[   0% ] update_scripts_classes |
[  33% ] update_scripts_classes |
[ DONE ] update_scripts_classes

[   0% ] loading_editor_layout | Started 正在加载编辑器 (5 steps)
[   0% ] loading_editor_layout | 正在加载编辑器布局……
[  16% ] loading_editor_layout | 正在加载停靠面板……
[ DONE ] loading_editor_layout

G1_EXIT=0
===== G2 --check-only --script res://scripts/build_fx_r18_verify.gd =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

G2_EXIT=0
===== G3 --quit =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G3_EXIT=0
```

**门禁汇总**：`G1_EXIT=0` / `RUN_EXIT=0` / `G2_EXIT=0` / `G3_EXIT=0`；对 `r18_gate_import.log`、`r18_verify_run.log`、`r18_gate_checkonly.log`、`r18_gate_quit.log` 以 `SCRIPT ERROR|Parse Error|ERROR` 检索 → **`No matches found`（0 条）**。未冒充全绿：上述 WARNING 已如实登记。

### 2.4 Movie Maker 抓帧实际 stdout 与 R17→R18 画面差异

抓帧命令（绝对路径 + `.png` + `--fixed-fps 30 --quit-after 6`）：

```text
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/r18_fx.png \
  --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn
```

实际 stdout（`r18_capture.log`）：

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 616.92 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Ti

Movie Maker mode enabled, recording movie in 1280×720 @ 30 FPS...
--------------------------------------------------------------------------------
Done recording movie at path: F:/Game/aierdengfahuan/capture/r18_fx.png
6 frames at 30 FPS (movie length: 00:00:00:06), recorded in 00:00:01 (100% of real-time speed).
CPU render time: 0.00 seconds (average: 0.01 ms/frame)
GPU render time: 0.00 seconds (average: 0.00 ms/frame)
Encoding time: 0.18 seconds (average: 29.89 ms/frame)
--------------------------------------------------------------------------------
CAPTURE_EXIT=0
```

产物：`r18_fx00000000.png` … `r18_fx00000005.png`（6 帧，1280×720，单帧约 120 KB）——`--write-movie …/r18_fx.png` 按 Godot Movie Maker 约定产出**编号 PNG 序列**，`r18_fx.png` 为路径前缀而非单文件；为让派单指定的文件名真实存在，另把**第 3 帧 `r18_fx00000003.png` 原样复制**为 `capture/r18_fx.png`（真实帧、非伪造、非重新渲染）。对比基准取同序号的 R17 第 3 帧 `capture/r1700000003.png`（必读件）。留痕：`r18_vs_r17.png`（左 R17 / 右 R18 全图）、`r18_hud_vs_r17.png`（上 R17 / 下 R18 HUD 区 730×220）。

**R17 → R18 画面差异（基于两帧真实像素对比，逐项写清）**：

| 项 | R17（`r1700000003.png`） | R18（`r18_fx00000003.png` = `r18_fx.png`） | 结论 |
|---|---|---|---|
| ① 暖金体积光扇形 | 光源（屏幕约 `x=904,y=184`）处仅一个暖金 bloom 亮斑，向下扇形很淡、几乎与暖金地面融为一体 | 同位置暖金锥形更连续可辨，中心多出一道**竖直亮柱**（柔核+亮核两道高光），扇形层数由 4 增至 6、梯度更顺 | **加强生效**；峰值 alpha 保持 `0.18`，**画面未过曝、未糊**，地面砖纹与角色剪影清晰。如实说明：地面本身是暖金砖同色系，扇形可见度提升幅度有限，不是戏剧性变亮 |
| ② 角色脚下倒影 | 骑士脚下仅见**数条细小水平亮线/横线**，无成片镜像 | 脚下出现**向下翻转的深色/蓝灰半透明镜像色块**（2×2 块连成轮廓）+ 逐行波纹 + 深度渐隐，向下方扩散成一片块状倒影 | **由「一条水平亮线」变为「垂直镜像色块」**，形态差异最明显；仍为半透明、未盖住角色 |
| ③ HUD 面板光尘 | 深蓝「赐福·宁姆格福」面板内可见**多个浅色光尘小点（约 5~7 个）**遮挡文字区 | 深蓝面板内 **0 个光尘点**，面板干净、文字清晰；面板**外**（右侧天空、地面）光尘小点仍在 | **HUD 避让生效**；光尘 seed / 数量（48+32）不变，仅绘制时按 `x<730,y<220` 逐粒跳过，未整体删减光尘 |
| ④ 整体色调 / 清晰度 | 1280×720，暖金地面 + 蓝色天空，Nearest 像素网格清晰 | 同构图、同色调，砖纹 / 角色 / HUD 边框均清晰，**无泛白糊屏** | 「加强但不糊画面」达成；`texture_filter=Nearest` 保持 |

### 2.5 零写入 / 编码 / 字节核对（实际 stdout）

```text
===== PRE courtyard.tscn sha256 =====
461f19c74686acb9fd92aa4ed0aaa023d60fad604d874684634cecb64261f5fa *F:/Game/aierdengfahuan/godot/scenes/courtyard.tscn
===== POST courtyard.tscn sha256 =====
461f19c74686acb9fd92aa4ed0aaa023d60fad604d874684634cecb64261f5fa *F:/Game/aierdengfahuan/godot/scenes/courtyard.tscn
===== 文件字节数 =====
15130 F:/Game/aierdengfahuan/godot/scripts/hd2d_fx.gd
11984 F:/Game/aierdengfahuan/godot/scripts/build_fx_r18_verify.gd
===== 文件 sha256 =====
9d8c380b040838861475f1e9cc742c4c40e449ff2eff4c5baf9d6d193c647163 *F:/Game/aierdengfahuan/godot/scripts/hd2d_fx.gd
47c559ead2248f774a118252a12c4aa2192a41eb04636560f082a56fcc01b2f4 *F:/Game/aierdengfahuan/godot/scripts/build_fx_r18_verify.gd
===== UTF-8 校验 =====
UTF8_OK: 两个 .gd 均为合法 UTF-8
```

> `courtyard.tscn` PRE/POST sha256 逐字一致 → **本轮零写入**（Rank-1 独占未被触碰）。注：该值与 `DONE-R17.md` 记录的 `306b2467…` 不同，说明 R17 之后主场景已被其它轮次 / 并发实例更新过；本轮只做 PRE/POST 自比对，不冒充「与 R17 相同」，如实登记。

### 2.6 回执落地核验（实际 stdout）

回执按派单写入 `command_center/ai/4/outbox/cmd-20261109-095518-176-A4.json` 后，被中枢**实时消费**并从 outbox 移走（与 `DONE-R17.md §3`、`00-群聊总线.md MSG-20261109-0916`「回执按各自 id 写入并被消费」「不重复写第二份回执」一致），归档于 `command_center/dispatcher/receipts/cmd-20261109-095518-176-A4.json`。故 outbox 终态为空、receipts 有该文件，**不重写第二份回执**（避免中枢重复消费）。归档件解析与内容核验实际 stdout：

```text
归档回执 JSON 解析 OK | keys= ['ai', 'result', 'status', 'task_id']
  task_id= cmd-20261109-095518-176-A4  ai= 4  status= done
  result 长度= 977 | 引用 DONE-R18.md= True | 含 RESULT=PASS= True
```

归档件 `result` 全文逐字引用本文件 §0 / §2 / §3 实际结论；四字段齐备、UTF-8 合法、JSON 可解析。

---

## 3. 未完成项与阻塞（③ 如实登记，不冒充全绿）

| # | 项 | 性质 / 归属 |
|---|---|---|
| 1 | 体积光「加强」的视觉幅度有限 | 暖金扇形叠在暖金地面砖上属同色系，对比被削弱；本轮以「加层数 + 中心高光、峰值 alpha 不抬高」达成「加强但不糊」。若要戏剧性加强需调整地面色温或引入 `CanvasItemMaterial` Add 混合（枚举须 `ClassDB` 真跑核对，PLAN §3.6 已登记），**超本轮范围 / 待 Rank-1 裁决**，未擅自做 |
| 2 | 倒影 2D/3D 遮挡固有限制 | SubViewport 内 2D CanvasLayer 天然覆盖在 3D 之上，无法把倒影插到 3D 角色「之下」；本轮用「半透明镜像色块 + 压缩 + 渐隐」近似。PLAN §6 #2 既有登记，真实遮挡顺序仍待 Rank-1 裁决 |
| 3 | 倒影参数偏离冻结值 | `alpha 0.35→0.42`、压缩 `0.70→0.85` 偏离 PLAN §3.3 冻结口径，属派单第 2 条精修增强；未改 `quality_preset_*.tres` / `render_profiles.tres`，**待 Rank-1 / 总指挥复核** |
| 4 | HUD 避让为保守矩形近似 | 按派单「约 x<730、y<220」做整块屏幕矩形逐粒跳过，非精确到 HUD 面板多边形；`logical_to_screen=2` 依据当前 `stretch_shrink=2`。若 HUD 布局 / 缩放变更，需同步该矩形，本轮未做自适应探测（避免刺探、避免越界改 HUD） |
| 5 | 移动档「降级而非全关」 | PLAN §4.3 待裁决建议，本轮**保持冻结口径**（mobile 四项全关），未擅改 `render_profiles.tres` |
| 6 | 静态层逐帧重绘未节流 | PLAN §4.4 给 Rank-1 的落地建议（体积光/bloom 仅档位变化时重绘、移动档节流），本轮沿用 `_process()` 逐帧 `queue_redraw()` 口径，未擅改 |
| 7 | 画面验收范围 | 差异结论基于 Movie Maker 第 3 帧**静态**真实像素对比；未做逐帧动态验收 / 人工试玩 / 运行期帧时间实测（PLAN §4.1 基线不含 FX，不冒充本轮性能结果） |
| 8 | 长期阻塞（沿用既有登记） | ComfyUI 正式 spritesheet 接入、`128bit` 口径、apk 产物、运行期可见性人工验收仍未解决；**ComfyUI 仍是主美术路线**，本脚本是零外部依赖 2D 程序化兜底，不取代主路线、不宣称已能出图 / 已实现 3D 后处理 / 原生 HDR bloom |
| 9 | 合规边界 | 未写 `hd2d_fx.tscn` / `courtyard.tscn` / 其它工位 / 总线 / 总纲 / 契约；未自行 `git commit` / `git push`；零付费 / 零外部素材 / 零插件 / 零云服务；中文 UTF-8；Godot 4.7.2 合法语法 |

---

## 4. 合规声明

本轮**只写**派单授权范围内的 4 类产物：`godot/scripts/hd2d_fx.gd`（精修）、`godot/scripts/build_fx_r18_verify.gd`（新建）、`teamwork/Rank-4/DONE-R18.md` 与回执例外 `teamwork/command_center/ai/4/outbox/cmd-20261109-095518-176-A4.json`、`capture/` 下抓帧序列 / 对比图 / 日志。**未写** `godot/scenes/courtyard.tscn`（Rank-1 独占，PRE/POST sha256 一致）、`godot/scenes/hd2d_fx.tscn`、任何 `.tres` / `.import` / 其它 `.gd` / 其它 Rank 工位 / `00-群聊总线.md`（开工只读一次、未追加）/ 总纲 / 契约 / 任务书；未自行 git。所有 stdout 均为 Godot 4.7.2 真跑 / Grep 检索的实际输出，未伪造、未臆造引擎常量、未冒充全绿（既有 WARNING 已登记）。零付费 / 零外部生成服务 / 零外部素材增量 / 零插件；ComfyUI 仍是主美术路线。
