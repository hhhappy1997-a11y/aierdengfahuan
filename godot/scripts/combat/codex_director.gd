extends Node
## ===========================================================================
## R30 [ROUND=R30] · 赐福图鉴「成就系统运行时 + Tab 面板」
## （Rank-1，cmd-20261111-125001-344-A1，v0.8.0 新内容）
##
## 职责：
##   ① 读 Rank-2 的 res://data/rpg/codex_entries.tres（并发时序下可能尚未落盘 →
##      降级为内置 4 项默认并 push_warning 如实登记，不崩、不产生 SCRIPT ERROR）；
##   ② 订阅既有三段式 flag（事件驱动，绝不每帧轮询）：
##        grace.tutorial.completed / dungeon.wave_trial.completed /
##        dungeon.wave_trial.best_wave / grace.upgrade_<id>.unlocked ×3；
##   ③ 判定 4 类成就（教学完成 / 三波全清 / 三项增益全解锁 / 最高波次 ≥3），
##      达成写 grace.codex_<id>.unlocked（裁决 A36 三段式，false→true 单向、
##      绝不回写 false） + commit("codex_unlocked") 严格「先落盘再改运行时实例」；
##   ④ 信号 codex_entry_unlocked(id,title) / codex_progress_changed(unlocked,total)；
##   ⑤ Tab 键（KEY_TAB，不与教学 T 键冲突）开关图鉴面板：运行时建独立 CanvasLayer，
##      不写 courtyard.tscn 任何场景节点（裁决 A35，静态节点数保持 41）。
##
## 运行时挂载：由 hud.gd 在真实 courtyard 场景里 call_deferred("add_child") 挂到
##   SubViewportContainer 的父节点（Courtyard，SubViewport 之外，不受 stretch_shrink 缩放）；
##   独立 hud.tscn 实例（--script 验证）不建本节点，既有 58/30/11/127 PASS 逐字不回退。
## 依赖注入：injected_state / injected_writer 供 verify_codex_v080.gd 在 --script 模式下
##   注入内存 WorldState + FakeWriter（不污染 user:// 存档、不伪造落盘）。
##
## --script 模式纪律（项目既有踩坑）：不用 /root/... 绝对路径（一律
##   Engine.get_main_loop() / root.get_node_or_null() 相对探活）；add_child 一律
##   call_deferred 或由挂载方 deferred，避免 "Parent node is busy setting up children"。
## 面板位置 [PLACEHOLDER] 待试玩目视校准（rationale：见 CODEX_RECT_* 逐项避让推导）。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。
## ===========================================================================

signal codex_entry_unlocked(id: String, title: String)
signal codex_progress_changed(unlocked: int, total: int)

# ---- 既有三段式来源 flag（只读，绝不改 world_state.gd 正则）----
const F_TUTORIAL_COMPLETED: String = "grace.tutorial.completed"
const F_TRIAL_COMPLETED: String = "dungeon.wave_trial.completed"
const F_BEST_WAVE: String = "dungeon.wave_trial.best_wave"
const FLAG_UPGRADE_PREFIX: String = "grace.upgrade_"
const FLAG_UPGRADE_SUFFIX: String = ".unlocked"
# 三项增益 id 取自既有 res://data/rpg/grace_upgrades.tres（不硬编码名称/数值）。
const UPGRADE_IDS: Array[String] = ["hp_max_bonus", "roll_iframe_bonus", "attack_power_bonus"]
const BEST_WAVE_TARGET: int = 3

# ---- 成就 flag / 落盘 reason（裁决 A36：grace.codex_<id>.unlocked 三段式）----
const FLAG_CODEX_PREFIX: String = "grace.codex_"
const FLAG_CODEX_SUFFIX: String = ".unlocked"
const COMMIT_REASON: String = "codex_unlocked"
const CODEX_ENTRIES_PATH: String = "res://data/rpg/codex_entries.tres"

# ---- 内置 4 项默认（Rank-2 .tres 未落盘 / 加载失败 / 结构不完整时降级用）----
# id 用下划线连接（A36 / A23 口径），condition 为内部判定标识，四段字面废止。
const DEFAULT_ENTRIES: Array = [
	{"id": "tutorial_complete", "title": "赐福入门", "description": "完成赐福引导教学", "condition": "tutorial_complete"},
	{"id": "trial_cleared", "title": "三波全清", "description": "通关三波试炼", "condition": "trial_cleared"},
	{"id": "all_upgrades", "title": "增益圆满", "description": "解锁全部三项增益", "condition": "all_upgrades"},
	{"id": "best_wave_ge3", "title": "百战之证", "description": "最高波次达到 3 波", "condition": "best_wave_ge3"},
]

# ---- Tab 面板布局（避开 6 套 HUD + 玩家/Boss 包围盒，见 verify 几何断言）----
# courtyard.tscn 实读坐标：赐福 HUD x<730,y<220；画质面板 x>760,y<180；
#   波次 WaveLabel (24,232)-(720,264)；教学 TutorialLabel (24,520)-(1100,556)；
#   兑换面板（R29 运行时迁出）(740,358)-(1276,568)；底部 StatusLabel (24,660)-(1224,692)；
#   玩家 (400,320)-(690,570)；Boss (645,230)-(880,350)。
# 取左侧竖条 x∈[24,380]（right=380 < 玩家左沿 400 / Boss 左沿 645 / 兑换面板左沿 740），
#   y∈[272,508]（top=272 > 波次 HUD 下沿 264 / 赐福 HUD 下沿 220，
#   bottom=508 < 教学 HUD 上沿 520 / 底部 HUD 上沿 660）→ 与 8 个矩形几何交集恒为 0。
const CODEX_LAYER_NAME: String = "CodexPanelLayer"
const CODEX_LAYER_INDEX: int = 46          # 高于 QualitySettings=40 / 兑换层=45 / HUD=20
const CODEX_BG_COLOR: Color = Color(0.04, 0.06, 0.12, 0.30)   # alpha 0.30 ≤ 0.35
const CODEX_BORDER_COLOR: Color = Color(0.83, 0.68, 0.3, 0.55)
const GOLD: Color = Color(0.83, 0.68, 0.3, 1.0)               # 已达成高亮
const DIM: Color = Color(0.55, 0.54, 0.50, 1.0)               # 未达成
const FONT_SIZE: int = 14
const CODEX_RECT_LEFT: float = 24.0
const CODEX_RECT_TOP: float = 272.0
const CODEX_RECT_RIGHT: float = 380.0
const CODEX_RECT_BOTTOM: float = 508.0

# ---- 可注入（验证 / 装配用）----
var codex_entries_path: String = CODEX_ENTRIES_PATH
var injected_state: Node = null
var injected_writer: Node = null

# ---- 运行期状态（如实登记，不伪造）----
var entries_source: String = "unknown"          # "tres" / "builtin_default"
var degraded: bool = false
var degrade_reasons: Array[String] = []
var unlock_events: Array[String] = []           # 顺序证据：stage_flags → disk_write → runtime_update
var commit_count: int = 0
var _entries: Array = []
var _source_keys: Dictionary = {}
var _unlocked: Dictionary = {}                  # id -> true，只增不减（单向）
var _state: Node = null
var _writer: Node = null
var _evaluating: bool = false                  # 防 delta_committed 在 commit 内同步重入
var _layer: CanvasLayer = null
var _panel: Panel = null
var _title_label: Label = null
var _rows: Array = []
var _progress_label: Label = null
var _id_re: RegEx = null

# ==========================================================================
# 1) 生命周期 / 依赖绑定
# ==========================================================================

func _ready() -> void:
	_resolve_deps()
	_load_entries()
	_build_source_keys()
	_subscribe()
	_restore_unlocked()
	# 真实场景的 _ready 传播期 add_child 会报 "busy setting up children"，
	# 面板建层一律 deferred；--script 验证可调 build_panel_now() 同步建好。
	call_deferred("_deferred_build_panel")
	evaluate()
	print("[R30][CODEX] ready | source=%s entries=%d degraded=%s | 面板 deferred 建层(独立 CanvasLayer，不写场景)" % [
			entries_source, _entries.size(), str(degraded)])


## 依赖探活：注入优先（--script 验证）→ 否则经 Engine.get_main_loop()/root 相对探活
## （不用 /root/... 绝对路径，项目既有踩坑口径）。缺失一律登记降级、不崩。
func _resolve_deps() -> void:
	_state = injected_state
	_writer = injected_writer
	if _state == null:
		var ml: MainLoop = Engine.get_main_loop()
		if ml is SceneTree:
			_state = (ml as SceneTree).root.get_node_or_null(NodePath("WorldState"))
	if _writer == null:
		var ml2: MainLoop = Engine.get_main_loop()
		if ml2 is SceneTree:
			_writer = (ml2 as SceneTree).root.get_node_or_null(NodePath("SaveDeltaWriter"))
	if _state == null:
		_degrade("WorldState 未就绪：成就判定只读默认值、达成 flag 仅进程内（降级，不崩）")
	if _writer == null:
		_degrade("SaveDeltaWriter 未就绪：达成 flag 仅进程内内存、未落盘（降级，不崩）")
	set_process_unhandled_input(true)


# ==========================================================================
# 2) 图鉴条目加载（Rank-2 .tres；缺失 / 失败 / 结构不全一律降级内置 4 项）
# ==========================================================================

func _load_entries() -> void:
	_entries = DEFAULT_ENTRIES.duplicate(true)
	entries_source = "builtin_default"
	if not ResourceLoader.exists(codex_entries_path):
		_degrade("Rank-2 图鉴资源未落盘：%s → 降级为内置 4 项默认（并发时序，如实登记，不崩）" % codex_entries_path)
		return
	var res: Resource = ResourceLoader.load(codex_entries_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	if res == null:
		_degrade("Rank-2 图鉴资源加载失败：%s → 降级为内置 4 项默认" % codex_entries_path)
		return
	var raw: Variant = _pick_array(res, ["entries", "items", "codex_entries"])
	if raw == null or (raw as Array).size() < _entries.size():
		_degrade("Rank-2 图鉴资源无 4 项条目 → 降级为内置 4 项默认")
		return
	var arr: Array = raw as Array
	# 条件判定由本运行时按任务单 4 类硬规定执行（不依赖 Rank-2 的条件字段）；
	# 仅以 .tres 的 id / title / description 覆盖显示与三段式 key 的 id 段（容错多字段名）。
	for i: int in range(_entries.size()):
		var item: Variant = arr[i]
		var tid: String = _field_str(item, ["id", "entry_id", "codex_id"])
		var ttitle: String = _field_str(item, ["title", "display_name", "name"])
		var tdesc: String = _field_str(item, ["description", "desc", "detail"])
		if _is_valid_id(tid):
			_entries[i]["id"] = tid
		if not ttitle.is_empty():
			_entries[i]["title"] = ttitle
		if not tdesc.is_empty():
			_entries[i]["description"] = tdesc
	entries_source = "tres"
	print("[R30][CODEX] 读到 Rank-2 图鉴资源 entries=%d（显示文本/ id 覆盖内置默认，条件仍按 4 类判定）" % arr.size())


## 从 Resource 里按候选属性名取第一个非空 Array（兼容 Rank-2 多种结构）。
func _pick_array(res: Resource, names: Array) -> Variant:
	for n: Variant in names:
		var v: Variant = res.get(String(n))
		if v != null and typeof(v) == TYPE_ARRAY and not (v as Array).is_empty():
			return v
	return null


## 从 Dictionary / Object 里按候选字段名取第一个非空字符串。
func _field_str(v: Variant, names: Array) -> String:
	for n: Variant in names:
		var val: Variant = null
		if typeof(v) == TYPE_DICTIONARY:
			val = (v as Dictionary).get(String(n), null)
		elif v is Object:
			val = (v as Object).get(String(n))
		if val != null and not String(val).is_empty():
			return String(val)
	return ""


## id 段合法性：小写字母 / 数字 / 下划线（保证 grace.codex_<id>.unlocked 三段式正则通过）。
func _is_valid_id(s: String) -> bool:
	if s.is_empty():
		return false
	if _id_re == null:
		_id_re = RegEx.new()
		_id_re.compile("^[a-z0-9_]+$")
	return _id_re.search(s) != null


func _degrade(reason: String) -> void:
	degraded = true
	degrade_reasons.append(reason)
	push_warning("[R30][CODEX] " + reason)


# ==========================================================================
# 3) 三段式订阅（事件驱动，绝不每帧轮询）
# ==========================================================================

func _build_source_keys() -> void:
	_source_keys.clear()
	_source_keys[F_TUTORIAL_COMPLETED] = true
	_source_keys[F_TRIAL_COMPLETED] = true
	_source_keys[F_BEST_WAVE] = true
	for id: String in UPGRADE_IDS:
		_source_keys[upgrade_key(id)] = true


func _subscribe() -> void:
	if _state == null:
		return
	var cb_changed: Callable = Callable(self, "_on_flag_changed")
	if _state.has_signal("flag_changed") and not _state.is_connected("flag_changed", cb_changed):
		_state.connect("flag_changed", cb_changed)
	var cb_committed: Callable = Callable(self, "_on_delta_committed")
	if _state.has_signal("delta_committed") and not _state.is_connected("delta_committed", cb_committed):
		_state.connect("delta_committed", cb_committed)


func _on_flag_changed(key: String, _old_value: Variant, _new_value: Variant) -> void:
	if _source_keys.has(key):
		evaluate()


func _on_delta_committed(_seq: int, _reason: String) -> void:
	# 存档回放 / 跨场景注入兜底一次全量；commit 内部同步触发时由 _evaluating 拦重入。
	evaluate()


## 重启恢复：从 WorldState 读回已落盘的 codex_<id>.unlocked，只恢复运行时镜像（不回写、
## 不重复落盘、不发逐项解锁信号），并发一次初始进度。
func _restore_unlocked() -> void:
	if _state != null and _state.has_method("get_flag"):
		for v: Variant in _entries:
			var e: Dictionary = v as Dictionary
			var id: String = String(e.get("id", ""))
			if not id.is_empty() and bool(_state.call("get_flag", codex_key(id), false)):
				_unlocked[id] = true
	codex_progress_changed.emit(_unlocked.size(), _entries.size())


# ==========================================================================
# 4) 4 类成就判定 + 单向解锁 + 「先落盘再改运行时实例」
# ==========================================================================

func codex_key(id: String) -> String:
	return FLAG_CODEX_PREFIX + id + FLAG_CODEX_SUFFIX


func upgrade_key(id: String) -> String:
	return FLAG_UPGRADE_PREFIX + id + FLAG_UPGRADE_SUFFIX


func _flag(key: String, default_value: Variant) -> Variant:
	if _state == null or not _state.has_method("get_flag"):
		return default_value
	return _state.call("get_flag", key, default_value)


func _condition_met(e: Dictionary) -> bool:
	match String(e.get("condition", "")):
		"tutorial_complete":
			return bool(_flag(F_TUTORIAL_COMPLETED, false))
		"trial_cleared":
			return bool(_flag(F_TRIAL_COMPLETED, false))
		"all_upgrades":
			if UPGRADE_IDS.is_empty():
				return false
			for id: String in UPGRADE_IDS:
				if not bool(_flag(upgrade_key(id), false)):
					return false
			return true
		"best_wave_ge3":
			return int(_flag(F_BEST_WAVE, 0)) >= BEST_WAVE_TARGET
	return false


## 一次全量判定。返回本次新解锁的 id 数组。严格顺序：
##   ① set_flag 入队（stage_flags）→ commit("codex_unlocked") 原子写（disk_write）；
##   ② 落盘成功后【才】改运行时镜像 / 发信号（runtime_update）。
## 单向：_unlocked 只增不减，绝不回写 false；重复达成因 _unlocked 命中直接跳过，不双写。
## 降级（writer 缺失）：如实登记「未落盘」，仍推进进程内镜像（与 tutorial_director 同口径）。
func evaluate() -> Array[String]:
	var newly: Array[String] = []
	if _evaluating:
		return newly
	_evaluating = true
	var to_write: Array[String] = []
	for v: Variant in _entries:
		var e: Dictionary = v as Dictionary
		var id: String = String(e.get("id", ""))
		if id.is_empty() or _unlocked.has(id):
			continue
		if _condition_met(e):
			to_write.append(id)
	if not to_write.is_empty():
		var can_flag: bool = _state != null and _state.has_method("set_flag")
		if can_flag:
			for id: String in to_write:
				unlock_events.append("stage_flags:" + id)
				_state.call("set_flag", codex_key(id), true)
		if _writer != null and _writer.has_method("commit"):
			_writer.call("commit", COMMIT_REASON)
			commit_count += 1
			unlock_events.append("disk_write:" + COMMIT_REASON)
		else:
			_degrade("达成 flag 未落盘：SaveDeltaWriter 不可用，仅进程内内存（如实登记，不冒充原子写）")
			unlock_events.append("disk_write_downgrade:" + COMMIT_REASON)
		# ★ 落盘（或如实降级登记）之后才改运行时实例 / 发信号。
		for id: String in to_write:
			_mark_unlocked_runtime(id)
			unlock_events.append("runtime_update:" + id)
			newly.append(id)
		_refresh_panel()
	_evaluating = false
	return newly


func _mark_unlocked_runtime(id: String) -> void:
	_unlocked[id] = true
	var title: String = ""
	for v: Variant in _entries:
		var e: Dictionary = v as Dictionary
		if String(e.get("id", "")) == id:
			title = String(e.get("title", ""))
			break
	codex_entry_unlocked.emit(id, title)
	codex_progress_changed.emit(_unlocked.size(), _entries.size())
	print("[R30][CODEX][UNLOCK] id=%s title=%s progress=%d/%d reason=%s" % [
			id, title, _unlocked.size(), _entries.size(), COMMIT_REASON])


# ==========================================================================
# 5) Tab 面板：运行时独立 CanvasLayer（不写 courtyard.tscn，节点数保持 41）
# ==========================================================================

func build_panel_now() -> void:
	_build_panel()


func _deferred_build_panel() -> void:
	if _layer == null or not is_instance_valid(_layer):
		_build_panel()


func _build_panel() -> void:
	if _layer != null and is_instance_valid(_layer):
		_refresh_panel()
		return
	# CanvasLayer 挂在 director 自身下：director 位于 Courtyard（SubViewport 之外），
	# 故该层同在根 viewport、不受 stretch_shrink 缩放；生命周期与 director 一致
	# （free 时一并释放），也不依赖父节点是否处于 _ready 传播期。
	var mount: Node = self
	_layer = CanvasLayer.new()
	_layer.name = CODEX_LAYER_NAME
	_layer.layer = CODEX_LAYER_INDEX
	mount.add_child(_layer)
	_panel = Panel.new()
	_panel.name = "CodexPanel"
	_panel.offset_left = CODEX_RECT_LEFT
	_panel.offset_top = CODEX_RECT_TOP
	_panel.offset_right = CODEX_RECT_RIGHT
	_panel.offset_bottom = CODEX_RECT_BOTTOM
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = CODEX_BG_COLOR
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(1)
	sb.border_color = CODEX_BORDER_COLOR
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	_panel.add_theme_stylebox_override("panel", sb)
	_layer.add_child(_panel)

	_title_label = _make_label("CodexTitle")
	_title_label.offset_left = 12.0
	_title_label.offset_top = 6.0
	_title_label.offset_right = CODEX_RECT_RIGHT - CODEX_RECT_LEFT - 12.0
	_title_label.offset_bottom = 30.0
	_panel.add_child(_title_label)
	for i: int in range(_entries.size()):
		var row: Label = _make_label("CodexRow%d" % i)
		row.offset_left = 12.0
		row.offset_top = 36.0 + float(i) * 26.0
		row.offset_right = CODEX_RECT_RIGHT - CODEX_RECT_LEFT - 12.0
		row.offset_bottom = 60.0 + float(i) * 26.0
		_rows.append(row)
		_panel.add_child(row)
	_progress_label = _make_label("CodexProgress")
	_progress_label.offset_left = 12.0
	_progress_label.offset_top = 150.0
	_progress_label.offset_right = CODEX_RECT_RIGHT - CODEX_RECT_LEFT - 12.0
	_progress_label.offset_bottom = 176.0
	_panel.add_child(_progress_label)

	_layer.visible = false           # 默认隐藏（首帧不出现半透明矩形）
	_refresh_panel()
	print("[R30][CODEX][PANEL] 独立 CanvasLayer(layer=%d) 建层 | rect=(%.0f,%.0f)-(%.0f,%.0f) alpha=%.2f | 默认隐藏 | 不写 courtyard.tscn" % [
			CODEX_LAYER_INDEX, CODEX_RECT_LEFT, CODEX_RECT_TOP, CODEX_RECT_RIGHT, CODEX_RECT_BOTTOM, CODEX_BG_COLOR.a])


func _make_label(n: String) -> Label:
	var l: Label = Label.new()
	l.name = n
	l.add_theme_font_size_override("font_size", FONT_SIZE)
	l.add_theme_color_override("font_color", DIM)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.06, 1.0))
	l.add_theme_constant_override("outline_size", 3)
	return l


## 刷新 4 项名称 / 描述 / 已达成高亮（GOLD）/ 进度 n/4。
func _refresh_panel() -> void:
	if _panel == null or not is_instance_valid(_panel):
		return
	if _title_label != null:
		_title_label.text = "赐福图鉴　[Tab 开关]"
	for i: int in range(_entries.size()):
		if i >= _rows.size():
			break
		var e: Dictionary = _entries[i] as Dictionary
		var got: bool = is_unlocked(String(e.get("id", "")))
		var mark: String = "✓" if got else "○"
		var row: Label = _rows[i] as Label
		row.text = "%s %s｜%s" % [mark, String(e.get("title", "")), String(e.get("description", ""))]
		row.add_theme_color_override("font_color", GOLD if got else DIM)
	if _progress_label != null:
		_progress_label.text = "进度 %d/%d" % [_unlocked.size(), _entries.size()]


func toggle_panel() -> void:
	if _layer == null or not is_instance_valid(_layer):
		_build_panel()
	if _layer == null or not is_instance_valid(_layer):
		return
	_layer.visible = not _layer.visible
	print("[R30][CODEX][TAB] toggle → visible=%s" % str(_layer.visible))


func is_panel_open() -> bool:
	return _layer != null and is_instance_valid(_layer) and _layer.visible


func get_panel_rect() -> Rect2:
	if _panel == null or not is_instance_valid(_panel):
		return Rect2()
	return Rect2(_panel.offset_left, _panel.offset_top,
			_panel.offset_right - _panel.offset_left,
			_panel.offset_bottom - _panel.offset_top)


func get_panel_alpha() -> float:
	return CODEX_BG_COLOR.a


func get_row_color(index: int) -> Color:
	if index < 0 or index >= _rows.size():
		return Color()
	var row: Label = _rows[index] as Label
	return row.get_theme_color("font_color", "Label")


func get_row_text(index: int) -> String:
	if index < 0 or index >= _rows.size():
		return ""
	return (_rows[index] as Label).text


func get_progress_text() -> String:
	return "" if _progress_label == null else _progress_label.text


func get_layer_index() -> int:
	return -1 if _layer == null or not is_instance_valid(_layer) else _layer.layer


func get_layer_name() -> String:
	return "" if _layer == null or not is_instance_valid(_layer) else String(_layer.name)


func get_layer_parent_name() -> String:
	if _layer == null or not is_instance_valid(_layer):
		return ""
	var p: Node = _layer.get_parent()
	return "" if p == null else String(p.name)


## Tab（KEY_TAB=4194306）开关图鉴；不与教学 T 键（84）冲突。处理完 set_input_as_handled，
## 避免同一事件再被其它 _unhandled_input 节点消费。
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k: InputEventKey = event as InputEventKey
	if k.pressed and not k.echo and (k.keycode == KEY_TAB or k.physical_keycode == KEY_TAB):
		toggle_panel()
		var vp: Viewport = get_viewport()
		if vp != null:
			vp.set_input_as_handled()


# ==========================================================================
# 6) 只读接口（供 HUD / 验证读回，绝不改状态）
# ==========================================================================

func get_entries() -> Array:
	return _entries.duplicate(true)


func get_progress() -> Dictionary:
	return {"unlocked": _unlocked.size(), "total": _entries.size()}


func is_unlocked(id: String) -> bool:
	return bool(_unlocked.get(id, false))


func get_unlock_events() -> Array:
	return unlock_events.duplicate()


func get_status() -> Dictionary:
	return {
		"source": entries_source,
		"degraded": degraded,
		"reasons": degrade_reasons.duplicate(),
		"commits": commit_count,
		"unlocked": _unlocked.size(),
		"total": _entries.size(),
		"panel_open": is_panel_open(),
	}
