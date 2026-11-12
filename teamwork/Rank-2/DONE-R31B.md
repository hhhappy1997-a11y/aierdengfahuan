# DONE-R31B.md · R31B 遗留补齐结论（由 R32 合并执行，Rank-2）

> 补回执 id：`cmd-20261111-141611-501-A2` ｜ 触发：`cmd-20261112-074023-393-A2`（R32 任务单 ④ + 「R31B 遗留补执行」段）
> 背景：上一轮四条 R31B 派单因执行进程通道故障未接单，本轮由 R32 合并补齐，**另写一份
> 回执、另写一份 DONE**，不与 R32 回执 / DONE 合成一条。
> 归属：Rank-2。完整交付与真跑输出见 `teamwork/Rank-2/DONE-R32.md`；接线清单见
> `teamwork/Rank-2/R31B-INTEGRATION.md`。

## 1. 补齐产物

| 文件 | 作用 |
|---|---|
| `godot/scripts/combat/verify_trial_modifier_runtime_v090b.gd` | 用 `ResourceLoader.load(..., CACHE_MODE_IGNORE)` 回读真实 `trial_modifiers.tres` 与 `wave_trial.tres`，实例化 `TrialModifierService` 做三词条结算回归，并 md5 前后对比证明既有 `.tres` 零改动 |
| `teamwork/Rank-2/R31B-INTEGRATION.md` | 接线清单（service 由谁调用 / stats 来源 / 落盘责任 Rank）+ broken 判据（词条失效 / 奖励通胀 / 存档越权 / 表被意外改写）+ 待裁决项 |
| `teamwork/command_center/ai/2/outbox/cmd-20261111-141611-501-A2.json` | R31B 补回执（另份） |

既有只读依赖（零改动）：`trial_modifier_config.gd` / `trial_modifier_service.gd` /
`trial_modifiers.tres` / `wave_trial_config.gd` / `wave_trial.tres` /
`verify_trial_modifier_v090.gd`。

## 2. 真跑结论（原文关键行，完整见 DONE-R32.md §4）

```
[V090B-TM] modifier_table_load_cache_ignore PASS=true | path=res://data/rpg/trial_modifiers.tres
[V090B-TM] wave_table_load_cache_ignore PASS=true | path=res://data/rpg/wave_trial.tres
[V090B-TM] settle_no_hit_150 PASS=true | total=150 mult=1.5 [PLACEHOLDER]
[V090B-TM] settle_time_pressure_130 PASS=true | total=130 mult=1.3 [PLACEHOLDER]
[V090B-TM] settle_low_vigor_140 PASS=true | total=140 mult=1.4 [PLACEHOLDER]
[V090B-TM] settle_max_not_multiply PASS=true | 取 max(1.5,1.3)=1.5 -> 150（非 195，不叠乘）
[V090B-TM] exclusive_same_group_rejected PASS=true | no_hit + low_vigor 同 survival 组拒绝
[V090B-TM] no_modifier_baseline PASS=true | 未选 -> 回落基础 100
[V090B-TM] balance_all_nonneg PASS=true | 全程 balance>=0 且 =total，bonus>=0
[V090B-TM] invalid_negative_base_rejected PASS=true | base=-1 拒绝
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

- 三词条结算符合 `[PLACEHOLDER]` 倍率（1.5 / 1.3 / 1.4），`base_points` 取自真实
  `wave_trial.tres` 的 `reward_points`（100 / 150 / 200）。
- 互斥拒绝（`survival` 组）、未选回落、余额非负、异常拒绝（负点数 / `null` stats /
  `config=null`）全部机器判定通过。
- **md5 零改动结论**：`trial_modifiers.tres` = `7e9e5ac7d35d8d15171e69975ac3356d`、
  `wave_trial.tres` = `793b6daa7c7730feed1a3f849701d58a`，前后完全一致，既有 `.tres` 数值零改动。
- `pass=41 fail=0`，`RESULT=ALL_MATCH`，`SCRIPT ERROR=0`，`EXIT=0`。

## 3. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | verify 落地 + 真表 `CACHE_MODE_IGNORE` 回读 + 三词条结算回归 + md5 零改动证明 + `R31B-INTEGRATION.md`；`RESULT=ALL_MATCH` |
| **失败** | 无 |
| **需用户确认** | 运行时接线落地方 / 时机（Rank-1 导演层）、`stats` 采集口径、三词条 `[PLACEHOLDER]` 倍率校准（详见 `R31B-INTEGRATION.md` §4） |

## 4. 未完成项 / 阻塞

- 运行时接线（谁实例化 `TrialModifierService`、`select` 触发时机、`settle` 挂在哪一步）属
  Rank-1 导演层，本轮 Rank-2 未改 `encounter_director.gd`（唯一写入方 Rank-1）；接线前词条
  在运行时不生效，纯逻辑 + 数据表 + 验证已就绪。
- `stats` 的 `damage_taken` / `hp_ratio` 由哪一层汇总（导演层 / 玩家组件）待 Rank-1 编排确认。
- 无阻塞。

## 5. 待裁决项

见 `R31B-INTEGRATION.md` §4（运行时接线落地方与时机、词条 UI 消费、`stats` 统计口径、
`[PLACEHOLDER]` 校准、R31B 与 R32 回执合并不消歧）。
