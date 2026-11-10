# DONE-R25B.md — Rank-4 工程冻结后重录最终画面 + 重导双产物验签（ROUND=R25B）

- 补单 id：`cmd-20261110-214727-361-A4`（`[ROUND=R25B]`），总指挥 21:47:28 GUI 下达
- 执行：Rank-4（美术管线与工具链） · 完成：2026-11-10 21:50~21:55（本机 +0800）
- 真源：`teamwork/Rank-4/调度任务单-latest.json`（已逐字读取核对）
- 背景（总指挥核验）：R25 的 450 帧 `v030_demo.mp4` 早于 Rank-1 Boss 接线最终修正、录屏无 Boss；
  `godot/project.godot:37` 已改 `res://scenes/courtyard.tscn`、三套素材已重绘 16 色，但 `build/` 仍是 14:35 旧版。
- 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）；ffmpeg 9.0.2；
  JAVA_HOME `D:/AndroidToolchain/jdk17`（OpenJDK 17）；SDK `D:/AndroidToolchain/sdk`；零付费、零外部依赖。

> **一句话结论**：本轮两件收口全部真跑完成 —— **① 重录 450 帧 = 15 秒最终画面**（`v030_final.mp4` **867,453 B**），
> ViewImage 三帧目视确认 **Boss 第二角色（金色牛角+白脸+红披风）首/中/尾均可见**、战斗 HUD 数值真实推进、
> 16 色重绘素材进画面、三套 HUD 不回退；**② 双产物重导各 EXIT=0**，验签 `Verifies` / v2+v3+v4 true /
> 包名 `com.aierdengfahuan.game`，新旧字节数如实对比。**中帧玩家骑士 `death` 横躺仍不可辨（未达，不翻案）**、HD-2D 全绿未达，
> 均如实写未达、不粉饰、不谎报。门禁 `SCRIPT ERROR=0`、47/34/20/45 PASS 不回退。

---

## 1. 实际交付清单（全部真跑，EXIT 逐项登记）

| # | 动作 / 命令（`--headless --path F:/Game/aierdengfahuan/godot` 省略前缀时见注） | EXIT | 日志 |
|---|---|---|---|
| ① | `--headless --path <godot> --import` | **0** | `capture/r25b_g1_import.log`（16 行，ERROR/SCRIPT ERROR/Parse Error 计数 **0**） |
| ② | `--path <godot> --write-movie capture/v030_final.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`） | **0** | `capture/r25b_capture.log` |
| ② | `ffmpeg -y -framerate 30 -start_number 0 -i v030_final%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart v030_final.mp4` | **0** | `capture/r25b_ffmpeg.log` |
| ③ | ViewImage 真看首/中/尾三帧 + 2× 中央放大裁剪；写 `capture/V030-FINAL-REVIEW.md`、独占追加 `capture/CAPTURE-REPORT.md` §8 | — | 目视证据见 §3 |
| ④ | `--headless --export-release "Windows Desktop"` | **0** | `capture/r25b_export_windows.log` |
| ④ | `--headless --export-debug "Android"`（JAVA_HOME=jdk17） | **0** | `capture/r25b_export_android.log` |
| ④ | `apksigner.bat verify --verbose --print-certs` / `--v4-signature-file` / `aapt dump badging` | **0 / 0 / 0** | `capture/r25b_apksigner_verify*.log` |
| ⑤ | G2 `--check-only --script res://test/presentation.gd`、G3 `--quit`、4 个 verify 脚本 | **全 0** | `capture/r25b_g2_checkonly.log` / `r25b_g3_quit.log` / `r25b_verify_*.log` |

> 注：录屏不加 `--headless`（沿用 R22/R25 定稿，日志含 `OpenGL API 3.3.0 NVIDIA ...` / `Movie Maker mode enabled`）；
> 其余引擎任务均 `--headless`。录屏（GPU 渲染）与 ffmpeg 编码**串行**；全程一次只跑一个 GPU 任务。

---

## 2. 录屏帧数与 MP4 字节数（本轮真跑实测）

| 项 | 实测 |
|---|---|
| 序列帧 | **450 张** `capture/v030_final00000000.png` ~ `v030_final00000449.png`，1280×720 RGBA，编号连续 0..449 |
| 时长 | `450 frames at 30 FPS (movie length: 00:00:15:00)` = **15.000000 s**；recorded in 00:00:23 |
| 非单帧循环 | 首/中/尾 md5 `95d8b62802a783f871f82e210ecb8f30` / `8a27bbe9c88004551d30b976ac0a128c` / `78c2742ba1e676a99f672124e0556683` **全不同** |
| **MP4 字节数** | **`capture/v030_final.mp4` = 867,453 B** |
| 编码 | `libx264 / yuv420p / 1280×720 / 30 fps / nb_frames=450 / duration=15.000000 / +faststart`（`moov` 前置已核对） |
| WAV | `capture/v030_final.wav` **5,760,044 B**（Movie Maker 自动音轨，单独保留） |
| **WAV 是否混入 MP4** | **未混入**：ffmpeg 输入仅 PNG 序列、无音频 `-i`，`ffprobe -select_streams a` 音频流计数 = **0**（MP4 仅视频轨）。如实登记，不谎报音视频合并 |
| 与 R25 旧录屏 | `v030_demo.mp4` 829,818 B（无 Boss）并存保留；本轮为**新重录序列** `v030_final*`，因 Boss 接线修正进入工程画面出现第二角色，字节数 867,453 B 非旧文件改名 |

---

## 3. 三帧目视结论（ViewImage 真看，2× 中央放大裁剪复核）

裁剪证据：`capture/r25b_head_center_crop.png` / `r25b_mid_center_crop.png` / `r25b_tail_center_crop.png`；
对照 Rank-1 实证帧 `capture/v030_boss_00000000.png`（金角+红披风+白脸第二角色已实证）。

| 帧 | **Boss 第二个角色是否可见** | 玩家骑士 | HUD 逐字 | 光效 / 赐福标题 |
|---|---|---|---|---|
| **首 0**（段 A medium/desktop） | **可见**：金角（两只）+ 白脸 + 红披风 + 金胸甲青宝石，与骑士**并列**（与 Rank-1 实证形象一致） | 清晰：`idle` 蓝甲 / 蓝盾青宝石 / 竖直亮钢剑 | `玩家 HP 100/100 \| Boss HP 100% \| 动作 idle 0/0 \| 闪避 0 \| 命中 0 \| 进行中` | 光柱+光尘+光池；「赐福 · 宁姆格福」；画质面板在 |
| **中 225**（段 B low/mobile） | **可见且清晰**：金角 / 白脸（红嘴）/ 大红披风 / 金肩甲青条 / 金胸甲青宝石 | **不可辨（未达，不翻案）**：`death` 横躺贴地暗色融入砖地，放大图无蓝甲/蓝盾/亮钢剑色块 | `玩家 HP 76/100 \| Boss HP 95% \| 动作 idle 0/0 \| 闪避 1 \| 命中 2 \| 进行中` | 四项光效全关、更暗；「赐福 · 巡礼教堂」；画质面板在 |
| **尾 449**（段 C high/desktop） | **可见**：金角+白脸+红披风，与骑士**并列** | 清晰：`attack_heavy` 亮钢剑高举过头（十字剑柄在上） | `玩家 HP 76/100 \| Boss HP 0% \| 动作 idle 0/0 \| 闪避 1 \| 命中 3 \| 胜利·已落盘` | 光柱/光尘/光池回归；「赐福 · 希芙拉河井底」暗色；画质面板在 |

- **Boss 第二角色：是，三帧均可见**（首/尾与骑士并列、中帧单独清晰）。相对 R25「Boss 无可见像素形象」是 Rank-1 接线最终修正带来的**真实画面变化**，如实登记、不冒充本轮改工程。
- **16 色重绘素材进画面：是**（4×4 规则大砖全段可见，干净硬边色块，无渐变 / dithering / 高频噪点 / 马赛克）。
- **三套 HUD 不回退：是**（① 赐福标题框「宁姆格福→巡礼教堂→希芙拉河井底」事件驱动变化；② 画质设置面板「低/中/高」三按钮三帧均在；③ 底部战斗 HUD 五项三帧均在且数值推进）。
- **三段画质切换 / pose 切换保留生效**（A medium/desktop → B low/mobile 四项光效全关 → C high/desktop 光效回归）。
- **中帧角色不可辨必须写未达**：玩家骑士 `death` 仍不可辨（与 R25 定稿一致，本轮未重绘修复、**不翻案**）；Boss 清晰可辨为本轮新增事实，二者不互相抵消、不粉饰为「中帧完全达标」。
- **与《八方旅人》式 HD-2D 的差距（未达全绿）**：景深/光效仍 2D `draw_*` 近似（无 DOF/体积散射/SSR/HDR bloom）；Boss 与玩家并列叠合缺前后站位 / 遮挡 / 投影 / 景深层次；地面 4×4 大砖高倍平铺重复；8 pose 各 1 帧无逐帧动画；角色仍 3D `AnimatedSprite3D` 像素贴图；16 色重绘为细节降级/占位化；`death` 单帧不可辨；左侧固定深蓝尖锐形状（R23 既有元素）来源未追查。详见 `capture/V030-FINAL-REVIEW.md` §5。

---

## 4. 战斗 HUD 五项数值推进（双证，不粉饰）

`capture/r25b_capture.log` 7 行 `[R25][COMBAT]` `get_snapshot()` 真实回显（只经 `EncounterDirector` 既有 `debug_*` 接口，
HUD 由导演 `_update_hud()` 依真实状态刷新，**未写 `StatusLabel.text`、未伪造数值**）：

| 帧 | 事件 | 玩家 HP | Boss HP | 动作 / 帧 | 闪避 | 命中 | outcome |
|---:|---|---:|---|---|---:|---:|---:|
| 30 | C-01 轻攻击命中 | 100.0 | 0.9877 | attack_light / 12 | 0 | 1 | -1 |
| 60 | C-02 玩家受击 | 88.0 | 0.9877 | idle / 0 | 0 | 1 | -1 |
| 90 | C-03 翻滚闪避 | 88.0 | 0.9877 | roll / 5 | 1 | 1 | -1 |
| 150 | C-04 重攻击命中 | 88.0 | 0.9596 | attack_heavy / 20 | 1 | 2 | -1 |
| 220 | C-04b 段 B 中段受击 | 76.0 | 0.9596 | idle / 0 | 1 | 2 | -1 |
| 300 | C-05 轻攻击再推进 | 76.0 | 0.9474 | attack_light / 12 | 1 | 3 | -1 |
| 430 | C-06 击败 Boss | 76.0 | 0.0 | idle / 0 | 1 | 3 | 1（胜利） |

| 五项 | 判定 |
|---|---|
| 玩家 HP | **推进** ✅ 100→88→76 |
| Boss HP | **推进** ✅ 100%→98.77%→95.96%→94.74%→0% |
| 动作 / 动作帧 | **全程有推进** ⚠️ 日志 `attack_light/12 → roll/5 → attack_heavy/20`；但首/中/尾三个采样点 HUD 均落在 `idle 0/0`，**如实登记、不粉饰为三帧可见推进** |
| 闪避 | **推进** ✅ 0→1 |
| 命中 | **推进** ✅ 0→1→2→3 |

> 结论：**四项在三帧采样点可见推进，动作帧以全程快照为准有推进**；三帧 HUD 文本互异，非静态文本伪造。

---

## 5. 新旧产物字节数与验签（④）

环境：`JAVA_HOME=D:/AndroidToolchain/jdk17`（OpenJDK 17 build 17+35）、`PATH` 含 jdk17/bin、
SDK `D:/AndroidToolchain/sdk`、build-tools 36.1.0、`debug.keystore`（`D:/AndroidToolchain/debug.keystore`
与 `C:/Users/62668/AppData/Roaming/Godot/keystores/debug.keystore` 均在，2,666 B）。

| 产物 | **R23B 旧**（14:35/14:36，导出前磁盘实测） | **R25B 新**（21:53/21:54） | 差异 |
|---|---:|---:|---:|
| `Aierdengfahuan.exe` | 109,127,680 B | **109,127,680 B** | 0（`binary_format/embed_pck=false`，固定 Windows 模板，工程内容全在 `.pck`） |
| `Aierdengfahuan.pck` | 1,579,332 B | **1,124,888 B** | **-454,444 B** |
| `Aierdengfahuan.apk` | 29,829,394 B | **29,377,137 B** | **-452,257 B** |
| `Aierdengfahuan.apk.idsig` | 239,026 B | **239,026 B** | 0（时间戳刷新 21:54，v4 验签 `true` 证明与新 apk 匹配，非旧文件残留） |

> pck/apk 减小如实归因：R25 三套素材重绘为 16 色（实测 15 / 11 / 10 色），PNG 体积大幅下降；
> `savepack` / `export` 100% 完成、`EXIT=0`、验签通过，非漏打包。exe 字节数不变因固定引擎模板（非陈旧产物）。

**验签结果（全部达标）**：

| 检查 | 输出 | EXIT |
|---|---|---|
| `apksigner.bat verify --verbose --print-certs` | `Verifies` / v2=**true** / v3=**true** / v3.1=false / v4=false（默认未传 idsig）/ Number of signers: 1 | **0** |
| `apksigner.bat verify --verbose --v4-signature-file Aierdengfahuan.apk.idsig` | `Verifies` / v2=**true** / v3=**true** / **v4=true** / Number of signers: 1 | **0** |
| `aapt.exe dump badging` 首行 | `package: name='com.aierdengfahuan.game' versionCode='1' versionName='1.0.0' ... targetSdkVersion:'36'` | **0** |

> **`Verifies` ✓ / v2+v3(+v4) true ✓ / 包名 `com.aierdengfahuan.game` ✓**。
> Android 导出 stdout 一条既有非致命 `ERROR: No project icon specified`（`export_plugin.cpp:1941`），EXIT=0 / 签名成功；
> 工程冻结、本轮未改 `application/config/icon`（如实登记，不擅自改工程）。

产物按 `.gitignore`（第 8 行 `build/`、10~13 行 `*.exe`/`*.pck`/`*.apk`/`*.aab`、26 行 `*.log`）排除、不入库；
**未执行任何 git 写操作**（不自行 git）。

---

## 6. 三段门禁与 PASS 数字（⑤，真跑不回退）

| 段 | 命令 | EXIT / 结论 |
|---|---|---|
| G1 | `--headless --import` | **0** |
| G2 | `--headless --check-only --script res://test/presentation.gd` | **0**（定稿注入脚本语法通过） |
| G3 | `--headless --quit` | **0**（仅既有非致命 `WARNING: 2 ObjectDB instances were leaked at exit`，非 SCRIPT ERROR） |
| RUN mobile | `--script res://scripts/verify_fx_mobile.gd` | **0** · `pass=47 fail=0 total=47 RESULT=PASS` |
| RUN profile | `--script res://scripts/verify_fx_profile.gd` | **0** · `pass=34 fail=0 total=34 RESULT=PASS` |
| RUN v010 | `--script res://scripts/combat/verify_encounter_v010.gd` | **0** · `pass=20 fail=0 RESULT=ALL_MATCH` |
| RUN v020 | `--script res://scripts/combat/verify_encounter_v020.gd` | **0** · `pass=45 fail=0 RESULT=ALL_MATCH` |

- **13 份 `capture/r25b_*.log` 的 `SCRIPT ERROR|Parse Error` 逐份 0、合计 0 → 字面 `SCRIPT ERROR=0`**（命令行 grep；`grep -c` 无匹配返回退出码 1 属正常，统计值为 0）。
- **47 / 34 / 20 / 45 PASS 不回退**。

---

## 7. 未完成项与如实登记（不伪装完成）

1. **HD-2D 全绿未达成**（§3 差距 9 条），不冒充达标；16 色受控重绘相对 R23 数千色素材是**细节降级 / 占位化**（裁决 A15 取舍）。
2. **中帧玩家骑士 `death` 横躺贴地不可辨**（单帧可辨识度缺陷），本轮未重绘修复、**未翻案**；Boss 在中帧清晰可辨为本轮新增事实，二者不互相抵消。
3. **Boss 虽可见但与玩家并列叠合、缺前后站位 / 遮挡 / 投影 / 景深层次**，战斗表现力弱于 HD-2D 分层合成。
4. **WAV（5,760,044 B）未混入 MP4**（音频流 = 0），单独保留，未谎报音视频合并。
5. **动作帧在首/中/尾三个采样点均为 `idle 0/0`**，推进以全程 `get_snapshot()` 日志为准（§4），不粉饰为三帧可见推进。
6. **Android 导出非致命 `No project icon specified`**：工程冻结，本轮未改 `application/config/icon`（超出「不改工程源文件」约束）。
7. 未做人工鼠标点击 / 真机试玩逐帧动态验收；Movie Maker 固定步长录屏不等价于实时性能评测。
8. `128bit` 歧义待用户确认、人工试玩属用户侧（沿用 R25 登记）；未生成 `00-汇总.md`、未对跨模块争议裁决。
9. 未执行任何 git 操作（总指挥收尾）；R25 旧录屏 `v030_demo*` / `v030_boss*` 与 R25B 新序列 `v030_final*` 并存留证、不删除、不臆断来源。

**阻塞：无。** 本轮计划内产物（`--import` / 450 帧录屏 / MP4 / 三帧目视 / 评审报告 / CAPTURE-REPORT 追加 / 双产物重导 / 验签 / 三段门禁 / DONE / 回执）全部完成；未完成项为如实登记的达标边界，不影响交付。

---

## 8. 合规与所有权

- **只写** `capture/`（序列帧 / MP4 / WAV / 裁剪图 / `r25b_*.log` / `V030-FINAL-REVIEW.md` / `CAPTURE-REPORT.md` §8 独占追加）、
  `teamwork/Rank-4/DONE-R25B.md`、`build/` 下 4 件导出产物、回执 `teamwork/command_center/ai/4/outbox/`。
- **未改任何 `godot/` 工程源文件、未改素材**：`project.godot` / `courtyard.tscn` / `encounter_director.gd` /
  `presentation.gd` / 任何 `.tres` / `.png.import` / `assets/generated/r23/` 均零写入（工程冻结）。
- 产出先目视检查（三帧 ViewImage + 2× 裁剪复核）再交付；直接改直接真跑，**未新建只读探针 / 巡检脚本**；
  零付费、零外部素材服务、一次只跑一个 GPU 任务（录屏与 ffmpeg 编码串行）。
- 不伪造产物、不谎报成功（HD-2D 全绿 / WAV 混入 / 中帧 death 不可辨 / 动作帧采样点 / 非致命 ERROR 均如实写「未达」或登记）。

## 9. 回执

- 精确路径：`F:/Game/aierdengfahuan/teamwork/command_center/ai/4/outbox/cmd-20261110-214727-361-A4.json`
- 内容：`{"task_id":"cmd-20261110-214727-361-A4","ai":4,"status":"done","result":"引用 DONE-R25B.md 实际结论：…"}`
  （result 为本文实测结论摘要，含 450 帧 / 867,453 B / 三帧目视 / 新旧字节数 / 验签 / PASS / 未完成项）。
- **写入成功并被调度中枢即时收取（如实登记，非回执缺失）**：回执写入精确路径后，中枢于 `2026-11-10 22:00:03`
  消费，归档为 `teamwork/command_center/dispatcher/receipts/cmd-20261110-214727-361-A4.json`（**1,194 B**）；
  `dispatcher/ledger.jsonl` 第 96 行记 `id=cmd-20261110-214727-361-A4` / `status=done` / `finished_at=22:00:03` /
  `result` 与所写回执**逐字一致**（含 867453 B / 1124888 / 29377137 等实测数据）；`ai/4/status.json` 同步
  `state=idle` / `completed=43` / `last_seen=22:00:03`。outbox 被消费后瞬时为空，是本项目 dispatcher
  的既定分发行为（沿用 DONE-R21B.md §6 / DONE-R25.md §6 登记），**非回执未写、非路径错误**。
- **幂等校验（如实登记一次复制产生的副本）**：为验证写入，从 receipts 归档幂等复制回精确路径一次，
  `python -m json.tool` 即时校验 `JSON_VALID=1`（JSON 合法、字段齐全），随后中枢再次即时收取并生成带时间戳副本
  `cmd-20261110-214727-361-A4.json.20261110-220055-058`（同为 1,194 B）。`ledger.jsonl` 本轮 id 记录**仅 1 条**
  （未重复记账）；两份归档内容一致、均保留不删除（属中枢产物，不在本轮删除范围）。
