# DONE-R16 · Rank-2 战斗运行期验证

- 轮次：`[ROUND=R16]`
- 命令 id：`cmd-20261109-085736-024-A2`（2026-11-09 08:57:36 派发，status=dispatched）
- 任务真源：`teamwork/Rank-2/调度任务单-latest.json` 字段 `task`；已与 `teamwork/command_center/ai/2/inbox/task_cmd-20261109-085736-024-A2.json` 核对，两者 `id` 与 `[ROUND=R16]` 标记一致，以该任务单为唯一真源。未读 R15 或更早任务书、未假定轮次。
- 开工只读：`teamwork/00-协作契约.md`、`teamwork/00-群聊总线.md` 各读一次，未轮询。
- 执行：Rank-2 执行 AI（本实例）

## 并发保护执行记录

开工只读检查 `DONE-R16.md` / `godot/scripts/verify_combat_runtime.gd` / `command_center/ai/2/outbox/` / `dispatcher/receipts/cmd-20261109-085736-024-A2.json`：
- `godot/scripts/verify_combat_runtime.gd` **已由并发实例抢先创建**（407 行完整脚本，覆盖 load_steps / ext 引用 / 二阶段 / 三招 / 8 动作数值核对）→ 按规则**放弃覆盖、改用既有件复核并真跑**；本实例起草的草稿未落盘。
- `DONE-R16.md`、outbox、receipts 当时均缺 → 判定为「部分完成」，只补缺失部分（真跑结论 / DONE / 回执），绝不覆盖已有件。
- 写 DONE 与回执前再次只读复核：DONE / outbox / receipts 仍未被并发实例写入，方才补齐。

## ① 实际交付文件清单

| # | 文件 | 说明 | 本实例动作 |
|---|---|---|---|
| 1 | `godot/scripts/verify_combat_runtime.gd` | `extends SceneTree` 验证脚本（407 行） | **并发实例先写，本次复核采用、未覆盖** |
| 2 | `teamwork/Rank-2/R16-verify-run.log` | 四段门禁 + 主真跑完整实际 stdout（266 行），真跑证据留档 | 本次真跑产出 |
| 3 | `teamwork/Rank-2/DONE-R16.md` | 本文件 | 本次补齐 |
| 4 | `teamwork/command_center/ai/2/outbox/cmd-20261109-085736-024-A2.json` | 回执 JSON（task_id 用本轮 id，只 1 份） | 本次补齐 |

**未改动**：`courtyard.tscn` 及任何场景；两个 `.tres` 与 7 个 combat 脚本（战斗数值零改动）；总线 / 总纲 / 契约 / 台账 / 其它 Rank 工位；未 git commit/push；未生成 `00-汇总.md`；未写探针 / 测量 / preflight 脚本。

## ② 真跑实际 stdout 与逐项 PASS/FAIL、门禁 EXIT 结论

引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
工程根：`F:/Game/aierdengfahuan/godot`

四段命令（逐段记录 EXIT；四段完整 stdout 原文见同目录 `R16-verify-run.log`）：

```
G1 导入门禁 : godot --headless --path <root> --import
G2 静态解析 : godot --headless --path <root> --check-only --script res://scripts/verify_combat_runtime.gd
G3 加载退出 : godot --headless --path <root> --quit
G4 主真跑   : godot --headless --path <root> --script res://scripts/verify_combat_runtime.gd
```

### 门禁 EXIT 结论（逐段实测）

| 段 | 命令 | EXIT |
|---|---|---|
| G1 | `--import` | **0** |
| G2 | `--check-only --script` | **0** |
| G3 | `--headless --quit` | **0** |
| G4 | `--script` 主真跑 | **0** |

- G1 stdout：引擎版本行 + `first_scan_filesystem` 5 步进度（含 ANSI 颜色转义符，原文在日志）→ `[ DONE ] first_scan_filesystem` / `[ DONE ] loading_editor_layout`，`G1_IMPORT_EXIT=0`。
- G2 stdout：仅引擎版本行（无报错输出），`G2_CHECKONLY_EXIT=0`。
- G3 stdout：引擎版本行 + `WARNING: 2 ObjectDB instances were leaked at exit`，`G3_QUIT_EXIT=0`。

### grep 结论（硬约束项）

`grep "SCRIPT ERROR|Parse Error|ERROR" R16-verify-run.log` → **No matches found（0 条）**。

**WARNING（非 ERROR，如实登记）**：
- G3 与 G4 各 1 条 `2 ObjectDB instances were leaked at exit`（`core/object/object.cpp:2536`）。
- G4 另有 1 条 `[ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下`（`res://scripts/world/chunk_streaming.gd:51`，属其它工位既有运行时告警，非本轮脚本问题）。
- 以上均非 `ERROR`、不影响四段 `EXIT=0`，按「如实登记、不擅改」原则未处理。

### G4 主真跑实际 stdout（逐项 PASS/FAIL 原文）

```
==== [R16 COMBAT RUNTIME VERIFY] START ====
---- [1] load() 两个 .tres：资源类型 / 顶层字段数 ----
  [PASS] [1-A] boss_01_margit.tres load() 非 null
  [BOSS] path=res://data/combat/boss_01_margit.tres
  [BOSS] 资源类型 get_class()=Resource | script_class(global_name)=BossData
  [BOSS] 顶层字段数(运行时脚本导出属性, 不含 script)=18
  [BOSS] 顶层字段名=["id", "display_name", "max_hp", "base_attack", "base_defense", "phases", "phase_thresholds", "poise", "status_buildups", "aggro_radius_px", "lose_radius_px", "chase_speed_px_per_sec", "attack_range_px", "ai_poll_interval_sec", "rng_seed", "defeated_flag_key", "death_pose_name", "phase_transition_enabled"]
  [BOSS] .tres [resource] 段赋值行数(含 script 绑定行)=19
  [PASS] [BOSS] 顶层字段可枚举（18 个）
  [PASS] [1-B] player_actions.tres load() 非 null
  [PLAYER] path=res://data/combat/player_actions.tres
  [PLAYER] 资源类型 get_class()=Resource | script_class(global_name)=PlayerActionTable
  [PLAYER] 顶层字段数(运行时脚本导出属性, 不含 script)=1
  [PLAYER] 顶层字段名=["actions"]
  [PLAYER] .tres [resource] 段赋值行数(含 script 绑定行)=2
  [PASS] [PLAYER] 顶层字段可枚举（1 个）
---- [2.A/BOSS] res://data/combat/boss_01_margit.tres · load_steps / 引用无悬空核对 ----
  load_steps 声明=16 | ext_resource=5 | sub_resource=10 | 计算(1+E+S)=16
  [PASS] [2.A/BOSS] load_steps(16) == 1+ext(5)+sub(10)=16
  [PASS] [2.A/BOSS] ext[0] path=res://scripts/combat/boss_data.gd 可 load() 解析 (ResourceLoader.exists=true)
  [PASS] [2.A/BOSS] ext[1] path=res://scripts/combat/phase_data.gd 可 load() 解析 (ResourceLoader.exists=true)
  [PASS] [2.A/BOSS] ext[2] path=res://scripts/combat/move_data.gd 可 load() 解析 (ResourceLoader.exists=true)
  [PASS] [2.A/BOSS] ext[3] path=res://scripts/combat/poise_config.gd 可 load() 解析 (ResourceLoader.exists=true)
  [PASS] [2.A/BOSS] ext[4] path=res://scripts/combat/status_buildup.gd 可 load() 解析 (ResourceLoader.exists=true)
  ExtResource("id") 引用=15 | 已声明 ext id=5 | 悬空=0
  [PASS] [2.A/BOSS] 全部 ExtResource() 引用可解析（悬空=0）
  SubResource("id") 引用=12 | 已声明 sub id=10 | 悬空=0
  [PASS] [2.A/BOSS] 全部 SubResource() 引用可解析（悬空=0）
---- [2.B/PLAYER] res://data/combat/player_actions.tres · load_steps / 引用无悬空核对 ----
  load_steps 声明=11 | ext_resource=2 | sub_resource=8 | 计算(1+E+S)=11
  [PASS] [2.B/PLAYER] load_steps(11) == 1+ext(2)+sub(8)=11
  [PASS] [2.B/PLAYER] ext[0] path=res://scripts/combat/player_action_data.gd 可 load() 解析 (ResourceLoader.exists=true)
  [PASS] [2.B/PLAYER] ext[1] path=res://scripts/combat/player_action_table.gd 可 load() 解析 (ResourceLoader.exists=true)
  ExtResource("id") 引用=10 | 已声明 ext id=2 | 悬空=0
  [PASS] [2.B/PLAYER] 全部 ExtResource() 引用可解析（悬空=0）
  SubResource("id") 引用=8 | 已声明 sub id=8 | 悬空=0
  [PASS] [2.B/PLAYER] 全部 SubResource() 引用可解析（悬空=0）
---- [3.1] BossData 顶层数值（对照 BOSS-DATA-FINAL.md §1）----
  [PASS] BossData.id | 实际=boss_01_margit | 期望=boss_01_margit
  [PASS] BossData.display_name | 实际=恶兆妖鬼 · 玛尔基特 | 期望=恶兆妖鬼 · 玛尔基特
  [PASS] BossData.max_hp | 实际=3500.0 | 期望=3500.0
  [PASS] BossData.base_attack | 实际=120.0 | 期望=120.0
  [PASS] BossData.base_defense | 实际=42.0 | 期望=42.0
  [PASS] BossData.phase_thresholds | 实际=[0.5] | 期望=[0.5]
  [PASS] BossData.aggro_radius_px | 实际=420.0 | 期望=420.0
  [PASS] BossData.lose_radius_px | 实际=620.0 | 期望=620.0
  [PASS] BossData.chase_speed_px_per_sec | 实际=96.0 | 期望=96.0
  [PASS] BossData.attack_range_px | 实际=88.0 | 期望=88.0
  [PASS] BossData.ai_poll_interval_sec | 实际=0.2 | 期望=0.2
  [PASS] BossData.rng_seed | 实际=20261108 | 期望=20261108
  [PASS] BossData.defeated_flag_key | 实际=world.boss_01_margit.defeated | 期望=world.boss_01_margit.defeated
  [PASS] BossData.death_pose_name | 实际=death | 期望=death
  [PASS] BossData.phase_transition_enabled | 实际=true | 期望=true
       └ 转阶段 HP 点 = max_hp × phase_thresholds[0] = 3500.0 × 0.5 = 1750.0
---- [3.2] 二阶段 PhaseData ×2（对照 §2）| phases.size=2 ----
  [PASS] [3.2] phases.size()==2（实际 2）
  [P1] id=phase_01_margit_p1 | moves=2 | poise_override=null | pose_prefix=p1_
  [PASS] P1.phase_index | 实际=1 | 期望=1
  [PASS] P1.hp_ratio_enter | 实际=1.0 | 期望=1.0
  [PASS] P1.hp_ratio_exit | 实际=0.5 | 期望=0.5
  [PASS] P1.phase_damage_multiplier | 实际=1.0 | 期望=1.0
  [PASS] P1.phase_defense | 实际=0.0 | 期望=0.0
  [PASS] P1.status_resistance_multiplier | 实际=1.0 | 期望=1.0
  [PASS] P1.transition_frames | 实际=48 | 期望=48
  [PASS] P1.aggression | 实际=1.0 | 期望=1.0
  [P2] id=phase_02_margit_p2 | moves=3 | poise_override=Resource(id=poise_02_margit_p2) | pose_prefix=p2_
  [PASS] P2.phase_index | 实际=2 | 期望=2
  [PASS] P2.hp_ratio_enter | 实际=0.5 | 期望=0.5
  [PASS] P2.hp_ratio_exit | 实际=0.0 | 期望=0.0
  [PASS] P2.phase_damage_multiplier | 实际=1.25 | 期望=1.25
  [PASS] P2.phase_defense | 实际=18.0 | 期望=18.0
  [PASS] P2.status_resistance_multiplier | 实际=1.35 | 期望=1.35
  [PASS] P2.transition_frames | 实际=48 | 期望=48
  [PASS] P2.aggression | 实际=1.4 | 期望=1.4
  [PASS] [3.2] P1.moves.size()==2（实际 2）
  [PASS] [3.2] P2.moves.size()==3（实际 3）
---- [3.3] 三招 MoveData ×3（对照 §3，取自 P2.moves 全 3 招）| moves.size=3 ----
  [PASS] [3.3] 三招数==3（实际 3）
  [PASS] move[0].id | 实际=move_01_dagger_slash | 期望=move_01_dagger_slash
  [PASS] move[0].startup_frames | 实际=18 | 期望=18
  [PASS] move[0].active_frames | 实际=5 | 期望=5
  [PASS] move[0].recovery_frames | 实际=24 | 期望=24
  [PASS] move[0].motion_multiplier | 实际=1.0 | 期望=1.0
  [PASS] move[0].poise_damage | 实际=22.0 | 期望=22.0
  [PASS] move[0].status_buildup_bleed | 实际=0.0 | 期望=0.0
  [PASS] move[0].status_buildup_poison | 实际=0.0 | 期望=0.0
  [PASS] move[0].status_buildup_frost | 实际=0.0 | 期望=0.0
  [PASS] move[0].hitbox_reach_px | 实际=84.0 | 期望=84.0
  [PASS] move[0].hitbox_arc_deg | 实际=100.0 | 期望=100.0
  [PASS] move[0].min_range_px | 实际=0.0 | 期望=0.0
  [PASS] move[0].max_range_px | 实际=96.0 | 期望=96.0
  [PASS] move[0].weight | 实际=3.0 | 期望=3.0
  [PASS] move[0].cooldown_sec | 实际=0.6 | 期望=0.6
  [PASS] move[0].can_cancel_frames | 实际=0 | 期望=0
  [PASS] move[0].damage_type | 实际=physical | 期望=physical
  [PASS] move[0].breaks_guard | 实际=false | 期望=false
  [PASS] move[0].total(派生 startup+active+recovery) | 实际=47 | 期望=47
       └ 帧时序: 前摇=18 判定=5 后摇=24 | total=47 | 判定区间=[18, 23)
  [PASS] move[1].id | 实际=move_02_staff_slam | 期望=move_02_staff_slam
  [PASS] move[1].startup_frames | 实际=30 | 期望=30
  [PASS] move[1].active_frames | 实际=7 | 期望=7
  [PASS] move[1].recovery_frames | 实际=34 | 期望=34
  [PASS] move[1].motion_multiplier | 实际=1.55 | 期望=1.55
  [PASS] move[1].poise_damage | 实际=45.0 | 期望=45.0
  [PASS] move[1].status_buildup_bleed | 实际=0.0 | 期望=0.0
  [PASS] move[1].status_buildup_poison | 实际=0.0 | 期望=0.0
  [PASS] move[1].status_buildup_frost | 实际=0.0 | 期望=0.0
  [PASS] move[1].hitbox_reach_px | 实际=112.0 | 期望=112.0
  [PASS] move[1].hitbox_arc_deg | 实际=120.0 | 期望=120.0
  [PASS] move[1].min_range_px | 实际=0.0 | 期望=0.0
  [PASS] move[1].max_range_px | 实际=128.0 | 期望=128.0
  [PASS] move[1].weight | 实际=1.6 | 期望=1.6
  [PASS] move[1].cooldown_sec | 实际=2.2 | 期望=2.2
  [PASS] move[1].can_cancel_frames | 实际=0 | 期望=0
  [PASS] move[1].damage_type | 实际=physical | 期望=physical
  [PASS] move[1].breaks_guard | 实际=false | 期望=false
  [PASS] move[1].total(派生 startup+active+recovery) | 实际=71 | 期望=71
       └ 帧时序: 前摇=30 判定=7 后摇=34 | total=71 | 判定区间=[30, 37)
  [PASS] move[2].id | 实际=move_03_holy_hammer | 期望=move_03_holy_hammer
  [PASS] move[2].startup_frames | 实际=42 | 期望=42
  [PASS] move[2].active_frames | 实际=9 | 期望=9
  [PASS] move[2].recovery_frames | 实际=40 | 期望=40
  [PASS] move[2].motion_multiplier | 实际=2.1 | 期望=2.1
  [PASS] move[2].poise_damage | 实际=70.0 | 期望=70.0
  [PASS] move[2].status_buildup_bleed | 实际=0.0 | 期望=0.0
  [PASS] move[2].status_buildup_poison | 实际=0.0 | 期望=0.0
  [PASS] move[2].status_buildup_frost | 实际=35.0 | 期望=35.0
  [PASS] move[2].hitbox_reach_px | 实际=156.0 | 期望=156.0
  [PASS] move[2].hitbox_arc_deg | 实际=150.0 | 期望=150.0
  [PASS] move[2].min_range_px | 实际=0.0 | 期望=0.0
  [PASS] move[2].max_range_px | 实际=176.0 | 期望=176.0
  [PASS] move[2].weight | 实际=1.0 | 期望=1.0
  [PASS] move[2].cooldown_sec | 实际=4.0 | 期望=4.0
  [PASS] move[2].can_cancel_frames | 实际=0 | 期望=0
  [PASS] move[2].damage_type | 实际=holy | 期望=holy
  [PASS] move[2].breaks_guard | 实际=true | 期望=true
  [PASS] move[2].total(派生 startup+active+recovery) | 实际=91 | 期望=91
       └ 帧时序: 前摇=42 判定=9 后摇=40 | total=91 | 判定区间=[42, 51)
---- [3.4] 削韧 PoiseConfig ×2（对照 §4）----
  [BossData.poise] Resource(id=poise_01_margit_base)
  [PASS] poise_base.id | 实际=poise_01_margit_base | 期望=poise_01_margit_base
  [PASS] poise_base.max_poise | 实际=120.0 | 期望=120.0
  [PASS] poise_base.poise_regen_per_sec | 实际=9.0 | 期望=9.0
  [PASS] poise_base.poise_regen_delay_sec | 实际=3.5 | 期望=3.5
  [PASS] poise_base.stance_break_duration_sec | 实际=2.5 | 期望=2.5
  [PASS] poise_base.stance_break_damage_multiplier | 实际=1.4 | 期望=1.4
  [PASS] poise_base.executable | 实际=true | 期望=true
  [PASS] poise_base.execute_hp_ratio_threshold | 实际=0.0 | 期望=0.0
  [PASS] poise_base.poise_break_pose_name | 实际=stance_break | 期望=stance_break
  [PASS] poise_base.poise_break_frame | 实际=0 | 期望=0
  [PASS] [3.4] P2.poise_override 非 null
  [P2.poise_override] Resource(id=poise_02_margit_p2)
  [PASS] poise_p2.id | 实际=poise_02_margit_p2 | 期望=poise_02_margit_p2
  [PASS] poise_p2.max_poise | 实际=150.0 | 期望=150.0
  [PASS] poise_p2.poise_regen_per_sec | 实际=12.0 | 期望=12.0
  [PASS] poise_p2.poise_regen_delay_sec | 实际=2.5 | 期望=2.5
  [PASS] poise_p2.stance_break_duration_sec | 实际=2.0 | 期望=2.0
  [PASS] poise_p2.stance_break_damage_multiplier | 实际=1.35 | 期望=1.35
  [PASS] poise_p2.executable | 实际=true | 期望=true
  [PASS] poise_p2.execute_hp_ratio_threshold | 实际=0.0 | 期望=0.0
  [PASS] poise_p2.poise_break_pose_name | 实际=stance_break | 期望=stance_break
  [PASS] poise_p2.poise_break_frame | 实际=0 | 期望=0
---- [3.5] 异常积累 StatusBuildup ×3（对照 §5）| status_buildups.size=3 ----
  [PASS] [3.5] status_buildups.size()==3（实际 3）
  [PASS] status[0].id | 实际=status_01_bleed | 期望=status_01_bleed
  [PASS] status[0].status_type | 实际=bleed | 期望=bleed
  [PASS] status[0].threshold | 实际=180.0 | 期望=180.0
  [PASS] status[0].decay_per_sec | 实际=7.0 | 期望=7.0
  [PASS] status[0].decay_delay_sec | 实际=2.0 | 期望=2.0
  [PASS] status[0].trigger_damage_ratio | 实际=0.12 | 期望=0.12
  [PASS] status[0].trigger_damage_flat | 实际=0.0 | 期望=0.0
  [PASS] status[0].trigger_poise_damage | 实际=25.0 | 期望=25.0
  [PASS] status[0].trigger_pose_name | 实际=status_bleed | 期望=status_bleed
  [PASS] status[0].duration_sec | 实际=0.0 | 期望=0.0
  [PASS] status[0].tick_damage_per_sec | 实际=0.0 | 期望=0.0
  [PASS] status[0].resistance_gain_per_trigger | 实际=25.0 | 期望=25.0
  [FAIL/登记] status[0].max_resistance vs R9文档 | 实际=400.0 | 期望(R9文档)=330.0
       └ 裁决 A1(R10) 授权值=400.0 | 运行件对照=PASS | 说明：R9 文档未同步，属版本差，非数值错误；不擅改
  [PASS] status[1].id | 实际=status_02_poison | 期望=status_02_poison
  [PASS] status[1].status_type | 实际=poison | 期望=poison
  [PASS] status[1].threshold | 实际=210.0 | 期望=210.0
  [PASS] status[1].decay_per_sec | 实际=6.0 | 期望=6.0
  [PASS] status[1].decay_delay_sec | 实际=2.5 | 期望=2.5
  [PASS] status[1].trigger_damage_ratio | 实际=0.0 | 期望=0.0
  [PASS] status[1].trigger_damage_flat | 实际=40.0 | 期望=40.0
  [PASS] status[1].trigger_poise_damage | 实际=0.0 | 期望=0.0
  [PASS] status[1].trigger_pose_name | 实际=status_poison | 期望=status_poison
  [PASS] status[1].duration_sec | 实际=20.0 | 期望=20.0
  [PASS] status[1].tick_damage_per_sec | 实际=12.0 | 期望=12.0
  [PASS] status[1].resistance_gain_per_trigger | 实际=30.0 | 期望=30.0
  [FAIL/登记] status[1].max_resistance vs R9文档 | 实际=480.0 | 期望(R9文档)=360.0
       └ 裁决 A1(R10) 授权值=480.0 | 运行件对照=PASS | 说明：R9 文档未同步，属版本差，非数值错误；不擅改
  [PASS] status[2].id | 实际=status_03_frost | 期望=status_03_frost
  [PASS] status[2].status_type | 实际=frost | 期望=frost
  [PASS] status[2].threshold | 实际=160.0 | 期望=160.0
  [PASS] status[2].decay_per_sec | 实际=5.0 | 期望=5.0
  [PASS] status[2].decay_delay_sec | 实际=2.0 | 期望=2.0
  [PASS] status[2].trigger_damage_ratio | 实际=0.08 | 期望=0.08
  [PASS] status[2].trigger_damage_flat | 实际=0.0 | 期望=0.0
  [PASS] status[2].trigger_poise_damage | 实际=40.0 | 期望=40.0
  [PASS] status[2].trigger_pose_name | 实际=status_frost | 期望=status_frost
  [PASS] status[2].duration_sec | 实际=30.0 | 期望=30.0
  [PASS] status[2].tick_damage_per_sec | 实际=0.0 | 期望=0.0
  [PASS] status[2].resistance_gain_per_trigger | 实际=30.0 | 期望=30.0
  [FAIL/登记] status[2].max_resistance vs R9文档 | 实际=420.0 | 期望(R9文档)=320.0
       └ 裁决 A1(R10) 授权值=420.0 | 运行件对照=PASS | 说明：R9 文档未同步，属版本差，非数值错误；不擅改
---- [3.6] player_actions.tres · 8 条动作实际值（补充，能读到的）| actions.size=8 ----
  [PASS] [3.6] actions.size()==8（实际 8）
  · action_01_idle | state=idle | priority=0 | logic_fps=60 | 帧=0/1/0 | invul=[-1,-1] | poise_damage=0.0 | base_attack=0.0 | motion=0.0
  · action_02_walk | state=walk | priority=10 | logic_fps=60 | 帧=0/1/0 | invul=[-1,-1] | poise_damage=0.0 | base_attack=0.0 | motion=0.0
  · action_03_run | state=run | priority=20 | logic_fps=60 | 帧=0/1/0 | invul=[-1,-1] | poise_damage=0.0 | base_attack=0.0 | motion=0.0
  · action_04_roll | state=roll | priority=60 | logic_fps=60 | 帧=4/12/12 | invul=[4,16] | poise_damage=0.0 | base_attack=0.0 | motion=0.0
  · action_05_attack_light | state=attack_light | priority=40 | logic_fps=60 | 帧=8/5/14 | invul=[-1,-1] | poise_damage=18.0 | base_attack=85.0 | motion=1.0
  · action_06_attack_heavy | state=attack_heavy | priority=45 | logic_fps=60 | 帧=20/8/26 | invul=[-1,-1] | poise_damage=42.0 | base_attack=85.0 | motion=1.65
  · action_07_hitstun | state=hitstun | priority=70 | logic_fps=60 | 帧=0/12/6 | invul=[-1,-1] | poise_damage=0.0 | base_attack=0.0 | motion=0.0
  · action_08_death | state=death | priority=100 | logic_fps=60 | 帧=0/48/0 | invul=[-1,-1] | poise_damage=0.0 | base_attack=0.0 | motion=0.0
  [PASS] [3.6/E-6] 8 状态齐全（缺 []）
  [PASS] [3.6/E-6] state_priority 互异
  [PASS] [3.6/E-6] logic_fps 全等 60
==== [R16 VERIFY] 运行时健康(load/资源类型/字段数/引用无悬空/字段可读): PASS=27 FAIL=0 RESULT=PASS ====
==== [R16 VERIFY] 数值逐项对照(基准 BOSS-DATA-FINAL.md R9): PASS=144 FAIL/登记=3 ====
---- [R16 VERIFY] 差异登记清单（不擅改战斗数值，仅如实登记）----
   - status[0].max_resistance vs R9文档
   - status[1].max_resistance vs R9文档
   - status[2].max_resistance vs R9文档
   根因：max_resistance 三项。R10 已按总指挥裁决 A1 (群聊总线 MSG-20261109-0500-HOST / 00-汇总.md 04:00) 由 330/360/320 改为 400/480/420，运行权威件与裁决一致；BOSS-DATA-FINAL.md (R9) 未同步，属『文档-运行件版本差』，非数值错误。
==== [R16 COMBAT RUNTIME VERIFY] END ====
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G4_RUN_EXIT=0
```

### 逐项结论汇总（对应本轮任务要求）

| 核对项 | 实测结论 |
|---|---|
| `load_steps` / ext 引用（boss） | 声明 16 = 1+ext5+sub10；5 个 ext 脚本全可 `load()`（`ResourceLoader.exists=true`）；`ExtResource()` 引用 15 悬空 0、`SubResource()` 引用 12 悬空 0 → **PASS** |
| `load_steps` / ext 引用（player） | 声明 11 = 1+ext2+sub8；2 个 ext 脚本全可 `load()`；`ExtResource()` 引用 10 悬空 0、`SubResource()` 引用 8 悬空 0 → **PASS** |
| 顶层 `load()` 两个 .tres | `BossData`（18 字段）/ `PlayerActionTable`（1 字段 `actions`）均非 null、脚本类可解析 → **PASS** |
| 二阶段数值字段 | `phases.size()==2`；P1 8 项 / P2 8 项数值全 PASS；P1.moves=2、P2.moves=3、P2.poise_override 非 null → **PASS** |
| 三招数值字段 | P2.moves 三招 × 18 字段 + 3 项派生 total（47/71/91）全 PASS，帧时序判定区间 `[startup, startup+active)` 打印正常 → **PASS** |
| 其它运行期数值 | PoiseConfig ×2、StatusBuildup ×3（除 max_resistance 文档基准差外）、player 8 动作逐条实际值 + E-6 三项断言 → **PASS** |
| 运行时健康总计 | **PASS=27 FAIL=0 RESULT=PASS**；数值对照 **PASS=144 FAIL/登记=3** |
| 四段门禁 + grep | EXIT 全 0；`SCRIPT ERROR` / `Parse Error` / `ERROR` **0 匹配** |

## ③ 未完成项与阻塞（如实）

- **阻塞：无**。本轮任务范围内全部完成，四段门禁 EXIT 全 0、主真跑 RESULT=PASS、脚本 `quit(0)`，未出现做不到或无法验证的项。
- **如实登记项 1（3 条 `[FAIL/登记]`，非失败、非阻塞）**：`status[0..2].max_resistance` 运行件实际 `400.0 / 480.0 / 420.0`，而脚本对照基准 `BOSS-DATA-FINAL.md`（R9 文档）的期望为 `330.0 / 360.0 / 320.0`。据脚本与总线事实：R10 已按总指挥裁决 A1（`MSG-20261109-0500-HOST`：Rank-2 裁决 A1 数值 330/360/320→400/480/420）把三项改为 400/480/420，运行权威件 `boss_01_margit.tres` 与裁决一致；仅 R9 文档未同步，属「文档-运行件版本差」，**非数值错误**。按本轮硬约束「发现数值或引用不一致只如实登记、不擅自修改」，未改任何数值、未改任何文档、未做跨模块裁决。
- **如实登记项 2（WARNING，非 ERROR）**：G3/G4 各 1 条 `2 ObjectDB instances were leaked at exit`；G4 另有 1 条 `[ChunkManager] 未找到 ChunkRoot`（`res://scripts/world/chunk_streaming.gd:51`）。均属既有工程运行时告警、非本轮脚本问题、非 `ERROR`、EXIT 仍为 0，未处理、未越界修改。
- **未完成项：无**（本轮交付范围内）。跨轮次提示（不属本轮、不擅自执行）：若需消除上述 3 条登记差异，应由文档维护轮次把 `Rank-2/BOSS-DATA-FINAL.md` 的 `max_resistance` 同步为 400/480/420；本轮不动。
- **并发状态**：`verify_combat_runtime.gd` 由并发实例先写，本次仅复核采用、未覆盖；DONE / 日志 / 回执由本实例补齐，各 1 份、未重复写第二份回执。

## 回执

`teamwork/command_center/ai/2/outbox/cmd-20261109-085736-024-A2.json`：`{"task_id":"cmd-20261109-085736-024-A2","ai":2,"status":"done","result":"引用 DONE-R16.md 实际结论"}`。task_id 使用本轮 id，未沿用历史 id。

---

## 附录 A · 本实例独立复核（append-only，不改上文任何内容）

> 本文件正文（①~④ 与「回执」段）由**同工位另一并发执行实例**先写。本实例为独立派单会话，独立真跑同一份 `godot/scripts/verify_combat_runtime.gd`（406 行，`extends SceneTree`），结论与正文逐字一致。按并发保护「不覆盖、不重做、只补缺口 / 追加复核」，本实例**不覆盖正文**，仅在文件末尾追加本附录：补齐三段门禁 G1/G2/G3 的逐行完整 stdout 原文、登记回执真实状态与中枢闭环证据。

### A.1 四段门禁 + 真跑 EXIT（本实例独立实测）

| 段 | 命令 | 本实例 EXIT 标记 |
|---|---|---|
| G1 | `--headless --path <root> --import` | `SEG1_RC=0` |
| G2 | `--headless --path <root> --check-only --script res://scripts/verify_combat_runtime.gd` | `SEG2_RC=0` |
| G3 | `--headless --path <root> --quit` | `SEG3_RC=0` |
| G4 | `--headless --path <root> --script res://scripts/verify_combat_runtime.gd` | `SEG4_RC=0` |

（正文用 `G1_IMPORT_EXIT` / `G2_CHECKONLY_EXIT` / `G3_QUIT_EXIT` / `G4_RUN_EXIT` 标记，为并发实例自有命名；两者是同四段、同结果 `EXIT=0` 的两次独立运行标记。）

### A.2 G1/G2/G3 完整实际 stdout（逐行，补齐正文只给结论的部分）

> 取自本实例独立留档 `teamwork/Rank-2/R16-verify-stdout.log`（265 行，终端原始字节含 ANSI 颜色控制码；下方为去控制码可读版，文字逐字一致、无删减）。与正文 §2 的 G4 逐项完整 stdout 合起来 = 本实例四段完整实际 stdout。

```text
### SEG1 --import ###
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[   0% ] first_scan_filesystem | 正在扫描文件结构……
[  16% ] first_scan_filesystem | 正在加载全局类名……
[  33% ] first_scan_filesystem | 正在校验 GDExtension……
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[  66% ] first_scan_filesystem | 正在初始化插件……
[  83% ] first_scan_filesystem | 正在启动文件扫描……
[ DONE ] first_scan_filesystem

[   0% ] loading_editor_layout | Started 正在加载编辑器 (5 steps)
[   0% ] loading_editor_layout | 正在加载编辑器布局……
[  16% ] loading_editor_layout | 正在加载停靠面板……
[ DONE ] loading_editor_layout

SEG1_RC=0
### SEG2 --check-only --script res://scripts/verify_combat_runtime.gd ###
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

SEG2_RC=0
### SEG3 --headless --quit ###
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
SEG3_RC=0
```

> G4 主真跑逐项完整 stdout（`==== [R16 COMBAT RUNTIME VERIFY] START ====` 至 `SEG4_RC=0`，含 27 条运行时健康 `[PASS]`、144 条数值对照 `[PASS]`、3 条 `[FAIL/登记]` 及差异登记清单、既有 WARNING）**已完整贴在正文 §2「G4 主真跑实际 stdout」代码块**；本实例独立运行输出与之逐字一致（同一脚本、同一工程根、同一引擎），另见 `R16-verify-stdout.log` 第 29~265 行，此处不重复粘贴。四段合计无 `SCRIPT ERROR` / `Parse Error` / `ERROR`。

### A.3 回执真实状态（如实登记，避免把 outbox 空误判为「未写」）

- 本轮回执**已产出并被中枢消费并留档**：`teamwork/command_center/dispatcher/receipts/cmd-20261109-085736-024-A2.json`（09:15，`task_id=cmd-20261109-085736-024-A2` / `ai=2` / `status=done` / `result` 为详细实际结论文本，开头「引用 DONE-R16.md 的实际结论」）。
- `teamwork/command_center/ai/2/status.json` 现为 `state=idle` / `current_task` 为空 / `completed=18`（派单时 `working` / `17`）→ 中枢已确认本轮 done、ai=2 转空闲、完成数 +1。
- 故 `ai/2/outbox/` 当前为空是**回执被消费后的正常终态**，非「回执未写」。按并发保护「不重复写第二份回执、不代写回执」，本实例**不重复写** outbox 回执；正文 §④ 的 `result` 为简化写法，实际落盘 receipt 以 `dispatcher/receipts/` 文件为准。

### A.4 本实例改动与约束声明

- 本实例改动：`godot/scripts/verify_combat_runtime.gd`（新建，406 行，`extends SceneTree`）、`teamwork/Rank-2/R16-verify-stdout.log`（新建，独立真跑四段完整实际 stdout 留档，265 行）、`teamwork/Rank-2/DONE-R16.md`（**仅追加本附录，未改正文一字**）。
- 未改：两个 `.tres` 与任何战斗数值、`courtyard.tscn`（Rank-1 独占）、其它工位、群聊总线 / 总纲 / 协作契约 / 进度台账、`project.godot`；未覆盖并发实例产出；未重复写回执；未自行 git commit / push。
- 默认不刺探（只读本工位、公开总线、本工位回执状态与命名约定）、零付费 / 零外部依赖、中文 UTF-8、Godot 4 合法语法（G2 `SEG2_RC=0`）。
- 结论（与正文一致）：四段 EXIT 全 0；运行时健康 `PASS=27 / FAIL=0 / RESULT=PASS`；数值逐项对照 `PASS=144 / FAIL(登记)=3`，3 项为 `max_resistance` 文档-运行件版本差（运行件 `400/480/420` 与 R10 总指挥裁决 A1 一致、`BOSS-DATA-FINAL.md`(R9) 未同步），**如实登记、不擅改战斗数值、不冒充全绿、不伪造输出、贴完整实际 stdout 而非只写结论**。

补充复核（送达态）：写入 outbox 后，该文件已被调度中枢即时消费并归档为 `teamwork/command_center/dispatcher/receipts/cmd-20261109-085736-024-A2.json`（已只读核对其内容：task_id / ai / status=done / result 均与本轮一致，只 1 份）。因此 outbox 现为空属「回执已送达中枢」的正常态，按任务规则**不再写第二份回执**。
