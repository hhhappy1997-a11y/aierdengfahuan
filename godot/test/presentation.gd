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
##
## R26 v0.4.0 改动（Rank-4 本轮独占本文件）：
##   ① 逐帧动作演示：_drive_pose 改为每 5 帧推进一次子帧、3 子帧(0/1/2)轮转、
##      每 15 帧换 pose，使两份 SpriteFrames 每动画 3 帧在 450 帧录屏中真实可见；
##      frame_index 与 HybridSpriteRig._clamp_frame_index(帧数=3) 对齐，无越界。
##   ② 三波试炼 HUD：追加 _drive_wave_hud（防御性），三波段 0/150/300 与三段画质切换对齐；
##      只调用 WaveTrialDirector 既有公开接口 start_trial() / debug_advance(sec) /
##      on_encounter_finished(true) / get_snapshot()（has_method 守卫），确定性推进 1→2→3 波，
##      绝不写 Label.text / 不伪造波次数值（HUD 由导演层自身 _refresh_hud() 刷新）；
##      若 Rank-1 尚未落盘波次导演/HUD 节点，则如实打印跳过、不冒充已驱动。
##   ③ 三段画质切换(_drive_segment)、赐福 HUD flag(_drive_hud_flags)、
##      战斗 HUD 注入(_drive_combat_v030) 逐字保留，保证三套既有 HUD 全程可读。
##   [PLACEHOLDER] SUBFRAME_INTERVAL=5 为演示节奏，待试玩校准（rationale：
##      450 帧 / 5 = 90 步，90 / 3 = 30 个 pose 周期，8 pose 循环约 3.75 轮，每 pose 恰好 3 子帧）。

## R28 v0.6.0 改动（Rank-4 本轮独占本文件 · 派单 cmd-20261111-095602-831-A4）：
##   ① 真实输入事件注入：新增 _drive_real_input / _inject_key，经 Input.parse_input_event
##      注入 InputEventKey（J=light_attack / Space=roll / E=interact / 1=购买），由引擎输入系统
##      分发到既有 _unhandled_input 路由；动作帧 HUD 由 EncounterDirector._request_action→
##      _update_hud 真实推进、兑换面板由 hud._toggle_shop 真实展开、购买经 hud.purchase_upgrade。
##      绝不写 Label.text、不调 debug_* 伪造数值、不直接改 HUD 文本。
##   ② 赐福标题点亮：_drive_hud_flags 时间线重排，让首/中/尾三帧采样均处「点亮(金)」态，
##      仍全部经 WorldState.set_flag → flag_changed → HUD.refresh_label → apply_lit_state(GOLD)。
##   ③ tutorial 接口：Rank-1 承诺的 tutorial_director.is_tutorial_active()/force_complete()
##      防御性探测；并发时序下未落盘则如实降级为「直接注入按键 + 登记接口缺失」，
##      不伪造画面、不谎称教学闭环已证明。
##   [PLACEHOLDER] ACTION_INTERVAL=6 为动作注入节奏，待试玩校准（rationale：
##      450 帧 / 6 = 75 次注入，J/Space 交替，动作帧窗口约 6 渲染帧，使动作帧 HUD 全片不恒 idle 0/0；
##      f=0 J / f=6 Space / f=20 E 严格按教学三步顺序，让教学真实完成并衔接到第 1 波）。
##
## R29 [ROUND=R29] 首帧动作帧 1 帧延迟修复（Rank-1 本轮独占本文件）：
##   改前真跑实证：frame=0 的 [R28][EVIDENCE] 显示 StatusLabel 仍为「动作 idle 0/0」——
##   _on_frame(f=0) 内经 Input.parse_input_event 注入的 J 要等下一帧输入 flush 才分发，
##   故 Movie Maker 抓取的录屏首帧动作帧恒为 idle 0/0（1 帧延迟）。
##   修法：在 _initialize() 内（第 0 帧之前）预热注入一次真实 J 事件，令首个渲染帧前
##   输入路由已激活、EncounterDirector._request_action("attack_light") 已推进动作帧 HUD。
##   仍严格走真实 Input.parse_input_event 路由，绝不写 Label.text / 不调 debug_* 伪造数值；
##   _drive_real_input 的 f=0 J / f=6 Space / f=20 E 教学三步时间线逐字保留，
##   预热 J 只额外消费一次 light_attack（教学第 2 步期待 Space，重复 J 不推进教学、不破坏闭环）。
##   [PLACEHOLDER] 预热键位 J 与既有教学第一步一致，待试玩校准（rationale：不引入新动作）。
##
## R30 [ROUND=R30] 赐福图鉴 Tab 演示注入（Rank-1 本轮独占本文件）：
##   在 15 秒 450 帧序列里【注入一次】KEY_TAB（CODEX_TAB_FRAME=210），经既有
##   _inject_key() → Input.parse_input_event(InputEventKey) 真实输入路由交引擎分发到
##   CodexDirector._unhandled_input，打开赐福图鉴面板，让录屏证明图鉴可打开。
##   Tab(KEY_TAB=4194306) 不与教学 T 键 / interact(E) / 数字键冲突；
##   绝不写任何 Label.text、不调 debug_* 伪造数值、不改四套 HUD 文本。
##   只读回读：_log_input_evidence 在关键帧读 CodexDirector.is_panel_open() 留证（不写）。
##   [PLACEHOLDER] CODEX_TAB_FRAME=210 为演示节奏（rationale：留 ≥15 帧输入 flush 余量，
##   使 f=225 / f=449 的 EVIDENCE 稳定读回 panel_open=true，避开 R29 实证的 1 帧输入延迟）。

## R33 [ROUND=R33] · 新玩法进实机演示序列（Rank-1 本轮独占本文件 · 派单 cmd-20261112-084053-303-A1）：
##   总指挥回看 capture/v100_final.mp4 目视结论：15 秒录屏里完全看不到 R32 新增玩法
##   （Boss 韧性条 / 处决窗口读秒 / 赐福抉择三选一卡片）—— R32 只落了纯逻辑与单元验证，
##   HUD 侧只有 get_stagger_hud_view() / get_boon_draft_view() 字典快照，
##   【没有任何真实可见节点】，演示序列也没有触发链。
##   本轮在 presentation.gd 里补：
##    ① 运行时挂载独立 CanvasLayer 可见层（ProgressBar 韧性条 + 读秒/F 反馈 Label +
##       三选一卡片 Label）；文本/数值全部读 HUD 公开快照，不写既有 HUD 的 Label.text、
##       不调 debug_*、不伪造数值；位置取右上空白区，避开 6 套 HUD / 玩家 / Boss。
##    ② 绑定 Rank-2 真实 StaggerService / BoonDraftService（CACHE_MODE_IGNORE 回读），
##       订阅 execution_performed / boon_draft_selected 真实信号回读。
##    ③ F 键处决 / 数字键 2 选择 / Tab 关闭图鉴 均走既有 _inject_key() →
##       Input.parse_input_event(InputEventKey) 真实输入路由（真按键纪律）。
##    ④ 【演示驱动，非玩家真实操作可达】演示序列里没有真实「玩家命中削韧」与「真实清波」
##       事件，故开窗用显式 StaggerService.apply_hit(100.0)、卡片用显式 HUD.on_wave_cleared()
##       构造演示状态，每帧 tick/poll 推进读秒；此二者在 DONE-R33.md 如实标注，
##       仍缺的运行时触发链列为待总指挥裁决项，不冒充已完整接线。
##    ⑤ Tab 在 f=240 再注入一次关闭图鉴，实证 R33「图鉴开→兑换隐藏 / 关→恢复」互斥。
##    ⑥ 信号 connect 在 450 帧时间线末尾显式 disconnect（释放路径兜底）。
##   [PLACEHOLDER] R33 帧点为演示节奏，待试玩校准。

const TOTAL_FRAMES: int = 450

# courtyard.tscn 内节点路径（只读引用，不改场景）
const RIG_PATH: String = "SubViewportContainer/SubViewport/Player/Hybrid2D3DAnimatedSprite"
const QUALITY_PATH: String = "QualitySettings"
const CAMERA_PATH: String = "SubViewportContainer/SubViewport/Camera3D"
# R27 v0.5.0 · 三波空间节奏：视差远景节点（hd2d_parallax.gd，Rank-4 独占）只读引用
const PARALLAX_PATH: String = "SubViewportContainer/SubViewport/ParallaxBackdropLayer/ParallaxBackdrop"

# 冻结 pose 子集（与 HybridSpriteRig.FROZEN_POSES / player_spriteframes.tres 对齐）
const POSES: Array = [
	"idle", "walk", "run", "roll",
	"attack_light", "attack_heavy", "hitstun", "death"
]
const POSE_INTERVAL: int = 15
# R26 [PLACEHOLDER] 逐帧动作演示节奏：每 5 帧推进一个子帧，3 子帧轮转（待试玩校准）
const SUBFRAME_INTERVAL: int = 5

# ---- R28 v0.6.0 · 真实输入事件注入（project.godot [input] physical_keycode 对齐）----
const KEY_J: int = 74            # light_attack（J）
const KEY_SPACE: int = 32        # roll（Space）
const KEY_E: int = 69            # interact（E）
const KEY_1: int = 49            # 兑换选项 1（hud.purchase_upgrade(0)）
const KEY_TAB_CODE: int = 4194306 # KEY_TAB（R30，赐福图鉴开关；不与教学 T 键 84 冲突）
const CODEX_TAB_FRAME: int = 210  # [PLACEHOLDER] R30 注入一次 Tab 的帧，待试玩校准
const ACTION_INTERVAL: int = 6   # [PLACEHOLDER] 动作注入周期（帧），待试玩校准
const E_OPEN_FRAME: int = 20     # 教学第 3 步：注入 E（J→Space→E 顺序），同时打开兑换面板并保持全片展开
const BUY_FRAME: int = 170       # 注入数字键 1 购买一项（教学奖励 + 波次结算已累积赐福点数）
const TUTORIAL_GUARD_FRAME: int = 40  # 教学状态兜底检查帧（避免三波永久冻结 / 教学与波次双驱动）

# ---- R33 [ROUND=R33] · 新玩法演示（真实按键 + 演示驱动状态构造）----
const KEY_F_CODE: int = 70             # KEY_F（处决；HUD._process_r32_keys → request_execution）
const KEY_2_CODE: int = 50             # 数字键 2（赐福抉择选择；boon_draft.select(1)）
const STAGGER_SVC_PATH: String = "res://scripts/combat/stagger_service.gd"
const STAGGER_CFG_PATH: String = "res://data/combat/stagger_rules.tres"
const BOON_SVC_PATH: String = "res://scripts/combat/boon_draft_service.gd"
const BOON_CFG_PATH: String = "res://data/rpg/boon_draft.tres"
const R33_LAYER_NAME: String = "R33DemoMechanismsLayer"
const R33_LAYER_INDEX: int = 48        # 高于 CodexPanelLayer=46 / 兑换层=45 / QualitySettings=40
# 可见层位置：右上空白区 x∈[900,1276] / y∈[190,352]，与 quality(y<180)、shop(y>358)、
#   Boss+中央角色(x<880)、codex(x<380)、底部条(y>660) 均无交集，不遮角色、不与既有 HUD 叠压。
const R33_RECT_LEFT: float = 900.0
const R33_RECT_TOP: float = 190.0
const R33_RECT_RIGHT: float = 1276.0
const R33_RECT_BOTTOM: float = 352.0
# [PLACEHOLDER] 演示节奏：韧性/处决段 96~145、Tab 关闭 240、抉择段 330~399。
const STAGGER_BIND_FRAME: int = 96
const STAGGER_EXEC_FRAME: int = 126
const STAGGER_END_FRAME: int = 146
const CODEX_TAB_CLOSE_FRAME: int = 240
const BOON_BIND_FRAME: int = 330
const BOON_SELECT_FRAME: int = 352
const BOON_END_FRAME: int = 400

# R28 既有输入路由节点路径（只读引用）
const HUD_PATH: String = "SubViewportContainer/SubViewport/FXLayer/Hud"
const ENCOUNTER_PATH: String = "EncounterRoot"
const STATUS_LABEL_PATH: String = "HUD/StatusLabel"

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
# R26 三波试炼导演（防御性解析；Rank-1 未落盘则保持 null，不伪造）
var _wave: Node = null
var _wave_ready: bool = false
# R27 三波空间节奏画面驱动节点（防御性解析）
var _parallax: Node = null
# ---- R28 v0.6.0 真实输入注入运行期引用（防御性解析，未落盘则判空降级、不崩）----
var _hud: Node = null
var _encounter: Node = null
var _status_label: Label = null
# Rank-1 tutorial_director 接口（并发时序下可能未落盘；如实登记，不假设存在）
var _tutorial_director: Node = null
var _tutorial_api_available: bool = false
# ---- R33 新玩法演示运行期引用（防御性解析 / 判空降级，不假设服务已落盘）----
var _r33_layer: CanvasLayer = null
var _r33_poise_bar: ProgressBar = null
var _r33_stagger_label: Label = null
var _r33_draft_label: Label = null
var _r33_stagger_svc: Object = null
var _r33_boon_svc: Object = null
var _r33_exec_text: String = ""
var _r33_select_text: String = ""
var _r33_exec_count: int = 0
var _r33_select_count: int = 0
var _r33_signals_connected: bool = false


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

	# ④ R26 三波试炼导演（防御性解析；Rank-1 独占 courtyard.tscn，未落盘则保持 null，不伪造）
	_wave = _find_wave_director()
	_wave_ready = _wave != null
	if _wave_ready:
		print("[R26][WAVE] 找到波次导演 name=%s class=%s" % [str(_wave.name), str(_wave.get_class())])
	else:
		push_warning("[R26][WAVE] 波次导演/HUD 节点未落盘（Rank-1 独占），三波 HUD 驱动将如实跳过")

	# ④b R27 三波空间节奏画面节点（ParallaxBackdrop，hd2d_parallax.gd 既有 set_wave_index 接口）
	_parallax = _courtyard.get_node_or_null(PARALLAX_PATH) as Node
	if _parallax != null and _parallax.has_method("set_wave_index"):
		print("[R27][SPACE] 找到 ParallaxBackdrop name=%s class=%s（三波空间变化可驱动）" % [
				str(_parallax.name), str(_parallax.get_class())])
	else:
		push_warning("[R27][SPACE] ParallaxBackdrop / set_wave_index 不可用，三波空间变化将如实跳过")

	# ④c R28 v0.6.0：真实输入路由节点（只读引用）+ Rank-1 tutorial 接口防御性探测
	_hud = _courtyard.get_node_or_null(HUD_PATH) as Node
	_encounter = _courtyard.get_node_or_null(ENCOUNTER_PATH) as Node
	if _encounter != null:
		_status_label = _encounter.get_node_or_null(STATUS_LABEL_PATH) as Label
	print("[R28][REFS] hud=%s encounter=%s status_label=%s" % [
			str(_hud != null), str(_encounter != null), str(_status_label != null)])
	_resolve_tutorial_api()

	# ⑤ 逐帧驱动：process_frame 每帧一次，帧号与 --quit-after 450 对齐；退出交给 --quit-after。
	process_frame.connect(Callable(self, "_on_frame"))
	print("[R22] process_frame 已连接 | TOTAL_FRAMES=%d @--fixed-fps 30 (15s)" % TOTAL_FRAMES)

	# ⑥ R29：首帧动作帧 1 帧延迟修复 —— 第 0 帧之前预热一次真实输入路由（详见头部 R29 注释）。
	_prewarm_action_input()
	# ⑦ R33：新玩法演示可见层 + Rank-2 真实服务绑定 + 信号回读（演示驱动，见 DONE-R33.md）。
	_build_r33_overlay()
	_bind_r33_services()


## R29 · _initialize 阶段（第 0 帧之前）预热注入一次真实 J 键，消除录屏首帧 idle 0/0 延迟。
## 仍经既有 _inject_key() → Input.parse_input_event(InputEventKey) 真实路由，不碰 HUD 文本 / 数值。
func _prewarm_action_input() -> void:
	_inject_key(KEY_J)
	print("[R29][INPUT] _initialize 预热注入真实按键 light_attack(J) -> Input.parse_input_event(InputEventKey)（提前到第 0 帧之前，消除首帧 idle 0/0 延迟）")


func _on_frame() -> void:
	if _frame >= TOTAL_FRAMES:
		return
	_drive_segment(_frame)
	_drive_pose(_frame)
	_drive_hud_flags(_frame)
	_drive_combat_v030(_frame)
	_drive_wave_hud(_frame)
	_drive_wave_space(_frame)
	_drive_growth_hud(_frame)
	_drive_real_input(_frame)
	_drive_r33_mechanisms(_frame)
	_frame += 1
	if _frame == TOTAL_FRAMES:
		_r33_release_signals()
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


## R26 v0.4.0 逐帧动作演示：每 SUBFRAME_INTERVAL(5) 帧推进一次子帧，
## 3 子帧(0/1/2)轮转、每 15 帧换 pose；frame_index 与两份 SpriteFrames 每动画 3 帧对齐，
## HybridSpriteRig._clamp_frame_index 会把上限 clamp 到帧数-1(=2)，无越界、无 SCRIPT ERROR。
func _drive_pose(f: int) -> void:
	if f % SUBFRAME_INTERVAL != 0:
		return
	var step: int = f / SUBFRAME_INTERVAL
	var idx: int = (step / 3) % POSES.size()
	var pose: String = String(POSES[idx])
	var frame_index: int = step % 3
	if _rig == null or not is_instance_valid(_rig) or not _rig.has_method("set_pose"):
		return
	_rig.call("set_pose", pose, frame_index)
	var cur_pose: String = "?"
	if _rig.has_method("get_current_pose"):
		cur_pose = str(_rig.call("get_current_pose"))
	print("[R26][POSE] frame=%d set_pose(%s, %d) -> get_current_pose()=%s" % [
			f, pose, frame_index, cur_pose])


## HUD flag 变化：WorldState.set_flag → flag_changed → HUD.refresh_label（事件驱动，不轮询）。
## R28 v0.6.0：点亮时间线重排 —— 让首(0)/中(225)/尾(449)三帧采样均处「点亮(金)」态，
## 三段赐福名切换与「点亮↔暗」flag 变化演示保留；仍全部经既有事件驱动路由，不写 Label.text。
func _drive_hud_flags(f: int) -> void:
	match f:
		0:
			_set_flag(FLAG_LAST_GRACE, "grace_limgrave_gatefront")
			_set_flag(LIT_GATEFRONT, true)
			print("[R28][HUD] frame=%d 标题→「赐福 · 关卡前」点亮(金)（首帧可见）" % f)
		40:
			_set_flag(LIT_GATEFRONT, false)
			print("[R28][HUD] frame=%d 同一赐福转暗(灰) flag 变化演示" % f)
		45:
			_set_flag(LIT_GATEFRONT, true)
			print("[R28][HUD] frame=%d 同一赐福再点亮(金) flag 再变化" % f)
		150:
			_set_flag(FLAG_LAST_GRACE, "grace_limgrave_chapel")
			_set_flag(LIT_CHAPEL, true)
			print("[R28][HUD] frame=%d 标题→「赐福 · 巡礼教堂」点亮(金)（中帧可见）" % f)
		250:
			_set_flag(LIT_CHAPEL, false)
			print("[R28][HUD] frame=%d 同一赐福转暗(灰) flag 变化演示" % f)
		255:
			_set_flag(LIT_CHAPEL, true)
			print("[R28][HUD] frame=%d 同一赐福再点亮(金) flag 再变化" % f)
		300:
			_set_flag(FLAG_LAST_GRACE, "grace_weeping_shore")
			_set_flag(LIT_SHORE, true)
			print("[R28][HUD] frame=%d 标题→「赐福 · 啜泣海岸」点亮(金)" % f)
		420:
			_set_flag(FLAG_LAST_GRACE, "grace_siofra_well")
			_set_flag(LIT_WELL, true)
			print("[R28][HUD] frame=%d 标题→「赐福 · 希芙拉河井底」点亮(金)（尾帧可见）" % f)


func _set_flag(key: String, value: Variant) -> void:
	if _world_state == null or not is_instance_valid(_world_state):
		return
	if _world_state.has_method("set_flag"):
		_world_state.call("set_flag", key, value)


## ============================================================================
## R25 · 战斗 HUD 输入注入（方向 3/5；裁决 A15）—— 本段为纯追加，既有逻辑不改。
## 只调用 EncounterDirector 既有 debug_* 公共接口 + get_snapshot()，
## HUD 数值由导演层自身 _update_hud() 刷新，绝不写 StatusLabel 文本、不伪造数值。
## 三段画质切换（_drive_segment）与 pose 切换（_drive_pose）原样保留。
## ============================================================================

func _director() -> Node:
	if _courtyard == null or not is_instance_valid(_courtyard):
		return null
	return _courtyard.get_node_or_null("EncounterRoot") as Node


func _log_snapshot(tag: String) -> void:
	var d: Node = _director()
	if d == null or not d.has_method("get_snapshot"):
		return
	var s: Dictionary = d.call("get_snapshot")
	print("[R25][COMBAT] %s | player_hp=%s boss_hp=%s pose=%s frame=%s dodges=%s hits_landed=%s outcome=%s" % [
			tag, str(s.get("player_hp", "?")), str(s.get("boss_hp_ratio", "?")),
			str(s.get("pose", "?")), str(s.get("frame", "?")),
			str(s.get("dodges", "?")), str(s.get("hits_landed", "?")), str(s.get("outcome", "?"))])


func _combat_attack(pose: String, steps: int, tag: String) -> void:
	var d: Node = _director()
	if d == null or not d.has_method("debug_request_action"):
		push_warning("[R25] EncounterDirector 不可用，跳过 %s" % tag)
		return
	d.call("debug_request_action", pose)
	d.call("debug_step", steps)
	_log_snapshot(tag)


func _combat_boss_hit(tag: String) -> void:
	var d: Node = _director()
	if d == null or not d.has_method("debug_boss_hit"):
		push_warning("[R25] EncounterDirector 不可用，跳过 %s" % tag)
		return
	d.call("debug_boss_hit")
	d.call("debug_step", 1)
	_log_snapshot(tag)


func _combat_dodge(tag: String) -> void:
	var d: Node = _director()
	if d == null or not d.has_method("debug_request_action"):
		push_warning("[R25] EncounterDirector 不可用，跳过 %s" % tag)
		return
	d.call("debug_request_action", "roll")
	d.call("debug_step", 4)          # 翻滚无敌窗口 [4,13)
	d.call("debug_boss_hit")         # 无敌帧内来袭命中 -> 免伤 + dodges
	d.call("debug_step", 1)
	_log_snapshot(tag)


func _combat_kill(tag: String) -> void:
	var d: Node = _director()
	if d == null or not d.has_method("debug_kill_boss"):
		push_warning("[R25] EncounterDirector 不可用，跳过 %s" % tag)
		return
	d.call("debug_kill_boss")
	_log_snapshot(tag)


## 15 秒 450 帧内，战斗 HUD 五项（玩家 HP / Boss HP / 动作帧 / 闪避 / 命中）
## 各至少推进一次，且三段 A/B/C 均有注入点：
##   f30 轻攻击命中(命中+/BossHP↓/动作变) -> f60 受击(玩家HP↓) -> f90 翻滚闪避(闪避+)
##   -> f150 重攻击命中(attack_heavy startup=20，debug_step 须>=20 才在 _frame==20 结算命中)
##   -> f220 段B中段受击推进 -> f300 轻攻击再推进 -> f430 击败 Boss(BossHP=0/胜利)。
## 全部为导演层既有 debug_* 真实数值，非文本伪造、不写 StatusLabel.text。
func _drive_combat_v030(f: int) -> void:
	match f:
		30:
			_combat_attack("attack_light", 12, "C-01 轻攻击命中")
		60:
			_combat_boss_hit("C-02 玩家受击")
		90:
			_combat_dodge("C-03 翻滚闪避")
		150:
			_combat_attack("attack_heavy", 20, "C-04 重攻击命中")
		220:
			_combat_boss_hit("C-04b 段B中段受击推进")
		300:
			_combat_attack("attack_light", 12, "C-05 轻攻击再推进")
		430:
			_combat_kill("C-06 击败 Boss")


## ============================================================================
## R26 v0.4.0 · 三波试炼 HUD 驱动（纯追加，防御性；不改导演层 / 场景 / 既有 HUD）
## 三波段落边界 0 / 150 / 300 与 _drive_segment 三段画质切换对齐。
## 波次 HUD 数值一律由 WaveTrialDirector 既有接口自身刷新；本脚本不写任何 Label.text、
## 不伪造波次计数。若 Rank-1 尚未落盘波次导演/HUD 节点，则如实打印跳过、不冒充已驱动。
## ============================================================================

## 防御性解析波次导演节点（courtyard.tscn 由 Rank-1 独占，本脚本只读引用、不写）。
func _find_wave_director() -> Node:
	if _courtyard == null or not is_instance_valid(_courtyard):
		return null
	for p in ["WaveTrialRoot", "WaveTrialDirector", "WaveTrial",
			"EncounterRoot/WaveTrialDirector", "EncounterRoot/WaveTrialRoot"]:
		var n: Node = _courtyard.get_node_or_null(NodePath(String(p))) as Node
		if n != null:
			return n
	return null


func _drive_wave_hud(f: int) -> void:
	# 三波段落边界（与 _drive_segment 段 A/B/C 对齐）；非边界帧不驱动，避免每帧轮询
	var wave: int = 0
	if f == 0:
		wave = 1
	elif f == 150:
		wave = 2
	elif f == 300:
		wave = 3
	if wave == 0:
		return
	if not _wave_ready or _wave == null or not is_instance_valid(_wave):
		print("[R26][WAVE] frame=%d 波%d 段开始 | 波次导演未落盘（Rank-1 独占），三波 HUD 仅以段 A/B/C + 既有 HUD 呈现（不伪造数值）" % [f, wave])
		return
	_drive_wave_to(wave, f)


## 只经 WaveTrialDirector 既有公开接口推进到目标波的 TELEGRAPH，绝不写 Label.text：
##   start_trial() / debug_advance(sec) / on_encounter_finished(true) / get_snapshot()。
## 状态机 IDLE→TELEGRAPH→WAVE_ACTIVE→WAVE_CLEARED→NEXT_WAVE→下一波 TELEGRAPH；
## 每步都实时读 get_snapshot() 自适应（导演层 _process 也在自动推进，故不假设当前状态）。
## 波次数值 / 倒计时 / 赐福点数全部由导演层自身 _refresh_hud() 刷新，本脚本不构造。
func _drive_wave_to(wave: int, f: int) -> void:
	if not _wave.has_method("get_snapshot"):
		return
	if wave == 1:
		if _wave.has_method("start_trial"):
			_wave.call("start_trial")
		_log_wave(f, wave)
		return
	var guard: int = 0
	while guard < 16:
		guard += 1
		var s: Dictionary = _wave.call("get_snapshot")
		var idx: int = int(s.get("index", 0))
		var st: int = int(s.get("state", 0))
		if (idx >= wave - 1 and st == 1) or st == 5:  # 目标波 TELEGRAPH / TRIAL_COMPLETED
			break
		if st == 0:                                   # IDLE -> 开试炼
			if _wave.has_method("start_trial"):
				_wave.call("start_trial")
			else:
				break
		elif st == 1:                                 # TELEGRAPH -> 越过入场预告
			if _wave.has_method("debug_advance"):
				_wave.call("debug_advance", float(s.get("remaining", 0.0)) + 0.01)
			else:
				break
		elif st == 2:                                 # WAVE_ACTIVE -> 结算清波
			if _wave.has_method("on_encounter_finished"):
				_wave.call("on_encounter_finished", true)
			else:
				break
		elif st == 3 or st == 4:                       # WAVE_CLEARED / NEXT_WAVE -> 下一波
			if _wave.has_method("debug_advance"):
				_wave.call("debug_advance", 0.0)
			else:
				break
		else:
			break
	_log_wave(f, wave)


func _log_wave(f: int, wave: int) -> void:
	var s: Dictionary = _wave.call("get_snapshot")
	print("[R26][WAVE] frame=%d 波%d 驱动完成 | state=%s index=%s/%s points=%s hud_text=%s" % [
			f, wave, str(s.get("state_name", "?")), str(s.get("index", "?")),
			str(s.get("total", "?")), str(s.get("points_total", "?")),
			str(s.get("hud_text", "?"))])


## ============================================================================
## R27 v0.5.0 · 三波空间节奏画面驱动（Rank-4 独占本文件 · 派单 cmd-20261111-083350-249-A4）
## 三波边界 0 / 150 / 300 与 _drive_segment 段 A/B/C、_drive_wave_hud 波 1/2/3 严格对齐；
## 只调用 hd2d_parallax.gd 既有公开接口 set_wave_index(w)（has_method 守卫），
## 让远景色带 / 雾密度 / 地面色调按波次产生可辨变化；不新增素材、不启 GPU job、不写场景。
## ============================================================================
func _drive_wave_space(f: int) -> void:
	var wave: int = 0
	if f == 0:
		wave = 1
	elif f == 150:
		wave = 2
	elif f == 300:
		wave = 3
	if wave == 0:
		return
	if _parallax == null or not is_instance_valid(_parallax) \
			or not _parallax.has_method("set_wave_index"):
		push_warning("[R27][SPACE] frame=%d 波%d | ParallaxBackdrop 节点/接口不可用，三波空间变化如实跳过" % [f, wave])
		return
	_parallax.call("set_wave_index", wave)
	print("[R27][SPACE] frame=%d 波%d set_wave_index(%d) -> 回读 wave_index=%s（远景色带/雾密度/地面色调按波切换）" % [
			f, wave, wave, str(_parallax.get("wave_index"))])


## ============================================================================
## R27 · 成长兑换 HUD 可读性实证（纯读，绝不写 Label.text / 不伪造数值）
## 三波边界与尾帧读 WaveTrialDirector 既有 get_snapshot() 的赐福点数 / 历史最佳 / hud_text；
## WaveTrialHud/WaveLabel 位于 CanvasLayer layer=20，视差(layer=5)/光效(layer=10) 均在其下且
## 光尘逐粒 HUD 避让，三波空间换色不遮挡成长兑换 HUD；赐福点数 0→100→250→450 全程可读。
## ============================================================================
func _drive_growth_hud(f: int) -> void:
	if f != 0 and f != 150 and f != 300 and f != 449:
		return
	if not _wave_ready or _wave == null or not is_instance_valid(_wave) \
			or not _wave.has_method("get_snapshot"):
		print("[R27][GROWTH] frame=%d 波次导演未落盘（Rank-1 独占），成长兑换 HUD 数值如实跳过" % f)
		return
	var s: Dictionary = _wave.call("get_snapshot")
	print("[R27][GROWTH] frame=%d 成长兑换 HUD 快照 | 赐福点数=%s 历史最佳=%s 波=%s/%s hud_text=%s" % [
			f, str(s.get("points_total", "?")), str(s.get("best_wave", "?")),
			str(s.get("index", "?")), str(s.get("total", "?")), str(s.get("hud_text", "?"))])


## ============================================================================
## R28 v0.6.0 · 真实输入事件注入（Rank-4 独占本文件 · 派单 cmd-20261111-095602-831-A4）
## 全部经 Input.parse_input_event 注入 InputEventKey（pressed + released 配对），由引擎输入系统
## 分发到既有 _unhandled_input 路由，不写任何 Label.text、不调 debug_* 伪造数值：
##   J(74)     -> EncounterDirector._unhandled_input(light_attack) -> _request_action("attack_light")
##   Space(32) -> ... (roll) -> _request_action("roll")；_request_action 当帧 _update_hud() 推进动作帧
##   E(69)     -> hud._toggle_shop() 展开兑换面板 / encounter._grace_rest() / wave.interact_restart()
##   1(49)     -> hud.purchase_upgrade(0) 购买一项（点数由 WaveTrialDirector 结算真实累积）
## ============================================================================

## 防御性探测 Rank-1 承诺的 tutorial_director 接口；并发时序下未落盘则如实降级，不假设存在。
func _resolve_tutorial_api() -> void:
	_tutorial_api_available = false
	_tutorial_director = null
	var candidates: Array[String] = [
		"TutorialDirector", "TutorialRoot", "TutorialRoot/TutorialDirector",
		"EncounterRoot/TutorialDirector", "WaveTrialDirector/TutorialDirector",
		"SubViewportContainer/SubViewport/FXLayer/Hud/TutorialDirector"]
	for p: String in candidates:
		var n: Node = _courtyard.get_node_or_null(NodePath(p)) as Node
		if n != null and n.has_method("is_tutorial_active") and n.has_method("force_complete"):
			_tutorial_director = n
			_tutorial_api_available = true
			break
	if not _tutorial_api_available:
		print("[R28][TUTORIAL][降级] 全工程无 tutorial 脚本/节点，is_tutorial_active()/force_complete() 接口未落盘；"
				+ "降级为「直接注入真实按键 + 如实登记接口缺失」，教学闭环未证明、不谎报")
		return
	var active: bool = bool(_tutorial_director.call("is_tutorial_active"))
	# _initialize 阶段教学 _ready 尚未执行，状态为 NOT_STARTED（active=false）；
	# 真实避免双驱动在逐帧 _guard_tutorial() 里做：由真实按键 J→Space→E 完成教学并衔接到波次。
	print("[R28][TUTORIAL] 接口已落盘 name=%s is_tutorial_active()=%s（_initialize 阶段教学 _ready 未执行；逐帧以 is_tutorial_active() 监测，由真实按键 J→Space→E 完成教学并衔接到第 1 波）" % [
			str(_tutorial_director.name), str(active)])
	if active:
		_tutorial_director.call("force_complete")
		print("[R28][TUTORIAL] force_complete() 已调用，避免教学状态机与本脚本输入注入双驱动")


## 构造真实 InputEventKey 并注入引擎输入系统（pressed + released 配对）。
func _inject_key(keycode: int) -> void:
	var press: InputEventKey = InputEventKey.new()
	press.physical_keycode = keycode
	press.keycode = keycode
	press.pressed = true
	press.echo = false
	Input.parse_input_event(press)
	var release: InputEventKey = InputEventKey.new()
	release.physical_keycode = keycode
	release.keycode = keycode
	release.pressed = false
	release.echo = false
	Input.parse_input_event(release)


## 逐帧驱动真实输入注入 + 关键帧只读回读证据。
func _drive_real_input(f: int) -> void:
	# ① 周期性 J / Space：f=0 的 J 完成教学第 1 步、f=6 的 Space 完成第 2 步；
	#    教学完成后继续注入，仅驱动 EncounterDirector 动作帧 HUD（教学 COMPLETED 态不再消费输入）。
	if f % ACTION_INTERVAL == 0:
		var step: int = f / ACTION_INTERVAL
		var key: int = KEY_J if step % 2 == 0 else KEY_SPACE
		var action: String = "light_attack(J)" if key == KEY_J else "roll(Space)"
		_inject_key(key)
		print("[R28][INPUT] frame=%d 注入真实按键 %s -> Input.parse_input_event(InputEventKey)" % [f, action])
	# ② E：教学第 3 步（STEP_GRACE_SHOP 期待 interact）+ hud._toggle_shop() 打开兑换面板；
	#    只注入一次，之后面板保持展开（不再注入 E 关闭它）。
	if f == E_OPEN_FRAME:
		_inject_key(KEY_E)
		print("[R28][INPUT] frame=%d 注入真实按键 interact(E) -> tutorial 第3步 / hud._toggle_shop / encounter._grace_rest / wave.interact_restart" % f)
	# ③ 数字键 1：购买一项（点数由教学奖励 + 波次结算真实累积，不构造）。
	if f == BUY_FRAME:
		_inject_key(KEY_1)
		print("[R28][INPUT] frame=%d 注入真实按键 1 -> hud.purchase_upgrade(0) 购买一项" % f)
	# ③b R30：注入一次 Tab，走真实 Input.parse_input_event 路由打开赐福图鉴（录屏留证）。
	if f == CODEX_TAB_FRAME:
		_inject_key(KEY_TAB_CODE)
		print("[R30][CODEX][INPUT] frame=%d 注入真实按键 Tab(KEY_TAB=%d) -> Input.parse_input_event(InputEventKey) -> CodexDirector._unhandled_input 打开赐福图鉴面板" % [f, KEY_TAB_CODE])
	# ④ 教学闭环监测 + 兜底：用 is_tutorial_active()/force_complete() 避免教学冻结与波次驱动双驱动。
	if f == TUTORIAL_GUARD_FRAME:
		_guard_tutorial(f)
	# ⑤ 关键帧只读回读（不写）：验证输入经既有路由生效。
	if f == 0 or f == E_OPEN_FRAME + 2 or f == BUY_FRAME + 1 or f == 225 or f == 449:
		_log_input_evidence(f)
	# ⑥ R33：F 键处决（真实 Input.parse_input_event → HUD._process_r32_keys →
	#    request_execution() → 真实 StaggerService.try_execute()）。
	if f == STAGGER_EXEC_FRAME:
		_inject_key(KEY_F_CODE)
		print("[R33][INPUT] frame=%d 注入真实按键 F(KEY_F=%d) -> HUD.request_execution() → 真实 StaggerService.try_execute()" % [f, KEY_F_CODE])
	# ⑦ R33：Tab 再注入一次关闭图鉴（演示「图鉴关闭 → 兑换/赐福成长面板恢复」互斥）。
	if f == CODEX_TAB_CLOSE_FRAME:
		_inject_key(KEY_TAB_CODE)
		print("[R33][INPUT] frame=%d 再注入真实按键 Tab -> 关闭图鉴；HUD 互斥恢复兑换面板 visible（R33 修复实证）" % f)
	# ⑧ R33：数字键 2 选择赐福抉择（真实输入 → HUD._select_boon_draft(1) → 真实 BoonDraftService.select(1)）。
	if f == BOON_SELECT_FRAME:
		_inject_key(KEY_2_CODE)
		print("[R33][INPUT] frame=%d 注入真实按键 2(KEY_2=%d) -> HUD._select_boon_draft(1) → 真实 BoonDraftService.select(1)" % [f, KEY_2_CODE])


## 教学闭环监测：读 tutorial_director 既有只读快照 + is_tutorial_active()；
## 教学仍激活则 force_complete() 兜底（避免三波永久冻结 / 演示序列与教学双驱动），
## 已完成则登记「由真实按键三步完成并自动衔接到第 1 波」，不谎报教学闭环已证明。
func _guard_tutorial(f: int) -> void:
	if not _tutorial_api_available or _tutorial_director == null \
			or not is_instance_valid(_tutorial_director):
		print("[R28][TUTORIAL] frame=%d 接口未落盘（降级）：教学闭环未证明，波次仅由既有 _drive_wave_hud 驱动" % f)
		return
	var snap: Dictionary = {}
	if _tutorial_director.has_method("get_snapshot"):
		snap = _tutorial_director.call("get_snapshot")
	var active: bool = bool(_tutorial_director.call("is_tutorial_active"))
	print("[R28][TUTORIAL] frame=%d 快照 state=%s step_events=%s total_reward=%s wave_started=%s hud=%s | is_tutorial_active()=%s" % [
			f, str(snap.get("state_name", "?")), str(snap.get("step_events", "?")),
			str(snap.get("total_reward", "?")), str(snap.get("wave_started", "?")),
			str(snap.get("tutorial_hud_text", "?")), str(active)])
	if active:
		_tutorial_director.call("force_complete")
		print("[R28][TUTORIAL] frame=%d 真实按键未完成教学 -> force_complete() 兜底（如实登记，非真实按键闭环）" % f)
	else:
		print("[R28][TUTORIAL] frame=%d 教学已由真实按键 J→Space→E 三步完成并自动衔接到第 1 波（force_complete 未触发）" % f)


## 只读回读既有公共接口，打印「输入经既有路由生效」的证据，绝不写 Label.text。
func _log_input_evidence(f: int) -> void:
	var shop_open: String = "n/a"
	var shop_msg: String = "n/a"
	if _hud != null and is_instance_valid(_hud) and _hud.has_method("get_shop_view"):
		var v: Dictionary = _hud.call("get_shop_view")
		shop_open = str(v.get("open", "?"))
		shop_msg = str(v.get("message", "?"))
	var status: String = "n/a"
	if _status_label != null and is_instance_valid(_status_label):
		status = _status_label.text
	# R30：只读回读图鉴面板开关态（不写 HUD 文本 / 不伪造数值）。
	var codex_open: String = "n/a"
	if _courtyard != null and is_instance_valid(_courtyard):
		var cd: Node = _courtyard.get_node_or_null("CodexDirector") as Node
		if cd != null and cd.has_method("is_panel_open"):
			codex_open = str(cd.call("is_panel_open"))
	# R33：只读回读兑换面板【真实节点 visible】留证 —— f=225（Tab 图鉴开）应为 false、
	#   f=449（Tab 关）应为 true，即「图鉴打开→兑换确实隐藏 / 关闭→恢复」的实机证据。
	var shop_visible: String = "n/a"
	if _hud != null and is_instance_valid(_hud):
		var lbl: Label = _hud.get("_shop_label") as Label
		if lbl != null and is_instance_valid(lbl):
			shop_visible = str(lbl.visible)
	print("[R28][EVIDENCE] frame=%d shop_open=%s shop_message=%s | StatusLabel=%s | codex_panel_open=%s | shop_label_visible=%s" % [
			f, shop_open, shop_msg, status, codex_open, shop_visible])


## ============================================================================
## R33 [ROUND=R33] · 新玩法演示可见层 + 真实服务驱动（Rank-1 本轮独占本文件）
## 可见层文本/数值一律读 HUD 公开快照 get_stagger_hud_view() / get_boon_draft_view()，
## 不写既有 HUD 的 Label.text、不调 debug_*、不伪造数值；运行时挂载、不写 courtyard.tscn。
## 【演示驱动】开窗 / 卡片由显式调用 Rank-2 公开方法构造，见 DONE-R33.md 待裁决项。
## ============================================================================

func _r33_make_label(n: String) -> Label:
	var l: Label = Label.new()
	l.name = n
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82, 1.0))
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.06, 1.0))
	l.add_theme_constant_override("outline_size", 5)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.06, 0.12, 0.30)
	bg.set_corner_radius_all(6)
	bg.set_border_width_all(1)
	bg.border_color = Color(0.83, 0.68, 0.3, 0.55)
	bg.content_margin_left = 10.0
	bg.content_margin_right = 10.0
	bg.content_margin_top = 6.0
	bg.content_margin_bottom = 6.0
	l.add_theme_stylebox_override("normal", bg)
	return l


func _r33_hide_all() -> void:
	if _r33_poise_bar != null and is_instance_valid(_r33_poise_bar):
		_r33_poise_bar.visible = false
	if _r33_stagger_label != null and is_instance_valid(_r33_stagger_label):
		_r33_stagger_label.visible = false
	if _r33_draft_label != null and is_instance_valid(_r33_draft_label):
		_r33_draft_label.visible = false


func _build_r33_overlay() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = R33_LAYER_NAME
	layer.layer = R33_LAYER_INDEX
	# ① Boss 韧性条：真实 ProgressBar（非文本伪条），value 由 HUD 快照 poise_ratio 驱动。
	var bar: ProgressBar = ProgressBar.new()
	bar.name = "R33PoiseBar"
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.offset_left = R33_RECT_LEFT + 12.0
	bar.offset_top = R33_RECT_TOP + 12.0
	bar.offset_right = R33_RECT_RIGHT - 12.0
	bar.offset_bottom = R33_RECT_TOP + 34.0
	layer.add_child(bar)
	_r33_poise_bar = bar
	# ② 处决窗口读秒 / F 处决反馈（多行 Label）。
	var sl: Label = _r33_make_label("R33StaggerLabel")
	sl.offset_left = R33_RECT_LEFT + 12.0
	sl.offset_top = R33_RECT_TOP + 40.0
	sl.offset_right = R33_RECT_RIGHT - 12.0
	sl.offset_bottom = R33_RECT_BOTTOM - 12.0
	layer.add_child(sl)
	_r33_stagger_label = sl
	# ③ 赐福抉择三选一卡片（与韧性段互斥显示）。
	var dl: Label = _r33_make_label("R33BoonDraftLabel")
	dl.offset_left = R33_RECT_LEFT + 12.0
	dl.offset_top = R33_RECT_TOP + 12.0
	dl.offset_right = R33_RECT_RIGHT - 12.0
	dl.offset_bottom = R33_RECT_BOTTOM - 12.0
	layer.add_child(dl)
	_r33_draft_label = dl
	_r33_hide_all()
	_r33_layer = layer
	# SceneTree._initialize 已能取到 Courtyard 实例（场景树已构建）；仍用 call_deferred
	# 双保险，避开 _ready 传播期（同 R29/R30/R31 既有口径）。
	root.call_deferred("add_child", layer)
	print("[R33][OVERLAY] 演示可见层组装完成（CanvasLayer layer=%d，rect=(%.0f,%.0f)-(%.0f,%.0f) 避开既有 HUD/角色）→ deferred 入 root" % [
			R33_LAYER_INDEX, R33_RECT_LEFT, R33_RECT_TOP, R33_RECT_RIGHT, R33_RECT_BOTTOM])


func _bind_r33_services() -> void:
	# Rank-2 真实服务（CACHE_MODE_IGNORE 回读真值）；缺件判空降级、不崩、不伪造。
	if ResourceLoader.exists(STAGGER_SVC_PATH) and ResourceLoader.exists(STAGGER_CFG_PATH):
		var ss: Script = ResourceLoader.load(STAGGER_SVC_PATH, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
		var sc: Resource = ResourceLoader.load(STAGGER_CFG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
		if ss != null and sc != null:
			_r33_stagger_svc = ss.new(sc)
			if _hud != null and is_instance_valid(_hud) and _hud.has_method("bind_stagger_service"):
				_hud.call("bind_stagger_service", _r33_stagger_svc)
	if ResourceLoader.exists(BOON_SVC_PATH) and ResourceLoader.exists(BOON_CFG_PATH):
		var bs: Script = ResourceLoader.load(BOON_SVC_PATH, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
		var bc: Resource = ResourceLoader.load(BOON_CFG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
		if bs != null and bc != null:
			_r33_boon_svc = bs.new(bc)
			if _hud != null and is_instance_valid(_hud) and _hud.has_method("bind_boon_draft_service"):
				_hud.call("bind_boon_draft_service", _r33_boon_svc)
	# 真实信号回读（只登记，不伪造画面数值）；末尾 _r33_release_signals() 显式释放。
	if _hud != null and is_instance_valid(_hud):
		if _hud.has_signal("execution_performed"):
			_hud.connect("execution_performed", Callable(self, "_r33_on_execution"))
			_r33_signals_connected = true
		if _hud.has_signal("boon_draft_selected"):
			_hud.connect("boon_draft_selected", Callable(self, "_r33_on_boon_selected"))
			_r33_signals_connected = true
	print("[R33][SVC] stagger=%s boon=%s | 演示驱动：开窗/卡片由显式调用 Rank-2 公开方法构造，见 DONE-R33.md" % [
			str(_r33_stagger_svc != null), str(_r33_boon_svc != null)])


func _r33_on_execution(_window_id: String, bonus_points: int) -> void:
	_r33_exec_count += 1
	_r33_exec_text = "处决成功！额外点数 +%d（F 键）" % bonus_points
	print("[R33][EXEC] execution_performed 真实信号回读 bonus=%d count=%d" % [bonus_points, _r33_exec_count])


func _r33_on_boon_selected(index: int, choice_id: String) -> void:
	_r33_select_count += 1
	_r33_select_text = "已选择第 %d 项（%s）｜数字键确认" % [index + 1, choice_id]
	print("[R33][BOON] boon_draft_selected 真实信号回读 index=%d id=%s count=%d" % [
			index, choice_id, _r33_select_count])


func _r33_release_signals() -> void:
	if not _r33_signals_connected or _hud == null or not is_instance_valid(_hud):
		return
	var cb1: Callable = Callable(self, "_r33_on_execution")
	if _hud.has_signal("execution_performed") and _hud.is_connected("execution_performed", cb1):
		_hud.disconnect("execution_performed", cb1)
	var cb2: Callable = Callable(self, "_r33_on_boon_selected")
	if _hud.has_signal("boon_draft_selected") and _hud.is_connected("boon_draft_selected", cb2):
		_hud.disconnect("boon_draft_selected", cb2)
	_r33_signals_connected = false
	print("[R33][RELEASE] execution_performed / boon_draft_selected 信号连接已释放（_exit_tree 兜底口径）")


func _r33_open_stagger_window(f: int) -> void:
	_r33_exec_text = ""
	if _r33_stagger_svc == null:
		print("[R33][STAGGER] frame=%d 真实 StaggerService 不可用，韧性演示如实跳过（不伪造）" % f)
		return
	# 【演示驱动】真实「玩家命中 → apply_hit」链未接入演示序列（无真实命中削韧事件），
	# 显式调用 Rank-2 公开 apply_hit(100.0) 构造「破韧开窗」演示状态（签名见 DONE-R32.md §3）。
	var r: Dictionary = _r33_stagger_svc.call("apply_hit", 100.0) as Dictionary
	if _hud != null and is_instance_valid(_hud) and _hud.has_method("poll_stagger_service"):
		_hud.call("poll_stagger_service")
	print("[R33][STAGGER] frame=%d apply_hit(100.0) → opened_now=%s window=%s remaining=%s（演示驱动：非玩家真实命中链）" % [
			f, str(r.get("opened_now", "?")), str(r.get("window_open", "?")), str(r.get("window_remaining", "?"))])


func _r33_refresh_stagger(f: int) -> void:
	_r33_hide_all()
	if _r33_poise_bar == null or _r33_stagger_label == null:
		return
	var v: Dictionary = {}
	if _hud != null and is_instance_valid(_hud) and _hud.has_method("get_stagger_hud_view"):
		v = _hud.call("get_stagger_hud_view") as Dictionary
	_r33_poise_bar.value = clampf(float(v.get("poise_ratio", 1.0)) * 100.0, 0.0, 100.0)
	var lines: Array[String] = []
	lines.append(str(v.get("poise_text", "Boss 韧性")))
	lines.append(str(v.get("window_text", "")))
	if not _r33_exec_text.is_empty():
		lines.append(_r33_exec_text)
	_r33_stagger_label.text = "\n".join(PackedStringArray(lines))
	_r33_poise_bar.visible = true
	_r33_stagger_label.visible = true
	if f == STAGGER_BIND_FRAME or f == STAGGER_EXEC_FRAME or f == STAGGER_END_FRAME - 1:
		print("[R33][STAGGER][HUD] frame=%d poise=[%s] window=[%s] exec=[%s]（读 HUD 真实快照渲染可见层）" % [
				f, str(v.get("poise_text", "?")), str(v.get("window_text", "?")), _r33_exec_text])


func _r33_open_boon_draft(f: int) -> void:
	_r33_select_text = ""
	if _hud == null or not is_instance_valid(_hud) or not _hud.has_method("on_wave_cleared"):
		print("[R33][BOON] frame=%d HUD 不可用，抉择演示如实跳过（不伪造）" % f)
		return
	# 【演示驱动】真实「清波 → wave_cleared → 抉择」链未接入演示序列（无真实清波事件），
	# 显式调用 HUD.on_wave_cleared()（内部读真实 BoonDraftService 候选）构造三选一卡片。
	_hud.call("on_wave_cleared")
	print("[R33][BOON] frame=%d on_wave_cleared() → 三选一卡片打开（演示驱动：非玩家真实清波可达）" % f)


func _r33_refresh_boon_draft(f: int) -> void:
	_r33_hide_all()
	if _r33_draft_label == null:
		return
	var v: Dictionary = {}
	if _hud != null and is_instance_valid(_hud) and _hud.has_method("get_boon_draft_view"):
		v = _hud.call("get_boon_draft_view") as Dictionary
	var choices: Array = v.get("choices", []) as Array
	var lines: Array[String] = []
	lines.append("赐福抉择 · 三选一（数字键 1 / 2 / 3 选择）")
	for i: int in range(choices.size()):
		var c: Variant = choices[i]
		var title: String = ""
		if typeof(c) == TYPE_DICTIONARY:
			var d: Dictionary = c as Dictionary
			title = String(d.get("title", d.get("id", "")))
		lines.append("  %d. %s" % [i + 1, title])
	if not _r33_select_text.is_empty():
		lines.append(_r33_select_text)
	elif bool(v.get("open", false)):
		lines.append("提示：按 1 / 2 / 3 选择一项")
	_r33_draft_label.text = "\n".join(PackedStringArray(lines))
	_r33_draft_label.visible = true
	if f == BOON_BIND_FRAME or f == BOON_SELECT_FRAME or f == BOON_END_FRAME - 1:
		print("[R33][BOON][HUD] frame=%d open=%s choices=%d select=[%s]（读 HUD 真实快照渲染可见层）" % [
				f, str(v.get("open", "?")), choices.size(), _r33_select_text])


## 逐帧驱动：韧性/处决段（96~145）与赐福抉择段（330~399）互斥显示；其余帧隐藏。
func _drive_r33_mechanisms(f: int) -> void:
	if f == STAGGER_BIND_FRAME:
		# 可见层入树回读：证明 deferred add_child 已生效（CanvasLayer 能被 MovieMaker 渲染的前提）。
		print("[R33][OVERLAY] frame=%d 可见层入树回读 is_inside_tree=%s（CanvasLayer 渲染前提）" % [
				f, str(_r33_layer != null and _r33_layer.is_inside_tree())])
		_r33_open_stagger_window(f)
	if f >= STAGGER_BIND_FRAME and f < STAGGER_END_FRAME:
		# 真实服务 tick(delta) 推进窗口倒计时 + HUD.poll_stagger_service() 回读真实快照；
		# 二者均由显式逐帧调用驱动（演示序列确定性，不读引擎真实时钟）。
		if _r33_stagger_svc != null and _r33_stagger_svc.has_method("tick"):
			_r33_stagger_svc.call("tick", 1.0 / 30.0)
		if _hud != null and is_instance_valid(_hud) and _hud.has_method("poll_stagger_service"):
			_hud.call("poll_stagger_service")
		_r33_refresh_stagger(f)
		return
	if f == BOON_BIND_FRAME:
		_r33_open_boon_draft(f)
	if f >= BOON_BIND_FRAME and f < BOON_END_FRAME:
		_r33_refresh_boon_draft(f)
		return
	_r33_hide_all()
