// R29 v0.7.0 · P2 全屏景深强化小样（cmd-20261111-112804-021-A4 · Rank-4）
// Compatibility 后端 screen texture 尝试：hint_screen_texture / SCREEN_UV。
// 所有生效数值由 godot/scripts/render/hd2d_parallax.gd 从 Rank-2 depth_profile.tres
// （未落盘则 [PLACEHOLDER] 安全默认）经 set_shader_parameter 注入；
// 本文件 uniform 一律不带默认值，不硬编码任何生效数值。
// 若 Compatibility 后端 screen texture 不可用，hd2d_parallax.gd 会关闭本 shader
// 并降级为程序化 _draw() 强化，且如实登记「shader 未生效」（裁决 A30）。
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;

uniform float vignette_strength;
uniform float vignette_inner;
uniform float vignette_outer;
uniform float cool_fog_strength;
uniform vec3 cool_fog_color;
uniform float warm_glow_strength;
uniform vec3 warm_glow_color;
uniform vec2 warm_glow_pos;
uniform float depth_far_strength;
uniform float blur_radius;
uniform float bloom_threshold;
uniform vec2 screen_px;
uniform float wave_tier;
uniform float lit_level;
uniform float finale;

void fragment() {
	vec2 uv = SCREEN_UV;
	float aspect = screen_px.x / max(screen_px.y, 1.0);
	vec2 texel = 1.0 / max(screen_px, vec2(1.0));
	vec3 base = texture(screen_tex, uv).rgb;

	// ① 多层视差景深：屏幕上部（远景）轻模糊 + 降饱和 + 冷夜雾；下部近景保持锐利
	float far = 1.0 - smoothstep(0.02, 0.30, uv.y);
	vec2 r = texel * blur_radius * far;
	vec3 blur = (
		texture(screen_tex, uv + vec2(r.x, 0.0)).rgb +
		texture(screen_tex, uv - vec2(r.x, 0.0)).rgb +
		texture(screen_tex, uv + vec2(0.0, r.y)).rgb +
		texture(screen_tex, uv - vec2(0.0, r.y)).rgb
	) * 0.25;
	vec3 col = mix(base, blur, clamp(depth_far_strength * 3.0 * far, 0.0, 0.85));
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(lum), far * cool_fog_strength * 0.35);
	col = mix(col, cool_fog_color, far * cool_fog_strength * 0.40);

	// ② 边缘暗角（宽高比校正的径向压暗）
	vec2 dv = uv - vec2(0.5);
	dv.x *= aspect;
	float dist = length(dv) / 0.72;
	float vig = 1.0 - vignette_strength * smoothstep(vignette_inner, vignette_outer, dist);
	col *= vig;

	// ③ 冷夜雾（近景底部薄雾，衔接 3D 地面）
	float low_fog = smoothstep(0.58, 1.0, uv.y) * cool_fog_strength * 0.22;
	col = mix(col, cool_fog_color, low_fog);

	// ④ 暖金光晕：随点亮态 / 波次平滑递进（不闪烁），仅暖金主光过阈
	vec2 gv = uv - warm_glow_pos;
	gv.x *= aspect;
	float gd = length(gv);
	float glow = exp(-gd * gd * 16.0) * warm_glow_strength
		* (0.55 + 0.45 * lit_level) * (0.60 + 0.40 * wave_tier);
	float core = (1.0 - smoothstep(0.0, 0.05, gd)) * bloom_threshold
		* warm_glow_strength * lit_level;
	col += warm_glow_color * (glow + core);

	// ⑤ 三波完成收束光效（一次性扩散环，程序化 uniform 驱动，非反复闪烁）
	if (finale > 0.001) {
		float rr = (1.0 - finale) * 0.95;
		float ring = exp(-pow((gd - rr) * 10.0, 2.0));
		col += warm_glow_color * ring * finale * 0.55;
	}

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
