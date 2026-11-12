# DONE-R31.md · Rank-1 交付报告

- 派单：`cmd-20261111-133549-878-A1`（`cmd-20261111-133549-878` / `ai=1`）
- 轮次 / 版本：`[ROUND=R31]` · v0.9.0
- 依据：`teamwork/Rank-1/调度任务单-latest.json` 的 `id` / `task` 全文（完整清单 + 公共契约 + 目录所有权）、`teamwork/00-协作契约.md`
- 工作目录：`F:/Game/aierdengfahuan` · 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`v4.7.2.stable.official.ed1daf0bf`）
- 目录所有权：`godot/scripts/render/impact_feedback.gd`、`hud.gd`、`presentation.gd`、`verify_impact_feedback_v090.gd` 归 Rank-1；本轮只写其中 3 个（新建 2 + 修改 1），`presentation.gd` 本轮未改动（任务 ①②③ 未涉及，不擅自扩范围）。

---

## 一、实际交付清单

### 1) 新建 `godot/scripts/render/impact_feedback.gd`（CanvasLayer 打击反馈层）

- **结构**：`extends CanvasLayer`。因 `CanvasLayer` 继承 `Node`、不是 `CanvasItem`、本身没有 `_draw()`，内部定义 `class FlashPainter extends Node2D` 并在 `_ready()` 运行时 `add_child` 承担**程序化 `_draw()` / `draw_rect()`** 暖金闪光（非原生后处理、非外部贴图、零 GPU job、零付费）。`layer=12`。
- **三类反馈**：
  - 命中瞬间暖金闪光：`FLASH_PEAK_ALPHA=0.42`、线性衰减 `0.06/帧`（7 帧归零，单调不增）、`_draw()` 只画安全区矩形。
  - 短促屏幕微震：以 `CanvasLayer.offset` 真实位移，确定性 `cos()/sin()` 振荡（不用 rand，headless 可复现），`SHAKE_MAX_AMPLITUDE=6.0` 上限、`1.2/帧` 衰减（5 帧归零）。
  - hitstop 请求：`request_hitstop(frames)` 一律 `clampi` 到 `[0, HITSTOP_MAX_FRAMES=4]`，只登记请求帧数并逐帧递减，**不暂停引擎帧循环**（不干扰 `--script` 门禁帧推进）。
- **降级开关**：`set_low_quality(true)`（低画质 / 移动端）→ 只保留闪光，`shake_amplitude=0` / `offset=ZERO` / `hitstop=0`，已有值立即归零；`set_low_quality(false)` 恢复。
- **HUD 避让**：7 个 HUD 文字 / 面板矩形（左上标题、画质面板、波次 HUD、教学 HUD、右下兑换面板、底部战斗 HUD、Tab 图鉴面板）各 `grow(AVOID_MARGIN=8.0)`（`> 微震上限 6`，保证微震平移时闪光边缘也不侵入文字区）；扫描线矩形分解得 60 个安全 `flash_rect`（真跑回读），`_draw()` 只画这些矩形；`sample_flash(x,y)` 按实际绘制矩形采样，避让区 / 屏幕外恒返回 `0.0`。`set_panel_open(name, open)` 在 shop / codex 面板打开时追加强化避让矩形。
- **按实接入既有信号**（读 `godot/scripts/combat/encounter_director.gd` 后接入，**未改该文件**）：
  - `SIG_ENCOUNTER_FINISHED = "encounter_finished"`（`:25 signal encounter_finished(won: bool)`）
  - `SIG_GRACE_RESTED = "grace_rested"`（`:26 signal grace_rested(rest_count: int)`）
  - `SIG_MOVE_LANDED = "move_landed"`（`:337 _bind_boss()` 里 `boss.connect("move_landed", ...)` 既有连接的 BossController 信号）
  - `_dedup_connect()` 在 `connect` 前用 `source.get_signal_connection_list(sig)` **按方法名去重**（`cb.get_object()==self and cb.get_method()==method` 则跳过），同一信号不重复 connect → 不重复触发；`_exit_tree()` 统一断开，不留悬空 Callable。
- **命中瞬间驱动**：既有导演层 `_try_player_hit()` 只做 `_hits_landed += 1`、并未声明命中信号，且本轮硬约束「不改既有战斗逻辑 / 不改 `encounter_director.gd`」，故提供公共入口 `request_impact(intensity)` 由集成层在命中帧显式调用，不臆造、不私改既有件（详见第四节待裁决 1）。
- 所有新数值标 `[PLACEHOLDER]` 并在代码内逐条写 rationale（峰值 / 衰减 / 幅度 / 频率 / 帧数 / margin / layer / 7 个避让矩形 / 暖金色）。
- `--script` 纪律：不用 `get_tree()`、不用 `/root/...` 绝对路径；`add_child` 不自动 flush `_ready()`，验证脚本显式 `call("_ready")`，全部状态推进经公共 `advance_frame()` 显式驱动。

### 2) 修改 `godot/scripts/hud.gd`（**5 处最小追加，1~9 节既有逻辑逐字未动**）

- 新增 R31 常量 `IMPACT_FEEDBACK_PATH` / `IMPACT_LAYER_NAME`、变量 `var _impact_feedback`、`_ready()` 末尾 `_ensure_impact_feedback()`、`_refresh_shop_hud()` 开头 `_sync_impact_panels()`、文件末尾 §10。
- `_ensure_impact_feedback()`：沿父链找 `SubViewportContainer` → 取其父节点 `Courtyard` 作挂载根（与 R29 兑换层 / R30 `CodexDirector` 同口径：SubViewport 之外、铺满真实 1280×720 视口），`mount.call_deferred("add_child", layer)` **运行时 add_child 挂载**（`call_deferred` 避开 `_ready()` 传播期 `Parent node is busy setting up children` 的 R29 实证错误）；随后 `bind_director(EncounterRoot)` 按实接入既有信号、读 `QualitySettings.get_quality_preset()`（`low`/`mobile` → `set_low_quality(true)`，不每帧轮询）。独立 `hud.tscn` 实例（`--script` 验证）祖先链无 `SubViewportContainer` → 判空返回、不建节点，保护既有 58/30/11/127 PASS 回归不回退。
- `_sync_impact_panels()`：事件驱动（`_refresh_shop_hud` / 挂载完成时各一次）把 `shop_open` 与只读 `CodexDirector.is_panel_open()` 同步给反馈层 `set_panel_open()`，**Tab 图鉴 / 兑换面板打开时反馈层不遮挡文字**；依赖缺失判空降级、不产生 SCRIPT ERROR。
- **未改**：`godot/scenes/courtyard.tscn`（静态节点数 41、`uv1_scale` 2/1/1 原样，A38 断言保持）、`encounter_director.gd`、既有 `.tres` / 数据表、`project.godot`、素材、其它 Rank 文件一律只读。

### 3) 新建 `godot/scripts/render/verify_impact_feedback_v090.gd`（`extends SceneTree`）

- 11 组共 35 条断言，逐条打印 `PASS/FAIL`，输出 `SUMMARY pass/fail` 与 `RESULT=ALL_MATCH`（全通过）/ `RESULT=MISMATCH`（有失败，如实）。
- 任务单 ③ 七条必测：闪光衰减单调（C）、微震幅度不超上限（D）、hitstop 帧数不超上限（E）、降级开关生效（F）、HUD 避让区像素 0（G）、重复 connect 不重复触发（H）、无信号不自发光（B）。
- 补充：按实接入信号名（A，读 `encounter_director.gd` 的 `get_script_signal_list()` 回读真实信号名 + 反馈层常量比对）、面板打开不遮挡（I）、A38 不破坏（J：节点数 41 / uv 2/1/1 / 无静态反馈层节点）、`hud.gd` 挂载接线（K）。
- 纪律：`root.add_child(host)` 相对装配、显式 `call("_ready")` + `set_process(false)`（确定性）、`ResourceLoader.load(..., CACHE_MODE_IGNORE)` 回读、不用 `get_tree()` / `/root/...`；`FakeDirector` / `FakeBoss` 为 `add_user_signal` 轻量替身（只为确定性 emit，不加载 / 不改既有战斗件），真实信号名由 A 组从脚本列表读回证明。

---

## 二、真跑输出结论（关键输出原文）

引擎：`Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org`

### 三段门禁（各段 EXIT 与 `SCRIPT ERROR` 统计）

```
===== G1 --headless --import =====        G1_EXIT=0 SCRIPT_ERROR=0
===== G2A --check-only --script =====     G2A_EXIT=0 SCRIPT_ERROR=0
===== G2B --headless --script verify ==== G2B_EXIT=0 SCRIPT_ERROR=0
===== G3 --headless --quit ============== G3_EXIT=0 SCRIPT_ERROR=0
```
**合计 `SCRIPT ERROR=0`**（四段全部 `grep -c 'SCRIPT ERROR'` 得 0）。

命令（原文）：
```
D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --import
D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --check-only --script res://scripts/render/verify_impact_feedback_v090.gd
D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/render/verify_impact_feedback_v090.gd
D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --quit
```

### G2B 验证脚本输出（原文摘录，均为运行期实际回读值）

```
[V090] ==== verify_impact_feedback_v090 真跑开始 | cmd-20261111-133549-878-A1 [ROUND=R31] Rank-1 ====
[V090] LOAD feedback class=GDScript resource_path=res://scripts/render/impact_feedback.gd CACHE_MODE_IGNORE=true
[V090] A1 encounter_director.gd 既有信号含 encounter_finished / grace_rested PASS=true | script_signals=["encounter_finished", "grace_rested"]
[V090] A2 反馈层信号常量与既有信号名逐字一致（按实接入、不臆造） PASS=true | constants=[encounter_finished,grace_rested,move_landed]
[V090] A3 反馈层为 CanvasLayer 且 layer 低于 HUD 文字层（双保险不遮文字） PASS=true | class=CanvasLayer layer=12
[V090] B1 新建 + _ready 后 flash/shake/hitstop/impact 全 0 PASS=true | flash=0.0 shake=0.0 hitstop=0 impact=0
[V090] B2 无信号推进 6 帧仍全 0（不自发光） PASS=true | flash=0.0 shake=0.0 hitstop=0 impact=0
[V090] C1 触发后 flash_alpha == 峰值且 ≤ 上限 PASS=true | peak=0.4200 cap=0.4200
[V090] C2 连续 12 帧衰减单调不增且恒 ≥ 0 PASS=true | seq=[0.42, 0.36, 0.3, 0.24, 0.18, 0.12, 0.06, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
[V090] C3 衰减到 0 后保持 0、不回升 PASS=true | final=0.0000
[V090] D1 3 轮触发 × 8 帧：amplitude / offset.length 恒 ≤ SHAKE_MAX_AMPLITUDE PASS=true | cap=6.00 worst_amp=6.0000 worst_offset_len=6.0000
[V090] E1 request_hitstop(999) == 上限（clamp） PASS=true | actual=4 cap=4
[V090] E2 request_hitstop(-5) == 0（下限 clamp） PASS=true | actual=0
[V090] E3 hitstop 帧数恒 ≤ 上限且逐帧递减到 0 PASS=true | seq=[4, 3, 2, 1, 0, 0] last=0 cap=4
[V090] F1 降级后闪光仍生效（flash_alpha > 0） PASS=true | flash=0.42
[V090] F2 降级后 shake=0 / offset=ZERO / hitstop=0（只保留闪光） PASS=true | shake=0.0 offset=(0.0, 0.0) hitstop=0 low=true
[V090] F3 降级后 request_hitstop(999) == 0 PASS=true | actual=0
[V090] F4 关闭降级后微震 / hitstop 恢复（> 0） PASS=true | shake=6.0 hitstop=2 low=false
[V090] G1 flash_rects 非空（程序化 _draw 有可画安全区） PASS=true | flash_rects=60 avoid_rects=7
[V090] G2 每个 flash_rect 与每个 avoid_rect 几何交集面积恒 == 0 PASS=true | worst_overlap=0.0000 px²
[V090] G3 HUD 避让区所有采样点 flash 像素 == 0（峰值态） PASS=true | max_pixel=0.0000
[V090] G4 避让集覆盖左上标题 / 右下兑换 / Tab 图鉴三个关键矩形 PASS=true | title=true shop=true codex=true
[V090] G5 安全区（角色区 640,400）flash 像素 > 0（闪光确实可见） PASS=true | sample=0.4200
[V090] G6 屏幕外采样 flash 像素 == 0 PASS=true | sample=0.0000
[V090] H1 重复 bind_director 后每个既有信号仍仅 1 条连接（按方法名去重） PASS=true | encounter_finished=1 grace_rested=1
[V090] H2 emit 一次 encounter_finished → impact_count == 1（不重复触发） PASS=true | impact_count=1
[V090] H3 再 emit 一次 → impact_count == 2（信号仍正常驱动） PASS=true | impact_count=2
[V090] H4 grace_rested 亦按实接入并触发（impact_count == 3） PASS=true | impact_count=3
[V090] H5 Boss.move_landed 按实接入、去重后又触发一次（impact_count == 4） PASS=true | boss_move_landed_connections=1 impact_count=4
[V090] I1 shop / codex 面板打开后，面板矩形内 flash 像素仍全 0 PASS=true | max_pixel=0.0000
[V090] I2 面板打开后避让集仍覆盖 shop / codex 关键矩形 PASS=true | avoid_rects=9 shop=true codex=true
[V090] I3 set_panel_open 状态可只读回读（shop=true / codex=true） PASS=true | panel_open={ "shop": true, "codex": true }
[V090] J1 courtyard.tscn 静态 [node] 行数 == 41（A38 节点数保持） PASS=true | count=41 expected=41
[V090] J2 uv 2/1/1 原样：Vector3(2,2,1) ×1 + Vector3(1,1,1) ×2 PASS=true | uv_2x=1 uv_1x=2
[V090] J3 courtyard.tscn 文本无 ImpactFeedbackLayer / impact_feedback.gd（运行时挂载、不写场景） PASS=true | contains_layer=false contains_script=false
[V090] K1 hud.gd 含 IMPACT_FEEDBACK_PATH / IMPACT_LAYER_NAME / _ensure_impact_feedback PASS=true | path=true name=true ensure=true
[V090] K2 hud.gd 含 call_deferred add_child / bind_director / set_low_quality / set_panel_open PASS=true | add_child=true bind=true degrade=true panel=true sync=true
[V090] ---- 回读汇总 ----
[V090] SUMMARY pass=35 fail=0 total=35 ok=true
[V090] RESULT=ALL_MATCH
[V090] ==== verify_impact_feedback_v090 真跑结束 ====
```

### G3 `--headless --quit` 真实场景运行时挂载证据（原文摘录）

```
[R31][HUD] 运行时挂载 ImpactFeedbackLayer → Courtyard（CanvasLayer，不写 courtyard.tscn；按实接入既有战斗信号 / 画质降级 / 面板避让）
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
[R29B][SHOP] 默认隐藏 visible=false (shop_open=false) | 深底 alpha=0.30 | rect=(740,358)-(1276,568) 屏幕右下避开玩家/Boss 包围盒 | autowrap=3
[R30][CODEX][PANEL] 独立 CanvasLayer(layer=46) 建层 | rect=(24,272)-(380,508) alpha=0.30 | 默认隐藏 | 不写 courtyard.tscn
```
G3 加载完整 `courtyard.tscn` 主场景、flush 了 `call_deferred`，反馈层真实挂载且无任何 SCRIPT ERROR。

### 修复记录（如实，不隐瞒首次失败）

首次 G2B 真跑报：
```
SCRIPT ERROR: Parse Error: Function "cosf()" not found in base self.
   at: GDScript::reload (res://scripts/render/impact_feedback.gd:201)
SCRIPT ERROR: Parse Error: Function "sinf()" not found in base self.
   at: GDScript::reload (res://scripts/render/impact_feedback.gd:241)
```
根因：Godot 4.7.2 / GDScript 全局三角函数为 `cos()` / `sin()`，无 `cosf()` / `sinf()`。首跑因此连锁出现 `_fb_script.new()` 不可用、`SUMMARY pass=6 fail=2 RESULT=MISMATCH`。已把 `cosf/sinf` 改为 `cos/sin` 后**完整重跑三段门禁**，得上述 `G1/G2A/G2B/G3 EXIT=0`、`SCRIPT ERROR=0`、`SUMMARY pass=35 fail=0`、`RESULT=ALL_MATCH`。

### 关于退出期告警（如实登记）

G2B / G3 退出期各有既有 WARNING：`[SaveSystem] --script 工具模式…跳过自动读回`、`[ChunkManager] 未找到 ChunkRoot…`、`2 ObjectDB instances were leaked at exit`。其中 `ObjectDB leaked` 在**不跑本轮 verify 脚本的 G3** 同样出现，属全工程既有 `--script` / `--quit` 退出期现象，非本轮引入；四段 `SCRIPT ERROR=0` 不受影响。

---

## 三、未完成项与阻塞

1. **15~20 秒实机录屏并回看未执行**：公共契约纪律要求「用跑起来的画面判断进度 / 15~20 秒实机录屏并回看」，但本轮派单 ①②③ 与 hint 未包含录屏/抓帧回看项，且硬约束「不启 GPU job、零付费、只写授权文件、不自行扩范围」。本轮真跑证据为三段门禁 + 35 条验证断言 + G3 完整主场景运行时挂载日志。如需补录屏，请总指挥派单（可复用 `godot/test/presentation.gd` 既有 450 帧流程；`capture/` 属 Rank-4 授权）。
2. **`[PLACEHOLDER]` 数值待试玩校准**：闪光峰值 / 衰减、微震幅度 / 频率、hitstop 帧数、`AVOID_MARGIN`、`LAYER_INDEX`、7 个避让矩形、暖金色均为布局 / 手感值，代码内已逐条写 rationale；按契约 §5「WorkBuddy 不替人做手感与审美判断」，本轮不做目视定稿。
3. **「命中瞬间」自动信号驱动未接线**：既有 `encounter_director.gd` 未声明命中信号，本轮严守「不改既有战斗逻辑 / 不改该文件」，只在反馈层留 `request_impact(intensity)` 公共入口；`hud.gd` 挂载时仅按实接入既有 `encounter_finished` / `grace_rested` / `move_landed` 三信号，尚未把 `request_impact()` 接到玩家命中帧（会触及既有战斗件）。见待裁决 1。
4. **未做既有全量回归**：任务单只要求三段门禁 + 本轮 verify；v060/v070/v080 等既有 verify 脚本未逐一串行真跑。G3 全场景加载无 SCRIPT ERROR 间接覆盖部分集成面，但不冒充「全量回归已通过」。如需请派单。
5. **无阻塞**：三段门禁与验证脚本均已真跑通过，交付文件齐全，回执已写。

---

## 四、待总指挥裁决项

1. **命中信号接口归属（跨模块）**：是否授权 Rank-2 在 `encounter_director.gd` 的 `_try_player_hit()` 命中帧新增一个 `combat_hit(...)` 信号（或授权装配层在命中帧调用 `ImpactFeedback.request_impact()`），使「命中瞬间」由信号自动驱动、而非当前显式调用？本轮严守不越界，未改该文件、未臆造信号名。
2. **层号共用**：`ImpactFeedbackLayer layer=12` 与 G3 日志中 `[R29][GRADE] V070DepthGradeRect … layer=12` 同层，Godot 按场景树顺序绘制（反馈层后挂 → 在其上）。两者均低于 HUD 文字层（20 / 21 / 45 / 46），且几何避让已保证不遮文字，未发现冲突；若要求独占层号，可调整 `[PLACEHOLDER] LAYER_INDEX`（当前 12）。
3. **是否补 15 秒实机录屏 / 抓帧回看与既有全量回归**（见未完成项 1 / 4）。
4. **`[PLACEHOLDER]` 数值与 7 个避让矩形待试玩目视校准后是否统一收敛**（本轮只登记、不擅改）。
5. `presentation.gd` 属 Rank-1 授权但本轮未改动（任务 ①②③ 未涉及）；若需在 450 帧演示序列里注入一次命中反馈留证，请派单明确。

---

## 五、回执

已按任务单 `id` 写回执到
`F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/cmd-20261111-133549-878-A1.json`
（**是 `teamwork/command_center/`，非工程根 `command_center/`**；工程根 `F:/Game/aierdengfahuan/command_center` 经真跑确认不存在，未写错位置），字段：`task_id` / `ai=1` / `status=done` / `result`（引用本文实际结论）。

回执 JSON 全文（与写入内容逐字一致）：
```json
{"task_id":"cmd-20261111-133549-878-A1","ai":1,"status":"done","result":"引用 DONE-R31.md 实际结论：R31 交付 impact_feedback.gd / hud.gd 运行时挂载 / verify_impact_feedback_v090.gd 三件；三段门禁 G1/G2A/G2B/G3 均 EXIT=0 且 SCRIPT_ERROR=0；验证 35 PASS / 0 FAIL / RESULT=ALL_MATCH；courtyard.tscn 节点数 41 与 uv 2/1/1 原样保持。"}
```

### 回执投递实证（如实登记，非谎报）

写入后曾观察到 outbox 内 `.json` 文件「跨工具调用不可见」，经对照实验定位为**调度中枢 dispatcher 的正常取件消费**，而非写入失败或丢失（原文）：

```
# 同一次 Bash 调用内写入后立即
-rw-r--r-- 1 admin 197121   373 ... cmd-20261111-133549-878-A1.json
-rw-r--r-- 1 admin 197121 17724 ... cp_probe.txt        # .txt 对照文件
# sleep 3 后（同一调用内）
-rw-r--r-- 1 admin 197121 17724 ... cp_probe.txt        # .json 已被取走，.txt 保留
```

即 watcher 只消费 `outbox/*.json` 回执、不影响其它文件。取件去向（真跑 `find` 原文）：

```
F:/Game/aierdengfahuan/teamwork/command_center/dispatcher/receipts/cmd-20261111-133549-878-A1.json
F:/Game/aierdengfahuan/teamwork/command_center/dispatcher/receipts/cmd-20261111-133549-878-A1.json.20261111-140055-791
F:/Game/aierdengfahuan/teamwork/command_center/dispatcher/receipts/cmd-20261111-133549-878-A1.json.20261111-140220-321
F:/Game/aierdengfahuan/teamwork/command_center/dispatcher/receipts/cmd-20261111-133549-878-A1.json.20261111-140311-621
F:/Game/aierdengfahuan/teamwork/command_center/dispatcher/receipts/cmd-20261111-133549-878-A1.json.20261111-140723-469
F:/Game/aierdengfahuan/teamwork/command_center/dispatcher/receipts/cmd-20261111-133549-878-A1.json.20261111-140809-392
```

归档的正式回执已 `json.load` 读回并逐字段校验（原文）：

```
DISPATCHER_RECEIPT_VALID=YES
{"task_id": "cmd-20261111-133549-878-A1", "ai": 1, "status": "done", "result": "引用 DONE-R31.md 实际结论：R31 交付 impact_feedback.gd / hud.gd 运行时挂载 / verify_impact_feedback_v090.gd 三件；三段门禁 G1/G2A/G2B/G3 均 EXIT=0 且 SCRIPT_ERROR=0；验证 35 PASS / 0 FAIL / RESULT=ALL_MATCH；courtyard.tscn 节点数 41 与 uv 2/1/1 原样保持。"}
```

结论：回执**已成功投递并被调度中枢接收归档**；outbox 作为发件箱被取空属预期行为。对照用的 `cp_probe.txt` 已删除，outbox 干净。

未自行 `git`（总指挥收尾）；未删除 `.workbuddy` 目录。
