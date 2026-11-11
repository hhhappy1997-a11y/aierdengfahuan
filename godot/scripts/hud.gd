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
# R28 [ROUND=R28] 教学完成点亮来源（bool，false→true 单向）。
# 单独常量、不并入 LIT_SOURCE_FLAGS：保护既有 verify_persistence_hud_v050.gd 的
# D5「LIT_SOURCE_FLAGS.size()==2」断言（30 PASS 全不回退）。教学完成与试炼完成都
# 读三段式 flag，颜色切换统一复用既有 apply_lit_state(lit) 入口，不硬编码颜色条件。
const LIT_FLAG_TUTORIAL_COMPLETED: String = "grace.tutorial.completed"
# R28B / 裁决 A26：grace.tutorial.step_index 是【世界持久层】单调历史最高进度
#   （按 max 写、绝不回退、T 重开不回写更小值），只作存档 / 回放 / 重启恢复记录。
#   教学 HUD 的「进度 1-3」必须显示【运行时游标】（见 read_tutorial_progress() /
#   tutorial_progress_text()），绝不读该世界 flag，否则 T 重开会卡在历史最高 3/3。
#   本常量只登记「不用于显示」的世界 key：不并入 LIT_SOURCE_FLAGS、不并入 _bound_keys、
#   不参与 refresh_label 增量命中，保护 verify_persistence_hud_v050.gd D5
#   「LIT_SOURCE_FLAGS.size()==2」等既有断言不回退。
const FLAG_TUTORIAL_STEP_INDEX: String = "grace.tutorial.step_index"
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

# ---- R29 [ROUND=R29] · 兑换面板文字可读性（段 B / low-mobile SubViewport 缩放）----
# 根因（改前真跑三档抓帧实证）：courtyard.tscn 的 GraceShopLabel 挂在
#   SubViewportContainer/SubViewport/FXLayer/Hud（SubViewport 内）。quality_settings.apply()
#   按档位改写 SubViewportContainer.stretch_shrink（low=3 / medium=2 / high=1）与 SubViewport
#   内部渲染尺寸（low=480x270 / medium=640x360 / high=960x540），Label 的屏幕绝对坐标
#   offset=(24,300)-(1100,470) 在小尺寸 SubViewport 内被整体拉伸/裁剪：
#     high(shrink=1) 文字叠在砖地上、字号小、对比度低，勉强可辨；
#     medium(shrink=2) 文字被推到 y≈610 与底部战斗 HUD 重叠、后两行被截断；
#     low(shrink=3) offset 远超内部视口 → 兑换面板文字完全消失。
# 修法：_ready() 里把该 Label 迁到【SubViewport 外】的独立 CanvasLayer（与 QualitySettings
#   同级，挂 SubViewportContainer 的父节点），CanvasLayer 铺满真实 1280x720 视口、不受
#   stretch_shrink 影响；同时固定字号 + 高对比度（亮色字 / 深色描边阴影 / 半透明深底），
#   保证 low/medium/high 三档一致可读。
# 边界：只动兑换面板 Label 自身的父节点与 theme / 位置 / 可见性，不改兑换逻辑
#   （get_shop_view / purchase_upgrade）、不改四套既有 HUD 位置。独立 hud.tscn 实例
#   （--script 验证）无 SubViewport，判空降级、不迁节点、不改节点路径，
#   保护既有 58 / 30 / 11 PASS 断言不回退。
# R29B [ROUND=R29B] 修正：上轮保留的 offset (24,300)-(1100,470) 在独立 CanvasLayer 上
#   变成 1076×170 的近黑实心大矩形，首帧常驻并横切玩家/Boss 躯干（总指挥目视发现）。
#   本轮改为：① 面板 visible 严格由 shop_open 门控（首帧隐藏 / E 打开才显示 / 关闭隐藏）；
#   ② 深底 alpha 0.88→0.30；③ offset 移到屏幕右下 SHOP_RECT_*（避开角色包围盒与四套 HUD）。
# [PLACEHOLDER] 字号 / 颜色 / 层号 / rect 为布局值，待试玩目视校准（rationale：20px 在
#   1280x720 下 5 行文本约 120px；layer=45 高于 QualitySettings=40）。
const SHOP_FONT_SIZE: int = 20
const SHOP_LAYER_INDEX: int = 45
const SHOP_LAYER_NAME: String = "GraceShopReadableLayer"
const SHOP_TEXT_COLOR: Color = Color(1.0, 0.96, 0.82, 1.0)
const SHOP_OUTLINE_COLOR: Color = Color(0.02, 0.03, 0.06, 1.0)
# R29B [ROUND=R29B]：改前深底 alpha=0.88 几乎不透明，在独立 CanvasLayer 上形成
#   x≈24–1100 / y≈300–470 的近黑实心大矩形，首帧常驻并遮住玩家/Boss 躯干
#   （总指挥目视 v070 定稿三帧发现的新回归）。压到 0.30（≤0.35）：真跑像素量化
#   验证面板区保留底层砖地纹理、不是近黑实心块。边框同步降到 0.55 避免金边突兀。
const SHOP_BG_COLOR: Color = Color(0.04, 0.06, 0.12, 0.30)
const SHOP_BORDER_COLOR: Color = Color(0.83, 0.68, 0.3, 0.55)
const SHOP_OUTLINE_SIZE: int = 6
# R29B · 面板位置（屏幕右下，避开角色包围盒与四套 HUD）。改前 (24,300)-(1100,470)
#   横切玩家(x≈400–680,y≈490–570) / Boss(x≈645–880,y≈230–350) 躯干；新矩形
#   x≥740 / y≥358 落在两者包围盒之外：Boss 下沿 y≈350 < 358、玩家右沿 x≈680 < 740。
#   不覆盖 赐福 HUD(x<730,y<220) / 画质面板(x>760,y<180)（本面板 y≥358）；
#   也不压 波次 HUD(y≈240,x<460) / 教学 HUD(y≈520,x<700) / 底部战斗 HUD(y≈660)。
#   宽 536px < 原 1076px、覆盖面积 182,920→112,896 px²，配合 autowrap 保持 20px 字号
#   与三档可读（独立 CanvasLayer 不受 stretch_shrink 影响）。[PLACEHOLDER] 待试玩校准。
const SHOP_RECT_LEFT: float = 740.0
const SHOP_RECT_TOP: float = 358.0
const SHOP_RECT_RIGHT: float = 1276.0
const SHOP_RECT_BOTTOM: float = 568.0

# ---- R30 [ROUND=R30] · 赐福图鉴运行时挂载（最小接线，裁决 A35）----
# 只做「运行时 new + call_deferred add_child」，不写 courtyard.tscn 任何场景节点
#   （静态节点数保持 41）、不改既有兑换逻辑、不改四套 HUD 文本。
# 独立 hud.tscn 实例（--script 验证）祖先链无 SubViewportContainer → 直接判空返回、
#   不建节点，保护既有 58 / 30 / 11 / 127 PASS 逐字不回退。
const CODEX_DIRECTOR_PATH: String = "res://scripts/combat/codex_director.gd"
const CODEX_DIRECTOR_NAME: String = "CodexDirector"

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
	# R29：把兑换面板 Label 迁出 SubViewport（仅在真实场景命中）；独立 hud.tscn 实例判空降级。
	_ensure_shop_readable()
	if _grace_runtime == null and not grace_runtime_path.is_empty():
		_grace_runtime = get_node_or_null(grace_runtime_path)
	set_process_unhandled_input(true)
	_refresh_shop_hud()
	# R30：运行时挂赐福图鉴导演（不改场景节点 / 不动兑换逻辑与四套 HUD 文本）。
	_ensure_codex_director()


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
	# R28：教学完成三段式 flag 也登记进增量命中集合（事件驱动，不每帧轮询）。
	_bound_keys[LIT_FLAG_TUTORIAL_COMPLETED] = true
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
	# R28：全量刷新也纳入「教学完成」三段式来源（否则 commit → delta_committed →
	# refresh_all 会把 flag_changed 刚点亮的亮金覆盖回暗灰）。既有回归的干净基线里
	# grace.tutorial.completed 默认 false，lit or false == lit，逐字等价、不回退。
	apply_lit_state(lit or _read_tutorial_lit())
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
	# R28：教学完成（grace.tutorial.completed）flag 变化 → 读三段式 flag 汇总点亮态，
	# 与试炼完成共用既有 apply_lit_state(lit) 入口，代码内不出现「某 flag → 某颜色」硬编码。
	if key == LIT_FLAG_TUTORIAL_COMPLETED:
		apply_lit_state(_read_lit_sources() or _read_tutorial_lit())
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


## R28：教学完成点亮来源（纯读、事件驱动）。经唯一 _flag(key, default) 入口显式传
## 业务默认值 false 读三段式 flag；只产出 bool，颜色切换完全交给 apply_lit_state()。
## 与 _read_lit_sources() 分离，避免改动既有 2 项来源数组（保护 v050 D5 断言）。
func _read_tutorial_lit() -> bool:
	return bool(_flag(LIT_FLAG_TUTORIAL_COMPLETED, false))


## R28B / 裁决 A26 · 教学进度显示（只认运行时游标，绝不读世界持久层 flag）。
## runtime_step_index 来自 TutorialDirector.get_snapshot()["step_index"]（T 重开归零）；
## 返回 "赐福引导 %d/%d"，供教学 HUD / 集成层渲染与验证读回。
## 世界 flag FLAG_TUTORIAL_STEP_INDEX 只登记、绝不读取：它是单调历史最高进度，
## 若用它渲染，T 重开后进度会错误地卡在 3/3（A26 明确禁止）。
func tutorial_progress_text(runtime_step_index: int, total_steps: int) -> String:
	var total: int = maxi(1, total_steps)
	var shown: int = clampi(runtime_step_index + 1, 1, total)
	return "赐福引导 %d/%d" % [shown, total]


## R28B / 裁决 A26 · 从教学导演的运行时快照产出教学进度显示（集成层只读接口）。
## 只取 get_snapshot()["step_index"]（运行时游标）与 total_steps；
## 绝不读 grace.tutorial.step_index 世界 flag，绝不写任何 flag、不发信号。
## director 为空 / 无 get_snapshot 时安全回落 0 / 3，不崩、不产生 SCRIPT ERROR。
func read_tutorial_progress(director: Node) -> Dictionary:
	var runtime_step: int = 0
	var total: int = 3
	if director != null and director.has_method("get_snapshot"):
		var snap: Dictionary = director.call("get_snapshot") as Dictionary
		runtime_step = int(snap.get("step_index", 0))
		total = int(snap.get("total_steps", 3))
	return {
		"runtime_step_index": runtime_step,
		"total_steps": total,
		"text": tutorial_progress_text(runtime_step, total),
		"source": "runtime_cursor",
		"world_flag_key_not_for_display": FLAG_TUTORIAL_STEP_INDEX,
	}

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
#    R28B ③ 兼容旧档：写入侧自 R28 双写收敛后【只写 grace.upgrade_<id>.unlocked】
#          （裁决 A23，本轮逐字未动），不再新写 grace.trial.bought_<id>；
#          读取侧接入 Rank-2 GraceUpgradeService 的三个兼容函数
#          legacy_bought_flag_key() / is_purchased_in_flags() / load_state_from_flags()，
#          以「unlocked OR 旧 grace.trial.bought_<id>」判定，使只有旧 bought_ 的
#          历史存档仍可识别已购（见 get_shop_view / purchase_upgrade /
#          _purchase_flags_snapshot）。F1~F8 防刷核心逐字不变。
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


## R28B / ③ 兼容旧档：从 WorldState 逐 key get_flag 构造「已购判定」flags 快照。
## I-1 铁律：WorldState 只暴露 get_flag(key, default)，不可访问内部 _flags；
## 故按 upgrade id 收集权威 unlocked 与旧 grace.trial.bought_<id> 两键的值，
## 交 GraceUpgradeService.is_purchased_in_flags() / load_state_from_flags() 以
## 「unlocked OR 旧 bought_」判定，使仅有旧 bought_ 的历史存档仍可识别已购。
## 纯读、不写；写仍只写 unlocked（裁决 A23 / F1~F8 防刷判定逐字不变）。
func _purchase_flags_snapshot(state: Node, cfg: GraceUpgradeConfig) -> Dictionary:
	var flags: Dictionary = {}
	if state == null or cfg == null or not state.has_method("get_flag"):
		return flags
	for i: int in range(cfg.upgrade_count()):
		var u := cfg.get_upgrade(i)
		if u == null:
			continue
		var auth_key: String = unlocked_key(u.id)
		var legacy_key: String = GraceUpgradeService.legacy_bought_flag_key(u.id)
		flags[auth_key] = bool(state.call("get_flag", auth_key, false))
		flags[legacy_key] = bool(state.call("get_flag", legacy_key, false))
	return flags


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
		# R28B ③：一次构造兼容快照（unlocked OR 旧 bought_），供全部兑换项共用；
		# 写入侧仍只写 unlocked，读取侧兼容纯 bought_ 历史存档。
		var flags: Dictionary = _purchase_flags_snapshot(state, cfg)
		for i: int in range(cfg.upgrade_count()):
			var u := cfg.get_upgrade(i)
			if u == null:
				continue
			var unlocked: bool = GraceUpgradeService.is_purchased_in_flags(flags, u.id)
			items.append({
				"index": i, "id": u.id, "name": u.display_name, "cost": u.cost,
				"unlocked": unlocked, "affordable": (not unlocked) and balance >= u.cost,
			})
	return {"open": shop_open, "balance": balance, "points": points, "spent": spent,
		"items": items, "message": shop_message}


## R29 · 把兑换面板 Label 迁出 SubViewport，挂到不受 stretch_shrink 影响的独立 CanvasLayer。
## 只在「Label 确实位于某个 SubViewportContainer/SubViewport 内 + 能找到其父级挂载根」时执行；
## 独立 hud.tscn 实例（--script 验证）不含 SubViewportContainer，判空降级、节点路径 / 文本 /
## 兑换逻辑逐字不变。固定字号 + 高对比度 theme 覆盖仅作用于该 Label，三档渲染结果一致。
## 时序：_ready() 期间场景根（Courtyard / root）处于 _propagate_ready（blocked>0），直接
##   outside_root.add_child(layer) 会报 "Parent node is busy setting up children" 并失败
##   （改前真跑实证：Label 被 reparent 到游离层 → 三档文字全部消失）。故用 call_deferred
##   把「建层 + reparent + theme」推迟到本帧 _ready 传播完成之后、首帧渲染之前执行。
func _ensure_shop_readable() -> void:
	if _shop_label == null or not is_instance_valid(_shop_label):
		return
	var container: SubViewportContainer = null
	var p: Node = _shop_label.get_parent()
	while p != null:
		if p is SubViewportContainer:
			container = p as SubViewportContainer
			break
		p = p.get_parent()
	if container == null:
		# --script 独立 hud.tscn 实例：Label 不在 SubViewport 内，保持原路径 / 原属性（降级）。
		return
	var outside_root: Node = container.get_parent()
	if outside_root == null:
		return
	call_deferred("_deferred_shop_readable", outside_root)


## 由 call_deferred 触发：此时 outside_root 已完成 children setup，add_child 合法。
func _deferred_shop_readable(outside_root: Node) -> void:
	if _shop_label == null or not is_instance_valid(_shop_label) \
			or outside_root == null or not is_instance_valid(outside_root):
		return
	# 幂等：同名独立层已存在则复用，不重复建层。
	var layer: CanvasLayer = outside_root.get_node_or_null(NodePath(SHOP_LAYER_NAME)) as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = SHOP_LAYER_NAME
		layer.layer = SHOP_LAYER_INDEX
		outside_root.add_child(layer)
	if not layer.is_inside_tree():
		return
	if _shop_label.get_parent() != layer:
		_shop_label.reparent(layer)
	# R29B：把面板从横切角色中部的 (24,300)-(1100,470) 移到屏幕右下 SHOP_RECT_*。
	#   autowrap 让 20px 字号在较窄宽度下自动折行、不裁字；文字内容逐字不动，
	#   独立 CanvasLayer 不受 stretch_shrink 影响 → low/medium/high 三档一致可读。
	_shop_label.offset_left = SHOP_RECT_LEFT
	_shop_label.offset_top = SHOP_RECT_TOP
	_shop_label.offset_right = SHOP_RECT_RIGHT
	_shop_label.offset_bottom = SHOP_RECT_BOTTOM
	_shop_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# 固定字号 + 高对比度（不受 SubViewport 缩放影响的独立层，三档一致）。
	_shop_label.add_theme_font_size_override("font_size", SHOP_FONT_SIZE)
	_shop_label.add_theme_color_override("font_color", SHOP_TEXT_COLOR)
	_shop_label.add_theme_color_override("font_outline_color", SHOP_OUTLINE_COLOR)
	_shop_label.add_theme_constant_override("outline_size", SHOP_OUTLINE_SIZE)
	_shop_label.add_theme_color_override("font_shadow_color", SHOP_OUTLINE_COLOR)
	_shop_label.add_theme_constant_override("shadow_offset_x", 2)
	_shop_label.add_theme_constant_override("shadow_offset_y", 2)
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = SHOP_BG_COLOR
	bg.set_corner_radius_all(6)
	bg.set_border_width_all(1)
	bg.border_color = SHOP_BORDER_COLOR
	bg.content_margin_left = 12.0
	bg.content_margin_right = 12.0
	bg.content_margin_top = 8.0
	bg.content_margin_bottom = 8.0
	_shop_label.add_theme_stylebox_override("normal", bg)
	# R29B：可见性严格由 shop_open 门控。_ready() 的 _refresh_shop_hud() 已按
	#   shop_open=false 设过 visible=false；reparent / theme 覆盖后这里再显式同步一次，
	#   保证 deferred 建层之后首帧仍隐藏（画面不出现大矩形）。
	_shop_label.visible = shop_open
	print("[R29][SHOP] 兑换面板迁出 SubViewport → 独立 CanvasLayer(layer=%d) | 固定字号=%d + 描边/阴影/深底高对比 | rect=(%.0f,%.0f)-(%.0f,%.0f) 避开 赐福HUD(x<730,y<220)/画质面板(x>760,y<180)" % [
			SHOP_LAYER_INDEX, SHOP_FONT_SIZE,
			_shop_label.offset_left, _shop_label.offset_top,
			_shop_label.offset_right, _shop_label.offset_bottom])
	print("[R29B][SHOP] 默认隐藏 visible=%s (shop_open=%s) | 深底 alpha=%.2f | rect=(%.0f,%.0f)-(%.0f,%.0f) 屏幕右下避开玩家/Boss 包围盒 | autowrap=%d" % [
			str(_shop_label.visible), str(shop_open), SHOP_BG_COLOR.a,
			SHOP_RECT_LEFT, SHOP_RECT_TOP, SHOP_RECT_RIGHT, SHOP_RECT_BOTTOM,
			int(_shop_label.autowrap_mode)])


## 渲染三项可兑换增益（名称 / cost / 是否已解锁 / 当前余额）+ 可读提示到 GraceShopLabel。
func _refresh_shop_hud() -> void:
	if _shop_label == null:
		return
	var v: Dictionary = get_shop_view()
	var is_open: bool = bool(v.get("open", false))
	# R29B：GraceShopLabel 与其 normal stylebox（深底 + 金边）整体随 shop_open 显隐。
	#   shop_open=false（首帧 / 关闭 / 购买会话结束）→ visible=false，画面不出现大矩形；
	#   仅 E 键打开（shop_open=true）才显示。既有文本 / 兑换逻辑逐字不动。
	_shop_label.visible = is_open
	if not is_open:
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
	# R28B ③：按兼容口径（unlocked OR 旧 grace.trial.bought_<id>）从 flags 快照恢复
	# 已购集合，使只有旧 bought_ 的历史存档仍被 F1 判为「已购、拒绝重复购买」。
	# 写仍只写 unlocked（裁决 A23），本轮未新增任何 bought_ 写入点。
	var flags: Dictionary = _purchase_flags_snapshot(state, cfg)
	var all_ids: Array = []
	for i: int in range(cfg.upgrade_count()):
		var it := cfg.get_upgrade(i)
		if it != null:
			all_ids.append(it.id)
	var row: Dictionary = cfg.make_upgrade(u.id, u.display_name, u.cost, u.effect_key, u.effect_value)
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	svc.load_state_from_flags(flags, all_ids, spent)
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
	# R28 收敛后 purchased_flag_key() == unlocked_key()（同键幂等合并为单写）。
	# 写仍只写 unlocked（裁决 A23），绝不新写 grace.trial.bought_<id>；本行逐字未动。
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


# ==========================================================================
# 9) R30 [ROUND=R30] · 赐福图鉴运行时挂载（唯一新增接线，1~8 节逐字未动）
# ==========================================================================
## 只在「真实 courtyard 场景」里挂 CodexDirector：沿父链找到 SubViewportContainer，
## 取其父节点（Courtyard，SubViewport 之外，与 QualitySettings / 兑换层同级）作挂载根。
## call_deferred 避开 _ready() 传播期 "Parent node is busy setting up children"（R29 实证）。
## 独立 hud.tscn 实例无 SubViewportContainer → 降级不建节点、不崩、既有回归不回退。
func _ensure_codex_director() -> void:
	var container: SubViewportContainer = null
	var p: Node = get_parent()
	while p != null:
		if p is SubViewportContainer:
			container = p as SubViewportContainer
			break
		p = p.get_parent()
	if container == null:
		return
	var mount: Node = container.get_parent()
	if mount == null or mount.get_node_or_null(NodePath(CODEX_DIRECTOR_NAME)) != null:
		return
	var script: Script = load(CODEX_DIRECTOR_PATH) as Script
	if script == null:
		push_warning("[HUD] CodexDirector 脚本不可用，赐福图鉴降级（不崩）")
		return
	var director: Node = script.new() as Node
	if director == null:
		return
	director.name = CODEX_DIRECTOR_NAME
	mount.call_deferred("add_child", director)
	print("[R30][HUD] 运行时挂载 %s → Courtyard（独立 CanvasLayer 由导演自建，不写 courtyard.tscn）" % CODEX_DIRECTOR_NAME)
