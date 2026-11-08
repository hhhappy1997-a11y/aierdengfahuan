# BOSS-DATA-FINAL.md —— M5 Boss 最终数据表（Rank-2 · R9）

> 轮次：R9「M5 Boss 最终数据表与汇总材料」，任务单 `cmd-20261109-033148-250-A2`。
> 本表整理 `boss_01_margit.tres` 的**二阶段 + 3 招最终数值**（max_hp / 削韧 / 异常积累 /
> 阶段阈值 / 招式倍率 / 前摇·判定·后摇帧数），并与 `数据表schema.md` v1.0 **逐项核对**。
> 字段真源：`数据表schema.md`；数值实例：`boss_01_margit.tres`；E-8 三项冲突见
> `E8-裁决建议表.md`（**只给建议、不改数值**）。中文 UTF-8。
> **本轮未改任何 `.tres` 数值、未改 `.gd`、未改 schema 口径**（既有件不重做、待裁决项只登记）。

---

## 0. 数据来源与权威口径

| 项 | 内容 |
|---|---|
| 运行权威件 | `godot\data\combat\boss_01_margit.tres`（工程根落位件；5 条 `ext_resource` → `res://scripts/combat/*.gd`） |
| 工位设计稿 | `teamwork\Rank-2\boss_01_margit.tres`（5 条 `ext_resource` → `res://data/schemas/*.gd`） |
| 两份一致性 | `diff <(grep -v ext_resource 工位稿) <(grep -v ext_resource 运行件)` → **DIFF_RC=0**：全部数值字段、sub_resource 声明、id、`load_steps=16` 逐字一致；差异仅 5 条 `ext_resource path`（R6 装配必需的路径修正，非数值，见 `COMBAT-ASSEMBLY.md` §2.5） |
| 本表取值 | 一律取自**运行权威件**；工位稿数值与之逐字相同 |
| 字段真源 | `数据表schema.md` v1.0（§0.1 路径、§1 BossData、§2 PhaseData、§3 MoveData、§4 PoiseConfig、§5 StatusBuildup、§9 E-1~E-9） |
| 校验器口径 | `combat_data_validator.gd`（工位件，`@export resistance_sample_triggers: int = 8`，E-8 式见 §6.3） |

> 数值实例中的 `sprite_frames_path`（`res://assets/generated/bosses/margit_phase{1,2}.tres`）是
> **资源字段值**，Q1 裁决前「仅登记不调用」，阶段动画实际走 `pose_prefix`（`p1_` / `p2_`）+ `set_pose()`。

---

## 1. BossData 顶层数值（18 字段）

| # | 字段 | 类型 | schema 默认 | 本表实际值 | 取值范围 | 核对 |
|---|---|---|---|---|---|---|
| 1 | `id` | String | `""` | `boss_01_margit` | `boss_\d{2}_[a-z0-9_]+` | ✓ |
| 2 | `display_name` | String | `""` | `恶兆妖鬼 · 玛尔基特` | ≤64 字 | ✓ |
| 3 | `max_hp` | float | `1.0` | **3500.0** | `(0, 1e6]` | ✓ |
| 4 | `base_attack` | float | `0.0` | `120.0` | `[0, 1e5]` | ✓ |
| 5 | `base_defense` | float | `0.0` | `42.0` | `[0, 1e5]` | ✓ |
| 6 | `phases` | `Array[PhaseData]` | `[]` | 2 条（p1/p2，见 §2） | `[1, 8]` | ✓ |
| 7 | `phase_thresholds` | `Array[float]` | `[]` | **`[0.5]`** | 每项 `(0,1)` 严格递减，长度 `= phases.size()-1 = 1` | ✓ |
| 8 | `poise` | PoiseConfig | `null` | `poise_01_margit_base`（见 §4） | 非空 | ✓ |
| 9 | `status_buildups` | `Array[StatusBuildup]` | `[]` | 3 条（bleed/poison/frost，见 §5） | `[0, 3]`、`status_type` 不重复 | ✓ |
| 10 | `aggro_radius_px` | float | `300.0` | `420.0` | `(0, 4096]` | ✓ |
| 11 | `lose_radius_px` | float | `450.0` | `620.0` | `(0, 8192]` 且 `> aggro` | ✓（E-5） |
| 12 | `chase_speed_px_per_sec` | float | `80.0` | `96.0` | `[0, 2048]` | ✓ |
| 13 | `attack_range_px` | float | `64.0` | `88.0` | `[0, 2048]` | ✓ |
| 14 | `ai_poll_interval_sec` | float | `0.20` | `0.2` | `[0.05, 2.0]` | ✓ |
| 15 | `rng_seed` | int | `0` | `20261108` | `[0, 2147483647]` | ✓ |
| 16 | `defeated_flag_key` | String | `""` | `world.boss_01_margit.defeated` | 三段式 flag（**2 号只读**） | ✓ |
| 17 | `death_pose_name` | String | `"death"` | `death` | 非空 | ✓ |
| 18 | `phase_transition_enabled` | bool | `true` | `true` | — | ✓ |

> **max_hp = 3500.0** 为最终值；阶段阈值按此值比例计算 → 转阶段 HP 点 = `3500 × 0.5 = 1750.0`。

---

## 2. 二阶段数值（PhaseData × 2，15 字段逐项核对）

| # | 字段 | 类型 / 默认 | 取值范围 | P1 `phase_01_margit_p1` | P2 `phase_02_margit_p2` | 核对 |
|---|---|---|---|---|---|---|
| 1 | `id` | String `""` | `phase_\d{2}_[a-z0-9_]+` | `phase_01_margit_p1` | `phase_02_margit_p2` | ✓ |
| 2 | `phase_index` | int `1` | `[1,8]`、连续递增 | `1` | `2` | ✓（E-1） |
| 3 | `hp_ratio_enter` | float `1.0` | `(0,1]` | `1.0` | **`0.5`** | ✓ |
| 4 | `hp_ratio_exit` | float `0.0` | `[0,1)` | **`0.5`** | `0.0`（末阶段） | ✓（E-1） |
| 5 | `phase_damage_multiplier` | float `1.0` | `[0.1,10.0]` | `1.0` | **`1.25`** | ✓ |
| 6 | `phase_defense` | float `0.0` | `[0,1e5]`（额外、加算） | `0.0` | `18.0` | ✓ |
| 7 | `sprite_frames_path` | String `""` | `res://...` 或空 | `.../margit_phase1.tres` | `.../margit_phase2.tres` | ✓（仅登记） |
| 8 | `pose_prefix` | String `"p1_"` | 非空、以 `_` 结尾 | `p1_` | `p2_` | ✓ |
| 9 | `moves` | `Array[MoveData]` `[]` | `[1,16]` | 2 招（m1/m2） | 3 招（m1/m2/m3） | ✓ |
| 10 | `poise_override` | PoiseConfig `null` | 可空 | `null`（用 BossData.poise） | `poise_02_margit_p2`（覆盖） | ✓ |
| 11 | `status_resistance_multiplier` | float `1.0` | `[0.1,10.0]` | `1.0` | **`1.35`** | ✓ |
| 12 | `transition_pose_name` | String | 非空 | `phase_transition` | `phase_transition` | ✓ |
| 13 | `transition_frames` | int `48` | `[0,600]` | `48` | `48` | ✓ |
| 14 | `transition_invulnerable` | bool `true` | — | `true` | `true` | ✓ |
| 15 | `aggression` | float `1.0` | `[0.1,5.0]` | `1.0` | `1.4` | ✓ |

**阶段阈值汇总（最终）**

| 量 | 值 | 来源 |
|---|---|---|
| `phase_thresholds` | `[0.5]` | BossData 显式阈值表 |
| P1 → P2 触发 | HP 比例 `< 0.5`（即 HP `< 1750.0`） | `hp_ratio_exit = 0.5` |
| P2 进入 | HP 比例 `≤ 0.5` | `hp_ratio_enter = 0.5` |
| P2 退出 | `0.0`（末阶段，不再转阶段） | `hp_ratio_exit = 0.0` |
| 实际异常阈值 | `(threshold + 累计抗性) × status_resistance_multiplier` | P1 ×1.0 / P2 ×1.35 |
| 实际出招轮询 | `ai_poll_interval_sec / aggression` = P1 `0.20s` / P2 `0.1429s` | PhaseData.aggression |

---

## 3. 三招数值（MoveData × 3，21 字段逐项核对）

### 3.1 完整字段表

| # | 字段 | 默认 / 取值范围 | `move_01_dagger_slash` 短刀横斩 | `move_02_staff_slam` 法杖砸地 | `move_03_holy_hammer` 圣光锤击 | 核对 |
|---|---|---|---|---|---|---|
| 1 | `id` | `""` | `move_01_dagger_slash` | `move_02_staff_slam` | `move_03_holy_hammer` | ✓ |
| 2 | `display_name` | `""` ≤64 字 | `短刀横斩` | `法杖砸地` | `圣光锤击` | ✓ |
| 3 | `pose_name` | `"attack_light"` 非空 | `dagger_slash` | `staff_slam` | `holy_hammer` | ✓ |
| 4 | `startup_frames` | `12` `[0,600]` | **18** | **30** | **42** | ✓ |
| 5 | `active_frames` | `4` `[1,600]` | **5** | **7** | **9** | ✓ |
| 6 | `recovery_frames` | `18` `[0,600]` | **24** | **34** | **40** | ✓ |
| 7 | `motion_multiplier` | `1.0` `[0,100]` | **1.0** | **1.55** | **2.1** | ✓ |
| 8 | `damage_type` | `physical\|fire\|holy\|bleed` | `physical` | `physical` | `holy` | ✓ |
| 9 | `poise_damage` | `0.0` `[0,1e5]` | **22.0** | **45.0** | **70.0** | ✓ |
| 10 | `status_buildup_bleed` | `0.0` `[0,1e5]` | `0.0` | `0.0` | `0.0` | ✓ |
| 11 | `status_buildup_poison` | `0.0` `[0,1e5]` | `0.0` | `0.0` | `0.0` | ✓ |
| 12 | `status_buildup_frost` | `0.0` `[0,1e5]` | `0.0` | `0.0` | **35.0** | ✓ |
| 13 | `hitbox_reach_px` | `64.0` `[0,4096]` | `84.0` | `112.0` | `156.0` | ✓ |
| 14 | `hitbox_arc_deg` | `90.0` `(0,360]` | `100.0` | `120.0` | `150.0` | ✓ |
| 15 | `hitbox_offset_px` | `Vector2.ZERO` | `Vector2(0, 0)` | `Vector2(0, 0)` | `Vector2(0, 0)` | ✓ |
| 16 | `min_range_px` | `0.0` `[0,4096]` | `0.0` | `0.0` | `0.0` | ✓ |
| 17 | `max_range_px` | `96.0` `[min,4096]` | `96.0` | `128.0` | `176.0` | ✓（E-4） |
| 18 | `weight` | `1.0` `[0,1000]` | `3.0` | `1.6` | `1.0` | ✓ |
| 19 | `cooldown_sec` | `0.0` `[0,60]` | `0.6` | `2.2` | `4.0` | ✓ |
| 20 | `can_cancel_frames` | `0` `[0,600]` | `0` | `0` | `0` | ✓（E-3） |
| 21 | `breaks_guard` | `false` | `false` | `false` | `true` | ✓ |

### 3.2 帧时序专项（前摇 / 判定 / 后摇，左闭右开）

> `total_frames` **不设字段**，由 `startup + active + recovery` 派生（schema §3 注、E-2），
> 本表给出派生值供汇总核对；判定区间一律 `[startup, startup + active)`。

| 招式 | 前摇 `startup` | 判定 `active` | 后摇 `recovery` | `total`（派生） | 判定区间 `[start, end)` |
|---|---|---|---|---|---|
| m1 短刀横斩 | 18 帧 | 5 帧 | 24 帧 | `18+5+24 = 47` | `[18, 23)` |
| m2 法杖砸地 | 30 帧 | 7 帧 | 34 帧 | `30+7+34 = 71` | `[30, 37)` |
| m3 圣光锤击 | 42 帧 | 9 帧 | 40 帧 | `42+9+40 = 91` | `[42, 51)` |

### 3.3 招式倍率汇总

| 量 | 值 | 说明 |
|---|---|---|
| 招式倍率 M | `1.0` / `1.55` / `2.1` | MoveData.motion_multiplier |
| 阶段倍率 P | P1 `1.0` / P2 `1.25` | PhaseData.phase_damage_multiplier |
| 攻击力 A | `120.0` | BossData.base_attack |
| 防御 D | `42.0`（P2 额外 +`18.0` = `60.0`） | BossData.base_defense + PhaseData.phase_defense |
| 权重 | `3.0` / `1.6` / `1.0`（P1 仅前两招可抽） | 加权抽取，冷却中权重临时记 0 |

> 数值全在 `.tres` 资源字段内，`.gd` 不出现字面数值参与逻辑（E-9「改数值不改代码」）。

---

## 4. 削韧数值（PoiseConfig × 2 + 招式 poise_damage + 异常触发削韧）

### 4.1 PoiseConfig 字段逐项核对（10 字段）

| # | 字段 | 默认 / 取值范围 | `poise_01_margit_base`（Boss 默认 / P1） | `poise_02_margit_p2`（P2 覆盖） | 核对 |
|---|---|---|---|---|---|
| 1 | `id` | `""` | `poise_01_margit_base` | `poise_02_margit_p2` | ✓ |
| 2 | `max_poise` | `100.0` `(0,1e5]` | **120.0** | **150.0** | ✓ |
| 3 | `poise_regen_per_sec` | `8.0` `[0,1e4]` | `9.0` | `12.0` | ✓ |
| 4 | `poise_regen_delay_sec` | `3.0` `[0,60]` | `3.5` | `2.5` | ✓ |
| 5 | `stance_break_duration_sec` | `2.5` `[0,30]` | `2.5` | `2.0` | ✓ |
| 6 | `stance_break_damage_multiplier` | `1.4` `[1.0,5.0]` | `1.4` | `1.35` | ✓ |
| 7 | `executable` | `true` | `true` | `true` | ✓ |
| 8 | `execute_hp_ratio_threshold` | `0.0` `[0,1]` | `0.0`（不启用该条件） | `0.0` | ✓ |
| 9 | `poise_break_pose_name` | `"stance_break"` 非空 | `stance_break` | `stance_break` | ✓ |
| 10 | `poise_break_frame` | `0` `[0,255]` | `0` | `0` | ✓ |

### 4.2 削韧值汇总

| 来源 | 削韧值 | 说明 |
|---|---|---|
| m1 命中 | `22.0` | MoveData.poise_damage |
| m2 命中 | `45.0` | 同上 |
| m3 命中 | `70.0` | 同上 |
| bleed 触发瞬间 | `25.0` | StatusBuildup.trigger_poise_damage |
| frost 触发瞬间 | `40.0` | 同上 |
| poison 触发瞬间 | `0.0` | 同上 |
| 韧性上限 | P1 `120.0` / P2 `150.0` | 归零触发姿态崩坏 |
| 崩坏窗口额外伤害乘数 | P1 `1.4` / P2 `1.35` | stance_break_damage_multiplier |

---

## 5. 异常积累数值（StatusBuildup × 3 + 招式施加值）

### 5.1 StatusBuildup 字段逐项核对（14 字段）

| # | 字段 | 默认 / 取值范围 | `status_01_bleed` | `status_02_poison` | `status_03_frost` | 核对 |
|---|---|---|---|---|---|---|
| 1 | `id` | `""` | `status_01_bleed` | `status_02_poison` | `status_03_frost` | ✓ |
| 2 | `status_type` | `bleed\|poison\|frost` 不重复 | `bleed` | `poison` | `frost` | ✓（E-8 前半） |
| 3 | `threshold` | `100.0` `(0,1e5]` | **180.0** | **210.0** | **160.0** | ✓ |
| 4 | `decay_per_sec` | `6.0` `[0,1e4]` | `7.0` | `6.0` | `5.0` | ✓ |
| 5 | `decay_delay_sec` | `2.0` `[0,60]` | `2.0` | `2.5` | `2.0` | ✓ |
| 6 | `trigger_damage_ratio` | `0.12` `[0,10]` | `0.12` | `0.0` | `0.08` | ✓ |
| 7 | `trigger_damage_flat` | `0.0` `[0,1e5]` | `0.0` | `40.0` | `0.0` | ✓ |
| 8 | `trigger_poise_damage` | `0.0` `[0,1e5]` | `25.0` | `0.0` | `40.0` | ✓ |
| 9 | `trigger_pose_name` | 非空 | `status_bleed` | `status_poison` | `status_frost` | ✓ |
| 10 | `trigger_frame` | `0` `[0,255]` | `0` | `0` | `0` | ✓ |
| 11 | `duration_sec` | `0.0` `[0,300]` | `0.0`（纯瞬发） | `20.0` | `30.0` | ✓ |
| 12 | `tick_damage_per_sec` | `0.0` `[0,1e4]` | `0.0` | `12.0` | `0.0` | ✓（`duration==0` 时 `tick=0`） |
| 13 | `resistance_gain_per_trigger` | `20.0` `[0,1e4]` | **25.0** | **30.0** | **30.0** | ✓ |
| 14 | `max_resistance` | `300.0` `[0,1e5]` | **330.0** | **360.0** | **320.0** | ⚠ 取值合法，但 E-8 式不满足（见 §6.3 / `E8-裁决建议表.md`） |

### 5.2 异常积累汇总

| 量 | bleed | poison | frost |
|---|---|---|---|
| 基础触发阈值 `threshold` | `180.0` | `210.0` | `160.0` |
| 每次触发抗性增量 | `25.0` | `30.0` | `30.0` |
| 累计抗性上限 `max_resistance` | `330.0` | `360.0` | `320.0` |
| 实际阈值 | `(threshold + 累计抗性) × status_resistance_multiplier`（P1 ×1.0 / P2 ×1.35） | 同左 | 同左 |
| 触发伤害 | `0.12 × max_hp = 420.0` | `flat 40.0` + `20s × 12.0/s = 240.0` | `0.08 × max_hp = 280.0` |
| 招式施加值 | 三招均 `0.0` | 三招均 `0.0` | 仅 m3 `35.0` / 命中 |
| 衰减 | `7.0/s`（延迟 `2.0s`） | `6.0/s`（延迟 `2.5s`） | `5.0/s`（延迟 `2.0s`） |

> 结算顺序（schema §5）：命中 → 按 `MoveData.status_buildup_<type>` 累加 → 重置衰减计时 →
> 若 `积累值 >= 实际阈值` 则触发 → 积累值归零；**触发伤害不再吃招式倍率与阶段倍率**。

---

## 6. 与 `数据表schema.md` 逐项核对

### 6.1 字段集合核对（E-9：字段名 ⊆ schema 字段集合、逐字一致、无多余字段）

| 类 | schema 字段数 | `.tres` 实际字段 | 逐项结论 |
|---|---|---|---|
| BossData | 18 | `id, display_name, max_hp, base_attack, base_defense, phases, phase_thresholds, poise, status_buildups, aggro_radius_px, lose_radius_px, chase_speed_px_per_sec, attack_range_px, ai_poll_interval_sec, rng_seed, defeated_flag_key, death_pose_name, phase_transition_enabled` | 18/18 逐字一致 ✓ |
| PhaseData | 15 | `id, phase_index, hp_ratio_enter, hp_ratio_exit, phase_damage_multiplier, phase_defense, sprite_frames_path, pose_prefix, moves, poise_override, status_resistance_multiplier, transition_pose_name, transition_frames, transition_invulnerable, aggression` | 15/15 逐字一致 ✓ |
| MoveData | 21 | `id, display_name, pose_name, startup_frames, active_frames, recovery_frames, motion_multiplier, damage_type, poise_damage, status_buildup_bleed, status_buildup_poison, status_buildup_frost, hitbox_reach_px, hitbox_arc_deg, hitbox_offset_px, min_range_px, max_range_px, weight, cooldown_sec, can_cancel_frames, breaks_guard` | 21/21 逐字一致 ✓；**未出现 `total_frames` 字段**（schema §3 注要求不设）✓ |
| PoiseConfig | 10 | `id, max_poise, poise_regen_per_sec, poise_regen_delay_sec, stance_break_duration_sec, stance_break_damage_multiplier, executable, execute_hp_ratio_threshold, poise_break_pose_name, poise_break_frame` | 10/10 逐字一致 ✓ |
| StatusBuildup | 14 | `id, status_type, threshold, decay_per_sec, decay_delay_sec, trigger_damage_ratio, trigger_damage_flat, trigger_poise_damage, trigger_pose_name, trigger_frame, duration_sec, tick_damage_per_sec, resistance_gain_per_trigger, max_resistance` | 14/14 逐字一致 ✓ |

> E-9 补充：`.tres` 中不出现任何字面数值参与逻辑（数值只在资源字段内）；`sprite_frames_path`、
> `hitbox_offset_px = Vector2(0, 0)` 等均为资源字段值。→ **E-9 PASS**。

### 6.2 取值范围逐项核对

§1~§5 各表的「取值范围 / 核对」列已对 18 + 15×2 + 21×3 + 10×2 + 14×3 = **171 个字段实例**
逐项核对，全部落在 schema 规定范围内；`id` 命名规范见 §6.4。结论：**取值范围全数合法**。

### 6.3 字段级校验等式 E-1~E-9（schema §9）

| 编号 | 等式 / 约束 | 本表实际 | 结论 |
|---|---|---|---|
| **E-1** | `phase_thresholds[i] == phases[i].hp_ratio_exit`；`phases[i].phase_index == i+1`；`phases[i].hp_ratio_exit == phases[i+1].hp_ratio_enter` | `[0.5] == 0.5`；`1, 2` 连续；`0.5 == 0.5` | **PASS** |
| **E-2** | `total = startup + active + recovery`；判定区间 `[startup, startup+active)` | `47/71/91`；`[18,23)/[30,37)/[42,51)` 无越界、前后摇不重叠 | **PASS** |
| **E-3** | `can_cancel_frames <= recovery_frames` | `0 <= 24/34/40`（三招全 `0`，不可取消） | **PASS** |
| **E-4** | `min_range_px <= max_range_px`；`attack_range_px <= max(moves[*].max_range_px)` | `0 <= 96/128/176`；`88 <= 176` | **PASS** |
| **E-5** | `lose_radius_px > aggro_radius_px` | `620 > 420`（滞回） | **PASS** |
| **E-6** | `PlayerActionData` 8 条状态齐全 / 优先级互异 / `logic_fps` 全等 | **不在本表范围**（属 `player_actions.tres` / M1） | N/A（本表不判定） |
| **E-7** | 玩家动作无敌帧等式 | **不在本表范围**（属 `player_actions.tres` / M1） | N/A（本表不判定） |
| **E-8** | `status_type` 无重复；`threshold + gain × 8 <= max_resistance` | 前半 PASS（bleed/poison/frost 不重复）；后半 **3 项 FAIL**：`380>330` / `450>360` / `400>320` | **FAIL（3 项，待裁决）** → `E8-裁决建议表.md` |
| **E-9** | 字段名 ⊆ schema；无字面数值参与逻辑 | 见 §6.1 / §6.2 | **PASS** |

> E-8 校验式来自 `combat_data_validator.gd:212-213`
> `limit = threshold + resistance_gain_per_trigger * resistance_sample_triggers(=8)`，与 schema §9 E-8 一致。
> **E-1/E-3/E-4/E-5/E-9 通过，E-8 三项 FAIL 属总指挥裁决项，本轮只登记不擅改。**

### 6.4 id 命名规范核对（schema §0.2）

| 类别 | 规范 | 本表 id | 结论 |
|---|---|---|---|
| Boss | `boss_\d{2}_[a-z0-9_]+` | `boss_01_margit` | ✓ |
| 阶段 | `phase_\d{2}_[a-z0-9_]+`，`phase_index` 递增不重复 | `phase_01_margit_p1` / `phase_02_margit_p2` | ✓ |
| 招式 | `move_\d{2}_[a-z0-9_]+`，跨阶段可复用 | `move_01_dagger_slash` / `move_02_staff_slam` / `move_03_holy_hammer`（P1/P2 复用 m1、m2） | ✓ |
| 韧性 | `poise_\d{2}_[a-z0-9_]+` | `poise_01_margit_base` / `poise_02_margit_p2` | ✓ |
| 异常 | `status_\d{2}_[a-z0-9_]+`，`status_type` 与 slug 对应 | `status_01_bleed` / `status_02_poison` / `status_03_frost` | ✓ |
| flag key | `<模块>.<对象>.<状态>`（2 号只读） | `world.boss_01_margit.defeated` | ✓ |

---

## 7. 本轮 grep 实证（实际输出，取自运行权威件）

```
=== 两份 .tres 数值一致性（排除 ext_resource 行后 diff） ===
DIFF_RC=0 → 数值/字段逐字一致，仅 ext_resource 路径不同

=== E-8 运行件数值行 ===
38:status_type = "bleed"      39:threshold = 180.0   49:resistance_gain_per_trigger = 25.0   50:max_resistance = 330.0
55:status_type = "poison"     56:threshold = 210.0   66:resistance_gain_per_trigger = 30.0   67:max_resistance = 360.0
72:status_type = "frost"      73:threshold = 160.0   83:resistance_gain_per_trigger = 30.0   84:max_resistance = 320.0
```

> 与 `R5-待裁决登记.md` §2.5、`COMBAT-ASSEMBLY.md` §5、`DONE-R8.md` §5 登记的
> `180/25/330`、`210/30/360`、`160/30/320` **逐字一致、零改动**。

---

## 8. 待裁决 / 未完成项（只登记，不擅改）

1. **E-8 三项数值冲突**：`380>330` / `450>360` / `400>320`，`CombatDataValidator._ready()` 落位工程根后
   会稳定复现 4 条 `ERROR:`（3 FAIL + 1 汇总）。**裁决建议见 `E8-裁决建议表.md`，本轮不改数值。**
2. **`res://data/schema`（单数） vs `schemas`（复数）口径**：`COMBAT-ASSEMBLY.md` §6.2 登记，
   裁决归总指挥；本轮未改脚本头注释 / 任务书 / schema 文档。
3. **`CombatDataValidator` / `enemy_director.gd` / `player_state_machine.gd` 未落位工程根**：
   `COMBAT-ASSEMBLY.md` §6.7 登记，是否落位待裁决；故本表 E-8 结论来自工位既有件的静态式与历史真跑实证。
4. **历史 signal 去留 / I-2 唯一发射点收敛注释口径**：`COMBAT-ASSEMBLY.md` §6.3 登记。
5. **Q1（`SpriteFrames` 替换 vs `set_pose`）**：本表 `sprite_frames_path` 仅登记，实际阶段动画走 `pose_prefix`。
6. **手感调校 / 渲染与运行时验收**：契约 §5，本表只做数值与字段核对，不调手感、不宣称已渲染可见。

---

## 9. 边界声明

- 本轮新增：**仅本文件**；`godot\data\combat\boss_01_margit.tres` 与工位稿**零改动**（数值行 diff=0）。
- 未写 `project.godot`、其它工位、总线 / 总纲 / 契约 / 台账；未自行 git commit / push。
- 零付费 / 零外部依赖；中文 UTF-8；Godot 4 合法语法（相关 `.gd` 已由 R9 三段门禁 52/52 `--check-only` EXIT=0）。
- 全部数值来自本机实际文件 grep 与逐项核对，**未伪造、未冒充全绿**：E-8 三项 FAIL 如实保留。
