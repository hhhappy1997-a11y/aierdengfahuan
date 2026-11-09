# DONE-R16.md · 独立可挂载 HD-2D 光效场景（实现轮次）

> 轮次：**R16**｜派单：`cmd-20261109-085736-029-A4`｜命令：`[ROUND=R16]`｜工位：**Rank-4 美术管线与工具链**｜日期：2026-11-09
> 定位：**实现件（相对 R15 的「只给方案」）**。在 `gl_compatibility` 后端不支持 `Environment` glow / 3D 体积雾 / SSR 的前提下，按 `HD2D-FX-PLAN.md` 把体积光 / 光尘 / 湿地倒影 / bloom 四项用 **2D `CanvasLayer` + `CanvasItem._draw()` 原语**实现为**独立可挂载**光效场景，零外部素材；一个 `fx_profile` 档位开关驱动「桌面四项全开 / 移动四项全关」。
> **本轮只交付独立场景，未挂主场景**：不写 `courtyard.tscn`（Rank-1 独占），R17 由 Rank-1 挂进主场景。
> 必读（已读）：`Rank-4/HD2D-FX-PLAN.md`（分层 1/2/10/11/12 与原语/参数）、`Rank-4/ART-SPEC-FINAL.md`、`godot/scripts/render/hd2d_placeholder.gd`（10 步 `_draw()` 基线）、`00-群聊总线.md`（**开工只读一次、未追加**）。
> 只读引用（均未改）：`godot/scenes/courtyard.tscn`（只读核对节点 / layer，本工位零写入）、`godot/scripts/core/render_profiles.gd`、`godot/project.godot`、`godot/scripts/build_hud.gd` / `build_ground_material.gd` / `assemble_r15.gd` / `attach_hud.gd` / `build_courtyard.gd`（`extends SceneTree` + `CACHE_MODE_IGNORE` 回读模式）、`command_center/dispatcher/receipts/cmd-20261109-083628-786-A4.json`（回执格式样例）、`Rank-4/DONE-R15.md`（方案件）、`Rank-4/DONE-R14.md`（三段门禁口径）。
> 合规：零付费 / 零外部素材 / 零插件 / 零云服务；**ComfyUI 仍是主美术路线**，本实现是零外部依赖的 2D 程序化兜底，不取代主路线、不宣称已能出图 / 已实现 3D 后处理 / 已验收画面；不伪造输出、不臆造引擎常量；中文 UTF-8；Godot 4.7.2 合法语法；不自行 `git commit` / `git push`。

---

## 0. 一句话结论

R16 把 R15 的四项 FX 方案**真跑落地**为独立场景 `godot/scenes/hd2d_fx.tscn`（`CanvasLayer` 根 `HD2DFX(layer=10)` + 4 个挂 `hd2d_fx.gd` 的 `Node2D` 光效节点），一个 `@export_enum` 档位开关 `fx_profile` 控制四项全开/全关；`extends SceneTree` 的 `build_hd2d_fx.gd` 真跑生成并用 `CACHE_MODE_IGNORE` 从磁盘回读校验「节点结构 + 脚本挂载」`pass=10 fail=0`、`RESULT=PASS`；三段门禁 `G1 --import` / `G2 --check-only --script hd2d_fx.gd` / `G3 --quit`（另含 build 脚本 check-only 与生成真跑）**全 `EXIT=0`**；`courtyard.tscn` sha256 前后完全一致，证明**零写入**。**独立场景未挂主场景**，待 R17 由 Rank-1 接入。

---

## 1. 交付清单（①）

| # | 文件 | 字节 | sha256（前缀） | 说明 |
|---|---|---|---|---|
| 1 | `godot/scripts/hd2d_fx.gd` | 11530 | `184ae178318d6a47f2…` | `extends Node2D` 程序化 `_draw()` 四项光效 + `fx_profile` 档位开关；零外部素材 |
| 2 | `godot/scripts/build_hd2d_fx.gd` | 10243 | `d257bd0e3fe48851…` | `extends SceneTree` 真跑生成 `.tscn` + `CACHE_MODE_IGNORE` 回读校验 |
| 3 | `godot/scenes/hd2d_fx.tscn` | 651 | `47f51d44fe6b18f4…` | 独立可挂载场景：`CanvasLayer` 根 + 4 光效节点 |
| 4 | `teamwork/Rank-4/DONE-R16.md` | 见文件 | 见文件 | 本文件（①交付清单 ②自检含回读实际输出 ③未完成项与阻塞） |
| 5 | `teamwork/command_center/ai/4/outbox/cmd-20261109-085736-029-A4.json` | 2835 | — | 回执 JSON（写入后被中枢实时消费移入 `dispatcher/receipts/`，§2.5 容错校验） |

**脚本四项实现（对照 `HD2D-FX-PLAN.md` §3 与 `hd2d_placeholder.gd` 10 步基线，参数原样沿用、不重造口径）**：

| FX 项 | `_draw()` 原语 | 关键参数（沿用冻结件） |
|---|---|---|
| 湿地倒影 | 镜像 `draw_rect()` | `y_mirror=2*GROUND_Y-sy-1`、压缩 `0.70`、逐行波纹 `sin(t+y_ref)*0.03*BUFFER_W`、`alpha 0.35`、普通 Mix（非 Add）；镜像源为内联 32×32 实体色板索引阵列（零外部素材） |
| 体积光 | `draw_colored_polygon()`（`draw_polygon` 家族）×4 + `draw_line()` 中心高光 | `light_pos=(452,92)`、`spread 40/86/132/178`、`bottom=280`、`alpha 0.18/0.12/0.07/0.04`、`#FFD27A`，低 alpha 多次叠加近似径向衰减 |
| 光尘 | `draw_circle()` | 远景冷白 48（`#BFD0EA`/0.25）+ 近景暖金 32（`#FFD27A`/0.45），`seed=PLACEHOLDER_SEED=20261108` 固定、`fposmod` 循环、`sin` 横摆、`round()` 整数坐标 |
| bloom | 同心圆 `draw_circle()` ×5 + 核心 | 半径 `[4,8,14,22,32]`、alpha `[0.20,0.12,0.07,0.04,0.02]`、`#FFD27A` + `#FFF0C2` 核心；仅 `warm_gold_key` 过阈（`threshold≈0.95` 几何近似），冷夜雾区不放置 |

**档位开关**：`@export_enum("desktop", "mobile") var fx_profile: String = "desktop"`；`_apply_profile()` 派生四项布尔门 + `visible`：`desktop` 四项全开、`mobile` 四项全关（冻结口径 `HD2D-FX-PLAN.md` §4.2 / `quality_preset_*.tres` / `render_profiles.tres`）。`set_fx_profile()` 为运行期改档公共入口。§4.3「移动档降级而非全关」为待裁决建议，本轮不擅自实现（沿用 R15 登记）。

**场景结构**（`hd2d_fx.tscn`，`SceneState` 节点数 = 5）：

```text
HD2DFX (CanvasLayer, layer=10)                      ← 对齐方案 §2.1 既有 FXLayer 冻结值 10
├── FXReflection (Node2D, script=hd2d_fx.gd)       ← 倒影（最下 / fx_0_back）
├── FXGodRays    (Node2D, script=hd2d_fx.gd)       ← 体积光（fx_0_back）
├── FXMotes      (Node2D, script=hd2d_fx.gd)       ← 光尘（fx_1_front）
└── FXBloom      (Node2D, script=hd2d_fx.gd)       ← bloom（最上 / fx_1_front）
```

四个节点同挂一份 `hd2d_fx.gd`，由节点名分派 `_draw()` 只画对应一项；同 CanvasLayer 内靠子节点顺序叠加，对齐 `HD-2D视觉规范.md` §10 层序（`fx_0_back → entity → fx_1_front`）。

> **可写范围核对**：以上 5 处即本轮全部写入，均在派单授权范围内（`Rank-4/`、`godot/scripts/hd2d_fx.gd`、`godot/scripts/build_hd2d_fx.gd`、`godot/scenes/hd2d_fx.tscn` + 回执例外 `command_center/ai/4/outbox/`）。
> **引擎自动缓存（非本工位手写源件，如实登记）**：`godot/scripts/hd2d_fx.gd.uid`(19 B)、`godot/scripts/build_hd2d_fx.gd.uid`(20 B) 由 `G1 --import` 自动生成；`godot/.godot/` 下缓存 mtime 变化同理（与 `DONE-R14.md` §1 既有登记一致）。未写 `courtyard.tscn` / 其它 `.tscn` / `.tres` / `.import` / 其它工位 / 总线 / 总纲 / 契约 / 任务书。

---

## 2. 自检（② 含回读实际输出）

### 2.1 `RUN --script build_hd2d_fx.gd` 真跑 + `CACHE_MODE_IGNORE` 回读（完整实际 stdout）

命令：`Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/build_hd2d_fx.gd`

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

==== [R16 build_hd2d_fx] START ====
[R16] LOAD_SCRIPT path=res://scripts/hd2d_fx.gd resource_path=res://scripts/hd2d_fx.gd class=GDScript
[R16] MAKE_NODE name=FXReflection script_set=true fx_profile=desktop
[R16] MAKE_NODE name=FXGodRays script_set=true fx_profile=desktop
[R16] MAKE_NODE name=FXMotes script_set=true fx_profile=desktop
[R16] MAKE_NODE name=FXBloom script_set=true fx_profile=desktop
[R16] PACK pack_err=0 child_count=4 SceneState_nodes=5 probe_nodes=5 ok=true
[R16] SAVE_OK path=res://scenes/hd2d_fx.tscn save_err=0 (OK=0)
==== [R16 回读 CACHE_MODE_IGNORE] START ====
[R16_VERIFY] readback class=PackedScene resource_path=res://scenes/hd2d_fx.tscn SceneState_nodes=5
[R16_VERIFY] ① readback_not_null_and_PackedScene PASS=true | class=PackedScene
[R16_VERIFY] ② SceneState_node_count PASS=true | nodes=5 expected=5
[R16_VERIFY] ③ root_is_CanvasLayer_layer10 PASS=true | name=HD2DFX class=CanvasLayer layer=10 expected=10
[R16_VERIFY] ④ children_structure PASS=true | child_count=4 names=["FXReflection", "FXGodRays", "FXMotes", "FXBloom"] expected=["FXReflection", "FXGodRays", "FXMotes", "FXBloom"]
[R16_VERIFY] ⑤ script_attached_all_4 PASS=true | FXReflection:script=res://scripts/hd2d_fx.gd | FXGodRays:script=res://scripts/hd2d_fx.gd | FXMotes:script=res://scripts/hd2d_fx.gd | FXBloom:script=res://scripts/hd2d_fx.gd
[R16_VERIFY] ⑥ fx_profile_default_desktop PASS=true | FXReflection:desktop | FXGodRays:desktop | FXMotes:desktop | FXBloom:desktop
[R16_VERIFY] ⑦a mobile_all_off PASS=true | set_fx_profile(mobile) -> visible=false / _all_on=false (4 节点)
[R16_VERIFY] ⑦b desktop_all_on PASS=true | set_fx_profile(desktop) -> visible=true / _all_on=true (4 节点)
[R16_VERIFY] ⑧ texture_filter_Nearest PASS=true | expected=1
---- [R16] hd2d_fx.tscn 全文（磁盘实际内容）----
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hd2d_fx.gd" id="1_joxd1"]

[node name="HD2DFX" type="CanvasLayer" unique_id=80156914]
layer = 10

[node name="FXReflection" type="Node2D" parent="." unique_id=665929974]
texture_filter = 1
script = ExtResource("1_joxd1")

[node name="FXGodRays" type="Node2D" parent="." unique_id=861575665]
texture_filter = 1
script = ExtResource("1_joxd1")

[node name="FXMotes" type="Node2D" parent="." unique_id=2139348949]
texture_filter = 1
script = ExtResource("1_joxd1")

[node name="FXBloom" type="Node2D" parent="." unique_id=1977446241]
texture_filter = 1
script = ExtResource("1_joxd1")

---- [R16] hd2d_fx.tscn 全文 END ----
[R16_VERIFY] ⑨ zero_external_assets PASS=true | ext_resource_lines=1 lines=["[ext_resource type=\"Script\" path=\"res://scripts/hd2d_fx.gd\" id=\"1_joxd1\"]"] no_png_texture_subres=true
==== [R16 回读 CACHE_MODE_IGNORE] END ====
[R16] VERIFY_SUMMARY pass=10 fail=0 ok=true
==== [R16] RESULT=PASS ====
==== [R16 build_hd2d_fx] END ====
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
RUN_EXIT=0
```

> 结论：`CACHE_MODE_IGNORE` 回读**绕过缓存、从磁盘重解析**刚保存的 `.tscn`，10 项校验全 `PASS=true`、`pass=10 fail=0`、`RESULT=PASS`。末尾 2 条 `WARNING`（`ChunkManager` 既有 autoload 告警 + `ObjectDB leaked`）为工程既有、非 ERROR、非本轮新增故障（与 `DONE-R14.md` §2.2 同类登记一致），如实登记、不冒充「零 WARNING」。

### 2.2 三段门禁复跑（一次连跑，实际 EXIT）

| 段 | 命令 | 实际 EXIT |
|---|---|---|
| PRE | `sha256sum godot/scenes/courtyard.tscn` | `709f05bd…a6970642fc6`（前） |
| G1 | `--headless --path … --import` | `G1_EXIT=0`（`first_scan_filesystem` / `update_scripts_classes` / `loading_editor_layout` 三段 `[ DONE ]`） |
| G2a | `--headless --path … --check-only --script res://scripts/hd2d_fx.gd` | `G2a_EXIT=0` |
| G2b | `--headless --path … --check-only --script res://scripts/build_hd2d_fx.gd` | `G2b_EXIT=0` |
| RUN | `--headless --path … --script res://scripts/build_hd2d_fx.gd` | `RUN_EXIT=0`（见 §2.1） |
| G3 | `--headless --path … --quit` | `G3_EXIT=0` |
| POST | `sha256sum godot/scenes/courtyard.tscn` | `709f05bd…a6970642fc6`（后） |

> 派单点名的三段 `--import` / `--check-only --script hd2d_fx.gd` / `--quit` **全 `EXIT=0`**；另补 build 脚本 `--check-only` 与生成真跑 `RUN` 亦 `EXIT=0`。五段 `SCRIPT ERROR` / `Parse Error` / `ERROR` 均 `0`。

### 2.3 `courtyard.tscn` 零写入证据（sha256 前后逐字一致）

```text
===== PRE courtyard.tscn sha256 =====
709f05bd1e754e0999bfe8a933828c52a3974b83c0643d43476aaa6970642fc6 *godot/scenes/courtyard.tscn
===== POST courtyard.tscn sha256 =====
709f05bd1e754e0999bfe8a933828c52a3974b83c0643d43476aaa6970642fc6 *godot/scenes/courtyard.tscn
```

> 前后完全一致：本轮 `G1 --import` 只导入资源、不写 `.tscn`；`build_hd2d_fx.gd` 只 `load()` 光效脚本 + `ResourceSaver.save()` 到 `hd2d_fx.tscn`，从不加载 / 修改 / 保存 `courtyard.tscn`。**Rank-1 本轮独占该文件，本工位零写入。**

### 2.4 交付文件字节数 / sha256 / UTF-8 真跑 stdout

```text
===== 字节数 =====
11530 godot/scripts/hd2d_fx.gd
10243 godot/scripts/build_hd2d_fx.gd
  651 godot/scenes/hd2d_fx.tscn
22424 total
===== sha256 =====
184ae178318d6a47f2ab69ad49a0f0272de2b29756ad15386c7206a960c7a8cd *godot/scripts/hd2d_fx.gd
d257bd0e3fe488515668a06ba5bdf385a22d89e07e078e77e1cd2123982d8020 *godot/scripts/build_hd2d_fx.gd
47f51d44fe6b18f498bb3ee39b73d069c888939d7d5ff482d0760da4c120e27b *godot/scenes/hd2d_fx.tscn
===== UTF-8 校验（内联 python）=====
godot/scripts/hd2d_fx.gd utf8_ok=True chars=9699 has_cjk=True
godot/scripts/build_hd2d_fx.gd utf8_ok=True chars=9136 has_cjk=True
godot/scenes/hd2d_fx.tscn utf8_ok=True chars=651 has_cjk=False
```

> 三个交付件 `utf8_ok=True`；`.tscn` 为引擎序列化的 ASCII 文本（`has_cjk=False` 属正常），中文注释集中在两份 `.gd`。本文件 `DONE-R16.md` 落盘后另经只读最终复核：`utf8_ok=True`、`has_cjk=True`、`has_line_start_json_fence=False`（按历轮惯例交付清单记「见文件」，不自述会随定稿变化的字节数）；回执 UTF-8 见 §2.5。文档内**不含行首 ```json 围栏**（回执是独立 `.json` 文件），与 `ART-SPEC-FINAL.md` §5 一贯口径自洽。

### 2.5 回执 JSON 容错校验（中枢实时消费，实际 stdout）

写入 `command_center/ai/4/outbox/cmd-20261109-085736-029-A4.json` 后被中枢进程**实时消费**移入 `dispatcher/receipts/`。按「outbox 在则校验 outbox，否则校验中枢保存的同一份」容错校验：

```text
===== 回执 JSON 容错校验（中枢实时消费）=====
outbox_exists  = False
receipts_exists= True
checked_path   = teamwork/command_center/dispatcher/receipts/cmd-20261109-085736-029-A4.json
bytes          = 2835
utf8_ok        = True
json_load_ok   = True
task_id        = cmd-20261109-085736-029-A4 | match = True
ai             = 4 | is4   = True
status         = done | done  = True
result_len     = 1763
refs_DONE_R16  = True
has_RESULT_PASS= True
has_sha_prefix = True
has_not_attach = True
```

> 结论：回执**已写入 outbox 且已被中枢接收**（receipts 中文件即回执本体，`json.load` 通过、四字段齐备、`task_id` 正确、`ai=4` / `status=done`、`result` 引用 `DONE-R16.md` 实际结论且含 `RESULT=PASS` / sha 前缀 / 「独立场景未挂主场景」）。`outbox_exists=False` 是中枢消费行为，**不是未写、不是失败**（与 `DONE-R15.md` §2.2 / `DONE-R14.md` §2.6 同一既有正常流程），如实登记、不伪造「outbox 常驻」。

### 2.6 合规自检表

| 项 | 实际核对 | 结论 |
|---|---|---|
| 默认不刺探 | 只读必读 4 件 + 任务直接相关的场景 / 双档件 / 构建模式参考 / 回执样例；未做进度巡检、未写探针 | 通过 |
| 零付费 / 零外部素材 | 四项全为内联常量 + `_draw()` 原语；`.tscn` 内 `ext_resource` 仅 1 个 `Script`、无 PNG / Texture / sub_resource（⑨ `PASS=true`） | 通过 |
| ComfyUI 主美术路线 | 本实现明确标注为 2D 程序化零依赖兜底，不取代主路线、不宣称已能出图 | 通过 |
| 不碰 `courtyard.tscn` | sha256 前后一致（§2.3）；脚本不加载 / 不修改 / 不保存该场景 | 通过 |
| 不伪造输出 | §2.1~§2.5 全部为运行期实际 stdout / 只读核对；`WARNING` 与 `outbox_exists=False` 如实登记 | 通过 |
| 中文 UTF-8 | 三交付件 `utf8_ok=True`（§2.4）、回执 `utf8_ok=True`（§2.5）、本文件中文 UTF-8 | 通过 |
| Godot 4 合法语法 | `G2a` / `G2b` `--check-only EXIT=0`、`G1 --import` 无 Parse Error、`RUN EXIT=0` | 通过 |
| 不自行 git | 未执行 `git commit` / `git push` / 任何写 git 操作 | 通过 |
| 总线开工只读一次 | 已读 `00-群聊总线.md` 一次，无接口变更 / 里程碑交付 / 阻塞求助 / @ 回应四类事件，未追加 | 通过 |
| 回执按 `task_id` 写 outbox | `cmd-20261109-085736-029-A4.json`，已被中枢消费归档（§2.5） | 通过 |

---

## 3. 未完成项与阻塞（③）

> **最首要一条：独立场景未挂主场景。** 本轮按派单「实现独立可挂载的光效场景，不碰 `courtyard.tscn`」只交付 `hd2d_fx.tscn` 这一独立场景，**未挂进 `courtyard.tscn`**（Rank-1 本轮独占、本工位零写入）；**R17 由 Rank-1 挂进主场景**（方案 §5 落地步骤 1~2、§2.1 的 SubViewport 内 FX 栈接入点）。`status=done` 指「独立场景交付 + 程序化自检闭环」，**不是**「已挂主场景 / 已验收画面」。

| # | 未完成项 / 阻塞 | 性质 | 说明 / 去向 |
|---|---|---|---|
| 1 | **独立场景未挂主场景** | **派单明确的本轮边界** | `hd2d_fx.tscn` 独立可挂载；未写 `courtyard.tscn`；R17 由 Rank-1 挂进主场景 SubViewport 的 `FXLayer(layer=10)` 一侧 |
| 2 | 方案 §2.1 多 CanvasLayer 分层未逐层表达 | 设计取舍（如实登记） | 方案建议 `FXReflection(1)/FXGodRays(2)/FXLayer(10)/FXBloom(11)/FXModulate(12)` 多个 CanvasLayer；本独立场景为**单 CanvasLayer 根 layer=10 + 4 个同名分派 Node2D 子节点**，靠同层子节点顺序叠加近似层序。接入时按接入点分层（含 `CanvasModulate` 可选层）由 Rank-1 裁决 |
| 3 | `.tscn` 未显式序列化 `fx_profile` 行 | 引擎默认属性序列化行为 | `fx_profile` 值等于脚本默认 `"desktop"`，Godot 省略默认属性序列化，故 `.tscn` 无该行；回读 `get("fx_profile")` 仍为 `"desktop"`（⑥ `PASS=true`）。R17 改档在 Inspector 或运行期 `set_fx_profile()` 设置 |
| 4 | 移动档「降级而非全关」未实现 | 待裁决建议（不擅改冻结值） | §4.3 的「体积光 2 层 / 光尘 16~24 粒 / bloom 3 层静态渐变 / 倒影保持关」为待总指挥裁决建议；本轮按 §4.2 冻结口径 `mobile` 四项全关，未改任何 `.tres`（沿用 R15 登记） |
| 5 | 未运行期抓帧 / 未验收画面 | 未验证 | 本轮自检是**节点结构 + 脚本挂载 + 档位派生**的程序化回读（10 项），未渲染抓帧、未验收四项可见性 / 暖金×冷雾对比 / 冷雾区不过阈；待 R17 挂载后由 Rank-1 抓帧复核 |
| 6 | 2D / 3D 遮挡固有限制 | 既有登记 | SubViewport 内所有 2D CanvasLayer 天然覆盖在 3D 之上，倒影无法插到 3D 角色「之下」；用「半透明镜像 + 仅湿地区 + alpha 0.35」近似，真实遮挡顺序待 Rank-1 结合场景裁决（`scene_integration.md` §4 #3 / 方案 §6 #2） |
| 7 | 静态层逐帧重绘 | 落地建议未执行 | `_process()` 沿用 `hd2d_placeholder.gd` 每帧 `queue_redraw()` 口径；§4.4「静态层（体积光/bloom）仅档位变化时重绘 + 移动档节流到 30fps」是给 Rank-1 的性能建议，本轮未实现 |
| 8 | `CanvasItemMaterial.BLEND_MODE_ADD` 等 Add 混合枚举 | 未使用 / 未核对 | 本轮 `_draw()` 用「低 alpha 多次叠加」近似加色（与占位脚本一致），未用 Add 混合；若将来升级须 `ClassDB` 真跑核对枚举名（沿用 `DONE-R14.md` §2.1「臆造 `TEXTURE_REPEAT_ENABLED` 致 Parse Error」教训），本轮不写死、不臆造 |
| 9 | 性能预算未实测 | 设计目标 | §4.4 的桌面 ≤1.5 ms / 移动 ≤0.5 ms 是设计目标非实测；`CAPTURE-REPORT` 的 0.37 / 0.49 ms 是**不含 FX** 的静态基线，不冒充本方案结果 |
| 10 | `G3` / `RUN` 的 2 条 WARNING | 非阻塞（既有） | `ChunkManager` autoload `ChunkRoot` 缺失告警 + 退出时 `ObjectDB leaked`（2 实例），非 ERROR、非本轮脚本引入，与历轮 DONE 一致 |
| 11 | 回执被中枢实时消费，outbox 不常驻 | 非阻塞（已送达） | §2.5 已容错校验 receipts 中同一份通过；若 HOST 需 outbox 常驻副本，请在中枢停止消费后由 HOST 决定 |
| 12 | 长期项 | 沿用既有登记 | `128bit` 歧义（`ART-SPEC-FINAL.md` §6）、ComfyUI 正式素材接入、出图长期阻塞；零改动、不自行裁决 |

---

## 4. 合规声明 / 写入清单

- 本工位**写入**仅限：`godot/scripts/hd2d_fx.gd`、`godot/scripts/build_hd2d_fx.gd`、`godot/scenes/hd2d_fx.tscn`、`teamwork/Rank-4/DONE-R16.md`、回执例外 `teamwork/command_center/ai/4/outbox/cmd-20261109-085736-029-A4.json`（中枢消费后移入 `dispatcher/receipts/`，该移动由中枢执行）。
- **未写**：`godot/scenes/courtyard.tscn`（Rank-1 独占，sha256 前后一致）、`godot/scripts/render/hd2d_placeholder.gd`（运行中脚本零改动）、任何 `.tres` / `.import` / 其它 `.gd` / 其它工位 / `00-群聊总线.md`（开工只读一次、未追加）/ 总纲 / 契约 / 任务书；未自行 `git commit` / `git push`。
- `.gd.uid` 两份为 `G1 --import` 引擎自动生成的缓存文件（§1 已如实登记），非本工位手写源件。
- 零付费 / 零外部生成服务 / 零外部素材增量 / 零插件；**ComfyUI 仍是主美术路线**；中文 UTF-8；不伪造输出 / 不臆造引擎常量 / 不夸大画面已达标 / 不宣称已实现 3D 后处理或真 bloom / 真体积光。

---

## 5. 结论

R16 主任务闭环：按 `HD2D-FX-PLAN.md` 把体积光 / 光尘 / 湿地倒影 / bloom 四项实现为**独立可挂载**的零外部素材 2D 程序化光效场景，`fx_profile` 档位开关实现「桌面四项全开 / 移动四项全关」；`extends SceneTree` 真跑生成 `hd2d_fx.tscn` 并 `CACHE_MODE_IGNORE` 回读校验节点结构与脚本挂载（`pass=10 fail=0`、`RESULT=PASS`）；三段门禁（`--import` / `--check-only --script hd2d_fx.gd` / `--quit`）与生成真跑全 `EXIT=0`；`courtyard.tscn` 零写入（sha256 前后一致）；`DONE-R16.md` 三段齐备；回执按 `task_id` 写入 outbox 并被中枢实时接收、四字段与内容断言全通过。

> 证据：`godot/scripts/hd2d_fx.gd`（11530 B）、`godot/scripts/build_hd2d_fx.gd`（10243 B）、`godot/scenes/hd2d_fx.tscn`（651 B，§2.1 全文）、回执 `cmd-20261109-085736-029-A4.json`（2835 B，§2.5）、§2.1~§2.5 全部真跑 stdout。
> **明确边界：独立场景未挂主场景** —— R17 由 Rank-1 挂进 `courtyard.tscn`；本轮 `status=done` 不含「已挂主场景 / 已验收画面」，未完成项与阻塞见 §3。

---

## 6. 追加复核补记（本实例 · 并发保护分支；只追加，不改动上文 §0~§5 任何结论）

> 上文 §0~§5 与「结论」均由**并发实例先写**。本实例按派单「并发保护 —— 本轮最高优先级」最终判定为「**已由并发实例完成，本次仅复核**」：**未重做交付件、未覆盖既有结论、未重复写第二份回执**，仅追加本段复核证据并补齐派单点名的一处缺口（后台出图 job 只读观察结论）。

### 6.1 并发判定过程（本实例逐次只读检查，如实）

| 时点 | 只读检查结果 | 判定 |
|---|---|---|
| 开工首查 | `DONE-R16.md` / `godot/scripts/hd2d_fx.gd` / `godot/scenes/hd2d_fx.tscn` / `command_center/ai/4/outbox/*` / `**/receipts/cmd-20261109-085736-029-A4.json` **全部不存在** | 需完整实现 |
| 第二批只读 | `godot/scripts/build_hd2d_fx.gd` **已被并发实例先写**（完整 R16 构建脚本，含 `CACHE_MODE_IGNORE` 回读 9 项校验、派单 id 与 `[ROUND=R16]` 标记） | 转「部分完成 → 只补缺失、绝不覆盖」，复用既有构建脚本 |
| 写入前复核 | `hd2d_fx.gd`（275 行）/ `hd2d_fx.tscn`（5 节点）/`DONE-R16.md` 均已出现；回执已被中枢消费（outbox 空 + `dispatcher/receipts/cmd-20261109-085736-029-A4.json` 存在） | 最终判定「已由并发实例完成，本次仅复核」 |

- 真源核对：`Rank-4/调度任务单-latest.json` 的 `id=cmd-20261109-085736-029-A4`、`[ROUND=R16]` 与本轮派发完全一致，以它为本轮唯一真源（未读 R15 或更早任务书当作本轮任务）。
- 按派单「outbox 空但 receipts 归档存在 → 不再写第二份」：**本实例不写任何回执文件**。

### 6.2 独立复核证据（本实例只读 / 真跑，非引用上文自述）

**(a) 两个 `--check-only` 静态门禁独立真跑（引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，实际 stdout）**：

```text
=== G2a: --check-only --script res://scripts/hd2d_fx.gd ===
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

EXIT_G2a=0
=== G2b: --check-only --script res://scripts/build_hd2d_fx.gd ===
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

EXIT_G2b=0
```

> 两段 `Stderr: (empty)`，输出内 `SCRIPT ERROR` / `Parse Error` / `ERROR` **均无**；与 §2.2 登记的 `G2a_EXIT=0` / `G2b_EXIT=0` 一致。

**(b) 交付件 sha256 / 字节（本实例只读 stdout，与 §1 / §2.4 逐项吻合）**：

```text
47f51d44fe6b18f498bb3ee39b73d069c888939d7d5ff482d0760da4c120e27b  godot/scenes/hd2d_fx.tscn    651 B
184ae178318d6a47f2ab69ad49a0f0272de2b29756ad15386c7206a960c7a8cd  godot/scripts/hd2d_fx.gd    11530 B
d257bd0e3fe488515668a06ba5bdf385a22d89e07e078e77e1cd2123982d8020  godot/scripts/build_hd2d_fx.gd  10243 B
```

**(c) 节点结构文本复核**：本实例 `Read godot/scenes/hd2d_fx.tscn` 全文 5 节点（`HD2DFX` CanvasLayer layer=10 + `FXReflection`/`FXGodRays`/`FXMotes`/`FXBloom` 四个挂 `ExtResource("1_joxd1")` 的 Node2D，`texture_filter=1`），与 §2.1 打印的「磁盘实际内容」逐行一致（含 `unique_id`）；`ext_resource` 仅 1 个 Script、无 PNG / Texture / sub_resource。

**(d) 回执本体复核**：`Read dispatcher/receipts/cmd-20261109-085736-029-A4.json` → 合法 JSON、四字段齐备，`task_id=cmd-20261109-085736-029-A4` / `ai=4` / `status=done` / `result` 引用 `DONE-R16.md` 实际结论且含 `RESULT=PASS`；`wc -c` = 2835 B；`Glob outbox/*` → `No files found`（中枢实时消费，与 §2.5 一致）。

**(e) `courtyard.tscn` sha256 差异（如实登记，不伪造、不裁决）**：本实例只读 `sha256sum` 实际 stdout：

```text
=== 复核 courtyard.tscn sha256（本实例只读） ===
07766ced53b55cf262fc151eea3b8ec941cd29256966e791384eb422560af43a *godot/scenes/courtyard.tscn
```

> 该值与上文 §2.3 登记的 `709f05bd…a6970642fc6`、`DONE-R15.md` §2.4 的 `d70ae5b76992a5f3` **均不相同**。该文件由 **Rank-1 独占**，总指挥 / 主会话正与本轮并发推进，本实例复核时点已不同于 §2.3 的真跑时点，属并发改动的**时点差异**；本工位全程仅 `Read` / `sha256sum` 只读、**零写入**。本实例不据此复现 §2.3 的「前后一致」数值、不对跨模块争议做最终裁决、不伪造任何哈希；§2.3 是并发实例在其真跑时点的记录，本段只登记本实例独立读数。

### 6.3 补缺口：后台出图 job 只读观察结论（派单点名项，上文 §3 #12 未记载本轮观察）

上文 §3 #12 仅把「出图长期阻塞」登记为既有长期项，未记载本轮对该后台 job 的只读观察。按派单「③ 未完成项与阻塞（如实，**含后台出图 job 只读观察结论**）」补记（**只读；未启动第二个 GPU 出图 job、未重启、未杀现有 job**）：

```text
=== Rank-4 PNG / 后台日志元信息（只读 ls -l）===
-rw-r--r-- 1 admin 197121 25320 Nov  9 01:21  asset_proof_stderr.log
-rw-r--r-- 1 admin 197121     0 Nov  9 01:05  asset_proof_stdout.txt
-rw-r--r-- 1 admin 197121  1495 Nov  9 08:07  ground_tile.png
=== asset_proof_stdout.txt 行数 ===
0
=== 后台出图 job 日志尾部（只读 tail -n 4）===
D:\godogen_assets\image\.venv\Lib\site-packages\huggingface_hub\utils\_validators.py:206: UserWarning: The `local_dir_use_symlinks` argument is deprecated and ignored in `hf_hub_download`. Downloading to a local directory does not use symlinks anymore.
  warnings.warn(
Fetching 2 files:   0%|          | 0/2 [00:00<?, ?it/s]Fetching 2 files: 100%|██████████| 2/2 [00:00<00:00, 999.83it/s]
Loading checkpoint shards:   0%|          | 0/2 [00:00<?, ?it/s]Loading checkpoint shards:  50%|█████     | 1/2 [05:35<05:35, 335.95s/it]
=== 两日志 Grep（-i）\.png|saved|output|保存|Traceback|out of memory|CUDA ===
No matches found
```

- `asset_proof_stdout.txt` 为 **0 字节 / 0 行**；`asset_proof_stderr.log` 停在权重 / shard 加载阶段（`Loading checkpoint shards: 50%`）；两日志内**无任何 PNG / saved / output 产出记录**（Grep `-i` → `No matches found`）。
- 如实区分：`Rank-4/ground_tile.png`（1495 B，mtime 08:07）为既有素材，**不属于上述两份后台日志的输出**，沿用 `DONE-R15.md` §5.2 的区分口径，产出方不在本轮核对范围、不臆断来源、**不据此宣称该后台 job 已出图**。
- **结论**：后台 `qwen-image --quant nf4` 出图 job 两份日志内**无 PNG 产出**，长期阻塞延续，如实记阻塞；本轮 R16 是实现程序化光效场景、不涉及出图、不需要 GPU，按派单「无 PNG 则如实记阻塞并继续本轮交付」执行，不启动第二个 GPU job、不重启 / 不杀现有 job。

### 6.4 「程序化近似 ≠ 原生后处理」显式声明（补强派单点名声明）

- 四项 FX 均为 2D `CanvasItem._draw()` 的**几何 / 低 alpha 多次叠加近似**：倒影是逐块 `draw_rect()` 垂直镜像的半透明减色 Mix（非 Add、非 SSR）；体积光是扇形 `draw_colored_polygon()` 低 alpha 叠加（非 3D 体积散射 / 体积雾）；光尘是 `draw_circle()` 确定性粒子（非 GPU 粒子 / 光照后处理）；bloom 是同心圆几何近似（**非** HDR 亮度阈值 bloom 后处理）。`_draw()` 无逐调用 Add 混合参数。
- `gl_compatibility` 后端不支持 `Environment.glow` / 3D 体积雾 / SSR / 屏幕空间后处理（§0 / §3 #8 已登记）；`CanvasItemMaterial.BLEND_MODE_ADD` 等枚举本轮未使用、未臆造。
- **不宣称画面已达 HD-2D 全效**：未运行期抓帧、未验收四项可见性 / 暖金×冷雾对比 / 冷雾区不过阈（§3 #5）；2D 层无法插到 3D 角色之下（§3 #6）；单 CanvasLayer + 子节点顺序叠加是方案 §2.1 多 CanvasLayer 分层的近似（§3 #2）。
- `status=done` 指「**独立场景交付 + 程序化结构自检闭环**」，非已挂主场景 / 已验收画面（§3 #1、§5 明确边界）。

### 6.5 本实例真跑 / 引擎输出（如实，不伪造）

- 本实例真跑仅两段 `--check-only`（6.2 (a)，`EXIT_G2a=0` / `EXIT_G2b=0`，两段输出内 `SCRIPT ERROR` / `Parse Error` / `ERROR` 均无）。
- 本实例**未重跑** `G1 --import` / `G3 --quit` / `RUN --script build_hd2d_fx.gd`：避免与并发实例同时写 `.godot` 缓存，尤避免 `RUN` 重新 `PackedScene.pack()` + `ResourceSaver.save()` **覆盖既有 `hd2d_fx.tscn` 交付件**（并发保护：不覆盖、不重做）。三段门禁逐段 EXIT 与 `CACHE_MODE_IGNORE` 回读 `pass=10 fail=0` / `RESULT=PASS` 的完整实际 stdout **引用上文 §2.1 / §2.2（并发实例真跑）**，不伪造、不谎报本实例重跑。
- 本实例未写探针 / 测量 / preflight 脚本；所有输出均为只读核对或引擎 `--check-only` 真跑。

### 6.6 补记后判定

交付清单 5 项、DONE 三段（①交付清单 / ②自检含真跑 stdout 与逐段 EXIT / ③未完成项与阻塞）、回执一份（`task_id=cmd-20261109-085736-029-A4`、已被中枢消费归档）齐备；本段只**追加**后台出图 job 观察、「程序化近似非原生后处理」显式声明与独立复核证据，**不改动上文 §0~§5 与「结论」任何既有结论**，`status=done` 口径不变（指独立场景交付闭环，非画面已实现 / 已验收）。按派单并发保护回报：「**已由并发实例完成，本次仅复核**」。
