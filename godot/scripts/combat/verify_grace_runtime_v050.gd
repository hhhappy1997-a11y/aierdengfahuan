extends SceneTree

## ===========================================================================
## R27B / v0.5.0 · 赐福成长「真机挂载 + 购买入口 + 运行时数值 + 存档不变量」自测
## （Rank-1，cmd-20261111-091349-628-A1，[ROUND=R27B]）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_grace_runtime_v050.gd
##
## 断言 7 类（任务单 ⑤）：
##   M 挂载生效（courtyard.tscn 真节点 / 脚本 / 导演接线 / 购买 HUD Label）
##   V 三项数值复验（100→120 HP / 13→14 iframe / 85→90 attack，经 Rank-2 apply_purchased）
##   P 购买幂等（can_purchase/purchase / 重复购买 / 余额不足 / 异常输入 / 先落盘再改运行时）
##   B 余额非负     S spent 单调     U unlocked 单向     D 依赖缺失降级
##
## 口径：
##   - 裁决 A23：grace.upgrade_<id>.unlocked 三段式收敛有效（四段字面废止），
##     不改 world_state.gd 正则；购买同时兼容写 Rank-2 读取口径 grace.trial.bought_<id>。
##   - 裁决 A24：增益运行时由 Rank-1 装配层挂载到 courtyard.tscn 的 WaveTrialDirector 下，
##     经 wave_trial_director._apply_grace_runtime() 在 _ready 后调用既有公开 apply_purchased()。
##   - --script 模式纪律：不用 /root/... 绝对路径（用 Engine.get_main_loop() /
##     root.get_node_or_null() 相对探活）；add_child 不 flush _ready → 显式 call("_ready")；
##     注入（bind_grace_deps / bind_world_state）一律在 _ready 之后。
##   - 存档：全程用「内存 WorldState 实例 + FakeWriter」验证真实 I-1 set_flag / commit
##     编排时序，不写 user://saves/slot_01/delta.json（不污染回归基线、不伪造产物）。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。
## ===========================================================================

const COURTYARD_SCENE: String = "res://scenes/courtyard.tscn"
const HUD_SCENE: String = "res://scenes/hud.tscn"
const RUNTIME_SCRIPT_PATH: String = "res://scripts/combat/grace_upgrade_runtime.gd"
const WAVE_SCRIPT_PATH: String = "res://scripts/combat/wave_trial_director.gd"
const ENCOUNTER_SCRIPT_PATH: String = "res://scripts/combat/encounter_director.gd"
const WORLD_STATE_SCRIPT_PATH: String = "res://scripts/rpg/world_state.gd"
const HUD_SCRIPT_PATH: String = "res://scripts/hud.gd"
const PLAYER_TABLE_PATH: String = "res://data/combat/player_actions.tres"
const CONFIG_PATH: String = "res://data/rpg/grace_upgrades.tres"

const FLAG_POINTS: String = "grace.trial.points"
const FLAG_SPENT: String = "grace.trial.spent_points"
const COMMIT_REASON: String = "grace_upgrade_purchased"
const FLAG_UNLOCKED_PREFIX: String = "grace.upgrade_"
const FLAG_UNLOCKED_SUFFIX: String = ".unlocked"
const TEN_FIELDS: Array[String] = [
	"schema_version", "slot", "seq", "baseline", "flags",
	"quests", "inventory", "spawns", "removals", "meta",
]
const EXPECT_IDS: Array[String] = ["hp_max_bonus", "roll_iframe_bonus", "attack_power_bonus"]
const EXPECT_NAMES: Array[String] = ["赐福·生命上限", "赐福·翻滚余韵", "赐福·攻击强化"]
const EXPECT_COSTS: Array[int] = [100, 200, 300]

var _pass: int = 0
var _fail: int = 0
## 手动 new()/instantiate() 的 Node 统一登记，_finish() 退出前 free，避免 ObjectDB 泄漏告警。
var _temps: Array[Node] = []


## 只记录 commit(reason) 的替身：验证「先落盘再改运行时实例」编排而不写 user:// 盘。
class FakeWriter extends Node:
	var commits: Array[String] = []

	func commit(reason: String) -> void:
		commits.append(reason)


func _track(n: Node) -> void:
	_temps.append(n)


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[GRV050] %s PASS=%s | %s" % [tag, str(ok), detail])


func _new_mem_ws() -> Node:
	var ws: Node = Node.new()
	ws.set_script(load(WORLD_STATE_SCRIPT_PATH) as Script)
	_track(ws)
	ws.call("_ready")
	return ws


func _find_action(table: Resource, pose: String) -> PlayerActionData:
	var raw: Variant = table.get("actions")
	if typeof(raw) != TYPE_ARRAY:
		return null
	for a: Variant in (raw as Array):
		var action: PlayerActionData = a as PlayerActionData
		if action != null and action.pose_name == pose:
			return action
	return null


## 装配一个 hud.tscn 实例：先加 GraceShopLabel（运行时 UI，不改 hud.tscn 文件），
## 再 add_child + 显式 call("_ready")，最后在 _ready 之后注入依赖（踩坑口径）。
func _new_hud(ws: Node, writer: Node, runtime: Node, encounter: Node) -> Node:
	var packed: PackedScene = load(HUD_SCENE) as PackedScene
	var hud: Node = packed.instantiate()
	_track(hud)
	hud.name = "R27BTestHud"
	var lbl: Label = Label.new()
	lbl.name = "GraceShopLabel"
	hud.add_child(lbl)
	root.add_child(hud)
	if not hud.is_node_ready():
		hud.call("_ready")
	hud.call("bind_grace_deps", ws, writer, runtime, encounter)
	return hud


func _initialize() -> void:
	print("[GRV050] ==== verify_grace_runtime_v050 真跑开始 | cmd-20261111-091349-628-A1 [ROUND=R27B] Rank-1 ====")
	_test_mount()
	_test_three_values()
	_test_purchase_flow()
	_test_balance_nonneg()
	_test_spent_monotonic()
	_test_unlocked_oneway()
	_test_degrade()
	_test_input_routing()
	_finish()


# ---------------------------------------------------------------------------
# M) 挂载生效：courtyard.tscn 真节点 / 脚本 / 导演接线 / 购买 HUD Label
# ---------------------------------------------------------------------------
func _test_mount() -> void:
	var packed: PackedScene = load(COURTYARD_SCENE) as PackedScene
	_ck("M1 courtyard.tscn 可加载为 PackedScene", packed != null, "path=%s" % COURTYARD_SCENE)
	if packed == null:
		return
	var inst: Node = packed.instantiate()
	_track(inst)
	var rt: Node = inst.find_child("GraceUpgradeRuntime", true, false)
	_ck("M2 挂载节点 GraceUpgradeRuntime 存在（instantiate 回读）", rt != null,
		"found=%s" % str(rt != null))
	if rt != null:
		var scr: Script = rt.get_script() as Script
		var scr_path: String = scr.resource_path if scr != null else "<null>"
		_ck("M3 挂载脚本 == grace_upgrade_runtime.gd", scr_path == RUNTIME_SCRIPT_PATH,
			"script=%s" % scr_path)
		var parent: Node = rt.get_parent()
		_ck("M4 挂载父节点为 WaveTrialDirector（裁决 A24 装配层）",
			parent != null and String(parent.name) == "WaveTrialDirector",
			"parent=%s" % (String(parent.name) if parent != null else "<null>"))
	var shop: Node = inst.find_child("GraceShopLabel", true, false)
	_ck("M5 购买 HUD GraceShopLabel 存在（三项名称/cost/解锁/余额载体）", shop != null,
		"found=%s" % str(shop != null))
	var wave_script: Script = load(WAVE_SCRIPT_PATH) as Script
	var wave_probe: Node = Node.new()
	_track(wave_probe)
	wave_probe.set_script(wave_script)
	_ck("M6 波次导演具备 _apply_grace_runtime() 接线方法",
		wave_probe.has_method("_apply_grace_runtime"),
		"_ready 后经既有公开 apply_purchased() 作用到运行时")
	var hud_script: Script = load(HUD_SCRIPT_PATH) as Script
	# hud.gd extends CanvasLayer：探针必须是 CanvasLayer，不能是裸 Node（native type 校验）。
	var hud_probe: CanvasLayer = CanvasLayer.new()
	_track(hud_probe)
	hud_probe.set_script(hud_script)
	_ck("M7 HUD 具备购买入口 purchase_upgrade() / get_shop_view()",
		hud_probe.has_method("purchase_upgrade") and hud_probe.has_method("get_shop_view"),
		"数字键 1/2/3 → 幂等购买编排 + HUD 只读视图")


# ---------------------------------------------------------------------------
# V) 三项数值复验：100→120 HP / 13→14 iframe / 85→90 attack
#    经 Rank-2 既有公开方法 apply_purchased(encounter, ws)，零新增数值口径。
# ---------------------------------------------------------------------------
func _test_three_values() -> void:
	var table: Resource = load(PLAYER_TABLE_PATH) as Resource
	var roll: PlayerActionData = _find_action(table, "roll")
	var light: PlayerActionData = _find_action(table, "attack_light")
	_ck("V1 apply 前 roll.invulnerable_end_frame=13",
		roll != null and roll.invulnerable_end_frame == 13,
		"got=%d" % (roll.invulnerable_end_frame if roll != null else -1))
	_ck("V2 apply 前 attack_light.base_attack=85",
		light != null and light.base_attack == 85.0,
		"got=%s" % (str(light.base_attack) if light != null else "null"))
	# 真实 EncounterDirector 脚本实例（不 _ready：_state=null 时既有 _grace_rest 直接 return，
	# 避免触发 Boss 重建 / 落盘；@export player_max_hp 仍可读可写）。
	var enc: Node = Node.new()
	_track(enc)
	enc.set_script(load(ENCOUNTER_SCRIPT_PATH) as Script)
	_ck("V3 apply 前 @export player_max_hp=100", float(enc.get("player_max_hp")) == 100.0,
		"got=%s" % str(enc.get("player_max_hp")))
	# 三项已购的内存 flag 状态（Rank-2 运行时读取口径 grace.trial.bought_<id>）。
	var ws: Node = _new_mem_ws()
	ws.call("set_flag", FLAG_POINTS, 1000)
	for id: String in EXPECT_IDS:
		ws.call("set_flag", GraceUpgradeService.purchased_flag_key(id), true)
	var rt: GraceUpgradeRuntime = GraceUpgradeRuntime.new()
	_track(rt)
	var report: Dictionary = rt.call("apply_purchased", enc, ws)
	_ck("V4 apply_purchased applied=3 / degraded=0",
		int(report.get("applied", 0)) == 3 and int(report.get("degraded", 0)) == 0,
		"checked=%s applied=%s degraded=%s" % [
			str(report.get("checked", 0)), str(report.get("applied", 0)), str(report.get("degraded", 0))])
	_ck("V5 HP 上限 100 → 120（@export player_max_hp）",
		float(enc.get("player_max_hp")) == 120.0,
		"after=%s" % str(enc.get("player_max_hp")))
	_ck("V6 翻滚无敌窗口 13 → 14（invulnerable_end_frame）",
		roll != null and roll.invulnerable_end_frame == 14,
		"after=%d" % (roll.invulnerable_end_frame if roll != null else -1))
	_ck("V7 攻击力 85 → 90（base_attack）",
		light != null and light.base_attack == 90.0,
		"after=%s" % (str(light.base_attack) if light != null else "null"))
	var heavy: PlayerActionData = _find_action(table, "attack_heavy")
	_ck("V8 attack_heavy 同步 85 → 90", heavy != null and heavy.base_attack == 90.0,
		"after=%s" % (str(heavy.base_attack) if heavy != null else "null"))
	# 同进程重复 apply 不得重复叠加（_applied_ids 幂等）。
	var report2: Dictionary = rt.call("apply_purchased", enc, ws)
	_ck("V9 同进程重复 apply 不重复叠加",
		float(enc.get("player_max_hp")) == 120.0 \
			and roll != null and roll.invulnerable_end_frame == 14 \
			and light != null and light.base_attack == 90.0,
		"report2.applied=%s" % str(report2.get("applied", 0)))


# ---------------------------------------------------------------------------
# P) 购买入口：HUD 显示 / 幂等 / 余额不足 / 异常输入 / 先落盘再改运行时实例
# ---------------------------------------------------------------------------
func _test_purchase_flow() -> void:
	var ws: Node = _new_mem_ws()
	ws.call("set_flag", FLAG_POINTS, 1000)
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var rt: GraceUpgradeRuntime = GraceUpgradeRuntime.new()
	_track(rt)
	var enc: Node = Node.new()
	_track(enc)
	enc.set_script(load(ENCOUNTER_SCRIPT_PATH) as Script)
	var hud: Node = _new_hud(ws, fw, rt, enc)
	hud.call("_toggle_shop")
	var view: Dictionary = hud.call("get_shop_view") as Dictionary
	var items: Array = view.get("items", []) as Array
	_ck("P1 HUD 显示三项（名称 / cost / 是否已解锁 / 当前余额）",
		items.size() == 3 and int(view.get("balance", -1)) == 1000 \
			and bool(view.get("open", false)),
		"items=%d balance=%s open=%s" % [items.size(), str(view.get("balance", -1)), str(view.get("open", false))])
	var all_locked: bool = true
	for i: int in range(items.size()):
		var row: Dictionary = items[i] as Dictionary
		if bool(row.get("unlocked", true)):
			all_locked = false
	_ck("P2 三项初始均未解锁（false）", all_locked, "items=%s" % str(items))
	var lbl: Label = hud.get_node_or_null("GraceShopLabel") as Label
	var hud_text: String = lbl.text if lbl != null else ""
	_ck("P3 GraceShopLabel 文本含三项名称 / cost / 余额",
		hud_text.contains(EXPECT_NAMES[0]) and hud_text.contains(EXPECT_NAMES[2]) \
			and hud_text.contains("1000") and hud_text.contains("300"),
		"text=%s" % hud_text.replace("\n", " / "))

	var r0: Dictionary = hud.call("purchase_upgrade", 0) as Dictionary
	_ck("P4 数字键 1 购买成功且已 commit",
		bool(r0.get("ok", false)) and bool(r0.get("committed", false)),
		"reason=%s committed=%s" % [str(r0.get("reason", "")), str(r0.get("committed", false))])
	_ck("P5 spent_points 0 → 100", int(ws.call("get_flag", FLAG_SPENT, -1)) == 100,
		"spent=%s" % str(ws.call("get_flag", FLAG_SPENT, -1)))
	_ck("P6 unlocked false → true（三段式收敛 key）",
		bool(ws.call("get_flag", FLAG_UNLOCKED_PREFIX + EXPECT_IDS[0] + FLAG_UNLOCKED_SUFFIX, false)),
		"key=%s" % (FLAG_UNLOCKED_PREFIX + EXPECT_IDS[0] + FLAG_UNLOCKED_SUFFIX))
	_ck("P7 兼容 Rank-2 读取口径 grace.trial.bought_<id> 同写",
		bool(ws.call("get_flag", GraceUpgradeService.purchased_flag_key(EXPECT_IDS[0]), false)),
		"同一 commit 原子落盘，使挂载运行时可读已购项")
	_ck("P8 commit(reason) == grace_upgrade_purchased",
		fw.commits.size() == 1 and fw.commits[0] == COMMIT_REASON,
		"commits=%s" % str(fw.commits))
	_ck("P9 绝不回退 grace.trial.points（恒 1000）",
		int(ws.call("get_flag", FLAG_POINTS, -1)) == 1000,
		"points=%s" % str(ws.call("get_flag", FLAG_POINTS, -1)))

	# 重复购买（幂等）
	var rd: Dictionary = hud.call("purchase_upgrade", 0) as Dictionary
	_ck("P10 重复购买同一 id 被拒绝（幂等）", not bool(rd.get("ok", true)),
		"reason=%s" % str(rd.get("reason", "")))
	_ck("P11 重复购买 spent 不二次累加（仍 100）",
		int(ws.call("get_flag", FLAG_SPENT, -1)) == 100,
		"spent=%s" % str(ws.call("get_flag", FLAG_SPENT, -1)))
	var dup_msg: String = String((hud.call("get_shop_view") as Dictionary).get("message", ""))
	_ck("P12 重复购买 HUD 给出可读提示（含「已解锁」）",
		dup_msg.contains("已解锁"), "message=%s" % dup_msg)

	# 依次购买 2 / 3
	var r1: Dictionary = hud.call("purchase_upgrade", 1) as Dictionary
	var r2: Dictionary = hud.call("purchase_upgrade", 2) as Dictionary
	_ck("P13 数字键 2 / 3 均购买成功",
		bool(r1.get("ok", false)) and bool(r2.get("ok", false)),
		"r1=%s r2=%s" % [str(r1.get("reason", "")), str(r2.get("reason", ""))])
	_ck("P14 spent_points 单调递增到 600（100+200+300）",
		int(ws.call("get_flag", FLAG_SPENT, -1)) == 600,
		"spent=%s" % str(ws.call("get_flag", FLAG_SPENT, -1)))
	_ck("P15 commit 调用 3 次、reason 均为 grace_upgrade_purchased",
		fw.commits.size() == 3 and fw.commits[0] == COMMIT_REASON \
			and fw.commits[1] == COMMIT_REASON and fw.commits[2] == COMMIT_REASON,
		"commits=%s" % str(fw.commits))
	# 「先落盘再改运行时实例」：每组 stage_flags → disk_write → runtime_update
	var events: Array = hud.get("grace_purchase_events") as Array
	var order_ok: bool = events.size() == 9
	if events.size() == 9:
		for i: int in range(0, 9, 3):
			if not (String(events[i]).begins_with("stage_flags") \
					and String(events[i + 1]).begins_with("disk_write:") \
					and String(events[i + 2]).begins_with("runtime_update")):
				order_ok = false
	_ck("P16 先落盘再改运行时实例（3 组 stage_flags→disk_write→runtime_update）",
		order_ok, "events=%s" % str(events))
	# 绝不 removals / 十字段不受破坏
	var delta_v: Variant = ws.get("_delta")
	var removals: Array = []
	var top: Array = []
	if typeof(delta_v) == TYPE_DICTIONARY:
		removals = (delta_v as Dictionary).get("removals", []) as Array
		top = (delta_v as Dictionary).keys()
	_ck("P17 绝不 removals（removals 为空）", removals.is_empty(),
		"removals=%s" % str(removals))
	var top_ok: bool = top.size() == TEN_FIELDS.size()
	for k: String in TEN_FIELDS:
		if not top.has(k):
			top_ok = false
	_ck("P18 购买不改 SaveDelta 十字段顶层结构", top_ok, "top=%s" % str(top))

	# 余额不足：新内存 ws，points=50 < cost=100
	var poor_ws: Node = _new_mem_ws()
	poor_ws.call("set_flag", FLAG_POINTS, 50)
	var fw2: FakeWriter = FakeWriter.new()
	_track(fw2)
	var hud2: Node = _new_hud(poor_ws, fw2, null, null)
	hud2.call("_toggle_shop")
	var rp: Dictionary = hud2.call("purchase_upgrade", 0) as Dictionary
	_ck("P19 余额不足被拒绝（can_purchase 门控）", not bool(rp.get("ok", true)),
		"reason=%s balance=%s" % [str(rp.get("reason", "")), str(rp.get("balance", -1))])
	_ck("P20 余额不足 spent 不变（未扣点 / 无 commit）",
		int(poor_ws.call("get_flag", FLAG_SPENT, 0)) == 0 and fw2.commits.is_empty(),
		"spent=%s commits=%s" % [str(poor_ws.call("get_flag", FLAG_SPENT, 0)), str(fw2.commits)])
	var poor_msg: String = String((hud2.call("get_shop_view") as Dictionary).get("message", ""))
	_ck("P21 余额不足 HUD 给出可读提示（含「点数不足」）",
		poor_msg.contains("点数不足"), "message=%s" % poor_msg)

	# 异常输入：越界 index
	var fw3: FakeWriter = FakeWriter.new()
	_track(fw3)
	var hud3: Node = _new_hud(_new_mem_ws(), fw3, null, null)
	var rneg: Dictionary = hud3.call("purchase_upgrade", -1) as Dictionary
	var rbig: Dictionary = hud3.call("purchase_upgrade", 99) as Dictionary
	_ck("P22 异常输入 index=-1 / 99 均被拒绝",
		not bool(rneg.get("ok", true)) and not bool(rbig.get("ok", true)),
		"rneg=%s rbig=%s" % [str(rneg.get("reason", "")), str(rbig.get("reason", ""))])
	var bad_msg: String = String((hud3.call("get_shop_view") as Dictionary).get("message", ""))
	_ck("P23 异常输入 HUD 给出可读提示（含「无效选项」）",
		bad_msg.contains("无效选项"), "message=%s" % bad_msg)


# ---------------------------------------------------------------------------
# B) 余额非负：points − spent_points ≥ 0，每次成功购买后余额均非负
# ---------------------------------------------------------------------------
func _test_balance_nonneg() -> void:
	var ws: Node = _new_mem_ws()
	ws.call("set_flag", FLAG_POINTS, 1000)
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var hud: Node = _new_hud(ws, fw, null, null)
	var nonneg: bool = true
	var series: Array[int] = []
	for i: int in range(3):
		var r: Dictionary = hud.call("purchase_upgrade", i) as Dictionary
		var bal: int = int(r.get("balance", -1))
		series.append(bal)
		if bal < 0:
			nonneg = false
	_ck("B1 每次成功购买后余额非负", nonneg, "balances=%s" % str(series))
	_ck("B2 余额 = points − spent_points = 1000 − 600 = 400",
		series == [900, 700, 400] and int(ws.call("get_flag", FLAG_SPENT, -1)) == 600,
		"balances=%s spent=%s" % [str(series), str(ws.call("get_flag", FLAG_SPENT, -1))])
	var view: Dictionary = hud.call("get_shop_view") as Dictionary
	_ck("B3 HUD 视图余额非负（maxi(0, ·) 防脏值）", int(view.get("balance", -1)) >= 0,
		"balance=%s" % str(view.get("balance", -1)))


# ---------------------------------------------------------------------------
# S) spent_points 单调递增：外部传入落后值不回退累计（纯逻辑服务层）
# ---------------------------------------------------------------------------
func _test_spent_monotonic() -> void:
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	svc.load_state(500, [])
	var row: Dictionary = {
		"id": EXPECT_IDS[0], "display_name": EXPECT_NAMES[0], "cost": 100,
		"effect_key": "hp_max", "effect_value": 20.0,
	}
	var r: Dictionary = svc.purchase(1000, 0, row)
	_ck("S1 spent 单调递增：max(内部 500, 外部 0) + 100 = 600",
		int(r.get("spent_points", -1)) == 600 and svc.get_spent_points() == 600,
		"spent=%s getter=%s" % [str(r.get("spent_points", -1)), str(svc.get_spent_points())])
	_ck("S2 purchase 返回的 points 恒为原值（绝不回退）",
		int(r.get("points", -1)) == 1000, "points=%s" % str(r.get("points", -1)))
	_ck("S3 余额 = balance(1000, 600) = 400",
		GraceUpgradeService.balance(1000, 600) == 400, "balance(1000,600)=400")


# ---------------------------------------------------------------------------
# U) unlocked 单向：false→true，无 false 回写；重复购买 / 失败均不翻转
# ---------------------------------------------------------------------------
func _test_unlocked_oneway() -> void:
	var ws: Node = _new_mem_ws()
	ws.call("set_flag", FLAG_POINTS, 1000)
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var hud: Node = _new_hud(ws, fw, null, null)
	for i: int in range(3):
		hud.call("purchase_upgrade", i)
	var all_true: bool = true
	for id: String in EXPECT_IDS:
		if not bool(ws.call("get_flag", FLAG_UNLOCKED_PREFIX + id + FLAG_UNLOCKED_SUFFIX, false)):
			all_true = false
	_ck("U1 三项 unlocked 均 false→true（单向置位）", all_true,
		"ids=%s" % str(EXPECT_IDS))
	# 重复购买（失败路径）不得把 true 翻回 false，也不产生新 commit
	var before_commits: int = fw.commits.size()
	var rd: Dictionary = hud.call("purchase_upgrade", 0) as Dictionary
	var still_true: bool = bool(ws.call("get_flag",
			FLAG_UNLOCKED_PREFIX + EXPECT_IDS[0] + FLAG_UNLOCKED_SUFFIX, false))
	_ck("U2 重复购买被拒且 unlocked 不翻转、不产生新 commit",
		not bool(rd.get("ok", true)) and still_true and fw.commits.size() == before_commits,
		"ok=%s still_true=%s commits=%d→%d" % [
			str(rd.get("ok", true)), str(still_true), before_commits, fw.commits.size()])
	var flags_v: Variant = ws.get("_flags")
	var no_false_write: bool = true
	if typeof(flags_v) == TYPE_DICTIONARY:
		for k: Variant in (flags_v as Dictionary).keys():
			if String(k).begins_with(FLAG_UNLOCKED_PREFIX) \
					and not bool((flags_v as Dictionary)[k]):
				no_false_write = false
	_ck("U3 内存 flags 中不存在 false 的 unlocked 回写", no_false_write,
		"flags=%s" % str((flags_v as Dictionary).keys() if typeof(flags_v) == TYPE_DICTIONARY else []))


# ---------------------------------------------------------------------------
# D) 依赖缺失降级：WorldState 无接口 / encounter=null / writer 未就绪 → 不崩、如实登记
# ---------------------------------------------------------------------------
func _test_degrade() -> void:
	# ① apply_purchased 的 WorldState 不可用降级
	var rt: GraceUpgradeRuntime = GraceUpgradeRuntime.new()
	_track(rt)
	var fake_ws: Node = Node.new()   # 无 get_flag / set_flag 接口
	_track(fake_ws)
	var rep: Dictionary = rt.call("apply_purchased", null, fake_ws)
	_ck("D1 apply_purchased WorldState 不可用 → 降级、不崩",
		int(rep.get("degraded", 0)) >= 1 and (rep.get("reasons", []) as Array).size() >= 1,
		"degraded=%s reasons=%s" % [str(rep.get("degraded", 0)), str(rep.get("reasons", []))])
	# ② try_purchase 的 WorldState 不可用降级
	var rp: Dictionary = rt.call("try_purchase", EXPECT_IDS[0], fake_ws, null)
	_ck("D2 try_purchase WorldState 不可用 → 购买未落盘、不崩",
		not bool(rp.get("ok", true)) and String(rp.get("reason", "")).contains("WorldState"),
		"reason=%s" % str(rp.get("reason", "")))
	# ③ apply_purchased 的 EncounterDirector 未注入降级（hp_max 如实登记「数据已落、效果待接」）
	var ws: Node = _new_mem_ws()
	ws.call("set_flag", GraceUpgradeService.purchased_flag_key(EXPECT_IDS[0]), true)
	var rt2: GraceUpgradeRuntime = GraceUpgradeRuntime.new()
	_track(rt2)
	var rep2: Dictionary = rt2.call("apply_purchased", null, ws)
	var items: Array = rep2.get("items", []) as Array
	var hp_degraded: bool = false
	var honest_reason: bool = false
	for it: Variant in items:
		var row: Dictionary = it as Dictionary
		if str(row.get("effect_key", "")) == "hp_max":
			hp_degraded = str(row.get("status", "")) == "degraded"
			honest_reason = str(row.get("reason", "")).contains("数据已落、效果待接")
	_ck("D3 encounter=null → hp_max 如实降级「数据已落、效果待接」",
		hp_degraded and honest_reason, "items=%s" % str(items))
	# ④ HUD 购买入口在 WorldState 无接口时降级、不崩
	var fw4: FakeWriter = FakeWriter.new()
	_track(fw4)
	var hud: Node = _new_hud(fake_ws, fw4, null, null)
	var rh: Dictionary = hud.call("purchase_upgrade", 0) as Dictionary
	var msg: String = String((hud.call("get_shop_view") as Dictionary).get("message", ""))
	_ck("D4 HUD 购买在依赖缺失时降级、不崩且给出可读提示",
		not bool(rh.get("ok", true)) and msg.contains("WorldState"),
		"reason=%s message=%s" % [str(rh.get("reason", "")), msg])


# ---------------------------------------------------------------------------
# I) 输入路由：赐福休息 / E 键 interact 打开面板，数字键 1 / 2 / 3 购买
#    （构造真实 InputEvent 传给 hud._unhandled_input，不改 project.godot [input]）
# ---------------------------------------------------------------------------
func _test_input_routing() -> void:
	var ws: Node = _new_mem_ws()
	ws.call("set_flag", FLAG_POINTS, 1000)
	var fw: FakeWriter = FakeWriter.new()
	_track(fw)
	var hud: Node = _new_hud(ws, fw, null, null)
	# E 键 interact（赐福休息）→ 打开赐福成长兑换面板
	var ev_e: InputEventAction = InputEventAction.new()
	ev_e.action = "interact"
	ev_e.pressed = true
	hud.call("_unhandled_input", ev_e)
	_ck("I1 E 键 interact 打开赐福成长兑换面板", bool(hud.get("shop_open")),
		"shop_open=%s" % str(hud.get("shop_open")))
	var view: Dictionary = hud.call("get_shop_view") as Dictionary
	_ck("I2 面板打开时 HUD 显示三项 + 当前余额",
		(view.get("items", []) as Array).size() == 3 and int(view.get("balance", -1)) == 1000,
		"items=%d balance=%s" % [(view.get("items", []) as Array).size(), str(view.get("balance", -1))])
	# 数字键 1 / 2 / 3 依次购买
	var spent_expect: Array[int] = [100, 300, 600]
	var keys: Array[int] = [KEY_1, KEY_2, KEY_3]
	for i: int in range(3):
		var k: InputEventKey = InputEventKey.new()
		k.physical_keycode = keys[i]
		k.keycode = keys[i]
		k.pressed = true
		hud.call("_unhandled_input", k)
		_ck("I%d 数字键 %d 触发购买（spent=%d）" % [3 + i, i + 1, spent_expect[i]],
			int(ws.call("get_flag", FLAG_SPENT, 0)) == spent_expect[i] \
				and fw.commits.size() == i + 1,
			"spent=%s commits=%d" % [
				str(ws.call("get_flag", FLAG_SPENT, 0)), fw.commits.size()])
	# 再按 E 关闭面板
	var ev_e2: InputEventAction = InputEventAction.new()
	ev_e2.action = "interact"
	ev_e2.pressed = true
	hud.call("_unhandled_input", ev_e2)
	_ck("I6 再按 E 关闭兑换面板", not bool(hud.get("shop_open")),
		"shop_open=%s" % str(hud.get("shop_open")))


func _finish() -> void:
	for n: Node in _temps:
		if is_instance_valid(n):
			n.free()
	_temps.clear()
	var ok: bool = _fail == 0 and _pass > 0
	print("[GRV050] ---- 回读汇总 ----")
	print("[GRV050] SUMMARY pid=%d pass=%d fail=%d ok=%s" % [
		OS.get_process_id(), _pass, _fail, str(ok)])
	print("[GRV050] RESULT=%s" % ("ALL_PASS" if ok else "HAS_FAIL"))
	print("[GRV050] ==== verify_grace_runtime_v050 真跑结束 ====")
	quit(0 if ok else 1)
