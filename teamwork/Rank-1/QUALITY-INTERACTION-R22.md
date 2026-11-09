# QUALITY-INTERACTION-R22.md · 画质菜单真实交互验收（信号注入 + Movie Maker 抓帧）

> 命令 `cmd-20261109-124640-130-A1` · `[ROUND=R22]` · AI=1（Rank-1）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`，`--version` EXIT=0）
> 工程根 `F:/Game/aierdengfahuan/godot`；抓帧目录 `F:/Game/aierdengfahuan/capture/`
> 本轮目录所有权：**只写** `godot/scripts/verify_quality_interaction.gd`（+ 引擎自动 `.uid`）、
> `capture/r22_quality_*.png` / `r22_quality_*.wav`（本单指定）、`teamwork/Rank-1/r22_*.log`、
> `teamwork/Rank-1/QUALITY-INTERACTION-R22.md`、`DONE-R22.md`、回执 JSON。
> **未写** `project.godot`（工程冻结）、`hud.gd`、`hd2d_fx.gd`/`hd2d_fx.tscn`、
> `verify_frame_data.gd`、`capture/CAPTURE-REPORT.md`、`godot/test/`（禁写清单）。

---

## ① 本轮补的缺口（R21 → R22）

R21 如实登记「画质按钮未发生真实点击」：其 `[R21_QUALITY]` 仅是 `_ready()` 的 UI 就绪 /
按钮连接 / 节点数回读日志；`quality_settings.gd` 已去掉自动演示序列，Movie Maker 无交互录制时
`_on_quality_button_pressed()` 回调从未触发，故「选择画质档」日志缺失。

R22 用**可复现的脚本交互**补上该证据链：新写 `verify_quality_interaction.gd`（`extends SceneTree`），
真跑加载 `courtyard.tscn` → 找到 `QualitySettings` 实例的三个 Button →
用脚本 `Button.pressed.emit()` **注入 pressed 信号**（如实声明：**非 `InputEventMouseButton` 鼠标点击**）
依次切 `low / medium / high` → 每次切换读回 `fx_profile_controller` 实际档位与四项渲染参数 →
stdout 打印 `[R22_QUALITY]` 每档证据 → 与 Movie Maker (`--write-movie`) 同跑录制三档画面。

信号注入真实打通了 R21 缺失的回调链路，抓帧 stdout 中确出现三条
`[R21_QUALITY] 选择画质档 preset=low|medium|high | 链路 set_quality→apply→re_evaluate 完成`（见 §③）。

---

## ② 验证脚本设计（结构性事实自己验）

`godot/scripts/verify_quality_interaction.gd`（GDScript 类型标注完整，Godot 4.7.2 合法语法）：

1. `ResourceLoader.load("res://scenes/courtyard.tscn", "PackedScene", CACHE_MODE_IGNORE)` 从磁盘重解析，
   实跑 `ps.get_state().get_node_count() = 25`；`instantiate()` → `root.add_child()` →
   `await process_frame` 触发全部 `_ready()`（按钮绑定、controller group 注册）。
2. 结构核实（4 项 PASS）：`QualitySettings` 实例存在且为 `CanvasLayer`；`HD2DFX` 挂
   `fx_profile_controller.gd` 且有 `switch_profile`/`re_evaluate`；`SubViewportContainer`/`SubViewport`
   存在；三个 Button（`BtnLow/BtnMedium/BtnHigh`）各有 `pressed` 连接 1 条（保证 emit 能触发回调）。
3. 依次 `btn.pressed.emit()`，每档 `await` 4 个 `process_frame`（让 `apply()` 渲染参数生效 +
   Movie Maker 录到该档稳定帧），回读 5 项并与独立 oracle（`quality_settings.gd` 的冻结 PRESETS，
   不从被测脚本 import）比对：fx_profile_active / low_resolution_size / scaling_3d / stretch_shrink /
   SubViewport 实际尺寸。
4. 汇总 `19 PASS / 0 FAIL`（4 结构 + 3 档 × 5 项），`RESULT=PASS`，`quit(0)`。

真跑命令族（全部绝对路径；交互验证 headless，抓帧不带 `--headless` 走 GPU、一次只跑一个 GPU 任务）：

```
# 三段门禁
G1: godot --headless --path F:/Game/aierdengfahuan/godot --import
G2: godot --headless --path F:/Game/aierdengfahuan/godot --check-only --script res://scripts/verify_quality_interaction.gd
G3: godot --headless --path F:/Game/aierdengfahuan/godot --quit
# 交互验证（headless，stdout 证据）
    godot --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/verify_quality_interaction.gd
# 交互验证 + Movie Maker 抓帧（GPU，同一脚本同一运行）
    godot --path F:/Game/aierdengfahuan/godot --script res://scripts/verify_quality_interaction.gd \
          --write-movie F:/Game/aierdengfahuan/capture/r22_quality_.png --fixed-fps 30
# 回归
    godot --headless --path ... --script res://scripts/verify_fx_profile.gd
    godot --headless --path ... --script res://scripts/verify_fx_mobile.gd
```

---

## ③ 三档真跑 stdout（`r22_interaction.log` / `r22_capture.log` 原文摘录）

### 交互触发证据（R21 缺失的「选择日志」本轮真实出现）

```
[R22] SIGNAL_INJECT preset=low    button=BtnLow    method=Button.pressed.emit() | 非鼠标点击
[R21_QUALITY] 选择画质档 preset=low | 链路 set_quality→apply→re_evaluate 完成 | get_quality_preset()=low
[R22] SIGNAL_INJECT preset=medium button=BtnMedium method=Button.pressed.emit() | 非鼠标点击
[R21_QUALITY] 选择画质档 preset=medium | 链路 set_quality→apply→re_evaluate 完成 | get_quality_preset()=medium
[R22] SIGNAL_INJECT preset=high   button=BtnHigh   method=Button.pressed.emit() | 非鼠标点击
[R21_QUALITY] 选择画质档 preset=high | 链路 set_quality→apply→re_evaluate 完成 | get_quality_preset()=high
```

### `[R22_QUALITY]` 每档证据

```
[R22_QUALITY] 档位=low | 触发=Signal.pressed.emit()（脚本注入，非鼠标点击） | fx_profile_controller.fx_profile_active=mobile
[R22_QUALITY] 档位=low | low_resolution_size=(480, 270) | scaling_3d/scale=0.75 | stretch_shrink=3 | SubViewportContainer.stretch=true | SubViewport.size(实际渲染)=(426, 240)
[R22_QUALITY] 档位=low | 脚本渲染帧区间=[1..4] 停留=4帧（Movie Maker --write-movie 序列中本档对应帧段）

[R22_QUALITY] 档位=medium | 触发=Signal.pressed.emit()（脚本注入，非鼠标点击） | fx_profile_controller.fx_profile_active=desktop
[R22_QUALITY] 档位=medium | low_resolution_size=(640, 360) | scaling_3d/scale=0.85 | stretch_shrink=2 | SubViewportContainer.stretch=true | SubViewport.size(实际渲染)=(640, 360)
[R22_QUALITY] 档位=medium | 脚本渲染帧区间=[5..8] 停留=4帧（Movie Maker --write-movie 序列中本档对应帧段）

[R22_QUALITY] 档位=high | 触发=Signal.pressed.emit()（脚本注入，非鼠标点击） | fx_profile_controller.fx_profile_active=desktop
[R22_QUALITY] 档位=high | low_resolution_size=(960, 540) | scaling_3d/scale=1.0 | stretch_shrink=1 | SubViewportContainer.stretch=true | SubViewport.size(实际渲染)=(1280, 720)
[R22_QUALITY] 档位=high | 脚本渲染帧区间=[9..12] 停留=4帧（Movie Maker --write-movie 序列中本档对应帧段）
```

### 三档运行期回读对照（`[R22_RES]` 原文）

```
[R22_RES] 档位=low    shrink=3 SubViewport.size=(426, 240)   fx=mobile  low_resolution_size=(480, 270) scale=0.75
[R22_RES] 档位=medium shrink=2 SubViewport.size=(640, 360)   fx=desktop low_resolution_size=(640, 360) scale=0.85
[R22_RES] 档位=high   shrink=1 SubViewport.size=(1280, 720)  fx=desktop low_resolution_size=(960, 540) scale=1.0
```

| 档位 | fx_profile_active | low_resolution_size | scaling_3d/scale | stretch_shrink | SubViewport 实际渲染 |
|---|---|---|---|---|---|
| low | mobile（四项 FX 全关） | (480, 270) | 0.75 | 3 | (426, 240) |
| medium | desktop（四项全开） | (640, 360) | 0.85 | 2 | (640, 360) |
| high | desktop（四项全开） | (960, 540) | 1.0 | 1 | (1280, 720) |

汇总：`==== [R22] SUMMARY pass=19 fail=0 total=19 ====` / `==== [R22] RESULT=PASS ====`，
交互验证 EXIT=0、抓帧运行 EXIT=0，**`SCRIPT ERROR=0`**。

---

## ④ 三段门禁与 SCRIPT ERROR 汇总

| 段 | 命令 | EXIT |
|---|---|---|
| G1 | `--headless --path <root> --import` | **0** |
| G2 | `--headless --path <root> --check-only --script res://scripts/verify_quality_interaction.gd` | **0** |
| G3 | `--headless --path <root> --quit` | **0** |

对最终版 7 份 `teamwork/Rank-1/r22_*.log` **逐文件**精确 grep `SCRIPT ERROR|Parse Error`，**全部 0 条**：

```
r22_capture.log 0 | r22_gate_checkonly.log 0 | r22_gate_import.log 0 | r22_gate_quit.log 0
r22_interaction.log 0 | r22_regress_verify_fx_mobile.log 0 | r22_regress_verify_fx_profile.log 0
```

回归（不回退）：`verify_fx_profile.gd` **34 PASS / 0 FAIL / RESULT=PASS**；
`verify_fx_mobile.gd` **47 PASS / 0 FAIL / RESULT=PASS**；两份 EXIT=0、`SCRIPT ERROR=0`。

引擎自动产物（非手写，如实登记）：`godot/scripts/verify_quality_interaction.gd.uid`（19 字节，G1 `--import` 生成）。

---

## ⑤ 抓帧产物（`capture/`，全部 Movie Maker 真实输出）

抓帧 stdout：

```
Movie Maker mode enabled, recording movie in 1280×720 @ 30 FPS...
Done recording movie at path: F:/Game/aierdengfahuan/capture/r22_quality_.png
13 frames at 30 FPS (movie length: 00:00:00:13), recorded in 00:00:07 (14% of real-time speed).
```

`--write-movie` 前缀 `r22_quality_.png` 按 Godot 约定产出编号序列（前缀非单文件），
文件名全部匹配 `capture/r22_quality_*.png`：

| 帧段 | 文件名 | 张数 | 字节 | 对应档位 |
|---|---|---|---|---|
| A | `r22_quality_00000000.png` ~ `r22_quality_00000003.png` | 4 | 66572（4 帧全同） | low |
| B | `r22_quality_00000004.png` ~ `r22_quality_00000007.png` | 4 | 125633 ~ 125723 | medium |
| C | `r22_quality_00000008.png` ~ `r22_quality_00000012.png` | 5 | 220950 ~ 221137 | high |
| 自动音频轨 | `r22_quality_.wav` | 1 | 166444 | 引擎自动产物 |
| 展示图 A | `r22_quality_low.png` | 1 | 66572 | 由 `00000002` **原样复制** |
| 展示图 B | `r22_quality_medium.png` | 1 | 125654 | 由 `00000006` **原样复制** |
| 展示图 C | `r22_quality_high.png` | 1 | 221085 | 由 `00000010` **原样复制** |

展示图 md5 与源帧逐对一致（原样复制，非伪造、非重新渲染，沿用 R18/R19 先例）：

```
95e8f0fd00c6cf84e58424958d42a217  r22_quality_00000002.png == r22_quality_low.png
4ecfc29f3a085c06f4f51be9f32d258d  r22_quality_00000006.png == r22_quality_medium.png
9c37de1e73a2784bc86e2eca1041f43c  r22_quality_00000010.png == r22_quality_high.png
```

**帧段 ↔ 档位映射与 1 帧偏移（如实）**：脚本 stdout 打印的「脚本渲染帧区间」为
`[1..4] / [5..8] / [9..12]`（脚本帧游标自 1 计）；Movie Maker 实测 PNG 帧号为
`[0..3] / [4..7] / [8..12]`（自 0 计），二者相差 1 帧——`pressed.emit()` 发生在当帧 draw 之前、
两套计数起点不同所致。**以像素量化实测分组为准**，脚本区间仅作时序参考，不硬套帧号。

---

## ⑥ 像素 / 可读性对比（Pillow 量化 + ViewImage 目视，双重实证）

13 帧全部 `1280×720`（IHDR 实测），Pillow 逐帧统计（灰度相邻差 = 高频/边缘能量，
`eq_h/eq_v` = 水平/垂直相邻像素完全相同比例，`uniq_colors` = 唯一 RGB 颜色数）：

| 帧段 | 档位 | 字节 | 边缘能量 | eq_h | eq_v | 唯一颜色数 |
|---|---|---|---|---|---|---|
| A `00000000~00000003` | low | 66572（全同） | **12.397** | **0.955** | 0.876 | **3319** |
| B `00000004~00000007` | medium | ~125670 | 17.658 | 0.932 | 0.801 | ~7620 |
| C `00000008~00000012` | high | ~221060 | **23.931** | **0.918** | 0.709 | **14650** |

三段**段内 4 帧指标几乎恒定**（静态画面，排除「启动渐进渲染」），段间**阶梯式突变**
（边缘能量 12.4 → 17.7 → 23.9，颜色数 3319 → 7621 → 14638），与三档离散切换一一对应。

**ViewImage 目视（三张代表帧，产出先目视再接入）**：

| 档位 | 目视结论 |
|---|---|
| low（图 `r22_quality_00000002.png`） | 画面**完整渲染**（蓝天 / 暖金砖地 / 中央像素骑士 / 左上 HUD「赐福 · 宁姆格福」/ 右上画质面板「画质设置 · 低 / 中 / 高」+「低/中/高」三按钮均可读），**非启动帧**；HUD 面板相对占比最大、砖块最粗、整体最糊；**无体积光柱、无光尘**（mobile 四项 FX 全关）。 |
| medium（图 `r22_quality_00000006.png`） | 同样完整；HUD 面板与文字中等、砖块中等密度；出现淡金色光柱与少量光尘（desktop 四项全开）；清晰度居中。 |
| high（图 `r22_quality_00000010.png`） | 同样完整；HUD 面板最小、砖块最细密锐利、金色光柱与光尘最明显；整体最清晰。 |

结论：三档画面**可读性差异真实可辨**，由两条链路共同产生——
① `stretch_shrink`(3/2/1) → SubViewport 内部渲染分辨率 (426×240)/(640×360)/(1280×720) →
放大后像素块状程度、HUD 相对尺寸、砖块密度、边缘锐利度；
② `fx_profile`(mobile/desktop/desktop) → 四项光效（体积光 / 光尘等）开关。
右上 `QualitySettings` 画质面板是主窗口 `CanvasLayer`（layer=40），三档帧中大小位置一致、不受
SubViewport 内部档位影响，符合预期。

---

## ⑦ 未完成项与边界（如实）

1. **信号注入 ≠ 鼠标点击**：本轮三档切换全部由脚本 `Button.pressed.emit()` 注入触发，
   **如实声明不是 `InputEventMouseButton` 真机鼠标点击**；未做 GUI 人工点击 / 真机点击的 stdout 实证
   （如需需带交互 GUI 运行或总指挥另行派单）。R21 的「未发生真实点击」在本轮升级为
   「信号注入触发了真实回调链路 + 画面档位变化」，但未冒充鼠标点击。
2. **按钮无「选中」视觉反馈**：信号注入只触发回调链路、不改变按钮外观；三档帧中右上画质面板
   三个按钮外观一致。本轮证明的是「档位切换链路生效 + 画面档位变化」，不是「按钮点击视觉反馈」。
3. **Movie Maker 输出恒 1280×720**：13 帧 IHDR 全部 1280×720；三档差异来自**内部 SubViewport
   渲染分辨率与 FX 光效开关**，不是输出尺寸变化。继承 R21 已查清的边界，**不冒充「引擎输出 640×360」**。
4. **`low_resolution_size` 与 SubViewport 实际尺寸不一致**：low 目标 (480,270)/实际 (426,240)、
   high 目标 (960,540)/实际 (1280,720)，因 `stretch=true` 时引擎按 container/shrink 计算
   （1280/3≈426）；为 `quality_settings.gd` 既有行为，本轮如实回读、未改被测脚本。
5. **`scaling_3d/scale` / `low_resolution_size` 是 ProjectSettings 运行期改写**（读回值真实变化、
   不落盘、不写 `project.godot`）；真正驱动画面分辨率的是 `stretch_shrink` → `SubViewport.size`。
   本轮四项读回全变化，画面差异由 shrink + fx_profile 共同产生，不夸大单项作用。
6. **帧区间 1 帧偏移**：见 §⑤，脚本帧游标与 Movie Maker 帧号起点不同，以像素量化实测分组为准。
7. **既有 WARNING（非本轮引入、非 ERROR）**：交互 / 回归日志含工程既有
   `ObjectDB instances were leaked` 等（不改退出码）；抓帧日志 `0 WARNING / 0 ERROR / 0 SCRIPT ERROR`。
   未处理、未冒充全绿。
8. **按约束未做 / 未写**：真机鼠标点击、人工试玩逐帧动态验收、逐帧时间性能实测、GUI 交互录制；
   不新建只读探针 / 巡检脚本、不主动扫目录做进度巡检；零付费 / 零外部素材 / 零付费生成服务 /
   零插件 / 未新增 autoload / 未新增 class_name；不写 `project.godot`、`hud.gd`、`hd2d_fx.*`、
   `verify_frame_data.gd`、`capture/CAPTURE-REPORT.md`、`godot/test/`；不伪造产物、不谎报成功；
   不自行 `git commit` / `git push`（由总指挥收尾）。

---

## 结论

R22 闭环：新增 `verify_quality_interaction.gd` 真跑 `courtyard.tscn`，脚本注入 `pressed` 信号
（如实：非鼠标点击）依次切 low/medium/high，**19 PASS / 0 FAIL**；`[R22_QUALITY]` 三档证据
读回 controller 档位与四项渲染参数全部符合冻结口径，并真实触发 R21 缺失的「选择画质档」日志；
Movie Maker 抓帧 **13 张** `r22_quality_00000000~00000012.png`（+3 张真实帧复制的档位展示图），
Pillow 量化三段分明 + ViewImage 目视确认三档可读性差异；三段门禁真实 EXIT **0/0/0**、
7 份日志 `SCRIPT ERROR=0`；`verify_fx_profile.gd` **34 PASS**、`verify_fx_mobile.gd` **47 PASS** 不回退。

`status=done` 指本轮「信号注入交互证据 + 三档读回 + 画面档位变化 + 门禁 + 回归 + 验收文档」闭环，
**不代表**「真机鼠标点击已实证」（见 ⑦-1）。
