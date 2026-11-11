# DONE-R29.md · R29 v0.7.0 Rank-4 交付

> 派单 `cmd-20261111-112804-021-A4` · `[ROUND=R29]` · Rank-4（美术管线与工具链）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable）· ffmpeg 9.0.2 绝对路径
> 详细实证见 `capture/V070-RUNTIME-REVIEW.md`、`capture/CAPTURE-REPORT.md §12`、`capture/r29_*.log`。

---

## 1. shader 是否生效 / 降级原因（裁决 A30）

**生效，未降级。**

- 新增 `godot/shaders/v070_depth_grade.gdshader`：`shader_type canvas_item` + **`uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest`** + `SCREEN_UV`，一次全屏采样实现「多层视差景深 + 边缘暗角 + 冷夜雾 + 暖金光晕 + 三波收束扩散环」。
- 新增 `CanvasLayer(layer=12)` + `ColorRect`（铺满、透明兜底、`mouse_filter=IGNORE`）+ `ShaderMaterial`，由 `hd2d_parallax.gd::_r29_init()` **运行时 `call_deferred("add_child", layer)` 创建**（`_ready()` 内直接 `add_child` 会触发 `Parent node is busy setting up children`，故延迟挂载）。
- **Compatibility 后端 `hint_screen_texture` 真跑可用**，证据链（不靠推断、不谎称）：
  1. 三段门禁 + 正式录屏 + 30 帧短跑日志**均无** shader 编译错误 / `SCREEN_TEXTURE` 未定义报错，`SCRIPT ERROR=0`；
  2. `[R29][GRADE] shader 小样已挂载 | layer=12 rect=V070DepthGradeRect`；短跑曾出现的 `Parent node is busy` 经 backtrace 确认来自 **Rank-1 `hud.gd:795`**（并发件），非本层，正式录屏已消失；
  3. 像素 A/B（R28 `v060_demo00000000.png` → R29 `v070_demo00000000.png`，避开 HUD 的边缘点）：`(5,360) -39.7`、`(1275,360) -18.3`、`(10,710)/(1270,710) -20.0`、`(320,650)/(960,650) -12.0`、四角 `-1.7`，而**上部中心 `(640,100) 0.0`** → 典型径向暗角特征；若 ColorRect 未铺满或 screen texture 采样失效不可能出现该规律且画面仍完整；
  4. 参数注入日志 `总命中=20` + 双档切换（f=173 mobile / f=279 desktop）证明 uniform 逐帧真实写入。
- **降级原因：无（未触发降级）**。`hd2d_parallax.gd::_r29_draw_grade()` 等价程序化 `_draw()` 强化层**已实现但本轮未启用**（`GRADE_FORCE_DRAW_FALLBACK=false`）、**未经真跑目视**，如实登记，不计入交付画面效果，不谎称其生效。
- **口径澄清**：「shader 生效」= Compatibility 后端一次全屏 screen-reading 后处理真的在画面上起作用；**不是**真 3D 景深 / 体积光 / SSR / `Environment.glow`。HD-2D 全绿仍**未达**。
- **不遮 HUD / 不回退 desktop**：`layer=12` < `Hud(20)`/`WaveTrialHud(20)`/`TutorialHud(21)`/`QualitySettings(40)`；`hd2d_fx.gd` 本轮**零改动**（mtime 仍 2026-11-09），四项光效与新层无冲突、desktop 四项全开不回退。
- **不回退回归**：运行时创建节点，**绝不写 `courtyard.tscn` 的 `[node` 条目** → 磁盘节点数恒 **41**，`verify_wave_runtime_v040`(`NODE_COUNT_AFTER=41`) 与 `verify_tutorial_restart_v060`(`NODE_COUNT_EXPECTED=41`) 断言均保持 PASS。

## 2. 景深与光色参数（读 Rank-2 `depth_profile.tres`，不硬编码）

- **并发时序（如实）**：开跑时 `godot/data/render/depth_profile.tres` 未落盘；执行期间 Rank-2 落盘（mtime `2026-11-11 11:39`）。实现同时具备「未落盘 → `[PLACEHOLDER]` 安全默认 + 不等待不伪造」与「落盘 → 真读」两条路径；正式录屏走**真读**路径（`[R29][DEPTH] 参数表已读取 … 总命中=20 | 生效来源=res://data/render/depth_profile.tres`）。Rank-1 的 `presentation.gd`（R29 版，首帧预热）与 `hud.gd`（R29 版，面板迁出 SubViewport）亦在执行期间落盘，**只读使用、未写**。
- 参数表结构：顶层 `[resource]` + `desktop`/`mobile` 两个子 `DepthProfile` Resource。`_r29_map_profile()` 逐字段映射（顶层容错 + 子档覆盖）；**shader 内 uniform 一律不带默认值**，全部由 `set_shader_parameter` 注入 → 生效数值不硬编码于 shader。

| 参数表字段 | shader uniform | desktop | mobile |
|---|---|---|---|
| `vignette_strength` | `vignette_strength` | 0.240 | 0.120 |
| `warm_glow_strength` | `warm_glow_strength` | 0.450 | 0.220 |
| `fog_density` | `cool_fog_strength`（×5 `[PLACEHOLDER]`） | 0.175 | 0.090 |
| `cold_night_fog_color` | `cool_fog_color` | `#2B3A5C` | `#2B3A5C` |
| `warm_gold_key_color` | `warm_glow_color` | `#F0A94C` | `#F0A94C` |
| `layer_depths[0]` | `depth_far_strength`（×0.4） | 0.100 | 0.140 |
| `parallax_coefficients[0]` | `blur_radius`（×25） | 1.50 | 1.25 |

- 参数表无对应字段、由 `[PLACEHOLDER]` 安全默认补齐：`vignette_inner=0.34`、`vignette_outer=0.78`、`warm_glow_pos=(0.706,0.256)`（对齐 `hd2d_fx.gd` `LIGHT_POS(452,92)/640×360`）、`bloom_threshold=0.75`（对齐 `FXBloom` 仅暖金过阈口径）。派生系数 `×5/×0.4/×25` 为「参数表字段语义 → shader uniform」量纲换算，待试玩校准。
- 双档按 `QualitySettings.get_quality_preset()` 逐帧选择：段 A/C desktop、段 B mobile（录屏日志两次切换可见）。
- 节奏数值 `[PLACEHOLDER]`：`FINALE_DELAY_SEC=4.0`、`FINALE_DURATION_SEC=2.0`（rationale：波3 自 f=300=10s 起，f420 触发、单峰峰值落在尾帧 449，与 f430 击败 Boss / f420 赐福标题切「希芙拉河井底」尾段对齐）。全部 rationale 写在 `hd2d_parallax.gd` 注释。

## 3. 录屏帧数 / MP4 字节数 / WAV

| 项 | 实测 |
|---|---|
| 录屏命令 | `--path <godot> --write-movie capture/v070_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`） |
| 帧数 | **450 帧**（`v070_demo00000000.png … v070_demo00000449.png`），`1280×720 / 30 FPS / 15.000000s`，**EXIT=0**，`SCRIPT ERROR=0` |
| ffmpeg | 绝对路径 `C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`，`-framerate 30 -start_number 0 -i v070_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，**EXIT=0** |
| ffprobe | `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000`，`moov` 前置 |
| **MP4 字节数** | **`capture/v070_demo.mp4` = 935,921 B** |
| **WAV 是否混入** | **未混入**：ffmpeg 仅输入 PNG 序列、无音频 `-i`，`ffprobe -select_streams a` 音频流计数 = **0**，如实登记 |

## 4. 三帧 ViewImage 目视结论（真看首 0 / 中 225 / 尾 449）

| 帧 | 结论 |
|---|---|
| **首 0** | 段 A / 第 1/3 波 / desktop-medium；赐福「关卡前」亮金；**动作 `attack_light 1/27`（非 idle 0/0）**；兑换面板提示态；深蓝夜空 + 分层山影 + 雾带可辨；四角暗角可辨；HUD 清晰无遮挡。 |
| **中 225** | 段 B / 第 2/3 波 / low-mobile；赐福「巡礼教堂」亮金；**兑换面板 5 行清晰可辨**（R28 同段不可辨 → 改善）；动作 `roll 6/22`；mobile 档暗角/光晕较弱（参数表 mobile 0.120/0.220）、四项光效全关；HUD 未被遮挡。 |
| **尾 449** | 段 C / 第 3/3 波 / desktop-high；赐福「希芙拉河井底」亮金（暖紫背景下目视偏暗，像素仍 GOLD）；**一次明显暖金收束光效/光晕增强**；兑换面板 5 行清晰；动作 `roll 8/22` / `胜利 · 已落盘`；`第 3/3 波 点数 350 历史最佳 3`；四角暗角可辨；HUD 无遮挡。 |

**六项判定**：
1. 景深分层**可辨**（仍 2D 近似，非真 3D 景深）；
2. 暗角/光晕**改善，有像素实证**（边缘 `-12~-40`、上部中心 `0`；暖金区 `(904,184)` 尾帧 192 vs R28 34、R29 `f400=137`/`f430=123`）；
3. 段 B 文字**可读（本轮改善）** —— 归 **Rank-1 `hud.gd::_ensure_shop_readable()` 迁出 SubViewport**，Rank-4 未写 `hud.gd`、不冒领；
4. 首帧动作帧**不再 idle 0/0**（`attack_light 1/27`）—— 归 **Rank-1 `presentation.gd` `_initialize` 预热注入 J**，Rank-4 只读、不冒领；
5. 点亮态节奏**达标**：三帧标题最亮像素均 `(212,174,76)`=GOLD；暖金层次 `lerp` 平滑递进（尾帧 `lit=1.00 tier=1.00`）；三波完成后**一次**收束（单峰、不闪烁、不遮 HUD，来源「波3 + 演示节奏」兜底，不冒充游戏事件证明）；
6. **HD-2D 全绿未达（如实写未达）**：景深/光效仍 2D 近似、地面高倍平铺、billboard 像素精灵、`[PLACEHOLDER]` 待试玩、未做人工试玩逐帧动态验收。

## 5. 真跑输出结论（门禁 / 回归 / 不回退）

- **三段门禁**：G1 `--headless --import` / G2 `--headless --check-only --script res://test/presentation.gd` / G3 `--headless --quit` **EXIT=0/0/0**，`SCRIPT ERROR|Parse Error` = **0**（字面 `SCRIPT ERROR=0`）。
- **全 PASS 回归（不回退）**：`47 / 34 / 20 / 45 / 53 / 58 / 650`（7 项基线 **907 PASS**）+ `64 / 86 / 31`（v060 教学 **181 PASS**）+ `verify_wave_runtime_v040` **37** + `verify_tutorial_restart_v060` **48** → **合计 1173 PASS / 0 FAIL**，与开跑前基线逐项一致、零回退；全部 `r29_verify_*.log` `SCRIPT ERROR=0`。
- **并发竞态如实登记**：首次 G1 因 Rank-1 并发改写 `hud.gd` 半写入出现 1 条 `_ensure_shop_readable()` Parse Error，重跑归零；30 帧短跑 `r29_probe.log` 的 `Parent node is busy`（backtrace `hud.gd:795`，Rank-1 件）与 GLES3 `leaked` 退出告警，在正式 450 帧 `r29_capture.log` 中**均未复现**。未写他人件、未等待、未掩盖。

## 6. 实际交付清单

| 文件 | 改动 |
|---|---|
| `godot/shaders/v070_depth_grade.gdshader` | **新增**：P2 全屏 shader（hint_screen_texture，uniform 无默认值） |
| `godot/scripts/render/hd2d_parallax.gd` | **追加** R29 段：运行时创建 CanvasLayer+ColorRect+ShaderMaterial、读 `depth_profile.tres` 双档、参数注入、点亮态/波次/收束节奏、降级 `_draw()` 备用层 |
| `godot/scenes/courtyard.tscn` | **仅视觉属性**：`ParallaxBackdrop` 加 `metadata/v070_depth_profile_path`（**不新增 `[node`**，磁盘节点数恒 41） |
| `capture/V070-RUNTIME-REVIEW.md` | **新增**：三帧目视 + 像素实证 + 六项判定 + 门禁回归 |
| `capture/CAPTURE-REPORT.md` | **追加** §12「R29 v0.7.0」 |
| `capture/v070_demo*.png` / `v070_demo.mp4` | **新增**：450 帧 + 935,921 B MP4 |
| `capture/r29_*.log` | **新增**：门禁/回归/录屏/ffmpeg/短跑日志 + 基线日志 |
| `teamwork/Rank-4/DONE-R29.md` | **新增**（本文件） |
| `teamwork/command_center/ai/4/outbox/cmd-20261111-112804-021-A4.json` | **新增**：回执（写入精确路径后被调度中枢**实时自动消费**至 `teamwork/command_center/dispatcher/receipts/cmd-20261111-112804-021-A4.json`，内容一致、1804 B、`status=done`；outbox 在本轮开跑前即为空发件箱，属总指挥收尾的正常协作机制，如实登记） |

**未写**：`hd2d_fx.gd` / `hud.gd` / `presentation.gd`（Rank-1 只读）/ 导演脚本 / 素材 PNG / SpriteFrames `.tres` / `project.godot` / `depth_profile.tres`（Rank-2 只读）/ 契约 / README / 任何验证脚本；**未自行 git**（总指挥收尾）。零付费、零外部依赖、零新增 GPU job。

## 7. 未完成项 / 阻塞

- **HD-2D 全绿未达**（§4 第 6 项，如实写未达）；
- 全屏 shader 仍是 2D 后处理近似，真 3D DoF / 体积光 / SSR / glow 未实现（P3 不推荐，见 `TECHNICAL-ART-DEPTH-v060.md`）；
- 降级 `_draw()` 强化层已实现但本轮**未启用、未经真跑目视**；
- 参数派生系数 `×5/×0.4/×25`、`vignette_inner/outer`、`warm_glow_pos`、`bloom_threshold`、`FINALE_DELAY/DURATION` 为 `[PLACEHOLDER]`，待试玩校准；未做人工试玩逐帧动态验收 / 全片 450 帧逐帧目视；
- 段 B 文字改善与首帧非 idle 归 Rank-1，本轮不冒领；
- 未自行 git（总指挥收尾）。
- **阻塞：无。**
