# DONE-R30.md · R30 v0.8.0 Rank-4 交付

> 派单 `cmd-20261111-125001-360-A4` · `[ROUND=R30]` · Rank-4（美术管线与工具链）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable）· ffmpeg 9.0.2 绝对路径 `C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`（Bash PATH 里没有）
> 详细实证见 `capture/V080-RUNTIME-REVIEW.md`、`capture/CAPTURE-REPORT.md §13`、`capture/r30_*.log`、`teamwork/Rank-4/r30_ground_tile_redraw.py`。
> 结论以「跑起来的画面」为准，不粉饰、不谎报、不自行 git（总指挥收尾）。

---

## 1. A37 降级层开关验证结果（验证完已恢复 shader 默认档）

| 项 | 结果 |
|---|---|
| 开关过程 | `hd2d_parallax.gd::GRADE_FORCE_DRAW_FALLBACK` **false → true（临时）→ false（恢复）** |
| 降级层真跑 | 同一 `presentation.gd` 450 帧录屏 `v080_fallback*.png`，**EXIT=0 / 450 帧 / 1280×720 / 15.000000s / SCRIPT ERROR=0**；日志证据 `[R29][GRADE] Compatibility screen texture 不可用 … → 降级为程序化 _draw() 强化` |
| 目视留证 | 保留首 0 / 中 225 / 尾 449 三帧 `capture/v080_fallback00000000.png / …00000225.png / …00000449.png`（均 1280×720），中间帧按 R29 惯例清理 |
| **恢复确认** | 恢复后文件第 80 行 `= false`；正式 450 帧 `r30_capture.log` 出现 `[R29][GRADE] shader 小样已挂载 … 参数来源=res://data/render/depth_profile.tres 命中=20/11`，降级层日志无此行 → **回到 shader 默认档、未回退画面** |

**首/中/尾画面对比（像素 A/B，`v080_demo` shader 档 vs `v080_fallback` 降级层）**：

| 帧 | mean_abs_diff | max_diff | 差异像素(>8) |
|---|---|---|---|
| 首 0 | 11.834 | 141 | 58.52% |
| 中 225 | 5.651 | 111 | 42.30% |
| 尾 449 | 13.340 | 178 | 58.93% |

- 尾帧暖金区 `(904,184)`：shader `(255,218,104)` vs 降级 `(86,83,76)`（−169/−135/−28）→ 降级层**暖金收束/光晕显著弱**；
- 边缘/下部 `(320,650)`、`(5,360)`：降级层普遍比 shader 档亮 `+18~+39` → 降级层**暗角更弱、画面更平**；
- 上部中心 `(640,100)` 两档差 `−4~+5` → 差异集中在暗角/暖光/收束，天空底色基本一致；
- 目视：降级层是「6 层四边矩形暗角 + 3 层冷蓝矩形雾带 + 同心圆 + `draw_arc` 圆弧（尾帧可见金色圆环）」，更程序化/分层；shader 档是平滑径向暗角 + 一次全屏 screen-reading 后处理；两档地面/赐福标题/兑换面板/HUD 均完整、HUD 未遮挡。

**适用场景与代价（写清、不谎称默认）**：
- 适用：Compatibility 后端 `hint_screen_texture` / screen-reading shader **失效**（加载失败、`SCREEN_TEXTURE` 未定义、编译报错、后端不支持屏读）时兜底「暗角/冷夜雾/多层景深/暖金光晕/收束环」四项观感，保证画面不空白、不遮 HUD。R29/R30 实测屏读可用，故平时不启用。
- 代价：① 无 screen-reading，只能 2D 程序化分层矩形/同心圆/圆弧，暗角与暖光明显弱、观感更生硬（有像素实证）；② `_draw()` 每帧 `queue_redraw()` 重绘，CPU draw call 多于 shader 一次 GPU 全屏 pass；③ 参数仍由 `_r29_params`（读 Rank-2 `depth_profile.tres` 双档）注入，与 shader 路径共用；④ 品质下降属「降级」，**不得计入默认画面效果、不得冒充真 3D 光效**。
- **口径澄清**：降级层日志里的「Compatibility screen texture 不可用」是强制开关触发的既有措辞，并非 R30 真的检测到屏读失效；降级层不是默认效果，`v080_demo.mp4` 是恢复后的 shader 默认档画面（裁决 A37）。

---

## 2. 地面重绘实测色数与接缝

旧版**先备份** `teamwork/Rank-4/v070_pre_v080_backup/ground_tile.png`（673 B / 6 色 / 128×128 / 边缘 diff=0，重跑脚本有 `if not exists` 保护，备份未被覆盖）再覆盖 `godot/assets/generated/r23/ground_tile.png`。

| 约束 / 改进 | 实测 |
|---|---|
| **6 色受控板** | `unique_colors = 6`，逐字取自旧板、`palette_in_old_board=True`；分布 `(121,180,232) 3603 / (63,111,196) 3327 / (44,76,140) 3107 / (6,10,20) 2608 / (27,42,74) 2340 / (10,16,32) 1399` |
| **128×128** | `size=(128,128) / RGBA` |
| **4×4 大砖** | 16 块（每砖 32×32） |
| **左右边缘像素完全一致** | `left_right_edge_diff = 0`（逐像素比对 x=0 与 x=127 全列） |
| **上下边缘像素完全一致** | `top_bottom_edge_diff = 0`（逐像素比对 y=0 与 y=127 全行） |
| **3–5 阶明度** | `brightness_steps_per_brick = [3,4,5]`（同心方框梯度、板内连续阶） |
| **砖块色阶微扰** | 16 砖 `base=[1,3,2,3,1,1,3,3,2,3,2,1,1,2,3,2]`、`steps=[5,3,4,5,4,3,4,5,3,4,3,5,5,5,4,5]`，重复周期 32px→128px |
| **磨损用受控色而非噪点** | 每砖 2 处受控形状（短划痕 / 2×2 小色块），颜色取自 6 色板内比主体暗 1 阶、确定性 hash 定位，非逐像素随机散点 |
| 脚本断言 | `ASSERT = ALL PASS` |

**先目视检查再接入**：3×3 平铺旧版 `r30_tile_old_tiled.png` 每砖完全相同、重复感极强；首版重绘偏亮（L5 亮色占 38%）→ 微调 `base 2/3/4→1/2/3`、磨损 2~3 处→固定 2 处 → 新版 `r30_tile_new_tiled.png` 砖块明暗/图案各异、重复感明显降低，冷蓝夜色与 4×4 大砖/连贯缝隙保持、未见明显接缝。**未改** SpriteFrames / 角色 PNG / `project.godot`。

---

## 3. uv 改动（A35 独占 courtyard.tscn 视觉属性）

| 地面 MeshInstance3D 材质 | 改前 | 改后 |
|---|---|---|
| `StandardMaterial3D_uvplate`（GroundPlate） | `uv1_scale = Vector3(4, 4, 1)` | **`Vector3(2, 2, 1)`** |
| `StandardMaterial3D_uvlow`（TerraceLow） | `uv1_scale = Vector3(2, 2, 1)` | **`Vector3(1, 1, 1)`** |
| `StandardMaterial3D_uvhigh`（TerraceHigh） | `uv1_scale = Vector3(1, 1, 1)` | `Vector3(1, 1, 1)`（保持 1） |

- 三处最终值 **2/1/1**，标 `[PLACEHOLDER]` + rationale 于 `courtyard.tscn` 的 `;` 注释（「降低高倍平铺重复感、与地面精修配套、待试玩校准」），G1 `--headless --import` **EXIT=0** 验证注释可被引擎正常解析。
- **只改这三处视觉属性、不新增节点**：`grep -c "^\[node "` = **41**（改前 41、改后 41），`verify_wave_runtime_v040` 的 `courtyard_node_count PASS=true | node_count=41 expected=41` 与 `verify_tutorial_restart_v060` 的 41 断言均成立。
- 与地面重绘配套：平铺倍率减半、砖块变大、周期更长 → 录屏首/中/尾三帧地面重复感进一步降低。

---

## 4. 录屏帧数 / MP4 字节数 / WAV

| 项 | 实测 |
|---|---|
| 正式录屏命令 | `--path <godot> --write-movie F:/Game/aierdengfahuan/capture/v080_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`） |
| **帧数** | **450 帧**（`v080_demo00000000.png … v080_demo00000449.png`，python 精确统计序号 `0..449`、`continuous=True`），`1280×720 / 30 FPS / 15.000000s`，**EXIT=0 / SCRIPT ERROR=0** |
| ffmpeg | 绝对路径 9.0.2：`-framerate 30 -start_number 0 -i v080_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，**EXIT=0** |
| ffprobe | `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000` |
| **MP4 字节数** | **`capture/v080_demo.mp4` = 1,022,776 B** |
| **WAV 是否混入 MP4** | **未混入**：Movie Maker 自动生成 `capture/v080_demo.wav`（5,760,044 B），但 ffmpeg 仅输入 PNG 序列、无音频 `-i`，`ffprobe -select_streams a` 音频流计数 = **0**。如实登记 |
| 降级层录屏 | 另 450 帧（A37 开关验证用），仅留首/中/尾三帧、中间帧已清理 |

---

## 5. 三帧 ViewImage 目视结论（真看首 0 / 中 225 / 尾 449，shader 默认档）

| 帧 | 段 / 波 / 画质 | 结论 |
|---|---|---|
| **首 0** | 段 A / 第 1/3 波 / desktop-medium | 地面砖块浅/中/深蓝交错 + 深色短划痕磨损、**明暗差异明显、重复感降低**；深蓝夜空 + 分层山影 + 雾带 + 四角暗角可辨；赐福「关卡前」亮金；兑换面板提示态；画质面板「低/中/高」清晰；动作 `attack_light 1/27`；玩家与 Boss 像素精灵可见；HUD 未被遮挡；**无图鉴面板**；HD-2D 全绿未达 |
| **中 225** | 段 B / 第 2/3 波 / low-mobile | 地面砖块明暗差异明显；**兑换面板 5 行清晰可辨**（归 Rank-1 `hud.gd::_ensure_shop_readable()` 迁出 SubViewport，Rank-4 未写 `hud.gd`、不冒领）；赐福「巡礼教堂」亮金；动作 `roll 6/22`；mobile 四项光效全关、整体较暗；HUD 无遮挡；**无图鉴面板** |
| **尾 449** | 段 C / 第 3/3 波 / desktop-high | 地面砖块明暗差异明显；**一次明显暖金收束光效/光晕**；赐福「希芙拉河井底」亮金（暖紫背景下目视偏暗、像素仍 GOLD）；兑换面板 5 行清晰；`第 3/3 波 点数 350 历史最佳 3`；动作 `roll 8/22` / `胜利 · 已落盘`；HUD 无遮挡；**无图鉴面板**；HD-2D 全绿未达 |

**四项判定**：
1. **地面重复感是否改善 → 是**（3×3 平铺目视 + 三帧录屏目视 + 实测 16 砖微扰；仍保留 4×4 大砖周期，属硬约束，非「消除重复」）；
2. **降级层与 shader 对比 → 明显不同**（§1 像素 A/B 与目视：降级层暗角更弱更平、暖金收束显著弱、更程序化/分层矩形；验证完已恢复 shader 默认档，降级层非默认效果）；
3. **图鉴面板（若 Rank-1 已落盘）是否可读 → 未出现、未落盘**（开跑前 `find -iname "*codex*"` 无结果、`hud.gd` 无 codex/Tab 关键字；三帧均只有赐福标题/画质面板/兑换面板/HUD；按并发时序**不等待、不伪造**）；
4. **HD-2D 全绿是否达到 → 未达（如实写未达）**：景深/光效仍 2D screen-reading 后处理 + `draw_*` 近似、地面仍 4×4 大砖平铺、billboard 像素精灵、`[PLACEHOLDER]` 待试玩、未做人工试玩逐帧动态验收 / 全片 450 帧逐帧目视。

---

## 6. 真跑输出结论（门禁 / 回归 / 不回退）

- **三段门禁**：G1 `--headless --import` / G2 `--headless --check-only --script res://test/presentation.gd` / G3 `--headless --quit` **EXIT=0/0/0**；六份日志（`r30_g1/g2/g3`、`r30_capture`、`r30_ffmpeg`、`r30_fallback_capture`）逐份 `SCRIPT ERROR|Parse Error` = **0** → 字面 **`SCRIPT ERROR=0`**。
- **全 PASS 回归（如实登记未完全达成）**：12 项中 **11 项全 PASS = 1136 PASS / 0 FAIL**（`47 / 34 / 20 / 45 / 53 / 58 / 650 / 64 / 86 / 31 / 48`）+ `verify_wave_runtime_v040` **35 PASS / 2 FAIL · RESULT=FAILED**（重跑同值稳定）→ **合计 1171 PASS / 2 FAIL**（R29 基线 1173 PASS / 0 FAIL）。
  - **2 个 FAIL 根因（不掩盖、不放宽、不改断言）**：按 A35 把 uv 改成 2/1/1 后，`verify_wave_runtime_v040.gd` 两条硬编码旧期望 `uv_groundplate_4 expected=(4,4,1)`（实测 2,2,1）、`uv_terracelow_2 expected=(2,2,1)`（实测 1,1,1）未同步 → **断言字面过期**，属预期内冲突、非功能回退；`courtyard_node_count=41 expected=41` 仍 PASS、`uv_terracehigh_1` 仍 PASS、其余 11 项零回退。
  - 按公共契约「不改断言不放宽不掩盖」与目录所有权（验证脚本不在 Rank-4 本轮写入白名单），**Rank-4 未写该脚本**；建议脚本所有者把期望 `4→2 / 2→1` 同步后复跑即恢复 `37/0`、合计回到 `1173 PASS`（R28 同类 node_count 期望过期、R29 同步归零，先例一致）。
- **并发时序如实登记**：Rank-1 图鉴/Tab 注入未落盘，录屏三帧均无图鉴面板，未等待、未伪造、未冒领；其余并发件（`hud.gd` / `presentation.gd` / `depth_profile.tres`）只读使用、未写。三段门禁、正式录屏、降级层录屏、ffmpeg 全部 `SCRIPT ERROR=0`，未出现 R29 记录过的 `Parent node is busy` / `leaked` 之外的异常。

---

## 7. 实际交付清单

| 文件 | 改动 |
|---|---|
| `godot/assets/generated/r23/ground_tile.png` | **覆盖重绘**：6 色 / 128×128 / 4×4 大砖 / 上下左右边缘 diff=0 无缝 / 16 砖色阶微扰 / 受控磨损 / 3–5 阶明度 |
| `teamwork/Rank-4/v070_pre_v080_backup/ground_tile.png` | **新增**：旧版备份（673 B） |
| `teamwork/Rank-4/r30_ground_tile_redraw.py` + `r30_tile_old_tiled.png` / `r30_tile_new_tiled.png` | **新增**：重绘脚本 + 3×3 平铺旧/新目视预览 |
| `godot/scripts/render/hd2d_parallax.gd` | **临时切换后恢复**：`GRADE_FORCE_DRAW_FALLBACK` false→true（A37 验证）→false（shader 默认档）+ R30 说明注释 |
| `godot/scenes/courtyard.tscn` | **仅视觉属性**：3 处 `uv1_scale` 4/2/1→2/1/1 + `;` `[PLACEHOLDER]` 注释（不新增 `[node`、节点数恒 41） |
| `capture/v080_demo*.png` | **新增**：450 帧（0..449 连续） |
| `capture/v080_demo.mp4` | **新增**：1,022,776 B（h264 / 450 帧 / 15s） |
| `capture/v080_demo.wav` | Movie Maker 自动生成，未混入 MP4（如实登记） |
| `capture/v080_fallback00000000 / 00000225 / 00000449.png` | **新增**：A37 降级层首/中/尾三帧留证（中间帧已清理） |
| `capture/V080-RUNTIME-REVIEW.md` | **新增**：三帧目视 + A37 降级层对比 + 像素 A/B + 门禁回归 + 未完成项 |
| `capture/CAPTURE-REPORT.md` | **追加** §13「R30 v0.8.0」 |
| `capture/r30_*.log` | **新增**：门禁 / 录屏 / ffmpeg / 降级层 / 12 项回归 + 重跑日志 |
| `teamwork/Rank-4/DONE-R30.md` | **新增**（本文件） |
| `teamwork/command_center/ai/4/outbox/cmd-20261111-125001-360-A4.json` | **新增**：回执（写入精确路径，非工程根 command_center/）；写入后被调度中枢**实时自动消费**至 `teamwork/command_center/dispatcher/receipts/cmd-20261111-125001-360-A4.json`（内容一致、1648 B、`status=done`、`result` 引用 DONE-R30.md 实际结论），outbox 为空发件箱，属总指挥收尾的正常协作机制（与 R29 一致，如实登记） |

**未写**：`hd2d_fx.gd` / `hud.gd` / `codex_director.gd` / `presentation.gd`（Rank-1 只读）/ 导演脚本 / `verify_*` 验证脚本 / shader 文件 / 角色 PNG / SpriteFrames `.tres` / `project.godot` / `depth_profile.tres`（Rank-2 只读）/ 契约 / README；**未自行 git**（总指挥收尾）。零付费、零外部依赖、零新增 GPU job。

---

## 8. 未完成项 / 阻塞

- **HD-2D 全绿未达**（§5 第 4 项，如实写未达）；
- **图鉴面板（Rank-1 Tab 注入）未落盘**、录屏三帧未出现，按并发时序不等待、不伪造、不冒领；
- **`verify_wave_runtime_v040` 35 PASS / 2 FAIL**：2 个 uv 断言期望值过期（expected 4/2/1 vs actual 2/1/1），待脚本所有者同步 `4→2 / 2→1` 后复跑恢复 37/0；Rank-4 未写该脚本、未放宽断言；回归「全 PASS」本轮**未完全达成**，如实登记；
- `[PLACEHOLDER]` 数值（uv 2/1/1、砖块 base/steps/磨损数、shader 派生系数与节奏）待试玩校准；未做人工试玩逐帧动态验收 / 全片 450 帧逐帧目视；
- 全屏 shader 仍是 2D 后处理近似，真 3D DoF / 体积光 / SSR / glow 未实现（P3 不推荐，见 `TECHNICAL-ART-DEPTH-v060.md`）；降级层只完成一次开关验证 + 目视留证，未作为默认效果、未做长期启用评估；
- 地面重复感是「降低」而非「消除」（4×4 大砖周期为任务硬约束）；
- 未自行 git（总指挥收尾）。
- **阻塞：无**（2 个 FAIL 为已登记的断言期望值过期项，非功能阻塞）。
