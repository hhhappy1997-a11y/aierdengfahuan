# hd2d_placeholder.md · 程序化 `_draw()` 占位方案（R5 边界收口 · 可直接落地）

> 轮次：**R5** ｜派单：`cmd-20261109-020321-549-A4`（`调度任务单-latest.json`）｜工位：Rank-4（美术管线与工具链）
> 唯一可写 `Rank-4\`；唯一例外 `command_center\ai\4\outbox\` 回执。中文 UTF-8。
> 本轮定位：**单一后台 `qwen-image --quant nf4` 出图 job 未完成、ComfyUI 本机路径/工作流 JSON 未登记** → 四项受阻塞（alpha/128px/≤256 色收敛、装饰层逐像素对齐无源图可做），只有「程序化 `_draw()` 占位兜底」不依赖外部源图，故本文件把它写成可直接落地的方案。

---

## 0. 结论速览与边界（先读这里）

| 项 | 本轮结论 |
|---|---|
| 本文件是什么 | 无出图时的**零外部依赖占位兜底方案**：单个 Godot `Node2D._draw()` 画出「多层视差 + 体积光 + 光尘 + 湿地倒影 + bloom + 金线深蓝 UI」完整 HD-2D 画面，供 M0 验证构图/景深/冷暖对比 |
| 本文件不是什么 | **不是**正式渲染实现、**不是**美术资产、**不是**已出图结论、**不产 `.gd`/`.tscn`/shader**（契约 §9.3 / `README.md` §1：4 号交付件为 JSON + Markdown，落地实现归 1 号） |
| 零外部依赖 | ✅ 不依赖任何 PNG / ComfyUI / 插件 / 云服务 / 付费 API；只用 Godot 4 内置 `_draw()` 原语 + 冻结参数 |
| 与冻结件关系 | **引用、不重做**：参数与顺序对齐 `HD-2D视觉规范.md` §3/§4/§7 与 `hd2d_placeholder_params.json`（R2，18 键）。本文件是「落地说明」，`hd2d_placeholder_r5_params.json` 是「R5 落地参数补充」，三者互不覆盖 |
| 路线优先级 | **ComfyUI 仍是主美术路线**；`qwen-image` 仅为本地零付费备选；程序化 `_draw()` **仅作 M0 占位与显存不足降级，不取代二者**（契约 §9.3 / §5） |
| 是否宣称已能出图 | ❌ 否。本方案的存在恰恰是因为**无源图**，不伪造任何 PNG / 校验数据 |

---

## 1. 落地总结构（1 号照此接入）

```text
Main（Node2D / Control）
└── HD2DPlaceholder（Node2D，挂本方案的 _draw 逻辑）
     ├── 输入：cam_x / cam_y（相机像素位移）、Time.get_ticks_msec()（动画时钟）
     ├── 画布：先渲染到 640×360 缓冲（SubViewport / 低分辨率 Viewport），
     │          再整数倍 2x/3x/4x Nearest 放大到屏幕（1 逻辑像素 = 1 缓冲像素）
     ├── 每帧：queue_redraw() → _draw() 按 §2 的 10 步顺序重画
     └── 开关：placeholder_enabled（bool），退出条件见 §7
```

- 单个节点、单次 `_draw()` 内按序调用，不建场景树分支、不建多节点层、不加载贴图。
- 所有实体坐标 `round()` 到整数；**禁止亚像素位移 / 非整数缩放 / 任意角度旋转**（仅水平翻转）。
- 背景层用连续色带/多边形 → 平滑；实体层用 `1×1` 矩形块 → 硬像素。二者同画布即 HD-2D「像素精灵 vs 平滑景深」对比。

---

## 2. 绘制分层顺序（10 步，一次 `_draw()` 内按序调用）

对齐 `HD-2D视觉规范.md` §7.1 与 `hd2d_placeholder_params.json::depth.draw_pass_count=10`（9 个视差层 + 1 步湿地倒影，倒影属 `bg_3_near` 内效果、不单独计层）。

```json
{
  "draw_pass_count": 10,
  "passes": [
    { "step": 1,  "layer": "bg_0_sky",   "primitive": "draw_rect x64",        "content": "天空横向色带渐变 + 黄金树辉光晕" },
    { "step": 2,  "layer": "bg_1_far",   "primitive": "draw_colored_polygon",  "content": "远山/黄金树剪影 + 低 alpha 冷雾矩形" },
    { "step": 3,  "layer": "bg_2_mid",   "primitive": "draw_colored_polygon",  "content": "中景崖体/林地 + 上缘 1px 受光亮边" },
    { "step": 4,  "layer": "bg_3_near",  "primitive": "draw_rect",             "content": "地平线以下地面带 + 湿地 mask 标记" },
    { "step": 5,  "layer": "fx_0_back",  "primitive": "draw_colored_polygon", "content": "体积光扇形 + 远景冷白光尘" },
    { "step": 6,  "layer": "reflection", "primitive": "draw_rect",            "content": "实体剪影垂直镜像（湿地倒影），挂在 bg_3_near 湿地区" },
    { "step": 7,  "layer": "entity",     "primitive": "draw_rect x1024",     "content": "32x32 像素人形色板索引阵列，锚点 (16,31)" },
    { "step": 8,  "layer": "fx_1_front", "primitive": "draw_circle",          "content": "近景暖金光尘 + 同心圆模拟 bloom" },
    { "step": 9,  "layer": "fg_0_occl",  "primitive": "draw_colored_polygon",  "content": "前景草丛/柱剪影，压暗制造纵深" },
    { "step": 10, "layer": "ui",         "primitive": "draw_rect",            "content": "金线深蓝底板 + 1px 金线描边 + 角饰" }
  ]
}
```

---

## 3. 多层视差（重点一）

### 3.1 变换公式（每层绘制前套用）

```text
# 伪代码，非交付 .gd（本工位不产 .gd，落地由 1 号写）
for layer in layers:
    ox = round(-cam_x * layer.parallax)                                   # 水平视差，取整
    oy = round(-cam_y * layer.parallax * 0.3) if layer.id in ("bg_0_sky", "bg_1_far") else 0
    draw_set_transform(Vector2(ox, oy), 0.0, Vector2.ONE)                  # 只平移，不缩放不旋转
    draw_layer(layer)
draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)                         # UI 层前复位（ui 系数 0，屏幕固定）
```

- `parallax` 常量表写死（下表），不随区域增减层数；`ui` 系数 0 = 屏幕固定不跟随相机。
- 背景层 `draw_colored_polygon` 顶点同样要 `round()`，避免边缘亚像素抖动。

### 3.2 视差系数与色温（对齐 §3）

| 层 ID | parallax | 绘制序 | 色温/饱和 | 模糊半径(640×360) | Alpha |
|---|---|---|---|---|---|
| `bg_0_sky` | 0.05 | 0 | 冷雾偏色、饱和 -40% | 0（连续渐变） | 1.0 |
| `bg_1_far` | 0.15 | 1 | 冷调 `#2B3A5C`、饱和 -55% | 2.0 | 1.0 |
| `bg_2_mid` | 0.35 | 2 | 冷调、饱和 -30% | 1.0 | 1.0 |
| `bg_3_near` | 0.70 | 3 | 中性、饱和 -10% | 0 | 1.0 |
| `fx_0_back` | 0.45 | 4 | 暖金、Add 混合 | 1.5 | 0.25~0.45 |
| `entity` | 1.00 | 5 | 原色板、Nearest、无模糊 | 0 | 1.0 |
| `fx_1_front` | 1.00 | 6 | 暖金为主、Add 混合 | 0 | 0.30~0.80 |
| `fg_0_occl` | 1.25 | 7 | 压暗至 L1~L2、饱和 -60% | 1.0 | 0.85~1.0 |
| `ui` | 0.00 | 8 | 原色板 | 0 | 1.0 |

> 硬约束：只有 `entity` 层允许像素硬边；`bg_*` 层禁止像素块感；`entity` 与背景之间必须保留至少 1 个半透明 `fx` 层做空气透视（HD-2D 景深感关键，不许省）。

---

## 4. 四类重点效果的 `_draw()` 原语与参数（重点二~四 + bloom）

### 4.1 体积光 God Rays（`fx_0_back`）

```text
# 伪代码，非交付 .gd
light_screen_pos = 光源在 640×360 缓冲上的屏幕坐标（固定常量或由 1 号传入）
for i in range(godray_layers):                          # 4 层
    a = godray_alpha[i]                                  # [0.18, 0.12, 0.07, 0.04]
    # 以 light_screen_pos 为顶点、向下扩散的扇形：左右边界随 i 外扩
    poly = [light_screen_pos, 左下顶点(i), 右下顶点(i)]
    draw_colored_polygon(poly, Color("#FFD27A", a))     # Add 叠加近似径向光束衰减
```

- 参数：`samples=48`（32~64）、`density=0.75`（0.6~0.9）、`decay=0.95`、`weight=0.40`（0.3~0.5）、`exposure=0.32`（0.25~0.4）、色 `#FFD27A`。
- 判据：只在暖金主光方向出现；冷雾区不得出现金色光束；不得盖住角色剪影。

### 4.2 光尘 Motes（`fx_0_back` 远景 / `fx_1_front` 近景）

```text
# 伪代码，非交付 .gd；固定 seed 生成确定性分布，便于复现截图对比
rng = RandomNumberGenerator.new(); rng.seed = placeholder_seed   # 20261108
for mote in motes:
    y = (mote.y0 - speed * t) % buffer_height                    # 上飘 2~6 px/s，越界回卷
    x = mote.x0 + sin(t * freq + mote.phase) * sway_px            # 正弦横摆 ±3 px / 2~4 s
    draw_circle(Vector2(round(x), round(y)), size_px, layer_color) # 半径 1，Add 叠加
```

- 参数：远 `count_far=48`（40~120）、近 `count_near=32`（40~120）、`size_px=[1,3]`、`lifetime_s=[4,8]`、`speed_px_s=[2,6]`、`sway_px=3`、`sway_period_s=[2,4]`、`blend=Add`。
- 色：远景 `#BFD0EA` alpha `0.25`；近景 `#FFD27A` alpha `0.45`。
- 判据：不得密集到遮挡判定信息；不得用线性过滤放大。

### 4.3 湿地倒影（`reflection`，挂在 `bg_3_near` 湿地区）

```text
# 伪代码，非交付 .gd；对 entity 每个像素块做垂直镜像
for block in entity_blocks:                            # block: (px, py, w, h, color)
    y_mirror = 2 * ground_y - py - h                     # 脚底 Y 对齐的垂直镜像
    y_ref = ground_y + (y_mirror - ground_y) * reflection_squash   # 高度压缩 0.70
    ripple_dx = sin(t + y_ref) * ripple * buffer_width  # 逐行横向错位模拟水波
    draw_rect(Rect2(round(px + ripple_dx), round(y_ref), w, h),
              Color(block.color, reflection_alpha))      # alpha 0.35
```

- 参数：`reflection_alpha=0.35`（0.25~0.45）、`vertical_squash=0.70`（0.6~0.8）、`ripple=0.03`（0.02~0.06）、`dry_ground=false`。
- 判据：倒影与角色脚底对齐、降采样到与主体**同一像素网格**，禁止半像素错位；干地无倒影。

### 4.4 Bloom / Glow（`fx_1_front`，同心圆近似）

```text
# 伪代码，非交付 .gd
for i in range(bloom_radii.size()):                      # [4, 8, 14, 22, 32]
    draw_circle(light_screen_pos, bloom_radii[i],
                Color("#FFD27A", bloom_alpha[i]))       # [0.20, 0.12, 0.07, 0.04, 0.02]
```

- 参数：`threshold=0.95`（0.85~1.05）、`intensity=0.50`（0.35~0.7）、`radius=6`（4~8），`only_warm_gold_over_threshold=true`。
- 判据：只让暖金高光过阈；冷夜雾保持不发亮，否则冷暖对比失效。

### 4.5 像素实体 / UI（补齐完整画面）

- 实体：32×32 二维色板索引数组逐格 `draw_rect(Rect2(px, py, 1, 1), palette[idx])`，锚点 `(16,31)`、1px 轮廓 `#0B1226`、≤16 色/角色；所有坐标 `round()`。
- UI：底板 `Color("#0E1B33", 0.92)`，四边 1px `#E8C479` `draw_rect` 描线，角饰 8×8 小方块，`panel_margin_px=8`；文本用点阵方块示意。

### 4.6 四效核心参数（结构化，供真跑解析引用）

```json
{
  "canvas": { "buffer_width": 640, "buffer_height": 360, "integer_scale": 3, "scale_allowed": [2, 3, 4], "filter": "Nearest" },
  "parallax": [
    { "id": "bg_0_sky", "coefficient": 0.05 }, { "id": "bg_1_far", "coefficient": 0.15 },
    { "id": "bg_2_mid", "coefficient": 0.35 }, { "id": "bg_3_near", "coefficient": 0.70 },
    { "id": "fx_0_back", "coefficient": 0.45 }, { "id": "entity", "coefficient": 1.00 },
    { "id": "fx_1_front", "coefficient": 1.00 }, { "id": "fg_0_occl", "coefficient": 1.25 },
    { "id": "ui", "coefficient": 0.00 }
  ],
  "volumetric_light": { "enabled": true, "layer": "fx_0_back", "samples": 48, "density": 0.75, "decay": 0.95, "weight": 0.40, "exposure": 0.32, "color_hex": "#FFD27A", "godray_layers": 4, "godray_alpha": [0.18, 0.12, 0.07, 0.04] },
  "light_motes": { "enabled": true, "count_far": 48, "count_near": 32, "size_px": [1, 3], "lifetime_s": [4, 8], "speed_px_s": [2, 6], "sway_px": 3, "sway_period_s": [2, 4], "blend": "Add", "far_color_hex": "#BFD0EA", "far_alpha": 0.25, "near_color_hex": "#FFD27A", "near_alpha": 0.45 },
  "wet_reflection": { "enabled": true, "layer": "bg_3_near", "alpha": 0.35, "vertical_squash": 0.70, "ripple": 0.03, "align": "脚底 Y 对齐，降采样到与主体同一像素网格，禁止半像素错位", "dry_ground": false },
  "bloom": { "enabled": true, "only_warm_gold_over_threshold": true, "threshold": 0.95, "intensity": 0.50, "radius": 6, "placeholder_radii": [4, 8, 14, 22, 32], "placeholder_alpha": [0.20, 0.12, 0.07, 0.04, 0.02], "color_hex": "#FFD27A" },
  "entity": { "grid": [32, 32], "anchor": [16, 31], "outline_hex": "#0B1226", "max_colors_per_character": 16 },
  "ui": { "border_px": 1, "panel_margin_px": 8, "panel_hex": "#0E1B33", "gold_line_hex": "#E8C479" },
  "sky_bands": 64,
  "placeholder_seed": 20261108
}
```

---

## 5. 动画驱动与像素网格（零外部依赖的关键）

```text
# 伪代码，非交付 .gd
func _process(_delta):
    queue_redraw()                       # 每帧请求重画

func _draw():
    var t = Time.get_ticks_msec() / 1000.0
    # 光尘 y 位移 / 横摆、倒影 ripple、bloom 呼吸 都由 t 驱动，不读任何贴图/网络
    draw_all_passes(t)
```

- 时钟只取 `Time.get_ticks_msec()`（Godot 内置），不依赖外部计时/资源。
- 整帧先渲染到 640×360 缓冲，再整数倍 Nearest 放大（禁止非整数倍缩放，否则像素抖动判不合格）。
- `placeholder_seed=20261108` 保证光尘分布确定性，便于截图对比与复现。

---

## 6. R5 落地自检判据（可被程序真跑核对）

```json
{
  "round": "R5",
  "task_id": "cmd-20261109-020321-549-A4",
  "checks": [
    { "id": "zero_external_dependency", "expect": true, "note": "不依赖 PNG/ComfyUI/插件/云服务/付费 API" },
    { "id": "draw_pass_count", "expect": 10, "note": "9 视差层 + 1 步湿地倒影" },
    { "id": "parallax_layer_count", "expect": 9, "note": "ui 系数 0 屏幕固定" },
    { "id": "four_effects_present", "expect": ["parallax", "light_motes", "wet_reflection", "volumetric_light"], "note": "本轮点名的四类效果全部有 _draw 原语与参数" },
    { "id": "integer_round_only", "expect": true, "note": "实体坐标 round() 到整数，禁止亚像素/非整数缩放" },
    { "id": "produces_gd_or_tscn", "expect": false, "note": "本工位交付 JSON + Markdown，落地实现归 1 号" },
    { "id": "comfyui_is_primary_route", "expect": true, "note": "占位不取代 ComfyUI 主路线" },
    { "id": "qwen_image_is_local_fallback_only", "expect": true, "note": "qwen-image 仅本地零付费备选" },
    { "id": "claims_image_generation_ready", "expect": false, "note": "不宣称已能出图、不伪造 PNG" }
  ]
}
```

参数与顺序均可在 1 号接入前用脚本核对：把 §2 / §4.6 / §6 三处 JSON 与 `hd2d_placeholder_params.json`、`HD-2D视觉规范.md` §7.4 逐字段比对，不一致即为漂移，须回到冻结件。

---

## 7. 边界与退出条件

- **是**：M0 视觉构图验证、景深层数/系数验证、暖金 × 冷夜雾对比验证、UI 可读性验证、无美术依赖时的可玩画面。
- **不是**：正式渲染实现、性能优化依据、最终美术验收依据、已出图证明。
- **退出条件**：当 `assets/generated/bg_layers/` 与 `assets/generated/chars/` 有首批合规 spritesheet 且 1 号完成纹理层接入后，逐层把占位绘制替换为 `draw_texture_rect()` 或 Sprite2D/3D 场景节点；`placeholder_enabled` 保留为调试开关，不再作为默认画面。
- **本轮（R5）状态**：出图 job 未完成、无 PNG、ComfyUI 路径未登记 → 本方案作为**兜底**交付，不回头改写出图/收敛/对齐记录；后续轮次若产物到位，由 HOST 决定是否收敛。

---

## 8. 合规声明

- 只写 `Rank-4\`（本文件、`hd2d_placeholder_r5_params.json`、`DONE-R5.md`）；唯一例外 `command_center\ai\4\outbox\` 回执 JSON。未写群聊总线、未写其它工位 / 工程根 / 总纲 / 契约 / 任务书、未自行 `git commit`/`git push`。
- 零付费 / 零外部依赖：付费 API 一律禁用，不列云服务、不列花费确认项；`stable-audio`/`gen3d`/`mia-rig` 不申请、不补装、不碰 WSL、不绕过。
- **ComfyUI 仍是主美术路线**；`qwen-image` 仅为同为零付费的本地备选；程序化 `_draw()` 仅 M0 占位/降级，不取代二者。
- `image/quantize.py` 是 DiT 权重量化器，**未**用作 256 色调色板量化器（本方案不涉量化）。
- 默认不刺探：仅只读检查 `Rank-4\*.png` 与两份日志（本轮明确要求的验收动作），未启动第二个 GPU job、未杀/未重启现有 job、未扫别人工位、未写探针/测量/preflight 脚本。
- 既有冻结件（`HD-2D视觉规范.md`、`hd2d_placeholder_params.json`、`美术管线.md`、`ASSET-PROOF.md` 等）一律**引用、不重做、一个字节未改**。
- 中文 UTF-8；本文件内嵌 3 个 `json` 代码块均合法可解析（见 `DONE-R5.md` 自检）。
- **不宣称已能出图、不伪造输出**：这是本轮最重要的一条。
