extends Resource
class_name TutorialConfig

## ===========================================================================
## R28 / v0.6.0 · 教学三步数据表资源（Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261111-095602-824-A2）
## 目录所有权：本文件 / godot/data/rpg/tutorial_steps.tres /
##   grace_upgrade_service.gd（双写收敛）/ verify_tutorial_reward_v060.gd /
##   自有回归存档隔离脚本 / teamwork/Rank-2/ 归 Rank-2。
##   两份导演脚本 / 场景 / 素材 / project.godot / 契约 / README / presentation.gd 一律不碰。
##
## 【设计口径】
## - 数值唯一真源是 res://data/rpg/tutorial_steps.tres（3 步实例）；本类只定义结构、
##   expected_action 白名单与「字段缺失 / 空表」降级基线，不把任何设计数值写死进代码。
## - 所有设计数值（reward_points / timeout_sec）一律标 [PLACEHOLDER]：首版取自任务单，
##   待人工试玩校准；逐项 rationale 见本文件「设计数值 rationale」注释块与
##   teamwork/Rank-2/DONE-R28.md。不拍脑袋写死、不静默改数。
## - 存储层 @export steps: Array[Dictionary]：沿用 R26 / R27 实证结论 —— Godot 4.7.2
##   内部类 Resource 实例无法正确序列化进 .tres，故 .tres 每步用 Dictionary，
##   由 get_step() 在运行时包装成静态类型视图 TutorialStep。
## - 全静态类型：@export 字段 / 常量 / 方法参数与返回值全部显式类型标注。
##
## 【expected_action 既有落点核对（全部命中 project.godot [input]，零新增键位）】
##   "J"     -> light_attack（physical_keycode=74，Object(InputEventKey)）
##   "Space" -> roll        （physical_keycode=32）
##   "E"     -> interact    （physical_keycode=69；赐福休息 / 打开兑换面板 / 重开试炼）
##   三步梯度 = 「轻攻击（最基础）→ 翻滚（进阶闪避）→ 交互（闭环收束，进赐福系统）」，
##   与既有输入动作一一对应，不引入新键位、不改 project.godot。
##
## 【设计数值 [PLACEHOLDER] rationale（数值实例在 .tres，本块只写「为什么」）】
##   ① step_01_light_attack  expected_action=J      reward_points=20  timeout_sec=15.0
##      rationale：20 为三步最低，轻攻击是最基础操作，用最小正反馈快速建立「按键→反馈」；
##      避免首步奖励过大稀释后两步的引导权重（梯度单调 20<30<50）。
##   ② step_02_roll          expected_action=Space  reward_points=30  timeout_sec=15.0
##      rationale：30 落在首末之间，翻滚含无敌窗口（既有 [4,13) 帧）操作难度高于轻攻击，
##      奖励递增以匹配「逐步加压」的教学曲线。
##   ③ step_03_interact      expected_action=E      reward_points=50  timeout_sec=15.0
##      rationale：50 为最高，交互是「进赐福 / 打开成长兑换 / 收束教学」的闭环关键步，
##      用最大奖励强化玩家记住该入口；三步合计 100 恰好与既有 grace_upgrades.tres
##      第 1 项 cost=100 对齐（「完成一轮教学 ≈ 换一项最便宜增益」），仅为首版巧合对齐，
##      不是经济定论，待试玩校准。
##   timeout_sec=15.0（单步统一）：给新手「读提示 + 试按键」的充裕窗口，又不至于挂机；
##   统一值简化状态机（三步同一时限），为 [PLACEHOLDER] 首版，试玩后可按步拆分。
##   全部数值为任务单建议的 [PLACEHOLDER] 首版，校准需同步 .tres /
##   verify_tutorial_reward_v060.gd 的 EXPECT_* / DONE-R28.md。
## 引擎：Godot 4.7.2 标准版 / GDScript。
## ===========================================================================

## ---- expected_action 白名单（[PLACEHOLDER] 首版，与 project.godot [input] 三动作对齐）----
const ACTION_LIGHT_ATTACK: String = "J"
const ACTION_ROLL: String = "Space"
const ACTION_INTERACT: String = "E"
const KNOWN_ACTIONS: PackedStringArray = [
	ACTION_LIGHT_ATTACK, ACTION_ROLL, ACTION_INTERACT
]

## ---- [PLACEHOLDER] 降级基线（仅用于字段缺失 / 空表，不是设计数值）----
## rationale 逐项见 DONE-R28.md §「数值与 rationale」；下列常量只保证「不崩、可判非法」。
const DEFAULT_STEP_ID: String = ""                 # [PLACEHOLDER] 空 id = 未配置，判非法，强制人工补
const DEFAULT_PROMPT: String = ""                  # [PLACEHOLDER] 空提示 = 未配置，判非法
const DEFAULT_EXPECTED_ACTION: String = ""         # [PLACEHOLDER] 空 action 不在白名单，判非法
const DEFAULT_REWARD_POINTS: int = 0               # [PLACEHOLDER] 0 奖励判非法，避免凭空刷点
const DEFAULT_TIMEOUT_SEC: float = 0.0             # [PLACEHOLDER] 0 时限判非法，避免无限挂起

## 每步「静态类型视图」：仅在运行时由 get_step() 构造，不参与 .tres 序列化。
## 5 个字段全静态类型；默认值均为 [PLACEHOLDER] 降级基线。
class TutorialStep extends Resource:
	@export var step_id: String = ""                # [PLACEHOLDER]
	@export var prompt: String = ""                 # [PLACEHOLDER]
	@export var expected_action: String = ""        # [PLACEHOLDER] J / Space / E
	@export var reward_points: int = 0              # [PLACEHOLDER] 单步奖励点数
	@export var timeout_sec: float = 0.0            # [PLACEHOLDER] 单步超时秒数

## 三步结构（任务单 ①「step_id / prompt / expected_action / reward_points / timeout_sec」）。
@export var steps: Array[Dictionary] = []


## 工厂：返回一行 Dictionary（.tres 存储单元）；不硬编码任何设计数值，数值由调用方传入。
func make_step(
	p_step_id: String,
	p_prompt: String,
	p_expected_action: String,
	p_reward_points: int,
	p_timeout_sec: float) -> Dictionary:
	return {
		"step_id": p_step_id,
		"prompt": p_prompt,
		"expected_action": p_expected_action,
		"reward_points": p_reward_points,
		"timeout_sec": p_timeout_sec,
	}


## 字段缺失降级：Dictionary 缺 key / 类型异常时回落到 [PLACEHOLDER] 基线，不抛错。
func step_from_dict(d: Dictionary) -> TutorialStep:
	var s: TutorialStep = TutorialStep.new()
	s.step_id = str(d.get("step_id", DEFAULT_STEP_ID))
	s.prompt = str(d.get("prompt", DEFAULT_PROMPT))
	s.expected_action = str(d.get("expected_action", DEFAULT_EXPECTED_ACTION))
	s.reward_points = int(d.get("reward_points", DEFAULT_REWARD_POINTS))
	s.timeout_sec = float(d.get("timeout_sec", DEFAULT_TIMEOUT_SEC))
	return s


## 越界拒绝：非法下标返回 null，不崩、不回绕。
func get_step(index: int) -> TutorialStep:
	if index < 0 or index >= steps.size():
		return null
	return step_from_dict(steps[index] as Dictionary)


func step_count() -> int:
	return steps.size()


func is_known_action(action: String) -> bool:
	return KNOWN_ACTIONS.has(action)


## 单步合法性：5 字段齐全且非空、expected_action 命中既有键位白名单、
## reward_points > 0、timeout_sec > 0。
func is_step_valid(s: TutorialStep) -> bool:
	if s == null:
		return false
	if s.step_id.is_empty() or s.prompt.is_empty():
		return false
	if not is_known_action(s.expected_action):
		return false
	if s.reward_points <= 0:
		return false
	if s.timeout_sec <= 0.0:
		return false
	return true


## 三步奖励合计（只读聚合，供 verify / 装配层核对，不改状态）。
func total_reward_points() -> int:
	var total: int = 0
	for i: int in range(steps.size()):
		var s: TutorialStep = get_step(i)
		if s != null:
			total += s.reward_points
	return total


## 奖励单调：严格递增（首版 20<30<50）；非单调或空表返回 false。
## 供 verify_tutorial_reward_v060.gd「奖励单调」断言直接调用。
func is_reward_monotonic() -> bool:
	if steps.size() < 2:
		return false
	var prev: int = -1
	for i: int in range(steps.size()):
		var s: TutorialStep = get_step(i)
		if s == null:
			return false
		if i > 0 and s.reward_points <= prev:
			return false
		prev = s.reward_points
	return true
