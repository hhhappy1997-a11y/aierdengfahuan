extends Resource
class_name BoonDraftConfig

## ===========================================================================
## R32 / v0.10.0 · 战后赐福抉择 Boon Draft「数据表」资源（Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-074023-393-A2）
## 目录所有权·R32 冻结：本文件 / godot/data/rpg/boon_draft.tres /
##   boon_draft_service.gd / verify_boon_draft_v100.gd / teamwork/Rank-2/ 归 Rank-2。
##   encounter_director.gd（唯一写入方 Rank-1）/ hud.gd / impact_feedback.gd /
##   场景 / 素材 / 既有 .tres / 其它 Rank 文件一律只读、不改。
##
## 【纯逻辑边界（任务单 ①）】
## - 本类是数据表结构，不含结算逻辑；不继承 Node、不碰场景树、不 add_child、
##   不读写存档文件（I-1）、不碰渲染、不 load 任何资源。
## - 数值唯一真源是 res://data/rpg/boon_draft.tres（3 个候选实例）；本类只定义
##   结构、字段白名单、合法性纯函数与「字段缺失 / 空表」降级基线，不把任何设计
##   数值写死进代码（DEFAULT_* 只是非法降级基线，不是设计数值）。
## - 沿用 R26~R31 实证结论：Godot 4.7.2 内部类 Resource 实例无法正确序列化进
##   .tres，故 .tres 每项用 Dictionary，由 get_boon() 在运行时包装成静态类型
##   视图 BoonDraftConfig.Boon。
##
## 【8 字段契约（任务单 ①）】
##   id / title / description / effect_key / effect_value /
##   cost_key / cost_value / exclusive_group
## - effect_key 白名单：hp_restore（生命回复）/ poise_damage_bonus（削韧强化）/
##   points_bonus（点数加成）—— 三个候选各占其一。
## - cost_key 白名单：hp_scale（下一波敌人生命上限倍率）/
##   telegraph_scale（下一波敌人出招前摇倍率）—— 代价只作用于「下一波」。
## - exclusive_group 白名单：recovery（资源/回复类）/ tempo（节奏/操作类）。
##   候选 0「生机涌流」与候选 2「恩典供奉」同属 recovery 互斥，防单波资源双收；
##   候选 1「破势锋芒」属 tempo 独立组。互斥/重复选择拒绝由 boon_draft_service.gd
##   执行；本类只校验 group 命中白名单。
##
## 【设计数值 [PLACEHOLDER] rationale（数值实例在 .tres，本块只写「为什么」）】
##   ⚠ 以下全部为 [PLACEHOLDER] 首版假设、待人工试玩校准；只改 .tres 不改代码。
##   ① boon_01_vigor_mend「赐福·生机涌流」 effect=hp_restore 40.0
##      cost=hp_scale 1.15  group=recovery
##      rationale：清波后立即回血是最直接的续航收益，配「下一波敌人 +15% HP」把
##      续航换成硬仗，避免白拿；回血量取单波受击量的同量级（[PLACEHOLDER] 40）。
##   ② boon_02_poise_edge「赐福·破势锋芒」 effect=poise_damage_bonus 0.25
##      cost=telegraph_scale 0.85  group=tempo
##      rationale：+25% 削韧让玩家更快打出机制 B 的处决窗口，属操作向增益；
##      代价是「下一波前摇 ×0.85」（出招更快、闪避容错更低），把收益转成压力，
##      不与 hp_scale 叠加，避免难度双重放大。
##   ③ boon_03_grace_tribute「赐福·恩典供奉」 effect=points_bonus 60.0
##      cost=hp_scale 1.20  group=recovery
##      rationale：+60 赐福点数加速长期成长（R27 赐福成长出口），代价略高于回血
##      项（1.20 > 1.15），因点数可跨波累积、比一次性回血更「值钱」；与候选 0
##      同属 recovery 互斥，防「回血 + 拿点」单波资源双收导致奖励通胀。
##   effect_value 恒 > 0（只给增益不倒扣）、cost_value 恒 > 0（代价必存在），
##   二者成对生效；hp_scale > 1 表示敌人更肉、telegraph_scale < 1 表示前摇更短，
##   均为「下一波」乘性修正，取值语义写死在表说明、数值随表变化。
##
## 【调参唯一入口（只改表不改代码）】
##   godot/data/rpg/boon_draft.tres —— 3 候选的
##   id / title / description / effect_key / effect_value /
##   cost_key / cost_value / exclusive_group 全在此一处。
##   校准同步清单：.tres -> verify_boon_draft_v100.gd 的 EXPECT_* ->
##   teamwork/Rank-2/DONE-R32.md 数值拆解表 -> 三段门禁；
##   不静默改数、不改本 .gd 的 DEFAULT_* 基线（那是非法输入降级用，不是设计数值）。
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- 词条 id / 效果 / 代价 / 互斥组白名单（数据驱动的结构约束，不是设计数值）----
const KNOWN_IDS: PackedStringArray = [
	"boon_01_vigor_mend", "boon_02_poise_edge", "boon_03_grace_tribute",
]
const KNOWN_EFFECT_KEYS: PackedStringArray = [
	"hp_restore", "poise_damage_bonus", "points_bonus",
]
const KNOWN_COST_KEYS: PackedStringArray = ["hp_scale", "telegraph_scale"]
const KNOWN_GROUPS: PackedStringArray = ["recovery", "tempo"]

## ---- [PLACEHOLDER] 降级基线（仅用于字段缺失 / 空表，不是设计数值）----
const DEFAULT_ID: String = ""                         # [PLACEHOLDER] 空 id 判非法
const DEFAULT_TITLE: String = ""                      # [PLACEHOLDER]
const DEFAULT_DESCRIPTION: String = ""                # [PLACEHOLDER]
const DEFAULT_EFFECT_KEY: String = ""                 # [PLACEHOLDER] 空 key 判非法
const DEFAULT_EFFECT_VALUE: float = 0.0               # [PLACEHOLDER] 0 判非法（增益必 >0）
const DEFAULT_COST_KEY: String = ""                   # [PLACEHOLDER] 空 key 判非法
const DEFAULT_COST_VALUE: float = 0.0                 # [PLACEHOLDER] 0 判非法（代价必 >0）
const DEFAULT_EXCLUSIVE_GROUP: String = ""            # [PLACEHOLDER] 空组判非法

## 每项「静态类型视图」：仅在运行时由 get_boon() 构造，不参与 .tres 序列化。
## 8 个字段全静态类型；默认值均为 [PLACEHOLDER] 降级基线。
class Boon extends Resource:
	@export var id: String = ""                        # [PLACEHOLDER]
	@export var title: String = ""                     # [PLACEHOLDER]
	@export var description: String = ""               # [PLACEHOLDER]
	@export var effect_key: String = ""                # [PLACEHOLDER]
	@export var effect_value: float = 0.0              # [PLACEHOLDER]
	@export var cost_key: String = ""                  # [PLACEHOLDER]
	@export var cost_value: float = 0.0                # [PLACEHOLDER]
	@export var exclusive_group: String = ""           # [PLACEHOLDER]

## 3 项候选结构（任务单 ① 的 8 字段）。
@export var boons: Array[Dictionary] = []


## 工厂：返回一行 Dictionary（.tres 存储单元）；不硬编码任何设计数值，数值由调用方传入。
func make_boon(
	p_id: String,
	p_title: String,
	p_description: String,
	p_effect_key: String,
	p_effect_value: float,
	p_cost_key: String,
	p_cost_value: float,
	p_exclusive_group: String) -> Dictionary:
	return {
		"id": p_id,
		"title": p_title,
		"description": p_description,
		"effect_key": p_effect_key,
		"effect_value": p_effect_value,
		"cost_key": p_cost_key,
		"cost_value": p_cost_value,
		"exclusive_group": p_exclusive_group,
	}


## 字段缺失降级：Dictionary 缺 key / 类型异常时回落到 [PLACEHOLDER] 基线，不抛错。
func boon_from_dict(d: Dictionary) -> Boon:
	var b: Boon = Boon.new()
	b.id = str(d.get("id", DEFAULT_ID))
	b.title = str(d.get("title", DEFAULT_TITLE))
	b.description = str(d.get("description", DEFAULT_DESCRIPTION))
	b.effect_key = str(d.get("effect_key", DEFAULT_EFFECT_KEY))
	b.effect_value = _num(d.get("effect_value", DEFAULT_EFFECT_VALUE), DEFAULT_EFFECT_VALUE)
	b.cost_key = str(d.get("cost_key", DEFAULT_COST_KEY))
	b.cost_value = _num(d.get("cost_value", DEFAULT_COST_VALUE), DEFAULT_COST_VALUE)
	b.exclusive_group = str(d.get("exclusive_group", DEFAULT_EXCLUSIVE_GROUP))
	return b


## 数值容错：仅 int/float 可转 float，其余回落基线（防类型异常把数值污染成 0 / 负）。
static func _num(v: Variant, fallback: float) -> float:
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return float(v)
	return fallback


## 越界 / 行类型异常拒绝：返回 null 或非法空视图，不崩、不回绕。
func get_boon(index: int) -> Boon:
	if index < 0 or index >= boons.size():
		return null
	var row: Variant = boons[index]
	if typeof(row) != TYPE_DICTIONARY:
		return Boon.new()
	return boon_from_dict(row as Dictionary)


func boon_count() -> int:
	return boons.size()


## 按 id 查候选视图（找不到返回 null）；服务层合法性依赖此函数。
func find_boon_by_id(id: String) -> Boon:
	for i: int in range(boons.size()):
		var b: Boon = get_boon(i)
		if b != null and b.id == id:
			return b
	return null


static func is_id_known(id: String) -> bool:
	return KNOWN_IDS.has(id)


static func is_effect_key_known(k: String) -> bool:
	return KNOWN_EFFECT_KEYS.has(k)


static func is_cost_key_known(k: String) -> bool:
	return KNOWN_COST_KEYS.has(k)


static func is_group_known(g: String) -> bool:
	return KNOWN_GROUPS.has(g)


## 单项合法性：8 字段齐全非空、effect_key / cost_key / group 命中白名单、
## effect_value > 0 且 cost_value > 0（代价与增益成对且均为正，缺一即非法）。
func is_boon_valid(b: Boon) -> bool:
	if b == null:
		return false
	if b.id.is_empty() or b.title.is_empty() or b.description.is_empty():
		return false
	if not is_id_known(b.id):
		return false
	if not is_effect_key_known(b.effect_key):
		return false
	if not is_cost_key_known(b.cost_key):
		return false
	if not is_group_known(b.exclusive_group):
		return false
	if b.effect_value <= 0.0:
		return false
	if b.cost_value <= 0.0:
		return false
	return true


## 全表合法性：恰好 3 项、三项合法、三个 effect_key 互异（三候选各占一种增益）。
## 空表 / 缺项 / 复制粘贴错配返回 false。
func is_boon_set_valid() -> bool:
	if boons.size() != KNOWN_IDS.size():
		return false
	var seen_effects: Dictionary = {}
	for i: int in range(boons.size()):
		var b: Boon = get_boon(i)
		if b == null or not is_boon_valid(b):
			return false
		if seen_effects.has(b.effect_key):
			return false
		seen_effects[b.effect_key] = true
	return true


## 分组视图：group -> 该组候选 id 数组（供「互斥组」机器判定，不改状态）。
func group_to_ids() -> Dictionary:
	var out: Dictionary = {}
	for i: int in range(boons.size()):
		var b: Boon = get_boon(i)
		if b == null:
			continue
		if not out.has(b.exclusive_group):
			out[b.exclusive_group] = []
		(out[b.exclusive_group] as Array).append(b.id)
	return out
