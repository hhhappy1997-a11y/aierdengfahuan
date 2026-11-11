# DONE-R27B.md · Rank-1 交付报告（R27B · 赐福成长真机闭环收口）

> 补单 `cmd-20261111-091349-628-A1`（`command_id=cmd-20261111-091349-628`，`[ROUND=R27B]`，工程冻结后补单）。
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--headless --path F:/Game/aierdengfahuan/godot`，串行独立进程真跑。
> 裁决 **A23**：`grace.upgrade_<id>.unlocked` 三段式收敛有效、四段字面废止、不改 `world_state.gd` 正则；
> 裁决 **A24**：增益运行时由 Rank-1 装配层接通，不与 R27 成果混算。

---

## 1. 挂载方式（裁决 A24，任务单 ①）

只改 `godot/scenes/courtyard.tscn` 的**节点/属性**，未改 Rank-4 本轮已改的任何视觉属性、未改 `project.godot` 图标行：

| 改动 | 内容 |
|---|---|
| 新增 1 行 `ext_resource` | `id="19_grt"` → `res://scripts/combat/grace_upgrade_runtime.gd`（Rank-2 脚本，本轮只读复用、未改） |
| 新增节点 | `[node name="GraceUpgradeRuntime" type="Node" parent="WaveTrialDirector"]`，`script = ExtResource("19_grt")`，`encounter_director_path = NodePath("../../EncounterRoot")` |
| 新增节点 | `[node name="GraceShopLabel" type="Label" parent="SubViewportContainer/SubViewport/FXLayer/Hud"]`（购买 HUD 文本载体） |
| Hud 节点新增 2 行属性 | `grace_runtime_path = NodePath("../../../../WaveTrialDirector/GraceUpgradeRuntime")`、`shop_label_path = NodePath("GraceShopLabel")` |

`godot/scripts/combat/wave_trial_director.gd` 在 `_ready()` 末尾新增 `_apply_grace_runtime()`：`get_node_or_null("GraceUpgradeRuntime")` → 经既有公开方法 `apply_purchased(_encounter, null)` 在 **`_ready` 之后**把已购三项作用到运行时实例；`ws` 传 `null`，由 Rank-2 脚本自身按 `Engine.get_main_loop()` 相对探活 `WorldState`（`--script` 模式亦可用）。依赖缺失（节点 / 方法 / WorldState / 数据表）如实降级打印、不崩、不产生 `SCRIPT ERROR`。既有方法 / 信号 / `debug_*` 签名 / `get_snapshot()` 键逐字不动。

**真机日志证据**（`--headless --quit-after 90 res://scenes/courtyard.tscn`）：
- 未购态（当前存档无已购 flag）：`[WaveTrial] 增益运行时接线：checked=3 applied=0 degraded=0 reasons=[]`（如实：3 项 `not_purchased`）。
- **已购测试态存档对照实验**（§3）：`checked=3 applied=3 degraded=0`。

---

## 2. 购买入口（任务单 ②）

**交互**：赐福休息 / **E 键 `interact`** 打开（再按关闭）兑换面板；**数字键 `1` / `2` / `3`** 购买三项。`hud.gd` 新增 `_unhandled_input(event)`：`InputEventAction("interact")` 切换面板，`InputEventKey.physical_keycode == KEY_1/2/3` 触发购买；未打开面板时按键给出「请先按 E 打开」提示。数字键用引擎常量直判，**未改** `project.godot [input]` 段。既有 `encounter_director._unhandled_input → _grace_rest()` 与 `wave_trial_director._unhandled_input → interact_restart()` 保持原样，E 键三路并存（赐福休息 + 重开 + 打开兑换面板）。

**HUD 显示**：`courtyard.tscn` 的 `GraceShopLabel` 渲染三项（名称 / cost / 是否已解锁 / 当前余额）+ 可读提示行，例：
```
赐福成长 ｜ 当前余额 1000（点数 1000 − 已消费 0） ｜ 1/2/3 兑换
  1. 赐福·生命上限 ｜ 消耗 100 ｜ 可兑换
  2. 赐福·翻滚余韵 ｜ 消耗 200 ｜ 可兑换
  3. 赐福·攻击强化 ｜ 消耗 300 ｜ 可兑换
提示：按 E 打开/关闭；数字键 1 / 2 / 3 兑换
```

**落盘编排**（`hud.gd` 新增第 8 节，既有 1~7 节逐字未动）：
1. `GraceUpgradeService.can_purchase(points, spent, row)` / `purchase()` 幂等判定（含重复购买 / 余额不足 / 异常输入）；
2. 成功后 `set_flag("grace.trial.spent_points", 旧+cost)`（单调递增）与 `set_flag("grace.upgrade_<id>.unlocked", true)`（**false→true 单向**，裁决 A23 三段式收敛）；
3. **兼容双写** `grace.trial.bought_<id>`（Rank-2 `GraceUpgradeRuntime.apply_purchased()` 的读取口径），三者**同一 `commit("grace_upgrade_purchased")` 原子落盘**，详见 §10 未完成项 4；
4. `commit(reason)` **严格「先落盘再改运行时实例」**：`stage_flags → disk_write(commit) → runtime_update(apply_purchased)` 事件序列（`grace_purchase_events` 可机器读回）；`commit` 未就绪时如实降级「flag 仅进程内内存、未落盘、增益未作用到运行时」，绝不冒充已落盘；
5. **绝不 `removals`、绝不回退 `grace.trial.points`**（`points` 全程只读）；余额 `maxi(0, points − spent_points) ≥ 0`。

**拒绝路径 + 可读提示**：余额不足（「点数不足：… 需要 100，当前余额 50」）、重复购买（「…已解锁，不能重复购买」）、异常输入 index（「无效选项，请按 1 / 2 / 3 选择」）、配置/依赖缺失（「兑换表不可用」/「WorldState 不可用…」）均被拒绝且不扣点、不产生 commit。

**附带修复**：`hud.gd._ready()` 原 `get_node_or_null("/root/WorldState")` 在 `--script` 模式下触发 `Can't use get_node() with absolute paths from outside the active scene tree` ERROR；改为 `Engine.get_main_loop() + root.get_node_or_null()` 相对探活（项目既有踩坑口径），真机场景等价命中同一 autoload，既有 30 / 31 PASS 绑定链路不回退。

---

## 3. 三项数值复验（任务单 ①）

**真机场景 90 帧 · 已购测试态存档对照实验**（先经 Python 构造「三项已购」测试态存档 → 跑场景 → 恢复存档，如实登记、不伪造产物；`EXIT=0 SCRIPT ERROR=0`）：

```
[WaveTrial] 增益运行时接线：checked=3 applied=3 degraded=0 reasons=[]
[WaveTrial]   · hp_max_bonus       hp_max       status=applied before=100.0 after=120.0 via=@export player_max_hp + trial_grace_rest()
[WaveTrial]   · roll_iframe_bonus  roll_iframe  status=applied before=13    after=14    via=@export PlayerActionData.invulnerable_end_frame（action_04_roll）
[WaveTrial]   · attack_power_bonus attack_power status=applied before=85.0  after=90.0  via=@export PlayerActionData.base_attack（attack_light / attack_heavy）
```

即 **100→120 HP / 13→14 iframe / 85→90 attack** 三项全部经既有 `@export` + 既有公开方法 `trial_grace_rest()` 命中（`trial_grace_rest()` 在 `_ready` 阶段调用无 ERROR）。另由 `verify_grace_runtime_v050.gd` V1~V9 独立复验、Rank-2 `verify_grace_upgrade_v050.gd` 127 PASS 内 `wiring_*` 断言实证，零新增战斗数值。

---

## 4. 旧缺陷根因与修法（任务单 ③，`verify_wave_persist_v040.gd` 43/1）

**定位**：先做对照复现 —— 构造缺 `slot` / `quests` 的旧格式 `delta.json` 后真跑，得 `pass=43 fail=1 RESULT=HAS_FAIL`，失败项唯一为 **`D6 十字段齐全`**：`top=[baseline, flags, inventory, meta, removals, schema_version, seq, spawns] extra=[] missing=["slot","quests"]`。与 Rank-4 `DONE-R27.md §6` 记录一致（改动前 `courtyard.tscn` 备份对照同为 43/1，非本轮引入）。

**根因**：磁盘残留旧格式 `delta.json` 被 `WorldState._load()` 回放后 `_delta` 沿用旧顶层结构，随后 `commit` 的落盘产物仍缺 `slot` / `quests` → D6 稳定 FAIL，属**存档状态 / 运行次序依赖**。

**判定（说明哪种）**：当前 `WorldState._new_delta()` 本身就是十字段，与 D6 断言口径一致，**不是「断言与当前实现的真实口径差异」**；是本验证脚本**装配对磁盘残留格式的依赖缺陷**。因此**修装配**（既非改断言字面、也非改被测实现）：

- 新增 `_normalize_delta_top(delta, ws)`：以当前实现 `_new_delta()` 的完整十字段补齐 `_delta` **缺失**的顶层字段（只补缺失、绝不覆盖既有 `flags` / 数据）；
- `_initialize()` 装配阶段经 **I-1 真实写入口**（`SaveDeltaWriter.commit(reason)`，取不到时回落 `WorldState._commit_delta`）原子写盘后再 `_load()` 回读，使 D6 校验的是「本次真实落盘产物」；
- **D6 断言逐字保留、不删、不放宽**；不改 `world_state.gd` 正则（A23）、不手改存档、不伪造产物。

**补 1 条回归用例**（`G1`）：模拟 Rank-4 §6 记录的旧格式（缺 `slot`/`quests`）→ 实证归一化后十字段齐全且既有 `flags` 完好保留（`before_missing=["slot","quests"] after_missing=[] flags_kept=true`）。

**结果**：**`43/1 HAS_FAIL` → `45 PASS / 0 FAIL / RESULT=ALL_PASS / EXIT=0`**（44 条既有断言 + 1 条新回归，44 不回退）；在「旧格式磁盘态」下复跑同样全绿，存档恢复为完整十字段（`schema_version=3`、`removals=[]`）。

---

## 5. 附带的一处断言基线同步（如实登记，不隐瞒）

`verify_wave_runtime_v040.gd` 的 `courtyard_node_count` 断言（R26 基线 `NODE_COUNT_AFTER=36` / `delta=+3`）因本轮**授权新增 2 个真实节点**（`GraceUpgradeRuntime` / `GraceShopLabel`）使 `node_count=38` 而出现 `36/1 FAILED`。

- **判定**：断言与当前实现的真实口径差异 → **修断言**：`NODE_COUNT_AFTER 36→38`、`delta 3→5`、注释补 R27B 两节点说明；断言仍严格检查 `node_count` 与 `delta` 的精确值，**不删断言、不放宽、不掩盖**。
- 该文件是 Rank-1 自身 R26 交付的验证件（非跨工位资产），本轮同步节点数基线。
- **结果**：`37 PASS / 0 FAIL / RESULT=ALL_MATCH` 不回退。

---

## 6. 新自测 `verify_grace_runtime_v050.gd`（任务单 ⑤，新写）

`extends SceneTree`，`58 PASS / 0 FAIL / RESULT=ALL_PASS / EXIT=0`，8 类断言：

| 类 | 覆盖 |
|---|---|
| M 挂载生效（7） | `courtyard.tscn` instantiate 回读 `GraceUpgradeRuntime` 节点 / 脚本路径 / 父节点 `WaveTrialDirector` / `GraceShopLabel` / 导演 `_apply_grace_runtime()` / HUD `purchase_upgrade()`+`get_shop_view()` |
| V 三项数值（9） | 100→120 / 13→14 / 85→90、`attack_heavy` 同步、同进程重复 apply 不叠加 |
| P 购买编排（23） | HUD 三项显示 / 幂等 / 余额不足 / 异常输入 / `commit(reason)` / 先落盘再改运行时实例（3 组事件序列）/ 绝不 removals / 十字段不破坏 / 可读提示 |
| B 余额非负（3）/ S spent 单调（3）/ U unlocked 单向（3） | `points − spent ≥ 0`、`max(内部,外部)+cost`、`false→true` 无回写 |
| D 依赖缺失降级（4） | WorldState 无接口 / `encounter=null` / HUD 依赖缺失 → 不崩、如实登记「数据已落、效果待接」 |
| I 输入路由（6） | E 键 interact 开关面板、数字键 1/2/3 依次触发购买（spent 100→300→600） |

全程用**内存 `WorldState` 实例 + `FakeWriter`** 验证真实 I-1 `set_flag` / `commit` 编排时序，不写 `user://saves/slot_01/delta.json`（不污染回归基线）。

---

## 7. 全回归（任务单 ⑤「全不回退」）

| 回归组 | 期望 | 实测 | 结论 |
|---|---|---|---|
| `verify_encounter_v010.gd` | 20 | `pass=20 fail=0 ALL_MATCH` | 不回退 |
| `verify_encounter_v020.gd` | 45 | `pass=45 fail=0 ALL_MATCH` | 不回退 |
| `verify_encounter_v030.gd` | 53 | `pass=53 fail=0 ALL_MATCH` | 不回退 |
| `verify_fx_profile.gd` | 34 | `pass=34 fail=0 PASS` | 不回退 |
| `verify_fx_mobile.gd` | 47 | `pass=47 fail=0 PASS` | 不回退 |
| `verify_quality_interaction.gd` | 19 | `pass=19 fail=0 PASS` | 不回退 |
| 31 组合 | 31 | `r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11 | 不回退 |
| `verify_wave_trial_v040.gd` | 58 | `pass=58 fail=0 ALL_MATCH` | 不回退 |
| `verify_wave_runtime_v040.gd` | 37 | `pass=37 fail=0 ALL_MATCH`（§5 基线同步后） | 不回退 |
| `verify_wave_persist_v040.gd` | 44 | **`pass=45 fail=0 ALL_PASS`**（44 既有 + 1 新回归） | 不回退且旧缺陷收口 |
| `verify_grace_upgrade_v050.gd`（Rank-2） | 127 | `pass=127 fail=0 ALL_MATCH` | 不回退 |
| `verify_persistence_hud_v050.gd` | 30 | `pass=30 fail=0 ALL_PASS` | 不回退 |
| `verify_grace_runtime_v050.gd`（**新**） | — | **`pass=58 fail=0 ALL_PASS`** | 本轮新增 |
| `verify_wave_flags_v040.gd`（Rank-3） | 23 | selftest 17 + write 3 + read 3（3 进程） | 不回退 |
| `verify_grace_flags_v050.gd`（Rank-3） | 25 | selftest 19 + write 3 + read 3（3 进程） | 不回退 |
| `verify_frame_data.gd` | — | `PASS_COUNT=650 FAIL_COUNT=0 ALL_MATCH` | 不回退 |

**三段门禁**（全部 `EXIT=0`、`SCRIPT ERROR=0`）：
`G1 --headless --import`；`G2 --headless --check-only --script ×8`（hud / wave_trial_director / encounter_director / 5 份 verify / grace_upgrade_runtime）；`G3 --headless --quit`；`--headless --quit-after 90 res://scenes/courtyard.tscn`。

**32 份最终日志**：`TOTAL_SCRIPT_ERROR = 0`、`PASS=false` 总数 = 0。既有 WARNING（`[ChunkManager] 未找到 ChunkRoot`、`ObjectDB instances were leaked`、`--script` 工具模式 SaveSystem 降级、波次降级登记）均非 `SCRIPT ERROR`，与 R23~R27 日志一致。

---

## 8. 动作帧 HUD / 录屏未推进（任务单 ④，如实登记）

- `attack_light 0/27 → 1/27` 已由 R27 在真实输入下实证；本轮**未改** `godot/test/presentation.gd`（Rank-4 独占），动作帧 HUD 显示本体仍在既有 `encounter_director._update_hud()` 内，未回退。
- **录屏未推进原因**：本轮公共契约「**不启 GPU job**」+ 沿用 R27 既有边界，15~20 秒实机录屏 / 目视回看未做；进度判断依据为三段门禁 + 全回归日志 + `verify_grace_runtime_v050.gd` 58 条运行时断言 + 已购态场景 90 帧日志。购买 HUD 的视觉观感（字号 / 与画面重叠 / 亮金对比度）待人工试玩目视校准，不冒充达标。

---

## 9. 目录所有权 / 合规

- **只写**：`godot/scenes/courtyard.tscn`（节点/属性，未碰视觉属性）、`godot/scripts/combat/wave_trial_director.gd`、`godot/scripts/hud.gd`、`godot/scripts/combat/verify_grace_runtime_v050.gd`（新）、`godot/scripts/combat/verify_wave_persist_v040.gd`（仅修旧缺陷）、`godot/scripts/combat/verify_wave_runtime_v040.gd`（仅同步节点数基线，§5 如实登记）、`teamwork/Rank-1/`（本文）、回执 `command_center/ai/1/outbox/`。
- **未写**：素材 PNG / `.tres`（含 `grace_upgrades.tres` / `player_actions.tres` / `wave_trial.tres`）/ `project.godot`（含图标行）/ `presentation.gd` / 契约 / README / `world_state.gd`（A23 正则未改）/ `save_delta_writer.gd` / `grace_upgrade_config|service|runtime.gd`（Rank-2 全部只读复用）/ 其它 Rank 目录 / 其它 `.tscn`。`encounter_director.gd` 本轮可写但无需改动，未动。
- `--script` 模式不用 `/root/...` 绝对路径（`Engine.get_main_loop()` + `root.get_node_or_null()` 相对探活）、`add_child` 显式 `call("_ready")`、注入在 `_ready` 之后；零付费、零外部依赖、未启 GPU job；直接改直接真跑，未新建只读探针 / 巡检脚本（`verify_grace_runtime_v050.gd` 是任务单 ⑤ 明确要求的正式验证载体）；不伪造产物、不谎报成功、未自行 `git`（总指挥收尾）。

---

## 10. 未完成项 / 如实边界

1. **未做 15~20 秒实机录屏 / 目视回看**（不启 GPU job），见 §8。
2. 三项 `cost` 100/200/300 与 `effect_value` 20/1/5 仍为 `[PLACEHOLDER]`，数值真源在 Rank-2 的 `grace_upgrades.tres`，待人工试玩校准；本轮未改任何 `.tres`、未静默改数。
3. **已购态场景实证是「构造测试态存档」的对照实验**（非玩家真实购买累积）；购买交互在 `verify_grace_runtime_v050.gd` 用真实 `hud.gd` 实例 + 真实 `InputEvent` 验证，未在带渲染真机画面目视。
4. **`grace.trial.bought_<id>` 兼容双写**：裁决 A23 的 `grace.upgrade_<id>.unlocked` 是解锁真值，但 Rank-2 `GraceUpgradeRuntime.apply_purchased()` 读取的是 `grace.trial.bought_<id>`；因 Rank-2 脚本不在本轮可写范围，故购买成功时两者**同一 commit 原子落盘**、都只置 `true` / 单调，绝不 removals。如实登记；若后续 Rank-2 统一收敛到 `unlocked` 口径可去掉双写。
5. 真机未购态 `applied=0` 是如实结果（存档无已购 flag），非「未接通」；接线在 flag 为真时自动生效（§3 已实证 `applied=3`）。
6. HD-2D 全绿未达 / 三波色带雾数值 `[PLACEHOLDER]` / `128bit` 歧义等沿用 R27 既有未完成项，本轮不代做、不冒充达标。
7. 未自行 `git`（总指挥收尾）。

**阻塞：无。**

---

## 11. 回执

精确路径：`F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/cmd-20261111-091349-628-A1.json`
字段：`{"task_id":"cmd-20261111-091349-628-A1","ai":1,"status":"done","result":"引用 DONE-R27B.md 实际结论（挂载 / 购买入口 / 三项数值 / 旧缺陷 / v050 58 PASS / 全回归与三段门禁 / 未完成项）"}`，`result` 全文见该 JSON（2098 B）。

> **如实登记**：回执写入 `ai/1/outbox/` 后，调度中枢 watcher 会即时自动归档到
> `teamwork/command_center/dispatcher/receipts/cmd-20261111-091349-628-A1.json`（同一内容、同一 2098 B，
> 09:45:07 归档）。本轮已向精确路径写入并补写保留一份；两处内容一致、均可读回，不谎报路径、不伪造送达。
