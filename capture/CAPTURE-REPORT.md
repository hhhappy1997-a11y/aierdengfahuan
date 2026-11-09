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
