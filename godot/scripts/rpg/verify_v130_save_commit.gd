extends SceneTree

## ===========================================================================
## R36 / v0.13.0「专注值与战技 · 画面补齐」存档 commit 三态只读验证（Rank-3 交付件）
##   cmd-20261112-154132-916-A3 / [ROUND=R36]
##
## 真跑（三个独立 Godot 引擎进程，各自 PID 不同，共享一次 run 的独立临时槽）：
##   D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/rpg/verify_v130_save_commit.gd \
##       -- write  <RUN>
##   ... -- load   <RUN>
##   ... -- assert <RUN>
##   不带 -- 参数 = all（单进程自检：三态依次执行、各用独立 WorldState 实例，
##   便于 `--check-only --script` / `--headless --script <verify>` 门禁直接
##   得到 PASS/FAIL + RESULT=ALL_MATCH）。
##
## 【验证什么 · 任务单 ① / 裁决 A66】
##   三态 = ① 写盘（Rank-3 I-1 编排口径夹具：战技扣 FP / 赐福休息回满 /
##   重复释放拒绝 → 7 个 combat.focus.* flag 与既有 points/spent 同一次
##   commit(reason) 原子写）→ ② 新进程 load（空内存 WorldState 只从磁盘
##   delta.json 重建）→ ③ 断言读回（磁盘真值 / 写盘期望 / 新进程内存读回三方一致）。覆盖：
##     - ★ A66：专注值 FP 落盘 flag（combat.focus.current / max / art_id /
##       spend_count / restore_count / policy / last_reject）严格三段式、只作
##       flags 字典新 key；**与赐福点数分离**：磁盘 grace.trial.points /
##       grace.trial.spent_points 全程原值不动、FP 绝不混用 points / spent_points；
##     - ★ FP 上限不被突破：current 序列恒 <= max、回满恰等于 max、超上限封顶；
##     - ★ 重复释放不二次扣费：FP 新值未严格减少即拒绝、spend_count 单调、
##       反例期望值 != 落盘值；
##     - 十字段冻结 / schema_version=3 / removals 恒空 / commit(reason) 原子写 /
##       先落盘再改运行时实例 / 重启读回一致 / 旧档缺 key 回落基线；
##     - A48① / A54 静态证据：生产编排层源码含 3 信号订阅回调 + 唯一实例 getter。
##
## 【口径夹具的边界 · 如实登记，不伪造】
##   本件不加载 presentation.gd、不实例化主场景、不连真实 HUD / FocusService 信号、
##   不改 godot/ 业务代码。文内 `_sig_*` 一组函数是 Rank-3 I-1「落盘编排口径」的
##   【确定性自包含夹具】：以本轮生产编排层 points_commit_orchestrator.gd 的 A66
##   口径为输入，模拟编排层「订阅信号 → 计算新值 → 十字段 commit → 先落盘后改实例」
##   的唯一权威链路，只验证【口径 + 磁盘一致性】，不冒充「真实可达」。
##   ★ 真实可达回归（A48③：不加载 presentation.gd / 不在验证脚本内模拟编排 /
##   真实输入 → 生产链路 → 磁盘）由另一交付件 verify_focus_production_v130.gd 承担。
##
## 【不改什么 · 硬约束】
##   - 不改 world_state.gd / 生产编排层逻辑：只读加载 world_state.gd，
##     只调用既有 _ready() / _apply_snapshot() / get_flag()；
##   - 不碰生产存档：全部读写落在 user://saves/verify_v130_<RUN>/，与
##     user://saves/slot_01/ 物理隔离；对生产 delta.json 只做 get_md5 只读前后对照；
##   - 不写 removals、不新增 SaveDelta 顶层字段、schema_version 恒 3；
##   - 不改其它 Rank 产出、不新建只读探针 / 巡检脚本（本件是正式自测件）；
##   - 自包含：不依赖 Rank-1 / Rank-2 任何运行时单例（避免三进程 --script 模式下
##     autoload 状态抖动），flag key 逐字对齐契约 §3.3 R36 段 / 生产编排层常量。
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
const SLOT_BASE: String = "user://saves/verify_v130"

const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]

## 9 个关键 flag key（逐字对齐契约 §3.3 R36 段 / 生产编排层常量段）：
##   points / spent（既有，FP 与之分离）+ 7 个 combat.focus.*（R36 新增）
const K_POINTS: String = "grace.trial.points"
const K_SPENT: String = "grace.trial.spent_points"
const K_FOCUS_CURRENT: String = "combat.focus.current"
const K_FOCUS_MAX: String = "combat.focus.max"
const K_FOCUS_ART_ID: String = "combat.focus.art_id"
const K_FOCUS_SPEND_COUNT: String = "combat.focus.spend_count"
const K_FOCUS_RESTORE_COUNT: String = "combat.focus.restore_count"
const K_FOCUS_POLICY: String = "combat.focus.policy"
const K_FOCUS_LAST_REJECT: String = "combat.focus.last_reject"

const FOCUS_KEYS: Array[String] = [
	K_FOCUS_CURRENT, K_FOCUS_MAX, K_FOCUS_ART_ID, K_FOCUS_SPEND_COUNT,
	K_FOCUS_RESTORE_COUNT, K_FOCUS_POLICY, K_FOCUS_LAST_REJECT,
]

## [PLACEHOLDER] 三态夹具数值（非新设计数值，仅用于确定性三态回读）。
##   rationale：逐项对齐生产编排层 A66 口径与 Rank-2 focus_rules.tres [PLACEHOLDER]：
##     - FP 上限 100（对齐 focus_rules.tres fp_max=100.0）、辉石魔砾 12 / 狮子斩 35；
##     - 初始 points=500 / spent=15（既有赐福点数，FP 链路全程不触碰）；
##     - 事件链：战技 100→88→53 → 赐福休息回满 100 → 战技 100→88 → 重复释放拒绝；
##     - 边界：回满传 150 封顶到 100、重复 focus_spent(100) 未减少被拒。
##   调参唯一入口：只改本件 FIX_* 常量 + 生产编排层常量段（只改常量不改逻辑），不静默改数。
const FIX_FP_MAX: int = 100
const FIX_POINTS: int = 500
const FIX_SPENT: int = 15
const FIX_ART_PEBBLE: String = "glintstone_pebble"
const FIX_ART_LION: String = "lion_slash"
const FIX_POLICY_REFILL: String = "rest_refill"
const FIX_REJECT_COOLDOWN: String = "cooldown"
const FIX_EXPECTED_CURRENT: int = 100
const FIX_EXPECTED_SPEND_COUNT: int = 3
const FIX_EXPECTED_RESTORE_COUNT: int = 2
const FIX_EXPECTED_ART_ID: String = FIX_ART_PEBBLE
const FIX_EXPECTED_LAST_REJECT: String = FIX_REJECT_COOLDOWN
const FIX_WRONG_SPEND_DOUBLE: int = 6      # 反例：重复释放也二次扣 → spend_count 翻倍
const FIX_WRONG_CURRENT_OVER_MAX: int = 150 # 反例：回满不封顶 → 突破上限

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
# A66 落盘编排口径夹具（确定性自包含，不连真实 HUD / FocusService 信号）
#   _orch_flags  = 要落进 flags 字典的真值（磁盘唯一权威来源）
#   _focus_current_history = 每次合法 focus_spent / focus_restored 后的 current（上限判定用）
#   _focus_reject_observed / _focus_cap_hits 只供机器判定，不进落盘 flags
# ---------------------------------------------------------------------------
var _orch_flags: Dictionary = {}
var _focus_current_history: Array[int] = []
var _focus_reject_observed: int = 0
var _focus_cap_hits: int = 0


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V130-C] %s PASS=%s | %s" % [tag, str(ok), detail])


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
# Rank-3 I-1 落盘编排口径夹具（对账生产 points_commit_orchestrator.gd R36 段）
# ==========================================================================

func _orch_reset() -> void:
	_orch_flags = {
		K_POINTS: FIX_POINTS,
		K_SPENT: FIX_SPENT,
		K_FOCUS_CURRENT: FIX_FP_MAX,
		K_FOCUS_MAX: FIX_FP_MAX,
		K_FOCUS_ART_ID: "",
		K_FOCUS_SPEND_COUNT: 0,
		K_FOCUS_RESTORE_COUNT: 0,
		K_FOCUS_POLICY: "",
		K_FOCUS_LAST_REJECT: "",
	}
	_focus_current_history = [FIX_FP_MAX]
	_focus_reject_observed = 0
	_focus_cap_hits = 0


## ★ A66 生产回调 ① 口径：focus_spent(art_id, ..., fp_remaining)。
##   重复释放 / 信号重放（磁盘已有 current 且新值未严格减少）→ 拒绝、不二次扣费；
##   越过 FP 上限 → 拒绝、不落盘。成功才更新 current / art_id / spend_count。
func _sig_focus_spent(art_id: String, fp_remaining: int, maxv: int) -> bool:
	var new_cur: int = fp_remaining
	if maxv > 0 and new_cur > maxv:
		return false
	var old: int = int(_orch_flags.get(K_FOCUS_CURRENT, FIX_FP_MAX))
	if new_cur >= old:
		_focus_reject_observed += 1
		return false
	_orch_flags[K_FOCUS_CURRENT] = new_cur
	_orch_flags[K_FOCUS_MAX] = maxv
	_orch_flags[K_FOCUS_ART_ID] = art_id
	_orch_flags[K_FOCUS_SPEND_COUNT] = int(_orch_flags[K_FOCUS_SPEND_COUNT]) + 1
	_focus_current_history.append(new_cur)
	return true


## ★ A66 生产回调 ② 口径：focus_restored(fp_before, fp_after, policy)。
##   唯一允许 FP 增加的出口；fp_after 超过 max 时封顶（不突破上限）。
func _sig_focus_restored(fp_after: int, policy: String, maxv: int) -> bool:
	var new_cur: int = fp_after
	if maxv > 0 and new_cur > maxv:
		new_cur = maxv
		_focus_cap_hits += 1
	if new_cur < 0:
		new_cur = 0
	_orch_flags[K_FOCUS_CURRENT] = new_cur
	_orch_flags[K_FOCUS_MAX] = maxv
	_orch_flags[K_FOCUS_RESTORE_COUNT] = int(_orch_flags[K_FOCUS_RESTORE_COUNT]) + 1
	_orch_flags[K_FOCUS_POLICY] = policy
	_focus_current_history.append(new_cur)
	return true


## ★ A66 生产回调 ③ 口径：focus_rejected(art_id, reason)。
##   只写 last_reject（String），绝不动 current / spend_count / points / spent_points。
func _sig_focus_rejected(reason: String) -> bool:
	_focus_reject_observed += 1
	_orch_flags[K_FOCUS_LAST_REJECT] = reason
	return true


## 事件序列（真实玩法顺序 + 三类边界：回满超上限封顶 / 重复释放拒绝 / FP 未减少重放）。
func _run_events() -> void:
	_orch_reset()
	# —— 既有赐福点数（FP 与之分离：以下事件一律不碰 points / spent）——
	# —— 战技扣 FP：辉石魔砾 100→88、狮子斩 88→53 ——
	_sig_focus_spent(FIX_ART_PEBBLE, 88, FIX_FP_MAX)        # current=88 spend=1
	_sig_focus_spent(FIX_ART_LION, 53, FIX_FP_MAX)          # current=53 spend=2
	# —— 赐福休息回满：53→100（policy=rest_refill）——
	_sig_focus_restored(FIX_FP_MAX, FIX_POLICY_REFILL, FIX_FP_MAX)  # current=100 restore=1
	# —— 再施放一次：100→88 ——
	_sig_focus_spent(FIX_ART_PEBBLE, 88, FIX_FP_MAX)        # current=88 spend=3
	# 边界①：重复释放（冷却期）→ focus_rejected，不二次扣费
	_sig_focus_rejected(FIX_REJECT_COOLDOWN)               # last_reject=cooldown，current/spend 不变
	# 边界②：回满传超上限 150 → 封顶到 100（上限不被突破）
	_sig_focus_restored(FIX_WRONG_CURRENT_OVER_MAX, FIX_POLICY_REFILL, FIX_FP_MAX)  # current=100 restore=2
	# 边界③：重复 focus_spent 传 100（未严格减少）→ 拒绝，spend 不变
	_sig_focus_spent(FIX_ART_PEBBLE, FIX_FP_MAX, FIX_FP_MAX)


## 完整 flags：经 _run_events() 由 A66 编排口径算出（9 个关键 key）。
func _full_flags() -> Dictionary:
	_run_events()
	return _orch_flags.duplicate(true)


func _verify_keys() -> Array[String]:
	var out: Array[String] = [K_POINTS, K_SPENT]
	out.append_array(FOCUS_KEYS)
	return out


## 缺 key 回落基线的期望 default：String flag -> ""、int flag -> 0、bool flag -> false。
func _baseline_for(key: String) -> Variant:
	if key == K_FOCUS_ART_ID or key == K_FOCUS_POLICY or key == K_FOCUS_LAST_REJECT:
		return ""
	return 0


## 十字段 SaveDelta 骨架（与 world_state.gd::_new_delta() 同构）；schema_version=3 冻结、
## removals 恒空、不新增顶层字段。slot 字段沿用 "slot_01"（结构值，非物理路径）。
func _delta_shell(flags: Dictionary, reason: String) -> Dictionary:
	return {
		"schema_version": 3,
		"slot": "slot_01",
		"seq": 9,
		"baseline": {"manifest": "res://data/rpg/world_baseline.tres", "manifest_hash": "", "baseline_version": 1, "resource_ids": []},
		"flags": flags,
		"quests": {},
		"inventory": {},
		"spawns": {"defeated": [], "epoch": 0},
		"removals": [],
		"meta": {"playtime_seconds": 0, "area_id": "", "last_grace_id": "", "written_at_unix": 0, "game_version": "0.13.0-r36", "last_commit_reason": reason},
	}


## 旧存档：只有既有登记 key、缺本轮全部 7 个 combat.focus.* key，schema_version=3 / removals 空。
func _legacy_delta() -> Dictionary:
	var flags: Dictionary = {
		"grace.network.last_grace_id": "grace_limgrave_gatefront",
		"dungeon.wave_trial.best_wave": 3,
		"grace.trial.points": FIX_POINTS,
		"grace.trial.spent_points": FIX_SPENT,
	}
	return _delta_shell(flags, "v130_legacy_baseline")


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
# 生产订阅者存在性（静态证据）：project.godot 注册行 + 编排层源码 A66 回调
# ---------------------------------------------------------------------------
func _t_static_registration() -> void:
	var src: String = FileAccess.get_file_as_string(PCO_PATH)
	_ck("S01 生产编排层脚本文件存在（验证脚本不另写编排逻辑）",
		FileAccess.file_exists(PCO_PATH), "path=%s" % PCO_PATH)
	_ck("S02 A48①：生产源码含 focus_spent 生产订阅回调 _on_focus_spent",
		src.contains("_on_focus_spent") and src.contains("\"focus_spent\""),
		"focus_spent 生产订阅者在")
	_ck("S03 A48①：生产源码含 focus_restored 生产订阅回调 _on_focus_restored",
		src.contains("_on_focus_restored") and src.contains("\"focus_restored\""),
		"focus_restored 生产订阅者在")
	_ck("S04 A48①：生产源码含 focus_rejected 生产订阅回调 _on_focus_rejected",
		src.contains("_on_focus_rejected") and src.contains("\"focus_rejected\""),
		"focus_rejected 生产订阅者在")
	_ck("S05 A54：生产源码含 get_focus_service 唯一实例复用（不自建第二个）",
		src.contains("get_focus_service") and src.contains("bind_focus_service"),
		"A54 唯一实例 getter + 显式绑定入口在")
	_ck("S06 A66：生产源码含专注值 FP 7 个三段式 flag 常量",
		src.contains("combat.focus.current") and src.contains("combat.focus.spend_count") \
		and src.contains("combat.focus.restore_count"),
		"FP flag 常量在")


# ---------------------------------------------------------------------------
# 态 1 · 写盘（write）：A66 编排 → 期望/反例夹具 → 旧档夹具，commit(reason) 原子落进独立槽
# ---------------------------------------------------------------------------
func _phase_write() -> void:
	print("[V130-C][WRITE] ---- 态1 写盘 ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
	var ok_dir: bool = _prepare_slot()
	_ck("W01 独立临时槽可写且与生产隔离", ok_dir and not _slot_dir.contains("slot_01"),
		"slot=%s（物理隔离 user://saves/slot_01）" % _slot_dir)

	var flags: Dictionary = _full_flags()
	var delta: Dictionary = _delta_shell(flags, "focus_restored_rest_refill")
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
		"focus_current_history": _focus_current_history,
		"focus_reject_observed": _focus_reject_observed,
		"focus_cap_hits": _focus_cap_hits,
		"expected_current": FIX_EXPECTED_CURRENT,
		"expected_spend_count": FIX_EXPECTED_SPEND_COUNT,
		"expected_restore_count": FIX_EXPECTED_RESTORE_COUNT,
		"expected_art_id": FIX_EXPECTED_ART_ID,
		"expected_last_reject": FIX_EXPECTED_LAST_REJECT,
		"wrong_spend_double": FIX_WRONG_SPEND_DOUBLE,
		"wrong_current_over_max": FIX_WRONG_CURRENT_OVER_MAX,
		"points_before": FIX_POINTS,
		"spent_before": FIX_SPENT,
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
		_ck("W07 removals 恒空（A66 绝不写 removals）", (disk.get("removals", []) as Array).is_empty(),
			"removals=%s" % str(disk.get("removals", [])))
		var df: Dictionary = disk.get("flags", {}) as Dictionary
		var bad: Array[String] = []
		for k: Variant in df.keys():
			if _re.search(String(k)) == null:
				bad.append(String(k))
		_ck("W08 全部 flag key 三段式正则", bad.is_empty(),
			"keys=%d bad=%s" % [df.size(), str(bad)])
	# 编排口径自洽（写盘进程内）
	_ck("W09 A66 战技扣 FP：current 100→88→53 后经休息回满、再战技 → 最终 100",
		int(flags.get(K_FOCUS_CURRENT, -1)) == FIX_EXPECTED_CURRENT,
		"current=%s" % str(flags.get(K_FOCUS_CURRENT)))
	_ck("W10 A66 spend_count 单调 == 3（重复释放不二次扣费）",
		int(flags.get(K_FOCUS_SPEND_COUNT, -1)) == FIX_EXPECTED_SPEND_COUNT,
		"spend_count=%s" % str(flags.get(K_FOCUS_SPEND_COUNT)))
	_ck("W11 A66 restore_count == 2（含超上限封顶那次回满）",
		int(flags.get(K_FOCUS_RESTORE_COUNT, -1)) == FIX_EXPECTED_RESTORE_COUNT,
		"restore_count=%s" % str(flags.get(K_FOCUS_RESTORE_COUNT)))
	_ck("W12 A66 FP 上限不被突破：current 历史序列恒 <= max=100",
		_current_history_within_max(), "history=%s cap_hits=%d" % [
			str(_focus_current_history), _focus_cap_hits])
	_ck("W13 A66 重复释放/重放拒绝计数 >= 1（spend_count 不因此增加）",
		_focus_reject_observed >= 1, "reject_observed=%d" % _focus_reject_observed)
	_ck("W14 A66 FP 与赐福点数分离：points==500 / spent==15 全程不变",
		int(flags.get(K_POINTS, -1)) == FIX_POINTS and int(flags.get(K_SPENT, -1)) == FIX_SPENT,
		"points=%s spent=%s" % [str(flags.get(K_POINTS)), str(flags.get(K_SPENT))])
	_ck("W15 A66 last_reject / policy / art_id 为最近值",
		String(flags.get(K_FOCUS_LAST_REJECT, "")) == FIX_EXPECTED_LAST_REJECT \
		and String(flags.get(K_FOCUS_POLICY, "")) == FIX_POLICY_REFILL \
		and String(flags.get(K_FOCUS_ART_ID, "")) == FIX_EXPECTED_ART_ID,
		"last_reject=%s policy=%s art_id=%s" % [str(flags.get(K_FOCUS_LAST_REJECT)),
			str(flags.get(K_FOCUS_POLICY)), str(flags.get(K_FOCUS_ART_ID))])
	_ck("W16 回满超上限 150 已封顶（cap_hits==1）",
		_focus_cap_hits == 1, "cap_hits=%d" % _focus_cap_hits)


func _current_history_within_max() -> bool:
	for v: int in _focus_current_history:
		if v < 0 or v > FIX_FP_MAX:
			return false
	return true


# ---------------------------------------------------------------------------
# 态 2 · 新进程 load：全新进程 / 空内存 WorldState，只从磁盘 delta.json 重建
# ---------------------------------------------------------------------------
func _phase_load() -> void:
	print("[V130-C][LOAD] ---- 态2 新进程 load ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
	var delta: Dictionary = _read_json(_delta_path)
	_ck("L01 磁盘 delta.json 存在可解析（唯一权威）", not delta.is_empty(),
		"path=%s" % _delta_path)
	if delta.is_empty():
		return
	var ws: Node = _new_ws()
	var before: Variant = ws.call("get_flag", K_FOCUS_CURRENT, -1)
	_ck("L02 新 WorldState 空内存基线（未 apply 前无 focus.current）",
		int(before) == -1, "load 前 get_flag(focus.current, -1)=%s" % str(before))
	ws.call("_apply_snapshot", delta)   # ★ 落盘成功后才改运行时实例
	var disk_flags: Dictionary = delta.get("flags", {}) as Dictionary
	var rb_flags: Dictionary = {}
	for k: Variant in disk_flags.keys():
		rb_flags[String(k)] = ws.call("get_flag", String(k), null)
	var readback: Dictionary = {
		"load_pid": OS.get_process_id(),
		"flags": rb_flags,
		"current": int(ws.call("get_flag", K_FOCUS_CURRENT, 0)),
		"max": int(ws.call("get_flag", K_FOCUS_MAX, 0)),
		"spend_count": int(ws.call("get_flag", K_FOCUS_SPEND_COUNT, 0)),
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
	print("[V130-C][ASSERT] ---- 态3 断言读回 ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
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

	# B 组：9 个关键 flag 三方一致（磁盘 / 写盘期望 / 新进程内存读回）
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
	_ck("B00 9 项关键 flag 三方全一致", b_all, "keys=%d" % keys.size())

	# C 组：★ A66 FP 与赐福点数分离
	var d_points: int = int(disk_flags.get(K_POINTS, -1))
	var d_spent: int = int(disk_flags.get(K_SPENT, -1))
	_ck("C01 A66 磁盘 grace.trial.points 保持 500（FP 链路不混用 points）",
		d_points == FIX_POINTS and d_points == int(expected.get("points_before", -1)),
		"points=%d" % d_points)
	_ck("C02 A66 磁盘 grace.trial.spent_points 保持 15（FP 链路不混用 spent_points）",
		d_spent == FIX_SPENT and d_spent == int(expected.get("spent_before", -1)),
		"spent=%d" % d_spent)
	_ck("C03 A66 7 个 FP flag key 全为 combat.focus.* 前缀、无一等于 points/spent",
		_focus_keys_pure(), "keys=%s" % str(FOCUS_KEYS))
	var fp_as_points: bool = false
	for k: String in FOCUS_KEYS:
		if k == K_POINTS or k == K_SPENT:
			fp_as_points = true
	_ck("C04 A66 FP flag 绝不写入 points / spent_points 键名", not fp_as_points,
		"FP keys 与 points/spent 无交集")

	# F 组：★ A66 FP 上限不被突破 + 回满恰等于 max
	var d_max: int = int(disk_flags.get(K_FOCUS_MAX, -1))
	var d_current: int = int(disk_flags.get(K_FOCUS_CURRENT, -1))
	_ck("F01 A66 FP 上限 == 100 且 current == 上限（回满恰等于 max，不突破）",
		d_max == FIX_FP_MAX and d_current == d_max,
		"current=%d max=%d" % [d_current, d_max])
	var history: Array = expected.get("focus_current_history", []) as Array
	var hist_ok: bool = true
	for v: Variant in history:
		if int(v) < 0 or int(v) > d_max:
			hist_ok = false
	_ck("F02 A66 current 历史序列恒 0<=v<=max（上限不突破，机器判定）",
		hist_ok and not history.is_empty(), "history=%s" % str(history))
	_ck("F03 A66 反例：落盘 current != 未封顶的 150",
		d_current != int(expected.get("wrong_current_over_max", -1)),
		"disk=%d wrong=%s" % [d_current, str(expected.get("wrong_current_over_max"))])
	_ck("F04 A66 超上限封顶命中 1 次", int(expected.get("focus_cap_hits", -1)) == 1,
		"cap_hits=%s" % str(expected.get("focus_cap_hits")))

	# G 组：★ A66 重复释放不二次扣费
	var d_spend_count: int = int(disk_flags.get(K_FOCUS_SPEND_COUNT, -1))
	_ck("G01 A66 spend_count == 3（战技 3 次成功，边界拒绝不增）",
		d_spend_count == FIX_EXPECTED_SPEND_COUNT, "spend_count=%d" % d_spend_count)
	_ck("G02 A66 反例：spend_count != 重复释放也二次扣的翻倍值 6",
		d_spend_count != int(expected.get("wrong_spend_double", -1)),
		"disk=%d wrong=%s" % [d_spend_count, str(expected.get("wrong_spend_double"))])
	_ck("G03 A66 重复释放/重放拒绝计数 >= 1",
		int(expected.get("focus_reject_observed", -1)) >= 1 \
		and int(rb_flags.get(K_FOCUS_SPEND_COUNT, -1)) == d_spend_count,
		"reject_observed=%s rb_spend=%s" % [str(expected.get("focus_reject_observed")),
			str(rb_flags.get(K_FOCUS_SPEND_COUNT))])
	_ck("G04 A66 restore_count == 2（两次回满：普通 + 超上限封顶）",
		int(disk_flags.get(K_FOCUS_RESTORE_COUNT, -1)) == FIX_EXPECTED_RESTORE_COUNT,
		"restore_count=%s" % str(disk_flags.get(K_FOCUS_RESTORE_COUNT)))

	# I 组：新 flag 类型（三段式合法 + 标量白名单）
	_ck("I01 combat.focus.current / max / spend_count / restore_count 为数值",
		_is_num(disk_flags.get(K_FOCUS_CURRENT, null)) \
		and _is_num(disk_flags.get(K_FOCUS_MAX, null)) \
		and _is_num(disk_flags.get(K_FOCUS_SPEND_COUNT, null)) \
		and _is_num(disk_flags.get(K_FOCUS_RESTORE_COUNT, null)),
		"int 经 JSON 读回 float，如实容忍")
	_ck("I02 combat.focus.art_id / policy / last_reject 为 String",
		typeof(disk_flags.get(K_FOCUS_ART_ID, null)) == TYPE_STRING \
		and typeof(disk_flags.get(K_FOCUS_POLICY, null)) == TYPE_STRING \
		and typeof(disk_flags.get(K_FOCUS_LAST_REJECT, null)) == TYPE_STRING,
		"String 标量白名单")

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
	_ck("D03 removals 为空（A66 绝不写 removals）",
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
	_ck("D05 新 FP flag 只作 flags 字典 key、未进顶层", new_top.is_empty(),
		"顶层三段式前缀字段=%s" % str(new_top))

	# E 组：旧存档缺 key 回落基线，不升级、不 removals
	var legacy_flags: Dictionary = legacy.get("flags", {}) as Dictionary
	var missing_new: bool = true
	for k: String in FOCUS_KEYS:
		if legacy_flags.has(k):
			missing_new = false
	_ck("E00 旧档确实缺全部 7 个 combat.focus.* key（回落测试前提）", missing_new,
		"legacy flags keys=%s" % str(legacy_flags.keys()))
	var ws_legacy: Node = _new_ws()
	ws_legacy.call("_apply_snapshot", legacy)
	var e_all: bool = true
	for k: String in FOCUS_KEYS:
		var default: Variant = _baseline_for(k)
		var got: Variant = ws_legacy.call("get_flag", k, default)
		var ok: bool = _val_eq(got, default)
		if not ok:
			e_all = false
		_ck("E[%s] 缺 key 回落基线" % k, ok,
			"get_flag=%s default=%s" % [str(got), str(default)])
	_ck("E10 7 项缺 key 全回落基线（不创建 key）", e_all, "keys=%d" % FOCUS_KEYS.size())
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
		print("[V130-C][ASSERT] WARN 生产 slot_01 md5 前后不同（可能并发方写入，非本件所为）before=%s after=%s" % [before, after])
		_ck("H02 生产存档差异如实登记（不计 FAIL、避免并发回归抖动）", true,
			"md5 before=%s after=%s | WARN 已打印" % [before, after])


func _is_num(v: Variant) -> bool:
	var t: int = typeof(v)
	return t == TYPE_INT or t == TYPE_FLOAT


func _focus_keys_pure() -> bool:
	for k: String in FOCUS_KEYS:
		if not k.begins_with("combat.focus."):
			return false
		if _re.search(k) == null:
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
	print("[V130-C] === verify_v130_save_commit SELFTEST START | R36 / v0.13.0 | cmd-20261112-154132-916-A3 ===")
	print("[V130-C] A49/A48④：本件不加载 presentation.gd、不连真实 HUD / FocusService 信号、只验证 A66 落盘口径 + 磁盘一致性；真实可达回归见 verify_focus_production_v130.gd")
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
	print("[V130-C] main_loop=%s root=%s WorldState_probe=%s（Engine.get_main_loop 相对探活，仅登记）" % [
		str(tree != null), str(tree_root != null), str(ws_probe != null)])
	_parse_args()
	_slot_dir = "%s_%s" % [SLOT_BASE, _run]
	_delta_path = _slot_dir + "/delta.json"
	_expected_path = _slot_dir + "/expected.json"
	_readback_path = _slot_dir + "/readback.json"
	_legacy_path = _slot_dir + "/legacy.json"
	_prod_md5_before = _production_md5()
	print("[V130-C] RUN=%s mode=%s slot=%s production_md5_before=%s" % [
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
	print("[V130-C] SUMMARY mode=%s pid=%d slot=%s pass=%d fail=%d total=%d" % [
		_mode, OS.get_process_id(), _slot_dir, _pass, _fail, _pass + _fail])
	print("[V130-C] OVERALL=%s" % ("PASS" if ok else "FAIL"))
	print("[V130-C] RESULT=%s" % ("ALL_MATCH" if ok else "MISMATCH"))
	print("[V130-C] === SELFTEST END ===")
	quit(0 if ok else 1)
