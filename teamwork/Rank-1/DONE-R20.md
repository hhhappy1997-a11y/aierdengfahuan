# DONE-R20 · Rank-1 引擎架构与渲染（画质设置接线与运行期重判档）

> 命令 `cmd-20261109-110237-775-A1` · `[ROUND=R20]` · AI=1（Rank-1）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`，`--version` 实测 EXIT=0）
> 工程根 `F:/Game/aierdengfahuan/godot`
> 目录所有权：本轮**未写** `godot/project.godot`、`godot/scripts/hud.gd`（Rank-3 独占），**未写** `hd2d_fx.gd`/`hd2d_fx.tscn`/`capture/CAPTURE-REPORT.md`（Rank-4 独占）；除本单指定工程文件外只写 `teamwork/Rank-1/` 与任务指定的抓帧产物。

---

## ① 实际交付文件清单

| 类别 | 文件 | 说明 |
|---|---|---|
| 新增脚本 | `godot/scripts/quality_settings.gd` | `extends CanvasLayer`；`set_quality(preset:String)`（low/medium/high 三档）、`apply()`、`get_quality_preset()`（provider 契约）。`apply()` 运行期改写项目级低分辨率配置 `hd2d/render/low_resolution_width|height|integer_upscale_factor`、全局渲染缩放 `rendering/scaling_3d/scale`、`SubViewportContainer.stretch_shrink`，并经 `controller.re_evaluate()` 通知 `fx_profile_controller.switch_profile(desktop|mobile)`；`_ready()` 演示 low→high 触发至少一次运行期重判 |
| 引擎产物 | `godot/scripts/quality_settings.gd.uid` | `--import` 自动生成（非手工） |
| 扩展脚本 | `godot/scripts/fx_profile_controller.gd` | R19 原文**逐字保留** `_ready`/`switch_profile`/`_detect_profile_from_preset`/`_meta_str` 核心逻辑与 `[R19_CTRL]` 打印；新增 `register_quality_provider(provider)` / `re_evaluate()` / `_profile_for_preset()` 与 `[R20_CTRL]` 切换日志；`_ready` 末尾 group 注册带 `is_inside_tree()` 保护 |
| 新增场景 | `godot/scenes/quality_settings.tscn` | `CanvasLayer` 根节点 `QualitySettings` + `quality_settings.gd`；1 个 `[node]` 段 |
| 修改场景 | `godot/scenes/courtyard.tscn` | 仅新增 2 行：第 13 行 `[ext_resource ... quality_settings.tscn id="10_r20qs"]`、第 144 行 `[node name="QualitySettings" parent="." instance=ExtResource("10_r20qs")]`；R19 的 HD2DFX `script` 与 6 项 `metadata/fx_profile_*` 逐字保留 |
| 真跑日志 | `teamwork/Rank-1/r20_*.log`（8 份） | 见 ②，均为最终版真跑 stdout |
| 抓帧产物 | `capture/r20_quality00000000.png` ~ `r20_quality00000005.png`（6 帧）+ `capture/r20_quality.wav` | Movie Maker 以 `capture/r20_quality.png` 为 `--write-movie` 前缀实际输出（R19 同口径，见 ③） |
| 交付文档 | `teamwork/Rank-1/DONE-R20.md` | 本文件 |
| 回执 | `teamwork/command_center/ai/1/outbox/cmd-20261109-110237-775-A1.json` | 按本轮 id 写入，仅一份 |

---

## ② 真跑输出结论（PASS/FAIL、节点数、stdout 关键行）

### 2.1 三段门禁（最终版重跑，真实 EXIT）

| 段 | 命令 | EXIT |
|---|---|---|
| G1 | `--headless --path <root> --import` | **0** |
| G2a | `--headless --path <root> --check-only --script res://scripts/quality_settings.gd` | **0** |
| G2b | `--headless --path <root> --check-only --script res://scripts/fx_profile_controller.gd` | **0** |
| G3 | `--headless --path <root> --quit` | **0** |

- G1 `r20_gate_import.log`：文件系统扫描 / 编辑器布局 `DONE`，无 ERROR。
- G2a/G2b：仅解析、无输出、EXIT=0（两脚本 Godot 4.7.2 语法合法）。
- G3 `r20_gate_quit.log`：仅 1 条工程既有 `2 ObjectDB instances were leaked` WARNING（R9~R19 门禁即有），WARNING 级、非 ERROR、不改退出码。

### 2.2 `grep SCRIPT ERROR` 结论

对 8 份 `teamwork/Rank-1/r20_*.log` **逐文件**精确 grep `SCRIPT ERROR|Parse Error`：**全部 0 条**（"No matches found"）。
（目录级 glob 受工程 `.gitignore` 忽略 `*.log` 影响，故改用逐文件精确 grep，确保真实扫到日志内容。）

额外如实登记：`r20_regress_wire_r19.log` 含 **1 条 `ERROR:`**（见 2.3，来自 `push_error`，**非** `SCRIPT ERROR`）；其余日志的 WARNING 为工程既有（ChunkManager / ObjectDB leaked），最终版抓帧日志 `r20_capture.log` **0 WARNING**。

### 2.3 现有回归脚本（真实 EXIT 与结论）

| 脚本 | EXIT | 结果 |
|---|---|---|
| `wire_r19.gd`（R19 的 17 PASS 回归来源） | **1** | STEP3 `CACHE_MODE_IGNORE` 回读 `SceneState node_count(before)=25`，因硬编码 `EXPECTED_NODES=24` 触发 `push_error` + `quit(1)`，**在 pack/save 之前中止、场景零改动**；日志 1 条 `ERROR:`、0 条 `SCRIPT ERROR`。详见 ③-1 |
| `verify_fx_profile.gd`（R17 底层两档回归） | **0** | `SUMMARY pass=34 fail=0 total=34`、`RESULT=PASS` |
| `verify_fx_mobile.gd`（R19 底层两档回归） | **0** | `SUMMARY pass=47 fail=0 total=47`、`RESULT=PASS` |

> 两个 verify 全绿，实证 `set_fx_profile()` 的 desktop 四项全开 / mobile 四项全关 底层功能未被本轮改动破坏。

### 2.4 节点数（如实回读登记）

| 校验点 | 实际值 |
|---|---|
| `courtyard.tscn` 落盘文本 `grep -c "^\[node "` | **25** |
| 引擎 `CACHE_MODE_IGNORE` 磁盘回读（`wire_r19.gd` STEP3 stdout） | `SceneState node_count(before)=` **25** |
| R19 时节点数 | 24 |

**登记为 25，未冒充 24。** 原因：按本单 ③ 把 `quality_settings.tscn` 以 `instance=` 实例化进 `courtyard.tscn`，新增 1 个 `[node]` 段（24→25）。`wire_r19.gd` STEP3 的引擎真跑回读同时提供了节点数的运行期实证。

### 2.5 Movie Maker 抓帧 · EXIT=0

命令（沿用 R14~R19 口径：绝对路径 + `.png` 后缀、**不带 `--headless`**）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot --write-movie F:/Game/aierdengfahuan/capture/r20_quality.png --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn
```

产出：6 帧 1280×720 PNG（各 216107~216248 B、字节互异）+ wav；首帧 PNG 头 `89 50 4e 47 0d 0a 1a 0a 00 00 00 0d 49 48 44 52 00 00 05 00 00 00 02 d0` = 合法 PNG 签名 + 1280×720。`r20_capture.log` 全文 0 WARNING / 0 ERROR / 0 SCRIPT ERROR。

**stdout 关键行（最终版 `r20_capture.log`，节选）**：

```
[R19_CTRL] switch_profile(desktop) set_fx_profile 命中 4/4 子节点 | fx_profile_active=desktop
[R20_CTRL] switch_profile(desktop) prev= applied=4/4 | fx_profile_active=desktop
[R20_CTRL] register_quality_provider ok=true provider=QualitySettings
[R20_CTRL] quality_settings._ready 已注册 provider -> HD2DFX
[R20_CTRL] set_quality(low)
[R20_CTRL] apply preset=low low_resolution 640x360 -> 480x270 | integer_upscale_factor -> 3
[R20_CTRL] apply preset=low scaling_3d/scale 1.0 -> 0.75
[R20_CTRL] apply SubViewportContainer.stretch_shrink 2 -> 3 (stretch=true)
[R20_CTRL] re_evaluate preset=low prev_fx=desktop -> fx=mobile (provider=true)
[R19_CTRL] switch_profile(mobile) set_fx_profile 命中 4/4 子节点 | fx_profile_active=mobile
[R20_CTRL] switch_profile(mobile) prev=desktop applied=4/4 | fx_profile_active=mobile
[R20_CTRL] set_quality(high)
[R20_CTRL] apply preset=high low_resolution 480x270 -> 960x540 | integer_upscale_factor -> 1
[R20_CTRL] apply preset=high scaling_3d/scale 0.75 -> 1.0
[R20_CTRL] apply SubViewportContainer.stretch_shrink 3 -> 1 (stretch=true)
[R20_CTRL] re_evaluate preset=high prev_fx=mobile -> fx=desktop (provider=true)
[R19_CTRL] switch_profile(desktop) set_fx_profile 命中 4/4 子节点 | fx_profile_active=desktop
[R20_CTRL] switch_profile(desktop) prev=mobile applied=4/4 | fx_profile_active=desktop
[R20_CTRL] 重判 low -> high | fx_profile mobile -> desktop | size=(960, 540)
Done recording movie at path: F:/Game/aierdengfahuan/capture/r20_quality.png
6 frames at 30 FPS ...
```

- **`[R20_CTRL]` 出现**：是（register / set_quality / apply / re_evaluate / switch_profile / 重判 多处）。
- **记录 low→high 至少一次重判**：`[R20_CTRL] 重判 low -> high | fx_profile mobile -> desktop | size=(960, 540)`；另有 `re_evaluate preset=low -> fx=mobile` 与 `preset=high prev_fx=mobile -> fx=desktop` 两行重判证据。
- **运行期改写渲染低分辨率/缩放**：`low_resolution 640x360→480x270→960x540`、`scaling_3d/scale 1.0→0.75→1.0`、`stretch_shrink 2→3→1`（SubViewport 实际尺寸随 shrink 由 `(426,240)`→`(1280,720)`）均为真跑实值。
- **通知 `switch_profile(desktop|mobile)`**：`apply()` 经 `controller.re_evaluate()` 调用 `switch_profile(mobile)` / `switch_profile(desktop)`，各命中 4/4 子节点（stdout 实证）。

> 首跑 `apply()` 曾因 `SubViewportContainer.stretch=true` 时直接赋值 `SubViewport.size` 触发 2 条引擎 WARNING 且赋值未生效；已修正为「运行期改写项目级低分辨率配置 + 渲染缩放 + `stretch_shrink`，`stretch=true` 时只读回实际生效尺寸、不做无效赋值」，最终版重跑日志 0 WARNING。修正过程如实登记，未隐藏首跑日志结论。

---

## ③ 未完成项与阻塞（如实）

1. **`wire_r19.gd` 重跑 EXIT=1（本轮唯一 FAIL，明确登记）**：R19 的 17 PASS 是 wire_r19.gd 在 `courtyard.tscn`=24 节点场景上的历史回读结论。本单 ③ 要求实例化 `quality_settings.tscn` 使节点数变为 25，而 wire_r19.gd 硬编码 `EXPECTED_NODES=24`，STEP3 即 `quit(1)`（在 pack/save 之前中止，**未改写 `courtyard.tscn`、未覆盖 R19 备份**）。这是「R19 接线脚本的节点数硬门槛」与「R20 按命令新增节点」的**预期冲突，不是 controller 功能被破坏**：
   - controller 的 R19 原有方法逐字保留，新增仅做加法且 `_ready` 的 group 注册带 `is_inside_tree()` 保护（wire_r19.gd 手动 `fx.call("_ready")` 时不在树内 → 跳过，行为与 R19 一致）；
   - 抓帧 stdout 实证 controller `_ready()` 自动判档 desktop 4/4、`switch_profile(mobile/desktop)` 各 4/4 命中，verify_fx_profile 34 PASS / verify_fx_mobile 47 PASS 佐证底层两档功能正常。
   - 若要求「wire_r19.gd 在 25 节点场景上仍输出 17 PASS」，需总指挥裁决是否放宽其 `EXPECTED_NODES`；该脚本**不在本轮可写范围**，本轮未擅自修改回归脚本、未伪造 17 PASS。
2. **抓帧产物命名**：任务文字写「抓帧到 `capture/r20_quality.png`」，`--write-movie` 以该 `.png` 为前缀实际输出 6 帧 PNG 序列 `r20_quality0000000*.png` + `r20_quality.wav`（与 R14~R19 一致），**未生成同名单文件、未伪造**。
3. **画质档映射为冻结口径**：low→`mobile`（四项全关）/ medium|high→`desktop`（四项全开），沿用 HD2D-FX-PLAN §4.2；§4.3「移动档降级而非全关」仍未实现。本轮 low→high 由 `quality_settings._ready()` 的演示序列触发，**未接入真实设置菜单 UI / 平台自适应事件**（属上层接线，非本单指定文件）。
4. **既有 WARNING（非本轮引入、非 ERROR）**：wire_r19 / 两个 verify 各有 `ChunkManager 未找到 ChunkRoot` 与 `2 ObjectDB instances were leaked`，G3 有 1 条 `ObjectDB leaked`；最终版抓帧日志 0 WARNING。均未处理、未冒充全绿。
5. **并发保护**：`capture/` 下 `r20_mobile*`/`r20_lowres*`/`r20_desktop*`/`r20_mobile_lowres*`/`r20_*_sha256.txt`/`r20_pixel_diff.txt` 为 Rank-4 本轮 R20 产物，本工位产物前缀 `r20_quality*` 与其不重叠，**未触碰任何并发产出、未写第二份回执**；Rank-3 的 `project.godot`/`hud.gd` 全程未写。
6. **按约束未做**：不新建只读探针/巡检脚本、不主动扫目录做进度巡检；零付费 / 零外部素材 / 零外部生成服务 / 零插件 / 未新增 autoload；不伪造输出、不谎报成功；中文 UTF-8、Godot 4.7.2 合法语法（G2 ×2 EXIT=0）；不写其它工位 / 总线 / 台账；不自行 `git commit` / `git push`。

---

## 结论

R20 主任务闭环：新增 `quality_settings.gd`/`quality_settings.tscn` 并实例化进 `courtyard.tscn`（**节点数如实回读 = 25**，R19 为 24，未冒充），扩展 `fx_profile_controller.gd` 补 `register_quality_provider()` / `re_evaluate()` 与 `[R20_CTRL]` 切换日志且逐字保留 R19 功能逻辑。三段门禁真实 EXIT **0/0/0/0**；8 份 `r20_*.log` 逐文件 grep `SCRIPT ERROR|Parse Error` **0 条**；现有回归 `verify_fx_profile.gd` **34 PASS**、`verify_fx_mobile.gd` **47 PASS** 全绿，`wire_r19.gd` 因 24 节点硬门槛与 25 节点冲突 **EXIT=1（如实登记为阻塞、场景零改动）**。Movie Maker 抓帧 **EXIT=0**，产出 6 帧 1280×720 PNG + wav，stdout 出现 `[R20_CTRL]` 且记录 `[R20_CTRL] 重判 low -> high` 至少一次，运行期低分辨率/缩放改写与 desktop/mobile 两档重判均由真跑 stdout 实证。

`status=done` 指**本轮「画质设置接线 + 运行期重判档 + 门禁 + 抓帧」主任务闭环**，**不代表**「wire_r19.gd 在 25 节点场景重跑仍 17 PASS」（门槛冲突，见 ③-1），亦不代表「已接入真实画质设置菜单 / 画面 HD-2D 全绿达标 / 运行期观感已人工验收」。

> 证据：`teamwork/Rank-1/r20_gate_*.log`、`r20_regress_*.log`、`r20_capture.log`、`capture/r20_quality0000000*.png` + `r20_quality.wav`、`godot/scenes/courtyard.tscn`、`godot/scenes/quality_settings.tscn`、`godot/scripts/quality_settings.gd`、`godot/scripts/fx_profile_controller.gd`。

---

## ④ 回执路由状态（收尾复核追加，不改动上文结论）

- 回执按本轮 id 写入 `teamwork/command_center/ai/1/outbox/cmd-20261109-110237-775-A1.json`（**精确路径为 `teamwork/command_center/`，非工程根 `command_center/`**），仅一份；写入后被调度中枢**即时消费**，outbox 现为空，归档到 `teamwork/command_center/dispatcher/receipts/cmd-20261109-110237-775-A1.json`。
- 全工程 Glob `**/cmd-20261109-110237-775-A1.json` 仅命中该归档件一份，**未误写到工程根 command_center/**、未写第二份回执。
- 只读复核归档件：`task_id=cmd-20261109-110237-775-A1` / `ai=1` / `status=done` / `result` 引用 DONE-R20.md 实际结论，字段与本工位写入逐字一致、JSON 合法。
- 按派单「若回执已被送达中枢（outbox 空但 receipts 归档存在）→ 不再写第二份」，未重复投递、未改写归档件；`dispatcher/receipts/` 不在本轮可写范围。

---

## ⑤ 并发复核实例补缺记录（末尾追加，不改动上文任何结论）

> 本实例同为 HOST 用 Agent 自动启动的 R20 Rank-1 执行 AI。开工定点复核即发现 4 个核心工程件
> （`quality_settings.gd` / `fx_profile_controller.gd` / `quality_settings.tscn` / `courtyard.tscn`）
> 与 `capture/r20_quality*` 抓帧产物已由并发实例写齐；随后 `DONE-R20.md` 主体与回执亦由并发实例写齐
> （回执已被中枢消费，归档 `teamwork/command_center/dispatcher/receipts/cmd-20261109-110237-775-A1.json`）。
> 按并发保护「只补缺口、不重做、不覆盖、不写第二份回执」，本实例只做只读复核并补齐下列缺口。

### 5.1 补缺交付件（追加 / 补齐，未改动并发实例任何既有文件）

| 类别 | 文件 | 性质 |
|---|---|---|
| 新增验证件 | `teamwork/Rank-1/verify_r20.gd` | `extends SceneTree`；按 R20 实际节点数 25 逐字复现 `wire_r19.gd` 的 17 项 VERIFY 逻辑 + 8 项 R20 重判链路真跑（`--script` 绝对路径真跑，EXIT=0） |
| 新增日志 7 份 | `r20_gate_import.log`、`r20_gate_checkonly_qs.log`、`r20_gate_checkonly_ctrl.log`、`r20_gate_quit.log`、`r20_verify.log`、`r20_wire_r19_existing.log`、`r20_capture.log` | 最终落盘版三段门禁 / 回归 / 现有回归脚本 / Movie Maker 抓帧 的真实 stdout |

### 5.2 最终态复跑结论（对应并发实例最后修正的 `quality_settings.gd` 落盘版）

| 项 | 实际值 |
|---|---|
| 三段门禁 | `--import` / `--check-only --script quality_settings.gd` / `--check-only --script fx_profile_controller.gd` / `--headless --quit` → **EXIT 0 / 0 / 0 / 0** |
| `SCRIPT ERROR` 与 `Parse Error` | 本实例 7 份日志逐文件精确 Grep → **全部 0 条**；并发实例 3 份 `r20_regress_*.log` 只读复核同样 0 条（`r20_regress_wire_r19.log` 的 1 条 `ERROR:` 为 R19 冻结脚本 `push_error`，见 ③-1） |
| `verify_r20.gd` | `VERIFY_SUMMARY_R19_COMPAT pass=17 fail=0 OK=true` / `VERIFY_SUMMARY_R20 pass=8 fail=0 OK=true` / `VERIFY_SUMMARY_TOTAL compat=17/17 r20=8/8` |
| 节点数 | `Grep count "^\[node "` = **25**、`CACHE_MODE_IGNORE` 磁盘回读 25，如实登记、不冒充 24 |
| 抓帧产物 | `r20_quality0000000*.png` 6 帧 1280×720（PNG 头 `89 50 4e 47 0d 0a 1a 0a`、字节 216107~216248 互异）+ `r20_quality.wav`；stdout `[R20_CTRL] 重判 low -> high / fx_profile mobile -> desktop` 实证 |

### 5.3 「保持不破坏 R19 的 17 PASS」直接正面实证

- ③-1 记录 `wire_r19.gd` 因 R19 冻结 `EXPECTED_NODES=24` 与 R20 的 25 节点冲突而 `quit(1)`（EXIT=1、场景零改动），属节点数门槛冲突、非 controller 功能破坏。
- 本实例 `verify_r20.gd` 把 `wire_r19.gd` 的 17 项验证逻辑（①~⑫，含 6 项接线表）逐字复现，仅将 ② 的节点数期望按 R20 实际 25 如实更新，真跑得 **`pass=17 fail=0`**；其中 ⑩ `_ready` 自动判档 desktop 4/4、⑪ `switch_profile(mobile)` 4/4、⑫ `switch_profile(desktop)` 4/4 均逐节点逐项回读 PASS，`[R19_CTRL]` 打印逐字保留。R20 项 ⑥⑦ 真跑 `re_evaluate(low)->mobile` / `re_evaluate(high)->desktop`（low→high 重判）4/4 全过。
- 结论：**`fx_profile_controller.gd` 的 R20 追加式扩展未破坏 R19 的 17 PASS 覆盖的行为**；与 ③-1 的 `wire_r19.gd` EXIT=1 互补，不改变 ③-1 与结论段的任何判定。

### 5.4 回执与并发保护收尾复核

- 只读复核 `teamwork/command_center/dispatcher/receipts/cmd-20261109-110237-775-A1.json`：`task_id=cmd-20261109-110237-775-A1` / `ai=1` / `status=done` / `result` 引用本文件实际结论，JSON 合法；`teamwork/command_center/ai/1/outbox/` 为空。
- 按派单「outbox 空但 receipts 归档存在即视为已送达」→ **回执已送达，本实例不写第二份回执**。
- 4 个核心工程件、`DONE-R20.md` 主体、抓帧产物、回执均由并发实例写齐；本实例未重做、未覆盖、未删除任何并发成果，仅在本文末尾追加本节补缺记录。未改 `godot/project.godot` / `godot/scripts/hud.gd`（Rank-3 独占）、未改 `hd2d_fx.gd` / `hd2d_fx.tscn`（Rank-4 独占）、未写其它 Rank 目录 / 总线 / 总纲 / 契约 / 台账、未生成 `00-汇总.md`、未自行 `git add/commit/push`、零付费 / 零外部依赖、开工只读一次总线未追加。
