# WAVE-TRIAL-TUNING.md · R26 / v0.4.0 波次试炼数值假设与人工校准手册

> 工位 **Rank-2（战斗系统与数据驱动）**｜命令 `cmd-20261111-073556-923-A2` `[ROUND=R26]`
> 真源：`teamwork/Rank-2/调度任务单-latest.json`｜引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（v4.7.2.stable）
> 定位：**人工试玩校准**用的数值假设表 + 调参位置 + 「broken」定义。所有首版数值取自任务单 ②，一律标 `[PLACEHOLDER]`，不拍脑袋写死；本文件与 `.tres` / verify 期望常量三者需同步维护。

---

## 0. 一句话口径与文件分工

| 职责 | 文件 | 谁改 |
|---|---|---|
| **数值唯一真源**（3 波实例） | `godot/data/rpg/wave_trial.tres` 的 `waves` 数组 | 人工试玩后只改这里 |
| 结构 / 降级 / 合法性 / 静态类型视图 | `godot/scripts/combat/wave_trial_config.gd`（`class_name WaveTrialConfig`） | Rank-2，不写设计数值 |
| 生成 + `CACHE_MODE_IGNORE` 回读校验 | `teamwork/Rank-2/build_wave_trial_v040.gd`（`extends SceneTree`） | Rank-2 |
| 自测断言（PASS/FAIL/RESULT） | `godot/scripts/combat/verify_wave_trial_v040.gd`（`extends SceneTree`） | Rank-2，校准后同步 `EXPECT_*` |
| 读表 / 组织战斗 / 波次 HUD | `wave_trial_director.gd` 等（**Rank-1 独占**） | Rank-1，本轮不碰 |

> 改数值**只改 `.tres`**，不改代码 / 导演层 / 场景 / 素材 / 契约 / README（目录所有权硬约束）。

---

## 1. 三波首版数值表（全部 `[PLACEHOLDER]`）

| 波 | `enemy_id`（复用既有） | `hp_multiplier` | `move_weight` | `reward_points` | `telegraph_sec` | `time_limit_sec` |
|---|---|---|---|---|---|---|
| 1 | `enemy_01_limgrave_soldier` | **1.0** | 1.0 | **100** | 1.5 | 30.0 |
| 2 | `enemy_01_limgrave_soldier` | **1.3** | 1.0 | **150** | 1.5 | 30.0 |
| 3 | `boss_01_margit` | **1.6** | 1.0 | **200** | 1.5 | 30.0 |

- 3 波、hp 与 reward **严格单调递增**（`1.0<1.3<1.6`、`100<150<200`），由 `verify_wave_trial_v040.gd` 断言。
- 敌人 id 复用 `godot/data/combat/enemy_01_limgrave_soldier.tres`（`id="enemy_01_limgrave_soldier"`）与 `godot/data/combat/boss_01_margit.tres`（`id="boss_01_margit"`），**不新增任何数据表**（verify 会 `load()` 这两张表证明存在）。

### 逐字段 rationale（为什么是这个值 / 待校准什么）

| 字段 | 类型 | 语义 | 首版来源 | `[PLACEHOLDER]` rationale / 待校准点 |
|---|---|---|---|---|
| `enemy_id` | `String` | 该波沿用的既有敌人表 id | 任务单 ② 指定复用两表 | 编排假设「杂兵 → 杂兵 → Boss 压轴」；试玩若节奏不对可改编排（例如第 2 波换精英），但**只能用既有 id**。 |
| `hp_multiplier` | `float` | 乘在既有敌人 `max_hp` 上的倍率 | 任务单 ② 给定 1.0 / 1.3 / 1.6 | `1.0` 是恒等基线（不放大也不削弱既有数值），`1.3`/`1.6` 造递增压力曲线；梯度本身待试玩校准，判据见 §4「难度过高 / 过低」。 |
| `move_weight` | `float` | 该波招式加权抽取权重 | 任务单 ② **未给具体值** | 取 `1.0` 等权基线，与既有 `MoveData.weight=1.0` 口径同源；这是**纯假设**，试玩按 Boss/杂兵出招频率再校准，不把 1.0 当定论。 |
| `reward_points` | `int` | 清波奖励点数 | 任务单 ② 给定 100 / 150 / 200 | 与 hp 梯度同向递增，让「越难越值钱」；若出现点数通胀按 §4 回调。 |
| `telegraph_sec` | `float` | 波次级出招前摇 / 预警秒数 | 任务单 ② 给定 1.5 | 与既有 `MoveData.startup_frames`（60fps 下约 0.2s 的单招起手）**量纲不同**：本表是波次预警窗口，不是单招帧数；待试玩按「看得清、来得及躲」校准。硬约束：`>0` 且 `< time_limit_sec`（verify 校验）。 |
| `time_limit_sec` | `float` | 单波时限秒数 | 任务单 ② 给定 30 | §4「首波 30 秒打不完」的阈值就是它；调本值即调 broken 阈值，需同步本文与 verify。 |

---

## 2. 代码里的 `[PLACEHOLDER]` 降级基线（**不是设计数值**）

`wave_trial_config.gd` 的 `DEFAULT_*` 常量只在「Dictionary 缺 key / 空表」时兜底，保证不崩、且能被 `is_wave_valid()` 判非法；**不是**上表的设计值。

| 常量 | 值 | rationale |
|---|---|---|
| `DEFAULT_ENEMY_ID` | `""` | 缺 id 判非法，强制人工补，绝不静默塞一个敌人进去 |
| `DEFAULT_HP_MULTIPLIER` | `1.0` | 恒等，缺值不放大也不削弱 |
| `DEFAULT_MOVE_WEIGHT` | `1.0` | 等权，与 `MoveData.weight` 同口径 |
| `DEFAULT_REWARD_POINTS` | `0` | 缺值不发点数，避免凭空通胀 |
| `DEFAULT_TELEGRAPH_SEC` | `1.5` | 首版前摇 `[PLACEHOLDER]`，待试玩 |
| `DEFAULT_TIME_LIMIT_SEC` | `30.0` | 首版时限 `[PLACEHOLDER]`，待试玩 |

降级路径：`wave_from_dict(d)` 对缺 key / 类型异常回落到上述基线；`get_wave(index)` 越界返回 `null`；空表 `get_wave(0)` 返回 `null` 不崩。均由 verify「空表/字段缺失降级」断言覆盖。

---

## 3. 调参位置（唯一入口 + 同步清单）

1. **改数值**：编辑 `godot/data/rpg/wave_trial.tres` 的 `waves`（3 个 Dictionary，各 6 个 key）。改完真跑 `verify_wave_trial_v040.gd`。
2. **改结构 / 降级 / 合法性**：编辑 `godot/scripts/combat/wave_trial_config.gd`（不写设计数值）。
3. **从构建脚本重建 `.tres`**（仅在需要时）：
   `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script F:/Game/aierdengfahuan/teamwork/Rank-2/build_wave_trial_v040.gd`
   ⚠ 会**覆盖**手写改动，重建后需重新核对 §1 数值表。
4. **校准后必须同步三处**：`.tres` 数值 → `verify_wave_trial_v040.gd` 的 `EXPECT_IDS/EXPECT_HP/EXPECT_REWARD/EXPECT_TELEGRAPH_SEC/EXPECT_TIME_LIMIT_SEC/EXPECT_MOVE_WEIGHT` → 本文 §1 与 §4 阈值。**不静默改数**。
5. **不碰**：Rank-1 `wave_trial_director.gd` / `courtyard.tscn` / 波次 HUD / `00-协作契约.md` / `README.md` / `project.godot` / 既有 `.tres`（目录所有权）。

---

## 4. 「broken」定义（人工试玩校准判据）

| # | 现象（试玩观测） | 判定 | 优先回调动作 |
|---|---|---|---|
| B1 | **首波 30 秒打不完**：`time_limit_sec` 到点仍有第 1 波敌人存活 | **难度过高** | 先下调第 1 波 `hp_multiplier`（1.0 已是恒等下限，可改 `enemy_id` 为更弱敌人，或复核既有 `max_hp` 是否偏高）；必要时上调 `time_limit_sec`，并同步 verify 与本文 §1。 |
| B2 | **三波全清 < 15 秒**：总用时远低于 3×时限 | **难度过低** | 上调 `hp_multiplier` 梯度 / `move_weight`（出招更凶）；或下调 `time_limit_sec` 收紧窗口。 |
| B3 | **点数通胀**：清波奖励产出远快于消耗 / 兑换速度，排行或经济失衡 | **奖励失衡** | 下调 `reward_points` 梯度（100/150/200）；检查奖励递增是否与 hp 递增失配。 |

补充说明（如实边界，不冒充）：

- **15 秒 / 30 秒阈值本身也是 `[PLACEHOLDER]`**，来自任务单 broken 定义；若试玩后目标节奏变化，需同步更新本文与 verify（verify 当前**只校验数据合法性与单调性，不测这两个时长** —— 时长属运行时 HUD / 导演层观测，归 Rank-1 记录，本轮不越界实现）。
- B1 的「30 秒」= 本表 `time_limit_sec`；调时限即调阈值，二者联动。
- `hp_multiplier` 与 `reward_points` 的**单调递增**是 verify 硬断言；若校准需要破坏单调性，先改 verify 与本文口径再改数。
- 本轮只交付**数据表 + 数值假设 + 代码级自测**，**人工试玩手感与审美判断由用户侧完成**（契约 §5 / 总纲），本文件不冒充已完成试玩校准。

---

## 5. 技术口径记录：为什么是 `Array[Dictionary]` + 运行时 `WaveData` 视图

R26 首次真跑实证（证据：`teamwork/Rank-2/R26-build-run.log` 首版两轮与首版 `wave_trial.tres` 第 5 行）：

- Godot **4.7.2** 把「内部类」Resource 实例序列化进 `.tres` 时，内部类脚本会退化成**空的 `[sub_resource type="GDScript" id="GDScript_..."]`**（无源码、不指向内部类），回读实例丢脚本类，`as WaveData` 全部为 `null`。
- 且 `@export var waves: Array[WaveData]`（内部类作类型化数组元素类型）回读时报
  `Attempted to assign an object into a TypedArray, that does not inherit from 'GDScript'`，数组被丢空。
- 即使改成 `Array[Resource]`，数组长度回读正确，但元素仍因上述空 GDScript 子资源无法 cast 回 `WaveData`。

故按任务单「**可用 Array[Dictionary] 或自定义 Resource 子类**」采用：

- **存储层** `@export var waves: Array[Dictionary]`（类型化数组，`.tres` 每行一个 Dictionary，6 个 key）；
- **运行时视图** `class WaveData extends Resource`（6 个 `@export` 全静态类型字段），由 `get_wave()` / `wave_from_dict()` 在**运行时**从 Dictionary 构造，不参与 `.tres` 序列化；
- **全静态类型**：`@export` 字段 / 常量 / 方法参数与返回值全部显式类型标注；数组为类型化 `Array[Dictionary]`；
- **兼容导演层两种读法**：`cfg.waves[i]["hp_multiplier"]`（Dictionary 直读）与 `cfg.get_wave(i).hp_multiplier`（WaveData 视图），`WaveData` 亦支持 `view["hp_multiplier"]`（`Object.get`）；
- **数据驱动**：设计数值只在 `.tres`，代码零硬编码设计值。

> 这是对引擎 4.7.2 内部类序列化限制的**实测适配**，不是降低要求：字段、类型、三波结构、降级与校验一项不少。

---

## 6. 真跑校验入口（命令）

```bash
ENGINE="D:/Godot/Godot_v4.7.2-stable_win64.exe"
PROJ="F:/Game/aierdengfahuan/godot"

# ① 注册新增 class_name（新增 WaveTrialConfig 后必须先跑，否则其它脚本解析不到）
"$ENGINE" --headless --path "$PROJ" --import

# ② 构建 + CACHE_MODE_IGNORE 回读（返回 RESULT=BUILT_AND_VERIFIED）
"$ENGINE" --headless --path "$PROJ" --script \
  "F:/Game/aierdengfahuan/teamwork/Rank-2/build_wave_trial_v040.gd"

# ③ 自测（返回 RESULT=ALL_MATCH）
"$ENGINE" --headless --path "$PROJ" --script \
  res://scripts/combat/verify_wave_trial_v040.gd

# ④ 三段门禁：--check-only --script → --headless --quit，逐段 grep SCRIPT ERROR=0
```

---

## 7. 未完成项 / 如实边界

- 人工试玩校准（B1/B2/B3 实测判定）**未执行**，属用户侧；本文只给出判据与调参入口。
- `move_weight` 的任务单未给值，首版 `1.0` 是明确标注的 `[PLACEHOLDER]` 假设，**不是**定论。
- `telegraph_sec` 与既有 `MoveData.startup_frames` 的换算关系（波次预警 vs 单招起手）尚未由导演层实接验证，Rank-1 接线后需复核。
- 未改任何 Rank-1 / Rank-3 / Rank-4 文件，未自行 `git`，零付费、零外部依赖。
