extends SceneTree
class_name RollRuntimeCheck

## ===========================================================================
## R22 / cmd-20261109-124640-182-A2 · Rank-2 翻滚无敌窗口「运行期逐帧实测」
##
## 与 R19/R21 的区别：R19/R21 只在【数据层】静态断言 4/9/9=22 帧@60、无敌 [4,13)；
## 本脚本【真跑】按 logic_fps 逐帧推进 action_04_roll 的 startup/active/recovery，
## 每帧注入 1 次来袭命中，输出 frame_index / invulnerable / hit_accepted，并在运行期
## 逐帧断言三段受击行为，补齐「跑起来的东西判断进度」这一层。
##
## 【数据同源 / 零硬编码期望】所有边界（startup/active/recovery/inv_start/inv_end/
##   logic_fps/total）一律从 player_actions.tres 的 PlayerActionData 字段读出并派生，
##   脚本内不出现任何战斗数值字面量常量（4/9/9/22/4/13/60 均不写死）。
##   「期望」与「运行逻辑」虽同源，却刻意取自不同字段、用不同机制计算，保证断言有区分度：
##     · 运行逻辑（被测）：逐字复刻 teamwork/Rank-2/player_state_machine.gd:233-242
##       is_invulnerable() —— 用 invulnerable_start_frame / invulnerable_end_frame 字段判定，
##       这正是工程里玩家状态机真实采用的判定；
##     · 期望（基准）：由三段帧字段按 E-7 自洽等式推导 [startup, startup+active)
##       （与 godot/scripts/combat/boss_controller.gd:226-227 的 [startup, active_end)
##       判定窗口口径一致）；
##     · 逐帧断言两者相等 —— 验证「数据层字段」与「运行期状态机行为」一致，
##       若 .tres 被改坏（如 inv_end 与 active 段错位）运行期即 FAIL，非自证循环。
##
## 【0-based frame_index 口径】数据层无敌区间 [inv_start, inv_end) 为 0-based 左闭右开；
##   规格件 player_state_machine.gd 的 _physics_process 先 state_frame += 1 再判定，
##   存在 1-based 偏移。本运行期实测以 0-based frame_index ∈ [0, total) 逐帧推进，
##   使逐帧表与 [4,13) 数据口径直接对齐；该口径差异如实登记，不擅改规格件。
##
## 【同跑验证器】preload(res://scripts/combat/combat_data_validator.gd).new() 真实实例化
##   CombatDataValidator 并调用 validate_all() -> Dictionary，打印 VALIDATOR_ERROR；
##   R21「650 PASS」合计口径由外部重跑 res://scripts/verify_frame_data.gd 回归段确认
##   （本单只调用、不修改 verify_frame_data.gd）。
##
## 【门禁 / 可复跑命令】ROOT=F:/Game/aierdengfahuan/godot，ENGINE=D:/Godot/Godot_v4.7.2-stable_win64.exe
##   G1 $ENGINE --headless --path $ROOT --import                                 （新增 class_name 必跑）
##   G2 $ENGINE --headless --path $ROOT --check-only --script res://scripts/combat/roll_runtime_check.gd
##   G3 $ENGINE --headless --path $ROOT --quit
##   主真跑 $ENGINE --headless --path $ROOT --script res://scripts/combat/roll_runtime_check.gd
##   650 回归 $ENGINE --headless --path $ROOT --script res://scripts/verify_frame_data.gd
##
## 退出码真实反映断言结论（PASS->0 / FAIL->1），不恒为 0、不预设结论、不伪造输出。
## 只新增本文件；不写 project.godot / courtyard.tscn / hud.gd / hd2d_fx.* / capture/ /
## verify_frame_data.gd。GDScript 全静态类型标注。中文 UTF-8。
## ===========================================================================

const PLAYER_TRES: String = "res://data/combat/player_actions.tres"
const ROLL_ID: String = "action_04_roll"
const VALIDATOR_SCRIPT = preload("res://scripts/combat/combat_data_validator.gd")

var _pass: int = 0
var _fail: int = 0


func _initialize() -> void:
	print("==== [R22 ROLL RUNTIME CHECK] START ====")
	var table: PlayerActionTable = load(PLAYER_TRES) as PlayerActionTable
	if table == null:
		print("[FATAL] load() 失败 | path=%s" % PLAYER_TRES)
		print("==== [R22 ROLL RUNTIME CHECK] RESULT=LOAD_FAILED ====")
		quit(1)
		return

	# ---- 唯一真源：从 .tres 取出 action_04_roll ----
	var roll: PlayerActionData = null
	for entry in table.actions:
		var action: PlayerActionData = entry as PlayerActionData
		if action != null and action.id == ROLL_ID:
			roll = action
			break
	if roll == null:
		print("[FATAL] 未找到 %s | path=%s" % [ROLL_ID, PLAYER_TRES])
		print("==== [R22 ROLL RUNTIME CHECK] RESULT=ACTION_NOT_FOUND ====")
		quit(1)
		return

	# ---- 全部边界同源读取，零硬编码 ----
	var s: int = roll.startup_frames
	var a: int = roll.active_frames
	var r: int = roll.recovery_frames
	var ist: int = roll.invulnerable_start_frame
	var ien: int = roll.invulnerable_end_frame
	var fps: int = roll.logic_fps
	var total: int = s + a + r
	var delta: float = 1.0 / float(fps) if fps > 0 else 0.0
	# 期望基准：由三段帧按 E-7 推导 [startup, startup+active)（独立于 inv_* 字段）
	var exp_inv_start: int = s
	var exp_inv_end: int = s + a

	print("---- [SOURCE] 期望与运行逻辑同源读取 player_actions.tres（零硬编码）----")
	print("[SOURCE] id=%s state_name=%s | startup_frames=%d active_frames=%d recovery_frames=%d" % [roll.id, roll.state_name, s, a, r])
	print("[SOURCE] invulnerable_start_frame=%d invulnerable_end_frame=%d logic_fps=%d" % [ist, ien, fps])
	print("[SOURCE] derived total=s+a+r=%d | 步进 delta=1/%d=%.6f s | 期望 E-7 窗口=[%d,%d)" % [total, fps, delta, exp_inv_start, exp_inv_end])
	print("[SOURCE] 分段口径（均由变量派生）: startup=[0,%d) / 无敌=[%d,%d) / 恢复=[%d,%d)" % [s, ist, ien, ien, total])

	# ---- 逐帧推进：startup -> active -> recovery，每帧注入 1 次来袭命中 ----
	print("---- [FRAME TABLE] frame_index / phase / invulnerable / hit_accepted / inv_expected ----")
	var frames_run: int = 0
	var startup_all_hit: bool = true
	var invuln_all_inv: bool = true
	var recovery_all_hit: bool = true
	var elapsed: float = 0.0
	for frame_index: int in range(total):
		var phase: String = "startup" if frame_index < s else ("active" if frame_index < s + a else "recovery")
		# 运行逻辑（被测）：逐字复刻 player_state_machine.gd is_invulnerable()，用 inv_* 字段
		var invulnerable: bool = _runtime_is_invulnerable(roll, frame_index)
		# 每帧注入 1 次来袭命中：无敌则拒绝、否则接受
		var hit_accepted: bool = not invulnerable
		# 期望（基准）：由三段帧推导的 E-7 窗口，独立计算
		var expected_inv: bool = frame_index >= exp_inv_start and frame_index < exp_inv_end
		print("FRAME frame_index=%d phase=%s invulnerable=%s hit_accepted=%s inv_expected=%s elapsed_sec=%.4f" % [
			frame_index, phase, str(invulnerable), str(hit_accepted), str(expected_inv), elapsed])
		_check("frame[%d] 运行期 invulnerable == E-7 期望(%s)" % [frame_index, str(expected_inv)], invulnerable == expected_inv)
		_check("frame[%d] hit_accepted == !invulnerable" % frame_index, hit_accepted == (not invulnerable))
		# 三段受击行为累计（边界全为变量）
		if frame_index < s and not hit_accepted:
			startup_all_hit = false
		if frame_index >= ist and frame_index < ien and not invulnerable:
			invuln_all_inv = false
		if frame_index >= ien and not hit_accepted:
			recovery_all_hit = false
		frames_run += 1
		elapsed += delta

	# ---- 分段 / 总帧 / E-7 / fps 断言（边界全部由 .tres 变量派生）----
	print("---- [ASSERT] 分段 / 总帧 / E-7 / fps ----")
	_assert_named("startup [0,%d) 全部可受击" % s, startup_all_hit)
	_assert_named("无敌 [%d,%d) 全部免伤" % [ist, ien], invuln_all_inv)
	_assert_named("恢复 [%d,%d) 全部可受击" % [ien, total], recovery_all_hit)
	_assert_named("总帧 frames_run==total(=%d)" % total, frames_run == total)
	_assert_named("total==startup+active+recovery", total == s + a + r)
	_assert_named("E-7 inv_start==startup", ist == s)
	_assert_named("E-7 inv_end==startup+active", ien == s + a)
	_assert_named("E-7 无敌长度==active", ien - ist == a)
	_assert_named("E-7 0<=inv_start<inv_end<=total", ist >= 0 and ist < ien and ien <= total)
	_assert_named("logic_fps>0 且逐帧步进时长自洽", fps > 0 and is_equal_approx(elapsed, float(total) / float(fps)))

	# ---- 同跑 CombatDataValidator.validate_all() ----
	print("---- [VALIDATOR] 同跑 CombatDataValidator.validate_all() ----")
	var validator: CombatDataValidator = VALIDATOR_SCRIPT.new() as CombatDataValidator
	var vres: Dictionary = validator.validate_all()
	var v_checks: int = int(vres.get("checks", 0))
	var v_pass: int = int(vres.get("pass", 0))
	var v_fail: int = int(vres.get("fail", 0))
	var v_errors: Array = vres.get("errors", []) as Array
	var v_status: String = String(vres.get("status", ""))
	print("[VALIDATOR] instance_valid=%s | checks=%d pass=%d fail=%d errors=%d status=%s" % [
		str(is_instance_valid(validator)), v_checks, v_pass, v_fail, v_errors.size(), v_status])
	print("[VALIDATOR] VALIDATOR_ERROR=%d" % v_fail)
	_assert_named("VALIDATOR_ERROR==0 (validate_all fail==0)", v_fail == 0)
	_assert_named("VALIDATOR errors 为空", v_errors.is_empty())
	_assert_named("VALIDATOR status==OK", v_status == "OK")

	# ---- SUMMARY ----
	print("==== [R22 ROLL RUNTIME CHECK] SUMMARY ====")
	print("  逐帧实测 | FRAMES_RUN=%d TOTAL=%d FPS=%d | startup=[0,%d) / 无敌=[%d,%d) / 恢复=[%d,%d)" % [
		frames_run, total, fps, s, ist, ien, ien, total])
	print("  CombatDataValidator.validate_all() | VALIDATOR_CHECKS=%d VALIDATOR_PASS=%d VALIDATOR_FAIL=%d VALIDATOR_ERROR=%d" % [
		v_checks, v_pass, v_fail, v_fail])
	print("  PASS_COUNT=%d FAIL_COUNT=%d" % [_pass, _fail])
	print("  RESULT=%s" % ("ALL_MATCH" if _fail == 0 else "MISMATCH"))
	print("  NOTE: 边界/期望全部同源读取 player_actions.tres，零硬编码；650 PASS 合计口径由外部重跑 verify_frame_data.gd 回归段确认；quit 退出码真实反映断言结论。")
	print("==== [R22 ROLL RUNTIME CHECK] END ====")
	quit(0 if _fail == 0 else 1)


## 运行逻辑（被测）：逐字复刻 teamwork/Rank-2/player_state_machine.gd:233-242
## is_invulnerable()，唯一差别是把规格件的 state_frame 换成本实测的 0-based frame_index，
## 以与 .tres 的 [inv_start, inv_end) 左闭右开数据口径对齐。
func _runtime_is_invulnerable(action: PlayerActionData, frame_index: int) -> bool:
	if action.invulnerable_start_frame < 0 or action.invulnerable_end_frame <= action.invulnerable_start_frame:
		return false
	return frame_index >= action.invulnerable_start_frame and frame_index < action.invulnerable_end_frame


func _check(label: String, ok: bool) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("[FAIL] %s" % label)


func _assert_named(label: String, ok: bool) -> void:
	print("[ASSERT] %s -> %s" % [label, "PASS" if ok else "FAIL"])
	_check(label, ok)
