# DONE-R34C · 布局回归修复（Rank-1）

- 轮次：`R34C` · 生产机制文本布局回归修复
- 任务单：`cmd-20261112-120028-967-A1`（`teamwork/Rank-1/调度任务单-latest.json`，GUI 下达 / high）
- 执行：Rank-1（引擎架构与渲染执行 AI）
- 日期：2026-11-12
- 引擎：`Godot v4.7.2.stable.official.ed1daf0bf`（`D:/Godot/Godot_v4.7.2-stable_win64.exe`）
- 工程：`F:/Game/aierdengfahuan/godot`
- 口径：零付费 / 零外部依赖 / 不启 GPU job / 不伪造产物 / 不自行 git

---

## 1. 交付清单

### 1.1 实际改动文件（Rank-1 唯一写入范围内，共 2 个代码文件 + 本文档 + 回执）

| 文件 | 改动摘要 |
| --- | --- |
| `godot/scripts/hud.gd` | ① 新增归一化锚点 `ANCHOR_COMBO`（`hud.gd:1218`）作为「生产机制连击评级 / 倍率 / 命中数文本」**独立分区**；② 新增 `get_production_mechanism_rect()`（`hud.gd:1259`）/`get_shop_title_rect()`（`hud.gd:1265`）两个公开包围盒方法与 `get_hud_layout()` 新 key（`hud.gd:1278-1279`）；③ `set_layout_viewport()` 联动 `_r34_apply_combo_rect()`（`hud.gd:1231`）；④ `ProdComboLabel` 定位由 `R34_RECT_BOTTOM+8/+36` 硬编码像素堆叠改为按锚点 rect 定位（`hud.gd:2169`、`hud.gd:2178`）；⑤ `_r34_build_visible()` 在独立 `hud.tscn --script` 实例无外部 mount 时降级挂 HUD 自身（`hud.gd:2122`），使生产可见层真实节点可被运行时断言读取；⑥ 新增幂等公开入口 `ensure_production_visible_layer()`（`hud.gd:2190`）。 |
| `godot/scripts/render/verify_hud_layout_v100.gd` | **保留既有 24 条断言逐字不删不放宽**；新增 I 组 7 条「真实节点 rect 运行时断言」：新增常量 `COMBO_SVC_PATH`/`COMBO_CFG_PATH`（`verify_hud_layout_v100.gd:37-38`）、夹具补赐福成长标题行真实节点定位 + 显式建生产可见层（`verify_hud_layout_v100.gd:95-102`）、`_initialize()` 追加 `_test_r34c_real_rects()`（`verify_hud_layout_v100.gd:162`）、I 组实现（`verify_hud_layout_v100.gd:451-566`）。注入真实 Tab（`Input.parse_input_event` + `process_key_event`）与真实命中（`ComboService.register_hit(10.0)`）后读真实 Label 节点 `get_global_rect()`。 |
| `teamwork/Rank-1/DONE-R34C.md` | 本文档。 |
| `teamwork/command_center/ai/1/outbox/cmd-20261112-120028-967-A1.json` | 回执 JSON。 |

### 1.2 分区避让修复要点（任务 ①）

- **根因（R34B 引入）**：`ProdComboLabel` 原用 `R34_RECT_LEFT+12 / R34_RECT_BOTTOM+8 / R34_RECT_RIGHT-12 / R34_RECT_BOTTOM+36` 硬编码像素堆叠，落在 `(912,360)-(1264,388)`；赐福成长标题行 `GraceShopLabel`（R29 独立 CanvasLayer）位于 `SHOP_RECT = (740,358)-(1276,568)`。两者 x 区间 `[912,1264]∩[740,1276]=[912,1264]`（宽 352）、y 区间 `[360,388]∩[358,568]=[360,388]`（高 28）→ **改前交集面积 352×28 = 9856 px²**，即总指挥目视的「两行互压」。
- **修法**：新增 `ANCHOR_COMBO = Rect2(0.01875, 0.85556, 0.60000, 0.05000)`（`hud.gd:1218`），1280×720 下解析为 `(24,616)-(792,652)`，位于底部状态条（`ANCHOR_STATUS` y≥0.922）正上方，且整体在中央角色（`ANCHOR_CHAR` y≤0.792）/ 右侧面板（`ANCHOR_SIDE` y≤0.833）/ 兑换面板（`SHOP_RECT` y≤0.789）下沿之下。真实节点 offset 由 `_r34_apply_combo_rect()` 按 `_scaled_rect(ANCHOR_COMBO)` 设置（`hud.gd:2178-2186`），**不硬编码像素堆叠**；视口变化经 `set_layout_viewport()` 联动重定位（`hud.gd:1231`）。
- **不破坏既有断言**：`ANCHOR_COMBO` **不并入** `get_layout_rects()` 的 6 分区数组（既有 A1「rects.size()==6」不放宽），只经新公开方法暴露。
- **A46 / A48 口径保持**：Tab 仍由 `HUD._process_r32_keys` → `_toggle_codex_panel` 单一仲裁（`hud.gd:1670-1671`，未改）；生产可见层仍常驻、每帧按状态刷新（`_r34_refresh_visible()` / `_process()`，未改）。
- **实机挂载路径不变**：有 `SubViewportContainer`/`Courtyard` 时仍挂外部 `ProductionMechanismsLayer`；GATE3 `--headless --quit` 回读 `is_inside_tree=true`（见 §2.5）。

### 1.3 只读未改（硬约束核对）

`encounter_director.gd`、`wave_trial_director.gd`、`presentation.gd`、`project.godot`（本轮 Rank-3 改 autoload）、`courtyard.tscn`（节点 41 / uv 2/1/1）、既有 `.tres`（含 `combo_rules.tres`、`boon_draft.tres`）、素材、其它 Rank 产出 —— **一律只读不改**。只读引用了 Rank-2 的 `combo_service.gd`/`combo_config.gd`/`combo_rules.tres` 用于真实命中注入（`verify` 中 `CACHE_MODE_IGNORE` 回读），未写。

---

## 2. 真跑输出原文

### 2.1 三段门禁命令

```
GATE1: Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --import
GATE2a: ... --headless --path ... --check-only --script res://scripts/render/verify_hud_layout_v100.gd
GATE2b: ... --headless --path ... --script res://scripts/render/verify_hud_layout_v100.gd
GATE3: ... --headless --path F:/Game/aierdengfahuan/godot --quit
G3:    grep -c "SCRIPT ERROR" <三段合并输出>   → 0
```

### 2.2 GATE1 `--headless --import` 原文

```
===== GATE1 --headless --import =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[   0% ] first_scan_filesystem | 正在扫描文件结构……
[  16% ] first_scan_filesystem | 正在加载全局类名……
[  33% ] first_scan_filesystem | 正在校验 GDExtension……
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[  66% ] first_scan_filesystem | 正在初始化插件……
[  83% ] first_scan_filesystem | 正在启动文件扫描……
[ DONE ] first_scan_filesystem

[   0% ] update_scripts_classes | Started 正在注册全局类…… (3 steps)
[   0% ] update_scripts_classes | 
[  25% ] update_scripts_classes | 
[  50% ] update_scripts_classes | 
[ DONE ] update_scripts_classes

[   0% ] loading_editor_layout | Started 正在加载编辑器 (5 steps)
[   0% ] loading_editor_layout | 正在加载编辑器布局……
[  16% ] loading_editor_layout | 正在加载停靠面板……
[ DONE ] loading_editor_layout

GATE1_EXIT=0
```

### 2.3 GATE2a `--check-only --script` 原文

```
===== GATE2a --headless --check-only --script verify =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

GATE2a_EXIT=0
```

### 2.4 GATE2b `--headless --script verify_hud_layout_v100.gd` 原文（完整）

```
===== GATE2b --headless --script verify =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[V100HUD] ==== verify_hud_layout_v100 真跑开始 | R32 v0.10.0 Rank-1 ====
[R34B][HUD] A54 唯一实例：不自建 Combo/Boon 服务，由 _r34_bootstrap() 经 get_combo_service()/get_boon_service() 绑定 wave_trial_director 唯一实例
[R34][HUD] f 链：生产常驻可见层 ProductionMechanismsLayer 入树 is_inside_tree=false（按状态显示，非 presentation.gd 构造）
[V100HUD] A1 6 个分区且 id 齐全（title/quality/wave/guide/status/side） PASS=true | count=6 ids=["title", "quality", "wave", "guide", "status", "side"]
[V100HUD] A2 任意两处文字/面板包围盒交集面积恒 == 0（三处重叠已消除） PASS=true | worst_overlap=0.0000 px²
[V100HUD] A3 6 个分区面积 > 0 且全部落在 1280x720 内 PASS=true | viewport=1280x720
[V100HUD] B1 初始无面板常驻（visible_side_panels 为空，消除画质/成长面板同时常驻） PASS=true | visible=[]
[V100HUD] B2 打开兑换 → 仅 shop 可见 PASS=true | visible=["shop"]
[V100HUD] B3 Tab 图鉴打开 → 隐藏常驻兑换面板，仅 codex 可见（消除叠压） PASS=true | visible=["codex"] codex_open=true
[V100HUD] B4 Tab 图鉴关闭 → 按 shop_open 原态恢复兑换面板 PASS=true | visible=["shop"]
[V100HUD] B5 赐福抉择卡片压过一切，右侧同时仅 1 个面板可见（互斥） PASS=true | visible=["boon_draft"] codex_open=true shop_open=true
[V100HUD] C1 1280x720 基准 + 960x540/640x360/480x270 三档降级：文字不出界且仍不重叠 PASS=true | ["1280x720:bounded=true overlap=0.000", "960x540:bounded=true overlap=0.000", "640x360:bounded=true overlap=0.000", "480x270:bounded=true overlap=0.000"]
[V100HUD] D1 6 个分区与中央角色保护区交集恒 == 0（不遮角色） PASS=true | worst_overlap=0.0000 char=[P: (400.0, 229.9968), S: (480.0, 339.9984)]
[V100HUD] D2 赐福抉择卡片矩形与中央角色保护区不重叠 PASS=true | overlaps=false card_rect=[P: (900.0064, 300.0024), S: (356.0064, 300.0024)]
[V100HUD] E1 抉择卡片打开时数字键 1 被消费 → 走 boon_draft.select、卡片关闭、emit 信号 PASS=true | consumed=true selected=0 open=false selected_signal=1
[V100HUD] E2 抉择数字键未误触既有兑换（grace_purchase_events 无新增） PASS=true | before=0 after=0
[V100HUD] E3 卡片关闭后数字键不被 R32 拦截（交还既有兑换逻辑，状态隔离正确） PASS=true | consumed=false
[V100HUD] F1 courtyard.tscn 静态 [node] 行数 == 41（A38 保持，场景只读） PASS=true | count=41 expected=41
[V100HUD] F2 既有 4 信号 + 新增 2 信号（execution_performed / boon_draft_selected）齐全 PASS=true | missing=[]
[V100HUD] F3 R32 新增关键公开 / 钩子方法可寻址 PASS=true | missing=[]
[V100HUD] G 组：Rank-2 真实服务已落盘 → 绑定真实 BoonDraftService 实例做联调
[V100HUD] G1 真实 BoonDraftService 绑定 + 清波钩子：卡片打开且读到 3 个真实候选 PASS=true | open=true service=true choices=3
[R34][HUD] d 链：抉择 apply() 结算生效 paired=true effect=poise_damage_bonus(0.25) cost=telegraph_scale(0.85) | 已注入 Rank-2 下游消费方=false → 下一波清波由 wave_trial_director.apply()/settle() 消费
[V100HUD] G2 数字键 2 → 真实 boon_draft_service.select(1) 成功、卡片关闭、emit 信号 PASS=true | consumed=true selected=1 select_ok=true reason=ok signal=1
[V100HUD] ==== H 组 R33 真实 Tab 输入 → 实际节点 visible 互斥 ====
[V100HUD] H1 夹具含真实兑换面板节点 GraceShopLabel 且 HUD._shop_label 已绑定（可读实际 visible） PASS=true | panel=true bound=true
[V100HUD] H2 初始（图鉴关闭 / shop_open=true）：真实兑换面板节点 visible=true PASS=true | visible=true side=["shop"]
[V100HUD] H3 真实 Tab 按下/松开后：图鉴打开、右侧仅 codex 可见、兑换面板真实节点 visible=false（互斥生效） PASS=true | consumed=true codex_open=true shop_visible=false side=["codex"]
[V100HUD] H4 真实 Tab 再按下/松开后：图鉴关闭、兑换面板真实节点 visible=true（关闭恢复原态） PASS=true | consumed=true codex_open=false shop_visible=true side=["shop"]
[V100HUD] H5 赐福抉择卡片打开时真实兑换节点仍隐藏、右侧仅 boon_draft 可见（互斥优先级） PASS=true | shop_visible=false side=["boon_draft"]
[V100HUD] ==== I 组 R34C 真实节点 rect 运行时断言（Tab + 命中注入） ====
[V100HUD] I1 真实命中（ComboService.register_hit）后生产机制连击文本真实节点常驻可见且文本含连击/评级/倍率 PASS=true | hit_ok=true node=true visible=true text=连击评价 · 1 连击 ｜ 评级 D ｜ 倍率 1.00
[V100HUD] I2 真实节点 rect：生产机制可见层文本 vs 赐福成长标题行交集面积恒 == 0（R34B 叠压已消除） PASS=true | combo_rect=[P: (24.0, 616.0032), S: (768.0, 36.0)] shop_rect=[P: (740.0, 358.0), S: (536.0, 210.0)] overlap=0.0000 px²
[V100HUD] I3 评级条（生产机制独立分区）vs 其它 HUD 文字块（title/quality/wave/guide/status/side + 赐福成长标题行）两两不相交 PASS=true | combo_anchor=[P: (24.0, 616.0032), S: (768.0, 36.0)] blocks=7 worst_overlap=0.0000 px²
[V100HUD] I4 连击文本真实节点 rect 与独立分区锚点 rect 一致（按锚点定位，不硬编码像素堆叠） PASS=true | node_rect=[P: (24.0, 616.0032), S: (768.0, 36.0)] anchor_rect=[P: (24.0, 616.0032), S: (768.0, 36.0)]
[V100HUD] I5 真实 Tab 打开图鉴后：赐福成长标题行真实节点隐藏、连击文本仍常驻可见、右侧仅 codex（A46/A48） PASS=true | consumed=true codex_open=true shop_hidden=true combo_visible=true side=["codex"]
[V100HUD] I5b 真实 Tab 再注入关闭图鉴 → 赐福成长标题行恢复可见（互斥关闭恢复） PASS=true | consumed=true codex_open=false shop_visible=true
[V100HUD] I6 1280x720 + 三档降级：真实连击节点不出界 / 不遮中央角色 / 不与赐福成长标题行相交 PASS=true | ["1280x720:rect=[P: (24.0, 616.0032), S: (768.0, 36.0)] bounded=true char_ov=0.00 shop_ov=0.00", "960x540:rect=[P: (18.0, 462.0024), S: (576.0, 27.0)] bounded=true char_ov=0.00 shop_ov=0.00", "640x360:rect=[P: (12.0, 308.0016), S: (384.0, 23.0)] bounded=true char_ov=0.00 shop_ov=0.00", "480x270:rect=[P: (9.0, 231.0012), S: (288.0, 23.0)] bounded=true char_ov=0.00 shop_ov=0.00"]
[V100HUD] ---- 回读汇总 ----
[V100HUD] SUMMARY pass=31 fail=0 total=31 ok=true
[V100HUD] RESULT=ALL_MATCH
[V100HUD] ==== verify_hud_layout_v100 真跑结束 ====
WARNING: [SaveSystem] --script 工具模式（未带 v050_read 标记）：跳过自动读回（降级，不崩，保护回归基线）
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/save_system.gd:42)
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: [R34C][PCO] HUD 未就绪（重试 6 次）→ 绑定降级：不订阅、不写盘
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _deferred_bind (res://scripts/rpg/points_commit_orchestrator.gd:135)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
GATE2b_EXIT=0
```

### 2.5 GATE3 `--headless --quit` 原文（关键行）

```
===== GATE3 --headless --quit =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[SaveSystem] 自动读回完成 | dungeon.wave_trial.best_wave=3 | grace.trial.points=450 | dungeon.wave_trial.completed=true
[R29][DEPTH] 档=desktop 命中字段=10 | vignette=0.240 warm=0.450 fog=0.175 deep=0.100 blur=1.50
[R29][DEPTH] 档=mobile 命中字段=10 | vignette=0.120 warm=0.220 fog=0.090 deep=0.140 blur=1.25
[R29][DEPTH] 参数表已读取 path=res://data/render/depth_profile.tres | 总命中=20 | 生效来源=res://data/render/depth_profile.tres | desktop/mobile 双档按画质切换（数值不硬编码于 shader）
[R29][GRADE] shader 小样已挂载（待短跑目视 + 编译日志确认生效） | layer=12 rect=V070DepthGradeRect | 参数来源=res://data/render/depth_profile.tres 命中=20/11
[R30][HUD] 运行时挂载 CodexDirector → Courtyard（独立 CanvasLayer 由导演自建，不写 courtyard.tscn）
[R31][HUD] 运行时挂载 ImpactFeedbackLayer → Courtyard（CanvasLayer，不写 courtyard.tscn；按实接入既有战斗信号 / 画质降级 / 面板避让）
[R34B][HUD] A54 唯一实例：不自建 Combo/Boon 服务，由 _r34_bootstrap() 经 get_combo_service()/get_boon_service() 绑定 wave_trial_director 唯一实例
[R20][FXReflection] 默认档位=desktop（未请求覆盖，desktop 四项全开零回退）
[R20][FXGodRays] 默认档位=desktop（未请求覆盖，desktop 四项全开零回退）
[R20][FXMotes] 默认档位=desktop（未请求覆盖，desktop 四项全开零回退）
[R20][FXBloom] 默认档位=desktop（未请求覆盖，desktop 四项全开零回退）
[R19_CTRL] _detect source=res://data/render/quality_preset_desktop.tres
[R19_CTRL] low_resolution_size active=(640, 360) desktop=(640, 360) mobile=(480, 270)
[R19_CTRL] 判档 active>=desktop=true -> fx_profile=desktop
[R19_CTRL] switch_profile(desktop) set_fx_profile 命中 4/4 子节点 | fx_profile_active=desktop
[R20_CTRL] switch_profile(desktop) prev= applied=4/4 | fx_profile_active=desktop
[R20_CTRL] register_quality_provider ok=true provider=QualitySettings
[R20_CTRL] quality_settings._ready 已注册 provider -> HD2DFX
[R21_QUALITY] 已连接按钮 QualityPanel/VBox/ButtonRow/BtnLow -> 档位 low
[R21_QUALITY] 已连接按钮 QualityPanel/VBox/ButtonRow/BtnMedium -> 档位 medium
[R21_QUALITY] 已连接按钮 QualityPanel/VBox/ButtonRow/BtnHigh -> 档位 high
[R21_QUALITY] 画质设置菜单 UI 就绪 | panel=true rect=(760,32)-(1244,176) | title=画质设置 · 低 / 中 / 高 | buttons=[low{text=低 visible=true} | medium{text=中 visible=true} | high{text=高 visible=true}]
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
[BossController] 阶段装载 -> phase_index=1 pose_prefix=p1_ 招式数=2
[R34][ENC] 生产服务创建 | stagger=true（combo 由 HUD 注入，未落盘则判空降级，不冒充联调）
[WaveTrial] 持久化基线读回：dungeon.wave_trial.best_wave=3 / dungeon.wave_trial.completed=true / grace.trial.points=450（经 WorldState.get_flag）
[BossController] 阶段装载 -> phase_index=1 pose_prefix=p1_ 招式数=2
[WaveTrial] 增益运行时接线：checked=3 applied=1 degraded=0 reasons=[]
[WaveTrial]   · hp_max_bonus hp_max status=applied before=100.0 after=120.0 via=@export player_max_hp + trial_grace_rest()
[WaveTrial]   · roll_iframe_bonus roll_iframe status=not_purchased before=- after=- via=未购买
[WaveTrial]   · attack_power_bonus attack_power status=not_purchased before=- after=- via=未购买
[Tutorial] 可选教学配置已读：res://data/rpg/tutorial_steps.tres | texts=["按 J 发动一次轻攻击", "按 Space 翻滚一次", "按 E 与赐福交互"] hints=["J", "Space", "E"] rewards=[20, 30, 50]
[Tutorial] 存档已完成（grace.tutorial.completed=true）→ 跳过教学，波次自动开始（按 T 可强制重开）
[R32][impact_fx] 只读加载成功 png=res://assets/generated/r23/impact_fx.png frames=4 fw=128 cols=4 palette_id=hd2d_index_256_v1
[R34C][PCO] 生产订阅者已绑定 HUD | signals=4 slot=user://saves/slot_01（A55 唯一权威通道）
[R29][SHOP] 兑换面板迁出 SubViewport → 独立 CanvasLayer(layer=45) | 固定字号=20 + 描边/阴影/深底高对比 | rect=(740,358)-(1276,568) 避开 赐福HUD(x<730,y<220)/画质面板(x>760,y<180)
[R29B][SHOP] 默认隐藏 visible=false (shop_open=false) | 深底 alpha=0.30 | rect=(740,358)-(1276,568) 屏幕右下避开玩家/Boss 包围盒 | autowrap=3
[R30][CODEX] 读到 Rank-2 图鉴资源 entries=4（显示文本/ id 覆盖内置默认，条件仍按 4 类判定）
[R30][CODEX] ready | source=tres entries=4 degraded=false | 面板 deferred 建层(独立 CanvasLayer，不写场景)
[R33][HUD] Tab 互斥仲裁收敛：CodexDirector 自身 Tab 监听关闭，HUD._unhandled_input 统一处理 Tab 并经 toggle_panel() 同步真实图鉴面板 visible
[R34][HUD] f 链：生产常驻可见层 ProductionMechanismsLayer 入树 is_inside_tree=true（按状态显示，非 presentation.gd 构造）
[R34][HUD] 生产链装配完成 | stagger_bound=true boon_bound=true combo_bound=true combo_signals=true wave_cleared=true wave_started=true visible=true
[R34][ComboFX] 绑定唯一 ComboService 成功 node=FXBloom signals=4（A54 复用 get_combo_service，不自建）
[R34][ENC] 同一 StaggerService 已推给 HUD（命中削韧 ↔ 韧性条单一事实源） | hud=Hud
[R30][CODEX][PANEL] 独立 CanvasLayer(layer=46) 建层 | rect=(24,272)-(380,508) alpha=0.30 | 默认隐藏 | 不写 courtyard.tscn
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
GATE3_EXIT=0
```

### 2.6 全工程 G3 `grep SCRIPT ERROR` 统计

```
===== SCRIPT ERROR COUNT (全工程 G3) =====
0
GREP_EXIT=1          # grep -c 无匹配时退出码 1，计数为 0
```

四段退出码：`GATE1_EXIT=0` / `GATE2a_EXIT=0` / `GATE2b_EXIT=0` / `GATE3_EXIT=0`。**`SCRIPT ERROR=0`**。

### 2.7 A38 校验（courtyard.tscn 只读回读）

- 节点数：`F1` 断言 `count=41 expected=41 PASS=true`；GATE3 `--quit` 另有 `courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41`。
- uv `2/1/1`：`courtyard.tscn:24` 登记「uv1_scale 4/2/1 → 2/1/1」；只读回读三材质 `uv1_scale` 的 x 分量 —— `courtyard.tscn:30` `StandardMaterial3D_uvplate = Vector3(2, 2, 1)`、`courtyard.tscn:35` `uvlow = Vector3(1, 1, 1)`、`courtyard.tscn:40` `uvhigh = Vector3(1, 1, 1)` → **2/1/1 不变**。
- 本轮 Rank-1 未写 `courtyard.tscn`。

---

## 3. 验收三态

### 3.1 三态汇总（PASS / FAIL / SKIP）

| 状态 | 计数 | 说明 |
| --- | --- | --- |
| **PASS** | 31 条断言 + 4 段门禁 | 既有 24 条全 PASS 未删未放宽；新增 I 组 7 条全 PASS；`RESULT=ALL_MATCH`；GATE1/2a/2b/3 全 `EXIT=0`；`SCRIPT ERROR=0`；A38 41 / 2/1/1 不变 |
| **FAIL** | 0 | 无 |
| **SKIP** | 0 | G 组 Rank-2 真实 `BoonDraftService` 已落盘并联调，未触发「未落盘 SKIP」 |

### 3.2 三块任务逐项验收

| 任务 | 验收点 | 证据 | 结论 |
| --- | --- | --- | --- |
| ① 分区避让修复 | 连击评级 / 倍率 / 命中数文本移入独立分区、用锚点不硬编码 | `ANCHOR_COMBO`（`hud.gd:1218`）+ I4 `node_rect == anchor_rect` PASS | **PASS** |
| ① | 不与赐福成长标题行 / 波次行 / 赐福引导行 / 图鉴面板 / 画质面板相交 | I2 `overlap=0.0000 px²`；I3 `blocks=7 worst_overlap=0.0000 px²`（6 分区 + shop title） | **PASS** |
| ① | 1280×720 与降级分辨率不出界、不遮中央角色 | I6 四档 `bounded=true char_ov=0.00 shop_ov=0.00` | **PASS** |
| ① | A46 单一 Tab 仲裁者 / A48 生产可见层常驻口径不变 | I5 `codex_open=true`、`combo_visible=true`、`side=["codex"]`；`hud.gd:1670-1671` 未改 | **PASS** |
| ② 运行时断言 | 保留既有 24 条不删不放宽 | A~H 组逐条 PASS，`SUMMARY total=31`（24+7） | **PASS** |
| ② | 新增「生产机制可见层文本 vs 赐福成长标题行」真实节点 rect 断言 | I2，注入真实 `register_hit` 后读 `get_global_rect()`，`overlap=0.0000` | **PASS** |
| ② | 新增「评级条 vs 其它 HUD 文字块」真实节点 rect 断言 | I3，`blocks=7 worst_overlap=0.0000` | **PASS** |
| ② | 注入真实 Tab 与命中输入后读实际节点位置 | I1 `hit_ok=true`、I5/I5b Tab 互斥恢复 `consumed=true` | **PASS** |
| ② | 输出 PASS/FAIL + `RESULT=ALL_MATCH` | 逐条 `PASS=true/false` + `RESULT=ALL_MATCH` | **PASS** |
| ③ 门禁 | 三段门禁真跑 + 全工程 G3 `grep SCRIPT ERROR=0` | §2.2~§2.6，4 段 `EXIT=0`、计数 `0` | **PASS** |
| ③ | A38 节点数 41 / uv 2/1/1 不变 | §2.7 | **PASS** |
| 如实登记 | 第 340 帧「处决窗口 1.8s · 按 F」自然出现正向证据 | §6 | **PASS** |

### 3.3 文字重叠是否消除（结论）

**已消除（几何 / 真实节点 rect 口径）**：改前 `ProdComboLabel (912,360)-(1264,388)` 与 `GraceShopLabel (740,358)-(1276,568)` 交集 **9856 px²**；改后 `ProdComboLabel (24,616)-(792,652)` 与 `(740,358)-(1276,568)` 交集 **0 px²**（I2 实测 `overlap=0.0000 px²`）。评级条与 7 个 HUD 文字块两两不相交（I3 `worst_overlap=0.0000 px²`）。
**说明**：以上为 `--headless` 真跑的几何 / 真实节点 rect 断言结论；最终「画面可读性」以总指挥本轮亲自重跑的 15~20 秒实机录屏目视为准（按公共契约，Rank-1 不重复录屏）。

---

## 4. 未完成项

1. **实机录屏与目视**：15~20 秒实机录屏 / 目视由总指挥本轮亲自重跑，Rank-1 按公共契约未重复录屏；本轮交付的真跑为 `--headless` 逻辑门禁，不替代目视。
2. **`ANCHOR_COMBO` 数值为 `[PLACEHOLDER]` 初值**（`hud.gd:1218`，`rationale` 已随代码注释），待试玩目视校准后定稿，本轮未定稿数值。
3. **「与右下 D/C/B/A/S 评级条合并」方案未采用/未验证**：`hud.gd` 内不存在独立的 D/C/B/A/S 评级条节点，本轮采用任务 ① 建议的另一方案「放进左下状态条的独立行」。若后续 Rank-4 落盘该评级条，合并方案见 §5 待裁决项 2。

---

## 5. 待总指挥裁决项

1. **`ANCHOR_COMBO` [PLACEHOLDER] 布局初值**：`Rect2(0.01875, 0.85556, 0.60000, 0.05000)` 待试玩目视校准（是否需微调 y 安全缝 / 宽度 / 是否与底部状态条合并为同一分区）。
2. **连击文本落位方案二选一**：本轮落「左下状态条上方独立行」；任务 ① 建议的「与右下 D/C/B/A/S 评级条合并」因 `hud.gd` 内无该节点未采用。请裁决是否在 Rank-4 评级条落盘后改为合并，或维持独立分区。
3. **独立 `hud.tscn --script` 实例的夹具降级挂载口径**：本轮为让运行时断言读到「真实节点 rect」，在 `_r34_build_visible()` 无外部 mount 时降级挂 HUD 自身（`hud.gd:2122`）。实机（有 `SubViewportContainer`/`Courtyard`）仍挂外部 `ProductionMechanismsLayer`，GATE3 回读 `is_inside_tree=true`。请裁决该夹具降级是否需登记为常驻契约、或改为仅在 verify 内构造。
4. **跨 Rank 接口（Rank-3 `PointsCommitOrchestrator` autoload，A56 授权）**：`--script` 工具模式下报 `WARNING: [R34C][PCO] HUD 未就绪（重试 6 次）→ 绑定降级：不订阅、不写盘`；实机 `--quit` 下 `[R34C][PCO] 生产订阅者已绑定 HUD | signals=4` 正常。属跨 Rank 只读观察，`project.godot` 与 Rank-3 文件本轮未改；是否需在 Rank-3 DONE 补登记 `--script` 降级口径，交总指挥裁决。
5. **`WARNING: 2 ObjectDB instances were leaked at exit`**：`--script`（含 verify）与**无 verify 的纯 `--quit`** 两种模式均出现 → 判定为工程既有现象，非本轮引入、非 `SCRIPT ERROR`、不影响门禁。是否立项清理交总指挥裁决。
6. **R34B / Rank-4 DONE 旧结论修订**：其 DONE 把该叠压标为「既有、非本轮引入」并把「处决窗口」标为「未覆盖 / 15 秒内未自然触发」，与总指挥目视不符（见 §6）。是否要求对应 Rank 修订历史 DONE，交总指挥裁决；Rank-1 本轮只在本 DONE 如实登记，不改其它 Rank 文件。

---

## 6. 「处决窗口自然触发」正向证据（如实登记）

- **总指挥亲自目视**：回看 `capture/v110_final.mp4` 第 **340 帧**，确认 **「处决窗口 1.8s · 按 F」在真实链路下自然出现**。
- **性质**：这是**正向证据**，比 R34B / Rank-4 DONE 登记的「15 秒内未自然触发 / 未覆盖」更乐观；本轮 **不沿用旧的「未覆盖」结论**，也不把该项列入「未完成项 / SKIP」。
- **链路保持**：既有 R32 处决链路（`stagger_service` / `_try_execution_input` / `KEY_F` 分支 `hud.gd:1673-1674` / 1.8s 窗口文本 / `execution_performed` 信号）**逐字未动、未删改**；本轮三块任务只改 HUD 生产机制文本分区与验证脚本，不触碰处决触发链。
- **证据边界**：该正向证据来自总指挥目视（真实链路画面），Rank-1 本轮未重复录屏、未伪造该证据，也未以 `--headless` 逻辑门禁冒充目视结论。
- **附带佐证（非替代）**：GATE3 `--quit` 实机装配输出 `[R34][HUD] 生产链装配完成 | stagger_bound=true ...` 与 `[R34][ENC] 同一 StaggerService 已推给 HUD（命中削韧 ↔ 韧性条单一事实源）`，显示处决窗口所依赖的 StaggerService 链路在实机正常装配；窗口「自然出现」的判定仍以总指挥第 340 帧目视为准。

---

## 7. 附：真跑 WARNING 如实登记（非 SCRIPT ERROR，不计入门禁）

| WARNING | 出现位置 | 判定 |
| --- | --- | --- |
| `[SaveSystem] --script 工具模式（未带 v050_read 标记）：跳过自动读回` | GATE2b | `--script` 工具模式既有降级，不崩、保护回归基线 |
| `[ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下` | GATE2b | `--script` 无场景树既有降级 |
| `[R34C][PCO] HUD 未就绪（重试 6 次）→ 绑定降级：不订阅、不写盘` | GATE2b | 跨 Rank（Rank-3 autoload）`--script` 降级；实机 `--quit` 正常绑定，见 §5.4 |
| `2 ObjectDB instances were leaked at exit` | GATE2b **及** GATE3（无 verify 亦出现） | 工程既有现象，非本轮引入，非 `SCRIPT ERROR` |

---

## 8. 回执与中枢归档确认

- 写入路径：`teamwork/command_center/ai/1/outbox/cmd-20261112-120028-967-A1.json`（**是 `teamwork/command_center/`，不是工程根**）。
- 写入后 `outbox/` 由中枢消费清空；**中枢已归档**到 `teamwork/command_center/dispatcher/receipts/cmd-20261112-120028-967-A1.json`，`dispatcher/ledger.jsonl:140` 有该 `task_id` 记录（时间戳 12:23）。
- 归档回执回读校验：`JSON OK`、`keys=['task_id','ai','status','result']`、`ai=1`、`status=done`、`result` 749 字符且引用 `DONE-R34C.md`，含 `RESULT=ALL_MATCH` / `SCRIPT ERROR=0` /「处决窗口」正向证据。

---

（本 DONE 结论与真跑输出原文一致；回执 `result` 引用本文件实际结论。）
