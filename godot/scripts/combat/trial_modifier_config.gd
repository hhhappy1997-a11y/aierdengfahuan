extends Resource
class_name TrialModifierConfig

## ===========================================================================
## R31 / v0.9.0 · 试炼词条「数据表」资源（Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261111-133549-883-A2）
## 目录所有权·R31：本文件 / godot/data/rpg/trial_modifiers.tres /
##   trial_modifier_service.gd / verify_trial_modifier_v090.gd /
##   verify_codex_full_wish_v090.gd / teamwork/Rank-2/ 归 Rank-2。
##   既有 .tres / 导演层 / hud.gd / 场景 / 素材 / 其它 Rank 文件一律只读、不改。
##
## 【设计口径：数据驱动 / 只改表不改代码】
## - 数值唯一真源是 res://data/rpg/trial_modifiers.tres（3 项实例）；本类只定义
##   结构、字段白名单、「合法性」纯函数与「字段缺失 / 空表」降级基线，
##   不把任何设计数值写死进代码（DEFAULT_* 只是非法降级基线，不是设计数值）。
## - 沿用 R26~R30 实证结论：Godot 4.7.2 内部类 Resource 实例无法正确序列化进
##   .tres，故 .tres 每项用 Dictionary，由 get_modifier() 在运行时包装成静态类型
##   视图 TrialModifier。
## - 3 个可选词条：no_hit / time_pressure / low_vigor。
## - exclusive_group 互斥分组：
##     no_hit / low_vigor  -> "survival"（生存限制类，二者不可叠加：
##                            防「条件不可达」与「奖励通胀」）
##     time_pressure       -> "tempo"（节奏类，可与 survival 组任一共存）
##   选择合法性 / 互斥组拒绝由 trial_modifier_service.gd 执行；本类只校验
##   group 命中白名单。
## - 条件语义（由词条 id 固定分派，数值阈值全部来自本表，不在代码写死）：
##     no_hit        : stats.damage_taken <= 0
##                     （无伤 = 0 次受击；本词条不改时限/血量，故 scale 均 1.0）
##     time_pressure : stats.elapsed_sec <= stats.time_limit_sec * time_limit_scale
##                     （time_limit_scale < 1 压缩时限，阈值随表变化）
##     low_vigor     : stats.hp_ratio <= hp_scale
##                     （hp_scale < 1 压低起始血量，结算时血量比例不高于该阈值）
##   stats 字段缺失 / 类型异常 -> 条件判「未达成」-> 回落基础结算，不惩罚、不崩。
## - 全静态类型，引擎 Godot 4.7.2 / GDScript。
##
## 【设计数值 [PLACEHOLDER] rationale（数值实例在 .tres，本块只写「为什么」）】
##   ⚠ 以下全部为 [PLACEHOLDER] 首版假设、待人工试玩校准；只改 .tres 不改代码。
##   ① no_hit        reward_multiplier=1.5  time_limit_scale=1.0  hp_scale=1.0
##      group=survival。rationale：无伤是最高操作门槛，给三档里最高倍率；
##      不加时限/血量限制，避免与其它难度叠加把条件推到不可达。
##   ② time_pressure reward_multiplier=1.3  time_limit_scale=0.6  hp_scale=1.0
##      group=tempo。rationale：把既有 30s 时限压缩到 60%（0.6），是「节奏」
##      压力而非「生存」压力；倍率低于无伤（限时可通过背板熟悉路线），
##      单独成组允许与 survival 词条共存，但共存时倍率取 max 不叠乘（防通胀）。
##   ③ low_vigor     reward_multiplier=1.4  time_limit_scale=1.0  hp_scale=0.5
##      group=survival。rationale：起始血量压到 50%（0.5），风险介于无伤与
##      限时之间，倍率 1.4 居中；与 no_hit 同属 survival 组互斥，避免
##      「无伤 + 半血」双重生存限制叠加导致条件不可达。
##   梯度 1.5（无伤） > 1.4（低血量） > 1.3（限时）与达成难度同向，三者互异
##   且均 >= 1.0，保证「奖励单调不减 / 余额非负」——词条只加成、绝不扣减
##   基础点数。time_limit_scale / hp_scale 取值 (0, 1]；配套 1.0 表示
##   「不改动该维度」。
##
## 【调参唯一入口】
##   godot/data/rpg/trial_modifiers.tres —— 3 词条的
##   id / title / description / reward_multiplier / time_limit_scale /
##   hp_scale / exclusive_group 全在此一处。
##   校准同步清单：.tres -> verify_trial_modifier_v090.gd 的 EXPECT_* ->
##   teamwork/Rank-2/TRIAL-MODIFIER-TUNING.md -> DONE-R31.md -> 三段门禁；
##   不静默改数、不改本 .gd 的 DEFAULT_* 基线（那是非法输入降级用，不是设计数值）。
## ===========================================================================

## ---- 词条 id / 互斥组白名单（数据驱动的结构约束，不是设计数值）----
const KNOWN_IDS: PackedStringArray = ["no_hit", "time_pressure", "low_vigor"]
const KNOWN_GROUPS: PackedStringArray = ["survival", "tempo"]

## 三段式 flag 正则（与 world_state.gd FLAG_KEY_REGEX 同口径，供 verify 引用）。
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"

## ---- [PLACEHOLDER] 降级基线（仅用于字段缺失 / 空表，不是设计数值）----
const DEFAULT_ID: String = ""                          # [PLACEHOLDER] 空 id 判非法
const DEFAULT_TITLE: String = ""                       # [PLACEHOLDER]
const DEFAULT_DESCRIPTION: String = ""                 # [PLACEHOLDER]
const DEFAULT_REWARD_MULTIPLIER: float = 1.0           # [PLACEHOLDER] 1.0 = 不加成（非法基线）
const DEFAULT_TIME_LIMIT_SCALE: float = 1.0            # [PLACEHOLDER] 1.0 = 不压缩时限
const DEFAULT_HP_SCALE: float = 1.0                    # [PLACEHOLDER] 1.0 = 不压低血量
const DEFAULT_EXCLUSIVE_GROUP: String = ""             # [PLACEHOLDER] 空组判非法

## 每项「静态类型视图」：仅在运行时由 get_modifier() 构造，不参与 .tres 序列化。
## 7 个字段全静态类型；默认值均为 [PLACEHOLDER] 降级基线。
class TrialModifier extends Resource:
	@export var id: String = ""                            # [PLACEHOLDER]
	@export var title: String = ""                         # [PLACEHOLDER]
	@export var description: String = ""                   # [PLACEHOLDER]
	@export var reward_multiplier: float = 1.0             # [PLACEHOLDER]
	@export var time_limit_scale: float = 1.0              # [PLACEHOLDER]
	@export var hp_scale: float = 1.0                      # [PLACEHOLDER]
	@export var exclusive_group: String = ""               # [PLACEHOLDER]

## 3 项词条结构（任务单 ① 的 7 字段）。
@export var modifiers: Array[Dictionary] = []


## 工厂：返回一行 Dictionary（.tres 存储单元）；不硬编码任何设计数值，数值由调用方传入。
func make_modifier(
	p_id: String,
	p_title: String,
	p_description: String,
	p_reward_multiplier: float,
	p_time_limit_scale: float,
	p_hp_scale: float,
	p_exclusive_group: String) -> Dictionary:
	return {
		"id": p_id,
		"title": p_title,
		"description": p_description,
		"reward_multiplier": p_reward_multiplier,
		"time_limit_scale": p_time_limit_scale,
		"hp_scale": p_hp_scale,
		"exclusive_group": p_exclusive_group,
	}


## 字段缺失降级：Dictionary 缺 key / 类型异常时回落到 [PLACEHOLDER] 基线，不抛错。
func modifier_from_dict(d: Dictionary) -> TrialModifier:
	var m: TrialModifier = TrialModifier.new()
	m.id = str(d.get("id", DEFAULT_ID))
	m.title = str(d.get("title", DEFAULT_TITLE))
	m.description = str(d.get("description", DEFAULT_DESCRIPTION))
	m.reward_multiplier = _num(d.get("reward_multiplier", DEFAULT_REWARD_MULTIPLIER), DEFAULT_REWARD_MULTIPLIER)
	m.time_limit_scale = _num(d.get("time_limit_scale", DEFAULT_TIME_LIMIT_SCALE), DEFAULT_TIME_LIMIT_SCALE)
	m.hp_scale = _num(d.get("hp_scale", DEFAULT_HP_SCALE), DEFAULT_HP_SCALE)
	m.exclusive_group = str(d.get("exclusive_group", DEFAULT_EXCLUSIVE_GROUP))
	return m


## 数值容错：仅 int/float 可转 float，其余回落基线（防类型异常把数值污染成 0 / 负）。
static func _num(v: Variant, fallback: float) -> float:
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return float(v)
	return fallback


## 越界 / 行类型异常拒绝：返回 null 或非法空视图，不崩、不回绕。
func get_modifier(index: int) -> TrialModifier:
	if index < 0 or index >= modifiers.size():
		return null
	var row: Variant = modifiers[index]
	if typeof(row) != TYPE_DICTIONARY:
		return TrialModifier.new()
	return modifier_from_dict(row as Dictionary)


func modifier_count() -> int:
	return modifiers.size()


## 按 id 查词条视图（找不到返回 null）；服务层 select() 的合法性依赖此函数。
func find_modifier_by_id(id: String) -> TrialModifier:
	for i: int in range(modifiers.size()):
		var m: TrialModifier = get_modifier(i)
		if m != null and m.id == id:
			return m
	return null


static func is_id_known(id: String) -> bool:
	return KNOWN_IDS.has(id)


static func is_group_known(g: String) -> bool:
	return KNOWN_GROUPS.has(g)


## 单项合法性：7 字段齐全非空、id / group 命中白名单、倍率 >= 1（奖励单调不减）、
## 两个 scale 落在 (0, 1] 区间（只允许压缩/不变，不允许放大或取负）。
func is_modifier_valid(m: TrialModifier) -> bool:
	if m == null:
		return false
	if m.id.is_empty() or m.title.is_empty() or m.description.is_empty():
		return false
	if not is_id_known(m.id):
		return false
	if not is_group_known(m.exclusive_group):
		return false
	if m.reward_multiplier < 1.0:
		return false
	if m.time_limit_scale <= 0.0 or m.time_limit_scale > 1.0:
		return false
	if m.hp_scale <= 0.0 or m.hp_scale > 1.0:
		return false
	return true


## 全表倍率集合合法：3 项倍率均 >= 1.0 且两两互异（三档难度区分，防复制粘贴错配）。
## 空表 / 缺项返回 false。
func is_multiplier_set_valid() -> bool:
	if modifiers.size() != KNOWN_IDS.size():
		return false
	var seen: Dictionary = {}
	for i: int in range(modifiers.size()):
		var m: TrialModifier = get_modifier(i)
		if m == null or m.reward_multiplier < 1.0:
			return false
		if seen.has(m.reward_multiplier):
			return false
		seen[m.reward_multiplier] = true
	return true


## 分组视图：group -> 该组词条 id 数组（供「互斥组」机器判定，不改状态）。
func group_to_ids() -> Dictionary:
	var out: Dictionary = {}
	for i: int in range(modifiers.size()):
		var m: TrialModifier = get_modifier(i)
		if m == null:
			continue
		if not out.has(m.exclusive_group):
			out[m.exclusive_group] = []
		(out[m.exclusive_group] as Array).append(m.id)
	return out
