extends RefCounted
class_name GraceUpgradeService

## ===========================================================================
## R27 / v0.5.0 · 赐福点数兑换「纯逻辑」服务（RefCounted）
## R28 / v0.6.0 · ③ 双写收敛：以 unlocked 为唯一权威件、bought_<id> 仅兼容读取
##
## 纯逻辑边界：不继承 Node、不碰场景树、不 load 资源、不读写 flag、不落盘。
##   购买判定的唯一入口是 can_purchase(points, spent_points, upgrade)，
##   记账与防刷状态留在本实例内，由外部（接线脚本 / 存档层）注入与取回。
##
## 【防刷铁律（任务单 ③ / 契约 F1~F8，R28 逐字未动）】
##  - 余额 = points - spent_points；消费只让 spent_points 单调递增，
##    绝不 removals、绝不回退 grace.trial.points（points 只读，本服务从不写入）。
##  - 重复购买同一 id 必须被拒绝：_purchased_ids 一旦置位，can_purchase 恒 false，
##    purchase() 不重复扣点（幂等）。
##  - spent_points 单调递增：以 max(内部累计, 外部传入) 为基准再 +cost，
##    任何外部传入的落后值都不会把累计拉回退。
##  - 异常输入（null / {} / 缺字段 / 负 cost / 未知 effect_key / 负点数）一律拒绝，不崩。
##
## 【R28 ③ 双写收敛口径（本文件是唯一写入件，如实登记影响范围）】
##  收敛前：grace.upgrade_<id>.unlocked（hud.gd 裁决 A23 权威）与
##          grace.trial.bought_<id>（Rank-2 读取口径）在同一 commit 内双写，冗余。
##  收敛后：以 grace.upgrade_<id>.unlocked 为【唯一权威写入件】；
##          grace.trial.bought_<id> 仅作【兼容读取】（不再新写）。
##  实现：所有「运行时读取 / 写入口径」都经本文件的集中式静态函数
##        purchased_flag_key(id)；R28 起该函数返回权威 unlocked key。
##        因此无需改任何调用方，即完成全局收敛：
##     - 写入点：hud.gd:763 `set_flag(purchased_flag_key(u.id), true)`、
##               grace_upgrade_runtime.gd:284 `set_flag(purchased_flag_key(upgrade_id), true)`
##               → 收敛后写 unlocked；hud.gd:761 本就写 unlocked_key（同值），
##               两处 set_flag 幂等合并为单写，grace.trial.bought_* 不再有任何新写点。
##     - 读取点：hud.gd:643/744、grace_upgrade_runtime.gd:96/265
##               `get_flag(purchased_flag_key(id))` → 收敛后读 unlocked（权威）。
##  兼容读取既有存档：新增 legacy_bought_flag_key(id) / is_purchased_in_flags() /
##        collect_purchased_ids_from_flags() / load_state_from_flags()，
##        以「unlocked OR 旧 bought_」判定，保证纯 bought_ 旧档可读、不破坏 F1 防刷。
##  如实登记的遗留影响（不谎报）：
##    - hud.gd（Rank-1 所有权）与 grace_upgrade_runtime.gd（本轮白名单外）未调用上述
##      新兼容函数；它们收敛后只 get_flag(unlocked)。生产存档自 R27B 起每次购买都同时
##      落 unlocked + bought_，两键成对，收敛不丢已购态；「纯 bought_ 旧档」的兼容
##      读取入口已在本文件提供，调用方接入属 Rank-1 / 总指挥后续动作，本轮如实登记。
##    - hud.gd 头注 / :566-568 关于「另写 Rank-2 读取口径 bought_」的文案与收敛后
##      实际行为（写 unlocked）出现偏差；hud.gd 归 Rank-1，本轮未改，如实登记。
##    - F1~F8 防刷核心（_purchased_ids / _spent_points / can_purchase / purchase /
##      balance / _result）逐字未动；key 字符串变化不触及任何防刷判定。
##
## 【三段式 flag key（全部符合 WorldState FLAG_KEY_REGEX）】
##  - grace.trial.points         只读（既有，波次导演累计，绝不回退）
##  - grace.trial.spent_points   只增（本轮新增消费累计）
##  - grace.upgrade_<id>.unlocked 唯一权威（收敛后写入 / 主读；裁决 A23 三段式）
##  - grace.trial.bought_<id>    仅兼容读取（不再新写；旧存档可能含此键）
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const FLAG_POINTS: String = "grace.trial.points"
const FLAG_SPENT_POINTS: String = "grace.trial.spent_points"

## R28 ③：唯一权威件 key 与 hud.gd:55-56 常量逐字对齐（不硬编码四段字面）。
const FLAG_UNLOCKED_PREFIX: String = "grace.upgrade_"
const FLAG_UNLOCKED_SUFFIX: String = ".unlocked"
## R28 ③：旧兼容 key，仅供读取既有存档；本服务及所有收敛后的写入点都不再生成新写。
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


## R28 ③：唯一权威件 key（grace.upgrade_<id>.unlocked）。
## 与 hud.gd:572-573 unlocked_key(upgrade_id) 完全同式，收敛后两边写同一键。
static func authoritative_unlocked_key(id: String) -> String:
	return FLAG_UNLOCKED_PREFIX + id + FLAG_UNLOCKED_SUFFIX


## R28 ③：所有「运行时读取 / 写入口径」的集中式入口。
## 收敛后返回【唯一权威件 unlocked key】（不再返回 grace.trial.bought_<id>）。
## 既有全部调用点（hud.gd:643/744/763、grace_upgrade_runtime.gd:96/265/284、
## verify_grace_upgrade_v050.gd / verify_grace_runtime_v050.gd 夹具）无需改动即自动收敛。
static func purchased_flag_key(id: String) -> String:
	return authoritative_unlocked_key(id)


## R28 ③：旧兼容读取专用 key（grace.trial.bought_<id>）。
## 只用于「既有存档可读」，本服务从不以此 key 生成任何写入件。
static func legacy_bought_flag_key(id: String) -> String:
	return FLAG_BOUGHT_PREFIX + id


## R28 ③：兼容读取判定（纯函数，不碰 WorldState）：
## 以 unlocked（权威）OR 旧 bought_（兼容）判定某 id 是否已购，保证既有存档可读。
## flags 由调用方从 WorldState 快照取得；缺失键一律按 false 处理，不抛错。
static func is_purchased_in_flags(flags: Dictionary, id: String) -> bool:
	if bool(flags.get(authoritative_unlocked_key(id), false)):
		return true
	return bool(flags.get(legacy_bought_flag_key(id), false))


## R28 ③：按兼容口径从 flags 快照收集已购 id（保持传入顺序，只增不减）。
static func collect_purchased_ids_from_flags(flags: Dictionary, ids: Array) -> Array:
	var out: Array = []
	for v: Variant in ids:
		var id: String = str(v)
		if is_purchased_in_flags(flags, id):
			out.append(id)
	return out


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


## R28 ③：从 WorldState flags 快照按「unlocked OR 旧 bought_」兼容恢复。
## 供运行时 / 装配层接入以兼容纯 bought_ 旧档；不改 load_state 既有签名与 F1 防刷语义。
func load_state_from_flags(flags: Dictionary, ids: Array, spent_points: int) -> void:
	load_state(spent_points, collect_purchased_ids_from_flags(flags, ids))


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
