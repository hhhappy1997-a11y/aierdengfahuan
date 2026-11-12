# DONE-R35.md · R35 / v0.12.0「精准弹反 · 消费闭合」交付报告（Rank-3）

> 轮次：`R35 / v0.12.0` ｜ 派单 id：`cmd-20261112-125821-143-A3` ｜ 执行 AI：`3（Rank-3 RPG / 世界 / 存档）`
> 真源：`teamwork/Rank-3/调度任务单-latest.json`（`task` 全文 + 公共契约 + 目录所有权 + A48 硬要求）＋ `teamwork/Rank-1/DONE-R35.md`（A58 window_id / `parry_performed` 信号）＋ `teamwork/Rank-2/DONE-R35.md` §3（ParryService 接口）＋ `teamwork/00-协作契约.md` §3.3 历史条款。**以任务单为准**。
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> 结论：**任务 ①②③④⑤⑥ 全部落地。A59 把 `grace.trial.spent_points` 唯一出口接到生产编排层 autoload（抉择 cost → `[PLACEHOLDER]` points 映射 → 单调累加 + unlocked flag 同一次 commit 原子写 + 余额门控 + 重复购买拒绝 + 缺失非法拒绝告警 + 绝不写 removals / 绝不回退 points）；A58 订阅 `parry_performed`（A48① 生产订阅者，5 信号）把 `exe:` / `parry:` 去重键改接非空唯一 window_id，第二次弹反真实入账、不同窗口不合并。两份新验证脚本 + 契约 §3.3 R35 段 + 迭代文档 + README 状态段落地。三段门禁全 `EXIT=0`、全工程 `SCRIPT ERROR=0 / Parse Error=0 / ERROR 前缀=0`；两份新脚本 `RESULT=ALL_MATCH`（70 + 39 PASS）、三进程三态 72 PASS、既有 7 份回归 350 PASS 全绿；A38 节点 41 / uv `2/1/1`、生产 `slot_01` 基线 `md5=219cbf043d3ae14a97f66c44f0e9591e` 零改动。如实登记：headless 无帧缓冲、15~20 秒实机录屏目视由总指挥亲自判定；`cost→points` 系数与弹反数值仍 `[PLACEHOLDER]` 待人工试玩校准；HD-2D 全绿（A41/A52）未达、`128bit`（A53）继续保留。**

---

## 1. 交付清单（实际落地文件，本轮唯一写入方 = Rank-3）

| 文件 | 类型 | 实际改动 |
|---|---|---|
| `godot/scripts/rpg/points_commit_orchestrator.gd` | 修改（重写，保留全部既有逻辑 + 文件尾追加 R35 段） | **任务① A59 + 任务② A58**：`BOUND_SIGNALS` 4→5（新增 `parry_performed` 生产订阅者）+ `CORE_SIGNALS`（4，保证既有 `bind_hud` 口径兼容）；新增 `K_UNLOCKED` / `K_PARRY_COUNT` / `K_PARRY_WID` 三段式 flag 常量、`[PLACEHOLDER]` cost→points 映射常量段（含 rationale / 调参唯一入口）、R35 运行时门控态；`_on_parry_performed`（配对键 `parry:<wid>`，空 id 降级唯一键 + 告警）；`_resolve_event_key` 加 parry 分支；`_on_points_awarded` 把两个弹反 flag 与 points 同一次 commit 原子写；`_on_boon_draft_applied` 改为调 `_try_charge_boon_cost`（A59 唯一出口）；`_on_production_wave_modifier` 加 cost 一致性对账（绝不二次扣费）；`_on_execution_performed` 加空 window_id 防御；新增 `_validate_cost` / `_cost_to_points` / `_try_charge_boon_cost`；`get_status()` 追加观测键；`_ready` / `_commit` 惰性镜像补齐 3 个新 key。**A55/A57 既有逻辑逐字保留**（`points_awarded` 唯一权威通道、points 原样采信）。 |
| `godot/scripts/rpg/verify_v120_save_commit.gd` | **新增** | **任务③**：三进程三态（`write` / `load` / `assert` / `all`）存档验证件，`all` **70 PASS / 0 FAIL**、三进程 **17+6+49=72 PASS / 0 FAIL**；覆盖 A59 单调累加 / 原子写 / 余额 / 重复拒绝 / 缺失非法拒绝 / 绝不写 removals / 不回退 points、A58 两个不同 parry 键与两个不同 exe 键不合并、A60 防通胀反例、十字段冻结 / schema=3 / 三段式正则 / 旧档回落 / 重启读回一致。 |
| `godot/scripts/rpg/verify_spent_points_production_v120.gd` | **新增** | **任务③ / A48③**：不加载 `presentation.gd`、不在验证脚本内模拟编排；实例化主场景 → `bind_hud` 生产订阅者（5 信号）→ 生产 HUD 真实运行时信号 → 生产编排层 autoload 落盘 → 读磁盘断言六项链；独立 PID 临时槽。**39 PASS / 0 FAIL / RESULT=ALL_MATCH**。 |
| `teamwork/00-协作契约.md` §3.3 | 修改（**只追加** R35 说明段） | **任务④**：登记 3 个新三段式 flag（`combat.parry.success_count` int / `combat.parry.window_id` String / `grace.boon_draft.unlocked` bool）与裁决 **A58**（window_id 非空唯一）/ **A59**（spent_points 唯一出口归属编排层）/ **A60**（弹反奖励 `[PLACEHOLDER]` 不得点数通胀 + 5 类 broken 判据）/ **A61**（HD-2D 全绿仍按 A41/A52、`128bit` 继续保留 A53）。历史条款 / I-1~I-6 / §3.1 §3.2 缺号一律未改。 |
| `teamwork/迭代-v0.12.0-精准弹反与消费闭合.md` | **新增** | **任务⑤**：玩法拆解表 / 漏洞识别 P0~P2 / GDD 六项 / 三栏清单 / 节点信号链 / 真跑数字 / 验收三态 / 风险回滚 / 下一版 backlog（**只列零付费零外部依赖增量**）。 |
| `README.md` | 修改（追加 §六，不删历史行） | **任务⑤**：追加 §六 R35 / v0.12.0 状态表（6.1 状态表 / 6.2 资产表 / 6.3 已做增量 / 6.4 还差增量），所有历史行保留未动。 |
| `teamwork/Rank-3/R35-*.log` | 新增（17 份） | 三段门禁 + 回归真跑 stdout 留档，合计 157,498 B；逐份 `SCRIPT ERROR=0`。 |
| `teamwork/Rank-3/DONE-R35.md` | 新增 | 本报告。 |
| `teamwork/command_center/ai/3/outbox/cmd-20261112-125821-143-A3.json` | 新增 | 本轮回执（§11 写后确认中枢归档）。 |

### 只读未改（硬约束）

`godot/scripts/combat/encounter_director.gd` / `godot/scripts/hud.gd` / `godot/test/presentation.gd` / `godot/scripts/render/verify_*`（Rank-1 所有）、`godot/scripts/combat/wave_trial_director.gd` / `parry_service.gd` / `parry_config.gd` / `verify_parry_*.gd` / `data/combat/parry_rules.tres`（Rank-2 所有）、`godot/scripts/hd2d_fx.gd` / `assets/generated/r23/`（Rank-4 所有）、`godot/project.godot`（既有 autoload，本轮只读）、`godot/scenes/courtyard.tscn`（A38 节点 41 / uv `2/1/1`）、既有 `.tres` 数值、其它 Rank 产出。未删除 `.workbuddy`。

---

## 2. 任务① · A59 接管 `spent_points` 出口（生产编排层）

### 2.1 链路（生产运行时，非演示驱动）
```
Rank-1 HUD _r34_settle_boon_draft() → boon_draft_applied(index, choice_id, effect_key, effect_value, cost_key, cost_value)
Rank-1 HUD 下一波 wave_started     → production_wave_modifier(wave_index, effect_key, effect_value, cost_key, cost_value)
        ↓（生产订阅者 = PointsCommitOrchestrator autoload，BOUND_SIGNALS 5 信号）
_on_boon_draft_applied → _try_charge_boon_cost("boon:<index>", choice_id, cost_key, cost_value, "boon_draft_cost_applied")
   ① _validate_cost：cost_key 命中白名单且非空、cost_value 有限且 > 0 → 缺失/非法拒绝 + push_warning
   ② _claimed.has(dedup_key) → 重复购买拒绝 + 告警（spent 不二次累加）
   ③ _read_delta()：磁盘为唯一权威，p = points / s = spent，余额 p − (s + cost_points) ≥ 0 前置门控
   ④ writes{K_SPENT: s+cost_points, K_SELECTED: choice_id, K_COST: true, K_UNLOCKED: true}
      → 一次 _commit("boon_draft_cost_applied", writes, 0, p) 原子写
         （writes 绝不含 K_POINTS → 绝不回退 points；_commit 恒 removals=[] → 绝不写 removals）
   ⑤ 落盘成功才 _claimed[dedup_key]=true + 更新运行时镜像 + emit；失败不改内存、告警
_on_production_wave_modifier → _pending_wave_key = "wave:<index>" + cost 一致性对账
      ★ 与 boon_draft_applied 是同一抉择的两个阶段 → 只做配对键 + 对账，绝不二次扣费
```

- **cost→points `[PLACEHOLDER]` 映射**：Rank-2 `boon_draft_service.apply()` 的 `cost_value` 是「下一波敌人难度乘性修正」（`hp_scale` / `telegraph_scale`，> 0 倍率）**并非点数**；A59 用 `points_cost = max(MIN, round(cost_value × FACTOR))` 线性折算（`FACTOR=10.0` / `MIN=1` `[PLACEHOLDER]`）。rationale：真实经济平衡（点数产出速率 vs 抉择代价）须人工试玩校准、headless 不做手感判断。**调参唯一入口 = `points_commit_orchestrator.gd` 常量段（集中一处、只改常量不改逻辑；目录所有权冻结、本轮不新增数据表）**；`COST_KEY_WHITELIST` 与 Rank-2 `boon_draft_config.gd::is_cost_key_known` 对齐。
- **原子性**：`spent_points` 累加与 `grace.boon_draft.unlocked` / `.selected` / `.cost_applied` 四者落在**同一次 `_commit` 的 writes 字典**（一次 `.tmp → flush → rename → delta.json + .bak`），不存在「扣了费没解锁」或「解锁了没扣费」中间态。
- **不变量**：余额前置门控在落盘前；`writes` 不含 `K_POINTS`；`_commit` 恒 `removals=[]`、校验 `p < runtime_points` 拒绝回退、`p − s < 0` 拒绝透支；缺失/非法/重复/余额不足共 4 类拒绝均 `push_warning`、不静默。

### 2.2 新数值（全部 `[PLACEHOLDER]`）

| 数值 | 来源 / rationale |
|---|---|
| `COST_TO_POINTS_FACTOR=10.0` / `COST_TO_POINTS_MIN=1` | `points_commit_orchestrator.gd` 常量段；把「难度倍率」折算成点数消耗，取 10.0 使 `cost_value=1.5` → 15 点（与既有 `execute_bonus_points=50` / `points_bonus=50` 同量级）；MIN 防 0 值空转 |
| `COST_KEY_WHITELIST = [hp_scale, telegraph_scale]` | 对齐 Rank-2 `boon_draft_config.gd::is_cost_key_known`；新增 cost_key 须同步本常量，否则拒绝并告警 |
| `grace.boon_draft.unlocked`（bool / false→true 单向） | 契约 §3.3 R35 段新登记；与 `spent_points` 同一 commit，一次性永久成就、无 `false` 回写路径 |

---

## 3. 任务② · A58 去重键 + 订阅 `parry_performed`（修 Rank-1 交办缺口）

- **缺口（Rank-1 交办）**：Rank-1 已生成非空唯一 window_id（`exe_0_1/exe_0_2`、`parry_0_1/parry_0_2`）并实证编排层 `claimed` 含两个不同 `exe:` 键；但编排层**尚未订阅 `parry_performed`**，第二次弹反 `points_awarded("parry", 50, "parry_service.try_parry")` 被 `auto:parry:50:...` 指纹去重误拒。
- **本轮闭合**：
  - `BOUND_SIGNALS` 4→5，新增订阅 HUD `parry_performed(window_id: String, bonus_points: int, poise_bonus: float)`（信号签名逐字来自 Rank-1 `hud.gd:40`）。`bind_hud` 的 `_bound` 判定改看 4 个 `CORE_SIGNALS`，保证既有验证脚本 `verify_points_commit_production_v110.gd` 的 P04「4 信号订阅」口径兼容（复跑 `28 PASS` 实证）。
  - `_on_parry_performed(wid, ...)` → `_pending_parry_key = "parry:" + wid`（**保留不消费**：同窗口重放仍解析到同键 → 去重拒绝；不同窗口覆盖成新键 → 各自入账）。空 `window_id` 属上游异常 → 降级 `parry_fallback_<seq>` 唯一键 + `push_warning`（不误合并、不静默）。
  - `_resolve_event_key` 对 `reason=="parry"` 优先返回 `parry:<window_id>`；`reason=="execution"` 仍为 `exe:<window_id>`（加空 id 防御）；`wave_cleared` 仍 `wave:<index>`；无配对键才降级 `auto:` 指纹。
  - `_on_points_awarded` 在 `reason=="parry"` 时把 `combat.parry.success_count`（+1）与 `combat.parry.window_id`（最近 wid）**与 `grace.trial.points` 同一次 commit 原子写**。
- **A55/A57 口径保留**：`points_awarded` 仍是点数落盘唯一权威通道；`points` 是倍率后最终结算值，编排层**原样采信、不二次加工、不自行叠倍率**；`wave_cleared` 基础值 / `combo_settled` 绝不入账。
- **A48①**：`parry_performed` 的生产运行时订阅者 = `PointsCommitOrchestrator` autoload（非验证脚本探针），运行日志 `[R34C][PCO] 生产订阅者已绑定 HUD | signals=5`、`P05` 5 信号 connection_list 均含编排层回调实证；Rank-1 侧 `EncounterDirector` 为另一生产订阅者（削韧 + 连击 guard），职责不同（落盘去重 vs 战斗结算）。

---

## 4. 真跑输出原文（三段门禁 + 全工程 G3）

统一命令前缀：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；引擎日志落 `teamwork/Rank-3/R35-*.log`（17 份，合计 157,498 B，实测 `os.path.getsize`）。

### GATE-1 `--headless --import`
```
G1_EXIT=0
```

### GATE-2a `--check-only --script`（3 件，全 `EXIT=0`）
```
CHECK points_commit_orchestrator.gd EXIT=0
CHECK verify_v120_save_commit.gd EXIT=0
CHECK verify_spent_points_production_v120.gd EXIT=0
```

### GATE-2b `--headless --script <verify>`（9 件 + 三进程三态，全 `EXIT=0`）
```
RUN rpg/verify_v120_save_commit.gd             EXIT=0  70 PASS / RESULT=ALL_MATCH
RUN rpg/verify_spent_points_production_v120.gd EXIT=0  39 PASS / RESULT=ALL_MATCH
RUN rpg/verify_v110_save_commit.gd             EXIT=0  64 PASS / RESULT=PASS
RUN rpg/verify_points_commit_production_v110.gd EXIT=0 28 PASS / RESULT=ALL_MATCH
RUN render/verify_parry_runtime_v120.gd        EXIT=0  27 PASS / RESULT=ALL_MATCH
RUN render/verify_production_chains_v110.gd    EXIT=0  57 PASS / RESULT=ALL_MATCH
RUN render/verify_hud_layout_v100.gd           EXIT=0  36 PASS / RESULT=ALL_MATCH
RUN combat/verify_parry_v120.gd                EXIT=0  58 PASS / RESULT=ALL_MATCH
RUN combat/verify_parry_settlement_v120.gd     EXIT=0  80 PASS / RESULT=ALL_MATCH
TRI write  EXIT=0  17 PASS / RESULT=ALL_MATCH   pid=22792
TRI load   EXIT=0   6 PASS / RESULT=ALL_MATCH   pid=23020
TRI assert EXIT=0  49 PASS / RESULT=ALL_MATCH   pid=492
[V120-C] A02 三进程真跑（write/load/assert pid 互不相同） PASS=true | write=22792 load=23020 assert=492
```
> 既有 7 份回归合计 `64+28+27+57+36+58+80 = 350 PASS / 0 FAIL`，逐字不删不放宽；本轮两新脚本 `70 + 39 = 109 PASS / 0 FAIL`；三进程三态 `17+6+49 = 72 PASS / 0 FAIL`。

`verify_v120_save_commit.gd`（`[V120-C]`，all 模式 70 条逐条 PASS，关键行节选）：
```
[V120-C] W09 A55 编排自洽：points == points_awarded 累加一次 PASS=true | points=400 awarded_sum=400
[V120-C] W10 A59 spent_points == cost1+cost2 单调累加 PASS=true | spent=25 cost1=12 cost2=13
[V120-C] W11 A59 unlocked / selected / cost_applied 与 spent 同一原子写 PASS=true | unlocked=true selected=boon_ember_vein cost_applied=true
[V120-C] W12 A59 缺失/非法/超额/重复共 6 次拒绝 PASS=true | reject_count=6
[V120-C] W13 A58 两个不同 parry 键各自入账、不合并 PASS=true | k1=parry:parry_0_1 k2=parry:parry_0_2
[V120-C] W14 A58 两个不同 exe 键不合并 PASS=true | exe:exe_0_1 / exe:exe_0_2 均在
[V120-C] W15 A60 弹反成功计数恰为 2 PASS=true | parry_count=2
[V120-C] C03 A59 绝不回退 points PASS=true | points=400 awarded_sum=400
[V120-C] G02 A59 防重复扣费（反例 != 落盘值） PASS=true | disk=25 wrong_spent_double=37
[V120-C] G03 A59 unlocked flag 与 spent 同一次 commit 落盘且为 bool true PASS=true
[V120-C] H01 A58 两个不同 parry 窗口各自入账 PASS=true | claimed=["wave:1","parry:parry_0_1","parry:parry_0_2","exe:exe_0_1","exe:exe_0_2","boon:1","boon:2"]
[V120-C] H03 A60 防通胀：落盘点数 != 三窗口都入账反例 PASS=true | disk=400 wrong_parry_double=450
[V120-C] D03 removals 为空（A59 绝不写 removals） PASS=true
[V120-C] L04 新进程内存读回逐项 == 磁盘（重启读回一致） PASS=true
[V120-C] F02 生产 slot_01 md5 前后一致 PASS=true | md5=219cbf043d3ae14a97f66c44f0e9591e
[V120-C] SUMMARY mode=all pass=70 fail=0 total=70 | OVERALL=PASS | RESULT=ALL_MATCH
```

`verify_spent_points_production_v120.gd`（`[V120-SP]`，39 条逐条 PASS，**关键行全量**见 §5）：
```
[V120-SP] SUMMARY pid=26860 slot=user://saves/verify_r35_spent_26860 pass=39 fail=0 total=39
[V120-SP] OVERALL=PASS
[V120-SP] RESULT=ALL_MATCH
```

### GATE-3 `--headless --quit`（主场景生产实证）
```
G3_EXIT=0
[SaveSystem] 自动读回完成 | dungeon.wave_trial.best_wave=3 | grace.trial.points=450 | dungeon.wave_trial.completed=true
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
[R35][WaveTrial] 精准弹反生产订阅者已装配：ParryService 唯一实例 + 4 信号 connect（A48①/A54）
[R34C][PCO] 生产订阅者已绑定 HUD | signals=5 slot=user://saves/slot_01（A55 唯一权威通道）
```

### 全工程 G3 统计（17 份 `R35-*.log`）
```
########## FINAL GATE STAT ##########
SCRIPT_ERROR_COUNT=0
PARSE_ERROR_COUNT=0
ERROR_PREFIX_COUNT=0
G1_EXIT=0 / 3×G2a EXIT=0 / 12×G2b EXIT=0 / G3_EXIT=0
```

### WARNING 如实登记（非 `SCRIPT ERROR`、不影响门禁 `EXIT=0`）
```
WARNING: [R35][PCO] A59 重复购买拒绝 | dedup_key=boon:1 choice=boon_frost_edge（设计内拒绝，非错误）
WARNING: [R34C][PCO] 重复领取拒绝 | event_key=parry:parry_0_2 reason=parry ...（同窗口重放幂等拒绝，设计内）
WARNING: [R34B][ENC] 波次开始无 cost_key/effect_key（未抉择或记录缺失）→ 运行时敌人参数回落中性基线（既有降级）
WARNING: [SaveSystem] --script 工具模式（未带 v050_read 标记）：跳过自动读回（既有降级）
WARNING: 2 ObjectDB instances were leaked at exit（既有 --script 降级）
```

### A38 / 既有 `.tres` / 生产存档零改动
```
node_count=41  uv_2x=1  uv_1x=2                        （G3 CACHE_MODE_IGNORE 真跑回读 + 两份验证脚本静态断言）
生产 slot_01 md5 before==after=219cbf043d3ae14a97f66c44f0e9591e
G3 [SaveSystem] 自动读回 grace.trial.points=450 / best_wave=3 / completed=true（基线未变）
```
> 本轮未新增 / 未修改任何 `.tres`；只改 3 个 `godot/scripts/rpg/` 文本文件，既有 `.tres` 数值逐字未动（未逐份重算 md5，因本轮对这些文件零写入、且 Rank-2 R35 已实证 8 份既有表零改动）。

### 资产实测字节数（`os.path.getsize`，非编造）
```
godot/scripts/rpg/points_commit_orchestrator.gd            29,507 B（修改）
godot/scripts/rpg/verify_v120_save_commit.gd               39,853 B（新增）
godot/scripts/rpg/verify_spent_points_production_v120.gd   26,371 B（新增）
teamwork/迭代-v0.12.0-精准弹反与消费闭合.md                34,837 B（新增）
teamwork/00-协作契约.md（§3.3 追加 R35 段）                84,307 B（只追加）
teamwork/Rank-3/R35-*.log（17 份）                         157,498 B
```

---

## 5. ★ 两次不同 parry 窗口各自入账的实证（Rank-1 交办缺口闭合）

### 5.1 生产链路实证（`verify_spent_points_production_v120.gd`，真实磁盘读回）
```
[V120-SP] P04 生产编排层 bind_hud 成功（5 信号订阅，含 parry_performed） PASS=true | bound=true
[V120-SP] P05 ★ A48① 生产订阅者存在性（运行时）：5 信号 connection_list 均含编排层回调 PASS=true | subs={ "points_awarded": true, "execution_performed": true, "boon_draft_applied": true, "production_wave_modifier": true, "parry_performed": true }
[V120-SP] R02 前置点数已由生产编排层落盘（A55 唯一权威通道） PASS=true | points=600
[V120-SP] R03 真实 K 输入已注入（Input.parse_input_event + process_key_event） PASS=true | key=K(75)
[R35][HUD] 可弹反窗口开启 | wid=parry_0_1 sec=0.35（生产链路，非验证脚本模拟）
[R35][ENC] parry_performed 生产订阅生效 | wid=parry_0_1 bonus=50 poise_bonus=25.0 boss_poise=95.0 applied=1
[V120-SP] R13 ★ parry 窗口 1 真实入账（parry:<window_id> 配对键） PASS=true | points 600 → 650
[R35][ENC] parry_performed 生产订阅生效 | wid=parry_0_2 bonus=50 poise_bonus=25.0 boss_poise=70.0 applied=2
[V120-SP] R14 ★★ 两个不同 parry 窗口各自入账（第二次不再被 auto 指纹去重误拒） PASS=true | points 650 → 700（两次各 +50）
[V120-SP] R15 ★ A60 弹反奖励不通胀：两次增量恰好 = 2×bonus PASS=true | delta=100 expected=100
[V120-SP] R16 ★ A58 编排层 claimed 含两个不同 parry 去重键（不同窗口不合并） PASS=true | k1=parry:parry_0_1 k2=parry:parry_0_2 claimed=["auto:wave_cleared:100:wave_trial_director.wave_cleared", "auto:wave_cleared:500:wave_trial_director.wave_cleared_front", "boon:1", "parry:parry_0_1", "parry:parry_0_2"]
[V120-SP] R17 A58/A60 弹反三段式 flag 与 points 同一次 commit 原子写 PASS=true | success_count=2 window_id=parry_0_2
[V120-SP] R18 同一 parry 窗口重放幂等拒绝（不二次入账） PASS=true | points=700（未变）
[V120-SP] R19 生产编排层真实 commit 次数 > 0（非验证脚本自模拟） PASS=true | commit_count=5
[V120-SP] B02 ★ 重启读回一致：新 WorldState 逐项 get_flag == 磁盘 PASS=true | flags=7 项逐项比对
[V120-SP] B05 生产 slot_01 md5 前后一致（全程不写 slot_01） PASS=true | md5=219cbf043d3ae14a97f66c44f0e9591e
```

**链条读数**：`points` 基线 `600`（真实清波 `+100` 生产链路 + 前置补足 `+500`）→ 窗口 1 `parry:parry_0_1` 入账 `600→650` → 窗口 2 `parry:parry_0_2` 入账 `650→700`（**不再被 `auto:parry:50:parry_service.try_parry` 指纹误拒**）→ 同窗口重放被拒 `700` 不变。`claimed` 同时含 `parry:parry_0_1` 与 `parry:parry_0_2` **两个不同键**（A58「不同窗口不合并」），`success_count=2` / `window_id=parry_0_2` 与各自 points 同一次 commit 原子写，重启读回逐项一致。

### 5.2 跨 Rank 独立佐证（Rank-1 只读复跑，未改其文件）
```
[V120P] C2 ★ A48③ 真实输入 → points_awarded → PointsCommitOrchestrator（生产 autoload）→ 磁盘 PASS=true | disk=100 runtime=100 commit_count=2
[V120P] C5b A58 ★ Rank-3 编排层 exe: 去重键不再合并不同窗口 PASS=true | k1=exe:exe_0_1 k2=exe:exe_0_2 claimed=["parry:parry_0_1", "parry:parry_0_2", "exe:exe_0_1", "exe:exe_0_2"]
[V120P] SUMMARY pass=27 fail=0 total=27 ok=true parry_source=rank2_production_unique_instance | RESULT=ALL_MATCH
```
> Rank-1 `DONE-R35.md` §4 记录修复前 C2 = `disk=50 commit_count=1`（第二次弹反被自动指纹去重误拒）；本轮 A58 修复后同一只读脚本复跑变为 `disk=100 commit_count=2`，**两次弹反各自真实入账**，且 C5b 的 `claimed` 现在同时列出两 parry 键 + 两 exe 键。脚本 `27 PASS / 0 FAIL`（断言未写死旧值、按「磁盘 == 运行时 + 去重键不合并」判定），无回归破坏。
> 注：Rank-1 `verify_parry_runtime_v120.gd` 文件内有一行「[如实登记] Rank-3 编排层本轮尚未订阅 parry_performed …」的**打印文本**随修复过时；该行是 print（非断言），Rank-1 文件只读，是否同步由总指挥裁决（§9 第 8 条）。

### 5.3 三态夹具佐证（`verify_v120_save_commit.gd`）
```
[V120-C] W13 A58 两个不同 parry 键各自入账、不合并 PASS=true | k1=parry:parry_0_1 k2=parry:parry_0_2
[V120-C] H01 A58 两个不同 parry 窗口各自入账（claimed 含两个不同 parry 键） PASS=true
[V120-C] H03 A60 防通胀：落盘点数 != 三窗口都入账反例 PASS=true | disk=400 wrong_parry_double=450
[V120-C] H05 A60 parry 成功计数 == 2 PASS=true
```

---

## 6. A48 四项 · 逐条自查结论（硬要求，前三轮三次重演）

| # | 硬要求 | 自查结论 | 证据 |
|---|---|---|---|
| **①** | 任何新信号必须有**生产运行时订阅者**，不能只出现在验证脚本里 | **通过**。本轮编排层新增订阅 `parry_performed`（Rank-1 本轮新信号）作为 A58 弹反去重键 / 两个弹反 flag 的**生产运行时订阅者 = `PointsCommitOrchestrator` autoload**（常驻 `project.godot` 注册的生产脚本），不是验证脚本探针。Rank-1 侧 `EncounterDirector` 亦为生产订阅者（真实削韧）。 | `verify_spent_points_production_v120.gd` S04（源码含 `_on_parry_performed` + `"parry_performed"`）/ P04/P05（5 信号 connection_list 均含编排层回调）；**GATE-3 主场景日志** `[R34C][PCO] 生产订阅者已绑定 HUD | signals=5`；`[R35][ENC] parry_performed 生产订阅生效` 3 次（真实削韧） |
| **②** | 任何新服务遵守 A54 唯一实例（从既有导演层 `get_*_service()` 复用，不自建第二个） | **通过**。编排层本轮**未新建任何服务**（无 `new()` / 第二实例）；`ParryService` 由 Rank-2 `wave_trial_director.get_parry_service()` 唯一装配、Rank-1 HUD 鸭子类型复用，编排层只消费信号。 | G3 `[R35][WaveTrial] 精准弹反生产订阅者已装配：ParryService 唯一实例 + 4 信号 connect（A48①/A54）`；`[R35][ENC] 生产装配 | parry_unique_instance=true`；`verify_parry_runtime_v120.gd` C5b / Rank-2 DONE §9 |
| **③** | 必须有一条**不加载 `presentation.gd`、不在验证脚本内模拟编排**的真实可达回归，断言「真实输入 → 生产链路 → 磁盘 / 画面」确实发生 | **通过**。`verify_spent_points_production_v120.gd` 自行 instantiate 主场景、**不加载 `presentation.gd`**；编排（累加 / 去重 / 原子写）**全由生产 `PointsCommitOrchestrator` autoload 执行**（本脚本一行未写编排逻辑，只读磁盘断言）；通过生产 HUD 节点发射其真实运行时信号 + 注入真实 K 输入（`Input.parse_input_event`）；独立 PID 临时槽与生产 `slot_01` 物理隔离。 | 39 PASS / `RESULT=ALL_MATCH`；R05~R08（抉择扣费 → 磁盘 spent 0→15）、R13~R18（两次 parry 600→650→700）、B01~B05（重启读回一致 / 生产 md5 前后一致）；G3 生产主场景实证装配 |
| **④** | 纯逻辑 + 单元断言不算可玩交付，演示驱动不算真实可达 | **通过**。可达性由 §③ 的真实主场景 / 生产信号 / 生产订阅者 / 真实磁盘 / 重启读回承担；`verify_v120_save_commit.gd` 在头部与 `_initialize()` 明确登记为「只验证口径 + 磁盘一致性」的确定性三态夹具、**不冒充真实可达**；`presentation.gd` 演示驱动全程未加载、不计入可玩交付。 | 两份脚本头部口径声明；§4 / §5 输出；§7 验收三态如实登记 |

---

## 7. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 任务① A59：`spent_points` 唯一出口接生产编排层 autoload；cost→points `[PLACEHOLDER]` 映射 + rationale + 调参唯一入口；与 unlocked flag 同一次 commit 原子写；余额前置门控 / 重复购买拒绝 / 缺失非法拒绝告警 / 绝不写 removals / 绝不回退 points（R05~R12 + G 组实证）。② 任务② A58：订阅 `parry_performed`（A48① 生产订阅者，5 信号实证）、`exe:<window_id>` / `parry:<window_id>` 去重键、不同窗口不合并（两个不同 parry 键各自入账、Rank-1 C2 复跑佐证）；A55/A57 口径原样保留。③ 任务③：两份新验证脚本（后者不加载 `presentation.gd`、不在验证脚本内模拟编排、真实链路读磁盘六项断言链）、`PASS/FAIL + RESULT=ALL_MATCH`。④ 任务④：契约 §3.3 只追加 R35 段（3 新三段式 flag + A58/A59/A60/A61），历史条款 / I-1~I-6 / §3.1 §3.2 缺号未动。⑤ 任务⑤：迭代文档 + README §六 状态段（追加、不删历史行）。⑥ 任务⑥：三段门禁全 `EXIT=0`、全工程 `SCRIPT ERROR=0 / Parse Error=0 / ERROR 前缀=0`；A38 节点 41 / uv `2/1/1`；生产 `slot_01` 零改动。⑦ **A48 四项逐条通过**（§6）。⑧ 既有 7 份回归 350 PASS 全绿、三进程三态 pid 互不相同。⑨ 目录所有权：只写任务单授权文件，其余一律只读。 |
| **失败** | 无最终失败。如实登记过程，不冒充一次通过：① `verify_v120_save_commit.gd` 首版 W16 去重键计数写 6（实际 7：`wave:1` + 2 parry + 2 exe + 2 boon），`--check-only` 语法通过后、首跑 `all` 前修正为 7；② 两份脚本的「重复购买拒绝 / 同窗口重放 / 波次无抉择降级」按设计产出 `WARNING`（非 `SCRIPT ERROR`、不计 FAIL）；③ 最终两脚本与全部回归一次全绿。 |
| **需用户确认** | ① 15~20 秒实机录屏目视由总指挥本轮亲自重跑（headless 无像素级目视、Rank-3 不重复录屏、不冒充目视通过）；② 全部 `[PLACEHOLDER]` 数值待人工试玩校准（只改常量段 / 表）；③ 演示 D→A 递进 / S 级爆发目视；④ HD-2D 全绿（A41/A52）未达、`128bit` 歧义（A53）继续保留；⑤ `boon:<index>` 跨波次去重口径、弹反免伤语义、`combo_keep` / `fail_penalty` 生效等跨 Rank 裁决项（§9）；⑥ 既有 WARNING 清理；⑦ Rank-1 验证脚本内过时「如实登记」打印文本同步。 |

---

## 8. 未完成项（如实登记，交总指挥排期）

1. **实机录屏目视（A42）**：headless 无帧缓冲，15~20 秒录屏 + 首 / 中 / 尾三帧回看由总指挥本轮亲自重跑；Rank-3 不代做手感 / 审美判断、不冒充目视通过。
2. **`[PLACEHOLDER]` 数值校准**：`COST_TO_POINTS_FACTOR=10.0` / `MIN=1`（编排层常量段）、`parry_rules.tres`（Rank-2 所有）、抉择 / 连击 / 处决各版数值待人工试玩；调参只改常量段 / 表不改代码。
3. **HD-2D 全绿未达（A41/A52/A61）**、`128bit` 歧义（A53 保留）、地面裂缝观感、真机 exe / apk 手感：沿用既有登记。
4. **`teamwork/Rank-3/存档与flag规范.md` §3.3 全局登记表未同步 3 个新 flag**：不在本轮任务单授权文件清单内，Rank-3 未越界写；契约 §3.3 R35 段已登记，待下一版授权后补全局登记表。
5. **Rank-1 `verify_parry_runtime_v120.gd` 内过时「如实登记」打印文本**：该行是 print（非断言），Rank-1 文件只读，是否同步由总指挥裁决；复跑已 `27 PASS`。
6. **既有 WARNING / 降级日志**（SaveSystem 工具模式 / ChunkManager / ObjectDB 泄漏 / PCO 重复拒绝 / 波次无抉择降级）：非本轮引入（后两条为 A59/A58 设计内拒绝），是否纳入后续清理由总指挥裁决。
7. **演示 D→A 递进 / S 级收束爆发目视**：沿用 Rank-1 DONE-R35 §7 第 1 条，headless 日志无法实证 A/S 级，Rank-3 不冒充。
8. **无阻塞**；所有硬约束内工作已完成。

---

## 9. 待总指挥裁决项（只登记、不擅改）

1. **`cost→points` `[PLACEHOLDER]` 系数校准**：`FACTOR=10.0` / `MIN=1` 待人工试玩；调参唯一入口 = 编排层常量段（只改常量不改逻辑）。
2. **`boon:<index>` 去重键跨波次口径**：当前沿用契约 R34 第 162 行 `boon:<index>`，跨波次同 index 抉择会被误拒；是否改为 `boon:<index>:<choice_id>` 请裁决。
3. **`production_wave_modifier` 是否独立承担一次扣费**：本轮按「与 `boon_draft_applied` 是同一抉择的两个阶段、扣费恰好一次」实现（前者只做配对键 + cost 对账、绝不二次扣费）；若玩法要求两阶段各自扣费请裁决。
4. **`grace.boon_draft.unlocked` 与既有 `grace.upgrade_<id>.unlocked` 命名空间是否统一**：本轮新登记在 `grace.boon_draft.*`（与 `selected` / `cost_applied` 同对象段）。
5. **弹反成功是否免伤 / `combo_keep` / `fail_penalty` 是否真正生效**：沿用 Rank-1 / Rank-2 DONE-R35 待裁决项，Rank-3 不代改战斗判定。
6. **`128bit` 歧义（A53）继续保留**、**HD-2D 全绿按 A41/A52 三判据（A61）**：沿用既有裁决、不消歧、不据单路自评宣称全绿。
7. **既有 WARNING 清理 / 实录屏回看 / 存档与flag规范 §3.3 全局登记表同步**：沿用既有裁决 / 排期。
8. **Rank-1 验证脚本内过时「如实登记」打印文本同步**（§5.2 注）：由归属 Rank 自行更新，Rank-3 只读。

---

## 10. 硬约束 / 纪律遵守声明

- **唯一写入方 = Rank-3**：仅 `points_commit_orchestrator.gd` / `verify_v120_save_commit.gd` / `verify_spent_points_production_v120.gd` / `00-协作契约.md` §3.3 追加段 / `迭代-v0.12.0-精准弹反与消费闭合.md` / `README.md` 状态段 / `teamwork/Rank-3/`（DONE + 日志）/ 回执；其余一律只读。`courtyard.tscn` 节点 41 / uv `2/1/1` 与 `presentation.gd` 只读；`project.godot` 本轮只读（既有 autoload 不动）；既有 `.tres` 数值零改动；未改契约其它历史条款 / I-1~I-6 / §3.1 §3.2 缺号 / 其它 Rank 产出。未删除 `.workbuddy`。
- **A50 / A55 边界**：点数落盘唯一写入方仍为 Rank-3 编排层；Rank-1 只发信号、Rank-2 只发信号 + 纯逻辑判定、Rank-4 只读；两份验证脚本只读磁盘断言、不写编排逻辑。
- **Godot 4 `--script` 纪律**：`extends SceneTree` 用 `Engine.get_main_loop() as SceneTree` 取 root、不用 `get_tree()` / 不用 `/root/...` 绝对路径；`add_child` 后显式 `call("_ready")` / `_r34_bootstrap()`；对已装配 `PointsCommitOrchestrator` autoload 不重复挂载（未装配时按 `project.godot` 注册项挂同一生产脚本，如实登记不算自模拟）；资源 `CACHE_MODE_IGNORE` 回读；connect 前 `get_signal_connection_list()` 去重、`_release()` / `_finish()` 有释放路径；独立 PID 临时槽（`verify_v120_<pid>` / `verify_r35_spent_<pid>`）与生产 `slot_01` 物理隔离。
- **编排层 autoload 安全降级**：`_ready()` `call_deferred` 延迟绑定 + 最多 6 次重试 + 耗尽 `push_warning`（不订阅 / 不写盘 / 不报错）；`_commit` 惰性初始化正则 / 运行时镜像；`_exit_tree` / `NOTIFICATION_WM_CLOSE_REQUEST` 兜底释放；无 HUD 的纯 `--headless --import` / `--check-only --script` / 无输入 GATE-3 均不报错不写盘（G3 实证 `signals=5` 绑定但无 commit、生产基线 `points=450` 未变）。
- **生产存档保护（如实登记）**：所有验证脚本使用独立 PID 临时槽、全程不 `open WRITE` 生产 `slot_01`；生产 `slot_01` md5 `219cbf043d3ae14a97f66c44f0e9591e` 前后一致（B05 / F02）。
- **零付费、零外部依赖、不启 GPU job**；**不伪造产物、不谎报成功、不自行 git**（总指挥收尾）；**默认不刺探**：未扫目录做进度巡检、未写只读探针 / 巡检脚本、未反复核对文件状态（仅按任务单读取必做文件 + 必要的只读接口源码，真跑日志落 `teamwork/Rank-3/R35-*.log`）。

---

## 11. 回执与中枢归档

- 回执路径（**`teamwork/command_center/`，非工程根**）：
  `teamwork/command_center/ai/3/outbox/cmd-20261112-125821-143-A3.json`
- 四字段：`{"task_id":"cmd-20261112-125821-143-A3","ai":3,"status":"done","result":"引用 DONE-R35.md 实际结论：…"}`。
### 回执写后确认（中枢归档 · 实测，非推断 / 不伪造 / 不重放）

写回执到 `ai/3/outbox/` 后**即时回读确认**（由中枢流程自动处理，Rank-3 只写 outbox、未自建 / 未伪造归档、未重放）：

```
· 写前状态（基线）：outbox 为空；dispatcher/ledger.jsonl 本任务登记 status=dispatched / finished_at=""
  ；ai/3/status.json：state=working / current_task=cmd-20261112-125821-143-A3 / completed=39
· 回执写入 ai/3/outbox/cmd-20261112-125821-143-A3.json 后由中枢自动回收：
  写后 outbox 已清空（中枢正常处理，与 DONE-R34C / Rank-1 / Rank-2 §10 口径一致）
· dispatcher/receipts/cmd-20261112-125821-143-A3.json  存在（归档副本）
· dispatcher/ledger.jsonl 本任务记录更新为：
  id=cmd-20261112-125821-143-A3  ai=3  status=done  finished_at=2026-11-12 14:08:42
  result 与回执逐字一致（引用 DONE-R35.md 实际结论）
· ai/3/status.json：state=idle / current_task="" / completed=40（39→40）
  / last_seen=2026-11-12 14:08:42
· 回执四字段合法性（由中枢成功解析并归档间接实证）：task_id / ai=3 / status=done
  / result 齐全；中枢已成功读取该 JSON 并把 result 写入 ledger（与回执逐字一致）
```

> 归档到 `teamwork/command_center/dispatcher/receipts/`（**是 teamwork/command_center/，不是工程根 command_center/**）；归档 / 台账 / 状态更新由中枢流程完成。注：本轮中枢归档日志载体为 `dispatcher/ledger.jsonl`（与 Rank-2 DONE-R35 §11 口径一致），如实登记、不臆造 `dispatcher.log` 文件名。
