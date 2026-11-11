extends Node
## SaveSystem autoload 装配占位（R8 · Rank-1）→ R27 占位接线（cmd-20261111-083350-232-A1）。
## 注册路径：res://scripts/world/save_system.gd（project.godot [autoload] SaveSystem）
##
## R8 背景：R7 全工程门禁 18 条 ERROR 中 6 条来自本 autoload 注册路径下全工程根没有脚本，
## 导致 autoload 创建 / 实例化失败。本件只做「装配层闭合」，让 5 个 autoload 指向实际存在的脚本。
##
## R27 [ROUND=R27 / v0.5.0] 完善：在 _ready() 里经既有 WorldState._load() 入口把磁盘
##   user://saves/slot_01/delta.json 自动读回内存，兑现「玩家重启 exe 后 HUD 直接读出
##   历史最佳 / 赐福点数 / 试炼完成态」（DONE-R26B.md §8.1 登记的跨 exe 读回缺口）。
##   边界（严格逐条遵守任务单）：
##     - 不改 world_state.gd、不改 project.godot 的 [autoload] 段；
##     - 不新增存档顶层字段、不动 schema_version=3：_load() 只把既有 delta.json 的
##       flags 回放进 WorldState 内存，不构造 / 解析 / 改写 SaveDelta 十字段，不用 removals；
##     - 本件自己不 FileAccess 读写存档、不 set_flag、不 commit，只读回；
##     - 提供 is_loaded() 查询接线是否完成读回。
##
## 依赖 / 模式缺失降级（push_warning、不崩、不谎报）：
##   - WorldState 节点取不到 或 没有 _load() 方法 → 降级，is_loaded()=false。
##   - --script / SceneTree 工具进程默认**不加载玩家存档**：实测 Godot 4.7.2 下 autoload
##     的 _ready() 里 /root/WorldState 绝对路径可解析，若在此模式无条件 _load()，会把磁盘
##     里已有的 grace.*.lit / last_grace_id 演示 flag 灌进验证进程，使既有回归（如
##     verify_hud_binding.gd 的 A2 点亮态增量依赖 lit=false 初值）基线被污染而回退。
##     故 --script 且未带显式用户标记时如实降级，保证 11 组既有回归 WorldState 基线与
##     R26B 完全一致、全不回退。真实验证载体需要读回时，在 `--` 之后带用户标记 v050_read
##     显式启用（等价于 verify_wave_persist_v040.gd 的「一次性测试装配修正」口径）。
##   - 真实游戏 / 纯场景运行（main_scene=courtyard.tscn、玩家打开 exe、三段门禁 G3
##     --headless --quit）无 --script，恒自动读回，已实测打印三 flag 真实读回值。
##   - 探活沿用 /root/WorldState 绝对路径（与 hud.gd / SaveDeltaWriter.gd 同款）；
##     验证脚本侧一律用 Engine.get_main_loop() + root.get_node_or_null() 相对探活（任务单踩坑）。
##
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

# 接线状态：_ready() 成功经 WorldState._load() 读回后置 true；降级路径恒 false。
# 这是 SaveSystem 实例的运行期状态，不是 SaveDelta 存档的顶层字段（不触碰 schema）。
var _loaded: bool = false


func _ready() -> void:
	_loaded = false
	if not _readback_allowed():
		push_warning("[SaveSystem] --script 工具模式（未带 v050_read 标记）：跳过自动读回（降级，不崩，保护回归基线）")
		return
	var ws: Node = get_node_or_null("/root/WorldState")
	if ws == null:
		push_warning("[SaveSystem] 未解析到 /root/WorldState（依赖未就绪），跳过自动读回（降级，不崩）")
		return
	if not ws.has_method("_load"):
		push_warning("[SaveSystem] WorldState 缺少 _load() 入口，跳过自动读回（降级，不崩）")
		return
	# 既有 I-1 权威实现的回放加载入口：schema_version=3 逐级迁移 → delta.log 回放 →
	# 只把 flags 合并进内存。本件不碰 _delta / _flags / _seq 内部结构。
	ws.call("_load")
	_loaded = true
	# 读回证据：打印三个跨局三段式 flag 的真实读回值（供「写→重启读回」日志比对）。
	if ws.has_method("get_flag"):
		print("[SaveSystem] 自动读回完成 | dungeon.wave_trial.best_wave=%d | grace.trial.points=%d | dungeon.wave_trial.completed=%s" % [
			int(ws.call("get_flag", "dungeon.wave_trial.best_wave", 0)),
			int(ws.call("get_flag", "grace.trial.points", 0)),
			str(ws.call("get_flag", "dungeon.wave_trial.completed", false))])


## 真实游戏 / 纯场景运行恒允许；--script 工具进程仅显式带用户标记 v050_read 时允许。
func _readback_allowed() -> bool:
	if not OS.get_cmdline_args().has("--script"):
		return true
	for a: String in OS.get_cmdline_user_args():
		if a == "v050_read":
			return true
	return false


## 查询接线是否完成读回。真实场景运行成功读回为 true；依赖缺失 / --script 降级为 false。
func is_loaded() -> bool:
	return _loaded
