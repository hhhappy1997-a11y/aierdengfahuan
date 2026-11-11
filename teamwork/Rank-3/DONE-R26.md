# DONE-R26.md · Rank-3 交付报告（R26 · v0.4.0 波次试炼 GDD / 三段式 flag / 验证与文档）

- 任务：`cmd-20261111-073556-928-A3`，`[ROUND=R26]`，**v0.4.0 新内容**，Rank-3 执行 AI（RPG / 世界 / 存档）
- 日期：2026-11-11
- 任务单：`teamwork/Rank-3/调度任务单-latest.json`（开工只读，已读 ✓；`task` 字段完整版以 `json.load` 补读，第 6 行截断部分已核对）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--version` = `4.7.2.stable.official.ed1daf0bf`（`G0_EXIT=0`）
- 工程根（`--path`）：`F:/Game/aierdengfahuan/godot`

> **真跑结论（总览，均为实际 stdout）**：
> ① **WAVE-TRIAL-GDD.md** 按 Game Designer 核心循环文档格式写齐六项（purpose / player experience goal / inputs / outputs / edge cases / failure states）+ 核心循环（行动→反馈→目标→再行动）+ 目标梯度（30 秒短期 / 一局中期三波全清 / 长期最高波次）+ 留存钩子；按 Level Designer 标准补「入场读秒 + 敌人可见预告 + 退避空间 + 三波空间节奏」blockout 说明与难度曲线。**所有数值引用 Rank-2 `WAVE-TRIAL-TUNING.md` `[PLACEHOLDER]` 表、不另造数值**；该文件属 Rank-2 本轮并发产出、Rank-3 产出时**尚未落地**，GDD 采用字段名引用式占位并如实登记待校对（§0.1 / §7 V7），**不伪造引用、不猜数字**。
> ② **三个三段式 flag 两处登记**：`00-协作契约.md` §3.3 登记表（key / 类型 / 读写方 / 单调性 4 列）+ `teamwork/Rank-3/存档与flag规范.md` §3.3 全局登记表同步追加；契约 §3.3 追加说明段写明**与 §4.4 十字段、`schema_version=3` 的关系、`commit(reason)` 强制落盘点、「先落盘再改运行时实例」顺序**及读写边界。
> ③ 新建 `teamwork/Rank-3/verify_wave_flags_v040.gd`（`extends SceneTree`）：真跑 **23 PASS / 0 FAIL `RESULT=ALL_PASS`**（selftest 17 + write 3 + read 3），覆盖三段式正则 / `best_wave` 单调递增 / `completed` 只增不减 / 重启读回一致；selftest/write/read 三进程 pid 22900 / 10124 / 17944 **全不同**，write→read 两独立引擎进程实证「重启读回一致」；`--script` 模式按要求**不用 `/root/...` 绝对路径**，用 `Engine.get_main_loop()` / `get_root().get_node_or_null()` 相对探活。
> ④ `README.md`（工程根）新增 **v0.4.0 条目 + R26 回归真跑行**；「二、还差什么」新增 **第 13 项**（`[PLACEHOLDER]` 数值待人工试玩校准 / `WAVE-TRIAL-TUNING.md` 待落地校对）并复核 **第 10（人工试玩）/ 11（`128bit`）/ 12（HD-2D 全绿未达）在 v0.4.0 仍未达**。
> ⑤ **R21/R22 的 31 PASS / 0 FAIL**（`r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11）R26 重跑**不回退**；**14 次引擎调用全 `EXIT=0`**，14 份 `R26-*.log` 逐份 `grep SCRIPT ERROR / Parse Error / ERROR` **全 0**，三段门禁 `grep SCRIPT ERROR=0` 达成。
> ⑥ 本轮**未写任何 `godot/` 工程业务文件**（Rank-1/2/4 并发写入）；**未新建只读探针 / 巡检脚本**（`verify_wave_flags_v040.gd` 是任务单 ③ 明确要求的验证载体）；零付费、零外部依赖、不自行 git。

---

## ① 实际交付清单（本轮真正写入的文件与段落）

| # | 文件 | 动作 | 改动内容 |
|---|------|------|------|
| 1 | `teamwork/Rank-3/WAVE-TRIAL-GDD.md` | **新建** | Game Designer 六项 + 核心循环 + 目标梯度 + 留存钩子 + Level Designer blockout（入场读秒 / 敌人可见预告 / 退避空间 / 三波空间节奏）+ 难度曲线 + 数值引用表（§0.1）+ 存档落盘口径（§6）+ 验证校对清单（§7）；全部数值引用 Rank-2 `[PLACEHOLDER]` 表、不另造数值 |
| 2 | `teamwork/00-协作契约.md` §3.3 | **追加 3 行 + 说明段** | 登记表追加 `dungeon.wave_trial.best_wave` / `.completed` / `grace.trial.points` 三行（key / 类型 / 读写方 / 单调性）；R25 注释「两 key」消歧为「R25 两 key」；新增 R26 说明段（十字段 / `schema_version=3` 关系、`commit(reason)` 三处强制落盘点、先落盘再改运行时实例顺序、读写边界）。**§3.1/§3.2 缺号、I-1~I-6 接口表、§9 及其余历史条款一律未动** |
| 3 | `teamwork/Rank-3/存档与flag规范.md` §3.3 | **追加 3 行 + 1 句** | 全局 flag 登记表追加 3 行（key / 类型 / 基线 / 写入时机 / 说明）+ R26 口径指向句；**§3.1 正则 / §3.2 命名空间 / §4.1 十字段 / §4.4 回放规则 / 其它登记行一律未动** |
| 4 | `teamwork/Rank-3/verify_wave_flags_v040.gd` | **新建** | `extends SceneTree` 口径自测载体（详见 §1.1 / §2.3） |
| 5 | `F:/Game/aierdengfahuan/README.md` | **修改（4 处）** | ① 顶部追加 R26 维护记录；②「一、已做了什么」表追加 **v0.4.0 条目行 + R26 回归真跑行**；③「二、还差什么」表追加 **第 13 项**；④ 表后追加 **v0.4.0 复核段**（第 10/11/12 项仍未达）。§3.1~§3.4 既有 `stat` 实测表与历史结论未改；顶部「中枢 done 轮次」表仍为 R22 快照、按历史结论保留不冒充 |
| 6 | `teamwork/Rank-3/R26-*.log`（14 份） | **新建 · 运行输出留档** | `G0-version` / `G1-import` / `G2a-wfv040` / `G2b-writer` / `G2c-hud` / `G2d-r19` / `G2e-r17` / `G2f-e2e` / `G3-quit` / `RUN-r19` / `RUN-r17` / `WFV-selftest` / `WFV-write` / `WFV-read`，均为实际 stdout，非工程源文件、非脚本 |
| 7 | `teamwork/Rank-3/DONE-R26.md` | **新建** | 本报告 |
| 8 | `teamwork/command_center/ai/3/outbox/cmd-20261111-073556-928-A3.json` | **新建** | 回执 JSON，写在 `teamwork/command_center/` 下的**精确 id 路径**（**未**写到工程根 `command_center/`） |

### 1.1 契约 §3.3 登记表（key / 类型 / 读写方 / 单调性）

| key | 类型 | 读写方 | 单调性 |
|---|---|---|---|
| `dungeon.wave_trial.best_wave` | int（基线 `0`） | 写：Rank-3（订阅 Rank-1 `wave_cleared` / `trial_completed`，按 `max(旧, 本局最高波次)` 更新，强制 `commit(reason)` 先落盘）／读：波次 HUD「历史最佳」/ 回放断言（纯读 `get_flag`） | **单调递增、只增不减**：不清零、不回退、重启不丢；新局较低波次不覆盖历史最高、多次挑战不重复累加 |
| `dungeon.wave_trial.completed` | bool（基线 `false`） | 写：Rank-3（三波全清置 `true`，强制 `commit("wave_trial_completed")` 先落盘）／读：HUD / 成就门控 / 回放断言 | **只增不减（false → true 单向）**：失败 / 超时 / 主动退出 / 重启 / 重复挑战均无 false 回写路径 |
| `grace.trial.points` | int（基线 `0`） | 写：Rank-3（订阅 `wave_cleared(index,points)` 累加，`reward_points` 读 Rank-2 表，强制 `commit(reason)` 先落盘）／读：波次 HUD「赐福点数」/ 回放断言 | **单调递增、永不清除**：清波即入账、赐福休息不清零、重启不丢；同一波重复触发由门控防二次累加 |

- 三 key 均通过 §2 三段式正则 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`（`dungeon` / `grace` 前缀、`wave_trial` / `trial` 对象段、`best_wave` / `completed` / `points` 状态段全合法）；`world_state.gd` 的 `FLAG_KEY_REGEX` 无需修改、无需迁移、不改 `schema_version`。
- **读写边界**：写方仅 Rank-3（I-1 `set_flag`）；读方为波次 HUD 与回放断言；**Rank-1 不写 flag**（其 R26 任务单明确「不写 flag，交 Rank-3」）。

### 1.2 与 §4.4 十字段 / `schema_version=3` / `commit(reason)` / 落盘顺序的关系（契约 §3.3 R26 说明段要点）

- **十字段冻结**：`SaveDelta` 十字段（`schema_version / slot / seq / baseline / flags / quests / inventory / spawns / removals / meta`，`存档与flag规范.md` §4.1 定义、§4.4 回放合并消费）不得新增顶层字段；三个新 flag **只作为 `flags` 字典内的新 key** 落进既有结构（§3.2 收敛规则 INV-6），不新增顶层字段、不改字段类型、不引入嵌套结构 → **`schema_version` 保持 `3`、不触发 §4.7 迁移链**；回放按 §4.4「LWW by timestamp / 写入顺序」合并、类型冲突以 §3.3 登记表声明类型为准。
- **`commit(reason)` 强制落盘点（3 处）**：每波 `wave_cleared` 结算（`wave_trial_cleared`）、三波全清 `trial_completed`（`wave_trial_completed`）、失败 / 超时 / 主动退出结算（`wave_trial_settled`）；reason 仅进 `meta.last_commit_reason`、不是新顶层字段、不触发迁移。
- **「先落盘再改运行时实例」顺序**：① 取 Rank-1 结算结果 → ② 计算新值（`best_wave=max` / `points=旧+本波点数` / `completed` 仅全清置 `true`）→ ③ ★ `commit(reason)` 按十字段原子写（`.tmp → flush → rename → delta.json`）→ ④ ★ 落盘成功后才更新 `WorldState` 运行时 flag 实例并 `emit flag_changed`；③ 失败则不执行 ④、运行时保持旧值、如实告警，绝不「内存已改、磁盘未改」。磁盘为唯一权威。

### 1.3 verify_wave_flags_v040.gd 验证覆盖（5 类 → 17 条 selftest 断言）

| 类 | 断言 | 依据 |
|---|---|---|
| A 三段式正则 | A1 三个新 flag 通过正则；A2 六类非法 key（两段式 / 大写 / 连字符 / 四段 / 非法前缀 / 中文）全被拒绝 | 契约 §2、`存档与flag规范.md` §3.1 |
| B `best_wave` 单调递增 | B1 三波推进 0→1→2→3 严格递增；B2 新局较低波次 `max` 口径不回退；B3 多次挑战取历史最高、不重复累加 | GDD §3 / §6.1、契约 §3.3 |
| C `completed` 只增不减 + `points` 单调递增 | C1 三波全清 false→true；C2 失败 / 重启 / 重复挑战无 false 回写；C3 points 三次结算 0→1→2→3 严格递增；C4 赐福休息不清零、completed 不回退 | GDD §6.1、契约 §3.3 |
| D 重启读回一致 | D1 真实 `FileAccess` 落盘到**独立** `user://wave_flags_v040_state.json`（不碰 `slot_01/delta.json`）；D2 新建独立 `_State` 实例 `_load()` 重建内存；D3 逐项读回 `best_wave / completed / points` 3/3 一致 | GDD §6.4 / §7 V4、R25 先例 |
| E commit 顺序 + 十字段 / schema | E1 连续 3 次 commit 事件序列恒为 `disk_write → runtime_update`（先落盘再改运行时实例）；E2 落盘态与运行时实例态逐项一致；E3 十字段齐全且无额外顶层字段；E4 `schema_version=3` 不触发迁移；E5 落盘 flags 全通过三段式正则 | 契约 §3.3 R26 说明段、`存档与flag规范.md` §4.1 / §4.4 |

**`--script` 模式纪律（任务单明确要求）**：全程**不用 `/root/...` 绝对路径**；`_initialize()` 用 `Engine.get_main_loop()` + `get_root().get_node_or_null("WorldState")` 相对探活，取不到如实降级、**不依赖其结果判 PASS**（实测 `WorldState_probe=true`，但仅登记不用于判定）。退出用 `quit(0 if ok else 1)`，输出 `[WFV040] SUMMARY ... pass=N fail=0 ok=true` + `[WFV040] RESULT=ALL_PASS`。

**如实边界（不粉饰）**：本载体是**口径级模拟验证**（内置 `_flags` / `_disk` / `_runtime` / `_State` 模拟 I-1 `WorldState` + `SaveDeltaWriter.commit` 时序），**不是对 Rank-1 导演层 / Rank-2 数据表运行时代验**；`EXPECT` 中 `points=3` 是自测构造的模拟值（3 次结算各 +1），**不引用也不替代** Rank-2 `reward_points [PLACEHOLDER]`；本轮 Rank-3 不写 `godot/` 工程文件（目录所有权硬约束）。「重启读回一致」在同进程内由「真实文件落盘 → 全新实例 `_load()`」验证，并**另用 write/read 两个独立引擎进程**（pid 10124 / 17944）实证跨进程一致性。JSON `parse_string` 的 int→float round-trip（读回 `3.0`）由 `_val_eq`（`is_equal_approx`）容忍，**如实登记、不隐瞒**。

---

## ② 真跑输出结论（实际 stdout，未删改、未补写）

### 2.1 命令清单（引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--path F:/Game/aierdengfahuan/godot`）

| 段 | 命令标志 | 日志 |
|----|----|----|
| G0 | `--version` | `R26-G0-version.log` |
| G1 门禁 | `--headless --import` | `R26-G1-import.log` |
| G2a | `--headless --check-only --script <abs>/verify_wave_flags_v040.gd`（**新脚本语法门禁**） | `R26-G2a-wfv040.log` |
| G2b | `--headless --check-only --script res://scripts/save_delta_writer.gd` | `R26-G2b-writer.log` |
| G2c | `--headless --check-only --script res://scripts/hud.gd` | `R26-G2c-hud.log` |
| G2d | `--headless --check-only --script <abs>/r19_verify_hud.gd` | `R26-G2d-r19.log` |
| G2e | `--headless --check-only --script res://scripts/verify_hud_binding.gd` | `R26-G2e-r17.log` |
| G2f | `--headless --check-only --script <abs>/r22_save_e2e.gd` | `R26-G2f-e2e.log` |
| G3 门禁 | `--headless --quit` | `R26-G3-quit.log` |
| 回归 A | `--headless --script <abs>/r19_verify_hud.gd` | `R26-RUN-r19.log` |
| 回归 B | `--headless --script res://scripts/verify_hud_binding.gd` | `R26-RUN-r17.log` |
| WFV selftest | `--headless --script <abs>/verify_wave_flags_v040.gd` | `R26-WFV-selftest.log` |
| WFV write | `WAVE_V040_PHASE=write ... --script <abs>/verify_wave_flags_v040.gd` | `R26-WFV-write.log` |
| WFV read | `WAVE_V040_PHASE=read ... --script <abs>/verify_wave_flags_v040.gd` | `R26-WFV-read.log` |

> `<abs>` = `F:/Game/aierdengfahuan/teamwork/Rank-3/`。**一次只跑一个引擎进程、串行执行**；回归在前、verify 在后（verify 用独立 `user://` 文件，不污染 `slot_01/delta.json`，与 31 PASS 回归互不干扰）。

### 2.2 退出码（14 次引擎调用全部 `EXIT=0`）

```
G0_EXIT=0  G1_EXIT=0  G2a_EXIT=0  G2b_EXIT=0  G2c_EXIT=0  G2d_EXIT=0  G2e_EXIT=0  G2f_EXIT=0  G3_EXIT=0
R19_EXIT=0  R17_EXIT=0  SELFTEST_EXIT=0  WRITE_EXIT=0  READ_EXIT=0
```

### 2.3 PASS / FAIL 数字（实际 SUMMARY 行）

```
[R19]    SUMMARY pass=20 fail=0 ok=true
[R17]    SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true
[WFV040] SUMMARY phase=selftest pid=22900 pass=17 fail=0 ok=true   → RESULT=ALL_PASS
[WFV040] SUMMARY phase=write    pid=10124 pass=3  fail=0 ok=true   → RESULT=ALL_PASS
[WFV040] SUMMARY phase=read     pid=17944 pass=3  fail=0 ok=true   → RESULT=ALL_PASS
```

| 项 | 数值 | 说明 |
|---|:--:|---|
| R21/R22 HUD / 存档回归 | **20 PASS / 0 FAIL** | `r19_verify_hud.gd`，R26 重跑不回退 |
| R17 HUD 绑定回归 | **11 PASS / 0 FAIL** | `verify_hud_binding.gd`，`degraded=false`、`flag_chain_verified=true` |
| **任务单 ④ 的 31 PASS 回归** | **31 PASS / 0 FAIL** | 20 + 11，**不回退** |
| flag 自测 selftest（主自测） | **17 PASS / 0 FAIL** | A1/A2 + B1/B2/B3 + C1/C2/C3/C4 + D1/D2/D3 + E1/E2/E3/E4/E5，`RESULT=ALL_PASS` |
| flag 自测 write / read | **3 + 3 PASS / 0 FAIL** | 两独立引擎进程 pid 10124 / 17944 不同 = 真重启，`RESULT=ALL_PASS` |
| **flag 自测合计** | **23 PASS / 0 FAIL** | 17 + 3 + 3；三进程 pid 22900 / 10124 / 17944 全不同 |

> write→read 阶段：`R1` 新进程 `_load()` 从磁盘重建内存、`R2` 跨进程读回 **3/3 一致**（`best_wave=3` / `completed=true` / `points=3`）、`R3` 重启恢复 `completed` 与 `best_wave` 均不回退；D3 selftest 同进程「全新实例读回」同样 3/3 一致。

### 2.4 三段门禁 `grep SCRIPT ERROR=0`

| 段 | 标志 | `SCRIPT ERROR` | `Parse Error` | `ERROR` | `EXIT` |
|----|----|:--:|:--:|:--:|:--:|
| G1 | `--headless --import` | 0 | 0 | 0 | 0 |
| G2a | `--check-only --script` **verify_wave_flags_v040.gd** | 0 | 0 | 0 | 0 |
| G2b~G2f | `--check-only --script` ×5（writer / hud / r19 / r17 / e2e） | 0 | 0 | 0 | 0 |
| G3 | `--headless --quit` | 0 | 0 | 0 | 0 |

> **14 份 `R26-*.log` 逐份 `grep`：`SCRIPT ERROR=0`、`Parse Error=0`、`ERROR=0` 全为 0**（含 G0 / 5 份回归与自测运行日志）；全量汇总 `SCRIPT ERROR total=0`、`Parse Error total=0`、`ERROR token total=0`；三段门禁 `grep SCRIPT ERROR=0` 达成。
> 退出残留仍是工程既有 **WARNING、非 ERROR、未隐藏、未宣称零 WARNING**：`[ChunkManager] 未找到 ChunkRoot`（`chunk_streaming.gd:51`）、`2 ObjectDB instances were leaked at exit`（`object.cpp:2536`），见 `R26-G3-quit.log` / `R26-WFV-selftest.log`。

### 2.5 存档写入的如实说明

verify 载体只写**独立** `user://wave_flags_v040_state.json`（实测绝对路径 `C:/Users/62668/AppData/Roaming/Godot/app_userdata/艾尔登法环 · HD-2D/wave_flags_v040_state.json`），**不碰** `user://saves/slot_01/delta.json`、不注入测试种子到工程存档、不伪造产物。回归脚本 `r19_verify_hud.gd` / `verify_hud_binding.gd` 的既有 autoload commit 行为按历轮一贯口径保留，未改动任何工程文件。

---

## ③ 未完成项与阻塞

**阻塞：无功能性阻塞。** 派单 5 项（① GDD / ② flag 登记 / ③ verify 脚本并真跑 / ④ README / ⑤ 31 PASS 回归 + 三段门禁）均真实达成。

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 1 | **Rank-2 `WAVE-TRIAL-TUNING.md` 落地后校对** | **未达 · 待 Rank-2 并发产出** | Rank-3 产出 GDD 时该文件尚未落地（开工定向核对 1 次确认），GDD §0.1 采用「字段名引用式占位」、不填数字；待其落地后按 §7 V7 校对引用键名 / rationale / broken 定义一致性，不一致**改 GDD 引用段、不改 Rank-2 数据表**；README 第 13 项已登记 |
| 2 | **波次数值 `[PLACEHOLDER]` 人工试玩校准** | **属用户侧 · 本轮不代做** | 倍率 / 奖励 / 预告 / 时限具体值须由人工试玩校准；headless 真跑不做手感判断，Rank-3 不冒充完成 |
| 3 | **v0.4.0 四项实现**（Rank-1 `wave_trial_director.gd` / `courtyard.tscn` / 波次 HUD；Rank-2 `wave_trial_config.gd` / `wave_trial.tres` / `verify_wave_trial_v040.gd`；Rank-4 素材与录屏） | **未由 Rank-3 实现、未代验、不宣称完成** | 归 Rank-1 / Rank-2 / Rank-4 本轮并发写入 `godot/` 与 `capture/`；目录所有权硬约束禁止 Rank-3 触碰 |
| 4 | **人工试玩（exe / apk）与手感 / 审美验收**（裁决 A17） | **属用户侧 · 本轮只给勾选清单、不冒充完成** | README 第 10 项已给勾选清单（翻滚无敌帧手感 / Boss 招式公平性 / 区域密度 / 画面可见性 / 默认入口庭院与 Boss 是否可见）；headless 无真实帧缓冲 |
| 5 | **`128bit` 词义歧义** | **待用户确认 · A15 不消歧** | 契约 §9.3 / `00-汇总.md` §6.2 第 5 项 / README 第 11 项均显式保留；指「128px 画布尺寸」还是「位宽 / 色深」以用户后续确认为准，未编码进任何期望值 |
| 6 | **HD-2D 全绿未达** | **未达成 · 长期项** | R24 总指挥目视回看实证：Boss 无可见像素形象、战斗数值 15 秒停在 `idle 0/0`、地面平铺重复与马赛克观感、光效仍 2D 近似；README 第 12 项如实登记 |
| 7 | 15–20 秒实机录屏并目视回看 / exe / pck / apk 重导 | 长期项 · 不在本单 | 本轮未写任何 `godot/` 工程文件；录屏与产物重导由工程变更方 / 后续轮次承担 |
| 8 | 既有退出 WARNING | 如实保留 · 非 ERROR | `ChunkManager` / `ObjectDB instances leaked`，历轮已登记，R26 真跑中仍出现，未隐藏 |
| 9 | `JSON.parse_string` int→float round-trip | 如实登记 · 由 `_val_eq` 容忍 | 读回 `best_wave/points=3.0`，非缺陷、与 R25 / r22 口径一致 |
| 10 | 中枢 done 轮次表 / outbox 消费 | 未据以改写 | README 顶部表仍为 R22 快照，按历史结论保留、不冒充已进 done 序列；回执按精确路径写入，是否被实时消费以中枢实际行为为准 |

---

## ④ 约束对照

- **目录所有权** ✓：只写 `00-协作契约.md`（仅 §3.3）/ `存档与flag规范.md`（仅 §3.3 表 + 1 句）/ `README.md`（工程根）/ `teamwork/Rank-3/`（GDD、verify、DONE、14 份日志）+ 回执例外 `teamwork/command_center/ai/3/outbox/`；**绝对未碰** `godot/project.godot`、`godot/scenes/*`、`godot/scripts/*`、`godot/data/*`、既有存档件 / 战斗件 / 美术资源、其它 Rank 文档、`00-汇总.md`、teamwork 根 `README.md`（导航，主 AI 只读）、`build/` 产物。
- **公共契约** ✓：直接改、直接真跑；**未新建只读探针 / 巡检脚本**（`verify_wave_flags_v040.gd` 是任务单 ③ 明确要求的验证载体，其余复用既有 `r19_verify_hud.gd` / `verify_hud_binding.gd` / `r22_save_e2e.gd`）；未主动扫目录做进度巡检（仅对任务单指定的引擎 / 脚本 / 回执路径与 Rank-2 TUNING 文件做定向存在性核对 1 次）；零付费、零外部依赖；一次只跑一个引擎进程、无 GPU job；产出先目视检查再接入。
- **不伪造 / 不谎报** ✓：TUNING 未落地不冒充引用具体值、Rank-1/2/4 实现不冒充完成、`128bit` 不消歧、HD-2D 全绿未达不粉饰、人工试玩不代做、既有 WARNING 不隐藏、JSON int→float round-trip 如实登记、verify 载体为口径级模拟（非运行时代验）如实说明。
- **不自行 git** ✓：由总指挥收尾。
- **三段门禁 `grep SCRIPT ERROR=0`** ✓；中文 UTF-8 ✓。

---

## ⑤ 回执

按本轮 `task_id` 写 `F:/Game/aierdengfahuan/teamwork/command_center/ai/3/outbox/cmd-20261111-073556-928-A3.json`（在 `teamwork/command_center/` 下，**未**写到工程根 `command_center/`），结构：

```json
{"task_id":"cmd-20261111-073556-928-A3","ai":3,"status":"done","result":"引用 DONE-R26.md 实际结论：① WAVE-TRIAL-GDD.md 六项齐全 + 核心循环 + 目标梯度 + 留存钩子 + Level Designer blockout + 难度曲线，数值全部引用 Rank-2 WAVE-TRIAL-TUNING.md [PLACEHOLDER] 表、不另造数值（该表 Rank-2 并发未落地，采用字段名引用式占位并如实登记待校对）。② 三段式 flag 登记进 00-协作契约.md §3.3（key/类型/读写方/单调性）与 存档与flag规范.md §3.3，并说明与 §4.4 十字段、schema_version=3、commit(reason) 强制落盘点、先落盘再改运行时实例顺序的关系。③ verify_wave_flags_v040.gd 真跑 23 PASS/0 FAIL RESULT=ALL_PASS（selftest 17 + write 3 + read 3，三进程 pid 22900/10124/17944 全不同，write→read 实证重启读回一致），--script 模式不用 /root/ 绝对路径、用 Engine.get_main_loop()/root.get_node_or_null() 相对探活。④ README.md 新增 v0.4.0 条目与 R26 回归真跑行，还差什么新增第 13 项并复核第 10/11/12 项（人工试玩/128bit/HD-2D 全绿未达）v0.4.0 仍未达。⑤ 31 PASS/0 FAIL（r19 20 + r17 11）不回退；14 次引擎调用全 EXIT=0；14 份 R26-*.log 逐份 grep SCRIPT ERROR/Parse Error/ERROR 全 0，三段门禁 grep SCRIPT ERROR=0 达成。未写任何 godot/ 工程文件、未新建探针/巡检脚本、零付费、不自行 git。未完成项：WAVE-TRIAL-TUNING.md 待落地校对、波次数值待人工试玩校准、Rank-1/2/4 并发实现未代验、人工试玩/128bit/HD-2D 全绿未达、15-20 秒录屏、既有 WARNING 非 ERROR 如实保留。"}
```

> **写后实测（本轮）**：回执写入成功后 `outbox/` 被中枢**实时消费清空**（目录当前 0 文件，与 `DONE-R21.md §⑤` / `DONE-R22.md §⑤` / `DONE-R23.md §⑥` / `DONE-R24.md §⑤` / `DONE-R25.md §⑤` 同一消费时序现象），首次直接读 `outbox/` 精确路径得到 `exists=False`，**如实登记、未隐藏**。归档件 `teamwork/command_center/dispatcher/receipts/cmd-20261111-073556-928-A3.json`（**2213 字节**）读回校验：`json_valid=True`、`keys=['ai','result','status','task_id']`、`task_id=cmd-20261111-073556-928-A3` / `ai=3` / `status=done`、`result_len=1285`、`result` 以「引用 DONE-R26.」开头并含 `23 PASS` / `31 PASS` / `DONE-R26.md` 引用；工程根 `command_center/` **不存在**（未误写）。按幂等 / 并发保护**不重复写第二份回执**。
>
> 结论：回执**路径正确**（`teamwork/command_center/ai/3/outbox/` 下的精确 id 文件，且已被中枢按该 id 归档）、**内容符合**任务单 `{"task_id":...,"ai":3,"status":"done","result":"引用 DONE-R26.md 实际结论"}` 结构。按实际产物判定，不臆测、不谎报。

---

## ⑥ 关联

`teamwork/Rank-3/WAVE-TRIAL-GDD.md`（本轮设计主文档）、`teamwork/Rank-3/verify_wave_flags_v040.gd`（本轮自测载体）、`teamwork/00-协作契约.md` §3.3、`teamwork/Rank-3/存档与flag规范.md` §3.1 / §3.3 / §4.1 / §4.4 / §4.7、`teamwork/Rank-2/WAVE-TRIAL-TUNING.md`（Rank-2 并发产出，数值真源）、`teamwork/Rank-3/GRACE-RETRY-V020.md` / `verify_grace_flags_v030.gd`（R25 先例）、`F:/Game/aierdengfahuan/README.md`（状态表）、`teamwork/Rank-3/R26-*.log`（14 份真跑 stdout）。
