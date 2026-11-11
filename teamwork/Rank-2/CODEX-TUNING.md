# CODEX-TUNING.md · R30 / v0.8.0 赐福图鉴成就数值假设与人工校准手册

> 工位 **Rank-2（战斗系统与数据驱动）**｜命令 `cmd-20261111-125001-351-A2` `[ROUND=R30]`
> 真源：`teamwork/Rank-2/调度任务单-latest.json`｜引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（v4.7.2.stable）
> 定位：**人工试玩校准**用的数值假设表 + condition 语义 + 调参位置 + 「broken」定义。
> 所有首版数值取自任务单 ①，一律标 `[PLACEHOLDER]`，不拍脑袋写死；本文件与 `.tres` / verify 期望常量三者需同步维护。

---

## 0. 一句话口径与文件分工

| 职责 | 文件 | 谁改 |
|---|---|---|
| **数值唯一真源**（4 项成就实例） | `godot/data/rpg/codex_entries.tres` 的 `entries` 数组 | 人工试玩后只改这里 |
| 结构 / condition 白名单 / 求值 / 降级 / 静态类型视图 | `godot/scripts/combat/codex_config.gd`（`class_name CodexConfig`） | Rank-2，不写设计数值 |
| 自测断言（PASS/FAIL/RESULT） | `godot/scripts/combat/verify_codex_reward_v080.gd`（`extends SceneTree`） | Rank-2，校准后同步 `EXPECT_*` |
| 读表 / 订阅 flag / 判定解锁 / 写 `grace.codex_<id>.unlocked` / Tab 面板 | `codex_director.gd` / `hud.gd`（**Rank-1 独占**） | Rank-1，本轮不碰 |
| 图鉴 GDD / 收集留存钩子 | `CODEX-GDD.md`（**Rank-3 独占**） | Rank-3，本轮不碰 |

> 改数值**只改 `.tres`**，不改代码 / 导演层 / 场景 / 素材 / 契约 / README（目录所有权硬约束）。

---

## 1. 四项成就首版数值表（全部 `[PLACEHOLDER]`）

| # | `id`（A36 下划线） | `title` / `description` | `condition_kind` | `condition_value` | `reward_points` |
|---|---|---|---|---|---|
| 1 | `tutorial_complete` | 赐福图鉴·初谒 / 完成赐福引导三步教学，点亮图鉴第一页 | `bool_true` | `{"flag": "grace.tutorial.completed"}` | **30** |
| 2 | `wave_trial_clear` | 赐福图鉴·破阵 / 三波试炼全清，留下第一场完整的胜利记录 | `bool_true` | `{"flag": "dungeon.wave_trial.completed"}` | **50** |
| 3 | `all_grace_upgrades` | 赐福图鉴·满愿 / 解锁全部三项赐福增益，集齐成长分支 | `all_of` | `{"flags": ["grace.upgrade_hp_max_bonus.unlocked", "grace.upgrade_roll_iframe_bonus.unlocked", "grace.upgrade_attack_power_bonus.unlocked"]}` | **80** |
| 4 | `best_wave_3` | 赐福图鉴·登峰 / 最高波次达到 3，抵达试炼顶端 | `int_at_least` | `{"flag": "dungeon.wave_trial.best_wave", "threshold": 3}` | **120** |

- 4 项、奖励 **严格单调递增** `30<50<80<120`、合计 **280**，由 `verify_codex_reward_v080.gd` 断言。
- `condition_kind` **只用既有 flag 语义三态**（`bool_true` / `int_at_least` / `all_of`），不发明新条件类型；4 项覆盖全部 3 种语义。
- 成就解锁 flag 由 Rank-1 按裁决 **A36** 写为三段式 `grace.codex_<id>.unlocked`（`id` 下划线连接，沿用 A23）；本表只产出 `id`，不写 flag、不写场景节点（A35）。

### 逐字段 rationale（为什么是这个值 / 待校准什么）

| 字段 | 类型 | 语义 | 首版来源 | `[PLACEHOLDER]` rationale / 待校准点 |
|---|---|---|---|---|
| `id` | `String` | 成就唯一标识，下划线连接 | 任务单 ① 4 类成就 | 直接用于 A36 的 `grace.codex_<id>.unlocked`；改 id 需同步 Rank-1 订阅与面板文案，不静默改。 |
| `title` / `description` | `String` | 面板显示名称 / 达成说明 | 本轮首版文案 | 纯展示 `[PLACEHOLDER]`，试玩后按可读性 / 本地化校准；不参与任何条件判定或点数计算。 |
| `condition_kind` | `String` | 条件判定语义 | 任务单 ①「既有 flag 语义」 | 白名单 3 态；与 Rank-1 的 4 类成就判定一一对应（教学/三波 = 单 bool，三项增益 = 多 bool 全满足，最高波次 = int 阈值）。**新增 kind 属于改契约，不在本轮授权内**。 |
| `condition_value` | `Dictionary` | 条件参数（只引用既有登记 flag） | 既有三段式 flag 登记表 | 只引用 `REGISTERED_FLAGS`（见 §2），保证「条件可达」；`threshold=3` 与既有三波结构（`best_wave` 理论上限 3）对齐。若后续扩波需同步阈值。 |
| `reward_points` | `int` | 解锁时入账 `grace.trial.points` 的点数 | 任务单 ① 给定 30/50/80/120 | 梯度与达成难度同向递增；合计 280 刻意低于既有单轮三波产出 450，使图鉴是「留存钩子 / 小额补贴」而非第二套点数来源（防 §5 B2 奖励通胀）。与教学 20/30/50、成长成本 100/200/300 同量级校准。 |

---

## 2. condition 语义与「条件可达」保证（只用既有 flag 语义）

| `condition_kind` | `condition_value` 形状 | 求值口径（`CodexConfig.evaluate_condition`） |
|---|---|---|
| `bool_true` | `{"flag": "<三段式 key>"}` | `bool(flags.get(flag, false)) == true` |
| `int_at_least` | `{"flag": "<三段式 key>", "threshold": <int>}` | `int(flags.get(flag, 0)) >= threshold`（阈值非负） |
| `all_of` | `{"flags": ["<key>", ...]}` | 列表非空且**每个** `bool(flags.get(key, false)) == true` |

**只允许引用的既有登记 flag**（`CodexConfig.REGISTERED_FLAGS`，均由既有生产逻辑写入 → 条件可达）：

| flag | 类型 | 写入方（既有） | 用于 |
|---|---|---|---|
| `grace.tutorial.completed` | bool | Rank-1 `tutorial_director.gd`（A26 落地口径） | 成就 1 |
| `dungeon.wave_trial.completed` | bool | Rank-1 `wave_trial_director.gd` | 成就 2 |
| `dungeon.wave_trial.best_wave` | int | Rank-1 `wave_trial_director.gd` | 成就 4 |
| `grace.upgrade_hp_max_bonus.unlocked` | bool | R28 收敛后唯一权威件 | 成就 3（`all_of` 之一） |
| `grace.upgrade_roll_iframe_bonus.unlocked` | bool | 同上 | 成就 3（`all_of` 之一） |
| `grace.upgrade_attack_power_bonus.unlocked` | bool | 同上 | 成就 3（`all_of` 之一） |

- `CodexConfig.is_entry_valid()` 会拒绝：未知 `condition_kind`、`condition_value` 结构非法、引用未登记 flag（**条件不可达**）、`reward_points <= 0`。
- 静态保证 ≠ 运行时保证：verify 用构造的 flags 快照证明 4 项条件「未达成全 false / 达成全 true」；**真实 flag 是否按时写入由 Rank-1 订阅负责**，本轮不越界实现、不谎报已接线。

---

## 3. 代码里的 `[PLACEHOLDER]` 降级基线（**不是设计数值**）

`codex_config.gd` 的 `DEFAULT_*` 常量只在「Dictionary 缺 key / 空表」时兜底，保证不崩、且能被 `is_entry_valid()` 判非法；**不是** §1 的设计值。

| 常量 | 值 | rationale |
|---|---|---|
| `DEFAULT_ID` | `""` | 缺 id 判非法，强制人工补 |
| `DEFAULT_TITLE` | `""` | 缺标题判非法 |
| `DEFAULT_DESCRIPTION` | `""` | 缺描述判非法 |
| `DEFAULT_CONDITION_KIND` | `""` | 空 kind 不在白名单判非法 |
| `DEFAULT_REWARD_POINTS` | `0` | 缺值不发点数，避免凭空通胀 |

降级路径：`entry_from_dict(d)` 对缺 key / 类型异常回落到上述基线；`get_entry(index)` 越界返回 `null`、行类型异常返回非法空视图；空表 `get_entry(0)` 返回 `null` 不崩。均由 verify「空表/字段缺失降级」断言覆盖。

---

## 4. 调参唯一入口 + 同步清单

1. **改数值**：编辑 `godot/data/rpg/codex_entries.tres` 的 `entries`（4 个 Dictionary，各 6 个 key）。改完真跑 `verify_codex_reward_v080.gd`。
2. **改结构 / 求值 / 降级 / 合法性**：编辑 `godot/scripts/combat/codex_config.gd`（不写设计数值）。
3. **校准后必须同步四处**：`.tres` 数值 → `verify_codex_reward_v080.gd` 的 `EXPECT_IDS / EXPECT_KINDS / EXPECT_REWARDS / EXPECT_TOTAL / EXPECT_THRESHOLD / EXPECT_FLAG_KEYS` → 本文 §1 与 §5 阈值 → `DONE-R30.md`。**不静默改数**。
4. **新增 `class_name` / 改 `.tres` 后必须** `--headless --import` 重新注册，再跑三段门禁。
5. **不碰**：Rank-1 `codex_director.gd` / `hud.gd` / `presentation.gd` / `verify_codex_v080.gd`、Rank-3 `CODEX-GDD.md` / 契约 / README、`courtyard.tscn` / 素材 / shader / `project.godot` / 其余 `.tres`（目录所有权）。

---

## 5. 「broken」定义（人工试玩校准判据）

| # | 现象（试玩观测） | 判定 | 优先回调动作 |
|---|---|---|---|
| B1 | **门槛过高**：合理游玩时长内 4 项成就仍解锁寥寥；例如 `best_wave_3` 需反复刷多局才到 3、`all_grace_upgrades` 需 600 点成长成本远超单轮 450 产出 | **成就门槛过高** | 下调 `int_at_least` 的 `threshold`（当前 3，与三波上限对齐，不宜低于 3 否则与 `wave_trial_clear` 重叠）；或复核既有 `grace_upgrades.tres` 的 `cost`（Rank-2 表，须协调整改）；不靠改 `condition_kind` 绕过。 |
| B2 | **奖励通胀**：图鉴 280 点相对既有三波 450 产出过大，或 4 项一次性全领使点数产出快于兑换消耗、成长曲线失衡 | **奖励失衡** | 下调 `reward_points` 梯度（30/50/80/120），**保持严格单调递增**（verify 硬断言）；不得回滚已入账 `grace.trial.points`（只增不减铁律），只调表。 |
| B3 | **条件不可达**：某成就永远无法解锁 —— `condition_value` 引用了未登记 / 永不写入的 flag、`threshold` 超过 `best_wave` 理论上限、`all_of` 含不存在的 upgrade id | **条件定义错误** | 修 `.tres` 的 `condition_value` 回到 `REGISTERED_FLAGS` 白名单内；`threshold` 不超过既有波数；`all_of` 子项与 `grace_upgrades.tres` 的 3 个 id 逐字对齐。由 `is_entry_valid()` + verify「引用既有登记 flag / 三段式正则」静态拦截，运行时再靠 Rank-1 订阅。 |
| B4 | **重复领取**：同一 `id` 多次达成 / 多次触发导致 `grace.trial.points` 二次累加、commit 二次落盘、余额异常 | **防刷铁律被破坏** | 保持 `_claimed` 幂等 + 条件单向 + `commit` 先落盘（`stage_flags → disk_write → runtime_update`）；失败操作不写 points、不置位、不 commit。由 verify「重复领取拒绝 / commit 先落盘 / points 只增不减 / 余额非负」断言覆盖。 |

补充说明（如实边界，不冒充）：

- **四类 broken 的观测阈值本身也是 `[PLACEHOLDER]`**："合理游玩时长""产出快于消耗"需人工试玩定量，本文只给判据与回调方向，不写死时长数字。
- **verify 只校验数据合法性 / 条件求值 / 奖励账务 / 防刷**，**不测运行时 flag 是否真实写入**（归 Rank-1 `codex_director.gd` 订阅）、不测面板可读性（归 Rank-1 Tab 面板 + Rank-4 录屏目视）、不测画面（归 Rank-4 capture）。
- `reward_points` **严格单调递增**是 verify 硬断言；若校准需要破坏单调性，先改 verify 与本文口径再改数。
- 本轮只交付**数据表 + 数值假设 + 代码级自测**，**人工试玩手感与审美判断由用户侧完成**（契约 §5 / 总纲），本文件不冒充已完成试玩校准。

---

## 6. 与既有系统的关系（零字段重名 / 零脚本改动）

- **点数账户**：图鉴奖励与既有教学 `reward_points`（20/30/50）、三波 `reward_points`（100/150/200）共用**同一个** `grace.trial.points`；教学表与波次表的 `reward_points` 是**同名不同语义域**，图鉴是第三个语义域，引用时须区分（沿用 WAVE-TRIAL-GDD §10.7 T-V6 校对口径）。
- **余额**：`balance = grace.trial.points - grace.trial.spent_points`，复用 `GraceUpgradeService.balance()`；图鉴奖励只增 `points`、绝不回退 / 绝不 `removals`。
- **成长成本**：`all_of` 引用的 3 个 `grace.upgrade_<id>.unlocked` 是 R28 双写收敛后的唯一权威件（兼容读取 `legacy_bought_flag_key`），与 `grace_upgrades.tres` 的 `hp_max_bonus / roll_iframe_bonus / attack_power_bonus` 逐字对齐。
- **flag 正则**：所有引用 key 均匹配 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`，`world_state.gd` 无需修改、无需迁移、不改 `schema_version`。
