extends CanvasLayer

## R16 · HUD ↔ WorldState / 赐福网络 数据绑定（Rank-3，cmd-20261109-085736-027-A3）。
## R21 · 统一存档快旅口径（Rank-3，cmd-20261109-115818-643-A3）：
##   grace_fast_travel() 与 travel_to() 统一优先取 /root/SaveDeltaWriter，注入 committer 仅兜底。
## 挂载点：res://scenes/hud.tscn 根节点 Hud（CanvasLayer），与场景根节点类型一致。
##
## I-1 边界（SAVE-SPEC-FINAL.md §3 / HUD-BINDING.md §2.4）：
##   HUD 只读 WorldState.get_flag(key, default)；不 set_flag、不构造 / 解析 SaveDelta、
##   不 FileAccess 读写 user://saves/、不 ResourceLoader 加载存档、不 JSON.parse 存档、
##   不调用 WorldState 内部方法（_commit_delta 等）。
##   grace_fast_travel 的「原子落盘」由 3 号内部件 SaveDeltaWriter.commit(reason) 完成，
##   HUD 只编排「先落盘、后发信号」的顺序，自己不实现 commit 逻辑。
##
## 刷新策略：事件驱动（flag_changed / delta_committed 信号）+ _ready() 一次全量，
##   禁止在 _process() / _physics_process() 里每帧轮询 get_flag。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

# ==========================================================================
# 4 个信号（HUD → 外部，沿用 HUD-BINDING.md §3.2 草案）
# ==========================================================================
signal grace_selected(target_grace_id: String)     # 菜单选中某个已解锁赐福（仅 UI 事件）
signal travel_confirmed(target_grace_id: String)   # 确认传送；等价触发 GameEvents.travel_requested
signal rest_requested(grace_id: String)            # 请求休息（→ grace_rest 落盘，由 3 号状态机处理）
signal hud_refreshed()                             # 一次完整 refresh_all() 完成（自检 / 调试）

# ==========================================================================
# 常量
# ==========================================================================
const LAST_GRACE_KEY: String = "grace.network.last_grace_id"   # 三段式，已登记常量，不拼接
const TITLE_PREFIX: String = "赐福 · "
const TITLE_PLACEHOLDER: String = "赐福 · 宁姆格福"             # last_grace_id 空值回退占位
const GOLD: Color = Color(0.83, 0.68, 0.3, 1.0)              # 与 hud.tscn 落盘金色一致
const DIM: Color = Color(0.45, 0.42, 0.34, 1.0)               # 未点亮运行期暗色
# R27 [ROUND=R27] 赐福点亮态的三段式 flag 来源（数据驱动，不硬编码颜色切换条件）：
#   试炼完成：dungeon.wave_trial.completed（bool，false→true 单向）
#   赐福休息：grace.network.last_rest_epoch（int，每次休息 +1，>0 表示已休息）
# 只登记「读哪些 flag」，颜色切换统一交给既有 apply_lit_state(lit)（GOLD / DIM）。
const LIT_FLAG_TRIAL_COMPLETED: String = "dungeon.wave_trial.completed"
const LIT_FLAG_REST_EPOCH: String = "grace.network.last_rest_epoch"
const LIT_SOURCE_FLAGS: Array[String] = [LIT_FLAG_TRIAL_COMPLETED, LIT_FLAG_REST_EPOCH]
# 对齐 chunk_world_bridge.gd:43 const REASON_FAST_TRAVEL
const REASON_FAST_TRAVEL: String = "grace_fast_travel"
# R19/R20：SaveDeltaWriter 的 autoload 注册键与 /root 路径。R20 起已正式注册为 autoload，
# R21 起供 travel_to() / grace_fast_travel() 两入口统一优先解析真实节点、
# 供 get_commit_status() 如实读回注册态。
const WRITER_AUTOLOAD_KEY: String = "autoload/SaveDeltaWriter"
const WRITER_ROOT_PATH: String = "/root/SaveDeltaWriter"

# ---- R27B · 赐福成长购买入口（裁决 A23 三段式收敛 / A24 增益运行时接线）----
const GRACE_CONFIG_PATH: String = "res://data/rpg/grace_upgrades.tres"
const FLAG_POINTS: String = "grace.trial.points"
const FLAG_SPENT_POINTS: String = "grace.trial.spent_points"
## 裁决 A23：grace.upgrade_<id>.unlocked 三段式收敛有效，四段字面废止，不改 world_state.gd 正则。
const FLAG_UNLOCKED_PREFIX: String = "grace.upgrade_"
const FLAG_UNLOCKED_SUFFIX: String = ".unlocked"
const COMMIT_REASON_PURCHASED: String = "grace_upgrade_purchased"

# ==========================================================================
# 依赖注入 / 运行期引用
# ==========================================================================
@export var grace_network_path: String = "res://data/rpg/grace_network.tres"
## R27B：挂载的增益运行时节点（courtyard.tscn 覆盖真机相对路径）与兑换面板 Label。
## 默认空 NodePath 使 hud.tscn 的独立实例（既有回归）判空降级，不崩、不改 hud.tscn 结构。
@export var grace_runtime_path: NodePath = ^""
@export var shop_label_path: NodePath = ^"GraceShopLabel"

var _world_state: Node = null            # /root/WorldState（autoload）
var _net: Resource = null                # GraceNetwork（8 节点 / 7 边，运行期唯一数据源）
var _title_label: Label = null           # hud.tscn 内 TitleLabel
var _bound_keys: Dictionary = {}          # 绑定集合：flag_changed 增量命中判定
var _menu: Array[Dictionary] = []        # 赐福菜单数据快照（无 UI 容器节点，供后续 UI 消费）
var fast_travel_committer: Callable = Callable()  # 可注入：func(reason: String) -> void，默认未注入

# ---- R19 · 赐福菜单运行期统计 / SaveDeltaWriter 降级登记（如实，不伪造 autoload）----
var grace_node_count: int = 0                 # open_grace_menu() 运行期从 .tres 读到的 nodes.size()
var grace_edge_count: int = 0                 # open_grace_menu() 运行期从 .tres 读到的 edges.size()
var menu_open: bool = false                   # 菜单是否已打开（仅内存态，不改 hud.tscn 结构）
var commit_degraded: bool = false             # 最近一次落盘（travel_to / grace_fast_travel 共用）是否走了「非 autoload」降级
var last_commit_source: String = "none"       # "autoload" / "injected" / "none"（如实登记）
var last_commit_reason: String = ""           # 最近一次 commit 的 reason
var last_commit_ok: bool = false              # 最近一次是否真的先落盘
var commit_log: Array[String] = []            # 逐次落盘登记（供自检 / 回执引用）

# ---- R27B 购买入口运行期状态（既有 1~7 节逻辑逐字未动）----
var _shop_label: Label = null                 # courtyard.tscn 新增的 GraceShopLabel
var shop_open: bool = false                   # 兑换面板开关（仅内存态）
var shop_message: String = "按 E 打开赐福成长兑换；数字键 1 / 2 / 3 选择"
var grace_purchase_events: Array[String] = [] # 顺序证据：stage_flags → disk_write → runtime_update
var _grace_ws: Node = null                    # 注入优先（验证），否则场景探活
var _grace_writer: Node = null
var _grace_runtime: Node = null
var _grace_encounter: Node = null

# ==========================================================================
# 1) 生命周期 / 依赖绑定
# ==========================================================================

func _ready() -> void:
	_title_label = get_node_or_null("TitleLabel") as Label
	load_grace_network(grace_network_path)
	# R27B：--script / SceneTree 模式下 add_child 不 flush data.tree，/root/... 绝对路径会触发
	#   "Can't use get_node() with absolute paths from outside the active scene tree"。
	#   改用 Engine.get_main_loop() + root.get_node_or_null() 相对探活（项目既有踩坑口径）；
	#   真机场景等价命中同一 autoload WorldState，既有 30/31 PASS 绑定链路不变。
	var ml: MainLoop = Engine.get_main_loop()
	var ws_root: Node = null
	if ml is SceneTree:
		ws_root = (ml as SceneTree).root.get_node_or_null(NodePath("WorldState"))
	bind_world_state(ws_root)
	# 一次初始化全量刷新：内部所有 WorldState.get_flag(key, default) 均显式传业务默认值
	refresh_all()
	# R27B：绑定兑换面板 Label / 增益运行时节点并启用输入；依赖缺失判空降级、不崩。
	_shop_label = get_node_or_null(shop_label_path) as Label
	if _grace_runtime == null and not grace_runtime_path.is_empty():
		_grace_runtime = get_node_or_null(grace_runtime_path)
	set_process_unhandled_input(true)
	_refresh_shop_hud()


## 注入 WorldState 引用并连信号；重复绑定先断开旧连接，避免重复回调。
func bind_world_state(ws: Node) -> void:
	if _world_state == ws:
		return
	if _world_state != null and is_instance_valid(_world_state):
		if _world_state.has_signal("flag_changed") and _world_state.is_connected("flag_changed", Callable(self, "_on_flag_changed")):
			_world_state.disconnect("flag_changed", Callable(self, "_on_flag_changed"))
		if _world_state.has_signal("delta_committed") and _world_state.is_connected("delta_committed", Callable(self, "_on_delta_committed")):
			_world_state.disconnect("delta_committed", Callable(self, "_on_delta_committed"))
	_world_state = ws
	if _world_state == null:
		push_warning("[HUD] 未找到 /root/WorldState，走只读占位（TitleLabel 显示占位文本）")
		return
	# 事件驱动：订阅 flag_changed（增量）与 delta_committed（回放 / 注入兜底全量）
	if _world_state.has_signal("flag_changed"):
		_world_state.connect("flag_changed", Callable(self, "_on_flag_changed"))
	if _world_state.has_signal("delta_committed"):
		_world_state.connect("delta_committed", Callable(self, "_on_delta_committed"))


## load .tres 一次并缓存，取 nodes / edges，建立绑定集合；不硬编码任何赐福名 / 边。
func load_grace_network(path: String) -> void:
	_net = null
	_bound_keys.clear()
	_bound_keys[LAST_GRACE_KEY] = true
	# R27：把「试炼完成 / 赐福休息」两段三段式 flag 登记进增量命中集合，
	# 使其成为事件驱动的点亮来源（订阅 flag_changed，不每帧轮询）。
	for k: String in LIT_SOURCE_FLAGS:
		_bound_keys[k] = true
	if not ResourceLoader.exists(path):
		push_warning("[HUD] 赐福网络资源不存在：%s" % path)
		return
	var res: Resource = ResourceLoader.load(path, "Resource", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	if res == null:
		push_warning("[HUD] 赐福网络加载失败：%s" % path)
		return
	_net = res
	for n in _grace_nodes():
		var node: Resource = n as Resource
		if node == null:
			continue
		_bound_keys[String(node.get("lit_flag"))] = true
		_bound_keys[String(node.get("unlocked_flag"))] = true

# ==========================================================================
# 2) flag 读取与刷新（对应 HUD-BINDING.md §1.4 / §1.5）
# ==========================================================================

## 唯一的 flag 读取入口：等价于 WorldState.get_flag(key, default)，
## 显式传业务默认值（String → ""、bool → false），绝不依赖 default = null 形参默认。
func _flag(key: String, default: Variant) -> Variant:
	if _world_state == null or not _world_state.has_method("get_flag"):
		return default
	return _world_state.call("get_flag", key, default)


## 一次全量刷新：_ready / delta_committed / 场景切换后。读取 → 比对 → 赋值，幂等。
func refresh_all() -> void:
	var last_id: String = String(_flag(LAST_GRACE_KEY, ""))       # 显式 default=""
	set_title_from_grace(last_id)
	# 全量：逐节点读 lit / unlocked（显式 default=false），重建点亮态与菜单数据快照
	var lit: bool = false
	for n in _grace_nodes():
		var node: Resource = n as Resource
		if node == null:
			continue
		var node_lit: bool = bool(_flag(String(node.get("lit_flag")), false))        # 显式 default=false
		var _node_unlocked: bool = bool(_flag(String(node.get("unlocked_flag")), false))  # 显式 default=false
		if String(node.get("grace_id")) == last_id:
			lit = node_lit
	apply_lit_state(lit)
	_menu = build_grace_menu()
	hud_refreshed.emit()


## flag_changed 命中的单 key 增量刷新：只动受该 key 影响的 UI 属性，不全量重算。
func refresh_label(key: String) -> void:
	if key == LAST_GRACE_KEY:
		set_title_from_grace(String(_flag(LAST_GRACE_KEY, "")))   # 显式 default=""
		return
	# R27：试炼完成 / 赐福休息 flag 变化 → 读三段式 flag 汇总点亮态，由
	# apply_lit_state(lit) 统一完成「暗灰 → 亮金」切换（本处不硬编码颜色条件）。
	if LIT_SOURCE_FLAGS.has(key):
		apply_lit_state(_read_lit_sources())
		return
	for n in _grace_nodes():
		var node: Resource = n as Resource
		if node == null:
			continue
		var lit_flag: String = String(node.get("lit_flag"))
		if key == lit_flag:
			# 仅当该节点是当前赐福时才改点亮态，避免无关 flag 误刷
			if String(node.get("grace_id")) == String(_flag(LAST_GRACE_KEY, "")):
				apply_lit_state(bool(_flag(lit_flag, false)))     # 显式 default=false
			return
		if key == String(node.get("unlocked_flag")):
			_menu = build_grace_menu()                          # 解锁态变化 → 菜单快照增量重建
			return


func _on_flag_changed(key: String, _old_value: Variant, _new_value: Variant) -> void:
	# 事件驱动增量刷新：仅命中绑定集合才刷新，禁止每帧轮询
	if _bound_keys.has(key):
		refresh_label(key)


func _on_delta_committed(_seq: int, _reason: String) -> void:
	# 存档回放 / 跨场景注入后兜底一次全量刷新（防信号丢失 / 回放注入不一致）
	refresh_all()

# ==========================================================================
# 3) 金色 Label 绑定（对应 HUD-BINDING.md §1.3）
# ==========================================================================

## TitleLabel.text = "赐福 · " + nodes[*].display_name；空值 / 查不到回退静态占位。
func set_title_from_grace(grace_id: String) -> void:
	var text: String = TITLE_PLACEHOLDER
	if not grace_id.is_empty():
		var node: Resource = _find_grace(grace_id)
		if node != null:
			var display: String = String(node.get("display_name"))
			if not display.is_empty():
				text = TITLE_PREFIX + display
	if _title_label != null and _title_label.text != text:
		_title_label.text = text


## 运行期改 font_color 点亮 / 暗色；.tscn 落盘的静态金色保持不变（不改 .tscn）。
func apply_lit_state(lit: bool) -> void:
	if _title_label == null:
		return
	var c: Color = GOLD if lit else DIM
	if _title_label.get_theme_color("font_color", "Label") != c:
		_title_label.add_theme_color_override("font_color", c)


## R27：点亮态 = 三段式 flag 来源的状态汇总（纯读、事件驱动）。
## 每个来源经唯一入口 _flag(key, default) 显式传默认值读取；bool 直接取真值，
## int（赐福休息 epoch）以 >0 表示「已休息」。任一来源为真即点亮。
## 只产出 bool，颜色切换完全交给 apply_lit_state()，代码内不出现「某 flag → 某颜色」硬编码。
func _read_lit_sources() -> bool:
	var lit: bool = false
	for k: String in LIT_SOURCE_FLAGS:
		var v: Variant = _flag(k, false)
		if typeof(v) == TYPE_BOOL:
			lit = lit or bool(v)
		elif typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
			lit = lit or (int(v) > 0)
	return lit

# ==========================================================================
# 4) 赐福菜单（对应 HUD-BINDING.md §2，8 节点 / 7 边数据驱动）
# ==========================================================================

## 遍历 nodes，过滤 requires_flags（发现前置）+ unlocked，文本 / 分组 / 排序全取自 .tres。
func build_grace_menu() -> Array[Dictionary]:
	var menu: Array[Dictionary] = []
	for n in _grace_nodes():
		var node: Resource = n as Resource
		if node == null:
			continue
		if not are_flags_satisfied(_dict_of(node.get("requires_flags"))):
			continue
		if not is_grace_unlocked(node):
			continue
		var entry: Dictionary = {
			"id": String(node.get("grace_id")),
			"text": String(node.get("display_name")),
			"group": String(node.get("area_id")),
			"is_dungeon": bool(node.get("is_dungeon")),
			"order": _array_of(node.get("neighbors")),
			"scene_path": String(node.get("scene_path")),
			"spawn_marker": String(node.get("spawn_marker"))
		}
		menu.append(entry)
	return menu


func is_grace_unlocked(node: Resource) -> bool:
	if node == null:
		return false
	var key: String = String(node.get("unlocked_flag"))
	if key.is_empty():
		return false
	return bool(_flag(key, false))                              # 显式 default=false


## 逐条 get_flag(k, false) == expected；expected 均为 bool true（见 .tres 7 边条件）。
func are_flags_satisfied(requires: Dictionary) -> bool:
	for k in requires.keys():
		var key: String = String(k)
		var expected: Variant = requires[k]
		var actual: Variant = _flag(key, false)                  # 显式 default=false
		if typeof(actual) != typeof(expected) or actual != expected:
			return false
	return true


## 用 edges[*].requires_flags 求从 from_id 出发、条件满足且目标已解锁的可达赐福。
func get_reachable_targets(from_id: String) -> Array[String]:
	var out: Array[String] = []
	if _net == null or from_id.is_empty():
		return out
	for e in _edges():
		var edge: Dictionary = _dict_of(e)
		if String(edge.get("from", "")) != from_id:
			continue
		if not are_flags_satisfied(_dict_of(edge.get("requires_flags", {}))):
			continue
		var to_id: String = String(edge.get("to", ""))
		var target: Resource = _find_grace(to_id)
		if target == null or not is_grace_unlocked(target):
			continue
		if not out.has(to_id):
			out.append(to_id)
	return out


func on_grace_selected(target_grace_id: String) -> void:
	# 菜单点击回调 → 仅发 UI 事件信号
	grace_selected.emit(target_grace_id)


## 草案接口：校验目标 → travel_confirmed 信号（HUD 不自行落盘）。
func request_travel(target_grace_id: String) -> void:
	var node: Resource = _find_grace(target_grace_id)
	if node == null:
		push_warning("[HUD] request_travel: 目标不在赐福网络：%s" % target_grace_id)
		return
	if not is_grace_unlocked(node):
		push_warning("[HUD] request_travel: 目标未解锁：%s" % target_grace_id)
		return
	if not are_flags_satisfied(_dict_of(node.get("requires_flags"))):
		push_warning("[HUD] request_travel: 目标发现前置未满足：%s" % target_grace_id)
		return
	travel_confirmed.emit(target_grace_id)

# ==========================================================================
# 5) grace_fast_travel 接口（本轮重点，对应 HUD-BINDING.md §2.4）
# ==========================================================================

## 注入 3 号内部件的强制落盘入口，供装配层把 SaveDeltaWriter.commit 交给 HUD 编排顺序。
## HUD 只持有 Callable、只编排顺序，不实现 commit 逻辑（I-1）。
func set_fast_travel_committer(c: Callable) -> void:
	fast_travel_committer = c


## 赐福快速传送编排接口。不可颠倒的顺序（任务书 / §2.4）：
##   1 校验目标 unlocked + 当前赐福沿 edges 的 requires_flags 全部满足（只读 get_flag(k, false)）；
##   2 先落盘：与 travel_to() 统一走 _commit_before_travel(reason)，优先取 /root/SaveDeltaWriter
##      原子写，注入 committer 仅在取不到该节点时兜底（HUD 不自己 commit、不构造 SaveDelta）；
##   3 后发信号：travel_confirmed / GameEvents.travel_requested → 1 号 SceneRouter 换场景。
## /root/SaveDeltaWriter 与注入 committer 都取不到时：不自行落盘，只发信号，
##   由既有链路 ChunkWorldBridge._on_travel_requested → commit("grace_fast_travel") 兜底（如实登记）。
func grace_fast_travel(target_grace_id: String, reason: String = REASON_FAST_TRAVEL) -> void:
	# 1 校验
	var node: Resource = _find_grace(target_grace_id)
	if node == null:
		push_warning("[HUD] grace_fast_travel: 目标不在赐福网络：%s" % target_grace_id)
		return
	if not is_grace_unlocked(node):
		push_warning("[HUD] grace_fast_travel: 目标未解锁：%s" % target_grace_id)
		return
	if not are_flags_satisfied(_dict_of(node.get("requires_flags"))):
		push_warning("[HUD] grace_fast_travel: 目标发现前置未满足：%s" % target_grace_id)
		return
	var current_id: String = String(_flag(LAST_GRACE_KEY, ""))   # 显式 default=""
	if not current_id.is_empty() and current_id != target_grace_id:
		if not get_reachable_targets(current_id).has(target_grace_id):
			push_warning("[HUD] grace_fast_travel: 沿 edges 的 requires_flags 未全部满足：%s→%s" % [current_id, target_grace_id])
			return
	# 2 先落盘（与 travel_to() 统一入口 _commit_before_travel：优先 /root/SaveDeltaWriter，注入 committer 仅取不到时兜底）
	if not _commit_before_travel(reason):
		push_warning("[HUD] grace_fast_travel: 未找到 SaveDeltaWriter / 未注入 committer，落盘交既有 travel_requested 订阅链路兜底")
	# 3 后发信号
	travel_confirmed.emit(target_grace_id)
	var bus: Node = get_node_or_null("/root/GameEvents")
	if bus != null and bus.has_signal("travel_requested"):
		bus.emit_signal("travel_requested", target_grace_id)


## 休息请求（→ grace_rest 落盘，由 3 号状态机订阅处理；HUD 只发信号）。
func request_rest(grace_id: String) -> void:
	rest_requested.emit(grace_id)


## R21（cmd-20261109-115818-643-A3）：两入口统一口径后的兼容封装。
## 保留此私有方法名以免破坏历史调用；实际落盘统一委托 _commit_before_travel(reason)，
## 即优先取 /root/SaveDeltaWriter、注入 committer 仅在取不到该节点时兜底，并如实登记降级态。
## 本方法内不再有「注入 committer 优先」的旧口径。
func _delegate_commit(reason: String) -> bool:
	return _commit_before_travel(reason)

# ==========================================================================
# 6) 私有小工具（数据取自 .tres，避免硬编码 / 避免 null 传播）
# ==========================================================================

func _grace_nodes() -> Array:
	if _net == null:
		return []
	var raw: Variant = _net.get("nodes")
	if typeof(raw) != TYPE_ARRAY:
		return []
	return raw as Array


func _edges() -> Array:
	if _net == null:
		return []
	var raw: Variant = _net.get("edges")
	if typeof(raw) != TYPE_ARRAY:
		return []
	return raw as Array


func _find_grace(grace_id: String) -> Resource:
	if grace_id.is_empty():
		return null
	for n in _grace_nodes():
		var node: Resource = n as Resource
		if node != null and String(node.get("grace_id")) == grace_id:
			return node
	return null


func _dict_of(v: Variant) -> Dictionary:
	if typeof(v) == TYPE_DICTIONARY:
		return v as Dictionary
	return {}


func _array_of(v: Variant) -> Array:
	if typeof(v) == TYPE_ARRAY:
		return (v as Array).duplicate()
	return []

# ==========================================================================
# 7) R19 · open_grace_menu() / travel_to()（本轮追加，1~6 节既有逻辑逐字未动）
# ==========================================================================
# 约束：
#   - 赐福菜单数据 100% 运行期取自 res://data/rpg/grace_network.tres（8 节点 / 7 边由
#     _grace_nodes() / _edges() 遍历得到，代码内不硬编码任何赐福名 / 边 / 计数常量）；
#   - travel_to() 严格「先 commit 原子落盘、后发 travel_confirmed / travel_requested 信号」；
#   - R20（裁决 A9）：project.godot [autoload] 已正式注册 SaveDeltaWriter，travel_to()
#     优先取 /root/SaveDeltaWriter 完成 commit；仅当取不到该节点时才回退注入 committer
#     并如实登记降级。get_commit_status() 可把 degraded / source / reason / ok /
#     writer_registered_as_autoload 读回，绝不伪造落盘与 autoload 状态。
#   - R21：grace_fast_travel() 亦统一走 _commit_before_travel()，与 travel_to() 同口径
#     （优先 /root/SaveDeltaWriter、注入 committer 仅兜底），顺序同为 commit → confirmed → requested。

## 打开赐福菜单：运行期强制从磁盘重读 .tres（load_grace_network 内 CACHE_MODE_IGNORE），
## 统计实际节点 / 边数，重建菜单快照并返回（调用方据此渲染 UI，不改 hud.tscn 结构）。
func open_grace_menu() -> Array[Dictionary]:
	load_grace_network(grace_network_path)
	grace_node_count = _grace_nodes().size()
	grace_edge_count = _edges().size()
	_menu = build_grace_menu()
	menu_open = true
	return _menu.duplicate(true)


## 赐福快速传送（R19 编排接口 / R20 兑现 autoload）。不可颠倒的顺序：
##   1 校验目标（数据取自 .tres，不硬编码）；
##   2 先落盘：优先取 /root/SaveDeltaWriter.commit(reason) 原子写；取不到该节点才回退
##     注入 committer 并如实登记降级（见 _commit_before_travel）；
##   3 后发信号：HUD.travel_confirmed（4 信号之一）+ GameEvents.travel_requested。
func travel_to(grace_id: String) -> void:
	# 1 校验
	var node: Resource = _find_grace(grace_id)
	if node == null:
		push_warning("[HUD] travel_to: 目标不在赐福网络：%s" % grace_id)
		return
	if not is_grace_unlocked(node):
		push_warning("[HUD] travel_to: 目标未解锁：%s" % grace_id)
		return
	if not are_flags_satisfied(_dict_of(node.get("requires_flags"))):
		push_warning("[HUD] travel_to: 目标发现前置未满足：%s" % grace_id)
		return
	# 2 先落盘（内部完成 autoload 检测 / 注入 committer 降级 / 如实登记）
	_commit_before_travel(REASON_FAST_TRAVEL)
	# 3 后发信号
	travel_confirmed.emit(grace_id)
	var bus: Node = get_node_or_null("/root/GameEvents")
	if bus != null and bus.has_signal("travel_requested"):
		bus.emit_signal("travel_requested", grace_id)


## 先落盘的唯一入口（R20）：优先取 /root/SaveDeltaWriter（已注册 autoload 的真实节点）；
## 取不到该节点才回退注入 committer。三种来源如实写入 last_commit_source /
## commit_degraded / commit_log，不伪造已落盘、不伪造 autoload 可用。
func _commit_before_travel(reason: String) -> bool:
	last_commit_reason = reason
	# 优先：/root/SaveDeltaWriter 真实节点（R20 已在 project.godot [autoload] 注册）
	var writer: Node = get_node_or_null(WRITER_ROOT_PATH)
	if writer != null and writer.has_method("commit"):
		writer.call("commit", reason)
		commit_degraded = false
		last_commit_source = "autoload"
		last_commit_ok = true
		_log_commit()
		return true
	# 回退：取不到 /root/SaveDeltaWriter 才用注入 committer（如实登记降级）
	commit_degraded = true
	if fast_travel_committer.is_valid():
		fast_travel_committer.call(reason)
		last_commit_source = "injected"
		last_commit_ok = true
		push_warning("[HUD] 降级登记：未取到 /root/SaveDeltaWriter，改用 set_fast_travel_committer() 注入的 committer 完成 commit(reason=%s)" % reason)
		_log_commit()
		return true
	# 连注入 committer 都没有：明确登记「未能先落盘」，不冒充原子写已完成
	last_commit_source = "none"
	last_commit_ok = false
	push_warning("[HUD] 降级登记：未取到 /root/SaveDeltaWriter 且未注入 committer；本次 travel_to 未能先落盘，仅后发 travel_requested（如实登记）")
	_log_commit()
	return false


func _log_commit() -> void:
	commit_log.append("source=%s reason=%s ok=%s degraded=%s" % [last_commit_source, last_commit_reason, str(last_commit_ok), str(commit_degraded)])


## 供装配层 / 自检读回「降级登记」实际值，避免只靠日志口头声明。
func get_commit_status() -> Dictionary:
	return {
		"degraded": commit_degraded,
		"source": last_commit_source,
		"reason": last_commit_reason,
		"ok": last_commit_ok,
		"writer_registered_as_autoload": ProjectSettings.has_setting(WRITER_AUTOLOAD_KEY),
		"writer_root_exists": get_node_or_null(WRITER_ROOT_PATH) != null,
		"log": commit_log.duplicate(),
		"grace_node_count": grace_node_count,
		"grace_edge_count": grace_edge_count
	}


# ==========================================================================
# 8) R27B · 赐福成长「购买入口」（裁决 A23 / A24）
#    交互：E 键 interact（赐福休息）打开 / 关闭兑换面板，数字键 1 / 2 / 3 购买；
#          HUD 显示三项（名称 / cost / 是否已解锁 / 当前余额）+ 可读提示。
#    落盘：经 GraceUpgradeService.can_purchase / purchase 幂等判定；成功后写
#          grace.trial.spent_points（单调递增）与 grace.upgrade_<id>.unlocked（单向），
#          commit("grace_upgrade_purchased") 严格「先落盘再改运行时实例」；
#          绝不 removals、绝不回退 grace.trial.points。
#    兼容：同一 commit 内另写 Rank-2 运行时读取口径 grace.trial.bought_<id>，使挂载的
#          GraceUpgradeRuntime.apply_purchased() 能读到已购项（裁决 A23 三段式收敛与
#          Rank-2 内部标记并存，如实登记，不改 Rank-2 脚本）。
#    既有 1~7 节逻辑逐字未动；依赖缺失一律判空降级、不崩、不产生 SCRIPT ERROR。
# ==========================================================================

func unlocked_key(upgrade_id: String) -> String:
	return FLAG_UNLOCKED_PREFIX + upgrade_id + FLAG_UNLOCKED_SUFFIX


## 验证 / 装配注入口：注入优先于场景探活（--script 模式可确定性验证落盘时序）。
func bind_grace_deps(ws: Node, writer: Node, runtime: Node, encounter: Node = null) -> void:
	_grace_ws = ws
	_grace_writer = writer
	_grace_runtime = runtime
	_grace_encounter = encounter


func _grace_state() -> Node:
	if _grace_ws != null:
		return _grace_ws
	if _world_state != null:
		return _world_state
	var ml: MainLoop = Engine.get_main_loop()
	if ml is SceneTree:
		return (ml as SceneTree).root.get_node_or_null(NodePath("WorldState"))
	return null


func _grace_delta_writer() -> Node:
	if _grace_writer != null:
		return _grace_writer
	var ml: MainLoop = Engine.get_main_loop()
	if ml is SceneTree:
		return (ml as SceneTree).root.get_node_or_null(NodePath("SaveDeltaWriter"))
	return null


func _grace_runtime_node() -> Node:
	if _grace_runtime != null:
		return _grace_runtime
	if not grace_runtime_path.is_empty():
		return get_node_or_null(grace_runtime_path)
	return null


func _grace_encounter_node() -> Node:
	if _grace_encounter != null:
		return _grace_encounter
	return get_node_or_null(^"../../../../EncounterRoot")


func _load_grace_config() -> GraceUpgradeConfig:
	if not ResourceLoader.exists(GRACE_CONFIG_PATH):
		return null
	return ResourceLoader.load(GRACE_CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as GraceUpgradeConfig


## 只读视图：供 HUD 渲染与验证读回（不改 WorldState、不写 flag）。
func get_shop_view() -> Dictionary:
	var cfg: GraceUpgradeConfig = _load_grace_config()
	var state: Node = _grace_state()
	var points: int = 0
	var spent: int = 0
	if state != null and state.has_method("get_flag"):
		points = int(state.call("get_flag", FLAG_POINTS, 0))
		spent = int(state.call("get_flag", FLAG_SPENT_POINTS, 0))
	var balance: int = maxi(0, points - spent)
	var items: Array[Dictionary] = []
	if cfg != null:
		for i: int in range(cfg.upgrade_count()):
			var u := cfg.get_upgrade(i)
			if u == null:
				continue
			var unlocked: bool = false
			if state != null and state.has_method("get_flag"):
				unlocked = bool(state.call("get_flag", unlocked_key(u.id), false)) \
					or bool(state.call("get_flag", GraceUpgradeService.purchased_flag_key(u.id), false))
			items.append({
				"index": i, "id": u.id, "name": u.display_name, "cost": u.cost,
				"unlocked": unlocked, "affordable": (not unlocked) and balance >= u.cost,
			})
	return {"open": shop_open, "balance": balance, "points": points, "spent": spent,
		"items": items, "message": shop_message}


## 渲染三项可兑换增益（名称 / cost / 是否已解锁 / 当前余额）+ 可读提示到 GraceShopLabel。
func _refresh_shop_hud() -> void:
	if _shop_label == null:
		return
	var v: Dictionary = get_shop_view()
	if not bool(v.get("open", false)):
		_shop_label.text = "赐福成长 · 按 E 打开兑换"
		return
	var lines: Array[String] = []
	lines.append("赐福成长 ｜ 当前余额 %d（点数 %d − 已消费 %d） ｜ 1/2/3 兑换" % [
		int(v.get("balance", 0)), int(v.get("points", 0)), int(v.get("spent", 0))])
	var items: Array = v.get("items", []) as Array
	for it: Variant in items:
		var row: Dictionary = it as Dictionary
		var state_text: String = "已解锁" if bool(row.get("unlocked", false)) else \
			("可兑换" if bool(row.get("affordable", false)) else "点数不足")
		lines.append("  %d. %s ｜ 消耗 %d ｜ %s" % [
			int(row.get("index", 0)) + 1, str(row.get("name", "")),
			int(row.get("cost", 0)), state_text])
	lines.append("提示：" + str(v.get("message", "")))
	_shop_label.text = "\n".join(PackedStringArray(lines))


func _set_shop_message(msg: String) -> void:
	shop_message = msg
	_refresh_shop_hud()


func _toggle_shop() -> void:
	shop_open = not shop_open
	shop_message = "按 E 打开/关闭；数字键 1 / 2 / 3 兑换" if shop_open else ""
	_refresh_shop_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_toggle_shop()
		return
	if event is InputEventKey:
		var k: InputEventKey = event as InputEventKey
		if k.pressed and not k.echo:
			var idx: int = -1
			if k.physical_keycode == KEY_1 or k.keycode == KEY_1:
				idx = 0
			elif k.physical_keycode == KEY_2 or k.keycode == KEY_2:
				idx = 1
			elif k.physical_keycode == KEY_3 or k.keycode == KEY_3:
				idx = 2
			if idx >= 0:
				if not shop_open:
					_set_shop_message("请先按 E 打开赐福成长兑换面板")
					return
				purchase_upgrade(idx)


func _reject_message(svc: GraceUpgradeService, points: int, spent: int, row: Dictionary, u) -> String:
	var balance: int = maxi(0, points - spent)
	var id: String = str(row.get("id", ""))
	if svc.is_purchased(id):
		return "「%s」已解锁，不能重复购买" % str(u.display_name)
	if balance < int(row.get("cost", 0)):
		return "点数不足：%s 需要 %d，当前余额 %d" % [
			str(u.display_name), int(row.get("cost", 0)), balance]
	return "输入异常或该项不可兑换，购买被拒绝（余额 %d）" % balance


## 一次购买编排（幂等判定 / 落盘 / 运行时接线）。返回 report 供 HUD 与验证读回。
## 严格「先落盘再改运行时实例」：set_flag 入队 → commit 原子写 → 才 apply_purchased。
func purchase_upgrade(index: int) -> Dictionary:
	var cfg: GraceUpgradeConfig = _load_grace_config()
	if cfg == null:
		_set_shop_message("兑换表不可用，购买被拒绝（降级，不崩）")
		return {"ok": false, "reason": "config_unavailable", "committed": false}
	if index < 0 or index >= cfg.upgrade_count():
		_set_shop_message("无效选项，请按 1 / 2 / 3 选择")
		return {"ok": false, "reason": "invalid_index", "committed": false}
	var u := cfg.get_upgrade(index)
	if u == null or not cfg.is_upgrade_valid(u):
		_set_shop_message("该项配置非法，购买被拒绝")
		return {"ok": false, "reason": "invalid_upgrade", "committed": false}
	var state: Node = _grace_state()
	if state == null or not state.has_method("get_flag") or not state.has_method("set_flag"):
		_set_shop_message("WorldState 不可用，购买未落盘（降级，不崩）")
		return {"ok": false, "reason": "world_state_unavailable", "committed": false}
	var points: int = int(state.call("get_flag", FLAG_POINTS, 0))
	var spent: int = int(state.call("get_flag", FLAG_SPENT_POINTS, 0))
	var purchased_ids: Array = []
	for i: int in range(cfg.upgrade_count()):
		var it := cfg.get_upgrade(i)
		if it == null:
			continue
		if bool(state.call("get_flag", unlocked_key(it.id), false)) \
				or bool(state.call("get_flag", GraceUpgradeService.purchased_flag_key(it.id), false)):
			purchased_ids.append(it.id)
	var row: Dictionary = cfg.make_upgrade(u.id, u.display_name, u.cost, u.effect_key, u.effect_value)
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	svc.load_state(spent, purchased_ids)
	if not svc.can_purchase(points, spent, row):
		_set_shop_message(_reject_message(svc, points, spent, row, u))
		return {"ok": false, "reason": "can_purchase_rejected",
			"balance": maxi(0, points - spent), "committed": false}
	var r: Dictionary = svc.purchase(points, spent, row)
	if not bool(r.get("ok", false)):
		_set_shop_message("幂等判定拒绝购买（%s）" % str(r.get("reason", "")))
		return {"ok": false, "reason": str(r.get("reason", "")), "committed": false}
	var new_spent: int = int(r.get("spent_points", spent))
	# ★ 先落盘：经 I-1 唯一写入口 set_flag 入队 SaveDelta → commit(reason) 原子写。
	grace_purchase_events.append("stage_flags:" + u.id)
	state.call("set_flag", FLAG_SPENT_POINTS, new_spent)
	state.call("set_flag", unlocked_key(u.id), true)
	# 兼容 Rank-2 运行时读取口径（同一 commit 原子落盘，如实登记）。
	state.call("set_flag", GraceUpgradeService.purchased_flag_key(u.id), true)
	var writer: Node = _grace_delta_writer()
	if writer == null or not writer.has_method("commit"):
		grace_purchase_events.append("disk_write_downgrade:" + u.id)
		_set_shop_message("SaveDeltaWriter 未就绪：flag 仅进程内内存、未落盘，增益未作用到运行时（如实降级）")
		return {"ok": true, "reason": "commit_downgrade", "committed": false,
			"spent_points": new_spent, "balance": maxi(0, points - new_spent)}
	writer.call("commit", COMMIT_REASON_PURCHASED)
	grace_purchase_events.append("disk_write:" + COMMIT_REASON_PURCHASED)
	# ★ 落盘成功后才改运行时实例（HP 上限 / 翻滚无敌 / 攻击力）。
	var rt: Node = _grace_runtime_node()
	if rt != null and rt.has_method("apply_purchased"):
		var applied: Dictionary = rt.call("apply_purchased", _grace_encounter_node(), state)
		grace_purchase_events.append("runtime_update:" + str(applied.get("applied", 0)))
	else:
		grace_purchase_events.append("runtime_update_downgrade:0")
	var balance: int = maxi(0, points - new_spent)
	var msg: String = "兑换成功：%s（消耗 %d，余额 %d）" % [u.display_name, u.cost, balance]
	_set_shop_message(msg)
	return {"ok": true, "reason": "ok", "committed": true, "id": u.id,
		"spent_points": new_spent, "balance": balance, "points": points, "message": msg}
