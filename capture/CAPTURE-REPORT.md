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

---

## R21 低分辨率与帧时间（Rank-4 · 2026-11-09 · 派单 `cmd-20261109-115818-662-A4`）

> 本节由 Rank-4 独占追加。延续 R20 如实登记的边界（`--resolution 640x360` 未改变 Movie Maker 录制尺寸），本轮**不改 `project.godot`**（避免与其它三路并发冲突），用零依赖方式真跑多种 CLI 参数组合查清边界、实测 mobile/desktop 帧时间并留证。
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`），抓帧一律 `--fixed-fps 30 --quit-after 4`，场景 `res://scenes/courtyard.tscn`。

### 1. 边界结论（先说结果）：本轮未达成「引擎级低分辨率输出」

**7 组 CLI 参数组合全部真跑 EXIT=0，Movie Maker stdout 一律 `recording movie in 1280×720 @ 30 FPS`，PNG IHDR 实测一律 1280×720，无一输出 640×360。**

| 组合 | 额外 CLI 参数 | stdout 录制尺寸 | PNG 实测(IHDR) | 首帧字节 |
|---|---|---|---|---|
| C1 `r21_lowres_c1_base` | 无（基线） | 1280×720 | 1280×720 | 125346 |
| C2 `r21_lowres_c2_res640x360` | `--resolution 640x360` | 1280×720 | 1280×720 | 406020 |
| C3 `r21_lowres_c3_res1920x1080` | `--resolution 1920x1080` | 1280×720 | 1280×720 | 287862 |
| C4 `r21_lowres_c4_res640_full` | `--resolution 640x360 --fullscreen` | 1280×720 | 1280×720 | 126815 |
| C5 `r21_lowres_c5_res480x270` | `--resolution 480x270` | 1280×720 | 1280×720 | 491198 |
| C6 `r21_lowres_c6_res640_max` | `--resolution 640x360 --windowed --maximized` | 1280×720 | 1280×720 | 407063 |
| FT `r21_lowres_ft_mobile` | 无 + `AIERDENG_FX_PROFILE=mobile` | 1280×720 | 1280×720 | 112772（4 帧全同）|

**根因（引擎 `--help` 全文 `capture/r21_godot_help.txt` 129 行留证）**：Godot 4.7.2 CLI 与尺寸/缩放相关的参数**只有** `--resolution <W>x<H>`、`--position`、`--fullscreen/-f`、`--windowed/-w`、`--maximized/-m`、`--screen`、`--disable-vsync`；**没有任何缩放(scaling)CLI 参数、没有任何命令行覆盖 project settings 的途径**。Movie Maker 输出尺寸由 `project.godot` 的 `window/size/viewport_width=1280` / `viewport_height=720` / `window_width_override=1280` / `window_height_override=720` 决定（R20 已登记）。本轮硬约束禁止写 `project.godot`，也禁止在 `godot/` 下新建 `override.cfg` / 临时工程，故**在授权范围内无法让引擎直接输出 640×360 PNG** —— 这是边界，不是失败，如实写明。

### 2. `--resolution` 确实改变了内部渲染画面，但不改变输出文件尺寸

C2 的 PNG 字节 406020 远大于 C1 基线 125346；PIL 真算（同尺寸 1280×720）：

- `c1_base vs c2_res640x360`：MAD(R,G,B)=(10.455, 8.888, 5.505)，差异像素比例(|L|>16)=**0.228038**，边缘能量 37.037 → 22.346。
- ViewImage 真看：C1 蓝天 / 左上深蓝 HUD「赐福 · 宁姆格福」/ 右上「画质设置 · 低/中/高」/ 暖金横砖地面（砖缝细密）/ 中央像素骑士 / 地平线暖金 bloom 与体积光亮点、角色脚下倒影亮线，像素细腻；**C2 构图元素完全相同，但砖块像素网格明显变粗、砖缝更块状、HUD 文字与角色轮廓更糊**。

即 `--resolution 640x360` 触发了内部 SubViewport 低分辨率渲染 + 整数放大（与 R20 的 `r20_mobile_lowres` 同类），画面密度确实下降，但 Movie Maker 仍把结果写进 **1280×720** 的 PNG。**「内部低分辨率渲染」≠「输出 640×360 文件」**，本轮不冒充。

### 3. 帧时间真跑（`capture/r21_frame_time.md`，非估算）

引擎 `--print-fps` 直接打印 `Project FPS: N (X mspf)`，X 即运行期每帧毫秒数；Python 基于该 stdout 统计：

| 组 | 档位 | V-Sync | 采样行数 | FPS 均值 | **mspf 均值** |
|---|---|---|---|---|---|
| `fps_desktop_vsync` | desktop 四项全开 | 开 | 5 | 59.8 | **16.72 ms** |
| `fps_mobile_vsync` | mobile 四项全关 | 开 | 4 | 60.0 | **16.66 ms** |
| `fps_desktop_novsync` | desktop 四项全开 | 关 | 28 | 198.8 | **5.03 ms** |
| `fps_mobile_novsync` | mobile 四项全关 | 关 | 19 | 291.7 | **3.43 ms** |

- V-Sync 开：stdout 明示 `FPS will likely be capped to the monitor refresh rate`，两组均被 60 Hz 锁死，帧时间几乎无差异 —— 如实登记为 V-Sync 限制，不冒充性能优化。
- 关 V-Sync 全速：desktop 5.03 ms/帧 vs mobile 3.43 ms/帧，**mobile 帧时间少 31.8%、吞吐 1.47×**，是「四项光效全关 → FX 层零绘制」的真实渲染开销下降。
- 补充口径 Movie Maker 4 帧录制：CPU render 0.02 / GPU 0.00 ms/帧（四舍五入、样本太短不可判定档位）；Encoding `c1_base` 126.17 vs `ft_mobile` 28.64 ms/帧（组间 28.64~143.47 波动大、受磁盘/画面复杂度影响，不作稳定结论）。

### 4. PIL 后处理 640×360 对照图（明确标注，禁止冒充）

引擎直接输出 640×360 未达成，故仅用 PIL 对**引擎真跑的原始帧** `r21_lowres_c1_base00000000.png`（1280×720）做 2× LANCZOS 降采样：

- `capture/r21_lowres_post_2x_downsample.png` — **640×360**，图上顶部红字醒目标注「**后处理对照 · 非引擎低分辨率渲染**」/ `POST-PROCESS 2x DOWNSAMPLE · NOT ENGINE LOW-RES RENDER`，底部标注源文件与生成方式。
- `capture/r21_lowres_post_vs_engine.png` — 并排对比（左=引擎真实输出缩略 / 右=后处理降采样），标题红字再次声明右图非引擎渲染。

> **这两张是「后处理对照，非引擎低分辨率渲染」，只是画质参照，绝不代表引擎已输出 640×360、也不冒充 Movie Maker 产物。** 全 `capture/` 下唯一的 640×360 文件就是带标注的 `r21_lowres_post_2x_downsample.png`；所有 `r21_lowres_c*/ft_mobile*` 帧仍为 1280×720。

### 5. 画面差距与回归（如实登记）

- `c1_base(desktop 四项全开) vs ft_mobile(mobile 四项全关)`：MAD=(2.299, 2.133, 1.583)，diff_ratio=**0.042374**，差异集中在天空光尘/bloom 与角色脚下倒影区域（同态同尺寸，PIL 真算）。
- **47 PASS / 34 PASS 不回退**：`verify_fx_mobile.gd` 真跑 `pass=47 fail=0`、`verify_fx_profile.gd` 真跑 `pass=34 fail=0`（stdout 标签沿用既有 `[R19]` / `[R17]`，未伪装成 R21）。三段门禁 `--headless --import` → `--check-only --script` → `--headless --quit` 及两个 RUN 共 6 项 **EXIT=0**；17 份 `r21_*.log` 的 `SCRIPT ERROR|Parse Error|ERROR` **SUM=0**。
- 本轮**零改动工程源件**：未写 `project.godot` / `courtyard.tscn` / `quality_settings.*` / `hud.gd` / `verify_frame_data.gd` / `hd2d_fx.*` / `verify_fx_*.gd` / 任何 `.tres` / `.import`。

### 6. 未完成项 / 边界（不冒充全绿）

1. **引擎级 640×360 PNG 输出未达成**：唯一途径需改 `project.godot` 的 viewport/window 尺寸（Rank-3 独占，本轮硬约束禁写），或在 `godot/` 下新建 `override.cfg` / 临时工程（超本轮目录所有权）。按派单要求「重导双产物另以 R21B 补单在工程冻结后执行」，本轮只查清并留证。
2. 并发实例：本轮真跑期间另有 Rank-4 并发实例用 `r21_lowres_base / res640 / res320 / res1920 / res640win / res640headless` 命名产出抓帧（32 个文件，均无对应 log、均 1280×720），与本实例命名 `c1~c6 / ft_mobile` 互不冲突；本实例**未覆盖、未删除、未冒充**并发产物，如实登记。
3. 帧时间为主场景 `courtyard.tscn` 非 headless 窗口真跑；未做逐 `_draw()` 拆分 / GPU 时间戳 / 人工试玩逐帧动态验收；Movie Maker 组受固定步长与 4 帧样本限制，差异不作稳定性能结论。
4. 沿用 R20 长期边界：HD-2D 全绿未达成，四项光效仍是 2D 程序化 `draw_*` 近似（`gl_compatibility` 后端不支持 HDR bloom / 3D 体积光 / SSR），ComfyUI 正式 spritesheet 未接入；本轮不精修光效。
5. 本轮真跑失败项：**无**（7 组抓帧 + 4 组帧时间 + 6 项门禁全部 EXIT=0）。

未完成项、阻塞与合规边界详见 `teamwork/Rank-4/DONE-R21.md`。

---

## R22 实机录屏（Rank-4 · 2026-11-09 · 派单 `cmd-20261109-124640-188-A4`）

> 本节由 Rank-4 独占追加。用户至今未亲眼看过运行时，本轮为 **godogen 核心交付：首次产出 15 秒连续实机录屏并 ViewImage 真看首/中/尾帧**。完整目视回看见 `capture/R22-RUNTIME-REVIEW.md`，交付清单见 `teamwork/Rank-4/DONE-R22.md`。**HD-2D 全绿未达成，如实写「未达」。**

### 1. 录屏命令与实际帧数（等价确定性方式，含如实登记的改动点）

```
D:/Godot/Godot_v4.7.2-stable_win64.exe \
  --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/r22_demo.png \
  --fixed-fps 30 --quit-after 450 \
  --script res://test/presentation.gd \
  res://scenes/courtyard.tscn
```

- 任务单原命令（无末尾位置参数、由脚本 `instantiate()+add_child()` 加载 `courtyard.tscn`）**已真跑**：`EXIT=0`、同样 450 帧，但 **Movie Maker 只录到 2D CanvasLayer（HUD/FX），SubViewport 的 3D 世界（砖地 / 像素骑士）不进入录制，画面主体缺失** —— 这是 `--script` 与录制在画面语义上的冲突。按任务单授权改用等价确定性方式（仍 450 帧 / 真实完整画面 / 跨段行为推进 / 确定性），改动点如实登记：
  1. **命令末尾补位置参数 `res://scenes/courtyard.tscn`**，由引擎正常加载场景（单实例、3D 渲染完整）；`presentation.gd` 的 `_initialize()` 改为 `root.get_node_or_null("Courtyard")` 复用引擎实例，不再自行 `instantiate()+add_child()`（杜绝双实例）。
  2. 任务要求「`_initialize()` 里预置相机」。实测 `--script` 模式下脚本对 `Camera3D` 写任何属性（`position`/`rotation_degrees`/`fov`/`current`，含 `call_deferred` 后写、含逐帧改 transform）都会破坏 SubViewport 的 3D 相机注册 → 3D 主体消失。故**相机预置由 `courtyard.tscn` 静态节点承担**，脚本在 `_initialize()` 里只读确认、不写入；逐帧相机缓动取消，跨帧推进由档位 / pose / HUD / `hd2d_fx` 既有逐帧重绘承担。
- 对照真跑证据（`capture/` 内 PNG + log 均保留，ViewImage 真看）：

| 对照 | 方式 | 3D 砖地/角色 |
|---|---|---|
| `r22_baseline` | `--write-movie … res://scenes/courtyard.tscn`（无 `--script`） | **完整可见** |
| `r22_nocam` | `--script` + 位置参数、复用单实例、**完全不写相机** | **完整可见** |
| `r22_combo` | `--script` + 位置参数 + 脚本自行 `add_child()`（双实例） | 缺失 |
| `r22_reuse` / `r22_cam2` / `r22_cam3` / `r22_defer` | 复用单实例但写相机属性（含 deferred / 逐帧） | 缺失 |

### 2. 产物（真实产出，非伪造）

| 产物 | 实测 |
|---|---|
| PNG 序列 | **450 张**，`r22_demo00000000.png` ~ `00000449.png`，编号连续 `0..449`（Python 校验 `continuous_0_449=True`），IHDR 均 **1280×720** |
| 时长 / 帧率 | `450 frames at 30 FPS (movie length: 00:00:15:00)`，`CAPTURE EXIT=0` |
| WAV | `r22_demo.wav`，**5,760,044 字节**（Movie Maker 自动音频轨，单独保留） |
| MP4 | `r22_demo.mp4`，**760,956 字节**；ffmpeg 本机可用（`-c:v libx264 -pix_fmt yuv420p -movflags +faststart`，`EXIT=0`）；ffprobe：`h264`/`yuv420p`/`1280×720`/`nb_frames=450`/`30/1`/`duration=15.000000`。**MP4 仅含视频，未混入 WAV、未谎报音视频合并** |

### 3. ViewImage 首 / 中 / 尾三帧所见（真看）

- **首帧 0（段 A medium/desktop）**：3D 暖金横砖地面铺满下半屏（透视砖缝、左侧立体台阶），中央蓝色盔甲像素骑士 idle 站立、脚下湿地倒影亮线；左上深蓝金边 HUD「赐福 · 宁姆格福」暗灰字，右上「画质设置 · 低/中/高」金框按钮；地平线暖金 bloom 光点、体积光扇形、冷白/暖金光尘点；亮蓝纯色天空。
- **中帧 225（段 B low/mobile）**：砖缝/色块**明显变粗**（low 档 `stretch_shrink=3` 放大），HUD 面板**明显放大**且文字变「赐福 · 巡礼教堂」暗灰；**四项光效（体积光/光尘/bloom/倒影）全部消失**；角色处于 `set_pose(death)` 姿态且被放大 HUD 遮挡，站立骑士不可见。
- **尾帧 449（段 C high/desktop）**：砖缝比中段**更细更清晰**（high 档 `shrink=1`），HUD 面板缩小、文字「赐福 · 希芙拉河井底」暗灰；骑士 `set_pose(attack_heavy)` 举武器姿态可见、倒影恢复；四项光效**全部恢复**。

### 4. 行为是否跨整段推进：**是**

三段各 150 帧（5 秒）：`0–149 medium/desktop 四项全开` → `150–299 low/mobile 四项全关`（帧 150 `set_quality("low")+apply()`）→ `300–449 high/desktop 四项全开`（帧 300 `set_quality("high")+apply()`）。全段 **30 次 `set_pose` 切帧**、**5 次 HUD flag 变化**（帧 40/190/250/340/420，`WorldState.set_flag → flag_changed → HUD` 事件驱动增量刷新）、**2 次画质档位切换**（连带 `fx_profile desktop→mobile→desktop`）。日志 `SEG=3 / POSE=30 / HUD=5 / set_quality=2`、时间线跑到 `frame=450`，首/中/尾 md5 全不同 → **非单帧循环**。desktop 段另有 `hd2d_fx.gd` 既有 `_process` 逐帧重绘（光尘上飘 / 倒影波纹）。如实说明：段 B 光效全关期间 3D 主体静止（相机写入会破坏 3D 录制，故取消逐帧相机/角色位移），仅靠 pose 每 15 帧切换与 HUD 事件推进，存在短静止区间。

### 5. 与 HD-2D 目标的差距：**未达全绿**

| 目标项 | 实际 | 判定 |
|---|---|---|
| 像素精灵 vs 3D 场景 | Nearest 硬边像素骑士 vs 透视砖地，对比成立 | 部分达到 |
| 平滑景深 / DOF / 大气远景 | **无**：3D 地面远近全程清晰、天空纯色亮蓝无远景层次 | **未达** |
| 体积光 / 光尘 / 湿地倒影 / bloom | 均为 2D 程序化 `draw_*` 近似（扇形 / 圆点 / 垂直镜像色块 / 同心圆），随档位开关；非 3D 体积散射 / SSR / HDR bloom | **近似，未达** |
| 金线深蓝 UI | 深蓝底 + 金色 1px 边框 + 金色中文标题/按钮，三帧清晰 | **达到** |
| 整体氛围 | 亮蓝白天 + 高亮暖金砖地，偏亮偏平；非《八方旅人》式深蓝夜景 / 黄昏氛围光 | **未达** |

沿用 R20/R21 长期边界：四项光效仍是 2D 程序化近似（`gl_compatibility` 后端不支持 HDR bloom / 3D 体积光 / SSR）；ComfyUI 正式 spritesheet 未接入（`player_spriteframes.tres` 8 pose 各仅 1 帧，只有切 pose 换图、无逐帧动作）；像素精灵与 3D 地面光照/阴影未统一。本轮只做录屏与目视回看、未精修美术，**不冒充全绿**。

### 6. 回归与合规

- `verify_fx_mobile.gd` 真跑 `pass=47 fail=0 RESULT=PASS`、`verify_fx_profile.gd` 真跑 `pass=34 fail=0 RESULT=PASS`（**47 / 34 不回退**）。
- 三段门禁（`--headless --import` → `--check-only --script` → `--headless --quit`）与 2 个 verify 的 `check-only` 全部 `EXIT=0`；**16 个 `r22_*.log` 的 `SCRIPT ERROR|Parse Error` SUM=0**（含 `r22_capture.log`）。
- 本轮四路均**未写** `project.godot`；本 Rank **未写** `courtyard.tscn` / `quality_settings.*` / `hud.gd` / `hd2d_fx.*` / `verify_frame_data.gd`。零付费、未引入任何付费素材生成服务、一次只跑一个 GPU/编码任务、无 git 提交。
- 新增文件：`godot/test/presentation.gd`（`extends SceneTree`，全静态类型标注）、`capture/R22-RUNTIME-REVIEW.md`、本段落、`teamwork/Rank-4/DONE-R22.md`、`command_center/ai/4/outbox/` 回执。

### 7. 未完成项 / 边界

1. **HD-2D 全绿未达成**（§5），本轮不精修美术。
2. 段 B 3D 主体静止、death 姿态 + 放大 HUD 遮挡使角色不可见；相机/角色逐帧位移动画因破坏 3D 录制而取消。
3. MP4 仅视频轨；`r22_demo.wav` 单独保留，未混入、未谎报合并。
4. 诊断对照产物（`r22_baseline*` / `r22_combo*` / `r22_reuse*` / `r22_nocam*` / `r22_cam2*` / `r22_cam3*` / `r22_defer*` 的 PNG 与 log）保留在 `capture/` 作为改动点证据；首版 `r22_demo`（缺 3D 主体）已被定稿版覆盖，未单独留档，如实登记。
5. 未做人工试玩逐帧动态验收 / GPU 时间戳 / 逐 `_draw()` 拆分；Movie Maker 固定步长录屏不等价于实时性能评测。

未完成项、阻塞与合规边界详见 `teamwork/Rank-4/DONE-R22.md`。

---

## R23 新素材接入验收（R23B · Rank-1 独占追加 · 2026-11-09 · `cmd-20261109-141302-870-A1`）

> 本节由 **Rank-1 独占追加**。四路 R23 已完成、工程与素材冻结；本轮把 `godot/assets/generated/r23/`
> 的新素材真正接进可见画面，并交付 15 秒录屏 + 目视回看 + 双产物重导。
> **结论：新素材确实进入画面（与 R23 旧帧有可辨差异）；HD-2D 全绿仍未达，如实写未达。**

### 1. 接入改动（静态，真改真核对）

| 文件 | 改动 | 目的 |
|---|---|---|
| `godot/assets/generated/chars/player_spriteframes.tres` | `ext_resource path` → `res://assets/generated/r23/player_spritesheet.png` | 玩家 8 pose 新图 |
| `godot/assets/generated/boss/boss_spriteframes.tres` | `ext_resource path` → `res://assets/generated/r23/boss_spritesheet.png` | Boss 3 pose 新图 |
| `godot/assets/generated/terrain/ground_material.tres` | `ext_resource path` → `res://assets/generated/r23/ground_tile.png` | 派单点名的地面材质 |
| `ground_tile_mat_plate.tres` / `ground_tile_mat_low.tres` / `ground_tile_mat_high.tres` | `ext_resource path` → `res://assets/generated/r23/ground_tile.png` | **派单「必要时同步 courtyard.tscn 实例引用」裁量**：`courtyard.tscn` 实际引用的是这 3 个材质而非 `ground_material.tres`，只改后者画面不会变 |

- **保留旧 PNG 不覆盖**：`chars/player_spritesheet.png` 59,147 B、`boss/boss_spritesheet.png` 31,250 B、
  `terrain/ground_tile.png` 1,495 B 均原样保留；新 PNG 217,416 / 86,163 / 38,339 B。
- **pose 名 / 帧序 / `region.x` 不变**：`player_spriteframes.tres` 8 个 `Rect2(*,0,128,128)`
  （idle=0 … death=896）、`boss_spriteframes.tres` 3 个（0/128/256）、loop 与 `uv1_scale` 全部未改。
  帧序硬证据：`player_spritesheet.png` / `boss_spritesheet.png` 逐 128 切片与对应单帧 PNG **像素级 IDENTICAL**（8/8、3/3）。
- **`courtyard.tscn` 本身未改**（引用的是 `.tres` 文件、路径不变）；节点数经
  `CACHE_MODE_IGNORE` 真跑回读 `SceneState_node_count=27`（`r23b_verify_quality_interaction.log`），
  与 R23 登记一致，**不冒充 25**。
- **56 条校验**：按 `ASSET-SPEC-R23.md` A~E 组逐条真跑（PNG PIL 实测 / manifest / `.png.import` / tres /
  verify 脚本 / 文件系统）→ **56 PASS / 0 FAIL**；F 组 2 条 `128bit` 歧义**挂起、不计 PASS/FAIL**。
  契约字面载体（`player|boss/import.json` 与未锁定命名字段）与实际交付（单一 `manifest.json`）的差异
  **逐条如实登记、不冒充字面全 PASS**，见 `teamwork/Rank-1/DONE-R23B.md §2`。

### 2. 15 秒录屏产物（真跑）

| 项 | 值 |
|---|---|
| 命令 | `--path <root> --write-movie capture/r23_final.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（复用 R22 已验证形态） |
| EXIT | **0** |
| 帧 | **450 张** `r23_final00000000.png` ~ `r23_final00000449.png`，全部 1280×720 |
| 时长 | **450 帧 @30 FPS = 15.000000 s**（ffprobe `nb_frames=450 / duration=15.000000`） |
| 时间线 | SEG-A(0–149 medium/desktop) / SEG-B(150–299 low/mobile) / SEG-C(300–449 high/desktop)，`时间线完成 frame=450` |
| MP4 | `capture/r23_final.mp4`，**1,288,103 B**，`libx264 / yuv420p / +faststart`，`FFMPEG_EXIT=0` |
| WAV | `capture/r23_final.wav` **5,760,044 B** 真实产出；**未混入 MP4**（ffprobe 音频流=0，MP4 仅视频轨），与 R22 `r22_demo.mp4` 口径一致，**如实登记、不谎报合并** |

### 3. ViewImage 目视回看（首 / 中 / 尾三帧 + R23 旧帧对照）

| 帧 | 目视结论 |
|---|---|
| 首 `r23_final00000000.png` | 密集不规则暖金/青灰石砖地面（非纯色平面）、红发+钴蓝板甲+金饰像素骑士、深蓝夜空+山影+雾带、暖金光柱/光尘/光池、金线深蓝 HUD 不遮挡 |
| 中 `r23_final00000225.png` | 石砖纹理依旧清晰；角色换 pose（红白头饰+钴蓝甲+金护肩）完整可见；四项光效全关（无光柱/光尘/倒影）；HUD 标题随 flag 变「赐福 · 巡礼教堂」，三档面板尺寸一致 |
| 尾 `r23_final00000449.png` | 石砖最锐利；角色为红发+格纹头巾+胸前发光青蓝宝石 pose，无破图/重复小人；光柱/光尘/光池回归；标题「赐福 · 希芙拉河井底」暗色未点亮 |

**接入前后对照**（`capture/r23_night_00000005.png` 为 R23 接入前旧帧）：
- 地面：旧 = 规则长条砖网格、黄绿/棕褐平涂、重复感强；新 = 不规则密集石砖、暖金/青灰/橙点、磨损颗粒细节。
- 角色：旧 = 蓝白头盔+红围巾小骑士、色块简单；新 = 红发/格纹头巾+钴蓝板甲+金饰+青蓝宝石、层次与硬描边明显。
→ **「新素材是否真的进入画面」= 是**，由静态指向改动 + 450 帧真实渲染 + ViewImage 目视三者支撑，非 clean build 推断、非改名冒充。

**Boss 如实登记**：`courtyard.tscn` 27 节点中**无 Boss 实例**，`boss_spriteframes.tres` 虽已指向 r23/、
`boss_01_margit.tscn` 引用它，但本 15 秒 courtyard 画面**不含 Boss**，不冒充可见；`decor_layer.png` 未接入（派单未要求）。

### 4. 门禁与回归（真跑，不回退）

- 三段门禁 `--headless --import` / `--check-only --script` / `--headless --quit`：`EXIT 0 / 0 / 0`；
  **8 份 `r23b_*.log` 的 `SCRIPT ERROR|Parse Error` 合计 = 0**。
- `verify_frame_data.gd` **650 PASS / 0 FAIL / RESULT=ALL_MATCH**（`VALIDATOR_CHECKS=533 VALIDATOR_ERROR=0`；
  翻滚 `4/9/9=22@60` 无敌 `[4,13)`、Boss `47/71/91`、E-8 `400/480/420` 不回退）；
  `verify_fx_profile.gd` **34 PASS**、`verify_fx_mobile.gd` **47 PASS**、
  `verify_quality_interaction.gd` **19 PASS**、`r19_verify_hud.gd` **20 PASS** —— 全部不回退。
- 既有非致命 WARNING（`2 ObjectDB instances were leaked` / `ChunkManager 未找到 ChunkRoot` / HUD 降级登记）
  非 `SCRIPT ERROR`、不改退出码，如实登记。

### 5. 与 HD-2D 目标的差距：**未达全绿**

新石砖贴图与角色细节明显改善，但：`uv1_scale` 高倍平铺重复感仍明显、暖金地面大面积偏亮（冷夜雾向地面渗透不足、
白天感残留）；景深仍为 2D 程序化分层近似（山影几何化，无 3D 深度雾 / DOF）；四项光效仍为 2D `draw_*` 近似
（`gl_compatibility` 不支持 HDR bloom / 体积光 / SSR）；8 pose 各仅 1 帧、无逐帧动作动画；角色为 3D
`AnimatedSprite3D` 像素贴图。本轮只做接入与目视回看、未精修美术，**不冒充全绿**。

### 6. 合规

零付费、未引入付费素材生成服务、一次只跑一个 GPU/编码任务；未写 `project.godot`；未自行 `git commit`；
产物按 `.gitignore`（`build/`、`*.exe`、`*.pck`、`*.apk`、`*.log`）排除不入库。
完整交付与未完成项见 `teamwork/Rank-1/DONE-R23B.md`，逐帧目视详见 `capture/R23-FINAL-REVIEW.md`。

---

## R24 v0.2.0 实机录屏（R24B · Rank-4 独占追加 · 2026-11-09 · 补单 `cmd-20261109-211247-261-A4`）

> 本节由 **Rank-4 独占追加**。四路 R24 已全部 done、工程冻结，本轮只补 15 秒实机录屏与总指挥目视回看证据；
> 不改任何 `godot/` 工程文件、不改美术资源、不自行 git。完整目视回看见 `capture/V020-RUNTIME-REVIEW.md`，
> 交付清单见 `teamwork/Rank-4/DONE-R24B.md`。
> **结论：450 帧 = 15 s 真实完整画面 + MP4 真实产出；三帧真看战斗 HUD 可见可读、夜景/视差/赐福/画质面板不回退、行为跨段推进；Boss 仍无可见像素形象（不替 Rank-1 翻案）、HD-2D 全绿未达，如实写「未达」。**

### 1. 录屏命令与实际帧数

复用 `godot/test/presentation.gd`，按 R22/R23 已验证命令形态（末尾位置参数 `res://scenes/courtyard.tscn` 为 R22 已验证必需项）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe \
  --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/v020_demo.png \
  --fixed-fps 30 --quit-after 450 \
  --script res://test/presentation.gd \
  res://scenes/courtyard.tscn
```

- **定稿 run2：`CAPTURE_EXIT=0`，450 帧 = `00:00:15:00`（15.000000 s）**，`SEG-A frame=0` / `SEG-B frame=150` / `SEG-C frame=300` / `时间线完成 frame=450`。
- **首次真跑 run1 偶发短录 285 帧 = 9.5 s**（`285 frames at 30 FPS (movie length: 00:00:09:15)`，停在 `frame=270`、无 SEG-C）：清理 `v020_demo*` 后**串行重跑同一命令**得定稿 450 帧，未改任何工程文件 / 脚本参数。root cause 未逐一追查（R24 新增 `[BossController]` 随机抽招时序 / 首次预热均有可能），`godot/` 运行时脚本经 Grep 诊断无主动 `quit()`，`v020_capture_run1.log` / `v020_capture_run2.log` 两份日志均留证，**如实登记不臆断、不冒充**。

### 2. 产物（真实产出，非伪造）

| 产物 | 实测 |
|---|---|
| PNG 序列 | **450 张** `v020_demo00000000.png` ~ `v020_demo00000449.png`，编号连续 `0..449`，IHDR 均 **1280×720**；首/中/尾 md5 `2c90061a…` / `f118adc5…` / `0cb37095…` 全不同（非单帧循环） |
| WAV | `v020_demo.wav` **5,760,044 B**（Movie Maker 自动音频轨，单独保留） |
| MP4 | `capture/v020_demo.mp4` **1,488,378 B**，`libx264 / yuv420p / +faststart`，`FFMPEG_EXIT=0`；ffprobe `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000` |
| **WAV 是否混入** | **未混入**。ffprobe 音频流计数 = **0**，MP4 仅视频轨；与 R22 `r22_demo.mp4`、R23B `r23_final.mp4` 口径一致，**如实登记、不谎报合并** |
| 日志 | `v020_capture_run1.log`（偶发短录）/ `v020_capture_run2.log`（定稿）/ `v020_ffmpeg.log` / `v020_gate_g*.log` / `v020_verify_fx_*.log` |

> 录屏（非 headless GPU 渲染）与 ffmpeg 编码**串行**执行，未与其它 GPU 任务并行。

### 3. ViewImage 首 / 中 / 尾三帧目视（真看）

| 帧 | 目视结论 |
|---|---|
| 首 `v020_demo00000000.png`（段 A medium/desktop） | 深蓝夜空 + 星点 + 远山剪影 + 冷蓝雾带（分层远景）；密集不规则暖金/青灰石砖透视地面；红发+钴蓝甲+金饰像素骑士 idle、脚下暖金光池；右上暖金光柱+光尘；左上「赐福 · 宁姆格福」、右上「画质设置 · 低/中/高」金线深蓝面板；**底部 y≈660 金色战斗 HUD 逐字可读** |
| 中 `v020_demo00000225.png`（段 B low/mobile） | 石砖纹理仍清晰、像素网格略粗；角色换 pose 完整可见；**四项光效全关**（光柱/光尘/倒影/bloom 消失、画面更暗）；深蓝夜景底色与分层远景仍在；标题变「赐福 · 巡礼教堂」(暗)；画质面板尺寸一致；底部战斗 HUD 清晰 |
| 尾 `v020_demo00000449.png`（段 C high/desktop） | 石砖最锐利；角色为红发+格纹头巾+胸前发光青蓝宝石 pose，无破图/重复小人；光柱/光尘/光池回归；标题「赐福 · 希芙拉河井底」暗色未点亮；画质面板可见；底部战斗 HUD 清晰 |

### 4. 逐项判定（未达全绿写未达）

- **底部战斗 HUD：可见可读（达到）** —— 三帧金色文字 `玩家 HP 100/100 ｜ Boss HP 100% ｜ 动作 idle 0/0 ｜ 闪避 0 ｜ 命中 0 ｜ 进行中` 逐字可读，与 Rank-1 R24 登记一致；**但数值整段不推进**（无输入注入，未完成项）。
- **Boss 可见像素形象：无（未达，不翻案）** —— 三帧均只有中央玩家骑士，无独立大型 Boss 精灵；`Boss HP 100%` 仅为 HUD 文本。与 **Rank-1 R24「无可见形象」一致，本轮不替它翻案**。
- **深蓝夜景 / 三层视差远景 / 赐福 HUD / 画质面板：均不回退** —— 深蓝渐变夜空+星点+远山剪影+横向雾带分层成立（2D 近似）；赐福标题随 flag 三段变化、画质面板三档尺寸一致不遮挡；相对 R22 亮蓝纯色天空为已升级并保持。
- **行为跨整段推进：是** —— `SEG=3 / POSE=30 / HUD=5 / 时间线完成 frame=450`，三帧 md5 全不同；段 B 四项全关期间 3D 主体静止（沿用 R22 边界），仅 pose/HUD 事件推进。
- **与《八方旅人》式 HD-2D 差距：未达全绿** —— 景深/光效仍为 2D `draw_*` 近似（无 3D 深度雾/DOF/体积散射/SSR/HDR bloom），地面高倍平铺重复感与白天感残留，8 pose 各仅 1 帧无逐帧动画，角色为 3D `AnimatedSprite3D` 像素贴图，Boss 无可见形象。本轮只做录屏与目视回看、未精修美术，**不冒充全绿**。

### 5. 门禁与回归（真跑，不回退）

- 三段门禁 `G1 --headless --import` / `G2 --headless --check-only --script res://test/presentation.gd` / `G3 --headless --quit`：**EXIT 0 / 0 / 0**。
- **9 份 `v020_*.log` 的 `SCRIPT ERROR|Parse Error|ERROR:` 合计 = 0**（逐份全 0，含录屏/ffmpeg/gate/verify 全部日志）→ **SCRIPT ERROR=0 通过**。
- `verify_fx_mobile.gd` **`pass=47 fail=0 RESULT=PASS`**、`verify_fx_profile.gd` **`pass=34 fail=0 RESULT=PASS`** → **47 / 34 不回退**。
- 既有非致命 `2 ObjectDB instances were leaked` WARNING（G3 与 verify 日志）非 SCRIPT ERROR、不改退出码，如实登记。
- 说明：Grep 工具目录 glob 对含 ANSI 控制符的 Godot 日志未匹配，门禁统计以任务明文的命令行 `grep` 完成（逐份计数全 0），Grep 工具对精确单文件交叉一致；如实登记工具行为，不影响结论。

### 6. 未完成项 / 合规

1. HD-2D 全绿未达成；Boss 无可见像素形象（不翻案）；战斗 HUD 数值不推进；段 B 主体静止；左侧固定深蓝尖锐几何形状（R23 已登记既有元素）来源未逐一追查。
2. run1 偶发短录 285 帧已留证，根因未逐一追查、不臆断；定稿为 run2 450 帧。
3. WAV 未混入 MP4、单独保留；未做人工试玩逐帧动态验收；Movie Maker 固定步长录屏不等价于实时性能评测。
4. 零付费、零外部依赖（本机 ffmpeg 可用）、一次只跑一个 GPU/编码任务；只写 `capture/` 与 `teamwork/Rank-4/`（+ 回执 `command_center/ai/4/outbox/`）；**未写 `project.godot` / `courtyard.tscn` / 任何 `.tres` / `.png` 美术资源，未自行 git**。

完整逐帧目视与差距分析见 `capture/V020-RUNTIME-REVIEW.md`；交付清单与未完成项见 `teamwork/Rank-4/DONE-R24B.md`。

---

## R25 v0.3.0 16 色受控色板重绘 + 录屏输入注入（R25 · Rank-4 独占追加 · 2026-11-10 20:47 · 派单 `cmd-20261110-204604-844-A4`）

> 本节由 **Rank-4 独占追加**。按总指挥裁决 A15（项目级色库 ≥256、单帧 ≤16 色索引），
> 用本机 PIL 程序化重绘 `godot/assets/generated/r23/` 下三套可发布素材，并在
> `godot/test/presentation.gd` 注入战斗演示序列；真跑 15 秒录屏 + ViewImage 目视。
> **结论：新 16 色素材确实进入画面、战斗 HUD 五项数值全部真实推进、47/34 PASS 不回退、
> 三段门禁 EXIT 0/0/0 且 SCRIPT ERROR=0；HD-2D 全绿仍未达，如实写「未达」。**
> 完整逐帧目视与差距分析见 `capture/V030-RUNTIME-REVIEW.md`，交付清单见 `teamwork/Rank-4/DONE-R25.md`。

### 1. 重绘口径（A15）与自验

| 项 | 实测 |
|---|---|
| 项目级色库 | `teamwork/Rank-4/palette_256_v030.json`：304 项 / **288 唯一色（≥256）**；既有 `palette_256.json` 未改 |
| 单帧色数 | 13 张 128×128 单帧/tile 非透明唯一 RGB **3~9 色（≤16）**，全部取自色库 16 个基色索引 |
| 画布 / 缩放 | 128px 基准画布；64×64 原生逻辑网格 **×2 NEAREST**（每 2×2 块同色，全检 PASS） |
| 硬边 / alpha | 无渐变 / 无 dithering / 无高频噪点；RGBA 二值 alpha（0 或 255），ground 全 255 |
| 路径不变 | 15 张 PNG + `player_spritesheet.png`(1024×128) / `boss_spritesheet.png`(384×128) 路径逐字不变，只换内容；旧版备份 `r23_pre_v030_backup/`（15 张，可恢复） |
| 一致性 | spritesheet 逐 128 切片与对应单帧**像素级一致 8/8 + 3/3**；`ground_tile.png` 左右/上下边缘像素**完全一致** |
| 目视 | `r23_v030_contact.png` 联系表 ViewImage 真看：8 玩家动作帧姿态互异、3 Boss 招式武器各异、4×4 石砖、无破图/空白 |

> 未改 `manifest.json`（R23 历史 provenance 如实保留）、未改任何 `.tres` / `.png.import` / 场景（除 `presentation.gd` 的纯追加）。

### 2. 15 秒录屏产物（真跑）

命令形态复用 R22/R23B/R24B（`--write-movie … --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`）：

| 项 | 实测 |
|---|---|
| CAPTURE_EXIT | **0**；`450 frames at 30 FPS (00:00:15:00)` |
| PNG | **450 张** `v030_demo00000000.png`~`00000449.png`，均 1280×720；首/中/尾 md5 全不同 |
| MP4 | `v030_demo.mp4` **607,659 B**，`libx264/yuv420p/+faststart`，`FFMPEG_EXIT=0`；ffprobe `nb_frames=450 / duration=15.000000 / 30/1` |
| WAV | `v030_demo.wav` 5,760,044 B 真实产出，**未混入 MP4**（ffprobe 音频流=0），与 R22~R24B 口径一致、不谎报合并 |
| 日志 | `v030_capture.log` / `v030_ffmpeg.log` / `v030_gate_g*.log` / `v030_verify_fx_*.log` 共 7 份 |

### 3. 战斗 HUD 数值推进（本轮核心，ViewImage 逐字 + get_snapshot 日志双证）

注入只经 `EncounterDirector` 既有 `debug_*` 接口（`debug_request_action / debug_boss_hit / debug_step / debug_kill_boss`）+ `get_snapshot()`，由导演层自身 `_update_hud()` 刷新 `StatusLabel`，**不写 HUD 文本、不伪造数值**。

| 帧 | 玩家 HP | Boss HP | 动作 | 闪避 | 命中 | 状态 |
|---|---|---|---|---|---|---|
| 0 首 | 100/100 | 100% | idle 0/0 | 0 | 0 | 进行中 |
| 30 | 100/100 | 98% | **attack_light 12/27** | 0 | **1** | 进行中 |
| 90 | **88/100** | 98% | **roll 5/22** | **1** | 1 | 进行中 |
| 150 | 88/100 | 98% | **attack_heavy 16/54** | 1 | 1 | 进行中 |
| 225 中 | 88/100 | **95%** | idle 0/0 | 1 | **2** | 进行中 |
| 449 尾 | 88/100 | **0%** | idle 0/0 | 1 | **3** | **胜利 · 已落盘** |

五项（玩家 HP / Boss HP / 动作帧 / 闪避 / 命中）**各至少变化一次**，状态亦推进。首/中/尾三帧恰好都落在动作窗口外（idle 0/0），故补看 f30/f90/f150 三个注入帧作为「动作帧变化」目视证据；6 行 `[R25][COMBAT]` 的 `get_snapshot()` 日志与 HUD 文字逐项吻合。

### 4. 新素材进画面 / 行为 / 差距

- **新素材进入画面 = 是**：地面由 R23 不规则密集石砖 → 本轮 4×4 规整大砖 + 整齐砖缝 + 确定性磨损块；骑士由精致多色像素 → 简化 16 色硬边像素骑士（红头巾/白脸/钴蓝甲/白剑），8 pose 可辨。
- 三段画质切换（medium/desktop → low/mobile → high/desktop）、`set_pose` 切帧、赐福标题三段变化全部保留；既有 `_drive_segment / _drive_pose / _drive_hud_flags` 逐字未改，只追加 `_drive_combat_v030`。
- **HD-2D 全绿未达**：16 色受控色板相对 R23 ComfyUI 数千色精致素材是**细节降级 / 占位化**（口径取舍，不冒充视觉升级）；景深 / 四项光效仍为 2D `draw_*` 近似，8 pose 各仅 1 帧无逐帧动画，Boss 无可见像素形象（不翻案），段 B 主体静止，左侧深蓝尖锐几何形状来源未追查。本轮只做重绘 + 注入 + 录屏，未精修美术。

### 5. 门禁与回归（真跑，不回退）

- 三段门禁 `--headless --import` / `--headless --check-only --script res://test/presentation.gd` / `--headless --quit`：**EXIT 0 / 0 / 0**。
- `verify_fx_mobile.gd` **pass=47 fail=0 RESULT=PASS**、`verify_fx_profile.gd` **pass=34 fail=0 RESULT=PASS** → **47 / 34 不回退**。
- **7 份 `v030_*.log` 的 `SCRIPT ERROR|Parse Error` 逐份 0、合计 0，字面 `SCRIPT ERROR=0`**。

### 6. 未完成项 / 阻塞 / 合规

1. HD-2D 全绿未达成（§4）；16 色重绘为细节降级。
2. **旧 GPU job 长期阻塞**：`qwen-image --quant nf4` 历史 job 本轮只读核验一次 —— `asset_proof_stdout.txt` 0 B、`asset_proof_stderr.log` 25,320 B，Rank-4 下全部 PNG 最新 mtime 2026-11-09 14:06（R23 旧产出），**无任何 11-10 之后的新 PNG**；无产出可验收，记为长期阻塞，不等待、不重试拉起、**本轮零 GPU 生成任务**。
3. WAV 未混入 MP4；`128bit` 歧义待用户确认、不消歧、不编码进期望值（A15）；人工试玩属用户侧（A17），本轮只给勾选清单不冒充完成。
4. 零付费、零外部依赖（本机 PIL/ffmpeg/numpy）；只写 `r23/` PNG、`presentation.gd`、`capture/`、`teamwork/Rank-4/`；**未写** `project.godot` / `courtyard.tscn` / `encounter_director.gd` / 任何 `.tres` / 其它 Rank 工位 / `00-*` 契约总线；未自行 git。
5. 本轮未生成 `00-汇总.md`、未对跨模块争议裁决。

完整逐帧目视与差距分析见 `capture/V030-RUNTIME-REVIEW.md`；交付清单与未完成项见 `teamwork/Rank-4/DONE-R25.md`。

### 7. 定稿补记（本任务单最终交付口径 · 2026-11-10 21:20 · Rank-4）

> **如实登记并发**：本任务单被两个 Rank-4 实例并发执行。上方 §1~§6 为前次实例（约 20:47，
> `capture/v030_*.log`，MP4 **607,659 B**）产出；**磁盘最终产物以本定稿第二次真跑（21:18，
> `capture/r25_*.log`，MP4 **829,818 B**）为准**——本定稿重新串行真跑录屏 + ffmpeg 覆盖了
> `capture/v030_demo*.png` / `v030_demo.mp4` / `v030_demo.wav`。两版日志与报告并存留证，
> 不删除前次产物、不臆断并发来源。以下为本定稿实测（详见 `capture/V030-RUNTIME-REVIEW.md` 定稿版、
> `teamwork/Rank-4/DONE-R25.md` 定稿版）。

**7.1 重绘实测（本机 PIL，零付费 / 零外部素材服务）**

| 项 | 本定稿实测 |
|---|---|
| 工具 / 证据 | `teamwork/Rank-4/r25_redraw.py`、`r25_redraw_metrics.json`、`r25_contact_player.png`、`r25_contact_boss_tile.png`、`r25_preview/`（先目视后接入） |
| 三套可发布素材 | `player_spritesheet.png` **1024×128 / 8 帧**（逐帧 15/15/15/11/15/15/15/11 色）；`boss_spritesheet.png` **384×128 / 3 招**（逐帧 11 色）；`ground_tile.png` **128×128 / 10 色 / alpha 全 255** |
| 单帧非透明唯一 RGB | player 单帧 **11~15 色**、boss 单帧 **11 色**、ground **10 色**、decor **8 色**，全部 **≤16**；全部落在与 `r23_baseline/player_idle_v1.png` 一致的 16 色板内（`palette_outside={}`） |
| 网格 / 硬边 | 64×64 逻辑 ×2 NEAREST，全部 `block2_mismatch=0`；无渐变 / 无 dithering / 无高频噪点；RGBA 二值 alpha（0/255，ground 全 255） |
| tile 无缝 | `LR_mismatch_rows=0` / `TB_mismatch_cols=0` / `four_corners_equal=true` |
| 姿态互异 | 8 玩家帧、3 Boss 帧 md5 **全不同**（`player_all_distinct=true` / `boss_all_distinct=true`），非复制同一张图 |
| 路径 / 备份 | 15 张 PNG + 2 spritesheets 路径逐字不变、只换内容；旧版 15 张（Nov 9 时间戳、34877/16733/13605 色）备份于 `teamwork/Rank-4/r23_pre_v030_backup/`，可恢复（本轮 commit 因备份已存在而跳过复制，未破坏） |
| 未改 | `manifest.json`（R23 历史 provenance）、任何 `.tres` / `.png.import` / 场景 / 契约 / `project.godot` / `encounter_director.gd` |

**7.2 15 秒录屏与 MP4（本定稿真跑）**

`CAPTURE_EXIT=0` / `FFMPEG_EXIT=0`；**450 张** `v030_demo*.png`（1280×720，0..449 连续），
`450 frames at 30 FPS (00:00:15:00)`；首/中/尾 md5
`b4dc270e…` / `a090e443…` / `0ceb6d2e…` 全不同；`v030_demo.mp4` **829,818 B**，
ffprobe `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000 / +faststart`；
`v030_demo.wav` **5,760,044 B** 单独保留，**WAV 未混入 MP4**（ffprobe 音频流=0，仅视频轨，如实登记）。

**7.3 战斗 HUD 数值推进（本定稿 `r25_capture.log` 7 行 `[R25][COMBAT]` + ViewImage 逐字双证）**

| 帧 | 事件 | 玩家 HP | Boss HP | 动作 / 帧 | 闪避 | 命中 | 状态 |
|---:|---|---:|---:|---|---:|---:|---|
| 0 首 | 初始 | 100/100 | 100% | idle 0/0 | 0 | 0 | 进行中 |
| 30 | 轻攻击命中 | 100/100 | 98% | attack_light 12 | 0 | 1 | 进行中 |
| 60 | 玩家受击 | 88/100 | 98% | idle 0 | 0 | 1 | 进行中 |
| 90 | 翻滚闪避 | 88/100 | 98% | roll 5 | 1 | 1 | 进行中 |
| 150 | 重攻击命中 | 88/100 | 95% | attack_heavy 20 | 1 | 2 | 进行中 |
| 220 | 段 B 中段受击 | 76/100 | 95% | idle 0 | 1 | 2 | 进行中 |
| 225 中 | （HUD 逐字） | 76/100 | 95% | idle 0/0 | 1 | 2 | 进行中 |
| 300 | 轻攻击再推进 | 76/100 | 94% | attack_light 12 | 1 | 3 | 进行中 |
| 430 / 449 尾 | 击败 Boss | 76/100 | 0% | idle 0/0 | 1 | 3 | 胜利·已落盘 |

五项（玩家 HP 100→88→76 / Boss HP 100→98→95→94→0% / 动作帧 / 闪避 0→1 / 命中 0→1→2→3）
**各至少变化一次**；全部经 `EncounterDirector` 既有 `debug_*` 接口 + `get_snapshot()`，
由导演 `_update_hud()` 刷新，**不写 `StatusLabel.text`、不伪造数值**。相对前次实例，本定稿修正了
`presentation.gd` 中 `attack_heavy` 的 `debug_step(16)`（startup=20，step 16 不命中）为 `debug_step(20)`，
并补 f=220 段 B 注入，故 C-04 真实命中、中帧玩家 HP 推进到 76。

**7.4 三帧目视（本定稿 ViewImage 真看）**

- 首帧 0：16 色 `idle` 骑士 + 4×4 规则砖地清晰进入画面，HUD `100/100 | 100% | 闪避0 命中0 | 进行中`。
- 中帧 225：HUD `76/100 | 95% | 闪避1 命中2 | 进行中` 已推进；但 `death` 横躺贴地暗色融入砖地，
  **角色不可辨（未达）**；加抽 frame 180（`attack_light` 横斩）骑士清晰，证明非段 B 画质档整体丢失。
- 尾帧 449：`attack_heavy`（剑高举）骑士清晰，HUD `76/100 | 0% | 闪避1 命中3 | 胜利·已落盘`。
- 三段画质切换 / pose 切换 / 赐福标题事件驱动 / 深蓝夜景分层远景全部保留；HD-2D 全绿**未达**（景深光效仍 2D 近似、8 pose 各 1 帧、Boss 无可见形象、砖地高倍平铺、death 单帧不可辨），如实写未达、不冒充。

**7.5 门禁与回归（本定稿真跑，不回退）**

| 段 | 日志（`capture/r25_*.log`） | EXIT / 结论 |
|---|---|---|
| G1 `--headless --import`（录屏前重导入 15 张新 PNG） | `r25_g1_import.log` | **0** |
| G2 `--headless --check-only --script res://test/presentation.gd` | `r25_g2_checkonly.log` | **0**（注入脚本语法通过） |
| G3 `--headless --quit` | `r25_g3_quit.log` | **0**（仅既有 `2 ObjectDB instances were leaked` 非致命 WARNING） |
| RUN mobile | `r25_verify_fx_mobile.log` | **0** · `pass=47 fail=0 total=47 RESULT=PASS` |
| RUN profile | `r25_verify_fx_profile.log` | **0** · `pass=34 fail=0 total=34 RESULT=PASS` |

- **7 份 `r25_*.log` 的 `SCRIPT ERROR|Parse Error` 逐份 0、合计 0，字面 `SCRIPT ERROR=0`**；
  **47 PASS / 34 PASS 不回退**。

**7.6 未完成项**：HD-2D 全绿未达；frame 225 `death` 角色不可辨（单帧可辨识度缺陷，未重绘修复）；
Boss 无可见像素形象；WAV 未混入 MP4；`128bit` 歧义待用户确认；人工试玩属用户侧；
双实例并发的两版日志/报告并存（不臆断来源）；未做人工试玩逐帧动态验收；未自行 git（总指挥收尾）。

---

## 8. R25B v0.3.0 定稿（补单 `cmd-20261110-214727-361-A4` · 2026-11-10 21:50~21:55 · Rank-4）

> 四路 R25 已全部 done、工程冻结，本轮只做两件收口：**重录最终画面 + 重导双产物**。
> 本节为**独占追加**，不改动上方 §1~§7 任何既有正文（含 R25 定稿补记 §7）；两版日志 / 产物并存留证。
> 日志统一前缀 `capture/r25b_*.log`；完整评审见 `capture/V030-FINAL-REVIEW.md`，交付清单见 `teamwork/Rank-4/DONE-R25B.md`。

**8.1 重录 15 秒最终画面（先 `--import`）**

- `--headless --path <godot> --import`：`IMPORT_EXIT=0` / `SCRIPT ERROR=0`（`r25b_g1_import.log`，16 行）。
- 录屏：`--write-movie capture/v030_final.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`
  （沿用定稿 `presentation.gd` 输入注入 + 三段画质切换，本轮零改动；不加 `--headless` 保证 Movie Maker 真实渲染）。
  `CAPTURE_EXIT=0`；**450 张** `v030_final00000000.png`~`v030_final00000449.png`（1280×720 RGBA，0..449 连续）；
  `450 frames at 30 FPS (00:00:15:00)`；首/中/尾 md5 `95d8b628…` / `8a27bbe9…` / `78c2742b…` 全不同。
- MP4：`capture/v030_final.mp4` **867,453 B**；`FFMPEG_EXIT=0`；ffprobe `h264 / yuv420p / 1280×720 / 30fps / nb_frames=450 / duration=15.000000 / +faststart`。
- WAV：`capture/v030_final.wav` **5,760,044 B**（Movie Maker 自动音轨）；**WAV 未混入 MP4**（ffprobe 音频流 = 0，仅视频轨），如实登记、不谎报音视频合并。
- 与 R25 `v030_demo.mp4`（829,818 B）并存：本轮为**新重录序列**（`v030_final*`），因 Rank-1 Boss 接线最终修正进入工程，画面出现第二个角色，字节数变化如实登记、非旧文件改名。

**8.2 三帧目视（ViewImage 真看原图 + 2× 中央放大裁剪 `r25b_{head,mid,tail}_center_crop.png`）**

| 帧 | Boss 第二角色 | 玩家骑士 | HUD 逐字 | 光效 / 标题 |
|---|---|---|---|---|
| 首 0（段 A medium/desktop） | **可见**：金角+白脸+红披风，与骑士并列（与 Rank-1 `v030_boss_00000000.png` 实证形象一致） | 清晰：`idle` 蓝甲 / 蓝盾青宝石 / 竖直亮钢剑 | `100/100 \| 100% \| idle 0/0 \| 闪避0 \| 命中0 \| 进行中` | 光柱+光尘+光池；「赐福 · 宁姆格福」；画质面板在 |
| 中 225（段 B low/mobile） | **可见且清晰**（金角 / 白脸 / 红披风 / 金肩甲青条 / 金胸甲青宝石） | **不可辨（未达，不翻案）**：`death` 横躺贴地暗色融入砖地 | `76/100 \| 95% \| idle 0/0 \| 闪避1 \| 命中2 \| 进行中` | 四项光效全关、更暗；「赐福 · 巡礼教堂」；画质面板在 |
| 尾 449（段 C high/desktop） | **可见**：金角+白脸+红披风，与骑士并列 | 清晰：`attack_heavy` 亮钢剑高举过头 | `76/100 \| 0% \| idle 0/0 \| 闪避1 \| 命中3 \| 胜利·已落盘` | 光柱/光尘/光池回归；「赐福 · 希芙拉河井底」暗色；画质面板在 |

- **Boss 第二个角色是否可见：是**（首/尾并列、中帧单独清晰）。相对 R25「Boss 无可见像素形象」为 Rank-1 接线修正带来的真实变化，如实登记、不冒充本轮改工程。
- **16 色重绘素材进画面：是**（4×4 规则大砖全段可见、干净硬边色块、无渐变/噪点/马赛克）。
- **三套 HUD 不回退：是**（赐福标题框事件驱动变化 / 画质设置面板三按钮 / 底部战斗 HUD 五项，三帧全程在）。
- **战斗数值推进**：玩家 HP 100→88→76、Boss HP 100%→98.77%→95.96%→94.74%→0%、闪避 0→1、命中 0→1→2→3、动作帧 attack_light/12→roll/5→attack_heavy/20，
  由 `r25b_capture.log` 7 行 `[R25][COMBAT]` `get_snapshot()` + 三帧 HUD 逐字双证；**动作帧在三个采样点均显示 `idle 0/0`，推进以全程日志为准，如实登记不粉饰**。
- **中帧角色不可辨必须写未达**：玩家骑士 `death` 仍不可辨（沿袭 R25 结论、**不翻案**）；Boss 可见为新增事实，二者不互相抵消。经 2× 中央放大复核确认。
- **HD-2D 全绿未达**：景深/光效仍 2D `draw_*` 近似、Boss 与玩家并列叠合缺纵深站位/遮挡、地面高倍平铺重复、8 pose 各 1 帧、角色仍 3D 贴图像素、16 色为细节降级、death 单帧不可辨、左侧固定深蓝尖锐形状来源未追查。如实写未达、不冒充。

**8.3 重导双产物与验签（`JAVA_HOME=D:/AndroidToolchain/jdk17`、SDK `D:/AndroidToolchain/sdk`、debug.keystore 就位）**

| 命令 | EXIT | 说明 |
|---|---|---|
| `--headless --export-release "Windows Desktop"` | **0** | 重生成 `build/Aierdengfahuan.exe` + `.pck` |
| `--headless --export-debug "Android"`（JAVA_HOME=jdk17） | **0** | 重生成 `.apk` + `.apk.idsig`；签名走 `build-tools/36.1.0/apksigner.bat sign`；stdout 一条既有非致命 `ERROR: No project icon specified`（工程冻结未改图标） |

新旧字节数（旧 = R23B / 14:35~14:36，导出前磁盘实测；新 = R25B / 21:53~21:54）：

| 产物 | R23B 旧 | **R25B 新** | 差异 |
|---|---:|---:|---:|
| `Aierdengfahuan.exe` | 109,127,680 B | **109,127,680 B** | 0（`embed_pck=false` 固定 Windows 模板，工程内容全在 `.pck`） |
| `Aierdengfahuan.pck` | 1,579,332 B | **1,124,888 B** | **-454,444 B** |
| `Aierdengfahuan.apk` | 29,829,394 B | **29,377,137 B** | **-452,257 B** |
| `Aierdengfahuan.apk.idsig` | 239,026 B | **239,026 B** | 0（时间戳刷新 21:54，v4 验签 `true` 证明与新 apk 匹配） |

> pck/apk 减小如实归因：R25 三套素材重绘为 16 色（实测 15/11/10 色），PNG 体积大幅下降；
> `savepack` / `export` 100% 完成、`EXIT=0`、验签通过，非漏打包、非旧文件残留。

验签（`apksigner.bat verify --verbose --print-certs`，JAVA_HOME=jdk17）：`Verifies` / v2=**true** / v3=**true** /
v3.1=false / v4=false（默认未传 idsig）/ Number of signers: 1，EXIT=0；追加 `--v4-signature-file Aierdengfahuan.apk.idsig`：
`Verifies` / v2=**true** / v3=**true** / **v4=true**，EXIT=0。`aapt dump badging` 首行包名 **`com.aierdengfahuan.game`**
（versionCode=1 / versionName=1.0.0 / targetSdkVersion=36）。**Verifies ✓ / v2+v3(+v4) true ✓ / 包名 ✓ 全部达标。**

产物按 `.gitignore`（第 8 行 `build/`、10~13 行 `*.exe`/`*.pck`/`*.apk`/`*.aab`、26 行 `*.log`）排除、不入库；
**未执行任何 git 写操作**（不自行 git）。

**8.4 三段门禁与 PASS 不回退（真跑）**

| 段 | 日志（`capture/r25b_*.log`） | EXIT / 结论 |
|---|---|---|
| G1 | `r25b_g1_import.log`（`--import`） | **0** |
| G2 | `r25b_g2_checkonly.log`（`--check-only --script res://test/presentation.gd`） | **0** |
| G3 | `r25b_g3_quit.log`（`--quit`） | **0**（仅既有非致命 `2 ObjectDB instances were leaked` WARNING） |
| RUN mobile | `r25b_verify_fx_mobile.log` | **0** · `pass=47 fail=0 total=47 RESULT=PASS` |
| RUN profile | `r25b_verify_fx_profile.log` | **0** · `pass=34 fail=0 total=34 RESULT=PASS` |
| RUN v010 | `r25b_verify_encounter_v010.log` | **0** · `pass=20 fail=0 RESULT=ALL_MATCH` |
| RUN v020 | `r25b_verify_encounter_v020.log` | **0** · `pass=45 fail=0 RESULT=ALL_MATCH` |

- **13 份 `r25b_*.log` 的 `SCRIPT ERROR|Parse Error` 逐份 0、合计 0 → 字面 `SCRIPT ERROR=0`**；
  **47 / 34 / 20 / 45 PASS 不回退**。

**8.5 未完成项**：HD-2D 全绿未达；中帧玩家 `death` 不可辨（不翻案）；Boss 与玩家并列叠合缺纵深站位；
WAV 未混入 MP4；动作帧三采样点均 `idle 0/0`；Android 导出非致命 `No project icon specified`；
未做人工试玩逐帧动态验收；`128bit` 歧义待用户确认；未自行 git（总指挥收尾）；
工程源文件与素材零改动（工程冻结）。**阻塞：无。**

---

## 9. R26 v0.4.0 逐像素精修 16 色角色 / 逐帧动作 / 地面收敛 / 15 秒录屏（Rank-4 独占追加 · 2026-11-11 · 派单 `cmd-20261111-073556-932-A4` · `[ROUND=R26]`）

> 详细运行期目视复核见 `capture/V040-RUNTIME-REVIEW.md`；素材自检见
> `teamwork/Rank-4/r26_redraw_metrics.json`；交付清单见 `teamwork/Rank-4/DONE-R26.md`。
> 用户判定「像素化不是马赛克」、R25 16 色重绘又出现「积木感」，本轮做**逐像素精修**。

**9.1 重绘实测（本机 PIL 12.3.0，零付费 / 零外部素材生成服务）**

沿用 `teamwork/艾尔登法环HD2D-美术风格提案.md` 锚点 v1 的 16 色板与外描边 `#0A1020`，
`r26_redraw.py` 把 R25 的大矩形块改为逐像素轮廓化造型：头盔逐行圆顶 + 金盔脊 +
面甲(眼缝 T 字/鼻梁/呼吸孔/护颊/高光) + 红缨斜飘、肩甲逐行斜边梯形 + 高光边 + 铆钉、
披风逐行飘动轮廓 + 明暗褶皱竖条 + 锯齿下摆、胸甲收腰 + 板甲分层线 + 菱形金饰 + 青宝石、
鸢盾逐行弧边、剑身中脊/刃高光/收尖/金剑格/缠柄/剑首。**消除积木感**。

| 项 | 实测 |
|---|---|
| 单帧色数 | 玩家 8 pose **11–16 色**（≤16）；Boss 3 招 **11 色**；地面 **6 色**；装饰 8 色；色板零越界 |
| 规格 | 64×64 逻辑网格 ×2 NEAREST → 128×128 RGBA；`block2_mismatch=0`（严格 2×2 硬边）；alpha 仅 0/255；无渐变/无 dithering/无噪点 |
| ★ death | 横躺剪影抬到画面中部、头/躯干/武器分色、主体亮面 `STEEL/WHITE/GOLD/COBALT_L` 与地面 `COBALT/DARK` 分离；`death_avg_luma=81.72` vs `ground_avg_luma=67.77`（delta **+13.95**），不再贴地隐形 |
| 旧版备份 | `teamwork/Rank-4/v030_pre_v040_backup/`（**17 文件**：15 PNG + 两份 `.tres`），先备份再覆盖 |

**9.2 逐帧动作（8×3=24 帧 / Boss 3×3=9 帧）**

| 项 | 实测 |
|---|---|
| `player_spritesheet.png` | **3072×128 / 24 帧**，每帧 ≤16 色；帧物理顺序 `x = action*3*128 + sub*128` |
| `boss_spritesheet.png` | **1152×128 / 9 帧**，每帧 ≤11 色 |
| 子帧差异 | 呼吸 `dy` / 武器角度 / 披风褶皱相位 / 腿部步态 / 红缨飘幅；**8 pose + 3 招各 3 子帧 md5 全互异**（`player_all_3_distinct=true / boss_all_3_distinct=true`） |
| 两份 `.tres` | `chars/player_spriteframes.tres`（8 动画 ×3 帧）、`boss/boss_spriteframes.tres`（3 动画 ×3 帧）；`region.x = action*3*128 + sub*128`；`ext_resource` 的 path/id 与动画名逐字不变、loop 保持；本轮 Rank-4 独占授权 |
| 单帧 PNG | 8 `player_<pose>.png` + 3 `boss_<move>.png` 同步刷新为对应 pose 第 0 子帧内容，路径不变 |

**9.3 地面收敛 / 裁决 A19**

`ground_tile.png` 去绿(TEAL)/黄(GOLD)杂色点，4×4 大砖保持，明度 4 阶全蓝系
(`DARK/COBALT/COBALT_L/SKY_L`) + 缝色 `OUT` + 角部 `INK`，6 色、不透明、
左右/上下边缘像素逐像素完全一致（`LR_mismatch_rows=0 / TB_mismatch_cols=0 / four_corners_equal=true`）。

**裁决 A19：本轮 Rank-4 未写 `courtyard.tscn`**（Rank-1 独占，避免并发覆盖）。
三处 `uv1_scale` 建议值 **16/3/2 → 4/2/1** 仅在此登记；只读核对当前场景已由 Rank-1 落盘为
`Vector3(4,4,1) / Vector3(2,2,1) / Vector3(1,1,1)`（x 分量即 4/2/1），与建议值一致。

**9.4 `godot/test/presentation.gd`（Rank-4 独占）**

保留三段画质切换（`_drive_segment` medium→low→high）、赐福 HUD flag、战斗 HUD 注入三套既有 HUD 可读性；
① `_drive_pose` 改每 5 帧推进子帧、3 子帧(0/1/2)轮转、每 15 帧换 pose，
使两份 `.tres` 每动画 3 帧在 450 帧录屏中真实可见（`[R26][POSE]` 90 行日志）；
② 追加 `_drive_wave_hud`（防御性）：并发期间 Rank-1 落盘 `WaveTrialDirector` 后真实命中，
只经既有公开接口 `start_trial() / debug_advance(sec) / on_encounter_finished(true) / get_snapshot()`
确定性推进三波，绝不写 `Label.text`、不伪造波次数值。
`SUBFRAME_INTERVAL=5` 标 [PLACEHOLDER] 待试玩校准。

**9.5 15 秒录屏 / MP4 / WAV（真跑）**

| 项 | 实测 |
|---|---|
| 录屏 | `--write-movie capture/v040_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`），**EXIT=0 / 450 帧 / 1280×720 / 15.000000s** |
| 三波 HUD | `r26_capture.log` 三行 `[R26][WAVE]` 与三帧逐字双证：第 1/3 波(点数 0) → 第 2/3 波(100、最佳 1) → 第 3/3 波(250、最佳 2) → 尾帧 450/3 全清 |
| MP4 | `capture/v040_demo.mp4` **754,476 B**，`libx264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / +faststart`（`moov` 前置），`FFMPEG_EXIT=0` |
| **WAV 是否混入 MP4** | **未混入**：ffmpeg 输入仅 PNG 序列、无音频 `-i`，`ffprobe -select_streams a` 音频流计数 = **0**。如实登记，不谎报音视频合并 |

**9.6 三帧目视（ViewImage 真看，结论见 `V040-RUNTIME-REVIEW.md`）**

| 判定 | 结论 |
|---|---|
| 角色是否还像积木 | **否（达标）**：面甲/肩甲/披风褶皱/剑盾细节可辨，逐像素轮廓化脱离大方块 |
| death 是否可辨 | **是（重点修复达标，相对 R25B 翻案）**：中帧 225 横躺人形头/躯干/散落剑盾分色，不再贴地隐形 |
| 地面是否去杂色 | **是**：干净蓝灰 4×4 砖、无绿/黄杂色点与噪点、无缝 |
| 波次 HUD 是否可读 | **是**：三波 1/3→2/3→3/3 真实推进，金色 WaveLabel 全程可读；三套既有 HUD 全在 |
| **HD-2D 全绿** | **未达（如实写未达）**：景深/光效仍 2D `draw_*` 近似、Boss 与玩家并列叠合缺纵深、地面高倍平铺重复、左侧深蓝尖锐形状来源未追查、角色仍是 3D 贴图像素精灵、未做人工试玩逐帧动态验收、动作帧三采样点均 `idle 0/0` |

**9.7 门禁与 PASS 不回退（真跑 `capture/r26_*.log`）**

G1 `--headless --import` / G2 `--headless --check-only --script res://test/presentation.gd` /
G3 `--headless --quit` 三段 **EXIT=0**；**12 份 `r26_*.log` 的 `SCRIPT ERROR|Parse Error` 逐份 0、合计 0 → 字面 `SCRIPT ERROR=0`**；
`47 / 34 / 20 / 45 / 53 PASS` **不回退**（v030 实跑即 53）；
R26 新增 `verify_wave_trial_v040.gd` **58 PASS**、`verify_wave_runtime_v040.gd` **37 PASS** 额外真跑 `ALL_MATCH`。

**9.8 未完成项 / 合规**：HD-2D 全绿未达（§9.6）；三采样点动作帧 HUD 仍 `idle 0/0`；
未做人工试玩逐帧动态验收；`128bit` 歧义待用户确认；`SUBFRAME_INTERVAL=5` 为 [PLACEHOLDER] 待试玩校准；
未写 `courtyard.tscn` / `project.godot` / 导演层 / 契约 / README / 其它 `.tres`；未自行 git（总指挥收尾）；
零 GPU 额外 job、零付费、零外部素材服务（程序化 PIL），录屏与 ffmpeg 编码串行。**阻塞：无。**

---

## 10. R27 v0.5.0 · Rank-4 完善旧内容（派单 `cmd-20261111-083350-249-A4`）

> `[ROUND=R27]` · Rank-4 独占追加 · 引擎 4.7.2.stable / ffmpeg 9.0.2（绝对路径）
> 逐项实证见 `capture/V050-RUNTIME-REVIEW.md`、`teamwork/Rank-4/DONE-R27.md`、`capture/r27_*.log`。
> 结论以「跑起来的画面」为准，不粉饰、不谎报。

**10.1 三波空间节奏画面 / 纵深站位**

`hd2d_parallax.gd` 新增 `wave_index`（1/2/3）与 `set_wave_index(w)`，按波次让
远景色带 / 雾密度 / 地面色调 / 山影振幅 / 地平线高光产生可辨差异：
波1 冷蓝基准（雾×1.00 / 地面×1.00 / 山影×1.00）；波2 深紫浓雾（雾×1.75 / 地面×1.40 / 山影×1.30）；
波3 暖紫雾散（雾×0.60 / 地面×0.70 / 山影×0.80 / 地平线暖金 0.34）。
`presentation.gd` 在 `frame=0/150/300` 与三段画质切换、三波 HUD 对齐驱动，
`r27_capture.log` 三行 `[R27][SPACE] ... set_wave_index(1/2/3) -> 回读 wave_index=1/2/3` 实证。
`[PLACEHOLDER]` 色带/雾/地面数值待试玩校准（rationale：零新增素材、零 GPU job，靠 2D `_draw()` 色带与 alpha 叠加呈现三波空间节奏）。
像素实证（避开 HUD 面板）：天空 (620,60) 波1 `(21,33,60)` → 波2 `(36,44,77)` → 波3 `(51,28,49)` 暖紫红；
地面 (1000,620) `(60,79,109)` → `(57,72,109)` → `(70,84,111)`。
`courtyard.tscn` 把 `Player` 移到 `(-3.5, 0, 2.0)`、`BossVisual` 移到 `(0.5, 0, -8.0)`（x 差 4.0 / z 差 10.0），
三帧实机画面玩家近大、Boss 远小、上下分离，**不再并列叠合**。

**10.2 Android 项目图标 / 导出 stdout**

程序化生成 `godot/icon.png` **128×128 RGBA 金线深蓝**（深蓝底 `#0B1226` + 双金框 + 三重金环 +
黄金树竖干/放射枝 + 四角金饰 + 金核），先 ViewImage 目视通过再接入；
`project.godot` 在 `[application]` 段**只加 `config/icon="res://icon.png"` 一行**，其它段逐字不动。
真跑 `--headless --export-debug "Android"`（`JAVA_HOME=D:/AndroidToolchain/jdk17` /
`ANDROID_HOME=D:/AndroidToolchain/sdk` / `debug.keystore`）：**EXIT=0**，
`capture/r27_export_android.log` 中 `No project icon specified` 计数 = **0**（历史对照 `r25b_export_android.log` = 1），
APK 生成 `res/mipmap-*/icon.webp` 多分辨率图标、`apksigner` 签名 `Signed`、产物 `build/Aierdengfahuan_r27.apk` 29,756,181 B。
**该历史非致命警告本轮已消除（如实登记，不谎报）。**

**10.3 左侧固定深蓝尖锐几何形状：来源与修复**

受控实验定位（`r27_probe_a/b/c_*.png`）：隐藏 `Terrain` → 形状消失；只隐藏 `TerraceHigh` → 形状消失。
**来源 = `courtyard.tscn` 的 `SubViewportContainer/SubViewport/Terrain/TerraceHigh`**
（`MeshInstance3D` + `BoxMesh_k5tdy` size `(8,1.2,8)` + 材质 `StandardMaterial3D_uvhigh`
`uv1_scale=(1,1,1)` / `ground_tile.png`，位置 `(-9,0.6,-8)`）。
成因：扁平 BoxMesh 在远处左侧经低俯角相机斜视，侧面/顶角被冷蓝雾 + 暖金光照着色成深蓝双片楔形（约 `#13285A`），
且 uv 与地面 4 倍平铺尺度不一致，看似孤立尖锐几何而非可辨台面。
修复：先压扁/统一 uv/降低位置，真跑目视发现宽楔形减弱为一条细斜线但未彻底消失；
最终设该节点 **`visible = false`** 彻底移除，2 帧对照确认左侧恢复完整连续砖地。
为兑现 `verify_wave_runtime_v040` 的 `uv_terracehigh_1` 断言与全 PASS 不回退，`uv1_scale` / `size` / transform 恢复原值
（节点已隐藏、不参与渲染、对画面零影响）。**未改任何素材 PNG / 材质文件、未把未定位说成已解决。**

**10.4 15 秒录屏 / MP4 / WAV / 三帧目视**

| 项 | 实测 |
|---|---|
| 录屏 | `--write-movie capture/v050_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`），**EXIT=0 / 450 帧 / 1280×720 / 15.000000s**，`SCRIPT ERROR=0` |
| ffmpeg | 绝对路径 `.../ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`，`-framerate 30 -start_number 0 -i v050_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，**EXIT=0** |
| **MP4** | `capture/v050_demo.mp4` **751,894 B**；ffprobe `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000`，`moov` 前置 |
| **WAV 是否混入 MP4** | **未混入**：ffmpeg 输入仅 PNG 序列、无音频 `-i`，`ffprobe -select_streams a` 音频流计数 = **0**。如实登记 |

`ViewImage` 真看首 0 / 中 225 / 尾 449 三帧（逐帧结论见 `V050-RUNTIME-REVIEW.md` §3）：
三波画面**有区分**（冷蓝 → 深紫浓雾更暗 → 暖紫红雾散更亮）；纵深站位**改善**（玩家近大、Boss 远小、不叠合）；
左侧尖锐形状**消失**（三帧该区均为砖地 RGB ~`(71~77,93~98,129~131)`）；
金色 WaveLabel `第 1/3 波 点数 0` → `第 2/3 波 点数 100` → `第 3/3 波 点数 450`，
成长兑换 HUD / 赐福标题 / 画质面板 / 底部战斗五项三帧全在且可读。
**HD-2D 全绿：未达（如实写未达）** —— 景深/光效仍 2D `draw_*` 近似、三波变化是 2D 色带叠加非真 3D 体积雾、
地面高倍平铺重复、角色仍 `AnimatedSprite3D` billboard、未做人工试玩逐帧动态验收、三采样点动作帧 HUD 仍 `idle 0/0`。

**10.5 三段门禁 / PASS 回归**

G1 `--headless --import` / G2 `--headless --check-only --script res://test/presentation.gd` /
G3 `--headless --quit` 三段 **EXIT=0**；全部 `capture/r27_*.log` 的 `SCRIPT ERROR|Parse Error` 逐份 0、
**`TOTAL_SCRIPT_ERROR=0`**；**`47 / 34 / 20 / 45 / 53 / 58 / 37 PASS` 全部不回退**，另 `verify_frame_data` **650 PASS / 0 FAIL**。
如实登记的额外项：Rank-1 R26B 的 `verify_wave_persist_v040.gd`（不在 R26 回归基线）稳定 `43/1 HAS_FAIL`
（固有 `D6` 缺 `slot`/`quests`；首次 `36/8` 为存档状态/运行次序依赖），
**用 R27 改动前 `courtyard.tscn` 备份对照同样 `43/1`，证明非本轮 Rank-4 改动引入**；本轮未写该脚本/存档系统。

**10.6 目录所有权 / 合规 / 未完成项**

只写 `courtyard.tscn` 视觉属性 / `project.godot` 图标一行 / `icon.png` / `hd2d_parallax.gd` /
`presentation.gd` / `capture/` / `teamwork/Rank-4/`（+ 回执 `command_center/ai/4/outbox/`）；
未写 `hud.gd` / `save_system.gd` / `wave_trial_director.gd` / 素材 PNG / 两份 `SpriteFrames .tres` / 契约 / README；
未自行 git（总指挥收尾）。先目视检查再接入、直接改直接真跑、未新建只读探针/巡检脚本；零付费、零外部依赖、不启 GPU job。
未完成：HD-2D 全绿未达、三波数值 `[PLACEHOLDER]` 待试玩、`128bit` 歧义、人工试玩逐帧动态验收未做、
额外项 `verify_wave_persist_v040` 稳定 `43/1`。**阻塞：无。**

---

## 11. R28 v0.6.0 · Rank-4 真实按键注入录屏 + 点亮态画面 + 景深评估（派单 `cmd-20261111-095602-831-A4`）

> `[ROUND=R28]` · Rank-4 独占追加 · 引擎 4.7.2.stable / ffmpeg 9.0.2（绝对路径）
> 逐项实证见 `capture/V060-RUNTIME-REVIEW.md`、`TECHNICAL-ART-DEPTH-v060.md`、`teamwork/Rank-4/DONE-R28.md`、`capture/r28_*.log`。
> 结论以「跑起来的画面」为准，不粉饰、不谎报。

**11.1 真实输入事件注入（本轮核心，全部经既有输入路由）**

`godot/test/presentation.gd` 新增 `_inject_key()` / `_drive_real_input()`：构造 `InputEventKey`（`physical_keycode` + `keycode`、`pressed+released` 配对），经 **`Input.parse_input_event()`** 注入引擎输入系统，由引擎分发到既有 `_unhandled_input()` 路由；**不写 `Label.text`、不调 `debug_*` 伪造数值、不直接改 HUD**。
`J(74)=light_attack` / `Space(32)=roll` → `EncounterDirector._request_action()` 当帧 `_update_hud()`；`E(69)=interact` → `hud._toggle_shop()` / `encounter._grace_rest()` / `wave.interact_restart()`；`1(49)` → `hud.purchase_upgrade(0)`。
`[PLACEHOLDER] ACTION_INTERVAL=6`（450/6=75 次注入，待试玩校准）；`f=0 J → f=6 Space → f=20 E` 严格按教学三步顺序，`f=170` 购买；E 只注入一次，面板全片保持展开。
**tutorial 接口并发时序（如实）**：开跑最初全工程无 tutorial 文件；执行期间 Rank-1 落盘 `tutorial_director.gd` + `courtyard.tscn` 的 `TutorialHud/TutorialLabel/TutorialDirector` 三节点。故本轮探测到接口**已落盘**（未走「接口缺失降级」），逐帧 `is_tutorial_active()` 监测、`force_complete()` 仅作兜底，**实测未触发**；未谎称接口缺失、也未谎称教学由强制跳过证明。`Input.parse_input_event` 有 **1 帧延迟**（f=6 注入 E → f=7 `shop_open=true`），首帧 0 尚未反映注入，如实登记。

**11.2 教学 → 波次衔接（真实按键三步闭环，非 force_complete 跳过）**

`r28_capture.log`：`[Tutorial] 步骤完成 step=light_attack reward=20 → STEP_ROLL` → `step=roll reward=30 → STEP_GRACE_SHOP` → `step=grace_shop reward=50 → COMPLETED`；`step_events=["light_attack","roll","grace_shop"]`、`total_reward=100`、`wave_started=true`。
教学完成 → `[WaveTrial] 教学完成 → 自动进第 1 波：start_trial()=true（index=1/3）` → `begin_wave_after_tutorial()=true`；随后既有 `_drive_wave_hud` 在 `f=150/300` 推进到 **第 2/3 波 / 第 3/3 波**（`[R26][WAVE]` 三行 + `[R27][GROWTH]` hud_text `第 1/3 → 2/3 → 3/3 波`，历史最佳 0→1→2→3、赐福点数 0→100→250→450）。
`[R28][TUTORIAL] frame=40 教学已由真实按键 J→Space→E 三步完成并自动衔接到第 1 波（force_complete 未触发）`。额外佐证：v060 教学验证 `verify_tutorial_v060` 64 PASS、`verify_tutorial_reward_v060` 86 PASS、`verify_save_isolation_v060` 31 PASS 全 ALL_PASS/ALL_MATCH。

**11.3 15 秒录屏 / MP4 / WAV / 三帧目视**

| 项 | 实测 |
|---|---|
| 录屏 | `--write-movie capture/v060_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`），**EXIT=0 / 450 帧 / 1280×720 / 15.000000s**，`SCRIPT ERROR=0` |
| ffmpeg | 绝对路径 `.../ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe`，`-framerate 30 -start_number 0 -i v060_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，**EXIT=0** |
| **MP4** | `capture/v060_demo.mp4` **897,681 B**；ffprobe `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000`，`moov` 前置 |
| **WAV 是否混入 MP4** | **未混入**：输入仅 PNG 序列、无音频 `-i`，`ffprobe -select_streams a` 音频流计数 = **0**。如实登记 |

`ViewImage` 真看首 0 / 中 225 / 尾 449（+ 面板区裁剪放大 `r28_panel_head/mid/tail.png` + 像素采样，逐帧结论见 `V060-RUNTIME-REVIEW.md §3/§4`）：

- **动作帧 HUD 推进：是（本轮修复 R27 遗留「恒 idle 0/0」）** —— 中帧 `动作 roll 6/22`、尾帧 `动作 roll 8/22`（非 idle），全片 J/Space 真实按键经 `_request_action → _update_hud` 驱动；首帧仍 `idle 0/0`（输入 1 帧延迟，如实）。
- **兑换面板展开：是** —— `shop_open` 从 frame 22 起持续 true 到 449；尾帧 449 清晰可辨 5 行（含「兑换成功：赐福·生命上限（消耗 100，余额 0）」、三项增益、余额），购买真实成功且 `玩家 HP 100/100 → 120/120`（增益运行时生效）。如实登记：首帧为未展开提示态；中帧 225 段 B `low/mobile` 下 `SubViewport` 缩放使面板文字目视不可清晰辨认，不谎称三帧均清晰。
- **赐福标题点亮：是** —— 三帧标题区像素实测最亮 `(212,174,76)` = GOLD、`dim_px=0`；经 `WorldState.set_flag → flag_changed → HUD.refresh_label → apply_lit_state(GOLD)` 既有事件路由，不写 `Label.text`。
- **HD-2D 全绿：未达（如实写未达）** —— 景深/光效仍 2D `draw_*` 近似、三波变化是 2D 色带叠加、地面高倍平铺、角色仍 `AnimatedSprite3D` billboard、段 B 面板不可辨、首帧 idle、未做人工试玩逐帧动态验收、数值 `[PLACEHOLDER]`。

**11.4 景深技术评估（只写文档、未改渲染件）**

新增 `TECHNICAL-ART-DEPTH-v060.md`：`gl_compatibility` 下真 3D 景深 / 体积光 / 湿地倒影 / bloom **当前均不可直接依赖**——`Environment.glow` 历史实测/显式关闭不支持、`volumetric_fog` 属 Compatibility 后端能力缺口、`DoF/SSR` 需 Forward+ 后处理链、SubViewport 分层与切 `forward_plus` 后端代价（帧时间 / 录制确定性 / 输入穿透 / 缩放错位 / 断言回归）大于收益。给零付费替代方案与优先级 P0（定调）→ P1（强化既有 2D `draw_*` 伪景深/光锥/倒影参数）→ P2（一次全屏 `BackBufferCopy` shader，须真跑帧时间）→ P3（切后端/多 SubViewport，不推荐）。**未实现、未谎称实现任何真 3D 光效。**

**11.5 三段门禁 / PASS 回归**

G1 `--headless --import` / G2 `--headless --check-only --script res://test/presentation.gd` / G3 `--headless --quit` 三段 **EXIT=0**；`r28_g1/g2/g3`、`r28_capture`、`r28_ffmpeg` 逐份 `SCRIPT ERROR|Parse Error` = 0、**合计 0 → 字面 `SCRIPT ERROR=0`**。
回归 `47 / 34 / 20 / 45 / 53 / 58 / 650 PASS`（7 项基线合计 **907 PASS 全不回退**）+ 本轮 v060 教学验证 `31 / 86 / 64 PASS`（181 PASS 全 ALL_PASS/ALL_MATCH）；全部 `r28_verify_*.log` `SCRIPT ERROR|Parse Error` 合计 **0**。
**如实登记的 1 项 FAIL（非 Rank-4 引入）**：`verify_wave_runtime_v040` 稳定 `pass=36 fail=1 RESULT=FAILED`（重跑同值），失败断言 `courtyard_node_count PASS=false | node_count=41 expected=38`。根因：Rank-1 本轮并发在 `courtyard.tscn` 新增 `TutorialHud/TutorialLabel/TutorialDirector` 3 节点使 `[node` 数 38→41，脚本硬编码 `NODE_COUNT_AFTER=38` 未同步（R27 基线为 `36/36 PASS`；本轮开跑前已更新为 `38` 且当时 PASS）。Rank-4 本轮只写 `presentation.gd` / `capture/` / 评估文档 / `teamwork/Rank-4/`，**未写场景、未写验证脚本、不改断言不放宽不掩盖**；建议由脚本所有者同步期望值为 41 后复跑。本轮不谎称「全 PASS」。

**11.6 目录所有权 / 合规 / 未完成项**

只写 `godot/test/presentation.gd` / `capture/` / `TECHNICAL-ART-DEPTH-v060.md` / `teamwork/Rank-4/`（+ 回执 `teamwork/command_center/ai/4/outbox/`）；
未写 `courtyard.tscn` / `tutorial_director.gd` / `wave_trial_director.gd` / `hud.gd` / `encounter_director.gd` / 素材 PNG / `.tres` / `project.godot` / 契约 / README / 任何验证脚本；未自行 git（总指挥收尾）。
先目视检查再接入（20/60 帧短验输入生效与教学闭环 → 正式 450 帧 → 三帧 ViewImage + 裁剪 + 像素采样后才写结论）、直接改直接真跑、未新建只读探针/巡检脚本（短跑复用同一脚本，临时 PNG 已清理）；零付费、零外部依赖、不启 GPU job。
未完成：HD-2D 全绿未达、段 B 面板不可辨、首帧 idle、`verify_wave_runtime_v040` 36/1（并发断言过期）、数值 `[PLACEHOLDER]` 待试玩、真 3D 光效仅评估未实现、未自行 git。**阻塞：无。**

---

## 12. R29 v0.7.0 · Rank-4 全屏 shader 小样 + 景深强化 + 点亮态节奏 + 15 秒录屏（派单 `cmd-20261111-112804-021-A4`）

> `[ROUND=R29]` · Rank-4 独占追加 · 引擎 4.7.2.stable / ffmpeg 9.0.2（绝对路径）
> 逐项实证见 `capture/V070-RUNTIME-REVIEW.md`、`TECHNICAL-ART-DEPTH-v060.md`、`teamwork/Rank-4/DONE-R29.md`、`capture/r29_*.log`。
> 结论以「跑起来的画面」为准，不粉饰、不谎报。

**12.1 P2 全屏 shader 小样（A30 判定：Compatibility screen texture 可用，shader 生效，未降级）**

新增 `godot/shaders/v070_depth_grade.gdshader`（`shader_type canvas_item` + `hint_screen_texture` / `SCREEN_UV` 一次全屏采样）：一 pass 实现「多层视差景深（上部远景 4-tap 轻模糊 + 降饱和 + 冷雾）+ 边缘暗角 + 冷夜雾 + 暖金光晕 + 三波收束扩散环」。由 `hd2d_parallax.gd` **运行时** `call_deferred("add_child")` 创建 `CanvasLayer(layer=12)` + `ColorRect` + `ShaderMaterial`；**不写 `courtyard.tscn` 的 `[node` 条目**（磁盘节点数恒 41 → `verify_wave_runtime_v040` / `verify_tutorial_restart_v060` 的 41 断言不回退）。`layer=12` 在 HUD(20/21/40) 之下，不遮 HUD。
生效证据链：三段门禁 + 正式录屏 + 短跑日志**无 shader 编译错误 / `SCREEN_TEXTURE` 报错**；像素 A/B（R28→R29 首帧）边缘点 `-12.0~-39.7`、上部中心 `0.0` 呈径向压暗；参数注入日志 `总命中=20` 且双档切换。**如实口径**：这是「Compatibility 后端一次全屏 screen-reading 后处理真的起作用」，**不是**真 3D 景深 / 体积光 / bloom。`_r29_draw_grade()` 程序化 `_draw()` 降级层已实现但本轮**未启用、未目视验证**（`GRADE_FORCE_DRAW_FALLBACK=false`），如实登记。
`hd2d_fx.gd` 四项光效**零改动**（mtime 仍 2026-11-09），desktop 档不回退、与新层无冲突。

**12.2 读 Rank-2 参数表，不硬编码（并发时序如实）**

开跑时 `depth_profile.tres` 未落盘；执行期间 Rank-2 落盘（mtime 11:39），正式录屏走**真读**路径：`desktop`/`mobile` 双档子 Resource，逐字段映射（顶层容错 + 子档覆盖），`总命中=20`（每档 10）。shader 内 uniform **一律无默认值**，全部 `set_shader_parameter` 注入。
实测：desktop `vignette=0.240 / warm=0.450 / fog=0.175 / deep=0.100 / blur=1.50`，mobile `0.120 / 0.220 / 0.090 / 0.140 / 1.25`；色 `cold_night_fog_color=#2B3A5C`、`warm_gold_key_color=#F0A94C`。双档按 `get_quality_preset()` 切换（日志 `f=173→mobile`、`f=279→desktop`）。派生系数 `×5/×0.4/×25` 与 `vignette_inner/outer`、`warm_glow_pos`、`bloom_threshold` 均标 `[PLACEHOLDER]` 待试玩校准，rationale 见 `hd2d_parallax.gd` 注释。

**12.3 点亮态与三波完成节奏**

赐福标题三帧最亮像素均 `(212,174,76)`=GOLD 点亮态；点亮后暖金层次随波次经 `lerp` 平滑递进（不闪烁），尾帧 `lit=1.00 tier=1.00`。三波完成后**一次**收束光效：`sin(phase·PI)` 单峰 `[PLACEHOLDER] FINALE_DELAY=4.0s / DURATION=2.0s` 使峰值落在尾帧 449，日志 `[R29][FINALE] … 来源=演示节奏兜底(波3 + 4.0s)`（导演 `TRIAL_COMPLETED` 仅佐证，**不冒充游戏事件证明**）。像素：暖金区 `(904,184)` 尾帧 192 vs R28 尾帧 34、R29 `f400=137`/`f430=123` → 收束峰值可见。

**12.4 15 秒录屏 / MP4 / WAV / 三帧目视**

| 项 | 实测 |
|---|---|
| 录屏 | `--write-movie capture/v070_demo.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（不加 `--headless`），**EXIT=0 / 450 帧 / 1280×720 / 15.000000s**，`SCRIPT ERROR=0` |
| ffmpeg | 绝对路径 9.0.2，`-framerate 30 -start_number 0 -i v070_demo%08d.png -frames:v 450 -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，**EXIT=0** |
| **MP4** | `capture/v070_demo.mp4` **935,921 B**；ffprobe `h264 / yuv420p / 1280×720 / 30/1 / nb_frames=450 / duration=15.000000`，`moov` 前置 |
| **WAV 是否混入** | **未混入**：输入仅 PNG 序列、无音频 `-i`，`ffprobe -select_streams a` 音频流计数 = **0**。如实登记 |

`ViewImage` 真看首 0 / 中 225 / 尾 449（+ 像素采样，逐帧结论见 `V070-RUNTIME-REVIEW.md §4/§5`）：

- **景深分层可辨：是** —— 64 色带夜空 + 3 层山影视差 + 远/近雾带 + 地面冷夜压暗 + shader 远景轻模糊/降饱和/冷雾；**仍为 2D 近似，非真 3D 景深**。
- **暗角/光晕改善：是（像素实证）** —— 边缘 `-12~-40`、上部中心 `0`；尾帧暖金区 192（R28 34）。
- **段 B 文字可读：是，本轮改善** —— 中帧 low/mobile 兑换面板 5 行清晰可辨（R28 同段不可辨）；归 **Rank-1 `hud.gd::_ensure_shop_readable()` 迁出 SubViewport**（`[R29][SHOP]`），Rank-4 未写 `hud.gd`、不冒领。
- **首帧动作帧：否，已非 idle 0/0** —— 首帧 `动作 attack_light 1/27`；归 **Rank-1 `presentation.gd` `_initialize` 预热注入 J**（`[R29][INPUT]`），Rank-4 只读该文件、不冒领。
- **点亮态节奏：达标** —— 三帧 GOLD、暖金层次平滑递进、尾帧一次收束、不闪烁不遮 HUD。
- **HD-2D 全绿：未达（如实写未达）** —— 景深/光效仍 2D `draw_*`/全屏后处理近似、地面高倍平铺、billboard 像素精灵、`[PLACEHOLDER]` 待试玩、未做人工试玩逐帧动态验收。

**12.5 三段门禁 / PASS 回归**

G1 `--headless --import` / G2 `--headless --check-only --script res://test/presentation.gd` / G3 `--headless --quit` 三段 **EXIT=0/0/0**，`r29_g1/g2/g3` + `r29_capture` + `r29_ffmpeg` 逐份 `SCRIPT ERROR|Parse Error` = 0 → 字面 `SCRIPT ERROR=0`。
回归 `47 / 34 / 20 / 45 / 53 / 58 / 650 PASS`（7 项基线 **907**）+ v060 教学 `64 / 86 / 31`（**181**）+ `verify_wave_runtime_v040` **37** + `verify_tutorial_restart_v060` **48** → **合计 1173 PASS / 0 FAIL**，与开跑前基线逐项一致、**零回退**；全部 `r29_verify_*.log` `SCRIPT ERROR` = 0。
**并发竞态如实登记**：首次 G1 因 Rank-1 并发改写 `hud.gd` 半写入出现 1 条 `_ensure_shop_readable()` Parse Error，重跑归零；30 帧短跑 `r29_probe.log` 的 `Parent node is busy`（backtrace `hud.gd:795`，Rank-1 件）与 GLES3 `leaked` 退出告警，在正式 450 帧 `r29_capture.log` 中**均未复现**。Rank-4 未写他人件、未等待、未掩盖。

**12.6 目录所有权 / 合规 / 未完成项**

只写 `godot/shaders/v070_depth_grade.gdshader` / `godot/scripts/render/hd2d_parallax.gd` / `godot/scenes/courtyard.tscn` 的**视觉属性 metadata**（新增 1 行、不新增 `[node`） / `capture/` / `teamwork/Rank-4/`（+ 回执 `teamwork/command_center/ai/4/outbox/`）；
未写 `hd2d_fx.gd` / `hud.gd` / `presentation.gd`（Rank-1 只读）/ 导演脚本 / 素材 PNG / SpriteFrames `.tres` / `project.godot` / `depth_profile.tres`（Rank-2 只读）/ 契约 / README / 任何验证脚本；未自行 git（总指挥收尾）。
先目视检查再接入（30 帧短跑 + ViewImage + 像素 A/B 判定 shader 生效 → 正式 450 帧 → 三帧 ViewImage + 像素采样后才写结论）、直接改直接真跑、未新建只读探针/巡检脚本（短跑复用同一脚本、临时 PNG 已清理）；零付费、零外部依赖、不启 GPU job。
未完成：HD-2D 全绿未达、真 3D 光效未实现、降级 `_draw()` 层未启用未目视、`[PLACEHOLDER]` 数值待试玩校准、未做人工试玩逐帧动态验收、未自行 git。**阻塞：无。**

