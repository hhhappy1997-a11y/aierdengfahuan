extends Node
class_name CombatEventBus

## ===========================================================================
## 2 号工位 · R4 新增交付件：I-2 对外发射点（收敛 R2/R3 遗留的 GameEvents 挂载偏差）
##
## 【本轮定位】任务书-R4.md 交付件 2「I-2 信号改挂 GameEvents autoload」。
##   R2 把 enemy_defeated / boss_defeated 定义在 PlayerStateMachine 节点自身
##   （DONE-R2.md §4 第 1 项、DONE-R3.md §4 第 3 项登记为遗留偏差）。
##   本轮按「既有交付件不重做、只补齐本轮新增 / 缺失项」与任务书-R4 §硬性约束
##   「不改既有交付件内容（只追加 / 补齐）」，**不改任何既有 .gd**，改为新增本件作为
##   2 号唯一的 I-2 对外发射点：击杀信号直接 emit 到 /root/GameEvents autoload
##   （1 号注册、3 号实现 game_events.gd；信号 enemy_defeated / boss_defeated 均在该
##   autoload 上定义，参数单个 String）。
## 【接线契约（R4 起生效）】
##   EnemyDirector.target_defeated / BossController 击杀
##     -> CombatEventBus.report_defeat(defeat_id, is_boss)
##       -> /root/GameEvents.enemy_defeated | boss_defeated
##         -> 3 号 SaveDeltaWriter 订阅并写 combat.*.defeated（I-2）。
##   PlayerStateMachine 上既有的同名信号降级为模块内历史声明（既有件零改动，保留供
##   1 号 / UI 的模块内订阅）；3 号只订阅 GameEvents、不重复订阅，避免双写。
##   与 3 号《接口契约.md》§2.2「节点组 combat_signal_bus 优先 + /root/GameEvents 兼容」
##   的发现顺序兼容：本轮把信号承载体统一收敛为 GameEvents autoload。
## 【参数 / flag 口径】参数单个 String（数据表 id：BossData.id / EnemyData.id）；
##   2 号不写任何 flag、不碰 SaveDelta、不双写（击杀 flag 只由 3 号写）。
## 【硬约束】本节点不定义 enemy_defeated / boss_defeated 信号，只转发到 autoload；
##   不含任何战斗数值；autoload 缺失时降级为 push_warning、不回退到本地信号（避免双出口）。
## 【目标路径】res://scripts/combat/combat_event_bus.gd
## 引擎：Godot 4 标准版 / GDScript，全静态类型；中文 UTF-8。
## ===========================================================================

@export var game_events_path: NodePath = ^"/root/GameEvents"

var _game_events: Node = null


func _ready() -> void:
	_game_events = get_node_or_null(game_events_path)


## 2 号唯一的 I-2 对外发射点。defeat_id = 数据表 id（单个 String）。
func report_defeat(defeat_id: String, is_boss: bool) -> void:
	var bus: Node = _resolve_bus()
	if bus == null:
		push_warning("CombatEventBus: 未找到 /root/GameEvents autoload，I-2 击杀信号未发出（集成层需注册 autoload）")
		return
	var signal_name: String = "boss_defeated" if is_boss else "enemy_defeated"
	if not bus.has_signal(signal_name):
		push_error("CombatEventBus: GameEvents 缺少信号 -> %s" % signal_name)
		return
	bus.emit_signal(signal_name, defeat_id)


## 可选：把 EnemyDirector.target_defeated(defeat_id, is_boss) 一根线接到本发射点。
## 用信号存在性检查 + Callable 弱类型，避免与 EnemyDirector 全局类强耦合（本件可独立解析）。
func bind_director(director: Node) -> void:
	if director == null or not director.has_signal("target_defeated"):
		push_warning("CombatEventBus: bind_director 目标无 target_defeated 信号")
		return
	var cb: Callable = Callable(self, "_on_target_defeated")
	if not director.is_connected("target_defeated", cb):
		director.connect("target_defeated", cb)


func _on_target_defeated(defeat_id: String, is_boss: bool) -> void:
	report_defeat(defeat_id, is_boss)


func _resolve_bus() -> Node:
	if _game_events != null and is_instance_valid(_game_events):
		return _game_events
	_game_events = get_node_or_null(game_events_path)
	return _game_events
