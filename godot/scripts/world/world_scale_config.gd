class_name WorldScaleConfig
extends Resource
## R38 / v0.15.0「大地图 · 2.5D 尺度重构」· 世界尺度唯一配置（Rank-1 唯一写入）
## 派单 cmd-20261112-234238-645-A1 · [ROUND=R38] · AI=1
##
## 【调参唯一入口】所有大地图尺寸 / 相机 / 缩放 / 视差 / 雾数值只在本脚本对应的
##   res://data/render/world_scale.tres 修改（只改表不改代码）；本脚本内的默认值均为
##   [PLACEHOLDER] 非法占位基线（is_valid() 必为 false），不是设计值。
##   big_map_runtime.gd / character_scale.gd / hud.gd / verify_bigmap_v150.gd 一律
##   从该 .tres 读取，绝不硬编码 1.6 / 0.64 / 4096 / 2304 / zoom 等数值。
##
## 【美术规格不变】128px 基准画布、单帧 ≤16 色索引、项目级 ≥256 色色库、RGBA 保 alpha、
##   硬边无渐变无噪点；本轮只调 2D 尺度 / 层次，不改素材 / 色库 / 渲染后端。
## 【不切后端 / 不引入真 3D 网格】大地图为新增 Node2D 分区层 + CanvasItem/_draw()
##   体系（仍 gl_compatibility）；既有 Node3D/SubViewport 3D 战斗场景原样保留，
##   v0.1~v0.14 三波试炼 / 赐福 / 图鉴 / 弹反 / 战技 / 元素瓶 / 死亡轮回入口仍可达。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 / 零外部依赖 / 零 GPU job。

# ── 地图逻辑尺寸（[PLACEHOLDER] 待试玩校准）────────────────────────────
## rationale：用户「换画面路线，大地图+2.5d」需远大于既有单屏 1280×720；
##   4096×2304 ≈ 3.2× 单屏宽 / 3.2× 单屏高、16:9 与单屏同比例，便于 Camera2D
##   limit 边界与 zoom 视野换算。改尺寸 → 只改 .tres 的 map_logic_size。
@export var map_logic_size: Vector2 = Vector2.ZERO
## 既有单屏逻辑基准（对比 / 视野换算用，非设计值）：
##   rationale：courtyard.tscn SubViewport.size=640×360、显示基准 1280×720；
##   V150 断言 map_logic_size 必须显著大于它。
@export var viewport_logic_size: Vector2 = Vector2.ZERO

# ── 人物显示尺寸 40%（硬指标）─────────────────────────────────────────
## 既有角色 scale 基线（改前 courtyard.tscn 两个 PixelSprite transform = 1.6）：
##   rationale：R38 总指挥按「人物显示尺寸缩到现在的 40%」理解（不是人物数量）；
##   baseline 只作历史基线登记，不再作为运行时缩放值。
@export var character_scale_baseline: float = 0.0
## 缩放比例（硬指标 0.40）：rationale：用户需求「人物是只有现在的 40%」。
@export var character_scale_ratio: float = 0.0
## 运行时角色缩放 = baseline × ratio = 1.6 × 0.40 = 0.64（计算式，非独立拍值）：
##   rationale：写进 .tres 并注明基线值与计算式（任务③硬要求）；角色渲染脚本
##   character_scale.gd 只从本字段读，绝不硬编码 1.6 / 0.64。
@export var character_scale: float = 0.0
## 角色单帧像素尺寸（128px 基准画布下 32×48 单帧，I-5 import.json 口径）：
##   rationale：供「画面像素高度对比」换算 pixel_height = frame.y / ppm × scale。
@export var character_frame_size: Vector2 = Vector2.ZERO
@export var pixels_per_meter: float = 0.0

# ── Camera2D（[PLACEHOLDER] 待试玩校准）───────────────────────────────
## zoom < 1 使可见世界视野显著扩大（可见 = viewport / zoom）：
##   rationale：0.5 → 可见 2560×1440 逻辑像素（比单屏 1280×720 扩大 2×），
##   配合 4096×2304 地图仍有可探索余量；改视野只改 .tres 的 camera_zoom。
@export var camera_zoom: Vector2 = Vector2.ZERO
## 相机边界（limit_left/right/top/bottom），与 map_logic_size 对齐：
##   rationale：Camera2D 随玩家位移但视口边缘不得越出地图；四值单列便于
##   V150 静态回读与 BigMapRuntime 运行时 clamp（数据驱动，脚本不写 4096/2304）。
@export var camera_limit_left: float = -1.0
@export var camera_limit_top: float = -1.0
@export var camera_limit_right: float = -1.0
@export var camera_limit_bottom: float = -1.0

# ── 多层视差 / 2.5D 层次（[PLACEHOLDER] 待试玩校准）───────────────────
## 视差层数（远景色带 / 中景地形与地标 / 地面 tile 大范围平铺 / 前景遮挡层 = 4）：
##   rationale：任务①要求「至少 3 层」，4 层覆盖远景→中景→地面→前景遮挡。
@export var parallax_layer_count: int = 0
## 各层视差系数（远小近大，与层数一一对应）：
##   rationale：层世界位移 = 相机位移 × 系数；系数越小随相机移动越少（更远）。
##   首版沿用既有 hd2d_parallax.gd / depth_profile.tres 0.06/0.14/0.26 分层概念，
##   前景遮挡层取 0.42（最大），形成 4 级互不相同系数。
@export var parallax_coefficients: PackedFloat32Array = PackedFloat32Array()
## 按层深度雾密度（远浓近淡，与层数一一对应）：
##   rationale：Compatibility 后端不做真体积光 / Environment.glow，用纯 2D
##   CanvasItem.modulate 叠色近似按层深度雾（硬边无噪点、零 GPU job）。
@export var fog_density_by_layer: PackedFloat32Array = PackedFloat32Array()
@export var y_sort_enabled: bool = false
## 前景遮挡层 z_index（大于其它层 → 遮挡角色 / 地标）：
@export var foreground_z_index: int = 0
## 玩家移动速度（逻辑像素/秒，[PLACEHOLDER]）：
##   rationale：450 帧 @30fps 演示里可横穿相当一段大地图，证明可探索。
@export var player_move_speed: float = 0.0
## 一次真实按键脉冲等效帧时长（秒，[PLACEHOLDER]）：
##   rationale：演示用 press+release 同帧配对注入，脉冲步进保证「点按即走一步」；
##   持续按住则由 _process 按 speed×delta 推进，二者都由本表驱动。
@export var input_pulse_delta: float = 0.0

# ── 派生量（供 V150 / BigMapRuntime / CharacterScaleApplier 断言，不写死数值）──

## 角色缩放计算式：character_scale == baseline × ratio（V150 断言用）。
func computed_character_scale() -> float:
	return character_scale_baseline * character_scale_ratio

## 角色画面像素高度（米）：frame.y × (1/pixels_per_meter) × scale。
func character_pixel_height(scale_value: float) -> float:
	if pixels_per_meter <= 0.0:
		return 0.0
	return character_frame_size.y / pixels_per_meter * scale_value

## 相机可见世界尺寸（视野显著扩大判据）。
func camera_visible_size() -> Vector2:
	if camera_zoom.x <= 0.0 or camera_zoom.y <= 0.0:
		return Vector2.ZERO
	return Vector2(viewport_logic_size.x / camera_zoom.x, viewport_logic_size.y / camera_zoom.y)

## [PLACEHOLDER] 非法占位基线自检：.tres 填设计值后 is_valid() 必须为 true。
func is_valid() -> bool:
	if map_logic_size.x <= 0.0 or map_logic_size.y <= 0.0:
		return false
	if viewport_logic_size.x <= 0.0 or viewport_logic_size.y <= 0.0:
		return false
	if map_logic_size.x <= viewport_logic_size.x or map_logic_size.y <= viewport_logic_size.y:
		return false
	if character_scale_baseline <= 0.0 or character_scale_ratio <= 0.0 or character_scale <= 0.0:
		return false
	if not is_equal_approx(character_scale, computed_character_scale()):
		return false
	if character_frame_size.x <= 0.0 or character_frame_size.y <= 0.0 or pixels_per_meter <= 0.0:
		return false
	if camera_zoom.x <= 0.0 or camera_zoom.y <= 0.0 or camera_zoom.x >= 1.0 or camera_zoom.y >= 1.0:
		return false
	if camera_limit_right <= camera_limit_left or camera_limit_bottom <= camera_limit_top:
		return false
	if not is_equal_approx(camera_limit_right - camera_limit_left, map_logic_size.x) \
			or not is_equal_approx(camera_limit_bottom - camera_limit_top, map_logic_size.y):
		return false
	if parallax_layer_count < 3:
		return false
	if parallax_coefficients.size() != parallax_layer_count \
			or fog_density_by_layer.size() != parallax_layer_count:
		return false
	for c: float in parallax_coefficients:
		if c <= 0.0 or c >= 1.0:
			return false
	for i: int in range(1, parallax_coefficients.size()):
		if parallax_coefficients[i] <= parallax_coefficients[i - 1]:
			return false
	for i: int in range(1, fog_density_by_layer.size()):
		if fog_density_by_layer[i] >= fog_density_by_layer[i - 1]:
			return false
	if foreground_z_index <= 0 or not y_sort_enabled:
		return false
	if player_move_speed <= 0.0 or input_pulse_delta <= 0.0:
		return false
	return true
