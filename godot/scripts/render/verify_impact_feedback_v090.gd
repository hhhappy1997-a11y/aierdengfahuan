extends SceneTree
## ===========================================================================
## R31 [ROUND=R31] · 打击反馈层 v0.9.0 自测（Rank-1，cmd-20261111-133549-878-A1）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/render/verify_impact_feedback_v090.gd
##
## 断言组（任务单 ③ 七条 + 接线 / 契约回读）：
##   A 按实接入既有信号名（读 encounter_director.gd 脚本信号列表，不臆造）
##   B 无信号不自发光
##   C 闪光衰减单调（触发后 12 帧单调不增、恒 ≥0、归零不回升）
##   D 微震幅度不超上限（amplitude / offset.length 恒 ≤ SHAKE_MAX_AMPLITUDE）
##   E hitstop 帧数不超上限（999 → 上限、-5 → 0、逐帧递减到 0）
##   F 降级开关生效（low 只保留闪光：shake=0 / hitstop=0 / flash>0；关闭后恢复）
##   G HUD 避让区像素 0（flash 峰值态：几何交集 0、采样 0、安全区 >0、三关键矩形被覆盖）
##   H 重复 connect 不重复触发（bind 两次仍 1 条连接、emit 一次仅 1 次 impact）
##   I 面板打开不遮挡（shop / codex 打开后矩形内像素仍 0）
##   J A38 不破坏（courtyard.tscn [node]==41 / uv 2/1/1 / 无反馈层静态节点）
##   K hud.gd 运行时挂载接线（常量 / add_child / bind_director / 降级 / 面板同步）
##   L R31B 集成（A39：真实导演层 player_hit_landed emit → 反馈层自动触发；
##     连续命中不叠加异常 / 降级下 shake·hitstop=0 但仍闪光 / HUD 避让区像素仍 0）
##
## --script / SceneTree 纪律：
##   - 不用 get_tree()、不用 /root/... 绝对路径；只用 root.add_child(host) 相对装配；
##   - add_child 不自动 flush _ready()：每个反馈层夹具显式 call("_ready") 后
##     set_process(false)，全部状态推进经公共 advance_frame() 显式驱动（确定性）；
##   - 资源回读用 ResourceLoader.load(..., CACHE_MODE_IGNORE)；场景/脚本文本回读用
##     FileAccess.get_file_as_string（同 verify_codex_v080.gd H1/H2 口径）。
##   - FakeDirector / FakeBoss 是 add_user_signal 构造的轻量替身：只为确定性 emit 信号，
##     不加载 BossController / 不改既有战斗件；真实信号名由 A 组从脚本列表读回证明。
## 输出：逐条 PASS/FAIL + SUMMARY 计数 + RESULT=ALL_MATCH（全通过）/ MISMATCH（有失败）。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。
##
## R35C [ROUND=R35C] / HOST 裁决 A64 回归：既有 A~L 共 42 条断言逐字未动、不删不放宽；
##   新增 M 组（闪光绘制包围盒不再覆盖中景大矩形 / 远锚点像素 0 / 局部网格围绕锚点）
##   与 N 组（HUD 避让区像素仍为 0 / 收敛后几何避让仍 0）两类运行时断言，并输出
##   改前（全屏安全网格）/ 改后（局部 flash_rects）覆盖面积实证。
##   SUMMARY total 由 42 → 47；全通过仍输出 RESULT=ALL_MATCH。
## ===========================================================================

const FEEDBACK_PATH: String = "res://scripts/render/impact_feedback.gd"
const ENCOUNTER_PATH: String = "res://scripts/combat/encounter_director.gd"
const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"
const HUD_PATH: String = "res://scripts/hud.gd"

# 关键 HUD 文字 / 面板矩形（屏幕 1280x720；与 hud.gd SHOP_RECT_* /
# verify_codex_v080.gd G 组 / courtyard.tscn Label offset 同口径）
const SCREEN: Rect2 = Rect2(0.0, 0.0, 1280.0, 720.0)
const RECT_TITLE: Rect2 = Rect2(0.0, 0.0, 730.0, 220.0)
const RECT_SHOP: Rect2 = Rect2(740.0, 358.0, 536.0, 210.0)
const RECT_CODEX: Rect2 = Rect2(24.0, 272.0, 356.0, 236.0)
const NODE_COUNT_EXPECTED: int = 41
## R35C/A64：中景半透明大矩形（R35B 精确定位 x≈388..1280 / y≈188..720）作为
##   「不再被闪光覆盖」的对照矩形；M 组断言收敛后 bbox 不覆盖它、其远锚点像素为 0。
const MID_RECT: Rect2 = Rect2(388.0, 188.0, 892.0, 532.0)


## 既有信号替身：只声明 encounter_director.gd 里真实存在的两个 signal，
## 供确定性 emit；不加载 / 不修改任何既有战斗件。
class FakeDirector extends Node:
	func _init() -> void:
		add_user_signal("encounter_finished", [{"name": "won", "type": TYPE_BOOL}])
		add_user_signal("grace_rested", [{"name": "rest_count", "type": TYPE_INT}])


## Boss 替身：move_landed 是 encounter_director.gd:337 _bind_boss 既有连接的信号名；
## 这里用无参 user signal 作最小替身（回调全默认参数可接），只为测去重 / 触发。
class FakeBoss extends Node:
	func _init() -> void:
		add_user_signal("move_landed")


## R31B/A39 真实导演层命中替身：只声明 encounter_director.gd:29 真实存在的
## player_hit_landed(damage:int) 信号（同名同参），供确定性 emit 验证「真实导演层
## emit → 反馈层自动 request_impact()」闭环；不加载 / 不修改任何既有战斗件。
class RealHitDirector extends Node:
	func _init() -> void:
		add_user_signal("player_hit_landed", [{"name": "damage", "type": TYPE_INT}])

	func land_hit(damage: int) -> void:
		emit_signal("player_hit_landed", damage)


var _pass: int = 0
var _fail: int = 0
var _temps: Array[Node] = []
var _fb_script: Script = null


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V090] %s PASS=%s | %s" % [tag, str(ok), detail])


func _track(n: Node) -> void:
	_temps.append(n)


## 每个夹具挂独立 host：反馈层 CanvasLayer 及其内部 FlashPainter 一并挂在 host 下，
## free(host) 可整体释放，root 下无残留 / 无重名冲突。
func _new_feedback() -> Node:
	var host: Node = Node.new()
	host.name = "ImpactTestHost"
	_track(host)
	root.add_child(host)
	var fb: Node = _fb_script.new() as Node
	_track(fb)
	host.add_child(fb)
	if not fb.is_node_ready():
		fb.call("_ready")
	fb.set_process(false)   # 关掉 _process，全部由 advance_frame() 显式推进，确定性
	return fb


func _new_director() -> Node:
	var d: Node = FakeDirector.new()
	_track(d)
	root.add_child(d)
	var boss: Node = FakeBoss.new()
	boss.name = "Boss"
	_track(boss)
	d.add_child(boss)
	return d


func _snap(fb: Node) -> Dictionary:
	return fb.call("get_snapshot") as Dictionary


func _count_substr(s: String, what: String) -> int:
	if what.is_empty():
		return 0
	return s.split(what).size() - 1


func _avoid_covers(avoid: Array, r: Rect2) -> bool:
	for a in avoid:
		var aa: Rect2 = a
		if aa.encloses(r):
			return true
	return false


## 对一组矩形取中心 + 四角内缩 5 点采样，返回其中最大 sample_flash 值。
func _max_pixel(fb: Node, rects: Array) -> float:
	var worst: float = 0.0
	for a in rects:
		var aa: Rect2 = a
		var pts: Array[Vector2] = [
			aa.position + aa.size * 0.5,
			aa.position + Vector2(4.0, 4.0),
			Vector2(aa.end.x - 4.0, aa.position.y + 4.0),
			Vector2(aa.position.x + 4.0, aa.end.y - 4.0),
			aa.end - Vector2(4.0, 4.0),
		]
		for p in pts:
			worst = maxf(worst, float(fb.call("sample_flash", p.x, p.y)))
	return worst


## R35C/A64 改前对照：按 R31 原「全屏扫描线安全网格」算法重算覆盖面积
##   （纯几何计算，不改生产代码、不新建探针脚本），用于改前/改后覆盖面积实证。
func _fullscreen_safe_area(avoid: Array) -> float:
	var xs: Array = [SCREEN.position.x, SCREEN.end.x]
	var ys: Array = [SCREEN.position.y, SCREEN.end.y]
	for a in avoid:
		var rr: Rect2 = a
		var c: Rect2 = rr.intersection(SCREEN)
		if c.get_area() <= 0.0:
			continue
		xs.append(c.position.x)
		xs.append(c.end.x)
		ys.append(c.position.y)
		ys.append(c.end.y)
	var ux: Array = xs.duplicate()
	ux.sort()
	var uy: Array = ys.duplicate()
	uy.sort()
	var uxu: Array[float] = []
	for v in ux:
		var f: float = clampf(float(v), SCREEN.position.x, SCREEN.end.x)
		if uxu.is_empty() or absf(f - uxu[uxu.size() - 1]) > 0.01:
			uxu.append(f)
	var uyu: Array[float] = []
	for v in uy:
		var f2: float = clampf(float(v), SCREEN.position.y, SCREEN.end.y)
		if uyu.is_empty() or absf(f2 - uyu[uyu.size() - 1]) > 0.01:
			uyu.append(f2)
	var total: float = 0.0
	for i: int in range(uxu.size() - 1):
		for j: int in range(uyu.size() - 1):
			var cell: Rect2 = Rect2(uxu[i], uyu[j], uxu[i + 1] - uxu[i], uyu[j + 1] - uyu[j])
			if cell.get_area() <= 0.0:
				continue
			var blocked: bool = false
			for a in avoid:
				var rr2: Rect2 = a
				if cell.intersection(rr2).get_area() > 0.0:
					blocked = true
					break
			if not blocked:
				total += cell.get_area()
	return total


## 求一组矩形的合并包围盒（纯 min/max，不依赖 Rect2.merge）。
func _union_bbox(rects: Array) -> Rect2:
	if rects.is_empty():
		return Rect2()
	var minx: float = SCREEN.end.x
	var miny: float = SCREEN.end.y
	var maxx: float = SCREEN.position.x
	var maxy: float = SCREEN.position.y
	for a in rects:
		var rr: Rect2 = a
		minx = minf(minx, rr.position.x)
		miny = minf(miny, rr.position.y)
		maxx = maxf(maxx, rr.end.x)
		maxy = maxf(maxy, rr.end.y)
	return Rect2(minx, miny, maxx - minx, maxy - miny)


func _initialize() -> void:
	print("[V090] ==== verify_impact_feedback_v090 真跑开始 | cmd-20261111-133549-878-A1 [ROUND=R31] Rank-1 ====")
	_fb_script = ResourceLoader.load(
			FEEDBACK_PATH, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if _fb_script == null:
		print("[V090] RESULT=MISMATCH（impact_feedback.gd 加载失败）")
		quit(1)
		return
	print("[V090] LOAD feedback class=%s resource_path=%s CACHE_MODE_IGNORE=true" % [
			_fb_script.get_class(), _fb_script.resource_path])
	_test_signal_names()
	_test_no_self_emit()
	_test_flash_decay()
	_test_shake_cap()
	_test_hitstop_cap()
	_test_degrade()
	_test_hud_avoid()
	_test_dedup_connect()
	_test_panel_open()
	_test_a38()
	_test_hud_wiring()
	_test_r31b_director_hit()
	_test_r35c_local_flash()
	_test_r35c_hud_avoid_pixels()
	_finish()


# ---------------------------------------------------------------------------
# A) 按实接入既有信号名（读 encounter_director.gd 脚本信号列表）
# ---------------------------------------------------------------------------
func _test_signal_names() -> void:
	var enc: Script = ResourceLoader.load(
			ENCOUNTER_PATH, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
	var names: Array[String] = []
	if enc != null:
		for s in enc.get_script_signal_list():
			names.append(String(s.get("name", "")))
	_ck("A1 encounter_director.gd 既有信号含 encounter_finished / grace_rested",
			names.has("encounter_finished") and names.has("grace_rested"),
			"script_signals=%s" % str(names))
	var fb: Node = _new_feedback()
	var snap: Dictionary = _snap(fb)
	# 反馈层常量名以 get_script_constant_map() 回读（不硬编码第二份信号名）
	var cmap: Dictionary = _fb_script.get_script_constant_map()
	_ck("A2 反馈层信号常量与既有信号名逐字一致（按实接入、不臆造）",
			String(cmap.get("SIG_ENCOUNTER_FINISHED", "")) == "encounter_finished" \
					and String(cmap.get("SIG_GRACE_RESTED", "")) == "grace_rested" \
					and String(cmap.get("SIG_MOVE_LANDED", "")) == "move_landed",
			"constants=[%s,%s,%s]" % [
					str(cmap.get("SIG_ENCOUNTER_FINISHED", "")),
					str(cmap.get("SIG_GRACE_RESTED", "")),
					str(cmap.get("SIG_MOVE_LANDED", ""))])
	_ck("A3 反馈层为 CanvasLayer 且 layer 低于 HUD 文字层（双保险不遮文字）",
			fb is CanvasLayer and int(snap.get("layer", -1)) < 20,
			"class=%s layer=%s" % [fb.get_class(), str(snap.get("layer", "?"))])


# ---------------------------------------------------------------------------
# B) 无信号不自发光
# ---------------------------------------------------------------------------
func _test_no_self_emit() -> void:
	var fb: Node = _new_feedback()
	var s0: Dictionary = _snap(fb)
	var ok0: bool = float(s0.get("flash_alpha", -1.0)) == 0.0 \
			and float(s0.get("shake_amplitude", -1.0)) == 0.0 \
			and int(s0.get("hitstop_frames", -1)) == 0 \
			and int(s0.get("impact_count", -1)) == 0
	_ck("B1 新建 + _ready 后 flash/shake/hitstop/impact 全 0", ok0,
			"flash=%s shake=%s hitstop=%s impact=%s" % [
					str(s0.get("flash_alpha", "?")), str(s0.get("shake_amplitude", "?")),
					str(s0.get("hitstop_frames", "?")), str(s0.get("impact_count", "?"))])
	for _i: int in range(6):
		fb.call("advance_frame")
	var s1: Dictionary = _snap(fb)
	var ok1: bool = float(s1.get("flash_alpha", -1.0)) == 0.0 \
			and float(s1.get("shake_amplitude", -1.0)) == 0.0 \
			and int(s1.get("hitstop_frames", -1)) == 0 \
			and int(s1.get("impact_count", -1)) == 0
	_ck("B2 无信号推进 6 帧仍全 0（不自发光）", ok1,
			"flash=%s shake=%s hitstop=%s impact=%s" % [
					str(s1.get("flash_alpha", "?")), str(s1.get("shake_amplitude", "?")),
					str(s1.get("hitstop_frames", "?")), str(s1.get("impact_count", "?"))])


# ---------------------------------------------------------------------------
# C) 闪光衰减单调
# ---------------------------------------------------------------------------
func _test_flash_decay() -> void:
	var fb: Node = _new_feedback()
	var peak_cap: float = float(_snap(fb).get("flash_peak_alpha", 0.42))
	fb.call("request_impact", 1.0)
	var peak: float = float(fb.call("get_flash_alpha"))
	_ck("C1 触发后 flash_alpha == 峰值且 ≤ 上限",
			absf(peak - peak_cap) < 0.0001 and peak <= peak_cap + 0.0001 and peak > 0.0,
			"peak=%.4f cap=%.4f" % [peak, peak_cap])
	var prev: float = peak
	var mono: bool = true
	var seq: Array[float] = [prev]
	for _i: int in range(12):
		fb.call("advance_frame")
		var a: float = float(fb.call("get_flash_alpha"))
		seq.append(a)
		if a > prev + 0.0001 or a < 0.0:
			mono = false
		prev = a
	_ck("C2 连续 12 帧衰减单调不增且恒 ≥ 0", mono, "seq=%s" % str(seq))
	_ck("C3 衰减到 0 后保持 0、不回升",
			float(fb.call("get_flash_alpha")) == 0.0,
			"final=%.4f" % float(fb.call("get_flash_alpha")))


# ---------------------------------------------------------------------------
# D) 微震幅度不超上限
# ---------------------------------------------------------------------------
func _test_shake_cap() -> void:
	var fb: Node = _new_feedback()
	var cap: float = float(_snap(fb).get("shake_max_amplitude", 6.0))
	var ok: bool = true
	var worst_amp: float = 0.0
	var worst_len: float = 0.0
	for _cycle: int in range(3):
		fb.call("request_impact", 1.0)
		for _i: int in range(8):
			var s: Dictionary = _snap(fb)
			var amp: float = float(s.get("shake_amplitude", 0.0))
			var off: Vector2 = s.get("shake_offset", Vector2.ZERO)
			worst_amp = maxf(worst_amp, amp)
			worst_len = maxf(worst_len, off.length())
			if amp > cap + 0.0001 or amp < 0.0 or off.length() > cap + 0.0001:
				ok = false
			fb.call("advance_frame")
	_ck("D1 3 轮触发 × 8 帧：amplitude / offset.length 恒 ≤ SHAKE_MAX_AMPLITUDE",
			ok, "cap=%.2f worst_amp=%.4f worst_offset_len=%.4f" % [cap, worst_amp, worst_len])


# ---------------------------------------------------------------------------
# E) hitstop 帧数不超上限
# ---------------------------------------------------------------------------
func _test_hitstop_cap() -> void:
	var fb: Node = _new_feedback()
	var cap: int = int(_snap(fb).get("hitstop_max_frames", 4))
	var r1: int = int(fb.call("request_hitstop", 999))
	var r2: int = int(fb.call("request_hitstop", -5))
	_ck("E1 request_hitstop(999) == 上限（clamp）", r1 == cap,
			"actual=%d cap=%d" % [r1, cap])
	_ck("E2 request_hitstop(-5) == 0（下限 clamp）", r2 == 0, "actual=%d" % r2)
	fb.call("request_hitstop", 999)
	var ok: bool = true
	var seq: Array[int] = []
	for _i: int in range(6):
		var f: int = int(_snap(fb).get("hitstop_frames", -1))
		seq.append(f)
		if f > cap or f < 0:
			ok = false
		fb.call("advance_frame")
	var last: int = int(_snap(fb).get("hitstop_frames", -1))
	_ck("E3 hitstop 帧数恒 ≤ 上限且逐帧递减到 0", ok and last == 0,
			"seq=%s last=%d cap=%d" % [str(seq), last, cap])


# ---------------------------------------------------------------------------
# F) 降级开关生效（低画质 / 移动端只保留闪光）
# ---------------------------------------------------------------------------
func _test_degrade() -> void:
	var fb: Node = _new_feedback()
	fb.call("set_low_quality", true)
	fb.call("request_impact", 1.0)
	var s: Dictionary = _snap(fb)
	_ck("F1 降级后闪光仍生效（flash_alpha > 0）",
			float(s.get("flash_alpha", 0.0)) > 0.0,
			"flash=%s" % str(s.get("flash_alpha", "?")))
	_ck("F2 降级后 shake=0 / offset=ZERO / hitstop=0（只保留闪光）",
			float(s.get("shake_amplitude", -1.0)) == 0.0 \
					and (s.get("shake_offset", Vector2.ONE) as Vector2) == Vector2.ZERO \
					and int(s.get("hitstop_frames", -1)) == 0 \
					and bool(s.get("low_quality", false)),
			"shake=%s offset=%s hitstop=%s low=%s" % [
					str(s.get("shake_amplitude", "?")), str(s.get("shake_offset", "?")),
					str(s.get("hitstop_frames", "?")), str(s.get("low_quality", "?"))])
	var rh: int = int(fb.call("request_hitstop", 999))
	_ck("F3 降级后 request_hitstop(999) == 0", rh == 0, "actual=%d" % rh)
	fb.call("set_low_quality", false)
	fb.call("request_impact", 1.0)
	var s2: Dictionary = _snap(fb)
	_ck("F4 关闭降级后微震 / hitstop 恢复（> 0）",
			float(s2.get("shake_amplitude", 0.0)) > 0.0 \
					and int(s2.get("hitstop_frames", 0)) > 0 \
					and not bool(s2.get("low_quality", true)),
			"shake=%s hitstop=%s low=%s" % [
					str(s2.get("shake_amplitude", "?")),
					str(s2.get("hitstop_frames", "?")), str(s2.get("low_quality", "?"))])


# ---------------------------------------------------------------------------
# G) HUD 避让区像素 0
# ---------------------------------------------------------------------------
func _test_hud_avoid() -> void:
	var fb: Node = _new_feedback()
	fb.call("request_impact", 1.0)   # 峰值态下断言，最强条件
	var avoid: Array = fb.call("get_avoid_rects") as Array
	var rects: Array = fb.call("get_flash_rects") as Array
	_ck("G1 flash_rects 非空（程序化 _draw 有可画安全区）", rects.size() > 0,
			"flash_rects=%d avoid_rects=%d" % [rects.size(), avoid.size()])
	var worst_area: float = 0.0
	for r in rects:
		var rr: Rect2 = r
		for a in avoid:
			var aa: Rect2 = a
			worst_area = maxf(worst_area, rr.intersection(aa).get_area())
	_ck("G2 每个 flash_rect 与每个 avoid_rect 几何交集面积恒 == 0",
			worst_area == 0.0, "worst_overlap=%.4f px²" % worst_area)
	var pix: float = _max_pixel(fb, avoid)
	_ck("G3 HUD 避让区所有采样点 flash 像素 == 0（峰值态）",
			pix == 0.0, "max_pixel=%.4f" % pix)
	_ck("G4 避让集覆盖左上标题 / 右下兑换 / Tab 图鉴三个关键矩形",
			_avoid_covers(avoid, RECT_TITLE) and _avoid_covers(avoid, RECT_SHOP) \
					and _avoid_covers(avoid, RECT_CODEX),
			"title=%s shop=%s codex=%s" % [
					str(_avoid_covers(avoid, RECT_TITLE)),
					str(_avoid_covers(avoid, RECT_SHOP)),
					str(_avoid_covers(avoid, RECT_CODEX))])
	var safe: float = float(fb.call("sample_flash", 640.0, 400.0))
	_ck("G5 安全区（角色区 640,400）flash 像素 > 0（闪光确实可见）",
			safe > 0.0, "sample=%.4f" % safe)
	var outside: float = float(fb.call("sample_flash", -10.0, 400.0))
	_ck("G6 屏幕外采样 flash 像素 == 0", outside == 0.0, "sample=%.4f" % outside)


# ---------------------------------------------------------------------------
# H) 重复 connect 不重复触发
# ---------------------------------------------------------------------------
func _test_dedup_connect() -> void:
	var fb: Node = _new_feedback()
	var d: Node = _new_director()
	fb.call("bind_director", d)
	fb.call("bind_director", d)   # 重复绑定
	var c1: int = d.get_signal_connection_list("encounter_finished").size()
	var c2: int = d.get_signal_connection_list("grace_rested").size()
	_ck("H1 重复 bind_director 后每个既有信号仍仅 1 条连接（按方法名去重）",
			c1 == 1 and c2 == 1, "encounter_finished=%d grace_rested=%d" % [c1, c2])
	d.emit_signal("encounter_finished", true)
	_ck("H2 emit 一次 encounter_finished → impact_count == 1（不重复触发）",
			int(fb.call("get_impact_count")) == 1,
			"impact_count=%d" % int(fb.call("get_impact_count")))
	d.emit_signal("encounter_finished", true)
	_ck("H3 再 emit 一次 → impact_count == 2（信号仍正常驱动）",
			int(fb.call("get_impact_count")) == 2,
			"impact_count=%d" % int(fb.call("get_impact_count")))
	d.emit_signal("grace_rested", 1)
	_ck("H4 grace_rested 亦按实接入并触发（impact_count == 3）",
			int(fb.call("get_impact_count")) == 3,
			"impact_count=%d" % int(fb.call("get_impact_count")))
	var boss: Node = d.get_node_or_null(^"Boss")
	if boss != null:
		var cb: int = boss.get_signal_connection_list("move_landed").size()
		boss.emit_signal("move_landed")
		_ck("H5 Boss.move_landed 按实接入、去重后又触发一次（impact_count == 4）",
				cb == 1 and int(fb.call("get_impact_count")) == 4,
				"boss_move_landed_connections=%d impact_count=%d" % [
						cb, int(fb.call("get_impact_count"))])
	else:
		_ck("H5 Boss 替身存在", false, "未找到 Boss 子节点")


# ---------------------------------------------------------------------------
# I) 面板打开不遮挡
# ---------------------------------------------------------------------------
func _test_panel_open() -> void:
	var fb: Node = _new_feedback()
	fb.call("set_panel_open", "shop", true)
	fb.call("set_panel_open", "codex", true)
	fb.call("request_impact", 1.0)
	var panels: Array = [RECT_SHOP, RECT_CODEX]
	var pix: float = _max_pixel(fb, panels)
	_ck("I1 shop / codex 面板打开后，面板矩形内 flash 像素仍全 0",
			pix == 0.0, "max_pixel=%.4f" % pix)
	var avoid: Array = fb.call("get_avoid_rects") as Array
	_ck("I2 面板打开后避让集仍覆盖 shop / codex 关键矩形",
			_avoid_covers(avoid, RECT_SHOP) and _avoid_covers(avoid, RECT_CODEX),
			"avoid_rects=%d shop=%s codex=%s" % [
					avoid.size(), str(_avoid_covers(avoid, RECT_SHOP)),
					str(_avoid_covers(avoid, RECT_CODEX))])
	var s: Dictionary = _snap(fb)
	var po: Dictionary = s.get("panel_open", {}) as Dictionary
	_ck("I3 set_panel_open 状态可只读回读（shop=true / codex=true）",
			bool(po.get("shop", false)) and bool(po.get("codex", false)),
			"panel_open=%s" % str(po))


# ---------------------------------------------------------------------------
# J) A38 不破坏（courtyard.tscn 节点数 41 / uv 2/1/1 / 无静态反馈层节点）
# ---------------------------------------------------------------------------
func _test_a38() -> void:
	var text: String = FileAccess.get_file_as_string(COURTYARD_PATH)
	var count: int = 0
	for line: String in text.split("\n"):
		if line.begins_with("[node "):
			count += 1
	_ck("J1 courtyard.tscn 静态 [node] 行数 == 41（A38 节点数保持）",
			count == NODE_COUNT_EXPECTED, "count=%d expected=%d" % [count, NODE_COUNT_EXPECTED])
	var n2: int = _count_substr(text, "uv1_scale = Vector3(2, 2, 1)")
	var n1: int = _count_substr(text, "uv1_scale = Vector3(1, 1, 1)")
	_ck("J2 uv 2/1/1 原样：Vector3(2,2,1) ×1 + Vector3(1,1,1) ×2",
			n2 == 1 and n1 == 2, "uv_2x=%d uv_1x=%d" % [n2, n1])
	_ck("J3 courtyard.tscn 文本无 ImpactFeedbackLayer / impact_feedback.gd（运行时挂载、不写场景）",
			not text.contains("ImpactFeedbackLayer") and not text.contains("impact_feedback.gd"),
			"contains_layer=%s contains_script=%s" % [
					str(text.contains("ImpactFeedbackLayer")),
					str(text.contains("impact_feedback.gd"))])


# ---------------------------------------------------------------------------
# K) hud.gd 运行时挂载接线
# ---------------------------------------------------------------------------
func _test_hud_wiring() -> void:
	var text: String = FileAccess.get_file_as_string(HUD_PATH)
	_ck("K1 hud.gd 含 IMPACT_FEEDBACK_PATH / IMPACT_LAYER_NAME / _ensure_impact_feedback",
			text.contains("IMPACT_FEEDBACK_PATH") and text.contains("IMPACT_LAYER_NAME") \
					and text.contains("_ensure_impact_feedback"),
			"path=%s name=%s ensure=%s" % [
					str(text.contains("IMPACT_FEEDBACK_PATH")),
					str(text.contains("IMPACT_LAYER_NAME")),
					str(text.contains("_ensure_impact_feedback"))])
	_ck("K2 hud.gd 含 call_deferred add_child / bind_director / set_low_quality / set_panel_open",
			text.contains("call_deferred(\"add_child\"") and text.contains("bind_director") \
					and text.contains("set_low_quality") and text.contains("set_panel_open") \
					and text.contains("_sync_impact_panels"),
			"add_child=%s bind=%s degrade=%s panel=%s sync=%s" % [
					str(text.contains("call_deferred(\"add_child\"")),
					str(text.contains("bind_director")), str(text.contains("set_low_quality")),
					str(text.contains("set_panel_open")), str(text.contains("_sync_impact_panels"))])


# ---------------------------------------------------------------------------
# L) R31B/A39：真实导演层 player_hit_landed emit → 反馈层自动触发
#    ① 真实导演层 emit 后闪光 > 0；② 连续命中不叠加异常；③ 降级仍闪光；
#    ④ HUD 避让区像素 0；⑤ connect 去重不重复触发。
#    既有 A~K 共 35 条断言逐字未动、不删不放宽；本组只新增。
# ---------------------------------------------------------------------------
func _test_r31b_director_hit() -> void:
	# L1 静态回读：真实 encounter_director.gd 确实声明该信号且在 _try_player_hit 内 emit（不臆造）
	var enc: Script = ResourceLoader.load(
			ENCOUNTER_PATH, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
	var names: Array[String] = []
	if enc != null:
		for s in enc.get_script_signal_list():
			names.append(String(s.get("name", "")))
	var enc_text: String = FileAccess.get_file_as_string(ENCOUNTER_PATH)
	var emit_in_source: bool = enc_text.contains("player_hit_landed.emit(") \
			and enc_text.contains("signal player_hit_landed(damage: int)")
	_ck("L1 真实导演层声明 player_hit_landed(damage:int) 且 _try_player_hit 内 emit",
			names.has("player_hit_landed") and emit_in_source,
			"script_signals=%s emit_in_source=%s" % [str(names), str(emit_in_source)])

	# L2/L3/L4 装配：反馈层 bind 真实命中替身，核对常量与连接数
	var fb: Node = _new_feedback()
	var d: Node = RealHitDirector.new()
	_track(d)
	root.add_child(d)
	fb.call("bind_director", d)
	var cmap: Dictionary = _fb_script.get_script_constant_map()
	var sig_name: String = String(cmap.get("SIG_PLAYER_HIT_LANDED", ""))
	_ck("L2 反馈层 SIG_PLAYER_HIT_LANDED 常量与真实信号名逐字一致",
			sig_name == "player_hit_landed", "sig_const=%s" % sig_name)
	var conn: int = d.get_signal_connection_list("player_hit_landed").size()
	_ck("L3 bind_director 已按实订阅 player_hit_landed（连接数 1）",
			conn == 1, "connections=%d" % conn)

	# L4 真实导演层 emit 一次命中 → 闪光 > 0 且三类反馈齐发
	d.call("land_hit", 12)
	var s2: Dictionary = _snap(fb)
	var flash2: float = float(s2.get("flash_alpha", 0.0))
	_ck("L4 真实导演层 emit 一次命中后闪光 > 0（暖金闪光/微震/hitstop 自动触发）",
			flash2 > 0.0 and int(fb.call("get_impact_count")) == 1 \
					and float(s2.get("shake_amplitude", 0.0)) > 0.0 \
					and int(s2.get("hitstop_frames", 0)) > 0,
			"flash=%.4f impact=%d shake=%s hitstop=%s" % [
					flash2, int(fb.call("get_impact_count")),
					str(s2.get("shake_amplitude", "?")), str(s2.get("hitstop_frames", "?"))])

	# L5 连续命中不叠加异常：flash/shake/hitstop 恒在 [0,上限]、无 NaN、impact 线性
	var peak_cap: float = float(s2.get("flash_peak_alpha", 0.42))
	var shake_cap: float = float(s2.get("shake_max_amplitude", 6.0))
	var hs_cap: int = int(s2.get("hitstop_max_frames", 4))
	var clean: bool = true
	for _i: int in range(5):
		d.call("land_hit", 9)
		var s: Dictionary = _snap(fb)
		var fa: float = float(s.get("flash_alpha", -1.0))
		var sa: float = float(s.get("shake_amplitude", -1.0))
		var hs: int = int(s.get("hitstop_frames", -1))
		if fa != fa or fa < 0.0 or fa > peak_cap + 0.0001 \
				or sa != sa or sa < 0.0 or sa > shake_cap + 0.0001 \
				or hs < 0 or hs > hs_cap:
			clean = false
	_ck("L5 连续 5 次命中：flash/shake/hitstop 恒在 [0,上限]、无 NaN、不叠加异常",
			clean and int(fb.call("get_impact_count")) == 6,
			"impact=%d peak_cap=%.4f shake_cap=%.2f hitstop_cap=%d" % [
					int(fb.call("get_impact_count")), peak_cap, shake_cap, hs_cap])

	# L6 重复 bind 去重：连接仍 1 条、单次 emit 仅 +1 impact
	fb.call("bind_director", d)
	var conn2: int = d.get_signal_connection_list("player_hit_landed").size()
	d.call("land_hit", 7)
	_ck("L6 重复 bind_director 后仍 1 条连接、单次 emit 仅 +1 impact（不重复触发）",
			conn2 == 1 and int(fb.call("get_impact_count")) == 7,
			"connections=%d impact=%d" % [conn2, int(fb.call("get_impact_count"))])

	# L7 降级仍闪光 + HUD 避让区像素 0（峰值态最强条件）
	var fb2: Node = _new_feedback()
	fb2.call("set_low_quality", true)
	var d2: Node = RealHitDirector.new()
	_track(d2)
	root.add_child(d2)
	fb2.call("bind_director", d2)
	d2.call("land_hit", 15)
	var sd: Dictionary = _snap(fb2)
	var flash_low: float = float(sd.get("flash_alpha", 0.0))
	var avoid2: Array = fb2.call("get_avoid_rects") as Array
	var pix_low: float = _max_pixel(fb2, avoid2)
	_ck("L7 降级下真实命中仍闪光>0、shake/hitstop=0、HUD 避让区像素仍 0",
			flash_low > 0.0 and float(sd.get("shake_amplitude", -1.0)) == 0.0 \
					and int(sd.get("hitstop_frames", -1)) == 0 and pix_low == 0.0,
			"flash=%.4f shake=%s hitstop=%s max_avoid_pixel=%.4f" % [
					flash_low, str(sd.get("shake_amplitude", "?")),
					str(sd.get("hitstop_frames", "?")), pix_low])


# ---------------------------------------------------------------------------
# M) R35C/A64 局部收敛：闪光绘制包围盒不再覆盖中景大矩形 + 改前/改后覆盖面积实证
# N) R35C/A64 HUD 避让区像素仍为 0（A64 保留项，收敛后回归）
#    既有 A~L 共 42 条断言逐字未动、不删不放宽；本 M/N 两组为新增运行时断言。
# ---------------------------------------------------------------------------
func _test_r35c_local_flash() -> void:
	var fb: Node = _new_feedback()
	fb.call("request_impact", 1.0)   # 峰值态，最强条件
	var rects: Array = fb.call("get_flash_rects") as Array
	var avoid: Array = fb.call("get_avoid_rects") as Array
	var cmap: Dictionary = _fb_script.get_script_constant_map()
	var radius: float = float(cmap.get("FLASH_RADIUS", -1.0))
	var anchor: Vector2 = cmap.get("FLASH_ANCHOR", Vector2.ZERO)
	var diameter: float = radius * 2.0
	# 改前（全屏安全网格）/ 改后（局部 flash_rects）覆盖面积实证
	var area_before: float = _fullscreen_safe_area(avoid)
	var area_after: float = 0.0
	for a in rects:
		var rr: Rect2 = a
		area_after += rr.get_area()
	var bbox: Rect2 = _union_bbox(rects)
	var ratio: float = area_after / area_before if area_before > 0.0 else 0.0
	print("[V090] [R35C] FLASH_COVERAGE_BEFORE=%.1f px2 AFTER=%.1f px2 ratio=%.4f" % [
			area_before, area_after, ratio])
	print("[V090] [R35C] FLASH_BBOX=(%.1f,%.1f,%.1f,%.1f) MID_RECT=(388,188,892,532) radius=%.1f anchor=(%.1f,%.1f)" % [
			bbox.position.x, bbox.position.y, bbox.size.x, bbox.size.y, radius, anchor.x, anchor.y])
	# M1：闪光绘制包围盒不再覆盖中景大矩形（宽/高 <= 局部作用域直径、面积 << 中景 892x532）
	var m1: bool = radius > 0.0 \
			and bbox.size.x <= diameter + 0.01 \
			and bbox.size.y <= diameter + 0.01 \
			and bbox.get_area() < MID_RECT.get_area()
	_ck("M1 [R35C/A64] 闪光绘制包围盒不再覆盖中景大矩形（bbox<=局部直径、面积<<892x532）",
			m1, "bbox_size=(%.1f,%.1f) diameter=%.1f bbox_area=%.1f mid_area=%.1f" % [
					bbox.size.x, bbox.size.y, diameter, bbox.get_area(), MID_RECT.get_area()])
	# M2：中景大矩形内「远离锚点」的 5 处代表点改后 flash 像素为 0（改前峰值态为 0.42）
	var mid_points: Array[Vector2] = [
			Vector2(1000.0, 600.0), Vector2(1200.0, 620.0),
			Vector2(1250.0, 300.0), Vector2(450.0, 600.0), Vector2(900.0, 300.0),
	]
	var worst_mid: float = 0.0
	for p in mid_points:
		worst_mid = maxf(worst_mid, float(fb.call("sample_flash", p.x, p.y)))
	_ck("M2 [R35C/A64] 中景大矩形远锚点 5 处采样 flash 像素全 0（改前峰值态为 0.42）",
			worst_mid == 0.0, "worst_mid_pixel=%.4f points=%d" % [worst_mid, mid_points.size()])
	# M3：局部网格非空、锚点闪光>0、所有 flash_rect 落在局部作用域内
	var anchor_pix: float = float(fb.call("sample_flash", anchor.x, anchor.y))
	var local_rect: Rect2 = Rect2(anchor - Vector2(radius, radius), Vector2(diameter, diameter))
	var all_local: bool = rects.size() > 0
	for a in rects:
		var rr: Rect2 = a
		if not local_rect.encloses(rr):
			all_local = false
	_ck("M3 [R35C/A64] 局部网格非空、锚点闪光>0、所有 flash_rect 落在局部作用域内",
			all_local and anchor_pix > 0.0,
			"rects=%d anchor=(%.1f,%.1f) anchor_pixel=%.4f all_local=%s" % [
					rects.size(), anchor.x, anchor.y, anchor_pix, str(all_local)])


func _test_r35c_hud_avoid_pixels() -> void:
	var fb: Node = _new_feedback()
	fb.call("request_impact", 1.0)   # 峰值态
	var avoid: Array = fb.call("get_avoid_rects") as Array
	var rects: Array = fb.call("get_flash_rects") as Array
	# N1：7 区避让矩形 9 点密集采样（中心/四角内缩/四边中点）flash 像素恒 0
	var worst: float = 0.0
	var samples: int = 0
	for a in avoid:
		var rr: Rect2 = a
		var pts: Array[Vector2] = [
				rr.position + rr.size * 0.5,
				rr.position + Vector2(2.0, 2.0),
				Vector2(rr.end.x - 2.0, rr.position.y + 2.0),
				Vector2(rr.position.x + 2.0, rr.end.y - 2.0),
				rr.end - Vector2(2.0, 2.0),
				Vector2(rr.position.x + rr.size.x * 0.5, rr.position.y + 2.0),
				Vector2(rr.position.x + rr.size.x * 0.5, rr.end.y - 2.0),
				Vector2(rr.position.x + 2.0, rr.position.y + rr.size.y * 0.5),
				Vector2(rr.end.x - 2.0, rr.position.y + rr.size.y * 0.5),
		]
		for p in pts:
			worst = maxf(worst, float(fb.call("sample_flash", p.x, p.y)))
			samples += 1
	_ck("N1 [R35C/A64] 峰值态 7 区 HUD 避让矩形 9 点密集采样 flash 像素全 0",
			worst == 0.0, "samples=%d worst_pixel=%.4f avoid_rects=%d" % [
					samples, worst, avoid.size()])
	# N2：收敛后每个 flash_rect 与每个避让矩形几何交集面积仍 == 0（A64 保留项）
	var worst_area: float = 0.0
	for r in rects:
		var rr: Rect2 = r
		for a in avoid:
			var aa: Rect2 = a
			worst_area = maxf(worst_area, rr.intersection(aa).get_area())
	_ck("N2 [R35C/A64] 收敛后每个 flash_rect 与每个 avoid_rect 几何交集面积仍 == 0",
			worst_area == 0.0, "worst_overlap=%.4f px2 flash_rects=%d" % [
					worst_area, rects.size()])


func _finish() -> void:
	# 倒序释放：先 free 后创建的夹具（含其自建层），避免 feedback._exit_tree 悬空 Callable。
	for i: int in range(_temps.size() - 1, -1, -1):
		var n: Node = _temps[i]
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	var ok: bool = _fail == 0 and _pass > 0
	print("[V090] ---- 回读汇总 ----")
	print("[V090] SUMMARY pass=%d fail=%d total=%d ok=%s" % [
			_pass, _fail, _pass + _fail, str(ok)])
	if ok:
		print("[V090] RESULT=ALL_MATCH")
	else:
		print("[V090] RESULT=MISMATCH")
	print("[V090] ==== verify_impact_feedback_v090 真跑结束 ====")
	quit(0 if ok else 1)
