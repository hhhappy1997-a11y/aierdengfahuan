extends CanvasLayer
## M2 的 F3 性能 HUD（1 号 R2 交付件，属随工程发行的运行时交付件，不是临时测量脚本）。
## 落位：res://scripts/ui/performance_hud.gd，M2 挂到主 viewport 的 UI 层（FX 层之上）。
## 采集：帧时间 / p99 / 常驻 chunk 数 / 静态内存；F3（action debug_perf_hud）切换显示。
## 验收口径对齐 架构设计.md §4：p99 ≤ 20 ms、单帧 ≤ 33.3 ms、chunk 载入计数恒 1、内存不单调增长。

const SAMPLE_CAPACITY: int = 240
const P99_QUANTILE: float = 0.99
const BYTES_PER_MB: float = 1048576.0

@export var hud_layer: int = 100
@export var update_interval_sec: float = 0.25

var _label: Label = null
var _samples: Array[float] = []
var _elapsed: float = 0.0
var _visible_flag: bool = false


func _ready() -> void:
	layer = hud_layer
	_label = Label.new()
	_label.name = "PerformanceHudLabel"
	_label.position = Vector2(8.0, 8.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_label.visible = false


func _process(delta: float) -> void:
	var frame_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_samples.append(frame_ms)
	if _samples.size() > SAMPLE_CAPACITY:
		_samples.remove_at(0)
	if not _visible_flag:
		return
	_elapsed += delta
	if _elapsed < update_interval_sec:
		return
	_elapsed = 0.0
	_label.text = _compose_text(frame_ms)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F3:
			_visible_flag = not _visible_flag
			_label.visible = _visible_flag
			get_viewport().set_input_as_handled()


func _compose_text(frame_ms: float) -> String:
	var resident: int = _resident_chunk_count()
	var mem_bytes: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	var mem_mb: float = mem_bytes / BYTES_PER_MB
	return "F3 性能 HUD\n帧时间 %.2f ms\np99 %.2f ms\n常驻 chunk %d\n静态内存 %.1f MB" % [
		frame_ms, _p99_frame_ms(), resident, mem_mb
	]


func _p99_frame_ms() -> float:
	if _samples.is_empty():
		return 0.0
	var sorted_samples: Array = _samples.duplicate()
	sorted_samples.sort()
	var index: int = mini(sorted_samples.size() - 1, int(float(sorted_samples.size()) * P99_QUANTILE))
	return float(sorted_samples[index])


func _resident_chunk_count() -> int:
	var cm: Node = get_node_or_null("/root/ChunkManager")
	if cm == null or not cm.has_method("get_loaded_chunk_ids"):
		return 0
	var ids: Array = cm.call("get_loaded_chunk_ids")
	return ids.size()
