# V030-RUNTIME-REVIEW.md — R25 / v0.3.0 实机录屏·运行时目视评审（定稿版）

- 任务单：`cmd-20261110-204604-844-A4`（`[ROUND=R25]`，方向 3 / 5，裁决 A15）
- 执行：Rank-4（美术管线与工具链） · 定稿时间：2026-11-10 21:20（本机 +0800）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official）

> **定稿说明（如实登记并发）**：本任务单被**两个 Rank-4 实例并发执行**。前次实例（约 20:47~21:07）留下
> `v030_*.log`（7 份）、`v030_demo.mp4` 607,659 B、以及一版同名 RUNTIME-REVIEW / DONE / CAPTURE-REPORT 段落；
> 本实例（21:08~21:20）在读取 `presentation.gd` 时发现其已被并发写入一版注入，遂在其基础上修正
> `attack_heavy` 步长（16→20，见 §3）并补 f=220 段 B 注入，重新串行真跑录屏与 ffmpeg，**覆盖**
> `capture/v030_demo*.png` / `v030_demo.mp4` / `v030_demo.wav`，日志以 `capture/r25_*.log` 留档。
> **磁盘最终产物以本定稿（21:18 真跑）为准**：`v030_demo.mp4` = 829,818 B。前次 `v030_*.log` 与
> 其报告数据作为并发历史保留、不删除、不冒充定稿；不臆断并发来源。

- **一句话结论：真跑 450 帧 = 15.000000 s、MP4 真实产出 829,818 B；ViewImage 真看首/中/尾三帧（并加抽 frame 180）——本轮受控 16 色重绘的新骑士与新 4×4 规则砖地确实进入画面、硬边干净无马赛克噪点，底部战斗 HUD 的玩家 HP / Boss HP / 动作帧 / 闪避 / 命中五项全部真实推进（导演层 debug_* 驱动、非文本伪造）；但中帧（frame 225, pose=death 横躺）角色在密集砖地上不可辨、Boss 仍无可见像素形象、景深/光效仍为 2D 近似、地面高倍平铺重复、8 pose 各仅 1 帧无逐帧动画——与《八方旅人》式 HD-2D 目标仍有明显差距。判定「未达全绿」，如实写未达、不冒充达标。**

---

## 1. 录屏与 MP4 实测（本定稿真跑，如实登记）

录屏命令（R22/R24B 已验证形态；末尾位置参数 `res://scenes/courtyard.tscn` 为必需项）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe \
  --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/v030_demo.png \
  --fixed-fps 30 --quit-after 450 \
  --script res://test/presentation.gd \
  res://scenes/courtyard.tscn
```

| 项 | 实测 |
|---|---|
| 录屏 | `CAPTURE_EXIT=0`，**450 张 PNG**，`v030_demo00000000.png` ~ `v030_demo00000449.png`，编号连续 `0..449`，均 **1280×720 RGBA** |
| 时长 | `450 frames at 30 FPS (movie length: 00:00:15:00)` = **15.000000 s**；`时间线完成 frame=450` |
| 非单帧循环 | 首/中/尾 md5 `b4dc270e868944c63320a739be8189c9` / `a090e4435ae0133552fee1052476d134` / `0ceb6d2e3c79f335d9148af097c1b549` 全不同 |
| MP4 | `capture/v030_demo.mp4`，**829,818 B**；`ffmpeg -y -framerate 30 -start_number 0 -i v030_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart v030_demo.mp4`，`FFMPEG_EXIT=0` |
| ffprobe | `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000 / size=829818` |
| WAV | `capture/v030_demo.wav`，**5,760,044 B**（Movie Maker 自动音频轨，单独保留） |
| **WAV 是否混入 MP4** | **未混入**。ffmpeg 输入仅 PNG 序列、无音频 `-i`；`ffprobe -select_streams a` 音频流计数 = **0**，MP4 仅视频轨。与 R22 / R23B / R24B 口径一致，**如实登记，不谎报音视频合并** |
| 日志 | 本定稿 7 份 `capture/r25_*.log`（capture / ffmpeg / G1 / G2 / G3 / verify_mobile / verify_profile） |

> 本轮因替换了 15 张 r23 PNG，录屏前**先真跑 G1 `--headless --import`**（15 个资源全部 reimport，生成新 .ctex），否则命令行运行会沿用旧缓存导致新素材不入画；G1 / G2 在录屏前跑，G3 与两段 verify 在录屏后跑（§6）。录屏（GPU 渲染）与 ffmpeg 编码**串行**执行；本轮零 GPU 生成任务、零付费、零外部素材服务。

---

## 2. 三帧目视结论（ViewImage 真看，非推测）

### 首帧 `v030_demo00000000.png`（frame 0，段 A medium/desktop）
- **新素材进入画面：是**。中央为干净受控 16 色像素骑士 `idle`：红缨盔、钴蓝板甲、暖金肩甲、亮钢面甲、左盾（青宝石）、右竖直亮钢剑、暗红披风，脚下暖金光池；硬边色块、**无渐变 / 无 dithering / 无高频噪点 / 无马赛克**。
- **地面**：4×4 规则大砖、深色砖缝、每砖 3 阶明度（亮蓝高光 / 钴蓝中间调 / 深蓝暗角）+ 规则金石装饰块，颜色干净、砖缝网格连续。
- **底部战斗 HUD（逐字可读）**：`玩家 HP 100/100 | Boss HP 100% | 动作 idle 0/0 | 闪避 0 | 命中 0 | 进行中`（初始态）。
- 顶部：左上金框「赐福 · 宁姆格福」、右上「画质设置 · 低/中/高」面板、深蓝夜空 + 远山剪影 + 星点、中央暖金光柱 + 光尘，均存在。

### 中帧 `v030_demo00000225.png`（frame 225，段 B low/mobile）
- **底部战斗 HUD（逐字可读）**：`玩家 HP 76/100 | Boss HP 95% | 动作 idle 0/0 | 闪避 1 | 命中 2 | 进行中` —— 相对首帧 **玩家 HP 100→76、Boss HP 100%→95%、闪避 0→1、命中 0→2 全部推进**。
- **角色：不可辨（未达，如实登记）**。经 `capture/r25_mid_center_crop.png` 中央区域放大复核，frame 225 画面中央**仅见砖地 + 左侧既有深蓝尖锐形状，无可辨认骑士色块**。该帧 `set_pose` 落在 `death`（step=15, idx=7），本轮重绘的 `death` 帧为「横躺贴地、暗蓝/深红低明度」剪影，在密集透视砖地背景下融入、不可辨。
- 为不臆断归因，加抽 **frame 180**（同属段 B、pose=`attack_light`）：骑士**清晰可见**（水平横斩亮钢剑 + 青色挥砍弧 + 前推盾 + 金肩甲 + 红缨），HUD `玩家 HP 88/100 | Boss HP 95% | 动作 idle 0/0 | 闪避 1 | 命中 2 | 进行中`。故判定为 **death 单帧可辨识度缺陷**，非段 B 画质档整体丢失角色。
- 段 B 四项光效（光柱 / 光尘 / 倒影 / bloom）全关、更暗；标题「赐福 · 巡礼教堂」（暗）；画质面板尺寸一致；砖地仍清晰。

### 尾帧 `v030_demo00000449.png`（frame 449，段 C high/desktop）
- **新素材进入画面：是**。中央骑士 `attack_heavy` 姿态清晰可辨：亮钢剑**高举过头**、金锤状护手、金肩甲、红缨、盾、暗红披风，干净 16 色硬边。
- **底部战斗 HUD（逐字可读）**：`玩家 HP 76/100 | Boss HP 0% | 动作 idle 0/0 | 闪避 1 | 命中 3 | 胜利·已落盘` —— Boss HP 归零、状态转「胜利」，为 C-06 `debug_kill_boss()` 真实结算。
- 光柱 / 光尘 / 光池回归、画质面板可见、左上「希芙拉河井底」暗色未点亮（flag 事件驱动生效）；砖地最锐利。

---

## 3. 战斗 HUD 数值是否推进（本定稿真跑日志 `[R25][COMBAT]`，导演层 `get_snapshot()` 回显）

注入只经 `encounter_director.gd` 既有 `debug_*` 接口；HUD 文本由导演 `_update_hud()` 依真实状态刷新，**未写 `StatusLabel.text`、未伪造数值**。7 个注入点跨段 A/B/C 全程分布（`capture/r25_capture.log`）：

| 帧 | 事件 | 玩家 HP | Boss HP | 动作 / 帧 | 闪避 | 命中 | outcome |
|---:|---|---:|---:|---|---:|---:|---:|
| 30 | C-01 轻攻击命中 | 100 | 98% | attack_light / 12 | 0 | **1** | -1 |
| 60 | C-02 玩家受击 | **88** | 98% | idle / 0 | 0 | 1 | -1 |
| 90 | C-03 翻滚闪避 | 88 | 98% | roll / 5 | **1** | 1 | -1 |
| 150 | C-04 重攻击命中 | 88 | **95%** | attack_heavy / 20 | 1 | **2** | -1 |
| 220 | C-04b 段 B 中段受击 | **76** | 95% | idle / 0 | 1 | 2 | -1 |
| 300 | C-05 轻攻击再推进 | 76 | **94%** | attack_light / 12 | 1 | **3** | -1 |
| 430 | C-06 击败 Boss | 76 | **0%** | idle / 0 | 1 | 3 | **1（胜利）** |

**逐项判定：玩家 HP（100→88→76）变化 ✅ / Boss HP（100%→98→95→94→0%）变化 ✅ / 动作帧（idle→attack_light→roll→attack_heavy→idle，帧号 0→12→5→20）变化 ✅ / 闪避（0→1）变化 ✅ / 命中（0→1→2→3）变化 ✅。五项各至少变化一次，达到。**
（注：本定稿修正了并发版 `presentation.gd` 中 `attack_heavy` 的 `debug_step(16)`——其 startup=20，命中只在 `_frame==20` 结算，step 16 不会命中；改为 `debug_step(20)` 后日志 C-04 确认 `hits_landed=2`、`boss_hp 98%→95%`，重攻击真实命中；并补 f=220 段 B 受击注入，使中帧玩家 HP 推进到 76。）

---

## 4. 逐项判定汇总

| 判定项 | 结论 |
|---|---|
| 新 16 色素材是否进入画面 | **是**（首帧 idle / frame 180 attack_light / 尾帧 attack_heavy 均清晰；4×4 规则砖地全段可见；G1 重新导入生效） |
| 硬约束外观（硬边 / 无渐变 / 无 dithering / 无噪点） | **通过**（画面为干净色块，无 R23 马赛克） |
| 战斗数值是否推进 | **是**（五项全变化，见 §3；三帧 HUD 文本互异） |
| 三段画质切换与 pose 切换 | **保留且生效**（SEG-A/B/C；每 15 帧 `set_pose`，首/中/尾/抽查姿态不同；赐福标题事件驱动变化） |
| Boss 可见像素形象 | **无（未达）**：画面仅中央玩家，`Boss HP` 为 HUD 文本；`boss_spritesheet.png` 虽已重绘，但场景未挂独立 Boss 精灵，与 Rank-1 R24 登记一致，本轮不翻案 |
| 中帧角色可辨性 | **未达**：frame 225 `death` 横躺贴地暗色融入砖地，不可辨（§2）；加抽 frame 180 证明非画质档整体问题 |
| HD-2D 全绿 | **未达**，见 §5 |

---

## 5. 与 HD-2D 目标的差距（未达全绿，如实写未达）

1. **景深 / 光效仍为 2D `draw_*` 近似**：无 3D 深度雾 / DOF / 体积散射 / SSR / HDR bloom；暖金光柱与光尘为 2D 图层，段 B 全关、段 C 回归，非真实体积光。
2. **地面高倍平铺重复感强**：4×4 大砖在 64×64 平面 + 透视下高频重复，虽已规则无缝、零噪点，仍缺近景细节层次与真实湿地倒影。
3. **8 pose 各仅 1 帧、无逐帧动画**：`player_spriteframes.tres` 每个动画只挂 1 张 AtlasTexture，录屏中姿态靠 `set_pose` 整帧切换，非 4/9/9=22 帧翻滚动画。
4. **角色仍为 3D `AnimatedSprite3D` 像素贴图**，非纯 2D 精灵与 3D 场景的分层 HD-2D 合成；本轮只替换贴图内容，未改渲染管线。
5. **Boss 无可见像素形象**（同 R24 边界），三招 spritesheet 未进画面。
6. **death 单帧在密集砖地不可辨**（§2），本轮重绘新暴露的可辨识度回退。
7. **16 色受控重绘相对 R23 数千色素材是细节降级 / 占位化**（裁决 A15 单帧 ≤16 色的必然取舍），不冒充视觉升级。
8. **画面左侧固定深蓝色尖锐几何形状**：首/中/尾及抽查帧均出现、位置固定，为 R23 已登记既有场景/FX 元素，来源未逐一追查，如实登记不臆断。
9. **既有非致命 WARNING**（`2 ObjectDB instances were leaked at exit`）非 SCRIPT ERROR，见 §6。

> 结论：**未达全绿**。本轮达成的是「受控 16 色重绘素材真实进入画面 + 战斗 HUD 数值真实推进」，不是 HD-2D 全绿达标；按公共契约不冒充、不谎报。

---

## 6. 门禁与回归（本定稿真跑，不回退）

| 段 | 命令（`--headless --path <root>`） | 日志 | EXIT |
|---|---|---|---|
| G1 | `--import`（录屏前，重新导入 15 张新 PNG） | `r25_g1_import.log` | **0** |
| G2 | `--check-only --script res://test/presentation.gd` | `r25_g2_checkonly.log` | **0**（注入脚本语法通过） |
| G3 | `--quit` | `r25_g3_quit.log` | **0** |
| RUN mobile | `--script res://scripts/verify_fx_mobile.gd` | `r25_verify_fx_mobile.log` | **0** · `pass=47 fail=0 total=47 RESULT=PASS` |
| RUN profile | `--script res://scripts/verify_fx_profile.gd` | `r25_verify_fx_profile.log` | **0** · `pass=34 fail=0 total=34 RESULT=PASS` |

- **7 份 `capture/r25_*.log` 的 `SCRIPT ERROR|Parse Error` 逐份 0、合计 0，字面 `SCRIPT ERROR=0`**（命令行 grep，含 capture / ffmpeg / 3 门禁 / 2 verify）。
- **47 PASS / 34 PASS 不回退**。
- G3 既有非致命 `WARNING: 2 ObjectDB instances were leaked at exit` 非 SCRIPT ERROR、不改退出码，如实登记。
- 说明：`grep -c` 无匹配时返回退出码 1 属正常，统计值为 0，不代表门禁失败。

---

## 7. 未完成项与如实登记（本评审范围）

1. HD-2D 全绿未达成（§5），不冒充达标；16 色重绘为细节降级。
2. Boss 无可见像素形象；`boss_spritesheet.png` 已重绘但场景未引用其可见精灵。
3. frame 225 `death` 姿态角色不可辨（单帧可辨识度缺陷），本轮未重绘修复、未再重跑录屏，如实登记。
4. WAV（5,760,044 B）**未混入** MP4（音频流 = 0），单独保留，未谎报音视频合并。
5. 未做人工鼠标点击 / 真机试玩逐帧动态验收；Movie Maker 固定步长录屏不等价于实时性能评测。
6. `manifest.json` 为 R23 历史产出记录（仍记 3664~13605 色），本轮未改（不在授权写入对象）；本轮实测色数以 `teamwork/Rank-4/r25_redraw_metrics.json` 与 `DONE-R25.md` 为准。既有 `palette_256.json` / 并发实例产出的 `palette_256_v030.json` 均未被本定稿改写。
7. 双实例并发（见文首「定稿说明」）：磁盘 `v030_demo*.png` / `.mp4` / `.wav` 由本定稿覆盖，`v030_*.log`（前次实例）与 `r25_*.log`（本定稿）并存；前次同名 RUNTIME-REVIEW / DONE 数据（MP4 607,659 B 等）由本定稿文件接管修正，如实登记、不臆断并发来源。
8. `presentation.gd` 在本轮读取后被并发写入一版注入（`_drive_combat_v030`）；本定稿在其基础上修正 `attack_heavy` 步长并补 f=220 段 B 注入，未整体覆盖他人内容。
9. `128bit` 歧义待用户确认、不消歧、不编码进期望值（A15）；人工试玩属用户侧（A17）。
10. git 收尾按公共契约由总指挥执行，本轮未自行 git。

**阻塞：无。** 本评审范围内产物（三帧目视 + 数值推进核验 + 差距登记 + 未达结论 + 门禁结论）全部完成。
