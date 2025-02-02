shader_type canvas_item;

uniform sampler2D screen: hint_screen_texture;

uniform float curvature = 10.0;
uniform float vignette_width = 10.0;
uniform float glow = 1.5;

void fragment() {
	vec2 screen_size = vec2(textureSize(screen, 0));
	vec2 pixel = vec2(1.0 / screen_size.x, 1.0 / screen_size.y);

	vec2 uv = UV * 2.0 - 1.0;
	vec2 sphere_offset = uv.yx / curvature;
	uv = uv + uv * sphere_offset * sphere_offset;

	vec2 vignette_size = vec2(vignette_width / screen_size.x, vignette_width / screen_size.y);
	vec2 vignette = smoothstep(vec2(0.0), vignette_size, 1.0 - abs(uv));

	uv = uv * 0.5 + 0.5;

	float scanline = smoothstep(0.49, 0.51, cos(UV.y * PI * 0.5 * screen_size.y) * 0.5 + 0.5);
	float vertical_line = smoothstep(0.49, 0.51, cos(UV.x * PI * 0.5 * screen_size.x) * 0.5 + 0.5);

	vec4 light_area = texture(screen, uv) * 0.5 + texture(screen, uv + vec2(pixel.x, 0.0)) * 0.3 + + texture(screen, uv + vec2(2.0 * pixel.x, 0.0)) * 0.2;
	light_area *= glow;
	vec4 dark_area = light_area * 0.4 + texture(screen, uv + vec2(0.0, pixel.y)) * 0.3 + texture(screen, uv - vec2(0.0, pixel.y)) * 0.3;
	dark_area *= dark_area * glow;

	COLOR = vec4(0.0);
	COLOR= mix(light_area, dark_area, scanline);
	COLOR = mix(COLOR, vec4(vertical_line), 0.02);

	COLOR = COLOR * vignette.x * vignette.y;
	COLOR.a = 1.0;
}
