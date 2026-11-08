extends Node
## R4 交付：M2「3x3 常驻流式加载」可测实现。
## 落位：res://scripts/world/chunk_streaming_r4.gd。
##
## 与 R2 chunk_streaming.gd 的关系：R2 件保留为 ChunkManager autoload（不重做、不替换）；
## 本件是 R4 新增的 M2 可测实现，供 courtyard / M2 验收驱动挂载与断言。
## 两者接口对齐（set_player_chunk / get_load_count / chunk_loaded / chunk_unloaded），
## 便于 SceneRouter 与 2 号消费者无差别订阅。
##
## 任务书 R4 要点：
##  - 完整时序：load_threaded_request → load_threaded_get_status → load_threaded_get。
##  - 三态去重：UNLOADED / LOADING / LOADED 三态；非 UNLOADED 的块不重复发起请求；
##    延迟卸载是 LOADED 态上的「待释放」标记（不引入第四态），折返时取消以复用实例，
##    保证总纲 §4 M2「往返走不重复加载」。
##  - 信号：chunk_loaded / chunk_unloaded（另带 chunk_load_failed / player_chunk_changed）。
##  - flag：只经 WorldState.get_flag / set_flag 读写（I-1），不碰存档文件、不构造 SaveDelta。
##
## 硬约束：不写探针 / 测量 / preflight 脚本；不实现 billboard / 锚定 / AABB；
## I-4 set_pose 不扩展、pose 名冻结（本件不触及）；GDScript 全静态类型。

signal chunk_loaded(chunk_id: String)
signal chunk_unloaded(chunk_id: String)
signal chunk_load_failed(chunk_id: String, reason: String)
signal player_chunk_changed(chunk_id: String, center: Vector2i)

const CHUNK_SIZE_M: float = 64.0
const RADIUS: int = 1
const CHUNK_SCENE_DIR: String = "res://scenes/world/chunks/"
const FLAG_PREFIX: String = "chunk."
const FLAG_LOADED_SUFFIX: String = ".loaded"

enum ChunkState { UNLOADED, LOADING, LOADED }

@export var region: String = "limgrave"
@export var chunk_root_path: NodePath = NodePath("")
@export var auto_start: bool = true
@export var unload_delay_sec: float = 2.0
@export var max_concurrent_loads: int = 3

var _states: Dictionary = {}             # chunk_id -> ChunkState（三态）
var _instances: Dictionary = {}          # chunk_id -> Node（已挂树实例）
var _pending_unload: Dictionary = {}     # chunk_id -> 剩余延迟秒数（LOADED 上的待释放标记，非独立态）
var _discard_on_finish: Dictionary = {}  # 在途 LOADING 但已离开 3x3，完成后丢弃
var _load_count: Dictionary = {}         # chunk_id -> chunk_loaded 发出次数（M2 验收）
var _reported_failures: Dictionary = {}
var _center: Vector2i = Vector2i(0, 0)
var _center_initialized: bool = false
var _active_loads: int = 0
var _chunk_root: Node = null
var _world_state: Node = null
var _progress: Array = []


# ---------------------------------------------------------------- 生命周期

func _ready() -> void:
	_world_state = get_node_or_null("/root/WorldState")
	# autoload / 挂载场景就绪后再解析 ChunkRoot；M2 驱动也会等这一帧完成再喂输入。
	call_deferred("_bootstrap")


func _bootstrap() -> void:
	if _world_state == null:
		_world_state = get_node_or_null("/root/WorldState")
	_chunk_root = _resolve_chunk_root()
	if _chunk_root == null:
		push_warning("[ChunkStreamingR4] 未找到 ChunkRoot，chunk 实例暂挂本节点下。")
		_chunk_root = self
	if auto_start:
		set_player_chunk(_center)


func _process(delta: float) -> void:
	pump(delta)


func pump(delta: float) -> void:
	## 推进一帧：轮询线程加载 + 推进延迟卸载。运行时由 _process 自动调用；
	## M2 验收驱动可 set_process(false) 后显式调用，获得确定性帧步进（「可测」）。
	_poll_loads()
	_tick_unload(delta)


func _resolve_chunk_root() -> Node:
	if chunk_root_path != NodePath(""):
		var explicit: Node = get_node_or_null(chunk_root_path)
		if explicit != null:
			return explicit
	var found: Node = get_tree().root.find_child("ChunkRoot", true, false)
	return found if found != null else null


# ---------------------------------------------------------------- 公开接口（可测）

func set_player_chunk(chunk: Vector2i) -> void:
	## 玩家所在 chunk 变化时由 SceneRouter / 玩家控制器调用。
	var wanted: Array = _wanted_ids(chunk)
	if _center_initialized and chunk == _center:
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

	# 离开 3x3 的块：LOADED 进入延迟卸载；在途 LOADING 标记完成后丢弃。
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
	## 三态可测：返回 ChunkState 枚举值（UNLOADED/LOADING/LOADED），供 M2 验收读取。
	return int(_states.get(chunk_id, ChunkState.UNLOADED))


func get_loaded_chunk_ids() -> Array:
	var out: Array = []
	for raw_id in _states.keys():
		var id: String = String(raw_id)
		if is_chunk_loaded(id):
			out.append(id)
	return out


func get_load_count(chunk_id: String) -> int:
	## M2 验收：3x3 往返走之后每个出现过的 chunk_id 计数应恒为 1。
	return int(_load_count.get(chunk_id, 0))


func get_seen_chunk_ids() -> Array:
	## 返回所有曾成功加载过的 chunk_id（_load_count 的键），供验收遍历。
	return _load_count.keys()


func read_loaded_flag(chunk_id: String, default_value: bool = false) -> bool:
	## 只经 WorldState.get_flag 读 flag（I-1）；供 M2 验收 / 3 号消费。
	if _world_state == null or not _world_state.has_method("get_flag"):
		return default_value
	return bool(_world_state.call("get_flag", _flag_key(chunk_id), default_value))


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
	push_warning("[ChunkStreamingR4] %s 加载跳过：%s" % [chunk_id, reason])
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

	# 加载期间玩家已离开 3x3：实例不入树、直接丢弃，归还槽位（不产生 chunk_loaded）。
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
	## 只经 WorldState.set_flag 写 flag（I-1）；单例缺失时降级 no-op，不碰存档文件 / SaveDelta。
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
