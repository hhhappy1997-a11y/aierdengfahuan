extends Resource
class_name FocusConfig

## ===========================================================================
## R36 / v0.13.0「专注值与战技 · 画面补齐」· Focus 规则数据表资源（Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-154132-912-A2）
## 目录所有权·R36 冻结：本文件 / godot/data/combat/focus_rules.tres /
##   focus_service.gd / verify_focus_v130.gd / verify_focus_settlement_v130.gd /
##   wave_trial_director.gd（接线，唯一写入方 Rank-2）/ teamwork/Rank-2/ 归 Rank-2 唯一写入；
##   encounter_director.gd / hud.gd / presentation.gd（唯一写入方 Rank-1）/
##   points_commit_orchestrator.gd / project.godot（Rank-3）/ courtyard.tscn /
##   所有既有 .tres 数值 / 场景 / 素材 / 其它 Rank 文件一律只读、不改。
##
## 【纯逻辑边界（任务单 ① / 契约 I-1）】
## - 本类是数据表结构，不含结算逻辑：extends Resource、不继承 Node、不碰场景树、
##   不 add_child、不取 root、不调用 get_tree()、不用 /root/... 绝对路径、
##   不读写存档文件（I-1）、不碰渲染、不 load 任何资源。
## - 数值唯一真源是 res://data/combat/focus_rules.tres；本类只定义结构、字段白名单、
##   合法性纯函数与「字段缺失 / 表非法」降级基线，不把任何设计数值写死进代码
##   （@export 默认值 = DEFAULT_* 降级基线，刻意 != 表值，不是设计数值）。
##
## 【5 个字段契约（任务单 ①，全部 [PLACEHOLDER]）】
##   fp_max              : float  专注值上限；构造 / reset() / 赐福休息回满到该值
##   fp_regen_on_rest    : float  赐福休息「增量回复」量（仅 rest_refill=false 时生效）
##   arts                : Array[Dictionary]  2 个战技，每行 6 字段：
##                          id / title / fp_cost / cooldown_sec / damage / poise_damage
##                          · 辉石魔砾（低耗远程）/ 狮子斩（高耗高削韧）
##                          · damage 并入【既有清波点数结算基数】（A57 唯一最终值）
##                          · poise_damage 并入【既有 Boss 削韧结算】（StaggerService.apply_hit）
##   rest_refill         : bool   赐福休息是否「回满」；true=回满 fp_max，false=按 fp_regen_on_rest 增量
##   invalid_input_policy: String 异常输入策略；首版唯一合法值 POLICY_REJECT="reject"
##                          （异常 id / 负数 / null / 非法 delta 一律拒绝且不改状态）
##
## 【设计数值 [PLACEHOLDER] rationale（数值实例在 .tres，本块只写「为什么」）】
##   ⚠ 以下全部为 [PLACEHOLDER] 首版假设、待人工试玩校准；只改 .tres 不改代码。
##   ① fp_max = 100.0
##      rationale：与既有 stagger_rules.tres 的 stagger_max=100.0 同量级，便于「专注值条」
##      与「韧性条」统一量纲；取整百便于 15~20 秒实机录屏里肉眼观察消耗/回复。
##   ② fp_regen_on_rest = 40.0
##      rationale：rest_refill=false 时的增量回复量，取 fp_max 的 40%，表达「休息回一部分而非全满」；
##      默认 rest_refill=true 不启用该字段，保留它供裁决切换回满/增量策略，不改代码。
##   ③ rest_refill = true
##      rationale：任务单覆盖点「赐福休息回满」——赐福休息是唯一的 FP 回复出口（守住
##      「FP 只减不增除休息」不变量）；置 false 可切换为按 fp_regen_on_rest 增量回复的对照档。
##   ④ invalid_input_policy = "reject"
##      rationale：异常输入（不存在的 id / null / 数字 / 空串 / 负 delta）一律拒绝且不改状态，
##      避免 clamp / ignore 造成「隐式扣 FP / 隐式污染冷却」的不可测分支；首版只实现 reject，
##      任何策略扩展都必须先补回归用例再改代码 + 表 + 验证，列为 DONE-R36 待裁决项。
##   ⑤ arts[0] 辉石魔砾 glintstone_pebble（低耗远程）
##      fp_cost=12.0  rationale：约 fp_max 的 1/8，一局可连续施放约 8 次，定位「远程消耗/补刀」。
##      cooldown_sec=0.6  rationale：短冷却，防同帧连发把 damage/poise 刷成通胀（A51/A60）。
##      damage=18.0  rationale：并入清波结算基数的小额点数伤害，明显小于 R35 弹反 points_bonus=50，
##      避免战技奖励盖过既有处决/弹反出口（不造成点数通胀）。
##      poise_damage=8.0  rationale：远程低削韧，小于既有 reference_poise_damage=25.0，
##      一次魔砾 ≈ 1/3 次标准命中，不改既有削韧判定分支。
##   ⑥ arts[1] 狮子斩 lion_slash（高耗高削韧）
##      fp_cost=35.0  rationale：约 fp_max 的 1/3，一局至多 2~3 次，与魔砾形成资源取舍。
##      cooldown_sec=1.8  rationale：长冷却，与高削韧/高伤害匹配，防连发刷结算（A51/A60）。
##      damage=45.0  rationale：与 R35 弹反 points_bonus=50 同量级，近战高伤战技的清波点数贡献。
##      poise_damage=40.0  rationale：既有 stagger_max=100.0 的 40%、reference_poise_damage=25.0 的
##      1.6 倍，体现「高削韧」定位；仍经既有 StaggerService.apply_hit 结算，不改判定分支。
##
## 【调参唯一入口（只改表不改代码）】
##   godot/data/combat/focus_rules.tres —— fp_max / fp_regen_on_rest / arts(2×6) /
##   rest_refill / invalid_input_policy 全在此一处。
##   校准同步清单：.tres -> verify_focus_v130.gd 的 EXPECT_* ->
##   teamwork/Rank-2/DONE-R36.md 数值拆解表 -> 三段门禁；不静默改数、
##   不改本 .gd 的 DEFAULT_* 基线（那是非法输入降级用，不是设计数值）。
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- 公开常量（签名稳定）----
## 异常输入策略：首版唯一合法值。FocusService 拒绝分支据此实现；改策略需同步改代码 + 回归用例。
const POLICY_REJECT: String = "reject"
## 战技行字段白名单（is_valid() 逐项校验，缺一即非法表）。
const ART_FIELDS: PackedStringArray = [
	"id", "title", "fp_cost", "cooldown_sec", "damage", "poise_damage"
]

## ---- [PLACEHOLDER] 降级基线（字段缺失 / 表非法时用，刻意 != 设计数值）----
const DEFAULT_FP_MAX: float = 1.0
const DEFAULT_FP_REGEN_ON_REST: float = 0.0
const DEFAULT_REST_REFILL: bool = false
## 注：policy 的降级基线必须与唯一合法值一致，否则 is_valid() 会判表非法、服务降级；
## 它不参与「DEFAULT_* != 表值」的机器判定（验证脚本只对数值字段做该判定）。
const DEFAULT_INVALID_INPUT_POLICY: String = POLICY_REJECT

## 5 个字段（@export 默认值 = 降级基线；设计数值在 .tres）。
@export var fp_max: float = DEFAULT_FP_MAX                        # [PLACEHOLDER]
@export var fp_regen_on_rest: float = DEFAULT_FP_REGEN_ON_REST    # [PLACEHOLDER]
@export var arts: Array[Dictionary] = []                          # [PLACEHOLDER]
@export var rest_refill: bool = DEFAULT_REST_REFILL               # [PLACEHOLDER]
@export var invalid_input_policy: String = DEFAULT_INVALID_INPUT_POLICY  # [PLACEHOLDER]


## 全表合法性：5 字段类型合法、fp_max>0、回复/各战技数值 >=0 且 fp_cost>0、
## policy == POLICY_REJECT、arts 恰含合法且不重复 id 的行；异常一律 false（不崩）。
func is_valid() -> bool:
	if typeof(fp_max) != TYPE_INT and typeof(fp_max) != TYPE_FLOAT:
		return false
	if typeof(fp_regen_on_rest) != TYPE_INT and typeof(fp_regen_on_rest) != TYPE_FLOAT:
		return false
	if typeof(rest_refill) != TYPE_BOOL:
		return false
	if typeof(invalid_input_policy) != TYPE_STRING:
		return false
	if typeof(arts) != TYPE_ARRAY:
		return false
	var fmax: float = float(fp_max)
	var regen: float = float(fp_regen_on_rest)
	if is_nan(fmax) or is_inf(fmax) or fmax <= 0.0:
		return false
	if is_nan(regen) or is_inf(regen) or regen < 0.0:
		return false
	if String(invalid_input_policy) != POLICY_REJECT:
		return false
	if (arts as Array).is_empty():
		return false
	var seen: Dictionary = {}
	for entry: Variant in (arts as Array):
		if typeof(entry) != TYPE_DICTIONARY:
			return false
		var d: Dictionary = entry as Dictionary
		for k: String in ART_FIELDS:
			if not d.has(k):
				return false
		var id: String = str(d.get("id", ""))
		var title: String = str(d.get("title", ""))
		if id.is_empty() or title.is_empty():
			return false
		if typeof(d.get("id")) != TYPE_STRING or typeof(d.get("title")) != TYPE_STRING:
			return false
		if seen.has(id):
			return false
		seen[id] = true
		for nk: String in ["fp_cost", "cooldown_sec", "damage", "poise_damage"]:
			var v: Variant = d[nk]
			if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
				return false
			var f: float = float(v)
			if is_nan(f) or is_inf(f) or f < 0.0:
				return false
		if float(d["fp_cost"]) <= 0.0:
			return false
	return true


## ---- 只读 getter（全静态类型；数值来自表，代码不写死设计值）----
func get_fp_max() -> float:
	return float(fp_max)


func get_fp_regen_on_rest() -> float:
	return float(fp_regen_on_rest)


func get_rest_refill() -> bool:
	return bool(rest_refill)


func get_invalid_input_policy() -> String:
	return String(invalid_input_policy)


func get_art_count() -> int:
	return (arts as Array).size()


func get_art_ids() -> PackedStringArray:
	var out: PackedStringArray = []
	for entry: Variant in (arts as Array):
		if typeof(entry) == TYPE_DICTIONARY:
			out.append(str((entry as Dictionary).get("id", "")))
	return out


## 越界 / 缺失返回空 Dictionary（不崩）；返回副本，调用方改动不污染表。
func get_art(index: int) -> Dictionary:
	if index < 0 or index >= (arts as Array).size():
		return {}
	return ((arts as Array)[index] as Dictionary).duplicate()


## 按 id 查战技；找不到返回空 Dictionary（异常 id 拒绝的判定依据）。
func get_art_by_id(id: String) -> Dictionary:
	for entry: Variant in (arts as Array):
		if typeof(entry) == TYPE_DICTIONARY:
			var d: Dictionary = entry as Dictionary
			if str(d.get("id", "")) == id:
				return d.duplicate()
	return {}
