extends RefCounted
class_name EncounterRulesV020

## ===========================================================================
## v0.2.0 P1 · Rank-2 新增：连续同名招式抑制规则（RefCounted 纯逻辑 / 数据驱动）。
##
## 【定位】修复 v0.1.0 遗留：L3 运行日志出现连续同名 move_01_dagger_slash。
##   本件不进场景树、不依赖 autoload、不读任何 .tres、不改任何既有战斗件，
##   只做「给定上一招 / 候选招 / 冷却秒 / 帧率，判断是否放行」的纯计算。
## 【数据驱动·不硬编码帧数】冷却窗口 = max(MoveData.cooldown_sec,
##   BossData.ai_poll_interval_sec) × fps。帧数完全由「秒 × 帧率」换算得出，
##   代码里没有任何固定帧数常量。DEFAULT_FPS 仅是 fps<=0 时的降级帧率基准
##   （帧率，不是帧数），保证 0 值 / 负 fps 边界不除零、不崩。
##   ai_poll_interval_sec 由导演层按 BossData 注入，作为数据表 cooldown_sec=0
##   时的冷却下限兜底：Boss 至少隔一个 AI 轮询周期才可能再出同一招。
## 【按帧记录】tick_frame() 每逻辑帧推进 _elapsed_frames（上一招距今帧数）；
##   last_move_id 记录最近一次被放行的招式 id；should_allow_move() 据此判定。
## 【对外接口】should_allow_move(last_id, candidate, cooldown_sec, fps) -> bool
##   与 retry_count（连续同名被抑制的累计次数）。
## 引擎：Godot 4.7.2 / GDScript，全静态类型；中文 UTF-8。
## ===========================================================================

## fps<=0 时的降级帧率基准（帧率，不是帧数常量；保证边界不除零）。
const DEFAULT_FPS: float = 60.0

## 按帧记录的「最近一次被放行的招式 id」。
var last_move_id: String = ""
## 连续同名被抑制的累计次数（任务 ②③ 指定的 retry_count）。
var retry_count: int = 0
## 累计放行 / 抑制次数（供快照与自测观测，不参与判定）。
var total_allowed: int = 0
var total_suppressed: int = 0

var _ai_poll_interval_sec: float = 0.0
var _fps: float = DEFAULT_FPS
var _elapsed_frames: int = 0          # 自最近一次放行起经过的逻辑帧
var _active_window_frames: float = 0.0 # 最近一次放行招式的冷却窗口帧数


func _init(ai_poll_interval_sec: float = 0.0, fps: float = DEFAULT_FPS) -> void:
	_ai_poll_interval_sec = maxf(0.0, ai_poll_interval_sec)
	_fps = fps if fps > 0.0 else DEFAULT_FPS
	reset_for_rematch()


## 供导演层按 BossData 重新配置（数据表改动 / 依赖降级后）。
func configure(ai_poll_interval_sec: float, fps: float = DEFAULT_FPS) -> void:
	_ai_poll_interval_sec = maxf(0.0, ai_poll_interval_sec)
	_fps = fps if fps > 0.0 else DEFAULT_FPS


## 每逻辑帧推进（按帧记录上一招 id 的时间基准）。delta 仅作签名兼容：
## 帧基准按「拍」计，与 PlayerActionState / 导演层 60 拍一致，不做浮点累加。
func tick_frame(_delta: float = 0.0) -> void:
	_elapsed_frames += 1


## 冷却窗口帧数：max(招式冷却秒, AI 轮询间隔秒) × fps，全部数据驱动。
## cooldown_sec 来自 MoveData，_ai_poll_interval_sec 来自 BossData。
func window_frames(cooldown_sec: float, fps: float) -> float:
	var base_sec: float = maxf(maxf(0.0, cooldown_sec), _ai_poll_interval_sec)
	return base_sec * (fps if fps > 0.0 else _fps)


## 核心判定：candidate 相对 last_id 是否为「冷却窗口内的连续同名」。
##  - 同名且仍在窗口内 -> 抑制：retry_count / total_suppressed +1，返回 false；
##    不更新 last_move_id / _elapsed_frames（冷却继续计时，下一帧可重试）。
##  - 其余（不同名 / 窗口已过 / 空 id / 0 值降级）-> 放行：记录 id、帧基准归零。
func should_allow_move(last_id: String, candidate: String, cooldown_sec: float, fps: float) -> bool:
	var active_fps: float = fps if fps > 0.0 else _fps
	var window: float = window_frames(cooldown_sec, active_fps)
	var same_move: bool = not last_id.is_empty() and not candidate.is_empty() and candidate == last_id
	var in_window: bool = float(_elapsed_frames) < window
	if same_move and in_window:
		retry_count += 1
		total_suppressed += 1
		return false
	last_move_id = candidate
	_elapsed_frames = 0
	_active_window_frames = window
	total_allowed += 1
	return true


## 赐福休息 / 重复挑战重置：清「上一招」与帧基准，累计计数保留（跨挑战可观测）。
func reset_for_rematch() -> void:
	last_move_id = ""
	_elapsed_frames = 0
	_active_window_frames = 0.0


## 完全重置（含累计计数），供自测隔离用例。
func reset_all() -> void:
	reset_for_rematch()
	retry_count = 0
	total_allowed = 0
	total_suppressed = 0


func get_elapsed_frames() -> int:
	return _elapsed_frames


func get_active_window_frames() -> float:
	return _active_window_frames


func get_ai_poll_interval_sec() -> float:
	return _ai_poll_interval_sec
