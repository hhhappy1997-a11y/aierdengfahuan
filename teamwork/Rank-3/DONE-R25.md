# DONE-R25.md · Rank-3 交付报告（R25 · v0.3.0 方向 4：契约口径 A15 + 重复挑战 flag 登记与验证）

- 任务：`cmd-20261110-204604-840-A3`，`[ROUND=R25]`，**v0.3.0 方向 4**，Rank-3 执行 AI（RPG / 世界 / 存档）
- 日期：2026-11-10
- 任务单：`teamwork/Rank-3/调度任务单-latest.json`（开工只读，已读 ✓）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--version` = `4.7.2.stable.official.ed1daf0bf`（`G0_EXIT=0`）
- 工程根（`--path`）：`F:/Game/aierdengfahuan/godot`

> **真跑结论（总览，均为实际 stdout）**：
> ① **裁决 A15 落地**：`teamwork/00-协作契约.md` §9.3 的 I-5 色数口径由「256 色以上 / 单帧 ≥256」统一为「**项目级色库 ≥256 色、单帧强制 ≤16 色索引、RGBA 保 alpha、128px 基准画布**」；`128bit` 歧义**仍显式保留、不消歧、不编码进期望值、待用户确认**；`00-汇总.md` §6.2 **只改第 5 行待确认项**、其它历史条款（含第 8 行 R24 遗留快照）未动。
> ② 两个三段式 flag **两处登记**：`00-协作契约.md` **新增 §3.3 登记表**（key / 类型 / 读写方 / 单调性 4 列）+ `teamwork/Rank-3/存档与flag规范.md` §3.3 全局登记表**追加 §2.3 的 2 行**（兑现 GRACE-RETRY-V020.md §7.1 落地清单第 1 条）。
> ③ 新建 `teamwork/Rank-3/verify_grace_flags_v030.gd`（`extends SceneTree`）：真跑 **16 PASS / 0 FAIL `RESULT=ALL_PASS`**（selftest 10 + write 3 + read 3）；selftest/write/read 三进程 pid 不同（34108 / 41208 / 37940），**write→read 两独立引擎进程实证「重启读回一致」**；`--script` 模式按要求**不用 `/root/...` 绝对路径**，用 `Engine.get_main_loop()` / `get_root().get_node_or_null()` 相对探活。
> ④ `README.md`（工程根）新增 **v0.3.0 方向 4 条目 + R25 回归真跑行**，「二、还差什么」新增 **第 10 / 11 / 12 项**（人工试玩属用户侧 A17 / `128bit` 待确认 / HD-2D 全绿未达）。
> ⑤ **R21/R22 的 31 PASS / 0 FAIL**（`r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11）R25 重跑**不回退**；**13 次引擎调用全 `EXIT=0`**，13 份 `R25-*.log` 逐份 `grep SCRIPT ERROR / Parse Error / ERROR` **全 0**，三段门禁 `grep SCRIPT ERROR=0` 达成。
> ⑥ 本轮**未写任何 `godot/` 工程文件**（Rank-1/2/4 并发写入）；**未新建只读探针 / 巡检脚本**（`verify_grace_flags_v030.gd` 是任务单 ③ 明确要求的验证载体）；零付费、零外部依赖、不自行 git。

---

## ① 实际交付清单（本轮真正写入的文件与段落）

| # | 文件 | 动作 | 改动内容 |
|---|------|------|------|
| 1 | `teamwork/00-协作契约.md` §9.3 | **修改** | A15 口径：标题 / 导语标注「R25 裁决 A15 统一口径」；像素素材规格 bullet 改为「色数两层口径（项目级色库 ≥256 下限 + 单帧强制 ≤16 色索引上限，原单帧 ≥256 废止）／128px 基准画布不变／RGBA 保 alpha／`128bit` 歧义显式保留待确认」；**DNF 合规边界段、§3 I-1~I-6 接口表、§9.1/§9.2、其余历史条款一律未动** |
| 2 | `teamwork/00-协作契约.md` §3.3 | **新增子节** | 「三段式 flag 登记表（R25 / v0.3.0 方向 4）」：4 列（key / 类型 / 读写方 / 单调性）登记 `grace.encounter_01.retried` 与 `.retry_active`；附真源链、三段式正则合法性、`encounter_01` 与 Rank-2 遭遇 id 对齐约定、`128bit` 无关声明 |
| 3 | `teamwork/00-汇总.md` §6.2 | **修改（仅第 5 行）** | 「`128bit` 歧义」待确认项现状列同步 A15 口径（含「用户选第 5 项视为确认美术风格提案 v1」、色库/单帧两层、原单帧 ≥256 废止、歧义仍待确认）；需要列加「A15 不消歧、仍待确认」；**第 1~4 / 6~8 行及「R22 遗留快照」等历史措辞原样保留** |
| 4 | `teamwork/Rank-3/存档与flag规范.md` §3.3 | **追加 2 行** | 逐字追加 GRACE-RETRY-V020.md §2.3 待追加行：`grace.encounter_01.retried`（int / `0`）/ `grace.encounter_01.retry_active`（bool / `false`），使新 key 在 I-1 真源登记表中合法可用；未改 §3.1 正则 / §3.2 命名空间 / 其它登记行 |
| 5 | `teamwork/Rank-3/verify_grace_flags_v030.gd` | **新建** | `extends SceneTree` 口径自测载体（详见 §1.1 / §2.3） |
| 6 | `F:/Game/aierdengfahuan/README.md` | **修改（3 处）** | ① 顶部追加 R25 更新记录；② 「一、已做了什么」表追加 **v0.3.0 方向 4 条目行** + **R25 回归真跑行**；③ 「二、还差什么」表**第 9 项补 A16 归属说明** + 新增 **第 10（人工试玩属用户侧 A17）/ 11（`128bit` 待确认）/ 12（HD-2D 全绿未达）** 三项。§3.1~§3.4 既有 `stat` 实测表与历史结论未改 |
| 7 | `teamwork/Rank-3/R25-*.log`（13 份） | **新建 · 运行输出留档** | `G0-version` / `G1-import` / `G2a-writer` / `G2b-hud` / `G2c-r19` / `G2d-e2e` / `G2e-grace` / `G3-quit` / `RUN-r19` / `RUN-r17` / `GFV-selftest` / `GFV-write` / `GFV-read`，均为实际 stdout，非工程源文件、非脚本 |
| 8 | `teamwork/Rank-3/DONE-R25.md` | **新建** | 本报告 |
| 9 | `teamwork/command_center/ai/3/outbox/cmd-20261110-204604-840-A3.json` | **新建** | 回执 JSON，写在 `teamwork/command_center/` 下的**精确 id 路径**（**未**写到工程根 `command_center/`） |

### 1.1 「契约 §3.3 登记表」歧义的如实处理（两处都登记，不臆断）

任务单 ② 措辞「登记进**契约 §3.3 登记表**」存在指代歧义，按**真源链 + 落地清单**两处补齐、内容一致，避免漏做：

| 落点 | 依据 | 内容 |
|---|---|---|
| `teamwork/00-协作契约.md` **新增 §3.3** | 任务单字面「契约」；本轮 ① 已确权 Rank-3 可改该文件；写明任务单要求的 **key / 类型 / 读写方 / 单调性** 4 列 | 2 行登记表（新增子节，§3.1/§3.2 缺号如实说明、不改 I-1~I-6 接口表） |
| `teamwork/Rank-3/存档与flag规范.md` **§3.3 全局 flag 登记表** | 项目内「§3.3 登记表」唯一真源（GRACE-RETRY-V020.md §0 / §2.3 / **§7.1 落地清单第 1 条**：R25 必须在此追加 2 行后才可在代码里使用新 key） | 逐字追加 §2.3 的 2 行 |

两处文件均在 Rank-3 本轮可写范围（`00-协作契约.md` 归 Rank-3；`存档与flag规范.md` 在 `teamwork/Rank-3/`），**不构成越权、不产生冲突口径**。

### 1.2 A15 口径前后值（用于交付核对）

| 维度 | 前值（R23 拍板，改前） | 后值（R25 裁决 A15，改后） |
|---|---|---|
| 色数 | **256 色以上（≥256 色）**；由「全项目共用一份 ≤256 色索引调色板」**上限放宽为下限**，不再以 256 色封顶 | **两层口径须同时满足**：① **项目级色库 ≥256 色**（项目级下限，全项目共用统一色库）；② **单帧强制 ≤16 色索引**（单帧上限、受控色板）。原「单帧 ≥256」**废止** |
| 画布 | 128px 基准画布不变，逐帧 128×128、脚贴地 | **128px 基准画布**（不变） |
| 通道 | RGBA / alpha 保留 | **RGBA 保 alpha**（不变，明确表述） |
| `128bit` | 显式保留、待用户确认，不消歧 | **仍显式保留、不消歧、不编码进任何期望值、待用户确认**（A15 不消歧） |
| 零付费 / DNF 合规 | 本地 ComfyUI 零付费；DNF 仅本机参考、不进发布包 | **不变**（未改动该历史条款） |

### 1.3 §3.3 登记内容（key / 类型 / 读写方 / 单调性）

| key | 类型 | 读写方 | 单调性 |
|---|---|---|---|
| `grace.encounter_01.retried` | int（基线 `0`） | 写：Rank-3 赐福菜单「重复挑战」回调（`set_flag(key, get_flag(key,0)+1)`，强制 `commit("grace_retry")` 先落盘）／读：HUD 次数 / L4 计数 / 回放断言（纯读 `get_flag`） | **单调递增、永不清除**：只 +1 不回退，休息不清零、重启不丢；与 `combat.<id>.defeated` 不同命名空间，不表达 Boss 生死 |
| `grace.encounter_01.retry_active` | bool（基线 `false`） | 写：Rank-3（发起置 `true`；结算 / 重启恢复置 `false`）／读：导演层门控（回合内防重复发起） | **非单调（回合内翻转）**：每回合结束必置 `false`；`_load()` 后若为 `true` 且无活跃遭遇实例则判异常中断并置 `false` |

### 1.4 verify_grace_flags_v030.gd 验证覆盖（4 类 → 10 条 selftest 断言）

| 类 | 断言 | 依据 |
|---|---|---|
| A 三段式正则 | A1 两个新 flag 通过 `^(world\|quest\|combat\|grace\|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`；A2 六类非法 key（两段式 / 大写 / 连字符 / 四段 / 非法前缀 / 中文）全被拒绝 | 契约 §2、GRACE-RETRY §2.1 / §2.3 |
| B commit 顺序 | B1 连续 3 次 commit 的事件序列恒为 `disk_write → runtime_update`（**先落盘再改运行时实例**）；B2 落盘态与运行时实例态逐项一致 | GRACE-RETRY §4.2 步骤 9→10 纪律 |
| C `retried` 单调递增 | C1 三次发起 0→1→2→3 严格递增；C2 同回合 `retry_active=true` 门控不二次 +1；C3 赐福休息不清零、`defeated` 不回退 | GRACE-RETRY §2.2 / §3 规则 6 / §4.2 |
| D 重启读回一致 | D1 真实 `FileAccess` 落盘到**独立** `user://grace_flags_v030_state.json`（不碰 `slot_01/delta.json`）；D2 新建独立 `_State` 实例 `_load()` 重建内存；D3 逐项读回 `retried / retry_active / defeated` 3/3 一致 | GRACE-RETRY §4.2 步骤 15 / §5.3 单槽 |

**`--script` 模式纪律（任务单明确要求）**：全程**不用 `/root/...` 绝对路径**；`_initialize()` 用 `Engine.get_main_loop()` + `get_root().get_node_or_null("WorldState")` 相对探活，取不到如实降级、**不依赖其结果判 PASS**（实测 `WorldState_probe=true`，但仅登记不用于判定）。退出用 `quit(0 if ok else 1)`，输出 `[GFV030] SUMMARY ... pass=N fail=0 ok=true` + `[GFV030] RESULT=ALL_PASS`。

**如实边界（不粉饰）**：本载体是**口径级模拟验证**（内置 `_flags` / `_disk` / `_runtime` / `_State` 模拟 I-1 `WorldState` + `SaveDeltaWriter.commit` 时序），**不是对 Rank-2 运行时实现件的代验**；本轮 Rank-3 不写 `godot/` 工程文件（目录所有权硬约束）。「重启读回一致」在同进程内由「真实文件落盘 → 全新实例 `_load()`」验证，并**另用 write/read 两个独立引擎进程**（pid 41208 / 37940）实证跨进程一致性。JSON `parse_string` 的 int→float round-trip（读回 `retried: 3.0`）由 `_val_eq`（`is_equal_approx`）容忍，**如实登记、不隐瞒**。

---

## ② 真跑输出结论（实际 stdout，未删改、未补写）

### 2.1 命令清单（引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--path F:/Game/aierdengfahuan/godot`）

| 段 | 命令标志 | 日志 |
|----|----|----|
| G0 | `--version` | `R25-G0-version.log` |
| G1 门禁 | `--headless --import` | `R25-G1-import.log` |
| G2a | `--headless --check-only --script res://scripts/save_delta_writer.gd` | `R25-G2a-writer.log` |
| G2b | `--headless --check-only --script res://scripts/hud.gd` | `R25-G2b-hud.log` |
| G2c | `--headless --check-only --script <abs>/r19_verify_hud.gd` | `R25-G2c-r19.log` |
| G2d | `--headless --check-only --script <abs>/r22_save_e2e.gd` | `R25-G2d-e2e.log` |
| **G2e** | `--headless --check-only --script <abs>/verify_grace_flags_v030.gd`（**新脚本语法门禁**） | `R25-G2e-grace.log` |
| G3 门禁 | `--headless --quit` | `R25-G3-quit.log` |
| 回归 A | `--headless --script <abs>/r19_verify_hud.gd` | `R25-RUN-r19.log` |
| 回归 B | `--headless --script res://scripts/verify_hud_binding.gd` | `R25-RUN-r17.log` |
| GFV selftest | `--headless --script <abs>/verify_grace_flags_v030.gd` | `R25-GFV-selftest.log` |
| GFV write | `GRACE_V030_PHASE=write ... --script <abs>/verify_grace_flags_v030.gd` | `R25-GFV-write.log` |
| GFV read | `GRACE_V030_PHASE=read ... --script <abs>/verify_grace_flags_v030.gd` | `R25-GFV-read.log` |

> `<abs>` = `F:/Game/aierdengfahuan/teamwork/Rank-3/`。**一次只跑一个引擎进程、串行执行**；回归在前、verify 在后（verify 用独立 `user://` 文件，不污染 `slot_01/delta.json`，与 31 PASS 回归互不干扰）。

### 2.2 退出码（13 次引擎调用全部 `EXIT=0`）

```
G0_EXIT=0  G1_EXIT=0  G2a_EXIT=0  G2b_EXIT=0  G2c_EXIT=0  G2d_EXIT=0  G2e_EXIT=0  G3_EXIT=0
R19_EXIT=0  R17_EXIT=0  SELFTEST_EXIT=0  WRITE_EXIT=0  READ_EXIT=0
```

### 2.3 PASS / FAIL 数字（实际 SUMMARY 行）

```
[R19]    SUMMARY pass=20 fail=0 ok=true
[R17]    SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true
[GFV030] SUMMARY phase=selftest pid=34108 pass=10 fail=0 ok=true   → RESULT=ALL_PASS
[GFV030] SUMMARY phase=write    pid=41208 pass=3  fail=0 ok=true   → RESULT=ALL_PASS
[GFV030] SUMMARY phase=read     pid=37940 pass=3  fail=0 ok=true   → RESULT=ALL_PASS
```

| 项 | 数值 | 说明 |
|---|:--:|---|
| R21 HUD / 存档回归 | **20 PASS / 0 FAIL** | `r19_verify_hud.gd`，R25 重跑不回退 |
| R17 HUD 绑定回归 | **11 PASS / 0 FAIL** | `verify_hud_binding.gd`，`degraded=false`、`flag_chain_verified=true` |
| **任务单 ⑤ 的 31 PASS 回归** | **31 PASS / 0 FAIL** | 20 + 11，**不回退** |
| flag 自测 selftest（主自测） | **10 PASS / 0 FAIL** | A1/A2 + B1/B2 + C1/C2/C3 + D1/D2/D3，`RESULT=ALL_PASS` |
| flag 自测 write / read | **3 + 3 PASS / 0 FAIL** | 两独立引擎进程 pid 41208 / 37940 不同 = 真重启，`RESULT=ALL_PASS` |
| **flag 自测合计** | **16 PASS / 0 FAIL** | 10 + 3 + 3；三进程 pid 34108 / 41208 / 37940 全不同 |

> write→read 阶段：`R1` 新进程 `_load()` 从磁盘重建内存、`R2` 跨进程读回 **3/3 一致**（`retried=3` / `retry_active=false` / `defeated=true`）、`R3` 重启恢复 `retry_active=false` 无残留 true；D3 selftest 同进程「全新实例读回」同样 3/3 一致。

### 2.4 三段门禁 `grep SCRIPT ERROR=0`

| 段 | 标志 | `SCRIPT ERROR` | `Parse Error` | `ERROR` | `EXIT` |
|----|----|:--:|:--:|:--:|:--:|
| G1 | `--headless --import` | 0 | 0 | 0 | 0 |
| G2a | `--check-only --script` writer | 0 | 0 | 0 | 0 |
| G2b | `--check-only --script` hud | 0 | 0 | 0 | 0 |
| G2c | `--check-only --script` r19 | 0 | 0 | 0 | 0 |
| G2d | `--check-only --script` r22_e2e | 0 | 0 | 0 | 0 |
| G2e | `--check-only --script` **verify_grace_flags_v030.gd** | 0 | 0 | 0 | 0 |
| G3 | `--headless --quit` | 0 | 0 | 0 | 0 |

> **13 份 `R25-*.log` 逐份 `grep`：`SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR=0` 全为 0**（含 G0 / 5 份回归与自测运行日志）；三段门禁 `grep SCRIPT ERROR=0` 达成。
> 退出残留仍是工程既有 **WARNING、非 ERROR、未隐藏、未宣称零 WARNING**：`[ChunkManager] 未找到 ChunkRoot`（`chunk_streaming.gd:51`）、`2 ObjectDB instances were leaked at exit`（`object.cpp:2536`），见 `R25-G3-quit.log` / `R25-GFV-*.log`。

### 2.5 存档写入的如实说明

verify 载体只写**独立** `user://grace_flags_v030_state.json`（实测绝对路径 `C:/Users/62668/AppData/Roaming/Godot/app_userdata/艾尔登法环 · HD-2D/grace_flags_v030_state.json`），**不碰** `user://saves/slot_01/delta.json`、不注入测试种子到工程存档、不伪造产物。回归脚本 `r19_verify_hud.gd` / `verify_hud_binding.gd` 的既有 autoload commit 行为按历轮一贯口径保留，未改动任何工程文件。

---

## ③ 未完成项与阻塞

**阻塞：无功能性阻塞。** 派单 5 项（① A15 口径 + §6.2 / ② flag 登记 / ③ verify 脚本并真跑 / ④ README / ⑤ 31 PASS 回归 + 三段门禁）均真实达成。

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 1 | **v0.3.0 四项实现**（A16 `main_scene` 改指 `courtyard.tscn` / Boss 可见像素形象 / 录屏注入输入让战斗数值推进 / 按 16 色受控色板重绘消除马赛克） | **未由 Rank-3 实现、未代验、不宣称完成** | 归 Rank-1 / Rank-2 / Rank-4 本轮并发写入 `godot/` 与 `capture/`；目录所有权硬约束禁止 Rank-3 触碰。README 第 9 / 12 项已如实标注 |
| 2 | **人工试玩（exe / apk）与手感 / 审美验收**（裁决 A17） | **属用户侧 · 本轮只给勾选清单、不冒充完成** | README 第 10 项已给勾选清单（翻滚无敌帧手感 / Boss 招式公平性 / 区域密度 / 画面可见性 / 默认入口庭院与 Boss 是否可见）；headless 无真实帧缓冲 |
| 3 | **`128bit` 词义歧义** | **待用户确认 · A15 不消歧** | 契约 §9.3 / `00-汇总.md` §6.2 第 5 项 / README 第 11 项均显式保留；指「128px 画布尺寸」还是「位宽 / 色深」以用户后续确认为准，未编码进任何期望值 |
| 4 | **HD-2D 全绿未达** | **未达成 · 长期项** | R24 总指挥目视回看实证：Boss 无可见像素形象、战斗数值 15 秒停在 `idle 0/0`、地面平铺重复与马赛克观感、光效仍 2D 近似；README 第 12 项如实登记 |
| 5 | `encounter_01` 对象段与 Rank-2 实际遭遇 id 对齐 | **待对齐** | GRACE-RETRY §2.3 / 契约 §3.3 已约定：以 Rank-2 `encounter_rules_v020.gd` 实际 id 为准，不一致改口径文档对象段、不改数据表 id；本轮按任务单示例字面量登记 |
| 6 | `grace_retry` reason 字面量是否复用 `grace_rest` | **待总指挥裁决（可选）** | GRACE-RETRY §4.1 已注明：仅 `meta.last_commit_reason` 使用、不是新顶层字段、不触发迁移；若裁决复用，替换字符串即可、时序不变 |
| 7 | 赐福菜单 UI 画面 / 15–20 秒录屏 / exe / pck / apk 重导 | 长期项 · 不在本单 | 本轮未写任何 `godot/` 工程文件；产物重导由工程变更方 / 后续轮次承担 |
| 8 | 既有退出 WARNING | 如实保留 · 非 ERROR | `ChunkManager` / `ObjectDB instances leaked`，历轮已登记，R25 真跑中仍出现，未隐藏 |
| 9 | 中枢 done 轮次表 / outbox 消费 | 未据以改写 | README 顶部表仍为 R22 快照，按历史结论保留、不冒充已进 done 序列；回执按精确路径写入，是否被实时消费以中枢实际行为为准 |

---

## ④ 约束对照

- **目录所有权** ✓：只写 `00-协作契约.md` / `00-汇总.md`（**仅 §6.2 第 5 行**）/ `README.md`（工程根）/ `teamwork/Rank-3/`（+ 回执例外 `teamwork/command_center/ai/3/outbox/`）；**绝对未碰** `godot/project.godot`、`godot/scenes/*`、`godot/scripts/*`、既有存档件 / 战斗件 / 美术资源、其它 Rank 文档、`build/` 产物。
- **公共契约** ✓：直接改、直接真跑；**未新建只读探针 / 巡检脚本**（`verify_grace_flags_v030.gd` 是任务单 ③ 明确要求的验证载体，其余复用既有 `r19_verify_hud.gd` / `verify_hud_binding.gd` / `r22_save_e2e.gd`）；未主动扫目录做进度巡检（仅对任务单指定的引擎 / 脚本 / 回执路径做定向存在性核对）；零付费、零外部依赖；一次只跑一个引擎进程、无 GPU job；产出先目视检查（§开头核对）再接入。
- **不伪造 / 不谎报** ✓：v0.3.0 四项实现不冒充完成、`128bit` 不消歧、HD-2D 全绿未达不粉饰、人工试玩不代做、既有 WARNING 不隐藏、JSON int→float round-trip 如实登记、verify 载体为口径级模拟（非 Rank-2 运行时代验）如实说明。
- **不自行 git** ✓：由总指挥收尾。
- **三段门禁 `grep SCRIPT ERROR=0`** ✓；中文 UTF-8 ✓。

---

## ⑤ 回执

按本轮 `task_id` 写 `F:/Game/aierdengfahuan/teamwork/command_center/ai/3/outbox/cmd-20261110-204604-840-A3.json`（在 `teamwork/command_center/` 下，**未**写到工程根 `command_center/`）：

```json
{"task_id":"cmd-20261110-204604-840-A3","ai":3,"status":"done","result":"引用 DONE-R25.md 实际结论：① 裁决 A15 落地：00-协作契约.md §9.3 的 I-5 色数口径由「256 色以上 / 单帧 ≥256」统一为「项目级色库 ≥256 色、单帧强制 ≤16 色索引、RGBA 保 alpha、128px 基准画布」，128bit 歧义仍显式保留待用户确认；00-汇总.md 仅改 §6.2 第 5 行待确认项，其它历史条款未动。② 两个三段式 flag（grace.encounter_01.retried int 单调递增 / grace.encounter_01.retry_active bool 回合内翻转）两处登记：契约新增 §3.3 登记表（key/类型/读写方/单调性 4 列）+ 存档与flag规范.md §3.3 追加 §2.3 的 2 行。③ 新建 verify_grace_flags_v030.gd（extends SceneTree）真跑 16 PASS/0 FAIL RESULT=ALL_PASS（selftest 10 + write 3 + read 3，三进程 pid 34108/41208/37940 不同，write→read 实证重启读回一致），--script 模式不用 /root/ 绝对路径、用 Engine.get_main_loop()/root.get_node_or_null() 相对探活。④ README 新增 v0.3.0 方向 4 条目 + R25 回归真跑行，还差什么新增第 10/11/12 项（人工试玩属用户侧 A17 / 128bit 待确认 / HD-2D 全绿未达）。⑤ 31 PASS/0 FAIL（r19 20 + r17 11）不回退；13 次引擎调用全 EXIT=0，13 份 R25-*.log grep SCRIPT ERROR/Parse Error/ERROR 全 0；既有 WARNING 非 ERROR 如实保留。未写任何 godot/ 工程文件、未新建探针/巡检脚本、零付费、不自行 git。未完成项：v0.3.0 四项实现归 Rank-1/2/4 并发未代验、128bit 待确认、HD-2D 全绿未达、人工试玩属用户侧、encounter_01 id 对齐与 grace_retry reason 待裁决。"}
```

**写后实测（本轮）**：回执写入成功后 `outbox/` 被中枢**实时消费清空**（目录当前 0 文件，与 `DONE-R21.md §⑤` / `DONE-R22.md §⑤` / `DONE-R23.md §⑥` / `DONE-R24.md §⑤` 同一消费时序现象），首次直接读 `outbox/` 精确路径得到 `FileNotFoundError`，**如实登记、未隐藏**。归档件 `teamwork/command_center/dispatcher/receipts/cmd-20261110-204604-840-A3.json`（**1693 字节**）读回校验：`json_valid=True`、`keys=['ai','result','status','task_id']`、`task_id=cmd-20261110-204604-840-A3` / `ai=3` / `status=done`、`result_len=980`、`result` 以「引用 DONE-R25.」开头；工程根 `command_center/` **不存在**（未误写）。按幂等 / 并发保护**不重复写第二份回执**。

> 结论：回执**路径正确**（`teamwork/command_center/ai/3/outbox/` 下的精确 id 文件，且已被中枢按该 id 归档）、**内容符合**任务单 `{"task_id":...,"ai":3,"status":"done","result":"引用 DONE-R25.md 实际结论"}` 结构。按实际产物判定，不臆测、不谎报。

---

## ⑥ 关联

`teamwork/00-协作契约.md`（§9.3 A15 口径真源 / 新增 §3.3 登记表）、`teamwork/00-汇总.md` §6.2、`teamwork/Rank-3/存档与flag规范.md` §3.3、`teamwork/Rank-3/GRACE-RETRY-V020.md`（flag 定义 / §7.1 落地清单）、`teamwork/Rank-3/verify_grace_flags_v030.gd`（本轮自测载体）、`F:/Game/aierdengfahuan/README.md`（状态表）、`teamwork/Rank-3/DNF-COMPLIANCE-R23.md`、`teamwork/Rank-3/R25-*.log`（13 份真跑 stdout）。

---

## ⑦ 并发复核补记（另一并发 Rank-3 实例 · 只追加、不重做）

> 本补记由本实例在**并发保护**下追加：开工复核发现任务单 ①②③④ 的交付件、`DONE-R25.md` 及本轮回执（写入 `outbox/` 后被中枢实时消费、归档于 `teamwork/command_center/dispatcher/receipts/cmd-20261110-204604-840-A3.json`）**均已由并发实例写齐**，故按「只复核、只补真实缺口、不重做、不写第二份回执」执行：**未重做**任何交付件、**未写第二份回执**。以下为本实例独立复核结果与真实缺口补齐。

### 7.1 本实例独立真跑复核（与 §② 结论一致，属不同实例 / 不同次运行）

引擎同为 `D:/Godot/Godot_v4.7.2-stable_win64.exe`、`--path F:/Game/aierdengfahuan/godot`，本实例串行 **12 次引擎调用全 `EXIT=0`**：

- G1 `--headless --import`；G2 `--check-only --script` ×5（`r19_verify_hud.gd` / `res://scripts/verify_hud_binding.gd` / `r22_save_e2e.gd` / `verify_grace_flags_v030.gd` / `res://scripts/save_delta_writer.gd`）；G3 `--headless --quit` —— 全 `EXIT=0`。
- 本实例汇总输出：**`SCRIPT ERROR=0`、`Parse Error=0`、`ERROR` token = 0**。
- **31 PASS / 0 FAIL 不回退**：`[R19] SUMMARY pass=20 fail=0 ok=true` + `[R17] SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true`。
- `verify_grace_flags_v030.gd`：**16 PASS / 0 FAIL `RESULT=ALL_PASS`** —— selftest `pass=10 pid=1836`、write `pass=3 pid=29656`、read `pass=3 pid=34684`；**write→read 两独立引擎进程 pid 29656 / 34684 不同 = 重启读回一致实证**。
- 本实例 pid（1836 / 29656 / 34684）与 §2.3 并发实例 pid（34108 / 41208 / 37940）**不同**，属不同实例 / 不同次真跑，**两套数值各自真实、不合并、不冒充**；PASS 数与门禁口径一致。

### 7.2 对 13 份 `R25-*.log` 的复核（声明属实）

`ls` 实测 `teamwork/Rank-3/R25-*.log` **13 份**（`Glob` 因 `.gitignore` 屏蔽 `*.log` 未检出，以 `ls` 为准）；`grep` 汇总：`SCRIPT ERROR=0`、`Parse Error=0`、`ERROR=0`；SUMMARY 行与 §2.3 一致（R19 20 / R17 11 / GFV selftest 10 + write 3 + read 3、`RESULT=ALL_PASS`）；G3 退出残留 `2 ObjectDB instances were leaked at exit` 为既有 **WARNING、非 ERROR**，如实保留。**§② 真跑结论属实**。

### 7.3 真实缺口补齐（§① 第 3 / 6 项与当前文件状态的差异）

| 落点 | §① 原描述 | 当前实际状态（本实例复核） |
|---|---|---|
| `teamwork/00-汇总.md` §6.2 | 「**修改（仅第 5 行）**」、第 1~4 / 6~8 行原样保留 | 第 5 行已按 A15 同步（并发实例）；**另有第 9 行「R25 / 裁决 A15 落地登记」追加行**（本实例并发补写，已修正其中对不存在的 `§9.3.1` 的引用）。第 1~8 行历史条款**确未改动**，第 9 行为新增、不属改历史条款；「仅改第 5 行」应补记为「第 5 行同步 + 第 9 行追加」 |
| 工程根 `README.md` 顶部 | 追加 R25 更新记录 | 并发竞争中一度出现 2 条 R25 维护行，本实例已**合并为 1 条**（保留并发实例行 10，删除本实例重复行及其 `§9.3.1` 错误引用）。§① 第 6 项「顶部追加 R25 更新记录」仍成立 |

> 契约 §9.3 为**直接改 §9.3 正文**（非新建 `§9.3.1` 子节）；本实例在 `00-汇总.md` / `README.md` 曾出现的 `§9.3.1` 引用均已清除。

### 7.4 复核结论

任务单 5 项（① A15 口径 + §6.2 / ② 两处 flag 登记 / ③ verify 脚本并真跑 / ④ README / ⑤ 31 PASS 回归 + 三段门禁 `grep SCRIPT ERROR=0`）**均真实达成**；`DONE-R25.md` 主体结论有效，本补记只追加、不重做。**未完成项与阻塞以 §③ 为准，无新增**：人工试玩属用户侧（A17，只给勾选清单）、`128bit` 待用户确认不消歧、HD-2D 全绿未达、A16 归 Rank-1、v0.3.0 四项实现归 Rank-1/2/4 未代验、`encounter_01` id 对齐与 `grace_retry` reason 待裁决。回执按精确 id 已由并发实例写入并被中枢归档，**本实例不重复写**；未自行 git、零付费、零外部依赖。
