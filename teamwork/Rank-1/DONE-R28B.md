# DONE-R28B · Rank-1（引擎架构与渲染）

- **补单 id**：`cmd-20261111-105411-909-A1`（[ROUND=R28B]）
- **工程根**：`F:/Game/aierdengfahuan`；Godot 工程 `F:/Game/aierdengfahuan/godot`
- **引擎**：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）
- **结论速览**：三处收口全部落地并真跑实证 —— ① 裁决 A26（世界持久层单调 / 运行时游标分离）落地 `tutorial_director.gd` + `hud.gd`；② 裁决 A27 正式授权 `verify_wave_runtime_v040.gd` 期望值 38→41，复跑 **37 PASS 不回退**，补 1 条「教学 3 节点」回归用例；③ Rank-2 三个兼容函数接入 `hud.gd` / `grace_upgrade_runtime.gd` 已购判定读取路径，纯旧 `bought_` 档可识别已购、写仍只写 `unlocked`；④ 新写 `verify_tutorial_restart_v060.gd` **48 PASS / 0 FAIL / RESULT=ALL_PASS**；⑤ 三段门禁 **10 份日志 SCRIPT ERROR=0**，全回归 **41 份 `r28b_*.log` 全量 SCRIPT ERROR=0 / PASS=false=0**，`64 / 86 / 21 / 31 / 58 / 37` 全部不回退。
- **零付费 / 零外部依赖 / 未启 GPU job / 未新建只读探针巡检脚本 / 未自行 git**（总指挥收尾）。

---

## 1. 写清单核对（只写白名单）

| 文件 | 动作 | 内容 |
|---|---|---|
| `godot/scripts/combat/tutorial_director.gd` | 改写 | A26 世界持久层单调 / 运行时游标分离 |
| `godot/scripts/hud.gd` | 改写 | A26 教学进度显示口径 + ③ 兼容旧档接入 + R28 遗留文案勘误（仅注释） |
| `godot/scripts/combat/grace_upgrade_runtime.gd` | 改写 | ③ 兼容旧档接入（已购判定读取路径） |
| `godot/scripts/combat/verify_wave_runtime_v040.gd` | 改写（仅头部注释） | A27 授权追认；断言集合 / 常量 / 判定逐字未动 |
| `godot/scripts/combat/verify_tutorial_restart_v060.gd` | **新写** | `extends SceneTree` 自测，48 条断言 |
| `teamwork/Rank-1/` | 追加 | `DONE-R28B.md` + 41 份 `r28b_*.log` 真跑日志 + 回执（回执在 `command_center/ai/1/outbox/`） |

**未写**：素材 PNG / `.tres` / `project.godot` / `presentation.gd` / 契约文档 / `README.md` / `courtyard.tscn` / `grace_upgrade_service.gd` / `world_state.gd` / 其它 Rank 目录。`grace.tutorial.step_index` 未改 `world_state.gd` 正则、未迁移 `schema_version`（仍为 3）、未新增顶层字段。

---

## 2. 裁决 A26 落地（世界持久层 vs 运行时游标）

### 2.1 `tutorial_director.gd`

- 新增三段式常量 `FLAG_TUTORIAL_STEP_INDEX = "grace.tutorial.step_index"`（匹配 `WorldState.FLAG_KEY_REGEX`，无需改正则）。
- 新增 `_world_step_index_mirror`（依赖缺失降级时的进程内镜像）、`_read_step_index_flag()`（只读世界 flag）、`_stage_step_index_max(progress)`（**按 `max(旧值, 本步累计进度)` 写，只有更大才 `set_flag`，绝不回写更小值**）。
- 新增集成层只读接口 `get_runtime_step_index()` / `get_world_step_index()`；`get_snapshot()` 新增 `world_step_index`（`step_index` 仍为运行时游标）。
- `_grant_reward()` 内在每步完成时按 `max` 推进世界 flag，**与既有赐福点数奖励合并入同一次 `commit("tutorial_step_reward")`**：不新增落盘点、不改 commit 次数，保护 `verify_tutorial_v060.gd` 的 A18（`commits.size()==4` / 末位 `tutorial_completed`）、F4（`commit_count==0`）、H6（幂等不重复落盘）等 64 条断言不回退（实测 64 PASS）。
- `_enter_tutorial()` / `restart_tutorial()`：**只重置运行时游标 `_step_index`、提示、会话奖励、波次衔接态**；绝不回写 / 清零世界 flag，绝不清除 `grace.tutorial.completed`（`false→true` 单向保持）。`restart_tutorial()` 本人不调用任何 `set_flag` / `commit`。
- `_refresh_hud()` 进度 `%d/%d` 明确取**运行时游标**，绝不读世界 flag（否则 T 重开会卡在历史最高 3/3）。

### 2.2 `hud.gd`（教学进度显示：显示运行时游标而非世界 flag）

- 登记 `FLAG_TUTORIAL_STEP_INDEX`（**只登记「不用于显示」的世界 key**）：不并入 `LIT_SOURCE_FLAGS`、不并入 `_bound_keys`、不参与 `refresh_label` 增量命中，保护 `verify_persistence_hud_v050.gd` D5「`LIT_SOURCE_FLAGS.size()==2`」等既有断言（实测 30 PASS）。
- 新增 `tutorial_progress_text(runtime_step_index, total_steps)` 与 `read_tutorial_progress(director)`：**只取 `TutorialDirector.get_snapshot()["step_index"]` 运行时游标**构造「赐福引导 N/3」，绝不读 `grace.tutorial.step_index` 世界 flag，纯只读、不写 flag、不发信号；director 缺失安全回落 0/3，不崩。
- 实证（新脚本 C 组）：完成后显示 3/3；T 重开后显示回到 1/3，而世界 flag 仍 = 3（C7 PASS）——显示口径与世界持久层严格分离。

### 2.3 如实登记的契约口径差异（不隐瞒、不冒称）

- 契约 §3.3 / `WAVE-TRIAL-GDD.md` §10.8 把 `grace.tutorial.step_index` 的**写方登记为 Rank-3**（订阅 `tutorial_step_completed` 信号、`commit("tutorial_step_completed")`），并写「Rank-1 不写 flag」。但 Rank-3 在 R28 与本轮均**不写任何 `godot/` 工程业务文件**，工程内不存在该订阅件。裁决 A26 明确要求「落地到 `tutorial_director.gd`」，故本轮由 Rank-1 在运行时代理该世界 flag 的 `max` 写；commit reason 沿用既有 `tutorial_step_reward`（未新增落盘点以保护 64 PASS 时序断言），**与契约登记的 `tutorial_step_completed` 字符串不同**。差异如实登记，供总指挥裁决是否同步契约文案（契约 / GDD 不在本轮白名单，未改）。
- 契约 §3.3 把「教学 HUD 进度 1-3」登记为该世界 flag 的**读方**；裁决 A26 明确覆盖为「显示运行时游标而非世界 flag」。本轮按裁决 A26 落地，契约文案未改，如实登记。
- `grace.tutorial.completed` 保持 `false→true` 单向、T 重开不清除（F 组实测多次 T 重开恒 true）。

---

## 3. 裁决 A27：断言前后值与回归

### 3.1 断言前后值（精确登记）

| 阶段 | `NODE_COUNT_AFTER` | `NODE_COUNT_DELTA` | 实跑结果 |
|---|---|---|---|
| R28 之前（断言过期） | **38** | **5** | `node_count=41 expected=38` → `courtyard_node_count` FAIL，稳定 **36/37** |
| R28 同步（当时 DONE-R28 §8.1 登记为「越权风险、待裁决」） | **41** | **8** | **37 PASS / 0 FAIL / ALL_MATCH** |
| **R28B 裁决 A27 正式授权追认（本轮）** | **41** | **8** | **37 PASS / 0 FAIL / ALL_MATCH**（复跑不回退） |

根因：`courtyard.tscn` 新增 3 个真实教学节点 `TutorialHud` / `TutorialLabel` / `TutorialDirector`，属「断言与当前实现的真实口径差异 → 修断言」，非实现缺陷。

### 3.2 本轮实际动作

- **只改数字（R28 已执行）、不删断言、不放宽其它判定**：本轮对 `verify_wave_runtime_v040.gd` **仅在头部注释追加「裁决 A27 授权 38→41」说明**；`NODE_COUNT_AFTER=41` / `NODE_COUNT_DELTA=8` / 全部 `_ck` 断言 / 判定逻辑 / 断言数量（37 条）**逐字未动**，故复跑精确 **37 PASS**，与任务「复跑 37 PASS 不回退」验收数字一致。
- **补 1 条回归用例说明「教学 3 节点」**：落在本轮任务 ④ 明确要求新写的正式验证载体 `verify_tutorial_restart_v060.gd` 的 **E3 `tutorial_three_nodes_present`**，精确断言 `TutorialHud`(CanvasLayer) / `TutorialLabel`(Label) / `TutorialDirector`(Node+脚本) 三节点真实存在且类型正确；配套 E4 直接读 v040 脚本常量实证 `NODE_COUNT_AFTER=41 / DELTA=8`，E5 断言「节点数 41 + 教学 3 节点」即 v040 H 组 `courtyard_node_count` 的 37 PASS 基线口径。
- **编排决策如实登记**：任务 A27 同时要求「只改数字 / 不删断言」与「复跑 37 PASS 不回退」，若给 v040 增加 1 条 `_ck`，其 SUMMARY 会变 38，与 37 PASS 验收数字不符。故把新增的 1 条回归用例放在新脚本而非 v040；v040 断言集合逐字不动。此落点选择透明登记，供总指挥裁决（如需把该用例移入 v040，则 v040 将变为 38 PASS，既有 37 条仍全 PASS 不回退）。

---

## 4. ③ 兼容旧档接入（Rank-2 三个兼容函数）

Rank-2 `grace_upgrade_service.gd` 提供（本轮**未改**）：`legacy_bought_flag_key()` / `is_purchased_in_flags()` / `load_state_from_flags()`。因 I-1 铁律 `WorldState` 只暴露 `get_flag(key, default)`、不可访问内部 `_flags`，两文件均新增 `_purchase_flags_snapshot(state, cfg)`：**逐 upgrade id 用 `get_flag` 收集权威 `unlocked` 与旧 `grace.trial.bought_<id>` 两键**，构造 flags 字典快照后交给兼容函数，纯读、不写。

| 调用方 | 读取路径 | 接入的兼容函数 |
|---|---|---|
| `hud.gd` | `get_shop_view()` 兑换项 `unlocked` 判定 | `is_purchased_in_flags()` |
| `hud.gd` | `purchase_upgrade()` 恢复 F1 已购集合 | `load_state_from_flags()` |
| `hud.gd` | `_purchase_flags_snapshot()` | `legacy_bought_flag_key()` |
| `grace_upgrade_runtime.gd` | `apply_purchased()` 已购判定 | `is_purchased_in_flags()` |
| `grace_upgrade_runtime.gd` | `try_purchase()` 恢复 F1 已购集合 | `load_state_from_flags()` |
| `grace_upgrade_runtime.gd` | `_purchase_flags_snapshot()` | `legacy_bought_flag_key()` + `authoritative_unlocked_key()` |

- **写仍只写 `unlocked`**（裁决 A23 / R28 双写收敛，写入路径逐字未动）：实测 D10「成功购买只写 unlocked / 绝不新写 `grace.trial.bought_<id>`」PASS；`F1~F8` 防刷核心（`can_purchase` / `purchase` / `spent_points` 单调 / 重复购买拒绝）逐字不变，实测 `verify_grace_upgrade_v050.gd` **127 PASS**、`verify_grace_runtime_v050.gd` **58 PASS**、D5/D7/D11 旧档重复购买被拒。
- 纯旧档（只有 `grace.trial.bought_hp_max_bonus=true`、无 `unlocked`）实测：`get_shop_view()` 判已解锁、`purchase_upgrade()` 拒绝重复购买（`can_purchase_rejected`）、`try_purchase()` 拒绝（`duplicate_id`）、`apply_purchased()` 该项非 `not_purchased`（D4~D8 全 PASS）。
- 新档（仅 `unlocked`）仍识别已购（D9 PASS），A23 不回退。
- 顺带勘误 `hud.gd` §8 头注与 `purchase_upgrade()` 内 R28 遗留的「另写 Rank-2 读取口径 `bought_`」过时文案（仅注释，代码逐字未动）——收敛后 `purchased_flag_key()` 已返回 `unlocked`，实际不再新写 `bought_`。

---

## 5. 新写 `verify_tutorial_restart_v060.gd`（任务 ④）

`extends SceneTree`，纯内存夹具（`WorldState` 手动 `new()` 不写 `user://` 盘、`FakeWriter` 只记 `commit(reason)`、WaveTrialDirector / HUD / Label / GraceUpgradeRuntime 独立实例、显式 `call("_ready")`、注入在 `_ready` 之后、不用 `/root/...` 绝对路径），**48 PASS / 0 FAIL / RESULT=ALL_PASS / EXIT=0**。

分组覆盖：A 世界 `step_index` 单调不回退（含按 max 写：外部更大值 7 不被回写覆盖、不新增落盘点）；B T 重开运行时归零但世界 flag 不变、completed 单向（含中途 T 重开）；C HUD 显示运行时游标而非世界 flag；D 旧档兼容读取（三个函数接入实证）；E 节点数 41 + 教学 3 节点（A27 回归用例）+ 37 PASS 基线；F completed 单向 / 全依赖缺失降级 `commit_count=0`。

---

## 6. 三段门禁 + 全回归（真跑输出结论）

引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--headless --path F:/Game/aierdengfahuan/godot`，串行单进程。

| 段 | 命令要点 | EXIT | `SCRIPT ERROR` / `Parse Error` |
|---|---|---|---|
| G1 | `--headless --import` | 0 | 0 |
| G2 | `--headless --check-only --script` ×8（tutorial_director / hud / grace_upgrade_runtime / verify_wave_runtime_v040 / verify_tutorial_restart_v060 / verify_tutorial_v060 / wave_trial_director / encounter_director） | 全 0 | 全 0 |
| G3 | `--headless --quit-after 90 res://scenes/courtyard.tscn` | 0 | 0 |

**10 份 `r28b_g*.log` 逐份 grep `SCRIPT ERROR` / `Parse Error` = 0，`TOTAL_SCRIPT_ERROR=0`。**
全量 **41 份 `r28b_*.log`**：`SCRIPT_ERROR=0`、`PASS=false / fail>0 = 0`。

### 6.1 任务点名的口径数字（全部实跑达到、不回退）

| 组 | 期望 | 实测 | 结论 |
|---|---|---|---|
| `verify_tutorial_v060`（R28 本轮前既有） | 64 | `pass=64 fail=0 ALL_PASS` | 不回退（A18 / F4 / H6 全绿，A26 未新增落盘点） |
| `verify_tutorial_reward_v060` | 86 | `pass=86 fail=0 ALL_MATCH` | 不回退 |
| `verify_tutorial_flags_v060`（Rank-3 三态） | 21 | `selftest 15 + write 3 + read 3 = 21`（三进程 pid 28232 / 29292 / 7604 全不同） | 不回退 |
| `verify_save_isolation_v060` | 31 | `pass=31 fail=0 ALL_MATCH` | 不回退 |
| `verify_wave_trial_v040` / `verify_grace_runtime_v050` | 58 | `58 / 58` | 不回退 |
| **`verify_wave_runtime_v040`（A27）** | **37** | **`pass=37 fail=0 ALL_MATCH`** | **不回退（裁决 A27 授权后精确 37 PASS）** |
| **`verify_tutorial_restart_v060`（本轮新）** | — | **`pass=48 fail=0 ALL_PASS`** | 本轮新增 |

### 6.2 全回归其余脚本（16 项全回归覆盖，全部 EXIT=0 / fail=0）

| 组 | 实测 |
|---|---|
| `verify_wave_persist_v040` | `45`（编排首跑，经 I-1 归一化补齐十字段并真实落盘） |
| `verify_persistence_hud_v050` | `30 ALL_PASS`（十字段齐全，未回退） |
| `verify_encounter_v010 / v020 / v030` | `20 / 45 / 53` |
| `verify_fx_profile / verify_fx_mobile / verify_quality_interaction` | `34 / 47 / 19` |
| `verify_hud_binding` | `11` |
| `r19_verify_hud`（Rank-3） | `20`（`20 + 11 = 31`） |
| `verify_wave_flags_v040`（Rank-3 三态） | `17 + 3 + 3 = 23`（pid 4424 / 3060 / 27324 全不同） |
| `verify_grace_upgrade_v050` | `127`（兼容函数接入未破坏 F1~F8） |
| `verify_boss_phase / boss_poses / boss_runtime / combat_runtime / frame_data / pose_names` | 全部 `RESULT=PASS`（combat_runtime `PASS=27 FAIL=0`） |

工程内 23 个 verify 脚本 + Rank-3 七个口径件进程全部 `EXIT=0 / fail=0 / SCRIPT ERROR=0`；编排沿用 R28 §7（`verify_wave_persist_v040` 先归一化 → `verify_persistence_hud_v050` → 其余 → `verify_save_isolation_v060` 收尾），无 29/30 并发中间态。

---

## 7. 未完成项与如实边界

1. **契约文案口径差异（供总指挥裁决）**：契约 §3.3 / GDD §10.8 登记 `grace.tutorial.step_index` 写方为 Rank-3、commit reason `tutorial_step_completed`、读方含「教学 HUD 进度 1-3」；裁决 A26 由 Rank-1 运行时代理 max 写、reason 沿用 `tutorial_step_reward`、HUD 改显运行时游标。契约 / GDD / README 不在本轮白名单，未改、如实登记。
2. **A27 新增回归用例落点（供总指挥裁决）**：因「只改数字 / 复跑 37 PASS 不回退」精确约束，补的 1 条「教学 3 节点」用例落在 `verify_tutorial_restart_v060.gd` E3 而非 v040；v040 断言集合逐字未动（详见 §3.2）。
3. **未做 `grace.tutorial.step_index` 跨 exe 重启读回实证**：本轮以进程内 WorldState + 单向/`max` 语义 + 新脚本 A/B/F 组断言 + Rank-3 `verify_tutorial_flags_v060` 三态（含真实 FileAccess 落盘 / 独立 State `_load()` 读回）验证；`verify_tutorial_restart_v060.gd` 用隔离夹具，**不污染生产存档**（`grace.tutorial.completed` / `step_index` 从未写入生产磁盘）。
4. **未做 15~20 秒实机录屏 / 目视回看**：本轮约束「不启 GPU job」；进度判断依据为三段门禁 + 48 条新自测断言 + 全回归 + G3 纯场景日志。教学 HUD 视觉观感（字号 / 重叠 / 亮金对比度）待人工试玩目视校准；`presentation.gd` 归 Rank-4，本轮未改、未代跑录屏。
5. **数值 `[PLACEHOLDER]` 待试玩校准**：单步奖励 / 文案 / 键位提示运行期读 Rank-2 `tutorial_steps.tres`（20/30/50），代码内默认值仅作依赖缺失降级；教学 HUD 位置 y=520 / 字号 18 / 金色为布局值，待目视校准。
6. **存档磁盘为测试态**：`verify_wave_persist_v040` / `verify_persistence_hud_v050` 等经 I-1 真实写入口多次落盘覆盖 `slot_01/delta.json`；均为真实 `set_flag` + `commit`，非伪造产物。
7. 未自行 `git`（总指挥收尾）；零付费、零外部依赖、未启 GPU job；未新建只读探针 / 巡检脚本（新 v060 是任务单 ④ 明确要求的正式验证载体）。

---

## 8. 回执

- 精确路径：`F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/cmd-20261111-105411-909-A1.json`
- 内容：`{"task_id":"cmd-20261111-105411-909-A1","ai":1,"status":"done","result":"引用 DONE-R28B.md 实际结论：..."}`（`result` 引用本文档实际结论，含 A26 / A27 前后值 / 兼容旧档 / PASS 数字 / 未完成项）。
- **写后实测（如实登记，非巡检 / 交付自验 1 次）**：回执写入成功后 `outbox/` 被中枢**实时消费清空**（直接读精确路径 `exists=False`，与 DONE-R26B / R27 / R28 §⑤ 同一消费时序现象），未隐藏。归档件 `teamwork/command_center/dispatcher/receipts/cmd-20261111-105411-909-A1.json`（**3006 字节**，11:18）读回校验：`json_valid=True`、`keys=['ai','result','status','task_id']`、`task_id=cmd-20261111-105411-909-A1` / `ai=1` / `status=done`、`result_len=1936`、`result` 以「引用 teamwork/Rank-1/DONE-R28B.md 实际结论」开头并含 `A26` / `A27` / `38` / `41` / `37 PASS` / `48 PASS` / `64` / `86` / `21` / `31` / `58` / `SCRIPT ERROR=0` / `兼容` / `未完成项` 关键结论；`ai/1/status.json` 同步 `completed=46 / state=idle`。按幂等 / 并发保护**不重复写第二份回执**。
