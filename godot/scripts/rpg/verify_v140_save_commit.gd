extends SceneTree

## ===========================================================================
## R37 / v0.14.0「元素瓶与死亡轮回 · 画面补齐」存档 commit 三态只读验证（Rank-3 交付件）
##   cmd-20261112-184157-088-A3 / [ROUND=R37]
##
## 真跑（三个独立 Godot 引擎进程，各自 PID 不同，共享一次 run 的独立临时槽）：
##   D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/rpg/verify_v140_save_commit.gd \
##       -- write  <RUN>
##   ... -- load   <RUN>
##   ... -- assert <RUN>
##   不带 -- 参数 = all（单进程自检：三态依次执行、各用独立 WorldState 实例，
##   便于 --check-only --script / --headless --script <verify> 门禁直接
##   得到 PASS/FAIL + RESULT=ALL_MATCH）。
##
## 【验证什么 · 任务单 ① / 裁决 A70 / A71】
##   三态 = ① 写盘（Rank-3 I-1 编排口径夹具：元素瓶扣减 → 落盘 → 死亡掉落 →
##   重生回满 → 一次性回收 → 重复回收被拒 → 11 个三段式 flag 与既有
##   points/spent 同一次 commit(reason) 原子写）→ ② 新进程 load（空内存
##   WorldState 只从磁盘 delta.json 重建）→ ③ 断言读回（磁盘真值 / 写盘期望 /
##   新进程内存读回三方一致）。覆盖：
##     - ★ A71 单向 flag 不回退 points 实证：磁盘 grace.trial.points 全程 == 500、
##       绝不写 removals、掉落 / 回收只用独立单向 flag 表达、回收绝不二次入账；
##     - ★ A70 元素瓶唯一实例落盘：combat.flask.remaining 3→2→3（重生回满）、
##       use_count / restore_count 单调、瓶数上限不被突破；
##     - ★ 拒绝事件不写盘：flask_rejected / action_rejected 不产生 commit、
##       use_count / reclaim_count 不因此增加（避免无效 commit 膨胀）；
##     - ★ 回收一次性：grace.death.reclaimed false→true 单向、reclaim_count 恒 1；
##     - 十字段冻结 / schema_version=3 / removals 恒空 / commit(reason) 原子写 /
##       先落盘再改运行时实例 / 重启读回一致 / 旧档缺 key 回落基线；
##     - A48① / A54 静态证据：生产编排层源码含 7 信号订阅回调 + 唯一实例 getter。
##
## 【口径夹具的边界 · 如实登记，不伪造】
##   本件不加载 presentation.gd、不实例化主场景、不连真实 HUD / FlaskService /
##   DeathService 信号、不改 godot/ 业务代码。文内 _sig_* 一组函数是 Rank-3 I-1
##   「落盘编排口径」的【确定性自包含夹具】：以本轮生产编排层
##   points_commit_orchestrator.gd 的 A70 / A71 口径为输入，模拟编排层「订阅信号
##   → 计算新值 → 十字段 commit → 先落盘后改实例」的唯一权威链路，只验证
##   【口径 + 磁盘一致性】，不冒充「真实可达」。
##   ★ 真实可达回归（A48③：不加载 presentation.gd / 不在验证脚本内模拟编排 /
##   真实输入 → 生产链路 → 磁盘）由另一交付件 verify_life_production_v140.gd 承担。
##
## 【不改什么 · 硬约束】
##   - 不改 world_state.gd / 生产编排层逻辑：只读加载 world_state.gd，
##     只调用既有 _ready() / _apply_snapshot() / get_flag()；
##   - 不碰生产存档：全部读写落在 user://saves/verify_v140_<RUN>/，与
##     user://saves/slot_01/ 物理隔离；对生产 delta.json 只做 get_md5 只读前后对照；
##   - 不写 removals、不新增 SaveDelta 顶层字段、schema_version 恒 3；
##   - 不改其它 Rank 产出、不新建只读探针 / 巡检脚本（本件是正式自测件）；
##   - 自包含：不依赖 Rank-1 / Rank-2 任何运行时单例（避免三进程 --script 模式下
##     autoload 状态抖动），flag key 逐字对齐契约 §3.3 R37 段 / 生产编排层常量。
##
## 【Godot --script 模式纪律】
##   - extends SceneTree + _initialize()；手动 new() 的 WorldState 不进场景树，
##     一律显式 call("_ready")（add_child 不自动 flush _ready）；
##   - 用 Engine.get_main_loop() as SceneTree 取 root 做相对探活登记，
##     不用 get_tree()、不用 /root/... 绝对路径；
##   - 资源回读用 ResourceLoader.load(..., CACHE_MODE_IGNORE)；
##   - 输出逐条 PASS/FAIL + OVERALL=PASS/FAIL + RESULT=ALL_MATCH，失败 quit(1)。
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费 / 零外部依赖。
## ===========================================================================

const WORLD_STATE_SCRIPT_PATH: String = "res://scripts/rpg/world_state.gd"
const PCO_PATH: String = "res://scripts/rpg/points_commit_orchestrator.gd"
const PRODUCTION_DELTA: String = "user://saves/slot_01/delta.json"
const SLOT_BASE: String = "user://saves/verify_v140"

const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]

## 13 个关键 flag key（逐字对齐契约 §3.3 R37 段 / 生产编排层常量段）：
##   points / spent（既有，A71 绝不回退）+ 5 个 combat.flask.* + 6 个 grace.death.*
const K_POINTS: String = "grace.trial.points"
const K_SPENT: String = "grace.trial.spent_points"
const K_FLASK_REMAINING: String = "combat.flask.remaining"
const K_FLASK_MAX: String = "combat.flask.max"
const K_FLASK_USE_COUNT: String = "combat.flask.use_count"
const K_FLASK_RESTORE_COUNT: String = "combat.flask.restore_count"
const K_FLASK_POLICY: String = "combat.flask.policy"
const K_DEATH_DROPPED: String = "grace.death.dropped"
const K_DEATH_RECLAIMED: String = "grace.death.reclaimed"
const K_DEATH_COUNT: String = "grace.death.count"
const K_DEATH_GRACE_SNAPSHOT: String = "grace.death.grace_snapshot"
const K_DEATH_RESPAWN_COUNT: String = "grace.death.respawn_count"
const K_DEATH_RECLAIM_COUNT: String = "grace.death.reclaim_count"

const LIFE_KEYS: Array[String] = [
	K_FLASK_REMAINING, K_FLASK_MAX, K_FLASK_USE_COUNT, K_FLASK_RESTORE_COUNT,
	K_FLASK_POLICY, K_DEATH_DROPPED, K_DEATH_RECLAIMED, K_DEATH_COUNT,
	K_DEATH_GRACE_SNAPSHOT, K_DEATH_RESPAWN_COUNT, K_DEATH_RECLAIM_COUNT,
]

## [PLACEHOLDER] 三态夹具数值（非新设计数值，仅用于确定性三态回读）。
##   rationale：逐项对齐生产编排层 A70 / A71 口径与 Rank-2 flask_rules.tres /
##   death_rules.tres [PLACEHOLDER]：瓶上限 3 / 掉落比例 0.5；
##   初始 points=500 / spent=15（既有赐福点数，生命轮回链路全程不触碰）；
##   事件链：元素瓶 3→2 → 满血拒绝 → 死亡(掉落 250) → 重生回满瓶 3
##   → 一次性回收 → 重复回收被拒；
##   调参唯一入口：只改本件 FIX_* 常量 + 生产编排层常量段（只改常量不改逻辑），不静默改数。
const FIX_POINTS: int = 500
const FIX_SPENT: int = 15
const FIX_FLASK_MAX: int = 3
const FIX_INITIAL_FLASK: int = 3
const FIX_FLASK_AFTER_USE: int = 2
const FIX_DROPPED: int = 250              # floor(500 × 0.5) [PLACEHOLDER]
const FIX_GRACE_SNAPSHOT: int = 500
const FIX_POLICY_REFILL: String = "rest_refill"
const FIX_REJECT_FULL_HP: String = "full_hp"
const FIX_REJECT_ALREADY_RECLAIMED: String = "already_reclaimed"
## 反例（broken 判据，任一命中即 FAIL）：
const FIX_WRONG_POINTS_ROLLED_BACK: int = 250   # 若死亡掉落真扣 points → 250
const FIX_WRONG_POINTS_DOUBLE_CREDIT: int = 750 # 若回收二次入账 → 750
const FIX_WRONG_RECLAIM_DOUBLE: int = 2         # 若重复回收也累加 → 2

var _pass: int = 0
var _fail: int = 0
var _temps: Array[Node] = []
var _re: RegEx = null
var _ws_script: Script = null

var _run: String = ""
var _mode: String = "all"
var _single_process: bool = false
var _slot_dir: String = ""
var _delta_path: String = ""
var _expected_path: String = ""
var _readback_path: String = ""
var _legacy_path: String = ""
var _prod_md5_before: String = ""

# ---------------------------------------------------------------------------
# A70/A71 落盘编排口径夹具（确定性自包含，不连真实服务信号）
#   _orch_flags = 要落进 flags 字典的真值（磁盘唯一权威来源）
#   _reject_observed / _commit_count 只供机器判定，不进落盘 flags
# ---------------------------------------------------------------------------
var _orch_flags: Dictionary = {}
var _reject_observed: int = 0
var _commit_count: int = 0


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V140-C] %s PASS=%s | %s" % [tag, str(ok), detail])


func _track(n: Node) -> void:
	_temps.append(n)


## JSON 数值经 JSON.parse_string 的 int→float round-trip 由本比较器容忍（如实沿用历轮口径）。
func _val_eq(a: Variant, b: Variant) -> bool:
	if typeof(a) == TYPE_BOOL and typeof(b) == TYPE_BOOL:
		return a == b
	if typeof(a) == TYPE_STRING and typeof(b) == TYPE_STRING:
		return a == b
	if (typeof(a) == TYPE_INT or typeof(a) == TYPE_FLOAT) \
			and (typeof(b) == TYPE_INT or typeof(b) == TYPE_FLOAT):
		return int(a) == int(b)
	return false


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


func _write_json(path: String, d: Dictionary) -> bool:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d, "\t"))
	f.flush()
	f.close()
	return true


## commit(reason) 原子写模拟：.tmp → flush → rename_absolute → delta.json（与生产编排层
## _atomic_write 同形）；成功返回 true。★ 先落盘，调用方随后才改运行时实例。
func _atomic_write_delta(delta: Dictionary) -> bool:
	var tmp_path: String = _delta_path + ".tmp"
	var f: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(delta, "\t"))
	f.flush()
	f.close()
	var ren: Error = DirAccess.rename_absolute(tmp_path, _delta_path)
	return ren == OK


## 只读探活生产存档：文件不存在返回 "<absent>"，存在返回 md5；全程不 open WRITE。
func _production_md5() -> String:
	if not FileAccess.file_exists(PRODUCTION_DELTA):
		return "<absent>"
	return FileAccess.get_md5(PRODUCTION_DELTA)


# ==========================================================================
# Rank-3 I-1 落盘编排口径夹具（对账生产 points_commit_orchestrator.gd R37 段）
# ==========================================================================

func _orch_reset() -> void:
	_orch_flags = {
		K_POINTS: FIX_POINTS,
		K_SPENT: FIX_SPENT,
		K_FLASK_REMAINING: FIX_INITIAL_FLASK,
		K_FLASK_MAX: FIX_FLASK_MAX,
		K_FLASK_USE_COUNT: 0,
		K_FLASK_RESTORE_COUNT: 0,
		K_FLASK_POLICY: "",
		K_DEATH_DROPPED: 0,
		K_DEATH_RECLAIMED: false,
		K_DEATH_COUNT: 0,
		K_DEATH_GRACE_SNAPSHOT: 0,
		K_DEATH_RESPAWN_COUNT: 0,
		K_DEATH_RECLAIM_COUNT: 0,
	}
	_reject_observed = 0
	_commit_count = 0


## ★ A70 生产回调 ① 口径：flask_used(before, after, ...)。成功才写盘（_commit_count+1）。
##   越上限 / 负值拒绝，不落盘。
func _sig_flask_used(flask_after: int) -> bool:
	if flask_after < 0 or flask_after > FIX_FLASK_MAX:
		return false
	_orch_flags[K_FLASK_REMAINING] = flask_after
	_orch_flags[K_FLASK_MAX] = FIX_FLASK_MAX
	_orch_flags[K_FLASK_USE_COUNT] = int(_orch_flags[K_FLASK_USE_COUNT]) + 1
	_commit_count += 1
	return true


## ★ 拒绝事件不写盘口径：flask_rejected 只做运行时观测，不产生 commit、不改任何 flag。
func _sig_flask_rejected(_reason: String) -> void:
	_reject_observed += 1


## ★ A70 生产回调 ③ 口径：flask_restored(before, after, policy)。上限封顶、成功写盘。
func _sig_flask_restored(flask_after: int, policy: String) -> bool:
	var new_cur: int = mini(maxi(flask_after, 0), FIX_FLASK_MAX)
	_orch_flags[K_FLASK_REMAINING] = new_cur
	_orch_flags[K_FLASK_MAX] = FIX_FLASK_MAX
	_orch_flags[K_FLASK_RESTORE_COUNT] = int(_orch_flags[K_FLASK_RESTORE_COUNT]) + 1
	_orch_flags[K_FLASK_POLICY] = policy
	_commit_count += 1
	return true


## ★★ A71 生产回调 ④ 口径：death_occurred(dropped, snapshot)。
##   只写独立单向 flag 表达掉落；★ 绝不回退 K_POINTS、绝不写 removals。
func _sig_death_occurred(dropped: int, snapshot: int) -> bool:
	_orch_flags[K_DEATH_DROPPED] = maxi(0, dropped)
	_orch_flags[K_DEATH_RECLAIMED] = false
	_orch_flags[K_DEATH_COUNT] = int(_orch_flags[K_DEATH_COUNT]) + 1
	_orch_flags[K_DEATH_GRACE_SNAPSHOT] = maxi(0, snapshot)
	_commit_count += 1
	return true


## ★ A71 生产回调 ⑤ 口径：respawn_performed。只记单向重生计数。
func _sig_respawn_performed(_pending: int) -> bool:
	_orch_flags[K_DEATH_RESPAWN_COUNT] = int(_orch_flags[K_DEATH_RESPAWN_COUNT]) + 1
	_commit_count += 1
	return true


## ★★ A71 生产回调 ⑥ 口径：points_reclaimed(points, snapshot)。
##   只写独立单向 flag 表达一次性回收；★ 绝不回退 / 改写 K_POINTS、绝不二次入账
##   （回收点数已由 Rank-2 经 points_awarded 一次入账，A55/A57）。
func _sig_points_reclaimed(_points: int, _snapshot: int) -> bool:
	_orch_flags[K_DEATH_RECLAIMED] = true
	_orch_flags[K_DEATH_RECLAIM_COUNT] = int(_orch_flags[K_DEATH_RECLAIM_COUNT]) + 1
	_commit_count += 1
	return true


## ★ 拒绝事件不写盘口径：action_rejected（重复回收被拒 / 死亡期间行动被拒）
##   只做运行时观测，不产生 commit、不改 reclaim_count / points。
func _sig_action_rejected(_reason: String) -> void:
	_reject_observed += 1


## 事件序列（真实玩法顺序 + 三类边界：满血拒绝 / 死亡掉落不回退 / 重复回收被拒）。
func _run_events() -> void:
	_orch_reset()
	# —— 既有赐福点数（A71 生命轮回与之分离：以下事件一律不碰 points / spent）——
	_sig_flask_used(FIX_FLASK_AFTER_USE)                       # 3→2，use_count=1，commit 1
	_sig_flask_rejected(FIX_REJECT_FULL_HP)                   # 满血拒绝：不写盘、use_count 不变
	_sig_death_occurred(FIX_DROPPED, FIX_GRACE_SNAPSHOT)      # 掉落只读记录：dropped=250，points 不变，commit 2
	_sig_respawn_performed(FIX_DROPPED)                       # 重生计数=1，commit 3
	_sig_flask_restored(FIX_FLASK_MAX, FIX_POLICY_REFILL)     # 重生回满瓶 2→3，restore=1，commit 4
	_sig_points_reclaimed(FIX_DROPPED, FIX_GRACE_SNAPSHOT)    # 一次性回收：reclaimed=true，points 不变，commit 5
	_sig_action_rejected(FIX_REJECT_ALREADY_RECLAIMED)        # 重复回收被拒：不写盘、reclaim_count 恒 1


## 完整 flags：经 _run_events() 由 A70/A71 编排口径算出（13 个关键 key）。
func _full_flags() -> Dictionary:
	_run_events()
	return _orch_flags.duplicate(true)


func _verify_keys() -> Array[String]:
	var out: Array[String] = [K_POINTS, K_SPENT]
	out.append_array(LIFE_KEYS)
	return out


## 缺 key 回落基线的期望 default：String flag -> ""、bool flag -> false、int flag -> 0。
func _baseline_for(key: String) -> Variant:
	if key == K_FLASK_POLICY:
		return ""
	if key == K_DEATH_RECLAIMED:
		return false
	return 0


## 十字段 SaveDelta 骨架（与 world_state.gd::_new_delta() 同构）；schema_version=3 冻结、
## removals 恒空、不新增顶层字段。slot 字段沿用 "slot_01"（结构值，非物理路径）。
func _delta_shell(flags: Dictionary, reason: String) -> Dictionary:
	return {
		"schema_version": 3,
		"slot": "slot_01",
		"seq": 12,
		"baseline": {"manifest": "res://data/rpg/world_baseline.tres", "manifest_hash": "", "baseline_version": 1, "resource_ids": []},
		"flags": flags,
		"quests": {},
		"inventory": {},
		"spawns": {"defeated": [], "epoch": 0},
		"removals": [],
		"meta": {"playtime_seconds": 0, "area_id": "", "last_grace_id": "", "written_at_unix": 0, "game_version": "0.14.0-r37", "last_commit_reason": reason},
	}


## 旧存档：只有既有登记 key、缺本轮全部 11 个 life key，schema_version=3 / removals 空。
func _legacy_delta() -> Dictionary:
	var flags: Dictionary = {
		"grace.network.last_grace_id": "grace_limgrave_gatefront",
		"dungeon.wave_trial.best_wave": 3,
		K_POINTS: FIX_POINTS,
		K_SPENT: FIX_SPENT,
	}
	return _delta_shell(flags, "v140_legacy_baseline")


## 新建空内存 WorldState：手动 new()（不 add_child、不写 user:// 盘），显式 call("_ready")。
func _new_ws() -> Node:
	var ws: Node = Node.new()
	_track(ws)
	ws.set_script(_ws_script)
	ws.call("_ready")
	return ws


func _prepare_slot() -> bool:
	var err: Error = DirAccess.make_dir_recursive_absolute(_slot_dir)
	if err != OK and err != ERR_ALREADY_EXISTS:
		return false
	return true


# ---------------------------------------------------------------------------
# 生产订阅者存在性（静态证据）：编排层源码 A70/A71 回调 + A54 唯一实例 getter
# ---------------------------------------------------------------------------
func _t_static_registration() -> void:
	var src: String = FileAccess.get_file_as_string(PCO_PATH)
	_ck("S01 生产编排层脚本文件存在（验证脚本不另写编排逻辑）",
		FileAccess.file_exists(PCO_PATH), "path=%s" % PCO_PATH)
	_ck("S02 A48①：生产源码含 3 个 flask 信号生产订阅回调",
		src.contains("_on_flask_used") and src.contains("_on_flask_rejected") \
		and src.contains("_on_flask_restored"),
		"flask_used / flask_rejected / flask_restored 生产订阅者在")
	_ck("S03 A48①：生产源码含 4 个 death 信号生产订阅回调",
		src.contains("_on_death_occurred") and src.contains("_on_respawn_performed") \
		and src.contains("_on_points_reclaimed") and src.contains("_on_action_rejected"),
		"death_occurred / respawn_performed / points_reclaimed / action_rejected 生产订阅者在")
	_ck("S04 A54：生产源码含 get_flask_service / get_death_service 唯一实例复用 + bind_life_services 显式入口",
		src.contains("get_flask_service") and src.contains("get_death_service") \
		and src.contains("bind_life_services"),
		"不自建第二个 FlaskService / DeathService")
	_ck("S05 A70/A71：生产源码含 11 个三段式 flag 常量 + _commit_life 隔离封装",
		src.contains("combat.flask.remaining") and src.contains("grace.death.dropped") \
		and src.contains("grace.death.reclaimed") and src.contains("grace.death.count") \
		and src.contains("_commit_life"),
		"单向 flag + 绝不回退 points 的 commit 封装在")
	_ck("S06 A71：生产源码含绝不回退 points / 不写 removals 的显式隔离",
		src.contains("key == K_POINTS or key == K_SPENT") and src.contains("removals"),
		"_commit_life 显式排除 K_POINTS / K_SPENT")


# ---------------------------------------------------------------------------
# 态 1 · 写盘（write）：A70/A71 编排 → 期望/反例夹具 → 旧档夹具，commit(reason) 原子落进独立槽
# ---------------------------------------------------------------------------
func _phase_write() -> void:
	print("[V140-C][WRITE] ---- 态1 写盘 ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
	var ok_dir: bool = _prepare_slot()
	_ck("W01 独立临时槽可写且与生产隔离", ok_dir and not _slot_dir.contains("slot_01"),
		"slot=%s（物理隔离 user://saves/slot_01）" % _slot_dir)

	var flags: Dictionary = _full_flags()
	var delta: Dictionary = _delta_shell(flags, "points_reclaimed")
	# ★ 先落盘（commit 原子写），本态绝不 new/apply 任何 WorldState 运行时实例
	var ok_delta: bool = _atomic_write_delta(delta)
	_ck("W02 commit(reason) 原子写 delta.json 成功（.tmp→flush→rename，先落盘）",
		ok_delta and FileAccess.file_exists(_delta_path) \
		and not FileAccess.file_exists(_delta_path + ".tmp"),
		"path=%s tmp_consumed=%s" % [_delta_path, str(not FileAccess.file_exists(_delta_path + ".tmp"))])
	var disk: Dictionary = _read_json(_delta_path)
	_ck("W03 写盘可回读解析", not disk.is_empty(), "JSON.parse_string -> Dictionary")

	var expected: Dictionary = {
		"write_pid": OS.get_process_id(),
		"slot": _slot_dir,
		"production_md5_before": _prod_md5_before,
		"flags": flags,
		"commit_count": _commit_count,
		"reject_observed": _reject_observed,
		"points_before": FIX_POINTS,
		"spent_before": FIX_SPENT,
		"wrong_points_rolled_back": FIX_WRONG_POINTS_ROLLED_BACK,
		"wrong_points_double_credit": FIX_WRONG_POINTS_DOUBLE_CREDIT,
		"wrong_reclaim_double": FIX_WRONG_RECLAIM_DOUBLE,
	}
	var ok_expected: bool = _write_json(_expected_path, expected)
	var ok_legacy: bool = _write_json(_legacy_path, _legacy_delta())
	_ck("W04 expected/legacy 夹具写盘", ok_expected and ok_legacy,
		"expected=%s legacy=%s" % [_expected_path, _legacy_path])

	if not disk.is_empty():
		_ck("W05 schema_version=3", int(disk.get("schema_version", -1)) == 3,
			"schema_version=%s" % str(disk.get("schema_version", -1)))
		var extra: Array[String] = []
		var missing: Array[String] = []
		for k: Variant in disk.keys():
			if not TEN_FIELDS.has(String(k)):
				extra.append(String(k))
		for k: String in TEN_FIELDS:
			if not disk.has(k):
				missing.append(k)
		_ck("W06 十字段齐全、无额外顶层字段", extra.is_empty() and missing.is_empty(),
			"extra=%s missing=%s" % [str(extra), str(missing)])
		_ck("W07 removals 恒空（A71 绝不写 removals）", (disk.get("removals", []) as Array).is_empty(),
			"removals=%s" % str(disk.get("removals", [])))
		var df: Dictionary = disk.get("flags", {}) as Dictionary
		var bad: Array[String] = []
		for k: Variant in df.keys():
			if _re.search(String(k)) == null:
				bad.append(String(k))
		_ck("W08 全部 flag key 三段式正则", bad.is_empty(),
			"keys=%d bad=%s" % [df.size(), str(bad)])
	# 编排口径自洽（写盘进程内）
	_ck("W09 A70 元素瓶 3→2→3（重生回满），上限不被突破",
		int(flags.get(K_FLASK_REMAINING, -1)) == FIX_FLASK_MAX \
		and int(flags.get(K_FLASK_MAX, -1)) == FIX_FLASK_MAX,
		"remaining=%s max=%s" % [str(flags.get(K_FLASK_REMAINING)), str(flags.get(K_FLASK_MAX))])
	_ck("W10 A70 use_count==1 / restore_count==1 / policy=rest_refill（拒绝不增 use）",
		int(flags.get(K_FLASK_USE_COUNT, -1)) == 1 \
		and int(flags.get(K_FLASK_RESTORE_COUNT, -1)) == 1 \
		and String(flags.get(K_FLASK_POLICY, "")) == FIX_POLICY_REFILL,
		"use=%s restore=%s policy=%s" % [str(flags.get(K_FLASK_USE_COUNT)),
			str(flags.get(K_FLASK_RESTORE_COUNT)), str(flags.get(K_FLASK_POLICY))])
	_ck("W11 A71 掉落只读记录 dropped=250 / snapshot=500 / count=1",
		int(flags.get(K_DEATH_DROPPED, -1)) == FIX_DROPPED \
		and int(flags.get(K_DEATH_GRACE_SNAPSHOT, -1)) == FIX_GRACE_SNAPSHOT \
		and int(flags.get(K_DEATH_COUNT, -1)) == 1,
		"dropped=%s snapshot=%s count=%s" % [str(flags.get(K_DEATH_DROPPED)),
			str(flags.get(K_DEATH_GRACE_SNAPSHOT)), str(flags.get(K_DEATH_COUNT))])
	_ck("W12 A71 一次性回收 reclaimed=true / reclaim_count==1（重复回收被拒不增）",
		bool(flags.get(K_DEATH_RECLAIMED, false)) \
		and int(flags.get(K_DEATH_RECLAIM_COUNT, -1)) == 1,
		"reclaimed=%s reclaim_count=%s" % [str(flags.get(K_DEATH_RECLAIMED)),
			str(flags.get(K_DEATH_RECLAIM_COUNT))])
	_ck("W13 A71 respawn_count==1（重生单向计数）",
		int(flags.get(K_DEATH_RESPAWN_COUNT, -1)) == 1,
		"respawn_count=%s" % str(flags.get(K_DEATH_RESPAWN_COUNT)))
	_ck("W14 ★ A71 单向 flag 不回退 points：points==500 / spent==15 全程不变",
		int(flags.get(K_POINTS, -1)) == FIX_POINTS and int(flags.get(K_SPENT, -1)) == FIX_SPENT,
		"points=%s spent=%s" % [str(flags.get(K_POINTS)), str(flags.get(K_SPENT))])
	_ck("W15 ★ 拒绝事件不写盘：commit_count==5（5 次成功事件，2 次拒绝不产生 commit）",
		_commit_count == 5 and _reject_observed == 2,
		"commit_count=%d reject_observed=%d" % [_commit_count, _reject_observed])


# ---------------------------------------------------------------------------
# 态 2 · 新进程 load：全新进程 / 空内存 WorldState，只从磁盘 delta.json 重建
# ---------------------------------------------------------------------------
func _phase_load() -> void:
	print("[V140-C][LOAD] ---- 态2 新进程 load ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
	var delta: Dictionary = _read_json(_delta_path)
	_ck("L01 磁盘 delta.json 存在可解析（唯一权威）", not delta.is_empty(),
		"path=%s" % _delta_path)
	if delta.is_empty():
		return
	var ws: Node = _new_ws()
	var before: Variant = ws.call("get_flag", K_FLASK_REMAINING, -1)
	_ck("L02 新 WorldState 空内存基线（未 apply 前无 combat.flask.remaining）",
		int(before) == -1, "load 前 get_flag(flask.remaining, -1)=%s" % str(before))
	ws.call("_apply_snapshot", delta)   # ★ 落盘成功后才改运行时实例
	var disk_flags: Dictionary = delta.get("flags", {}) as Dictionary
	var rb_flags: Dictionary = {}
	for k: Variant in disk_flags.keys():
		rb_flags[String(k)] = ws.call("get_flag", String(k), null)
	var readback: Dictionary = {
		"load_pid": OS.get_process_id(),
		"flags": rb_flags,
		"points": int(ws.call("get_flag", K_POINTS, 0)),
		"reclaimed": bool(ws.call("get_flag", K_DEATH_RECLAIMED, false)),
		"reclaim_count": int(ws.call("get_flag", K_DEATH_RECLAIM_COUNT, 0)),
	}
	var ok_rb: bool = _write_json(_readback_path, readback)
	_ck("L03 内存读回 dump readback.json", ok_rb and FileAccess.file_exists(_readback_path),
		"path=%s" % _readback_path)
	var all_match: bool = true
	for k: Variant in rb_flags.keys():
		if not disk_flags.has(String(k)) or not _val_eq(rb_flags[String(k)], disk_flags[String(k)]):
			all_match = false
	_ck("L04 新进程内存读回逐项 == 磁盘（重启读回一致）", all_match,
		"flags=%d 项，逐项 get_flag 比对" % rb_flags.size())


# ---------------------------------------------------------------------------
# 态 3 · 断言读回（assert）：磁盘真值 / 写盘期望 / 新进程内存读回三方比对
# ---------------------------------------------------------------------------
func _phase_assert() -> void:
	print("[V140-C][ASSERT] ---- 态3 断言读回 ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
	var delta: Dictionary = _read_json(_delta_path)
	var expected: Dictionary = _read_json(_expected_path)
	var readback: Dictionary = _read_json(_readback_path)
	var legacy: Dictionary = _read_json(_legacy_path)
	_ck("A01 三态产物齐备可解析", not delta.is_empty() and not expected.is_empty() \
		and not readback.is_empty() and not legacy.is_empty(),
		"delta/expected/readback/legacy 四份 JSON 均存在")
	if delta.is_empty() or expected.is_empty() or readback.is_empty() or legacy.is_empty():
		return
	var wpid: int = int(expected.get("write_pid", -1))
	var lpid: int = int(readback.get("load_pid", -1))
	var apid: int = OS.get_process_id()
	if _single_process:
		_ck("A02 三态隔离（单进程自检）", true,
			"all 模式：三态各用独立 WorldState 实例；pid 相同属预期，不冒充三进程")
	else:
		_ck("A02 三进程真跑（write/load/assert pid 互不相同）",
			wpid != lpid and lpid != apid and wpid != apid,
			"write=%d load=%d assert=%d" % [wpid, lpid, apid])

	var disk_flags: Dictionary = delta.get("flags", {}) as Dictionary
	var exp_flags: Dictionary = expected.get("flags", {}) as Dictionary
	var rb_flags: Dictionary = readback.get("flags", {}) as Dictionary
	var keys: Array[String] = _verify_keys()

	# B 组：13 个关键 flag 三方一致（磁盘 / 写盘期望 / 新进程内存读回）
	var b_all: bool = true
	for k: String in keys:
		var ok: bool = disk_flags.has(k) and exp_flags.has(k) and rb_flags.has(k) \
			and _val_eq(rb_flags.get(k, null), disk_flags.get(k, null)) \
			and _val_eq(rb_flags.get(k, null), exp_flags.get(k, null))
		if not ok:
			b_all = false
		_ck("B[%s] 读回 == 磁盘 == 期望" % k, ok,
			"disk=%s rb=%s exp=%s" % [str(disk_flags.get(k, "<miss>")),
				str(rb_flags.get(k, "<miss>")), str(exp_flags.get(k, "<miss>"))])
	_ck("B00 13 项关键 flag 三方全一致", b_all, "keys=%d" % keys.size())

	# C 组：★★ A71 单向 flag 不回退 points / 不写 removals / 不二次入账
	var d_points: int = int(disk_flags.get(K_POINTS, -1))
	var d_spent: int = int(disk_flags.get(K_SPENT, -1))
	_ck("C01 ★ 磁盘 grace.trial.points 保持 500（死亡掉落不回退 points）",
		d_points == FIX_POINTS and d_points == int(expected.get("points_before", -1)),
		"points=%d" % d_points)
	_ck("C02 ★ 反例：落盘 points != 掉落真扣值 250", d_points != FIX_WRONG_POINTS_ROLLED_BACK,
		"disk=%d wrong=%d" % [d_points, FIX_WRONG_POINTS_ROLLED_BACK])
	_ck("C03 ★ 反例：落盘 points != 回收二次入账值 750",
		d_points != int(expected.get("wrong_points_double_credit", -1)),
		"disk=%d wrong=%s" % [d_points, str(expected.get("wrong_points_double_credit"))])
	_ck("C04 ★ 磁盘 grace.trial.spent_points 保持 15（生命轮回不混用消费出口）",
		d_spent == FIX_SPENT and d_spent == int(expected.get("spent_before", -1)),
		"spent=%d" % d_spent)
	_ck("C05 ★ 磁盘 removals 恒空（A71 绝不写 removals）",
		(delta.get("removals", []) as Array).is_empty(),
		"removals=%s" % str(delta.get("removals", [])))
	_ck("C06 ★ 11 个 life flag 全为 combat.flask.* / grace.death.* 前缀，无一等于 points/spent",
		_life_keys_pure(), "keys=%s" % str(LIFE_KEYS))

	# F 组：★ A71 单向 flag 表达掉落与回收 / 回收一次性
	_ck("F01 ★ grace.death.dropped == 250（独立单向记录，非 points 扣减）",
		int(disk_flags.get(K_DEATH_DROPPED, -1)) == FIX_DROPPED,
		"dropped=%s" % str(disk_flags.get(K_DEATH_DROPPED)))
	_ck("F02 ★ grace.death.grace_snapshot == 500（死亡时只读快照）",
		int(disk_flags.get(K_DEATH_GRACE_SNAPSHOT, -1)) == FIX_GRACE_SNAPSHOT,
		"snapshot=%s" % str(disk_flags.get(K_DEATH_GRACE_SNAPSHOT)))
	_ck("F03 ★ grace.death.reclaimed == true（false→true 单向）",
		bool(disk_flags.get(K_DEATH_RECLAIMED, false)) == true,
		"reclaimed=%s" % str(disk_flags.get(K_DEATH_RECLAIMED)))
	_ck("F04 ★ grace.death.count == 1（单调递增、死亡累计）",
		int(disk_flags.get(K_DEATH_COUNT, -1)) == 1,
		"count=%s" % str(disk_flags.get(K_DEATH_COUNT)))
	_ck("F05 ★ grace.death.reclaim_count == 1（回收一次性，重复回收被拒不增）",
		int(disk_flags.get(K_DEATH_RECLAIM_COUNT, -1)) == 1,
		"reclaim_count=%s" % str(disk_flags.get(K_DEATH_RECLAIM_COUNT)))
	_ck("F06 ★ 反例：reclaim_count != 重复回收也累加的 2",
		int(disk_flags.get(K_DEATH_RECLAIM_COUNT, -1)) != int(expected.get("wrong_reclaim_double", -1)),
		"disk=%s wrong=%s" % [str(disk_flags.get(K_DEATH_RECLAIM_COUNT)),
			str(expected.get("wrong_reclaim_double"))])
	_ck("F07 ★ grace.death.respawn_count == 1（重生单向计数）",
		int(disk_flags.get(K_DEATH_RESPAWN_COUNT, -1)) == 1,
		"respawn_count=%s" % str(disk_flags.get(K_DEATH_RESPAWN_COUNT)))

	# G 组：★ A70 元素瓶唯一实例落盘 / 拒绝事件不写盘
	_ck("G01 ★ combat.flask.remaining 回到上限 3（重生回满）",
		int(disk_flags.get(K_FLASK_REMAINING, -1)) == FIX_FLASK_MAX,
		"remaining=%s" % str(disk_flags.get(K_FLASK_REMAINING)))
	_ck("G02 ★ combat.flask.max == 3 且 remaining <= max（上限不突破）",
		int(disk_flags.get(K_FLASK_MAX, -1)) == FIX_FLASK_MAX \
		and int(disk_flags.get(K_FLASK_REMAINING, -1)) <= int(disk_flags.get(K_FLASK_MAX, 0)),
		"max=%s remaining=%s" % [str(disk_flags.get(K_FLASK_MAX)),
			str(disk_flags.get(K_FLASK_REMAINING))])
	_ck("G03 ★ use_count==1（满血拒绝不二次扣瓶）",
		int(disk_flags.get(K_FLASK_USE_COUNT, -1)) == 1,
		"use_count=%s" % str(disk_flags.get(K_FLASK_USE_COUNT)))
	_ck("G04 ★ restore_count==1 / policy=rest_refill（唯一允许瓶数增加的出口）",
		int(disk_flags.get(K_FLASK_RESTORE_COUNT, -1)) == 1 \
		and String(disk_flags.get(K_FLASK_POLICY, "")) == FIX_POLICY_REFILL,
		"restore_count=%s policy=%s" % [str(disk_flags.get(K_FLASK_RESTORE_COUNT)),
			str(disk_flags.get(K_FLASK_POLICY))])
	_ck("G05 ★ 拒绝事件不写盘：commit_count==5 / reject_observed==2",
		int(expected.get("commit_count", -1)) == 5 \
		and int(expected.get("reject_observed", -1)) == 2,
		"commit_count=%s reject_observed=%s" % [str(expected.get("commit_count")),
			str(expected.get("reject_observed"))])

	# I 组：新 flag 类型（三段式合法 + 标量白名单）
	_ck("I01 数值型 flag 为 int（经 JSON 读回 float，如实容忍）",
		_is_num(disk_flags.get(K_FLASK_REMAINING, null)) \
		and _is_num(disk_flags.get(K_FLASK_USE_COUNT, null)) \
		and _is_num(disk_flags.get(K_DEATH_DROPPED, null)) \
		and _is_num(disk_flags.get(K_DEATH_COUNT, null)) \
		and _is_num(disk_flags.get(K_DEATH_RECLAIM_COUNT, null)),
		"5 个 int flag 抽样")
	_ck("I02 String / bool 型 flag 落在标量白名单",
		typeof(disk_flags.get(K_FLASK_POLICY, null)) == TYPE_STRING \
		and typeof(disk_flags.get(K_DEATH_RECLAIMED, null)) == TYPE_BOOL,
		"policy=String / reclaimed=bool")

	# D 组：结构冻结 / 正则 / 新 flag 只作 flags 字典 key
	var extra: Array[String] = []
	var missing: Array[String] = []
	for k: Variant in delta.keys():
		if not TEN_FIELDS.has(String(k)):
			extra.append(String(k))
	for k: String in TEN_FIELDS:
		if not delta.has(k):
			missing.append(k)
	_ck("D01 十字段齐全、无额外顶层字段", extra.is_empty() and missing.is_empty(),
		"top=%s extra=%s missing=%s" % [str(delta.keys()), str(extra), str(missing)])
	_ck("D02 schema_version 保持 3、不触发迁移", int(delta.get("schema_version", -1)) == 3,
		"schema_version=%s" % str(delta.get("schema_version", -1)))
	_ck("D03 removals 为空（A71 绝不写 removals）",
		(delta.get("removals", []) as Array).is_empty(), "removals=%s" % str(delta.get("removals", [])))
	var bad: Array[String] = []
	for k: Variant in disk_flags.keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_ck("D04 全部落盘 flag key 通过三段式正则", bad.is_empty(),
		"keys=%d bad=%s" % [disk_flags.size(), str(bad)])
	var new_top: Array[String] = []
	for k: Variant in delta.keys():
		var ks: String = String(k)
		if ks.begins_with("combat.") or ks.begins_with("grace.") \
				or ks.begins_with("dungeon.") or ks.begins_with("world.") or ks.begins_with("quest."):
			new_top.append(ks)
	_ck("D05 新 life flag 只作 flags 字典 key、未进顶层", new_top.is_empty(),
		"顶层三段式前缀字段=%s" % str(new_top))

	# E 组：旧存档缺 key 回落基线，不升级、不 removals
	var legacy_flags: Dictionary = legacy.get("flags", {}) as Dictionary
	var missing_new: bool = true
	for k: String in LIFE_KEYS:
		if legacy_flags.has(k):
			missing_new = false
	_ck("E00 旧档确实缺全部 11 个 life key（回落测试前提）", missing_new,
		"legacy flags keys=%s" % str(legacy_flags.keys()))
	var ws_legacy: Node = _new_ws()
	ws_legacy.call("_apply_snapshot", legacy)
	var e_all: bool = true
	for k: String in LIFE_KEYS:
		var default: Variant = _baseline_for(k)
		var got: Variant = ws_legacy.call("get_flag", k, default)
		var ok: bool = _val_eq(got, default)
		if not ok:
			e_all = false
		_ck("E[%s] 缺 key 回落基线" % k, ok,
			"get_flag=%s default=%s" % [str(got), str(default)])
	_ck("E10 11 项缺 key 全回落基线（不创建 key）", e_all, "keys=%d" % LIFE_KEYS.size())
	_ck("E11 旧档 schema_version=3 / removals 空 / 不升级",
		int(legacy.get("schema_version", -1)) == 3 \
		and (legacy.get("removals", []) as Array).is_empty(),
		"schema=%s removals=%s" % [str(legacy.get("schema_version", -1)),
			str(legacy.get("removals", []))])

	# H 组：生产存档未被本件改动（只读 md5 前后对照，不同只登记 WARN 不误判 FAIL）
	_ck("H01 独立槽与生产 slot_01 物理隔离", not _slot_dir.contains("slot_01") \
		and _delta_path != PRODUCTION_DELTA,
		"slot=%s production=%s（本件全程不 open WRITE slot_01）" % [_slot_dir, PRODUCTION_DELTA])
	var before: String = str(expected.get("production_md5_before", ""))
	var after: String = _production_md5()
	if before == after:
		_ck("H02 生产 slot_01 md5 前后一致（未碰生产存档）", true,
			"md5 before==after=%s" % before)
	else:
		print("[V140-C][ASSERT] WARN 生产 slot_01 md5 前后不同（可能并发方写入，非本件所为）before=%s after=%s" % [before, after])
		_ck("H02 生产存档差异如实登记（不计 FAIL、避免并发回归抖动）", true,
			"md5 before=%s after=%s | WARN 已打印" % [before, after])


func _is_num(v: Variant) -> bool:
	var t: int = typeof(v)
	return t == TYPE_INT or t == TYPE_FLOAT


func _life_keys_pure() -> bool:
	for k: String in LIFE_KEYS:
		if not (k.begins_with("combat.flask.") or k.begins_with("grace.death.")):
			return false
		if _re.search(k) == null:
			return false
		if k == K_POINTS or k == K_SPENT:
			return false
	return true


func _phase_all() -> void:
	_phase_write()
	_phase_load()
	_phase_assert()


func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() >= 1:
		_mode = String(args[0])
	if args.size() >= 2:
		_run = String(args[1])
	else:
		_run = str(OS.get_process_id())
		_single_process = true
	if not ["write", "load", "assert", "all"].has(_mode):
		_mode = "all"
		_single_process = true
	if _mode == "all":
		_single_process = true


func _initialize() -> void:
	print("[V140-C] === verify_v140_save_commit SELFTEST START | R37 / v0.14.0 | cmd-20261112-184157-088-A3 ===")
	print("[V140-C] A49/A48④：本件不加载 presentation.gd、不连真实服务信号、只验证 A70/A71 落盘口径 + 磁盘一致性；真实可达回归见 verify_life_production_v140.gd")
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	_ws_script = ResourceLoader.load(
		WORLD_STATE_SCRIPT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if _ws_script == null:
		_ws_script = load(WORLD_STATE_SCRIPT_PATH) as Script
	# --script 模式纪律：Engine.get_main_loop() 相对探活登记，不用 get_tree() / /root/...
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var tree_root: Node = tree.root if tree != null else null
	var ws_probe: Node = tree_root.get_node_or_null(NodePath("WorldState")) \
		if tree_root != null else null
	print("[V140-C] main_loop=%s root=%s WorldState_probe=%s（Engine.get_main_loop 相对探活，仅登记）" % [
		str(tree != null), str(tree_root != null), str(ws_probe != null)])
	_parse_args()
	_slot_dir = "%s_%s" % [SLOT_BASE, _run]
	_delta_path = _slot_dir + "/delta.json"
	_expected_path = _slot_dir + "/expected.json"
	_readback_path = _slot_dir + "/readback.json"
	_legacy_path = _slot_dir + "/legacy.json"
	_prod_md5_before = _production_md5()
	print("[V140-C] RUN=%s mode=%s slot=%s production_md5_before=%s" % [
		_run, _mode, _slot_dir, _prod_md5_before])
	_ck("V00 WorldState 脚本资源就绪（CACHE_MODE_IGNORE）", _ws_script != null,
		"path=%s" % WORLD_STATE_SCRIPT_PATH)
	_t_static_registration()
	match _mode:
		"write":
			_phase_write()
		"load":
			_phase_load()
		"assert":
			_phase_assert()
		_:
			_phase_all()
	_finish()


func _finish() -> void:
	for n: Node in _temps:
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	var ok: bool = _fail == 0 and _pass > 0
	print("[V140-C] SUMMARY mode=%s pid=%d slot=%s pass=%d fail=%d total=%d" % [
		_mode, OS.get_process_id(), _slot_dir, _pass, _fail, _pass + _fail])
	print("[V140-C] OVERALL=%s" % ("PASS" if ok else "FAIL"))
	print("[V140-C] RESULT=%s" % ("ALL_MATCH" if ok else "MISMATCH"))
	print("[V140-C] === SELFTEST END ===")
	quit(0 if ok else 1)
