extends CanvasLayer

## R16 · HUD ↔ WorldState / 赐福网络 数据绑定（Rank-3，cmd-20261109-085736-027-A3）。
## R21 · 统一存档快旅口径（Rank-3，cmd-20261109-115818-643-A3）：
##   grace_fast_travel() 与 travel_to() 统一优先取 /root/SaveDeltaWriter，注入 committer 仅兜底。
## 挂载点：res://scenes/hud.tscn 根节点 Hud（CanvasLayer），与场景根节点类型一致。
##
## I-1 边界（SAVE-SPEC-FINAL.md §3 / HUD-BINDING.md §2.4）：
##   HUD 只读 WorldState.get_flag(key, default)；不 set_flag、不构造 / 解析 SaveDelta、
##   不 FileAccess 读写 user://saves/、不 ResourceLoader 加载存档、不 JSON.parse 存档、
##   不调用 WorldState 内部方法（_commit_delta 等）。
##   grace_fast_travel 的「原子落盘」由 3 号内部件 SaveDeltaWriter.commit(reason) 完成，
##   HUD 只编排「先落盘、后发信号」的顺序，自己不实现 commit 逻辑。
##
## 刷新策略：事件驱动（flag_changed / delta_committed 信号）+ _ready() 一次全量，
##   禁止在 _process() / _physics_process() 里每帧轮询 get_flag。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

# ==========================================================================
# 4 个信号（HUD → 外部，沿用 HUD-BINDING.md §3.2 草案）
# ==========================================================================
signal grace_selected(target_grace_id: String)     # 菜单选中某个已解锁赐福（仅 UI 事件）
signal travel_confirmed(target_grace_id: String)   # 确认传送；等价触发 GameEvents.travel_requested
signal rest_requested(grace_id: String)            # 请求休息（→ grace_rest 落盘，由 3 号状态机处理）
signal hud_refreshed()                             # 一次完整 refresh_all() 完成（自检 / 调试）
# R32 [ROUND=R32] 新增信号（既有 4 信号逐字未动、既有验证断言不回退）：
signal execution_performed(window_id: String, bonus_points: int)   # 机制 B：处决窗口内按 F 完成处决
signal boon_draft_selected(index: int, choice_id: String)         # 机制 A：赐福抉择三选一
# R34 [ROUND=R34] 生产运行时触发链新增信号（既有 6 信号逐字不动）：
#   e 链：点数只发信号 / 传参给 Rank-3 I-1 权威写入点，Rank-1 不写存档文件（A50）。
signal points_awarded(reason: String, points: int, source: String)
#   d 链：抉择选中 → apply() 结算生效，广播成对 effect/cost 供 Rank-2 wave_trial_director 消费。
signal boon_draft_applied(index: int, choice_id: String, effect_key: String, effect_value: float, cost_key: String, cost_value: float)
#   d 链：下一波开始时把上一波抉择的修正广播给下一波消费方（作用于下一波）。
signal production_wave_modifier(wave_index: int, effect_key: String, effect_value: float, cost_key: String, cost_value: float)
# ---- R35 [ROUND=R35] 新增信号（既有 9 信号逐字不动）----
#   精准弹反：窗口内真实 K → 成功结算 → 广播。
#   A48①：生产运行时订阅者 = EncounterDirector（_r35_bootstrap 里 connect），
#          成功时由导演层真实削韧并保护连击不断；绝不只是验证脚本订阅。
signal parry_performed(window_id: String, bonus_points: int, poise_bonus: float)
# ---- R36 [ROUND=R36] 新增信号（既有 10 信号逐字不动）----
#   战技 Q：真实 Q 输入 → A54 唯一 focus_service 判定 FP / 冷却 → 成功扣 FP 广播、
#   失败（专注不足 / 冷却中）广播。A48①：两信号的生产运行时订阅者 =
#   EncounterDirector（_r36_bootstrap connect，真实施加战技伤害 / 削韧），
#   绝不只是验证脚本订阅；HUD 自身同时订阅刷新「专注值 FP」条与提示文本。
signal focus_skill_performed(skill_id: String, fp_before: int, fp_after: int, fp_cost: int, damage: int, poise: float, multiplier: float)
signal focus_skill_rejected(reason: String, fp: int, fp_max: int)
# ---- R37 [ROUND=R37] 新增信号（既有 12 信号逐字不动）----
#   元素瓶 G：真实 G 输入 → A54 唯一 flask_service 判定瓶数 / HP → 成功扣瓶回 HP 广播、
#   失败（瓶数不足 / 生命已满 / 死亡期间）广播。A48①：4 个新信号的生产运行时订阅者 =
#   EncounterDirector（_r37_bootstrap connect，hp_after 原样写回真实 _player_hp，A57），
#   绝不只是验证脚本订阅。
signal flask_used(flask_before: int, flask_after: int, hp_before: int, hp_after: int)
signal flask_rejected(reason: String, flask: int)
#   死亡轮回：HP 归零 → death_service 判定死亡态 → 广播掉落赐福点数（HUD 显示「你死了」）；
#   赐福重生 → death_service 判定 → 广播回满 HP/FP/瓶。Rank-1 只做状态表现与信号转发，
#   不新增第二套胜负判定（既有 ENC._finish / encounter_finished 逐字不动）。
signal player_died(dropped_points: int)
signal player_respawned(hp: int, fp: int, flask: int)

# ==========================================================================
# 19) R37 [ROUND=R37 / v0.14.0] · 元素瓶 G + 死亡轮回（运行时侧，Rank-1 唯一写入方）
#   常量 / 状态变量【前置声明】（函数实现见文件末尾 19 节），确保 _r34_build_visible /
#   _process_r32_keys / set_layout_viewport / _r34_refresh_visible 等既有段落引用时
#   无 GDScript 前向声明问题；既有常量 / 变量 / 信号 / 分区数组逐字不动。
#   A48①：4 个新信号（flask_used / flask_rejected / player_died / player_respawned）
#          的【生产运行时订阅者 = EncounterDirector】（_r37_bootstrap connect）。
#   A54：flask_service / death_service 唯一实例从 wave_trial_director.get_flask_service() /
#        get_death_service() 复用，绝不自建第二个；并发未落盘时判空降级、不崩、
#        不产生 SCRIPT ERROR、如实登记「真实判定逻辑待 Rank-2 落盘联调」（同 R35/R36 先例）。
#   A57：元素瓶回复后的 hp_after / flask_after 一律取服务【最终结算值】原样采信，
#        本层不二次计算；ENC 生产订阅者把 hp_after 原样写回真实 _player_hp。
#   不改既有普通攻击判定 / 帧数据 / 输出格式 / 既有胜负结算分支：G 为新增输入分支，
#     死亡态只做状态表现与信号转发，不订阅 / 不改 ENC._finish / encounter_finished。
# ==========================================================================
# ---- Rank-2 flask_service / death_service 鸭子类型契约（命名差异不崩）----
#   R37 真实接口（Rank-2 派单 cmd-...-082-A2）：flask_service.use_flask(current_hp,max_hp) /
#   on_grace_rest() / reset() / get_snapshot()；death_service HP 归零判定 / 掉落 / 重生 /
#   get_snapshot()。下列候选同时兼容契约替身，字段命名差异不改本层代码即可兼容。
const R37_FLASK_METHOD_USE: Array[String] = ["use_flask", "try_use_flask", "drink_flask"]
const R37_FLASK_METHOD_REST: Array[String] = ["on_grace_rest", "rest_at_grace", "rest", "refill"]
const R37_FLASK_METHOD_SNAPSHOT: Array[String] = ["get_snapshot", "get_status", "get_view", "get_flask_view"]
#   Rank-2 真实 DeathService 主接口：on_death(grace_points) / on_grace_respawn() /
#   reclaim_dropped()；契约替身 observe_hp(hp,max_hp) / respawn() 作为降级候选。
const R37_DEATH_METHOD_ON_DEATH: Array[String] = ["on_death", "on_player_death", "enter_death"]
const R37_DEATH_METHOD_OBSERVE: Array[String] = ["observe_hp", "on_hp_changed", "notify_hp", "check_death", "update_hp"]
const R37_DEATH_METHOD_RESPAWN: Array[String] = ["on_grace_respawn", "respawn", "on_respawn", "rebirth"]
const R37_DEATH_METHOD_SNAPSHOT: Array[String] = ["get_snapshot", "get_status", "get_view", "get_death_view"]
const R37_KEY_OK: Array[String] = ["ok", "success", "accepted"]
const R37_KEY_REASON: Array[String] = ["reason", "result", "reject_reason"]
const R37_KEY_FLASK: Array[String] = ["flask", "flask_remaining", "flask_count", "current_flask", "remaining", "flask_after"]
const R37_KEY_FLASK_MAX: Array[String] = ["flask_max", "max_flask", "flask_capacity", "capacity"]
const R37_KEY_FLASK_BEFORE: Array[String] = ["flask_before", "prev_flask"]
const R37_KEY_HP: Array[String] = ["hp_after", "current_hp", "hp", "hp_remaining", "new_hp"]
const R37_KEY_HP_BEFORE: Array[String] = ["hp_before", "prev_hp"]
const R37_KEY_HEAL: Array[String] = ["heal_amount", "heal", "hp_restored", "healed"]
const R37_KEY_IS_DEAD: Array[String] = ["is_dead", "dead", "is_death", "in_death_state", "death_state", "dead_state"]
const R37_KEY_DROPPED: Array[String] = ["dropped_points", "dropped", "points_dropped", "pending_drop", "drop"]
# [PLACEHOLDER] 服务未落盘时的 HUD【显示降级初值】（非玩法数值，权威瓶数恒以
#   flask_rules.tres / flask_service.get_snapshot() 为准）；rationale：Rank-2 服务未装配时
#   HUD 仍显示稳定的「当前/上限」条，不伪装成真实瓶数。调参唯一入口 = 本常量表（只改表不改算法）。
const R37_FLASK_FALLBACK: int = 3
const R37_FLASK_MAX_FALLBACK: int = 3
# [PLACEHOLDER] 元素瓶 / 死亡提示显示时长（秒），待试玩校准；rationale：短暂可见反馈不常驻遮挡。
#   调参唯一入口 = 本常量表。
const R37_HINT_SHOW_SEC: float = 1.2
const R37_FLASK_LABEL_NAME: String = "ProdFlaskLabel"
const R37_DEATH_LABEL_NAME: String = "ProdDeathLabel"
const R37_WAVE_REL_PATH: String = "WaveTrialDirector"
const R37_ENC_REL_PATH: String = "EncounterRoot"

var _r37_flask: Object = null                # A54 唯一 flask_service（wave 复用，不自建）
var _r37_death: Object = null                # A54 唯一 death_service（wave 复用，不自建）
var _r37_flask_label: Label = null           # 「元素瓶 N/M」真实节点 ProdFlaskLabel
var _r37_death_label: Label = null           # 「你死了」真实节点 ProdDeathLabel
var _r37_flask_cur: int = R37_FLASK_FALLBACK         # 当前瓶数镜像（权威来自服务快照）
var _r37_flask_max: int = R37_FLASK_MAX_FALLBACK     # 瓶上限镜像
var _r37_hp: float = 0.0                    # 玩家 HP 镜像（只读 ENC.get_life_hp_view()）
var _r37_hp_max: float = 0.0                 # 玩家 HP 上限镜像
var _r37_is_dead_state: bool = false         # 死亡态（death_service 权威 / 降级 HP 归零）
var _r37_dropped_points: int = 0             # 首轮掉落赐福点数（重复死亡不二次掉落）
var _r37_death_count: int = 0                # 死亡态进入次数（边沿触发）
var _r37_respawn_count: int = 0              # 赐福重生次数
var _r37_hint_text: String = ""              # 「瓶数不足 / 生命已满 / 回复 N HP」提示
var _r37_hint_remaining: float = 0.0
var _r37_last_g_event_id: int = 0            # 同一 InputEvent 实例幂等去重（ENC+HUD 双接 G）
var _r37_last_g_result: Dictionary = {}
var _r37_attempt_count: int = 0
var _r37_success_count: int = 0
var _r37_reject_count: int = 0
var _r37_attempt_log: Array[Dictionary] = []
var _r37_bootstrapped: bool = false
var _r37_grace_subscribed: bool = false      # ENC.grace_rested 生产订阅
var _r37_resting: bool = false               # 赐福休息重入守卫（防 wave.trial_grace_rest 二次广播）

# ==========================================================================
# 常量
# ==========================================================================
const LAST_GRACE_KEY: String = "grace.network.last_grace_id"   # 三段式，已登记常量，不拼接
const TITLE_PREFIX: String = "赐福 · "
const TITLE_PLACEHOLDER: String = "赐福 · 宁姆格福"             # last_grace_id 空值回退占位
const GOLD: Color = Color(0.83, 0.68, 0.3, 1.0)              # 与 hud.tscn 落盘金色一致
const DIM: Color = Color(0.45, 0.42, 0.34, 1.0)               # 未点亮运行期暗色
# R27 [ROUND=R27] 赐福点亮态的三段式 flag 来源（数据驱动，不硬编码颜色切换条件）：
#   试炼完成：dungeon.wave_trial.completed（bool，false→true 单向）
#   赐福休息：grace.network.last_rest_epoch（int，每次休息 +1，>0 表示已休息）
# 只登记「读哪些 flag」，颜色切换统一交给既有 apply_lit_state(lit)（GOLD / DIM）。
const LIT_FLAG_TRIAL_COMPLETED: String = "dungeon.wave_trial.completed"
const LIT_FLAG_REST_EPOCH: String = "grace.network.last_rest_epoch"
const LIT_SOURCE_FLAGS: Array[String] = [LIT_FLAG_TRIAL_COMPLETED, LIT_FLAG_REST_EPOCH]
# R28 [ROUND=R28] 教学完成点亮来源（bool，false→true 单向）。
# 单独常量、不并入 LIT_SOURCE_FLAGS：保护既有 verify_persistence_hud_v050.gd 的
# D5「LIT_SOURCE_FLAGS.size()==2」断言（30 PASS 全不回退）。教学完成与试炼完成都
# 读三段式 flag，颜色切换统一复用既有 apply_lit_state(lit) 入口，不硬编码颜色条件。
const LIT_FLAG_TUTORIAL_COMPLETED: String = "grace.tutorial.completed"
# R28B / 裁决 A26：grace.tutorial.step_index 是【世界持久层】单调历史最高进度
#   （按 max 写、绝不回退、T 重开不回写更小值），只作存档 / 回放 / 重启恢复记录。
#   教学 HUD 的「进度 1-3」必须显示【运行时游标】（见 read_tutorial_progress() /
#   tutorial_progress_text()），绝不读该世界 flag，否则 T 重开会卡在历史最高 3/3。
#   本常量只登记「不用于显示」的世界 key：不并入 LIT_SOURCE_FLAGS、不并入 _bound_keys、
#   不参与 refresh_label 增量命中，保护 verify_persistence_hud_v050.gd D5
#   「LIT_SOURCE_FLAGS.size()==2」等既有断言不回退。
const FLAG_TUTORIAL_STEP_INDEX: String = "grace.tutorial.step_index"
# 对齐 chunk_world_bridge.gd:43 const REASON_FAST_TRAVEL
const REASON_FAST_TRAVEL: String = "grace_fast_travel"
# R19/R20：SaveDeltaWriter 的 autoload 注册键与 /root 路径。R20 起已正式注册为 autoload，
# R21 起供 travel_to() / grace_fast_travel() 两入口统一优先解析真实节点、
# 供 get_commit_status() 如实读回注册态。
const WRITER_AUTOLOAD_KEY: String = "autoload/SaveDeltaWriter"
const WRITER_ROOT_PATH: String = "/root/SaveDeltaWriter"

# ---- R27B · 赐福成长购买入口（裁决 A23 三段式收敛 / A24 增益运行时接线）----
const GRACE_CONFIG_PATH: String = "res://data/rpg/grace_upgrades.tres"
const FLAG_POINTS: String = "grace.trial.points"
const FLAG_SPENT_POINTS: String = "grace.trial.spent_points"
## 裁决 A23：grace.upgrade_<id>.unlocked 三段式收敛有效，四段字面废止，不改 world_state.gd 正则。
const FLAG_UNLOCKED_PREFIX: String = "grace.upgrade_"
const FLAG_UNLOCKED_SUFFIX: String = ".unlocked"
const COMMIT_REASON_PURCHASED: String = "grace_upgrade_purchased"

# ---- R29 [ROUND=R29] · 兑换面板文字可读性（段 B / low-mobile SubViewport 缩放）----
# 根因（改前真跑三档抓帧实证）：courtyard.tscn 的 GraceShopLabel 挂在
#   SubViewportContainer/SubViewport/FXLayer/Hud（SubViewport 内）。quality_settings.apply()
#   按档位改写 SubViewportContainer.stretch_shrink（low=3 / medium=2 / high=1）与 SubViewport
#   内部渲染尺寸（low=480x270 / medium=640x360 / high=960x540），Label 的屏幕绝对坐标
#   offset=(24,300)-(1100,470) 在小尺寸 SubViewport 内被整体拉伸/裁剪：
#     high(shrink=1) 文字叠在砖地上、字号小、对比度低，勉强可辨；
#     medium(shrink=2) 文字被推到 y≈610 与底部战斗 HUD 重叠、后两行被截断；
#     low(shrink=3) offset 远超内部视口 → 兑换面板文字完全消失。
# 修法：_ready() 里把该 Label 迁到【SubViewport 外】的独立 CanvasLayer（与 QualitySettings
#   同级，挂 SubViewportContainer 的父节点），CanvasLayer 铺满真实 1280x720 视口、不受
#   stretch_shrink 影响；同时固定字号 + 高对比度（亮色字 / 深色描边阴影 / 半透明深底），
#   保证 low/medium/high 三档一致可读。
# 边界：只动兑换面板 Label 自身的父节点与 theme / 位置 / 可见性，不改兑换逻辑
#   （get_shop_view / purchase_upgrade）、不改四套既有 HUD 位置。独立 hud.tscn 实例
#   （--script 验证）无 SubViewport，判空降级、不迁节点、不改节点路径，
#   保护既有 58 / 30 / 11 PASS 断言不回退。
# R29B [ROUND=R29B] 修正：上轮保留的 offset (24,300)-(1100,470) 在独立 CanvasLayer 上
#   变成 1076×170 的近黑实心大矩形，首帧常驻并横切玩家/Boss 躯干（总指挥目视发现）。
#   本轮改为：① 面板 visible 严格由 shop_open 门控（首帧隐藏 / E 打开才显示 / 关闭隐藏）；
#   ② 深底 alpha 0.88→0.30；③ offset 移到屏幕右下 SHOP_RECT_*（避开角色包围盒与四套 HUD）。
# [PLACEHOLDER] 字号 / 颜色 / 层号 / rect 为布局值，待试玩目视校准（rationale：20px 在
#   1280x720 下 5 行文本约 120px；layer=45 高于 QualitySettings=40）。
const SHOP_FONT_SIZE: int = 20
const SHOP_LAYER_INDEX: int = 45
const SHOP_LAYER_NAME: String = "GraceShopReadableLayer"
const SHOP_TEXT_COLOR: Color = Color(1.0, 0.96, 0.82, 1.0)
const SHOP_OUTLINE_COLOR: Color = Color(0.02, 0.03, 0.06, 1.0)
# R29B [ROUND=R29B]：改前深底 alpha=0.88 几乎不透明，在独立 CanvasLayer 上形成
#   x≈24–1100 / y≈300–470 的近黑实心大矩形，首帧常驻并遮住玩家/Boss 躯干
#   （总指挥目视 v070 定稿三帧发现的新回归）。压到 0.30（≤0.35）：真跑像素量化
#   验证面板区保留底层砖地纹理、不是近黑实心块。边框同步降到 0.55 避免金边突兀。
const SHOP_BG_COLOR: Color = Color(0.04, 0.06, 0.12, 0.30)
const SHOP_BORDER_COLOR: Color = Color(0.83, 0.68, 0.3, 0.55)
const SHOP_OUTLINE_SIZE: int = 6
# R29B · 面板位置（屏幕右下，避开角色包围盒与四套 HUD）。改前 (24,300)-(1100,470)
#   横切玩家(x≈400–680,y≈490–570) / Boss(x≈645–880,y≈230–350) 躯干；新矩形
#   x≥740 / y≥358 落在两者包围盒之外：Boss 下沿 y≈350 < 358、玩家右沿 x≈680 < 740。
#   不覆盖 赐福 HUD(x<730,y<220) / 画质面板(x>760,y<180)（本面板 y≥358）；
#   也不压 波次 HUD(y≈240,x<460) / 教学 HUD(y≈520,x<700) / 底部战斗 HUD(y≈660)。
#   宽 536px < 原 1076px、覆盖面积 182,920→112,896 px²，配合 autowrap 保持 20px 字号
#   与三档可读（独立 CanvasLayer 不受 stretch_shrink 影响）。[PLACEHOLDER] 待试玩校准。
const SHOP_RECT_LEFT: float = 740.0
const SHOP_RECT_TOP: float = 358.0
const SHOP_RECT_RIGHT: float = 1276.0
const SHOP_RECT_BOTTOM: float = 568.0

# ---- R30 [ROUND=R30] · 赐福图鉴运行时挂载（最小接线，裁决 A35）----
# 只做「运行时 new + call_deferred add_child」，不写 courtyard.tscn 任何场景节点
#   （静态节点数保持 41）、不改既有兑换逻辑、不改四套 HUD 文本。
# 独立 hud.tscn 实例（--script 验证）祖先链无 SubViewportContainer → 直接判空返回、
#   不建节点，保护既有 58 / 30 / 11 / 127 PASS 逐字不回退。
const CODEX_DIRECTOR_PATH: String = "res://scripts/combat/codex_director.gd"
const CODEX_DIRECTOR_NAME: String = "CodexDirector"

# ---- R31 [ROUND=R31] · 打击反馈层运行时挂载（唯一新增接线，1~9 节逐字未动）----
# 只做「运行时 new + call_deferred add_child」，不写 courtyard.tscn 任何场景节点
#   （静态节点数保持 41 / uv 2/1/1 原样）、不改既有兑换逻辑与四套 HUD 文本。
# 反馈层按实接入 EncounterDirector 既有信号；低画质 / 移动端由 set_low_quality 降级为只保留闪光；
# Tab 图鉴 / 兑换面板打开时 set_panel_open 追加强化避让，反馈层不遮文字。
# 独立 hud.tscn 实例（--script 验证）祖先链无 SubViewportContainer → 判空返回、不建节点。
const IMPACT_FEEDBACK_PATH: String = "res://scripts/render/impact_feedback.gd"
const IMPACT_LAYER_NAME: String = "ImpactFeedbackLayer"

# ==========================================================================
# 依赖注入 / 运行期引用
# ==========================================================================
@export var grace_network_path: String = "res://data/rpg/grace_network.tres"
## R27B：挂载的增益运行时节点（courtyard.tscn 覆盖真机相对路径）与兑换面板 Label。
## 默认空 NodePath 使 hud.tscn 的独立实例（既有回归）判空降级，不崩、不改 hud.tscn 结构。
@export var grace_runtime_path: NodePath = ^""
@export var shop_label_path: NodePath = ^"GraceShopLabel"

var _world_state: Node = null            # /root/WorldState（autoload）
var _net: Resource = null                # GraceNetwork（8 节点 / 7 边，运行期唯一数据源）
var _title_label: Label = null           # hud.tscn 内 TitleLabel
var _bound_keys: Dictionary = {}          # 绑定集合：flag_changed 增量命中判定
var _menu: Array[Dictionary] = []        # 赐福菜单数据快照（无 UI 容器节点，供后续 UI 消费）
var fast_travel_committer: Callable = Callable()  # 可注入：func(reason: String) -> void，默认未注入

# ---- R19 · 赐福菜单运行期统计 / SaveDeltaWriter 降级登记（如实，不伪造 autoload）----
var grace_node_count: int = 0                 # open_grace_menu() 运行期从 .tres 读到的 nodes.size()
var grace_edge_count: int = 0                 # open_grace_menu() 运行期从 .tres 读到的 edges.size()
var menu_open: bool = false                   # 菜单是否已打开（仅内存态，不改 hud.tscn 结构）
var commit_degraded: bool = false             # 最近一次落盘（travel_to / grace_fast_travel 共用）是否走了「非 autoload」降级
var last_commit_source: String = "none"       # "autoload" / "injected" / "none"（如实登记）
var last_commit_reason: String = ""           # 最近一次 commit 的 reason
var last_commit_ok: bool = false              # 最近一次是否真的先落盘
var commit_log: Array[String] = []            # 逐次落盘登记（供自检 / 回执引用）

# ---- R27B 购买入口运行期状态（既有 1~7 节逻辑逐字未动）----
var _shop_label: Label = null                 # courtyard.tscn 新增的 GraceShopLabel
var shop_open: bool = false                   # 兑换面板开关（仅内存态）
var shop_message: String = "按 E 打开赐福成长兑换；数字键 1 / 2 / 3 选择"
var grace_purchase_events: Array[String] = [] # 顺序证据：stage_flags → disk_write → runtime_update
var _grace_ws: Node = null                    # 注入优先（验证），否则场景探活
var _grace_writer: Node = null
var _grace_runtime: Node = null
var _grace_encounter: Node = null
# R31：运行时挂载的打击反馈层（CanvasLayer，非场景静态节点）。
var _impact_feedback: Node = null

# ==========================================================================
# 1) 生命周期 / 依赖绑定
# ==========================================================================

func _ready() -> void:
	_title_label = get_node_or_null("TitleLabel") as Label
	load_grace_network(grace_network_path)
	# R27B：--script / SceneTree 模式下 add_child 不 flush data.tree，/root/... 绝对路径会触发
	#   "Can't use get_node() with absolute paths from outside the active scene tree"。
	#   改用 Engine.get_main_loop() + root.get_node_or_null() 相对探活（项目既有踩坑口径）；
	#   真机场景等价命中同一 autoload WorldState，既有 30/31 PASS 绑定链路不变。
	var ml: MainLoop = Engine.get_main_loop()
	var ws_root: Node = null
	if ml is SceneTree:
		ws_root = (ml as SceneTree).root.get_node_or_null(NodePath("WorldState"))
	bind_world_state(ws_root)
	# 一次初始化全量刷新：内部所有 WorldState.get_flag(key, default) 均显式传业务默认值
	refresh_all()
	# R27B：绑定兑换面板 Label / 增益运行时节点并启用输入；依赖缺失判空降级、不崩。
	_shop_label = get_node_or_null(shop_label_path) as Label
	# R29：把兑换面板 Label 迁出 SubViewport（仅在真实场景命中）；独立 hud.tscn 实例判空降级。
	_ensure_shop_readable()
	if _grace_runtime == null and not grace_runtime_path.is_empty():
		_grace_runtime = get_node_or_null(grace_runtime_path)
	set_process_unhandled_input(true)
	_refresh_shop_hud()
	# R30：运行时挂赐福图鉴导演（不改场景节点 / 不动兑换逻辑与四套 HUD 文本）。
	_ensure_codex_director()
	# R31：运行时挂打击反馈层（不改场景节点；面板避让 / 信号按实接入 / 画质降级见 §10）。
	_ensure_impact_feedback()
	# R32：HUD 分区布局初始化（纯内存、不写场景节点；分区 / 互斥 / 新机制见 §11~§14）。
	_init_r32_layout()
	# R34 c/d/e/f：生产服务创建（同步）+ 帧末跨节点装配（call_deferred 避开 busy）。
	_r34_create_boon_service()
	call_deferred("_r34_bootstrap")


## 注入 WorldState 引用并连信号；重复绑定先断开旧连接，避免重复回调。
func bind_world_state(ws: Node) -> void:
	if _world_state == ws:
		return
	if _world_state != null and is_instance_valid(_world_state):
		if _world_state.has_signal("flag_changed") and _world_state.is_connected("flag_changed", Callable(self, "_on_flag_changed")):
			_world_state.disconnect("flag_changed", Callable(self, "_on_flag_changed"))
		if _world_state.has_signal("delta_committed") and _world_state.is_connected("delta_committed", Callable(self, "_on_delta_committed")):
			_world_state.disconnect("delta_committed", Callable(self, "_on_delta_committed"))
	_world_state = ws
	if _world_state == null:
		push_warning("[HUD] 未找到 /root/WorldState，走只读占位（TitleLabel 显示占位文本）")
		return
	# 事件驱动：订阅 flag_changed（增量）与 delta_committed（回放 / 注入兜底全量）
	if _world_state.has_signal("flag_changed"):
		_world_state.connect("flag_changed", Callable(self, "_on_flag_changed"))
	if _world_state.has_signal("delta_committed"):
		_world_state.connect("delta_committed", Callable(self, "_on_delta_committed"))


## load .tres 一次并缓存，取 nodes / edges，建立绑定集合；不硬编码任何赐福名 / 边。
func load_grace_network(path: String) -> void:
	_net = null
	_bound_keys.clear()
	_bound_keys[LAST_GRACE_KEY] = true
	# R27：把「试炼完成 / 赐福休息」两段三段式 flag 登记进增量命中集合，
	# 使其成为事件驱动的点亮来源（订阅 flag_changed，不每帧轮询）。
	for k: String in LIT_SOURCE_FLAGS:
		_bound_keys[k] = true
	# R28：教学完成三段式 flag 也登记进增量命中集合（事件驱动，不每帧轮询）。
	_bound_keys[LIT_FLAG_TUTORIAL_COMPLETED] = true
	if not ResourceLoader.exists(path):
		push_warning("[HUD] 赐福网络资源不存在：%s" % path)
		return
	var res: Resource = ResourceLoader.load(path, "Resource", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	if res == null:
		push_warning("[HUD] 赐福网络加载失败：%s" % path)
		return
	_net = res
	for n in _grace_nodes():
		var node: Resource = n as Resource
		if node == null:
			continue
		_bound_keys[String(node.get("lit_flag"))] = true
		_bound_keys[String(node.get("unlocked_flag"))] = true

# ==========================================================================
# 2) flag 读取与刷新（对应 HUD-BINDING.md §1.4 / §1.5）
# ==========================================================================

## 唯一的 flag 读取入口：等价于 WorldState.get_flag(key, default)，
## 显式传业务默认值（String → ""、bool → false），绝不依赖 default = null 形参默认。
func _flag(key: String, default: Variant) -> Variant:
	if _world_state == null or not _world_state.has_method("get_flag"):
		return default
	return _world_state.call("get_flag", key, default)


## 一次全量刷新：_ready / delta_committed / 场景切换后。读取 → 比对 → 赋值，幂等。
func refresh_all() -> void:
	var last_id: String = String(_flag(LAST_GRACE_KEY, ""))       # 显式 default=""
	set_title_from_grace(last_id)
	# 全量：逐节点读 lit / unlocked（显式 default=false），重建点亮态与菜单数据快照
	var lit: bool = false
	for n in _grace_nodes():
		var node: Resource = n as Resource
		if node == null:
			continue
		var node_lit: bool = bool(_flag(String(node.get("lit_flag")), false))        # 显式 default=false
		var _node_unlocked: bool = bool(_flag(String(node.get("unlocked_flag")), false))  # 显式 default=false
		if String(node.get("grace_id")) == last_id:
			lit = node_lit
	# R28：全量刷新也纳入「教学完成」三段式来源（否则 commit → delta_committed →
	# refresh_all 会把 flag_changed 刚点亮的亮金覆盖回暗灰）。既有回归的干净基线里
	# grace.tutorial.completed 默认 false，lit or false == lit，逐字等价、不回退。
	apply_lit_state(lit or _read_tutorial_lit())
	_menu = build_grace_menu()
	hud_refreshed.emit()


## flag_changed 命中的单 key 增量刷新：只动受该 key 影响的 UI 属性，不全量重算。
func refresh_label(key: String) -> void:
	if key == LAST_GRACE_KEY:
		set_title_from_grace(String(_flag(LAST_GRACE_KEY, "")))   # 显式 default=""
		return
	# R27：试炼完成 / 赐福休息 flag 变化 → 读三段式 flag 汇总点亮态，由
	# apply_lit_state(lit) 统一完成「暗灰 → 亮金」切换（本处不硬编码颜色条件）。
	if LIT_SOURCE_FLAGS.has(key):
		apply_lit_state(_read_lit_sources())
		return
	# R28：教学完成（grace.tutorial.completed）flag 变化 → 读三段式 flag 汇总点亮态，
	# 与试炼完成共用既有 apply_lit_state(lit) 入口，代码内不出现「某 flag → 某颜色」硬编码。
	if key == LIT_FLAG_TUTORIAL_COMPLETED:
		apply_lit_state(_read_lit_sources() or _read_tutorial_lit())
		return
	for n in _grace_nodes():
		var node: Resource = n as Resource
		if node == null:
			continue
		var lit_flag: String = String(node.get("lit_flag"))
		if key == lit_flag:
			# 仅当该节点是当前赐福时才改点亮态，避免无关 flag 误刷
			if String(node.get("grace_id")) == String(_flag(LAST_GRACE_KEY, "")):
				apply_lit_state(bool(_flag(lit_flag, false)))     # 显式 default=false
			return
		if key == String(node.get("unlocked_flag")):
			_menu = build_grace_menu()                          # 解锁态变化 → 菜单快照增量重建
			return


func _on_flag_changed(key: String, _old_value: Variant, _new_value: Variant) -> void:
	# 事件驱动增量刷新：仅命中绑定集合才刷新，禁止每帧轮询
	if _bound_keys.has(key):
		refresh_label(key)


func _on_delta_committed(_seq: int, _reason: String) -> void:
	# 存档回放 / 跨场景注入后兜底一次全量刷新（防信号丢失 / 回放注入不一致）
	refresh_all()

# ==========================================================================
# 3) 金色 Label 绑定（对应 HUD-BINDING.md §1.3）
# ==========================================================================

## TitleLabel.text = "赐福 · " + nodes[*].display_name；空值 / 查不到回退静态占位。
func set_title_from_grace(grace_id: String) -> void:
	var text: String = TITLE_PLACEHOLDER
	if not grace_id.is_empty():
		var node: Resource = _find_grace(grace_id)
		if node != null:
			var display: String = String(node.get("display_name"))
			if not display.is_empty():
				text = TITLE_PREFIX + display
	if _title_label != null and _title_label.text != text:
		_title_label.text = text


## 运行期改 font_color 点亮 / 暗色；.tscn 落盘的静态金色保持不变（不改 .tscn）。
func apply_lit_state(lit: bool) -> void:
	if _title_label == null:
		return
	var c: Color = GOLD if lit else DIM
	if _title_label.get_theme_color("font_color", "Label") != c:
		_title_label.add_theme_color_override("font_color", c)


## R27：点亮态 = 三段式 flag 来源的状态汇总（纯读、事件驱动）。
## 每个来源经唯一入口 _flag(key, default) 显式传默认值读取；bool 直接取真值，
## int（赐福休息 epoch）以 >0 表示「已休息」。任一来源为真即点亮。
## 只产出 bool，颜色切换完全交给 apply_lit_state()，代码内不出现「某 flag → 某颜色」硬编码。
func _read_lit_sources() -> bool:
	var lit: bool = false
	for k: String in LIT_SOURCE_FLAGS:
		var v: Variant = _flag(k, false)
		if typeof(v) == TYPE_BOOL:
			lit = lit or bool(v)
		elif typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
			lit = lit or (int(v) > 0)
	return lit


## R28：教学完成点亮来源（纯读、事件驱动）。经唯一 _flag(key, default) 入口显式传
## 业务默认值 false 读三段式 flag；只产出 bool，颜色切换完全交给 apply_lit_state()。
## 与 _read_lit_sources() 分离，避免改动既有 2 项来源数组（保护 v050 D5 断言）。
func _read_tutorial_lit() -> bool:
	return bool(_flag(LIT_FLAG_TUTORIAL_COMPLETED, false))


## R28B / 裁决 A26 · 教学进度显示（只认运行时游标，绝不读世界持久层 flag）。
## runtime_step_index 来自 TutorialDirector.get_snapshot()["step_index"]（T 重开归零）；
## 返回 "赐福引导 %d/%d"，供教学 HUD / 集成层渲染与验证读回。
## 世界 flag FLAG_TUTORIAL_STEP_INDEX 只登记、绝不读取：它是单调历史最高进度，
## 若用它渲染，T 重开后进度会错误地卡在 3/3（A26 明确禁止）。
func tutorial_progress_text(runtime_step_index: int, total_steps: int) -> String:
	var total: int = maxi(1, total_steps)
	var shown: int = clampi(runtime_step_index + 1, 1, total)
	return "赐福引导 %d/%d" % [shown, total]


## R28B / 裁决 A26 · 从教学导演的运行时快照产出教学进度显示（集成层只读接口）。
## 只取 get_snapshot()["step_index"]（运行时游标）与 total_steps；
## 绝不读 grace.tutorial.step_index 世界 flag，绝不写任何 flag、不发信号。
## director 为空 / 无 get_snapshot 时安全回落 0 / 3，不崩、不产生 SCRIPT ERROR。
func read_tutorial_progress(director: Node) -> Dictionary:
	var runtime_step: int = 0
	var total: int = 3
	if director != null and director.has_method("get_snapshot"):
		var snap: Dictionary = director.call("get_snapshot") as Dictionary
		runtime_step = int(snap.get("step_index", 0))
		total = int(snap.get("total_steps", 3))
	return {
		"runtime_step_index": runtime_step,
		"total_steps": total,
		"text": tutorial_progress_text(runtime_step, total),
		"source": "runtime_cursor",
		"world_flag_key_not_for_display": FLAG_TUTORIAL_STEP_INDEX,
	}

# ==========================================================================
# 4) 赐福菜单（对应 HUD-BINDING.md §2，8 节点 / 7 边数据驱动）
# ==========================================================================

## 遍历 nodes，过滤 requires_flags（发现前置）+ unlocked，文本 / 分组 / 排序全取自 .tres。
func build_grace_menu() -> Array[Dictionary]:
	var menu: Array[Dictionary] = []
	for n in _grace_nodes():
		var node: Resource = n as Resource
		if node == null:
			continue
		if not are_flags_satisfied(_dict_of(node.get("requires_flags"))):
			continue
		if not is_grace_unlocked(node):
			continue
		var entry: Dictionary = {
			"id": String(node.get("grace_id")),
			"text": String(node.get("display_name")),
			"group": String(node.get("area_id")),
			"is_dungeon": bool(node.get("is_dungeon")),
			"order": _array_of(node.get("neighbors")),
			"scene_path": String(node.get("scene_path")),
			"spawn_marker": String(node.get("spawn_marker"))
		}
		menu.append(entry)
	return menu


func is_grace_unlocked(node: Resource) -> bool:
	if node == null:
		return false
	var key: String = String(node.get("unlocked_flag"))
	if key.is_empty():
		return false
	return bool(_flag(key, false))                              # 显式 default=false


## 逐条 get_flag(k, false) == expected；expected 均为 bool true（见 .tres 7 边条件）。
func are_flags_satisfied(requires: Dictionary) -> bool:
	for k in requires.keys():
		var key: String = String(k)
		var expected: Variant = requires[k]
		var actual: Variant = _flag(key, false)                  # 显式 default=false
		if typeof(actual) != typeof(expected) or actual != expected:
			return false
	return true


## 用 edges[*].requires_flags 求从 from_id 出发、条件满足且目标已解锁的可达赐福。
func get_reachable_targets(from_id: String) -> Array[String]:
	var out: Array[String] = []
	if _net == null or from_id.is_empty():
		return out
	for e in _edges():
		var edge: Dictionary = _dict_of(e)
		if String(edge.get("from", "")) != from_id:
			continue
		if not are_flags_satisfied(_dict_of(edge.get("requires_flags", {}))):
			continue
		var to_id: String = String(edge.get("to", ""))
		var target: Resource = _find_grace(to_id)
		if target == null or not is_grace_unlocked(target):
			continue
		if not out.has(to_id):
			out.append(to_id)
	return out


func on_grace_selected(target_grace_id: String) -> void:
	# 菜单点击回调 → 仅发 UI 事件信号
	grace_selected.emit(target_grace_id)


## 草案接口：校验目标 → travel_confirmed 信号（HUD 不自行落盘）。
func request_travel(target_grace_id: String) -> void:
	var node: Resource = _find_grace(target_grace_id)
	if node == null:
		push_warning("[HUD] request_travel: 目标不在赐福网络：%s" % target_grace_id)
		return
	if not is_grace_unlocked(node):
		push_warning("[HUD] request_travel: 目标未解锁：%s" % target_grace_id)
		return
	if not are_flags_satisfied(_dict_of(node.get("requires_flags"))):
		push_warning("[HUD] request_travel: 目标发现前置未满足：%s" % target_grace_id)
		return
	travel_confirmed.emit(target_grace_id)

# ==========================================================================
# 5) grace_fast_travel 接口（本轮重点，对应 HUD-BINDING.md §2.4）
# ==========================================================================

## 注入 3 号内部件的强制落盘入口，供装配层把 SaveDeltaWriter.commit 交给 HUD 编排顺序。
## HUD 只持有 Callable、只编排顺序，不实现 commit 逻辑（I-1）。
func set_fast_travel_committer(c: Callable) -> void:
	fast_travel_committer = c


## 赐福快速传送编排接口。不可颠倒的顺序（任务书 / §2.4）：
##   1 校验目标 unlocked + 当前赐福沿 edges 的 requires_flags 全部满足（只读 get_flag(k, false)）；
##   2 先落盘：与 travel_to() 统一走 _commit_before_travel(reason)，优先取 /root/SaveDeltaWriter
##      原子写，注入 committer 仅在取不到该节点时兜底（HUD 不自己 commit、不构造 SaveDelta）；
##   3 后发信号：travel_confirmed / GameEvents.travel_requested → 1 号 SceneRouter 换场景。
## /root/SaveDeltaWriter 与注入 committer 都取不到时：不自行落盘，只发信号，
##   由既有链路 ChunkWorldBridge._on_travel_requested → commit("grace_fast_travel") 兜底（如实登记）。
func grace_fast_travel(target_grace_id: String, reason: String = REASON_FAST_TRAVEL) -> void:
	# 1 校验
	var node: Resource = _find_grace(target_grace_id)
	if node == null:
		push_warning("[HUD] grace_fast_travel: 目标不在赐福网络：%s" % target_grace_id)
		return
	if not is_grace_unlocked(node):
		push_warning("[HUD] grace_fast_travel: 目标未解锁：%s" % target_grace_id)
		return
	if not are_flags_satisfied(_dict_of(node.get("requires_flags"))):
		push_warning("[HUD] grace_fast_travel: 目标发现前置未满足：%s" % target_grace_id)
		return
	var current_id: String = String(_flag(LAST_GRACE_KEY, ""))   # 显式 default=""
	if not current_id.is_empty() and current_id != target_grace_id:
		if not get_reachable_targets(current_id).has(target_grace_id):
			push_warning("[HUD] grace_fast_travel: 沿 edges 的 requires_flags 未全部满足：%s→%s" % [current_id, target_grace_id])
			return
	# 2 先落盘（与 travel_to() 统一入口 _commit_before_travel：优先 /root/SaveDeltaWriter，注入 committer 仅取不到时兜底）
	if not _commit_before_travel(reason):
		push_warning("[HUD] grace_fast_travel: 未找到 SaveDeltaWriter / 未注入 committer，落盘交既有 travel_requested 订阅链路兜底")
	# 3 后发信号
	travel_confirmed.emit(target_grace_id)
	var bus: Node = get_node_or_null("/root/GameEvents")
	if bus != null and bus.has_signal("travel_requested"):
		bus.emit_signal("travel_requested", target_grace_id)


## 休息请求（→ grace_rest 落盘，由 3 号状态机订阅处理；HUD 只发信号）。
func request_rest(grace_id: String) -> void:
	rest_requested.emit(grace_id)


## R21（cmd-20261109-115818-643-A3）：两入口统一口径后的兼容封装。
## 保留此私有方法名以免破坏历史调用；实际落盘统一委托 _commit_before_travel(reason)，
## 即优先取 /root/SaveDeltaWriter、注入 committer 仅在取不到该节点时兜底，并如实登记降级态。
## 本方法内不再有「注入 committer 优先」的旧口径。
func _delegate_commit(reason: String) -> bool:
	return _commit_before_travel(reason)

# ==========================================================================
# 6) 私有小工具（数据取自 .tres，避免硬编码 / 避免 null 传播）
# ==========================================================================

func _grace_nodes() -> Array:
	if _net == null:
		return []
	var raw: Variant = _net.get("nodes")
	if typeof(raw) != TYPE_ARRAY:
		return []
	return raw as Array


func _edges() -> Array:
	if _net == null:
		return []
	var raw: Variant = _net.get("edges")
	if typeof(raw) != TYPE_ARRAY:
		return []
	return raw as Array


func _find_grace(grace_id: String) -> Resource:
	if grace_id.is_empty():
		return null
	for n in _grace_nodes():
		var node: Resource = n as Resource
		if node != null and String(node.get("grace_id")) == grace_id:
			return node
	return null


func _dict_of(v: Variant) -> Dictionary:
	if typeof(v) == TYPE_DICTIONARY:
		return v as Dictionary
	return {}


func _array_of(v: Variant) -> Array:
	if typeof(v) == TYPE_ARRAY:
		return (v as Array).duplicate()
	return []

# ==========================================================================
# 7) R19 · open_grace_menu() / travel_to()（本轮追加，1~6 节既有逻辑逐字未动）
# ==========================================================================
# 约束：
#   - 赐福菜单数据 100% 运行期取自 res://data/rpg/grace_network.tres（8 节点 / 7 边由
#     _grace_nodes() / _edges() 遍历得到，代码内不硬编码任何赐福名 / 边 / 计数常量）；
#   - travel_to() 严格「先 commit 原子落盘、后发 travel_confirmed / travel_requested 信号」；
#   - R20（裁决 A9）：project.godot [autoload] 已正式注册 SaveDeltaWriter，travel_to()
#     优先取 /root/SaveDeltaWriter 完成 commit；仅当取不到该节点时才回退注入 committer
#     并如实登记降级。get_commit_status() 可把 degraded / source / reason / ok /
#     writer_registered_as_autoload 读回，绝不伪造落盘与 autoload 状态。
#   - R21：grace_fast_travel() 亦统一走 _commit_before_travel()，与 travel_to() 同口径
#     （优先 /root/SaveDeltaWriter、注入 committer 仅兜底），顺序同为 commit → confirmed → requested。

## 打开赐福菜单：运行期强制从磁盘重读 .tres（load_grace_network 内 CACHE_MODE_IGNORE），
## 统计实际节点 / 边数，重建菜单快照并返回（调用方据此渲染 UI，不改 hud.tscn 结构）。
func open_grace_menu() -> Array[Dictionary]:
	load_grace_network(grace_network_path)
	grace_node_count = _grace_nodes().size()
	grace_edge_count = _edges().size()
	_menu = build_grace_menu()
	menu_open = true
	return _menu.duplicate(true)


## 赐福快速传送（R19 编排接口 / R20 兑现 autoload）。不可颠倒的顺序：
##   1 校验目标（数据取自 .tres，不硬编码）；
##   2 先落盘：优先取 /root/SaveDeltaWriter.commit(reason) 原子写；取不到该节点才回退
##     注入 committer 并如实登记降级（见 _commit_before_travel）；
##   3 后发信号：HUD.travel_confirmed（4 信号之一）+ GameEvents.travel_requested。
func travel_to(grace_id: String) -> void:
	# 1 校验
	var node: Resource = _find_grace(grace_id)
	if node == null:
		push_warning("[HUD] travel_to: 目标不在赐福网络：%s" % grace_id)
		return
	if not is_grace_unlocked(node):
		push_warning("[HUD] travel_to: 目标未解锁：%s" % grace_id)
		return
	if not are_flags_satisfied(_dict_of(node.get("requires_flags"))):
		push_warning("[HUD] travel_to: 目标发现前置未满足：%s" % grace_id)
		return
	# 2 先落盘（内部完成 autoload 检测 / 注入 committer 降级 / 如实登记）
	_commit_before_travel(REASON_FAST_TRAVEL)
	# 3 后发信号
	travel_confirmed.emit(grace_id)
	var bus: Node = get_node_or_null("/root/GameEvents")
	if bus != null and bus.has_signal("travel_requested"):
		bus.emit_signal("travel_requested", grace_id)


## 先落盘的唯一入口（R20）：优先取 /root/SaveDeltaWriter（已注册 autoload 的真实节点）；
## 取不到该节点才回退注入 committer。三种来源如实写入 last_commit_source /
## commit_degraded / commit_log，不伪造已落盘、不伪造 autoload 可用。
func _commit_before_travel(reason: String) -> bool:
	last_commit_reason = reason
	# 优先：/root/SaveDeltaWriter 真实节点（R20 已在 project.godot [autoload] 注册）
	var writer: Node = get_node_or_null(WRITER_ROOT_PATH)
	if writer != null and writer.has_method("commit"):
		writer.call("commit", reason)
		commit_degraded = false
		last_commit_source = "autoload"
		last_commit_ok = true
		_log_commit()
		return true
	# 回退：取不到 /root/SaveDeltaWriter 才用注入 committer（如实登记降级）
	commit_degraded = true
	if fast_travel_committer.is_valid():
		fast_travel_committer.call(reason)
		last_commit_source = "injected"
		last_commit_ok = true
		push_warning("[HUD] 降级登记：未取到 /root/SaveDeltaWriter，改用 set_fast_travel_committer() 注入的 committer 完成 commit(reason=%s)" % reason)
		_log_commit()
		return true
	# 连注入 committer 都没有：明确登记「未能先落盘」，不冒充原子写已完成
	last_commit_source = "none"
	last_commit_ok = false
	push_warning("[HUD] 降级登记：未取到 /root/SaveDeltaWriter 且未注入 committer；本次 travel_to 未能先落盘，仅后发 travel_requested（如实登记）")
	_log_commit()
	return false


func _log_commit() -> void:
	commit_log.append("source=%s reason=%s ok=%s degraded=%s" % [last_commit_source, last_commit_reason, str(last_commit_ok), str(commit_degraded)])


## 供装配层 / 自检读回「降级登记」实际值，避免只靠日志口头声明。
func get_commit_status() -> Dictionary:
	return {
		"degraded": commit_degraded,
		"source": last_commit_source,
		"reason": last_commit_reason,
		"ok": last_commit_ok,
		"writer_registered_as_autoload": ProjectSettings.has_setting(WRITER_AUTOLOAD_KEY),
		"writer_root_exists": get_node_or_null(WRITER_ROOT_PATH) != null,
		"log": commit_log.duplicate(),
		"grace_node_count": grace_node_count,
		"grace_edge_count": grace_edge_count
	}


# ==========================================================================
# 8) R27B · 赐福成长「购买入口」（裁决 A23 / A24）
#    交互：E 键 interact（赐福休息）打开 / 关闭兑换面板，数字键 1 / 2 / 3 购买；
#          HUD 显示三项（名称 / cost / 是否已解锁 / 当前余额）+ 可读提示。
#    落盘：经 GraceUpgradeService.can_purchase / purchase 幂等判定；成功后写
#          grace.trial.spent_points（单调递增）与 grace.upgrade_<id>.unlocked（单向），
#          commit("grace_upgrade_purchased") 严格「先落盘再改运行时实例」；
#          绝不 removals、绝不回退 grace.trial.points。
#    R28B ③ 兼容旧档：写入侧自 R28 双写收敛后【只写 grace.upgrade_<id>.unlocked】
#          （裁决 A23，本轮逐字未动），不再新写 grace.trial.bought_<id>；
#          读取侧接入 Rank-2 GraceUpgradeService 的三个兼容函数
#          legacy_bought_flag_key() / is_purchased_in_flags() / load_state_from_flags()，
#          以「unlocked OR 旧 grace.trial.bought_<id>」判定，使只有旧 bought_ 的
#          历史存档仍可识别已购（见 get_shop_view / purchase_upgrade /
#          _purchase_flags_snapshot）。F1~F8 防刷核心逐字不变。
#    既有 1~7 节逻辑逐字未动；依赖缺失一律判空降级、不崩、不产生 SCRIPT ERROR。
# ==========================================================================

func unlocked_key(upgrade_id: String) -> String:
	return FLAG_UNLOCKED_PREFIX + upgrade_id + FLAG_UNLOCKED_SUFFIX


## 验证 / 装配注入口：注入优先于场景探活（--script 模式可确定性验证落盘时序）。
func bind_grace_deps(ws: Node, writer: Node, runtime: Node, encounter: Node = null) -> void:
	_grace_ws = ws
	_grace_writer = writer
	_grace_runtime = runtime
	_grace_encounter = encounter


func _grace_state() -> Node:
	if _grace_ws != null:
		return _grace_ws
	if _world_state != null:
		return _world_state
	var ml: MainLoop = Engine.get_main_loop()
	if ml is SceneTree:
		return (ml as SceneTree).root.get_node_or_null(NodePath("WorldState"))
	return null


func _grace_delta_writer() -> Node:
	if _grace_writer != null:
		return _grace_writer
	var ml: MainLoop = Engine.get_main_loop()
	if ml is SceneTree:
		return (ml as SceneTree).root.get_node_or_null(NodePath("SaveDeltaWriter"))
	return null


func _grace_runtime_node() -> Node:
	if _grace_runtime != null:
		return _grace_runtime
	if not grace_runtime_path.is_empty():
		return get_node_or_null(grace_runtime_path)
	return null


func _grace_encounter_node() -> Node:
	if _grace_encounter != null:
		return _grace_encounter
	return get_node_or_null(^"../../../../EncounterRoot")


func _load_grace_config() -> GraceUpgradeConfig:
	if not ResourceLoader.exists(GRACE_CONFIG_PATH):
		return null
	return ResourceLoader.load(GRACE_CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as GraceUpgradeConfig


## R28B / ③ 兼容旧档：从 WorldState 逐 key get_flag 构造「已购判定」flags 快照。
## I-1 铁律：WorldState 只暴露 get_flag(key, default)，不可访问内部 _flags；
## 故按 upgrade id 收集权威 unlocked 与旧 grace.trial.bought_<id> 两键的值，
## 交 GraceUpgradeService.is_purchased_in_flags() / load_state_from_flags() 以
## 「unlocked OR 旧 bought_」判定，使仅有旧 bought_ 的历史存档仍可识别已购。
## 纯读、不写；写仍只写 unlocked（裁决 A23 / F1~F8 防刷判定逐字不变）。
func _purchase_flags_snapshot(state: Node, cfg: GraceUpgradeConfig) -> Dictionary:
	var flags: Dictionary = {}
	if state == null or cfg == null or not state.has_method("get_flag"):
		return flags
	for i: int in range(cfg.upgrade_count()):
		var u := cfg.get_upgrade(i)
		if u == null:
			continue
		var auth_key: String = unlocked_key(u.id)
		var legacy_key: String = GraceUpgradeService.legacy_bought_flag_key(u.id)
		flags[auth_key] = bool(state.call("get_flag", auth_key, false))
		flags[legacy_key] = bool(state.call("get_flag", legacy_key, false))
	return flags


## 只读视图：供 HUD 渲染与验证读回（不改 WorldState、不写 flag）。
func get_shop_view() -> Dictionary:
	var cfg: GraceUpgradeConfig = _load_grace_config()
	var state: Node = _grace_state()
	var points: int = 0
	var spent: int = 0
	if state != null and state.has_method("get_flag"):
		points = int(state.call("get_flag", FLAG_POINTS, 0))
		spent = int(state.call("get_flag", FLAG_SPENT_POINTS, 0))
	var balance: int = maxi(0, points - spent)
	var items: Array[Dictionary] = []
	if cfg != null:
		# R28B ③：一次构造兼容快照（unlocked OR 旧 bought_），供全部兑换项共用；
		# 写入侧仍只写 unlocked，读取侧兼容纯 bought_ 历史存档。
		var flags: Dictionary = _purchase_flags_snapshot(state, cfg)
		for i: int in range(cfg.upgrade_count()):
			var u := cfg.get_upgrade(i)
			if u == null:
				continue
			var unlocked: bool = GraceUpgradeService.is_purchased_in_flags(flags, u.id)
			items.append({
				"index": i, "id": u.id, "name": u.display_name, "cost": u.cost,
				"unlocked": unlocked, "affordable": (not unlocked) and balance >= u.cost,
			})
	return {"open": shop_open, "balance": balance, "points": points, "spent": spent,
		"items": items, "message": shop_message}


## R29 · 把兑换面板 Label 迁出 SubViewport，挂到不受 stretch_shrink 影响的独立 CanvasLayer。
## 只在「Label 确实位于某个 SubViewportContainer/SubViewport 内 + 能找到其父级挂载根」时执行；
## 独立 hud.tscn 实例（--script 验证）不含 SubViewportContainer，判空降级、节点路径 / 文本 /
## 兑换逻辑逐字不变。固定字号 + 高对比度 theme 覆盖仅作用于该 Label，三档渲染结果一致。
## 时序：_ready() 期间场景根（Courtyard / root）处于 _propagate_ready（blocked>0），直接
##   outside_root.add_child(layer) 会报 "Parent node is busy setting up children" 并失败
##   （改前真跑实证：Label 被 reparent 到游离层 → 三档文字全部消失）。故用 call_deferred
##   把「建层 + reparent + theme」推迟到本帧 _ready 传播完成之后、首帧渲染之前执行。
func _ensure_shop_readable() -> void:
	if _shop_label == null or not is_instance_valid(_shop_label):
		return
	var container: SubViewportContainer = null
	var p: Node = _shop_label.get_parent()
	while p != null:
		if p is SubViewportContainer:
			container = p as SubViewportContainer
			break
		p = p.get_parent()
	if container == null:
		# --script 独立 hud.tscn 实例：Label 不在 SubViewport 内，保持原路径 / 原属性（降级）。
		return
	var outside_root: Node = container.get_parent()
	if outside_root == null:
		return
	call_deferred("_deferred_shop_readable", outside_root)


## 由 call_deferred 触发：此时 outside_root 已完成 children setup，add_child 合法。
func _deferred_shop_readable(outside_root: Node) -> void:
	if _shop_label == null or not is_instance_valid(_shop_label) \
			or outside_root == null or not is_instance_valid(outside_root):
		return
	# 幂等：同名独立层已存在则复用，不重复建层。
	var layer: CanvasLayer = outside_root.get_node_or_null(NodePath(SHOP_LAYER_NAME)) as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = SHOP_LAYER_NAME
		layer.layer = SHOP_LAYER_INDEX
		outside_root.add_child(layer)
	if not layer.is_inside_tree():
		return
	if _shop_label.get_parent() != layer:
		_shop_label.reparent(layer)
	# R29B：把面板从横切角色中部的 (24,300)-(1100,470) 移到屏幕右下 SHOP_RECT_*。
	#   autowrap 让 20px 字号在较窄宽度下自动折行、不裁字；文字内容逐字不动，
	#   独立 CanvasLayer 不受 stretch_shrink 影响 → low/medium/high 三档一致可读。
	_shop_label.offset_left = SHOP_RECT_LEFT
	_shop_label.offset_top = SHOP_RECT_TOP
	_shop_label.offset_right = SHOP_RECT_RIGHT
	_shop_label.offset_bottom = SHOP_RECT_BOTTOM
	_shop_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# 固定字号 + 高对比度（不受 SubViewport 缩放影响的独立层，三档一致）。
	_shop_label.add_theme_font_size_override("font_size", SHOP_FONT_SIZE)
	_shop_label.add_theme_color_override("font_color", SHOP_TEXT_COLOR)
	_shop_label.add_theme_color_override("font_outline_color", SHOP_OUTLINE_COLOR)
	_shop_label.add_theme_constant_override("outline_size", SHOP_OUTLINE_SIZE)
	_shop_label.add_theme_color_override("font_shadow_color", SHOP_OUTLINE_COLOR)
	_shop_label.add_theme_constant_override("shadow_offset_x", 2)
	_shop_label.add_theme_constant_override("shadow_offset_y", 2)
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = SHOP_BG_COLOR
	bg.set_corner_radius_all(6)
	bg.set_border_width_all(1)
	bg.border_color = SHOP_BORDER_COLOR
	bg.content_margin_left = 12.0
	bg.content_margin_right = 12.0
	bg.content_margin_top = 8.0
	bg.content_margin_bottom = 8.0
	_shop_label.add_theme_stylebox_override("normal", bg)
	# R29B：可见性严格由 shop_open 门控。_ready() 的 _refresh_shop_hud() 已按
	#   shop_open=false 设过 visible=false；reparent / theme 覆盖后这里再显式同步一次，
	#   保证 deferred 建层之后首帧仍隐藏（画面不出现大矩形）。
	_shop_label.visible = shop_open
	print("[R29][SHOP] 兑换面板迁出 SubViewport → 独立 CanvasLayer(layer=%d) | 固定字号=%d + 描边/阴影/深底高对比 | rect=(%.0f,%.0f)-(%.0f,%.0f) 避开 赐福HUD(x<730,y<220)/画质面板(x>760,y<180)" % [
			SHOP_LAYER_INDEX, SHOP_FONT_SIZE,
			_shop_label.offset_left, _shop_label.offset_top,
			_shop_label.offset_right, _shop_label.offset_bottom])
	print("[R29B][SHOP] 默认隐藏 visible=%s (shop_open=%s) | 深底 alpha=%.2f | rect=(%.0f,%.0f)-(%.0f,%.0f) 屏幕右下避开玩家/Boss 包围盒 | autowrap=%d" % [
			str(_shop_label.visible), str(shop_open), SHOP_BG_COLOR.a,
			SHOP_RECT_LEFT, SHOP_RECT_TOP, SHOP_RECT_RIGHT, SHOP_RECT_BOTTOM,
			int(_shop_label.autowrap_mode)])


## 渲染三项可兑换增益（名称 / cost / 是否已解锁 / 当前余额）+ 可读提示到 GraceShopLabel。
func _refresh_shop_hud() -> void:
	# R31：兑换面板开闭同步给反馈层（面板打开时强化避让，闪光不遮文字）。
	_sync_impact_panels()
	if _shop_label == null:
		return
	var v: Dictionary = get_shop_view()
	var is_open: bool = bool(v.get("open", false))
	# R29B：GraceShopLabel 与其 normal stylebox（深底 + 金边）整体随 shop_open 显隐。
	#   shop_open=false（首帧 / 关闭 / 购买会话结束）→ visible=false，画面不出现大矩形；
	#   仅 E 键打开（shop_open=true）才显示。既有文本 / 兑换逻辑逐字不动。
	# R32：显隐再叠加右侧面板互斥（Tab 图鉴 / 赐福抉择打开时隐藏兑换面板、关闭恢复）；
	#   默认态 is_side_panel_visible("shop") 等价于 shop_open，既有断言不回退。
	_shop_label.visible = is_side_panel_visible("shop")
	if not is_open:
		_shop_label.text = "赐福成长 · 按 E 打开兑换"
		return
	var lines: Array[String] = []
	lines.append("赐福成长 ｜ 当前余额 %d（点数 %d − 已消费 %d） ｜ 1/2/3 兑换" % [
		int(v.get("balance", 0)), int(v.get("points", 0)), int(v.get("spent", 0))])
	var items: Array = v.get("items", []) as Array
	for it: Variant in items:
		var row: Dictionary = it as Dictionary
		var state_text: String = "已解锁" if bool(row.get("unlocked", false)) else \
			("可兑换" if bool(row.get("affordable", false)) else "点数不足")
		lines.append("  %d. %s ｜ 消耗 %d ｜ %s" % [
			int(row.get("index", 0)) + 1, str(row.get("name", "")),
			int(row.get("cost", 0)), state_text])
	lines.append("提示：" + str(v.get("message", "")))
	_shop_label.text = "\n".join(PackedStringArray(lines))


func _set_shop_message(msg: String) -> void:
	shop_message = msg
	_refresh_shop_hud()


func _toggle_shop() -> void:
	shop_open = not shop_open
	shop_message = "按 E 打开/关闭；数字键 1 / 2 / 3 兑换" if shop_open else ""
	_refresh_shop_hud()


func _unhandled_input(event: InputEvent) -> void:
	# R32：新增键（F 处决 / Tab 图鉴 / 抉择卡片数字键）走独立状态隔离处理；
	# 既有 interact / 兑换数字键逻辑在其后逐字不变（保护既有回归断言）。
	if _process_r32_keys(event):
		return
	if event.is_action_pressed("interact"):
		_toggle_shop()
		return
	if event is InputEventKey:
		var k: InputEventKey = event as InputEventKey
		if k.pressed and not k.echo:
			var idx: int = -1
			if k.physical_keycode == KEY_1 or k.keycode == KEY_1:
				idx = 0
			elif k.physical_keycode == KEY_2 or k.keycode == KEY_2:
				idx = 1
			elif k.physical_keycode == KEY_3 or k.keycode == KEY_3:
				idx = 2
			if idx >= 0:
				if not shop_open:
					_set_shop_message("请先按 E 打开赐福成长兑换面板")
					return
				purchase_upgrade(idx)


func _reject_message(svc: GraceUpgradeService, points: int, spent: int, row: Dictionary, u) -> String:
	var balance: int = maxi(0, points - spent)
	var id: String = str(row.get("id", ""))
	if svc.is_purchased(id):
		return "「%s」已解锁，不能重复购买" % str(u.display_name)
	if balance < int(row.get("cost", 0)):
		return "点数不足：%s 需要 %d，当前余额 %d" % [
			str(u.display_name), int(row.get("cost", 0)), balance]
	return "输入异常或该项不可兑换，购买被拒绝（余额 %d）" % balance


## 一次购买编排（幂等判定 / 落盘 / 运行时接线）。返回 report 供 HUD 与验证读回。
## 严格「先落盘再改运行时实例」：set_flag 入队 → commit 原子写 → 才 apply_purchased。
func purchase_upgrade(index: int) -> Dictionary:
	var cfg: GraceUpgradeConfig = _load_grace_config()
	if cfg == null:
		_set_shop_message("兑换表不可用，购买被拒绝（降级，不崩）")
		return {"ok": false, "reason": "config_unavailable", "committed": false}
	if index < 0 or index >= cfg.upgrade_count():
		_set_shop_message("无效选项，请按 1 / 2 / 3 选择")
		return {"ok": false, "reason": "invalid_index", "committed": false}
	var u := cfg.get_upgrade(index)
	if u == null or not cfg.is_upgrade_valid(u):
		_set_shop_message("该项配置非法，购买被拒绝")
		return {"ok": false, "reason": "invalid_upgrade", "committed": false}
	var state: Node = _grace_state()
	if state == null or not state.has_method("get_flag") or not state.has_method("set_flag"):
		_set_shop_message("WorldState 不可用，购买未落盘（降级，不崩）")
		return {"ok": false, "reason": "world_state_unavailable", "committed": false}
	var points: int = int(state.call("get_flag", FLAG_POINTS, 0))
	var spent: int = int(state.call("get_flag", FLAG_SPENT_POINTS, 0))
	# R28B ③：按兼容口径（unlocked OR 旧 grace.trial.bought_<id>）从 flags 快照恢复
	# 已购集合，使只有旧 bought_ 的历史存档仍被 F1 判为「已购、拒绝重复购买」。
	# 写仍只写 unlocked（裁决 A23），本轮未新增任何 bought_ 写入点。
	var flags: Dictionary = _purchase_flags_snapshot(state, cfg)
	var all_ids: Array = []
	for i: int in range(cfg.upgrade_count()):
		var it := cfg.get_upgrade(i)
		if it != null:
			all_ids.append(it.id)
	var row: Dictionary = cfg.make_upgrade(u.id, u.display_name, u.cost, u.effect_key, u.effect_value)
	var svc: GraceUpgradeService = GraceUpgradeService.new()
	svc.load_state_from_flags(flags, all_ids, spent)
	if not svc.can_purchase(points, spent, row):
		_set_shop_message(_reject_message(svc, points, spent, row, u))
		return {"ok": false, "reason": "can_purchase_rejected",
			"balance": maxi(0, points - spent), "committed": false}
	var r: Dictionary = svc.purchase(points, spent, row)
	if not bool(r.get("ok", false)):
		_set_shop_message("幂等判定拒绝购买（%s）" % str(r.get("reason", "")))
		return {"ok": false, "reason": str(r.get("reason", "")), "committed": false}
	var new_spent: int = int(r.get("spent_points", spent))
	# ★ 先落盘：经 I-1 唯一写入口 set_flag 入队 SaveDelta → commit(reason) 原子写。
	grace_purchase_events.append("stage_flags:" + u.id)
	state.call("set_flag", FLAG_SPENT_POINTS, new_spent)
	state.call("set_flag", unlocked_key(u.id), true)
	# R28 收敛后 purchased_flag_key() == unlocked_key()（同键幂等合并为单写）。
	# 写仍只写 unlocked（裁决 A23），绝不新写 grace.trial.bought_<id>；本行逐字未动。
	state.call("set_flag", GraceUpgradeService.purchased_flag_key(u.id), true)
	var writer: Node = _grace_delta_writer()
	if writer == null or not writer.has_method("commit"):
		grace_purchase_events.append("disk_write_downgrade:" + u.id)
		_set_shop_message("SaveDeltaWriter 未就绪：flag 仅进程内内存、未落盘，增益未作用到运行时（如实降级）")
		return {"ok": true, "reason": "commit_downgrade", "committed": false,
			"spent_points": new_spent, "balance": maxi(0, points - new_spent)}
	writer.call("commit", COMMIT_REASON_PURCHASED)
	grace_purchase_events.append("disk_write:" + COMMIT_REASON_PURCHASED)
	# ★ 落盘成功后才改运行时实例（HP 上限 / 翻滚无敌 / 攻击力）。
	var rt: Node = _grace_runtime_node()
	if rt != null and rt.has_method("apply_purchased"):
		var applied: Dictionary = rt.call("apply_purchased", _grace_encounter_node(), state)
		grace_purchase_events.append("runtime_update:" + str(applied.get("applied", 0)))
	else:
		grace_purchase_events.append("runtime_update_downgrade:0")
	var balance: int = maxi(0, points - new_spent)
	var msg: String = "兑换成功：%s（消耗 %d，余额 %d）" % [u.display_name, u.cost, balance]
	_set_shop_message(msg)
	return {"ok": true, "reason": "ok", "committed": true, "id": u.id,
		"spent_points": new_spent, "balance": balance, "points": points, "message": msg}


# ==========================================================================
# 9) R30 [ROUND=R30] · 赐福图鉴运行时挂载（唯一新增接线，1~8 节逐字未动）
# ==========================================================================
## 只在「真实 courtyard 场景」里挂 CodexDirector：沿父链找到 SubViewportContainer，
## 取其父节点（Courtyard，SubViewport 之外，与 QualitySettings / 兑换层同级）作挂载根。
## call_deferred 避开 _ready() 传播期 "Parent node is busy setting up children"（R29 实证）。
## 独立 hud.tscn 实例无 SubViewportContainer → 降级不建节点、不崩、既有回归不回退。
func _ensure_codex_director() -> void:
	var container: SubViewportContainer = null
	var p: Node = get_parent()
	while p != null:
		if p is SubViewportContainer:
			container = p as SubViewportContainer
			break
		p = p.get_parent()
	if container == null:
		return
	var mount: Node = container.get_parent()
	if mount == null:
		return
	# R33：已挂载（场景复用 / 二次 _ready）时只补引用 + 重新收敛 Tab 仲裁，不重复建节点。
	var existing: Node = mount.get_node_or_null(NodePath(CODEX_DIRECTOR_NAME))
	if existing != null:
		_codex_director = existing
		call_deferred("_r33_arbitrate_codex_tab")
		return
	var script: Script = load(CODEX_DIRECTOR_PATH) as Script
	if script == null:
		push_warning("[HUD] CodexDirector 脚本不可用，赐福图鉴降级（不崩）")
		return
	var director: Node = script.new() as Node
	if director == null:
		return
	director.name = CODEX_DIRECTOR_NAME
	# R33：保存真实引用，供 Tab 互斥仲裁读 is_panel_open() / 驱动 toggle_panel()。
	_codex_director = director
	mount.call_deferred("add_child", director)
	# R33：deferred 顺序在 add_child（→ director._ready 里 set_process_unhandled_input(true)）
	#   之后执行，此时关闭其 Tab 监听才不会被 _ready 覆盖；HUD 成为唯一 Tab 仲裁者。
	call_deferred("_r33_arbitrate_codex_tab")
	print("[R30][HUD] 运行时挂载 %s → Courtyard（独立 CanvasLayer 由导演自建，不写 courtyard.tscn）" % CODEX_DIRECTOR_NAME)


## R33 · Tab 仲裁收敛：director 已入树、_ready 已执行完，关闭其自身 _unhandled_input，
## 由 HUD 统一处理 Tab（消除两个独立监听者状态不同步 / set_input_as_handled 吞键）。
## 只改运行时节点属性，不改 codex_director.gd 文件、不写 courtyard.tscn（静态节点数 41 保持）。
func _r33_arbitrate_codex_tab() -> void:
	if _codex_director == null or not is_instance_valid(_codex_director):
		return
	_codex_director.set_process_unhandled_input(false)
	apply_side_panel_visibility()
	print("[R33][HUD] Tab 互斥仲裁收敛：CodexDirector 自身 Tab 监听关闭，HUD._unhandled_input 统一处理 Tab 并经 toggle_panel() 同步真实图鉴面板 visible")


## R33 · 把互斥态落实到 CodexDirector 的真实图鉴面板节点（CanvasLayer.visible）。
## 只经公开方法 is_panel_open()/toggle_panel() 鸭子类型适配：不读私有字段、不改其文件。
## want 取 is_side_panel_visible("codex")（单一事实源）：赐福抉择 / 兑换优先时图鉴面板
## 确实隐藏，关闭后恢复；director 缺失（--script 独立 hud 实例）判空降级、既有断言不回退。
func _sync_codex_panel_visible() -> void:
	if _codex_director == null or not is_instance_valid(_codex_director):
		return
	var cd: Node = _codex_director
	if not cd.has_method("is_panel_open") or not cd.has_method("toggle_panel"):
		return
	var want: bool = is_side_panel_visible("codex")
	if bool(cd.call("is_panel_open")) != want:
		cd.call("toggle_panel")


# ==========================================================================
# 10) R31 [ROUND=R31] · 打击反馈层运行时挂载（唯一新增接线，1~9 节逐字未动）
# ==========================================================================
## 沿父链找到 SubViewportContainer，取其父节点 Courtyard 作挂载根（与 R29 兑换层 /
## R30 CodexDirector 同口径：SubViewport 之外、铺满真实 1280x720 视口）。
## call_deferred 避开 _ready() 传播期 "Parent node is busy setting up children"（R29 实证）。
## 独立 hud.tscn 实例无 SubViewportContainer → 降级不建节点、不崩、既有回归不回退。
func _ensure_impact_feedback() -> void:
	var container: SubViewportContainer = null
	var p: Node = get_parent()
	while p != null:
		if p is SubViewportContainer:
			container = p as SubViewportContainer
			break
		p = p.get_parent()
	if container == null:
		return
	var mount: Node = container.get_parent()
	if mount == null or mount.get_node_or_null(NodePath(IMPACT_LAYER_NAME)) != null:
		return
	var script: Script = load(IMPACT_FEEDBACK_PATH) as Script
	if script == null:
		push_warning("[HUD] ImpactFeedback 脚本不可用，打击反馈层降级（不崩）")
		return
	var layer: Node = script.new() as Node
	if layer == null:
		return
	layer.name = IMPACT_LAYER_NAME
	_impact_feedback = layer
	mount.call_deferred("add_child", layer)
	# 按实接入 EncounterDirector 既有信号（反馈层内部 get_signal_connection_list 去重 connect）。
	var director: Node = mount.get_node_or_null(NodePath("EncounterRoot"))
	if director != null and layer.has_method("bind_director"):
		layer.call("bind_director", director)
	# 低画质 / 移动端只保留闪光（读 QualitySettings 既有 get_quality_preset，不每帧轮询）。
	var quality: Node = mount.get_node_or_null(NodePath("QualitySettings"))
	if quality != null and quality.has_method("get_quality_preset") \
			and layer.has_method("set_low_quality"):
		var preset: String = str(quality.call("get_quality_preset"))
		layer.call("set_low_quality", preset == "low" or preset == "mobile")
	_sync_impact_panels()
	print("[R31][HUD] 运行时挂载 %s → Courtyard（CanvasLayer，不写 courtyard.tscn；按实接入既有战斗信号 / 画质降级 / 面板避让）" % IMPACT_LAYER_NAME)


## 面板开闭同步：兑换面板由 shop_open 门控；Tab 图鉴面板只读 CodexDirector.is_panel_open()。
## 事件驱动（_refresh_shop_hud / 挂载完成时各一次），不在 _process 每帧轮询。
## 反馈层默认已常驻避让全部 HUD 文字 / 面板矩形，set_panel_open 再追加强化避让，
## 故面板打开期间反馈层不遮挡文字；依赖缺失一律判空降级、不产生 SCRIPT ERROR。
func _sync_impact_panels() -> void:
	var fb: Node = _impact_feedback
	if fb == null or not is_instance_valid(fb) or not fb.has_method("set_panel_open"):
		return
	# R33：与 apply_side_panel_visibility 共用单一事实源 is_side_panel_visible(...)，
	#   不再用 shop_open 原态 / 另读 CodexDirector，避免反馈层避让与面板真实 visible 不一致。
	fb.call("set_panel_open", "shop", is_side_panel_visible("shop"))
	fb.call("set_panel_open", "codex", is_side_panel_visible("codex"))
	fb.call("set_panel_open", "boon_draft", is_side_panel_visible("boon_draft"))


# ==========================================================================
# 11) R32 [ROUND=R32] · HUD 分区避让（归一化锚点 / 包围盒，不硬编码像素堆叠）
# ==========================================================================
# 根因（总指挥回看 capture/v090_demo.mp4 首/中/尾三帧目视实证）：
#   a) 赐福引导行「已完成(3/3)/按T重开教学」与波次行「第 N/3 波｜赐福点数｜前计时｜历史最佳」
#      挤在同一水平带 → 文字重叠；
#   b) Tab 图鉴面板展开时与波次行 / 赐福成长面板文字叠压；
#   c) 右上「画质设置·低/中/高」面板与右侧「赐福成长」面板同时常驻、文字叠压。
# 修法：把 HUD 划成 6 个【两两不相交】的分区 + 1 个中央角色保护区，用
#   【归一化锚点 Rect2（[0,1] 比例，position+size）】定义，不硬编码像素堆叠；
#   运行时按当前视口尺寸线性缩放 → 任意分辨率（含降级档）都不出界、不重叠。
#   右侧「兑换 / 图鉴 / 赐福抉择」三面板共用 ANCHOR_SIDE 同一分区且状态互斥（§12/§14）。
# [PLACEHOLDER] 锚点为目视布局初值，待试玩校准；rationale：分区间保留安全缝
#   （归一化后随缩放保持），配合 autowrap 保证长文本不越界、不叠压；调参只改本节常量。
const LAYOUT_BASE: Vector2 = Vector2(1280.0, 720.0)
const ANCHOR_TITLE: Rect2 = Rect2(0.01875, 0.02222, 0.37500, 0.11667)     # 左上标题
const ANCHOR_QUALITY: Rect2 = Rect2(0.60625, 0.02222, 0.37500, 0.16667)   # 右上画质
const ANCHOR_WAVE: Rect2 = Rect2(0.01875, 0.27778, 0.27813, 0.04167)      # 左中·波次带
const ANCHOR_GUIDE: Rect2 = Rect2(0.01875, 0.33056, 0.27813, 0.04167)     # 左中·引导带（与波次分两行）
const ANCHOR_STATUS: Rect2 = Rect2(0.01875, 0.92222, 0.96250, 0.05000)    # 左下状态条
const ANCHOR_SIDE: Rect2 = Rect2(0.70313, 0.41667, 0.27813, 0.41667)      # 右侧面板（兑换/图鉴/抉择 互斥）
const ANCHOR_CHAR: Rect2 = Rect2(0.31250, 0.31944, 0.37500, 0.47222)      # 中央角色保护区（非文字）
# R34C [ROUND=R34C] · 生产机制「连击评级 / 倍率 / 命中数」文本【独立分区】（任务 1）。
#   根因：R34B 的 ProdComboLabel 用 R34_RECT_BOTTOM+8 / +36 硬编码像素堆叠，落在
#   赐福成长标题行 GraceShopLabel（SHOP_RECT_TOP 0.497）同一水平带 → 实机两行互压。
#   修法：归一化锚点置于底部状态条（ANCHOR_STATUS y≥0.922）正上方，且整体在中央角色
#   （ANCHOR_CHAR y≤0.792）/ 右侧面板（ANCHOR_SIDE y≤0.833）/ 兑换面板（SHOP_RECT
#   y≤0.789）下沿之下；随 _layout_viewport 等比缩放，任意降级档都不出界 / 不重叠。
#   本锚点【不并入 get_layout_rects() 的 6 分区数组】（保护既有 A1「rects.size()==6」
#   断言不放宽），只经 get_production_mechanism_rect() 暴露，供真实节点定位与断言读取。
# [PLACEHOLDER] 锚点为布局初值，待试玩目视校准（rationale：y 0.85556~0.90556 与
#   status 0.92222 留 0.01666 安全缝、与 char/side/shop 下沿留 ≥0.06 垂直缝；
#   左半宽 0.60 避开右下侧面板余量，长文本 autowrap 不越界；调参只改本节常量）。
const ANCHOR_COMBO: Rect2 = Rect2(0.01875, 0.85556, 0.60000, 0.05000)    # 左下·生产机制评级条（独立分区）
# ---- R35 [ROUND=R35] · 精准弹反「金色预兆 / 读秒」文本【独立分区】----
#   落在左侧波次带(0.27778~0.31944) / 引导带(0.33056~0.37222) 之下、
#   连击评级条(0.85556~0.90556) / 底部状态条(0.92222~) 之上；
#   x 0.01875~0.29688 严格在中央角色保护区(ANCHOR_CHAR x≥0.31250) 之左，
#   与右侧面板 / 兑换面板 / 右上韧性条(x≥0.70313) 天然不相交。
#   归一化锚点随 _layout_viewport 等比缩放 → 四档降级均不出界 / 不与任一文字包围盒相交。
#   【不并入 get_layout_rects() 的 6 分区数组】（保护既有 A1「size()==6」断言不放宽），
#   只经 get_parry_telegraph_rect() 暴露，供真实节点定位与 HUD 布局断言读取。
# [PLACEHOLDER] 锚点为布局初值，待试玩目视校准
#   （rationale：与上方 guide 下沿 0.37222 留 0.03056 垂直安全缝、与下方 combo 留 ≥0.36 缝；
#   与中央角色左沿 0.31250 留 0.01562 水平缝；长文本 autowrap 不越界；调参只改本节常量）。
const ANCHOR_PARRY: Rect2 = Rect2(0.01875, 0.40278, 0.27813, 0.08333)    # 左中·精准弹反金色预兆带（独立分区）
# ---- R36 [ROUND=R36] · 「专注值 FP」条【独立分区】----
#   落在精准弹反带下沿(0.48611)之下、连击评级条上沿(0.85556)之上；x 0.01875~0.29688
#   严格在中央角色保护区(ANCHOR_CHAR x≥0.31250)之左，与右侧面板 / 兑换 / 右上韧性条
#   (x≥0.578/0.703)、波次/引导带(y≤0.37222)、底部状态条(y≥0.92222) 天然不相交。
#   归一化锚点随 _layout_viewport 等比缩放 → 四档降级均不出界 / 不与任一文字包围盒相交。
#   【不并入 get_layout_rects() 的 6 分区数组】（保护既有 A1「size()==6」断言不放宽），
#   只经 get_focus_rect() 暴露，供真实节点定位与 HUD 布局断言读取。
# [PLACEHOLDER] 锚点为布局初值，待试玩目视校准
#   （rationale：与上方 parry 下沿 0.48611 留 0.02778 垂直安全缝、与下方 combo 留 ≥0.30 缝；
#   与中央角色左沿 0.31250 留 0.01562 水平缝；调参只改本节常量）。
const ANCHOR_FOCUS: Rect2 = Rect2(0.01875, 0.51389, 0.27813, 0.04167)   # 左中·专注值 FP 条（独立分区）
# ---- R36B [ROUND=R36B] · 「当前战技」文字【独立分区】（A69 裁决 R 切换）----
#   落在 FP 条下沿(0.55556)之下、连击评级条上沿(0.85556)之上；x 0.01875~0.29688
#   严格在中央角色保护区(ANCHOR_CHAR x≥0.31250)之左，与右侧面板/兑换(x≥0.578)、
#   波次/引导带(y≤0.37222)、弹反预兆带(y≤0.48611)、FP 条(y≤0.55556)、
#   底部状态条(y≥0.92222)全部不相交。归一化锚点随 _layout_viewport 等比缩放，
#   四档降级均不出界 / 不与任一文字包围盒相交。不并入 get_layout_rects() 的 6 分区
#   （保护既有 A1「size()==6」断言不放宽），只经 get_current_art_rect() 暴露。
# [PLACEHOLDER] 锚点为布局初值，待试玩目视校准。
#   rationale（y=0.63 的由来）：真实 Label 有约 23px 最小内容高度，480x270 降级档
#   FP 条节点被撑到 y≈138.75~161.75（锚点仅 0.04167*270≈11.25 高），故初版
#   y=0.58333(≈157.5) 会与 FP 条交叠 567px²（L3 真跑实证）。下移到 0.63(≈170.1)
#   后与 FP 条下沿留 ≥8px 缝、与 combo 上沿(≈231)留 ≥37px 缝；1280x720 下
#   y=453.6~483.6 与 FP 条(370~400)/combo(616~652) 均不相交。与中央角色左沿
#   0.31250 留 0.01562 水平缝；长文本 autowrap 不越界；调参只改本节常量。
const ANCHOR_ART: Rect2 = Rect2(0.01875, 0.63000, 0.27813, 0.04167)     # 左中·当前战技名（独立分区）
# ---- R37 [ROUND=R37] · 「元素瓶 N/M」【独立分区】（沿用 R34C/R36/R36B 锚点口径）----
#   x 0.01875~0.29688 严格在中央角色保护区(ANCHOR_CHAR x≥0.31250)/右侧面板(x≥0.70313)之左；
#   y 0.74500~0.78667 落在当前战技名(ANCHOR_ART 0.63000~0.67167)之后、连击评价带
#   (ANCHOR_COMBO 0.85556~0.90556)之前，与 FP 条(0.51389)/弹反预兆带(0.40278)/波次·引导带
#   全部错行；低档 Label 最小内容高度撑开（同 R36B L3 实证）仍有 ≥6px 间隙。
#   【不并入 get_layout_rects() 的 6 分区数组】（保护既有 A1「size()==6」断言不放宽），
#   只经 get_flask_rect() 暴露。
const ANCHOR_FLASK: Rect2 = Rect2(0.01875, 0.74500, 0.27813, 0.04167)
# ---- R37 · 「你死了 / 掉落赐福点数」【独立分区】（仅死亡态可见，居中上方醒目）----
#   x 0.31250~0.68750 与 y 0.20500~0.26056：在左上标题(≤0.13889)/右上画质(≤0.18889)之下、
#   中央角色保护区(≥0.31944)之上；与右侧面板(x≥0.70313)/兑换面板(x≥0.578,y≥0.497)无交集。
const ANCHOR_DEATH: Rect2 = Rect2(0.31250, 0.20500, 0.37500, 0.05556)

var _layout_viewport: Vector2 = LAYOUT_BASE


func _init_r32_layout() -> void:
	set_layout_viewport(LAYOUT_BASE)


## 降级分辨率入口：由 QualitySettings / 集成层按真实视口调用（不每帧轮询）。
func set_layout_viewport(size: Vector2) -> void:
	_layout_viewport = Vector2(maxf(1.0, size.x), maxf(1.0, size.y))
	# R34C：生产机制连击文本真实节点随视口重定位（降级档不出界 / 不遮角色 / 不重叠）。
	_r34_apply_combo_rect()
	# R35：精准弹反金色预兆真实节点随视口重定位（独立分区，四档降级不与文字相交）。
	_r35_apply_parry_rect()
	# R36：专注值 FP 条真实节点随视口重定位（独立分区，四档降级不与文字相交）。
	_r36_apply_focus_rect()
	# R36B：当前战技名真实节点随视口重定位（独立分区，四档降级不与文字相交）。
	_r36b_apply_art_rect()
	# R37：元素瓶 / 死亡态真实节点随视口重定位（独立分区，四档降级不与文字相交）。
	_r37_apply_flask_rect()
	_r37_apply_death_rect()


func _scaled_rect(anchor: Rect2) -> Rect2:
	return Rect2(anchor.position.x * _layout_viewport.x,
			anchor.position.y * _layout_viewport.y,
			anchor.size.x * _layout_viewport.x,
			anchor.size.y * _layout_viewport.y)


## 6 个 HUD 文字 / 面板分区的实际包围盒（供布局断言与运行时定位）。
func get_layout_rects() -> Array[Dictionary]:
	return [
		{"id": "title", "rect": _scaled_rect(ANCHOR_TITLE)},
		{"id": "quality", "rect": _scaled_rect(ANCHOR_QUALITY)},
		{"id": "wave", "rect": _scaled_rect(ANCHOR_WAVE)},
		{"id": "guide", "rect": _scaled_rect(ANCHOR_GUIDE)},
		{"id": "status", "rect": _scaled_rect(ANCHOR_STATUS)},
		{"id": "side", "rect": _scaled_rect(ANCHOR_SIDE)},
	]


func get_center_char_rect() -> Rect2:
	return _scaled_rect(ANCHOR_CHAR)


## R34C · 生产机制连击评级文本【独立分区】的实际包围盒（归一化锚点 → 当前视口线性缩放）。
##   供 ProdComboLabel 真实节点定位与运行时 rect 断言读取；不并入 6 分区数组（A1 不回退）。
func get_production_mechanism_rect() -> Rect2:
	return _scaled_rect(ANCHOR_COMBO)


## R34C · 赐福成长标题行（GraceShopLabel 真实节点，R29 独立 CanvasLayer）包围盒。
##   与既有 SHOP_RECT_* 同源，供「生产机制文本 vs 赐福成长标题行」断言作几何事实源。
func get_shop_title_rect() -> Rect2:
	return Rect2(SHOP_RECT_LEFT, SHOP_RECT_TOP,
			SHOP_RECT_RIGHT - SHOP_RECT_LEFT, SHOP_RECT_BOTTOM - SHOP_RECT_TOP)


## R35 · 精准弹反金色预兆文本【独立分区】的实际包围盒（归一化锚点 → 当前视口线性缩放）。
##   供 ProdParryLabel 真实节点定位与「预兆文字不与其它文字包围盒相交」断言读取；
##   不并入 6 分区数组（A1 不回退）。
func get_parry_telegraph_rect() -> Rect2:
	return _scaled_rect(ANCHOR_PARRY)


## R36 · 「专注值 FP」条【独立分区】的实际包围盒（归一化锚点 → 当前视口线性缩放）。
##   供 ProdFocusLabel 真实节点定位与「FP 条不与其它文字包围盒相交」断言读取；
##   不并入 6 分区数组（A1 不回退）。
func get_focus_rect() -> Rect2:
	return _scaled_rect(ANCHOR_FOCUS)


## R36B · 「当前战技」文字【独立分区】的实际包围盒（归一化锚点 → 当前视口线性缩放）。
##   供 ProdArtLabel 真实节点定位与「战技名不与 FP 条 / 其它文字包围盒相交」断言读取；
##   不并入 6 分区数组（A1 不回退）。
func get_current_art_rect() -> Rect2:
	return _scaled_rect(ANCHOR_ART)


## R37 · 「元素瓶 N/M」独立分区实际包围盒（供 ProdFlaskLabel 定位与避让断言读取）。
func get_flask_rect() -> Rect2:
	return _scaled_rect(ANCHOR_FLASK)


## R37 · 「你死了」独立分区实际包围盒（供 ProdDeathLabel 定位与避让断言读取）。
func get_death_rect() -> Rect2:
	return _scaled_rect(ANCHOR_DEATH)


func get_hud_layout() -> Dictionary:
	return {
		"viewport": _layout_viewport,
		"rects": get_layout_rects(),
		"center_char": get_center_char_rect(),
		"visible_side_panels": get_visible_side_panels(),
		"codex_open": is_codex_open(),
		"boon_draft_open": is_boon_draft_open(),
		"production_mechanism_rect": get_production_mechanism_rect(),
		"shop_title_rect": get_shop_title_rect(),
	}


# ==========================================================================
# 12) R32 · 右侧面板互斥状态机（Tab 图鉴 ↔ 兑换 ↔ 赐福抉择）
# ==========================================================================
var _codex_open: bool = false
var _boon_draft_open: bool = false
# R33 [ROUND=R33] · 赐福图鉴导演真实引用（右侧面板互斥的唯一仲裁者 = HUD）。
# 根因（总指挥回看 capture/v100_final.mp4 目视实证）：R30 的 CodexDirector 由
#   call_deferred 挂载、晚于 HUD 入树，其 _unhandled_input 在逆序分发中优先命中 Tab
#   并 vp.set_input_as_handled() 吞键 → HUD 收不到 Tab、_codex_open 恒 false、
#   get_visible_side_panels() 恒按 shop_open 返回 shop → 兑换/赐福成长面板常驻；
#   而 R32 的 19 条包围盒断言只读布局/逻辑态、直接 set_codex_open 绕过真实输入路径，
#   故全 PASS 却与实机不符。
# 修法：_ensure_codex_director() 保存引用并在 director 入树（_ready 执行完）后关闭
#   其自身 Tab 监听，由 HUD._unhandled_input → _process_r32_keys 统一仲裁；
#   apply_side_panel_visibility() 经公开 toggle_panel()/is_panel_open() 把互斥落实到
#   CodexDirector 真实 CanvasLayer.visible 与兑换 Label.visible（不是只做包围盒）。
# 独立 hud.tscn --script 实例无 SubViewportContainer → 引用恒 null、判空降级，
#   既有 19 条断言 / 58·30·11·127 PASS 逐字不回退。
var _codex_director: Node = null


func set_codex_open(open: bool) -> void:
	_codex_open = open
	apply_side_panel_visibility()


func is_codex_open() -> bool:
	return _codex_open


func _toggle_codex_panel() -> void:
	set_codex_open(not _codex_open)


## 右侧面板互斥：同一时刻最多 1 个可见；优先级 赐福抉择 > 图鉴 > 兑换。
## Tab 图鉴打开时隐藏常驻兑换面板、关闭时按 shop_open 原态恢复（shop_open 本身不变）。
func get_visible_side_panels() -> Array[String]:
	var out: Array[String] = []
	if _boon_draft_open:
		out.append("boon_draft")
	elif _codex_open:
		out.append("codex")
	elif shop_open:
		out.append("shop")
	return out


func is_side_panel_visible(panel: String) -> bool:
	return get_visible_side_panels().has(panel)


## 把互斥状态落实到真实节点 / 打击反馈层：图鉴或抉择打开时强制隐藏兑换 Label，
## 关闭后按 shop_open 恢复；R33 再把互斥落实到 CodexDirector 真实图鉴面板 visible，
## 使「图鉴打开 → 兑换/赐福成长确实隐藏；关闭 → 恢复」在真实 Tab 输入路径上生效，
## 不再只是包围盒布局。set_panel_open 让反馈层在面板区强化避让、不遮文字。
func apply_side_panel_visibility() -> void:
	var shop_visible: bool = is_side_panel_visible("shop")
	if _shop_label != null and is_instance_valid(_shop_label):
		_shop_label.visible = shop_visible
	_sync_codex_panel_visible()
	var fb: Node = _impact_feedback
	if fb != null and is_instance_valid(fb) and fb.has_method("set_panel_open"):
		fb.call("set_panel_open", "codex", is_side_panel_visible("codex"))
		fb.call("set_panel_open", "boon_draft", is_side_panel_visible("boon_draft"))
		fb.call("set_panel_open", "shop", shop_visible)


# ==========================================================================
# 13) R32 · 机制 B：Boss 韧性处决窗口（订阅 Rank-2 stagger_service 公开接口）
# ==========================================================================
# 边界：Rank-2 stagger_service.gd 为 RefCounted 纯逻辑、本轮并行交付（此刻未落盘）。
#   本层【只经公开方法 / 信号】鸭子类型适配，绝不静态引用其 class_name、绝不直接读
#   其私有实现字段；契约候选名成组登记，命中即用、缺失即降级、不伪造联调结果。
#   待 Rank-2 落盘后按真实接口名复跑 verify_stagger_runtime_v100.gd（见 DONE-R32.md）。
const STAGGER_SIGNAL_OPEN_CANDIDATES: Array[String] = [
	"execution_window_opened", "window_opened", "stance_broken"]
const STAGGER_SIGNAL_CLOSE_CANDIDATES: Array[String] = [
	"execution_window_closed", "window_closed"]
## Rank-2 真实服务还有 stagger_value_changed(current, maximum) 驱动韧性条（事件驱动，不轮询）。
const STAGGER_SIGNAL_CHANGED_CANDIDATES: Array[String] = ["stagger_value_changed"]
const STAGGER_METHOD_IS_OPEN: Array[String] = [
	"is_execution_window_open", "is_window_open", "window_open"]
const STAGGER_METHOD_REMAINING: Array[String] = [
	"get_window_remaining_sec", "get_window_remaining", "get_remaining_sec"]
const STAGGER_METHOD_POISE: Array[String] = [
	"get_poise_ratio", "get_boss_poise_ratio", "get_poise"]
const STAGGER_METHOD_EXECUTE: Array[String] = [
	"perform_execution", "try_execute", "execute"]
## [PLACEHOLDER] 处决窗口默认读秒：Rank-2 stagger_rules.tres 落盘前 HUD 侧降级初值。
## rationale：给「处决窗口」读秒一个可见但短促的初值，真实时长以 Rank-2 信号 / 方法为准。
const STAGGER_WINDOW_FALLBACK_SEC: float = 3.0

var _stagger_service: Object = null
var _stagger_window_open: bool = false
var _stagger_window_remaining: float = 0.0
var _stagger_poise_ratio: float = 1.0
var _stagger_execution_consumed: bool = false
var _execution_count: int = 0
var _stagger_window_id: String = ""
var _stagger_window_bonus: int = 0


## 绑定 Rank-2 服务：按契约候选信号名 connect（去重），再读一次公开态。
func bind_stagger_service(svc: Object) -> void:
	_unbind_stagger_signals()
	_stagger_service = svc
	if svc == null:
		return
	for sig: String in STAGGER_SIGNAL_OPEN_CANDIDATES:
		if svc.has_signal(sig):
			_dedup_connect_stagger(svc, sig, "_on_stagger_window_opened")
			break
	for sig: String in STAGGER_SIGNAL_CLOSE_CANDIDATES:
		if svc.has_signal(sig):
			_dedup_connect_stagger(svc, sig, "_on_stagger_window_closed")
			break
	for sig: String in STAGGER_SIGNAL_CHANGED_CANDIDATES:
		if svc.has_signal(sig):
			_dedup_connect_stagger(svc, sig, "_on_stagger_value_changed")
			break
	poll_stagger_service()


func _dedup_connect_stagger(svc: Object, sig: String, method: String) -> void:
	var cb: Callable = Callable(self, method)
	for conn in svc.get_signal_connection_list(sig):
		var c: Callable = conn.get("callable", Callable())
		if c.get_object() == self and String(c.get_method()) == method:
			return
	svc.connect(sig, cb)


## _exit_tree 兜底 disconnect：信号连接必须有明确释放路径，卸载后不留悬空 Callable。
func _unbind_stagger_signals() -> void:
	if _stagger_service == null or not is_instance_valid(_stagger_service):
		return
	var all_sigs: Array = STAGGER_SIGNAL_OPEN_CANDIDATES \
			+ STAGGER_SIGNAL_CLOSE_CANDIDATES + STAGGER_SIGNAL_CHANGED_CANDIDATES
	for sig: String in all_sigs:
		if not _stagger_service.has_signal(sig):
			continue
		var cb_open: Callable = Callable(self, "_on_stagger_window_opened")
		if _stagger_service.is_connected(sig, cb_open):
			_stagger_service.disconnect(sig, cb_open)
		var cb_close: Callable = Callable(self, "_on_stagger_window_closed")
		if _stagger_service.is_connected(sig, cb_close):
			_stagger_service.disconnect(sig, cb_close)
		var cb_changed: Callable = Callable(self, "_on_stagger_value_changed")
		if _stagger_service.is_connected(sig, cb_changed):
			_stagger_service.disconnect(sig, cb_changed)


## 真实服务 execution_window_opened(remaining_sec: float, bonus_points: int) 为 2 参：
## 第 2 参是额外点数（不是 window_id），此处按公开签名如实承接。
func _on_stagger_window_opened(remaining_sec: Variant = null, bonus_points: Variant = null, _c: Variant = null) -> void:
	_open_execution_window(remaining_sec, bonus_points)


func _on_stagger_window_closed(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	_close_execution_window()


## 真实服务 stagger_value_changed(current, maximum) → 韧性条比例（事件驱动，不轮询）。
func _on_stagger_value_changed(current: Variant = null, maximum: Variant = null, _c: Variant = null) -> void:
	if current == null or maximum == null:
		return
	if (typeof(current) == TYPE_FLOAT or typeof(current) == TYPE_INT) \
			and (typeof(maximum) == TYPE_FLOAT or typeof(maximum) == TYPE_INT):
		var mx: float = float(maximum)
		if mx > 0.0:
			_stagger_poise_ratio = clampf(float(current) / mx, 0.0, 1.0)


func _open_execution_window(remaining: Variant, bonus: Variant) -> void:
	var sec: float = STAGGER_WINDOW_FALLBACK_SEC
	if remaining != null and (typeof(remaining) == TYPE_FLOAT or typeof(remaining) == TYPE_INT):
		sec = maxf(0.0, float(remaining))
	_stagger_window_open = true
	_stagger_window_remaining = sec
	_stagger_execution_consumed = false
	_stagger_window_bonus = int(bonus) if (bonus != null \
			and (typeof(bonus) == TYPE_INT or typeof(bonus) == TYPE_FLOAT)) else 0
	# A58 [ROUND=R35]：处决窗口统一生成【非空且唯一】的 window_id（exe_<wave>_<seq>），
	#   随 execution_performed 带出 → Rank-3 编排层 "exe:<window_id>" 去重键不再合并不同窗口。
	#   生成规则 / 失败降级见文件尾 _r35_make_window_id()。
	_stagger_window_id = _r35_make_window_id("exe")


func _close_execution_window() -> void:
	_stagger_window_open = false
	_stagger_window_remaining = 0.0


## 从公开方法回读状态（不碰私有字段）：由信号回调 / 显式推进调用，不在 _process 每帧轮询。
func poll_stagger_service() -> void:
	if _stagger_service == null or not is_instance_valid(_stagger_service):
		return
	var svc: Object = _stagger_service
	# 首选 get_snapshot()（Rank-2 真实服务稳定公开接口）：一次读回韧性 / 窗口态，
	# 不碰任何私有字段；缺失再回落候选方法（兼容替身 / 旧口径）。
	if svc.has_method("get_snapshot"):
		var snap: Variant = svc.call("get_snapshot")
		if typeof(snap) == TYPE_DICTIONARY:
			var d: Dictionary = snap as Dictionary
			var cur: float = float(d.get("stagger", 0.0))
			var mx: float = float(d.get("stagger_max", 1.0))
			if mx > 0.0:
				_stagger_poise_ratio = clampf(cur / mx, 0.0, 1.0)
			var wo: Variant = d.get("window_open", null)
			if typeof(wo) == TYPE_BOOL:
				if bool(wo) and not _stagger_window_open:
					_open_execution_window(d.get("window_remaining", null), d.get("execute_bonus_points", null))
				elif not bool(wo) and _stagger_window_open:
					_close_execution_window()
			if _stagger_window_open and d.has("window_remaining"):
				_stagger_window_remaining = maxf(0.0, float(d.get("window_remaining", 0.0)))
			return
	for m: String in STAGGER_METHOD_POISE:
		if svc.has_method(m):
			_stagger_poise_ratio = clampf(float(svc.call(m)), 0.0, 1.0)
			break
	var is_open: Variant = null
	for m: String in STAGGER_METHOD_IS_OPEN:
		if svc.has_method(m):
			is_open = svc.call(m)
			break
	if is_open != null and typeof(is_open) == TYPE_BOOL:
		if bool(is_open) and not _stagger_window_open:
			_open_execution_window(null, null)
		elif not bool(is_open) and _stagger_window_open:
			_close_execution_window()
	if _stagger_window_open:
		for m: String in STAGGER_METHOD_REMAINING:
			if svc.has_method(m):
				_stagger_window_remaining = maxf(0.0, float(svc.call(m)))
				break


## 处决窗口读秒推进（显式驱动，确定性；超时自动关窗 = 契约「超时关闭」）。
func tick_stagger(delta: float) -> void:
	if not _stagger_window_open:
		return
	_stagger_window_remaining = maxf(0.0, _stagger_window_remaining - maxf(0.0, delta))
	if _stagger_window_remaining <= 0.0:
		_close_execution_window()


## 窗口内触发一次处决：重复触发 / 窗口外一律拒绝；成功后 emit execution_performed。
func request_execution() -> Dictionary:
	if not _stagger_window_open:
		return {"ok": false, "reason": "window_closed"}
	if _stagger_execution_consumed:
		return {"ok": false, "reason": "already_executed"}
	_stagger_execution_consumed = true
	_execution_count += 1
	var bonus: int = 0
	if _stagger_service != null and is_instance_valid(_stagger_service):
		for m: String in STAGGER_METHOD_EXECUTE:
			if _stagger_service.has_method(m):
				var r: Variant = _stagger_service.call(m)
				if typeof(r) == TYPE_DICTIONARY:
					bonus = int((r as Dictionary).get("bonus_points", 0))
				break
	execution_performed.emit(_stagger_window_id, bonus)
	# R34 e 链：处决额外点数只发信号 / 传参给 Rank-3 I-1 权威写入点，Rank-1 不写存档文件（A50）。
	points_awarded.emit("execution", bonus, "stagger_service.try_execute")
	_r34_points_count += 1
	# 处决消耗本窗口一次机会；窗口本身由 tick_stagger 超时 / Rank-2 closed 信号关闭。
	# 窗口内重复 F 由 _stagger_execution_consumed 拒绝（契约「重复触发拒绝」）。
	return {"ok": true, "reason": "ok",
			"execution_count": _execution_count, "bonus_points": bonus}


func _try_execution_input() -> void:
	request_execution()


## HUD 显示数据（Boss 韧性条 / 处决窗口读秒），纯只读快照供验证与渲染回读。
func get_stagger_hud_view() -> Dictionary:
	return {
		"window_open": _stagger_window_open,
		"remaining_sec": _stagger_window_remaining,
		"poise_ratio": _stagger_poise_ratio,
		"execution_consumed": _stagger_execution_consumed,
		"execution_count": _execution_count,
		"window_id": _stagger_window_id,
		"window_bonus": _stagger_window_bonus,
		"service_available": _stagger_service != null and is_instance_valid(_stagger_service),
		"poise_text": "Boss 韧性 %d%%" % int(_stagger_poise_ratio * 100.0),
		"window_text": ("处决窗口 %.1fs · 按 F" % _stagger_window_remaining) if _stagger_window_open else "",
	}


# ==========================================================================
# 14) R32 · 机制 A：赐福抉择三选一卡片（调用 Rank-2 boon_draft_service.select）
# ==========================================================================
const BOON_METHOD_CANDIDATES: Array[String] = ["get_candidates", "get_options", "get_choices"]

var _boon_draft_service: Object = null
var _boon_draft_choices: Array = []
var _boon_draft_selected_index: int = -1
var _boon_draft_last_result: Dictionary = {}


func bind_boon_draft_service(svc: Object) -> void:
	_boon_draft_service = svc


## 每波清波后钩子（wave_cleared）：显示三选一卡片；与图鉴 / 兑换互斥、不遮中央角色。
func on_wave_cleared(_index: Variant = null, _points: Variant = null) -> void:
	show_boon_draft()


func show_boon_draft(choices: Array = []) -> void:
	_boon_draft_choices = choices.duplicate(true)
	if _boon_draft_choices.is_empty() and _boon_draft_service != null \
			and is_instance_valid(_boon_draft_service):
		for m: String in BOON_METHOD_CANDIDATES:
			if _boon_draft_service.has_method(m):
				var c: Variant = _boon_draft_service.call(m)
				if typeof(c) == TYPE_ARRAY:
					_boon_draft_choices = (c as Array).duplicate(true)
				break
		# 契约适配：真实 BoonDraftService 的候选在 get_config() → BoonDraftConfig.boons
		# （Array[Dictionary]）；用鸭子类型读，不静态引用 Rank-2 class_name、不读私有实现。
		if _boon_draft_choices.is_empty() and _boon_draft_service.has_method("get_config"):
			var cfg: Object = _boon_draft_service.call("get_config") as Object
			if cfg != null:
				var raw: Variant = cfg.get("boons")
				if typeof(raw) == TYPE_ARRAY:
					for row: Variant in (raw as Array):
						if typeof(row) == TYPE_DICTIONARY:
							var d: Dictionary = row as Dictionary
							_boon_draft_choices.append({
								"id": String(d.get("id", "")),
								"title": String(d.get("title", "")),
							})
	_boon_draft_open = true
	_boon_draft_selected_index = -1
	_boon_draft_last_result = {}
	apply_side_panel_visibility()


func close_boon_draft() -> void:
	_boon_draft_open = false
	apply_side_panel_visibility()


func is_boon_draft_open() -> bool:
	return _boon_draft_open


## 数字键 1/2/3 选择：与既有兑换数字键做状态隔离（_process_r32_keys 拦截），不误触。
func _select_boon_draft(index: int) -> Dictionary:
	if not _boon_draft_open:
		return {"ok": false, "reason": "draft_closed"}
	if index < 0 or index > 2:
		return {"ok": false, "reason": "invalid_index"}
	var result: Dictionary = {"ok": true, "reason": "selection_recorded"}
	if _boon_draft_service != null and is_instance_valid(_boon_draft_service) \
			and _boon_draft_service.has_method("select"):
		var r: Variant = _boon_draft_service.call("select", index)
		if typeof(r) == TYPE_DICTIONARY:
			result = r as Dictionary
	else:
		result["service_available"] = false
	_boon_draft_selected_index = index
	_boon_draft_last_result = result
	var choice_id: String = ""
	if index < _boon_draft_choices.size():
		var c: Variant = _boon_draft_choices[index]
		if typeof(c) == TYPE_DICTIONARY:
			choice_id = String((c as Dictionary).get("id", ""))
	boon_draft_selected.emit(index, choice_id)
	# R34 d 链：抉择选中 → 真实 apply() 结算生效 + 广播成对 effect/cost 给下一波消费方。
	_r34_settle_boon_draft(index, choice_id)
	close_boon_draft()
	return result


func get_boon_draft_view() -> Dictionary:
	return {
		"open": _boon_draft_open,
		"choices": _boon_draft_choices.duplicate(true),
		"selected_index": _boon_draft_selected_index,
		"last_result": _boon_draft_last_result.duplicate(),
		"service_available": _boon_draft_service != null and is_instance_valid(_boon_draft_service),
		"rect": _scaled_rect(ANCHOR_SIDE),
		"overlaps_center_char": _scaled_rect(ANCHOR_SIDE).intersection(get_center_char_rect()).get_area() > 0.0,
	}


# ==========================================================================
# 15) R32 · 输入状态隔离（既有 _unhandled_input 逻辑逐字保留在其后）
# ==========================================================================
func _digit_index(pc: int, kc: int) -> int:
	for i: int in range(3):
		var key_code: int = KEY_1 + i
		if pc == key_code or kc == key_code:
			return i
	return -1


## 返回是否消费该事件。抉择卡片打开时数字键 1/2/3 只走抉择、其余键一律拦截，
## 绝不落到既有兑换逻辑（状态隔离避免误触）。F / Tab 走处决 / 图鉴互斥。
func _process_r32_keys(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var k: InputEventKey = event as InputEventKey
	if not k.pressed or k.echo:
		return false
	var pc: int = k.physical_keycode
	var kc: int = k.keycode
	# R37 [ROUND=R37] · 死亡态门禁（任务②「死亡期间拒绝 G/Q/K/F」）：death_service 权威
	#   死亡态期间对 G/Q/K/F（+R 切换）消费事件但不执行；E（赐福休息 → 重生）/ Tab /
	#   数字键既有行为逐字不动。权威态只读 A54 唯一 death_service 快照 _r37_is_dead()，
	#   不新增第二套胜负判定、不改既有普通攻击判定 / 帧数据 / 输出格式。
	if _r37_is_dead() and (pc == KEY_G or kc == KEY_G or pc == KEY_Q or kc == KEY_Q \
			or pc == KEY_K or kc == KEY_K or pc == KEY_F or kc == KEY_F \
			or pc == KEY_R or kc == KEY_R):
		_r37_hint_text = "死亡期间无法行动"
		_r37_hint_remaining = R37_HINT_SHOW_SEC
		_r37_refresh_flask()
		return true
	if _boon_draft_open:
		var di: int = _digit_index(pc, kc)
		if di >= 0:
			_select_boon_draft(di)
		return true
	if pc == KEY_TAB or kc == KEY_TAB:
		_toggle_codex_panel()
		return true
	if pc == KEY_F or kc == KEY_F:
		_try_execution_input()
		return true
	# R35：精准弹反真实 K 输入（与 F / Tab 同走 HUD 单一 _unhandled_input → R32 键路径）。
	#   生产窗口状态由 A54 唯一 ParryService 决定；窗口外 / 重复 / 冷却由 request_parry 门控拒绝。
	if pc == KEY_K or kc == KEY_K:
		_try_parry_input()
		return true
	# R36：战技 Q 真实输入（与 F / Tab / K 同走 HUD 单一 _unhandled_input → R32 键路径）。
	#   权威判定 = request_focus_skill()（复用 A54 唯一 focus_service）；ENC 侧同接 Q 并转发
	#   到本入口，靠 event 实例幂等去重，绝不重复扣 FP / 不重复发信号。
	if pc == KEY_Q or kc == KEY_Q:
		_try_focus_skill_input(event)
		return true
	# R36B [ROUND=R36B / A69 裁决]：战技切换 R 真实输入（与 F / Tab / K / Q 同走 HUD
	#   单一 _unhandled_input → _process_r32_keys 仲裁者路径）。权威判定 = request_art_switch()
	#   （只读 A54 唯一 focus_service 的 arts 列表循环切换，不自建第二实例、不改表数值）。
	#   ENC 侧同接 R 并转发本入口，靠 event 实例幂等去重；切换不改 FP / 冷却，消费事件后
	#   return true，绝不落到既有 interact / 数字键逻辑（R 不误触其它键）。
	if pc == KEY_R or kc == KEY_R:
		_try_art_switch_input(event)
		return true
	# R37 [ROUND=R37] · 元素瓶 G 真实输入（与 F / Tab / K / Q / R 同走 HUD
	#   单一 _unhandled_input → _process_r32_keys 仲裁者路径）。权威判定 =
	#   request_flask_use()（复用 A54 唯一 flask_service 判定瓶数 / HP）；
	#   ENC 侧同接 G 并转发本入口，靠同一 event 实例幂等去重，绝不重复扣瓶。
	if pc == KEY_G or kc == KEY_G:
		_try_flask_input(event)
		return true
	return false


## 验证 / 注入入口：与 _unhandled_input 走完全相同的 R32 键处理路径（确定性，不需帧分发）。
func process_key_event(event: InputEvent) -> bool:
	return _process_r32_keys(event)


func _exit_tree() -> void:
	_unbind_stagger_signals()
	_codex_director = null
	_r34_release()
	_r37_release()                      # R37：ENC.grace_rested 生产订阅的释放路径


# ==========================================================================
# 16) R34 [ROUND=R34] · 生产运行时触发链 c) / d) / e) / f)（HUD 单一 Tab 仲裁者口径不回退）
#   把 R33「演示专用可见层 + 演示驱动显式服务调用」升级为生产常驻：
#     c) 清波 → 卡片：订阅真实 WaveTrialDirector.wave_cleared(index, points)
#        → _r34_on_wave_cleared → 既有 on_wave_cleared() 显示三选一卡片。
#     d) apply/settle 消费方：_select_boon_draft() 后真实 BoonDraftService.apply()
#        结算生效，emit boon_draft_applied(成对 effect/cost)；下一波 wave_started
#        广播 production_wave_modifier 给 Rank-2 wave_trial_director 消费（不改其文件）。
#     e) 点数落盘：points_awarded(reason, points, source) 只发信号 / 传参给
#        Rank-3 I-1 权威写入点，Rank-1 不 set_flag / 不 commit / 不写存档（A50）。
#     f) 生产 HUD 常驻可见节点：hud.gd 自身建 ProductionMechanismsLayer（韧性条 +
#        读秒/F Label + 三选一卡片 Label + 连击 Label），按状态显示，不再由
#        presentation.gd 动态构造；文本全部读 HUD 公开快照，不写既有 Label.text。
#   既有 1~15 节逻辑 / 6 信号 / 19+5 条断言 / 1~14 关键方法签名逐字不动。
#   --script 独立 hud.tscn 实例：无 SubViewportContainer 父链 → 可见层判空降级、不建节点，
#   不影响既有 24 / 16 / 42 PASS；signal connect 用 get_signal_connection_list 去重、
#   _exit_tree 有 disconnect 释放路径；资源回读 CACHE_MODE_IGNORE。
# ==========================================================================

const R34_BOON_SVC_PATH: String = "res://scripts/combat/boon_draft_service.gd"
const R34_BOON_CFG_PATH: String = "res://data/rpg/boon_draft.tres"
const R34_COMBO_SVC_PATH: String = "res://scripts/combat/combo_service.gd"
const R34_COMBO_CFG_PATH: String = "res://data/rpg/combo_rules.tres"
const R34_LAYER_NAME: String = "ProductionMechanismsLayer"
const R34_LAYER_INDEX: int = 48
# [PLACEHOLDER] 可见层位置沿用 R33 右上空白区，待试玩校准（rationale：避开 quality /
#   shop / Boss+中央角色 / codex / 底部条，首帧隐藏不遮角色；调参只改本节常量）。
const R34_RECT_LEFT: float = 900.0
const R34_RECT_TOP: float = 190.0
const R34_RECT_RIGHT: float = 1276.0
const R34_RECT_BOTTOM: float = 352.0

var _r34_combo: Object = null                 # 生产 ComboService（HUD 创建，注入导演层）
var _r34_wave: Node = null                    # WaveTrialDirector 引用（订阅 wave_cleared/wave_started）
var _r34_prod_layer: CanvasLayer = null       # f 链常驻可见层
var _r34_poise_bar: ProgressBar = null
var _r34_stagger_label: Label = null
var _r34_draft_label: Label = null
var _r34_combo_label: Label = null
var _r34_bootstrapped: bool = false
var _r34_wave_cleared_connected: bool = false
var _r34_wave_started_connected: bool = false
var _r34_points_count: int = 0                # points_awarded 发出次数（e 链可观测）
var _r34_last_boon_apply: Dictionary = {}     # d 链最后一次 apply() 结算结果
var _r34_boon_forward_ok: bool = false        # d 链抉择是否已注入 Rank-2 下游消费方
var _r34_pending_wave_modifier: Dictionary = {}  # 待作用下一波的修正
var _r34_active_wave_modifier: Dictionary = {}   # 已广播给下一波的修正
var _r34_wave_modifier_broadcast_count: int = 0


## A54 [ROUND=R34B] · 唯一实例收敛：
##   ComboService / BoonDraftService 唯一实例归属 wave_trial_director.gd；
##   本层【绝不另建第二个实例】。生产 _ready 不再 new 任何服务，
##   由 _r34_bootstrap() 经 get_combo_service()/get_boon_service() 复用 Rank-2
##   装配的唯一实例并 bind（消除 Rank-2 登记的「双实例归属」待裁决项）。
##   修前根因：命中转发到 HUD 自建 combo、清波结算用 wave 自建 combo → combo 恒 0。
func _r34_create_boon_service() -> void:
	print("[R34B][HUD] A54 唯一实例：不自建 Combo/Boon 服务，由 _r34_bootstrap() 经 get_combo_service()/get_boon_service() 绑定 wave_trial_director 唯一实例")


# ---- R34B [ROUND=R34B] · 4 信号订阅 / 连击 HUD 视图 / 任务2 作用链路（追加）----
# 以下成员声明与函数均位于类体，顺序不影响 GDScript 解析（--check-only 实证）。

## 连击 HUD 视图（4 个公开信号事件驱动；供 Rank-4 连击视觉反馈 / 验证读取，不写盘）。
var _r34_combo_view: Dictionary = {
	"count": 0, "rank": "D", "multiplier": 1.0,
	"last_rank_from": "", "last_reset_reason": "", "last_settlement": {},
	"changed_count": 0, "rank_changed_count": 0, "reset_count": 0, "settled_count": 0,
}
var _r34_combo_signals_connected: bool = false


## 订阅 ComboService 唯一实例的 4 个公开信号（DONE-R34.md §3.1 签名）。
## connect 前用 get_signal_connection_list 去重；_r34_release 有 disconnect 释放路径。
func _r34_connect_combo_signals() -> void:
	if _r34_combo == null or not is_instance_valid(_r34_combo):
		return
	_r34_dedup_connect(_r34_combo, "combo_changed", "_r34_on_combo_changed")
	_r34_dedup_connect(_r34_combo, "rank_changed", "_r34_on_rank_changed")
	_r34_dedup_connect(_r34_combo, "combo_reset", "_r34_on_combo_reset")
	_r34_dedup_connect(_r34_combo, "combo_settled", "_r34_on_combo_settled")
	_r34_combo_signals_connected = true
	_r34_refresh_combo_view()


func _r34_disconnect_combo_signals() -> void:
	if _r34_combo == null or not is_instance_valid(_r34_combo):
		return
	var pairs: Array = [
		["combo_changed", "_r34_on_combo_changed"],
		["rank_changed", "_r34_on_rank_changed"],
		["combo_reset", "_r34_on_combo_reset"],
		["combo_settled", "_r34_on_combo_settled"],
	]
	for p: Array in pairs:
		var sig: String = str(p[0])
		var cb: Callable = Callable(self, str(p[1]))
		if _r34_combo.has_signal(sig) and _r34_combo.is_connected(sig, cb):
			_r34_combo.disconnect(sig, cb)
	_r34_combo_signals_connected = false


## 从唯一实例公开只读接口刷新视图（事件驱动，不轮询）。
func _r34_refresh_combo_view() -> void:
	if _r34_combo == null or not is_instance_valid(_r34_combo):
		return
	if _r34_combo.has_method("get_snapshot"):
		var d: Dictionary = _r34_combo.call("get_snapshot") as Dictionary
		_r34_combo_view["count"] = int(d.get("combo", d.get("count", _r34_combo_view["count"])))
		_r34_combo_view["rank"] = str(d.get("rank", _r34_combo_view["rank"]))
		_r34_combo_view["multiplier"] = float(d.get("multiplier", _r34_combo_view["multiplier"]))


## 4 信号回调（签名逐字对齐 DONE-R34.md §3.1；Variant 形参兼容鸭子类型）。
func _r34_on_combo_changed(count: Variant = null, rank: Variant = null) -> void:
	if count != null:
		_r34_combo_view["count"] = int(count)
	if rank != null:
		_r34_combo_view["rank"] = str(rank)
	_r34_combo_view["changed_count"] = int(_r34_combo_view["changed_count"]) + 1
	_r34_refresh_visible()


func _r34_on_rank_changed(from_rank: Variant = null, to_rank: Variant = null, multiplier: Variant = null) -> void:
	if to_rank != null:
		_r34_combo_view["rank"] = str(to_rank)
	if from_rank != null:
		_r34_combo_view["last_rank_from"] = str(from_rank)
	if multiplier != null:
		_r34_combo_view["multiplier"] = float(multiplier)
	_r34_combo_view["rank_changed_count"] = int(_r34_combo_view["rank_changed_count"]) + 1
	_r34_refresh_visible()


func _r34_on_combo_reset(reason: Variant = null) -> void:
	_r34_combo_view["last_reset_reason"] = str(reason) if reason != null else ""
	_r34_combo_view["reset_count"] = int(_r34_combo_view["reset_count"]) + 1
	_r34_refresh_combo_view()
	_r34_refresh_visible()


func _r34_on_combo_settled(total_points: Variant = null, base_points: Variant = null,
		rank: Variant = null, multiplier: Variant = null) -> void:
	_r34_combo_view["last_settlement"] = {
		"total_points": int(total_points) if total_points != null else 0,
		"base_points": int(base_points) if base_points != null else 0,
		"rank": str(rank) if rank != null else "",
		"multiplier": float(multiplier) if multiplier != null else 1.0,
	}
	_r34_combo_view["settled_count"] = int(_r34_combo_view["settled_count"]) + 1
	_r34_refresh_visible()


## 生产 HUD 连击可见层视图（供 Rank-4 连击视觉反馈 / 验证读取）。
func get_combo_hud_view() -> Dictionary:
	return _r34_combo_view.duplicate()


## 供 Rank-4 / 验证取 A54 唯一实例（同一 ComboService，不经场景树）。
func get_combo_service() -> Object:
	return _r34_combo


## 任务 2 [R34B]：波次开始时把 boon_draft 的 cost_key/effect_key 从「导演层记录」
##   推到 EncounterDirector 的运行时敌人参数（hp_scale / telegraph_scale / 削韧）。
## 数据源：① Rank-2 wave_trial_director.get_snapshot() 的 boon_cost_key /
##   boon_effect_key / boon_cost_value（导演层记录，R34 只到这一层）；
##   ② HUD _r34_active_wave_modifier（BoonDraftConfig.apply 真实成对数据，字段齐全）。
## 两者皆缺 / 非法 → 传空 key，由 enc 回落基础值并 push_warning 告警（失败降级）。
## 不改 .tres / courtyard.tscn / 判定分支；不写存档（A50）。
func _r34b_apply_wave_enemy_params(wave_index: int) -> void:
	var ml: MainLoop = Engine.get_main_loop()
	var courtyard: Node = null
	if ml is SceneTree:
		courtyard = (ml as SceneTree).root.get_node_or_null(NodePath("Courtyard"))
	if courtyard == null:
		courtyard = _r34_find_mount_root()
	if courtyard == null:
		return
	var enc: Node = courtyard.get_node_or_null(NodePath("EncounterRoot"))
	if enc == null or not enc.has_method("apply_wave_enemy_params"):
		return
	var m: Dictionary = _r34_active_wave_modifier.duplicate()
	if m.is_empty():
		m = _r34_pending_wave_modifier.duplicate()
	# ① 导演层记录（Rank-2 get_snapshot 的 boon_* 只读 key）
	if _r34_wave != null and is_instance_valid(_r34_wave) \
			and _r34_wave.has_method("get_snapshot"):
		var ws: Dictionary = _r34_wave.call("get_snapshot") as Dictionary
		var wcost: String = str(ws.get("boon_cost_key", ""))
		var weff: String = str(ws.get("boon_effect_key", ""))
		var wval: float = float(ws.get("boon_cost_value", 0.0))
		if not wcost.is_empty():
			m["cost_key"] = wcost
			m["cost_value"] = wval
		if not weff.is_empty():
			m["effect_key"] = weff
	var r: Dictionary = enc.call("apply_wave_enemy_params", wave_index,
			str(m.get("effect_key", "")), float(m.get("effect_value", 0.0)),
			str(m.get("cost_key", "")), float(m.get("cost_value", 0.0))) as Dictionary
	print("[R34B][HUD] 任务2 作用链路：wave_started(index=%d) → apply_wave_enemy_params → 运行时敌人参数 | cost=%s(%.2f) effect=%s(%.2f) applied=%s degraded=%s" % [
			wave_index, str(m.get("cost_key", "")), float(m.get("cost_value", 0.0)),
			str(m.get("effect_key", "")), float(m.get("effect_value", 0.0)),
			str(r.get("applied", false)), str(r.get("degraded", false))])


## ComboService 注入口：装配层（生产）/ 验证进程（契约替身）注入真实或替身实例，
## 鸭子类型、不静态引用 Rank-2 class_name。同时转注入 EncounterDirector 的命中转发链。
func bind_combo_service(svc: Object) -> void:
	_r34_combo = svc
	var ml: MainLoop = Engine.get_main_loop()
	var enc: Node = null
	if ml is SceneTree:
		var courtyard: Node = (ml as SceneTree).root.get_node_or_null(NodePath("Courtyard"))
		if courtyard == null:
			courtyard = _r34_find_mount_root()
		if courtyard != null:
			enc = courtyard.get_node_or_null(NodePath("EncounterRoot"))
	if enc != null and enc.has_method("bind_combo_service"):
		enc.call("bind_combo_service", svc)


## 跨节点装配（生产 call_deferred / 验证显式 call）：拉同一 StaggerService、
## A54 复用 wave 唯一 Combo/Boon 实例、订阅 4 个 combo 信号 + 真实波次信号、
## 建生产常驻可见层、启用显示层 _process。
func _r34_bootstrap() -> void:
	if _r34_bootstrapped:
		return
	_r34_bootstrapped = true
	var ml: MainLoop = Engine.get_main_loop()
	var courtyard: Node = null
	if ml is SceneTree:
		courtyard = (ml as SceneTree).root.get_node_or_null(NodePath("Courtyard"))
	if courtyard == null:
		courtyard = _r34_find_mount_root()
	if courtyard != null:
		var enc: Node = courtyard.get_node_or_null(NodePath("EncounterRoot"))
		if enc != null and enc.has_method("get_stagger_service"):
			var ss: Object = enc.call("get_stagger_service") as Object
			if ss != null and _stagger_service != ss:
				bind_stagger_service(ss)
		var wave: Node = courtyard.get_node_or_null(NodePath("WaveTrialDirector"))
		if wave != null:
			_r34_wave = wave
			# A54 [R34B]：唯一实例归属 wave_trial_director.gd，绝不另建第二个实例。
			# 命中转发（enc）/ 清波结算（wave）/ HUD 显示 三方共用同一 ComboService。
			if wave.has_method("get_combo_service"):
				var combo: Object = wave.call("get_combo_service") as Object
				if combo != null and is_instance_valid(combo):
					bind_combo_service(combo)         # 存 HUD 引用 + 转注入 enc 命中/tick 转发链
					_r34_connect_combo_signals()     # 任务1 e：订阅 4 个公开信号
			if wave.has_method("get_boon_service"):
				var boon: Object = wave.call("get_boon_service") as Object
				if boon != null and is_instance_valid(boon):
					bind_boon_draft_service(boon)    # HUD 卡片显示复用同一 BoonDraftService
			_r34_dedup_connect(wave, "wave_cleared", "_r34_on_wave_cleared")
			_r34_dedup_connect(wave, "wave_started", "_r34_on_wave_started")
			# A54 [R35]：ParryService 唯一实例归属 wave_trial_director.gd，
			#   本层【绝不另建第二个实例】，只经 get_parry_service() 复用并 bind。
			if wave.has_method("get_parry_service"):
				var parry: Object = wave.call("get_parry_service") as Object
				if parry != null and is_instance_valid(parry):
					bind_parry_service(parry)
					print("[R35][HUD] A54 唯一 ParryService 已复用 wave.get_parry_service()（不自建第二实例）")
	_r34_build_visible()
	_r36_bootstrap()                     # R36：A54 唯一 focus_service + A65 免伤 / 赐福回满 生产订阅
	_r37_bootstrap()                     # R37：A54 唯一 flask/death_service + 赐福重生 生产订阅
	set_process(true)
	_r34_refresh_visible()
	print("[R34][HUD] 生产链装配完成 | stagger_bound=%s boon_bound=%s combo_bound=%s combo_signals=%s wave_cleared=%s wave_started=%s visible=%s" % [
			str(_stagger_service != null), str(_boon_draft_service != null), str(_r34_combo != null),
			str(_r34_combo_signals_connected),
			str(_r34_wave_cleared_connected), str(_r34_wave_started_connected),
			str(_r34_prod_layer != null and is_instance_valid(_r34_prod_layer) and _r34_prod_layer.is_inside_tree())])


func _r34_dedup_connect(obj: Object, sig: String, method: String) -> void:
	if obj == null or not obj.has_signal(sig):
		return
	var cb: Callable = Callable(self, method)
	for conn in obj.get_signal_connection_list(sig):
		var c: Callable = conn.get("callable", Callable())
		if c.get_object() == self and String(c.get_method()) == method:
			_r34_mark_connected(sig)
			return
	obj.connect(sig, cb)
	_r34_mark_connected(sig)


func _r34_mark_connected(sig: String) -> void:
	if sig == "wave_cleared":
		_r34_wave_cleared_connected = true
	elif sig == "wave_started":
		_r34_wave_started_connected = true


## c) 真实 wave_cleared → HUD 卡片；e) 清波点数只发信号给 Rank-3（不写盘）。
## ---- A57 [ROUND=R34D] · 发射值修正（总指挥裁决 A57，最后一处玩法分叉）----
##   points_awarded(reason, points, source) 的 points 必须携带【最终结算值（含连击倍率）】；
##   wave_cleared(index, points) 第二参保留基础值，只作 HUD 展示与事件键（on_wave_cleared 用）；
##   combo_settled(total, base, rank, mult) 只作对账 / 展示（HUD 订阅更新视图），绝不二次入账
##   —— 本函数每条 wave_cleared 只发 1 次 points_awarded，Rank-3 编排层「原样采信」落盘（A55 不变）。
##   取源：A54 唯一 ComboService 实例（get_combo_service() → _r34_combo，与 wave._combo 同一实例）。
##   wave_trial_director._clear_wave() 先 settle() 再 emit wave_cleared，故 get_last_settlement()
##   此时即本次清波的倍率后结算（ok / settled / total_points）。
##   失败降级：无有效结算 → 回落基础值 + push_warning 告警（不静默吞掉）。
func _r34_on_wave_cleared(index: Variant = null, points: Variant = null) -> void:
	on_wave_cleared(index, points)
	var base_pts: int = int(points) if points != null else 0
	# A57：最终结算值（含连击倍率）默认回落基础值，取到有效结算后覆盖。
	var final_pts: int = base_pts
	var settled_ok: bool = false
	var combo: Object = get_combo_service()
	if combo != null and is_instance_valid(combo) and combo.has_method("get_last_settlement"):
		var last: Dictionary = combo.call("get_last_settlement") as Dictionary
		if bool(last.get("ok", false)) and bool(last.get("settled", false)) \
				and int(last.get("total_points", 0)) > 0:
			final_pts = int(last.get("total_points", base_pts))
			settled_ok = true
	# 回落：无有效结算 → 尝试一次 settle(base_pts)（幂等）；仍无 → 回落基础值并告警。
	if not settled_ok and combo != null and is_instance_valid(combo) and combo.has_method("settle"):
		var r: Dictionary = combo.call("settle", base_pts) as Dictionary
		if bool(r.get("ok", false)) and int(r.get("total_points", 0)) > 0:
			final_pts = int(r.get("total_points", base_pts))
			settled_ok = true
	if not settled_ok:
		push_warning("[R34D][HUD] A57 降级：清波未取到有效倍率结算 → points_awarded 回落基础值 base=%d（失败降级，不静默吞掉）" % base_pts)
	# ★ 每条 wave_cleared 事件只发一次 points_awarded（绝不重复入账）。
	points_awarded.emit("wave_cleared", final_pts, "wave_trial_director.wave_cleared")
	_r34_points_count += 1
	_r34_refresh_visible()
	print("[R34D][HUD] A57 c 链：真实 wave_cleared(index=%s base=%d final=%d settled=%s) → 抉择卡片 open=%s | points_awarded 已发一次（携带倍率后值）" % [
			str(index), base_pts, final_pts, str(settled_ok), str(is_boon_draft_open())])


## d) 下一波 wave_started → 把上一波抉择修正广播给 Rank-2 消费方（作用于下一波）。
func _r34_on_wave_started(index: Variant = null, _total: Variant = null) -> void:
	var wi: int = int(index) if index != null else 0
	if not _r34_pending_wave_modifier.is_empty():
		var m: Dictionary = _r34_pending_wave_modifier
		_r34_active_wave_modifier = m.duplicate()
		_r34_wave_modifier_broadcast_count += 1
		production_wave_modifier.emit(wi,
				String(m.get("effect_key", "")), float(m.get("effect_value", 0.0)),
				String(m.get("cost_key", "")), float(m.get("cost_value", 0.0)))
		print("[R34][HUD] d 链：下一波 wave_started(index=%d) → production_wave_modifier 广播 effect=%s cost=%s（供 Rank-2 消费）" % [
				wi, String(m.get("effect_key", "")), String(m.get("cost_key", ""))])
	# 任务 2 [R34B]：波次开始把抉择代价从「导演层记录」推到运行时敌人参数；
	# 无抉择修正时也调用一次，由 enc 回落基础值并告警（失败降级实证）。
	_r34b_apply_wave_enemy_params(wi)
	_r34_refresh_visible()


## d) 抉择选中 → 真实 apply() 结算生效 + emit boon_draft_applied（成对 effect/cost）。
## 并把抉择注入 Rank-2 wave_trial_director 的 boon 服务（其 select_boon(index) 公开注入口），
## 使 Rank-2 在下一波 _clear_wave() 的 apply()/settle() 真正消费「玩家所选」——
## 只调用公开方法 / 鸭子类型判空降级，不改 wave_trial_director.gd 文件（Rank-2 唯一写入方）。
func _r34_settle_boon_draft(index: int, choice_id: String) -> void:
	var forwarded: bool = false
	if _r34_wave != null and is_instance_valid(_r34_wave) \
			and _r34_wave.has_method("select_boon"):
		var fr: Variant = _r34_wave.call("select_boon", index)
		var fr_ok: bool = (typeof(fr) == TYPE_DICTIONARY and bool((fr as Dictionary).get("ok", false)))
		# A54 唯一实例：select_boon 与本层 select 命中【同一】BoonDraftService，
		# 第二次 select 被幂等拒绝（duplicate/exclusive）→ 以 has_selection() 判定
		# 「抉择已注入 Rank-2 下游消费方」，不依赖第二次 select 的 ok，语义不变。
		var r2_sel: bool = false
		if _r34_wave.has_method("get_boon_service"):
			var r2boon: Object = _r34_wave.call("get_boon_service") as Object
			if r2boon != null and is_instance_valid(r2boon) and r2boon.has_method("has_selection"):
				r2_sel = bool(r2boon.call("has_selection"))
		forwarded = fr_ok or r2_sel
	_r34_boon_forward_ok = forwarded
	var payload: Dictionary = {}
	if _boon_draft_service != null and is_instance_valid(_boon_draft_service) \
			and _boon_draft_service.has_method("apply"):
		var av: Variant = _boon_draft_service.call("apply")
		if typeof(av) == TYPE_DICTIONARY:
			payload = av as Dictionary
	_r34_last_boon_apply = payload.duplicate()
	if not bool(payload.get("ok", false)):
		return
	var effect_key: String = String(payload.get("effect_key", ""))
	var effect_value: float = float(payload.get("effect_value", 0.0))
	var cost_key: String = String(payload.get("cost_key", ""))
	var cost_value: float = float(payload.get("cost_value", 0.0))
	_r34_pending_wave_modifier = {
		"effect_key": effect_key, "effect_value": effect_value,
		"cost_key": cost_key, "cost_value": cost_value,
		"choice_id": choice_id, "index": index,
		"paired": bool(payload.get("paired", false)),
	}
	boon_draft_applied.emit(index, choice_id, effect_key, effect_value, cost_key, cost_value)
	print("[R34][HUD] d 链：抉择 apply() 结算生效 paired=%s effect=%s(%.2f) cost=%s(%.2f) | 已注入 Rank-2 下游消费方=%s → 下一波清波由 wave_trial_director.apply()/settle() 消费" % [
			str(payload.get("paired", false)), effect_key, effect_value, cost_key, cost_value,
			str(_r34_boon_forward_ok)])


# ---- f) 生产 HUD 常驻可见层（hud.gd 自建，不再由 presentation.gd 动态构造）----

func _r34_find_mount_root() -> Node:
	var p: Node = get_parent()
	while p != null:
		if p is SubViewportContainer:
			return p.get_parent()
		p = p.get_parent()
	return null


func _r34_make_label(n: String) -> Label:
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


## 建常驻可见层并挂到 SubViewport 外的 Courtyard（与 R29/R30/R31 同口径，不受 stretch_shrink 影响）。
## 独立 hud.tscn --script 实例无 SubViewportContainer 父链 → 判空降级、不建节点（保护既有断言）。
func _r34_build_visible() -> void:
	if _r34_prod_layer != null and is_instance_valid(_r34_prod_layer):
		return
	var mount: Node = _r34_find_mount_root()
	if mount == null:
		# R34C：独立 hud.tscn --script 实例无 SubViewportContainer / Courtyard 外部挂载点
		#   → 降级挂到 HUD 自身（CanvasLayer 子节点），生产可见层真实节点仍建立并按锚点
		#   定位，供运行时断言读真实 rect；实机有 mount 时挂载路径逐字不变。
		mount = self
	var layer: CanvasLayer = mount.get_node_or_null(NodePath(R34_LAYER_NAME)) as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = R34_LAYER_NAME
		layer.layer = R34_LAYER_INDEX
		mount.add_child(layer)
	_r34_prod_layer = layer
	var bar: ProgressBar = layer.get_node_or_null(NodePath("ProdPoiseBar")) as ProgressBar
	if bar == null:
		bar = ProgressBar.new()
		bar.name = "ProdPoiseBar"
		bar.min_value = 0.0
		bar.max_value = 100.0
		bar.value = 100.0
		bar.show_percentage = false
		bar.offset_left = R34_RECT_LEFT + 12.0
		bar.offset_top = R34_RECT_TOP + 12.0
		bar.offset_right = R34_RECT_RIGHT - 12.0
		bar.offset_bottom = R34_RECT_TOP + 34.0
		layer.add_child(bar)
	_r34_poise_bar = bar
	var sl: Label = layer.get_node_or_null(NodePath("ProdStaggerLabel")) as Label
	if sl == null:
		sl = _r34_make_label("ProdStaggerLabel")
		sl.offset_left = R34_RECT_LEFT + 12.0
		sl.offset_top = R34_RECT_TOP + 40.0
		sl.offset_right = R34_RECT_RIGHT - 12.0
		sl.offset_bottom = R34_RECT_BOTTOM - 12.0
		layer.add_child(sl)
	_r34_stagger_label = sl
	var dl: Label = layer.get_node_or_null(NodePath("ProdDraftLabel")) as Label
	if dl == null:
		dl = _r34_make_label("ProdDraftLabel")
		dl.offset_left = R34_RECT_LEFT + 12.0
		dl.offset_top = R34_RECT_TOP + 12.0
		dl.offset_right = R34_RECT_RIGHT - 12.0
		dl.offset_bottom = R34_RECT_BOTTOM - 12.0
		layer.add_child(dl)
	_r34_draft_label = dl
	var cl: Label = layer.get_node_or_null(NodePath("ProdComboLabel")) as Label
	if cl == null:
		cl = _r34_make_label("ProdComboLabel")
		layer.add_child(cl)
	_r34_combo_label = cl
	# R35：精准弹反「金色预兆 + 读秒」真实 Label（生产常驻可见层，非 presentation.gd 构造）。
	#   独立分区锚点定位，字体染色为金色，不与其它任一文字包围盒相交（J 组真跑断言）。
	var pl: Label = layer.get_node_or_null(NodePath("ProdParryLabel")) as Label
	if pl == null:
		pl = _r34_make_label("ProdParryLabel")
		pl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.30, 1.0))
		layer.add_child(pl)
	_r35_parry_label = pl
	# R36：专注值 FP 条真实节点（生产常驻可见层，独立分区锚点，不与其它文字相交）。
	var fl: Label = layer.get_node_or_null(NodePath("ProdFocusLabel")) as Label
	if fl == null:
		fl = _r34_make_label("ProdFocusLabel")
		fl.add_theme_color_override("font_color", Color(0.55, 0.80, 1.0, 1.0))
		layer.add_child(fl)
	_r36_focus_label = fl
	# R36B：「当前战技：XXX」真实节点（生产常驻可见层，独立分区锚点，不与任一文字相交）。
	var al: Label = layer.get_node_or_null(NodePath(R36B_ART_LABEL_NAME)) as Label
	if al == null:
		al = _r34_make_label(R36B_ART_LABEL_NAME)
		al.add_theme_color_override("font_color", Color(1.0, 0.84, 0.30, 1.0))
		layer.add_child(al)
	_r36b_art_label = al
	# R37：「元素瓶 N/M」真实节点（生产常驻可见层，独立分区锚点，不与任一文字相交）。
	var kl: Label = layer.get_node_or_null(NodePath(R37_FLASK_LABEL_NAME)) as Label
	if kl == null:
		kl = _r34_make_label(R37_FLASK_LABEL_NAME)
		kl.add_theme_color_override("font_color", Color(0.55, 0.92, 0.72, 1.0))
		layer.add_child(kl)
	_r37_flask_label = kl
	# R37：「你死了 · 掉落赐福点数 N」真实节点（仅死亡态可见，独立分区锚点）。
	var xl: Label = layer.get_node_or_null(NodePath(R37_DEATH_LABEL_NAME)) as Label
	if xl == null:
		xl = _r34_make_label(R37_DEATH_LABEL_NAME)
		xl.add_theme_color_override("font_color", Color(1.0, 0.36, 0.32, 1.0))
		xl.visible = false
		layer.add_child(xl)
	_r37_death_label = xl
	# R34C：连击评级 / 倍率 / 命中数文本按【独立分区锚点】定位，不再用
	#   R34_RECT_BOTTOM+8/+36 硬编码像素堆叠压在赐福成长标题行上。
	_r34_apply_combo_rect()
	_r35_apply_parry_rect()
	_r36_apply_focus_rect()
	_r36b_apply_art_rect()
	_r37_apply_flask_rect()
	_r37_apply_death_rect()
	_r34_hide_all()
	print("[R34][HUD] f 链：生产常驻可见层 %s 入树 is_inside_tree=%s（按状态显示，非 presentation.gd 构造）" % [
			R34_LAYER_NAME, str(layer.is_inside_tree())])


## R34C：连击评级文本【真实节点】按独立分区锚点定位（不硬编码像素堆叠）。
##   视口变化由 set_layout_viewport() 联动重算；锚点归一化 → 1280x720 与降级档
##   都不出界 / 不遮中央角色 / 不与赐福成长标题行等任一包围盒相交。
func _r34_apply_combo_rect() -> void:
	if _r34_combo_label == null or not is_instance_valid(_r34_combo_label):
		return
	var r: Rect2 = get_production_mechanism_rect()
	_r34_combo_label.offset_left = r.position.x
	_r34_combo_label.offset_top = r.position.y
	_r34_combo_label.offset_right = r.end.x
	_r34_combo_label.offset_bottom = r.end.y


## R34C：幂等确保生产可见层真实节点已建立（供 --script / 集成显式调用；实机由
##   _r34_bootstrap() 经 call_deferred 走 _r34_build_visible() 同一入口，A48 口径不变）。
func ensure_production_visible_layer() -> void:
	_r34_build_visible()


func _r34_hide_all() -> void:
	for n: Node in [_r34_poise_bar, _r34_stagger_label, _r34_draft_label, _r34_combo_label, _r35_parry_label]:
		if n != null and is_instance_valid(n):
			n.visible = false


## 按状态显示常驻可见层：文本全部读 HUD 公开快照（get_*_view），不写既有 HUD 的 Label.text。
func _r34_refresh_visible() -> void:
	if _r34_prod_layer == null or not is_instance_valid(_r34_prod_layer):
		return
	var bv: Dictionary = get_boon_draft_view()
	var sv: Dictionary = get_stagger_hud_view()
	_r34_hide_all()
	if bool(bv.get("open", false)):
		var lines: Array[String] = ["赐福抉择 · 三选一（数字键 1 / 2 / 3 选择）"]
		var choices: Array = bv.get("choices", []) as Array
		for i: int in range(choices.size()):
			var c: Variant = choices[i]
			var title: String = ""
			if typeof(c) == TYPE_DICTIONARY:
				title = String((c as Dictionary).get("title", (c as Dictionary).get("id", "")))
			lines.append("  %d. %s" % [i + 1, title])
		if _r34_draft_label != null:
			_r34_draft_label.text = "\n".join(PackedStringArray(lines))
			_r34_draft_label.visible = true
	elif bool(sv.get("window_open", false)) or float(sv.get("poise_ratio", 1.0)) < 0.999:
		if _r34_poise_bar != null:
			_r34_poise_bar.value = clampf(float(sv.get("poise_ratio", 1.0)) * 100.0, 0.0, 100.0)
			_r34_poise_bar.visible = true
		if _r34_stagger_label != null:
			var slines: Array[String] = [String(sv.get("poise_text", ""))]
			var wt: String = String(sv.get("window_text", ""))
			if not wt.is_empty():
				slines.append(wt)
			_r34_stagger_label.text = "\n".join(PackedStringArray(slines))
			_r34_stagger_label.visible = true
	# R35：精准弹反金色预兆 / 读秒 / 结果文本按状态显示（独立分区 ProdParryLabel）。
	#   文本全部读 get_parry_hud_view() 公开快照；窗口外 / 失败超时 → 空文本隐藏，
	#   失败或超时按既有受击结算（本层不改伤害判定），不伪造窗口。
	if _r35_parry_label != null and is_instance_valid(_r35_parry_label):
		var pv: Dictionary = get_parry_hud_view()
		var ptext: String = String(pv.get("telegraph_text", ""))
		if not ptext.is_empty():
			_r35_parry_label.text = ptext
			_r35_parry_label.visible = true
	var combo_text: String = _r34_combo_text()
	if not combo_text.is_empty() and _r34_combo_label != null:
		_r34_combo_label.text = combo_text
		_r34_combo_label.visible = true
	# R36：专注值 FP 条常驻可见 + A65「弹反·免伤」/ 战技失败提示文本（按本地状态镜像刷新，
	#   不每帧读服务快照；FP 权威值由 request / bind / 赐福事件后显式 poll_focus_service 同步）。
	_r36_refresh_focus()
	# R37：元素瓶 N/M 常驻可见 + 死亡态「你死了 / 掉落赐福点数」按状态显示。
	_r37_refresh_flask()
	_r37_refresh_death()


func _r34_combo_text() -> String:
	# 4 信号事件驱动视图（A54 唯一实例，DONE-R34.md §3.1 签名）；count 取 combo 字段。
	var count: int = int(_r34_combo_view.get("count", 0))
	var rank: String = str(_r34_combo_view.get("rank", "D"))
	var mult: float = float(_r34_combo_view.get("multiplier", 1.0))
	if count <= 0 and _r34_combo != null and is_instance_valid(_r34_combo) \
			and _r34_combo.has_method("get_snapshot"):
		var cv: Variant = _r34_combo.call("get_snapshot")
		if typeof(cv) == TYPE_DICTIONARY:
			var d: Dictionary = cv as Dictionary
			# 真实 ComboService.get_snapshot() 用 "combo"；兼容替身 count/combo_count。
			count = int(d.get("combo", d.get("count", d.get("combo_count", 0))))
			rank = str(d.get("rank", d.get("rank_name", rank)))
			mult = float(d.get("multiplier", mult))
	if count <= 0:
		return ""
	return "连击评价 · %d 连击 ｜ 评级 %s ｜ 倍率 %.2f" % [count, rank, mult]


## 生产 HUD 渲染层每帧只做：递减本层显示读秒镜像（tick_stagger 既有）+ 按状态刷新常驻可见层。
## 不轮询 get_flag、不调用服务方法构造状态（StaggerService 的真实 tick 在导演层 b 链驱动）。
func _process(delta: float) -> void:
	if _stagger_window_open:
		tick_stagger(delta)
	# R35：可弹反窗口读秒镜像由生产帧驱动（ParryService 真实 tick 亦由导演层帧链转发）。
	if _r35_parry_window_open or _r35_parry_cooldown > 0.0:
		tick_parry(delta)
	tick_focus(delta)                     # R36：FP 冷却 / 提示显示镜像递减（生产帧驱动）
	tick_life(delta)                      # R37：元素瓶提示显示镜像递减（生产帧驱动）
	_r34_refresh_visible()


# ---- 生产链只读状态（验证脚本 / 运行日志读回，不含数值口径、不写盘）----

func get_production_status() -> Dictionary:
	return {
		"stagger_bound": _stagger_service != null and is_instance_valid(_stagger_service),
		"boon_bound": _boon_draft_service != null and is_instance_valid(_boon_draft_service),
		"combo_bound": _r34_combo != null and is_instance_valid(_r34_combo),
		"wave_cleared_connected": _r34_wave_cleared_connected,
		"wave_started_connected": _r34_wave_started_connected,
		"visible_layer_in_tree": _r34_prod_layer != null and is_instance_valid(_r34_prod_layer) \
				and _r34_prod_layer.is_inside_tree(),
		"points_awarded_count": _r34_points_count,
		"last_boon_apply": _r34_last_boon_apply.duplicate(),
		"boon_forward_ok": _r34_boon_forward_ok,
		"pending_wave_modifier": _r34_pending_wave_modifier.duplicate(),
		"active_wave_modifier": _r34_active_wave_modifier.duplicate(),
		"wave_modifier_broadcast_count": _r34_wave_modifier_broadcast_count,
		"boon_draft_open": is_boon_draft_open(),
		"stagger_hud": get_stagger_hud_view(),
		"combo_signals_connected": _r34_combo_signals_connected,
		"combo_hud": get_combo_hud_view(),
		# ---- R35 追加（既有键名与取值口径逐字不变）----
		"parry_bound": _r35_parry != null and is_instance_valid(_r35_parry),
		"parry_hud": get_parry_hud_view(),
		"parry_window_id": _r35_parry_window_id,
		"parry_success_count": _r35_parry_success_count,
		"parry_attempt_count": _r35_parry_attempt_count,
		"parry_signal_connected": _r35_parry_connected,
		# ---- R36 追加（既有键名与取值口径逐字不变）----
		"focus_bound": _r36_focus != null and is_instance_valid(_r36_focus),
		"focus_hud": get_focus_hud_view(),
		"focus_parry_negate_count": _r36_parry_negate_count,
	}


func get_last_boon_apply() -> Dictionary:
	return _r34_last_boon_apply.duplicate()


func get_active_wave_modifier() -> Dictionary:
	return _r34_active_wave_modifier.duplicate()


func _r34_release() -> void:
	_r36_release()                       # R36：ENC.parry_damage_negated 订阅的释放路径
	_r35_release()                       # R35：ParryService 信号 connect 的释放路径
	_r34_disconnect_combo_signals()      # R34B：4 个 combo 信号 connect 的释放路径
	if _r34_wave != null and is_instance_valid(_r34_wave):
		var cb1: Callable = Callable(self, "_r34_on_wave_cleared")
		if _r34_wave.has_signal("wave_cleared") and _r34_wave.is_connected("wave_cleared", cb1):
			_r34_wave.disconnect("wave_cleared", cb1)
		var cb2: Callable = Callable(self, "_r34_on_wave_started")
		if _r34_wave.has_signal("wave_started") and _r34_wave.is_connected("wave_started", cb2):
			_r34_wave.disconnect("wave_started", cb2)
	_r34_wave = null
	_r34_wave_cleared_connected = false
	_r34_wave_started_connected = false


# ==========================================================================
# 17) R35 [ROUND=R35] · v0.12.0 精准弹反（运行时侧，Rank-1 唯一写入方）
#   A48①：新信号 parry_performed 的生产运行时订阅者 = EncounterDirector
#          （_r35_bootstrap() 里 connect，成功时真实削韧 + 保护连击不断），
#          绝不只是验证脚本订阅。
#   A54：ParryService 唯一实例归属 wave_trial_director.gd；本层只经
#        wave.get_parry_service() 复用并 bind_parry_service()，绝不自建第二个。
#   A57：弹反赐福点数沿用「points_awarded.points = 最终结算值（含连击倍率）」口径，
#        取 A54 唯一 ComboService 的有效倍率；无有效倍率 → 回落基础值 + 告警。
#   A58：处决 / 弹反窗口统一生成非空且唯一 window_id（exe_<wave>_<seq> /
#        parry_<wave>_<seq>），随 execution_performed / parry_performed 带出。
#   不改既有伤害判定 / 帧数据 / 输出格式：失败或超时 → 既有受击链照常结算，
#   本层只附加「成功 → 削韧 / 点数 / 连击不断」与「金色预兆 + 读秒」显示。
#   鸭子类型 + 判空降级：Rank-2 接口未落盘 / 方法名差异均不产生 SCRIPT ERROR、不崩。
# ==========================================================================

# ---- Rank-2 契约候选（鸭子类型，不静态引用 ParryService class_name）----
const R35_PARRY_SIGNAL_OPEN: Array[String] = [
	"parry_window_opened", "window_opened", "parry_window_open"]
const R35_PARRY_SIGNAL_CLOSE: Array[String] = [
	"parry_window_closed", "window_closed", "parry_window_close"]
const R35_PARRY_METHOD_TRY: Array[String] = ["try_parry", "parry", "attempt_parry", "request_parry"]
const R35_PARRY_METHOD_TICK: Array[String] = ["tick", "advance", "step"]
const R35_PARRY_METHOD_SNAPSHOT: Array[String] = ["get_snapshot", "get_status", "get_view"]
const R35_KEY_OPEN: Array[String] = ["window_open", "parry_window_open", "open", "is_open"]
const R35_KEY_REMAINING: Array[String] = ["window_remaining", "remaining", "window_sec_remaining", "remaining_sec"]
const R35_KEY_COOLDOWN: Array[String] = ["cooldown_remaining", "cooldown", "cooldown_sec"]
const R35_KEY_WID: Array[String] = ["window_id", "parry_window_id"]
const R35_KEY_OK: Array[String] = ["ok", "success", "accepted", "parried"]
const R35_KEY_REASON: Array[String] = ["reason", "result"]
const R35_KEY_POINTS: Array[String] = ["points_bonus", "bonus_points", "points"]
const R35_KEY_POISE: Array[String] = ["poise_bonus", "bonus_poise", "poise"]
## [PLACEHOLDER] 可弹反窗口读秒降级初值（Rank-2 服务未提供 remaining 时）。
## rationale：给「金色预兆读秒」一个可见但短促的初值，真实时长以 parry_rules.tres
## 的 window_sec / 服务快照为准；调参唯一入口 = res://data/combat/parry_rules.tres（只改表不改代码）。
const R35_PARRY_WINDOW_FALLBACK_SEC: float = 0.8

var _r35_parry: Object = null                  # A54 唯一 ParryService（wave.get_parry_service() 复用）
var _r35_parry_connected: bool = false
var _r35_parry_window_open: bool = false       # 窗口状态镜像（服务为权威）
var _r35_parry_window_remaining: float = 0.0  # 读秒镜像
var _r35_parry_window_id: String = ""          # A58 唯一窗口 id
var _r35_parry_consumed: bool = false          # 同窗口重复按键幂等
var _r35_parry_cooldown: float = 0.0           # 冷却期拒绝
var _r35_parry_result_text: String = ""        # 成功 / 失败反馈文本
var _r35_parry_label: Label = null             # 金色预兆真实节点
var _r35_parry_success_count: int = 0
var _r35_parry_attempt_count: int = 0
var _r35_points_count: int = 0                 # 弹反 points_awarded 发出次数
var _r35_exe_seq: int = 0                      # A58 处决窗口序号
var _r35_parry_seq: int = 0                    # A58 弹反窗口序号
var _r35_parry_log: Array[Dictionary] = []     # 逐次尝试（供验证 / 运行日志只读回读）


## 供 Rank-4 / 验证取 A54 唯一实例（同一 ParryService，不经场景树）。
func get_parry_service() -> Object:
	return _r35_parry


## 多候选键读取：Rank-2 快照字段命名差异不改本层代码即可兼容。
func _r35_pick(d: Dictionary, keys: Array[String], default_value: Variant) -> Variant:
	for k: String in keys:
		if d.has(k):
			return d[k]
	return default_value


func _r35_last_snapshot() -> Dictionary:
	var svc: Object = _r35_parry
	if svc == null or not is_instance_valid(svc):
		return {}
	for m: String in R35_PARRY_METHOD_SNAPSHOT:
		if svc.has_method(m):
			var v: Variant = svc.call(m)
			if typeof(v) == TYPE_DICTIONARY:
				return v as Dictionary
	return {}


func _r35_dedup_connect(obj: Object, sig: String, method: String) -> void:
	if obj == null or not obj.has_signal(sig):
		return
	var cb: Callable = Callable(self, method)
	for conn in obj.get_signal_connection_list(sig):
		var c: Callable = conn.get("callable", Callable())
		if c.get_object() == self and String(c.get_method()) == method:
			return
	obj.connect(sig, cb)


## A54 唯一实例注入口（生产由 _r34_bootstrap 经 wave.get_parry_service() 复用）。
func bind_parry_service(svc: Object) -> void:
	_r35_release()
	_r35_parry = svc
	if svc == null or not is_instance_valid(svc):
		return
	for sig: String in R35_PARRY_SIGNAL_OPEN:
		if svc.has_signal(sig):
			_r35_dedup_connect(svc, sig, "_r35_on_parry_window_opened")
			break
	for sig2: String in R35_PARRY_SIGNAL_CLOSE:
		if svc.has_signal(sig2):
			_r35_dedup_connect(svc, sig2, "_r35_on_parry_window_closed")
			break
	_r35_parry_connected = true
	poll_parry_service()


## 从服务公开快照回读窗口态（事件驱动 + 显式推进调用，不每帧轮询服务）。
func poll_parry_service() -> void:
	var snap: Dictionary = _r35_last_snapshot()
	if snap.is_empty():
		return
	var wo: bool = bool(_r35_pick(snap, R35_KEY_OPEN, false))
	if wo:
		if not _r35_parry_window_open:
			_r35_open_parry_window(
					_r35_pick(snap, R35_KEY_REMAINING, R35_PARRY_WINDOW_FALLBACK_SEC),
					_r35_pick(snap, R35_KEY_WID, ""))
		else:
			_r35_parry_window_remaining = maxf(0.0,
					float(_r35_pick(snap, R35_KEY_REMAINING, _r35_parry_window_remaining)))
	elif _r35_parry_window_open:
		_r35_close_parry_window()
	var cd: float = float(_r35_pick(snap, R35_KEY_COOLDOWN, 0.0))
	if cd > _r35_parry_cooldown:
		_r35_parry_cooldown = cd


## 开窗信号回调：先按权威快照同步，签名差异 / 无快照时用实参兜底（不崩）。
func _r35_on_parry_window_opened(a: Variant = null, b: Variant = null, _c: Variant = null) -> void:
	poll_parry_service()
	if _r35_parry_window_open:
		return
	var sec: Variant = R35_PARRY_WINDOW_FALLBACK_SEC
	var wid: Variant = ""
	if a != null and (typeof(a) == TYPE_FLOAT or typeof(a) == TYPE_INT):
		sec = a
	elif a != null and typeof(a) == TYPE_STRING:
		wid = a
	if b != null and (typeof(b) == TYPE_FLOAT or typeof(b) == TYPE_INT):
		sec = b
	elif b != null and typeof(b) == TYPE_STRING:
		wid = b
	_r35_open_parry_window(sec, wid)


func _r35_on_parry_window_closed(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	poll_parry_service()
	if _r35_parry_window_open:
		_r35_close_parry_window()


func _r35_open_parry_window(remaining: Variant, wid: Variant) -> void:
	var sec: float = R35_PARRY_WINDOW_FALLBACK_SEC
	if remaining != null and (typeof(remaining) == TYPE_FLOAT or typeof(remaining) == TYPE_INT):
		sec = maxf(0.0, float(remaining))
	_r35_parry_window_open = true
	_r35_parry_window_remaining = sec
	_r35_parry_consumed = false
	_r35_parry_result_text = ""
	var s: String = str(wid) if wid != null else ""
	# A58：服务带 id 则采信，为空则本地生成非空唯一 id（失败降级，不静默留空）。
	_r35_parry_window_id = s if not s.is_empty() else _r35_make_window_id("parry")
	_r34_refresh_visible()
	print("[R35][HUD] 可弹反窗口开启 | wid=%s sec=%.2f（金色预兆 + 读秒，真实 K 输入待触发）" % [
			_r35_parry_window_id, sec])


func _r35_close_parry_window() -> void:
	_r35_parry_window_open = false
	_r35_parry_window_remaining = 0.0
	# 超时 / 窗口外：按既有正常受击结算（本层不改伤害判定），只清预兆显示。
	_r35_parry_result_text = ""
	_r34_refresh_visible()


## 读秒 / 冷却镜像（生产 _process 帧驱动；服务真实 tick 由导演层帧链转发）。
func tick_parry(delta: float) -> void:
	var dt: float = maxf(0.0, delta)
	if _r35_parry_window_open:
		_r35_parry_window_remaining = maxf(0.0, _r35_parry_window_remaining - dt)
		if _r35_parry_window_remaining <= 0.0:
			_r35_close_parry_window()
	if _r35_parry_cooldown > 0.0:
		_r35_parry_cooldown = maxf(0.0, _r35_parry_cooldown - dt)


func _r35_log(reason: String, ok: bool, wid: String, pts: int, poise: float) -> void:
	_r35_parry_log.append({"reason": reason, "ok": ok, "window_id": wid,
			"points": pts, "poise_bonus": poise})


func get_parry_attempt_log() -> Array[Dictionary]:
	return _r35_parry_log.duplicate(true)


## A58 window_id 生成规则：
##   · 格式 "<prefix>_<wave>_<seq>"（prefix = exe / parry）；
##   · wave 取 _r34_wave.get_snapshot().index（波次导演真实当前波）；
##   · seq 为前缀各自的单调递增计数，保证同进程内任意两个窗口 id 不相等；
##   · 失败降级：波次导演不可用 → wave 回落 0 + push_warning（不静默）；
##     seq 仍单调递增保证唯一；prefix 空 → "win"；生成结果恒为非空字符串。
func _r35_wave_index() -> int:
	if _r34_wave != null and is_instance_valid(_r34_wave) and _r34_wave.has_method("get_snapshot"):
		var s: Variant = _r34_wave.call("get_snapshot")
		if typeof(s) == TYPE_DICTIONARY:
			return int((s as Dictionary).get("index", 0))
	push_warning("[R35][HUD] A58 降级：波次导演不可用 → window_id 波次段回落 0（seq 单调递增仍保证唯一）")
	return 0


func _r35_make_window_id(prefix: String) -> String:
	var p: String = prefix if not prefix.is_empty() else "win"
	var wave: int = _r35_wave_index()
	if p == "exe":
		_r35_exe_seq += 1
		return "%s_%d_%d" % [p, wave, _r35_exe_seq]
	_r35_parry_seq += 1
	return "%s_%d_%d" % [p, wave, _r35_parry_seq]


## A57 倍率后值口径：弹反赐福点数 = 基础 points_bonus × 有效连击倍率（最终结算值）。
##   取源 = A54 唯一 ComboService 的有效结算倍率（get_last_settlement）或当前倍率；
##   无有效倍率 / 服务不可用 → 回落基础值 + push_warning（失败降级，不静默吞掉）。
##   调参唯一入口 = res://data/rpg/combo_rules.tres 的 multiplier（只改表不改代码）。
func _r35_final_points(base: int) -> int:
	if base <= 0:
		return base
	var combo: Object = get_combo_service()
	if combo == null or not is_instance_valid(combo):
		push_warning("[R35][HUD] A57 降级：ComboService 不可用 → 弹反赐福点数回落基础值 base=%d" % base)
		return base
	var mult: float = -1.0
	if combo.has_method("get_last_settlement"):
		var last: Dictionary = combo.call("get_last_settlement") as Dictionary
		if bool(last.get("ok", false)) and bool(last.get("settled", false)):
			mult = float(last.get("multiplier", 1.0))
	if mult <= 0.0 and combo.has_method("get_multiplier"):
		mult = float(combo.call("get_multiplier"))
	if mult <= 0.0 or is_nan(mult) or is_inf(mult):
		push_warning("[R35][HUD] A57 降级：未取到有效连击倍率 → 弹反赐福点数回落基础值 base=%d" % base)
		return base
	return int(roundf(float(base) * mult))


## 真实 K 输入落点：窗口内成功 / 窗口外拒绝 / 重复幂等 / 冷却拒绝。
## 权威判定交 A54 唯一 ParryService.try_parry()；HUD 只做门控 + 显示 + 发信号。
func request_parry() -> Dictionary:
	_r35_parry_attempt_count += 1
	if not _r35_parry_window_open:
		_r35_log("window_closed", false, _r35_parry_window_id, 0, 0.0)
		return {"ok": false, "reason": "window_closed", "window_id": _r35_parry_window_id}
	if _r35_parry_consumed:
		_r35_log("already_parried", false, _r35_parry_window_id, 0, 0.0)
		return {"ok": false, "reason": "already_parried", "window_id": _r35_parry_window_id}
	if _r35_parry_cooldown > 0.0:
		_r35_log("cooldown", false, _r35_parry_window_id, 0, 0.0)
		return {"ok": false, "reason": "cooldown", "window_id": _r35_parry_window_id}
	var result: Dictionary = {}
	var svc: Object = _r35_parry
	if svc != null and is_instance_valid(svc):
		for m: String in R35_PARRY_METHOD_TRY:
			if svc.has_method(m):
				var r: Variant = svc.call(m)
				if typeof(r) == TYPE_DICTIONARY:
					result = r as Dictionary
				elif typeof(r) == TYPE_BOOL:
					result = {"ok": bool(r)}
				break
	var ok: bool = bool(_r35_pick(result, R35_KEY_OK, false))
	if not ok:
		var reason: String = String(_r35_pick(result, R35_KEY_REASON, "parry_rejected"))
		# 失败 / 超时 → 既有正常受击结算（本层不改伤害判定 / 帧数据 / 输出格式）。
		_r35_log(reason, false, _r35_parry_window_id, 0, 0.0)
		return {"ok": false, "reason": reason, "window_id": _r35_parry_window_id}
	_r35_parry_consumed = true
	_r35_parry_success_count += 1
	var wid: String = _r35_parry_window_id
	if wid.is_empty():
		wid = _r35_make_window_id("parry")   # A58 失败降级：服务未带 id → 本地生成非空唯一 id
	var snap: Dictionary = _r35_last_snapshot()
	var pts: int = int(_r35_pick(result, R35_KEY_POINTS, _r35_pick(snap, R35_KEY_POINTS, 0)))
	var poise: float = float(_r35_pick(result, R35_KEY_POISE, _r35_pick(snap, R35_KEY_POISE, 0.0)))
	var final_pts: int = _r35_final_points(pts)
	# A48①：生产订阅者（EncounterDirector）收此信号 → 真实削韧 + 连击不断。
	parry_performed.emit(wid, final_pts, poise)
	# A55 / A57：赐福点数只发信号（Rank-1 不写盘），携带倍率后最终值。
	points_awarded.emit("parry", final_pts, "parry_service.try_parry")
	_r35_points_count += 1
	_r35_parry_result_text = "弹反成功！ +削韧 / +赐福点数 / 连击不断"
	_r35_log("ok", true, wid, final_pts, poise)
	# 同窗口保留至 tick 超时 / 服务 closed 信号；_r35_parry_consumed 阻止重复结算
	# （窗口内重复按 K → already_parried，重复按键幂等）。
	_r34_refresh_visible()
	print("[R35][HUD] 弹反成功 | wid=%s base=%d final=%d poise_bonus=%.1f → parry_performed + points_awarded 已发（A57 倍率后值）" % [
			wid, pts, final_pts, poise])
	return {"ok": true, "reason": "ok", "window_id": wid,
			"bonus_points": final_pts, "poise_bonus": poise}


func _try_parry_input() -> void:
	request_parry()


## 精准弹反 HUD 视图（金色预兆 / 读秒 / 唯一窗口 id / 独立分区 rect）。
func get_parry_hud_view() -> Dictionary:
	var text: String = ""
	if not _r35_parry_result_text.is_empty():
		text = _r35_parry_result_text
	elif _r35_parry_window_open:
		text = "精准弹反窗口 %.1fs · 按 K" % _r35_parry_window_remaining
	return {
		"window_open": _r35_parry_window_open,
		"remaining_sec": _r35_parry_window_remaining,
		"window_id": _r35_parry_window_id,
		"cooldown_sec": _r35_parry_cooldown,
		"consumed": _r35_parry_consumed,
		"success_count": _r35_parry_success_count,
		"attempt_count": _r35_parry_attempt_count,
		"service_available": _r35_parry != null and is_instance_valid(_r35_parry),
		"telegraph_text": text,
		"rect": get_parry_telegraph_rect(),
		"points_awarded_count": _r35_points_count,
	}


## 金色预兆真实节点按独立分区锚点定位（视口变化由 set_layout_viewport 联动重算）。
func _r35_apply_parry_rect() -> void:
	if _r35_parry_label == null or not is_instance_valid(_r35_parry_label):
		return
	var r: Rect2 = get_parry_telegraph_rect()
	_r35_parry_label.offset_left = r.position.x
	_r35_parry_label.offset_top = r.position.y
	_r35_parry_label.offset_right = r.end.x
	_r35_parry_label.offset_bottom = r.end.y


## 信号 connect 的释放路径（_exit_tree → _r34_release → 本函数）。
func _r35_release() -> void:
	var svc: Object = _r35_parry
	if svc != null and is_instance_valid(svc):
		var all_sigs: Array = R35_PARRY_SIGNAL_OPEN + R35_PARRY_SIGNAL_CLOSE
		for sig: String in all_sigs:
			if not svc.has_signal(sig):
				continue
			var cb_open: Callable = Callable(self, "_r35_on_parry_window_opened")
			if svc.is_connected(sig, cb_open):
				svc.disconnect(sig, cb_open)
			var cb_close: Callable = Callable(self, "_r35_on_parry_window_closed")
			if svc.is_connected(sig, cb_close):
				svc.disconnect(sig, cb_close)
	_r35_parry_connected = false


# ==========================================================================
# 18) R36 [ROUND=R36] · v0.13.0 专注值 FP / 战技 Q（运行时侧，Rank-1 唯一写入方）
#   A48①：HUD 新信号 focus_skill_performed / focus_skill_rejected 的【生产运行时订阅者】
#          = EncounterDirector（_r36_bootstrap connect，真实削韧 / 伤害）；ENC 新信号
#          parry_damage_negated（A65）的生产订阅者 = 本 HUD（显示「弹反·免伤」）。
#          绝不只是验证脚本订阅。
#   A54：focus_service 唯一实例从 wave_trial_director.get_focus_service() 复用，绝不自建
#        第二个实例；Rank-2 本轮并发新增件尚未落盘时判空降级、不崩、不产生 SCRIPT ERROR、
#        如实登记「真实判定逻辑待 Rank-2 落盘联调」（同 R35 FakeParry 先例）。
#   A57：战技伤害携带【倍率后最终值】（基础伤害 × 唯一 ComboService 有效倍率），
#        ENC 生产订阅者原样采信、不二次结算；无有效倍率回落基础值。
#   A46：Q 与 F / Tab / K 同走 HUD._unhandled_input → _process_r32_keys 单一仲裁者路径，
#        不回退到多监听者吞键；ENC 同接 Q 转发本权威入口，event 实例幂等去重。
#   不改既有普通攻击判定 / 帧数据 / 输出格式：Q 为新增输入分支，战技效果走生产订阅链，
#     HUD 既有文本 / 四套 HUD / 6 分区布局逐字不动；FP 条用独立归一化锚点 ANCHOR_FOCUS，
#     不与任何既有文字包围盒相交（不并入 get_layout_rects() 的 6 分区，保护 A1 断言）。
# ==========================================================================

# ---- Rank-2 focus_service 鸭子类型契约（不静态引用 class_name，命名差异不崩）----
#   R36 真实接口（Rank-2 focus_service.gd）：spend_fp(art_id) 判定 / get_snapshot() 快照 /
#   on_grace_rest() 回满 / tick(delta) 冷却；成功返回键 damage / poise_damage /
#   fp_cost / fp_remaining / art_id / cooldown_remaining。下列候选同时兼容契约替身。
const R36_FOCUS_METHOD_SPEND: String = "spend_fp"       # 真实服务主入口（需 art_id 实参）
const R36_FOCUS_METHOD_ART_IDS: Array[String] = ["get_art_ids"]  # 取默认战技 id
const R36_FOCUS_METHOD_TRY: Array[String] = [
	"try_focus_skill", "cast_skill", "try_skill", "consume_focus", "spend_focus"]
const R36_FOCUS_METHOD_SNAPSHOT: Array[String] = [
	"get_snapshot", "get_status", "get_focus_view", "get_view"]
const R36_FOCUS_METHOD_REST: Array[String] = [
	"on_grace_rest", "rest_at_grace", "rest", "refill", "reset"]
const R36_FOCUS_METHOD_TICK: Array[String] = ["tick", "advance", "step"]
const R36_KEY_OK: Array[String] = ["ok", "success", "accepted", "cast"]
const R36_KEY_REASON: Array[String] = ["reason", "result", "reject_reason"]
const R36_KEY_FP: Array[String] = ["fp", "fp_after", "fp_remaining", "current_fp", "focus"]
const R36_KEY_FP_BEFORE: Array[String] = ["fp_before", "fp_prev"]
const R36_KEY_FP_MAX: Array[String] = ["fp_max", "max_fp", "focus_max"]
const R36_KEY_FP_COST: Array[String] = ["fp_cost", "cost", "fp_spent"]
const R36_KEY_DAMAGE: Array[String] = ["damage", "skill_damage", "base_damage"]
const R36_KEY_POISE: Array[String] = ["poise_damage", "poise", "skill_poise"]
const R36_KEY_COOLDOWN: Array[String] = ["cooldown_remaining", "cooldown", "cooldown_sec"]
const R36_KEY_WID: Array[String] = ["art_id", "window_id", "skill_id", "wid"]
# [PLACEHOLDER] 服务未落盘时的显示降级初值（非玩法数值）：仅用于 FP 条文本占位，
#   rationale：Rank-2 focus_service 未装配时 HUD 仍可显示一个稳定的「当前/上限」条，
#   权威值恒以服务 get_snapshot() 为准；调参唯一入口 = 本常量表（只改表不改算法）。
const R36_FP_FALLBACK: int = 60
const R36_FP_MAX_FALLBACK: int = 60
# [PLACEHOLDER] 战技提示 / A65「弹反·免伤」反馈显示时长（秒），待试玩校准；
#   rationale：给短暂的可见反馈窗口，不常驻遮挡；调参唯一入口 = 本常量表。
const R36_HINT_SHOW_SEC: float = 1.2
const R36_NEGATE_SHOW_SEC: float = 1.5

const R36_FOCUS_LABEL_NAME: String = "ProdFocusLabel"
const R36_ENC_REL_PATH: String = "EncounterRoot"
const R36_WAVE_REL_PATH: String = "WaveTrialDirector"
# R36B [ROUND=R36B] · 「当前战技：XXX」真实节点名（A69 裁决 R 切换，独立分区锚点）。
const R36B_ART_LABEL_NAME: String = "ProdArtLabel"

var _r36_focus: Object = null               # A54 唯一 focus_service（wave 复用，不自建）
var _r36_focus_label: Label = null          # 「专注值 FP」条真实节点
var _r36_fp: int = R36_FP_FALLBACK          # 当前 FP 镜像（权威来自服务快照）
var _r36_fp_max: int = R36_FP_MAX_FALLBACK  # FP 上限镜像
var _r36_cooldown: float = 0.0             # 冷却镜像（服务为权威，本地仅显示递减）
var _r36_last_q_event_id: int = 0          # 同一 InputEvent 实例幂等去重（ENC+HUD 双接 Q 不重复结算）
var _r36_last_q_result: Dictionary = {}
var _r36_attempt_count: int = 0
var _r36_success_count: int = 0
var _r36_reject_count: int = 0
var _r36_skill_seq: int = 0                # 非空唯一 skill window id 序号
var _r36_attempt_log: Array[Dictionary] = []
var _r36_hint_text: String = ""            # 「专注不足 / 冷却中 / 战技命中」提示
var _r36_hint_remaining: float = 0.0
var _r36_parry_negate_text: String = ""    # A65「弹反·免伤」反馈
var _r36_parry_negate_remaining: float = 0.0
var _r36_parry_negate_count: int = 0
var _r36_focus_signal_connected: bool = false
var _r36_bootstrapped: bool = false

# ---- R36B [ROUND=R36B] · 战技切换（A69 裁决：R 键在 focus_rules.tres 的 arts 间循环）----
var _r36b_art_index: int = 0                # 当前战技索引（默认 0 = arts[0]，既有 Q 行为不回退）
var _r36b_art_ids: PackedStringArray = []   # 从 A54 唯一实例 get_art_ids() 只读同步，不自建服务
var _r36b_art_label: Label = null           # 「当前战技：XXX」真实节点 ProdArtLabel
var _r36b_last_r_event_id: int = 0          # 同一 event 实例幂等去重（ENC+HUD 双接 R 不重复切换）
var _r36b_last_r_result: Dictionary = {}
var _r36b_switch_count: int = 0             # 切换次数（只读快照 / 运行日志用）


## 多候选键读取（Rank-2 快照字段命名差异不改本层代码即可兼容，同 R35 _r35_pick）。
func _r36_pick(d: Dictionary, keys: Array[String], default_value: Variant) -> Variant:
	for k: String in keys:
		if d.has(k):
			return d[k]
	return default_value


## 默认战技 id：优先真实 FocusService.get_art_ids() 首个 id（数值来自 focus_rules.tres，
## 本层不硬编码具体战技）；契约替身 / 无该方法时回落空串由服务按自身契约判定（不崩）。
func _r36_default_art_id(svc: Object) -> String:
	for m: String in R36_FOCUS_METHOD_ART_IDS:
		if svc.has_method(m):
			var ids: Variant = svc.call(m)
			if ids is PackedStringArray and not (ids as PackedStringArray).is_empty():
				return String((ids as PackedStringArray)[0])
			if ids is Array and not (ids as Array).is_empty():
				return str((ids as Array)[0])
	return ""


## A54 唯一实例注入口（生产由 _r36_bootstrap 经 wave.get_focus_service() 复用；
## 验证进程注入契约替身）。绝不 new 第二个生产实例。
func bind_focus_service(svc: Object) -> void:
	_r36_focus = svc
	_r36_last_q_event_id = 0
	_r36_last_q_result = {}
	_r36b_last_r_event_id = 0
	_r36b_last_r_result = {}
	poll_focus_service()
	_r36_refresh_focus()                  # 内部同步 R36B「当前战技」真实节点文本


func get_focus_service() -> Object:
	return _r36_focus


## 从权威服务快照同步 FP 当前 / 上限 / 冷却（事件后显式调用，不每帧轮询）。
func poll_focus_service() -> void:
	var svc: Object = _r36_focus
	if svc == null or not is_instance_valid(svc):
		return
	var snap: Dictionary = {}
	for m: String in R36_FOCUS_METHOD_SNAPSHOT:
		if svc.has_method(m):
			var v: Variant = svc.call(m)
			if typeof(v) == TYPE_DICTIONARY:
				snap = v as Dictionary
				break
	if snap.is_empty():
		return
	_r36_fp = int(_r36_pick(snap, R36_KEY_FP, _r36_fp))
	_r36_fp_max = int(_r36_pick(snap, R36_KEY_FP_MAX, _r36_fp_max))
	_r36_cooldown = maxf(0.0, float(_r36_pick(snap, R36_KEY_COOLDOWN, _r36_cooldown)))


## A57 倍率后值口径：取 A54 唯一 ComboService 的有效结算倍率；无有效倍率回落 1.0。
## 调参唯一入口 = res://data/rpg/combo_rules.tres 的 multiplier（只改表不改代码）。
func _r36_effective_multiplier() -> float:
	var combo: Object = get_combo_service()
	if combo == null or not is_instance_valid(combo):
		return 1.0
	var mult: float = -1.0
	if combo.has_method("get_last_settlement"):
		var last: Dictionary = combo.call("get_last_settlement") as Dictionary
		if bool(last.get("ok", false)) and bool(last.get("settled", false)):
			mult = float(last.get("multiplier", 1.0))
	if mult <= 0.0 and combo.has_method("get_multiplier"):
		mult = float(combo.call("get_multiplier"))
	if mult <= 0.0 or is_nan(mult) or is_inf(mult):
		return 1.0
	return mult


func _r36_make_skill_id() -> String:
	_r36_skill_seq += 1
	return "skill_%d" % _r36_skill_seq


## 失败原因归一为 HUD 中文提示「专注不足 / 冷却中」（不改服务 reason 原值，随信号带出）。
func _r36_reason_hint(reason: String) -> String:
	var r: String = reason.to_lower()
	if r.contains("cooldown") or r.contains("cool") or r.contains("冷却") or r == "cd":
		return "冷却中"
	if r.contains("fp") or r.contains("focus") or r.contains("insufficient") \
			or r.contains("not_enough") or r.contains("不足"):
		return "专注不足"
	if r.contains("unavailable") or r.contains("no_service"):
		return "战技服务未就绪"
	return "战技未释放"


## 真实 Q 输入唯一权威判定（HUD._process_r32_keys / ENC._r36_request_focus_skill 同调本入口）。
## 成功 → 扣 FP（服务权威）+ 发 focus_skill_performed（A57 倍率后值）；失败 → 不扣 FP +
## 发 focus_skill_rejected + HUD「专注不足 / 冷却中」提示。同一 event 实例幂等去重。
func request_focus_skill(event: InputEvent = null) -> Dictionary:
	if event != null:
		var eid: int = event.get_instance_id()
		if eid == _r36_last_q_event_id and not _r36_last_q_result.is_empty():
			return _r36_last_q_result.duplicate()
		_r36_last_q_event_id = eid
	_r36_attempt_count += 1
	var svc: Object = _r36_focus
	if svc == null or not is_instance_valid(svc):
		var r_unavail: Dictionary = {"ok": false, "reason": "focus_service_unavailable",
				"fp": _r36_fp, "fp_max": _r36_fp_max}
		_r36_reject_count += 1
		_r36_hint_text = "战技服务未就绪"
		_r36_hint_remaining = R36_HINT_SHOW_SEC
		focus_skill_rejected.emit("focus_service_unavailable", _r36_fp, _r36_fp_max)
		_r36_log("focus_service_unavailable", false, "", 0, _r36_fp, _r36_fp_max)
		_r36_refresh_focus()
		_r36_last_q_result = r_unavail
		return r_unavail.duplicate()
	var result: Dictionary = {}
	var art_id: String = ""              # R36B：本次 Q 释放的【当前选中】战技 id
	# 真实 Rank-2 FocusService 主入口 spend_fp(art_id)：R36B 起取【当前选中】战技 id
	# （默认 arts[0]，与既有行为逐字等价；arts 列表 / title 全来自 focus_rules.tres，
	#  HUD 不硬编码具体 id / 数值，只读 A54 唯一实例）。
	if svc.has_method(R36_FOCUS_METHOD_SPEND):
		art_id = get_current_art_id()
		if art_id.is_empty():
			art_id = _r36_default_art_id(svc)   # 空列表 / 服务降级时回落既有默认，不回退
		var vs: Variant = svc.call(R36_FOCUS_METHOD_SPEND, art_id)
		if typeof(vs) == TYPE_DICTIONARY:
			result = vs as Dictionary
		elif typeof(vs) == TYPE_BOOL:
			result = {"ok": bool(vs)}
	else:
		# 契约替身 / 其它命名（无参入口，判空降级不崩）。
		for m: String in R36_FOCUS_METHOD_TRY:
			if svc.has_method(m):
				var v: Variant = svc.call(m)
				if typeof(v) == TYPE_DICTIONARY:
					result = v as Dictionary
				elif typeof(v) == TYPE_BOOL:
					result = {"ok": bool(v)}
				break
	var ok: bool = bool(_r36_pick(result, R36_KEY_OK, false))
	var reason: String = String(_r36_pick(result, R36_KEY_REASON, ""))
	poll_focus_service()
	if not ok:
		_r36_reject_count += 1
		_r36_hint_text = _r36_reason_hint(reason)
		_r36_hint_remaining = R36_HINT_SHOW_SEC
		focus_skill_rejected.emit(reason, _r36_fp, _r36_fp_max)
		_r36_log(reason, false, "", 0, _r36_fp, _r36_fp_max)
		_r36_refresh_focus()
		_r36_last_q_result = result
		return result.duplicate()
	# 成功：A57 倍率后值（基础伤害 × 有效连击倍率，ENC 原样采信不二次结算）。
	var fp_before: int = int(_r36_pick(result, R36_KEY_FP_BEFORE, _r36_fp))
	var fp_after: int = int(_r36_pick(result, R36_KEY_FP, _r36_fp))
	var fp_cost: int = int(_r36_pick(result, R36_KEY_FP_COST, 0))
	var base_damage: int = int(_r36_pick(result, R36_KEY_DAMAGE, 0))
	var poise: float = float(_r36_pick(result, R36_KEY_POISE, 0.0))
	var wid: String = String(_r36_pick(result, R36_KEY_WID, ""))
	if wid.is_empty():
		wid = _r36_make_skill_id()
	var mult: float = _r36_effective_multiplier()
	var final_damage: int = int(roundf(float(base_damage) * mult))
	_r36_success_count += 1
	_r36_hint_text = "战技命中 · -%d FP" % fp_cost
	_r36_hint_remaining = R36_HINT_SHOW_SEC
	# A48①：生产运行时订阅者（EncounterDirector）收此信号 → 真实削韧 + 真实伤害。
	focus_skill_performed.emit(wid, fp_before, fp_after, fp_cost, final_damage, poise, mult)
	_r36_log("ok", true, wid, final_damage, fp_after, _r36_fp_max)
	_r36_refresh_focus()
	_r36_last_q_result = result
	print("[R36][HUD] 真实 Q → 战技命中 | art=%s wid=%s fp %d->%d cost=%d base=%d final=%d(×%.2f) poise=%.1f → focus_skill_performed 已发（A57 倍率后值）" % [
			art_id, wid, fp_before, fp_after, fp_cost, base_damage, final_damage, mult, poise])
	return result.duplicate()


func _r36_log(reason: String, ok: bool, wid: String, damage: int, fp: int, fp_max: int) -> void:
	_r36_attempt_log.append({"reason": reason, "ok": ok, "window_id": wid,
			"damage": damage, "fp": fp, "fp_max": fp_max})


func get_focus_attempt_log() -> Array[Dictionary]:
	return _r36_attempt_log.duplicate(true)


## 战技 HUD 视图（FP 当前 / 上限 / 提示 / 独立分区 rect / 计数，供可见层与验证读取）。
func get_focus_hud_view() -> Dictionary:
	var av: Dictionary = get_current_art_view()   # R36B 只读追加（既有 key 逐字不动）
	return {
		"fp": _r36_fp,
		"fp_max": _r36_fp_max,
		"fp_text": "专注值 FP %d/%d" % [_r36_fp, _r36_fp_max],
		"cooldown_sec": _r36_cooldown,
		"hint_text": _r36_hint_text,
		"parry_negate_text": _r36_parry_negate_text,
		"parry_negate_count": _r36_parry_negate_count,
		"service_available": _r36_focus != null and is_instance_valid(_r36_focus),
		"attempt_count": _r36_attempt_count,
		"success_count": _r36_success_count,
		"reject_count": _r36_reject_count,
		"rect": get_focus_rect(),
		"focus_signal_connected": _r36_focus_signal_connected,
		# ---- R36B 追加只读 key（既有 14 个 key 逐字不动）----
		"current_art_id": String(av.get("art_id", "")),
		"current_art_title": String(av.get("title", "")),
		"current_art_index": int(av.get("art_index", 0)),
		"current_art_count": int(av.get("art_count", 0)),
		"current_art_rect": get_current_art_rect(),
	}


## 「专注值 FP」条真实节点按独立分区锚点定位（视口变化由 set_layout_viewport 联动重算）。
func _r36_apply_focus_rect() -> void:
	if _r36_focus_label == null or not is_instance_valid(_r36_focus_label):
		return
	var r: Rect2 = get_focus_rect()
	_r36_focus_label.offset_left = r.position.x
	_r36_focus_label.offset_top = r.position.y
	_r36_focus_label.offset_right = r.end.x
	_r36_focus_label.offset_bottom = r.end.y


## FP 条常驻可见刷新（本地镜像 + 提示 / A65 免伤反馈，不读服务快照、不写既有 Label.text）。
func _r36_refresh_focus() -> void:
	if _r36_focus_label == null or not is_instance_valid(_r36_focus_label):
		return
	var line: String = "专注值 FP %d/%d  ｜  Q 战技" % [_r36_fp, _r36_fp_max]
	if not _r36_parry_negate_text.is_empty():
		line += "  ｜  %s" % _r36_parry_negate_text
	elif not _r36_hint_text.is_empty():
		line += "  ｜  %s" % _r36_hint_text
	_r36_focus_label.text = line
	_r36_focus_label.visible = true        # 常驻显示「当前 / 上限」，不按窗口隐藏
	_r36b_refresh_art()                    # R36B：同步「当前战技：XXX」真实节点（常驻，与 FP 条同源刷新）


## 生产帧驱动：提示 / A65 反馈显示时长 + 冷却镜像递减（服务真实 tick 由导演层帧链转发）。
func tick_focus(delta: float) -> void:
	var dt: float = maxf(0.0, delta)
	if _r36_hint_remaining > 0.0:
		_r36_hint_remaining = maxf(0.0, _r36_hint_remaining - dt)
		if _r36_hint_remaining <= 0.0:
			_r36_hint_text = ""
	if _r36_parry_negate_remaining > 0.0:
		_r36_parry_negate_remaining = maxf(0.0, _r36_parry_negate_remaining - dt)
		if _r36_parry_negate_remaining <= 0.0:
			_r36_parry_negate_text = ""
	if _r36_cooldown > 0.0:
		_r36_cooldown = maxf(0.0, _r36_cooldown - dt)


func _try_focus_skill_input(event: InputEvent) -> Dictionary:
	return request_focus_skill(event)


## A65 [HOST 裁决] · 弹反成功免伤 HUD 反馈：ENC.parry_damage_negated 的【生产运行时订阅者】
##   （_r36_bootstrap connect，非验证脚本）。本次窗口内成功 → 显示「弹反·免伤」。
func _r36_on_parry_damage_negated(_window_id: String) -> void:
	_r36_parry_negate_count += 1
	_r36_parry_negate_text = "弹反·免伤"
	_r36_parry_negate_remaining = R36_NEGATE_SHOW_SEC
	_r36_refresh_focus()
	print("[R36][HUD] A65 弹反·免伤反馈 | wid=%s count=%d（生产订阅者，非验证脚本）" % [
			_window_id, _r36_parry_negate_count])


## 赐福休息回满 FP：ENC.grace_rested 生产订阅者回调 → 唯一 focus_service.rest() → poll 回读。
func _r36_on_grace_rested(_rest_count: int) -> void:
	var svc: Object = _r36_focus
	if svc != null and is_instance_valid(svc):
		for m: String in R36_FOCUS_METHOD_REST:
			if svc.has_method(m):
				svc.call(m)
				break
	poll_focus_service()
	_r36_hint_text = "赐福休息 · FP 回满"
	_r36_hint_remaining = R36_HINT_SHOW_SEC
	_r36_parry_negate_text = ""
	_r36_refresh_focus()
	print("[R36][HUD] 赐福休息 → focus_service.rest() → FP 回满 | fp=%d/%d" % [_r36_fp, _r36_fp_max])


func _r36_dedup_connect(obj: Object, sig: String, method: String) -> void:
	if obj == null or not obj.has_signal(sig):
		return
	var cb: Callable = Callable(self, method)
	for conn in obj.get_signal_connection_list(sig):
		var c: Callable = conn.get("callable", Callable())
		if c.get_object() == self and String(c.get_method()) == method:
			return
	if not obj.is_connected(sig, cb):
		obj.connect(sig, cb)


## 生产装配（_r34_bootstrap 末尾调用 / --script 验证显式调用同一入口）：
##   ① A54 唯一 focus_service 从 wave_trial_director.get_focus_service() 复用（绝不自建）；
##   ② A48① HUD 成为 ENC.parry_damage_negated（A65）/ grace_rested（回满）的生产订阅者。
func _r36_bootstrap() -> void:
	if _r36_bootstrapped:
		return
	_r36_bootstrapped = true
	var ml: MainLoop = Engine.get_main_loop()
	var courtyard: Node = null
	if ml is SceneTree:
		courtyard = (ml as SceneTree).root.get_node_or_null(NodePath("Courtyard"))
	if courtyard == null:
		courtyard = _r34_find_mount_root()
	if courtyard != null:
		var wave: Node = courtyard.get_node_or_null(NodePath(R36_WAVE_REL_PATH))
		if wave != null and wave.has_method("get_focus_service"):
			var svc: Object = wave.call("get_focus_service") as Object
			if svc != null and is_instance_valid(svc):
				bind_focus_service(svc)       # A54：复用唯一实例，不自建第二个
		var enc: Node = courtyard.get_node_or_null(NodePath(R36_ENC_REL_PATH))
		if enc != null and is_instance_valid(enc):
			_r36_dedup_connect(enc, "parry_damage_negated", "_r36_on_parry_damage_negated")
			_r36_dedup_connect(enc, "grace_rested", "_r36_on_grace_rested")
			_r36_focus_signal_connected = true
	print("[R36][HUD] 生产装配 | focus_unique_instance=%s A65/回满生产订阅=%s（A48①/A54，不自建第二实例）" % [
			str(_r36_focus != null and is_instance_valid(_r36_focus)), str(_r36_focus_signal_connected)])


## 信号 connect 的释放路径（_exit_tree → _r34_release → 本函数）。
func _r36_release() -> void:
	var ml: MainLoop = Engine.get_main_loop()
	var courtyard: Node = null
	if ml is SceneTree:
		courtyard = (ml as SceneTree).root.get_node_or_null(NodePath("Courtyard"))
	if courtyard == null:
		courtyard = _r34_find_mount_root()
	if courtyard != null:
		var enc: Node = courtyard.get_node_or_null(NodePath(R36_ENC_REL_PATH))
		if enc != null and is_instance_valid(enc):
			var pairs: Dictionary = {
				"parry_damage_negated": "_r36_on_parry_damage_negated",
				"grace_rested": "_r36_on_grace_rested"}
			for sig: String in pairs.keys():
				if enc.has_signal(sig):
					var cb: Callable = Callable(self, String(pairs[sig]))
					if enc.is_connected(sig, cb):
						enc.disconnect(sig, cb)
	_r36_focus_signal_connected = false


# ==========================================================================
# 18B) R36B [ROUND=R36B] · 战技切换（HOST 裁决 A69：R 键循环切换当前战技）
#   【只读数据表】：arts 列表 / title / 各战技数值全部来自 res://data/combat/focus_rules.tres，
#     经 A54 唯一 FocusService 的公开只读接口 get_art_ids() / get_config() 读取；
#     本层绝不 new 第二个 FocusService、绝不写 .tres、绝不硬编码任何战技 id / 数值。
#   【单一事实源】：当前选中战技索引 _r36b_art_index 只存在 HUD（Q 释放的权威判定者）；
#     HUD._process_r32_keys(R) 与 ENC._unhandled_input(R) 都转发到本段唯一入口
#     request_art_switch()，靠同一 event 实例幂等去重，绝不重复切换。
#   【不重置 FP / 冷却】：切换全程只读服务、不调 spend_fp / tick / on_grace_rest / reset，
#     不改 _r36_fp / _r36_cooldown 镜像，故切换不重置 FP、不触发冷却重置。
#   【不改既有】：既有 18 节 R36 的 14 个 get_focus_hud_view key / 6 信号 / Q 判定分支 /
#     普通攻击判定 / 输出格式逐字不动；仅新增只读 getter 与独立分区真实节点。
# ==========================================================================

## 从 A54 唯一 focus_service 只读 arts 列表，同步本地镜像。
## 只读 get_art_ids() 公开接口；服务缺失 / 命名差异 → 空列表降级、不崩、不产生 SCRIPT ERROR。
func _r36b_sync_art_ids(svc: Object) -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	if svc != null and is_instance_valid(svc) and svc.has_method("get_art_ids"):
		var v: Variant = svc.call("get_art_ids")
		if v is PackedStringArray:
			ids = (v as PackedStringArray).duplicate()
		elif v is Array:
			for s: Variant in (v as Array):
				ids.append(str(s))
	_r36b_art_ids = ids
	return ids


## 只读数据表 title（FocusConfig.get_art_by_id(id) 的 title 字段）；
## 缺失 / 契约替身无 get_config → 回落 art_id 显示，不崩、不改表、不伪造中文名。
func _r36b_art_title(svc: Object, art_id: String) -> String:
	if svc != null and is_instance_valid(svc) and svc.has_method("get_config"):
		var cfg: Object = svc.call("get_config") as Object
		if cfg != null:
			if cfg.has_method("get_art_by_id"):
				var d: Variant = cfg.call("get_art_by_id", art_id)
				if typeof(d) == TYPE_DICTIONARY:
					var t: String = str((d as Dictionary).get("title", ""))
					if not t.is_empty():
						return t
			var raw: Variant = cfg.get("arts")
			if typeof(raw) == TYPE_ARRAY:
				for row: Variant in (raw as Array):
					if typeof(row) == TYPE_DICTIONARY \
							and str((row as Dictionary).get("id", "")) == art_id:
						var t2: String = str((row as Dictionary).get("title", ""))
						if not t2.is_empty():
							return t2
	return art_id


## 当前选中战技 id：默认 arts[0]（既有 Q 行为不回退），R 切换后取 index 对应 id。
## 只读 A54 唯一实例 arts 列表；索引越界自动归 0（表变更 / 服务替换安全降级）。
func get_current_art_id() -> String:
	var ids: PackedStringArray = _r36b_sync_art_ids(_r36_focus)
	if ids.is_empty():
		return ""
	if _r36b_art_index < 0 or _r36b_art_index >= ids.size():
		_r36b_art_index = 0
	return String(ids[_r36b_art_index])


## 当前战技只读视图（供 HUD 显示 / 验证读回 / 运行日志；既有 get_focus_hud_view key 逐字不动）。
func get_current_art_view() -> Dictionary:
	var svc: Object = _r36_focus
	var ids: PackedStringArray = _r36b_sync_art_ids(svc)
	var idx: int = _r36b_art_index
	if not ids.is_empty() and (idx < 0 or idx >= ids.size()):
		idx = 0
	var art_id: String = String(ids[idx]) if not ids.is_empty() else ""
	var title: String = _r36b_art_title(svc, art_id) if not art_id.is_empty() else ""
	return {
		"art_id": art_id,
		"title": title,
		"art_index": idx,
		"art_count": ids.size(),
		"art_ids": ids,
		"switch_count": _r36b_switch_count,
		"rect": get_current_art_rect(),
		"text": ("当前战技：%s" % title) if not art_id.is_empty() else "当前战技：—",
	}


## R36B · R 键循环切换当前战技【唯一权威入口】（A69 裁决）。
##   a) 从 A54 唯一 get_focus_service() 读 arts 列表；b) 索引循环 +1 取模；
##   c) 刷新 HUD「当前战技：辉石魔砾 / 狮子斩」真实节点；
##   e) 全程只读数据表，不调 spend_fp/tick/on_grace_rest/reset，不改 FP 余额 / 冷却镜像
##      → 切换不重置 FP、不触发冷却重置。
##   同一 event 实例幂等去重（ENC + HUD 双接 R，绝不重复切换）；不写 .tres、不自建服务。
func request_art_switch(event: InputEvent = null) -> Dictionary:
	if event != null:
		# 松开 / echo 事件不触发切换（防御 ENC 转发 / 重复投递），且不改幂等缓存。
		if event is InputEventKey:
			var k: InputEventKey = event as InputEventKey
			if not k.pressed or k.echo:
				return {"ok": false, "reason": "not_pressed"}
		var eid: int = event.get_instance_id()
		if eid == _r36b_last_r_event_id and not _r36b_last_r_result.is_empty():
			return _r36b_last_r_result.duplicate()
		_r36b_last_r_event_id = eid
	var svc: Object = _r36_focus
	var ids: PackedStringArray = _r36b_sync_art_ids(svc)
	if ids.is_empty():
		var r_unavail: Dictionary = {"ok": false, "reason": "arts_unavailable",
				"art_index": _r36b_art_index, "art_count": 0}
		_r36b_last_r_result = r_unavail
		return r_unavail.duplicate()
	_r36b_art_index = (_r36b_art_index + 1) % ids.size()
	_r36b_switch_count += 1
	var art_id: String = String(ids[_r36b_art_index])
	var title: String = _r36b_art_title(svc, art_id)
	_r36b_refresh_art()
	var r: Dictionary = {"ok": true, "reason": "ok", "art_id": art_id,
			"title": title, "art_index": _r36b_art_index, "art_count": ids.size(),
			"switch_count": _r36b_switch_count}
	_r36b_last_r_result = r
	print("[R36B][HUD] R 切换战技 | index=%d/%d art=%s 当前战技：%s（只读数据表、不重置 FP/冷却）" % [
			_r36b_art_index, ids.size(), art_id, title])
	return r.duplicate()


## 真实 R 输入落点（与 _unhandled_input 同走 R32 键路径）。
func _try_art_switch_input(event: InputEvent) -> Dictionary:
	return request_art_switch(event)


## 「当前战技」真实节点按独立分区锚点定位（视口变化由 set_layout_viewport 联动重算）。
func _r36b_apply_art_rect() -> void:
	if _r36b_art_label == null or not is_instance_valid(_r36b_art_label):
		return
	var r: Rect2 = get_current_art_rect()
	_r36b_art_label.offset_left = r.position.x
	_r36b_art_label.offset_top = r.position.y
	_r36b_art_label.offset_right = r.end.x
	_r36b_art_label.offset_bottom = r.end.y


## 「当前战技：XXX」真实节点常驻可见刷新（文本只读数据表 title，不写既有 Label.text）。
func _r36b_refresh_art() -> void:
	if _r36b_art_label == null or not is_instance_valid(_r36b_art_label):
		return
	var v: Dictionary = get_current_art_view()
	_r36b_art_label.text = String(v.get("text", "当前战技：—"))
	_r36b_art_label.visible = true


# ==========================================================================
# 19) R37 [ROUND=R37 / v0.14.0] · 元素瓶 G / 死亡轮回 运行时实现
#   （承接文件前部 19 节常量 / 变量前置声明）
# ==========================================================================

func _r37_pick(d: Dictionary, keys: Array[String], default_value: Variant) -> Variant:
	for k: String in keys:
		if d.has(k):
			return d[k]
	return default_value


func _r37_find_courtyard() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	var c: Node = null
	if ml is SceneTree:
		c = (ml as SceneTree).root.get_node_or_null(NodePath("Courtyard"))
	if c == null:
		c = _r34_find_mount_root()
	return c


func _r37_find_enc() -> Node:
	var c: Node = _r37_find_courtyard()
	if c == null:
		return null
	return c.get_node_or_null(NodePath(R37_ENC_REL_PATH))


## A54 唯一实例注入口（生产由 _r37_bootstrap 经 wave.get_flask_service() 复用；
## 验证进程注入契约替身）。绝不 new 第二个生产实例。
func bind_flask_service(svc: Object) -> void:
	_r37_flask = svc
	_r37_flask_snapshot()
	_r37_refresh_flask()


func get_flask_service() -> Object:
	return _r37_flask


func bind_death_service(svc: Object) -> void:
	_r37_death = svc
	_r37_death_snapshot()


func get_death_service() -> Object:
	return _r37_death


## 只读服务快照同步本地瓶数镜像（权威值恒取服务，不写表 / 不二次计算）。
func _r37_flask_snapshot() -> Dictionary:
	var svc: Object = _r37_flask
	if svc == null or not is_instance_valid(svc):
		return {"flask": _r37_flask_cur, "flask_max": _r37_flask_max}
	var snap: Dictionary = {}
	for m: String in R37_FLASK_METHOD_SNAPSHOT:
		if svc.has_method(m):
			var v: Variant = svc.call(m)
			if typeof(v) == TYPE_DICTIONARY:
				snap = v as Dictionary
			break
	_r37_flask_cur = int(_r37_pick(snap, R37_KEY_FLASK, _r37_flask_cur))
	_r37_flask_max = int(_r37_pick(snap, R37_KEY_FLASK_MAX, _r37_flask_max))
	return snap


func _r37_death_snapshot() -> Dictionary:
	var svc: Object = _r37_death
	if svc == null or not is_instance_valid(svc):
		return {"is_dead": _r37_is_dead_state, "dropped_points": _r37_dropped_points}
	var snap: Dictionary = {}
	for m: String in R37_DEATH_METHOD_SNAPSHOT:
		if svc.has_method(m):
			var v: Variant = svc.call(m)
			if typeof(v) == TYPE_DICTIONARY:
				snap = v as Dictionary
			break
	return snap


## 真实玩家 HP 只读来源 = ENC 既有状态（新增只读 getter，不改既有判定 / 帧数据）。
func _r37_enc_hp_view() -> Dictionary:
	var enc: Node = _r37_find_enc()
	if enc != null and is_instance_valid(enc) and enc.has_method("get_life_hp_view"):
		var v: Variant = enc.call("get_life_hp_view")
		if typeof(v) == TYPE_DICTIONARY:
			return v as Dictionary
	return {"hp": _r37_hp, "max_hp": _r37_hp_max}


## 死亡态只读（_process_r32_keys 门禁 / ENC 侧判定 / 验证读回共用）。
func _r37_is_dead() -> bool:
	return _r37_is_dead_state


func is_player_dead() -> bool:
	return _r37_is_dead_state


## 元素瓶 / 死亡轮回 HUD 只读视图（供可见层、运行日志、验证脚本读回；不写盘）。
func get_life_hud_view() -> Dictionary:
	return {
		"flask": _r37_flask_cur,
		"flask_max": _r37_flask_max,
		"flask_text": "元素瓶 %d/%d" % [_r37_flask_cur, _r37_flask_max],
		"hp": _r37_hp,
		"hp_max": _r37_hp_max,
		"is_dead": _r37_is_dead_state,
		"dropped_points": _r37_dropped_points,
		"death_text": ("你死了 · 掉落赐福点数 %d" % _r37_dropped_points) if _r37_is_dead_state else "",
		"hint_text": _r37_hint_text,
		"flask_service_available": _r37_flask != null and is_instance_valid(_r37_flask),
		"death_service_available": _r37_death != null and is_instance_valid(_r37_death),
		"attempt_count": _r37_attempt_count,
		"success_count": _r37_success_count,
		"reject_count": _r37_reject_count,
		"death_count": _r37_death_count,
		"respawn_count": _r37_respawn_count,
		"flask_rect": get_flask_rect(),
		"death_rect": get_death_rect(),
	}


func get_life_attempt_log() -> Array[Dictionary]:
	return _r37_attempt_log.duplicate(true)


func _r37_log(reason: String, ok: bool, hp: int, flask: int) -> void:
	_r37_attempt_log.append({"reason": reason, "ok": ok, "hp": hp, "flask": flask})


func _r37_reason_hint(reason: String) -> String:
	var r: String = reason.to_lower()
	if r.contains("empty") or r.contains("exhaust") or r.contains("no_flask") \
			or r.contains("insufficient") or r.contains("out_of") or r.contains("瓶"):
		return "瓶数不足"
	if r.contains("full") or r.contains("max_hp") or r.contains("满"):
		return "生命已满"
	if r.contains("death") or r.contains("dead"):
		return "死亡期间无法行动"
	if r.contains("duplicate") or r.contains("重复"):
		return "重复按键已忽略"
	if r.contains("unavailable"):
		return "元素瓶服务未就绪"
	return "元素瓶无法使用（%s）" % reason


## 失败统一出口：不扣瓶、发 flask_rejected（A48① ENC 生产订阅者记录）、HUD 提示。
func _r37_reject(reason: String, flask: int) -> Dictionary:
	_r37_reject_count += 1
	_r37_hint_text = _r37_reason_hint(reason)
	_r37_hint_remaining = R37_HINT_SHOW_SEC
	flask_rejected.emit(reason, flask)
	_r37_log(reason, false, int(_r37_hp), flask)
	_r37_refresh_flask()
	var r: Dictionary = {"ok": false, "reason": reason, "flask": flask}
	_r37_last_g_result = r
	return r.duplicate()


## 真实 G 输入【唯一权威判定】（HUD._process_r32_keys / ENC._r37_request_flask_use
## 同调本入口）。成功 → 扣 1 瓶 + 回 HP（服务权威）+ 发 flask_used（A57 最终值）；
## 失败（瓶数不足 / 生命已满 / 死亡期间 / 服务未就绪）→ 不扣瓶 + 提示 + 发 flask_rejected。
## 同一 event 实例幂等去重；服务自身保证瓶尽 / 满血 / 重复按键不二次扣瓶（幂等）。
func request_flask_use(event: InputEvent = null) -> Dictionary:
	if event != null:
		if event is InputEventKey:
			var k: InputEventKey = event as InputEventKey
			if not k.pressed or k.echo:
				return {"ok": false, "reason": "not_pressed"}
		var eid: int = event.get_instance_id()
		if eid == _r37_last_g_event_id and not _r37_last_g_result.is_empty():
			return _r37_last_g_result.duplicate()
		_r37_last_g_event_id = eid
	_r37_attempt_count += 1
	if _r37_is_dead():
		return _r37_reject("death_state_reject", _r37_flask_cur)
	var svc: Object = _r37_flask
	if svc == null or not is_instance_valid(svc):
		return _r37_reject("flask_service_unavailable", _r37_flask_cur)
	var hp_view: Dictionary = _r37_enc_hp_view()
	var hp: float = float(hp_view.get("hp", _r37_hp))
	var hp_max: float = maxf(1.0, float(hp_view.get("max_hp", _r37_hp_max)))
	_r37_hp = hp
	_r37_hp_max = hp_max
	var flask_before_observed: int = _r37_flask_cur
	var result: Dictionary = {}
	var called: bool = false
	for m: String in R37_FLASK_METHOD_USE:
		if svc.has_method(m):
			var v: Variant = svc.call(m, hp, hp_max)
			if typeof(v) == TYPE_DICTIONARY:
				result = v as Dictionary
			elif typeof(v) == TYPE_BOOL:
				result = {"ok": bool(v)}
			called = true
			break
	if not called:
		return _r37_reject("flask_method_unavailable", _r37_flask_cur)
	_r37_flask_snapshot()                 # 权威瓶数来自服务快照（A54 / A57 原样采信）
	var ok: bool = bool(_r37_pick(result, R37_KEY_OK, false))
	var reason: String = String(_r37_pick(result, R37_KEY_REASON, ""))
	if not ok:
		return _r37_reject(reason if not reason.is_empty() else "flask_rejected", _r37_flask_cur)
	var flask_before: int = int(_r37_pick(result, R37_KEY_FLASK_BEFORE, flask_before_observed))
	var flask_after: int = int(_r37_pick(result, R37_KEY_FLASK, _r37_flask_cur))
	var hp_before: int = int(_r37_pick(result, R37_KEY_HP_BEFORE, int(hp)))
	var hp_after: int = int(_r37_pick(result, R37_KEY_HP, int(hp)))
	_r37_success_count += 1
	_r37_hint_text = "元素瓶 · 回复 %d HP" % maxi(0, hp_after - hp_before)
	_r37_hint_remaining = R37_HINT_SHOW_SEC
	flask_used.emit(flask_before, flask_after, hp_before, hp_after)
	_r37_log("ok", true, hp_after, flask_after)
	_r37_refresh_flask()
	_r37_last_g_result = result
	print("[R37][HUD] 真实 G → 元素瓶成功 | 瓶 %d->%d HP %d->%d → flask_used 已发（A57 原样采信服务最终值，ENC 生产订阅者写回真实 _player_hp）" % [
			flask_before, flask_after, hp_before, hp_after])
	return result.duplicate()


## 真实 G 输入落点（与 _unhandled_input 同走 R32 键路径）。
func _try_flask_input(event: InputEvent) -> Dictionary:
	return request_flask_use(event)


## 赐福点数【只读】来源（death_service.on_death 的 grace_points 实参）：
##   WorldState 既有三段式 flag grace.trial.points（HUD 既有只读口径，绝不写回）；
##   autoload 不可用 → 0 降级（掉落 0，不崩、不伪装点数）。
func _r37_grace_points() -> float:
	var ws: Node = _world_state
	if ws != null and is_instance_valid(ws) and ws.has_method("get_flag"):
		var v: Variant = ws.call("get_flag", FLAG_POINTS, 0)
		if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
			return maxf(0.0, float(v))
	return 0.0


## ENC 转发的 HP 变化 → A54 唯一 death_service 权威判定死亡态（Rank-1 只做状态表现
## 与信号转发）。HP 归零且未进入死亡态 → 调真实接口 on_death(grace_points)（掉落点数
## 只读 WorldState 赐福点数 flag，绝不写回）；契约替身走 observe_hp(hp,max_hp)；
## 服务未落盘 / 无判定方法 → 按 HP 归零做纯状态表现（不判定掉落、不二次结算）。
## 重复 HP 归零转发不二次调 on_death（death_service 自身 already_dead 亦拒绝二次掉落）。
func on_player_hp_changed(hp: float, max_hp: float) -> Dictionary:
	_r37_hp = hp
	_r37_hp_max = maxf(1.0, max_hp)
	var svc: Object = _r37_death
	if svc == null or not is_instance_valid(svc):
		_r37_set_death_state(hp <= 0.0, 0)
		_r37_refresh_flask()
		return {"is_dead": _r37_is_dead_state, "dropped_points": _r37_dropped_points}
	if hp <= 0.0 and not _r37_is_dead_state:
		var triggered: bool = false
		for m: String in R37_DEATH_METHOD_ON_DEATH:
			if svc.has_method(m):
				svc.call(m, _r37_grace_points())   # 真实 DeathService.on_death(grace_points)
				triggered = true
				break
		if not triggered:
			for m2: String in R37_DEATH_METHOD_OBSERVE:
				if svc.has_method(m2):
					svc.call(m2, hp, max_hp)       # 契约替身 observe_hp(hp,max_hp)
					break
	# 快照判定（真实服务 get_snapshot().is_dead / dropped_points）
	var snap: Dictionary = _r37_death_snapshot()
	var dead: bool = bool(_r37_pick(snap, R37_KEY_IS_DEAD, hp <= 0.0))
	var dropped: int = int(_r37_pick(snap, R37_KEY_DROPPED, 0))
	_r37_set_death_state(dead, dropped)
	_r37_refresh_flask()
	return snap


## 死亡态边沿触发：仅在「未死 → 死」时发 player_died（A48① ENC 生产订阅者）并记掉落；
## 重复死亡（已死 → 仍死）不二次掉落 / 不二次发信号 / 不覆盖首轮掉落点数。
func _r37_set_death_state(dead: bool, dropped: int) -> void:
	if dead and not _r37_is_dead_state:
		_r37_is_dead_state = true
		_r37_dropped_points = dropped
		_r37_death_count += 1
		player_died.emit(dropped)
		print("[R37][HUD] HP 归零 → 死亡态 | 掉落赐福点数=%d death_count=%d → player_died 已发（death_service 权威判定，不新增第二套胜负判定）" % [
				dropped, _r37_death_count])
	_r37_refresh_death()


## 赐福休息 / 重生（ENC.grace_rested 的【生产运行时订阅者】，_r37_bootstrap connect）：
##   flask_service.on_grace_rest() 补满瓶 + death_service.respawn() 判定重生；
##   HP 回满由 ENC 既有 _grace_rest() 完成、FP 回满由 R36 既有订阅完成、
##   连击 / 弹反 / 处决窗口重置由 ENC 既有 _state.reset() + Rank-2 wave 完成，
##   本层只清死亡态显示 + 发 player_respawned（A48①），不新增第二套胜负判定。
func _r37_on_grace_rested(_rest_count: int) -> void:
	# 重入守卫（真跑实证修复）：Rank-2 wave._on_respawn_performed → encounter.trial_grace_rest()
	# → _grace_rest() → grace_rested 二次广播会嵌套回到本回调，造成二次补瓶 /
	# 二次 player_respawned。嵌套直接 return；外层先清死亡态杜绝二次判定 was_dead。
	if _r37_resting:
		return
	_r37_resting = true
	var was_dead: bool = _r37_is_dead_state
	_r37_is_dead_state = false
	var fs: Object = _r37_flask
	if fs != null and is_instance_valid(fs):
		for m: String in R37_FLASK_METHOD_REST:
			if fs.has_method(m):
				fs.call(m)
				break
	_r37_flask_snapshot()
	var ds: Object = _r37_death
	if ds != null and is_instance_valid(ds):
		for m2: String in R37_DEATH_METHOD_RESPAWN:
			if ds.has_method(m2):
				ds.call(m2)
				break
	_r37_is_dead_state = false
	_r37_dropped_points = 0
	var hp_view: Dictionary = _r37_enc_hp_view()
	_r37_hp = float(hp_view.get("hp", _r37_hp))
	_r37_hp_max = maxf(1.0, float(hp_view.get("max_hp", _r37_hp_max)))
	if was_dead:
		_r37_respawn_count += 1
		player_respawned.emit(int(_r37_hp), _r36_fp, _r37_flask_cur)
		print("[R37][HUD] 赐福重生 → HP/FP/瓶回满 | hp=%d fp=%d flask=%d → player_respawned 已发（清除「你死了」，回到当前波起点由 Rank-2 wave 既有链完成）" % [
				int(_r37_hp), _r36_fp, _r37_flask_cur])
	_r37_hint_text = "赐福休息 · 元素瓶补满"
	_r37_hint_remaining = R37_HINT_SHOW_SEC
	_r37_refresh_flask()
	_r37_refresh_death()
	_r37_resting = false                       # 释放重入守卫（外层回调结束）


## 「元素瓶 N/M」真实节点按独立分区锚点定位（视口变化由 set_layout_viewport 联动重算）。
func _r37_apply_flask_rect() -> void:
	if _r37_flask_label == null or not is_instance_valid(_r37_flask_label):
		return
	var r: Rect2 = get_flask_rect()
	_r37_flask_label.offset_left = r.position.x
	_r37_flask_label.offset_top = r.position.y
	_r37_flask_label.offset_right = r.end.x
	_r37_flask_label.offset_bottom = r.end.y


## 「你死了」真实节点按独立分区锚点定位（仅死亡态可见）。
func _r37_apply_death_rect() -> void:
	if _r37_death_label == null or not is_instance_valid(_r37_death_label):
		return
	var r: Rect2 = get_death_rect()
	_r37_death_label.offset_left = r.position.x
	_r37_death_label.offset_top = r.position.y
	_r37_death_label.offset_right = r.end.x
	_r37_death_label.offset_bottom = r.end.y


## 元素瓶常驻可见刷新（本地镜像 + 提示，不写既有 Label.text、不读服务快照）。
func _r37_refresh_flask() -> void:
	if _r37_flask_label == null or not is_instance_valid(_r37_flask_label):
		return
	var line: String = "元素瓶 %d/%d  ｜  G 使用" % [_r37_flask_cur, _r37_flask_max]
	if not _r37_hint_text.is_empty():
		line += "  ｜  %s" % _r37_hint_text
	_r37_flask_label.text = line
	_r37_flask_label.visible = true


## 死亡态显示刷新：死亡 → 「你死了 · 掉落赐福点数 N」，重生 → 隐藏。
func _r37_refresh_death() -> void:
	if _r37_death_label == null or not is_instance_valid(_r37_death_label):
		return
	if _r37_is_dead_state:
		_r37_death_label.text = String(get_life_hud_view().get("death_text", "你死了")) + "  ｜  赐福 E 重生"
		_r37_death_label.visible = true
	else:
		_r37_death_label.text = ""
		_r37_death_label.visible = false


## 生产帧驱动：元素瓶提示显示时长递减（不调服务方法、不改既有帧数据）。
func tick_life(delta: float) -> void:
	if _r37_hint_remaining > 0.0:
		_r37_hint_remaining = maxf(0.0, _r37_hint_remaining - maxf(0.0, delta))
		if _r37_hint_remaining <= 0.0:
			_r37_hint_text = ""
			_r37_refresh_flask()


func _r37_dedup_connect(obj: Object, sig: String, method: String) -> void:
	if obj == null or not obj.has_signal(sig):
		return
	var cb: Callable = Callable(self, method)
	for conn in obj.get_signal_connection_list(sig):
		var c: Callable = conn.get("callable", Callable())
		if c.get_object() == self and String(c.get_method()) == method:
			return
	if not obj.is_connected(sig, cb):
		obj.connect(sig, cb)


## 生产装配（_r34_bootstrap 末尾调用 / --script 验证显式调用同一入口）：
##   ① A54 唯一 flask_service / death_service 从 wave.get_*_service() 复用（绝不自建）；
##   ② A48① 订阅 ENC.grace_rested → _r37_on_grace_rested（补满瓶 / 判定重生）。
func _r37_bootstrap() -> void:
	if _r37_bootstrapped:
		return
	_r37_bootstrapped = true
	var courtyard: Node = _r37_find_courtyard()
	if courtyard != null:
		var wave: Node = courtyard.get_node_or_null(NodePath(R37_WAVE_REL_PATH))
		if wave != null:
			if wave.has_method("get_flask_service"):
				var fs: Object = wave.call("get_flask_service") as Object
				if fs != null and is_instance_valid(fs):
					bind_flask_service(fs)        # A54：复用唯一实例，不自建第二个
			if wave.has_method("get_death_service"):
				var ds: Object = wave.call("get_death_service") as Object
				if ds != null and is_instance_valid(ds):
					bind_death_service(ds)
		var enc: Node = courtyard.get_node_or_null(NodePath(R37_ENC_REL_PATH))
		if enc == null:
			enc = _r37_find_enc()
		if enc != null and is_instance_valid(enc):
			_r37_dedup_connect(enc, "grace_rested", "_r37_on_grace_rested")
			_r37_grace_subscribed = true
	_r37_flask_snapshot()
	_r37_refresh_flask()
	_r37_refresh_death()
	print("[R37][HUD] 生产装配 | flask_unique=%s death_unique=%s grace_subscribed=%s（A48①/A54，不自建第二实例）" % [
			str(_r37_flask != null and is_instance_valid(_r37_flask)),
			str(_r37_death != null and is_instance_valid(_r37_death)), str(_r37_grace_subscribed)])


## 信号 connect 的释放路径（_exit_tree → _r37_release）。
func _r37_release() -> void:
	var enc: Node = _r37_find_enc()
	if enc != null and is_instance_valid(enc) and enc.has_signal("grace_rested"):
		var cb: Callable = Callable(self, "_r37_on_grace_rested")
		if enc.is_connected("grace_rested", cb):
			enc.disconnect("grace_rested", cb)
	_r37_grace_subscribed = false
