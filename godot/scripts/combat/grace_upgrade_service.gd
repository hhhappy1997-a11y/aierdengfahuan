extends RefCounted
class_name GraceUpgradeService

## ===========================================================================
## R27 / v0.5.0 · 赐福点数兑换「纯逻辑」服务（RefCounted）
##
## 纯逻辑边界：不继承 Node、不碰场景树、不 load 资源、不读写 flag、不落盘。
##   购买判定的唯一入口是 can_purchase(points, spent_points, upgrade)，
##   记账与防刷状态留在本实例内，由外部（接线脚本 / 存档层）注入与取回。
##
## 【防刷铁律（任务单 ③ / 契约）】
##  - 余额 = points - spent_points；消费只让 spent_points 单调递增，
##    绝不 removals、绝不回退 grace.trial.points（points 只读，本服务从不写入）。
##  - 重复购买同一 id 必须被拒绝：_purchased_ids 一旦置位，can_purchase 恒 false，
##    purchase() 不重复扣点（幂等）。
##  - spent_points 单调递增：以 max(内部累计, 外部传入) 为基准再 +cost，
##    任何外部传入的落后值都不会把累计拉回退。
##  - 异常输入（null / {} / 缺字段 / 负 cost / 未知 effect_key / 负点数）一律拒绝，不崩。
##
## 【三段式 flag key（供接线脚本落盘，本服务只生成字符串、不写 flag）】
##  - grace.trial.points         只读（既有，波次导演累计，绝不回退）
##  - grace.trial.spent_points   只增（本轮新增消费累计）
##  - grace.trial.bought_<id>    每项一个 bool 已购标记（拒绝重复购买）
##  三者均符合 WorldState FLAG_KEY_REGEX：^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const FLAG_POINTS: String = "grace.trial.points"
const FLAG_SPENT_POINTS: String = "grace.trial.spent_points"
const FLAG_BOUGHT_PREFIX: String = "grace.trial.bought_"

## 与 grace_upgrade_config.gd 的 KNOWN_EFFECT_KEYS 保持一致（校准时同步两处）。
## 放在本服务里使「未知 effect_key」也能被纯逻辑层拒绝，不依赖任何 class_name。
const KNOWN_EFFECT_KEYS: PackedStringArray = ["hp_max", "roll_iframe", "attack_power"]

const REASON_OK: String = "ok"
const REASON_INSUFFICIENT: String = "insufficient_points"
const REASON_DUPLICATE: String = "duplicate_id"
const REASON_INVALID_UPGRADE: String = "invalid_upgrade"
const REASON_INVALID_POINTS: String = "invalid_points"

## 已购 id 集合（id -> true）；单调递增，从不 erase（绝不 removals）。
var _purchased_ids: Dictionary = {}
## 本实例累计消费；单调递增，只做 max + cost，从不减小、从不回退。
var _spent_points: int = 0


static func purchased_flag_key(id: String) -> String:
	return FLAG_BOUGHT_PREFIX + id


## 余额 = points - spent_points（纯函数，不判合法性，允许负值供上层识别异常）。
static func balance(points: int, spent_points: int) -> int:
	return points - spent_points


## 从落盘 flag 恢复已购状态（重开进程 / 装配时调用一次）。
## spent_points 取 max(0, 传入) 防脏值；purchased_ids 只增不减。
func load_state(spent_points: int, purchased_ids: Array) -> void:
	_spent_points = maxi(0, spent_points)
	for v: Variant in purchased_ids:
		var id: String = str(v)
		if not id.is_empty():
			_purchased_ids[id] = true


func get_spent_points() -> int:
	return _spent_points


func is_purchased(id: String) -> bool:
	return _purchased_ids.has(id)


func get_purchased_ids() -> Array[String]:
	var out: Array[String] = []
	for k: Variant in _purchased_ids.keys():
		out.append(str(k))
	return out


## 把 upgrade 统一成 Dictionary（兼容 .tres 的 Dictionary 行与 UpgradeData 视图）。
## 结构非法返回空 Dictionary。只读，不抛错。
func _as_dict(upgrade: Variant) -> Dictionary:
	if typeof(upgrade) == TYPE_DICTIONARY:
		return upgrade as Dictionary
	if upgrade is Object:
		var o: Object = upgrade as Object
		var d: Dictionary = {}
		for key: String in ["id", "display_name", "cost", "effect_key", "effect_value"]:
			var found: bool = false
			for p: Dictionary in o.get_property_list():
				if String(p.get("name", "")) == key:
					found = true
					break
			if not found:
				return {}
			d[key] = o.get(key)
		return d
	return {}


## 单项字段合法性（不查余额、不查已购）：5 字段齐全且类型正确、
## id / 名称 / effect_key 非空、effect_key 命中落点白名单、cost>0、effect_value>0。
func _is_upgrade_shape_valid(row: Dictionary) -> bool:
	if row.is_empty():
		return false
	for key: String in ["id", "display_name", "cost", "effect_key", "effect_value"]:
		if not row.has(key):
			return false
	var id_v: Variant = row.get("id")
	var name_v: Variant = row.get("display_name")
	var key_v: Variant = row.get("effect_key")
	var cost_v: Variant = row.get("cost")
	var ev_v: Variant = row.get("effect_value")
	if typeof(id_v) != TYPE_STRING or String(id_v).is_empty():
		return false
	if typeof(name_v) != TYPE_STRING or String(name_v).is_empty():
		return false
	if typeof(key_v) != TYPE_STRING or String(key_v).is_empty():
		return false
	if not KNOWN_EFFECT_KEYS.has(String(key_v)):
		return false
	if typeof(cost_v) != TYPE_INT and typeof(cost_v) != TYPE_FLOAT:
		return false
	if int(cost_v) <= 0:
		return false
	if typeof(ev_v) != TYPE_INT and typeof(ev_v) != TYPE_FLOAT:
		return false
	if float(ev_v) <= 0.0:
		return false
	return true


## 能否购买：点数合法（points>=0 / spent_points>=0）、结构合法、未购过、余额 >= cost。
## 纯判定，不改任何状态。
func can_purchase(points: int, spent_points: int, upgrade: Variant) -> bool:
	if points < 0 or spent_points < 0:
		return false
	var row: Dictionary = _as_dict(upgrade)
	if not _is_upgrade_shape_valid(row):
		return false
	var id: String = str(row.get("id"))
	if is_purchased(id):
		return false
	var cost: int = int(row.get("cost"))
	if balance(points, spent_points) < cost:
		return false
	return true


## 执行一次购买。幂等防重复扣点：
##  - can_purchase 不通过 → ok=false，spent_points / 已购集合均不变（不扣点）。
##  - 通过 → 置位 id、spent_points 单调递增累计，返回新 spent_points 与新余额。
## 返回的 points 是原值（只读），显式证明「绝不回退 grace.trial.points」。
func purchase(points: int, spent_points: int, upgrade: Variant) -> Dictionary:
	var row: Dictionary = _as_dict(upgrade)
	var id: String = str(row.get("id", ""))
	var cost: int = int(row.get("cost", 0))
	var base_spent: int = maxi(_spent_points, spent_points)
	if points < 0 or spent_points < 0:
		return _result(false, REASON_INVALID_POINTS, id, cost, base_spent, points)
	if not _is_upgrade_shape_valid(row):
		return _result(false, REASON_INVALID_UPGRADE, id, cost, base_spent, points)
	if is_purchased(id):
		return _result(false, REASON_DUPLICATE, id, cost, base_spent, points)
	if balance(points, base_spent) < cost:
		return _result(false, REASON_INSUFFICIENT, id, cost, base_spent, points)
	# 唯一写入路径：只增 spent_points、只增 purchased 标记，绝不 removals、绝不写 points。
	_spent_points = base_spent + cost
	_purchased_ids[id] = true
	return _result(true, REASON_OK, id, cost, _spent_points, points)


func _result(ok: bool, reason: String, id: String, cost: int, spent: int, points: int) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"id": id,
		"cost": cost,
		"spent_points": spent,
		"balance": balance(points, spent),
		"points": points,
	}
