extends SceneTree
## R15 / cmd-20261109-083628-782-A2 · Rank-2 pose 名称一致性「真跑比对」脚本
##
## 项1：player_spriteframes.tres 的 8 个动画名 vs HybridSpriteRig.FROZEN_POSES（常量）
## 项2：boss_spriteframes.tres 的 3 个动画名 vs boss_import.json 的
##      pose_names + pose_prefix / phase_hint
## 项3：HybridSpriteRig.POSE_PREFIXES 是否 == ["p1_","p2_"]
## 项4：三段门禁 --import / --check-only --script verify_pose_names.gd / --quit
##      （由外部命令执行，EXIT 与实际 stdout 见 DONE-R15.md；本脚本不自检门禁本身）
##
## 运行（真跑）：godot --headless --path godot --script res://scripts/verify_pose_names.gd
## 静态（门禁）：godot --headless --path godot --check-only --script res://scripts/verify_pose_names.gd
##
## 说明：HybridSpriteRig 为工程内 class_name 全局类，常量访问前须先 --import 刷新全局类缓存。
## 所有名称统一转 String 后再比较，避免 StringName / String 跨 Variant 类型比较歧义。

const PLAYER_TRES := "res://assets/generated/chars/player_spriteframes.tres"
const BOSS_TRES   := "res://assets/generated/boss/boss_spriteframes.tres"
const BOSS_JSON   := "res://assets/generated/boss/boss_import.json"

var _frozen: Array = []         # HybridSpriteRig.FROZEN_POSES，转 String
var _prefixes: Array = []       # HybridSpriteRig.POSE_PREFIXES，转 String
var _player: Array = []         # player_spriteframes.tres 动画名，转 String
var _boss: Array = []           # boss_spriteframes.tres 动画名，转 String
var _pose_names: Array = []     # boss_import.json -> pose_names
var _prefix_values: Array = []  # boss_import.json -> pose_prefix 的值集合
var _hint_keys: Array = []      # boss_import.json -> phase_hint 的键集合
var _pass_count: int = 0
var _fail_count: int = 0


func _initialize() -> void:
	print("==== [R15 POSE NAMES VERIFY] START ====")
	_collect()
	_check_1()
	_check_2()
	_check_3()
	print("==== [R15 POSE NAMES VERIFY] PASS_COUNT=%d FAIL_COUNT=%d ====" % [_pass_count, _fail_count])
	print("==== [R15 POSE NAMES VERIFY] RESULT=%s ====" % ("PASS" if _fail_count == 0 else "FAIL"))
	quit(0 if _fail_count == 0 else 1)


# ---------------------------------------------------------------- 数据源（真读，不臆测）
func _collect() -> void:
	# ① 两个冻结常量（全局类 HybridSpriteRig）
	_frozen = _to_string_array(HybridSpriteRig.FROZEN_POSES)
	_prefixes = _to_string_array(HybridSpriteRig.POSE_PREFIXES)
	print("[源] HybridSpriteRig.FROZEN_POSES (常量) | count=%d | values=%s" % [_frozen.size(), str(_frozen)])
	print("[源] HybridSpriteRig.POSE_PREFIXES (常量) | count=%d | values=%s" % [_prefixes.size(), str(_prefixes)])

	# ② player_spriteframes.tres
	var p_res: Resource = load(PLAYER_TRES)
	var p_sf: SpriteFrames = p_res as SpriteFrames
	if p_sf == null:
		_fail("[源] load(%s) 返回 null 或非 SpriteFrames" % PLAYER_TRES)
	else:
		_player = _to_string_array(Array(p_sf.get_animation_names()))
		print("[源] player_spriteframes.tres | animation_count=%d | names=%s" % [_player.size(), str(_player)])

	# ③ boss_spriteframes.tres
	var b_res: Resource = load(BOSS_TRES)
	var b_sf: SpriteFrames = b_res as SpriteFrames
	if b_sf == null:
		_fail("[源] load(%s) 返回 null 或非 SpriteFrames" % BOSS_TRES)
	else:
		_boss = _to_string_array(Array(b_sf.get_animation_names()))
		print("[源] boss_spriteframes.tres | animation_count=%d | names=%s" % [_boss.size(), str(_boss)])

	# ④ boss_import.json
	var fa: FileAccess = FileAccess.open(BOSS_JSON, FileAccess.READ)
	if fa == null:
		_fail("[源] FileAccess.open(%s) 失败" % BOSS_JSON)
		return
	var text: String = fa.get_as_text()
	fa.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		_fail("[源] boss_import.json JSON.parse_string 未返回 Dictionary")
		return
	var data: Dictionary = parsed
	_pose_names = _to_string_array(data.get("pose_names", []))
	var pp: Variant = data.get("pose_prefix", {})
	var ph: Variant = data.get("phase_hint", {})
	if pp is Dictionary:
		_prefix_values = _to_string_array((pp as Dictionary).values())
	if ph is Dictionary:
		_hint_keys = _to_string_array((ph as Dictionary).keys())
	print("[源] boss_import.json | pose_names=%s" % str(_pose_names))
	print("[源] boss_import.json | pose_prefix.values=%s" % str(_prefix_values))
	print("[源] boss_import.json | phase_hint.keys=%s" % str(_hint_keys))


# ---------------------------------------------------------------- 项1
func _check_1() -> void:
	print("---- 项1: player_spriteframes.tres 8 个动画名 vs HybridSpriteRig.FROZEN_POSES (常量) ----")
	_assert(_player.size() == 8, "[1.1] player 动画数 == 8（实际 %d）" % _player.size())

	# 脚本注释口径：FROZEN_POSES = 基础 8 + Boss 3；前 8 项为基础动作，末 3 项为 Boss 招式。
	var base8: Array = []
	var boss3: Array = []
	for i in range(_frozen.size()):
		if i < 8:
			base8.append(_frozen[i])
		else:
			boss3.append(_frozen[i])
	print("[1] FROZEN_POSES.count=%d | 基础 8=%s | Boss 3=%s" % [_frozen.size(), str(base8), str(boss3)])

	# 逐项：player 每个动画名都必须被冻结表接受（在 FROZEN_POSES 内）
	for i in range(_player.size()):
		var nm: String = String(_player[i])
		_assert(_frozen.has(nm), "[1.2.%d] player 动画名 '%s' 在 FROZEN_POSES 内（表内接受）" % [i + 1, nm])

	# 集合等价（顺序无关）：player 8 名 == 冻结表基础 8 名
	_assert(_same_set(_player, base8), "[1.3] player 8 名集合 == FROZEN_POSES 基础 8 集合（player=%s / base8=%s）" % [str(_player), str(base8)])
	_assert(_no_dup(_player), "[1.4] player 8 名无重复")


# ---------------------------------------------------------------- 项2
func _check_2() -> void:
	print("---- 项2: boss_spriteframes.tres 3 个动画名 vs boss_import.json 的 pose_names + pose_prefix / phase_hint ----")
	_assert(_boss.size() == 3, "[2.1] boss 动画数 == 3（实际 %d）" % _boss.size())
	_assert(_pose_names.size() == 3, "[2.2] pose_names 数量 == 3（实际 %d）" % _pose_names.size())
	_assert(_hint_keys.size() == 3, "[2.3] phase_hint 键数量 == 3（实际 %d）" % _hint_keys.size())
	_assert(_same_set(_boss, _hint_keys), "[2.4] boss 3 动画名集合 == phase_hint 键集合（boss=%s / hint=%s）" % [str(_boss), str(_hint_keys)])

	for i in range(_boss.size()):
		var full: String = String(_boss[i])
		# 用冻结常量 POSE_PREFIXES 拆前缀，再用 json 的 pose_prefix 值集合校验合法性
		var matched_prefix: String = ""
		for pfx in _prefixes:
			if full.begins_with(String(pfx)):
				matched_prefix = String(pfx)
				break
		var base: String = full.substr(matched_prefix.length()) if matched_prefix != "" else full
		print("[2.5.%d] 动画名 '%s' | 前缀='%s' | 去前缀='%s'" % [i + 1, full, matched_prefix, base])
		_assert(matched_prefix != "" and _prefix_values.has(matched_prefix),
			"[2.5.%d] '%s' 的前缀属于 pose_prefix 值集合 %s" % [i + 1, full, str(_prefix_values)])
		_assert(_pose_names.has(base),
			"[2.5.%d] '%s' 去前缀后 '%s' 属于 pose_names %s" % [i + 1, full, base, str(_pose_names)])
		_assert(_hint_keys.has(full),
			"[2.5.%d] '%s' 属于 phase_hint 键集合 %s" % [i + 1, full, str(_hint_keys)])

	# 交叉佐证：pose_names 的 Boss 3 基础名亦应在冻结表内（与项1 的 FROZEN_POSES 呼应）
	for i in range(_pose_names.size()):
		var pn: String = String(_pose_names[i])
		_assert(_frozen.has(pn), "[2.6.%d] pose_names '%s' 亦在 FROZEN_POSES 冻结表内（Boss 3 名口径）" % [i + 1, pn])


# ---------------------------------------------------------------- 项3
func _check_3() -> void:
	print("---- 项3: HybridSpriteRig.POSE_PREFIXES 是否 == [\"p1_\",\"p2_\"] ----")
	var expected: Array = ["p1_", "p2_"]
	for i in range(expected.size()):
		var got: String = String(_prefixes[i]) if i < _prefixes.size() else "<缺失>"
		_assert(i < _prefixes.size() and got == String(expected[i]),
			"[3.%d] POSE_PREFIXES[%d] == '%s'（实际 '%s'）" % [i + 1, i, expected[i], got])
	_assert(_prefixes == expected, "[3.3] POSE_PREFIXES 整体 == %s（实际 %s）" % [str(expected), str(_prefixes)])
	_assert(_same_set(_prefixes, _prefix_values),
		"[3.4] (交叉) 常量 POSE_PREFIXES 集合 == boss_import.json pose_prefix 值集合（常量=%s / json=%s）" % [str(_prefixes), str(_prefix_values)])


# ---------------------------------------------------------------- 工具
func _to_string_array(src: Variant) -> Array:
	var out: Array = []
	if src is Array:
		for item in src:
			out.append(String(item))
	elif src is PackedStringArray:
		for item in src:
			out.append(String(item))
	return out


func _same_set(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for x in a:
		if not b.has(x):
			return false
	return true


func _no_dup(a: Array) -> bool:
	for i in range(a.size()):
		for j in range(i + 1, a.size()):
			if a[i] == a[j]:
				return false
	return true


func _assert(condition: bool, message: String) -> void:
	if condition:
		_pass_count += 1
		print("  [PASS] %s" % message)
	else:
		_fail(message)


func _fail(message: String) -> void:
	_fail_count += 1
	print("  [FAIL] %s" % message)
