class_name QualityPreset
extends Resource
## 画质档 Resource（1 号 R2 交付件，附加脚本；供两份 quality_preset_*.tres 引用）。
## 落位：res://scripts/core/quality_preset.gd。
## 字段对齐 接口契约.md §8 的 QualityProfile，并补齐 R2 要求的缓冲尺寸 / 常驻 chunk 数 /
## 目标帧时间 / 内存上限。数值由 4 号视觉规范与用户人工试玩校准，1 号只定义结构。

@export var low_resolution_size: Vector2i = Vector2i(640, 360)
@export var integer_upscale_factor: int = 2
@export var resident_chunk_count: int = 9
@export var volumetric_fog_enabled: bool = true
@export var glow_enabled: bool = true
@export var dust_particle_cap: int = 120
@export var wet_reflection_enabled: bool = true
@export var shadow_map_size: int = 2048
@export var target_frame_time_ms: float = 16.67
@export var memory_limit_mb: int = 1536
