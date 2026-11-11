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

> **v0.4.0（R26）复核「还差什么」**：第 **10 项人工试玩（exe / apk 手感 / 审美验收，裁决 A17）**、第 **11 项 `128bit` 词义歧义（待用户确认、A15 不消歧）**、第 **12 项 HD-2D 全绿未达（Boss 无可见像素形象 / 战斗数值停摆 / 地面平铺与马赛克 / 光效 2D 近似）** 三项在 v0.4.0 **仍未达**，本轮 Rank-3 均未代做、未宣称完成；新增第 13 项为 v0.4.0 特有的数值校准 / 并发表落地校对缺口。
>
> **v0.5.0（R27）复核「还差什么」**：第 **10 项人工试玩（exe / apk 手感 / 审美验收，裁决 A17）**、第 **11 项 `128bit` 词义歧义（待用户确认、A15 不消歧）**、第 **12 项 HD-2D 全绿未达（Boss 无可见像素形象 / 战斗数值停摆 / 地面平铺与马赛克 / 光效 2D 近似）** 在 v0.5.0 **仍未达**，本轮 Rank-3 均未代做、未宣称完成；第 **13 项**（v0.4.0 波次数值校准）中 `WAVE-TRIAL-TUNING.md` **已于 R26 后落地**，「待落地校对」部分可推进，但倍率 / 奖励 / 时限具体值仍待人工试玩校准、Rank-3 不代做；新增第 14 项为 v0.5.0 特有的成长数值校准 / 并发表落地校对 / `<id>` 收敛裁决 / 运行时效果接通缺口。
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
