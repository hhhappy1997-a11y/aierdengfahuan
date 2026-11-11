extends Resource
class_name WaveTrialConfig

## ===========================================================================
## R26 / v0.4.0 · 波次试炼数据表资源（Rank-2 交付件）
##
## 真源：teamwork/Rank-2/调度任务单-latest.json（id cmd-20261111-073556-923-A2）
## 目录所有权：本文件 / godot/data/rpg/wave_trial.tres / verify_wave_trial_v040.gd /
##   teamwork/Rank-2/ 归 Rank-2；导演层 wave_trial_director.gd 归 Rank-1（读本 .tres）。
##
## 【设计口径】
## - 数值唯一真源是 res://data/rpg/wave_trial.tres（3 波实例）；本类只定义结构与
##   「字段缺失 / 空表」降级基线，不把任何设计数值写死进代码。
## - 所有数值均标 [PLACEHOLDER]：首版取自任务单，待人工试玩校准；逐项 rationale 见
##   teamwork/Rank-2/WAVE-TRIAL-TUNING.md「数值假设表」。不拍脑袋写死。
## - 全静态类型：@export 字段 / 常量 / 方法参数与返回值全部显式类型标注。
## - 存储层 @export waves: Array[Dictionary]（任务单「可用 Array[Dictionary]」口径）：
##   Godot 4.7.2 中内部类 Resource 实例无法正确序列化进 .tres（引擎把内部类脚本退化成
##   空 [sub_resource type="GDScript"]，回读实例丢脚本类；R26 首次真跑实证，
##   见 R26-build-run.log 首版 / WAVE-TRIAL-TUNING.md §5）。故 .tres 每行用 Dictionary，
##   由 get_wave() 在运行时包装成静态类型视图 WaveData。
## - 每波两种读法都兼容：cfg.waves[i]["hp_multiplier"]（Dictionary / 导演层直读）
##   与 cfg.get_wave(i).hp_multiplier（WaveData 视图）；WaveData 亦支持 wave["field"]。
## 引擎：Godot 4.7.2 标准版 / GDScript。
## ===========================================================================

## ---- [PLACEHOLDER] 降级基线（仅用于字段缺失 / 空表，不是设计数值） ----
## rationale 逐项见 WAVE-TRIAL-TUNING.md §2；下列常量只保证「不崩、可判非法」。
const DEFAULT_ENEMY_ID: String = ""            # [PLACEHOLDER] 空 id = 未配置，is_wave_valid 判非法，强制人工补
const DEFAULT_HP_MULTIPLIER: float = 1.0       # [PLACEHOLDER] 恒等基线：不放大也不削弱既有敌人 HP
const DEFAULT_MOVE_WEIGHT: float = 1.0         # [PLACEHOLDER] 等权基线，与 MoveData.weight=1.0 同源口径
const DEFAULT_REWARD_POINTS: int = 0           # [PLACEHOLDER] 无奖励基线，避免字段缺失凭空点数通胀
const DEFAULT_TELEGRAPH_SEC: float = 1.5       # [PLACEHOLDER] 首版前摇，待试玩校准
const DEFAULT_TIME_LIMIT_SEC: float = 30.0     # [PLACEHOLDER] 首版单波时限，待试玩校准

## 每波「静态类型视图」：仅在运行时由 get_wave() 构造，不参与 .tres 序列化。
## 6 个字段全静态类型；默认值均为 [PLACEHOLDER] 降级基线。
class WaveData extends Resource:
	@export var enemy_id: String = ""                    # [PLACEHOLDER] 复用既有 enemy_01_limgrave_soldier / boss_01_margit
	@export var hp_multiplier: float = 1.0              # [PLACEHOLDER] 与既有敌人 max_hp 相乘
	@export var move_weight: float = 1.0                # [PLACEHOLDER] 招式加权抽取权重
	@export var reward_points: int = 0                  # [PLACEHOLDER] 清波奖励点数
	@export var telegraph_sec: float = 1.5              # [PLACEHOLDER] 出招前摇秒数
	@export var time_limit_sec: float = 30.0            # [PLACEHOLDER] 单波时限秒数

## 三波结构（任务单「@export waves: Array[WaveData] 或等价 / 可用 Array[Dictionary]」口径）。
@export var waves: Array[Dictionary] = []


## 工厂：返回一行 Dictionary（.tres 存储单元）；不硬编码任何设计数值，数值由调用方传入。
func make_wave(
	p_enemy_id: String,
	p_hp_multiplier: float,
	p_move_weight: float,
	p_reward_points: int,
	p_telegraph_sec: float,
	p_time_limit_sec: float) -> Dictionary:
	return {
		"enemy_id": p_enemy_id,
		"hp_multiplier": p_hp_multiplier,
		"move_weight": p_move_weight,
		"reward_points": p_reward_points,
		"telegraph_sec": p_telegraph_sec,
		"time_limit_sec": p_time_limit_sec,
	}


## 字段缺失降级：Dictionary 缺 key / 类型异常时回落到 [PLACEHOLDER] 基线，不抛错。
func wave_from_dict(d: Dictionary) -> WaveData:
	var w: WaveData = WaveData.new()
	w.enemy_id = str(d.get("enemy_id", DEFAULT_ENEMY_ID))
	w.hp_multiplier = float(d.get("hp_multiplier", DEFAULT_HP_MULTIPLIER))
	w.move_weight = float(d.get("move_weight", DEFAULT_MOVE_WEIGHT))
	w.reward_points = int(d.get("reward_points", DEFAULT_REWARD_POINTS))
	w.telegraph_sec = float(d.get("telegraph_sec", DEFAULT_TELEGRAPH_SEC))
	w.time_limit_sec = float(d.get("time_limit_sec", DEFAULT_TIME_LIMIT_SEC))
	return w


## 越界拒绝：第 0 波以下 / 第 4 波及以上等非法下标返回 null，不崩、不回绕；
## 合法波经 wave_from_dict 补齐缺失字段（降级）后返回静态类型视图。
func get_wave(index: int) -> WaveData:
	if index < 0 or index >= waves.size():
		return null
	return wave_from_dict(waves[index] as Dictionary)


func wave_count() -> int:
	return waves.size()


## 单波合法性：time_limit 与 telegraph 合法（>0 且前摇小于时限）、倍率/权重为正、
## 奖励非负、enemy_id 非空。
func is_wave_valid(w: WaveData) -> bool:
	if w == null:
		return false
	if w.enemy_id.is_empty():
		return false
	if w.hp_multiplier <= 0.0 or w.move_weight <= 0.0:
		return false
	if w.reward_points < 0:
		return false
	if w.telegraph_sec <= 0.0 or w.time_limit_sec <= 0.0:
		return false
	if w.telegraph_sec >= w.time_limit_sec:
		return false
	return true
