# DONE-R38C.md · R38C 清理清单外第 6 份回归的旧基线断言（HOST 裁决 A80 越界授权）交付报告（Rank-1）

> 轮次：`R38C` ｜ 任务单 id：`cmd-20261113-080813-761-A1` ｜ 执行 AI：`1（Rank-1 引擎架构与渲染执行 AI）`
> 真源：`teamwork/Rank-1/调度任务单-latest.json`（id 核对一致；task 全文 + 裁决 A80 越界授权 + 公共契约 + 目录所有权·R38C + 交付·缺一不可）
> 精确改法源：`teamwork/Rank-1/DONE-R38B.md` **§4.3 / §8 待裁决 #1**（清单外第 6 份 V090 的 2 条 A38 旧基线断言，附与 §2 的 8 条完全一致的改法）
> 前序：`DONE-R38.md`（R38 / A74 把 `courtyard.tscn` 从节点 41 / uv 2-1-1 改为 **54 / 16-8-8**）→ `DONE-R38B.md`（A79 把 5 份回归的 8 条 A38 断言同步到新基线，219 PASS / 0 FAIL；如实登记清单外第 6 份 V090 仍有 2 条旧基线 FAIL，45 PASS / 2 FAIL / MISMATCH / EXIT=1，因不在授权范围未越权改）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`）
>
> **一句话结论**：按裁决 A80 把清单外第 6 份 `verify_impact_feedback_v090.gd` 的 **2 条 A38 旧基线断言（J1 节点数 41→54、J2 uv 2/1/1→16/8/8）逐条同步到新基线 54 / 16-8-8**（只改期望数字 / 标签 / 注释，不删断言、不放宽判定、判定逻辑逐字不动）；V090 复跑 **47 PASS / 0 FAIL / RESULT=ALL_MATCH / EXIT=0 / SCRIPT ERROR=0**；全量回归收口 **12 份受 A74 影响回归 605 PASS / 0 FAIL / 12×ALL_MATCH / 12×EXIT=0**，人物 40% 断言仍 PASS、既有战斗入口仍可达（A77）、A74 新基线一致；三段门禁 G1 import / G2b V040 / G3 quit 全 `EXIT=0`，最终全工程 **`SCRIPT ERROR=0 / PARSE ERROR=0`**。本轮**未遇到 Rank-4 并行录屏的瞬时半成品**（12 份回归 + 门禁三进程逐进程 `SCRIPT ERROR=0`），无需收敛后复跑；headless 无帧缓冲，本轮不含定稿录屏 / 目视（归 Rank-4 / 总指挥，不重复录屏）。

---

## 1. 交付清单（实际落地文件）

| # | 文件 | 类型 | 本轮改动 |
|---|---|---|---|
| ① | `godot/scripts/render/verify_impact_feedback_v090.gd` | 修改（A80 授权） | 2 条 A38 断言的期望数字 / 标签 / 注释同步到 54 / 16-8-8，共 **7 处文本编辑**（详见 §2）；判定逻辑、断言集合、其余 45 条断言逐字未动。 |
| ② | `teamwork/Rank-1/DONE-R38C.md` | **新建** | 本交付报告。 |
| ③ | `teamwork/command_center/ai/1/outbox/cmd-20261113-080813-761-A1.json` | **新建** | 本轮回执（**`teamwork/command_center/`**，非工程根），写后经中枢归档（§10）。 |

**只读未改（硬约束）**：`courtyard.tscn` / `world_scale.tres` / 既有 `.tres` / `project.godot` / `impact_feedback.gd` / `hd2d_fx.gd` / `hd2d_parallax.gd` / `hud.gd` / `encounter_director.gd` / `wave_trial_director.gd`（Rank-2）/ `points_commit_orchestrator.gd`（Rank-3）/ `verify_wave_runtime_v040.gd` / `verify_bigmap_v150.gd` 及其余 10 份回归脚本 / 其它 Rank 产出。

---

## 2. 2 条断言改前 → 改后逐条对照（交付要求 · 核心）

### 2.1 同步口径（裁决 A80 / 硬约束逐字遵守）

- 依 `DONE-R38B.md §8 待裁决 #1` 的精确改法（与 §2 的 8 条同源）：只改 **期望数字 / 标签 / 注释**。
  - 节点数：`const NODE_COUNT_EXPECTED: int = 41` → `54`；J1 标签 `== 41` → `== 54`。
  - uv：`_count_substr(text, "uv1_scale = Vector3(2, 2, 1)")` → `Vector3(16, 16, 1)`；`("uv1_scale = Vector3(1, 1, 1)")` → `Vector3(8, 8, 1)`；J2 标签 `uv 2/1/1 ... Vector3(2,2,1)×1 + Vector3(1,1,1)×2` → `uv 16/8/8 ... Vector3(16,16,1)×1 + Vector3(8,8,1)×2`。
  - 顶部 J 组列表注释、J 组头部注释 `41 / 2/1/1` → `54 / 16/8/8`。
- **不删断言、不放宽判定、不改判定逻辑**：2 个 `_ck(...)` 判定表达式与全部其余断言逐字不动 ——
  `count == NODE_COUNT_EXPECTED`、`n2 == 1 and n1 == 2`；`_ck` 调用结构、`_count_substr` 结构、变量名 `n2` / `n1`、detail 格式串、J3 断言均不动。
- 仅在常量行 / 注释 / 标签末尾补最短 `R38 / A74 新基线` 标注（与 R38B §2 五份脚本同口径）。
- 新基线真值来自 `courtyard.tscn` 磁盘回读：`Vector3(16, 16, 1)` ×1（GroundPlate）、`Vector3(8, 8, 1)` ×2（TerraceLow/TerraceHigh）、`[node ` 行数 54；与 V040 `node_count=54`、V150 `B2/B7/F4` 完全一致。

### 2.2 逐条对照表（2 条断言 / 7 处编辑）

| # | 断言 tag | 位置 | 改前（A38 旧基线 41 / 2-1-1） | 改后（A74 新基线 54 / 16-8-8） | 判定逻辑 |
|---|---|---|---|---|---|
| 1 | **J1** 节点数 | 行 53 常量 | `const NODE_COUNT_EXPECTED: int = 41` | `const NODE_COUNT_EXPECTED: int = 54  # R38 / A74 新基线（A38 旧基线 41）` | `count == NODE_COUNT_EXPECTED` 不动 |
| 2 | **J1** 节点数 | 行 525 标签 | `J1 courtyard.tscn 静态 [node] 行数 == 41（A38 节点数保持）` | `... 行数 == 54（A38 节点数保持；R38 / A74 新基线 41→54）` | 同上（行 526 逐字不动） |
| 3 | **J2** uv | 行 527 字面量 | `_count_substr(text, "uv1_scale = Vector3(2, 2, 1)")` | `_count_substr(text, "uv1_scale = Vector3(16, 16, 1)")` | `n2 == 1 and n1 == 2` 不动（仍期望 ×1 + ×2） |
| 4 | **J2** uv | 行 528 字面量 | `_count_substr(text, "uv1_scale = Vector3(1, 1, 1)")` | `_count_substr(text, "uv1_scale = Vector3(8, 8, 1)")` | 同上 |
| 5 | **J2** uv | 行 529 标签 | `J2 uv 2/1/1 原样：Vector3(2,2,1) ×1 + Vector3(1,1,1) ×2` | `J2 uv 16/8/8 原样：Vector3(16,16,1) ×1 + Vector3(8,8,1) ×2（R38 / A74 新基线）` | 同上（行 530 逐字不动） |
| 6 | J 组注释（非判定路径） | 行 19 顶部列表 | `J A38 不破坏（courtyard.tscn [node]==41 / uv 2/1/1 ...）` | `==54 / uv 16/8/8 ...；R38 / A74 新基线 41→54 / 2-1-1→16-8-8` | —（注释） |
| 7 | J 组注释（非判定路径） | 行 517 组头 | `# J) A38 不破坏（courtyard.tscn 节点数 41 / uv 2/1/1 ...）` | `节点数 54 / uv 16/8/8 ...；R38 / A74 新基线 41→54 / 2-1-1→16-8-8` | —（注释） |

> 说明：2 条断言（J1 / J2）落在 **1 个常量 + 3 个标签行 + 2 个 `_count_substr` 字面量** 共 6 处，连同 2 处组注释合计 **7 处编辑**；断言集合 **47 条未变**，其余 45 条逐字未动。

### 2.3 改后落盘实证（改后 Grep 回读，原文节选）

```
verify_impact_feedback_v090.gd:19:##   J A38 不破坏（courtyard.tscn [node]==54 / uv 16/8/8 / 无反馈层静态节点；R38 / A74 新基线 41→54 / 2-1-1→16-8-8）
verify_impact_feedback_v090.gd:53:const NODE_COUNT_EXPECTED: int = 54  # R38 / A74 新基线（A38 旧基线 41）
verify_impact_feedback_v090.gd:517:# J) A38 不破坏（courtyard.tscn 节点数 54 / uv 16/8/8 / 无静态反馈层节点；R38 / A74 新基线 41→54 / 2-1-1→16-8-8）
verify_impact_feedback_v090.gd:525:	_ck("J1 courtyard.tscn 静态 [node] 行数 == 54（A38 节点数保持；R38 / A74 新基线 41→54）",
verify_impact_feedback_v090.gd:526:			count == NODE_COUNT_EXPECTED, "count=%d expected=%d" % [count, NODE_COUNT_EXPECTED])
verify_impact_feedback_v090.gd:527:	var n2: int = _count_substr(text, "uv1_scale = Vector3(16, 16, 1)")
verify_impact_feedback_v090.gd:528:	var n1: int = _count_substr(text, "uv1_scale = Vector3(8, 8, 1)")
verify_impact_feedback_v090.gd:529:	_ck("J2 uv 16/8/8 原样：Vector3(16,16,1) ×1 + Vector3(8,8,1) ×2（R38 / A74 新基线）",
```

判定逻辑行 526 `count == NODE_COUNT_EXPECTED`、行 530 `n2 == 1 and n1 == 2` **逐字未动**（回读可见）。

### 2.4 残留检查

改后对 `== 41` / `Vector3(2, 2, 1)` / `Vector3(1, 1, 1)` / `uv 2/1/1` / `NODE_COUNT_EXPECTED: int = 41` / `[node]==41` 做精确 Grep：**`No matches found`（旧基线字面量 0 残留）**。标注文字里的 `41→54` / `2-1-1→16-8-8` / `A38 旧基线 41` 为有意留痕，不在判定路径。

---

## 3. V090 复跑输出（任务 ① · 真跑输出原文）

命令：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/render/verify_impact_feedback_v090.gd`

改前后对照（改前数据来自 `DONE-R38B.md §4.3` 只读真跑）：

```
[改前 / R38B] J1 ... 行数 == 41（A38 节点数保持） PASS=false | count=54 expected=41
[改前 / R38B] J2 uv 2/1/1 原样：...            PASS=false | uv_2x=0 uv_1x=0
[改前 / R38B] SUMMARY pass=45 fail=2 total=47 ok=false
[改前 / R38B] RESULT=MISMATCH   V090_EXIT=1

[改后 / R38C 真跑原文]
[V090] J1 courtyard.tscn 静态 [node] 行数 == 54（A38 节点数保持；R38 / A74 新基线 41→54） PASS=true | count=54 expected=54
[V090] J2 uv 16/8/8 原样：Vector3(16,16,1) ×1 + Vector3(8,8,1) ×2（R38 / A74 新基线） PASS=true | uv_2x=1 uv_1x=2
[V090] J3 courtyard.tscn 文本无 ImpactFeedbackLayer / impact_feedback.gd（运行时挂载、不写场景） PASS=true | contains_layer=false contains_script=false
[V090] ---- 回读汇总 ----
[V090] SUMMARY pass=47 fail=0 total=47 ok=true
[V090] RESULT=ALL_MATCH
[V090] ==== verify_impact_feedback_v090 真跑结束 ====
========== V090_EXIT=0 ==========
V090_SCRIPT_ERROR_LINES=0
V090_PARSE_ERROR_LINES=0
```

**结论**：**47 PASS / 0 FAIL / total=47 / ok=true / RESULT=ALL_MATCH / EXIT=0 / SCRIPT ERROR=0 / PARSE ERROR=0**。2 条旧基线断言同步后全部 PASS，其余 45 条（A~I / J3 / K / L / M / N）全 PASS、`PASS=false` 计数 0。J1 `count=54 expected=54`、J2 `uv_2x=1 uv_1x=2` 实证新基线同步正确，判定逻辑未放宽（仍是 `count==常量`、`n2==1 and n1==2`）。

**既有日志噪音（非 SCRIPT ERROR / 非 FAIL，如实登记）**：`--script` 工具模式下 `WARNING: [SaveSystem] 跳过自动读回（降级，不崩）`、`WARNING: [ChunkManager] 未找到 ChunkRoot`、`WARNING: [PCO] HUD/FocusService/FlaskService/DeathService 未就绪 → 绑定降级`、`WARNING: 2 ObjectDB instances were leaked at exit` —— 与 `DONE-R38B §5.4` 同口径既有登记，非 `SCRIPT ERROR` / 非 `PARSE ERROR` / 非本轮引入 / 不影响 `EXIT=0` 与断言全 PASS。

---

## 4. 全量回归结果（任务 ②）

### 4.1 12 份受 A74 影响回归 · 逐份真跑汇总（输出原文）

命令前缀统一 `... --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/.../<name>.gd`，逐份 `SUMMARY` / `RESULT` / `EXIT` / `SCRIPT ERROR` 原文：

```
===== RUN verify_wave_runtime_v040 =====   [V040] SUMMARY pass=37 fail=0  | RESULT=ALL_MATCH  | EXIT=0 SCRIPT_ERROR=0 PARSE_ERROR=0 PASS_false=0
===== RUN verify_bigmap_v150 =====         [V150] SUMMARY pass=37 fail=0 total=37 ok=true  | RESULT=ALL_MATCH  | EXIT=0 SCRIPT_ERROR=0 PARSE_ERROR=0 PASS_false=0
===== RUN verify_hud_layout_v100 =====     [V100HUD] SUMMARY pass=48 fail=0 total=48 ok=true  | RESULT=ALL_MATCH  | EXIT=0 SCRIPT_ERROR=0 PARSE_ERROR=0 PASS_false=0
===== RUN verify_production_chains_v110 === [V110] SUMMARY pass=75 fail=0 total=75 ok=true  | RESULT=ALL_MATCH  | EXIT=0 SCRIPT_ERROR=0 PARSE_ERROR=0 PASS_false=0
===== RUN verify_life_runtime_v140 =====   [V140] SUMMARY pass=26 fail=0 total=26 ok=true flask_source=rank2_production_unique_instance  | RESULT=ALL_MATCH  | EXIT=0 SCRIPT_ERROR=0
===== RUN verify_focus_runtime_v130 =====  [V130] SUMMARY pass=39 fail=0 total=39 ok=true focus_source=rank2_production_unique_instance  | RESULT=ALL_MATCH  | EXIT=0 SCRIPT_ERROR=0
===== RUN verify_parry_runtime_v120 =====  [V120P] SUMMARY pass=31 fail=0 total=31 ok=true parry_source=rank2_production_unique_instance  | RESULT=ALL_MATCH  | EXIT=0 SCRIPT_ERROR=0
===== RUN verify_impact_feedback_v090 ==== [V090] SUMMARY pass=47 fail=0 total=47 ok=true  | RESULT=ALL_MATCH  | EXIT=0 SCRIPT_ERROR=0 PARSE_ERROR=0 PASS_false=0
===== RUN verify_world_encounter_v150 ==== [V150-WE] SUMMARY pass=49 fail=0  | RESULT=ALL_MATCH  | EXIT=0 SCRIPT_ERROR=0 PARSE_ERROR=0 PASS_false=0
===== RUN verify_world_settlement_v150 === [V150-WS] SUMMARY pass=78 fail=0  | RESULT=ALL_MATCH  | EXIT=0 SCRIPT_ERROR=0 PARSE_ERROR=0 PASS_false=0
===== RUN verify_v150_save_commit =====    [V150-C] SUMMARY mode=all pid=10148 slot=user://saves/verify_v150_10148 pass=85 fail=0 total=85  | RESULT=ALL_MATCH  | EXIT=0 SCRIPT_ERROR=0
===== RUN verify_world_production_v150 === [V150-WP] SUMMARY pid=15740 slot=user://saves/verify_v150_wp_15740 pass=53 fail=0 total=53  | RESULT=ALL_MATCH  | EXIT=0 SCRIPT_ERROR=0

===== FULL REGRESSION (12 scripts, A74-affected) =====
TOTAL_PASS=605  TOTAL_FAIL=0  SCRIPT_ERROR_LINES_SUM=0  PARSE_ERROR_LINES_SUM=0
```

**合计 605 PASS / 0 FAIL**（37+37+48+75+26+39+31+47+49+78+85+53 = 605），12 份全部 `RESULT=ALL_MATCH` / `EXIT=0` / `SCRIPT ERROR=0` / `PARSE ERROR=0` / `PASS=false` 计数 0。

### 4.2 关键回归 V040 / V150 证据行（人物 40% / A77 战斗入口 / A74 新基线）

```
[V040] courtyard_node_count PASS=true | node_count=54 expected=54（+21：... + R38 大地图 13 节点）
[V040] uv_groundplate_16 PASS=true | uv1_scale=(16.0, 16.0, 1.0) expected=(16,16,1)
[V150] A4 人物缩放计算式 character_scale == baseline × ratio PASS=true | baseline=1.600 ratio=0.400 computed=0.6400 character_scale=0.6400
[V150] A5 ★ 人物显示尺寸 == 基线 × 0.40（±容差） PASS=true | 0.6400 == 1.600 × 0.40 = 0.6400 | tol=0.0010
[V150] B2 ★ A74 新基线 node_count == 54 PASS=true | node_count=54 expected=54（+13 大地图节点）
[V150] B3 既有战斗入口 EncounterRoot / WaveTrialDirector / Hud / Camera3D 仍可达 PASS=true | enc=true wave=true hud=true cam3d=true
[V150] B7 ★ A74 新基线 uv 16/8/8 PASS=true | plate=(16.0,16.0,1.0) low=(8.0,8.0,1.0) high=(8.0,8.0,1.0)
[V150] C2 ★ 角色显示尺寸实测：真实节点 scale == 基线 × 0.40 PASS=true | target_scales=[0.64,0.64,0.64] applied_targets=3
[V150] C3 画面像素高度对比：new/old == 0.40 PASS=true | old=2.4000m new=0.9600m ratio=0.4000
[V150] E2 HUD 角色包围盒避让几何从 world_scale.tres 读 ratio ≈ 0.40 PASS=true | ratio=0.4000 expected=0.40
[V150] E3 新尺寸角色包围盒 == 保守保护区 × ratio PASS=true | bbox_size=(192.0,135.9994) guard_size=(480.0,339.9984) ratio=0.4000
[V150] F1 既有战斗入口 EncounterRoot / WaveTrialDirector / Hud 仍可达（大地图为新增层） PASS=true | enc=true wave=true hud=true
[V150] F4 A74 节点数与 uv 新基线在实例侧一致（54 / 16-8-8） PASS=true | node_count=54 uv=(16.0,16.0,1.0)/(8.0,8.0,1.0)/(8.0,8.0,1.0)
```

- **人物 40% 断言仍 PASS**：V150 A4 / A5 / C2 / C3 / E2 / E3 全 `PASS=true`（0.64 = 1.6×0.40、3 节点 scale 实测、画面像素高 2.4000m→0.9600m、ratio 0.4000）。
- **既有战斗入口仍可达（A77）**：V150 B3 / F1 全 `PASS=true`（`EncounterRoot` / `WaveTrialDirector` / `Hud` / `Camera3D` 均可寻址，大地图为新增并行层、既有闭环不删不改）。
- **A74 新基线一致**：V040 `node_count=54` + uv 16、V150 B2 / B7 / F4 全 PASS。

### 4.3 全量口径汇总

| 分组 | 脚本 | 结果 |
|---|---|---|
| R38B 授权 5 份（本轮复跑确认） | V140 / V100HUD / V110 / V130 / V120P | **219 PASS / 0 FAIL**，5×`ALL_MATCH`（与 R38B §3 一致） |
| 关键回归 + 本轮修复 | V040 / V150 / **V090** | **37 + 37 + 47 = 121 PASS / 0 FAIL**，3×`ALL_MATCH`（V090 由 45/2 转 47/0） |
| world / save 回归（任务 ② 点名） | V150-WE / V150-WS / V150-C / V150-WP | **49+78+85+53 = 265 PASS / 0 FAIL**，4×`ALL_MATCH` |
| **本轮全量收口合计** | **12 份** | **605 PASS / 0 FAIL / SCRIPT ERROR=0 / PARSE ERROR=0 / 12×EXIT=0** |

> 口径说明：本轮「全量回归收口」= 任务 ② 点名的 12 份受 A74 影响回归（覆盖 R38B 涉及的全部 8 份 + 4 份 world / save 回归）。未擅自扩大到工程内更早批次、与 A74 无关的其它 `verify_*.gd`（任务单未要求、避免引入无关历史状态）。本轮这 12 份范围内 **0 FAIL**。

---

## 5. 三段门禁 + 全工程 G3 `grep SCRIPT ERROR=0`（任务 ③）

### 5.1 门禁真跑输出原文

```
========== G1 IMPORT ==========
[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[  16% ] first_scan_filesystem | 正在加载全局类名……
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[  83% ] first_scan_filesystem | 正在启动文件扫描……
[ DONE ] first_scan_filesystem
[   0% ] loading_editor_layout | Started 正在加载编辑器 (5 steps)
[ DONE ] loading_editor_layout
========== G1_IMPORT_EXIT=0 ==========
G1_SCRIPT_ERROR_LINES=0
========== G2B V040 RERUN ==========
[V040] courtyard_node_count PASS=true | node_count=54 expected=54
[V040] uv_groundplate_16 PASS=true | uv1_scale=(16.0, 16.0, 1.0) expected=(16,16,1)
[V040] SUMMARY pass=37 fail=0
[V040] RESULT=ALL_MATCH
========== G2B_V040_EXIT=0 ==========
G2B_SCRIPT_ERROR_LINES=0
========== G3 QUIT ==========
[SaveSystem] 自动读回完成 | dungeon.wave_trial.best_wave=0 | grace.trial.points=0 | dungeon.wave_trial.completed=false
[R34C][PCO] 生产订阅者已绑定 HUD | signals=5 slot=user://saves/slot_01（A55 唯一权威通道）
[R36][PCO] A66 生产订阅者已绑定 FocusService 唯一实例 | signals=3 slot=user://saves/slot_01
[R37][PCO] A70/A71 生产订阅者已绑定 FlaskService + DeathService 唯一实例 | signals=7 slot=user://saves/slot_01
[R38][PCO] A48①/A76 生产订阅者已绑定 WorldMapService 唯一实例 | signals=4 slot=user://saves/slot_01（赐福网络 / 大地图进度落盘）
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
========== G3_QUIT_EXIT=0 ==========
G3_SCRIPT_ERROR_LINES=0
G3_PARSE_ERROR_LINES=0
```

### 5.2 最终 `SCRIPT ERROR` 结论（全工程 G3 grep 汇总）

```
12 份回归 SCRIPT_ERROR_LINES_SUM=0（任务②逐进程实测）
门禁三进程 G1+G2B+G3 SCRIPT_ERROR_LINES_SUM=0
FINAL SCRIPT_ERROR_LINES=0   PARSE_ERROR_LINES=0
```

- 三段门禁 G1 import / G2b V040 / G3 quit 全 `EXIT=0`；G3 日志 `WorldMapService ... signals=4` 正常装配，证明 Rank-3 PCO 并行接线当前落盘完整、无 Parse Error 竞态复现。
- 任务 ② 12 份回归 + 任务 ① V090 + 三段门禁，**逐进程 `SCRIPT ERROR=0`**；全工程 **`SCRIPT ERROR=0 / PARSE ERROR=0`** 达成。

### 5.3 并行瞬时半成品登记（如实）

本轮任务 ② 12 份回归与任务 ③ 门禁三进程**全程 `SCRIPT ERROR=0`**，**未捕获到 Rank-4 并行定稿录屏或其它 Rank 的瞬时半成品**（与 `DONE-R38B §5.3` 首次 V040/V150 瞬时 2 条 PCO:321 Parse Error 不同）。按任务单「若门禁期间遇到其它 Rank 的瞬时半成品，如实登记并在收敛后复跑」——本轮无此情形，无需收敛后复跑，未越界改任何别人的文件。

### 5.4 既有日志噪音（非 SCRIPT ERROR · 如实登记）

- `WARNING: [SaveSystem] --script 工具模式跳过自动读回`、`WARNING: [ChunkManager] 未找到 ChunkRoot`、`WARNING: [PCO] HUD / FocusService / FlaskService / DeathService 未就绪 → 绑定降级`（V090 / V040 等 `--script` 工具模式）：工具模式既有降级提示，非 `SCRIPT ERROR` / 非 FAIL。
- `WARNING: 2 ObjectDB instances were leaked at exit.`（G3 quit / V090）：与 `DONE-R38 §6.2` / `DONE-R38B §5.4` 同口径既有登记。
- 以上均**不影响 `EXIT=0` 与断言全 PASS**，未靠改断言迁就、未删该日志。

---

## 6. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① **2 条 A38 断言（J1 / J2）按 A80 逐条同步到 54 / 16-8-8**，只改期望数字 / 标签 / 注释，不删断言、不放宽判定、判定逻辑 `count == NODE_COUNT_EXPECTED` 与 `n2 == 1 and n1 == 2` 逐字不动（§2）。② **V090 复跑 47 PASS / 0 FAIL / RESULT=ALL_MATCH / EXIT=0 / SCRIPT ERROR=0**（§3）。③ **全量回归收口 12 份 605 PASS / 0 FAIL**、12×`ALL_MATCH`/`EXIT=0`；**人物 40% 断言仍 PASS**（V150 A4/A5/C2/C3/E2/E3）、**既有战斗入口仍可达 A77**（B3/F1）、A74 新基线 54/16-8-8 一致（§4）。④ 三段门禁 G1 import / G2b V040 / G3 quit 全 `EXIT=0`，最终全工程 **`SCRIPT ERROR=0 / PARSE ERROR=0`**（§5）。⑤ 只写授权 3 文件、其余只读（§9）。⑥ 回执写入 `teamwork/command_center/` 并确认中枢归档（§10）。 |
| **失败 / 未达** | ① headless 无帧缓冲，本轮**不含定稿录屏 / 目视帧**（公共契约归 Rank-4 / 总指挥，不重复录屏、不出目视结论）。② **HD-2D 全绿沿用前序未达**（A41/A52/A61/A68），本轮未触及。③ `--script` / quit 既有 `WARNING` 降级与 ObjectDB leaked 噪音如实登记（§5.4），非 SCRIPT ERROR / 非 FAIL。④ 本轮无功能回归、无瞬时半成品需收敛复跑。 |
| **需用户确认 / 待裁决** | 见 §8（共 3 组；#1 为 Rank-3 PCO 并行接线落盘确认沿用项、#2 为前序未完成沿用项、#3 为 A80 已闭环说明）。 |

---

## 7. 未完成项

1. **定稿录屏 / 目视**：按公共契约由 Rank-4 / 总指挥负责，本轮不重复录屏、不出目视结论（headless 无帧缓冲）。
2. **沿用前序未完成项**：`DONE-R38 §10 #2~#7`（大地图 2D 与既有 3D 视觉融合 / 标准相机管线、`[PLACEHOLDER]` 试玩校准、演示长距离巡航、跨 Rank 接口对齐、A38 契约同步 / HD-2D 全绿 / 真机 exe·apk 手感 / GitHub 补推等）本轮未触及。
3. **本轮无遗留功能缺陷**：V090 2 条旧基线断言已闭环（47/0），12 份回归 0 FAIL，三段门禁全绿，无需后续补跑（瞬时半成品本轮未出现）。

---

## 8. 待总指挥裁决项（如实登记，不擅改）

**待裁决 #1（沿用 · Rank-3 并行接线确认）**：`points_commit_orchestrator.gd`（Rank-3 只读）曾在 `DONE-R38B §5.3` 出现 A76 WorldMapService 接线「调用先落盘、函数定义后落盘」的瞬时 Parse Error。本轮 G3 quit 日志 `[R38][PCO] ... WorldMapService ... signals=4` 正常装配、12 份回归 + 门禁全程 `SCRIPT ERROR=0`，**未复现竞态**。请 Rank-3 / 总指挥确认该追加已定稿落盘、避免后续并行编辑再次产生竞态（Rank-1 无权修改该文件）。

**待裁决 #2（沿用项）**：`DONE-R38 §10 #2~#7`（定稿录屏目视 / 相机管线 / `[PLACEHOLDER]` 校准 / 长距离巡航 / 跨 Rank 接口 / 前序未完成项），本轮未触及，汇总时统一裁决。

**待裁决 #3（本轮已闭环说明）**：`DONE-R38B §8 待裁决 #1`（清单外第 6 份 V090 补单授权）已由本轮 **HOST 裁决 A80** 消解 —— 2 条断言已按精确改法同步、V090 47/0 `ALL_MATCH`，**无需再补单**。

---

## 9. 硬约束遵守声明

- **唯一写入方**：只写 ①~③（V090 + DONE-R38C.md + 回执）。**未改** `courtyard.tscn` / `world_scale.tres` / 既有 `.tres` / `project.godot` / 其它 `verify_*.gd` / 其它 Rank 产出（全部只读真跑）。
- **裁决 A80 边界**：2 条断言只改期望数字 / 标签 / 注释；不删断言、不放宽判定、不改判定逻辑；未靠改断言掩盖任何 FAIL（V090 2 条 FAIL 是纯旧基线过期，已如实对照改前 / 改后）。
- **Godot 真跑纪律**：全部 `extends SceneTree` 的 `--script` 模式，用 `Engine.get_main_loop() as SceneTree` 取 root、显式 `call("_ready")`、资源 `CACHE_MODE_IGNORE`（V090 沿用既有纪律，本轮未改其运行结构）；未用 `get_tree()` / 未用 `/root/...` 绝对路径；G1 已 `--headless --import` 同步。
- **零付费 / 零外部依赖 / 不启 GPU job**：仅本地 Godot 4.7.2；未 `--write-movie` 录屏 / 未调 ffmpeg / 未列任何付费项。
- **默认不刺探**：未主动扫目录做进度巡检、未新建只读探针 / 巡检脚本；Grep/Glob 均为「改后断言落盘确认 + 全量回归脚本路径定位 + 中枢归档确认」所必需的目标文件精确读取，用真跑输出判断进度。
- **不伪造产物、不谎报成功**：2 条同步以真跑 47 PASS / 0 FAIL 实证；既有 `WARNING` / ObjectDB leaked 如实登记、未隐瞒、未冒称全工程 62 个脚本全绿 / 未冒称录屏目视 / 未冒称 HD-2D 全绿。
- **不自行 git**（总指挥收尾）；**未删除 `.workbuddy` 目录**；**定稿录屏与目视由 Rank-4 / 总指挥负责，本轮不重复录屏**。

---

## 10. 回执与中枢归档确认

- 回执写入授权路径（**`teamwork/command_center/`**，非工程根）：`teamwork/command_center/ai/1/outbox/cmd-20261113-080813-761-A1.json`，四字段 `{"task_id":"cmd-20261113-080813-761-A1","ai":1,"status":"done","result":"...引用 DONE-R38C.md 实际结论..."}`。
- 中枢归档回读确认：见下方 §10.1（写后实测，如实登记）。

### 10.1 中枢归档确认（写后实测，如实登记）

- **outbox 已清空**：`teamwork/command_center/**/cmd-20261113-080813-761-A1.json` 精确回读仅命中 **1 处** = `dispatcher/receipts/cmd-20261113-080813-761-A1.json`（回执已被中枢移走归档，`outbox_count=0`）。
- **归档副本 VALID_JSON**：`teamwork/command_center/dispatcher/receipts/cmd-20261113-080813-761-A1.json` 四字段齐全 —— `task_id=cmd-20261113-080813-761-A1` / `ai=1` / `status=done` / `result` 全文与回执逐字一致。
- **`ai/1/status.json`**：`{"ai":1,"state":"idle","current_task":"","completed":71,"last_seen":"2026-11-13 08:19:40"}`（`completed` 70→71、`current_task` 清空、state idle）。
- **`dispatcher/dispatcher.log` 尾部原文**：`[2026-11-13 08:19:40] ← 1 号 AI 回执 <cmd-20261113-080813-761-A1> 完成：R38C 完成（详见 teamwork/Rank-1/DONE-R38C.md）：按 HOST 裁决 A80 把清单外第 ...`，确认 id 与派单一致、中枢已回收验证 `done`。
- **`dispatcher/ledger.jsonl` 本任务行（第 164 行）VALID_JSON**：`id=cmd-20261113-080813-761-A1` / `command=cmd-20261113-080813-761` / `ai=1` / `status=done` / `finished_at=2026-11-13 08:19:40` / `result` 开头 `R38C 完成（详见 teamwork/Rank-1/DONE-R38C.md）...` 与回执 `result` 逐字一致（**RESULT_MATCH=True**）。
