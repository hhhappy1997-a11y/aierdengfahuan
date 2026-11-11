# V080-RUNTIME-REVIEW.md · R30 v0.8.0 15 秒实机录屏运行期目视复核

> 派单 `cmd-20261111-125001-360-A4` · `[ROUND=R30]` · Rank-4（美术管线与工具链）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable）/ ffmpeg 9.0.2（本机绝对路径 `C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`，Bash PATH 里没有）
> 真跑产物：`capture/v080_demo*.png` **450 帧** @30fps/15s；`capture/v080_demo.mp4` **1,022,776 字节**
> 结论以 **ViewImage 真看首 0 / 中 225 / 尾 449 三帧 + A37 降级层三帧目视 + 像素 A/B + `capture/r30_*.log` 逐帧日志 + 三段门禁/回归日志** 为准；不粉饰、不谎报、不把 2D 全屏后处理叫「真 3D 光效」。

---

## 1. 真跑与产物（非伪造）

| 项 | 实测 |
|---|---|
| 正式录屏命令 | `--path F:/Game/aierdengfahuan/godot --write-movie F:/Game/aierdengfahuan/capture/v080_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`，沿用 R22~R29 定稿） |
| 录屏 EXIT / 帧数 | **0** / **450 帧**（`v080_demo00000000.png … v080_demo00000449.png`，python 精确统计序号 `0..449` 连续 `continuous=True`），`1280×720 / 30 FPS / 15.000000s`（引擎日志 `450 frames at 30 FPS (movie length: 00:00:15:00)`） |
| 录屏日志 | `SCRIPT ERROR\|Parse Error` = **0**；`[R29][GRADE] shader 小样已挂载 … 参数来源=res://data/render/depth_profile.tres 命中=20/11`（证明 **shader 默认档已恢复**）；`[R29][DEPTH]` / `[R29][FINALE]` 均在 |
| ffmpeg | 绝对路径 9.0.2：`-framerate 30 -start_number 0 -i v080_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，**EXIT=0**，输出 `frame=450` |
| ffprobe 视频 | `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000` |
| **MP4 字节数** | **`capture/v080_demo.mp4` = 1,022,776 B**（ffprobe `size=1022776`） |
| **WAV 是否混入 MP4** | **未混入**。Movie Maker 自动生成了 `capture/v080_demo.wav`（5,760,044 B），但 ffmpeg 输入仅 PNG 序列、无任何音频 `-i`；`ffprobe -select_streams a -show_entries stream=index` 音频流计数 = **0**。如实登记，不谎报音视频合并 |

---

## 2. 地面重复感是否改善（本轮 A35+ 平铺精修核心）

**判定：改善（有 3×3 平铺目视 + 三帧录屏目视 + 实测数据）。**

- 旧版 `ground_tile.png`：128×128 / 6 色 / 4×4 大砖 / 左右上下边缘 diff=0（无缝），但 **16 块砖完全同一图案**（同一同心阶梯 + 同一组斑点）→ 3×3 平铺预览（`teamwork/Rank-4/r30_tile_old_tiled.png`）重复感极强、周期 32px。
- 本轮重绘（`teamwork/Rank-4/r30_ground_tile_redraw.py`，旧版先备份到 `teamwork/Rank-4/v070_pre_v080_backup/`）：
  - 保持 **6 色受控板**（逐字取自旧版、不私加新色）/ **128×128 RGBA** / **4×4 大砖（16 块）** / **左右边缘 diff=0、上下边缘 diff=0（无缝）**；
  - **① 砖块色阶微扰**：16 块砖主体基调 `base=[1,3,2,3,1,1,3,3,2,3,2,1,1,2,3,2]`、明度阶数 `steps=[5,3,4,5,4,3,4,5,3,4,3,5,5,5,4,5]`，重复周期由 32px 抬到 128px；
  - **② 磨损纹理用受控色而非噪点**：每砖 2 处受控形状（短划痕 / 2×2 小色块），颜色取自 6 色板内比主体暗 1 阶，确定性 hash 定位、非逐像素随机散点；
  - **③ 3–5 阶明度**：每砖同心方框梯度恰好 3/4/5 阶（实测 `brightness_steps_per_brick=[3,4,5]`），板内连续阶、不 clamp 饱和；
  - 实测色数 **6**、6 色分布 `(121,180,232) 3603 / (63,111,196) 3327 / (44,76,140) 3107 / (6,10,20) 2608 / (27,42,74) 2340 / (10,16,32) 1399`；`ASSERT = ALL PASS`。
- 3×3 平铺目视（`r30_tile_new_tiled.png`）：砖块之间**明暗与图案各异**，旧版「每块完全相同」的重复感明显降低，冷蓝夜色、4×4 大砖、连贯缝隙保持；磨损为受控形状而非噪点散点；**未见明显接缝**。
- 录屏首/中/尾三帧目视：地面砖块呈浅蓝 / 中蓝 / 深蓝交错、带深色短划痕磨损，**不再是每块一模一样**；配合 `courtyard.tscn` 三个地面材质 `uv1_scale 4/2/1 → 2/1/1`（平铺倍率减半、砖块变大、周期更长）→ 高倍平铺重复感进一步降低。
- **如实**：仍保留 4×4 大砖的周期性结构（这是任务硬约束「保持 4×4 大砖」），故是「降低重复感」而非「消除重复」；未做人工试玩逐帧动态验收。

---

## 3. A37 降级层开关验证（首/中/尾对比；验证完已恢复 shader 默认档）

### 3.1 开关过程（真跑、留证）

| 步 | 内容 | 证据 |
|---|---|---|
| ① 临时切换 | `hd2d_parallax.gd::GRADE_FORCE_DRAW_FALLBACK` `false → true` | 文件改动 |
| ② 降级层录屏 | 同 450 帧命令、`--write-movie …/v080_fallback.png`，**EXIT=0 / 450 帧 / 1280×720 / 15s / SCRIPT ERROR=0** | `capture/r30_fallback_capture.log`：`[R29][GRADE] Compatibility screen texture 不可用（短跑目视/编译日志判定）→ 降级为程序化 _draw() 强化；shader 未生效（A30 如实登记）`；引擎日志 `450 frames at 30 FPS (movie length: 00:00:15:00)` |
| ③ 目视留证 | 保留首 0 / 中 225 / 尾 449 三帧 `capture/v080_fallback00000000.png / …00000225.png / …00000449.png`（均 1280×720），中间帧按 R29 惯例清理 | 三帧文件 + 本 §3 |
| ④ **恢复** | `GRADE_FORCE_DRAW_FALLBACK` `true → false`（shader 默认档） | 文件第 80 行 `= false`；正式录屏日志 `[R29][GRADE] shader 小样已挂载` |

> **口径澄清（裁决 A37）**：日志里「Compatibility screen texture 不可用」是 `_r29_init()` 降级分支的既有措辞，本次是**强制开关验证**（`GRADE_FORCE_DRAW_FALLBACK=true`）触发，并非 R30 真的检测到 screen texture 失效；R29 与 R30 正式录屏均证实 Compatibility 后端 `hint_screen_texture` 可用、shader 生效。**降级层不是默认效果**，`v080_demo.mp4` 是恢复后的 shader 默认档画面，未回退、未把降级层算作交付画面。

### 3.2 首/中/尾像素 A/B（`v080_demo` shader 档 vs `v080_fallback` 降级层）

| 帧 | mean_abs_diff | max_diff | 差异像素占比(>8) |
|---|---|---|---|
| 首 0 | 11.834 | 141 | 58.52% |
| 中 225 | 5.651 | 111 | 42.30% |
| 尾 449 | 13.340 | 178 | 58.93% |

采样点（shader → 降级，delta）：

| 点 | 首 0 | 尾 449 |
|---|---|---|
| 暖金区 `(904,184)` | `(231,211,159) → (239,224,179)` +8/+13/+20 | **`(255,218,104) → (86,83,76)` −169/−135/−28** |
| 下部 `(320,650)` | `(96,117,120) → (125,153,157)` +29/+36/+37 | `(107,125,125) → (141,164,164)` +34/+39/+39 |
| 左边缘 `(5,360)` | `(110,133,134) → (128,155,157)` +18/+22/+23 | `(116,138,136) → (134,161,160)` +18/+23/+24 |
| 四角 `(10,10)` | `(5,9,23) → (5,11,29)` +0/+2/+6 | `(21,12,28) → (24,14,35)` +3/+2/+7 |
| 上部中心 `(640,100)` | `(21,34,60) → (18,34,65)` −3/0/+5 | `(58,35,53) → (54,31,56)` −4/−4/+3 |

### 3.3 目视与对比结论

- **降级层能跑、不崩、画面完整**：450 帧 EXIT=0 / SCRIPT ERROR=0，三帧地面 / 赐福标题 / 兑换面板 5 行 / 画质面板 / 底部动作 HUD 均完整可读、HUD 未被遮挡、不新增节点。
- **与 shader 默认档画面明显不同**（差异像素 42%~59%）：
  - **暗角更弱、整体更平更亮**：降级层是「6 层四边矩形边框」暗角，边缘/下部采样点普遍比 shader 档亮 +18~+39；shader 档是宽高比校正的平滑径向暗角（一次全屏 screen-reading）。
  - **暖金收束/光晕显著弱**：尾帧 `(904,184)` shader 档 `(255,218,104)` 饱和暖金，降级层仅 `(86,83,76)`；降级层虽有 `_r29_draw_grade()` 的 `draw_arc` 扩散环（尾帧目视可见一道金色圆弧）与同心圆光斑，但强度远不及 shader 档的一次收束高光。
  - **观感更「程序化/分层」**：3 层冷蓝降饱和矩形雾带 + 规则矩形暗角 + 同心圆 + 圆弧，相对 shader 档的全屏采样平滑过渡更生硬；上部中心 `(640,100)` 两档差异极小（−4~+5），说明差异集中在暗角/暖光/收束而非天空底色。
  - 中帧（low/mobile）差异最小（5.651 / 42.30%），因 mobile 档参数 `vignette=0.120 / warm=0.220` 本就弱。
- **恢复确认**：正式 450 帧 `r30_capture.log` 出现 `[R29][GRADE] shader 小样已挂载`，降级层日志未出现该行 → 开关确实来回切换并回到 shader 默认档。

### 3.4 降级层适用场景与代价（写清、不谎称默认）

- **适用场景**：Compatibility 后端 `hint_screen_texture` / screen-reading shader **失效**时（shader 文件加载失败、`SCREEN_TEXTURE` 未定义 / 编译报错、后端不支持屏读），由 `_r29_init()` 关闭 shader、改由本节点 `_draw()` 追加 `_r29_draw_grade()`，兜底「暗角 / 冷夜雾 / 多层景深 / 暖金光晕 / 收束环」四项观感，保证画面不空白、不遮挡 HUD。**R29/R30 实测 screen texture 可用，故平时不启用。**
- **代价**：
  1. **无 screen-reading**：只能 2D 程序化分层矩形/同心圆/圆弧，无法基于屏幕内容做模糊、降饱和、径向渐变 → 暗角更弱更平、暖金收束显著弱（§3.2 像素实证），观感更生硬；
  2. **每帧 CPU 重绘**：`_draw()` 内 `queue_redraw()` 逐帧执行多次 `draw_rect/draw_circle/draw_arc`，CPU draw call 多于 shader 的一次 GPU 全屏 pass；
  3. **参数同源**：仍由 `_r29_params`（读 Rank-2 `depth_profile.tres` 双档）注入，双档切换依赖 `QualitySettings`，与 shader 路径共用；不额外引入素材/GPU job；
  4. **品质下降属「降级」**：只保证「有」，不保证与 shader 档等价；不得计入默认画面效果、不得冒充真 3D 光效。

---

## 4. ViewImage 首 / 中 / 尾三帧（shader 默认档，真看逐帧记录）

| 帧 | 段 / 波 / 画质 | 赐福标题 | 底部动作 HUD | 兑换面板 | 波次 WaveLabel | 地面 |
|---|---|---|---|---|---|---|
| **首 0** | 段 A / 第 1/3 波 / desktop-medium | 「赐福 · 关卡前」**亮金** | `玩家 HP 100/100 ｜ Boss HP 100% ｜ 动作 attack_light 1/27 ｜ 闪避 0 ｜ 命中 0 ｜ 进行中` | 提示态「按 E 打开赐福成长兑换」 | `第 1/3 波 ｜ 赐福点数 0 ｜ 倒计时 0.0 ｜ 历史最佳 0` | 砖块浅/中/深蓝交错、深色短划痕磨损，明暗差异明显 |
| **中 225** | 段 B / 第 2/3 波 / low-mobile | 「赐福 · 巡礼教堂」**亮金** | `玩家 HP 108/120 ｜ Boss HP 100% ｜ 动作 roll 6/22 ｜ 闪避 2 ｜ 命中 4 ｜ 进行中` | **清晰可辨 5 行** | `第 2/3 波 ｜ 赐福点数 0 ｜ 倒计时 29.0 ｜ 历史最佳 1` | 同上；mobile 档四项光效全关、整体较暗 |
| **尾 449** | 段 C / 第 3/3 波 / desktop-high | 「赐福 · 希芙拉河井底」亮金（暖紫背景下目视偏暗，像素仍 GOLD） | `玩家 HP 108/120 ｜ Boss HP 0% ｜ 动作 roll 8/22 ｜ 闪避 2 ｜ 命中 5 ｜ 胜利 · 已落盘` | **清晰可辨 5 行** | `第 3/3 波 ｜ 赐福点数 350 ｜ 倒计时 0.0 ｜ 历史最佳 3` | 同上；**一次明显暖金收束光效/光晕**（地平线中央暖金光柱 + 光点） |

中/尾帧兑换面板 5 行（目视逐字可读）：
`赐福成长 ｜ 当前余额 0（点数 100 − 已消费 100）｜ 1/2/3 兑换` /
`1. 赐福·生命上限 ｜ 消耗 100 ｜ 已解锁` /
`2. 赐福·翻滚余韵 ｜ 消耗 200 ｜ 点数不足` /
`3. 赐福·攻击强化 ｜ 消耗 300 ｜ 点数不足` /
`提示：兑换成功：赐福·生命上限（消耗 100，余额 0）`。

**其它**：三帧均为完整连续冷蓝 4×4 砖地 + 深蓝/暖紫夜空 + 分层山影 + 横向雾带 + 四角暗角；玩家（蓝甲金肩红缨鸢盾）与 Boss（金角红身）近大远小、上下分离；画质设置「低 / 中 / 高」面板三帧均在；暖金光柱/光尘/倒影/bloom 在 desktop 段（首/尾）可见、mobile 段（中）四项全关；HUD 各文字清晰、未被全屏层遮挡（首/中帧「赐福引导」与「赐福标题已点亮」有文字重叠，属 Rank-1 HUD 层既有布局，非本轮 shader 层遮挡）。

### 4.1 图鉴面板（若 Rank-1 已落盘）是否可读

**未出现、不可读判定不适用 —— 如实登记「Rank-1 Tab 注入未落盘」。**
开跑前核查：`find godot -iname "*codex*"` 无结果、`godot/scripts/hud.gd` 无 `codex / 图鉴 / Tab` 关键字；按任务单「并发时序：Rank-1 的 Tab 注入可能尚未落盘 → 图鉴面板未出现在录屏里，如实登记不等待、不伪造」。首/中/尾三帧 ViewImage 均**只有**赐福标题框、右上画质设置面板、兑换面板、底部 HUD，**未见图鉴/Codex/Tab 面板**。本轮不等待、不伪造、不冒领。

### 4.2 HD-2D 全绿是否达到

**未达（如实写未达）**：
1. 景深 / 暗角 / 冷夜雾 / 暖金光晕 / 收束仍是「一次全屏 2D screen-reading 后处理 + `_draw()` 近似」，不是真 3D DoF / 体积光 / SSR / `Environment.glow`；
2. `hd2d_fx.gd` 四项仍为 `draw_rect/draw_colored_polygon/draw_circle/draw_line` 伪光效；三波空间变化仍是 2D 色带/雾 alpha/地面色调；
3. 地面仍是 4×4 大砖程序化 tile（本轮只降低重复感、未消除周期）；角色仍是 `AnimatedSprite3D` billboard 像素精灵；
4. 派生系数 `×5 / ×0.4 / ×25`、`vignette_inner/outer`、`warm_glow_pos`、`FINALE_DELAY/DURATION` 与新增 `uv1_scale 2/1/1`、砖块 `base/steps/磨损数` 均 `[PLACEHOLDER]`，待试玩校准；
5. 仅 3 帧采样 + 逐帧日志 + 像素 A/B 复核，未做全片 450 帧逐帧目视 / 人工试玩逐帧动态验收；
6. 图鉴面板（Rank-1 并发件）未落盘、未出现在录屏。

---

## 5. WAV 是否混入 MP4

**未混入**。Movie Maker 本轮生成 `capture/v080_demo.wav`（5,760,044 B），但 ffmpeg 命令输入仅 `v080_demo%08d.png` 序列、无任何音频 `-i`；`ffprobe -select_streams a` 音频流计数 = **0**。如实登记，不谎报音视频合并。（历史 `frame.wav` / `v070_final.wav` 等同样未参与。）

---

## 6. 门禁与回归（真跑，不回退）

**三段门禁**（`capture/r30_g1_import.log` / `r30_g2_checkonly.log` / `r30_g3_quit.log`）：`--headless --import` / `--headless --check-only --script res://test/presentation.gd` / `--headless --quit` **EXIT=0/0/0**；连同 `r30_capture.log` / `r30_ffmpeg.log` / `r30_fallback_capture.log` 六份日志逐份 `SCRIPT ERROR|Parse Error` = **0** → 字面 **`SCRIPT ERROR=0`**。G1 import 亦验证 `courtyard.tscn` 新增的 `;` `[PLACEHOLDER]` 注释行可被引擎正常解析。

**全 PASS 回归（如实登记未完全达成）**：

| 脚本 | 本轮 | R29 基线 |
|---|---|---|
| `verify_fx_mobile` | 47 PASS / 0 FAIL · `RESULT=PASS` | 47 |
| `verify_fx_profile` | 34 PASS / 0 FAIL · `RESULT=PASS` | 34 |
| `verify_encounter_v010` | 20 PASS · `ALL_MATCH` | 20 |
| `verify_encounter_v020` | 45 PASS · `ALL_MATCH` | 45 |
| `verify_encounter_v030` | 53 PASS · `ALL_MATCH` | 53 |
| `verify_wave_trial_v040` | 58 PASS · `ALL_MATCH` | 58 |
| `verify_frame_data` | **650 PASS / 0 FAIL**（`PASS_COUNT=650`）· `ALL_MATCH` | 650 |
| `verify_tutorial_v060` | 64 PASS · `ALL_PASS` | 64 |
| `verify_tutorial_reward_v060` | 86 PASS · `ALL_MATCH` | 86 |
| `verify_save_isolation_v060` | 31 PASS · `ALL_MATCH` | 31 |
| `verify_tutorial_restart_v060` | 48 PASS / 0 FAIL · `ALL_PASS`（`node_count=41` 断言成立） | 48 |
| **11 项小计** | **1136 PASS / 0 FAIL** | 1136 |
| `verify_wave_runtime_v040` | **35 PASS / 2 FAIL · `RESULT=FAILED`**（重跑同值稳定） | 37 / 0 |
| **合计** | **1171 PASS / 2 FAIL** | **1173 PASS / 0 FAIL** |

**2 个 FAIL 根因（不掩盖、不放宽、不改断言）**：`verify_wave_runtime_v040.gd` 硬编码 uv 期望值，实测读回为

```
[V040] courtyard_node_count PASS=true | node_count=41 expected=41
[V040] uv_groundplate_4  PASS=false | uv1_scale=(2.0, 2.0, 1.0) expected=(4,4,1)
[V040] uv_terracelow_2   PASS=false | uv1_scale=(1.0, 1.0, 1.0) expected=(2,2,1)
[V040] uv_terracehigh_1  PASS=true  | uv1_scale=(1.0, 1.0, 1.0) expected=(1,1,1)
```

即本轮**按任务单 A35 把 uv 从 4/2/1 改为 2/1/1** 后，脚本里两条旧期望值（`uv_groundplate_4` 期望 4、`uv_terracelow_2` 期望 2）未同步 → 断言字面过期。性质：**预期内的断言期望值冲突，非功能回退** —— 41 节点数断言仍 PASS、其余 11 项全 PASS、`uv_terracehigh_1` 仍 PASS、scene 解析/录屏/门禁均正常。按公共契约「不改断言不放宽不掩盖」与目录所有权（验证脚本不在 Rank-4 本轮写入白名单），**Rank-4 未写该脚本**；建议由脚本所有者把 `uv_groundplate` 期望 `4→2`、`uv_terracelow` 期望 `2→1` 同步后复跑，即可恢复 `37 PASS / 0 FAIL`、合计回到 `1173 PASS`。R28 曾出现同类「断言期望值过期」（node_count 38→41），R29 由脚本所有者同步后归零，先例一致。

---

## 7. 目录所有权 / 合规

- 本轮只写：`godot/assets/generated/r23/ground_tile.png`、`godot/scripts/render/hd2d_parallax.gd`（A37 开关临时切换后恢复 + R30 说明注释）、`godot/scenes/courtyard.tscn` 的 **3 处视觉属性 uv1_scale + `;` `[PLACEHOLDER]` 注释**（不新增 `[node`、磁盘节点数恒 41）、`capture/`、`teamwork/Rank-4/`（+ 回执 `teamwork/command_center/ai/4/outbox/`）。
- **未写**：`hd2d_fx.gd` / `hud.gd` / `codex_director.gd` / `presentation.gd`（Rank-1 只读）/ 导演脚本 / `verify_*` 验证脚本 / shader 文件 / 角色 PNG / SpriteFrames `.tres` / `project.godot` / `depth_profile.tres`（Rank-2 只读）/ 契约 / README / `CAPTURE-REPORT.md` 之外的报告；**未自行 git**（总指挥收尾）。
- 公共契约：**先目视检查再接入**（3×3 平铺预览旧/新对照 + 首版偏亮后微调 → 才覆盖；地面/uv 改完才落正式 450 帧；降级层三帧 + shader 三帧 ViewImage + 像素 A/B 后才写结论）；**直接改直接真跑**，未新建只读探针/巡检脚本（降级层短跑复用同一 `presentation.gd`、临时 PNG 已清理）；不伪造产物、不谎报成功（HD-2D 全绿写未达、WAV 未混入、图鉴未落盘、降级层非默认、2 个 FAIL 如实登记、改善不冒领 Rank-1）。零付费、零外部依赖、零新增 GPU job（录屏 GPU 渲染与 ffmpeg 编码串行）。

---

## 8. 未完成项 / 阻塞

- **HD-2D 全绿未达**（§4.2 六项，如实写未达）；
- **图鉴面板（Rank-1 Tab 注入）未落盘**、录屏三帧未出现，按并发时序不等待、不伪造；
- **`verify_wave_runtime_v040` 35/2**：2 个 uv 断言期望值过期，待脚本所有者同步 `4→2 / 2→1` 后复跑恢复 37/0（Rank-4 未写该脚本）；
- `[PLACEHOLDER]` 数值（uv 2/1/1、砖块 base/steps/磨损数、shader 派生系数与节奏）待试玩校准；未做人工试玩逐帧动态验收 / 全片 450 帧逐帧目视；
- 全屏 shader 仍 2D 后处理近似，真 3D DoF / 体积光 / SSR / glow 未实现（P3 不推荐，见 `TECHNICAL-ART-DEPTH-v060.md`）；
- 降级层仅完成一次开关验证 + 目视留证，未作为默认效果、未做长期启用评估；
- 未自行 git（总指挥收尾）。
- **阻塞：无**（2 个 FAIL 为断言期望值过期的已完成登记项，非功能阻塞）。
