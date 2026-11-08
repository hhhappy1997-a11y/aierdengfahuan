extends Node
class_name ChunkWorldBridge

## R4 补齐件：SaveDelta / WorldState（3 号，I-1 权威）与 Rank-1 ChunkManager 的工程根联调桥接。
## 本件只做三件事，**不重做 / 不改写任何 R2 / R3 既有交付件**：
##   1) chunk 加载 flag 的 I-1 三段式归一（见下方跨工位口径冲突说明）；
##   2) 把 ChunkManager / SceneRouter 的加载边界对齐到 存档与flag规范.md §4.8 的强制落盘点；
##   3) 为 ChunkManager._apply_world_flags 提供「只读 flag + 三段式校验」的收集入口。
##
## 【跨工位口径冲突 · 待 HOST 裁决，3 号不越界改 Rank-1 文件】
##   Rank-1 `chunk_streaming_r4.gd` 用 `FLAG_PREFIX = "chunk."` 写 `chunk.<chunk_id>.loaded`，
##   而 I-1（存档与flag规范.md §3.1）三段式第一段仅允许 world|quest|combat|grace|dungeon。
##   `chunk.` 首段非法 → WorldState.set_flag 会 push_warning 并忽略，导致「chunk 已加载」写不进存档。
##   本件提供 normalize_chunk_flag() 归一为 `world.<chunk_id>.loaded`（三段式合法），
##   建议 Rank-1 后续改经此函数或采用 world 前缀；最终口径以 HOST 裁决为准，本轮不动对方文件。
##
## 只经 WorldState.get_flag / set_flag 与 3 号内部 SaveDeltaWriter.commit 交互（I-1）。
## 不读写存档文件、不构造 SaveDelta、不调 ResourceLoader、不写探针 / 测量 / preflight 脚本。
## 中文 UTF-8；Godot 4 全静态类型；零付费 / 零外部依赖。
##
## 【R8 · 负坐标归一（本轮落地：只增强本文件，不改对方文件 / 不改正则权威）】
##   R7 §2 实测：Rank-1 ChunkManager 生成负坐标 chunk_id（chunk_limgrave_-1_-1、
##   chunk_limgrave_0_-1 等），'-' 不在 I-1 三段式第二段 [a-z0-9_]+ 允许集；旧版
##   normalize_chunk_flag() 直接拼接 → world.chunk_limgrave_-1_-1.loaded 仍非法，
##   bridge 只能 push_warning「归一后仍非法」并丢弃（w7.log 两条 WARNING）。
##   R8 在本文件内新增 sanitize_flag_segment()，把 '-' → "neg" 转义后生成合法 flag；
##   normalize_chunk_flag() / normalize_flag_key() 均经此清洗。
##   边界：不改 world_state.gd:24 FLAG_KEY_REGEX、不改 存档与flag规范.md §3.1 正则、
##   不改 Rank-1 chunk_streaming*.gd 的 chunk_id / flag 命名；待裁决项 B（chunk flag
##   A/B/C 最终口径）仍只登记不擅改，由 HOST 裁决。本件只保证 3 号归一产物恒定合法。

const VALID_MODULES: Array = ["world", "quest", "combat", "grace", "dungeon"]

# R8 负坐标归一常量：只影响 3 号归一产物，不改下方 FLAG_KEY_REGEX（I-1 正则权威不动）。
# 合法字符集与 world_state.gd:24 三段式第二段 / 第三段逐字一致。
const LEGAL_SEGMENT_CHARS: String = "abcdefghijklmnopqrstuvwxyz0123456789_"
const NEG_TOKEN: String = "neg"   # 单个 '-' → "neg"（-1 → neg1），全合法字符、可读、可反解
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"

# 加载边界 → 存档与flag规范.md §4.8 的强制落盘 reason
const REASON_DUNGEON_ENTER: String = "dungeon_enter"
const REASON_DUNGEON_EXIT: String = "dungeon_exit"
const REASON_FAST_TRAVEL: String = "grace_fast_travel"

var _ws: Node = null
var _writer: Node = null
var _cm: Node = null
var _events: Node = null

func _ready() -> void:
	_ws = get_node_or_null("/root/WorldState")
	_writer = get_node_or_null("/root/SaveDeltaWriter")
	_cm = get_node_or_null("/root/ChunkManager")
	_events = get_node_or_null("/root/GameEvents")
	_connect_boundaries()

# ---------------------------------------------------------------- 1) chunk flag 三段式归一

## 把任意字符串收敛成 I-1 三段式允许的「段」（R8 新增）。
## 每个 '-' 编码为 NEG_TOKEN（"neg"），其余 [a-z0-9_] 原样保留，其它非法字符
## （大写 / '.' / 空格等）直接丢弃。结果只含 [a-z0-9_]，必定满足 I-1 三段式。
## 无 '-' 时输出与输入逐字一致（保证既有 45 项联调断言零回归）；不静默猜测业务值。
## 定位：只生成「稳定 / 唯一 / 合法」的 flag 段，不做业务反解；对 Rank-1 按契约 §2
## 生成的 chunk_id（区域 slug 为 [a-z0-9_]、坐标为 [0-9-]+）稳定且无碰撞。
static func sanitize_flag_segment(seg: String) -> String:
	var out: String = ""
	for i in range(seg.length()):
		var c: String = seg.substr(i, 1)
		if c == "-":
			out += NEG_TOKEN
		elif LEGAL_SEGMENT_CHARS.find(c) >= 0:
			out += c
	return out

## 把 Rank-1 的 `chunk.<chunk_id>.loaded` 归一为 I-1 合法三段式 `world.<chunk_id>.loaded`。
## 已是合法三段式的 key 原样返回；非法首段统一收敛到 world 段（INV-6：状态全部进 flags）。
## R8：obj / state 段经 sanitize_flag_segment() 清洗，使含负坐标 '-' 的 key 也能收敛为
## 合法三段式（如 chunk.chunk_limgrave_0_-1.loaded → world.chunk_limgrave_0_neg1.loaded）。
## 非三段式输入返回 ""（调用方过滤，不静默猜测）。
static func normalize_flag_key(raw_key: String) -> String:
	var parts: PackedStringArray = raw_key.split(".")
	if parts.size() != 3:
		return ""
	var module: String = parts[0]
	if not VALID_MODULES.has(module):
		module = "world"
	return "%s.%s.%s" % [module, sanitize_flag_segment(parts[1]), sanitize_flag_segment(parts[2])]

## `chunk_limgrave_0_0` → `world.chunk_limgrave_0_0.loaded`（三段式、首段白名单内）。
## R8：chunk_id 先经 sanitize_flag_segment() 归一，负坐标不再产生非法 flag：
##   chunk_limgrave_-1_-1 → world.chunk_limgrave_neg1_neg1.loaded（is_valid_flag_key=true）
##   chunk_limgrave_0_-1  → world.chunk_limgrave_0_neg1.loaded
static func normalize_chunk_flag(chunk_id: String) -> String:
	return "world.%s.loaded" % sanitize_flag_segment(chunk_id)

## 三段式 + 首段白名单校验（与 world_state.gd:24 FLAG_KEY_REGEX 逐字一致）。
static func is_valid_flag_key(key: String) -> bool:
	var r: RegEx = RegEx.new()
	r.compile(FLAG_KEY_REGEX)
	return r.search(key) != null

# ---------------------------------------------------------------- 2) 加载边界 → 强制落盘（§4.8）

func _connect_boundaries() -> void:
	# 3 号 GameEvents：地牢进 / 出、赐福传送（接口契约.md §1.3 / game_events.gd:10~11）
	if _events != null:
		if _events.has_signal("dungeon_transition_requested"):
			_events.connect("dungeon_transition_requested", Callable(self, "_on_dungeon_transition"))
		if _events.has_signal("travel_requested"):
			_events.connect("travel_requested", Callable(self, "_on_travel_requested"))
	# Rank-1 ChunkManager：chunk 加载完成 / 玩家跨 chunk（chunk_streaming.gd:12~15）
	if _cm != null:
		if _cm.has_signal("chunk_loaded"):
			_cm.connect("chunk_loaded", Callable(self, "_on_chunk_loaded"))
		if _cm.has_signal("player_chunk_changed"):
			_cm.connect("player_chunk_changed", Callable(self, "_on_player_chunk_changed"))

## direction = "enter" / "exit" → dungeon_enter / dungeon_exit 强制同步（与 1 号加载边界对齐）。
func _on_dungeon_transition(_dungeon_id: String, direction: String) -> void:
	var reason: String = REASON_DUNGEON_ENTER if direction == "enter" else REASON_DUNGEON_EXIT
	_commit(reason)

## 传送前（离开当前区域）→ grace_fast_travel 强制同步，防跨场景丢状态。
func _on_travel_requested(_target_grace_id: String) -> void:
	_commit(REASON_FAST_TRAVEL)

## chunk 加载完成：只读校验归一后的 flag 是否已登记，不额外写盘（避免每次加载刷盘）。
func _on_chunk_loaded(chunk_id: String) -> void:
	var key: String = normalize_chunk_flag(chunk_id)
	if not is_valid_flag_key(key):
		push_warning("[ChunkWorldBridge] 归一后仍非法：%s" % key)
		return
	if _ws != null and _ws.has_method("get_flag"):
		_ws.call("get_flag", key, false)

## 玩家跨 chunk：不强制落盘；只在边界点（地牢进出 / 传送）统一落盘，避免刷盘。
func _on_player_chunk_changed(chunk_id: String, _center: Vector2i) -> void:
	if _ws != null and _ws.has_method("get_flag"):
		_ws.call("get_flag", normalize_chunk_flag(chunk_id), false)

## 3 号内部强制落盘（SaveDeltaWriter.commit → WorldState._commit_delta），1 / 2 号不得调用。
func _commit(reason: String) -> void:
	if _writer != null and _writer.has_method("commit"):
		_writer.call("commit", reason)

# ---------------------------------------------------------------- 3) _apply_world_flags 的只读收集

## 供 chunk 场景 / ChunkManager 侧调用：对 get_flag_keys() 返回的 key 先做三段式归一 + 校验，
## 再经 WorldState.get_flag 读值，过滤非法 key（降级为不收集，不写盘、不构造 SaveDelta）。
## 对应 chunk_streaming.gd:251 _apply_world_flags 的「1 号只收集 flag 并转交」口径。
func collect_world_flags(flag_keys: Array) -> Dictionary:
	var out: Dictionary = {}
	if _ws == null or not _ws.has_method("get_flag"):
		return out
	for raw in flag_keys:
		var key: String = normalize_flag_key(String(raw))
		if key.is_empty() or not is_valid_flag_key(key):
			continue
		out[key] = _ws.call("get_flag", key, null)
	return out
