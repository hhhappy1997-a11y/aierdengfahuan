# DONE-R35C.md · R35C「收敛打击反馈层半透明大矩形」交付报告（Rank-1 引擎架构与渲染）

> 轮次：`R35C` ｜ 任务单 id：`cmd-20261112-151135-238-A1` ｜ 执行 AI：`1（Rank-1 引擎架构与渲染执行 AI）`
> 真源：`teamwork/Rank-1/调度任务单-latest.json`（`task` 全文 + 公共契约 + 目录所有权，HOST 裁决 A64 越界授权）。**以任务单为准**。
> 前序实证：`teamwork/Rank-4/DONE-R35B.md`（半透明矩形精确定位实证）。
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）

> **一句话结论**：A64 授权三块任务全部真跑完成 —— ① `impact_feedback.gd` 暖金闪光安全单元网格由「铺满中景 x≈388..1280 / y≈188..720 的半透明大矩形底板」收敛为「围绕命中锚点 (640,400) ±半径 120 的局部网格」，实际绘制单元覆盖面积 **314016 → 51144 px²（ratio 0.1629，减少 83.71%）**，绘制包围盒 **(520,280,240,232)** 不再覆盖中景大矩形 (388,188,892,532)；7 区 HUD 几何避让（避让区像素仍 0）/ 降级开关 / 闪光衰减单调 / 微震幅度上限 / hitstop 帧数上限 / 重复 connect 去重 / 无信号不自发光 全部保留，既有 `[PLACEHOLDER]` 数值语义逐字未动。② `verify_impact_feedback_v090.gd` 既有 **42 条断言逐字不删不放宽** + 新增 M/N 两类运行时断言，真跑 **47/47 PASS · RESULT=ALL_MATCH**。③ 三段门禁 G1/G2/G3 全 `EXIT=0`、全工程 `SCRIPT ERROR=0 / PARSE_ERROR=0`、A38 节点 **41** / uv **2/1/1** 不变。回执写入并确认中枢归档。**未完成 / 待裁决**：定稿录屏由总指挥本轮亲自重跑并目视（本轮不重复录屏），几何断言已证明大矩形不再绘制，但本交付不含新录屏 / 目视帧；`FLASH_ANCHOR` / `FLASH_RADIUS` 待试玩校准；真实逐次命中坐标需另授权。

---

## 1. 交付清单（实际落地文件）

| # | 文件 | 类型 | 本轮改动 |
|---|---|---|---|
| ① | `godot/scripts/render/impact_feedback.gd` | 修改（A64 特别授权，唯一生产脚本改动） | 文件头加 R35C 收敛说明；新增 `[PLACEHOLDER]` 常量 `FLASH_ANCHOR=(640,400)`（:103）/ `FLASH_RADIUS=120.0`（:109），逐条 rationale + 调参唯一入口；重写 `_rebuild_flash_rects()`（:377）把扫描线切分范围由整个 `SCREEN` 收敛为「命中锚点 ±半径」局部作用域。**既有 `[PLACEHOLDER]` 数值、HUD 避让几何、降级、衰减、微震/hitstop、connect 去重、无信号不自发光、FlashPainter._draw()、sample_flash() 逐字未动。** |
| ② | `godot/scripts/render/verify_impact_feedback_v090.gd` | 修改（授权） | 既有 A~L 共 **42 条断言逐字未动、不删不放宽**；新增 `MID_RECT` 对照常量、`_fullscreen_safe_area()` / `_union_bbox()` 几何对照 helper（写在既有验证脚本内，非独立探针脚本）；新增 **M 组 3 条**（闪光绘制包围盒不再覆盖中景大矩形 / 远锚点像素 0 / 局部网格围绕锚点）与 **N 组 2 条**（HUD 避让区像素仍为 0 / 收敛后几何避让仍 0）两类运行时断言，并打印改前 / 改后覆盖面积实证。`SUMMARY` total 42 → 47。 |
| ③ | `teamwork/Rank-1/DONE-R35C.md` | 新增 | 本交付报告。 |
| ④ | `teamwork/Rank-1/r35c_g1_import.log` / `r35c_g2_check_impact.log` / `r35c_g2_check_verify.log` / `r35c_verify.log` / `r35c_g3_quit.log` | 新增 | 三段门禁 + 回归真跑日志原文留档（授权目录内）。 |
| ⑤ | `teamwork/command_center/ai/1/outbox/cmd-20261112-151135-238-A1.json` | 新增 | 本轮回执（**teamwork/command_center/**，非工程根），写后经中枢归档至 `dispatcher/receipts/`。 |

---

## 2. 三块任务实现说明

### 2.1 任务① 收敛实现（定位 → 改法 → 面积证据）

**根因定位（与 R35B 精确定位一致）**：`_rebuild_flash_rects()` 原以 `var xs = [SCREEN.position.x, SCREEN.end.x]` / `ys = [SCREEN.position.y, SCREEN.end.y]` 等**整屏边界**做扫描线切分，把所有 HUD 避让矩形边界加入切分点后，生成的是「除 7 区 HUD 避让外的整屏安全单元网格」；`FlashPainter._draw()` 用 `draw_rect(r, Color(..., _flash_alpha))` 把这些单元全部填暖金。R35B 已实证：边界 388 / 188 恰是 `RECT_CODEX.grow(8)` 右边界 / `RECT_QUALITY.grow(8)` 下边界，f148 峰值 → f154 归零的 7 帧衰减对应 `FLASH_PEAK_ALPHA=0.42` / `FLASH_DECAY_PER_FRAME=0.06` —— 这块「整屏安全区减 HUD 后剩下的大矩形」就是弹反窗口帧（110/148/150）覆盖中景的半透明浅色底板。

**收敛改法（最小侵入）**：

- 新增 `[PLACEHOLDER]` 常量（`impact_feedback.gd:103`、`:109`）：
  - `FLASH_ANCHOR: Vector2 = Vector2(640.0, 400.0)` —— 既有战斗信号不带命中坐标（`_on_combat_signal()` 无参、`request_impact(intensity)` 无位置参数），故用固定锚点对齐全景战斗中心 / 角色区（与既有 G5 采样点同口径），**不改信号签名、不改其它文件**（`hud.gd` / `encounter_director.gd` 均只读）。
  - `FLASH_RADIUS: float = 120.0` —— 局部作用域半边长，边宽 2R=240，覆盖面积上限 (2R)²=57600 px²，远小于中景 892×532。
  - 两者均标 `[PLACEHOLDER]` + rationale + **调参唯一入口 = 本常量表（只改表不改算法）**，待人工试玩校准。
- 重写 `_rebuild_flash_rects()`（`:377`）：切分范围由 `SCREEN` 改为 `Rect2(FLASH_ANCHOR - Vector2(R,R), Vector2(2R,2R)).intersection(SCREEN)`；`xs/ys` 初值改为局部作用域边界；避让矩形边界改用 `r.intersection(local)`；`_sorted_unique()` 的 clamp lo/hi 改为局部边界。**「cell 与任一避让矩形交集面积为 0 才保留」的几何判定逻辑逐字保留** → 避让区像素恒 0。
- `FlashPainter._draw()` 与 `sample_flash()` 经 `get_flash_rects()` 自动只画 / 只判局部网格，**未改动**；峰值 alpha / 7 帧衰减 / 微震 / hitstop / 降级 / 去重 / 不自发光 全部不动。

**改前 / 改后面积证据**：详见 §5（真跑实测 314016 → 51144 px²）。

### 2.2 任务② 回归（42 条既有断言 + 两类新增运行时断言）

- **既有 42 条**（A~L）逐字未动、不删不放宽，真跑全部 `PASS=true`（含 G1 `flash_rects` 非空、G2 几何交集 0、G3 避让区采样 0、G5 角色区 (640,400) 闪光 >0、L7 降级下避让区像素 0、J1/J2 A38）。
- **新增两类运行时断言**（峰值态下取最强条件）：
  - **M 组「闪光绘制包围盒不再覆盖中景大矩形」**：M1 合并包围盒宽 / 高 ≤ 局部作用域直径 240、面积 55680 px² ≪ 中景 474544 px²；M2 中景大矩形内远离锚点的 5 个代表点 `sample_flash` 全 0（改前峰值态为 0.42）；M3 局部网格非空、锚点闪光 0.42>0、全部 `flash_rect` 落在局部作用域内。
  - **N 组「HUD 避让区像素仍为 0」**：N1 峰值态 7 区避让矩形 9 点密集采样（共 63 点）全 0；N2 收敛后每个 `flash_rect` 与每个 `avoid_rect` 几何交集面积仍 == 0。
- 结果：`SUMMARY pass=47 fail=0 total=47 ok=true`、`RESULT=ALL_MATCH`、`VERIFY_EXIT=0`。

### 2.3 任务③ 门禁（三段 + G3 + A38）

- 三段门禁按公共契约顺序真跑：`--headless --import` → `--check-only --script`（两脚本）/ `--headless --script <verify>` → `--headless --quit`，五段全 `EXIT=0`。
- 全工程 G3 grep：5 段日志 `SCRIPT_ERROR=0`、`PARSE_ERROR=0`；G3 退出日志非空，真实加载全工程（含 `[R31][HUD] 运行时挂载 ImpactFeedbackLayer → Courtyard`、`[R21_QUALITY] courtyard.tscn ... node_count=41`）。
- A38：`courtyard.tscn` 只读核对 `node_count=41`、`uv1_scale = Vector3(1,1,1)` ×2 + `Vector3(2,2,1)` ×1（uv **2/1/1**），J1/J2 真跑断言亦 PASS，本轮零改动该文件。

---

## 3. 真跑输出原文

命令前缀统一 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；日志留档 `teamwork/Rank-1/r35c_*.log`。

### 3.1 三段门禁 EXIT + 全工程 SCRIPT ERROR / PARSE ERROR grep

```
=== G1 --headless --import ===
G1_IMPORT_EXIT=0
=== G2a --check-only --script impact_feedback.gd ===
G2_IMPACT_CHECK_EXIT=0
=== G2b --check-only --script verify_impact_feedback_v090.gd ===
G2_VERIFY_CHECK_EXIT=0
=== G2c VERIFY --headless --script (回归) ===
VERIFY_EXIT=0
=== G3 --headless --quit ===
G3_QUIT_EXIT=0
=== SCRIPT ERROR / PARSE ERROR grep (5 段日志) ===
r35c_g1_import.log : SCRIPT_ERROR=0 PARSE_ERROR=0
r35c_g2_check_impact.log : SCRIPT_ERROR=0 PARSE_ERROR=0
r35c_g2_check_verify.log : SCRIPT_ERROR=0 PARSE_ERROR=0
r35c_verify.log : SCRIPT_ERROR=0 PARSE_ERROR=0
r35c_g3_quit.log : SCRIPT_ERROR=0 PARSE_ERROR=0
```

### 3.2 `verify_impact_feedback_v090.gd` 回归真跑输出全文

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[V090] ==== verify_impact_feedback_v090 真跑开始 | cmd-20261111-133549-878-A1 [ROUND=R31] Rank-1 ====
[V090] LOAD feedback class=GDScript resource_path=res://scripts/render/impact_feedback.gd CACHE_MODE_IGNORE=true
[V090] A1 encounter_director.gd 既有信号含 encounter_finished / grace_rested PASS=true | script_signals=["encounter_finished", "grace_rested", "player_hit_landed"]
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
[V090] G1 flash_rects 非空（程序化 _draw 有可画安全区） PASS=true | flash_rects=3 avoid_rects=7
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
[V090] L1 真实导演层声明 player_hit_landed(damage:int) 且 _try_player_hit 内 emit PASS=true | script_signals=["encounter_finished", "grace_rested", "player_hit_landed"] emit_in_source=true
[V090] L2 反馈层 SIG_PLAYER_HIT_LANDED 常量与真实信号名逐字一致 PASS=true | sig_const=player_hit_landed
[V090] L3 bind_director 已按实订阅 player_hit_landed（连接数 1） PASS=true | connections=1
[V090] L4 真实导演层 emit 一次命中后闪光 > 0（暖金闪光/微震/hitstop 自动触发） PASS=true | flash=0.4200 impact=1 shake=6.0 hitstop=2
[V090] L5 连续 5 次命中：flash/shake/hitstop 恒在 [0,上限]、无 NaN、不叠加异常 PASS=true | impact=6 peak_cap=0.4200 shake_cap=6.00 hitstop_cap=4
[V090] L6 重复 bind_director 后仍 1 条连接、单次 emit 仅 +1 impact（不重复触发） PASS=true | connections=1 impact=7
[V090] L7 降级下真实命中仍闪光>0、shake/hitstop=0、HUD 避让区像素仍 0 PASS=true | flash=0.4200 shake=0.0 hitstop=0 max_avoid_pixel=0.0000
[V090] [R35C] FLASH_COVERAGE_BEFORE=314016.0 px2 AFTER=51144.0 px2 ratio=0.1629
[V090] [R35C] FLASH_BBOX=(520.0,280.0,240.0,232.0) MID_RECT=(388,188,892,532) radius=120.0 anchor=(640.0,400.0)
[V090] M1 [R35C/A64] 闪光绘制包围盒不再覆盖中景大矩形（bbox<=局部直径、面积<<892x532） PASS=true | bbox_size=(240.0,232.0) diameter=240.0 bbox_area=55680.0 mid_area=474544.0
[V090] M2 [R35C/A64] 中景大矩形远锚点 5 处采样 flash 像素全 0（改前峰值态为 0.42） PASS=true | worst_mid_pixel=0.0000 points=5
[V090] M3 [R35C/A64] 局部网格非空、锚点闪光>0、所有 flash_rect 落在局部作用域内 PASS=true | rects=3 anchor=(640.0,400.0) anchor_pixel=0.4200 all_local=true
[V090] N1 [R35C/A64] 峰值态 7 区 HUD 避让矩形 9 点密集采样 flash 像素全 0 PASS=true | samples=63 worst_pixel=0.0000 avoid_rects=7
[V090] N2 [R35C/A64] 收敛后每个 flash_rect 与每个 avoid_rect 几何交集面积仍 == 0 PASS=true | worst_overlap=0.0000 px2 flash_rects=3
[V090] ---- 回读汇总 ----
[V090] SUMMARY pass=47 fail=0 total=47 ok=true
[V090] RESULT=ALL_MATCH
[V090] ==== verify_impact_feedback_v090 真跑结束 ====
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
       [0] _deferred_bind (res://scripts/rpg/points_commit_orchestrator.gd:178)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

> 既有 WARNING 如实登记（非本轮引入、非 SCRIPT ERROR、不影响 `EXIT=0`）：`--script` 工具模式下 `SaveSystem` 跳过自动读回、`ChunkManager` 未找到 ChunkRoot、`PointsCommitOrchestrator` autoload（任务单已提示验证进程会加载它）HUD 未就绪绑定降级、`2 ObjectDB instances were leaked at exit`。G3 `--headless --quit` 日志尾部同样有 `2 ObjectDB instances were leaked at exit`。均与 R35B / R31 既有口径一致。

### 3.3 A38 courtyard.tscn 只读核对

```
=== A38 courtyard.tscn 只读核对 ===
node_count=41
      2 uv1_scale = Vector3(1, 1, 1)
      1 uv1_scale = Vector3(2, 2, 1)
```

节点 **41** / uv **2/1/1**（`Vector3(2,2,1)` ×1 + `Vector3(1,1,1)` ×2）不变，本轮零改动 `courtyard.tscn`。

### 3.4 两段门禁日志非空佐证（不空跑冒充）

- `r35c_g1_import.log`：含 `[ DONE ] first_scan_filesystem` / `[ DONE ] update_scripts_classes` / `[ DONE ] loading_editor_layout`，`G1_IMPORT_EXIT=0`。
- `r35c_g3_quit.log`：含全工程加载输出 `[R31][HUD] 运行时挂载 ImpactFeedbackLayer → Courtyard`、`[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41`、`[R35][HUD] A54 唯一 ParryService 已复用...`，`G3_QUIT_EXIT=0`。

---

## 4. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 收敛实现落地：`impact_feedback.gd` 由全屏大矩形底板改为围绕命中锚点的局部网格，新增 `[PLACEHOLDER]` `FLASH_ANCHOR`/`FLASH_RADIUS` + rationale + 调参唯一入口，改前/改后覆盖面积实证齐备；② A64 全部保留项真跑保持：7 区 HUD 几何避让（避让区像素 0，N1 63 点全 0）/ 降级开关 / 闪光衰减单调（C2 seq 单调不增）/ 微震幅度上限（D1 ≤6）/ hitstop 帧数上限（E1/E3 ≤4）/ 重复 connect 去重（H1/L6 连接数 1）/ 无信号不自发光（B1/B2）；③ 既有 `[PLACEHOLDER]` 数值语义逐字未动（峰值 0.42 / 衰减 0.06 / 微震 6 / hitstop 4 / AVOID_MARGIN 8 等常量未改）；④ 既有 42 条断言不删不放宽全 PASS + 新增 M/N 两类运行时断言，`SUMMARY pass=47 fail=0 total=47` / `RESULT=ALL_MATCH`；⑤ 三段门禁全 `EXIT=0`、全工程 `SCRIPT ERROR=0` / `PARSE_ERROR=0`；⑥ A38 节点 41 / uv `2/1/1` 不变；⑦ 只写授权文件、其余只读；⑧ 回执写入并确认中枢归档（§8）。 |
| **失败 / 未达** | ① **本交付不含新录屏 / 目视帧**：公共契约规定「定稿录屏由总指挥本轮亲自重跑并目视，你不重复录屏」，故弹反窗口帧（110/148/150）的实际收敛画面待总指挥目视确认 —— 运行时几何断言（M1/M2/N1）已证明大矩形不再绘制，但未出图，不冒称目视通过；② **HD-2D 全绿未达**（沿用 R35B）：仍是 `CanvasItem._draw()` 2D 程序化近似，无真 DoF / 真体积光 / SSR / `Environment.glow` / Forward+，不包装成全绿；③ 「围绕命中点」当前用**固定常量锚点**（既有信号不带坐标），非真实逐次命中坐标（见 §7 待裁决）。 |
| **需用户确认 / 待裁决** | 见 §7。 |

---

## 5. 改前 / 改后覆盖面积实证（真跑实测，任务①硬要求）

两种口径均由 `verify_impact_feedback_v090.gd` 真跑输出（`[V090] [R35C] ...` 行），非估算：**改前**由验证脚本内新增的 `_fullscreen_safe_area(avoid)` 按 R31 原「全屏扫描线安全网格」算法几何重算（同一套 7 区避让矩形、同一套 cell 判定，纯几何计算、非独立探针脚本）；**改后**由收敛后 `get_flash_rects()` 的实际绘制单元逐项累加。二者同口径可比。

| 口径 | 改前（R31 全屏底板） | 改后（R35C 局部网格） | 变化 |
|---|---|---|---|
| **A. 实际绘制单元面积和** | `314016.0 px²` | `51144.0 px²` | `ratio=0.1629`，**减少 83.71%** |
| **B. 绘制包围盒 bbox** | 整屏级，覆盖中景大矩形 `Rect2(388,188,892,532)` = `474544 px²` | `(520,280,240,232)` = `55680 px²`，完全落在局部作用域 `(520,280,240,240)` 内 | 不再覆盖 x≈388..1280 / y≈188..720 中景大矩形 |
| **C. 网格单元数** | 全屏扫描线多单元 | `flash_rects=3` | 局部网格 |

**像素级证据（真跑断言）**：

- 中景大矩形内远离锚点的 5 个代表点 `(1000,600)` / `(1200,620)` / `(1250,300)` / `(450,600)` / `(900,300)` —— 改前均落在全屏安全网格内（峰值态 `sample_flash=0.42`），改后 `worst_mid_pixel=0.0000`（M2 PASS），直接证明中景不再被半透明覆盖。
- 锚点 `(640,400)`（角色区）改后 `sample_flash=0.4200`（G5 / M3 PASS），局部闪光仍可见、非空网格。
- 7 区 HUD 避让矩形 9 点密集采样共 `samples=63`，`worst_pixel=0.0000`（N1 PASS）；`flash_rect` 与 `avoid_rect` `worst_overlap=0.0000 px²`（G2 / N2 PASS），A64「避让区像素仍为 0」保持。
- 包围盒 `bbox_size=(240.0,232.0)` ≤ 局部直径 `diameter=240.0`、`bbox_area=55680.0` ≪ `mid_area=474544.0`（M1 PASS）。

---

## 6. 未完成项（如实登记，不冒称）

1. **定稿录屏 / 目视帧**：按公共契约由总指挥本轮亲自重跑并目视，本轮不重复录屏；本交付以运行时几何断言证明大矩形不再绘制，不含新 MP4 / 抽帧 / 目视结论，弹反窗口帧实际观感待总指挥确认。
2. **真实逐次命中坐标**：当前 `FLASH_ANCHOR` 为固定常量（既有 `move_landed` / `player_hit_landed` 等信号不带坐标），「围绕命中点」为围绕战斗中心锚点的局部网格；若需每次命中都用真实命中坐标，需改信号签名 / 集成层传参（涉只读文件，超本轮授权，见 §7）。
3. **HD-2D 全绿**：差距清单（真 DoF / 真 `volumetric_fog` / SSR / `Environment.glow` / Forward+ 后端）沿用 R35B 保持未达，本轮未新增真 3D 光效、未切后端。
4. **A63 Rank-4 口径同步**：`verify_fx_mobile.gd` 的 mobile `visible` 断言同步属 Rank-4 本轮授权（A63），不在 Rank-1 写入范围，未改。

---

## 7. 待裁决项（只登记、不擅改）

1. **定稿录屏目视结论**：请总指挥按公共契约亲自重跑并目视弹反窗口帧（110/148/150），确认大矩形消失、HUD 文字无遮挡；本轮几何断言已就绪。
2. **`[PLACEHOLDER]` 试玩校准**：`FLASH_ANCHOR=(640,400)` / `FLASH_RADIUS=120.0` 待人工试玩校准；调参唯一入口 = `impact_feedback.gd` 常量表（只改表不改算法）。
3. **真实逐次命中坐标**：如要求「围绕每次真实命中点」而非固定锚点，请裁决是否授权改 `encounter_director.gd` 命中信号带坐标 / `hud.gd` 传参 / 本层 `request_impact` 增加可选坐标参数（均涉只读或其它文件，本轮未擅改）。
4. **R19 `verify_fx_mobile.gd` 口径**：R35B §7.2 登记的 mobile `visible` 断言同步，由 Rank-4 按 A63 处理，请总指挥复核（本轮未改）。
5. **HD-2D 全绿差距清单**：沿用既有「未达」口径，请裁决后续路线。

---

## 8. 回执与中枢归档（写后实测，如实登记）

- 回执写入授权路径（**`teamwork/command_center/`**，非工程根）：`teamwork/command_center/ai/1/outbox/cmd-20261112-151135-238-A1.json`，四字段 `{"task_id":"cmd-20261112-151135-238-A1","ai":1,"status":"done","result":"...引用 DONE-R35C.md 实际结论..."}`。
- **中枢归档回读确认（写后实测）**：
  - `ai/1/outbox/` 已清空（`total 0`，回执被中枢移走 → `dispatcher/receipts/`，属中枢正常处理，不重放、不伪造）。
  - 归档副本 `dispatcher/receipts/cmd-20261112-151135-238-A1.json` 存在（**1270 字节**），回读 **VALID_JSON**，四字段齐全：`task_id=cmd-20261112-151135-238-A1 / ai=1 / status=done / result_len=689`。
  - `ai/1/status.json`：`{"ai":1,"state":"idle","current_task":"","completed":65,"last_seen":"2026-11-12 15:24:33"}`（`current_task` 清空、state=idle）。
  - `dispatcher/dispatcher.log` 尾部原文：`[2026-11-12 15:24:33] ← 1 号 AI 回执 <cmd-20261112-151135-238-A1> 完成：R35C 完成（详见 teamwork/Rank-1/DONE-R35C.md 实际结论）：A64 授权收敛 impac...`，确认 id 与派单一致。

---

## 9. 硬约束遵守声明

- **唯一写入方**：只写 `godot/scripts/render/impact_feedback.gd`（A64 特别授权）、`godot/scripts/render/verify_impact_feedback_v090.gd`、`teamwork/Rank-1/`（DONE + 门禁日志）、回执。**未改** `hd2d_fx.gd` / `hud.gd` / `presentation.gd` / `encounter_director.gd` / `wave_trial_director.gd` / `points_commit_orchestrator.gd` / `project.godot` / `courtyard.tscn`（A38 节点 41 / uv 2/1/1）/ 既有 `.tres` / 素材 / 其它 Rank 产出。
- **不改 `[PLACEHOLDER]` 数值语义**：既有全部常量值逐字未动；仅新增 `FLASH_ANCHOR` / `FLASH_RADIUS` 两个 `[PLACEHOLDER]` 字段（带 rationale + 调参入口）。
- **零付费、零外部依赖、不启 GPU job、不列任何付费项**：仅本地 Godot 4.7.2，未录屏 / 未启 Movie Maker / 未调 ffmpeg。
- **SceneTree / `--script` 纪律**：`extends SceneTree` 验证脚本按既有夹具 `add_child` 后显式 `call("_ready")` 再 `set_process(false)`；取 `root` 相对装配，未用 `get_tree()`、未用 `/root/...` 绝对路径；资源回读 `ResourceLoader.load(..., CACHE_MODE_IGNORE)`；`project.godot` 的 `PointsCommitOrchestrator` autoload 在 verify / G3 进程被加载，其降级 WARNING 已如实登记（§3.2）。
- **默认不刺探**：未主动扫目录做进度巡检、未新建只读探针 / 巡检脚本（`_fullscreen_safe_area` / `_union_bbox` 为既有验证脚本内的几何对照 helper）；所有读取均针对任务单指定的契约 / 目标文件 / 门禁日志与归档确认所必需的路径，用跑起来的真跑输出判断进度。
- **不伪造产物、不谎报成功**：三段门禁日志非空（§3.4），改前/改后面积、47 条断言、SCRIPT ERROR 数字均为真跑输出原文；既有 WARNING 如实登记；未冒称目视通过、未冒称 HD-2D 全绿、未冒称真实逐次命中坐标。
- **不自行 git**（总指挥收尾）；**未删除 `.workbuddy` 目录**。
