# DONE-R32.md · R32 / v0.10.0「赐福抉择 · 韧性处决」交付报告（Rank-2）

> 轮次：`R32 / v0.10.0` ｜ 任务单 id：`cmd-20261112-074023-393-A2` ｜ 执行 AI：`2（Rank-2 战斗系统与数据驱动）`
> 真源：`teamwork/Rank-2/调度任务单-latest.json`（`task` 全文）+ `teamwork/00-协作契约.md`
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable）
> 结论：**三段门禁全绿、`SCRIPT ERROR=0`、三份自测 `RESULT=ALL_MATCH`、既有 `.tres` md5 零改动**。

---

## 1. 交付清单（实际落地文件，全部归 Rank-2）

### 机制 A · 战后赐福抉择 Boon Draft（新增 3 件）

| 文件 | 类型 | 作用 |
|---|---|---|
| `godot/data/rpg/boon_draft.tres` | 新增数据表 | 三选一候选（3 项 `Array[Dictionary]`，8 字段齐全），数值首版 `[PLACEHOLDER]` |
| `godot/scripts/combat/boon_draft_config.gd` | 新增 Resource（`class_name BoonDraftConfig`） | 结构 / 8 字段白名单 / 合法性纯函数 / 降级基线 / 逐项 rationale / 调参唯一入口 |
| `godot/scripts/combat/boon_draft_service.gd` | 新增 RefCounted（`class_name BoonDraftService`） | `select()/apply()/settle()` 纯逻辑 |

### 机制 B · Boss 韧性处决（新增 3 件）

| 文件 | 类型 | 作用 |
|---|---|---|
| `godot/data/combat/stagger_rules.tres` | 新增规则表 | 4 个 `[PLACEHOLDER]` 标量参数 |
| `godot/scripts/combat/stagger_config.gd` | 新增 Resource（`class_name StaggerConfig`） | 标量结构 / `is_valid()` / 降级基线 / 逐项 rationale |
| `godot/scripts/combat/stagger_service.gd` | 新增 RefCounted（`class_name StaggerService`） | 削韧 / 开窗 / 处决 / 超时 / Boss 死亡 纯逻辑 + **3 个公开信号** |

### 自测脚本（新增 3 件，均在 `godot/scripts/combat/`）

| 文件 | 作用 | 结果 |
|---|---|---|
| `verify_boon_draft_v100.gd` | 机制 A 正常/边界/异常自测 | `pass=97 fail=0 RESULT=ALL_MATCH` |
| `verify_stagger_v100.gd` | 机制 B 正常/边界/异常 + 信号订阅自测 | `pass=62 fail=0 RESULT=ALL_MATCH` |
| `verify_trial_modifier_runtime_v090b.gd` | R31B 遗留：真表回读结算 + md5 零改动证明 | `pass=41 fail=0 RESULT=ALL_MATCH` |

### 文档（新增 2 件）

| 文件 | 作用 |
|---|---|
| `teamwork/Rank-2/R31B-INTEGRATION.md` | R31B 接线清单 / broken 判据 / 待裁决项 |
| `teamwork/Rank-2/DONE-R31B.md` | R31B 遗留补齐简述（另份 DONE） |

### 只读未改（硬约束）

`godot/scripts/combat/encounter_director.gd`（唯一写入方 Rank-1 / A44）、`hud.gd`、
`impact_feedback.gd`、`courtyard.tscn`、`presentation.gd`、场景 / 素材 / 其它 Rank 文件、
既有 `trial_modifiers.tres` / `wave_trial.tres`（数值零改动）、`00-协作契约.md`（不私改）。

---

## 2. 玩法拆解表（需求 → 机制 → 数值 → 状态 → 验收）

### 机制 A · 赐福抉择

| 需求 | 机制 | 数值（`[PLACEHOLDER]` 首版） | 状态 | 验收 |
|---|---|---|---|---|
| 每波清波后给一次「有代价的成长」 | 三选一，增益与代价成对生效 | ① 生机涌流 `hp_restore=40.0` / `hp_scale=1.15` ② 破势锋芒 `poise_damage_bonus=0.25` / `telegraph_scale=0.85` ③ 恩典供奉 `points_bonus=60.0` / `hp_scale=1.20` | `_selected_index / _applied / _settled`（实例内、不持久化） | `verify_boon_draft_v100.gd` 97 断言 |
| 防单波资源双收 | `exclusive_group`：①③ 同 `recovery` 互斥，② `tempo` 独立 | — | 同组二次 `select` → `REASON_EXCLUSIVE` | `exclusive_same_group_rejected` |
| 防重复抉择 / 防通胀 | 三选一只成功一次；重复 `apply`/`settle` 拒绝 | 点数加成仅 `points_bonus` 候选生效 | `select/apply/settle` 幂等 | `duplicate_*` / `already_*` / `same_frame_*` |
| 点数余额非负 | `settle` 仅加成、`balance=max(0,total)`，负点数/null 拒绝 | `bonus=60` | `balance>=0` 恒真 | `invalid_*` / `balance=160` |

### 机制 B · 韧性处决

| 需求 | 机制 | 数值（`[PLACEHOLDER]` 首版） | 状态 | 验收 |
|---|---|---|---|---|
| Boss 破韧后给抢处决窗口 | 命中累积削韧，归零开窗 | `stagger_max=100.0`、`reference_poise_damage=25.0`（4 击开窗） | `_stagger / _window_open / _window_remaining` | `flow_zero_stagger_opens_window` |
| 窗口有时限 | `tick(delta)` 确定性倒计时，超时关窗恢复满韧性 | `window_duration_sec=3.0` | `remaining` 递减 → 0 关闭 | `bnd_over_duration_timeout` / `bnd_exact_duration_timeout` |
| 处决给额外点数 | 窗口内 `try_execute()` 给点、关窗、恢复韧性 | `execute_bonus_points=50` | `total_execute_bonus` 只增 | `flow_execute_ok` / `same_frame_execute_once` |
| 连续命中不叠加异常 | 窗口期命中幂等拒绝、不重复开窗 | — | `REASON_WINDOW_OPEN` | `stack_*` |
| Boss 死亡后不再开窗 | `on_boss_defeated()` 置标志、关窗 | — | `_boss_defeated` | `boss_defeated_*` |

### 数值拆解 / rationale 摘要（详见两个 config.gd 头注）

- **调参唯一入口（只改表不改代码）**：`godot/data/rpg/boon_draft.tres` 与
  `godot/data/combat/stagger_rules.tres`；代码里 `DEFAULT_*` 是非法降级基线（刻意 ≠ 表值，
  `verify_stagger_v100.gd` 的 `default_is_not_design_*` 机器判定），不是设计数值。
- 校准同步清单：`.tres` → 各 verify 的 `EXPECT_*` → 本 DONE 数值表 → 三段门禁；不静默改数。
- rationale 要点：回血换下一波敌人更肉（1.15）、削韧换前摇更短（0.85）、拿点换更肉
  （1.20 > 1.15，点数可跨波累积更值钱）；韧性 100 / 4 击破韧、窗口 3.0s 够反应不宽松、
  处决 +50 点约为单波奖励 1/3~1/2 不喧宾夺主。全部 `[PLACEHOLDER]`，待人工试玩校准。

---

## 3. 供 Rank-1 接线的公开方法与信号签名（本轮重点）

> `StaggerService` 是 `RefCounted` 纯逻辑，**信号是 Object 级能力**，Rank-1 直接
> `connect` 到本服务实例即可，无需场景树 / 无需 `/root/...`。以下签名**稳定、不再改动**。

### 3.1 公开信号（`godot/scripts/combat/stagger_service.gd`）

```
signal stagger_value_changed(current: float, maximum: float)
    # 韧性变化（含恢复）时发，供 HUD 韧性条
signal execution_window_opened(remaining_sec: float, bonus_points: int)
    # 韧性归零开窗时发；remaining_sec=窗口总时长，bonus_points=本次处决可给点数
signal execution_window_closed(reason: String)
    # 窗口关闭时发；reason 取下方 3 个常量之一，供 HUD 收起「可处决」提示
```

`execution_window_closed(reason)` 的 `reason` 取值（公开常量）：

```
StaggerService.CLOSE_EXECUTED      = "executed"        # 处决成功
StaggerService.CLOSE_TIMEOUT       = "timeout"         # 超时自动关闭
StaggerService.CLOSE_BOSS_DEFEATED = "boss_defeated"   # Boss 死亡强制关窗
```

### 3.2 公开方法（全静态类型）

```
_init(config: StaggerConfig = null)                 # 构造注入规则表，自动 reset()
set_config(config: StaggerConfig) -> void           # 替换表并 reset()
get_config() -> StaggerConfig
reset() -> void                                     # 恢复满韧性 / 关窗 / 清死亡标志（每次 Boss 战开始）

apply_hit(poise_damage: Variant) -> Dictionary       # 玩家命中：累积削韧，归零开窗
try_execute() -> Dictionary                           # F 键处决：窗口内给点、关窗、恢复韧性
tick(delta_sec: Variant) -> Dictionary                # 每帧推进窗口倒计时；超时自动关窗
on_boss_defeated() -> void                            # Boss 死亡：置标志、关窗、此后不再开窗

is_window_open() -> bool                            # HUD 是否显示「可处决」
get_window_remaining() -> float                     # 窗口剩余秒数（HUD 倒计时）
get_stagger() -> float / get_max_stagger() -> float # 韧性条当前 / 上限
is_boss_defeated() -> bool
get_total_execute_bonus() -> int                    # 累计处决额外点数（只增、>=0）
get_snapshot() -> Dictionary                        # 全状态快照（见下）
```

返回 Dictionary 字段（供 Rank-1 消费）：

```
apply_hit : {ok, reason, poise_damage, stagger, stagger_max,
             window_open, window_remaining, opened_now}
try_execute: {ok, reason, bonus_points, total_execute_bonus, window_open, stagger}
tick       : {ok, reason, delta_sec, window_open, window_remaining, timed_out}
get_snapshot: {stagger, stagger_max, window_open, window_remaining,
               window_duration_sec, execute_bonus_points, boss_defeated,
               total_execute_bonus}
```

`reason` 常量：`REASON_OK / REASON_NO_CONFIG / REASON_INVALID_HIT / REASON_INVALID_DELTA /
REASON_WINDOW_OPEN / REASON_BOSS_DEFEATED / REASON_NO_WINDOW`。

### 3.3 Rank-1 接线示意（伪代码，供 `encounter_director.gd` / HUD / F 键）

```gdscript
# 装配（规则表从 res://data/combat/stagger_rules.tres 读，CACHE_MODE_IGNORE 回读真值）
var stagger := StaggerService.new(
    ResourceLoader.load("res://data/combat/stagger_rules.tres", "",
                        ResourceLoader.CACHE_MODE_IGNORE) as StaggerConfig)
stagger.connect("stagger_value_changed",   Callable(self, "_on_stagger_changed"))   # HUD 韧性条
stagger.connect("execution_window_opened", Callable(self, "_on_window_opened"))     # 显示 F 处决 + 倒计时
stagger.connect("execution_window_closed", Callable(self, "_on_window_closed"))     # 收起提示

# 玩家命中 landed（Rank-1 本轮新增 player_hit_landed 信号 / emit 处）
func _on_player_hit_landed(poise_damage: float) -> void:
    stagger.apply_hit(poise_damage)   # 归零自动 emit execution_window_opened

# 每帧（确定性驱动，时间不由引擎时钟读取）
func _process(delta: float) -> void:
    if not stagger.is_boss_defeated():
        stagger.tick(delta)            # 超时自动 emit closed("timeout") 并恢复韧性

# F 键处决
func _on_execute_pressed() -> void:
    var r := stagger.try_execute()
    if r.ok:
        # bonus_points 交 Rank-3 点数结算层落盘（I-1），Rank-2 不写存档
        emit_signal("execute_bonus_earned", int(r["bonus_points"]))

# Boss 死亡
func _on_boss_defeated() -> void:
    stagger.on_boss_defeated()        # 此后 apply_hit 不再开窗
```

**接线注意**：① `tick(delta)` 必须每帧调用，否则窗口不会超时（纯逻辑不读真实时钟）；
② 窗口期内 `apply_hit` 幂等拒绝（`REASON_WINDOW_OPEN`），不会二次开窗；
③ 处决额外点数的落盘责任归 **Rank-3（I-1）**，Rank-2 只产出 `bonus_points`、绝不写
`user://` / `set_flag` / `commit`；④ `reset()` 在每次 Boss 战开始调用一次。

### 3.4 机制 A 接口（供导演层 / 结算层接线，非 HUD 订阅）

```
class_name BoonDraftService (RefCounted)
_init(config: BoonDraftConfig = null) / set_config(c) / get_config() / reset()
select(index: Variant) -> Dictionary      # 三选一；越界/null/重复/互斥拒绝
apply() -> Dictionary                     # 返回 {ok, id, effect_key, effect_value,
                                          #        cost_key, cost_value, exclusive_group, paired}
settle(base_points: Variant) -> Dictionary  # {ok, total_points, bonus_points, balance,
                                            #  effect_key, cost_key, cost_value, paired, ...}
has_selection() / is_applied() / is_settled() / get_selected_index() / get_snapshot()
```

> `apply()` 的 `cost_key / cost_value` 是**「下一波」乘性修正**（`hp_scale` >1 敌人更肉 /
> `telegraph_scale` <1 前摇更短），由导演层在下一波生成敌人时消费；`effect_key=hp_restore /
> poise_damage_bonus` 的运行时效果由各自消费方接线。本服务只产出成对数据、不写存档、
> 不碰渲染、不改下一波实例。`points_bonus` 由 `settle()` 计入点数。

---

## 4. 真跑输出原文（三段门禁，`SCRIPT ERROR=0`）

引擎：`Godot Engine v4.7.2.stable.official.ed1daf0bf`。命令前缀统一为
`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`

### GATE-1 `--headless --import`

```
[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
... [ DONE ] first_scan_filesystem
[   0% ] update_scripts_classes | BoonDraftConfig / BoonDraftService /
         EncounterDirector / StaggerConfig / StaggerService   （首次真跑注册）
[ DONE ] update_scripts_classes
[ DONE ] loading_editor_layout
GATE-1 EXIT=0
```

### GATE-2a `--check-only --script`（语法门禁，3 件）

```
check-only verify_boon_draft_v100 EXIT=0
check-only verify_stagger_v100 EXIT=0
check-only verify_trial_modifier_runtime_v090b EXIT=0
```

### GATE-2b `--headless --script <verify>`（实跑，全 `RESULT=ALL_MATCH`）

```
[V100-BD] === SELFTEST START ===
[V100-BD] scene_tree_root_via_main_loop PASS=true | Engine.get_main_loop() as SceneTree -> root
[V100-BD] table_load_cache_ignore PASS=true | path=res://data/rpg/boon_draft.tres
[V100-BD] effect_value[0] PASS=true | got=40.0 expect=40.0 [PLACEHOLDER]
[V100-BD] cost_value[2] PASS=true | got=1.2 expect=1.2 [PLACEHOLDER]
[V100-BD] exclusive_same_group_rejected PASS=true | 0(recovery) + 2(recovery) 互斥拒绝
[V100-BD] apply_paired_true PASS=true | paired=true（增益与代价成对）
[V100-BD] settle_points_bonus_total PASS=true | base=100 +60 -> total=160 / bonus=60 / balance=160
[V100-BD] invalid_negative_base_rejected PASS=true | base=-1 拒绝
[V100-BD] same_frame_settle_once PASS=true | 同帧 2 次 settle 只第 1 次生效
...（共 97 条逐条 PASS=true 原文，含正常/边界/异常三类）...
[V100-BD] SUMMARY pass=97 fail=0
[V100-BD] OVERALL=PASS
[V100-BD] RESULT=ALL_MATCH
run verify_boon_draft_v100 EXIT=0

[V100-ST] === SELFTEST START ===
[V100-ST] signal_execution_window_opened_exists PASS=true | signal execution_window_opened(remaining_sec: float, bonus_points: int)
[V100-ST] flow_zero_stagger_opens_window PASS=true | 4×25 削韧归零开窗，stagger=0 [PLACEHOLDER]
[V100-ST] signal_opened_payload PASS=true | payload remaining=3.0 bonus=50
[V100-ST] flow_execute_ok PASS=true | 处决成功 bonus=50 total=50 [PLACEHOLDER]
[V100-ST] bnd_over_duration_timeout PASS=true | delta=999 > 3.0 -> 超时关窗 + 恢复满韧性
[V100-ST] bnd_exact_duration_timeout PASS=true | delta=3.0（恰好窗口时长）-> 超时关窗
[V100-ST] stack_no_double_open PASS=true | execution_window_opened 仍只 1 次（不重复开窗）
[V100-ST] same_frame_execute_once PASS=true | 同帧 2 次处决只第 1 次给 50 点（不刷点）
[V100-ST] boss_defeated_no_window PASS=true | Boss 死亡后命中 -> 拒绝且不再开窗
...（共 62 条逐条 PASS=true 原文）...
[V100-ST] SUMMARY pass=62 fail=0
[V100-ST] OVERALL=PASS
[V100-ST] RESULT=ALL_MATCH
run verify_stagger_v100 EXIT=0

[V090B-TM] === SELFTEST START ===
[V090B-TM] md5_before_modifier_nonempty PASS=true | trial_modifiers.tres md5(before)=7e9e5ac7d35d8d15171e69975ac3356d
[V090B-TM] md5_before_wave_nonempty PASS=true | wave_trial.tres md5(before)=793b6daa7c7730feed1a3f849701d58a
[V090B-TM] settle_no_hit_150 PASS=true | no_hit 达成 -> total=150 mult=1.5 [PLACEHOLDER]
[V090B-TM] settle_time_pressure_130 PASS=true | total=130 mult=1.3 [PLACEHOLDER]
[V090B-TM] settle_low_vigor_140 PASS=true | total=140 mult=1.4 [PLACEHOLDER]
[V090B-TM] settle_max_not_multiply PASS=true | 两项达成取 max(1.5,1.3)=1.5 -> 150（非 195）
[V090B-TM] exclusive_same_group_rejected PASS=true | no_hit + low_vigor 同 survival 组拒绝
[V090B-TM] no_modifier_baseline PASS=true | 未选 -> 回落基础 100
[V090B-TM] balance_all_nonneg PASS=true | 全程 balance>=0 且 =total，bonus>=0
[V090B-TM] invalid_stats_null_rejected PASS=true | stats=null 拒绝
[V090B-TM] MD5 trial_modifiers.tres before=7e9e5ac7d35d8d15171e69975ac3356d after=7e9e5ac7d35d8d15171e69975ac3356d
[V090B-TM] MD5 wave_trial.tres    before=793b6daa7c7730feed1a3f849701d58a after=793b6daa7c7730feed1a3f849701d58a
[V090B-TM] md5_trial_modifiers_zero_change PASS=true | 既有 trial_modifiers.tres 前后 md5 一致（零改动）
[V090B-TM] md5_wave_trial_zero_change PASS=true | 既有 wave_trial.tres 前后 md5 一致（零改动）
[V090B-TM] SUMMARY pass=41 fail=0
[V090B-TM] OVERALL=PASS
[V090B-TM] RESULT=ALL_MATCH
run verify_trial_modifier_runtime_v090b EXIT=0
```

### GATE-3 `--headless --quit`（主场景实证）

```
[SaveSystem] 自动读回完成 | dungeon.wave_trial.best_wave=3 | grace.trial.points=450 | ...
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（A38 断言保持）
[WaveTrial] 增益运行时接线：checked=3 applied=1 degraded=0 reasons=[]
[Tutorial] 存档已完成（grace.tutorial.completed=true）→ 跳过教学，波次自动开始
...（既有 HUD / FX / CODEX / SHOP 装配日志，均既有行为）...
GATE-3 EXIT=0
```

### 统一统计（`grep SCRIPT ERROR=0`）

```
########## SUMMARY ##########
SCRIPT ERROR TOTAL = 0  (grep SCRIPT ERROR=0 期望)
ERROR(exact 'SCRIPT ERROR') lines:
(none)
GATE-1 EXIT=0 / 3×check-only EXIT=0 / 3×run EXIT=0 / GATE-3 EXIT=0
```

**PASS/FAIL 汇总**：`97 + 62 + 41 = 200 PASS / 0 FAIL`，三份 `RESULT=ALL_MATCH`，
`SCRIPT ERROR=0`。

> 如实登记（不冒充全绿、不谎报）：3 个 `--script` 段与 `--quit` 段尾部各有既有 autoload
> `WARNING`：`[SaveSystem] --script 工具模式…跳过自动读回（降级，不崩）`、
> `[ChunkManager] 未找到 ChunkRoot…`、`2 ObjectDB instances were leaked at exit`。
> 这些是**既有工程在 `--script / --headless` 工具模式下的既有告警**，非 `SCRIPT ERROR`、
> 非本轮引入、不影响断言与门禁（EXIT=0）。本轮未改这些文件（越界），如实登记。

---

## 5. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 机制 A/B 6 个新文件 + 3 个 verify + 2 份文档落地；② 三段门禁 GATE-1/2a/2b/3 全 EXIT=0；③ 三份自测 `RESULT=ALL_MATCH`（200 PASS / 0 FAIL）；④ `grep SCRIPT ERROR=0`；⑤ 既有 `trial_modifiers.tres` / `wave_trial.tres` md5 前后一致（零改动）；⑥ `courtyard.tscn` 零改动，GATE-3 实证 `node_count=41`（uv `2/1/1` 因零改动保持）；⑦ 纯逻辑边界（I-1 不读写存档 / 不碰渲染 / 不写生产 `delta.json`）由代码与自测双重保证 |
| **失败** | 无 |
| **需用户确认** | ① 全部 `[PLACEHOLDER]` 数值待人工试玩校准（调参只改表）；② 运行时接线（Rank-1 订阅 3 个信号 / F 键 / HUD、导演层消费 `apply_hit` / `tick` / `cost_key`）由 Rank-1 本轮并行完成，Rank-2 未改 `encounter_director.gd`；③ 处决额外点数 / boon 点数的落盘由 Rank-3（I-1）接线；④ 本轮纯逻辑 + 数据表 + headless 真跑，未做 15~20 秒实机录屏回看（无画面可录），按公共契约如实登记为后续动作；⑤ 既有 autoload 的 3 条 WARNING 是否处理 |

---

## 6. 未完成项 / 阻塞

- **运行时接线未由 Rank-2 落地**（授权边界，非缺陷）：`encounter_director.gd` 本轮唯一写入方
  是 Rank-1（A44），Rank-2 只读。3 个信号 / `apply_hit` / `try_execute` / `tick` / `on_boss_defeated`
  的接线由 Rank-1 完成；接线前机制在运行时不产生画面效果，纯逻辑与数据表已就绪并自测通过。
- **`hp_restore` / `poise_damage_bonus` / `cost_key` 的运行时消费方**未落地（属导演层 / 玩家组件），
  Rank-2 只产出成对数据。详见 §3.4。
- **实机录屏目视**（公共契约要求 15~20 秒回看）：本轮交付为纯逻辑 + 数据表，headless 真跑无渲染
  画面，未录屏；不伪造、列为后续 / 需用户确认。
- 无阻塞；所有硬约束内工作已完成。

---

## 7. 待总指挥裁决项（只登记、不擅改）

1. **数值校准**：boon 三候选（40.0 / 0.25 / 60.0、1.15 / 0.85 / 1.20）与韧性规则
   （100.0 / 3.0 / 50 / 25.0）全部 `[PLACEHOLDER]`，待人工试玩校准；只改 `.tres`、同步
   verify 的 `EXPECT_*` 与本文数值表。
2. **机制 A 的存档口径**：boon draft 本轮按「纯逻辑不写存档（I-1）」落地，未新增三段式 flag；
   若需持久化「已选赐福 / 代价生效到下一波」，由 Rank-3 按契约 §3.3 登记新 flag 并裁决
   （本轮 Rank-3 并行任务含「新 flag 三段式登记」）。
3. **处决额外点数 / boon 点数的落盘点与 reason**：由 Rank-3 经 `grace.trial.points`（只增不减）
   与 `commit(...)` 落盘，Rank-2 不写；具体 reason 字符串由 Rank-3 口径登记。
4. **Boon「代价作用于下一波」的落地位置**：`hp_scale` / `telegraph_scale` 由 Rank-1 导演层
   在下一波生成敌人时消费，请明确是乘到 `wave_trial.tres` 的 `hp_multiplier` / `telegraph_sec`
   还是独立叠加层（避免与既有倍率重复放大）。
5. **既有 autoload 的 3 条 WARNING**（SaveSystem 工具模式降级 / ChunkManager / ObjectDB 泄漏）：
   非本轮引入，是否纳入后续清理由总指挥裁决。
6. **R31B 与 R32 回执合并口径**：按任务单已另写回执 `cmd-20261111-141611-501-A2.json` +
   `DONE-R31B.md`，两条命令未合成一条，口径以任务单为准。

---

## 8. 设计漏洞主动识别（P0 / P1 / P2）

| 级别 | 漏洞 | 缓解 / 现状 |
|---|---|---|
| **P0** | 无 | 纯逻辑层已覆盖幂等 / 非负 / 异常 / 存档越权 / Boss 死亡 / 超时，自测机器判定 |
| **P1** | 机制 B 的 `tick(delta)` 依赖外部每帧调用；导演层若漏接，窗口永不超时 | 已在 §3.3 接线示意与头注显式强调；属接线约束，需 Rank-1 保证 |
| **P1** | 机制 A 的 `cost_key`「下一波」由外部消费；若漏接则代价失效（白拿增益） | `apply()` 强制 `paired=true` 且成对返回 cost 元数据；消费落地待 Rank-1（裁决项 4） |
| **P2** | `reference_poise_damage=25.0` 仅文档参考、不参与结算，实机招式削韧可能与之脱节 | 由调用方按招式传 `apply_hit(poise_damage)`；校准同步表说明 |
| **P2** | `points_bonus` 表值以 float 存储、`settle()` 用 `roundf` 取整 | 首版 60.0 → 60 精确；校准时避免非整浮点 |
| **P2** | 全部 `[PLACEHOLDER]` 未经手感校准 | 调参唯一入口 + 校准同步清单，待人工试玩 |

---

## 9. 硬约束遵守声明

- `encounter_director.gd` / `hud.gd` / `impact_feedback.gd` / `presentation.gd` / 场景 / 素材 /
  其它 Rank 文件**只读未改**；`courtyard.tscn` 节点数 `41` / uv `2/1/1` 未破坏（GATE-3 实证）。
- 既有 `.tres` 数值零改动（`trial_modifiers.tres` / `wave_trial.tres` md5 前后一致），只新增
  `boon_draft.tres` / `stagger_rules.tres` 两张新表。
- 纯逻辑（I-1）：两个 service 均为 `RefCounted`，不 `add_child` / 不 `get_tree()` / 不
  `/root/...` / 不 `open(user://)` / 不 `set_flag` / 不 `commit` / 不碰渲染 / 不写生产存档。
- Godot4 自测纪律：`extends SceneTree` 用 `Engine.get_main_loop() as SceneTree` 取 root（只读
  断言）、资源回读 `CACHE_MODE_IGNORE`、不写 `user://slot_01/delta.json`。
- 零付费、零外部依赖、不启 GPU job；不伪造产物、不谎报成功、不自行 git；未删除 `.workbuddy`。
- 默认不刺探：未扫目录做进度巡检、未写只读探针 / 巡检脚本；仅按任务单要求确认回执目录与
  中枢归档结构。

---

## 10. 两份回执与中枢归档确认（写后已确认）

- 回执写入 Rank-2 授权路径（**`teamwork/command_center/`，非工程根**）：
  `teamwork/command_center/ai/2/outbox/cmd-20261112-074023-393-A2.json` 与
  `cmd-20261111-141611-501-A2.json`，均为 `{"task_id", "ai":2, "status":"done", "result"}` 四字段。
- 中枢（`poll_ms=600`）已归档，`dispatcher.log` 尾部原文：
  ```
  [2026-11-12 07:59:32] ← 2 号 AI 回执 <cmd-20261112-074023-393-A2> 完成：R32 / v0.10.0 完成…
  [2026-11-12 07:59:40] ← 2 号 AI 回执 <cmd-20261111-141611-501-A2> 完成：R31B 遗留由 R32 合并补齐…
  ```
- 归档副本落位：`dispatcher/receipts/cmd-20261112-074023-393-A2.json`（1812 B）与
  `cmd-20261111-141611-501-A2.json`（952 B），两份均 `VALID_JSON=True`、`status=done`、
  `ai=2`、`task_id` 正确；`ledger.jsonl` 新增 2 条登记；`ai/2/status.json` 由
  `working / completed=39` 更新为 `idle / completed=41 / current_task=""`。
- `outbox` 按中枢流程归档后清空（回执已移入 `dispatcher/receipts/` 归档），与历史其它 AI
  的 outbox 为空一致，属中枢正常处理；不重放、不伪造。R32 与 R31B 两份回执、两份 DONE
  分开登记，未合成一条。
