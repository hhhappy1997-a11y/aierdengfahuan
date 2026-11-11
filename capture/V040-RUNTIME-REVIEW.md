# V040-RUNTIME-REVIEW.md · R26 v0.4.0 15 秒实机录屏运行期目视复核

> 派单 `cmd-20261111-073556-932-A4` · `[ROUND=R26]` · Rank-4（美术管线与工具链）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）· ffmpeg 9.0.2 · PIL 12.3.0
> 真跑产物：`capture/v040_demo*.png` 450 帧 @30fps/15s；`capture/v040_demo.mp4` **754,476 字节**
> 本文件结论以 **ViewImage 真看首/中/尾三帧 + `r26_capture.log` 逐帧日志 + `r26_redraw_metrics.json` 自检** 为准，不粉饰、不谎报。

---

## 1. 真跑与产物（非伪造）

| 项 | 实测 |
|---|---|
| 录屏命令 | `--path <godot> --write-movie capture/v040_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`，沿用 R22/R25 定稿） |
| 录屏 EXIT / 帧数 | **0** / **450 帧**，`Movie Maker ... 1280×720 @ 30 FPS`、`movie length 00:00:15:00` |
| ffmpeg | `-framerate 30 -start_number 0 -i v040_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，**EXIT=0** |
| ffprobe 视频 | `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000`；`moov` 在文件头 offset 36（前 4KB 内，`+faststart` 生效） |
| MP4 字节数 | **754,476 B** |
| **WAV 是否混入 MP4** | **未混入**：ffmpeg 输入仅 PNG 序列、无任何音频 `-i`；`ffprobe -select_streams a` 音频流计数 = **0**。如实登记，不谎报音视频合并 |

---

## 2. ViewImage 首 / 中 / 尾三帧（真看，逐帧记录）

| 帧 | 段 / 画质 | 玩家姿态与造型 | 波次 HUD（金色 WaveLabel） | 赐福 / 画质面板 / 底部战斗 HUD | 光效 |
|---|---|---|---|---|---|
| **首 0** | 段 A `medium/desktop` | `idle`：蓝甲 + 金肩甲斜边 + 白面甲(眼缝/鼻梁) + 红缨 + 鸢盾(金框/青宝石) + 竖直亮钢剑（中脊/剑格/缠柄）；Boss 金角红身并列 | `第 1/3 波 ｜ 赐福点数 0 ｜ 倒计时 1.5 ｜ 历史最佳 0` | 「赐福 · 宁姆格福」/ 画质设置低中高 / `玩家 HP 100/100 \| Boss HP 100% \| 动作 idle 0/0 \| 闪避 0 \| 命中 0 \| 进行中` | 光柱+光尘+光池四项全开 |
| **中 225** | 段 B `low/mobile` | **`death` 横躺**：头在左(蓝盔/白面甲/红缨)、躯干居中(金胸饰+青宝石+板甲分层)、腿向右、上方散落金框鸢盾与亮钢剑、红披风；与 Boss 部分叠合 | `第 2/3 波 ｜ 赐福点数 100 ｜ 倒计时 29.0 ｜ 历史最佳 1` | 「赐福 · 巡礼教堂」/ 画质面板在 / `玩家 HP 76/100 \| Boss HP 95% \| 动作 idle 0/0 \| 闪避 1 \| 命中 2 \| 进行中` | 四项光效全关、整体更暗 |
| **尾 449** | 段 C `high/desktop` | `attack_heavy`：亮钢剑高举过头、蓄力金光、金肩甲、披风 | `第 3/3 波 ｜ 赐福点数 450 ｜ 倒计时 0.0 ｜ 历史最佳 3` | 「赐福 · 希芙拉河井底」暗色 / 画质面板在 / `玩家 HP 76/100 \| Boss HP 0% \| 动作 idle 0/0 \| 闪避 1 \| 命中 3 \| 胜利·已落盘` | 光柱/光尘/光池回归 |

- 三波 HUD 由 `presentation.gd::_drive_wave_hud` 只经 `WaveTrialDirector` 既有公开接口
  `start_trial() / debug_advance(sec) / on_encounter_finished(true) / get_snapshot()` 确定性推进，
  `r26_capture.log` 三行 `[R26][WAVE]` 与三帧 HUD 逐字双证：
  第 1/3 波(点数 0) → 第 2/3 波(点数 100、历史最佳 1) → 第 3/3 波(点数 250、历史最佳 2) → 尾帧 450/3（三波全清）。
  **数值由导演层自身 `_refresh_hud()` 刷新，脚本不写 `Label.text`、不伪造波次计数。**
- 三段画质切换 `r26_capture.log` 三行 `[R22][SEG-A/B/C]` 与三帧光效/画质面板状态一致（medium→low→high）。

---

## 3. 四项判定

### 3.1 角色是否还像积木 → **否（本轮达标）**
R25 的 8 pose 是大矩形堆叠；本轮 `r26_redraw.py` 逐像素轮廓化：
头盔逐行圆顶 + 金盔脊 + 面甲(眼缝 T 字 / 鼻梁 / 呼吸孔 / 护颊 / 高光) + 红缨斜飘、
肩甲逐行斜边梯形 + 左上高光边 + 下缘阴影 + 铆钉、披风逐行飘动轮廓 + 明暗褶皱竖条 + 锯齿下摆、
胸甲逐行收腰 + 板甲分层线 + 菱形金饰 + 青宝石、鸢盾逐行弧边、剑身中脊/刃高光/收尖/金剑格/缠柄/剑首。
三帧实机画面中面甲、肩甲、披风褶皱、剑盾细节均可辨，**不再是大方块积木感**。
（自检：单帧非透明唯一 RGB 11–16 色 ≤16、严格 2×2 硬边 `block2_mismatch=0`、alpha 仅 0/255、色板零越界。）

### 3.2 death 是否可辨 → **是（本轮重点修复达标，相对 R25B 翻案）**
R25B 结论为「中帧 death 贴地暗色融入砖地、不可辨」。本轮把横躺剪影抬到画面中部、
头/躯干/武器分色、主体亮面用 `STEEL/WHITE/GOLD/COBALT_L`(L55–95) 与地面 `COBALT/DARK`(L45/22) 分离，
下方留透明不贴地。中帧 225 实机画面可辨「横躺人形」：左侧头(白面甲+红缨)、中部蓝金躯干+青宝石、
上方散落的金框盾与亮钢剑、右侧腿与靴。
自检 `death_avg_luma=81.72` vs `ground_avg_luma=67.77`（delta **+13.95**，death 整体亮于地面）；
主体亮面与地面主色差 ≥2 档明度。**如实翻案，但不冒充 HD-2D 全绿**（见 §4）。

### 3.3 地面是否去杂色 → **是**
`ground_tile.png` 去掉 R25 的绿(TEAL)/黄(GOLD)中心装饰点与高光杂点，
4×4 大砖保持，明度 4 阶全蓝系(`DARK/COBALT/COBALT_L/SKY_L`) + 缝色 `OUT` + 角部 `INK`，
实测 **6 色**、不透明(alpha 全 255)、左右/上下边缘像素逐像素完全一致
(`LR_mismatch_rows=0 / TB_mismatch_cols=0 / four_corners_equal=true`)。
三帧实机地面均为干净蓝灰砖、无绿/黄杂色点与高频噪点；2×2 平铺接缝连续。

### 3.4 波次 HUD 是否可读 → **是**
`WaveTrialHud/WaveLabel`（CanvasLayer layer=20、金色 17px、`第 X/3 波 ｜ 赐福点数 … ｜ 倒计时 … ｜ 历史最佳 …`）
在三帧均清晰可读，且三波 1/3→2/3→3/3 真实推进、点数与历史最佳递增。
既有三套 HUD（赐福标题框 / 画质设置面板 / 底部战斗五项）三帧全程在，未回退。
**动作帧三采样点仍显示 `idle 0/0`**（既有 EncounterDirector HUD 与 presentation 的 `set_pose` 是两套独立刷新），
如实登记、不粉饰；pose 逐帧推进以 `r26_capture.log` 的 `[R26][POSE]` 90 行日志为准。

---

## 4. HD-2D 全绿判定 → **未达（如实写未达）**

以下差距本轮未解决，均如实登记、不冒充达标：
1. 景深 / 光柱 / 光尘 / 光池 / 倒影仍为 2D `draw_*` 近似，非真体积光 / 景深分层；
2. Boss 与玩家并列叠合、缺纵深站位与遮挡（中/尾帧尤其明显）；
3. 地面 4×4 砖高倍平铺重复感仍强；
4. 画面左中固定深蓝尖锐形状来源未追查（既有现象，非本轮引入）；
5. 角色仍是 3D 贴图像素精灵（`AnimatedSprite3D` billboard），非真 3D 体素 / 低多边形角色；
6. 仅做 3 帧采样 + 逐帧日志复核，未做人工试玩逐帧动态验收；
7. 三采样点动作帧 HUD 均 `idle 0/0`（见 §3.4）。

---

## 5. 门禁与回归（真跑，不回退）

| 段 | 日志（`capture/r26_*.log`） | EXIT / 结论 |
|---|---|---|
| G1 | `r26_g1_import.log`（`--headless --import`） | **0** |
| G2 | `r26_g2_checkonly.log`（`--headless --check-only --script res://test/presentation.gd`） | **0**（改后重跑） |
| G3 | `r26_g3_quit.log`（`--headless --quit`） | **0**（仅既有非致命 `2 ObjectDB instances were leaked` WARNING） |
| RUN mobile | `r26_verify_fx_mobile.log` | **0** · `pass=47 fail=0 total=47 RESULT=PASS` |
| RUN profile | `r26_verify_fx_profile.log` | **0** · `pass=34 fail=0 total=34 RESULT=PASS` |
| RUN v010 | `r26_verify_encounter_v010.log` | **0** · `pass=20 fail=0 RESULT=ALL_MATCH` |
| RUN v020 | `r26_verify_encounter_v020.log` | **0** · `pass=45 fail=0 RESULT=ALL_MATCH` |
| RUN v030 | `r26_verify_encounter_v030.log` | **0** · `pass=53 fail=0 RESULT=ALL_MATCH` |
| RUN wave_trial_v040（Rank-2 新增） | `r26_verify_wave_trial_v040.log` | **0** · `pass=58 fail=0 RESULT=ALL_MATCH` |
| RUN wave_runtime_v040（Rank-1 新增） | `r26_verify_wave_runtime_v040.log` | **0** · `pass=37 fail=0 RESULT=ALL_MATCH` |

- **字面 `SCRIPT ERROR=0`**：全部 12 份 `r26_*.log` 的 `SCRIPT ERROR|Parse Error` 逐份 0、合计 **0**
  （`grep -c` 无匹配返回退出码 1 属正常，统计值为 0）。
- **47 / 34 / 20 / 45 / 53 PASS 不回退**（v030 实跑即 53）；两个 R26 新增 v040 验证脚本额外真跑 58 / 37 PASS。

---

## 6. 裁决 A19 / 目录所有权（合规登记）

- **裁决 A19：本轮 Rank-4 未写 `courtyard.tscn`**（Rank-1 独占，避免并发覆盖）。
  三处 `uv1_scale` 建议值 **16/3/2 → 4/2/1** 仅在本报告登记，不落笔到场景。
  只读核对：`courtyard.tscn` 当前三处已由 Rank-1 落盘为
  `Vector3(4,4,1) / Vector3(2,2,1) / Vector3(1,1,1)`（x 分量即 4/2/1），与建议值一致，**本轮未写**。
- 本轮只写：`godot/assets/generated/r23/` 下 PNG、两份 `SpriteFrames` `.tres`、
  `godot/test/presentation.gd`、`capture/`、`teamwork/Rank-4/`。
  未写 `courtyard.tscn` / `project.godot` / 导演层 / 契约 / README / 其它 `.tres`；未自行 git。
- 零 GPU job 额外负载、零付费、零外部素材生成服务（程序化 PIL 绘制）；录屏（GPU 渲染）与 ffmpeg 编码串行。

---

## 7. 未完成项 / 阻塞

- **HD-2D 全绿未达**（§4 七项，如实写未达）；
- 三采样点动作帧 HUD 仍 `idle 0/0`（既有两套刷新独立，非本轮回归）；
- 未做人工试玩逐帧动态验收；`128bit` 歧义待用户确认；
- `SUBFRAME_INTERVAL=5` 为 [PLACEHOLDER] 演示节奏，待试玩校准；
- 未自行 git（总指挥收尾）。
- **阻塞：无。**
