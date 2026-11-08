extends Node
## 大地图分块流式加载（总纲 3.2 / 1 号工位）
## 落位：res://scripts/world/chunk_streaming.gd，注册为 autoload 单例 ChunkManager。
## 场景树中的 ChunkRoot 保持空 Node3D，不挂本脚本，避免与 autoload 形成双实例。
##
## 约定：
##  - 以玩家所在 chunk 为中心 3x3 常驻；UNLOADED / LOADING / LOADED / UNLOADING 四态去重，
##    对外表现为「加载中 / 已加载 / 卸载」三态 + 延迟卸载期。
##  - 只经 WorldState.get_flag / set_flag 与世界状态交互（I-1），不读写存档文件、不构造 SaveDelta。
##  - 不实现 billboard / 锚定 / AABB；不写探针、测量或 preflight 脚本。

signal chunk_loaded(chunk_id: String)
signal chunk_unloaded(chunk_id: String)
signal chunk_load_failed(chunk_id: String, reason: String)
signal player_chunk_changed(chunk_id: String, center: Vector2i)

const CHUNK_SIZE_M: float = 64.0
const PIXELS_PER_METER: float = 32.0
const RADIUS: int = 1
const CHUNK_SCENE_DIR: String = "res://scenes/world/chunks/"

enum ChunkState { UNLOADED, LOADING, LOADED, UNLOADING }

@export var region: String = "limgrave"
@export var chunk_root_path: NodePath = NodePath("")
@export var auto_start: bool = true
@export var unload_delay_sec: float = 2.0
@export var max_concurrent_loads: int = 2
@export var density_poi_min_count: int = 1

var _states: Dictionary = {}          # chunk_id -> ChunkState
var _instances: Dictionary = {}       # chunk_id -> Node（已挂树的实例）
var _pending_unload: Dictionary = {}  # chunk_id -> 剩余延迟秒数
var _load_count: Dictionary = {}      # chunk_id -> chunk_loaded 发出次数（M2 验收读它）
var _reported_failures: Dictionary = {}
var _center: Vector2i = Vector2i(0, 0)
var _active_loads: int = 0
var _chunk_root: Node = null
var _progress: Array = []

# ---------------------------------------------------------------- 生命周期

func _ready() -> void:
	# autoload 的 _ready 早于 Main 场景，延后一帧再解析 ChunkRoot。
	call_deferred("_bootstrap")


func _bootstrap() -> void:
	_chunk_root = _resolve_chunk_root()
	if _chunk_root == null:
		push_warning("[ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。")
		_chunk_root = self
	if auto_start:
		set_player_chunk(_center)


func _process(delta: float) -> void:
	_poll_loads()
	_tick_unload(delta)


func _resolve_chunk_root() -> Node:
	if chunk_root_path != NodePath(""):
		var explicit: Node = get_node_or_null(chunk_root_path)
		if explicit != null:
			return explicit
	var found: Node = get_tree().root.find_child("ChunkRoot", true, false)
	return found if found != null else null

# ---------------------------------------------------------------- 公开接口（I-6 / 2 号 / 3 号消费）

func set_player_chunk(chunk: Vector2i) -> void:
	## 玩家所在 chunk 变化时由 SceneRouter / 玩家控制器调用。
	var wanted: Array = _wanted_ids(chunk)
	if chunk == _center and not _states.is_empty():
		# 同一 chunk 内移动：只补发尚未排队的请求，不重算卸载。
		_fill_pending_requests(wanted)
		return
	_center = chunk

	# 折返：取消尚未到期的卸载，实例直接复用，不重复加载。
	for raw_id in wanted:
		var id := String(raw_id)
		if _pending_unload.has(id):
			_pending_unload.erase(id)
			if int(_states.get(id, ChunkState.UNLOADED)) == ChunkState.UNLOADING:
				_states[id] = ChunkState.LOADED

	for raw_id in wanted:
		_request_chunk(String(raw_id))

	# 离开 3x3 的块进入延迟卸载，不立即释放。
	for raw_id in _states.keys():
		var id := String(raw_id)
		if wanted.has(id):
			continue
		var st: int = int(_states.get(id, ChunkState.UNLOADED))
		if st == ChunkState.LOADED:
			_states[id] = ChunkState.UNLOADING
			_pending_unload[id] = unload_delay_sec
		elif st == ChunkState.LOADING:
			# 在途请求不能改成 UNLOADING：否则 _poll_loads 不再轮询它，并发槽位永不释放。
			# 保持 LOADING，由 _finish_load 检测到 pending 标记后立即丢弃并归还槽位。
			_pending_unload[id] = unload_delay_sec

	player_chunk_changed.emit(_make_id(chunk.x, chunk.y), chunk)


func world_to_chunk(world_pos: Vector3) -> Vector2i:
	## M1 起：玩家世界坐标 -> chunk 坐标，供 SceneRouter 直接喂给 set_player_chunk。
	return Vector2i(
		floori(world_pos.x / CHUNK_SIZE_M),
		floori(world_pos.z / CHUNK_SIZE_M)
	)


func get_player_chunk() -> Vector2i:
	return _center


func is_chunk_loaded(chunk_id: String) -> bool:
	return int(_states.get(chunk_id, ChunkState.UNLOADED)) == ChunkState.LOADED


func get_loaded_chunk_ids() -> Array:
	var out: Array = []
	for raw_id in _states.keys():
		var id := String(raw_id)
		if is_chunk_loaded(id):
			out.append(id)
	return out


func get_load_count(chunk_id: String) -> int:
	## M2 验收：往返走之后每个 chunk_id 的计数应恒为 1。
	return int(_load_count.get(chunk_id, 0))


func force_reload_chunk(chunk_id: String) -> void:
	## 仅 debug（F4）使用：只对已加载块生效，避免打断在途请求造成并发槽位泄漏。
	if not is_chunk_loaded(chunk_id):
		return
	_pending_unload.erase(chunk_id)
	_unload_chunk(chunk_id)
	_request_chunk(chunk_id)

# ---------------------------------------------------------------- 请求与去重

func _wanted_ids(center: Vector2i) -> Array:
	var out: Array = []
	for dy in range(-RADIUS, RADIUS + 1):
		for dx in range(-RADIUS, RADIUS + 1):
			out.append(_make_id(center.x + dx, center.y + dy))
	return out


func _make_id(x: int, y: int) -> String:
	return "chunk_%s_%d_%d" % [region, x, y]


func _path_for(chunk_id: String) -> String:
	return CHUNK_SCENE_DIR + chunk_id + ".tscn"


func _request_chunk(chunk_id: String) -> void:
	if int(_states.get(chunk_id, ChunkState.UNLOADED)) != ChunkState.UNLOADED:
		return
	if _active_loads >= max_concurrent_loads:
		return
	var path := _path_for(chunk_id)
	if not ResourceLoader.exists(path, "PackedScene"):
		_report_failure_once(chunk_id, "scene_missing")
		return
	var err: int = ResourceLoader.load_threaded_request(path, "PackedScene", false)
	if err != OK:
		_report_failure_once(chunk_id, "request_error_%d" % err)
		return
	_states[chunk_id] = ChunkState.LOADING
	_active_loads += 1


func _fill_pending_requests(wanted: Array = []) -> void:
	## 并发槽位释放后补齐排队中的 chunk，保证 3x3 最终填满。
	if wanted.is_empty():
		wanted = _wanted_ids(_center)
	for raw_id in wanted:
		if _active_loads >= max_concurrent_loads:
			break
		_request_chunk(String(raw_id))


func _report_failure_once(chunk_id: String, reason: String) -> void:
	if _reported_failures.has(chunk_id):
		return
	_reported_failures[chunk_id] = true
	push_warning("[ChunkManager] %s 加载跳过：%s" % [chunk_id, reason])
	chunk_load_failed.emit(chunk_id, reason)

# ---------------------------------------------------------------- 线程加载时序

func _poll_loads() -> void:
	for raw_id in _states.keys():
		var chunk_id := String(raw_id)
		if int(_states.get(chunk_id, ChunkState.UNLOADED)) != ChunkState.LOADING:
			continue
		var path := _path_for(chunk_id)
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
				_report_failure_once(chunk_id, "thread_load_failed")
	_fill_pending_requests()


func _finish_load(chunk_id: String, path: String) -> void:
	# load_threaded_get 只在 THREAD_LOAD_LOADED 之后调用，提前调用会阻塞主线程造成帧尖峰。
	var res: Resource = ResourceLoader.load_threaded_get(path)
	_release_slot()
	if res == null or not (res is PackedScene):
		_states[chunk_id] = ChunkState.UNLOADED
		_report_failure_once(chunk_id, "not_packed_scene")
		return

	# 加载期间玩家已离开 3x3：实例不入树，直接释放，避免「加载完立刻卸载」的抖动。
	if _pending_unload.has(chunk_id):
		_pending_unload.erase(chunk_id)
		_states[chunk_id] = ChunkState.UNLOADED
		return

	var inst: Node = (res as PackedScene).instantiate()
	_chunk_root.add_child(inst)
	_instances[chunk_id] = inst
	_states[chunk_id] = ChunkState.LOADED
	_load_count[chunk_id] = int(_load_count.get(chunk_id, 0)) + 1
	_apply_world_flags(chunk_id, inst)
	_check_density(chunk_id, inst)
	chunk_loaded.emit(chunk_id)


func _release_slot() -> void:
	_active_loads = maxi(0, _active_loads - 1)

# ---------------------------------------------------------------- I-1 世界状态桥接

func _apply_world_flags(chunk_id: String, inst: Node) -> void:
	## 1 号只收集 flag 并转交，不定义键名、不碰存档文件、不构造 SaveDelta。
	if not inst.has_method("get_flag_keys") or not inst.has_method("apply_world_flags"):
		return
	var ws: Node = get_node_or_null("/root/WorldState")
	if ws == null or not ws.has_method("get_flag"):
		push_warning("[ChunkManager] WorldState 未就绪，%s 使用空 flags（I-1 降级）。" % chunk_id)
		return
	var flags: Dictionary = {}
	for raw_key in inst.call("get_flag_keys"):
		var key := String(raw_key)
		flags[key] = ws.call("get_flag", key, null)
	inst.call("apply_world_flags", flags)


func _check_density(chunk_id: String, inst: Node) -> void:
	## 密度原则：每 64m chunk 至少 1 个 POI（30 秒路程约 135m，验收更严）。
	if not inst.has_method("get_poi_count"):
		return
	var count: int = int(inst.call("get_poi_count"))
	if count < density_poi_min_count:
		push_warning("[density] %s 未达 POI 下限：%d/%d" % [chunk_id, count, density_poi_min_count])

# ---------------------------------------------------------------- 延迟卸载

func _tick_unload(delta: float) -> void:
	if _pending_unload.is_empty():
		return
	for raw_id in _pending_unload.keys():
		var chunk_id := String(raw_id)
		var left: float = float(_pending_unload[chunk_id]) - delta
		if left > 0.0:
			_pending_unload[chunk_id] = left
			continue
		_pending_unload.erase(chunk_id)
		if int(_states.get(chunk_id, ChunkState.UNLOADED)) == ChunkState.UNLOADING:
			_unload_chunk(chunk_id)


func _unload_chunk(chunk_id: String) -> void:
	var inst: Node = _instances.get(chunk_id, null) as Node
	if inst != null and is_instance_valid(inst):
		inst.queue_free()
	_instances.erase(chunk_id)
	_states.erase(chunk_id)
	chunk_unloaded.emit(chunk_id)
