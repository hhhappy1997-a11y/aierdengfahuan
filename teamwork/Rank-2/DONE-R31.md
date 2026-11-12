# DONE-R31.md — Rank-2 交付（R31 / v0.9.0）

> 任务单：`teamwork/Rank-2/调度任务单-latest.json`，id **`cmd-20261111-133549-883-A2`**（[ROUND=R31]）。
> 工位：Rank-2 战斗系统与数据驱动。协作契约：`teamwork/00-协作契约.md`（铁律：只写本 Rank 授权文件）。
> 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`，工程 `F:/Game/aierdengfahuan/godot`。

---

## 1. 实际交付清单（8 个文件，全部实际落盘）

| # | 文件 | 内容 |
|---|---|---|
| 1 | `godot/data/rpg/trial_modifiers.tres` | 3 词条 `no_hit` / `time_pressure` / `low_vigor`，7 字段（id/title/description/reward_multiplier/time_limit_scale/hp_scale/exclusive_group），数值全 `[PLACEHOLDER]` |
| 2 | `godot/scripts/combat/trial_modifier_config.gd` | `extends Resource` + `class_name TrialModifierConfig`；`Array[Dictionary]` 存储 + `TrialModifier` 静态视图 + 白名单/合法性/降级/分组纯函数；头注写全 `[PLACEHOLDER]` rationale 与「调参唯一入口只改表不改代码」 |
| 3 | `godot/scripts/combat/trial_modifier_service.gd` | `RefCounted` 纯逻辑（不读写存档、不碰渲染）：`select(id)` / `clear()` / `settle(base_points, stats) -> Dictionary`；选择合法性、互斥组拒绝、未选回落基础、奖励单调不减、余额非负、异常输入拒绝 |
| 4 | `godot/scripts/combat/verify_trial_modifier_v090.gd` | 92 条断言，覆盖 ①②③；输出逐条 PASS + SUMMARY + `RESULT=ALL_MATCH` |
| 5 | `godot/scripts/combat/verify_codex_full_wish_v090.gd` | 按 4 张既有 `.tres` 真值模拟正常游玩路径，机器判定满愿 4/4；26 条断言；输出 `FULL_WISH_4OF4` / `SHORTFALL_POINTS` / PASS+`RESULT` |
| 6 | `teamwork/Rank-2/TRIAL-MODIFIER-TUNING.md` | 数值假设表 + broken 定义（B1 词条互斥失效 / B2 奖励通胀 / B3 条件不可达 / B4 重复领取）+ 校准同步清单 |
| 7 | `teamwork/Rank-2/DONE-R31.md` | 本文件（交付清单 / 真跑结论 / 未完成项与阻塞 / 待裁决项） |
| 8 | `teamwork/command_center/ai/2/outbox/cmd-20261111-133549-883-A2.json` | 回执 JSON（注意：teamwork/ 下的 command_center/，非工程根） |

> **未触碰**：既有 4 张 `.tres`（`codex_entries.tres` / `grace_upgrades.tres` / `wave_trial.tres` / `tutorial_steps.tres`）、`encounter_director.gd` / `wave_trial_director.gd` / `codex_director.gd` / `hud.gd` / 场景 / 素材 / 其它 Rank 文件 / `project.godot`，一律只读。`courtyard.tscn` 节点数与 uv 未改。未自行 git。

---

## 2. 真跑输出结论（三段门禁，原文摘录）

### 第 1 段 · `--headless --import`
`IMPORT_EXIT=0`；`update_scripts_classes` 注册 `TrialModifierConfig` / `TrialModifierService` 两个全局类名；`reimport` 完成；无 `SCRIPT ERROR`。

### 第 2 段 · `--check-only --script`（4 个新脚本）
```
CHECK_EXIT[trial_modifier_config.gd]=0
CHECK_EXIT[trial_modifier_service.gd]=0
CHECK_EXIT[verify_trial_modifier_v090.gd]=0
CHECK_EXIT[verify_codex_full_wish_v090.gd]=0
```
4/4 语法检查通过，无 Parse Error。

### 第 2 段 · `--headless --script verify_trial_modifier_v090.gd`
```
[V090-TM] SUMMARY pass=92 fail=0
[V090-TM] OVERALL=PASS
[V090-TM] RESULT=ALL_MATCH
VERIFY_TM_EXIT=0
```
92 条全 PASS：3 词条 7 字段 / `[PLACEHOLDER]` 真值 / 倍率互异且 ≥1 / 分组（survival=2、tempo=1）/ select 合法性与重复拒绝 / 同组互斥拒绝与跨组共存 / clear / 未选回落基础 / 三种条件达成与未达成回落 / 倍率取 max 不叠乘（150 而非 195）/ 奖励单调不减 / 余额非负 / 异常输入（负 base、非 Dictionary stats、无 config）拒绝。

### 第 2 段 · `--headless --script verify_codex_full_wish_v090.gd`
```
[V090-CW] 表回读 · 教学 20/30/50 合计=100 · 三波 100/150/200 合计=450 · 成长 100/200/300 合计=600 · 图鉴 30/50/80/120 合计=280
[V090-CW] 买成长前累计 points=750（教学 100 + 三波 450 + 已解锁图鉴 200） · 三项成长 cost=600 · 余额=150 · 缺口=0
[V090-CW] 买齐三项成长后 points=830 图鉴解锁=["tutorial_complete", "wave_trial_clear", "best_wave_3", "all_grace_upgrades"]
[V090-CW] 图鉴 4 项成就已解锁=4/4 · 三项成长 purchased=3 · 缺口=0 · 盈余=150
[V090-CW] FULL_WISH_4OF4=REACHABLE
[V090-CW] SHORTFALL_POINTS=0
[V090-CW] SURPLUS_POINTS=150
[V090-CW] SUMMARY pass=26 fail=0
[V090-CW] OVERALL=PASS
[V090-CW] RESULT=ALL_MATCH
VERIFY_CW_EXIT=0
```

### 第 3 段 · `--headless --quit`
`QUIT_EXIT=0`；`[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41`（**A38 节点数 41 未破坏**，uv 未触碰）；但全工程段输出 **5 个 `SCRIPT ERROR` + 1 个 `ERROR`**（见 §4）。

### `SCRIPT ERROR` 统计（如实，不谎报 0）
| 范围 | SCRIPT ERROR 数 |
|---|---|
| 本 Rank 四段门禁（`--import` / `--check-only ×4` / 两个 `--script verify`） | **0** |
| `--headless --quit` 全工程段 | **5**（全部来自 Rank-1 `impact_feedback.gd` 与 `hud.gd` 连带） |

> `--script` 模式下另有 3 条既有 `WARNING`（`[SaveSystem] --script 工具模式跳过自动读回`、`[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked`），属既有 autoload 在工具模式的固有降级告警，**不是 `SCRIPT ERROR`**；两个 verify 均为纯内存夹具，未读写 `user://` 存档、未触碰 `delta.json`，无并发抖动。

---

## 3. 满愿 4/4 可达性结论（本轮硬要求，务必写清）

> **结论：按既有 4 张 `.tres` 的真实数值，图鉴满愿 4/4 可达（`FULL_WISH_4OF4=REACHABLE`），缺口 `SHORTFALL_POINTS=0`，盈余 `SURPLUS_POINTS=150`。**

推导链（全部由 `verify_codex_full_wish_v090.gd` 用 `CACHE_MODE_IGNORE` 回读真值后**动态聚合**，未硬编码结论、未改任何既有表数值、未伪造 4/4）：

1. **教学三步**：20+30+50 = 100 → `points=100`；`grace.tutorial.completed=true` → 解锁 `tutorial_complete` +30 → **130**。
2. **三波**：100+150+200 = 450 → `points=580`；`dungeon.wave_trial.completed=true` / `best_wave=3` → 解锁 `wave_trial_clear` +50 与 `best_wave_3` +120 → **750**。
3. **买成长前「已解锁图鉴奖励」** = 30+50+120 = **200**。`all_grace_upgrades` 的 80 点需 3 项成长 unlocked 才达成，**未预支、不计入买成长预算**；脚本显式断言「买成长前该条件 = false」（`cycle_dependency_honest PASS=true`），不绕过循环依赖。
4. **买成长前累计** = 100（教学）+ 450（三波）+ 200（图鉴）= **750**；三项成长 `cost` = 100+200+300 = **600**；**余额 = 150 ≥ 0**，故三项可全买（`stage3_purchase_all_3 PASS=true`，`spent=600`，3 个 `grace.upgrade_<id>.unlocked=true`）。
5. 买齐后触发 `all_grace_upgrades` +80 → `points=830`；4 项成就 flag `grace.codex_<id>.unlocked` 全为 true → **4/4 达成**。
6. 解锁顺序 = `tutorial_complete → wave_trial_clear → best_wave_3 → all_grace_upgrades`（满愿最后，依赖买齐成长），合法。

断言全过：**余额非负**（全程 ≥0）、**无重复领取**（4 项二次领取全被拒、`points` 不变=830、已领=4）、**points 只增不减**（序列 `[0,20,50,100,130,230,380,580,630,750,830]`）、**4 项成就 flag 三段式合法**（`grace.codex_<id>.unlocked` 全通过 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`）、**解锁顺序合法**。

> 若后续调表导致不可达，脚本会自动输出 `FULL_WISH_4OF4=UNREACHABLE` + 缺口点数、`full_wish_4of4_reachable` 判 FAIL、`RESULT=FAIL`；本 Rank **绝不擅自改既有表数值、绝不伪造 4/4**。

---

## 4. 未完成项与阻塞（如实登记）

1. **阻塞 · 非本 Rank 授权范围**：`--headless --quit` 全工程段出现 5 个 `SCRIPT ERROR` + 1 个 `ERROR`，原文归因：
   ```
   SCRIPT ERROR: Parse Error: Function "cosf()" not found in base self.   at: ... impact_feedback.gd:201
   SCRIPT ERROR: Parse Error: Function "sinf()" not found in base self.   at: ... impact_feedback.gd:201
   SCRIPT ERROR: Parse Error: Function "cosf()" not found in base self.   at: ... impact_feedback.gd:241
   SCRIPT ERROR: Parse Error: Function "sinf()" not found in base self.   at: ... impact_feedback.gd:241
   ERROR: Failed to load script "res://scripts/render/impact_feedback.gd" with error "Parse error".
   SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.  at: hud.gd:1092
   ```
   按「目录所有权·R31」，`godot/scripts/render/impact_feedback.gd` 与 `hud.gd` 归 **Rank-1**；硬约束「既有导演层 / hud.gd / 其它 Rank 文件一律只读、不改」。**本 Rank 未擅自修、未改任何越界文件**；本 Rank 自有文件四段门禁 `SCRIPT ERROR=0`。建议 Rank-1 将 `cosf()` / `sinf()` 改为 Godot 4.7.2 合法 API（`cos()` / `sin()` 或对应等价实现），由总指挥复跑 `--quit`。
2. **人工试玩校准**：所有 `[PLACEHOLDER]` 数值（1.5 / 1.3 / 1.4、0.6、0.5）待试玩；调参唯一入口 `trial_modifiers.tres`，校准需同步 `verify_trial_modifier_v090.gd` 的 `EXPECT_*`、`TRIAL-MODIFIER-TUNING.md`、本文件并重跑门禁，不静默改数。
3. **15~20 秒实机录屏目视回看 / HD-2D 手感与审美**：属用户侧 / Rank-4；headless 无真实帧缓冲，本轮不代做、不宣称完成。
4. **接线未做（本轮授权边界）**：`trial_modifier_service.gd` 是纯逻辑，未接入导演层 / HUD / 存档；`stats` 由哪一侧生产并注入 `settle()` 待裁决（见 §5 第 4 条）。
5. 未自行 git（总指挥收尾）；未删除 `.workbuddy` 目录；零付费、零外部依赖、未启 GPU job。

---

## 5. 待总指挥裁决项

1. **满愿 4/4 可达性结论**：**可达**（缺口 0 / 盈余 150），请裁决是否接受；本结论由真值动态算出，若后续调表导致不可达，脚本会如实输出 `UNREACHABLE` + 缺口，本 Rank 不擅自改既有表数值。
2. **`--quit` 段 5 个 `SCRIPT ERROR` 的归属与修复**：属 Rank-1 `impact_feedback.gd`（`cosf/sinf` 在 4.7.2 不存在）+ `hud.gd` 连带；请裁决由 Rank-1 修复后复跑全工程门禁，本 Rank 不越界修改、不谎报全工程 `SCRIPT ERROR=0`。
3. **试炼词条数值与口径**：`reward_multiplier` 1.5/1.3/1.4、`time_limit_scale` 0.6、`hp_scale` 0.5 全为 `[PLACEHOLDER]`；`exclusive_group` 分组（survival 互斥 / tempo 共存）与「跨组共存时倍率取 max 不叠乘」口径请确认。
4. **`stats` 生产与注入归属**：`damage_taken` / `elapsed_sec` / `time_limit_sec` / `hp_ratio` 由哪一侧（波次导演 / 战斗结算）写入并调用 `settle()`，本轮未接线，请裁决接线归属与 I-1/I-2 边界。
5. **契约 §3.3 与本轮**:本轮未新增任何三段式 flag、未写 `SaveDelta`、未改 `world_state.gd` 正则 / `schema_version`；无需裁决项。

---

## 6. 回执

已写 `teamwork/command_center/ai/2/outbox/cmd-20261111-133549-883-A2.json`，内容严格为 4 字段 `{task_id, ai=2, status="done", result="引用 DONE-R31.md 实际结论"}`（result 值引用本文件 §2 / §3 实际结论）。

> **投递核实（如实登记）**：回执投递到 `ai/2/outbox/` 后，由调度中枢 watcher 立即收集到 `teamwork/command_center/dispatcher/receipts/cmd-20261111-133549-883-A2.json`。Windows 原生 PowerShell 实读该收件箱文件 584 字节、`ConvertFrom-Json` 校验 `task_id / ai / status / result` 四字段齐全（`ai=2`、`status=done`、`task_id=cmd-20261111-133549-883-A2`、`result` 引用本文件 §2 / §3 实际结论），与投递内容逐字一致；`outbox` 作为投件口消费后为空属正常收集机制，不谎报、不重复投递。本 Rank 未写工程根 `command_center/`；未自行 git。
