# DONE-R9.md —— Rank-2（战斗系统与数据驱动）R9 完成标志

> 轮次：R9「M5 Boss 最终数据表与汇总材料」。任务单 `cmd-20261109-033148-250-A2`
> （`调度任务单-latest.json` 实读 id 一致），派单见 `00-群聊总线.md` `MSG-20261109-0331-HOST`。
> 唯一可写：`teamwork\Rank-2\`、`godot\scripts\combat\`、`godot\data\combat\`；
> 回执例外 `teamwork\command_center\ai\2\outbox\`。**不写** `project.godot`、其它工位 / 子目录、
> 总线 / 总纲 / 契约 / 台账；不自行 git commit / push；既有件不重做；待裁决项只登记不擅改。
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（本轮 `--version` 实测
> `4.7.2.stable.official.ed1daf0bf`，EXIT=0）。
> 本文所有数字 / 输出均来自**本轮本机实际输出与机器化核对**（门禁时间戳
> `2026-11-09 03:36:29 ~ 03:38:07 +0800`），不引用旧结论冒充、不伪造、不冒充全绿。中文 UTF-8。

---

## 0. 结论速览

| 交付项 | 状态 | 实际结论 |
|---|---|---|
| ① BOSS 最终数值表 + schema 逐项核对 | **完成** | `BOSS-DATA-FINAL.md`：二阶段 + 3 招全部数值、171 个字段实例逐项核对、E-1~E-9 等式结论 |
| ② E-8 三项冲突裁决建议表 | **完成（只给建议、不改数值）** | `E8-裁决建议表.md`：现状值 / 校验阈值 / 候选值 / 影响面 / 建议 五列 + A/B/C 三方向；`.tres` 数值零改动 |
| ③ 战斗侧 I-1~I-4 一致性自检 | **完成** | `I-INTERFACE-SELFCHECK.md`：四项均一致，附本轮 grep 实证 / 三段门禁真跑 / 既有 R7 实跑（明确标注非本轮新跑） |
| ④ 真跑三段门禁确认无回归 | **完成** | FINAL：`SEG0/1/3_RC=0`、`SEG2_SCRIPTS=52 SEG2_FAIL=0`、`SCRIPT ERROR=0`、`ERROR=0`、`hides a global=0`、`Failed to load=0` |
| `DONE-R9.md` / 回执 | **完成** | 本文件 + `cmd-20261109-033148-250-A2.json` 写入 outbox |

**不冒充全绿**：`ERROR=0` 仅指脚本 / 加载 / 解析层；仍有 1 条跨工位 / 引擎时序
`WARNING: 2 ObjectDB instances were leaked at exit`；E-8 数据层三项冲突与其余待裁决项仍在；
段 3 只做 `--headless --quit` 加载门禁，未做渲染 / 运行时 / 手感验收。

完成标志：`status=done`，回执 `task_id=cmd-20261109-033148-250-A2`。

---

## 1. 实际交付清单（①）

### 1.1 本轮新增文件（共 5 个：4 文档 + 1 回执）

| # | 文件 | 落位 | 内容 |
|---|---|---|---|
| 1 | `BOSS-DATA-FINAL.md` | `teamwork\Rank-2\`（新建） | M5 Boss 最终数值表：BossData 18 字段 / PhaseData 2 阶段 / MoveData 3 招（前摇·判定·后摇帧数与 `[start,end)`）/ PoiseConfig 2 组 / StatusBuildup 3 条；与 `数据表schema.md` 逐项核对（字段集合、取值范围、E-1~E-9、id 规范） |
| 2 | `E8-裁决建议表.md` | `teamwork\Rank-2\`（新建） | E-8 三项冲突（bleed `380>330` / poison `450>360` / frost `400>320`）裁决建议表：现状值 / 校验阈值 / 候选值 / 影响面 / 建议；A/B/C 三方向与倾向性建议；**零数值改动** |
| 3 | `I-INTERFACE-SELFCHECK.md` | `teamwork\Rank-2\`（新建） | 战斗侧 I-1 / I-2 / I-3 / I-4 一致性自检结论 + 本轮 grep 实证 + 三段门禁真跑输出 + 既有 R7 实跑引用 |
| 4 | `DONE-R9.md` | `teamwork\Rank-2\`（新建，本文件） | ① 实际交付清单 ② 自检含真跑实际输出结论 ③ 未完成项与阻塞 |
| 5 | `cmd-20261109-033148-250-A2.json` | `teamwork\command_center\ai\2\outbox\`（新建） | 完成回执 JSON（`task_id` / `ai=2` / `status=done` / `result` 引用本文件实际结论） |

### 1.2 明确未改动（机器化核对）

- `godot\data\combat\boss_01_margit.tres`：**数值零改动**。本轮 `grep` 实证三组仍为
  `180/25/330`、`210/30/360`、`160/30/320`；与工位稿（排除 5 条 `ext_resource` 行后）
  `diff` → **DIFF_RC=0**（数值 / 字段逐字一致）。
- `teamwork\Rank-2\boss_01_margit.tres` 工位稿、`godot\scripts\combat\` 全部 12 个 `.gd` 与
  `.gd.uid`：`spawn_request.gd` 的 R8 裁决注释等既有内容**零改动**（本轮未写任何 `.gd`）。
- `godot\project.godot`（Rank-1 独占）、`godot\export_presets.cfg`（Rank-1 R10 交付件）、
  `godot\scripts\rpg\spawn_request.gd`（I-3 权威件）、`godot\scripts\rpg\*`、
  `godot\data\rpg\*`、`godot\scenes\`、Rank-1/3/4 子目录：**零改动、只读引用**。
- 工位既有交付件（`数据表schema.md`、`接口契约.md`、`R5-待裁决登记.md`、`I2-WIRING.md`、
  `COMBAT-ASSEMBLY.md`、`DONE-R2~R8.md`、`combat_data_validator.gd`、`schema\*` 等）：**零改动**。
- 总线 / 总纲 / 契约 / 台账 / 任务书：**零改动**；未自行 git commit / push；零付费 / 零外部依赖。

### 1.3 交付项逐项说明

| 交付项 | 关键结论 |
|---|---|
| ① 最终数值表 | `max_hp=3500.0`；阶段阈值 `[0.5]`（P1 `exit=0.5` / P2 `enter=0.5`, `exit=0.0`）；3 招倍率 `1.0/1.55/2.1`、阶段倍率 `1.0/1.25`；前摇/判定/后摇 `18/5/24`、`30/7/34`、`42/9/40`（`total` 派生 `47/71/91`，判定区间 `[18,23)`/`[30,37)`/`[42,51)`）；削韧 `22/45/70` + 韧性上限 `120/150`；异常阈值 `180/210/160`、招式施加 frost `35`（仅 m3）。**字段集合 / 取值范围 / id 规范全数合法**；E-1/E-2/E-3/E-4/E-5/E-9 **PASS**，E-6/E-7 不属本表（属 M1 玩家动作），**E-8 三项 FAIL 如实保留** |
| ② 裁决建议表 | 现状值 / 校验阈值 / 候选值 / 影响面 / 建议 五列齐全；三方向 A（改 3 组 `max_resistance` 至 ≥380/450/400）/ B（调小 `resistance_sample_triggers` N≤5）/ C（修订 E-8 式）；**建议倾向 A**（口径一致、改数值不改代码、影响面最小），但明确「仅供裁决参考、2 号不实施、不选定最终值」。E-8 属总指挥裁决项，本轮未改任何数值 / 校验参数 / 文档口径 |
| ③ 接口自检 | I-1 战斗层只读 `get_flag`、`set_flag(` **0 命中**；I-2 单 String 信号 + 唯一发射点 + **击杀 flag 不双写**；I-3 `^class_name SpawnRequest` 全工程**仅 1 处**在 `scripts/rpg/`；I-4 `call("set_pose"` **单点 1 处**。四项均一致；§3.4 登记 schema §8 10 字段假设 vs 权威件 17 字段的字面差异（schema 已声明非定义权声明，不构成契约违反） |
| ④ 真跑门禁 | 见 §2，FINAL 快照 `ERROR=0`、52/52 `--check-only` EXIT=0，确认无回归 |

---

## 2. 自检含真跑实际输出结论（②）

### 2.1 三段门禁 FINAL 稳定快照（本轮实际 stdout，逐字）

> 引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`；工程根 `F:/Game/aierdengfahuan/godot`；
> 日志 `C:\Users\62668\AppData\Local\Temp\r9_gate_a2\`（系统临时目录，收尾删除）。
> 口径同 `Rank-1\GATE-FINAL.md` §1 / `DONE-R8.md` §4.1。

```
=== FINAL GATE_TS_START=2026-11-09 03:37:51 +0800 ===
FINAL_SEG0_RC=0
--- seg0 ---
4.7.2.stable.official.ed1daf0bf
FINAL_SEG1_RC=0
final_seg1.log 行数: 16
FINAL_SEG2_SCRIPTS=52 FINAL_SEG2_FAIL=0
FINAL_SEG3_RC=0
--- seg 3 原文 ---
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
=== FINAL all.log 行数: 125 ===
SCRIPT ERROR: 0
Parse Error: 0
ERROR lines: 0
WARNING lines: 1
leaked lines: 1
hides a global: 0
dangling/not found/Failed to load: 0
=== ERROR/WARNING 原文 ===
124:WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
=== FINAL GATE_TS_END=2026-11-09 03:38:07 +0800 ===
```

| 段 | 命令 | 退出码 | 实际输出 |
|---|---|---|---|
| 0 | `--version` | `FINAL_SEG0_RC=0` | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `--headless --path <root> --import` | `FINAL_SEG1_RC=0` | 16 行；扫描 / 全局类注册 / 编辑器布局 DONE；无 ERROR |
| 2 | `--check-only --script`（全工程 **52** 个 `.gd`） | `FINAL_SEG2_SCRIPTS=52 FINAL_SEG2_FAIL=0` | 52 个脚本全部解析通过，`FAIL` 列表为空 |
| 3 | `--headless --path <root> --quit` | `FINAL_SEG3_RC=0` | 主场景 + 5 个 autoload 启动后正常退出；仅 1 条 leaked WARNING |

### 2.2 `SCRIPT ERROR` 专项与宽口径 grep（合并 `final_all.log` 125 行）

| 检查 | 实际计数 |
|---|---|
| `SCRIPT ERROR` | **0** |
| `Parse Error` | **0** |
| `ERROR` 行数 | **0** |
| `WARNING` / `leaked` | **1 / 1**（唯一 1 条，见 2.1） |
| `hides a global` | **0** |
| `dangling` / `not found` / `Failed to load` | **0 / 0 / 0** |

> 工具链 §4.2：运行时错误不改退出码，必须 grep —— 已执行。唯一告警
> `WARNING: 2 ObjectDB instances were leaked at exit`（`all.log:124`），与
> `GATE-FINAL.md` §6 / `DONE-R8.md` §4.4 一致，为 ChunkManager 在途 `load_threaded_request`
> 遇 `--headless --quit` 的 `RefCounted` 残留，**WARNING 级、非 ERROR、非 SCRIPT ERROR、
> 不改退出码**，2 号不越界修复。

### 2.3 并行时序如实登记（不冒充全程无冲突）

| 时点 | 实际输出 | 归因 |
|---|---|---|
| 首次门禁 `03:36:29` 段 1 `--import` | **8 条 `ERROR:`**（`Couldn't find the given section "preset.0" ... export_filter/include_filter/exclude_filter` ×2 + `Cannot get keys from nonexistent section "preset.0.options"` ×2）；合并 `SCRIPT ERROR: 0`、`Parse Error: 0`、`ERROR lines: 8`、`SEG2_SCRIPTS=52 SEG2_FAIL=0` | `godot\export_presets.cfg`（**Rank-1 R10 交付件**，`03:35:51` 落盘 457 B）当时为**未完成版**，缺 3 个 preset 级键与 `[preset.0.options]` 键 → Godot `--import` 读导出预设报错 |
| 第二次复跑 `--import`（约 `03:37`） | `RE_IMPORT_RC=0`、`RE_IMPORT ERROR 计数: 0`、`SCRIPT ERROR: 0`、`Parse Error: 0` | Rank-1 并行把该文件补全为 **768 B 有效版**（补入 `export_filter="all_resources"` / `include_filter` / `exclude_filter` 与 `binary_format/embed_pck=false`） |
| FINAL 完整三段 `03:37:51` | `ERROR lines: 0`（§2.1） | 稳定快照，与 R9 基线 `ERROR=0` 一致 |

> 这 8 条 ERROR 是**配置层读取错误**（`export_presets.cfg`，Rank-1 范围）、**非脚本层**
> （`SCRIPT ERROR=0` / `Parse Error=0`、52 个 `.gd` 全 EXIT=0）、**非战斗层**、**非本轮 2 号改动**。
> 属四路并行写同一工程根的时序现象，已由 Rank-1 自行收口；2 号**不改他人文件、不越界修复、
> 不冒充全绿**，按实际输出如实登记。**战斗侧无回归结论不受该时序影响。**
> 另：本轮 `.gd` 计数 **52**（R8 / `GATE-FINAL` 基线 51），差 1 件来自并行写入；按「默认不刺探」
> 未逐一追查归属，只登记数量差异，门禁窗口内未出现脚本层 ERROR。

### 2.4 BOSS 数据表逐项核对结论（`BOSS-DATA-FINAL.md`）

- 两份 `.tres`（工位稿 / 运行件）排除 5 条 `ext_resource` 后 `diff` **DIFF_RC=0**，数值逐字一致。
- 字段集合（BossData 18 / PhaseData 15 / MoveData 21 / PoiseConfig 10 / StatusBuildup 14）
  **逐字一致、无多余字段、无 `total_frames` 字段**（E-9 PASS）；171 个字段实例取值范围全数合法。
- **E-1 / E-2 / E-3 / E-4 / E-5 / E-9 PASS**；E-6 / E-7 属 M1 玩家动作、不在本表判定范围；
  **E-8 三项 FAIL（`380>330` / `450>360` / `400>320`）如实保留为总指挥裁决项**。
- id 规范（boss / phase / move / poise / status / flag key）全数符合 `数据表schema.md` §0.2。

### 2.5 I-1~I-4 战斗侧一致性自检结论（`I-INTERFACE-SELFCHECK.md`）

| 编号 | 本轮 grep 实证 | 结论 |
|---|---|---|
| I-1 | combat 侧 `set_flag(` 实际调用 **0 命中**；`boss_controller.gd:338-341` 双参 `get_flag` 只读 | **一致** |
| I-2 | `game_events.gd:8-9` 两信号均单 `String`；`combat_event_bus.gd:42` 唯一发射点、`:51` `emit_signal(signal_name, defeat_id)` 单参；击杀 flag 写方为 3 号 `save_delta_writer.gd:48-60` | **一致（单 String、不双写）** |
| I-3 | `^class_name SpawnRequest` 全工程**仅 1 处** = `scripts/rpg/spawn_request.gd:2`；combat 版无 `class_name`；段 1 `hides a global=0`、段 3 `Failed to load=0` | **一致（权威件在 rpg/）** |
| I-4 | `call("set_pose"` 全战斗层**单点 1 处**（`boss_controller.gd:351`），带 `has_method` 守卫 | **一致** |

> 真跑证据：本轮 R9 三段门禁（§2.1，段 3 真实实例化 `GameEvents` autoload 后
> `SCRIPT ERROR=0` / `Failed to load=0`）+ 引用的**既有**真跑记录
> `R7\I2-WIRING.md`（C1~C6 全 PASS、`RESULT=PASS checks=6 fail=0`，**明确标注非本轮新跑、
> 未重做**）。I-3 的 schema §8 10 字段假设 vs 权威件 17 字段字面差异已登记为待汇总对齐项
> （schema 已声明非定义权声明，不构成契约违反）。

### 2.6 E-8 裁决建议结论（`E8-裁决建议表.md`）

- 现状值 / 校验阈值 / 候选值 / 影响面 / 建议 **五列齐全**；三方向 A / B / C 与静态影响如实列出。
- **建议倾向 A**（改 3 组 `max_resistance` 至 ≥380/450/400，保持 N=8、口径不动、影响面最小），
  但明确「仅供总指挥裁决参考、2 号不实施、不选定最终值」。
- **本轮零数值改动**：`.tres` 三组数值逐字未改、`combat_data_validator.gd` 的 `@export` 默认值
  未改、`数据表schema.md` §9 口径未改。E-8 属总指挥裁决项。

### 2.7 判定汇总

| 层 | 结论 |
|---|---|
| 脚本层 | **PASS**：52/52 `--check-only` EXIT=0，`SCRIPT ERROR=0`、`Parse Error=0` |
| 资源 / 加载层 | **PASS**：G1 `--import` / G3 `--quit` EXIT=0，`hides a global=0`、`Failed to load=0`、`dangling=0`、`not found=0` |
| 战斗层回归 | **无回归**：本轮未写任何 `.gd` / `.tres` / 配置；战斗侧 I-1~I-4 四项一致；52 件解析全通过 |
| 数据自洽层 | **E-8 三项 FAIL 仍在**（validator 未落位工程根，门禁日志无 E-8 字样 ≠ 已解决） |
| 整体 | **非「全绿」**：`ERROR=0` 但 1 条跨工位 / 引擎时序 leaked WARNING；E-8 与其余待裁决项仍在；段 3 只做加载门禁，未做渲染 / 运行时 / 手感验收 |

---

## 3. 未完成项与阻塞（③）

> 以下均为「需总指挥裁决 / 跨工位集成 / 超本工位范围」项，**均不阻塞本轮 R9 收尾**；
> 本轮一律只登记、不擅改、不冒充已解决。

1. **E-8 三项数值冲突**（`380>330` / `450>360` / `400>320`）：本轮已产出裁决建议表，
   **仍需总指挥给出明确数值 / 口径**后由后续轮次执行；`CombatDataValidator` 落位工程根后会
   稳定复现 4 条 `ERROR:`（3 FAIL + 1 汇总）。2 号未改数值。
2. **I-3 字段口径字面差异**：`数据表schema.md` §8 的 10 字段最小假设 vs 3 号权威件 17 字段；
   消费件 `enemy_director.gd` 未落位工程根，字段对齐待后续轮次裁决（`I-INTERFACE-SELFCHECK.md` §3.4）。
3. **历史 signal 去留 / I-2 唯一发射点收敛**：`player_state_machine.gd` 既有 `signal` 与旧
   `report_defeat` 本地 emit 属既有件，`COMBAT-ASSEMBLY.md` §6.3 登记待裁决；本轮未改。
4. **`res://data/schema`（单数） vs `schemas`（复数）口径**：`COMBAT-ASSEMBLY.md` §6.2 登记，
   裁决归总指挥；本轮未改脚本头注释 / 任务书 / schema 文档。
5. **战斗层既有件未落位工程根**：`combat_data_validator.gd` / `enemy_director.gd` /
   `player_state_machine.gd` 仍在 `Rank-2\`（§6.7），是否落位待裁决。
6. **工位内 2 个 `class_name SpawnRequest` 规格件 / `enemy_director.gd` 强类型引用**：
   不在工程根扫描范围、不参与门禁（`DONE-R8.md` §7.2），按「既有件不重做」本轮未动。
7. **Q1（`SpriteFrames` 替换 vs `set_pose`）**：`接口契约.md` §4 Q1 登记；本轮不私改接口，
   `sprite_frames_path` 仅登记不调用。
8. **ObjectDB leaked WARNING / 渲染与运行时验收 / M5 手感调校**：跨工位 / 引擎时序与
   契约 §5「WorkBuddy 不替人做手感与审美判断」；本轮不越界修复、不宣称已渲染可见、不调手感。
9. **并行时序**：首次门禁的 8 条导出预设 `ERROR:` 已由 Rank-1 补全 `export_presets.cfg` 后归零
   （§2.3）；`.gd` 51→52 数量差异如实登记，未追查归属（默认不刺探）。

---

## 4. 收尾口径

- 本轮实际写入：**5 个新文件**（`BOSS-DATA-FINAL.md`、`E8-裁决建议表.md`、
  `I-INTERFACE-SELFCHECK.md`、`DONE-R9.md`、`outbox\cmd-20261109-033148-250-A2.json`）。
  **其余既有件零改动、零覆盖**；未写 `project.godot` / `export_presets.cfg` / `scripts\rpg\` 权威件 /
  其它工位 / 总线 / 总纲 / 契约 / 台账。
- 门禁日志 `C:\Users\62668\AppData\Local\Temp\r9_gate_a2\`（`seg*.log` / `final_*.log` /
  `all.log` / `final_all.log` / `scripts.txt`）在系统临时目录、不落工位 / 工程根 / 不提交，
  结论已抄录进本文件与三份交付文档，**收尾删除**。
- 三段门禁在真实 `godot\` 工程根按任务书要求复跑；`--import` 更新的是既有 `godot\.godot\`
  引擎缓存（`.gitignore` 排除、非 2 号交付件），未覆盖任何源码 / 既有文件。
- 回执路径解析：任务书字面 `command_center\ai\2\outbox\`，工程根下无 `command_center\`；
  中枢真实空间为 `teamwork\command_center\`（沿用 `COMBAT-ASSEMBLY.md` §1 / `DONE-R6~R8.md` §8
  口径），回执写入 `teamwork\command_center\ai\2\outbox\`，未在根下另建目录。
- 回执：`{"task_id":"cmd-20261109-033148-250-A2","ai":2,"status":"done","result":"<引用本文件实际结论>"}`，
  `task_id` 与 `调度任务单-latest.json` 实读 id 一致。
- **回执流转（如实登记）**：回执（task_id=cmd-20261109-033148-250-A2 / ai=2 / status=done /
  result 引用本文件实际结论）写入 `teamwork\command_center\ai\2\outbox\` 后被中枢即时轮询消费，
  归档于 `teamwork\command_center\dispatcher\receipts\cmd-20261109-033148-250-A2.json`（2368 B）；
  实跑复核 `python json.load` 解析通过（task_id / ai=2 / status=done / result 1297 字），
  `ai\2\status.json` 实测 `state=idle / completed=10 / last_seen 2026-11-09 03:45:15`
  （R8 收尾 `completed=9`，本轮 +1）。`outbox\` 因中枢消费再度为空属
  `DONE-R6.md` §8 / `DONE-R7.md` §8 / `DONE-R8.md` §8 已记录的正常现象，
  **回执已生效、不重复补写**；该归档件由中枢生成，不在 2 号可写范围，未删除、未改动。
- 零付费 / 零外部依赖；中文 UTF-8；Godot 4 合法语法（52/52 `--check-only` 通过）；
  开工必读只读一次；默认不刺探；未自行 git commit / push；
  **待裁决项一律未擅改、未选定、未伪造输出、未冒充全绿**。
