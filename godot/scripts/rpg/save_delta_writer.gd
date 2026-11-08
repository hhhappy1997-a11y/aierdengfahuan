extends Node

## Delta 写入时机、原子写触发、检查点落盘（3 号内部节点）。
## 订阅 GameEvents 的击杀信号（I-2）；击杀 flag 只由本节点写，2 号只发信号不双写。
## 对外（1/2 号）不暴露任何方法；强制落盘经 WorldState._commit_delta(reason) 内部调用。

var _ws: Node = null
var _bus: Node = null
var _pending: bool = false
var _merge_window_sec: float = 0.5
var _acc: float = 0.0

func _ready() -> void:
    _ws = get_node_or_null("/root/WorldState")
    _bus = get_node_or_null("/root/GameEvents")
    if _bus == null:
        push_warning("I-2: 未找到 GameEvents，击杀 flag 暂不落盘")
        return
    if _bus.has_signal("enemy_defeated"):
        _bus.connect("enemy_defeated", Callable(self, "_on_enemy_defeated"))
    if _bus.has_signal("boss_defeated"):
        _bus.connect("boss_defeated", Callable(self, "_on_boss_defeated"))

func _process(delta: float) -> void:
    if not _pending:
        return
    _acc += delta
    if _acc >= _merge_window_sec:
        _acc = 0.0
        _pending = false
        _commit("flag_batch")

## 标记一次 flag 变化，进入 0.5 s 合并窗口（非强制点，见存档与flag规范.md §4.8）。
func mark_flag_changed() -> void:
    _pending = true

## 强制同步落盘点：赐福点亮 / 休息、传送、地牢进出、击杀、拾取、任务阶段、退出。
func commit(reason: String) -> void:
    _pending = false
    _acc = 0.0
    _commit(reason)

func _commit(reason: String) -> void:
    if _ws != null and _ws.has_method("_commit_delta"):
        _ws.call("_commit_delta", reason)

## I-2：精英 / 普通敌人击杀。击杀 flag 只由 3 号写（respawn_policy 判定见箱庭地牢模板.md §6）。
func _on_enemy_defeated(enemy_id: String) -> void:
    _set_flag("combat.%s.defeated" % enemy_id, true)
    commit("enemy_defeated")

## I-2：Boss 击杀，永久保留（respawn_policy = "never"）。
func _on_boss_defeated(boss_id: String) -> void:
    _set_flag("combat.%s.defeated" % boss_id, true)
    _set_flag("combat.%s.phase_two_ready" % boss_id, false)
    commit("boss_defeated")

func _set_flag(key: String, value: Variant) -> void:
    if _ws != null and _ws.has_method("set_flag"):
        _ws.call("set_flag", key, value)
