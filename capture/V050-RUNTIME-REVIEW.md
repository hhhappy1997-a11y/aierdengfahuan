# V050-RUNTIME-REVIEW.md · R27 v0.5.0 15 秒实机录屏运行期目视复核

> 派单 `cmd-20261111-083350-249-A4` · `[ROUND=R27]` · Rank-4（美术管线与工具链）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）
> ffmpeg 9.0.2（本机绝对路径 `C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`，Bash PATH 里没有）
> 真跑产物：`capture/v050_demo*.png` **450 帧** @30fps/15s；`capture/v050_demo.mp4` **751,894 字节**
> 本文件结论以 **ViewImage 真看首/中/尾三帧 + `capture/r27_capture.log` 逐帧日志 + 像素采样** 为准，不粉饰、不谎报。

---

## 1. 真跑与产物（非伪造）

| 项 | 实测 |
|---|---|
| 录屏命令 | `--path <godot> --write-movie capture/v050_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`，沿用 R22/R25/R26 定稿） |
| 录屏 EXIT / 帧数 | **0** / **450 帧**（`v050_demo00000000.png … v050_demo00000449.png`），`Movie Maker 1280×720 @ 30 FPS`、`movie length 00:00:15:00` |
| 录屏日志 | `SCRIPT ERROR\|Parse Error` = **0**；`[R27][SPACE]` 3 行、`[R27][GROWTH]` 4 行、`[R26][WAVE]` / `[R26][POSE]` / `[R22][SEG-*]` 均在 |
| ffmpeg | `-framerate 30 -start_number 0 -i v050_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，**EXIT=0** |
| ffprobe 视频 | `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000`；`moov` 前置（`+faststart`） |
| **MP4 字节数** | **751,894 B**（`capture/v050_demo.mp4`，最终版真跑产物） |
| **WAV 是否混入 MP4** | **未混入**：ffmpeg 输入仅 PNG 序列、无任何音频 `-i`；`ffprobe -select_streams a` 音频流计数 = **0**。如实登记，不谎报音视频合并 |

---

## 2. 三波空间节奏（本轮新增，程序化零素材）

`hd2d_parallax.gd` 新增 `wave_index`（1/2/3）与公开接口 `set_wave_index(w)`；
`presentation.gd` 在三波边界 `frame=0 / 150 / 300` 与 `_drive_segment` 段 A/B/C、`_drive_wave_hud` 波 1/2/3 严格对齐调用，
`r27_capture.log` 三行 `[R27][SPACE] frame=0/150/300 set_wave_index(1/2/3) -> 回读 wave_index=1/2/3` 实证生效。
未显式驱动时脚本防御性回退到 `WaveTrialDirector.get_snapshot()["index"]+1`，节点缺失静默回退波 1、不臆造数值。

| 波 | 远景色带（sky top→bot） | 雾密度 | 地面色调 | 山影振幅 | 地平线高光 |
|---|---|---|---|---|---|
| 1 冷夜起始 | `#04081A → #142B56`（R23 基准） | ×1.00 冷蓝 `#7E96BF` | ×1.00 冷蓝 `#0A1836` | ×1.00 | 冷雾 0.18 |
| 2 深紫浓雾 | `#050A20 → #1E2A58` | **×1.75** 冷紫 `#8E96C8` | **×1.40** 深紫蓝 `#12164A`（更暗） | ×1.30 | 0.10 |
| 3 暖紫雾散 | `#1A0C22 → #4A2846` | **×0.60** 暖 `#C08A6A` | **×0.70** 暖褐 `#2A1428`（更亮偏暖） | ×0.80 | **暖金 `#D89A5A` 0.34** |

**[PLACEHOLDER]** 上述色带 / 雾 / 地面 / 山影数值为演示节奏，待试玩校准。
**rationale**：三波须在同一场景内靠 2D `_draw()` 程序化色带与 alpha 叠加呈现可辨空间变化，
不新增素材、不改 PNG / SpriteFrames、零 GPU job；数值取「冷蓝 → 深紫浓雾 → 暖紫雾散」三段递进以便目视可辨。

**像素级客观对比**（采样点避开赐福/画质 HUD 面板，单位 RGB）：

| 采样点 | 波1 首帧0 | 波2 中帧225 | 波3 尾帧449 |
|---|---|---|---|
| 天空 (620,60) | (21,33,60) 冷蓝 | (36,44,77) 偏紫 | **(51,28,49) 暖紫红**（红分量 21→51） |
| 天空 (620,130) | (31,49,85) | (14,30,58) 更暗 | **(65,36,61) 暖紫红** |
| 雾带 (620,200) | (29,47,77) | (6,14,35) 更浓更暗 | (31,40,63) 转暖 |
| 地面 (1000,620) | (60,79,109) | (57,72,109) 更暗 | (70,84,111) 更亮偏暖 |
| 原形状区 (445,320) | (73,96,129) 砖地 | (71,93,129) 砖地 | (77,98,131) 砖地 |

---

## 3. ViewImage 首 / 中 / 尾三帧（最终版真看，逐帧记录）

| 帧 | 段 / 波 / 画质 | 三波空间画面 | 玩家与 Boss 站位 | 左侧尖锐形状 | 金色 WaveLabel | 其余 HUD |
|---|---|---|---|---|---|---|
| **首 0** | 段 A / 波1 / medium-desktop | 深蓝夜空 + 冷蓝雾带 + 蓝灰砖地（冷蓝基准）；光柱/光尘/光池四项全开 | 玩家（`idle` 蓝甲+金肩甲+白面甲+红缨+鸢盾+竖直亮钢剑）在**画面中下偏左、较大**；Boss（金角红身）在**画面上方偏右、较小**，两者上下分离、近大远小、**不再叠合** | **完全消失**，该处为完整连续的蓝灰 4×4 砖地 | `第 1/3 波 ｜ 赐福点数 0 ｜ 倒计时 1.5 ｜ 历史最佳 0` | 「赐福 · 宁姆格福」/ 画质设置低中高 / `玩家 HP 100/100 \| Boss HP 100% \| 动作 idle 0/0 \| 闪避 0 \| 命中 0 \| 进行中` |
| **中 225** | 段 B / 波2 / low-mobile | 天空明显**更暗更紫**、雾带更浓（画面上部紫雾横带）、地面偏紫蓝且更暗；四项光效全关 | 玩家 `death` 横躺在**下方中央**（头/躯干/腿/散落金框盾与亮钢剑分色可辨），Boss 在**上方远处**，纵深分离、不叠合 | **完全消失**，完整连续砖地 | `第 2/3 波 ｜ 赐福点数 100 ｜ 倒计时 29.0 ｜ 历史最佳 1` | 「赐福 · 巡礼教堂」/ 画质面板在 / `玩家 HP 76/100 \| Boss HP 95% \| 闪避 1 \| 命中 2 \| 进行中` |
| **尾 449** | 段 C / 波3 / high-desktop | 天空明显**偏暖紫红**（顶部紫红渐变）、地平线暖色带、雾更薄、地面更亮偏暖；暖金体积光回归 | 玩家 `attack_heavy` 举剑在**下方**，Boss 在**上方远处**，纵深分离、不叠合 | **完全消失**，完整连续砖地 | `第 3/3 波 ｜ 赐福点数 450 ｜ 倒计时 0.0 ｜ 历史最佳 3` | 「赐福 · 希芙拉河井底」暗色 / 画质面板在 / `玩家 HP 76/100 \| Boss HP 0% \| 闪避 1 \| 命中 3 \| 胜利·已落盘` |

**成长兑换 HUD 可读**：`WaveTrialHud/WaveLabel`（CanvasLayer layer=20、金色 17px）三帧全程清晰；
`r27_capture.log` 四行 `[R27][GROWTH]` 读 `WaveTrialDirector.get_snapshot()` 实证赐福点数 **0 → 100 → 250 → 450**、历史最佳真实读回，
数值由导演层自身 `_refresh_hud()` 刷新，`presentation.gd` 绝不写 `Label.text`、不伪造计数。
视差层 layer=5 / 光效层 layer=10 均在 HUD 层之下，且 `hd2d_parallax.gd` 与 `hd2d_fx.gd` 光尘逐粒 HUD 避让，三波换色不遮挡成长兑换 HUD。
赐福标题框 / 画质设置面板 / 底部战斗五项三帧全在，未回退。

---

## 4. 四项判定

### 4.1 三波画面是否有区分 → **是（本轮达标）**
首帧冷蓝基准、中帧深紫浓雾且整体更暗、尾帧暖紫红雾散且更亮偏暖；
ViewImage 三帧目视 + §2 像素采样（天空红分量 21→36→51、尾帧 (65,36,61) 暖紫）+ 3 行 `[R27][SPACE]` 驱动日志三证一致。

### 4.2 纵深站位是否改善 → **是（本轮达标）**
`courtyard.tscn` 把 `Player` 从 `(0,0,0)` 移到 `(-3.5, 0, 2.0)`（近、偏左下），
`BossVisual` 从 `(2,0,0)` 移到 `(0.5, 0, -8.0)`（远、偏右上），**x 差 4.0、z 差 10.0**；
三帧实机画面中玩家近大、Boss 远小，上下分离，不再像 R26 那样「并列叠合」。

### 4.3 左侧尖锐形状是否消失 → **是（已精确定位并修复）**
来源定位到 **`courtyard.tscn` 的 `SubViewportContainer/SubViewport/Terrain/TerraceHigh`**：
`MeshInstance3D` + `BoxMesh_k5tdy`（size `Vector3(8, 1.2, 8)`）+ 材质 `StandardMaterial3D_uvhigh`
（`albedo_texture=res://assets/generated/r23/ground_tile.png`、`uv1_scale=Vector3(1,1,1)`），
transform 位置 `(-9, 0.6, -8)`。受控实验（`capture/r27_probe_a/b/c_*.png` + 日志）：
① 隐藏整个 `Terrain` → 形状消失；② 只隐藏 `TerraceHigh` → 形状消失 → 精确定位；
③ 隐藏后左侧恢复完整连续砖地。

**成因**：扁平 BoxMesh 位于远处左侧，从低俯角 `Camera3D(0,8,15)` 斜视时主要看到侧面/顶角，
被冷蓝环境雾 + 暖金 `SunLight` 着色成深蓝双片楔形（实测主色约 `#13285A`）；
且 `uv1_scale=1` 与 `GroundPlate` 的 4 倍平铺尺度不一致，看起来像孤立尖锐几何而非可辨台面。

**修复过程（如实登记，不把未定位说成已解决）**：先尝试压扁 `BoxMesh 1.2→0.3`、统一 `uv 1→4`、降低位置 `0.6→0.15`，
真跑目视发现宽大楔形**减弱为一条细斜线但未彻底消失**（`r27_shape_crop_v050.png`）；
最终对该节点设 **`visible = false`** 彻底移除该几何，2 帧对照（`r27_probe_c_crop.png`）确认左侧深蓝斜线完全消失、露出完整砖地。
为兑现 `verify_wave_runtime_v040` 的 `uv_terracehigh_1` 断言（期望 `(1,1,1)`）与「全 PASS 回归不回退」，
把 `uv1_scale` / `BoxMesh size` / transform 恢复原值（节点已隐藏、不参与渲染，对画面零影响）；
最终 450 帧录屏与 MP4 是在该最终场景下重跑的，产物与代码严格一致。**未改任何素材 PNG / 材质文件。**

### 4.4 HD-2D 全绿是否达到 → **未达（如实写未达）**
本轮解决了「三波空间节奏」「纵深站位」「左侧尖锐形状」三项，但以下差距仍在，不冒充达标：
1. 景深 / 光柱 / 光尘 / 光池 / 倒影仍为 2D `draw_*` 近似，非真体积光 / 真景深分层；
2. 三波空间变化是 2D 色带 / 雾 alpha / 地面色调叠加，非真 3D 体积雾 / 动态景深；
3. 地面 4×4 砖高倍平铺重复感仍强；
4. 角色仍是 3D 贴图像素精灵（`AnimatedSprite3D` billboard），非真 3D 体素 / 低多边形角色；
5. 仅做 3 帧采样 + 逐帧日志复核，未做人工试玩逐帧动态验收；
6. 三采样点动作帧 HUD 仍 `idle 0/0`（既有 EncounterDirector HUD 与 `set_pose` 两套刷新独立，非本轮回归）；
7. 三波色带 / 雾 / 地面数值为 [PLACEHOLDER]，待试玩校准。

---

## 5. 门禁与回归（真跑，不回退）

| 段 | 日志（`capture/r27_*.log`） | EXIT / 结论 |
|---|---|---|
| G1 | `r27_g1_import.log`（`--headless --import`） | **0** |
| G2 | `r27_g2_checkonly.log`（`--headless --check-only --script res://test/presentation.gd`） | **0** |
| G3 | `r27_g3_quit.log`（`--headless --quit`） | **0**（仅既有非致命 `2 ObjectDB instances were leaked` WARNING） |
| RUN mobile | `r27_verify_fx_mobile.log` | **0** · `pass=47 fail=0 total=47 RESULT=PASS` |
| RUN profile | `r27_verify_fx_profile.log` | **0** · `pass=34 fail=0 total=34 RESULT=PASS` |
| RUN v010 | `r27_verify_encounter_v010.log` | **0** · `pass=20 fail=0 RESULT=ALL_MATCH` |
| RUN v020 | `r27_verify_encounter_v020.log` | **0** · `pass=45 fail=0 RESULT=ALL_MATCH` |
| RUN v030 | `r27_verify_encounter_v030.log` | **0** · `pass=53 fail=0 RESULT=ALL_MATCH` |
| RUN wave_trial_v040 | `r27_verify_wave_trial_v040.log` | **0** · `pass=58 fail=0 RESULT=ALL_MATCH` |
| RUN wave_runtime_v040 | `r27_verify_wave_runtime_v040.log` | **0** · `pass=37 fail=0 RESULT=ALL_MATCH` |
| RUN frame_data | `r27_verify_frame_data.log` | **0** · `PASS_COUNT=650 FAIL_COUNT=0 RESULT=ALL_MATCH` |

- **字面 `SCRIPT ERROR=0`**：全部 `r27_*.log` 的 `SCRIPT ERROR|Parse Error` 逐份 0、`TOTAL_SCRIPT_ERROR=0`。
- **47 / 34 / 20 / 45 / 53 / 58 / 37 PASS + 650 PASS 全部不回退**（R26 基线）。

**如实登记的额外项（非本轮改动、非 R26 回归基线）**：额外跑了 Rank-1 R26B 交付的
`verify_wave_persist_v040.gd`（R26 `DONE-R26.md` §7 回归清单未列该件），稳定 `pass=43 fail=1 RESULT=HAS_FAIL`：
固有 1 项 `D6 十字段齐全` 因 `delta.json` 顶层缺 `slot` / `quests` 失败；首次批量跑出现 `36/8` 是
`verify_encounter_v010` 先写盘覆盖 `delta.json` 导致 D 段 `disk=-1` 读回失败（存档状态/运行次序依赖），连续跑后稳定 `43/1`。
**用 R27 改动前 `courtyard.tscn` 备份做对照实验（`r27_verify_wave_persist_baseline.log`）同样 `43/1 HAS_FAIL`，
证明该 FAIL 非本轮 Rank-4 改动引入**（脚本不引用 `courtyard.tscn` 视觉属性 / `project.godot` icon 行 /
`hd2d_parallax.gd` / `presentation.gd`，仅依赖 autoload；`save_system.gd` 归 Rank-1 独占且其
`--script` 工具模式读回降级为既有行为）。本轮未写该文件、未自行改存档系统。

---

## 6. 目录所有权 / 合规

- 本轮只写：`courtyard.tscn` 视觉属性、`project.godot` 的 `config/icon` **一行**、`godot/icon.png`、
  `hd2d_parallax.gd`、`presentation.gd`、`capture/`、`teamwork/Rank-4/`（+ 回执 `command_center/ai/4/outbox/`）。
- **未写**：`hud.gd` / `save_system.gd` / `wave_trial_director.gd` / 素材 PNG / 两份 `SpriteFrames .tres` /
  契约 / README / 其它 `.tres` / 其它 Rank 工位；**未自行 git**（总指挥收尾）。
- 公共契约：**先目视检查再接入**（图标先 ViewImage 看后才写 `project.godot`；尖锐形状先裁剪 ViewImage
  定位、受控实验隐藏验证后才落最终修复）；**直接改直接真跑**，未新建只读探针 / 巡检脚本；
  不伪造产物、不谎报成功（HD-2D 全绿写未达、WAV 未混入如实登记、额外脚本 FAIL 如实登记）。
- 零 GPU 额外 job、零付费、零外部素材生成服务（图标与形状修复均程序化 / 场景属性）；录屏（GPU 渲染）与 ffmpeg 编码串行。

---

## 7. 未完成项 / 阻塞

- **HD-2D 全绿未达**（§4.4 七项，如实写未达）；
- 三采样点动作帧 HUD 仍 `idle 0/0`；未做人工试玩逐帧动态验收；
- 三波色带 / 雾 / 地面数值 `[PLACEHOLDER]` 待试玩校准；`128bit` 歧义待用户确认；
- 额外项 `verify_wave_persist_v040` 稳定 `43/1 HAS_FAIL`（非本轮引入、非 R26 基线，见 §5）；
- 未自行 git（总指挥收尾）。
- **阻塞：无。**
