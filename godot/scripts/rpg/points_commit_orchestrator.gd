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
## R35 / v0.12.0「精准弹反 · 消费闭合」追加（A58 / A59 / A60，见文件尾 R35 段）：
##   - A59：接管 grace.trial.spent_points 出口。订阅 boon_draft_applied /
##     production_wave_modifier，把抉择 cost（[PLACEHOLDER] 映射）单调累加进
##     spent_points，与 unlocked flag 同一次 commit 原子写；余额前置门控 / 重复购买拒绝 /
##     绝不写 removals / 绝不回退 points；缺失 / 非法值拒绝并告警。
##   - A58：订阅 parry_performed(window_id, bonus_points, poise_bonus)，
##     exe: / parry: 去重键改接非空唯一 window_id；不同窗口各自入账、不合并。
##   - 保留 A55 / A57：points_awarded 唯一权威通道、points 为倍率后最终结算值、原样采信。
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
## R34C 既有 4 个必需信号（_bound 判定用，保持既有验证脚本 bind_hud 口径兼容）。
const CORE_SIGNALS: Array[String] = [
	"points_awarded", "execution_performed",
	"boon_draft_applied", "production_wave_modifier",
]
## R35 / A58：新增 parry_performed 生产订阅者（编排层 = 生产 autoload，非验证脚本）。
const BOUND_SIGNALS: Array[String] = [
	"points_awarded", "execution_performed",
	"boon_draft_applied", "production_wave_modifier",
	"parry_performed",
]
const MAX_BIND_RETRY: int = 6

const K_POINTS: String = "grace.trial.points"
const K_SPENT: String = "grace.trial.spent_points"
const K_PERFORMED: String = "grace.execution.performed"
const K_SELECTED: String = "grace.boon_draft.selected"
const K_COST: String = "grace.boon_draft.cost_applied"

## ---- R35 / v0.12.0 新增三段式 flag（契约 §3.3 R35 段登记）----
const K_UNLOCKED: String = "grace.boon_draft.unlocked"        # A59 抉择解锁（与 spent_points 同一 commit）
const K_PARRY_COUNT: String = "combat.parry.success_count"    # A60 弹反成功计数（int，单调递增）
const K_PARRY_WID: String = "combat.parry.window_id"          # A58 最近弹反窗口 id（String）

## ---- R36 / v0.13.0 新增三段式 flag（契约 §3.3 R36 段登记 / 裁决 A66）----
## A66：专注值 FP 落盘 flag，与赐福点数 grace.trial.points / spent_points 完全分离。
##  7 个 key 均严格匹配三段式正则 ^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$。
const K_FOCUS_CURRENT: String = "combat.focus.current"             # int 当前专注值（战技减 / 休息回满 / 上限封顶）
const K_FOCUS_MAX: String = "combat.focus.max"                     # int 专注值上限（唯一实例 get_fp_max() 鸭子读）
const K_FOCUS_ART_ID: String = "combat.focus.art_id"               # String 最近成功战技 id
const K_FOCUS_SPEND_COUNT: String = "combat.focus.spend_count"     # int 成功施放累计（单调递增、只增不减）
const K_FOCUS_RESTORE_COUNT: String = "combat.focus.restore_count" # int 赐福休息回满累计（单调递增、只增不减）
const K_FOCUS_POLICY: String = "combat.focus.policy"               # String 最近休息策略（rest_refill / rest_regen）
const K_FOCUS_LAST_REJECT: String = "combat.focus.last_reject"     # String 最近拒绝原因（no_config/invalid_art/...）
## R36 / A48①：3 个 FocusService 信号的生产运行时订阅者 = 本编排层 autoload（非验证脚本）。
const FOCUS_SIGNALS: Array[String] = ["focus_spent", "focus_restored", "focus_rejected"]

## ---- [PLACEHOLDER] cost→points 映射（A59）----
## rationale：Rank-2 boon_draft_service.apply() 的 cost_value 是「下一波敌人难度乘性修正」
##   （hp_scale / telegraph_scale，> 0 的倍率），并非赐福点数；A59 需要把它换算成点数消耗，
##   闭合「行动→反馈→目标→消费成长」循环。当前采用线性换算
##   points_cost = max(MIN, round(cost_value × FACTOR))，是 [PLACEHOLDER] 首版经济占位：
##   真实经济平衡（点数产出速率 vs 抉择代价）须人工试玩校准，headless 真跑不做手感判断。
## 调参唯一入口 = 本常量段（集中一处、只改常量不改逻辑）；目录所有权冻结、本轮不新增数据表。
##   COST_KEY_WHITELIST 与 Rank-2 boon_draft_config.gd::is_cost_key_known 对齐，
##   未来新增 cost_key 须同步本常量（否则按「非法值」拒绝并告警，不静默吞掉）。
const COST_TO_POINTS_FACTOR: float = 10.0   # [PLACEHOLDER]
const COST_TO_POINTS_MIN: int = 1           # [PLACEHOLDER] 最小扣点，防 0 值空转
const COST_KEY_WHITELIST: Array[String] = ["hp_scale", "telegraph_scale"]

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

## ---- R35 运行时门控态（不落盘）----
var _pending_parry_key: String = ""      # A58 parry:<window_id> 配对键（保留不消费，同窗口幂等）
var _pending_parry_wid: String = ""      # A58 最近非空 window_id（供三段式 flag 写入）
var _parry_wid_fallback_seq: int = 0     # A58 空 window_id 降级唯一键计数（不误合并）
var _last_charge_cost_key: String = ""   # A59 production_wave_modifier 对账用
var _last_charge_cost_value: float = 0.0
var _charge_reject_count: int = 0        # A59 观测：缺失 / 非法 / 重复 / 余额不足拒绝计数

## 运行时 flag 镜像（"先落盘后改运行时实例"里的实例；落盘成功后才更新）。
var _runtime_flags: Dictionary = {}

## 观测计数（供「生产订阅者存在性证据」/ 验证断言只读）。
var _commit_count: int = 0
var _last_reason: String = ""
var _last_points: int = 0

## ---- R36 / v0.13.0 运行时态（不落盘）：A54 唯一实例引用 / 上限缓存 / 拒绝观测 ----
var _focus_service: Object = null       # A54：RefCounted 唯一实例，经 wave.get_focus_service() 复用，绝不 new 第二个
var _focus_max_cache: int = 0           # 从唯一实例 get_fp_max() 鸭子读到的上限（运行时观测，不落盘依赖）
var _focus_reject_observed: int = 0     # focus_rejected 观测计数（A48① 生产订阅者存在性证据）
var _focus_bind_retry: int = 0
var _focus_bound: bool = false


func _ready() -> void:
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	_ws = _find_world_state()
	_runtime_flags = {
		K_POINTS: 0, K_SPENT: 0, K_PERFORMED: 0,
		K_SELECTED: "", K_COST: false,
		K_UNLOCKED: false, K_PARRY_COUNT: 0, K_PARRY_WID: "",
	}
	# autoload 早于主场景入树 → 延迟绑定（绝不在 _ready 里立即连尚未入树的 HUD）。
	call_deferred("_deferred_bind")
	# R36 / A66：延迟绑定 A54 唯一 FocusService（生产订阅者；无主场景时安全降级、不写盘）。
	call_deferred("_deferred_bind_focus")


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
## R35：parry_performed 为新增【可选】信号——主场景 HUD 必提供（否则 push_warning 降级，
##   不静默）；_bound 判定只看 4 个 CORE_SIGNALS，保证既有验证脚本 bind_hud 口径兼容。
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
	if not hud.has_signal("parry_performed"):
		push_warning("[R35][PCO] HUD 未提供 parry_performed → A58 弹反去重键降级（不静默、不写盘）")
	var core_ok: bool = true
	for sig: String in CORE_SIGNALS:
		if not hud.has_signal(sig):
			core_ok = false
	_bound = core_ok and connected >= CORE_SIGNALS.size()
	if _bound:
		hud_bound.emit(hud)
		print("[R34C][PCO] 生产订阅者已绑定 HUD | signals=%d slot=%s（A55 唯一权威通道）" % [
			connected, _slot_dir])
	else:
		push_warning("[R34C][PCO] HUD 信号不全，绑定降级（connected=%d/%d）" % [
			connected, BOUND_SIGNALS.size()])
	return _bound


func _release() -> void:
	_release_focus()
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
		"spent": int(_runtime_flags.get(K_SPENT, 0)),
		"unlocked": bool(_runtime_flags.get(K_UNLOCKED, false)),
		"parry_count": int(_runtime_flags.get(K_PARRY_COUNT, 0)),
		"parry_window_id": String(_runtime_flags.get(K_PARRY_WID, "")),
		"performed": int(_runtime_flags.get(K_PERFORMED, 0)),
		"claimed": _claimed.keys(),
		"pending_exe_key": _pending_exe_key,
		"pending_wave_key": _pending_wave_key,
		"pending_parry_key": _pending_parry_key,
		"charge_reject_count": _charge_reject_count,
		"focus_bound": _focus_bound,
		"focus_service": _focus_service != null,
		"focus_max_cache": _focus_max_cache,
		"focus_reject_observed": _focus_reject_observed,
		"focus_current": int(_runtime_flags.get(K_FOCUS_CURRENT, 0)),
		"focus_max": int(_runtime_flags.get(K_FOCUS_MAX, 0)),
		"focus_art_id": String(_runtime_flags.get(K_FOCUS_ART_ID, "")),
		"focus_spend_count": int(_runtime_flags.get(K_FOCUS_SPEND_COUNT, 0)),
		"focus_restore_count": int(_runtime_flags.get(K_FOCUS_RESTORE_COUNT, 0)),
		"focus_policy": String(_runtime_flags.get(K_FOCUS_POLICY, "")),
		"focus_last_reject": String(_runtime_flags.get(K_FOCUS_LAST_REJECT, "")),
	}


# ---------------------------------------------------------------------------
# ② 关联信号：取得配对去重键（exe / boon / wave / parry）
# ---------------------------------------------------------------------------

## execution_performed(window_id, bonus_points)：配对键【保留不消费】，
## 同一处决被重复领取时仍解析到同一 exe:<window_id> → 去重拒绝（A55）。
## R35 / A58：window_id 必须非空唯一；上游若给空串，降级生成唯一键（不误合并、不静默）。
func _on_execution_performed(window_id: String, _bonus_points: int) -> void:
	if window_id.is_empty():
		push_warning("[R35][PCO] A58：execution_performed window_id 为空 → 降级唯一键（不误合并）")
		_fallback_seq += 1
		_pending_exe_key = "exe:fallback_%d" % _fallback_seq
		return
	_pending_exe_key = "exe:" + window_id


## production_wave_modifier(wave_index, ...)：波次开始广播的 wave:<index> 配对键。
## R35 / A59：本信号与 boon_draft_applied 是【同一抉择的两个阶段】（apply 广播 →
##   下一波修正广播）。扣费由唯一权威事件 boon_draft_applied 触发恰好一次；本回调
##   只做 cost 一致性对账 + wave 配对键，★ 绝不二次扣费（spent_points 单调累加恰好一次）。
func _on_production_wave_modifier(wave_index: int, _effect_key: String,
		_effect_value: float, cost_key: String, cost_value: float) -> void:
	_pending_wave_key = "wave:" + str(wave_index)
	if _last_charge_cost_key.is_empty():
		return
	if cost_key != _last_charge_cost_key \
			or not is_equal_approx(cost_value, _last_charge_cost_value):
		push_warning("[R35][PCO] A59 对账告警：wave_modifier cost 与已入账抉择不一致 | wave=%d key=%s value=%.4f" % [
			wave_index, cost_key, cost_value])


## boon_draft_applied(index, choice_id, ...)：A59 抉择扣费唯一权威事件。
##   cost → [PLACEHOLDER] points → spent_points 单调累加；与 K_SELECTED / K_COST /
##   K_UNLOCKED 同一 commit("boon_draft_cost_applied") 原子先落盘。
##   重复购买 / 余额不足 / 缺失·非法值一律拒绝并告警（不回退 points、不写 removals）。
func _on_boon_draft_applied(index: int, choice_id: String, _effect_key: String,
		_effect_value: float, cost_key: String, cost_value: float) -> void:
	_try_charge_boon_cost("boon:" + str(index), choice_id, cost_key, cost_value,
		"boon_draft_cost_applied")


# ---------------------------------------------------------------------------
# ① A55 唯一权威通道：points_awarded(reason, points, source)
# ---------------------------------------------------------------------------

func _on_points_awarded(reason: String, points: int, source: String) -> void:
	if points < 0:
		push_warning("[R34C][PCO] 负点数拒绝（只增不减、绝不回退 points）：%d" % points)
		return
	# 去重键：优先配对信号（exe / wave / parry），缺失时降级为唯一键（不误判重复领取）。
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
	# R35 / A58 / A60：parry 成功入账时，把弹反三段式 flag 与 points 同一次 commit 原子写。
	#   points 仍是 A57「倍率后最终结算值」，编排层原样采信、不二次加工、不自行叠倍率。
	if reason == "parry" and not _pending_parry_wid.is_empty():
		writes[K_PARRY_COUNT] = int(_runtime_flags.get(K_PARRY_COUNT, 0)) + 1
		writes[K_PARRY_WID] = _pending_parry_wid
	# ★ 先落盘；成功才登记去重键 + 更新运行时实例 + emit。
	if _commit("points_awarded_" + reason, writes, points, new_points):
		_claimed[key] = true


func _resolve_event_key(reason: String, points: int, source: String) -> String:
	if reason == "execution" and not _pending_exe_key.is_empty():
		return _pending_exe_key
	# R35 / A58：parry 配对键 = parry:<window_id>（非空唯一）。不同窗口 → 不同键 →
	#   各自入账；同一窗口重放 → 同键 → 去重拒绝（不再被 auto 指纹误合并）。
	if reason == "parry" and not _pending_parry_key.is_empty():
		return _pending_parry_key
	if reason == "wave_cleared" and not _pending_wave_key.is_empty():
		return _pending_wave_key
	# 无配对键时以 (reason, points, source) 指纹去重：同一事件重放 → 同键 → 拒绝二次领取；
	# 配对键存在时优先配对键（exe:<window_id> / parry:<window_id> / wave:<index>），不同事件由配对 id / 指纹区分。
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
			K_UNLOCKED: false, K_PARRY_COUNT: 0, K_PARRY_WID: "",
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


# ===========================================================================
# R35 / v0.12.0「精准弹反 · 消费闭合」追加段（Rank-3 唯一写入）
#   A58：parry_performed 订阅 + parry:<window_id> 去重键 + 弹反三段式 flag
#   A59：spent_points 唯一出口（抉择 cost → [PLACEHOLDER] points → 单调累加）
#   A60：弹反奖励不得点数通胀（每窗口恰好一次、points 原样采信 A57）
#   A48①：parry_performed 的生产运行时订阅者 = 本编排层 autoload（非验证脚本）。
#   A55/A57 口径：points_awarded 仍是点数落盘唯一权威通道，points 为倍率后最终结算值，
#                 编排层原样采信、绝不二次加工 / 绝不自行叠倍率 / 绝不写 removals / 绝不回退 points。
# ===========================================================================

## A58：订阅 HUD parry_performed(window_id, bonus_points, poise_bonus)。
##   Rank-1 已保证 window_id 非空唯一（parry_<wave>_<seq> / exe_<wave>_<seq>）。
##   配对键【保留不消费】：同一窗口重放仍解析到同一 parry:<window_id> → 去重拒绝；
##   不同窗口覆盖成新键 → 各自入账（A58「不同窗口不合并」）。
##   空 window_id 属上游异常 → 降级生成唯一键 + push_warning（不误合并、不静默）。
func _on_parry_performed(window_id: String, _bonus_points: int, _poise_bonus: float) -> void:
	var wid: String = window_id
	if wid.is_empty():
		push_warning("[R35][PCO] A58：parry_performed window_id 为空 → 降级唯一键（不误合并、不静默）")
		_parry_wid_fallback_seq += 1
		wid = "parry_fallback_%d" % _parry_wid_fallback_seq
	_pending_parry_key = "parry:" + wid
	_pending_parry_wid = wid


## A59 缺失 / 非法值校验：cost_key 命中白名单且非空；cost_value 有限且 > 0。
##   拒绝时返回 false，由调用方 push_warning 并拒绝落盘（不回退 points、不写 removals）。
func _validate_cost(cost_key: String, cost_value: float) -> bool:
	if cost_key.is_empty() or not COST_KEY_WHITELIST.has(cost_key):
		return false
	if is_nan(cost_value) or is_inf(cost_value) or cost_value <= 0.0:
		return false
	return true


## [PLACEHOLDER] cost→points 线性映射（rationale / 调参唯一入口见常量段）。
##   cost_value 是「下一波难度倍率」而非点数，故乘 FACTOR 折算；夹取 MIN 防 0 值空转。
func _cost_to_points(_cost_key: String, cost_value: float) -> int:
	var raw: int = int(roundf(cost_value * COST_TO_POINTS_FACTOR))
	return maxi(COST_TO_POINTS_MIN, raw)


## A59 spent_points 唯一出口：抉择 cost → spent_points 单调累加 + unlocked flag 原子写。
##   顺序（沿用 R26 §6.4 / R27 §9.9 / R34C 五步，不得颠倒）：
##     ① 缺失 / 非法值拒绝并告警（不落盘）；
##     ② 重复购买拒绝（dedup_key 命中去重表）；
##     ③ ★ 磁盘为唯一权威：读磁盘 points / spent，余额 points - (spent + cost) >= 0 前置门控；
##     ④ 与 K_SELECTED / K_COST / K_UNLOCKED 同一次 commit(reason) 原子先落盘
##        （writes 绝不含 K_POINTS → 绝不回退 points；_commit 恒 removals=[] → 绝不写 removals）；
##     ⑤ 落盘成功才登记去重键 + 更新运行时实例（_commit 内部完成）+ emit；
##        失败则不改内存、如实告警（已在 _commit / 调用方登记）。
func _try_charge_boon_cost(dedup_key: String, choice_id: String,
		cost_key: String, cost_value: float, reason: String) -> bool:
	# ① 缺失 / 非法值
	if not _validate_cost(cost_key, cost_value):
		_charge_reject_count += 1
		push_warning("[R35][PCO] A59 抉择扣费拒绝（cost 缺失/非法）：key=%s value=%.4f choice=%s" % [
			cost_key, cost_value, choice_id])
		return false
	var cost_points: int = _cost_to_points(cost_key, cost_value)
	if cost_points <= 0:
		_charge_reject_count += 1
		push_warning("[R35][PCO] A59 抉择扣费拒绝（cost→points<=0）：choice=%s" % choice_id)
		return false
	# ② 重复购买
	if _claimed.has(dedup_key):
		_charge_reject_count += 1
		push_warning("[R35][PCO] A59 重复购买拒绝 | dedup_key=%s choice=%s（spent_points 不二次累加）" % [
			dedup_key, choice_id])
		return false
	# ③ 磁盘唯一权威 + 余额前置门控
	var delta: Dictionary = _read_delta()
	var flags: Dictionary = delta.get("flags", {}) as Dictionary
	var p: int = int(flags.get(K_POINTS, 0))
	var s: int = int(flags.get(K_SPENT, 0))
	var new_spent: int = s + cost_points
	if new_spent < s or p - new_spent < 0:
		_charge_reject_count += 1
		push_warning("[R35][PCO] A59 余额不足拒绝（points - spent_points >= 0 前置门控）：points=%d spent=%d cost=%d choice=%s" % [
			p, s, cost_points, choice_id])
		return false
	# ④ 与 unlocked flag 同一次 commit 原子写（绝不回退 points / 绝不写 removals）
	var writes: Dictionary = {
		K_SPENT: new_spent,
		K_SELECTED: choice_id,
		K_COST: true,
		K_UNLOCKED: true,
	}
	if not _commit(reason, writes, 0, p):
		_charge_reject_count += 1
		push_warning("[R35][PCO] A59 commit 失败 → 不解锁、不扣点（磁盘未改） | choice=%s" % choice_id)
		return false
	# ⑤ 落盘成功才登记去重键 + 记录 cost 供 production_wave_modifier 对账
	_claimed[dedup_key] = true
	_last_charge_cost_key = cost_key
	_last_charge_cost_value = cost_value
	return true


# ===========================================================================
# R36 / v0.13.0「专注值与战技 · 画面补齐」追加段（Rank-3 唯一写入）
#   A66：专注值 FP 唯一实例（A54 经 wave.get_focus_service() 复用、绝不 new 第二个）
#         + 落盘归属编排层、与赐福点数分离（不混用 points / spent_points）。
#   A48①：focus_spent / focus_restored / focus_rejected 的生产运行时订阅者 =
#          本编排层 autoload（生产节点，非验证脚本）；验证脚本只调本层
#          bind_focus_service() 显式入口，不在此自建订阅 / 不模拟编排。
#   订阅信号签名逐字来自 Rank-2 DONE-R36.md §3.1 / focus_service.gd：
#     focus_spent(art_id, fp_cost, damage, poise_damage, fp_remaining)
#     focus_restored(fp_before, fp_after, policy)
#     focus_rejected(art_id, reason)
#   口径：十字段冻结 / schema_version=3 / 不写 removals / commit(reason) 原子写 /
#     ★ 先落盘再改运行时实例 / 重启读回一致；FP 与赐福点数分离（focus_writes
#     绝不含 K_POINTS / K_SPENT）；重复释放不二次扣费（FP 新值须严格小于磁盘旧值）。
#   安全降级：无 HUD / 无 WaveTrialDirector 的纯 --headless --quit / --import /
#     --check-only 场景重试耗尽仅 push_warning，不写盘、不报错、不 null 解引用。
# ===========================================================================

## 延迟绑定 A54 唯一 FocusService（autoload 早于主场景入树）。
##   重试耗尽仍无 FocusService → push_warning 降级（不订阅 / 不写盘 / 不报错）。
func _deferred_bind_focus() -> void:
	if _focus_bound:
		return
	var focus: Object = _find_focus_service()
	if focus != null:
		bind_focus_service(focus)
		return
	_focus_bind_retry += 1
	if _focus_bind_retry <= MAX_BIND_RETRY:
		call_deferred("_deferred_bind_focus")
	else:
		push_warning("[R36][PCO] A66：FocusService 未就绪（重试 %d 次）→ 绑定降级：不订阅、不写盘" % MAX_BIND_RETRY)


## 相对 root 查找 WaveTrialDirector → 调 get_focus_service() 取 A54 唯一实例。
##   不静态引用 class_name、不用 /root/... 绝对路径、不自建第二个 FocusService。
func _find_focus_service() -> Object:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var wave: Node = _scan_wave(tree.root)
	if wave == null or not wave.has_method("get_focus_service"):
		return null
	return wave.call("get_focus_service") as Object


func _scan_wave(n: Node) -> Node:
	if n.name == "WaveTrialDirector" and n.has_method("get_focus_service"):
		return n
	for c: Node in n.get_children():
		var found: Node = _scan_wave(c)
		if found != null:
			return found
	return null


## 显式绑定入口（正常游戏由 _deferred_bind_focus 调；--script 验证进程直接调以保证确定性）。
##   connect 前 is_connected 去重，绝不重复连接；A54 唯一实例由参数传入、不 new。
func bind_focus_service(focus: Object) -> bool:
	if focus == null or not is_instance_valid(focus):
		return false
	_focus_service = focus
	var connected: int = 0
	for sig: String in FOCUS_SIGNALS:
		if not focus.has_signal(sig):
			continue
		var method: String = "_on_" + sig
		var cb: Callable = Callable(self, method)
		if not focus.is_connected(sig, cb):
			focus.connect(sig, cb)
		connected += 1
	_focus_max_cache = _focus_read_max(focus)
	_focus_bound = connected == FOCUS_SIGNALS.size()
	if _focus_bound:
		print("[R36][PCO] A66 生产订阅者已绑定 FocusService 唯一实例 | signals=%d slot=%s（FP 落盘与赐福点数分离）" % [
			connected, _slot_dir])
	else:
		push_warning("[R36][PCO] A66 FocusService 信号不全，绑定降级（connected=%d/%d）" % [
			connected, FOCUS_SIGNALS.size()])
	return _focus_bound


## 从 A54 唯一实例鸭子读 FP 上限（Rank-2 接口命名差异不产生 SCRIPT ERROR）。
func _focus_read_max(focus: Object) -> int:
	if focus != null and is_instance_valid(focus) and focus.has_method("get_fp_max"):
		var m: int = int(round(float(focus.call("get_fp_max"))))
		if m > 0:
			return m
	if _focus_max_cache > 0:
		return _focus_max_cache
	return 0


## FP 上限权威值：优先唯一实例，回落磁盘已落盘 max，再回落缓存。
func _focus_max_value(flags: Dictionary) -> int:
	var m: int = _focus_read_max(_focus_service)
	if m > 0:
		return m
	var dm: int = int(flags.get(K_FOCUS_MAX, 0))
	if dm > 0:
		return dm
	return _focus_max_cache


## 释放 3 个信号连接（有释放路径，不留悬空 Callable）。
func _release_focus() -> void:
	if _focus_service != null and is_instance_valid(_focus_service):
		for sig: String in FOCUS_SIGNALS:
			var cb: Callable = Callable(self, "_on_" + sig)
			if _focus_service.has_signal(sig) and _focus_service.is_connected(sig, cb):
				_focus_service.disconnect(sig, cb)
	_focus_service = null
	_focus_bound = false


## FP 专用 commit 封装：★ 显式隔离，focus_writes 绝不含 K_POINTS / K_SPENT，
##   所有 key 必须以 "combat.focus." 开头且通过三段式正则；复用既有 _commit
##   （十字段冻结 / schema_version=3 / 不写 removals / 原子写 / 先落盘再改实例）。
##   awarded_points=0 / new_total=磁盘 points 原值 → points_committed 不误导。
func _commit_focus(reason: String, focus_writes: Dictionary, delta: Dictionary) -> bool:
	if _re == null:
		_re = RegEx.new()
		_re.compile(FLAG_KEY_REGEX)
	for k: Variant in focus_writes.keys():
		var key: String = String(k)
		if not key.begins_with("combat.focus.") or key == K_POINTS or key == K_SPENT:
			push_warning("[R36][PCO] A66 非法 FP flag key（越界或混用赐福点数），本次不落盘：%s" % key)
			return false
		if _re.search(key) == null:
			push_warning("[R36][PCO] A66 非法三段式 FP flag key，本次不落盘：%s" % key)
			return false
		var val: Variant = focus_writes[k]
		if not _is_scalar(val):
			push_warning("[R36][PCO] A66 非标量 FP flag value，本次不落盘：%s" % key)
			return false
	var disk_points: int = int((delta.get("flags", {}) as Dictionary).get(K_POINTS, 0))
	return _commit(reason, focus_writes, 0, disk_points)


## A66 生产回调 ①：战技成功扣 FP → 落盘。
##   ★ 重复释放不二次扣费：磁盘已有 current 时新值必须严格 < 旧值；
##     否则（同参重放 / 冷却期误发 / 异常）拒绝、不落盘、spend_count 不增。
##   ★ FP 只减不增除休息：合法 focus_spent 恒使 current 减少、且不超过上限。
func _on_focus_spent(art_id: String, _fp_cost: float, _damage: float,
		_poise_damage: float, fp_remaining: float) -> void:
	if is_nan(fp_remaining) or is_inf(fp_remaining):
		push_warning("[R36][PCO] A66 focus_spent fp_remaining 非有限值 → 拒绝、不落盘")
		return
	var new_cur: int = int(round(fp_remaining))
	if new_cur < 0:
		push_warning("[R36][PCO] A66 focus_spent 负 FP → 拒绝、不落盘")
		return
	var delta: Dictionary = _read_delta()
	var flags: Dictionary = delta.get("flags", {}) as Dictionary
	var maxv: int = _focus_max_value(flags)
	if maxv > 0 and new_cur > maxv:
		push_warning("[R36][PCO] A66 focus_spent 越过 FP 上限 → 拒绝、不落盘 | cur=%d max=%d" % [new_cur, maxv])
		return
	if flags.has(K_FOCUS_CURRENT) and new_cur >= int(flags.get(K_FOCUS_CURRENT, 0)):
		_focus_reject_observed += 1
		push_warning("[R36][PCO] A66 重复释放/重放拒绝（FP 未减少，不二次扣费）| cur=%d disk=%d" % [
			new_cur, int(flags.get(K_FOCUS_CURRENT, 0))])
		return
	var spend: int = int(flags.get(K_FOCUS_SPEND_COUNT, 0)) + 1
	var writes: Dictionary = {
		K_FOCUS_CURRENT: new_cur,
		K_FOCUS_MAX: maxv,
		K_FOCUS_ART_ID: String(art_id),
		K_FOCUS_SPEND_COUNT: spend,
	}
	if not _commit_focus("focus_spent_" + String(art_id), writes, delta):
		push_warning("[R36][PCO] A66 focus_spent commit 失败 → 磁盘未改、运行时实例保持旧值")


## A66 生产回调 ②：赐福休息回满 → 落盘（唯一允许 FP 增加的出口）。
##   ★ FP 上限不被突破：fp_after 超过 max 时封顶到 max，绝不写 > max 的 current。
func _on_focus_restored(_fp_before: float, fp_after: float, policy: String) -> void:
	if is_nan(fp_after) or is_inf(fp_after):
		push_warning("[R36][PCO] A66 focus_restored fp_after 非有限值 → 拒绝、不落盘")
		return
	var delta: Dictionary = _read_delta()
	var flags: Dictionary = delta.get("flags", {}) as Dictionary
	var maxv: int = _focus_max_value(flags)
	var new_cur: int = int(round(fp_after))
	if maxv > 0 and new_cur > maxv:
		push_warning("[R36][PCO] A66 FP 上限保护：回满值 %d > max %d → 封顶（不突破上限）" % [new_cur, maxv])
		new_cur = maxv
	if new_cur < 0:
		new_cur = 0
	var restore: int = int(flags.get(K_FOCUS_RESTORE_COUNT, 0)) + 1
	var writes: Dictionary = {
		K_FOCUS_CURRENT: new_cur,
		K_FOCUS_MAX: maxv,
		K_FOCUS_RESTORE_COUNT: restore,
		K_FOCUS_POLICY: String(policy),
	}
	if not _commit_focus("focus_restored_" + String(policy), writes, delta):
		push_warning("[R36][PCO] A66 focus_restored commit 失败 → 磁盘未改、运行时实例保持旧值")


## A66 生产回调 ③：施放被拒 → 运行时观测 + 落盘最近拒绝原因（不扣 FP）。
##   只写 combat.focus.last_reject（String），绝不动 combat.focus.current /
##   spend_count / points / spent_points；重复释放不二次扣费。
func _on_focus_rejected(_art_id: String, reason: String) -> void:
	_focus_reject_observed += 1
	var delta: Dictionary = _read_delta()
	var writes: Dictionary = {K_FOCUS_LAST_REJECT: String(reason)}
	if not _commit_focus("focus_rejected_" + String(reason), writes, delta):
		push_warning("[R36][PCO] A66 focus_rejected commit 失败 → 磁盘未改")
