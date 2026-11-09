# V020-RUNTIME-REVIEW.md — R24B v0.2.0 15 秒实机录屏目视回看

> 补单 `cmd-20261109-211247-261-A4`（`[ROUND=R24B]`）· Rank-4（美术管线与工具链）
> 四路 R24 已全部 done、工程冻结，本轮只补 15 秒实机录屏与总指挥目视回看证据，不改任何 `godot/` 工程文件 / 美术资源。
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable）· 2026-11-09 本机 +0800 · OpenGL 3.3 / NVIDIA RTX 4060 Ti
>
> **一句话结论：450 帧 = 15.000000 s 真实完整画面、MP4 真实产出；ViewImage 首/中/尾三帧真看——底部战斗 HUD 可见可读、深蓝夜景 / 三层视差远景 / 赐福 HUD / 画质面板不回退、行为跨整段推进；但 Boss 仍无可见像素形象（与 Rank-1 R24 登记一致，不翻案），HD-2D 全绿仍未达，如实写「未达」。**

---

## 0. 真跑命令与产物（如实登记）

复用 `godot/test/presentation.gd`，按 R22/R23 已验证命令形态（命令末尾位置参数 `res://scenes/courtyard.tscn` 为 R22 已验证的必需项，否则 Movie Maker 只录 2D CanvasLayer、3D 主体不入画）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe \
  --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/v020_demo.png \
  --fixed-fps 30 --quit-after 450 \
  --script res://test/presentation.gd \
  res://scenes/courtyard.tscn
```

| 项 | 真跑结果 |
|---|---|
| `CAPTURE_EXIT` | **0**（run2 定稿） |
| Movie Maker | `recording movie in 1280×720 @ 30 FPS` |
| **PNG 序列** | **450 张**，`v020_demo00000000.png` ~ `v020_demo00000449.png`，编号连续 `0..449`（内联 python 校验 `continuous_0_449=True`），IHDR 均 **1280×720** |
| 时长 / 帧率 | `450 frames at 30 FPS (movie length: 00:00:15:00)` = **15.000000 s** |
| 时间线 | `SEG-A frame=0` / `SEG-B frame=150` / `SEG-C frame=300` / `时间线完成 frame=450`（非单帧循环） |
| WAV | `v020_demo.wav`，**5,760,044 B**，Movie Maker 自动音频轨，单独保留 |
| ffmpeg | `ffmpeg -y -framerate 30 -start_number 0 -i v020_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart v020_demo.mp4`，`FFMPEG_EXIT=0` |
| **MP4** | `capture/v020_demo.mp4`，**1,488,378 B**；ffprobe：`h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000` |
| **WAV 是否混入** | **未混入**。ffprobe 音频流计数 = **0**，MP4 仅视频轨；`v020_demo.wav` 单独保留。与 R22 `r22_demo.mp4`、R23B `r23_final.mp4` 口径一致，如实登记、不谎报音视频合并 |
| 首/中/尾 md5 | `2c90061aa2b5` / `f118adc56675` / `0cb370952d6f`（全不同 → 非单帧循环） |

**首次真跑偶发短录（如实留档，不掩盖、不冒充）**：同一命令的 run1 只录得 **285 帧 = 9.5 s**（`285 frames at 30 FPS (movie length: 00:00:09:15)`，日志 `v020_capture_run1.log`），时间线停在 `frame=270`、无 `SEG-C`、无「时间线完成 frame=450」。清理 `v020_demo*` PNG/WAV 后**串行重跑 run2**（同一已验证命令、未改任何工程文件 / 未改脚本参数）得到完整 450 帧。run1 根因未逐一追查（R24 新增 `[BossController]` 随机抽招时序 / 首次运行预热均有可能），**如实登记不臆断**；Grep 诊断确认 `godot/` 运行时脚本无主动 `quit()`（`boss_controller.gd` 明确「不 change_scene / 不 queue_free 整个节点」，`quit()` 仅存在于 build_/verify_/perf_ 一次性脚本），故按偶发短录留证，定稿采用 run2。首次与定稿两份日志均保留在 `capture/`。

> 录屏为**单个 GPU/编码任务**（非 headless），ffmpeg 合成为另一个编码任务，两者**串行**、未与其它 GPU 任务并行。

---

## 1. 首 / 中 / 尾三帧目视（ViewImage 真看，非推测）

| 帧 | 文件 | 档位 | 目视所见 |
|---|---|---|---|
| **首 0** | `v020_demo00000000.png` | 段 A medium / desktop 四项全开 | 深蓝夜空 + 星点 + 远山剪影 + 横向冷蓝雾带（多层分层远景）；暖金/棕褐/青灰/橙点密集不规则石砖透视铺满下半屏；中央**红发 + 钴蓝板甲 + 金饰**像素骑士 idle 站立、脚下暖金光池；右上暖金垂直光柱 + 光尘点；左上金线深蓝 HUD「赐福 · 宁姆格福」，右上「画质设置 · 低 / 中 / 高」金框三按钮；**底部 y≈660 金色战斗 HUD 文字条清晰可读**。左侧有一固定深蓝色尖锐几何形状（见 §6） |
| **中 225** | `v020_demo00000225.png` | 段 B low / mobile 四项全关 | 石砖纹理依旧清晰、砖缝/像素网格较首帧略粗（low 档 `stretch_shrink=3`）；角色换为**红白头饰 + 钴蓝甲 + 金护肩 + 蓝下摆** pose，完整可见、未被 HUD 遮挡；**四项光效（光柱/光尘/倒影光池/bloom）全部消失**，画面整体更暗；深蓝夜空 + 山影 + 雾带仍在；左上标题变「赐福 · 巡礼教堂」（暗灰未点亮），画质面板尺寸与首帧一致；底部战斗 HUD 依旧清晰可读 |
| **尾 449** | `v020_demo00000449.png` | 段 C high / desktop 四项全开 | 石砖最锐利、细节最密；角色为**红发 + 黄黑格纹头巾 + 钴蓝甲 + 胸前发光青蓝宝石** pose，无破图/重复小人/空白；深蓝夜空 + 分层山影 + 雾带 + 暖金光柱 + 光尘 + 脚下光池回归；左上「赐福 · 希芙拉河井底」为**暗色未点亮态**（frame=420 flag=false，HUD 事件驱动生效）；画质面板仍可见；底部战斗 HUD 依旧清晰可读 |

---

## 2. 逐项检查结论（按派单要求逐条）

| # | 检查项 | 判定 | 依据 |
|---|---|---|---|
| 1 | **底部战斗 HUD 是否可见可读** | **可见可读（达到）** | 三帧底部 y≈660 均有金色文字条，逐字可读：`玩家 HP 100/100 ｜ Boss HP 100% ｜ 动作 idle 0/0 ｜ 闪避 0 ｜ 命中 0 ｜ 进行中`。与 Rank-1 R24「战斗 HUD（含 Boss HP）出现、金色文字逐字可读」登记一致。**但数值在整段内不推进**（三帧全同），见 §6 未完成项 |
| 2 | **Boss 是否有可见像素形象** | **无（未达，不翻案）** | 三帧均只有中央玩家骑士，**无独立大型 Boss 敌人精灵**。底部 HUD 的 `Boss HP 100%` 是 UI 文本，不是像素形象。与 **Rank-1 在 R24 如实登记的「无可见形象」完全一致，本轮不替它翻案**。左侧固定深蓝色尖锐几何形状为 R23 已登记的既有场景/FX 元素，非 Boss 形象 |
| 3 | **深蓝夜景** | **不回退** | 三帧均为深蓝渐变夜空 + 星点 + 冷蓝雾带 + 远山剪影，暖金光柱/光池构成暖冷对比；段 B 关光效后夜景底色仍在。相对 R22「亮蓝白天纯色天空」为已升级并保持 |
| 4 | **三层视差远景** | **不回退** | 天空渐变层 / 远山剪影层 / 横向雾带层 + 前景透视石砖，分层成立（`hd2d_parallax.gd` 2D 程序化近似），三帧均在；无 3D 深度雾/DOF，见 §5 |
| 5 | **赐福 HUD** | **不回退** | 金线深蓝面板 + 中文标题，三帧随 flag 变化：「宁姆格福」→「巡礼教堂」(暗) →「希芙拉河井底」(暗，未点亮)，事件驱动增量刷新生效，尺寸正常、不遮挡角色 |
| 6 | **画质面板** | **不回退** | 右上「画质设置 · 低 / 中 / 高」金线深蓝面板 + 三按钮三帧均可见，三档尺寸一致、不放大、不遮挡角色（与 R22 段 B「HUD 放大遮挡」相比未回退） |
| 7 | **行为是否跨整段推进** | **是** | 见 §3 |
| 8 | **与《八方旅人》式 HD-2D 的差距** | **未达全绿** | 见 §5 |

---

## 3. 行为是否跨整段推进：**是**

三段各 150 帧（5 秒）：`0–149 medium/desktop 四项全开` →（frame 150 `set_quality("low")+apply()`）`150–299 low/mobile 四项全关` →（frame 300 `set_quality("high")+apply()`）`300–449 high/desktop 四项全开`。

- 日志 `v020_capture_run2.log` 实测：`SEG=3`、`POSE=30`（每 15 帧一次 `set_pose`，8 个冻结 pose 循环）、`HUD=5`（帧 40/190/250/340/420，`WorldState.set_flag → flag_changed → HUD` 事件驱动）、`时间线完成 frame=450`。日志中 `set_quality(` 字样共 4 处（脚本 2 次档位切换 + 画质面板 `[R21_QUALITY]` 联动回读），如实登记不硬凑成 2。
- 三帧目视差异：赐福标题、角色 pose、四项光效开关、石砖锐利度、画面亮度均不同；首/中/尾 md5 全不同 → **明确非单帧循环**。
- 段 A/C 另有 `hd2d_fx.gd` 既有 `_process` 逐帧重绘（光尘上飘 / 倒影波纹）。
- 如实边界：段 B（mobile 四项全关）3D 主体静止（R22 起相机写入会破坏 Movie Maker 的 SubViewport 3D 录制，故取消逐帧相机/角色位移），仅靠 30 次 `set_pose` + 5 次 HUD flag 推进，存在短静止区间；`[BossController]` 每帧随机抽招日志真实推进，但无战斗数值结算注入。

---

## 4. 门禁与回归（真跑，不回退）

| 段 / 脚本 | 命令（`--headless --path <root>`） | EXIT | 结论 |
|---|---|---|---|
| G1 | `--import` | 0 | 无 SCRIPT ERROR |
| G2 | `--check-only --script res://test/presentation.gd` | 0 | 无 SCRIPT ERROR |
| G3 | `--quit` | 0 | 无 SCRIPT ERROR（仅既有 `2 ObjectDB instances were leaked` WARNING，非致命、非 ERROR、不改退出码） |
| RUN mobile | `--script res://scripts/verify_fx_mobile.gd` | 0 | `==== [R19] SUMMARY pass=47 fail=0 total=47 ==== RESULT=PASS` |
| RUN profile | `--script res://scripts/verify_fx_profile.gd` | 0 | `==== [R17] SUMMARY pass=34 fail=0 total=34 ==== RESULT=PASS` |

- **9 份 `v020_*.log` 的 `SCRIPT ERROR|Parse Error|ERROR:` 合计 = 0**（逐份计数全 0；含 `v020_capture.log` / `_run1` / `_run2` / `_ffmpeg` / 3 份 gate / 2 份 verify）。**SCRIPT ERROR=0 通过**。
- **47 PASS / 34 PASS 不回退**。
- 说明：Grep 工具对含 ANSI 控制符的 Godot 日志在目录 glob 下未匹配，门禁统计改用任务明文的命令行 `grep` 完成，逐份计数如上；Grep 工具对精确单文件（`v020_capture_run2.log`）可正常返回 `SEG-C` / `时间线完成` 行，交叉一致。如实登记工具行为，不影响结论。
- 未写 `project.godot` / `courtyard.tscn` / `quality_settings.*` / `hud.gd` / `hd2d_fx.*` / `verify_fx_*.gd` / 任何 `.tres` / `.png` 美术资源。

---

## 5. 与《八方旅人》式 HD-2D 目标的差距：**未达全绿**（如实写未达）

| 目标项 | R24B 实际 | 判定 |
|---|---|---|
| 像素精灵 × 3D 场景对比 | 硬边像素骑士 + 透视石砖地面，对比成立 | **部分达到** |
| 高质量地面贴图 | 新石砖纹理细节丰富，但 `uv1_scale` 高倍平铺 → **重复感仍明显**；暖金砖大面积偏亮，**冷夜雾向地面渗透不足、白天感残留** | **未达全绿** |
| 平滑景深 / DOF / 大气远景 | 2D 程序化分层近似（渐变天空/山影/雾带），山影几何化、层次有限；**无 3D 深度雾 / DOF 虚化**，近景地面全程清晰 | **未达** |
| 体积光 / 光尘 / 湿地倒影 / bloom | 2D `draw_*` 近似（垂直光柱/圆点/脚下光池/同心圆），随档位开关；非 3D 体积散射 / SSR / HDR bloom（`gl_compatibility` 后端限制） | **近似，未达** |
| 金线深蓝 UI（赐福 / 画质 / 战斗 HUD） | 三帧清晰、三档尺寸一致、底部战斗 HUD 金色文字逐字可读 | **达到** |
| 角色动画 | 8 pose 各仅 1 帧（切 pose 换图），**无逐帧动作动画** | **未达** |
| Boss 可见像素形象 | **无**（仅 HUD 有 `Boss HP` 文字） | **未达** |
| 整体氛围 | 深蓝夜景 + 暖金主光成立，但地面亮度偏高、光池与暗部对比强度不足原作 HD-2D | **未达全绿** |

> 沿用 R20~R24 长期边界：本轮只做「录屏 + 目视回看」，**未精修美术、未接入 Boss 像素形象**，不冒充全绿。工程冻结，本轮不改任何 `godot/` 源件与美术资源。

---

## 6. 如实登记 / 未完成项

1. **HD-2D 全绿未达成**（§5），本轮不精修美术、不谎报达标。
2. **Boss 无可见像素形象**：与 Rank-1 R24「无可见形象」登记一致，**不翻案**；`courtyard.tscn` 内 encounter 以 instance 接入（node_count 29），Boss AI 日志真实推进，但画面中无独立 Boss 精灵。
3. **底部战斗 HUD 数值不推进**：三帧均为 `玩家 HP 100/100 ｜ Boss HP 100% ｜ 动作 idle 0/0 ｜ 闪避 0 ｜ 命中 0 ｜ 进行中`，无输入注入（R24 Rank-1 已登记）；本轮按公共契约不新建只读探针/巡检脚本，未做交互注入。
4. **WAV 未混入 MP4**：`v020_demo.wav`（5,760,044 B）单独保留，MP4 仅 h264/yuv420p 视频轨（音频流=0），与 R22/R23B 口径一致。
5. **run1 首次真跑偶发短录 285 帧 = 9.5 s**：日志 `v020_capture_run1.log` 留证，根因未逐一追查、不臆断；串行重跑 run2 得定稿 450 帧，两份日志均保留。
6. **画面左侧固定深蓝色尖锐几何形状**：首/中/尾三帧均出现、位置固定，为 R23 已登记的既有场景/FX 元素（非本轮改动引入），来源未逐一追查，如实登记不臆断。
7. **段 B（low/mobile 四项全关）3D 主体静止**，仅靠 pose 每 15 帧切换与 HUD 事件推进，存在短静止区间（沿用 R22）。
8. **既有非致命 WARNING**（`2 ObjectDB instances were leaked at exit`）在 G3 与 verify 日志中出现，非 `SCRIPT ERROR`、不改退出码，如实登记。
9. **未做人工鼠标点击 / 真机试玩逐帧动态验收**；Movie Maker 固定步长录屏不等价于实时性能评测。
10. **Grep 工具目录 glob 对含 ANSI 控制符日志未匹配**，门禁统计由命令行 `grep` 完成（§4），结论不受影响。
11. 零付费、零外部依赖（本机 ffmpeg 可用）、一次只跑一个 GPU/编码任务；只写 `capture/` 与 `teamwork/Rank-4/`（+ 回执到 `command_center/ai/4/outbox/`）；**未自行 git**。

---

> **证据**：`capture/v020_demo00000000.png`（首）/ `v020_demo00000225.png`（中）/ `v020_demo00000449.png`（尾），
> 450 张 PNG 序列、`capture/v020_demo.mp4`、`capture/v020_demo.wav`、
> `capture/v020_capture_run1.log`（偶发短录）/ `v020_capture_run2.log`（定稿）/ `v020_ffmpeg.log` /
> `v020_gate_g*.log` / `v020_verify_fx_*.log`。
> 完整交付清单与未完成项见 `teamwork/Rank-4/DONE-R24B.md`；本报告追加于 `capture/CAPTURE-REPORT.md`「R24 v0.2.0 实机录屏」段。
