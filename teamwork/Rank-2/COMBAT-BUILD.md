# COMBAT-BUILD.md —— R3 三段构建门禁真跑结论 +「改数值不改代码」校验清单

> 2 号工位 · 战斗系统与数据驱动 · R3 交付件（任务书-R3.md §2 / §3）。
> 中文 UTF-8。唯一写入 `Rank-2\`。**本文件所有数字均为本机真跑 / 机器化校验的实际输出，不引用旧结论冒充、不伪造。**

---

## 0. 结论速览

- **三段门禁真跑 PASS**：引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`），`--version` / `--headless --import` / 9 个 `--check-only --script` / `--headless --quit` **全部 EXIT=0**；全日志（49 行）grep `SCRIPT ERROR` 等错误关键词 **0 命中**。
- **`.tres` 校验 PASS**：3 份 `.tres` 的 `load_steps` 与 ext/sub 资源数全部自洽、悬空引用 0、字段越界 0。
- **8 个 Resource 类脚本 PASS**：7 类 119 行 `@export` 与 `数据表schema.md` §1~§7 **逐字一致**；`SpawnRequest` 17 字段与 Rank-3《接口契约.md》§3 / R2 规格件**逐字一致**。
- **「改数值不改代码」PASS**：全仓 `.gd` 的 `const` 仅 2 处 `MIN_DAMAGE: float = 1.0`；4 个逻辑脚本代码体去注释后**数据表特征数值硬编码 0 命中**；全部实例数值落在 3 份 `.tres`。
- **如实登记的阻塞**：本机 `D:\godogen_assets\motion\` 无预置 `rootmotion.json` 实例、未实跑 `gen-moves`/`add-moves` 生成本作 clip（见 §7、`motion-mapping.md` §6）；`res://data/schema/`（任务书单数）与 `res://data/schemas/`（真源复数）口径差异待 HOST 裁决；I-2 `GameEvents` autoload 挂载偏差为 R2 遗留项。

---

## 1. 真跑环境（任务书 §3 / 契约 §10）

| 项 | 值 |
|---|---|
| 引擎 | `D:\Godot\Godot_v4.7.2-stable_win64.exe`，`--version` 实测 `4.7.2.stable.official.ed1daf0bf` |
| 临时工程 | 系统临时目录 `C:\Users\62668\AppData\Local\Temp\r3_gate_a2\`（**不在 teamwork 内、不提交、收尾即删**） |
| `project.godot` | `config_version=5`，`run/main_scene="res://main.tscn"`（经 `--import` 实测接受，无版本报错） |
| `main.tscn` | `load_steps=4` = 3 个 `ext_resource`（3 份 `.tres`）+ 1；最小场景，声明 3 份 `.tres` 为场景依赖以供引擎实际加载 |
| 平铺布局 | `res://data/schemas/*.gd`（9 个：R3 新增 8 个 + R2 配套 `player_action_table.gd` 复制件）、`res://data/{bosses,enemies,player}/*.tres`（3 份） |
| 未做 | 未写任何探针 / 测量 / preflight 脚本；`main.tscn` 是最小场景配置、非脚本；未运行 `gen3d`/`mia-rig`、未碰 WSL、零付费 |

> 段 2 的 9 个脚本中，`boss_data / phase_data / move_data / poise_config / status_buildup / enemy_data / player_action_data / spawn_request` 为 **R3 新增交付件**；`player_action_table.gd` 是 R2 既有 `schema_player_action_table.gd` 的**只读复制**（供 `player_actions.tres` 的 `script_class="PlayerActionTable"` 解析），**不重做、不改动 R2 原件**。

---

## 2. 三段门禁 · 实际输出结论

### 2.1 命令与退出码

| 段 | 命令 | 退出码 | 结论 |
|---|---|---|---|
| 0 | `Godot_v4.7.2-stable_win64.exe --version` | **0** | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `... --headless --path <gate> --import` | **0** | 首次扫描 5 步 DONE；注册 9 个全局类 DONE；加载编辑器 DONE |
| 2 | `... --headless --path <gate> --check-only --script res://data/schemas/<各 .gd>`（9 个） | **9/9 = 0** | 全部解析通过 |
| 3 | `... --headless --path <gate> --quit` | **0** | 打开工程、加载 `main.tscn` 及 3 份 `.tres` 场景依赖后退出 |

段 2 的 9 个脚本：`data/schemas/{boss_data,phase_data,move_data,poise_config,status_buildup,enemy_data,player_action_data,spawn_request,player_action_table}.gd`。

### 2.2 各段日志要点（原始输出摘录）

- 段 1 `--import`：
  ```
  [ DONE ] first_scan_filesystem            (5 steps)
  [   0% ] update_scripts_classes | Started 正在注册全局类…… (9 steps)
  [   0% ] BossData / EnemyData / MoveData / PhaseData / PlayerActionData /
           PlayerActionTable / PoiseConfig / SpawnRequest / StatusBuildup
  [ DONE ] update_scripts_classes
  [ DONE ] loading_editor_layout
  ```
  **9 个 class_name 全部注册成功**；无 `ERROR` / `SCRIPT ERROR`。
- 段 2：9 次启动的日志均只有 `Godot Engine v4.7.2...` 版本头，无解析报错。
- 段 3 `--quit`：日志仅一行版本头，无报错（**未复现 R2 首轮「无 main_scene 不退出」问题**，因本轮 `project.godot` 已声明 `run/main_scene`）。

### 2.3 `SCRIPT ERROR` grep 结果（契约 §10 / 工具链 §4.2 要求：必须 grep，不以退出码冒充通过）

把 4 段日志合并为 `log_all.txt`（共 **49 行**）后执行：

```
grep -nEi "SCRIPT ERROR|Parse Error|ERROR:|Failed|Cannot|dangling|悬空|Invalid|not found|Can't" log_all.txt
```

**结果：0 命中**（grep RC=1 = 无匹配）。逐项：`SCRIPT ERROR` 0、`Parse Error` 0、`ERROR:` 0、`Failed` 0、`Cannot` 0、`dangling`/`悬空` 0、`Invalid` 0、`not found` 0、`Can't` 0。
按工具链 §4.2「运行时 `SCRIPT ERROR` 只中断当前函数、退出码仍为 0」的口径，**本轮以 grep 结果为准判定通过**。

---

## 3. `.tres` 校验：`load_steps` / ext-sub 自洽 / 悬空引用 / 字段一致

任务书 §2 要求本轮对 `boss_01_margit.tres` 等做校验（R2 产出的 `.tres` 本轮**只读不改**）。

### 3.1 `load_steps` 与 ext/sub 资源数自洽（Grep 工具 count 模式实测）

| `.tres` | `load_steps` | `ext_resource` | `sub_resource` | 期望 `ext+sub+1` | 结论 |
|---|---|---|---|---|---|
| `boss_01_margit.tres` | **16** | **5** | **10** | 16 | **PASS** |
| `player_actions.tres` | **11** | **2** | **8** | 11 | **PASS** |
| `enemy_01_limgrave_soldier.tres` | **7** | **4** | **2** | 7 | **PASS** |

### 3.2 悬空引用差集（refs − declared，Bash 内联校验）

| `.tres` | 声明 id 数 | 被引用 id 数 | `dangling` |
|---|---|---|---|
| `boss_01_margit.tres` | 15（5 ext + 10 sub） | 15 | **0** |
| `player_actions.tres` | 10（2 ext + 8 sub） | 10 | **0** |
| `enemy_01_limgrave_soldier.tres` | 6（4 ext + 2 sub） | 6 | **0** |

所有 `ExtResource("...")` / `SubResource("...")`（含 `Array[ExtResource(...)]` 类型化数组标注）逐一比对声明：**未声明引用 0、悬空引用 0**。`phase_01.poise_override = null`、`status_buildups` 类型化空数组均为合法写法。

### 3.3 `.tres` 字段键 ⊆ schema 字段集（E-9）

字段全集 = R3 8 个类的 101 个唯一 `@export` 字段名 + R2 配套 `PlayerActionTable.actions` = **102**（与 DONE-R2.md §2.4 的 102 一致）。排除 Godot 内建 `script` 后：

| `.tres` | 唯一键数 | 越界字段名 |
|---|---|---|
| `boss_01_margit.tres` | 74 | **0** |
| `player_actions.tres` | 26 | **0**（`actions` 属 `PlayerActionTable` 容器，已纳入字段全集） |
| `enemy_01_limgrave_soldier.tres` | 46 | **0** |

---

## 4. 8 个 Resource 类脚本字段与唯一真源逐字一致

| 校验 | 方法 | 实际输出 | 结论 |
|---|---|---|---|
| 7 类 vs `数据表schema.md` §1~§7 | 抽文档代码块 119 行 `@export` 与 R3 7 个脚本 119 行做规范化 diff | 行数 119 = 119，**diff 无差异** | **逐字一致 PASS** |
| `SpawnRequest` vs Rank-3 §3 / R2 规格件 | 17 行 `@export` 规范化 diff | 行数 17 = 17，**diff 无差异** | **逐字一致 PASS（17 字段）** |
| R3 schema 纯度 | 8 个脚本 `func` 定义数 | **0**（无函数体，仅 `@export` 字段声明） | 纯数据规格件 PASS |

> `SpawnRequest` 说明：`数据表schema.md` §8 的 10 字段是「2 号消费侧最小字段假设、不主张定义权」；按任务书-R3 §4 / 用户指令 I-3 / R2 口径 §6 第 4 条，**以 Rank-3《接口契约.md》§3 的 17 字段为唯一定义**，本轮照此落地，差异已在各脚本头注释与 `DONE-R3.md` 登记。

---

## 5.「改数值不改代码」校验清单

### 5.1 表驱动字段清单（**只允许出现在 `.tres` 资源实例里，GDScript 不得硬编码**）

| 类别 | 表驱动字段（逐项） | 数值实例所在 `.tres` |
|---|---|---|
| 伤害公式 A/M/P/S/D | `base_attack`、`base_defense`、`motion_multiplier`、`phase_damage_multiplier`、`phase_defense`、`stance_break_damage_multiplier`、`base_attack`（PlayerActionData） | boss / enemy / player_actions |
| 生命 / 阶段阈值 | `max_hp`、`phase_thresholds`、`hp_ratio_enter`、`hp_ratio_exit`、`execute_hp_ratio_threshold`、`status_resistance_multiplier` | boss / enemy |
| 韧性 / 处决 | `max_poise`、`poise_regen_per_sec`、`poise_regen_delay_sec`、`stance_break_duration_sec`、`poise_damage`、`execute_hp_ratio_threshold` | boss / enemy / player_actions |
| 异常积累 | `threshold`、`decay_per_sec`、`decay_delay_sec`、`trigger_damage_ratio`、`trigger_damage_flat`、`trigger_poise_damage`、`duration_sec`、`tick_damage_per_sec`、`resistance_gain_per_trigger`、`max_resistance`、`status_buildup_{bleed,poison,frost}` | boss / enemy / player_actions |
| 帧 / 判定区间 | `startup_frames`、`active_frames`、`recovery_frames`、`invulnerable_start_frame`、`invulnerable_end_frame`、`transition_frames`、`can_cancel_frames`、`cancel_window_frames`、`pose_frame_offset`、`poise_break_frame`、`trigger_frame`、`logic_fps` | 全部 3 份 |
| 距离 / 半径 / 速度 | `aggro_radius_px`、`lose_radius_px`、`attack_range_px`、`chase_speed_px_per_sec`、`hitbox_reach_px`、`hitbox_arc_deg`、`hitbox_offset_px`、`min_range_px`、`max_range_px`、`move_speed_px_per_sec` | 全部 3 份 |
| 权重 / 冷却 / 种子 / 频率 | `weight`、`cooldown_sec`、`rng_seed`、`aggression`、`ai_poll_interval_sec`、`state_priority`、`stamina_cost` | 全部 3 份 |

派生规则（代码只做派生、不存数值）：`total_frames = startup + active + recovery`（**不设字段**）；判定区间 `[startup, startup + active)`、无敌区间 `[invulnerable_start_frame, invulnerable_end_frame)` 左闭右开（E-2 / E-7）。

### 5.2 禁止硬编码项 + 本轮实测

| 禁止项 | 允许的唯一例外 | 实测结果 |
|---|---|---|
| 逻辑代码里出现战斗数值字面量（如 `3500` / `420` / `2.1` / `1.65` / `1.55` / `20261108` / `620` / `260` / `168` 等） | `MIN_DAMAGE = 1` 类**下限常量** | 全仓 `.gd` 的 `const` **仅 2 处**：`combat_resolver.gd:20`、`player_state_machine.gd:42` 的 `const MIN_DAMAGE: float = 1.0`；4 个逻辑脚本**去注释后代码体**特征数值命中 **0** → **PASS** |
| 把数值写进 `schema/*.gd`（除 `@export` 默认值 / 类型外） | — | R3 8 个脚本 `func` 定义数 0，仅 `@export` 字段声明 + 默认值 → **PASS** |
| 在 `.tres` 里写脚本 / 表达式逻辑 | — | 3 份 `.tres` 数值全部是资源字段值（带数值字段行：boss 125 / player_actions 153 / enemy 34 行），无内联逻辑 → **PASS** |
| 双源不一致（`total_frames` 单列字段、无敌区间与 active 不对齐） | — | 由表字段派生；`action_04_roll` 无敌 `[4,13)` == `[startup, startup+active)` `[4,13)`（`4/9/9=22`、E-7 对齐；R19 裁决 / R20 回归同步） → **PASS** |

> 结论：**数值全部留在表里**；调平衡只改 `.tres` 的上述字段，不改任何 `.gd`（「改数值不改代码」核心验收达成）。

---

## 6. R2 口径 §6（I-1 / I-2 / I-3 / I-4）核对

| 编号 | 口径 | R3 核对结果 |
|---|---|---|
| I-1 | 只用 `WorldState.get_flag(key, default)` / `set_flag(key, value)`，调用方自行 cast | R3 新增 8 个 Resource 类为**纯数据规格件、无任何函数调用**，不涉及 flag 读写；沿用 `DONE-R2.md` §2.5 结论（`player_state_machine.gd` / `enemy_director.gd` 均双参调用、已删兼容分支），本轮未改 R2 逻辑件 |
| I-2 | 信号统一挂 `GameEvents` autoload、参数单个 `String`、击杀 flag 只由 Rank-3 写、2 号不双写 | R3 新增件不含信号定义，**不新增偏差**；`enemy_defeated/boss_defeated` 参数单个 `String`、`.defeated` flag 硬拦截、只发信号不双写均符合 R2 结论；**遗留偏差**：2 号现有交付件把信号定义在 `PlayerStateMachine` 节点自身、未显式挂 `GameEvents` autoload —— 按 HOST「已有交付件不重做」未改，登记为集成收口 / 待裁决（见 `DONE-R3.md` §4） |
| I-3 | `SpawnRequest` 17 字段以 Rank-3《接口契约.md》§3 为唯一定义 | **符合**：R3 `schema/spawn_request.gd` 17 字段与 Rank-3 §3 表 / R2 规格件逐字一致（§4）；文件头明确定义权归 3 号、落完整工程时 2 号不重复挂载同名全局类 |
| I-4 | 只调 `set_pose()`，pose 名按冻结表加 `p1_`/`p2_` 前缀 | R3 新增件只声明 `pose_name` / `pose_prefix` / `*_pose_name` 字段、**不调用 `set_pose()`**；沿用 R2：`player_state_machine.gd` / `enemy_director.gd` 仅 2 处调用、Boss 阶段 `p1_`/`p2_` 前缀拼接、不写 billboard / 锚定 / 缩放 / `SpriteFrames` |

---

## 7. 未完成项与阻塞（如实登记，详见 `DONE-R3.md` §4）

1. **`rootmotion.json` 无预置实例、未生成本作 clip**：映射见 `motion-mapping.md`，为字段契约映射，非真跑产物；`gen3d`/`mia-rig` 本机不可用、不补装、不碰 WSL（任务书 §4）。
2. **路径口径差异待 HOST 裁决**：任务书-R3 §2 字面 `res://data/schema/`（单数）与 `数据表schema.md` §0.1 / R2 规格件 / 3 份 `.tres` 的 `res://data/schemas/`（复数）不一致；本轮按真源取复数以保证 `.tres` 不悬空、真跑自洽，不擅改他人文档。
3. **I-2 `GameEvents` autoload 挂载偏差**、**`combat_data_validator._ready()` 运行时自检未实跑 / E-8 抗性溢出口径待复核**、**M5 Boss 控制器**：均为 R2 遗留项，本轮未改 R2 交付件，沿用 `DONE-R2.md` §4 登记。
4. **`COMBAT-BUILD` 三段门禁未挂载 `CombatDataValidator` 触发 `_ready()`**：本轮 `--import` / `--check-only` / `--quit` 校验的是脚本解析与 `.tres` 加载，未执行 validator 的运行时资源自检（E-1/E-3/E-4/E-5/E-8/E-9）；脚本本身 `--check-only` 已通过（R2 口径），运行时自检待集成时挂载复核。

---

## 8. 收尾

- 临时工程 `C:\Users\62668\AppData\Local\Temp\r3_gate_a2\` 未落入 teamwork、不提交；收尾时清理删除。
- 未写总线 / 台账 / git；未自行 commit / push；零付费、无外部依赖、未写探针脚本。
