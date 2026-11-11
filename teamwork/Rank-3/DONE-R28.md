# DONE-R28.md · Rank-3 交付报告（R28 · v0.6.0 赐福引导三步教学 GDD / 引导 blockout / flag 登记 / 验证与文档）

- 任务：`cmd-20261111-095602-827-A3`，`[ROUND=R28]`，**v0.6.0 新内容**，Rank-3 执行 AI（RPG / 世界 / 存档）
- 日期：2026-11-11
- 任务单：`teamwork/Rank-3/调度任务单-latest.json`（开工只读，已读 ✓；另对齐 `teamwork/command_center/commander/archive/cmd-20261111-095602-827.json` 与 Rank-1 / Rank-2 本轮任务单，均只读）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--version` = `4.7.2.stable.official.ed1daf0bf`（`G0_EXIT=0`）
- 工程根（`--path`）：`F:/Game/aierdengfahuan/godot`

> **真跑结论（总览，均为实际 stdout）**：
> ① **`WAVE-TRIAL-GDD.md` 追加 §10「赐福引导 · 三步教学」章节**（Game Designer 六项齐全：purpose / player experience goal + 数值引用表 / inputs / outputs / edge cases T-E1~T-E12 / failure states T-F1~T-F7）；定位「前 30 秒无引导」断点（v0.4.0 仅「自动开始 + 常驻 HUD」补法不够）、给出五层目标梯度衔接、三段连续奖励节奏与四条留存钩子；§0~§9 原样保留、不改写、不冒充 v0.6.0 已实现。**全部数值引用 Rank-2 `[PLACEHOLDER]` 表、不另造数值**（本轮 `tutorial_config.gd` / `tutorial_steps.tres` 并发产出、Rank-3 产出时尚未落地，采用字段名引用式占位并如实登记待校对；既有 `WAVE-TRIAL-TUNING.md` / `GRACE-UPGRADE-TUNING.md` 已落地、只引用键名不填数值）。
> ② **新建 `TUTORIAL-BLOCKOUT.md`**（Level Designer 标准）：教学区 B-Z1 / 战斗区 B-Z2 空间分离三条机制（状态 / 威胁 / 时序）、视觉引导（教学 HUD 安全区避开五套占位 / 敌人预告「可见但不激活」/ 退避带沿用 S5 连续）、三步「示范→操作→反馈」节奏、失败回退与不惩罚原则；**只写规格、不改脚本 / 场景 / 任何 `godot/` 文件**。
> ③ **两个三段式 flag 两处登记**：`00-协作契约.md` §3.3 登记表（key / 类型 / 读写方 / 单调性 4 列）+ `teamwork/Rank-3/存档与flag规范.md` §3.3 全局登记表同步追加；契约 §3.3 追加 R28 说明段写明三段式合法性、T 重开与 `step_index` 单调口径、与 §4.4 十字段 / `schema_version=3` 关系、`commit("tutorial_step_completed")` / `commit("tutorial_completed")` 强制落盘点、「先落盘再改运行时实例」顺序、教学奖励绝不写 `removals` / 绝不回退 `points`、旧存档缺 key 回落基线、读写边界。
> ④ 新建 `teamwork/Rank-3/verify_tutorial_flags_v060.gd`（`extends SceneTree`）：真跑 **21 PASS / 0 FAIL `RESULT=ALL_PASS`**（selftest 15 + write 3 + read 3），覆盖三段式正则（含六类反例）/ `completed` 单向与 `step_index` 单调递增 / 重启读回一致 / commit 顺序与十字段；selftest/write/read 三进程 pid **25820 / 26968 / 3180 全不同**，write→read 两独立引擎进程实证「重启读回 3/3 一致」；`--script` 模式**不用 `/root/...` 绝对路径**，用 `Engine.get_main_loop()` / `get_root().get_node_or_null()` 相对探活。
> ⑤ `README.md`（工程根）新增 **v0.6.0 条目 + R28 回归真跑行**；「二、还差什么」新增 **第 15 项**并追加 **v0.6.0 复核段**（第 10/11/12 项仍未达、第 13/14 项已落地表可推进校对、第 15 项为 v0.6.0 特有缺口）。
> ⑥ **R21/R22 的 31 PASS / 0 FAIL**（`r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11）R28 重跑**不回退**（本轮 R17 **首次即 `11 PASS / 0 FAIL`，无 R27 的并发 9/2 抖动**）；**14 次引擎调用全 `EXIT=0`**、**14 份 `R28-*.log` 逐份 `grep SCRIPT ERROR / Parse Error / ERROR` 全 0**，三段门禁 `grep SCRIPT ERROR=0` 达成。
> ⑦ 本轮**未写任何 `godot/` 工程业务文件**（Rank-1/2/4 并发写入）；**未新建只读探针 / 巡检脚本**（`verify_tutorial_flags_v060.gd` 是任务单 ③ 明确要求的验证载体）；零付费、零外部依赖、不自行 git。

---

## ① 实际交付清单（本轮真正写入的文件与段落）

| # | 文件 | 动作 | 改动内容 |
|---|------|------|------|
| 1 | `teamwork/Rank-3/WAVE-TRIAL-GDD.md` | **修改（文末追加）** | 文末**追加 §10「赐福引导 · 三步教学」**（§10.1 purpose / §10.2 player experience goal + 数值引用表 / §10.3 inputs / §10.4 outputs / §10.5 edge cases T-E1~T-E12 / §10.6 failure states T-F1~T-F7 / §10.7 前 30 秒断点定位 + 五层目标梯度衔接 + 三段奖励节奏 + 四条留存钩子 / §10.8 三段式 flag + 落盘口径 + 口径差异登记 + 校对清单 T-V1~T-V9 / §10.9 关联）。**§0~§9 一字未改**；数值纪律：不写具体数值、只引用 Rank-2 `[PLACEHOLDER]` 键名并如实登记教学表未落地 |
| 2 | `teamwork/Rank-3/TUTORIAL-BLOCKOUT.md` | **新建** | Level Designer 引导 blockout 规格（§0 口径所有权 + 四条硬边界 / §1 B-Z1~B-Z3 空间分离与三条机制 / §2 HUD 安全区·敌人预告·退避带 + TB-A1~A6 / §3 三步「示范→操作→反馈」时序表 + 三条硬要求 / §4 四条不惩罚 + 回退层级 + rationale + TB-B1~B4 / §5 与 GDD·契约·验证对齐 / §6 校对清单 TB-V1~TB-V8 / §7 关联）。**纯规格，无脚本、无坐标数值、无工程文件写入** |
| 3 | `teamwork/00-协作契约.md` §3.3 | **追加 2 行 + R28 说明段** | 登记表追加 `grace.tutorial.completed` / `grace.tutorial.step_index` 两行（key / 类型 / 读写方 / 单调性）；新增 R28 说明段（6 条：三段式合法性 / 单调性与 T 重开口径 / 十字段与 `schema_version=3` / `commit(reason)` 落盘点 / 先落盘再改运行时实例 / 读写边界）。**§3.1/§3.2 缺号、I-1~I-6 接口表、§9 及其余历史条款一律未动** |
| 4 | `teamwork/Rank-3/存档与flag规范.md` §3.3 | **追加 2 行 + 1 句** | 全局 flag 登记表追加 2 行（key / 类型 / 基线 / 写入时机 / 说明）+ R28 口径指向句；**§3.1 正则 / §3.2 命名空间 / §4.1 十字段 / §4.4 回放规则 / 其它登记行一律未动** |
| 5 | `teamwork/Rank-3/verify_tutorial_flags_v060.gd` | **新建** | `extends SceneTree` 口径自测载体（详见 §1.4 / §2.3） |
| 6 | `F:/Game/aierdengfahuan/README.md` | **修改（4 处）** | ① 顶部追加 R28 维护记录；②「一、已做了什么」表追加 **v0.6.0 条目行 + R28 回归真跑行**；③「二、还差什么」表追加 **第 15 项**；④ 表后追加 **v0.6.0 复核段**。§3.1~§3.4 既有 `stat` 实测表与历史结论未改；顶部「中枢 done 轮次」表仍为 R22 快照、按历史结论保留不冒充 |
| 7 | `teamwork/Rank-3/R28-*.log`（14 份） | **新建 · 运行输出留档** | `G0-version` / `G1-import` / `G2a-tfv060` / `G2b-writer` / `G2c-hud` / `G2d-r19` / `G2e-r17` / `G2f-e2e` / `G3-quit` / `RUN-r19` / `RUN-r17` / `TFV-selftest` / `TFV-write` / `TFV-read`，均为实际 stdout，非工程源文件、非脚本 |
| 8 | `teamwork/Rank-3/DONE-R28.md` | **新建** | 本报告 |
| 9 | `teamwork/command_center/ai/3/outbox/cmd-20261111-095602-827-A3.json` | **新建** | 回执 JSON，写在 `teamwork/command_center/` 下的**精确 id 路径**（**未**写到工程根 `command_center/`） |

### 1.1 GDD §10「赐福引导 · 三步教学」章节要点

- **Game Designer 六项齐全**：purpose（补「前 30 秒无引导」断点 / 与三波梯度衔接不抢跑 / 把引导接进奖励节奏与留存钩子）／player experience goal（「被牵着走的第一分钟」+ §10.2 数值引用表：`step_id / prompt / expected_action / reward_points / timeout_sec` 教学字段 + `WAVE-TRIAL-TUNING.md` / `GRACE-UPGRADE-TUNING.md` 键名，全字段名引用式占位）／inputs（玩家输入 `J / Space / E / T` / Rank-1 状态机 `NOT_STARTED→STEP_LIGHT_ATTACK→STEP_ROLL→STEP_GRACE_SHOP→COMPLETED` / `tutorial_step_completed(step_id, reward)` 信号 / `tutorial_steps.tres` / 三段式 flag 基线 / 第 1 波 `TELEGRAPH` 衔接）／outputs（教学 HUD 金色提示 / 即时反馈 / `step_index`+`completed`+`points` 存档输出 / `COMPLETED` 自动进第 1 波 / 奖励节奏）／edge cases T-E1~T-E12（错按 / 重复触发 / 超时 / 空表 / 已完成跳过 / T 重开 / 中途退出 / 重启读回 / 类型非法 / 同帧竞争 / 存档未加载完 / 旧存档缺 key）／failure states T-F1~T-F7（玩家失败不惩罚 / 点数通胀 / 冗长过短 / 系统降级 / 衔接失败 / 引导未达 / 视觉未达）。
- **断点定位（§10.7）**：`迭代-v0.4.0-试炼与精修.md` §1 第 4 断点「前 30 秒无引导 / 玩家不知道要做什么」，v0.4.0 的「自动开始 + 常驻 HUD」只回答「打第几波 / 还剩多久」，未教按键；v0.6.0 三步「示范→操作→反馈」把开局从「被计时地摸索」变成「不被计时地学会」。
- **与三波目标梯度衔接**：新增「引导」为最前置一层（引导 / 短期 30 秒 / 中期三波 / 长期最高波次 / 成长，共五层）；教学期间三波 `IDLE`、不计时、不生成伤害判定；`COMPLETED` 后自动进第 1 波 `TELEGRAPH`，复用 §4 与 `WAVE-TRIAL-SPATIAL.md` 的读秒 / 可见预告 / 退避规格；老玩家由 `completed=true` 跳过、按 T 重开复习。§2 / §9 循环与 §5 难度曲线均不回退。
- **奖励节奏与留存钩子（§10.7）**：三段连续（教学每步 `reward_points` → 三波 `reward_points` 递增 → `cost` 出口）共用同一个 `grace.trial.points`、全程只增不减、不写 `removals`；四条钩子 = **`completed` 单向「我学会了」**（不可撤销 + 赐福点亮态 + 跳过门控）/ **开局即正反馈**（第一笔入账）/ **可重开但不惩罚**（T 重开 + 低门槛）/ **既有历史最佳·赐福点数·永久增益·重复挑战更轻松**（R26 / R27 原样保留）。
- **数值纪律**：不写任何具体数值；「三步 / 前 30 秒 / 三波 / 进度 1-3」为任务单给定的结构描述（同 §0.1 脚注口径）；本轮教学表未落地如实登记「字段名引用式占位、待 T-V6 校对，不一致改 GDD 引用段不改数据表」。

### 1.2 TUTORIAL-BLOCKOUT.md blockout 要点

- **只写规格**：§0 四条硬边界（只写规格 / 不改脚本场景 / 不写坐标数值全 `[PLACEHOLDER]` / 不代验不谎报），产出物仅文字与表格。
- **教学区与战斗区空间分离（§1）**：B-Z1 教学引导带（无敌人 / 无伤害判定 / 无倒计时）/ B-Z2 战斗区（复用 SPATIAL S1~S7，`COMPLETED` 后才激活）/ B-Z3 教学 HUD 安全区；三条机制 = **状态分离**（教学期三波 `IDLE`）/ **威胁分离**（敌人预告位「可见但不激活」）/ **时序分离**（状态切换而非场景切换，不加载 / 不黑屏 / 不弹全屏面板）；沿用 SPATIAL §1 空间分层原则「预告位在视野内、退避位在威胁范围外、HUD 在屏幕边缘、生成点与退避带分离、四者互不重叠」。
- **视觉引导（§2）**：教学金色提示一行（步骤文案 / 进度 1-3 / 本步奖励点数）**避开 Rank-1 任务单五套占位**（赐福 `x<730,y<220` / 画质 `x>760,y<180` / 底部战斗 `y≈660` / 波次 `y≈232` / 兑换 `y≈610`，坐标只作「避开」引用、非本规格新造数值）；敌人预告教学期可见不激活、`COMPLETED` 后沿用 `telegraph_sec [PLACEHOLDER]` 且**任何阶段不取消起手预告**；退避带沿用 S5 连续、不因教学收窄；点亮态读三段式 flag、复用 `hud.gd` `apply_lit_state` 入口。TB-A1~A6 规格判定项。
- **三步节奏（§3）**：每步「示范（文案 + 按键提示 + 高亮）→ 操作（只接受 `expected_action`，错按不推进不惩罚）→ 反馈（确认 + 点数入账 + 进度 +1 + 下一步示范）」时序表；三步全完成提示收束 + 点亮态 + 自动进第 1 波；三条硬要求（一次只教一个输入 / 反馈即时可见 / 不切场景不加载打断）。
- **失败回退与不惩罚（§4）**：四条不惩罚（错按 / 超时 / 退出 / T 重开均不死亡不扣血不扣点不回退）；**回退粒度 = 当前步**（不回 `NOT_STARTED`、不清空已入账点数）；**运行时回退 vs 持久化单调解耦**（状态机可复位，持久化 `step_index` / `completed` 不回写更小值，与 §4.4「quest_stages 取较大值」同机制）；系统降级安全停 `NOT_STARTED`、不自动进波；三条 rationale（学习窗口不是考核窗口 / 空间上给得起 / 单调保证复习不抹掉成就）。TB-B1~B4 规格判定项。

### 1.3 契约 §3.3 两个新 flag 登记（key / 类型 / 读写方 / 单调性）

| key | 类型 | 读写方 | 单调性 |
|---|---|---|---|
| `grace.tutorial.completed` | bool（基线 `false`） | 写：Rank-3（订阅三步全完成信号置 `true`，与末次 `step_index` 同一 `commit("tutorial_completed")` 原子先落盘）／读：赐福点亮态（读三段式 flag，不硬编码）、老玩家跳过教学门控、回放断言（纯读 `get_flag`） | **只增不减（false → true 单向）**：失败 / 超时 / 主动退出 / 重启 / T 重开教学 / 重复挑战均无 `false` 回写路径，一次性永久成就 |
| `grace.tutorial.step_index` | int（基线 `0`） | 写：Rank-3（订阅 Rank-1 `tutorial_step_completed(step_id, reward)`，按 `max(旧值, 本步序号)` 推进，强制 `commit(reason)` 先落盘）／读：教学 HUD「进度 1-3」、重启恢复、回放断言（纯读 `get_flag`） | **单调递增、只增不减**：`0→1→2→3`，重启不丢、赐福休息不清零；T 重开教学属 Rank-1 运行时状态机复位，持久化 flag **不回写更小值**（与 §4.4「quest_stages 取较大值」同机制） |

- **三段式合法性**：两 key 的 `grace` 前缀 / `tutorial` 对象段 / `completed` / `step_index` 状态段均匹配 §2 正则 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`；`world_state.gd` 的 `FLAG_KEY_REGEX` 无需修改、无需迁移、不改 `schema_version`；`verify_tutorial_flags_v060.gd` A2 以六类非法 key 机器判定。
- **T 重开与 `step_index` 单调口径（如实登记、不伪造）**：Rank-1 任务单「按 T 重开教学」属运行时状态机复位（教学 HUD 进度重走三步），本轮把持久化 `step_index` 登记为单调递增、重开不回写更小值，与 §4.4「quest_stages 取较大值、阶段只前进不回退」「集合并集只增不减」同机制；**若总指挥 / Rank-1 需要「重开时进度归零」的持久化语义，列为待裁决的口径差异**（同 §3.1 脚注 A8 / R27 `<id>` 收敛先例），本轮按三段式单调不变量落地、不擅自改正则、不改 `world_state.gd`。
- **与 §4.4 十字段 / `schema_version=3` 的关系**：十字段冻结、不得新增顶层字段；2 个新 flag 只作为 `flags` 字典内的新 key 落进既有结构（INV-6），不新增顶层字段 / 不改类型 / 不引入嵌套 → **`schema_version` 保持 `3`、不触发 §4.7 迁移链**；回放按 §4.4「LWW by timestamp / 写入顺序」合并、类型冲突以 §3.3 登记表声明类型为准；旧存档缺这两个 key 时 `get_flag(key, default)` 回落基线 `false` / `0`，不升级、不重置；**教学奖励只累加既有 `grace.trial.points`、绝不写 `removals`、绝不回退 `points`**。
- **`commit(reason)` 强制落盘点**：每步 `tutorial_step_completed`（`step_index` 按 `max` 推进 + `points` 累加本步 `reward_points`）、三步全完成 `tutorial_completed`（`completed=true` 与末次 `step_index` 同一原子写）、重启恢复 `load`（只读 `_load()`）；波次清波 / 全清 / 失败结算沿用 R26 `wave_trial_cleared` / `wave_trial_completed` / `wave_trial_settled`（不动 `grace.tutorial.*`）；reason 仅进 `meta.last_commit_reason`、不是新顶层字段、不触发迁移。
- **「先落盘再改运行时实例」顺序**：① 由 Rank-1 信号取结算结果 → ② 计算新值（`step_index=max(旧, 本步序号)` / `points=旧+本步 reward_points` / `completed` 仅全完成置 `true`）→ ③ ★ `commit(reason)` 按十字段原子写（`.tmp → flush → rename → delta.json`）→ ④ ★ 落盘成功后才更新 `WorldState` 运行时 flag 实例、`emit flag_changed`（教学 HUD 进度 / 点亮态增量刷新）→ ⑤ ③ 失败则不执行 ④、运行时保持旧值、不推进步数、不发奖、如实告警，绝不「内存已改、磁盘未改」。磁盘为唯一权威。
- **读写边界 / 不越界**：写方 Rank-3（I-1 `set_flag` 权威定义方）；**Rank-1 `tutorial_director.gd` 只发信号、不写 flag**，Rank-2 `tutorial_config.gd` / `tutorial_steps.tres` 只提供 `[PLACEHOLDER]` 数据表、不读写存档（I-1）；读方为教学 HUD / 点亮态 / 跳过门控 / 回放断言。**Rank-3 本轮只登记口径、不写任何 `godot/` 工程业务文件、不代验运行时接线**。

### 1.4 verify_tutorial_flags_v060.gd 验证覆盖（4 类 → 15 条 selftest 断言）

| 类 | 断言 | 依据 |
|---|---|---|
| A 三段式正则 | A1 两个新 flag（`completed` / `step_index`）全通过正则；A2 六类非法 key（两段式 / 大写 / 连字符 / 非法前缀 / 中文 / 四段 `grace.tutorial.step.index`）全被拒绝 | 契约 §2、`存档与flag规范.md` §3.1 |
| B 单向 / 单调 | B1 三步依次完成 `step_index` 严格递增 `0→1→2→3`；B2 `completed` false→true、`points` 每步只增不减；B3 重复触发 / T 重开（更小步序号）/ 重复 completed 被拒、`step_index` 不回退、`points` 不二次累加、无新 commit；B4 失败 / 超时 / 退出 / 重启后三者均不回退；B5 绝不写 `removals`、绝不回退 `points` | GDD §10.8、契约 §3.3 R28 说明段 |
| C 重启读回一致 | C1 真实 `FileAccess` 落盘到**独立** `user://tutorial_flags_v060_state.json`（不碰 `slot_01/delta.json`）；C2 新建独立 `_State` 实例 `_load()` 重建内存；C3 逐项读回 `completed / step_index / points` 3/3 一致 | GDD §10.8 / T-V3、R25 / R26 / R27 先例 |
| D commit 顺序 + 十字段 / schema | D1 连续 3 次 commit 事件序列恒为 `disk_write → runtime_update`（先落盘再改运行时实例）；D2 落盘态与运行时实例态逐项一致；D3 十字段齐全且无额外顶层字段；D4 `schema_version=3` 不触发迁移；D5 落盘 flags 全通过三段式正则 | 契约 §3.3 R28 说明段、`存档与flag规范.md` §4.1 / §4.4 |

**`--script` 模式纪律（任务单明确要求）**：全程**不用 `/root/...` 绝对路径**；`_initialize()` 用 `Engine.get_main_loop()` + `get_root().get_node_or_null("WorldState")` 相对探活，取不到如实降级、**不依赖其结果判 PASS**（实测 `WorldState_probe=true`，但仅登记不用于判定）。退出用 `quit(0 if ok else 1)`，输出 `[TFV060] SUMMARY ... pass=N fail=0 ok=true` + `[TFV060] RESULT=ALL_PASS`。

**如实边界（不粉饰）**：本载体是**口径级模拟验证**（内置 `_flags` / `_disk` / `_runtime` / `_State` / `_advance_step` / `_mark_completed` 模拟 I-1 `WorldState` + `SaveDeltaWriter.commit` + Rank-1 教学信号时序），**不是对 Rank-1 导演层 / Rank-2 教学数据表 / 教学 HUD 与点亮态的运行时代验**；`SIM_STEP_MAX=3` / `SIM_REWARD=1` / `EXPECT` 的 `step_index=3 / points=3` 是自测构造的口径级模拟值，**不引用也不替代** Rank-2 `tutorial_steps.tres` / `WAVE-TRIAL-TUNING.md` / `GRACE-UPGRADE-TUNING.md` 的 `[PLACEHOLDER]` 数值（Rank-2 任务单建议 20/30/50、15s 仅为建议值，本脚本不采用）；本轮 Rank-3 不写 `godot/` 工程文件。「重启读回一致」在同进程内由「真实文件落盘 → 全新实例 `_load()`」验证，并**另用 write/read 两个独立引擎进程**（pid 26968 / 3180）实证跨进程一致性。JSON `parse_string` 的 int→float round-trip（读回 `3.0`）由 `_val_eq`（`is_equal_approx`）容忍，**如实登记、不隐瞒**。

### 1.5 README.md 更新（4 处）

1. 顶部追加 **R28 维护记录**（v0.6.0 交付摘要 + §3 资产表 / 中枢 done 表按历史结论保留）。
2.「一、已做了什么」表追加 **v0.6.0 赐福引导 · 三步教学条目行 + R28 回归真跑行**（含 31 PASS 不回退、21 PASS 自测、14 份日志 grep 全 0）。
3.「二、还差什么」表追加 **第 15 项**（教学表落地校对 / `[PLACEHOLDER]` 数值校准 / 教学 HUD·点亮态·衔接接线 / `step_index` 单调 vs T 重开口径裁决）。
4. 表后追加 **v0.6.0 复核段**（第 10 人工试玩 / 11 `128bit` / 12 HD-2D 全绿未达仍未达；第 13 / 14 项已落地表可推进校对、数值仍待试玩；第 15 项为 v0.6.0 特有缺口）。

---

## ② 真跑输出结论（实际 stdout，未删改、未补写）

### 2.1 命令清单（引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--path F:/Game/aierdengfahuan/godot`）

| 段 | 命令标志 | 日志 |
|----|----|----|
| G0 | `--version` | `R28-G0-version.log` |
| G1 门禁 | `--headless --import` | `R28-G1-import.log` |
| G2a | `--headless --check-only --script <abs>/verify_tutorial_flags_v060.gd`（**新脚本语法门禁**） | `R28-G2a-tfv060.log` |
| G2b | `--headless --check-only --script res://scripts/save_delta_writer.gd` | `R28-G2b-writer.log` |
| G2c | `--headless --check-only --script res://scripts/hud.gd` | `R28-G2c-hud.log` |
| G2d | `--headless --check-only --script <abs>/r19_verify_hud.gd` | `R28-G2d-r19.log` |
| G2e | `--headless --check-only --script res://scripts/verify_hud_binding.gd` | `R28-G2e-r17.log` |
| G2f | `--headless --check-only --script <abs>/r22_save_e2e.gd` | `R28-G2f-e2e.log` |
| G3 门禁 | `--headless --quit` | `R28-G3-quit.log` |
| 回归 A | `--headless --script <abs>/r19_verify_hud.gd` | `R28-RUN-r19.log` |
| 回归 B | `--headless --script res://scripts/verify_hud_binding.gd` | `R28-RUN-r17.log` |
| TFV selftest | `--headless --script <abs>/verify_tutorial_flags_v060.gd` | `R28-TFV-selftest.log` |
| TFV write | `TUTORIAL_V060_PHASE=write ... --script <abs>/verify_tutorial_flags_v060.gd` | `R28-TFV-write.log` |
| TFV read | `TUTORIAL_V060_PHASE=read ... --script <abs>/verify_tutorial_flags_v060.gd` | `R28-TFV-read.log` |

> `<abs>` = `F:/Game/aierdengfahuan/teamwork/Rank-3/`。**一次只跑一个引擎进程、串行执行**；回归在前、TFV 在后（TFV 用独立 `user://` 文件，不污染 `slot_01/delta.json`）。

### 2.2 退出码（14 次引擎调用全 `EXIT=0`）

```
G0_EXIT=0  G1_EXIT=0  G2a_EXIT=0  G2b_EXIT=0  G2c_EXIT=0  G2d_EXIT=0  G2e_EXIT=0  G2f_EXIT=0  G3_EXIT=0
R19_EXIT=0  R17_EXIT=0  SELFTEST_EXIT=0  WRITE_EXIT=0  READ_EXIT=0
```

### 2.3 PASS / FAIL 数字（实际 SUMMARY 行）

```
[R19]    SUMMARY pass=20 fail=0 ok=true
[R17]    SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true   （首次即通过，无并发抖动）
[TFV060] SUMMARY phase=selftest pid=25820 pass=15 fail=0 ok=true   → RESULT=ALL_PASS
[TFV060] SUMMARY phase=write    pid=26968 pass=3  fail=0 ok=true   → RESULT=ALL_PASS
[TFV060] SUMMARY phase=read     pid=3180  pass=3  fail=0 ok=true   → RESULT=ALL_PASS
```

| 项 | 数值 | 说明 |
|---|:--:|---|
| R21/R22 HUD / 存档回归 | **20 PASS / 0 FAIL** | `r19_verify_hud.gd`，R28 重跑不回退 |
| R17 HUD 绑定回归（首次） | **11 PASS / 0 FAIL** | `verify_hud_binding.gd`，`degraded=false`、`flag_chain_verified=true`；**首次即通过，未出现 R27 的并发 9/2 抖动** |
| **任务单 ④ 的 31 PASS 回归** | **31 PASS / 0 FAIL** | 20 + 11，**不回退** |
| flag 自测 selftest（主自测） | **15 PASS / 0 FAIL** | A1/A2 + B1/B2/B3/B4/B5 + C1/C2/C3 + D1/D2/D3/D4/D5，`RESULT=ALL_PASS` |
| flag 自测 write / read | **3 + 3 PASS / 0 FAIL** | 两独立引擎进程 pid 26968 / 3180 不同 = 真重启，`RESULT=ALL_PASS` |
| **flag 自测合计** | **21 PASS / 0 FAIL** | 15 + 3 + 3；三进程 pid 25820 / 26968 / 3180 全不同 |

> write→read 阶段：`R1` 新进程 `_load()` 从磁盘重建内存、`R2` 跨进程读回 **3/3 一致**（`completed=true` / `step_index=3` / `points=3`）、`R3` 重启恢复三者不回退；C3 selftest 同进程「全新实例读回」同样 3/3 一致。

### 2.4 三段门禁 `grep SCRIPT ERROR=0`

| 段 | 标志 | `SCRIPT ERROR` | `Parse Error` | `ERROR` | `EXIT` |
|----|----|:--:|:--:|:--:|:--:|
| G1 | `--headless --import` | 0 | 0 | 0 | 0 |
| G2a | `--check-only --script` **verify_tutorial_flags_v060.gd** | 0 | 0 | 0 | 0 |
| G2b~G2f | `--check-only --script` ×5（writer / hud / r19 / r17 / e2e） | 0 | 0 | 0 | 0 |
| G3 | `--headless --quit` | 0 | 0 | 0 | 0 |

> **14 份 `R28-*.log` 逐份 `grep`：`SCRIPT ERROR=0`、`Parse Error=0`、`ERROR=0` 全为 0**（含 G0 / 2 份回归运行日志 / 3 份自测运行日志）；全量汇总 **三类 ERROR 命中合计 = 0**；三段门禁 `grep SCRIPT ERROR=0` 达成。
> 退出残留仍是工程既有 **WARNING、非 ERROR、未隐藏、未宣称零 WARNING**：`[SaveSystem] --script 工具模式（未带 v050_read 标记）：跳过自动读回（降级，不崩，保护回归基线）`、`[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`，见 `R28-TFV-*.log` / `R28-G3-quit.log` / `R28-RUN-r17.log`。

### 2.5 如实说明（不粉饰）

- **Rank-2 教学表未落地（开工定向核对 1 次，非巡检）**：`find godot teamwork/Rank-2 -iname "*tutorial*"` 返回空，确认本轮 `tutorial_config.gd` / `tutorial_steps.tres` / `verify_tutorial_reward_v060.gd` 属 Rank-2 并发产出、Rank-3 产出时**尚未落地**；故 GDD §10 / BLOCKOUT 的教学字段采用**字段名引用式占位**、不填数字、不猜数字，待落地后按 T-V6 / TB-V5 校对（不一致改 GDD 引用段、不改 Rank-2 数据表）。既有 `WAVE-TRIAL-TUNING.md`（07:48）与 `GRACE-UPGRADE-TUNING.md`（08:59）**已落地**，仅引用键名、不填数值。README 第 15 项如实登记。
- **TFV 载体**只写**独立** `user://tutorial_flags_v060_state.json`，**不碰** `user://saves/slot_01/delta.json`、不注入测试种子到工程存档、不伪造产物。回归脚本 `r19_verify_hud.gd` / `verify_hud_binding.gd` 的既有 autoload commit 行为按历轮一贯口径保留，未改动任何工程文件。
- **R17 首次即 11 PASS / 0 FAIL**：本轮未复现 R27 的共享存档初态并发 9/2 抖动（Rank-2 本轮任务单 ④ 承担「回归脚本存档初态隔离」）；按「不主动巡检 / 不破坏共享状态」纪律，Rank-3 **未清理 / 未重置存档、未改回归脚本、未伪造 PASS**，仅如实记录首次通过结果。
- **verify 载体为口径级模拟（非运行时代验）**、`JSON.parse_string` int→float round-trip 由 `_val_eq` 容忍、既有 WARNING 非 ERROR 未隐藏 —— 均如实登记。

---

## ③ 未完成项与阻塞

**阻塞：无功能性阻塞。** 派单 5 项（① GDD 教学章节 / ② BLOCKOUT / ③ flag 登记 + verify 脚本并真跑 / ④ README + 31 PASS 回归 + 三段门禁 / ⑤ 只写自有文件）均真实达成。

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 1 | **Rank-2 `tutorial_config.gd` / `tutorial_steps.tres` / 教学 `[PLACEHOLDER]` 表落地后校对** | **未达 · 待 Rank-2 并发产出** | 产出时未落地（定向核对 1 次确认），采用字段名引用式占位、不填数字；待落地后按 GDD §10.8 T-V6 / BLOCKOUT TB-V5 校对 `step_id / prompt / expected_action / reward_points / timeout_sec` 实际取值、教学与波次 `reward_points` 同名不同语义域、rationale / broken 定义一致性，不一致**改 GDD 引用段、不改 Rank-2 数据表**；README 第 15 项已登记 |
| 2 | **`step_index` 单调 vs T 重开「进度归零」的持久化口径裁决** | **待总指挥裁决** | Rank-1「按 T 重开教学」属运行时状态机复位，Rank-3 把持久化 `step_index` 登记为单调递增（与 §4.4「quest_stages 取较大值」同机制）；若需「重开时进度归零」的持久化语义需改语义定义，本轮**不擅自改正则 / 不改 `world_state.gd`**；契约 §3.3 / GDD §10.8 / README 第 15 项均登记 |
| 3 | **教学 `reward_points` / `timeout_sec` / `cost` `[PLACEHOLDER]` 人工试玩校准** | **属用户侧 · 本轮不代做** | 奖励 / 超时 / 兑换成本具体值须由人工试玩校准；headless 真跑不做手感判断，Rank-3 不冒充完成 |
| 4 | **v0.6.0 四项实现**（Rank-1 `tutorial_director.gd` / 教学 HUD 金色引导行 / 赐福点亮态 / `verify_tutorial_v060.gd`；Rank-2 `tutorial_config.gd` / `tutorial_steps.tres` / `verify_tutorial_reward_v060.gd` / 双写收敛；Rank-4 素材 / `courtyard.tscn` 视觉 / 录屏） | **未由 Rank-3 实现、未代验、不宣称完成** | 归 Rank-1 / Rank-2 / Rank-4 本轮并发写入 `godot/` 与 `capture/`；目录所有权硬约束禁止 Rank-3 触碰 |
| 5 | **教学 HUD / 点亮态 / 跳过门控 / 第 1 波衔接 / T 重开 / 演示序列兼容的运行时接线** | **属 Rank-1 并发实现 · 未代验** | GDD §10.6 T-F5 / T-F6「不代验、不宣称已接通」；Rank-3 只登记口径与 blockout 规格 |
| 6 | **引导 blockout / 视觉引导 / 环境氛围视觉落地** | **属 Rank-4 / Rank-1 · 未达** | BLOCKOUT.md 只写规格标注，不写 `courtyard.tscn` / 光效 / 脚本、不代验画面 |
| 7 | **人工试玩（exe / apk）与手感 / 审美验收**（裁决 A17） | **属用户侧 · 本轮只给勾选清单、不冒充完成** | README 第 10 项；headless 无真实帧缓冲 |
| 8 | **`128bit` 词义歧义** | **待用户确认 · A15 不消歧** | 契约 §9.3 / `00-汇总.md` §6.2 / README 第 11 项显式保留，未编码进任何期望值 |
| 9 | **HD-2D 全绿未达** | **未达成 · 长期项** | R24 目视回看实证：Boss 无可见像素形象、战斗数值停摆、地面平铺与马赛克、光效 2D 近似；README 第 12 项如实登记 |
| 10 | **第 13 / 14 项历史缺口**（v0.4.0 波次数值校准、v0.5.0 `<id>` 收敛裁决 / 永久增益运行时效果接通 / 成长数值校准） | **部分可推进、仍未达** | 两份 TUNING.md 已落地、可推进引用键名校对；`<id>` 收敛裁决 / 运行时效果接通 / 数值校准仍待总指挥 / Rank-2 / 用户侧，README 第 15 项前的 v0.6.0 复核段如实登记 |
| 11 | 15–20 秒实机录屏并目视回看 / exe / pck / apk 重导 | 长期项 · 不在本单 | 本轮未写任何 `godot/` 工程文件；录屏与产物重导由工程变更方 / 后续轮次承担 |
| 12 | 既有退出 WARNING / `JSON.parse_string` int→float round-trip | 如实保留 · 非缺陷 | `SaveSystem` --script 降级 / `ChunkManager` / `ObjectDB instances leaked` 历轮已登记、未隐藏；读回 `3.0` 由 `_val_eq` 容忍、与 R25 / R26 / R27 / r22 口径一致 |
| 13 | 中枢 done 轮次表 / outbox 消费 | 未据以改写 | README 顶部表仍为 R22 快照，按历史结论保留、不冒充已进 done 序列；回执按精确路径写入，是否被实时消费以中枢实际行为为准 |

---

## ④ 约束对照

- **目录所有权** ✓：只写 `00-协作契约.md`（仅 §3.3 登记表 + R28 说明段）/ `存档与flag规范.md`（仅 §3.3 表 + 1 句）/ `README.md`（工程根）/ `teamwork/Rank-3/`（GDD §10、TUTORIAL-BLOCKOUT、verify、DONE、14 份日志）+ 回执例外 `teamwork/command_center/ai/3/outbox/`；**绝对未碰** `godot/project.godot`、`godot/scenes/*`、`godot/scripts/*`、`godot/data/*`、既有存档件 / 战斗件 / 美术资源、其它 Rank 文档、`00-汇总.md`、teamwork 根 `README.md`（导航，主 AI 只读）、`build/` 产物、用户共享存档 `slot_01/delta.json`（本轮未读未写）。
- **公共契约** ✓：直接改、直接真跑；**未新建只读探针 / 巡检脚本**（`verify_tutorial_flags_v060.gd` 是任务单 ③ 明确要求的验证载体，其余复用既有 `r19_verify_hud.gd` / `verify_hud_binding.gd` / `r22_save_e2e.gd`）；未主动扫目录做进度巡检（仅对任务单指定的引擎 / 脚本 / 回执路径与 Rank-2 教学表做定向存在性核对 1 次）；零付费、零外部依赖；一次只跑一个引擎进程、无 GPU job；产出先目视检查再接入。
- **不伪造 / 不谎报** ✓：Rank-2 教学表未落地不冒充引用具体值、`<id>` / T 重开口径差异如实收敛并列待裁决（不伪造 PASS）、Rank-1/2/4 实现不冒充完成、引导视觉 / 点亮态待接不宣称已生效、HD-2D 全绿未达不粉饰、人工试玩不代做、既有 WARNING 不隐藏、JSON int→float round-trip 如实登记、verify 载体为口径级模拟（非运行时代验）如实说明、R17 首次即通过如实记录未伪造抖动。
- **不自行 git** ✓：由总指挥收尾。
- **三段门禁 `grep SCRIPT ERROR=0`** ✓；中文 UTF-8 ✓。

---

## ⑤ 回执

按本轮 `task_id` 写 `F:/Game/aierdengfahuan/teamwork/command_center/ai/3/outbox/cmd-20261111-095602-827-A3.json`（在 `teamwork/command_center/` 下，**未**写到工程根 `command_center/`），结构：

```json
{"task_id":"cmd-20261111-095602-827-A3","ai":3,"status":"done","result":"引用 DONE-R28.md 实际结论：① WAVE-TRIAL-GDD.md 追加 §10 赐福引导·三步教学章节，Game Designer 六项齐全（purpose/player experience goal+数值引用表/inputs/outputs/edge cases T-E1~T-E12/failure states T-F1~T-F7），定位前 30 秒无引导断点、五层目标梯度衔接、三段连续奖励节奏与四条留存钩子，数值全引用 Rank-2 [PLACEHOLDER] 表不另造数值（本轮教学表并发未落地、字段名引用式占位如实登记）。② 新建 TUTORIAL-BLOCKOUT.md：教学区/战斗区空间分离三机制、视觉引导 HUD 避开五套占位/敌人预告可见不激活/退避带沿用 S5、三步示范→操作→反馈节奏、失败回退与不惩罚原则，只写规格不改脚本。③ 两个三段式 flag 登记进 00-协作契约.md §3.3 与 存档与flag规范.md §3.3（key/类型/读写方/单调性）：grace.tutorial.completed bool 单向 / grace.tutorial.step_index int 单调递增；写明与 §4.4 十字段、schema_version=3、commit(tutorial_step_completed)/commit(tutorial_completed) 与先落盘再改运行时实例、旧存档回落基线、绝不写 removals/绝不回退 points、T 重开与 step_index 单调口径待裁决。④ verify_tutorial_flags_v060.gd 真跑 21 PASS/0 FAIL RESULT=ALL_PASS（selftest 15 pid=25820 + write 3 pid=26968 + read 3 pid=3180，三进程 pid 全不同，write→read 实证重启读回 3/3 一致），--script 模式不用 /root/ 绝对路径、用 Engine.get_main_loop()/get_root().get_node_or_null() 相对探活。⑤ README.md 新增 v0.6.0 条目与 R28 回归真跑行、还差什么第 15 项与 v0.6.0 复核段。⑥ 31 PASS/0 FAIL（r19 20 + r17 11）不回退、R17 首次即 11 PASS 无并发抖动；14 次引擎调用全 EXIT=0、14 份 R28-*.log 逐份 grep SCRIPT ERROR/Parse Error/ERROR 全 0，三段门禁 grep SCRIPT ERROR=0 达成。未写任何 godot/ 工程业务文件、未新建探针/巡检脚本、零付费、不自行 git。未完成项：tutorial_config.gd/tutorial_steps.tres 待落地校对键名、step_index 单调 vs T 重开进度归零待总指挥裁决、教学 reward_points/timeout_sec/cost 待人工试玩校准、教学 HUD/点亮态/第 1 波衔接/T 重开运行时接线归 Rank-1 未代验、人工试玩/128bit/HD-2D 全绿未达、15-20 秒录屏、既有 WARNING 非 ERROR 如实保留。"}
```

> **写后实测（本轮，非巡检 / 交付自验 1 次）**：回执写入成功后 `outbox/` 被中枢**实时消费清空**（目录当前 0 文件，直接读精确路径 `exists=False`，与 `DONE-R21.md`~`DONE-R27.md` §⑤ 同一消费时序现象），**如实登记、未隐藏**。归档件 `teamwork/command_center/dispatcher/receipts/cmd-20261111-095602-827-A3.json`（**2441 字节**）读回校验：`json_valid=True`、`keys=['ai','result','status','task_id']`、`task_id=cmd-20261111-095602-827-A3` / `ai=3` / `status=done`、`result_len=1420`、`result` 以「引用 DONE-R28.md 实际结论」开头并含 `21 PASS` / `31 PASS` / `ALL_PASS` / `grace.tutorial.completed` / `grace.tutorial.step_index` / `schema_version=3` / `R28-*.log` / `不自行 git` 关键结论；工程根 `command_center/` **不存在**（未误写）。按幂等 / 并发保护**不重复写第二份回执**。
>
> 结论：回执**路径正确**（`teamwork/command_center/ai/3/outbox/` 下的精确 id 文件，且已被中枢按该 id 归档）、**内容符合**任务单 `{"task_id":...,"ai":3,"status":"done","result":"引用 DONE-R28.md 实际结论"}` 结构。按实际产物判定，不臆测、不谎报。

---

## ⑥ 关联

`teamwork/Rank-3/WAVE-TRIAL-GDD.md` §10（本轮教学章节）、`teamwork/Rank-3/TUTORIAL-BLOCKOUT.md`（本轮引导 blockout）、`teamwork/Rank-3/verify_tutorial_flags_v060.gd`（本轮自测载体）、`teamwork/00-协作契约.md` §3.3、`teamwork/Rank-3/存档与flag规范.md` §3.1 / §3.3 / §4.1 / §4.4 / §4.7、`teamwork/迭代-v0.4.0-试炼与精修.md` §1（「前 30 秒无引导」断点原始诊断）、`teamwork/Rank-2/调度任务单-latest.json`（本轮教学表字段约定，只读）、`teamwork/Rank-2/WAVE-TRIAL-TUNING.md` / `GRACE-UPGRADE-TUNING.md`（已落地 `[PLACEHOLDER]` 数值真源）、`teamwork/Rank-3/WAVE-TRIAL-SPATIAL.md`（R27 空间规格）、`verify_grace_flags_v050.gd` / `DONE-R27.md`（R27 先例）、`F:/Game/aierdengfahuan/README.md`（状态表）、`teamwork/Rank-3/R28-*.log`（14 份真跑 stdout）。
