# DONE-R26.md · Rank-2（战斗系统与数据驱动）

> 轮次 **R26**｜命令 `cmd-20261111-073556-923-A2`（`[ROUND=R26]`，v0.4.0 新内容）
> 真源：`teamwork/Rank-2/调度任务单-latest.json`（`id` / `ai=2` / 正文已核对）
> 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（v4.7.2.stable.official.ed1daf0bf）
> 工程根 `F:/Game/aierdengfahuan`，Godot 工程 `F:/Game/aierdengfahuan/godot`｜中文 UTF-8
> 结论：**任务单 ①~⑤ 全部落地并经真跑验证通过，无阻塞**。

---

## 1. 实际交付清单（含精确落盘时间 +0800）

| # | 文件 | 动作 | 落盘时间 | 大小 | 内容 |
|---|---|---|---|---|---|
| 1 | `godot/scripts/combat/wave_trial_config.gd` | **新写** | **07:45:30** | 5647 B | `extends Resource` / `class_name WaveTrialConfig`；三波结构、`[PLACEHOLDER]` 降级基线、越界拒绝、字段缺失降级、合法性校验。 |
| 2 | `godot/data/rpg/wave_trial.tres` | **新写（构建脚本生成 + 回读校验）** | **07:45:55** | 688 B | 3 波数据表，**本轮最早落盘给 Rank-1 导演层读取的产物**。 |
| 3 | `teamwork/Rank-2/build_wave_trial_v040.gd` | **新写** | 07:45:44 | 4012 B | `extends SceneTree` 构建器：`make_wave` → `ResourceSaver.save` → `CACHE_MODE_IGNORE` 回读逐字段校验。 |
| 4 | `teamwork/Rank-2/WAVE-TRIAL-TUNING.md` | **新写** | 07:48:22 | 10895 B | 数值假设表 + 调参位置 + 「broken」定义 + 技术口径记录。 |
| 5 | `godot/scripts/combat/verify_wave_trial_v040.gd` | **新写** | 07:48:52 | 11038 B | `extends SceneTree`，**58 条断言**，输出 PASS/FAIL 与 RESULT，失败 `quit(1)`。 |
| 6 | `teamwork/Rank-2/DONE-R26.md` | 新写 | 本文件 | — | 本文件。 |
| 7 | `teamwork/command_center/ai/2/outbox/cmd-20261111-073556-923-A2.json` | 新写 | 本轮 | — | 按本命令 id 的回执（**teamwork 下 outbox，非工程根 command_center/**）。 |

另有 6 份真跑日志落在 `teamwork/Rank-2/R26-*.log`（`gate1-import` / `gate2-checkonly-config` / `gate2-checkonly-verify` / `gate3-quit` / `build-run` / `verify-run`），均为真实执行输出，非推断。

**未写 / 未改**（目录所有权）：`wave_trial_director.gd` / `encounter_director.gd` / `courtyard.tscn` / 波次 HUD（Rank-1）；`00-协作契约.md` / `README.md` / `WAVE-TRIAL-GDD.md` / `verify_wave_flags_v040.gd` / `teamwork/Rank-3/`（Rank-3）；`godot/assets/generated/r23/` 与两份 spriteframes `.tres` / `presentation.gd` / `teamwork/Rank-4/`（Rank-4）；`project.godot` / 既有战斗件 / 其余 `.tres`（全体禁写）。未自行 `git commit/push`，未生成 `00-汇总.md`。

---

## 2. 按任务单正文逐项落实

### ① `wave_trial_config.gd`（资源类）

- `extends Resource` + `class_name WaveTrialConfig`；**全静态类型**：`@export` 字段、`DEFAULT_*` 常量、方法参数与返回值全部显式类型标注（沿用工程既有 `enemy_data.gd` 风格）。
- 三波结构 `@export var waves: Array[Dictionary]`，每波 6 个字段：`enemy_id` / `hp_multiplier` / `move_weight` / `reward_points` / `telegraph_sec` / `time_limit_sec`。
- **运行时静态类型视图** `class WaveData extends Resource`（6 个 `@export` 字段），由 `get_wave()` / `wave_from_dict()` 从 Dictionary 构造；导演层两种读法均兼容：`cfg.waves[i]["hp_multiplier"]` 与 `cfg.get_wave(i).hp_multiplier`（`WaveData` 亦支持 `view["field"]`）。
- API：`make_wave(...)`（工厂，返回一行 Dictionary）、`get_wave(index)`（越界返回 null）、`wave_count()`、`wave_from_dict(d)`（缺 key / 类型异常回落 `[PLACEHOLDER]` 基线）、`is_wave_valid(w)`（time_limit/telegraph/倍率/权重/奖励/id 合法性）。
- **所有数值标 `[PLACEHOLDER]`**：6 个 `DEFAULT_*` 降级基线逐项注释，逐项 rationale 写在 `WAVE-TRIAL-TUNING.md` §2；设计数值不在代码里写死，唯一真源是 `.tres`。

### ② `wave_trial.tres`（3 波）

| 波 | `enemy_id` | `hp_multiplier` | `move_weight` | `reward_points` | `telegraph_sec` | `time_limit_sec` |
|---|---|---|---|---|---|---|
| 1 | `enemy_01_limgrave_soldier` | 1.0 | 1.0 | 100 | 1.5 | 30.0 |
| 2 | `enemy_01_limgrave_soldier` | 1.3 | 1.0 | 150 | 1.5 | 30.0 |
| 3 | `boss_01_margit` | 1.6 | 1.0 | 200 | 1.5 | 30.0 |

- 全部为任务单 ② 给定值；`move_weight` 任务单未给具体值，取 `1.0` 等权基线并明确标 `[PLACEHOLDER]`（文档 §1 / §7 如实登记）。
- 敌人 id **复用既有** `godot/data/combat/enemy_01_limgrave_soldier.tres`（`id="enemy_01_limgrave_soldier"`）与 `godot/data/combat/boss_01_margit.tres`（`id="boss_01_margit"`），**未新增任何数据表**；verify 会 `load()` 两张表证明存在。
- 生成方式：`extends SceneTree` 构建脚本 `ResourceSaver.save` 落盘，再 `ResourceLoader.load(..., CACHE_MODE_IGNORE)` 回读逐字段比对，18 个字段全 `OK`、3 波 `valid=true`、`RESULT=BUILT_AND_VERIFIED`（`R26-build-run.log`）。

### ③ `WAVE-TRIAL-TUNING.md`

- **数值假设表**（§1）：三波 6 字段全量 + 逐字段 rationale（来源 / 为什么 / 待校准点），全部标 `[PLACEHOLDER]`。
- **调参位置**（§0 / §3）：唯一入口 `godot/data/rpg/wave_trial.tres` 的 `waves`；改完跑 verify；校准后必须同步 `.tres` → verify `EXPECT_*` → 文档 §1/§4 三处，不静默改数。
- **「broken」定义**（§4）：B1 首波 30 秒打不完 = 难度过高（优先回调 `hp_multiplier` / 编排 / `time_limit_sec`）；B2 三波全清 <15 秒 = 难度过低（上调 hp 梯度 / `move_weight`）；B3 点数通胀 = 奖励失衡（下调 `reward_points` 梯度）。并如实说明 15s/30s 阈值本身是 `[PLACEHOLDER]`、verify 不测运行时时长（归 Rank-1 HUD 观测）。
- 另含 §5 技术口径记录、§6 真跑命令、§7 未完成项边界。

### ④ `verify_wave_trial_v040.gd`（58 条断言，`RESULT=ALL_MATCH`）

覆盖任务单 ④ 全部点，逐条打印 `PASS=true/false` 与明细：

| 组 | 断言数（含） | 覆盖 |
|---|---|---|
| `table_load_cache_ignore` | 1 | `.tres` 以 `CACHE_MODE_IGNORE` 真读盘 |
| ① 结构 | 3×(字段齐全/id/hp/reward/move_weight/telegraph/time_limit/valid) + `wave_count_3` + `make_wave_6_fields` = 27 | 3 波、6 字段、逐值等于首版期望 |
| ② 单调 | 2 条（`hp_multiplier_strictly_increasing` / `reward_points_strictly_increasing`） | `1.0<1.3<1.6`、`100<150<200`，逐段打印实测 |
| ③ 越界 | 5 条 | `get_wave(-1)`（第 0 波 / 负下标）、`get_wave(3)`、`get_wave(4)` 均拒绝；合法 0..2 可取、不回绕 |
| ④ 降级 | 10 条 | 空表 `wave_count()==0` / `get_wave(0)==null`、`is_wave_valid(null)`、全字段缺失回落 `[PLACEHOLDER]` 基线且判非法、部分缺失合法、`.tres` 半行 Dictionary 不崩且补齐 |
| ⑤ 时限/前摇 | 11 条 | 3 波合法；`telegraph=0/-1`、`time_limit=0/-5`、`telegraph=time_limit=30`、`telegraph=31>30`、`hp=0`、`reward=-1` 逐一拒绝；`1.5<30` 通过 |
| ⑥ 复用既有 | 4 条 | 两张既有敌人表 `load()` 成功、3 波 id 均来自既有集合、点访问与字典式访问相等 |

`SUMMARY pass=58 fail=0`，`RESULT=ALL_MATCH`，`EXIT=0`，`PASS=false` 命中 **0**，失败会 `quit(1)`，不伪造 PASS。

### ⑤ 三段门禁 `grep SCRIPT ERROR=0`

**新增 `class_name WaveTrialConfig` 后已先跑 `--headless --import`**（任务单特别提醒；否则其它脚本解析不到全局类），共 3 次 import 真跑（07:43:16 / 07:44:40 / 07:45:49 / 07:49:26），全部 `EXIT=0`。详见 §4。

---

## 3. 落盘时间（任务单要求写明，供 Rank-1 对账）

| 产物 | 落盘时间（+0800） | 说明 |
|---|---|---|
| **`godot/data/rpg/wave_trial.tres`** | **2026-11-11 07:45:55.783494500** | **本轮最关键落盘**：由 `--headless --script .../build_wave_trial_v040.gd` 真跑 `ResourceSaver.save` 生成，`stat` mtime 复核；**早于本文件、tuning、verify 的落盘**，Rank-1 的 `wave_trial_director.gd` 可尽早 `load("res://data/rpg/wave_trial.tres")` 读到 3 波数据。 |
| `godot/scripts/combat/wave_trial_config.gd` | 2026-11-11 07:45:30.930941900 | 最终版（技术适配后落盘，见 §5.1）；初版 07:42 左右，经 2 次实证修订。 |
| `teamwork/Rank-2/build_wave_trial_v040.gd` | 2026-11-11 07:45:44.205108000 | 构建器。 |
| `teamwork/Rank-2/WAVE-TRIAL-TUNING.md` | 2026-11-11 07:48:22.587161500 | 调参文档。 |
| `godot/scripts/combat/verify_wave_trial_v040.gd` | 2026-11-11 07:48:52.169007300 | 自测脚本。 |

> Rank-1 读取口径：`load("res://data/rpg/wave_trial.tres") as WaveTrialConfig` → `cfg.waves`（`Array[Dictionary]`，3 行 6 key）或 `cfg.get_wave(i)`（`WaveData` 视图，点访问 / `view["field"]` 均可）。`class_name` 已由 `--headless --import` 注册到全局类缓存，可直接解析。

---

## 4. 真跑三段门禁输出结论（实际执行，非推断）

引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot`

| 段 | 命令 | 实际输出 | EXIT | SCRIPT ERROR | Parse Error | `ERROR:` |
|---|---|---|---|---|---|---|
| 1 | `--headless --import` | `first_scan_filesystem [DONE]` / `loading_editor_layout [DONE]`，注册 `WaveTrialConfig` 全局类 | **0** | **0** | **0** | **0** |
| 2a | `--check-only --script res://scripts/combat/wave_trial_config.gd` | 仅引擎头、无错误 | **0** | **0** | **0** | **0** |
| 2b | `--check-only --script res://scripts/combat/verify_wave_trial_v040.gd` | 仅引擎头、无错误 | **0** | **0** | **0** | **0** |
| 3 | `--headless --quit` | 主场景 / autoload 正常加载退出（2 条既有 WARNING：`ChunkManager` 无 ChunkRoot、`ObjectDB instances were leaked`，**非 ERROR**） | **0** | **0** | **0** | **0** |

**构建脚本与自测真跑（`--headless --script`）**：

| 脚本 | 结果 | EXIT | SCRIPT ERROR | Parse Error | `ERROR:` |
|---|---|---|---|---|---|
| `build_wave_trial_v040.gd`（项目外自有脚本，绝对路径 `--script`） | 18 字段回读全 `OK`、3 波 `valid=true`、`SUMMARY ok=true`、`RESULT=BUILT_AND_VERIFIED` | 0 | **0** | **0** | **0** |
| `verify_wave_trial_v040.gd` | `SUMMARY pass=58 fail=0`、`RESULT=ALL_MATCH`、`PASS=false`=0 | 0 | **0** | **0** | **0** |

- **6 份 `R26-*.log` 逐份 `grep`：`SCRIPT ERROR=0`、`Parse Error=0`、`ERROR:=0`**（连 C++ 层非致命 `ERROR:` 都没有）。
- 装配期非致命输出（如实登记）：`--script` 与 `--quit` 模式带引擎既有 `WARNING`（ChunkManager 未找到 ChunkRoot、ObjectDB leak 2 实例），**不是 `SCRIPT ERROR`**，不影响 RESULT 与 EXIT，与 R25 惯例一致。
- 未写 `user://` 存档 flag、未触发任何 commit；本轮纯数据表构建与只读校验。

---

## 5. 未完成项与阻塞 / 如实边界（不粉饰、不冒充）

1. **无阻塞**：任务单 ①~⑤ 全部落地并经真跑验证通过。
2. **人工试玩校准未执行**：B1/B2/B3 的实测判定属用户侧（契约 §5「WorkBuddy 不替人做手感与审美判断」）。本轮只交付数据表 + 数值假设表 + 判据 + 调参入口 + 代码级自测，**不冒充已完成试玩校准**。
3. **`move_weight` 任务单未给值**：首版 `1.0` 是明确标注的 `[PLACEHOLDER]` 等权假设（与 `MoveData.weight=1.0` 同源），**不是定论**，待试玩按出招频率校准。
4. **`telegraph_sec` 与既有 `MoveData.startup_frames` 的量纲关系**（波次预警秒 vs 单招起手帧）尚未由 Rank-1 导演层实接验证；接线后需复核，本轮不越界改导演层。
5. **15s / 30s broken 阈值本身是 `[PLACEHOLDER]`**：verify 只校验数据合法性与单调性，**不测运行时时长**（时长属 HUD / 导演层观测，归 Rank-1）；调 `time_limit_sec` 即调 B1 阈值，须同步本文 §1/§4 与 verify。
6. **技术适配（如实登记，非降低要求）**：最终存储层是 `Array[Dictionary]` + 运行时 `WaveData` 视图，**不是** `@export waves: Array[WaveData]` 直接落地。原因见 §5.1 实证。字段、类型、三波结构、降级、校验一项不少，导演层两种读法都兼容。
7. **未改**任何 Rank-1 / Rank-3 / Rank-4 文件、`project.godot` / 场景 / 素材 / 契约 / README；未自行 `git`（总指挥收尾）；零付费、零外部依赖、未启 GPU job；**未新建只读探针 / 巡检 / preflight 脚本**（`build_wave_trial_v040.gd` 是数据表生成器，`verify_wave_trial_v040.gd` 是正式自测件，均非探针），未主动扫目录做进度巡检。
8. **并发保护复核**：写交付前复核 `teamwork/Rank-2/DONE-R26.md` 不存在、`teamwork/command_center/ai/2/outbox/` 为空、`teamwork/command_center/dispatcher/receipts/` 无同 id 归档，无并发实例写齐，故正常写一份 DONE 与一份回执（不写第二份）。

### 5.1 技术口径实证（为什么改用 `Array[Dictionary]`）

按任务单「可用 Array[Dictionary] 或自定义 Resource 子类」，首版先试「自定义 Resource 子类」直落，`extends SceneTree` 构建脚本真跑**两轮均失败**（日志留存于 `R26-build-run.log` 首版输出，最终版日志已覆盖为成功结果，失败证据以本节文字与当时 `.tres` 内容如实登记）：

- 第 1 轮（`@export var waves: Array[WaveData]`，`WaveData` 为内部类）：`ResourceSaver.save` 成功，回读报
  `ERROR: Attempted to assign an object into a TypedArray, that does not inherit from 'GDScript'`，数组被丢空（`wave_count mismatch got=0 expect=3`）。
- 第 2 轮（改 `Array[Resource]`）：数组长度回读正确，但引擎把内部类脚本序列化成**空的 `[sub_resource type="GDScript"]`**（首版 `.tres` 第 5 行），回读实例丢脚本类，`as WaveData` 全为 `null`，字段虽写入但无法作为视图使用。

结论：**Godot 4.7.2 无法把内部类 Resource 实例正确序列化 / 反序列化进 `.tres`**（内部类作类型化数组元素类型时元素类型被解析为 `GDScript` 脚本类）。故按任务单允许的 `Array[Dictionary]` 落地存储层，内部类 `WaveData` 降级为**运行时静态类型视图**（`get_wave()` / `wave_from_dict()` 构造，不参与序列化）。第 3 轮真跑 `RESULT=BUILT_AND_VERIFIED`，`.tres` 内容干净可读（3 个 Dictionary、6 key），verify 58 条全 PASS。

---

## 6. 回执与中枢消费复核

**写入路径（严格按任务单指定，非工程根 command_center/）**：
`teamwork/command_center/ai/2/outbox/cmd-20261111-073556-923-A2.json`

实际写入内容（4 键，`result` 引用本 DONE 实际结论）：

```json
{"task_id":"cmd-20261111-073556-923-A2","ai":2,"status":"done","result":"引用 teamwork/Rank-2/DONE-R26.md 实际结论：①~⑤ 全部落地并真跑通过、无阻塞。godot/data/rpg/wave_trial.tres（3 波 hp 1.0/1.3/1.6、reward 100/150/200、telegraph 1.5、time_limit 30，复用 enemy_01_limgrave_soldier / boss_01_margit 不新增数据表）于 2026-11-11 07:45:55 +0800 落盘供 Rank-1 读取；构建脚本 CACHE_MODE_IGNORE 回读 18 字段全 OK、RESULT=BUILT_AND_VERIFIED；verify_wave_trial_v040.gd 58 PASS / 0 FAIL / RESULT=ALL_MATCH；三段门禁 EXIT=0，6 份 R26 日志 SCRIPT ERROR=0 / Parse Error=0 / ERROR:=0。未完成项：人工试玩校准（B1/B2/B3）属用户侧，本轮只交数值假设表、判据与调参入口，不冒充已完成；move_weight=1.0 为 [PLACEHOLDER] 假设；技术适配为 Array[Dictionary] + 运行时 WaveData 视图（Godot 4.7.2 内部类序列化实测限制），字段与类型一项不少。"}
```

**复核（写入后立即执行）**：回执写入 outbox 后被调度中枢**即时消费**（outbox 目录变空，07:51），并归档至
`teamwork/command_center/dispatcher/receipts/cmd-20261111-073556-923-A2.json`（982 B，07:51）；读回该归档，
`task_id` / `ai=2` / `status=done` / `result` 与写入内容逐字一致。按 R25 DONE §4.8 与中枢既定消费机制，
**outbox 为空属正常、不视为缺失，不重复写第二份回执**；验收以 receipts 归档为准。
（本机 `python` 不可用，JSON 合法性以 Read 逐字读回 + 4 键核对为准，未伪造校验。）
