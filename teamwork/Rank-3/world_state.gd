extends Node

## I-1 权威实现（Autoload 单例名 WorldState，脚本 res://autoload/world_state.gd，由 1 号注册）。
## 对外仅两个方法：get_flag(key, default) -> Variant、set_flag(key, value) -> void。
## 1 / 2 号禁止直接读写存档文件、禁止构造 / 解析 SaveDelta、禁止访问以下划线开头的内部成员。
##
## SaveDelta 合并规则（本轮 R2 落地，5 条，全部为内部行为，**不改变 I-1 对外签名**）：
##   M1 集合并集只增不减：spawns.defeated 取并集，击杀不可回滚。
##   M2 inventory 数量快照后写覆盖：inventory 是 {item_id: count} 快照，后写覆盖；count<=0 时 erase 移除。
##   M3 quest_stages 取较大值：同一 quest 的 stage_index = max(旧, 新)，阶段只前进不回退。
##   M4 timestamp 升序回放：delta.log 行按 written_at_unix（timestamp）升序逐行应用，后写覆盖先写（LWW）。
##   M5 .tmp → rename 原子写：delta.json.tmp → flush → DirAccess.rename_absolute → delta.json.bak。
## 另含 LWW 冲突、schema_version 1→2→3 逐级迁移、单槽 user://saves/slot_01/delta.json。

signal flag_changed(key: String, old_value: Variant, new_value: Variant)
signal delta_committed(seq: int, reason: String)

const SLOT_DIR: String = "user://saves/slot_01"
const DELTA_PATH: String = "user://saves/slot_01/delta.json"
const DELTA_TMP_PATH: String = "user://saves/slot_01/delta.json.tmp"
const DELTA_BAK_PATH: String = "user://saves/slot_01/delta.json.bak"
const DELTA_LOG_PATH: String = "user://saves/slot_01/delta.log"
const SCHEMA_VERSION: int = 3
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"

var _flags: Dictionary = {}       # 当前世界状态 = 基线 + Delta
var _baseline: Dictionary = {}    # 基线默认值
var _delta: Dictionary = {}       # 内存 SaveDelta 最新快照
var _seq: int = 0
var _re: RegEx = null

func _ready() -> void:
    _re = RegEx.new()
    _re.compile(FLAG_KEY_REGEX)
    _register_baseline({
        "manifest": "res://data/world_baseline.tres",
        "resource_ids": [
            "res://data/dialogue/dialogue_and_quest.tres",
            "res://data/grace/grace_network.tres",
            "res://data/dungeons/dungeon_01_bellvault.tres",
            "res://data/world_baseline.tres",
            "res://data/spawns/spawn_bellvault_elite_01.tres"
        ]
    })

# ==========================================================================
# I-1 对外：仅此两个方法。1 / 2 号不得依赖其外的任何成员。
# ==========================================================================

## 纯读：不发信号、不写盘、不创建 key、无副作用。未命中返回 default。
func get_flag(key: String, default: Variant = null) -> Variant:
    if not _validate_flag_key(key):
        push_warning("I-1: 非法 flag key：%s" % key)
        return default
    if _flags.has(key):
        return _flags[key]          # 标量返回值拷贝（GDScript 标量天然值语义）
    if _baseline.has(key):
        return _baseline[key]
    return default

## 幂等写入。仅当值真正变化：更新内存 → 发 flag_changed → 入队 Delta → seq += 1。
## 从不在调用内同步落盘；落盘由 save_delta_writer.gd 的 0.5 s 窗口 / 强制点触发。
func set_flag(key: String, value: Variant) -> void:
    if not _validate_flag_key(key):
        push_warning("I-1: 非法 flag key，写入忽略：%s" % key)
        return
    if not _is_scalar(value):
        push_error("I-1: flag value 仅允许 bool/int/float/String，写入忽略：%s" % key)
        return
    var old: Variant = get_flag(key, null)
    if typeof(old) == typeof(value) and old == value:
        return                      # 幂等：同 key 同值不发信号、不增 seq、不入 Delta
    _flags[key] = value
    flag_changed.emit(key, old, value)
    var flags: Dictionary = _delta.get("flags", {}) as Dictionary
    flags[key] = value
    _delta["flags"] = flags
    _seq += 1
    _delta["seq"] = _seq

# ==========================================================================
# 内部：flag 校验 / 基线登记 / SaveDelta 骨架（1 / 2 号不得依赖）
# ==========================================================================

func _validate_flag_key(key: String) -> bool:
    var r: RegEx = _re
    if r == null:
        r = RegEx.new()
        r.compile(FLAG_KEY_REGEX)
    return r.search(key) != null

func _is_scalar(v: Variant) -> bool:
    var t: int = typeof(v)
    return t == TYPE_BOOL or t == TYPE_INT or t == TYPE_FLOAT or t == TYPE_STRING

func _register_baseline(manifest: Dictionary) -> void:
    _baseline = {
        "grace.network.last_rest_epoch": 0,
        "grace.network.last_grace_id": ""
    }
    _flags = _baseline.duplicate(true)
    _delta = _new_delta()
    _seq = 0
    var ids: Array = manifest.get("resource_ids", []) as Array
    var collected: Array = []
    for p in ids:
        var path: String = String(p)
        collected.append(path)
        if ResourceLoader.exists(path):
            var res: Resource = ResourceLoader.load(path)
            if res == null:
                push_warning("I-1: 基线资源加载失败：%s" % path)
        else:
            push_warning("I-1: 基线资源不存在（跳过）：%s" % path)
    var baseline: Dictionary = _delta.get("baseline", {}) as Dictionary
    baseline["manifest"] = String(manifest.get("manifest", "res://data/world_baseline.tres"))
    baseline["resource_ids"] = collected
    _delta["baseline"] = baseline

func _new_delta() -> Dictionary:
    return {
        "schema_version": SCHEMA_VERSION,
        "slot": "slot_01",
        "seq": 0,
        "baseline": {"manifest": "res://data/world_baseline.tres", "manifest_hash": "", "baseline_version": 1, "resource_ids": []},
        "flags": {},
        "quests": {},                      # quest_id -> {stage_id, stage_index, flags}
        "inventory": {},                   # M2：{item_id: count} 数量快照
        "spawns": {"defeated": [], "epoch": 0},
        "removals": [],
        "meta": {"playtime_seconds": 0, "area_id": "", "last_grace_id": "", "written_at_unix": 0, "game_version": "", "last_commit_reason": ""}
    }

# ==========================================================================
# 内部：SaveDelta 合并 5 规则（R2 硬验收，逐条对应命名方法）
# ==========================================================================

## M1 集合并集只增不减：spawns.defeated 取并集，击杀不可回滚。
func _merge_set_union(old: Array, incoming: Array) -> Array:
    var result: Array = old.duplicate()
    for item in incoming:
        if not result.has(item):
            result.append(item)
    return result

## M2 inventory 数量快照后写覆盖：count<=0 时 erase 移除该 item；否则后写覆盖。
func _merge_inventory(snapshot: Dictionary, writes: Dictionary) -> Dictionary:
    var result: Dictionary = snapshot.duplicate(true)
    for k in writes.keys():
        var item_id: String = String(k)
        var count: int = int(writes[k])
        if count <= 0:
            result.erase(item_id)
        else:
            result[item_id] = count
    return result

## M3 quest_stages 取较大值：同一 quest 的 stage_index = max(旧, 新)，阶段只前进不回退。
func _merge_quest_stages(snapshot_quests: Dictionary, incoming_quests: Dictionary) -> Dictionary:
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

## M4 timestamp 升序回放的比较器：按 written_at_unix（缺失回落 seq）升序。
func _compare_lines(a: Variant, b: Variant) -> bool:
    var da: Dictionary = a as Dictionary
    var db: Dictionary = b as Dictionary
    var ta: int = int(da.get("written_at_unix", da.get("seq", 0)))
    var tb: int = int(db.get("written_at_unix", db.get("seq", 0)))
    return ta < tb

## M4 timestamp 升序回放：日志行按 written_at_unix 升序排序后逐行应用（LWW 后写覆盖）。
func _replay_log(lines: Array, snapshot: Dictionary) -> Dictionary:
    var ordered: Array = lines.duplicate()
    ordered.sort_custom(Callable(self, "_compare_lines"))
    var state: Dictionary = snapshot.duplicate(true)
    for line in ordered:
        _apply_line(state, line as Dictionary)
    return state

func _apply_line(state: Dictionary, line: Dictionary) -> void:
    var flags: Dictionary = state.get("flags", {}) as Dictionary
    var spawns: Dictionary = state.get("spawns", {"defeated": [], "epoch": 0}) as Dictionary
    var inventory: Dictionary = state.get("inventory", {}) as Dictionary
    var quests: Dictionary = state.get("quests", {}) as Dictionary

    # flags：后写覆盖（LWW by timestamp / seq）
    var f: Dictionary = line.get("flags", {}) as Dictionary
    for k in f.keys():
        var key: String = String(k)
        if _validate_flag_key(key) and _is_scalar(f[k]):
            flags[key] = f[k]

    # M1 集合并集只增不减
    var sp: Dictionary = line.get("spawns", {}) as Dictionary
    spawns["defeated"] = _merge_set_union(spawns.get("defeated", []) as Array, sp.get("defeated", []) as Array)
    spawns["epoch"] = maxi(int(spawns.get("epoch", 0)), int(sp.get("epoch", 0)))

    # M2 inventory 数量快照后写覆盖，count=0 移除
    inventory = _merge_inventory(inventory, line.get("inventory", {}) as Dictionary)

    # M3 quest_stages 取较大值
    quests = _merge_quest_stages(quests, line.get("quests", {}) as Dictionary)

    # removals 优先（先删后不加）
    for k in (line.get("removals", []) as Array):
        flags.erase(String(k))

    state["flags"] = flags
    state["spawns"] = spawns
    state["inventory"] = inventory
    state["quests"] = quests

# ==========================================================================
# 内部：原子写 / 落盘 / 迁移 / 回放加载 / 快照注入
# ==========================================================================

## M5 .tmp → rename 原子写：tmp → flush → rename_absolute → 成功后更新 bak。
func _atomic_write(delta: Dictionary) -> bool:
    var err: Error = DirAccess.make_dir_recursive_absolute(SLOT_DIR)
    if err != OK and err != ERR_ALREADY_EXISTS:
        push_error("I-1: 无法创建存档目录：%s" % SLOT_DIR)
        return false
    var f: FileAccess = FileAccess.open(DELTA_TMP_PATH, FileAccess.WRITE)
    if f == null:
        push_error("I-1: 无法打开 .tmp：%s" % DELTA_TMP_PATH)
        return false
    f.store_string(JSON.stringify(delta, "\t"))
    f.flush()
    f.close()
    var ren: Error = DirAccess.rename_absolute(DELTA_TMP_PATH, DELTA_PATH)
    if ren != OK:
        push_error("I-1: rename 失败（保留旧 delta.json 与 .tmp，内存状态仍正确）")
        return false
    var bak: FileAccess = FileAccess.open(DELTA_BAK_PATH, FileAccess.WRITE)
    if bak != null:
        bak.store_string(JSON.stringify(delta, "\t"))
        bak.flush()
        bak.close()
    return true

## 强制落盘（3 号内部方法，1 / 2 号不得调用）。
func _commit_delta(reason: String) -> void:
    _delta["seq"] = _seq
    var meta: Dictionary = _delta.get("meta", {}) as Dictionary
    meta["last_commit_reason"] = reason
    meta["written_at_unix"] = int(Time.get_unix_time_from_system())
    _delta["meta"] = meta
    if _atomic_write(_delta):
        delta_committed.emit(_seq, reason)

## schema_version 1 → 2 → 3 逐级迁移，禁止跳级；未知更高版本拒绝加载。
func _migrate(d: Dictionary) -> Dictionary:
    var origin: int = int(d.get("schema_version", 1))
    if origin > SCHEMA_VERSION:
        push_error("I-1: 存档来自更新版本（schema_version=%d），拒绝加载" % origin)
        return {}
    var state: Dictionary = d.duplicate(true)
    var v: int = origin
    if v == 1:
        # v1 → v2：补 spawns.epoch、inventory 数量快照、baseline.manifest_hash
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
        # v2 → v3：补 removals、meta.game_version、last_rest_epoch 约定
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

## 读 delta.log：只回放 seq > 快照 seq 的行；损坏 / 半截行丢弃（日志是尽力而为补偿）。
func _read_log(after_seq: int) -> Array:
    var out: Array = []
    if not FileAccess.file_exists(DELTA_LOG_PATH):
        return out
    var f: FileAccess = FileAccess.open(DELTA_LOG_PATH, FileAccess.READ)
    if f == null:
        return out
    while not f.eof_reached():
        var line: String = f.get_line()
        if line.strip_edges().is_empty():
            continue
        var parsed: Variant = JSON.parse_string(line)
        if typeof(parsed) != TYPE_DICTIONARY:
            continue
        var d: Dictionary = parsed as Dictionary
        if int(d.get("seq", 0)) <= after_seq:
            continue
        out.append(d)
    f.close()
    return out

func _load() -> void:
    if not FileAccess.file_exists(DELTA_PATH):
        return
    var f: FileAccess = FileAccess.open(DELTA_PATH, FileAccess.READ)
    if f == null:
        return
    var text: String = f.get_as_text()
    f.close()
    var parsed: Variant = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("I-1: delta.json 解析失败，从基线重建")
        return
    var snapshot: Dictionary = _migrate(parsed as Dictionary)
    if snapshot.is_empty():
        return
    var lines: Array = _read_log(int(snapshot.get("seq", 0)))
    var state: Dictionary = _replay_log(lines, snapshot)
    _apply_snapshot(state)

func _apply_snapshot(delta: Dictionary) -> void:
    _flags = _baseline.duplicate(true)
    var flags: Dictionary = delta.get("flags", {}) as Dictionary
    for k in flags.keys():
        _flags[String(k)] = flags[k]
    for k in (delta.get("removals", []) as Array):
        _flags.erase(String(k))
    _delta = delta
    _seq = int(delta.get("seq", 0))
