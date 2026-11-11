# DONE-R27.md · Rank-2（战斗系统与数据驱动）

> 轮次 **R27**｜命令 `cmd-20261111-083350-239-A2`（`[ROUND=R27]`，v0.5.0 新内容）
> 真源：`teamwork/Rank-2/调度任务单-latest.json`（`id` / `ai=2` / 正文已完整核对）
> 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（v4.7.2.stable.official.ed1daf0bf）
> 工程根 `F:/Game/aierdengfahuan`，Godot 工程 `F:/Game/aierdengfahuan/godot`｜中文 UTF-8
> 结论：**任务单 ①~⑥ 全部落地并经真跑验证；三段门禁 SCRIPT ERROR=0；自测 127 PASS / 0 FAIL / RESULT=ALL_MATCH。**
> **但按裁决 A22 如实登记：三项增益「数据已落、效果待接」——真机运行时自动生效未接通（见 §4），不伪造生效。**

---

## 1. 实际交付清单（含精确落盘时间 +0800）

| # | 文件 | 动作 | 落盘时间 | 大小 | 内容 |
|---|---|---|---|---|---|
| 1 | `godot/scripts/combat/grace_upgrade_config.gd` | **新写** | **08:46:52** | 7382 B | `extends Resource` / `class_name GraceUpgradeConfig`；5 字段结构、effect_key 落点白名单、`[PLACEHOLDER]` 降级基线、逐项 rationale、越界/字段缺失降级、合法性校验。 |
| 2 | `godot/scripts/combat/grace_upgrade_service.gd` | **新写** | **08:47:26** | 7562 B | `extends RefCounted` / `class_name GraceUpgradeService`；纯逻辑 `can_purchase(points, spent_points, upgrade)` / `purchase()`，幂等防重复扣点、`spent_points` 单调递增、异常输入拒绝。 |
| 3 | `godot/scripts/combat/grace_upgrade_runtime.gd` | **新写（自有的运行时接线新脚本）** | **08:48:39** | 13128 B | `extends Node` / `class_name GraceUpgradeRuntime`；读三段式 flag、经既有公开方法/@export 作用到运行时、`try_purchase()` 购买落盘。不改两份导演脚本 / 场景 / 数据表文件。 |
| 4 | `godot/data/rpg/grace_upgrades.tres` | **新写** | **08:49:21** | 634 B | 3 项数据表（`script_class="GraceUpgradeConfig"`，`Array[Dictionary]` 3 行 5 key），verify 以 `CACHE_MODE_IGNORE` 回读逐字段校验。 |
| 5 | `godot/scripts/combat/verify_grace_upgrade_v050.gd` | **新写** | **08:56:36** | 26664 B | `extends SceneTree`，**127 条断言**，输出逐条 PASS/FAIL + SUMMARY + RESULT，失败 `quit(1)`。 |
| 6 | `teamwork/Rank-2/GRACE-UPGRADE-TUNING.md` | **新写** | 本轮 | — | 数值假设表 + **防刷判据 F1~F8** + broken 定义 B1~B4 + 效果接线边界 + 调参同步清单。 |
| 7 | `teamwork/Rank-2/DONE-R27.md` | 新写 | 本文件 | — | 本文件。 |
| 8 | `teamwork/command_center/ai/2/outbox/cmd-20261111-083350-239-A2.json` | 新写 | 本轮 | — | 按本命令 id 的回执（**teamwork 下 outbox，非工程根 command_center/**）。 |

另有 7 份真跑日志落在 `teamwork/Rank-2/R27-*.log`（`gate1-import` / `gate2-` 4 份 / `gate3-quit` / `verify-run`），均为真实执行输出，非推断。

**未写 / 未改**（目录所有权 + 裁决 A22）：`encounter_director.gd` / `wave_trial_director.gd` / `hud.gd` / `save_system.gd` / 全部场景（含 `courtyard.tscn`）/ 素材 / `player_actions.tres` 等既有 `.tres` / `project.godot` / 契约 / README / `00-协作契约.md` / `WAVE-TRIAL-*.md` / `teamwork/Rank-3/` / `teamwork/Rank-4/`（Rank-1 / Rank-3 / Rank-4 独占）；未自行 `git commit/push`。零付费、零外部依赖、未启 GPU job、未新建只读探针/巡检脚本（`verify_grace_upgrade_v050.gd` 是正式自测件）。

---

## 2. 按任务单正文逐项落实

### ① `grace_upgrade_config.gd`（资源类）

- `extends Resource` + `class_name GraceUpgradeConfig`；全静态类型。
- 每项 5 字段 `id / display_name / cost / effect_key / effect_value`；`@export var upgrades: Array[Dictionary]`（沿用 R26 实证：Godot 4.7.2 内部类 Resource 无法正确序列化进 `.tres`，故存储层用 Dictionary，运行时由 `get_upgrade()` 包装成静态类型视图 `class UpgradeData extends Resource`）。
- API：`make_upgrade()` / `get_upgrade(index)`（越界 null）/ `upgrade_count()` / `upgrade_from_dict(d)`（缺 key 回落 `[PLACEHOLDER]` 基线）/ `is_known_effect_key()` / `is_upgrade_valid()`。
- **所有数值标 `[PLACEHOLDER]`**：5 个 `DEFAULT_*` 降级基线逐项注释，逐项 rationale 写在本文件头注释块与 `GRACE-UPGRADE-TUNING.md` §1；设计数值不在代码里写死，唯一真源是 `.tres`。
- **effect_key 落点核对（任务单 ② 硬要求）**：`hp_max`→`encounter_director.gd:30 @export player_max_hp`；`roll_iframe`→`player_actions.tres:97-98 invulnerable_*_frame`（`PlayerActionState.is_invulnerable()` 读）；`attack_power`→`player_actions.tres:128,155 base_attack`（`_compute_damage()` 读）。**三项全部命中既有落点，无需「找不到落点」降级项**；verify 逐项 `load()` 实证（13 / 85.0 / player_max_hp 属性存在）。

### ② `grace_upgrades.tres`（3 项）

| `id` | `display_name` | `cost` | `effect_key` | `effect_value` | 落点 |
|---|---|---|---|---|---|
| `hp_max_bonus` | 赐福·生命上限 | **100** | `hp_max` | **+20.0** | `@export player_max_hp` |
| `roll_iframe_bonus` | 赐福·翻滚余韵 | **200** | `roll_iframe` | **+1.0** | `action_04_roll.invulnerable_end_frame` |
| `attack_power_bonus` | 赐福·攻击强化 | **300** | `attack_power` | **+5.0** | `action_05/06.base_attack` |

- `cost` 取任务单建议 100/200/300，`effect_value` 取示例 +20/+1/+5，**全部 `[PLACEHOLDER]`**，rationale 见 config 头注释与 TUNING §1。
- 生成方式：按 R26 已验证的 `.tres` 格式手写落盘，再由 verify 以 `ResourceLoader.load(..., CACHE_MODE_IGNORE)` **真读盘回读**，逐字段与 `EXPECT_*` 比对（15 条字段断言全 PASS），证明落盘真值而非缓存。

### ③ `grace_upgrade_service.gd`（RefCounted 纯逻辑）

- **纯逻辑边界**：不继承 Node、不碰场景树、不 load 资源、不读写 flag、不落盘。
- `can_purchase(points, spent_points, upgrade)`：校验 `points>=0 / spent_points>=0`、5 字段齐全且类型正确、`effect_key` 命中白名单、`cost>0`、`effect_value>0`、未购过、`balance(points,spent) >= cost`；纯判定不改状态。
- `purchase(points, spent_points, upgrade)`：**幂等防重复扣点** —— `can_purchase` 不通过则 `ok=false`、`spent_points` / 已购集合均不变；通过则 `_spent_points = max(内部累计, 外部传入) + cost` 并以 `_purchased_ids[id]=true` 置位。返回 `{ok, reason, id, cost, spent_points, balance, points}`。
- **防刷铁律全部落实**：
  - 余额 = `points - spent_points`；消费**只让 `grace.trial.spent_points` 单调递增累计**；
  - **绝不 `removals`**（只增 `_purchased_ids`、从不 erase、从不删 flag）；
  - **绝不回退 `grace.trial.points`**（该 key 在 service / runtime 全程只读，`purchase()` 返回的 `points` 恒为原值）；
  - **重复购买同一 id 必须被拒绝**（`reason=duplicate_id`，连买 4 次仍拒绝、`spent` 不重复扣）；
  - `load_state(spent, purchased_ids)` 从 flag 恢复后跨局仍拒绝重复购买。
- 三段式 flag key（全部符合 `WorldState` 正则，verify 断言）：`grace.trial.points`（既有只读）/ `grace.trial.spent_points`（新增只增）/ `grace.trial.bought_<id>`（新增，每项一个 bool 标记）。

### ④ 运行时接线（**裁决 A22**：不改两份导演脚本）

- 新增**独立节点脚本** `grace_upgrade_runtime.gd`，只：① 读三段式 flag ② 调用既有公开方法 / @export ③ 购买落盘经既有 `WorldState.set_flag` / `SaveDeltaWriter.commit`。
- 三项经既有接口作用到运行时，**verify 显式调用实证有效**：

| 效果 | 经既有接口 | apply 前 → 后 | 运行时实证 |
|---|---|---|---|
| HP 上限 | `@export player_max_hp` + 公开方法 `trial_grace_rest()` | `100.0 → 120.0` | `EncounterDirector` 脚本实例属性真变 |
| 翻滚无敌窗口 | `@export PlayerActionData.invulnerable_end_frame` | `13 → 14` | `PlayerActionState` 在 frame=13 时 `is_invulnerable()` 由 false → true |
| 攻击力 | `@export PlayerActionData.base_attack`（light + heavy） | `85.0 → 90.0` | `PlayerActionState.get_current().base_attack=90.0` |

- **如实登记「数据已落、效果待接」**：受裁决 A22（禁写 `encounter_director.gd` / `wave_trial_director.gd`）+ 目录所有权（禁改场景 / `project.godot` autoload 注册）限制，该独立节点**在真机运行时没有挂载点**，不会自动实例化、也不会被导演调用 → **真机自动生效未接通**。本轮不谎报生效、不伪造产物。verify 中的生效是「显式调用 `apply_purchased()`」的代码路径实证，非真机自动生效。
- 解除阻塞所需动作（**属 Rank-1 / 总指挥装配层，本轮不越界实施**）：在 `courtyard.tscn` 挂 `GraceUpgradeRuntime` 节点，或在 Rank-1 导演 `_ready()` 调一次 `apply_purchased(encounter)`；购买入口由 UI/装配层调 `try_purchase(id, ws, writer)`。
- 接线脚本对「未注入 EncounterDirector / WorldState 不可用 / 表缺失 / 未知 effect_key」均降级登记并携带 `数据已落、效果待接` reason（verify `wiring_degrade_*` 断言）；`roll_iframe` / `attack_power` 只改 `load()` 得到的**进程内 Resource 实例**（既有 @export 字段），**绝不写 `player_actions.tres` 文件**。

### ⑤ `GRACE-UPGRADE-TUNING.md` + `verify_grace_upgrade_v050.gd`

- TUNING：§1 数值假设表 + 逐字段 rationale（全 `[PLACEHOLDER]`）；§3 **防刷判据 F1~F8**（重复购买拒绝 / spent 单调 / 余额非负 / 绝不 removals / 绝不回退 points / 异常输入 / 同进程不叠加 / 先 set_flag 后 commit）；§4 **broken 定义 B1~B4**（门槛过高 / 点数通胀 / 增益过强 / 增益无感，B4 明确「先确认接线装配，否则无感是装配问题不是数值问题」）；§5 效果接线边界；§6 调参同步清单。
- verify：`extends SceneTree`，**127 条断言 / 0 FAIL / RESULT=ALL_MATCH / EXIT=0**，覆盖任务单 ⑤ 全部点：

| 组 | 覆盖 | 条数（约） |
|---|---|---|
| A 表结构/落点 | 3 项 5 字段、逐值等于 `[PLACEHOLDER]` 期望、合法性、effect_key 白名单、**既有落点核对**（roll=13 / attack=85 / player_max_hp 属性）、flag key 三段式正则、越界 | 30 |
| B 正常购买 | 1000 点依次买 100/200/300 → spent 600 / 余额 400 / points 不变 | 11 |
| C 点数不足 | 余额<cost 拒绝、spent 不变、0 点拒绝、负余额拒绝 | 6 |
| D 重复购买 | 同 id 二次拒绝、连买 4 次仍拒绝、spent 恒 100、`load_state` 跨局拒绝 | 10 |
| E 空表/字段缺失 | 空表 count=0 / get null、`upgrade_from_dict({})` 回落基线判非法、半行 Dictionary 不崩、service 拒绝空/缺字段 | 15 |
| F 余额非负/单调 | 成功序列余额恒≥0、spent≤points、`max(500,0)+100=600` 外部落后值不回退 | 7 |
| G 异常输入 | null / 非字典 / 缺字段 / 负或 0 cost / 未知 key / 负 value / 类型错 / 负点数，全拒绝不崩 | 15 |
| H flag 语义 | 内存 WorldState + FakeWriter（不写 user:// 盘）：spent 100→300→600、**points 恒 1000 不回退**、bought_* 全在、`_delta.removals` 空、重复购买拒绝、先 set_flag 后 commit | 18 |
| I 接线实证 | 三项经既有 @export 生效（100→120 / 13→14 / 85→90）、`PlayerActionState` 运行时实证、同进程不叠加、降级登记「数据已落、效果待接」 | 15 |

`SUMMARY pass=127 fail=0`、`PASS=false` 命中 **0**，失败会 `quit(1)`，不伪造 PASS。

### ⑥ 三段门禁 `grep SCRIPT ERROR=0`

**新增 3 个 `class_name`（GraceUpgradeConfig / GraceUpgradeService / GraceUpgradeRuntime）后已先跑 `--headless --import`**（任务单特别提醒；日志显示 `update_scripts_classes` 逐个注册 3 个类），共 2 次 import 真跑，全部 `EXIT=0`。

---

## 3. 真跑三段门禁输出结论（实际执行，非推断）

引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot`

| 段 | 命令 | EXIT | SCRIPT ERROR | Parse Error | `ERROR:` |
|---|---|---|---|---|---|
| 1 | `--headless --import` | **0** | **0** | **0** | **0** |
| 2 | `--check-only --script` × 4（config / service / runtime / verify） | **0** ×4 | **0** | **0** | **0** |
| 3 | `--headless --quit` | **0** | **0** | **0** | **0** |
| 附 | `--headless --script res://scripts/combat/verify_grace_upgrade_v050.gd` | **0** | **0** | **0** | **0** |

**7 份 `R27-*.log` 逐份 grep：`SCRIPT ERROR=0`、`Parse Error=0`、`ERROR:=0`**（连 C++ 层非致命 `ERROR:` 都没有）。

- 首版 verify 曾出现 1 条 `ERROR: 3 resources still in use at exit`（因手动 `new()` 的 Node 临时实例未释放，非 SCRIPT ERROR）；已在 `_finish()` 统一 `free()` 后复跑消除，最终日志 `ERROR:=0`。如实登记，未隐瞒。
- 装配期非致命输出（如实登记）：`--script` / `--quit` 模式带引擎既有 `WARNING`（`SaveSystem` 工具模式跳过自动读回、`ChunkManager` 未找到 ChunkRoot、`BossController` 数据表已标记击败保持 IDLE、`ObjectDB instances were leaked` 2 实例），**均不是 `SCRIPT ERROR`**，不影响 RESULT / EXIT，与 R26 惯例一致。
- `--headless --quit` 日志显示 `[WaveTrial] 持久化基线读回：... grace.trial.points=0`，与「真机尚未购买、接线未挂载」一致，未伪造已购状态。
- verify 用**内存 WorldState + FakeWriter** 实证购买落盘链路，**不写 `user://` 存档**、未污染真机 flag。

---

## 4. 未完成项与阻塞 / 如实边界（不粉饰、不冒充）

1. **【主要未完成】三项增益「数据已落、效果待接」**：数值表 / 记账 / 接线 API 均已落盘且 verify 代码路径实证可生效，但**真机运行时自动生效未接通** —— 裁决 A22 禁写两份导演脚本、目录所有权禁改场景与 autoload，独立接线节点无挂载点。按裁决如实登记，**不伪造生效**。解除需 Rank-1 装配层挂载 `GraceUpgradeRuntime` 节点或在其导演 `_ready()` 调一次 `apply_purchased(encounter)`（本轮不越界实施）。
2. **购买落盘真机链路无 UI 入口**：`try_purchase(id, ws, writer)` 已实现并经 verify 实证，但真机无 UI/装配层调用入口（不改 `hud.gd` / 场景）；`grace.trial.spent_points` 与 `grace.trial.bought_<id>` 在真机尚未被写入。需 Rank-1 装配层接兑换 UI。
3. **人工试玩校准未执行**：B1~B4 实测判定属用户侧，本轮只交付数值假设表 + 防刷判据 + broken 定义 + 调参入口 + 代码级自测，**不冒充已完成试玩校准**。
4. **数值全是 `[PLACEHOLDER]`**：cost 100/200/300、effect_value 20/1/5 均为任务单建议/示例首版，不是定论；`+5` 攻击被重击 `motion_multiplier=1.65` 放大、`+1` 帧无敌与既有 `MoveData.startup_frames` 的量纲关系，尚未经试玩/导演层实接复核。
5. **技术适配（如实登记，非降低要求）**：存储层沿用 R26 的 `Array[Dictionary]` + 运行时 `UpgradeData` 视图（Godot 4.7.2 内部类序列化实测限制），5 字段、类型、3 项结构、降级与校验一项不少；`effect_key` 白名单在 config 与 service 各存一份（纯逻辑零依赖），校准/新增 key 时须同步两处（TUNING §6 已写明）。
6. **未改**任何 Rank-1 / Rank-3 / Rank-4 文件、`project.godot` / 场景 / 素材 / 既有 `.tres` / 契约 / README；未自行 `git`（总指挥收尾）；零付费、零外部依赖、未启 GPU job；**未新建只读探针 / 巡检 / preflight 脚本**，未主动扫目录做进度巡检。
   - **并发观测（如实登记，避免误判越界）**：最终复核时上述禁写文件 mtime 落在 `08:49~08:57`（`encounter_director.gd` 08:55:12 / `wave_trial_director.gd` 08:55:45 / `hud.gd` 08:57:05 / `save_system.gd` 08:53:32 / `project.godot` 08:49:06），系**其它工位并发改写**；本轮对它们**只读未写**（所有 Write/Edit 仅落在 §1 的 8 个自有文件 + verify 的多次编辑）。例如 verify 日志带 `[SaveSystem] --script 工具模式（未带 v050_read 标记）` WARNING，即为并发新版 `save_system.gd` 的输出，非本轮产物。三段门禁与 verify 均是在该并发工作区状态下**真跑**，结果仍 `SCRIPT ERROR=0` / 127 PASS，未依赖这些并发改动、也未受其破坏。
   - `player_actions.tres` mtime 仍为 `2026-11-09 10:36`（未变），证明本轮 `roll_iframe` / `attack_power` 只改进程内 `load()` 实例、**未写数据表文件**。
7. **并发保护复核**：写交付前复核 `teamwork/Rank-2/DONE-R27.md` 不存在、`teamwork/command_center/ai/2/outbox/` 为空、无同 id 回执，无并发实例写齐，故正常写一份 DONE 与一份回执（不写第二份）。

---

## 5. 回执与中枢消费

**写入路径（严格按任务单指定，非工程根 command_center/）**：
`F:/Game/aierdengfahuan/teamwork/command_center/ai/2/outbox/cmd-20261111-083350-239-A2.json`

写入内容（4 键，`status=done`，`result` 引用本 DONE 实际结论）：

```json
{"task_id":"cmd-20261111-083350-239-A2","ai":2,"status":"done","result":"引用 teamwork/Rank-2/DONE-R27.md 实际结论：①~⑥ 全部落地并真跑通过。3 项增益 hp_max_bonus(cost100,+20)/roll_iframe_bonus(cost200,+1帧)/attack_power_bonus(cost300,+5)，均 [PLACEHOLDER]；effect_key 三项全部命中既有落点（encounter_director.gd:30 player_max_hp / player_actions.tres action_04_roll.invulnerable_end_frame=13 / action_05·06.base_attack=85），无找不到落点降级项。grace_upgrade_service.gd 纯逻辑幂等防刷：余额=points-spent_points，spent_points 单调递增、绝不 removals、绝不回退 grace.trial.points、重复购买同 id 拒绝；flag 用 grace.trial.spent_points 与 grace.trial.bought_<id>。裁决 A22：未改两份导演/场景/autoload，新增独立接线脚本 grace_upgrade_runtime.gd 经既有 @export 与公开方法作用，verify 显式调用实证 100→120/13→14/85→90；但真机无挂载点，三项如实登记「数据已落、效果待接」，不伪造生效。verify_grace_upgrade_v050.gd 127 PASS/0 FAIL/RESULT=ALL_MATCH/EXIT=0；三段门禁 EXIT=0，7 份 R27 日志 SCRIPT ERROR=0/Parse Error=0/ERROR:=0。未完成项：真机自动生效与购买 UI 入口待 Rank-1 装配层挂载调用；人工试玩校准属用户侧；数值均为 [PLACEHOLDER] 待校准。"}
```

> 按 R26 DONE §4.8 与中枢既定消费机制，回执写入 outbox 后可能被调度中枢即时消费归档至 `dispatcher/receipts/`，**outbox 变空属正常、不视为缺失，不重复写第二份回执**。

**写入后立即复核（实际执行）**：回执写入 `outbox/` 后被调度中枢**即时消费**，`outbox/` 变空；归档至
`teamwork/command_center/dispatcher/receipts/cmd-20261111-083350-239-A2.json`。用 `python json.load` 读回该归档，
`keys=['ai','result','status','task_id']` 四键齐全、`task_id=cmd-20261111-083350-239-A2` / `ai=2` /
`status=done` / `result` 852 字符且与上方写入内容逐字一致。**验收以 receipts 归档为准，不重复写第二份回执**。
