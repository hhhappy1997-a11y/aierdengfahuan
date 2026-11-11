extends Resource
class_name GraceUpgradeConfig

## ===========================================================================
## R27 / v0.5.0 · 赐福成长「点数兑换」数据表资源（Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261111-083350-239-A2）
## 目录所有权：本文件 / godot/data/rpg/grace_upgrades.tres /
##   grace_upgrade_service.gd / grace_upgrade_runtime.gd /
##   verify_grace_upgrade_v050.gd / teamwork/Rank-2/ 归 Rank-2。
##
## 【设计口径】
## - 数值唯一真源是 res://data/rpg/grace_upgrades.tres（3 项实例）；本类只定义结构、
##   effect_key 白名单与「字段缺失 / 空表」降级基线，不把任何设计数值写死进代码。
## - 所有设计数值标 [PLACEHOLDER]（首版取自任务单建议 100/200/300 与示例 +20/+1/+5），
##   待人工试玩校准；逐项 rationale 见本文件「设计数值 rationale」注释块与
##   teamwork/Rank-2/GRACE-UPGRADE-TUNING.md §1。不拍脑袋写死、不静默改数。
## - 存储层 @export upgrades: Array[Dictionary]：沿用 R26 实证结论 —— Godot 4.7.2
##   内部类 Resource 实例无法正确序列化进 .tres，故 .tres 每行用 Dictionary，
##   由 get_upgrade() 在运行时包装成静态类型视图 UpgradeData。
## - 全静态类型：@export 字段 / 常量 / 方法参数与返回值全部显式类型标注。
##
## 【effect_key 落点核对（任务单 ② 硬要求：必须能在既有数据表或导演层找到对应落点）】
##   hp_max       -> godot/scripts/combat/encounter_director.gd:30
##                   @export var player_max_hp: float = 100.0（EncounterDirector 公开 @export）
##   roll_iframe  -> godot/data/combat/player_actions.tres:97-98
##                   action_04_roll.invulnerable_start_frame=4 / invulnerable_end_frame=13
##                   （PlayerActionState.is_invulnerable() 读这两个 @export，
##                    见 player_action_state.gd:66-73；无敌区间左闭右开）
##   attack_power -> godot/data/combat/player_actions.tres:128,155
##                   action_05_attack_light.base_attack=85.0 / action_06_attack_heavy.base_attack=85.0
##                   （EncounterDirector._compute_damage() 读 action.base_attack，
##                    见 encounter_director.gd:180-187）
##   三项均命中既有落点，故 .tres 无「找不到落点」降级项；
##   但「运行时自动生效」另受裁决 A22 限制（不改两份导演脚本 / 不改场景），
##   接线结果如实登记于 grace_upgrade_runtime.gd 头注与 DONE-R27.md §4。
## 引擎：Godot 4.7.2 标准版 / GDScript。
## ===========================================================================

## ---- effect_key 白名单（只允许命中既有落点的 key） ----
const EFFECT_KEY_HP_MAX: String = "hp_max"
const EFFECT_KEY_ROLL_IFRAME: String = "roll_iframe"
const EFFECT_KEY_ATTACK_POWER: String = "attack_power"
const KNOWN_EFFECT_KEYS: PackedStringArray = [
	EFFECT_KEY_HP_MAX, EFFECT_KEY_ROLL_IFRAME, EFFECT_KEY_ATTACK_POWER
]

## ---- [PLACEHOLDER] 降级基线（仅用于字段缺失 / 空表，不是设计数值） ----
## rationale 逐项见 GRACE-UPGRADE-TUNING.md §2；下列常量只保证「不崩、可判非法」。
const DEFAULT_ID: String = ""                  # [PLACEHOLDER] 空 id = 未配置，判非法，强制人工补
const DEFAULT_DISPLAY_NAME: String = ""        # [PLACEHOLDER] 空名称 = 未配置，判非法
const DEFAULT_COST: int = 0                    # [PLACEHOLDER] 0 成本判非法，避免凭空免费刷增益
const DEFAULT_EFFECT_KEY: String = ""          # [PLACEHOLDER] 空 key 不在白名单，判非法
const DEFAULT_EFFECT_VALUE: float = 0.0        # [PLACEHOLDER] 0 增益判非法，避免无效兑换

## ---------------------------------------------------------------------------
## 设计数值 [PLACEHOLDER] rationale（数值实例在 .tres，本块只写「为什么」）
## ---------------------------------------------------------------------------
## ① id=hp_max_bonus       cost=100  effect_key=hp_max        effect_value=20.0
##    rationale：100 与三波首清奖励 100（wave_trial.tres 第 1 波）对齐，「一轮试炼换一项」；
##    20.0 约为既有 player_max_hp=100.0 的 +20%，是「可感知但不破坏一击线」的保守首版。
## ② id=roll_iframe_bonus  cost=200  effect_key=roll_iframe   effect_value=1.0
##    rationale：200 落在前两波奖励之和（100+150=250）内，定位中期兑换；
##    +1 帧（60fps 约 16.7ms，无敌窗口 4..13 → 4..14）是最小可读增量，避免翻滚过强。
## ③ id=attack_power_bonus cost=300  effect_key=attack_power  effect_value=5.0
##    rationale：300 约为三波奖励 100+150+200=450 的大头，定位后期兑换；
##    +5.0 约为 base_attack=85.0 的 +5.9%，对「A×M×P×S−D」伤害式是温和增幅。
## 三项 cost 100/200/300 与 effect_value 20/1/5 全部为任务单建议/示例的 [PLACEHOLDER] 首版，
## 待人工试玩按 GRACE-UPGRADE-TUNING.md §4 broken 判据校准；校准需同步 .tres / verify EXPECT_* / 文档。
## ---------------------------------------------------------------------------

## 每项「静态类型视图」：仅在运行时由 get_upgrade() 构造，不参与 .tres 序列化。
class UpgradeData extends Resource:
	@export var id: String = ""
	@export var display_name: String = ""
	@export var cost: int = 0
	@export var effect_key: String = ""
	@export var effect_value: float = 0.0

## 三项结构（任务单 ①「每项含 id / display_name / cost / effect_key / effect_value」）。
@export var upgrades: Array[Dictionary] = []


## 工厂：返回一行 Dictionary（.tres 存储单元）；不硬编码任何设计数值，数值由调用方传入。
func make_upgrade(
	p_id: String,
	p_display_name: String,
	p_cost: int,
	p_effect_key: String,
	p_effect_value: float) -> Dictionary:
	return {
		"id": p_id,
		"display_name": p_display_name,
		"cost": p_cost,
		"effect_key": p_effect_key,
		"effect_value": p_effect_value,
	}


## 字段缺失降级：Dictionary 缺 key / 类型异常时回落到 [PLACEHOLDER] 基线，不抛错。
func upgrade_from_dict(d: Dictionary) -> UpgradeData:
	var u: UpgradeData = UpgradeData.new()
	u.id = str(d.get("id", DEFAULT_ID))
	u.display_name = str(d.get("display_name", DEFAULT_DISPLAY_NAME))
	u.cost = int(d.get("cost", DEFAULT_COST))
	u.effect_key = str(d.get("effect_key", DEFAULT_EFFECT_KEY))
	u.effect_value = float(d.get("effect_value", DEFAULT_EFFECT_VALUE))
	return u


## 越界拒绝：非法下标返回 null，不崩、不回绕。
func get_upgrade(index: int) -> UpgradeData:
	if index < 0 or index >= upgrades.size():
		return null
	return upgrade_from_dict(upgrades[index] as Dictionary)


func upgrade_count() -> int:
	return upgrades.size()


func is_known_effect_key(key: String) -> bool:
	return KNOWN_EFFECT_KEYS.has(key)


## 单项合法性：id / 名称非空、cost>0、effect_key 命中既有落点白名单、effect_value>0。
func is_upgrade_valid(u: UpgradeData) -> bool:
	if u == null:
		return false
	if u.id.is_empty() or u.display_name.is_empty():
		return false
	if u.cost <= 0:
		return false
	if not is_known_effect_key(u.effect_key):
		return false
	if u.effect_value <= 0.0:
		return false
	return true
