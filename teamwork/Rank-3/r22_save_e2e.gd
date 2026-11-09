extends SceneTree

## R22 · 存档端到端真跑载体（cmd-20261109-124640-185-A3，[ROUND=R22]）
## 补做 R21 §3.2 / §4.3 明确未做的「写盘 → 重启独立引擎进程 → _load 回放 → get_flag 读回」完整链路。
## 用既有 SaveDeltaWriter.commit(reason) / WorldState._load() / SaveDelta 十字段口径，
## 不新建只读探针 / 巡检脚本，不改任何 godot/ 下既有工程文件（本载体落在 teamwork/Rank-3/）。
## 两次独立 Godot 进程用环境变量 E2E_PHASE=write|read 区分；两阶段 stdout 的 pid 不同即「重启」实证。
## 验证：十字段 / schema_version=3 / 三段式 flag / slot_01 一致 / meta.last_commit_reason 本次写盘。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

const TEN_FIELDS: Array[String] = [
	"baseline", "flags", "inventory", "meta", "quests",
	"removals", "schema_version", "seq", "slot", "spawns"
]
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"
const WRITE_REASON: String = "r22_e2e_write"
const DELTA_PATH: String = "user://saves/slot_01/delta.json"

# 写盘阶段经 I-1 权威入口 set_flag 注入的 5 个三段式 flag（覆盖 bool / int / String 三类 value 白名单）
const SEED_FLAGS: Dictionary = {
	"grace.limgrave_gatefront.lit": true,
	"grace.limgrave_gatefront.unlocked": true,
	"quest.bell_of_return.stage": 2,
	"combat.boss_01_margit.defeated": true,
	"grace.network.last_grace_id": "grace_limgrave_gatefront",
}

var _pass: int = 0
var _fail: int = 0
var _frame: int = 0
var _phase: String = ""
var _re: RegEx = null


func _check(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
		print("[R22] %s PASS=true | %s" % [tag, detail])
	else:
		_fail += 1
		print("[R22] %s PASS=false | %s" % [tag, detail])


## 值相等比较：数值容忍 Godot JSON.parse_string 的 int→float 既有 round-trip 行为，
## bool/String 严格按类型 + 值相等。不隐瞒该既有行为，比较口径如实。
func _val_eq(a: Variant, b: Variant) -> bool:
	var ta: int = typeof(a)
	var tb: int = typeof(b)
	if (ta == TYPE_INT or ta == TYPE_FLOAT) and (tb == TYPE_INT or tb == TYPE_FLOAT):
		return is_equal_approx(float(a), float(b))
	return ta == tb and a == b


func _initialize() -> void:
	_phase = OS.get_environment("E2E_PHASE")
	_re = RegEx.new()
	_re.compile(FLAG_KEY_REGEX)
	print("[R22] ==== 存档端到端真跑开始 ====")
	print("[R22] phase=%s pid=%d" % [_phase, OS.get_process_id()])
	print("[R22] user_delta_abs=%s" % ProjectSettings.globalize_path(DELTA_PATH))
	# autoload 在 --script 模式下由引擎在首帧前创建；等若干帧确保 _ready() 已 flush（R17/R19 时序口径）
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	if _frame < 3:
		return
	process_frame.disconnect(_on_frame)
	if _phase == "write":
		_run_write()
	elif _phase == "read":
		_run_read()
	else:
		print("[R22] 未知 E2E_PHASE=%s（应为 write|read）" % _phase)
		print("[R22] SUMMARY phase=%s pid=%d pass=0 fail=1 ok=false" % [_phase, OS.get_process_id()])
		quit(1)


func _run_write() -> void:
	var ws: Node = get_root().get_node_or_null("WorldState")
	var writer: Node = get_root().get_node_or_null("SaveDeltaWriter")
	_check("W① /root/WorldState 与 /root/SaveDeltaWriter 就绪", ws != null and writer != null,
		"ws=%s writer=%s" % [str(ws != null), str(writer != null)])
	if ws == null or writer == null:
		_finish("write")
		return

	# 经 I-1 权威入口 set_flag 写 5 个三段式 flag（不直接写盘、不构造 SaveDelta）
	for k in SEED_FLAGS.keys():
		ws.call("set_flag", String(k), SEED_FLAGS[k])
	_check("W② set_flag 注入 5 个三段式 flag", SEED_FLAGS.size() == 5,
		"keys=%s" % str(SEED_FLAGS.keys()))

	# 既有 SaveDeltaWriter.commit(reason) → WorldState._commit_delta → _atomic_write(slot_01/delta.json)
	writer.call("commit", WRITE_REASON)
	var cnt: int = int(writer.get("commit_count"))
	var reason: String = String(writer.get("last_commit_reason"))
	_check("W③ 既有 writer.commit 触发真实落盘", cnt >= 1 and reason == WRITE_REASON,
		"commit_count=%d last_commit_reason=%s" % [cnt, reason])

	# 磁盘证据：delta.json 存在 + 绝对路径 + 字节数 + 十字段 / schema_version / slot
	var abs_path: String = ProjectSettings.globalize_path(DELTA_PATH)
	var exists: bool = FileAccess.file_exists(DELTA_PATH)
	var size: int = 0
	var d: Dictionary = {}
	if exists:
		var f: FileAccess = FileAccess.open(DELTA_PATH, FileAccess.READ)
		if f != null:
			var text: String = f.get_as_text()
			size = text.length()
			f.close()
			var parsed: Variant = JSON.parse_string(text)
			if typeof(parsed) == TYPE_DICTIONARY:
				d = parsed as Dictionary
	_check("W④ slot_01/delta.json 已写盘", exists and size > 0,
		"path=%s bytes=%d" % [abs_path, size])
	var missing: Array = []
	for fld in TEN_FIELDS:
		if not d.has(fld):
			missing.append(fld)
	var extra: Array = []
	for k in d.keys():
		if not TEN_FIELDS.has(String(k)):
			extra.append(String(k))
	_check("W⑤ 十字段齐全且无额外顶层字段", missing.is_empty() and extra.is_empty(),
		"missing=%s extra=%s ten=%s" % [str(missing), str(extra), str(TEN_FIELDS)])
	var sv: int = int(d.get("schema_version", -1))
	var slot: String = String(d.get("slot", ""))
	var seq: int = int(d.get("seq", -1))
	var meta: Dictionary = d.get("meta", {}) as Dictionary
	var mreason: String = String(meta.get("last_commit_reason", ""))
	_check("W⑥ schema_version=3 / slot=slot_01 / 本次 reason 落 meta", sv == 3 and slot == "slot_01" and mreason == WRITE_REASON,
		"schema_version=%d slot=%s seq=%d meta.last_commit_reason=%s" % [sv, slot, seq, mreason])
	var flags: Dictionary = d.get("flags", {}) as Dictionary
	var bad: Array = []
	for k in flags.keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_check("W⑦ 落盘 flags 全部三段式", flags.size() == SEED_FLAGS.size() and bad.is_empty(),
		"flag_count=%d bad=%s keys=%s" % [flags.size(), str(bad), str(flags.keys())])
	_finish("write")


func _run_read() -> void:
	var ws: Node = get_root().get_node_or_null("WorldState")
	_check("R① /root/WorldState 就绪", ws != null, "node=%s" % str(ws != null))
	if ws == null:
		_finish("read")
		return

	# 「重启」证据：新进程启动，WorldState._ready() 只登记基线、尚未 _load()
	var before: Variant = ws.call("get_flag", "grace.limgrave_gatefront.lit", false)
	_check("R② 新进程 _load() 前内存为基线（未读档）", before == false,
		"get_flag(grace.limgrave_gatefront.lit,false)=%s" % str(before))

	# 磁盘证据（与 write 阶段同一路径）：文件仍在、十字段 / schema / slot / 三段式一致
	var abs_path: String = ProjectSettings.globalize_path(DELTA_PATH)
	var exists: bool = FileAccess.file_exists(DELTA_PATH)
	var d: Dictionary = {}
	if exists:
		var f: FileAccess = FileAccess.open(DELTA_PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			f.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				d = parsed as Dictionary
	_check("R③ 与 write 阶段同一 slot_01/delta.json 仍在盘", exists, "path=%s" % abs_path)
	var missing: Array = []
	for fld in TEN_FIELDS:
		if not d.has(fld):
			missing.append(fld)
	_check("R④ 读回十字段齐全", missing.is_empty(), "missing=%s ten=%s" % [str(missing), str(TEN_FIELDS)])
	var sv: int = int(d.get("schema_version", -1))
	var slot: String = String(d.get("slot", ""))
	_check("R⑤ schema_version=3 / slot=slot_01 一致", sv == 3 and slot == "slot_01",
		"schema_version=%d slot=%s" % [sv, slot])
	var meta: Dictionary = d.get("meta", {}) as Dictionary
	var mreason: String = String(meta.get("last_commit_reason", ""))
	_check("R⑥ meta.last_commit_reason 为本次 write 阶段写入", mreason == WRITE_REASON,
		"meta.last_commit_reason=%s (期望 %s)" % [mreason, WRITE_REASON])
	var flags: Dictionary = d.get("flags", {}) as Dictionary
	var bad: Array = []
	for k in flags.keys():
		if _re.search(String(k)) == null:
			bad.append(String(k))
	_check("R⑦ 读回 flags 全部三段式且数量一致", flags.size() == SEED_FLAGS.size() and bad.is_empty(),
		"flag_count=%d bad=%s keys=%s" % [flags.size(), str(bad), str(flags.keys())])

	# 触发既有 _load() → _migrate → _replay_log → _apply_snapshot 完整回放
	ws.call("_load")

	# 经 I-1 纯读 get_flag 逐项读回 5 个 flag，与 write 阶段注入值逐项一致
	var readback: Dictionary = {}
	var mism: Array = []
	for k in SEED_FLAGS.keys():
		var key: String = String(k)
		var v: Variant = ws.call("get_flag", key, null)
		readback[key] = v
		if not _val_eq(v, SEED_FLAGS[key]):
			mism.append("%s got=%s want=%s" % [key, str(v), str(SEED_FLAGS[key])])
	_check("R⑧ _load() 回放后 get_flag 逐项读回一致（5/5）", mism.is_empty(),
		"readback=%s mism=%s" % [str(readback), str(mism)])

	# 磁盘 flags 与写盘种子逐项一致（slot_01 一致）
	var disk_mism: Array = []
	for k in SEED_FLAGS.keys():
		var key: String = String(k)
		if not flags.has(key) or not _val_eq(flags[key], SEED_FLAGS[key]):
			disk_mism.append(key)
	_check("R⑨ 磁盘 flags 与写盘种子逐项一致（slot_01 一致）", disk_mism.is_empty(),
		"disk_mism=%s slot=%s" % [str(disk_mism), slot])
	_finish("read")


func _finish(phase: String) -> void:
	var ok: bool = _fail == 0
	print("[R22] ---- 阶段 %s 回读汇总 ----" % phase)
	print("[R22] SUMMARY phase=%s pid=%d pass=%d fail=%d ok=%s" % [phase, OS.get_process_id(), _pass, _fail, str(ok)])
	print("[R22] ==== 存档端到端真跑阶段结束 ====")
	quit(0 if ok else 1)
