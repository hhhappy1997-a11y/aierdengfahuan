extends SceneTree

## ===========================================================================
## R34 / v0.11.0 · 连击评价 Combo Rank「规则表 + 纯逻辑 + 信号」自测（Rank-2 交付件）
##
## 真跑：D:/Godot/Godot_v4.7.2-stable_win64.exe --headless \
##       --path F:/Game/aierdengfahuan/godot \
##       --script res://scripts/combat/verify_combo_v110.gd
## 覆盖（任务单 ③）：正常 / 边界 / 异常三类输入 ——
##   正常：0 连击结算、命中累积 combo、D/C/B/A/S 跨档评级、倍率随评级、Boss 死亡结算、
##         4 个公开信号 connect + payload；
##   边界：0 连击、超长间隔（tick(999) 超时重置）、恰好 timeout、窗口内递减、受击重置、
##         reset_on_hit_taken=false、门槛边界值、同帧多次（累积 / settle 幂等 / tick no-op）；
##   异常：负数伤害、null、0、字符串、NaN/Inf、负/null base_points、config=null、
##         重复 settle、重复 on_boss_defeated、Boss 死亡后命中、异常后正常流程仍成立。
## 输出逐条 PASS=true/false + SUMMARY + OVERALL=PASS/FAIL + RESULT=ALL_MATCH；失败 quit(1)。
## --script 模式纪律：不 add_child、不取 /root/... 绝对路径、不用 get_tree()；
##   用 Engine.get_main_loop() as SceneTree 取 root 做只读断言；读表 CACHE_MODE_IGNORE；
##   不写 user:// 存档、不碰渲染；时间由 tick(delta) 确定性驱动，不依赖真实引擎时钟。
## 期望值来自 combo_rules.tres 首版 [PLACEHOLDER]（4/8/14/22 / 1.0/1.15/1.35/1.6/2.0 /
##   2.5 / true）。调参只改表，同步本脚本 EXPECT_*。
## 引擎：Godot 4.7.2 / GDScript，全静态类型。
## ===========================================================================

const CONFIG_PATH: String = "res://data/rpg/combo_rules.tres"

## [PLACEHOLDER] R34 首版期望（校验基准，不写进数据表；待人工试玩校准）。
const EXPECT_THRESHOLDS: Dictionary = {"D": 0, "C": 4, "B": 8, "A": 14, "S": 22}
const EXPECT_MULT: Dictionary = {"D": 1.0, "C": 1.15, "B": 1.35, "A": 1.6, "S": 2.0}
const EXPECT_TIMEOUT: float = 2.5
const EXPECT_RESET_ON_HIT: bool = true
const RANKS: PackedStringArray = ["D", "C", "B", "A", "S"]

var _pass: int = 0
var _fail: int = 0

## 信号计数 / payload（connect 后统计，每组开头 _reset_signals() 清零）。
var _sig_changed: int = 0
var _sig_rank: int = 0
var _sig_reset: int = 0
var _sig_settled: int = 0
var _last_count: int = -1
var _last_rank: String = ""
var _last_from: String = ""
var _last_to: String = ""
var _last_rank_mult: float = -1.0
var _last_reset_reason: String = ""
var _last_settle_payload: Array = []


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[V110-CB] %s PASS=%s | %s" % [tag, str(ok), detail])


func _on_changed(count: int, rank: String) -> void:
	_sig_changed += 1
	_last_count = count
	_last_rank = rank


func _on_rank(from_rank: String, to_rank: String, multiplier: float) -> void:
	_sig_rank += 1
	_last_from = from_rank
	_last_to = to_rank
	_last_rank_mult = multiplier


func _on_reset(reason: String) -> void:
	_sig_reset += 1
	_last_reset_reason = reason


func _on_settled(total_points: int, base_points: int, rank: String, multiplier: float) -> void:
	_sig_settled += 1
	_last_settle_payload = [total_points, base_points, rank, multiplier]


func _reset_signals() -> void:
	_sig_changed = 0
	_sig_rank = 0
	_sig_reset = 0
	_sig_settled = 0
	_last_count = -1
	_last_rank = ""
	_last_from = ""
	_last_to = ""
	_last_rank_mult = -1.0
	_last_reset_reason = ""
	_last_settle_payload = []


## 构造并 connect 4 个公开信号（Object 级，不经场景树）。
func _make(cfg: ComboConfig) -> ComboService:
	var s: ComboService = ComboService.new(cfg)
	s.connect("combo_changed", Callable(self, "_on_changed"))
	s.connect("rank_changed", Callable(self, "_on_rank"))
	s.connect("combo_reset", Callable(self, "_on_reset"))
	s.connect("combo_settled", Callable(self, "_on_settled"))
	return s


func _initialize() -> void:
	print("[V110-CB] === SELFTEST START ===")
	# --script 模式纪律：用 Engine.get_main_loop() as SceneTree 取 root（只读断言），
	# 不用 get_tree()、不用 /root/... 绝对路径；本夹具纯内存，不 add_child。
	var ml: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = ml as SceneTree
	var root_node: Node = tree.root if tree != null else null
	_ck("scene_tree_root_via_main_loop", tree != null and root_node != null,
		"Engine.get_main_loop() as SceneTree -> root，不用 get_tree()/绝对路径")
	var cfg: ComboConfig = ResourceLoader.load(
		CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as ComboConfig
	_ck("table_load_cache_ignore", cfg != null, "path=%s" % CONFIG_PATH)
	if cfg == null:
		_finish()
		return
	_test_structure(cfg)          # 正常：表结构 / 首版数值 / 降级基线
	_test_public_api(cfg)         # 正常：公开方法与信号签名稳定
	_test_normal_flow(cfg)        # 正常：命中累积 / 跨档 / 倍率 / 信号
	_test_settle(cfg)             # 正常：0 连击 / A / S 结算 / 重复 / Boss 死亡
	_test_boundaries(cfg)         # 边界：0 连击 / 超时长 / 恰好 / 递减 / 受击 / 同帧
	_test_invalid_inputs(cfg)     # 异常：负数 / null / 0 / 字符串 / NaN/Inf / config=null
	_finish()


## A) [正常] 表结构 / 4 个 [PLACEHOLDER] / is_valid / 代码不写死设计数值
func _test_structure(cfg: ComboConfig) -> void:
	_ck("ruleset_valid", cfg.is_valid(), "is_valid=true")
	_ck("rank_count_5", cfg.rank_count() == 5 and cfg.get_ranks() == RANKS,
		"5 档 D/C/B/A/S")
	for rank: String in RANKS:
		_ck("threshold_%s_ph" % rank,
			cfg.get_threshold_for_rank(rank) == int(EXPECT_THRESHOLDS[rank]),
			"got=%d expect=%d [PLACEHOLDER]" % [cfg.get_threshold_for_rank(rank), int(EXPECT_THRESHOLDS[rank])])
		_ck("multiplier_%s_ph" % rank,
			is_equal_approx(cfg.get_multiplier_for_rank(rank), float(EXPECT_MULT[rank])),
			"got=%s expect=%s [PLACEHOLDER]" % [str(cfg.get_multiplier_for_rank(rank)), str(EXPECT_MULT[rank])])
	_ck("timeout_sec_ph", is_equal_approx(cfg.timeout_sec, EXPECT_TIMEOUT),
		"got=%s expect=%s [PLACEHOLDER]" % [str(cfg.timeout_sec), str(EXPECT_TIMEOUT)])
	_ck("reset_on_hit_taken_ph", cfg.reset_on_hit_taken == EXPECT_RESET_ON_HIT,
		"got=%s expect=%s [PLACEHOLDER]" % [str(cfg.reset_on_hit_taken), str(EXPECT_RESET_ON_HIT)])
	# 降级基线 != 设计数值：证明代码里没写死 [PLACEHOLDER] 设计数值（只改表不改代码）
	_ck("default_is_not_design_timeout", not is_equal_approx(ComboConfig.DEFAULT_TIMEOUT_SEC, EXPECT_TIMEOUT),
		"DEFAULT_TIMEOUT_SEC=%s != 表值 2.5（降级基线，非设计数值）" % str(ComboConfig.DEFAULT_TIMEOUT_SEC))
	_ck("default_is_not_design_threshold_S", int(ComboConfig.DEFAULT_RANK_THRESHOLDS["S"]) != int(EXPECT_THRESHOLDS["S"]),
		"DEFAULT_RANK_THRESHOLDS[S]=%d != 表值 22" % int(ComboConfig.DEFAULT_RANK_THRESHOLDS["S"]))
	_ck("default_is_not_design_mult_S", not is_equal_approx(float(ComboConfig.DEFAULT_MULTIPLIER["S"]), float(EXPECT_MULT["S"])),
		"DEFAULT_MULTIPLIER[S]=%s != 表值 2.0" % str(ComboConfig.DEFAULT_MULTIPLIER["S"]))
	# 门槛边界纯函数
	_ck("rank_for_combo_0_D", cfg.get_rank_for_combo(0) == "D", "0 连击 -> D")
	_ck("rank_for_combo_3_D", cfg.get_rank_for_combo(3) == "D", "3 连击 -> D（门槛 4 之前）")
	_ck("rank_for_combo_4_C", cfg.get_rank_for_combo(4) == "C", "4 连击 -> C（恰好门槛）")
	_ck("rank_for_combo_21_A", cfg.get_rank_for_combo(21) == "A", "21 连击 -> A")
	_ck("rank_for_combo_22_S", cfg.get_rank_for_combo(22) == "S", "22 连击 -> S（恰好门槛）")
	_ck("rank_for_combo_999_S", cfg.get_rank_for_combo(999) == "S", "999 连击封顶 S")
	_ck("rank_for_combo_negative_clamped", cfg.get_rank_for_combo(-5) == "D", "负 combo 夹到 0 -> D")


## B) [正常] 公开方法 / 信号签名稳定（供 Rank-1 接线 / Rank-4 视觉反馈，见 DONE-R34.md）
func _test_public_api(cfg: ComboConfig) -> void:
	var s: ComboService = ComboService.new(cfg)
	_ck("signal_combo_changed_exists", s.has_signal("combo_changed"),
		"signal combo_changed(count: int, rank: String)")
	_ck("signal_rank_changed_exists", s.has_signal("rank_changed"),
		"signal rank_changed(from_rank: String, to_rank: String, multiplier: float)")
	_ck("signal_combo_reset_exists", s.has_signal("combo_reset"),
		"signal combo_reset(reason: String)")
	_ck("signal_combo_settled_exists", s.has_signal("combo_settled"),
		"signal combo_settled(total_points: int, base_points: int, rank: String, multiplier: float)")
	_ck("reset_reason_constants", ComboService.RESET_HIT_TAKEN == "hit_taken" \
		and ComboService.RESET_TIMEOUT == "timeout" \
		and ComboService.RESET_BOSS_DEFEATED == "boss_defeated" \
		and ComboService.RESET_MANUAL == "manual",
		"RESET_HIT_TAKEN / RESET_TIMEOUT / RESET_BOSS_DEFEATED / RESET_MANUAL 稳定")
	_ck("reason_constants", ComboService.REASON_OK == "ok" \
		and ComboService.REASON_NO_CONFIG == "no_config" \
		and ComboService.REASON_INVALID_HIT == "invalid_hit" \
		and ComboService.REASON_INVALID_POINTS == "invalid_points" \
		and ComboService.REASON_INVALID_DELTA == "invalid_delta" \
		and ComboService.REASON_BOSS_DEFEATED == "boss_defeated" \
		and ComboService.REASON_ALREADY_DEFEATED == "already_defeated" \
		and ComboService.REASON_ALREADY_SETTLED == "already_settled" \
		and ComboService.REASON_RESET_DISABLED == "reset_disabled",
		"9 个 REASON_* 常量稳定")
	var snap: Dictionary = s.get_snapshot()
	for k: String in ["combo", "rank", "multiplier", "elapsed_since_hit", "timeout_sec",
		"reset_on_hit_taken", "boss_defeated", "settled", "config_present", "last_settlement"]:
		_ck("snapshot_has_%s" % k, snap.has(k), "get_snapshot() 含 %s" % k)
	_ck("public_read_methods", s.get_combo() == 0 and s.get_rank() == "D" \
		and is_equal_approx(s.get_multiplier(), 1.0) \
		and is_equal_approx(s.get_elapsed_since_hit(), 0.0) \
		and is_equal_approx(s.get_timeout_sec(), EXPECT_TIMEOUT) \
		and s.get_reset_on_hit_taken() == EXPECT_RESET_ON_HIT \
		and not s.is_boss_defeated() and not s.is_settled() \
		and s.get_config() == cfg and s.get_last_settlement().is_empty(),
		"get_combo/get_rank/get_multiplier/get_elapsed_since_hit/get_timeout_sec/"
		+ "get_reset_on_hit_taken/is_boss_defeated/is_settled/get_config/get_last_settlement")


## C) [正常] 命中累积 22 次、跨 4 档、倍率随评级、4 个信号计数与 payload
func _test_normal_flow(cfg: ComboConfig) -> void:
	var s: ComboService = _make(cfg)
	_reset_signals()
	var ranks: Array = []
	var rank_up_count: int = 0
	var hit_all_ok: bool = true
	for i: int in range(22):
		var r: Dictionary = s.register_hit(10.0)
		ranks.append(str(r.get("rank")))
		if not bool(r.get("ok", false)):
			hit_all_ok = false
		if bool(r.get("rank_up", false)):
			rank_up_count += 1
	_ck("hit_all_ok", hit_all_ok and ranks.size() == 22, "22 次命中全部 ok=true")
	_ck("rank_at_1_D", ranks[0] == "D", "第 1 击 -> D")
	_ck("rank_at_4_C", ranks[3] == "C", "第 4 击 -> C（跨档）")
	_ck("rank_at_8_B", ranks[7] == "B", "第 8 击 -> B（跨档）")
	_ck("rank_at_14_A", ranks[13] == "A", "第 14 击 -> A（跨档）")
	_ck("rank_at_22_S", ranks[21] == "S", "第 22 击 -> S（跨档）")
	_ck("combo_22", s.get_combo() == 22, "combo=22")
	_ck("multiplier_S_2_0", is_equal_approx(s.get_multiplier(), 2.0), "S 级倍率=2.0 [PLACEHOLDER]")
	_ck("signal_changed_22", _sig_changed == 22, "combo_changed 发 22 次（每次命中）")
	_ck("signal_rank_changed_4", _sig_rank == 4, "rank_changed 恰好 4 次（D→C→B→A→S）")
	_ck("signal_rank_payload_S", _last_from == "A" and _last_to == "S" \
		and is_equal_approx(_last_rank_mult, 2.0),
		"末次 rank_changed(A→S, mult=2.0)")
	_ck("rank_up_flag_on_cross", rank_up_count == 4,
		"跨档 4 次 register_hit.rank_up=true（D→C/C→B/B→A/A→S）")
	# 重复命中同一档不重复 rank_changed
	_reset_signals()
	var s2: ComboService = _make(cfg)
	for i: int in range(3):
		s2.register_hit(10.0)
	_ck("no_rank_change_within_D", _sig_rank == 0 and s2.get_rank() == "D",
		"D 档内 3 连击不跨档、rank_changed=0")


## D) [正常] 结算：0 连击 / A / S / 余额非负 / 重复拒绝 / Boss 死亡结算
func _test_settle(cfg: ComboConfig) -> void:
	# 0 连击：D 级倍率 1.0，total = base，不惩罚、不加点
	_reset_signals()
	var s0: ComboService = _make(cfg)
	var r0: Dictionary = s0.settle(100)
	_ck("settle_zero_combo_D_100", bool(r0.get("ok")) and str(r0.get("rank")) == "D" \
		and is_equal_approx(float(r0.get("multiplier")), 1.0) \
		and int(r0.get("total_points")) == 100 and int(r0.get("bonus_points")) == 0,
		"0 连击 -> total=100 mult=1.0（基础结算）[PLACEHOLDER]")
	_ck("settle_balance_nonneg", int(r0.get("balance")) == 100 and int(r0.get("balance")) >= 0,
		"balance=100 >= 0（余额非负）")
	_ck("signal_settled_once", _sig_settled == 1, "combo_settled 恰好发 1 次")
	_ck("signal_settled_payload", _last_settle_payload.size() == 4 \
		and int(_last_settle_payload[0]) == 100 and int(_last_settle_payload[1]) == 100 \
		and str(_last_settle_payload[2]) == "D",
		"payload total=100 base=100 rank=D")
	# 重复 settle：幂等拒绝、不重复给点
	var r0b: Dictionary = s0.settle(100)
	_ck("duplicate_settle_rejected", not bool(r0b.get("ok")) \
		and str(r0b.get("reason")) == ComboService.REASON_ALREADY_SETTLED,
		"同帧/重复 settle -> already_settled 拒绝（防刷点）")
	_ck("duplicate_settle_no_points", int(r0b.get("total_points")) == 0 \
		and int(r0b.get("balance")) == 0,
		"重复拒绝时 total=0 balance=0")
	_ck("settle_last_settlement_recorded", s0.is_settled() and not s0.get_last_settlement().is_empty(),
		"get_last_settlement() 记录首次结算")
	# A 级：14 连击 mult 1.6 -> round(100*1.6)=160
	var sA: ComboService = _make(cfg)
	for i: int in range(14):
		sA.register_hit(10.0)
	var rA: Dictionary = sA.settle(100)
	_ck("settle_A_160", bool(rA.get("ok")) and str(rA.get("rank")) == "A" \
		and is_equal_approx(float(rA.get("multiplier")), 1.6) \
		and int(rA.get("total_points")) == 160 and int(rA.get("bonus_points")) == 60,
		"A 级 -> total=160 mult=1.6 bonus=60 [PLACEHOLDER]")
	# S 级：22 连击 mult 2.0 -> 200
	var sS: ComboService = _make(cfg)
	for i: int in range(22):
		sS.register_hit(10.0)
	var rS: Dictionary = sS.settle(100)
	_ck("settle_S_200", bool(rS.get("ok")) and str(rS.get("rank")) == "S" \
		and int(rS.get("total_points")) == 200 and int(rS.get("bonus_points")) == 100,
		"S 级 -> total=200 mult=2.0 [PLACEHOLDER]")
	# 余额非负：多组成功结算恒 balance>=0 且 =total、bonus>=0
	var all_nonneg: bool = true
	for r: Dictionary in [r0, rA, rS]:
		if int(r.get("balance")) < 0 or int(r.get("balance")) != int(r.get("total_points")):
			all_nonneg = false
		if int(r.get("bonus_points")) < 0:
			all_nonneg = false
	_ck("balance_all_nonneg", all_nonneg, "全程 balance>=0 且 =total，bonus>=0")
	# Boss 死亡结算：定格评级后仍可 settle 一次；重复死亡 / 死亡后命中拒绝
	var sB: ComboService = _make(cfg)
	for i: int in range(14):
		sB.register_hit(10.0)
	var b1: Dictionary = sB.on_boss_defeated()
	_ck("boss_defeated_ok", bool(b1.get("ok")) and sB.is_boss_defeated() \
		and str(b1.get("rank")) == "A",
		"on_boss_defeated -> 定格 A 级")
	var b2: Dictionary = sB.on_boss_defeated()
	_ck("duplicate_boss_defeated_rejected", not bool(b2.get("ok")) \
		and str(b2.get("reason")) == ComboService.REASON_ALREADY_DEFEATED,
		"重复 on_boss_defeated -> already_defeated 拒绝")
	var hb: Dictionary = sB.register_hit(10.0)
	_ck("boss_defeated_hit_rejected", not bool(hb.get("ok")) \
		and str(hb.get("reason")) == ComboService.REASON_BOSS_DEFEATED,
		"Boss 死亡后命中 -> 拒绝")
	var sb: Dictionary = sB.settle(100)
	_ck("boss_defeated_settle_ok", bool(sb.get("ok")) and int(sb.get("total_points")) == 160,
		"Boss 死亡结算仍得 A 级 160 点")


## E) [边界] 0 连击 / 超长间隔 / 恰好 timeout / 窗口内递减 / 受击重置 /
##          reset_on_hit_taken=false / 同帧多次
func _test_boundaries(cfg: ComboConfig) -> void:
	# 0 连击直接结算（不经任何命中）
	var sZ: ComboService = _make(cfg)
	var rZ: Dictionary = sZ.settle(150)
	_ck("bnd_zero_combo_settle", bool(rZ.get("ok")) and int(rZ.get("total_points")) == 150 \
		and sZ.get_combo() == 0,
		"0 连击直接结算 150（D 级，不崩、不惩罚）")
	# 超长间隔：命中 5 次 -> C，一次 tick(999) 超时归零
	_reset_signals()
	var s1: ComboService = _make(cfg)
	for i: int in range(5):
		s1.register_hit(10.0)
	_ck("bnd_before_timeout_rank_C", s1.get_rank() == "C" and s1.get_combo() == 5,
		"5 连击 -> C 级")
	var t1: Dictionary = s1.tick(999.0)
	_ck("bnd_overlong_interval_timeout", bool(t1.get("ok")) and bool(t1.get("timed_out")) \
		and s1.get_combo() == 0 and s1.get_rank() == "D",
		"超长间隔 delta=999 > 2.5 -> 超时重置 combo=0 / D 级")
	_ck("bnd_timeout_reset_reason", _sig_reset == 1 \
		and _last_reset_reason == ComboService.RESET_TIMEOUT,
		"combo_reset(reason=timeout) 恰好 1 次")
	_ck("bnd_timeout_rank_changed_down", _sig_rank == 2 \
		and _last_from == "C" and _last_to == "D",
		"命中升档 D→C + 超时降档 C→D 共 2 次 rank_changed，末次 C→D（供 Rank-4 收起特效）")
	# 恰好 timeout：tick(2.5) 触发超时
	_reset_signals()
	var s2: ComboService = _make(cfg)
	for i: int in range(5):
		s2.register_hit(10.0)
	var t2: Dictionary = s2.tick(EXPECT_TIMEOUT)
	_ck("bnd_exact_timeout", bool(t2.get("timed_out")) and s2.get_combo() == 0,
		"delta=2.5（恰好 timeout）-> 超时重置")
	# 窗口内递减：tick(1.0) 不超时、elapsed 累加、combo/评级保持
	_reset_signals()
	var s3: ComboService = _make(cfg)
	for i: int in range(5):
		s3.register_hit(10.0)
	var t3: Dictionary = s3.tick(1.0)
	_ck("bnd_within_timeout_decrement", bool(t3.get("ok")) and not bool(t3.get("timed_out")) \
		and s3.get_combo() == 5 and is_equal_approx(s3.get_elapsed_since_hit(), 1.0),
		"delta=1.0 -> elapsed=1.0、combo 保持 5、未超时")
	# 命中刷新计时：再命中一次后 elapsed 归零、tick(2.0) 不超时
	s3.register_hit(10.0)
	_ck("bnd_hit_refreshes_elapsed", is_equal_approx(s3.get_elapsed_since_hit(), 0.0),
		"命中后 elapsed 归零（计时刷新）")
	var t3b: Dictionary = s3.tick(2.0)
	_ck("bnd_hit_resets_timer", not bool(t3b.get("timed_out")) and s3.get_combo() == 6,
		"命中后 elapsed 归零，再 tick(2.0)<2.5 不超时")
	# 受击重置
	_reset_signals()
	var s4: ComboService = _make(cfg)
	for i: int in range(10):
		s4.register_hit(10.0)
	var h4: Dictionary = s4.on_hit_taken()
	_ck("bnd_hit_taken_reset", bool(h4.get("ok")) and bool(h4.get("reset")) \
		and s4.get_combo() == 0 and s4.get_rank() == "D",
		"受击 -> 中断连击归零、评级回 D")
	_ck("bnd_hit_taken_reset_reason", _sig_reset == 1 \
		and _last_reset_reason == ComboService.RESET_HIT_TAKEN,
		"combo_reset(reason=hit_taken)")
	# reset_on_hit_taken=false：受击 no-op、combo 不变
	var cfg_off: ComboConfig = cfg.duplicate() as ComboConfig
	cfg_off.reset_on_hit_taken = false
	var s5: ComboService = _make(cfg_off)
	for i: int in range(6):
		s5.register_hit(10.0)
	var h5: Dictionary = s5.on_hit_taken()
	_ck("bnd_reset_disabled_no_reset", bool(h5.get("ok")) \
		and str(h5.get("reason")) == ComboService.REASON_RESET_DISABLED \
		and not bool(h5.get("reset")) and s5.get_combo() == 6,
		"reset_on_hit_taken=false -> 受击不中断（REASON_RESET_DISABLED）")
	_ck("bnd_reset_disabled_config_valid", cfg_off.is_valid() and not s5.get_reset_on_hit_taken(),
		"对照档表仍合法、读接口返回 false")
	# 同帧多次：多次命中累积、多次 settle 幂等、无 combo 时多次 tick no-op
	_reset_signals()
	var s6: ComboService = _make(cfg)
	for i: int in range(4):
		s6.register_hit(10.0)
	_ck("same_frame_hits_accumulate", s6.get_combo() == 4 and s6.get_rank() == "C",
		"同帧 4 次命中累积 combo=4 -> C")
	var k1: Dictionary = s6.tick(0.016)
	var k2: Dictionary = s6.tick(0.016)
	_ck("same_frame_tick_noop", bool(k1.get("ok")) and bool(k2.get("ok")) \
		and not bool(k1.get("timed_out")) and not bool(k2.get("timed_out")) \
		and s6.get_combo() == 4,
		"同帧多次 tick 不超时、combo 保持")
	var e1: Dictionary = s6.settle(100)
	var e2: Dictionary = s6.settle(100)
	_ck("same_frame_settle_once", bool(e1.get("ok")) and not bool(e2.get("ok")) \
		and int(e1.get("total_points")) == 115 and s6.is_settled(),
		"同帧多次 settle 只第 1 次生效（C 级 100*1.15=115）")
	# reset：归零、评级回 D、清标志
	var s7: ComboService = _make(cfg)
	for i: int in range(22):
		s7.register_hit(10.0)
	s7.settle(100)
	s7.reset()
	_ck("bnd_reset_all", s7.get_combo() == 0 and s7.get_rank() == "D" \
		and not s7.is_settled() and not s7.is_boss_defeated() \
		and is_equal_approx(s7.get_elapsed_since_hit(), 0.0),
		"reset -> 归零 / D 级 / 清结算与死亡标志 / 清计时")


## F) [异常] 负数/null/0/字符串/NaN/Inf 伤害、负/null base、null delta、config=null、
##          异常不改状态、异常后正常流程仍成立
func _test_invalid_inputs(cfg: ComboConfig) -> void:
	var s: ComboService = _make(cfg)
	_ck("invalid_hit_negative_rejected", not bool(s.register_hit(-5.0).get("ok")) \
		and str(s.register_hit(-5.0).get("reason")) == ComboService.REASON_INVALID_HIT,
		"register_hit(-5) 负数伤害拒绝")
	_ck("invalid_hit_zero_rejected", not bool(s.register_hit(0).get("ok")), "register_hit(0) 拒绝")
	_ck("invalid_hit_null_rejected", not bool(s.register_hit(null).get("ok")), "register_hit(null) 拒绝")
	_ck("invalid_hit_string_rejected", not bool(s.register_hit("x").get("ok")), "register_hit(字符串) 拒绝")
	_ck("invalid_hit_nan_rejected", not bool(s.register_hit(NAN).get("ok")), "register_hit(NaN) 拒绝")
	_ck("invalid_hit_inf_rejected", not bool(s.register_hit(INF).get("ok")), "register_hit(Inf) 拒绝")
	_ck("invalid_hit_no_state_change", s.get_combo() == 0 and s.get_rank() == "D",
		"异常命中不改状态（combo=0 / D 级）")
	# settle 异常
	var r_neg: Dictionary = s.settle(-1)
	_ck("invalid_points_negative_rejected", not bool(r_neg.get("ok")) \
		and str(r_neg.get("reason")) == ComboService.REASON_INVALID_POINTS, "settle(-1) 拒绝")
	_ck("invalid_points_no_output", int(r_neg.get("total_points")) == 0 \
		and int(r_neg.get("balance")) == 0 and int(r_neg.get("bonus_points")) == 0,
		"拒绝时 total=0 balance=0 bonus=0（不产出负点数）")
	_ck("invalid_points_null_rejected", not bool(s.settle(null).get("ok")), "settle(null) 拒绝")
	_ck("invalid_points_string_rejected", not bool(s.settle("x").get("ok")), "settle(字符串) 拒绝")
	_ck("invalid_points_nan_rejected", not bool(s.settle(NAN).get("ok")), "settle(NaN) 拒绝")
	_ck("invalid_points_inf_rejected", not bool(s.settle(INF).get("ok")), "settle(Inf) 拒绝")
	_ck("invalid_points_not_settled", not s.is_settled(), "异常 settle 不置 _settled（状态未污染）")
	# tick 异常
	_ck("invalid_delta_null_rejected", not bool(s.tick(null).get("ok")), "tick(null) 拒绝")
	_ck("invalid_delta_negative_rejected", not bool(s.tick(-1.0).get("ok")), "tick(-1) 拒绝")
	_ck("invalid_delta_string_rejected", not bool(s.tick("x").get("ok")), "tick(字符串) 拒绝")
	_ck("invalid_delta_nan_rejected", not bool(s.tick(NAN).get("ok")), "tick(NaN) 拒绝")
	_ck("invalid_delta_inf_rejected", not bool(s.tick(INF).get("ok")), "tick(Inf) 拒绝")
	# config=null
	var s_null: ComboService = ComboService.new(null)
	var rn: Dictionary = s_null.register_hit(10.0)
	_ck("invalid_no_config_hit_rejected", not bool(rn.get("ok")) \
		and str(rn.get("reason")) == ComboService.REASON_NO_CONFIG, "config=null 命中拒绝")
	var rsn: Dictionary = s_null.settle(100)
	_ck("invalid_no_config_settle_rejected", not bool(rsn.get("ok")) \
		and str(rsn.get("reason")) == ComboService.REASON_NO_CONFIG, "config=null 结算拒绝")
	_ck("invalid_no_config_snapshot", s_null.get_snapshot().get("config_present") == false,
		"config=null 快照 config_present=false（降级不崩）")
	# 异常后正常流程仍成立
	var s_ok: ComboService = _make(cfg)
	s_ok.register_hit(null)
	s_ok.settle(-1)
	for i: int in range(14):
		s_ok.register_hit(10.0)
	var r_ok: Dictionary = s_ok.settle(100)
	_ck("invalid_then_normal_ok", bool(r_ok.get("ok")) and int(r_ok.get("total_points")) == 160,
		"异常拒绝后正常流程仍得 A 级 160（状态未被污染）")


func _finish() -> void:
	print("[V110-CB] SUMMARY pass=%d fail=%d" % [_pass, _fail])
	var all_ok: bool = _fail == 0 and _pass > 0
	print("[V110-CB] OVERALL=%s" % ("PASS" if all_ok else "FAIL"))
	print("[V110-CB] RESULT=%s" % ("ALL_MATCH" if all_ok else "FAIL"))
	print("[V110-CB] === SELFTEST END ===")
	quit(0 if all_ok else 1)
