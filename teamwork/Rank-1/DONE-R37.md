# DONE-R37.md · R37 / v0.14.0「元素瓶与死亡轮回 · 画面补齐」交付报告（Rank-1）

> 轮次：`R37` ｜ 任务单 id：`cmd-20261112-184157-061-A1` ｜ 执行 AI：`1（Rank-1 引擎架构与渲染执行 AI）`
> 真源：`teamwork/Rank-1/调度任务单-latest.json`（task 全文 + 公共契约 + A48 硬要求 + 目录所有权，HOST 裁决 A65~A69 见 `00-群聊总线.md` MSG-20261112-1840-HOST）
> 前序：`teamwork/Rank-1/DONE-R36B.md`（A54 唯一实例 / R36B 独立分区 / 契约替身先例）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
>
> **一句话结论**：R37 四块任务全部真跑完成 —— `hud.gd` / `encounter_director.gd` 接真实 `_unhandled_input(G)` 与死亡轮回状态表现，HUD 新增独立分区真实节点 `ProdFlaskLabel`「元素瓶 N/M」与 `ProdDeathLabel`「你死了 / 掉落赐福点数」；**Rank-2 的 FlaskService / DeathService 在本轮执行期间落盘，`get_flask_service()` / `get_death_service()` 三方同一真实实例，V140 走的是真实 Rank-2 服务（非契约替身）**：真实 G → 瓶扣减 / HP 回复（A57 原样写回 ENC `_player_hp`）/ 瓶尽拒绝 / 满血拒绝 / 赐福补满瓶 / 双接幂等，真实 HP 归零 → 死亡态 → 赐福重生回满 HP/FP/瓶。新写 `verify_life_runtime_v140.gd`（不加载 `presentation.gd`）26/26、V110 66→75、V100HUD 44→48、V130 39/39、V120P 31/31，**219 PASS / 0 FAIL 五份全 `RESULT=ALL_MATCH`**。三段门禁 G1/G2a(8)/G2b(5)/G3 全 `EXIT=0`、全工程 19 段日志 `SCRIPT ERROR=0 / PARSE_ERROR=0`；A38 节点 **41** / uv `2/1/1` 不变；10 份既有 `.tres` md5 与 DONE-R36B 逐字一致。**演示覆盖如实登记**：元素瓶 450 帧内成功 1 次（已覆盖）；连击 D→A→S / S 级爆发与「一次死亡与重生」在 450 帧内**未自然出现 → 链路已接线但演示未覆盖，不冒充**。**未完成 / 待裁决**：定稿录屏目视、死亡重生演示覆盖、掉落点数来源、`reclaim_dropped()` 触发点、HD-2D 全绿。

---

## 1. 交付清单（实际落地文件）

| # | 文件 | 类型 | 本轮改动 |
|---|---|---|---|
| ① | `godot/scripts/hud.gd` | 修改（Rank-1 唯一写入） | 新增 4 个 R37 信号 `flask_used / flask_rejected / player_died / player_respawned`；独立分区锚点 `ANCHOR_FLASK / ANCHOR_DEATH` + `get_flask_rect() / get_death_rect()`；`ProductionMechanismsLayer` 新建真实节点 `ProdFlaskLabel`（常驻）/ `ProdDeathLabel`（死亡态）；`set_layout_viewport()` 联动 R37 rect；`_process_r32_keys` 加 G 分支 + 死亡态门禁（死亡期间拒绝 G/Q/K/F）；`_r34_bootstrap` / `_exit_tree` 加 R37 装配 / 释放；末尾追加 19 节 R37 实现（鸭子类型契约、`request_flask_use` 唯一权威入口、`on_player_hp_changed` → `on_death(grace_points)`、`_r37_on_grace_rested` 重生 + 重入守卫、A54 复用、只读视图、生产订阅、释放）。既有 12 信号 / 14 个 `get_focus_hud_view` key / 6 分区布局 / Q·K·F·R 判定 / 普通攻击判定 / 输出格式逐字不动。 |
| ② | `godot/scripts/combat/encounter_director.gd` | 修改（Rank-1 唯一写入） | `_unhandled_input` 追加 G 分支（+ 死亡态门禁对新增 G/Q/R 消费不转发，既有 roll/light/heavy/interact/Q/R 判定逐字不动）；`_on_boss_move_landed` 扣血后追加一行 `_r37_forward_hp_changed()`（只转发 HP，不改既有判定 / 帧数据 / 胜负结算分支）；`_r34_bootstrap` / `_r34_release` 追加 R37 装配 / 释放；末尾追加 R37 段（4 个新信号的**生产运行时订阅者** `flask_used → _player_hp` A57 原样写回 / `flask_rejected` / `player_died` / `player_respawned` 只读记录，`get_life_hp_view()` 只读 HP 视图，A54 唯一实例复用）。 |
| ③ | `godot/test/presentation.gd` | 修改（Rank-1 唯一写入） | 头部加 R37 rationale；新增 `KEY_G_CODE=71` 与 `R37_*` 演示节奏常量（全部标 `[PLACEHOLDER]` + rationale + 调参唯一入口）；`_drive_real_input` 末尾**只追加** ⑮ G 周期注入 / ⑯ 尾段更密 J / ⑰ 尾段更密 K / ⑱ 两次赐福 E。既有 R28/R34/R35/R36/R36B 常量数值、全部 `[PLACEHOLDER]` 数值、Q/J/K/R 注入节奏逐字不动，不回退演示驱动。 |
| ④ | `godot/scripts/render/verify_life_runtime_v140.gd` | 新增 | 本轮主回归（`extends SceneTree`，**不加载 `presentation.gd`**，A48③）。A~E 五组 26 条：装配 / A38 / A48① / A54 / 真实 G→瓶扣减·HP回复·瓶尽·满血·补瓶·幂等·异常输入 / 真实 Q 消耗 FP / HP 归零→死亡态→拒绝 G/Q/K/F→重复死亡→赐福重生回满 / 生产消费汇总。优先复用 Rank-2 真实服务，缺席才降级 FakeFlask / FakeDeath 契约替身。 |
| ⑤ | `godot/scripts/render/verify_production_chains_v110.gd` | 修改（扩展，既有 66 条不删不放宽） | 追加 R37 组 9 条（4 信号 / A48① 生产订阅者 / A54 三方同一实例 ×2 / 真实节点 / 真实 G 生产链 / 元素瓶包围盒避让 / 赐福补瓶 / A38）。**66 → 75**。 |
| ⑥ | `godot/scripts/render/verify_hud_layout_v100.gd` | 修改（扩展，既有 44 条不删不放宽） | 追加 M 组 4 条（`ProdFlaskLabel` 真实节点 rect 与 FP 条 / 当前战技名 / 连击评价带 / 弹反预兆带 / 6 分区两两不相交 + 四档降级不出界不遮角色 + 与 `get_flask_rect()` 锚点一致）。**44 → 48**。 |
| ⑦ | `teamwork/Rank-1/DONE-R37.md` | 新增 | 本交付报告。 |
| ⑧ | `teamwork/Rank-1/r37_*.log`（19 份） | 新增 | 三段门禁 + 5 回归 + 450 帧演示逻辑帧真跑日志原文留档（授权目录内）。 |
| ⑨ | `teamwork/command_center/ai/1/outbox/cmd-20261112-184157-061-A1.json` | 新增 | 本轮回执（**teamwork/command_center/**，非工程根），写后经中枢归档（§10）。 |

**只读未改（硬约束）**：`wave_trial_director.gd`（Rank-2 所有）/ `flask_service.gd` `death_service.gd` `flask_config.gd` `death_config.gd` `flask_rules.tres` `death_rules.tres`（Rank-2 所有，本轮只读确认接口）/ `points_commit_orchestrator.gd` `project.godot`（Rank-3 所有）/ `hd2d_fx.gd` `impact_feedback.gd`（Rank-4 所有，只读）/ `courtyard.tscn`（A38 节点 41 / uv 2/1/1 / 节点名）/ 10 份既有 `.tres` / 素材 / 其它 Rank 产出。`verify_focus_runtime_v130.gd` / `verify_parry_runtime_v120.gd` 仅复跑不改。

---

## 2. 四块任务实现说明

### 2.1 任务① 元素瓶运行时侧（G 键）

**真实输入双接 + 唯一权威入口**（A46/R36B 口径）：`G`（物理键码 71）→ HUD `_unhandled_input → _process_r32_keys(G)` 与 ENC `_unhandled_input(G)` 双接，都转发到 `hud.request_flask_use(event)`；靠 `event.get_instance_id()` 幂等去重（ENC+HUD 双接同一 event 不重复扣瓶，V140 B5 实证）。ENC `_r37_is_g()` 只认 press（过滤 release/echo，沿用 R36B 修法）。

**A54 唯一实例 + 真实 Rank-2 服务**：HUD `request_flask_use()` 只读 ENC `get_life_hp_view()` 拿真实 `current_hp / max_hp`，调 A54 唯一 `flask_service.use_flask(current_hp, max_hp)`；Rank-2 `FlaskService` 判定 `no_config / invalid_input / full_hp / no_flask / duplicate` 五道门。成功 → 扣 1 瓶、返回 `hp_after`（封顶不超上限）→ HUD 发 `flask_used`（A57 **最终结算值**原样采信、不二次计算）→ ENC 生产订阅者把 `hp_after` 原样写回真实 `_player_hp`。失败 → 不扣瓶、发 `flask_rejected` + HUD「瓶数不足 / 生命已满 / 重复按键已忽略」提示。

**HUD 显示避让**：独立归一化锚点 `ANCHOR_FLASK = Rect2(0.01875, 0.74500, 0.27813, 0.04167)`（当前战技名 0.63000 之后、连击评价带 0.85556 之前，x 严格在中央角色保护区之左），真实节点 `ProdFlaskLabel` 按 `_scaled_rect()` 定位，`set_layout_viewport()` 联动；**不并入 `get_layout_rects()` 的 6 分区**（保护既有 A1「size()==6」）。V100HUD M2 实测 15 块文字/面板包围盒 `worst_overlap=0.0000 px²`、M3 四档降级全 `text_ov=0.00`、V140 A8 与 V110 R37-6 均 `worst_overlap=0.0000`。

**不改既有**：G 为新增输入分支，战技 Q / 弹反 K / 处决 F / 翻滚 / 轻·重攻击 / E 既有判定逐字不动；既有输出格式 / 帧数据 / 胜负结算分支不动。

### 2.2 任务② 死亡轮回运行时侧（状态表现 + 信号转发）

**HP 归零 → 死亡态**：ENC `_on_boss_move_landed` 扣血后追加**一行** `_r37_forward_hp_changed()`（只转发最终 HP，既有 `_finish(false)` 胜负结算逐字不动）；HUD `on_player_hp_changed(hp, max_hp)` 在 `hp<=0` 且未死亡时调 A54 唯一 `death_service.on_death(grace_points)`（Rank-2 真实接口，掉落点数只读 WorldState `grace.trial.points` 三段式 flag，绝不写回），读 `get_snapshot().is_dead / dropped_points` → HUD「你死了 · 掉落赐福点数 N（赐福 E 重生）」真实节点 `ProdDeathLabel` 可见 + 发 `player_died`。**Rank-1 不新增第二套胜负判定**（不订阅 / 不改 `_finish` / `encounter_finished`）。

**死亡期间拒绝 G/Q/K/F**：HUD `_process_r32_keys` 开头死亡门禁 + ENC `_unhandled_input` 开头死亡门禁（只对新增 G/Q/R 消费不转发），K/F 由 HUD 侧覆盖，E（赐福休息 → 重生）/ Tab / 数字键既有行为不动。V140 D2 实证：死亡态下真实 G/Q/K/F 输入 → 瓶数不变、无 `flask_used` / 无战技释放 / 无弹反 / 无处决。

**重复死亡不二次掉落**：HUD `_r37_set_death_state` 边沿触发（仅「未死→死」发 `player_died`），已死态再次 HP 归零不二次调 `on_death`、不二次发信号、不覆盖首轮掉落；Rank-2 `DeathService.on_death` 自身 `already_dead / drop_pending` 亦拒绝二次掉落。V140 D3 实证 `death_count` 不增。

**赐福重生**：真实 E → ENC 既有 `_grace_rest()`（HP 回满）→ `grace_rested` 广播 → HUD 生产订阅者 `_r37_on_grace_rested()` 调 `flask_service.on_grace_rest()` 补满瓶 + `death_service.on_grace_respawn()` 判定重生；Rank-2 `WaveTrialDirector` 订阅 `respawn_performed` 生产链路**自动复位 FP / 瓶 / 连击 / 弹反窗口**并回到当前波；HUD 清死亡态（隐藏 `ProdDeathLabel`）+ 发 `player_respawned`。V140 D4 实证重生后 `hp=100 / fp=100/100 / flask=3/3 / is_dead=false`。

**真跑发现并修复的真实 bug（非纸面设计）**：Rank-2 `WaveTrial._on_respawn_performed()` → `encounter.trial_grace_rest()` → 再次 `_grace_rest()` → `grace_rested` **二次广播**，嵌套回 HUD `_r37_on_grace_rested()`，导致 `player_respawned` 首轮发 2 次（V140 D4 首轮 FAIL `respawned_log=2`）。修法：HUD 加重入守卫 `_r37_resting` + 回调开头先清 `_r37_is_dead_state`，嵌套直接 return；复跑 D4 `respawned_log=1`、26/26 全绿。**未放宽任何断言**，如实登记并列待裁决项 §8.3（是否需在 Rank-2 侧收敛二次广播）。

### 2.3 任务③ 完善演示覆盖（R36 遗留 P0）

只追加真实 `Input.parse_input_event` 注入节奏（**绝不改既有 `[PLACEHOLDER]` 数值、绝不回退演示驱动**）：⑮ G 周期 45 帧（9 次真实 G）、⑯ 尾段更密 J（86 次）、⑰ 尾段更密 K（48 次）、⑱ 两次赐福 E（f=246/430，互相抵消兑换面板 toggle，f=225/f=449 既有只读回读值逐字不变）。

450 帧 headless 逻辑真跑（`--fixed-fps 30 --quit-after 450`，**不带 `--write-movie`、不算录屏 / 不启 GPU job**）：`PRESENTATION_LOGIC_EXIT=0`、时间线完成 `frame=450`、日志 996 行、`SCRIPT ERROR=0`。

- **元素瓶：已覆盖** —— `[R37][ENC] 元素瓶生产消费 | 瓶 3->2 HP 88->100` + `[R37][HUD] 真实 G → 元素瓶成功 | 瓶 3->2 HP 88->100 → flask_used 已发`。其余 8 次 G 被 `full_hp` 拒绝（ENC 既有赐福休息 + 首次元素瓶把 HP 回满，Boss 招式未再打空），不二次扣瓶，符合真实服务判定。
- **连击 D→A 递进 / S 级收束爆发**：尾段 J/K 密度已大幅提高（命中数 0→25），但 450 帧日志未出现显式 `评级 A/S` 结算，与 A67 目视 B 级 1.35 同口径，**未在录屏目视确认，不冒充**。
- **一次死亡与重生**：450 帧内玩家 HP 从未归零（`StatusLabel` 全程 100→120/120，Boss 招式未打空 + 赐福休息 2 次回满），日志无「你死了 / 死亡态 / 重生」。**如实登记「链路已接线但演示未覆盖」**（任务③明确许可），真实可达由 V140 D 组承担（不加载 `presentation.gd`）。

### 2.4 任务④ 真实可达回归

- **V140（新主回归）**：`extends SceneTree`，`Engine.get_main_loop() as SceneTree` 取 root、显式 `call("_ready")` / `_r34_bootstrap()`、`CACHE_MODE_IGNORE`、connect 前 `get_signal_connection_list()` 去重 + `_finish()` disconnect 释放；**不加载 `presentation.gd`**（A3 运行时树零 presentation 节点）、**不在验证脚本内模拟编排**。真实 G/E 输入 → 生产 HUD/ENC 接线 → **Rank-2 真实 FlaskService / DeathService**（`flask_source=rank2_production_unique_instance death_source=rank2_production_unique_instance`，非契约替身）→ ENC 生产消费（`_player_hp` 真实写回）→ `ProdFlaskLabel / ProdDeathLabel` 真实可见节点文本（画面）。26/26。
- **V110**：追加 R37 组 9 条，既有 66 条不删不放宽 → 75/75。
- **V100HUD**：追加 M 组 4 条（元素瓶文字包围盒四档降级避让），既有 44 条不删不放宽 → 48/48。
- 两个既有脚本（V130 / V120P）**只读复跑**，39/39、31/31 全 `RESULT=ALL_MATCH`。

---

## 3. 键位表（改前 → 改后）

| 物理键（keycode） | 改前（R36B / v0.13.1） | 改后（R37 / v0.14.0） | 备注 |
|---|---|---|---|
| `J` (74) | `light_attack` 轻攻击 | **不变** | 演示密度增强 |
| `Space` (32) | `roll` 翻滚 | **不变** | — |
| `K` (75) | 精准弹反 | **不变**（死亡态被门禁拒绝） | — |
| `F` (70) | 处决 | **不变**（死亡态被门禁拒绝） | — |
| `Q` (81) | 战技（释放当前选中） | **不变**（死亡态被门禁拒绝） | — |
| `R` (82) | 战技切换 | **不变**（死亡态被门禁拒绝） | — |
| `E` (69) | `interact`（赐福休息 / 兑换） | **不变**，新增「死亡态下赐福休息 → 重生」生产订阅表现 | ENC 既有 `_grace_rest()` |
| **`G` (71)** | **【无绑定 / 空闲】** | **【新增】元素瓶使用 → `request_flask_use()` → A54 唯一 FlaskService.use_flask** | HUD + ENC 双接，event 实例幂等去重 |

**冲突核验**：`G=71` 与既有 `J=74 / Space=32 / K=75 / F=70 / Q=81 / R=82 / E=69 / 1=49 / 2=50 / 3=51 / Tab=4194306` 全部不同；两文件按 `physical_keycode / keycode` 精确匹配分支，无 InputMap action `"G"` 占用；V140 D2 实证「死亡期间按 G/Q/K/F 不扣瓶 / 不释放战技 / 不弹反 / 不处决」。

---

## 4. 真跑输出原文

命令前缀统一 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；日志留档 `teamwork/Rank-1/r37_*.log`。

### 4.1 三段门禁 EXIT（原文）

```
G1_IMPORT_EXIT=0
G2A_hud_EXIT=0                              G2A_encounter_director_EXIT=0
G2A_presentation_EXIT=0                     G2A_verify_life_runtime_v140_EXIT=0
G2A_verify_focus_runtime_v130_EXIT=0        G2A_verify_hud_layout_v100_EXIT=0
G2A_verify_production_chains_v110_EXIT=0    G2A_verify_parry_runtime_v120_EXIT=0
G2B_verify_life_runtime_v140_EXIT=0  [V140] RESULT=ALL_MATCH
G2B_verify_focus_runtime_v130_EXIT=0 [V130] RESULT=ALL_MATCH
G2B_verify_hud_layout_v100_EXIT=0    [V100HUD] RESULT=ALL_MATCH
G2B_verify_production_chains_v110_EXIT=0 [V110] RESULT=ALL_MATCH
G2B_verify_parry_runtime_v120_EXIT=0 [V120P] RESULT=ALL_MATCH
G3_QUIT_EXIT=0
PRESENTATION_LOGIC_EXIT=0（450 帧 headless 逻辑帧真跑，日志 996 行，时间线完成 frame=450）
```

### 4.2 全工程 `SCRIPT ERROR` / `PARSE ERROR` grep（19 段日志，原文）

```
LOG_COUNT=19
FINAL SCRIPT_ERROR_LINES=0  PARSE_ERROR_LINES=0
```
> 逐日志均为 `SCRIPT_ERROR=0 PARSE_ERROR=0`（`r37_g1_import` / 8 份 `r37_g2a_*` / 5 份 `r37_g2b_*` / `r37_g3_quit` / `r37_presentation_logic` / `r37_v140.run` / 2 份单独回归 run）。
> 一处如实登记：V140 B7 断言描述初版含字面词「不 SCRIPT ERROR」被 print 进日志污染 grep（非引擎脚本错误），已改为「不崩 / 无解析错误」并刷新两份 V140 日志复跑，最终口径 `SCRIPT_ERROR=0` 干净达标，未放宽任何断言。
> 既有 WARNING / ERROR 如实登记（非本轮引入、非 `SCRIPT ERROR`、不影响 `EXIT=0`）：`--script` 工具模式 `SaveSystem` 跳过自动读回、`ChunkManager` 未找到 ChunkRoot、`PointsCommitOrchestrator` autoload 降级、`2 ObjectDB instances were leaked at exit` 等，与 DONE-R36B §5.6 尾注同口径。

### 4.3 五个回归 SUMMARY / RESULT（原文）

```
[V140] SUMMARY pass=26 fail=0 total=26 ok=true flask_source=rank2_production_unique_instance death_source=rank2_production_unique_instance
[V140] RESULT=ALL_MATCH
[V130] SUMMARY pass=39 fail=0 total=39 ok=true focus_source=rank2_production_unique_instance
[V130] RESULT=ALL_MATCH
[V100HUD] SUMMARY pass=48 fail=0 total=48 ok=true
[V100HUD] RESULT=ALL_MATCH
[V110] SUMMARY pass=75 fail=0 total=75 ok=true
[V110] RESULT=ALL_MATCH
[V120P] SUMMARY pass=31 fail=0 total=31 ok=true parry_source=rank2_production_unique_instance
[V120P] RESULT=ALL_MATCH
```
**PASS/FAIL 汇总**：`26 + 39 + 48 + 75 + 31 = 219 PASS / 0 FAIL`，五份 `RESULT=ALL_MATCH`。V110 既有 66 条、V100HUD 既有 44 条逐条保留、未删未放宽。

### 4.4 V140 关键断言逐条原文（新增）

```
[V140] A2 A38 courtyard.tscn 节点数 == 41 PASS=true | count=41 expected=41
[V140] A3 A48③ 不加载 presentation.gd（运行时树零 presentation 节点） PASS=true | presentation_in_tree=false
[V140] A5 A48① ★ HUD 4 个新信号各有生产运行时订阅者 EncounterDirector PASS=true | signals_with_enc_subscriber=4/4
[V140] A6 A54 ★ HUD / ENC 的 flask_service + death_service 各同一真实 Object PASS=true | flask_same=true death_same=true flask_source=rank2_production_unique_instance death_source=rank2_production_unique_instance
[V140] A8 元素瓶文字包围盒不与 6 分区 / 赐福成长标题 / 连击带 / 弹反带 / FP 条 / 战技名相交 PASS=true | flask_rect=[P: (24.0, 536.4), S: (356.0064, 30.00238)] blocks=11 worst_overlap=0.0000 px²
[V140] B1 ★ A48③ 真实 G → 瓶数扣减（3→2）+ HP 回复（60→100）+ flask_used 广播 + ENC 生产消费真实写回 _player_hp（A57） PASS=true | flask 3->2 hp 60->100 used 0->1 writeback 0->1 enc_flask_events=1
[V140] B2 真实 G 后 HUD 真实节点 ProdFlaskLabel 文本显示「元素瓶 2/3」（画面同步） PASS=true
[V140] B5 重复按键幂等：HUD+ENC 双接同一真实 G event 实例只扣 1 瓶 PASS=true | flask 2 -> 1（期望 -1）
[V140] B4 瓶尽拒绝：flask==0 时真实 G 不扣瓶 + flask_rejected（瓶数不足 / no_flask） PASS=true | flask=0 after=0 reject=no_flask hint=[瓶数不足]
[V140] B6 赐福休息补满瓶：真实 E → grace_rested 生产订阅 → flask 0→max PASS=true | flask 0 -> 3 (max=3)
[V140] B3 满血拒绝：HP 已满时真实 G 不扣瓶 + flask_rejected（生命已满） PASS=true | reject=full_hp hint=[生命已满]
[V140] B7 异常输入拒绝：HP<0 时真实 G 不扣瓶（服务 invalid_input_policy，不崩 / 无解析错误） PASS=true
[V140] C1 真实 Q 消耗 FP 建立非满基线 PASS=true | fp 100 -> 88 (max=100)
[V140] D1 HP 归零 → 死亡态 +「你死了 / 掉落赐福点数」+ player_died 广播 PASS=true | hud_dead=true death_service_dead=true dropped=0 death_text=[你死了 · 掉落赐福点数 0]
[V140] D2 ★ 死亡期间拒绝 G/Q/K/F PASS=true | flask=3 used=3 focus=1 parry=0 exec=0
[V140] D3 重复死亡不二次掉落 PASS=true | died_log=1 dropped=0 death_count=1
[V140] D4 ★ 重生后 HP/FP/瓶回满 + 死亡态清除 + player_respawned 广播 PASS=true | hp=100 fp=100/100 flask=3/3 is_dead=false respawned_log=1
[V140] E1 A48③ ★ 真实输入 → 生产链路 → 画面：ENC 生产消费记录非空 PASS=true | flask_events=3 death_events=1 respawn_events=1 hp_writeback=3
```

### 4.5 V100HUD M 组 + V110 R37 组（新增）

```
[V100HUD] M2 ★ HUD 元素瓶文字包围盒不与 FP 条 / 当前战技名 / 连击评价带 / 弹反预兆带 / 其它文字相交 PASS=true | blocks=15 worst_overlap=0.0000 px²
[V100HUD] M3 1280x720 + 三档降级：元素瓶节点不出界 / 不遮中央角色 / 不与任一文字包围盒相交 PASS=true | 四档 text_ov=0.00
[V100HUD] M4 元素瓶真实节点 rect 与独立分区锚点 get_flask_rect() 一致 PASS=true
[V110] R37-2 A48① ★ 4 个新信号各有生产运行时订阅者 EncounterDirector PASS=true | signals_with_enc_subscriber=4/4
[V110] R37-3 A54 ★ HUD / ENC / wave.get_flask_service() 三方同一真实 Object PASS=true
[V110] R37-5 ★ A48③ 真实 G 输入 → 瓶扣减 + ENC 生产订阅者真实消费 + hp 写回 PASS=true
[V110] R37-6 ★ 元素瓶文字包围盒不与 FP 条 / 当前战技名 / 连击评价带 / 6 分区相交 PASS=true | worst_overlap=0.0000 px²
```

### 4.6 G3 主场景实证 / A38 静态 / 既有 .tres md5（原文）

```
===== G3 主场景实证 =====
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41
[R37][WaveTrial] 元素瓶生产订阅者已装配：FlaskService 唯一实例 + 3 信号 connect（A48①/A54）
[R37][WaveTrial] 死亡轮回生产订阅者已装配：DeathService 唯一实例 + 4 信号 connect（A48①/A54）
[R37][HUD] 生产装配 | flask_unique=true death_unique=true grace_subscribed=true（A48①/A54，不自建第二实例）
[R37][ENC] 生产装配 | flask_unique=true death_unique=true flask_signal_subscribed=true（A48① 生产运行时订阅者）
===== A38 静态只读核对 =====
node_count=41  uv1_scale Vector3(2,2,1) ×1 + Vector3(1,1,1) ×2（2/1/1 口径，V110 A38-2 / V130 F7 / V120P P5 全 PASS）
===== 既有 .tres md5（与 DONE-R36B 记录逐字一致）=====
wave_trial.tres 793b6daa7c7730feed1a3f849701d58a   boon_draft.tres 44d8b941f8b28dfa2931984707b5c53e
trial_modifiers.tres 7e9e5ac7d35d8d15171e69975ac3356d   stagger_rules.tres 49ce964e7c268804efbf2f20bec6565d
combo_rules.tres a1ad4635ae0342c696fe650eb13d4930   player_actions.tres 75390f71c002ef3cea6392a397ec267c
boss_01_margit.tres f2f71c7019c64e6c631c553887376c7d   enemy_01_limgrave_soldier.tres 9de25e0229d1c2c55a1740d2f838ad79
parry_rules.tres 5d560e57c5c0fdfdec3f20b3f3535728   focus_rules.tres 289fd4f08424658d9625fd3ac3d93bfd
```

---

## 5. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 元素瓶 G：`hud.gd` / `encounter_director.gd` 真实 `_unhandled_input(G)`，A54 唯一 FlaskService 判定，成功扣瓶回 HP（A57 原样写回）、失败「瓶数不足 / 生命已满」不扣瓶；HUD `ProdFlaskLabel` 独立分区真实节点（包围盒避让）。② 死亡轮回：HP 归零 → 死亡态「你死了 · 掉落赐福点数」→ 赐福重生回满 HP/FP/瓶、重置连击与窗口、回当前波；死亡/重生由 Rank-2 DeathService 判定，Rank-1 只做状态表现与信号转发，不新增第二套胜负判定；死亡期间拒绝 G/Q/K/F、重复死亡不二次掉落。③ 演示只追加真实注入节奏、既有数值/节奏逐字不动、不回退演示驱动；450 帧逻辑真跑元素瓶成功 1 次。④ V140 26/26、V110 66→75、V100HUD 44→48、V130 39/39、V120P 31/31，219 PASS / 0 FAIL 五份全 `RESULT=ALL_MATCH`，既有断言不删不放宽。⑤ 三段门禁全 `EXIT=0`、全工程 `SCRIPT ERROR=0 / PARSE_ERROR=0`。⑥ A38 节点 41 / uv 2/1/1 不变；10 份既有 `.tres` md5 与 DONE-R36B 逐字一致。⑦ A48 四项逐条达标（§7）。⑧ 只写授权文件、其余只读。⑨ 回执写入并确认中枢归档（§10）。 |
| **失败 / 未达** | ① **死亡与重生演示未覆盖**：450 帧内 HP 未归零，链路已接线（V140 D 组真实可达）但演示未覆盖，如实登记「链路已接线但演示未覆盖」，不冒充（任务③明确许可）。② **连击 D→A→S / S 级收束爆发**未在录屏目视确认（沿用 A67 目视 B 级 1.35 口径）。③ **本交付不含新录屏 / 目视帧**：按公共契约由总指挥定稿录屏亲自重跑并目视；逻辑真跑只证明生产链路触发，不冒称画面目视通过。④ **HD-2D 全绿未达**（沿用 A41/A52/A61/A68）：仍是 2D `_draw()` / screen-reading shader 近似、2D tile 地面、billboard 精灵，无真 DoF / 真体积光 / SSR / Forward+。 |
| **需用户确认 / 待裁决** | 见 §8。 |

---

## 6. 演示覆盖情况（如实登记）

| 机制 | 450 帧逻辑真跑 | 结论 |
|---|---|---|
| 元素瓶使用 | G 注入 9 次 → **成功 1 次**（瓶 3→2，HP 88→100）+ 8 次 `full_hp` 拒绝 | **已覆盖**（真实生产链日志留证） |
| 赐福休息补满瓶 | E 注入 2 次（f=246/430）+ 既有 f=20，`flask_restored` / 拒绝日志 flask=3 | 已接线、链路真实 |
| 连击 D→A 递进 / S 级收束爆发 | 尾段 J 86 次 + K 48 次，命中 0→25，无显式 `评级 A/S` | **未覆盖**（待总指挥定稿录屏目视，不冒充） |
| 一次死亡与重生 | HP 全程 100→120/120 未归零，无「你死了 / 重生」日志 | **链路已接线但演示未覆盖**（V140 D 组真实可达） |

> 说明：G 成功 1 次后被 `full_hp` 拒绝，是 ENC 既有赐福休息回满 HP + Rank-2 FlaskService `full_hp` 门共同作用的**真实判定结果**；未改任何 `[PLACEHOLDER]` 数值去强行制造瓶尽 / 死亡，避免伪造演示（硬约束「不冒充」）。

---

## 7. A48 四项逐条自查（硬要求）

| # | A48 条款 | 逐条自查结论 | 实证 |
|---|---|---|---|
| ① | 新信号必须有**生产运行时订阅者** | **达标**。HUD 新增 4 信号 `flask_used / flask_rejected / player_died / player_respawned` 的生产订阅者 = **EncounterDirector**（`_r37_bootstrap` connect，4/4 去重 + `_r37_release` 释放）：`flask_used` 回调把 `hp_after` 原样写回真实 `_player_hp`（A57），其余 3 个做只读生产消费记录。Rank-2 FlaskService 3 信号 / DeathService 4 信号由 **WaveTrialDirector** 生产订阅。均非验证脚本订阅。 | V140 A5 `4/4`、V110 R37-2 `4/4`、G3 `[R37][ENC] flask_signal_subscribed=true` / `[R37][WaveTrial] 3 信号 + 4 信号 connect` |
| ② | 遵守 A54 唯一实例 | **达标**。HUD / ENC / wave 三方同一真实 Object（`get_flask_service()` / `get_death_service()` 从 wave 复用，绝不自建第二个）；本轮 Rank-2 服务真实落盘，V140 `flask_source=rank2_production_unique_instance / death_source=rank2_production_unique_instance`（**非契约替身**）。V140 内 `FakeFlask / FakeDeath` 仅作 Rank-2 缺席时的降级预留，真跑未启用。 | V140 A6/E3、V110 R37-3/R37-3b、G3 `flask_unique=true death_unique=true` |
| ③ | 不加载 `presentation.gd`、不在验证脚本内模拟编排的真实可达回归 | **达标**。V140 不加载 `presentation.gd`（A3 运行时树零 presentation 节点）、不模拟编排：真实 `Input.parse_input_event` G/E → 生产 HUD/ENC `_unhandled_input / R32` 键路径 → **Rank-2 真实 FlaskService.use_flask / DeathService.on_death / on_grace_respawn** → ENC 生产订阅者 `_player_hp` 真实写回 → `ProdFlaskLabel / ProdDeathLabel` 真实可见节点文本变化（画面）。V100HUD M 组读真实节点 `get_global_rect()` 做几何断言。 | V140 A3/B1/B2/B4/D1/D1b/D4/E1、演示 450 帧元素瓶成功日志 |
| ④ | 纯逻辑 + 单元断言不算可玩交付 | **达标**。交付含真实可见节点（元素瓶 / 死亡态）、真实 `G/E` 输入、生产运行时订阅链、真实 Boss/HP 结算、450 帧演示逻辑真跑（元素瓶成功 1 次 / 25 次命中）、三段门禁 + 5 回归真跑；`presentation.gd` 演示驱动仅作注入机会，真实可达由 V140 承担。 | §4 全部门禁 / 回归 / 演示输出 |

**SceneTree / `--script` 纪律**：V140 / V110 / V100HUD 用 `Engine.get_main_loop() as SceneTree` 取 root（不用 `get_tree()` / 不用 `/root/...` 绝对路径）、`add_child` 后显式 `call("_ready")` / `_r34_bootstrap()`、资源 `CACHE_MODE_IGNORE`、connect 前 `get_signal_connection_list` 去重 + `_finish()` disconnect 释放；`project.godot` 既有 `PointsCommitOrchestrator` autoload 直接复用、不重复挂载。

---

## 8. 未完成项 / 待总指挥裁决项（如实登记，不擅改）

**未完成项**
1. **定稿录屏 / 目视帧**：按公共契约由总指挥本轮亲自重跑并目视；本轮不含新 MP4 / 抽帧 / 目视结论。元素瓶 HUD /「你死了」文字实机观感待目视确认。
2. **死亡与重生演示覆盖**：450 帧内 HP 未归零，「链路已接线但演示未覆盖」（V140 D 组真实可达）。是否需延长序列 / 提高 Boss 伤害 `[PLACEHOLDER]` / 专门演示段，请裁决（本轮未擅改任何数值）。
3. **连击 D→A→S / S 级收束爆发**：逻辑真跑尾段密度已提高但未显式结算到 A/S，实机可见性待目视。
4. **HD-2D 全绿**：差距清单（真 DoF / 真 `volumetric_fog` / SSR / `Environment.glow` / Forward+ 后端）沿用 R35B/R35C/R36 保持未达。
5. **`[PLACEHOLDER]` 试玩校准**：`ANCHOR_FLASK / ANCHOR_DEATH` 锚点（hud.gd 常量表）、`R37_*` 演示节奏（presentation.gd R37 常量段）、`R37_HINT_SHOW_SEC` 提示时长待试玩校准；`flask_rules.tres` / `death_rules.tres` 数值归 Rank-2，本轮只读。

**待裁决项**
1. **掉落赐福点数来源**：HUD `on_death(grace_points)` 的实参取自 WorldState 只读 flag `grace.trial.points`（三段式，绝不写回）；验证进程该 flag 为 0 → `dropped=0`，HUD 显示「掉落赐福点数 0」。若 Rank-2 期望传「当前波累计点数」或由 `reclaim_dropped()` 统一入账基数，请裁决来源与归属（接口异议）。
2. **`reclaim_dropped()` 触发点 / `points_reclaimed` 一次入账**：当前 HUD 重生调 `on_grace_respawn()`，Rank-2 wave 订阅 `respawn_performed` 复位各服务；日志未见 `points_reclaimed` 触发。一次性回收与 `points_awarded` 一次入账（A55/A57）的触发链归属（Rank-1 / Rank-2 / Rank-3）请裁决，本轮不擅自新增入账。
3. **Rank-2 二次广播收敛**：`WaveTrial._on_respawn_performed() → encounter.trial_grace_rest() → _grace_rest() → grace_rested` 二次广播导致 HUD 重入，本轮已在 HUD 加 `_r37_resting` 重入守卫修复（真跑实证，未放宽断言）；是否需在 Rank-2 侧收敛该二次广播，请复核。
4. **重复按键幂等双机制**：Rank-2 FlaskService 自带「相邻同签名 `duplicate`」门 + Rank-1 event 实例幂等去重是两层独立机制；演示里 HP 一直满导致 8 次 `full_hp` 拒绝。是否需短冷却窗口 / 表字段（Rank-2 已列其 DONE 待裁决），请裁决。
5. **键位 / UI 形态**：G 键位最终实机手感、「元素瓶 N/M」常驻文本 Label /「你死了」中央上方节点位置、是否需瓶图标 / 死亡遮罩 / 重生特效（Rank-4），请裁决归属与避让断言同步。
6. **信号命名口径**：HUD 新增 `flask_used / flask_rejected / player_died / player_respawned` 与 Rank-2 FlaskService `flask_used / flask_rejected / flask_restored`、DeathService `death_occurred / respawn_performed / points_reclaimed / action_rejected` 分属不同对象、签名不同（HUD 4 参 vs 服务 5 参），是否需统一命名 / 合并，请裁决。
7. **A38 §3.3 契约同步 / HD-2D 全绿路线 / `128bit` 歧义 / 真机 exe·apk 手感与移动端触控 / GitHub 补推**：沿用前序未完成项。

---

## 9. 硬约束遵守声明

- **唯一写入方**：只写 `hud.gd` / `encounter_director.gd` / `presentation.gd` / `verify_life_runtime_v140.gd` / `verify_production_chains_v110.gd` / `verify_hud_layout_v100.gd` / `teamwork/Rank-1/`（DONE + 19 份日志）/ 回执。**未改** `wave_trial_director.gd` / 全部 Rank-2 服务与 `.tres` / `points_commit_orchestrator.gd` / `project.godot` / `hd2d_fx.gd` / `impact_feedback.gd` / `courtyard.tscn`（A38 节点 41 / uv 2/1/1）/ 10 份既有 `.tres` / 素材 / 其它 Rank 产出；`verify_focus_runtime_v130.gd` / `verify_parry_runtime_v120.gd` 仅复跑未改。
- **不改既有 `[PLACEHOLDER]` 数值 / 输出格式**：`presentation.gd` 既有 R28/R34/R35/R36/R36B 常量数值与 Q/J/K/R 注入节奏逐字不动；`hud.gd` 既有 12 信号 / 14 个 `get_focus_hud_view` key / 四套 HUD / 6 分区布局逐字不动；ENC 既有 roll/light/heavy/interact/Q/R 判定、`_on_boss_move_landed` 既有结算、`_finish` 胜负结算分支逐字不动（只追加一行 HP 转发）；既有 `.tres` md5 逐字一致。
- **零付费、零外部依赖、不启 GPU job**：仅本地 Godot 4.7.2；未 `--write-movie` 录屏 / 未调 ffmpeg / 未列任何付费项。
- **默认不刺探**：未主动扫目录做进度巡检、未新建只读探针 / 巡检脚本；所有读取均针对任务单指定契约 / 目标文件 / Rank-2 只读接口确认 / 门禁日志 / 归档确认所必需路径，用真跑输出判断进度。
- **不伪造产物、不谎报成功**：19 段门禁日志非空、5 回归数字 / SCRIPT ERROR 数字 / 元素瓶与死亡实证 / 演示统计均为真跑输出原文；V140 首轮 10 条 FAIL（字段名 / 真实接口不匹配）与 D4 二次广播 bug 均如实登记并修复复跑；未冒称死亡重生演示覆盖、未冒称连击 D→A→S / S 级录屏覆盖、未冒称目视通过、未冒称 HD-2D 全绿。
- **不自行 git**（总指挥收尾）；**未删除 `.workbuddy` 目录**。

---

## 10. 回执与中枢归档确认（写后实测，如实登记）

- 回执写入授权路径（**`teamwork/command_center/`**，非工程根）：`teamwork/command_center/ai/1/outbox/cmd-20261112-184157-061-A1.json`，四字段 `{"task_id":"cmd-20261112-184157-061-A1","ai":1,"status":"done","result":"…引用 DONE-R37.md 实际结论…"}`。
- **中枢归档回读确认（写后实测，如实登记）**：
  - `ai/1/outbox/` 已清空（回执被中枢移走 → `dispatcher/receipts/`，属中枢正常处理）：`outbox_count=0`。
  - 归档副本 `teamwork/command_center/dispatcher/receipts/cmd-20261112-184157-061-A1.json` 存在（**1864 字节**），回读 **VALID_JSON**，四字段齐全：`keys=['ai','result','status','task_id']` / `task_id=cmd-20261112-184157-061-A1` / `ai=1` / `status=done` / `result_len=1014`。
  - `ai/1/status.json`：`{"ai":1,"state":"idle","current_task":"","completed":68,"last_seen":"2026-11-12 19:28:18"}`（`completed` 67→68、`current_task` 清空、state working→idle）。
  - `dispatcher/dispatcher.log` 尾部原文：`[2026-11-12 19:28:18] ← 1 号 AI 回执 <cmd-20261112-184157-061-A1> 完成：R37/v0.14.0 四块任务全部真跑完成，实际结论见 teamwork/Rank-1/DONE-R37.md：① h…`，确认 id 与派单一致、中枢已回收验证 `done`。
  - `dispatcher/ledger.jsonl` 本任务行回读 **VALID_JSON**：`id=cmd-20261112-184157-061-A1 / command=cmd-20261112-184157-061 / ai=1 / status=done / issued_at=2026-11-12 18:41:57 / finished_at=2026-11-12 19:28:18 / result_len=1014`（与回执 result 逐字一致）。
