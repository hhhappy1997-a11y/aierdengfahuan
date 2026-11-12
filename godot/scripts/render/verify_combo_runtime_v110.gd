extends SceneTree
## ===========================================================================
## R34B [ROUND=R34B] · 连击评价「真实可达」全链回归（Rank-1）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/render/verify_combo_runtime_v110.gd
##
## A49 / A48 口径：在【不加载 presentation.gd】的独立进程里自行 instantiate 主场景，
##   由真实输入 / 真实信号 / 真实服务断言全链连通：
##     真实命中 → combo 增长 → 评级变化 → 清波点数按倍率结算 → 受击重置 → Boss 死亡结算。
##   A54：ComboService / BoonDraftService 唯一实例归属 wave_trial_director.gd，
##   enc / hud / wave 三方 getter 返回同一实例（机器判定，绝不另建第二实例）。
##   任务2：抉择 cost_key/effect_key 作用到波次开始时运行时敌人参数并验证失败降级。
##   点数只发信号 / 不写存档（A50）：全程 bind_persistence(null,null) 显式降级。
##
## --script / SceneTree 纪律：add_child 不 flush _ready() → 显式 call("_ready")；
##   call_deferred 不 flush → 显式 call("_r34_bootstrap")；
##   用 Engine.get_main_loop() as SceneTree 取 root，不用 get_tree() / 不用 /root/...；
##   资源回读 CACHE_MODE_IGNORE；信号 connect 前 get_signal_connection_list 去重、
##   验证结束显式 disconnect 释放路径。
## 输出：逐条 PASS/FAIL + SUMMARY + RESULT=ALL_MATCH（全通过）/ MISMATCH。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。
## ===========================================================================

const COURTYARD_PATH: String = "res://scenes/courtyard.tscn"
const REL_HUD: String = "SubViewportContainer/SubViewport/FXLayer/Hud"
const REL_ENC: String = "EncounterRoot"
const REL_WAVE: String = "WaveTrialDirector"
const KEY_2: int = 50          # 数字键 2（赐福抉择第 2 项 boon_02_poise_edge）

# ---- A57 [ROUND=R34D] 生产落盘订阅者（Rank-3 autoload，只读复用，不重复挂载）----
const PCO_AUTOLOAD_NAME: String = "PointsCommitOrchestrator"
const PCO_PATH: String = "res://scripts/rpg/points_commit_orchestrator.gd"
const PRODUCTION_DELTA: String = "user://saves/slot_01/delta.json"
const A57_SLOT_BASE: String = "user://saves/verify_r34d_combo"
const K_POINTS: String = "grace.trial.points"

var _pass: int = 0
var _fail: int = 0
var _tree: SceneTree = null
var _courtyard: Node = null
var _hud: Node = null
var _enc: Node = null
var _wave: Node = null
var _combo: Object = null

# 4 信号探针 + wave_cleared 口径探针（connect 后统计，不改游戏状态）
var _combo_changed_count: int = 0
var _rank_changed_count: int = 0
var _combo_reset_reasons: Array[String] = []
var _combo_settled_logs: Array[Dictionary] = []
var _wave_cleared_pts: Array[int] = []
var _probes_connected: bool = false

# A57 全链组（独立 PID 临时槽 + 生产编排层引用 + HUD points_awarded 探针）
var _a57_orch: Node = null
var _a57_slot_dir: String = ""
var _a57_delta_path: String = ""
var _a57_prod_md5_before: String = ""
var _a57_points_trace: Array[int] = []
var _a57_pa_log: Array[Dictionary] = []


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V110-CBR] %s PASS=%s | %s" % [tag, str(ok), detail])


func _key(code: int, pressed: bool) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	e.echo = false
	return e


func _dedup_connect(obj: Object, sig: String, method: String) -> bool:
	if obj == null or not obj.has_signal(sig):
		return false
	var cb: Callable = Callable(self, method)
	for conn in obj.get_signal_connection_list(sig):
		var c: Callable = conn.get("callable", Callable())
		if c.get_object() == self and String(c.get_method()) == method:
			return false
	obj.connect(sig, cb)
	return true


func _initialize() -> void:
	print("[V110-CBR] ==== verify_combo_runtime_v110 真跑开始 | R34B v0.11.0 Rank-1 ====")
	print("[V110-CBR] A49：本进程不加载 presentation.gd；自行 instantiate 主场景 + 显式 _ready()/bootstrap()")
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null:
		print("[V110-CBR] RESULT=MISMATCH（Engine.get_main_loop() 非 SceneTree）")
		quit(1)
		return
	_load_main_scene()
	if _courtyard == null:
		_finish(true)
		return
	_resolve_nodes()
	if _hud == null or _enc == null or _wave == null:
		_finish(true)
		return
	_explicit_ready()
	_explicit_bootstrap()
	# 关闭 Boss AI：--script 的 _initialize 阶段引擎未 flush Boss._ready、_hp 默认 0，
	# get_hp_ratio()<=0 会误判 _finish(true) 令 _step 首拍后 early return（同既有 v110 口径）。
	_enc.set("simulate_boss", false)
	# 点数只发信号 / 不写存档（A50）：显式 bind_persistence(null,null) 降级。
	if _wave.has_method("bind_persistence"):
		_wave.call("bind_persistence", null, null)
	_a57_bind_orchestrator()
	_t_a54_unique()
	_bind_combo_probes()
	_t_real_hit_rank()
	_t_clear_wave_settle()
	_a57_assert_full_chain()
	_t_hit_taken_reset()
	_t_enemy_params()
	_t_boss_defeated_settle()
	_t_hud_visible()
	_t_static_wiring()
	_finish(false)


func _load_main_scene() -> void:
	var packed: PackedScene = ResourceLoader.load(
			COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		print("[V110-CBR] 主场景加载失败：%s" % COURTYARD_PATH)
		return
	_courtyard = packed.instantiate()
	if _courtyard == null:
		print("[V110-CBR] 主场景 instantiate 失败")
		return
	_tree.root.add_child(_courtyard)
	print("[V110-CBR] 主场景已实例化入树 | name=%s is_inside_tree=%s（未加载 presentation.gd）" % [
			str(_courtyard.name), str(_courtyard.is_inside_tree())])


func _resolve_nodes() -> void:
	_hud = _courtyard.get_node_or_null(NodePath(REL_HUD))
	_enc = _courtyard.get_node_or_null(NodePath(REL_ENC))
	_wave = _courtyard.get_node_or_null(NodePath(REL_WAVE))
	_ck("a0 主场景关键节点可寻址（EncounterRoot / Hud / WaveTrialDirector）",
			_hud != null and _enc != null and _wave != null,
			"enc=%s hud=%s wave=%s" % [str(_enc != null), str(_hud != null), str(_wave != null)])


func _explicit_ready() -> void:
	for n: Node in [_enc, _hud, _wave]:
		if n != null and not n.is_node_ready() and n.has_method("_ready"):
			n.call("_ready")
	print("[V110-CBR] 显式 _ready() 完成（EncounterDirector / HUD / WaveTrialDirector）")


func _explicit_bootstrap() -> void:
	if _enc.has_method("_r34_bootstrap"):
		_enc.call("_r34_bootstrap")
	if _hud.has_method("_r34_bootstrap"):
		_hud.call("_r34_bootstrap")
	print("[V110-CBR] 显式 _r34_bootstrap() 完成（A54 唯一实例复用 + 4 信号订阅 + 波次订阅）")


# ---------------------------------------------------------------------------
# ① A54 唯一实例证据（机器判定三方 getter 同一 Object）
# ---------------------------------------------------------------------------
func _t_a54_unique() -> void:
	var c_enc: Object = _enc.call("get_combo_service") as Object if _enc.has_method("get_combo_service") else null
	var c_hud: Object = _hud.call("get_combo_service") as Object if _hud.has_method("get_combo_service") else null
	var c_wave: Object = _wave.call("get_combo_service") as Object if _wave.has_method("get_combo_service") else null
	_combo = c_wave
	_ck("u1 A54 唯一实例：enc / hud / wave.get_combo_service() 为【同一】ComboService（绝不另建第二实例）",
			c_enc != null and c_enc == c_hud and c_hud == c_wave \
					and c_enc.has_method("register_hit") and c_enc.has_signal("combo_changed"),
			"enc=%s hud=%s wave=%s same=%s" % [str(c_enc != null), str(c_hud != null),
					str(c_wave != null), str(c_enc != null and c_enc == c_hud and c_hud == c_wave)])
	var b_wave: Object = _wave.call("get_boon_service") as Object if _wave.has_method("get_boon_service") else null
	var b_hud: Object = _hud.get("_boon_draft_service") as Object
	_ck("u2 A54 唯一实例：hud._boon_draft_service 复用 wave.get_boon_service() 同一 BoonDraftService",
			b_wave != null and b_hud == b_wave,
			"hud=%s wave=%s same=%s" % [str(b_hud != null), str(b_wave != null), str(b_hud == b_wave)])
	_ck("u3 唯一实例为真实 ComboService（4 信号 + settle/get_snapshot 公开接口齐全）",
			_combo != null and _combo.has_signal("combo_changed") and _combo.has_signal("rank_changed") \
					and _combo.has_signal("combo_reset") and _combo.has_signal("combo_settled") \
					and _combo.has_method("settle") and _combo.has_method("get_snapshot"),
			"4signals+settle+snapshot ok=%s" % str(_combo != null))


# ---------------------------------------------------------------------------
# 4 信号探针（订阅唯一实例，验证结束 disconnect）
# ---------------------------------------------------------------------------
func _bind_combo_probes() -> void:
	if _combo == null:
		return
	_probes_connected = true
	_dedup_connect(_combo, "combo_changed", "_on_combo_changed")
	_dedup_connect(_combo, "rank_changed", "_on_rank_changed")
	_dedup_connect(_combo, "combo_reset", "_on_combo_reset")
	_dedup_connect(_combo, "combo_settled", "_on_combo_settled")
	_dedup_connect(_wave, "wave_cleared", "_on_wave_cleared")
	_dedup_connect(_hud, "points_awarded", "_on_points_awarded")   # A57：HUD 发射值探针


func _on_combo_changed(_count: int, _rank: String) -> void:
	_combo_changed_count += 1


func _on_rank_changed(_from_rank: String, _to_rank: String, _multiplier: float) -> void:
	_rank_changed_count += 1


func _on_combo_reset(reason: String) -> void:
	_combo_reset_reasons.append(reason)


func _on_combo_settled(total_points: int, base_points: int, rank: String, multiplier: float) -> void:
	_combo_settled_logs.append({
		"total_points": total_points, "base_points": base_points,
		"rank": rank, "multiplier": multiplier,
	})


func _on_wave_cleared(_index: int, points: int) -> void:
	_wave_cleared_pts.append(points)


func _on_points_awarded(reason: String, points: int, source: String) -> void:
	_a57_pa_log.append({"reason": reason, "points": points, "source": source})


# ---------------------------------------------------------------------------
# ② 真实命中 → combo 增长 → 评级变化（A48 玩家真实可达）
# ---------------------------------------------------------------------------
func _t_real_hit_rank() -> void:
	# 先让 wave 真实进第 1 波（TELEGRAPH→WAVE_ACTIVE），其 _consume_pending_boon() 会 combo.reset()
	# 到干净 D 级；随后用【真实 light_attack 命中链】累积，绝不直接调 register_hit 伪造。
	if _wave.has_method("start_trial"):
		_wave.call("start_trial")
	if _wave.has_method("debug_advance"):
		_wave.call("debug_advance", 999.0)   # TELEGRAPH → WAVE_ACTIVE（单次 _advance 只进一个分支）
	if _combo != null and _combo.has_method("reset"):
		_combo.call("reset")
	var c0: int = int(_combo.call("get_combo")) if _combo != null and _combo.has_method("get_combo") else -1
	var rank0: String = str(_combo.call("get_rank")) if _combo != null and _combo.has_method("get_rank") else "?"
	var rank_changes_before: int = _rank_changed_count
	# 14 击 → A 级（门槛 D:0 C:4 B:8 A:14 [PLACEHOLDER]）；每轮 debug_step(30) 让 27 帧动作
	# 完整走完回 idle，下一轮 request 才被状态机接受；每次命中刷新连击计时，30 拍=0.5s<2.5s 不超时。
	for _i: int in range(14):
		_enc.call("debug_request_action", "attack_light")
		_enc.call("debug_step", 30)
	var c1: int = int(_combo.call("get_combo")) if _combo != null and _combo.has_method("get_combo") else -1
	var rank1: String = str(_combo.call("get_rank")) if _combo != null and _combo.has_method("get_rank") else "?"
	_ck("h1 真实 light_attack 命中 → 唯一实例 combo 增长（player_hit_landed → register_hit）",
			c1 > c0 and c1 >= 14, "combo %d -> %d" % [c0, c1])
	_ck("h2 combo 增长驱动评级变化 D→C→B→A（rank_changed 跨档信号真实发出）",
			rank0 == "D" and rank1 == "A" and _rank_changed_count - rank_changes_before >= 3,
			"rank %s -> %s | rank_changed += %d" % [rank0, rank1, _rank_changed_count - rank_changes_before])
	_ck("h3 4 信号订阅生效：combo_changed 探针随真实命中递增",
			_combo_changed_count >= 14, "combo_changed=%d" % _combo_changed_count)


# ---------------------------------------------------------------------------
# ③ 清波点数按倍率结算（A 级 1.6 → 100×1.6=160 [PLACEHOLDER]）
# ---------------------------------------------------------------------------
func _t_clear_wave_settle() -> void:
	var settled_before: int = _combo_settled_logs.size()
	# 真实状态机清波：WAVE_ACTIVE → on_encounter_finished(true) → _clear_wave() → combo.settle(base)
	var finished: bool = bool(_wave.call("on_encounter_finished", true))
	var ss: Dictionary = _wave.call("get_settlement_snapshot") as Dictionary
	var snap: Dictionary = _wave.call("get_snapshot") as Dictionary
	_ck("s1 真实 wave 状态机清波（on_encounter_finished(true)）→ combo.settle() 结算",
			finished and int(ss.get("settlement_count", 0)) >= 1,
			"finished=%s settlement_count=%s" % [str(finished), str(ss.get("settlement_count", "?"))])
	_ck("s2 清波点数按评级倍率结算：A 级 1.6 → settled=160（100×1.6 [PLACEHOLDER]）",
			int(ss.get("last_settled_points", 0)) == 160 \
					and str(ss.get("combo_rank", "")) == "A" \
					and abs(float(ss.get("combo_multiplier", 0.0)) - 1.6) < 0.001,
			"settled=%s rank=%s mult=%s" % [str(ss.get("last_settled_points", "?")),
					str(ss.get("combo_rank", "?")), str(ss.get("combo_multiplier", "?"))])
	_ck("s3 combo_settled 信号真实发出且携带 total=160 > base=100（倍率生效，供 Rank-3/Rank-4 订阅）",
			_combo_settled_logs.size() > settled_before \
					and int((_combo_settled_logs.back() as Dictionary).get("total_points", 0)) == 160 \
					and int((_combo_settled_logs.back() as Dictionary).get("base_points", 0)) == 100,
			"settled_log=%s" % str(_combo_settled_logs.back() if not _combo_settled_logs.is_empty() else {}))
	_ck("s4 wave_cleared 第二参仍为基础 pts=100（既有输出格式零改动）；倍率只并入导演层落盘口径 → 口径分叉如实登记",
			_wave_cleared_pts.size() >= 1 and _wave_cleared_pts.back() == 100 \
					and int(ss.get("last_settled_points", 0)) == 160 \
					and int(snap.get("points_total", 0)) == 160,
			"wave_cleared_pts=%s settled=%s points_total=%s" % [str(_wave_cleared_pts),
					str(ss.get("last_settled_points", "?")), str(snap.get("points_total", "?"))])
	# 真实抉择按键：清波后卡片打开，按数字键 2 选 boon_02_poise_edge
	# （effect=poise_damage_bonus 0.25 / cost=telegraph_scale 0.85），供任务2 下一波作用链路。
	var ev: InputEventKey = _key(KEY_2, true)
	Input.parse_input_event(ev)
	var consumed: bool = bool(_hud.call("process_key_event", ev))
	var rel: InputEventKey = _key(KEY_2, false)
	Input.parse_input_event(rel)
	var la: Dictionary = _hud.call("get_last_boon_apply") as Dictionary
	_ck("s5 真实数字键 2 → 抉择 apply() 成对 effect/cost 生效（供任务2 下一波敌人参数）",
			consumed and bool(la.get("ok", false)) and bool(la.get("paired", false)) \
					and str(la.get("cost_key", "")) == "telegraph_scale" \
					and str(la.get("effect_key", "")) == "poise_damage_bonus",
			"consumed=%s paired=%s effect=%s cost=%s" % [str(consumed), str(la.get("paired", "?")),
					str(la.get("effect_key", "?")), str(la.get("cost_key", "?"))])


# ---------------------------------------------------------------------------
# ④ 受击重置（玩家受击 → on_hit_taken → combo 归零）
# ---------------------------------------------------------------------------
func _t_hit_taken_reset() -> void:
	# 推进到下一波：WAVE_CLEARED → NEXT_WAVE → TELEGRAPH（wave_started → combo.reset + 广播 + 任务2 作用）
	_wave.call("debug_advance", 0.0)
	_wave.call("debug_advance", 0.0)
	_wave.call("debug_advance", 999.0)   # → WAVE_ACTIVE
	for _i: int in range(3):
		_enc.call("debug_request_action", "attack_light")
		_enc.call("debug_step", 30)
	var before: int = int(_combo.call("get_combo")) if _combo != null and _combo.has_method("get_combo") else -1
	if _enc.has_method("debug_boss_hit"):
		_enc.call("debug_boss_hit")       # 真实玩家受击路径 → _r34b_combo_on_hit_taken()
	var after: int = int(_combo.call("get_combo")) if _combo != null and _combo.has_method("get_combo") else -1
	_ck("r1 玩家受击 → ComboService.on_hit_taken() → combo 归零（受击中断连击）",
			before > 0 and after == 0, "combo %d -> %d" % [before, after])
	_ck("r2 combo_reset(hit_taken) 信号真实发出（4 信号订阅生效）",
			_combo_reset_reasons.has("hit_taken"), "reset_reasons=%s" % str(_combo_reset_reasons))


# ---------------------------------------------------------------------------
# ⑤ 任务2：抉择 cost_key/effect_key 真正作用到运行时敌人参数
# ---------------------------------------------------------------------------
func _t_enemy_params() -> void:
	var ep: Dictionary = _enc.call("get_enemy_runtime_params") as Dictionary
	_ck("p1 运行时敌人参数已由波次开始作用链路刷新（applied=true，字段齐全）",
			_enc.has_method("apply_wave_enemy_params") and _enc.has_method("get_enemy_runtime_params") \
					and not ep.is_empty() and bool(ep.get("applied", false)) \
					and ep.has("hp_scale") and ep.has("telegraph_scale") and ep.has("poise_damage_bonus"),
			"keys=%s" % str(ep.keys()))
	_ck("p2 cost_key=telegraph_scale(0.85) / effect_key=poise_damage_bonus(0.25) 数值真实来自 boon_draft.tres（[PLACEHOLDER] 表）",
			str(ep.get("cost_key", "")) == "telegraph_scale" \
					and str(ep.get("effect_key", "")) == "poise_damage_bonus" \
					and abs(float(ep.get("telegraph_scale", 0.0)) - 0.85) < 0.001 \
					and abs(float(ep.get("poise_damage_bonus", 0.0)) - 0.25) < 0.001,
			"cost=%s(%.2f) effect=%s(%.2f)" % [str(ep.get("cost_key", "?")),
					float(ep.get("cost_value", 0.0)), str(ep.get("effect_key", "?")),
					float(ep.get("effect_value", 0.0))])
	_ck("p3 基础值从 wave_trial.tres（[PLACEHOLDER] 表）读取，有效倍率 = base × cost（不硬编码数值）",
			abs(float(ep.get("base_hp_multiplier", 0.0)) - 1.3) < 0.001 \
					and abs(float(ep.get("effective_telegraph_scale", 0.0)) - 1.275) < 0.001,
			"base_hp=%.2f base_telegraph=%.2f eff_telegraph=%.3f" % [
					float(ep.get("base_hp_multiplier", 0.0)), float(ep.get("base_telegraph_sec", 0.0)),
					float(ep.get("effective_telegraph_scale", 0.0))])
	_ck("p4 代价真正作用到敌人运行时实例（Boss 实例元数据标注有效倍率，不写 .tres / 不改判定分支）",
			bool(ep.get("boss_instance_annotated", false)) \
					and _boss_meta_ok("r34b_effective_telegraph_scale", 1.275),
			"annotated=%s meta_ok=%s" % [str(ep.get("boss_instance_annotated", false)),
					str(_boss_meta_ok("r34b_effective_telegraph_scale", 1.275))])
	_ck("p5 失败降级可观测：无抉择修正时传空 key → 回落中性基线 + degraded 告警（独立确定性调用）",
			_degrade_probe(), "中性基线 hp_scale=1.0 / telegraph_scale=1.0 / poise_bonus=0.0 + degraded=true")


func _boss_meta_ok(key: String, expect: float) -> bool:
	var b: Node = _enc.get("_boss") as Node
	if b == null or not b.has_meta(key):
		return false
	return abs(float(b.get_meta(key)) - expect) < 0.001


func _degrade_probe() -> bool:
	# 独立调用：空 cost/effect → 回落中性基线；调用后原参数由后续 wave_started 重新覆盖。
	var r: Dictionary = _enc.call("apply_wave_enemy_params", 0, "", 0.0, "", 0.0) as Dictionary
	return bool(r.get("applied", false)) and bool(r.get("degraded", false)) \
			and abs(float(r.get("hp_scale", -1.0)) - 1.0) < 0.001 \
			and abs(float(r.get("telegraph_scale", -1.0)) - 1.0) < 0.001 \
			and abs(float(r.get("poise_damage_bonus", -1.0)) - 0.0) < 0.001


# ---------------------------------------------------------------------------
# ⑥ Boss 死亡结算（末波清波 → on_boss_defeated 定格 + settle）+ ENC 接线
# ---------------------------------------------------------------------------
func _t_boss_defeated_settle() -> void:
	# 第 2 波清波（非末波）→ 推进到末波 index 2 → WAVE_ACTIVE → 8 击到 B 级。
	_wave.call("on_encounter_finished", true)
	_wave.call("debug_advance", 0.0)
	_wave.call("debug_advance", 0.0)
	_wave.call("debug_advance", 999.0)
	for _i: int in range(8):
		_enc.call("debug_request_action", "attack_light")
		_enc.call("debug_step", 30)
	var settled_before: int = _combo_settled_logs.size()
	var rank_before: String = str(_combo.call("get_rank")) if _combo != null and _combo.has_method("get_rank") else "?"
	var finished: bool = bool(_wave.call("on_encounter_finished", true))   # 末波 → on_boss_defeated + settle(200)
	var ss: Dictionary = _wave.call("get_settlement_snapshot") as Dictionary
	var boss_defeated: bool = bool(_combo.call("is_boss_defeated")) if _combo != null and _combo.has_method("is_boss_defeated") else false
	_ck("b1 末波（Boss 波）真实清波 → ComboService.on_boss_defeated() 定格评级",
			finished and boss_defeated, "on_encounter_finished=%s boss_defeated=%s rank_before=%s" % [
					str(finished), str(boss_defeated), rank_before])
	_ck("b2 Boss 死亡结算按定格评级倍率：B 级 1.35 → settled=270（200×1.35 [PLACEHOLDER]）",
			int(ss.get("last_settled_points", 0)) == 270 \
					and _combo_settled_logs.size() > settled_before \
					and int((_combo_settled_logs.back() as Dictionary).get("total_points", 0)) == 270,
			"settled=%s rank=%s mult=%s last_log=%s" % [str(ss.get("last_settled_points", "?")),
					str(ss.get("combo_rank", "?")), str(ss.get("combo_multiplier", "?")),
					str(_combo_settled_logs.back() if not _combo_settled_logs.is_empty() else {})])
	_ck("b3 Boss 死亡后 combo_settled 信号再发一次（结算演出 / 点数落盘订阅口径）",
			_combo_settled_logs.size() - settled_before == 1,
			"settled_logs=%d -> %d" % [settled_before, _combo_settled_logs.size()])
	# ENC 任务1 d 接线：真实 _finish(true) 路径 → _r34b_combo_on_boss_defeated() → 唯一实例定格。
	if _combo != null and _combo.has_method("reset"):
		_combo.call("reset")
	for _i2: int in range(2):
		_enc.call("debug_request_action", "attack_light")
		_enc.call("debug_step", 30)
	_enc.call("_finish", true)   # 真实胜利结算路径（不写盘：won 分支不 commit）
	var enc_defeated: bool = bool(_combo.call("is_boss_defeated")) if _combo != null and _combo.has_method("is_boss_defeated") else false
	_ck("b4 ENC 任务1 d：Boss 死亡（_finish(true)）→ on_boss_defeated() 转发到唯一实例生效",
			enc_defeated, "enc_path boss_defeated=%s" % str(enc_defeated))


# ---------------------------------------------------------------------------
# ⑦ 生产 HUD 可见层 / 4 信号订阅证据（供 Rank-4 连击视觉反馈读取）
# ---------------------------------------------------------------------------
func _t_hud_visible() -> void:
	var st: Dictionary = _hud.call("get_production_status") as Dictionary
	var cv: Dictionary = _hud.call("get_combo_hud_view") as Dictionary
	_ck("v1 HUD 已订阅 4 个 combo 信号（get_production_status.combo_signals_connected）",
			bool(st.get("combo_signals_connected", false)),
			"connected=%s" % str(st.get("combo_signals_connected", false)))
	_ck("v2 生产 HUD 可见层视图含评级/倍率/连击数（按状态显示，供 Rank-4 读取）",
			cv.has("rank") and cv.has("multiplier") and cv.has("count") \
					and _hud.has_method("_r34_refresh_visible"),
			"rank=%s mult=%s count=%s changed=%s rank_changed=%s settled=%s" % [
					str(cv.get("rank", "?")), str(cv.get("multiplier", "?")), str(cv.get("count", "?")),
					str(cv.get("changed_count", "?")), str(cv.get("rank_changed_count", "?")),
					str(cv.get("settled_count", "?"))])
	_ck("v3 4 信号探针累计：combo_changed / rank_changed / combo_reset / combo_settled 全链有真实回调",
			_combo_changed_count >= 14 and _rank_changed_count >= 3 \
					and not _combo_reset_reasons.is_empty() and _combo_settled_logs.size() >= 2,
			"changed=%d rank_changed=%d reset=%d settled=%d" % [_combo_changed_count,
					_rank_changed_count, _combo_reset_reasons.size(), _combo_settled_logs.size()])


# ---------------------------------------------------------------------------
# ⑧ 静态口径：ENC/HUD R34B 段零写盘（A50）+ 接线关键字
# ---------------------------------------------------------------------------
func _t_static_wiring() -> void:
	var enc_src: String = FileAccess.get_file_as_string("res://scripts/combat/encounter_director.gd")
	var hud_src: String = FileAccess.get_file_as_string("res://scripts/hud.gd")
	var enc_r34b: String = enc_src.substr(enc_src.find("# R34B [ROUND=R34B]"))
	var hud_r34b: String = hud_src.substr(hud_src.find("# ---- R34B"))
	var no_write: bool = (not enc_r34b.contains(".call(\"set_flag\"") and not enc_r34b.contains(".call(\"commit\"")) \
			and (not hud_r34b.contains(".call(\"set_flag\"") and not hud_r34b.contains(".call(\"commit\"")) \
			and (not enc_r34b.contains("FileAccess.open") and not hud_r34b.contains("FileAccess.open"))
	_ck("w1 R34B 追加段源码零写盘：不含 set_flag / commit / FileAccess 写盘点（I-1 / A50，点数只发信号）",
			enc_r34b.length() > 0 and hud_r34b.length() > 0 and no_write,
			"enc_r34b_len=%d hud_r34b_len=%d no_write=%s" % [enc_r34b.length(), hud_r34b.length(), str(no_write)])
	_ck("w2 ENC 任务1 c/d + 任务2 削韧真实消费接线关键字齐全",
			enc_r34b.contains("_r34b_combo_on_hit_taken") and enc_r34b.contains("_r34b_combo_on_boss_defeated") \
					and enc_src.contains("(1.0 + poise_bonus)") and enc_r34b.contains("apply_wave_enemy_params"),
			"hit_taken/boss_defeated/poise_bonus/apply_wave_enemy_params 命中")


func _finish(early: bool) -> void:
	# A57：释放生产编排层 4 信号订阅 + HUD points_awarded 探针（有释放路径）。
	if _a57_orch != null and is_instance_valid(_a57_orch) and _a57_orch.has_method("_release"):
		_a57_orch.call("_release")
	if _hud != null and is_instance_valid(_hud):
		var cba: Callable = Callable(self, "_on_points_awarded")
		if _hud.has_signal("points_awarded") and _hud.is_connected("points_awarded", cba):
			_hud.disconnect("points_awarded", cba)
	# 释放 4 信号探针 + wave_cleared 连接（有释放路径，不留悬空 Callable）
	if _probes_connected:
		if _combo != null and is_instance_valid(_combo):
			var pairs: Array = [
				["combo_changed", "_on_combo_changed"], ["rank_changed", "_on_rank_changed"],
				["combo_reset", "_on_combo_reset"], ["combo_settled", "_on_combo_settled"]]
			for p: Array in pairs:
				var sig: String = str(p[0])
				var cb: Callable = Callable(self, str(p[1]))
				if _combo.has_signal(sig) and _combo.is_connected(sig, cb):
					_combo.disconnect(sig, cb)
		if _wave != null and is_instance_valid(_wave):
			var cbw: Callable = Callable(self, "_on_wave_cleared")
			if _wave.has_signal("wave_cleared") and _wave.is_connected("wave_cleared", cbw):
				_wave.disconnect("wave_cleared", cbw)
	var ok: bool = (not early) and _fail == 0 and _pass > 0
	print("[V110-CBR] ---- 回读汇总 ----")
	print("[V110-CBR] SUMMARY pass=%d fail=%d total=%d ok=%s" % [_pass, _fail, _pass + _fail, str(ok)])
	if ok:
		print("[V110-CBR] RESULT=ALL_MATCH")
	else:
		print("[V110-CBR] RESULT=MISMATCH")
	print("[V110-CBR] ==== verify_combo_runtime_v110 真跑结束 ====")
	quit(0 if ok else 1)


# ===========================================================================
# A57 [ROUND=R34D] · 裁决 A57 全链回归（追加组，既有 28 条断言逐字不删不放宽）
#   本件天然在第 1 波（wave_trial.tres 基础 pts=100）验证：14 击 A 级 1.6 →
#   100×1.6=160 落在 points_awarded 与磁盘（A57「倍率后值实证」核心证据）。
#   复用生产 autoload PointsCommitOrchestrator（A55 原样采信），不重复挂载、不模拟编排；
#   独立 PID 临时槽，生产 slot_01 全程只读 md5 前后对照。
# ===========================================================================
func _a57_read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


func _a57_prod_md5() -> String:
	if not FileAccess.file_exists(PRODUCTION_DELTA):
		return "<absent>"
	return FileAccess.get_md5(PRODUCTION_DELTA)


## 绑定生产编排层（优先引擎已装配的 autoload，绝不重复挂载）+ 独立 PID 临时槽。
func _a57_bind_orchestrator() -> void:
	var orch: Node = _tree.root.get_node_or_null(NodePath(PCO_AUTOLOAD_NAME)) as Node
	var source: String = "autoload"
	if orch != null:
		# --script 模式 add_child 不自动 flush _ready() → 显式补一次（编排层另有惰性初始化兜底）。
		if orch.has_method("_ready") and not orch.is_node_ready():
			orch.call("_ready")
	else:
		# 极端降级：autoload 未装配时按注册项挂【同一生产脚本】，不在本脚本内另写编排逻辑。
		var scr: Script = ResourceLoader.load(
			PCO_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		if scr != null:
			var n: Node = Node.new()
			n.name = PCO_AUTOLOAD_NAME
			n.set_script(scr)
			_tree.root.add_child(n)
			if n.has_method("_ready"):
				n.call("_ready")
			orch = n
			source = "manual-same-script"
	_a57_orch = orch
	_ck("A57-0 生产编排层实例就位（优先 autoload，不重复挂载；降级时挂同一生产脚本）",
		orch != null and is_instance_valid(orch), "source=%s" % source)
	if orch == null:
		return
	_a57_slot_dir = "%s_%d" % [A57_SLOT_BASE, OS.get_process_id()]
	_a57_delta_path = _a57_slot_dir + "/delta.json"
	_a57_prod_md5_before = _a57_prod_md5()
	var cfg_ok: bool = bool(orch.call("configure_slot", _a57_slot_dir))
	_ck("A57-0b 独立 PID 临时槽与生产 slot_01 物理隔离（落盘前注入）",
		cfg_ok and not _a57_slot_dir.contains("slot_01") and _a57_delta_path != PRODUCTION_DELTA,
		"slot=%s" % _a57_slot_dir)
	var bound: bool = bool(orch.call("bind_hud", _hud))
	_ck("A57-0c PointsCommitOrchestrator.bind_hud 成功（4 信号订阅、A55 唯一权威通道）",
		bound, "bound=%s" % str(bound))


## 在既有 s1~s5（14 击 A 级 → 清波 160 → 抉择）之后立即断言全链；此时下一波
## wave_started / production_wave_modifier 尚未广播，编排层去重键为 auto 指纹。
func _a57_assert_full_chain() -> void:
	print("[V110-CBR][A57] ==== 裁决 A57 全链组开始（第 1 波 100×A级1.6=160）====")
	if _a57_orch == null:
		_ck("A57 编排层可用", false, "orch=null")
		return
	# ① points_awarded 探针：wave_cleared 恰 1 条、携带倍率后值 160（A57 发射值修正）。
	var wave_events: Array[Dictionary] = []
	for e: Dictionary in _a57_pa_log:
		if String(e.get("reason", "")) == "wave_cleared":
			wave_events.append(e)
	var pa_pts: int = int((wave_events[0] as Dictionary).get("points", 0)) if wave_events.size() == 1 else -1
	_ck("A57-1 ★ points_awarded 携带倍率后值 160（wave_cleared 分支，每条清波只发一次、不再是基础 pts=100）",
		wave_events.size() == 1 and pa_pts == 160,
		"wave_events=%s" % str(wave_events))
	# ② 全链一致：真实命中 → combo 增长 → 评级 A → 清波按倍率结算 160 → points_awarded → 编排层落盘 160。
	var ss: Dictionary = _wave.call("get_settlement_snapshot") as Dictionary
	var snap: Dictionary = _wave.call("get_snapshot") as Dictionary
	var last: Dictionary = {}
	if _combo != null and _combo.has_method("get_last_settlement"):
		last = _combo.call("get_last_settlement") as Dictionary
	var st: Dictionary = _a57_orch.call("get_status") as Dictionary
	var disk: Dictionary = _a57_read_json(_a57_delta_path)
	var disk_pts: int = int((disk.get("flags", {}) as Dictionary).get(K_POINTS, 0))
	_a57_points_trace.append(disk_pts)
	print("[V110-CBR][A57] 全链真值 | base=%s mult=%s combo_total=%s 导演层=%s points_awarded=%d 编排层=%s 磁盘=%d" % [
		str(last.get("base_points", "?")), str(ss.get("combo_multiplier", "?")),
		str(last.get("total_points", "?")), str(ss.get("last_settled_points", "?")),
		pa_pts, str(st.get("points", "?")), disk_pts])
	_ck("A57-2 ★ 全链一致 100×1.6=160：导演层结算 / combo 结算 / points_awarded / 编排层 / 磁盘 均为 160",
		int(ss.get("last_settled_points", 0)) == 160 and int(snap.get("points_total", 0)) == 160 \
				and int(last.get("total_points", 0)) == 160 and int(last.get("base_points", 0)) == 100 \
				and pa_pts == 160 and int(st.get("points", 0)) == 160 and disk_pts == 160,
		"settled=%s points_total=%s combo=%s pa=%d runtime=%s disk=%d" % [
			str(ss.get("last_settled_points", "?")), str(snap.get("points_total", "?")),
			str(last.get("total_points", "?")), pa_pts, str(st.get("points", "?")), disk_pts])
	# ③ wave_cleared(index, points) 保留基础值 100 只作 HUD 展示 / 事件键（A57 裁决、既有 s4 不变）。
	_ck("A57-3 wave_cleared(index, points) 保留基础值 100 只作 HUD 展示 / 事件键（A57 裁决、既有 s4 不变）",
		_wave_cleared_pts.size() >= 1 and _wave_cleared_pts.back() == 100,
		"wave_cleared_pts=%s" % str(_wave_cleared_pts))
	# ④ combo_settled 只作对账 / 展示、绝不二次入账。
	var orch_subs_settled: bool = false
	if _combo != null and _combo.has_signal("combo_settled"):
		for conn in _combo.get_signal_connection_list("combo_settled"):
			var c: Callable = conn.get("callable", Callable())
			if c.get_object() == _a57_orch:
				orch_subs_settled = true
	_ck("A57-4 combo_settled 绝不二次入账（编排层不订阅 + 磁盘=160 非 320 + points_awarded 恰 1 次 + combo_settled 已发 total=160）",
		(not orch_subs_settled) and disk_pts == 160 and wave_events.size() == 1 \
				and not _combo_settled_logs.is_empty() \
				and int((_combo_settled_logs.back() as Dictionary).get("total_points", 0)) == 160,
		"orch_subs=%s disk=%d settled_log=%s" % [str(orch_subs_settled), disk_pts,
			str(_combo_settled_logs.back() if not _combo_settled_logs.is_empty() else {})])
	# ⑤ 同一清波重复触发被去重拒绝（两层门控）。
	var cnt_before: int = int((_wave.call("get_settlement_snapshot") as Dictionary).get("settlement_count", 0))
	var dup: bool = bool(_wave.call("on_encounter_finished", true))
	var cnt_after: int = int((_wave.call("get_settlement_snapshot") as Dictionary).get("settlement_count", 0))
	_ck("A57-5a 同一清波重复 on_encounter_finished 被 Rank-2 WAVE_ACTIVE 门控拒绝（不重复结算）",
		(not dup) and cnt_after == cnt_before,
		"dup_accepted=%s settlement_count %d -> %d" % [str(dup), cnt_before, cnt_after])
	_hud.emit_signal("points_awarded", "wave_cleared", 160, "wave_trial_director.wave_cleared")
	var disk2: Dictionary = _a57_read_json(_a57_delta_path)
	var disk2_pts: int = int((disk2.get("flags", {}) as Dictionary).get(K_POINTS, 0))
	_a57_points_trace.append(disk2_pts)
	_ck("A57-5b 重放同一 points_awarded 被编排层去重键拒绝（磁盘不增、不二次入账）",
		disk2_pts == 160 and disk2_pts == disk_pts,
		"disk %d -> %d（重放被拒）" % [disk_pts, disk2_pts])
	# ⑥ 点数只增不减。
	var mono: bool = true
	for i: int in range(1, _a57_points_trace.size()):
		if _a57_points_trace[i] < _a57_points_trace[i - 1]:
			mono = false
	_ck("A57-6 点数只增不减（磁盘逐次回读序列单调不减）",
		mono and _a57_points_trace.size() >= 2, "trace=%s" % str(_a57_points_trace))
	# ⑦ 生产 slot_01 不被污染。
	_ck("A57-7 生产 slot_01 md5 前后一致（全程不写 slot_01）",
		_a57_prod_md5() == _a57_prod_md5_before, "md5=%s" % _a57_prod_md5_before)
	print("[V110-CBR][A57] ==== 裁决 A57 全链组结束 ====")
