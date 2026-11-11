# DONE-R27.md · Rank-3 交付报告（R27 · v0.5.0 赐福成长 GDD / 空间 blockout / 三段式 flag / 验证与文档）

- 任务：`cmd-20261111-083350-244-A3`，`[ROUND=R27]`，**v0.5.0 新内容**，Rank-3 执行 AI（RPG / 世界 / 存档）
- 日期：2026-11-11
- 任务单：`teamwork/Rank-3/调度任务单-latest.json`（开工只读，已读 ✓；第 6 行截断的「目录所有权」段已用 `cat` 补读完整版核对）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--version` = `4.7.2.stable.official.ed1daf0bf`（`G0_EXIT=0`）
- 工程根（`--path`）：`F:/Game/aierdengfahuan/godot`

> **真跑结论（总览，均为实际 stdout）**：
> ① **WAVE-TRIAL-GDD.md 追加 §9「赐福成长」章节**（Game Designer 六项齐全 + 核心循环由 R26 四环节补全为 v0.5.0 五环节「行动→反馈→目标→**消费成长**→再行动」+ 点数出口闭合断点 + 目标梯度四层 + 三条留存钩子 + 三段式 flag / 落盘口径与校对清单）；§0~§8 原样保留、不改写、不冒充 v0.5.0 已实现。全部新数值引用 Rank-2 本轮 `GRACE-UPGRADE-TUNING.md` `[PLACEHOLDER]` 表、不另造数值（Rank-2 并发产出、Rank-3 产出时**尚未落地**，采用字段名引用式占位并如实登记待校对）。
> ② **新建 WAVE-TRIAL-SPATIAL.md**（Level Designer 三波空间节奏 blockout）：每波入场读秒与敌人可见预告、站位与连续退避带、**难度空间优先于数值缩放**、逐波教学 / 加压 / 收束节奏 + 环境叙事标注 T1/T2/T3、S1~S7 空间要素与 SP-A1~A5 规格判定项；**只写规格、不改脚本 / 场景 / 任何 `godot/` 文件**。
> ③ **两个三段式 flag 两处登记**：`00-协作契约.md` §3.3 登记表（key / 类型 / 读写方 / 单调性 4 列）+ `teamwork/Rank-3/存档与flag规范.md` §3.3 全局登记表同步追加；契约 §3.3 追加 R27 说明段写明 **`<id>` 三段式收敛口径**、与 §4.4 十字段 / `schema_version=3` 的关系、`commit("grace_upgrade_purchased")` 强制落盘点、「先落盘再改运行时实例」顺序、消费绝不写 `removals` / 绝不回退 `points`、余额 `points − spent_points ≥ 0`、旧存档缺 key 回落基线、读写边界。
> ④ 新建 `teamwork/Rank-3/verify_grace_flags_v050.gd`（`extends SceneTree`）：真跑 **25 PASS / 0 FAIL `RESULT=ALL_PASS`**（selftest 19 + write 3 + read 3），覆盖三段式正则（含四段反例）/ `spent_points` 单调递增 / `unlocked` 单向 / 余额非负 / 重启读回一致 / commit 顺序与十字段；selftest/write/read 三进程 pid **16004 / 26652 / 25188 全不同**，write→read 两独立引擎进程实证「重启读回一致」；`--script` 模式**不用 `/root/...` 绝对路径**，用 `Engine.get_main_loop()` / `get_root().get_node_or_null()` 相对探活。
> ⑤ `README.md`（工程根）新增 **v0.5.0 条目 + R27 回归真跑行**；「二、还差什么」新增 **第 14 项**并追加 **v0.5.0 复核段**（第 10/11/12 项仍未达、第 13 项 `WAVE-TRIAL-TUNING.md` 已落地可推进校对）。
> ⑥ **R21/R22 的 31 PASS / 0 FAIL**（`r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11）R27 重跑**不回退**（**如实登记并发抖动**：首次 R17 因共享存档初态幂等出现 `9 PASS/2 FAIL`，定向重跑 1 次恢复 `11 PASS/0 FAIL`）；**15 份 `R27-*.log` 逐份 `grep SCRIPT ERROR / Parse Error / ERROR` 全 0**，三段门禁 `grep SCRIPT ERROR=0` 达成。
> ⑦ 本轮**未写任何 `godot/` 工程业务文件**（Rank-1/2/4 并发写入）；**未新建只读探针 / 巡检脚本**（`verify_grace_flags_v050.gd` 是任务单 ④ 明确要求的验证载体）；零付费、零外部依赖、不自行 git。

---

## ① 实际交付清单（本轮真正写入的文件与段落）

| # | 文件 | 动作 | 改动内容 |
|---|------|------|------|
| 1 | `teamwork/Rank-3/WAVE-TRIAL-GDD.md` | **修改（2 处）** | ① 头部追加 **R27 / v0.5.0 维护记录**（说明 §9 追加、§0~§8 原样保留）；② 文末**追加 §9「赐福成长」**（§9.1~§9.10：purpose / player experience goal + 数值引用表 / inputs / outputs / edge cases G-E1~G-E11 / failure states G-F1~G-F7 / 核心循环补全与点数出口闭合断点 / 目标梯度与留存钩子 / 三段式 flag 与落盘口径 + 校对清单 G-V1~G-V10 / 关联）。**§0~§8 一字未改** |
| 2 | `teamwork/Rank-3/WAVE-TRIAL-SPATIAL.md` | **新建** | Level Designer 三波空间节奏 blockout 规格（§0 口径所有权 / §1 S1~S7 空间要素 / §2 入场读秒与可见预告 / §3 站位与退避 + SP-A1~A5 / §4 三波教学-加压-收束 blockout 表 / §5 难度空间优先于数值缩放 / §6 T1/T2/T3 环境叙事标注 / §7 与 GDD·契约·验证对齐 / §8 校对清单 SP-V1~SP-V8 / §9 关联）。**纯规格，无脚本、无坐标数值、无工程文件写入** |
| 3 | `teamwork/00-协作契约.md` §3.3 | **追加 2 行 + R27 说明段** | 登记表追加 `grace.trial.spent_points` / `grace.upgrade_<id>.unlocked` 两行（key / 类型 / 读写方 / 单调性）；新增 R27 说明段（6 条：三段式合法性 / `<id>` 收敛口径 / 十字段与 `schema_version=3` / `commit(reason)` 落盘点 / 先落盘再改运行时实例 / 读写边界）。**§3.1/§3.2 缺号、I-1~I-6 接口表、§9 及其余历史条款一律未动** |
| 4 | `teamwork/Rank-3/存档与flag规范.md` §3.3 | **追加 2 行 + 1 句** | 全局 flag 登记表追加 2 行（key / 类型 / 基线 / 写入时机 / 说明）+ R27 口径指向句；**§3.1 正则 / §3.2 命名空间 / §4.1 十字段 / §4.4 回放规则 / 其它登记行一律未动** |
| 5 | `teamwork/Rank-3/verify_grace_flags_v050.gd` | **新建** | `extends SceneTree` 口径自测载体（详见 §1.4 / §2.3） |
| 6 | `F:/Game/aierdengfahuan/README.md` | **修改（4 处）** | ① 顶部追加 R27 维护记录；②「一、已做了什么」表追加 **v0.5.0 条目行 + R27 回归真跑行**；③「二、还差什么」表追加 **第 14 项**；④ 表后追加 **v0.5.0 复核段**。§3.1~§3.4 既有 `stat` 实测表与历史结论未改；顶部「中枢 done 轮次」表仍为 R22 快照、按历史结论保留不冒充 |
| 7 | `teamwork/Rank-3/R27-*.log`（15 份） | **新建 · 运行输出留档** | `G0-version` / `G1-import` / `G2a-gfv050` / `G2b-writer` / `G2c-hud` / `G2d-r19` / `G2e-r17` / `G2f-e2e` / `G3-quit` / `RUN-r19` / `RUN-r17`（首次抖动）/ `RUN-r17-recheck`（重跑恢复）/ `GFV-selftest` / `GFV-write` / `GFV-read`，均为实际 stdout，非工程源文件、非脚本 |
| 8 | `teamwork/Rank-3/DONE-R27.md` | **新建** | 本报告 |
| 9 | `teamwork/command_center/ai/3/outbox/cmd-20261111-083350-244-A3.json` | **新建** | 回执 JSON，写在 `teamwork/command_center/` 下的**精确 id 路径**（**未**写到工程根 `command_center/`） |

### 1.1 GDD §9「赐福成长」章节要点

- **Game Designer 六项齐全**：purpose（给只进不出的 `grace.trial.points` 一个出口、闭合长期动机断点、保住单调不变量、制造可累积成长）／player experience goal（「积累看得见、兑现摸得着、成长带得走」+ §9.2 数值引用表：`id / cost / effect_key / effect_value / reward_points` 全部字段名引用式占位）／inputs（玩家输入 / `wave_cleared` 事件 / Rank-2 `can_purchase` 纯逻辑判定 / `grace_upgrades.tres` / 三段式 flag 基线）／outputs（界面三态 + HUD 余额 / 即时反馈 / `spent_points`+`unlocked` 存档输出 / 永久增益作用于运行时）／edge cases G-E1~G-E11（余额不足 / 重复购买 / 空表 / 依赖缺失 / 中途退出 / 重启读回 / `<id>` 非法 / 类型不符 / 同帧竞争 / 存档未加载完 / 旧存档缺 key）／failure states G-F1~G-F7（玩家失败不回退 / 成长过强 / 过弱·通胀 / 负余额 / 系统降级 / 效果未接通 / 视觉未达）。
- **核心循环补全（§9.7）**：R26 四环节「行动→反馈→目标→再行动」→ v0.5.0 五环节「行动→反馈→目标→**消费成长**→再行动」，给出五环节循环图与逐环节说明。
- **点数出口如何闭合断点（§9.7 核心）**：① 断点定位 —— `grace.trial.points` 单调递增、永不清除，只有清波入账入口、没有消费出口，「目标」后点数只是 HUD 上变大的数字，「再行动」能力等价，长期动机断裂；② 出口设计 —— 消费**不回退 `points`、不写 `removals`**（§4.4 回放「集合并集只增不减」不允许把累计量改小），新增 `spent_points` 作为「已消费」单调镜像，兑换成功 `spent_points = 旧 + cost`、`unlocked = true`，**余额 = `points − spent_points` ≥ 0** 硬约束由 `can_purchase` 落盘前门控；③ 闭环成立 ——「攒点数→花点数换永久增益→带增益重复挑战」把白攒数字变成带得走的能力；④ 与空间 / 数值解耦 —— 改的是玩家能力、不改三波空间 / `hp_multiplier`，R26 §5 难度曲线与 §6 存档语义不回退。
- **目标梯度与留存钩子（§9.8）**：四层梯度（短期 30 秒清波 / 中期一局三波全清 / 长期最高波次·累计点数 / **成长：攒够点数→兑换永久增益→带增益挑战**）；三条留存钩子 = **永久增益**（`unlocked` 单向、跨局跨重启不丢、不可撤销不可重复购买）/ **历史最佳**（`best_wave` 单调递增、变强后有能力刷新）/ **重复挑战更轻松**（玩家变强、敌人数值不变，相对难度下降）；三者关系「永久增益是因、更轻松是体感、历史最佳是果」。

### 1.2 WAVE-TRIAL-SPATIAL.md blockout 要点

- **只写规格**：§0 四条硬边界（只写规格 / 不改脚本场景 / 不写坐标数值全 `[PLACEHOLDER]` / 不代验不谎报），产出物仅文字与表格。
- **S1~S7 空间要素**：战斗区 / 玩家初始位 / 敌人生成点 / 预告位 / 退避带 / HUD 安全区（含 v0.5.0 新增「余额」标签）/ 波间结算窗口位；「预告位在视野内、退避位在威胁范围外、HUD 在屏幕边缘、生成点与退避带分离、四者互不重叠」为底线。
- **每波入场读秒与可见预告（§2）**：`IDLE → TELEGRAPH`（时长引用 `telegraph_sec [PLACEHOLDER]`）、读秒不生成伤害判定、敌人提前可见且与 `enemy_id / move_weight` 对齐、高频招式先有可见前摇；**三波共同底线：任何一波不得取消起手预告**（难度靠空间不靠藏信息）。
- **站位与退避空间（§3）**：初始位固定可读、交战在「近身位 ↔ 退避带」间决策、回场路径连续；退避带逐波收窄但**每波连续、无死角、无即死死角、不靠隐藏墙提示**；与永久增益解耦（增益改玩家能力、不改空间规格）；SP-A1~A5 规格判定项供人工试玩核对、不写验证脚本。
- **三波节奏 blockout 表（§4）**：第 1 波**教学 / 读场**（单方向来敌、空间最宽、预告最完整、T1 明亮开阔、无收紧）→ 第 2 波**加压 / 换向**（来敌方向或组合变化、退避带中等收窄、保留起手预告、T2 光色变化提示重新读场）→ 第 3 波**收束 / 结算**（空间最紧、退避带最窄但连续、起手预告仍可见、T3 聚光收束、清波即 `TRIAL_COMPLETED`）；三波共用同一战斗区、不切场景。
- **难度空间优先于数值缩放（§5 核心论点）**：逐波抬压优先靠空间（来敌方向 / 生成点数量 / 退避带宽度 / 预告可读性 / 视野收束），数值（`hp_multiplier / move_weight / time_limit_sec`）只作微调兜底；5 条 rationale（可读可判可退避 / 公平性不依赖背板 / 调空间不动存档不触发迁移 / 与 v0.5.0 成长解耦 / `[PLACEHOLDER]` 可试玩校准）；与 GDD §5「曲线形态」互补、不冲突。
- **逐波环境叙事标注（§6）**：T1 / T2 / T3 / 波间四条规格标注 + 三条底线（氛围不降低预告可读性、收束波不用暗场代替起手预告、规格标注不粉饰 HD-2D 全绿未达）；视觉落地归 Rank-4、本轮不代做。

### 1.3 契约 §3.3 两个新 flag 登记（key / 类型 / 读写方 / 单调性）

| key | 类型 | 读写方 | 单调性 |
|---|---|---|---|
| `grace.trial.spent_points` | int（基线 `0`） | 写：Rank-3（I-1 `set_flag` 权威；兑换编排在 Rank-2 `grace_upgrade_service.purchase()` 判定通过后 `spent_points = 旧 + cost`，与 `unlocked` 同一 `commit("grace_upgrade_purchased")` 原子先落盘）／读：赐福成长界面「余额」、Rank-2 购买判定入参、回放断言（纯读 `get_flag`） | **单调递增、永不清除**：只按 `cost` 累加、不回退、重启不丢；**绝不回退 `grace.trial.points`、绝不写 `removals`**；重复购买由门控防二次累加；余额 `points − spent_points ≥ 0` 硬约束 |
| `grace.upgrade_<id>.unlocked` | bool（基线 `false`） | 写：Rank-3（兑换成功置 `true`，与 `spent_points` 同一 `commit(reason)` 原子先落盘）／读：赐福成长界面「已解锁 / 可兑换 / 点数不足」、Rank-2 运行时效果门控、回放断言 | **只增不减（false → true 单向）**：失败 / 超时 / 重启 / 重复挑战 / 重复购买均无 `false` 回写路径，一次性永久成就 |

- **`<id>` 三段式收敛口径（如实登记、不伪造）**：任务单给的模式键 `grace.upgrade.<id>.unlocked` 为**四段**，但 §3.1 三段式正则 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$` **只允许 2 个点、对象段 `[a-z0-9_]+` 不含点号**，四段形式**无法通过**（会破坏 INV-5 / 契约 §2）。故**实际落盘 key 收敛为三段** `grace.upgrade_<id>.unlocked`（把 `<id>` 并入对象段、前缀 `upgrade_`），`FLAG_KEY_REGEX` 无需修改、无需迁移、不改 `schema_version`。`verify_grace_flags_v050.gd` 以「收敛后三段式通过 + 四段式作为 A2 反例被拒」机器判定；**保留四段字面还是采用三段收敛列为待总指挥裁决的口径差异（同 §3.1 脚注 A8 / 契约 §2 两段式示例回改先例），本轮按三段式不变量落地、不擅自改正则、不改 `world_state.gd`**。
- **与 §4.4 十字段 / `schema_version=3` 的关系**：十字段冻结、不得新增顶层字段；2 个新 flag 只作为 `flags` 字典内的新 key 落进既有结构（INV-6），不新增顶层字段 / 不改类型 / 不引入嵌套 → **`schema_version` 保持 `3`、不触发 §4.7 迁移链**；回放按 §4.4「LWW by timestamp / 写入顺序」合并、类型冲突以 §3.3 登记表声明类型为准；**旧存档缺这两个 key 时 `get_flag(key, default)` 回落基线 `0` / `false`，不升级、不重置**；**消费绝不写 `removals`**（抹除 `points` 会破坏 R26 单调不变量与回放「集合并集只增不减」语义）。
- **`commit(reason)` 强制落盘点**：兑换成功（每项）`grace_upgrade_purchased`（`spent_points += cost` 与对应 `unlocked = true` 同一原子写）、波次清波 / 全清 / 失败结算沿用 R26 `wave_trial_cleared` / `wave_trial_completed` / `wave_trial_settled`（不动 `spent_points` / `unlocked`）、重启恢复 `load`（只读 `_load()`）；reason 仅进 `meta.last_commit_reason`、不是新顶层字段、不触发迁移。
- **「先落盘再改运行时实例」顺序**：① 由 Rank-2 `purchase()` 判定结果取 `cost` / `id` → ② 计算新值（`spent_points = 旧 + cost` / `unlocked = true`，以 `points − spent_points ≥ 0` 前置门控）→ ③ ★ `commit(reason)` 按十字段原子写（`.tmp → flush → rename → delta.json`）→ ④ ★ 落盘成功后才更新 `WorldState` 运行时 flag 实例、`emit flag_changed`、并把永久增益作用到运行时 → ⑤ ③ 失败则不执行 ④、运行时保持旧值、**不解锁、不扣点、如实告警**，绝不「内存已改、磁盘未改」。磁盘为唯一权威。
- **读写边界 / 不越界**：写方 Rank-3（I-1 `set_flag` 权威定义方）；Rank-2 `grace_upgrade_service.gd` 为 RefCounted 纯逻辑、只收参数只判定、不直接读写存档文件（I-1），由兑换编排层在其判定通过后触发落 flag；任何 Rank 经 I-1 `set_flag` 写入都须满足登记的类型 / 单调性 / 余额非负 / 落盘顺序不变量；读方为成长界面 / HUD / 效果门控 / 回放断言。**Rank-3 本轮只登记口径、不写任何 `godot/` 工程业务文件、不代验运行时接线**。

### 1.4 verify_grace_flags_v050.gd 验证覆盖（6 类 → 19 条 selftest 断言）

| 类 | 断言 | 依据 |
|---|---|---|
| A 三段式正则 | A1 余额输入 + 新 flag（`points / spent_points / 3×unlocked`）全通过正则；A2 六类非法 key（两段式 / 大写 / 连字符 / 非法前缀 / 中文 / **四段 `grace.upgrade.hp_max.unlocked`**）全被拒绝 | 契约 §2、`存档与flag规范.md` §3.1、`<id>` 收敛口径 |
| B `spent_points` 单调递增 | B1 两次兑换 0→2→4 严格递增；B2 余额不足 / 重复购买被拒、不二次累加；B3 赐福休息 / 重启不清零、`points` 不回退 | GDD §9.9、契约 §3.3 |
| C `unlocked` 单向 | C1 兑换成功 false→true、余额不足项保持 false；C2 失败 / 重启 / 重复挑战无 false 回写；C3 已解锁项重复购买被拒、不翻转、不产生新 commit | GDD §9.9、契约 §3.3 |
| D 余额非负 | D1 每次成功兑换后 `points − spent_points ≥ 0`；D2 余额不足拒绝后余额 / `points` / `spent` 均不变；D3 消费绝不写 `removals`、绝不回退 `points`（余额模型而非扣减模型） | 契约 §3.3、Rank-2 任务单「绝不 removals / 绝不回退 points」 |
| E 重启读回一致 | E1 真实 `FileAccess` 落盘到**独立** `user://grace_flags_v050_state.json`（不碰 `slot_01/delta.json`）；E2 新建独立 `_State` 实例 `_load()` 重建内存；E3 逐项读回 `points / spent_points / 3×unlocked` 5/5 一致 | GDD §9.9 / G-V5、R25 / R26 先例 |
| F commit 顺序 + 十字段 / schema | F1 连续 3 次 commit 事件序列恒为 `disk_write → runtime_update`（先落盘再改运行时实例）；F2 落盘态与运行时实例态逐项一致；F3 十字段齐全且无额外顶层字段；F4 `schema_version=3` 不触发迁移；F5 落盘 flags 全通过三段式正则 | 契约 §3.3 R27 说明段、`存档与flag规范.md` §4.1 / §4.4 |

**`--script` 模式纪律（任务单明确要求）**：全程**不用 `/root/...` 绝对路径**；`_initialize()` 用 `Engine.get_main_loop()` + `get_root().get_node_or_null("WorldState")` 相对探活，取不到如实降级、**不依赖其结果判 PASS**（实测 `WorldState_probe=true`，但仅登记不用于判定）。退出用 `quit(0 if ok else 1)`，输出 `[GFV050] SUMMARY ... pass=N fail=0 ok=true` + `[GFV050] RESULT=ALL_PASS`。

**如实边界（不粉饰）**：本载体是**口径级模拟验证**（内置 `_flags` / `_disk` / `_runtime` / `_State` / `_attempt_purchase` 模拟 I-1 `WorldState` + `SaveDeltaWriter.commit` + Rank-2 `purchase()` 门控时序），**不是对 Rank-1 导演层 / Rank-2 数据表 / 运行时效果的运行时代验**；`SIM_POINTS=5` / `SIM_COST=2` / `EXPECT` 的 `points=5 / spent_points=4` 是自测构造的口径级模拟值，**不引用也不替代** Rank-2 `GRACE-UPGRADE-TUNING.md` 的 `[PLACEHOLDER]` 数值（其任务单建议 cost 100/200/300 仅为建议值，本脚本不采用）；示例 upgrade id `hp_max / roll_iframe / attack_power` 取自 Rank-2 任务单示例 `effect_key`，**待其 `grace_upgrade_config.gd` 落地后校对 `<id>` 实际取值**，脚本只验证三段式收敛模板与不变量、不依赖具体 id；本轮 Rank-3 不写 `godot/` 工程文件。「重启读回一致」在同进程内由「真实文件落盘 → 全新实例 `_load()`」验证，并**另用 write/read 两个独立引擎进程**（pid 26652 / 25188）实证跨进程一致性。JSON `parse_string` 的 int→float round-trip（读回 `5.0` / `4.0`）由 `_val_eq`（`is_equal_approx`）容忍，**如实登记、不隐瞒**。

### 1.5 README.md 更新（4 处）

1. 顶部追加 **R27 维护记录**（v0.5.0 交付摘要 + §3 资产表 / 中枢 done 表按历史结论保留）。
2.「一、已做了什么」表追加 **v0.5.0 赐福成长条目行 + R27 回归真跑行**（含 31 PASS 并发抖动如实登记、25 PASS 自测、15 份日志 grep 全 0）。
3.「二、还差什么」表追加 **第 14 项**（`GRACE-UPGRADE-TUNING.md` / `grace_upgrade_config.gd` 待落地校对 `<id>` / `[PLACEHOLDER]` 数值待人工试玩校准 / `<id>` 三段式收敛口径待裁决 / 永久增益运行时效果待接通）。
4. 表后追加 **v0.5.0 复核段**（第 10 人工试玩 / 11 `128bit` / 12 HD-2D 全绿未达仍未达；第 13 项 `WAVE-TRIAL-TUNING.md` 已落地可推进校对、数值仍待试玩）。

---

## ② 真跑输出结论（实际 stdout，未删改、未补写）

### 2.1 命令清单（引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--path F:/Game/aierdengfahuan/godot`）

| 段 | 命令标志 | 日志 |
|----|----|----|
| G0 | `--version` | `R27-G0-version.log` |
| G1 门禁 | `--headless --import` | `R27-G1-import.log` |
| G2a | `--headless --check-only --script <abs>/verify_grace_flags_v050.gd`（**新脚本语法门禁**） | `R27-G2a-gfv050.log` |
| G2b | `--headless --check-only --script res://scripts/save_delta_writer.gd` | `R27-G2b-writer.log` |
| G2c | `--headless --check-only --script res://scripts/hud.gd` | `R27-G2c-hud.log` |
| G2d | `--headless --check-only --script <abs>/r19_verify_hud.gd` | `R27-G2d-r19.log` |
| G2e | `--headless --check-only --script res://scripts/verify_hud_binding.gd` | `R27-G2e-r17.log` |
| G2f | `--headless --check-only --script <abs>/r22_save_e2e.gd` | `R27-G2f-e2e.log` |
| G3 门禁 | `--headless --quit` | `R27-G3-quit.log` |
| 回归 A | `--headless --script <abs>/r19_verify_hud.gd` | `R27-RUN-r19.log` |
| 回归 B（首次） | `--headless --script res://scripts/verify_hud_binding.gd` | `R27-RUN-r17.log` |
| 回归 B（定向重跑） | `--headless --script res://scripts/verify_hud_binding.gd` | `R27-RUN-r17-recheck.log` |
| GFV selftest | `--headless --script <abs>/verify_grace_flags_v050.gd` | `R27-GFV-selftest.log` |
| GFV write | `GRACE_V050_PHASE=write ... --script <abs>/verify_grace_flags_v050.gd` | `R27-GFV-write.log` |
| GFV read | `GRACE_V050_PHASE=read ... --script <abs>/verify_grace_flags_v050.gd` | `R27-GFV-read.log` |

> `<abs>` = `F:/Game/aierdengfahuan/teamwork/Rank-3/`。**一次只跑一个引擎进程、串行执行**；回归在前、GFV 在后（GFV 用独立 `user://` 文件，不污染 `slot_01/delta.json`）。

### 2.2 退出码（15 次引擎调用：14 次 `EXIT=0` + 首次 R17 `EXIT=1` 并发抖动，重跑恢复 0）

```
G0_EXIT=0  G1_EXIT=0  G2a_EXIT=0  G2b_EXIT=0  G2c_EXIT=0  G2d_EXIT=0  G2e_EXIT=0  G2f_EXIT=0  G3_EXIT=0
R19_EXIT=0  R17_EXIT=1（首次·并发抖动）  SELFTEST_EXIT=0  WRITE_EXIT=0  READ_EXIT=0
R17_RECHECK_EXIT=0（定向重跑恢复）
```

### 2.3 PASS / FAIL 数字（实际 SUMMARY 行）

```
[R19]    SUMMARY pass=20 fail=0 ok=true
[R17]    SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=9  fail=2 ok=false   （首次·抖动）
[R17]    SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true   （定向重跑恢复）
[GFV050] SUMMARY phase=selftest pid=16004 pass=19 fail=0 ok=true   → RESULT=ALL_PASS
[GFV050] SUMMARY phase=write    pid=26652 pass=3  fail=0 ok=true   → RESULT=ALL_PASS
[GFV050] SUMMARY phase=read     pid=25188 pass=3  fail=0 ok=true   → RESULT=ALL_PASS
```

| 项 | 数值 | 说明 |
|---|:--:|---|
| R21/R22 HUD / 存档回归 | **20 PASS / 0 FAIL** | `r19_verify_hud.gd`，R27 重跑不回退 |
| R17 HUD 绑定回归（最终） | **11 PASS / 0 FAIL** | `verify_hud_binding.gd`，`degraded=false`、`flag_chain_verified=true`；以定向重跑实证为准 |
| **任务单 ⑤ 的 31 PASS 回归** | **31 PASS / 0 FAIL** | 20 + 11，**不回退** |
| flag 自测 selftest（主自测） | **19 PASS / 0 FAIL** | A1/A2 + B1/B2/B3 + C1/C2/C3 + D1/D2/D3 + E1/E2/E3 + F1/F2/F3/F4/F5，`RESULT=ALL_PASS` |
| flag 自测 write / read | **3 + 3 PASS / 0 FAIL** | 两独立引擎进程 pid 26652 / 25188 不同 = 真重启，`RESULT=ALL_PASS` |
| **flag 自测合计** | **25 PASS / 0 FAIL** | 19 + 3 + 3；三进程 pid 16004 / 26652 / 25188 全不同 |

> write→read 阶段：`R1` 新进程 `_load()` 从磁盘重建内存、`R2` 跨进程读回 **5/5 一致**（`points=5` / `spent_points=4` / `up1=true` / `up2=true` / `up3=false`）、`R3` 重启恢复 `spent_points` / `unlocked` 不回退、余额非负；E3 selftest 同进程「全新实例读回」同样 5/5 一致。

### 2.4 三段门禁 `grep SCRIPT ERROR=0`

| 段 | 标志 | `SCRIPT ERROR` | `Parse Error` | `ERROR` | `EXIT` |
|----|----|:--:|:--:|:--:|:--:|
| G1 | `--headless --import` | 0 | 0 | 0 | 0 |
| G2a | `--check-only --script` **verify_grace_flags_v050.gd** | 0 | 0 | 0 | 0 |
| G2b~G2f | `--check-only --script` ×5（writer / hud / r19 / r17 / e2e） | 0 | 0 | 0 | 0 |
| G3 | `--headless --quit` | 0 | 0 | 0 | 0 |

> **15 份 `R27-*.log` 逐份 `grep`：`SCRIPT ERROR=0`、`Parse Error=0`、`ERROR=0` 全为 0**（含 G0 / 5 份回归与自测运行日志 / 重跑日志）；全量汇总 **三类 ERROR 命中合计 = 0**；三段门禁 `grep SCRIPT ERROR=0` 达成。
> 退出残留仍是工程既有 **WARNING、非 ERROR、未隐藏、未宣称零 WARNING**：`[ChunkManager] 未找到 ChunkRoot`（`chunk_streaming.gd:51`）、`2 ObjectDB instances were leaked at exit`（`object.cpp:2536`），见 `R27-G3-quit.log` / `R27-RUN-r17*.log` / `R27-GFV-*.log`。

### 2.5 存档写入与 R17 并发抖动的如实说明

- **GFV 载体**只写**独立** `user://grace_flags_v050_state.json`，**不碰** `user://saves/slot_01/delta.json`、不注入测试种子到工程存档、不伪造产物。回归脚本 `r19_verify_hud.gd` / `verify_hud_binding.gd` 的既有 autoload commit 行为按历轮一贯口径保留，未改动任何工程文件。
- **R17 首次 `9 PASS / 2 FAIL` 根因（定向诊断，非巡检）**：`verify_hud_binding.gd`（既有只读回归脚本，Rank-3 不修改）的 A1 期望 `grace.network.last_grace_id` 的 `set_flag` 让 `TitleLabel.text` 从其它值变「关卡前」、A2 期望 `grace.limgrave_gatefront.lit` 的 `set_flag` 让颜色 `DIM→GOLD`；首次运行时共享 `slot_01/delta.json` 初态已被并发方写成 **幂等值**（`before=[赐福 · 关卡前]` / 颜色已是 GOLD），`set_flag` 按 INV-4「同 key 同 value 不发 `flag_changed`」不触发增量刷新 → A1/A2 判 FAIL（`hud_refreshed=1(基线=1)` 未增）。**这是共享存档初态被 R27 并发写入方动态改写导致的状态依赖抖动，非 `godot/` 代码回退、非 Rank-3 交付件引入**（Rank-3 本轮只写文档 / 验证脚本 / 契约 / README，不碰 `hud.gd` / 回归脚本 / 存档）。
- **只读佐证（不修改）**：首次运行 `SaveSystem` 读回日志 `best_wave=3 / completed=true / points=550`；定向重跑前 A1 `before=[赐福 · 宁姆格福]`、A2 `before=(0.45,0.42,0.34,1.0)`（DIM）→ 重跑 `11 PASS / 0 FAIL / EXIT=0`；重跑后 `delta.json`（1121 B）实测 `best_wave=3 / completed=true / lit=true / last_grace_id="grace_siofra_well" / points=900` —— `points` 550→900、`last_grace_id` 变化，**实证共享存档在 R27 期间被并发方持续改写**。按「不主动巡检 / 不破坏共享状态」纪律，Rank-3 **未清理 / 未重置存档、未改回归脚本、未伪造 PASS**，仅定向重跑 1 次取得稳定实证并如实登记首次 FAIL。
- **最终 31 PASS 以定向重跑实证为准**（`r19` 20 + `r17` 11），与 R21/R22/R24/R25/R26 历轮口径一致、不回退；首次抖动作为并发环境现象**如实保留、不隐藏**。

---

## ③ 未完成项与阻塞

**阻塞：无功能性阻塞。** 派单 6 项（① GDD 成长章节 / ② SPATIAL blockout / ③ flag 登记 / ④ verify 脚本并真跑 / ⑤ README + 31 PASS 回归 + 三段门禁 / ⑥ 只写自有文件）均真实达成；31 PASS 回归的一次并发抖动已定向重跑恢复、如实登记。

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 1 | **Rank-2 `GRACE-UPGRADE-TUNING.md` / `grace_upgrade_config.gd` / `grace_upgrades.tres` / `grace_upgrade_service.gd` 落地后校对** | **未达 · 待 Rank-2 并发产出** | Rank-3 产出 GDD §9 / SPATIAL 时这些文件尚未落地（开工定向核对 1 次确认），采用字段名引用式占位、不填数字；待落地后按 §9.9 G-V7 / SPATIAL §8 SP-V6 校对 `id` 实际取值 / 引用键名 / rationale / broken 定义一致性，不一致**改 GDD 引用段、不改 Rank-2 数据表**；README 第 14 项已登记 |
| 2 | **`<id>` 四段字面 vs 三段收敛的口径裁决** | **待总指挥裁决** | 任务单 `grace.upgrade.<id>.unlocked` 与 §3.1 三段式正则冲突，Rank-3 收敛为 `grace.upgrade_<id>.unlocked` 并机器判定「四段被拒」；保留四段字面需改正则与 `world_state.gd`（Rank-1 所有），本轮**不擅自改、不伪造四段通过正则**；契约 §3.3 / GDD §9.9 / README 第 14 项均登记 |
| 3 | **`cost` / `effect_value` `[PLACEHOLDER]` 人工试玩校准** | **属用户侧 · 本轮不代做** | 成长幅度 / 兑换成本 / 点数产出具体值须由人工试玩校准；headless 真跑不做手感判断，Rank-3 不冒充完成 |
| 4 | **v0.5.0 四项实现**（Rank-1 `wave_trial_director.gd` / 波次 HUD / 赐福成长界面；Rank-2 `grace_upgrade_config.gd` / `grace_upgrade_service.gd` / `grace_upgrades.tres` / `verify_grace_upgrade_v050.gd`；Rank-4 素材 / `courtyard.tscn` 视觉 / 录屏） | **未由 Rank-3 实现、未代验、不宣称完成** | 归 Rank-1 / Rank-2 / Rank-4 本轮并发写入 `godot/` 与 `capture/`；目录所有权硬约束禁止 Rank-3 触碰 |
| 5 | **永久增益运行时效果接通**（HP 上限 / 翻滚无敌窗口 / 攻击力、`effect_key` 落点核对） | **属 Rank-2 并发实现 · 未代验** | GDD §9.6 G-F6「数据已落、效果待接」不宣称已生效；Rank-3 只登记口径 |
| 6 | **空间 blockout / 环境叙事 T1/T2/T3 视觉落地** | **属 Rank-4 / Rank-1 · 未达** | SPATIAL.md 只写规格标注，不写 `courtyard.tscn` / 光效 / 脚本、不代验画面 |
| 7 | **人工试玩（exe / apk）与手感 / 审美验收**（裁决 A17） | **属用户侧 · 本轮只给勾选清单、不冒充完成** | README 第 10 项；headless 无真实帧缓冲 |
| 8 | **`128bit` 词义歧义** | **待用户确认 · A15 不消歧** | 契约 §9.3 / `00-汇总.md` §6.2 / README 第 11 项显式保留，未编码进任何期望值 |
| 9 | **HD-2D 全绿未达** | **未达成 · 长期项** | R24 目视回看实证：Boss 无可见像素形象、战斗数值停摆、地面平铺与马赛克、光效 2D 近似；README 第 12 项如实登记 |
| 10 | 15–20 秒实机录屏并目视回看 / exe / pck / apk 重导 | 长期项 · 不在本单 | 本轮未写任何 `godot/` 工程文件；录屏与产物重导由工程变更方 / 后续轮次承担 |
| 11 | 既有退出 WARNING / `JSON.parse_string` int→float round-trip | 如实保留 · 非缺陷 | `ChunkManager` / `ObjectDB instances leaked` 历轮已登记、未隐藏；读回 `5.0` / `4.0` 由 `_val_eq` 容忍、与 R25 / R26 / r22 口径一致 |
| 12 | **R17 首次并发抖动 `9 PASS/2 FAIL`** | **已定向重跑恢复、如实登记** | 根因为共享存档初态被并发方写成幂等值、非代码回退；最终 31 PASS 以重跑实证为准；若后续轮次频繁复现，建议由 Rank-1 / 总指挥评估回归脚本的存档初态隔离，Rank-3 不越界改 `godot/` 文件 |
| 13 | 中枢 done 轮次表 / outbox 消费 | 未据以改写 | README 顶部表仍为 R22 快照，按历史结论保留、不冒充已进 done 序列；回执按精确路径写入，是否被实时消费以中枢实际行为为准 |

---

## ④ 约束对照

- **目录所有权** ✓：只写 `00-协作契约.md`（仅 §3.3）/ `存档与flag规范.md`（仅 §3.3 表 + 1 句）/ `README.md`（工程根）/ `teamwork/Rank-3/`（GDD §9、SPATIAL、verify、DONE、15 份日志）+ 回执例外 `teamwork/command_center/ai/3/outbox/`；**绝对未碰** `godot/project.godot`、`godot/scenes/*`、`godot/scripts/*`、`godot/data/*`、既有存档件 / 战斗件 / 美术资源、其它 Rank 文档、`00-汇总.md`、teamwork 根 `README.md`（导航，主 AI 只读）、`build/` 产物、**用户共享存档 `slot_01/delta.json`（仅只读查看 1 次作诊断，未修改）**。
- **公共契约** ✓：直接改、直接真跑；**未新建只读探针 / 巡检脚本**（`verify_grace_flags_v050.gd` 是任务单 ④ 明确要求的验证载体，其余复用既有 `r19_verify_hud.gd` / `verify_hud_binding.gd` / `r22_save_e2e.gd`）；未主动扫目录做进度巡检（仅对任务单指定的引擎 / 脚本 / 回执路径、Rank-2 upgrade 配置与共享存档做定向存在性 / 状态核对）；零付费、零外部依赖；一次只跑一个引擎进程、无 GPU job；产出先目视检查再接入。
- **不伪造 / 不谎报** ✓：Rank-2 并发表未落地不冒充引用具体值、`<id>` 四段无法通过三段式正则如实收敛并列待裁决（不伪造 PASS）、Rank-1/2/4 实现不冒充完成、永久增益效果待接不宣称生效、HD-2D 全绿未达不粉饰、人工试玩不代做、既有 WARNING 不隐藏、JSON int→float round-trip 如实登记、verify 载体为口径级模拟（非运行时代验）如实说明、**R17 首次 9/2 抖动不隐藏、定向重跑恢复后如实登记最终 31 PASS**。
- **不自行 git** ✓：由总指挥收尾。
- **三段门禁 `grep SCRIPT ERROR=0`** ✓；中文 UTF-8 ✓。

---

## ⑤ 回执

按本轮 `task_id` 写 `F:/Game/aierdengfahuan/teamwork/command_center/ai/3/outbox/cmd-20261111-083350-244-A3.json`（在 `teamwork/command_center/` 下，**未**写到工程根 `command_center/`），结构：

```json
{"task_id":"cmd-20261111-083350-244-A3","ai":3,"status":"done","result":"引用 DONE-R27.md 实际结论：① WAVE-TRIAL-GDD.md 追加 §9 赐福成长章节，Game Designer 六项齐全 + 核心循环补全为五环节「行动→反馈→目标→消费成长→再行动」+ 点数出口闭合断点（spent_points 单调镜像、points 不回退、不写 removals、余额 points-spent≥0）+ 目标梯度四层与三条留存钩子（永久增益/历史最佳/重复挑战更轻松），数值全引用 Rank-2 GRACE-UPGRADE-TUNING.md [PLACEHOLDER] 表不另造数值（并发表未落地、字段名引用式占位如实登记）。② 新建 WAVE-TRIAL-SPATIAL.md：三波空间节奏 blockout，入场读秒与可见预告、站位与连续退避带、难度空间优先于数值缩放、教学/加压/收束节奏与 T1/T2/T3 环境叙事标注，只写规格不改脚本。③ 两个三段式 flag 登记进 00-协作契约.md §3.3 与 存档与flag规范.md §3.3（key/类型/读写方/单调性）：grace.trial.spent_points int 单调递增 / grace.upgrade_<id>.unlocked bool 单向；<id> 四段字面与三段式正则冲突、收敛为三段并列待总指挥裁决，写明与 §4.4 十字段、schema_version=3、commit(grace_upgrade_purchased) 与先落盘再改运行时实例的关系。④ verify_grace_flags_v050.gd 真跑 25 PASS/0 FAIL RESULT=ALL_PASS（selftest 19 + write 3 + read 3，三进程 pid 16004/26652/25188 全不同，write→read 实证重启读回一致），--script 模式不用 /root/ 绝对路径、用 Engine.get_main_loop()/root.get_node_or_null() 相对探活。⑤ README.md 新增 v0.5.0 条目与 R27 回归真跑行、还差什么第 14 项与 v0.5.0 复核段。⑥ 31 PASS/0 FAIL（r19 20 + r17 11）不回退（如实登记首次 R17 因共享存档初态并发抖动 9 PASS/2 FAIL、定向重跑恢复 11 PASS/0 FAIL）；15 份 R27-*.log 逐份 grep SCRIPT ERROR/Parse Error/ERROR 全 0，三段门禁 grep SCRIPT ERROR=0 达成。未写任何 godot/ 工程文件、未新建探针/巡检脚本、零付费、不自行 git。未完成项：GRACE-UPGRADE-TUNING.md 与 grace_upgrade_config.gd 待落地校对 <id>、<id> 三段式收敛待总指挥裁决、cost/effect_value 待人工试玩校准、永久增益运行时效果与空间/环境叙事视觉落地归 Rank-2/Rank-4 未代验、人工试玩/128bit/HD-2D 全绿未达、15-20 秒录屏、既有 WARNING 非 ERROR 如实保留。"}
```

> **写后实测（本轮，非巡检 / 交付自验 1 次）**：回执写入成功后 `outbox/` 被中枢**实时消费清空**（目录当前 0 文件，直接读精确路径 `exists=False`，与 `DONE-R21.md §⑤` / `DONE-R22.md §⑤` / `DONE-R23.md §⑥` / `DONE-R24.md §⑤` / `DONE-R25.md §⑤` / `DONE-R26.md §⑤` 同一消费时序现象），**如实登记、未隐藏**。归档件 `teamwork/command_center/dispatcher/receipts/cmd-20261111-083350-244-A3.json`（**2450 字节**）读回校验：`json_valid=True`、`keys=['ai','result','status','task_id']`、`task_id=cmd-20261111-083350-244-A3` / `ai=3` / `status=done`、`result_len=1362`、`result` 以「引用 DONE-R27.md 实际结论」开头并含 `25 PASS` / `31 PASS` / `ALL_PASS` / `grace.trial.spent_points` / `schema_version=3` / `R27-*.log` / `不自行 git` 关键结论；工程根 `command_center/` **不存在**（未误写）。按幂等 / 并发保护**不重复写第二份回执**。
>
> 结论：回执**路径正确**（`teamwork/command_center/ai/3/outbox/` 下的精确 id 文件，且已被中枢按该 id 归档）、**内容符合**任务单 `{"task_id":...,"ai":3,"status":"done","result":"引用 DONE-R27.md 实际结论"}` 结构。按实际产物判定，不臆测、不谎报。

---

## ⑥ 关联

`teamwork/Rank-3/WAVE-TRIAL-GDD.md` §9（本轮成长章节）、`teamwork/Rank-3/WAVE-TRIAL-SPATIAL.md`（本轮空间规格）、`teamwork/Rank-3/verify_grace_flags_v050.gd`（本轮自测载体）、`teamwork/00-协作契约.md` §3.3、`teamwork/Rank-3/存档与flag规范.md` §3.1 / §3.3 / §4.1 / §4.4 / §4.7、`teamwork/Rank-2/GRACE-UPGRADE-TUNING.md`（Rank-2 并发产出，数值真源）、`teamwork/Rank-2/调度任务单-latest.json`（对齐 upgrade id / 余额口径，只读）、`teamwork/Rank-2/WAVE-TRIAL-TUNING.md`（R26 后已落地）、`teamwork/Rank-3/GRACE-RETRY-V020.md` / `verify_grace_flags_v030.gd`（R25 先例）、`teamwork/Rank-3/WAVE-TRIAL-GDD.md` §0~§8 / `verify_wave_flags_v040.gd` / `DONE-R26.md`（R26 先例）、`F:/Game/aierdengfahuan/README.md`（状态表）、`teamwork/Rank-3/R27-*.log`（15 份真跑 stdout）。
