extends Node

## v0.6.0 R28 · 赐福引导「三步教学运行时」（Rank-1，cmd-20261111-095602-818-A1）。
## 挂载：res://scenes/courtyard.tscn 根节点 Courtyard 下的 TutorialDirector（Node）。
## 职责：状态机编排 + 消费既有 input action + 逐步赐福点数奖励 + 单向完成 flag +
##       教学期冻结三波 / 完成自动进第 1 波 + T 强制重开 + 演示序列跳过接口。
## 状态机：NOT_STARTED → STEP_LIGHT_ATTACK(J) → STEP_ROLL(Space) →
##         STEP_GRACE_SHOP(E) → COMPLETED。
## 边界：
##   - 不改 project.godot：三个步骤只消费既有 action（light_attack / roll / interact），
##     T 重开直接按 physical_keycode=KEY_T 判定（不新增 action）；
##   - 不改 presentation.gd（Rank-4 独占）：只提供 is_tutorial_active() / force_complete()
##     供外部演示序列检测与跳过，避免「教学 + 演示序列」双驱动；
##   - 经 I-1 唯一写入口 WorldState.set_flag + SaveDeltaWriter.commit(reason) 写
##     grace.tutorial.completed（bool，false→true 单向）与赐福点数奖励 grace.trial.points
##     （单调递增、绝不回退、绝不 removals）；依赖缺失时只走进程内镜像、不落盘、不崩；
##   - 【R28B 裁决 A26】grace.tutorial.step_index 是【世界持久层】单调历史最高进度
##     （按 max 写、绝不回退，0→1→2→3）；_step_index 是【运行时教学游标】。
##     T 键重开只重置运行时游标与提示，绝不回写 / 清零世界 flag，绝不清除
##     grace.tutorial.completed。教学 HUD 进度显示取运行时游标（见 _refresh_hud /
##     hud.gd read_tutorial_progress()），绝不读世界 flag，否则 T 重开会卡在历史最高 3/3。
##     step_index 的 set_flag 与既有赐福点数奖励合并入同一次 commit("tutorial_step_reward")，
##     不新增落盘点，保护 verify_tutorial_v060.gd 的 set_flag→commit 时序断言不回退；
##   - 教学期间不推进三波：经 WaveTrialDirector.set_tutorial_freeze(true) 冻结，
##     完成后 begin_wave_after_tutorial() 解冻并自动进第 1 波；波次导演缺失时降级、不崩。
## 踩坑对齐：--script / SceneTree 模式 /root/... 绝对路径不可用（一律 Engine.get_main_loop()
##   + root.get_node_or_null() 相对探活）；add_child 不 flush _ready（验证脚本显式 call("_ready")，
##   并在 _ready 之后 bind_tutorial_deps() 注入确定性依赖）。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

# ==========================================================================
# 信号
# ==========================================================================
## 完成一步发出：step_id 为 STEP_IDS 之一，reward 为本次实际发放的赐福点数
## （首次教学每步 REWARD_PER_STEP；已完成存档按 T 重开时为 0，防重复刷点）。
signal tutorial_step_completed(step_id: String, reward: int)
## 三步全部完成（写单向 flag / 解冻波次之后）发出，供 HUD / 演示序列监听。
signal tutorial_completed()

# ==========================================================================
# 状态机 / 常量
# ==========================================================================
enum State { NOT_STARTED, STEP_LIGHT_ATTACK, STEP_ROLL, STEP_GRACE_SHOP, COMPLETED }
const STATE_NAMES: PackedStringArray = [
	"NOT_STARTED", "STEP_LIGHT_ATTACK", "STEP_ROLL", "STEP_GRACE_SHOP", "COMPLETED"
]

## 三步顺序（STEP_ORDER[i] 是第 i 步的状态；STEP_IDS / STEP_ACTIONS / STEP_TEXTS 一一对应）。
const STEP_ORDER: Array[int] = [
	State.STEP_LIGHT_ATTACK, State.STEP_ROLL, State.STEP_GRACE_SHOP
]
const STEP_IDS: PackedStringArray = ["light_attack", "roll", "grace_shop"]
## 只消费 project.godot 既有 input action，不新增、不改 project.godot。
const STEP_ACTIONS: PackedStringArray = ["light_attack", "roll", "interact"]
## [PLACEHOLDER] 教学文案（步骤提示），待试玩校准；rationale：与既有三个 action 的
##   键位字面（J / Space / E）一致，不引入新键位、不改既有 HUD 文本。
const STEP_TEXTS: PackedStringArray = [
	"按 J 轻攻击", "按 Space 翻滚", "按 E 打开赐福商店"
]
const KEY_HINTS: PackedStringArray = ["J", "Space", "E"]
const TOTAL_STEPS: int = 3

## [PLACEHOLDER] 每步赐福点数奖励；rationale：三步共 60 点，作为教学即时反馈，
##   不破坏既有波次 100/150/200 的奖励梯度；配合首波奖励即可凑够兑换最低档 100，
##   具体数值待试玩校准。单调写入 grace.trial.points，绝不回退、绝不 removals。
const REWARD_PER_STEP: int = 20

# ---- 三段式 flag（严格匹配 WorldState.FLAG_KEY_REGEX，不改 schema）----
const FLAG_TUTORIAL_COMPLETED: String = "grace.tutorial.completed"
## R28B 裁决 A26：世界持久层「历史最高教学进度」，单调递增（按 max 写），T 重开绝不回退。
## 三段式 key 匹配 WorldState.FLAG_KEY_REGEX；与运行时游标 _step_index 严格分离，
## 绝不用于教学 HUD 的「进度 1-3」显示（显示口径见 _refresh_hud / hud.gd）。
const FLAG_TUTORIAL_STEP_INDEX: String = "grace.tutorial.step_index"
const FLAG_POINTS: String = "grace.trial.points"
const COMMIT_REASON_STEP: String = "tutorial_step_reward"
const COMMIT_REASON_COMPLETED: String = "tutorial_completed"

## Rank-2 可选教学配置（tutorial_config.gd / data/rpg/tutorial_steps.tres）。
## 未落盘 / 字段缺失一律降级用内置 [PLACEHOLDER] 常量，不崩、不产生 SCRIPT ERROR。
const DEFAULT_CONFIG_PATH: String = "res://data/rpg/tutorial_steps.tres"

# ==========================================================================
# 装配 / 依赖注入
# ==========================================================================
@export var wave_director_path: NodePath = ^"../WaveTrialDirector"
@export var tutorial_label_path: NodePath = ^"../TutorialHud/TutorialLabel"
@export var config_path: String = DEFAULT_CONFIG_PATH
## 玩家打开 exe 默认进入教学（存档已完成则跳过）；验证可置 false 只装配不自动进。
@export var auto_start: bool = true

var _state: int = State.NOT_STARTED
## A26：运行时教学游标（0..TOTAL_STEPS），T 重开归零；教学 HUD 进度显示只认本值。
var _step_index: int = 0
## A26：世界持久层 grace.tutorial.step_index 的进程内镜像（依赖缺失降级时只用镜像，
## 绝不谎报落盘）。世界 flag 本身单调不回退，T 重开绝不回写更小值。
var _world_step_index_mirror: int = 0
var _step_events: Array[String] = []       # 顺序证据：已完成的 step_id
var _total_reward: int = 0                 # 本会话实际发放点数合计
var _completed_flag: bool = false          # 运行期镜像（依赖缺失时只用镜像）
var _wave_frozen: bool = false
var _wave_started: bool = false
var _commit_count: int = 0
var _degrade_reason: String = ""           # 最近一次降级登记（如实，不伪造）
var _config_loaded: bool = false
var _deps_prebound: bool = false             # _ready 前已显式注入依赖 → 不再场景探活覆盖

# 可选配置软解析结果（读不到字段一律回落内置 [PLACEHOLDER] 常量）。
# 数值唯一真源是 Rank-2 的 res://data/rpg/tutorial_steps.tres（prompt /
# expected_action / reward_points）；代码内常量只在依赖缺失降级时兜底。
var _step_texts: PackedStringArray = STEP_TEXTS.duplicate()
var _step_hints: PackedStringArray = KEY_HINTS.duplicate()
var _step_rewards: Array[int] = [REWARD_PER_STEP, REWARD_PER_STEP, REWARD_PER_STEP]

var _label: Label = null                   # 教学 HUD 金色引导行
var _wave: Node = null                     # WaveTrialDirector（可注入）
var _world_state: Node = null              # WorldState（可注入）
var _delta_writer: Node = null             # SaveDeltaWriter（可注入）

# ==========================================================================
# 1) 生命周期 / 依赖相对探活 / 可选配置
# ==========================================================================
func _ready() -> void:
	_resolve_deps()
	_load_optional_config()
	set_process_unhandled_input(true)
	if auto_start and not _read_completed_flag():
		_enter_tutorial()
	else:
		# 已有存档完成 → 跳过教学：不冻结三波，WaveTrialDirector 既有 auto_start 正常进第 1 波。
		_state = State.COMPLETED
		_completed_flag = _read_completed_flag()
		print("[Tutorial] 存档已完成（%s=true）→ 跳过教学，波次自动开始（按 T 可强制重开）"
				% FLAG_TUTORIAL_COMPLETED)
	_refresh_hud()


## 相对探活：绝不使用 /root/... 绝对路径（--script / SceneTree 模式不可解析）。
## 场景节点用相对 NodePath；autoload 用 Engine.get_main_loop() + root.get_node_or_null()。
func _resolve_deps() -> void:
	# 装配层 / 验证脚本若在 _ready 之前已 bind_tutorial_deps() 预注入，则尊重注入、
	# 不再用场景探活覆盖（--script 模式 autoload 与注入实例可能不同）。
	if _deps_prebound:
		return
	_label = get_node_or_null(tutorial_label_path) as Label
	_wave = get_node_or_null(wave_director_path)
	var ml: MainLoop = Engine.get_main_loop()
	if ml is SceneTree:
		var tree_root: Node = (ml as SceneTree).get_root()
		if tree_root != null:
			_world_state = tree_root.get_node_or_null(NodePath("WorldState"))
			_delta_writer = tree_root.get_node_or_null(NodePath("SaveDeltaWriter"))
	if _label == null:
		push_warning("[Tutorial] 教学 HUD Label 未找到：引导行不刷新（降级，不崩）")
	if _wave == null:
		push_warning("[Tutorial] WaveTrialDirector 未找到：教学期三波冻结 / 完成自动进第 1 波降级（不崩）")
	if _world_state == null or _delta_writer == null:
		push_warning("[Tutorial] WorldState / SaveDeltaWriter 未就绪：flag 与奖励仅进程内内存、未落盘（降级，不崩）")


## 验证 / 装配显式注入口（注入优先于场景探活，--script 模式可确定性验证落盘时序）。
## 传 null 显式降级；注入后若教学已激活则立即重新冻结波次，保证「教学期不推进三波」。
func bind_tutorial_deps(ws: Node, writer: Node, wave: Node, label: Label) -> void:
	_deps_prebound = true
	_world_state = ws
	_delta_writer = writer
	_wave = wave
	_label = label
	if is_tutorial_active() and _wave != null and _wave.has_method("set_tutorial_freeze"):
		_wave.call("set_tutorial_freeze", true)
		_wave_frozen = true
	_refresh_hud()


## 软解析 Rank-2 可选教学配置：文件不存在 / 加载失败 / 字段缺失均降级，
## 保留内置 [PLACEHOLDER] 三步文案与奖励，绝不崩、绝不产生 SCRIPT ERROR。
func _load_optional_config() -> void:
	_config_loaded = false
	if not ResourceLoader.exists(config_path):
		_degrade_reason = "可选教学配置不存在：" + config_path
		push_warning("[Tutorial] 可选教学配置不存在（%s）→ 使用内置 [PLACEHOLDER] 三步文案/奖励（依赖缺失降级，不崩）" % config_path)
		return
	var res: Resource = ResourceLoader.load(
			config_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	if res == null:
		_degrade_reason = "可选教学配置加载失败：" + config_path
		push_warning("[Tutorial] 可选教学配置加载失败 → 使用内置 [PLACEHOLDER] 三步文案/奖励（降级，不崩）")
		return
	_config_loaded = true
	# 软读 Rank-2 数据表每步的 prompt / expected_action / reward_points；
	# 字段缺失 / 类型不符一律回落内置 [PLACEHOLDER] 默认，不崩、不改既有 action 映射。
	if _prop_exists(res, "steps"):
		var raw: Variant = res.get("steps")
		if typeof(raw) == TYPE_ARRAY:
			var arr: Array = raw as Array
			for i: int in range(mini(arr.size(), TOTAL_STEPS)):
				var prompt: String = _row_string(arr[i], "prompt")
				if not prompt.is_empty():
					_step_texts[i] = prompt
				var hint: String = _row_string(arr[i], "expected_action")
				if not hint.is_empty():
					_step_hints[i] = hint
				var pts: int = _row_int(arr[i], "reward_points")
				if pts > 0:
					_step_rewards[i] = pts
	print("[Tutorial] 可选教学配置已读：%s | texts=%s hints=%s rewards=%s" % [
			config_path, str(_step_texts), str(_step_hints), str(_step_rewards)])


func _prop_exists(obj: Object, prop: String) -> bool:
	for p: Dictionary in obj.get_property_list():
		if String(p.get("name", "")) == prop:
			return true
	return false


func _row_string(row: Variant, field: String) -> String:
	if typeof(row) == TYPE_DICTIONARY:
		var d: Dictionary = row as Dictionary
		if d.has(field):
			return str(d[field])
	elif row is Object and _prop_exists(row as Object, field):
		return str((row as Object).get(field))
	return ""


func _row_int(row: Variant, field: String) -> int:
	if typeof(row) == TYPE_DICTIONARY:
		var d: Dictionary = row as Dictionary
		if d.has(field) and (typeof(d[field]) == TYPE_INT or typeof(d[field]) == TYPE_FLOAT):
			return int(d[field])
	elif row is Object and _prop_exists(row as Object, field):
		var v: Variant = (row as Object).get(field)
		if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
			return int(v)
	return 0

# ==========================================================================
# 2) flag 读写 / 落盘（经 I-1 唯一入口，依赖缺失降级、不崩）
# ==========================================================================
func _read_completed_flag() -> bool:
	if _world_state != null and _world_state.has_method("get_flag"):
		return bool(_world_state.call("get_flag", FLAG_TUTORIAL_COMPLETED, false))
	return _completed_flag


## A26：只读世界持久层「历史最高教学进度」（int，缺失回落 0）。
## 绝不用于教学 HUD 进度显示；仅供回放 / 集成层 / 验证读回世界 flag 真值。
func _read_step_index_flag() -> int:
	if _world_state != null and _world_state.has_method("get_flag"):
		return int(_world_state.call("get_flag", FLAG_TUTORIAL_STEP_INDEX, 0))
	return _world_step_index_mirror


## A26：按 max 写世界持久层「历史最高教学进度」（只入队 set_flag，绝不新增 commit）。
## progress = 本步完成后的累计进度（1..TOTAL_STEPS）。只有 best > 旧值才写，
## 绝不回写更小值 —— T 重开 / 外部落后值都无法把历史最高拉回退（与 §4.4
## quest_stages「取较大值」同机制）。依赖缺失时只推进进程内镜像、绝不谎报落盘、不崩。
func _stage_step_index_max(progress: int) -> void:
	var cur: int = _read_step_index_flag()
	var best: int = maxi(cur, progress)
	if best <= cur:
		return
	if _world_state != null and _world_state.has_method("set_flag"):
		_world_state.call("set_flag", FLAG_TUTORIAL_STEP_INDEX, best)
	_world_step_index_mirror = best


## A26 集成层只读接口：运行时教学游标（教学 HUD 进度显示取此值，T 重开归零）。
func get_runtime_step_index() -> int:
	return _step_index


## A26 集成层只读接口：世界持久层历史最高进度（绝不用于进度显示）。
func get_world_step_index() -> int:
	return _read_step_index_flag()


## 单向写 grace.tutorial.completed=true（绝不 false 回写）；
## 先 set_flag 入队 → commit(reason) 强制原子落盘 → 才更新运行期镜像。
func _write_completed_flag() -> void:
	if _world_state != null and _world_state.has_method("set_flag"):
		_world_state.call("set_flag", FLAG_TUTORIAL_COMPLETED, true)
		_commit(COMMIT_REASON_COMPLETED)
	else:
		_degrade_reason = "WorldState 不可用：grace.tutorial.completed 仅进程内标记、未落盘（降级，不崩）"
		push_warning("[Tutorial] " + _degrade_reason)
	_completed_flag = true


## 每步赐福点数奖励：单调累加 grace.trial.points（绝不回退、绝不 removals）。
## 已完成存档按 T 重开时返回 0（防重复刷点）；依赖缺失时如实降级、不崩。
## A26：同一步内把世界持久层 step_index 按 max 推进（_stage_step_index_max），
##   与点数奖励共用既有这一次 commit("tutorial_step_reward")，不新增落盘点。
## 返回本次实际发放点数，随 tutorial_step_completed(step_id, reward) 一并发给监听者。
func _grant_reward(_step_id: String) -> int:
	if _read_completed_flag():
		return 0
	# 单步奖励取 Rank-2 数据表（20/30/50 梯度）；配置缺失时回落内置 [PLACEHOLDER] 默认。
	var amount: int = _step_rewards[_step_index]
	if _world_state != null and _world_state.has_method("get_flag") \
			and _world_state.has_method("set_flag"):
		var cur: int = int(_world_state.call("get_flag", FLAG_POINTS, 0))
		_world_state.call("set_flag", FLAG_POINTS, cur + amount)
		# A26：本步完成后的累计进度按 max 写世界持久层（T 重开绝不回退）。
		_stage_step_index_max(_step_index + 1)
		_commit(COMMIT_REASON_STEP)
	else:
		_degrade_reason = "WorldState 不可用：赐福点数奖励未落盘（降级，不崩）"
		push_warning("[Tutorial] " + _degrade_reason)
		# A26：降级路径只推进进程内镜像（单调不回退），绝不谎报已落盘。
		_stage_step_index_max(_step_index + 1)
	_total_reward += amount
	return amount


func _commit(reason: String) -> void:
	if _delta_writer == null or not _delta_writer.has_method("commit"):
		_degrade_reason = "SaveDeltaWriter 未就绪：flag / 奖励仅进程内内存、未落盘（降级，不崩）"
		return
	_delta_writer.call("commit", reason)
	_commit_count += 1

# ==========================================================================
# 3) 状态机：进入 / 逐步完成 / 完成收口 / T 重开 / 强制完成
# ==========================================================================
func is_tutorial_active() -> bool:
	return _state == State.STEP_LIGHT_ATTACK or _state == State.STEP_ROLL \
		or _state == State.STEP_GRACE_SHOP


## 进入（或重开）教学：状态回第一步、冻结三波、刷新金色引导行。
## 【A26】只重置【运行时】游标 / 提示 / 会话奖励 / 波次衔接态：
##   绝不回写 / 清零 grace.tutorial.step_index 世界持久层，绝不清除
##   grace.tutorial.completed（false→true 单向）。世界 flag 由 _stage_step_index_max
##   按 max 单独维护，T 重开前后恒不回退。
func _enter_tutorial() -> void:
	_state = State.STEP_LIGHT_ATTACK
	_step_index = 0                  # A26：仅运行时游标归零（世界 flag 不动）
	_step_events.clear()
	_total_reward = 0
	_wave_started = false
	if _wave != null and _wave.has_method("set_tutorial_freeze"):
		_wave.call("set_tutorial_freeze", true)
		_wave_frozen = true
	else:
		_wave_frozen = false
		push_warning("[Tutorial] WaveTrialDirector 不可用/无冻结接口：教学期三波冻结未接线（降级，不崩）")
	_refresh_hud()
	print("[Tutorial] 教学开始：STEP_LIGHT_ATTACK（J）｜ 波次冻结，教学期间不推进三波")


## 完成当前一步：发信号 + 给赐福点数奖励 + 推进状态；第三步后写单向 flag 并进第 1 波。
func _complete_current_step() -> void:
	if not is_tutorial_active():
		return
	var step_id: String = STEP_IDS[_step_index]
	var reward: int = _grant_reward(step_id)
	_step_events.append(step_id)
	tutorial_step_completed.emit(step_id, reward)
	_step_index += 1
	if _step_index >= TOTAL_STEPS:
		_finalize()
	else:
		_state = STEP_ORDER[_step_index]
	_refresh_hud()
	print("[Tutorial] 步骤完成 step=%s reward=%d → state=%s（%d/%d）" % [
			step_id, reward, STATE_NAMES[_state], mini(_step_index + 1, TOTAL_STEPS), TOTAL_STEPS])


## 三步收口：状态 → COMPLETED、写单向完成 flag、解冻三波并自动进第 1 波、发完成信号。
func _finalize() -> void:
	_state = State.COMPLETED
	_write_completed_flag()
	_unfreeze_and_start_wave()
	tutorial_completed.emit()
	print("[Tutorial] 三步教学完成：%s=true（单向）｜ 赐福标题点亮（读三段式 flag）｜ 自动进第 1 波"
			% FLAG_TUTORIAL_COMPLETED)


func _unfreeze_and_start_wave() -> void:
	if _wave == null:
		push_warning("[Tutorial] WaveTrialDirector 不可用：无法自动进第 1 波（降级，不崩）")
		return
	if _wave.has_method("begin_wave_after_tutorial"):
		_wave_started = bool(_wave.call("begin_wave_after_tutorial"))
		_wave_frozen = false
		print("[Tutorial] 波次衔接：begin_wave_after_tutorial()=%s（解冻 + 自动进第 1 波）" % str(_wave_started))
	elif _wave.has_method("set_tutorial_freeze") and _wave.has_method("start_trial"):
		_wave.call("set_tutorial_freeze", false)
		_wave_frozen = false
		_wave_started = bool(_wave.call("start_trial"))
		print("[Tutorial] 波次衔接（兼容入口）：set_tutorial_freeze(false) + start_trial()=%s" % str(_wave_started))
	else:
		push_warning("[Tutorial] WaveTrialDirector 无教学衔接接口：仅解冻登记（降级，不崩）")


## 按 T 强制重开教学：忽略「已完成存档跳过」，状态回第一步并重新冻结三波。
## 已完成存档重开时步骤奖励返回 0（防重复刷点），状态机 / 信号仍完整走一遍。
## 【A26】重开只经 _enter_tutorial() 复位运行时游标与提示；世界持久层
##   grace.tutorial.step_index 保持历史最高（绝不回退），grace.tutorial.completed
##   保持 true（单向不清除）。本函数不调用任何 set_flag / commit。
func restart_tutorial() -> void:
	_enter_tutorial()
	print("[Tutorial] 按 T 强制重开教学（忽略已完成存档）｜ state=%s ｜ 世界 step_index=%d（不回退）" % [
			STATE_NAMES[_state], _read_step_index_flag()])


## 演示序列跳过入口：把剩余步骤一次性完成（每步照常发信号），随后写 flag / 解冻 / 进第 1 波。
## 不在教学激活态时幂等返回，避免与既有演示序列 / 波次自动开始双驱动。
func force_complete() -> void:
	if not is_tutorial_active():
		return
	while is_tutorial_active():
		_complete_current_step()
	print("[Tutorial] force_complete()：演示序列跳过教学，已完成并自动进第 1 波")

# ==========================================================================
# 4) 输入消费（既有 input action + T 键重开）
# ==========================================================================
func _unhandled_input(event: InputEvent) -> void:
	# T 键：任意状态（含已完成存档跳过态 / COMPLETED）强制重开教学。
	# T 不是既有 action，直接按 physical_keycode 判定，不改 project.godot。
	if event is InputEventKey:
		var k: InputEventKey = event as InputEventKey
		if k.pressed and not k.echo \
				and (k.physical_keycode == KEY_T or k.keycode == KEY_T):
			restart_tutorial()
			return
	if not is_tutorial_active():
		return
	# 只消费当前步骤对应的既有 action；错误按键 / 已完成态一律不推进。
	var expected: String = STEP_ACTIONS[_step_index]
	if event.is_action_pressed(expected):
		_complete_current_step()

# ==========================================================================
# 5) 教学 HUD 金色引导行（步骤文案 / 进度 1-3 / 奖励点数）
# ==========================================================================
## 独立的一行金色 Label（courtyard.tscn 的 TutorialHud/TutorialLabel，y≈520）。
## 不改既有四套 HUD 的任何文本；本行只读本导演状态，教学完成后显示完成态。
## 【A26】进度 %d/%d 取【运行时游标】_step_index，绝不读 grace.tutorial.step_index
##   世界持久层 flag —— 后者是单调历史最高进度，T 重开后仍为 3，若用它渲染会
##   错误卡在「3/3」。hud.gd 的 read_tutorial_progress() 同样只认运行时游标。
func _refresh_hud() -> void:
	if _label == null:
		return
	if _state == State.NOT_STARTED:
		_label.text = "赐福引导 · 准备中 ｜ 按 T 开始教学"
	elif _state == State.COMPLETED:
		_label.text = "赐福引导 · 已完成（3/3）｜ 赐福标题已点亮 ｜ 按 T 重开教学"
	else:
		_label.text = "赐福引导 %d/%d ｜ %s（%s） ｜ 完成奖励 +%d 赐福点数 ｜ 按 T 重开" % [
			_step_index + 1, TOTAL_STEPS, _step_texts[_step_index],
			_step_hints[_step_index], _reward_for_current_session()]
	_label.modulate = Color(0.83, 0.68, 0.3, 1.0)


func _reward_for_current_session() -> int:
	return 0 if _read_completed_flag() else _step_rewards[_step_index]

# ==========================================================================
# 6) 集成层只读接口（供 HUD / 演示序列 / 验证脚本 / 运行日志；非探针）
# ==========================================================================
func get_snapshot() -> Dictionary:
	return {
		"state": _state,
		"state_name": STATE_NAMES[_state],
		# A26：step_index = 运行时教学游标（T 重开归零，教学 HUD 进度显示取此值）。
		"step_index": _step_index,
		# A26：world_step_index = 世界持久层历史最高进度（按 max 写、绝不回退）。
		"world_step_index": _read_step_index_flag(),
		"total_steps": TOTAL_STEPS,
		"is_tutorial_active": is_tutorial_active(),
		"completed_flag": _read_completed_flag(),
		"step_events": _step_events.duplicate(),
		"total_reward": _total_reward,
		"step_rewards": _step_rewards.duplicate(),
		"wave_frozen": _wave_frozen,
		"wave_started": _wave_started,
		"commit_count": _commit_count,
		"config_loaded": _config_loaded,
		"degrade_reason": _degrade_reason,
		"tutorial_hud_text": _label.text if _label != null else "",
	}
