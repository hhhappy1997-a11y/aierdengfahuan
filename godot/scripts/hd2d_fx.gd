extends Node2D
## R18 · 独立可挂载 HD-2D 光效节点（程序化 _draw() · 零外部素材）
## 派单：cmd-20261109-095518-176-A4 · [ROUND=R18] · 工位 Rank-4
## 精修（在 R16 独立场景 / R17 由 Rank-1 挂进主场景的基础上，只改本 .gd）：
##   ① 暖金体积光扇形 4→6 层、峰值 alpha 保持 0.18 不糊画面、补中心高光带（柔核+亮核）；
##   ② 倒影改垂直镜像近似：2×2 半透明色块向下翻转 + 压缩 0.85 + 深度渐隐 + 逐行波纹，
##      不再是被地面横砖淹没成的「一条水平亮线」；
##   ③ 光尘绘制时按 HUD 屏幕矩形（约 x<730、y<220）逐粒跳过，避免面板被点状遮挡；
##   ④ fx_profile desktop/mobile 档位开关与 texture_filter=Nearest 冻结口径不变。
##
## R20 精修（派单 cmd-20261109-110237-810-A4 · [ROUND=R20] · Rank-4）：
##   ⑤ 补 R19 缺口：新增「运行期强制档位覆盖」，读环境变量 AIERDENG_FX_PROFILE=mobile，
##      经 call_deferred 在 courtyard.tscn 的 HD2DFX 根（Rank-1 独占 fx_profile_controller.gd）
##      的 _ready() 强制 desktop 之后，把本 FX 节点真正落到 mobile 四项全关，并锁定档位
##      忽略后续 desktop 请求 → Movie Maker 抓帧可真实输出移动档画面（非 desktop 帧改名）。
##      未设该环境变量时完全不激活：默认 desktop 四项全开零回退，47 PASS 回归不受影响。
##   ⑥ HUD 避让矩形（x<730、y<220）改由 hd2d_fx.tscn 的 metadata 场景级配置、脚本常量兜底；
##      判定纳入光尘圆点半径（margin 只向外扩），避免粒子边缘擦进 HUD 面板。
##      mobile 四项全关时 _draw() 直接 return、FX 层零绘制，天然无光尘遮 HUD。
##
## 定位：把 HD2D-FX-PLAN.md §3 的四项 2D 程序化光效（湿地倒影 / 体积光 / 光尘 /
##       bloom）外提为独立 CanvasLayer 场景里的光效节点。R17 已由 Rank-1 把
##       hd2d_fx.tscn 挂进 courtyard.tscn；本轮不碰主场景（Rank-1 独占）。
##
## 四项原语（均落在 _draw() 内，零 PNG / 零贴图 / 零插件 / 零云服务 / 零付费 API）：
##   · 倒影   draw_rect()     垂直镜像色块 + 压缩 + 逐行波纹 + 深度渐隐（§3.3 / 占位 step6）
##   · 体积光 draw_colored_polygon() ×6 + draw_line() 中心高光（§3.1 / step5）
##   · 光尘   draw_circle()   远景冷白 48 + 近景暖金 32，seed=20261108 固定，HUD 区避让（§3.2）
##   · bloom  draw_circle()   同心圆 ×5 + 暖金核心，仅 warm_gold_key 过阈（§3.4 / step8）
##
## 档位开关：fx_profile = "desktop" 四项全开 / "mobile" 四项全关
##   （冻结口径 HD2D-FX-PLAN.md §4.2，quality_preset_*.tres / render_profiles.tres）。
##   §4.3「移动档降级而非全关」是待裁决建议，本轮不擅自实现（沿用 R15 登记）。
##
## R32 / v0.10.0 追加（派单 cmd-20261112-074023-416-A4 ② · R31B 遗留补齐）：
##   ⑦ impact_fx.png 按 r23/import.json 以【只读加载】方式接入本程序化特效层，
##      复用 FXBloom 分派、不新增节点 / 不改节点名 / 不改 courtyard.tscn / 不改 presentation.gd；
##      保留既有四项降级层与 desktop/mobile 档位，资源缺失静默跳过、移动端零额外开销。
##
## 约束：ComfyUI 仍是主美术路线，本脚本是零外部依赖的 2D 程序化兜底，不取代主路线、
##       不宣称已能出图 / 已实现 3D 后处理；中文 UTF-8；Godot 4 合法语法。
##       实体坐标 round() 到整数、禁亚像素；Nearest 过滤；不改运行中 hd2d_placeholder.gd。
##
## R34 / v0.11.0 追加（派单 cmd-20261112-091304-459-A4 ① · Rank-4）：
##   ⑧ 连击评级反馈层：D/C/B/A/S 五档暖金强度 + 光尘密度递进、S 级一次短促暖金
##      收束爆发（无过曝）、受击/超时/manual 重置冷却到冷夜雾；全部落在既有
##      FXBloom 分派节点的 _draw() 内（最上层叠加），零新增节点 / 零 GPU job / 零付费。
##      【A54】经 wave_trial_director.gd 公开 get_combo_service() 订阅「唯一」ComboService
##      的 4 个公开信号，绝不自建第二个、不读其私有实现；未接线则静默降级（既有四项
##      光效 + impact_fx 照常）。单帧 ≤16 色受控 / 项目级 ≥256 色两层口径不变：
##      连击层零新增色号（复用既有 PALETTE_HEX / 既有 _draw 已用 hex）。
##      完整 [PLACEHOLDER] 数值表 / rationale / 口径差异登记见下方「R34 连击评级反馈层」块。

# ---------------------------------------------------------------------------
# 冻结口径常量（引用 hd2d_placeholder.gd / HD2D-FX-PLAN.md §3 / ART-SPEC-FINAL.md §2.2）
# ---------------------------------------------------------------------------
const BUFFER_W := 640.0
const BUFFER_H := 360.0
const GROUND_Y := 250.0
const PLACEHOLDER_SEED := 20261108
const LIGHT_POS := Vector2(452.0, 92.0)

const PROFILE_DESKTOP := "desktop"
const PROFILE_MOBILE := "mobile"

# ---------------------------------------------------------------------------
# R32 / v0.10.0 · R31B 遗留补齐：impact_fx.png 只读接入程序化特效层
# 派单 cmd-20261112-074023-416-A4 ②。约束（逐条）：
#   · 只读加载：运行时 FileAccess.get_file_as_string() 读 import.json + load() 读 PNG，
#     绝不写 / 不生成 / 不修改 res://assets/generated/r23/ 下任何文件；
#   · 不新增节点、不改 courtyard.tscn 节点 41 / uv 2/1/1 / 任何节点名、
#     不改 presentation.gd；仅复用既有 FXBloom 分派分支（最上层光效）；
#   · 保留既有降级层：资源缺失 / JSON 解析失败 / 显式关开关 → 静默跳过，
#     既有 FXReflection / FXGodRays / FXMotes / FXBloom 四项程序化光效照常；
#   · 移动端不劣化：懒加载只在 desktop（_all_on）绘制路径触发，mobile 段
#     _draw() 开头即 return，永不加载、零额外绘制开销。
# [PLACEHOLDER] 演示循环 int(t*fps)%n / alpha=0.32 / 绘制 96×96 为试玩校准值，
#   rationale：15s 录屏全段可见、低 alpha 不加剧暖金收束过曝、避开 HUD 矩形与角色判定区。
# ---------------------------------------------------------------------------
const IMPACT_IMPORT_PATH: String = "res://assets/generated/r23/import.json"
const IMPACT_PNG_PATH: String = "res://assets/generated/r23/impact_fx.png"
@export var impact_fx_enabled: bool = true
@export var impact_fx_alpha: float = 0.32
var _impact_sheet: Texture2D = null
var _impact_import: Dictionary = {}
var _impact_load_attempted: bool = false

# ---------------------------------------------------------------------------
# R20 · 运行期强制档位覆盖（补 R19「只抓到 desktop 画面」缺口）
# 背景：courtyard.tscn 的 HD2DFX 根挂 Rank-1 独占 fx_profile_controller.gd，其 _ready()
#       依 fx_profile_source（固定指向 desktop preset 640×360）把 4 个 FX 子节点强制切回
#       desktop。本脚本是 hd2d_fx.tscn 的 4 个 FX 子节点（Rank-4 可写），在此提供
#       「只在显式请求时激活」的覆盖：环境变量 = mobile 时，deferred 排在 controller
#       _ready() 之后落到 mobile，并锁定档位忽略后续 desktop 请求。
# 默认（未设环境变量）：不激活，_ready() 走原 set_fx_profile(fx_profile) 默认 desktop，
#       desktop 四项全开零回退；verify_fx_mobile.gd 的 47 PASS 回归不受任何影响。
# ---------------------------------------------------------------------------
const ENV_FORCE_PROFILE: String = "AIERDENG_FX_PROFILE"
var _force_profile: String = ""

# 档位开关（唯一开关）：desktop 四项全开 / mobile 四项全关
@export_enum("desktop", "mobile") var fx_profile: String = PROFILE_DESKTOP

# 四项各自的绘制门（由档位派生；分列便于 R17 按接入点 / 待裁决降级建议逐项接线）
var _all_on: bool = true
var _on_reflection: bool = true
var _on_godrays: bool = true
var _on_motes: bool = true
var _on_bloom: bool = true

# ---------------------------------------------------------------------------
# R18 精修参数（普通成员，供 build_fx_r18_verify.gd 运行期 get() 回读；零外部素材）
# ---------------------------------------------------------------------------
# ① 体积光：层数 4→6（径向衰减更细腻），扇形峰值 alpha 保持 0.18 不抬高以免糊画面；
#    另以中心高光带（柔核 + 亮核）强化暖金主光方向。
var godray_layers: int = 6
var godray_alpha: Array[float] = [0.18, 0.14, 0.10, 0.07, 0.045, 0.025]
var godray_spread_base: float = 40.0
var godray_spread_step: float = 30.0
# ② 倒影：垂直镜像 2×2 半透明色块（连成轮廓）+ 压缩 0.85 向下延伸 + 深度渐隐 + 逐行波纹。
var reflection_squash: float = 0.85
var reflection_alpha: float = 0.42
var reflection_fade: float = 0.55
var reflection_block_px: float = 2.0
var reflection_ripple: float = 0.035

# ---------------------------------------------------------------------------
# [PLACEHOLDER] R31 / v0.9.0 · 湿地倒影精修新增参数（待试玩校准）
# rationale：暖金像素角色倒影须落在「冷夜雾湿地」上才成立 —— 离散冷蓝水面带 +
#   暖金/冷白交替高光横线 + 深层冷雾叠色，强化「暖金 × 冷夜雾」强对比，
#   与像素精灵硬边形成「2×2 硬色块 vs 平滑水面」的 HD-2D 层次。
# 既有 reflection_squash / alpha / fade / block_px / ripple 五项冻结口径全部保留不改。
# ---------------------------------------------------------------------------
var reflection_water_bands: int = 4
var reflection_cold_tint: float = 0.30

# [PLACEHOLDER] R31 / v0.9.0 · 光尘密度精修：远景 48→64 / 近景 32→48（待试玩校准）
# rationale：暖金近景浮尘加密强化体积光下的空气感，冷白远景加密拉开与像素精灵
#   硬边的「平滑景深」层次；仅 desktop 档 _all_on 绘制，mobile 四项全关时
#   _draw() 直接 return（数组构建开销可忽略）→ 移动端档位零劣化。
# tone 分组（i % 3）做「金线深蓝」冷暖分层，确定性、无随机噪点。
const MOTES_FAR_COUNT: int = 64
const MOTES_NEAR_COUNT: int = 48
# ③ 光尘 HUD 避让：屏幕坐标矩形（约 x<730、y<220），绘制时逐粒跳过。
#    FX 与 HUD 同处 SubViewport(640×360) 逻辑坐标，画布经 stretch_shrink=2 放大到 1280×720。
var hud_avoid_screen_w: float = 730.0
var hud_avoid_screen_h: float = 220.0
var logical_to_screen: float = 2.0
# R20 精修：把光尘圆点半径纳入避让判定（最大 size≈3 逻辑px ×2 = 6 屏幕px），
#   margin 只向外扩、不缩小冻结口径的 x<730 / y<220 矩形，避免粒子边缘擦进 HUD 面板。
var hud_avoid_margin_px: float = 6.0

# 倒影源：与 hd2d_placeholder.gd 一致的 32×32 像素实体色板索引阵列（内联常量，零外部素材）
# 锚点 (16,31)：脚底像素位于 py=31；字符 '0'-'9'/'a'-'f' -> 色板索引 0..15，'.' = 透明。
var ENTITY_ROWS: Array[String] = [
	"................................",
	"................................",
	"................................",
	"................................",
	".............aaaaaa.............",
	"............a888888a............",
	"............a888888a............",
	"............a222222a............",
	"...........a22222222a...........",
	"............a2a222aa............",
	"............a222222a............",
	"............a222222a............",
	".............a2222a.............",
	".........aaaa777777aaaa.........",
	".........a877777777778a.........",
	".........aa7777777777aa.........",
	".........a.a77777777a.a.........",
	".........a.a77777777a.a.........",
	".........a.a77777777a.a.........",
	".........a.a77777777a.a.........",
	".........a.affffffffa.a.........",
	".........a.a77777777a.a.........",
	".........a.a77777777a.a.........",
	".........a.a77777777a.a.........",
	"............a888888a............",
	"............a888888a............",
	"............a888888a............",
	"............a888888a............",
	"............a888888a............",
	"...........aaaaaaaaaa...........",
	"...........aaaaaaaaaa...........",
	"...........aaaaaaaaaa..........."
]

# 取色板：palette_256.json colors[0..15]（内联 hex，零外部素材、不加载 JSON / PNG）
var PALETTE_HEX: Array[String] = [
	"#FFF0C2", "#FFD27A", "#F0A94C", "#C97A2E", "#8A5A22",
	"#BFD0EA", "#7E96BF", "#4A6089", "#2B3A5C", "#16233F", "#0B1226",
	"#1F3A63", "#16294A", "#0E1B33", "#080F1F", "#E8C479"
]

var _palette: Array[Color] = []
var _motes_far: Array[Dictionary] = []    # 远景冷白光尘（确定性 seed）
var _motes_near: Array[Dictionary] = []   # 近景暖金光尘

# ---------------------------------------------------------------------------
# R34 / v0.11.0 · 连击评级反馈层（派单 cmd-20261112-091304-459-A4 ① · Rank-4）
# ---------------------------------------------------------------------------
# 目标：D/C/B/A/S 五档按「暖金强度 + 光尘密度」递进；S 级升档加一次短促暖金收束
#   爆发（无过曝）；受击 / 超时 / manual 重置时冷却到冷夜雾。零 GPU job、零付费、
#   零外部素材，全部落在 CanvasItem._draw() 内（draw_rect / draw_circle / draw_arc /
#   draw_string），与既有四项 2D 程序化光效同层叠加（FXBloom 分派最上层）。
#
# 【A54 裁决 · 唯一实例】订阅 Rank-2 ComboService 的 4 个公开信号，但绝不 new()
#   第二个 ComboService：经 wave_trial_director.gd 公开 get_combo_service() 取同一实例。
#   本层用 has_method("get_combo_service") 遍历场景树找导演节点（不依赖 /root 绝对路径、
#   不依赖 group、不读其私有实现），deferred 等导演 _ready() 装配完成后绑定，最多重试
#   COMBO_BIND_MAX_ATTEMPTS 帧；找不到 / 未接线 → 连击反馈层零绘制、静默降级，
#   既有 FXReflection / FXGodRays / FXMotes / FXBloom / impact_fx 照常（降级层保留）。
#
# 【口径登记（如实，不冒充）】00-协作契约.md §9.3 把程序化 _draw() 定位为「M0 占位与
#   显存不足时的降级、不是正式素材路线」；本层是【运行时视觉反馈层】（非替代正式像素
#   素材），按 R34 任务单「以任务单为准」特批用 _draw() 实现。ComfyUI / 本地程序化素材
#   仍是主美术路线，本层不宣称已能出图、不宣称真 3D 光效、不把 2D 近似包装成
#   「HD-2D 全绿已达成」（A30 / HD2D-STYLE-ANCHOR-v2 §0）。§9.3 口径差异列为待裁决项。
#
# 【色数口径不变】连击反馈层所有色号逐字复用本脚本既有 PALETTE_HEX 与既有 _draw()
#   已用 hex：暖金 #FFD27A / #F0A94C / #FFF0C2、冷夜雾 #2B3A5C / #4A6089 / #16233F、
#   冷亮 #BFD0EA —— 【零新增色号】，故单帧 ≤16 色受控口径与项目级色库 ≥256 色两层
#   口径（A15）均不变。暖金主光 #F0A94C / 冷夜雾 #2B3A5C 即 HD2D-STYLE-ANCHOR-v2 §8
#   登记的历史显示色（32 色板 L7 / L3），与 depth_profile.tres 显示口径一致、
#   不引入 v2 受控板新色、不冒充新色板（A32）。
#
# 【移动端不劣化】连击反馈绘制只在 _draw() 的 FXBloom 分派内、受既有 _all_on 门控：
#   mobile 四项全关时 _draw() 开头即 return → 连击层零绘制、零额外加载；计时器更新
#   亦只在 _all_on 且 FXBloom 节点执行。信号订阅为一次性（仅 FXBloom 节点），开销可忽略。
#   impact_fx 懒加载 / R20 强制档位覆盖 / HUD 避让矩形 / 四项降级层开关全部逐字保留。
#
# 【调参唯一入口 = 本节 [PLACEHOLDER] 常量表（只改表、不改算法）】；全部数值待人工
#   试玩校准，校准只改下表，不碰 _draw_combo_rank_fx / 信号回调 / 绑定逻辑。
#
# [PLACEHOLDER] 各档暖金强度 COMBO_RANK_GLOW {D:0 C:.10 B:.20 A:.32 S:.46}
#   rationale：D 级零额外暖金（0 连击不惩罚、不与既有 FXBloom 叠加）；逐档 +.10/.12/.14
#   把「暖金越浓 = 连击越高」做成单调可读梯度；S 封顶 .46 且所有暖金绘制 alpha 峰值
#   ≤.46、不画纯白核心、不叠乘既有 bloom 核心(#FFF0C2 a=.85)，防过曝（A41 目视项）。
# [PLACEHOLDER] 各档光尘密度 COMBO_RANK_MOTES {D:0 C:6 B:14 A:24 S:36}
#   rationale：与 ComboService 门槛 {0,4,8,14,22} 同量级递增（D 零粒子、S 36 ≤ 既有
#   MOTES_NEAR_COUNT=48 量级），确定性公式分布、硬边 1~2px 圆点，非随机噪点；
#   HUD 逐粒避让沿用既有 _is_hud_avoid。
# [PLACEHOLDER] S 收束爆发时长 COMBO_BURST_SEC=0.45（秒）
#   rationale：短促「收束」而非持续泛光；仅低 alpha 扩散环（峰值 .18）、无纯白核心，
#   不与升档闪光叠乘，避免 S 级过曝；由 rank_changed(to=="S") 触发一次。
# [PLACEHOLDER] 冷夜雾冷却时长 COMBO_COOLDOWN_SEC=0.90（秒）
#   rationale：受击 / 超时 / manual 重置后暖金退场、冷雾泛起的可辨窗口；底部冷雾横带
#   避开 HUD(x<365,y<110 逻辑) 与角色判定区(y<270)，与「暖金 × 冷夜雾」对冲一致。
# [PLACEHOLDER] COMBO_GLOW_LERP=8.0 / COMBO_MOTE_RISE=10.0 / COMBO_BIND_MAX_ATTEMPTS=90
#   rationale：暖金强度平滑趋近避免突变闪烁；光尘上飘速度与既有 FXMotes(2~6px/s)
#   同量级略快；绑定自愈窗口 = 3s@30fps，兼容导演装配时序，失败静默降级。
# ---------------------------------------------------------------------------
const COMBO_RANK_ORDER = ["D", "C", "B", "A", "S"]
const COMBO_RANK_GLOW = {"D": 0.0, "C": 0.10, "B": 0.20, "A": 0.32, "S": 0.46}
const COMBO_RANK_MOTES = {"D": 0, "C": 6, "B": 14, "A": 24, "S": 36}
const COMBO_BURST_SEC: float = 0.45
const COMBO_COOLDOWN_SEC: float = 0.90
const COMBO_GLOW_LERP: float = 8.0
const COMBO_MOTE_RISE: float = 10.0
const COMBO_BIND_MAX_ATTEMPTS: int = 90

# 连击反馈层运行期状态（仅 FXBloom 分派节点订阅 / 绘制；_combo_service 是只读引用）
var _combo_service: Object = null
var _combo_bind_attempts: int = 0
var _combo_rank: String = "D"
var _combo_count: int = 0
var _combo_mult: float = 1.0
var _combo_glow: float = 0.0
var _combo_burst: float = 0.0
var _combo_cooling: float = 0.0
var _combo_last_reset_reason: String = ""
var _combo_last_settle: Dictionary = {}


## R34 · 绑定唯一 ComboService（A54 复用 get_combo_service，绝不自建第二个实例）。
## 仅 FXBloom 节点在 _ready() 里 call_deferred 触发；装配时序未就绪时由 _process 自愈重试。
func _try_bind_combo() -> void:
	if _combo_service != null:
		return
	if _combo_bind_attempts >= COMBO_BIND_MAX_ATTEMPTS:
		return
	_combo_bind_attempts += 1
	var tree := get_tree()
	if tree == null:
		return
	var director := _find_node_with_method(tree.root, "get_combo_service")
	if director == null:
		return
	var svc: Object = director.call("get_combo_service")
	if svc == null:
		return
	_combo_service = svc
	var sigs := ["combo_changed", "rank_changed", "combo_reset", "combo_settled"]
	var cbs := ["_on_combo_changed", "_on_rank_changed", "_on_combo_reset", "_on_combo_settled"]
	for i in range(sigs.size()):
		if not svc.is_connected(sigs[i], Callable(self, cbs[i])):
			svc.connect(sigs[i], Callable(self, cbs[i]))
	print("[R34][ComboFX] 绑定唯一 ComboService 成功 node=%s signals=%d（A54 复用 get_combo_service，不自建）" % [
			str(name), sigs.size()])


## 只读遍历场景树找带公开方法的节点（不依赖绝对路径 / group / 私有实现）。
func _find_node_with_method(n: Node, m: String) -> Node:
	if n.has_method(m):
		return n
	for c in n.get_children():
		var r := _find_node_with_method(c, m)
		if r != null:
			return r
	return null


# ---- 4 个公开信号回调（签名真源：teamwork/Rank-2/DONE-R34.md §3.1）----
func _on_combo_changed(count: int, rank: String) -> void:
	_combo_count = count
	if COMBO_RANK_ORDER.has(rank):
		_combo_rank = rank


func _on_rank_changed(from_rank: String, to_rank: String, multiplier: float) -> void:
	if COMBO_RANK_ORDER.has(to_rank):
		_combo_rank = to_rank
	_combo_mult = multiplier
	# 升到 S：触发一次短促暖金收束爆发（无过曝：峰值 alpha 受控、不画纯白核心）
	if to_rank == "S" and from_rank != "S":
		_combo_burst = COMBO_BURST_SEC


func _on_combo_reset(reason: String) -> void:
	# 受击 / 超时 / Boss 定格 / manual 重置：冷却到冷夜雾（暖金归零）
	_combo_last_reset_reason = reason
	_combo_cooling = COMBO_COOLDOWN_SEC
	_combo_burst = 0.0
	_combo_count = 0
	_combo_rank = "D"
	_combo_mult = 1.0


func _on_combo_settled(total_points: int, base_points: int, rank: String, multiplier: float) -> void:
	# 结算定格评级（只读登记，不额外爆发，避免与 S 升档爆发叠加过曝）
	if COMBO_RANK_ORDER.has(rank):
		_combo_rank = rank
	_combo_mult = multiplier
	_combo_last_settle = {"total": total_points, "base": base_points,
			"rank": rank, "mult": multiplier}


## 计时器推进（只在 _all_on 且 FXBloom 节点执行；mobile 四项全关时零开销）。
func _update_combo_timers(delta: float) -> void:
	if _combo_cooling > 0.0:
		_combo_cooling = maxf(0.0, _combo_cooling - delta)
	if _combo_burst > 0.0:
		_combo_burst = maxf(0.0, _combo_burst - delta)
	var target: float = float(COMBO_RANK_GLOW.get(_combo_rank, 0.0))
	if _combo_cooling > 0.0:
		target = 0.0
	_combo_glow = lerpf(_combo_glow, target, clampf(COMBO_GLOW_LERP * delta, 0.0, 1.0))


## R34 · 连击评级反馈层绘制（仅由 _draw() 的 FXBloom 分派调用，最上层）。
## 未绑定 ComboService → 静默 return（既有四项光效 + impact_fx 照常，降级层保留）。
func _draw_combo_rank_fx(t: float) -> void:
	if _combo_service == null:
		return
	var font: Font = ThemeDB.fallback_font
	var rank_idx: int = maxi(0, COMBO_RANK_ORDER.find(_combo_rank))
	var glow: float = _combo_glow
	# ① 冷夜雾冷却（重置后）：底部低 alpha 冷雾横带，避开 HUD 与角色判定区
	if _combo_cooling > 0.0:
		var cold: float = clampf(_combo_cooling / COMBO_COOLDOWN_SEC, 0.0, 1.0)
		draw_rect(Rect2(0.0, 286.0, BUFFER_W, 8.0), _c("#4A6089", 0.06 * cold))
		for k in range(3):
			var by: float = 300.0 + float(k) * 18.0
			draw_rect(Rect2(0.0, by, BUFFER_W, 14.0),
					_c("#2B3A5C", (0.05 + 0.07 * cold) * (1.0 - float(k) * 0.25)))
	# ② 暖金光尘：密度按档递进，确定性硬边小圆点 + HUD 逐粒避让
	var mote_count: int = int(COMBO_RANK_MOTES.get(_combo_rank, 0))
	for i in range(mote_count):
		var mx: float = 250.0 + float((i * 37) % 140)
		var my: float = fposmod(170.0 + float((i * 53) % 100) - t * COMBO_MOTE_RISE, 130.0) + 150.0
		if _is_hud_avoid(mx, my):
			continue
		var mcol: String = "#FFF0C2" if i % 3 == 0 else "#FFD27A"
		draw_circle(Vector2(float(round(mx)), float(round(my))), 1.0 + float(i % 2),
				_c(mcol, 0.20 + 0.30 * glow))
	# ③ 评级条（右下空地，避开 HUD 面板 x<365,y<110 与角色判定区）
	var bar_x: float = 462.0
	var bar_y: float = 318.0
	draw_rect(Rect2(bar_x, bar_y, 162.0, 28.0), _c("#16233F", 0.55))
	draw_rect(Rect2(bar_x, bar_y, 162.0, 28.0), _c("#4A6089", 0.18), false, 1.0)
	var cell_w: float = 26.0
	for i in range(COMBO_RANK_ORDER.size()):
		var r: String = String(COMBO_RANK_ORDER[i])
		var cx: float = bar_x + 6.0 + float(i) * (cell_w + 4.0)
		var reached: bool = i <= rank_idx
		var is_current: bool = i == rank_idx
		if is_current and glow > 0.0:
			draw_rect(Rect2(cx - 2.0, bar_y + 2.0, cell_w + 4.0, 24.0),
					_c("#F0A94C", 0.10 + 0.28 * glow))
		var fill: Color
		if is_current:
			fill = _c("#FFD27A", 0.55 + 0.40 * glow)
		elif reached:
			fill = _c("#F0A94C", 0.45)
		else:
			fill = _c("#16233F", 0.85)
		draw_rect(Rect2(cx, bar_y + 4.0, cell_w, 20.0), fill)
		draw_rect(Rect2(cx, bar_y + 4.0, cell_w, 20.0), _c("#4A6089", 0.5), false, 1.0)
		if font != null:
			var lcol: Color = _c("#FFF0C2", 0.95) if is_current else _c("#BFD0EA", 0.7)
			draw_string(font, Vector2(cx + 8.0, bar_y + 18.0), r,
					HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, lcol)
	if font != null:
		var info: String = "%d HIT" % _combo_count
		if _combo_mult > 1.0:
			info += "  x%.2f" % _combo_mult
		draw_string(font, Vector2(bar_x + 4.0, bar_y - 4.0), info,
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, _c("#FFD27A", 0.85))
	# ④ S 级短促暖金收束爆发：仅低 alpha 扩散环，无纯白核心、无过曝
	if _combo_burst > 0.0:
		var p: float = 1.0 - clampf(_combo_burst / COMBO_BURST_SEC, 0.0, 1.0)
		var br: float = 10.0 + 34.0 * p
		var ba: float = 0.18 * (1.0 - p)
		draw_arc(Vector2(BUFFER_W * 0.5, GROUND_Y), br, 0.0, TAU, 32,
				_c("#F0A94C", ba), 2.0)
		draw_arc(Vector2(BUFFER_W * 0.5, GROUND_Y), br * 0.6, 0.0, TAU, 32,
				_c("#FFD27A", ba * 0.8), 1.0)


func _ready() -> void:
	_palette.clear()
	for h in PALETTE_HEX:
		_palette.append(Color(h))
	_build_motes()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_hud_avoid_meta()
	# R20 运行期强制档位：仅当显式设置环境变量 AIERDENG_FX_PROFILE=mobile 时激活。
	# courtyard.tscn 的 HD2DFX 根（Rank-1 独占 fx_profile_controller.gd）会在其
	# _ready() 里把 4 个 FX 子节点强制切回 desktop；故此处用 call_deferred 排队到
	# 本帧所有 _ready() 完成后再落到 mobile，并锁定档位忽略后续 desktop 请求。
	_force_profile = _read_forced_profile()
	if _force_profile == PROFILE_MOBILE:
		call_deferred("_apply_forced_mobile")
		print("[R20][%s] 强制档位=mobile（deferred 覆盖 controller 的 desktop）env=%s" % [
				str(name), ENV_FORCE_PROFILE])
	else:
		set_fx_profile(fx_profile)
		print("[R20][%s] 默认档位=%s（未请求覆盖，desktop 四项全开零回退）" % [
				str(name), fx_profile])
	# R34：连击评级反馈层 —— 仅 FXBloom 分派节点订阅唯一 ComboService（A54），
	# deferred 排在 WaveTrialDirector._ready() 装配完成之后；装配时序未就绪由 _process 自愈重试。
	if str(name) == "FXBloom":
		call_deferred("_try_bind_combo")


## 档位开关的公共入口：改档位并立即重算四项门 / 可见性（供 build 脚本回读真跑验证）。
## R20：强制 mobile 激活期间忽略外部（fx_profile_controller / 画质菜单）切回 desktop 的请求，
##       保证抓帧全程稳定停在 mobile；未激活时行为与 R18/R19 完全一致（47 PASS 不受影响）。
func set_fx_profile(profile: String) -> void:
	if _force_profile == PROFILE_MOBILE and profile == PROFILE_DESKTOP:
		print("[R20][%s] 忽略外部 set_fx_profile(desktop)：强制 mobile 锁定生效" % str(name))
		return
	fx_profile = profile
	_apply_profile()


## R20：读取运行期强制档位（环境变量；零外部依赖、Movie Maker 兼容）。
func _read_forced_profile() -> String:
	if OS.has_environment(ENV_FORCE_PROFILE):
		var v := OS.get_environment(ENV_FORCE_PROFILE).strip_edges().to_lower()
		if v == PROFILE_MOBILE or v == PROFILE_DESKTOP:
			return v
	return ""


## R20：deferred 落地（在所有 _ready() 之后），把本节点真正切到 mobile 四项全关。
func _apply_forced_mobile() -> void:
	set_fx_profile(PROFILE_MOBILE)
	print("[R20][%s] deferred 落地 set_fx_profile(mobile) | visible=%s _all_on=%s fx_profile=%s 四门=[%s %s %s %s]" % [
			str(name), str(visible), str(_all_on), fx_profile,
			str(_on_reflection), str(_on_godrays), str(_on_motes), str(_on_bloom)])


## R20：HUD 避让矩形可由 hd2d_fx.tscn 的 metadata 覆盖（场景级权威数据，脚本常量兜底）。
func _apply_hud_avoid_meta() -> void:
	if has_meta("hud_avoid_screen_w"):
		hud_avoid_screen_w = float(get_meta("hud_avoid_screen_w"))
	if has_meta("hud_avoid_screen_h"):
		hud_avoid_screen_h = float(get_meta("hud_avoid_screen_h"))


func _apply_profile() -> void:
	# 冻结口径（HD2D-FX-PLAN.md §4.2）：desktop 四项全开 / mobile 四项全关。
	# §4.3 的「移动降级而非全关」为待裁决建议，本轮不擅自实现（R15 已登记）。
	_all_on = (fx_profile == PROFILE_DESKTOP)
	_on_reflection = _all_on
	_on_godrays = _all_on
	_on_motes = _all_on
	_on_bloom = _all_on
	# mobile 整层不绘制；desktop 四项由节点名分派、按同层子节点顺序叠加
	visible = _all_on


func _build_motes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = PLACEHOLDER_SEED
	_motes_far.clear()
	for i in range(MOTES_FAR_COUNT):
		_motes_far.append({
			"x0": rng.randf_range(0.0, BUFFER_W),
			"y0": rng.randf_range(0.0, BUFFER_H),
			"phase": rng.randf_range(0.0, TAU),
			"freq": rng.randf_range(TAU / 4.0, TAU / 2.0),
			"speed": rng.randf_range(2.0, 6.0),
			"size": rng.randf_range(1.0, 3.0),
			"tone": i % 3
		})
	_motes_near.clear()
	for i in range(MOTES_NEAR_COUNT):
		_motes_near.append({
			"x0": rng.randf_range(0.0, BUFFER_W),
			"y0": rng.randf_range(0.0, BUFFER_H),
			"phase": rng.randf_range(0.0, TAU),
			"freq": rng.randf_range(TAU / 4.0, TAU / 2.0),
			"speed": rng.randf_range(2.0, 6.0),
			"size": rng.randf_range(1.0, 3.0),
			"tone": i % 3
		})


func _process(delta: float) -> void:
	# 逐帧重绘沿用 hd2d_placeholder.gd::_process 口径（光尘上飘 / 倒影波纹需逐帧）。
	# §4.4「静态层（体积光/bloom）仅档位变化时重绘 + 移动档节流」是给 Rank-1 的
	# 落地建议，本轮不擅自实现，如实登记为待接线项。
	if _all_on:
		# R34：连击反馈层计时器 + 绑定自愈（仅 FXBloom 节点；mobile 四项全关时零开销）
		if str(name) == "FXBloom":
			if _combo_service == null:
				_try_bind_combo()
			_update_combo_timers(delta)
		queue_redraw()


func _draw() -> void:
	if not _all_on:
		return
	var t := Time.get_ticks_msec() / 1000.0
	# 单节点内按 HD-2D视觉规范.md §10 层序绘制：fx_0_back(倒影/体积光) → fx_1_front(光尘/bloom)。
	# 独立场景由 4 个同名分派节点分担，各节点同处一个 CanvasLayer，靠子节点顺序叠加。
	match str(name):
		"FXReflection":
			if _on_reflection:
				_draw_reflection(t)
		"FXGodRays":
			if _on_godrays:
				_draw_godrays(t)
		"FXMotes":
			if _on_motes:
				_draw_motes(t)
		"FXBloom":
			if _on_bloom:
				_draw_bloom(t)
			_draw_impact_fx(t)   # R32：只读加载的 4 帧打击反馈（资源缺失则降级跳过）
			_draw_combo_rank_fx(t)  # R34：连击评级反馈层（未绑定 ComboService 则静默跳过）
		_:
			pass


# ---------------------------------------------------------------------------
# 共用辅助
# ---------------------------------------------------------------------------
func _c(hex_color: String, a: float) -> Color:
	var c := Color(hex_color)
	c.a = a
	return c


func _c_palette_alpha(idx: int, a: float) -> Color:
	var c := _palette[idx]
	c.a = a
	return c


func _hex_char_to_index(ch: String) -> int:
	return "0123456789abcdef".find(ch)


func _collect_entity_blocks() -> Array[Dictionary]:
	var blocks: Array[Dictionary] = []
	var origin_x := BUFFER_W * 0.5 - 16.0    # 锚点 x=16 对齐屏幕中心
	var origin_y := GROUND_Y - 31.0          # py=31 -> 屏幕 y=GROUND_Y
	for py in range(32):
		var row: String = ENTITY_ROWS[py]
		for px in range(32):
			var ch: String = row[px]
			if ch == ".":
				continue
			blocks.append({
				"x": origin_x + float(px),
				"y": origin_y + float(py),
				"idx": _hex_char_to_index(ch)
			})
	return blocks


# ---------------------------------------------------------------------------
# R18 ③ 光尘 HUD 避让：逻辑坐标 → 屏幕坐标判定（约 x<730、y<220）
#   FX / HUD 同处 SubViewport(640×360)，stretch_shrink=2 放大到 1280×720；
#   光尘会绘制在 HUD 之上（HD2DFX 与 Hud 同 layer=10、树序靠后），故绘制时逐粒跳过。
#   R20 精修：判定纳入光尘圆点半径（margin 只向外扩、不缩小 x<730 / y<220 矩形）。
# ---------------------------------------------------------------------------
func _is_hud_avoid(logical_x: float, logical_y: float) -> bool:
	var sx := logical_x * logical_to_screen
	var sy := logical_y * logical_to_screen
	return (sx < hud_avoid_screen_w + hud_avoid_margin_px) \
		and (sy < hud_avoid_screen_h + hud_avoid_margin_px)


# ---------------------------------------------------------------------------
# ① 湿地倒影：垂直镜像 2×2 半透明色块（HD2D-FX-PLAN.md §3.3 / 占位 step6）
#    R18：源块关于 GROUND_Y 向下翻转 + 压缩到脚下 + 深度渐隐 + 逐行波纹，
#         画成连片的镜像色块，而非 1×1 点被地面横砖淹没成的一条水平亮线。
# ---------------------------------------------------------------------------
func _draw_reflection(t: float) -> void:
	var blocks := _collect_entity_blocks()
	var cx := BUFFER_W * 0.5
	# [PLACEHOLDER] R31 冷夜雾湿地水面基底：离散冷蓝横带（越深越浓），只铺倒影区宽度
	var water_w := 60.0
	for k in range(reflection_water_bands):
		var wa := 0.05 + 0.035 * float(k)
		draw_rect(Rect2(float(round(cx - water_w * 0.5)),
				float(round(GROUND_Y + 2.0 + float(k) * 7.0)),
				water_w, 7.0), _c("#16233F", wa))
	# 水面高光横线：暖金 × 冷白交替（湿地对主光 / 夜雾的镜面反射，硬边 1px）
	for q in range(3):
		var wy := float(round(GROUND_Y + 6.0 + float(q) * 15.0))
		var hx := sin(t * 0.9 + float(q)) * 3.0
		draw_line(Vector2(float(round(cx - 30.0 + hx)), wy),
				Vector2(float(round(cx + 30.0 + hx)), wy), _c("#FFD27A", 0.10), 1.0)
		draw_line(Vector2(float(round(cx - 24.0 - hx)), wy + 2.0),
				Vector2(float(round(cx + 24.0 - hx)), wy + 2.0), _c("#BFD0EA", 0.07), 1.0)
	for b in blocks:
		var sy: float = float(b["y"])
		var y_mirror := 2.0 * GROUND_Y - sy - 1.0
		var y_ref := GROUND_Y + (y_mirror - GROUND_Y) * reflection_squash
		var depth := clampf((y_ref - GROUND_Y) / (31.0 * reflection_squash), 0.0, 1.0)
		var alpha := reflection_alpha * (1.0 - reflection_fade * depth)
		var ripple_dx := sin(t * 1.4 + y_ref * 0.35) * reflection_ripple * BUFFER_W
		draw_rect(Rect2(float(round(float(b["x"]) + ripple_dx)), float(round(y_ref)),
					reflection_block_px, reflection_block_px),
				_c_palette_alpha(int(b["idx"]), alpha))
		# 深层叠冷夜雾：把暖金倒影压进冷蓝水面（暖金 × 冷夜雾分离）
		if depth > 0.35:
			draw_rect(Rect2(float(round(float(b["x"]) + ripple_dx)), float(round(y_ref)),
					reflection_block_px, reflection_block_px),
					_c("#4A6089", reflection_cold_tint * depth * alpha))


# ---------------------------------------------------------------------------
# ② 体积光：draw_colored_polygon ×6 + draw_line 中心高光（HD2D-FX-PLAN.md §3.1 / step5）
#    R18：层数 4→6、spread 递进更密、峰值 alpha 保持 0.18 不抬高（不糊画面），
#         另补「柔核 + 亮核」两道暖金中心高光带强化主光方向。
# ---------------------------------------------------------------------------
func _draw_godrays(_t: float) -> void:
	var bottom := GROUND_Y + 30.0
	for i in range(godray_layers):
		var spread := godray_spread_base + float(i) * godray_spread_step
		var poly := PackedVector2Array([
			LIGHT_POS,
			Vector2(LIGHT_POS.x - spread, bottom),
			Vector2(LIGHT_POS.x + spread, bottom)
		])
		# _draw() 无逐调用 Add 混合参数，用低 alpha 多次叠加近似径向光束衰减
		draw_colored_polygon(poly, _c("#FFD27A", godray_alpha[i]))
	# 中心高光带：较宽柔核 + 锐利亮核（只在暖金主光方向，不铺满画面）
	draw_line(LIGHT_POS, Vector2(LIGHT_POS.x, bottom), _c("#FFD27A", 0.16), 3.0)
	draw_line(LIGHT_POS, Vector2(LIGHT_POS.x, bottom), _c("#FFF0C2", 0.12), 1.0)


# ---------------------------------------------------------------------------
# ③ 光尘：draw_circle()，seed=PLACEHOLDER_SEED 固定（HD2D-FX-PLAN.md §3.2 / step5+8）
#    R18/R20：绘制时逐粒跳过 HUD 矩形（约 x<730、y<220），避免面板被点状遮挡。
# ---------------------------------------------------------------------------
func _draw_motes(t: float) -> void:
	for m in _motes_far:
		var y := fposmod(float(m["y0"]) - float(m["speed"]) * t, BUFFER_H)
		var x := float(m["x0"]) + sin(t * float(m["freq"]) + float(m["phase"])) * 3.0
		if _is_hud_avoid(x, y):
			continue
		# 金线深蓝：远景冷白为主，每 3 粒嵌 1 粒深蓝靛，拉开平滑景深冷色层次
		var far_hex := "#BFD0EA"
		if int(m["tone"]) == 1:
			far_hex = "#4A6089"
		draw_circle(Vector2(float(round(x)), float(round(y))), float(m["size"]), _c(far_hex, 0.25))
	for m in _motes_near:
		var y := fposmod(float(m["y0"]) - float(m["speed"]) * t, BUFFER_H)
		var x := float(m["x0"]) + sin(t * float(m["freq"]) + float(m["phase"])) * 3.0
		if _is_hud_avoid(x, y):
			continue
		# 暖金近景：每 3 粒嵌 1 粒浅金高光，与冷夜雾远景形成暖金 × 冷夜强对比
		var near_hex := "#FFD27A"
		if int(m["tone"]) == 1:
			near_hex = "#FFF0C2"
		draw_circle(Vector2(float(round(x)), float(round(y))), float(m["size"]), _c(near_hex, 0.45))


# ---------------------------------------------------------------------------
# ④ bloom 近似：同心圆 ×5 + 暖金核心（HD2D-FX-PLAN.md §3.4 / 占位 step8）
#    只让 warm_gold_key 过阈（threshold≈0.95 的几何近似）；冷夜雾区不放置任何光晕。
# ---------------------------------------------------------------------------
func _draw_bloom(_t: float) -> void:
	var radii: Array[float] = [4.0, 8.0, 14.0, 22.0, 32.0]
	var alphas: Array[float] = [0.20, 0.12, 0.07, 0.04, 0.02]
	for i in range(radii.size()):
		draw_circle(LIGHT_POS, radii[i], _c("#FFD27A", alphas[i]))
	draw_circle(LIGHT_POS, 3.0, _c("#FFF0C2", 0.85))          # L8 96% 核心过阈


# ---------------------------------------------------------------------------
# R32 ② · impact_fx.png 只读加载（懒加载，仅 desktop 绘制路径触发）
#   FileAccess.get_file_as_string 为只读；load() 为只读资源加载；
#   任一环节失败 → _impact_sheet 保持 null，_draw_impact_fx() 静默跳过，
#   既有四项程序化光效照常（降级层保留），不 push_error、不崩。
# ---------------------------------------------------------------------------
func _ensure_impact_loaded() -> void:
	if _impact_load_attempted:
		return
	_impact_load_attempted = true
	if not FileAccess.file_exists(IMPACT_IMPORT_PATH):
		return
	var txt := FileAccess.get_file_as_string(IMPACT_IMPORT_PATH)
	if txt.is_empty():
		return
	var parser := JSON.new()
	if parser.parse(txt) != OK or not (parser.data is Dictionary):
		return
	_impact_import = parser.data
	if not ResourceLoader.exists(IMPACT_PNG_PATH):
		return
	_impact_sheet = load(IMPACT_PNG_PATH) as Texture2D
	if _impact_sheet != null:
		print("[R32][impact_fx] 只读加载成功 png=%s frames=%d fw=%d cols=%d palette_id=%s" % [
				IMPACT_PNG_PATH, int(_impact_import.get("frame_count", 4)),
				int(_impact_import.get("frame_width", 128)), int(_impact_import.get("columns", 4)),
				str(_impact_import.get("palette_id", "?"))])
	else:
		print("[R32][impact_fx] 降级：PNG 不可加载，保留既有四项程序化光效")


# R32 ② · 4 帧冲击环叠加（复用既有 FXBloom 分派，不新增节点 / 不改节点名）
#   帧参数全部取自 import.json（frame_width / frame_height / columns / frame_count / actions[0].fps）；
#   绘制区固定在角色左侧空地（逻辑 640×360），避开 HUD 矩形 x<365,y<110 与角色判定区；
#   96×96 为运行时绘制尺寸（非素材降采样），texture_filter=Nearest 保硬边。
func _draw_impact_fx(t: float) -> void:
	if not impact_fx_enabled:
		return
	_ensure_impact_loaded()
	if _impact_sheet == null or _impact_import.is_empty():
		return
	var fw: float = float(_impact_import.get("frame_width", 128))
	var fh: float = float(_impact_import.get("frame_height", 128))
	var cols: int = maxi(1, int(_impact_import.get("columns", 4)))
	var n: int = maxi(1, int(_impact_import.get("frame_count", 4)))
	var fps: float = 12.0
	var actions: Array = _impact_import.get("actions", [])
	if actions.size() > 0 and actions[0] is Dictionary:
		fps = maxf(1.0, float((actions[0] as Dictionary).get("fps", 12.0)))
	# [PLACEHOLDER] 演示节奏：按 import.json 的 fps 循环 4 帧，保证 15s 录屏全段可见；
	#   import.json 的 loop=false 为资产单次播放语义，运行时循环待试玩校准。
	var idx: int = int(t * fps) % n
	var col: int = idx % cols
	var row: int = int(idx / cols)
	var src := Rect2(float(col) * fw, float(row) * fh, fw, fh)
	var dst := Rect2(200.0, 150.0, 96.0, 96.0)
	draw_texture_rect_region(_impact_sheet, dst, src, Color(1.0, 1.0, 1.0, impact_fx_alpha))
