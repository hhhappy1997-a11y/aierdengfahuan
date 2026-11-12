# DONE-R32 · Rank-1 引擎架构与渲染（R32 / v0.10.0「赐福抉择 · 韧性处决」）

- 派单 id：`cmd-20261112-074023-388-A1`（总指挥，经 `AierdengfahuanCommander.exe` GUI 下达）
- 轮次：`[ROUND=R32]` / v0.10.0
- 工位：Rank-1；`godot/scripts/combat/encounter_director.gd` 本轮唯一写入方（A44 / 任务单【目录所有权·R32 冻结】）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe` → `Godot Engine v4.7.2.stable.official.ed1daf0bf`
- 工程：`F:/Game/aierdengfahuan/godot`（`res://`）
- **总结论**：四块任务全部完成；7 份验证脚本全 PASS；三段门禁 GATE1/2/3 EXIT=0；**全工程 G3 `SCRIPT ERROR=0`**；A38 节点数 41 / uv `2/1/1` / 节点名保持不变。

---

## 1. 交付清单（实际文件）

| # | 文件 | 动作 | 说明 |
|---|---|---|---|
| 1 | `godot/scripts/combat/encounter_director.gd` | 改（最小） | R31B / A39：`signal player_hit_landed(damage:int)` 声明上轮已部分写入，本轮**只在 `_try_player_hit()` 玩家成功命中处补 1 行 emit**（`player_hit_landed.emit(int(damage))`）；未改既有数值 / 判定分支 / 帧数据 / 输出格式 / 其它信号 / BossController `move_landed` 订阅链 |
| 2 | `godot/scripts/render/impact_feedback.gd` | 改 | 新增 `SIG_PLAYER_HIT_LANDED` 常量 + `bind_director()` 按实订阅该信号（`get_signal_connection_list` 去重）+ `_exit_tree` 释放路径 → 命中自动 `request_impact()`（暖金闪光 / 微震 / hitstop 真实游玩触发） |
| 3 | `godot/scripts/render/verify_impact_feedback_v090.gd` | 改（扩展） | **保留既有 35 条断言不删不放宽**，新增 L 组 7 条 → 共 42 条全 PASS |
| 4 | `godot/scripts/hud.gd` | 改（追加式） | 新增 2 信号 + §11~§15：分区锚点布局 / Tab 互斥状态机 / 机制 B 韧性处决 / 机制 A 赐福抉择 / 输入状态隔离；既有 1~10 节逻辑与 4 信号逐字未动（仅 `_ready` 追加 1 行、`_unhandled_input` 开头插入 1 个隔离入口、`_refresh_shop_hud` visible 叠加互斥，默认态与 `shop_open` 等价，既有回归不回退） |
| 5 | `godot/scripts/render/verify_hud_layout_v100.gd` | 新写 | 19 条断言全 PASS（含真实 BoonDraftService 联调 G 组），输出 `RESULT=ALL_MATCH` |
| 6 | `godot/test/verify_stagger_runtime_v100.gd` | 新写 | 16 条断言全 PASS（含真实 StaggerService 联调 H 组），输出 `RESULT=ALL_MATCH` |
| 7 | `teamwork/Rank-1/DONE-R32.md` | 新写 | 本文档 |
| 8 | `teamwork/Rank-1/DONE-R31B.md` | 新写 | R31B 遗留补齐结论 |
| 9 | `teamwork/command_center/ai/1/outbox/cmd-20261112-074023-388-A1.json` | 新写 | R32 回执 |
| 10 | `teamwork/command_center/ai/1/outbox/cmd-20261111-141611-495-A1.json` | 新写 | R31B 补回执 |

**只读未改（硬约束）**：`godot/scenes/courtyard.tscn`（节点数 41 / uv `2/1/1` / 节点名）、`godot/test/presentation.gd`、素材 / 数据表 / 其它 Rank 文件、`00-协作契约.md`。零付费、零外部依赖、未启 GPU job、未自行 git（总指挥收尾）。

> **中枢归档确认（写后实测，不伪造）**：两份回执写入 `teamwork/command_center/ai/1/outbox/` 后，调度中枢已异步消费并归档到 `teamwork/command_center/dispatcher/receipts/`（08:01，文件 1202B + 146B，JSON 回读有效、内容与写入一致，outbox 已清空）。归档路径为 `teamwork/command_center/`，非工程根 `command_center/`。

---

## 2. 真跑输出原文

### 2.1 三段门禁（GATE 1/2/3）

```
===== GATE 1/3 : --headless --import =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[ DONE ] first_scan_filesystem
[ DONE ] update_scripts_classes
[ DONE ] loading_editor_layout
GATE1_EXIT=0
===== GATE 2/3 : --check-only --script (本轮 6 个改动/新增脚本) =====
CHECK_ONLY[res://scripts/hud.gd]_EXIT=0
CHECK_ONLY[res://scripts/render/impact_feedback.gd]_EXIT=0
CHECK_ONLY[res://scripts/combat/encounter_director.gd]_EXIT=0
CHECK_ONLY[res://scripts/render/verify_impact_feedback_v090.gd]_EXIT=0
CHECK_ONLY[res://scripts/render/verify_hud_layout_v100.gd]_EXIT=0
CHECK_ONLY[res://test/verify_stagger_runtime_v100.gd]_EXIT=0
===== GATE 3/3 : --headless --quit (全工程主场景 courtyard.tscn) =====
[SaveSystem] 自动读回完成 | dungeon.wave_trial.best_wave=3 | grace.trial.points=450 | dungeon.wave_trial.completed=true
[R30][HUD] 运行时挂载 CodexDirector → Courtyard（独立 CanvasLayer 由导演自建，不写 courtyard.tscn）
[R31][HUD] 运行时挂载 ImpactFeedbackLayer → Courtyard（CanvasLayer，不写 courtyard.tscn；按实接入既有战斗信号 / 画质降级 / 面板避让）
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
[WaveTrial] 增益运行时接线：checked=3 applied=1 degraded=0 reasons=[]
[R29B][SHOP] 默认隐藏 visible=false (shop_open=false) | 深底 alpha=0.30 | rect=(740,358)-(1276,568) 屏幕右下避开玩家/Boss 包围盒
[R30][CODEX][PANEL] 独立 CanvasLayer(layer=46) 建层 | rect=(24,272)-(380,508) alpha=0.30 | 默认隐藏 | 不写 courtyard.tscn
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
GATE3_EXIT=0
===== G3 : 全工程 grep SCRIPT ERROR =====
SCRIPT ERROR=0
```

> 说明：`WARNING: 2 ObjectDB instances were leaked at exit` 是 `--headless --quit` 工具模式的既有退出告警，非 `SCRIPT ERROR`；全工程 G3 统计口径为 `SCRIPT ERROR`，结果为 0。

### 2.2 验证脚本（逐项汇总 + 联调组逐条原文）

```
[V090] L1 真实导演层声明 player_hit_landed(damage:int) 且 _try_player_hit 内 emit PASS=true | script_signals=["encounter_finished", "grace_rested", "player_hit_landed"] emit_in_source=true
[V090] L4 真实导演层 emit 一次命中后闪光 > 0（暖金闪光/微震/hitstop 自动触发） PASS=true | flash=0.4200 impact=1 shake=6.0 hitstop=2
[V090] L5 连续 5 次命中：flash/shake/hitstop 恒在 [0,上限]、无 NaN、不叠加异常 PASS=true | impact=6 peak_cap=0.4200 shake_cap=6.00 hitstop_cap=4
[V090] L7 降级下真实命中仍闪光>0、shake/hitstop=0、HUD 避让区像素仍 0 PASS=true | flash=0.4200 shake=0.0 hitstop=0 max_avoid_pixel=0.0000
[V090] SUMMARY pass=42 fail=0 total=42 ok=true
[V090] RESULT=ALL_MATCH

[V100HUD] A2 任意两处文字/面板包围盒交集面积恒 == 0（三处重叠已消除） PASS=true | worst_overlap=0.0000 px²
[V100HUD] B3 Tab 图鉴打开 → 隐藏常驻兑换面板，仅 codex 可见（消除叠压） PASS=true | visible=["codex"] codex_open=true
[V100HUD] B4 Tab 图鉴关闭 → 按 shop_open 原态恢复兑换面板 PASS=true | visible=["shop"]
[V100HUD] C1 1280x720 基准 + 960x540/640x360/480x270 三档降级：文字不出界且仍不重叠 PASS=true
[V100HUD] D2 赐福抉择卡片矩形与中央角色保护区不重叠 PASS=true | overlaps=false
[V100HUD] E2 抉择数字键未误触既有兑换（grace_purchase_events 无新增） PASS=true | before=0 after=0
[V100HUD] G 组：Rank-2 真实服务已落盘 → 绑定真实 BoonDraftService 实例做联调
[V100HUD] G1 真实 BoonDraftService 绑定 + 清波钩子：卡片打开且读到 3 个真实候选 PASS=true | open=true service=true choices=3
[V100HUD] G2 数字键 2 → 真实 boon_draft_service.select(1) 成功、卡片关闭、emit 信号 PASS=true | consumed=true selected=1 select_ok=true reason=ok signal=1
[V100HUD] SUMMARY pass=19 fail=0 total=19 ok=true
[V100HUD] RESULT=ALL_MATCH

[V100STG] B1 处决窗口超时自动关闭：window_open=false / 读秒=0 PASS=true
[V100STG] C1 窗口内按 F 触发处决：execution_performed emit / execution_count=1 / F 被消费 PASS=true
[V100STG] D1 同一窗口内重复 F / 重复 request_execution 均被拒绝（计数不变） PASS=true | repeat_reason=already_executed
[V100STG] H 组：Rank-2 真实服务已落盘 → 绑定真实 StaggerService 实例做联调
[V100STG] H1 真实 StaggerService 绑定成功（service_available=true / 初始未开窗 / 满韧性） PASS=true | service=true window=false poise=1.0
[V100STG] H2 真实 apply_hit(100) 开窗：HUD window_open=true / 读秒>0 / 韧性 0% / bonus=50 PASS=true | window=true remaining=3.0 poise=0.0 bonus=50
[V100STG] H3 窗口内 F 触发真实 try_execute：execution_performed(bonus=50) / 真实服务关窗 PASS=true | consumed=true signal=1 bonus=50 window=false
[V100STG] H4 真实服务 tick(999) 超时 → closed(timeout) → HUD 关窗 PASS=true | reopened=true after_tick_window=false
[V100STG] SUMMARY pass=16 fail=0 total=16 ok=true
[V100STG] RESULT=ALL_MATCH
```

> 既有回归：`verify_hud_binding.gd` → `SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true`（既有 11 条不回退）。

### 2.3 全工程 G3 综合（6 个验证脚本只读重跑，统一统计）

```
[res://scripts/render/verify_impact_feedback_v090.gd] EXIT=0 SCRIPT_ERROR=0 RESULT=ALL_MATCH | SUMMARY pass=42 fail=0 total=42 ok=true
[res://scripts/render/verify_hud_layout_v100.gd]      EXIT=0 SCRIPT_ERROR=0 RESULT=ALL_MATCH | SUMMARY pass=19 fail=0 total=19 ok=true
[res://test/verify_stagger_runtime_v100.gd]           EXIT=0 SCRIPT_ERROR=0 RESULT=ALL_MATCH | SUMMARY pass=16 fail=0 total=16 ok=true
[res://scripts/verify_hud_binding.gd]                  EXIT=0 SCRIPT_ERROR=0                | SUMMARY mode=AUTOLOAD_OK pass=11 fail=0 ok=true
[res://scripts/combat/verify_stagger_v100.gd]         EXIT=0 SCRIPT_ERROR=0 RESULT=ALL_MATCH | SUMMARY pass=62 fail=0   （Rank-2 交付件，只读运行）
[res://scripts/combat/verify_boon_draft_v100.gd]      EXIT=0 SCRIPT_ERROR=0 RESULT=ALL_MATCH | SUMMARY pass=97 fail=0   （Rank-2 交付件，只读运行）
===== 全工程 G3 SCRIPT ERROR=0 =====
```

---

## 3. 验收三态

| 状态 | 项 |
|---|---|
| ✅ **通过** | ① R31B 遗留补齐（`verify_impact_feedback_v090` 42/0 ALL_MATCH，既有 35 条不删不放宽）；② HUD 分区避让：三处文字/面板重叠消除（两两包围盒交集 0）、Tab 互斥状态机、1280x720 + 960x540/640x360/480x270 四档文字不出界、不遮中央角色（19/0 ALL_MATCH）；③ 机制 B 韧性处决：窗口开启 / 超时关闭 / F 触发 / 重复触发拒绝 + **真实 StaggerService 联调**（16/0 ALL_MATCH）；④ 机制 A 赐福抉择：三选一数字键与兑换状态隔离 + 卡片/图鉴/兑换互斥 + **真实 BoonDraftService.select 联调**；⑤ 三段门禁 GATE1/2/3 EXIT=0、全工程 G3 `SCRIPT ERROR=0`；⑥ A38 节点数 41 / uv `2/1/1` 不变，既有 hud 绑定回归 11/0 不回退 |
| ❌ **失败** | 无 |
| ⚠️ **需用户确认** | (a) HUD 分区锚点与 `STAGGER_WINDOW_FALLBACK_SEC=3.0` 为 `[PLACEHOLDER]` 目视/降级初值，需实机目视校准；(b) 公共契约要求的 15~20 秒实机录屏 + 回看：本轮为 headless 门禁、无 GUI 录屏，属人工目视项，**未做、不伪造产物**；(c) 两个新增 HUD 信号（`execution_performed` / `boon_draft_selected`）的下游消费（Rank-3 点数结算 / 下一波代价）不在本轮授权范围，跨 Rank 闭环未打通 |

---

## 4. 玩法拆解表（需求 → 机制 → 数值 → 状态 → 验收）

| 需求 | 机制 | 数值（`[PLACEHOLDER]`） | 状态 | 验收 |
|---|---|---|---|---|
| 赐福引导行与波次行重叠（总指挥目视） | 6 分区归一化锚点 `Rect2`，按视口线性缩放 | `ANCHOR_TITLE/QUALITY/WAVE/GUIDE/STATUS/SIDE/CHAR` | `get_layout_rects()` / `set_layout_viewport()` | A2 两两交集 0、C1 四档不出界 |
| Tab 图鉴 / 兑换 / 抉择面板叠压 + 画质与成长面板同时常驻 | 右侧三面板互斥状态机（优先级 抉择 > 图鉴 > 兑换），`apply_side_panel_visibility()` 落到 `_shop_label.visible` | 无数值 | `_codex_open` / `_boon_draft_open` / `get_visible_side_panels()` | B1~B5、E2 数字键隔离 |
| 韧性处决窗口（机制 B） | 订阅 Rank-2 `execution_window_opened/closed/stagger_value_changed` + F 键 `try_execute()` + `execution_performed` | `STAGGER_WINDOW_FALLBACK_SEC=3.0`（HUD 降级初值） | `_stagger_window_open` / `_stagger_execution_consumed` / `execution_count` | A~H 组，H1~H4 真实联调 |
| 赐福抉择三选一（机制 A） | `on_wave_cleared` 钩子 + 数字键 1/2/3 → `boon_draft_service.select(index)` | 无数值（候选读 `get_config().boons`，3 项） | `_boon_draft_open` / `_boon_draft_selected_index` | E1/E3、G1/G2 真实联调 |

**主动识别的设计漏洞（P0/P1/P2）**
- **P1**｜HUD 分区锚点作用于 hud.gd 暴露的布局模型与 `_shop_label` 显隐；`courtyard.tscn` 的静态 Label offset 本轮只读冻结，真实画面中波次 / 画质 / 图鉴等静态 Label 是否严格落在新分区需实机目视复核（如实登记，未伪造画面断言）。
- **P1**｜`execution_performed.bonus_points` 与 boon `apply()/settle()` 的代价去向需 Rank-3 / 波次导演消费，本轮只接线到 HUD 层，跨 Rank 玩法闭环未打通。
- **P2**｜Rank-1 适配层用「契约候选名鸭子类型」容错，Rank-2 接口现已稳定落盘，建议后续收敛为固定契约常量。
- **P0**：无。

---

## 5. `[PLACEHOLDER]` 数值登记（rationale + 调参唯一入口）

| 常量 | 值 | rationale | 调参唯一入口 |
|---|---|---|---|
| `ANCHOR_*`（7 个归一化 Rect2） | `[0,1]` 比例 | 分区间保留安全缝，随视口缩放线性保持不重叠；配合 autowrap 保证长文本不越界、不叠压 | `hud.gd` §11 常量（只改常量不改布局代码） |
| `STAGGER_WINDOW_FALLBACK_SEC` | 3.0 | Rank-2 `stagger_rules.tres` 落盘前 HUD 侧降级初值；**真实时长以 Rank-2 `execution_window_opened(remaining_sec, bonus_points)` 为准**（真实联调 H2 实测 3.0 / bonus 50） | `hud.gd` §13 常量；真值在 Rank-2 `godot/data/combat/stagger_rules.tres` |
| `LAYOUT_BASE` | 1280x720 | 与 `project.godot` 视口一致 | `hud.gd` §11 |

---

## 6. 未完成项 / 阻塞

- **无功能未完成项、无阻塞**。四块任务全部落地并真跑通过。
- 如实登记（不伪造联调）：Rank-2 的 `stagger_service.gd` / `boon_draft_service.gd` / `stagger_config.gd` / `boon_draft_config.gd` / `stagger_rules.tres` / `boon_draft.tres` **在本轮执行中途落盘**（开工初读时尚不存在）。因此本轮结论不是「待 Rank-2 落盘后复跑」，而是**已绑定真实服务实例完成联调**（H1~H4 / G1~G2 全 PASS）。两个 v100 验证脚本仍保留「落盘则跑真实实例 / 未落盘则 SKIP 并如实打印待复跑」的条件分支，任何时刻都不冒充联调结果。
- 未做：实机录屏 + 回看、目视校准（人工项，见 §3 需用户确认）。

---

## 7. 待总指挥裁决项

1. `execution_performed(window_id, bonus_points)` / `boon_draft_selected(index, choice_id)` 两个新增 HUD 信号的下游消费方（Rank-3 点数结算、波次导演「下一波」代价）由谁接线、何时接线。
2. HUD 分区锚点 `[PLACEHOLDER]` 是否按实机目视统一回写 `courtyard.tscn` 静态 Label offset（该场景本轮 A38 只读冻结，改动需另行授权）。
3. Rank-1 适配层是否由「契约候选名鸭子类型」收敛为固定契约常量（Rank-2 接口现已稳定落盘）。
4. §4 的 P1 设计漏洞（跨 Rank 玩法闭环 / 静态 Label 目视复核）排期。

---

## 8. 边界合规声明

- 只写任务单【目录所有权·R32 冻结】授权 Rank-1 的文件；`encounter_director.gd` 本轮唯一写入方为 Rank-1，未越界写 Rank-2/3/4 文件、素材、数据表、场景、`presentation.gd`。
- 未删 `.workbuddy` 目录；未扫目录做进度巡检；未写只读探针 / 测量 / preflight 脚本；未反复核对文件状态（Rank-2 落盘状态由真跑输出 `exists=true` 发现，非主动巡检）。
- 未自行 git（总指挥收尾）；零付费、零外部依赖、未启 GPU job、未列任何付费项到待办 / 下一步。
- 信号 connect 均有 `_exit_tree` 兜底 disconnect（`impact_feedback.gd` / `hud.gd::_unbind_stagger_signals`）；`extends SceneTree` 的 `--script` 模式显式 `call("_ready")` 后 `set_process(false)`；未用 `get_tree()` / `/root/...` 绝对路径（用 `Engine.get_main_loop() as SceneTree` 取 root）；资源回读 `ResourceLoader.load(..., CACHE_MODE_IGNORE)`；未引入 `cosf()/sinf()`（沿用 `cos()/sin()`）。
