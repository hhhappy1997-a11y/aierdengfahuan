# DONE-R21 · Rank-1 引擎架构与渲染（画质设置菜单 UI 化）

> 命令 `cmd-20261109-115818-630-A1` · `[ROUND=R21]` · AI=1（Rank-1）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`，`--version` EXIT=0）
> 工程根 `F:/Game/aierdengfahuan/godot`；回执目录 `F:/Game/aierdengfahuan/teamwork/command_center/`
> 目录所有权：本轮只写 `godot/scenes/quality_settings.tscn`、`godot/scripts/quality_settings.gd`（本 Rank 独占）；
> `godot/scenes/courtyard.tscn` 归本 Rank 但**保持零改动**。
> **未写** `project.godot`、`hud.gd`、`save_delta_writer.gd`、`hd2d_fx.gd`/`hd2d_fx.tscn`、
> `verify_frame_data.gd`（其它 Rank 并发写入）。

---

## ① 实际交付文件清单

| 类别 | 文件 | 说明 |
|---|---|---|
| 修改场景 | `godot/scenes/quality_settings.tscn` | CanvasLayer 根 `QualitySettings`（`layer=40` 保证置顶可见）下补齐真实可见控件：`QualityPanel`(PanelContainer) + `VBox` + 金色中文 `TitleLabel`「画质设置 · 低 / 中 / 高」 + `ButtonRow` + 三个 Button「低」「中」「高」；新增 2 个 `StyleBoxFlat` 子资源（面板深蓝底 `Color(0.07,0.1,0.16,1)` + 金色 1px 边框 `Color(0.83,0.68,0.3,1)`；按钮深蓝底 + 同色金边）；标题/按钮 `font_color` 金色。共 8 个 `[node]` 段 |
| 修改脚本 | `godot/scripts/quality_settings.gd` | **去掉** R20 `_ready()` 的 `set_quality("low")→apply()→set_quality("high")→apply()` 自动演示序列；**保留** `set_quality(preset)`/`apply()`/`get_quality_preset()` 三 API 原样（含 R20 运行期改写低分辨率/缩放 + controller 重判）。新增：`_bind_buttons()` 连接三 Button.pressed、`_on_quality_button_pressed(preset)` 回调（set_quality→apply→`_notify_re_evaluate()`→打印 `[R21_QUALITY]` 选择日志）、`_log_ui_ready()`（UI 就绪日志 + `CACHE_MODE_IGNORE` 回读节点数）、`_readback_courtyard_node_count()` |
| 保持不变 | `godot/scenes/courtyard.tscn` | 第 13 行 `ext_resource quality_settings.tscn id="10_r20qs"`、第 144 行 `[node name="QualitySettings" parent="." instance=ExtResource("10_r20qs")]` 逐字保留，本轮零写入 |
| 真跑日志 | `teamwork/Rank-1/r21_*.log`（6 份） | `r21_gate_import.log` / `r21_gate_checkonly.log` / `r21_gate_quit.log` / `r21_regress_verify_fx_profile.log` / `r21_regress_verify_fx_mobile.log` / `r21_capture.log`，均为最终版真跑 stdout |
| 抓帧产物 | `capture/r21_quality00000000.png` ~ `r21_quality00000005.png`（6 帧）+ `capture/r21_quality.wav` | Movie Maker 以 `capture/r21_quality.png` 为 `--write-movie` 前缀实际输出（沿用 R14~R20 口径） |
| 交付文档 | `teamwork/Rank-1/DONE-R21.md` | 本文件 |
| 回执 | `teamwork/command_center/ai/1/outbox/cmd-20261109-115818-630-A1.json` | 按本轮 id 写入，精确路径在 `teamwork/command_center/` 下，仅一份 |

**UI 位置（避开 HUD 主面板矩形 x<730,y<220）**：`QualityPanel offset=(760,32)-(1244,176)`，整块落在 `x>730` 右侧区域（1280×720 viewport），与左上 HUD `HudPanel (24,24)-(364,108)` 完全不重叠；CanvasLayer `layer=40` 保证绘制在 SubViewportContainer 之上。

---

## ② 真跑输出结论

### 2.1 三段门禁（真实 EXIT）

| 段 | 命令 | EXIT |
|---|---|---|
| G1 | `--headless --path <root> --import` | **0** |
| G2 | `--headless --path <root> --check-only --script res://scripts/quality_settings.gd` | **0** |
| G3 | `--headless --path <root> --quit` | **0** |

G2 EXIT=0 实证改写后脚本 Godot 4.7.2 语法合法；G3 运行 `Main.tscn`（主场景），EXIT=0。

### 2.2 `grep SCRIPT ERROR` 结论

对 6 份 `teamwork/Rank-1/r21_*.log` **逐文件**精确 grep `SCRIPT ERROR|Parse Error`：**全部 0 条**。
如实登记的 WARNING（均非 ERROR、不改退出码）：`r21_gate_quit.log` 1 条（工程既有 `ObjectDB instances were leaked`，R9~R20 即有）；两个 verify 各 2 条（工程既有 `ChunkManager 未找到 ChunkRoot` / `ObjectDB leaked`）；最终版 `r21_capture.log` **0 WARNING / 0 ERROR / 0 SCRIPT ERROR**；G1/G2 日志 0 ERROR / 0 WARNING。

### 2.3 现有回归脚本（不回退）

| 脚本 | EXIT | 结果 |
|---|---|---|
| `verify_fx_profile.gd` | **0** | `SUMMARY pass=34 fail=0 total=34`、`RESULT=PASS` |
| `verify_fx_mobile.gd` | **0** | `SUMMARY pass=47 fail=0 total=47`、`RESULT=PASS` |

两个 verify 全绿，34 PASS / 47 PASS **未回退**（底层 desktop 四项全开 / mobile 四项全关功能正常）。

### 2.4 节点数（CACHE_MODE_IGNORE 真跑回读，如实登记）

| 校验点 | 实际值 |
|---|---|
| `courtyard.tscn` 落盘文本 `grep -c "^\[node "` | **25** |
| 引擎 `CACHE_MODE_IGNORE` 磁盘回读（`quality_settings.gd::_readback_courtyard_node_count()` → r21_capture.log 第 20 行 stdout） | `SceneState node_count=` **25** |
| R20 登记 | 25 |

**登记为 25，未冒充 24、未虚报变化。** 说明：本轮 `courtyard.tscn` 零改动，QualitySettings 仍是 `instance=` 引用；`quality_settings.tscn` 内部新增的 8 个控件节点属于被引用子场景展开内容，**不计入 `courtyard.tscn` 自身 SceneState 节点数**，故回读仍为 25。`_ready()` 内以 `ResourceLoader.load("res://scenes/courtyard.tscn", "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)` 强制绕过缓存重解析磁盘文件、只读 `get_state().get_node_count()`，不 instantiate、不写盘。

### 2.5 Movie Maker 抓帧 · EXIT=0

命令（沿用 R14~R20 口径：绝对路径 + `.png` 前缀、**不带 `--headless`**）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot --write-movie F:/Game/aierdengfahuan/capture/r21_quality.png --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn
```

产出：6 帧 1280×720 PNG（字节 125657~125796 互异）+ `r21_quality.wav`；首帧 PNG 头 `89 50 4e 47 0d 0a 1a 0a 00 00 00 0d 49 48 44 52` = 合法 PNG 签名 + IHDR。
`Done recording movie ... 6 frames at 30 FPS ... recorded in 00:00:03`。

**stdout `[R21_QUALITY]`（r21_capture.log 第 16~20 行，共 5 条，满足「至少一条」）**：

```
[R21_QUALITY] 已连接按钮 QualityPanel/VBox/ButtonRow/BtnLow -> 档位 low
[R21_QUALITY] 已连接按钮 QualityPanel/VBox/ButtonRow/BtnMedium -> 档位 medium
[R21_QUALITY] 已连接按钮 QualityPanel/VBox/ButtonRow/BtnHigh -> 档位 high
[R21_QUALITY] 画质设置菜单 UI 就绪 | panel=true rect=(760,32)-(1244,176) | title=画质设置 · 低 / 中 / 高 | buttons=[low{text=低 visible=true} | medium{text=中 visible=true} | high{text=高 visible=true}]
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=25（R20 登记 25，如实回读不冒充）
```

### 2.6 UI 控件在画面可见 · 双重实证

**(A) Pillow 像素统计**（首帧 `r21_quality00000000.png`，ROI = 面板矩形 `(760,32)-(1244,176)`，金色目标 `(212,173,77)`、深蓝目标 `(18,26,41)`）：

| 指标 | R21（有 UI） | R20 同区域对照（无 UI） |
|---|---|---|
| ROI 金色像素 | **3828** | **0** |
| ROI 深蓝像素 | **44759** | **0** |
| 顶边 `y=32` 金色 | **484 / 484**（整行命中） | 0 / 484 |
| 底边 `y=175` 金色 | **484 / 484**（整行命中） | 0 / 484 |
| 左边 `x=760` 金色 | **144 / 144**（整列命中） | 0 |
| 右边 `x=1243` 金色 | **144 / 144**（整列命中） | 0 |
| 按钮上下边框行 | `y=75` 452、`y=122` 452 金色像素 | 无 |

四条 1px 金色边框 **全像素命中**，加上 3 个按钮的边框长行，实证深蓝底 + 金色 1px 边框矩形被真实绘制；R20 无 UI 帧同区域金色/深蓝均为 0，证明该 UI 是本轮新增、非画面既有内容。

**(B) ViewImage 真看**：右上方清晰可见深蓝底、金色 1px 边框的面板，金色中文标题「画质设置 · 低 / 中 / 高」与三个金色边框按钮「低」「中」「高」中文可读；与左上角 HUD 面板「赐福 · 宁姆格福」分离、无重叠，落在 `x>730` 区域。中文字形由 Godot 默认主题的系统字体回退渲染（实测可读），**未引入任何外部/付费字体素材**。

---

## ③ 未完成项与阻塞（如实）

1. **按钮「选择日志」未在本次抓帧 stdout 出现**：Movie Maker `--write-movie` 为无交互自动录制（无鼠标输入），`_on_quality_button_pressed()` 回调未在抓帧中触发，故 `[R21_QUALITY] 选择画质档 ...` 这条选择日志未出现。回调链路（set_quality → apply → `fx_profile_controller.re_evaluate()` → 选择日志）**代码已接线**且 G2 `--check-only` 语法校验 EXIT=0；stdout 的 5 条 `[R21_QUALITY]` 来自 `_ready()` 的 UI 就绪 / 按钮连接 / 节点数回读日志（真实事件，非伪造）。按约束**未新建探针/巡检脚本、未用自动演示序列冒充点击**；如需「真机点击产生选择日志」的 stdout 实证，需带交互的 GUI 运行或总指挥另行派单。
2. **既有 WARNING（非本轮引入、非 ERROR）**：G3 1 条 `ObjectDB leaked`、两个 verify 各 2 条（`ChunkManager 未找到 ChunkRoot` / `ObjectDB leaked`）；抓帧日志 0 WARNING。未处理、未冒充全绿。
3. **并发写入观察**：真跑期间 `hud.gd`（mtime 12:06:30）、`verify_frame_data.gd`（mtime 12:07:04）发生变化，系 Rank-3 / Rank-2 并发写入，本轮**全程未触碰**；`project.godot` 本轮无人写。
4. **画质档映射仍为冻结口径**：low→mobile（四项全关）/ medium|high→desktop（四项全开）；§4.3「移动档降级而非全关」仍未实现（非本单范围）。
5. **按约束未做**：不新建只读探针/巡检脚本、不主动扫目录做进度巡检；零付费 / 零外部素材 / 零外部生成服务 / 零插件 / 未新增 autoload；不伪造产物、不谎报成功；中文 UTF-8、Godot 4.7.2 合法语法（G2 EXIT=0）；不写其它工位 / 总线 / 台账；不自行 `git commit` / `git push`。

---

## 结论

R21 主任务闭环：`quality_settings.tscn` 补真实可见控件（金线深蓝、中文标题 + 低/中/高三按钮、位置避开 HUD 主面板矩形 `x<730,y<220`）；`quality_settings.gd` 去掉 `_ready()` 自动演示序列、保留三 API、接按钮回调并打印 `[R21_QUALITY]`；`courtyard.tscn` 保持 QualitySettings 实例化节点零改动，节点数经 `CACHE_MODE_IGNORE` 真跑回读 **25**，如实登记、未冒充。

三段门禁真实 EXIT **0/0/0**；6 份 `r21_*.log` 逐文件 grep `SCRIPT ERROR|Parse Error` **全 0**；`verify_fx_profile.gd` **34 PASS**、`verify_fx_mobile.gd` **47 PASS** 不回退；Movie Maker 抓帧 **EXIT=0** 产出 6 帧 1280×720 PNG + wav，stdout **5 条 `[R21_QUALITY]`**；Pillow 像素统计（四条 1px 金边全命中、R20 同区域对照为 0）+ ViewImage 真看 **双重实证 UI 控件在画面可见**。

`status=done` 指本轮「UI 化 + 门禁 + 回归 + 抓帧 + 可见性实证」闭环，**不代表**「按钮已在真机被点击并产生选择日志」（无交互抓帧未触发，见 ③-1）。

> 证据：`teamwork/Rank-1/r21_gate_*.log`、`r21_regress_*.log`、`r21_capture.log`、`capture/r21_quality0000000*.png` + `r21_quality.wav`、`godot/scenes/quality_settings.tscn`、`godot/scripts/quality_settings.gd`、`godot/scenes/courtyard.tscn`。

---

## ④ 回执路由状态（收尾复核追加，不改动上文结论）

- 回执按本轮 id 写入精确路径 `teamwork/command_center/ai/1/outbox/cmd-20261109-115818-630-A1.json`（**在 `teamwork/command_center/` 下，非工程根 `command_center/`**），仅一份；写入后被调度中枢**即时消费**，outbox 现为空，归档到 `teamwork/command_center/dispatcher/receipts/cmd-20261109-115818-630-A1.json`（与 R20 同现象）。
- 只读复核归档件：JSON 合法，`task_id=cmd-20261109-115818-630-A1` / `ai=1` / `status=done` / `result` 引用 DONE-R21.md 实际结论，字段与本工位写入一致。
- 工程根 `F:/Game/aierdengfahuan/command_center/` **不存在**，未误写到工程根；按派单「outbox 空但 receipts 归档存在即视为已送达」，未重复投递、未改写归档件；`dispatcher/receipts/` 不在本轮可写范围。
