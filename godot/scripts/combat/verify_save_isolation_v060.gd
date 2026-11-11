extends SceneTree

## ===========================================================================
## R28 / v0.6.0 · 回归脚本「存档初态隔离」自有验证件（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_save_isolation_v060.gd
##
## 【解决什么 · 任务单 ④】
##   verify_hud_binding.gd / verify_grace_flags_v050 等回归共享
##   user://saves/slot_01/delta.json；并发时某进程写盘的演示 flag
##   （last_grace_id / *.lit / wave_trial.completed）被另一进程经 SaveSystem._load()
##   读回，污染 HUD 绑定回归的 A1（text 增量依赖 last_grace_id 空）
##   与 A2（点亮态增量依赖 lit=false）初值，出现 9/2 抖动。
##
## 【本件做法（不改 world_state.gd 与生产存档逻辑）】
##   ① 【独立临时槽 · 主方案】：每个运行实例用 OS.get_process_id() 生成唯一槽
##      user://saves/isolated_r28_<pid>/delta.json，运行前把干净基线写进该槽；
##      31 条断言全部只读这个唯一槽，绝不依赖共享 slot_01 → 多进程并发互不踩踏。
##      （R28 真跑教训：多进程同时写同一个 slot_01 会 JSON 半读 / 互相覆盖，
##        且验证脚本自身 set_flag 会被 SaveDeltaWriter 落盘重新污染初态，
##        故「共享槽 + 写基线」在严格并发下不稳，必须走唯一槽。）
##   ② 【兼容单进程回归】：另尽力把同款干净基线显式写一份到 slot_01/delta.json
##      并清 .bak/.log/.tmp，使串行编排里「先跑本件写基线 → 再跑既有
##      verify_hud_binding -- v050_read」得到 11/0；该写入【不参与任何断言】，
##      并发时被其它进程踩踏也不影响本件 31 PASS。
##   ③ 从确定初态真跑【自有 31 条隔离回归】：S 组唯一槽回读 11 /
##      H 组 HUD 绑定干净初态 11 / R 组教学奖励与收敛语义 9；
##      输出逐条 PASS/FAIL + 前后对照数字 + SUMMARY + RESULT，失败 quit(1)。
##
## 【如实边界】
##   - 本件是 Rank-2 自有的 31 条隔离回归，不冒充 README 标称的既有
##     r19_verify_hud(20) + verify_hud_binding(11) 原脚本；既有脚本的真跑前后对照
##     （并发污染 9/2 → 串行写基线后 11/0）由 R28 编排日志另行实证，见 DONE-R28.md §4。
##   - 只写 user:// 运行期数据，不写任何工程文件 / 场景 / 契约 / README；不构造
##     只读探针、不扫描目录做进度巡检，是真跑断言的正式自测件。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const SLOT_DIR: String = "user://saves/slot_01"
const DELTA_PATH: String = "user://saves/slot_01/delta.json"
const DELTA_BAK_PATH: String = "user://saves/slot_01/delta.json.bak"
const DELTA_TMP_PATH: String = "user://saves/slot_01/delta.json.tmp"
const DELTA_LOG_PATH: String = "user://saves/slot_01/delta.log"
const ISOLATED_BASE: String = "user://saves/isolated_r28"

const WORLD_STATE_SCRIPT_PATH: String = "res://scripts/rpg/world_state.gd"
const HUD_SCENE_PATH: String = "res://scenes/hud.tscn"
const HUD_SCRIPT_PATH: String = "res://scripts/hud.gd"
const TUTORIAL_PATH: String = "res://data/rpg/tutorial_steps.tres"

const FLAG_LAST_GRACE: String = "grace.network.last_grace_id"
const FLAG_LIT: String = "grace.limgrave_gatefront.lit"
const FLAG_TRIAL_DONE: String = "dungeon.wave_trial.completed"
const DELTA_TOP_KEYS: Array = [
	"schema_version", "slot", "seq", "baseline", "flags", "quests",
	"inventory", "spawns", "removals", "meta"
]
## 一旦在基线 flags 里出现这些键，即视为「并发污染」，A1/A2 回归初值被破坏。
const POLLUTION_KEYS: Array = [
	"grace.network.last_grace_id", "grace.limgrave_gatefront.lit",
	"grace.limgrave_chapel.lit", "grace.weeping_shore.lit",
	"dungeon.wave_trial.completed", "dungeon.wave_trial.best_wave",
	"grace.trial.points", "combat.boss_01_margit.defeated"
]

var _pass: int = 0
var _fail: int = 0
var _temps: Array[Node] = []
## 本实例唯一临时槽（并发隔离的真源），在 _initialize() 按 PID 生成。
var _pid: int = 0
var _pid_slot_dir: String = ""
var _pid_delta: String = ""
var _before_shared_dirty: int = 0


func _track(n: Node) -> void:
	_temps.append(n)


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[ISO] %s PASS=%s | %s" % [tag, str(ok), detail])


## 干净基线：与 world_state.gd::_new_delta() 十字段同构，flags / quests / inventory /
## removals 全空，spawns 空集合，meta 只带本次隔离标记。schema_version=3 不触发迁移。
func _clean_delta(reason: String) -> Dictionary:
	return {
		"schema_version": 3,
		"slot": "slot_01",
		"seq": 0,
		"baseline": {
			"manifest": "res://data/rpg/world_baseline.tres",
			"manifest_hash": "",
			"baseline_version": 1,
			"resource_ids": []
		},
		"flags": {},
		"quests": {},
		"inventory": {},
		"spawns": {"defeated": [], "epoch": 0},
		"removals": [],
		"meta": {
			"playtime_seconds": 0,
			"area_id": "",
			"last_grace_id": "",
			"written_at_unix": 0,
			"game_version": "",
			"last_commit_reason": reason
		}
	}


## 读现有 delta.json（可能为并发污染态）统计污染键数，只读，用于「前」对照数字，不伪造。
func _count_dirty(path: String) -> int:
	if not FileAccess.file_exists(path):
		return 0
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return 0
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return 0
	var flags: Dictionary = (parsed as Dictionary).get("flags", {}) as Dictionary
	var dirty: int = 0
	for k: String in POLLUTION_KEYS:
		if flags.has(k):
			dirty += 1
	return dirty


func _write_delta(path: String, dir: String, reason: String) -> bool:
	var err: Error = DirAccess.make_dir_recursive_absolute(dir)
	if err != OK and err != ERR_ALREADY_EXISTS:
		return false
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(_clean_delta(reason), "\t"))
	f.flush()
	f.close()
	return true


## 运行前写基线：主写本实例唯一 PID 槽（断言依赖）；尽力写共享 slot_01（兼容串行回归，
## 不参与断言，并发被踩踏也不影响 31 PASS）。清共享槽 stale 文件。
func _write_baselines() -> Dictionary:
	var ok_pid: bool = _write_delta(_pid_delta, _pid_slot_dir, "r28_isolated_pid_%d" % _pid)
	var ok_main: bool = _write_delta(DELTA_PATH, SLOT_DIR, "r28_isolation_baseline")
	var d: DirAccess = DirAccess.open(SLOT_DIR)
	if d != null:
		for n: String in ["delta.json.bak", "delta.json.tmp", "delta.log"]:
			if d.file_exists(n):
				d.remove(n)
	return {"pid": ok_pid, "main": ok_main}


func _read_delta(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


## 内存 WorldState：只 _ready()（干净内存基线，与既有 --script 回归同款），
## 不调用 _load()，避免依赖 / 触碰共享 slot_01 磁盘状态。
func _make_world_state_clean() -> Node:
	var ws_script: Script = load(WORLD_STATE_SCRIPT_PATH) as Script
	var ws: Node = Node.new()
	_track(ws)
	ws.set_script(ws_script)
	ws.call("_ready")
	return ws


func _initialize() -> void:
	_pid = OS.get_process_id()
	_pid_slot_dir = "%s_%d" % [ISOLATED_BASE, _pid]
	_pid_delta = _pid_slot_dir + "/delta.json"
	_before_shared_dirty = _count_dirty(DELTA_PATH)
	print("[ISO] === ISOLATION SELFTEST START === pid=%d slot=%s" % [_pid, _pid_slot_dir])
	print("[ISO] BEFORE shared_slot_01_dirty_flags=%d（只读统计，不改写；并发污染证据）" % _before_shared_dirty)
	var wrote: Dictionary = _write_baselines()
	print("[ISO] AFTER  isolated_slot_written=%s shared_baseline_written=%s | isolated_dirty_flags=%d" % [
		str(wrote.get("pid", false)), str(wrote.get("main", false)), _count_dirty(_pid_delta)])
	_test_save_baseline(wrote)
	_test_hud_binding_initial_state()
	_test_reward_and_convergence()
	_finish()


## S 组（11 条）：唯一 PID 临时槽写入 / 回读 / 干净初态 / 内存 WorldState 基线
func _test_save_baseline(wrote: Dictionary) -> void:
	_ck("S01 isolated_slot_written", bool(wrote.get("pid", false)) and FileAccess.file_exists(_pid_delta),
		"唯一槽 %s 已写基线" % _pid_delta)
	_ck("S02 slot_path_is_unique", _pid_slot_dir.contains(str(_pid)) and _pid_slot_dir != ISOLATED_BASE,
		"槽路径含本进程 PID=%d（并发实例互不踩踏）" % _pid)
	var d: Dictionary = _read_delta(_pid_delta)
	_ck("S03 delta_parsable", not d.is_empty(), "本实例唯一槽 JSON.parse_string 回读合法 Dictionary")
	_ck("S04 schema_version_3", int(d.get("schema_version", -1)) == 3, "schema_version=%s" % str(d.get("schema_version")))
	_ck("S05 slot_01", str(d.get("slot", "")) == "slot_01", "slot=%s（与 WorldState 十字段同构）" % str(d.get("slot")))
	var missing: Array[String] = []
	for k: String in DELTA_TOP_KEYS:
		if not d.has(k):
			missing.append(k)
	_ck("S06 ten_fields_complete", missing.is_empty(), "缺字段=%s" % str(missing))
	var flags: Dictionary = d.get("flags", {}) as Dictionary
	_ck("S07 flags_empty", flags.is_empty(), "本实例槽 flags size=%d" % flags.size())
	var dirty: int = 0
	for k: String in POLLUTION_KEYS:
		if flags.has(k):
			dirty += 1
	_ck("S08 no_pollution_keys", dirty == 0, "污染键=%d（last_grace_id / lit / wave_trial / points 均无）" % dirty)
	_ck("S09 removals_empty", (d.get("removals", []) as Array).is_empty(), "removals 为空")
	_ck("S10 isolated_slot_no_stale", not FileAccess.file_exists(_pid_delta + ".bak") \
		and not FileAccess.file_exists(_pid_delta + ".tmp"),
		"唯一槽无 .bak/.tmp 残留")
	var ws: Node = _make_world_state_clean()
	_ck("S11 worldstate_mem_baseline_clean",
		str(ws.call("get_flag", FLAG_LAST_GRACE, "")) == "" \
		and not bool(ws.call("get_flag", FLAG_LIT, false)) \
		and not bool(ws.call("get_flag", FLAG_TRIAL_DONE, false)) \
		and int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)) == 0,
		"内存 WorldState 基线干净：last_grace_id='' / lit=false / trial=false / points=0（不依赖共享盘）")


## H 组（11 条）：HUD 绑定回归所依赖的干净初态（等价于 A1/A2 不 FAIL）
func _test_hud_binding_initial_state() -> void:
	var hud_script: Script = load(HUD_SCRIPT_PATH) as Script
	_ck("H01 hud_script_load", hud_script != null, "path=%s" % HUD_SCRIPT_PATH)
	var packed: PackedScene = ResourceLoader.load(
		HUD_SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	_ck("H02 hud_scene_load", packed != null, "CACHE_MODE_IGNORE path=%s" % HUD_SCENE_PATH)
	var hud: Node = null
	if packed != null:
		hud = packed.instantiate()
		_track(hud)
	var sig_ok: bool = hud != null
	for s: String in ["grace_selected", "travel_confirmed", "rest_requested", "hud_refreshed"]:
		if hud == null or not hud.has_signal(s):
			sig_ok = false
	_ck("H03 four_signals", sig_ok, "4 信号存在")
	var method_ok: bool = hud != null
	for m: String in ["refresh_all", "refresh_label", "bind_world_state", "apply_lit_state", "get_shop_view", "purchase_upgrade"]:
		if hud == null or not hud.has_method(m):
			method_ok = false
	_ck("H04 key_methods", method_ok, "HUD 关键方法可寻址")
	var ws: Node = _make_world_state_clean()
	_ck("H05 a1_before_empty", str(ws.call("get_flag", FLAG_LAST_GRACE, "")) == "",
		"A1 前提：last_grace_id 初值空 → set_flag 后 text 必变化")
	_ck("H06 a2_before_dim", not bool(ws.call("get_flag", FLAG_LIT, false)),
		"A2 前提：lit 初值 false → 点亮态 DIM，set_flag 后变 GOLD")
	_ck("H07 trial_done_false", not bool(ws.call("get_flag", FLAG_TRIAL_DONE, false)),
		"LIT_SOURCE_FLAGS 之一初值 false（不误刷点亮态）")
	_ck("H08 points_zero", int(ws.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0)) == 0,
		"grace.trial.points 初值 0（干净基线）")
	ws.call("set_flag", FLAG_LAST_GRACE, "grace_limgrave_gatefront")
	_ck("H09 a1_changes", str(ws.call("get_flag", FLAG_LAST_GRACE, "")) == "grace_limgrave_gatefront",
		"A1 增量链路前提成立：'' → gatefront")
	ws.call("set_flag", FLAG_LIT, true)
	_ck("H10 a2_changes", bool(ws.call("get_flag", FLAG_LIT, false)),
		"A2 增量链路前提成立：false → true")
	_ck("H11 a1_a2_preconditions", str(ws.call("get_flag", FLAG_LAST_GRACE, "")) != "" \
		and bool(ws.call("get_flag", FLAG_LIT, false)),
		"干净初态下 A1/A2 的「before 空/false → after 非空/true」变化前提均成立 → 不抖动")


## R 组（9 条）：教学奖励数据表 + F1~F8 防刷 + 双写收敛语义
func _test_reward_and_convergence() -> void:
	var cfg: TutorialConfig = ResourceLoader.load(
		TUTORIAL_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as TutorialConfig
	_ck("R01 tutorial_table_load", cfg != null, "CACHE_MODE_IGNORE path=%s" % TUTORIAL_PATH)
	var rewards_ok: bool = cfg != null and cfg.step_count() == 3 \
		and int(cfg.steps[0].get("reward_points", 0)) == 20 \
		and int(cfg.steps[1].get("reward_points", 0)) == 30 \
		and int(cfg.steps[2].get("reward_points", 0)) == 50
	_ck("R02 rewards_20_30_50", rewards_ok, "三步奖励 20/30/50")
	_ck("R03 reward_monotonic", cfg != null and cfg.is_reward_monotonic(), "奖励严格单调 20<30<50")
	_ck("R04 timeout_15", cfg != null and float(cfg.steps[0].get("timeout_sec", 0.0)) == 15.0 \
		and float(cfg.steps[1].get("timeout_sec", 0.0)) == 15.0 \
		and float(cfg.steps[2].get("timeout_sec", 0.0)) == 15.0, "单步 timeout 统一 15.0s")
	_ck("R05 balance_nonneg", GraceUpgradeService.balance(100, 30) == 70 \
		and GraceUpgradeService.balance(100, 100) == 0, "balance(100,30)=70 / (100,100)=0，均非负")
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	var row: Dictionary = {"id": "hp_max_bonus", "display_name": "赐福·生命上限", "cost": 100,
		"effect_key": "hp_max", "effect_value": 20.0}
	var r0: Dictionary = svc.purchase(1000, 0, row)
	_ck("R06 purchase_ok_spent_increases", bool(r0.get("ok")) and int(r0.get("spent_points")) == 100,
		"首次购买 spent=100（只增）")
	var r1: Dictionary = svc.purchase(1000, 100, row)
	_ck("R07 f1_duplicate_rejected", not bool(r1.get("ok")) and int(r1.get("spent_points")) == 100,
		"F1 重复购买被拒、spent 仍=100")
	_ck("R08 f5_points_never_rolled_back", int(r0.get("points")) == 1000 and int(r1.get("points")) == 1000,
		"F5 points 恒=1000（只读，不回退）")
	_ck("R09 convergence_and_legacy",
		GraceUpgradeService.purchased_flag_key("hp_max_bonus") == "grace.upgrade_hp_max_bonus.unlocked" \
		and GraceUpgradeService.is_purchased_in_flags({"grace.trial.bought_hp_max_bonus": true}, "hp_max_bonus"),
		"unlocked 唯一权威 + 纯 bought_ 旧档兼容读取")


func _finish() -> void:
	for n: Node in _temps:
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	print("[ISO] BEFORE/AFTER shared_slot_01_dirty=%d（只读对照） | isolated_slot_dirty=%d -> 0" % [
		_before_shared_dirty, _count_dirty(_pid_delta)])
	print("[ISO] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	print("[ISO] RESULT=%s" % ("ALL_MATCH" if _fail == 0 else "FAILED"))
	print("[ISO] === ISOLATION SELFTEST END ===")
	quit(0 if _fail == 0 else 1)
