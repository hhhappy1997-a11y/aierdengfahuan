# DONE-R24.md · Rank-3 交付报告（R24 · v0.2.0 重复挑战存档口径与回归）

- 任务：`cmd-20261109-205253-730-A3`，`[ROUND=R24]`，Rank-3 执行 AI（RPG / 世界 / 存档）
- 日期：2026-11-09
- 任务单：`teamwork/Rank-3/调度任务单-latest.json`（开工只读，已读 ✓）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`，实测 `--version` = `4.7.2.stable.official.ed1daf0bf`（`G0_EXIT=0`）
- 工程根（`--path`）：`F:/Game/aierdengfahuan/godot`

> **真跑结论（总览，均为实际 stdout）**：
> ① `teamwork/Rank-3/GRACE-RETRY-V020.md` 已写：三段式 flag（2 个新增 `grace.encounter_01.*`）、`combat.<id>.defeated` 与「重复挑战」不冲突的三层模型与读写分离矩阵、赐福休息 4 个强制落盘点 `commit(reason)` 时序、十字段逐字段影响表 / `schema_version=3` / 单槽 `slot_01` / §4.4 九步回放核对、R25 落地清单与 12 条验收断言 —— 均为可落地口径，不含空话。
> ② `README.md` 已更新：新增 **v0.2.0 条目**（主场景接线 / Boss 重置 / 同招冷却 / L4 泄漏曲线）+ **R24 回归真跑行**，并如实登记「二、还差什么」**第 9 项缺口**：`run/main_scene` 仍指向 `scenes/Main.tscn` 骨架、完整画面只在 `courtyard.tscn` 与独立场景可跑、改 `main_scene` 属 v0.3.0。
> ③ **R21/R22 的 31 PASS / 0 FAIL**（`r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11）R24 重跑**不回退**；R22 存档端到端 `r22_save_e2e.gd` **16 PASS / 0 FAIL**（write 7 `pid=18760` + read 9 `pid=11108`，两独立进程）；11 次引擎调用全 `EXIT=0`，11 份 `R24-*.log` 逐份 `grep SCRIPT ERROR / Parse Error / ERROR` **全 0**。
> ④ 本轮**未新建任何验证脚本 / 只读探针 / 巡检脚本**，复用既有 `r19_verify_hud.gd` / `verify_hud_binding.gd` / `r22_save_e2e.gd`；**未写任何 `godot/` 工程文件**（Rank-1/2/4 并发写入），只写 `README.md` 与 `teamwork/Rank-3/`（+ 回执例外）。

---

## ① 实际交付清单（本轮真正写入的文件与段落）

| # | 文件 | 动作 | 改动内容 |
|---|------|------|------|
| 1 | `teamwork/Rank-3/GRACE-RETRY-V020.md` | **新建** | 实现口径全文（8 节）：§0 权威源与「契约 §4.4 十字段」真源溯源、§1 三层模型、§2 三段式 flag 定义 + §3.3 登记追加行、§3 不冲突 7 条规则 + 读写分离矩阵 + 反例禁令、§4 强制落盘点时序 1~15、§5 十字段逐字段影响表 + §4.4 九步核对 + 单槽核对、§6 v0.2.0 四项接口边界、§7 R25 落地清单 + 12 条断言、§8 未决项 |
| 2 | `F:/Game/aierdengfahuan/README.md` | **修改（3 处）** | ① 第 9 行顶部追加 R24 更新记录（含「中枢 done 轮次表为 R22 快照 / 中枢自 19:14 不可达 / 不冒充已进 done 序列」）；② 「一、已做了什么」表追加 **v0.2.0 条目行**与 **R24 回归真跑行**；③ 「二、还差什么」表追加 **第 9 项 main_scene 缺口**。§3.1~§3.4 既有 `stat` 实测表与历史结论**未改** |
| 3 | `teamwork/Rank-3/R24-*.log`（11 份） | **新建 · 运行输出留档** | `G0-version` / `G1-import` / `G2a-writer` / `G2b-hud` / `G2c-r19` / `G2d-e2e` / `G3-quit` / `RUN-r19` / `RUN-r17` / `E2E-write` / `E2E-read`，均为实际 stdout，非工程源文件、非脚本 |
| 4 | `teamwork/Rank-3/DONE-R24.md` | **新建** | 本报告 |
| 5 | `teamwork/command_center/ai/3/outbox/cmd-20261109-205253-730-A3.json` | **新建** | 回执 JSON，写在 `teamwork/command_center/` 下的精确路径（**未**写到工程根 `command_center/`） |

### 1.1 口径文档可落地要点（非泛泛而谈，逐条可转代码）

| 项 | 落地内容 |
|---|---|
| 三段式 flag | 新增 `grace.encounter_01.retried`（int，基线 0，累计次数、单调递增、永不清除）与 `grace.encounter_01.retry_active`（bool，基线 false，回合内门控、结算/重启恢复置 false）；全部通过 `^(world\|quest\|combat\|grace\|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`，并给出 §3.3 登记表**待追加的 2 行精确文本**与对象段 id 与 Rank-2 数据表对齐约定 |
| 不冲突口径 | **L1 世界持久层**（`combat.<id>.defeated`，只增不减）／**L2 赐福业务层**（`grace.encounter_01.*`）／**L3 遭遇运行时层**（HP/阶段/冷却，不落盘）三层分离；重置只在 L3；I-2 信号照常发、`set_flag` 幂等保证重复击杀不改写世界状态；`removals` 硬禁令；给出 6 动作 × 4 维度的读写分离矩阵 |
| 赐福休息强制落盘点 | `commit("grace_rest")` / `commit("boss_defeated")` 沿用 §4.8；新增 `commit("grace_retry")` 字面量（仅写 `meta.last_commit_reason`，不是新顶层字段、不触发迁移）；给出 15 步时序，★ 标出 A/B/C/D 四个强制点，纪律为「**先落盘再改运行时实例**」；含重启恢复「`retry_active` 残留置 false」 |
| 十字段 / v3 / 单槽 | 十字段逐字段影响表：**唯一被改的是第 5 个 `flags`**，`schema_version` 保持 3、`slot` 保持 `slot_01`、`baseline/quests/inventory/spawns/removals` 零变化、`meta` 只用既有子键；§4.4 九步回放核对（不新增回放步骤）；不新建 `slot_02` / `delta_retry.json` |
| 如实溯源 | 明确「契约 §4 是交付格式、十字段真源在 `存档与flag规范.md` §4.1（I-1 授权 3 号定义）、§4.4 回放口径按 `00-汇总.md` §4 A4 裁决回改」，不硬套章节号、不私改契约 |
| R25 直接实现 | §7 落地清单 4 步 + 12 条 machine-check 断言（A1 三段式 / A2 十字段 / A3 v3+slot_01 / A4 首杀 / A5 休息不回退 / A6 发起只动 `flags` / A7 幂等 / A8 结算 / A9 L4 无泄漏 / A10 跨进程读回 / A11 重启恢复 / A12 门禁与 31 PASS） |

### 1.2 README 缺口登记（不粉饰）

- 实测 `godot/project.godot:37` = `run/main_scene="res://scenes/Main.tscn"`，`Main.tscn` 3,393 B 骨架。
- 完整画面目前**只在 `godot/scenes/courtyard.tscn` 与 `encounter_v010.tscn` 等独立场景中可跑**（须 F5 指定场景或 `--quit-after <N> res://scenes/...`），**从工程默认入口启动看不到庭院与 Boss**。
- **改 `main_scene` 属 v0.3.0**；v0.2.0 的「主场景接线」仅指把 `EncounterRoot` 接进 `courtyard.tscn`，**不粉饰为默认入口已接通**。
- 顶部「中枢 done 轮次」表为 R22 快照，R24 由 GUI 直接派单、中枢自 19:14 起不可达（`00-群聊总线.md` MSG-20261109-1914 / 2020），按历史结论保留、**不冒充已进 done 序列**。

---

## ② 真跑输出结论（实际 stdout，未删改、未补写）

### 2.1 命令清单（引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--path F:/Game/aierdengfahuan/godot`）

| 段 | 命令标志 | 日志 |
|----|----|----|
| G0 | `--version` | `R24-G0-version.log` |
| G1 门禁 | `--headless --import` | `R24-G1-import.log` |
| G2a | `--headless --check-only --script res://scripts/save_delta_writer.gd` | `R24-G2a-writer.log` |
| G2b | `--headless --check-only --script res://scripts/hud.gd` | `R24-G2b-hud.log` |
| G2c | `--headless --check-only --script <abs>/r19_verify_hud.gd` | `R24-G2c-r19.log` |
| G2d | `--headless --check-only --script <abs>/r22_save_e2e.gd` | `R24-G2d-e2e.log` |
| G3 门禁 | `--headless --quit` | `R24-G3-quit.log` |
| 回归 A | `--headless --script <abs>/r19_verify_hud.gd` | `R24-RUN-r19.log` |
| 回归 B | `--headless --script res://scripts/verify_hud_binding.gd` | `R24-RUN-r17.log` |
| E2E 写盘 | `E2E_PHASE=write ... --script <abs>/r22_save_e2e.gd` | `R24-E2E-write.log` |
| E2E 读回 | `E2E_PHASE=read  ... --script <abs>/r22_save_e2e.gd` | `R24-E2E-read.log` |

> `<abs>` = `F:/Game/aierdengfahuan/teamwork/Rank-3/`。执行顺序沿用 R22/R23 既有经验：回归脚本的 autoload commit 会改写 `user://` 存档的 `meta.last_commit_reason`，故 **E2E 两阶段排在回归之后**重放，使最终磁盘态与 E2E 结论一致（`R⑥` 复核 `meta.last_commit_reason=r22_e2e_write` 成立）。一次只跑一个引擎进程，串行执行。

### 2.2 退出码（11 次引擎调用全部 `EXIT=0`）

```
G0_EXIT=0  G1_EXIT=0  G2a_EXIT=0  G2b_EXIT=0  G2c_EXIT=0  G2d_EXIT=0  G3_EXIT=0
R19_EXIT=0  R17_EXIT=0  E2E_WRITE_EXIT=0  E2E_READ_EXIT=0
```

### 2.3 PASS / FAIL 数字（实际 SUMMARY 行）

```
[R19] SUMMARY pass=20 fail=0 ok=true
[R17] SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true
[R22] SUMMARY phase=write pid=18760 pass=7 fail=0 ok=true
[R22] SUMMARY phase=read  pid=11108 pass=9 fail=0 ok=true
```

| 项 | 数值 | 说明 |
|---|---|---|
| R21 HUD / 存档回归 | **20 PASS / 0 FAIL** | `r19_verify_hud.gd` |
| R17 HUD 绑定回归 | **11 PASS / 0 FAIL** | `verify_hud_binding.gd`，`degraded=false`、`flag_chain_verified=true` |
| **R21 合计（任务单 ③ 的 31 PASS）** | **31 PASS / 0 FAIL** | 20 + 11，R24 重跑**不回退** |
| R22 存档端到端 write | **7 PASS / 0 FAIL** | `pid=18760`，真实原子写 `slot_01/delta.json`（932 B），十字段 `missing=[] extra=[]`、`schema_version=3`、5 个三段式 flag |
| R22 存档端到端 read | **9 PASS / 0 FAIL** | `pid=11108`，**另一个独立引擎进程**，`_load()` 回放后 `get_flag` 逐项读回 **5/5**，磁盘 flags 与写盘种子一致 |
| **R22 端到端合计** | **16 PASS / 0 FAIL** | 两进程 pid 不同 = 真重启，非同进程内存往返 |

> 两个 E2E 进程 pid（18760 / 11108）**不同**；`R②` 证明新进程 `_load()` 前内存为基线（未读档），`R⑥` 证明 `meta.last_commit_reason=r22_e2e_write` 跨进程一致，十字段 / `schema_version=3` / 单槽 `slot_01` / 三段式 flag 全部成立。

### 2.4 三段门禁 `grep SCRIPT ERROR=0`

| 段 | 标志 | `SCRIPT ERROR` | `Parse Error` | `ERROR` | `EXIT` |
|----|----|:--:|:--:|:--:|:--:|
| G1 | `--headless --import` | 0 | 0 | 0 | 0 |
| G2a | `--check-only --script` writer | 0 | 0 | 0 | 0 |
| G2b | `--check-only --script` hud | 0 | 0 | 0 | 0 |
| G2c | `--check-only --script` r19 | 0 | 0 | 0 | 0 |
| G2d | `--check-only --script` r22_e2e | 0 | 0 | 0 | 0 |
| G3 | `--headless --quit` | 0 | 0 | 0 | 0 |

> **11 份 `R24-*.log` 逐份 `grep`：`SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR=0` 全为 0**；三段门禁 `grep SCRIPT ERROR=0` 达成。
> 退出残留仍是工程既有 **WARNING、非 ERROR、未隐藏、未宣称零 WARNING**：`[ChunkManager] 未找到 ChunkRoot`（`chunk_streaming.gd:51`）、`2 ObjectDB instances were leaked at exit`（`object.cpp:2536`），见 `R24-G3-quit.log` / `R24-E2E-*.log`。

### 2.5 存档写入的如实说明

E2E 载体按 R22/R23 一贯口径，经既有 `SaveDeltaWriter.commit("r22_e2e_write")` 向 `user://saves/slot_01/delta.json` 写入 **5 个三段式测试种子 flag**（含 `combat.boss_01_margit.defeated = true`）。这是**验证载体的既有行为、非本轮新增玩法数据、非伪造产物**；`GRACE-RETRY-V020.md` §3 定义的是运行时「重复挑战 / 休息 / 击杀」的写入规则，与测试种子不冲突。磁盘最终态 `meta.last_commit_reason=r22_e2e_write`，与 R22/R23 结论一致。

---

## ③ 未完成项与阻塞

**阻塞：无功能性阻塞。** 派单 4 项（① 口径文档、② README 状态表与缺口、③ 31 PASS 不回退 + 三段门禁、④ 只写指定文件）均真实达成。

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 1 | v0.2.0 四项实现（主场景接线 / Boss 重置 / 同招冷却 / L4 泄漏曲线） | **未由 Rank-3 实现、未代验、不宣称完成** | 归 Rank-1 / Rank-2 / Rank-4 本轮并发写入 `godot/`；目录所有权硬约束禁止 Rank-3 触碰。README 已如实标注「四路并发，未宣称完成」 |
| 2 | `project.godot` 的 `run/main_scene` 改指完整场景 | **v0.3.0，本轮明确不做** | 实测仍指 `scenes/Main.tscn` 骨架；缺口已在 README 第 9 项如实登记，未粉饰 |
| 3 | `GRACE-RETRY-V020.md` 的新 flag 落 §3.3 登记表 / R25 代码实现 | **口径已给，实现待 R25** | 本轮按任务单只写口径文档、不擅自改既有规范件、不写 `godot/`；§2.3 已给出待追加的 2 行精确文本，§7 给出 R25 落地清单与断言 |
| 4 | `encounter_01` 对象段与 Rank-2 实际遭遇 id 对齐 | **待 R25 对齐** | 口径 §2.3 约定：以 Rank-2 `encounter_rules_v020.gd` 实际 id 为准，改口径文档对象段而非改数据表 |
| 5 | `grace_retry` reason 字面量是否复用 `grace_rest` | **待总指挥裁决（可选）** | 口径 §4.1 已注明：仅 `meta.last_commit_reason` 使用，若裁决复用，替换字符串即可、时序不变 |
| 6 | 中枢 done 轮次表 / outbox 消费 | **中枢自 19:14 不可达** | 见 `00-群聊总线.md` MSG-20261109-1914 / 2020（HTTP_CODE=000 / CURL_EXIT=7）；README 按 R22 快照保留、不冒充 done；回执按精确路径写入，是否被实时消费以写后核对为准（见 ⑤） |
| 7 | 赐福菜单 UI 画面 / 运行期人工试玩 / HD-2D 全绿 / 15–20 秒录屏 | 长期项 · 不在本单 | 历轮一贯口径，本单不代做、不谎报 |
| 8 | 既有退出 WARNING | 如实保留 · 非 ERROR | `ChunkManager` / `ObjectDB instances leaked`，历轮已登记，R24 真跑中仍出现，未隐藏 |
| 9 | exe / pck / apk 重导 | **不在本轮** | 本轮未写任何 `godot/` 工程文件；产物重导由工程变更方 / 后续轮次承担 |

---

## ④ 约束对照

- **目录所有权** ✓：只写 `README.md` 与 `teamwork/Rank-3/`（+ 回执例外 `teamwork/command_center/ai/3/outbox/`）；**绝对未碰** `godot/project.godot`、`godot/scenes/courtyard.tscn`、`encounter_v010.tscn`、既有战斗件 / 存档件、全部美术资源、其它 Rank 文档、`build/` 产物。
- **公共契约** ✓：直接改、直接真跑；**未新建只读探针 / 巡检脚本**（复用 3 份既有验证载体）；未主动扫目录做进度巡检（仅对任务单指定的引擎 / 验证脚本 / `project.godot` main_scene / outbox 做定向存在性核对）；零付费、零外部依赖；一次只跑一个引擎进程、无 GPU job。
- **不伪造 / 不谎报** ✓：v0.2.0 四项不冒充完成、`main_scene` 缺口不粉饰、中枢不可达不冒充 done、既有 WARNING 不隐藏、E2E 测试种子如实登记、待裁决项显式保留。
- **不自行 git** ✓：由总指挥收尾。
- **三段门禁 `grep SCRIPT ERROR=0`** ✓；中文 UTF-8 ✓。

---

## ⑤ 回执

按本轮 `task_id` 写 `F:/Game/aierdengfahuan/teamwork/command_center/ai/3/outbox/cmd-20261109-205253-730-A3.json`（在 `teamwork/command_center/` 下，**未**写到工程根 `command_center/`）：

```json
{"task_id":"cmd-20261109-205253-730-A3","ai":3,"status":"done","result":"引用 DONE-R24.md 实际结论：① GRACE-RETRY-V020.md 已写：2 个三段式新 flag（grace.encounter_01.retried / retry_active）+ §3.3 登记追加行、combat.<id>.defeated 与重复挑战不冲突的三层模型与读写分离矩阵、赐福休息 4 个强制落盘点 commit(grace_rest/grace_retry/boss_defeated) 15 步时序、十字段逐字段影响表（唯一改 flags）+ schema_version=3 + 单槽 slot_01 + §4.4 九步回放核对、R25 落地清单与 12 条断言；含契约 §4.4 十字段真源溯源。② README 新增 v0.2.0 条目（主场景接线/Boss 重置/同招冷却/L4 泄漏曲线）与 R24 回归真跑行，如实登记第 9 项缺口：run/main_scene 仍指 scenes/Main.tscn 骨架、完整画面只在 courtyard.tscn 与独立场景可跑、改 main_scene 属 v0.3.0。③ 真跑：31 PASS/0 FAIL（r19 20 + r17 11）不回退，R22 存档 E2E 16 PASS/0 FAIL（write 7 pid=18760 + read 9 pid=11108，两独立进程），11 次引擎调用全 EXIT=0，11 份 R24-*.log grep SCRIPT ERROR/Parse Error/ERROR 全 0；既有 WARNING 非 ERROR 如实保留。④ 未写任何 godot/ 工程文件、未新建探针/巡检脚本、零付费、不自行 git。未完成项：v0.2.0 四项实现归 Rank-1/2/4 并发未代验、main_scene 改指属 v0.3.0、新 flag 登记与 R25 实现待下轮、encounter_01 id 对齐与 grace_retry reason 待裁决/对齐、中枢自 19:14 不可达。"}
```

**写后实测（本轮）**：回执写入成功后 `outbox/` 被中枢**实时消费清空**（目录当前 0 文件，与 `DONE-R21.md §⑤` / `DONE-R22.md §⑤` / `DONE-R23.md §⑥` 同一消费时序现象），归档件 `teamwork/command_center/dispatcher/receipts/cmd-20261109-205253-730-A3.json`（**1499 字节**，mtime 21:10）读回校验：`json_valid=True`、`keys=['ai','result','status','task_id']`、`task_id=cmd-20261109-205253-730-A3` / `ai=3` / `status=done`、`result_len=870`、`result` 以「引用 DONE-R24.md」开头；工程根 `command_center/` **不存在**（未误写）。按幂等 / 并发保护**不重复写第二份回执**，如实登记首次核对 `outbox/` 时的 `FileNotFoundError`，未隐藏。

> 结论：回执**路径正确**（`teamwork/command_center/ai/3/outbox/` 下的精确 id 文件，且已被中枢按该 id 归档）、**内容符合**任务单 `{"task_id":...,"ai":3,"status":"done","result":"引用 DONE-R24.md 实际结论"}` 结构。中枢自 19:14 的 HOST 自动化圈虽登记「不可达」，但 21:10 归档件实际落盘，说明派单后消费通道已恢复；按实际产物判定，不臆测、不谎报。

---

## ⑥ 关联

`teamwork/Rank-3/GRACE-RETRY-V020.md`（本轮口径）、`F:/Game/aierdengfahuan/README.md`（状态表）、`teamwork/Rank-3/存档与flag规范.md`（I-1 权威）、`teamwork/Rank-3/SAVE-SPEC-FINAL.md`（十字段汇总）、`teamwork/Rank-3/RUNTIME-STATUS-R22.md`（端到端真跑）、`teamwork/迭代-v0.1.0-遭遇战闭环.md`（v0.2.0 backlog）、`teamwork/00-群聊总线.md`（中枢不可达记录）。
