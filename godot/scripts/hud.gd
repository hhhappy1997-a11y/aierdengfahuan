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
# R32 [ROUND=R32] 新增信号（既有 4 信号逐字未动、既有验证断言不回退）：
signal execution_performed(window_id: String, bonus_points: int)   # 机制 B：处决窗口内按 F 完成处决
signal boon_draft_selected(index: int, choice_id: String)         # 机制 A：赐福抉择三选一

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

# ---- R31 [ROUND=R31] · 打击反馈层运行时挂载（唯一新增接线，1~9 节逐字未动）----
# 只做「运行时 new + call_deferred add_child」，不写 courtyard.tscn 任何场景节点
#   （静态节点数保持 41 / uv 2/1/1 原样）、不改既有兑换逻辑与四套 HUD 文本。
# 反馈层按实接入 EncounterDirector 既有信号；低画质 / 移动端由 set_low_quality 降级为只保留闪光；
# Tab 图鉴 / 兑换面板打开时 set_panel_open 追加强化避让，反馈层不遮文字。
# 独立 hud.tscn 实例（--script 验证）祖先链无 SubViewportContainer → 判空返回、不建节点。
const IMPACT_FEEDBACK_PATH: String = "res://scripts/render/impact_feedback.gd"
const IMPACT_LAYER_NAME: String = "ImpactFeedbackLayer"

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
# R31：运行时挂载的打击反馈层（CanvasLayer，非场景静态节点）。
var _impact_feedback: Node = null

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
	# R31：运行时挂打击反馈层（不改场景节点；面板避让 / 信号按实接入 / 画质降级见 §10）。
	_ensure_impact_feedback()
	# R32：HUD 分区布局初始化（纯内存、不写场景节点；分区 / 互斥 / 新机制见 §11~§14）。
	_init_r32_layout()


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
	# R31：兑换面板开闭同步给反馈层（面板打开时强化避让，闪光不遮文字）。
	_sync_impact_panels()
	if _shop_label == null:
		return
	var v: Dictionary = get_shop_view()
	var is_open: bool = bool(v.get("open", false))
	# R29B：GraceShopLabel 与其 normal stylebox（深底 + 金边）整体随 shop_open 显隐。
	#   shop_open=false（首帧 / 关闭 / 购买会话结束）→ visible=false，画面不出现大矩形；
	#   仅 E 键打开（shop_open=true）才显示。既有文本 / 兑换逻辑逐字不动。
	# R32：显隐再叠加右侧面板互斥（Tab 图鉴 / 赐福抉择打开时隐藏兑换面板、关闭恢复）；
	#   默认态 is_side_panel_visible("shop") 等价于 shop_open，既有断言不回退。
	_shop_label.visible = is_side_panel_visible("shop")
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
	# R32：新增键（F 处决 / Tab 图鉴 / 抉择卡片数字键）走独立状态隔离处理；
	# 既有 interact / 兑换数字键逻辑在其后逐字不变（保护既有回归断言）。
	if _process_r32_keys(event):
		return
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
	if mount == null:
		return
	# R33：已挂载（场景复用 / 二次 _ready）时只补引用 + 重新收敛 Tab 仲裁，不重复建节点。
	var existing: Node = mount.get_node_or_null(NodePath(CODEX_DIRECTOR_NAME))
	if existing != null:
		_codex_director = existing
		call_deferred("_r33_arbitrate_codex_tab")
		return
	var script: Script = load(CODEX_DIRECTOR_PATH) as Script
	if script == null:
		push_warning("[HUD] CodexDirector 脚本不可用，赐福图鉴降级（不崩）")
		return
	var director: Node = script.new() as Node
	if director == null:
		return
	director.name = CODEX_DIRECTOR_NAME
	# R33：保存真实引用，供 Tab 互斥仲裁读 is_panel_open() / 驱动 toggle_panel()。
	_codex_director = director
	mount.call_deferred("add_child", director)
	# R33：deferred 顺序在 add_child（→ director._ready 里 set_process_unhandled_input(true)）
	#   之后执行，此时关闭其 Tab 监听才不会被 _ready 覆盖；HUD 成为唯一 Tab 仲裁者。
	call_deferred("_r33_arbitrate_codex_tab")
	print("[R30][HUD] 运行时挂载 %s → Courtyard（独立 CanvasLayer 由导演自建，不写 courtyard.tscn）" % CODEX_DIRECTOR_NAME)


## R33 · Tab 仲裁收敛：director 已入树、_ready 已执行完，关闭其自身 _unhandled_input，
## 由 HUD 统一处理 Tab（消除两个独立监听者状态不同步 / set_input_as_handled 吞键）。
## 只改运行时节点属性，不改 codex_director.gd 文件、不写 courtyard.tscn（静态节点数 41 保持）。
func _r33_arbitrate_codex_tab() -> void:
	if _codex_director == null or not is_instance_valid(_codex_director):
		return
	_codex_director.set_process_unhandled_input(false)
	apply_side_panel_visibility()
	print("[R33][HUD] Tab 互斥仲裁收敛：CodexDirector 自身 Tab 监听关闭，HUD._unhandled_input 统一处理 Tab 并经 toggle_panel() 同步真实图鉴面板 visible")


## R33 · 把互斥态落实到 CodexDirector 的真实图鉴面板节点（CanvasLayer.visible）。
## 只经公开方法 is_panel_open()/toggle_panel() 鸭子类型适配：不读私有字段、不改其文件。
## want 取 is_side_panel_visible("codex")（单一事实源）：赐福抉择 / 兑换优先时图鉴面板
## 确实隐藏，关闭后恢复；director 缺失（--script 独立 hud 实例）判空降级、既有断言不回退。
func _sync_codex_panel_visible() -> void:
	if _codex_director == null or not is_instance_valid(_codex_director):
		return
	var cd: Node = _codex_director
	if not cd.has_method("is_panel_open") or not cd.has_method("toggle_panel"):
		return
	var want: bool = is_side_panel_visible("codex")
	if bool(cd.call("is_panel_open")) != want:
		cd.call("toggle_panel")


# ==========================================================================
# 10) R31 [ROUND=R31] · 打击反馈层运行时挂载（唯一新增接线，1~9 节逐字未动）
# ==========================================================================
## 沿父链找到 SubViewportContainer，取其父节点 Courtyard 作挂载根（与 R29 兑换层 /
## R30 CodexDirector 同口径：SubViewport 之外、铺满真实 1280x720 视口）。
## call_deferred 避开 _ready() 传播期 "Parent node is busy setting up children"（R29 实证）。
## 独立 hud.tscn 实例无 SubViewportContainer → 降级不建节点、不崩、既有回归不回退。
func _ensure_impact_feedback() -> void:
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
	if mount == null or mount.get_node_or_null(NodePath(IMPACT_LAYER_NAME)) != null:
		return
	var script: Script = load(IMPACT_FEEDBACK_PATH) as Script
	if script == null:
		push_warning("[HUD] ImpactFeedback 脚本不可用，打击反馈层降级（不崩）")
		return
	var layer: Node = script.new() as Node
	if layer == null:
		return
	layer.name = IMPACT_LAYER_NAME
	_impact_feedback = layer
	mount.call_deferred("add_child", layer)
	# 按实接入 EncounterDirector 既有信号（反馈层内部 get_signal_connection_list 去重 connect）。
	var director: Node = mount.get_node_or_null(NodePath("EncounterRoot"))
	if director != null and layer.has_method("bind_director"):
		layer.call("bind_director", director)
	# 低画质 / 移动端只保留闪光（读 QualitySettings 既有 get_quality_preset，不每帧轮询）。
	var quality: Node = mount.get_node_or_null(NodePath("QualitySettings"))
	if quality != null and quality.has_method("get_quality_preset") \
			and layer.has_method("set_low_quality"):
		var preset: String = str(quality.call("get_quality_preset"))
		layer.call("set_low_quality", preset == "low" or preset == "mobile")
	_sync_impact_panels()
	print("[R31][HUD] 运行时挂载 %s → Courtyard（CanvasLayer，不写 courtyard.tscn；按实接入既有战斗信号 / 画质降级 / 面板避让）" % IMPACT_LAYER_NAME)


## 面板开闭同步：兑换面板由 shop_open 门控；Tab 图鉴面板只读 CodexDirector.is_panel_open()。
## 事件驱动（_refresh_shop_hud / 挂载完成时各一次），不在 _process 每帧轮询。
## 反馈层默认已常驻避让全部 HUD 文字 / 面板矩形，set_panel_open 再追加强化避让，
## 故面板打开期间反馈层不遮挡文字；依赖缺失一律判空降级、不产生 SCRIPT ERROR。
func _sync_impact_panels() -> void:
	var fb: Node = _impact_feedback
	if fb == null or not is_instance_valid(fb) or not fb.has_method("set_panel_open"):
		return
	# R33：与 apply_side_panel_visibility 共用单一事实源 is_side_panel_visible(...)，
	#   不再用 shop_open 原态 / 另读 CodexDirector，避免反馈层避让与面板真实 visible 不一致。
	fb.call("set_panel_open", "shop", is_side_panel_visible("shop"))
	fb.call("set_panel_open", "codex", is_side_panel_visible("codex"))
	fb.call("set_panel_open", "boon_draft", is_side_panel_visible("boon_draft"))


# ==========================================================================
# 11) R32 [ROUND=R32] · HUD 分区避让（归一化锚点 / 包围盒，不硬编码像素堆叠）
# ==========================================================================
# 根因（总指挥回看 capture/v090_demo.mp4 首/中/尾三帧目视实证）：
#   a) 赐福引导行「已完成(3/3)/按T重开教学」与波次行「第 N/3 波｜赐福点数｜前计时｜历史最佳」
#      挤在同一水平带 → 文字重叠；
#   b) Tab 图鉴面板展开时与波次行 / 赐福成长面板文字叠压；
#   c) 右上「画质设置·低/中/高」面板与右侧「赐福成长」面板同时常驻、文字叠压。
# 修法：把 HUD 划成 6 个【两两不相交】的分区 + 1 个中央角色保护区，用
#   【归一化锚点 Rect2（[0,1] 比例，position+size）】定义，不硬编码像素堆叠；
#   运行时按当前视口尺寸线性缩放 → 任意分辨率（含降级档）都不出界、不重叠。
#   右侧「兑换 / 图鉴 / 赐福抉择」三面板共用 ANCHOR_SIDE 同一分区且状态互斥（§12/§14）。
# [PLACEHOLDER] 锚点为目视布局初值，待试玩校准；rationale：分区间保留安全缝
#   （归一化后随缩放保持），配合 autowrap 保证长文本不越界、不叠压；调参只改本节常量。
const LAYOUT_BASE: Vector2 = Vector2(1280.0, 720.0)
const ANCHOR_TITLE: Rect2 = Rect2(0.01875, 0.02222, 0.37500, 0.11667)     # 左上标题
const ANCHOR_QUALITY: Rect2 = Rect2(0.60625, 0.02222, 0.37500, 0.16667)   # 右上画质
const ANCHOR_WAVE: Rect2 = Rect2(0.01875, 0.27778, 0.27813, 0.04167)      # 左中·波次带
const ANCHOR_GUIDE: Rect2 = Rect2(0.01875, 0.33056, 0.27813, 0.04167)     # 左中·引导带（与波次分两行）
const ANCHOR_STATUS: Rect2 = Rect2(0.01875, 0.92222, 0.96250, 0.05000)    # 左下状态条
const ANCHOR_SIDE: Rect2 = Rect2(0.70313, 0.41667, 0.27813, 0.41667)      # 右侧面板（兑换/图鉴/抉择 互斥）
const ANCHOR_CHAR: Rect2 = Rect2(0.31250, 0.31944, 0.37500, 0.47222)      # 中央角色保护区（非文字）

var _layout_viewport: Vector2 = LAYOUT_BASE


func _init_r32_layout() -> void:
	set_layout_viewport(LAYOUT_BASE)


## 降级分辨率入口：由 QualitySettings / 集成层按真实视口调用（不每帧轮询）。
func set_layout_viewport(size: Vector2) -> void:
	_layout_viewport = Vector2(maxf(1.0, size.x), maxf(1.0, size.y))


func _scaled_rect(anchor: Rect2) -> Rect2:
	return Rect2(anchor.position.x * _layout_viewport.x,
			anchor.position.y * _layout_viewport.y,
			anchor.size.x * _layout_viewport.x,
			anchor.size.y * _layout_viewport.y)


## 6 个 HUD 文字 / 面板分区的实际包围盒（供布局断言与运行时定位）。
func get_layout_rects() -> Array[Dictionary]:
	return [
		{"id": "title", "rect": _scaled_rect(ANCHOR_TITLE)},
		{"id": "quality", "rect": _scaled_rect(ANCHOR_QUALITY)},
		{"id": "wave", "rect": _scaled_rect(ANCHOR_WAVE)},
		{"id": "guide", "rect": _scaled_rect(ANCHOR_GUIDE)},
		{"id": "status", "rect": _scaled_rect(ANCHOR_STATUS)},
		{"id": "side", "rect": _scaled_rect(ANCHOR_SIDE)},
	]


func get_center_char_rect() -> Rect2:
	return _scaled_rect(ANCHOR_CHAR)


func get_hud_layout() -> Dictionary:
	return {
		"viewport": _layout_viewport,
		"rects": get_layout_rects(),
		"center_char": get_center_char_rect(),
		"visible_side_panels": get_visible_side_panels(),
		"codex_open": is_codex_open(),
		"boon_draft_open": is_boon_draft_open(),
	}


# ==========================================================================
# 12) R32 · 右侧面板互斥状态机（Tab 图鉴 ↔ 兑换 ↔ 赐福抉择）
# ==========================================================================
var _codex_open: bool = false
var _boon_draft_open: bool = false
# R33 [ROUND=R33] · 赐福图鉴导演真实引用（右侧面板互斥的唯一仲裁者 = HUD）。
# 根因（总指挥回看 capture/v100_final.mp4 目视实证）：R30 的 CodexDirector 由
#   call_deferred 挂载、晚于 HUD 入树，其 _unhandled_input 在逆序分发中优先命中 Tab
#   并 vp.set_input_as_handled() 吞键 → HUD 收不到 Tab、_codex_open 恒 false、
#   get_visible_side_panels() 恒按 shop_open 返回 shop → 兑换/赐福成长面板常驻；
#   而 R32 的 19 条包围盒断言只读布局/逻辑态、直接 set_codex_open 绕过真实输入路径，
#   故全 PASS 却与实机不符。
# 修法：_ensure_codex_director() 保存引用并在 director 入树（_ready 执行完）后关闭
#   其自身 Tab 监听，由 HUD._unhandled_input → _process_r32_keys 统一仲裁；
#   apply_side_panel_visibility() 经公开 toggle_panel()/is_panel_open() 把互斥落实到
#   CodexDirector 真实 CanvasLayer.visible 与兑换 Label.visible（不是只做包围盒）。
# 独立 hud.tscn --script 实例无 SubViewportContainer → 引用恒 null、判空降级，
#   既有 19 条断言 / 58·30·11·127 PASS 逐字不回退。
var _codex_director: Node = null


func set_codex_open(open: bool) -> void:
	_codex_open = open
	apply_side_panel_visibility()


func is_codex_open() -> bool:
	return _codex_open


func _toggle_codex_panel() -> void:
	set_codex_open(not _codex_open)


## 右侧面板互斥：同一时刻最多 1 个可见；优先级 赐福抉择 > 图鉴 > 兑换。
## Tab 图鉴打开时隐藏常驻兑换面板、关闭时按 shop_open 原态恢复（shop_open 本身不变）。
func get_visible_side_panels() -> Array[String]:
	var out: Array[String] = []
	if _boon_draft_open:
		out.append("boon_draft")
	elif _codex_open:
		out.append("codex")
	elif shop_open:
		out.append("shop")
	return out


func is_side_panel_visible(panel: String) -> bool:
	return get_visible_side_panels().has(panel)


## 把互斥状态落实到真实节点 / 打击反馈层：图鉴或抉择打开时强制隐藏兑换 Label，
## 关闭后按 shop_open 恢复；R33 再把互斥落实到 CodexDirector 真实图鉴面板 visible，
## 使「图鉴打开 → 兑换/赐福成长确实隐藏；关闭 → 恢复」在真实 Tab 输入路径上生效，
## 不再只是包围盒布局。set_panel_open 让反馈层在面板区强化避让、不遮文字。
func apply_side_panel_visibility() -> void:
	var shop_visible: bool = is_side_panel_visible("shop")
	if _shop_label != null and is_instance_valid(_shop_label):
		_shop_label.visible = shop_visible
	_sync_codex_panel_visible()
	var fb: Node = _impact_feedback
	if fb != null and is_instance_valid(fb) and fb.has_method("set_panel_open"):
		fb.call("set_panel_open", "codex", is_side_panel_visible("codex"))
		fb.call("set_panel_open", "boon_draft", is_side_panel_visible("boon_draft"))
		fb.call("set_panel_open", "shop", shop_visible)


# ==========================================================================
# 13) R32 · 机制 B：Boss 韧性处决窗口（订阅 Rank-2 stagger_service 公开接口）
# ==========================================================================
# 边界：Rank-2 stagger_service.gd 为 RefCounted 纯逻辑、本轮并行交付（此刻未落盘）。
#   本层【只经公开方法 / 信号】鸭子类型适配，绝不静态引用其 class_name、绝不直接读
#   其私有实现字段；契约候选名成组登记，命中即用、缺失即降级、不伪造联调结果。
#   待 Rank-2 落盘后按真实接口名复跑 verify_stagger_runtime_v100.gd（见 DONE-R32.md）。
const STAGGER_SIGNAL_OPEN_CANDIDATES: Array[String] = [
	"execution_window_opened", "window_opened", "stance_broken"]
const STAGGER_SIGNAL_CLOSE_CANDIDATES: Array[String] = [
	"execution_window_closed", "window_closed"]
## Rank-2 真实服务还有 stagger_value_changed(current, maximum) 驱动韧性条（事件驱动，不轮询）。
const STAGGER_SIGNAL_CHANGED_CANDIDATES: Array[String] = ["stagger_value_changed"]
const STAGGER_METHOD_IS_OPEN: Array[String] = [
	"is_execution_window_open", "is_window_open", "window_open"]
const STAGGER_METHOD_REMAINING: Array[String] = [
	"get_window_remaining_sec", "get_window_remaining", "get_remaining_sec"]
const STAGGER_METHOD_POISE: Array[String] = [
	"get_poise_ratio", "get_boss_poise_ratio", "get_poise"]
const STAGGER_METHOD_EXECUTE: Array[String] = [
	"perform_execution", "try_execute", "execute"]
## [PLACEHOLDER] 处决窗口默认读秒：Rank-2 stagger_rules.tres 落盘前 HUD 侧降级初值。
## rationale：给「处决窗口」读秒一个可见但短促的初值，真实时长以 Rank-2 信号 / 方法为准。
const STAGGER_WINDOW_FALLBACK_SEC: float = 3.0

var _stagger_service: Object = null
var _stagger_window_open: bool = false
var _stagger_window_remaining: float = 0.0
var _stagger_poise_ratio: float = 1.0
var _stagger_execution_consumed: bool = false
var _execution_count: int = 0
var _stagger_window_id: String = ""
var _stagger_window_bonus: int = 0


## 绑定 Rank-2 服务：按契约候选信号名 connect（去重），再读一次公开态。
func bind_stagger_service(svc: Object) -> void:
	_unbind_stagger_signals()
	_stagger_service = svc
	if svc == null:
		return
	for sig: String in STAGGER_SIGNAL_OPEN_CANDIDATES:
		if svc.has_signal(sig):
			_dedup_connect_stagger(svc, sig, "_on_stagger_window_opened")
			break
	for sig: String in STAGGER_SIGNAL_CLOSE_CANDIDATES:
		if svc.has_signal(sig):
			_dedup_connect_stagger(svc, sig, "_on_stagger_window_closed")
			break
	for sig: String in STAGGER_SIGNAL_CHANGED_CANDIDATES:
		if svc.has_signal(sig):
			_dedup_connect_stagger(svc, sig, "_on_stagger_value_changed")
			break
	poll_stagger_service()


func _dedup_connect_stagger(svc: Object, sig: String, method: String) -> void:
	var cb: Callable = Callable(self, method)
	for conn in svc.get_signal_connection_list(sig):
		var c: Callable = conn.get("callable", Callable())
		if c.get_object() == self and String(c.get_method()) == method:
			return
	svc.connect(sig, cb)


## _exit_tree 兜底 disconnect：信号连接必须有明确释放路径，卸载后不留悬空 Callable。
func _unbind_stagger_signals() -> void:
	if _stagger_service == null or not is_instance_valid(_stagger_service):
		return
	var all_sigs: Array = STAGGER_SIGNAL_OPEN_CANDIDATES \
			+ STAGGER_SIGNAL_CLOSE_CANDIDATES + STAGGER_SIGNAL_CHANGED_CANDIDATES
	for sig: String in all_sigs:
		if not _stagger_service.has_signal(sig):
			continue
		var cb_open: Callable = Callable(self, "_on_stagger_window_opened")
		if _stagger_service.is_connected(sig, cb_open):
			_stagger_service.disconnect(sig, cb_open)
		var cb_close: Callable = Callable(self, "_on_stagger_window_closed")
		if _stagger_service.is_connected(sig, cb_close):
			_stagger_service.disconnect(sig, cb_close)
		var cb_changed: Callable = Callable(self, "_on_stagger_value_changed")
		if _stagger_service.is_connected(sig, cb_changed):
			_stagger_service.disconnect(sig, cb_changed)


## 真实服务 execution_window_opened(remaining_sec: float, bonus_points: int) 为 2 参：
## 第 2 参是额外点数（不是 window_id），此处按公开签名如实承接。
func _on_stagger_window_opened(remaining_sec: Variant = null, bonus_points: Variant = null, _c: Variant = null) -> void:
	_open_execution_window(remaining_sec, bonus_points)


func _on_stagger_window_closed(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	_close_execution_window()


## 真实服务 stagger_value_changed(current, maximum) → 韧性条比例（事件驱动，不轮询）。
func _on_stagger_value_changed(current: Variant = null, maximum: Variant = null, _c: Variant = null) -> void:
	if current == null or maximum == null:
		return
	if (typeof(current) == TYPE_FLOAT or typeof(current) == TYPE_INT) \
			and (typeof(maximum) == TYPE_FLOAT or typeof(maximum) == TYPE_INT):
		var mx: float = float(maximum)
		if mx > 0.0:
			_stagger_poise_ratio = clampf(float(current) / mx, 0.0, 1.0)


func _open_execution_window(remaining: Variant, bonus: Variant) -> void:
	var sec: float = STAGGER_WINDOW_FALLBACK_SEC
	if remaining != null and (typeof(remaining) == TYPE_FLOAT or typeof(remaining) == TYPE_INT):
		sec = maxf(0.0, float(remaining))
	_stagger_window_open = true
	_stagger_window_remaining = sec
	_stagger_execution_consumed = false
	_stagger_window_bonus = int(bonus) if (bonus != null \
			and (typeof(bonus) == TYPE_INT or typeof(bonus) == TYPE_FLOAT)) else 0
	# 真实服务不提供 window_id，留空如实登记；bonus_points 由信号第 2 参给出。
	_stagger_window_id = ""


func _close_execution_window() -> void:
	_stagger_window_open = false
	_stagger_window_remaining = 0.0


## 从公开方法回读状态（不碰私有字段）：由信号回调 / 显式推进调用，不在 _process 每帧轮询。
func poll_stagger_service() -> void:
	if _stagger_service == null or not is_instance_valid(_stagger_service):
		return
	var svc: Object = _stagger_service
	# 首选 get_snapshot()（Rank-2 真实服务稳定公开接口）：一次读回韧性 / 窗口态，
	# 不碰任何私有字段；缺失再回落候选方法（兼容替身 / 旧口径）。
	if svc.has_method("get_snapshot"):
		var snap: Variant = svc.call("get_snapshot")
		if typeof(snap) == TYPE_DICTIONARY:
			var d: Dictionary = snap as Dictionary
			var cur: float = float(d.get("stagger", 0.0))
			var mx: float = float(d.get("stagger_max", 1.0))
			if mx > 0.0:
				_stagger_poise_ratio = clampf(cur / mx, 0.0, 1.0)
			var wo: Variant = d.get("window_open", null)
			if typeof(wo) == TYPE_BOOL:
				if bool(wo) and not _stagger_window_open:
					_open_execution_window(d.get("window_remaining", null), d.get("execute_bonus_points", null))
				elif not bool(wo) and _stagger_window_open:
					_close_execution_window()
			if _stagger_window_open and d.has("window_remaining"):
				_stagger_window_remaining = maxf(0.0, float(d.get("window_remaining", 0.0)))
			return
	for m: String in STAGGER_METHOD_POISE:
		if svc.has_method(m):
			_stagger_poise_ratio = clampf(float(svc.call(m)), 0.0, 1.0)
			break
	var is_open: Variant = null
	for m: String in STAGGER_METHOD_IS_OPEN:
		if svc.has_method(m):
			is_open = svc.call(m)
			break
	if is_open != null and typeof(is_open) == TYPE_BOOL:
		if bool(is_open) and not _stagger_window_open:
			_open_execution_window(null, null)
		elif not bool(is_open) and _stagger_window_open:
			_close_execution_window()
	if _stagger_window_open:
		for m: String in STAGGER_METHOD_REMAINING:
			if svc.has_method(m):
				_stagger_window_remaining = maxf(0.0, float(svc.call(m)))
				break


## 处决窗口读秒推进（显式驱动，确定性；超时自动关窗 = 契约「超时关闭」）。
func tick_stagger(delta: float) -> void:
	if not _stagger_window_open:
		return
	_stagger_window_remaining = maxf(0.0, _stagger_window_remaining - maxf(0.0, delta))
	if _stagger_window_remaining <= 0.0:
		_close_execution_window()


## 窗口内触发一次处决：重复触发 / 窗口外一律拒绝；成功后 emit execution_performed。
func request_execution() -> Dictionary:
	if not _stagger_window_open:
		return {"ok": false, "reason": "window_closed"}
	if _stagger_execution_consumed:
		return {"ok": false, "reason": "already_executed"}
	_stagger_execution_consumed = true
	_execution_count += 1
	var bonus: int = 0
	if _stagger_service != null and is_instance_valid(_stagger_service):
		for m: String in STAGGER_METHOD_EXECUTE:
			if _stagger_service.has_method(m):
				var r: Variant = _stagger_service.call(m)
				if typeof(r) == TYPE_DICTIONARY:
					bonus = int((r as Dictionary).get("bonus_points", 0))
				break
	execution_performed.emit(_stagger_window_id, bonus)
	# 处决消耗本窗口一次机会；窗口本身由 tick_stagger 超时 / Rank-2 closed 信号关闭。
	# 窗口内重复 F 由 _stagger_execution_consumed 拒绝（契约「重复触发拒绝」）。
	return {"ok": true, "reason": "ok",
			"execution_count": _execution_count, "bonus_points": bonus}


func _try_execution_input() -> void:
	request_execution()


## HUD 显示数据（Boss 韧性条 / 处决窗口读秒），纯只读快照供验证与渲染回读。
func get_stagger_hud_view() -> Dictionary:
	return {
		"window_open": _stagger_window_open,
		"remaining_sec": _stagger_window_remaining,
		"poise_ratio": _stagger_poise_ratio,
		"execution_consumed": _stagger_execution_consumed,
		"execution_count": _execution_count,
		"window_id": _stagger_window_id,
		"window_bonus": _stagger_window_bonus,
		"service_available": _stagger_service != null and is_instance_valid(_stagger_service),
		"poise_text": "Boss 韧性 %d%%" % int(_stagger_poise_ratio * 100.0),
		"window_text": ("处决窗口 %.1fs · 按 F" % _stagger_window_remaining) if _stagger_window_open else "",
	}


# ==========================================================================
# 14) R32 · 机制 A：赐福抉择三选一卡片（调用 Rank-2 boon_draft_service.select）
# ==========================================================================
const BOON_METHOD_CANDIDATES: Array[String] = ["get_candidates", "get_options", "get_choices"]

var _boon_draft_service: Object = null
var _boon_draft_choices: Array = []
var _boon_draft_selected_index: int = -1
var _boon_draft_last_result: Dictionary = {}


func bind_boon_draft_service(svc: Object) -> void:
	_boon_draft_service = svc


## 每波清波后钩子（wave_cleared）：显示三选一卡片；与图鉴 / 兑换互斥、不遮中央角色。
func on_wave_cleared(_index: Variant = null, _points: Variant = null) -> void:
	show_boon_draft()


func show_boon_draft(choices: Array = []) -> void:
	_boon_draft_choices = choices.duplicate(true)
	if _boon_draft_choices.is_empty() and _boon_draft_service != null \
			and is_instance_valid(_boon_draft_service):
		for m: String in BOON_METHOD_CANDIDATES:
			if _boon_draft_service.has_method(m):
				var c: Variant = _boon_draft_service.call(m)
				if typeof(c) == TYPE_ARRAY:
					_boon_draft_choices = (c as Array).duplicate(true)
				break
		# 契约适配：真实 BoonDraftService 的候选在 get_config() → BoonDraftConfig.boons
		# （Array[Dictionary]）；用鸭子类型读，不静态引用 Rank-2 class_name、不读私有实现。
		if _boon_draft_choices.is_empty() and _boon_draft_service.has_method("get_config"):
			var cfg: Object = _boon_draft_service.call("get_config") as Object
			if cfg != null:
				var raw: Variant = cfg.get("boons")
				if typeof(raw) == TYPE_ARRAY:
					for row: Variant in (raw as Array):
						if typeof(row) == TYPE_DICTIONARY:
							var d: Dictionary = row as Dictionary
							_boon_draft_choices.append({
								"id": String(d.get("id", "")),
								"title": String(d.get("title", "")),
							})
	_boon_draft_open = true
	_boon_draft_selected_index = -1
	_boon_draft_last_result = {}
	apply_side_panel_visibility()


func close_boon_draft() -> void:
	_boon_draft_open = false
	apply_side_panel_visibility()


func is_boon_draft_open() -> bool:
	return _boon_draft_open


## 数字键 1/2/3 选择：与既有兑换数字键做状态隔离（_process_r32_keys 拦截），不误触。
func _select_boon_draft(index: int) -> Dictionary:
	if not _boon_draft_open:
		return {"ok": false, "reason": "draft_closed"}
	if index < 0 or index > 2:
		return {"ok": false, "reason": "invalid_index"}
	var result: Dictionary = {"ok": true, "reason": "selection_recorded"}
	if _boon_draft_service != null and is_instance_valid(_boon_draft_service) \
			and _boon_draft_service.has_method("select"):
		var r: Variant = _boon_draft_service.call("select", index)
		if typeof(r) == TYPE_DICTIONARY:
			result = r as Dictionary
	else:
		result["service_available"] = false
	_boon_draft_selected_index = index
	_boon_draft_last_result = result
	var choice_id: String = ""
	if index < _boon_draft_choices.size():
		var c: Variant = _boon_draft_choices[index]
		if typeof(c) == TYPE_DICTIONARY:
			choice_id = String((c as Dictionary).get("id", ""))
	boon_draft_selected.emit(index, choice_id)
	close_boon_draft()
	return result


func get_boon_draft_view() -> Dictionary:
	return {
		"open": _boon_draft_open,
		"choices": _boon_draft_choices.duplicate(true),
		"selected_index": _boon_draft_selected_index,
		"last_result": _boon_draft_last_result.duplicate(),
		"service_available": _boon_draft_service != null and is_instance_valid(_boon_draft_service),
		"rect": _scaled_rect(ANCHOR_SIDE),
		"overlaps_center_char": _scaled_rect(ANCHOR_SIDE).intersection(get_center_char_rect()).get_area() > 0.0,
	}


# ==========================================================================
# 15) R32 · 输入状态隔离（既有 _unhandled_input 逻辑逐字保留在其后）
# ==========================================================================
func _digit_index(pc: int, kc: int) -> int:
	for i: int in range(3):
		var key_code: int = KEY_1 + i
		if pc == key_code or kc == key_code:
			return i
	return -1


## 返回是否消费该事件。抉择卡片打开时数字键 1/2/3 只走抉择、其余键一律拦截，
## 绝不落到既有兑换逻辑（状态隔离避免误触）。F / Tab 走处决 / 图鉴互斥。
func _process_r32_keys(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var k: InputEventKey = event as InputEventKey
	if not k.pressed or k.echo:
		return false
	var pc: int = k.physical_keycode
	var kc: int = k.keycode
	if _boon_draft_open:
		var di: int = _digit_index(pc, kc)
		if di >= 0:
			_select_boon_draft(di)
		return true
	if pc == KEY_TAB or kc == KEY_TAB:
		_toggle_codex_panel()
		return true
	if pc == KEY_F or kc == KEY_F:
		_try_execution_input()
		return true
	return false


## 验证 / 注入入口：与 _unhandled_input 走完全相同的 R32 键处理路径（确定性，不需帧分发）。
func process_key_event(event: InputEvent) -> bool:
	return _process_r32_keys(event)


func _exit_tree() -> void:
	_unbind_stagger_signals()
	_codex_director = null
