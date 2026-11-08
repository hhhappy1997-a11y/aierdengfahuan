extends Node
## R5 交付：按画质档位调整「常驻 chunk 数」的流式加载实现（移动端 4 chunk 运行时落地）。
## 落位：res://scripts/world/chunk_streaming_r5.gd。
##
## 与既有件的关系（R2/R3/R4 一律保留、不重做、不替换）：
##  - R2 chunk_streaming.gd 仍注册为 ChunkManager autoload，固定 RADIUS=1 → 3x3=9 块，不改。
##  - R4 chunk_streaming_r4.gd 仍是 M2「3x3 常驻」可测实现，固定 3x3=9 块，不改。
##  - 本件是 R5 新增，补齐 R2/R4 遗留的「移动端常驻 4 chunk 运行时落地」：
##    常驻块数不再写死为 9，而是由画质档 Resource 的 resident_chunk_count 字段驱动
##    （quality_preset_desktop.tres=9 / quality_preset_mobile.tres=4），运行时可切换。
##  - 三者接口对齐（set_player_chunk / pump / get_state / get_load_count /
##    get_seen_chunk_ids / read_loaded_flag / chunk_loaded / chunk_unloaded），
##    便于 SceneRouter 与 2 号消费者无差别订阅。
##
## 档位邻域生成：以玩家所在 chunk 为原点，在 [-2,2]^2 的 25 个候选偏移中，
## 按「到中心的平方距离 → dx → dy」确定性排序，取前 resident_chunk_count 个。
##  - count=9 时前 9 个恰好是完整 3x3（d²=0 的 1 个 + d²=1 的 4 个 + d²=2 的 4 个），
##    与 R2/R4 的 3x3 完全等价，桌面档行为不变。
##  - count=4 时取最近的 4 块（中心 + 3 个 d²=1 邻居），即移动端降级常驻 4 块。
##  - 任意 1..25 的档位数值都可直接生效，符合总纲「数据表改数值不改代码」。
##
## 运行时档位切换联动（与 SceneRouter 对接，不改既有件）：
##    router.call("set_quality_preset", true)            # 切到移动档
##    cm.apply_preset_path(router.active_preset_path)    # 从 quality_preset_mobile.tres 读 4
##  或：cm.configure_from_preset(router.get_active_preset())
##
## 其余口径沿用 R4：load_threaded_request → load_threaded_get_status → load_threaded_get
## 完整时序；UNLOADED/LOADING/LOADED 三态去重；延迟卸载为 LOADED 上的待释放标记；
## 折返取消标记复用实例；只经 WorldState.get_flag / set_flag 读写 flag（I-1），
## 不碰存档文件、不构造 SaveDelta。
##
## 硬约束：不写探针 / 测量 / preflight 脚本；不实现 billboard / 锚定 / AABB；
## I-4 set_pose 不扩展、pose 名冻结（本件不触及）；GDScript 全静态类型。

signal chunk_loaded(chunk_id: String)
signal chunk_unloaded(chunk_id: String)
signal chunk_load_failed(chunk_id: String, reason: String)
signal player_chunk_changed(chunk_id: String, center: Vector2i)
signal resident_chunk_count_changed(count: int)

const CHUNK_SIZE_M: float = 64.0
const CHUNK_SCENE_DIR: String = "res://scenes/world/chunks/"
const FLAG_PREFIX: String = "chunk."
const FLAG_LOADED_SUFFIX: String = ".loaded"
const DESKTOP_RESIDENT_CHUNK_COUNT: int = 9
const MOBILE_RESIDENT_CHUNK_COUNT: int = 4
const SEARCH_RADIUS: int = 2
const MAX_RESIDENT_CHUNKS: int = 25  # (2*SEARCH_RADIUS+1)^2

enum ChunkState { UNLOADED, LOADING, LOADED }

@export var region: String = "limgrave"
@export var chunk_root_path: NodePath = NodePath("")
@export var auto_start: bool = true
@export var unload_delay_sec: float = 2.0
@export var max_concurrent_loads: int = 3
## 常驻 chunk 数（档位驱动）。默认桌面 9；切移动档由 apply_preset_path 改为 4。
@export var resident_chunk_count: int = DESKTOP_RESIDENT_CHUNK_COUNT

var _states: Dictionary = {}             # chunk_id -> ChunkState（三态）
var _instances: Dictionary = {}          # chunk_id -> Node（已挂树实例）
var _pending_unload: Dictionary = {}     # chunk_id -> 剩余延迟秒数（LOADED 上的待释放标记）
var _discard_on_finish: Dictionary = {}  # 在途 LOADING 但已离开邻域，完成后丢弃
var _load_count: Dictionary = {}         # chunk_id -> chunk_loaded 发出次数
var _reported_failures: Dictionary = {}
var _center: Vector2i = Vector2i(0, 0)
var _center_initialized: bool = false
var _active_loads: int = 0
var _chunk_root: Node = null
var _world_state: Node = null
var _progress: Array = []
var _wanted_offsets: Array[Vector2i] = []
var _cached_offset_count: int = -1


# ---------------------------------------------------------------- 生命周期

func _ready() -> void:
	_world_state = get_node_or_null("/root/WorldState")
	call_deferred("_bootstrap")


func _bootstrap() -> void:
	if _world_state == null:
		_world_state = get_node_or_null("/root/WorldState")
	_chunk_root = _resolve_chunk_root()
	if _chunk_root == null:
		push_warning("[ChunkStreamingR5] 未找到 ChunkRoot，chunk 实例暂挂本节点下。")
		_chunk_root = self
	if auto_start:
		set_player_chunk(_center)


func _process(delta: float) -> void:
	pump(delta)


func pump(delta: float) -> void:
	## 推进一帧：轮询线程加载 + 推进延迟卸载。验收驱动可 set_process(false) 后
	## 显式调用，获得确定性帧步进（「可测」，与 R4 同口径）。
	_poll_loads()
	_tick_unload(delta)


func _resolve_chunk_root() -> Node:
	if chunk_root_path != NodePath(""):
		var explicit: Node = get_node_or_null(chunk_root_path)
		if explicit != null:
			return explicit
	var found: Node = get_tree().root.find_child("ChunkRoot", true, false)
	return found if found != null else null


# ---------------------------------------------------------------- 档位配置（R5 新增）

func set_resident_chunk_count(count: int) -> bool:
	## 按档位设置常驻 chunk 数并立即重算邻域。返回是否成功（clamp 到 1..25）。
	var clamped: int = clampi(count, 1, MAX_RESIDENT_CHUNKS)
	if clamped == resident_chunk_count and _center_initialized:
		_ensure_offsets()
		return true
	resident_chunk_count = clamped
	_cached_offset_count = -1
	_ensure_offsets()
	if _center_initialized:
		_reconcile(_center, true)
	resident_chunk_count_changed.emit(resident_chunk_count)
	return true


func configure_from_preset(preset: Resource) -> bool:
	## 从画质档 Resource 读取 resident_chunk_count（QualityPreset 字段）。
	## 用属性守卫，不硬依赖 class_name，缺字段时返回 false，不臆测档位。
	if preset == null:
		return false
	var value: Variant = preset.get("resident_chunk_count")
	if value == null:
		return false
	return set_resident_chunk_count(int(value))


func apply_preset_path(path: String) -> bool:
	## 与 SceneRouter.active_preset_path / set_quality_preset 联动：加载 .tres 并应用档位。
	if not ResourceLoader.exists(path, "Resource"):
		return false
	var preset: Resource = ResourceLoader.load(path, "Resource")
	return configure_from_preset(preset)


func get_resident_chunk_count() -> int:
	return resident_chunk_count


func get_wanted_ids() -> Array:
	## 当前档位下中心邻域的 chunk_id 列表（验收读它核对 9 / 4）。
	return _wanted_ids(_center)


func _ensure_offsets() -> void:
	if _cached_offset_count == resident_chunk_count and not _wanted_offsets.is_empty():
		return
	var candidates: Array[Vector2i] = []
	for dy in range(-SEARCH_RADIUS, SEARCH_RADIUS + 1):
		for dx in range(-SEARCH_RADIUS, SEARCH_RADIUS + 1):
			candidates.append(Vector2i(dx, dy))
	candidates.sort_custom(Callable(self, "_compare_offset"))
	_wanted_offsets.clear()
	var take: int = mini(resident_chunk_count, candidates.size())
	var i: int = 0
	while i < take:
		_wanted_offsets.append(candidates[i])
		i += 1
	_cached_offset_count = resident_chunk_count


func _compare_offset(a: Vector2i, b: Vector2i) -> bool:
	## 确定性排序：平方距离 → dx → dy，保证任意档位下邻域可复现。
	var da: int = a.x * a.x + a.y * a.y
	var db: int = b.x * b.x + b.y * b.y
	if da != db:
		return da < db
	if a.x != b.x:
		return a.x < b.x
	return a.y < b.y


# ---------------------------------------------------------------- 公开接口（可测）

func set_player_chunk(chunk: Vector2i) -> void:
	_reconcile(chunk, false)


func _reconcile(chunk: Vector2i, force: bool) -> void:
	var wanted: Array = _wanted_ids(chunk)
	if _center_initialized and not force and chunk == _center:
		# 同 chunk 内移动：仅补齐尚未发起的请求，不重算、不触发卸载（三态去重）。
		_fill_pending_requests(wanted)
		return
	_center = chunk
	_center_initialized = true

	# 折返：取消尚未到期的卸载 / 完成丢弃标记，实例直接复用（保持 LOADED），不重复加载。
	for raw_id in wanted:
		var id: String = String(raw_id)
		if _pending_unload.has(id):
			_pending_unload.erase(id)
		if _discard_on_finish.has(id):
			_discard_on_finish.erase(id)

	for raw_id in wanted:
		_request_chunk(String(raw_id))

	# 离开邻域的块：LOADED 进入延迟卸载；在途 LOADING 标记完成后丢弃。
	for raw_id in _states.keys():
		var id: String = String(raw_id)
		if wanted.has(id):
			continue
		var st: int = int(_states.get(id, ChunkState.UNLOADED))
		if st == ChunkState.LOADED:
			_pending_unload[id] = unload_delay_sec
		elif st == ChunkState.LOADING:
			_discard_on_finish[id] = true

	player_chunk_changed.emit(_make_id(chunk.x, chunk.y), chunk)


func world_to_chunk(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / CHUNK_SIZE_M),
		floori(world_pos.z / CHUNK_SIZE_M)
	)


func get_player_chunk() -> Vector2i:
	return _center


func is_chunk_loaded(chunk_id: String) -> bool:
	return int(_states.get(chunk_id, ChunkState.UNLOADED)) == ChunkState.LOADED


func get_state(chunk_id: String) -> int:
	return int(_states.get(chunk_id, ChunkState.UNLOADED))


func get_loaded_chunk_ids() -> Array:
	var out: Array = []
	for raw_id in _states.keys():
		var id: String = String(raw_id)
		if is_chunk_loaded(id):
			out.append(id)
	return out


func get_load_count(chunk_id: String) -> int:
	## 往返走之后每个出现过的 chunk_id 计数应恒为 1（不重复加载）。
	return int(_load_count.get(chunk_id, 0))


func get_seen_chunk_ids() -> Array:
	return _load_count.keys()


func read_loaded_flag(chunk_id: String, default_value: bool = false) -> bool:
	## 只经 WorldState.get_flag 读 flag（I-1）；供联调 / 3 号消费。
	if _world_state == null or not _world_state.has_method("get_flag"):
		return default_value
	return bool(_world_state.call("get_flag", _flag_key(chunk_id), default_value))


# ---------------------------------------------------------------- 请求与去重

func _wanted_ids(center: Vector2i) -> Array:
	_ensure_offsets()
	var out: Array = []
	for off in _wanted_offsets:
		out.append(_make_id(center.x + off.x, center.y + off.y))
	return out


func _make_id(x: int, y: int) -> String:
	return "chunk_%s_%d_%d" % [region, x, y]


func _path_for(chunk_id: String) -> String:
	return CHUNK_SCENE_DIR + chunk_id + ".tscn"


func _flag_key(chunk_id: String) -> String:
	return FLAG_PREFIX + chunk_id + FLAG_LOADED_SUFFIX


func _request_chunk(chunk_id: String) -> void:
	# 三态去重：非 UNLOADED（LOADING / LOADED）不重复发起请求。
	if int(_states.get(chunk_id, ChunkState.UNLOADED)) != ChunkState.UNLOADED:
		return
	if _active_loads >= max_concurrent_loads:
		return
	var path: String = _path_for(chunk_id)
	if not ResourceLoader.exists(path, "PackedScene"):
		_report_failure_once(chunk_id, "scene_missing")
		return
	var err: int = ResourceLoader.load_threaded_request(path, "PackedScene", false)
	if err != OK:
		_report_failure_once(chunk_id, "request_error_%d" % err)
		return
	_states[chunk_id] = ChunkState.LOADING
	_active_loads += 1


func _fill_pending_requests(wanted: Array) -> void:
	for raw_id in wanted:
		if _active_loads >= max_concurrent_loads:
			return
		_request_chunk(String(raw_id))


func _report_failure_once(chunk_id: String, reason: String) -> void:
	if _reported_failures.has(chunk_id):
		return
	_reported_failures[chunk_id] = true
	push_warning("[ChunkStreamingR5] %s 加载跳过：%s" % [chunk_id, reason])
	chunk_load_failed.emit(chunk_id, reason)


# ---------------------------------------------------------------- 线程加载完整时序

func _poll_loads() -> void:
	for raw_id in _states.keys():
		var chunk_id: String = String(raw_id)
		if int(_states.get(chunk_id, ChunkState.UNLOADED)) != ChunkState.LOADING:
			continue
		var path: String = _path_for(chunk_id)
		_progress.clear()
		var status: int = ResourceLoader.load_threaded_get_status(path, _progress)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				pass
			ResourceLoader.THREAD_LOAD_LOADED:
				_finish_load(chunk_id, path)
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_release_slot()
				_states[chunk_id] = ChunkState.UNLOADED
				_discard_on_finish.erase(chunk_id)
				_report_failure_once(chunk_id, "thread_load_failed")
	_fill_pending_requests(_wanted_ids(_center))


func _finish_load(chunk_id: String, path: String) -> void:
	# load_threaded_get 只在 THREAD_LOAD_LOADED 之后调用；提前调用会阻塞主线程造成帧尖峰。
	var res: Resource = ResourceLoader.load_threaded_get(path)
	_release_slot()
	if res == null or not (res is PackedScene):
		_states[chunk_id] = ChunkState.UNLOADED
		_discard_on_finish.erase(chunk_id)
		_report_failure_once(chunk_id, "not_packed_scene")
		return

	# 加载期间玩家已离开邻域：实例不入树、直接丢弃，归还槽位（不产生 chunk_loaded）。
	if _discard_on_finish.has(chunk_id):
		_discard_on_finish.erase(chunk_id)
		_states[chunk_id] = ChunkState.UNLOADED
		return

	var inst: Node = (res as PackedScene).instantiate()
	_chunk_root.add_child(inst)
	_instances[chunk_id] = inst
	_states[chunk_id] = ChunkState.LOADED
	_load_count[chunk_id] = int(_load_count.get(chunk_id, 0)) + 1
	_write_loaded_flag(chunk_id, true)
	chunk_loaded.emit(chunk_id)


func _release_slot() -> void:
	_active_loads = maxi(0, _active_loads - 1)


# ---------------------------------------------------------------- I-1 flag 桥接（只经 get_flag / set_flag）

func _write_loaded_flag(chunk_id: String, value: bool) -> void:
	## 只经 WorldState.set_flag 写 flag（I-1）；单例缺失时降级 no-op，不碰存档 / SaveDelta。
	if _world_state == null or not _world_state.has_method("set_flag"):
		return
	_world_state.call("set_flag", _flag_key(chunk_id), value)


# ---------------------------------------------------------------- 延迟卸载（LOADED 上的待释放标记）

func _tick_unload(delta: float) -> void:
	if _pending_unload.is_empty():
		return
	for raw_id in _pending_unload.keys():
		var chunk_id: String = String(raw_id)
		var left: float = float(_pending_unload[chunk_id]) - delta
		if left > 0.0:
			_pending_unload[chunk_id] = left
			continue
		_pending_unload.erase(chunk_id)
		if is_chunk_loaded(chunk_id):
			_unload_chunk(chunk_id)


func _unload_chunk(chunk_id: String) -> void:
	var inst: Node = _instances.get(chunk_id, null) as Node
	if inst != null and is_instance_valid(inst):
		inst.queue_free()
	_instances.erase(chunk_id)
	_states[chunk_id] = ChunkState.UNLOADED
	chunk_unloaded.emit(chunk_id)
