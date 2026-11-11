# DONE-R28.md · Rank-2（战斗系统与数据驱动）

> 轮次 **R28**｜命令 `cmd-20261111-095602-824-A2`（`[ROUND=R28]`，v0.6.0）
> 真源：`teamwork/Rank-2/调度任务单-latest.json`（`id` / `ai=2` / 正文已完整核对）
> 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`）
> 工程根 `F:/Game/aierdengfahuan`，Godot 工程 `F:/Game/aierdengfahuan/godot`｜中文 UTF-8
> 结论：**任务单 ①~⑤ 全部落地并经真跑验证**。三段门禁 `EXIT=0`、`grep SCRIPT ERROR / Parse Error = 0`；
> 新增 `class_name TutorialConfig` 已 `--headless --import` 注册（`global_script_class_cache.cfg:307`）。
> 奖励校验 **86 PASS**、自有存档隔离回归 **31 PASS**（并发 3 轮全稳定）、
> 既有 `127 / 58 / 11 PASS` 全不回退；存档初态前后对照 **9/2 → 11/0**。
> **按目录所有权如实登记 ③ 双写收敛的影响范围与遗留项（§2③ / §4），不谎报生效、不越界改导演层。**

---

## 1. 实际交付清单

| # | 文件 | 动作 | 大小 | 内容 |
|---|---|---|---|---|
| 1 | `godot/scripts/combat/tutorial_config.gd` | **新写** | 8042 B | `extends Resource` / `class_name TutorialConfig`；三步 5 字段结构、`[PLACEHOLDER]` 降级基线、`expected_action` 白名单与落点核对、逐项 rationale、`TutorialStep` 静态类型视图、`is_reward_monotonic()`。 |
| 2 | `godot/data/rpg/tutorial_steps.tres` | **新写** | 644 B | 3 步数据表（`script_class="TutorialConfig"`，`Array[Dictionary]` 3 行 5 key），verify 以 `CACHE_MODE_IGNORE` 真读盘逐字段校验。 |
| 3 | `godot/scripts/combat/verify_tutorial_reward_v060.gd` | **新写** | 20223 B | `extends SceneTree`，**86 条断言**，6 类奖励校验 + 双写收敛旁证，输出 PASS/FAIL + SUMMARY + RESULT，失败 `quit(1)`。 |
| 4 | `godot/scripts/combat/grace_upgrade_service.gd` | **改（③ 双写收敛）** | 12439 B | 集中式 `purchased_flag_key()` 收敛到权威 unlocked；新增 `authoritative_unlocked_key()` / `legacy_bought_flag_key()` / `is_purchased_in_flags()` / `collect_purchased_ids_from_flags()` / `load_state_from_flags()`；**F1~F8 防刷逻辑逐字未动**。 |
| 5 | `godot/scripts/combat/verify_save_isolation_v060.gd` | **新写（自有回归隔离脚本）** | 15555 B | `extends SceneTree`，**31 条断言**；每进程 `OS.get_process_id()` 唯一独立临时槽 + 运行前显式写基线，输出前后对照数字 + SUMMARY + RESULT。 |
| 6 | `teamwork/Rank-2/DONE-R28.md` | 新写 | 本文件 | 本文件。 |
| 7 | `teamwork/command_center/ai/2/outbox/cmd-20261111-095602-824-A2.json` | 新写 | — | 按本命令 id 的回执（**teamwork 下 command_center/ai/2/outbox，非工程根 command_center/**）。 |

另有 `teamwork/Rank-2/R28-*.log`（gate1 / gate2 × 8 / gate3 / BEFORE / AFTER / concurrent / final / run）共 30+ 份真跑日志，均为真实执行输出，非推断。

**未写 / 未改**（目录所有权硬约束）：`tutorial_director.gd` / `wave_trial_director.gd` / `encounter_director.gd` / `hud.gd` / `courtyard.tscn` / 全部场景与素材 / `project.godot` / `00-协作契约.md` / `README.md` / `godot/test/presentation.gd` / 既有 `.tres`（除本轮授权新建的 `tutorial_steps.tres`）/ `world_state.gd` / 生产存档逻辑 / 契约；未自行 `git`。零付费、零外部依赖、未启 GPU job、未新建只读探针 / 巡检脚本（两份 verify 均为真跑断言的正式自测件）。

---

## 2. 按任务单正文逐项落实

### ① 教学数据表 `tutorial_config.gd` + `tutorial_steps.tres` + rationale

- `extends Resource` + `class_name TutorialConfig`；全静态类型。
- 三步结构逐字段：`step_id / prompt / expected_action / reward_points / timeout_sec`；`@export var steps: Array[Dictionary]`（沿用 R26/R27 实证：Godot 4.7.2 内部类 Resource 无法正确序列化进 `.tres`，故存储层用 Dictionary，运行时 `get_step()` 包装成 `TutorialStep` 视图）。
- **数值全标 `[PLACEHOLDER]`**：5 个 `DEFAULT_*` 降级基线逐个标注（空 id / 空 prompt / 空 action / 0 奖励 / 0 时限），只保证「不崩、可判非法」，不是设计数值；设计数值实例只在 `.tres`，头注「设计数值 `[PLACEHOLDER]` rationale」块逐项写「为什么」，`KNOWN_ACTIONS` 亦标首版 `[PLACEHOLDER]`。
- **expected_action 既有落点核对（全部命中 `project.godot [input]`，零新增键位）**：`J`→`light_attack`(physical_keycode=74)、`Space`→`roll`(32)、`E`→`interact`(69，赐福休息 / 打开兑换面板 / 重开试炼)。三步梯度 = 「轻攻击 → 翻滚 → 交互（闭环进赐福系统）」。

**三步数据与逐项 rationale（全部 `[PLACEHOLDER]` 首版，待人工试玩校准）：**

| # | `step_id` | `expected_action` | `prompt` | `reward_points` | `timeout_sec` | rationale |
|---|---|---|---|---|---|---|
| 1 | `step_01_light_attack` | `J` | 按 J 发动一次轻攻击 | **20** | **15.0** | 三步最低；轻攻击是最基础操作，最小正反馈快速建立「按键→反馈」，避免首步权重稀释后两步。梯度单调 20<30<50。 |
| 2 | `step_02_roll` | `Space` | 按 Space 翻滚一次 | **30** | **15.0** | 中档；翻滚含无敌窗口（既有 `[4,13)` 帧）操作难度高于轻攻击，奖励递增匹配「逐步加压」曲线。 |
| 3 | `step_03_interact` | `E` | 按 E 与赐福交互 | **50** | **15.0** | 最高；交互是「进赐福 / 打开成长兑换 / 收束教学」闭环关键步，最大奖励强化玩家记住入口。三步合计 **100** 恰与既有 `grace_upgrades.tres` 第 1 项 `cost=100` 对齐（「完成一轮教学 ≈ 换一项最便宜增益」），**仅为首版巧合对齐、非经济定论**。 |

- `timeout_sec=15.0`（单步统一）：给新手「读提示 + 试按键」充裕窗口、又不至挂机；统一值简化状态机，为 `[PLACEHOLDER]` 首版，试玩后可按步拆分。
- 校准同步清单：`.tres` 数值 → `verify_tutorial_reward_v060.gd` 的 `EXPECT_*` → 本文；**不静默改数**。
- `.tres` 真读盘回读：`verify_tutorial_reward_v060.gd` 以 `CACHE_MODE_IGNORE` 加载，逐字段与 `[PLACEHOLDER]` 期望比对（A 组 26 条全 PASS），证明落盘真值而非缓存。

### ② 奖励校验 `verify_tutorial_reward_v060.gd`

`extends SceneTree`，**86 条断言 / 0 FAIL / `RESULT=ALL_MATCH` / `EXIT=0`**（`R28-final-verify_tutorial_reward_v060.log`）。纯内存夹具：`RewardLedger` 发放器 + `FakeWriter`（只记 `commit(reason)` 时序，不写 `user://` 盘）+ 手动 `new()` 的 `WorldState` 实例（不 `add_child`、不污染生产存档）。

| 任务单 ② 断言 | 实现落点 | 真跑结果 |
|---|---|---|
| 奖励单调 | `TutorialConfig.is_reward_monotonic()` + 逐值 20/30/50 + 非单调表反例（30,20,50→false） | B 组 9 条全 PASS |
| 余额非负 | `GraceUpgradeService.balance(points, spent)`，领取 / 消费 / 超额消费拒绝全程 `balance>=0` | C 组 8 条全 PASS |
| 重复领取拒绝 | `_claimed` 集合，同 step 二次 / 连领 4 次 / 跨 `load_state_from_flags` 恢复仍拒，`points` 不变、失败不 commit | D 组 9 条全 PASS |
| 超时不重复发奖 | `within_timeout=false` 拒绝且不占名额、不置位、不 commit；超时后时限内可领一次且再领被拒 | E 组 11 条全 PASS |
| `grace.trial.points` 只增不减 | 内存 `WorldState.get_flag` 逐次读回序列非递减；失败操作不改 points；`_delta.removals` 恒空 | F 组 7 条全 PASS |
| commit 先落盘 | 事件序列 `stage_flags`(set_flag) 严格早于 `disk_write`(commit)；失败不新增 commit；writer 缺失如实登记降级 | G 组 9 条全 PASS |
| （附）双写收敛旁证 | 权威 key / 兼容 key / `is_purchased_in_flags` / 三段式正则 / F1 不破坏 | H 组 9 条全 PASS |

输出：`[V060] 逐条 PASS=true/false` + `[V060] SUMMARY pass=86 fail=0` + `[V060] RESULT=ALL_MATCH`；失败 `quit(1)`，不伪造 PASS。

### ③ 双写收敛（以 `unlocked` 为唯一权威件，`bought_<id>` 仅兼容读取）

**收敛前后口径**
- 收敛前：`grace.upgrade_<id>.unlocked`（`hud.gd` 裁决 A23 权威）与 `grace.trial.bought_<id>`（Rank-2 运行时读取口径）在同一 commit 内**双写**，冗余。
- 收敛后：`grace.upgrade_<id>.unlocked` 为**唯一权威写入件**；`grace.trial.bought_<id>` **仅兼容读取、不再新写**。

**实现（只改 `grace_upgrade_service.gd`，严守目录所有权白名单）**
所有「运行时读取 / 写入口径」都经本文件的集中式静态函数 `GraceUpgradeService.purchased_flag_key(id)`。R28 起该函数返回权威 `authoritative_unlocked_key(id)` = `grace.upgrade_<id>.unlocked`（常量与 `hud.gd:55-56` 的 `FLAG_UNLOCKED_PREFIX/SUFFIX` 逐字对齐）。因此**无需改任何调用方**即完成全局收敛：
- 新增 `authoritative_unlocked_key()` / `legacy_bought_flag_key()`（旧兼容 key，仅读）/ `is_purchased_in_flags()`（unlocked OR 旧 bought_）/ `collect_purchased_ids_from_flags()` / `load_state_from_flags()` → **既有存档可读**。
- **F1~F8 防刷核心（`_purchased_ids` / `_spent_points` / `can_purchase` / `purchase` / `balance` / `_result`）逐字未动**；key 字符串变化不触及任何防刷判定。真跑佐证：`verify_grace_upgrade_v050.gd` **127 PASS**、`verify_grace_runtime_v050.gd` **58 PASS**、`verify_tutorial_reward_v060.gd` H 组 9 条全不回退。

**影响范围登记（如实，grep 实证）**

| 类别 | 调用点 | 收敛后行为 |
|---|---|---|
| 写入点 × 2 | `hud.gd:785`、`grace_upgrade_runtime.gd:284` `set_flag(purchased_flag_key(...), true)` | 写 `unlocked`；`hud.gd:783` 本就写 `unlocked_key`（同值），两处 `set_flag` 幂等合并为**单写** |
| 读取点 | `hud.gd:643/744`、`grace_upgrade_runtime.gd:96/265` `get_flag(purchased_flag_key(...))` | 读 `unlocked`（权威） |
| 兼容读（新增，仅读） | `grace_upgrade_service.gd` 的 `legacy_bought_flag_key()` / `is_purchased_in_flags()` / `load_state_from_flags()` | 纯 `bought_` 旧档可读，**不生成任何新写件** |
| 全工程调用点 | `purchased_flag_key` 共 **26 处 / 7 文件**（`grace_upgrade_service` / `grace_upgrade_runtime` / `hud` / `verify_grace_upgrade_v050` / `verify_grace_runtime_v050` / `verify_tutorial_reward_v060` / `verify_save_isolation_v060`） | 全部自动收敛 |
| 静态核验 | `grep set_flag[^#]*grace.trial.bought` → **0 处** | 确认不再有任何直接写 `bought_` 字面量的 `set_flag` |

**遗留影响（如实登记，不谎报）**
1. `hud.gd`（Rank-1 所有权）与 `grace_upgrade_runtime.gd`（本轮白名单外）未调用新增兼容函数；它们收敛后只 `get_flag(unlocked)`。生产存档自 R27B 起每次购买都同时落 `unlocked + bought_`，两键成对，收敛**不丢已购态**；「纯 `bought_` 旧档」的兼容读取入口已在本文件提供，调用方接入属 Rank-1 / 总指挥后续动作，本轮如实登记为遗留项。
2. `hud.gd` 头注 / `:784` 关于「同一 commit 内另写 Rank-2 读取口径 `grace.trial.bought_<id>`」的文案与收敛后实际行为（写 `unlocked`）出现偏差；`hud.gd` 归 Rank-1，本轮未改，如实登记。既有 `verify_grace_runtime_v050.gd` 的 P7 断言文案「兼容 `bought_` 同写」同样滞后，但其断言值经 `purchased_flag_key()` 随收敛同步、真跑仍 **58 PASS**，本轮未改、不谎报。
3. 未改 `world_state.gd` 正则（`grace.upgrade_<id>.unlocked` 与 `grace.trial.bought_<id>` 均为合法三段式，H 组正则断言 PASS）。

### ④ 回归脚本存档初态隔离（前后对照数字）

**根因（真跑复现）**：`verify_hud_binding.gd` 的 `A1`（`text` 增量依赖 `grace.network.last_grace_id` 初值空）与 `A2`（点亮态增量依赖 `grace.limgrave_gatefront.lit=false` → DIM）依赖干净初态；并发时某进程写盘的演示 flag 被另一进程经 `SaveSystem._load()`（带 `v050_read` 标记）读回 → A1/A2 FAIL = **9/2 抖动**。

**方案演进（如实）**：首版「共享 `slot_01` + 每次运行前显式写基线」在**严格并发**下仍不稳 —— 真跑发现多进程同时写同一 `delta.json` 会 JSON 半读 / 互相覆盖，且**验证脚本自身 `set_flag` 会被 `SaveDeltaWriter` 落盘重新污染初态**（`AFTER` 后 `shared_slot_01_dirty=8` 即为证据）。故按任务单给出的另一条正解改为：**每进程用 `OS.get_process_id()` 生成唯一独立临时槽** `user://saves/isolated_r28_<pid>/delta.json`，31 条断言全部只读本进程唯一槽、绝不依赖共享 `slot_01`；另「尽力」把同款干净基线显式写一份到 `slot_01`（兼容单进程串行回归，**不参与任何断言**，并发被踩踏也不影响 31 PASS）。**未改 `world_state.gd` 与生产存档逻辑**（只写 `user://` 运行期数据）。

**前后对照数字（全部真跑，日志见 `R28-BEFORE-*.log` / `R28-AFTER-*.log` / `R28-concurrent-*.log`）：**

| 阶段 | 初态 | 真跑载体 | 结果 |
|---|---|---|---|
| BEFORE-1（精确复现历史 9/2） | 构造并发污染档 `last_grace_id=gatefront` / `lit=true` / `trial=true` | `verify_hud_binding -- v050_read` | **9 PASS / 2 FAIL**（A1+A2 双 FAIL，`EXIT=1`） |
| BEFORE-2（开箱磁盘污染档实测） | 原始 `delta.json`（演示 flag） | `verify_hud_binding -- v050_read` | **10 PASS / 1 FAIL**（A2 FAIL，`EXIT=1`） |
| BEFORE-3（并发 3 轮、无隔离） | 共享 `slot_01` 被并发写 | `verify_hud_binding × 3` + 首版隔离脚本 × 3 | HUD 三轮**全 9/2**；首版隔离脚本 **26/5、24/7、24/7**（共享槽互相踩踏） |
| AFTER-1（唯一 PID 槽隔离） | `isolated_r28_<pid>/` 干净基线 | `verify_save_isolation_v060` | **31 PASS / 0 FAIL / `RESULT=ALL_MATCH`**；`isolated_dirty_flags=0` |
| AFTER-2（并发 3 轮隔离） | 3 个不同 PID 槽 `21324 / 24656 / 27448` | `verify_save_isolation_v060 × 3` 同批启动 | **三轮全 31 PASS / 0 FAIL**，0 抖动 |
| AFTER-3（串行写基线后既有回归） | 干净基线 | `verify_hud_binding -- v050_read` | **11 PASS / 0 FAIL**（`EXIT=0`） |
| AFTER-4（普通回归 / 最终态） | `--script` 默认跳过读回 | `verify_hud_binding` | **11 PASS / 0 FAIL** |

**对照结论**：`9/2`（及 `26/5 / 24/7` 抖动）→ 稳定 `31 PASS / 0 FAIL`（并发 3 轮）+ `11/0`（串行既有回归），**0 抖动**。
**如实边界**：本件是 Rank-2 自有的 31 条隔离回归，不冒充 README 标称的既有 `r19_verify_hud(20) + verify_hud_binding(11)` 原脚本（该 `r19_verify_hud.gd` 已不在工程中）；既有 `verify_hud_binding` 的 `9/2 → 11/0` 由上面的串行编排日志另行实证。既有回归脚本本身（Rank-3 历史件）不在本轮白名单内，未改；其并发稳定仍依赖「运行前写基线」或后续迁移到独立槽。

### ⑤ 三段门禁（真跑，`grep SCRIPT ERROR=0`）

```bash
ENG="D:/Godot/Godot_v4.7.2-stable_win64.exe"
PROJ="F:/Game/aierdengfahuan/godot"

# G1 新增 class_name 必须先 --headless --import（TutorialConfig 已注册于 global_script_class_cache.cfg:307）
"$ENG" --headless --path "$PROJ" --import                       # EXIT=0
# G2 解析门禁（8 个脚本全 EXIT=0 / 0 ERROR）
for s in tutorial_config grace_upgrade_service verify_tutorial_reward_v060 \
         verify_save_isolation_v060 grace_upgrade_runtime verify_grace_upgrade_v050 \
         verify_grace_runtime_v050; do
  "$ENG" --headless --path "$PROJ" --check-only --script "res://scripts/combat/$s.gd"
done
# 另检 hud.gd（Rank-1 未改，收敛后仍可解析）EXIT=0 / 0 ERROR
# G3 主场景加载退出
"$ENG" --headless --path "$PROJ" --quit                        # EXIT=0
```

- 三段 `EXIT` 全 `0`；`R28-*.log` 全量 `grep -hE "SCRIPT ERROR|Parse Error" | wc -l` = **0**。
- 新增 `class_name TutorialConfig` 后已 `--headless --import`，`godot/.godot/global_script_class_cache.cfg:307` 出现 `class: &"TutorialConfig"`。
- 真跑自测（最终全量重跑，`R28-final-*.log`）：见 §3。

---

## 3. 真跑输出结论汇总（最终态）

| 脚本 | PASS | FAIL | RESULT | EXIT |
|---|---|---|---|---|
| `verify_tutorial_reward_v060.gd`（本轮新） | **86** | 0 | `ALL_MATCH` | 0 |
| `verify_save_isolation_v060.gd`（本轮新） | **31** | 0 | `ALL_MATCH` | 0 |
| `verify_grace_upgrade_v050.gd`（既有，回归不回退） | **127** | 0 | `ALL_MATCH` | 0 |
| `verify_grace_runtime_v050.gd`（既有，回归不回退） | **58** | 0 | `ALL_PASS` | 0 |
| `verify_hud_binding.gd`（既有，回归不回退） | **11** | 0 | `ok=true` | 0 |
| 并发 3 轮 `verify_save_isolation_v060.gd` | **31 × 3** | 0 | `ALL_MATCH × 3` | 0 |
| G1 `--import` / G2 `--check-only --script` × 9 / G3 `--quit` | — | — | `SCRIPT ERROR / Parse Error = 0` | 0 |

> 说明：`verify_grace_upgrade_v050.gd` 的 `flag_buy_hp_bought_flag_true` / `no_removals_flags_intact` 等断言经 `purchased_flag_key()` 取值，收敛后随 key 同步、真值仍成立（127 PASS 不回退），其**注释文案**仍用旧 `bought_` 口径，属既有脚本、本轮未改，如实登记。

---

## 4. 未完成项 / 阻塞 / 如实边界

1. **教学三步真机接线未装配**：`tutorial_steps.tres` 是数据表，`TutorialConfig` 是资源类；真机读取 / 逐步发放奖励 / 超时状态机需 Rank-1 导演层（`tutorial_director.gd` 等，本轮目录所有权禁写）接线。本轮只交付「数据 + 结构 + 奖励校验逻辑」，**不谎报真机教学已跑通**。
2. **三项赐福增益真机自动生效未接通**（沿用 R27 裁决 A22）：`GraceUpgradeRuntime` 独立节点无挂载点，「数据已落、效果待接」，见 `DONE-R27.md §4` / `GRACE-UPGRADE-TUNING.md §5`，本轮未改导演层 / 场景 / `project.godot`。
3. **纯 `bought_` 旧档兼容读取的调用方接入未做**（§2③ 遗留 1）：入口函数已提供，`hud.gd` / `grace_upgrade_runtime.gd` 未调用，属 Rank-1 / 总指挥后续动作。
4. **既有脚本文案滞后**（§2③ 遗留 2）：`hud.gd` / `verify_grace_runtime_v050.gd` 关于「另写 `bought_`」的注释与收敛后行为有偏差，均不在本轮白名单内，未改、如实登记。
5. **共享 `slot_01` 被验证脚本落盘再污染的机制**：`SaveDeltaWriter` 会把验证进程 `set_flag` 的测试 flag 落盘（`AFTER` 后实测 `shared_dirty=8`）；本轮用唯一 PID 槽绕开，但**既有回归脚本并发仍需「运行前写基线」或后续迁移独立槽**，未改其本体（不在白名单）。
6. **人工试玩校准（B1~B4 / 教学 20/30/50 / 15s）未执行**，属用户侧；所有数值为 `[PLACEHOLDER]` 首版，本文只给 rationale 与同步清单，不冒充已校准。
7. **未做 15~20 秒实机录屏回看**：本轮为 headless 数据 / 逻辑 / 门禁任务，无渲染管线可录；沿用契约「headless 无法替代人眼与手感判断」的如实边界，不伪造画面证据。
8. `git status` 中 `README.md` / `courtyard.tscn` / `hud.gd` / `wave_trial_director.gd` / `presentation.gd` / 契约 等显示为 modified，系**其它工位并发改动，非本轮所为**；本轮未自行 `git commit/push`。零付费、零外部依赖、未启 GPU job、未新建只读探针 / 巡检脚本。
9. **原 `user://saves/slot_01/delta.json`**（开箱演示污染档）已备份到 `teamwork/Rank-2/R28-delta-original.json`；本轮为前后对照构造过污染档、最终由隔离脚本写为 R28 干净基线（`flags={}`，schema_version=3 十字段齐全）。属运行期数据、非工程文件，如实登记。

---

## 5. 回执

- **精确路径（任务单指定）**：`F:/Game/aierdengfahuan/teamwork/command_center/ai/2/outbox/cmd-20261111-095602-824-A2.json`（`teamwork` 下 `command_center`，非工程根 `command_center/`）。
- 内容：`{"task_id":"cmd-20261111-095602-824-A2","ai":2,"status":"done","result":"引用 DONE-R28.md 实际结论（①~⑤ 全部落地；奖励校验 86 PASS、隔离回归 31 PASS 并发 3 轮稳定、既有 127/58/11 PASS 不回退；前后对照 9/2 → 11/0；三段门禁 EXIT=0 且 grep SCRIPT ERROR=0；双写收敛影响范围与遗留项如实登记）"}`。
- **调度中枢自动收件行为（如实登记）**：`outbox` 写入后，调度中枢 dispatcher 会「收件即归档」——把回执
  移入 `teamwork/command_center/dispatcher/receipts/cmd-20261111-095602-824-A2.json` 并清空 `outbox`，
  同时写 `dispatcher/dispatcher.log` 与 `ai/2/status.json`。本轮回执共写入精确 `outbox` 路径 **3 次**，
  `dispatcher/dispatcher.log:600/601/602` 三行「← 2 号 AI 回执 `<cmd-20261111-095602-824-A2>` 完成」
  （`10:34:13 / 10:35:30 / 10:36:28`）为接收铁证；`ai/2/status.json` 已置
  `state=idle / current_task="" / completed=32`，说明总指挥已收件结案。归档副本 `receipts/<id>.json`
  与本轮写入内容逐字一致（JSON 合法 / `ai=2` / `status=done`）。
  因 dispatcher 持续监控，`outbox` 在收件后为空属标准流程（非交付缺失）；本轮未改调度中枢任何
  脚本 / 配置，未自行 `git`。
