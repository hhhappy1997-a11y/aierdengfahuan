# DONE-R36.md · R36 / v0.13.0「专注值与战技 · 画面补齐」交付报告（Rank-1 引擎架构与渲染）

> 轮次：`R36` ｜ 任务单 id：`cmd-20261112-154132-903-A1` ｜ 执行 AI：`1（Rank-1 引擎架构与渲染执行 AI）`
> 真源：`teamwork/Rank-1/调度任务单-latest.json`（`task` 全文 + 公共契约含 A48 + 目录所有权），以任务单为准。
> 前序：`teamwork/Rank-1/DONE-R35C.md`、`teamwork/00-群聊总线.md` MSG-20261112-1535-HOST（A39~A64 裁决）。
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）

> **一句话结论**：R36 四块任务全部真跑完成 —— ① HUD 加「专注值 FP」条（独立分区锚点，四档降级与 13 块文字包围盒交集恒 0），Q 键接真实 `_unhandled_input`，复用 A54 唯一 `wave.get_focus_service()` **真实 Rank-2 FocusService**（并行派单期间落盘），判定 FP / 冷却，成功扣 FP + `focus_skill_performed`（A57 倍率后值）驱动 ENC 真实削韧 / 伤害，失败「专注不足 / 冷却中」不扣 FP；② A65 弹反成功免伤落地并真跑实证（窗口内成功 HP 88→88 不变、窗口外 / 超时 100→88 正常扣血、guard 一次性消费），HUD「弹反·免伤」反馈；③ `presentation.gd` 只追加 Q / J / K 真实按键注入节奏（既有 `[PLACEHOLDER]` 常量数值逐字不动、不回退演示驱动），450 帧逻辑真跑中战技释放 / 弹反免伤 / 连击倍率结算真实出现；④ 新写 `verify_focus_runtime_v130.gd`（不加载 presentation.gd）28/28 PASS，扩展 V110 66/66、V120P 31/31、V100HUD 40/40 全 `RESULT=ALL_MATCH`。三段门禁 G1/G2/G3 全 `EXIT=0`、全工程 `SCRIPT ERROR=0 / PARSE_ERROR=0`、A38 节点 **41** / uv **2/1/1** 不变。回执写入并确认中枢归档（§9）。**未完成 / 待裁决**：定稿录屏 / 目视帧由总指挥本轮亲自重跑（本轮不含新录屏 / 目视帧）；连击 D→A→S 完整评级序列与 S 级收束爆发、战技 / 免伤的实机画面观感待目视；`[PLACEHOLDER]` 试玩校准；HD-2D 全绿沿用未达。

---

## 1. 交付清单（实际落地文件）

| # | 文件 | 类型 | 本轮改动 |
|---|---|---|---|
| ① | `godot/scripts/combat/encounter_director.gd` | 修改（Rank-1 唯一写入） | 新增 `parry_damage_negated(window_id)` 信号（A65）；`_on_boss_move_landed` 扣血前一次性消费 `_r35_parry_guard` 命中即免伤 return（不改翻滚无敌 / 正常受击路径 / 帧数据 / 输出格式）；`_unhandled_input` 追加 Q 分支转发 HUD 权威入口（event 实例幂等）；R36 段：`_r36_bootstrap` 复用 A54 唯一 focus_service + `focus_skill_performed/rejected` **生产运行时订阅者**（真实削韧 `apply_damage` + `_resolve_poise`）、`bind_focus_service` / `get_focus_service` / `get_focus_production_snapshot` / `_r36_release` 释放路径。既有 roll/light/heavy/interact 判定逐字不动。 |
| ② | `godot/scripts/hud.gd` | 修改（Rank-1 唯一写入） | 新增 `focus_skill_performed` / `focus_skill_rejected` 信号；「专注值 FP」条真实节点 `ProdFocusLabel` + 独立归一化锚点 `ANCHOR_FOCUS` + `get_focus_rect()`（不并入 6 分区）；`_process_r32_keys` 加 Q（A46 单一仲裁者）；R36 段：`request_focus_skill()` 权威判定（对齐真实 `spend_fp(art_id)` / `get_snapshot` / `on_grace_rest`）、A57 倍率后值、A65「弹反·免伤」生产订阅回调、赐福休息回满、FP 条常驻刷新、`_r36_bootstrap` / `_r36_release`。既有文本 / 四套 HUD / 6 分区布局逐字不动。 |
| ③ | `godot/test/presentation.gd` | 修改（Rank-1 唯一写入） | 头部加 R36 说明（rationale + 调参唯一入口）；新增 `KEY_Q_CODE` 与 `R36_*` 演示节奏常量；`_drive_real_input` 末尾**只追加**⑪ Q 战技 / ⑫ J 收束爆发 / ⑬ K 收束爆发 三段 `Input.parse_input_event` 注入。既有 R28/R34/R35 常量数值逐字不动、不改 `[PLACEHOLDER]` 数值、不回退演示驱动。 |
| ④ | `godot/scripts/render/verify_focus_runtime_v130.gd` | 新增 | **真实可达回归**（不加载 presentation.gd、不模拟编排）：复用 A54 唯一真实 FocusService，`F/Q/R/A65` 组共 **28 条**，断言真实 Q → FP 扣减 / 不足拒绝 / 冷却拒绝 / 赐福休息回满 / 重复按键幂等 / A57 倍率后值 / 生产链（Rank-1 ENC + Rank-2 wave 双方订阅者）/ 画面节点变化 / A48①。契约替身 `FakeFocus` 仅作「Rank-2 未落盘」降级兜底（本轮未触发）。 |
| ⑤ | `godot/scripts/render/verify_production_chains_v110.gd` | 修改（扩展，既有断言不删不放宽） | 追加 `_t_r36_focus_chain()`（`R36-1~5` 共 9 条）：新信号 / FP 条真实节点 / A54 三方同一实例 / A48① 生产订阅者 / 真实 Q → 生产链 / A38。既有 57 条逐字不动。 |
| ⑥ | `godot/scripts/render/verify_parry_runtime_v120.gd` | 修改（扩展，既有断言不删不放宽） | 追加 `_t_a65_parry_negate()`（`A65-0~3` 共 4 条）：**窗口内成功 → 玩家 HP 不变**、**窗口外 / 超时 → 正常扣血**、HUD「弹反·免伤」、免伤只作用本次窗口。既有 27 条逐字不动。 |
| ⑦ | `godot/scripts/render/verify_hud_layout_v100.gd` | 修改（扩展，既有断言不删不放宽） | 追加 K 组（`K1~4` 共 4 条）：FP 条真实节点 rect 与 13 块文字包围盒 `worst_overlap==0`、四档降级不出界 / 不遮角色 / 不相交、与 `get_focus_rect()` 一致。既有 36 条逐字不动。 |
| ⑧ | `teamwork/Rank-1/DONE-R36.md` | 新增 | 本交付报告。 |
| ⑨ | `teamwork/Rank-1/r36_g1_import.log` / `r36_g2_check_*.log` / `r36_verify_*.log` / `r36_g3_quit.log` / `r36_presentation_logic.log` | 新增 | 三段门禁 + 4 回归 + 演示逻辑帧真跑日志原文留档（授权目录内）。 |
| ⑩ | `teamwork/command_center/ai/1/outbox/cmd-20261112-154132-903-A1.json` | 新增 | 本轮回执（**teamwork/command_center/**，非工程根），写后经中枢归档（§9）。 |

---

## 2. 四块任务实现说明

### 2.1 任务① 专注值 FP 与战技 Q（运行时侧）

**A54 唯一实例**：Rank-2 本轮并行产出 `focus_service.gd` / `focus_config.gd` / `focus_rules.tres` 及 `wave_trial_director.get_focus_service()` 在本 AI 工作期间落盘。生产侧 `hud.gd._r36_bootstrap()` / `encounter_director.gd._r36_bootstrap()` 均从 `wave.get_focus_service()` 复用**同一真实 Object**，绝不 `new` 第二实例（V130 `F3`/`F3b`、V110 `R36-2` 三方同一实证）。Rank-1 一侧同时保留鸭子类型多候选方法名 / 键名 + 判空降级，Rank-2 接口命名差异不产生 SCRIPT ERROR。

**真实输入链**：`Q`（物理键码 81）→ 两文件各自 `_unhandled_input` 接 Q（HUD 走 `_process_r32_keys` 单一仲裁者 A46；ENC 加 Q 分支转发 HUD 权威入口，靠 `event.get_instance_id()` 幂等去重防双结算）→ `hud.request_focus_skill()` → 真实 `FocusService.spend_fp(art_id)`（默认战技 id 取 `get_art_ids()[0]`，数值全来自 `focus_rules.tres`，本层不硬编码）→ 成功扣 FP + emit `focus_skill_performed(skill_id, fp_before, fp_after, fp_cost, damage, poise, multiplier)`、失败 emit `focus_skill_rejected(reason)`（不扣 FP）。

**A57 倍率后值**：战技伤害 = `base_damage × 唯一 ComboService 有效倍率`（`_r36_effective_multiplier()`，无有效倍率回落 1.0），随信号带出，ENC 生产订阅者原样采信、不二次结算。Q5 真跑 `base=18.0 mult=1.00 expect=18 signal_damage=18`。

**A48① 生产运行时订阅者**（全部为生产节点，非验证脚本）：
- HUD `focus_skill_performed` / `focus_skill_rejected` → **EncounterDirector**（真实施加 `Boss.apply_damage` + `_resolve_poise` 削韧）；
- ENC `parry_damage_negated` → **HUD**（A65「弹反·免伤」反馈）；
- ENC `grace_rested` → **HUD**（赐福休息回满 FP）；
- Rank-2 真实 `FocusService.focus_spent` → **wave_trial_director**（Rank-2 真实累计清波基数 / 削韧，实测 `wave_subscribed=true`）。
所有 connect 均 `get_signal_connection_list` 去重、`_r36_release()` 有 disconnect 释放路径。

**FP 条**：生产常驻可见层 `ProductionMechanismsLayer` 自建真实 `Label` 节点 `ProdFocusLabel`（文本「专注值 FP 当前/上限 ｜ Q 战技」+ 提示 / A65 反馈），按独立归一化锚点 `ANCHOR_FOCUS = Rect2(0.01875, 0.51389, 0.27813, 0.04167)` 定位，`set_layout_viewport` 联动 `_r36_apply_focus_rect()`；不并入 `get_layout_rects()` 的 6 分区数组（保护 A1「size()==6」断言）。V100HUD K 组实测 1280x720 + 三档降级 `worst_overlap=0.0000 px²`、不出界 / 不遮中央角色。

### 2.2 任务② A65 弹反成功免伤（HOST 裁决）

`encounter_director.gd._on_boss_move_landed()`：把 `_r35_consume_parry_guard()` 一次性消费**提前到扣血之前**。`guard=true`（本次窗口内真实 K 成功弹反，`parry_performed` 生产订阅者置位）→ 免除**该次** Boss 招式伤害（玩家 HP 不变、不计 hits_taken、连击不断）+ emit `parry_damage_negated` → HUD 显示「弹反·免伤」；`guard=false`（窗口外 / 超时 / 未弹反）→ **逐字走既有**扣血 + `_r34b_combo_on_hit_taken()` 连击中断结算。翻滚无敌 `is_invulnerable()` 等其它伤害路径逐字不动；guard 一次性消费实现「只作用于本次窗口」。实证见 §5。

### 2.3 任务③ 演示覆盖（presentation.gd）

只追加三段真实 `Input.parse_input_event` 注入节奏（既有 R28/R34/R35 常量数值逐字不动、`[PLACEHOLDER]` 战斗数值一律不动、不回退 R34 已移除的演示驱动）：⑪ Q 战技 30 帧周期、⑫ 尾段 330~445 J 每 2 帧收束爆发、⑬ 尾段 320~445 K 每 3 帧收束爆发。450 帧 `--headless` 逻辑帧真跑（不带 `--write-movie`，不算录屏 / 不启 GPU job）结果见 §6：**Q 注入 14 次 → 战技真实释放 13 次**（FP 100→88→76→64→52…）、**战技拒绝 15 次**（13 cooldown + 2 insufficient_fp）、**A65 免伤反馈 1 次**、弹反成功 `parry_performed` 生产消费、A57 清波结算 `base=100 → final=198`（倍率 1.98，连击评级实际推进）、J 收束 58 / K 收束 42 次，`SCRIPT ERROR=0`。如实登记：D→A→S 完整评级序列 / S 级收束爆发 / 实机画面观感仍待总指挥定稿录屏目视，本轮不含新录屏 / 目视帧，不冒充（§6 / §7）。

### 2.4 任务④ 真实可达回归

- **A48③ 主回归** `verify_focus_runtime_v130.gd`：`extends SceneTree`，`Engine.get_main_loop() as SceneTree` 取 root、显式 `call("_ready")` / `_r34_bootstrap()`、`CACHE_MODE_IGNORE`、connect 去重 / disconnect 释放；**不加载 presentation.gd**（F8 运行时树检查零 presentation 脚本节点）、**不在验证脚本内模拟编排**（只注入真实 Q + 复用生产唯一实例 / 生产节点公开方法），断言「真实输入 → 生产链路 → 磁盘 / 画面」：真实 Q → 真实 FocusService 扣 FP → `focus_skill_performed` → ENC 真实削韧 / 伤害 + `focus_spent` → wave 真实累计 → ProdFocusLabel 真实可见节点文本变化（Q3 `100/100 → 88/100`）。
- 三个既有脚本仅**追加**组、既有断言逐字不删不放宽（§1）。

---

## 3. 真跑输出原文

命令前缀统一 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；日志留档 `teamwork/Rank-1/r36_*.log`。

### 3.1 三段门禁 EXIT + 全工程 SCRIPT ERROR / PARSE ERROR grep

```
===== G1 --headless --import =====                     G1_IMPORT_EXIT=0
===== G2a --check-only --script（7 个改动脚本）=====
  CHECK res://scripts/combat/encounter_director.gd                EXIT=0
  CHECK res://scripts/hud.gd                                        EXIT=0
  CHECK res://test/presentation.gd                                 EXIT=0
  CHECK res://scripts/render/verify_focus_runtime_v130.gd           EXIT=0
  CHECK res://scripts/render/verify_production_chains_v110.gd       EXIT=0
  CHECK res://scripts/render/verify_parry_runtime_v120.gd           EXIT=0
  CHECK res://scripts/render/verify_hud_layout_v100.gd              EXIT=0
===== G2b --headless --script（4 个回归）=====
  VERIFY verify_focus_runtime_v130          EXIT=0
  VERIFY verify_production_chains_v110     EXIT=0
  VERIFY verify_parry_runtime_v120         EXIT=0
  VERIFY verify_hud_layout_v100            EXIT=0
===== G3 --headless --quit（全工程加载）=====          G3_QUIT_EXIT=0
===== SCRIPT ERROR / PARSE ERROR grep（14 段日志）=====
  r36_g1_import.log                          : SCRIPT_ERROR=0 PARSE_ERROR=0
  r36_g2_check_encounter_director.log        : SCRIPT_ERROR=0 PARSE_ERROR=0
  r36_g2_check_hud.log                       : SCRIPT_ERROR=0 PARSE_ERROR=0
  r36_g2_check_presentation.log              : SCRIPT_ERROR=0 PARSE_ERROR=0
  r36_g2_check_verify_focus_runtime_v130.log : SCRIPT_ERROR=0 PARSE_ERROR=0
  r36_g2_check_verify_production_chains_v110.log : SCRIPT_ERROR=0 PARSE_ERROR=0
  r36_g2_check_verify_parry_runtime_v120.log     : SCRIPT_ERROR=0 PARSE_ERROR=0
  r36_g2_check_verify_hud_layout_v100.log        : SCRIPT_ERROR=0 PARSE_ERROR=0
  r36_verify_verify_focus_runtime_v130.log       : SCRIPT_ERROR=0 PARSE_ERROR=0
  r36_verify_verify_production_chains_v110.log   : SCRIPT_ERROR=0 PARSE_ERROR=0
  r36_verify_verify_parry_runtime_v120.log       : SCRIPT_ERROR=0 PARSE_ERROR=0
  r36_verify_verify_hud_layout_v100.log          : SCRIPT_ERROR=0 PARSE_ERROR=0
  r36_verify_v130.log / r36_verify_v120.log / r36_verify_v110.log / r36_verify_v100hud.log : SCRIPT_ERROR=0
  r36_g3_quit.log                            : SCRIPT_ERROR=0 PARSE_ERROR=0
  合计 SCRIPT_ERROR+PARSE_ERROR = 0
```

### 3.2 四个回归 SUMMARY / RESULT 原文

```
[V130] SUMMARY pass=28 fail=0 total=28 ok=true focus_source=rank2_production_unique_instance
[V130] RESULT=ALL_MATCH
[V110] SUMMARY pass=66 fail=0 total=66 ok=true
[V110] RESULT=ALL_MATCH
[V120P] SUMMARY pass=31 fail=0 total=31 ok=true parry_source=rank2_production_unique_instance
[V120P] RESULT=ALL_MATCH
[V100HUD] SUMMARY pass=40 fail=0 total=40 ok=true
[V100HUD] RESULT=ALL_MATCH
```

### 3.3 V130 关键断言原文（真实输入 → 生产链路 → 画面）

```
[V130] A54 ★ 复用 wave.get_focus_service() 真实唯一实例（Rank-2 FocusService 已落盘）→ 走真实判定，不冒充联调
[V130] F3 A54 ★ HUD / ENC / wave.get_focus_service() 三方同一真实 Object（绝不自建第二实例） PASS=true | source=rank2_production_unique_instance same=true
[V130] F3b ★ A54 走真实 Rank-2 FocusService（spend_fp / get_snapshot / on_grace_rest / 4 信号），非契约替身 PASS=true
[V130] F4 A48① ★ focus_skill_performed 有【生产运行时订阅者 EncounterDirector】 PASS=true | subscribers=2 enc_subscribed=true
[V130] F4c A48① ★ 真实 FocusService.focus_spent 有【生产订阅者 wave_trial_director】 PASS=true | wave_subscribed=true
[V130] F5 A48① ★ parry_damage_negated 有【生产运行时订阅者 HUD】 PASS=true | subscribers=2 hud_subscribed=true
[V130] F6 ★ 专注值 FP 条真实节点 ProdFocusLabel 常驻可见且文本含「专注值 FP 当前/上限」 PASS=true | text=[专注值 FP 100/100  ｜  Q 战技]
[V130] F8 A49 ★ 本验证进程不加载 presentation.gd（场景树零 presentation 脚本节点、主场景自行 instantiate） PASS=true
[V130] Q1 ★ 真实 Q 输入 → 战技成功（权威 spend_fp 判定 ok=true） PASS=true
[V130] Q2 ★ 真实 Q → FP 扣减：服务 fp 100.0 -> 88.0（扣 fp_cost=12.0），spend_count +1，HUD 视图同步 PASS=true
[V130] Q3 ★ A48③ 画面确实发生：ProdFocusLabel 真实可见节点文本随真实 Q 由「100」变为「88」 PASS=true | before=[专注值 FP 100/100  ｜  Q 战技] after=[专注值 FP 88/100  ｜  Q 战技  ｜  战技命中 · -12 FP] visible=true
[V130] Q4 ★ A48③ 生产链路：focus_skill_performed → EncounterDirector 真实削韧 / 伤害 PASS=true | events=1 poise_applied=1 damage_applied=1
[V130] Q4b ★ A48③ Rank-2 生产链：真实 focus_spent 广播被 wave 生产订阅者接收（探针 +1） PASS=true | focus_spent_signals=1 art=glintstone_pebble
[V130] Q5 A57 ★ focus_skill_performed.damage 为倍率后最终值（base×mult），multiplier 随信号带出（≥1.0） PASS=true | base=18.0 mult=1.00 expect=18 signal_damage=18
[V130] R1 ★ 专注不足拒绝：真实 Q → ok=false reason=insufficient_fp，FP 不变（4.0 < cost 12.0）、HUD 提示「专注不足」 PASS=true
[V130] R2 ★ 冷却拒绝：冷却期连续真实 Q → ok=false reason=cooldown，FP 不变（88.0）、HUD 提示「冷却中」 PASS=true
[V130] R3 ★ 重复按键幂等：同一 Q event 连投两次 → 权威 spend 仅 +1、FP 只扣一次、performed 恰 1 次 PASS=true
[V130] R4 ★ 赐福休息回满：真实 debug_grace_rest → grace_rested → HUD 生产订阅者 → FP 回满（88.0 → 100.0/100.0），restore_count +1 PASS=true
[V130] R5 异常 / 边界输入不崩：非 Q 键不误触战技、服务判空降级返回确定 unavailable 且不误扣 FP PASS=true
[V130] A65-H1 ★ parry_damage_negated → HUD 生产订阅者显示「弹反·免伤」反馈 PASS=true
```

### 3.4 A38 courtyard.tscn 只读核对 + G3 非空佐证

```
=== A38 courtyard.tscn 只读核对 ===
节点数(静态 [node 行)              : 41
uv1_scale = Vector3(2, 2, 1) 出现 : 1
uv1_scale = Vector3(1, 1, 1) 出现 : 2
→ 节点 41 / uv 2/1/1 不变，本轮零改动 courtyard.tscn。

=== G3 --headless --quit 日志（57 行，非空）===
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41
[R31][HUD] 运行时挂载 ImpactFeedbackLayer → Courtyard
[R36][WaveTrial] 专注值/战技生产订阅者已装配：FocusService 唯一实例 + 4 信号 connect（A48①/A54）
[R36][HUD] 生产装配 | focus_unique_instance=true A65/回满生产订阅=true（A48①/A54，不自建第二实例）
[R36][ENC] 生产装配 | focus_unique_instance=true focus_skill_subscribed=true（A48① 生产运行时订阅者，A54 不自建第二实例）
```

> 既有 WARNING / ERROR 如实登记（非本轮引入、非 `SCRIPT ERROR`、不影响 `EXIT=0`）：`--script` 工具模式 `SaveSystem` 跳过自动读回、`ChunkManager` 未找到 ChunkRoot、`PointsCommitOrchestrator` autoload 降级、`2 ObjectDB instances were leaked at exit`；V130 / V120P 调用 `debug_grace_rest()` → `_respawn_boss()` → `BossController._ready` 触发 `ERROR: Can't use get_node() with absolute paths from outside the active scene tree`（R24 v0.2.0 既有赐福休息重建 Boss 在 `--script` 工具模式的降级，非 SCRIPT ERROR、A65-2 / R4 断言仍 PASS）。首次 G3 quit 出现 `[R34][ComboFX]` 相关既有 ComboService 4 信号绑定日志；并行时序下曾有一次 `hd2d_fx.gd` 对契约替身 `combo_changed` 信号 connect 的既有降级 ERROR（**V130 已去掉 FakeCombo 注入**，最终门禁日志 `SCRIPT ERROR=0`）。

---

## 4. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 「专注值 FP」条真实节点 + 独立分区锚点，四档降级与 13 块文字包围盒 `worst_overlap=0`；② Q 键两文件接真实 `_unhandled_input`，复用 A54 **唯一真实 Rank-2 FocusService**，成功扣 FP + 战技效果（ENC 真实削韧 / 伤害）、失败「专注不足 / 冷却中」不扣 FP，A57 倍率后值口径，不改既有普通攻击判定 / 帧数据 / 输出格式；③ A65 窗口内成功免伤、窗口外 / 超时正常扣血、HUD「弹反·免伤」，只作用本次窗口；④ 演示只追加注入节奏、既有 `[PLACEHOLDER]` 数值逐字不动、不回退演示驱动，450 帧逻辑真跑生产链真实触发；⑤ 新写 V130（28/28）+ 扩展 V110(66)/V120P(31)/V100HUD(40) 全 `RESULT=ALL_MATCH`、既有断言不删不放宽；⑥ 三段门禁全 `EXIT=0`、全工程 `SCRIPT ERROR=0 / PARSE_ERROR=0`；⑦ A38 节点 41 / uv 2/1/1 不变；⑧ A48 四项逐条达标（§8）；⑨ 只写授权文件、其余只读；⑩ 回执写入并确认中枢归档（§9）。 |
| **失败 / 未达** | ① **本交付不含新录屏 / 目视帧**：公共契约规定「定稿录屏由总指挥本轮亲自重跑并目视，本轮不重复录屏」，故 D→A→S 完整评级序列 / S 级收束爆发、战技 / 弹反免伤实机画面观感待总指挥目视确认，运行时逻辑真跑已证明生产链触发但不冒称目视通过；② **连击 D→A→S / S 级爆发**：逻辑真跑中 A57 清波结算 `base=100 → final=198`（倍率 1.98）证明连击评级确有推进并结算，但「完整 D→A→S 递进 + S 级收束爆发」的逐档序列未在录屏目视确认，如实登记；③ **HD-2D 全绿未达**（沿用 R35B/R35C）：仍是 2D `_draw()` / screen-reading shader 近似、2D tile 地面、billboard 精灵，无真 DoF / 真体积光 / SSR / Forward+，不包装成全绿。 |
| **需用户确认 / 待裁决** | 见 §7。 |

---

## 5. A65 弹反成功免伤实证（真跑原文）

`verify_parry_runtime_v120.gd` A65 组（真实 K 输入 → `process_key_event`，与 `_unhandled_input` 同路径）：

```
[V120P] ==== A65 组：弹反成功免伤 / 窗口外·超时正常扣血 ====
[V120P] A65-0 起点干净：parry_guard 已复位为 false（窗口外 / 超时态） PASS=true | guard_clean=true
[V120P] A65-1 ★ 窗口外 / 超时（guard=false）→ Boss 招式正常扣血（player_hp 下降）、不发免伤 PASS=true | hp 100.0 -> 88.0 negate_count 1 -> 1
[R36][HUD] A65 弹反·免伤反馈 | wid=parry_0_3 count=2（生产订阅者，非验证脚本）
[V120P] A65-2 ★ 窗口内真实 K 成功弹反 → 免除该次 Boss 招式伤害：玩家 HP 不变、negate_count +1、HUD「弹反·免伤」 PASS=true | attempt_ok=true guard=true hp 88.0 -> 88.0 negate 1 -> 2 hint=[弹反·免伤]
[V120P] A65-3 ★ A65 免伤只作用本次窗口（guard 一次性消费）：下一次 Boss 招式正常扣血、不重复免伤 PASS=true | hp 88.0 -> 76.0 negate_count 2 -> 2
[V120P] SUMMARY pass=31 fail=0 total=31 ok=true parry_source=rank2_production_unique_instance
```

- **窗口内成功 → 玩家 HP 不变**：`hp 88.0 -> 88.0`（guard=true 消费 → 免伤 return）。
- **窗口外 / 超时 → 正常扣血**：`hp 100.0 -> 88.0`、免伤后 `hp 88.0 -> 76.0`（既有 `incoming_damage=12` 逐字不动）。
- **只作用本次窗口**：guard 一次性消费，下一次招式恢复既有扣血路径。
- **HUD 反馈**：`parry_damage_negated` 生产订阅者显示「弹反·免伤」。

---

## 6. 演示覆盖情况（如实登记，不冒充）

`presentation.gd` 450 帧 `--headless` 逻辑帧真跑（**不带 `--write-movie`，不算录屏 / 不启 GPU job / 零付费**）：`PRESENTATION_LOGIC_EXIT=0`、日志 817 行、`SCRIPT_ERROR=0`、`==== [R22 presentation] 时间线完成 frame=450 ====`。

| 覆盖项 | 逻辑真跑实证 | 是否录屏目视确认 |
|---|---|---|
| 战技释放 / FP 扣减 | **真实出现**：Q 注入 14 次 → `[R36][ENC] 战技生产消费` 13 次（`fp 88->88 / 76->76 / 64->64 / 52->52…`，真实扣 FP + 削韧 / 伤害）；战技拒绝 15 次（13 `cooldown` + 2 `insufficient_fp`） | 否（待总指挥定稿录屏目视） |
| 弹反免伤（A65） | **真实出现**：`[R36][HUD] A65 弹反·免伤反馈 | wid=parry_1_2 count=1`；`[R35][ENC] parry_performed 生产订阅生效 | wid=parry_1_2 …` | 否（待目视） |
| 连击 D→A 递进 / S 级收束爆发 | **链路推进已实证**：A57 清波结算 `base=100 → final=198`（倍率 1.98，连击评级确有推进）；J 收束爆发注入 58 次、K 收束爆发 42 次给足机会 | **否**：完整 D→A→S 逐档序列 / S 级收束爆发未在录屏目视确认，按任务单如实登记「链路已接线但演示未覆盖」，不冒充 |
| 注入节奏 | Q 14 次、J 收束 58 次、K 收束 42 次，全部 `Input.parse_input_event` 真实输入路由 | — |

> 依据公共契约「定稿录屏由总指挥本轮亲自重跑并目视，本轮不重复录屏」+ A47（Movie Maker 录屏禁止加 `--headless`），本轮**不含新 MP4 / 抽帧 / 目视帧**；上述为 headless 逻辑帧真跑证据，仅证明「真实按键注入 → 生产链路」连通，不冒充实机画面目视通过。连击 D→A→S 完整序列与 S 级爆发、战技 / 免伤实机观感：**链路已接线但演示目视未覆盖**。

---

## 7. 未完成项 / 待裁决项（如实登记，不擅改）

**未完成项**
1. **定稿录屏 / 目视帧**：按公共契约由总指挥本轮亲自重跑并目视；本轮不含新录屏 / 抽帧 / 目视结论（§6）。
2. **连击 D→A→S / S 级收束爆发**：逻辑真跑证明连击倍率结算推进，但完整评级序列 / S 级爆发实机可见性待目视（§4 失败态②、§6）。
3. **HD-2D 全绿**：差距清单（真 DoF / 真 `volumetric_fog` / SSR / `Environment.glow` / Forward+ 后端）沿用 R35B/R35C 保持未达。
4. **`[PLACEHOLDER]` 试玩校准**：`ANCHOR_FOCUS` 锚点、`R36_*` 演示节奏常量（调参唯一入口 = hud.gd 常量表 / presentation.gd R36 常量段，只改表不改代码）；`focus_rules.tres` 战技数值归 Rank-2，本轮只读。
5. **多战技切换**：Q 单键当前施放 `get_art_ids()[0]`（辉石魔砾 / 辉石魔砾），第二个战技（狮子斩）未接切换键位 / UI；数值来自 `focus_rules.tres`（Rank-2 所有），未擅改。

**待总指挥裁决项**
1. 定稿录屏目视结论（大矩形收敛后续 / FP 条 / 战技 / 免伤 / 连击高评级画面）。
2. Q 战技单键固定首战技 vs 多战技切换键位（涉 HUD 输入层 + Rank-2 表，若需请授权）。
3. A65 免伤范围：本轮按「窗口内成功 → 免除该次 Boss 招式伤害 + guard 一次性消费」收敛；若需「窗口时长内多次招式均免」或与其它无敌 / 减伤路径叠加口径，请裁决。
4. FP 条形态：本轮为「当前 / 上限」真实文本 Label（常驻独立分区）；若需图形进度条 `ProgressBar`，请裁决是否加节点（涉避让断言同步）。
5. `ANCHOR_FOCUS` / `R36_*` 演示节奏 / 全部 `[PLACEHOLDER]` 试玩校准。
6. HD-2D 全绿路线；`128bit` 歧义继续保留（A43/A53/A61）；真实逐次命中坐标（沿用 R35C §7.3）。
7. Rank-2 并行接口异议：本轮初读时 `focus_service.gd` / `get_focus_service()` 未落盘，Rank-1 接线先按鸭子契约 + 判空降级写好，Rank-2 落盘后已对齐真实 `spend_fp(art_id)` / `get_snapshot` / `on_grace_rest` / 4 信号完成真实联调（§2.1）；如 Rank-2 后续微调接口命名，鸭子多候选可兼容，请复核。

---

## 8. A48 四项逐条自查结论（硬要求）

| # | A48 条款 | 逐条自查结论 | 实证 |
|---|---|---|---|
| ① | **任何新信号必须有生产运行时订阅者，不能只出现在验证脚本里** | **达标**。本轮 3 个新信号：HUD `focus_skill_performed` / `focus_skill_rejected` 的订阅者 = **EncounterDirector**（`_r36_bootstrap` connect，真实削韧 / 伤害 / 拒绝记录）；ENC `parry_damage_negated` 的订阅者 = **HUD**（`_r36_bootstrap` connect，A65「弹反·免伤」+ 赐福回满）。另复用既有 `ENC.grace_rested → HUD`、Rank-2 真实 `FocusService.focus_spent → wave_trial_director`。全部 connect 于生产 `_r34_bootstrap → _r36_bootstrap`，去重 + `_r36_release` 释放路径。 | V130 `F4 / F4b / F4c / F5`、V110 `R36-3 / 3b / 3c` 全 PASS；G3 quit 日志 `[R36][ENC] … focus_skill_subscribed=true` |
| ② | **任何新服务遵守 A54 唯一实例（从既有导演层 get_*_service() 复用，不自建第二个）** | **达标**。focus_service 唯一实例由 `wave_trial_director.get_focus_service()` 装配，HUD / ENC 生产 `_r36_bootstrap()` 均复用该**同一真实 Object**、绝不 `new` 第二实例；验证 V130 亦直接复用真实唯一实例（契约替身 `FakeFocus` 仅在 Rank-2 未落盘时降级，本轮 `focus_source=rank2_production_unique_instance` 未触发）。 | V130 `F3`（三方同一）/ `F3b`（真实 spend_fp 非替身）、V110 `R36-2` PASS |
| ③ | **必须有一条不加载 presentation.gd、不在验证脚本内模拟编排的真实可达回归，断言「真实输入 → 生产链路 → 磁盘 / 画面」确实发生** | **达标**。主回归 `verify_focus_runtime_v130.gd`：不加载 presentation.gd（F8 运行时树零 presentation 脚本节点）、不模拟编排（只注入真实 Q + 复用生产唯一实例 / 公开方法）；`Q1~Q4/Q4b` 实证「真实 Q → 真实 FocusService 扣 FP → `focus_skill_performed` → ENC 真实削韧 / 伤害 + `focus_spent` → wave 真实累计 → **画面** ProdFocusLabel 真实可见节点文本 `100/100 → 88/100`」。V110 `R36-4` 追加第二条同口径实证。磁盘侧沿用既有 V110 A57 全链（points_awarded → 编排层 → 磁盘），本轮既有断言不删不放宽。 | V130 `F8 / Q1/Q2/Q3/Q4/Q4b`、V110 `R36-4` PASS |
| ④ | **纯逻辑 + 单元断言不算可玩交付，演示驱动不算真实可达** | **达标**。交付含真实可见节点（ProdFocusLabel 常驻 HUD、四档降级避让）、真实 `_unhandled_input(Q)` 输入、生产运行时订阅链、真实 Boss 削韧 / 伤害、赐福休息回满、A65 免伤，全部经 Godot 4.7.2 三段门禁 + 4 回归真跑；V130 / V110 / V120P / V100HUD 均以 `extends SceneTree` 实例化 courtyard.tscn 生产节点验证，非纯逻辑单元断言；`presentation.gd` 演示驱动仅作覆盖机会注入，不充作真实可达（真实可达由 V130 承担）。 | §3 全部门禁 / 回归输出；§5 A65 实证；§6 演示真跑 |

---

## 9. 回执与中枢归档（写后实测，如实登记）

- 回执写入授权路径（**`teamwork/command_center/`**，非工程根）：`teamwork/command_center/ai/1/outbox/cmd-20261112-154132-903-A1.json`，四字段 `{"task_id":"cmd-20261112-154132-903-A1","ai":1,"status":"done","result":"…引用 DONE-R36.md 实际结论…"}`。
- **中枢归档回读确认（写后实测，如实登记）**：
  - `ai/1/outbox/` 已清空（回执被中枢移走 → `dispatcher/receipts/`，属中枢正常处理，不重放、不伪造）：`ls -A outbox | wc -l = 0`。
  - 归档副本 `teamwork/command_center/dispatcher/receipts/cmd-20261112-154132-903-A1.json` 存在（**2269 字节**），回读 **VALID_JSON**，四字段齐全：`task_id=cmd-20261112-154132-903-A1 / ai=1 / status=done / result_len=1217`（result 引用 DONE-R36.md 实际结论）。
  - `ai/1/status.json`：`{"ai":1,"state":"idle","current_task":"","completed":66,"last_seen":"2026-11-12 16:52:31"}`（`current_task` 清空、state=idle、completed 65→66）。
  - `dispatcher/dispatcher.log` 尾部原文：`[2026-11-12 16:52:31] ← 1 号 AI 回执 <cmd-20261112-154132-903-A1> 完成：R36 / v0.13.0 四块任务全部真跑完成，详见 teamwork/Rank-1/DONE-R36.md 实际结论`，确认 id 与派单一致、中枢已回收验证 `done`。

---

## 10. 硬约束遵守声明

- **唯一写入方**：只写 `encounter_director.gd` / `hud.gd` / `presentation.gd` / 4 个 `verify_*.gd` / `teamwork/Rank-1/`（DONE + 门禁日志）/ 回执。**未改** `wave_trial_director.gd` / `focus_service.gd` / `focus_config.gd` / `focus_rules.tres`（Rank-2 自行落盘，本 AI 只读）/ `points_commit_orchestrator.gd` / `project.godot`（Rank-3）/ `hd2d_fx.gd` / `impact_feedback.gd`（只读）/ 既有 `.tres` / `courtyard.tscn`（A38 节点 41 / uv 2/1/1）/ 素材 / 其它 Rank 产出。
- **不改既有普通攻击判定 / 帧数据 / 输出格式**：ENC 既有 roll/light/heavy/interact 分支与 `_update_hud` 文本格式逐字不动；`presentation.gd` 既有 `[PLACEHOLDER]` 常量数值逐字不动（仅新增 R36 节奏常量段与三段 `_inject_key`）。
- **零付费、零外部依赖、不启 GPU job**：仅本地 Godot 4.7.2；未 `--write-movie` 录屏 / 未调 ffmpeg / 未列任何付费项。
- **SceneTree / `--script` 纪律**：`extends SceneTree` 验证脚本按既有夹具 `add_child` 后显式 `call("_ready")` / `_r34_bootstrap()`；用 `Engine.get_main_loop() as SceneTree` 取 root，不用 `get_tree()` / 不用 `/root/...` 绝对路径；资源 `ResourceLoader.load(..., CACHE_MODE_IGNORE)`；connect 前 `get_signal_connection_list` 去重、`_finish` 有 disconnect 释放路径；`project.godot` 既有 `PointsCommitOrchestrator` autoload 直接复用、不重复挂载。
- **默认不刺探**：未主动扫目录做进度巡检、未新建只读探针 / 巡检脚本；所有读取均针对任务单指定契约 / 目标文件 / 门禁日志 / 归档确认所必需路径，用真跑输出判断进度。
- **不伪造产物、不谎报成功**：三段门禁日志非空（§3.4）、4 回归数字 / SCRIPT ERROR 数字 / A65 实证 / 演示统计均为真跑输出原文；既有 WARNING / ERROR 如实登记（§3 尾注）；未冒称目视通过、未冒称 HD-2D 全绿、未冒称连击 D→A→S / S 级录屏覆盖。
- **不自行 git**（总指挥收尾）；**未删除 `.workbuddy` 目录**（`F:/Game/aierdengfahuan/.workbuddy` 实测存在）。
