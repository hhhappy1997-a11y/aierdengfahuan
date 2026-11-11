class_name DepthProfile
extends Resource
## R29 · 景深强化层数据驱动参数（Rank-2 交付件 · v0.7.0 新内容）
## 派单 cmd-20261111-112803-988-A2 · [ROUND=R29] · AI=2（Rank-2 战斗系统与数据驱动）
## 落位：res://scripts/render/depth_profile.gd
##
## 定位：按 TECHNICAL-ART-DEPTH-v060.md §5 P1「多层视差景深 + 边缘暗角 +
##   冷夜雾 + 暖金光晕」把 2D 近似景深的全部可调量参数化为单一 Resource，
##   供 Rank-4 的 shader / hd2d_parallax.gd 按画质档读取；本资源只定义结构与
##   合法性自检，不改任何场景 / shader / 素材 / 既有画质档。
##
## 【调参唯一入口】两档设计数值只在 res://data/render/depth_profile.tres；
##   本脚本内所有默认值均为 [PLACEHOLDER] 非法占位基线（is_valid() 必为 false），
##   不是设计值。改数值 → 只改 .tres → 同步 verify_depth_profile_v070.gd 的
##   期望/色板常量 → 真跑三段门禁。详见 teamwork/Rank-2/DEPTH-PROFILE-TUNING.md。
##
## 【色号口径】#RRGGBB uppercase 字符串。首选依据为 Rank-3 风格锚点
##   HD2D-STYLE-ANCHOR-v2.md §5.3 的 16 色受控板（colors_16）与 §2.2 唯一
##   锚点色：cold_night_fog_hex=#1B2A4A / warm_gold_key_hex=#C99A3A
##   （该文档明示「供 depth_profile.tres 字段逐字引用」）。两档色号逐字取此锚点。
##   若该锚点文档未落盘，verify 才降级到工程冻结色板 palette_256.json 32 色，
##   依据选定与如实登记见 verify_depth_profile_v070.gd 运行期 [ANCHOR]/[DEGRADE]。
##   注：v2 §5.1 明言 16 色受控板（v1 §2 真源）与 palette_256.json 32 色板
##   为历史两套口径并存、不擅自合并；本轮按任务单与 v2 用前者，后者仅降级用。
##
## 【P1 参数口径 / 全部 [PLACEHOLDER] 首版，待人工试玩校准】
##   - 层深 layer_depths：多层视差各层归一化深度（远→近，0<d<=1），
##     数组长度=层数；rationale：复用 hd2d_parallax.gd:47-49 三层视差
##     （P_RIDGE_FAR/MID/NEAR=0.06/0.14/0.26）的分层概念，用数组表达
##     「几层 + 各层纵深」，零新增节点即可驱动 2D _draw() 分层。
##   - 视差系数 parallax_coefficients：与层深一一对应（0<c<=1，远小近大），
##     desktop 首版直接取 hd2d_parallax.gd 既有 0.06/0.14/0.26 作对齐基线；
##     rationale：与既有三层山影漂移幅度逐字对齐，避免另起一套数值。
##   - 雾密度 fog_density：冷夜雾密度（0~1）；rationale：工程
##     Environment.fog_density=0.02（TECHNICAL-ART-DEPTH-v060.md §1），
##     以该基线上下微调，Compatibility 后端传统深度雾零 GPU job。
##   - 暗角强度 vignette_strength：边缘暗角（0~1）；rationale：P1 边缘暗角
##     为纯 2D 绘制量，对齐 HD2D-STYLE-ANCHOR-v2.md §2.3 建议区间 0.10~0.25
##     （desktop 0.24 / mobile 0.12），低分辨率整数放大缓冲下压暗过强会伤
##     HUD 面板文字（R28B 实证），故留上限且 mobile 更弱。
##   - 暖金光晕强度 warm_glow_strength：暖金光晕/bloom 强度（0~1）；
##     rationale：对齐 hd2d_fx.gd FXBloom「仅 warm_gold_key 过阈」口径，
##     单标量控制过阈强度，避免全屏泛白。
##   - 冷夜雾色号 cold_night_fog_color / 暖金主光色号 warm_gold_key_color：
##     rationale：调性由冻结色板锁定，两档同色号保证画质切换不改冷暖对冲；
##     降级只动强度/层数/密度，不动色相（不糊不黑口径见 tuning 文档）。
##
## 【真跑】D:/Godot/Godot_v4.7.2-stable_win64.exe
##   --headless --path F:/Game/aierdengfahuan/godot --import（注册 class_name）
##   --headless --path ... --script res://scripts/verify_depth_profile_v070.gd
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 / 零外部依赖 / 零 GPU job。

# ── 单档 7 参数（[PLACEHOLDER] 非法占位基线，不是设计值）──────────────
@export var layer_depths: PackedFloat32Array = PackedFloat32Array()
@export var parallax_coefficients: PackedFloat32Array = PackedFloat32Array()
@export var fog_density: float = 0.0
@export var vignette_strength: float = 0.0
@export var warm_glow_strength: float = 0.0
@export var cold_night_fog_color: String = ""
@export var warm_gold_key_color: String = ""

# ── 档位集合容器（仅 depth_profile.tres 顶层实例填充；单档实例为 null）──
# rationale：任务要求单文件两档；用两个子资源各为一份 DepthProfile，
#   顶层以宽类型 Resource 引用，规避自引用类型在 --import 期的解析风险，
#   运行时以 `as DepthProfile` 还原。
@export var desktop: Resource = null
@export var mobile: Resource = null


## 合法性自检（结构 + 数值范围 + 色号格式；不含色板 membership，那部分归 verify）。
## 边界「拒绝不崩」的被测对象：任何负强度 / 超 1 系数 / 空表 / 字段缺失
## 一律返回 false，不抛异常、不 assert、不崩溃。
func is_valid() -> bool:
	if layer_depths.is_empty() or parallax_coefficients.is_empty():
		return false
	if layer_depths.size() != parallax_coefficients.size():
		return false
	for d in layer_depths:
		if d <= 0.0 or d > 1.0:
			return false
	for c in parallax_coefficients:
		if c <= 0.0 or c > 1.0:
			return false
	if fog_density < 0.0 or fog_density > 1.0:
		return false
	if vignette_strength < 0.0 or vignette_strength > 1.0:
		return false
	if warm_glow_strength < 0.0 or warm_glow_strength > 1.0:
		return false
	if not _is_hex6(cold_night_fog_color) or not _is_hex6(warm_gold_key_color):
		return false
	return true


func _is_hex6(s: String) -> bool:
	if s.length() != 7 or not s.begins_with("#"):
		return false
	for i in range(1, 7):
		var ch: String = s.substr(i, 1).to_upper()
		if not (("0" <= ch and ch <= "9") or ("A" <= ch and ch <= "F")):
			return false
	return true
