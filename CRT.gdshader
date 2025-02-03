shader_type canvas_item;

uniform sampler2D screen: hint_screen_texture, filter_linear_mipmap;

uniform float curvature = 10.0;
uniform float vignette_width = 10.0;
uniform float glow = 2.2;
uniform float contrast = 2.0;
uniform float saturation = 0.5;
uniform float scanline_strength = 1.0;

void fragment() {
	vec2 screen_size = vec2(textureSize(screen, 0));
	vec2 pixel = vec2(1.0 / screen_size.x, 1.0 / screen_size.y);

	vec2 uv = SCREEN_UV * 2.0 - 1.0;
	vec2 sphere_offset = uv.yx / curvature;
	uv = uv + uv * sphere_offset * sphere_offset;

	vec2 vignette_size = vec2(vignette_width / screen_size.x, vignette_width / screen_size.y);
	vec2 vignette = smoothstep(vec2(0.0), vignette_size, 1.0 - abs(uv));

	uv = uv * 0.5 + 0.5;

	float scanline = sin(uv.y * (2.0 * PI) * (screen_size.y / 3.0)) * 0.5 + 0.5;
	scanline *= scanline_strength;
	float vertical_line = sin(uv.x * (2.0 * PI) * (screen_size.x / 2.0)) * 0.5 + 0.5;

	vec4 light_area = texture(screen, uv) * 0.6 + texture(screen, uv + vec2(pixel.x, 0.0)) * 0.2 + texture(screen, uv + vec2(2.0 * pixel.x, 0.0)) * 0.2;
	//light_area *= glow;
	//light_area = (light_area - 0.5) * contrast + 0.5;
	light_area *= max(vec4(1.0), glow * (1.0 - light_area));
	
	float average = (light_area.r + light_area.g + light_area.b) / 3.0;
	float xd = average - light_area.r;
	float yd = average - light_area.g;
	float zd = average - light_area.b;
	light_area.r += xd * -saturation;
	light_area.g += yd * -saturation;
	light_area.b += zd * -saturation;
	
	vec4 dark_area = light_area * 0.4 + texture(screen, uv + vec2(0.0, pixel.y)) * 0.3 + texture(screen, uv - vec2(0.0, pixel.y)) * 0.3;
	dark_area *= dark_area * glow;
	
	vec4 blur = max(vec4(0.0), textureLod(screen, uv, 1.0) * 4.0 - 2.0);
	
	COLOR = vec4(0.0);
	COLOR = mix(light_area, dark_area, scanline);
	COLOR = mix(COLOR, vec4(vertical_line), 0.02);
	//COLOR += blur;

	COLOR.rgb = COLOR.rgb * vignette.x * vignette.y;
	COLOR.a = 1.0;
	//COLOR = blur;
}
