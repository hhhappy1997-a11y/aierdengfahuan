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
