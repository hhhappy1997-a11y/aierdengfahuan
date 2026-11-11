extends SceneTree
## R29 · depth_profile.tres 两档景深参数校验（Rank-2 交付件 · v0.7.0 新内容）
## 派单 cmd-20261111-112803-988-A2 · [ROUND=R29] · AI=2（Rank-2 战斗系统与数据驱动）
## 真跑：godot --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/verify_depth_profile_v070.gd
## 门禁：godot --headless --path ... --check-only --script res://scripts/verify_depth_profile_v070.gd
##
## 唯一职责：CACHE_MODE_IGNORE 真读盘 res://data/render/depth_profile.tres →
##   取 desktop / mobile 两档（DepthProfile 子资源）→ 逐项断言参数合法、
##   mobile 不比 desktop 更亮/更糊/更黑、色号落在色板内 → 边界非法构造
##   经 DepthProfile.is_valid() 拒绝且不崩 → 汇总 PASS/FAIL + RESULT。
##
## 【色板依据·如实登记】任务要求「色号落在 HD2D-STYLE-ANCHOR v2 色板内」。
##   HD2D-STYLE-ANCHOR-v2.md 归 Rank-3 所有权；本轮运行期以
##   FileAccess.file_exists("res://../HD2D-STYLE-ANCHOR-v2.md") 实测其已落盘
##   （R29 并发产物），故【不降级】：采用该文档 §5.3 的可机器解析常量块
##   colors_16（16 色受控板，v1 §2 真源）+ §2.2 唯一锚点色
##   cold_night_fog_hex=#1B2A4A / warm_gold_key_hex=#C99A3A（§2.2 明示
##   「供 depth_profile.tres 字段逐字引用」），两档色号须逐字相等。
##   若该文档尚未落盘（另一运行情形），则按任务单降级为「自带色板常量」：
##   工程冻结色板 godot/assets/generated/palette_256.json 的 32 色及其
##   cold_night_fog / warm_gold_key 语义组，并以 [DEGRADE] 行如实登记。
##   运行期打印 [ANCHOR] / [DEGRADE] 与所选依据，不谎称读到不存在的文档。
##   注：v2 §5.1 明言 16 色受控板（v1 §2 真源）与 palette_256.json 32 色板
##   是「历史两套口径并存、不擅自合并」；本轮按任务单与 v2 指定用前者，
##   后者仅在降级时使用，两套不混用。
##
## 边界：只加载 depth_profile.tres（load + CACHE_MODE_IGNORE，不 pack / 不保存）；
##   不加载 / 不修改 courtyard.tscn / hud.gd / presentation.gd / 任何 shader / 素材；
##   零外部素材 / 零付费 / 零插件 / 零 GPU job；中文 UTF-8；Godot 4.7.2 全静态类型；
##   不伪造输出，所有断言值均为运行期实际回读。

const PROFILE_PATH: String = "res://data/render/depth_profile.tres"
const ANCHOR_DOC_HINT: String = "HD2D-STYLE-ANCHOR-v2.md"

# ── 首选：HD2D-STYLE-ANCHOR-v2.md §5.3 colors_16（逐字复制）──────────
const ANCHOR_V2_COLORS_16 := [
	"#0A1020", "#1B2A4A", "#6B4226", "#B33A3A",
	"#2C4C8C", "#3F6FC4", "#C99A3A", "#35D0C0",
	"#79B4E8", "#E8B98C", "#F2D07A", "#C9D2E0",
	"#E8EDF2", "#24406B", "#3B2E5A", "#5A3B52"
]
const ANCHOR_V2_COLD_NIGHT_FOG: String = "#1B2A4A"
const ANCHOR_V2_WARM_GOLD_KEY: String = "#C99A3A"

# ── 降级：godot/assets/generated/palette_256.json 32 色（逐字）──────────
const FALLBACK_COLORS_32 := [
	"#FFF0C2", "#FFD27A", "#F0A94C", "#C97A2E", "#8A5A22",
	"#BFD0EA", "#7E96BF", "#4A6089", "#2B3A5C", "#16233F", "#0B1226",
	"#1F3A63", "#16294A", "#0E1B33", "#080F1F",
	"#E8C479", "#B8944A", "#8A6A32",
	"#C6BBA4", "#9A8E78", "#6E6453", "#463F35", "#29251F",
	"#A8C09A", "#6C8A70", "#3E5A4C", "#22372F",
	"#F5E6C8", "#9FB4D4", "#55688A",
	"#D9584A", "#6FBF8E"
]
const FALLBACK_COLD_GROUP := ["#BFD0EA", "#7E96BF", "#4A6089", "#2B3A5C", "#16233F", "#0B1226"]
const FALLBACK_WARM_GROUP := ["#FFF0C2", "#FFD27A", "#F0A94C", "#C97A2E", "#8A5A22"]

var _pass_count: int = 0
var _fail_count: int = 0
# 运行期选定的色板依据（由 ⓪ 锚点文档存在性决定，如实登记）
var _palette: Array = []
var _cold_expect: String = ""
var _warm_expect: String = ""
var _cold_group: Array = []
var _warm_group: Array = []
var _strict_anchor: bool = false
var _palette_source: String = ""


func _initialize() -> void:
	print("==== [R29 verify_depth_profile_v070] START ====")

	# (0) 色板依据选定（如实登记；锚点文档已落盘则不降级）
	var anchor_abs: String = ProjectSettings.globalize_path("res://../" + ANCHOR_DOC_HINT)
	var anchor_exists: bool = FileAccess.file_exists(anchor_abs)
	if anchor_exists:
		_palette = ANCHOR_V2_COLORS_16
		_cold_expect = ANCHOR_V2_COLD_NIGHT_FOG
		_warm_expect = ANCHOR_V2_WARM_GOLD_KEY
		_cold_group = [ANCHOR_V2_COLD_NIGHT_FOG]
		_warm_group = [ANCHOR_V2_WARM_GOLD_KEY]
		_strict_anchor = true
		_palette_source = "HD2D-STYLE-ANCHOR-v2.md §5.3 colors_16（16 色受控板）"
		print("[R29][ANCHOR] anchor_doc=%s exists=true | 文档已落盘，不降级；采用 %s" % [
				ANCHOR_DOC_HINT, _palette_source])
	else:
		_palette = FALLBACK_COLORS_32
		_cold_group = FALLBACK_COLD_GROUP
		_warm_group = FALLBACK_WARM_GROUP
		_strict_anchor = false
		_palette_source = "降级：godot/assets/generated/palette_256.json 32 色"
		print("[R29][DEGRADE] anchor_doc=%s exists=false | 尚未落盘 → 降级为自带色板常量（%s）" % [
				ANCHOR_DOC_HINT, _palette_source])
	_check("⓪ 色板依据选定并如实登记", true,
			"anchor_exists=%s / strict_anchor=%s / palette=%d 色 / source=%s" % [
					str(anchor_exists), str(_strict_anchor), _palette.size(), _palette_source])

	# (1) 真读盘加载（CACHE_MODE_IGNORE 绕过缓存，强制重解析刚落盘的 .tres）
	var res: Resource = ResourceLoader.load(
			PROFILE_PATH, "Resource", ResourceLoader.CACHE_MODE_IGNORE)
	if res == null:
		push_error("[R29] 资源加载失败 path=" + PROFILE_PATH)
		print("==== [R29] RESULT=FAIL ====")
		quit(1)
		return
	var root: DepthProfile = res as DepthProfile
	_check("① 资源加载成功且可 cast 为 DepthProfile", root != null,
			"path=%s class=%s" % [PROFILE_PATH, res.get_class()])
	if root == null:
		_finish()
		return

	var d: DepthProfile = root.desktop as DepthProfile
	var m: DepthProfile = root.mobile as DepthProfile
	_check("② desktop 档存在且为 DepthProfile", d != null, "desktop=%s" % str(root.desktop))
	_check("③ mobile 档存在且为 DepthProfile", m != null, "mobile=%s" % str(root.mobile))
	if d == null or m == null:
		_finish()
		return

	# (2) 两档参数合法（is_valid 自检 + 逐字段范围 + 色号色板）
	_verify_tier("desktop", d)
	_verify_tier("mobile", m)

	# (3) mobile 降级关系（不更亮 / 不更糊 / 不更黑）
	_verify_degrade(d, m)

	# (4) 边界拒绝不崩
	_verify_boundaries()

	_finish()


func _verify_tier(label: String, p: DepthProfile) -> void:
	print("---- [R29 档位回读] %s START ----" % label)
	print("[R29][%s] layer_depths=%s parallax=%s fog=%.4f vignette=%.4f glow=%.4f cold=%s warm=%s" % [
			label, str(p.layer_depths), str(p.parallax_coefficients),
			p.fog_density, p.vignette_strength, p.warm_glow_strength,
			p.cold_night_fog_color, p.warm_gold_key_color])
	_check("[%s] is_valid()==true" % label, p.is_valid(), "结构/范围/色号格式自检")

	var ld: PackedFloat32Array = p.layer_depths
	var pc: PackedFloat32Array = p.parallax_coefficients
	_check("[%s] layer_depths 非空且长度==parallax_coefficients" % label,
			not ld.is_empty() and ld.size() == pc.size(),
			"ld=%d pc=%d" % [ld.size(), pc.size()])

	var ld_ok: bool = not ld.is_empty()
	for x in ld:
		if x <= 0.0 or x > 1.0:
			ld_ok = false
	_check("[%s] 每个层深 0<d<=1" % label, ld_ok, "values=%s" % str(ld))

	var pc_ok: bool = not pc.is_empty()
	for x in pc:
		if x <= 0.0 or x > 1.0:
			pc_ok = false
	_check("[%s] 每个视差系数 0<c<=1" % label, pc_ok, "values=%s" % str(pc))

	var inc_ok: bool = true
	for i in range(1, pc.size()):
		if pc[i] <= pc[i - 1]:
			inc_ok = false
	_check("[%s] 视差系数远小近大严格递增" % label, inc_ok, "values=%s" % str(pc))

	_check("[%s] fog_density 0~1" % label,
			p.fog_density >= 0.0 and p.fog_density <= 1.0, "%.4f" % p.fog_density)
	_check("[%s] vignette_strength 0~1" % label,
			p.vignette_strength >= 0.0 and p.vignette_strength <= 1.0, "%.4f" % p.vignette_strength)
	_check("[%s] warm_glow_strength 0~1" % label,
			p.warm_glow_strength >= 0.0 and p.warm_glow_strength <= 1.0, "%.4f" % p.warm_glow_strength)

	_check("[%s] 冷夜雾色号 ∈ 色板（%s）" % [label, _palette_source],
			_palette.has(p.cold_night_fog_color), "color=%s" % p.cold_night_fog_color)
	if _strict_anchor:
		_check("[%s] 冷夜雾色号逐字 == v2 锚点 #1B2A4A" % label,
				p.cold_night_fog_color == _cold_expect,
				"color=%s expect=%s" % [p.cold_night_fog_color, _cold_expect])
	else:
		_check("[%s] 冷夜雾色号 ∈ 降级板 cold_night_fog 语义组" % label,
				_cold_group.has(p.cold_night_fog_color), "color=%s" % p.cold_night_fog_color)
	_check("[%s] 暖金主光色号 ∈ 色板（%s）" % [label, _palette_source],
			_palette.has(p.warm_gold_key_color), "color=%s" % p.warm_gold_key_color)
	if _strict_anchor:
		_check("[%s] 暖金主光色号逐字 == v2 锚点 #C99A3A" % label,
				p.warm_gold_key_color == _warm_expect,
				"color=%s expect=%s" % [p.warm_gold_key_color, _warm_expect])
	else:
		_check("[%s] 暖金主光色号 ∈ 降级板 warm_gold_key 语义组" % label,
				_warm_group.has(p.warm_gold_key_color), "color=%s" % p.warm_gold_key_color)
	print("---- [R29 档位回读] %s END ----" % label)


func _verify_degrade(d: DepthProfile, m: DepthProfile) -> void:
	print("---- [R29 mobile 降级关系] START ----")
	_check("降级① mobile 不比 desktop 更亮（warm_glow_strength）",
			m.warm_glow_strength <= d.warm_glow_strength,
			"mobile=%.4f desktop=%.4f" % [m.warm_glow_strength, d.warm_glow_strength])
	_check("降级② mobile 雾不比 desktop 更浓（fog_density）",
			m.fog_density <= d.fog_density,
			"mobile=%.4f desktop=%.4f" % [m.fog_density, d.fog_density])
	_check("降级③ mobile 层数不多于 desktop",
			m.layer_depths.size() <= d.layer_depths.size(),
			"mobile=%d desktop=%d" % [m.layer_depths.size(), d.layer_depths.size()])

	var dmax: float = 0.0
	for x in d.layer_depths:
		if x > dmax:
			dmax = x
	var mmax: float = 0.0
	for x in m.layer_depths:
		if x > mmax:
			mmax = x
	_check("降级④ mobile 层深跨度不超过 desktop",
			mmax <= dmax, "mobile_max=%.4f desktop_max=%.4f" % [mmax, dmax])

	var par_ok: bool = m.parallax_coefficients.size() <= d.parallax_coefficients.size()
	if par_ok:
		for i in range(m.parallax_coefficients.size()):
			if m.parallax_coefficients[i] > d.parallax_coefficients[i]:
				par_ok = false
	_check("降级⑤ mobile 视差系数逐项不超过 desktop（对应层）", par_ok,
			"mobile=%s desktop=%s" % [str(m.parallax_coefficients), str(d.parallax_coefficients)])
	_check("降级⑥ mobile 不比 desktop 更黑（vignette_strength）",
			m.vignette_strength <= d.vignette_strength,
			"mobile=%.4f desktop=%.4f" % [m.vignette_strength, d.vignette_strength])
	print("---- [R29 mobile 降级关系] END ----")


func _verify_boundaries() -> void:
	print("---- [R29 边界拒绝不崩] START ----")
	_reject("边界① 负 fog_density", _mk_bad("fog_density", -0.1))
	_reject("边界② 负 vignette_strength", _mk_bad("vignette_strength", -0.1))
	_reject("边界③ 负 warm_glow_strength", _mk_bad("warm_glow_strength", -0.1))
	_reject("边界④ 视差系数超 1", _mk_bad_arr("parallax", PackedFloat32Array([0.06, 1.5, 0.26])))
	_reject("边界⑤ 层深超 1", _mk_bad_arr("layer", PackedFloat32Array([0.25, 1.2, 0.9])))
	_reject("边界⑥ fog_density 超 1", _mk_bad("fog_density", 1.2))
	_reject("边界⑦ 空 layer_depths（空表）", _mk_bad_arr("layer", PackedFloat32Array()))
	_reject("边界⑧ 空 parallax_coefficients（空表）", _mk_bad_arr("parallax", PackedFloat32Array()))
	_reject("边界⑨ 层深/视差长度不匹配（字段缺失）", _mk_mismatch())
	_reject("边界⑩ 空冷夜雾色号（字段缺失）", _mk_bad("cold", ""))
	_reject("边界⑪ 非法 hex 色号", _mk_bad("cold", "NOT_A_COLOR"))
	_reject("边界⑫ 全新空实例（字段全缺失）", DepthProfile.new())
	print("---- [R29 边界拒绝不崩] END ----")


func _base_good() -> DepthProfile:
	var p := DepthProfile.new()
	p.layer_depths = PackedFloat32Array([0.25, 0.55, 0.9])
	p.parallax_coefficients = PackedFloat32Array([0.06, 0.14, 0.26])
	p.fog_density = 0.035
	p.vignette_strength = 0.24
	p.warm_glow_strength = 0.45
	p.cold_night_fog_color = "#1B2A4A"
	p.warm_gold_key_color = "#C99A3A"
	return p


func _mk_bad(field: String, v: Variant) -> DepthProfile:
	var p := _base_good()
	match field:
		"fog_density": p.fog_density = float(v)
		"vignette_strength": p.vignette_strength = float(v)
		"warm_glow_strength": p.warm_glow_strength = float(v)
		"cold": p.cold_night_fog_color = str(v)
		"warm": p.warm_gold_key_color = str(v)
	return p


func _mk_bad_arr(which: String, arr: PackedFloat32Array) -> DepthProfile:
	var p := _base_good()
	if which == "layer":
		p.layer_depths = arr
	else:
		p.parallax_coefficients = arr
	return p


func _mk_mismatch() -> DepthProfile:
	var p := _base_good()
	p.layer_depths = PackedFloat32Array([0.25, 0.55])
	return p


func _reject(label: String, p: DepthProfile) -> void:
	var v: bool = p.is_valid()
	_check(label, v == false,
			"is_valid()=%s 期望=false；调用未抛异常/未崩溃" % str(v))


func _check(label: String, ok: bool, detail: String) -> void:
	if ok:
		_pass_count += 1
	else:
		_fail_count += 1
	print("[R29_CHK] %s PASS=%s | %s" % [label, str(ok), detail])


func _finish() -> void:
	var ok: bool = (_fail_count == 0)
	print("==== [R29] SUMMARY pass=%d fail=%d total=%d ====" % [
			_pass_count, _fail_count, _pass_count + _fail_count])
	print("==== [R29] RESULT=%s ====" % ("PASS" if ok else "FAIL"))
	print("==== [R29 verify_depth_profile_v070] END ====")
	quit(0 if ok else 1)
