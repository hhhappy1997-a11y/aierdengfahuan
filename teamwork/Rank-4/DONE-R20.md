# DONE-R20.md · 移动档画面直接验收 + 光效精修

> 轮次：**R20**｜派单：`cmd-20261109-110237-810-A4`｜命令：`[ROUND=R20]`｜工位：**Rank-4 美术管线与工具链**｜日期：2026-11-09
> 一句话结论：**首次真实抓到 mobile 档（四项全关）画面**（R19 承认其 `r19_mobile*.png` 实为 desktop 档），并量化了 desktop/mobile 差距；`verify_fx_mobile.gd` 真跑 **47 PASS / fail=0**，三段门禁 + 抓帧共 8 份日志 `SCRIPT ERROR|Parse Error|ERROR` **全 0 条**。**画面未达 HD-2D 全绿，如实写未达，不冒充。**
> 必读（已读）：`Rank-4/调度任务单-latest.json`、`command_center/ai/4/inbox/task_cmd-20261109-110237-810-A4.json`、`DONE-R19.md`、`CAPTURE-REPORT.md`、`hd2d_fx.gd` / `hd2d_fx.tscn` / `verify_fx_mobile.gd`、`courtyard.tscn` / `project.godot` / `fx_profile_controller.gd` / `HD2D-FX-PLAN.md`（均只读核对，未改禁改件）。

---

## 0. 实际结论（先说结果）

1. **补上 R19 缺口**：R19 的 4 帧是 `courtyard.tscn` 中 `HD2DFX` 默认 desktop（四项全开）画面。根因是 `HD2DFX` 根挂 Rank-1 独占 `fx_profile_controller.gd`，其 `_ready()` 依 `fx_profile_source`（固定指向 desktop preset 640×360）判档 **desktop** 并把 4 个 FX 子节点切回 desktop。
2. **本轮解法（只在 Rank-4 可写文件内）**：`hd2d_fx.gd` 新增「运行期强制档位覆盖」——抓帧时设 `AIERDENG_FX_PROFILE=mobile`，4 个 FX 节点 `_ready()` 用 `call_deferred` 排在 controller 之后落到 mobile，并锁定档位忽略后续 `set_fx_profile("desktop")`；默认不设该变量 → desktop 四项全开零回退。抓帧 stdout 有完整证据链（§2.3）。
3. **真实画面**：`r20_mobile*.png`（四项全关）与 `r20_mobile_lowres*.png`（四项全关 + 低分辨率渲染）均为 Movie Maker 直接产出，**非 desktop 帧改名**；画面主体（蓝天 / 暖金横砖 / HUD「赐福 · 宁姆格福」/ 像素骑士）清晰可读，不糊、不纯黑、HUD 无光尘遮挡。
4. **47 PASS 回归 + 三段门禁**：全绿、ERROR 0 条（§2.2）。
5. **如实边界**：`CAPTURE-REPORT.md` 已追加「R20 移动档验收」段落并写明 **未达 HD-2D 全绿**；R19 与 R20 的 desktop 帧因其它 Rank 并发画质改动不可直接逐像素对比；`--resolution` 未改变 Movie Maker 录制尺寸（仍 1280×720）。详见 §3。

---

## 1. 实际交付清单

### 1.1 改动的工程源件（2 个，均在派单可写范围）

| # | 文件 | 字节 | sha256（前缀） | 改动内容 |
|---|---|---|---|---|
| 1 | `godot/scripts/hd2d_fx.gd` | 19886 | `6509f45c6f530aec…` | ① 运行期强制档位覆盖（`ENV_FORCE_PROFILE` / `_force_profile` / `_read_forced_profile()` / `_apply_forced_mobile()` / `set_fx_profile` 的 mobile 锁定）；② `_apply_hud_avoid_meta()` 从 `hd2d_fx.tscn` metadata 读 HUD 避让矩形、脚本常量兜底；③ `_is_hud_avoid()` 纳入光尘半径 margin（只向外扩、不缩小 x<730/y<220 矩形）；④ 按 `hd2d_placeholder.gd:51-82` 权威阵列把 `ENTITY_ROWS` 校正为 32 行 × 32 字符（写入时曾误成 31 行 / 一行 36 字符，已用 Python + 权威副本核对修正，`range(32)` 不再越界）；⑤ 全部原有四项 `_draw()` 绘制逻辑、参数、冻结口径**逐字保留** |
| 2 | `godot/scenes/hd2d_fx.tscn` | 1031 | `9a79ccbfde13df13…` | 4 个 FX 节点各补 `fx_profile = "desktop"`（desktop 四项全开基线显式化）+ `metadata/hud_avoid_screen_w = 730.0` / `metadata/hud_avoid_screen_h = 220.0`（HUD 避让矩形场景级可配置，供 `_apply_hud_avoid_meta()` 运行期读取）。**节点数仍为 5**（CanvasLayer 根 + 4×Node2D），未增删节点，47 PASS 的 ③⑤ 结构检查不受影响 |

> `godot/scripts/verify_fx_mobile.gd` **本轮零改动**：12393 字节、sha256 `b5c0dda33edd895a…`，与 `DONE-R19.md §2.6` 记录的 `b5c0dda33edd895ae1ba5ec7aca02e2587f2adbc11e5d7e9365e3b256bed58b1` 一致 → 47 PASS 是既有脚本**原样真跑**，不是改脚本凑出来的。其 stdout 标签仍为 `[R19]`（沿用既有脚本），如实登记、未伪装成 R20 标签。

### 1.2 抓帧产物（`capture/` 下，全部真实 Movie Maker 输出）

| 序列 | 文件 | 尺寸 | 字节/帧 | 档位 |
|---|---|---|---|---|
| desktop 对照 | `r20_desktop00000000.png` ~ `00000003.png` | 1280×720 | 216164 / 216121 / 216113 / 216130（4 帧各异） | desktop 四项全开 |
| **mobile 主证据** | `r20_mobile00000000.png` ~ `00000003.png` | 1280×720 | 201529（4 帧 sha256 全同 `94264be8cc05…`） | **mobile 四项全关** |
| **mobile 低分辨率** | `r20_mobile_lowres00000000.png` ~ `00000003.png` | 1280×720 | 370112（4 帧 sha256 全同 `72b10a9973fa…`） | **mobile 四项全关 + 低分辨率渲染** |
| 首次低分辨率实验（如实登记、不删除、不冒充） | `r20_lowres00000000.png` ~ `00000003.png` | 1280×720 | 358167（4 帧全同） | mobile 四项全关（同命令同参数，仅 `--write-movie` 前缀不同；因早期工程态构图不同，字节与正式帧不同） |
| Movie Maker 自动音频轨 | `r20_desktop.wav` / `r20_mobile.wav` / `r20_mobile_lowres.wav` / `r20_lowres.wav` | — | 51244 各 | 引擎自动产物，非手写 |

### 1.3 真跑 stdout 日志 / 分析产物（`capture/` 下）

`r20_gate_import.log`、`r20_verify_run.log`、`r20_gate_checkonly.log`、`r20_gate_quit.log`（三段门禁 + RUN）、`r20_capture_desktop.log`、`r20_capture_mobile.log`、`r20_capture_lowres.log`、`r20_capture_mobile_lowres.log`（抓帧）、`r20_pixel_diff.txt`（PIL 量化像素/可读性对比最终结果）、`r20_pre_sha256.txt` / `r20_post_sha256.txt` / `r20_final_sha256.txt`（零写入 / 并发态留证）。共 **39 个 `r20_*` 文件**。

### 1.4 报告与回执

| 文件 | 说明 |
|---|---|
| `capture/CAPTURE-REPORT.md` | **独占追加**「R20 移动档验收」段落（desktop/mobile 实际差距 + 未达 HD-2D 全绿） |
| `teamwork/Rank-4/DONE-R20.md` | 本文件 |
| `teamwork/command_center/ai/4/outbox/cmd-20261109-110237-810-A4.json` | 回执 JSON（**精确路径在 `teamwork/command_center/` 下**；已确认工程根 `F:/Game/aierdengfahuan/command_center` 不存在，未写错位置） |

> **回执落地核验（实际 stdout）**：回执按派单写入 outbox 后被中枢**实时消费**并从 outbox 移走（与 `DONE-R19.md §2.7` 一致），归档于 `teamwork/command_center/dispatcher/receipts/cmd-20261109-110237-810-A4.json`（2530 字节）。归档件解析实测：`JSON_OK keys=['ai','result','status','task_id']`、`task_id=cmd-20261109-110237-810-A4`、`ai=4`、`status=done`、`result 长度=1558`；引用 `DONE-R20.md=True`，含 `pass=47` / `未达 HD-2D 全绿` / `r20_mobile` / `SCRIPT ERROR` / `0.010299` / `并发` 均为 True；`dispatcher/ledger.jsonl` 本轮记录 `status=done`、`finished_at=2026-11-09 11:23:11`。归档路径在 `teamwork/command_center/` 下、工程根 `command_center` 不存在 → **回执写对路径，未写错位置**。

### 1.5 未写（零改动）与目录所有权

- **Rank-1 独占**：`godot/scenes/courtyard.tscn`（PRE/POST 内容 sha256 一致 `0d429ab7…` → `b8bf7aae…` 见 §3 并发说明）、`quality_settings`、`godot/scripts/fx_profile_controller.gd`、`quality_preset_*.tres` / `render_profiles.tres` — 本轮一个字节未写。
- **Rank-3 独占**：`godot/project.godot`、`godot/scripts/hud.gd` — 未写。
- **Rank-2 独占**：`godot/scripts/verify_frame_data.gd` — 未写。
- 未新建任何只读探针 / 巡检脚本（像素对比用 `python - <<'PY'` 内联执行、未落盘脚本文件）；未写其它工位 / 总线 / 总纲 / 契约 / 任务书；未自行 `git commit` / `git push`；零付费 / 零外部素材 / 零插件 / 零云服务；中文 UTF-8；Godot 4.7.2 合法语法。

---

## 2. 真跑输出结论

### 2.1 命令（Windows Git Bash，引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`）

```text
# 三段门禁 + RUN（最终工程态重跑一遍，见 §3 并发说明）
"$GODOT" --headless --path godot --import                                            # G1
"$GODOT" --headless --path godot --script res://scripts/verify_fx_mobile.gd          # RUN 真跑
"$GODOT" --headless --path godot --check-only --script res://scripts/verify_fx_mobile.gd  # G2
"$GODOT" --headless --path godot --quit                                              # G3
# 抓帧（独立 CLI，脚本内不嵌套第二个引擎进程）
"$GODOT" --path godot --write-movie capture/r20_desktop.png --fixed-fps 30 --quit-after 4 res://scenes/courtyard.tscn                 # A desktop
AIERDENG_FX_PROFILE=mobile "$GODOT" --path godot --write-movie capture/r20_mobile.png --fixed-fps 30 --quit-after 4 res://scenes/courtyard.tscn   # B mobile
AIERDENG_FX_PROFILE=mobile "$GODOT" --path godot --resolution 640x360 --write-movie capture/r20_mobile_lowres.png --fixed-fps 30 --quit-after 4 res://scenes/courtyard.tscn  # D mobile 低分辨率
```

### 2.2 三段门禁 + 47 PASS 回归（最终态，实际 stdout）

```text
G1_EXIT=0   RUN_EXIT=0   G2_EXIT=0   G3_EXIT=0
==== [R19] SUMMARY pass=47 fail=0 total=47 ====
==== [R19] RESULT=PASS ====
```

RUN 日志同时打印 4 行 `[R20][FX*] 默认档位=desktop（未请求覆盖，desktop 四项全开零回退）` → 默认路径（门禁 / verify 真跑 / 普通运行）**不激活**强制 mobile，desktop 四项全开零回退，47 PASS 不受影响。

**8 份 `r20_*.log` 的 `grep -cE "SCRIPT ERROR|Parse Error|ERROR"` 全部 0 条**：

```text
r20_capture_desktop.log: 0 条      r20_capture_lowres.log: 0 条
r20_capture_mobile.log: 0 条      r20_capture_mobile_lowres.log: 0 条
r20_gate_checkonly.log: 0 条      r20_gate_import.log: 0 条
r20_gate_quit.log: 0 条           r20_verify_run.log: 0 条
```

### 2.3 抓帧 EXIT 与「真实 mobile 档」证据链（`r20_capture_mobile.log` 实际 stdout 摘录）

```text
A_EXIT=0   B_EXIT=0   D_EXIT=0   （首次 C 实验 EXIT=0）
Movie Maker mode enabled, recording movie in 1280×720 @ 30 FPS...
[R20][FXReflection] 强制档位=mobile（deferred 覆盖 controller 的 desktop）env=AIERDENG_FX_PROFILE
[R20][FXGodRays]    强制档位=mobile（deferred 覆盖 controller 的 desktop）env=AIERDENG_FX_PROFILE
[R20][FXMotes]      强制档位=mobile（deferred 覆盖 controller 的 desktop）env=AIERDENG_FX_PROFILE
[R20][FXBloom]      强制档位=mobile（deferred 覆盖 controller 的 desktop）env=AIERDENG_FX_PROFILE
[R19_CTRL] 判档 active>=desktop=true -> fx_profile=desktop
[R20][FXReflection] 忽略外部 set_fx_profile(desktop)：强制 mobile 锁定生效   （×4）
[R19_CTRL] switch_profile(desktop) set_fx_profile 命中 4/4 子节点 | fx_profile_active=desktop
[R20_CTRL] set_quality(low) / re_evaluate preset=low prev_fx=desktop -> fx=mobile
[R19_CTRL] switch_profile(mobile) set_fx_profile 命中 4/4 子节点
[R20_CTRL] set_quality(high) / re_evaluate preset=high prev_fx=mobile -> fx=desktop
[R20][FXReflection] 忽略外部 set_fx_profile(desktop)：强制 mobile 锁定生效   （×4，第二次拦截）
[R20][FXReflection] deferred 落地 set_fx_profile(mobile) | visible=false _all_on=false fx_profile=mobile 四门=[false false false false]   （×4）
4 frames at 30 FPS (movie length: 00:00:00:04)
```

> 最终态下并发的 `QualitySettings` 会 `low→high` 两次重判档，my 锁定逐一拦截两次 `desktop` 请求、允许 `mobile` 请求，最后 deferred 仍落地 **四项全关**。证明机制在 Rank-1 升级后的 controller 下依然稳固。

### 2.4 像素 / 可读性对比（`capture/r20_pixel_diff.txt`，PIL 真算，非臆造）

| 对比 | MAD(R,G,B) | diff_ratio(\|L\|>16) |
|---|---|---|
| `r19_desktop vs r20_desktop` | (30.716, 31.377, 28.474) | 0.290605 —— **来自并发画质改动，非本轮回退**（§3） |
| **`r20_desktop vs r20_mobile`（同态，有效验收）** | (0.617, 0.435, 0.668) | **0.010299** |
| `r20_desktop vs r20_mobile_lowres` | (16.812, 14.353, 10.026) | 0.270931 |
| `r20_mobile vs r20_mobile_lowres` | (16.599, 14.319, 9.668) | 0.267958 —— 低分辨率帧确实不同，非同帧复制 |

- 差异 bbox=(24, 0, 637, 361)，8×6 网格差异集中在天空中部与角色脚下（四项光效所在区域）。
- 天空亮点计数：`r20_desktop=180` → **`r20_mobile=0` / `r20_mobile_lowres=0`**（`r19_desktop=16` 为旧构图，不可直接比）。
- **HUD 面板区 (0,0,400,150) 差异仅 56 像素 / 0.000933** → 移动档 HUD 无光尘遮挡。
- 可读性：全部 `non_black=1.0`（不纯黑）；sharpness desktop 10.983 / mobile 11.108 / lowres 6.921（均不糊，关光效后更锐利）。
- **帧间一致性**：`r20_desktop` 4 帧 sha256 各异（光尘逐帧动画在跑 → desktop 四项全开）；**`r20_mobile` / `r20_mobile_lowres` 4 帧 sha256 完全相同**（FX 层零绘制 → 静态）→ 反证不是 desktop 帧改名冒充。

### 2.5 desktop / mobile 实际差距（ViewImage 真看）

- **desktop 档**：天空散布零星暖金/冷白光尘点、地平线附近有明显暖金 bloom 亮斑与向上锥形体积光、角色脚下有倒影亮线 → 四项全开。
- **mobile 档**：上述四项全部消失；蓝天、暖金横砖地面（砖缝锐利）、左上深蓝 HUD 面板与「赐福 · 宁姆格福」文字、中央像素骑士剪影**全部清晰可读**；**无黑屏、无纯色空白、无大面积泛白、无糊屏、HUD 无点状遮挡**。
- **mobile 低分辨率档**：砖块像素网格明显变粗，主体元素仍完整可读，无黑屏 / 纯色 / 严重模糊 / 错位裁剪。

---

## 3. 未完成项与阻塞（如实登记，不冒充全绿）

| # | 项 | 性质 / 归属 |
|---|---|---|
| 1 | **未达 HD-2D 全绿** | 本轮只达成「真实抓到 mobile 四项全关画面且主体可读」。四项光效是 2D 程序化 `draw_*` 几何/加色近似，**非**真正 HDR bloom / 3D 体积光 / SSR（`gl_compatibility` 后端不支持）；倒影仍只有细亮线 + 少量深色块、非成片镜像；体积光/bloom 低对比叠加可见度弱；地面为程序化横砖、构图仍是占位阶段；ComfyUI 正式 spritesheet 未接入。`CAPTURE-REPORT.md` 已写明「未达 HD-2D 全绿」 |
| 2 | **`--resolution 640x360` 未改变 Movie Maker 录制尺寸** | 4 组 PNG 仍全部 1280×720（由 `project.godot` 的 `window_width_override/window_height_override` 决定）。「低分辨率」只体现在内部 SubViewport 降采样 + 整数放大后的像素网格（sharpness 6.921、`r20_mobile vs r20_mobile_lowres` 差异 26.8%）。**未产出真正的 640×360 / 480×270 PNG 文件**；若要真正低分辨率输出 PNG 须改 `project.godot`（Rank-3 独占），超本轮范围，如实登记 |
| 3 | **R19 与 R20 desktop 帧不可直接逐像素对比** | `r19_desktop vs r20_desktop` diff_ratio=0.2906，根因是本轮真跑期间其它 Rank 并发落盘 R20 画质管线（见 #4）改变了构图/缩放基准，**不是本轮 desktop 光效回退**；有效验收改用同态 `r20_desktop vs r20_mobile`。`r20_desktop` 天空亮点 180 > R19 的 16，反证 desktop 光效未回退 |
| 4 | **其它 Rank 并发写入（非本轮所为，如实登记）** | PRE/POST 校发现 `project.godot`（新增 `SaveDeltaWriter` autoload，注释 `cmd-20261109-110237-805-A3`）与 `fx_profile_controller.gd`（R20 扩展 `re_evaluate` / `register_quality_provider`，注释 `cmd-20261109-110237-775-A1`）sha256 变化；`courtyard.tscn` PRE/POST **内容一致**（`0d429ab7…`，最终态被并发重写同内容后为 `b8bf7aae…`，mtime 变、内容未变）。本轮**一个字节未写**这些文件。因工程态已变，已在最终态**重跑全部门禁/回归/抓帧并刷新正式产物**（§2.2/2.3 为最终态结果），确认强制档位机制在升级后的 controller + `QualitySettings` 下仍生效 |
| 5 | 强制档位是抓帧/验证专用通道 | 依赖环境变量 `AIERDENG_FX_PROFILE`，**未接入正式画质菜单**；正式运行期切档归 Rank-1 的 `QualitySettings` / `fx_profile_controller.gd`。本轮不越界改它们 |
| 6 | mobile 仍是「四项全关」冻结口径 | `HD2D-FX-PLAN.md §4.3`「移动档降级而非全关」是待裁决建议；本轮保持冻结口径（改降级保留会破坏 47 PASS），未擅改 `render_profiles.tres` / `quality_preset_mobile.tres`（Rank-1 独占） |
| 7 | 静态层逐帧重绘未节流 | `hd2d_fx.gd::_process()` 沿用逐帧 `queue_redraw()` 口径（mobile 四项全关时 `_all_on=false` 不重绘，故 mobile 无此开销）；PLAN §4.4 的节流建议仍待 Rank-1 落地 |
| 8 | 画面验收范围 | 基于 Movie Maker 4 帧**静态真实像素查看 + PIL 量化**；未做逐帧动态验收 / 人工试玩 / 运行期帧时间实测（PLAN §4.1 基线不含 FX，不冒充性能结果） |
| 9 | 长期阻塞（沿用既有登记） | ComfyUI 正式素材接入、`128bit` 口径、apk 产物、运行期可见性人工验收仍未解决；**ComfyUI 仍是主美术路线**，本脚本是零外部依赖 2D 程序化兜底，不取代主路线、不宣称已能出图 / 已实现 3D 后处理 / 原生 HDR bloom |
| 10 | 真跑 / 抓帧失败项 | **无**。G1/RUN/G2/G3 与 A/B/C/D 全部 EXIT=0，8 份日志 ERROR 0 条；若有失败会如实写入本节 |

---

## 4. 合规声明

本轮**只写**派单授权范围：`godot/scripts/hd2d_fx.gd`、`godot/scenes/hd2d_fx.tscn`、`capture/` 下本轮产物与 `CAPTURE-REPORT.md`（独占追加）、`teamwork/Rank-4/DONE-R20.md`、回执例外 `teamwork/command_center/ai/4/outbox/cmd-20261109-110237-810-A4.json`。**未写** `courtyard.tscn` / `quality_settings` / `fx_profile_controller.gd`（Rank-1 独占）、`project.godot` / `hud.gd`（Rank-3 独占）、`verify_frame_data.gd`（Rank-2 独占）、`verify_fx_mobile.gd`（本轮零改动）、任何 `.tres` / `.import` / 其它 `.gd` / 其它工位 / 总线 / 总纲 / 契约 / 任务书；未自行 git。所有 stdout 均为 Godot 4.7.2 真跑 / grep / PIL 实际计算结果，未伪造、未臆造引擎常量、未谎报成功、未冒充全绿；画面描述基于 ViewImage 真实查看；`r20_mobile*.png` 全部为 Movie Maker 真实输出，非 desktop 帧改名冒充。零付费 / 零外部生成服务 / 零外部素材增量 / 零插件；中文 UTF-8；Godot 4.7.2 合法语法。

---

## 5. 并发保护只读复核补记（本执行实例）

> 开工定点检查发现：本轮交付件（`r20_mobile*.png` / `r20_desktop*.png` / `r20_mobile_lowres*.png` / sha256 留证 / 8 份 `r20_*.log`）、`capture/CAPTURE-REPORT.md`「R20 移动档验收」段落、`godot/scripts/hd2d_fx.gd` + `godot/scenes/hd2d_fx.tscn` 精修、`teamwork/Rank-4/DONE-R20.md`、以及按本轮 id 的回执（`teamwork/command_center/ai/4/outbox/` 已被中枢实时消费移走，归档于 `dispatcher/receipts/cmd-20261109-110237-810-A4.json` 2530 字节、ledger `status=done`）**均已由并发实例写齐**。按并发保护规则：只做只读复核 + 补明显缺口，**不重做、不覆盖、不改写、不写第二份回执**；outbox 空但 receipts 归档存在即视为已送达。

**只读复核实证**（与上文 §2 逐字一致）：`grep -cE "SCRIPT ERROR|Parse Error|ERROR"` 对 8 份 `r20_*.log` 全部 **0 条**；`r20_verify_run.log` = `==== [R19] SUMMARY pass=47 fail=0 total=47 ====` / `==== [R19] RESULT=PASS ====` + 4 行「默认档位=desktop（未请求覆盖）」→ desktop 零回退。`sha256sum` 实测 `verify_fx_mobile.gd`=`b5c0dda33edd895ae…`（与 DONE-R19 记录一致 → 47 PASS 为既有脚本原样真跑）、`hd2d_fx.gd`=`6509f45c6f530aec…`、`hd2d_fx.tscn`=`9a79ccbfde13df13…`，与 §1.1 声明逐字一致。PNG 实测：`r20_mobile` 4 帧全同 `94264be8…`、`r20_mobile_lowres` 4 帧全同 `72b10a99…`、`r20_desktop` 4 帧各异，且 mobile 与 desktop 的 sha256 互不相同 → **非 desktop 帧改名冒充**；`r20_capture_mobile.log` 证据链（强制 mobile ×4 → 两次拦截 desktop → deferred 四门 `[false false false false]` ×4 → `4 frames at 30 FPS`）复核无误。

**GPU job 本轮定点只读检查（补 §3 第 9 项的显式记录）**：按硬约束**只做一次**定点只读（日志 + `Rank-4/*.png`），未重复启动第二个 GPU job、未杀 / 未重启既有 job。`teamwork/Rank-4/asset_proof_stderr.log` 仅见 `[load] text_encoder (nf4)` / `[load] transformer (nf4)` / `Loading weights …/750` / `Loading checkpoint shards: 50% … 1/2 [05:35<05:35, 335.95s/it]`，**停在权重加载阶段，无任何出图保存 / Saved / `.png` 记录**；`asset_proof_stdout.txt` 无 PNG 字样；`Rank-4/*.png` 仅既有 `ground_tile.png`（历史程序化 `_draw()` 占位地面砖，非本 qwen-image job 产物），不触发 alpha/128px/≤256 色新素材验收。**结论：仍无出图 PNG，qwen-image `--quant nf4` 长时 job 为长期阻塞**，如实登记、不谎报；本轮主交付（Movie Maker 抓帧与移动档光效）不依赖该 job，已完成。ComfyUI 仍是主美术路线，程序化 `_draw()` 为零外部依赖兜底。
