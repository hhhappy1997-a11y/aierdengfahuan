extends Resource
class_name WorldMapService

## ===========================================================================
## R38 / v0.15.0「大地图 · 2.5D 尺度重构」· 赐福网络 / 大地图纯逻辑服务
##                （Resource + class_name WorldMapService，Rank-3 交付件）
##
## 真源：teamwork/Rank-3/调度任务单-latest.json（id cmd-20261112-234238-656-A3）
## 目录所有权·R38 冻结：本文件 / data/rpg/grace_sites.tres /
##   points_commit_orchestrator.gd / verify_v150_save_commit.gd /
##   verify_world_production_v150.gd / 契约 §3.3 追加段 / 存档与flag规范.md §3.3 /
##   迭代文档 / README 状态段 / teamwork/Rank-3/ / 回执归 Rank-3 唯一写入；
##   courtyard.tscn（A74 后节点 54 / uv 16-8-8，Rank-1）/ hud.gd /
##   presentation.gd / world_scale.tres（Rank-1）/ 其它 Rank 产出 / 既有 .tres
##   数值 / project.godot 一律只读、不改。
##
## 【为什么是 Resource（既是配置表脚本又是纯逻辑服务）】
## - 本轮授权清单只允许新写 1 个脚本（world_map_service.gd）+ 1 张表
##   （grace_sites.tres），不授权单独的 grace_sites_config.gd。故本类
##   `extends Resource` + `class_name WorldMapService`：@export 字段即数据表结构
##   （grace_sites.tres 挂本脚本、script_class=WorldMapService），信号与纯逻辑
##   方法同在本类。加载 grace_sites.tres 得到的那一个 Resource 实例就是
##   「A54 唯一实例」（由生产编排层 PointsCommitOrchestrator 持有、getter 复用，
##   验证脚本绝不 new / load 第二个）。
## - 设计数值全部来自 res://data/rpg/grace_sites.tres，本文件不写死任何
##   [PLACEHOLDER] 数值（@export 默认值 = DEFAULT_* 非法降级基线，刻意 != 表值）。
##
## 【纯逻辑边界（任务单 ① / 契约 I-1）】
## - 不继承 Node、不碰场景树、不 add_child、不取 root、不调用 get_tree()、
##   不用 /root/... 绝对路径、不读写存档文件、不碰渲染、不落盘。
## - 运行时「区域发现 / 赐福点亮 / 快旅落点 / 进度」只记在实例内的字典与计数，
##   绝不写回 .tres、绝不读写 user:// 存档（I-1）；落盘由生产编排层订阅信号完成。
## - 信号是 Object 级能力：4 个稳定 signal 把「区域发现 / 赐福点亮 / 快旅 /
##   动作被拒」广播给生产订阅者（Rank-3 编排层 autoload），不 connect 任何全局节点；
##   ★ A48①：生产运行时订阅者 = PointsCommitOrchestrator autoload 的
##     bind_world_map_service()（生产脚本内 connect 4 信号，非验证脚本）。
##   ★ A54：唯一实例由该编排层装配并持有，get_world_map_service() 复用。
##
## 【公开信号（签名稳定，供生产编排层订阅落盘，见 DONE-R38.md §3）】
##   signal region_discovered(region_id: String, discovered_count: int, progress: int)
##       —— discover_region() 成功时发；progress 为单调递增的地图交互累计进度。
##   signal grace_site_lit(site_id: String, region_id: String, lit_count: int, progress: int)
##       —— light_site() 成功（首次点亮）时发；重复激活被拒、不发本信号、不改状态。
##   signal fast_travel_performed(site_id: String, region_id: String, travel_count: int, progress: int)
##       —— fast_travel() 成功（目标已点亮 + 所属区域已发现）时发；未解锁快旅被拒不发。
##   signal map_action_rejected(reason: String, action_id: String)
##       —— 异常输入 / 未知 id / 重复发现 / 重复激活 / 未解锁快旅 / 区域未发现被拒时发；
##          拒绝事件按 R37 既定策略「不写盘、只走 HUD 反馈」。
##
## 【规则（任务单 ① 逐条）】
## - 区域发现 discover_region(region_id)：表非法 -> no_config；非 String / 空 ->
##   invalid_input；未注册 -> unknown_region；已发现 -> already_discovered（幂等拒绝）；
##   成功置发现态、_discovered_count +1、_progress +1、发 region_discovered。
## - 赐福激活 light_site(site_id)：表非法 / 异常 id / 未知 site 拒绝；已点亮 ->
##   already_lit（★ 重复激活拒绝）；unlock_condition="region_discovered" 时要求
##   所属区域已发现（否则 region_not_discovered）；成功置点亮态、_lit_count +1、
##   _progress +1、发 grace_site_lit。
## - 快旅 fast_travel(site_id)：目标未点亮 -> not_lit（★ 未解锁快旅拒绝）；
##   所属区域未发现 -> region_not_discovered；成功置最近落点、_travel_count +1、
##   _progress +1、发 fast_travel_performed。
## - ★ 进度单调递增：_progress = _discovered_count + _lit_count + _travel_count，
##   仅成功动作 +1（每个成功动作恰好 +1），拒绝一律不改，除显式 reset() 外只增不减。
## - ★ 异常输入拒绝：null / 非 String / 空串 / 未注册 id / config 非法全拒绝且不改状态；
##   invalid_input_policy 首版唯一合法值 "reject"（clamp / ignore 会造不可测分支）。
## - 迷雾揭开：区域发现即揭开该区域迷雾；编排层落 world.map.fog_revealed（int 单调）。
## - reset()：回到构造初始态（每场新一局）；从 .tres 加载时 _init() 调一次，
##   ★ reset() 不预填任何依赖 @export 字段的状态（加载期字段尚未赋值）。
##
## 【三段式 flag 落盘口径（编排层实现，本服务只发信号；见契约 §3.3 R38 段）】
##   任务单示意 `world.map.region_<id>.discovered` 为四段，与冻结三段式正则
##   ^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$ 冲突，
##   R38 落盘收敛为严格三段（<id> 逐字保留、语义不变、机器正则全 PASS）：
##     world.region_<region_id>.discovered  bool  区域发现
##     grace.site_<site_id>.lit            bool  赐福点亮   （示意本身即三段，原样采用）
##     world.map.progress                  int   地图交互累计进度（单调递增）
##     world.map.fog_revealed              int   已揭开迷雾区域数（单调递增）
##     world.map.last_fast_travel          String 最近快旅落点（非单调·最近覆盖）
##   ★ 编排层 _commit_world_map() 显式隔离：writes 绝不含 grace.trial.points /
##     spent_points；commit(reason) 十字段冻结 / schema_version=3 / 不写 removals /
##     原子写 / 先落盘再改运行时实例 / 重启读回一致。
##
## 【调参唯一入口（只改表不改代码）】
##   godot/data/rpg/grace_sites.tres —— 4 个分区 id / 4 个赐福点 5 字段 /
##   invalid_input_policy 全在此一处。校准同步清单：.tres -> 两份 verify 的 EXPECT_*
##   -> teamwork/迭代-v0.15.0-大地图与2.5D.md 数值表 -> 三段门禁；不静默改数。
## 引擎：Godot 4.7.2 / GDScript，全静态类型，零付费、零外部依赖。
## ===========================================================================

## ---- 公开信号（4 个，签名稳定；生产订阅者 = PointsCommitOrchestrator autoload）----
signal region_discovered(region_id: String, discovered_count: int, progress: int)
signal grace_site_lit(site_id: String, region_id: String, lit_count: int, progress: int)
signal fast_travel_performed(site_id: String, region_id: String, travel_count: int, progress: int)
signal map_action_rejected(reason: String, action_id: String)

## ---- 表结构契约（签名稳定）----
const POLICY_REJECT: String = "reject"
const UNLOCK_NONE: String = "none"
const UNLOCK_REGION_DISCOVERED: String = "region_discovered"
const SITE_FIELDS: PackedStringArray = [
	"site_id", "region_id", "position", "display_name", "unlock_condition",
]

## ---- 方法返回 reason（公开常量，签名稳定）----
const REASON_OK: String = "ok"
const REASON_NO_CONFIG: String = "no_config"
const REASON_INVALID_INPUT: String = "invalid_input"
const REASON_UNKNOWN_REGION: String = "unknown_region"
const REASON_UNKNOWN_SITE: String = "unknown_site"
const REASON_ALREADY_DISCOVERED: String = "already_discovered"
const REASON_ALREADY_LIT: String = "already_lit"
const REASON_NOT_LIT: String = "not_lit"
const REASON_REGION_NOT_DISCOVERED: String = "region_not_discovered"

## 非 String 的 id 在 map_action_rejected payload 里的统一占位（可机器判定、不崩）。
const ID_NONE: String = "<none>"

## ---- [PLACEHOLDER] 降级基线（字段缺失 / 表非法时用，刻意 != 设计数值）----
const DEFAULT_REGION_IDS: PackedStringArray = []
const DEFAULT_SITES: Array[Dictionary] = []
const DEFAULT_INVALID_INPUT_POLICY: String = POLICY_REJECT

## ---- 表级字段（@export 默认值 = 降级基线；设计数值在 .tres）----
@export var region_ids: PackedStringArray = DEFAULT_REGION_IDS               # [PLACEHOLDER]
@export var sites: Array[Dictionary] = DEFAULT_SITES                         # [PLACEHOLDER]
@export var invalid_input_policy: String = DEFAULT_INVALID_INPUT_POLICY       # [PLACEHOLDER]

## ---- 运行时状态（本实例内，不持久化、不写回 .tres；I-1）----
var _discovered: Dictionary = {}      # region_id -> bool
var _lit: Dictionary = {}             # site_id -> bool
var _discovered_count: int = 0
var _lit_count: int = 0
var _travel_count: int = 0
var _progress: int = 0                # = discovered + lit + travel，单调递增（除 reset）
var _last_fast_travel: String = ""
var _reject_count: int = 0
var _last_result: Dictionary = {}
var _last_reject_reason: String = ""


func _init() -> void:
	reset()


## 回到构造初始态：清发现 / 点亮 / 落点 / 计数 / 最近结果；★ 不预填任何依赖
## @export 字段的状态（从 .tres 加载期 _init() 先于属性赋值执行）。每场新一局调用。
func reset() -> void:
	_discovered = {}
	_lit = {}
	_discovered_count = 0
	_lit_count = 0
	_travel_count = 0
	_progress = 0
	_last_fast_travel = ""
	_reject_count = 0
	_last_result = {}
	_last_reject_reason = ""


## ---- 全表合法性（异常一律 false，不崩、不抛）----
func is_valid() -> bool:
	if region_ids == null or region_ids.is_empty():
		return false
	var seen_regions: Dictionary = {}
	for r: String in region_ids:
		if r.is_empty() or not _is_snake(r) or seen_regions.has(r):
			return false
		seen_regions[r] = true
	if sites == null or sites.is_empty():
		return false
	var seen_ids: Dictionary = {}
	for entry: Variant in sites:
		if typeof(entry) != TYPE_DICTIONARY:
			return false
		var e: Dictionary = entry as Dictionary
		for f: String in SITE_FIELDS:
			if not e.has(f):
				return false
		var sid: Variant = e["site_id"]
		var rid: Variant = e["region_id"]
		var pos: Variant = e["position"]
		var dname: Variant = e["display_name"]
		var cond: Variant = e["unlock_condition"]
		if typeof(sid) != TYPE_STRING or String(sid).is_empty() or not _is_snake(String(sid)):
			return false
		if seen_ids.has(String(sid)):
			return false
		seen_ids[String(sid)] = true
		if typeof(rid) != TYPE_STRING or not seen_regions.has(String(rid)):
			return false
		if typeof(pos) != TYPE_VECTOR2:
			return false
		var pv: Vector2 = pos as Vector2
		if is_nan(pv.x) or is_nan(pv.y) or is_inf(pv.x) or is_inf(pv.y):
			return false
		if pv.x < 0.0 or pv.y < 0.0:
			return false
		if typeof(dname) != TYPE_STRING or String(dname).is_empty():
			return false
		if typeof(cond) != TYPE_STRING:
			return false
		var c: String = String(cond)
		if c != UNLOCK_NONE and c != UNLOCK_REGION_DISCOVERED:
			return false
	if typeof(invalid_input_policy) != TYPE_STRING:
		return false
	return String(invalid_input_policy) == POLICY_REJECT


## 对象段必须全小写 snake_case（保证拼出的三段式 flag key 通过冻结正则）。
func _is_snake(s: String) -> bool:
	if s.is_empty():
		return false
	for i: int in range(s.length()):
		var ch: String = s.substr(i, 1)
		var lower: bool = ch >= "a" and ch <= "z"
		var digit: bool = ch >= "0" and ch <= "9"
		if not (lower or digit or ch == "_"):
			return false
	return true


## ---- 只读 getter（全静态类型；数值来自表，代码不写死设计值）----
func get_region_ids() -> PackedStringArray:
	return region_ids.duplicate()


## 返回赐福点深拷贝（外层数组 + 每行 Dictionary duplicate），★ 服务只读、绝不写回表。
func get_sites() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Variant in sites:
		out.append((e as Dictionary).duplicate())
	return out


func get_region_count() -> int:
	return region_ids.size()


func get_site_count() -> int:
	return sites.size()


func get_invalid_input_policy() -> String:
	return String(invalid_input_policy)


func has_region(region_id: String) -> bool:
	return region_ids.has(region_id)


func has_site(site_id: String) -> bool:
	return not _find_site(site_id).is_empty()


func get_site_region(site_id: String) -> String:
	var e: Dictionary = _find_site(site_id)
	return String(e.get("region_id", "")) if not e.is_empty() else ""


func _find_site(site_id: String) -> Dictionary:
	for e: Variant in sites:
		var d: Dictionary = e as Dictionary
		if String(d.get("site_id", "")) == site_id:
			return d.duplicate()
	return {}


func is_discovered(region_id: String) -> bool:
	return bool(_discovered.get(region_id, false))


func is_lit(site_id: String) -> bool:
	return bool(_lit.get(site_id, false))


func get_discovered_count() -> int:
	return _discovered_count


func get_lit_count() -> int:
	return _lit_count


func get_fast_travel_count() -> int:
	return _travel_count


## ★ 地图交互累计进度：只增不减（除显式 reset），每个成功动作恰好 +1。
func get_progress() -> int:
	return _progress


func get_last_fast_travel() -> String:
	return _last_fast_travel


func get_reject_count() -> int:
	return _reject_count


func get_last_result() -> Dictionary:
	return _last_result.duplicate()


func get_last_reject_reason() -> String:
	return _last_reject_reason


func is_config_valid() -> bool:
	return is_valid()


func get_snapshot() -> Dictionary:
	return {
		"discovered_ids": _discovered.keys(),
		"lit_ids": _lit.keys(),
		"discovered_count": _discovered_count,
		"lit_count": _lit_count,
		"travel_count": _travel_count,
		"progress": _progress,
		"last_fast_travel": _last_fast_travel,
		"reject_count": _reject_count,
		"region_count": get_region_count(),
		"site_count": get_site_count(),
		"config_present": is_valid(),
		"invalid_input_policy": get_invalid_input_policy(),
		"last_result": _last_result.duplicate(),
		"last_reject_reason": _last_reject_reason,
	}


## ---- 统一拒绝（发 map_action_rejected；★ 不改任何状态、不改进度、不写盘）----
func _reject(reason: String, action_id: String) -> Dictionary:
	_reject_count += 1
	_last_reject_reason = reason
	map_action_rejected.emit(reason, action_id)
	return {
		"ok": false,
		"reason": reason,
		"action_id": action_id,
		"progress": _progress,
		"discovered_count": _discovered_count,
		"lit_count": _lit_count,
		"travel_count": _travel_count,
		"config_present": is_valid(),
	}


## ★ 进度推进：三个计数之和，成功动作恰好 +1（拒绝永不调用）。
func _bump_progress() -> void:
	_progress = _discovered_count + _lit_count + _travel_count


## 区域发现：表 / 输入 / 注册三重门；重复发现幂等拒绝；成功发 region_discovered。
func discover_region(region_id: Variant) -> Dictionary:
	if not is_valid():
		return _reject(REASON_NO_CONFIG, ID_NONE)
	if typeof(region_id) != TYPE_STRING or String(region_id).is_empty():
		return _reject(REASON_INVALID_INPUT, ID_NONE)
	var rid: String = String(region_id)
	if not region_ids.has(rid):
		return _reject(REASON_UNKNOWN_REGION, rid)
	if bool(_discovered.get(rid, false)):
		return _reject(REASON_ALREADY_DISCOVERED, rid)
	_discovered[rid] = true
	_discovered_count += 1
	_bump_progress()
	region_discovered.emit(rid, _discovered_count, _progress)
	var r: Dictionary = {
		"ok": true,
		"reason": REASON_OK,
		"region_id": rid,
		"discovered_count": _discovered_count,
		"progress": _progress,
		"config_present": true,
	}
	_last_result = r.duplicate()
	return r


## 赐福激活：★ 重复激活拒绝（already_lit）；解锁条件可数据驱动为
## "region_discovered"（所属区域须先发现）；成功发 grace_site_lit。
func light_site(site_id: Variant) -> Dictionary:
	if not is_valid():
		return _reject(REASON_NO_CONFIG, ID_NONE)
	if typeof(site_id) != TYPE_STRING or String(site_id).is_empty():
		return _reject(REASON_INVALID_INPUT, ID_NONE)
	var sid: String = String(site_id)
	var site: Dictionary = _find_site(sid)
	if site.is_empty():
		return _reject(REASON_UNKNOWN_SITE, sid)
	if bool(_lit.get(sid, false)):
		return _reject(REASON_ALREADY_LIT, sid)
	var rid: String = String(site["region_id"])
	if String(site["unlock_condition"]) == UNLOCK_REGION_DISCOVERED \
			and not bool(_discovered.get(rid, false)):
		return _reject(REASON_REGION_NOT_DISCOVERED, sid)
	_lit[sid] = true
	_lit_count += 1
	_bump_progress()
	grace_site_lit.emit(sid, rid, _lit_count, _progress)
	var r: Dictionary = {
		"ok": true,
		"reason": REASON_OK,
		"site_id": sid,
		"region_id": rid,
		"lit_count": _lit_count,
		"progress": _progress,
		"config_present": true,
	}
	_last_result = r.duplicate()
	return r


## 快旅：★ 未解锁（目标未点亮）拒绝；所属区域未发现拒绝；成功发
## fast_travel_performed（最近落点覆盖、进度 +1）。
func fast_travel(site_id: Variant) -> Dictionary:
	if not is_valid():
		return _reject(REASON_NO_CONFIG, ID_NONE)
	if typeof(site_id) != TYPE_STRING or String(site_id).is_empty():
		return _reject(REASON_INVALID_INPUT, ID_NONE)
	var sid: String = String(site_id)
	var site: Dictionary = _find_site(sid)
	if site.is_empty():
		return _reject(REASON_UNKNOWN_SITE, sid)
	if not bool(_lit.get(sid, false)):
		return _reject(REASON_NOT_LIT, sid)
	var rid: String = String(site["region_id"])
	if not bool(_discovered.get(rid, false)):
		return _reject(REASON_REGION_NOT_DISCOVERED, sid)
	_last_fast_travel = sid
	_travel_count += 1
	_bump_progress()
	fast_travel_performed.emit(sid, rid, _travel_count, _progress)
	var r: Dictionary = {
		"ok": true,
		"reason": REASON_OK,
		"site_id": sid,
		"region_id": rid,
		"travel_count": _travel_count,
		"progress": _progress,
		"config_present": true,
	}
	_last_result = r.duplicate()
	return r
