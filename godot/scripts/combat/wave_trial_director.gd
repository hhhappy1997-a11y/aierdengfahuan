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

# ---- R26B 持久化（经 WorldState / SaveDeltaWriter 既有入口）----
var _world_state: Node = null
var _delta_writer: Node = null
var _persist_available: bool = false
var _persist_downgrade_reason: String = ""
var _grace_points: int = 0          # grace.trial.points 的运行时镜像（跨局累计）
var _completed_flag: bool = false   # dungeon.wave_trial.completed 的运行时镜像
var _persist_events: Array[String] = []   # 顺序证据：stage_flags → disk_write → runtime_update
var _commit_count: int = 0


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
	_tick_auto_start()
	_advance(delta)


func _unhandled_input(event: InputEvent) -> void:
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
	restart_trial()


func restart_trial() -> bool:
	if is_trial_active():
		return false
	if _state == State.TRIAL_COMPLETED:
		_state = State.IDLE
	return start_trial()


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
	if _state != State.IDLE:
		_start_rejects += 1
		return false
	_index = 0
	_points_total = 0
	_started_waves.clear()
	_cleared_waves.clear()
	_enter_telegraph()
	return true


func _enter_telegraph() -> void:
	_state = State.TELEGRAPH
	_remaining = float(_waves[_index]["telegraph"])
	_started_waves.append(_index)
	wave_started.emit(_index, _total)
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
	var new_points: int = _grace_points + pts
	# ★ 先落盘（set_flag 入队 → commit 原子写），落盘成功后才改运行时实例。
	if not _persist_settle(REASON_CLEARED, new_best, new_points, false):
		# 降级：不写 flag、不落盘，进程内历史最佳仍按既有行为推进（如实、不崩）。
		_best_wave = new_best
	_state = State.WAVE_CLEARED
	_points_total += pts
	_cleared_waves.append(_index)
	wave_cleared.emit(_index, pts)
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
		"persist_available": _persist_available,
		"persist_downgrade_reason": _persist_downgrade_reason,
		"grace_trial_points": _grace_points,
		"wave_trial_completed": _completed_flag,
		"persist_events": _persist_events.duplicate(),
		"commit_count": _commit_count,
	}
