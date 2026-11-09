extends Node

## R20 · 裁决 A9：SaveDeltaWriter 正式注册为 autoload（cmd-20261109-110237-805-A3）。
## 3 号内部件（RPG / 世界 / 存档）：编排 SaveDelta 的写入时机与强制落盘点。
##
## 注册：project.godot [autoload] SaveDeltaWriter="*res://scripts/save_delta_writer.gd"
## 契约（00-协作契约.md §4.4 存档口径 / SAVE-SPEC-FINAL.md / I-1、I-2）：
##   - 对外唯一编排入口 commit(reason: String) -> void，签名与 R19 HUD 注入 committer
##     （Callable(func(reason: String) -> void)）逐字一致，供 HUD.travel_to()「先落盘」调用；
##   - 强制同步落盘点：commit() 委托 WorldState._commit_delta(reason) 做 §4.9 原子写
##     （.tmp → flush → rename_absolute → delta.json，单槽 user://saves/slot_01/）。
##     本节点不 FileAccess 读写存档、不构造 / 解析 SaveDelta 十字段（I-1 边界）；
##   - 非强制点走 0.5 s 合并窗口（§4.8 mark_flag_changed / _process）；
##   - I-2：订阅 GameEvents.enemy_defeated / boss_defeated，击杀 flag 只由本节点写，
##     enemy_id 为数据表 id，写入 key 严格遵守 flag 三段式 <模块>.<对象>.<状态>；
##   - flag 三段式正则与 world_state.gd:24 / SAVE-SPEC-FINAL.md §2 逐字一致：
##       ^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$
##   - committed(reason) 信号：落盘委托返回后同步发出，供装配层 / 自检观测
##     「先 commit 后发信号」的不可颠倒顺序。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

signal committed(reason: String)

# flag 严格三段式（与 world_state.gd FLAG_KEY_REGEX / SAVE-SPEC-FINAL.md §2 一致）
const FLAG_KEY_REGEX: String = "^(world|quest|combat|grace|dungeon)\\.[a-z0-9_]+\\.[a-z0-9_]+$"

var _ws: Node = null
var _bus: Node = null
var _re: RegEx = null
var _pending: bool = false
var _merge_window_sec: float = 0.5
var _acc: float = 0.0

# 自检 / 读回（如实登记，不伪造已落盘）
var commit_count: int = 0
var last_commit_reason: String = ""


func _ready() -> void:
    _re = RegEx.new()
    _re.compile(FLAG_KEY_REGEX)
    _ws = get_node_or_null("/root/WorldState")
    _bus = get_node_or_null("/root/GameEvents")
    # I-2：只在信号真实存在时连接，避免跨工位装配差异在三段门禁阶段报错
    if _bus != null:
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


## 非强制点：标记一次 flag 变化，进入 0.5 s 合并窗口（§4.8）。
func mark_flag_changed() -> void:
    _pending = true


## 强制同步落盘点（§4.8）。签名与 R19 HUD 注入 committer 一致：
## 赐福点亮 / 休息、传送、地牢进出、击杀、拾取、任务阶段、退出均由本入口落盘。
func commit(reason: String) -> void:
    _pending = false
    _acc = 0.0
    _commit(reason)


func _commit(reason: String) -> void:
    # 委托 I-1 权威实现的内部原子写入口（.tmp → rename → bak，单槽 delta.json）
    if _ws != null and _ws.has_method("_commit_delta"):
        _ws.call("_commit_delta", reason)
    commit_count += 1
    last_commit_reason = reason
    committed.emit(reason)


## I-2：精英 / 普通敌人击杀。key 三段式：combat.<数据表 id>.defeated
func _on_enemy_defeated(enemy_id: String) -> void:
    _set_flag("combat.%s.defeated" % enemy_id, true)
    commit("enemy_defeated")


## I-2：Boss 击杀，永久保留（respawn_policy = "never"）。
func _on_boss_defeated(boss_id: String) -> void:
    _set_flag("combat.%s.defeated" % boss_id, true)
    _set_flag("combat.%s.phase_two_ready" % boss_id, false)
    commit("boss_defeated")


func _set_flag(key: String, value: Variant) -> void:
    if _re == null or _re.search(key) == null:
        push_warning("[SaveDeltaWriter] 非法三段式 flag key，忽略写入：%s" % key)
        return
    if _ws != null and _ws.has_method("set_flag"):
        _ws.call("set_flag", key, value)
