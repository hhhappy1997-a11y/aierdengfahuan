# V030-FINAL-REVIEW.md — R25B / v0.3.0 最终画面·首/中/尾三帧目视评审

- 补单：`cmd-20261110-214727-361-A4`（`[ROUND=R25B]`，工程冻结后收口：重录最终画面 + 重导双产物）
- 执行：Rank-4（美术管线与工具链） · 时间：2026-11-10 21:50~21:55（本机 +0800）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）；ffmpeg 9.0.2
- 录屏源：`godot/test/presentation.gd` 定稿（输入注入 + 三段画质切换，本轮零改动）
- 目视方式：ViewImage 真看首/中/尾三帧原图，并用 2× NEAREST 中央放大裁剪
  `capture/r25b_head_center_crop.png` / `r25b_mid_center_crop.png` / `r25b_tail_center_crop.png` 复核角色构成；
  另对照 Rank-1 实证帧 `capture/v030_boss_00000000.png`。

> **一句话结论**：R25B 重录的 450 帧最终画面里，**Boss 第二个角色（金色牛角 + 白脸 + 红披风）在首/中/尾三帧均可见**，
> 首/尾帧与蓝甲骑士并列、中帧单独清晰；底部战斗 HUD 的玩家 HP / Boss HP / 闪避 / 命中四项在三帧采样点真实推进，
> 动作帧以全程 `get_snapshot()` 日志为准有推进（三个采样点均落在 `idle 0/0`，如实登记不粉饰）；
> 16 色重绘素材进入画面、三套 HUD 全程不回退。**但中帧玩家骑士 `death` 横躺贴地仍不可辨（未达，沿袭 R25 结论不翻案）**，
> 且 Boss 与玩家并列叠合、缺纵深站位，HD-2D 全绿仍未达成 —— 如实写未达、不冒充、不谎报。

---

## 1. 录屏与 MP4 实测（本轮真跑）

命令（沿用 R22/R25 定稿形态；`--write-movie` 改指 `v030_final.png`，不加 `--headless` 以保证 Movie Maker 真实渲染）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe \
  --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/v030_final.png \
  --fixed-fps 30 --quit-after 450 \
  --script res://test/presentation.gd \
  res://scenes/courtyard.tscn
```

| 项 | 实测 |
|---|---|
| 前置导入 | `--headless --import`，`IMPORT_EXIT=0` / `SCRIPT ERROR=0`（`capture/r25b_g1_import.log`） |
| 录屏 | `CAPTURE_EXIT=0`；**450 张** `v030_final00000000.png` ~ `v030_final00000449.png`，1280×720 RGBA，编号连续 0..449 |
| 时长 | `450 frames at 30 FPS (movie length: 00:00:15:00)` = **15.000000 s**；recorded in 00:00:23 |
| 非单帧循环 | 首/中/尾 md5 `95d8b62802a783f871f82e210ecb8f30` / `8a27bbe9c88004551d30b976ac0a128c` / `78c2742ba1e676a99f672124e0556683` 全不同 |
| MP4 | `capture/v030_final.mp4` = **867,453 B**；`ffmpeg -y -framerate 30 -start_number 0 -i v030_final%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart v030_final.mp4`，`FFMPEG_EXIT=0` |
| ffprobe | `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000 / size=867453`；`moov` 前置（faststart 生效） |
| WAV | `capture/v030_final.wav` = **5,760,044 B**（Movie Maker 自动音轨，单独保留） |
| **WAV 是否混入 MP4** | **未混入**。ffmpeg 输入仅 PNG 序列、无音频 `-i`；`ffprobe -select_streams a` 音频流计数 = **0**，MP4 仅视频轨。如实登记，不谎报音视频合并 |
| 日志 | `capture/r25b_capture.log` / `capture/r25b_ffmpeg.log`（`SCRIPT ERROR=0`） |

> 与 R25 定稿 `v030_demo.mp4`（829,818 B）对比：本轮为**重录的新序列**（`v030_final*.png` / `v030_final.mp4` / `v030_final.wav`），
> 因 Rank-1 Boss 接线最终修正进入工程，画面出现第二个角色，MP4 字节数 867,453 B（非旧文件改名、非伪造）。

---

## 2. 三帧目视结论（ViewImage 真看，非推测）

### 2.1 首帧 `v030_final00000000.png`（frame 0，段 A medium/desktop）
- **Boss 第二个角色：可见**。经 `r25b_head_center_crop.png` 2× 放大复核，画面中央**并列两个角色**：
  - 左：蓝甲骑士 —— 白色面甲、钴蓝板甲、左盾带青宝石、暖金肩甲、暗红披风、竖直亮钢剑；
  - 右：**「金色牛角（两只）+ 白色脸 + 红/暗红披风 + 金胸甲带青宝石 + 右臂青色横刃」的 Boss**，与 Rank-1
    `capture/v030_boss_00000000.png` 实证形象一致（参考帧 md5 `7ef900bf…`、本帧 `95d8b628…`，
    二者 md5 不同但主体角色构成一致，差异为逐帧光尘粒子等动态元素，如实登记不冒充同一文件）。
- **16 色重绘素材进入画面**：4×4 规则大砖地面（深蓝砖缝 / 蓝灰砖面 / 黄·绿·橙装饰点），角色为干净硬边色块，
  无渐变 / 无 dithering / 无高频噪点 / 无马赛克。
- **三套 HUD 全在**：左上金框「赐福 · 宁姆格福」、右上「画质设置 · 低 / 中 / 高」面板（三按钮）、底部战斗 HUD。
- 深蓝夜空 + 远山剪影 + 星点、中央暖金光柱 + 光尘 + 脚下金色光池；左侧固定深蓝尖锐几何形状（R23 已登记既有元素）。
- 底部 HUD 逐字：`玩家 HP 100/100 | Boss HP 100% | 动作 idle 0/0 | 闪避 0 | 命中 0 | 进行中`。

### 2.2 中帧 `v030_final00000225.png`（frame 225，段 B low/mobile）
- **Boss 可见且清晰可辨**：`r25b_mid_center_crop.png` 2× 放大下，中央仅见一个完整形象 —— 两只金色牛角、
  白色脸（带红色嘴部）、大红披风、左右暖金肩甲（带青色横条）、金胸甲带青宝石。这是本轮因 Rank-1 Boss 接线修正
  新进入画面的 Boss 精灵，清晰、色块分明。
- **玩家骑士不可辨（未达，如实写，不翻案）**：frame 225 的 `set_pose` 落在 `death`（step=15 / idx=7），
  横躺贴地的暗蓝/深红低明度剪影融入密集透视砖地，中央放大图中**找不到蓝甲 / 蓝盾 / 亮钢剑等骑士色块**。
  与 R25 定稿登记的「frame 225 death 角色不可辨」一致，本轮**未重绘修复、未翻案为达标**；
  既不因 Boss 可见就宣称「中帧角色完全可辨」，也不否认 Boss 已可见这一新增事实。
- 段 B 四项光效（光柱 / 光尘 / 倒影 / bloom）全关、画面整体更暗、无光柱；赐福标题变为「赐福 · 巡礼教堂」；
  画质面板尺寸与按钮不变；砖地仍清晰。
- 底部 HUD 逐字：`玩家 HP 76/100 | Boss HP 95% | 动作 idle 0/0 | 闪避 1 | 命中 2 | 进行中`。

### 2.3 尾帧 `v030_final00000449.png`（frame 449，段 C high/desktop）
- **两个角色再次并列可见**（`r25b_tail_center_crop.png` 2× 放大）：左侧蓝甲骑士 `attack_heavy` —— 亮钢剑
  **高举过头**（十字剑柄在上）、暖金肩甲、蓝盾带青宝石；右侧 Boss —— 金角、白脸、红披风、金胸甲青宝石。
- 光柱 / 光尘 / 脚下光池回归、砖地最锐利；左上「赐福 · 希芙拉河井底」暗色未点亮（flag 事件驱动生效）；画质面板在。
- 底部 HUD 逐字：`玩家 HP 76/100 | Boss HP 0% | 动作 idle 0/0 | 闪避 1 | 命中 3 | 胜利·已落盘`
  —— Boss HP 归零、状态转「胜利」，为 C-06 `debug_kill_boss()` 真实结算。

---

## 3. 战斗 HUD 五项数值是否推进（双证）

**证据 A：ViewImage 三帧 HUD 逐字**（见 §2）与 **证据 B：`capture/r25b_capture.log` 7 行 `[R25][COMBAT]`
`get_snapshot()` 真实回显**（注入只经 `EncounterDirector` 既有 `debug_*` 接口，HUD 文本由导演 `_update_hud()`
依真实状态刷新，**未写 `StatusLabel.text`、未伪造数值**）：

| 帧 | 事件 | 玩家 HP | Boss HP（比例） | 动作 / 帧 | 闪避 | 命中 | outcome |
|---:|---|---:|---|---|---:|---:|---:|
| 30 | C-01 轻攻击命中 | 100.0 | 0.9877 | attack_light / 12 | 0 | 1 | -1 |
| 60 | C-02 玩家受击 | 88.0 | 0.9877 | idle / 0 | 0 | 1 | -1 |
| 90 | C-03 翻滚闪避 | 88.0 | 0.9877 | roll / 5 | 1 | 1 | -1 |
| 150 | C-04 重攻击命中 | 88.0 | 0.9596 | attack_heavy / 20 | 1 | 2 | -1 |
| 220 | C-04b 段 B 中段受击 | 76.0 | 0.9596 | idle / 0 | 1 | 2 | -1 |
| 300 | C-05 轻攻击再推进 | 76.0 | 0.9474 | attack_light / 12 | 1 | 3 | -1 |
| 430 | C-06 击败 Boss | 76.0 | 0.0 | idle / 0 | 1 | 3 | 1（胜利） |

| 五项 | 判定 | 说明 |
|---|---|---|
| 玩家 HP | **推进** ✅ | 100→88→76；三帧 100/100 → 76/100 → 76/100 |
| Boss HP | **推进** ✅ | 100%→98.77%→95.96%→94.74%→0%；三帧 100% → 95% → 0% |
| 动作 / 动作帧 | **全程有推进，但三个采样点均为 `idle 0/0`** ⚠️ | 日志 `attack_light/12 → roll/5 → attack_heavy/20 → idle/0` 确证推进；首/中/尾三帧 HUD 恰好都落在 `idle 0/0`（注入发生在离散帧），**如实登记、不粉饰为三帧可见推进** |
| 闪避 | **推进** ✅ | 0→1；三帧 0 → 1 → 1 |
| 命中 | **推进** ✅ | 0→1→2→3；三帧 0 → 2 → 3 |

> 结论：**四项（玩家 HP / Boss HP / 闪避 / 命中）在三帧采样点可见推进，第五项动作帧以全程快照为准有推进**；
> 三帧 HUD 文本互异，非静态文本伪造。

---

## 4. 逐项判定汇总

| 判定项 | 结论 |
|---|---|
| Boss 第二个角色是否可见 | **是**（首/尾帧与骑士并列、中帧单独清晰；金角+白脸+红披风，与 Rank-1 实证一致）—— 相对 R25「Boss 无可见像素形象」为**接线修正带来的真实变化**，如实登记、不冒充本轮改工程 |
| 战斗 HUD 五项数值是否推进 | **是**（四项三帧可见、动作帧全程有推进，见 §3；不粉饰动作帧采样点） |
| 16 色重绘素材是否进画面 | **是**（4×4 规则砖地全段可见；首/尾骑士与 Boss 干净硬边色块；无渐变/噪点/马赛克） |
| 三套 HUD 是否不回退 | **是**（① 赐福标题框「宁姆格福→巡礼教堂→希芙拉河井底」事件驱动变化；② 画质设置面板三按钮三帧均在；③ 底部战斗 HUD 三帧均在且数值推进）全程无消失、无回退 |
| 三段画质切换 / pose 切换 | **保留且生效**（段 A medium/desktop → 段 B low/mobile 四项光效全关 → 段 C high/desktop 光效回归） |
| 中帧角色可辨性 | **未达（不翻案）**：玩家骑士 `death` 横躺不可辨；Boss 清晰可辨（新增事实），二者分别如实登记 |
| HD-2D 全绿 | **未达**，见 §5 |

---

## 5. 与《八方旅人》式 HD-2D 的差距（未达全绿，如实写未达）

1. **景深 / 光效仍为 2D `draw_*` 近似**：无 3D 深度雾 / DOF / 体积散射 / SSR / HDR bloom；暖金光柱与光尘为 2D 图层，段 B 全关、段 C 回归，非真实体积光。
2. **Boss 与玩家并列叠合、缺纵深站位**：两个角色贴在同一画面位置，几乎无前后站位、遮挡关系、投影与景深层次；HD-2D 的「2D 角色 + 3D 场景分层」在这里退化为同平面并排贴图。
3. **地面高倍平铺重复感强**：4×4 大砖在透视下高频重复，虽规则无缝、零噪点，仍缺近景细节层次与真实湿地倒影。
4. **8 pose 各仅 1 帧、无逐帧动画**：姿态靠 `set_pose` 整帧切换，非逐帧动画。
5. **角色仍为 3D `AnimatedSprite3D` 像素贴图**，非纯 2D 精灵与 3D 场景的分层合成；本轮只重录、未改渲染管线。
6. **16 色受控重绘相对 R23 数千色素材是细节降级 / 占位化**（裁决 A15 单帧 ≤16 色的必然取舍），不冒充视觉升级。
7. **中帧玩家 `death` 单帧在密集砖地不可辨**（§2.2），单帧可辨识度缺陷仍在。
8. **画面左侧固定深蓝尖锐几何形状**：首/中/尾均出现、位置固定，为 R23 已登记既有元素，来源未逐一追查，如实登记不臆断。
9. **既有非致命 WARNING**（`2 ObjectDB instances were leaked at exit`）非 SCRIPT ERROR，见 §6。

> 结论：**未达全绿**。本轮达成的是「Boss 第二角色真实进入画面 + 16 色重绘素材 + 战斗 HUD 真实数值推进 + 三套 HUD 不回退」，
> 不是 HD-2D 全绿达标；按公共契约不冒充、不谎报。

---

## 6. 门禁与产物（本轮真跑，详见 `teamwork/Rank-4/DONE-R25B.md`）

- 三段门禁 G1 `--import` / G2 `--check-only --script` / G3 `--quit` 全 `EXIT=0`；
  `verify_fx_mobile 47` / `verify_fx_profile 34` / `verify_encounter_v010 20` / `verify_encounter_v020 45` 全 PASS 不回退；
  13 份 `capture/r25b_*.log` 的 `SCRIPT ERROR|Parse Error` 逐份 0、合计 0 → **`SCRIPT ERROR=0`**。
- 双产物重导 `--export-release "Windows Desktop"` / `--export-debug "Android"` 各 `EXIT=0`；
  `apksigner verify` → `Verifies` / v2=true / v3=true / v4=true / 包名 `com.aierdengfahuan.game`。

---

## 7. 未完成项与如实登记

1. HD-2D 全绿未达成（§5），不冒充达标；16 色重绘为细节降级。
2. **中帧玩家骑士 `death` 横躺不可辨**（单帧可辨识度缺陷），本轮未重绘修复、未翻案；Boss 在中帧清晰可辨为本轮新增事实，二者不互相抵消。
3. Boss 虽可见但与玩家并列叠合、缺前后站位 / 遮挡 / 景深层次，战斗表现力弱。
4. WAV（5,760,044 B）**未混入** MP4（音频流 = 0），单独保留，未谎报音视频合并。
5. 动作帧在首/中/尾三个采样点均为 `idle 0/0`，推进以全程 `get_snapshot()` 日志为准（§3），不粉饰。
6. Android 导出 stdout 一条既有非致命 `ERROR: No project icon specified`（`export_plugin.cpp:1941`），EXIT=0 / 签名成功；
   工程冻结、本轮未改 `application/config/icon`。
7. 未做人工鼠标点击 / 真机试玩逐帧动态验收；Movie Maker 固定步长录屏不等价于实时性能评测。
8. `128bit` 歧义待用户确认、人工试玩属用户侧（沿用 R25 登记）；未生成 `00-汇总.md`、未对跨模块争议裁决。
9. 只写 `capture/`、`teamwork/Rank-4/`、`build/` 导出产物；**未改任何 `godot/` 工程源文件、未改素材**；未执行任何 git 操作（总指挥收尾）。

**阻塞：无。** 本评审范围内产物（三帧目视 + 数值推进核验 + 差距登记 + 未达结论 + WAV 登记）全部完成。
