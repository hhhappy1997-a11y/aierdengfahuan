class_name RenderProfiles
extends Resource
## R3 交付：桌面 / 移动双档渲染画像（两列对照表，可被引擎加载的 Resource）。
## 落位：res://scripts/core/render_profiles.gd；数据件 res://data/render/render_profiles.tres。
## 与 R2 的 quality_preset_*.tres 互补、不重做：那两份是单档运行参数（SceneRouter autoload
## 运行时读取），本件是「桌面档 / 移动档两列」的集中对照资源，字段命名按 R3 任务书
## （volumetric / motes / wet_reflection / bloom），数值与两份 .tres 对齐：
##   volumetric ↔ volumetric_fog_enabled，motes ↔ dust_particle_cap>0，
##   wet_reflection ↔ wet_reflection_enabled，bloom ↔ glow_enabled。

## 低分辨率渲染基准（SubViewport 缓冲尺寸）
@export var desktop_low_resolution: Vector2i = Vector2i(640, 360)
@export var mobile_low_resolution: Vector2i = Vector2i(480, 270)

## 常驻 chunk 数（桌面 3x3=9 / 移动端降级 4）
@export var desktop_resident_chunk_count: int = 9
@export var mobile_resident_chunk_count: int = 4

## FX 开关：体积光 volumetric / 光尘 motes / 湿地倒影 wet_reflection / bloom
@export var desktop_volumetric: bool = true
@export var desktop_motes: bool = true
@export var desktop_wet_reflection: bool = true
@export var desktop_bloom: bool = true
@export var mobile_volumetric: bool = false
@export var mobile_motes: bool = false
@export var mobile_wet_reflection: bool = false
@export var mobile_bloom: bool = false

## 目标帧时间（ms）：桌面 60fps=16.67 / 移动 30fps=33.33
@export var desktop_target_frame_time_ms: float = 16.67
@export var mobile_target_frame_time_ms: float = 33.33

## 显存 / 内存上限（MB）
@export var desktop_vram_limit_mb: int = 1536
@export var mobile_vram_limit_mb: int = 512
