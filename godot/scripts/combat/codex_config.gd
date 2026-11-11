extends Resource
class_name CodexConfig

## ===========================================================================
## R30 / v0.8.0 · 赐福图鉴「成就数据表」资源（Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261111-125001-351-A2）
## 目录所有权：本文件 / godot/data/rpg/codex_entries.tres /
##   verify_codex_reward_v080.gd / step_index 三态补跑 / teamwork/Rank-2/ 归 Rank-2。
##   codex_director.gd / hud.gd / presentation.gd / verify_codex_v080.gd 归 Rank-1；
##   CODEX-GDD.md / WAVE-TRIAL-GDD.md §10.8 / 00-协作契约.md §3.3 / README 归 Rank-3。
##   场景 / 素材 / 契约 / README / 其余 .tres / project.godot / 导演脚本 一律不碰。
##
## 【设计口径】
## - 数值唯一真源是 res://data/rpg/codex_entries.tres（4 项实例）；本类只定义结构、
##   condition_kind 白名单、「条件求值」纯函数与「字段缺失 / 空表」降级基线，
##   不把任何设计数值写死进代码。
## - condition_kind 只用既有 flag 语义三态（不发明新条件类型）：
##     bool_true     某 bool 型三段式 flag 为 true；
##                   condition_value = {"flag": "<三段式 key>"}
##     int_at_least  某 int 型三段式 flag >= 阈值；
##                   condition_value = {"flag": "<三段式 key>", "threshold": <int>}
##     all_of        多个 bool 型三段式 flag 全部为 true；
##                   condition_value = {"flags": ["<key>", ...]}
##   条件只引用既有登记 flag（REGISTERED_FLAGS，均由既有生产逻辑写入），保证「条件可达」。
## - 成就解锁 flag 用裁决 A36 三段式 grace.codex_<id>.unlocked（id 下划线连接、
##   沿用 A23）；本文件只产出成就 id，不写 flag（写归 Rank-1 codex_director.gd）。
## - 存储层 @export entries: Array[Dictionary]：沿用 R26 / R27 / R28 实证结论 ——
##   Godot 4.7.2 内部类 Resource 实例无法正确序列化进 .tres，故 .tres 每项用 Dictionary，
##   由 get_entry() 在运行时包装成静态类型视图 CodexEntry。
## - 全静态类型，引擎 Godot 4.7.2 / GDScript。
##
## 【设计数值 [PLACEHOLDER] rationale（数值实例在 .tres，本块只写「为什么」）】
##   奖励点数 30 / 50 / 80 / 120（任务单给定首版，全部 [PLACEHOLDER] 待人工试玩校准）：
##   ① tutorial_complete（教学完成，bool_true，30）：最易达成，用最小正反馈建立
##      「图鉴可收集」认知；与教学三步 20/30/50 同量级但略低，避免开局点数通胀。
##   ② wave_trial_clear（三波全清，bool_true，50）：一次性永久成就，难度高于教学，
##      奖励递增；与波次 100/150/200 产出相比只是小额补充，不喧宾夺主。
##   ③ all_grace_upgrades（三项增益全解锁，all_of，80）：需消耗既有 100/200/300
##      共 600 点成长成本，是最长线的收集目标，奖励继续递增但不带经济杠杆。
##   ④ best_wave_3（最高波次 >=3，int_at_least，120）：顶端挑战，四项最难、奖励最高。
##   梯度 30<50<80<120 严格单调且合计 280；刻意低于既有单轮三波产出 450，
##   使图鉴是「留存钩子 / 小额补贴」而非第二套点数来源（防奖励通胀）。
##   threshold=3 与既有三波结构一致（best_wave 理论上限 3），保证条件可达；
##   若后续扩波需在 .tres 同步阈值，不静默改数。
##
## 【调参唯一入口】
##   godot/data/rpg/codex_entries.tres —— 4 项成就的 id / title / description /
##   condition_kind / condition_value / reward_points 全在此一处。
##   校准同步清单：.tres → verify_codex_reward_v080.gd 的 EXPECT_* →
##   teamwork/Rank-2/CODEX-TUNING.md → DONE-R30.md → 三段门禁；不静默改数。
##   .gd 里的 DEFAULT_* 只是字段缺失时的非法占位基线，不是设计数值。
## ===========================================================================

## ---- condition_kind 既有 flag 语义白名单（只用这三种，不新增条件类型）----
const COND_BOOL_TRUE: String = "bool_true"
const COND_INT_AT_LEAST: String = "int_at_least"
const COND_ALL_OF: String = "all_of"
const KNOWN_CONDITION_KINDS: PackedStringArray = [
	COND_BOOL_TRUE, COND_INT_AT_LEAST, COND_ALL_OF
]

## 三段式 flag 正则（与 world_state.gd FLAG_KEY_REGEX 同口径）。
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"

## 成就条件允许引用的既有登记 flag（均由既有生产逻辑写入，保证「条件可达」）：
##   grace.tutorial.completed       教学完成（Rank-1 tutorial_director.gd）
##   dungeon.wave_trial.completed   三波全清（Rank-1 wave_trial_director.gd）
##   dungeon.wave_trial.best_wave   最高波次（同上）
##   grace.upgrade_<id>.unlocked    三项赐福增益解锁（R28 收敛后唯一权威件）
const REGISTERED_FLAGS: PackedStringArray = [
	"grace.tutorial.completed",
	"dungeon.wave_trial.completed",
	"dungeon.wave_trial.best_wave",
	"grace.upgrade_hp_max_bonus.unlocked",
	"grace.upgrade_roll_iframe_bonus.unlocked",
	"grace.upgrade_attack_power_bonus.unlocked",
]

## ---- [PLACEHOLDER] 降级基线（仅用于字段缺失 / 空表，不是设计数值）----
const DEFAULT_ID: String = ""                  # [PLACEHOLDER] 空 id 判非法
const DEFAULT_TITLE: String = ""               # [PLACEHOLDER] 空标题判非法
const DEFAULT_DESCRIPTION: String = ""         # [PLACEHOLDER] 空描述判非法
const DEFAULT_CONDITION_KIND: String = ""      # [PLACEHOLDER] 空 kind 不在白名单判非法
const DEFAULT_REWARD_POINTS: int = 0           # [PLACEHOLDER] 0 奖励判非法，避免凭空刷点

## 每项「静态类型视图」：仅在运行时由 get_entry() 构造，不参与 .tres 序列化。
## 6 个字段全静态类型；默认值均为 [PLACEHOLDER] 降级基线。
class CodexEntry extends Resource:
	@export var id: String = ""                       # [PLACEHOLDER]
	@export var title: String = ""                    # [PLACEHOLDER]
	@export var description: String = ""              # [PLACEHOLDER]
	@export var condition_kind: String = ""           # [PLACEHOLDER] bool_true / int_at_least / all_of
	@export var condition_value: Dictionary = {}      # [PLACEHOLDER] 条件参数（引用既有 flag）
	@export var reward_points: int = 0                # [PLACEHOLDER] 解锁奖励点数

## 4 项成就结构（任务单 ①「id / title / description / condition_kind /
## condition_value / reward_points」）。
@export var entries: Array[Dictionary] = []


## 工厂：返回一行 Dictionary（.tres 存储单元）；不硬编码任何设计数值，数值由调用方传入。
func make_entry(
	p_id: String,
	p_title: String,
	p_description: String,
	p_condition_kind: String,
	p_condition_value: Dictionary,
	p_reward_points: int) -> Dictionary:
	return {
		"id": p_id,
		"title": p_title,
		"description": p_description,
		"condition_kind": p_condition_kind,
		"condition_value": p_condition_value,
		"reward_points": p_reward_points,
	}


## 字段缺失降级：Dictionary 缺 key / 类型异常时回落到 [PLACEHOLDER] 基线，不抛错。
func entry_from_dict(d: Dictionary) -> CodexEntry:
	var e: CodexEntry = CodexEntry.new()
	e.id = str(d.get("id", DEFAULT_ID))
	e.title = str(d.get("title", DEFAULT_TITLE))
	e.description = str(d.get("description", DEFAULT_DESCRIPTION))
	e.condition_kind = str(d.get("condition_kind", DEFAULT_CONDITION_KIND))
	var cv: Variant = d.get("condition_value", {})
	if typeof(cv) == TYPE_DICTIONARY:
		e.condition_value = (cv as Dictionary).duplicate(true)
	else:
		e.condition_value = {}
	e.reward_points = int(d.get("reward_points", DEFAULT_REWARD_POINTS))
	return e


## 越界 / 行类型异常拒绝：返回 null 或非法空视图，不崩、不回绕。
func get_entry(index: int) -> CodexEntry:
	if index < 0 or index >= entries.size():
		return null
	var row: Variant = entries[index]
	if typeof(row) != TYPE_DICTIONARY:
		return CodexEntry.new()
	return entry_from_dict(row as Dictionary)


func entry_count() -> int:
	return entries.size()


## ---- 条件结构 / 求值（纯函数，不碰 WorldState、不写盘）----

static func is_condition_kind_known(kind: String) -> bool:
	return KNOWN_CONDITION_KINDS.has(kind)


static func flag_key_is_valid(key: String) -> bool:
	var re: RegEx = RegEx.new()
	re.compile(FLAG_KEY_REGEX)
	return re.search(key) != null


## condition_value 结构合法性：三种 kind 各自的字段形状 + flag 三段式 + 阈值非负。
static func is_condition_shape_valid(kind: String, value: Variant) -> bool:
	if not is_condition_kind_known(kind):
		return false
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = value as Dictionary
	match kind:
		COND_BOOL_TRUE:
			if not d.has("flag") or typeof(d.get("flag")) != TYPE_STRING:
				return false
			return flag_key_is_valid(str(d.get("flag")))
		COND_INT_AT_LEAST:
			if not d.has("flag") or not d.has("threshold"):
				return false
			if typeof(d.get("flag")) != TYPE_STRING or not flag_key_is_valid(str(d.get("flag"))):
				return false
			var t: Variant = d.get("threshold")
			if typeof(t) != TYPE_INT and typeof(t) != TYPE_FLOAT:
				return false
			return int(t) >= 0
		COND_ALL_OF:
			if not d.has("flags") or typeof(d.get("flags")) != TYPE_ARRAY:
				return false
			var list: Array = d.get("flags") as Array
			if list.is_empty():
				return false
			for v: Variant in list:
				if typeof(v) != TYPE_STRING or not flag_key_is_valid(str(v)):
					return false
			return true
	return false


## 提取条件引用的全部 flag key（供「条件可达 / 三段式」校验；结构非法返回空数组）。
static func condition_flag_keys(kind: String, value: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(value) != TYPE_DICTIONARY:
		return out
	var d: Dictionary = value as Dictionary
	match kind:
		COND_BOOL_TRUE, COND_INT_AT_LEAST:
			if d.has("flag") and typeof(d.get("flag")) == TYPE_STRING:
				out.append(str(d.get("flag")))
		COND_ALL_OF:
			if d.has("flags") and typeof(d.get("flags")) == TYPE_ARRAY:
				for v: Variant in (d.get("flags") as Array):
					if typeof(v) == TYPE_STRING:
						out.append(str(v))
	return out


## 纯求值：按 kind 从 flags 快照判定条件是否达成；非法输入一律 false、不抛错。
static func evaluate_condition(kind: String, value: Variant, flags: Dictionary) -> bool:
	if not is_condition_shape_valid(kind, value):
		return false
	var d: Dictionary = value as Dictionary
	match kind:
		COND_BOOL_TRUE:
			return bool(flags.get(str(d.get("flag")), false)) == true
		COND_INT_AT_LEAST:
			return int(flags.get(str(d.get("flag")), 0)) >= int(d.get("threshold"))
		COND_ALL_OF:
			for v: Variant in (d.get("flags") as Array):
				if not bool(flags.get(str(v), false)):
					return false
			return true
	return false


## 单项合法性：6 字段齐全非空、kind 命中白名单、condition_value 结构合法、
## 引用 flag 全为既有登记 flag（条件可达）、reward_points > 0。
func is_entry_valid(e: CodexEntry) -> bool:
	if e == null:
		return false
	if e.id.is_empty() or e.title.is_empty() or e.description.is_empty():
		return false
	if not is_condition_kind_known(e.condition_kind):
		return false
	if not is_condition_shape_valid(e.condition_kind, e.condition_value):
		return false
	for k: String in condition_flag_keys(e.condition_kind, e.condition_value):
		if not REGISTERED_FLAGS.has(k):
			return false
	if e.reward_points <= 0:
		return false
	return true


## 4 项奖励合计（只读聚合，供 verify / 装配层核对，不改状态）。
func total_reward_points() -> int:
	var total: int = 0
	for i: int in range(entries.size()):
		var e: CodexEntry = get_entry(i)
		if e != null:
			total += e.reward_points
	return total


## 奖励单调：严格递增（首版 30<50<80<120）；非单调或空表返回 false。
func is_reward_monotonic() -> bool:
	if entries.size() < 2:
		return false
	var prev: int = -1
	for i: int in range(entries.size()):
		var e: CodexEntry = get_entry(i)
		if e == null:
			return false
		if i > 0 and e.reward_points <= prev:
			return false
		prev = e.reward_points
	return true
