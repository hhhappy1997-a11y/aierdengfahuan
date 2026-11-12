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
##
## R35 / v0.12.0 追加（派单 cmd-20261112-125821-147-A4 ① · Rank-4）：
##   ⑨ 精准弹反视觉反馈层：订阅 Rank-2 ParryService 的 4 个公开信号
##      （parry_window_opened(window_sec) / parry_succeeded(poise_bonus, points_bonus,
##       combo_keep) / parry_failed(reason, fail_penalty) / parry_window_closed(reason)，
##       签名真源 teamwork/Rank-2/DONE-R35.md §3.1），在既有 FXBloom 分派节点 _draw()
##       最上层叠加：① 可弹反窗口金色预兆环（随 window_sec 收紧读秒，低 alpha 不过曝）；
##       ② 成功弹反瞬间「冷蓝 → 暖金」短促冲击闪光（两段既有色号交替，无连续插值 /
##       无纯白大核心 / 不叠乘既有 bloom）；③ 失败回落冷夜雾横带 + 环收起。
##       全部程序化 _draw()（draw_arc / draw_circle / draw_rect），零 GPU job / 零付费 /
##       零外部素材 / 零新增节点。
##      【A54】经 wave_trial_director.gd 公开 get_parry_service() 复用「唯一」ParryService
##      实例（与 R34 连击层同款 _find_node_with_method 遍历），绝不自建第二个、不读私有
##      实现；未接线则静默降级（既有四项光效 + R32 impact_fx + R34 连击层照常）。
##      单帧 ≤16 色受控 / 项目级 ≥256 色两层口径不变：弹反层【零新增色号】，逐字复用
##      本脚本既有 _draw / PALETTE_HEX 已用 hex（暖金 #F0A94C / #FFD27A / #FFF0C2、
##      冷蓝 #BFD0EA、冷夜雾 #2B3A5C / #4A6089 / #16233F）。
##      移动端不劣化：受既有 _all_on 门控（mobile 四项全关 _draw() 直接 return → 弹反层
##      零绘制），计时器 / 绑定自愈只在 desktop + FXBloom 分派节点执行。
##      完整 [PLACEHOLDER] 数值表 / rationale 见下方「R35 精准弹反反馈层」块。
##
## R35B / v0.12.1 追加（派单 cmd-20261112-142648-353-A4 · Rank-4）：
##   ⑩ 弹反视觉收敛（修「弹反窗口期半透明浅色大矩形」本轮新回归）：
##      · 定位：v110/v120 同帧像素差分 + SEG-A/B/C 分段目视 —— 该浅色大矩形只在
##        SEG-A（desktop/medium, 2x 放大）出现，SEG-B（mobile 四项全关、FX 零绘制）
##        与 SEG-C（desktop/high，FX 逻辑 640×360 坐标缩在左上 1/4）均无 → 来自本
##        FX 层，不是 HUD 文字提示框 / 抉择卡片底板 / 地面贴图本身。具体为
##        _draw_godrays() 6 层暖金半透明大三角（底边宽约 380 逻辑px，2x 后铺满中景）
##        + 弹反 / 连击层的全宽 draw_rect(Rect2(0,...,BUFFER_W,...)) 半透明横带，
##        叠在 R35 变亮的规整错缝石板地面上，压低地面与角色对比度；v110 深色
##        Voronoi 地面不显现，故为「本轮新回归」。
##      · a) 移除 / 缩小半透明大矩形底板：体积光扇形收束为窄光束（spread 缩小、
##        峰值 alpha 不抬高）；弹反失败 / 连击冷却的全宽横带改为围绕角色的局部收环 /
##        局部短带，不再 draw_rect 全宽铺中景。
##      · b) 金色预兆环改为「围绕角色 / Boss 的局部环」：环心由 PARRY_RING_ANCHOR
##        常量表给出（[PLACEHOLDER] + rationale），半径仍在 28~44 逻辑px 的局部量级。
##      · c) 成功闪光保持 PARRY_FLASH_SEC=0.36 短促 + 峰值 alpha ≤0.42 + 无纯白大核心。
##      · d) mobile 四项全关档位【轻量降级绘制】：不再 _draw() 开头直接 return，
##        改为仅 FXBloom 节点画「轻量环 + 既有 HUD 文字」；四项光效 / impact_fx /
##        连击层 / 全宽横带仍全关（移动端不劣化 ≠ 完全不绘制）。SEG-B 切换点
##        (frame=150) 也能看到弹反反馈。
##      · e) 零新增色号：全部逐字复用既有 PALETTE_HEX / _draw 已用 hex；单帧 ≤16 色
##        受控 + 项目级 ≥256 色色库两层口径不变。
##      · HUD 文字提示框（hud.gd 的 ProdParryLabel / 抉择卡片等，Rank-1 独占只读）
##        逐字不动：已被总指挥确认可读、位置合适。
##      · 完整 [PLACEHOLDER] 数值表 / rationale 见下方「R35B 弹反视觉收敛」块。

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
#    R35B 收敛：R18 的 spread 40→190（底边宽 380 逻辑px / 2x 后 760 屏幕px）是
#    「弹反窗口期半透明浅色大矩形铺满中景」的主因 —— 6 层暖金大三角叠在 R35 变亮的
#    规整石板上，把地面与角色压成一片浅暖灰。本轮把扇形收束为窄光束，只照亮光源
#    附近的局部区域，不再铺满中景；峰值 alpha 与层数 / 中心高光带逐字保留不改。
# [PLACEHOLDER] R35B 收束值 spread_base=20.0 / spread_step=10.0（外层 70.0 逻辑px）
#   rationale：底边宽 140 逻辑px（2x 后 280 屏幕px，约为原 760 的 37%），光束仍可辨
#   为「暖金主光」但不再横铺中景；逐层 +10 递进保留 6 层径向衰减层次；与 R34 S 爆发
#   环 / R35 弹反环（半径 28~56 逻辑px）同量级，保证「暖金 × 冷夜雾」强对比仍在、
#   不抬高任何 alpha（防过曝 A41）、零新增色号。调参唯一入口 = 本节两常量。
var godray_layers: int = 6
var godray_alpha: Array[float] = [0.18, 0.14, 0.10, 0.07, 0.045, 0.025]
var godray_spread_base: float = 20.0
var godray_spread_step: float = 10.0
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

# ---------------------------------------------------------------------------
# R35 / v0.12.0 · 精准弹反反馈层（派单 cmd-20261112-125821-147-A4 ① · Rank-4）
# ---------------------------------------------------------------------------
# 目标：订阅 Rank-2 ParryService 4 个公开信号（A54 唯一实例、不自建、不读私有实现），
#   在 FXBloom 分派节点 _draw() 最上层叠加三层 2D 程序化反馈：
#     ① 可弹反窗口「金色预兆环」：随 window_sec 从外半径 BASE_R 收紧到 MIN_R，
#        环上等分刻度按剩余比例逐格熄灭读秒；暖金低 alpha、无纯白核心、不过曝。
#     ② 成功弹反「冷蓝 → 暖金」短促冲击闪光：按时间进度分两段（前 COLD_RATIO 冷蓝
#        #BFD0EA 扩散环 → 后段暖金 #FFD27A/#F0A94C 扩散环 + 低 alpha 亮核），
#        仅两段既有色号交替、不做连续 RGB 插值（避免派生新色号、守零新增色号口径），
#        峰值 alpha ≤ PARRY_FLASH_ALPHA、不叠乘既有 FXBloom 核心、短促收束。
#     ③ 失败回落「冷夜雾」：底部低 alpha 冷蓝横带（避开 HUD 矩形 x<365,y<110 与角色
#        判定区）+ 一个快速淡出的暗色环把预兆收起，与「暖金 × 冷夜雾」对冲一致。
#   窗口关闭（parry_window_closed）立即收起预兆环；成功 / 失败信号各自起独立计时器。
#
# 【A54 唯一实例】与 R34 连击层同款：_try_bind_parry() 用 has_method("get_parry_service")
#   遍历场景树找 WaveTrialDirector，经公开 get_parry_service() 取唯一 ParryService，
#   connect 4 个公开信号；绝不 new() 第二个、不读私有实现、不依赖 /root 绝对路径 /
#   group。deferred 等导演 _ready() 装配完成后绑定，_process 自愈重试上限
#   PARRY_BIND_MAX_ATTEMPTS；未接线 → _draw_parry_fx() 静默 return（降级层保留），
#   既有 FXReflection/FXGodRays/FXMotes/FXBloom + impact_fx + 连击层照常。
#
# 【A48① 生产订阅者】本层即生产运行时订阅者（挂在 courtyard.tscn 的 FXBloom 节点、
#   非验证脚本）：真实玩家输入 → 生产链路开窗 / 弹反 → ParryService 发信号 → 本层
#   绘制到画面。Rank-1 已交付「450 帧开窗 3 次、一次成功弹反自然出现」，本层在
#   录屏画面中据此可见；不新建只读探针 / 巡检脚本。
#
# 【色数口径不变 · 零新增色号】全部色号逐字复用既有 _draw / PALETTE_HEX 已用 hex：
#   暖金 #F0A94C / #FFD27A / #FFF0C2、冷蓝 #BFD0EA、冷夜雾 #2B3A5C / #4A6089 /
#   #16233F —— 均为 R34 连击层 / 四项光效已在用色号，单帧 ≤16 色受控 + 项目级
#   ≥256 色两层口径（A15）均不变；暖金 #F0A94C / 冷夜雾 #2B3A5C 即锚点 v2 §8
#   登记的历史显示色（32 色板 L7/L3），不引入 v2 受控板新色、不冒充新色板（A32）。
#
# 【移动端不劣化】R35 原口径：绘制只在 _draw() 的 FXBloom 分派内、受 _all_on 门控，
#   mobile 四项全关时 _draw() 开头即 return → 弹反层零绘制。
#   【R35B 修订，见文件头 ⑩】本轮按任务单 d) 改为 mobile 档给轻量降级绘制（轻量环
#   + 既有 HUD 文字），不再 _draw() 直接 return；计时器 / 绑定自愈仍在 FXBloom 执行。
#
# 【调参唯一入口 = 本节 [PLACEHOLDER] 常量表（只改表、不改算法）】；全部强度 / 时长
#   数值待人工试玩校准，校准只改下表，不碰 _draw_parry_fx / 信号回调 / 绑定逻辑。
#   强度 / 时长逐项 rationale：
# [PLACEHOLDER] PARRY_RING_BASE_R=44.0 / PARRY_RING_MIN_R=28.0（逻辑 px）·
#   rationale：环套在中央骑士外围（判定区约 x 288~352 / GROUND_Y=250），外半径 44
#   不压角色本体、内收 28 让「窗口收紧」可读；与 R34 S 爆发环 (br 10→44) 同量级。
# [PLACEHOLDER] PARRY_RING_ALPHA=0.40 / PARRY_RING_WIDTH=2.0 / PARRY_RING_TICKS=12 ·
#   rationale：金色环峰值 alpha .40（不画纯白核心、不叠乘既有 bloom 核心 a=.85，防
#   过曝 A41）；2px 硬边弧、12 格确定性读秒刻度（非随机噪点），随剩余比例熄灭。
# [PLACEHOLDER] PARRY_FLASH_SEC=0.36（秒）·
#   rationale：短促「冲击」而非持续泛光；与 Rank-2 window_sec=0.35 [PLACEHOLDER]
#   同量级、略长 0.01s 让成功瞬间完整收束，不与连击 S 爆发(0.45s)叠乘过曝。
# [PLACEHOLDER] PARRY_FLASH_ALPHA=0.42 / PARRY_FLASH_R0=16.0 / PARRY_FLASH_R1=56.0 /
#   PARRY_FLASH_COLD_RATIO=0.40 ·
#   rationale：峰值 alpha .42 ≤ 连击层封顶 .46，不画纯白大核心；扩散环 16→56 与
#   S 爆发 10→44 同量级略外扩；前 40% 冷蓝、后 60% 暖金做「冷蓝→暖金」两段交替。
# [PLACEHOLDER] PARRY_FAIL_SEC=0.55（秒）/ PARRY_FAIL_ALPHA=0.20 ·
#   rationale：失败后暖金退场、冷雾泛起的可辨窗口；底部冷雾横带避开 HUD
#   (x<365,y<110 逻辑) 与角色判定区 (y<270)，alpha .20 低于 R34 冷却带、不压暗画面。
# [PLACEHOLDER] PARRY_BIND_MAX_ATTEMPTS=90 ·
#   rationale：绑定自愈窗口 = 3s@30fps，兼容导演装配时序，失败静默降级（同 R34）。
# ---------------------------------------------------------------------------
const PARRY_RING_BASE_R: float = 44.0
const PARRY_RING_MIN_R: float = 28.0
const PARRY_RING_ALPHA: float = 0.40
const PARRY_RING_WIDTH: float = 2.0
const PARRY_RING_TICKS: int = 12
const PARRY_FLASH_SEC: float = 0.36
const PARRY_FLASH_ALPHA: float = 0.42
const PARRY_FLASH_R0: float = 16.0
const PARRY_FLASH_R1: float = 56.0
const PARRY_FLASH_COLD_RATIO: float = 0.40
const PARRY_FAIL_SEC: float = 0.55
const PARRY_FAIL_ALPHA: float = 0.20
const PARRY_BIND_MAX_ATTEMPTS: int = 90

# ---------------------------------------------------------------------------
# R35B · 弹反视觉收敛 [PLACEHOLDER] 常量表（调参唯一入口，只改表不改算法）
# ---------------------------------------------------------------------------
# [PLACEHOLDER] 局部金色预兆环环心 PARRY_RING_ANCHOR_PLAYER=(320,250) / _BOSS=(386,168)
#   rationale：环必须【只围绕角色或 Boss】，不再铺满中景。PLAYER 锚点沿用既有
#   GROUND_Y=250 / BUFFER_W*0.5=320 的中央骑士脚底判定区（屏幕 640,500），即 R35
#   原环心；BOSS 锚点取 courtyard 中 Boss 像素精灵躯干中心（逻辑约 386,168 → 屏幕
#   772,336，与录屏中 Boss 位置一致）。两者都是「局部」锚点，半径仍在 28~44 逻辑px
#   （PARRY_RING_MIN_R / BASE_R），不 draw_rect 全屏 / 不铺中景。
#   [PLACEHOLDER] 待人工试玩校准：若 Boss 节点坐标变化，只改此表两个 Vector2。
const PARRY_RING_ANCHOR_PLAYER: Vector2 = Vector2(320.0, 250.0)
const PARRY_RING_ANCHOR_BOSS: Vector2 = Vector2(386.0, 168.0)
# [PLACEHOLDER] 轻量降级环 PARRY_LITE_RING_R=30.0 / PARRY_LITE_ALPHA=0.34 /
#   PARRY_LITE_FLASH_ALPHA=0.30 · rationale：mobile 四项全关档位只画一个 2px 暖金
#   环 + 一个短促扩散环（零四项光效 / 零 impact_fx / 零连击层 / 零全宽横带），
#   alpha 峰值 0.34 ≤ 既有 PARRY_RING_ALPHA=0.40，不画纯白核心、不过曝；半径 30
#   与 PARRY_RING_MIN_R=28 同量级，围绕角色局部，SEG-B 切换点 (frame=150) 也能看到
#   弹反反馈（「移动端不劣化」≠「完全不绘制」）。色号逐字复用既有 #F0A94C /
#   #FFD27A / #FFF0C2 / #BFD0EA，零新增色号。
const PARRY_LITE_RING_R: float = 30.0
const PARRY_LITE_ALPHA: float = 0.34
const PARRY_LITE_FLASH_ALPHA: float = 0.30

# 弹反反馈层运行期状态（仅 FXBloom 分派节点订阅 / 绘制；_parry_service 是只读引用）
var _parry_service: Object = null
var _parry_bind_attempts: int = 0
var _parry_window_open: bool = false
var _parry_window_total: float = 0.35
var _parry_window_left: float = 0.0
var _parry_flash_left: float = 0.0
var _parry_fail_left: float = 0.0
var _parry_last_close_reason: String = ""
var _parry_last_success: Dictionary = {}


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
	# ① 冷夜雾冷却（重置后）：R35B 收敛 —— 原 4 条全宽 draw_rect(BUFFER_W) 半透明
	#    横带是「铺满中景的半透明大矩形底板」之一，改为【围绕角色脚下的局部短带】
	#    （宽 ≤120 逻辑px、居中于 PARRY_RING_ANCHOR_PLAYER.x）+ 一个局部收环，
	#    保留「暖金退场 / 冷雾泛起」语义但不再横铺全屏、不压低地面与角色对比度。
	if _combo_cooling > 0.0:
		var cold: float = clampf(_combo_cooling / COMBO_COOLDOWN_SEC, 0.0, 1.0)
		var local_x: float = PARRY_RING_ANCHOR_PLAYER.x - 60.0
		draw_rect(Rect2(local_x, 286.0, 120.0, 6.0), _c("#4A6089", 0.10 * cold))
		for k in range(3):
			var by: float = 300.0 + float(k) * 14.0
			draw_rect(Rect2(local_x + float(k) * 8.0, by, 104.0, 8.0),
					_c("#2B3A5C", (0.08 + 0.10 * cold) * (1.0 - float(k) * 0.28)))
		draw_arc(PARRY_RING_ANCHOR_PLAYER, 36.0 + 8.0 * cold, 0.0, TAU, 32,
				_c("#16233F", 0.20 * cold), 1.0)
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


## R35 · 绑定唯一 ParryService（A54 复用 get_parry_service，绝不自建第二个实例）。
## 仅 FXBloom 节点在 _ready() 里 call_deferred 触发；装配时序未就绪时由 _process 自愈重试。
func _try_bind_parry() -> void:
	if _parry_service != null:
		return
	if _parry_bind_attempts >= PARRY_BIND_MAX_ATTEMPTS:
		return
	_parry_bind_attempts += 1
	var tree := get_tree()
	if tree == null:
		return
	var director := _find_node_with_method(tree.root, "get_parry_service")
	if director == null:
		return
	var svc: Object = director.call("get_parry_service")
	if svc == null:
		return
	var sigs := ["parry_window_opened", "parry_succeeded", "parry_failed", "parry_window_closed"]
	var cbs := ["_on_parry_window_opened", "_on_parry_succeeded", "_on_parry_failed", "_on_parry_window_closed"]
	# 降级层开关：4 信号任一缺失（Rank-2 并发半成品中间态）→ 不绑定、静默降级，
	# 既不对不存在的信号 connect 产生 ERROR，也不影响既有四项光效 / impact_fx / 连击层。
	for s in sigs:
		if not svc.has_signal(s):
			return
	_parry_service = svc
	for i in range(sigs.size()):
		if not svc.is_connected(sigs[i], Callable(self, cbs[i])):
			svc.connect(sigs[i], Callable(self, cbs[i]))
	print("[R35][ParryFX] 绑定唯一 ParryService 成功 node=%s signals=%d（A54 复用 get_parry_service，不自建）" % [
			str(name), sigs.size()])


# ---- R35 · 4 个公开信号回调（签名真源：teamwork/Rank-2/DONE-R35.md §3.1）----
func _on_parry_window_opened(window_sec: float) -> void:
	# 可弹反窗口开启：金色预兆环从 window_sec 起收紧读秒；成功 / 失败闪光先收起。
	_parry_window_total = maxf(0.01, float(window_sec))
	_parry_window_left = _parry_window_total
	_parry_window_open = true
	_parry_flash_left = 0.0
	_parry_fail_left = 0.0


func _on_parry_succeeded(poise_bonus: float, points_bonus: int, combo_keep: bool) -> void:
	# 成功弹反：触发「冷蓝 → 暖金」短促冲击闪光；payload 只读登记供飘字 / 对账。
	_parry_window_open = false
	_parry_window_left = 0.0
	_parry_flash_left = PARRY_FLASH_SEC
	_parry_fail_left = 0.0
	_parry_last_success = {"poise": poise_bonus, "points": points_bonus, "combo_keep": combo_keep}


func _on_parry_failed(reason: String, fail_penalty: int) -> void:
	# 失败（timeout / move_landed）：回落冷夜雾 + 收起预兆环；fail_penalty 只读登记。
	_parry_window_open = false
	_parry_window_left = 0.0
	_parry_flash_left = 0.0
	_parry_fail_left = PARRY_FAIL_SEC
	_parry_last_close_reason = reason


func _on_parry_window_closed(reason: String) -> void:
	# 窗口关闭（success / timeout / move_landed / boss_defeated / manual）：收起预兆环。
	_parry_window_open = false
	_parry_window_left = 0.0
	_parry_last_close_reason = reason


## R35 / R35B · 计时器推进（desktop 四项全开 + mobile 轻量降级，均只在 FXBloom 节点执行；
##   mobile 其余三项 / 其它节点零开销）。
func _update_parry_timers(delta: float) -> void:
	if _parry_window_left > 0.0:
		_parry_window_left = maxf(0.0, _parry_window_left - delta)
	if _parry_flash_left > 0.0:
		_parry_flash_left = maxf(0.0, _parry_flash_left - delta)
	if _parry_fail_left > 0.0:
		_parry_fail_left = maxf(0.0, _parry_fail_left - delta)


## R35 / R35B · 精准弹反视觉反馈绘制（仅由 _draw() 的 FXBloom 分派调用，最上层）。
## 未绑定 ParryService → 静默 return（既有四项光效 + impact_fx + 连击层照常，降级层保留）。
## R35B 收敛：全部反馈改为【围绕角色 / Boss 的局部环 + 短促闪光】，不再 draw_rect
##   全宽半透明横带铺中景（本轮半透明浅色大矩形的来源之一）。环心由 [PLACEHOLDER]
##   常量表 PARRY_RING_ANCHOR_PLAYER / _BOSS 给出，半径 28~56 逻辑px 均为局部量级。
func _draw_parry_fx(_t: float) -> void:
	if _parry_service == null:
		return
	# 预兆环 / 失败收环围绕【角色】；成功冲击闪光围绕【Boss】—— 均局部锚点，不铺中景。
	var center := PARRY_RING_ANCHOR_PLAYER
	var boss_center := PARRY_RING_ANCHOR_BOSS
	# ③ 失败回落冷夜雾：R35B 把原 4 条全宽 draw_rect(BUFFER_W) 半透明横带移除，
	#    只保留围绕角色的【局部暗色收环】+ 一小段局部冷雾短带，不横铺全屏。
	if _parry_fail_left > 0.0:
		var frac: float = clampf(_parry_fail_left / PARRY_FAIL_SEC, 0.0, 1.0)
		draw_rect(Rect2(center.x - 52.0, 292.0, 104.0, 6.0),
				_c("#4A6089", 0.10 * frac))
		var fr: float = PARRY_RING_BASE_R + 8.0 * (1.0 - frac)
		draw_arc(center, fr, 0.0, TAU, 32, _c("#16233F", 0.30 * frac), 1.0)
	# ① 可弹反窗口金色预兆环（围绕角色）：半径随 window_left 从 BASE_R 收到 MIN_R，刻度读秒
	if _parry_window_open and _parry_window_left > 0.0:
		var wr: float = clampf(_parry_window_left / _parry_window_total, 0.0, 1.0)
		var ring_r: float = PARRY_RING_MIN_R + (PARRY_RING_BASE_R - PARRY_RING_MIN_R) * wr
		draw_arc(center, ring_r, 0.0, TAU, 48, _c("#F0A94C", PARRY_RING_ALPHA), PARRY_RING_WIDTH)
		draw_arc(center, ring_r - 4.0, 0.0, TAU, 48,
				_c("#FFD27A", PARRY_RING_ALPHA * 0.45), 1.0)
		# 12 格确定性读秒刻度：按剩余比例逐格熄灭（硬边短弧，非随机噪点）
		var lit: int = mini(PARRY_RING_TICKS, int(float(PARRY_RING_TICKS) * wr) + 1)
		for k in range(PARRY_RING_TICKS):
			if k >= lit:
				continue
			var a0: float = TAU * float(k) / float(PARRY_RING_TICKS)
			var a1: float = a0 + TAU / float(PARRY_RING_TICKS) * 0.55
			draw_arc(center, ring_r + 4.0, a0, a1, 4,
					_c("#FFF0C2", PARRY_RING_ALPHA * 0.85), 1.0)
	# ② 成功弹反「冷蓝 → 暖金」短促冲击闪光（围绕 Boss）：PARRY_FLASH_SEC=0.36 短促、
	#    峰值 alpha ≤ PARRY_FLASH_ALPHA=0.42、两段既有色号交替、无连续插值 / 无纯白大核心。
	if _parry_flash_left > 0.0:
		var p: float = 1.0 - clampf(_parry_flash_left / PARRY_FLASH_SEC, 0.0, 1.0)
		var fade: float = 1.0 - p
		var flash_r: float = PARRY_FLASH_R0 + (PARRY_FLASH_R1 - PARRY_FLASH_R0) * p
		if p < PARRY_FLASH_COLD_RATIO:
			# 前段冷蓝：扩散环 + 低 alpha 冷亮核
			draw_arc(boss_center, flash_r, 0.0, TAU, 48,
					_c("#BFD0EA", PARRY_FLASH_ALPHA * fade), 2.0)
			draw_arc(boss_center, flash_r * 0.62, 0.0, TAU, 32,
					_c("#4A6089", PARRY_FLASH_ALPHA * fade * 0.6), 1.0)
		else:
			# 后段暖金：双环 + 低 alpha 亮核（不叠乘既有 FXBloom 的 #FFF0C2 a=.85 核心）
			draw_arc(boss_center, flash_r, 0.0, TAU, 48,
					_c("#FFD27A", PARRY_FLASH_ALPHA * fade), 2.0)
			draw_arc(boss_center, flash_r * 0.66, 0.0, TAU, 32,
					_c("#F0A94C", PARRY_FLASH_ALPHA * fade * 0.7), 1.0)
			draw_circle(boss_center, 3.0 * fade, _c("#FFF0C2", 0.28 * fade))


## R35B · mobile 四项全关档位的【轻量降级绘制】（仅 FXBloom 节点调用）。
## 「移动端不劣化」≠「完全不绘制」：四项光效 / impact_fx / 连击层 / 全宽横带全关，
## 只画「轻量环 + 既有 HUD 文字」—— 一个局部暖金环（开窗读秒）+ 一个短促成功扩散环，
## 与 desktop 同款局部锚点、同款既有色号，零新增色号 / 零 GPU job / 零外部素材。
## HUD 文字提示框由 hud.gd（Rank-1 独占只读）生产常驻可见层承担，本层不重复画文字、
## 不动 HUD 文字框；SEG-B 切换点 (frame=150) 也能看到弹反反馈。
func _draw_parry_lightweight(_t: float) -> void:
	if _parry_service == null:
		return
	var center := PARRY_RING_ANCHOR_PLAYER
	# 开窗：单个轻量暖金环（半径随窗口收紧读秒，2px 硬边，alpha ≤ PARRY_LITE_ALPHA）
	if _parry_window_open and _parry_window_left > 0.0:
		var wr: float = clampf(_parry_window_left / _parry_window_total, 0.0, 1.0)
		var lr: float = PARRY_LITE_RING_R - 6.0 * (1.0 - wr)
		draw_arc(center, lr, 0.0, TAU, 32, _c("#F0A94C", PARRY_LITE_ALPHA), 2.0)
		draw_arc(center, lr - 3.0, 0.0, TAU, 32,
				_c("#FFD27A", PARRY_LITE_ALPHA * 0.45), 1.0)
	# 成功：单个短促暖金 / 冷蓝扩散环（PARRY_FLASH_SEC 计时，峰值 alpha ≤ 0.30）
	if _parry_flash_left > 0.0:
		var p: float = 1.0 - clampf(_parry_flash_left / PARRY_FLASH_SEC, 0.0, 1.0)
		var fade: float = 1.0 - p
		var lr2: float = PARRY_FLASH_R0 + (PARRY_FLASH_R1 - PARRY_FLASH_R0) * p
		var hex: String = "#BFD0EA" if p < PARRY_FLASH_COLD_RATIO else "#FFD27A"
		draw_arc(PARRY_RING_ANCHOR_BOSS, lr2, 0.0, TAU, 32,
				_c(hex, PARRY_LITE_FLASH_ALPHA * fade), 2.0)
	# 失败：单个低 alpha 收环（围绕角色，无横带）
	if _parry_fail_left > 0.0:
		var frac: float = clampf(_parry_fail_left / PARRY_FAIL_SEC, 0.0, 1.0)
		draw_arc(center, PARRY_RING_BASE_R + 6.0 * (1.0 - frac), 0.0, TAU, 32,
				_c("#16233F", 0.24 * frac), 1.0)


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
	# R35：精准弹反反馈层 —— 同一 FXBloom 分派节点订阅唯一 ParryService（A54），
	# 与连击层同款 deferred + 自愈，绝不自建第二个实例、不读私有实现。
	if str(name) == "FXBloom":
		call_deferred("_try_bind_combo")
		call_deferred("_try_bind_parry")


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
	# R35B 按任务单 d) 落地 §4.3「移动档降级而非全关」：四项绘制门仍全 false，
	# 但 mobile 档【不再整层零绘制】—— 仅 FXBloom 节点保持 visible 用于画轻量弹反环，
	# 其余三项节点仍 visible=false、零绘制（「移动端不劣化」≠「完全不绘制」）。
	# 口径差异如实登记：R19 verify_fx_mobile.gd 断言「mobile 4 节点 visible 全 false」，
	# 本轮 FXBloom 一项按新口径改为 true；该验证脚本属只读、非本轮授权，未改（见 DONE-R35B）。
	_all_on = (fx_profile == PROFILE_DESKTOP)
	_on_reflection = _all_on
	_on_godrays = _all_on
	_on_motes = _all_on
	_on_bloom = _all_on
	# desktop 四项由节点名分派、按同层子节点顺序叠加；mobile 仅 FXBloom 可见画轻量环
	visible = _all_on or (str(name) == "FXBloom" and fx_profile == PROFILE_MOBILE)


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
	var is_bloom: bool = (str(name) == "FXBloom")
	if _all_on:
		# R34 / R35：连击 + 弹反反馈层计时器 + 绑定自愈
		# （仅 FXBloom 节点；desktop 四项全开）
		if is_bloom:
			if _combo_service == null:
				_try_bind_combo()
			_update_combo_timers(delta)
			if _parry_service == null:
				_try_bind_parry()
			_update_parry_timers(delta)
		queue_redraw()
	elif is_bloom and fx_profile == PROFILE_MOBILE:
		# R35B · mobile 四项全关档位【轻量降级】：四项光效 / impact_fx / 连击层零绘制，
		# 但弹反计时器 / 绑定自愈仍推进，并逐帧 queue_redraw() 让轻量环随窗口收紧读秒
		# （每帧仅 1~2 个 draw_arc，开销可忽略 → 「移动端不劣化」≠「完全不绘制」）。
		if _parry_service == null:
			_try_bind_parry()
		_update_parry_timers(delta)
		queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	# R35B · mobile 四项全关档位不再 _draw() 开头直接 return：仅 FXBloom 画「轻量环 +
	# 既有 HUD 文字」，其余三项 / 其它节点零绘制（「移动端不劣化」≠「完全不绘制」），
	# 使第 150 帧落在 SEG-B 切换点时也能看到弹反反馈。
	if not _all_on:
		if str(name) == "FXBloom" and fx_profile == PROFILE_MOBILE:
			_draw_parry_lightweight(t)
		return
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
			_draw_parry_fx(t)       # R35：精准弹反反馈层（未绑定 ParryService 则静默跳过）
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
