# DONE-R36.md · R36 / v0.13.0「专注值与战技 · 画面补齐」交付报告（Rank-3）

> 轮次：`R36 / v0.13.0` ｜ 任务单 id：`cmd-20261112-154132-916-A3` ｜ 执行 AI：`3（Rank-3 RPG / 世界 / 存档执行 AI）`
> 真源：`teamwork/Rank-3/调度任务单-latest.json`（`task` 全文 + 公共契约含 A48 + 目录所有权）
>   + `teamwork/Rank-2/DONE-R36.md` §3（FocusService 信号签名 / A54 唯一实例 / 真实输入驱动口）
>   + `teamwork/Rank-1/DONE-R36.md`（生产链路现状）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> **一句话结论**：R36 六块任务全部真跑完成 —— ① **FP 落盘**：`PointsCommitOrchestrator` autoload 作为 A48① 生产订阅者订阅 Rank-2 `FocusService` 的 `focus_spent` / `focus_restored` / `focus_rejected` 三信号，把专注值登记为 **7 个三段式 `combat.focus.*` flag**，严格遵守 SaveDelta 十字段 / `schema_version=3` 冻结、不写 `removals`、`commit(reason)` 原子写、先落盘再改运行时实例、重启读回一致，**FP 与赐福点数完全分离、不混用 `points` / `spent_points`、重复释放不二次扣费**；② 新写 `verify_v130_save_commit.gd`（`70 PASS` + 三态 `84 PASS`）与 `verify_focus_production_v130.gd`（A48③ 真实可达 `49 PASS`，不加载 `presentation.gd`、不在验证脚本内模拟编排），全 `RESULT=ALL_MATCH`；③ 文档口径同步（R35 遗留 P0）：规范 §3.3 全局表补 10 行、`verify_fx_mobile.gd` 头部「移动四项全关」同步为 A63「轻量降级绘制」（只改注释）；④ 契约 §3.3 只追加 R36 段（7 flag + 裁决 A65~A68）；⑤ 新写迭代文档 + README 状态段；⑥ 三段门禁 G1/G2a/G2b/G3 全 `EXIT=0`、**11 份日志 `SCRIPT ERROR=0 / PARSE_ERROR=0 / ERROR 前缀=0`**、G3 回读 `node_count=41`。`70 + 49 + 84 = 203 PASS / 0 FAIL`。**未完成 / 待裁决**：定稿录屏目视（A67）/ `[PLACEHOLDER]` 校准 / HD-2D 全绿（A68）/ `focus_rejected` 落盘策略 / 多战技切换等 backlog（均零付费零外部依赖），如实登记、不冒充。

---

## 1. 交付清单（实际落地文件，均在任务单授权范围）

| # | 文件 | 类型 | 本轮改动 |
|---|---|---|---|
| ① | `godot/scripts/rpg/points_commit_orchestrator.gd` | 修改（Rank-3 唯一写入） | 头部注释追加 R36 说明；常量段新增 `FOCUS_SIGNALS` + 7 个 `K_FOCUS_*`；运行时态新增 A54 唯一实例引用 / 上限缓存 / 拒绝观测；`_ready()` 追加 `_deferred_bind_focus()`；`_release()` 追加 `_release_focus()`；`get_status()` 追加 12 个 focus 只读观测 key；**文件尾追加 R36 完整实现段**（`_deferred_bind_focus` / `_find_focus_service` / `_scan_wave` / `bind_focus_service` / `_focus_read_max` / `_focus_max_value` / `_release_focus` / `_commit_focus` / 3 个生产回调 `_on_focus_spent` / `_on_focus_restored` / `_on_focus_rejected`）。既有 A55/A57/A59 逻辑（`_commit` / `bind_hud` / `_try_charge_boon_cost` / `_on_points_awarded` 等）**逐字未改** |
| ② | `godot/scripts/rpg/verify_v130_save_commit.gd` | 新写 | 三进程三态存档口径夹具（write/load/assert + all 单进程自检）：7 个 FP flag 三段式 / 十字段 / `schema_version=3` / `removals` 空 / `commit(reason)` 原子写 / 先落盘再改实例 / 重启读回一致 / 旧档缺 key 回落 / **FP 与赐福点数分离** / 上限不突破 / 重复释放不二次扣费 / A48①+A54 静态证据；独立 `user://saves/verify_v130_<RUN>/` 临时槽 |
| ③ | `godot/scripts/rpg/verify_focus_production_v130.gd` | 新写 | **A48③ 真实可达回归**：不加载 `presentation.gd`（B00 运行时树零 presentation 节点实证）、不在验证脚本内模拟编排；实例化主场景 → 复用 A54 唯一真实 FocusService → 调生产编排层 `bind_focus_service()` 显式入口（connect 在生产脚本内）→ 经生产真实驱动口 `wave.spend_focus()` / `focus_grace_rest()` 注入输入 → 读磁盘断言六段链；独立 `user://saves/verify_v130_fp_<pid>/` 临时槽 |
| ④ | `teamwork/Rank-3/存档与flag规范.md` | 修改（§3.3 全局登记表） | 补 10 行 flag（R35 遗留 3：`combat.parry.success_count` / `combat.parry.window_id` / `grace.boon_draft.unlocked`；R36 新增 7：`combat.focus.*`）+ R35 补登注记 + R36 注记；历史行未删 |
| ⑤ | `godot/scripts/verify_fx_mobile.gd` | 修改（**仅头部 `##` 注释**） | 头部「移动四项全关」旧表述同步为 A63「轻量降级绘制」口径（轻量环 + HUD 文字 / 不劣化 ≠ 不绘制）；**断言逻辑逐字未改**，`--check-only --script EXIT=0` |
| ⑥ | `teamwork/00-协作契约.md` | 修改（§3.3 **只追加**） | R36 说明段：7 个新 flag 逐条登记（key/类型/基线/读写方/单调性）+ 三段式合法性 + 十字段关系 + **裁决 A65/A66/A67/A68** 全文 + 未动声明；历史条款 / I-1~I-6 / §3.1 §3.2 缺号**一律未改** |
| ⑦ | `teamwork/迭代-v0.13.0-专注值与战技.md` | 新写 | 玩法拆解表 / 漏洞 P0~P2 / GDD 六项 / 三栏清单 / 节点信号链 / 真跑数字 / 验收三态 / 风险回滚 / 下一版 backlog（**只列零付费零外部依赖增量**） |
| ⑧ | `README.md`（工程根） | 修改（状态段追加） | 头部追加 R36 状态行 + 文末追加 §七「v0.13.0 状态表」（7.1 状态表 / 7.2 资产表增量 / 7.3 已做增量 / 7.4 还差增量）；历史行一律保留未动 |
| ⑨ | `teamwork/Rank-3/DONE-R36.md` | 新写 | 本交付报告 |
| ⑩ | `teamwork/Rank-3/R36-*.log`（11 份） | 新写 | 三段门禁 + 两份 verify + 三态真跑 stdout 留档，逐份 `SCRIPT ERROR=0 / Parse Error=0 / ERROR 前缀=0` |
| ⑪ | `teamwork/command_center/ai/3/outbox/cmd-20261112-154132-916-A3.json` | 新写 | 本轮回执（**`teamwork/command_center/`**，非工程根） |

### 只读未改（硬约束）
`godot/project.godot`（既有 7 项 autoload）、`godot/scenes/courtyard.tscn`（节点 41 / uv `2/1/1` / 节点名）、`godot/test/presentation.gd`、`godot/scripts/hud.gd` / `encounter_director.gd`（Rank-1）、`wave_trial_director.gd` / `focus_service.gd` / `focus_config.gd` / `focus_rules.tres`（Rank-2）、`hd2d_fx.gd` / `impact_feedback.gd`（Rank-4）、全部既有 `.tres` 数值、其它 Rank 产出。

---

## 2. 实现说明（A66 / A48① / A54）

- **A54 唯一实例**：编排层 `_find_focus_service()` 从 `SceneTree.root` 相对查找 `WaveTrialDirector` 节点 → 调 `get_focus_service()` 复用 Rank-2 装配的唯一真实 `FocusService`（RefCounted，**绝不 new 第二个**）；`verify_focus_production_v130.gd` P06 实证两次 getter 同一实例。
- **A48① 生产运行时订阅者**：`PointsCommitOrchestrator` autoload 的 `bind_focus_service()` 在**生产脚本内** connect `focus_spent` / `focus_restored` / `focus_rejected` 三信号（`get_signal_connection_list` 去重由 `is_connected` 承担、`_release_focus()` 有 disconnect 释放路径）；`_ready()` 用 `call_deferred("_deferred_bind_focus")` 延迟绑定、最多 6 次重试、耗尽仅 `push_warning`（不订阅 / 不写盘 / 不报错）。**G3 `--headless --quit` 真跑实证 `[R36][PCO] A66 生产订阅者已绑定 FocusService 唯一实例 | signals=3`（真实主场景自动绑定、非验证脚本）**，无输入不写盘。
- **FP 落盘口径**：三信号回调签名逐字对齐 Rank-2 DONE §3.1；`_commit_focus()` 复用既有 `_commit(reason)`（十字段冻结 / `schema_version=3` / `removals=[]` / `.tmp→flush→rename→delta.json+.bak` 原子写 / ★ 成功后才 `_apply_snapshot` 注入磁盘真值 + emit），并**显式隔离** `focus_writes`：必须全为 `combat.focus.` 前缀、通过三段式正则、标量白名单，且绝不含 `K_POINTS` / `K_SPENT`。
- **重复释放不二次扣费**：① 生产 `FocusService` 冷却期重复 `spend_fp` 幂等拒绝、不发 `focus_spent`；② 编排层二次门控 `new_cur`（`fp_remaining`）必须严格 `<` 磁盘旧 `combat.focus.current`，否则（重放 / 误发 / 异常）拒绝、不落盘、`spend_count` 不增。
- **FP 上限不被突破**：`_focus_max_value()` 经唯一实例 `get_fp_max()` 鸭子读上限；`_on_focus_spent` 对 `new_cur > max` 直接拒绝；`_on_focus_restored` 对 `fp_after > max` 封顶到 `max`。
- **`focus_rejected` 订阅职责**：只写 `combat.focus.last_reject`（String），绝不动 `current` / `spend_count` / 赐福点数（真实运行时消费、非空订阅）。
- **安全降级 / 惰性初始化**：`_commit()` 既有惰性初始化（正则 / 运行时镜像）兜底 `--script` 模式 autoload `_ready()` 未 flush；无 HUD / 无 WaveTrialDirector 的纯 `--import` / `--check-only --quit` 场景重试耗尽仅告警、不写盘、不报错、不 null 解引用；`configure_slot()` 注入独立 PID 临时槽只改落盘目标、不改十字段 / 不改 `project.godot`。

---

## 3. 真跑输出原文（最终统一三段门禁 · `SCRIPT ERROR=0`）

命令前缀统一 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；引擎版本行 `Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org`；日志留档 `teamwork/Rank-3/R36-*.log`（11 份，均为实际 stdout）。

### 3.1 三段门禁 EXIT 汇总（11 次引擎调用全 `EXIT=0`）

```
===== G1 --headless --import =====                     G1_EXIT=0
===== G2a --check-only --script（4 件）=====
  G2a_points_commit_orchestrator EXIT=0
  G2a_verify_v130_save_commit EXIT=0
  G2a_verify_focus_production_v130 EXIT=0
  G2a_verify_fx_mobile EXIT=0
===== G2b --headless --script（2 verify + 三态）=====
  G2b_save_commit EXIT=0
  G2b_focus_production EXIT=0
  G2b_tri_write EXIT=0
  G2b_tri_load EXIT=0
  G2b_tri_assert EXIT=0
===== G3 --headless --quit =====                       G3_EXIT=0
```

### 3.2 全工程 `grep SCRIPT ERROR=0`（11 份日志逐份 + 合计）

```
  R36-g1-import.log                              SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_PREFIX=0
  R36-g2a-points_commit_orchestrator.log         SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_PREFIX=0
  R36-g2a-verify_focus_production_v130.log       SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_PREFIX=0
  R36-g2a-verify_fx_mobile.log                   SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_PREFIX=0
  R36-g2a-verify_v130_save_commit.log            SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_PREFIX=0
  R36-g3-quit.log                                SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_PREFIX=0
  R36-run-verify_focus_production_v130.log       SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_PREFIX=0
  R36-run-verify_v130_save_commit.log            SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_PREFIX=0
  R36-tri-assert.log                             SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_PREFIX=0
  R36-tri-load.log                               SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_PREFIX=0
  R36-tri-write.log                              SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_PREFIX=0
  ---- 合计 SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_PREFIX=0 ----
```

### 3.3 两份 verify + 三进程三态 SUMMARY / RESULT

```
[V130-C] SUMMARY mode=all pid=22796 slot=user://saves/verify_v130_22796 pass=70 fail=0 total=70
[V130-C] OVERALL=PASS
[V130-C] RESULT=ALL_MATCH
[V130-FP] SUMMARY pid=25652 slot=user://saves/verify_v130_fp_25652 pass=49 fail=0 total=49
[V130-FP] OVERALL=PASS
[V130-FP] RESULT=ALL_MATCH
[V130-C] SUMMARY mode=write pid=26636 slot=user://saves/verify_v130_r36final pass=23 fail=0 total=23   → RESULT=ALL_MATCH
[V130-C] SUMMARY mode=load pid=36696 slot=user://saves/verify_v130_r36final pass=11 fail=0 total=11   → RESULT=ALL_MATCH
[V130-C] SUMMARY mode=assert pid=33224 slot=user://saves/verify_v130_r36final pass=50 fail=0 total=50 → RESULT=ALL_MATCH
```
- 三进程三态 `write 23 + load 11 + assert 50 = 84 PASS / 0 FAIL`，三 pid `26636 / 36696 / 33224` **互不相同**。
- **PASS/FAIL 汇总**：两份新脚本 `all` 模式 `70 + 49 = 119 PASS / 0 FAIL`；三进程三态 `84 PASS / 0 FAIL`；合计 **`203 PASS / 0 FAIL`**，全 `RESULT=ALL_MATCH`。

### 3.4 `verify_focus_production_v130.gd` 关键断言原文（真实链路读磁盘）

```
[V130-FP] B00 ★ A48③：运行时树零 presentation.gd 脚本节点（不加载演示驱动） PASS=true | found=false
[V130-FP] B03 ★ A48① 生产订阅者存在性（运行时）：3 信号 connection_list 均含编排层回调 PASS=true | subs={ "focus_spent": true, "focus_restored": true, "focus_rejected": true }
[V130-FP] R00 前置赐福点数已由生产编排层落盘 PASS=true | points=500 spent=15
[V130-FP] R03 ★ 战技扣 FP → 落盘：磁盘 combat.focus.current 减少且与真实服务 FP 一致 PASS=true | disk_current=88 service_fp=88 fp_max=100
[V130-FP] R06 ★ FP 连续扣减（只减不增） PASS=true | cur1=88 cur2=53 service_fp=53
[V130-FP] R09 schema_version=3、removals 恒空 PASS=true | schema=3.0 removals=[]
[V130-FP] R11 ★ A66 FP 与赐福点数分离：points / spent_points 在 FP 落盘前后逐字不变 PASS=true | points=500==500 spent=15==15
[V130-FP] R12 ★ A66 7 个 FP flag 全为 combat.focus.* 前缀，绝不混用 points / spent_points PASS=true
[V130-FP] R14 ★ 赐福休息回满 → 落盘 PASS=true | cur_before_rest=53 cur_rest=100 service_fp=100 fp_max=100
[V130-FP] Z01 ★ FP 上限不被突破 PASS=true | cur1=88 cur2=53 cur_rest=100 max=100
[V130-FP] Z02 ★ 回满恰等于 max（不突破上限） PASS=true | cur_rest=100 service_max=100
[V130-FP] Z03 ★ A66 分离口径在回满后仍成立 PASS=true | points=500 spent=15
[V130-FP] Z05 ★ 第 2 次重复释放被拒（cooldown） PASS=true | ok=false reason=cooldown
[V130-FP] Z06 ★★ 重复释放不二次扣费：current / spend_count 在第 2 次后完全不变 PASS=true | cur 100→88→88 spend 2→3→3
[V130-FP] Z07 ★ focus_rejected 有生产订阅者消费落盘 PASS=true | last_reject=cooldown current=88
[V130-FP] Z08 ★ A66 分离口径全链最终成立 PASS=true | points=500==500 spent=15==15
[V130-FP] Z09 生产编排层真实 commit 次数 > 0（非验证脚本自模拟） PASS=true | commit_count=7
[V130-FP] X02 ★ 重启读回一致：新 WorldState 逐项 get_flag == 磁盘 PASS=true | flags=12 项逐项比对
[V130-FP] X03 重启读回 FP 三态一致 PASS=true | current=88.0 max=100.0 spend=3.0
[V130-FP] X05 生产 slot_01 md5 前后一致 PASS=true | md5=b69805a97c3a044d7a0653b2d7422a60
```

### 3.5 G3 `--headless --quit` 关键日志（真实主场景、无输入不写盘）

```
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
[R36][WaveTrial] 专注值/战技生产订阅者已装配：FocusService 唯一实例 + 4 信号 connect（A48①/A54）
[R36][PCO] A66 生产订阅者已绑定 FocusService 唯一实例 | signals=3 slot=user://saves/slot_01（FP 落盘与赐福点数分离）
```

> 既有退出 WARNING 如实登记（非本轮引入、非 `SCRIPT ERROR`、不影响 `EXIT=0`）：`[SaveSystem] --script 工具模式…跳过自动读回`、`2 ObjectDB instances were leaked at exit`；G3 中编排层 autoload 在真实主场景自动绑定 FocusService（A48① 生产订阅者实证），但 `--headless --quit` 无输入 → 无 `focus_*` 信号 → **不写盘**。

---

## 4. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① `points_commit_orchestrator.gd` 订阅三信号、7 个 `combat.focus.*` 三段式 flag 落盘、A66 与赐福点数分离、先落盘后改实例、重启读回一致、重复释放不二次扣费、上限封顶、安全降级全部落地；② 两份新验证件 `70 PASS` + `49 PASS / RESULT=ALL_MATCH`、三进程三态 `84 PASS / 0 FAIL`（三 pid 互不相同）、合计 `203 PASS / 0 FAIL`；③ 真实可达回归不加载 `presentation.gd`（B00 `found=false` 运行时树实证）、不在验证脚本内模拟编排（编排全在生产 autoload、`commit_count=7` 真实落盘）；④ 文档口径同步：规范 §3.3 补 10 行 + R35/R36 注记、`verify_fx_mobile.gd` 头部 A63 口径（只改注释、断言逻辑零改动、`check-only EXIT=0`）；⑤ 契约 §3.3 只追加 R36 段（7 flag + A65~A68），历史条款 / I-1~I-6 / §3.1 §3.2 缺号未动；⑥ 迭代文档 + README 状态段追加、历史行未删；⑦ 三段门禁全 `EXIT=0`、11 份日志 `SCRIPT ERROR=0 / PARSE_ERROR=0 / ERROR 前缀=0`、G3 `node_count=41`；⑧ 生产 `slot_01` md5 前后一致、`courtyard.tscn` 节点 41 / uv `2/1/1` 未破坏；⑨ 只写授权文件、零付费、零外部依赖、不启 GPU job、不自行 git、未删 `.workbuddy`。 |
| **失败 / 未达** | ① **HD-2D 全绿未达**（A68 按 A41/A52/A61 三判据，光效仍 2D `_draw()` / screen-reading shader 近似、不切后端 A30）；② **程序化光环 / 闪光可辨识度未做定稿录屏目视**（A67：代码断言不算画面验收，headless 无帧缓冲，由总指挥亲自回看）；③ 连击 D→A→S 完整评级序列 / S 级收束爆发实机可见性沿用 R36 Rank-1 结论「链路已接线、演示目视未覆盖」；④ 既有退出 WARNING 未清理（非本轮引入、非 `SCRIPT ERROR`）。 |
| **需用户确认 / 待裁决** | 见 §7 / §8。 |

---

## 5. FP 与赐福点数分离实证（任务单① 硬口径专节）

| 层 | 证据 | 结论 |
|---|---|---|
| **键名层** | 7 个 FP flag 全为 `combat.focus.*` 前缀（`current` / `max` / `art_id` / `spend_count` / `restore_count` / `policy` / `last_reject`）；赐福点数为 `grace.trial.points` / `grace.trial.spent_points`。`R12` 机器判定 7 key 全为 `combat.focus.*`、与 points/spent 无交集；三态 `C03/C04` 反例判定 | **零键名混用** |
| **代码隔离层** | `_commit_focus()` 前置校验 `focus_writes` 必须 `begins_with("combat.focus.")`、通过三段式正则、标量白名单，且 `key != K_POINTS / K_SPENT`；既有 `_commit()` 只应用 `focus_writes`、不触碰 points/spent；三态夹具 `_full_flags()` 中 points/spent 由既有 A55/A59 通道产生、FP 事件一律不写二者 | **零写入路径交叉** |
| **磁盘前置层** | 真实链路先经生产 HUD `points_awarded` / `boon_draft_applied` 落盘 `points=500` / `spent=15`（`R00`），作为分离对照基线 | 基线存在、非零 |
| **全链磁盘层** | `R11`（战技扣 FP 后）`points=500==500 spent=15==15`；`Z03`（赐福休息回满后）`points=500 spent=15`；`Z08`（重复释放后）`points=500==500 spent=15==15`。FP 自身 `current 100→88→53→100→88`、`spend 1→2→3`、`commit_count=7`（含 7 次真实 FP/既有 commit）| **FP 全链 7 次落盘，points/spent 逐字不变** |
| **重启层** | `X02` 新 WorldState 从磁盘 `_apply_snapshot` 12 项逐项一致；`X03` `current=88 / max=100 / spend=3`；三态 `B00` 9 个关键 flag 三方一致（磁盘 / 期望 / 读回），`C01/C02` points=500 / spent=15 三方一致 | **重启读回不串值** |
| **三态口径层** | `verify_v130_save_commit.gd` C 组 `C01`（points==500 且 == 期望）、`C02`（spent==15 且 == 期望）、`C03`（7 个 FP key 纯 `combat.focus.*`）、`C04`（FP flag 绝不写入 points/spent 键名）；F 组上限不突破、G 组重复释放不二次扣费（反例 `spend_count != 6`） | **机器判定分离 + 边界** |

> **实证结论**：FP 与赐福点数在键名、写入路径、磁盘值、重启读回、三态口径五层均**完全分离**；`points=500==500` / `spent=15==15` 全链逐字不变，FP 消耗 / 回满 / 拒绝全部只落到 `combat.focus.*`，**不混用 `points` / `spent_points`**。

---

## 6. 文档口径同步逐处对照（任务单 ③④⑤ / R35 遗留 P0）

| 处 | 改前 | 改后 | 性质 / 实证 |
|---|---|---|---|
| `teamwork/00-协作契约.md` §3.3 | 止于 R35 说明段（A58~A61）+ R34C 等历史段 | **只追加 R36 说明段**：7 个新 flag 逐条登记 + 三段式 / 十字段关系 + **裁决 A65 / A66 / A67 / A68** 全文 + 未动声明 | 历史条款 / I-1~I-6 接口表 / §3.1 §3.2 缺号 / A39~A64 裁决登记 / 各轮历史说明段**一律未改**；追加位置在 R35 段末「未动」行之后、`## 4.` 之前 |
| `teamwork/Rank-3/存档与flag规范.md` §3.3 全局登记表 | 表格止于 R34 的 `combat.combo.count`；R35 的 3 个 `combat.parry.*` / `grace.boon_draft.unlocked` **漏登（R35 遗留 P0）** | 补 **10 行**：R35 遗留 3 行 + R36 新增 7 行 `combat.focus.*`；注记块追加「R35 / v0.12.0（R36 补登 · R35 遗留 P0）」+「R36 / v0.13.0」两段 | 历史表格行 / R26~R34 注记 / §3.1 §3.2 / §4 结构**一律未改**；补齐行标注「R35 遗留 P0 补登」 |
| `godot/scripts/verify_fx_mobile.gd` 头部注释 | ① 第 15~17 行「回读四项绘制门全 false」「差异对照表（桌面四项全开 / 移动四项全关）」；② 第 19 行「关掉四项光效后画面主体仍可读」；③ 无 A63 口径说明 | 头部追加 5 行 A63 口径说明（轻量环 + HUD 文字 / 不劣化 ≠ 不绘制）；职责 ②③ 同步为「轻量降级绘制」（FXBloom `visible=true` 走轻量绘制、其余 3 节点 `visible=false`）；④ 同步为「关掉四项重光效、保留轻量环 / HUD 文字后画面主体仍可读」 | **只改 `##` 头部注释**；断言逻辑（167~250 行 A63 已于 R35C 同步期望值）**逐字不动**；`--check-only --script` / G2a `EXIT=0`、`SCRIPT ERROR=0` |
| `teamwork/迭代-v0.13.0-专注值与战技.md` | 不存在 | **新写**：玩法拆解表 / P0~P2 / GDD 六项 / 三栏清单 / 节点信号链 / 真跑数字 / 验收三态 / 风险回滚 / 零付费零外部依赖 backlog | 所有新数值标 `[PLACEHOLDER]` + rationale + 调参唯一入口（只改表 / 常量不改逻辑） |
| `README.md`（工程根） | 头部引用块止于 R34；文末止于 §六（R35 / v0.12.0 状态表） | 头部追加 1 行 R36 状态行；文末**追加 §七**（7.1 状态表 / 7.2 资产表增量 / 7.3 已做增量 / 7.4 还差增量） | 一 / 二 / 三 表格、§四~§六、全部「总指挥定稿」历史行**一律保留未动**（只追加、不删历史行）；资产表字节数 `os.path.getsize` 实测、不编造 |

---

## 7. 未完成项（如实登记，不冒充）

1. **定稿录屏 / 目视帧（A67）**：程序化光环 / 闪光可辨识度必须在 15~20 秒定稿录屏关键帧由总指挥亲自目视确认，代码断言不算画面验收；headless 无帧缓冲，Rank-3 不代做手感 / 审美判断。本轮不含新录屏 / 抽帧 / 目视结论。
2. **`[PLACEHOLDER]` 试玩校准**：`focus_rules.tres` 的 `fp_max` / `fp_regen_on_rest` / 两战技 12 项数值、A59 `COST_TO_POINTS_FACTOR` 常量段待人工试玩校准；调参唯一入口见迭代文档 §1.2（只改表 / 常量不改代码）。
3. **HD-2D 全绿（A68）**：差距清单（真 DoF / 真 `volumetric_fog` / SSR / `Environment.glow` / Forward+）沿用 R35B/R35C 保持未达，A30 不切后端。
4. **连击 D→A→S 完整序列 / S 级收束爆发实机可见性**：沿用 Rank-1 R36 结论「链路已接线、演示目视未覆盖」，待总指挥定稿录屏。
5. **`focus_rejected` 落盘策略**：本轮为「生产订阅者非空职责」选择每次被拒原子写 `combat.focus.last_reject`（增加 commit 次数、不影响扣费）；是否改为只做运行时观测不落盘待裁决（§8）。
6. **多战技切换 / FP 条 `ProgressBar` / 既有 WARNING 清理 / 演示 D→A→S 覆盖**：均列迭代文档 §9 backlog（零付费零外部依赖增量），本轮授权边界外，未越界做、未冒充完成。
7. **既有退出 WARNING**（`[SaveSystem] --script 跳过自动读回` / `2 ObjectDB instances were leaked`）非本轮引入、非 `SCRIPT ERROR`，未清理、如实保留。

---

## 8. 待总指挥裁决项（只登记、不擅改）

1. **`focus_rejected` 落盘策略**：是否改为「只运行时观测、不落盘 `combat.focus.last_reject`」（本轮为 A48① 订阅者非空职责选择落盘）；涉编排层一个回调 + 两份验证断言。
2. **每波是否回满 FP / `rest_refill` 最终档位**：沿用 Rank-2 DONE §7 待裁决（本轮设计为跨波资源、仅赐福休息 / 新局 `reset()` 回满），请裁决；`rest_refill=true/false` 切换只改 `focus_rules.tres` 一行 + 补回归。
3. **多战技切换键位 / FP 条形态**：Q 单键固定首战技（Rank-1 现状），是否补第二战技切换 / `ProgressBar` 节点（涉 Rank-1 输入层 + Rank-2 表 + 避让断言同步）。
4. **A65 免伤范围 / A67 目视结论 / A68 HD-2D 全绿路线**：A65 按「窗口内成功 → 免除该次招式伤害 + guard 一次性消费」登记，若需窗口时长内多次免伤 / 叠加口径请裁决；A67 定稿录屏目视、A68 全绿路线由总指挥定夺。
5. **定稿录屏目视结论（A42 / A67）**：大矩形收敛后续 / FP 条 / 战技 / 免伤 / 光环闪光 / 连击高评级画面，由总指挥亲自重跑回看。
6. **`128bit` 歧义**：继续保留 A53（A15 / A43 / A61 保留口径、不消歧、不编码进期望值、以用户后续确认为准）。
7. **Rank-1 / Rank-2 并行接口异议**：本轮编排层对 FocusService 用鸭子多候选 + 判空降级（不静态引用 `class_name`）；若 Rank-2 后续微调 `get_focus_service()` / `get_fp_max()` / 信号签名，请复核编排层 `_find_focus_service()` / `_focus_read_max()` 兼容性。
8. **回执中枢归档**：见 §10，按中枢实际回收状态如实登记。

---

## 9. 硬约束遵守声明

- **只写授权文件**：`points_commit_orchestrator.gd`、两份新验证脚本、`00-协作契约.md` §3.3 追加段、`存档与flag规范.md` §3.3、`verify_fx_mobile.gd` 头部注释、新迭代文档、`README.md` 状态段、`teamwork/Rank-3/`（DONE + 11 份日志）、回执；**未改** `godot/` 其它业务代码、契约其它历史条款、其它 Rank 产出。
- **`project.godot` 本轮只读**（既有 7 项 autoload 不动）、`courtyard.tscn` 节点 41 / uv `2/1/1` / 节点名（A38 断言）只读、`presentation.gd` 只读、全部既有 `.tres` 数值只读。
- **SaveDelta 十字段与 `schema_version=3` 冻结**：7 个新 flag 只作 `flags` 字典新 key，不新增顶层字段 / 不引入嵌套 / 不触发迁移 / 不写 `removals` / 不回退 `grace.trial.points`；`commit(reason)` 原子写、先落盘再改运行时实例、重启读回一致。
- **Godot `--script` 纪律**：`extends SceneTree` 用 `Engine.get_main_loop() as SceneTree` 取 root，不用 `get_tree()`、不用 `/root/...` 绝对路径；`add_child` 后显式 `call("_ready")`（不依赖自动 flush）；资源回读 `CACHE_MODE_IGNORE`；三态 / 生产验证用**独立 PID 临时槽**（`verify_v130_<pid>` / `verify_v130_fp_<pid>` / `verify_v130_r36final`），不碰生产 `slot_01`；编排层 autoload 在无 HUD 的纯 `--import` / `--check-only --quit` 场景惰性初始化 / 安全降级、不报错不写盘（G1/G2a/G3 实证）。
- **A48 硬要求**：① 3 个新信号的生产运行时订阅者 = 编排层 autoload（G3 实证自动绑定 + `B03` connection_list）；② A54 唯一实例经 `get_focus_service()` 复用（`P06` 两次同一实例）；③ 一条不加载 `presentation.gd`（B00）、不模拟编排的真实可达回归 `verify_focus_production_v130.gd`（`commit_count=7`）；④ 纯逻辑 + 单元断言不算可玩交付，headless 无帧缓冲、不冒充实机目视。
- **零付费、零外部依赖、不启 GPU job**；不伪造产物、不谎报成功、不自行 git（总指挥收尾）；未删除 `.workbuddy` 目录。
- **默认不刺探**：未扫目录做进度巡检、未写只读探针 / 巡检脚本、未反复核对文件状态；仅按任务单要求读必做文件 / 目标文件、真跑输出判断、回执目录与中枢归档结构确认。

---

## 10. 回执与中枢归档确认（写后实测，如实登记）

- 回执写入授权路径（**`teamwork/command_center/`**，非工程根）：`teamwork/command_center/ai/3/outbox/cmd-20261112-154132-916-A3.json`，四字段 `{"task_id":"cmd-20261112-154132-916-A3","ai":3,"status":"done","result":"…引用 DONE-R36.md 实际结论…"}`。
- **中枢归档回读确认（写后实测，如实登记、不伪造）**：
  - 回执写入 `outbox` 后被中枢**实时回收**：`ai/3/outbox/` 复查已清空（剩余条目 `[]`），属中枢正常处理、不重放、不伪造。
  - **归档副本**：`teamwork/command_center/dispatcher/receipts/cmd-20261112-154132-916-A3.json` 存在（**1855 字节**），回读 **VALID_JSON**，四字段齐全 `keys=['ai','result','status','task_id']`，`task_id=cmd-20261112-154132-916-A3` / `ai=3` / `status=done` / `result_len=1089`，与 outbox 回执逐字一致。
  - `ai/3/status.json` 更新为 `{"ai":3,"state":"idle","current_task":"","completed":41,"last_seen":"2026-11-12 17:37:59"}`（`completed` 由 40 → 41、`current_task` 清空、`state` working → idle）。
  - `dispatcher/ledger.jsonl` 本单条目 `id=cmd-20261112-154132-916-A3 ai=3 status=done finished_at=2026-11-12 17:37:59 result_len=1089`，与回执 `result` 逐字一致；派单 `issued_at=2026-11-12 15:41:33` 与任务单一致。
  - `dispatcher/dispatcher.log` 尾部原文：`[2026-11-12 17:37:59] ← 3 号 AI 回执 <cmd-20261112-154132-916-A3> 完成：R36/v0.13.0 交付完成，实际结论见 teamwork/Rank-3/DONE-R36.md：① A66 专注值`，确认 id 与派单一致、中枢已回收验证 `done`。
  - 注：本轮归档副本文件名为 `receipts/<id>.json`（非 `receipt_<id>.json` 前缀），`status.json` / `ledger.jsonl` / `dispatcher.log` 三处均实证回收；如实登记、不臆造文件名。
