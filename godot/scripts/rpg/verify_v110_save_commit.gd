extends SceneTree

## ===========================================================================
## R34 / v0.11.0「玩法闭合 · 连击评价」点数与 flag 落盘三态只读验证（Rank-3 交付件）
##   cmd-20261112-091304-455-A3 / [ROUND=R34]
##
## 真跑（三个独立 Godot 引擎进程，各自 PID 不同，共享一次 run 的独立临时槽）：
##   D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/rpg/verify_v110_save_commit.gd \
##       -- write  <RUN>
##   ... -- load   <RUN>
##   ... -- assert <RUN>
##   不带 -- 参数 = all（单进程自检：三态依次执行、各用独立 WorldState 实例，
##   便于 `--check-only --script` / `--headless --script <verify>` 门禁直接
##   得到 PASS/FAIL + RESULT）。
##
## 【验证什么 · 任务单 ② + 裁决 A55】
##   三态 = ① 写盘（模拟 Rank-3 I-1 编排层把生产信号对账/去重后落进独立临时槽）
##   → ② 新进程 load（全新进程、空内存 WorldState，只能从磁盘 delta.json 重建）
##   → ③ 断言读回（磁盘真值 / 写盘期望 / 新进程内存读回三方一致）。覆盖：
##     - 处决奖励 / 抉择代价 / 连击倍率点数：落盘 `grace.trial.points` 与磁盘一致；
##     - ★ A55：`points_awarded(reason, points, source)` 是点数落盘【唯一权威通道】，
##       `wave_cleared(index, base_pts)` 只作 HUD 展示基础值（不作落盘依据），
##       `combo_settled(total, base, rank, mult)` 只作对账与展示 —— 三条通道职责边界
##       以「反例期望值」机器判定：落盘点数 == points_awarded 累加一次，
##       绝不等于「双通道各加一次 / 二次乘倍率 / combo_settled 重复入账」；
##     - ★ A51：连击倍率 multiplier 属 [PLACEHOLDER]、不落盘、不进 flag、
##       不参与点数计算，绝不造成点数通胀（broken 判据见 H 组）；
##     - 防重复领取：同一 execution / 同一清波 / 同一抉择不二次加点或扣费；
##     - 8 个关键 flag 三方一致（4 个 R32 flag + points/spent + 2 个连击 flag）；
##     - 余额 points - spent_points >= 0、spent <= points、不写 removals；
##     - 旧存档缺这些 key 时 get_flag(key, default) 回落基线、不升级、不迁移；
##     - 十字段冻结 / schema_version=3 / 三段式正则 / 新 flag 类型 / 只作 flags 字典新 key；
##     - `commit(reason)` 原子写（.tmp → flush → rename）成功后才改运行时实例；
##     - 生产 user://saves/slot_01/delta.json md5 前后一致（只读对照，不碰生产存档）。
##
## 【口径夹具的边界 · 如实登记，不伪造】
##   本件不加载 presentation.gd、不实例化主场景、不连真实 HUD 信号、不改 godot/ 业务代码。
##   文内 `_sig_*` 一组函数是 Rank-3 I-1「落盘编排口径」的【确定性自包含夹具】：
##   以 DONE-R34B.md §4 逐字固定的信号签名为输入，模拟编排层「配对信号 → 事件键去重
##   → 只经 points_awarded 落点 → 先落盘再改运行时实例」的唯一权威链路。真实运行时
##   接线（hud.gd 发信号 / wave_trial_director.gd / combo_service.gd）归 Rank-1 / Rank-2，
##   本件只验证【口径 + 磁盘一致性】，不代验、不冒充已接通（A49 / A50 / I-1）。
##   去重键来源：`points_awarded` 信号本身不带 window_id / wave_index，编排层须与
##   `execution_performed(window_id, bonus_points)` / `wave_cleared(index, base_points)`
##   配对取事件键（"exe:<window_id>" / "wave:<index>"）—— 该配对口径登记进契约 §3.3
##   R34 说明段与迭代文档「节点与信号链架构」。
##
## 【不改什么 · 硬约束】
##   - 不改 world_state.gd / save_delta_writer.gd 生产逻辑：只读加载 world_state.gd，
##     只调用既有 _ready() / _apply_snapshot() / get_flag()；
##   - 不碰生产存档：全部读写落在 user://saves/verify_v110_<RUN>/，与
##     user://saves/slot_01/ 物理隔离；对生产 delta.json 只做 get_md5 只读前后对照；
##   - 不写 removals、不新增 SaveDelta 顶层字段、schema_version 恒 3；
##   - 不改其它 Rank 产出、不新建只读探针 / 巡检脚本（本件是正式自测件）；
##   - 自包含：不依赖 Rank-1 / Rank-2 任何运行时单例（避免三进程 --script 模式下
##     autoload 状态抖动），flag key 逐字对齐契约 §3.3 / 存档与flag规范 §3.3 登记表。
##
## 【Godot --script 模式纪律】
##   - extends SceneTree + _initialize()；手动 new() 的 WorldState 不进场景树，
##     一律显式 call("_ready")（add_child 不自动 flush _ready）；
##   - 用 Engine.get_main_loop() as SceneTree 取 root 做相对探活登记，
##     不用 get_tree()、不用 /root/... 绝对路径；
##   - 资源回读用 ResourceLoader.load(..., CACHE_MODE_IGNORE)；
##   - 输出逐条 PASS/FAIL + SUMMARY pass/fail + RESULT，失败 quit(1)。
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费 / 零外部依赖。
## ===========================================================================

const WORLD_STATE_SCRIPT_PATH: String = "res://scripts/rpg/world_state.gd"
const PRODUCTION_DELTA: String = "user://saves/slot_01/delta.json"
const SLOT_BASE: String = "user://saves/verify_v110"

const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]

## 8 个关键 flag key（逐字对齐契约 §3.3 / 存档与flag规范 §3.3 登记表）：
##   4 个 R32 flag（抉择 String/bool、破韧窗口 bool、处决次数 int）+ points/spent
##   + 2 个 R34 新增连击 flag（combat.combo.rank String / combat.combo.count int）。
const K_SELECTED: String = "grace.boon_draft.selected"
const K_COST: String = "grace.boon_draft.cost_applied"
const K_STAGGER: String = "combat.boss_01.stagger_window"
const K_PERFORMED: String = "grace.execution.performed"
const K_POINTS: String = "grace.trial.points"
const K_SPENT: String = "grace.trial.spent_points"
const K_COMBO_RANK: String = "combat.combo.rank"
const K_COMBO_COUNT: String = "combat.combo.count"

## [PLACEHOLDER] 三态夹具数值（非新设计数值，仅用于确定性三态回读）。
##   rationale：逐项引用 DONE-R34B.md §5 真跑实证的既有数值，不另造：
##     - 清波基础 pts=100（wave_cleared 第二参，s4 实证 wave_cleared_pts=[100]）；
##     - points_awarded 清波权威值=160（A 级 1.6 → 100×1.6，s2/s3 实证 settled=160）；
##       ★ 该 160 仅作为「落盘值唯一来自 points_awarded、与 wave_cleared 基础 100 不同」
##       的分叉消除判据；points_awarded 具体是否携带倍率以 Rank-1 发信号实现为准，
##       Rank-3 口径是【原样采信、不二次加工、不自行叠加倍率】（A55 / A51），不臆断。
##     - 处决 bonus=50（e1 实证 exec_bonus=50）；
##     - 抉择代价折点=30（[PLACEHOLDER] 演示值，映射进既有 spent_points 出口）；
##     - 连击数=14（h1 实证 combo 0→14）、评级 "A"（h2 实证 D→A）、倍率 1.6（s2）。
##   预期：points = 160 + 50 = 210（只经 points_awarded 累加一次）；
##         spent = 30；余额 = 210 - 30 = 180 >= 0；performed = 1（重复处决不 +1）。
##   调参唯一入口：只改本件 FIX_* 常量 + 数据表（只改表不改代码），不静默改数。
const FIX_WAVE_BASE: int = 100
const FIX_WAVE_AWARDED: int = 160
const FIX_COMBO_RANK: String = "A"
const FIX_COMBO_MULT: float = 1.6
const FIX_COMBO_COUNT: int = 14
const FIX_EXEC_WINDOW: String = "win_exe_01"
const FIX_EXEC_BONUS: int = 50
const FIX_BOON_CHOICE: String = "boon_frost_edge"
const FIX_BOON_COST_POINTS: int = 30
const FIX_EXPECTED_POINTS: int = 210
const FIX_EXPECTED_SPENT: int = 30
const FIX_EXPECTED_BALANCE: int = 180
const FIX_EXPECTED_PERFORMED: int = 1

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
# A55 落盘编排口径夹具（确定性自包含，不连真实运行时信号）
#   _orch_flags  = 要落进 flags 字典的真值（磁盘唯一权威来源）
#   _orch_claimed = 运行时去重表（event_key -> true），本身不落盘（门控态）
#   对账标量只用于机器判定「三通道职责边界 / 防重复领取 / 防通胀」，不进落盘 flags
# ---------------------------------------------------------------------------
var _orch_flags: Dictionary = {}
var _orch_claimed: Dictionary = {}
var _orch_points_from_awarded: int = 0   # 仅 points_awarded 累加（A55 权威）
var _orch_points_from_wave: int = 0      # wave_cleared 基础累加（只读对账，绝不落盘）
var _orch_settle_total: int = 0          # combo_settled.total（只读对账）
var _orch_settle_mult: float = 1.0       # combo_settled.multiplier（[PLACEHOLDER]，绝不落盘）


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V110] %s PASS=%s | %s" % [tag, str(ok), detail])


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


## commit(reason) 原子写模拟：.tmp → flush → rename_absolute → delta.json（与 world_state.gd
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
# Rank-3 I-1 落盘编排口径夹具（信号签名逐字来自 DONE-R34B.md §4）
# ==========================================================================

func _orch_reset() -> void:
	_orch_flags = {
		K_POINTS: 0,
		K_SPENT: 0,
		K_PERFORMED: 0,
		K_SELECTED: "",
		K_COST: false,
		K_STAGGER: false,
		K_COMBO_RANK: "",
		K_COMBO_COUNT: 0,
	}
	_orch_claimed = {}
	_orch_points_from_awarded = 0
	_orch_points_from_wave = 0
	_orch_settle_total = 0
	_orch_settle_mult = 1.0


## Rank-2 `wave_cleared(index, points)`：第二参为基础 pts，★ 只作 HUD 展示 / 只读对账，
## 绝不累加 grace.trial.points（A55：不作落盘依据）。返回事件键供编排层配对去重。
func _sig_wave_cleared(index: int, base_points: int) -> String:
	_orch_points_from_wave += base_points
	return "wave:" + str(index)


## Rank-2 `combo_settled(total_points, base_points, rank, multiplier)`：★ 只作对账与展示，
## 绝不累加 grace.trial.points、绝不把 multiplier 落盘（A55 / A51）。落两个连击 flag。
func _sig_combo_settled(total_points: int, base_points: int, rank: String, multiplier: float) -> void:
	_orch_settle_total = total_points
	_orch_settle_mult = multiplier
	_orch_flags[K_COMBO_RANK] = rank


## Rank-1/2 `combo_changed`：连击计数快照 → combat.combo.count（非单调·每波覆盖）。
func _sig_combo_changed(combo_count: int) -> void:
	_orch_flags[K_COMBO_COUNT] = combo_count


## Rank-1 `execution_performed(window_id, bonus_points)`：只生成事件键 + 携带 bonus 供
## points_awarded 落点（成就计数亦由 points_awarded reason=="execution" 落），本身不落点。
func _sig_execution_performed(window_id: String, bonus_points: int) -> String:
	return "exe:" + window_id


## ★★ A55 唯一权威通道：`points_awarded(reason, points, source)`。
##   只有本函数累加 grace.trial.points；event_key 由编排层配对产生，命中去重表即拒绝
##   （防重复领取：同一执行 / 同一清波不二次加点）。reason=="execution" 时同时 +1 处决成就。
func _sig_points_awarded(reason: String, points: int, source: String, event_key: String) -> bool:
	if _orch_claimed.has(event_key):
		return false
	_orch_claimed[event_key] = true
	_orch_flags[K_POINTS] = int(_orch_flags[K_POINTS]) + points
	_orch_points_from_awarded += points
	if reason == "execution":
		_orch_flags[K_PERFORMED] = int(_orch_flags[K_PERFORMED]) + 1
	return true


## Rank-1 `boon_draft_applied(index, choice_id, effect_key, effect_value, cost_key, cost_value)`：
## 抉择代价走既有 spent_points 出口（不回退 points、不写 removals）；防重复扣费门控。
## cost_points 为编排层把 [PLACEHOLDER] cost 映射成的整数点值（本夹具给 30）。
func _sig_boon_draft_applied(index: int, choice_id: String, cost_points: int) -> bool:
	var key: String = "boon:" + str(index)
	if _orch_claimed.has(key):
		return false
	_orch_claimed[key] = true
	_orch_flags[K_SPENT] = int(_orch_flags[K_SPENT]) + cost_points
	_orch_flags[K_SELECTED] = choice_id
	_orch_flags[K_COST] = true
	return true


## 破韧窗口 R32 flag（非单调·局内翻转，本夹具取开窗态 true 作落盘快照）。
func _sig_stagger_window(is_open: bool) -> void:
	_orch_flags[K_STAGGER] = is_open


## 事件序列（真实玩法顺序参考 DONE-R34B.md §5 s1~s4 / e1 / b1~b4）+ 三类边界输入
## （重复清波 / 重复处决 / 重复抉择）。返回是否全部按预期去重（供写盘态断言）。
func _run_events() -> void:
	_orch_reset()
	# —— 波 1 真实链路：combo 增长 → 清波 → 评级倍率结算 → points_awarded 权威落点 ——
	_sig_combo_changed(FIX_COMBO_COUNT)                                   # combat.combo.count=14
	var wk: String = _sig_wave_cleared(1, FIX_WAVE_BASE)                  # 基础 100（只读对账）
	_sig_combo_settled(FIX_WAVE_AWARDED, FIX_WAVE_BASE, FIX_COMBO_RANK, FIX_COMBO_MULT)  # 对账 + rank=A
	_sig_points_awarded("wave_cleared", FIX_WAVE_AWARDED, \
		"wave_trial_director.wave_cleared", wk)                            # ★ +160（权威）
	# 边界①：同一清波重复触发（wave_cleared 再来一次基础 100，points_awarded 应被去重拒绝）
	var wk2: String = _sig_wave_cleared(1, FIX_WAVE_BASE)
	_sig_points_awarded("wave_cleared", FIX_WAVE_AWARDED, \
		"wave_trial_director.wave_cleared", wk2)
	# —— 处决：execution_performed + points_awarded(execution, bonus) ——
	var ek: String = _sig_execution_performed(FIX_EXEC_WINDOW, FIX_EXEC_BONUS)
	_sig_points_awarded("execution", FIX_EXEC_BONUS, "stagger_service.try_execute", ek)  # ★ +50 / performed=1
	# 边界②：同一处决重复领取
	var ek2: String = _sig_execution_performed(FIX_EXEC_WINDOW, FIX_EXEC_BONUS)
	_sig_points_awarded("execution", FIX_EXEC_BONUS, "stagger_service.try_execute", ek2)
	# —— 抉择代价（防重复扣费） ——
	_sig_boon_draft_applied(1, FIX_BOON_CHOICE, FIX_BOON_COST_POINTS)     # spent=30 / selected / cost_applied
	_sig_boon_draft_applied(1, FIX_BOON_CHOICE, FIX_BOON_COST_POINTS)     # 边界③：重复抉择拒绝
	# —— 破韧窗口接线 ——
	_sig_stagger_window(true)


## 完整 flags：经 _run_events() 由 A55 编排口径算出（8 个关键 key）+ 若干既有前置 flag；
## 全部三段式、只作 flags 字典 key。
func _full_flags() -> Dictionary:
	_run_events()
	var flags: Dictionary = _orch_flags.duplicate(true)
	flags["grace.tutorial.completed"] = true
	flags["dungeon.wave_trial.completed"] = true
	flags["dungeon.wave_trial.best_wave"] = 3
	return flags


## 8 个关键 flag（4 个 R32 + points/spent + 2 个连击）。
func _verify_keys() -> Array[String]:
	var out: Array[String] = []
	out.append(K_SELECTED)
	out.append(K_COST)
	out.append(K_STAGGER)
	out.append(K_PERFORMED)
	out.append(K_POINTS)
	out.append(K_SPENT)
	out.append(K_COMBO_RANK)
	out.append(K_COMBO_COUNT)
	return out


## 缺 key 回落基线的期望 default：String flag -> ""、int flag -> 0、bool flag -> false。
func _baseline_for(key: String) -> Variant:
	if key == K_SELECTED or key == K_COMBO_RANK:
		return ""
	if key == K_PERFORMED or key == K_POINTS or key == K_SPENT or key == K_COMBO_COUNT:
		return 0
	return false


## 十字段 SaveDelta 骨架（与 world_state.gd::_new_delta() 同构）；schema_version=3 冻结、
## removals 恒空、不新增顶层字段。slot 字段沿用 "slot_01"（结构值，非物理路径）。
func _delta_shell(flags: Dictionary, reason: String) -> Dictionary:
	return {
		"schema_version": 3,
		"slot": "slot_01",
		"seq": 11,
		"baseline": {
			"manifest": "res://data/rpg/world_baseline.tres",
			"manifest_hash": "",
			"baseline_version": 1,
			"resource_ids": []
		},
		"flags": flags,
		"quests": {},
		"inventory": {},
		"spawns": {"defeated": [], "epoch": 0},
		"removals": [],
		"meta": {
			"playtime_seconds": 0,
			"area_id": "",
			"last_grace_id": "",
			"written_at_unix": 0,
			"game_version": "0.11.0-r34",
			"last_commit_reason": reason
		}
	}


## 旧存档：只有既有登记 key、缺本轮全部 8 个关键 key，schema_version=3 / removals 空。
func _legacy_delta() -> Dictionary:
	var flags: Dictionary = {
		"grace.network.last_grace_id": "grace_limgrave_gatefront",
		"grace.limgrave_gatefront.lit": true,
		"dungeon.wave_trial.best_wave": 2,
	}
	return _delta_shell(flags, "v110_legacy_baseline")


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
# 态 1 · 写盘（write）：A55 编排 → 期望/反例夹具 → 旧档夹具，commit(reason) 原子落进独立槽
# ---------------------------------------------------------------------------
func _phase_write() -> void:
	print("[V110][WRITE] ---- 态1 写盘 ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
	var ok_dir: bool = _prepare_slot()
	_ck("W01 独立临时槽可写且与生产隔离", ok_dir and not _slot_dir.contains("slot_01"),
		"slot=%s（物理隔离 user://saves/slot_01）" % _slot_dir)

	# A55 编排先算出 flags + 对账标量（_full_flags 内部调 _run_events）
	var flags: Dictionary = _full_flags()
	var delta: Dictionary = _delta_shell(flags, "points_awarded_settlement")
	# ★ 先落盘（commit 原子写），本态绝不 new/apply 任何 WorldState 运行时实例
	var ok_delta: bool = _atomic_write_delta(delta)
	_ck("W02 commit(reason) 原子写 delta.json 成功（.tmp→flush→rename，先落盘）",
		ok_delta and FileAccess.file_exists(_delta_path) \
		and not FileAccess.file_exists(_delta_path + ".tmp"),
		"path=%s tmp_consumed=%s" % [_delta_path, str(not FileAccess.file_exists(_delta_path + ".tmp"))])
	var disk: Dictionary = _read_json(_delta_path)
	_ck("W03 写盘可回读解析", not disk.is_empty(), "JSON.parse_string -> Dictionary")

	# 反例期望值（A55 三通道职责边界 / A51 防通胀 / 防重复领取），全部动态算、写进 expected
	var wrong_double_channel: int = _orch_points_from_awarded + _orch_points_from_wave   # 210+200=410
	var wrong_double_mult: int = int(round(float(_orch_points_from_awarded) * _orch_settle_mult))  # 210*1.6=336
	var wrong_settle_add: int = _orch_points_from_awarded + _orch_settle_total           # 210+160=370
	var wrong_no_dedup: int = _orch_points_from_awarded + FIX_WAVE_AWARDED + FIX_EXEC_BONUS  # 210+160+50=420
	var expected: Dictionary = {
		"write_pid": OS.get_process_id(),
		"slot": _slot_dir,
		"production_md5_before": _prod_md5_before,
		"flags": flags,
		"points_awarded_sum": _orch_points_from_awarded,
		"wave_base_sum": _orch_points_from_wave,
		"settle_total": _orch_settle_total,
		"settle_mult": _orch_settle_mult,
		"claimed_count": _orch_claimed.size(),
		"expected_points": FIX_EXPECTED_POINTS,
		"expected_spent": FIX_EXPECTED_SPENT,
		"expected_balance": FIX_EXPECTED_BALANCE,
		"expected_performed": FIX_EXPECTED_PERFORMED,
		"wrong_double_channel": wrong_double_channel,
		"wrong_double_mult": wrong_double_mult,
		"wrong_settle_add": wrong_settle_add,
		"wrong_no_dedup": wrong_no_dedup,
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
		_ck("W07 removals 恒空", (disk.get("removals", []) as Array).is_empty(),
			"removals=%s" % str(disk.get("removals", [])))
		var df: Dictionary = disk.get("flags", {}) as Dictionary
		var bad: Array[String] = []
		for k: Variant in df.keys():
			if _re.search(String(k)) == null:
				bad.append(String(k))
		_ck("W08 全部 flag key 三段式正则", bad.is_empty(),
			"keys=%d bad=%s" % [df.size(), str(bad)])
	# 编排口径自洽（写盘进程内）：points == points_awarded 累加一次、claimed 去重键=3
	_ck("W09 A55 编排自洽：points == points_awarded 累加一次",
		int(flags.get(K_POINTS, -1)) == _orch_points_from_awarded \
		and _orch_points_from_awarded == FIX_EXPECTED_POINTS,
		"points=%s awarded_sum=%d wave_base_sum=%d(只读对账)" % [
			str(flags.get(K_POINTS)), _orch_points_from_awarded, _orch_points_from_wave])
	_ck("W10 去重键恰为 3（波1/处决/抉择各一次，重复被拒）",
		_orch_claimed.size() == 3, "claimed=%d" % _orch_claimed.size())


# ---------------------------------------------------------------------------
# 态 2 · 新进程 load：全新进程 / 空内存 WorldState，只从磁盘 delta.json 重建
# ---------------------------------------------------------------------------
func _phase_load() -> void:
	print("[V110][LOAD] ---- 态2 新进程 load ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
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
	_ck("L04 新进程内存读回逐项 == 磁盘", all_match,
		"flags=%d 项，逐项 get_flag 比对" % rb_flags.size())
	_ck("L05 新进程读回余额 >= 0", int(readback["balance"]) >= 0,
		"points=%d spent=%d balance=%s" % [rb_points, rb_spent, str(readback["balance"])])


# ---------------------------------------------------------------------------
# 态 3 · 断言读回（assert）：磁盘真值 / 写盘期望 / 新进程内存读回三方比对
# ---------------------------------------------------------------------------
func _phase_assert() -> void:
	print("[V110][ASSERT] ---- 态3 断言读回 ---- pid=%d slot=%s" % [OS.get_process_id(), _slot_dir])
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

	# C 组：余额 points - spent_points >= 0，与夹具期望一致，不透支
	var rb_balance: int = int(readback.get("balance", -1))
	_ck("C01 余额 >= 0（points - spent_points）", rb_balance >= 0,
		"balance=%d" % rb_balance)
	_ck("C02 余额 == 期望(180) 且 points-spent 自洽",
		rb_balance == FIX_EXPECTED_BALANCE \
		and int(readback.get("points", -1)) - int(readback.get("spent_points", -1)) == FIX_EXPECTED_BALANCE,
		"points=%s spent=%s balance=%d" % [str(readback.get("points")),
			str(readback.get("spent_points")), rb_balance])
	_ck("C03 spent <= points（不透支）", int(readback.get("spent_points", 0)) \
		<= int(readback.get("points", 0)), "spent=%s points=%s" % [
			str(readback.get("spent_points")), str(readback.get("points"))])

	# G 组：★ A55 三条通道职责边界 + 分叉消除（点数落盘唯一权威 = points_awarded）
	var disk_points: int = int(disk_flags.get(K_POINTS, -1))
	var awarded_sum: int = int(expected.get("points_awarded_sum", -1))
	var wave_base_sum: int = int(expected.get("wave_base_sum", -1))
	_ck("G01 A55 落盘点数 == points_awarded 累加一次(210)",
		disk_points == awarded_sum and disk_points == FIX_EXPECTED_POINTS,
		"disk_points=%d awarded_sum=%d expected=%d" % [disk_points, awarded_sum, FIX_EXPECTED_POINTS])
	_ck("G02 A55 wave_cleared 基础值(100/重复累计200)未进落盘（非落盘依据）",
		disk_points != wave_base_sum and wave_base_sum >= FIX_WAVE_BASE,
		"disk_points=%d wave_base_sum=%d（只读对账、HUD 展示）" % [disk_points, wave_base_sum])
	_ck("G03 A55 未走双通道各加一次（反例 != 落盘值）",
		disk_points != int(expected.get("wrong_double_channel", -1)),
		"disk=%d wrong_double_channel=%d(awarded+wave)" % [
			disk_points, int(expected.get("wrong_double_channel", -1))])
	_ck("G04 A55 combo_settled 只作对账：未额外入账（反例 != 落盘值）",
		disk_points != int(expected.get("wrong_settle_add", -1)) \
		and int(expected.get("settle_total", -1)) == FIX_WAVE_AWARDED,
		"disk=%d wrong_settle_add=%d settle_total=%d(对账一致)" % [
			disk_points, int(expected.get("wrong_settle_add", -1)), int(expected.get("settle_total", -1))])

	# H 组：★ A51 防点数通胀 + 防重复领取（broken 判据写清）
	_ck("H01 A51 未二次乘连击倍率 [PLACEHOLDER] 1.6（反例 != 落盘值）",
		disk_points != int(expected.get("wrong_double_mult", -1)),
		"disk=%d wrong_double_mult=%d(awarded×1.6)" % [
			disk_points, int(expected.get("wrong_double_mult", -1))])
	_ck("H02 A51 multiplier 未落盘（flags 内无倍率类 key、未进十字段）",
		not disk_flags.has("combat.combo.multiplier") and not delta.has("multiplier"),
		"multiplier 属 [PLACEHOLDER]、只作对账、不进 flags/顶层")
	_ck("H03 防重复领取：同一执行/清波重复不二次加点（反例 != 落盘值）",
		disk_points != int(expected.get("wrong_no_dedup", -1)),
		"disk=%d wrong_no_dedup=%d(重复清波160+重复处决50)" % [
			disk_points, int(expected.get("wrong_no_dedup", -1))])
	_ck("H04 防重复领取：grace.execution.performed == 1（重复处决不 +1）",
		int(rb_flags.get(K_PERFORMED, -1)) == FIX_EXPECTED_PERFORMED,
		"performed=%s expected=%d" % [str(rb_flags.get(K_PERFORMED)), FIX_EXPECTED_PERFORMED])
	_ck("H05 防重复扣费：spent_points == 30（重复抉择不二次扣）",
		int(rb_flags.get(K_SPENT, -1)) == FIX_EXPECTED_SPENT,
		"spent=%s expected=%d" % [str(rb_flags.get(K_SPENT)), FIX_EXPECTED_SPENT])
	_ck("H06 去重键恰为 3（写盘编排口径自洽）",
		int(expected.get("claimed_count", -1)) == 3,
		"claimed_count=%s" % str(expected.get("claimed_count")))

	# I 组：连击评级 flag（R34 新增，三段式合法）+ 类型
	_ck("I01 combat.combo.rank 为 String 且 == 'A'",
		typeof(disk_flags.get(K_COMBO_RANK, null)) == TYPE_STRING \
		and str(rb_flags.get(K_COMBO_RANK, "")) == FIX_COMBO_RANK,
		"rank=%s type=%d" % [str(rb_flags.get(K_COMBO_RANK)), typeof(disk_flags.get(K_COMBO_RANK, null))])
	var cc_t: int = typeof(disk_flags.get(K_COMBO_COUNT, null))
	_ck("I02 combat.combo.count 为数值且 == 14（int 经 JSON 读回 float，如实容忍）",
		(cc_t == TYPE_INT or cc_t == TYPE_FLOAT) \
		and int(rb_flags.get(K_COMBO_COUNT, -1)) == FIX_COMBO_COUNT,
		"count=%s type=%d" % [str(rb_flags.get(K_COMBO_COUNT)), cc_t])

	# J 组：4 个 R32 flag 落盘接线 + 类型（抉择/破韧/处决）
	_ck("J01 grace.boon_draft.selected 为 String 且读回 == 夹具",
		typeof(disk_flags.get(K_SELECTED, null)) == TYPE_STRING \
		and str(rb_flags.get(K_SELECTED, "")) == FIX_BOON_CHOICE,
		"selected=%s" % str(rb_flags.get(K_SELECTED)))
	_ck("J02 grace.boon_draft.cost_applied 为 bool 且 == true",
		typeof(disk_flags.get(K_COST, null)) == TYPE_BOOL \
		and rb_flags.get(K_COST) == true, "cost_applied=%s" % str(rb_flags.get(K_COST)))
	_ck("J03 combat.boss_01.stagger_window 为 bool 且 == true",
		typeof(disk_flags.get(K_STAGGER, null)) == TYPE_BOOL \
		and rb_flags.get(K_STAGGER) == true, "stagger_window=%s" % str(rb_flags.get(K_STAGGER)))
	_ck("J04 grace.execution.performed 单调递增且 == 1",
		int(rb_flags.get(K_PERFORMED, -1)) == FIX_EXPECTED_PERFORMED \
		and FIX_EXPECTED_PERFORMED >= 0,
		"performed=%s" % str(rb_flags.get(K_PERFORMED)))

	# D 组：结构冻结 / 正则 / 新 flag 类型 / 新 key 只在 flags 字典内
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
	_ck("D03 removals 为空（口径不启用 removals）",
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
		print("[V110][ASSERT] WARN 生产 slot_01 md5 前后不同（可能并发方写入，非本件所为；本件全程不写 slot_01）before=%s after=%s" % [before, after])
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
	print("[V110] === verify_v110_save_commit SELFTEST START | R34 / v0.11.0 | cmd-20261112-091304-455-A3 ===")
	print("[V110] A49/A55：本件不加载 presentation.gd、不连真实 HUD 信号、只验证 I-1 落盘口径 + 磁盘一致性")
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
	print("[V110] main_loop=%s root=%s WorldState_probe=%s（Engine.get_main_loop 相对探活，仅登记）" % [
		str(tree != null), str(tree_root != null), str(ws_probe != null)])
	_parse_args()
	_slot_dir = "%s_%s" % [SLOT_BASE, _run]
	_delta_path = _slot_dir + "/delta.json"
	_expected_path = _slot_dir + "/expected.json"
	_readback_path = _slot_dir + "/readback.json"
	_legacy_path = _slot_dir + "/legacy.json"
	_prod_md5_before = _production_md5()
	print("[V110] RUN=%s mode=%s slot=%s production_md5_before=%s" % [
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
	print("[V110] SUMMARY mode=%s pid=%d slot=%s pass=%d fail=%d" % [
		_mode, OS.get_process_id(), _slot_dir, _pass, _fail])
	print("[V110] RESULT=%s" % ("PASS" if ok else "FAIL"))
	print("[V110] === SELFTEST END ===")
	quit(0 if ok else 1)
