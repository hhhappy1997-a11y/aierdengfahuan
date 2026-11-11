# DONE-R26.md · Rank-4 交付报告

> 派单 `cmd-20261111-073556-932-A4` · `[ROUND=R26]` · v0.4.0 完善旧内容
> 角色：Rank-4 执行 AI（美术管线与工具链）
> 工程根 `F:/Game/aierdengfahuan` · 协作空间 `teamwork/` · 调度中枢 `teamwork/command_center/`
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）· ffmpeg 9.0.2 · PIL 12.3.0
> 真跑结论：素材自检全达标、三段门禁 `SCRIPT ERROR=0` + `47/34/20/45/53 PASS` 不回退、
> 15 秒录屏 450 帧 + MP4 合成成功、三帧 ViewImage 目视已看。**HD-2D 全绿未达（如实写未达）。**

---

## 0. 本轮任务定位

用户此前判定「像素化不是马赛克」，R25（v0.3.0）16 色重绘又出现「积木感」，
R25B 登记「中帧 death 横躺贴地暗色融入砖地、不可辨」。本轮 R26 做**逐像素精修**：
消除积木感、重点修 death 可辨剪影、逐帧动作(每 pose 3 子帧)、地面收敛、
15 秒实机录屏回看、三段门禁回归。

**裁决 A19（用户最新指令覆盖任务单原文）**：本轮 Rank-4 **不写 `courtyard.tscn`**（Rank-1 独占，
避免并发覆盖）；三处 `uv1_scale` `16/3/2 → 4/2/1` 由 Rank-1 顺手改，Rank-4 **只在报告里写建议值**。
任务单原文第 ③ 条「该场景属性由你独占写」已被裁决 A19 取代，按裁决执行。

---

## 1. 实际交付清单（逐文件，均真实落盘）

| # | 文件 | 动作 |
|---|---|---|
| 1 | `godot/assets/generated/r23/player_spritesheet.png` | 覆盖：`1024×128/8帧` → **`3072×128/24帧`** |
| 2 | `godot/assets/generated/r23/boss_spritesheet.png` | 覆盖：`384×128/3帧` → **`1152×128/9帧`** |
| 3 | `godot/assets/generated/r23/player_{idle,walk,run,roll,attack_light,attack_heavy,hitstun,death}.png` | 8 张单帧刷新为对应 pose 第 0 子帧内容，路径不变 |
| 4 | `godot/assets/generated/r23/boss_{p1_dagger_slash,p1_staff_slam,p2_holy_hammer}.png` | 3 张单帧刷新，路径不变 |
| 5 | `godot/assets/generated/r23/ground_tile.png` | 覆盖：收敛版（去绿/黄杂色点） |
| 6 | `godot/assets/generated/r23/decor_layer.png` | 覆盖：沿用 R25 规则几何、路径不变 |
| 7 | `godot/assets/generated/chars/player_spriteframes.tres` | 重写：8 动画 ×3 帧 AtlasTexture region |
| 8 | `godot/assets/generated/boss/boss_spriteframes.tres` | 重写：3 动画 ×3 帧 AtlasTexture region |
| 9 | `godot/test/presentation.gd` | 改：3 子帧演示 + 三波试炼 HUD 防御性驱动，保留三段画质切换 |
| 10 | `capture/v040_demo00000000.png … v040_demo00000449.png` | 新增 **450 帧** 15 秒录屏 |
| 11 | `capture/v040_demo.mp4` | 新增 **754,476 B** |
| 12 | `capture/V040-RUNTIME-REVIEW.md` | 新增运行期目视复核 |
| 13 | `capture/CAPTURE-REPORT.md` | **独占追加**「## 9. R26 v0.4.0」段落 |
| 14 | `capture/r26_*.log`（12 份） | 新增门禁/验证/录屏/ffmpeg 真跑日志 |
| 15 | `teamwork/Rank-4/r26_redraw.py` | 新增程序化 PIL 重绘 + 自检 + `.tres` 生成脚本 |
| 16 | `teamwork/Rank-4/r26_redraw_metrics.json` | 新增自检实测数据 |
| 17 | `teamwork/Rank-4/r26_preview/` + 4 张 `r26_contact_*.png` | 新增预览/联系表（先目视检查再接入） |
| 18 | `teamwork/Rank-4/v030_pre_v040_backup/` | 新增**旧版备份 17 文件**（15 PNG + 两份 `.tres`），先备份再覆盖 |
| 19 | `teamwork/Rank-4/DONE-R26.md` | 本文件 |
| 20 | `teamwork/command_center/ai/4/outbox/cmd-20261111-073556-932-A4.json` | 回执 JSON |

---

## 2. 重绘实测色数 / 帧数 / 备份路径

沿用 `teamwork/艾尔登法环HD2D-美术风格提案.md` 锚点 v1 的 **16 色板** 与外描边 `#0A1020`。
`r26_redraw.py` 把 R25 的 `g.rect()` 大矩形块改为逐像素轮廓化：头盔逐行圆顶 + 金盔脊 +
面甲(眼缝 T 字 / 鼻梁 / 呼吸孔 / 护颊 / 高光) + 红缨斜飘、肩甲逐行斜边梯形 + 高光边 + 铆钉、
披风逐行飘动轮廓 + 明暗褶皱竖条 + 锯齿下摆、胸甲收腰 + 板甲分层线 + 菱形金饰 + 青宝石、
鸢盾逐行弧边、剑身中脊 / 刃高光 / 收尖 / 金剑格 / 缠柄 / 剑首。

| 项 | 实测（对 r23 落盘文件统计，见 `r26_redraw_metrics.json`） |
|---|---|
| 玩家 8 单帧色数 | `idle 16 / walk 16 / run 15 / roll 11 / attack_light 16 / attack_heavy 15 / hitstun 15 / death 15`，**全部 ≤16** |
| Boss 3 单帧色数 | 各 **11 色** |
| `ground_tile.png` | **6 色**、不透明(alpha 全 255) |
| `decor_layer.png` | 8 色 |
| `player_spritesheet.png` | **3072×128 / 24 帧**，每帧 ≤16 色、整表 16 色 |
| `boss_spritesheet.png` | **1152×128 / 9 帧**，每帧 ≤11 色、整表 11 色 |
| 规格 | 64×64 逻辑网格 ×2 NEAREST → 128×128 RGBA；`block2_mismatch=0`（严格 2×2 硬边）；alpha 仅 `{0,255}`；无渐变 / 无 dithering / 无噪点；**色板零越界** |
| ★ death 明度分离 | `death_avg_luma=81.72` vs `ground_avg_luma=67.77`（delta **+13.95**）；主体亮面 `STEEL/WHITE/GOLD/COBALT_L`(L55–95) 与地面 `COBALT/DARK`(L45/22) 差 ≥2 档；横躺抬到画面中部、下方留透明 |
| **备份路径** | **`teamwork/Rank-4/v030_pre_v040_backup/`**（17 文件：15 PNG + `player_spriteframes.tres` + `boss_spriteframes.tres`），先备份再覆盖 |

**重点修 death**：横躺剪影头(亮钢面甲 + 红缨)/躯干(金胸饰 + 青宝石 + 板甲分层)/腿/散落剑盾分色，
不再贴地隐形。中帧 225 实机画面 ViewImage 真看确认可辨（相对 R25B 翻案，见 §6）。

---

## 3. 逐帧动作 / 两份 .tres（路径逐字不变）

| 项 | 实测 |
|---|---|
| 帧数 | 玩家 **8 pose ×3 子帧 = 24 帧**（3072×128）；Boss **3 招 ×3 子帧 = 9 帧**（1152×128） |
| 帧物理顺序 | `x = action*3*128 + sub*128`（= `action*384 + sub*128`） |
| 子帧差异 | 呼吸 `dy` / 武器角度 / 披风褶皱相位 / 腿部步态 / 红缨飘幅；**8 pose + 3 招各 3 子帧 md5 全互异**（`player_all_3_distinct=true`、`boss_all_3_distinct=true`） |
| `player_spriteframes.tres` | 8 动画 ×3 帧；`region.x = action*3*128 + sub*128`（idle 0/128/256、walk 384/512/640、run 768/896/1024、roll 1152/1280/1408、attack_light 1536/1664/1792、attack_heavy 1920/2048/2176、hitstun 2304/2432/2560、death 2688/2816/2944）；`ext path/id` 与动画名逐字不变、loop 保持 |
| `boss_spriteframes.tres` | 3 动画 ×3 帧；`region.x` 0/128/256、384/512/640、768/896/1024；`ext path/id` 与动画名逐字不变 |
| 单帧 PNG | 11 张刷新为对应 pose 第 0 子帧内容，路径不变 |
| 引擎验证 | G1 `--import` / G2 `--check-only` 真跑 EXIT=0，两份 `.tres` 正常加载、无 Parse Error |

---

## 4. 地面收敛 / 裁决 A19

`ground_tile.png`：去绿(TEAL)/黄(GOLD)杂色点与高光杂点，4×4 大砖保持，
明度 4 阶全蓝系(`DARK / COBALT / COBALT_L / SKY_L`) + 缝色 `OUT` + 角部 `INK`，
6 色、不透明，**左右/上下边缘像素逐像素完全一致**
（`LR_mismatch_rows=0 / TB_mismatch_cols=0 / four_corners_equal=true`）。

**裁决 A19**：本轮 Rank-4 **未写 `courtyard.tscn`**（Rank-1 独占，避免并发覆盖）。
三处 `uv1_scale` **建议值 `16/3/2 → 4/2/1`** 仅在本报告登记、不落笔到场景。
只读核对：当前 `courtyard.tscn` 三处已由 Rank-1 落盘为
`Vector3(4,4,1) / Vector3(2,2,1) / Vector3(1,1,1)`（x 分量即 4/2/1），与建议值一致。

---

## 5. `godot/test/presentation.gd` 改动（Rank-4 独占）

- **保留**：三段画质切换 `_drive_segment`（0–149 medium/desktop → 150–299 low/mobile → 300–449 high/desktop）、
  赐福 HUD flag 变化、战斗 HUD 五项注入 —— 三套既有 HUD 全程可读，不回退。
- **① 逐帧动作演示**：`_drive_pose` 改每 5 帧推进一次子帧、3 子帧(0/1/2)轮转、每 15 帧换 pose，
  `frame_index` 与 `HybridSpriteRig._clamp_frame_index`（帧数=3）对齐、无越界；
  `r26_capture.log` 90 行 `[R26][POSE]` 实证 3 子帧真实进画面。`SUBFRAME_INTERVAL=5` 标 **[PLACEHOLDER]** 待试玩校准。
- **② 三波试炼 HUD（防御性追加）**：并发期间 Rank-1 落盘 `WaveTrialDirector` / `WaveTrialHud` 后真实命中；
  只经既有公开接口 `start_trial() / debug_advance(sec) / on_encounter_finished(true) / get_snapshot()`
  确定性推进三波，**绝不写 `Label.text`、不伪造波次数值**；节点未落盘时如实打印跳过、不冒充已驱动。
  `[R26][WAVE]` 三行日志：第 1/3 波(点数 0) → 第 2/3 波(100 / 最佳 1) → 第 3/3 波(250 / 最佳 2) → 尾帧 450/3 全清。

---

## 6. 15 秒录屏 / MP4 字节数 / WAV / 三帧目视结论

| 项 | 实测 |
|---|---|
| 录屏 | `--write-movie capture/v040_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`，沿用定稿），**EXIT=0** |
| **录屏帧数** | **450 帧**（`v040_demo00000000.png … 00000449.png`），1280×720 @30fps / 15.000000s |
| ffmpeg | `-framerate 30 -start_number 0 -i v040_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，**EXIT=0** |
| **MP4 字节数** | **`capture/v040_demo.mp4` = 754,476 B**；ffprobe `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000`，`moov` 前置(+faststart) |
| **WAV 是否混入 MP4** | **未混入**：ffmpeg 输入仅 PNG 序列、无音频 `-i`；`ffprobe -select_streams a` 音频流计数 = **0**。如实登记 |

**ViewImage 真看首 / 中 / 尾三帧（逐项结论，详见 `capture/V040-RUNTIME-REVIEW.md`）**：

| 判定 | 结论 |
|---|---|
| 角色是否还像积木 | **否（达标）**：面甲(眼缝/鼻梁)、金肩甲斜边+铆钉、披风褶皱、剑身中脊/剑格/缠柄、鸢盾金框+青宝石均可辨，逐像素轮廓化脱离 R25 大方块 |
| death 是否可辨 | **是（重点修复达标，相对 R25B 翻案）**：中帧 225 横躺人形头/躯干/腿/上方散落金框盾与亮钢剑分色可辨，亮色主体不再贴地隐形 |
| 地面是否去杂色 | **是**：三帧均为干净蓝灰 4×4 大砖、无绿/黄杂色点与高频噪点、平铺接缝连续 |
| 波次 HUD 是否可读 | **是**：金色 WaveLabel 三波 `第 1/3 → 2/3 → 3/3 波` 真实推进、点数 0→100→250→450、历史最佳 0→1→2→3，全程清晰；赐福标题 / 画质面板 / 底部战斗 HUD 五项三帧全在 |
| **HD-2D 全绿** | **未达（如实写未达）**：景深/光效仍 2D `draw_*` 近似、Boss 与玩家并列叠合缺纵深站位/遮挡、地面高倍平铺重复、左侧固定深蓝尖锐形状来源未追查、角色仍是 3D 贴图像素精灵、未做人工试玩逐帧动态验收、动作帧三采样点 HUD 均 `idle 0/0` |

---

## 7. 三段门禁 / PASS 回归（真跑 `capture/r26_*.log`）

| 段 | 日志 | EXIT / 结论 |
|---|---|---|
| G1 | `r26_g1_import.log`（`--headless --import`） | **0** |
| G2 | `r26_g2_checkonly.log`（`--headless --check-only --script res://test/presentation.gd`，改后重跑） | **0** |
| G3 | `r26_g3_quit.log`（`--headless --quit`） | **0**（仅既有非致命 `2 ObjectDB instances were leaked` WARNING） |
| RUN mobile | `r26_verify_fx_mobile.log` | **0** · `pass=47 fail=0 total=47 RESULT=PASS` |
| RUN profile | `r26_verify_fx_profile.log` | **0** · `pass=34 fail=0 total=34 RESULT=PASS` |
| RUN v010 | `r26_verify_encounter_v010.log` | **0** · `pass=20 fail=0 RESULT=ALL_MATCH` |
| RUN v020 | `r26_verify_encounter_v020.log` | **0** · `pass=45 fail=0 RESULT=ALL_MATCH` |
| RUN v030 | `r26_verify_encounter_v030.log` | **0** · `pass=53 fail=0 RESULT=ALL_MATCH` |
| RUN wave_trial_v040（Rank-2 新增） | `r26_verify_wave_trial_v040.log` | **0** · `pass=58 fail=0 RESULT=ALL_MATCH` |
| RUN wave_runtime_v040（Rank-1 新增） | `r26_verify_wave_runtime_v040.log` | **0** · `pass=37 fail=0 RESULT=ALL_MATCH` |

- **字面 `SCRIPT ERROR=0`**：12 份 `r26_*.log` 的 `SCRIPT ERROR|Parse Error` 逐份 0、合计 **0**
  （`grep -c` 无匹配返回退出码 1 属正常，统计值为 0）。
- **47 / 34 / 20 / 45 / 53 PASS 不回退**（v030 实跑即 53）；两个 R26 新增 v040 脚本额外真跑 58 / 37 PASS。

---

## 8. 目录所有权 / 合规

- 只写：`godot/assets/generated/r23/` 下 PNG、两份 `SpriteFrames` `.tres`（本轮独占授权改 region）、
  `godot/test/presentation.gd`、`capture/`、`teamwork/Rank-4/`（+ 回执 `command_center/ai/4/outbox/`）。
- **未写**：`courtyard.tscn` / `project.godot` / 导演层(`wave_trial_director.gd` 等) / 契约 / README /
  `WAVE-TRIAL-GDD.md` / 其它 `.tres` / 其它 Rank 工位 / `00-*` 总线；**未自行 git**（总指挥收尾）。
- 公共契约：**先目视检查再接入**（4 张 `r26_contact_*.png` ViewImage 真看通过后才 `--commit`）；
  **直接改直接真跑**，未新建只读探针 / 巡检脚本；不伪造产物、不谎报成功（未达全绿写未达、WAV 未混入如实登记）。
- 零 GPU 额外 job、零付费、零外部素材生成服务（程序化 PIL 绘制）；录屏（GPU 渲染）与 ffmpeg 编码串行。

---

## 9. 未完成项 / 阻塞

1. **HD-2D 全绿未达**（§6 七项，如实写未达，不冒充达标）；
2. 三采样点动作帧 HUD 仍 `idle 0/0`（既有 EncounterDirector HUD 与 `set_pose` 两套刷新独立，非本轮回归）；
3. 未做人工试玩逐帧动态验收（仅 3 帧采样 + 逐帧日志复核）；
4. `128bit` 具体含义歧义待用户确认；
5. `SUBFRAME_INTERVAL=5` 为 [PLACEHOLDER] 演示节奏，待试玩校准；
6. 未自行 git（总指挥收尾）。
- **阻塞：无。**

---

## 10. 回执

回执 JSON 写到精确路径（**未写到工程根 `command_center/`**）：
`F:/Game/aierdengfahuan/teamwork/command_center/ai/4/outbox/cmd-20261111-073556-932-A4.json`
内容：`{"task_id":"cmd-20261111-073556-932-A4","ai":4,"status":"done","result":"引用本 DONE-R26.md 实际结论（含实测色数/帧数/备份/录屏/MP4/三帧目视/PASS/未完成项）"}`。

**调度中枢收取机制（如实登记，非伪造、非失败）**：本轮回执写入 `ai/4/outbox/` 后被调度中枢
`dispatcher` watcher 即时收取，移入 `teamwork/command_center/dispatcher/receipts/<id>.json`
并在 `dispatcher/ledger.jsonl` 登记 `status=done`（`dispatcher.log` 两次记录：
`07:58:57` 首版、`08:01:10` 终版）。收取后 outbox 被中枢清空属正常流程。
为满足「精确路径存在文件」的字面要求，已在本轮收尾再次把终版回执写回
`ai/4/outbox/<id>.json`（实测留存 1888 B、合法 JSON、`ai=4/status=done`），
`dispatcher/receipts/` 与 `ledger.jsonl` 同时保有两份送达记录。**回执送达确定无疑。**
