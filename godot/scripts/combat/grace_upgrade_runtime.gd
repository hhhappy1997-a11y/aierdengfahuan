extends Node
class_name GraceUpgradeRuntime

## ===========================================================================
## R27 / v0.5.0 · 赐福增益「运行时接线 + 购买落盘」（Rank-2 自有独立节点脚本）
##
## 【裁决 A22 / 目录所有权】
##  - 不得写 encounter_director.gd / wave_trial_director.gd（Rank-1 独占）；
##    不得改 hud.gd / save_system.gd / 场景 / 素材 / 契约 / README / project.godot。
##  - 本脚本只做三件事：
##      ① 读三段式 flag（WorldState.get_flag）判断已购项；
##      ② 调用既有公开方法 / @export 把已购增益作用到运行时；
##      ③ 购买落盘经既有 WorldState.set_flag / SaveDeltaWriter.commit。
##  - 绝不 removals、绝不回退 grace.trial.points；spent_points 单调递增。
##
## 【效果接线落点（全部为既有公开接口，零新增战斗数值）】
##  - hp_max       -> EncounterDirector 公开 @export player_max_hp（encounter_director.gd:30）
##                    + 既有公开方法 trial_grace_rest()（:721）把当前 HP 刷到新上限。
##  - roll_iframe  -> player_actions.tres 内 action_04_roll 的公开 @export
##                    invulnerable_end_frame（PlayerActionData @export，运行时实例不改文件）。
##  - attack_power -> player_actions.tres 内 action_05/06 的公开 @export base_attack。
##
## 【如实边界 · 不伪造生效】
##  受裁决 A22（不改两份导演脚本）+ 目录所有权（不改场景 / 不新增 autoload 注册）限制，
##  本独立节点在真机运行时【没有挂载点】：不会随场景树自动实例化、也不会被导演调用。
##  三项效果在 verify_grace_upgrade_v050.gd 中「显式调用 apply_purchased()」实证可生效，
##  但真机自动生效须由 Rank-1 装配层在 courtyard.tscn 挂本节点（或在其导演 _ready 调一次
##  apply_purchased(encounter)）。按裁决 A22 如实登记为「数据已落、效果待接」，不谎报真机已生效。
##  详见 teamwork/Rank-2/DONE-R27.md §4 与 GRACE-UPGRADE-TUNING.md §5。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const CONFIG_PATH: String = "res://data/rpg/grace_upgrades.tres"
const PLAYER_TABLE_PATH: String = "res://data/combat/player_actions.tres"
const COMMIT_REASON: String = "grace_upgrade_purchased"
const ROLL_POSE: String = "roll"
const ATTACK_POSES: PackedStringArray = ["attack_light", "attack_heavy"]

@export var config_path: String = CONFIG_PATH
@export var player_table_path: String = PLAYER_TABLE_PATH
@export var encounter_director_path: NodePath = ^"../EncounterRoot"

## 同一进程内防重复叠加（重启进程后由 flag 重新应用一次，属正常）。
var _applied_ids: Dictionary = {}


func _get_node_from_root(node_name: String) -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	if ml is SceneTree:
		return (ml as SceneTree).root.get_node_or_null(NodePath(node_name))
	return null


func _get_world_state() -> Node:
	return _get_node_from_root("WorldState")


func _get_delta_writer() -> Node:
	return _get_node_from_root("SaveDeltaWriter")


func _load_config() -> GraceUpgradeConfig:
	if not ResourceLoader.exists(config_path):
		return null
	return ResourceLoader.load(config_path, "", ResourceLoader.CACHE_MODE_IGNORE) as GraceUpgradeConfig


## 读取三段式 flag → 把已购增益作用到运行时。
## 返回 {checked, applied, degraded, items:[{id, effect_key, status, before, after, reason}], reasons}
## ws / encounter 可显式注入（验证模式）；为 null 时按 Engine.get_main_loop() 相对探活。
func apply_purchased(encounter: Node = null, ws: Node = null) -> Dictionary:
	var state: Node = ws if ws != null else _get_world_state()
	var items: Array[Dictionary] = []
	var report: Dictionary = {"checked": 0, "applied": 0, "degraded": 0, "items": items, "reasons": []}
	if state == null or not state.has_method("get_flag"):
		report["degraded"] = 1
		report["reasons"] = ["WorldState 不可用（相对探活）→ 数据已落、效果待接"]
		return report
	var cfg: GraceUpgradeConfig = _load_config()
	if cfg == null:
		report["degraded"] = 1
		report["reasons"] = ["grace_upgrades.tres 未加载 → 数据已落、效果待接"]
		return report
	for i: int in range(cfg.upgrade_count()):
		report["checked"] = int(report["checked"]) + 1
		var u := cfg.get_upgrade(i)
		if u == null or not cfg.is_upgrade_valid(u):
			items.append({
				"id": u.id if u != null else "",
				"effect_key": u.effect_key if u != null else "",
				"status": "invalid",
				"reason": "字段缺失/非法，跳过（数据已落、效果待接）",
			})
			report["degraded"] = int(report["degraded"]) + 1
			continue
		var fk: String = GraceUpgradeService.purchased_flag_key(u.id)
		if not bool(state.call("get_flag", fk, false)):
			items.append({"id": u.id, "effect_key": u.effect_key, "status": "not_purchased", "reason": "未购买"})
			continue
		if _applied_ids.has(u.id):
			items.append({"id": u.id, "effect_key": u.effect_key, "status": "already_applied", "reason": "同进程已应用，防重复叠加"})
			continue
		var row: Dictionary = cfg.make_upgrade(u.id, u.display_name, u.cost, u.effect_key, u.effect_value)
		var r: Dictionary = _dispatch(row, encounter)
		items.append(r)
		if bool(r.get("applied", false)):
			_applied_ids[u.id] = true
			report["applied"] = int(report["applied"]) + 1
		else:
			report["degraded"] = int(report["degraded"]) + 1
	return report


func _dispatch(row: Dictionary, encounter: Node) -> Dictionary:
	var ek: String = str(row.get("effect_key", ""))
	match ek:
		"hp_max":
			return _apply_hp_max(row, encounter)
		"roll_iframe":
			return _apply_roll_iframe(row)
		"attack_power":
			return _apply_attack_power(row)
		_:
			return {
				"id": str(row.get("id", "")), "effect_key": ek,
				"applied": false, "status": "degraded",
				"reason": "未知 effect_key → 数据已落、效果待接",
			}


## hp_max：经 EncounterDirector 既有公开 @export player_max_hp + 既有公开方法
## trial_grace_rest()（_grace_rest 内 _player_hp = player_max_hp）刷到新上限。不改导演脚本。
func _apply_hp_max(row: Dictionary, encounter: Node) -> Dictionary:
	var base: Dictionary = {
		"id": str(row.get("id", "")), "effect_key": "hp_max",
		"applied": false, "status": "degraded",
	}
	if encounter == null:
		base["reason"] = "EncounterDirector 未注入 → 数据已落、效果待接"
		return base
	var found: bool = false
	for p: Dictionary in encounter.get_property_list():
		if String(p.get("name", "")) == "player_max_hp":
			found = true
			break
	if not found:
		base["reason"] = "EncounterDirector 无 player_max_hp @export → 数据已落、效果待接"
		return base
	var before: float = float(encounter.get("player_max_hp"))
	encounter.set("player_max_hp", before + float(row.get("effect_value", 0.0)))
	var after: float = float(encounter.get("player_max_hp"))
	var rest_method: String = ""
	if encounter.has_method("trial_grace_rest"):
		rest_method = "trial_grace_rest"
	elif encounter.has_method("debug_grace_rest"):
		rest_method = "debug_grace_rest"
	if not rest_method.is_empty():
		encounter.call(rest_method)
	base["applied"] = true
	base["status"] = "applied"
	base["before"] = before
	base["after"] = after
	base["via"] = "@export player_max_hp + %s()" % rest_method
	return base


## roll_iframe：经 player_actions.tres 运行时实例中 action_04_roll 的既有公开 @export
## invulnerable_end_frame 延长无敌窗口。只改进程内 Resource 实例，绝不改数据表文件。
func _apply_roll_iframe(row: Dictionary) -> Dictionary:
	var base: Dictionary = {
		"id": str(row.get("id", "")), "effect_key": "roll_iframe",
		"applied": false, "status": "degraded",
	}
	if not ResourceLoader.exists(player_table_path):
		base["reason"] = "player_actions.tres 不存在 → 数据已落、效果待接"
		return base
	var table: Resource = load(player_table_path) as Resource
	if table == null:
		base["reason"] = "player_actions.tres 加载失败 → 数据已落、效果待接"
		return base
	var raw: Variant = table.get("actions")
	if typeof(raw) != TYPE_ARRAY:
		base["reason"] = "actions 字段缺失 → 数据已落、效果待接"
		return base
	for a: Variant in (raw as Array):
		var action: PlayerActionData = a as PlayerActionData
		if action == null or action.pose_name != ROLL_POSE:
			continue
		var before: int = action.invulnerable_end_frame
		action.invulnerable_end_frame = before + int(row.get("effect_value", 0))
		base["applied"] = true
		base["status"] = "applied"
		base["before"] = before
		base["after"] = action.invulnerable_end_frame
		base["via"] = "@export PlayerActionData.invulnerable_end_frame（action_04_roll）"
		return base
	base["reason"] = "未找到 action_04_roll → 数据已落、效果待接"
	return base


## attack_power：经 player_actions.tres 运行时实例中 attack_light / attack_heavy 的
## 既有公开 @export base_attack 提升攻击力。只改进程内 Resource 实例，绝不改数据表文件。
func _apply_attack_power(row: Dictionary) -> Dictionary:
	var base: Dictionary = {
		"id": str(row.get("id", "")), "effect_key": "attack_power",
		"applied": false, "status": "degraded",
	}
	if not ResourceLoader.exists(player_table_path):
		base["reason"] = "player_actions.tres 不存在 → 数据已落、效果待接"
		return base
	var table: Resource = load(player_table_path) as Resource
	if table == null:
		base["reason"] = "player_actions.tres 加载失败 → 数据已落、效果待接"
		return base
	var raw: Variant = table.get("actions")
	if typeof(raw) != TYPE_ARRAY:
		base["reason"] = "actions 字段缺失 → 数据已落、效果待接"
		return base
	var patched: int = 0
	var before: float = 0.0
	var after: float = 0.0
	for a: Variant in (raw as Array):
		var action: PlayerActionData = a as PlayerActionData
		if action == null or not ATTACK_POSES.has(action.pose_name):
			continue
		if patched == 0:
			before = action.base_attack
		action.base_attack = action.base_attack + float(row.get("effect_value", 0.0))
		after = action.base_attack
		patched += 1
	if patched == 0:
		base["reason"] = "未找到 attack_light / attack_heavy → 数据已落、效果待接"
		return base
	base["applied"] = true
	base["status"] = "applied"
	base["before"] = before
	base["after"] = after
	base["patched"] = patched
	base["via"] = "@export PlayerActionData.base_attack（attack_light / attack_heavy）"
	return base


## 购买落盘：经既有 WorldState.set_flag / SaveDeltaWriter.commit。
## ★ 唯一写入路径：只写 grace.trial.spent_points（单调递增）与 grace.trial.bought_<id>（bool）；
##   绝不 set_flag(grace.trial.points, ...)（不回退 points）、绝不 removals。
## ws / writer 可显式注入（验证模式）；writer 为 null 时如实降级「flag 仅进程内内存、未落盘」。
func try_purchase(upgrade_id: String, ws: Node = null, writer: Node = null) -> Dictionary:
	var state: Node = ws if ws != null else _get_world_state()
	var out: Dictionary = {"ok": false, "reason": "init", "id": upgrade_id, "committed": false}
	if state == null or not state.has_method("get_flag") or not state.has_method("set_flag"):
		out["reason"] = "WorldState 不可用 → 购买未落盘（降级，不崩）"
		return out
	var cfg: GraceUpgradeConfig = _load_config()
	if cfg == null:
		out["reason"] = "grace_upgrades.tres 未加载 → 购买未落盘"
		return out
	var target: Dictionary = {}
	var purchased_ids: Array = []
	for i: int in range(cfg.upgrade_count()):
		var u := cfg.get_upgrade(i)
		if u == null or not cfg.is_upgrade_valid(u):
			continue
		if u.id == upgrade_id:
			target = cfg.make_upgrade(u.id, u.display_name, u.cost, u.effect_key, u.effect_value)
		if bool(state.call("get_flag", GraceUpgradeService.purchased_flag_key(u.id), false)):
			purchased_ids.append(u.id)
	if target.is_empty():
		out["reason"] = "未知/非法 upgrade id → 购买被拒绝"
		return out
	var points: int = int(state.call("get_flag", GraceUpgradeService.FLAG_POINTS, 0))
	var spent: int = int(state.call("get_flag", GraceUpgradeService.FLAG_SPENT_POINTS, 0))
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	svc.load_state(spent, purchased_ids)
	var r: Dictionary = svc.purchase(points, spent, target)
	var ok: bool = bool(r.get("ok", false))
	out["ok"] = ok
	out["reason"] = str(r.get("reason", ""))
	out["points"] = points
	out["spent_points"] = int(r.get("spent_points", spent))
	out["balance"] = int(r.get("balance", 0))
	if not ok:
		return out
	state.call("set_flag", GraceUpgradeService.FLAG_SPENT_POINTS, out["spent_points"])
	state.call("set_flag", GraceUpgradeService.purchased_flag_key(upgrade_id), true)
	var w: Node = writer if writer != null else _get_delta_writer()
	if w != null and w.has_method("commit"):
		w.call("commit", COMMIT_REASON)
		out["committed"] = true
	else:
		out["commit_downgrade_reason"] = "SaveDeltaWriter 未就绪 → flag 仅进程内内存、未落盘（不崩）"
	return out
