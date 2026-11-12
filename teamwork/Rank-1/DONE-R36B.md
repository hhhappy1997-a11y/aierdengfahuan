# DONE-R36B.md · R36B / v0.13.1「补齐第二战技真实可达」交付报告（Rank-1）

> 轮次：`R36B` ｜ 任务单 id：`cmd-20261112-175103-031-A1` ｜ 执行 AI：`1（Rank-1 引擎架构与渲染执行 AI）`
> 真源：`teamwork/Rank-1/调度任务单-latest.json`（`task` 全文 + 总指挥 A67 目视结论 + 公共契约 + 目录所有权，HOST 裁决 A69）
> 前序：`teamwork/Rank-1/DONE-R36.md`、`teamwork/Rank-2/DONE-R36.md` §3（FocusService 接口与 arts 结构）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
>
> **一句话结论**：R36B 四块任务全部真跑完成 —— **P0 玩法缺口已修**：`hud.gd` / `encounter_director.gd` 接真实 `_unhandled_input(R)`，从 A54 唯一 `wave.get_focus_service()` 只读 `focus_rules.tres` 的 arts 列表循环切换当前战技；HUD 新增独立分区真实节点 `ProdArtLabel` 显示「当前战技：辉石魔砾 / 狮子斩」；**Q 改为释放当前选中 art_id**；切换不重置 FP / 冷却、不误触其它键。`presentation.gd` 只追加 4 个真实 R 注入帧点，450 帧 headless 逻辑真跑中**狮子斩 `lion_slash` 成功释放 3 次**（`fp_cost=35 / damage=45 / poise=40`），`hd2d_fx.gd` 的 `[FocusFX]` 生产节点订阅 `focus_spent(signals=4)`，**暖金斩击弧链路真实触发**。V130 保留既有 28 条扩展至 **39/39**、V100HUD 保留 40 条扩展至 **44/44**，V110 66/66、V120P 31/31 四份全 `RESULT=ALL_MATCH`。三段门禁 G1/G2a(7)/G2b(4)/G3 全 `EXIT=0`、全工程 16 段日志 `SCRIPT ERROR=0 / PARSE_ERROR=0`；A38 节点 **41** / uv **2/1/1** 不变；9 份既有 `.tres` + `focus_rules.tres` md5 与 DONE-R36 逐字一致。回执已写入并经中枢归档（§10）。**未完成 / 待裁决**：定稿录屏由总指挥本轮亲自重跑并目视（本轮不含新 MP4 / 抽帧 / 目视帧）；HD-2D 全绿沿用未达（2D 近似）。

---

## 1. 交付清单（实际落地文件）

| # | 文件 | 类型 | 本轮改动 |
|---|---|---|---|
| ① | `godot/scripts/hud.gd` | 修改（Rank-1 唯一写入） | 新增独立分区锚点 `ANCHOR_ART` / `get_current_art_rect()`；`set_layout_viewport()` 联动 `_r36b_apply_art_rect()`；`ProductionMechanismsLayer` 新建真实节点 `ProdArtLabel`；`_process_r32_keys` 加 R 分支（A46 单一仲裁者）；`get_focus_hud_view()` 追加 5 个只读 key（既有 14 个逐字不动）；`request_focus_skill()` 改用 `get_current_art_id()`（Q 释放当前选中）、成功日志追加 `art=%s`；新增 R36B 段：`_r36b_sync_art_ids` / `_r36b_art_title` / `get_current_art_id` / `get_current_art_view` / `request_art_switch`（唯一权威入口，event 实例幂等去重 + 过滤 release/echo）/ `_try_art_switch_input` / `_r36b_apply_art_rect` / `_r36b_refresh_art`。**既有 6 信号 / 14 个 HUD 视图 key / Q 判定分支 / 普通攻击判定 / 输出格式逐字不动，未新增任何信号。** |
| ② | `godot/scripts/combat/encounter_director.gd` | 修改（Rank-1 唯一写入） | `_unhandled_input` 追加 R 分支转发 HUD 唯一权威入口；新增 `_r36_is_r()`（**只认 press，过滤 release/echo**，修复双切换）/ `_r36_request_art_switch()`。既有 roll/light/heavy/interact/Q 判定逐字不动。 |
| ③ | `godot/test/presentation.gd` | 修改（Rank-1 唯一写入） | 头部加 R36B rationale；新增 `KEY_R_CODE=82` + `R36B_SWITCH_FRAMES=[45,165,285,405]`；`_drive_real_input` 末尾**只追加** ⑭ 真实 R 键 `Input.parse_input_event` 注入。既有 R28/R34/R35/R36 常量数值、`[PLACEHOLDER]` 数值、Q/J/K 注入节奏逐字不动，不回退演示驱动。 |
| ④ | `godot/scripts/render/verify_focus_runtime_v130.gd` | 修改（扩展，既有 28 条不删不放宽） | 追加 S 组 11 条（S0/S1/S2a/S2a2/S2b/S3/S4a/S4b/S5/S6/S7）+ `_svc_art_row` / `_svc_cooldown` / `_press_r` / `_art_view` / `_near` helper + `KEY_R` / `ART_LABEL_NAME` 常量。**28 → 39 条**。 |
| ⑤ | `godot/scripts/render/verify_hud_layout_v100.gd` | 修改（扩展，既有 40 条不删不放宽） | 追加 L 组 4 条（L1/L2/L3/L4）+ `_l_blocks` helper。**40 → 44 条**。 |
| ⑥ | `teamwork/Rank-1/DONE-R36B.md` | 新增 | 本交付报告。 |
| ⑦ | `teamwork/Rank-1/r36b_*.log`（16 份） | 新增 | 三段门禁 + 4 回归 + 450 帧演示逻辑帧真跑日志原文留档（授权目录内）。 |
| ⑧ | `teamwork/command_center/ai/1/outbox/cmd-20261112-175103-031-A1.json` | 新增 | 本轮回执（**teamwork/command_center/**，非工程根），写后经中枢归档（§10）。 |

**只读未改（硬约束）**：`wave_trial_director.gd` / `focus_rules.tres` / `focus_service.gd` / `focus_config.gd` / `points_commit_orchestrator.gd` / `hd2d_fx.gd` / `impact_feedback.gd` / `project.godot` / `courtyard.tscn` / `verify_production_chains_v110.gd` / `verify_parry_runtime_v120.gd`（仅复跑不改）/ 全部既有 `.tres` / 素材 / 其它 Rank 产出。

---

## 2. 四块任务实现说明

### 2.1 任务① 运行时接线（A69 裁决：R 键切换）

**A54 唯一实例 / 只读数据表**：HUD `_r36b_sync_art_ids()` 只调 A54 唯一 `FocusService.get_art_ids()` 读 arts 列表；`_r36b_art_title()` 只调 `get_config().get_art_by_id(id)["title"]` 读中文名（缺失回落 art_id、不崩）。**绝不 new 第二个 FocusService、绝不写 `.tres`、绝不硬编码任何战技 id / 数值**。V130 F3（三方同一真实 Object）+ S 组全部复用同一 `_focus` 实证。

**单一事实源**：当前选中索引 `_r36b_art_index` 只存在 HUD（Q 的权威判定者）；HUD `_process_r32_keys(R)` 与 ENC `_unhandled_input(R)` 都转发到 `request_art_switch(event)` 唯一入口，靠 `event.get_instance_id()` 幂等去重（ENC+HUD 双接 R 不重复切换）。

**真实输入链**：`R`（物理键码 82）→ 两文件各自 `_unhandled_input` 接 R → `hud.request_art_switch()` → 只读 arts 列表 → `index = (index+1) % count` → 刷新 `ProdArtLabel`「当前战技：XXX」。`Q` → `request_focus_skill()` → `get_current_art_id()`（默认 `arts[0]`，与既有行为逐字等价；R 切换后取当前 index）→ 真实 `FocusService.spend_fp(art_id)`。

**e) 切换不重置 FP / 冷却**：`request_art_switch()` 全程只读服务，**不调** `spend_fp / tick / on_grace_rest / reset`，不改 `_r36_fp` / `_r36_cooldown` 镜像。V130 S5 实证 `fp 65.0 -> 65.0`、`cd(lion_slash) 1.800 -> 1.800`。

**c) HUD 战技名避让**：独立归一化锚点 `ANCHOR_ART = Rect2(0.01875, 0.63000, 0.27813, 0.04167)`，真实节点 `ProdArtLabel` 按 `_scaled_rect()` 定位，`set_layout_viewport()` 联动 `_r36b_apply_art_rect()`；**不并入 `get_layout_rects()` 的 6 分区**（保护 V100HUD A1「size()==6」既有断言）。V100HUD L2 实测 15 块文字/面板包围盒 `worst_overlap=0.0000 px²`、L3 四档降级全 `text_ov=0.00`、V130 S6 真实节点与 FP 条 `intersection=0`。

**修复的真实 bug（真跑发现，非纸面设计）**：初版 ENC 的 R 分支沿用 Q 写法未过滤 `release` 事件 —— Q 有「成功后冷却」兜底使 release 转发被 `cooldown` 拒绝，但切换没有冷却保护，同一帧会**双切换**（狮斩→魔砾），暖金斩击弧便不出现。首轮 450 帧真跑实证「R 注入 4 次 / HUD 切换 8 次 / index 1→0」。修法：ENC `_r36_is_r()` 加 `k.pressed and not k.echo`，HUD `request_art_switch()` 开头再加一层 release/echo 防御。复跑实证「R 注入 4 次 / HUD 切换 4 次」，`art=lion_slash` 命中 3 次。

### 2.2 任务② 演示覆盖

只追加 4 个真实 `Input.parse_input_event` 的 R 注入帧点 `[45, 165, 285, 405]`，均落在相邻两个 Q 周期帧（f=30,60,90,…,420）之间，保证「R 先生效 → 紧随的 Q 释放当前选中」。既有 ⑪ Q 注入 / ⑫ J 收束 / ⑬ K 收束 节奏与全部 `[PLACEHOLDER]` 数值逐字不动；不写 `Label.text`、不调 `debug_*`、不显式 `apply_hit / on_wave_cleared / tick / poll`、不建动态可见层、不回退 R34 已移除的演示驱动。

450 帧 headless 逻辑真跑（`--fixed-fps 30 --quit-after 450`，**不带 `--write-movie`、不算录屏 / 不启 GPU job**）：`PRESENTATION_LOGIC_EXIT=0`、时间线完成 `frame=450`、`SCRIPT ERROR=0`。时序实证（日志行号）：

```
131:[R36][HUD] 真实 Q → 战技命中 | art=glintstone_pebble ... cost=12 base=18 poise=8.0
151:[R36B][INPUT] frame=45 真实按键 R(KEY_R=82) ... request_art_switch()
152:[R36B][HUD] R 切换战技 | index=1/2 art=lion_slash 当前战技：狮子斩
171:[R36][HUD] 真实 Q → 战技命中 | art=lion_slash ... cost=35 base=45 poise=40.0 ★暖金斩击弧
243:[R36][HUD] 真实 Q → 战技命中 | art=lion_slash ... cost=35 base=45 poise=40.0 ★
337:[R36B][INPUT] frame=165 真实按键 R ...
338:[R36B][HUD] R 切换战技 | index=0/2 art=glintstone_pebble 当前战技：辉石魔砾
362:[R36][HUD] 真实 Q → 战技命中 | art=glintstone_pebble ... cost=12 base=18 poise=8.0
...
493:[R36B][HUD] R 切换战技 | index=1/2 art=lion_slash 当前战技：狮子斩
536:[R36][HUD] 真实 Q → 战技命中 | art=lion_slash ... cost=35 base=45 poise=40.0 ★
762:[R36][HUD] 真实 Q → 战技命中 | art=glintstone_pebble ... final=24(×1.35)（尾帧连击倍率推进）
```

`[R36][FocusFX] 绑定唯一 FocusService 成功 fx_node=FXBloom getter_owner=Hud signals=4（A54 复用 get_focus_service，不自建）` —— `hd2d_fx.gd` 生产节点订阅 `focus_spent`，其 `_draw_focus_fx()` 以 `warm = (_focus_fx_art == "lion_slash")` 程序化 `draw_arc` 画暖金大弧（`#FFD27A / #F0A94C / #FFF0C2`）。故 `spend_fp("lion_slash")` 成功即触发暖金斩击弧，**链路真实可达、演示已覆盖**（逻辑真跑口径；实机画面目视由总指挥定稿录屏确认，§7）。

统计：R 注入 4 / HUD 单切 4 / HUD 战技命中 9（狮斩 3 + 魔砾 6）/ ENC 生产消费 9 / 战技拒绝 19（冷却 / 专注不足）。

### 2.3 任务③ 真实可达回归

- **V130（主回归）**：`extends SceneTree`，`Engine.get_main_loop() as SceneTree` 取 root、显式 `call("_ready")` / `_r34_bootstrap()`、`CACHE_MODE_IGNORE`、connect 去重 + `_finish()` disconnect 释放；**不加载 `presentation.gd`**（F8 运行时树零 presentation 节点）、**不在验证脚本内模拟编排**。新增 S 组以真实 R/Q 输入驱动生产唯一实例，断言「R 切换 → 当前战技变化」「两战技各自 fp_cost/damage/poise_damage 按表生效」「Q 释放当前选中」「R 不误触其它键」「切换不重置 FP/冷却」「HUD 战技名包围盒不与 FP 条/其它文字相交」「HUD 文本随切换变化」。
- **V100HUD**：新增 L 组，读 `ProdArtLabel` 真实节点 `get_global_rect()`，断言与 FP 条 / 连击评价带 / 弹反预兆带 / 6 分区 / 赐福成长标题行两两不相交 + 四档降级不出界 / 不遮角色 + 与 `get_current_art_rect()` 一致。
- 两个既有脚本（V110 / V120P）**只读复跑**，断言不删不放宽，全 `RESULT=ALL_MATCH`。

### 2.4 任务④ 门禁

三段门禁 G1 `--import` / G2a `--check-only --script`（7 件）/ G2b `--headless --script`（4 回归）/ G3 `--headless --quit` 全 `EXIT=0`；全工程 16 段日志 `SCRIPT ERROR=0 / PARSE_ERROR=0`；A38 静态 + G3 运行时 `node_count=41` / uv `2/1/1`；既有 `.tres` md5 零改动。

---

## 3. 键位表（改前 → 改后，任务①f）

| 物理键（keycode） | 改前（R36 / v0.13.0） | 改后（R36B / v0.13.1） | 备注 |
|---|---|---|---|
| `J` (74) | `light_attack` 轻攻击 | **不变** | EncounterDirector `_request_action` |
| `Space` (32) | `roll` 翻滚 | **不变** | 同上 |
| `K` (75) | 精准弹反 `request_parry` | **不变** | HUD R32 键路径 |
| `F` (70) | 处决 `request_execution` | **不变** | HUD R32 键路径 |
| `Q` (81) | 战技：固定释放 `arts[0]` 辉石魔砾（冷蓝） | **战技：释放【当前选中】art_id** | `request_focus_skill()` → `get_current_art_id()`；默认仍 `arts[0]`，既有行为不回退 |
| `E` (69) | `interact`（赐福休息 / 兑换面板开关） | **不变** | — |
| `1` / `2` / `3` (49/50/51) | 兑换选项 / 赐福抉择三选一 | **不变** | R32 状态隔离 |
| `Tab` (4194306) | 赐福图鉴开关（A46 单一仲裁者） | **不变** | — |
| **`R` (82)** | **【无绑定 / 空闲】** | **【新增】战技切换：在 `focus_rules.tres` 的 arts 间循环；HUD 显示当前战技名** | A69 裁决；HUD + ENC 双接，event 实例幂等去重 |

**冲突核验**：`R=82` 与既有 `J=74 / Space=32 / K=75 / F=70 / Q=81 / E=69 / 1=49 / 2=50 / 3=51 / Tab=4194306` 全部不同；两文件按 `physical_keycode / keycode` 精确匹配分支，无 InputMap action `"R"` 占用；V130 S4a/S4b 实证「按 R 不释放战技、不扣 FP、不处决、不弹反、不翻图鉴、不触发兑换」。

---

## 4. 两战技各自实证（数值全部来自 `focus_rules.tres`，只读、md5 不变）

| 战技 | `id` | `title` | `fp_cost` | `cooldown_sec` | `damage` | `poise_damage` | V130「按表生效」 | 450 帧演示命中 |
|---|---|---|---|---|---|---|---|---|
| 辉石魔砾（低耗远程 · 冷蓝弹道） | `glintstone_pebble` | 辉石魔砾 | 12.0 | 0.6 | 18.0 | 8.0 | **S2b PASS**（`result` 与 `table` 逐项相等） | **6 次** |
| 狮子斩（高耗高削韧 · 暖金斩击弧） | `lion_slash` | 狮子斩 | 35.0 | 1.8 | 45.0 | 40.0 | **S2a PASS**（`result` 与 `table` 逐项相等） | **3 次** |

**V130 S2a / S2b 原文**（真实 `spend_fp` 返回 vs 数据表行逐项比对）：

```
[V130] S2a ★ 狮子斩 fp_cost / damage / poise_damage 按表生效（Q 释放当前选中 arts[1]） PASS=true | result={ "ok": true, "reason": "ok", "art_id": "lion_slash", "title": "狮子斩", "fp_cost": 35.0, "damage": 45.0, "poise_damage": 40.0, "fp_remaining": 65.0, "cooldown_remaining": 1.8, "spend_count": 1, "config_present": true } table={ "cooldown_sec": 1.8, "damage": 45.0, "fp_cost": 35.0, "id": "lion_slash", "poise_damage": 40.0, "title": "狮子斩" }
[V130] S2a2 ★ focus_spent 广播 art_id=arts[1]（hd2d_fx 暖金斩击弧 warm 判定条件成立） PASS=true | focus_spent_signals=1 art=lion_slash
[V130] S2b ★ 辉石魔砾 fp_cost / damage / poise_damage 按表生效（切回 arts[0] 后 Q 释放当前选中） PASS=true | result={ "ok": true, "reason": "ok", "art_id": "glintstone_pebble", "title": "辉石魔砾", "fp_cost": 12.0, "damage": 18.0, "poise_damage": 8.0, "fp_remaining": 88.0, "cooldown_remaining": 0.6, "spend_count": 1, "config_present": true } table={ "cooldown_sec": 0.6, "damage": 18.0, "fp_cost": 12.0, "id": "glintstone_pebble", "poise_damage": 8.0, "title": "辉石魔砾" }
[V130] S3 ★ Q 释放当前选中战技（非硬编码 arts[0]）：R→arts[1] 后 Q=arts[1]、R→arts[0] 后 Q=arts[0] PASS=true | R→lion_slash / R→glintstone_pebble
```

`focus_rules.tres` md5 = `289fd4f08424658d9625fd3ac3d93bfd`（与 DONE-R36 逐字一致，本轮只读未改）；两战技全部数值仍为 `[PLACEHOLDER]`、调参唯一入口在 Rank-2 的表，本轮未擅改。

---

## 5. 真跑输出原文

命令前缀统一 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；日志留档 `teamwork/Rank-1/r36b_*.log`。

### 5.1 三段门禁 EXIT（原文）

```
G1_IMPORT_EXIT=0
G2A_hud_EXIT=0                              G2A_encounter_director_EXIT=0
G2A_presentation_EXIT=0                     G2A_verify_focus_runtime_v130_EXIT=0
G2A_verify_hud_layout_v100_EXIT=0           G2A_verify_production_chains_v110_EXIT=0
G2A_verify_parry_runtime_v120_EXIT=0
G2B_verify_focus_runtime_v130_EXIT=0        G2B_verify_hud_layout_v100_EXIT=0
G2B_verify_production_chains_v110_EXIT=0    G2B_verify_parry_runtime_v120_EXIT=0
G3_QUIT_EXIT=0
PRESENTATION_LOGIC_EXIT=0（450 帧 headless 逻辑帧真跑，日志 823 行）
```

### 5.2 全工程 `SCRIPT ERROR` / `PARSE ERROR` grep（16 段日志，原文）

```
r36b_g1_import.log                                   SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_g2a_encounter_director.log                      SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_g2a_hud.log                                     SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_g2a_presentation.log                            SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_g2a_verify_focus_runtime_v130.log               SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_g2a_verify_hud_layout_v100.log                  SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_g2a_verify_parry_runtime_v120.log               SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_g2a_verify_production_chains_v110.log           SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_g3_quit.log                                     SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_presentation_logic.log                          SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_v100hud.log                                     SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_v130.log                                        SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_verify_verify_focus_runtime_v130.log            SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_verify_verify_hud_layout_v100.log               SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_verify_verify_parry_runtime_v120.log            SCRIPT_ERROR=0 PARSE_ERROR=0
r36b_verify_verify_production_chains_v110.log        SCRIPT_ERROR=0 PARSE_ERROR=0
FINAL SCRIPT_ERROR_LINES=0  PARSE_ERROR_LINES=0
```

### 5.3 四个回归 SUMMARY / RESULT（原文）

```
[V130] SUMMARY pass=39 fail=0 total=39 ok=true focus_source=rank2_production_unique_instance
[V130] RESULT=ALL_MATCH
[V100HUD] SUMMARY pass=44 fail=0 total=44 ok=true
[V100HUD] RESULT=ALL_MATCH
[V120P] SUMMARY pass=31 fail=0 total=31 ok=true parry_source=rank2_production_unique_instance
[V120P] RESULT=ALL_MATCH
[V110] SUMMARY pass=66 fail=0 total=66 ok=true
[V110] RESULT=ALL_MATCH
```

**PASS/FAIL 汇总**：`39 + 44 + 31 + 66 = 180 PASS / 0 FAIL`，四份 `RESULT=ALL_MATCH`。V130 既有 28 条、V100HUD 既有 40 条逐条保留、未删未放宽。

### 5.4 V130 S 组 11 条逐条原文（新增）

```
[V130] ==== S 组 R36B：R 切换 / 两战技按表生效 / Q 释放当前选中 / 不误触 / 不重置 FP·冷却 / 包围盒避让 ====
[V130] S0 ★ focus_rules.tres arts 恰 2 个战技（只读 A54 唯一实例 get_art_ids） PASS=true | art_ids=["glintstone_pebble", "lion_slash"]
[V130] S1 ★ R 切换 → 当前战技变化（index 循环 +1、art_id/title 从 arts[0] 变为 arts[1]，title 只读表） PASS=true | glintstone_pebble(index=0,辉石魔砾) -> lion_slash(index=1,狮子斩)
[V130] S2a ★ 狮子斩 fp_cost / damage / poise_damage 按表生效（Q 释放当前选中 arts[1]） PASS=true | result={ ... "art_id": "lion_slash", "fp_cost": 35.0, "damage": 45.0, "poise_damage": 40.0 ... } table={ ... "fp_cost": 35.0, "damage": 45.0, "poise_damage": 40.0 ... }
[V130] S2a2 ★ focus_spent 广播 art_id=arts[1]（hd2d_fx 暖金斩击弧 warm 判定条件成立） PASS=true | focus_spent_signals=1 art=lion_slash
[V130] S2b ★ 辉石魔砾 fp_cost / damage / poise_damage 按表生效（切回 arts[0] 后 Q 释放当前选中） PASS=true | result={ ... "fp_cost": 12.0, "damage": 18.0, "poise_damage": 8.0 ... } table={ ... }
[V130] S3 ★ Q 释放当前选中战技（非硬编码 arts[0]）：R→arts[1] 后 Q=arts[1]、R→arts[0] 后 Q=arts[0] PASS=true | R→lion_slash / R→glintstone_pebble
[V130] S4a ★ R 不误触 Q（不释放战技 / 不扣 FP / 不发 focus_skill_performed·rejected） PASS=true | fp=100.0 spend=0 performed=0 rejected=0 switch_count=3
[V130] S4b ★ R 不误触 F 处决 / K 弹反 / Tab 图鉴 / 数字键兑换（关键计数与面板态不变） PASS=true | exec=0 parry=0 codex=false buy=0
[V130] S5 ★ 切换不重置 FP / 冷却（FP 余额不变、原战技 cooldown_remaining 不归零、不多扣一次） PASS=true | fp 65.0 -> 65.0 spend=1 cd(lion_slash) 1.800 -> 1.800
[V130] S6 ★ HUD 战技名包围盒不与 FP 条 / 连击评价带 / 弹反预兆带 / 其它文字相交 PASS=true | art_rect=[P: (24.0, 453.6), S: (356.0064, 30.0024)] blocks_worst=0.0000 px² node=true text=[当前战技：辉石魔砾]
[V130] S7 ★ HUD 显示「当前战技」真实节点文本随 R 切换变化、title 来自数据表（非硬编码） PASS=true | 辉石魔砾 -> 狮子斩 | node_text=[当前战技：狮子斩]
```

### 5.5 V100HUD L 组 4 条逐条原文（新增）

```
[V100HUD] ==== L 组 R36B 当前战技名真实节点 rect 避让断言 ====
[V100HUD] L1 生产常驻可见层含 R36B「当前战技」真实节点 ProdArtLabel（hud.gd 自建，非演示构造） PASS=true | node=true text=[当前战技：—]
[V100HUD] L2 ★ HUD 战技名包围盒不与 FP 条 / 连击评价带 / 弹反预兆带 / 其它文字相交 PASS=true | art_rect=[P: (24.0, 453.6), S: (356.0064, 30.00241)] blocks=15 worst_overlap=0.0000 px²
[V100HUD] L3 1280x720 + 三档降级：战技名节点不出界 / 不遮中央角色 / 不与任一文字包围盒相交 PASS=true | ["1280x720:... text_ov=0.00", "960x540:... text_ov=0.00", "640x360:... text_ov=0.00", "480x270:rect=[P: (9.0, 170.1), S: (133.5024, 23.0)] bounded=true char_ov=0.00 text_ov=0.00"]
[V100HUD] L4 战技名真实节点 rect 与独立分区锚点 get_current_art_rect() 一致（按锚点定位） PASS=true | node_rect=[P: (24.0, 453.6), S: (356.0064, 30.00241)] anchor_rect=[P: (24.0, 453.6), S: (356.0064, 30.0024)]
```

> **如实登记（一轮 FAIL → 修布局、不放宽断言）**：L3 首轮在 `480x270` 档 `PASS=false | text_ov=567.55`（SUMMARY 43/44）。根因：真实 `Label` 约 23px 最小内容高度在低档撑开，初版 `ANCHOR_ART y=0.58333(≈157.5)` 与 FP 条节点 `(138.75~161.75)` 交叠 567px²。修法是把锚点下移到 `y=0.63(≈170.1)`（改 `hud.gd` 布局值，写清 rationale），**未放宽任何断言**；复跑 L3 四档全 `text_ov=0.00`、44/44 全绿。

### 5.6 A38 / G3 主场景实证 / .tres md5（原文）

```
===== G3 主场景实证 =====
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
[R36][WaveTrial] 专注值/战技生产订阅者已装配：FocusService 唯一实例 + 4 信号 connect（A48①/A54）
[R36][PCO] A66 生产订阅者已绑定 FocusService 唯一实例 | signals=3 slot=user://saves/slot_01
[R36][HUD] 生产装配 | focus_unique_instance=true A65/回满生产订阅=true（A48①/A54，不自建第二实例）
[R36][FocusFX] 绑定唯一 FocusService 成功 fx_node=FXBloom getter_owner=Hud signals=4（A54 复用 get_focus_service，不自建）
[R36][ENC] 生产装配 | focus_unique_instance=true focus_skill_subscribed=true（A48① 生产运行时订阅者，A54 不自建第二实例）
===== A38 静态只读核对 =====
[node 行数=41]  uv2/2/1=1  uv1/1/1=2
===== 既有 .tres md5（与 DONE-R36 记录逐字一致）=====
wave_trial.tres 793b6daa7c7730feed1a3f849701d58a   boon_draft.tres 44d8b941f8b28dfa2931984707b5c53e
trial_modifiers.tres 7e9e5ac7d35d8d15171e69975ac3356d   stagger_rules.tres 49ce964e7c268804efbf2f20bec6565d
combo_rules.tres a1ad4635ae0342c696fe650eb13d4930   player_actions.tres 75390f71c002ef3cea6392a397ec267c
boss_01_margit.tres f2f71c7019c64e6c631c553887376c7d   enemy_01_limgrave_soldier.tres 9de25e0229d1c2c55a1740d2f838ad79
parry_rules.tres 5d560e57c5c0fdfdec3f20b3f3535728   focus_rules.tres 289fd4f08424658d9625fd3ac3d93bfd
```

> 既有 WARNING / ERROR 如实登记（非本轮引入、非 `SCRIPT ERROR`、不影响 `EXIT=0`）：`--script` 工具模式 `SaveSystem` 跳过自动读回、`ChunkManager` 未找到 ChunkRoot、`PointsCommitOrchestrator` autoload 降级、`2 ObjectDB instances were leaked at exit` 等，与 DONE-R36 §3 尾注同口径。
>
> **一处既有显示口径观察（非本轮引入、未改）**：演示日志 `[R36][HUD] 真实 Q → 战技命中 | ... fp 53->53 cost=35 ...` 中 `fp_before` 显示为施放后值，是既有 R36 `request_focus_skill()` 先 `poll_focus_service()` 再取 `R36_KEY_FP_BEFORE` 回落 `_r36_fp` 的打印时序所致（该字段仅用于日志与 `focus_skill_performed` 信号展示，**真实 FP 扣减由 A54 唯一 FocusService 权威判定**）。V130 Q2 / S2a / S2b / S5 已逐项实证服务 FP 真实扣减（100→88、100→65、65→65 切换不变）。本轮按「不改既有输出格式」硬约束**未改**该打印，如实登记、不冒充、列为待裁决项 §8.7。

---

## 6. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① A69 落地：`hud.gd` / `encounter_director.gd` 真实 `_unhandled_input(R)` 循环切换两战技，HUD 新增 `ProdArtLabel` 独立分区显示当前战技名（锚点/包围盒避让），Q 释放当前选中 art_id；只读 A54 唯一 FocusService、不自建第二实例、不改 `[PLACEHOLDER]` 数值、不重置 FP/冷却、不误触其它键；键位表改前→改后已列（§3）。② 演示只追加真实 R 注入节奏、既有数值/节奏逐字不动、不回退演示驱动；450 帧逻辑真跑狮子斩成功释放 3 次、辉石魔砾 6 次、`[FocusFX]` 生产订阅 `focus_spent`，暖金斩击弧链路真实触发。③ V130 28→39、V100HUD 40→44，V110 66 / V120P 31，四份全 `RESULT=ALL_MATCH`（180 PASS / 0 FAIL），既有断言不删不放宽。④ 三段门禁全 `EXIT=0`、全工程 `SCRIPT ERROR=0 / PARSE_ERROR=0`。⑤ A38 节点 41 / uv 2/1/1 不变；9 份既有 `.tres` + `focus_rules.tres` md5 与 DONE-R36 逐字一致。⑥ A48 四项逐条达标（§7）。⑦ 只写授权文件、其余只读。⑧ 回执写入并确认中枢归档（§10）。 |
| **失败 / 未达** | ① **本交付不含新录屏 / 目视帧**：按公共契约「定稿录屏由总指挥本轮亲自重跑并目视，本轮不重复录屏」；暖金斩击弧 / 「当前战技」HUD 的实机画面观感待总指挥目视确认，逻辑真跑只证明生产链路触发、不冒称画面目视通过。② **HD-2D 全绿未达**（沿用 A41/A52/A61/A68）：仍是 2D `_draw()` / screen-reading shader 近似、2D tile 地面、billboard 精灵，无真 DoF / 真体积光 / SSR / Forward+，不包装成全绿。③ 连击 D→A→S 完整序列 / S 级收束爆发未在录屏目视确认（本轮逻辑真跑尾帧倍率推进到 ×1.35，与 A67 目视 B 级一致）。 |
| **需用户确认 / 待裁决** | 见 §8。 |

---

## 7. A48 四项逐条自查（硬要求）

| # | A48 条款 | 逐条自查结论 | 实证 |
|---|---|---|---|
| ① | 新信号必须有**生产运行时订阅者** | **达标（且本轮未新增任何信号）**。R 切换只改 HUD 本地索引 + 刷新真实节点，不引入新信号，故不触发该约束；既有 6 个信号的生产订阅者全部保持：G3 日志 `[R36][ENC] focus_skill_subscribed=true`、`[R36][HUD] focus_unique_instance=true A65/回满生产订阅=true`、`[R36][WaveTrial] ... 4 信号 connect`、`[R36][FocusFX] ... signals=4`；V130 F4/F4b/F4c/F5 全 PASS。 | G3 装配日志、V130 F 组、S2a2（focus_spent 广播） |
| ② | 遵守 A54 唯一实例 | **达标**。`wave_trial_director.get_focus_service()` 装配唯一 FocusService；HUD `_r36_focus` / ENC `_r36_focus` / wave 三方同一真实 Object（V130 F3 `same=true`、`focus_source=rank2_production_unique_instance`）；R 切换的 `_r36b_sync_art_ids()` / `_r36b_art_title()` 只读该实例，绝不 `new` 第二个。 | V130 F3/F3b、S 组全部复用 `_focus`、G3 `focus_unique_instance=true` |
| ③ | 不加载 `presentation.gd`、不在验证脚本内模拟编排的真实可达回归 | **达标**。V130 主回归不加载 `presentation.gd`（F8 运行时树零 presentation 节点）、不模拟编排；S 组以真实 R/Q 输入（Input.parse_input_event + process_key_event）→ 生产唯一 FocusService.spend_fp → focus_spent → ENC/wave 生产订阅 → `ProdArtLabel` 真实可见节点文本由「当前战技：辉石魔砾」变「当前战技：狮子斩」。V100HUD L 组读真实节点 `get_global_rect()` 做几何断言。 | V130 F8/S1~S7、V100HUD L1~L4 |
| ④ | 纯逻辑 + 单元断言不算可玩交付 | **达标**。交付含真实可见节点 ProdArtLabel、真实 `_unhandled_input(R/Q)`、生产运行时订阅链、真实 Boss 削韧/伤害、450 帧演示逻辑真跑（两战技 9 次命中 / 19 次拒绝），全部经 Godot 4.7.2 三段门禁 + 4 回归真跑；`presentation.gd` 演示驱动仅作注入机会，真实可达由 V130 承担。 | §5 全部门禁 / 回归 / 演示输出 |

**SceneTree / `--script` 纪律**：V130 / V100HUD 用 `Engine.get_main_loop() as SceneTree` 取 root（不用 `get_tree()` / 不用 `/root/...` 绝对路径）、`add_child` 后显式 `call("_ready")` / `_r34_bootstrap()`、资源 `CACHE_MODE_IGNORE`、connect 前 `get_signal_connection_list` 去重 + `_finish()` disconnect 释放；`project.godot` 既有 `PointsCommitOrchestrator` autoload 直接复用、不重复挂载。

---

## 8. 未完成项 / 待总指挥裁决项（如实登记，不擅改）

**未完成项**
1. **定稿录屏 / 目视帧**：按公共契约由总指挥本轮亲自重跑并目视；本轮不含新 MP4 / 抽帧 / 目视结论。暖金「狮子斩」斩击弧与「当前战技：XXX」HUD 的实机观感待目视确认。
2. **HD-2D 全绿**：差距清单（真 DoF / 真 `volumetric_fog` / SSR / `Environment.glow` / Forward+ 后端）沿用 R35B/R35C/R36 保持未达。
3. **连击 D→A→S / S 级收束爆发**：逻辑真跑尾帧倍率推进到 ×1.35（与 A67 目视 B 级 1.35 一致），完整评级序列 / S 级爆发实机可见性待目视。
4. **`[PLACEHOLDER]` 试玩校准**：`ANCHOR_ART` 锚点（hud.gd 常量表）、`R36B_SWITCH_FRAMES` 演示节奏（presentation.gd R36B 常量段）待试玩校准；`focus_rules.tres` 两战技数值归 Rank-2，本轮只读。
5. **本轮不含新录屏 / 抽帧**（同 1，按契约不重复录屏）。

**待裁决项**
1. 定稿录屏目视结论（暖金斩击弧可辨识度 / 当前战技名 HUD 可读性 / HUD 文字无重叠 / 暖金未过曝）。
2. R 键位最终实机手感确认（A69 已裁决 R=82；是否需改用其它键 / 长按 / 滚轮，请裁决）。
3. 战技切换的 UI 形态：本轮为常驻文本 Label「当前战技：XXX」；若需战技图标 / 轮盘 / 切换音效 / 角标，请裁决归属与避让断言同步。
4. `ANCHOR_ART` / `R36B_SWITCH_FRAMES` / 全部 `[PLACEHOLDER]` 试玩校准档位。
5. 是否把「当前战技」并入 `get_layout_rects()` 的 6 分区数组（本轮为保护 V100HUD A1「size()==6」既有断言不并入，改以独立 `get_current_art_rect()` 暴露），请裁决。
6. HD-2D 全绿路线；`128bit` 歧义继续保留（A43/A53/A61）；真实逐次命中坐标（沿用 R35C §7.3）。
7. **既有 R36 显示口径**：`focus_skill_performed.fp_before` / HUD 日志 `fp X->X` 的打印时序（§5.6 观察）是否修正 —— 涉及改既有输出格式，需总指挥明确授权后再动，本轮未改。
8. Rank-4 / Rank-2 接口异议：本轮只读 `get_art_ids()` / `get_config().get_art_by_id()` / `focus_spent(art_id)`，与 `DONE-R36.md` §3 稳定签名一致；如后续微调命名，HUD 鸭子多候选 + 判空降级可兼容，请复核。

---

## 9. 硬约束遵守声明

- **唯一写入方**：只写 `hud.gd` / `encounter_director.gd` / `presentation.gd` / `verify_focus_runtime_v130.gd` / `verify_hud_layout_v100.gd` / `teamwork/Rank-1/`（DONE + 16 份日志）/ 回执。**未改** `wave_trial_director.gd` / `focus_rules.tres` / `focus_service.gd` / `focus_config.gd` / `points_commit_orchestrator.gd` / `hd2d_fx.gd` / `impact_feedback.gd` / `project.godot` / `courtyard.tscn`（A38 节点 41 / uv 2/1/1）/ 既有 `.tres` / 素材 / 其它 Rank 产出；`verify_production_chains_v110.gd` / `verify_parry_runtime_v120.gd` 仅复跑未改。
- **不改既有 `[PLACEHOLDER]` 数值 / 输出格式**：`focus_rules.tres` 两战技 12 项数值逐字不动（md5 一致）；`presentation.gd` 既有 R28/R34/R35/R36 常量数值与 Q/J/K 注入节奏逐字不动；`hud.gd` 既有 6 信号 / 14 个 `get_focus_hud_view` key / 四套 HUD / 6 分区布局逐字不动。
- **零付费、零外部依赖、不启 GPU job**：仅本地 Godot 4.7.2；未 `--write-movie` 录屏 / 未调 ffmpeg / 未列任何付费项。
- **默认不刺探**：未主动扫目录做进度巡检、未新建只读探针 / 巡检脚本；所有读取均针对任务单指定契约 / 目标文件 / 只读接口确认 / 门禁日志 / 归档确认所必需路径，用真跑输出判断进度。
- **不伪造产物、不谎报成功**：16 段门禁日志非空、4 回归数字 / SCRIPT ERROR 数字 / 两战技实证 / 演示统计均为真跑输出原文；L3 首轮 FAIL 与 ENC 双切换 bug 均如实登记并修复复跑；未冒称目视通过、未冒称 HD-2D 全绿、未冒称连击 D→A→S / S 级录屏覆盖。
- **不自行 git**（总指挥收尾）；**未删除 `.workbuddy` 目录**。

---

## 10. 回执与中枢归档确认（写后实测，如实登记）

- 回执写入授权路径（**`teamwork/command_center/`**，非工程根）：`teamwork/command_center/ai/1/outbox/cmd-20261112-175103-031-A1.json`，四字段 `{"task_id":"cmd-20261112-175103-031-A1","ai":1,"status":"done","result":"…引用 DONE-R36B.md 实际结论…"}`。
- **中枢归档回读确认（写后实测）**：
  - `ai/1/outbox/` 已清空（回执被中枢移走 → `dispatcher/receipts/`，属中枢正常处理）：`outbox_count=0`。
  - 归档副本 `teamwork/command_center/dispatcher/receipts/cmd-20261112-175103-031-A1.json` 存在（**1505 字节**），回读 **VALID_JSON**，四字段齐全：`keys=['ai','result','status','task_id']` / `task_id=cmd-20261112-175103-031-A1` / `ai=1` / `status=done` / `result_len=864`。
  - `ai/1/status.json`：`{"ai":1,"state":"idle","current_task":"","completed":67,"last_seen":"2026-11-12 18:23:52"}`（`completed` 66→67、`current_task` 清空、state working→idle）。
  - `dispatcher/dispatcher.log` 尾部原文：`[2026-11-12 18:23:52] ← 1 号 AI 回执 <cmd-20261112-175103-031-A1> 完成：R36B 四块任务全部真跑完成，实际结论见 teamwork/Rank-1/DONE-R36B.md：① A69 裁决落…`，确认 id 与派单一致、中枢已回收验证 `done`。
  - `dispatcher/ledger.jsonl` 本任务行回读 **VALID_JSON**：`id=cmd-20261112-175103-031-A1 / command=cmd-20261112-175103-031 / ai=1 / status=done / issued_at=2026-11-12 17:51:03 / finished_at=2026-11-12 18:23:52 / result_len=864`（与回执 result 逐字一致）。
