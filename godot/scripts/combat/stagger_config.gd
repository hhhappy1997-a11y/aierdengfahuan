extends Resource
class_name StaggerConfig

## ===========================================================================
## R32 / v0.10.0 · Boss 韧性处决「规则数据表」资源（Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261112-074023-393-A2）
## 目录所有权·R32 冻结：本文件 / godot/data/combat/stagger_rules.tres /
##   stagger_service.gd / verify_stagger_v100.gd / teamwork/Rank-2/ 归 Rank-2。
##   encounter_director.gd（唯一写入方 Rank-1）/ hud.gd / impact_feedback.gd /
##   场景 / 素材 / 既有 .tres / 其它 Rank 文件一律只读、不改。
##
## 【纯逻辑边界（任务单 ② / 契约 I-1）】
## - 本类是规则参数表，不含结算逻辑；不继承 Node、不碰场景树、不 add_child、
##   不读写存档文件（I-1）、不碰渲染、不 load 任何资源。
## - 数值唯一真源是 res://data/combat/stagger_rules.tres；本类只定义标量结构、
##   合法性纯函数与「字段缺失」降级基线，不把任何设计数值写死进代码
##   （@export 默认值 = DEFAULT_* 降级基线，不是设计数值）。
## - 与 boon_draft.tres 不同，本规则是「单组标量参数」而非候选列表，故用 4 个
##   @export 标量字段，而非 Array[Dictionary]。
##
## 【4 个 [PLACEHOLDER] 规则参数（.tres 里的数值实例，本块只写「为什么」）】
##   ⚠ 以下全部为 [PLACEHOLDER] 首版假设、待人工试玩校准；只改 .tres 不改代码。
##   ① stagger_max = 100.0
##      rationale：Boss 韧性条满值；配合 ④ 参考削韧 25 → 4 次标准命中破韧开窗，
##      与三波试炼节奏（每波 30s）量级相称，避免一击开窗或十击不破。
##   ② window_duration_sec = 3.0
##      rationale：韧性归零后开启 3.0 秒 F 键处决窗口；够玩家反应但不宽松，
##      超时自动关窗并恢复满韧性，形成「破韧→抢处决→失手重来」的博弈。
##   ③ execute_bonus_points = 50
##      rationale：窗口内成功处决额外给 50 赐福点数，约等于单波清波奖励
##      （wave_trial.tres 100/150/200）的 1/3~1/2，鼓励抢处决但不喧宾夺主；
##      恒 >= 0，只加成不扣减（余额非负）。
##   ④ reference_poise_damage = 25.0
##      rationale：单次标准命中的参考削韧量，仅供表说明 / 数值拆解参考；
##      **实际削韧量由调用方按招式传入 stagger_service.apply_hit(poise_damage)**，
##      本值不参与运行时结算、不写死在 service 里（口径随表 / 招式变化）。
##
## 【调参唯一入口（只改表不改代码）】
##   godot/data/combat/stagger_rules.tres ——
##   stagger_max / window_duration_sec / execute_bonus_points /
##   reference_poise_damage 全在此一处。
##   校准同步清单：.tres -> verify_stagger_v100.gd 的 EXPECT_* ->
##   teamwork/Rank-2/DONE-R32.md 数值拆解表 -> 三段门禁；
##   不静默改数、不改本 .gd 的 DEFAULT_* 基线（那是非法输入降级用，不是设计数值）。
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- [PLACEHOLDER] 降级基线（字段缺失 / config 非法时用，不是设计数值）----
const DEFAULT_STAGGER_MAX: float = 1.0              # [PLACEHOLDER] 最小合法满韧性
const DEFAULT_WINDOW_DURATION_SEC: float = 1.0      # [PLACEHOLDER] 最小合法窗口
const DEFAULT_EXECUTE_BONUS_POINTS: int = 0         # [PLACEHOLDER] 不给额外点数
const DEFAULT_REFERENCE_POISE_DAMAGE: float = 1.0   # [PLACEHOLDER] 最小合法削韧

## 4 个规则参数（@export 默认值 = 降级基线；设计数值在 .tres）。
@export var stagger_max: float = DEFAULT_STAGGER_MAX                          # [PLACEHOLDER]
@export var window_duration_sec: float = DEFAULT_WINDOW_DURATION_SEC          # [PLACEHOLDER]
@export var execute_bonus_points: int = DEFAULT_EXECUTE_BONUS_POINTS         # [PLACEHOLDER]
@export var reference_poise_damage: float = DEFAULT_REFERENCE_POISE_DAMAGE    # [PLACEHOLDER]


## 单组规则合法性：满韧性 / 窗口时长 / 参考削韧 > 0，处决额外点数 >= 0。
func is_valid() -> bool:
	if stagger_max <= 0.0 or is_nan(stagger_max) or is_inf(stagger_max):
		return false
	if window_duration_sec <= 0.0 or is_nan(window_duration_sec) or is_inf(window_duration_sec):
		return false
	if execute_bonus_points < 0:
		return false
	if reference_poise_damage <= 0.0 or is_nan(reference_poise_damage) or is_inf(reference_poise_damage):
		return false
	return true
