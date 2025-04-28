shader_type spatial;
render_mode cull_front, unshaded;

uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap;

const mat4 bayerIndex = mat4(
    vec4(00.0/16.0, 12.0/16.0, 03.0/16.0, 15.0/16.0),
    vec4(08.0/16.0, 04.0/16.0, 11.0/16.0, 07.0/16.0),
    vec4(02.0/16.0, 14.0/16.0, 01.0/16.0, 13.0/16.0),
    vec4(10.0/16.0, 06.0/16.0, 09.0/16.0, 05.0/16.0));

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	//NORMAL = -NORMAL;
}

void fragment() {
	int x = int(UV.x * 1100.0) % 4;
	int y = int(UV.y * 400.0) % 4;
	float m = bayerIndex[x][y] * 1.0 - 0.5;
	//m = rand(point) - 0.5;
	//m = rand(vec2(float(x), float(y))) - 0.5;
	m *= 0.01;
	
	ALBEDO = texture(screen_texture, SCREEN_UV).rgb;
	ALBEDO -= m;
	ALBEDO = floor(ALBEDO * 64.0) / (64.0);
	//ALBEDO = vec3(0.0);
	
	//ALPHA = m;
}

