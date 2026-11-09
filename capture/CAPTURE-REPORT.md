# 画面可见性验收报告（首次非 headless 真跑）

> 2026-11-09 07:58 · Godot 4.7.2.stable · OpenGL 3.3 / NVIDIA RTX 4060 Ti
> 命令：`godot --path godot --write-movie capture/frame.png --fixed-fps 30 --quit-after 12 res://scenes/courtyard.tscn`
> 结果：`Movie Maker mode enabled, recording movie in 1280×720 @ 30 FPS`，**12 帧**，`MOVIE_EXIT=0`，
> GPU 平均 0.37 ms/帧、CPU 0.49 ms/帧、编码 23.98 ms/帧。

## 1. 已验证通过（骨架可渲染）
- 场景能真实渲染，**不是黑屏 / 全白 / 空场景**；12 帧全部产出 PNG。
- 可见元素：上方蓝色天空带、灰蓝渐变雾背景、两块灰色高低平台（TerraceLow / TerraceHigh / GroundPlate）、中央一个蓝红像素骑士（即 `player_spriteframes.tres` 的 `idle` 帧）。
- 主场景 `AnimatedSprite3D` 装配生效，角色 sprite 确实出现在画面里。

## 2. 与总纲 HD-2D 目标的差距（如实登记，未宣称达标）
- 地形是**无贴图的纯灰平面**，没有地面材质/细节。
- 画面整体偏**冷灰蓝**，缺少总纲要求的**暖金光与冷夜雾强对比**。
- 看不到体积光、光尘、湿地倒影、bloom；程序化 `hd2d_placeholder.gd` 占位层的视觉贡献不明显。
- **没有任何 UI**（金线深蓝界面、HUD 均未接入）。
- 角色在 1280×720 里偏小（约 80px 高），构图与镜头距离需调。
- 12 帧为静态画面（未驱动 `set_pose()` 切帧，属预期，非缺陷）。

## 3. 结论
工程从「headless 门禁通过」推进到「**真实画面可见**」，但美术表现仍是占位阶段。
这不是失败，而是把此前一直未验收的部分首次摆到明面：后续若继续推进，应优先补地形材质、暖金主光、体积光/光尘/倒影/bloom、UI 与镜头构图。

> 证据帧：`capture/frame00000000.png` ~ `frame00000011.png`（另有 `frame.wav` 为 Movie Maker 音频轨）。

---

## R20 移动档验收（Rank-4 · 2026-11-09 · 派单 `cmd-20261109-110237-810-A4`）

> 本节由 Rank-4 独占追加。补齐 R19 承认的缺口：R19 的 `r19_mobile*.png` 实为 **desktop 档（四项光效全开）** 画面，R20 首次真实抓到 **mobile 档（四项全关）** 画面。
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，Movie Maker `--fixed-fps 30 --quit-after 4`，全部 PNG **1280×720**。

### 1. 真实 mobile 档如何生效（非 desktop 帧改名）

`courtyard.tscn` 的 `HD2DFX` 根挂 Rank-1 独占 `fx_profile_controller.gd`，其 `_ready()` 判档固定为 **desktop** 并把 4 个 FX 子节点切回 desktop（R19 根因）。本轮在 Rank-4 可写的 `hd2d_fx.gd` 内加「运行期强制档位覆盖」：抓帧时设环境变量 `AIERDENG_FX_PROFILE=mobile`，4 个 FX 节点 `_ready()` 用 `call_deferred` 排在 controller 之后落到 mobile，并锁定档位忽略后续 `set_fx_profile("desktop")`。默认不设该变量 → desktop 四项全开零回退、47 PASS 回归不受影响。

抓帧 stdout（`r20_capture_mobile.log`）实证链路：controller 判档 `desktop` → `[R20] 忽略外部 set_fx_profile(desktop)` ×4（并发的 `QualitySettings` 两次重判 desktop 亦被逐一拦截）→ `[R20] deferred 落地 set_fx_profile(mobile) | visible=false _all_on=false 四门=[false false false false]` ×4。

### 2. 本轮抓帧产物（均真实 Movie Maker 输出，非复制 / 改名）

| 序列 | 文件 | 尺寸 | 档位 | 说明 |
|---|---|---|---|---|
| desktop 对照 | `r20_desktop00000000.png` ~ `00000003.png` | 1280×720 | desktop 四项全开 | 无环境变量，证明光效未回退 |
| **mobile 主证据** | `r20_mobile00000000.png` ~ `00000003.png` | 1280×720 | **mobile 四项全关** | `AIERDENG_FX_PROFILE=mobile` |
| **mobile 低分辨率** | `r20_mobile_lowres00000000.png` ~ `00000003.png` | 1280×720 | **mobile 四项全关 + 低分辨率渲染** | 追加 `--resolution 640x360`（内部 SubViewport 降采样后整数放大，砖块像素网格明显变粗） |

> 所有 PNG 的**录制尺寸均为 1280×720**（由 `project.godot` 的 `window_*_override` 决定，`--resolution` 不改变 Movie Maker 录制尺寸）；「低分辨率」体现在内部渲染缓冲与像素网格（sharpness 6.921 vs 常规 mobile 11.108；`r20_mobile vs r20_mobile_lowres` 差异像素 26.8%），如实登记、不冒充输出尺寸。

### 3. desktop / mobile 实际画面差距（PIL 真算 + ViewImage 真看）

同态对比（`r20_desktop` vs `r20_mobile`，同一工程状态、同一时刻；完整数据见 `capture/r20_pixel_diff.txt`）：

- 全图 MAD=(0.617, 0.435, 0.668)，差异像素比例(|L|>16)=**0.010299**；差异 bbox=(24, 0, 637, 361)，8×6 网格显示差异集中在天空中部与角色脚下——正是四项光效所在区域。
- **天空亮点计数**（暖金/冷白光尘 + bloom 近似）：`r20_desktop=180` → `r20_mobile=0`、`r20_mobile_lowres=0`。
- **HUD 面板区 (0,0,400,150) 差异仅 56 像素 / 0.000933** → 移动档 HUD 未被光尘遮挡；旧契约矩形 (0,0,730,220) 差异 0.031 来自构图缩放，非点状遮挡。
- **帧间一致性**：`r20_desktop` 4 帧 sha256 各异（光尘逐帧动画在跑）；**`r20_mobile` / `r20_mobile_lowres` 4 帧 sha256 完全相同**（FX 层零绘制 → 静态）。这是「真实四项全关」的强证据，也反证不是 desktop 帧改名冒充。

ViewImage 真看结论：

- **desktop 档**：天空散布零星暖金/冷白光尘点、地平线附近有明显暖金 bloom 亮斑与向上锥形体积光、角色脚下有倒影亮线 → 四项全开。
- **mobile 档**：上述四项全部消失；蓝天、暖金横砖地面（砖缝锐利）、左上深蓝 HUD 面板与「赐福 · 宁姆格福」文字、中央像素骑士剪影**全部清晰可读**；**无黑屏、无纯色空白、无大面积泛白、无糊屏、HUD 无点状遮挡**。
- **mobile 低分辨率档**：砖块像素网格明显变粗，主体元素仍完整可读，无黑屏 / 纯色 / 严重模糊 / 错位裁剪。
- 可读性量化：全部 `non_black=1.0`（不纯黑）；sharpness desktop 10.983 / mobile 11.108 / lowres 6.921（均不糊，关光效后反而更锐利）。

### 4. 与 R19 桌面档的可比性（诚实边界）

`r19_mobile*.png` 与 `r20_desktop*.png` 全图 MAD≈(30.7, 31.4, 28.5)、diff_ratio=**0.2906**，**但这不是本轮 desktop 光效回退**：本轮真跑期间 Rank-1 / Rank-3 并发落盘了 R20 画质管线（`fx_profile_controller.gd` 扩展 `re_evaluate`，新增 `QualitySettings` 运行期 `set_quality(low/high)` 改 `SubViewport.size` / `stretch_shrink`，`project.godot` 新增 `SaveDeltaWriter` autoload），导致 R19 与 R20 的构图 / 缩放基准不同。故上文以 **R20 同态 desktop/mobile 对比**作为有效验收证据；`r20_desktop` 全天空亮点 180 > R19 的 16，反而说明 desktop 四项光效在新构图下更明显、未回退。

### 5. 结论：**未达 HD-2D 全绿**

本轮达成的是「**真实抓到 mobile 档四项全关画面且主体可读**」，**不是** HD-2D 视觉全绿：

- 四项光效是 2D 程序化 `draw_*` 几何 / 加色近似，**非**真正 HDR bloom / 3D 体积光 / 屏幕空间反射（`gl_compatibility` 后端不支持）；
- 角色脚下倒影仍只有细亮线与少量深色块，非成片清晰镜像；体积光 / bloom 为低对比叠加，可见度弱；
- 地面为程序化横砖，构图与镜头仍是占位阶段；ComfyUI 正式 spritesheet 未接入；
- 未做运行期帧时间实测 / 人工试玩 / 逐帧动态验收。

未完成项、阻塞与合规边界详见 `teamwork/Rank-4/DONE-R20.md`。
