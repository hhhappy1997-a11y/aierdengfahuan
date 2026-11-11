# V070-RUNTIME-REVIEW.md · R29 v0.7.0 15 秒实机录屏运行期目视复核

> 派单 `cmd-20261111-112804-021-A4` · `[ROUND=R29]` · Rank-4（美术管线与工具链）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable）/ ffmpeg 9.0.2（本机绝对路径 `C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`，Bash PATH 里没有）
> 真跑产物：`capture/v070_demo*.png` **450 帧** @30fps/15s；`capture/v070_demo.mp4` **935,921 字节**
> 结论以 **ViewImage 真看首 0 / 中 225 / 尾 449 三帧 + 像素采样 A/B + `capture/r29_capture.log` 逐帧日志 + 三段门禁/回归日志** 为准，不粉饰、不谎报、不把 2D 全屏后处理叫「真 3D 光效」。

---

## 1. 真跑与产物（非伪造）

| 项 | 实测 |
|---|---|
| 录屏命令 | `--path <godot> --write-movie capture/v070_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`，沿用 R22/R25/R26/R27/R28 定稿） |
| 录屏 EXIT / 帧数 | **0** / **450 帧**（`v070_demo00000000.png … v070_demo00000449.png`），`Movie Maker 1280×720 @ 30 FPS / 15.000000s` |
| 录屏日志 | `SCRIPT ERROR\|Parse Error` = **0**；`[R29][DEPTH]` / `[R29][GRADE]` / `[R29][DEPTH] 画质档切换` / `[R29][FINALE]` 均在；`busy` / `leaked` / `ERROR` 在正式 450 帧录屏中**均未出现**（短跑 30 帧曾出现，见 §7） |
| ffmpeg | 绝对路径 9.0.2：`-framerate 30 -start_number 0 -i v070_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，**EXIT=0** |
| ffprobe 视频 | `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000`；`moov` 前置 |
| **MP4 字节数** | **`capture/v070_demo.mp4` = 935,921 B** |
| **WAV 是否混入 MP4** | **未混入**：ffmpeg 输入仅 PNG 序列、无任何音频 `-i`；`ffprobe -select_streams a` 音频流计数 = **0**。如实登记，不谎报音视频合并 |

---

## 2. shader 是否生效（裁决 A30 核心，如实登记）

### 2.1 实现（P2 全屏 shader 小样）

- 新增 `godot/shaders/v070_depth_grade.gdshader`：`shader_type canvas_item`，使用 **`uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest` + `SCREEN_UV`** 做一次全屏采样，一 pass 实现「① 多层视差景深（上部远景 4-tap 轻模糊 + 降饱和 + 冷雾）② 边缘暗角（宽高比校正径向压暗）③ 冷夜雾（近景底部薄雾）④ 暖金光晕（随点亮态/波次平滑递进）⑤ 三波完成一次性收束扩散环」。
- 新增 `CanvasLayer(layer=12)` + `ColorRect`（铺满、`mouse_filter=IGNORE`、`color` 透明以在 shader 失效时零遮挡）+ `ShaderMaterial`，由 `hd2d_parallax.gd::_r29_init()` **运行时 `call_deferred("add_child", layer)` 创建**（`_ready()` 内直接 `add_child` 会触发 `Parent node is busy setting up children`，故延迟挂载）。
- **绝不写 `courtyard.tscn` 的 `[node` 条目**：磁盘场景节点数恒 **41**，`verify_wave_runtime_v040`（`NODE_COUNT_AFTER=41`）与 `verify_tutorial_restart_v060`（`NODE_COUNT_EXPECTED=41`）的断言不回退（§7 实证）。
- `layer=12` < `Hud(20)` / `WaveTrialHud(20)` / `TutorialHud(21)` / `QualitySettings(40)`：全屏层**不遮挡 HUD**，HUD 文字保持锐利。
- 与既有 `hd2d_fx.gd` 四项光效（倒影/体积光/光尘/bloom）**零冲突**：`hd2d_fx.gd` 本轮 **未改一字**（mtime 仍 2026-11-09），desktop 档四项全开效果不回退；新层只是叠在其上的一次后处理。

### 2.2 判定：**Compatibility 后端 screen texture 可用，shader 生效**（非降级）

证据链（不靠主观推断，不谎称）：

1. **编译**：三段门禁 G1 `--headless --import`、正式录屏 `r29_capture.log`、30 帧短跑 `r29_probe.log` 中**均无** shader 编译错误 / `SCREEN_TEXTURE` 未定义 / `hint_screen_texture` 报错；`SCRIPT ERROR=0`。
2. **挂载**：`[R29][GRADE] shader 小样已挂载 | layer=12 rect=V070DepthGradeRect`。短跑日志中的 `ERROR: Parent node is busy setting up children, add_child() failed` 经 GDScript backtrace 确认来自 **`res://scripts/hud.gd:795 _ensure_shop_readable()`（Rank-1 并发件）**，非本层；本层已改 `call_deferred` 且正式录屏日志中该错误已消失（Rank-1 亦已修好）。
3. **像素 A/B（R28 `v060_demo00000000.png` → R29 `v070_demo00000000.png`，避开 HUD 面板的边缘点）**：左右边缘 `(5,360) -39.7`、`(1275,360) -18.3`，下部 `(10,710)/(1270,710) -20.0`，`(320,650)/(960,650) -12.0`，四角 `(10,10) -1.7`，而**上部中心 `(640,100) 0.0`** —— 呈典型「边缘压暗、中心/上部不变」的径向暗角特征。若 `ColorRect` 未铺满或 screen texture 采样失效（返回黑/洋红/未编译），不可能出现这种规律的径向压暗且画面仍完整。
4. **参数注入生效**：录屏日志 `总命中=20`、双档切换（`f=173 → mobile vignette=0.120`、`f=279 → desktop vignette=0.240`），证明 ShaderMaterial uniform 被逐帧真实写入。

> 口径澄清：这里的「shader 生效」指 **Compatibility 后端一次全屏 screen-reading 后处理真的在画面上起作用**，**不是**真 3D 景深 / 体积光 / bloom；四项观感仍全部是 2D 程序化近似（§6 HD-2D 全绿未达）。

### 2.3 降级路径（已实现、本轮未启用，如实登记）

`hd2d_parallax.gd::_r29_draw_grade()` 提供等价的程序化 `_draw()` 强化层（暗角 6 层四边框 / 冷夜雾带 / 远景 3 层冷蓝降饱和 / 暖金同心圆 / 收束 `draw_arc` 扩散环），开关 `GRADE_FORCE_DRAW_FALLBACK`（当前 `false`）。因 §2.2 判定 screen texture 可用，**本轮未降级、该 `_draw()` 强化层未经真跑目视**，如实登记为「备用降级路径，未启用、未验证画面」；不把它算作已交付的画面效果。

---

## 3. 景深与光色参数（读 Rank-2 `depth_profile.tres`，不硬编码）

- **并发时序（如实）**：本轮开跑时 `godot/data/render/depth_profile.tres` 尚未落盘；执行期间 Rank-2 落盘（mtime `2026-11-11 11:39`）。故本实现同时具备「未落盘 → 自带 `[PLACEHOLDER]` 安全默认参数 + 不等待、不伪造」与「落盘 → 真读参数表」两条路径；正式录屏走的是**真读**路径（`[R29][DEPTH] 参数表已读取 … 总命中=20 | 生效来源=res://data/render/depth_profile.tres`）。
- 参数表实际结构：`[resource]` 顶层 + `desktop` / `mobile` 两个子 `DepthProfile` Resource。脚本 `_r29_map_profile()` 逐字段映射到 shader uniform（顶层字段结构容错 + 子档覆盖），**shader 内所有 uniform 一律不带默认值，全部由 `set_shader_parameter` 注入** → 生效数值不硬编码于 shader。

| 参数表字段 | 映射到的 shader uniform | desktop 实测 | mobile 实测 |
|---|---|---|---|
| `vignette_strength` | `vignette_strength` | 0.240 | 0.120 |
| `warm_glow_strength` | `warm_glow_strength` | 0.450 | 0.220 |
| `fog_density` | `cool_fog_strength`（×5 `[PLACEHOLDER]` 量纲换算） | 0.175 | 0.090 |
| `cold_night_fog_color` | `cool_fog_color`（hex → vec3） | `#2B3A5C` | `#2B3A5C` |
| `warm_gold_key_color` | `warm_glow_color`（hex → vec3） | `#F0A94C` | `#F0A94C` |
| `layer_depths[0]` | `depth_far_strength`（×0.4） | 0.100 | 0.140 |
| `parallax_coefficients[0]` | `blur_radius`（×25，低分辨率缓冲 1.5px 口径） | 1.50 | 1.25 |

- 参数表无对应字段、由 `[PLACEHOLDER]` 安全默认补齐：`vignette_inner=0.34` / `vignette_outer=0.78` / `warm_glow_pos=(0.706,0.256)`（对齐 `hd2d_fx.gd` 的 `LIGHT_POS(452,92)/640×360`）/ `bloom_threshold=0.75`（与 `FXBloom` 仅暖金过阈口径对齐）。
- 上述派生系数 `×5 / ×0.4 / ×25` 与全部默认数值均标 `[PLACEHOLDER]`、待试玩校准，rationale 写在 `hd2d_parallax.gd` 注释与 `DONE-R29.md`。
- 双档按 `QualitySettings.get_quality_preset()` 逐帧选择（`low/mobile → mobile`，否则 `desktop`），段 A/C 用 desktop、段 B 用 mobile，录屏日志可见两次切换。

---

## 4. ViewImage 首 / 中 / 尾三帧（真看，逐帧记录）

| 帧 | 段 / 波 / 画质 | 赐福标题 | 底部动作帧 HUD | 兑换面板 | 波次 WaveLabel |
|---|---|---|---|---|---|
| **首 0** | 段 A / 第 1/3 波 / desktop-medium | 「赐福 · 关卡前」**亮金** | `玩家 HP 100/100 \| Boss HP 100% \| **动作 attack_light 1/27** \| 闪避 0 \| 命中 0 \| 进行中` | 「赐福成长 · 按 E 打开兑换」提示态（大黑框） | `第 1/3 波 \| 赐福点数 0 \| 倒计时 0.0 \| 历史最佳 0` |
| **中 225** | 段 B / 第 2/3 波 / low-mobile | 「赐福 · 巡礼教堂」**亮金** | `玩家 HP 108/120 \| Boss HP 100% \| **动作 roll 6/22** \| 闪避 2 \| 命中 4 \| 进行中` | **清晰可辨 5 行**（见下） | `第 2/3 波 \| 赐福点数 0 \| 倒计时 29.0 \| 历史最佳 1` |
| **尾 449** | 段 C / 第 3/3 波 / desktop-high | 「赐福 · 希芙拉河井底」亮金（暖紫背景下目视偏暗，像素仍 GOLD） | `玩家 HP 108/120 \| Boss HP 0% \| **动作 roll 8/22** \| 闪避 2 \| 命中 5 \| 胜利 · 已落盘` | **清晰可辨 5 行** | `第 3/3 波 \| 赐福点数 350 \| 倒计时 0.0 \| 历史最佳 3` |

中/尾帧兑换面板 5 行（目视逐字可读）：
`赐福成长 ｜ 当前余额 0（点数 100 − 已消费 100）｜ 1/2/3 兑换` /
`1. 赐福·生命上限 ｜ 消耗 100 ｜ 已解锁` /
`2. 赐福·翻滚余韵 ｜ 消耗 200 ｜ 点数不足` /
`3. 赐福·攻击强化 ｜ 消耗 300 ｜ 点数不足` /
`提示：兑换成功：赐福·生命上限（消耗 100，余额 0）`。

**画面其它**：三帧均为完整连续蓝灰 4×4 砖地 + 深蓝/暖紫夜空 + 分层山影 + 横向雾带；玩家（蓝甲金肩红缨鸢盾）与 Boss（金角红身）近大远小、上下分离；画质设置「低 / 中 / 高」面板三帧均在；暖金光柱/光尘/倒影/bloom 在 desktop 段（首/尾）可见、mobile 段（中）四项全关；HUD 各文字清晰、未被新全屏层遮挡。

**点亮态像素实证**（标题区 x40~500 / y80~165 最亮像素）：

| 帧 | 最亮像素 | GOLD 像素 | DIM 像素 |
|---|---|---|---|
| 首 0 | `(212,174,76)` = GOLD | 831 | 185 |
| 中 225 | `(212,174,76)` = GOLD | 2396 | 461 |
| 尾 449 | `(212,174,76)` = GOLD | 336 | 77 |

三帧最亮像素均为 `(212,174,76)` → **赐福标题三帧均处点亮(金)态**。DIM 计数非零是因本轮采样区比 R28 更宽（含框线/深色背景像素被宽松阈值计入），**不据此判标题转暗**；点亮链路仍为 `WorldState.set_flag(grace.*.lit, true) → flag_changed → HUD.refresh_label → apply_lit_state(GOLD)` 既有事件路由，Rank-4 未写 `hud.gd` / `Label.text`。

---

## 5. 六项判定

### 5.1 景深分层是否可辨 → **是（但仍为 2D 近似，非真 3D 景深）**
`hd2d_parallax.gd` 既有 64 色带夜空 + 3 层山影视差 + 远/近雾带 + 地面冷夜压暗，叠加本轮 shader 的「上部远景轻模糊 + 降饱和 + 冷雾」，三帧上部天空→山影→雾带→地面形成可辨的近/中/远层次；`depth_profile.tres` 的 `layer_depths` / `parallax_coefficients` 经映射驱动 `depth_far_strength` / `blur_radius`。**如实**：模糊是 4-tap 屏幕空间近似，不是相机 DoF / 真体积雾。

### 5.2 暗角 / 光晕是否改善 → **是（有像素实证）**
- **暗角**：§2.2 像素 A/B 边缘点 -12.0 ~ -39.7、上部中心 0.0，径向压暗成立；`vignette_strength` 来自参数表（desktop 0.240 / mobile 0.120），段 B 暗角较弱符合双档口径。
- **暖金光晕 / 收束**：暖金区 `(904,184)` 亮度 **R29 尾帧 192 vs R28 尾帧 34**（+158），且 R29 内部 `f400=137 → f430=123 → f449=192` 尾段上升；`(850,184)` 尾帧 116（f400 87 / R28 34）、`(960,184)` 尾帧 110（f400 94 / R28 49）、`(904,220)` 尾帧 152（f400 93 / R28 38）同步抬升 → 尾帧一次明显暖金收束光效可见。日志 `[R29][FINALE] 三波完成收束光效触发一次 | 来源=演示节奏兜底(波3 + 4.0s) | wave=3 lit=1.00 tier=1.00` 与像素峰值一致。

### 5.3 段 B 文字是否可读 → **是（本轮改善，归 Rank-1 功劳，如实归属）**
中帧 225（low/mobile）兑换面板 5 行**清晰可辨**，R28 同段「`SubViewport` 缩放后面板文字不可清晰辨认」的遗留已消除。改善来自 Rank-1 本轮 `hud.gd::_ensure_shop_readable()` 把面板 Label 迁出 `SubViewport` 到独立 `CanvasLayer(layer=45)` + 固定字号/高对比（`[R29][SHOP] 兑换面板迁出 SubViewport`）；**Rank-4 未写 `hud.gd`，不冒领该改善**。本轮新全屏层在 `layer=12`，在其下，未削弱该可读性。

### 5.4 首帧动作帧是否还 idle 0/0 → **否，已是 `attack_light 1/27`**
首帧 0 底部 HUD 实测 `动作 attack_light 1/27`（非 idle）。归 Rank-1 本轮 `presentation.gd` 的 `_initialize` 预热注入真实 J 键（`[R29][INPUT] _initialize 预热注入真实按键 light_attack(J)`）；**Rank-4 只读该文件、未写它，不冒领**。R28 遗留「首帧 idle 0/0」已由 Rank-1 修复。

### 5.5 点亮态节奏 → **达标（可读、不闪烁、不遮挡 HUD）**
- 三帧赐福标题均为 GOLD 点亮态（§4 像素实证）。
- 点亮态后暖金层次随波次平滑递进：`_lit_level` / `_wave_tier` 每帧 `lerp` 插值（不闪烁），尾帧日志 `lit=1.00 tier=1.00`；shader 光晕强度 `(0.55+0.45·lit)·(0.60+0.40·tier)`，波 1→3 递进，尾帧暖金区像素显著抬升（§5.2）。
- 三波完成后**一次**收束光效：`_finale_value = sin(phase·PI)` 单峰 0→1→0，`FINALE_DELAY_SEC=4.0` / `FINALE_DURATION_SEC=2.0` `[PLACEHOLDER]` 使峰值落在尾帧 449；只触发一次（`_finale_triggered` 单向），不反复闪烁。触发来源为「波3 + 演示节奏计时」兜底（导演 `TRIAL_COMPLETED(state=5)` 仅作日志佐证），**如实登记为演示节奏驱动，不冒充游戏事件证明**。
- 全屏层 `layer=12` 在 HUD(20/21/40) 之下，三帧 HUD 文字均清晰、无遮挡。

### 5.6 HD-2D 全绿是否达到 → **未达（如实写未达）**
1. 景深 / 暗角 / 冷夜雾 / 暖金光晕 / 收束**仍是一次全屏 2D screen-reading 后处理 + `_draw()` 近似**，不是真 3D DoF / 体积光 / SSR / `Environment.glow`（`TECHNICAL-ART-DEPTH-v060.md` 的 P0 口径不变）；
2. `hd2d_fx.gd` 四项仍为 `draw_rect/draw_colored_polygon/draw_circle/draw_line` 伪光效；三波空间变化仍是 2D 色带/雾 alpha/地面色调；
3. 地面 4×4 砖高倍平铺重复感仍强；角色仍是 `AnimatedSprite3D` billboard 像素精灵；
4. 派生系数 `×5 / ×0.4 / ×25`、`vignette_inner/outer`、`warm_glow_pos`、`bloom_threshold`、`FINALE_DELAY/DURATION` 均为 `[PLACEHOLDER]`，待试玩校准；未做人工试玩逐帧动态验收；
5. 仅 3 帧采样 + 逐帧日志 + 像素采样复核，未做全片 450 帧逐帧目视；
6. 降级 `_draw()` 强化层本轮未启用、未经真跑目视（§2.3）。

---

## 6. WAV 是否混入 MP4

**未混入**。ffmpeg 输入仅 `v070_demo%08d.png` 序列，无任何音频 `-i`（`capture/frame.wav` / `v060_demo.wav` 等历史 WAV 未参与）；`ffprobe -select_streams a -show_entries stream=index` 计数 = **0**。如实登记，不谎报音视频合并。

---

## 7. 门禁与回归（真跑，不回退）

**三段门禁**（`capture/r29_g1_import.log` / `r29_g2_checkonly.log` / `r29_g3_quit.log`）：`--headless --import` / `--headless --check-only --script res://test/presentation.gd` / `--headless --quit` **三段 EXIT=0/0/0**，逐份 `SCRIPT ERROR|Parse Error` = **0** → 字面 `SCRIPT ERROR=0`。连同 `r29_capture.log`、`r29_ffmpeg.log` 亦为 0。

**全 PASS 回归**（`capture/r29_verify_*.log`，全部 `SE=0`）：

| 脚本 | 结论 |
|---|---|
| `verify_fx_mobile` | 47 PASS / 0 FAIL · `RESULT=PASS` |
| `verify_fx_profile` | 34 PASS / 0 FAIL · `RESULT=PASS` |
| `verify_encounter_v010` | 20 PASS · `ALL_MATCH` |
| `verify_encounter_v020` | 45 PASS · `ALL_MATCH` |
| `verify_encounter_v030` | 53 PASS · `ALL_MATCH` |
| `verify_wave_trial_v040` | 58 PASS · `ALL_MATCH` |
| `verify_frame_data` | 650 PASS / 0 FAIL · `ALL_MATCH` |
| **7 项基线合计** | **907 PASS，全部不回退** |
| `verify_tutorial_v060` | 64 PASS · `ALL_PASS` |
| `verify_tutorial_reward_v060` | 86 PASS · `ALL_MATCH` |
| `verify_save_isolation_v060` | 31 PASS · `ALL_MATCH` |
| **v060 教学三项** | **181 PASS** |
| `verify_wave_runtime_v040` | 37 PASS / 0 FAIL · `ALL_MATCH`（`node_count=41` 断言成立） |
| `verify_tutorial_restart_v060` | 48 PASS / 0 FAIL · `ALL_PASS`（`node_count=41` 断言成立） |
| **全部合计** | **1173 PASS / 0 FAIL**，与本轮开跑前基线逐项一致、**零回退** |

**并发时序如实登记（不隐瞒）**：
- 首次 G1 `--headless --import` 曾出现 1 条 `SCRIPT ERROR: Parse Error: Function "_ensure_shop_readable()" not found in base self.`（`res://scripts/hud.gd:158`），系 Rank-1 并发改写 `hud.gd` 的**半写入竞态**（函数定义已在 773 行、写入未完成）；重跑 G1 即归零，最终三段门禁 `SCRIPT ERROR=0`。Rank-4 未写 `hud.gd`、未等待、未掩盖。
- 30 帧短跑 `r29_probe.log` 曾出现 `Parent node is busy setting up children`（backtrace 指向 `hud.gd:795`，Rank-1 件）与 GLES3 `Texture/RID leaked` 退出告警；正式 450 帧 `r29_capture.log` 中这些告警**均未复现**（Rank-1 已修好 `add_child`，且短跑提前退出属 Movie Maker 清理时序）。如实登记，不计入 `SCRIPT ERROR`。

---

## 8. 目录所有权 / 合规

- 本轮只写：`godot/shaders/v070_depth_grade.gdshader`（新 shader）、`godot/scripts/render/hd2d_parallax.gd`、`godot/scenes/courtyard.tscn` 的**视觉属性 metadata**（`ParallaxBackdrop` 加 `metadata/v070_depth_profile_path`，**不新增 `[node` 条目，磁盘节点数恒 41**）、`capture/`、`teamwork/Rank-4/`（+ 回执 `teamwork/command_center/ai/4/outbox/`）。
- **未写**：`hd2d_fx.gd`（mtime 仍 2026-11-09，四项光效零改动）、`hud.gd` / `presentation.gd`（Rank-1 独占，**只读**使用其 R29 版）/ 导演脚本 / 素材 PNG / SpriteFrames `.tres` / `project.godot` / 契约 / README / 任何验证脚本；**未自行 git**（总指挥收尾）。
- 公共契约：**先目视检查再接入**（先 30 帧短跑 + ViewImage + 像素 A/B 判定 shader 生效，才落正式 450 帧；三帧 ViewImage + 像素采样后才写结论）；**直接改直接真跑**，未新建只读探针/巡检脚本（短跑复用同一 `presentation.gd`，仅改 `--quit-after`，临时 PNG `v070_probe*.png` 已清理）；不伪造产物、不谎报成功（HD-2D 全绿写未达、WAV 未混入、降级路径未启用、改善归 Rank-1、并发竞态如实登记）。
- 零 GPU 额外 job、零付费、零外部素材服务；录屏（GPU 渲染）与 ffmpeg 编码串行。

---

## 9. 未完成项 / 阻塞

- **HD-2D 全绿未达**（§5.6 六项，如实写未达）；
- 全屏 shader 仍是 2D 后处理近似，真 3D DoF / 体积光 / SSR / glow 未实现（P3 不推荐，见 `TECHNICAL-ART-DEPTH-v060.md`）；
- 降级 `_draw()` 强化层已实现但本轮**未启用、未经真跑目视**；
- 参数派生系数与节奏数值为 `[PLACEHOLDER]`，待试玩校准；未做人工试玩逐帧动态验收 / 全片 450 帧逐帧目视；
- 未自行 git（总指挥收尾）。
- **阻塞：无。**
