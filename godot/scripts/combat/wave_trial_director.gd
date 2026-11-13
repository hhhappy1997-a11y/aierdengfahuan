extends Node

## v0.4.0 R26 · 赐福试炼「波次导演层」（Rank-1，cmd-20261111-073556-918-A1）。
## R26B 收口（cmd-20261111-080359-707-A1）：① 自动开始（@export auto_start=true，_ready 后
##       延迟帧 start_trial，演示序列优先不双驱动）② 三 flag 持久化（经 WorldState.get_flag /
##       set_flag + SaveDeltaWriter.commit，先落盘再改运行时实例）③ 赐福点数与存档对齐。
## 挂载：res://scenes/courtyard.tscn 的 WaveTrialDirector（Node，挂在根 Courtyard 下）。
## 职责：编排波次与时序（状态机 + 倒计时 + 信号）、自动开始 / 重开入口、三 flag 落盘；
##       不定义战斗数值、不改存档 schema / 十字段、不构造 flag key 之外的顶层字段。
##       波数 / 每波入场预告 / 时限 / 赐福点数全部运行期读 Rank-2 的
##       res://data/rpg/wave_trial.tres；flag key 与单调性口径归 Rank-3（GDD §6）。
## 状态机：IDLE → TELEGRAPH → WAVE_ACTIVE → WAVE_CLEARED → NEXT_WAVE →（下一波 TELEGRAPH）
##         / TRIAL_COMPLETED；失败 / 超时 → 回赐福休息（IDLE），复用 EncounterDirector
##         既有赐福休息链路（本文件不新增战斗数值、不写 schema、不用 removals）。
## 降级：Rank-2 数据表可能尚未落盘 —— load 失败 / waves 字段缺失 / 波次字段非法时
##       一律降级为「单波默认试炼」，push_warning 如实登记，绝不硬编码三波数值、不崩溃；
##       WorldState / SaveDeltaWriter 未就绪时三 flag 只走进程内运行时、不落盘、不崩。
## 依赖读取全程用 get_property_list()/get()，不引用 WaveTrialConfig / WaveData class_name，
##       使 Rank-2 脚本未落盘时本脚本仍可解析、可降级，绝不产生 SCRIPT ERROR。
## 踩坑对齐：--script / SceneTree 模式 add_child 不 flush _ready（验证脚本显式 call("_ready")）；
##       /root/... 绝对路径不可用（本脚本只用相对 NodePath 与 root.get_node_or_null() 相对探活，
##       经 Engine.get_main_loop() 取 SceneTree）；
##       「先落盘再改运行时实例」在既有 I-1 架构下的映射：set_flag 是 I-1 唯一写入口
##       （同时入队 SaveDelta 与刷新 WorldState 内存 flags），commit(reason) 强制原子写盘；
##       本导演把「set_flag → commit」整体作为「先落盘」步骤，落盘成功后才更新导演自身的
##       运行时镜像（_best_wave / _grace_points / HUD / 信号），不谎称能拆开 I-1 内部。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

signal wave_started(index: int, total: int)
signal wave_cleared(index: int, points: int)
signal trial_completed(best_wave: int)

enum State { IDLE, TELEGRAPH, WAVE_ACTIVE, WAVE_CLEARED, NEXT_WAVE, TRIAL_COMPLETED }
const STATE_NAMES: PackedStringArray = [
	"IDLE", "TELEGRAPH", "WAVE_ACTIVE", "WAVE_CLEARED", "NEXT_WAVE", "TRIAL_COMPLETED"
]

const DEFAULT_TABLE_PATH: String = "res://data/rpg/wave_trial.tres"
# ---- R34 / v0.11.0 最小接线 · 抉择消费方 + 连击评价倍率（Rank-2 唯一写入）----
# 两张表只读（CACHE_MODE_IGNORE 回读真值）；既有 .tres 数值一律不改。
const COMBO_RULES_PATH: String = "res://data/rpg/combo_rules.tres"     # 新增表（R34）
const BOON_DRAFT_PATH: String = "res://data/rpg/boon_draft.tres"       # 既有表（R32），只读
# ---- R35 / v0.12.0 最小接线 · 精准弹反 Parry（Rank-2 唯一写入）----
const PARRY_RULES_PATH: String = "res://data/combat/parry_rules.tres"   # 新增表（R35），只读
# ---- R36 / v0.13.0 最小接线 · 专注值 FP 与战技（Rank-2 唯一写入）----
const FOCUS_RULES_PATH: String = "res://data/combat/focus_rules.tres"   # 新增表（R36），只读
# ---- R37 / v0.14.0 最小接线 · 元素瓶与死亡轮回（Rank-2 唯一写入）----
const FLASK_RULES_PATH: String = "res://data/rpg/flask_rules.tres"      # 新增表（R37），只读
const DEATH_RULES_PATH: String = "res://data/rpg/death_rules.tres"      # 新增表（R37），只读
# ---- R38 / v0.15.0 最小接线 · 大地图野外遭遇（Rank-2 唯一写入）----
const WORLD_ENCOUNTERS_PATH: String = "res://data/rpg/world_encounters.tres"  # 新增表（R38），只读
const REQUIRED_WAVE_FIELDS: PackedStringArray = [
	"telegraph_sec", "time_limit_sec", "reward_points"
]

# [PLACEHOLDER] 降级「单波默认试炼」的兜底时序，非战斗数值、非校准值。
# rationale：Rank-2 数据表缺失时仍需可运行、可断言；取值与任务书状态机
#   TELEGRAPH 1.5s / WAVE_ACTIVE 30s 一致，仅作兜底。表落盘后一律以表内
#   telegraph_sec / time_limit_sec / reward_points 为准，代码不据这些常量定义任何战斗数值。
const DEGRADED_TELEGRAPH_SEC: float = 1.5
const DEGRADED_TIME_LIMIT_SEC: float = 30.0
const DEGRADED_POINTS: int = 0

# R26B · Rank-3 三段式 flag（GDD §6.1 / 契约 §3.3）；只作为 flags 字典内新 key，
# 不新增 SaveDelta 顶层字段、不动 schema_version=3、不用 removals。
const K_BEST: String = "dungeon.wave_trial.best_wave"
const K_COMPLETED: String = "dungeon.wave_trial.completed"
const K_POINTS: String = "grace.trial.points"
# R27：Rank-2 赐福兑换累计消费（单调递增）；余额 = grace.trial.points - grace.trial.spent_points。
# 该 key 由 Rank-2 落盘，本导演只读、带默认 0 降级（Rank-2 未落盘时余额 = 全量 points）。
const K_SPENT: String = "grace.trial.spent_points"
const REASON_CLEARED: String = "wave_trial_cleared"
const REASON_COMPLETED: String = "wave_trial_completed"
const REASON_SETTLED: String = "wave_trial_settled"
# _ready 后延迟帧数再自动开始：给演示序列 / 外部驱动者留出优先窗口（一帧延迟的稳健版）。
const AUTO_START_DELAY_FRAMES: int = 2

@export var table_path: String = DEFAULT_TABLE_PATH
@export var encounter_director_path: NodePath = ^"../EncounterRoot"
@export var hud_label_path: NodePath = ^"../WaveTrialHud/WaveLabel"
## 玩家打开 exe 默认自动进入第 1 波；由 _ready 后延迟帧驱动。
@export var auto_start: bool = true
## 兼容开关：装配层 / 演示序列已显式驱动波次时置 true，自动开始让位（不双驱动）。
@export var has_external_driver: bool = false

var _state: int = State.IDLE
var _index: int = 0
var _total: int = 1
var _remaining: float = 0.0
var _waves: Array[Dictionary] = [
	{"telegraph": DEGRADED_TELEGRAPH_SEC, "time_limit": DEGRADED_TIME_LIMIT_SEC, "points": DEGRADED_POINTS}
]
var _degraded: bool = true
var _degrade_reason: String = "尚未加载数据表"

var _points_total: int = 0
var _best_wave: int = 0
var _grace_rests: int = 0
var _timeouts: int = 0
var _failures: int = 0
var _rejected_finishes: int = 0
var _start_rejects: int = 0
var _started_waves: Array[int] = []
var _cleared_waves: Array[int] = []

var _encounter: Node = null
var _label: Label = null

# ---- R26B 自动开始 ----
var _auto_start_pending: bool = false
var _auto_start_frames: int = 0

# ---- R28 [ROUND=R28] 教学运行时接线 ----
# 教学激活期间冻结三波（不自动开始、不推进、不响应 E 重开）；教学完成后由
# begin_wave_after_tutorial() 解冻并自动进第 1 波。默认 false，既有回归完全等价。
var _tutorial_freeze: bool = false

# ---- R26B 持久化（经 WorldState / SaveDeltaWriter 既有入口）----
var _world_state: Node = null
var _delta_writer: Node = null
var _persist_available: bool = false
var _persist_downgrade_reason: String = ""
var _grace_points: int = 0          # grace.trial.points 的运行时镜像（跨局累计）
var _completed_flag: bool = false   # dungeon.wave_trial.completed 的运行时镜像
var _persist_events: Array[String] = []   # 顺序证据：stage_flags → disk_write → runtime_update
var _commit_count: int = 0

# ---- R34 / v0.11.0 最小接线 · 抉择消费方 + 连击评价（Rank-2 唯一写入）----
# 两个纯逻辑服务实例（RefCounted，装配时读表注入；表/服务未落盘一律降级、不崩）。
# 本轮不接 encounter 命中信号（归 Rank-1），只消费清波 / 波次开始时刻的状态。
var _combo: ComboService = null
var _boon: BoonDraftService = null
# 抉择代价「作用到下一波」：清波时挂起、下一波 _enter_telegraph 时转为生效记录。
var _pending_cost_key: String = ""
var _pending_effect_key: String = ""
var _pending_cost_value: float = 0.0
var _active_cost_key: String = ""
var _active_effect_key: String = ""
var _active_cost_value: float = 0.0
# 最近一次清波结算记录（供 get_snapshot() / 验证脚本 / 后续 HUD 只读消费）。
var _last_settled_points: int = 0
var _last_combo_rank: String = "D"
var _last_combo_multiplier: float = 1.0
var _last_combo_count: int = 0
var _settlement_count: int = 0

# ---- R35 / v0.12.0 最小接线 · 精准弹反 Parry（Rank-2 唯一写入）----
# A54 唯一实例：ParryService 由本导演装配，Rank-1 / Rank-4 经 get_parry_service() 复用。
var _parry: ParryService = null
var _parry_poise_acc: float = 0.0       # 本波弹反成功累积削韧加成（并入既有削韧结算记录）
var _parry_points_acc: int = 0          # 本波弹反成功累积点数加成（并入清波结算基数）
var _parry_success_count: int = 0       # 本局弹反成功累计（只读统计）
var _parry_fail_count: int = 0          # 本局弹反失败累计（只读统计）
var _parry_window_opened_count: int = 0 # 本局开窗累计（生产订阅者实证）
var _parry_last_poise_applied: float = 0.0  # 实际作用于既有 StaggerService.apply_hit 的量
var _parry_last_combo_keep: bool = false
var _parry_last_close_reason: String = ""

# ---- R36 / v0.13.0 最小接线 · 专注值 FP 与战技（Rank-2 唯一写入）----
# A54 唯一实例：FocusService 由本导演装配，Rank-1 / Rank-4 经 get_focus_service() 复用。
var _focus: FocusService = null
var _focus_points_acc: int = 0           # 本波战技 damage 累积（并入清波点数结算基数）
var _focus_poise_acc: float = 0.0        # 本波战技 poise_damage 累积（并入既有削韧结算记录）
var _focus_poise_applied: float = 0.0    # 实际作用于既有 StaggerService.apply_hit 的量
var _focus_spend_count: int = 0          # 本局战技成功累计（只读统计 / A48① 生产订阅者实证）
var _focus_reject_count: int = 0         # 本局战技拒绝累计（只读统计）
var _focus_restore_count: int = 0        # 本局赐福休息回满累计（只读统计）
var _focus_cooldown_ready_count: int = 0 # 本局冷却就绪信号累计（A48① 生产订阅者实证）
var _focus_last_art_id: String = ""
var _focus_last_reject_reason: String = ""

# ---- R37 / v0.14.0 最小接线 · 元素瓶与死亡轮回（Rank-2 唯一写入）----
# A54 唯一实例：FlaskService / DeathService 由本导演装配，Rank-1 / Rank-4 经
#   get_flask_service() / get_death_service() 复用，绝不另建第二个。
var _flask: FlaskService = null
var _death: DeathService = null
# 元素瓶生产订阅者只读计数（A48① 实证）
var _flask_use_count: int = 0
var _flask_reject_count: int = 0
var _flask_restore_count: int = 0
# 死亡轮回生产订阅者只读记录（A48① 实证）
var _death_dropped_points: int = 0       # 最近一次死亡掉落点数（只读记录，绝不回退 points）
var _death_grace_snapshot: int = 0       # 死亡时 grace.trial.points 只读快照
var _death_count: int = 0                # 死亡发生累计
var _respawn_count: int = 0              # 赐福重生累计
var _reclaim_count: int = 0              # 一次性回收累计
var _death_reject_count: int = 0         # 死亡期间/异常拒绝累计
var _death_reclaim_acc: int = 0          # 待并入清波结算的回收点数（并入后清零，不二次入账）
var _life_last_reject_reason: String = ""

# ---- R38 / v0.15.0 最小接线 · 大地图野外遭遇（Rank-2 唯一写入）----
# A54 唯一实例：WorldEncounterService 由本导演装配，Rank-1 / Rank-3 / Rank-4 经
#   get_world_encounter_service() 复用，绝不另建第二个。
var _world: WorldEncounterService = null
var _world_reward_acc: int = 0           # 待并入清波结算的遭遇奖励（并入后清零，不二次入账）
var _world_enter_count: int = 0          # 进入区域累计（A48① 生产订阅者实证）
var _world_trigger_count: int = 0        # 遭遇触发累计（A48① 生产订阅者实证）
var _world_clear_count: int = 0          # 区域清除累计（A48① 生产订阅者实证）
var _world_reject_count: int = 0         # 触发被拒累计（A48① 生产订阅者实证）
var _world_current_region: String = ""   # 最近进入区域（只读记录）
var _world_active_encounter: String = "" # 最近触发的活跃遭遇（只读记录）
var _world_active_region: String = ""    # 最近触发的活跃区域（只读记录）
var _world_last_reject_reason: String = ""


func _ready() -> void:
	_label = get_node_or_null(hud_label_path) as Label
	_bind_encounter()
	_load_table()
	_resolve_persistence()
	_load_persisted_baseline()
	set_process(true)
	set_process_unhandled_input(true)
	_refresh_hud()
	# R27B 裁决 A24：增益运行时挂载接线（在 _ready 之后经既有公开方法作用到运行时实例）。
	_apply_grace_runtime()
	# R34 / v0.11.0 最小接线：装配 ComboService / BoonDraftService（只读两张表，降级不崩）。
	_init_combat_services()
	if auto_start:
		_auto_start_pending = true
		_auto_start_frames = 0


func _exit_tree() -> void:
	if _encounter != null and is_instance_valid(_encounter) \
			and _encounter.has_signal("encounter_finished"):
		var cb: Callable = Callable(self, "_on_encounter_finished")
		if _encounter.is_connected("encounter_finished", cb):
			_encounter.disconnect("encounter_finished", cb)
	_encounter = null


func _process(delta: float) -> void:
	# R28：教学激活期间不推进三波（自动开始与波次时序都冻结，避免与教学双驱动）。
	if _tutorial_freeze:
		return
	_tick_auto_start()
	# R35：精准弹反窗口 / 冷却由导演层每帧确定性推进（纯逻辑不读真实时钟）。
	if _parry != null:
		_parry.tick(delta)
	# R36：专注值冷却由导演层每帧确定性推进（纯逻辑不读真实时钟）。
	if _focus != null:
		_focus.tick(delta)
	_advance(delta)


func _unhandled_input(event: InputEvent) -> void:
	# R28：教学激活期间 E 键由 TutorialDirector 消费推进第三步，本导演不重开一轮。
	if _tutorial_freeze:
		return
	# 赐福休息 / E 键 interact 可重开一轮（既有 EncounterDirector 仍同时处理其 _grace_rest()）。
	if event.is_action_pressed("interact"):
		interact_restart()


# ===========================================================================
# 0) R26B 自动开始 / 兼容开关 / 重开（演示序列优先，不双驱动）
# ===========================================================================

## 一局是否正在进行（排除 IDLE 与 TRIAL_COMPLETED）；供自动开始让位与外部装配判活。
func is_trial_active() -> bool:
	return _state == State.TELEGRAPH or _state == State.WAVE_ACTIVE \
		or _state == State.WAVE_CLEARED or _state == State.NEXT_WAVE


## 兼容开关写入口：演示序列 / 装配层已驱动时置 true，自动开始让位。
func set_external_driver(enabled: bool) -> void:
	has_external_driver = enabled


## _ready 后延迟 AUTO_START_DELAY_FRAMES 帧再自动开始：演示序列 / 外部驱动者若已在
## 首帧 start_trial()，此处检测 is_trial_active() 让位，不重复计数、不重复发信号。
func _tick_auto_start() -> void:
	if not _auto_start_pending:
		return
	_auto_start_frames += 1
	if _auto_start_frames < AUTO_START_DELAY_FRAMES:
		return
	_auto_start_pending = false
	if has_external_driver:
		print("[WaveTrial] 自动开始让位：has_external_driver=true（外部驱动者优先，不双驱动）")
		return
	if is_trial_active():
		print("[WaveTrial] 自动开始让位：演示序列/外部已驱动（is_trial_active=true，不重复计数、不重复发信号）")
		return
	var ok: bool = start_trial()
	print("[WaveTrial] 自动开始：_ready 后延迟 %d 帧 start_trial()=%s → 进入第 1 波（state=%s index=%d/%d）" % [
		AUTO_START_DELAY_FRAMES, str(ok), STATE_NAMES[_state], _index + 1, _total])


## E 键 interact / 赐福休息后重开一轮；一局进行中拒绝（不打断、不重复计数）。
func interact_restart() -> void:
	if _tutorial_freeze:
		return
	restart_trial()


func restart_trial() -> bool:
	if is_trial_active():
		return false
	if _state == State.TRIAL_COMPLETED:
		_state = State.IDLE
	return start_trial()


# ===========================================================================
# 0.05) R28 [ROUND=R28] 教学运行时衔接（既有 0 / 0.1 节逻辑逐字未动）
# ===========================================================================

## 教学激活 / 结束的开关键。冻结时：取消待处理的自动开始；若已有活跃波次
## （例如教学完成后按 T 重开），把运行时状态复位到 IDLE（不落盘、不回退 flag），
## 保证教学期间三波不推进、教学完成后可从第 1 波干净开始。
func set_tutorial_freeze(enabled: bool) -> void:
	_tutorial_freeze = enabled
	if enabled:
		_auto_start_pending = false
		_auto_start_frames = 0
		if is_trial_active() or _state == State.TRIAL_COMPLETED:
			_state = State.IDLE
			_index = 0
			_remaining = 0.0
			_refresh_hud()
		print("[WaveTrial] 教学冻结：三波不自动开始 / 不推进（tutorial_freeze=true）")
	else:
		print("[WaveTrial] 教学解冻：可由 begin_wave_after_tutorial() / 既有 auto_start 进第 1 波")


func is_tutorial_frozen() -> bool:
	return _tutorial_freeze


## 教学完成后的单一衔接入口：先解冻、取消自动开始排队（避免重复 start），
## 再经既有 start_trial() 自动进第 1 波。返回是否真正进入第 1 波。
func begin_wave_after_tutorial() -> bool:
	set_tutorial_freeze(false)
	_auto_start_pending = false
	_auto_start_frames = 0
	if is_trial_active():
		return false
	if _state == State.TRIAL_COMPLETED:
		_state = State.IDLE
	var ok: bool = start_trial()
	print("[WaveTrial] 教学完成 → 自动进第 1 波：start_trial()=%s（state=%s index=%d/%d）" % [
			str(ok), STATE_NAMES[_state], _index + 1, _total])
	return ok


# ===========================================================================
# 0.1) R26B 持久化：依赖相对探活 / 基线读回 / 先落盘再改运行时实例
# ===========================================================================

## 只用 Engine.get_main_loop() + root.get_node_or_null() 相对探活，绝不用 /root/... 绝对路径。
## --script / SceneTree 模式取不到时如实降级，不依赖其结果判 PASS、不崩。
func _resolve_persistence() -> void:
	_world_state = null
	_delta_writer = null
	_persist_available = false
	_persist_downgrade_reason = ""
	var ml: MainLoop = Engine.get_main_loop()
	if ml == null or not (ml is SceneTree):
		_persist_downgrade_reason = "Engine.get_main_loop() 非 SceneTree"
		return
	var tree_root: Node = (ml as SceneTree).get_root()
	if tree_root == null:
		_persist_downgrade_reason = "SceneTree root 不可用"
		return
	var ws: Node = tree_root.get_node_or_null(NodePath("WorldState"))
	var wr: Node = tree_root.get_node_or_null(NodePath("SaveDeltaWriter"))
	if ws != null and ws.has_method("get_flag") and ws.has_method("set_flag"):
		_world_state = ws
	if wr != null and wr.has_method("commit"):
		_delta_writer = wr
	_persist_available = _world_state != null and _delta_writer != null
	if not _persist_available:
		_persist_downgrade_reason = "WorldState / SaveDeltaWriter 未就绪（相对探活 root.get_node_or_null）"


## 启动 / 「重启」时经既有 WorldState.get_flag 读回三个 flag 作为运行时实例基线。
## 依赖缺失时保持 0 / false 并如实 push_warning 降级（不写 flag、不崩）。
func _load_persisted_baseline() -> void:
	_best_wave = 0
	_grace_points = 0
	_completed_flag = false
	if not _persist_available:
		push_warning("[WaveTrial] 持久化依赖缺失（%s）：三 flag 只走进程内运行时、不落盘（降级，不崩）"
				% _persist_downgrade_reason)
		return
	_best_wave = int(_world_state.call("get_flag", K_BEST, 0))
	_grace_points = int(_world_state.call("get_flag", K_POINTS, 0))
	_completed_flag = bool(_world_state.call("get_flag", K_COMPLETED, false))
	print("[WaveTrial] 持久化基线读回：%s=%d / %s=%s / %s=%d（经 WorldState.get_flag）" % [
		K_BEST, _best_wave, K_COMPLETED, str(_completed_flag), K_POINTS, _grace_points])


## 装配 / 验证显式注入（或传 null 显式降级）；不新增顶层字段、不改 schema_version、不用 removals。
func bind_persistence(ws: Node, writer: Node) -> bool:
	if ws != null and ws.has_method("get_flag") and ws.has_method("set_flag"):
		_world_state = ws
	else:
		_world_state = null
	if writer != null and writer.has_method("commit"):
		_delta_writer = writer
	else:
		_delta_writer = null
	_persist_available = _world_state != null and _delta_writer != null
	if not _persist_available:
		_persist_downgrade_reason = "bind_persistence 显式降级（依赖缺失）"
	return _persist_available


## ★ 先落盘：经既有 I-1 写入口把新值入队 SaveDelta（set_flag），再经 SaveDeltaWriter.commit
##   强制原子写盘（.tmp → flush → rename → bak）。落盘成功后才改导演运行时实例。
##   单调保护：每次结算先经 WorldState.get_flag 读回当前值，对 best_wave / points 取 max，
##   保证只增不减、绝不因运行时镜像与磁盘态脱节而把历史值写回退；completed 仅置 true（单向）。
##   事件序列 stage_flags → disk_write → runtime_update 供机器判定「先落盘再改运行时实例」。
func _persist_settle(reason: String, new_best: int, new_points: int, mark_completed: bool) -> bool:
	if not _persist_available:
		return false
	# 公开只读入口：以 WorldState 当前 flag 值为基准做 max 保护（不新增顶层字段、不动 schema）。
	var cur_best: int = int(_world_state.call("get_flag", K_BEST, 0))
	var cur_points: int = int(_world_state.call("get_flag", K_POINTS, 0))
	var safe_best: int = maxi(new_best, cur_best)
	var safe_points: int = maxi(new_points, cur_points)
	_world_state.call("set_flag", K_BEST, safe_best)
	_world_state.call("set_flag", K_POINTS, safe_points)
	if mark_completed:
		_world_state.call("set_flag", K_COMPLETED, true)
	_persist_events.append("stage_flags:" + reason)
	_delta_writer.call("commit", reason)
	_persist_events.append("disk_write:" + reason)
	_commit_count += 1
	# ★ 落盘成功后才改运行时实例镜像（HUD / 信号由调用方随后刷新）。
	_best_wave = safe_best
	_grace_points = safe_points
	if mark_completed:
		_completed_flag = true
	_persist_events.append("runtime_update:" + reason)
	return true


# ===========================================================================
# 1) 数据表读取与降级（数值全部来自 Rank-2 的 .tres，代码零战斗数值硬编码）
# ===========================================================================

func _load_table() -> void:
	if not ResourceLoader.exists(table_path):
		_degrade_to_single("资源不存在：%s" % table_path)
		return
	var res: Resource = ResourceLoader.load(
			table_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	if res == null:
		_degrade_to_single("加载失败：%s" % table_path)
		return
	if not _prop_exists(res, "waves"):
		_degrade_to_single("字段缺失：waves")
		return
	var raw: Variant = res.get("waves")
	if typeof(raw) != TYPE_ARRAY or (raw as Array).is_empty():
		_degrade_to_single("waves 非数组或为空")
		return
	var parsed: Array[Dictionary] = []
	for entry: Variant in (raw as Array):
		# Rank-2 表按「Array[Dictionary] 或等价结构」落盘：同时兼容
		# Dictionary 行与 Resource 行（@export Array[WaveData] 形态）。
		var wave: Dictionary = _parse_wave(entry)
		if wave.is_empty():
			_degrade_to_single("波次条目字段缺失或非法（非 Dictionary / 非 Object、缺 key、非数值、时序<=0）")
			return
		parsed.append(wave)
	_waves = parsed
	_total = parsed.size()
	_degraded = false
	_degrade_reason = ""


func _degrade_to_single(reason: String) -> void:
	_degraded = true
	_degrade_reason = reason
	_waves = [
		{"telegraph": DEGRADED_TELEGRAPH_SEC, "time_limit": DEGRADED_TIME_LIMIT_SEC, "points": DEGRADED_POINTS}
	]
	_total = 1
	push_warning("[WaveTrial] 依赖缺失/字段异常 → 降级为「单波默认试炼」：%s"
			% reason + "（Rank-2 wave_trial.tres 未落盘或字段不完整；不硬编码三波数值、不崩溃、不写 flag）")


## 解析一行波次，返回编排所需的 {telegraph, time_limit, points}；
## 返回空 Dictionary 表示该行不可用（触发整体降级为单波默认试炼）。
## 只取这三项编排字段；enemy_id / hp_multiplier / move_weight 属战斗数值，
## 导演层不读、不定义。兼容 Rank-2 的 Array[Dictionary] 与等价的 Resource 数组。
func _parse_wave(entry: Variant) -> Dictionary:
	var tg: Variant = null
	var tl: Variant = null
	var pts: Variant = null
	if entry is Object:
		var w: Object = entry as Object
		for f: String in REQUIRED_WAVE_FIELDS:
			if not _prop_exists(w, f):
				return {}
		tg = w.get("telegraph_sec")
		tl = w.get("time_limit_sec")
		pts = w.get("reward_points")
	elif typeof(entry) == TYPE_DICTIONARY:
		var d: Dictionary = entry as Dictionary
		for f: String in REQUIRED_WAVE_FIELDS:
			if not d.has(f):
				return {}
		tg = d["telegraph_sec"]
		tl = d["time_limit_sec"]
		pts = d["reward_points"]
	else:
		return {}
	if not _is_number(tg) or not _is_number(tl) or not _is_number(pts):
		return {}
	var tg_f: float = float(tg)
	var tl_f: float = float(tl)
	if tg_f <= 0.0 or tl_f <= 0.0:
		return {}
	return {"telegraph": tg_f, "time_limit": tl_f, "points": int(pts)}


func _prop_exists(obj: Object, prop: String) -> bool:
	for p: Dictionary in obj.get_property_list():
		if String(p.get("name", "")) == prop:
			return true
	return false


func _is_number(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT


## 显式重读数据表（供 Rank-2 表落盘后刷新 / 验证「依赖缺失降级」用）。
func reload_table() -> void:
	_load_table()


## 装配 / 验证注入口：允许外部按 Rank-2 表结构注入波次（Array[Dictionary]，
## 每项 telegraph / time_limit / points）。运行时仍以 _load_table() 读表为准；
## 本接口只用于 Rank-2 表未落盘时的确定性验证与后续装配，不含任何战斗数值。
func configure_waves(waves: Array) -> bool:
	var parsed: Array[Dictionary] = []
	for entry: Variant in waves:
		if typeof(entry) != TYPE_DICTIONARY:
			return false
		var d: Dictionary = entry as Dictionary
		if not d.has("telegraph") or not d.has("time_limit") or not d.has("points"):
			return false
		var tg: float = float(d["telegraph"])
		var tl: float = float(d["time_limit"])
		if tg <= 0.0 or tl <= 0.0:
			return false
		parsed.append({"telegraph": tg, "time_limit": tl, "points": int(d["points"])})
	if parsed.is_empty():
		return false
	_waves = parsed
	_total = parsed.size()
	_degraded = false
	_degrade_reason = ""
	return true


# ===========================================================================
# 2) 状态机（IDLE / TELEGRAPH / WAVE_ACTIVE / WAVE_CLEARED / NEXT_WAVE / TRIAL_COMPLETED）
# ===========================================================================

func start_trial() -> bool:
	# R28：教学激活期间拒绝开试炼（演示序列 / 外部驱动的 start_trial 也不会造成双驱动）。
	if _tutorial_freeze:
		_start_rejects += 1
		return false
	if _state != State.IDLE:
		_start_rejects += 1
		return false
	_index = 0
	_points_total = 0
	_started_waves.clear()
	_cleared_waves.clear()
	# R34：新一局清空接线记录（逐字不改既有状态机分支 / 帧数据 / 输出格式）。
	_reset_r34_records()
	_enter_telegraph()
	return true


func _enter_telegraph() -> void:
	_state = State.TELEGRAPH
	_remaining = float(_waves[_index]["telegraph"])
	_started_waves.append(_index)
	wave_started.emit(_index, _total)
	# R34 最小接线（波次开始）：消费上一波抉择挂起的 cost_key / effect_key，并让连击从本波重算。
	_consume_pending_boon()
	# R35 最小接线（波次开始）：精准弹反从本波干净重算、按 Boss 出招节奏开窗（生产链路）。
	_open_parry_window_for_wave()
	# R36 最小接线（波次开始）：只清本波战技累计，不回满 FP（专注值跨波保留，仅赐福休息回满）。
	_clear_focus_wave_records()
	_refresh_hud()


func _enter_active() -> void:
	_state = State.WAVE_ACTIVE
	_remaining = float(_waves[_index]["time_limit"])
	_refresh_hud()


## 单一时间推进入口：运行时 _process 与验证脚本 debug_advance 走完全相同代码路径。
func _advance(delta: float) -> void:
	var dt: float = maxf(0.0, delta)
	if _state == State.TELEGRAPH:
		_remaining -= dt
		if _remaining <= 0.0:
			_enter_active()
	elif _state == State.WAVE_ACTIVE:
		_remaining -= dt
		if _remaining <= 0.0:
			_on_timeout()
		else:
			_refresh_hud()
	elif _state == State.WAVE_CLEARED:
		if _index + 1 < _total:
			_state = State.NEXT_WAVE
		else:
			# 三波全清：先落盘（completed=true + best_wave max），再改运行时实例 / 发信号。
			var new_best: int = maxi(_best_wave, _total)
			if not _persist_settle(REASON_COMPLETED, new_best, _grace_points, true):
				_best_wave = new_best
			_state = State.TRIAL_COMPLETED
			trial_completed.emit(_best_wave)
		_refresh_hud()
	elif _state == State.NEXT_WAVE:
		_index += 1
		_enter_telegraph()


func debug_advance(sec: float) -> void:
	_advance(sec)


# ===========================================================================
# 3) 接既有 EncounterDirector.encounter_finished(won) 推进波次
# ===========================================================================

## 公开入口：既供 encounter_finished 信号回调，也供验证脚本 / 装配层直接驱动。
## 仅 WAVE_ACTIVE 接受结算：重复触发 / 非激活期一律拒绝并计数，防重复计点与跳波。
func on_encounter_finished(won: bool) -> bool:
	if _state != State.WAVE_ACTIVE:
		_rejected_finishes += 1
		return false
	if won:
		_clear_wave()
	else:
		_failures += 1
		_fail_wave("encounter_finished(false)")
	return true


func _on_encounter_finished(won: bool) -> void:
	on_encounter_finished(won)


func _clear_wave() -> void:
	var pts: int = int(_waves[_index]["points"])
	var new_best: int = maxi(_best_wave, _index + 1)
	# ---- R34 最小接线 ①（wave_cleared）：消费 BoonDraftService.apply()/settle() 的
	#      cost_key / effect_key / points_bonus；抉择代价挂起到「下一波」再生效。
	var base_for_combo: int = pts
	if _boon != null and _boon.has_selection():
		var applied: Dictionary = _boon.apply()
		var boon_settled: Dictionary = _boon.settle(pts)
		if bool(applied.get("ok", false)):
			_pending_cost_key = str(applied.get("cost_key", ""))
			_pending_effect_key = str(applied.get("effect_key", ""))
			_pending_cost_value = float(applied.get("cost_value", 0.0))
		if bool(boon_settled.get("ok", false)):
			base_for_combo = maxi(0, int(boon_settled.get("total_points", pts)))
		_boon.reset()   # 本波抉择已消费完，为下一轮抉择留干净态
	# ---- R35 最小接线 ③：本波弹反成功累积 points_bonus 并入清波点数结算基数 ----
	#      沿用 A57：base_for_combo 经 combo.settle() 得到唯一最终结算值，HUD 经
	#      get_last_settlement() 取该值发 points_awarded 一次入账，绝不二次入账。
	base_for_combo = maxi(0, base_for_combo + _parry_points_acc)
	# ---- R36 最小接线 ③：本波战技 damage 累积并入清波点数结算基数 ----
	#      沿用 A57：base_for_combo 经 combo.settle() 得到唯一最终结算值，
	#      HUD 经 get_last_settlement() 取该值发 points_awarded 一次入账，绝不二次入账。
	base_for_combo = maxi(0, base_for_combo + _focus_points_acc)
	# ---- R37 最小接线 ③：一次性回收掉落点数并入清波点数结算基数 ----
	#      沿用 A55/A57：base_for_combo 经 combo.settle() 得唯一最终结算值，
	#      HUD 经 get_last_settlement() 取该值发 points_awarded 一次入账；
	#      并入后立即清零 _death_reclaim_acc（回收只生效一次、绝不二次入账）。
	base_for_combo = maxi(0, base_for_combo + _death_reclaim_acc)
	_death_reclaim_acc = 0
	# ---- R38 最小接线 ③：大地图野外遭遇奖励并入清波点数结算基数 ----
	#      沿用 A55/A57：base_for_combo 经 combo.settle() 得唯一最终结算值，
	#      HUD 经 get_last_settlement() 取该值发 points_awarded 一次入账；
	#      并入后立即清零 _world_reward_acc（遭遇奖励只入账一次、绝不二次入账）。
	base_for_combo = maxi(0, base_for_combo + _world_reward_acc)
	_world_reward_acc = 0
	# ---- R35：最后一波（Boss 波）死亡 → ParryService 不再开窗 ----
	if _index + 1 >= _total and _parry != null:
		_parry.on_boss_defeated()
	# ---- R34 最小接线 ②：把 ComboService 评级倍率并入清波点数结算。
	var settled_points: int = base_for_combo
	if _combo != null:
		if _index + 1 >= _total:
			_combo.on_boss_defeated()   # 最后一波（Boss 波）→ 死亡结算、定格评级
		var combo_result: Dictionary = _combo.settle(base_for_combo)
		_last_combo_rank = str(combo_result.get("rank", _combo.get_rank()))
		_last_combo_multiplier = float(combo_result.get("multiplier", _combo.get_multiplier()))
		_last_combo_count = _combo.get_combo()
		if bool(combo_result.get("ok", false)):
			settled_points = maxi(0, int(combo_result.get("total_points", base_for_combo)))
	var new_points: int = _grace_points + settled_points
	_last_settled_points = settled_points
	_settlement_count += 1
	# ★ 先落盘（set_flag 入队 → commit 原子写），落盘成功后才改运行时实例。
	if not _persist_settle(REASON_CLEARED, new_best, new_points, false):
		# 降级：不写 flag、不落盘，进程内历史最佳仍按既有行为推进（如实、不崩）。
		_best_wave = new_best
	_state = State.WAVE_CLEARED
	_points_total += settled_points
	_cleared_waves.append(_index)
	wave_cleared.emit(_index, pts)
	# ---- R38 最小接线 ④：清波后标记区域已清除（encounter_cleared 供 Rank-3 落盘）----
	#      只在确有活跃野外遭遇时生效；既有三波试炼正常清波（无 active）完全等价（A77）。
	_mark_world_cleared_on_wave()
	_refresh_hud()


func _on_timeout() -> void:
	_timeouts += 1
	_fail_wave("timeout（WAVE_ACTIVE 倒计时归零；时限以 Rank-2 表 time_limit_sec 为准）")


## 失败 / 超时 → 回赐福休息：状态回 IDLE、不推进波次；best_wave 按已抵达波次取 max
## 先落盘（GDD §6.3 P3 / wave_trial_settled），completed 不动（单向）。
func _fail_wave(reason: String) -> void:
	var new_best: int = maxi(_best_wave, _index + 1)
	if not _persist_settle(REASON_SETTLED, new_best, _grace_points, false):
		_best_wave = new_best
	_state = State.IDLE
	_remaining = 0.0
	_grace_rests += 1
	push_warning("[WaveTrial] 波次失败(%s) → 回赐福休息：index=%d，不推进波次、best_wave 按已抵达波次 max 落盘" % [reason, _index])
	_request_grace_rest()
	_refresh_hud()


func _request_grace_rest() -> void:
	# R36 最小接线：赐福休息回满专注值（生产链路，非验证脚本模拟）。
	if _focus != null:
		_focus.on_grace_rest()
	# R37 最小接线：赐福休息补满元素瓶（生产链路，非验证脚本模拟）。
	if _flask != null:
		_flask.on_grace_rest()
	if _encounter == null:
		push_warning("[WaveTrial] EncounterDirector 不可用：赐福休息仅登记、未实际复位（降级，不崩）")
		return
	if _encounter.has_method("trial_grace_rest"):
		_encounter.call("trial_grace_rest")
	elif _encounter.has_method("debug_grace_rest"):
		_encounter.call("debug_grace_rest")
	else:
		push_warning("[WaveTrial] EncounterDirector 无赐福休息接口：仅登记（降级，不崩）")


func _bind_encounter() -> void:
	var n: Node = get_node_or_null(encounter_director_path)
	if n == null and get_parent() != null:
		n = get_parent().get_node_or_null("EncounterRoot")
	if n == null:
		push_warning("[WaveTrial] 未找到 EncounterDirector：波次推进可用 on_encounter_finished() / bind_encounter_director() 驱动（降级，不崩）")
		return
	bind_encounter_director(n)


func bind_encounter_director(node: Node) -> bool:
	_encounter = node
	if node == null:
		return false
	if not node.has_signal("encounter_finished"):
		push_warning("[WaveTrial] 绑定对象缺少 encounter_finished 信号：仅支持手动 on_encounter_finished()（降级，不崩）")
		return false
	var cb: Callable = Callable(self, "_on_encounter_finished")
	if not node.is_connected("encounter_finished", cb):
		node.connect("encounter_finished", cb)
	return true


# ===========================================================================
# 4) 波次 HUD（只读 Label，由本导演刷新；不改任何既有 HUD 文本）
# ===========================================================================

func _refresh_hud() -> void:
	if _label == null:
		return
	var cd: float = maxf(0.0, _remaining) \
			if (_state == State.TELEGRAPH or _state == State.WAVE_ACTIVE) else 0.0
	var shown: int = clampi(_index + 1, 1, _total)
	# R27 [ROUND=R27] 赐福点数跨局对齐：不再显示本局累计 _points_total，改显示持久化
	# grace.trial.points 的可用余额 = points - grace.trial.spent_points（Rank-2 兑换消费）。
	# 直接经 WorldState.get_flag 公开入口读真值（与 Rank-2 消费口径一致），依赖缺失时
	# 回退运行时镜像 _grace_points、spent 记 0，如实降级、不崩。maxi(0, ·) 防负余额。
	var points: int = _grace_points
	var spent: int = 0
	if _world_state != null and _world_state.has_method("get_flag"):
		points = int(_world_state.call("get_flag", K_POINTS, _grace_points))
		spent = int(_world_state.call("get_flag", K_SPENT, 0))
	var balance: int = maxi(0, points - spent)
	_label.text = "第 %d/%d 波 ｜ 赐福点数 %d ｜ 倒计时 %.1f ｜ 历史最佳 %d" % [
		shown, _total, balance, cd, _best_wave]


# ===========================================================================
# 5) 集成层只读 / 驱动接口（供 HUD、验证脚本与运行日志；非探针，不含数值口径）
# ===========================================================================

# ===========================================================================
# R27B [ROUND=R27B] · 裁决 A24：增益运行时挂载接线（不改 Rank-2 脚本 / 不写 flag）
#   courtyard.tscn 的 WaveTrialDirector 下新增 GraceUpgradeRuntime 节点，
#   本导演在 _ready() 末尾经其既有公开方法 apply_purchased(encounter, ws) 把已购
#   三项（HP 上限 / 翻滚无敌 / 攻击力）作用到运行时实例；ws 传 null → 由 Rank-2
#   脚本自身按 Engine.get_main_loop() 相对探活 WorldState（--script 模式亦可用）。
#   依赖缺失（节点 / 方法 / WorldState / 数据表）如实降级打印、不崩、不产生 SCRIPT ERROR。
#   既有方法 / 信号 / debug_* 签名 / get_snapshot() 键逐字不动。
# ===========================================================================
func _apply_grace_runtime() -> void:
	var rt: Node = get_node_or_null(^"GraceUpgradeRuntime")
	if rt == null or not rt.has_method("apply_purchased"):
		print("[WaveTrial] 增益运行时节点缺失 → 数据已落、效果待接（降级，不崩）")
		return
	var enc: Node = _encounter
	if enc == null:
		enc = get_node_or_null(encounter_director_path)
	var report: Dictionary = rt.call("apply_purchased", enc, null)
	print("[WaveTrial] 增益运行时接线：checked=%s applied=%s degraded=%s reasons=%s" % [
		str(report.get("checked", 0)), str(report.get("applied", 0)),
		str(report.get("degraded", 0)), str(report.get("reasons", []))])
	var items: Array = report.get("items", []) as Array
	for it: Variant in items:
		var row: Dictionary = it as Dictionary
		print("[WaveTrial]   · %s %s status=%s before=%s after=%s via=%s" % [
			str(row.get("id", "")), str(row.get("effect_key", "")),
			str(row.get("status", "")), str(row.get("before", "-")),
			str(row.get("after", "-")), str(row.get("via", row.get("reason", "")))])


# ===========================================================================
# R34 / v0.11.0 最小接线 · 抉择消费方 + 连击评价（Rank-2 唯一写入）
#   - 只新增：装配 / 记录清零 / 「下一波」代价消费 / 只读 getter；
#   - 既有判定分支 / 帧数据 / 输出格式（wave_cleared(index,pts) / HUD 文本 /
#     get_snapshot() 既有 key）/ 既有 .tres 数值一律逐字不动。
#   - 两服务均为 RefCounted 纯逻辑（I-1 不读写存档 / 不碰渲染）；本导演只在
#     真实 wave_cleared / 波次开始两处消费其结算数据，绝不写生产存档。
# ===========================================================================

## 装配两个纯逻辑服务：只读两张表（CACHE_MODE_IGNORE 回读真值），
## 表 / 服务未落盘一律 push_warning 降级、绝不产生 SCRIPT ERROR、不崩。
func _init_combat_services() -> void:
	var combo_cfg: ComboConfig = ResourceLoader.load(
			COMBO_RULES_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as ComboConfig
	var boon_cfg: BoonDraftConfig = ResourceLoader.load(
			BOON_DRAFT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as BoonDraftConfig
	if combo_cfg != null:
		_combo = ComboService.new(combo_cfg)
	else:
		push_warning("[WaveTrial] ComboService 规则表不可用：连击倍率降级为 1.0（不崩）")
	if boon_cfg != null:
		_boon = BoonDraftService.new(boon_cfg)
	else:
		push_warning("[WaveTrial] BoonDraftService 规则表不可用：抉择不作结算（不崩）")
	# ---- R35 / v0.12.0：装配 ParryService 唯一实例 + 生产运行时订阅者 ----
	var parry_cfg: ParryConfig = ResourceLoader.load(
			PARRY_RULES_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as ParryConfig
	if parry_cfg != null:
		_parry = ParryService.new(parry_cfg)
		_bind_parry_signals()
	else:
		push_warning("[WaveTrial] ParryService 规则表不可用：精准弹反降级为不开窗（不崩）")
	# ---- R36 / v0.13.0：装配 FocusService 唯一实例 + 生产运行时订阅者 ----
	var focus_cfg: FocusConfig = ResourceLoader.load(
			FOCUS_RULES_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FocusConfig
	if focus_cfg != null:
		_focus = FocusService.new(focus_cfg)
		_bind_focus_signals()
	else:
		push_warning("[WaveTrial] FocusService 规则表不可用：专注值/战技降级为不可施放（不崩）")
	# ---- R37 / v0.14.0：装配 FlaskService / DeathService 唯一实例 + 生产运行时订阅者 ----
	var flask_cfg: FlaskConfig = ResourceLoader.load(
			FLASK_RULES_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FlaskConfig
	if flask_cfg != null:
		_flask = FlaskService.new(flask_cfg)
		_bind_flask_signals()
	else:
		push_warning("[WaveTrial] FlaskService 规则表不可用：元素瓶降级为不可使用（不崩）")
	var death_cfg: DeathConfig = ResourceLoader.load(
			DEATH_RULES_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as DeathConfig
	if death_cfg != null:
		_death = DeathService.new(death_cfg)
		_bind_death_signals()
	else:
		push_warning("[WaveTrial] DeathService 规则表不可用：死亡轮回降级为不记录（不崩）")
	# ---- R38 / v0.15.0：装配 WorldEncounterService 唯一实例 + 生产运行时订阅者 ----
	var world_cfg: WorldEncounterConfig = ResourceLoader.load(
			WORLD_ENCOUNTERS_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as WorldEncounterConfig
	if world_cfg != null:
		_world = WorldEncounterService.new(world_cfg)
		_bind_world_encounter_signals()
	else:
		push_warning("[WaveTrial] WorldEncounterService 规则表不可用：野外遭遇降级为不触发（不崩）")
	if _combo != null:
		_combo.reset()


## 新一局清空 R34 接线记录（不改既有状态机 / 帧数据 / 输出格式）。
func _reset_r34_records() -> void:
	_pending_cost_key = ""
	_pending_effect_key = ""
	_pending_cost_value = 0.0
	_active_cost_key = ""
	_active_effect_key = ""
	_active_cost_value = 0.0
	_last_settled_points = 0
	_last_combo_rank = "D"
	_last_combo_multiplier = 1.0
	_last_combo_count = 0
	_settlement_count = 0
	# ---- R35：新一局清空精准弹反记录 ----
	_parry_poise_acc = 0.0
	_parry_points_acc = 0
	_parry_success_count = 0
	_parry_fail_count = 0
	_parry_window_opened_count = 0
	_parry_last_poise_applied = 0.0
	_parry_last_combo_keep = false
	_parry_last_close_reason = ""
	# ---- R36：新一局清空专注值/战技记录，并把 FP 回满（新局初始态）----
	_focus_points_acc = 0
	_focus_poise_acc = 0.0
	_focus_poise_applied = 0.0
	_focus_spend_count = 0
	_focus_reject_count = 0
	_focus_restore_count = 0
	_focus_cooldown_ready_count = 0
	_focus_last_art_id = ""
	_focus_last_reject_reason = ""
	if _focus != null:
		_focus.reset()
	if _boon != null:
		_boon.reset()
	# ---- R37：新一局清空元素瓶 / 死亡轮回记录，并复位两个唯一实例 ----
	_flask_use_count = 0
	_flask_reject_count = 0
	_flask_restore_count = 0
	_death_dropped_points = 0
	_death_grace_snapshot = 0
	_death_count = 0
	_respawn_count = 0
	_reclaim_count = 0
	_death_reject_count = 0
	_death_reclaim_acc = 0
	_life_last_reject_reason = ""
	if _flask != null:
		_flask.reset()
	if _death != null:
		_death.reset()
	# ---- R38：新一局清大地图遭遇记录，并复位唯一实例 ----
	_world_reward_acc = 0
	_world_enter_count = 0
	_world_trigger_count = 0
	_world_clear_count = 0
	_world_reject_count = 0
	_world_current_region = ""
	_world_active_encounter = ""
	_world_active_region = ""
	_world_last_reject_reason = ""
	if _world != null:
		_world.reset()


## 波次开始：把上一波清波挂起的「代价 / 效果」作用到本波运行时（消费 cost_key /
## effect_key），并让连击从本波干净重算；不改既有判定分支 / 帧数据 / 输出格式。
func _consume_pending_boon() -> void:
	if _combo != null:
		_combo.reset()
	_active_cost_key = _pending_cost_key
	_active_effect_key = _pending_effect_key
	_active_cost_value = _pending_cost_value
	_pending_cost_key = ""
	_pending_effect_key = ""
	_pending_cost_value = 0.0


## ---- R34 只读 / 驱动接口（供 Rank-1 接线 / 验证脚本 / HUD；不写存档）----
func get_combo_service() -> ComboService:
	return _combo


func get_boon_service() -> BoonDraftService:
	return _boon


# ===========================================================================
# R35 / v0.12.0 最小接线 · 精准弹反 Parry（Rank-2 唯一写入）
#   - A48①：本导演（挂 courtyard.tscn 的生产节点）在装配时 connect 全部 4 信号，
#     生产运行时订阅者真实存在，绝不在验证脚本里才订阅；
#   - A54：唯一实例 _parry 由本导演装配，经 get_parry_service() 供 Rank-1 / Rank-4 复用；
#   - 不改既有判定分支 / 帧数据 / 输出格式 / 既有 .tres 数值；
#   - 弹反奖励并入既有削韧（StaggerService.apply_hit）与清波点数结算基数，
#     沿用 A57 经 points_awarded 发最终值、不二次入账；Rank-2 不写存档、不碰渲染。
# ===========================================================================

## 取本导演装配的 ParryService 唯一实例（供 Rank-1 接线 / Rank-4 视觉反馈 / A54 复用）。
func get_parry_service() -> ParryService:
	return _parry


## A48① 生产订阅者：4 个公开信号在装配时即 connect 到本导演（非验证脚本）。
func _bind_parry_signals() -> void:
	if _parry == null:
		return
	var pairs: Array = [
		["parry_window_opened", "_on_parry_window_opened"],
		["parry_succeeded", "_on_parry_succeeded"],
		["parry_failed", "_on_parry_failed"],
		["parry_window_closed", "_on_parry_window_closed"],
	]
	for p: Array in pairs:
		var sig: String = str(p[0])
		var method: String = str(p[1])
		if not _parry.has_signal(sig):
			continue
		var cb: Callable = Callable(self, method)
		if not _parry.is_connected(sig, cb):
			_parry.connect(sig, cb)
	print("[R35][WaveTrial] 精准弹反生产订阅者已装配：ParryService 唯一实例 + 4 信号 connect（A48①/A54）")


func _on_parry_window_opened(_window_sec: float) -> void:
	_parry_window_opened_count += 1


## 弹反成功：poise_bonus 并入既有削韧、points_bonus 累计到清波结算基数。
## 既有 StaggerService 经 encounter_director.get_stagger_service() 取同一实例（A54 口径延展），
## 调既有 apply_hit()，不改其判定分支；依赖缺失（--script / 无 EncounterDirector）只记录、不崩。
func _on_parry_succeeded(poise_bonus: float, points_bonus: int, combo_keep: bool) -> void:
	_parry_success_count += 1
	var pb: float = maxf(0.0, poise_bonus)
	_parry_poise_acc += pb
	_parry_points_acc = maxi(0, _parry_points_acc + int(points_bonus))
	_parry_last_combo_keep = combo_keep
	var ss: Object = null
	if _encounter != null and is_instance_valid(_encounter) \
			and _encounter.has_method("get_stagger_service"):
		ss = _encounter.call("get_stagger_service") as Object
	if ss != null and is_instance_valid(ss) and ss.has_method("apply_hit"):
		var hit: Dictionary = ss.call("apply_hit", pb) as Dictionary
		if bool(hit.get("ok", false)):
			_parry_last_poise_applied += pb


func _on_parry_failed(_reason: String, _fail_penalty: int) -> void:
	_parry_fail_count += 1
	# fail_penalty 只作记录 / 信号 payload，不扣减既有赐福点数（守住只增不减 / 余额非负）。


func _on_parry_window_closed(reason: String) -> void:
	_parry_last_close_reason = reason


## 波次 / Boss 出招开窗：清上一波窗口 / 冷却 / 本波累计，再开本波精准弹反窗口。
func _open_parry_window_for_wave() -> void:
	if _parry == null:
		return
	_parry.reset()
	_parry.open_window()
	# 每波清「本波累计」，避免上一波弹反奖励在下一波清波重复并入（不二次入账）。
	_parry_poise_acc = 0.0
	_parry_points_acc = 0
	_parry_last_poise_applied = 0.0
	print("[R35][WaveTrial] 波次开始精准弹反开窗：index=%d window_sec=%.2f（生产链路，非验证脚本模拟）" % [
			_index + 1, _parry.get_window_sec()])


## ---- R35 真实输入驱动口（供 Rank-1 输入层 / 验证调用；转调 A54 唯一实例）----
func try_parry() -> Dictionary:
	if _parry == null:
		return {"ok": false, "reason": "no_parry_service"}
	return _parry.try_parry()


func on_boss_move_telegraph() -> Dictionary:
	if _parry == null:
		return {"ok": false, "reason": "no_parry_service"}
	return _parry.open_window()


func on_boss_move_landed() -> Dictionary:
	if _parry == null:
		return {"ok": false, "reason": "no_parry_service"}
	return _parry.on_boss_move_landed()


# ===========================================================================
# R36 / v0.13.0 最小接线 · 专注值 FP 与战技（Rank-2 唯一写入）
#   - A48①：本导演（挂 courtyard.tscn 的生产节点）在装配时 connect 全部 4 信号，
#     生产运行时订阅者真实存在，绝不在验证脚本里才订阅；
#   - A54：唯一实例 _focus 由本导演装配，经 get_focus_service() 供 Rank-1 / Rank-4 复用；
#   - 不改既有判定分支 / 帧数据 / 输出格式 / 既有 .tres 数值；
#   - 战技 damage 并入既有清波点数结算基数、poise_damage 并入既有削韧结算，
#     沿用 A57 经 points_awarded 发最终值、不二次入账；Rank-2 不写存档、不碰渲染。
# ===========================================================================

## 取本导演装配的 FocusService 唯一实例（供 Rank-1 接线 / Rank-4 视觉反馈 / A54 复用）。
func get_focus_service() -> FocusService:
	return _focus


## A48① 生产订阅者：4 个公开信号在装配时即 connect 到本导演（非验证脚本）。
func _bind_focus_signals() -> void:
	if _focus == null:
		return
	var pairs: Array = [
		["focus_spent", "_on_focus_spent"],
		["focus_rejected", "_on_focus_rejected"],
		["focus_restored", "_on_focus_restored"],
		["focus_cooldown_ready", "_on_focus_cooldown_ready"],
	]
	for p: Array in pairs:
		var sig: String = str(p[0])
		var method: String = str(p[1])
		if not _focus.has_signal(sig):
			continue
		var cb: Callable = Callable(self, method)
		if not _focus.is_connected(sig, cb):
			_focus.connect(sig, cb)
	print("[R36][WaveTrial] 专注值/战技生产订阅者已装配：FocusService 唯一实例 + 4 信号 connect（A48①/A54）")


## 战技成功：damage 累计到清波结算基数、poise_damage 并入既有削韧。
## 既有 StaggerService 经 encounter_director.get_stagger_service() 取同一实例（A54 口径延展），
## 调既有 apply_hit()，不改其判定分支；依赖缺失（--script / 无 EncounterDirector）只记录、不崩。
func _on_focus_spent(art_id: String, _fp_cost: float, damage: float,
		poise_damage: float, _fp_remaining: float) -> void:
	_focus_spend_count += 1
	_focus_last_art_id = art_id
	_focus_points_acc = maxi(0, _focus_points_acc + int(damage))
	var pd: float = maxf(0.0, poise_damage)
	_focus_poise_acc += pd
	var ss: Object = null
	if _encounter != null and is_instance_valid(_encounter) \
			and _encounter.has_method("get_stagger_service"):
		ss = _encounter.call("get_stagger_service") as Object
	if ss != null and is_instance_valid(ss) and ss.has_method("apply_hit"):
		var hit: Dictionary = ss.call("apply_hit", pd) as Dictionary
		if bool(hit.get("ok", false)):
			_focus_poise_applied += pd


func _on_focus_rejected(_art_id: String, reason: String) -> void:
	_focus_reject_count += 1
	_focus_last_reject_reason = reason


func _on_focus_restored(_fp_before: float, _fp_after: float, _policy: String) -> void:
	_focus_restore_count += 1


func _on_focus_cooldown_ready(_art_id: String) -> void:
	_focus_cooldown_ready_count += 1


## 波次开始：只清「本波累计」，不回满 FP（专注值跨波保留，仅赐福休息回满 / 新局 reset 回满）。
func _clear_focus_wave_records() -> void:
	_focus_points_acc = 0
	_focus_poise_acc = 0.0
	_focus_poise_applied = 0.0
	_focus_last_reject_reason = ""


## ---- R36 真实输入驱动口（供 Rank-1 输入层 / 验证调用；转调 A54 唯一实例）----
func spend_focus(art_id: Variant) -> Dictionary:
	if _focus == null:
		return {"ok": false, "reason": "no_focus_service"}
	return _focus.spend_fp(art_id)


func focus_grace_rest() -> Dictionary:
	if _focus == null:
		return {"ok": false, "reason": "no_focus_service"}
	return _focus.on_grace_rest()


## 抉择三选一注入口（未来 UI / 验证脚本调用）；本导演不替玩家选择、不含数值。
func select_boon(index: Variant) -> Dictionary:
	if _boon == null:
		return {"ok": false, "reason": "no_boon_service"}
	return _boon.select(index)


func get_settlement_snapshot() -> Dictionary:
	return {
		"last_settled_points": _last_settled_points,
		"combo_rank": _last_combo_rank,
		"combo_multiplier": _last_combo_multiplier,
		"combo_count": _last_combo_count,
		"boon_cost_key": _active_cost_key,
		"boon_effect_key": _active_effect_key,
		"boon_cost_value": _active_cost_value,
		"settlement_count": _settlement_count,
		# ---- R35 新增只读 key（既有 key 逐字不动）----
		"parry_points_bonus": _parry_points_acc,
		"parry_poise_bonus": _parry_poise_acc,
		"parry_poise_applied": _parry_last_poise_applied,
		"parry_success_count": _parry_success_count,
		"parry_combo_keep": _parry_last_combo_keep,
		# ---- R36 新增只读 key（既有 key 逐字不动）----
		"focus_points_bonus": _focus_points_acc,
		"focus_poise_bonus": _focus_poise_acc,
		"focus_poise_applied": _focus_poise_applied,
		"focus_spend_count": _focus_spend_count,
		"focus_last_art_id": _focus_last_art_id,
		# ---- R37 新增只读 key（既有 key 逐字不动）----
		"life_reclaim_bonus": _death_reclaim_acc,
		"life_reclaim_count": _reclaim_count,
		"flask_use_count": _flask_use_count,
		"life_death_count": _death_count,
		"life_respawn_count": _respawn_count,
		# ---- R38 新增只读 key（既有 key 逐字不动）----
		"world_reward_bonus": _world_reward_acc,
		"world_cleared_count": _world.get_cleared_count() if _world != null else 0,
	}


func get_snapshot() -> Dictionary:
	return {
		"state": _state,
		"state_name": STATE_NAMES[_state],
		"index": _index,
		"total": _total,
		"remaining": _remaining,
		"points_total": _points_total,
		"best_wave": _best_wave,
		"degraded": _degraded,
		"degrade_reason": _degrade_reason,
		"grace_rests": _grace_rests,
		"timeouts": _timeouts,
		"failures": _failures,
		"rejected_finishes": _rejected_finishes,
		"start_rejects": _start_rejects,
		"started_waves": _started_waves.duplicate(),
		"cleared_waves": _cleared_waves.duplicate(),
		"hud_text": _label.text if _label != null else "",
		# ---- R26B 新增只读字段（既有 key 逐字不动，回归不回退）----
		"auto_start": auto_start,
		"has_external_driver": has_external_driver,
		"is_trial_active": is_trial_active(),
		# ---- R28 新增只读字段（既有 key 逐字不动，回归不回退）----
		"tutorial_frozen": _tutorial_freeze,
		"persist_available": _persist_available,
		"persist_downgrade_reason": _persist_downgrade_reason,
		"grace_trial_points": _grace_points,
		"wave_trial_completed": _completed_flag,
		"persist_events": _persist_events.duplicate(),
		"commit_count": _commit_count,
		# ---- R34 新增只读 key（既有 key 逐字不动，回归不回退）----
		"last_settled_points": _last_settled_points,
		"combo_rank": _last_combo_rank,
		"combo_multiplier": _last_combo_multiplier,
		"combo_count": _last_combo_count,
		"boon_cost_key": _active_cost_key,
		"boon_effect_key": _active_effect_key,
		"boon_cost_value": _active_cost_value,
		"settlement_count": _settlement_count,
		# ---- R35 新增只读 key（既有 27 + R34 8 个 key 逐字不动，回归不回退）----
		"parry_poise_acc": _parry_poise_acc,
		"parry_points_acc": _parry_points_acc,
		"parry_success_count": _parry_success_count,
		"parry_fail_count": _parry_fail_count,
		"parry_window_opened_count": _parry_window_opened_count,
		"parry_poise_applied": _parry_last_poise_applied,
		"parry_last_combo_keep": _parry_last_combo_keep,
		"parry_last_close_reason": _parry_last_close_reason,
		# ---- R36 新增只读 key（既有 27 + R34 8 + R35 8 个 key 逐字不动，回归不回退）----
		"focus_fp": _focus.get_fp() if _focus != null else 0.0,
		"focus_fp_max": _focus.get_fp_max() if _focus != null else 0.0,
		"focus_points_acc": _focus_points_acc,
		"focus_poise_acc": _focus_poise_acc,
		"focus_poise_applied": _focus_poise_applied,
		"focus_spend_count": _focus_spend_count,
		"focus_reject_count": _focus_reject_count,
		"focus_restore_count": _focus_restore_count,
		"focus_cooldown_ready_count": _focus_cooldown_ready_count,
		"focus_last_art_id": _focus_last_art_id,
		"focus_last_reject_reason": _focus_last_reject_reason,
		# ---- R37 新增只读 key（既有 27 + R34 8 + R35 8 + R36 11 个 key 逐字不动）----
		"flask_remaining": _flask.get_flasks() if _flask != null else 0,
		"flask_max": _flask.get_flask_max() if _flask != null else 0,
		"flask_use_count": _flask_use_count,
		"flask_reject_count": _flask_reject_count,
		"flask_restore_count": _flask_restore_count,
		"life_is_dead": _death.is_dead() if _death != null else false,
		"life_dropped_points": _death_dropped_points,
		"life_grace_snapshot": _death_grace_snapshot,
		"life_death_count": _death_count,
		"life_respawn_count": _respawn_count,
		"life_reclaim_count": _reclaim_count,
		"life_reclaim_acc": _death_reclaim_acc,
		"life_reject_count": _death_reject_count,
		"life_last_reject_reason": _life_last_reject_reason,
		# ---- R38 新增只读 key（既有 27 + R34 8 + R35 8 + R36 11 + R37 14 个 key 逐字不动）----
		"world_current_region": _world_current_region,
		"world_active_encounter": _world_active_encounter,
		"world_active_region": _world_active_region,
		"world_reward_acc": _world_reward_acc,
		"world_cleared_count": _world.get_cleared_count() if _world != null else 0,
		"world_enter_count": _world_enter_count,
		"world_trigger_count": _world_trigger_count,
		"world_clear_count": _world_clear_count,
		"world_reject_count": _world_reject_count,
		"world_last_reject_reason": _world_last_reject_reason,
	}


# ===========================================================================
# R37 / v0.14.0 最小接线 · 元素瓶与死亡轮回（Rank-2 唯一写入）
#   - A48①：本导演（挂 courtyard.tscn 的生产节点）在装配时 connect 全部 3+4 信号，
#     生产运行时订阅者真实存在，绝不在验证脚本里才订阅；
#   - A54：唯一实例 _flask / _death 由本导演装配，经 get_flask_service() /
#     get_death_service() 供 Rank-1 / Rank-4 复用，绝不另建第二个；
#   - 不改既有判定分支 / 帧数据 / 输出格式 / 既有 .tres 数值；
#   - 死亡只做只读记录（不回退 grace.trial.points / 绝不写 removals），
#     回收点数并入既有清波结算基数，沿用 A55/A57 经 points_awarded 一次入账、
#     不二次入账；赐福休息补满瓶、重生复位 FP / 瓶 / 连击 / 窗口；
#     Rank-2 不写存档、不碰渲染。
# ===========================================================================

## 取本导演装配的 FlaskService / DeathService 唯一实例（A54：供 Rank-1 / Rank-4 复用）。
func get_flask_service() -> FlaskService:
	return _flask


func get_death_service() -> DeathService:
	return _death


## A48① 生产订阅者：3 个元素瓶信号在装配时即 connect 到本导演（非验证脚本）。
func _bind_flask_signals() -> void:
	if _flask == null:
		return
	var pairs: Array = [
		["flask_used", "_on_flask_used"],
		["flask_rejected", "_on_flask_rejected"],
		["flask_restored", "_on_flask_restored"],
	]
	for p: Array in pairs:
		var sig: String = str(p[0])
		var method: String = str(p[1])
		if not _flask.has_signal(sig):
			continue
		var cb: Callable = Callable(self, method)
		if not _flask.is_connected(sig, cb):
			_flask.connect(sig, cb)
	print("[R37][WaveTrial] 元素瓶生产订阅者已装配：FlaskService 唯一实例 + 3 信号 connect（A48①/A54）")


## A48① 生产订阅者：4 个死亡轮回信号在装配时即 connect 到本导演（非验证脚本）。
func _bind_death_signals() -> void:
	if _death == null:
		return
	var pairs: Array = [
		["death_occurred", "_on_death_occurred"],
		["respawn_performed", "_on_respawn_performed"],
		["points_reclaimed", "_on_points_reclaimed"],
		["action_rejected", "_on_life_action_rejected"],
	]
	for p: Array in pairs:
		var sig: String = str(p[0])
		var method: String = str(p[1])
		if not _death.has_signal(sig):
			continue
		var cb: Callable = Callable(self, method)
		if not _death.is_connected(sig, cb):
			_death.connect(sig, cb)
	print("[R37][WaveTrial] 死亡轮回生产订阅者已装配：DeathService 唯一实例 + 4 信号 connect（A48①/A54）")


func _on_flask_used(_flask_before: int, _flask_after: int, _hp_before: float,
		_hp_after: float, _healed: float) -> void:
	_flask_use_count += 1


func _on_flask_rejected(reason: String, _flask_remaining: int) -> void:
	_flask_reject_count += 1
	_life_last_reject_reason = reason


func _on_flask_restored(_flask_before: int, _flask_after: int, _policy: String) -> void:
	_flask_restore_count += 1


## 死亡发生：★ 只做只读记录，绝不回退 grace.trial.points、绝不写 removals（A59）。
func _on_death_occurred(dropped_points: int, grace_snapshot: int) -> void:
	_death_dropped_points = maxi(0, dropped_points)
	_death_grace_snapshot = maxi(0, grace_snapshot)
	_death_count += 1


## 赐福重生：★ 生产链路复位运行时状态（回满 FP / 瓶、重置连击与窗口）。
## HP 回满由 Rank-1 EncounterDirector 既有赐福休息链路作用到真实 HP 实例
## （Rank-2 不持有 HP、不碰渲染、不写存档）；has_method 相对探活降级不崩。
func _on_respawn_performed(_pending_dropped_points: int) -> void:
	_respawn_count += 1
	if _flask != null:
		_flask.on_grace_rest()          # 回满瓶
	if _focus != null:
		_focus.on_grace_rest()          # 回满 FP / 清冷却
	if _combo != null:
		_combo.reset()                  # 重置连击
	if _parry != null:
		_parry.reset()                  # 重置弹反窗口
	# 清本波累计（不把死亡前的各类加成带进重生后清波结算，不二次入账）
	_focus_points_acc = 0
	_focus_poise_acc = 0.0
	_focus_poise_applied = 0.0
	_parry_points_acc = 0
	_parry_poise_acc = 0.0
	_parry_last_poise_applied = 0.0
	if _encounter != null and is_instance_valid(_encounter) \
			and _encounter.has_method("trial_grace_rest"):
		_encounter.call("trial_grace_rest")
	print("[R37][WaveTrial] 赐福重生复位：FP / 瓶回满、连击与窗口重置（生产链路，非验证脚本模拟）")


## 一次性回收：★ 累计到待结算 acc；由 _clear_wave() 并入 base_for_combo ->
##   combo.settle() -> HUD points_awarded 一次入账（A55/A57），绝不二次入账。
func _on_points_reclaimed(points: int, _grace_snapshot: int) -> void:
	_death_reclaim_acc = maxi(0, _death_reclaim_acc + maxi(0, points))
	_reclaim_count += 1


func _on_life_action_rejected(reason: String, _action_id: String) -> void:
	_death_reject_count += 1
	_life_last_reject_reason = reason


## ---- R37 真实输入驱动口（供 Rank-1 输入层 / 验证调用；转调 A54 唯一实例）----
func use_flask(current_hp: Variant, max_hp: Variant) -> Dictionary:
	if _flask == null:
		return {"ok": false, "reason": "no_flask_service"}
	return _flask.use_flask(current_hp, max_hp)


func flask_grace_rest() -> Dictionary:
	if _flask == null:
		return {"ok": false, "reason": "no_flask_service"}
	return _flask.on_grace_rest()


func on_player_death(grace_points: Variant) -> Dictionary:
	if _death == null:
		return {"ok": false, "reason": "no_death_service"}
	return _death.on_death(grace_points)


func on_grace_respawn() -> Dictionary:
	if _death == null:
		return {"ok": false, "reason": "no_death_service"}
	return _death.on_grace_respawn()


func reclaim_dropped_points() -> Dictionary:
	if _death == null:
		return {"ok": false, "reason": "no_death_service"}
	return _death.reclaim_dropped()


func guard_life_action(action_id: Variant) -> Dictionary:
	if _death == null:
		return {"ok": false, "reason": "no_death_service"}
	return _death.request_action(action_id)


# ===========================================================================
# R38 / v0.15.0 最小接线 · 大地图野外遭遇（Rank-2 唯一写入）
#   - A48①：本导演（挂 courtyard.tscn 的生产节点）在装配时 connect 全部 4 信号，
#     生产运行时订阅者真实存在、有真实职责（acc 累计 / 计数 / active 记录 / 清除），
#     绝不在验证脚本里才订阅；
#   - A54：唯一实例 _world 由本导演装配，经 get_world_encounter_service() 供
#     Rank-1 / Rank-3 / Rank-4 复用，绝不另建第二个；
#   - 不改既有判定分支 / 帧数据 / 输出格式 / 既有 .tres 数值；野外遭遇触发只标记
#     active 并累计奖励来源，结算仍走既有 _clear_wave() / combo.settle() /
#     HUD points_awarded 一次入账（A55/A57），清波后标记区域已清除（A77 既有入口不废）；
#   - 无野外遭遇时 _world_reward_acc 恒 0、_mark_world_cleared_on_wave() 空转，
#     既有三波试炼结算逐字等价；Rank-2 不写存档、不碰渲染。
# ===========================================================================

## 取本导演装配的 WorldEncounterService 唯一实例（A54：供 Rank-1 / Rank-3 / Rank-4 复用）。
func get_world_encounter_service() -> WorldEncounterService:
	return _world


## A48① 生产订阅者：4 个公开信号在装配时即 connect 到本导演（非验证脚本）。
func _bind_world_encounter_signals() -> void:
	if _world == null:
		return
	var pairs: Array = [
		["region_entered", "_on_world_region_entered"],
		["encounter_triggered", "_on_world_encounter_triggered"],
		["encounter_cleared", "_on_world_encounter_cleared"],
		["trigger_rejected", "_on_world_trigger_rejected"],
	]
	for p: Array in pairs:
		var sig: String = str(p[0])
		var method: String = str(p[1])
		if not _world.has_signal(sig):
			continue
		var cb: Callable = Callable(self, method)
		if not _world.is_connected(sig, cb):
			_world.connect(sig, cb)
	print("[R38][WaveTrial] 大地图野外遭遇生产订阅者已装配：WorldEncounterService 唯一实例 + 4 信号 connect（A48①/A54）")


func _on_world_region_entered(region_id: String) -> void:
	_world_enter_count += 1
	_world_current_region = region_id


## 遭遇触发：★ reward_points 只累计到待结算 acc，清波时并入 base_for_combo 一次入账
## （A55/A57）；active 记录供清波后标记区域已清除，绝不二次累计（service 幂等）。
func _on_world_encounter_triggered(encounter_id: String, region_id: String,
		reward_points: int) -> void:
	_world_reward_acc = maxi(0, _world_reward_acc + maxi(0, reward_points))
	_world_trigger_count += 1
	_world_active_encounter = encounter_id
	_world_active_region = region_id


func _on_world_encounter_cleared(_encounter_id: String, _region_id: String,
		_cleared_count: int) -> void:
	_world_clear_count += 1
	_world_active_encounter = ""
	_world_active_region = ""


func _on_world_trigger_rejected(reason: String, _encounter_id: String) -> void:
	_world_reject_count += 1
	_world_last_reject_reason = reason


## 清波后标记区域已清除：取 service 内部 active（唯一真相源）避免与镜像脱节；
## 无 active（既有三波正常清波）空转、不改既有行为；依赖缺失只登记、不崩。
func _mark_world_cleared_on_wave() -> void:
	if _world == null:
		return
	var active: String = _world.get_active_encounter_id()
	if active.is_empty():
		return
	_world.on_encounter_cleared(active)


## ---- R38 真实输入驱动口（供 Rank-1 输入层 / 验证调用；转调 A54 唯一实例）----
func enter_world_region(region_id: Variant) -> Dictionary:
	if _world == null:
		return {"ok": false, "reason": "no_world_service"}
	return _world.enter_region(region_id)


func try_world_encounter(position: Variant) -> Dictionary:
	if _world == null:
		return {"ok": false, "reason": "no_world_service"}
	return _world.try_trigger(position)


func on_world_encounter_cleared(encounter_id: Variant) -> Dictionary:
	if _world == null:
		return {"ok": false, "reason": "no_world_service"}
	return _world.on_encounter_cleared(encounter_id)
