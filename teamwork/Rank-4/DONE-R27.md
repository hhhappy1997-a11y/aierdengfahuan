# DONE-R27.md · Rank-4 交付报告

> 派单 `cmd-20261111-083350-249-A4` · `[ROUND=R27]` · v0.5.0 完善旧内容
> 角色：Rank-4 执行 AI（美术管线与工具链）
> 工程根 `F:/Game/aierdengfahuan` · 协作空间 `teamwork/` · 调度中枢 `teamwork/command_center/`
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）
> ffmpeg `C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`（9.0.2，Bash PATH 里没有）
> 真跑结论：三波空间画面有可辨差异 / Boss 与玩家纵深站位改善 / 左侧尖锐形状已定位并修复消失 /
> Android 图标警告消除 / 15 秒录屏 450 帧 + MP4 合成成功 / 三帧 ViewImage 真看 /
> 三段门禁 `SCRIPT ERROR=0` + `47/34/20/45/53/58/37 + 650 PASS` 全不回退。**HD-2D 全绿仍未达（如实写未达）。**

---

## 0. 本轮任务定位

R26（v0.4.0）遗留三项画面缺口：① 三波无空间节奏差异；② Boss 与玩家并列叠合缺纵深；
③ 画面左中固定深蓝尖锐形状来源未追查。本轮 R27 做「完善旧内容」：
按 `wave_index` 程序化改视差远景、拉开纵深站位、追查并修复尖锐形状、补 Android 项目图标、
改演示序列并真跑 15 秒录屏回看、三段门禁与全 PASS 回归不回退。

---

## 1. 实际交付清单（逐文件，均真实落盘）

| # | 文件 | 动作 |
|---|---|---|
| 1 | `godot/scripts/render/hd2d_parallax.gd` | 改：新增 `wave_index` / `set_wave_index()` / 三波色带·雾·地面·山影·地平线高光参数表，按波次差异绘制；防御性自动读 `WaveTrialDirector.get_snapshot()` |
| 2 | `godot/scenes/courtyard.tscn` | 改**视觉属性**：`Player` transform → `(-3.5,0,2.0)`；`BossVisual` transform → `(0.5,0,-8.0)`；`TerraceHigh` 加 `visible = false`（尖锐形状修复）；`uv1_scale` / `BoxMesh size` / transform 恢复原值以保 `uv_terracehigh_1` 断言 |
| 3 | `godot/project.godot` | **只加一行** `[application]` 段 `config/icon="res://icon.png"`；其它段逐字不动 |
| 4 | `godot/icon.png` | **新增** 128×128 RGBA 金线深蓝图标（程序化 PIL 生成，零素材服务） |
| 5 | `godot/test/presentation.gd` | 改：新增 `_drive_wave_space`（三波边界驱动 `set_wave_index(1/2/3)`）与 `_drive_growth_hud`（纯读成长兑换 HUD 快照）；缓存 `ParallaxBackdrop` 引用；三段画质 / pose / 赐福 flag / 战斗 HUD / 波次 HUD 逐字保留 |
| 6 | `capture/v050_demo00000000.png … v050_demo00000449.png` | **新增 450 帧** 15 秒实机录屏（最终版重跑，严格对应最终代码） |
| 7 | `capture/v050_demo.mp4` | **新增 751,894 B**（libx264 / yuv420p / 1280×720 / 30fps / 450 帧 / 15.000000s） |
| 8 | `capture/V050-RUNTIME-REVIEW.md` | 新增运行期目视复核（三波区分 / 纵深 / 形状 / 全绿 / WAV 四项判定 + 像素实证） |
| 9 | `capture/CAPTURE-REPORT.md` | **独占追加**「## 10. R27 v0.5.0」段落 |
| 10 | `capture/r27_*.log`（20+ 份） | 门禁 / 验证 / 录屏 / ffmpeg / Android 导出 / 受控实验真跑日志 |
| 11 | `capture/r27_probe_a/b/c_*.png` + `r27_shape_crop*.png` | 尖锐形状定位与修复的目视证据 |
| 12 | `teamwork/Rank-4/r27_courtyard_pre_probe_backup.tscn` / `r27_courtyard_final_backup.tscn` | 场景备份（先备份再改；对照实验用） |
| 13 | `build/Aierdengfahuan_r27.apk` (+ `.idsig`) | Android `--export-debug` 真跑产物（未覆盖既有 apk） |
| 14 | `teamwork/Rank-4/DONE-R27.md` | 本文件 |
| 15 | `teamwork/command_center/ai/4/outbox/cmd-20261111-083350-249-A4.json` | 回执 JSON |

---

## 2. 三波空间节奏画面 / 纵深站位（任务①）

`hd2d_parallax.gd` 单节点 `_draw()` 内按 `wave_index`（1/2/3）查表绘制，零新增素材、零 GPU job：

| 波 | 远景色带 top→bot | 雾密度 / 色 | 地面色调 / 强度 | 山影振幅 | 地平线高光 |
|---|---|---|---|---|---|
| 1 冷夜起始 | `#04081A → #142B56` | ×1.00 `#7E96BF` | ×1.00 `#0A1836` | ×1.00 | 冷雾 0.18 |
| 2 深紫浓雾 | `#050A20 → #1E2A58` | **×1.75** `#8E96C8` | **×1.40** `#12164A`（更暗） | ×1.30 | 0.10 |
| 3 暖紫雾散 | `#1A0C22 → #4A2846` | **×0.60** `#C08A6A` | **×0.70** `#2A1428`（更亮偏暖） | ×0.80 | **暖金 0.34** |

**[PLACEHOLDER]** 上述色带 / 雾 / 地面 / 山影数值为演示节奏，待试玩校准。
**rationale**：三波须在同一场景内靠 2D `draw_*` 色带与 alpha 叠加呈现可辨空间变化，
不新增素材、不改 PNG / SpriteFrames、零 GPU job；数值取「冷蓝 → 深紫浓雾 → 暖紫雾散」三段递进以便目视可辨。

`presentation.gd` 在 `frame=0/150/300` 与段 A/B/C、波 1/2/3 严格对齐调用 `set_wave_index(1/2/3)`；
`r27_capture.log` 三行 `[R27][SPACE] ... 回读 wave_index=1/2/3` 实证生效。
未显式驱动时脚本防御性从 `WaveTrialDirector.get_snapshot()["index"]+1` 回退，节点缺失静默回退波 1、不臆造数值。

**像素级客观差异**（避开 HUD 面板）：天空 (620,60) 波1 `(21,33,60)` → 波2 `(36,44,77)` → 波3 `(51,28,49)` 暖紫红；
天空 (620,130) `(31,49,85)` → `(14,30,58)` → `(65,36,61)`；雾带 (620,200) `(29,47,77)` → `(6,14,35)` → `(31,40,63)`；
地面 (1000,620) `(60,79,109)` → `(57,72,109)` → `(70,84,111)`。

**纵深站位**：`Player (0,0,0) → (-3.5, 0, 2.0)`（近、偏左下）、`BossVisual (2,0,0) → (0.5, 0, -8.0)`（远、偏右上），
**x 差 4.0 / z 差 10.0**；三帧实机画面玩家近大、Boss 远小、上下分离，不再并列叠合。
`EncounterRoot/Boss` 的 `sprite_path` 指向 `BossVisual/...` 路径逐字不变，导演层零改动。

---

## 3. Android 图标与导出 stdout 结论（任务②）

- `godot/icon.png`：**128×128 RGBA 金线深蓝**（深蓝底 `#0B1226` + 双金框 + 三重金环 + 黄金树竖干/放射枝 + 四角金饰 + 金核），
  程序化 PIL 绘制、**先 ViewImage 目视通过再接入**；零付费、零外部素材服务。
- `project.godot`：`[application]` 段**只加 `config/icon="res://icon.png"` 一行**（第 36 行），其它段逐字不动。
- 真跑 `--headless --export-debug "Android"`，环境 `JAVA_HOME=D:/AndroidToolchain/jdk17` /
  `ANDROID_HOME=D:/AndroidToolchain/sdk` / `debug.keystore`：**EXIT=0**。
- **stdout 结论**：`capture/r27_export_android.log` 中 `No project icon specified` 计数 = **0**；
  历史对照 `capture/r25b_export_android.log` = **1**（`ERROR: No project icon specified ... export_plugin.cpp:1941`）。
  APK 内生成 `res/mipmap-*/icon.webp` 多分辨率图标、`apksigner` `Signed`、产物 `build/Aierdengfahuan_r27.apk` 29,756,181 B。
  **该历史非致命警告本轮已消除（真跑确认，不谎报消除、也不隐瞒）。**

---

## 4. 左侧尖锐形状来源与修复（任务③）

**受控实验（直接改直接真跑）**：
① 临时隐藏整个 `Terrain` → 形状消失（`r27_probe_a_crop.png`）；
② 只隐藏 `TerraceHigh` → 形状消失（`r27_probe_b_crop.png`）→ 精确定位。

**来源**：`godot/scenes/courtyard.tscn` 的
`SubViewportContainer/SubViewport/Terrain/TerraceHigh` ——
`MeshInstance3D` + `BoxMesh_k5tdy`（`size = Vector3(8, 1.2, 8)`）+
材质 `StandardMaterial3D_uvhigh`（`albedo_texture = res://assets/generated/r23/ground_tile.png`、
`uv1_scale = Vector3(1,1,1)`、`texture_filter = 0`），transform 位置 `(-9, 0.6, -8)`。
**成因**：扁平 BoxMesh 位于远处左侧，从低俯角 `Camera3D(0,8,15)` 斜视时主要看到侧面/顶角，
被冷蓝环境雾 + 暖金 `SunLight` 着色成深蓝双片楔形（首帧实测主色约 `#13285A`），
且 `uv1_scale=1` 与 `GroundPlate` 的 4 倍平铺尺度不一致，看似孤立尖锐几何而非可辨台面。

**修复过程（如实，不把未定位说成已解决）**：
先压扁 `BoxMesh 1.2→0.3`、统一 `uv 1→4`、降低位置 `0.6→0.15`，真跑目视发现宽大楔形
**减弱为一条细斜线但未彻底消失**（`r27_shape_crop_v050.png`，三帧均在 x≈400-490/y≈255-410）；
最终对该节点设 **`visible = false`** 彻底移除，2 帧对照（`r27_probe_c_crop.png`）确认左侧深蓝斜线完全消失、露出完整连续砖地。
为兑现 `verify_wave_runtime_v040` 的 `uv_terracehigh_1` 断言（期望 `(1,1,1)`）与全 PASS 不回退，
把 `uv1_scale` / `BoxMesh size` / transform 恢复原值（节点已隐藏、不参与渲染、对画面零影响）；
最终 450 帧录屏与 MP4 在该最终场景下重跑，产物与代码严格一致。**未改任何素材 PNG / 材质文件。**

---

## 5. 演示序列 / 15 秒录屏 / MP4 / 三帧目视（任务④）

**`presentation.gd`**：新增 `PARALLAX_PATH` 只读引用 + `_parallax` 缓存；
`_drive_wave_space(f)` 在 0/150/300 调用 `set_wave_index(1/2/3)`；
`_drive_growth_hud(f)` 在 0/150/300/449 纯读 `get_snapshot()` 打印赐福点数 / 历史最佳 / `hud_text`，
**绝不写 `Label.text`、不伪造数值**；三段画质切换 / 3 子帧 pose / 赐福 flag / 战斗 HUD / 三波 HUD 逐字保留。
`r27_capture.log` 四行 `[R27][GROWTH]`：赐福点数 **0 → 100 → 250 → 450**。
`WaveTrialHud/WaveLabel`（layer=20）在视差层(5)/光效层(10)之上且光尘逐粒 HUD 避让，三波换色不遮挡成长兑换 HUD。

| 项 | 实测 |
|---|---|
| 录屏 | `--write-movie capture/v050_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`），**EXIT=0** |
| **录屏帧数** | **450 帧**（`v050_demo00000000.png … 00000449.png`），1280×720 @30fps / 15.000000s，`SCRIPT ERROR=0` |
| ffmpeg | 绝对路径 `.../ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`，`-framerate 30 -start_number 0 -i v050_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，**EXIT=0** |
| **MP4 字节数** | **`capture/v050_demo.mp4` = 751,894 B**；ffprobe `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000`，`moov` 前置 |
| **WAV 是否混入 MP4** | **未混入**：ffmpeg 输入仅 PNG 序列、无音频 `-i`；`ffprobe -select_streams a` 音频流计数 = **0**。如实登记 |

**ViewImage 真看首 0 / 中 225 / 尾 449 三帧**（逐帧记录见 `capture/V050-RUNTIME-REVIEW.md` §3）：

| 判定 | 结论 |
|---|---|
| **三波画面是否有区分** | **是（达标）**：首帧冷蓝基准 → 中帧深紫浓雾更暗 → 尾帧暖紫红雾散更亮；目视 + 像素采样 + 3 行 `[R27][SPACE]` 三证一致 |
| **纵深站位是否改善** | **是（达标）**：玩家近大偏左下、Boss 远小偏右上，上下分离，三帧均不叠合（R26 为并列叠合） |
| **左侧尖锐形状是否消失** | **是（已定位并修复）**：三帧该区均为完整连续蓝灰砖地，原深蓝楔形/细斜线完全消失 |
| **成长兑换 HUD 可读** | **是**：金色 WaveLabel `第 1/3 波 点数 0` → `第 2/3 波 点数 100` → `第 3/3 波 点数 450`，赐福标题 / 画质面板 / 底部战斗五项三帧全在 |
| **HD-2D 全绿** | **未达（如实写未达）**：景深/光效仍 2D `draw_*` 近似、三波变化是 2D 色带叠加非真 3D 体积雾、地面高倍平铺重复、角色仍 `AnimatedSprite3D` billboard、未做人工试玩逐帧动态验收、三采样点动作帧 HUD 仍 `idle 0/0` |

---

## 6. 三段门禁 / PASS 回归（任务⑤，真跑 `capture/r27_*.log`）

| 段 | 日志 | EXIT / 结论 |
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

- **字面 `SCRIPT ERROR=0`**：全部 `r27_*.log` 的 `SCRIPT ERROR|Parse Error` 逐份 0、**`TOTAL_SCRIPT_ERROR=0`**。
- **47 / 34 / 20 / 45 / 53 / 58 / 37 PASS 全不回退**，另 650 PASS。
- 过程中一度出现 `verify_wave_runtime_v040` `36/1 FAILED`（我改 `uv_terracehigh` 为 (4,4,1) 触发 `uv_terracehigh_1` 断言）；
  **已恢复 `uv1_scale=(1,1,1)` 并复跑恢复 `37 PASS / ALL_MATCH`**，未留回归。

**如实登记的额外项（非本轮改动、非 R26 回归基线）**：额外跑 Rank-1 R26B 交付的
`verify_wave_persist_v040.gd`（R26 `DONE-R26.md` §7 清单未列该件），稳定 `pass=43 fail=1 RESULT=HAS_FAIL`：
固有 1 项 `D6 十字段齐全` 因 `delta.json` 顶层缺 `slot` / `quests` 失败；首次批量 `36/8` 是
`verify_encounter_v010` 先写盘覆盖 `delta.json` 导致 D 段 `disk=-1` 读回失败（存档状态/运行次序依赖）。
**用 R27 改动前 `courtyard.tscn` 备份做对照实验（`r27_verify_wave_persist_baseline.log`）同样 `43/1 HAS_FAIL`，
证明非本轮 Rank-4 改动引入**（该脚本不引用本轮改动的场景视觉属性 / icon 行 / 视差脚本 / 演示脚本，仅依赖 autoload；
`save_system.gd` 归 Rank-1 独占且其 `--script` 工具模式读回降级为既有行为）。本轮未写该脚本 / 存档系统。

---

## 7. 目录所有权 / 合规

- 只写：`courtyard.tscn` 视觉属性、`project.godot` 图标**一行**、`godot/icon.png`、`hd2d_parallax.gd`、
  `presentation.gd`、`capture/`、`teamwork/Rank-4/`（+ 回执 `command_center/ai/4/outbox/`、导出产物 `build/`）。
- **未写**：`hud.gd` / `save_system.gd` / `wave_trial_director.gd` / 素材 PNG / 两份 `SpriteFrames .tres` /
  契约 / README / 其它 `.tres` / 其它 Rank 工位；**未自行 git**（总指挥收尾）。
- 公共契约：**先目视检查再接入**（图标先 ViewImage 通过后才写 `project.godot`；形状先裁剪 ViewImage 定位 + 受控实验隐藏验证后才落最终修复）；
  **直接改直接真跑**，未新建只读探针 / 巡检脚本、未主动扫目录做进度巡检；
  不伪造产物、不谎报成功（HD-2D 全绿写未达、WAV 未混入如实登记、额外脚本 FAIL 如实登记）。
- 零 GPU 额外 job、零付费、零外部素材生成服务（程序化 PIL / 场景属性）；录屏（GPU 渲染）与 ffmpeg 编码串行。

---

## 8. 未完成项 / 阻塞

1. **HD-2D 全绿未达**（§5 六项，如实写未达，不冒充达标）；
2. 三波色带 / 雾 / 地面数值为 `[PLACEHOLDER]`，待试玩校准；
3. 三采样点动作帧 HUD 仍 `idle 0/0`（既有两套刷新独立，非本轮回归）；
4. 未做人工试玩逐帧动态验收（仅 3 帧采样 + 逐帧日志复核）；
5. `128bit` 具体含义歧义待用户确认；
6. 额外项 `verify_wave_persist_v040` 稳定 `43/1 HAS_FAIL`（非本轮引入、非 R26 基线，见 §6）；
7. 未自行 git（总指挥收尾）。
- **阻塞：无。**

---

## 9. 回执

回执 JSON 写到精确路径（**未写到工程根 `command_center/`**）：
`F:/Game/aierdengfahuan/teamwork/command_center/ai/4/outbox/cmd-20261111-083350-249-A4.json`
内容：`{"task_id":"cmd-20261111-083350-249-A4","ai":4,"status":"done","result":"引用本 DONE-R27.md 实际结论（三波差异/图标导出/尖锐形状修复/450 帧与 MP4 751894 B/三帧目视/PASS/未完成项）"}`。
