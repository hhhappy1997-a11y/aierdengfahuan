extends Resource
class_name FlaskConfig

## ===========================================================================
## R37 / v0.14.0「元素瓶与死亡轮回 · 画面补齐」· 元素瓶规则数据表资源（Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-184157-082-A2）
## 目录所有权·R37 冻结：本文件 / godot/data/rpg/flask_rules.tres /
##   flask_service.gd / verify_flask_v140.gd / wave_trial_director.gd（接线，
##   唯一写入方 Rank-2）/ teamwork/Rank-2/ 归 Rank-2 唯一写入；
##   encounter_director.gd / hud.gd / presentation.gd（唯一写入方 Rank-1）/
##   points_commit_orchestrator.gd / project.godot（Rank-3）/ courtyard.tscn /
##   所有既有 .tres 数值 / 场景 / 素材 / 其它 Rank 文件一律只读、不改。
##
## 【纯逻辑边界（任务单 ① / 契约 I-1）】
## - 本类是数据表结构，不含结算逻辑：extends Resource、不继承 Node、不碰场景树、
##   不 add_child、不取 root、不调用 get_tree()、不用 /root/... 绝对路径、
##   不读写存档文件（I-1）、不碰渲染、不 load 任何资源。
## - 数值唯一真源是 res://data/rpg/flask_rules.tres；本类只定义结构、字段契约、
##   合法性纯函数与「字段缺失 / 表非法」降级基线，不把任何设计数值写死进代码
##   （@export 默认值 = DEFAULT_* 降级基线，刻意 != 表值，不是设计数值）。
##
## 【4 个字段契约（任务单 ①，全部 [PLACEHOLDER]）】
##   flask_max            : int    元素瓶携带上限；构造 / reset() / 赐福休息回满到该值
##   heal_amount          : float  每次使用回复的 HP 量（minf 封顶，HP 不超过上限）
##   rest_refill          : bool   赐福休息是否「补满瓶」；true=补满 flask_max，false=保持当前瓶数
##   invalid_input_policy : String 异常输入策略；首版唯一合法值 POLICY_REJECT="reject"
##                          （null / 非数值 / NaN / Inf / 负 HP / max_hp<=0 /
##                            current_hp>max_hp 一律拒绝且不改状态）
##
## 【设计数值 [PLACEHOLDER] rationale（数值实例在 .tres，本块只写「为什么」）】
##   ⚠ 以下全部为 [PLACEHOLDER] 首版假设、待人工试玩校准；只改 .tres 不改代码。
##   ① flask_max = 3
##      rationale：对标原作「元素瓶」初始携带数，取 3 瓶便于 15~20 秒录屏里肉眼观察
##      「3 → 2 → 1 → 0 → 赐福休息回满 3」的离散递减；与既有 focus fp_max=100.0 /
##      stagger_max=100.0 不同量纲（离散次数 vs 连续量），不混用。
##   ② heal_amount = 50.0
##      rationale：以 max_hp=100.0 为参照，一次回复半血，是明显的「救命」动作；实际
##      回复量恒 = minf(heal_amount, max_hp - current_hp)，用封顶保证「HP 不超过上限」；
##      它是纯恢复量、不并入清波点数结算，不造成点数通胀（A51/A60 精神）。
##   ③ rest_refill = true
##      rationale：任务单覆盖点「赐福休息补满」——赐福休息是**唯一**允许瓶数增加的
##      出口（守住「瓶数只减不增除休息」不变量）；置 false 切换为「保持当前瓶数」
##      对照档（FlaskService.REST_KEEP），不改代码。
##   ④ invalid_input_policy = "reject"
##      rationale：异常输入一律拒绝且不改状态，避免 clamp / ignore 造成「隐式扣瓶 /
##      隐式回复 HP」的不可测分支；首版只实现 reject，任何策略扩展必须先补回归用例
##      再改代码 + 表 + 验证，列为 DONE-R37 待裁决项。
##
## 【调参唯一入口（只改表不改代码）】
##   godot/data/rpg/flask_rules.tres —— flask_max / heal_amount / rest_refill /
##   invalid_input_policy 全在此一处。
##   校准同步清单：.tres -> verify_flask_v140.gd 的 EXPECT_* ->
##   teamwork/Rank-2/DONE-R37.md 数值拆解表 -> 三段门禁；不静默改数、
##   不改本 .gd 的 DEFAULT_* 基线（那是非法输入降级用，不是设计数值）。
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- 公开常量（签名稳定）----
## 异常输入策略：首版唯一合法值。FlaskService 拒绝分支据此实现；改策略需同步改代码 + 回归用例。
const POLICY_REJECT: String = "reject"

## ---- [PLACEHOLDER] 降级基线（字段缺失 / 表非法时用，刻意 != 设计数值）----
const DEFAULT_FLASK_MAX: int = 1
const DEFAULT_HEAL_AMOUNT: float = 1.0
const DEFAULT_REST_REFILL: bool = false
## 注：policy 的降级基线必须与唯一合法值一致，否则 is_valid() 会判表非法、服务降级；
## 它不参与「DEFAULT_* != 表值」的机器判定（验证脚本只对数值字段做该判定）。
const DEFAULT_INVALID_INPUT_POLICY: String = POLICY_REJECT

## 4 个字段（@export 默认值 = 降级基线；设计数值在 .tres）。
@export var flask_max: int = DEFAULT_FLASK_MAX                          # [PLACEHOLDER]
@export var heal_amount: float = DEFAULT_HEAL_AMOUNT                    # [PLACEHOLDER]
@export var rest_refill: bool = DEFAULT_REST_REFILL                     # [PLACEHOLDER]
@export var invalid_input_policy: String = DEFAULT_INVALID_INPUT_POLICY  # [PLACEHOLDER]


## 全表合法性：4 字段类型合法、flask_max 为正整数、heal_amount > 0 且有限、
## policy == POLICY_REJECT；异常一律 false（不崩）。
func is_valid() -> bool:
	if typeof(flask_max) != TYPE_INT and typeof(flask_max) != TYPE_FLOAT:
		return false
	if typeof(heal_amount) != TYPE_INT and typeof(heal_amount) != TYPE_FLOAT:
		return false
	if typeof(rest_refill) != TYPE_BOOL:
		return false
	if typeof(invalid_input_policy) != TYPE_STRING:
		return false
	var fm: float = float(flask_max)
	var ha: float = float(heal_amount)
	if is_nan(fm) or is_inf(fm) or fm <= 0.0:
		return false
	if not is_equal_approx(fm, floorf(fm)):   # 瓶数必须是整数
		return false
	if is_nan(ha) or is_inf(ha) or ha <= 0.0:
		return false
	return String(invalid_input_policy) == POLICY_REJECT


## ---- 只读 getter（全静态类型；数值来自表，代码不写死设计值）----
func get_flask_max() -> int:
	return int(flask_max)


func get_heal_amount() -> float:
	return float(heal_amount)


func get_rest_refill() -> bool:
	return bool(rest_refill)


func get_invalid_input_policy() -> String:
	return String(invalid_input_policy)
