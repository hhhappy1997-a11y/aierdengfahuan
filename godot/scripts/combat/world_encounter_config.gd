extends Resource
class_name WorldEncounterConfig

## ===========================================================================
## R38 / v0.15.0「大地图 · 2.5D 尺度重构」· 野外遭遇点数据表资源（Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-234238-650-A2）
## 目录所有权·R38 冻结：本文件 / godot/data/rpg/world_encounters.tres /
##   world_encounter_service.gd / wave_trial_director.gd（接线，唯一写入方 Rank-2）/
##   verify_world_encounter_v150.gd / verify_world_settlement_v150.gd /
##   teamwork/Rank-2/ 归 Rank-2 唯一写入；courtyard.tscn / hud.gd / presentation.gd
##   （Rank-1）/ points_commit_orchestrator.gd / project.godot（Rank-3）/ 既有 .tres
##   数值 / 场景 / 素材 / 其它 Rank 文件一律只读、不改。
##
## 【纯逻辑边界（任务单 ① / 契约 I-1）】
## - 本类是数据表结构，不含触发/结算逻辑：extends Resource、不继承 Node、不碰场景树、
##   不 add_child、不取 root、不调用 get_tree()、不用 /root/... 绝对路径、
##   不读写存档文件（I-1）、不碰渲染、不 load 任何资源。
## - 数值唯一真源是 res://data/rpg/world_encounters.tres；本类只定义结构、字段契约、
##   合法性纯函数与「字段缺失 / 表非法」降级基线，不把任何设计数值写死进代码
##   （@export 默认值 = DEFAULT_* 降级基线，刻意 != 表值，不是设计数值）。
##
## 【分区 id 对齐（任务单 ①「与 Rank-1 的分区 id 对齐」）】
## - region_ids 取既有 godot/data/rpg/m6_area_bindings.tres 的 `region` 字段真值：
##     limgrave / weeping_peninsula / stormveil / siofra_well（4 个 is_dungeon=false
##     的地表/野外区域）。该表是工程内既有、稳定的分区命名来源，逐字对齐、不臆造。
## - ★ 这 4 个 id 仍标 [PLACEHOLDER]：A76（大地图逻辑尺寸 / 分区 id / 相机边界口径，
##   数据驱动）由 Rank-1 world_scale.tres 与 Rank-3 grace_sites.tres 最终落定；若最终
##   口径不同，**只改 world_encounters.tres 的 region_id / region_ids 两处即可对齐，
##   不改代码、不改 service / director**（调参唯一入口，只改表不改代码）。
##
## 【遭遇点 7 字段契约（任务单 ①，全部 [PLACEHOLDER]）】
##   id             : String   遭遇点唯一 id（全表唯一、非空）
##   region_id      : String   所属分区 id，必须 ∈ region_ids（与 Rank-1 分区对齐）
##   position       : Vector2  2.5D 俯视世界坐标（XZ 平面，单位=逻辑像素）
##   enemy_group    : String   敌人组 id（引用既有 enemy/boss 资源 id，不改既有 .tres）
##   trigger_radius : float    进入触发半径（>0 且有限）；距离判定 distance_to <= radius
##   cleared_flag   : bool     表内初始清除标记（首版全 false）；运行时清除态由
##                             WorldEncounterService 实例内维护，★ 不写回本表（I-1）
##   reward_points  : int      触发该遭遇、清波结算后并入的奖励点数（>=0 且为整数）
## 表级：invalid_input_policy : String  异常输入策略；首版唯一合法值 POLICY_REJECT="reject"
##
## 【设计数值 [PLACEHOLDER] rationale（数值实例在 .tres，本块只写「为什么」）】
##   ⚠ 以下全部为 [PLACEHOLDER] 首版假设、待人工试玩校准；只改 .tres 不改代码。
##   ① 4 个分区 / 6 个遭遇点
##      rationale：任务单要求「至少 4 个区域」；每区 1~2 个遭遇点，便于覆盖「同区多遭遇
##      就近触发 / 距离判定 / 已清除区域不重复触发 / 区域进度单调递增」。limgrave 与
##      siofra_well 各 2 个（检验同区多遭遇），weeping_peninsula / stormveil 各 1 个。
##   ② position（(512,384) … (3072,896)）
##      rationale：落在 Rank-1 建议的 4096×2304 逻辑像素大地图内，4 区沿 X 从西到东分散，
##      使「相机随玩家位移」时各区遭遇点有可辨识间隔；纯坐标、不含渲染信息。
##   ③ trigger_radius = 96 / 80 / 112 / 96 / 128 / 128
##      rationale：取 80~128 逻辑像素，配合角色 40% 缩放后的可视范围；各区略有差异便于
##      肉眼区分「半径内触发 / 半径外 no_encounter」。0 或负值被 is_valid() 判非法。
##   ④ reward_points = 80 / 100 / 120 / 150 / 160 / 200
##      rationale：随分区推进递增（对标原作「越深入奖励越高」），但纯展示量纲；
##      ★ 奖励不直接落盘，只在既有清波结算（A55/A57）里并入 base_for_combo 一次，
##      经 combo.settle() -> points_awarded 一次入账，绝不二次入账、不造成点数通胀。
##   ⑤ enemy_group：引用既有 enemy_01_limgrave_soldier / boss_01_margit 的 id 字符串
##      rationale：数据驱动、与既有资源对齐；stormveil / siofra_well_deep 用 boss 组体现
##      区域深度。本表只存 id，不改既有 enemy/boss .tres 的任何数值。
##   ⑥ cleared_flag = false（全表）
##      rationale：首版所有遭遇初始未清除；service.reset() 按本字段初始化本局清除态，
##      使「初始已清区域」也可只改表配置（数据驱动），代码零改动。
##   ⑦ invalid_input_policy = "reject"
##      rationale：异常输入一律拒绝且不改状态，避免 clamp / ignore 造成「隐式触发 /
##      隐式二次清除」的不可测分支；首版只实现 reject，扩展需先补回归再改代码+表+验证。
##
## 【调参唯一入口（只改表不改代码）】
##   godot/data/rpg/world_encounters.tres —— 分区 id / 6 个遭遇点的 7 字段 /
##   invalid_input_policy 全在此一处。校准同步清单：.tres ->
##   verify_world_encounter_v150.gd 的 EXPECT_* -> teamwork/Rank-2/DONE-R38.md 数值拆解表
##   -> 三段门禁；不静默改数、不改本 .gd 的 DEFAULT_* 基线（那是非法输入降级用）。
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- 公开常量（签名稳定）----
## 异常输入策略：首版唯一合法值。WorldEncounterService 拒绝分支据此实现。
const POLICY_REJECT: String = "reject"

## 遭遇点 7 字段（config.is_valid() / service 逐项读表用，签名稳定）。
const ENCOUNTER_FIELDS: PackedStringArray = [
	"id", "region_id", "position", "enemy_group",
	"trigger_radius", "cleared_flag", "reward_points",
]

## ---- [PLACEHOLDER] 降级基线（字段缺失 / 表非法时用，刻意 != 设计数值）----
## 注：policy 的降级基线必须与唯一合法值一致，否则 is_valid() 会判表非法、服务降级；
## 它不参与「DEFAULT_* != 表值」的机器判定（验证脚本只对数值/集合字段做该判定）。
const DEFAULT_REGION_IDS: PackedStringArray = []
const DEFAULT_ENCOUNTERS: Array[Dictionary] = []
const DEFAULT_INVALID_INPUT_POLICY: String = POLICY_REJECT

## 表级字段（@export 默认值 = 降级基线；设计数值在 .tres）。
@export var region_ids: PackedStringArray = DEFAULT_REGION_IDS               # [PLACEHOLDER]
@export var encounters: Array[Dictionary] = DEFAULT_ENCOUNTERS               # [PLACEHOLDER]
@export var invalid_input_policy: String = DEFAULT_INVALID_INPUT_POLICY       # [PLACEHOLDER]


## 全表合法性：分区集合非空且无重复、遭遇点非空且逐行 7 字段类型/取值合法、
## policy == POLICY_REJECT；异常一律 false（不崩、不抛）。
func is_valid() -> bool:
	if region_ids == null or region_ids.is_empty():
		return false
	var seen_regions: Dictionary = {}
	for r: String in region_ids:
		if r.is_empty() or seen_regions.has(r):
			return false
		seen_regions[r] = true
	if encounters == null or encounters.is_empty():
		return false
	var seen_ids: Dictionary = {}
	for entry: Variant in encounters:
		if typeof(entry) != TYPE_DICTIONARY:
			return false
		var e: Dictionary = entry as Dictionary
		for f: String in ENCOUNTER_FIELDS:
			if not e.has(f):
				return false
		var eid: Variant = e["id"]
		var rid: Variant = e["region_id"]
		var pos: Variant = e["position"]
		var grp: Variant = e["enemy_group"]
		var rad: Variant = e["trigger_radius"]
		var clr: Variant = e["cleared_flag"]
		var rew: Variant = e["reward_points"]
		if typeof(eid) != TYPE_STRING or String(eid).is_empty():
			return false
		if seen_ids.has(String(eid)):
			return false
		seen_ids[String(eid)] = true
		if typeof(rid) != TYPE_STRING or not seen_regions.has(String(rid)):
			return false
		if typeof(pos) != TYPE_VECTOR2:
			return false
		var pv: Vector2 = pos as Vector2
		if is_nan(pv.x) or is_nan(pv.y) or is_inf(pv.x) or is_inf(pv.y):
			return false
		if typeof(grp) != TYPE_STRING or String(grp).is_empty():
			return false
		if not _is_finite_number(rad) or float(rad) <= 0.0:
			return false
		if typeof(clr) != TYPE_BOOL:
			return false
		if not _is_finite_number(rew):
			return false
		var rw: float = float(rew)
		if rw < 0.0 or not is_equal_approx(rw, floorf(rw)):
			return false
	if typeof(invalid_input_policy) != TYPE_STRING:
		return false
	return String(invalid_input_policy) == POLICY_REJECT


func _is_finite_number(v: Variant) -> bool:
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return false
	var f: float = float(v)
	return not (is_nan(f) or is_inf(f))


## ---- 只读 getter（全静态类型；数值来自表，代码不写死设计值）----
func get_region_ids() -> PackedStringArray:
	return region_ids.duplicate()


## 返回遭遇点的深拷贝（外层数组 duplicate + 每行 Dictionary duplicate），
## ★ 服务只读、绝不写回表（I-1：运行时清除态在 service 实例内，不改 .tres）。
func get_encounters() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Variant in encounters:
		out.append((e as Dictionary).duplicate())
	return out


func get_region_count() -> int:
	return region_ids.size()


func get_encounter_count() -> int:
	return encounters.size()


func get_invalid_input_policy() -> String:
	return String(invalid_input_policy)


func has_region(region_id: String) -> bool:
	return region_ids.has(region_id)
