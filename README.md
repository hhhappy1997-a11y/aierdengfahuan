# 艾尔登法环 · HD-2D（aierdengfahuan）

> 项目级**运行时状态表**。按 godogen `prompts/runtime.md` 纪律长期维护三块：① 已做了什么、② 还差什么、③ 资产清单表；
> 结构性事实自己验（能加载 / 无 SCRIPT ERROR / 资产就位），产出先目视检查再接入，零付费、零外部依赖。
> 工程根 `F:/Game/aierdengfahuan`｜Godot 工程 `F:/Game/aierdengfahuan/godot`｜引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`
> （`--version` = `4.7.2.stable.official.ed1daf0bf`，R22 实测 `EXIT=0`）。
> 本文件由 **R22 · cmd-20261109-124640-185-A3（Rank-3）** 更新；资产表字节数均为 `stat -c %s` 对实际落盘文件的实测值，不编造。
> **R23 · cmd-20261109-133602-490-A3（Rank-3）** 追加 §3.4「R23 素材条目与本机可选素材源合规登记」（口径 / 合规登记，非落盘产物）；§3.1~§3.3 既有实测值与历史结论未改。
> **R24 · cmd-20261109-205253-730-A3（Rank-3）** 追加「一、已做了什么」**v0.2.0 条目 + R24 回归真跑行**、「二、还差什么」**第 9 项 `main_scene` 缺口登记**；新增 `teamwork/Rank-3/GRACE-RETRY-V020.md`（重复挑战 / Boss 永久击败 / 赐福休息落盘实现口径，供 R25 直接落地）。§3.1~§3.4 既有实测值与历史结论未改。顶部「中枢 done 轮次」表为 **R22 快照**：R24 由 GUI 直接派单、中枢自 19:14 起不可达（见 `00-群聊总线.md`），未据以改写该表，按历史结论保留、**不冒充已进 done 序列**。
> **R25 · cmd-20261110-204604-840-A3（Rank-3，v0.3.0 方向 4）** 追加「一、已做了什么」**v0.3.0 条目 + R25 回归真跑行**、「二、还差什么」**第 10 / 11 / 12 项**（人工试玩属用户侧 / `128bit` 待确认 / HD-2D 全绿未达）；改 `teamwork/00-协作契约.md` §9.3（裁决 A15 色数口径统一）并新增 §3.3 登记表、`00-汇总.md` §6.2 待确认项同步、`teamwork/Rank-3/存档与flag规范.md` §3.3 追加 2 个 flag，新增 `teamwork/Rank-3/verify_grace_flags_v030.gd` 自测载体。§3.1~§3.4 既有实测值与历史结论未改；顶部「中枢 done 轮次」表仍为 R22 快照，按历史结论保留、不冒充已进 done 序列。**A16（`main_scene` 改指 `courtyard.tscn`）属 Rank-1 工程写入、A17（人工试玩）属用户侧，本轮 Rank-3 均不代做、不冒充完成**。
> **R26 · cmd-20261111-073556-928-A3（Rank-3，v0.4.0 波次试炼）** 追加「一、已做了什么」**v0.4.0 条目 + R26 回归真跑行**、「二、还差什么」**第 13 项**（`WAVE-TRIAL-TUNING.md` `[PLACEHOLDER]` 数值待人工试玩校准 / Rank-2 并发表落地后校对引用键名）并复核 **第 10（人工试玩）/ 11（`128bit`）/ 12（HD-2D 全绿未达）在 v0.4.0 仍未达**；新增 `teamwork/Rank-3/WAVE-TRIAL-GDD.md`（Game Designer 六项 + 核心循环 + 目标梯度 + 留存钩子 + Level Designer blockout + 难度曲线，数值全部引用 Rank-2 `WAVE-TRIAL-TUNING.md` `[PLACEHOLDER]` 表、不另造数值）、`teamwork/Rank-3/verify_wave_flags_v040.gd`（三段式 flag 口径自测）；`00-协作契约.md` §3.3 与 `存档与flag规范.md` §3.3 追加 3 个 flag（`dungeon.wave_trial.best_wave` int 单调递增 / `dungeon.wave_trial.completed` bool 只增不减 / `grace.trial.points` int 单调递增）并说明与十字段 / `schema_version=3` / `commit(reason)` / 先落盘顺序的关系。§3.1~§3.4 既有实测值与历史结论未改；顶部「中枢 done 轮次」表仍为 R22 快照，按历史结论保留、不冒充已进 done 序列。**本轮 Rank-3 未写任何 `godot/` 工程文件**（Rank-1/2/4 并发写入），未自行 git。
> **R27 · cmd-20261111-083350-244-A3（Rank-3，v0.5.0 赐福成长）** 追加「一、已做了什么」**v0.5.0 条目 + R27 回归真跑行**、「二、还差什么」**第 14 项**（`GRACE-UPGRADE-TUNING.md` / `grace_upgrade_config.gd` 待落地校对 `<id>` / `[PLACEHOLDER]` 数值待人工试玩校准 / 三段式收敛口径待裁决 / 永久增益运行时效果待接通）并复核 **第 10（人工试玩）/ 11（`128bit`）/ 12（HD-2D 全绿未达）/ 13（v0.4.0 波次数值校准）在 v0.5.0 状态**；`WAVE-TRIAL-GDD.md` 追加 §9「赐福成长」章节（Game Designer 六项 + 核心循环补全为五环节「行动→反馈→目标→**消费成长**→再行动」+ 点数出口闭合断点 + 目标梯度与三条留存钩子 + 三段式 flag / 落盘口径），新建 `WAVE-TRIAL-SPATIAL.md`（Level Designer 三波空间节奏 blockout：入场读秒 / 可见预告 / 站位退避 / 难度空间优先于数值缩放 / 教学-加压-收束 / 环境叙事标注，只写规格不改脚本）；`00-协作契约.md` §3.3 与 `存档与flag规范.md` §3.3 追加 2 个 flag（`grace.trial.spent_points` int 单调递增 / `grace.upgrade_<id>.unlocked` bool 单向）并说明 `<id>` 三段式收敛、十字段 / `schema_version=3` / `commit(reason)` / 先落盘顺序关系；新建 `verify_grace_flags_v050.gd`（6 类 25 PASS 口径自测）。§3.1~§3.4 既有实测值与历史结论未改；顶部「中枢 done 轮次」表仍为 R22 快照，按历史结论保留、不冒充已进 done 序列。**本轮 Rank-3 未写任何 `godot/` 工程文件**（Rank-1/2/4 并发写入），未自行 git。
> **R28 · cmd-20261111-095602-827-A3（Rank-3，v0.6.0 赐福引导 · 三步教学）** 追加「一、已做了什么」**v0.6.0 条目 + R28 回归真跑行**、「二、还差什么」**第 15 项**（Rank-2 `tutorial_config.gd` / `tutorial_steps.tres` 待落地校对引用键名 / `[PLACEHOLDER]` 数值待人工试玩校准 / 教学 HUD·点亮态·第 1 波衔接运行时接线 / `step_index` 单调 vs T 重开「进度归零」口径待裁决）并追加 **v0.6.0 复核段**（第 10 人工试玩 / 11 `128bit` / 12 HD-2D 全绿未达 / 13 波次数值校准 / 14 成长数值校准在 v0.6.0 状态）；`WAVE-TRIAL-GDD.md` **追加 §10「赐福引导 · 三步教学」章节**（Game Designer 六项齐全：purpose / player experience goal + 数值引用表 / inputs / outputs / edge cases T-E1~T-E12 / failure states T-F1~T-F7 + 前 30 秒断点定位 + 五层目标梯度衔接 + 三段连续奖励节奏 + 四条留存钩子 + 三段式 flag / 落盘口径 / 校对清单），**所有数值引用 Rank-2 `[PLACEHOLDER]` 表、不另造数值**（本轮教学表并发产出、Rank-3 产出时尚未落地，采用字段名引用式占位并如实登记待校对）；新建 **`TUTORIAL-BLOCKOUT.md`**（Level Designer 标准：教学区 / 战斗区空间分离三条机制、视觉引导 HUD 安全区避开五套占位 / 敌人预告「可见不激活」/ 退避带沿用 S5、三步「示范→操作→反馈」节奏、失败回退与不惩罚原则，只写规格不改脚本）；`00-协作契约.md` §3.3 与 `存档与flag规范.md` §3.3 追加 2 个 flag（`grace.tutorial.completed` bool 单向 / `grace.tutorial.step_index` int 单调递增）并说明 key/类型/读写方/单调性、与 §4.4 十字段 / `schema_version=3` / `commit` / 先落盘顺序关系；新建 **`verify_tutorial_flags_v060.gd`**（4 类 **21 PASS / 0 FAIL** 口径自测：三段式正则含六类反例 / 单向单调 / 重启读回 / commit 顺序与十字段）。§3.1~§3.4 既有实测值与历史结论未改；顶部「中枢 done 轮次」表仍为 R22 快照，按历史结论保留、不冒充已进 done 序列。**本轮 Rank-3 未写任何 `godot/` 工程业务文件**（Rank-1/2/4 并发写入），未自行 git。
> **R29 · cmd-20261111-112803-992-A3（Rank-3，v0.7.0 新内容：风格锚点 v2 定调 + A28 全文口径统一）** 新增工程根 **`HD2D-STYLE-ANCHOR-v2.md`**（Technical Artist / Game Designer 的 P0 定调：v1 八字段逐字冻结继承 + 补「景深分层 / 光色规范 / 暗角与光晕 / 三波色带节奏」四字段 + 与《八方旅人》式 HD-2D 差距清单 + 三条验收判据 + **16 色受控色板 / 项目级色库 ≥256 两层口径沿用裁决 A15**；明确只做 2D 近似强化、不切后端 A30、不谎称真 3D 光效）；**A28 全文口径统一**：把 `teamwork/00-协作契约.md` §3.3、`teamwork/Rank-3/WAVE-TRIAL-GDD.md` §10.8、本 README 里 `grace.tutorial.step_index` 的写方 / commit reason / 读方统一为裁决 A26 落地口径（写方 Rank-1 `tutorial_director.gd`、reason `tutorial_step_reward`、教学 HUD 读运行时游标、世界 flag 只作历史进度），逐处改前→改后见 `teamwork/Rank-3/DONE-R29.md`；追加「一、已做了什么」**v0.7.0 条目 + R29 回归真跑行**、「二、还差什么」**第 16 项 + v0.7.0 复核段**；**31 PASS / 0 FAIL 存档 / HUD 回归不回退**（`r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11，首次即 11/0）、12 次引擎调用全 `EXIT=0`、12 份 `R29-*.log` 逐份 `grep SCRIPT ERROR=0` / `Parse Error=0`（三段门禁达成；G3 退出期 4 条 `ERROR:` 前缀残留如实登记、非 SCRIPT ERROR，见下 R29 回归真跑行与 `DONE-R29.md`）。§3.1~§3.4 资产表实测字节数、「中枢 done 轮次」表（仍为 R22 快照）与其余历史结论未改；**本轮 Rank-3 未写任何 `godot/` 工程业务文件**（Rank-1/2/4 并发写入），未自行 git。
> **R29C · cmd-20261111-120737-845-A3（Rank-3，v0.7.1 裁决 A31 口径统一扩大 + A32 派生色登记）** 裁决 A31 把 R29 如实登记、授权边界外保留的**两处口径差异**统一到 A26 落地口径：`WAVE-TRIAL-GDD.md` 行 492（§10.3 inputs，任务单称「§10.6 行 492」）「Rank-3 订阅写 / Rank-1 不写 flag」与 `00-协作契约.md` §3.3 `grace.tutorial.completed` 行「写方 Rank-3」→ **写方 Rank-1 `tutorial_director.gd` / commit reason `tutorial_step_reward` / 教学 HUD 读运行时游标 / 世界 flag 只作历史进度**，逐处改前→改后见 `teamwork/Rank-3/DONE-R29C.md`；不改动其它历史条款（GDD §10.8 `completed` 行等按授权边界保留、作为新残留如实登记交裁决）。裁决 A32 在 `HD2D-STYLE-ANCHOR-v2.md` 追加 **§8「派生色说明」**：钉死 shader 色 uniform 真源是 `godot/data/render/depth_profile.tres` 锚点色 `#1B2A4A` / `#C99A3A`（hex→`Color(String(v))` 逐字直取、零数值派生），把 shader 报告派生显示色 `#2B3A5C` / `#F0A94C` 如实登记为 Rank-4 `palette_256.json` 32 色板灰阶档 L3/L7（Rank-2 首版误判 / 降级分支历史显示色），立下「派生色须写明来源公式 + rationale、不得冒充新色板、不并入 16 色受控表」硬规则；**未改任何 `godot/` 工程文件**。追加「一、已做了什么」**R29C 条目 + R29C 回归真跑行**、「二、还差什么」**第 16 项同步 + R29C 复核段**（R29B 为 Rank-1 并行轮次 `cmd-20261111-120737-841-A1`、本轮不代写其结论）；**31 PASS / 0 FAIL 存档 / HUD 回归不回退**、12 次引擎调用全 `EXIT=0`、12 份 `R29C-*.log` 逐份 `SCRIPT ERROR=0` / `Parse Error=0` / `ERROR:` 前缀 = 0（三段门禁达成；G3 仅 1 条既有 `ObjectDB instances leaked` WARNING、如实保留非 ERROR）。§3.1~§3.4 资产表实测字节数、「中枢 done 轮次」表（仍 R22 快照）与其余历史结论未改；**本轮 Rank-3 未写任何 `godot/` 工程业务文件**，未自行 git。
> **R30 · cmd-20261111-125001-356-A3（Rank-3，v0.8.0 完善旧内容：A34 残留清除 + 图鉴 GDD 章节）** ① **A34 残留 1**：`WAVE-TRIAL-GDD.md` §10.8 新 flag 表 `grace.tutorial.completed` 行「写方 Rank-3」就地统一为 A26 落地口径（写方 Rank-1 `tutorial_director.gd` / reason `tutorial_completed`、每步 `tutorial_step_reward` / 教学 HUD 读运行时游标 / 世界 flag 只作历史进度）并补 R30 说明段；`00-协作契约.md` §3.3 登记表 `completed` 行（R29C / A31 已统一）核对一致、**无需再改**、补 R30 说明段；逐处改前→改后见 `teamwork/Rank-3/DONE-R30.md`，不改动其它历史条款。② **A34 残留 2**：`HD2D-STYLE-ANCHOR-v2.md` §8.4 由「未完成 / 待登记」改写为派生显示色**四要素登记**（① 来源锚点 hex ② 派生公式含中间计算 ③ 结果 hex ④ rationale），明确 `#2B3A5C` / `#F0A94C` 来自 `teamwork/Rank-4/palette_256.json` 32 色板灰阶档 `L3(28%)` / `L7(85%)` 的历史显示色，给出「锚点色 → 灰阶插值 / 亮度提升 → 结果色」可复算公式（逐通道 Δ + 「冻结档不可由相邻档线性插值生成」反证），并声明**不是 v2 新色板 / 不并入 §5.2 16 色受控表 / uniform 真源仍是 `depth_profile.tres` 锚点色**；未改任何 `godot/` 工程文件。③ 新写 **`teamwork/Rank-3/CODEX-GDD.md`**（Game Designer 六项齐全：purpose / player experience goal / inputs / outputs / edge cases / failure states + 「收集」留存钩子 + 「教学→三波→成长」四层梯度衔接 + 奖励节奏与不惩罚原则 + `[PLACEHOLDER]` 数值引用表），**所有数值引用 Rank-2 `[PLACEHOLDER]` 表、不另造数值**（Rank-2 `CODEX-TUNING.md` / `codex_config.gd` / `codex_entries.tres` 于 12:55~12:59 落盘、13:01:35 done，本 GDD 已按落地表校对引用键名 / 数值 / 语义并逐项一致，见 `CODEX-GDD.md` §11 C-V1）。④ 追加「一、已做了什么」**v0.8.0 条目 + R30 回归真跑行**、「二、还差什么」**第 16 项同步（残留口径差异已清 / 派生色四要素已补）+ 第 17 项（v0.8.0 图鉴缺口）+ v0.8.0 复核段**；**31 PASS / 0 FAIL 存档 / HUD 回归不回退**（`r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11，首次即 11/0）、12 次引擎调用全 `EXIT=0`、12 份 `R30-*.log` 逐份 `SCRIPT ERROR=0` / `Parse Error=0` / `ERROR:` 前缀 = 0（三段门禁达成；G3 仅 1 条既有 `2 ObjectDB instances were leaked at exit` WARNING、如实保留非 ERROR）。§3.1~§3.4 资产表实测字节数、「中枢 done 轮次」表（仍 R22 快照）与其余历史结论未改；**本轮 Rank-3 未写任何 `godot/` 工程业务文件**，未自行 git（总指挥收尾）。

> **R31 · cmd-20261111-133549-886-A3（Rank-3，v0.9.0 完善旧内容：满愿存档三态回读 + GDD v0.9.0 + 契约登记）** ① `00-协作契约.md` §3.3 **只追加 R31 说明段**（不改历史条款 / 不改 I-1~I-6 接口表 / 不改 §3.1·§3.2 缺号），登记两个新三段式 flag：`grace.trial.modifier_active`（String / 基线 `""` / **非单调·局内翻转**）与 `grace.codex_full_wish.notified`（bool / 基线 `false` / **false→true 单向**），严格匹配 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`；只作 `flags` 字典新 key，`SaveDelta` 十字段与 `schema_version=3` 冻结、不写 `removals`、不新增顶层字段；`存档与flag规范.md` §3.3 全局登记表同步追加两行 + R31 注记。② 新写 **`godot/scripts/rpg/verify_v090_save_readback.gd`**（只读验证脚本）：三进程三态（write → 新进程 load → 断言读回）验证买齐三项成长后 `grace.upgrade_<id>.unlocked` / `grace.trial.spent_points` / `grace.codex_<id>.unlocked` 与磁盘一致、余额 `points − spent_points ≥ 0`、旧存档缺 key 回落基线；独立 `user://saves/verify_v090_<RUN>/` 临时槽（与生产 `slot_01` 物理隔离、md5 前后一致），不改 `world_state.gd` / `save_system.gd` 生产逻辑、不碰生产存档。③ 新写 **`teamwork/Rank-3/V090-GDD.md`**（game-development-pro 六项：purpose / player experience goal / inputs / outputs / edge cases / failure states，含 B1~B6 broken 判据与空间节奏影响）；`WAVE-TRIAL-GDD.md` / `CODEX-GDD.md` / 本 README **只追加 R31 / v0.9.0 状态段**、不改历史条款；所有新数值标 `[PLACEHOLDER]` 并写 rationale。**真跑结论**：三进程三态 `write 9 / load 6 / assert 41 PASS`、三份 `0 FAIL` / `RESULT=PASS`、合计 **56 PASS / 0 FAIL**，三 pid `31616 / 1644 / 24208` 互不相同（A02 机器判定）；单进程 `all` 自检 **54 PASS / 0 FAIL**；三段门禁 G1 `--headless --import` / G2 `--check-only --script` / G3 `--headless --quit` 与 5 份自有日志 `SCRIPT ERROR=0`、`Parse Error=0`、`ERROR:` 前缀 = 0 —— **首次 G3 另有 5 条 `SCRIPT ERROR`（`res://scripts/render/impact_feedback.gd:201/241` 的 `cosf()/sinf()`，属 Rank-1 本轮并发写入的瞬时半成品、非 Rank-3 引入），按历轮 R27「定向重跑 1 次」先例重跑归零**，`courtyard.tscn` A38 `node_count=41` 两次真跑回读保持；全部引擎调用 `EXIT=0`，既有 3 条退出 WARNING（`[SaveSystem] --script 跳过自动读回` / `[ChunkManager] 未找到 ChunkRoot` / `2 ObjectDB instances were leaked`）如实保留、非 ERROR。日志留档 `teamwork/Rank-3/R31-*.log`（7 份，均为实际 stdout）。**本段即 R31 / v0.9.0 状态段**：「一、已做了什么」/「二、还差什么」的历史行按「只追加、不改历史条款」保留未动，v0.9.0 增量以本段与 `teamwork/Rank-3/DONE-R31.md` 为准；§3.1~§3.4 资产表实测字节数、「中枢 done 轮次」表（仍 R22 快照）与其余历史结论未改。**本轮 Rank-3 未写任何 `godot/` 工程业务代码**（新写的验证脚本只读加载生产脚本、不修改其逻辑）、未自行 git（总指挥收尾）。
> **R32 · cmd-20261112-074023-412-A3（Rank-3，v0.10.0「赐福抉择 · 韧性处决」：新机制存档口径 + 玩法拆解与收口）** ① `00-协作契约.md` §3.3 **只追加 R32 说明段**（不改历史条款 / I-1~I-6 / §3.1·§3.2 缺号），登记 4 个新三段式 flag：`grace.boon_draft.selected`（String / 非单调·局内翻转）、`grace.boon_draft.cost_applied`（bool / 非单调·局内翻转）、`combat.boss_01.stagger_window`（bool / 非单调·局内翻转）、`grace.execution.performed`（int / 单调只增），严格匹配 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`；只作 `flags` 字典新 key，`SaveDelta` 十字段与 `schema_version=3` 冻结、不写 `removals`、不新增顶层字段；`存档与flag规范.md` §3.3 全局登记表同步追加 4 行 + R32 注记。追加段**同时登记总指挥裁决 A39~A45**（A39 命中信号接线归属与 Rank-1 越界授权范围 / A40 项目级色库 ≥256 色由 Rank-4 程序化扩充清零、单帧 ≤16 色不变 / A41 HD-2D 全绿以 `HD2D-STYLE-ANCHOR-v2.md` 三判据为准、如实记「未达全绿」/ A42 录屏目视以总指挥亲自回看首中尾三帧为准 / A43 `128bit` 歧义保留不消歧 / A44 `encounter_director.gd` 唯一写入方 = Rank-1 其余只读 / A45 三类新数值全部 `[PLACEHOLDER]` 待人工试玩校准）。② 新写 **`godot/scripts/rpg/verify_v100_save_readback.gd`**（只读验证脚本）：三进程三态（write → 新进程 load → 断言读回）验证抉择/处决 4 flag 与买齐三项成长后余额一致、`points − spent_points ≥ 0`、旧档缺 key 回落基线、生产 `slot_01` md5 前后一致；独立 `user://saves/verify_v100_<RUN>/` 临时槽（与生产物理隔离、三 PID 互不相同），不改 `world_state.gd` / `save_system.gd` 生产逻辑、不碰生产存档。③ 新写 **`teamwork/迭代-v0.10.0-赐福抉择与韧性处决.md`**（游戏拆解表「需求→机制→数值→状态→验收」+ P0/P1/P2 漏洞识别 + GDD 六项 + 三栏清单 + 节点与信号链架构 + 真跑数字 + 验收三态 + 风险回滚 + 零付费零外部依赖 backlog）。④ 本 README 追加 v0.10.0 状态段 / 资产表增量 /「已做了什么」/「还差什么」（见文末 §四，历史行一律保留未动）。**真跑结论（Rank-3 实测）**：三进程三态 `write 9 / load 6 / assert 42 PASS`、三份 `0 FAIL` / `RESULT=PASS`、合计 **57 PASS / 0 FAIL**，三 pid `22080 / 26888 / 26012` 互不相同（A02 机器判定）；单进程 `all` 自检 **55 PASS / 0 FAIL**；三段门禁 G1 `--headless --import` / G2 `--check-only --script` / G3 `--headless --quit` 与 7 份自有日志逐份 `SCRIPT ERROR=0` / `Parse Error=0` / `ERROR:` 前缀 = 0（`R32-G3-quit.log` 回读 `courtyard.tscn node_count=41`，A38 断言保持；生产 `slot_01` md5 前后一致 `ea30335b3d1fd6c5a846e04a704d91dc`）；全部引擎调用 `EXIT=0`，既有 3 条退出 WARNING（`[SaveSystem] --script 跳过自动读回` / `[ChunkManager] 未找到 ChunkRoot` / `2 ObjectDB instances were leaked`）如实保留、非 ERROR。日志留档 `teamwork/Rank-3/R32-*.log`（7 份，均为实际 stdout）。**引用 R32 派单反馈数字（非 Rank-3 本轮真跑，如与最终实测不符以各自 Rank 真跑为准）**：Rank-1 反馈 42 PASS / HUD 布局 19 PASS / 处决运行时 16 PASS；Rank-2 赐福抉择 97 PASS / 韧性 62 PASS / 词条运行时 41 PASS / 既有 `.tres` md5 前后一致；全工程 `SCRIPT ERROR=0`、A38 节点数 41。**本段即 R32 / v0.10.0 状态段**：「一、已做了什么」/「二、还差什么」/「三、资产清单表」历史行按「只追加、不改历史条款」保留未动，v0.10.0 增量以本段、文末 §四 与 `teamwork/Rank-3/DONE-R32.md` 为准；§3.1~§3.4 资产表实测字节数、「中枢 done 轮次」表（仍 R22 快照）与其余历史结论未改。**本轮 Rank-3 未写任何 `godot/` 工程业务代码**（新写的验证脚本只读加载生产脚本、不修改其逻辑）、未自行 git（总指挥收尾）。

> **R34 · cmd-20261112-091304-455-A3（Rank-3，v0.11.0「玩法闭合 · 连击评价」：点数落盘接线 + A55 唯一权威通道 + 迭代收口）** ① `00-协作契约.md` §3.3 **只追加 R34 说明段**：登记 2 个新三段式 flag（`combat.combo.rank` String 非单调 / `combat.combo.count` int 非单调·每波覆盖）+ **R32 四 flag 的 I-1 落盘接线口径**（信号订阅 → 事件键配对去重 → `set_flag` → `commit(reason)` 原子落盘 → 先落盘后改实例）+ **总指挥裁决 A49~A55**，其中 **A55 = `points_awarded(reason, points, source)` 点数落盘唯一权威通道**（`wave_cleared` 只作 HUD 展示基础值、`combo_settled` 只作对账与展示、三条通道职责边界写清），解决 R34B §4.4 登记的「点数落盘口径分叉」；`teamwork/Rank-3/存档与flag规范.md` §3.3 全局表同步追加 2 行 + R34 注记。② 新写 **`godot/scripts/rpg/verify_v110_save_commit.gd`**（只读三进程三态验证）：`write 11 + load 6 + assert 49 = 66 PASS / 0 FAIL`、三 pid `11728 / 30352 / 26900` 互不相同、单进程 `all` `64 PASS / 0 FAIL`、生产 `slot_01` md5 `5e900b2b47df9e2a9b36c4100282bc25` 前后一致；覆盖 A55 三通道边界 / A51 防通胀（反例 `410 / 336 / 370 / 420 != 落盘 210`）/ 防重复领取（同 execution / 清波 / 抉择不二次加点或扣费）/ 旧档缺 key 回落基线 / 十字段与 `schema_version=3` 冻结 / `commit(reason)` 原子写。③ 新写 **`teamwork/迭代-v0.11.0-玩法闭合与连击评价.md`**（玩法拆解表 / P0~P2 / GDD 六项 / 三栏清单 / 节点与信号链架构 / 自测与真跑数字 / 验收三态 / 风险回滚 / 零付费零外部依赖 backlog）。④ 本 README 追加 v0.11.0 状态表 / 资产表 / 已做与还差（文末 §五）。⑤ 三段门禁 G1 `--headless --import` / G2 `--check-only --script` / G3 `--headless --quit` 全 `EXIT=0`，7 份 `R34-*.log` 逐份 `SCRIPT ERROR=0` / `Parse Error=0` / `ERROR:` 前缀 = 0，G3 回读 `courtyard.tscn node_count=41`（A38 断言保持）。**真源结论见 `teamwork/Rank-3/DONE-R34.md`。本轮 Rank-3 未写任何 `godot/` 业务代码（仅新增只读验证脚本）、未改其它 Rank 产出、未改契约历史条款 / I-1~I-6 / §3.1·§3.2 缺号、未自行 git（总指挥收尾）**；§3.1~§3.4 资产表实测字节数与「中枢 done 轮次」表（仍 R22 快照）一律未改。

---

## 中枢 done 轮次

来源：`teamwork/command_center/commander/report.md`（调度中枢战报，逐 ROUND 的 done 记录）。

| 项 | 值 |
|---|---|
| 中枢**最近 done 轮次** | **R21B**（`cmd-20261109-122557-230-A4`，2026-11-09 12:37:03 done，按最终工程重导 exe / apk） |
| 当前 dispatched 轮次 | **R22**（A1 / A2 / A3 / A4 四路，2026-11-09 12:46:40 派发；本 README 由 A3 本单更新） |
| 已 done 的 ROUND 序列 | R7 · R8 · R9 · R10 · R11 · R12 · R13 · R14 · R15 · R16 · R17 · R18 · R19 · R20 · R20B · R21 · R21B |
| 1–4 号累计完成 | 30 / 23 / 23 / 26（report.md「1-4 号 AI 状态」） |

> 资产表「中枢 done 轮次」列依据 report.md 各 ROUND 的**任务标题与 done 记录**归类，非逐文件精确溯源；
> 逐文件原始落位轮次见各 `teamwork/Rank-N/DONE-R*.md`。R21B = 工程冻结后的最终交付态，R22 = 本单真跑验收态。

---

## 一、已做了什么

| 域 | 已落地（含对应中枢 done 轮次） |
|---|---|
| 工程骨架 | `godot/project.godot`：`config_version=5`、`run/main_scene=res://scenes/Main.tscn`、**6 个 autoload**（WorldState / GameEvents / SaveSystem / ChunkManager / SceneRouter / SaveDeltaWriter，R20 注册第 6 个）、15 个 input action、Jolt Physics、GL Compatibility、项目级 Nearest 纹理过滤。R7–R9 门禁归零，R20 / R21B |
| 存档（Rank-3） | **十字段 SaveDelta**（`schema_version / slot / seq / baseline / flags / quests / inventory / spawns / removals / meta`）、`schema_version=3`、单槽 `slot_01`、**三段式 flag** `^(world\|quest\|combat\|grace\|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`、`.tmp → flush → rename_absolute → delta.json` 原子写、1→2→3 迁移 / 日志升序回放 / `_apply_snapshot`。R20 注册 autoload、R21 统一 `travel_to()` 与 `grace_fast_travel()` 两入口口径。**R22 本单补做「写盘 → 重启独立引擎进程 → `_load()` 回放 → `get_flag` 读回」端到端真跑**（见下） |
| 战斗（Rank-2） | 帧数据 / Boss 3 招 / 阶段切换 / `CombatDataValidator` 类级实例化、翻滚帧修正。R9–R21 |
| 美术与渲染（Rank-4/Rank-1） | I-5 四类 PNG、SpriteFrames、HD-2D 光效独立场景、画质桌面 / 移动双档、地面材质与程序化占位兜底。R13–R21 |
| 场景 | `courtyard.tscn`（**实测 25 节点**）、`player.tscn` / `boss_01_margit.tscn` / `hud.tscn` / `hd2d_fx.tscn` / `quality_settings.tscn`。R15–R21B |
| 产物 | `build/` 下 exe / pck / apk / apk.idsig（R21B 按最终工程重导，字节数见资产表） |
| 三段门禁 / 回归 | R21 的 **31 PASS / 0 FAIL**（`r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11）R22 重跑**不回退**；G1 `--import` / G2 `--check-only --script` / G3 `--quit` 全 `EXIT=0`，12 份 R22 日志 `grep SCRIPT ERROR / Parse Error / ERROR` **全 0** |
| **v0.2.0 遭遇战迭代**（R24 派单 · 四路并发，**未宣称完成**） | **主场景接线**（Rank-1 `courtyard.tscn` + `build_courtyard_v020.gd`：把 `EncounterRoot` 接进庭院，**不改 `project.godot` 的 `main_scene`**）／**Boss 重置**（Rank-2 `encounter_director.gd`：赐福休息只重置运行时实例，不清 `combat.<id>.defeated`）／**同招冷却**（Rank-2 `encounter_rules_v020.gd`：招式冷却与距离门槛，消除连续同名招式）／**L4 泄漏曲线**（Rank-4 `perf_encounter_v020.gd` + `capture/`：反复进出场景的节点 / 内存对照）。Rank-3 本轮只交付 `teamwork/Rank-3/GRACE-RETRY-V020.md` 存档口径与 `DONE-R24.md`，**未写任何 `godot/` 工程文件**；四项实现归各自 Rank 并发写入，Rank-3 本轮**未代验、不宣称完成** |
| **R24 回归真跑**（Rank-3） | R21/R22 的 **31 PASS / 0 FAIL**（`r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11）R24 重跑**不回退**；R22 存档端到端 `r22_save_e2e.gd` **16 PASS / 0 FAIL**（write 7 `pid=18760` + read 9 `pid=11108`，两独立引擎进程）；G1 `--headless --import` / G2 `--check-only --script` ×4 / G3 `--headless --quit` 全 `EXIT=0`，11 份 `R24-*.log` `grep SCRIPT ERROR / Parse Error / ERROR` **全 0**；既有退出 WARNING（`ChunkManager` / `ObjectDB instances leaked`）如实保留、非 ERROR |
| **v0.3.0 方向 4**（R25 派单 · Rank-3 契约口径 / flag 登记与验证） | **裁决 A15**：按用户选第 5 项（确认美术风格提案 v1）把 `teamwork/00-协作契约.md` §9.3 的 I-5 色数口径由「256 色以上 / 单帧 ≥256」统一为「**项目级色库 ≥256 色、单帧强制 ≤16 色索引、RGBA 保 alpha、128px 基准画布**」（色库下限与单帧上限分两层、不矛盾，原「单帧 ≥256」废止）；`128bit` 歧义**仍显式保留、不消歧、不编码进期望值、待用户确认**；同步 `00-汇总.md` §6.2 待确认项，未改其它历史条款。**两个三段式 flag 登记**（`grace.encounter_01.retried` int 单调递增 / `grace.encounter_01.retry_active` bool 回合内翻转）进契约 §3.3 登记表与 `teamwork/Rank-3/存档与flag规范.md` §3.3 全局登记表，写明 key / 类型 / 读写方 / 单调性。新增 `teamwork/Rank-3/verify_grace_flags_v030.gd`（`extends SceneTree`）口径自测：三段式正则 / commit「先落盘再改运行时实例」/ `retried` 单调递增 / 重启读回一致，输出 PASS/FAIL 与 RESULT（`--script` 模式不用 `/root/...` 绝对路径，用 `Engine.get_main_loop()` / `root.get_node_or_null()` 相对探活、取不到如实降级）。**A16 / A17 归裁决不代做**：`run/main_scene` 改指 `courtyard.tscn` 属 Rank-1 工程写入（本轮不碰 `godot/`）、人工试玩属用户侧（本轮只给勾选清单）。Rank-3 本轮**未写任何 `godot/` 工程文件** |
| **R25 回归真跑**（Rank-3） | R21/R22 的 **31 PASS / 0 FAIL**（`r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11）R25 重跑**不回退**；`verify_grace_flags_v030.gd` 口径自测 **16 PASS / 0 FAIL `RESULT=ALL_PASS`**（selftest 10 `pid=34108` + write 3 `pid=41208` + read 3 `pid=37940`，write→read 两独立引擎进程 pid 不同实证「重启读回一致」；`JSON.parse_string` 的 int→float round-trip 由 `_val_eq` 容忍、如实登记）；引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe` 三段门禁 G1 `--headless --import` / G2 `--check-only --script` ×5（含新脚本语法检查）/ G3 `--headless --quit` 全 `EXIT=0`，**13 次引擎调用全 `EXIT=0`**、13 份 `R25-*.log` `grep SCRIPT ERROR / Parse Error / ERROR` **全 0**；既有退出 WARNING（`ChunkManager` / `ObjectDB instances leaked`）如实保留、非 ERROR |
| **v0.4.0 波次试炼**（R26 派单 · Rank-3 设计口径 / flag 登记与验证） | 新增 `teamwork/Rank-3/WAVE-TRIAL-GDD.md`：Game Designer 核心循环六项（purpose / player experience goal / inputs / outputs / edge cases / failure states）齐全、核心循环（行动→反馈→目标→再行动）、目标梯度（30 秒短期 / 一局三波全清 / 长期最高波次）、留存钩子，并按 Level Designer 标准补「入场读秒 + 敌人可见预告 + 退避空间 + 三波空间节奏」blockout 与难度曲线；**所有数值引用 Rank-2 `WAVE-TRIAL-TUNING.md` `[PLACEHOLDER]` 表、不另造数值**（该文件属 Rank-2 并发产出、Rank-3 产出时尚未落地，GDD 用字段名引用式占位，待落地后校对键名、如实登记）。**三个三段式 flag 登记**进 `00-协作契约.md` §3.3 与 `存档与flag规范.md` §3.3（key / 类型 / 读写方 / 单调性）：`dungeon.wave_trial.best_wave`（int 单调递增）/ `dungeon.wave_trial.completed`（bool 只增不减）/ `grace.trial.points`（int 单调递增）；写明与 §4.4 十字段冻结（新 flag 只进 `flags` 字典、不新增顶层字段）、`schema_version=3` 不触发迁移、`commit(reason)` 三处强制落盘点、「先落盘再改运行时实例」顺序。新增 `teamwork/Rank-3/verify_wave_flags_v040.gd`（`extends SceneTree`）：三段式正则 / `best_wave` 单调递增 / `completed` 只增不减 / 重启读回一致 / commit 顺序与十字段，输出 PASS/FAIL 与 RESULT（`--script` 模式不用 `/root/...` 绝对路径，用 `Engine.get_main_loop()` / `root.get_node_or_null()` 相对探活）。Rank-3 本轮**未写任何 `godot/` 工程文件**，运行时 / 数据表归 Rank-1 / Rank-2 并发写入、不代验、不宣称完成 |
| **R26 回归真跑**（Rank-3） | R21/R22 的 **31 PASS / 0 FAIL**（`r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11）R26 重跑**不回退**；`verify_wave_flags_v040.gd` 口径自测 **23 PASS / 0 FAIL `RESULT=ALL_PASS`**（selftest 17 `pid=22900` + write 3 `pid=10124` + read 3 `pid=17944`，三进程 pid 全不同；write→read 两独立引擎进程实证「重启读回一致」；`JSON.parse_string` 的 int→float round-trip 由 `_val_eq` 容忍、如实登记）；引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe` 三段门禁 G1 `--headless --import` / G2 `--check-only --script` ×6（含新脚本语法检查）/ G3 `--headless --quit`，**14 次引擎调用全 `EXIT=0`**、14 份 `R26-*.log` 逐份 `grep SCRIPT ERROR / Parse Error / ERROR` **全 0**（三段门禁 `grep SCRIPT ERROR=0` 达成）；既有退出 WARNING（`ChunkManager` / `ObjectDB instances leaked`）如实保留、非 ERROR |
| **v0.5.0 赐福成长**（R27 派单 · Rank-3 设计口径 / 空间规格 / flag 登记与验证） | `WAVE-TRIAL-GDD.md` **追加 §9「赐福成长」章节**：Game Designer 六项（purpose / player experience goal / inputs / outputs / edge cases / failure states）+ 核心循环由 R26 四环节补全为 v0.5.0 五环节「行动→反馈→目标→**消费成长**→再行动」+ 点数出口如何闭合断点（`spent_points` 单调镜像、`points` 不回退、不写 `removals`、余额 `points − spent_points ≥ 0`）+ 目标梯度四层（短期 / 中期 / 长期 / 成长）+ 三条留存钩子（永久增益 / 历史最佳 / 重复挑战更轻松）+ 三段式 flag / 落盘口径与校对清单；**所有新数值引用 Rank-2 本轮 `GRACE-UPGRADE-TUNING.md` `[PLACEHOLDER]` 表、不另造数值**（Rank-2 并发产出、Rank-3 产出时尚未落地，采用字段名引用式占位并如实登记待校对）。新建 **`WAVE-TRIAL-SPATIAL.md`**（Level Designer 三波空间节奏 blockout）：每波入场读秒 `telegraph_sec` 与敌人可见预告、站位与连续退避带、**难度空间优先于数值缩放**、逐波教学 / 加压 / 收束节奏 + 环境叙事标注 T1/T2/T3、S1~S7 空间要素与 SP-A1~A5 规格判定项；**只写规格、不改脚本 / 场景 / `godot/` 文件**。**两个三段式 flag 登记**进 `00-协作契约.md` §3.3 与 `存档与flag规范.md` §3.3（key / 类型 / 读写方 / 单调性）：`grace.trial.spent_points`（int 单调递增）/ `grace.upgrade_<id>.unlocked`（bool false→true 单向）；写明 `<id>` 四段字面 `grace.upgrade.<id>.unlocked` 与 §3.1 三段式正则冲突、**收敛为三段式**并列为待总指挥裁决（不伪造四段通过正则、不擅自改 `world_state.gd`）；写明与 §4.4 十字段冻结、`schema_version=3` 不迁移、`commit("grace_upgrade_purchased")` 强制落盘点、「先落盘再改运行时实例」顺序、消费绝不写 `removals`、旧存档缺 key 回落基线。新建 **`verify_grace_flags_v050.gd`**（`extends SceneTree`）：6 类断言（三段式正则含四段反例 / `spent_points` 单调 / `unlocked` 单向 / 余额非负 / 重启读回一致 / commit 顺序与十字段），输出 PASS/FAIL 与 RESULT（`--script` 模式不用 `/root/...` 绝对路径，用 `Engine.get_main_loop()` / `get_root().get_node_or_null()` 相对探活）。Rank-3 本轮**未写任何 `godot/` 工程文件**，运行时 / 数据表 / 场景 / 素材归 Rank-1 / Rank-2 / Rank-4 并发写入、不代验、不宣称完成 |
| **R27 回归真跑**（Rank-3） | R21/R22 的 **31 PASS / 0 FAIL**（`r19_verify_hud.gd` **20** + `verify_hud_binding.gd` **11**）R27 重跑**不回退**；**如实登记并发抖动**：首次 `verify_hud_binding.gd` 因共享 `slot_01/delta.json` 初态被并发方写成幂等值（`last_grace_id=关卡前` / `lit=true`）出现 `9 PASS / 2 FAIL`（A1/A2 增量刷新因 `set_flag` 幂等不触发、非代码回退、非 Rank-3 引入），**定向重跑 1 次恢复 `11 PASS / 0 FAIL` `ok=true` `EXIT=0`**，最终 31 PASS 以重跑实证为准；`verify_grace_flags_v050.gd` 口径自测 **25 PASS / 0 FAIL `RESULT=ALL_PASS`**（selftest 19 `pid=16004` + write 3 `pid=26652` + read 3 `pid=25188`，三进程 pid 全不同；write→read 两独立引擎进程实证「重启读回一致」；`JSON.parse_string` 的 int→float round-trip 由 `_val_eq` 容忍、如实登记）；引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe` 三段门禁 G1 `--headless --import` / G2 `--check-only --script` ×6（含新脚本语法检查）/ G3 `--headless --quit`，**15 次引擎调用中 14 次 `EXIT=0`、首次 R17 `EXIT=1`（上述并发抖动、重跑恢复 0）**、**15 份 `R27-*.log` 逐份 `grep SCRIPT ERROR / Parse Error / ERROR` 全 0**（三段门禁 `grep SCRIPT ERROR=0` 达成）；既有退出 WARNING（`ChunkManager` / `ObjectDB instances leaked`）如实保留、非 ERROR |
| **v0.6.0 赐福引导 · 三步教学**（R28 派单 · Rank-3 教学 GDD / 引导 blockout / flag 登记与验证） | `WAVE-TRIAL-GDD.md` **追加 §10「赐福引导 · 三步教学」章节**：Game Designer 六项（purpose / player experience goal + 数值引用表 / inputs / outputs / edge cases T-E1~T-E12 / failure states T-F1~T-F7）齐全 + **「前 30 秒无引导」断点定位**（v0.4.0 仅「自动开始 + 常驻 HUD」回答「打第几波」，未教按键；三步教学把开局变成「示范→操作→反馈」主动引导）+ **五层目标梯度衔接**（引导新增最前置一层 / 短期 30 秒 / 中期三波 / 长期最高波次 / 成长，教学期间不推进三波、`COMPLETED` 后自动进第 1 波 `TELEGRAPH`）+ **三段连续奖励节奏**（教学每步 `reward_points` → 三波 `reward_points` 递增 → `cost` 出口，全程只累加既有 `grace.trial.points`、不写 `removals`、不回退）+ **四条留存钩子**（`completed` 单向「我学会了」/ 开局即正反馈 / 可重开但不惩罚 / 既有历史最佳·点数·永久增益·重复挑战更轻松）+ 三段式 flag / 落盘口径与校对清单 T-V1~T-V9；**所有数值引用 Rank-2 `[PLACEHOLDER]` 表、不另造数值**（本轮 `tutorial_config.gd` / `tutorial_steps.tres` 并发产出、Rank-3 产出时尚未落地，采用字段名引用式占位并如实登记待校对；既有 `WAVE-TRIAL-TUNING.md` / `GRACE-UPGRADE-TUNING.md` 已落地、只引用键名不填数值）。新建 **`TUTORIAL-BLOCKOUT.md`**（Level Designer 标准）：教学区 B-Z1 / 战斗区 B-Z2 **空间分离三条机制**（状态 / 威胁 / 时序分离，逻辑分离视觉连续、不切场景）、**视觉引导**（教学 HUD 安全区 B-Z3 避开既有五套占位、敌人预告「可见但不激活」、退避带沿用 S5 连续）、**三步「示范→操作→反馈」节奏**、**失败回退与不惩罚原则**（错按 / 超时 / 退出 / 重开不死亡不扣点、回退粒度=当前步、运行时回退 vs 持久化单调解耦），TB-A1~A6 / TB-B1~B4 规格判定项，只写规格不改脚本 / 场景 / `godot/` 文件。**两个三段式 flag 登记**进 `00-协作契约.md` §3.3 与 `存档与flag规范.md` §3.3（key / 类型 / 读写方 / 单调性）：`grace.tutorial.completed`（bool false→true 单向）/ `grace.tutorial.step_index`（int `0→1→2→3` 单调递增）；写明与 §4.4 十字段冻结、`schema_version=3` 不迁移、`commit("tutorial_step_reward")`（A28 按裁决 A26 统一；R28 原登记为 `tutorial_step_completed`）/ `commit("tutorial_completed")` 强制落盘点、「先落盘再改运行时实例」顺序、旧存档缺 key 回落基线、教学奖励绝不写 `removals` / 绝不回退 `points`、**A26 已落地 / A28 全文统一：写方 Rank-1 `tutorial_director.gd`、reason `tutorial_step_reward`、教学 HUD 读运行时游标、世界 flag 只作历史进度**（R29 订正；R28 原登记为「待裁决」）。新建 **`verify_tutorial_flags_v060.gd`**（`extends SceneTree`）：4 类断言（三段式正则含六类反例 / 单向单调 / 重启读回一致 / commit 顺序与十字段），`--script` 模式**不用 `/root/...` 绝对路径**，用 `Engine.get_main_loop()` / `get_root().get_node_or_null()` 相对探活。Rank-3 本轮**未写任何 `godot/` 工程业务文件**，运行时 / 数据表 / HUD / 场景归 Rank-1 / Rank-2 / Rank-4 并发写入、不代验、不宣称完成 |
| **R28 回归真跑**（Rank-3） | R21/R22 的 **31 PASS / 0 FAIL**（`r19_verify_hud.gd` **20** + `verify_hud_binding.gd` **11**）R28 重跑**不回退**（本轮 R17 **首次即 `11 PASS / 0 FAIL`、无 R27 的并发 9/2 抖动**）；`verify_tutorial_flags_v060.gd` 口径自测 **21 PASS / 0 FAIL `RESULT=ALL_PASS`**（selftest 15 `pid=25820` + write 3 `pid=26968` + read 3 `pid=3180`，三进程 pid 全不同；write→read 两独立引擎进程实证「重启读回 3/3 一致」；`JSON.parse_string` 的 int→float round-trip 由 `_val_eq` 容忍、如实登记）；引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe` 三段门禁 G1 `--headless --import` / G2 `--check-only --script` ×6（含新脚本语法检查）/ G3 `--headless --quit`，**14 次引擎调用全 `EXIT=0`**、**14 份 `R28-*.log` 逐份 `grep SCRIPT ERROR / Parse Error / ERROR` 全 0**（三段门禁 `grep SCRIPT ERROR=0` 达成）；既有退出 WARNING（`[SaveSystem] --script 工具模式跳过自动读回` / `ChunkManager` / `ObjectDB instances leaked`）如实保留、非 ERROR |
| **v0.7.0 风格锚点 v2 定调 + A28 全文口径统一**（R29 派单 · Rank-3 自有文档 / 契约 §3.3 / GDD §10.8 / README） | 新增工程根 **`HD2D-STYLE-ANCHOR-v2.md`**（Technical Artist / Game Designer 的 P0 定调）：**v1 八字段逐字冻结继承** + 补「景深分层 / 光色规范 / 暗角与光晕 / 三波色带节奏」四字段 + **与《八方旅人》式 HD-2D 的 9 项差距清单（如实登记、非待办承诺）** + **三条验收判据**（缩略图 10% 剪影可读 / 主体与背景明度差 ≥2 档 / 同屏高饱和色 ≤3 种）+ **可逐字复用 16 色受控色板**（13 色继承 v1 §2 + 3 色 `[PLACEHOLDER]` 雾带色；钉死 `cold_night_fog_hex=#1B2A4A` / `warm_gold_key_hex=#C99A3A` / 3 色高饱和白名单；含可机器解析 JSON 块供 Rank-2 `verify_depth_profile_v070.gd` 逐字引用）+ **项目级色库 ≥256 两层口径沿用裁决 A15**（如实登记 Rank-4 `palette_256.json` 32 色板与 v1 §2 两套历史色板并存、不擅自合并、不伪造一致）；**明确只做 2D 近似强化、不切后端（A30）、不谎称真 3D 光效**（工程「光效」全为 `hd2d_fx.gd` 2D `_draw()` 近似，`gl_compatibility` 下真 3D 景深 / 体积光 / 倒影 / bloom 不可直接依赖；P0 定调 / P1 参数化 / P2 全屏 shader 分工归各自 Rank）。**A28 全文口径统一**：`teamwork/00-协作契约.md` §3.3 / `teamwork/Rank-3/WAVE-TRIAL-GDD.md` §10.8 / 本 README 三处 `grace.tutorial.step_index` 的写方（→ Rank-1 `tutorial_director.gd`）/ commit reason（→ `tutorial_step_reward`）/ 读方（→ 教学 HUD 读运行时游标、世界 flag 只作历史进度）统一为裁决 A26 落地口径，逐处改前→改后见 `teamwork/Rank-3/DONE-R29.md`；**不改动其它历史条款**（`completed` 行 / R25~R27 说明段 / §10.8 之外章节 / 资产表 / 中枢 done 表一律未动，§10.8 之外残留口径差异如实登记待裁决）。Rank-3 本轮**未写任何 `godot/` 工程业务文件**，运行时 / 数据表 / 景深参数 / 全屏 shader / 录屏归 Rank-1 / Rank-2 / Rank-4 并发写入、不代验、不宣称完成 |
| **R29 回归真跑**（Rank-3） | 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（`--version` = `4.7.2.stable.official.ed1daf0bf`，G0 `EXIT=0`）· `--path F:/Game/aierdengfahuan/godot`，**一次一个引擎进程、串行执行 12 次**：G1 `--headless --import` / G2 `--headless --check-only --script` ×6（verify_tutorial_flags_v060 / save_delta_writer.gd / hud.gd / r19_verify_hud.gd / verify_hud_binding.gd / r22_save_e2e.gd）/ G3 `--headless --quit` 三段门禁 + 回归 A `--headless --script r19_verify_hud.gd` + 回归 B `--headless --script verify_hud_binding.gd` + TFV selftest `--headless --script verify_tutorial_flags_v060.gd`，**12 次引擎调用全 `EXIT=0`**。**31 PASS / 0 FAIL 不回退**：`r19_verify_hud.gd` `SUMMARY pass=20 fail=0 ok=true` + `verify_hud_binding.gd` `SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true`（**首次即 11/0，无 R27 的并发 9/2 抖动**）；`verify_tutorial_flags_v060.gd` selftest **15 PASS / 0 FAIL `RESULT=ALL_PASS`**（`pid=23808`；**本轮只跑 selftest 一态，未跑 write/read 两独立进程三态，如实登记、不冒充 R28 的 21 PASS 全流程**）。**三段门禁 `grep SCRIPT ERROR=0` 达成**：12 份 `R29-*.log` 逐份 `SCRIPT ERROR=0`、`Parse Error=0`。**如实登记（不谎报）**：`R29-G3-quit.log` 另有 **4 条 `ERROR:` 前缀退出期引擎残留** —— 1 条 `Parent node is busy setting up children, add_child() failed`（backtrace 指向 `res://scripts/hud.gd:795 _ensure_shop_readable` / `hud.gd:158 _ready`，对应日志 `[R29][SHOP] 兑换面板迁出 SubViewport → 独立 CanvasLayer(layer=45)`，属 **Rank-1 本轮并发写入**、非 Rank-3 引入、不代修）+ 3 条 `RID allocations ... were leaked at exit`；**R28 基线 G3 无 `ERROR:` 行**（仅 1 条 `ObjectDB instances leaked` WARNING）。这 4 条**不是 `SCRIPT ERROR`、不是 `Parse Error`、不是回归断言失败**，12 次调用 `EXIT` 全 0、31 PASS 不回退；按历轮「如实保留 WARNING、非 ERROR」纪律一并登记，**不宣称「三类 ERROR 全 0」**。既有退出 WARNING（`[SaveSystem] --script 工具模式跳过自动读回` / `ChunkManager` / `ObjectDB instances leaked`，本轮 24 条）如实保留、非 ERROR。日志留档 `teamwork/Rank-3/R29-*.log`（12 份，均为实际 stdout） |
| **A31 口径统一扩大 + A32 派生色登记**（R29C 派单 · Rank-3 自有文档 / 契约 §3.3 / GDD 行 492 / 锚点 v2 / README） | **裁决 A31**：把 R29 如实登记、授权边界外保留的两处差异统一到 A26 落地口径 —— `WAVE-TRIAL-GDD.md` 行 492（§10.3 inputs，任务单称「§10.6 行 492」）「Rank-3 订阅写 / Rank-1 不写 flag」→ A26 落地口径；`00-协作契约.md` §3.3 登记表 `grace.tutorial.completed` 行「写方 Rank-3」→「写方 Rank-1 `tutorial_director.gd`」并补四要素注记；统一口径 = **写方 Rank-1 `tutorial_director.gd` / commit reason `tutorial_step_reward` / 教学 HUD 读运行时游标 / 世界 flag 只作历史进度**，信号名 `tutorial_step_completed(step_id, reward)` 保留不改，逐处改前→改后见 `DONE-R29C.md`；契约 §3.3 追加 R29C 说明段。**不改动其它历史条款**（`step_index` 行 / `completed` reason `tutorial_completed` / R25~R29 历史说明段 / I-1~I-6 / §9 / GDD §10.8 一律未改）；GDD §10.8 的 `completed` 行仍写方 Rank-3、按授权边界保留、作为新残留如实登记交裁决。**裁决 A32**：`HD2D-STYLE-ANCHOR-v2.md` 追加 §8「派生色说明」——钉死 `cool_fog_color` / `warm_glow_color` 的 uniform 真源为 `godot/data/render/depth_profile.tres` 锚点色 `#1B2A4A` / `#C99A3A`（来源公式 `Color(String(v))` hex→vec3 逐字直取、零数值派生；强度类 ×5/×0.4/×25 才是 `[PLACEHOLDER]` 量纲派生）；把 shader 报告派生显示色 `#2B3A5C` / `#F0A94C` 来源公式与 rationale 如实登记为 Rank-4 `palette_256.json` 32 色板灰阶档 L3(28%)/L7(85%) 与 `verify_depth_profile_v070.gd` 降级常量、Rank-2 首版误判 / 最终 `.tres` 已改回锚点（`DEPTH-PROFILE-TUNING.md` §3 纠错登记）；立下「派生色须写明来源锚点 hex + 派生公式 + 结果 hex + rationale 四要素、不得冒充新色板 / 不并入 §5.2 16 色受控表 / 不改 §5.3 常量块」硬规则；**未改任何 `godot/` 工程文件**。R29B 为 Rank-1 并行轮次（`cmd-20261111-120737-841-A1` 兑换面板遮挡修复）、本轮不代写其结论、不冒充已验 |
| **R29C 回归真跑**（Rank-3） | 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（`--version` = `4.7.2.stable.official.ed1daf0bf`、G0 `EXIT=0`）· `--path F:/Game/aierdengfahuan/godot`，**一次一个引擎进程、串行 12 次**：G1 `--headless --import` / G2 `--headless --check-only --script` ×6（verify_tutorial_flags_v060 / save_delta_writer.gd / hud.gd / r19_verify_hud.gd / verify_hud_binding.gd / r22_save_e2e.gd）/ G3 `--headless --quit` 三段门禁 + 回归 A `--headless --script r19_verify_hud.gd` + 回归 B `--headless --script verify_hud_binding.gd` + TFV selftest `--headless --script verify_tutorial_flags_v060.gd`，**12 次调用全 `EXIT=0`**。**31 PASS / 0 FAIL 不回退**：`r19_verify_hud.gd` `SUMMARY pass=20 fail=0 ok=true` + `verify_hud_binding.gd` `SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true`（**首次即 11/0**）；`verify_tutorial_flags_v060.gd` selftest `SUMMARY phase=selftest pid=25924 pass=15 fail=0 ok=true` / `RESULT=ALL_PASS`（**本轮只跑 selftest 一态，未跑 write/read 两独立进程三态，如实登记、不冒充 R28 的 21 PASS 全流程**）。**三段门禁 `grep SCRIPT ERROR=0` 达成**：12 份 `R29C-*.log` 逐份 `SCRIPT ERROR=0`、`Parse Error=0`、`ERROR:` 前缀 = 0（**本轮 G3 无 R29 那 4 条 `ERROR:` 前缀残留**，Rank-1 并发面板迁移已稳定；G3 仅 1 条既有 `2 ObjectDB instances were leaked at exit` WARNING、如实保留、非 ERROR）。日志留档 `teamwork/Rank-3/R29C-*.log`（12 份，均为实际 stdout）。G3 日志另见 `[R29][DEPTH] 参数表已读取 … 总命中=20` 真读路径生效（Rank-2 / Rank-4 并发产出，Rank-3 未写、未改、未代验） |
| **v0.8.0 赐福图鉴 · 成就系统**（R30 派单 · Rank-3 完善旧内容：A34 残留清除 + 图鉴 GDD 章节） | **A34 残留 1**：`WAVE-TRIAL-GDD.md` §10.8 新 flag 表 `grace.tutorial.completed` 行「写方 Rank-3」就地统一为 A26 落地口径（写方 Rank-1 `tutorial_director.gd` / reason `tutorial_completed`、每步 `tutorial_step_reward` / 教学 HUD 读运行时游标 / 世界 flag 只作历史进度）并补 R30 说明段；`00-协作契约.md` §3.3 登记表 `completed` 行（R29C / A31 已统一）核对一致、无需再改、补 R30 说明段；逐处改前→改后见 `DONE-R30.md`、不改动其它历史条款。**A34 残留 2**：`HD2D-STYLE-ANCHOR-v2.md` §8.4 补齐派生显示色**四要素**（来源锚点 hex + 可复算派生公式含中间计算 + 结果 hex + rationale），明确 `#2B3A5C` / `#F0A94C` 为 `palette_256.json` 32 色板灰阶档 L3(28%)/L7(85%) 历史显示色，给出「锚点色 → 灰阶插值 / 亮度提升 → 结果色」逐通道 Δ 公式与「冻结档不可由相邻档线性插值生成」反证，声明**不是 v2 新色板 / 不并入 §5.2 16 色受控表 / uniform 真源仍是 `depth_profile.tres` 锚点色**。**新写 `teamwork/Rank-3/CODEX-GDD.md`**：Game Designer 六项齐全（purpose / player experience goal / inputs / outputs / edge cases / failure states）+ 「收集」留存钩子（第五条、既有四条不回退）+ 「教学→三波→成长」四层目标梯度衔接表（4 项成就 ↔ 4 个既有持久化 flag）+ 三段连续奖励节奏与不惩罚原则 + `[PLACEHOLDER]` 数值引用表；**所有数值引用 Rank-2 `[PLACEHOLDER]` 表、不另造数值**（Rank-2 `CODEX-TUNING.md` / `codex_config.gd` / `codex_entries.tres` 于 12:55~12:59 落盘、13:01:35 done，本 GDD 已按落地表校对引用键名 / 数值 / 语义并逐项一致，见 `CODEX-GDD.md` §11 C-V1）。Rank-3 本轮**未写任何 `godot/` 工程业务文件**，运行时 / 数据表 / Tab 面板 / 演示序列归 Rank-1 / Rank-2 并发写入、不代验、不宣称完成 |
| **R30 回归真跑**（Rank-3） | 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（`--version` = `4.7.2.stable.official.ed1daf0bf`、G0 `EXIT=0`）· `--path F:/Game/aierdengfahuan/godot`，**一次一个引擎进程、串行 12 次**：G1 `--headless --import` / G2 `--headless --check-only --script` ×6（verify_tutorial_flags_v060 / save_delta_writer.gd / hud.gd / r19_verify_hud.gd / verify_hud_binding.gd / r22_save_e2e.gd）/ G3 `--headless --quit` 三段门禁 + 回归 A `--headless --script r19_verify_hud.gd` + 回归 B `--headless --script verify_hud_binding.gd` + TFV selftest `--headless --script verify_tutorial_flags_v060.gd`，**12 次调用全 `EXIT=0`**。**31 PASS / 0 FAIL 不回退**：`r19_verify_hud.gd` `SUMMARY pass=20 fail=0 ok=true` + `verify_hud_binding.gd` `SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true`（**首次即 11/0，无并发 9/2 抖动**）；`verify_tutorial_flags_v060.gd` selftest `SUMMARY phase=selftest pid=25516 pass=15 fail=0 ok=true` / `RESULT=ALL_PASS`（**本轮只跑 selftest 一态，未跑 write/read 两独立进程三态，如实登记、不冒充 21 PASS 全流程**）。**三段门禁 `grep SCRIPT ERROR=0` 达成**：12 份 `R30-*.log` 逐份 `SCRIPT ERROR=0`、`Parse Error=0`、`ERROR:` 前缀 = 0；G3 仅 1 条既有 `2 ObjectDB instances were leaked at exit` WARNING、如实保留非 ERROR。日志留档 `teamwork/Rank-3/R30-*.log`（12 份，均为实际 stdout）。`--script` 模式未用 `/root/...` 绝对路径、未新建探针 / 巡检脚本 |

### R22 存档端到端真跑结论（补 R21 §3.2 明确未做项）

用既有 `SaveDeltaWriter.commit(reason)` / `world_state.gd._load()` / `save_delta.gd` 十字段口径，**两个独立 Godot 进程**完成完整回放：

```
[写盘进程]  E2E_PHASE=write ... --script r22_save_e2e.gd   → SUMMARY phase=write pid=30324 pass=7 fail=0 ok=true
[重启进程]  E2E_PHASE=read  ... --script r22_save_e2e.gd   → SUMMARY phase=read  pid=38396 pass=9 fail=0 ok=true
```

- 两阶段 **pid 不同**（30324 / 38396）= 真正重启引擎进程，非同进程内内存往返。
- 写盘：经 `set_flag` 注入 5 个三段式 flag → `SaveDeltaWriter.commit("r22_e2e_write")` → 真实原子写 `user://saves/slot_01/delta.json`（932 字节）。
- 读回：新进程 `_ready()` 后内存为基线（`get_flag(...,false)=false`，未读档）→ 调既有 `_load()` 回放 → `get_flag` 逐项读回 **5/5 一致**。
- 校验：**十字段齐全且无额外顶层字段**、`schema_version=3`、`slot=slot_01`、5 个 flag 全通过三段式正则、`meta.last_commit_reason=r22_e2e_write` 跨进程一致。
- 合计 **16 PASS / 0 FAIL**；stdout 证据留档 `teamwork/Rank-3/R22-E2E-write.log` / `R22-E2E-read.log`。

---

## 二、还差什么

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| 1 | ComfyUI 正式 spritesheet 主美术路线接入 | 长期项 · 未解决 | 当前为本地零付费出图 + 程序化 `_draw()` 占位兜底；ComfyUI 仍是主路线（历轮 DONE 一贯口径），不宣称已能出图 |
| 2 | 真正 HDR bloom / 3D 体积光 / SSR | 长期项 · 未达成 | 四项光效为 2D 程序化 `draw_*` 几何 / 加色近似；`gl_compatibility` 后端不支持原生 3D 后处理，不夸大 |
| 3 | 赐福菜单 UI 画面 / 运行期人工试玩验收 | 未做 · 不阻塞 | `hud.tscn` 仍为 `HudPanel` + `TitleLabel`，菜单以 `Array[Dictionary]` 数据快照供 UI 消费；画面 / 人工试玩不在本单范围 |
| 4 | 15–20 秒实机录屏并目视回看 | R22 · A4 另单在办 | 本单（A3）不代做、不谎报；godogen 交付纪律由 Rank-4 R22 承担 |
| 5 | 既有退出 WARNING | 如实保留 · 非 ERROR | `[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`，历轮已登记，R22 真跑中仍出现，未隐藏、未宣称零 WARNING |
| 6 | 历史待裁决 / 登记项 | 只登记不擅改 | A8（契约两段式示例 vs 严格三段式）、`chunk.<id>.loaded` 归一口径、6 条 `res://scenes/*` 未实机换场景、`chunk_origin` 全 0 —— 交 HOST 裁决 |
| 7 | 多槽存档 UI / 玩家精确坐标进存档 | 按规范不做 | 规范冻结单槽 `slot_01`、复活锚点以 `meta.last_grace_id` 表达，非缺陷 |
| 8 | `project.godot` | 工程冻结 | 本轮四路均不写，保证录屏对应稳定工程、产物无需重导 |
| 9 | **`project.godot` 的 `run/main_scene` 仍指向 `scenes/Main.tscn` 骨架** | **v0.2.0 明确缺口 · 未解决** | 实测 `godot/project.godot:37` 为 `run/main_scene="res://scenes/Main.tscn"`（`Main.tscn` 3,393 B 骨架）；**完整画面目前只在 `godot/scenes/courtyard.tscn` 与 `encounter_v010.tscn` 等独立场景中可跑**（须 F5 指定场景 / `--quit-after <N> res://scenes/...`），从工程默认入口启动**看不到庭院与 Boss**。**改 `main_scene` 属 v0.3.0**，本轮四路均不写 `project.godot`（工程冻结 / 并发保护）；v0.2.0 的「主场景接线」仅指把 `EncounterRoot` 接进 `courtyard.tscn`，**不粉饰为默认入口已接通**。R25 裁决 A16 已定「改指 `courtyard.tscn`、`Main.tscn` 保留不删」，但写入归 Rank-1 工程侧，Rank-3 不代做 |
| 10 | **人工试玩（exe / apk）与手感 / 审美验收**（裁决 A17） | **属用户侧 · 本轮不代做、不冒充完成** | 总指挥裁决 A17：人工试玩属用户侧，本轮只给**勾选清单**（翻滚无敌帧手感 / Boss 招式公平性 / 区域密度 / 画面可见性 / 默认入口庭院与 Boss 是否可见），不冒充完成；headless 真跑无真实帧缓冲，手感与审美判断 WorkBuddy 不替人做 |
| 11 | **`128bit` 词义歧义**（裁决 A15 保留） | **待用户确认 · 未消歧** | A15 把色数口径统一为「项目级色库 ≥256 色 / 单帧 ≤16 色索引 / RGBA 保 alpha / 128px 基准画布」，但用户原文 `128bit` 究竟指「128px 画布尺寸」还是「位宽 / 色深」**仍显式保留、不消歧、不编码进任何期望值**，以用户后续确认为准；契约 §9.3 与 `00-汇总.md` §6.2 第 5 项均已登记 |
| 12 | **HD-2D 全绿未达**（R24 总指挥目视回看实证） | **未达成 · 长期项** | 战斗 HUD 已进庭院但 **Boss 无可见像素形象**、战斗数值 15 秒整段停在 `idle 0/0`（录屏无输入注入）、地面平铺重复与 R23 素材马赛克观感仍在、景深 / 光效仍是 2D `_draw()` 近似（非真 HDR bloom / 3D 体积光 / SSR）；A15 的「单帧 ≤16 色索引」受控色板是为消除马赛克观感的口径准备，**素材重绘归 Rank-4、本轮未落地** |
| 13 | **v0.4.0 波次数值 `[PLACEHOLDER]` 待人工试玩校准 / `WAVE-TRIAL-TUNING.md` 待落地校对** | **未达 · 待 Rank-2 并发产出 + 用户侧试玩** | Rank-3 `WAVE-TRIAL-GDD.md` 全部数值引用 Rank-2 `WAVE-TRIAL-TUNING.md` 的 `[PLACEHOLDER]` 表、不另造数值；Rank-3 产出时该表属 Rank-2 并发产出**尚未落地**，GDD 采用字段名引用式占位，待其落地后校对键名 / rationale / broken 定义一致性（不一致改 GDD 引用段、不改数据表）；倍率 / 奖励 / 预告 / 时限具体值须由人工试玩校准，headless 真跑不做手感判断，Rank-3 不代做、不冒充完成 |
| 14 | **v0.5.0 赐福成长：`GRACE-UPGRADE-TUNING.md` / `grace_upgrade_config.gd` 待落地校对、`<id>` 三段式收敛口径待裁决、`[PLACEHOLDER]` 数值待人工试玩校准、永久增益运行时效果待接通** | **未达 · 待 Rank-2 并发产出 + 总指挥裁决 + 用户侧试玩** | Rank-3 `WAVE-TRIAL-GDD.md` §9 / `WAVE-TRIAL-SPATIAL.md` 全部新数值引用 Rank-2 本轮 `GRACE-UPGRADE-TUNING.md` `[PLACEHOLDER]` 表、不另造数值；Rank-3 产出时该表与 `grace_upgrade_config.gd` / `grace_upgrades.tres` / `grace_upgrade_service.gd` 属 Rank-2 并发产出**尚未落地**，采用字段名引用式占位，待落地后校对 `id` 实际取值 / 引用键名 / rationale / broken 定义（不一致改 GDD 引用段、不改数据表）；任务单四段字面 `grace.upgrade.<id>.unlocked` 与 §3.1 三段式正则冲突，Rank-3 收敛为 `grace.upgrade_<id>.unlocked` 并**列为待总指挥裁决**（不伪造、不擅自改 `world_state.gd`）；`cost` / `effect_value` 具体值须由人工试玩校准；永久增益作用到运行时（HP / 翻滚无敌 / 攻击力）、`effect_key` 落点核对与空间 blockout / 环境叙事视觉落地归 Rank-2 / Rank-4 / 用户侧，Rank-3 不代做、不冒充完成 |
| 15 | **v0.6.0 赐福引导：`tutorial_config.gd` / `tutorial_steps.tres` 待落地校对引用键名、`[PLACEHOLDER]` 数值待人工试玩校准、教学 HUD / 点亮态 / 第 1 波衔接运行时接线、`step_index` 单调 vs T 重开「进度归零」口径待裁决** | **未达 · 待 Rank-2 并发产出 + Rank-1 接线 + 总指挥裁决 + 用户侧试玩** | Rank-3 `WAVE-TRIAL-GDD.md` §10 / `TUTORIAL-BLOCKOUT.md` 全部新数值引用 Rank-2 `[PLACEHOLDER]` 表、不另造数值；Rank-3 产出时本轮 `tutorial_config.gd` / `tutorial_steps.tres` 及教学 `[PLACEHOLDER]` 表属 Rank-2 并发产出**尚未落地**，采用字段名引用式占位，待落地后校对 `step_id / prompt / expected_action / reward_points / timeout_sec` 实际取值 / 教学与波次 `reward_points` 同名不同语义域 / rationale / broken 定义（不一致改 GDD 引用段、不改数据表）；教学 HUD 金色引导行避开五套占位、赐福点亮态读 flag、跳过门控、`COMPLETED` 自动进第 1 波、T 重开、演示序列兼容归 Rank-1 运行时接线，Rank-3 不代验、不宣称已接通；任务单「按 T 重开教学」与 `grace.tutorial.step_index` 登记为单调递增的持久化口径存在语义差异，Rank-3 按 §4.4「quest_stages 取较大值」落地并**列为待总指挥裁决**（不擅自改 `world_state.gd` 正则）；`reward_points` / `timeout_sec` / `cost` 具体值须由人工试玩校准，headless 真跑不做手感判断，Rank-3 不代做、不冒充完成 |
| 16 | **v0.7.0 风格锚点 v2：`[PLACEHOLDER]` 数值待人工试玩校准、景深强化层（Rank-2）/ HUD 景深呈现（Rank-1）/ 全屏 shader 小样与 15~20 秒录屏目视（Rank-4）未代验、HD-2D 全绿仍未达、残留口径差异（A31 统一两处 / R30·A34 已清除 GDD §10.8 `completed` 行）与 shader 派生色公式（R30·A34 §8.4 已补四要素）**均已清除 / 补齐** | **未达 · 待 Rank-1 / Rank-2 / Rank-4 并发产出 + 用户侧试玩 + 总指挥裁决** | `HD2D-STYLE-ANCHOR-v2.md` 的层数 / 远景冷雾 alpha / 暗角强度 / bloom 半径与 alpha / 三波雾带色号共 5 组 `[PLACEHOLDER]` 均写 rationale、待实录屏目视与人工试玩校准，Rank-3 不代做手感 / 审美判断、未写进任何工程代码；三条硬判据中 J1（缩略图 10% 剪影可读）及暗角 / 光晕 / 三波色带的画面观感须靠 Rank-4 录屏目视与用户试玩，Rank-3 只能静态查表判 J2 / J3 / J5 / J6、**不宣称 HD-2D 全绿**；A30 裁决不切后端、不做真 3D 光效，v2 §3 差距清单如实登记「2D 近似 vs 真 3D」为已知差距，第 2 项（真 HDR bloom / 3D 体积光 / SSR）与第 12 项保持未达；Rank-2 `depth_profile.tres` / `verify_depth_profile_v070.gd`、Rank-1 `verify_hud_depth_v070.gd`、Rank-4 全屏 shader 与录屏均属并发产出、Rank-3 不代验；A28 按任务单只统一契约 §3.3 / GDD §10.8 / README，**R29 曾把 GDD §10.6 事件输入表「Rank-3 订阅信号写 / Rank-1 不写 flag」等 §10.8 之外历史条款保留未动并如实登记交裁决（见 `DONE-R29.md`）**；**R29C / 裁决 A31 已把其中两处（GDD 行 492、契约 §3.3 `completed` 行写方）统一到 A26 落地口径**（写方 Rank-1 `tutorial_director.gd` / reason `tutorial_step_reward` / 教学 HUD 读运行时游标 / 世界 flag 只作历史进度，逐处改前→改后见 `DONE-R29C.md`），GDD §10.8 的 `grace.tutorial.completed` 行**已由 R30 / A34 统一为 A26 落地口径**（写方 Rank-1 `tutorial_director.gd` / reason `tutorial_completed` / 世界 flag 只作历史进度），残留口径差异**已清除**、不再交裁决；**A32 派生色**：`HD2D-STYLE-ANCHOR-v2.md` §8 已钉死 uniform 真源为 `depth_profile.tres` 锚点色、登记派生显示色来源；**R30 / A34 已在 §8.4 补齐四要素**（来源锚点 hex + 可复算派生公式含中间计算 + 结果 hex + rationale），明确 `#2B3A5C` / `#F0A94C` 为 `palette_256.json` 32 色板灰阶档 L3(28%)/L7(85%) 历史显示色，**不是 v2 新色板 / 不并入 §5.2 16 色受控表 / uniform 真源仍是 `depth_profile.tres` 锚点色**；按「历史显示色、非 v2 色板成员」登记，不得冒充新色板 |
| 17 | **v0.8.0 赐福图鉴：`[PLACEHOLDER]` 数值待人工试玩校准、Rank-1 `codex_director.gd` / Tab 面板 / `presentation.gd` 演示序列运行时接线与 `verify_codex_v080.gd` / `verify_codex_reward_v080.gd` 未代验、HD-2D 全绿仍未达** | **未达 · 待 Rank-1 并发产出 + 用户侧试玩** | `teamwork/Rank-3/CODEX-GDD.md` 全部新数值引用 Rank-2 `[PLACEHOLDER]` 表、不另造数值（Rank-2 `CODEX-TUNING.md` / `codex_config.gd` / `codex_entries.tres` 于 12:55~12:59 落盘、13:01:35 done；`CODEX-GDD.md` §11 C-V1 **已按落地表逐项校对** `id / title / description / condition_kind / condition_value / reward_points` / `reward_points` 30<50<80<120 合计 280 / `condition_kind` 三态 / B1~B4 broken 定义并**逐项一致**，§10 已改列为落地表引用；不一致改 GDD 引用段、不改数据表）；`reward_points` 30/50/80/120 具体值须由人工试玩校准；4 项成就与 4 个订阅 flag 的 `condition_kind` 对齐、`grace.codex_<id>.unlocked` 单向 / `commit("codex_unlocked")` 先落盘 / 重复领取拒绝 / 余额非负归 Rank-1 / Rank-2 校验脚本，Tab 面板安全区 / 不遮角色 / 15 秒演示序列注入一次 Tab / 15~20 秒录屏目视归 Rank-1 / Rank-4 / 用户侧，Rank-3 不代验、不宣称已接通；headless 真跑不做手感 / 审美判断，Rank-3 不代做、不冒充完成 |

> **v0.4.0（R26）复核「还差什么」**：第 **10 项人工试玩（exe / apk 手感 / 审美验收，裁决 A17）**、第 **11 项 `128bit` 词义歧义（待用户确认、A15 不消歧）**、第 **12 项 HD-2D 全绿未达（Boss 无可见像素形象 / 战斗数值停摆 / 地面平铺与马赛克 / 光效 2D 近似）** 三项在 v0.4.0 **仍未达**，本轮 Rank-3 均未代做、未宣称完成；新增第 13 项为 v0.4.0 特有的数值校准 / 并发表落地校对缺口。
>
> **v0.5.0（R27）复核「还差什么」**：第 **10 项人工试玩（exe / apk 手感 / 审美验收，裁决 A17）**、第 **11 项 `128bit` 词义歧义（待用户确认、A15 不消歧）**、第 **12 项 HD-2D 全绿未达（Boss 无可见像素形象 / 战斗数值停摆 / 地面平铺与马赛克 / 光效 2D 近似）** 在 v0.5.0 **仍未达**，本轮 Rank-3 均未代做、未宣称完成；第 **13 项**（v0.4.0 波次数值校准）中 `WAVE-TRIAL-TUNING.md` **已于 R26 后落地**，「待落地校对」部分可推进，但倍率 / 奖励 / 时限具体值仍待人工试玩校准、Rank-3 不代做；新增第 14 项为 v0.5.0 特有的成长数值校准 / 并发表落地校对 / `<id>` 收敛裁决 / 运行时效果接通缺口。
>
> **v0.6.0（R28）复核「还差什么」**：第 **10 项人工试玩（exe / apk 手感 / 审美验收，裁决 A17）**、第 **11 项 `128bit` 词义歧义（待用户确认、A15 不消歧）**、第 **12 项 HD-2D 全绿未达（Boss 无可见像素形象 / 战斗数值停摆 / 地面平铺与马赛克 / 光效 2D 近似）** 在 v0.6.0 **仍未达**，本轮 Rank-3 均未代做、未宣称完成；第 **13 项**（v0.4.0 波次数值校准）中 `WAVE-TRIAL-TUNING.md` 已落地、可推进引用键名校对，倍率 / 奖励 / 时限具体值仍待人工试玩校准；第 **14 项**（v0.5.0 成长数值校准 / `<id>` 收敛裁决 / 运行时效果接通）中 `GRACE-UPGRADE-TUNING.md` 已落地、可推进引用键名校对，`<id>` 收敛裁决 / 永久增益运行时效果接通 / 数值校准仍未达；新增第 15 项为 v0.6.0 特有的教学表落地校对 / 教学数值校准 / 教学 HUD·点亮态·衔接接线 / `step_index` 单调 vs T 重开口径裁决缺口。
> **v0.7.0（R29）复核「还差什么」**：第 **10 项人工试玩（exe / apk 手感 / 审美验收，裁决 A17）**、第 **11 项 `128bit` 词义歧义（待用户确认、A15 不消歧）**、第 **12 项 HD-2D 全绿未达**（含第 2 项真 HDR bloom / 3D 体积光 / SSR）在 v0.7.0 **仍未达** —— 裁决 A30 明确不切渲染后端、不做真 3D 光效，`HD2D-STYLE-ANCHOR-v2.md` §3 差距清单把「2D 近似 vs 真 3D」如实登记为已知差距，本轮 Rank-3 均未代做、未宣称完成；第 **13 项**（v0.4.0 波次数值校准）/ **14 项**（v0.5.0 成长数值校准 / `<id>` 收敛裁决 / 永久增益运行时效果接通）仍未达；第 **15 项**中「`step_index` 单调 vs T 重开『进度归零』口径待裁决」**已由裁决 A26 落地、按 A28 全文统一**（世界 flag 只作历史进度 / 教学 HUD 读运行时游标 / 写方 Rank-1 `tutorial_director.gd` / reason `tutorial_step_reward`），**不再待裁决**，该第 15 项剩余缺口（教学表落地校对 / 教学数值校准 / 教学 HUD·点亮态·衔接接线）仍未达；新增第 16 项为 v0.7.0 特有的风格锚点 v2 `[PLACEHOLDER]` 数值待试玩校准 / 景深强化层·HUD·全屏 shader 与录屏未代验 / §10.8 之外残留口径差异待裁决缺口。
>
> **R29C（v0.7.1）复核「还差什么」**：第 **10 项人工试玩（exe / apk 手感 / 审美验收，裁决 A17）**、第 **11 项 `128bit` 歧义（待用户确认、A15 不消歧）**、第 **12 项 HD-2D 全绿未达**（含第 2 项真 HDR bloom / 3D 体积光 / SSR）在 R29C **仍未达**；第 **13 项**（v0.4.0 波次数值校准）/ **14 项**（v0.5.0 成长数值校准 / `<id>` 收敛裁决 / 永久增益运行时效果接通）/ **15 项**（教学表落地校对 / 教学数值校准 / 教学 HUD·点亮态·衔接接线；其中「`step_index` 单调 vs T 重开『进度归零』口径待裁决」已由 A26 落地、A28 统一、不再待裁决）仍未达；第 **16 项**中「§10.8 之外残留口径差异待裁决」**已由裁决 A31 统一两处**（GDD 行 492 / 契约 §3.3 `completed` 行 → A26 落地口径，见 `DONE-R29C.md`），该第 16 项剩余缺口（v2 `[PLACEHOLDER]` 校准 / Rank-1·2·4 并发产出未代验 / HD-2D 全绿未达）仍未达；**A31 新残留如实登记**：GDD §10.8 的 `grace.tutorial.completed` 行仍为 R28 登记「写方 Rank-3 订阅三步全完成信号」，不属任务单 ① 授权清单、按「不改动其它历史条款」保留未动，与契约 §3.3 已统一的 `completed` 行存在**新的残留口径差异**，交总指挥裁决是否后续扩大统一；**A32 派生色待补**：shader 派生显示色 `#2B3A5C` / `#F0A94C` 缺「由锚点 `#1B2A4A` / `#C99A3A` 经何种公式派生」的规范公式，按 `HD2D-STYLE-ANCHOR-v2.md` §8.4 待 Rank-4 补四要素并交裁决，在此之前按「历史显示色、非 v2 色板成员」如实登记。
>
> **v0.8.0（R30）复核「还差什么」**：第 **10 项人工试玩（exe / apk 手感 / 审美验收，裁决 A17）**、第 **11 项 `128bit` 歧义（待用户确认、A15 不消歧）**、第 **12 项 HD-2D 全绿未达**（含第 2 项真 HDR bloom / 3D 体积光 / SSR）在 v0.8.0 **仍未达**，Rank-3 均未代做、未宣称完成；第 **13 项**（v0.4.0 波次数值校准）/ **14 项**（v0.5.0 成长数值校准 / `<id>` 收敛裁决 / 永久增益运行时效果接通）/ **15 项**（教学表落地校对 / 教学数值校准 / 教学 HUD·点亮态·衔接接线）仍未达；第 **16 项**中「§10.8 之外残留口径差异待裁决」**已由 R30 / A34 清除最后一处**（GDD §10.8 `grace.tutorial.completed` 行 → A26 落地口径，契约 §3.3 对应行核对已一致），「A32 派生色公式待补」**已由 R30 / A34 在 §8.4 补齐四要素**、不再待补；该第 16 项剩余缺口（v2 `[PLACEHOLDER]` 校准 / Rank-1·2·4 并发产出未代验 / HD-2D 全绿未达）仍未达。新增 **第 17 项**为 v0.8.0 图鉴特有的 `[PLACEHOLDER]` 数值校准 / Rank-1 运行时接线·Tab 面板·演示序列未代验缺口（Rank-2 表已落地、`CODEX-GDD.md` §11 C-V1 引用键名校对**已完成**）；本轮 Rank-3 只写自有文档 / GDD §10.8 / 契约 §3.3 / 锚点 §8.4 / README，**未写任何 `godot/` 工程业务文件**、未自行 git。
>
> 存档端到端真跑在 R21 §3.2 曾登记为「按公共契约不新建只读探针 / 巡检脚本，未冒充本轮重跑」；
> **R22 本单已补齐**（用本单验证载体 `teamwork/Rank-3/r22_save_e2e.gd`，非只读探针、非进度巡检脚本），故不再列为未完成项。

---

## 三、资产清单表（依据实际落盘文件，字节数为 `stat -c %s` 实测）

### 3.1 类别汇总

| 类别 | 实际落盘文件（路径相对工程根） | 文件数 | 字节数合计 | 中枢 done 轮次 |
|---|---|:--:|--:|---|
| I-5 玩家 **base 8 帧** PNG | `godot/assets/generated/chars/player_*.png`（8 动作） | 8 | **70,598** | R21B（冻结最终态） |
| I-5 玩家 **decor 8 帧** PNG | `godot/assets/generated/decor/player_decor_*.png` | 8 | **11,505** | R21B（冻结最终态） |
| I-5 Boss **base 3 招** PNG | `godot/assets/generated/boss/boss_{dagger_slash,holy_hammer,staff_slam}.png` | 3 | **32,269** | R21B（冻结最终态） |
| I-5 Boss **decor 3 招** PNG | `godot/assets/generated/boss/boss_decor_*.png` | 3 | **16,379** | R21B（冻结最终态） |
| 四类 PNG 合表 spritesheet | `chars/player_spritesheet.png`、`decor/player_decor_spritesheet.png`、`boss/boss_spritesheet.png`、`boss/boss_decor_spritesheet.png` | 4 | **118,363** | R21B（冻结最终态） |
| SpriteFrames | `chars/player_spriteframes.tres`、`boss/boss_spriteframes.tres` | 2 | **3,129** | R21B（冻结最终态） |
| player / boss 角色场景 | `godot/scenes/player.tscn`、`godot/scenes/boss_01_margit.tscn` | 2 | **735** | R21B（冻结最终态） |
| courtyard 主场景 | `godot/scenes/courtyard.tscn`（`grep -c '^\[node '` 实测 **25 节点**） | 1 | **6,406** | R20B → R21B |
| hd2d_fx 光效 | `godot/scenes/hd2d_fx.tscn` + `godot/scripts/hd2d_fx.gd` | 2 | **20,917** | R16 → R18 → R21B |
| hud | `godot/scenes/hud.tscn` + `godot/scripts/hud.gd` | 2 | **24,468** | R16 → R19 → R21 → R21B |
| quality_settings | `godot/scenes/quality_settings.tscn` + `godot/scripts/quality_settings.gd` | 2 | **13,181** | R20 → R21 → R21B |
| save_delta_writer / 存档三件 | `godot/scripts/save_delta_writer.gd` + `scripts/rpg/world_state.gd` + `scripts/rpg/save_delta.gd` | 3 | **30,958** | R20 → R21 → **R22**（本单端到端真跑） |
| 产物 exe | `build/Aierdengfahuan.exe` | 1 | **109,127,680** | **R21B**（重导） |
| 产物 pck | `build/Aierdengfahuan.pck` | 1 | **993,736** | **R21B**（重导） |
| 产物 apk | `build/Aierdengfahuan.apk` | 1 | **29,239,499** | **R21B**（重导） |
| 产物 idsig | `build/Aierdengfahuan.apk.idsig` | 1 | **234,930** | **R21B**（重导） |

### 3.2 I-5 四类 PNG 逐文件字节数明细

| 类 | 文件（相对 `godot/assets/generated/`） | 字节 |
|---|---|--:|
| 玩家 base | `chars/player_attack_heavy.png` | 9,220 |
| 玩家 base | `chars/player_attack_light.png` | 5,190 |
| 玩家 base | `chars/player_death.png` | 5,425 |
| 玩家 base | `chars/player_hitstun.png` | 9,081 |
| 玩家 base | `chars/player_idle_rgba.png` | 15,019 |
| 玩家 base | `chars/player_roll.png` | 8,044 |
| 玩家 base | `chars/player_run.png` | 11,115 |
| 玩家 base | `chars/player_walk.png` | 7,504 |
| 玩家 base 变体 | `chars/player_idle_single.png`（idle 另一变体，不计入 8 动作） | 8,345 |
| 玩家 decor | `decor/player_decor_attack_heavy.png` | 1,037 |
| 玩家 decor | `decor/player_decor_attack_light.png` | 1,324 |
| 玩家 decor | `decor/player_decor_death.png` | 1,691 |
| 玩家 decor | `decor/player_decor_hitstun.png` | 339 |
| 玩家 decor | `decor/player_decor_idle.png` | 1,414 |
| 玩家 decor | `decor/player_decor_roll.png` | 1,863 |
| 玩家 decor | `decor/player_decor_run.png` | 2,015 |
| 玩家 decor | `decor/player_decor_walk.png` | 1,822 |
| Boss base | `boss/boss_dagger_slash.png` | 12,672 |
| Boss base | `boss/boss_holy_hammer.png` | 10,352 |
| Boss base | `boss/boss_staff_slam.png` | 9,245 |
| Boss decor | `boss/boss_decor_dagger_slash.png` | 6,485 |
| Boss decor | `boss/boss_decor_holy_hammer.png` | 3,314 |
| Boss decor | `boss/boss_decor_staff_slam.png` | 6,580 |

### 3.3 场景 / 脚本 / 产物逐文件字节数明细

| 文件（相对工程根） | 字节 |
|---|--:|
| `godot/assets/generated/chars/player_spriteframes.tres` | 2,183 |
| `godot/assets/generated/boss/boss_spriteframes.tres` | 946 |
| `godot/assets/generated/chars/player_spritesheet.png` | 59,147 |
| `godot/assets/generated/decor/player_decor_spritesheet.png` | 11,086 |
| `godot/assets/generated/boss/boss_spritesheet.png` | 31,250 |
| `godot/assets/generated/boss/boss_decor_spritesheet.png` | 16,880 |
| `godot/scenes/player.tscn` | 360 |
| `godot/scenes/boss_01_margit.tscn` | 375 |
| `godot/scenes/courtyard.tscn` | 6,406 |
| `godot/scenes/hd2d_fx.tscn` | 1,031 |
| `godot/scenes/hud.tscn` | 914 |
| `godot/scenes/quality_settings.tscn` | 2,309 |
| `godot/scripts/hd2d_fx.gd` | 19,886 |
| `godot/scripts/hud.gd` | 23,554 |
| `godot/scripts/quality_settings.gd` | 10,872 |
| `godot/scripts/save_delta_writer.gd` | 4,378 |
| `godot/scripts/rpg/world_state.gd` | 15,353 |
| `godot/scripts/rpg/save_delta.gd` | 11,227 |
| `build/Aierdengfahuan.exe` | 109,127,680 |
| `build/Aierdengfahuan.pck` | 993,736 |
| `build/Aierdengfahuan.apk` | 29,239,499 |
| `build/Aierdengfahuan.apk.idsig` | 234,930 |

> 核算：玩家 base 8 动作 = 70,598 B；decor 8 帧 = 11,505 B；Boss base 3 招 = 32,269 B；Boss decor 3 招 = 16,379 B；
> 四张合表 = 59,147 + 11,086 + 31,250 + 16,880 = **118,363 B**；SpriteFrames = 2,183 + 946 = **3,129 B**；
> 角色场景 = 360 + 375 = **735 B**；hd2d_fx = 1,031 + 19,886 = **20,917 B**；hud = 914 + 23,554 = **24,468 B**；
> quality_settings = 2,309 + 10,872 = **13,181 B**；存档三件 = 4,378 + 15,353 + 11,227 = **30,958 B**。
> `player_spriteframes.tres` 实测注册 **8 个动作**（attack_heavy / attack_light / death / hitstun / idle / roll / run / walk），与「玩家 base 8 帧」口径吻合；
> `boss_spriteframes.tres` 对应 3 招。`courtyard.tscn` 的 25 节点为 `grep -c '^\[node '` 实测值。

---

### 3.4 R23 素材条目与本机可选素材源合规登记（2026-11-09 · 口径 / 合规登记，非落盘产物）

> 本小节为**规格口径与合规边界登记**，不代表本轮新增任何落盘素材文件：`godot/assets/generated/r23/` 归 Rank-4 所有，本轮未写、未生成 PNG、`stat` 实测字节数不适用。
> 依据：用户 R23 拍板口径「`128bit` + 256 色以上」与 DNF 合规边界；`teamwork/00-协作契约.md` §9.3（I-5 资产交付口径真源）、`teamwork/Rank-3/DNF-COMPLIANCE-R23.md`。

| 条目 | 来源 / 规格 | 落盘状态 | published_in_pck | 备注 |
|---|---|---|:--:|---|
| **R23 素材条目** | **本地 ComfyUI 自制**（零付费 / 零外部服务）｜**128px 基准画布**｜**≥256 色（256 色以上）**｜**RGBA / alpha 保留** | 口径登记，本轮未新增落盘素材 | **false** | `128bit` 词义歧义（128px 画布 / 位宽 / 色深）显式保留待用户确认；正式素材路线仍为本地 ComfyUI |
| **本机可选素材源：DNF NPK 仅参考** | DNF（`Neople` / 腾讯版权）NPK / 贴片，**仅本机开发期风格参考** | 参考目录，**不进工程素材链** | **false** | 参考目录以 `.gdignore` 标记，Godot 不扫描 / 不导入 / 不打包；不随仓库分发可识别商业贴片；不得进 `pck` / `exe` / `apk` |

**合规口径（`published_in_pck:false` 全覆盖）**：

- 上表两项均 **`published_in_pck: false`** —— 既不进 `.pck`，也不进 `.exe` / `.apk` 任何发布包；R23 素材条目是规格口径而非已发布资产，DNF NPK 是本机参考而非工程素材。
- **参考目录 `.gdignore`**：DNF 参考目录须以 `.gdignore` 标记，使 Godot 4.7.2 跳过该目录的文件系统扫描与资源导入，从机制上保证不被打进发布包；本轮不改素材目录，仅登记该约定（`.gdignore` 由素材目录所有方 Rank-4 按需落地）。
- 版权归 `Neople` / 腾讯；完整合规登记见 `teamwork/Rank-3/DNF-COMPLIANCE-R23.md`。

---

## 四、R32 / v0.10.0 状态表（追加段，历史行一律保留未动）

> 本段为 **R32 / cmd-20261112-074023-412-A3（Rank-3）** 追加；「一、已做了什么」/「二、还差什么」/「三、资产清单表」的所有历史行按「只追加、不改历史条款」保留未动，v0.10.0 增量以本段 + `teamwork/Rank-3/DONE-R32.md` 为准。零付费、零外部依赖、不启 GPU job。

### 4.1 v0.10.0 状态表

| 域 | 状态 | 说明 |
|---|---|---|
| 四个三段式 flag 登记 | ✅ 已落地（口径） | `grace.boon_draft.selected` / `.cost_applied` / `combat.boss_01.stagger_window` / `grace.execution.performed`，契约 §3.3 R32 段 + 存档与flag规范 §3.3 全局表；只作 `flags` 字典新 key、十字段冻结、`schema_version=3`、不写 `removals` |
| `verify_v100_save_readback.gd` | ✅ 通过（只读验证件） | 三进程三态 `57 PASS / 0 FAIL`、`all` 自检 `55 PASS / 0 FAIL`、三 pid 互不相同、生产 `slot_01` md5 前后一致；不改生产逻辑、不碰生产存档 |
| 迭代收口文档 | ✅ 已落地 | `teamwork/迭代-v0.10.0-赐福抉择与韧性处决.md`：拆解表 / P0~P2 / GDD 六项 / 三栏 / 架构 / 三态 / 回滚 / backlog |
| 裁决 A39~A45 | ✅ 已登记 | 契约 §3.3 R32 说明段同时登记，逐条如实（含 A41「未达全绿」、A43 不消歧、A45 `[PLACEHOLDER]`） |
| 三段门禁 `grep SCRIPT ERROR=0` | ✅ 通过 | 7 份 `R32-*.log` 逐份 `SCRIPT ERROR=0` / `Parse Error=0` / `ERROR:` 前缀 = 0；G3 回读 `node_count=41` |
| 抉择/处决/词条 `[PLACEHOLDER]` 校准（A45 / A17） | ⚠️ 需用户确认 | 用户侧人工试玩，Rank-3 不代做 |
| HD-2D 全绿（A41 三判据） | ❌ 未达 | 光效仍 2D `_draw()` / screen-reading shader 近似、地面 2D tile 贴 3D 平面、角色 billboard 像素精灵；不得据单路自评宣称全绿 |

### 4.2 资产表增量（R32 新增 / 改动文件，字节数为 `os.path.getsize` 实测，非编造）

| 文件（相对工程根） | 字节 | 类型 / 归属 |
|---|--:|---|
| `godot/scripts/rpg/verify_v100_save_readback.gd` | **26,410** | 新写只读验证脚本（本轮 Rank-3 唯一 `godot/` 新增文件，只读加载生产脚本、不改业务逻辑） |
| `teamwork/迭代-v0.10.0-赐福抉择与韧性处决.md` | **22,527** | 新写迭代收口文档（§10 backlog 禁词净化后定稿） |
| `teamwork/00-协作契约.md`（§3.3 追加 R32 段） | **56,767** | 只追加、历史条款未动 |
| `teamwork/Rank-3/存档与flag规范.md`（§3.3 追加 4 行 + 注记） | **36,167** | 只追加、历史条款未动 |
| `teamwork/Rank-3/R32-*.log`（9 份真跑 stdout：7 份主验证 + 2 份收尾复跑） | **29,001**（1,087+75+4,526+7,362+5,921+2,027+2,256+1,087+4,660） | 真跑日志留档；收尾 `R32-final-import/quit.log` 亦 `SCRIPT ERROR=0`、G3 回读 `node_count=41` |
| `README.md` / `teamwork/Rank-3/DONE-R32.md` / `DONE-R31B.md` / 两份回执 | —（不登记自指静态字节数） | 运行时状态文档 / 交付报告 / 回执：内容按「只追加」维护，字节数随段落追加变动，不做自指静态登记以免失真 |

> §3.1~§3.4 既有 I-5 素材 / 场景 / 脚本 / 产物实测字节数与「中枢 done 轮次」表（仍 R22 快照）一律未改；R32 未新增任何 I-5 素材 / 场景节点 / 导出产物，`courtyard.tscn` 节点 41 / uv 2/1/1 与 `presentation.gd` 只读。

### 4.3 「一、已做了什么」v0.10.0 增量（追加）

| 域 | 已落地 |
|---|---|
| **v0.10.0 赐福抉择 · 韧性处决**（R32 派单 · Rank-3 存档口径 / 玩法拆解 / 只读验证） | ① 契约 §3.3 + 存档与flag规范 §3.3 登记 4 个新三段式 flag（抉择 String/bool、处决窗口 bool、处决次数 int 单调只增）+ 裁决 A39~A45；② 新写 `godot/scripts/rpg/verify_v100_save_readback.gd` 三进程三态只读回读验证（`57 PASS / 0 FAIL`，独立 PID 临时槽、生产 `slot_01` md5 前后一致）；③ 新写 `teamwork/迭代-v0.10.0-赐福抉择与韧性处决.md`（game-development-pro 玩法拆解表 + P0/P1/P2 漏洞识别 + GDD 六项 + 三栏清单 + 节点与信号链架构 + 验收三态 + 风险回滚 + 零付费 backlog）；④ 工程根 `README.md` 追加 v0.10.0 状态段与本 §四；⑤ 真跑三段门禁 `grep SCRIPT ERROR=0`（7 份日志全 0、G3 回读 `node_count=41`）；⑥ 两份 DONE（`DONE-R32.md` / `DONE-R31B.md`）+ 两份回执（R32 本轮 + R31B 补）。**所有新数值标 `[PLACEHOLDER]` + rationale + 调参唯一入口（只改表不改代码），Rank-3 未写任何 `godot/` 业务代码、未改其它 Rank 产出、未自行 git（总指挥收尾）** |
| **R32 回归真跑**（Rank-3） | 三进程三态 `write 9 / load 6 / assert 42 = 57 PASS / 0 FAIL`、三 pid `22080 / 26888 / 26012` 互不相同；单进程 `all` `55 PASS / 0 FAIL`；G1 `--headless --import` / G2 `--check-only --script` / G3 `--headless --quit` 全 `EXIT=0`；7 份 `R32-*.log` 逐份 `SCRIPT ERROR=0` / `Parse Error=0` / `ERROR:` 前缀 = 0（三段门禁达成）；生产 `slot_01` md5 前后一致 `ea30335b3d1fd6c5a846e04a704d91dc`；`courtyard.tscn CACHE_MODE_IGNORE` 真跑回读 `node_count=41`（A38 断言保持）；既有 3 条退出 WARNING 如实保留、非 ERROR |

### 4.4 「二、还差什么」v0.10.0 增量（追加）

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| 18 | **v0.10.0 赐福抉择 / 韧性处决：`[PLACEHOLDER]` 数值待人工试玩校准、4 个新 flag 运行时写入接线（Rank-1 / Rank-2 并发）未代验、抉择面板安全区 / 处决窗口可读性 / 15~20 秒录屏目视（A42）未代判、HD-2D 全绿仍未达（A41）** | **未达 · 待用户侧试玩 + 其它 Rank 运行时接线 + 总指挥目视** | 三类新数值（试炼词条 / 赐福抉择 / 韧性处决）全部 `[PLACEHOLDER]`、rationale 与调参唯一入口见迭代文档 §2（A45）；`boon_draft.tres` / `stagger_rules.tres` / 编排服务 / `player_hit_landed` 命中信号 / HUD 面板归 Rank-1 / Rank-2 并发产出，Rank-3 只登记口径 + 只读验证脚本、不代验运行时接线；抉择面板不遮角色 / 处决窗口带形状差异（锚点 v2 J6）/ 15~20 秒录屏首中尾三帧归 Rank-4 与总指挥目视（A42），headless 无帧缓冲、Rank-3 不代做手感 / 审美判断；A41 以 `HD2D-STYLE-ANCHOR-v2.md` 三判据为准、如实记「未达全绿」，A30 不切后端；`128bit` 歧义（A43）继续保留待用户确认、不消歧 |

> **v0.10.0（R32）复核「还差什么」**：第 **10 项**（人工试玩，A17）/ **11 项**（`128bit` 歧义，A43 保留）/ **12 项**（HD-2D 全绿未达，A41 三判据）/ **2 项**（真 HDR bloom / 3D 体积光 / SSR）在 v0.10.0 **仍未达**；第 **13~17 项**（各版 `[PLACEHOLDER]` 校准 / 并发表落地校对 / 运行时接线）仍未达且本版第 18 项新增同类缺口；Rank-3 均未代做、未宣称完成。

### R33 实机可见性修复（2026-11-12 总指挥定稿）

- 修复 Tab 图鉴与赐福成长面板互斥的运行时根因（HUD 统一 Tab 仲裁），实机日志 frame=225 图鉴开→兑换隐藏、frame=449 关→恢复。
- 15 秒演示序列加入 Boss 韧性条 / 处决窗口读秒 / F 处决、赐福抉择三选一卡片 / 数字键选择；F / 数字键 / Tab 为真实按键注入，开窗与卡片属**演示驱动**，6 条生产运行时触发链仍待接线（见 `teamwork/Rank-1/DONE-R33.md`）。
- 总指挥亲自重跑定稿：`capture/v100_final.mp4` 450 帧 / 15.000s / 1,587,366 B；目视 5 帧确认新玩法可见、HUD 无重叠、暖金收束未过曝。
- 双产物重导：exe 109,178,880 B / pck 1,662,428 B / apk 30,206,569 B / idsig 243,122 B；apksigner v2/v3 true。
- **HD-2D 全绿仍未达成**（A41），地面周期重复感仍在；定稿录屏禁止加 `--headless`（A47）。

---

## 五、R34 / v0.11.0 状态表（追加段，历史行一律保留未动）

> 本段为 **R34 / cmd-20261112-091304-455-A3（Rank-3）** 追加；「一、已做了什么」/「二、还差什么」/「三、资产清单表」/「四、R32 / v0.10.0 状态表」/「R33 实机可见性修复」的所有历史行按「只追加、不改历史条款」保留未动，v0.11.0 增量以本段 + `teamwork/迭代-v0.11.0-玩法闭合与连击评价.md` + `teamwork/Rank-3/DONE-R34.md` 为准。零付费、零外部依赖、不启 GPU job。

### 5.1 v0.11.0 状态表

| 域 | 状态 | 说明 |
|---|---|---|
| 点数落盘唯一权威通道（A55） | ✅ 已落地（口径） | `points_awarded(reason, points, source)` 唯一权威、Rank-3 订阅写 `grace.trial.points`；`wave_cleared` 只作 HUD 展示基础值、`combo_settled` 只作对账与展示；三条通道职责边界 + A51 四类通胀 broken 判据登记进契约 §3.3 R34 段 |
| R32 四 flag 落盘接线 | ✅ 已落地（口径） | 抉择 / 破韧 / 处决 4 个 flag 接到 I-1 权威写入点（信号订阅 / 事件键配对去重 / `commit(reason)` / 先落盘后改实例）；防重复领取「同 execution / 同清波 / 同抉择不二次加点或扣费」 |
| 2 个连击三段式 flag | ✅ 已登记 | `combat.combo.rank` String / `combat.combo.count` int，基线 `"" / 0`、非单调；只作 `flags` 字典新 key、十字段冻结、`schema_version=3`、不写 `removals`；`multiplier` `[PLACEHOLDER]` 不落盘（A51） |
| `verify_v110_save_commit.gd` | ✅ 通过（只读验证件） | 三进程三态 `66 PASS / 0 FAIL`、`all` 自检 `64 PASS / 0 FAIL`、三 pid 互不相同、生产 `slot_01` md5 前后一致；不改生产逻辑、不碰生产存档 |
| 裁决 A49~A55 | ✅ 已登记 | 契约 §3.3 R34 说明段同时登记，逐条如实（含 A49 真实可达口径 / A50 唯一写入方 / A51 防通胀 / A52 按 A41 三判据 / A53 `128bit` 保留 / A54 唯一实例 / A55 权威通道） |
| 迭代收口文档 | ✅ 已落地 | `teamwork/迭代-v0.11.0-玩法闭合与连击评价.md`：拆解表 / P0~P2 / GDD 六项 / 三栏 / 架构 / 三态 / 回滚 / 零付费 backlog |
| 三段门禁 `grep SCRIPT ERROR=0` | ✅ 通过 | 7 份 `R34-*.log` 逐份 `SCRIPT ERROR=0` / `Parse Error=0` / `ERROR:` 前缀 = 0；G1/G2/G3 全 `EXIT=0`、G3 回读 `node_count=41` |
| 连击 / 抉择 / 处决 `[PLACEHOLDER]` 校准（A45 / A17） | ⚠️ 需用户确认 | 用户侧人工试玩，Rank-3 不代做 |
| 落盘接线运行时落地 + 真实输入连通（A49）/ 录屏目视（A42） | ⚠️ 需用户确认 | 归属 Rank 运行时接线 / 总指挥亲自回看首中尾三帧，Rank-3 不代验、不冒充完成 |
| HD-2D 全绿（A52 按 A41 三判据） | ❌ 未达 | 光效仍 2D `_draw()` / screen-reading shader 近似、地面 2D tile 贴 3D 平面、角色 billboard 像素精灵；不得据单路自评宣称全绿，A30 不切后端 |

### 5.2 资产表增量（R34 新增 / 改动文件，字节数为 `os.path.getsize` 实测，非编造）

| 文件（相对工程根） | 字节 | 类型 / 归属 |
|---|--:|---|
| `godot/scripts/rpg/verify_v110_save_commit.gd` | **39,467** | 新写只读三态验证脚本（本轮 Rank-3 唯一 `godot/` 新增文件，只读加载生产脚本、不改业务逻辑） |
| `teamwork/迭代-v0.11.0-玩法闭合与连击评价.md` | **31,638** | 新写迭代收口文档（§10 backlog 零付费零外部依赖增量） |
| `teamwork/00-协作契约.md`（§3.3 追加 R34 段） | **68,699** | 只追加、历史条款未动 |
| `teamwork/Rank-3/存档与flag规范.md`（§3.3 追加 2 行 + 注记） | **38,982** | 只追加、历史条款未动 |
| `teamwork/Rank-3/R34-*.log`（7 份真跑 stdout：G1/G2/G3 + write/load/assert/all） | **27,617**（1,367+75+5,778+8,656+6,915+2,146+2,680） | 真跑日志留档；逐份 `SCRIPT ERROR=0` |
| `README.md` / `teamwork/Rank-3/DONE-R34.md` / 回执 | —（不登记自指静态字节数） | 运行时状态文档 / 交付报告 / 回执：内容按「只追加」维护，字节数随段落追加变动，不做自指静态登记以免失真 |

> §3.1~§3.4 既有 I-5 素材 / 场景 / 脚本 / 产物实测字节数与「中枢 done 轮次」表（仍 R22 快照）一律未改；R34 未新增任何 I-5 素材 / 场景节点 / 导出产物，`courtyard.tscn` 节点 41 / uv 2/1/1 与 `presentation.gd` 只读。

### 5.3 「一、已做了什么」v0.11.0 增量（追加）

| 域 | 已落地 |
|---|---|
| **v0.11.0 玩法闭合与连击评价**（R34 派单 · Rank-3 点数落盘接线 / A55 权威通道 / 只读验证） | ① 契约 §3.3 + 存档与flag规范 §3.3 登记 2 个连击 flag + R32 四 flag 落盘接线口径 + 裁决 A49~A55（A55 三通道职责边界专段）；② 新写 `godot/scripts/rpg/verify_v110_save_commit.gd` 三进程三态只读验证（`66 PASS / 0 FAIL`，独立 PID 临时槽、生产 `slot_01` md5 前后一致，A55/A51/防重复/旧档回落机器判定）；③ 新写 `teamwork/迭代-v0.11.0-玩法闭合与连击评价.md`（玩法拆解表 + P0/P1/P2 + GDD 六项 + 三栏清单 + 节点与信号链架构 + 验收三态 + 风险回滚 + 零付费 backlog）；④ 工程根 `README.md` 追加 v0.11.0 状态段与本 §五；⑤ 真跑三段门禁 `grep SCRIPT ERROR=0`（7 份日志全 0、G3 回读 `node_count=41`）；⑥ `DONE-R34.md` + 回执。**所有新数值标 `[PLACEHOLDER]` + rationale + 调参唯一入口（只改表不改代码），Rank-3 未写任何 `godot/` 业务代码、未改其它 Rank 产出、未自行 git（总指挥收尾）** |
| **R34 回归真跑**（Rank-3） | 三进程三态 `write 11 + load 6 + assert 49 = 66 PASS / 0 FAIL`、三 pid `11728 / 30352 / 26900` 互不相同；单进程 `all` `64 PASS / 0 FAIL`；G1 `--headless --import` / G2 `--check-only --script` / G3 `--headless --quit` 全 `EXIT=0`；7 份 `R34-*.log` 逐份 `SCRIPT ERROR=0` / `Parse Error=0` / `ERROR:` 前缀 = 0（三段门禁达成）；生产 `slot_01` md5 前后一致 `5e900b2b47df9e2a9b36c4100282bc25`；`courtyard.tscn CACHE_MODE_IGNORE` 真跑回读 `node_count=41`（A38 断言保持）；既有 3 条退出 WARNING 如实保留、非 ERROR |

### 5.4 「二、还差什么」v0.11.0 增量（追加）

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| 19 | **v0.11.0 玩法闭合：`[PLACEHOLDER]` 数值待人工试玩校准、落盘接线运行时由归属 Rank 落地 / 真实输入连通（A49）未代验、`points_awarded.points` 是否携带倍率与事件键配对时序待对齐、15~20 秒录屏目视（A42）未代判、HD-2D 全绿仍未达（A52）** | **未达 · 待用户侧试玩 + 其它 Rank 运行时接线 + 总指挥目视 / 裁决** | 连击倍率 / 抉择代价 / 处决奖励三类 `[PLACEHOLDER]`、rationale 与调参唯一入口见迭代文档 §2（A45）；`hud.gd` 发信号 / `wave_trial_director.gd` / `combo_service.gd` / `boon_draft_service.gd` 运行时接线归 Rank-1 / Rank-2 并发产出，Rank-3 只登记口径 + 只读验证脚本、不代验运行时接线、不冒充「真实可达」（A49）；`points_awarded` 不带 `window_id` / `wave_index`，编排层与 `execution_performed` / `wave_cleared` 配对取事件键的时序健壮性归归属 Rank 校对；15~20 秒录屏首中尾三帧归 Rank-4 / 总指挥目视（A42），headless 无帧缓冲、Rank-3 不代做手感 / 审美判断；A52 以 `HD2D-STYLE-ANCHOR-v2.md` 三判据为准、如实记「未达全绿」，A30 不切后端；`128bit` 歧义（A53）继续保留待用户确认、不消歧 |

> **v0.11.0（R34）复核「还差什么」**：第 **10 项**（人工试玩，A17）/ **11 项**（`128bit` 歧义，A53 保留）/ **12 项**（HD-2D 全绿未达，A52 按 A41 三判据）/ **2 项**（真 HDR bloom / 3D 体积光 / SSR）在 v0.11.0 **仍未达**；第 **13~18 项**（各版 `[PLACEHOLDER]` 校准 / 并发表落地校对 / 运行时接线）仍未达且本版第 19 项新增同类缺口；Rank-3 均未代做、未宣称完成。


### R34 系列 / v0.11.0 玩法闭合 · 连击评价（2026-11-12 总指挥定稿）

- 新增机制：**连击评价 Combo Rank**（连续命中 → D/C/B/A/S 评级 → 倍率影响赐福点数 → 受击/超时重置），数据表 `combo_rules.tres` + 纯逻辑 `combo_service.gd` + 程序化 `_draw()` 五档视觉反馈。
- 完善功能：6 条生产运行时触发链接通、移除 `presentation.gd` 全部演示驱动、A54 唯一实例、A55/A56 生产落盘订阅者 `PointsCommitOrchestrator` autoload、A57 倍率后值进入落盘、HUD 连击文本布局回归修复、地面改不规则石板。
- 总指挥真跑：13 个验证脚本 37/26/97/62/110/59/42/31/51/39/28/64/16 PASS、FAIL 全 0；全工程门禁 `SCRIPT ERROR=0`；A38 节点 41 / uv 2/1/1 保持。
- 总指挥亲自重跑 `capture/v110_final.mp4`：450 帧 / 15.000s / 1,489,765 B；目视 5 帧确认文字重叠消除、Tab 互斥生效、处决窗口在真实链路下自然出现、暖金收束未过曝。
- 双产物重导：exe 109,178,880 B / pck 1,827,048 B / apk 30,372,475 B / idsig 243,122 B；apksigner v2/v3 true、icon_error=0。
- **HD-2D 全绿仍未达成**（A41/A52）；连击在录屏里仍停在 D 档，高评级由验证脚本实证、演示未覆盖；`[PLACEHOLDER]` 数值待人工试玩校准；定稿录屏禁止加 `--headless`（A47）。

## 六、R35 / v0.12.0 状态表（追加段，历史行一律保留未动）

> 本段为 **R35 / cmd-20261112-125821-143-A3（Rank-3）** 追加；「一、已做了什么」/「二、还差什么」/「三、资产清单表」/「四、R32 / v0.10.0 状态表」/「五、R34 / v0.11.0 状态表」/「R34 系列 … 总指挥定稿」的所有历史行按「只追加、不改历史条款」保留未动，v0.12.0 增量以本段 + `teamwork/迭代-v0.12.0-精准弹反与消费闭合.md` + `teamwork/Rank-3/DONE-R35.md` 为准。零付费、零外部依赖、不启 GPU job。

### 6.1 v0.12.0 状态表

| 域 | 状态 | 说明 |
|---|---|---|
| A59 `grace.trial.spent_points` 唯一出口 | ✅ 已落地（生产链路） | `PointsCommitOrchestrator` autoload 订阅 `boon_draft_applied` / `production_wave_modifier`，抉择 cost → `[PLACEHOLDER]` points 映射 → `spent_points` 单调累加，与 `grace.boon_draft.unlocked` / `.selected` / `.cost_applied` 同一次 `commit("boon_draft_cost_applied")` 原子写；余额 `points − spent_points ≥ 0` 前置门控 / 重复购买拒绝 / 缺失·非法值拒绝并告警 / 绝不写 `removals` / 绝不回退 `points`。cost→points 映射 `[PLACEHOLDER]` + rationale + 调参唯一入口（编排层常量段，只改常量不改逻辑） |
| A58 window_id 去重键 + `parry_performed` 订阅 | ✅ 已落地 | 编排层 `BOUND_SIGNALS` 由 4 扩为 **5**（新增订阅 HUD `parry_performed`，A48① 生产运行时订阅者，非验证脚本）；`exe:<window_id>` / `parry:<window_id>` 接非空唯一 window_id，不同窗口不合并、同一窗口重放幂等拒绝、空 id 降级唯一 fallback 键 + 告警；第二次弹反不再被 `auto:` 指纹误拒。保留 A55/A57（`points_awarded` 唯一权威通道、倍率后最终值原样采信） |
| A60 弹反奖励 `[PLACEHOLDER]` 防点数通胀 | ✅ 已落地 | 只经 `points_awarded("parry", …)` 一次原样采信，不落盘倍率 / 不二次加工 / 不叠乘；每窗口恰好一次；broken 判据（5 类）登记进契约 §3.3 R35 段，机器判定见新验证脚本 H 组 / R13~R18 |
| 3 个新三段式 flag | ✅ 已登记 | `combat.parry.success_count`（int / 单调递增）、`combat.parry.window_id`（String / 最近窗口覆盖）、`grace.boon_draft.unlocked`（bool / false→true 单向）；只作 `flags` 字典新 key、十字段冻结、`schema_version=3`、不写 `removals`、不回退 `points`；契约 §3.3 R35 段登记 A58/A59/A60/A61 |
| `verify_v120_save_commit.gd` | ✅ 通过 | 新写三进程三态存档验证件：`all` **70 PASS / 0 FAIL**，三进程 `write 17 + load 6 + assert 49 = 72 PASS / 0 FAIL`（pid `22792 / 23020 / 492` 互不相同）、生产 `slot_01` md5 前后一致、`RESULT=ALL_MATCH` |
| `verify_spent_points_production_v120.gd` | ✅ 通过（A48③ 真实可达） | 新写：不加载 `presentation.gd`、不在验证脚本内模拟编排；实例化主场景 → 生产 HUD 真实运行时信号 → 生产编排层 autoload 订阅 → 读磁盘断言「抉择扣费 → spent_points 增加 → 余额非负 → 重启读回一致 → 同一抉择重复购买被拒 → 两个不同 parry 窗口各自入账」；**39 PASS / 0 FAIL / RESULT=ALL_MATCH** |
| 契约 §3.3 + 迭代收口文档 | ✅ 已落地 | 契约 §3.3 **只追加** R35 说明段（历史条款 / I-1~I-6 / §3.1 §3.2 缺号未动）；`teamwork/迭代-v0.12.0-精准弹反与消费闭合.md`：拆解表 / P0~P2 / GDD 六项 / 三栏 / 节点信号链 / 真跑数字 / 验收三态 / 风险回滚 / 零付费 backlog |
| 三段门禁 `grep SCRIPT ERROR=0` | ✅ 通过 | G1 `--import` / 3× G2a `--check-only --script` / 12× G2b `--headless --script`（含三进程三态）/ G3 `--headless --quit` 全 `EXIT=0`；17 份 `R35-*.log` 统计 `SCRIPT_ERROR_COUNT=0 / PARSE_ERROR_COUNT=0 / ERROR_PREFIX_COUNT=0`；G3 回读 `node_count=41`、生产基线 `grace.trial.points=450` 未变 |
| 既有回归（7 份只读复跑） | ✅ 全绿 | `64 + 28 + 27 + 57 + 36 + 58 + 80 = 350 PASS / 0 FAIL`，逐字不删不放宽；Rank-1 `verify_parry_runtime_v120.gd` C2 由修复前 `disk=50 commit_count=1` 变为 `disk=100 commit_count=2`（两次弹反各自入账），C5b claimed 实证两 parry 键 + 两 exe 键 |
| `cost→points` / 弹反 / 抉择 `[PLACEHOLDER]` 校准（A45 / A17） | ⚠️ 需用户确认 | 用户侧人工试玩，Rank-3 不代做；调参唯一入口见迭代文档 §1.1 |
| 15~20 秒实机录屏目视（A42）/ 演示 D→A / S 级 | ⚠️ 需用户确认 | headless 无帧缓冲，总指挥亲自重跑回看；Rank-3 不代做手感 / 审美判断 |
| HD-2D 全绿（A61 按 A41/A52 三判据） | ❌ 未达 | 光效仍 2D `_draw()` / screen-reading shader 近似、地面 2D tile 贴 3D 平面、角色 billboard 像素精灵；不得据单路自评宣称全绿，A30 不切后端 |
| `128bit` 歧义（A53 继续保留） | ⚠️ 保留待用户确认 | A15 / A43 保留口径、不消歧、不编码进任何期望值 |

### 6.2 资产表增量（R35 新增 / 改动文件，字节数为 `os.path.getsize` 实测，非编造）

| 文件（相对工程根） | 字节 | 类型 / 归属 |
|---|--:|---|
| `godot/scripts/rpg/points_commit_orchestrator.gd` | **29,507** | 修改（A56 生产编排层 autoload，Rank-3 唯一写入）：A59 spent_points 出口 + A58 parry_performed 订阅 / 去重键 + 3 个新 flag；既有 A55/A57 逻辑未改 |
| `godot/scripts/rpg/verify_v120_save_commit.gd` | **39,853** | 新写三进程三态存档验证件（只读口径 + 磁盘一致性，70 PASS / 72 PASS） |
| `godot/scripts/rpg/verify_spent_points_production_v120.gd` | **26,371** | 新写 A48③ 真实可达回归（不加载 `presentation.gd`、不模拟编排，39 PASS） |
| `teamwork/迭代-v0.12.0-精准弹反与消费闭合.md` | **34,837** | 新写迭代收口文档（§9 backlog 零付费零外部依赖增量） |
| `teamwork/00-协作契约.md`（§3.3 追加 R35 段） | **84,307** | 只追加、历史条款 / I-1~I-6 / §3.1 §3.2 缺号未动 |
| `teamwork/Rank-3/R35-*.log`（17 份真跑 stdout：G1 / G2a×3 / G2b×12 / G3） | **157,498** | 真跑日志留档；逐份 `SCRIPT ERROR=0 / Parse Error=0 / ERROR 前缀=0` |
| `README.md` / `teamwork/Rank-3/DONE-R35.md` / 回执 | —（不登记自指静态字节数） | 运行时状态文档 / 交付报告 / 回执：内容按「只追加」维护，字节数随段落追加变动，不做自指静态登记以免失真 |

> §3.1~§3.4 既有 I-5 素材 / 场景 / 脚本 / 产物实测字节数与「中枢 done 轮次」表（仍 R22 快照）一律未改；R35 未新增任何 I-5 素材 / 场景节点 / 导出产物，`courtyard.tscn` 节点 41 / uv `2/1/1`、`presentation.gd`、`project.godot`（既有 autoload）、既有 `.tres` 数值一律只读未改；生产 `slot_01` md5 `219cbf043d3ae14a97f66c44f0e9591e` 前后一致。

### 6.3 「一、已做了什么」v0.12.0 增量（追加）

| 域 | 已落地 |
|---|---|
| **v0.12.0 精准弹反 · 消费闭合**（R35 派单 · Rank-3 点数消费出口 / 去重键 / 迭代收口） | ① `points_commit_orchestrator.gd` 接管 A59 `spent_points` 唯一出口（抉择扣费 → 单调累加 → 与 unlocked flag 同一次 commit 原子写、余额门控 / 重复拒绝 / 缺失非法拒绝告警 / 绝不写 removals / 绝不回退 points）+ A58 订阅 `parry_performed` 把 `exe:` / `parry:` 去重键接非空唯一 window_id（第二次弹反真实入账）；② 新写 `verify_v120_save_commit.gd`（三进程三态 70/72 PASS）与 `verify_spent_points_production_v120.gd`（A48③ 真实可达 39 PASS：抉择扣费 → spent 增加 → 余额非负 → 重启读回一致 → 重复购买被拒 → 两个不同 parry 窗口各自入账）；③ 契约 §3.3 只追加 R35 段（3 新三段式 flag + 裁决 A58/A59/A60/A61），本迭代文档 + README §六 状态段；④ 真跑三段门禁全 `EXIT=0`、`SCRIPT ERROR=0 / Parse Error=0 / ERROR 前缀=0`（17 份日志）、既有 7 份回归 350 PASS 全绿、A38 节点 41 / uv `2/1/1`、生产 `slot_01` 零改动；⑤ `DONE-R35.md` + 回执。**所有新数值标 `[PLACEHOLDER]` + rationale + 调参唯一入口（只改常量不改逻辑），Rank-3 未写任何其它 `godot/` 业务代码、未改其它 Rank 产出、未自行 git（总指挥收尾）** |
| **R35 回归真跑**（Rank-3） | 两份新脚本 `70 + 39 = 109 PASS / 0 FAIL`；三进程三态 `write 17 + load 6 + assert 49 = 72 PASS / 0 FAIL`、三 pid `22792 / 23020 / 492` 互不相同；既有 7 份 `64/28/27/57/36/58/80 = 350 PASS / 0 FAIL`；生产实证 `spent 0→15`、points `600→600`（不回退）、余额 `585`、两次 parry `600→650→700`、`claimed` 含 `parry:parry_0_1` / `parry:parry_0_2`、`success_count=2 / window_id=parry_0_2`、`commit_count=5`、重启读回一致、生产 `slot_01` md5 前后一致 `219cbf043d3ae14a97f66c44f0e9591e`；G3 回读 `node_count=41`。既有 3 条退出 WARNING 如实保留、非 ERROR |

### 6.4 「二、还差什么」v0.12.0 增量（追加）

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| 20 | **v0.12.0：`cost→points` `[PLACEHOLDER]` 系数人工试玩校准、15~20 秒录屏目视（A42）未代判、HD-2D 全绿仍未达（A61 按 A41/A52）、`128bit` 歧义（A53）继续保留、`boon:<index>` 跨波次去重口径 / 弹反免伤 / `combo_keep` 与 `fail_penalty` 生效等待裁决、演示 D→A / S 级未覆盖、既有 WARNING 清理** | **未达 · 待用户侧试玩 + 其它 Rank 裁决 / 运行时接线 + 总指挥目视** | `COST_TO_POINTS_FACTOR=10.0` / `MIN=1` 与弹反 `parry_rules.tres` 六项全部 `[PLACEHOLDER]`、rationale 与调参唯一入口见迭代文档 §1.1（A45）；headless 无帧缓冲、Rank-3 不代做手感 / 审美判断（A42）；A61 以 `HD2D-STYLE-ANCHOR-v2.md` 三判据为准、如实记「未达全绿」，A30 不切后端；`128bit` 歧义（A53）继续保留待用户确认、不消歧；`boon:<index>` 跨波次同序号抉择、弹反成功是否免伤、`combo_keep` / `fail_penalty` 是否真正生效、`production_wave_modifier` 是否独立扣费归总指挥裁决（迭代文档 §4 / §7 / §8）；`团队/Rank-3/存档与flag规范.md` §3.3 全局登记表同步、Rank-1 验证脚本内过时「如实登记」打印文本同步不在本轮授权范围、未越界写 |

> **v0.12.0（R35）复核「还差什么」**：第 **10 项**（人工试玩，A17）/ **11 项**（`128bit` 歧义，A53 保留）/ **12 项**（HD-2D 全绿未达，A61 按 A41/A52 三判据）/ **2 项**（真 HDR bloom / 3D 体积光 / SSR）在 v0.12.0 **仍未达**；第 **13~19 项**（各版 `[PLACEHOLDER]` 校准 / 并发表落地校对 / 运行时接线 / 录屏目视）仍未达且本版第 20 项新增同类缺口；Rank-3 均未代做、未宣称完成。

### R35 系列 / v0.12.0 精准弹反 · 消费闭合（2026-11-12 总指挥定稿）

- 新增机制：**精准弹反 Parry**（Boss 出招前开窗 → 玩家按 K → 成功加削韧 / 赐福点数 / 连击不断；窗口外 / 冷却 / 重复按键拒绝），数据表 `parry_rules.tres` + 纯逻辑 `parry_service.gd` + HUD 预兆文字 + 程序化 `_draw()` 反馈。
- 完善功能：A58 非空唯一 `window_id` 与 `parry:<id>` 去重键（两次弹反各自入账）、A59 `spent_points` 扣费出口原子写、A63 mobile 档轻量绘制与断言同步、A64 闪光底板收敛（面积 −83.71%）、地面改规整错缝石板。
- 总指挥真跑：14 个验证脚本 37/97/110/58/80/47/36/57/39/27/28/70/39/47 PASS、FAIL 全 0；全工程门禁 `SCRIPT ERROR=0`；A38 节点 41 / uv 2/1/1 保持。
- 总指挥亲自重跑 `capture/v120_final.mp4`：450 帧 / 15.000s / 1,475,275 B；目视 7 帧确认半透明大矩形消除、弹反 HUD 文字清晰、HUD 无重叠、连击 D→C 递进可见、340 帧余额 106 证扣费生效、尾帧胜利·已落盘。
- 双产物重导：exe 109,178,880 B / pck 1,958,864 B / apk 30,505,105 B / idsig 247,218 B；apksigner v2/v3 true、icon_error=0。
- **HD-2D 全绿仍未达成**；程序化光环 / 闪光实机不易辨识，连击 D→A / S 级未覆盖；`[PLACEHOLDER]` 待人工试玩校准；定稿录屏禁止加 `--headless`（A47）。
