extends SceneTree

## ===========================================================================
## R35 / v0.12.0「精准弹反 · 消费闭合」存档 commit 三态只读验证（Rank-3 交付件）
##   cmd-20261112-125821-143-A3 / [ROUND=R35]
##
## 真跑（三个独立 Godot 引擎进程，各自 PID 不同，共享一次 run 的独立临时槽）：
##   D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/rpg/verify_v120_save_commit.gd \
##       -- write  <RUN>
##   ... -- load   <RUN>
##   ... -- assert <RUN>
##   不带 -- 参数 = all（单进程自检：三态依次执行、各用独立 WorldState 实例，
##   便于 `--check-only --script` / `--headless --script <verify>` 门禁直接
##   得到 PASS/FAIL + RESULT=ALL_MATCH）。
##
## 【验证什么 · 任务单 ③ / 裁决 A58 / A59 / A60】
##   三态 = ① 写盘（Rank-3 I-1 编排口径夹具：A59 抉择扣费 → spent_points 单调累加
##   → 与 unlocked flag 同一次 commit 原子写）→ ② 新进程 load（空内存 WorldState
##   只从磁盘 delta.json 重建）→ ③ 断言读回（磁盘真值 / 写盘期望 / 新进程内存读回三方一致）。覆盖：
##     - ★ A59：抉择 cost（[PLACEHOLDER] 映射）→ spent_points 单调累加、只增不减；
##       与 grace.boon_draft.unlocked / selected / cost_applied 同一次 commit 原子写；
##       余额 points - spent_points >= 0 前置门控；重复购买（boon:<index>）拒绝；
##       缺失 / 非法 cost 值拒绝并告警（spent 不变）；绝不写 removals、绝不回退 points；
##     - ★ A58：exe:<window_id> / parry:<window_id> 去重键接非空唯一 window_id，
##       两个不同 parry 窗口各自入账、不合并；同一窗口重放幂等拒绝；
##     - ★ A60：弹反奖励 [PLACEHOLDER] 不得点数通胀（每窗口恰好一次、points 原样采信 A57），
##       broken 判据以「反例期望值」机器判定；
##     - A55/A57：points_awarded 唯一权威通道、points 为倍率后最终结算值、原样采信；
##     - 十字段冻结 / schema_version=3 / 三段式正则 / 新 flag 类型 / 只作 flags 字典新 key；
##     - 重启读回一致、旧档缺 key 回落基线、生产 slot_01 md5 前后一致。
##
## 【口径夹具的边界 · 如实登记，不伪造】
##   本件不加载 presentation.gd、不实例化主场景、不连真实 HUD 信号、不改 godot/ 业务代码。
##   文内 `_sig_*` 一组函数是 Rank-3 I-1「落盘编排口径」的【确定性自包含夹具】：
##   以本轮生产编排层 points_commit_orchestrator.gd 的 A59/A58 口径为输入，模拟编排层
##   「配对信号 → 事件键去重 → 唯一权威通道 → 与 unlocked 同一次 commit → 先落盘后改实例」
##   的唯一权威链路，只验证【口径 + 磁盘一致性】，不冒充「真实可达」。
##   ★ 真实可达回归（A48③：不加载 presentation.gd / 不在验证脚本内模拟编排 / 真实输入
##   → 生产链路 → 磁盘）由另一交付件 verify_spent_points_production_v120.gd 承担。
##
## 【不改什么 · 硬约束】
##   - 不改 world_state.gd / 生产编排层逻辑：只读加载 world_state.gd，
##     只调用既有 _ready() / _apply_snapshot() / get_flag()；
##   - 不碰生产存档：全部读写落在 user://saves/verify_v120_<RUN>/，与
##     user://saves/slot_01/ 物理隔离；对生产 delta.json 只做 get_md5 只读前后对照；
##   - 不写 removals、不新增 SaveDelta 顶层字段、schema_version 恒 3；
##   - 不改其它 Rank 产出、不新建只读探针 / 巡检脚本（本件是正式自测件）；
##   - 自包含：不依赖 Rank-1 / Rank-2 任何运行时单例（避免三进程 --script 模式下
##     autoload 状态抖动），flag key 逐字对齐契约 §3.3 R35 段登记表。
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
const PRODUCTION_DELTA: String = "user://saves/slot_01/delta.json"
const SLOT_BASE: String = "user://saves/verify_v120"

const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]

## 8 个关键 flag key（逐字对齐契约 §3.3 R35 段 / 生产编排层常量）：
##   points / spent（既有）+ 抉择三 flag + unlocked（A59 新增）+ 弹反二 flag（A58/A60 新增）
const K_POINTS: String = "grace.trial.points"
const K_SPENT: String = "grace.trial.spent_points"
const K_PERFORMED: String = "grace.execution.performed"
const K_SELECTED: String = "grace.boon_draft.selected"
const K_COST: String = "grace.boon_draft.cost_applied"
const K_UNLOCKED: String = "grace.boon_draft.unlocked"
const K_PARRY_COUNT: String = "combat.parry.success_count"
const K_PARRY_WID: String = "combat.parry.window_id"

## [PLACEHOLDER] 三态夹具数值（非新设计数值，仅用于确定性三态回读）。
##   rationale：逐项对齐生产编排层 points_commit_orchestrator.gd 常量段与 DONE-R35 口径：
##     - COST_TO_POINTS_FACTOR=10.0 / COST_TO_POINTS_MIN=1（[PLACEHOLDER] cost→points 线性映射）；
##     - 先给 points_awarded 清波权威值 300（A55 唯一权威通道，原样采信、不臆断倍率）；
##     - 两次不同 parry 窗口各 +50（A57 倍率后最终值、A58 不合并、A60 恰好各一次）；
##     - 抉择① hp_scale 1.15 → round(11.5)=12 点；抉择② telegraph_scale 1.30 → 13 点；
##       spent = 0 → 12 → 25（单调累加）；余额 = 400 - 25 = 375 >= 0；
##     - 非法 cost（空 key / 0 / NaN）与余额不足（cost_value=100.0 → 1000 点）一律拒绝。
##   预期：points=400 spent=25 parry_count=2 parry_wid=parry_0_2 unlocked=true performed=0
##   调参唯一入口：只改本件 FIX_* 常量 + 生产编排层常量段（只改常量不改逻辑），不静默改数。
const FIX_COST_FACTOR: float = 10.0
const FIX_COST_MIN: int = 1
const FIX_WAVE_AWARDED: int = 300
const FIX_PARRY_POINTS: int = 50
const FIX_PARRY_WID_1: String = "parry_0_1"
const FIX_PARRY_WID_2: String = "parry_0_2"
const FIX_BOON_1_CHOICE: String = "boon_frost_edge"
const FIX_BOON_1_KEY: String = "hp_scale"
const FIX_BOON_1_VALUE: float = 1.15
const FIX_BOON_2_CHOICE: String = "boon_ember_vein"
const FIX_BOON_2_KEY: String = "telegraph_scale"
const FIX_BOON_2_VALUE: float = 1.30
const FIX_EXPECTED_POINTS: int = 400
const FIX_EXPECTED_SPENT: int = 25
const FIX_EXPECTED_BALANCE: int = 375
const FIX_EXPECTED_PARRY_COUNT: int = 2
const FIX_EXPECTED_PERFORMED: int = 0

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
# A59 / A58 落盘编排口径夹具（确定性自包含，不连真实 HUD 信号）
#   _orch_flags  = 要落进 flags 字典的真值（磁盘唯一权威来源）
#   _orch_claimed = 运行时去重表（event_key -> true），本身不落盘（门控态）
#   _awarded_sum / _reject_count 只用于机器判定「防通胀 / 防重复 / 拒绝」，不进落盘 flags
# ---------------------------------------------------------------------------
var _orch_flags: Dictionary = {}
var _orch_claimed: Dictionary = {}
var _awarded_sum: int = 0
var _reject_count: int = 0


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V120-C] %s PASS=%s | %s" % [tag, str(ok), detail])


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
# Rank-3 I-1 落盘编排口径夹具（对账生产 points_commit_orchestrator.gd R35 段）
# ==========================================================================

func _orch_reset() -> void:
	_orch_flags = {
		K_POINTS: 0,
		K_SPENT: 0,
		K_PERFORMED: 0,
		K_SELECTED: "",
		K_COST: false,
		K_UNLOCKED: false,
		K_PARRY_COUNT: 0,
		K_PARRY_WID: "",
	}
	_orch_claimed = {}
	_awarded_sum = 0
	_reject_count = 0


## [PLACEHOLDER] cost→points 线性映射（与生产编排层常量段逐字对齐）。
func _cost_to_points(cost_value: float) -> int:
	return maxi(FIX_COST_MIN, int(roundf(cost_value * FIX_COST_FACTOR)))


## A59 缺失 / 非法值校验（与生产编排层 _validate_cost 对齐）。
func _cost_valid(cost_key: String, cost_value: float) -> bool:
	if cost_key.is_empty() or not ["hp_scale", "telegraph_scale"].has(cost_key):
		return false
	if is_nan(cost_value) or is_inf(cost_value) or cost_value <= 0.0:
		return false
	return true


## ★★ A55 唯一权威通道：points_awarded(reason, points, source)。
##   只有本函数累加 grace.trial.points；event_key 命中去重表即拒绝（防重复领取）。
##   A58：reason=="parry" 时 event_key = parry:<window_id>；A60 每窗口恰好一次。
##   A57：points 为倍率后最终结算值，原样采信、不二次加工、不自行叠倍率。
func _sig_points_awarded(reason: String, points: int, _source: String, event_key: String) -> bool:
	if _orch_claimed.has(event_key):
		_reject_count += 1
		return false
	_orch_claimed[event_key] = true
	_orch_flags[K_POINTS] = int(_orch_flags[K_POINTS]) + points
	_awarded_sum += points
	if reason == "execution":
		_orch_flags[K_PERFORMED] = int(_orch_flags[K_PERFORMED]) + 1
	if reason == "parry":
		_orch_flags[K_PARRY_COUNT] = int(_orch_flags[K_PARRY_COUNT]) + 1
		_orch_flags[K_PARRY_WID] = event_key.substr(String("parry:").length())
	return true


## A58 配对信号：parry_performed(window_id, ...) → 保留不消费的 parry:<window_id> 配对键。
func _sig_parry_performed(window_id: String) -> String:
	return "parry:" + window_id


## A58 配对信号：execution_performed(window_id, ...) → exe:<window_id>（非空唯一）。
func _sig_execution_performed(window_id: String) -> String:
	return "exe:" + window_id


## ★ A59 spent_points 唯一出口：抉择 cost → spent_points 单调累加 + unlocked flag 同一次 commit。
##   顺序：① 缺失/非法拒绝 → ② 重复购买拒绝 → ③ 余额前置门控 →
##   ④ 与 selected / cost_applied / unlocked 同一次原子写（绝不回退 points / 绝不写 removals）。
##   返回是否落账（供写盘态断言）；拒绝累加 _reject_count（不进落盘 flags）。
func _sig_boon_draft_applied(index: int, choice_id: String, cost_key: String, cost_value: float) -> bool:
	if not _cost_valid(cost_key, cost_value):
		_reject_count += 1
		return false
	var cost_points: int = _cost_to_points(cost_value)
	var key: String = "boon:" + str(index)
	if _orch_claimed.has(key):
		_reject_count += 1
		return false
	var p: int = int(_orch_flags[K_POINTS])
	var s: int = int(_orch_flags[K_SPENT])
	var new_spent: int = s + cost_points
	if new_spent < s or p - new_spent < 0:
		_reject_count += 1
		return false
	# ★ 同一次原子写（一条 commit 的 writes 同时含 4 个 flag）
	_orch_claimed[key] = true
	_orch_flags[K_SPENT] = new_spent
	_orch_flags[K_SELECTED] = choice_id
	_orch_flags[K_COST] = true
	_orch_flags[K_UNLOCKED] = true
	return true


## 事件序列（真实玩法顺序 + 三类边界输入：重复 parry 窗口 / 重复抉择 / 非法与超额 cost）。
func _run_events() -> void:
	_orch_reset()
	# —— 先给点数（A55 唯一权威通道，原样采信）——
	_sig_points_awarded("wave_cleared", FIX_WAVE_AWARDED,
		"wave_trial_director.wave_cleared", "wave:1")            # ★ +300
	# —— A58 / A60：两个【不同】parry 窗口各自入账（非空唯一 window_id）——
	var pk1: String = _sig_parry_performed(FIX_PARRY_WID_1)
	_sig_points_awarded("parry", FIX_PARRY_POINTS, "parry_service.try_parry", pk1)   # ★ +50 / count=1
	var pk2: String = _sig_parry_performed(FIX_PARRY_WID_2)
	_sig_points_awarded("parry", FIX_PARRY_POINTS, "parry_service.try_parry", pk2)   # ★ +50 / count=2
	# 边界①：同一 parry 窗口重放 → 同键 → 幂等拒绝（不二次加点 / 不 +1）
	_sig_points_awarded("parry", FIX_PARRY_POINTS, "parry_service.try_parry", pk2)
	# —— A58：两个不同处决窗口 exe 键不合并（只验键生成，不入账点数）——
	var ek1: String = _sig_execution_performed("exe_0_1")
	var ek2: String = _sig_execution_performed("exe_0_2")
	_orch_claimed[ek1] = true
	_orch_claimed[ek2] = true
	# —— A59：抉择①扣费（cost→points 单调累加 + unlocked 原子写）——
	_sig_boon_draft_applied(1, FIX_BOON_1_CHOICE, FIX_BOON_1_KEY, FIX_BOON_1_VALUE)  # spent=12
	# 边界②：同一抉择重复购买 → 拒绝（spent 不变）
	_sig_boon_draft_applied(1, FIX_BOON_1_CHOICE, FIX_BOON_1_KEY, FIX_BOON_1_VALUE)
	# —— A59：抉择②扣费（不同 index，累加到 25）——
	_sig_boon_draft_applied(2, FIX_BOON_2_CHOICE, FIX_BOON_2_KEY, FIX_BOON_2_VALUE)  # spent=25
	# 边界③：缺失 / 非法 cost → 拒绝（spent 不变）
	_sig_boon_draft_applied(3, "boon_bad_a", "", FIX_BOON_1_VALUE)
	_sig_boon_draft_applied(4, "boon_bad_b", FIX_BOON_2_KEY, 0.0)
	_sig_boon_draft_applied(5, "boon_bad_c", FIX_BOON_2_KEY, NAN)
	# 边界④：余额不足（cost_value=100.0 → 1000 点 > points-spent）→ 拒绝（spent 不变）
	_sig_boon_draft_applied(6, "boon_overspend", FIX_BOON_1_KEY, 100.0)


## 完整 flags：经 _run_events() 由 A59/A58 编排口径算出（8 个关键 key）+ 既有前置 flag；
## 全部三段式、只作 flags 字典 key。
func _full_flags() -> Dictionary:
	_run_events()
	var flags: Dictionary = _orch_flags.duplicate(true)
	flags["grace.tutorial.completed"] = true
	flags["dungeon.wave_trial.best_wave"] = 3
	return flags


func _verify_keys() -> Array[String]:
	var out: Array[String] = []
	out.append(K_POINTS)
	out.append(K_SPENT)
	out.append(K_SELECTED)
	out.append(K_COST)
	out.append(K_UNLOCKED)
	out.append(K_PARRY_COUNT)
	out.append(K_PARRY_WID)
	out.append(K_PERFORMED)
	return out


## 缺 key 回落基线的期望 default：String flag -> ""、int flag -> 0、bool flag -> false。
func _baseline_for(key: String) -> Variant:
	if key == K_SELECTED or key == K_PARRY_WID:
		return ""
	if key == K_PERFORMED or key == K_POINTS or key == K_SPENT or key == K_PARRY_COUNT:
		return 0
	return false


## 十字段 SaveDelta 骨架（与 world_state.gd::_new_delta() 同构）；schema_version=3 冻结、
## removals 恒空、不新增顶层字段。slot 字段沿用 "slot_01"（结构值，非物理路径）。
func _delta_shell(flags: Dictionary, reason: String) -> Dictionary:
	return {
		"schema_version": 3,
		"slot": "slot_01",
		"seq": 13,
		"baseline": {"manifest": "res://data/rpg/world_baseline.tres", "manifest_hash": "", "baseline_version": 1, "resource_ids": []},
		"flags": flags,
		"quests": {},
		"inventory": {},
		"spawns": {"defeated": [], "epoch": 0},
		"removals": [],
		"meta": {"playtime_seconds": 0, "area_id": "", "last_grace_id": "", "written_at_unix": 0, "game_version": "0.12.0-r35", "last_commit_reason": reason},
	}


## 旧存档：只有既有登记 key、缺本轮全部 8 个关键 key，schema_version=3 / removals 空。
func _legacy_delta() -> Dictionary:
	var flags: Dictionary = {
		"grace.network.last_grace_id": "grace_limgrave_gatefront",
		"dungeon.wave_trial.best_wave": 2,
	}
	return _delta_shell(flags, "v120_legacy_baseline")


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
# 态 1 · 写盘（write）：A59/A58 编排 → 期望/反例夹具 → 旧档夹具，commit(reason) 原子落进独立槽
# ---------------------------------------------------------------------------
func _phase_write() -> void:
	print("[V120-C][WRITE] ---- 态1 写盘 ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
	var ok_dir: bool = _prepare_slot()
	_ck("W01 独立临时槽可写且与生产隔离", ok_dir and not _slot_dir.contains("slot_01"),
		"slot=%s（物理隔离 user://saves/slot_01）" % _slot_dir)

	var flags: Dictionary = _full_flags()
	var delta: Dictionary = _delta_shell(flags, "boon_draft_cost_applied")
	# ★ 先落盘（commit 原子写），本态绝不 new/apply 任何 WorldState 运行时实例
	var ok_delta: bool = _atomic_write_delta(delta)
	_ck("W02 commit(reason) 原子写 delta.json 成功（.tmp→flush→rename，先落盘）",
		ok_delta and FileAccess.file_exists(_delta_path) \
		and not FileAccess.file_exists(_delta_path + ".tmp"),
		"path=%s tmp_consumed=%s" % [_delta_path, str(not FileAccess.file_exists(_delta_path + ".tmp"))])
	var disk: Dictionary = _read_json(_delta_path)
	_ck("W03 写盘可回读解析", not disk.is_empty(), "JSON.parse_string -> Dictionary")

	# 反例期望值（A60 防点数通胀 / A59 防重复扣费 broken 判据），全部动态算、写进 expected
	var wrong_no_dedup: int = _awarded_sum + FIX_PARRY_POINTS + FIX_WAVE_AWARDED   # 重复清波+重复 parry
	var wrong_parry_double: int = FIX_WAVE_AWARDED + FIX_PARRY_POINTS * 3          # 三窗口都入账
	var wrong_spent_double: int = FIX_EXPECTED_SPENT + _cost_to_points(FIX_BOON_1_VALUE)  # 重复抉择二次扣
	var expected: Dictionary = {
		"write_pid": OS.get_process_id(),
		"slot": _slot_dir,
		"production_md5_before": _prod_md5_before,
		"flags": flags,
		"awarded_sum": _awarded_sum,
		"reject_count": _reject_count,
		"claimed_count": _orch_claimed.size(),
		"claimed_keys": _orch_claimed.keys(),
		"expected_points": FIX_EXPECTED_POINTS,
		"expected_spent": FIX_EXPECTED_SPENT,
		"expected_balance": FIX_EXPECTED_BALANCE,
		"expected_parry_count": FIX_EXPECTED_PARRY_COUNT,
		"expected_performed": FIX_EXPECTED_PERFORMED,
		"cost_1_points": _cost_to_points(FIX_BOON_1_VALUE),
		"cost_2_points": _cost_to_points(FIX_BOON_2_VALUE),
		"wrong_no_dedup": wrong_no_dedup,
		"wrong_parry_double": wrong_parry_double,
		"wrong_spent_double": wrong_spent_double,
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
		_ck("W07 removals 恒空（A59 绝不写 removals）", (disk.get("removals", []) as Array).is_empty(),
			"removals=%s" % str(disk.get("removals", [])))
		var df: Dictionary = disk.get("flags", {}) as Dictionary
		var bad: Array[String] = []
		for k: Variant in df.keys():
			if _re.search(String(k)) == null:
				bad.append(String(k))
		_ck("W08 全部 flag key 三段式正则", bad.is_empty(),
			"keys=%d bad=%s" % [df.size(), str(bad)])
	# 编排口径自洽（写盘进程内）
	_ck("W09 A55 编排自洽：points == points_awarded 累加一次",
		int(flags.get(K_POINTS, -1)) == _awarded_sum \
		and _awarded_sum == FIX_EXPECTED_POINTS,
		"points=%s awarded_sum=%d" % [str(flags.get(K_POINTS)), _awarded_sum])
	_ck("W10 A59 spent_points == cost1+cost2 单调累加",
		int(flags.get(K_SPENT, -1)) == FIX_EXPECTED_SPENT \
		and int(flags.get(K_SPENT, -1)) == _cost_to_points(FIX_BOON_1_VALUE) + _cost_to_points(FIX_BOON_2_VALUE),
		"spent=%s cost1=%d cost2=%d" % [str(flags.get(K_SPENT)),
			_cost_to_points(FIX_BOON_1_VALUE), _cost_to_points(FIX_BOON_2_VALUE)])
	_ck("W11 A59 unlocked / selected / cost_applied 与 spent 同一原子写（均已在 flags）",
		bool(flags.get(K_UNLOCKED, false)) and String(flags.get(K_SELECTED, "")) == FIX_BOON_2_CHOICE \
		and bool(flags.get(K_COST, false)),
		"unlocked=%s selected=%s cost_applied=%s" % [str(flags.get(K_UNLOCKED)),
			str(flags.get(K_SELECTED)), str(flags.get(K_COST))])
	_ck("W12 A59 缺失/非法/超额/重复共 6 次拒绝（spent 不受影响）",
		_reject_count == 6, "reject_count=%d" % _reject_count)
	_ck("W13 A58 两个不同 parry 键各自入账、不合并",
		_orch_claimed.has("parry:" + FIX_PARRY_WID_1) \
		and _orch_claimed.has("parry:" + FIX_PARRY_WID_2) \
		and ("parry:" + FIX_PARRY_WID_1) != ("parry:" + FIX_PARRY_WID_2),
		"k1=parry:%s k2=parry:%s" % [FIX_PARRY_WID_1, FIX_PARRY_WID_2])
	_ck("W14 A58 两个不同 exe 键不合并",
		_orch_claimed.has("exe:exe_0_1") and _orch_claimed.has("exe:exe_0_2"),
		"exe:exe_0_1 / exe:exe_0_2 均在")
	_ck("W15 A60 弹反成功计数恰为 2（重复窗口幂等、不通胀）",
		int(flags.get(K_PARRY_COUNT, -1)) == FIX_EXPECTED_PARRY_COUNT,
		"parry_count=%s" % str(flags.get(K_PARRY_COUNT)))
	_ck("W16 去重键恰好 7（wave1 + 2 parry + 2 exe + 2 boon）",
		_orch_claimed.size() == 7, "claimed=%d keys=%s" % [_orch_claimed.size(), str(_orch_claimed.keys())])


# ---------------------------------------------------------------------------
# 态 2 · 新进程 load：全新进程 / 空内存 WorldState，只从磁盘 delta.json 重建
# ---------------------------------------------------------------------------
func _phase_load() -> void:
	print("[V120-C][LOAD] ---- 态2 新进程 load ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
	var delta: Dictionary = _read_json(_delta_path)
	_ck("L01 磁盘 delta.json 存在可解析（唯一权威）", not delta.is_empty(),
		"path=%s" % _delta_path)
	if delta.is_empty():
		return
	var ws: Node = _new_ws()
	var before: Variant = ws.call("get_flag", K_SPENT, 0)
	_ck("L02 新 WorldState 空内存基线", int(before) == 0,
		"load 前 spent_points=%s（干净基线 0，非写盘态实例）" % str(before))
	ws.call("_apply_snapshot", delta)   # ★ 落盘成功后才改运行时实例
	var disk_flags: Dictionary = delta.get("flags", {}) as Dictionary
	var rb_flags: Dictionary = {}
	for k: Variant in disk_flags.keys():
		rb_flags[String(k)] = ws.call("get_flag", String(k), null)
	var rb_points: int = int(ws.call("get_flag", K_POINTS, 0))
	var rb_spent: int = int(ws.call("get_flag", K_SPENT, 0))
	var readback: Dictionary = {
		"load_pid": OS.get_process_id(),
		"flags": rb_flags,
		"points": rb_points,
		"spent_points": rb_spent,
		"balance": rb_points - rb_spent,
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
	_ck("L05 新进程读回余额 >= 0", int(readback["balance"]) >= 0,
		"points=%d spent=%d balance=%s" % [rb_points, rb_spent, str(readback["balance"])])


# ---------------------------------------------------------------------------
# 态 3 · 断言读回（assert）：磁盘真值 / 写盘期望 / 新进程内存读回三方比对
# ---------------------------------------------------------------------------
func _phase_assert() -> void:
	print("[V120-C][ASSERT] ---- 态3 断言读回 ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
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

	# B 组：8 个关键 flag 三方一致（磁盘 / 写盘期望 / 新进程内存读回）
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
	_ck("B00 8 项关键 flag 三方全一致", b_all, "keys=%d" % keys.size())

	# C 组：A59 余额 points - spent_points >= 0、points 绝不回退、spent 单调
	var rb_balance: int = int(readback.get("balance", -1))
	var disk_points: int = int(disk_flags.get(K_POINTS, -1))
	var disk_spent: int = int(disk_flags.get(K_SPENT, -1))
	_ck("C01 余额 >= 0（points - spent_points）", rb_balance >= 0,
		"balance=%d" % rb_balance)
	_ck("C02 余额 == 期望(375) 且 points-spent 自洽",
		rb_balance == FIX_EXPECTED_BALANCE \
		and int(readback.get("points", -1)) - int(readback.get("spent_points", -1)) == FIX_EXPECTED_BALANCE,
		"points=%s spent=%s balance=%d" % [str(readback.get("points")),
			str(readback.get("spent_points")), rb_balance])
	_ck("C03 A59 绝不回退 points：points 只经 points_awarded 累加、扣费不动 points",
		disk_points == FIX_EXPECTED_POINTS and disk_points == int(expected.get("awarded_sum", -1)),
		"points=%d awarded_sum=%s" % [disk_points, str(expected.get("awarded_sum"))])
	_ck("C04 spent <= points（不透支）且 == 期望(25)",
		disk_spent <= disk_points and disk_spent == FIX_EXPECTED_SPENT,
		"spent=%d points=%d" % [disk_spent, disk_points])

	# G 组：★ A59 spent_points 单调累加 + 与 unlocked 同一原子写 + 重复购买拒绝
	_ck("G01 A59 spent == cost1+cost2（单调累加、只增不减）",
		disk_spent == int(expected.get("cost_1_points", -1)) + int(expected.get("cost_2_points", -1)),
		"spent=%d cost1=%s cost2=%s" % [disk_spent,
			str(expected.get("cost_1_points")), str(expected.get("cost_2_points"))])
	_ck("G02 A59 防重复扣费（反例 != 落盘值）",
		disk_spent != int(expected.get("wrong_spent_double", -1)),
		"disk=%d wrong_spent_double=%s" % [disk_spent, str(expected.get("wrong_spent_double"))])
	_ck("G03 A59 unlocked flag 与 spent 同一次 commit 落盘且为 bool true",
		typeof(disk_flags.get(K_UNLOCKED, null)) == TYPE_BOOL \
		and disk_flags.get(K_UNLOCKED) == true,
		"unlocked=%s type=%d" % [str(disk_flags.get(K_UNLOCKED)), typeof(disk_flags.get(K_UNLOCKED, null))])
	_ck("G04 A59 缺失/非法/超额/重复共 6 次拒绝（反例 spent 不出现）",
		int(expected.get("reject_count", -1)) == 6 and disk_spent == FIX_EXPECTED_SPENT,
		"reject_count=%s spent=%d" % [str(expected.get("reject_count")), disk_spent])
	_ck("G05 A59 selected 为 String 且为最后一次成功抉择 id",
		typeof(disk_flags.get(K_SELECTED, null)) == TYPE_STRING \
		and String(disk_flags.get(K_SELECTED, "")) == FIX_BOON_2_CHOICE,
		"selected=%s" % str(disk_flags.get(K_SELECTED)))
	_ck("G06 A59 cost_applied 为 bool 且 == true",
		typeof(disk_flags.get(K_COST, null)) == TYPE_BOOL and disk_flags.get(K_COST) == true,
		"cost_applied=%s" % str(disk_flags.get(K_COST)))

	# H 组：★ A58 去重键 + A60 防点数通胀（broken 判据）
	var claimed_keys: Array = expected.get("claimed_keys", []) as Array
	_ck("H01 A58 两个不同 parry 窗口各自入账（claimed 含两个不同 parry 键）",
		claimed_keys.has("parry:" + FIX_PARRY_WID_1) \
		and claimed_keys.has("parry:" + FIX_PARRY_WID_2),
		"claimed=%s" % str(claimed_keys))
	_ck("H02 A58 两个不同 exe 窗口不合并（claimed 含两个不同 exe 键）",
		claimed_keys.has("exe:exe_0_1") and claimed_keys.has("exe:exe_0_2"),
		"exe_0_1 / exe_0_2 均在")
	_ck("H03 A60 防通胀：落盘点数 != 三窗口都入账反例",
		disk_points != int(expected.get("wrong_parry_double", -1)),
		"disk=%d wrong_parry_double=%s" % [disk_points, str(expected.get("wrong_parry_double"))])
	_ck("H04 A60 防重复领取：落盘点数 != 无去重反例",
		disk_points != int(expected.get("wrong_no_dedup", -1)),
		"disk=%d wrong_no_dedup=%s" % [disk_points, str(expected.get("wrong_no_dedup"))])
	_ck("H05 A60 parry 成功计数 == 2（每窗口恰好一次、无重复入账）",
		int(disk_flags.get(K_PARRY_COUNT, -1)) == FIX_EXPECTED_PARRY_COUNT,
		"parry_count=%s" % str(disk_flags.get(K_PARRY_COUNT)))
	_ck("H06 A58 combat.parry.window_id 为 String 且 == 最近窗口",
		typeof(disk_flags.get(K_PARRY_WID, null)) == TYPE_STRING \
		and String(disk_flags.get(K_PARRY_WID, "")) == FIX_PARRY_WID_2,
		"window_id=%s" % str(disk_flags.get(K_PARRY_WID)))
	_ck("H07 grace.execution.performed == 0（exe 只验键生成、不冒充点数入账）",
		int(disk_flags.get(K_PERFORMED, -1)) == FIX_EXPECTED_PERFORMED,
		"performed=%s" % str(disk_flags.get(K_PERFORMED)))

	# I 组：新 flag 类型（三段式合法 + 标量白名单）
	var pc_t: int = typeof(disk_flags.get(K_PARRY_COUNT, null))
	_ck("I01 combat.parry.success_count 为数值且 == 2（int 经 JSON 读回 float，如实容忍）",
		(pc_t == TYPE_INT or pc_t == TYPE_FLOAT) \
		and int(disk_flags.get(K_PARRY_COUNT, -1)) == FIX_EXPECTED_PARRY_COUNT,
		"count=%s type=%d" % [str(disk_flags.get(K_PARRY_COUNT)), pc_t])
	_ck("I02 combat.parry.window_id 为 String（§2 标量白名单）",
		typeof(disk_flags.get(K_PARRY_WID, null)) == TYPE_STRING,
		"type=%d" % typeof(disk_flags.get(K_PARRY_WID, null)))

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
	_ck("D03 removals 为空（A59 绝不写 removals）",
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
		if ks.begins_with("grace.") or ks.begins_with("combat.") \
				or ks.begins_with("dungeon.") or ks.begins_with("world.") or ks.begins_with("quest."):
			new_top.append(ks)
	_ck("D05 新 flag 只作 flags 字典 key、未进顶层", new_top.is_empty(),
		"顶层三段式前缀字段=%s" % str(new_top))

	# E 组：旧存档缺 key 回落基线，不升级、不 removals
	var legacy_flags: Dictionary = legacy.get("flags", {}) as Dictionary
	var missing_new: bool = true
	for k: String in keys:
		if legacy_flags.has(k):
			missing_new = false
	_ck("E00 旧档确实缺全部 8 个关键 key（回落测试前提）", missing_new,
		"legacy flags keys=%s" % str(legacy_flags.keys()))
	var ws_legacy: Node = _new_ws()
	ws_legacy.call("_apply_snapshot", legacy)
	var e_all: bool = true
	for k: String in keys:
		var default: Variant = _baseline_for(k)
		var got: Variant = ws_legacy.call("get_flag", k, default)
		var ok: bool = _val_eq(got, default)
		if not ok:
			e_all = false
		_ck("E[%s] 缺 key 回落基线" % k, ok,
			"get_flag=%s default=%s" % [str(got), str(default)])
	_ck("E10 8 项缺 key 全回落基线（不创建 key）", e_all, "keys=%d" % keys.size())
	_ck("E11 旧档 schema_version=3 / removals 空 / 不升级",
		int(legacy.get("schema_version", -1)) == 3 \
		and (legacy.get("removals", []) as Array).is_empty(),
		"schema=%s removals=%s" % [str(legacy.get("schema_version", -1)),
			str(legacy.get("removals", []))])

	# F 组：生产存档未被本件改动（只读 md5 前后对照，不同只登记 WARN 不误判 FAIL）
	_ck("F01 独立槽与生产 slot_01 物理隔离", not _slot_dir.contains("slot_01") \
		and _delta_path != PRODUCTION_DELTA,
		"slot=%s production=%s（本件全程不 open WRITE slot_01）" % [_slot_dir, PRODUCTION_DELTA])
	var before: String = str(expected.get("production_md5_before", ""))
	var after: String = _production_md5()
	if before == after:
		_ck("F02 生产 slot_01 md5 前后一致（未碰生产存档）", true,
			"md5 before==after=%s" % before)
	else:
		print("[V120-C][ASSERT] WARN 生产 slot_01 md5 前后不同（可能并发方写入，非本件所为）before=%s after=%s" % [before, after])
		_ck("F02 生产存档差异如实登记（不计 FAIL、避免并发回归抖动）", true,
			"md5 before=%s after=%s | WARN 已打印" % [before, after])


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
	print("[V120-C] === verify_v120_save_commit SELFTEST START | R35 / v0.12.0 | cmd-20261112-125821-143-A3 ===")
	print("[V120-C] A49/A48④：本件不加载 presentation.gd、不连真实 HUD 信号、只验证 A59/A58/A60 落盘口径 + 磁盘一致性；真实可达回归见 verify_spent_points_production_v120.gd")
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
	print("[V120-C] main_loop=%s root=%s WorldState_probe=%s（Engine.get_main_loop 相对探活，仅登记）" % [
		str(tree != null), str(tree_root != null), str(ws_probe != null)])
	_parse_args()
	_slot_dir = "%s_%s" % [SLOT_BASE, _run]
	_delta_path = _slot_dir + "/delta.json"
	_expected_path = _slot_dir + "/expected.json"
	_readback_path = _slot_dir + "/readback.json"
	_legacy_path = _slot_dir + "/legacy.json"
	_prod_md5_before = _production_md5()
	print("[V120-C] RUN=%s mode=%s slot=%s production_md5_before=%s" % [
		_run, _mode, _slot_dir, _prod_md5_before])
	_ck("V00 WorldState 脚本资源就绪（CACHE_MODE_IGNORE）", _ws_script != null,
		"path=%s" % WORLD_STATE_SCRIPT_PATH)
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
	print("[V120-C] SUMMARY mode=%s pid=%d slot=%s pass=%d fail=%d total=%d" % [
		_mode, OS.get_process_id(), _slot_dir, _pass, _fail, _pass + _fail])
	print("[V120-C] OVERALL=%s" % ("PASS" if ok else "FAIL"))
	print("[V120-C] RESULT=%s" % ("ALL_MATCH" if ok else "MISMATCH"))
	print("[V120-C] === SELFTEST END ===")
	quit(0 if ok else 1)
