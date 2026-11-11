# DONE-R26 · Rank-1 交付（cmd-20261111-073556-918-A1 / [ROUND=R26] / v0.4.0 新内容 / 裁决 A19）

- 执行 AI：Rank-1（引擎架构与渲染）
- 工程根：`F:/Game/aierdengfahuan`；Godot 工程 `F:/Game/aierdengfahuan/godot`；引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）
- **结论速览**：赐福试炼波次运行时（状态机 + 3 信号 + 数据表驱动 + 依赖缺失降级单波）、既有 `encounter_finished(won)` 接线、波次 HUD（同层只读标签）、courtyard 三地面 `uv1_scale` 16/3/2 → 4/2/1 全部落地。三段门禁 21 份日志 `SCRIPT ERROR=0`；**34 / 47 / 19** PASS 与 **20 / 45 / 53** PASS 全不回退；新 `verify_wave_runtime_v040.gd` **37 PASS / 0 FAIL / RESULT=ALL_MATCH**；courtyard 节点数 **33 → 36（+3）**，CACHE_MODE_IGNORE 回读生效。未完成项见 §8。

---

## 1. 实际交付清单（只写自有文件）

| 文件 | 动作 | 说明 |
|---|---|---|
| `godot/scripts/combat/wave_trial_director.gd` | **新写** | extends Node；状态机 + 3 信号 + 数据表读取/降级 + HUD 刷新；零战斗数值硬编码、零 flag 写入 |
| `godot/scripts/combat/encounter_director.gd` | 末尾追加 1 个方法 | `trial_grace_rest()` 复用既有 `_grace_rest()`，供波次失败回赐福休息；**既有方法 / 信号 / debug_* 签名逐字未动** |
| `godot/scenes/courtyard.tscn` | 独占精确编辑 | 新增波次 HUD（2 节点）+ WaveTrialDirector（1 节点）；三地面材质 uv1_scale 降级；头部加 2 条 ext + 3 条 sub_resource；未动任何既有节点与脚本、未动 instance 覆盖段 |
| `godot/scripts/combat/verify_wave_runtime_v040.gd` | **新写** | extends SceneTree；37 条断言覆盖三波推进 / 超时 / 失败 / 重复触发 / 依赖缺失降级 / 信号接线 / courtyard 回读 |
| `teamwork/Rank-1/DONE-R26.md` | 本文 | 实际交付 / 真跑结论 / 未完成项 |
| `teamwork/Rank-1/r26_*.log` | 真跑日志 | G1 ×1 / G2 ×11 / RUN ×7 / G3 ×1 / 早期诊断 ×1，共 21 份 |
| `teamwork/command_center/ai/1/outbox/cmd-20261111-073556-918-A1.json` | 回执 | 严格按任务单 id 写到精确路径 |

**零写入**：任何素材 PNG / `.tres`（含 Rank-2 的 `wave_trial.tres`、`wave_trial_config.gd`）、`project.godot`、契约 / GDD / README、`godot/test/presentation.gd`、其它 Rank 目录既有文件、其它 `.tscn`。`ground_tile_mat_{plate,low,high}.tres` 只被原 ext 声明引用、未改一字（目录所有权「其余 .tres 本轮任何人都不得写」）。

> 并发事实（如实登记）：本轮执行期间 Rank-2 于 07:45 落盘 `wave_trial.tres` / `wave_trial_config.gd`，其 `waves` 为 `Array[Dictionary]`（非 `Array[WaveData]`）。首版 director 只认 Object 行 → G3 出现降级 warning「波次条目非 Object」；已改为同时兼容 Dictionary 行与 Resource 行（`_parse_wave()`），最终 G3 无 WaveTrial warning、正常读到 3 波。Rank-1 零改 Rank-2 文件。

## 2. 状态机与信号清单

| 项 | 内容 |
|---|---|
| 状态机 | `IDLE → TELEGRAPH(入场预告) → WAVE_ACTIVE(倒计时) → WAVE_CLEARED → NEXT_WAVE → (下一波 TELEGRAPH)` / `TRIAL_COMPLETED`；失败 / 超时 → 回 `IDLE`（赐福休息），不推进波次 |
| 信号 | `wave_started(index: int, total: int)`（进入每波 TELEGRAPH 时发）；`wave_cleared(index: int, points: int)`（清波时发）；`trial_completed(best_wave: int)`（全清时发） |
| 时序来源 | 波数 / `telegraph_sec` / `time_limit_sec` / `reward_points` 全部运行期读 `res://data/rpg/wave_trial.tres`（Rank-2），`_load_table()` 用 `CACHE_MODE_IGNORE`；**代码不读** `enemy_id` / `hp_multiplier` / `move_weight`（战斗数值交 Rank-2） |
| 编排边界 | 不写 flag、不 set_flag、不构造 flag key、不写存档；flag 与持久化交 Rank-3 |
| 单一时间入口 | `_advance(delta)`：`_process` 与 `debug_advance(sec)` 走完全相同代码路径（verify 可确定性断言） |
| 降级 | load 失败 / `waves` 缺失 / 波次字段缺失或非数值 / 时序 ≤ 0 → 一律降级为「单波默认试炼」+ `push_warning` 如实登记；**不崩溃、不硬编码三波数值** |
| 降级常量 | `DEGRADED_TELEGRAPH_SEC=1.5` / `DEGRADED_TIME_LIMIT_SEC=30.0` / `DEGRADED_POINTS=0`，均标 **[PLACEHOLDER]**；rationale：与任务书状态机 TELEGRAPH 1.5s / WAVE_ACTIVE 30s 一致，仅作 Rank-2 表缺失时的可运行兜底，表落盘后一律以表内字段为准，不据其定义任何战斗数值 |
| 门控 | `start_trial()` 仅 IDLE 接受；`on_encounter_finished(won)` 仅 WAVE_ACTIVE 接受，重复触发 / 非激活期拒绝并计数（防重复计点与跳波） |

## 3. 接既有 `encounter_director.gd` 推进波次（任务 ②）

- 波次导演 `_ready()` 解析 `encounter_director_path`（默认 `../EncounterRoot`，courtyard 内显式落盘为同一路径），订阅既有 `encounter_finished(won)` 信号；同时提供 `bind_encounter_director(node)` 供装配 / 验证注入。
- **胜利** → `_clear_wave()` → `WAVE_CLEARED` → `NEXT_WAVE` → 下一波；三波全清 → `TRIAL_COMPLETED` + `trial_completed(best_wave)`。
- **失败 / 超时** → 回 `IDLE` + 调 `_request_grace_rest()`：优先 `trial_grace_rest()`（本轮在 encounter_director 末尾追加），兜底既有 `debug_grace_rest()`，再降级为仅登记。复用既有 `_grace_rest()` 全链路（HP / 状态机 / Boss 重建 / 既有落盘），**不引入新数值**。
- 既有 `debug_*` 接口一字未动；v010 20 / v020 45 / v030 53 PASS 全不回退（见 §6）。
- verify 用真实 `encounter_director.gd` 实例 `emit_signal("encounter_finished", true/false)` 断言信号转发与「失败回赐福休息」真调用（`encounter_grace_rests=1`）。

## 4. 波次 HUD 与 uv 改动（任务 ③④ / 裁决 A19）

### 4.1 波次 HUD（courtyard 战斗 HUD 同层，只读 Label）

```
WaveTrialHud   CanvasLayer  parent="."   layer=20      # 与 EncounterRoot/HUD 同层
└─ WaveLabel   Label        rect=(24,232)-(720,264)  font_size=17  金色
   text 落盘占位 = "第 —/— 波 ｜ 赐福点数 — ｜ 倒计时 — ｜ 历史最佳 —"
   text 运行时由 wave_trial_director._refresh_hud() 刷新（Label 只读、不可交互）
```

- **[PLACEHOLDER] 布局值** `x∈[24,720] / y∈[232,264] / layer=20 / font_size=17`，rationale：需同时避开
  - 赐福 HUD `x<730, y<220` → 取 `y≥232 > 220`；
  - 画质面板 `x>760, y<180` → 取 `y≥232 > 180` 且 `x≤720 < 760`；
  - 底部战斗 HUD `y≈660` → 取 `y≤264 < 660`；
  - 「战斗 HUD 同层」→ layer=20（与 `EncounterRoot/HUD` 一致）。
  - 落盘文本用占位符「—」，不含任何硬编码波数 / 数值；实际值由数据表 + 运行时状态填充。
- **既有 HUD 文本零改动**：`StatusLabel` 仍 `text="遭遇战 v0.1.0 载入中…"` / `offset_top=660.0`；`TitleLabel` 仍 `text="赐福 · 宁姆格福"`（verify 回读断言）。
- 待试玩 / 目视校准字号与位置（本轮按「不启 GPU job」未抓帧，见 §8）。

### 4.2 uv1_scale 16/3/2 → 4/2/1（只改三处属性）

`ground_tile_mat_{plate,low,high}.tres` 归「其余 .tres 本轮任何人都不得写」，故**不改 .tres**：在 `courtyard.tscn` 内为三个地面 `MeshInstance3D` 各建一份内联 `StandardMaterial3D` sub_resource（沿用原 .tres 的 `albedo_texture` 指向 `ground_tile.png`、`texture_filter=0`，仅改 `uv1_scale`），把 `material_override` 从 `ExtResource` 换成 `SubResource`：

| 节点 | 原 uv1_scale | 新 uv1_scale |
|---|---|---|
| `GroundPlate` | `Vector3(16,16,1)` | `Vector3(4,4,1)` |
| `TerraceLow` | `Vector3(3,3,1)` | `Vector3(2,2,1)` |
| `TerraceHigh` | `Vector3(2,2,1)` | `Vector3(1,1,1)` |

- `CliffRim` 等其它节点、全部脚本、既有 instance 覆盖段一字未动。
- 头部原有 3 条 Material ext_resource 声明保留（现未被引用），未删除任何行；G1/G3 加载无 error/warning。
- 依据：`teamwork/Rank-4/艾尔登法环HD2D-美术评审报告.md` P0「`uv1_scale` 降到 4/2/1」与美术风格提案 §3。
- **裁决 A19**：`courtyard.tscn` 由 Rank-1 独占写；Rank-4 本轮只改 `ground_tile.png`、不写场景，避免并发覆盖。

## 5. 节点数回读（改动前后比对 + CACHE_MODE_IGNORE）

| 口径 | 数值 | 证据 |
|---|---|---|
| 改前 `[node ` 段 / SceneState 节点数 | **33** | R25 `DONE-R25.md` 登记 + R26 改前 `grep -c "^\[node "` 实测 33 |
| 改后磁盘 SceneState 节点数 | **36** | `verify_wave_runtime_v040.gd` 用 `ResourceLoader.load(..., "PackedScene", CACHE_MODE_IGNORE)` → `get_state().get_node_count()=36` |
| 增量 | **+3** | `WaveTrialHud` + `WaveLabel` + `WaveTrialDirector` 三个真实节点 |
| 既有回归脚本回读 | **36** | `verify_quality_interaction.gd` `[R22] LOAD ... SceneState_node_count=36 CACHE_MODE_IGNORE=true`（19 PASS 不回退，节点数仅打印、非断言） |
| 三项 uv 回读 | 4/2/1 全 true | `CACHE_MODE_IGNORE` instantiate（不 add_child、不 flush `_ready`）逐节点读 `material_override.uv1_scale` |
| instance 覆盖段回读 | 生效 | `EncounterRoot/Boss.sprite_path` 仍指向 `BossVisual/Hybrid2D3DAnimatedSprite` |

**关于「pack 前后节点数比对」的如实说明**：courtyard.tscn 沿用 R24/R25 既定流程 —— **文本精确编辑 + 末尾保留 instance 内部属性覆盖段**，本轮**未走 `PackedScene.pack()` 全量重建**（pack 会丢实例内部覆盖，正是既有踩坑）。因此「pack 前后」在本轮对应**改动前后**：33 → 36，并用 `CACHE_MODE_IGNORE` 回读确认 +3 节点、三项 uv、既有 HUD 文本与 instance 覆盖段全部生效。未谎报做过 pack。

## 6. 真跑输出结论（三段门禁 + 7 个 verify）

引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--headless --path F:/Game/aierdengfahuan/godot`。

| 段 | 命令要点 | EXIT | `SCRIPT ERROR` |
|---|---|---|---|
| G1 | `--headless --import` | 0 | 0 |
| G2 | `--headless --check-only --script` × 11（build_encounter_v010 / encounter_director / encounter_rules_v020 / verify_fx_profile / verify_fx_mobile / verify_quality_interaction / verify_encounter_v010 / v020 / v030 / **wave_trial_director** / **verify_wave_runtime_v040**） | 全 0 | 全 0 |
| G3 | `--headless --quit`（main_scene = `courtyard.tscn`） | 0 | 0 |

**21 份 `r26_*.log` 逐份 `grep SCRIPT ERROR` = 0、`Parse Error` = 0，`TOTAL_SCRIPT_ERROR = 0`。**

| verify 脚本 | 期望 | 实测 | 结论 |
|---|---|---|---|
| `verify_fx_profile.gd` | 34 | `pass=34 fail=0 RESULT=PASS` | 不回退 |
| `verify_fx_mobile.gd` | 47 | `pass=47 fail=0 RESULT=PASS` | 不回退 |
| `verify_quality_interaction.gd` | 19 | `pass=19 fail=0 RESULT=PASS` | 不回退（回读 `node_count=36`） |
| `verify_encounter_v010.gd` | 20 | `pass=20 fail=0 RESULT=ALL_MATCH` | 不回退（既有 debug_* 接口） |
| `verify_encounter_v020.gd` | 45 | `pass=45 fail=0 RESULT=ALL_MATCH` | 不回退 |
| `verify_encounter_v030.gd` | 53 | `pass=53 fail=0 RESULT=ALL_MATCH` | 不回退 |
| **`verify_wave_runtime_v040.gd`（新）** | — | **`pass=37 fail=0 RESULT=ALL_MATCH`** | 本轮新增 |

新 verify 37 条断言覆盖：真实表加载一致（表存在→3 波）、注入 3 波占位时序后的完整三波推进（TELEGRAPH→ACTIVE→CLEARED→NEXT_WAVE→…→TRIAL_COMPLETED，三个信号参数与累计点数）、超时、失败、重复触发（重复结算 / 二次 start）、依赖缺失降级（资源不存在 / 存在但无 `waves` 字段 / 单波跑完不崩 / 不出现硬编码三波）、`encounter_finished` 信号真实转发与失败回赐福休息、courtyard 节点数 / uv / HUD / 既有文本 / instance 覆盖段回读。
> 三波推进用 `configure_waves()` 注入 **[PLACEHOLDER-桩]** 纯时序（1.0 / 10.0 / 点数 1·2·3），**不是 Rank-2 设计数值**；真实表（3 波 100/150/200）的读取一致性单独断言，保证 Rank-2 表落盘与否都能确定性验证状态机。

门禁 / 运行仅有既有 WARNING（`[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`）与波次降级 / 失败登记的 `push_warning`，**均非 `SCRIPT ERROR`**，与 R23/R24/R25 日志一致。

## 7. 既有踩坑处理（如实登记）

- **`--script` 模式 `add_child` 不 flush `_ready`**：构建/验证脚本全部显式 `call("_ready")`；instantiate 但不 add_child 的场景回读不触发 `_ready`，纯结构/属性读取。
- **`/root/...` 绝对路径不可用**：本轮脚本只用相对 `NodePath`（`../EncounterRoot`、`../WaveTrialHud/WaveLabel`）与 `get_parent().get_node_or_null()` / `Engine.get_main_loop()` 口径。
- **instance 内部属性覆盖 pack 后丢失**：本轮不 pack 全量重建，保留 courtyard.tscn 末尾既有覆盖段，`CACHE_MODE_IGNORE` 回读 `sprite_path` 生效。
- **Rank-2 表结构为 `Array[Dictionary]`**：改 `_parse_wave()` 同时兼容 Dictionary 行与 Resource 行；字段缺失 / 非数值 / 时序非法一律降级单波。
- **数据表并发落盘**：首版 G3 出现降级 warning「波次条目非 Object」→ 兼容修正后正常读 3 波；中间态如实登记于 §1。
- **未新建只读探针 / 巡检脚本**：节点数 / uv / HUD 回读内建在正式验证脚本 `verify_wave_runtime_v040.gd` 中，未额外造探针。

## 8. 未完成项与阻塞（如实写未达）

1. **运行时触发入口未接线**：`WaveTrialDirector` 已挂 courtyard 且保持 `IDLE`，`start_trial()` 需由赐福交互 / Rank-3 链路调用；本轮未接自动触发（避免干扰既有画面与三段门禁）。**这是本轮最主要的未完成项**。
2. **「历史最佳」为进程内 `best_wave`**：未接 Rank-3 持久化 flag（任务明确「不写 flag，交 Rank-3」）；跨会话历史最佳待 Rank-3 接线后由外部注入 / 只读同步。
3. **「赐福点数」未与账户 / 存档对齐**：当前只累计 Rank-2 表 `reward_points` 并驱动 HUD 与 `wave_cleared` 信号，不写 flag、不落盘（归 Rank-3）。
4. **未做 15~20 秒实机录屏 / 目视回看**：本轮约束「不启 GPU job」；进度判断依据为三段门禁 + 37 条运行时断言 + `CACHE_MODE_IGNORE` 结构回读。波次 HUD 的视觉观感（字号 / 与画面重叠）待试玩目视校准，本轮只做了坐标层面的避让断言。
5. **波次 HUD 布局 / 降级时序均为 [PLACEHOLDER]**：待人工试玩校准，rationale 见 §2 / §4.1；未拍脑袋写死设计数值。
6. **Rank-2 表后续改动需复审**：director 对字段缺失 / 非法有降级保护，但若 Rank-2 改字段名或结构需重跑 `verify_wave_runtime_v040.gd` 复审。
7. **失败回赐福休息复用既有 `_grace_rest()`**（含既有 `commit` 链路）；波次导演自身不写 flag、不构造 key，flag 与持久化口径仍归 Rank-3。
8. 无 git 操作（总指挥收尾）。

## 9. 契约与所有权遵守

- 目录所有权：只写 `wave_trial_director.gd` / `encounter_director.gd` / `courtyard.tscn` / `verify_wave_runtime_v040.gd` / `teamwork/Rank-1/`；未写任何素材 PNG / `.tres`（含 `wave_trial.tres`）/ `project.godot` / 契约 / GDD / README / `presentation.gd` / 其它 Rank 目录 / 其它 `.tscn`。
- 公共契约：直接改、直接真跑；未新建只读探针 / 巡检脚本；零付费、零外部依赖、不启 GPU job；不伪造产物、不谎报成功、不自行 git。
- 回执 JSON 按任务单 id 写到精确路径 `F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/cmd-20261111-073556-918-A1.json`（`status=done`，`result` 引用本文实际结论）。**实际结果（如实登记）**：dispatcher 实时收件，写入后该文件已被移入 `teamwork/command_center/dispatcher/receipts/cmd-20261111-073556-918-A1.json`，`outbox/` 现为空 —— 属既有设计、非写入失败；已回读 receipts 那份并校验 `valid_json=True` / `task_id` / `ai=1` / `status=done` / `result` 引用本文，未重复写入以免制造第二份回执。
