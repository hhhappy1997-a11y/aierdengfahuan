extends Resource
class_name ParryConfig

## ===========================================================================
## R35 / v0.12.0「精准弹反 · 消费闭合」· Parry 规则数据表资源（Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-125821-139-A2）
## 目录所有权·R35 冻结：本文件 / godot/data/combat/parry_rules.tres /
##   parry_service.gd / verify_parry_v120.gd / verify_parry_settlement_v120.gd /
##   teamwork/Rank-2/ 归 Rank-2 唯一写入；encounter_director.gd / hud.gd /
##   presentation.gd（唯一写入方 Rank-1）/ project.godot（Rank-3）/ courtyard.tscn /
##   所有既有 .tres 数值 / 场景 / 素材 / 其它 Rank 文件一律只读、不改。
##
## 【纯逻辑边界（任务单 ① / 契约 I-1）】
## - 本类是数据表结构，不含结算逻辑：extends Resource、不继承 Node、不碰场景树、
##   不 add_child、不取 root、不调用 get_tree()、不用 /root/... 绝对路径、
##   不读写存档文件（I-1）、不碰渲染、不 load 任何资源。
## - 数值唯一真源是 res://data/combat/parry_rules.tres；本类只定义结构、字段白名单、
##   合法性纯函数与「字段缺失 / 表非法」降级基线，不把任何设计数值写死进代码
##   （@export 默认值 = DEFAULT_* 降级基线，刻意 != 表值，不是设计数值）。
##
## 【6 个字段契约（任务单 ①，全部 [PLACEHOLDER]）】
##   window_sec    : float  精准弹反窗口时长（秒）；open_window() 后 tick(delta) 推进，归零关窗
##   cooldown_sec  : float  弹反成功后的冷却时长（秒）；冷却期内 open_window/try_parry 拒绝
##   poise_bonus   : float  弹反成功并入【既有削韧结算】的削韧量（StaggerService.apply_hit）
##   points_bonus  : int    弹反成功并入【既有清波点数结算】的赐福点数加成
##   combo_keep    : bool   弹反成功是否保留当前连击（true=保留）；本轮只作信号 payload / 记录，
##                          不擅自联动既有 ComboService 判定分支（见 DONE-R35 待裁决项）
##   fail_penalty  : int    弹反失败（窗口外按键 / 超时 / Boss 招式落地未弹反）的惩罚记录量；
##                          本轮只作记录与信号 payload，不扣减既有赐福点数（守住「点数只增不减」）
##
## 【设计数值 [PLACEHOLDER] rationale（数值实例在 .tres，本块只写「为什么」）】
##   ⚠ 以下全部为 [PLACEHOLDER] 首版假设、待人工试玩校准；只改 .tres 不改代码。
##   ① window_sec = 0.35
##      rationale：精准弹反强调「窄窗口」，取 350ms 量级；与 R32 处决窗口 3.0s 拉开一个数量级，
##      避免弹反退化成「常驻格挡」。纯逻辑不读真实时钟，由导演层每帧 tick(delta) 确定性推进。
##   ② cooldown_sec = 1.2
##      rationale：成功后 1.2s 冷却，防止连续开窗把 poise_bonus / points_bonus 刷成奖励通胀；
##      略大于 window_sec，保证一次出招节奏内至多成功弹反一次。
##   ③ poise_bonus = 25.0
##      rationale：与既有 stagger_rules.tres 的 reference_poise_damage=25.0 / stagger_max=100.0
##      同量级，等于「一次标准命中」的削韧，弹反成功约等于白送一次有效削韧，不改既有削韧判定分支。
##   ④ points_bonus = 50
##      rationale：与既有 stagger_rules.tres 的 execute_bonus_points=50 同量级，避免弹反奖励
##      盖过处决出口；经导演层并入清波结算基数后随既有单一连击倍率结算（A51 不叠乘其它层）。
##   ⑤ combo_keep = true
##      rationale：弹反成功默认保留连击（HD-2D「防反不打断进攻节奏」手感）；置 false 可作
##      「弹反断连」对照档。本轮只广播该值，不擅自改既有 ComboService（不破坏 A57 settle 口径）。
##   ⑥ fail_penalty = 10
##      rationale：弹反失败给一个可观测的惩罚记录量（供 Rank-4 失败反馈 / 未来对接），量级小于
##      points_bonus=50，表达「贪弹反有代价」；本轮不真正扣点，守住既有「点数只增不减 / 余额非负」。
##
## 【调参唯一入口（只改表不改代码）】
##   godot/data/combat/parry_rules.tres —— window_sec / cooldown_sec / poise_bonus /
##   points_bonus / combo_keep / fail_penalty 全在此一处。
##   校准同步清单：.tres -> verify_parry_v120.gd 的 EXPECT_* ->
##   teamwork/Rank-2/DONE-R35.md 数值拆解表 -> 三段门禁；不静默改数、
##   不改本 .gd 的 DEFAULT_* 基线（那是非法输入降级用，不是设计数值）。
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- [PLACEHOLDER] 降级基线（字段缺失 / 表非法时用，刻意 != 设计数值）----
const DEFAULT_WINDOW_SEC: float = 0.1
const DEFAULT_COOLDOWN_SEC: float = 0.1
const DEFAULT_POISE_BONUS: float = 1.0
const DEFAULT_POINTS_BONUS: int = 0
const DEFAULT_COMBO_KEEP: bool = false
const DEFAULT_FAIL_PENALTY: int = 0

## 6 个字段（@export 默认值 = 降级基线；设计数值在 .tres）。
@export var window_sec: float = DEFAULT_WINDOW_SEC            # [PLACEHOLDER]
@export var cooldown_sec: float = DEFAULT_COOLDOWN_SEC        # [PLACEHOLDER]
@export var poise_bonus: float = DEFAULT_POISE_BONUS          # [PLACEHOLDER]
@export var points_bonus: int = DEFAULT_POINTS_BONUS          # [PLACEHOLDER]
@export var combo_keep: bool = DEFAULT_COMBO_KEEP             # [PLACEHOLDER]
@export var fail_penalty: int = DEFAULT_FAIL_PENALTY          # [PLACEHOLDER]


## 全表合法性：6 字段类型合法、window_sec>0、其余数值 >=0、无 NaN/Inf；异常一律 false（不崩）。
func is_valid() -> bool:
	if typeof(window_sec) != TYPE_INT and typeof(window_sec) != TYPE_FLOAT:
		return false
	if typeof(cooldown_sec) != TYPE_INT and typeof(cooldown_sec) != TYPE_FLOAT:
		return false
	if typeof(poise_bonus) != TYPE_INT and typeof(poise_bonus) != TYPE_FLOAT:
		return false
	if typeof(points_bonus) != TYPE_INT and typeof(points_bonus) != TYPE_FLOAT:
		return false
	if typeof(fail_penalty) != TYPE_INT and typeof(fail_penalty) != TYPE_FLOAT:
		return false
	if typeof(combo_keep) != TYPE_BOOL:
		return false
	var w: float = float(window_sec)
	var c: float = float(cooldown_sec)
	var pb: float = float(poise_bonus)
	var pts: float = float(points_bonus)
	var fp: float = float(fail_penalty)
	if is_nan(w) or is_inf(w) or w <= 0.0:
		return false
	if is_nan(c) or is_inf(c) or c < 0.0:
		return false
	if is_nan(pb) or is_inf(pb) or pb < 0.0:
		return false
	if is_nan(pts) or is_inf(pts) or pts < 0.0:
		return false
	if is_nan(fp) or is_inf(fp) or fp < 0.0:
		return false
	return true


func get_window_sec() -> float:
	return float(window_sec)


func get_cooldown_sec() -> float:
	return float(cooldown_sec)


func get_poise_bonus() -> float:
	return float(poise_bonus)


func get_points_bonus() -> int:
	return int(points_bonus)


func get_combo_keep() -> bool:
	return bool(combo_keep)


func get_fail_penalty() -> int:
	return int(fail_penalty)
