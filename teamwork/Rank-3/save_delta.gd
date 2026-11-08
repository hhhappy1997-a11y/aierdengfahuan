extends RefCounted
class_name SaveDelta

## R3 补齐件（任务书-R3.md §2 固定文件名 `save_delta.gd`）：单一职责的 SaveDelta 合并器。
## 与 R2 已产出的 `world_state.gd`（Autoload 单例 WorldState，I-1 权威、运行时实际执行者）口径逐条一致：
## 本文件把 合并 / 回放 / 原子写 / 迁移 规则外提为可单测、可复用的静态工具类，
## **不改变 I-1 对外签名**（仍是 WorldState.get_flag / set_flag 两方法），**不改动任何 R2 文件**。
## 运行时权威仍为 world_state.gd；本件供后续工程将内联合并逻辑迁移 / 复用时作为规范落地与验收基准。
##
## 规则（任务书-R3.md §2 第 2 行 + world_state.gd:7~13 的 5 条落地口径）：
##   R1 集合类并集只增不减                       → merge_set_union
##   R2 inventory 按 item_id 数量快照后写覆盖、count=0 移除 → merge_inventory
##   R3 quest_stages 取较大阶段值                 → merge_quest_stages
##   R4 transform / last_grace 后写覆盖          → merge_lww_scalars（LWW by timestamp / 写入顺序）
##   R5 timestamp 升序回放                       → replay
##   R6 .tmp → rename 原子写                     → atomic_write
##   R7 schema_version 迁移链、拒绝加载回退基线   → migrate / load_or_baseline
##
## 中文 UTF-8；Godot 4 全静态类型；零付费 / 零外部依赖。

const SCHEMA_VERSION: int = 3
const SLOT_DIR: String = "user://saves/slot_01"
const DELTA_PATH: String = "user://saves/slot_01/delta.json"
const DELTA_TMP_PATH: String = "user://saves/slot_01/delta.json.tmp"
const DELTA_BAK_PATH: String = "user://saves/slot_01/delta.json.bak"

## 需要「后写覆盖」(LWW) 的标量 / 位置 / 复活锚点类字段。
## 注：存档规范 §4.1 禁止玩家精确坐标(transform)进存档，复活锚点以 meta.last_grace_id 表达；
## 这里 transform 的语义等价物即 meta.area_id / last_grace_id / playtime_seconds 等标量，一律后写覆盖。
const LWW_META_KEYS: Array = ["area_id", "last_grace_id", "playtime_seconds", "game_version", "last_commit_reason"]

# ==========================================================================
# R1 / R2 / R3 —— 三类合并（与 world_state.gd._merge_* 逐条一致）
# ==========================================================================

## R1 集合并集只增不减：spawns.defeated 取并集，击杀不可回滚。
static func merge_set_union(old: Array, incoming: Array) -> Array:
	var result: Array = old.duplicate()
	for item in incoming:
		if not result.has(item):
			result.append(item)
	return result

## R2 inventory 数量快照后写覆盖：count<=0 时 erase 移除该 item，否则后写覆盖。
static func merge_inventory(snapshot: Dictionary, writes: Dictionary) -> Dictionary:
	var result: Dictionary = snapshot.duplicate(true)
	for k in writes.keys():
		var item_id: String = String(k)
		var count: int = int(writes[k])
		if count <= 0:
			result.erase(item_id)
		else:
			result[item_id] = count
	return result

## R3 quest_stages 取较大值：同一 quest 的 stage_index = max(旧, 新)，阶段只前进不回退。
static func merge_quest_stages(snapshot_quests: Dictionary, incoming_quests: Dictionary) -> Dictionary:
	var result: Dictionary = snapshot_quests.duplicate(true)
	for k in incoming_quests.keys():
		var qid: String = String(k)
		var inc: Dictionary = incoming_quests[k] as Dictionary
		if not result.has(qid):
			result[qid] = {"stage_id": "", "stage_index": 0, "flags": {}}
		var cur: Dictionary = result[qid] as Dictionary
		var cur_idx: int = int(cur.get("stage_index", 0))
		var inc_idx: int = int(inc.get("stage_index", 0))
		cur["stage_index"] = maxi(cur_idx, inc_idx)
		if inc_idx >= cur_idx:
			cur["stage_id"] = String(inc.get("stage_id", cur.get("stage_id", "")))
		result[qid] = cur
	return result

# ==========================================================================
# R4 —— 后写覆盖（LWW）标量 / flags / transform 等价字段
# ==========================================================================

static func _is_scalar(v: Variant) -> bool:
	var t: int = typeof(v)
	return t == TYPE_BOOL or t == TYPE_INT or t == TYPE_FLOAT or t == TYPE_STRING

## R4 后写覆盖：flags 标量（白名单校验）、meta 的 area_id / last_grace_id 等，后来者覆盖先写者。
static func merge_lww_scalars(state: Dictionary, line: Dictionary) -> void:
	var flags: Dictionary = state.get("flags", {}) as Dictionary
	var incoming_flags: Dictionary = line.get("flags", {}) as Dictionary
	for k in incoming_flags.keys():
		if _is_scalar(incoming_flags[k]):
			flags[String(k)] = incoming_flags[k]
	var meta: Dictionary = state.get("meta", {}) as Dictionary
	var incoming_meta: Dictionary = line.get("meta", {}) as Dictionary
	for key in LWW_META_KEYS:
		var mk: String = String(key)
		if incoming_meta.has(mk):
			meta[mk] = incoming_meta[mk]
	state["flags"] = flags
	state["meta"] = meta

# ==========================================================================
# R5 —— timestamp 升序回放
# ==========================================================================

static func _timestamp_of(line: Dictionary) -> int:
	return int(line.get("written_at_unix", line.get("seq", 0)))

## 手写插入排序按 written_at_unix 升序（缺失回落 seq），避免静态上下文里 sort_custom/Callable 绑定歧义。
static func _sort_lines_ascending(lines: Array) -> Array:
	var ordered: Array = lines.duplicate()
	for i in range(1, ordered.size()):
		var cur: Dictionary = ordered[i] as Dictionary
		var j: int = i - 1
		while j >= 0 and _timestamp_of(ordered[j] as Dictionary) > _timestamp_of(cur):
			ordered[j + 1] = ordered[j]
			j -= 1
		ordered[j + 1] = cur
	return ordered

static func _apply_line(state: Dictionary, line: Dictionary) -> void:
	# R4 标量 / flags / meta 后写覆盖
	merge_lww_scalars(state, line)
	# R1 集合并集只增不减
	var spawns: Dictionary = state.get("spawns", {"defeated": [], "epoch": 0}) as Dictionary
	var line_spawns: Dictionary = line.get("spawns", {}) as Dictionary
	spawns["defeated"] = merge_set_union(spawns.get("defeated", []) as Array, line_spawns.get("defeated", []) as Array)
	spawns["epoch"] = maxi(int(spawns.get("epoch", 0)), int(line_spawns.get("epoch", 0)))
	state["spawns"] = spawns
	# R2 inventory 数量快照后写覆盖
	state["inventory"] = merge_inventory(state.get("inventory", {}) as Dictionary, line.get("inventory", {}) as Dictionary)
	# R3 quest_stages 取较大值
	state["quests"] = merge_quest_stages(state.get("quests", {}) as Dictionary, line.get("quests", {}) as Dictionary)
	# removals 优先（先删后不加）
	var flags2: Dictionary = state.get("flags", {}) as Dictionary
	for k in (line.get("removals", []) as Array):
		flags2.erase(String(k))
	state["flags"] = flags2

## R5 timestamp 升序回放：日志行按 written_at_unix 升序逐行应用，后写覆盖先写（LWW）。
static func replay(snapshot: Dictionary, lines: Array) -> Dictionary:
	var state: Dictionary = snapshot.duplicate(true)
	var ordered: Array = _sort_lines_ascending(lines)
	for line in ordered:
		_apply_line(state, line as Dictionary)
	return state

# ==========================================================================
# R6 —— .tmp → rename 原子写
# ==========================================================================

## R6 原子写：tmp → flush → rename_absolute → 成功后更新 bak；失败保留旧 delta.json 与 .tmp。
static func atomic_write(delta: Dictionary) -> bool:
	var err: Error = DirAccess.make_dir_recursive_absolute(SLOT_DIR)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error("SaveDelta: 无法创建存档目录 " + SLOT_DIR)
		return false
	var f: FileAccess = FileAccess.open(DELTA_TMP_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveDelta: 无法打开 .tmp " + DELTA_TMP_PATH)
		return false
	f.store_string(JSON.stringify(delta, "\t"))
	f.flush()
	f.close()
	var ren: Error = DirAccess.rename_absolute(DELTA_TMP_PATH, DELTA_PATH)
	if ren != OK:
		push_error("SaveDelta: rename 失败，保留旧 delta.json 与 .tmp")
		return false
	var bak: FileAccess = FileAccess.open(DELTA_BAK_PATH, FileAccess.WRITE)
	if bak != null:
		bak.store_string(JSON.stringify(delta, "\t"))
		bak.flush()
		bak.close()
	return true

# ==========================================================================
# R7 —— schema_version 迁移链 / 拒绝加载回退基线
# ==========================================================================

## R7 逐级迁移 1→2→3，禁止跳级；未知更高版本返回空 Dictionary（拒绝加载 → 调用方回退基线）。
static func migrate(d: Dictionary) -> Dictionary:
	var origin: int = int(d.get("schema_version", 1))
	if origin > SCHEMA_VERSION:
		push_error("SaveDelta: 存档来自更新版本（schema_version=%d），拒绝加载" % origin)
		return {}
	var state: Dictionary = d.duplicate(true)
	var v: int = origin
	if v == 1:
		if not state.has("spawns"):
			state["spawns"] = {"defeated": [], "epoch": 0}
		if not state.has("inventory"):
			state["inventory"] = {}
		var baseline: Dictionary = state.get("baseline", {}) as Dictionary
		if not baseline.has("manifest_hash"):
			baseline["manifest_hash"] = ""
		state["baseline"] = baseline
		v = 2
	if v == 2:
		if not state.has("removals"):
			state["removals"] = []
		var meta: Dictionary = state.get("meta", {}) as Dictionary
		if not meta.has("game_version"):
			meta["game_version"] = ""
		state["meta"] = meta
		v = 3
	state["schema_version"] = SCHEMA_VERSION
	if origin != SCHEMA_VERSION:
		var meta2: Dictionary = state.get("meta", {}) as Dictionary
		meta2["migrated_from"] = origin
		state["meta"] = meta2
	return state

## 基线快照（拒绝加载 / 解析失败时的回退目标），与 world_state.gd._new_delta 同构。
static func baseline_delta() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"slot": "slot_01",
		"seq": 0,
		"baseline": {"manifest": "res://data/world_baseline.tres", "manifest_hash": "", "baseline_version": 1, "resource_ids": []},
		"flags": {},
		"quests": {},
		"inventory": {},
		"spawns": {"defeated": [], "epoch": 0},
		"removals": [],
		"meta": {"playtime_seconds": 0, "area_id": "", "last_grace_id": "", "written_at_unix": 0, "game_version": "", "last_commit_reason": ""}
	}

## R7 加载：解析失败 / 未知高版本 → 回退基线；否则迁移后只回放 seq > 快照 seq 的日志行。
static func load_or_baseline(snapshot_text: String, log_lines: Array) -> Dictionary:
	var parsed: Variant = JSON.parse_string(snapshot_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveDelta: delta.json 解析失败，回退基线")
		return baseline_delta()
	var migrated: Dictionary = migrate(parsed as Dictionary)
	if migrated.is_empty():
		push_warning("SaveDelta: 迁移拒绝加载，回退基线")
		return baseline_delta()
	var after_seq: int = int(migrated.get("seq", 0))
	var effective: Array = []
	for line in log_lines:
		var d: Dictionary = line as Dictionary
		if int(d.get("seq", 0)) > after_seq:
			effective.append(d)
	return replay(migrated, effective)
