extends Resource
class_name ComboConfig

## ===========================================================================
## R34 / v0.11.0「玩法闭合 · 连击评价」· Combo Rank 规则数据表资源（Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-091304-451-A2）
## 目录所有权·R34 冻结：本文件 / godot/data/rpg/combo_rules.tres /
##   combo_service.gd / verify_combo_v110.gd / verify_production_settlement_v110.gd /
##   teamwork/Rank-2/ 归 Rank-2 唯一写入；encounter_director.gd / hud.gd /
##   presentation.gd（唯一写入方 Rank-1）/ courtyard.tscn / 所有既有 .tres 数值 /
##   场景 / 素材 / 其它 Rank 文件一律只读、不改。
##
## 【纯逻辑边界（任务单 ① / 契约 I-1）】
## - 本类是数据表结构，不含结算逻辑：extends Resource、不继承 Node、不碰场景树、
##   不 add_child、不取 root、不调用 get_tree()、不用 /root/... 绝对路径、
##   不读写存档文件（I-1）、不碰渲染、不 load 任何资源。
## - 数值唯一真源是 res://data/rpg/combo_rules.tres；本类只定义结构、字段白名单、
##   合法性纯函数与「字段缺失 / 表非法」降级基线，不把任何设计数值写死进代码
##   （@export 默认值 = DEFAULT_* 降级基线，刻意 != 表值，不是设计数值）。
##
## 【4 个字段契约（任务单 ①）】
##   rank_thresholds     : Dictionary  rank 名 -> 达成该评级所需的最小 combo 数
##   multiplier          : Dictionary  rank 名 -> 赐福点数结算倍率
##   timeout_sec         : float       两次命中间隔超过该秒数判定连击中断、combo 归零
##   reset_on_hit_taken  : bool       玩家受击是否立即中断连击（true=中断）
## - RANK_ORDER = D/C/B/A/S（低→高），两张 Dictionary 必须且只能包含这 5 个 key。
## - 门槛严格递增（D 门槛恒为 0，0 连击起步评级 D）；倍率非递减、恒 > 0。
## - 评级倍率是【独立乘性层】：导演层清波结算只取 ComboService 一个倍率，不与
##   R31 试炼词条 / R32 处决加成叠乘（沿用「取单一倍率、防奖励通胀」口径）。
##
## 【设计数值 [PLACEHOLDER] rationale（数值实例在 .tres，本块只写「为什么」）】
##   ⚠ 以下全部为 [PLACEHOLDER] 首版假设、待人工试玩校准；只改 .tres 不改代码。
##   ① rank_thresholds = {D:0, C:4, B:8, A:14, S:22}
##      rationale：D 为 0 连击起步（保证结算不低于基础点数、无连击不惩罚）；
##      C=4 对应「一小段无伤连打」、B=8、A=14、S=22 逐级拉开，S 门槛 22 取
##      「一波 time_limit=30s 内近乎全程不被打断的高水平连击」量级，避免两三下
##      就 S 导致评级失去区分度。
##   ② multiplier = {D:1.0, C:1.15, B:1.35, A:1.6, S:2.0}
##      rationale：D=1.0 表示 0/低连击只拿基础点数；逐级 +0.15/+0.20/+0.25/+0.40，
##      S 封顶 2.0（翻倍）而非继续放大，防止高评级把赐福点数通胀到破坏 R27
##      成长出口节奏；单调递增但绝不叠乘其它倍率。
##   ③ timeout_sec = 2.5
##      rationale：两次命中间隔 >2.5s 判连击中断；与 R32 处决窗口 3.0s 同量级、
##      略短以强调「连续」；纯逻辑不读真实时钟、由导演层每帧 tick(delta) 推进。
##   ④ reset_on_hit_taken = true
##      rationale：受击立即中断连击（HD-2D 动作游戏「无伤连击」惯例），把「贪刀」
##      与「保连击」做成取舍；置 false 可作「宽松连击」对照档。
##
## 【调参唯一入口（只改表不改代码）】
##   godot/data/rpg/combo_rules.tres —— rank_thresholds / multiplier /
##   timeout_sec / reset_on_hit_taken 全在此一处。
##   校准同步清单：.tres -> verify_combo_v110.gd 的 EXPECT_* ->
##   teamwork/Rank-2/DONE-R34.md 数值拆解表 -> 三段门禁；不静默改数、
##   不改本 .gd 的 DEFAULT_* 基线（那是非法输入降级用，不是设计数值）。
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## 评级顺序（低→高）。结构约束，不是设计数值。
const RANK_ORDER: PackedStringArray = ["D", "C", "B", "A", "S"]

## ---- [PLACEHOLDER] 降级基线（字段缺失 / 表非法时用，刻意 != 设计数值）----
const DEFAULT_RANK_THRESHOLDS: Dictionary = {"D": 0, "C": 1, "B": 2, "A": 3, "S": 4}
const DEFAULT_MULTIPLIER: Dictionary = {"D": 1.0, "C": 1.0, "B": 1.0, "A": 1.0, "S": 1.0}
const DEFAULT_TIMEOUT_SEC: float = 1.0
const DEFAULT_RESET_ON_HIT_TAKEN: bool = true

## 4 个字段（@export 默认值 = 降级基线；设计数值在 .tres）。
@export var rank_thresholds: Dictionary = DEFAULT_RANK_THRESHOLDS        # [PLACEHOLDER]
@export var multiplier: Dictionary = DEFAULT_MULTIPLIER                   # [PLACEHOLDER]
@export var timeout_sec: float = DEFAULT_TIMEOUT_SEC                      # [PLACEHOLDER]
@export var reset_on_hit_taken: bool = DEFAULT_RESET_ON_HIT_TAKEN         # [PLACEHOLDER]


## 全表合法性：两张 Dictionary 含且仅含 5 个 rank、门槛严格递增且 D=0、
## 倍率非递减且恒 > 0、timeout>0；NaN/Inf/类型异常一律 false（不崩）。
func is_valid() -> bool:
	if typeof(rank_thresholds) != TYPE_DICTIONARY or typeof(multiplier) != TYPE_DICTIONARY:
		return false
	if timeout_sec <= 0.0 or is_nan(timeout_sec) or is_inf(timeout_sec):
		return false
	if rank_thresholds.size() != RANK_ORDER.size() or multiplier.size() != RANK_ORDER.size():
		return false
	var prev_t: int = -1
	var prev_m: float = -1.0
	for rank: String in RANK_ORDER:
		if not rank_thresholds.has(rank) or not multiplier.has(rank):
			return false
		var t: Variant = rank_thresholds[rank]
		var m: Variant = multiplier[rank]
		if typeof(t) != TYPE_INT and typeof(t) != TYPE_FLOAT:
			return false
		if typeof(m) != TYPE_INT and typeof(m) != TYPE_FLOAT:
			return false
		var tf: float = float(t)
		var mf: float = float(m)
		if is_nan(tf) or is_inf(tf) or is_nan(mf) or is_inf(mf) or mf <= 0.0:
			return false
		var ti: int = int(tf)
		if ti <= prev_t:                 # 门槛严格递增
			return false
		if mf < prev_m:                  # 倍率非递减
			return false
		prev_t = ti
		prev_m = mf
	if int(float(rank_thresholds["D"])) != 0:   # 0 连击起步评级 D
		return false
	return true


## 按 combo 数取评级：遍历低→高，最后满足的最高门槛即为评级；combo<0 夹到 0。
func get_rank_for_combo(combo: int) -> String:
	var c: int = maxi(0, combo)
	var out: String = "D"
	for rank: String in RANK_ORDER:
		if c >= int(float(rank_thresholds.get(rank, 0))):
			out = rank
	return out


func get_threshold_for_rank(rank: String) -> int:
	return int(float(rank_thresholds.get(rank, 0)))


func get_multiplier_for_rank(rank: String) -> float:
	return float(multiplier.get(rank, 1.0))


func rank_count() -> int:
	return RANK_ORDER.size()


func get_ranks() -> PackedStringArray:
	return RANK_ORDER.duplicate()
