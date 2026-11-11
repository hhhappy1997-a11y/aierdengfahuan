# DONE-R29 · Rank-1（引擎架构与渲染）

- **任务单 id**：`cmd-20261111-112803-982-A1`（[ROUND=R29]，v0.7.0 完善旧内容）
- **工程根**：`F:/Game/aierdengfahuan`；Godot 工程 `F:/Game/aierdengfahuan/godot`
- **引擎**：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）
- **结论速览**：四项任务全部落地并真跑实证 —— ① 段 B 兑换面板文字在 low/medium/high 三档一致清晰可读（迁出 SubViewport 到独立 CanvasLayer + 固定字号 20 + 描边/阴影/深底高对比），改前/改后 450 帧录屏 + ViewImage 目视 + 像素量化对照齐全；② 首帧动作帧由 `动作 idle 0/0` 变为 `动作 attack_light 1/27`（`_initialize()` 内预热真实 J 输入路由，仍走 `Input.parse_input_event`）；③ 新写 `verify_hud_depth_v070.gd` 完成 step_index 跨 exe 读回实证（进程 A pid=11812 写盘 → 进程 B pid=27864 真实场景自动 `_load()` 读回 `3/true` + `SaveSystem.is_loaded()=true`，6 PASS / 0 FAIL）；④ 三段门禁 13 份日志 `SCRIPT ERROR=0`，全回归 23 个工程内 verify + Rank-3 三态口径件全部既有 PASS 不回退（`64 / 86 / 21 / 48 / 37` 全达到），57 份 `r29_*.log` 全量 `SCRIPT ERROR=0`、`PASS=false/fail>0=0`。
- **零付费 / 零外部依赖 / 未启 GPU job / 未新建只读探针巡检脚本 / 未自行 git**（总指挥收尾）。

---

## 1. 写清单核对（只写白名单）

| 文件 | 动作 | 内容 |
|---|---|---|
| `godot/scripts/hud.gd` | 改写 | R29 兑换面板文字可读性：新增 8 个 `[PLACEHOLDER]` 布局常量、新增 `_ensure_shop_readable()` / `_deferred_shop_readable()`；`_ready()` 在缓存 `_shop_label` 后调用一次。既有 1~8 节 / 兑换逻辑（`get_shop_view` / `purchase_upgrade` / `_refresh_shop_hud`）/ 四套 HUD 位置逐字未动 |
| `godot/test/presentation.gd` | 改写 | R29 首帧延迟修复：头部注释 + `_initialize()` 末尾调用 `_prewarm_action_input()` + 新增该函数。`_drive_real_input` 的 `f=0 J / f=6 Space / f=20 E` 教学时间线逐字未动 |
| `godot/scripts/combat/verify_hud_depth_v070.gd` | **新写** | `extends SceneTree` 三模式（write / read / selftest），跨 exe 读回 6 条断言 |
| `capture/v070_hud*.png` | 新增 | 改前/改后各 450 帧录屏序列 + 8 张语义化对照帧（见 §2.4） |
| `teamwork/Rank-1/` | 追加 | `DONE-R29.md` + 57 份 `r29_*.log` 真跑日志 |
| `teamwork/command_center/ai/1/outbox/cmd-20261111-112803-982-A1.json` | 回执 | 按精确路径写入 |

**未写**：`courtyard.tscn` / 导演脚本（除本轮未改的 `tutorial_director.gd`）/ shader / 素材 PNG / `.tres` / `project.godot` / 契约 / `README.md` / 其它 Rank 目录 / 其它 verify 脚本。`grace.tutorial.step_index` 未改 `world_state.gd` 正则、不动 `schema_version=3`、不新增顶层字段。

---

## 2. ① 段 B：兑换面板文字三档可读（改前/改后真跑对照）

### 2.1 根因（改前三档抓帧实证）

`courtyard.tscn` 的 `GraceShopLabel` 挂在 `SubViewportContainer/SubViewport/FXLayer/Hud`（**SubViewport 内**），`quality_settings.apply()` 按档位改写 `SubViewportContainer.stretch_shrink`（low=3 / medium=2 / high=1）与 SubViewport 内部渲染尺寸（480×270 / 640×360 / 960×540）。Label 用屏幕绝对坐标 `offset=(24,300)-(1100,470)` 与 `font_size=16`，在小尺寸 SubViewport 内被整体拉伸/裁剪：

| 档位 | 改前表现（ViewImage 目视） |
|---|---|
| medium (frame 50) | 文字被推到 **y≈610**，与底部战斗 HUD（y≈660）**重叠**，后两行被截断 |
| low / mobile (frame 200) | `offset` 远超内部视口 → **兑换面板文字完全消失**（段 B 核心缺陷） |
| high (frame 350) | 文字叠在砖地上、字号小、无底色、对比度低，勉强可辨 |

### 2.2 修法（`hud.gd`，不改 courtyard.tscn / 不改兑换逻辑 / 不改四套 HUD 位置）

1. **迁出 SubViewport**：`_ensure_shop_readable()` 沿祖先链找到 `SubViewportContainer`，取其父节点（Courtyard 根，SubViewport 外）新建一个独立 `CanvasLayer`（`GraceShopReadableLayer`，`layer=45`），把 `_shop_label` `reparent()` 进去。CanvasLayer 铺满真实 1280×720 视口，**不受 `stretch_shrink` 影响**。
2. **固定字号 + 高对比度**：`add_theme_font_size_override("font_size", 20)`、近白暖色 `font_color`、深色 `font_outline_color`/`outline_size=6`、`font_shadow_color` + shadow offset、半透明深蓝 `StyleBoxFlat`（`normal` stylebox，金边 + 内边距）。
3. **位置不变**：保留既有 `offset=(24,300)-(1100,470)`，落在屏幕中部，天然避开 赐福 HUD `x<730,y<220` / 画质面板 `x>760,y<180` / 波次 HUD `y≈232` / 教学 HUD `y≈520` / 底部战斗 HUD `y≈660`。
4. **降级保护**：独立 `hud.tscn` 实例（`--script` 验证）祖先链无 `SubViewportContainer`，判空降级、不迁节点、不改节点路径与属性 → 保护既有 `58 / 30 / 11 / 127` PASS 断言不回退。
5. **时序踩坑（如实登记，真跑发现并修复）**：首版在 `_ready()` 里直接 `outside_root.add_child(layer)`，Godot 报 `ERROR: Parent node is busy setting up children, add_child() failed`，层未入树、Label 被 reparent 到游离节点 → 三档文字全部消失。改为 **`call_deferred("_deferred_shop_readable", outside_root)`**，把「建层 + reparent + theme」推迟到本帧 `_ready` 传播完成后、首帧渲染前执行；复跑该 ERROR 与退出时 RID/ObjectDB 泄漏告警均消失。

### 2.3 真跑方式

改前 / 改后各跑一次完整 450 帧录屏（一次覆盖三段画质：f=0 medium / f=150 low / f=300 high）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/v070_hud_<before|after>.png \
  --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd \
  res://scenes/courtyard.tscn
```

两次均 `EXIT=0`、450 帧、1280×720 @30FPS（日志 `r29_before_capture.log` / `r29_after_capture2.log`）。

### 2.4 前后对照（帧文件 + 像素量化）

| 语义化帧（同档同帧号对照） | 改前 | 改后 |
|---|---|---|
| medium | `capture/v070_hud_before_medium.png`（frame 50） | `capture/v070_hud_after_medium.png`（frame 50） |
| low / mobile | `capture/v070_hud_before_low.png`（frame 200） | `capture/v070_hud_after_low.png`（frame 200） |
| high | `capture/v070_hud_before_high.png`（frame 350） | `capture/v070_hud_after_high.png`（frame 350） |

**像素量化**（区域 `(24,300)-(1100,470)`；深底=深蓝半透背景像素、近白字=改后字体色像素、高对比边缘=亮度差>55 的相邻像素对；`python + PIL/numpy` 内联计算，不落盘脚本）：

| 档位 | 版本 | 深底 px | 近白字 px | 高对比边缘 |
|---|---|---:|---:|---:|
| medium | before | 6,752 | 56 | 848 |
| medium | **after** | **160,569** | **12,276** | **22,197** |
| low | before | 17,577 | 387 | 2,225 |
| low | **after** | **159,405** | **13,033** | **23,731** |
| high | before | 1,984 | 110 | 2,945 |
| high | **after** | **159,407** | **13,059** | **23,354** |

结论：改后三档深底 ≈159~161k、白字 ≈12.3~13.1k、边缘 ≈22~24k，**数值几乎一致**，证明渲染结果不再随 `stretch_shrink` 变化；改前 low 档白字仅 387px（背景噪点，无可读文字）。

**ViewImage 目视**（改后三档，逐行可读）：深色金边半透明面板内 5 行近白文字 ——
```
赐福成长 ｜ 当前余额 100（点数 100 − 已消费 0） ｜ 1/2/3 兑换
  1. 赐福·生命上限 ｜ 消耗 100 ｜ 可兑换
  2. 赐福·翻滚余韵 ｜ 消耗 200 ｜ 点数不足
  3. 赐福·攻击强化 ｜ 消耗 300 ｜ 点数不足
提示：按 E 打开/关闭；数字键 1 / 2 / 3 兑换
```
与赐福金色 HUD、右上画质面板、底部战斗 HUD 均不重叠（约束满足）。日志证据 `[R29][SHOP] 兑换面板迁出 SubViewport → 独立 CanvasLayer(layer=45) | 固定字号=20 ... | rect=(24,300)-(1100,470)`。

---

## 3. ② 首帧动作帧 1 帧延迟修复

- **根因（改前日志实证）**：`r29_before_capture.log` 的 `[R28][EVIDENCE] frame=0 ... StatusLabel=... 动作 idle 0/0 ...` —— `_on_frame(f=0)` 内 `Input.parse_input_event` 注入的 J 要等下一帧输入 flush 才分发，Movie Maker 抓取的录屏首帧恒为 `idle 0/0`。
- **修法（`presentation.gd`）**：在 `_initialize()` 内（第 0 帧之前、`process_frame.connect` 之后）调用 `_prewarm_action_input()`，经既有 `_inject_key(KEY_J)` → `Input.parse_input_event(InputEventKey)` **预热注入一次真实 J**。绝不写 `Label.text`、不调 `debug_*` 伪造数值；`_drive_real_input` 的 `f=0 J / f=6 Space / f=20 E` 教学三步时间线逐字保留（预热 J 额外消费一次 `light_attack`，教学第 2 步期待 Space，重复 J 不推进教学、不破坏闭环）。
- **前后对照**：

| 证据 | 改前 | 改后 |
|---|---|---|
| 首帧画面（`capture/v070_hud_before_frame0.png` / `after_frame0.png`） | 底部 `动作 idle 0/0`，教学 HUD `1/3`，兑换提示挤在 y≈610 | 底部 `动作 attack_light 1/27`，教学 HUD `2/3`（预热 J 被真实消费），兑换面板在 (24,300) |
| 日志 `[R28][EVIDENCE] frame=0` | `动作 idle 0/0` | `动作 attack_light 1/27` |
| 日志新增 | — | `[R29][INPUT] _initialize 预热注入真实按键 light_attack(J) -> Input.parse_input_event(...)` |

---

## 4. ③ step_index 跨 exe 重启读回实证（补 DONE-R28B §7.3 缺口）

新写 `godot/scripts/combat/verify_hud_depth_v070.gd`（`extends SceneTree`，三模式 write / read / selftest）。两个**独立引擎进程**，pid 不同，全部真实 I-1 入口，不伪造：

| 进程 | 命令要点 | pid | 输出 |
|---|---|---|---|
| A（写） | `--headless --path <godot> --script res://scripts/combat/verify_hud_depth_v070.gd -- phase=write` | **11812** | `_load()` 保留历史 → `WorldState.set_flag("grace.tutorial.step_index", 3)` + `set_flag("grace.tutorial.completed", true)` → `SaveDeltaWriter.commit("v070_step_index_write")`；`[V070][WRITE] 落盘完成 ... step_index=3.0 completed=true`；`RESULT=WRITE_OK` |
| B（读） | `--headless --path <godot> --quit-after 60 --script res://scripts/combat/verify_hud_depth_v070.gd res://scenes/courtyard.tscn -- v050_read phase=read` | **27864** | 真实主场景 `Courtyard=true`、`v050_read=true` → SaveSystem autoload 自动 `WorldState._load()` 读盘；`[V070][READ] 读回值 step_index=3 completed=true \| SaveSystem.is_loaded()=true`；`SUMMARY pass=6 fail=0` / `RESULT=ALL_PASS` |

B 的 6 条断言：`R1 step_index==3` / `R2 completed==true` / `R3 SaveSystem.is_loaded()==true` / `R4 磁盘 delta.json 两 flag==3/true` / `R5 内存读回==磁盘读回` / `R6 两个 key 合法三段式正则`，全 PASS。

**口径如实登记**：
- 进程 B 用 `--script` **仅承载断言**，同时带【真实主场景 `res://scenes/courtyard.tscn`】与【`v050_read` 用户标记】—— SaveSystem 的 `_readback_allowed()` 在 `--script` 下仅显式带该标记才允许 `WorldState._load()`，故 `is_loaded()=true` 是真实读盘而非降级；纯 `--script` 工具进程（无场景、无标记）会如实降级为 false（R27 既有口径）。这兑现任务单踩坑「进程 B 必须用真实场景或带 v050_read 标记」的组合。
- **附加证据**：另跑纯真实场景 `--headless --quit-after 30 res://scenes/courtyard.tscn`（**无 --script、无标记**，`r29_v070_pure_scene_readback.log`，`EXIT=0 / SE=0`），日志 `[SaveSystem] 自动读回完成 | ...` 证明真实场景恒自动读盘。
- 磁盘终态（python 直读 `user://saves/slot_01/delta.json`）：十字段齐全、`schema_version=3`、`grace.tutorial.step_index=3` / `grace.tutorial.completed=true` 真实存在，另含全回归写入的 `best_wave=7 / points=1337 / completed=true`。
- **写盘后关键回归复核全 PASS**：`verify_persistence_hud_v050=30` / `verify_hud_binding=11` / `verify_tutorial_v060=64` / `verify_wave_runtime_v040=37` / `verify_tutorial_restart_v060=48`（`r29_postwrite_*.log`），证明写 step_index 不破坏既有回归。

---

## 5. ④ 三段门禁 + 全回归（真跑输出结论）

引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--headless --path F:/Game/aierdengfahuan/godot`，串行单进程。

### 5.1 三段门禁（13 份日志，`SCRIPT ERROR` / `Parse Error` = 0）

| 段 | 命令要点 | EXIT | SCRIPT ERROR |
|---|---|---|---|
| G1 | `--headless --import` | 0 | 0 |
| G2 | `--headless --check-only --script` ×11（hud / presentation / verify_hud_depth_v070 / tutorial_director / wave_trial_director / encounter_director / verify_tutorial_v060 / verify_wave_runtime_v040 / verify_tutorial_restart_v060 / save_system / world_state） | 全 0 | 全 0 |
| G3 | `--headless --quit-after 90 res://scenes/courtyard.tscn` | 0 | 0 |

### 5.2 全回归：工程内 23 个 verify（`r29_regress_*.log`，全 EXIT=0 / SE=0）

| 组 | 实测 | 组 | 实测 |
|---|---|---|---|
| `verify_wave_persist_v040` | `45 ALL_PASS` | `verify_encounter_v010/v020/v030` | `20 / 45 / 53 ALL_MATCH` |
| `verify_persistence_hud_v050` | `30 ALL_PASS` | `verify_wave_trial_v040` | `58 ALL_MATCH` |
| `verify_fx_mobile / fx_profile / quality_interaction` | `47 / 34 / 19 PASS` | `verify_grace_upgrade_v050` | `127 ALL_MATCH` |
| `verify_hud_binding` | `11 (AUTOLOAD_OK)` | `verify_grace_runtime_v050` | `58 ALL_PASS` |
| `verify_boss_phase / poses / runtime` | `RESULT=PASS` | **`verify_tutorial_reward_v060`** | **`86 ALL_MATCH`** |
| `verify_combat_runtime` | `PASS=27 FAIL=0` | **`verify_tutorial_v060`** | **`64 ALL_PASS`** |
| `verify_frame_data / pose_names` | `ALL_MATCH / PASS` | **`verify_wave_runtime_v040`** | **`37 ALL_MATCH`** |
| `verify_save_isolation_v060` | `31 ALL_MATCH` | **`verify_tutorial_restart_v060`** | **`48 ALL_PASS`** |

任务点名数字 **`64 / 86 / 21 / 48 / 37` 全部实跑达到、不回退**。

### 5.3 Rank-3 三态口径件（`r29_regress_*flags*.log` / `r19_verify_hud.log`）

| 组 | 实测（三独立进程 pid 全不同） | 结论 |
|---|---|---|
| `verify_tutorial_flags_v060`（**21**） | selftest `15` (pid 25056) + write `3` (pid 29208) + read `3` (pid 14416) | 不回退 |
| `verify_wave_flags_v040`（**23**） | selftest `17` (pid 11084) + write `3` (pid 844) + read `3` (pid 24744) | 不回退 |
| `r19_verify_hud`（**20**）+ `verify_hud_binding`（11） | `20 / 11` → `31` | 不回退 |

### 5.4 全量日志汇总

`teamwork/Rank-1/r29_*.log` 共 **57 份**：`grep -l "SCRIPT ERROR|Parse Error"` 命中 **0** 个文件；`grep -l "PASS=false|fail=[1-9]"` 命中 **0** 个文件；`TOTAL_SCRIPT_ERROR=0`。

---

## 6. 未完成项与如实边界

1. **未做人工试玩目视校准**：本轮以 `--write-movie` 450 帧 / 15 秒 CPU 录制（非 GPU job）+ ViewImage 目视 + 像素量化判断进度；新增数值 `SHOP_FONT_SIZE=20` / `SHOP_LAYER_INDEX=45` / 颜色 / 描边尺寸 / 预热键位 J 均标 `[PLACEHOLDER]`，写清 rationale（20px×5 行≈120px 装进既有 170px 高度；layer 45 高于 QualitySettings=40），待试玩校准。
2. **契约文案未改**：`00-协作契约.md` / `WAVE-TRIAL-GDD.md` / `README.md` 不在本轮白名单；本轮未引入新的契约口径变更（DONE-R28B §7.1 登记的 A26 差异仍待总指挥裁决）。
3. **存档为测试态**：本轮 `verify_hud_depth_v070` 写进程 + 全回归若干脚本经真实 `set_flag` + `commit` 多次落盘覆盖 `slot_01/delta.json`（当前含 `step_index=3 / completed=true / best_wave=7 / points=1337`）；均为真实写入、非伪造产物，后续如需干净基线由编排层归一化。
4. **并发改动（如实登记）**：`git status` 显示其它 Rank 正在并发修改 `courtyard.tscn` / `hd2d_parallax.gd` / `README.md` / 契约文档 / 各 Rank 调度单；录屏日志出现 `[R29][DEPTH]` / `[R29][GRADE]` / `[R29][FINALE]` 等非本 AI 产出的 R29 行。本 AI 未写这些文件；复核 `courtyard.tscn` 节点数仍 `41`、`GraceShopLabel` 定义与 `font_size=16` 未变，`verify_wave_runtime_v040` 的 `37 PASS`（`NODE_COUNT_AFTER=41`）不受影响。
5. **首版 add_child 时序缺陷已修复并复跑**：见 §2.2 第 5 点；改前 `busy setting up children` 那份日志已被 `r29_after_capture2.log` 的干净复跑取代，不隐瞒、不冒充一次成功。
6. **录屏产物**：`capture/v070_hud*.png` 共 908 张（改前/改后各 450 帧序列 + 8 张语义化对照帧），全部落在白名单 `capture/v070_hud*.png` 内；Movie Maker 自动生成的 2 个 `.wav`（非白名单）已清理。
7. 未自行 `git`（总指挥收尾）；零付费、零外部依赖、未启 GPU job；未新建只读探针 / 巡检脚本（新 `verify_hud_depth_v070.gd` 是任务单 ③ 明确要求的正式验证载体）。

---

## 7. 回执

- 精确路径：`F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/cmd-20261111-112803-982-A1.json`
- 内容：`{"task_id":"cmd-20261111-112803-982-A1","ai":1,"status":"done","result":"引用 DONE-R29.md 实际结论：..."}`（`result` 含三档文字 / 首帧 / 跨 exe pid 与读回值 / PASS 数字 / SCRIPT ERROR=0 / 未完成项）。
- 中枢 `outbox/` 有实时消费清空机制（DONE-R28B §8 已登记），写后按幂等 / 并发保护不重复写第二份回执。
