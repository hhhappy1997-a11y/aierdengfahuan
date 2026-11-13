# DONE-R38B.md · R38B 清理 A74 大改后旧基线断言（HOST 裁决 A79 越界授权）交付报告（Rank-1）

> 轮次：`R38B` ｜ 任务单 id：`cmd-20261113-002853-270-A1` ｜ 执行 AI：`1（Rank-1 引擎架构与渲染执行 AI）`
> 真源：`teamwork/Rank-1/调度任务单-latest.json`（id 核对一致；task 全文 + 裁决 A79 越界授权 + 公共契约 + 目录所有权·R38B + 交付·缺一不可）
> 基准清单：`teamwork/Rank-1/DONE-R38.md` **§10**（8 条断言逐条精确同步清单，可直接执行）
> 前序：`teamwork/Rank-1/DONE-R38.md`（R38 / A74 把 `courtyard.tscn` 从节点 41 / uv 2-1-1 改为 **54 / 16-8-8**，V040 37/37 PASS；额外复跑既有 5 份得 211 PASS / 8 FAIL，8 条全部且仅为 A38 旧基线过期断言、因不在授权清单未越权改并附 §10 清单）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`）
>
> **一句话结论**：按 DONE-R38.md §10 把 5 份回归脚本的 **8 条 A38 旧基线断言逐条同步到新基线 54 / 16-8-8**（只改期望数字 / 标签 / 注释，不删断言、不放宽判定、不改判定逻辑）；复跑 5 份得 **219 PASS / 0 FAIL**、各自 `RESULT=ALL_MATCH` / `EXIT=0`；关键回归 V040 37/37、V150 37/37 双 `ALL_MATCH`，人物 40% 断言仍 PASS、既有战斗入口仍可达（A77）；三段门禁 G1 import / G2b / G3 quit 全 `EXIT=0`，最终全工程 **`SCRIPT ERROR=0 / PARSE ERROR=0`**。**如实登记两处异常（均未靠改断言掩盖、均未越权改清单外文件）**：① 首次 V040/V150 真跑瞬时捕获 2 条 `SCRIPT ERROR`（Rank-3 `points_commit_orchestrator.gd:321` 并行接线竞态 `_release_world_map()` 定义未落盘），已定位根因、门禁复跑已自愈归零；② **清单外第 6 份** `verify_impact_feedback_v090.gd` 仍有 2 条 A38 旧基线 FAIL（45 PASS / 2 FAIL / `MISMATCH`），不在 §10 清单与 A79 授权写入范围，按硬约束**未越权同步**，列待裁决 #1 请总指挥补单裁决。

---

## 1. 交付清单（实际落地文件）

| # | 文件 | 类型 | 本轮改动 |
|---|---|---|---|
| ① | `godot/scripts/render/verify_life_runtime_v140.gd` | 修改（A79 授权） | `NODE_COUNT_EXPECTED` 41→54；A2 注释 / 标签 `41`→`54`（+R38/A74 新基线标注）。 |
| ② | `godot/scripts/render/verify_hud_layout_v100.gd` | 修改（A79 授权） | `NODE_COUNT_EXPECTED` 41→54；F 组头部注释 / F1 标签 `41`→`54`。 |
| ③ | `godot/scripts/render/verify_production_chains_v110.gd` | 修改（A79 授权） | `NODE_COUNT_EXPECTED` 41→54（A38-1 / R36-5 / R37-8 三条共用）；A38 组注释 / 三条标签 `41`→`54`；A38-2 的 2 个 `text.count` 字面量 + 标签 `2/1/1`→`16/8/8`；⑤/⑧ 注释 `41`→`54`。 |
| ④ | `godot/scripts/render/verify_focus_runtime_v130.gd` | 修改（A79 授权） | `NODE_COUNT_EXPECTED` 41→54；F 组头部注释 / F7 注释 / F7 标签 `41 / 2-1-1`→`54 / 16-8-8`；2 个 `text.count` 字面量同步。 |
| ⑤ | `godot/scripts/render/verify_parry_runtime_v120.gd` | 修改（A79 授权） | `NODE_COUNT_EXPECTED` 41→54；P 组头部注释 / P5 标签 `41 / 2-1-1`→`54 / 16-8-8`；2 个 `text.count` 字面量同步。 |
| ⑥ | `teamwork/Rank-1/DONE-R38B.md` | **新建** | 本交付报告。 |
| ⑦ | `teamwork/command_center/ai/1/outbox/cmd-20261113-002853-270-A1.json` | **新建** | 本轮回执（**`teamwork/command_center/`**，非工程根），写后经中枢归档（§10）。 |

**只读未改（硬约束）**：`courtyard.tscn`（本轮不再改）/ `world_scale.tres` / 既有 `.tres` / `project.godot` / `impact_feedback.gd` / `hd2d_fx.gd` / `hd2d_parallax.gd` / `wave_trial_director.gd`（Rank-2）/ `points_commit_orchestrator.gd`（Rank-3）/ `verify_wave_runtime_v040.gd` / `verify_bigmap_v150.gd` / 其它 Rank 产出 / **`verify_impact_feedback_v090.gd`（清单外，见 §4.3 / §8 待裁决 #1）**。

---

## 2. 8 条断言改前 → 改后逐条对照（交付要求 · 核心）

### 2.1 同步口径（裁决 A79 / 硬约束逐字遵守）

- 只改 **期望数字 / 标签 / 注释**：`NODE_COUNT_EXPECTED` 41→54、标签 / 注释里的 `41`→`54`、`uv 2/1/1`→`uv 16/8/8`、`text.count("Vector3(2, 2, 1)")`→`text.count("Vector3(16, 16, 1)")`、`text.count("Vector3(1, 1, 1)")`→`text.count("Vector3(8, 8, 1)")`。
- **不删断言、不放宽判定、不改判定逻辑**：全部 `_ck(...)` 集合与下列判定表达式**逐字不动** ——
  `count == NODE_COUNT_EXPECTED`、`uv_2x == 1 and uv_1x == 2`、`count == NODE_COUNT_EXPECTED and uv_2x == 1 and uv_1x == 2`、`n2 == 1 and n1 == 2`（V090 未改，仅作对照说明）。
- 变量名 `uv_2x` / `uv_1x`、detail 格式串、`_ck` 调用结构一律不动；仅在常量行 / 注释 / 标签末尾补最短 `R38 / A74 新基线` 标注（与 R38 同步 V040 时"补 R38 说明"同口径）。
- 新基线真值来自 `courtyard.tscn` 磁盘回读：`Vector3(16, 16, 1)` ×1（GroundPlate）、`Vector3(8, 8, 1)` ×2（TerraceLow/TerraceHigh），`[node ` 行数 54；与 V040 `node_count=54 expected=54`、V150 `B2/B7/F4` 完全一致。

### 2.2 逐条对照表（DONE-R38.md §10 清单顺序）

| # | 文件 | 断言 tag | 改前（A38 旧基线 41 / 2-1-1） | 改后（A74 新基线 54 / 16-8-8） | 判定逻辑 |
|---|---|---|---|---|---|
| 1 | `verify_life_runtime_v140.gd` | `A2 A38 courtyard.tscn 节点数 == 41` | 常量 `=41`；注释 `# A2 A38 节点数 41`；标签 `== 41` | 常量 `=54`；注释 `节点数 54`；标签 `== 54` | `count == NODE_COUNT_EXPECTED` 不动 |
| 2 | `verify_hud_layout_v100.gd` | `F1 静态 [node] 行数 == 41` | 常量 `=41`；F 组注释 `节点数 41`；标签 `== 41` | 常量 `=54`；注释 `节点数 54`；标签 `== 54` | `count == NODE_COUNT_EXPECTED` 不动 |
| 3 | `verify_production_chains_v110.gd` | `A38-1 行数 == 41` | 常量 `=41`；标签 `== 41` | 常量 `=54`；标签 `== 54` | `count == NODE_COUNT_EXPECTED` 不动 |
| 4 | `verify_production_chains_v110.gd` | `A38-2 uv 2/1/1` | `text.count("Vector3(2, 2, 1)")` / `("Vector3(1, 1, 1)")`；标签 `uv 2/1/1 原样（Vector3(2,2,1)×1 + Vector3(1,1,1)×2）` | `text.count("Vector3(16, 16, 1)")` / `("Vector3(8, 8, 1)")`；标签 `uv 16/8/8 原样（Vector3(16,16,1)×1 + Vector3(8,8,1)×2）` | `uv_2x == 1 and uv_1x == 2` 不动（仍期望 ×1 + ×2） |
| 5 | `verify_production_chains_v110.gd` | `R36-5 A38 节点数 == 41` | 注释 `# ⑤ A38 节点 41 保持`；标签 `== 41` | 注释 `节点 54 保持`；标签 `== 54` | `count == NODE_COUNT_EXPECTED` 不动 |
| 6 | `verify_production_chains_v110.gd` | `R37-8 A38 节点数 == 41` | 注释 `# ⑧ A38 节点 41 保持`；标签 `== 41` | 注释 `节点 54 保持`；标签 `== 54` | `count == NODE_COUNT_EXPECTED` 不动 |
| 7 | `verify_focus_runtime_v130.gd` | `F7 节点 41 / uv 2/1/1` | 常量 `=41`；F 组注释 `节点 41 uv 2/1/1`；标签 `节点 41 / uv 2/1/1`；2 个 `text.count` 旧字面量 | 常量 `=54`；注释 / 标签 `54 / 16/8/8`；`text.count` → `Vector3(16, 16, 1)` / `Vector3(8, 8, 1)` | `count == NODE_COUNT_EXPECTED and uv_2x == 1 and uv_1x == 2` 不动 |
| 8 | `verify_parry_runtime_v120.gd` | `P5 节点 41 / uv 2/1/1` | 常量 `=41`；P 组注释 `节点 41 uv 2/1/1`；标签 `节点 41 / uv 2/1/1`；2 个 `text.count` 旧字面量 | 常量 `=54`；注释 / 标签 `54 / 16/8/8`；`text.count` → `Vector3(16, 16, 1)` / `Vector3(8, 8, 1)` | `count == NODE_COUNT_EXPECTED and uv_2x == 1 and uv_1x == 2` 不动 |

> 说明：8 条断言共落在 **5 个 `NODE_COUNT_EXPECTED` 常量**（V110 的 #3/#5/#6 三条共用同一常量，改 1 处即覆盖 3 条）+ **3 组 uv `text.count` 字面量**（#4/#7/#8）+ 相应标签 / 注释。断言集合 **219 条未变**。

### 2.3 改后落盘实证（改后 Grep 回读，节选原文）

```
verify_life_runtime_v140.gd:30:  const NODE_COUNT_EXPECTED: int = 54  # R38 / A74 新基线（A38 旧基线 41）
verify_life_runtime_v140.gd:478: _ck("A2 A38 courtyard.tscn 节点数 == 54（...；R38 / A74 新基线 41→54）",
verify_hud_layout_v100.gd:309:   _ck("F1 courtyard.tscn 静态 [node] 行数 == 54（...；R38 / A74 新基线 41→54）",
verify_production_chains_v110.gd:277:  _ck("A38-1 courtyard.tscn 静态 [node] 行数 == 54（...）",
verify_production_chains_v110.gd:279:  var uv_2x: int = text.count("Vector3(16, 16, 1)")
verify_production_chains_v110.gd:280:  var uv_1x: int = text.count("Vector3(8, 8, 1)")
verify_production_chains_v110.gd:281:  _ck("A38-2 uv 16/8/8 原样（Vector3(16,16,1)×1 + Vector3(8,8,1)×2；...）",
verify_production_chains_v110.gd:1108: _ck("R36-5 A38 courtyard.tscn 节点数 == 54（...）",
verify_production_chains_v110.gd:1232: _ck("R37-8 A38 courtyard.tscn 节点数 == 54（...）",
verify_focus_runtime_v130.gd:505:    _ck("F7 A38 courtyard.tscn 节点 54 / uv 16/8/8 原样（...）",
verify_focus_runtime_v130.gd:503/504: text.count("Vector3(16, 16, 1)") / text.count("Vector3(8, 8, 1)")
verify_parry_runtime_v120.gd:420:    _ck("P5 A38 courtyard.tscn 节点 54 / uv 16/8/8 原样（...）",
verify_parry_runtime_v120.gd:418/419: text.count("Vector3(16, 16, 1)") / text.count("Vector3(8, 8, 1)")
```

**残留检查**：5 份脚本内 `NODE_COUNT_EXPECTED: int = 41` / `== 41` / `uv 2/1/1` / `Vector3(2, 2, 1)` / `Vector3(1, 1, 1)` 等**旧断言字面量 0 残留**（标注文字里的 `41→54` / `2-1-1→16-8-8` / `A38 旧基线 41` 为有意留痕，不在判定路径）。

---

## 3. 5 份回归复跑输出（真跑输出原文）

命令前缀统一 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/render/<name>.gd`。逐份 `SUMMARY` / `RESULT` / `EXIT` 原文：

```
========== RUN verify_life_runtime_v140 ==========
[V140] SUMMARY pass=26 fail=0 total=26 ok=true flask_source=rank2_production_unique_instance death_source=rank2_production_unique_instance
[V140] RESULT=ALL_MATCH
========== EXIT_verify_life_runtime_v140=0 ==========
========== RUN verify_hud_layout_v100 ==========
[V100HUD] SUMMARY pass=48 fail=0 total=48 ok=true
[V100HUD] RESULT=ALL_MATCH
========== EXIT_verify_hud_layout_v100=0 ==========
========== RUN verify_production_chains_v110 ==========
[V110] SUMMARY pass=75 fail=0 total=75 ok=true
[V110] RESULT=ALL_MATCH
========== EXIT_verify_production_chains_v110=0 ==========
========== RUN verify_focus_runtime_v130 ==========
[V130] SUMMARY pass=39 fail=0 total=39 ok=true focus_source=rank2_production_unique_instance
[V130] RESULT=ALL_MATCH
========== EXIT_verify_focus_runtime_v130=0 ==========
========== RUN verify_parry_runtime_v120 ==========
[V120P] SUMMARY pass=31 fail=0 total=31 ok=true parry_source=rank2_production_unique_instance
[V120P] RESULT=ALL_MATCH
========== EXIT_verify_parry_runtime_v120=0 ==========
```

**合计 219 PASS / 0 FAIL**（26+48+75+39+31 = 219；与 DONE-R38 §6.5「219 条断言集合未变」一致），5 份全部 `RESULT=ALL_MATCH` / `EXIT=0`。**0 FAIL 达成**，8 条旧基线断言同步后全部 PASS；`PASS=false` 计数 0。

---

## 4. 全量回归结果（任务 ②）

### 4.1 关键回归 V040 / V150（真跑输出原文）

```
========== RUN scripts/combat/verify_wave_runtime_v040 ==========
[V040] courtyard_node_count PASS=true | node_count=54 expected=54（+21：... + R38 大地图 13 节点）
[V040] uv_groundplate_16 PASS=true | uv1_scale=(16.0, 16.0, 1.0) expected=(16,16,1)
[V040] SUMMARY pass=37 fail=0
[V040] RESULT=ALL_MATCH
========== EXIT_scripts/combat/verify_wave_runtime_v040=0 ==========
========== RUN scripts/render/verify_bigmap_v150 ==========
[V150] A4 人物缩放计算式 character_scale == baseline × ratio PASS=true | baseline=1.600 ratio=0.400 computed=0.6400 character_scale=0.6400
[V150] A5 ★ 人物显示尺寸 == 基线 × 0.40（±容差） PASS=true | 0.6400 == 1.600 × 0.40 = 0.6400 | tol=0.0010
[V150] B2 ★ A74 新基线 node_count == 54（改前 41 → 改后 54） PASS=true | node_count=54 expected=54（+13 大地图节点）
[V150] B3 既有战斗入口 EncounterRoot / WaveTrialDirector / Hud / Camera3D 仍可达 PASS=true | enc=true wave=true hud=true cam3d=true
[V150] B7 ★ A74 新基线 uv 16/8/8（改前 2/1/1） PASS=true | plate=(16.0,16.0,1.0) low=(8.0,8.0,1.0) high=(8.0,8.0,1.0)
[V150] C2 ★ 角色显示尺寸实测：真实节点 scale == 基线 × 0.40 PASS=true | target_scales=[0.64,0.64,0.64] expected=0.6400 applied_targets=3
[V150] C3 画面像素高度对比：new/old == 0.40 PASS=true | old=2.4000m new=0.9600m ratio=0.4000
[V150] E2 HUD 角色包围盒避让几何从 world_scale.tres 读 ratio ≈ 0.40 PASS=true | ratio=0.4000
[V150] E3 新尺寸角色包围盒 == 保守保护区 × ratio PASS=true | bbox=(192.0,135.9994) guard=(480.0,339.9984) ratio=0.4000
[V150] F1 既有战斗入口 ... 仍可达（大地图为新增层） PASS=true | enc=true wave=true hud=true
[V150] F4 A74 节点数与 uv 新基线在实例侧一致（54 / 16-8-8） PASS=true | node_count=54 uv=(16.0,16.0,1.0)/(8.0,8.0,1.0)/(8.0,8.0,1.0)
[V150] SUMMARY pass=37 fail=0 total=37 ok=true
[V150] RESULT=ALL_MATCH
========== EXIT_scripts/render/verify_bigmap_v150=0 ==========
```

- **人物 40% 断言仍 PASS**：V150 A4 / A5 / C2 / C3 / E2 / E3 全 `PASS=true`（0.64 = 1.6×0.40、3 节点 scale 实测 0.64、画面像素高 2.4000m→0.9600m、ratio 0.4000）。
- **既有战斗入口仍可达（A77）**：V150 B3 / F1 全 `PASS=true`（`EncounterRoot` / `WaveTrialDirector` / `Hud` / `Camera3D` 均可寻址，大地图为新增并行层、既有 41 节点与 v0.1~v0.14 闭环不删不改）。
- **A74 新基线一致**：V040 `node_count=54` + uv 16/8/8、V150 B2 / B7 / F4 全 PASS。
- 任务 ②点名的 `verify_hud_layout_v100.gd` / `verify_production_chains_v110.gd` 已在 §3 的 5 份复跑中 0 FAIL（48/48、75/75），不重复计。

### 4.2 全量口径汇总

| 分组 | 脚本 | 结果 |
|---|---|---|
| 授权 5 份（任务 ①） | V140 / V100HUD / V110 / V130 / V120P | **219 PASS / 0 FAIL**，5×`ALL_MATCH` |
| 关键回归（任务 ②） | V040 / V150 | **37/37 + 37/37**，2×`ALL_MATCH`（40% / 战斗入口 / 新基线全 PASS） |
| 授权范围合计 | 7 份脚本 | **293 条断言 / 0 FAIL** |
| 清单外第 6 份（§4.3） | `verify_impact_feedback_v090.gd` | **45 PASS / 2 FAIL / `MISMATCH` / `EXIT=1`**（旧基线过期，未授权同步） |
| 本轮涉及全量 | 8 份脚本 | **340 条 / 2 FAIL**，2 条均为清单外 A38 旧基线、**非功能回归** |

### 4.3 清单外 V090 如实登记（不得靠改断言掩盖 / 不越权）

改后残留检查在 `scripts/render/verify_impact_feedback_v090.gd` 发现 **A38 旧基线断言**（该文件**不在 DONE-R38.md §10 的 5 份清单、不在裁决 A79 授权写入范围**）：

```
verify_impact_feedback_v090.gd:53:   const NODE_COUNT_EXPECTED: int = 41
verify_impact_feedback_v090.gd:525:  _ck("J1 courtyard.tscn 静态 [node] 行数 == 41（A38 节点数保持）", count == NODE_COUNT_EXPECTED, ...)
verify_impact_feedback_v090.gd:527:  var n2: int = _count_substr(text, "uv1_scale = Vector3(2, 2, 1)")
verify_impact_feedback_v090.gd:528:  var n1: int = _count_substr(text, "uv1_scale = Vector3(1, 1, 1)")
verify_impact_feedback_v090.gd:529:  _ck("J2 uv 2/1/1 原样：Vector3(2,2,1) ×1 + Vector3(1,1,1) ×2", n2 == 1 and n1 == 2, ...)
```

只读真跑（未改该文件）原文：

```
[V090] J1 courtyard.tscn 静态 [node] 行数 == 41（A38 节点数保持） PASS=false | count=54 expected=41
[V090] J2 uv 2/1/1 原样：Vector3(2,2,1) ×1 + Vector3(1,1,1) ×2 PASS=false | uv_2x=0 uv_1x=0
[V090] SUMMARY pass=45 fail=2 total=47 ok=false
[V090] RESULT=MISMATCH
========== V090_EXIT=1 ==========
V090_SCRIPT_ERROR_LINES=0
```

**定性**：J1 / J2 两条**全部且仅为 A38 旧基线（41 / 2-1-1）期望值过期**（实际 `count=54`、`uv_2x=0 uv_1x=0` 说明地面已改 16/8/8），与 §10 的 8 条同源、**非真实功能失败**（V090 其余 45 条全 PASS、`SCRIPT ERROR=0`）。按【目录所有权·R38B「唯一写入方 = §10 清单 5 份脚本 + DONE-R38B.md + 回执，其余一律只读不改」】**本轮未越权同步、未改任何判定、未删断言、未靠改断言掩盖**。已列 **§8 待裁决 #1**，并附与 8 条完全一致的精确改法待补单。

---

## 5. 三段门禁 + 全工程 G3 `grep SCRIPT ERROR=0`（任务 ③）

### 5.1 门禁真跑输出原文

```
========== G1 IMPORT ==========
[   0% ] first_scan_filesystem | ... [ DONE ] first_scan_filesystem
[   0% ] loading_editor_layout | ... [ DONE ] loading_editor_layout
========== G1_IMPORT_EXIT=0 ==========
G1_SCRIPT_ERROR_LINES=0
========== G2B V040 RERUN ==========
[V040] SUMMARY pass=37 fail=0
[V040] RESULT=ALL_MATCH
========== G2B_V040_EXIT=0 ==========
G2B_SCRIPT_ERROR_LINES=0
========== G3 QUIT ==========
[SaveSystem] 自动读回完成 | ... [R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=54
[R34C][PCO] 生产订阅者已绑定 HUD | signals=5 slot=user://saves/slot_01（A55 唯一权威通道）
[R38][PCO] A48①/A76 生产订阅者已绑定 WorldMapService 唯一实例 | signals=4 slot=user://saves/slot_01（赐福网络 / 大地图进度落盘）
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
========== G3_QUIT_EXIT=0 ==========
G3_SCRIPT_ERROR_LINES=0
G3_PARSE_ERROR_LINES=0
```

V150 门禁后复跑（补充确认）：

```
[V150] A5 ★ 人物显示尺寸 == 基线 × 0.40 PASS=true | 0.6400 == 1.600 × 0.40 = 0.6400
[V150] B3 既有战斗入口 ... 仍可达 PASS=true | enc=true wave=true hud=true cam3d=true
[V150] C2 ★ 角色显示尺寸实测 ... PASS=true | target_scales=[0.64,0.64,0.64] applied_targets=3
[V150] C3 画面像素高度对比 ... PASS=true | old=2.4000m new=0.9600m ratio=0.4000
[V150] F1 既有战斗入口 ... 仍可达 PASS=true | enc=true wave=true hud=true
[V150] SUMMARY pass=37 fail=0 total=37 ok=true
[V150] RESULT=ALL_MATCH
========== V150_RERUN_EXIT=0 ==========
V150_RERUN_SCRIPT_ERROR_LINES=0
V150_RERUN_PARSE_ERROR_LINES=0
```

### 5.2 最终 `SCRIPT ERROR` 结论（全工程 G3 grep）

```
G1_IMPORT_EXIT=0           G1_SCRIPT_ERROR_LINES=0
G2B_V040_EXIT=0            G2B_SCRIPT_ERROR_LINES=0  | [V040] RESULT=ALL_MATCH pass=37 fail=0
G3_QUIT_EXIT=0             G3_SCRIPT_ERROR_LINES=0  G3_PARSE_ERROR_LINES=0
V150_RERUN_EXIT=0          V150_RERUN_SCRIPT_ERROR_LINES=0  V150_RERUN_PARSE_ERROR_LINES=0
5 份授权回归 + V040 + V150 + V090 逐进程 SCRIPT ERROR=0
FINAL SCRIPT_ERROR_LINES=0   PARSE_ERROR_LINES=0
```

### 5.3 瞬时 `SCRIPT ERROR` 竞态如实登记（根因定位 · 未掩盖）

**首次**真跑 V040 / V150 时（同一批次两个进程），两处进程头部各捕获 1 条：

```
SCRIPT ERROR: Parse Error: Function "_release_world_map()" not found in base self.
   at: GDScript::reload (res://scripts/rpg/points_commit_orchestrator.gd:321)
ERROR: Failed to load script "res://scripts/rpg/points_commit_orchestrator.gd" with error "Parse error".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
ERROR: Failed to instantiate an autoload, script 'res://scripts/rpg/points_commit_orchestrator.gd' does not inherit from 'Node'.
   at: start (main/main.cpp:4539)
```

- **根因定位**：`points_commit_orchestrator.gd`（**Rank-3 所有 / 只读**）`_release()` 第 321 行调用 `_release_world_map()`；Rank-3 并行追加 WorldMapService 接线（A76，与 DONE-R38 §10 #6「Rank-3 世界地图服务并行派单」对应）时**先写入了调用、函数定义随后才落盘**，在那一瞬间整个脚本 Parse Error → autoload 加载失败。当前磁盘回读该脚本 **第 1290 行已存在 `func _release_world_map() -> void:`**，另有 `_world_map_service` / `_deferred_bind_world_map` / `bind_world_map_service` 等完整接线 —— 证明是**并行编辑的瞬时半成品状态，非持久功能缺陷**。
- **非本轮引入**：本轮 Rank-1 只改 5 份 `verify_*` 回归脚本（§1），未触碰任何 Rank-3 文件；5 份授权回归（更早一批）全程 `SCRIPT ERROR=0`。
- **自愈证据**：G1 import `SCRIPT ERROR=0`、G2b 重跑 V040 `SCRIPT ERROR=0`、G3 quit `SCRIPT ERROR=0 / PARSE ERROR=0` 且日志 `[R38][PCO] ... WorldMapService ... signals=4` 正常装配、V150 门禁后复跑 `SCRIPT ERROR=0`。
- **未掩盖声明**：未改 `points_commit_orchestrator.gd`、未改任何断言去迁就、未删该错误；如实登记并请 Rank-3 / 总指挥确认落盘完整性（§8 待裁决 #2）。

### 5.4 既有日志噪音（非 SCRIPT ERROR · 如实登记）

- `ERROR: Can't use get_node() with absolute paths from outside the active scene tree.`（`boss_controller.gd:86` `_ready`，经 `encounter_director.gd` `_grace_rest` / `_respawn_boss` 触发；V140 3 处 / V110 1 处 / V130 1 处）—— `--script` 工具模式既有绝对路径 `get_node` 告警，**非 `SCRIPT ERROR` / 非 `PARSE ERROR` / 非本轮引入 / 不影响 `EXIT=0` 与断言全 PASS**。
- `WARNING: 2 ObjectDB instances were leaked at exit.`（G3 quit）—— 与 DONE-R38 §6.2 尾注同口径既有登记。
- V040 首跑 `WARNING: [WaveTrial] 未找到 EncounterDirector ...（降级，不崩）` —— 工具模式既有降级提示，非 FAIL。

---

## 6. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① **8 条 A38 断言按 §10 清单逐条同步到 54 / 16-8-8**，只改期望数字 / 标签 / 注释，不删断言、不放宽判定、判定逻辑逐字不动（§2）。② **5 份回归复跑 219 PASS / 0 FAIL**，各自 `RESULT=ALL_MATCH` / `EXIT=0`（§3）。③ 关键回归 V040 37/37、V150 37/37 双 `ALL_MATCH`；**人物 40% 断言仍 PASS**（A4/A5/C2/C3/E2/E3）、**既有战斗入口仍可达 A77**（B3/F1）、A74 新基线 54 / 16-8-8 一致（§4.1）。④ 三段门禁 G1 import / G2b V040 / G3 quit 全 `EXIT=0`，最终全工程 **`SCRIPT ERROR=0 / PARSE ERROR=0`**（§5）。⑤ 只写授权文件、其余只读（§9）。⑥ 回执写入 `teamwork/command_center/` 并确认中枢归档（§10）。 |
| **失败 / 未达** | ① **清单外 V090 2 条 A38 旧基线 FAIL**（45 PASS / 2 FAIL / `MISMATCH` / `EXIT=1`）—— 非功能回归、非授权范围，按硬约束**未越权同步**，如实登记待裁决 #1（§4.3）。② **首次 V040/V150 瞬时 2 条 `SCRIPT ERROR`**（Rank-3 PCO:321 并行接线竞态）—— 已定位根因、门禁复跑自愈归零，非本轮 5 份脚本引入、未靠改断言掩盖（§5.3）。③ headless 无帧缓冲，本轮**不含定稿录屏 / 目视帧**（公共契约归 Rank-4 / 总指挥，不重复录屏）。④ HD-2D 全绿沿用前序未达（A41/A52/A61/A68）。 |
| **需用户确认 / 待裁决** | 见 §8（共 3 组；#1 为清单外 V090 补单授权、#2 为 PCO 并行竞态确认、#3 沿用 DONE-R38 §10 其余项）。 |

---

## 7. 未完成项

1. **V090 同步未执行**（授权边界所限）：清单外第 6 份 2 条旧基线断言未同步，若总指挥补单授权可立即按 §8 #1 的精确改法执行并复跑（预期 47/47 `ALL_MATCH`）。本轮未擅自改。
2. **定稿录屏 / 目视**：按公共契约由 Rank-4 / 总指挥负责，本轮不重复录屏、不出目视结论。
3. **沿用前序未完成项**：DONE-R38 §10 #2~#7（大地图 2D 与既有 3D 视觉融合 / 标准相机管线、`[PLACEHOLDER]` 试玩校准、演示长距离巡航、跨 Rank 接口对齐、A38 契约同步 / HD-2D 全绿 / 真机 exe·apk 手感 / GitHub 补推等）本轮未触及。

---

## 8. 待总指挥裁决项（如实登记，不擅改）

**待裁决 #1（最高优先 · 清单外第 6 份旧基线断言）**：`scripts/render/verify_impact_feedback_v090.gd` 含 A38 旧基线 `NODE_COUNT_EXPECTED=41` / J1 `== 41` / J2 `uv 2/1/1`（2 条 FAIL，见 §4.3），**不在 DONE-R38.md §10 的 5 份清单、不在裁决 A79 授权写入范围**。R38 主改工位的 §10 清单可能遗漏了该份。请总指挥裁决是否**补单授权**由 Rank-1 同步；若授权，改法与 §2 的 8 条**完全一致、只改期望数字 / 标签 / 注释、不删断言、不放宽判定**：
- `const NODE_COUNT_EXPECTED: int = 41` → `54`；
- 头部 J 组注释 / `# J) A38 不破坏（节点数 41 / uv 2/1/1 ...）` → `54 / 16/8/8`；
- J1 标签 `行数 == 41` → `== 54`；
- J2 两个 `_count_substr(text, "uv1_scale = Vector3(2, 2, 1)")` / `("uv1_scale = Vector3(1, 1, 1)")` → `Vector3(16, 16, 1)` / `Vector3(8, 8, 1)`；标签 `uv 2/1/1 ... Vector3(2,2,1)×1 + Vector3(1,1,1)×2` → `uv 16/8/8 ... Vector3(16,16,1)×1 + Vector3(8,8,1)×2`；
- 判定 `count == NODE_COUNT_EXPECTED` 与 `n2 == 1 and n1 == 2` **逐字不动**。

**待裁决 #2（Rank-3 并行接线竞态）**：`points_commit_orchestrator.gd`（Rank-3 只读）A76 WorldMapService 接线曾出现「调用先落盘、函数定义后落盘」的瞬时 Parse Error（§5.3）。当前磁盘已完整、门禁全绿；请 Rank-3 / 总指挥确认该追加已定稿落盘、避免后续并行编辑再次产生竞态（Rank-1 无权修改该文件）。

**待裁决 #3（沿用项）**：DONE-R38 §10 的 #2~#7（定稿录屏目视 / 相机管线 / `[PLACEHOLDER]` 校准 / 长距离巡航 / 跨 Rank 接口 / 前序未完成项），本轮未触及，汇总时统一裁决。

---

## 9. 硬约束遵守声明

- **唯一写入方**：只写 ①~⑦（§10 清单 5 份脚本 + DONE-R38B.md + 回执）。**未改** `courtyard.tscn`（本轮不再改）/ `world_scale.tres` / 既有 `.tres` / `project.godot` / `impact_feedback.gd` / `hd2d_fx.gd` / `hd2d_parallax.gd` / `wave_trial_director.gd`（Rank-2）/ `points_commit_orchestrator.gd`（Rank-3）/ `verify_wave_runtime_v040.gd` / `verify_bigmap_v150.gd` / `verify_impact_feedback_v090.gd`（清单外，未授权）/ 其它 Rank 产出。
- **裁决 A79 边界**：8 条断言只改期望数字 / 标签 / 注释；不删断言、不放宽判定、不改判定逻辑；未改清单外任何断言去掩盖 FAIL（V090 2 条 FAIL 如实登记）。
- **Godot 真跑纪律**：全部 `extends SceneTree` 的 `--script` 模式，用 `Engine.get_main_loop() as SceneTree` 取 root、显式 `call("_ready")`、资源 `CACHE_MODE_IGNORE`（生产脚本与 V040/V150 既有纪律）；未用 `get_tree()` / 未用 `/root/...` 绝对路径；G1 已 `--headless --import` 同步。
- **零付费 / 零外部依赖 / 不启 GPU job**：仅本地 Godot 4.7.2；未 `--write-movie` 录屏 / 未调 ffmpeg / 未列任何付费项。
- **默认不刺探**：未主动扫目录做进度巡检、未新建只读探针 / 巡检脚本；Grep 均为「改后断言落盘确认 + 根因定位」所必需的目标文件精确读取，用真跑输出判断。
- **不伪造产物、不谎报成功**：8 条同步以真跑 219 PASS / 0 FAIL 实证；V090 2 条 FAIL、首次瞬时 2 条 SCRIPT ERROR、既有 `ERROR:` / `WARNING` 均如实登记、未隐瞒、未冒称全量 0 FAIL / 未冒称录屏目视 / 未冒称 HD-2D 全绿。
- **不自行 git**（总指挥收尾）；**未删除 `.workbuddy` 目录**；**定稿录屏与目视由 Rank-4 / 总指挥负责，本轮不重复录屏**。

---

## 10. 回执与中枢归档确认

- 回执写入授权路径（**`teamwork/command_center/`**，非工程根）：`teamwork/command_center/ai/1/outbox/cmd-20261113-002853-270-A1.json`，四字段 `{"task_id":"cmd-20261113-002853-270-A1","ai":1,"status":"done","result":"...引用 DONE-R38B.md 实际结论..."}`。
- 中枢归档回读确认：见下方 §10.1（写后实测，如实登记）。

### 10.1 中枢归档确认（写后实测，如实登记）

- **outbox 已清空**：`teamwork/command_center/**/cmd-20261113-002853-270-A1.json` 精确回读仅命中 **1 处** = `dispatcher/receipts/cmd-20261113-002853-270-A1.json`（回执已被中枢移走，`outbox_count=0`）。
- **归档副本 VALID_JSON**：`teamwork/command_center/dispatcher/receipts/cmd-20261113-002853-270-A1.json` 回读四字段齐全 —— `keys=['ai','result','status','task_id']` / `task_id=cmd-20261113-002853-270-A1` / `ai=1` / `status=done` / `result_len=981`。
- **`ai/1/status.json`**：`{"ai":1,"state":"idle","current_task":"","completed":70,"last_seen":"2026-11-13 07:59:33"}`（`completed` 69→70、`current_task` 清空、state working→idle）。
- **`dispatcher/dispatcher.log` 尾部原文**：`[2026-11-13 07:59:33] ← 1 号 AI 回执 <cmd-20261113-002853-270-A1> 完成：R38B 完成：按 teamwork/Rank-1/DONE-R38.md §10 清单把 5 份回归脚本的 8 条 A...`，确认 id 与派单一致、中枢已回收验证 `done`。
- **`dispatcher/ledger.jsonl` 本任务行 VALID_JSON**：`LEDGER_MATCH_LINES=1` / `id=cmd-20261113-002853-270-A1` / `command=cmd-20261113-002853-270` / `ai=1` / `status=done` / **`RESULT_MATCH=True`**（与回执 `result` 逐字一致）。
