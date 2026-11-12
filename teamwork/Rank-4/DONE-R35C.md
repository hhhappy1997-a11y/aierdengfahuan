# DONE-R35C.md · Rank-4 回执

- 轮次：R35C（mobile 档过期断言同步）
- 派单：`cmd-20261112-151135-267-A4` / `cmd-20261112-151135-267` · [ROUND=R35C] · 工位 Rank-4
- 裁决：HOST 裁决 A63（mobile 档「轻量降级绘制」为正确方向，旧断言期望值过期，同步断言到新口径，不删断言 / 不放宽判定 / 不改判定逻辑）
- 目录所有权：HOST 裁决 A64
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（Godot v4.7.2.stable.official.ed1daf0bf）
- 工程：`F:/Game/aierdengfahuan/godot`
- 日期：2026-11-12

---

## 一、交付清单

| # | 交付物 | 状态 |
|---|--------|------|
| 1 | `F:/Game/aierdengfahuan/godot/scripts/verify_fx_mobile.gd` — 按 A63 同步 2 条过期断言期望值 + 必要注释 | 已交付 |
| 2 | `F:/Game/aierdengfahuan/teamwork/Rank-4/DONE-R35C.md` — 本文件 | 已交付 |
| 3 | `F:/Game/aierdengfahuan/teamwork/command_center/ai/4/outbox/cmd-20261112-151135-267-A4.json` — 回执（中枢已归档） | 已交付 + 已归档 |

**中枢归档确认**：回执写入 `ai/4/outbox/` 后，调度中枢已轮询取走并归档到 `F:/Game/aierdengfahuan/teamwork/command_center/dispatcher/receipts/cmd-20261112-151135-267-A4.json`；读回归档文件 `task_id` / `ai` / `status` / `result` 与写入内容逐字一致，`ai/4/outbox/` 复查已空（回执已被取走），归档成功。`dispatcher/receipts/` 为中枢历史回执归档目录（含历轮 `cmd-…-A4.json`）。

定位结论：`verify_fx_mobile.gd` 实际路径为 **`godot/scripts/verify_fx_mobile.gd`**（`res://scripts/verify_fx_mobile.gd`），非 `godot/test/`。

本轮仅写入上述 3 个文件。其余文件（`hd2d_fx.gd` / `impact_feedback.gd`（本轮 Rank-1 在改，只读）/ `hud.gd` / `presentation.gd` / `encounter_director.gd` / `wave_trial_director.gd` / `points_commit_orchestrator.gd` / `project.godot` / `courtyard.tscn` / 既有 `.tres` / 素材 / 其它 Rank 产出 / `capture/` 录屏产物）一律只读、零写入。零付费、零外部依赖、未启 GPU job、未自行 git、未删除 `.workbuddy` 目录。

---

## 二、真跑输出原文

### 2.1 基线（改前，仅作对照，未改脚本时真跑）

```
==== [R19] SUMMARY pass=45 fail=2 total=47 ====
==== [R19] RESULT=FAIL ====
```

两条 FAIL 原文：

```
[R19_CHK] [FXBloom][mobile] visible PASS=false | actual=true expected=false
[R19_CHK] ⑦ desktop_vs_mobile_diff_all_4 PASS=false | 4 节点两档实际值对照：desktop 四项全开(visible/_all_on/四门=true) / mobile 四项全关(全=false)，两档 texture_filter 均 Nearest
```

实际回读值关键行（新口径实况）：

```
[R19_READ][FXBloom][mobile] visible=true _all_on=false fx_profile=mobile texture_filter=1(Nearest=1) | _on_reflection=false _on_godrays=false _on_motes=false _on_bloom=false
[R19_DIFF][FXBloom] desktop{visible=true _all_on=true fx_profile=desktop filter=1 gates=[true true true true]} | mobile{visible=true _all_on=false fx_profile=mobile filter=1 gates=[false false false false]}
```

### 2.2 改后 · 三段门禁 + verify 复跑（独立 CLI 真跑，脚本内不嵌套第二引擎进程）

命令序列（同一 Bash 会话顺序执行，`2>&1 | tee /tmp/r35c_gate_R35C.log` 收集原文）：

```
G1  : --headless --path F:/Game/aierdengfahuan/godot --import
G2  : --headless --path F:/Game/aierdengfahuan/godot --check-only --script res://scripts/verify_fx_mobile.gd
VER : --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/verify_fx_mobile.gd
G3  : --headless --path F:/Game/aierdengfahuan/godot --quit
```

G1 `--import` 原文（节选）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[  83% ] first_scan_filesystem | 正在启动文件扫描……
[ DONE ] first_scan_filesystem
[ DONE ] loading_editor_layout
```

G2 `--check-only --script` 原文（无报错，语法检查通过）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
（无 SCRIPT ERROR、无语法报错）
```

VERIFY 实跑原文（完整关键段）：

```
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
WARNING: [SaveSystem] --script 工具模式（未带 v050_read 标记）：跳过自动读回（降级，不崩，保护回归基线）
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
WARNING: [R34C][PCO] HUD 未就绪（重试 6 次）→ 绑定降级：不订阅、不写盘
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
[R19_READ][FXBloom][mobile] visible=true _all_on=false fx_profile=mobile texture_filter=1(Nearest=1) | _on_reflection=false _on_godrays=false _on_motes=false _on_bloom=false
[R19_CHK] [FXBloom][mobile] visible PASS=true | actual=true expected=true
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
[R19_DIFF][FXBloom] desktop{visible=true _all_on=true fx_profile=desktop filter=1 gates=[true true true true]} | mobile{visible=true _all_on=false fx_profile=mobile filter=1 gates=[false false false false]}
[R19_CHK] ⑦ desktop_vs_mobile_diff_all_4 PASS=true | 4 节点两档实际值对照：desktop 四项全开(visible/_all_on/四门=true) / mobile 四项绘制门全关(_all_on/四门=false)，其中 FXBloom 轻量可见(visible=true)、其余 3 节点 visible=false；两档 texture_filter 均 Nearest
---- [R19 desktop vs mobile 差异对照] END ----
[R19] PROFILE_RESET 全部节点复位 desktop（仅内存态，未写盘；hd2d_fx.tscn / courtyard.tscn 均零写入）
==== [R19] SUMMARY pass=47 fail=0 total=47 ====
==== [R19] RESULT=PASS ====
==== [R19 verify_fx_mobile] END ====
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
```

> 说明：运行期 3 条 `WARNING`（SaveSystem 工具模式降级 / ChunkManager 未找到 ChunkRoot / R34C PCO HUD 未就绪绑定降级）与退出期 `ObjectDB instances were leaked` 均为既有降级路径告警，非 `SCRIPT ERROR`；`RESULT=PASS`，Exit Code 0。

G3 `--quit` 全工程启动原文（节选，含 A38 佐证）：

```
[SaveSystem] 自动读回完成 | dungeon.wave_trial.best_wave=3 | grace.trial.points=725 | dungeon.wave_trial.completed=true
[R29][DEPTH] 档=desktop 命中字段=10 ... / 档=mobile 命中字段=10 ...
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
[R35][WaveTrial] 精准弹反生产订阅者已装配：ParryService 唯一实例 + 4 信号 connect（A48①/A54）
[R35][ParryFX] 绑定唯一 ParryService 成功 node=FXBloom signals=4（A54 复用 get_parry_service，不自建）
[R34][ComboFX] 绑定唯一 ComboService 成功 node=FXBloom signals=4（A54 复用 get_combo_service，不自建）
[R34C][PCO] 生产订阅者已绑定 HUD | signals=5 slot=user://saves/slot_01（A55 唯一权威通道）
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
```

全工程 G3 `grep SCRIPT ERROR` 计数（对四段门禁合并日志统计）：

```
===== 全工程 G3 SCRIPT ERROR 计数 = 0
```

整条门禁命令 `Exit Code: 0` / `Signal: (none)` / `Stderr: (empty)`。

### 2.3 A38 只读核对（courtyard.tscn 节点 41 / uv 2/1/1 不变）

- G3 真跑输出：`courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41`
- 针对性只读 Grep `^\[node ` 计数：`courtyard.tscn:41`
- uv `2/1/1` 出处：`courtyard.tscn:24` 注释 `; [R30 v0.8.0 · A35 Rank-4 独占视觉属性] [PLACEHOLDER] uv1_scale 4/2/1 → 2/1/1，待试玩校准`；uv 相关 SubResource（`StandardMaterial3D_uvplate` / `uvlow` / `uvhigh`）本轮零写入。
- 结论：**节点 41 / uv 2/1/1 不变**（双证节点数 + 本轮对 courtyard.tscn 零写入）。

---

## 三、验收三态

三态定义：✅ 达标 ｜ ⬜ 未完成（本轮范围外 / 后续轮次）｜ ⏳ 待裁决

| 验收点 | 状态 | 依据 |
|--------|------|------|
| 定位 `verify_fx_mobile.gd` 实际路径 | ✅ | `godot/scripts/verify_fx_mobile.gd` |
| 按 A63 同步 2 条过期断言（不删 / 不放宽 / 不改判定逻辑） | ✅ | 见第四节逐字对照；判定仍为严格相等 |
| 排查其它过期断言并如实登记 | ✅ | 逐条核对 47 条，除该 2 条外无其它过期断言（见 4.3） |
| 复跑 `47 PASS / 0 FAIL` + `RESULT=PASS` | ✅ | `SUMMARY pass=47 fail=0 total=47` / `RESULT=PASS` |
| 三段门禁 G1/G2/G3 | ✅ | G1 import DONE / G2 check-only 无报错 / G3 quit 全工程启动成功 |
| 全工程 G3 `grep SCRIPT ERROR=0` | ✅ | 计数 `= 0`，Exit Code 0 |
| A38 `courtyard.tscn` 节点 41 / uv `2/1/1` 不变 | ✅ | node_count=41 双证 + 本轮零写入 |
| 如实登记总指挥目视纠正口径（不沿用 R35 旧自评） | ✅ | 见第五节 |
| 硬约束（只读文件零写入 / 零付费 / 零外部依赖 / 不启 GPU job / 不自行 git / 不删 `.workbuddy`） | ✅ | 本轮仅写 3 个授权文件 |
| 定稿录屏由总指挥本轮亲自重跑并目视 | ⬜ | 按任务单「你不必重复录屏」，本轮我不重复录屏 |
| HD-2D 全绿 | ⬜ | 总指挥目视：仍 2D 近似，全绿未达 |
| 程序化 `_draw()` 光环 / 闪光实机可辨识 | ⬜ | 总指挥目视：实机仍不易辨识 |
| R19 头部历史职责注释是否同步到 A63 新口径 | ⏳ | 本轮按「只改两条断言期望值与必要注释」未动，提请裁决（见 4.4 / 第六节） |

---

## 四、两条断言改前 → 改后逐字对照

### 4.1 断言 ① · `[FXBloom][mobile] visible`（`_verify_node()`，`verify_fx_mobile.gd` 第 166 行区域）

判定本体**未改**，仍为第 195 行：

```gdscript
	_check("%s visible" % tag, v == exp_vis, "actual=%s expected=%s" % [str(v), str(exp_vis)])
```

改的是 `exp_vis` 的**期望值来源**。

**改前**（逐字）：

```gdscript
	var exp_vis: bool = (profile == "desktop")
	var exp_all: bool = (profile == "desktop")
	var exp_prof: String = profile
```

**改后**（逐字）：

```gdscript
	var exp_vis: bool = (profile == "desktop")
	# A63（R35C）：mobile 档 FXBloom 走「轻量降级绘制」（轻量环 + HUD 文字，
	# 移动端不劣化 ≠ 完全不绘制），该节点 mobile 下保持 visible=true；
	# 其余 3 个 FX 节点仍四项全关 visible=false。
	# 仅同步本条 visible 断言的期望值，判定逻辑（v == exp_vis 严格相等）不变。
	if profile == "mobile" and str(n.name) == "FXBloom":
		exp_vis = true
	var exp_all: bool = (profile == "desktop")
	var exp_prof: String = profile
```

对照要点：仅对 `FXBloom + mobile` 把 `visible` 期望由 `false` 改为 `true`（轻量可见）；`v == exp_vis` 严格相等判定、断言条数、`_check` 调用方式均未变。输出由 `actual=true expected=false / PASS=false` 变为 `actual=true expected=true / PASS=true`。

### 4.2 断言 ② · `⑦ desktop_vs_mobile_diff_all_4` 汇总项（`_print_diff()`，`verify_fx_mobile.gd` 第 234 行区域）

`_check` 调用本体**未改**（label 仍为 `⑦ desktop_vs_mobile_diff_all_4`，仍用 `diff_ok` 计数）。

**改前**（逐字）：

```gdscript
		var hit: bool = dv and da and (dp == "desktop") \
			and (not mv) and (not ma) and (mp == "mobile") \
			and (mf == CanvasItem.TEXTURE_FILTER_NEAREST) \
			and (df == CanvasItem.TEXTURE_FILTER_NEAREST) and gates_diff_ok
		diff_ok = diff_ok and hit
	_check("⑦ desktop_vs_mobile_diff_all_4", diff_ok,
			"4 节点两档实际值对照：desktop 四项全开(visible/_all_on/四门=true) / mobile 四项全关(全=false)，两档 texture_filter 均 Nearest")
```

**改后**（逐字）：

```gdscript
		# A63（R35C）：mobile 档 FXBloom 轻量降级绘制 → visible 期望 true；
		# 其余 3 节点 mobile 全关 → visible 期望 false。
		# 仅把 mobile visible 期望参数化（严格相等 mv == exp_mobile_vis），不放宽判定、不改其它项。
		var exp_mobile_vis: bool = (nm == "FXBloom")
		var hit: bool = dv and da and (dp == "desktop") \
			and (mv == exp_mobile_vis) and (not ma) and (mp == "mobile") \
			and (mf == CanvasItem.TEXTURE_FILTER_NEAREST) \
			and (df == CanvasItem.TEXTURE_FILTER_NEAREST) and gates_diff_ok
		diff_ok = diff_ok and hit
	_check("⑦ desktop_vs_mobile_diff_all_4", diff_ok,
			"4 节点两档实际值对照：desktop 四项全开(visible/_all_on/四门=true) / mobile 四项绘制门全关(_all_on/四门=false)，其中 FXBloom 轻量可见(visible=true)、其余 3 节点 visible=false；两档 texture_filter 均 Nearest")
```

对照要点：原 `(not mv)` 为「所有节点 mobile visible 一律必须为 false」的硬编码期望；改后把该期望参数化为按节点的 `exp_mobile_vis`（FXBloom=`true`，其余 3 节点=`false`），判定仍为严格相等 `mv == exp_mobile_vis`。对 3 个非 FXBloom 节点约束未放宽（仍要求 `mv=false`），对 FXBloom 要求 `mv=true`（即 A63 轻量可见）。`_all_on` / 四项门 / `texture_filter` / `fx_profile` / `gates_diff_ok` 各项判定与其它断言一律未动。detail 文本同步到新口径（去掉「mobile 四项全关(全=false)」的过期表述）。输出由 `PASS=false` 变为 `PASS=true`，汇总计数恢复 `47 PASS / 0 FAIL`。

### 4.3 其它过期断言排查结论（如实登记）

逐条核对全部 47 条断言（6 条结构/初始 + mobile 4 节点×5 + desktop 4 节点×5 + 1 条差异汇总）：

- mobile 档 FXBloom 的 `_all_on`（实际 `false`）、`four_draw_gates`（实际四门全 `false`）、`texture_filter`（实际 `Nearest`）、`fx_profile`（实际 `mobile`）四项旧期望在 R35B/A63 新口径下**仍成立**（轻量降级绘制不等于四项绘制门开启，`_draw()` 轻量分支 + HUD 文字不经过这四项门），无需改。
- mobile 档其余 3 节点（FXReflection / FXGodRays / FXMotes）仍为四项全关 `visible=false`，旧期望成立，无需改。
- desktop 档全部 20 条与 6 条结构/初始断言不受 R35B 影响，全部 `PASS`，无需改。
- **结论：除上述 2 条外，无其它过期断言。未删除任何断言，未放宽任何判定，未改动 `_check` 计数 / `diff_ok` / `ok` 汇总判定逻辑。**

### 4.4 未同步的注释（如实登记）

脚本头部 R19 编写期职责注释（`verify_fx_mobile.gd` 第 15–19 行）仍描述「回读 `visible=false`」「移动四项全关」「关掉四项光效后画面主体仍可读」等 R19 旧口径文字。本轮按任务单「只改这两条过期断言的期望值与必要注释」的范围约束**未改动该头部历史说明**（属 R19 编写期职责描述，非断言本体）。是否一并按 A63 口径同步，列入「待裁决项」。运行期不受影响（注释不参与判定）。

---

## 五、如实登记（沿用总指挥本轮亲自目视纠正口径，不沿用 R35 旧自评）

总指挥回看 `capture/v120_final.mp4` 第 **30 / 110 / 148 / 150 / 152 / 225 / 340 / 440** 帧确认，本轮 DONE 沿用以下口径：

| 项 | 总指挥目视纠正结论 |
|----|--------------------|
| 弹反 HUD 文字层 | **清晰可见**：148 帧「精准弹反窗口 0.3s · 按 K」、150 帧「弹反成功！+削韧 / +赐福点数 / 连击不断」 |
| HUD 文字重叠 | **无重叠**（R34C 修复有效） |
| 连击递进 | **D→C 递进可见**：评级 C / 倍率 1.15 / `4 HIT x1.15` |
| 地面 | 改规整错缝石板，**观感提升** |
| A59 扣费 | 340 帧「当前余额 106（点数 215 − 已消费 109）」证 **扣费生效** |
| 程序化 `_draw()` 光环 / 闪光 | 实机 **仍不易辨识** |
| HD-2D 全绿 | **未达**（仍 2D 近似） |

> 本轮不再沿用 R35 旧自评（「弹反反馈未能辨识 / HUD 既有重叠」）。定稿录屏由总指挥本轮亲自重跑并目视，Rank-4 不重复录屏。

---

## 六、未完成项

1. **HD-2D 全绿未达**（仍 2D 近似）—— 属画质长期目标，非本轮 A63 断言同步范围，待后续轮次。
2. **程序化 `_draw()` 光环 / 闪光实机仍不易辨识** —— 总指挥目视结论，需美术/渲染侧后续调参，本轮未改 `hd2d_fx.gd`（只读）。
3. **定稿录屏本轮由总指挥亲自重跑并目视** —— 按任务单「你不必重复录屏」，Rank-4 未重复录屏，也未改动 `capture/` 录屏产物。
4. 本轮未改 `hd2d_fx.gd` / `impact_feedback.gd` / `hud.gd` / `presentation.gd` / `courtyard.tscn` / 既有 `.tres` / 素材 / 其它 Rank 产出（目录所有权只读约束）。

---

## 七、待裁决项

1. **R19 头部历史职责注释**（第 15–19 行「移动四项全关 / 关掉四项光效…」）是否一并按 A63 新口径同步？本轮严守「只改两条断言期望值与必要注释」未动，提请 HOST / 总指挥裁决。
2. **A63 后续**：mobile 档 FXBloom「轻量环 + HUD 文字」的实机可辨识度（对照「`_draw()` 光环 / 闪光仍不易辨识」），是否需 Rank-1 在 `impact_feedback.gd` 进一步调参？本轮仅同步回归断言，未涉实现。
3. `--quit` 全工程启动期的既有 `WARNING`（SaveSystem / ChunkManager / R34C PCO 降级）与退出期 `ObjectDB instances were leaked`：均非 `SCRIPT ERROR`、不影响 `RESULT=PASS`，本轮按「不刺探 / 不越界」未处理，是否纳入后续清理由总指挥定夺。

---

## 八、结论

R35C 按 HOST 裁决 A63 完成 mobile 档过期断言同步：`verify_fx_mobile.gd` 仅改 2 条断言的期望值与必要注释（不删断言 / 不放宽判定 / 不改判定逻辑），真跑 **47 PASS / 0 FAIL / RESULT=PASS**；三段门禁通过、全工程 G3 `SCRIPT ERROR=0`；A38 `courtyard.tscn` 节点 41 / uv `2/1/1` 不变；如实登记沿用总指挥目视纠正口径。回执已写入 `teamwork/command_center/ai/4/outbox/cmd-20261112-151135-267-A4.json`，并经调度中枢归档至 `teamwork/command_center/dispatcher/receipts/cmd-20261112-151135-267-A4.json`（读回内容一致，outbox 已取空），**中枢归档确认完成**。
