extends CanvasLayer
## R31 [ROUND=R31] · 打击反馈层（Impact Feedback）+ HUD 避让
## 派单：cmd-20261111-133549-878-A1 · 工位 Rank-1 · v0.9.0
##
## 职责：命中瞬间三类反馈，全部程序化、零外部素材、零付费、不启 GPU job：
##   ① 暖金闪光 —— 由本层内部的 FlashPainter(Node2D) 用 _draw()/draw_rect 程序化绘制，
##      不是原生后处理 / 不是外部贴图 / 不是 GPU job；
##   ② 短促屏幕微震 —— 以 CanvasLayer.offset 真实位移，幅度受 SHAKE_MAX_AMPLITUDE 上限，
##      确定性三角函数振荡（不用 rand，保证 headless 断言可复现）；
##   ③ hitstop 请求 —— 只登记「请求帧数」(get_snapshot/request_hitstop)，不暂停引擎帧循环，
##      帧数受 HITSTOP_MAX_FRAMES 上限；由集成层按需消费，不干扰 --script 门禁帧推进。
##
## 为什么内部要挂 FlashPainter：CanvasLayer 继承 Node，不是 CanvasItem，本身没有 _draw() /
##   draw_rect()。故本脚本 extends CanvasLayer 满足「反馈层是 CanvasLayer」的挂载要求，
##   同时在 _ready() 运行时 add_child 一个内部类 FlashPainter(Node2D) 承担程序化 _draw()。
##   两者都不写 courtyard.tscn（挂载由 hud.gd 运行时 add_child 完成）。
##
## 既有战斗信号「按实接入」（读 godot/scripts/combat/encounter_director.gd 既有声明）：
##   - :25  signal encounter_finished(won: bool)
##   - :26  signal grace_rested(rest_count: int)
##   - :337 _bind_boss() 里 boss.connect("move_landed", Callable(self,"_on_boss_move_landed"))
##          → BossController 既有信号 move_landed(3 参) 代表一次招式落地 / 受击。
##   本层 bind_director() 只 connect 上述真实存在的信号名，connect 前用
##   get_signal_connection_list(sig) 按方法名去重（同一信号不重复 connect → 不重复触发）。
## R31B [ROUND=R31B] / HOST 裁决 A39 集成补接线：真实导演层已在 _try_player_hit()
##   玩家成功命中处新增 signal player_hit_landed(damage: int) + 一处 emit（只新增这一信号
##   与 emit，不改既有数值 / 判定分支 / 帧数据 / 输出格式 / 其它信号；move_landed 订阅链不变）。
##   本层新增 SIG_PLAYER_HIT_LANDED 常量并在 bind_director() 订阅该信号，命中时经统一回调
##   _on_combat_signal() 自动调用 request_impact() —— 暖金闪光 / 微震 / hitstop 在真实游玩中
##   自动触发，不再只靠集成层在命中帧手动调用 request_impact(intensity)。
##   request_impact(intensity) 公共入口保留供降级 / 验证 / 外部编排使用（不删不放宽）。
##
## 降级开关（低画质 / 移动端只保留闪光）：set_low_quality(true) 后 request_impact() /
##   request_hitstop() 只产生闪光，微震幅度与 hitstop 帧数恒为 0，已有值立即归零。
##
## HUD 避让（严格不遮文字）：_avoid_rects 由 7 个 HUD 文字 / 面板矩形各 grow(AVOID_MARGIN)
##   得到（屏幕 1280x720 坐标，沿用 verify_codex_v080.gd 既有避让口径）；_flash_rects 用
##   扫描线矩形分解，只保留与任何避让矩形【交集面积 == 0】的安全单元，_draw() 只画这些
##   单元 → 避让区像素贡献恒为 0（flash 峰值态亦然）。AVOID_MARGIN(8) > 微震上限(6)，
##   故微震 ≤6px 平移时闪光边缘也不会侵入 HUD 文字区。面板打开时 set_panel_open() 再
##   追加一层强化避让矩形，Tab 图鉴 / 兑换面板展开期间同样不遮文字。
##
## --script / SceneTree 纪律：不用 get_tree()、不用 /root/... 绝对路径；add_child 不会
##   自动 flush _ready()，验证脚本须显式 call("_ready") 后再 set_process(false)，
##   全部状态推进经公共 advance_frame() 显式驱动，确定性、不依赖帧循环。
## 全静态类型标注 · 中文 UTF-8 · Godot 4.7.2。

# ==========================================================================
# 既有战斗信号名（按实接入，不臆造；来源行号见文件头）
# ==========================================================================
const SIG_ENCOUNTER_FINISHED: String = "encounter_finished"   # encounter_director.gd:25
const SIG_GRACE_RESTED: String = "grace_rested"                 # encounter_director.gd:26
const SIG_MOVE_LANDED: String = "move_landed"                   # encounter_director.gd:337（BossController）
## R31B/A39：导演层 _try_player_hit() 玩家成功命中处 emit 的既有信号名（按实接入，不臆造）。
const SIG_PLAYER_HIT_LANDED: String = "player_hit_landed"
const ON_COMBAT_METHOD: String = "_on_combat_signal"            # 统一回调方法名（去重键）

# ==========================================================================
# [PLACEHOLDER] 视觉 / 时序数值（全部待试玩校准，逐条写 rationale）
# ==========================================================================
## 暖金闪光峰值 alpha：0.42 < 0.5，HD-2D 强对比下可感但不过曝、不盖住像素角色轮廓。
const FLASH_PEAK_ALPHA: float = 0.42
## 每帧线性衰减量：0.42/0.06 = 7 帧（60fps≈117ms）归零，短促、不留残影；线性保证衰减单调。
const FLASH_DECAY_PER_FRAME: float = 0.06
## 暖金色：与 hud.gd GOLD(0.83,0.68,0.3) 同系略提亮，作「命中瞬间」高光而非 UI 文字色。
const FLASH_GOLD: Color = Color(0.98, 0.80, 0.34, 1.0)
## 屏幕微震幅度上限 6px：1280x720 下可感不眩晕，且严格小于 AVOID_MARGIN(8)，
## 保证微震平移时闪光边缘仍不侵入 HUD 文字区。
const SHAKE_MAX_AMPLITUDE: float = 6.0
## 每帧衰减 1.2px：6/1.2 = 5 帧（≈83ms）归零，与闪光同量级的短促感。
const SHAKE_DECAY_PER_FRAME: float = 1.2
## 确定性振荡相位步进：避免 rand 导致 headless 断言不可复现；1.7 rad/帧 ≈ 每 4 帧一周。
const SHAKE_FREQ: float = 1.7
## hitstop 请求帧数上限 4：60fps 下 ≤67ms，不破坏操作手感；请求一律 clampi 到该上限。
const HITSTOP_MAX_FRAMES: int = 4
## 常规命中请求 2 帧（≤上限）：短促「顿帧」感，留给装配层消费。
const HITSTOP_REQUEST_FRAMES: int = 2
## 避让矩形外扩 8px：> SHAKE_MAX_AMPLITUDE(6)，留 2px 安全余量；避开 HUD 文字边缘抗锯齿。
const AVOID_MARGIN: float = 8.0
## 层号 12：高于 FXLayer/HD2DFX(10)、低于 QualitySettings(40) 与 HUD 文字层(20/21/45/46)，
## 即使几何有微缝，层级也在 HUD 文字之下，双保险不遮文字。
const LAYER_INDEX: int = 12
const PAINTER_NAME: String = "ImpactFlashPainter"

# ==========================================================================
# 屏幕与 HUD 文字 / 面板避让矩形（层局部 == 屏幕坐标；沿用既有真跑避让口径）
# [PLACEHOLDER] 矩形为目视布局值，待试玩校准（rationale：与 verify_codex_v080.gd
#   G 组 / hud.gd SHOP_RECT_* / courtyard.tscn Label offset 对齐，保证断言与实际同口径）
# ==========================================================================
const SCREEN: Rect2 = Rect2(0.0, 0.0, 1280.0, 720.0)
const RECT_TITLE: Rect2 = Rect2(0.0, 0.0, 730.0, 220.0)       # 左上标题 / 赐福 HUD
const RECT_QUALITY: Rect2 = Rect2(760.0, 0.0, 520.0, 180.0)    # 画质面板
const RECT_WAVE: Rect2 = Rect2(24.0, 232.0, 696.0, 32.0)       # 波次 HUD
const RECT_TUTORIAL: Rect2 = Rect2(24.0, 520.0, 1076.0, 36.0)  # 教学 HUD
const RECT_SHOP: Rect2 = Rect2(740.0, 358.0, 536.0, 210.0)     # 右下兑换面板
const RECT_BOTTOM: Rect2 = Rect2(24.0, 660.0, 1200.0, 32.0)    # 底部战斗 HUD
const RECT_CODEX: Rect2 = Rect2(24.0, 272.0, 356.0, 236.0)     # Tab 图鉴面板

# ==========================================================================
# 内部绘制节点：CanvasLayer 无 _draw()，由 Node2D 承担程序化暖金闪光
# ==========================================================================
class FlashPainter extends Node2D:
	var host: Node = null
	var flash_color: Color = Color.WHITE

	func _draw() -> void:
		if host == null or not is_instance_valid(host):
			return
		var a: float = float(host.call("get_flash_alpha"))
		if a <= 0.0:
			return
		var rects: Array = host.call("get_flash_rects")
		var c: Color = Color(flash_color.r, flash_color.g, flash_color.b, a)
		for i: int in range(rects.size()):
			var r: Rect2 = rects[i]
			draw_rect(r, c)


# ==========================================================================
# 运行期状态
# ==========================================================================
var _painter: FlashPainter = null
var _flash_alpha: float = 0.0
var _shake_amplitude: float = 0.0
var _shake_phase: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
var _hitstop_frames: int = 0
var _impact_count: int = 0
var _low_quality: bool = false
var _avoid_rects: Array[Rect2] = []
var _flash_rects: Array[Rect2] = []
var _bound_sources: Array[Object] = []
var _panel_open: Dictionary = {}


# ==========================================================================
# 生命周期
# ==========================================================================
func _ready() -> void:
	layer = LAYER_INDEX
	_rebuild_avoid_rects()
	_rebuild_flash_rects()
	_painter = FlashPainter.new()
	_painter.name = PAINTER_NAME
	_painter.host = self
	_painter.flash_color = FLASH_GOLD
	add_child(_painter)
	set_process(true)


func _process(delta: float) -> void:
	advance_frame(delta)


func _exit_tree() -> void:
	# 生命周期铁律：信号连接必须有释放路径，卸载后不留悬空 Callable。
	for src in _bound_sources:
		if not is_instance_valid(src):
			continue
		var o: Object = src
		for sig: String in [SIG_ENCOUNTER_FINISHED, SIG_GRACE_RESTED, SIG_MOVE_LANDED, SIG_PLAYER_HIT_LANDED]:
			if o.has_signal(sig):
				var cb: Callable = Callable(self, ON_COMBAT_METHOD)
				if o.is_connected(sig, cb):
					o.disconnect(sig, cb)
	_bound_sources.clear()


# ==========================================================================
# 公共接口（集成层 / 验证脚本）
# ==========================================================================

## 按实接入既有战斗信号（不改 encounter_director.gd）。connect 前按方法名去重。
func bind_director(director: Node) -> void:
	if director == null or not is_instance_valid(director):
		return
	_dedup_connect(director, SIG_ENCOUNTER_FINISHED, ON_COMBAT_METHOD)
	_dedup_connect(director, SIG_GRACE_RESTED, ON_COMBAT_METHOD)
	_dedup_connect(director, SIG_MOVE_LANDED, ON_COMBAT_METHOD)
	# R31B/A39：真实导演层玩家命中信号 → 命中瞬间自动 request_impact()（去重 connect）。
	_dedup_connect(director, SIG_PLAYER_HIT_LANDED, ON_COMBAT_METHOD)
	# BossController.move_landed 在 encounter_director.gd:337 由 _bind_boss 既有连接；
	# 真实场景里 Boss 是导演层的子节点，按实接入同一信号名。
	var boss: Node = director.get_node_or_null(^"Boss")
	if boss != null:
		_dedup_connect(boss, SIG_MOVE_LANDED, ON_COMBAT_METHOD)


## 通用信号绑定（供扩展 / 验证）：同样按方法名去重，信号不存在则安全跳过。
func bind_signal_source(source: Object, signal_name: String) -> void:
	_dedup_connect(source, signal_name, ON_COMBAT_METHOD)


## 「命中瞬间」显式触发入口：既有导演层未声明命中信号且不改既有件，由集成层在命中帧调用。
## intensity ∈ [0,1]，0 视为空触发（不自发光）。
func request_impact(intensity: float = 1.0) -> void:
	var k: float = clampf(intensity, 0.0, 1.0)
	if k <= 0.0:
		return
	_impact_count += 1
	_flash_alpha = FLASH_PEAK_ALPHA * k
	if _low_quality:
		_shake_amplitude = 0.0
		_hitstop_frames = 0
	else:
		_shake_amplitude = SHAKE_MAX_AMPLITUDE * k
		_hitstop_frames = clampi(HITSTOP_REQUEST_FRAMES, 0, HITSTOP_MAX_FRAMES)
	_shake_phase = 0.0
	_shake_offset = Vector2(cos(_shake_phase), sin(_shake_phase)) * _shake_amplitude
	offset = _shake_offset
	_queue_redraw()


## hitstop 请求：帧数一律 clamp 到 [0, HITSTOP_MAX_FRAMES]，降级时恒 0；返回实际生效帧数。
func request_hitstop(frames: int) -> int:
	if _low_quality:
		_hitstop_frames = 0
		return 0
	_hitstop_frames = clampi(frames, 0, HITSTOP_MAX_FRAMES)
	return _hitstop_frames


## 降级开关：低画质 / 移动端只保留闪光，微震与 hitstop 立即归零。
func set_low_quality(enabled: bool) -> void:
	_low_quality = enabled
	if enabled:
		_shake_amplitude = 0.0
		_shake_offset = Vector2.ZERO
		offset = Vector2.ZERO
		_hitstop_frames = 0
	_queue_redraw()


## 面板开闭联动：Tab 图鉴 / 兑换面板打开时追加一层强化避让矩形，保证不遮文字。
func set_panel_open(panel_name: String, open: bool) -> void:
	_panel_open[panel_name] = open
	_rebuild_avoid_rects()
	_rebuild_flash_rects()
	_queue_redraw()


## 显式推进一帧（验证与真机 _process 共用同一路径，保证确定性）。
func advance_frame(_delta: float = 1.0 / 60.0) -> void:
	_flash_alpha = maxf(0.0, _flash_alpha - FLASH_DECAY_PER_FRAME)
	_shake_amplitude = maxf(0.0, _shake_amplitude - SHAKE_DECAY_PER_FRAME)
	if _low_quality:
		_shake_amplitude = 0.0
	_shake_phase += SHAKE_FREQ
	_shake_offset = Vector2(cos(_shake_phase), sin(_shake_phase)) * _shake_amplitude
	offset = _shake_offset
	if _hitstop_frames > 0:
		_hitstop_frames -= 1
	_queue_redraw()


## 采样某屏幕点的闪光 alpha：严格按 _draw() 实际绘制的安全矩形判定，
## 落在任一 HUD 避让区 / 屏幕外恒返回 0.0 → 「HUD 避让区像素 0」可 headless 断言。
func sample_flash(x: float, y: float) -> float:
	if _flash_alpha <= 0.0:
		return 0.0
	var p: Vector2 = Vector2(x, y)
	if not SCREEN.has_point(p):
		return 0.0
	for r in _flash_rects:
		if r.has_point(p):
			return _flash_alpha
	return 0.0


## 只读状态快照（供 hud.gd / 验证脚本回读，不伪造数值）。
func get_snapshot() -> Dictionary:
	return {
		"flash_alpha": _flash_alpha,
		"shake_amplitude": _shake_amplitude,
		"shake_offset": _shake_offset,
		"hitstop_frames": _hitstop_frames,
		"impact_count": _impact_count,
		"low_quality": _low_quality,
		"flash_rects": _flash_rects.duplicate(),
		"avoid_rects": _avoid_rects.duplicate(),
		"layer": layer,
		"panel_open": _panel_open.duplicate(),
		# 上限值运行期回读（供验证脚本断言「不超上限」，不硬编码第二份数值）
		"flash_peak_alpha": FLASH_PEAK_ALPHA,
		"shake_max_amplitude": SHAKE_MAX_AMPLITUDE,
		"hitstop_max_frames": HITSTOP_MAX_FRAMES,
		"avoid_margin": AVOID_MARGIN,
	}


func get_flash_alpha() -> float:
	return _flash_alpha


func get_flash_rects() -> Array[Rect2]:
	return _flash_rects


func get_avoid_rects() -> Array[Rect2]:
	return _avoid_rects


func get_impact_count() -> int:
	return _impact_count


# ==========================================================================
# 私有实现
# ==========================================================================

## connect 前用 get_signal_connection_list(sig) 按方法名去重：同一信号上若已有
## 指向 self 且方法名相同的连接，直接返回 false，绝不重复 connect → 不重复触发。
func _dedup_connect(source: Object, sig: String, method: String) -> bool:
	if source == null or not source.has_signal(sig):
		return false
	for conn in source.get_signal_connection_list(sig):
		var cb: Callable = conn.get("callable", Callable())
		if cb.get_object() == self and String(cb.get_method()) == method:
			return false
	var callable: Callable = Callable(self, method)
	source.connect(sig, callable)
	if not _bound_sources.has(source):
		_bound_sources.append(source)
	return true


func _on_combat_signal(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	request_impact(1.0)


func _rebuild_avoid_rects() -> void:
	_avoid_rects.clear()
	var base: Array[Rect2] = [
		RECT_TITLE, RECT_QUALITY, RECT_WAVE, RECT_TUTORIAL,
		RECT_SHOP, RECT_BOTTOM, RECT_CODEX,
	]
	for r in base:
		_avoid_rects.append(r.grow(AVOID_MARGIN))
	# 面板打开时追加强化避让（基础已常驻避让，这里再加一圈缓冲，开闭均不遮文字）。
	if bool(_panel_open.get("shop", false)):
		_avoid_rects.append(RECT_SHOP.grow(AVOID_MARGIN * 2.0))
	if bool(_panel_open.get("codex", false)):
		_avoid_rects.append(RECT_CODEX.grow(AVOID_MARGIN * 2.0))


## 扫描线矩形分解：用所有避让矩形的 x/y 边界把屏幕切成网格单元，
## 只保留与任何避让矩形交集面积为 0 的安全单元 → _draw() 只画这些单元。
func _rebuild_flash_rects() -> void:
	_flash_rects.clear()
	var xs: Array = [SCREEN.position.x, SCREEN.end.x]
	var ys: Array = [SCREEN.position.y, SCREEN.end.y]
	for r in _avoid_rects:
		var c: Rect2 = r.intersection(SCREEN)
		if c.get_area() <= 0.0:
			continue
		xs.append(c.position.x)
		xs.append(c.end.x)
		ys.append(c.position.y)
		ys.append(c.end.y)
	var ux: Array[float] = _sorted_unique(xs, SCREEN.position.x, SCREEN.end.x)
	var uy: Array[float] = _sorted_unique(ys, SCREEN.position.y, SCREEN.end.y)
	for i: int in range(ux.size() - 1):
		for j: int in range(uy.size() - 1):
			var cell: Rect2 = Rect2(ux[i], uy[j], ux[i + 1] - ux[i], uy[j + 1] - uy[j])
			if cell.get_area() <= 0.0:
				continue
			var blocked: bool = false
			for r in _avoid_rects:
				if cell.intersection(r).get_area() > 0.0:
					blocked = true
					break
			if not blocked:
				_flash_rects.append(cell)


func _sorted_unique(input: Array, lo: float, hi: float) -> Array[float]:
	var s: Array = input.duplicate()
	s.sort()
	var out: Array[float] = []
	for v in s:
		var f: float = clampf(float(v), lo, hi)
		if out.is_empty() or absf(f - out[out.size() - 1]) > 0.01:
			out.append(f)
	return out


func _queue_redraw() -> void:
	if _painter != null and is_instance_valid(_painter):
		_painter.queue_redraw()
