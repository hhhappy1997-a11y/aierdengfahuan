# DONE-R31 · v0.9.0 · Rank-4 交付完成报告

- 派单 id：`cmd-20261111-133549-891-A4`
- ROUND：R31 / v0.9.0
- 工位：Rank-4 美术管线与工具链（AI=4）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）
- 工程：`F:/Game/aierdengfahuan/godot`
- 纪律：零 GPU job / 零付费 / 零外部依赖 / 不伪造产物 / 不谎报 / 不自行 git（总指挥收尾）

---

## 1. 交付清单（实际落盘）

| # | 文件 | 类型 | 实测 |
|---|---|---|---|
| 1 | `godot/assets/generated/r23/impact_fx.png` | 新写（程序化 PIL 逐像素） | 512×128 RGBA，5095 字节，4 帧横向 |
| 2 | `godot/assets/generated/r23/import.json` | 新写（I-5 配套） | 帧尺寸/锚点/帧数/动作名 + §9.3 两层口径 + 实测色数 |
| 3 | `godot/scripts/hd2d_fx.gd` | 精修（layer=10 四项光效） | 光尘密度 + 湿地倒影 + 金线深蓝冷暖分层 |
| 4 | `godot/scripts/render/hd2d_parallax.gd` | 精修（layer=5 视差远景） | 光尘密度 + 湿地反光衔接 + desktop/mobile 门控 |
| 5 | `capture/r31_demo00000000.png` … `r31_demo00000449.png` | 真跑中间帧 | 450 张（30 FPS × 15 s，0-based） |
| 6 | `capture/r31_demo.wav` | Movie Maker 伴生产物 | 5,760,044 字节（未混入 MP4） |
| 7 | `capture/v090_demo.mp4` | 最终录屏 | **1,769,025 字节**，450 帧 @30 FPS，libx264 / yuv420p |
| 8 | `teamwork/Rank-4/DONE-R31.md` | 本报告 | — |
| 9 | `teamwork/Rank-4/gen_impact_fx.py` | 可复现产出件 | 程序化 PIL 生成脚本（仅本地 Pillow 12.3.0） |
| 10 | `teamwork/Rank-4/apply_r31_gd_edits.py` | 可复现编辑件 | 精确唯一命中替换 + 16 项保留自检 |
| 11 | `teamwork/Rank-4/r31_gate.log` | 真跑日志原文 | 三段门禁 78 行 |
| 12 | `teamwork/Rank-4/r31_capture.log` | 真跑日志原文 | Movie Maker 录屏日志 |
| 13 | `teamwork/command_center/ai/4/outbox/cmd-20261111-133549-891-A4.json` | 回执 | 严格 4 字段 |

> **授权边界如实登记**：派单/用户查询把 `hd2d_fx.gd` 写作 `godot/scripts/render/hd2d_fx.gd`，工程实测该文件位于 `godot/scripts/hd2d_fx.gd`（`godot/scripts/render/` 下实为 `hd2d_parallax.gd` / `hd2d_placeholder*.gd`）。目录所有权明确把 `hd2d_fx.gd` 归 Rank-4，故按真实路径精修，未新建、未改名任何文件。

---

## 2. ① 16 色冲击特效素材（程序化 PIL，零 GPU job）

### 2.1 规格落地
- 128px 基准画布 × 4 帧「冲击环 / 暖金闪光」，横向 spritesheet 512×128。
- 逐像素 `putpixel`：硬边同心环（整数距离平方阈值）、中心暖白方块核心、十字 + 对角星芒、最外冷蓝细环；frame3 对角扇区断裂 + 暗金收束（起→扩→峰→收）。
- **RGBA 保 alpha**：前景 alpha=255 / 背景 alpha=0，实测 `alpha_bins=[0,255]`，无中间 alpha → 硬边、无渐变、无 dithering、无噪点（全程确定性几何，零随机）。
- 受控索引：色板全部取自项目级色库 `res://assets/generated/palette_256.json` 的 `colors[0..15]`，实际取用 8 色。

### 2.2 落盘后实测色数（硬数字）
```
逐帧 RGBA 色数(含透明): [8, 8, 8, 8]
最大单帧色数: 8          全部 <=16: True
alpha 档集合: [0, 255]    仅 0/255(硬边无渐变): True
受控色板(全表实际取用): #16233F #4A6089 #8A5A22 #C97A2E #E8C479 #F0A94C #FFD27A #FFF0C2
PNG: 512x128, 5095 字节
```

### 2.3 素材目视（先目视检查再接入）
4 帧硬边同心环由小到大扩张，暖金/金橙/深金 + 冷蓝细环 + 中心暖白十字星芒，透明背景；frame3 可见对角断裂缺口与暗金暖金收束；纯色块无渐变无噪点，暖金×冷夜蓝强对比成立。素材仅落盘、未接入场景（本轮授权未含场景接入）。

### 2.4 import.json（I-5 四项 + §9.3 两层口径）
- 帧尺寸 `frame_width/frame_height=128`，`columns=4 / rows=1 / frame_count=4`；锚点 `{"x":64,"y":64}`（特效中心，非脚贴地，全帧共用）；动作 `impact`(start 0 / end 3 / fps 12 / loop false)，`pose_names=["impact"]`。
- 导入期望：`lossless / mipmaps=false / texture_filter=Nearest / default_texture_filter=0 / fix_alpha_border`。
- 两层口径字段 `color_policy.two_layers`：`project_palette_min_colors=256` / `per_frame_max_colors=16`。

---

## 3. ② HD-2D 光效精修（不改场景 / 保 A38 / 保降级层）

### 3.1 改动（均为程序化 `_draw()`；所有新数值标 `[PLACEHOLDER]` 并附 rationale）

**`hd2d_fx.gd`（layer=10，desktop 四项全开）**
- 光尘密度：远景 48→64 / 近景 32→48；`tone=i%3` 做「金线深蓝」分层（远景冷白每 3 粒嵌 1 粒深蓝靛 `#4A6089`，近景暖金每 3 粒嵌 1 粒浅金 `#FFF0C2`）→ 暖金 × 冷夜雾强对比。
- 湿地倒影精修：新增冷夜雾水面基底（4 条离散冷蓝横带）、暖金/冷白交替高光横线、深层冷雾叠色（把暖金倒影压进冷蓝水面）；**既有** 垂直镜像 / 压缩 0.85 / 深度渐隐 / 逐行波纹 / 2×2 硬色块 / 五项 `reflection_*` 参数全部保留。
- 新增 `[PLACEHOLDER]`：`reflection_water_bands=4`、`reflection_cold_tint=0.30`、`MOTES_FAR_COUNT=64`、`MOTES_NEAR_COUNT=48`。rationale：暖金像素角色倒影须落在冷夜雾湿地上才成立；近景浮尘加密强化体积光空气感、远景加密拉开与像素精灵硬边的平滑景深；仅 desktop(`_all_on`) 绘制，mobile 四项全关 `_draw()` 直接 return（数组构建开销可忽略）→ 移动端零劣化。

**`hd2d_parallax.gd`（layer=5 视差远景）**
- 光尘密度：desktop 档远景 40→56 / 近景 20→32，新增粒做冷暖分层；**mobile 档按 `MOTE_BASE_FAR/NEAR`(40/20) 门控跳过新增粒、前 40/20 粒保持原色原 alpha 逐字等价 → 移动端档位零劣化**。
- 湿地倒影衔接：`_draw_ground_grade()` 在 3D 暖金砖地上补 3 条离散「冷夜雾 × 暖金」反光横带（仅 desktop 绘制、低 alpha 不遮挡 3D 地面 / HUD）。
- 新增 `[PLACEHOLDER]`：`MOTE_BASE_FAR=40 / MOTE_BASE_NEAR=20 / MOTE_FAR_COUNT=56 / MOTE_NEAR_COUNT=32` 及反光带系数。rationale：与 `hd2d_fx.gd` 像素角色湿地倒影呼应，强化「像素精灵 vs 平滑景深」对比。

### 3.2 保留项自检（16 项全绿，编辑脚本内置断言）
- `hd2d_fx.gd`：`@export_enum("desktop","mobile") var fx_profile`、`set_fx_profile()`、`_force_profile==PROFILE_MOBILE`、R20 环境变量强制档位、`"FXReflection"/"FXGodRays"/"FXMotes"/"FXBloom"` 四节点名分派、`_is_hud_avoid()`、`_apply_profile()` 全部保留。
- `hd2d_parallax.gd`：`GRADE_FORCE_DRAW_FALLBACK=false`、`set_wave_index()`、`_r29_current_tier()`、三波 `WAVE_SKY_TOP` 等 `WAVE_*` 常量、`_is_hud_avoid()`、`_r29_draw_grade()` 全部保留。

### 3.3 A38 / 场景约束
**未写 `courtyard.tscn`**（节点数 / uv / 节点名一字未动），未改节点名。门禁 GATE3 真跑日志原文：
```
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
```
→ **节点数 41 断言未破坏**；`uv_groundplate_2 / uv_terracelow_1 / uv_terracehigh_1` 属场景 uv，本轮零改动（未读取、未写入场景文件）。未改 `presentation.gd` / `hud.gd` / 数据表 / 其它 Rank 文件。

---

## 4. ③ 三段门禁 + 15 秒实机录屏（真跑输出原文结论）

### 4.1 三段门禁（`teamwork/Rank-4/r31_gate.log`）
```
GATE 1 --headless --import                         EXIT=0
GATE 2a --check-only --script res://scripts/hd2d_fx.gd            EXIT=0
GATE 2b --check-only --script res://scripts/render/hd2d_parallax.gd EXIT=0
GATE 2c --check-only --script res://test/presentation.gd            EXIT=0
GATE 3 --headless --quit                            EXIT=0
SCRIPT_ERROR_COUNT=0    PARSE_ERROR_COUNT=0
```
唯一非致命告警：`WARNING: 2 ObjectDB instances were leaked at exit`（引擎退出既有告警，非 SCRIPT ERROR，与本轮改动无关）。GATE3 另证 4 个 FX 节点默认 `desktop` 四项全开、R29 shader desktop/mobile 双档参数加载正常。

### 4.2 Movie Maker 15 秒真跑（`r31_capture.log`）
命令（`--write-movie` 绝对路径且带 `.png` 后缀）：
```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/r31_demo.png \
  --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd \
  res://scenes/courtyard.tscn
```
日志原文：
```
Done recording movie at path: F:/Game/aierdengfahuan/capture/r31_demo.png
450 frames at 30 FPS (movie length: 00:00:15:00), recorded in 00:00:42 (35% of real-time speed).
CPU render time: 0.42 seconds (average: 0.93 ms/frame)
GPU render time: 0.30 seconds (average: 0.67 ms/frame)
```
- **实测帧数 450 / 30 FPS / 时长 00:00:15:00（15 秒）**，`CAPTURE_EXIT=0`，`SCRIPT_ERROR_COUNT=0`。
- **未触发「短于 450 帧」分支** → 无需清理中间帧后串行重跑，无短录需如实留档、不冒充 15 秒。
- 真实输入注入由既有 `presentation.gd` 承担（J / Space / E / 1 / Tab 经 `Input.parse_input_event()`），本轮未改该脚本；中/尾帧可见赐福图鉴(Tab)与兑换面板展开、教学 3/3 完成、Boss HP 0% 胜利，证明输入路由生效。

### 4.3 ffmpeg 合成（`capture/v090_demo.mp4`）
```
C:/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe \
  -y -framerate 30 -start_number 0 -i capture/r31_demo%08d.png -frames:v 450 \
  -c:v libx264 -pix_fmt yuv420p -crf 18 -movflags +faststart capture/v090_demo.mp4
```
- `FFMPEG_EXIT=0`，x264 帧统计 `I:2 + P:117 + B:331 = 450` 帧。
- **MP4 字节数 = 1,769,025**（约 1.69 MiB）。
- 解码校验 `ffmpeg -v error -i v090_demo.mp4 -f null -` → `VERIFY_EXIT=0`。
- `r31_demo.wav`（5,760,044 字节）为 Movie Maker 伴生产物，**未混入 MP4**（避免音轨长度与 `-shortest` 截断 15 秒画面），如实登记。

---

## 5. ④ 目视回看首 / 中 / 尾三帧结论（ViewImage）

| 采样 | 文件 | 时点 |
|---|---|---|
| 首 | `r31_demo00000000.png` | 0 s（波1 / 赐福·关卡前） |
| 中 | `r31_demo00000225.png` | 7.5 s（波2 / 赐福·巡礼教堂 / 图鉴+兑换面板展开） |
| 尾 | `r31_demo00000449.png` | 15 s（波3 / 赐福·希芙拉河井底 / Boss HP 0% 胜利·已落盘） |

1. **地面重复感**：三帧均可见规则砖格阵列平铺，重复感客观存在。本轮在视差层补冷夜雾湿地反光带、光效层补湿地倒影水面带，一定程度柔化纯平铺，但砖纹重复仍可辨。地面材质/网格属 `courtyard.tscn` 3D 地形（Rank-1 所有、本轮未授权改），如实登记为既有观感，**不冒充已消除**。
2. **面板是否遮挡角色**：左上「赐福标题」金框、右上「画质设置」、底部战斗状态栏，以及中/尾帧展开的左侧「赐福图鉴」、右侧「赐福成长 1/2/3 兑换」面板，均布在画面边缘/两侧；**中央像素角色（含剑盾）全程可见、未被面板实心遮挡**。（观察项：左侧波次/教学提示文字带与角色左侧有轻微文字重叠/串行，属既有 HUD 文本布局 `hud.gd`=Rank-1，本轮未改、如实登记。）
3. **暖金收束**：首帧波1 暖金体积光柱收束于中心高光、未过曝；中帧波2 深紫浓雾下暖金转弱（三波空间节奏的可辨差异）；尾帧波3 暖紫雾散 + 地平线暖金高光 + 中心亮金核心，**暖金向中心收拢、收束感最强，全程无过曝糊画面**。
4. **像素精灵 vs 平滑景深**：像素点阵角色硬边（Nearest）全程清晰，背景深蓝→暖紫夜空 / 多层雾带 / 山影剪影为平滑渐变，对比清晰；分层光尘（暖金近景 + 冷白/深蓝远景）强化空气透视。
5. **HD-2D 全绿是否达成**：**达成（本轮目视结论）** —— 金线深蓝 UI、暖金光 × 冷夜雾强对比、像素精灵 vs 平滑景深、体积光/光尘/湿地倒影/bloom 四项光效、三波空间变化、450 帧完整 15 秒画面俱在。此为画面观感判断、非机器断言；「全绿」不覆盖 §6 的项目级色库口径差异。

---

## 6. 未完成项与阻塞

1. **项目级色库 ≥256 色未达标（既有口径差异，非本轮可改）**：契约 §9.3 / I-5 要求「项目级色库 ≥256 色」，但真源 `godot/assets/generated/palette_256.json` 实测 `colors` **仅 32 色**（`spec.max_colors=256`、`color_count=32`、`status=frozen_temporary_R2`）。本轮只在 `import.json` 引用该真源、**不扩写他人色库文件、不谎报**：两层口径中的「单帧 ≤16 色」严格达成，「项目级 ≥256 色」由既有色库现状决定 → 列入 §7 待裁决。
2. **impact_fx.png 未接入场景**：任务单①只要求素材 + `import.json` 落盘（I-5 交付给 Rank-1 导入），未授权改 `courtyard.tscn` / 场景节点，故素材仅落盘、未运行时接入；接入排期归 Rank-1 / 总指挥。
3. **地面砖格平铺重复感 / 教学 HUD 文字重叠**：均属既有场景与 HUD（Rank-1 所有），本轮未授权改，如实登记为观感观察项，未消除、不冒充。
4. **WAV 音轨未混入 MP4**：Movie Maker 伴生 `r31_demo.wav`，为避免 `-shortest` 截断画面未并入；若需带音轨版本请裁决。
5. **无阻塞**：本轮三段门禁、素材生成、精修、录屏、合成、目视全部真跑完成，无环境/依赖阻塞。

---

## 7. 待总指挥裁决项

1. **项目级色库口径（§9.3 / I-5）**：`palette_256.json` 实测 32 色 < 256 下限 —— 是扩写色库至 ≥256 色（谁执行 / 是否动他人文件），还是按现状冻结并修订契约文字？本轮按「不私改契约、不扩写他人文件、如实登记」处理。
2. **`hd2d_fx.gd` 路径口径**：派单写 `godot/scripts/render/hd2d_fx.gd`，工程实测在 `godot/scripts/hd2d_fx.gd`；本轮按真实路径精修。是否需要把文件归位到 `render/`（涉及改场景脚本引用，可能影响 A38）？
3. **地面重复感 / 教学 HUD 文字重叠**：是否立项（归 Rank-1 场景 / HUD）后续整改？
4. **WAV 是否并入 MP4**：带音轨版本是否需要。
5. **impact_fx.png 接入排期**：I-5 交付后由 Rank-1 导入的时点。
6. **`128bit` 歧义**：契约 §9.3 已显式保留待用户确认，本轮按「128px 基准画布」理解，不消歧、不编码进期望值。

---

## 8. 合规声明

- 零 GPU job、零付费、零外部素材生成服务：素材由本地 Pillow 12.3.0 逐像素生成；光效精修为 GDScript 程序化 `_draw()`；录屏/合成用本机 Godot + ffmpeg 绝对路径。
- 未新建只读探针/巡检脚本、未主动扫目录做进度巡检；`gen_impact_fx.py` / `apply_r31_gd_edits.py` 为产出/编辑件，非探针。
- 未改 `presentation.gd` / `hud.gd` / `courtyard.tscn`（节点数 41 / uv / 节点名）/ 数据表 / 其它 Rank 文件；未自行 git（总指挥收尾）；未删除 `.workbuddy` 目录。
- 所有新数值均标 `[PLACEHOLDER]` 并写清 rationale，待试玩校准。

---

## 9. 回执落盘观察（如实登记）

回执按任务单要求写入 `teamwork/command_center/ai/4/outbox/cmd-20261111-133549-891-A4.json`（严格 4 字段 `{"task_id","ai","status","result"}`）。实测调度中枢 hook 会即时消费 `outbox/` 回执并归档到 `teamwork/command_center/dispatcher/receipts/<同名>.json`：本轮前两次写入后 `outbox/` 被清空，而归档文件内容与本轮回执 `result` 逐字一致（`DISPATCHER_ARCHIVE_SAME_RESULT=True`）。最后一次写入已在同一次命令内确认 `outbox/` 文件存在（1226 字节、字段校验通过）且归档一致。此为调度中枢正常回执消费语义，**回执已被接收**，不冒充、不伪造。
