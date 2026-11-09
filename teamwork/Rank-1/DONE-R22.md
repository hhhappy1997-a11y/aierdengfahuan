# DONE-R22.md · Rank-1 引擎架构与渲染（画质菜单真实交互验收）

> 命令 `cmd-20261109-124640-130-A1` · `[ROUND=R22]` · AI=1（Rank-1）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`，`--version` EXIT=0）
> 工程根 `F:/Game/aierdengfahuan/godot`；回执目录 `F:/Game/aierdengfahuan/teamwork/command_center/`
> 详细验收证据见 `teamwork/Rank-1/QUALITY-INTERACTION-R22.md`（本文件为交付结论摘要）。
> 目录所有权：**未写** `project.godot`（工程冻结，mtime 停在 11:14 派单前）、`hud.gd`、
> `hd2d_fx.gd`/`hd2d_fx.tscn`、`verify_frame_data.gd`、`capture/CAPTURE-REPORT.md`、`godot/test/`。

---

## ① 实际交付文件清单

| 类别 | 文件 | 说明 |
|---|---|---|
| 新增验证脚本 | `godot/scripts/verify_quality_interaction.gd` | `extends SceneTree`；真跑加载 `courtyard.tscn`、找 `QualitySettings` 实例三个 Button、脚本 `Button.pressed.emit()` 注入 pressed 信号（如实：非鼠标点击）依次切 low/medium/high；每档读回 controller 档位 + `low_resolution_size` / `scaling_3d` / `stretch_shrink` / SubViewport 实际尺寸；`[R22_QUALITY]` 每档 stdout；GDScript 类型标注完整；19 PASS/0 FAIL |
| 引擎自动产物 | `godot/scripts/verify_quality_interaction.gd.uid` | 19 字节，G1 `--headless --import` 自动生成，非手写 |
| 真跑日志 | `teamwork/Rank-1/r22_*.log`（7 份） | `r22_gate_import` / `r22_gate_checkonly` / `r22_gate_quit` / `r22_interaction` / `r22_capture` / `r22_regress_verify_fx_profile` / `r22_regress_verify_fx_mobile`，均为最终版真跑 stdout |
| 抓帧产物 | `capture/r22_quality_00000000.png` ~ `r22_quality_00000012.png`（13 张） | Movie Maker `--write-movie ... r22_quality_.png --fixed-fps 30` 真实产出的编号序列，1280×720 |
| 抓帧自动产物 | `capture/r22_quality_.wav` | 166444 字节，Movie Maker 自动音频轨，引擎产物非手写 |
| 档位展示图 | `capture/r22_quality_low.png` / `r22_quality_medium.png` / `r22_quality_high.png` | 由 `00000002` / `00000006` / `00000010` **原样复制**（md5 逐对一致），真实帧、非伪造、非重新渲染 |
| 验收文档 | `teamwork/Rank-1/QUALITY-INTERACTION-R22.md` | 每档真跑 stdout、抓帧文件名、像素/可读性对比、未完成项 |
| 交付文档 | `teamwork/Rank-1/DONE-R22.md` | 本文件 |
| 回执 | `teamwork/command_center/ai/1/outbox/cmd-20261109-124640-130-A1.json` | 按本轮 id 写入精确路径（在 `teamwork/command_center/` 下，非工程根 `command_center/`） |

**本轮零改动**：`project.godot`、`courtyard.tscn`、`quality_settings.gd` / `quality_settings.tscn`、
`hud.gd`、`hd2d_fx.*`、`verify_frame_data.gd`、`capture/CAPTURE-REPORT.md`、`godot/test/`。

---

## ② 真跑输出结论

### 2.1 三段门禁（真实 EXIT）

| 段 | 命令 | EXIT |
|---|---|---|
| G1 | `--headless --path <root> --import` | **0** |
| G2 | `--headless --path <root> --check-only --script res://scripts/verify_quality_interaction.gd` | **0** |
| G3 | `--headless --path <root> --quit` | **0** |

### 2.2 `grep SCRIPT ERROR` 结论

对最终版 7 份 `r22_*.log` **逐文件**精确 grep `SCRIPT ERROR|Parse Error`：**全部 0 条**。
交互验证 / 抓帧运行 / 两份回归均 `SCRIPT ERROR=0`；抓帧日志 `0 WARNING / 0 ERROR`。

### 2.3 交互验证（本轮核心）

`verify_quality_interaction.gd` 真跑 EXIT=0，`==== [R22] SUMMARY pass=19 fail=0 total=19 ====` /
`==== [R22] RESULT=PASS ====`。脚本注入 pressed 信号真实触发 R21 缺失的回调链路，
stdout 出现三条 `[R21_QUALITY] 选择画质档 preset=low|medium|high | 链路 set_quality→apply→re_evaluate 完成`。

`[R22_QUALITY]` 三档证据（运行期实际回读，全部符合冻结口径）：

| 档位 | fx_profile_active | low_resolution_size | scaling_3d/scale | stretch_shrink | SubViewport 实际渲染 |
|---|---|---|---|---|---|
| low | mobile | (480, 270) | 0.75 | 3 | (426, 240) |
| medium | desktop | (640, 360) | 0.85 | 2 | (640, 360) |
| high | desktop | (960, 540) | 1.0 | 1 | (1280, 720) |

### 2.4 Movie Maker 抓帧 · EXIT=0

命令（与交互验证同一脚本同一运行，**不带 `--headless`**，一次只跑一个 GPU 任务）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot \
  --script res://scripts/verify_quality_interaction.gd \
  --write-movie F:/Game/aierdengfahuan/capture/r22_quality_.png --fixed-fps 30
```

stdout：`Movie Maker mode enabled, recording movie in 1280×720 @ 30 FPS...` /
`Done recording movie ... 13 frames at 30 FPS`。产出 **13 张** `r22_quality_00000000~00000012.png`
（+ `.wav`）+ 3 张档位展示图，全部真实 Movie Maker 输出 / 真实帧复制。

### 2.5 画面档位变化 · 双重实证

**Pillow 量化**（13 帧，段内静态、段间阶梯突变）：

| 档位 | 帧段 | 字节 | 边缘能量 | 水平相邻相等 | 唯一颜色数 |
|---|---|---|---|---|---|
| low | `00000000~00000003` | 66572（全同） | 12.397 | 0.955 | 3319 |
| medium | `00000004~00000007` | ~125670 | 17.658 | 0.932 | ~7620 |
| high | `00000008~00000012` | ~221060 | 23.931 | 0.918 | ~14650 |

**ViewImage 目视**（三张代表帧，产出先目视再接入）：三帧均完整渲染（天空 / 暖金砖地 /
像素骑士 / HUD「赐福 · 宁姆格福」/ 右上画质面板 + 低中高三按钮可读），**非启动帧**；
low 最糊、HUD 相对最大、无体积光与光尘（mobile 四项全关）；medium 居中、出现淡光柱与光尘；
high 最锐利、金色光柱与光尘最明显（desktop 四项全开）。

### 2.6 现有回归脚本（不回退）

| 脚本 | EXIT | 结果 |
|---|---|---|
| `verify_fx_profile.gd` | **0** | `SUMMARY pass=34 fail=0 total=34`、`RESULT=PASS` |
| `verify_fx_mobile.gd` | **0** | `SUMMARY pass=47 fail=0 total=47`、`RESULT=PASS` |

**34 PASS / 47 PASS 未回退**，两份 `SCRIPT ERROR=0`。

---

## ③ 未完成项与阻塞

**阻塞：无**（本轮四路门禁、交互、抓帧、回归、文档、回执均闭环）。

如实登记的未完成项 / 边界（详见 `QUALITY-INTERACTION-R22.md` §⑦）：

1. **信号注入 ≠ 鼠标点击**：三档切换全部由脚本 `Button.pressed.emit()` 注入触发，
   **如实声明不是 `InputEventMouseButton` 真机鼠标点击**；未做 GUI 人工点击 / 真机点击的 stdout 实证。
   R21 的「未发生真实点击」升级为「信号注入触发真实回调链路 + 画面档位变化」，未冒充鼠标点击。
2. **按钮无「选中」视觉反馈**：信号注入只触发回调链路、不改按钮外观；三档帧中右上画质面板
   三按钮外观一致。证明的是「链路生效 + 画面变化」，非「点击视觉反馈」。
3. **Movie Maker 输出恒 1280×720**：13 帧 IHDR 全部 1280×720；差异来自内部 SubViewport
   渲染分辨率（426×240/640×360/1280×720）与 fx_profile 光效开关，非输出尺寸变化；
   继承 R21 已查清边界，**不冒充「引擎输出 640×360」**。
4. **`low_resolution_size` 与 SubViewport 实际尺寸不一致**（low 480×270→426×240、
   high 960×540→1280×720），因 `stretch=true` 时引擎按 container/shrink 计算；既有行为，如实回读、未改。
5. **`scaling_3d/scale` / `low_resolution_size` 为 ProjectSettings 运行期改写**（读回真实变化、不落盘、
   不写 `project.godot`）；真正驱动画面分辨率的是 `stretch_shrink` → `SubViewport.size`。
6. **帧区间 1 帧偏移**：脚本帧游标（自 1 计）与 Movie Maker 帧号（自 0 计）起点不同，
   以像素量化实测分组为准，不硬套帧号。
7. **既有 WARNING（非本轮引入、非 ERROR）**：交互 / 回归日志含工程既有
   `ObjectDB instances were leaked` 等（不改退出码）；抓帧日志 0 WARNING。未处理、未冒充全绿。
8. **按约束未做 / 未写**：真机鼠标点击、人工试玩逐帧动态验收、逐帧时间性能实测、GUI 交互录制；
   不新建只读探针 / 巡检脚本、不主动扫目录做进度巡检；零付费 / 零外部素材 / 零付费生成服务 /
   零插件 / 未新增 autoload / 未新增 class_name；不写禁写清单文件；不伪造产物、不谎报成功；
   不自行 `git commit` / `git push`。

---

## 结论

R22 主任务闭环：新增 `verify_quality_interaction.gd` 真跑 `courtyard.tscn`，脚本注入 `pressed`
信号（如实：非鼠标点击）依次切 low/medium/high，**19 PASS / 0 FAIL**；`[R22_QUALITY]` 三档证据
读回 controller 档位与四项渲染参数全部符合冻结口径，并真实触发 R21 缺失的「选择画质档」日志；
Movie Maker 抓帧 **13 张** `r22_quality_00000000~00000012.png`（+3 张真实帧复制的档位展示图），
Pillow 量化三段分明 + ViewImage 目视确认三档可读性差异；三段门禁真实 EXIT **0/0/0**、
7 份日志 `SCRIPT ERROR=0`；`verify_fx_profile.gd` **34 PASS**、`verify_fx_mobile.gd` **47 PASS** 不回退。

`status=done` 指本轮「信号注入交互证据 + 三档读回 + 画面档位变化 + 门禁 + 回归 + 文档 + 回执」闭环，
**不代表**「真机鼠标点击已实证」（见 ③-1）。

> 证据：`teamwork/Rank-1/r22_*.log`（7 份）、`QUALITY-INTERACTION-R22.md`、
> `capture/r22_quality_0000000*.png` + `r22_quality_low/medium/high.png` + `r22_quality_.wav`、
> `godot/scripts/verify_quality_interaction.gd`（+ `.uid`）。

---

## ④ 回执路由状态（收尾复核追加，不改动上文结论）

- 回执按本轮 id 写入精确路径 `teamwork/command_center/ai/1/outbox/cmd-20261109-124640-130-A1.json`
  （**在 `teamwork/command_center/` 下，非工程根 `command_center/`**）；写入成功后被调度中枢
  **即时消费**，outbox 现为空，归档到
  `teamwork/command_center/dispatcher/receipts/cmd-20261109-124640-130-A1.json`（与 R20 / R21 同现象）。
- 只读复核归档件：JSON 合法，`task_id=cmd-20261109-124640-130-A1` / `ai=1` / `status=done` /
  `result` 引用 DONE-R22.md 实际结论，字段与本工位写入一致。
- 工程根 `F:/Game/aierdengfahuan/command_center/` **不存在**，未误写到工程根；按派单
  「outbox 空但 receipts 归档存在即视为已送达」，未重复投递、未改写归档件；
  `dispatcher/receipts/` 不在本轮可写范围。
