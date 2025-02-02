#[compute]
#version 450

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D screen_tex;

// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 screen_size;
	vec2 reserved;
} params;

const mat4 bayerIndex = mat4(
    vec4(00.0/16.0, 12.0/16.0, 03.0/16.0, 15.0/16.0),
    vec4(08.0/16.0, 04.0/16.0, 11.0/16.0, 07.0/16.0),
    vec4(02.0/16.0, 14.0/16.0, 01.0/16.0, 13.0/16.0),
    vec4(10.0/16.0, 06.0/16.0, 09.0/16.0, 05.0/16.0));

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

// The code we want to execute in each invocation
void main() {
	ivec2 point = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.screen_size);

	if (point.x >= size.x || point.y >= size.y) {
		return;
	}

	vec4 color = imageLoad(screen_tex, point);

	//color.r = floor(color.r * 30.0) / 30.0;
	//color.g = floor(color.g * 30.0) / 30.0;
	//color.b = floor(color.b * 30.0) / 30.0;
	//color.rgb = 1.0 - color.rgb;
	int x = int(point.x) % 4;
	int y = int(point.y) % 4;
	float m = bayerIndex[x][y] * 1.0 - 0.5;
	//m = rand(point) - 0.5;
	m *= 0.02;
	
	//color = color + vec4(m, m, m, 1.0);
	color += m;
	color = floor(color * 15.0 - 0.5) / (15.0);

	imageStore(screen_tex, point, color);
}
