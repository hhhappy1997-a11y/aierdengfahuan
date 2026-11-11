# DONE-R30.md · 赐福图鉴（成就系统运行时 + Tab 面板）

- **任务单 id**：`cmd-20261111-125001-344-A1`（[ROUND=R30]，v0.8.0 新内容，Rank-1）
- **引擎**：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）
- **工程根**：`F:/Game/aierdengfahuan`，Godot 工程 `F:/Game/aierdengfahuan/godot`
- **结论速览**：4 个可写文件全部落地并真跑；新自测 **39 PASS / 0 FAIL / RESULT=PASS**；三段门禁 **SCRIPT ERROR=0 / ERROR=0**；15 秒演示序列 f=210 注入一次真实 Tab，f=225/f=449 读回 `codex_panel_open=true`；v060 `64/86/21/48`、v070 `6/46` 全部达到。**1 项未达：`verify_wave_runtime_v040` 基线 37 → 实测 35/2，根因是 Rank-4 本轮并发的 `courtyard.tscn` 视觉属性改动导致 v040 旧断言未同步（非本轮引入、不在我可写白名单），如实登记于 §6，请总指挥裁决。**

---

## 1. 交付清单（严格限定白名单）

| 文件 | 动作 | 说明 |
| --- | --- | --- |
| `godot/scripts/combat/codex_director.gd` | **新写** | extends Node；成就状态机 + 2 信号 + Tab 面板 |
| `godot/scripts/combat/verify_codex_v080.gd` | **新写** | extends SceneTree；9 组 39 条断言 |
| `godot/scripts/hud.gd` | **最小接线** | 仅追加 2 常量 + `_ready()` 一行调用 + 第 9 节 `_ensure_codex_director()`；1~8 节既有兑换逻辑与四套 HUD 文本逐字未动 |
| `godot/test/presentation.gd` | **追加注入** | 仅追加 2 常量 + `_drive_real_input` 一处 Tab 注入分支 + `_log_input_evidence` 只读回读；既有时间线逐字未动 |
| `teamwork/Rank-1/DONE-R30.md` | 新写 | 本文件 |
| `teamwork/command_center/ai/1/outbox/cmd-20261111-125001-344-A1.json` | 新写 | 回执 |
| `teamwork/Rank-1/r30_*.log`、`r30_regress/*.log` | 新写 | 真跑门禁 / 自测 / 全回归日志（56 份） |

**未改**：`courtyard.tscn`（静态 `[node]` 行数恒 **41**）、素材、shader、契约、README、任何其它 `.tres`、`project.godot`、导演脚本。`git status` 中 `courtyard.tscn` / `hd2d_parallax.gd` / `README.md` / `ground_tile.png` / `capture/*` 等改动为 **Rank-4 / Rank-3 / Rank-2 本轮并发产出，非 Rank-1 所写**；`codex_config.gd` / `data/rpg/codex_entries.tres` / `verify_codex_reward_v080.gd` 为 Rank-2 本轮落盘。

**并发时序实证**：开工时全工程无 codex 文件；Rank-2 的 `res://data/rpg/codex_entries.tres` 在本轮真跑期间落盘。因此 `verify_codex_v080.gd` 同时覆盖两条路径——`MISSING_PATH` 强制降级（`source=builtin_default`），真实路径（`source=tres`）。真实场景门禁日志 `r30_gate3_quit.log` 显示 `source=tres entries=4 degraded=false`。

---

## 2. 图鉴状态机与信号

### 2.1 4 类成就与三段式来源 flag（事件驱动订阅，绝不每帧轮询）

| # | 成就（内置默认 title） | 条件来源 flag | 判定 |
| --- | --- | --- | --- |
| 1 | 赐福入门 / `tutorial_complete` | `grace.tutorial.completed` | bool true |
| 2 | 三波全清 / `trial_cleared` | `dungeon.wave_trial.completed` | bool true |
| 3 | 增益圆满 / `all_upgrades` | `grace.upgrade_<id>.unlocked` ×3 | 三项全 true（id 取自既有 `grace_upgrades.tres`：`hp_max_bonus` / `roll_iframe_bonus` / `attack_power_bonus`） |
| 4 | 百战之证 / `best_wave_ge3` | `dungeon.wave_trial.best_wave` | int ≥ 3 |

- 订阅 `WorldState.flag_changed(key, old, new)`（仅命中上述 4 类来源 key）+ `delta_committed(seq, reason)`（回放/注入兜底全量）。`commit()` 内部同步触发 `delta_committed` 由 `_evaluating` 守卫拦重入，不递归写盘。
- 读 Rank-2 `codex_entries.tres`：容错取 `entries/items/codex_entries` 数组，逐项取 `id`/`title`/`description`（兼容 `entry_id`/`display_name`/`desc` 等别名）覆盖显示文本与 id 段；**条件判定按任务单 4 类硬规定执行**（`condition` 内置），在 Rank-2 数据下逐项对齐。id 段经 `^[a-z0-9_]+$` 校验后才采纳。
- **降级**：资源不存在 / 加载失败 / 项数不足 4 → 内置 4 项默认 + `push_warning("[R30][CODEX] ... 降级为内置 4 项默认（并发时序，如实登记，不崩）")`；`entries_source="builtin_default"`、`degraded=true`、`degrade_reasons` 可经 `get_status()` 读回。WorldState / SaveDeltaWriter 缺失同样如实登记。

### 2.2 达成写入（裁决 A36 三段式 / 严格「先落盘再改运行时实例」）

```
① _state.set_flag("grace.codex_<id>.unlocked", true)     # 入队 SaveDelta，false→true 单向
   unlock_events += "stage_flags:<id>"
② _writer.commit("codex_unlocked")                        # SaveDeltaWriter → WorldState._commit_delta 原子写
   unlock_events += "disk_write:codex_unlocked"，commit_count += 1
③ 落盘成功后【才】 _unlocked[id]=true → codex_entry_unlocked.emit(id,title)
   → codex_progress_changed.emit(unlocked,total) → _refresh_panel()
   unlock_events += "runtime_update:<id>"
```

- **单向**：`_unlocked` 只增不减，绝不回写 false；来源 flag 复位后 codex flag 仍 true（D1 断言）。
- **重复达成不双写**：命中 `_unlocked` 直接跳过，重复 `flag_changed` / `evaluate()` 不增 commit、不增事件、不重发信号（E1/E2/E3 断言）。
- **重启恢复**：`_restore_unlocked()` 从 WorldState 读回已落盘 codex flag 恢复镜像，不回写、不重复落盘。
- **降级口径**：writer 缺失时 `push_warning` 登记「未落盘，仅进程内内存」，仍推进进程内镜像（与 `tutorial_director.gd` 同口径），不冒充原子写；主路径（FakeWriter）严格顺序由 C1/C2/C3 断言。
- **信号**：`codex_entry_unlocked(id: String, title: String)`、`codex_progress_changed(unlocked: int, total: int)`；`_ready()` 的 `_restore_unlocked()` 发一次初始进度。

### 2.3 只读接口（供 HUD / 验证读回）

`get_entries()` / `get_progress()` / `is_unlocked(id)` / `get_unlock_events()` / `get_status()` / `get_panel_rect()` / `get_panel_alpha()` / `get_row_color(i)` / `get_row_text(i)` / `get_progress_text()` / `get_layer_index()` / `get_layer_name()` / `get_layer_parent_name()` / `is_panel_open()` / `toggle_panel()` / `build_panel_now()` / `evaluate()`。

---

## 3. Tab 面板：位置与遮挡数字

- **键**：`KEY_TAB`（4194306），`_unhandled_input` 检测 `pressed && !echo`，处理完 `get_viewport().set_input_as_handled()`。经 F4 断言：教学 T(84) / E(69) / 1(49) 均不触发，不与教学 T 键冲突、不干扰兑换。F1 默认隐藏、F2 打开、F3 再按关闭、F5 release 不触发。
- **独立 CanvasLayer**：`CodexPanelLayer`，`layer=46`（高于 QualitySettings=40 / 兑换层=45 / HUD=20），运行时挂在 `CodexDirector` 自身下（同在根 viewport、SubViewport 之外，不受 `stretch_shrink` 缩放）。**不写 courtyard.tscn 任何节点**：静态 `[node]` 行数恒 **41**，场景文本无 `CodexPanelLayer` / `CodexDirector`（H1/H2 断言）。运行时新增 9 节点（1 director + 1 CanvasLayer + 1 Panel + 6 Label），均为运行期建层。
- **面板矩形**：`(24,272)-(380,508)`，宽 **356** × 高 **236** = **84,016 px²**。

避让矩形（`courtyard.tscn` 实读 / R29B 真跑像素框）与几何交集（G1 断言，全部 **0 px²**）：

| 避让对象 | 矩形 | 与面板交集 |
| --- | --- | --- |
| 赐福 HUD | x<730, y<220 | 0（面板 top=272 > 220） |
| 画质面板 | x>760, y<180 | 0（面板 x≤380） |
| 波次 HUD `WaveLabel` | (24,232)-(720,264) | 0（面板 top=272 > 264） |
| 教学 HUD `TutorialLabel` | (24,520)-(1100,556) | 0（面板 bottom=508 < 520） |
| 兑换面板（R29 运行时迁出） | (740,358)-(1276,568) | 0（面板 right=380 < 740） |
| 底部战斗 HUD `StatusLabel` | (24,660)-(1224,692) | 0（面板 bottom=508 < 660） |
| 玩家包围盒 | (400,320)-(690,570) | 0（面板 right=380 < 400） |
| Boss 包围盒 | (645,230)-(880,350) | 0（面板 right=380 < 645） |

- **半透明底**：`Color(0.04,0.06,0.12,0.30)`，alpha **0.30 ≤ 0.35**（G3 断言），不近黑实心、不遮角色。
- **内容**：标题「赐福图鉴　[Tab 开关]」+ 4 行「✓/○ 名称｜描述」+ 「进度 n/4」；已达成 `GOLD(0.83,0.68,0.3,1)` 高亮、未达成 `DIM(0.55,0.54,0.50,1)`（G5/G6/G7 断言）。
- 所有布局数值标 `[PLACEHOLDER]` 待试玩目视校准，源码逐项写 rationale。

---

## 4. presentation.gd 真实输入路由（15 秒演示序列）

`r30_presentation.log`（`--headless --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`，450 帧完成，SCRIPT ERROR=0 / ERROR=0）：

```
[R30][CODEX][INPUT] frame=210 注入真实按键 Tab(KEY_TAB=4194306) -> Input.parse_input_event(InputEventKey) -> CodexDirector._unhandled_input 打开赐福图鉴面板
[R30][CODEX][TAB] toggle → visible=true
[R28][EVIDENCE] frame=0   ... codex_panel_open=false      （默认隐藏）
[R28][EVIDENCE] frame=225 ... codex_panel_open=true       （中帧证明已打开）
[R28][EVIDENCE] frame=449 ... codex_panel_open=true       （尾帧仍可见）
```

- 全程经既有 `_inject_key()` → `Input.parse_input_event(InputEventKey)` 真实输入系统路由，**不写任何 Label.text、不调 debug_* 伪造数值、不改四套 HUD 文本**。
- 演示中成就按真实 flag 变化解锁（`id=tutorial_complete` / `best_wave_3` / `wave_trial_clear`，id 取自 Rank-2 tres，数据驱动生效）。
- `capture/` 归 Rank-4，Rank-4 本轮已产出 `capture/v080_demo.mp4` 等；Rank-1 不启 GPU job，Tab 可打开的证明以上述 headless 真跑日志为准，不自行录屏、不谎报目视回看。

---

## 5. 三段门禁 + 新自测 + 全回归（真跑输出结论）

引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--headless --path F:/Game/aierdengfahuan/godot`。

### 5.1 三段门禁（全部 EXIT=0，`r30_gate*.log` / `r30_check_*.log`）

| 段 | 命令 | 结果 |
| --- | --- | --- |
| G1 | `--headless --import` | EXIT=0，SCRIPT ERROR=0 / ERROR=0 |
| G2 | `--check-only --script` × 13（4 个本轮脚本 + tutorial/wave/encounter/world_state/save_system + 3 个基线 verify） | 全 EXIT=0 |
| G3 | `--headless --quit-after 90 res://scenes/courtyard.tscn` | EXIT=0，**SCRIPT ERROR=0 / ERROR=0** |

G3 真实场景集成日志（证明运行时挂载生效、不写场景节点）：
```
[R30][HUD] 运行时挂载 CodexDirector → Courtyard（独立 CanvasLayer 由导演自建，不写 courtyard.tscn）
[R30][CODEX] 读到 Rank-2 图鉴资源 entries=4（显示文本/ id 覆盖内置默认，条件仍按 4 类判定）
[R30][CODEX] ready | source=tres entries=4 degraded=false | 面板 deferred 建层(独立 CanvasLayer，不写场景)
[R30][CODEX][PANEL] 独立 CanvasLayer(layer=46) 建层 | rect=(24,272)-(380,508) alpha=0.30 | 默认隐藏 | 不写 courtyard.tscn
```

**56 份门禁 / 自测 / 全回归日志汇总**：`SCRIPT ERROR` / `Parse Error` 命中 **0**。门禁 G3 与 presentation 日志 `ERROR` 命中 **0**。

### 5.2 新自测 `verify_codex_v080.gd`（`r30_verify_codex_v080.log`）

`pid` 真实、`EXIT=0`、**`SUMMARY pass=39 fail=0 ok=true`**、**`RESULT=PASS`**、SCRIPT ERROR=0。9 组：
A 依赖缺失降级(6) / B 4 项条件与边界(8) / C 先落盘再改运行时(4) / D 单向(2) / E 重复不双写(3) / F Tab 开关(5) / G 面板不遮角色与高亮(7) / H 节点数 41(2) / I 三段式合法(2)。

### 5.3 v060 / v070 基线（真跑，`r30_regress/*.log`）

| 基线 | 脚本 | 实测 | 结论 |
| --- | --- | --- | --- |
| v060 | `verify_tutorial_v060` | `pass=64 fail=0 RESULT=ALL_PASS` | 达到 64 |
| v060 | `verify_tutorial_reward_v060` | `pass=86 fail=0 RESULT=ALL_MATCH` | 达到 86 |
| v060 | `verify_tutorial_flags_v060`（Rank-3 三态，两/三独立 pid） | selftest 15 + write 3 + read 3 | 达到 21 |
| v060 | `verify_tutorial_restart_v060` | `pass=48 fail=0 RESULT=ALL_PASS` | 达到 48 |
| v060 | `verify_wave_runtime_v040` | **`pass=35 fail=2`** | **未达 37，见 §6.1** |
| v070 | `verify_hud_depth_v070`（write→read 两进程） | `RESULT=WRITE_OK` → `pass=6 fail=0 RESULT=ALL_PASS` | 达到 6 |
| v070 | `verify_depth_profile_v070` | `pass=46 fail=0 total=46 RESULT=PASS` | 达到 46 |

### 5.4 既有全回归（26 个工程内 verify + 三态 + 两进程）

全部 `EXIT=0` 且 RESULT 通过，除 §6 两项外无回退。抽样：`verify_grace_upgrade_v050` 127、`verify_grace_runtime_v050` 58、`verify_wave_trial_v040` 58、`verify_wave_persist_v040` 45、`verify_save_isolation_v060` 31、`verify_encounter_v010/v020/v030` 20/45/53、`verify_fx_mobile` 47、`verify_fx_profile` 34、`verify_quality_interaction` 19、`verify_hud_binding` 11、`verify_boss_*` / `verify_combat_runtime` / `verify_frame_data` / `verify_pose_names` PASS。
Rank-2 本轮 `verify_codex_reward_v080`：`pass=124 fail=0 RESULT=PASS`（并发产物，如实登记）。

- `verify_persistence_hud_v050` 批量首跑 `29/1 HAS_FAIL`（A2 十字段缺 `slot`/`quests`）→ **单独复跑两次均 `30 ALL_PASS`** 翻案。与 DONE-R29B.md §6.2 完全同一「存档为测试态 / 前序 verify 经真实 commit 覆盖 `delta.json`」既有现象，与 hud.gd 本轮接线无关（A2 只检查存档顶层字段）。失败日志原样保留 `r30_regress/verify_persistence_hud_v050.log`，不隐藏、不冒充一次成功。

---

## 6. 未完成项 / 阻塞（如实登记，请总指挥裁决）

1. **`verify_wave_runtime_v040` 基线 37 → 35/2（唯一未达基线项）**：两条断言 `uv_groundplate_4`（期望 (4,4,1)，实读 (2,2,1)）、`uv_terracelow_2`（期望 (2,2,1)，实读 (1,1,1)）FAIL；连续单独复跑两次稳定 35/2。根因经 `git diff -- godot/scenes/courtyard.tscn` 确认：
   ```
   +; [R30 v0.8.0 · A35 Rank-4 独占视觉属性] [PLACEHOLDER] uv1_scale 4/2/1 → 2/1/1，待试玩校准
   -uv1_scale = Vector3(4, 4, 1)   +uv1_scale = Vector3(2, 2, 1)
   -uv1_scale = Vector3(2, 2, 1)   +uv1_scale = Vector3(1, 1, 1)
   ```
   即 **Rank-4 本轮 12:58 授权的并发视觉属性改动**使 v040 旧期望值失配；`courtyard.tscn` 与 `verify_wave_runtime_v040.gd` 均不在 Rank-1 可写白名单（任务单 ⑥），我未改场景 / 材质 / 画质任何文件，本轮 4 个文件与该断言无因果关系（第 3 条 uv_terracehigh_1 与其余 35 条断言全 PASS，含节点数 41）。
   **不谎报「37 不回退」**，请总指挥裁决：由 v040 脚本归口方同步期望值至 2/1/1，或由 Rank-4 回退视觉改动。
2. **`--script` 退出 `2 ObjectDB instances were leaked` 告警**：工程既有现象（256 份历史日志同样存在），非 SCRIPT ERROR、非本轮引入；已将夹具改为倒序释放（先断信号再释放监听者），告警仍为引擎既有输出。
3. **全回归 `verify_encounter_v010/v020/v030` 日志含 11 行既有 ERROR**（`Can't use get_node() with absolute paths from outside the active scene tree` ×8、`Signal 'boss_defeated' is already connected` ×3）：30 份历史日志同样存在，三脚本 RESULT 均 `ALL_MATCH`、EXIT=0；门禁 G3 / presentation 日志 ERROR=0。非本轮引入（`codex_director.gd` 未用 `/root/` 绝对路径、未连 `boss_defeated`）。
4. **降级路径口径**：writer 缺失时如实登记「未落盘」但仍推进进程内镜像（沿用 `tutorial_director.gd` 既有口径）；主路径严格「先落盘再改运行时实例」已由 C1/C2/C3 与 G3 真实场景日志证明。若总指挥要求降级时连进程内镜像都不推进，请裁决后我改。
5. **[PLACEHOLDER] 数值**：面板 rect / 字号 14 / 颜色 / layer=46 / `CODEX_TAB_FRAME=210` / `BEST_WAVE_TARGET=3` 均为布局与判定值，源码已写 rationale，待 15~20 秒试玩目视校准。
6. **录屏归属**：`capture/` 归 Rank-4；Rank-1 遵守「不启 GPU job」，未自行产出录屏，Tab 可打开的证明用 §4 headless 15 秒序列真跑日志。未做 Rank-1 侧目视回看（画面归 Rank-4）。
7. **回执时序**：按精确路径写入 `teamwork/command_center/ai/1/outbox/<id>.json`；若写后立即读 `exists=False`，系中枢 outbox 实时消费清空（DONE-R28B §8 / DONE-R29B §8 同一时序现象），归档应以 `teamwork/command_center/dispatcher/receipts/` 为准，按幂等不重复写第二份。

---

## 7. 回执

- 精确路径：`F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/cmd-20261111-125001-344-A1.json`
- 内容：`{"task_id":"cmd-20261111-125001-344-A1","ai":1,"status":"done","result":"引用 teamwork/Rank-1/DONE-R30.md 实际结论：..."}`（result 含 39 PASS / 三段门禁 SCRIPT ERROR=0 / v060 64·86·21·48·35* / v070 6·46 / 面板 rect 与 0 px² 交集 / §6 未完成项）。
- **写入实证（如实）**：写后读精确路径 `exists=False`，系中枢 `outbox/` 实时消费清空（DONE-R28B §8 / DONE-R29B §8 同一时序现象），非未写。归档件 `teamwork/command_center/dispatcher/receipts/cmd-20261111-125001-344-A1.json`（**3146 字节**，13:20:36）读回校验：`json_valid=True`、`keys=['task_id','ai','status','result']`、`task_id=cmd-20261111-125001-344-A1` / `ai=1` / `status=done` / `result_len=1971`；`ai/1/status.json` 同步 `completed=49 / state=idle / last_seen=2026-11-11 13:20:36`。按幂等 / 并发保护**不重复写第二份回执**。
- 最终复核（`r30_final_*.log`）：4 个文件 `--check-only` 全 EXIT=0；`verify_codex_v080` 最终真跑 `pass=39 fail=0 RESULT=PASS / EXIT=0`。
- 未自行 git（总指挥收尾）。
