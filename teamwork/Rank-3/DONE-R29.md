# DONE-R29.md · Rank-3 交付（R29 / v0.7.0 新内容：风格锚点 v2 定调 + A28 全文口径统一）

> 派单 `cmd-20261111-112803-992-A3` · `[ROUND=R29]` · Rank-3（RPG / 世界 / 存档）· 2026-11-11
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--version` = `4.7.2.stable.official.ed1daf0bf`（G0 `EXIT=0`）
> **结论：派单 5 项全部真实达成。** 风格锚点 v2 已尽早落盘、A28 三处口径统一、README v0.7.0 / 还差什么已更新、**31 PASS / 0 FAIL 存档 / HUD 回归不回退 + 三段门禁 `grep SCRIPT ERROR=0` 达成**；只写自有文档 / 契约 §3.3 / GDD §10.8 / README，**未写任何 `godot/` 工程业务文件**、未自行 git、零付费、零外部依赖、未启 GPU job、未新建只读探针 / 巡检脚本。

---

## 0. 一句话结论

风格锚点 **v2 = v1 八字段（逐字冻结继承）+ 4 新字段（景深分层 / 光色规范 / 暗角与光晕 / 三波色带节奏）**，补齐「与《八方旅人》式 HD-2D 的 9 项差距清单（如实登记）+ 三条验收判据 + 可逐字复用 16 色受控色板（项目级色库 ≥256 两层口径沿用 A15）」，并**明确只做 2D 近似强化、不切后端（A30）、不谎称真 3D 光效**；A28 把契约 §3.3 / GDD §10.8 / README 里 `grace.tutorial.step_index` 的写方 / commit reason / 读方统一为裁决 A26 落地口径（写方 Rank-1 `tutorial_director.gd` / reason `tutorial_step_reward` / 教学 HUD 读运行时游标 / 世界 flag 只作历史进度），逐处改前→改后见 §3；真跑 12 次引擎调用全 `EXIT=0`、31 PASS 不回退、12 份日志 `SCRIPT ERROR=0`（G3 退出期 4 条 `ERROR:` 前缀残留如实登记、非 SCRIPT ERROR）。

---

## 1. 实际交付清单

| # | 文件 | 动作 | 内容 |
|---|---|---|---|
| 1 | `F:/Game/aierdengfahuan/HD2D-STYLE-ANCHOR-v2.md` | **新建 · 尽早落盘** | P0 定调全文（§0 边界 / §1 v1 八字段 / §2 四新字段 / §3 差距清单 / §4 验收判据 / §5 16 色板与两层口径 / §6 `[PLACEHOLDER]` 汇总 / §7 未做什么）。**先于其它产出落盘**，供 Rank-2 `verify_depth_profile_v070.gd` 引用色板 |
| 2 | `teamwork/00-协作契约.md` §3.3 | **就地改 5 处 + 追加 1 段** | 登记表 `step_index` 行写 / 读、`commit(reason)` 落盘点、先落盘顺序第 ④ 步、读写边界段；追加 R29 说明段（逐处改前→改后 + 未动边界） |
| 3 | `teamwork/Rank-3/WAVE-TRIAL-GDD.md` §10.8 | **就地改 6 处 + 追加 2 处** | 新 flag 表 `step_index` 行写 / 读、T-P1（落盘点 + reason + 写入内容）、五步顺序第 ④ 步、口径差异登记、T-V8；追加 T-V10 + R29 说明段 |
| 4 | `README.md`（工程根） | **就地改 2 处 + 追加 5 处** | 头部 R29 说明行；v0.6.0 条目 reason / 待裁决状态订正（2 处）；「一、已做了什么」追加 v0.7.0 条目 + R29 回归真跑行；「二、还差什么」追加第 16 项 + v0.7.0 复核段 |
| 5 | `teamwork/Rank-3/R29-*.log`（12 份） | **新建 · 运行输出留档** | G0-version / G1-import / G2a~G2f / G3-quit / RUN-r19 / RUN-r17 / TFV-selftest，均为实际 stdout，非工程源文件、非脚本 |
| 6 | `teamwork/Rank-3/DONE-R29.md` | **新建** | 本文件 |
| 7 | `teamwork/command_center/ai/3/outbox/cmd-20261111-112803-992-A3.json` | **新建** | 回执 JSON |

> **回执投递如实登记**：回执 JSON 已按任务单精确路径写入 `teamwork/command_center/ai/3/outbox/cmd-20261111-112803-992-A3.json`（`task_id` / `ai:3` / `status:"done"` / `result` 引用本文实际结论）；写入后被**调度中枢即时取件消费**，现存于 `teamwork/command_center/dispatcher/receipts/cmd-20261111-112803-992-A3.json`（3049 B，JSON 解析通过、4 字段齐全、result 1664 字符），`teamwork/command_center/commander/report.md` 已把本任务登记为 **done**（2026-11-11 11:49:28，result 与回执一致）。`ai/3/outbox/` 被取件后清空，与历轮标准终态一致（R28 A3 回执亦在 `dispatcher/receipts/`、outbox 为空）；**未重复写入二次触发中枢、未干扰共享状态**。给总指挥的可查路径：写入目标 `teamwork/command_center/ai/3/outbox/cmd-20261111-112803-992-A3.json` → 中枢取件后 `teamwork/command_center/dispatcher/receipts/<同名>` → 战报 `commander/report.md` done 行。

**未写**：任何 `godot/` 工程业务文件（`project.godot` / `courtyard.tscn` / `hd2d_fx.gd` / `hd2d_parallax.gd` / `depth_profile.tres` / `hud.gd` / `tutorial_director.gd` / 素材 PNG / shader / `.tres`）、其它 Rank 目录、`00-汇总.md` / `00-进度台账.md` / 群聊总线 / 资产表 / 中枢 done 表。

---

## 2. 风格锚点 v2 要点与色板

### 2.1 要点

- **v1 八字段逐字冻结继承**（画风 / 视角 / 光照 / 线宽 / 质感 / 比例 / 色彩倾向 / 禁忌 + 3D 补充附属行），v2 不改一字。
- **4 个新增字段**：**景深分层**（远 / 中 / 近 3 层 2D 伪景深，靠分层色带 + 视差 + 传统深度雾 `fog_density=0.02`，绝不是真 DoF）；**光色规范**（光源方向全项目统一，暖金只打主体 / 近景，钉死 `cold_night_fog_hex=#1B2A4A` / `warm_gold_key_hex=#C99A3A`）；**暗角与光晕**（2D `_draw()` 低 alpha 冷色压暗 + `draw_circle()` 同心圆暖金过阈，不是 `Environment.glow`）；**三波色带节奏**（冷蓝 → 深紫 → 暖紫，复用 `hd2d_parallax.gd` 既有 `wave_index` 驱动）。
- **与《八方旅人》式 HD-2D 差距清单（9 项，如实登记、非待办承诺）**：景深 / 体积光 / 湿地倒影 / bloom / 3D 地形 = 明显差距（全为 2D 近似）；像素精灵 / 光色关系 / UI = 口径级已对齐；**渲染后端 `gl_compatibility` = 根因差距，A30 裁决不切**。
- **三条验收判据**：J1 缩略图 10% 剪影可读（须 Rank-4 录屏目视 + 用户试玩）；J2 主体与背景明度差 ≥2 档（锚点色对 65−22=43 ≈ 4 档，静态查表可判）；J3 同屏高饱和色 ≤3 种（3 色白名单静态可判）。补充 J4~J8（灰度可分 / 单帧 ≤16 色 / 状态不只靠颜色 / 暗角不遮 HUD / 三段门禁）。
- **A30 边界**：本版**只做 2D 近似强化、不切后端、不做真 3D 光效、不谎称 shader 生效**；工程「光效」全为 `hd2d_fx.gd` 的 `CanvasItem._draw()` 近似（依据 `TECHNICAL-ART-DEPTH-v060.md` §1 / §2 / §7）。P0（本文，仅文档）→ P1（Rank-2 参数 / Rank-1 HUD）→ P2（Rank-4 全屏 shader）分工。所有 v2 新数值标 `[PLACEHOLDER]` + rationale，未写进工程代码。

### 2.2 可逐字复用色板（16 色受控，sRGB hex6 大写）

| # | 色号 | L | 语义角色 | 来源 |
|---:|---|---:|---|---|
| 1 | `#0A1020` | ≈8 | 阴影 / 描边 | v1 §2 |
| 2 | `#1B2A4A` | ≈22 | **冷夜雾色号 `cold_night_fog_hex`** | v1 §2 |
| 3 | `#6B4226` | ≈30 | 暗棕 | v1 §2 派生 |
| 4 | `#B33A3A` | ≈40 | **危险暗红（高饱和白名单 ①）** | v1 §2 |
| 5 | `#2C4C8C` | ≈45 | 主色 钴蓝 | v1 §2 |
| 6 | `#3F6FC4` | ≈55 | 亮钴蓝 | v1 §2 派生 |
| 7 | `#C99A3A` | ≈65 | **暖金主光色号 `warm_gold_key_hex`（高饱和白名单 ②）** | v1 §2 |
| 8 | `#35D0C0` | ≈70 | **青绿（高饱和白名单 ③）** | v1 §2 派生 |
| 9 | `#79B4E8` | ≈72 | 亮蓝 | v1 §2 派生 |
| 10 | `#E8B98C` | ≈75 | 肤色 | v1 §2 派生 |
| 11 | `#F2D07A` | ≈82 | 暖金高光（受光色，不计入高饱和强调） | v1 §2 派生 |
| 12 | `#C9D2E0` | ≈82 | 冷亮钢 | v1 §2 派生 |
| 13 | `#E8EDF2` | ≈92 | 最高亮 亮钢 | v1 §2 |
| 14 | `#24406B` | ≈30 | **波 1 冷蓝雾带** `[PLACEHOLDER]` | v2 新增 |
| 15 | `#3B2E5A` | ≈25 | **波 2 深紫雾带** `[PLACEHOLDER]` | v2 新增 |
| 16 | `#5A3B52` | ≈32 | **波 3 暖紫雾带** `[PLACEHOLDER]` | v2 新增 |

- **两层口径沿用裁决 A15**（`00-协作契约.md` §9.3 逐字）：**项目级色库 ≥256 色**（项目级下限，载体 `teamwork/Rank-4/palette_256.json`，`palette_id=hd2d_index_256_v1`、当前冻结 32 色、容量上限 256）+ **单帧强制 ≤16 色索引**（单帧上限，从上表取色）；原「256 色以上 / 单帧 ≥256」废止；128px 基准画布不变、RGBA 保 alpha、`128bit` 歧义显式保留待用户确认。
- **如实登记**：Rank-4 `palette_256.json` 的 32 色板与美术提案 v1 §2 的色号**不是同一套（历史两套口径并存）**，v2 **不擅自合并、不伪造一致**；16 色受控表以 A15 确认的 v1 §2 为真源。
- **可机器解析常量块**（`HD2D-STYLE-ANCHOR-v2.md` §5.3）：含 `colors_16` / `cold_night_fog_hex` / `warm_gold_key_hex` / `high_saturation_allowlist`（`#B33A3A` / `#C99A3A` / `#35D0C0`）/ `wave_band_hex` / `two_layer_a15`，供 Rank-2 校验脚本整段逐字复制。

---

## 3. A28 三处「改前 → 改后」逐处对照

**统一目标（裁决 A26 落地口径）**：写方 = Rank-1 `tutorial_director.gd`（运行时代理按 `max` 写、`set_flag` 与本步奖励合并一次 commit）；commit reason = `tutorial_step_reward`；读方 = 教学 HUD 读运行时游标（`get_snapshot()["step_index"]` / `hud.gd read_tutorial_progress()`）；世界 flag `grace.tutorial.step_index` 只作历史进度。信号名 `tutorial_step_completed(step_id, reward)` 保留不改（A26 实现即此信号）。

### 3.1 `teamwork/00-协作契约.md` §3.3（5 改 + 1 追加）

| # | 位置 | 改前 | 改后 |
|---|---|---|---|
| C1 | 登记表 `step_index` 行「写」 | `写：Rank-3（订阅 Rank-1 tutorial_step_completed(step_id, reward)，每完成一步按 max(旧值, 本步序号) 推进，强制 commit(reason) 先落盘）` | `写：Rank-1 tutorial_director.gd（裁决 A26 运行时代理：按 max 推进，set_flag 与本步赐福点数奖励合并入同一次 commit("tutorial_step_reward") 先落盘、不新增落盘点）` |
| C2 | 登记表 `step_index` 行「读」 | `读：教学 HUD「进度 1-3」、重启恢复、回放断言（纯读 get_flag）` | `读：世界 flag 只作历史进度（重启恢复 / 回放断言纯读 get_flag）；教学 HUD 读运行时游标（TutorialDirector.get_snapshot()["step_index"] / hud.gd read_tutorial_progress()）、绝不读世界 flag` |
| C3 | `commit(reason)` 强制落盘点 | `每步 tutorial_step_completed 结算（tutorial_step_completed：step_index 按 max 推进 + points 累加）` | `每步结算（reason tutorial_step_reward，由 Rank-1 tutorial_director.gd 把 step_index 与本步 points 奖励合并入同一次原子 commit、不新增落盘点）`；`tutorial_completed` / `load` / R26 三处波次 reason 沿用不改 |
| C4 | 「先落盘再改运行时实例」第 ④ 步 | `emit flag_changed（教学 HUD 进度 / 赐福点亮态增量刷新）` | `emit flag_changed（赐福点亮态增量刷新；教学 HUD 进度取运行时游标、不随世界 flag 刷新）` |
| C5 | 「读写边界 / 本轮不越界」 | `写方 Rank-3（I-1 set_flag 权威定义方），订阅 Rank-1 信号；Rank-1 tutorial_director.gd 只发信号、不写 flag；读方教学 HUD「进度 / 步骤文案 / 奖励点数」…` | `写方 Rank-1 tutorial_director.gd（运行时代理，合并一次 commit("tutorial_step_reward")）；教学 HUD 读运行时游标、绝不读世界 flag；世界 flag 只作历史进度；赐福点亮态 / 跳过门控读 completed` |
| C6 | §3.3 末尾 | （无） | **追加 R29 说明段**：逐处改前→改后摘要 + 明确未动边界 |

### 3.2 `teamwork/Rank-3/WAVE-TRIAL-GDD.md` §10.8（6 改 + 2 追加）

| # | 位置 | 改前 | 改后 |
|---|---|---|---|
| G1 | 新 flag 表 `step_index` 行「写」 | `写：Rank-3（订阅 tutorial_step_completed(step_id, reward)，按 max 推进，强制 commit(reason) 先落盘）` | `写：Rank-1 tutorial_director.gd（裁决 A26 运行时代理：set_flag 与本步奖励合并入同一次 commit("tutorial_step_reward")、不新增落盘点）` |
| G2 | 新 flag 表 `step_index` 行「读」 | `读：教学 HUD「进度 1-3」、重启恢复、回放断言` | `读：世界 flag 只作历史进度；教学 HUD 读运行时游标、绝不读世界 flag` |
| G3 | T-P1 落盘点 | `每步 tutorial_step_completed 结算｜reason tutorial_step_completed｜step_index = max(旧, 本步序号)、points += 本步 reward_points` | `每步结算（A26：Rank-1 tutorial_director.gd 运行时代理）｜reason tutorial_step_reward｜step_index 的 set_flag 与本步 points 奖励合并入同一次原子 commit（不新增落盘点）` |
| G4 | 五步顺序第 ④ 步 | `emit flag_changed（教学 HUD 进度 / 赐福点亮态增量刷新）` | `emit flag_changed（赐福点亮态增量刷新；教学 HUD 进度取运行时游标、不随世界 flag 刷新）` |
| G5 | 口径差异登记 | `… 若总指挥 / Rank-1 需要「重开时进度归零」的持久化语义，列为待裁决的口径差异 … 教学 HUD 进度以运行时状态机为准` | `… 世界 flag 只作历史进度、教学 HUD 读运行时游标；该口径差异已由裁决 A26 落地（写方 Rank-1 / reason tutorial_step_reward / HUD 读运行时游标 / 世界 flag 只作历史进度），并按 A28 在 §10.8 全文统一，不再列为待裁决` |
| G6 | T-V8 校对清单 | `待总指挥裁决（本轮按单调不变量落地、不擅自改正则）` | `A26 已裁决落地、A28 全文统一（世界 flag 只作历史进度 / HUD 读运行时游标 / 写方 Rank-1 / reason tutorial_step_reward），不再待裁决` |
| G7 | 校对清单表 | （无） | **追加 T-V10**：A28 全文口径统一，状态 `R29 真跑（见 DONE-R29.md）` |
| G8 | §10.8 末尾 | （无） | **追加 R29 说明段**：逐处改前→改后 + 明确未动边界 |

### 3.3 `README.md`（工程根，2 改 + 5 追加）

| # | 位置 | 改前 | 改后 |
|---|---|---|---|
| R1 | 头部说明行 | （无 R29 行） | **追加 R29 说明行**（v2 定调 / A28 统一 / 31 PASS / 三段门禁 / G3 4 条 ERROR 如实登记指向） |
| R2 | v0.6.0 已做条目 reason | `commit("tutorial_step_completed") / commit("tutorial_completed") 强制落盘点` | `commit("tutorial_step_reward")（A28 按裁决 A26 统一；R28 原登记为 tutorial_step_completed）/ commit("tutorial_completed")` |
| R3 | v0.6.0 已做条目口径状态 | `T 重开与 step_index 单调口径（如实登记为待裁决）` | `A26 已落地 / A28 全文统一：写方 Rank-1 tutorial_director.gd、reason tutorial_step_reward、教学 HUD 读运行时游标、世界 flag 只作历史进度（R29 订正；R28 原登记为「待裁决」）` |
| R4 | 「一、已做了什么」 | （无） | **追加 v0.7.0 条目行**（v2 全文要点 + 差距清单 + 三判据 + 16 色板 + 两层口径 + A30 边界 + A28 统一 + 未动边界） |
| R5 | 「一、已做了什么」 | （无） | **追加 R29 回归真跑行**（12 次调用 / 31 PASS / TFV selftest / `SCRIPT ERROR=0` / 4 条 ERROR 如实登记） |
| R6 | 「二、还差什么」 | （无） | **追加第 16 项**（v0.7.0 `[PLACEHOLDER]` 校准 / 并发产出未代验 / HD-2D 全绿未达 / §10.8 之外残留口径差异待裁决） |
| R7 | 复核段 | （无） | **追加 v0.7.0 复核段**（第 10/11/12/13/14/15 项状态 + 第 15 项「待裁决」已由 A26 落地、不再待裁决 + 第 16 项） |

**未改动其它历史条款（逐处核对）**：契约 `grace.tutorial.completed` 整行、R25 / R26 / R27 三组历史说明段（含 R26 行 87、R27 行 95 的「写方 Rank-3」）、三段式正则段、§4.4 十字段 / `schema_version=3` 段、I-1~I-6 接口表、§3.1 / §3.2 缺号、§9；GDD §10.8 的 `completed` 整行、T-P2 / T-P3 / T-P4；**§10.8 之外的 §10.1~§10.7 / §10.9 及全部历史章节**；README §3.1~§3.4 资产表实测字节数、中枢 done 轮次表（仍 R22 快照）、其它 Rxx 历史行。契约 §3.3 行 98「待裁决」字样、README 第 15 项「口径待裁决」字样作为 **R28 历史如实登记保留**，其裁决状态以各自 R29 段 / v0.7.0 复核段为准。

---

## 4. 真跑输出结论（不靠 clean build，用实际 stdout）

### 4.1 命令清单（引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--path F:/Game/aierdengfahuan/godot`，一次一个进程、串行）

| 段 | 命令标志 | 日志 | `EXIT` |
|---|---|---|:--:|
| G0 | `--version` | `R29-G0-version.log` | 0 |
| G1 门禁 | `--headless --import` | `R29-G1-import.log` | 0 |
| G2a | `--headless --check-only --script <abs>/verify_tutorial_flags_v060.gd` | `R29-G2a-tfv060.log` | 0 |
| G2b | `--headless --check-only --script res://scripts/save_delta_writer.gd` | `R29-G2b-writer.log` | 0 |
| G2c | `--headless --check-only --script res://scripts/hud.gd` | `R29-G2c-hud.log` | 0 |
| G2d | `--headless --check-only --script <abs>/r19_verify_hud.gd` | `R29-G2d-r19.log` | 0 |
| G2e | `--headless --check-only --script res://scripts/verify_hud_binding.gd` | `R29-G2e-r17.log` | 0 |
| G2f | `--headless --check-only --script <abs>/r22_save_e2e.gd` | `R29-G2f-e2e.log` | 0 |
| G3 门禁 | `--headless --quit` | `R29-G3-quit.log` | 0 |
| 回归 A | `--headless --script <abs>/r19_verify_hud.gd` | `R29-RUN-r19.log` | 0 |
| 回归 B | `--headless --script res://scripts/verify_hud_binding.gd` | `R29-RUN-r17.log` | 0 |
| TFV selftest | `--headless --script <abs>/verify_tutorial_flags_v060.gd` | `R29-TFV-selftest.log` | 0 |

> `<abs>` = `F:/Game/aierdengfahuan/teamwork/Rank-3/`。**12 次引擎调用全 `EXIT=0`**。

### 4.2 PASS / FAIL（实际 SUMMARY 行）

| 项 | 实际输出 | 结论 |
|---|---|---|
| `r19_verify_hud.gd` | `SUMMARY pass=20 fail=0 ok=true` | **20 PASS / 0 FAIL** |
| `verify_hud_binding.gd` | `SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true` | **11 PASS / 0 FAIL**，**首次即 11/0，无 R27 并发 9/2 抖动** |
| **任务单 ④ 的 31 PASS 回归** | 20 + 11 | **31 PASS / 0 FAIL，不回退** |
| `verify_tutorial_flags_v060.gd` selftest | `SUMMARY phase=selftest pid=23808 pass=15 fail=0 ok=true` / `RESULT=ALL_PASS` | **15 PASS / 0 FAIL**；**本轮只跑 selftest 一态，未跑 write / read 两独立进程三态，如实登记、不冒充 R28 的 21 PASS 全流程** |

### 4.3 三段门禁 `grep SCRIPT ERROR=0`

- **12 份 `R29-*.log` 逐份 `SCRIPT ERROR=0`、`Parse Error=0`**（`grep -c` 逐份核验，见下汇总行）。**三段门禁 `grep SCRIPT ERROR=0` 达成**。
- **如实登记（不谎报「三类 ERROR 全 0」）**：`R29-G3-quit.log` 另有 **4 条 `ERROR:` 前缀退出期引擎残留** ——
  1. `ERROR: Parent node is busy setting up children, add_child() failed. Consider using add_child.call_deferred(child) instead.`（GDScript backtrace `res://scripts/hud.gd:795 _ensure_shop_readable` → `hud.gd:158 _ready`），对应同日志 `[R29][SHOP] 兑换面板迁出 SubViewport → 独立 CanvasLayer(layer=45)`，**属 Rank-1 本轮并发写入、非 Rank-3 引入、不在本轮授权范围、不代修**；
  2~4. `ERROR: 4 / 2 / 1 RID allocations ... were leaked at exit.`（退出期 RID 残留）。
  - **R28 基线 `R28-G3-quit.log` 无 `ERROR:` 行**（仅 1 条 `ObjectDB instances leaked` WARNING）；本轮 G3 日志因并发方新增节点 / shader / 面板迁移而信息量增大（2447 B → 4323 B）。
  - 这 4 条 **不是 `SCRIPT ERROR`、不是 `Parse Error`、不是回归断言失败**；12 次调用 `EXIT` 全 0、31 PASS 不回退。按历轮「如实保留 WARNING、非 ERROR」纪律一并登记，**不隐瞒、不宣称「三类 ERROR 全 0」**，交总指挥 / Rank-1 知悉。
- 既有退出 WARNING 如实保留、非 ERROR：`[SaveSystem] --script 工具模式跳过自动读回` / `[ChunkManager] 未找到 ChunkRoot` / `ObjectDB instances leaked`（本轮 24 条）/ `Canvas` / `CanvasItem` RID leaked。
- 并发环境佐证（非 Rank-3 产物、只读观察）：G3 日志出现 `[R29][DEPTH] 读取 res://data/render/depth_profile.tres 命中字段=2/11`、`[R29][GRADE] shader 小样已挂载`，即 Rank-2 / Rank-4 本轮并发产出已落盘；这些文件 Rank-3 均未写、未改、未代验。

---

## 5. README 新增

- **头部**：追加 R29 说明行（v2 定调 + A28 三处统一 + 31 PASS + 三段门禁 + G3 4 条 ERROR 指向）。
- **「一、已做了什么」**：追加 **v0.7.0 条目行**（风格锚点 v2 全文要点 / 9 项差距清单 / 三判据 / 16 色板 + 两层口径 / A30 边界 / A28 统一 / 未动边界）与 **R29 回归真跑行**（12 次调用 / 31 PASS / TFV selftest / `SCRIPT ERROR=0` / 4 条 ERROR 如实登记）。
- **「二、还差什么」**：追加 **第 16 项**（v0.7.0 `[PLACEHOLDER]` 校准 / Rank-1·2·4 并发产出未代验 / HD-2D 全绿未达 / §10.8 之外残留口径差异待裁决）与 **v0.7.0 复核段**（第 10/11/12/13/14 项仍未达；第 15 项「口径待裁决」已由 A26 落地、A28 统一、不再待裁决；新增第 16 项）。
- **就地订正**：v0.6.0 条目的 `commit("tutorial_step_completed")` → `commit("tutorial_step_reward")`、「T 重开与 `step_index` 单调口径（待裁决）」→「A26 已落地 / A28 全文统一」，均标注 R28 原登记值，不隐瞒历史。
- **未改**：§3.1~§3.4 资产表实测字节数、中枢 done 轮次表（仍 R22 快照）、其它历史 Rxx 行。

---

## 6. 未完成项与如实边界（无功能性阻塞）

| # | 项 | 状态 / 归属 |
|---|---|---|
| 1 | **风格锚点 v2 的 5 组 `[PLACEHOLDER]` 数值**（层数 3 / 远景冷雾 alpha 0.15~0.35 / 暗角强度 0.10~0.25 / bloom 半径·alpha / 三波雾带色号 3 个） | **待录屏目视 + 用户人工试玩校准**；均写 rationale、未写进任何工程代码；Rank-3 不代做手感 / 审美判断 |
| 2 | **J1（缩略图 10% 剪影可读）及暗角 / 光晕 / 三波色带的画面观感** | **须 Rank-4 录屏目视 + 用户试玩**；headless 真跑无真实帧缓冲，Rank-3 只能静态查表判 J2 / J3 / J5 / J6，**不宣称 HD-2D 全绿** |
| 3 | **A30 已知差距**（真 3D 景深 / 体积光 / 倒影 / bloom / `gl_compatibility` 后端） | 裁决不切后端、不做真 3D 光效；v2 §3 差距清单如实登记；README 第 2 / 12 项保持未达 |
| 4 | **§10.8 之外的残留口径差异** | 任务单只授权统一契约 §3.3 / GDD §10.8 / README，且「不改动其它历史条款」。**GDD §10.6 事件输入表（行 492）仍为 R28 登记「Rank-3 订阅信号写 `grace.tutorial.step_index` / `completed` 并累加 points，Rank-1 不写 flag」**、契约 `grace.tutorial.completed` 行仍写方 Rank-3、README 第 15 项仍含「口径待裁决」字样 —— 这些与 A26 落地口径（Rank-1 运行时代理写）存在**已知残留差异**，按授权边界保留未动、如实登记、**交总指挥裁决是否后续扩大统一范围**。v2 / 各 R29 段 / 本文件均已注明 |
| 5 | **G3 退出期 4 条 `ERROR:` 前缀残留** | 非 `SCRIPT ERROR` / 非 `Parse Error` / 非回归失败；归属 Rank-1 本轮并发 HUD 写入（`hud.gd:795`），Rank-3 不代修、如实登记 |
| 6 | **TFV 全流程 21 PASS** | 本轮按任务单 ④ 只跑 selftest 15 PASS，未跑 write / read 两独立进程三态；如实登记、不冒充 R28 全流程 |
| 7 | 15~20 秒实机录屏 / 目视回看 | 属 Rank-4 / 用户侧；本轮约束不启 GPU job，Rank-3 未代做、未谎报 |
| 8 | 人工试玩（exe / apk）手感 / 审美验收（A17）、`128bit` 歧义（A15 保留） | 历轮长期项，属用户侧 / 待用户确认，本轮未代做、未消歧 |

**阻塞：无功能性阻塞。** 派单 5 项（① v2 定调尽早落盘 / ② A28 三处口径统一逐处改前改后 / ③ README v0.7.0 与还差什么 / ④ 31 PASS 回归 + 三段门禁 / ⑤ 只写自有文档）均真实达成。

---

## 7. 授权边界与公共契约核对

- **只写**：`HD2D-STYLE-ANCHOR-v2.md`（工程根）、`00-协作契约.md` §3.3、`WAVE-TRIAL-GDD.md` §10.8、`README.md`（工程根）、`teamwork/Rank-3/`（`DONE-R29.md` + 12 份 `R29-*.log`）、`command_center/ai/3/outbox/` 回执 JSON。**未写任何 `godot/` 工程业务文件**，未写其它 Rank 目录。
- **直接改直接真跑**：12 次引擎调用均实际执行、日志为真实 stdout；**未新建只读探针 / 巡检脚本**（`R29-*.log` 是运行输出留档，非脚本）。
- **零付费、零外部依赖、未启 GPU job、未引入付费素材生成服务**；**不伪造产物、不谎报成功**（G3 4 条 ERROR / TFV 只跑一态 / §10.8 之外残留差异 / 两套历史色板并存均如实登记）；**未自行 git**（总指挥收尾）。
- **中文 UTF-8**；三段门禁 `--headless --import → --check-only --script → --headless --quit` 顺序执行、`grep SCRIPT ERROR=0` 达成；31 PASS 存档 / HUD 回归不回退。
