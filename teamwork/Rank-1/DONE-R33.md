# DONE-R33.md · R33 / 实机可见性修复轮（Rank-1）

> 轮次：`R33` ｜ 派单 id：`cmd-20261112-084053-303-A1` ｜ 执行 AI：`1（Rank-1 引擎架构与渲染）`
> 真源：`teamwork/Rank-1/调度任务单-latest.json`（`task` 全文）+ 总指挥目视结论（capture/v100_final.mp4 首/中/尾三帧）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable）
> 结论：**三段门禁全 `EXIT=0`、`SCRIPT ERROR=0`、三份回归 `RESULT=ALL_MATCH`（42/24/16 PASS）、A38 保持 41 节点 / uv 2/1/1；Tab 互斥在实机真实生效（日志实证）；新玩法已进 15 秒演示序列且可见层已入树。**
> 诚实边界：**Boss 开窗 / 赐福抉择卡片为「演示驱动，非玩家真实操作可达」**，不冒充已完整接线；仍缺运行时触发链见 §6。

---

## 1. 实际交付清单（本轮唯一写入方 = Rank-1）

| 文件 | 类型 | 实际改动 |
|---|---|---|
| `godot/scripts/hud.gd` | 修改 | R33 · Tab 互斥仲裁收敛（根因修复，见 §2）：新增 `_codex_director` 引用、`_r33_arbitrate_codex_tab()`、`_sync_codex_panel_visible()`；`apply_side_panel_visibility()` 把互斥落实到真实节点 `visible`；`_sync_impact_panels()` 统一单一事实源；`_exit_tree()` 清理引用。**1~11 节逐字未动、既有 19 条断言不删不放宽。** |
| `godot/scripts/render/verify_hud_layout_v100.gd` | 修改 | 新增 **H 组 5 条运行时断言**（`Input.parse_input_event()` 注入真实 Tab 按下/松开配对 → 读**实际节点 `GraceShopLabel.visible`** 断言互斥）；`_new_hud()` 夹具挂真实兑换面板节点；`_initialize()` 追加 H 组调用。**既有 A~G 共 19 条逐字保留。** |
| `godot/test/presentation.gd` | 修改（本轮特别授权） | 新增 R33 演示节：运行时挂载独立 CanvasLayer 可见层（ProgressBar 韧性条 + 读秒/F 反馈 Label + 三选一卡片 Label）；绑定 Rank-2 真实 `StaggerService` / `BoonDraftService`；F / 数字键 2 / Tab 关闭走真实 `Input.parse_input_event()`；开窗 / 卡片由显式公开方法构造（演示驱动）；`EVIDENCE` 增读 `shop_label_visible` 留证；信号末尾显式 disconnect。 |
| `teamwork/Rank-1/DONE-R33.md` | 新增 | 本报告 |
| `teamwork/command_center/ai/1/outbox/cmd-20261112-084053-303-A1.json` | 新增 | 回执（§8 确认归档） |

### 只读未改（硬约束）
`encounter_director.gd`、`impact_feedback.gd`、`codex_director.gd`、`stagger_service.gd`、`boon_draft_service.gd`、
Rank-2/3/4 全部产出、`courtyard.tscn`、素材、数据表（`boon_draft.tres` / `stagger_rules.tres`）、`project.godot`。
`courtyard.tscn` 静态节点数 41 / uv `2/1/1` / 节点名（A38）均未破坏（GATE-3 + v090 J1/J2/J3 实证）。
零付费、零外部依赖、不启 GPU job、不自行 git、未删除 `.workbuddy`、未写只读探针/巡检脚本。
**按任务要求不重复录屏**：本轮 headless 真跑 450 帧自测（未产出录屏文件），总指挥定稿 15 秒录屏与目视回看另行。

---

## 2. 任务① · Tab 互斥在实机生效（根因 + 修法 + 实机证据）

### 2.1 根因（不是编译问题，是真实输入路径被吞键）
- R30 的 `CodexDirector` 由 `hud.gd::_ensure_codex_director()` 用 `mount.call_deferred("add_child", director)` **晚于 HUD 入树**；
- Godot `_unhandled_input` 按场景树**逆序**分发 → 后挂载的 CodexDirector 优先命中 Tab，并在
  `codex_director.gd:519` 调 `vp.set_input_as_handled()` **吞键**；
- 结果：HUD 的 `_unhandled_input` **永远收不到 Tab** → `_codex_open` 恒 `false` →
  `get_visible_side_panels()` 恒按 `shop_open` 返回 `shop` → 兑换 / 赐福成长面板常驻；
- 而 R32 的 19 条包围盒断言只读「布局 / 逻辑态」，B 组直接 `set_codex_open(true/false)` **绕过真实输入路径**，
  故全 PASS 却与总指挥目视的实机不符。

### 2.2 修法（全部落在 `hud.gd`，不写 `codex_director.gd` / 场景）
1. `_ensure_codex_director()` 保存 `_codex_director` 引用；`call_deferred("_r33_arbitrate_codex_tab")`
   排在 `add_child` 之后（director `_ready()` 里 `set_process_unhandled_input(true)` 已执行完才关，避免被覆盖）；
2. `_r33_arbitrate_codex_tab()`：`_codex_director.set_process_unhandled_input(false)` → **HUD 成为唯一 Tab 仲裁者**，
   再 `apply_side_panel_visibility()` 同步一次；只改运行时节点属性，不改其文件、不写场景（静态节点数 41 保持）；
3. `apply_side_panel_visibility()` 新增 `_sync_codex_panel_visible()`：经公开 `is_panel_open()` / `toggle_panel()`
   鸭子类型适配，把 `is_side_panel_visible("codex")` 落实到 **CodexDirector 真实 CanvasLayer.visible**；
   `_shop_label.visible = is_side_panel_visible("shop")` 保持不变（真实兑换节点门控）；
4. `_sync_impact_panels()` 改用 `is_side_panel_visible(...)` 单一事实源，反馈层避让与面板真实 visible 一致；
5. `_exit_tree()` 清理 `_codex_director` 引用；`_unbind_stagger_signals()` 释放路径逐字保留。

### 2.3 实机证据（headless 真跑 450 帧，非推断）
```
[R33][HUD] Tab 互斥仲裁收敛：CodexDirector 自身 Tab 监听关闭，HUD._unhandled_input 统一处理 Tab 并经 toggle_panel() 同步真实图鉴面板 visible
[R28][EVIDENCE] frame=22  ... codex_panel_open=false | shop_label_visible=true
[R28][EVIDENCE] frame=225 ... codex_panel_open=true  | shop_label_visible=false   ← Tab(f=210) 图鉴打开 → 兑换确实隐藏
[R33][INPUT] frame=240 再注入真实按键 Tab -> 关闭图鉴；HUD 互斥恢复兑换面板 visible（R33 修复实证）
[R28][EVIDENCE] frame=449 ... codex_panel_open=false | shop_label_visible=true    ← 关闭 → 恢复
```
`shop_label_visible` 读的是 **HUD `_shop_label` 真实节点的 `visible`**（不是逻辑态、不是包围盒）。

### 2.4 H 组新增运行时断言（`Input.parse_input_event` 注入真实 Tab）
`--script` 模式无 GUI 输入分发，口径与 `verify_stagger_runtime_v100.gd` E 组一致：
`Input.parse_input_event(press/release)` 注入真实 Tab 按下/松开配对，再把同一事件对象喂
`process_key_event()`（与 `_unhandled_input` 完全相同的 R32 键处理路径），**读实际节点 `visible` 断言互斥**。
H1~H5 全 PASS，既有 19 条逐字保留 → `pass=24 fail=0 RESULT=ALL_MATCH`。

---

## 3. 任务② · 新玩法进 15 秒演示序列

### 3.1 真实缺口（不只是「没触发」，是「没有可见节点」）
R32 的 `get_stagger_hud_view()` / `get_boon_draft_view()` 只返回 **Dictionary 快照**，
HUD 侧**没有任何真实可见节点**；演示序列也没有触发链。故 15 秒录屏里完全看不到新玩法。

### 3.2 本轮做法
- `presentation.gd` 运行时挂载独立 `CanvasLayer(layer=48)`：真实 `ProgressBar` 韧性条 +
  读秒/F 反馈 Label + 三选一卡片 Label；位置 `(900,190)-(1276,352)` 右上空白区，
  与 quality(y<180) / shop(y>358) / Boss+中央角色(x<880) / codex(x<380) / 底部条(y>660) 均无交集；
  首帧隐藏、按段互斥显示（R29B 首帧大矩形回归不再出现）。
- **可见层文本/数值全部读 HUD 公开快照**（`get_stagger_hud_view()` / `get_boon_draft_view()`），
  不写既有 HUD 的 `Label.text`、不调 `debug_*`、不伪造数值；不写 `courtyard.tscn`。
- 绑定 Rank-2 真实 `StaggerService` / `BoonDraftService`（`CACHE_MODE_IGNORE` 回读），
  订阅 `execution_performed` / `boon_draft_selected` 真实信号回读。
- 帧点（[PLACEHOLDER] 待试玩校准）：
  `f=96` 开窗 → `f=96~145` 读秒推进 → `f=126` 真实 F 处决 → `f=240` 再 Tab 关图鉴 →
  `f=330` 三选一卡片 → `f=352` 真实数字键 2 选择 → `f=399` 结果反馈。
- 信号 connect 在 450 帧末尾 `_r33_release_signals()` 显式 disconnect（释放路径兜底）。

### 3.3 真跑原文（关键行，450 帧全量日志从略）
```
[R33][OVERLAY] 演示可见层组装完成（CanvasLayer layer=48，rect=(900,190)-(1276,352) 避开既有 HUD/角色）→ deferred 入 root
[R33][SVC] stagger=true boon=true | 演示驱动：开窗/卡片由显式调用 Rank-2 公开方法构造，见 DONE-R33.md
[R33][OVERLAY] frame=96 可见层入树回读 is_inside_tree=true（CanvasLayer 渲染前提）
[R33][STAGGER] frame=96 apply_hit(100.0) → opened_now=true window=true remaining=3.0（演示驱动：非玩家真实命中链）
[R33][STAGGER][HUD] frame=96  poise=[Boss 韧性 0%] window=[处决窗口 3.0s · 按 F] exec=[]（读 HUD 真实快照渲染可见层）
[R33][INPUT] frame=126 注入真实按键 F(KEY_F=70) -> HUD.request_execution() → 真实 StaggerService.try_execute()
[R33][STAGGER][HUD] frame=126 poise=[Boss 韧性 0%] window=[处决窗口 2.0s · 按 F] exec=[]
[R33][EXEC] execution_performed 真实信号回读 bonus=50 count=1
[R33][STAGGER][HUD] frame=145 poise=[Boss 韧性 100%] window=[] exec=[处决成功！额外点数 +50（F 键）]
[R33][INPUT] frame=240 再注入真实按键 Tab -> 关闭图鉴；HUD 互斥恢复兑换面板 visible（R33 修复实证）
[R33][BOON] frame=330 on_wave_cleared() → 三选一卡片打开（演示驱动：非玩家真实清波可达）
[R33][BOON][HUD] frame=330 open=true choices=3 select=[]（读 HUD 真实快照渲染可见层）
[R33][INPUT] frame=352 注入真实按键 2(KEY_2=50) -> HUD._select_boon_draft(1) → 真实 BoonDraftService.select(1)
[R33][BOON] boon_draft_selected 真实信号回读 index=1 id=boon_02_poise_edge count=1
[R33][BOON][HUD] frame=399 open=false choices=3 select=[已选择第 2 项（boon_02_poise_edge）｜数字键确认]
[R33][RELEASE] execution_performed / boon_draft_selected 信号连接已释放（_exit_tree 兜底口径）
==== [R22 presentation] 时间线完成 frame=450（--quit-after 450 负责退出）====
```

> 诚实说明：本轮为 **headless 真跑**（无渲染窗口、未产出录屏文件）。可见层 `is_inside_tree=true`、
> 节点 `visible` 按段切换、文本来自 HUD 真实快照，均已在日志中回读证明；
> **像素级目视由总指挥重跑 15 秒定稿录屏完成**，本轮不冒充已目视确认。

---

## 4. 任务③ · 门禁与回归（真跑输出原文）

统一命令前缀：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`

### GATE-1 `--headless --import`
```
[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[  16% ] first_scan_filesystem | 正在加载全局类名……
[ DONE ] first_scan_filesystem
[   0% ] update_scripts_classes | Started 正在注册全局类…… (3 steps)
[ DONE ] update_scripts_classes
[ DONE ] loading_editor_layout
GATE-1 EXIT=0
```

### GATE-2a `--check-only --script`（5 件，语法门禁）
```
check-only res://scripts/hud.gd                                  EXIT=0 | err_lines=0
check-only res://scripts/render/verify_hud_layout_v100.gd       EXIT=0 | err_lines=0
check-only res://test/presentation.gd                           EXIT=0 | err_lines=0
check-only res://scripts/render/verify_impact_feedback_v090.gd  EXIT=0 | err_lines=0
check-only res://test/verify_stagger_runtime_v100.gd            EXIT=0 | err_lines=0
```

### GATE-2b `--headless --script <verify>`（复跑 3 份）
```
--- RUN res://scripts/render/verify_impact_feedback_v090.gd EXIT=0 ---
[V090] J1 courtyard.tscn 静态 [node] 行数 == 41（A38 节点数保持） PASS=true | count=41 expected=41
[V090] J2 uv 2/1/1 原样：Vector3(2,2,1) ×1 + Vector3(1,1,1) ×2 PASS=true | uv_2x=1 uv_1x=2
[V090] J3 courtyard.tscn 文本无 ImpactFeedbackLayer / impact_feedback.gd PASS=true
[V090] SUMMARY pass=42 fail=0 total=42 ok=true
[V090] RESULT=ALL_MATCH

--- RUN res://scripts/render/verify_hud_layout_v100.gd EXIT=0 ---
[V100HUD] H1 夹具含真实兑换面板节点 GraceShopLabel 且 HUD._shop_label 已绑定 PASS=true | panel=true bound=true
[V100HUD] H2 初始（图鉴关闭 / shop_open=true）：真实兑换面板节点 visible=true PASS=true | visible=true side=["shop"]
[V100HUD] H3 真实 Tab 按下/松开后：图鉴打开、右侧仅 codex 可见、兑换面板真实节点 visible=false PASS=true | consumed=true codex_open=true shop_visible=false side=["codex"]
[V100HUD] H4 真实 Tab 再按下/松开后：图鉴关闭、兑换面板真实节点 visible=true PASS=true | consumed=true codex_open=false shop_visible=true side=["shop"]
[V100HUD] H5 赐福抉择卡片打开时真实兑换节点仍隐藏、右侧仅 boon_draft 可见 PASS=true | shop_visible=false side=["boon_draft"]
[V100HUD] SUMMARY pass=24 fail=0 total=24 ok=true
[V100HUD] RESULT=ALL_MATCH

--- RUN res://test/verify_stagger_runtime_v100.gd EXIT=0 ---
[V100STG] H1 真实 StaggerService 绑定成功 PASS=true | service=true window=false poise=1.0
[V100STG] H2 真实 apply_hit(100) 开窗 PASS=true | window=true remaining=3.0 poise=0.0 bonus=50
[V100STG] H3 窗口内 F 触发真实 try_execute PASS=true | consumed=true signal=1 bonus=50 window=false
[V100STG] H4 真实服务 tick(999) 超时 → closed(timeout) → HUD 关窗 PASS=true | reopened=true after_tick_window=false
[V100STG] SUMMARY pass=16 fail=0 total=16 ok=true
[V100STG] RESULT=ALL_MATCH
```

### GATE-3 `--headless --quit`（主场景实证）
```
[SaveSystem] 自动读回完成 | dungeon.wave_trial.best_wave=3 | grace.trial.points=450 | dungeon.wave_trial.completed=true
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
[WaveTrial] 持久化基线读回：dungeon.wave_trial.best_wave=3 / dungeon.wave_trial.completed=true / grace.trial.points=450
[WaveTrial] 增益运行时接线：checked=3 applied=1 degraded=0 reasons=[]
[Tutorial] 存档已完成（grace.tutorial.completed=true）→ 跳过教学，波次自动开始（按 T 可强制重开）
GATE-3 EXIT=0
```

### 演示序列真跑（450 帧，不录屏）
`--fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn` → `EXIT=0`

### 统一统计（G3 grep）
```
########## SUMMARY ##########
SCRIPT ERROR TOTAL = 0      （全工程 grep SCRIPT ERROR=0 期望）
Parse Error / ERROR: 行数 = 0
GATE-1 EXIT=0 / 5×check-only EXIT=0 / 3×verify EXIT=0 / GATE-3 EXIT=0 / PRES 450f EXIT=0
A38: node_count=41 PASS | uv 2/1/1 PASS
PASS 合计 = 42 + 24 + 16 = 82 PASS / 0 FAIL，三份 RESULT=ALL_MATCH
```

> 如实登记（不冒充全绿、不谎报）：`--script / --headless` 工具模式尾部仍有既有 autoload
> `WARNING`（`[SaveSystem] --script 工具模式…跳过自动读回` / `[ChunkManager] 未找到 ChunkRoot` /
> `2 ObjectDB instances were leaked at exit`）。这些**非 `SCRIPT ERROR`、非本轮引入、不影响断言与门禁**
> （各段 `EXIT=0`）。本轮未改这些文件（越界），如实登记。

---

## 5. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 任务①：定位并修复真实 Tab 输入路径吞键根因，HUD 成为唯一 Tab 仲裁者，互斥落实到真实节点 `visible`；实机日志 `f=225 shop_label_visible=false` / `f=449 =true` 双向实证。② H 组 5 条运行时断言（`Input.parse_input_event` 真实 Tab 注入 + 实际节点 `visible`）全 PASS，既有 19 条不删不放宽，`pass=24 RESULT=ALL_MATCH`。③ 任务②：Boss 韧性条 / 处决窗口读秒 / F 处决反馈（bonus=50）、赐福抉择三选一（choices=3）/ 数字键 2 选择（boon_02_poise_edge）全部进入 450 帧演示序列，可见层 `is_inside_tree=true`、文本来自 HUD 真实快照。④ 任务③：三段门禁全 `EXIT=0`、`SCRIPT ERROR=0`、三份回归 `42/24/16 PASS` 全 `ALL_MATCH`、A38 `41 / uv 2/1/1` 保持。 |
| **失败** | 无 |
| **需用户确认** | ① **总指挥亲自重跑 15 秒定稿录屏并目视回看**（本轮按要求未重复录屏，headless 真跑无像素级目视）。② 全部 `[PLACEHOLDER]` 数值（韧性 100/3.0/50/25、boon 三候选、演示帧点 96/126/146/240/330/352/400）待试玩校准。③ **演示驱动部分不冒充已完整接线**（见 §6/§7）。④ R33 采用「HUD 单一仲裁、运行时关闭 CodexDirector 自身 Tab 监听」的接口归属，请总指挥裁决（见 §7-3）。⑤ 既有 autoload 3 条 WARNING 是否纳入后续清理。 |

---

## 6. 未完成项 / 仍缺的运行时触发链清单（交总指挥排期）

> 以下均为**产品级运行时接线**，本轮授权边界内未落地；演示序列里用「显式调用 Rank-2 公开方法 /
> 演示可见层」替代，**如实标注、不冒充已完整接线**。

1. **玩家命中 → `StaggerService.apply_hit(poise_damage)`**：`encounter_director.gd` 目前只在
   `_try_player_hit()` emit `player_hit_landed(damage:int)`（R31B/A39 给打击反馈层用），**未订阅到
   StaggerService**。演示序列无真实命中削韧链 → 开窗由显式 `apply_hit(100.0)` 构造。
2. **每帧 `StaggerService.tick(delta)`**：`DONE-R32.md §3.3` 明确「必须每帧调用，否则窗口不会超时」，
   导演层 / 集成层未接 `_process`；演示里由 `presentation.gd` 逐帧显式调用。
3. **清波 → `HUD.on_wave_cleared()` → `BoonDraftService`**：`WaveTrialDirector` 的 `wave_cleared`
   未接到 HUD 的 `on_wave_cleared()`；演示序列无真实清波事件 → 卡片由显式 `on_wave_cleared()` 构造。
4. **`BoonDraftService.apply()` / `settle()` 的运行时消费方**：`hp_restore` / `poise_damage_bonus` /
   `cost_key`（`hp_scale` / `telegraph_scale` 作用于下一波）未接导演层（`DONE-R32.md §3.4`、§8 P1）；
   演示只走到 `select(1)`。
5. **处决额外点数 / boon 点数落盘**：按 I-1 归 Rank-3（`grace.trial.points` 只增 + `commit(...)`），
   reason 字符串口径未登记；演示里 bonus=50 仅由 `execution_performed` 信号回读显示，**未落盘**。
6. **生产 HUD 缺真实可见节点**：R32 的韧性条 / 处决读秒 / 三选一卡片只有 `get_*_view()` 字典快照，
   **没有任何产品 CanvasLayer / Label / ProgressBar**；本轮由 `presentation.gd` 运行时挂载**演示专用可见层**
   （读 HUD 快照渲染），不是产品 HUD 接线。
7. **F 处决 / 数字键选择的「完整玩家可达」**：输入路径本身真实（`Input.parse_input_event` →
   HUD `_unhandled_input` → 真实 service），但依赖上述演示驱动的开窗 / 卡片状态，游戏内尚未与真实
   战斗状态（削韧 / 清波）联动。

---

## 7. 「演示驱动」与「玩家真实操作可达」的明确区分（不冒充）

| 机制 | 本轮演示中的驱动方式 | 玩家真实操作可达？ |
|---|---|---|
| Tab 图鉴开 / 关 | 真实 `Input.parse_input_event` 注入 Tab（f=210 / f=240）→ HUD `_unhandled_input` → `_toggle_codex_panel()` → CodexDirector 真实面板 `visible` | **是**（真实输入路径；R33 修复后 HUD 为唯一仲裁者，互斥在实机生效） |
| Boss 韧性条 / 处决窗口读秒 | 显式 `StaggerService.apply_hit(100.0)` 开窗 + 每帧 `tick` / `poll_stagger_service` 推进；可见层读 `get_stagger_hud_view()` 渲染 | **否 —— 演示驱动**（无真实玩家命中削韧链，见 §6-1/2） |
| F 键处决反馈 | 真实 `Input.parse_input_event` 注入 F（f=126）→ HUD `request_execution()` → 真实 `StaggerService.try_execute()` → `execution_performed(bonus=50)` | **输入路径真实**，但依赖上一行演示驱动的开窗状态；整体不算完整玩家可达 |
| 赐福抉择三选一卡片 | 显式 `HUD.on_wave_cleared()` 构造（f=330），候选读真实 BoonDraftService；可见层读 `get_boon_draft_view()` 渲染 | **否 —— 演示驱动**（无真实清波事件，见 §6-3） |
| 数字键选择 | 真实 `Input.parse_input_event` 注入 2（f=352）→ HUD `_select_boon_draft(1)` → 真实 `BoonDraftService.select(1)` → `boon_draft_selected` | **输入路径真实**，但依赖上一行演示驱动的卡片状态；整体不算完整玩家可达 |
| 可见层（ProgressBar / Label） | `presentation.gd` 运行时挂载 CanvasLayer(layer=48)，**不写 courtyard.tscn** | **演示专用**，非产品 HUD 接线（见 §6-6） |

> 结论：**只有「Tab 图鉴开关」是完整真实输入路径且在实机生效**；F / 数字键的输入链路真实但依赖
> 演示状态；**开窗与卡片本身是演示驱动，非玩家真实操作可达**。本轮交付的是「新玩法能在 15 秒画面里
> 被看见」，不是「新玩法已完整接线可玩」，两者不混同。

---

## 8. 待总指挥裁决项（只登记、不擅改）

1. **§6 六条运行时触发链的排期与归属**（Rank-1 导演层 / Rank-2 / Rank-3）：尤其
   `player_hit_landed → apply_hit`、`_process → tick`、`wave_cleared → on_wave_cleared` 三条主线。
2. **产品 HUD 是否补真实可见节点**：本轮为演示层；若需产品化，需另派单改 `hud.gd` 渲染层
   （本轮为控制改动面未做，避免与「演示驱动」标注矛盾）。
3. **Tab 仲裁接口归属**：R33 采用「HUD 单一仲裁 + 运行时关闭 CodexDirector 自身 `_unhandled_input`」。
   若总指挥倾向保留 CodexDirector 自监听，建议改为在 `codex_director.gd` 增加
   `panel_toggled(open: bool)` 信号由 HUD 订阅 —— 需改 R30 产出，**超出本轮目录所有权**，故只列裁决。
4. **处决 / boon 点数落盘点与 reason**（Rank-3 I-1 口径）。
5. **`[PLACEHOLDER]` 数值与演示帧点校准**（调参只改表 / 帧点常量，同步本 DONE 数值表）。
6. **既有 autoload 3 条 WARNING** 是否纳入后续清理（非本轮引入、非 SCRIPT ERROR）。
7. **总指挥定稿录屏目视**：本轮 headless 真跑已证明逻辑 / 节点 / 日志，像素级目视由总指挥完成。

---

## 9. 硬约束遵守声明

- 唯一写入方 = Rank-1：仅 `hud.gd`、`verify_hud_layout_v100.gd`、`presentation.gd`、`teamwork/Rank-1/`、回执；
  其余文件（含 `courtyard.tscn`、`encounter_director.gd`、`impact_feedback.gd`、Rank-2/3/4 全部产出、
  素材、数据表）**只读未改**。
- `courtyard.tscn` 静态节点数 `41` / uv `2/1/1` / 节点名（A38）未破坏（GATE-3 + v090 J1/J2/J3 实证）。
- Godot4 `--script` 纪律：用 `Engine.get_main_loop() as SceneTree` 取 root、不用 `get_tree()` / `/root/...`
  绝对路径、资源回读 `CACHE_MODE_IGNORE`、信号 connect 有释放路径（`_exit_tree` / `_r33_release_signals` 兜底
  disconnect）；未引入 `cosf()/sinf()`（R31 踩坑），用 `cos()/sin()` 口径的文件未改。
- 既有 19 条断言逐字保留、不删不放宽；1~11 节 hud.gd 逻辑逐字未动；三份回归全 `ALL_MATCH`。
- 零付费、零外部依赖、不启 GPU job；不伪造产物、不谎报成功、不自行 git（总指挥收尾）；未删除 `.workbuddy`。
- 默认不刺探：未扫目录做进度巡检、未写只读探针/巡检脚本；仅按任务单要求确认回执目录与中枢归档结构；
  真跑日志落在系统临时目录（`/tmp`），未写入工程内。

---

## 10. 回执与中枢归档

- 回执路径（**`teamwork/command_center/`，非工程根**）：
  `teamwork/command_center/ai/1/outbox/cmd-20261112-084053-303-A1.json`
- 四字段：`{"task_id":"cmd-20261112-084053-303-A1","ai":1,"status":"done","result":"..."}`，
  `result` 引用本报告实际结论。
### 回执写后确认（中枢归档 · 实测，非推断）

```
[2026-11-12 08:59:56] ← 1 号 AI 回执 <cmd-20261112-084053-303-A1> 完成：见 teamwork/Rank-1/DONE-R33.md 实际结论…
```

- `ai/1/outbox/` 按中枢流程归档后**已清空**（回执被移入 `dispatcher/receipts/`），
  与 `DONE-R32.md §10` 既有口径一致，属中枢正常处理，不重放、不伪造；
- 归档副本 `teamwork/command_center/dispatcher/receipts/cmd-20261112-084053-303-A1.json`（1959 B）：
  `VALID_JSON=True`、`keys=['ai','result','status','task_id']`、`task_id` 正确、`ai=1`、
  `status=done`、`result_len=1128`；
- `dispatcher/ledger.jsonl` 新增 1 条：`id=cmd-20261112-084053-303-A1`、`status=done`、
  `finished_at=2026-11-12 08:59:56`；
- `ai/1/status.json`：`state=idle` / `current_task=""` / `completed=59` /
  `last_seen=2026-11-12 08:59:56`。
