extends SceneTree
## R22 · 15 秒实机录屏驱动脚本（godogen 核心交付 · 派单 cmd-20261109-124640-188-A4）
## 真跑（R22 等价确定性方式，改动点见 DONE-R22.md / CAPTURE-REPORT.md）：
##   D:/Godot/Godot_v4.7.2-stable_win64.exe \
##     --path F:/Game/aierdengfahuan/godot \
##     --write-movie F:/Game/aierdengfahuan/capture/r22_demo.png \
##     --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd \
##     res://scenes/courtyard.tscn
##
## 改动点（相对任务单原命令，全部经真跑对照，如实登记）：
##   ① 原命令未带位置参数主场景，由脚本 instantiate()+add_child() 加载 courtyard.tscn。
##      实测该组合下 Movie Maker 只渲染 2D CanvasLayer（HUD/FX），SubViewport 的 3D 世界
##      （砖地 / 像素角色）不进入录制，画面主体缺失。故命令末尾补位置参数主场景，
##      改由引擎正常加载 courtyard.tscn（单实例、3D 渲染完整），脚本只复用该实例并驱动行为。
##   ② 任务要求「_initialize() 里预置相机」。实测 --script 模式下脚本对 Camera3D 写任何属性
##      （position / rotation / fov / current，含 call_deferred 后写）都会破坏 SubViewport 的
##      3D 相机注册，导致 3D 主体消失（对照：完全不写相机=正常；写 current、写 transform、
##      deferred 写=均丢失）。故相机预置由 courtyard.tscn 静态节点承担，脚本在 _initialize()
##      里读取并确认其状态、不写入；画面主体完整。
##   仍为 450 帧 / 真实完整画面 / 跨段行为推进 / 确定性。
##
## 严格按技能 engines/godot-gdscript.md §Capture：
##   ① extends SceneTree；_initialize() 引用引擎加载的 courtyard.tscn 单实例、确认静态相机预置；
##      autoload 只经 root.get_node() 取，不直接引用单例名；
##   ② 经 SceneTree.process_frame 信号逐帧驱动跨段行为，450 帧全程无单帧循环 / 无死时间：
##      画质档位切换（quality_settings.set_quality + apply，连带 fx_profile desktop/mobile 切档）、
##      set_pose 切帧（角色精灵姿态，每 15 帧一次）、HUD flag 变化（WorldState.set_flag →
##      flag_changed → HUD 事件驱动增量刷新标题 / 点亮态）、hd2d_fx 既有 _process 逐帧重绘
##      （光尘上飘 / 倒影波纹，desktop 段）；
##   ③ 所有行为只调用工程既有公共接口，零改动冻结源件。
##
## 目录所有权：本文件是 Rank-4 本轮唯一新增的工程内文件；不写 project.godot /
##   courtyard.tscn / quality_settings.* / hud.gd / hd2d_fx.* / verify_frame_data.gd。
## 零外部素材 / 零付费 / 零插件 · 中文 UTF-8 · Godot 4.7.2 全静态类型标注。

const TOTAL_FRAMES: int = 450

# courtyard.tscn 内节点路径（只读引用，不改场景）
const RIG_PATH: String = "SubViewportContainer/SubViewport/Player/Hybrid2D3DAnimatedSprite"
const QUALITY_PATH: String = "QualitySettings"
const CAMERA_PATH: String = "SubViewportContainer/SubViewport/Camera3D"

# 冻结 pose 子集（与 HybridSpriteRig.FROZEN_POSES / player_spriteframes.tres 对齐）
const POSES: Array = [
	"idle", "walk", "run", "roll",
	"attack_light", "attack_heavy", "hitstun", "death"
]
const POSE_INTERVAL: int = 15

# 赐福 flag（三段式，全部符合 WorldState.FLAG_KEY_REGEX；id 取自 grace_network.tres）
const FLAG_LAST_GRACE: String = "grace.network.last_grace_id"
const LIT_GATEFRONT: String = "grace.limgrave_gatefront.lit"
const LIT_CHAPEL: String = "grace.limgrave_chapel.lit"
const LIT_SHORE: String = "grace.weeping_shore.lit"
const LIT_WELL: String = "grace.siofra_well.lit"

var _courtyard: Node = null
var _rig: Node = null
var _quality: Node = null
var _camera: Camera3D = null
var _world_state: Node = null
var _frame: int = 0
var _last_segment: int = -1


func _initialize() -> void:
	print("==== [R22 presentation] START | cmd-20261109-124640-188-A4 [ROUND=R22] Rank-4 ====")
	# 场景由命令行位置参数 res://scenes/courtyard.tscn 交引擎正常加载（单实例，保证 3D 世界渲染）；
	# 脚本不再 instantiate()+add_child()，杜绝双实例与 SubViewport 3D 渲染丢失。
	_courtyard = root.get_node_or_null("Courtyard")
	if _courtyard == null:
		push_error("[R22] 未找到引擎加载的 Courtyard 主场景实例")
		quit(1)
		return
	print("[R22] REUSE 引擎加载的 Courtyard 单实例 | name=%s children=%d" % [
			str(_courtyard.name), _courtyard.get_child_count()])

	# ① 相机预置：由 courtyard.tscn 静态节点承担；脚本在 _initialize() 读取确认、不写入。
	_camera = _courtyard.get_node_or_null(CAMERA_PATH) as Camera3D
	if _camera != null:
		print("[R22] CAMERA preset（courtyard.tscn 静态）pos=%s rot=%s fov=%.1f current=%s | 脚本只读确认，不写入" % [
				str(_camera.position), str(_camera.rotation_degrees), _camera.fov, str(_camera.current)])
	else:
		push_warning("[R22] 未找到 Camera3D，沿用场景静态相机")

	# ② 缓存行为节点（只读引用）
	_rig = _courtyard.get_node_or_null(RIG_PATH) as Node
	_quality = _courtyard.get_node_or_null(QUALITY_PATH) as Node
	print("[R22] REFS rig=%s quality=%s" % [str(_rig != null), str(_quality != null)])

	# ③ autoload：SceneTree 脚本不能直呼单例名，一律经 root.get_node()
	if root.has_node("WorldState"):
		_world_state = root.get_node("WorldState")
		print("[R22] AUTOLOAD root.get_node(\"WorldState\") -> %s" % str(_world_state.get_class()))
	else:
		push_warning("[R22] /root/WorldState 未就绪，HUD flag 段将跳过")

	# ④ 逐帧驱动：process_frame 每帧一次，帧号与 --quit-after 450 对齐；退出交给 --quit-after。
	process_frame.connect(Callable(self, "_on_frame"))
	print("[R22] process_frame 已连接 | TOTAL_FRAMES=%d @--fixed-fps 30 (15s)" % TOTAL_FRAMES)


func _on_frame() -> void:
	if _frame >= TOTAL_FRAMES:
		return
	_drive_segment(_frame)
	_drive_pose(_frame)
	_drive_hud_flags(_frame)
	_frame += 1
	if _frame == TOTAL_FRAMES:
		print("==== [R22 presentation] 时间线完成 frame=%d（--quit-after 450 负责退出）====" % _frame)


## 段 A(0-149 desktop/medium) → 段 B(150-299 mobile/low) → 段 C(300-449 desktop/high)
func _drive_segment(f: int) -> void:
	var segment: int = 0
	if f >= 300:
		segment = 2
	elif f >= 150:
		segment = 1
	if segment == _last_segment:
		return
	_last_segment = segment
	match segment:
		0:
			print("[R22][SEG-A] frame=%d 桌面档 medium / fx_profile=desktop 四项全开（_ready 默认态）" % f)
		1:
			_set_quality("low")
			print("[R22][SEG-B] frame=%d 画质档位切换 medium->low | shrink=3 / fx_profile=mobile 四项全关" % f)
		2:
			_set_quality("high")
			print("[R22][SEG-C] frame=%d 画质档位切换 low->high | shrink=1 / fx_profile=desktop 四项全开" % f)


func _set_quality(preset: String) -> void:
	if _quality == null or not is_instance_valid(_quality):
		push_warning("[R22] QualitySettings 节点不可用，跳过档位切换")
		return
	if _quality.has_method("set_quality"):
		_quality.call("set_quality", preset)
	if _quality.has_method("apply"):
		_quality.call("apply")
	var readback: String = "n/a"
	if _quality.has_method("get_quality_preset"):
		readback = str(_quality.call("get_quality_preset"))
	print("[R22] set_quality(%s)+apply() done | get_quality_preset()=%s" % [preset, readback])


## 每 15 帧切一次 pose，frame_index 逐次递增（HybridSpriteRig 内部 clamp；接口真实调用）
func _drive_pose(f: int) -> void:
	if f % POSE_INTERVAL != 0:
		return
	var step: int = f / POSE_INTERVAL
	var idx: int = step % POSES.size()
	var pose: String = String(POSES[idx])
	var frame_index: int = step % 4
	if _rig == null or not is_instance_valid(_rig) or not _rig.has_method("set_pose"):
		return
	_rig.call("set_pose", pose, frame_index)
	var cur_pose: String = "?"
	if _rig.has_method("get_current_pose"):
		cur_pose = str(_rig.call("get_current_pose"))
	print("[R22][POSE] frame=%d set_pose(%s, %d) -> get_current_pose()=%s" % [
			f, pose, frame_index, cur_pose])


## HUD flag 变化：WorldState.set_flag → flag_changed → HUD.refresh_label（事件驱动，不轮询）
func _drive_hud_flags(f: int) -> void:
	match f:
		40:
			_set_flag(FLAG_LAST_GRACE, "grace_limgrave_gatefront")
			_set_flag(LIT_GATEFRONT, true)
			print("[R22][HUD] frame=%d 标题→「赐福 · 关卡前」点亮(金)" % f)
		190:
			_set_flag(FLAG_LAST_GRACE, "grace_limgrave_chapel")
			_set_flag(LIT_CHAPEL, false)
			print("[R22][HUD] frame=%d 标题→「赐福 · 巡礼教堂」未点亮(暗)" % f)
		250:
			_set_flag(LIT_CHAPEL, true)
			print("[R22][HUD] frame=%d 同一赐福点亮(金) flag 再变化" % f)
		340:
			_set_flag(FLAG_LAST_GRACE, "grace_weeping_shore")
			_set_flag(LIT_SHORE, true)
			print("[R22][HUD] frame=%d 标题→「赐福 · 啜泣海岸」点亮(金)" % f)
		420:
			_set_flag(FLAG_LAST_GRACE, "grace_siofra_well")
			_set_flag(LIT_WELL, false)
			print("[R22][HUD] frame=%d 标题→「赐福 · 希芙拉河井底」未点亮(暗)" % f)


func _set_flag(key: String, value: Variant) -> void:
	if _world_state == null or not is_instance_valid(_world_state):
		return
	if _world_state.has_method("set_flag"):
		_world_state.call("set_flag", key, value)
