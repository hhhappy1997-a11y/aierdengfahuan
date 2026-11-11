# DONE-R29B · Rank-1（引擎架构与渲染）

- **任务单 id**：`cmd-20261111-120737-841-A1`（[ROUND=R29B]，紧急修复 v070 兑换面板深底遮挡角色回归）
- **工程根**：`F:/Game/aierdengfahuan`；Godot 工程 `F:/Game/aierdengfahuan/godot`
- **引擎**：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）
- **结论速览**：总指挥目视发现的回归已修复并真跑实证 —— ① `GraceShopLabel` 与其深底/边框整体 `visible` 严格由 `shop_open` 门控，首帧不再出现 x≈24–1100 / y≈300–470 的深蓝大矩形（改前该区近黑实心像素 171,845 / 93.9% → 改后 16,092 / 8.8%）；② 显示时深底 alpha 0.88→**0.30**（≤0.35），面板从横切角色中部移到屏幕右下 `(740,358)-(1276,568)`，与玩家/Boss 包围盒几何交集 **55,250 px → 0 px**，三档文字 6 行清晰可读；③ 「首帧 attack_light 1/27」「跨 exe 读回 6 PASS」「三档文字可读」全不回退；④ v060 `64/86/21/48/37`、v070 `6/46`、全回归 23 个 verify、三态口径件、三段门禁 `SCRIPT ERROR=0` 全达到。
- **零付费 / 零外部依赖 / 未启 GPU job / 未新建只读探针巡检脚本 / 未自行 git**（总指挥收尾）。

---

## 1. 写清单核对（只写白名单）

| 文件 | 动作 | 内容 |
|---|---|---|
| `godot/scripts/hud.gd` | 改写 | ① `_refresh_shop_hud()` 依据 `shop_open` 设 `_shop_label.visible`；② `SHOP_BG_COLOR` alpha 0.88→0.30、`SHOP_BORDER_COLOR` 0.9→0.55、新增 4 个 `SHOP_RECT_*` 布局常量；③ `_deferred_shop_readable()` 改 offset + `autowrap_mode=AUTOWRAP_WORD_SMART` + deferred 末尾二次同步 `visible`，新增 `[R29B][SHOP]` 日志行。**既有 1~8 节、兑换逻辑（`get_shop_view` / `_refresh_shop_hud` 文本 / `purchase_upgrade` / `_toggle_shop`）、四套 HUD 位置、R29 的 `call_deferred` 踩坑修复逐字未动** |
| `capture/v070b_*.png` | 新增 | 改后 450 帧录屏序列 + 4 张语义化对照帧（frame0 / medium f50 / low f200 / high f350），共 **454 张**，全部 1280×720 |
| `teamwork/Rank-1/` | 追加 | `DONE-R29B.md` + **53 份** `r29b_*.log` 真跑日志（含像素量化 `r29b_pixel_quant.log`） |
| `teamwork/command_center/ai/1/outbox/cmd-20261111-120737-841-A1.json` | 回执 | 按精确路径写入 |

**未写**：shader / `courtyard.tscn` / `presentation.gd` / 素材 PNG / `.tres` / `project.godot` / 契约 / `README.md` / 其它 Rank 目录 / 任何 verify 脚本。Movie Maker 自动生成的 `v070b_after.wav`（非白名单）已清理，`capture` 下 `v070b_*` 非 png 产物 = **0**。

---

## 2. 根因与修法（只改 hud.gd）

### 2.1 根因（改前真跑目视 + 像素实证）

R29 把 `GraceShopLabel` 迁出 `SubViewport` 到独立 `CanvasLayer(layer=45)` 后，给它加了 `StyleBoxFlat` 深底 `Color(0.04,0.06,0.12,0.88)` —— alpha **0.88 几乎不透明**。由于场景里该 Label 的 `offset=(24,300)-(1100,470)` 是屏幕绝对坐标，在铺满 1280×720 的独立层上变成一个 **1076×170 = 182,920 px 的近黑实心大矩形**；且 `_shop_label` 从未设 `visible=false`（`shop_open=false` 时 `_refresh_shop_hud()` 仍写入一行文字），故**首帧即常驻**，横切玩家（x≈400–680 / y≈320–570）与 Boss（x≈645–880 / y≈230–350）躯干。

### 2.2 修法

1. **面板默认隐藏（①）**：`_refresh_shop_hud()` 取 `get_shop_view()["open"]` → `_shop_label.visible = is_open`。深底 + 金边都是该 Label 的 `normal` stylebox，随节点一起隐藏/显示。`_ready()` 内 `shop_open=false` → 首帧隐藏；`_toggle_shop()`（E 键）→ `shop_open=true` → 显示；关闭 → 隐藏。`_deferred_shop_readable()`（R29 的 `call_deferred` 时序保护保留）在 reparent / theme 覆盖之后**再显式同步一次** `visible = shop_open`，保证 deferred 建层不改首帧隐藏态。
2. **深底 alpha ≤0.35（②）**：`SHOP_BG_COLOR` → `Color(0.04,0.06,0.12,0.30)`，边框 → `Color(0.83,0.68,0.3,0.55)`；字号、描边、阴影、圆角、内边距全部保留。
3. **移位避开角色（②）**：offset `(24,300)-(1100,470)` → `(740,358)-(1276,568)`（屏幕右下，宽 536px / 高 210px，覆盖面积 182,920→112,560 px²）。Boss 下沿 y≈350 < 358、玩家右沿 x≈680 < 740 → 两个包围盒几何交集为 0；面板 y≥358 不覆盖 赐福 HUD `x<730,y<220` / 画质面板 `x>760,y<180`；避让 波次 HUD(y≈240,x<460) / 教学 HUD(y≈520,x<700) / 底部战斗 HUD(y≈660)。
4. **保持三档可读**：面板仍在 R29 的独立 CanvasLayer（不受 `stretch_shrink` low=3 / medium=2 / high=1 影响），固定字号 **20px 不变**、文字内容逐字不动；因宽度收窄新增 `autowrap_mode = TextServer.AUTOWRAP_WORD_SMART`（G2 check-only 校验通过，运行期日志 `autowrap=3`），首行折成 2 行、共 6 行，不裁字。
5. **降级保护**：独立 `hud.tscn` 实例（`--script` 验证）祖先链无 `SubViewportContainer`，`_ensure_shop_readable()` 判空降级、不迁节点、不改节点路径与属性，`58 / 30 / 11 / 127` 等既有 PASS 不回退。

运行时日志实证（`r29b_after_capture.log:50-51`）：
```
[R29][SHOP] ... rect=(740,358)-(1276,568) ...
[R29B][SHOP] 默认隐藏 visible=false (shop_open=false) | 深底 alpha=0.30 | rect=(740,358)-(1276,568) 屏幕右下避开玩家/Boss 包围盒 | autowrap=3
```

---

## 3. 真跑方式

改前对照直接用 R29 定稿 `capture/v070_hud_after_{frame0,medium,low,high}.png`（不改写、只读取）。改后真跑一次完整 450 帧录屏（一次覆盖三段画质：f=0 medium / f=150 low / f=300 high；f=20 注入 E 打开面板、f=170 注入 1 购买成功、面板保持展开到 449）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/v070b_after.png \
  --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd \
  res://scenes/courtyard.tscn
```
`EXIT=0`、450 帧、1280×720 @30FPS、日志 `r29b_after_capture.log`、`SCRIPT ERROR=0`。像素量化用 `python + PIL/numpy` **内联计算、不落盘脚本**（`r29b_pixel_quant.log`）。

---

## 4. 前后对照（ViewImage 目视 + 像素数字）

### 4.1 ViewImage 目视

| 帧 | 改前（R29 `v070_hud_after_*`） | 改后（R29B `v070b_after_*`） |
|---|---|---|
| 首帧 frame0 | 深蓝近黑大矩形常驻，玩家/Boss 躯干整块被遮，只露一行「赐福成长 · 按 E 打开兑换」 | **大矩形消失**；蓝甲玩家与红色 Boss 完整可见；赐福金色标题框、画质面板、底部战斗 HUD「动作 attack_light 1/27」全部正常 |
| medium f50 | 大矩形盖住角色中部，底色近黑实心 | 面板在右下 `(740,358)-(1276,568)`，**半透明透出砖地纹理与金色光柱**；6 行近白文字清晰、无裁剪；不遮玩家/Boss、不压赐福 HUD / 画质面板 |
| low f200 | 文字在 SubViewport 缩放问题（R29 已修）；本轮对照重点是遮挡 | 同上，6 行文字清晰（含「兑换成功：赐福·生命上限」结果提示），三档一致 |
| high f350 | 同上 | 同上，字号/排版与 medium/low 一致（独立层不受 stretch_shrink 影响） |

### 4.2 像素量化数字（`r29b_pixel_quant.log`）

判定：`深蓝近黑实心像素 nbs = R<45 & G<55 & B<90 & B>R+10 & B>G+5 & luma<62`；`OLD=(24,300)-(1100,470)=182,920 px`；`NEW=(740,358)-(1276,568)=112,560 px`；`PLAYER=(400,320)-(690,570)=72,500 px`；`BOSS=(645,230)-(880,350)=28,200 px`。

**① 首帧无大矩形**（OLD 区，同帧号 frame0）：

| 版本 | luma_mean | luma_std | 深蓝近黑实心 px | 占比 |
|---|---:|---:|---:|---:|
| 改前 R29 | 27.86 | 24.20 | **171,845** | **93.9%** |
| **改后 R29B** | **90.83** | **33.97** | **16,092** | **8.8%** |

同帧号逐像素差(>30)：**OLD 矩形区内 177,921 px / 全屏其余区域仅 2,408 px** → 变化几乎完全集中在大矩形区，其余画面未动。

**② 打开时深底不是近黑实心块**（排除文字/金边 `L<100` 的背景像素）：

| 档位 | 改前 OLD 背景 mean / std | 改后 NEW 背景 mean / std | std 倍数 |
|---|---|---|---|
| medium f50 | 24.91 / 11.60 | 56.86 / 25.04 | 2.16× |
| low f200 | 24.07 / 11.72 | 48.70 / 19.16 | 1.63× |
| high f350 | 24.41 / 11.53 | 50.15 / 20.83 | 1.81× |

原理：alpha=0.88 时输出 ≈ `0.12×场景 + 近黑常数` → 背景几乎均匀（mean≈24、std≈11.5）；alpha=0.30 时 ≈ `0.70×场景 + 常数` → 保留砖地纹理方差（mean≈49–57、std≈19–25）。全区域口径同向：改前 OLD 近黑占比 **79.2–80.8%** → 改后 NEW **23.3–34.3%**（残留为场景本身暗像素）。

**③ 打开时面板不遮角色**：

| 档位 | 改前 PLAYER / BOSS 区内近黑 px | 改后 PLAYER / BOSS 区内近黑 px |
|---|---|---|
| medium f50 | 44,295 / 9,456 | 4,428 / 660 |
| low f200 | 40,834 / 9,621 | 8,132 / 714 |
| high f350 | 42,775 / 9,181 | 5,061 / 397 |

改后残留为**场景固有深蓝夜景 / 角色盔甲阴影像素，非面板**；决定性证据是几何交集：

| 面板 | ∩ PLAYER | ∩ BOSS | 合计 |
|---|---:|---:|---:|
| 改前 OLD | 43,500 | 11,750 | **55,250 px** |
| **改后 NEW** | **0** | **0** | **0 px** |

**④ 三档文字可读**（改后 NEW 面板区近白字像素）：medium **14,135** / low **15,086** / high **15,104** —— 三档数值近乎一致，证明文字渲染不随 `stretch_shrink` 变化，low 档无消失/无裁剪。

---

## 5. 三段门禁 + 全回归（真跑输出结论）

引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--headless --path F:/Game/aierdengfahuan/godot`，串行单进程。

### 5.1 三段门禁（12 份日志，全 EXIT=0 / SCRIPT ERROR=0 / Parse Error=0）

| 段 | 命令要点 | 结果 |
|---|---|---|
| G1 | `--headless --import` | EXIT=0 |
| G2 | `--headless --check-only --script` × **11**（hud / presentation / verify_hud_depth_v070 / tutorial_director / wave_trial_director / encounter_director / verify_tutorial_v060 / verify_wave_runtime_v040 / verify_tutorial_restart_v060 / world/save_system / rpg/world_state） | 全 EXIT=0（`TextServer.AUTOWRAP_WORD_SMART` 语法校验通过） |
| G3 | `--headless --quit-after 90 res://scenes/courtyard.tscn` | EXIT=0 |

### 5.2 v060 / v070 点名数字（全部实跑达到、不回退）

| 组 | 实测 | 组 | 实测 |
|---|---|---|---|
| **`verify_tutorial_v060`（64）** | `pass=64 fail=0 RESULT=ALL_PASS` | **`verify_tutorial_reward_v060`（86）** | `pass=86 fail=0 ALL_MATCH` |
| **`verify_tutorial_flags_v060`（21）** | selftest `15`(pid 23872) + write `3`(pid 19128) + read `3`(pid 7976) | **`verify_tutorial_restart_v060`（48）** | `pass=48 fail=0 ALL_PASS` |
| **`verify_wave_runtime_v040`（37）** | `pass=37 fail=0 ALL_MATCH`（`NODE_COUNT` 相关断言保持） | **`verify_wave_flags_v040`（23）** | `17 + 3 + 3`，三独立 pid |
| **`r19_verify_hud`（20）** | `pass=20 fail=0` | `verify_hud_binding`（11） | `pass=11 fail=0 AUTOLOAD_OK` |
| **v070 `verify_hud_depth_v070`（6）** | 跨 exe 两独立进程：write `pid=21308` → read `pid=29348`，真实主场景 + `v050_read` 标记，`SaveSystem.is_loaded()=true`、`step_index=3 / completed=true`，`SUMMARY pass=6 fail=0 RESULT=ALL_PASS` | **v070 `verify_depth_profile_v070`（46）** | `pass=46 fail=0 total=46 RESULT=PASS` |

> **口径确认**：任务单「v070 6 / 46」= 跨 exe 读回 `6 PASS`（`verify_hud_depth_v070.gd`）+ 两档景深参数 `46 PASS`（`verify_depth_profile_v070.gd`），本轮均定位到具体脚本并真跑复现。

### 5.3 全回归 23 个工程内 verify（`r29b_regress_*.log`，全 EXIT=0）

| 组 | 实测 | 组 | 实测 |
|---|---|---|---|
| `verify_wave_persist_v040` | `45 ALL_PASS` | `verify_encounter_v010/v020/v030` | `20 / 45 / 53 ALL_MATCH` |
| `verify_persistence_hud_v050` | `30 ALL_PASS` | `verify_wave_trial_v040` | `58 ALL_MATCH` |
| `verify_fx_mobile / fx_profile / quality_interaction` | `47 / 34 / 19 PASS` | `verify_grace_upgrade_v050` | `127 ALL_MATCH` |
| `verify_grace_runtime_v050` | `58 ALL_PASS` | `verify_boss_phase / poses / runtime` | `RESULT=PASS` |
| `verify_combat_runtime` | `PASS=27 FAIL=0` | `verify_frame_data / pose_names` | `ALL_MATCH / PASS` |
| `verify_save_isolation_v060` | `31 ALL_MATCH` | `verify_tutorial_v060 / restart` | `64 / 48 ALL_PASS` |

### 5.4 全量日志汇总

`teamwork/Rank-1/r29b_*.log` 共 **53 份**：`grep -l "SCRIPT ERROR|Parse Error"` 命中 **0**；`grep -l "PASS=false|fail=[1-9]|HAS_FAIL"` 命中 **0**（唯一 HIST_FAIL 见 §6.2 已如实留证并复跑翻案）。录屏 `r29b_after_capture.log` 首帧 `EVIDENCE frame=0 shop_open=false ... 动作 attack_light 1/27` —— **首帧动作帧不回退**；f=22 `shop_open=true`、f=171 `兑换成功`、f=449 `shop_open=true` 时间线完整。

---

## 6. 如实边界 / 未完成项

1. **「购买后回到隐藏」字面口径与任务 ③ 冲突，按 `visible = shop_open` 门控实现，如实登记**：本轮面板可见性**完全由 `shop_open` 决定** —— 首帧隐藏、E 打开显示、关闭（E 再按）隐藏；购买成功（`f=170`）不改 `shop_open`，面板继续显示「兑换成功」结果提示，用户再按 E 关闭即隐藏。原因：`presentation.gd`（本轮白名单外、不可改）在 f=20 打开后不再注入 E、f=170 购买成功；若购买即自动隐藏，则 low(f200) / high(f350) 两档画面将没有面板，**「三档文字可读不回退」与「打开时面板不遮角色」三档抓帧验证无法完成**，等于回退 R29 成果。且 `purchase_upgrade()` 属既有受保护逻辑，本轮不改。回归根因（深底脱离 `shop_open` 独立常驻）已根除。**这一条是口径取舍，不谎称字面 100% 满足，请总指挥裁决。**
2. **批量全回归首跑的存档中间态 FAIL（已翻案、留证）**：首次按默认顺序批量跑 23 个 verify 时，`verify_persistence_hud_v050` 的 A2「十字段齐全」读到的 `delta.json` 缺 `slot`/`quests`（8 字段），得到 `29/1 HAS_FAIL`。原因是前序 verify 经真实 `commit` 多次覆盖 `user://saves/slot_01/delta.json`（R29 DONE §6.3 已登记同一「存档为测试态」既有现象），与 hud.gd 的可见性/布局改动**无关**（A2 只检查存档顶层字段）。证据：单独真跑该件 **两次均 `30 ALL_PASS`**；先用既有真实入口归一化存档、再以「persistence 优先」顺序重跑全回归 **23 个全 EXIT=0**。失败日志原样保留为 `r29b_regress_verify_persistence_hud_v050_firstfail.log`，不隐藏、不冒充一次成功。
3. **数值为 `[PLACEHOLDER]` 待试玩校准**：`SHOP_BG_COLOR.a=0.30`、`SHOP_BORDER_COLOR.a=0.55`、`SHOP_RECT_*=(740,358,1276,568)`、`AUTOWRAP_WORD_SMART`；rationale 见 §2.2。未做人工试玩目视校准，本轮以 450 帧 CPU 录制 + ViewImage 目视 + 像素量化判断进度。
4. **存档为测试态**：本轮录屏、全回归、v070 write、三态 write 均经真实 `set_flag + commit` 多次落盘覆盖 `slot_01/delta.json`；均为真实写入、非伪造产物，后续如需干净基线由编排层归一化。
5. **三档抓帧复用既有 `presentation.gd`**（未改）；Movie Maker 的 `.wav` 已清理；`capture/v070b_*.png` 共 454 张全在白名单内。
6. 未自行 `git`（总指挥收尾）；零付费、零外部依赖、未启 GPU job；未新建只读探针 / 巡检脚本；三态口径件复用 `teamwork/Rank-3/` 既有脚本，以绝对路径 `--script` + 环境变量 `TUTORIAL_V060_PHASE` / `WAVE_V040_PHASE` 直接真跑，未复制/未改写。

---

## 7. 回执

- 精确路径：`F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/cmd-20261111-120737-841-A1.json`
- 内容：`{"task_id":"cmd-20261111-120737-841-A1","ai":1,"status":"done","result":"引用 DONE-R29B.md 实际结论：..."}`（`result` 含默认隐藏 / alpha 0.30 / 右下位置 / 首帧与打开态前后像素数字 / 64·86·21·48·37·6·46 / SCRIPT ERROR=0 / 口径边界与未完成项）。
- **写入实证（如实）**：写后读精确路径 `exists=False`，系中枢 `outbox/` 实时消费清空（DONE-R28B §8 同一时序现象），非未写。归档件 `teamwork/command_center/dispatcher/receipts/cmd-20261111-120737-841-A1.json`（**2708 字节**，12:36）读回校验：`json_valid=True`、`keys=['ai','result','status','task_id']`、`task_id=cmd-20261111-120737-841-A1` / `ai=1` / `status=done` / `result_len=1702`、以「引用 teamwork/Rank-1/DONE-R29B.md 实际结论」开头；`ai/1/status.json` 同步 `completed=48 / state=idle`。按幂等 / 并发保护**不重复写第二份回执**。
- 附带如实登记：G1 `--import` 会由引擎自动刷新 `godot/.godot/` 下的 `filesystem_cache10` / `project_metadata.cfg` / `global_script_class_cache.cfg` / `uid_cache.bin` 四处内部缓存（引擎行为，非本 AI 改动的 shader / 场景 / 素材 / 契约 / README 源文件）。
