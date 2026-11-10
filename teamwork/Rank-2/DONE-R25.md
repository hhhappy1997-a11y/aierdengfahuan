# DONE-R25.md · Rank-2（战斗系统与数据驱动）

> 轮次 **R25**｜命令 `cmd-20261110-204604-823-A2`｜真源：`teamwork/Rank-2/调度任务单-latest.json`（`id` 与 `[ROUND=R25]` 已核对，两份真源正文一致）｜中文 UTF-8
> 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（v4.7.2.stable.official.ed1daf0bf）｜工程根 `F:/Game/aierdengfahuan/godot`

---

## 1. 实际交付清单

| # | 文件 | 动作 | 内容 |
|---|---|---|---|
| 1 | `godot/scripts/combat/encounter_rules_v020.gd` | **只追加** | 追加 `const ENCOUNTER_ID: String = "encounter_01"`（GRACE-RETRY-V020.md §2.3 对象段对齐真源），供导演层拼接两个三段式 flag 的对象段；既有规则逻辑与 `DEFAULT_FPS` 等逐字不动。 |
| 2 | `godot/scripts/combat/encounter_director.gd` | **只追加 / 补齐** | 追加 A13 落地、两个三段式 flag 落盘、CombatResolver 削韧/异常/处决接线、`get_snapshot()` 可观测键；既有 v0.1.0 20 条 + v0.2.0 45 条断言路径与 `debug_*` 签名逐字不变（真跑证明不回退）。 |
| 3 | `godot/scripts/combat/verify_encounter_v030.gd` | **新写** | `extends SceneTree`，53 条断言，覆盖任务单 ④ 全部点，输出 PASS/FAIL 与 RESULT，失败 `quit(1)`。 |
| 4 | `teamwork/Rank-2/DONE-R25.md` | 新写 | 本文件。 |
| 5 | `teamwork/command_center/ai/2/outbox/cmd-20261110-204604-823-A2.json` | 新写 | 按本命令 id 的回执（teamwork 下 outbox，非工程根）。 |

**未写 / 未改**（目录所有权）：`godot/project.godot`、`encounter_v010.tscn`、素材 PNG / `.tres`、`presentation.gd`、`teamwork/Rank-1|3|4/`、`00-群聊总线.md` / `00-项目总纲.md` / `00-协作契约.md`。未自行 `git commit/push`，未生成 `00-汇总.md`。

---

## 2. 按任务单正文逐项落实

### ① 裁决 A13 落地（赐福休息重置 Boss 忽略 L1 永久击败 flag）

- **根因（真跑证实）**：`BossController._ready()` 读 `boss_data.defeated_flag_key`（= `world.boss_01_margit.defeated`），若 L1 永久击败 flag 为 true 则保持 IDLE、不进战斗（v030 对照断言 `a13_plain_boss_blocked_by_l1`：裸控制器 `get_phase_index()==0`）。
- **落地**：`_respawn_boss()` 重建 L3 运行时实例时，只给该实例一份 `src_data.duplicate()` 的**运行时数据表副本**并置 `defeated_flag_key = ""`（数值逐字复制自原表，数据驱动不变），使本次遭遇可重打；**绝不清除** `world.<id>.defeated` / `combat.<id>.defeated`、**不用 removals**、不改任何数据表文件、不改 BossController 既有件。
- **只读记录**：`_grace_rest()` 追加 `_read_l1_defeat_flags()`，把两个 L1 key 的值读进 `_l1_defeat_snapshot`（只读、绝不写回），并以 `_l1_defeat_ignored` 标记"检测到 L1 已击败仍允许重打"。
- **可验证**：v030 断言 `a13_replay_boss_full`（重建后 `boss_phase==1` / `boss_hp_ratio==1.0`）、`a13_can_damage_after_rest`（重建实例能受伤害，比例 1.0→0.9877）、`a13_l1_still_true`（两个 L1 flag 仍 true）、`a13_l1_ignored`（快照含两个 true 且 ignored=true）。

### ② 两个三段式 flag 真正写入 WorldState（先落盘再改运行时实例）

- 两个 key：`grace.encounter_01.retried`（int，单调递增）、`grace.encounter_01.retry_active`（bool，回合门控）。对象段由 `EncounterRulesV020.ENCOUNTER_ID` 驱动（`flag_retried_key()` / `flag_retry_active_key()`），与任务单 / GRACE-RETRY-V020.md 示例字面量一致，符合三段式正则 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`（v030 `v030_flag_keys_regex` PASS）。
- `start_grace_retry()`：经 I-1 `WorldState.get_flag/set_flag` 写入两 key → `SaveDeltaWriter.commit("grace_retry")` **强制落盘** → **才**调 `_reset_runtime_for_retry()` 改 L3 运行时实例（HP / 状态机 / Boss / 规则层 / outcome）。门控：`retry_active==true` 时拒绝（连点不二次 +1）。
- `finish_grace_retry()`（挂在 `_finish()` 结算末尾）：`set_flag(retry_active,false)` → `commit("grace_retry")` 先落盘 → 再释放回合标记。I-2 击杀链、SaveDeltaWriter 签名与 §4.5 原子写流程零改动。
- v030 断言：`retry_start_ok` / `retried_inc_1` / `retry_active_true` / `commit_reason_grace_retry`（`last_commit_reason=="grace_retry"`）/ `retry_runtime_reset_after_commit` / `retry_spam_gated` / `finish_retry_clears_active` / `finish_retry_commit_reason` / `retried_monotonic`（再次发起到 2，不回退）。

### ③ 接 CombatResolver 既有能力到导演层（数值全部来自数据表 / @export，零硬编码）

| 能力 | 接入方法 | 数值真源 |
|---|---|---|
| `compute_poise_after_hit` / `resolve_poise` | `_resolve_poise()` ← `_resolve_poise_on_hit(action)`（玩家命中接线）与 `debug_resolve_poise()` | `PlayerActionData.poise_damage` / `MoveData.poise_damage`、`PoiseConfig.max_poise` / `stance_break_duration_sec`（`BossData.poise` 或 `PhaseData.poise_override`） |
| `regen_poise` | `_tick_combat_state(delta)`（挂 `_step` 每帧）与 `debug_tick_combat()` | `PoiseConfig.poise_regen_delay_sec` / `poise_regen_per_sec` / `max_poise` |
| `apply_status_buildup`（bleed/poison/frost） | `_apply_status()` ← `_apply_action_status(action)` 与 `debug_apply_status()` | `BossData.status_buildups`（threshold / decay / trigger_damage_* / resistance_*）、`PhaseData.status_resistance_multiplier`、`BossData.max_hp` |
| `can_execute` | `check_execute()` | `PoiseConfig.executable` / `execute_hp_ratio_threshold`、运行时韧性 / 崩坏窗口、Boss HP 比例；判定帧 / 距离 / 命中登记按设计文档 §3.2 由调用方提供 |

- 全部状态（韧性 / 崩坏窗口 / 异常累积 / 抗性 / 计时）都是 **L3 纯运行时**，不写任何 flag / SaveDelta 字段。
- v030 断言：削韧归零与崩坏复位、崩坏窗口、延迟后韧性回复、异常累积与触发（trigger_damage 420.0 = max(1, 3500×0.12+0)）、抗性增长 25.0、poison/frost 累积、处决窗口开/关（需命中登记 / 判定帧 / 距离）、窗口过期后 `can_execute=false`。

### ④ `verify_encounter_v030.gd`（53 条断言）

覆盖：A13 重打（含裸控制器对照）、两个三段式 flag（字面量 / 正则 / 落盘 / 门控 / 结算 / 单调）、削韧归零与回复、异常累积与触发、处决窗口、0 血（Boss / 玩家）、连点、依赖缺失降级；同跑 v010/v020 不回退。输出 `PASS=true/false`、`SUMMARY`、`RESULT`，失败 `quit(1)`。

### ⑤ 未改 project.godot / 场景 / 素材 / 00-协作契约.md / presentation.gd —— 已遵守。

---

## 3. 真跑三段门禁输出结论（实际执行，非推断）

引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot`

| 段 | 命令 | 实际输出 | SCRIPT ERROR | Parse Error |
|---|---|---|---|---|
| 1 | `--headless --import` | `EXIT=0`，`first_scan_filesystem [DONE]` / `loading_editor_layout [DONE]` | **0** | **0** |
| 2 | `--check-only --script` ×3（v010/v020/v030） | 三个脚本均 `EXIT=0`、`(no errors)` | **0** | **0** |
| 3 | `--headless --quit` | `EXIT=0`，主场景 / autoload 正常加载退出（1 条 `ObjectDB instances were leaked` WARNING，非 ERROR） | **0** | **0** |

**verify 脚本真跑（`--headless --script`）**：

| 脚本 | SUMMARY | RESULT | EXIT | PASS=True | PASS=False | SCRIPT ERROR |
|---|---|---|---|---|---|---|
| `verify_encounter_v010.gd` | `pass=20 fail=0` | `ALL_MATCH` | 0 | 20 | 0 | **0** |
| `verify_encounter_v020.gd` | `pass=45 fail=0` | `ALL_MATCH` | 0 | 45 | 0 | **0** |
| `verify_encounter_v030.gd` | `pass=53 fail=0` | `ALL_MATCH` | 0 | 53 | 0 | **0** |

- **既有 PASS 数全部不回退**：v010 保持 20 PASS、v020 保持 45 PASS；新增 v030 53 PASS。三者 `RESULT=ALL_MATCH`。
- **grep `SCRIPT ERROR` = 0**：三段门禁与三个 verify 真跑均为 0。
- 装配期非致命输出（如实登记）：`--script` 模式下 v010/v020/v030 均带引擎 C++ 层 `ERROR:`（`get_node() with absolute paths` / `Signal 'boss_defeated' is already connected`，v010 4 条 / v020 5 条 / v030 2 条）与 WARNING（BossController 数据表 id 已标记击败、Boss 节点缺失降级、ObjectDB leak），均为既有 `--script` 装配惯例，**不是 `SCRIPT ERROR`**，不影响 RESULT 与 EXIT。
- 真跑经 I-1 写 `user://saves/slot_01` flag，v030 结束把 4 个 key（`world.boss_01_margit.defeated` / `combat.boss_01_margit.defeated` / `grace.encounter_01.retried` / `grace.encounter_01.retry_active`）恢复为原值（与 v010/v020 惯例一致）；`commit` 落盘由 SaveDeltaWriter 执行，本轮未直读写存档文件（I-1 边界）。

---

## 4. 未完成项与阻塞 / 如实边界（不粉饰、不冒充）

1. **无阻塞**：任务单正文 ①~⑤ 全部落地并经真跑验证通过。
2. **GRACE-RETRY-V020.md §7.1 第 1 步（在 `存档与flag规范.md` §3.3 登记表追加 2 行）本轮未执行**：该文件在 `teamwork/Rank-3/`（Rank-3 独占），任务单正文 ② 只要求"真正写入 WorldState"，且硬约束明令不写 `teamwork/Rank-3/`；两个 flag 已按三段式在 WorldState 中真实读写并落盘，登记表追加行留待 Rank-3 / 主 AI 处理。**如实登记为未达项，不冒充完成**。
3. **对象段 `encounter_01` 对齐**：GRACE §2.3 要求与 Rank-2 实际遭遇 id 统一；本轮按任务单给定字面量 `encounter_01` 落地，并由 `EncounterRulesV020.ENCOUNTER_ID` 单点驱动（数据表 id `boss_01_margit` 仍是 §3.1 对账基准，未改）；未改 Rank-3 口径文档的对象段（目录所有权）。
4. **`grace_retry` reason 字面量**：沿用 GRACE-RETRY-V020.md §4.1 新增定义，仅作用于 `meta.last_commit_reason` 字符串，未新增顶层字段、未触发 `schema_version` 迁移；若裁决要求复用 `grace_rest`，替换字符串即可，时序不变（如实登记）。
5. **`128bit` 歧义**：仍待用户确认，**未消歧、未编码进任何期望值**；本轮 v030 不涉及美术色数口径。
6. **裁决 A15 / A16 / A17（总指挥裁决，非本工位范围）**：A16 的 `run/main_scene` 改指 `courtyard.tscn` 属 Rank-1 独占 `project.godot`，本轮四路均不写，未执行；A17 人工试玩属用户侧，本轮只做代码验收、不冒充完成；A15 美术色数口径属 Rank-4，未涉及。
7. **不对跨模块争议做最终裁决**；未生成 `00-汇总.md`；未自行 `git commit/push`（总指挥收尾）；零付费、零外部依赖，未引入任何付费素材或外部生成服务；未新建只读探针 / 测量 / preflight / 巡检脚本，未主动扫目录做进度巡检。
8. **并发保护复核**：写交付前复核 `teamwork/Rank-2/DONE-R25.md`、outbox 与 `command_center/dispatcher/receipts/` 下 `cmd-20261110-204604-823-A2.json` / `receipt_cmd-20261110-204604-823-A2.json` 均不存在，无并发实例写齐，故正常写一份 DONE 与一份回执（不写第二份）。检索到的 `teamwork/Rank-3/DONE-R25.md` 属 Rank-3 工位，未动。**回执写入 outbox 后被中枢即时消费为空（任务单说明属正常、不视为缺失），并归档至 `teamwork/command_center/dispatcher/receipts/cmd-20261110-204604-823-A2.json`（1579 B，读回复核内容与写入一致、`result` 引用本 DONE 真实结论）；同 id 回执已存在于 receipts 归档，只复核、不重复写第二份。**

---

## 5. 二次独立复核记录（本 AI 实例，21:08–21:18；不改动上文任何正文）

本次接单时，上文 §1–§4 的 DONE 与回执已由同一任务单下的并发实例在 21:06 落地。本 AI **未覆盖、未重写任何并发成果**，另做一次独立真跑复核，结论与 §3 一致：

- **门禁独立真跑**：`R25-gate1-import.log` / `R25-gate2-{encounter_director,encounter_rules_v020,verify_encounter_v010,verify_encounter_v020,verify_encounter_v030}.log` / `R25-gate3-quit.log` 共 7 段，全 `EXIT=0`，逐段 `grep SCRIPT ERROR=0`、`Parse Error=0`、`ERROR_COLON=0`（G2 扩到 5 个脚本，覆盖两个被改 `.gd`）。
- **三 verify 独立真跑**：`R25-verify_encounter_v030-run.log` = **53 PASS / 0 FAIL**、`R25-verify_encounter_v020-run.log` = **45 PASS / 0 FAIL**、`R25-verify_encounter_v010-run.log` = **20 PASS / 0 FAIL**，三者 `RESULT=ALL_MATCH`、`EXIT=0`、`PASS=false` 命中 0、`SCRIPT ERROR=0`。v030 关键断言（A13 `a13_plain_boss_blocked_by_l1` / `a13_replay_boss_full` / `a13_can_damage_after_rest` / `a13_l1_still_true` / `a13_l1_ignored`、两 flag `retried_inc_1` / `retry_active_true` / `commit_reason_grace_retry` / `retry_spam_gated` / `retried_monotonic`、削韧 `poise_after_hit=98.0` / `poise_to_zero_stance_broken` / `poise_break_reset=120.0` / `poise_break_window=2.5` / `poise_regen_after_delay=98→120`、处决 `execute_window_open/closed` / `execute_out_of_reach`、异常 `status_trigger=420.0` / `status_resistance_gain=25.0`、0 血 `no_double_settle=9`、依赖缺失 4 条）逐条核对全 PASS。
- **落盘硬证据（补 §2 / §3 未覆盖的一项）**：单独真跑 v030（`R25-verify-v030-run.log`）后立即读 `user://saves/slot_01/delta.json`，`flags` 实测含 `"grace.encounter_01.retried": 2`、`"grace.encounter_01.retry_active": false`、`"world.boss_01_margit.defeated": true`、`"combat.boss_01_margit.defeated": true`，`meta.last_commit_reason` 由 commit 链写入，**无任何 removals 删除痕迹** —— 直接证明任务 ②「两个 flag 真正写入 WorldState 并落盘」与 A13「绝不清除永久记录、不用 removals」。
- **`--script` 模式边界（如实）**：该落盘 `delta.json` 顶层实测为 `{flags, meta, seq}` 简化结构（非 `存档与flag规范.md` §4.1 十字段），系验证模式下 WorldState autoload 初始化时序所致；两个新 flag 与两个 L1 永久 flag 均真实持久化。十字段结构属 Rank-3 存档实现 / 脚本模式边界，本 AI 不越界改 `world_state.gd` / `save_delta_writer.gd`，如实登记、不冒充满足十字段。
- **回执核验**：`teamwork/command_center/dispatcher/receipts/cmd-20261110-204604-823-A2.json`（1579 B，21:06）内容合法（`task_id` / `ai=2` / `status=done` / `result` 引用本 DONE 实际结论），`dispatcher/dispatcher.log:510` 有 `[2026-11-10 21:06:04] ← 2 号 AI 回执 <cmd-20261110-204604-823-A2>` 接收记录；outbox 当前为空系 dispatcher 既定消费机制，按 R24 DONE 与本文件 §4.8 惯例**不重复写第二份回执**，验收以 receipts 归档 + dispatcher.log 为准。
- **结论**：5 项任务全部完成、无回退、无阻塞；本 AI 只新增 `teamwork/Rank-2/R25-*.log` 真跑日志与本复核小节，未改任何 `.gd` / 契约 / 场景 / 数据表，未自行 git。
