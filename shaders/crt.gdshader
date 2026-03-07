shader_type canvas_item;

uniform float scan_line_count : hint_range(0, 1080) = 150.0;
uniform float curvature_x : hint_range(0.0, 1.0) = 0.25;
uniform float curvature_y : hint_range(0.0, 1.0) = 0.33;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

vec2 uv_curve(vec2 uv) {
	uv = (uv - 0.5) * 2.0;

	// You can tweak these values for more/less curve
	uv.x *= 1.0 + pow(abs(uv.y) * curvature_x, 2.0);
	uv.y *= 1.0 + pow(abs(uv.x) * curvature_y, 2.0);

	uv = (uv / 2.0) + 0.5;
	return uv;
}

void fragment() {
	vec2 curved_uv = uv_curve(SCREEN_UV);

	// Check if outside screen bounds
	if (curved_uv.x < 0.0 || curved_uv.x > 1.0 || curved_uv.y < 0.0 || curved_uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec3 color = texture(SCREEN_TEXTURE, curved_uv).rgb;

		// Scanlines
		float s = sin(curved_uv.y * scan_line_count * PI * 2.0);
		s = (s * 0.5 + 0.5) * 0.9 + 0.1;
		color *= pow(s, 0.25);

		// Vignette
		float vignette = (curved_uv.x * curved_uv.y * (1.0 - curved_uv.x) * (1.0 - curved_uv.y)) * 15.0;
		vignette = clamp(pow(vignette, 0.25), 0.0, 1.0);
		color *= vignette;

		COLOR = vec4(color, 1.0);
	}
}
