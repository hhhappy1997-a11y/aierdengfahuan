extends Resource
class_name DeathConfig

## ===========================================================================
## R37 / v0.14.0「元素瓶与死亡轮回 · 画面补齐」· 死亡轮回规则数据表资源（Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-184157-082-A2）
## 目录所有权·R37 冻结：本文件 / godot/data/rpg/death_rules.tres /
##   death_service.gd / verify_death_v140.gd / wave_trial_director.gd（接线，
##   唯一写入方 Rank-2）/ teamwork/Rank-2/ 归 Rank-2 唯一写入；
##   encounter_director.gd / hud.gd / presentation.gd（唯一写入方 Rank-1）/
##   points_commit_orchestrator.gd / project.godot（Rank-3）/ courtyard.tscn /
##   所有既有 .tres 数值 / 场景 / 素材 / 其它 Rank 文件一律只读、不改。
##
## 【纯逻辑边界（任务单 ② / 契约 I-1）】
## - 本类是数据表结构，不含结算逻辑：extends Resource、不继承 Node、不碰场景树、
##   不 add_child、不取 root、不调用 get_tree()、不用 /root/... 绝对路径、
##   不读写存档文件（I-1）、不碰渲染、不 load 任何资源。
## - 数值唯一真源是 res://data/rpg/death_rules.tres；本类只定义结构、字段契约、
##   合法性纯函数与「字段缺失 / 表非法」降级基线，不把任何设计数值写死进代码
##   （@export 默认值 = DEFAULT_* 降级基线，刻意 != 表值，不是设计数值）。
##
## 【3 个字段契约（任务单 ②，全部 [PLACEHOLDER]）】
##   drop_ratio          : float  死亡时按当前 grace.trial.points 记录「掉落」的比例
##                          （只是叙事层记录 + 独立单向 flag，**绝不回退**
##                            grace.trial.points、**绝不写 removals** —— A59）
##   drop_cap            : int    单次掉落点数上限（0 = 不封顶），防极端存档点数通胀
##   invalid_input_policy: String 异常输入策略；首版唯一合法值 POLICY_REJECT="reject"
##                          （null / 非数值 / NaN / Inf / 负点数 / 异常 action_id 一律拒绝）
##
## 【设计数值 [PLACEHOLDER] rationale（数值实例在 .tres，本块只写「为什么」）】
##   ⚠ 以下全部为 [PLACEHOLDER] 首版假设、待人工试玩校准；只改 .tres 不改代码。
##   ① drop_ratio = 0.5
##      rationale：死亡掉落取当前赐福点数的 50%，对标原作「死亡掉落卢恩、回到死亡点
##      可捡回」的叙事张力；但**磁盘 grace.trial.points 绝不回退、绝不写 removals**
##      （A59），掉落只是 DeathService 实例内的记录 + dropped / reclaimed 两个独立
##      单向 flag。回收时该点数经既有清波结算链路（A55/A57 points_awarded）**一次
##      入账**，点数只增不减、余额非负，不造成凭空通胀。
##   ② drop_cap = 500
##      rationale：单次掉落上限，防止极端存档（点数很大）下按比例掉落过大、回收时
##      点数跳变造成通胀观感（A51/A60 精神）；0 = 不封顶，供裁决切换。
##   ③ invalid_input_policy = "reject"
##      rationale：异常输入一律拒绝且不改状态，避免 clamp / ignore 造成「隐式掉落 /
##      隐式二次回收」的不可测分支；首版只实现 reject，任何策略扩展必须先补回归
##      用例再改代码 + 表 + 验证，列为 DONE-R37 待裁决项。
##
## 【调参唯一入口（只改表不改代码）】
##   godot/data/rpg/death_rules.tres —— drop_ratio / drop_cap /
##   invalid_input_policy 全在此一处。
##   校准同步清单：.tres -> verify_death_v140.gd 的 EXPECT_* ->
##   teamwork/Rank-2/DONE-R37.md 数值拆解表 -> 三段门禁；不静默改数、
##   不改本 .gd 的 DEFAULT_* 基线（那是非法输入降级用，不是设计数值）。
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- 公开常量（签名稳定）----
## 异常输入策略：首版唯一合法值。DeathService 拒绝分支据此实现；改策略需同步改代码 + 回归用例。
const POLICY_REJECT: String = "reject"

## ---- [PLACEHOLDER] 降级基线（字段缺失 / 表非法时用，刻意 != 设计数值）----
const DEFAULT_DROP_RATIO: float = 0.0
const DEFAULT_DROP_CAP: int = 0
## 注：policy 的降级基线必须与唯一合法值一致，否则 is_valid() 会判表非法、服务降级；
## 它不参与「DEFAULT_* != 表值」的机器判定（验证脚本只对数值字段做该判定）。
const DEFAULT_INVALID_INPUT_POLICY: String = POLICY_REJECT

## 3 个字段（@export 默认值 = 降级基线；设计数值在 .tres）。
@export var drop_ratio: float = DEFAULT_DROP_RATIO                     # [PLACEHOLDER]
@export var drop_cap: int = DEFAULT_DROP_CAP                          # [PLACEHOLDER]
@export var invalid_input_policy: String = DEFAULT_INVALID_INPUT_POLICY  # [PLACEHOLDER]


## 全表合法性：3 字段类型合法、0<=drop_ratio<=1 且有限、drop_cap 为非负整数且有限、
## policy == POLICY_REJECT；异常一律 false（不崩）。
func is_valid() -> bool:
	if typeof(drop_ratio) != TYPE_INT and typeof(drop_ratio) != TYPE_FLOAT:
		return false
	if typeof(drop_cap) != TYPE_INT and typeof(drop_cap) != TYPE_FLOAT:
		return false
	if typeof(invalid_input_policy) != TYPE_STRING:
		return false
	var r: float = float(drop_ratio)
	var c: float = float(drop_cap)
	if is_nan(r) or is_inf(r) or r < 0.0 or r > 1.0:
		return false
	if is_nan(c) or is_inf(c) or c < 0.0:
		return false
	if not is_equal_approx(c, floorf(c)):   # 上限必须是整数
		return false
	return String(invalid_input_policy) == POLICY_REJECT


## ---- 只读 getter（全静态类型；数值来自表，代码不写死设计值）----
func get_drop_ratio() -> float:
	return float(drop_ratio)


func get_drop_cap() -> int:
	return int(drop_cap)


func get_invalid_input_policy() -> String:
	return String(invalid_input_policy)
