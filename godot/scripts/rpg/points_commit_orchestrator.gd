extends Node

## ===========================================================================
## R34C / v0.11.0 · 点数落盘【生产编排层】（Rank-3 唯一写入，裁决 A56）
##   autoload 单例名 PointsCommitOrchestrator
##   注册（project.godot [autoload]）：
##     PointsCommitOrchestrator="*res://scripts/rpg/points_commit_orchestrator.gd"
##
## 背景（裁决 A48「逻辑存在 / 验证存在 ≠ 玩家真实可达」第三次重演的补齐）：
##   R34 只交付 A55 口径文档 + 三态验证夹具，points_awarded 信号在生产运行时
##   【没有任何订阅者】。本件作为常驻 autoload，是「点数落盘订阅者唯一入口」：
##   把 HUD 只发不写的 points_awarded 真正接进 I-1 权威写入点并落进磁盘 user:// 存档。
##
## 职责（任务单 ①）：
##   1) 订阅 HUD points_awarded(reason, points, source) —— A55 点数落盘唯一权威通道；
##   2) 同时订阅 execution_performed / boon_draft_applied / production_wave_modifier
##      取得去重键 exe:<window_id> / boon:<index> / wave:<index>，防重复领取；
##   3) 按 I-1 写 grace.trial.points（单调递增、只增不减、绝不写 removals、
##      余额 points - spent_points >= 0）、grace.execution.performed 等已登记三段式 flag；
##   4) ★ 严格「先落盘再改运行时实例」：commit(reason) 原子写成功后才更新
##      WorldState 运行时实例并 emit；失败则不改内存、如实告警；
##      SaveDelta 十字段冻结、schema_version=3、不新增顶层字段；
##   5) autoload 早于主场景入树 → HUD 绑定延迟（call_deferred + 按 script / 信号特征查找），
##      写清绑定方式 / 重试 / 失败降级；connect 前 get_signal_connection_list() 去重，
##      _exit_tree / NOTIFICATION_WM_CLOSE_REQUEST 兜底释放。
##
## 安全降级（硬约束）：_ready() 在无 HUD 的纯 --headless --quit / --import /
##   --check-only 场景下不报错、不写盘（只 push_warning 失败降级）。
##   落盘目标可经 configure_slot() 注入独立 PID 临时槽（验证用，绝不碰生产 slot_01）。
##
## Godot --script 纪律：用 Engine.get_main_loop() as SceneTree 取 root 相对查找，
##   不用 get_tree()、不用 /root/... 绝对路径字符串；资源 CACHE_MODE_IGNORE 回读。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。
## ===========================================================================

signal points_committed(reason: String, points: int, total_points: int)
signal committed(reason: String)
signal hud_bound(hud: Node)

const DEFAULT_SLOT_DIR: String = "user://saves/slot_01"
const HUD_SCRIPT_PATH: String = "res://scripts/hud.gd"
const SCHEMA_VERSION: int = 3
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]
const BOUND_SIGNALS: Array[String] = [
	"points_awarded", "execution_performed",
	"boon_draft_applied", "production_wave_modifier",
]
const MAX_BIND_RETRY: int = 6

const K_POINTS: String = "grace.trial.points"
const K_SPENT: String = "grace.trial.spent_points"
const K_PERFORMED: String = "grace.execution.performed"
const K_SELECTED: String = "grace.boon_draft.selected"
const K_COST: String = "grace.boon_draft.cost_applied"

var _slot_dir: String = DEFAULT_SLOT_DIR
var _delta_path: String = DEFAULT_SLOT_DIR + "/delta.json"

var _re: RegEx = null
var _hud: Node = null
var _ws: Node = null
var _bound: bool = false
var _bind_retry: int = 0

## 运行时门控态（不落盘）：事件去重表 + 配对键缓存。
var _claimed: Dictionary = {}
var _pending_exe_key: String = ""
var _pending_wave_key: String = ""
var _fallback_seq: int = 0

## 运行时 flag 镜像（"先落盘后改运行时实例"里的实例；落盘成功后才更新）。
var _runtime_flags: Dictionary = {}

## 观测计数（供「生产订阅者存在性证据」/ 验证断言只读）。
var _commit_count: int = 0
var _last_reason: String = ""
var _last_points: int = 0


func _ready() -> void:
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	_ws = _find_world_state()
	_runtime_flags = {
		K_POINTS: 0, K_SPENT: 0, K_PERFORMED: 0,
		K_SELECTED: "", K_COST: false,
	}
	# autoload 早于主场景入树 → 延迟绑定（绝不在 _ready 里立即连尚未入树的 HUD）。
	call_deferred("_deferred_bind")


## 相对 root 查找 WorldState 单例（不用 /root/... 绝对路径字符串）。
func _find_world_state() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(NodePath("WorldState"))


## 注入独立 PID 临时槽（验证脚本专用；生产默认 DEFAULT_SLOT_DIR）。
## 只改落盘目标路径，不改 SaveDelta 十字段结构 / 不改 project.godot。
func configure_slot(slot_dir: String) -> bool:
	if slot_dir.is_empty() or slot_dir == DEFAULT_SLOT_DIR:
		return false
	_slot_dir = slot_dir
	_delta_path = slot_dir + "/delta.json"
	return true


# ---------------------------------------------------------------------------
# ⑤ 延迟绑定 / 重试 / 失败降级 / 去重 connect / 兜底释放
#   绑定方式：_ready() 用 call_deferred 延迟到主场景入树后，_scan_hud() 递归扫 root
#             按「script resource_path == hud.gd」或「4 个 R34 信号特征」鸭子类型识别
#             HUD（不静态引用 class_name）；bind_hud() 为确定性显式入口。
#   重试：_deferred_bind() 未找到 HUD 时递归 call_deferred，最多 MAX_BIND_RETRY 次。
#   失败降级：重试耗尽仍无 HUD → push_warning，不订阅、不写盘、不报错
#             （无 HUD 的纯 --headless --quit / --import 场景安全）。
# ---------------------------------------------------------------------------

func _deferred_bind() -> void:
	if _bound:
		return
	var hud: Node = _find_hud()
	if hud != null:
		bind_hud(hud)
		return
	_bind_retry += 1
	if _bind_retry <= MAX_BIND_RETRY:
		call_deferred("_deferred_bind")
	else:
		push_warning("[R34C][PCO] HUD 未就绪（重试 %d 次）→ 绑定降级：不订阅、不写盘" % MAX_BIND_RETRY)


func _find_hud() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return _scan_hud(tree.root)


func _scan_hud(n: Node) -> Node:
	var scr: Script = n.get_script() as Script
	var script_ok: bool = scr != null and scr.resource_path == HUD_SCRIPT_PATH
	var sig_ok: bool = n.has_signal("points_awarded") \
		and n.has_signal("execution_performed") \
		and n.has_signal("boon_draft_applied") \
		and n.has_signal("production_wave_modifier")
	if script_ok or sig_ok:
		return n
	for c: Node in n.get_children():
		var found: Node = _scan_hud(c)
		if found != null:
			return found
	return null


## 显式绑定入口（正常游戏由 _deferred_bind 调；--script 验证进程直接调以保证确定性）。
## connect 前用 get_signal_connection_list() 去重，绝不重复连接。
func bind_hud(hud: Node) -> bool:
	if hud == null or not is_instance_valid(hud):
		return false
	_hud = hud
	var connected: int = 0
	for sig: String in BOUND_SIGNALS:
		if not hud.has_signal(sig):
			continue
		var method: String = "_on_" + sig
		var cb: Callable = Callable(self, method)
		var exists: bool = false
		for conn in hud.get_signal_connection_list(sig):
			var c: Callable = conn.get("callable", Callable())
			if c.get_object() == self and String(c.get_method()) == method:
				exists = true
				break
		if not exists:
			hud.connect(sig, cb)
		connected += 1
	_bound = connected == BOUND_SIGNALS.size()
	if _bound:
		hud_bound.emit(hud)
		print("[R34C][PCO] 生产订阅者已绑定 HUD | signals=%d slot=%s（A55 唯一权威通道）" % [
			connected, _slot_dir])
	else:
		push_warning("[R34C][PCO] HUD 信号不全，绑定降级（connected=%d/%d）" % [
			connected, BOUND_SIGNALS.size()])
	return _bound


func _release() -> void:
	if _hud != null and is_instance_valid(_hud):
		for sig: String in BOUND_SIGNALS:
			var cb: Callable = Callable(self, "_on_" + sig)
			if _hud.has_signal(sig) and _hud.is_connected(sig, cb):
				_hud.disconnect(sig, cb)
	_hud = null
	_bound = false


func _exit_tree() -> void:
	_release()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_release()


## 只读观测（生产订阅者存在性证据 / 验证断言）。
func get_status() -> Dictionary:
	return {
		"bound": _bound,
		"hud": _hud != null,
		"slot": _slot_dir,
		"commit_count": _commit_count,
		"last_reason": _last_reason,
		"last_points": _last_points,
		"points": int(_runtime_flags.get(K_POINTS, 0)),
		"performed": int(_runtime_flags.get(K_PERFORMED, 0)),
		"claimed": _claimed.keys(),
		"pending_exe_key": _pending_exe_key,
		"pending_wave_key": _pending_wave_key,
	}


# ---------------------------------------------------------------------------
# ② 关联信号：取得配对去重键（exe / boon / wave）
# ---------------------------------------------------------------------------

## execution_performed(window_id, bonus_points)：配对键【保留不消费】，
## 同一处决被重复领取时仍解析到同一 exe:<window_id> → 去重拒绝（A55）。
func _on_execution_performed(window_id: String, _bonus_points: int) -> void:
	_pending_exe_key = "exe:" + window_id


## production_wave_modifier(wave_index, ...)：波次开始广播的 wave:<index> 配对键。
func _on_production_wave_modifier(wave_index: int, _effect_key: String,
		_effect_value: float, _cost_key: String, _cost_value: float) -> void:
	_pending_wave_key = "wave:" + str(wave_index)


## boon_draft_applied(index, ...)：boon:<index> 防重复领取；只登记已登记三段式 flag，
## 绝不动 grace.trial.points / spent_points（保「只增不减 / 余额 >= 0」不变量）。
func _on_boon_draft_applied(index: int, choice_id: String, _effect_key: String,
		_effect_value: float, _cost_key: String, _cost_value: float) -> void:
	var key: String = "boon:" + str(index)
	if _claimed.has(key):
		return
	var writes: Dictionary = {K_SELECTED: choice_id, K_COST: true}
	if _commit("boon_draft_cost_applied", writes, 0, int(_runtime_flags.get(K_POINTS, 0))):
		_claimed[key] = true


# ---------------------------------------------------------------------------
# ① A55 唯一权威通道：points_awarded(reason, points, source)
# ---------------------------------------------------------------------------

func _on_points_awarded(reason: String, points: int, source: String) -> void:
	if points < 0:
		push_warning("[R34C][PCO] 负点数拒绝（只增不减、绝不回退 points）：%d" % points)
		return
	# 去重键：优先配对信号（exe / wave），缺失时降级为唯一键（不误判重复领取）。
	var key: String = _resolve_event_key(reason, points, source)
	if _claimed.has(key):
		push_warning("[R34C][PCO] 重复领取拒绝 | event_key=%s reason=%s points=%d source=%s" % [
			key, reason, points, source])
		return
	var cur_points: int = int(_runtime_flags.get(K_POINTS, 0))
	var new_points: int = cur_points + points
	if new_points < cur_points:
		push_warning("[R34C][PCO] 点数溢出保护，本次不落盘")
		return
	var writes: Dictionary = {K_POINTS: new_points}
	if reason == "execution":
		writes[K_PERFORMED] = int(_runtime_flags.get(K_PERFORMED, 0)) + 1
	# ★ 先落盘；成功才登记去重键 + 更新运行时实例 + emit。
	if _commit("points_awarded_" + reason, writes, points, new_points):
		_claimed[key] = true


func _resolve_event_key(reason: String, points: int, source: String) -> String:
	if reason == "execution" and not _pending_exe_key.is_empty():
		return _pending_exe_key
	if reason == "wave_cleared" and not _pending_wave_key.is_empty():
		return _pending_wave_key
	# 无配对键时以 (reason, points, source) 指纹去重：同一事件重放 → 同键 → 拒绝二次领取；
	# 配对键存在时优先配对键（exe:<window_id> / wave:<index>），不同事件由配对 id / 指纹区分。
	return "auto:%s:%d:%s" % [reason, points, source]


# ---------------------------------------------------------------------------
# ③④ 先落盘再改运行时实例 · commit(reason) 原子写 · 十字段冻结
# ---------------------------------------------------------------------------

## commit(reason)：① 取结算 → ② 计算新值 → ③ ★ 原子写盘 →
## ④ ★ 成功后才更新 WorldState 运行时实例 + emit → ⑤ 失败不改内存、如实告警。
func _commit(reason: String, writes: Dictionary, awarded_points: int, new_total: int) -> bool:
	# 惰性初始化：--script 模式下 autoload 的 _ready() 可能未 flush（引擎退出阶段才补跑），
	# 绝不依赖 _ready() 已执行 → 正则 / 运行时镜像就地补齐（安全降级、不 null 解引用）。
	if _re == null:
		_re = RegEx.new()
		_re.compile(FLAG_KEY_REGEX)
	if _runtime_flags.is_empty():
		_runtime_flags = {
			K_POINTS: 0, K_SPENT: 0, K_PERFORMED: 0,
			K_SELECTED: "", K_COST: false,
		}
	# 磁盘为唯一权威：读现有 delta.json（旧档缺 key 回落基线），不依赖内存实例。
	var delta: Dictionary = _read_delta()
	var flags: Dictionary = delta.get("flags", {}) as Dictionary
	# ② 应用本次结算（三段式正则 / 标量白名单校验）
	for k: Variant in writes.keys():
		var key: String = String(k)
		if _re == null or _re.search(key) == null:
			push_warning("[R34C][PCO] 非法三段式 flag key，本次不落盘：%s" % key)
			return false
		var val: Variant = writes[k]
		if not _is_scalar(val):
			push_warning("[R34C][PCO] 非标量 flag value，本次不落盘：%s" % key)
			return false
		flags[key] = val
	# 只增不减 + 余额非负硬约束
	var p: int = int(flags.get(K_POINTS, 0))
	var s: int = int(flags.get(K_SPENT, 0))
	if p < int(_runtime_flags.get(K_POINTS, 0)):
		push_warning("[R34C][PCO] grace.trial.points 回退被拒（只增不减）")
		return false
	if p - s < 0:
		push_warning("[R34C][PCO] 余额 points - spent_points < 0，本次不落盘")
		return false
	# 十字段冻结 / schema_version=3 / removals 恒空（reason 仅写 meta.last_commit_reason）
	delta["flags"] = flags
	delta["removals"] = []
	delta["schema_version"] = SCHEMA_VERSION
	delta["seq"] = int(delta.get("seq", 0)) + 1
	var meta: Dictionary = delta.get("meta", {}) as Dictionary
	meta["last_commit_reason"] = reason
	meta["written_at_unix"] = int(Time.get_unix_time_from_system())
	delta["meta"] = meta
	if not _validate_ten_fields(delta):
		push_warning("[R34C][PCO] SaveDelta 十字段校验失败，本次不落盘")
		return false
	# ③ ★ 原子写（.tmp → flush → rename_absolute → delta.json + .bak）
	if not _atomic_write(delta):
		push_warning("[R34C][PCO] commit 失败：磁盘未改 → 运行时实例保持旧值、不 emit | reason=%s" % reason)
		return false
	# ④ ★ 落盘成功后才更新 WorldState 运行时实例（_apply_snapshot 注入磁盘真值）
	_runtime_flags = flags.duplicate(true)
	_sync_world_state(delta)
	_commit_count += 1
	_last_reason = reason
	_last_points = p
	# ⑤ emit（落盘成功后）
	committed.emit(reason)
	points_committed.emit(reason, awarded_points, new_total)
	return true


func _is_scalar(v: Variant) -> bool:
	var t: int = typeof(v)
	return t == TYPE_BOOL or t == TYPE_INT or t == TYPE_FLOAT or t == TYPE_STRING


func _validate_ten_fields(delta: Dictionary) -> bool:
	for k: Variant in delta.keys():
		if not TEN_FIELDS.has(String(k)):
			return false
	for k: String in TEN_FIELDS:
		if not delta.has(k):
			return false
	return true


## 读磁盘 delta.json；缺 key 时 flags 字典自然不含该 key → 计算用 get(...,default) 回落基线，
## 不升级、不重置、不迁移。不存在 / 解析失败 → 新建十字段骨架（schema_version=3）。
func _read_delta() -> Dictionary:
	if FileAccess.file_exists(_delta_path):
		var f: FileAccess = FileAccess.open(_delta_path, FileAccess.READ)
		if f != null:
			var text: String = f.get_as_text()
			f.close()
			var parsed: Variant = JSON.parse_string(text)
			if typeof(parsed) == TYPE_DICTIONARY:
				return (parsed as Dictionary).duplicate(true)
	return _new_delta()


## 与 world_state.gd::_new_delta() / save_delta.gd::baseline_delta() 同构（十字段冻结）。
func _new_delta() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"slot": "slot_01",
		"seq": 0,
		"baseline": {"manifest": "res://data/rpg/world_baseline.tres", "manifest_hash": "", "baseline_version": 1, "resource_ids": []},
		"flags": {},
		"quests": {},
		"inventory": {},
		"spawns": {"defeated": [], "epoch": 0},
		"removals": [],
		"meta": {"playtime_seconds": 0, "area_id": "", "last_grace_id": "", "written_at_unix": 0, "game_version": "", "last_commit_reason": ""},
	}


func _atomic_write(delta: Dictionary) -> bool:
	var err: Error = DirAccess.make_dir_recursive_absolute(_slot_dir)
	if err != OK and err != ERR_ALREADY_EXISTS:
		return false
	var tmp: String = _delta_path + ".tmp"
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(delta, "\t"))
	f.flush()
	f.close()
	var ren: Error = DirAccess.rename_absolute(tmp, _delta_path)
	if ren != OK:
		return false
	var bak: FileAccess = FileAccess.open(_delta_path + ".bak", FileAccess.WRITE)
	if bak != null:
		bak.store_string(JSON.stringify(delta, "\t"))
		bak.flush()
		bak.close()
	return true


## 更新 WorldState 运行时实例：_apply_snapshot() 把【已落盘的】完整十字段 delta 注入，
## 磁盘为唯一权威，保证重启读回一致；绝不调用 set_flag（避免 0.5s 合并窗口二次覆盖）。
func _sync_world_state(delta: Dictionary) -> void:
	if _ws == null or not is_instance_valid(_ws):
		_ws = _find_world_state()
	if _ws != null and _ws.has_method("_apply_snapshot"):
		_ws.call("_apply_snapshot", delta)
