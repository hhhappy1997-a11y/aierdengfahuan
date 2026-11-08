extends Node
## 场景路由 autoload（SceneRouter）—— 1 号 R2 交付件。
## 落位：res://scripts/core/scene_router.gd，注册为 autoload 单例 SceneRouter（无 class_name，
## 避免与全局脚本类冲突，见 目录与命名规范.md §3）。
##
## 加载接口归属（回应 3 号 A6）：跨场景加载 / 短加载 / 赐福传送的**唯一入口**在 SceneRouter（1 号）。
## 3 号不直接 change_scene，只调用本单例的公开方法或订阅信号；地牢内容 / 赐福网络 / 落点仍归 3 号。
##
## 边界：
##  - 只经 get_node_or_null 拿 ChunkManager / 其它单例，缺失时优雅降级，不在 _ready 硬崩。
##  - 不读写存档文件、不构造 SaveDelta、不定义 flag schema（I-1）。
##  - 不写探针 / 测量 / preflight 脚本。

signal short_load_started(dungeon_id: String, direction: String)
signal short_load_finished(dungeon_id: String)
signal grace_travel_requested(target_grace_id: String)
signal chunk_stream_paused()
signal chunk_stream_resumed()
signal quality_preset_changed(preset_path: String)

const DESKTOP_PRESET_PATH: String = "res://data/render/quality_preset_desktop.tres"
const MOBILE_PRESET_PATH: String = "res://data/render/quality_preset_mobile.tres"
const DUNGEON_SCENE_DIR: String = "res://scenes/dungeons/"

@export var active_preset_path: String = DESKTOP_PRESET_PATH

var _desktop_preset: Resource = null
var _mobile_preset: Resource = null
var _stream_paused: bool = false
var _short_load_active: bool = false
var _pending_grace_id: String = ""
var _last_direction: String = ""


func _ready() -> void:
	_load_quality_presets()


func _load_quality_presets() -> void:
	## 启动时实际加载两份画质档 Resource：既是运行时档位切换所需，也让契约 §10 第三段门禁
	## （--headless --quit）真正覆盖 .tres 的解析与加载校验，而非只做静态文本检查。
	if ResourceLoader.exists(DESKTOP_PRESET_PATH):
		_desktop_preset = ResourceLoader.load(DESKTOP_PRESET_PATH, "Resource")
	else:
		push_warning("[SceneRouter] 桌面画质档缺失：%s" % DESKTOP_PRESET_PATH)
	if ResourceLoader.exists(MOBILE_PRESET_PATH):
		_mobile_preset = ResourceLoader.load(MOBILE_PRESET_PATH, "Resource")
	else:
		push_warning("[SceneRouter] 移动画质档缺失：%s" % MOBILE_PRESET_PATH)


func pause_chunk_stream() -> void:
	## 短加载 / 传送期间暂停 3x3 流式加载，避免加载遮罩下 chunk 仍在异步进出。
	if _stream_paused:
		return
	var cm: Node = get_node_or_null("/root/ChunkManager")
	if cm != null:
		cm.set_process(false)
	_stream_paused = true
	chunk_stream_paused.emit()


func resume_chunk_stream() -> void:
	if not _stream_paused:
		return
	var cm: Node = get_node_or_null("/root/ChunkManager")
	if cm != null:
		cm.set_process(true)
	_stream_paused = false
	chunk_stream_resumed.emit()


func request_short_load(dungeon_id: String, direction: String) -> void:
	## 3 号在悬崖 / 升降机 / 地道触发体内调用；direction 为返回朝向标记（语义由 3 号定义）。
	## 1 号只负责短加载时序与信号，不定义地牢内容、不做玩法判定。
	if _short_load_active:
		return
	_short_load_active = true
	_last_direction = direction
	pause_chunk_stream()
	short_load_started.emit(dungeon_id, direction)
	var scene_path: String = DUNGEON_SCENE_DIR + dungeon_id + ".tscn"
	if ResourceLoader.exists(scene_path, "PackedScene"):
		call_deferred("_do_short_load", scene_path, dungeon_id)
	else:
		# 3 号地牢场景尚未落位：不阻塞、不伪造成功，只登记并立即结束遮罩时序。
		push_warning("[SceneRouter] 地牢场景缺失，短加载时序空跑：%s" % scene_path)
		call_deferred("_finish_short_load", dungeon_id)


func _do_short_load(scene_path: String, dungeon_id: String) -> void:
	var err: int = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_warning("[SceneRouter] change_scene_to_file 失败：%s (err=%d)" % [scene_path, err])
	_finish_short_load(dungeon_id)


func _finish_short_load(dungeon_id: String) -> void:
	_short_load_active = false
	resume_chunk_stream()
	short_load_finished.emit(dungeon_id)


func travel_to_grace(target_grace_id: String) -> void:
	## 赐福传送：1 号只发信号 + 记录目标，落点 / 存档 / 赐福网络由 3 号订阅后处理（I-1 / 3 号职责）。
	## 不读 flag schema、不直接 set_flag、不构造 SaveDelta。
	_pending_grace_id = target_grace_id
	grace_travel_requested.emit(target_grace_id)


func get_pending_grace_id() -> String:
	return _pending_grace_id


func get_last_direction() -> String:
	return _last_direction


func set_quality_preset(use_mobile: bool) -> void:
	## 桌面 / 移动双档切换：只换资源引用并发信号，不重建 SubViewport、不重载 chunk（避免帧尖峰）。
	var path: String = MOBILE_PRESET_PATH if use_mobile else DESKTOP_PRESET_PATH
	active_preset_path = path
	quality_preset_changed.emit(path)


func get_active_preset() -> Resource:
	if active_preset_path == MOBILE_PRESET_PATH:
		return _mobile_preset
	return _desktop_preset
