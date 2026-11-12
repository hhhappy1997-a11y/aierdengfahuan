# DONE-R35.md · R35 / v0.12.0「精准弹反 · 消费闭合」交付报告（Rank-1）

> 轮次：`R35 / v0.12.0` ｜ 派单 id：`cmd-20261112-125821-135-A1` ｜ 执行 AI：`1（Rank-1 引擎架构与渲染执行）`
> 真源：`teamwork/Rank-1/调度任务单-latest.json`（`task` 全文 + 公共契约 + 目录所有权）+ `teamwork/Rank-1/DONE-R34D.md` + `teamwork/00-群聊总线.md` MSG-20261112-1255-HOST（A49~A57）/ MSG-20261112-0910-HOST（A39~A48）。**以任务单为准**。
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> 结论：**任务①②③④ 全部落地。精准弹反走 Rank-2 真实 `ParryService` 唯一实例（并发执行中已落盘）、真实 K 输入经 HUD → `parry_performed`（生产订阅者 EncounterDirector 真实削韧）→ `points_awarded` → Rank-3 生产 autoload → 磁盘，A48③「不加载 presentation.gd、不模拟编排」真实可达回归 27 PASS 实证；A58 处决/弹反 window_id 非空唯一，`exe:` 去重键不再合并不同窗口；演示 450 帧真跑实证一次成功弹反；三段门禁全 EXIT=0、全工程 `SCRIPT ERROR=0 / Parse Error=0`、本轮核心日志 `ERROR 前缀=0`、A38 节点 41 / uv `2/1/1`、5 份既有 `.tres` md5 逐字一致。如实登记：演示未覆盖 D→A 递进 / S 级爆发目视；Rank-3 `parry:` 去重键待接线；首轮真跑 2 FAIL 与 v050 批量 1 FAIL 均已定位修复/澄清，不冒充一次通过。**

---

## 1. 交付清单（实际落地文件，本轮唯一写入方 = Rank-1）

| 文件 | 类型 | 实际改动 |
|---|---|---|
| `godot/scripts/combat/encounter_director.gd` | 修改（5 处精确 Edit + 文件尾追加 R35 段） | **任务① / A48①**：`_r35_bootstrap()` 从 `wave_trial_director.get_parry_service()` 复用 A54 唯一实例（不自建）+ **connect HUD `parry_performed` 作为生产运行时订阅者**；`_on_parry_performed()` 真实调既有 `_resolve_poise()` 削韧 + 置「连击不断」guard；`_r35_tick()` 帧链转发 `ParryService.tick(delta)`；`_r35_forward_boss_move()` 转发 Boss 出招；`_r35_release()` 释放路径；`get_production_snapshot()` / `get_parry_production_snapshot()` 追加只读键；`_on_boss_move_landed()` 只把既有 `_r34b_combo_on_hit_taken()` 一行包上 guard 门控（成功弹反→连击不断），**扣血 / 免伤判定 / 帧数据 / 输出格式逐字不动**。 |
| `godot/scripts/hud.gd` | 修改（9 处精确 Edit + 文件尾追加 §17 R35 段） | **任务① / A58**：新增 `signal parry_performed(window_id, bonus_points, poise_bonus)`；`_process_r32_keys` 加真实 `KEY_K`（与 F/Tab 同一路径）；`ANCHOR_PARRY` 归一化独立分区 + `get_parry_telegraph_rect()`；`_r34_bootstrap()` 复用 wave 唯一实例；`_r34_build_visible()` 建金色预兆真实节点 `ProdParryLabel`；`_r34_hide_all` / `_r34_refresh_visible` / `_process` / `get_production_status` / `_r34_release` 追加接线；§17 实现 `bind_parry_service` / `poll_parry_service` / `request_parry` / `tick_parry` / `get_parry_hud_view` / `_r35_make_window_id` / `_r35_final_points`（A57 倍率后值）/ `_r35_release`。**A58**：`_open_execution_window()` 由空串改为 `_r35_make_window_id("exe")`。 |
| `godot/test/presentation.gd` | 修改（头部注释 + 常量 + `_drive_real_input` 末尾各 1 处追加） | **任务③**：只追加两段真实 `Input.parse_input_event` 注入（高密度 J + 周期 K），既有 R28/R30/R33/R34 注入节奏与全部 `[PLACEHOLDER]` 常量数值逐字不动、不回退演示驱动、不构造服务状态、不写 Label.text。 |
| `godot/scripts/render/verify_parry_runtime_v120.gd` | **新增** | **任务④ / A48③**：不加载 `presentation.gd` 的真实可达回归，27 条断言（装配 / A54 / A48① / A38 / 金色预兆画面 / 窗口内成功 / 窗口外拒绝 / 重复幂等 / 冷却拒绝 / 超时关窗 / A58 唯一 window_id / 生产削韧 / 生产落盘 / A57 / A50 / exe: 不合并）。 |
| `godot/scripts/render/verify_production_chains_v110.gd` | 修改（追加 R35 组 + 1 处接线） | **任务④**：`_initialize()` 追加 `_t_r35_parry_chain()`，文件尾追加 6 条断言（信号/方法 / A48① 生产订阅者 / A54 唯一实例 / 真实 K 路径 / A58 处决唯一 id / 预兆节点）。**既有 51 条逐字不删不放宽**。 |
| `godot/scripts/render/verify_hud_layout_v100.gd` | 修改（追加 J 组 + 1 处接线） | **任务④**：`_initialize()` 追加 `_test_r35_parry_rects()`，文件尾追加 5 条断言（预兆真实节点 / 金色文本 / **包围盒两两不相交** / 四档降级不出界不遮角色 / 锚点一致）。**既有 31 条逐字不删不放宽**。 |
| `teamwork/Rank-1/DONE-R35.md` | 新增 | 本报告（交付清单 / 真跑输出原文 / 验收三态 / **A48 四项逐条自查** / A58 规则 / 未完成项 / 待裁决项）。 |
| `teamwork/command_center/ai/1/outbox/cmd-20261112-125821-135-A1.json` | 新增 | 本轮回执（§10 写后确认中枢归档）。 |

### 只读未改（硬约束）
`wave_trial_director.gd`（Rank-2 所有，本轮其 R35 段由 Rank-2 自行落地）、`parry_service.gd` / `parry_config.gd` / `parry_rules.tres` / `verify_parry_v120.gd` / `verify_parry_settlement_v120.gd`（Rank-2 产出，只读复跑）、`points_commit_orchestrator.gd` / `project.godot` / `00-协作契约.md` / 迭代文档 / README（Rank-3 所有）、`courtyard.tscn`（A38）、5 份既有 `.tres`、素材、Rank-4 产出。未删除 `.workbuddy`。

---

## 2. 任务① · 精准弹反运行时接线（真实链路）

### 2.1 链路（生产运行时，非演示驱动）
```
Rank-2 wave_trial_director（波次/Boss 出招前）
   → ParryService 唯一实例 open_window()  [真实表 parry_rules.tres window_sec=0.35 [PLACEHOLDER]]
   → HUD poll_parry_service()（权威快照）/ parry_window_opened 信号 → 金色预兆 + 读秒
   → 玩家真实按 K（Input.parse_input_event → HUD._unhandled_input → _process_r32_keys）
   → HUD.request_parry()：窗口外 / 重复 consumed / 冷却 门控拒绝；窗口内 → ParryService.try_parry()
   → 成功：HUD emit parry_performed(wid, final_pts, poise_bonus)
        ├→ ★生产订阅者 EncounterDirector._on_parry_performed() → 既有 _resolve_poise() 真实削韧
        │     + 置 guard → 下一次 Boss 出招跳过 on_hit_taken（连击不断）
        └→ HUD emit points_awarded("parry", A57 倍率后值, ...) → Rank-3 PointsCommitOrchestrator autoload
              → 磁盘 grace.trial.points（A55 原样采信，Rank-1 不写盘）
   → 失败 / 超时：既有受击结算（_on_boss_move_landed 扣血 / 帧数据 / 输出格式逐字不动）
```
- **HUD 金色预兆**：`ProdParryLabel` 真实可见节点，字体 `Color(1.0,0.84,0.30)` 金色，文本 `精准弹反窗口 %.1fs · 按 K`；独立归一化锚点 `ANCHOR_PARRY = (0.01875, 0.40278, 0.27813, 0.08333)`，不并入 6 分区数组（保护 A1「size()==6」），随视口等比缩放。
- **不改既有判定**：`_on_boss_move_landed()` 仅把一行 `_r34b_combo_on_hit_taken()` 包上 `_r35_consume_parry_guard()`；`_player_hp -= incoming_damage` / `_hits_taken` / invulnerable 判定 / `_update_hud()` 输出格式逐字未动。`verify_encounter_v010/v020/v030` 复跑 `20/45/53 PASS` 全绿实证。
- **A57 倍率后值口径**：`_r35_final_points(base)` 取 A54 唯一 `ComboService.get_last_settlement()` 有效倍率（回落 `get_multiplier()`），`final = round(base × mult)`；无有效倍率 / 服务不可用 → 回落基础值 + `push_warning`（失败降级，不静默）。真跑 `base=50 final=50`（D 级 1.0），C3 PASS。
- **A54 / 鸭子类型**：HUD / ENC 均**不静态引用 `ParryService` class_name**，全用 `has_method` / 候选方法名 / `CACHE_MODE_IGNORE` 回读；Rank-2 接口未落盘时判空降级、不产生 `SCRIPT ERROR`、不崩。本轮 Rank-2 已落盘，真跑 `parry_source=rank2_production_unique_instance`（见 §4）。

### 2.2 新数值（全部 `[PLACEHOLDER]`，调参唯一入口 = 表，只改表不改代码）
| 数值 | 来源 / rationale |
|---|---|
| `window_sec=0.35` / `cooldown_sec` / `poise_bonus=25.0` / `points_bonus=50` / `combo_keep` / `fail_penalty` | `res://data/combat/parry_rules.tres`（**Rank-2 所有**，Rank-1 只读消费，不改） |
| `R35_PARRY_WINDOW_FALLBACK_SEC=0.8` | `hud.gd` §17 读秒降级初值；rationale：服务未提供 remaining 时给可见但短促的初值，真实时长以表 / 服务快照为准 |
| `ANCHOR_PARRY` 布局锚点 | `hud.gd` 布局段；rationale：与 guide 下沿留 0.03056 垂直缝、与中央角色左沿留 0.01562 水平缝，四档降级不出界 / 不与任一文字相交 |
| `R35_*` 演示按键密度（J 间隔 4 帧 / K 间隔 5 帧 / 扫描窗 30~440） | `presentation.gd` 头部；rationale：450 帧内约 100 次额外真实 J + 83 次额外真实 K 注入，提高真实链路自然触发概率，不改任何战斗数值表 |

---

## 3. 任务② · A58 修 window_id 空串（生成规则 + 失败降级）

- **生成规则**（`hud.gd::_r35_make_window_id(prefix)`）：
  - 格式 `<prefix>_<wave>_<seq>`，`prefix ∈ {exe, parry}`；
  - `wave` = `_r34_wave.get_snapshot().index`（波次导演真实当前波）；
  - `seq` 按前缀各自**单调递增** → 同进程内任意两个窗口 id 必不相等；
  - 处决：`_open_execution_window()` 生成 `exe_<wave>_<seq>`，随 `execution_performed(window_id, bonus_points)` 带出；
  - 弹反：`_r35_open_parry_window()` 优先采信服务快照的非空 `window_id`，为空则本地生成 `parry_<wave>_<seq>`，随 `parry_performed(window_id, ...)` 带出（亦写入 `get_parry_hud_view()` 供 Rank-4 / 验证读取）。
- **失败降级**（不静默）：波次导演不可用 → `wave` 回落 `0` + `push_warning`（seq 仍保证唯一）；服务未带 id → 本地生成；`prefix` 空 → `win`；生成结果**恒为非空字符串**。
- **不合并实证**：`verify_parry_runtime_v120.gd` C5b — 两次处决 `exe_0_1 / exe_0_2`，Rank-3 编排层 `claimed` 含 `exe:exe_0_1` 与 `exe:exe_0_2` 两个不同键（旧空串会合并为单一 `exe:` → 第二次被去重拒绝）。`parry:parry_0_1 / parry_0_2` 已随信号带出，去重键接线见 §7 待裁决第 1 条。

---

## 4. 真跑输出原文（三段门禁 + 全工程 G3）

统一命令前缀：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；纯引擎日志落系统临时目录 `/tmp/r35_*.log`（未写入工程内）。

### GATE-1 `--headless --import`
```
GATE1_EXIT=0
[ DONE ] first_scan_filesystem
[   0% ] update_scripts_classes | Started 正在注册全局类…… (5 steps)
```

### GATE-2a `--check-only --script`（6 件，全 `EXIT=0`）
```
CHECK res://scripts/hud.gd EXIT=0
CHECK res://scripts/combat/encounter_director.gd EXIT=0
CHECK res://test/presentation.gd EXIT=0
CHECK res://scripts/render/verify_parry_runtime_v120.gd EXIT=0
CHECK res://scripts/render/verify_production_chains_v110.gd EXIT=0
CHECK res://scripts/render/verify_hud_layout_v100.gd EXIT=0
```

### GATE-2b `--headless --script`（3 份本轮自测，全 `EXIT=0`）
```
verify_parry_runtime_v120    EXIT=0  [V120P] SUMMARY pass=27 fail=0 total=27 ok=true parry_source=rank2_production_unique_instance | RESULT=ALL_MATCH
verify_production_chains_v110 EXIT=0 [V110]  SUMMARY pass=57 fail=0 total=57 ok=true | RESULT=ALL_MATCH
verify_hud_layout_v100       EXIT=0  [V100HUD] SUMMARY pass=36 fail=0 total=36 ok=true | RESULT=ALL_MATCH
```
> 既有断言不回退：`verify_production_chains_v110.gd` 既有 `51` + R35 追加 `6` = `57`；`verify_hud_layout_v100.gd` 既有 `31` + J 组 `5` = `36`，均逐字不删不放宽。

`verify_parry_runtime_v120.gd`（`[V120P]`，27 条逐条 PASS，关键行节选）：
```
[V120P] A49/A48③：不加载 presentation.gd；不模拟编排；真实 K 输入 → 生产链路 → 磁盘/画面
[V120P] A54：复用 wave.get_parry_service() 唯一实例（Rank-2 真实服务已落盘）→ 走真实判定
[V120P] C0 生产编排层实例就位（优先 autoload，不重复挂载） PASS=true | source=autoload
[V120P] C0c PointsCommitOrchestrator.bind_hud 成功（A55 唯一权威通道） PASS=true | bound=true
[V120P] P1 A54 唯一实例：HUD.get_parry_service() 与唯一实例为同一 Object PASS=true | same=true
[V120P] P2 A48① ★ parry_performed 有【生产运行时订阅者 EncounterDirector】 PASS=true | subscribers=2 enc_subscribed=true
[V120P] P5 A38 courtyard.tscn 节点 41 / uv 2/1/1 原样 PASS=true | count=41 uv_2x=1 uv_1x=2
[R35][HUD] 可弹反窗口开启 | wid=parry_0_1 sec=0.35（金色预兆 + 读秒，真实 K 输入待触发）
[V120P] W1 开窗 → 金色预兆 + 读秒：ProdParryLabel 真实节点可见且文本含「精准弹反/按 K」 PASS=true | text=[精准弹反窗口 0.3s · 按 K] visible=true
[V120P] W1b 金色预兆文字为金色 PASS=true | gold=true
[R35][ENC] parry_performed 生产订阅生效 | wid=parry_0_1 bonus=50 poise_bonus=25.0 boss_poise=95.0 applied=1
[R35][HUD] 弹反成功 | wid=parry_0_1 base=50 final=50 poise_bonus=25.0 → parry_performed + points_awarded 已发（A57 倍率后值）
[V120P] W2 ★ 窗口内真实 K 输入（Input.parse_input_event）→ 弹反成功 PASS=true
[V120P] W3 ★ 成功 → parry_performed（带 window_id）+ points_awarded(parry) 各发一次 PASS=true
[V120P] W4 A58 ★ window_id 非空且为 parry_<wave>_<seq> 格式 PASS=true | wid=parry_0_1
[V120P] W5 ★ 窗口内重复按 K 幂等：不重复发 parry_performed / points_awarded PASS=true | attempt2.reason=window_closed（服务成功后关窗）
[V120P] W6 ★ 窗口外按 K 拒绝（window_closed，失败按既有正常受击结算） PASS=true
[V120P] W7a 第 2 个窗口内真实 K → 第 2 次弹反成功 PASS=true
[V120P] W7b A58 ★ 两次窗口 window_id 不合并 PASS=true | wid1=parry_0_1 wid2=parry_0_2
[V120P] W7c ★ 冷却期按 K 拒绝（服务 cooldown_remaining>0 拒绝开窗） PASS=true | cooldown=1.20 open_res.reason=cooldown
[V120P] W8 可弹反窗口超时自动关闭 PASS=true
[V120P] C1 ★ A48③ 生产链：parry_performed 由 EncounterDirector 真实消费并调用既有 _resolve_poise 削韧 PASS=true | events=2 poise_applied=2
[V120P] C2 ★ 真实输入 → points_awarded → PointsCommitOrchestrator（生产 autoload）→ 磁盘 grace.trial.points PASS=true | disk=50 runtime=50 commit_count=1
[V120P] C3 A57 口径：points_awarded(parry).points 为倍率后最终值 PASS=true | points_awarded=50 base=50
[V120P] C4 生产 slot_01 md5 前后一致 PASS=true
[V120P] C5a A58 ★ 两次处决窗口 window_id 非空且唯一 PASS=true | exe1=exe_0_1 exe2=exe_0_2
[V120P] C5b A58 ★ Rank-3 编排层 exe: 去重键不再合并不同窗口 PASS=true | k1=exe:exe_0_1 k2=exe:exe_0_2
[V120P] C6 A50：Rank-1 R35 追加段源码零写盘 PASS=true | no_write=true
[V120P] [如实登记] Rank-3 编排层本轮尚未订阅 parry_performed 生成 parry:<window_id> 去重键 → 第 2 次弹反 points_awarded 被 auto 指纹去重拒绝（Rank-1 已随 parry_performed 带出非空唯一 window_id；parry: 键接线待 Rank-3 / 总指挥裁决）
[V120P] SUMMARY pass=27 fail=0 total=27 ok=true parry_source=rank2_production_unique_instance
[V120P] RESULT=ALL_MATCH
```

### GATE-2b 既有回归复跑（14 个，只读复跑；13 全绿 + 1 环境澄清）
```
verify_encounter_v010         EXIT=0 20 PASS / ALL_MATCH   ← 既有 20 条不回退（我改了 _on_boss_move_landed）
verify_encounter_v020         EXIT=0 45 PASS / ALL_MATCH
verify_encounter_v030         EXIT=0 53 PASS / ALL_MATCH
verify_combo_v110             EXIT=0 110 PASS / ALL_MATCH
verify_combo_runtime_v110     EXIT=0 39 PASS / ALL_MATCH
verify_points_commit_production_v110 EXIT=0 28 PASS / ALL_MATCH
verify_stagger_runtime_v100   EXIT=0 16 PASS / ALL_MATCH
verify_stagger_v100           EXIT=0 62 PASS / ALL_MATCH
verify_hud_binding            EXIT=0 11 PASS / ok=true
verify_persistence_hud_v050   EXIT=1 29 PASS / 1 FAIL（批量跑时前序脚本污染 slot_01 的 A2 结构断言）
verify_parry_v120             EXIT=0 58 PASS / ALL_MATCH   ← Rank-2 产出只读复跑
verify_parry_settlement_v120  EXIT=0 80 PASS / ALL_MATCH   ← Rank-2 产出只读复跑
verify_v110_save_commit       EXIT=0 64 PASS / PASS
verify_production_settlement_v110 EXIT=0 59 PASS / ALL_MATCH
```
> **v050 澄清（非本轮引入、不谎报）**：批量顺序跑时前面脚本把生产 `slot_01/delta.json` 写成 8 字段（缺 `slot` / `quests`、值 7/1337），v050 的 `selftest` 经 `_ws._load()` 读到该骨架 → A2「十字段齐全」1 FAIL。恢复完整十字段基线（`best_wave=3 / points=450`）后**单独复跑**：
> ```
> V050_ALONE_EXIT=0  [V050] SUMMARY pid=29540 pass=30 fail=0 ok=true | RESULT=ALL_PASS
> ```
> 既有 30 条逐字不回退。生产 `slot_01` 在所有真跑结束后已恢复至本轮基线（见 §9）。

### GATE-2b 演示驱动真跑（任务③ 覆盖证据）
```
DEMO_EXIT=0
==== [R22 presentation] 时间线完成 frame=450（--quit-after 450 负责退出）====
SCRIPT ERROR=0
弹反成功次数=1  开窗次数=3
[R35][WaveTrial] 波次开始精准弹反开窗：index=1/2/3 window_sec=0.35（生产链路，非验证脚本模拟）
[R35][HUD] 弹反成功 | wid=parry_1_2 base=50 final=50 poise_bonus=25.0 → parry_performed + points_awarded 已发（A57 倍率后值）
[R34D][HUD] A57 c 链：真实 wave_cleared(index=0 base=100 final=115 settled=true) → 抉择卡片 open=true
```
> **一次成功弹反在 450 帧内自然出现（实证）**；连击 D→A 递进 / S 级收束爆发见 §6 未完成项（如实登记未覆盖）。

### GATE-3 `--headless --quit`（主场景生产实证）
```
GATE3_EXIT=0
[SaveSystem] 自动读回完成 | dungeon.wave_trial.best_wave=3 | grace.trial.points=450 | dungeon.wave_trial.completed=true
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41
[R35][WaveTrial] 精准弹反生产订阅者已装配：ParryService 唯一实例 + 4 信号 connect（A48①/A54）
[R35][HUD] A54 唯一 ParryService 已复用 wave.get_parry_service()（不自建第二实例）
[R35][ENC] 生产装配 | parry_unique_instance=true parry_performed_subscribed=true（A48① 生产运行时订阅者）
[R34C][PCO] 生产订阅者已绑定 HUD | signals=4 slot=user://saves/slot_01（A55 唯一权威通道）
```

### 全工程 G3 统计（25 份 `/tmp/r35_*.log`）
```
本轮核心日志（G1/G3/演示/3 自测/11 回归）：SCRIPT ERROR=0 / Parse Error=0 / ERROR 前缀=0
全工程合计：                              SCRIPT_ERROR_COUNT=0 / PARSE_ERROR_COUNT=0   ← 任务单硬要求达标
额外复跑的 3 个既有旧脚本（v010/v020/v030）：11 条既有引擎级 ERROR 打印
   （"Can't use get_node() with absolute paths..." / "Signal 'boss_defeated' is already connected..."）
   —— 全部为旧脚本 --script 模式已知打印、非 SCRIPT ERROR、非本轮引入，三者 RESULT 均 ALL_MATCH
```

### A38 / 既有 `.tres` 零改动
```
node_count=41  uv_2x=1  uv_1x=2
793b6daa7c7730feed1a3f849701d58a  data/rpg/wave_trial.tres
44d8b941f8b28dfa2931984707b5c53e  data/rpg/boon_draft.tres
7e9e5ac7d35d8d15171e69975ac3356d  data/rpg/trial_modifiers.tres
49ce964e7c268804efbf2f20bec6565d  data/combat/stagger_rules.tres
a1ad4635ae0342c696fe650eb13d4930  data/rpg/combo_rules.tres
（与 DONE-R34D 基线逐字一致）
```

### WARNING 如实登记（非 `SCRIPT ERROR`、不影响门禁 `EXIT=0`）
```
WARNING: [R34C][PCO] 重复领取拒绝 | event_key=auto:parry:50:parry_service.try_parry ...（Rank-3 parry: 键未接线，见 §7）
WARNING: [SaveSystem] --script 工具模式（未带 v050_read 标记）：跳过自动读回（降级，不崩）
WARNING: 2 ObjectDB instances were leaked at exit（既有 --script 降级）
```

---

## 5. A48 四项 · 逐条自查结论（硬要求，前三轮三次重演）

| # | 硬要求 | 自查结论 | 证据 |
|---|---|---|---|
| **①** | 任何新信号必须有**生产运行时订阅者**，不能只出现在验证脚本里 | **通过**。本轮唯一新信号 `hud.parry_performed` 的生产订阅者 = **`EncounterDirector`**（`_r35_bootstrap()` connect，`_on_parry_performed()` 真实削韧 + 连击 guard）；不是验证脚本探针。 | `verify_parry_runtime_v120.gd` P2 `PASS=true | enc_subscribed=true subscribers=2`；**GATE-3 主场景日志** `[R35][ENC] ... parry_performed_subscribed=true`；Rank-2 的 4 个 ParryService 信号亦由 `wave_trial_director` 生产订阅（GATE-3 `[R35][WaveTrial] ... 4 信号 connect`） |
| **②** | 任何新服务遵守 A54 唯一实例（从既有导演层 `get_*_service()` 复用，不自建第二个） | **通过**。HUD / ENC 一律经 `wave_trial_director.get_parry_service()` 鸭子类型复用，**没有任何 `new()` / 第二实例**；Rank-2 未落盘时判空降级而非自建。 | `verify_parry_runtime_v120.gd` P1 `PASS=true | hud_bound=true same=true`（hud 与 wave 同一 Object）；GATE-3 `[R35][HUD] A54 唯一 ParryService 已复用 wave.get_parry_service()（不自建第二实例）`；`verify_production_chains_v110.gd` R35-3 `PASS=true` |
| **③** | 必须有一条**不加载 `presentation.gd`、不在验证脚本内模拟编排**的真实可达回归，断言「真实输入 → 生产链路 → 磁盘 / 画面」确实发生 | **通过**。`verify_parry_runtime_v120.gd` 自行 instantiate 主场景、**不加载 presentation.gd**；注入真实 K（`Input.parse_input_event` + `process_key_event`）；落盘 / 去重 / 原子写全由**生产 `PointsCommitOrchestrator` autoload** 执行（本脚本只读磁盘断言，不写编排逻辑）；独立 PID 临时槽与生产 slot_01 物理隔离。 | W1 画面（`ProdParryLabel` 真实节点 visible + 金色预兆文本）；W2 真实输入成功；C1 生产削韧 `poise_applied=2`；**C2 磁盘真值 `disk=50 commit_count=1`**；C4 生产 slot_01 md5 前后一致；GATE-3 生产主场景实证装配 |
| **④** | 纯逻辑 + 单元断言不算可玩交付，演示驱动不算真实可达 | **通过**。可达性由 §③ 的真实输入 / 生产节点 / 磁盘 / 真实可见节点断言承担；`presentation.gd` 演示驱动**只用于「演示覆盖」登记**（450 帧实证一次成功弹反），绝不作为 A48 可达性证明；Rank-2 纯逻辑脚本 `verify_parry_v120.gd` 仅只读复跑佐证联调。 | `verify_parry_runtime_v120.gd` 头部 A49/A48③ 口径声明；§4 GATE-2b 演示驱动输出；§6 未完成项如实登记演示未覆盖部分 |

**补充**：Rank-2 在本轮并发执行中已落盘 `parry_service.gd` / `parry_config.gd` / `parry_rules.tres` 与 `wave_trial_director.get_parry_service()`，真跑 `parry_source=rank2_production_unique_instance` → 全链走**真实服务**，未启用契约替身（`FakeParry` 仅作为 Rank-2 未落盘时的降级分支保留并如实登记）。

---

## 6. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 任务①：精准弹反真实 K 输入 → 窗口 → 成功削韧 / 赐福点数 / 连击不断、失败超时正常受击；HUD 金色预兆 + 读秒真实可见节点；不改既有伤害判定 / 帧数据 / 输出格式（`v010/v020/v030` 20/45/53 PASS 不回退）；A54 唯一实例、A57 倍率后值口径。② 任务②：A58 `exe_<wave>_<seq>` / `parry_<wave>_<seq>` 非空唯一，`exe:` 键不合并（C5b 实证两个不同键），生成规则 + 失败降级写清。③ 任务④：新写 `verify_parry_runtime_v120.gd` 27 PASS、扩展两份 v110/v100 各自 `57 / 36 PASS`（既有断言逐字不删不放宽、预兆文字包围盒不相交 + 四档降级），均 `RESULT=ALL_MATCH`。④ 任务③：只追加真实按键注入节奏、不改 `[PLACEHOLDER]` 数值、不回退演示驱动；450 帧真跑 `EXIT=0`、一次成功弹反自然出现、开窗由生产链路。⑤ 三段门禁全 `EXIT=0`、全工程 `SCRIPT ERROR=0 / Parse Error=0`、本轮核心日志 `ERROR 前缀=0`、A38 节点 41 / uv `2/1/1`、5 份既有 `.tres` md5 零改动。⑥ **A48 四项逐条通过**（§5）。⑦ 目录所有权：只写 6 个工程脚本 + Rank-1 文档 + 回执，Rank-2/3/4 产出、`wave_trial_director.gd` / `points_commit_orchestrator.gd` / `project.godot` / `courtyard.tscn` / 既有 `.tres` 一律只读未改。 |
| **失败** | 无最终失败。**如实登记过程，不冒充一次通过**：① 首轮 `verify_parry_runtime_v120.gd` 为 `25 PASS / 2 FAIL / MISMATCH`——根因是验证脚本按契约替身假设「成功后 HUD 保留窗口 / 冷却期 HUD 命中 cooldown 门控」，而 Rank-2 真实服务成功后**主动关窗并进入冷却**、冷却期 `open_window()` 直接返回 `cooldown` 拒绝；生产逻辑正确，是断言假设过严。修正为按真实行为断言「不重复结算 / 不重复落盘」+ 兼容两种拒绝 reason，第二轮 `27 PASS / 0 FAIL`。② v050 批量复跑 1 FAIL（前序脚本污染 slot_01），单独复跑 `30 PASS / ALL_PASS`（§4）。 |
| **需用户确认** | ① 15~20 秒实机录屏目视由总指挥本轮亲自重跑（headless 无像素级目视，本 AI 不重复录屏、不冒充目视通过）；② 全部 `[PLACEHOLDER]` 数值待人工试玩校准（只改表）；③ 演示 D→A 递进 / S 级爆发目视；④ Rank-3 `parry:` 去重键接线；⑤ 弹反成功是否应免伤（§7）；⑥ 既有 WARNING 清理；⑦ HD-2D 全绿（A41 未达）、`128bit` 歧义（A43 保留）沿用既有登记。 |

---

## 7. 未完成项（如实登记，交总指挥排期）

1. **演示未覆盖 D→A 递进 / S 级收束爆发**：本轮只改按键密度、不改 `[PLACEHOLDER]` 数值、不回退演示驱动；450 帧 headless 真跑实证「一次成功弹反」与 A57 倍率后值（`base=100 → final=115`，至少跨到 C 档），但 HUD 连击评级文本只写 `Label.text`、不打印到日志，**headless 日志无法实证 A / S 级**，按任务单如实登记「**链路已接线但演示未覆盖（A/S 级）**」，不冒充。D→A 的生产链路由既有 `verify_combo_runtime_v110.gd`（14 击到 A 级 1.6）与 `verify_combo_v110.gd`（110 PASS）实证。由总指挥录屏目视判定。
2. **Rank-3 `parry:<window_id>` 去重键未接线**：`PointsCommitOrchestrator`（Rank-3 唯一写入）本轮 `BOUND_SIGNALS` 仍为 4 信号、未订阅 `parry_performed`，第 2 次弹反 `points_awarded` 被 `auto:parry:50:parry_service.try_parry` 指纹去重拒绝（C2 如实登记）。Rank-1 已把非空唯一 `window_id` 随 `parry_performed` 带出，接线归 Rank-3 / 总指挥裁决。
3. **实机录屏目视**：headless 无帧缓冲，按公共契约由总指挥本轮亲自重跑 15~20 秒并目视。
4. **`[PLACEHOLDER]` 数值校准**：`parry_rules.tres`（window_sec / cooldown_sec / poise_bonus / points_bonus / fail_penalty）、`combo_rules.tres`（rank_thresholds / multiplier / timeout_sec）、`R35_*` 演示节奏、布局锚点待人工试玩；调参只改表不改代码。
5. **弹反成功免伤语义**：为严守「不改既有伤害判定」，本轮成功只跳过 `on_hit_taken`（连击不断）+ 追加削韧 + 赐福点数，既有扣血逐字不动；「成功是否应免伤」见 §8 待裁决。
6. **既有 WARNING / 降级日志**（SaveSystem 工具模式 / ChunkManager / ObjectDB 泄漏 / PCO 去重拒绝）：非本轮引入，是否纳入后续清理由总指挥裁决。
7. **历史口径同步**（Rank-3 所有）：契约 §3.3 / DONE-R34C §7「处决 window_id 空串」表述，A58 已在代码层闭合，是否同步登记请裁决。
8. **HD-2D 全绿未达**（A41）、`128bit` 歧义（A43）、地面裂缝观感、真机 exe / apk 手感：沿用既有登记。

---

## 8. 待总指挥裁决项（只登记、不擅改）

1. **Rank-3 `parry:` 去重键接线**（A58 的弹反一半）：Rank-1 已随 `parry_performed` 带出非空唯一 `window_id`；`points_commit_orchestrator.gd` 归 Rank-3 唯一写入，是否本轮追加 `parry_performed` 订阅 + `parry:<window_id>` 配对键，请裁决（当前第 2 次及以后弹反点数被 auto 指纹去重拒绝）。
2. **弹反成功是否免伤**：当前按硬约束「不改既有伤害判定」保留扣血，仅连击不断 + 削韧 + 点数；若玩法要求「成功化解本次出招免伤」，需授权在 `_on_boss_move_landed` 增加前置门控（会改变既有受击结算分支），请裁决。
3. **演示 A/S 级覆盖**：是否允许进一步调整 `presentation.gd` 的 `R35_*` 节奏常量（新增 `[PLACEHOLDER]`，不改既有数值）或由总指挥录屏判定即可。
4. **契约 / 历史 DONE 口径同步**（§7 第 7 条）。
5. **既有 WARNING 清理**、**`grace.trial.spent_points` 抉择扣费出口**（R34C 延续）、**实录屏回看**：沿用既有裁决。

---

## 9. 硬约束 / 纪律遵守声明

- **唯一写入方 = Rank-1**：仅 `encounter_director.gd` / `hud.gd` / `presentation.gd` / `verify_parry_runtime_v120.gd` / `verify_production_chains_v110.gd` / `verify_hud_layout_v100.gd` + `DONE-R35.md` + 回执；其余一律只读。`courtyard.tscn` 静态 `[node]` 41 / uv `2/1/1` / 节点名未破坏；5 份既有 `.tres` md5 与 R34D 基线逐字一致。未删除 `.workbuddy`。
- **A50 / A55 边界**：Rank-1 只发 `points_awarded` 信号不写盘；`verify_parry_runtime_v120.gd` C6 静态断言 R35 追加段无 `set_flag` / `commit` / `FileAccess.open`；落盘唯一写入方仍为 Rank-3 编排层（本轮只读复跑）。
- **Godot 4 `--script` 纪律**：`extends SceneTree` 用 `Engine.get_main_loop() as SceneTree` 取 root、不用 `get_tree()` / 不用 `/root/...` 绝对路径；`add_child` 后显式 `call("_ready")` / `_r34_bootstrap()`；对已装配 `PointsCommitOrchestrator` autoload **不重复挂载**；资源 `CACHE_MODE_IGNORE` 回读；connect 前 `get_signal_connection_list()` 去重、`_finish()` / `_r35_release()` 有释放路径；独立 PID 临时槽与生产 `slot_01` 物理隔离。
- **生产存档保护（如实登记）**：演示驱动 / `verify_persistence_hud_v050.gd` 的 `selftest` 会写 `user://saves/slot_01/delta.json`；本轮在真跑前备份、真跑结束后**恢复至本轮基线** `md5=219cbf043d3ae14a97f66c44f0e9591e`（`best_wave=3 / points=450`，十字段齐全）。所有本轮验证脚本自身均使用独立 PID 临时槽，`C4` 实证生产 `slot_01` md5 前后一致。
- **零付费、零外部依赖、不启 GPU job**；不伪造产物、不谎报成功、不自行 git（总指挥收尾）；未写只读探针 / 巡检脚本、未扫目录做进度巡检、未反复核对文件状态（仅按任务单读取必读文件 + 必要的只读接口源码，真跑日志落系统临时目录）。

---

## 10. 回执与中枢归档

- 回执路径（**`teamwork/command_center/`，非工程根**）：
  `teamwork/command_center/ai/1/outbox/cmd-20261112-125821-135-A1.json`
- 四字段：`{"task_id":"cmd-20261112-125821-135-A1","ai":1,"status":"done","result":"引用 DONE-R35.md 实际结论：…"}`。
### 回执写后确认（中枢归档 · 实测，非推断 / 不伪造 / 不重放）
```
· 回执写入 ai/1/outbox/ 后由中枢自动回收：写后 outbox 已清空（中枢正常处理，
  与 DONE-R34B/R34C/R34D §10 口径一致）
· dispatcher/receipts/cmd-20261112-125821-135-A1.json  VALID_JSON=True
  keys=['ai','result','status','task_id'] | task_id 正确 | ai=1 | status=done
  | result 与回执逐字一致（引用 DONE-R35.md 实际结论）
· dispatcher/ledger.jsonl 新增 1 条：
  id=cmd-20261112-125821-135-A1 status=done finished_at=2026-11-12 13:41:34
· ai/1/status.json：state=idle / current_task="" / completed=64（63→64）
  / last_seen=2026-11-12 13:41:34
· dispatcher/dispatcher.log 尾部原文：
  [2026-11-12 13:41:34] ← 1 号 AI 回执 <cmd-20261112-125821-135-A1> 完成：引用 DONE-R35.md 实际结论：…
```
> 归档到 `teamwork/command_center/dispatcher/receipts/`（**是 teamwork/command_center/，不是工程根**）；归档 / 台账 / 状态更新由中枢流程完成，Rank-1 只写 outbox、未自建 / 未伪造归档、未重放。
