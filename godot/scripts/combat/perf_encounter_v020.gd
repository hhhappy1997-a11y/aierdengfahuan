extends SceneTree
## ===========================================================================
## R24 / cmd-20261109-205253-734-A4 · Rank-4 L4「泄漏与节点数曲线」真跑采集
##
## 目标：对 res://scenes/encounter_v010.tscn 反复 instantiate -> add_child ->
##   free 共 20 轮，每轮记录 Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
##   与 OS.get_static_memory_usage()，输出逐轮曲线并判定：
##     (a) 节点数每轮 free 后是否回落到基线；
##     (b) 节点数是否随轮次台阶式上涨（泄漏特征）。
##
## 【为何必须逐帧 await —— 真跑实测，非推测】
##   首版在 _initialize() 同步循环里 add_child/free 并「显式 call("_ready")」
##   （沿用 verify_encounter_v010.gd:79-111 的既有惯例），真跑结果为：
##     BASELINE nodes=0；20 轮 SEQ_NODES_ADD/SEQ_NODES_FREE 全为 [0,...]；
##     RESULT=DATA_UNRELIABLE；每轮另有 2 条引擎级绝对路径 ERROR。
##   原因：Performance.OBJECT_NODE_COUNT 是「每帧更新」的帧缓存，_initialize()
##   同步执行期间引擎一帧未跑，monitor 从未刷新，恒为 0；且此期 root 尚未进入
##   活动场景树，add_child 不 flush _ready、既有件 /root/... 绝对路径不可解析。
##   该同步试跑日志留证于 teamwork/Rank-4/L4-MAIN-sync-explicit-ready.log。
##   本版改为逐轮 await process_frame：帧循环启动后 root 进入活动场景树，
##   engine 按真实运行时语义自动 flush _ready（等价于「若需初始化」的惯例目的，
##   且不会重复调用），monitor 每帧刷新，绝对路径亦可正常解析。
##
## 【为何加 warmup 段 —— 第二版真跑实测的隔离控制】
##   第二版（逐帧、无 warmup）日志 L4-MAIN-perframe-no-warmup.log 显示：
##     全局节点数在 round00~03 从 9 一次性涨到 16（+7），round04~19 共 16 轮
##     完全恒定在 16；每轮 nodes_add - nodes_free 恒为 6（= 实例子树真实节点数），
##     内存首轮一次性 +18MB 后 19 轮仅 ~7.8KB 波动。
##   即增长有上限、前 4 轮后归零，且实例每轮都完整释放 6 个节点 —— 属 autoload
##   帧初始化 / 资源缓存的「一次性装配」，不是每轮累积泄漏。为隔离该变量、避免把
##   一次性漂移误判成台阶式上涨，正式 20 轮前先 warmup：12 空帧 + 1 次预热
##   instantiate/add/free，待 autoload 装配与 .tres 缓存落定后取稳定基线再采集。
##   warmup 的数字如实登记，不隐藏、不删改；正式 20 轮在该稳定基线上进行。
##
## 不伪造数字：每个数都来自引擎 API 实时采集；另用递归 _count_tree 统计实例子树
##   真实节点数作为独立佐证，并用 director._ready 是否产出 _state 验证初始化已 flush。
##   若 monitor 仍不随 add/free 变化，则输出 DATA_UNRELIABLE 并如实写明原因。
## 门禁 / 可复跑命令（ROOT=F:/Game/aierdengfahuan/godot，
##   ENGINE=D:/Godot/Godot_v4.7.2-stable_win64.exe）：
##   G1 $ENGINE --headless --path $ROOT --import
##   G2 $ENGINE --headless --path $ROOT --check-only --script res://scripts/combat/perf_encounter_v020.gd
##   G3 $ENGINE --headless --path $ROOT --quit
##   主真跑 $ENGINE --headless --path $ROOT --script res://scripts/combat/perf_encounter_v020.gd
## 只新增本文件；不改 courtyard.tscn / encounter_director.gd / project.godot /
##   encounter_v010.tscn / 既有战斗件 / 美术资源。GDScript 全静态类型。中文 UTF-8。
## ===========================================================================

const SCENE_PATH: String = "res://scenes/encounter_v010.tscn"
const ROUNDS: int = 20
const WARMUP_FRAMES: int = 12

var _nodes_before: Array[int] = []
var _nodes_add: Array[int] = []
var _mem_add: Array[int] = []
var _nodes_free: Array[int] = []
var _mem_free: Array[int] = []
var _tree_nodes: Array[int] = []
var _ready_flushed: Array[bool] = []
var _warm_start: int = 0
var _warm_end: int = 0


func _initialize() -> void:
	print("[PERF_V020] ==== R24 L4 节点数 / 静态内存曲线采集 START ====")
	print("[PERF_V020] scene=%s rounds=%d mode=per_frame_await warmup_frames=%d" % [
		SCENE_PATH, ROUNDS, WARMUP_FRAMES])

	var packed: PackedScene = ResourceLoader.load(
		SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		print("[PERF_V020] FATAL: ResourceLoader.load 返回 null，无法采集 | path=%s" % SCENE_PATH)
		print("[PERF_V020] RESULT=LOAD_FAILED")
		quit(1)
		return

	# ---- warmup：先推进 2 帧启动帧循环，再跑 WARMUP_FRAMES 空帧让 autoload
	#      一次性装配完成，最后做 1 次预热实例化让 .tres / 字体资源缓存落定。
	await process_frame
	await process_frame
	_warm_start = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for _w: int in range(WARMUP_FRAMES):
		await process_frame
	var pre: Node = packed.instantiate()
	if pre != null:
		root.add_child(pre)
		await process_frame
		pre.free()
		await process_frame
	_warm_end = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("[PERF_V020] WARMUP nodes_start=%d nodes_end=%d drift=%+d（autoload 一次性装配，如实登记）" % [
		_warm_start, _warm_end, _warm_end - _warm_start])

	var base_nodes: int = _warm_end
	var base_mem: int = int(OS.get_static_memory_usage())
	print("[PERF_V020] BASELINE nodes=%d mem_bytes=%d（warmup 后稳定基线）" % [base_nodes, base_mem])
	print("[PERF_V020] ---- 正式 20 轮逐轮曲线（before=add 前 / add=add_child+1 帧 / free=free+1 帧）----")

	for i: int in range(ROUNDS):
		var n_before: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var inst: Node = packed.instantiate()
		if inst == null:
			print("[PERF_V020] FATAL: instantiate 返回 null | round=%d" % i)
			print("[PERF_V020] RESULT=INSTANTIATE_FAILED")
			quit(1)
			return
		root.add_child(inst)
		# 帧循环已启动：引擎在此帧自动 flush _ready（真实运行时语义），不手工 call 以免重复。
		await process_frame
		var n_add: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var m_add: int = int(OS.get_static_memory_usage())
		var t_nodes: int = _count_tree(inst)
		# _state 由 director._ready 创建；非 null 即证明 _ready 已被引擎 flush。
		var flushed: bool = inst.get("_state") != null
		inst.free()
		# 再推进 1 帧，让 monitor 刷新到 free 之后的真实值。
		await process_frame
		var n_free: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var m_free: int = int(OS.get_static_memory_usage())
		_nodes_before.append(n_before)
		_nodes_add.append(n_add)
		_mem_add.append(m_add)
		_nodes_free.append(n_free)
		_mem_free.append(m_free)
		_tree_nodes.append(t_nodes)
		_ready_flushed.append(flushed)
		print("[PERF_V020] round=%02d ready_flushed=%s tree_nodes=%d nodes_before=%d nodes_add=%d mem_add=%d nodes_free=%d mem_free=%d d_nodes=%+d d_mem=%+d" % [
			i, str(flushed), t_nodes, n_before, n_add, m_add, n_free, m_free,
			n_free - base_nodes, m_free - base_mem])

	_verdict(base_nodes, base_mem)
	quit(0)


## 独立佐证：递归统计实例子树真实节点数（不依赖 Performance monitor 缓存）。
func _count_tree(node: Node) -> int:
	var total: int = 1
	for child: Node in node.get_children():
		total += _count_tree(child)
	return total


func _verdict(base_nodes: int, base_mem: int) -> void:
	var n: int = _nodes_free.size()
	if n == 0:
		print("[PERF_V020] RESULT=NO_SAMPLES（未采集到任何轮次，如实登记）")
		return

	# 采样有效性：monitor 是否随 add/free 刷新，且增量是否等于实例子树真实节点数
	var responsive: bool = false
	var delta_matches_tree: int = 0
	for i: int in range(n):
		if _nodes_add[i] != _nodes_free[i]:
			responsive = true
		if _nodes_add[i] - _nodes_free[i] == _tree_nodes[i]:
			delta_matches_tree += 1

	# 实例子树真实节点数是否 20 轮恒定；_ready 是否每轮都已 flush
	var tree_stable: bool = true
	var expected_tree: int = _tree_nodes[0]
	var ready_all: bool = true
	for i: int in range(n):
		if _tree_nodes[i] != expected_tree:
			tree_stable = false
		if not _ready_flushed[i]:
			ready_all = false

	# (a) 回落判定：每轮 free 后节点数 == 该轮 add 前（抵御基线漂移）
	var back_count: int = 0
	var all_back: bool = true
	var nondecreasing: bool = true
	var any_rise: bool = false
	var max_free: int = -1
	var before_min: int = _nodes_before[0]
	var before_max: int = _nodes_before[0]
	for i: int in range(n):
		var v: int = _nodes_free[i]
		if v == _nodes_before[i]:
			back_count += 1
		else:
			all_back = false
		max_free = maxi(max_free, v)
		before_min = mini(before_min, _nodes_before[i])
		before_max = maxi(before_max, _nodes_before[i])
		if i > 0:
			if v < _nodes_free[i - 1]:
				nondecreasing = false
			if v > _nodes_free[i - 1]:
				any_rise = true

	# (b) 台阶式上涨：free 后节点数随轮次单调不减、且存在上升、末轮高于首轮
	var staircase: bool = (not all_back) and nondecreasing and any_rise and _nodes_free[n - 1] > _nodes_free[0]
	var baseline_drift: int = before_max - before_min

	var mem_first: int = _mem_free[0]
	var mem_last: int = _mem_free[n - 1]
	var mem_max: int = mem_first
	var mem_min: int = mem_first
	var mem_nondecreasing: bool = true
	for i: int in range(n):
		mem_max = maxi(mem_max, _mem_free[i])
		mem_min = mini(mem_min, _mem_free[i])
		if i > 0 and _mem_free[i] < _mem_free[i - 1]:
			mem_nondecreasing = false

	print("[PERF_V020] ---- 判定 ----")
	print("[PERF_V020] WARMUP nodes_start=%d nodes_end=%d drift=%+d（一次性装配，不计入 20 轮）" % [
		_warm_start, _warm_end, _warm_end - _warm_start])
	print("[PERF_V020] SEQ_NODES_BEFORE=%s" % str(_nodes_before))
	print("[PERF_V020] SEQ_NODES_ADD=%s" % str(_nodes_add))
	print("[PERF_V020] SEQ_NODES_FREE=%s" % str(_nodes_free))
	print("[PERF_V020] SEQ_MEM_FREE_BYTES=%s" % str(_mem_free))
	print("[PERF_V020] VERDICT_SAMPLES_VALID=%s（monitor 随 add/free 刷新；add-free 增量 == tree_nodes 的轮数 %d/%d）" % [
		str(responsive), delta_matches_tree, n])
	print("[PERF_V020] VERDICT_TREE_NODES_STABLE=%s（实例子树真实节点数=%d）" % [str(tree_stable), expected_tree])
	print("[PERF_V020] VERDICT_READY_FLUSHED=%s（20 轮引擎自动 flush _ready）" % str(ready_all))
	print("[PERF_V020] VERDICT_BASELINE_DRIFT=%d（nodes_before 区间 [%d,%d]，0=无漂移）" % [
		baseline_drift, before_min, before_max])
	print("[PERF_V020] VERDICT_NODE_FALLBACK=%s（%d/%d 轮 free 后 == 该轮 add 前；max_free=%d）" % [
		str(all_back), back_count, n, max_free])
	print("[PERF_V020] VERDICT_STAIRCASE=%s（nondecreasing=%s any_rise=%s first=%d last=%d）" % [
		str(staircase), str(nondecreasing), str(any_rise), _nodes_free[0], _nodes_free[n - 1]])
	print("[PERF_V020] MEM_BASELINE=%d MEM_FIRST=%d MEM_LAST=%d MEM_MIN=%d MEM_MAX=%d DELTA_LAST_VS_BASE=%+d MEM_NONDECREASING=%s" % [
		base_mem, mem_first, mem_last, mem_min, mem_max, mem_last - base_mem, str(mem_nondecreasing)])

	var result: String
	if not responsive:
		result = "DATA_UNRELIABLE"
		print("[PERF_V020] NOTE: Performance.OBJECT_NODE_COUNT 仍未随 add_child/free 变化；"
			+ "帧缓存未刷新或 headless 模式不支持，不据此硬下回落/台阶结论（如实登记原因）。")
	elif staircase:
		result = "LEAK_SUSPECT"
		print("[PERF_V020] NOTE: 节点数呈台阶式上涨，疑似存在未释放节点/信号连接，需进一步定位。")
	elif all_back:
		result = "NO_LEAK"
		print("[PERF_V020] NOTE: 20 轮节点数均回落到该轮基线，未见台阶式上涨。")
	else:
		result = "NODE_DRIFT"
		print("[PERF_V020] NOTE: 节点数偏离基线但非单调台阶，需人工复核序列。")
	print("[PERF_V020] RESULT=%s" % result)
	print("[PERF_V020] ==== R24 L4 采集 END ====")
