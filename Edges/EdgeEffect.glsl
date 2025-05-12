#[compute]
#version 450

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D screen_tex;
layout(set = 1, binding = 0) uniform sampler2D depth_tex;
layout(set = 2, binding = 0) uniform sampler2D normal_tex;

// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 screen_size;
	vec2 reserved;
} params;


vec4 normal_roughness_compatibility(vec4 p_normal_roughness)
{
	float roughness = p_normal_roughness.w;
	if (roughness > 0.5) {
		roughness = 1.0 - roughness;
	}
	roughness /= (127.0 / 255.0);
	return vec4(normalize(p_normal_roughness.xyz * 2.0 - 1.0) * 0.5 + 0.5, roughness);
}

float rand(vec2 co)
{
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float normal_indicator(vec3 normalEdgeBias, vec3 baseNormal, vec3 newNormal, float depth_diff)
{
	// Credit: https://threejs.org/examples/webgl_postprocessing_pixel.html
	float normalDiff = dot(baseNormal - newNormal, normalEdgeBias);
	float normalIndicator = clamp(smoothstep(-.01, .01, normalDiff), 0.0, 1.0);
	float depthIndicator = clamp(sign(depth_diff * .25 + .0025), 0.0, 1.0);
	//depthIndicator = normalIndicator=1.0;
	return (1.0-dot(newNormal, baseNormal));
	return (1.0 - dot(baseNormal, newNormal)) * depthIndicator * normalIndicator;
}

// The code we want to execute in each invocation
void main()
{
	ivec2 point = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.screen_size);

	if (point.x >= size.x || point.y >= size.y) {
		return;
	}

	vec4 color = imageLoad(screen_tex, point);
	
	float depth_diff = 0.0;
	float neg_depth_diff = 0.0;//5;
	float depth = texelFetch(depth_tex, point, 0).r;
	float du = texelFetch(depth_tex, point + ivec2(0, 1), 0).r;
	float dl = texelFetch(depth_tex, point + ivec2(-1, 0), 0).r;
	float dr = texelFetch(depth_tex, point + ivec2(1, 0), 0).r;
	float dd = texelFetch(depth_tex, point + ivec2(0, -1), 0).r;
	depth_diff += clamp(depth - du, 0., 1.);
	depth_diff += clamp(depth - dd, 0., 1.);
	depth_diff += clamp(depth - dr, 0., 1.);
	depth_diff += clamp(depth - dl, 0., 1.);
	neg_depth_diff += depth - du;
	neg_depth_diff += depth - dd;
	neg_depth_diff += depth - dr;
	neg_depth_diff += depth - dl;
	//neg_depth_diff = clamp(neg_depth_diff, 0., 1.);
	//neg_depth_diff = clamp(smoothstep(0.498, 0.502, neg_depth_diff)*10., 0., 1.);
	//depth_diff = smoothstep(0.00055, 0.00056, depth_diff);
	//depth_diff = 0.1;
	vec3 n = normalize(normal_roughness_compatibility(texelFetch(normal_tex, point, 0)).rgb);
	
	vec3 nu = normalize(normal_roughness_compatibility(texelFetch(normal_tex, point + ivec2(0, 1), 0)).rgb);
	vec3 nl = normalize(normal_roughness_compatibility(texelFetch(normal_tex, point + ivec2(-1, 0), 0)).rgb);
	vec3 nr = normalize(normal_roughness_compatibility(texelFetch(normal_tex, point + ivec2(1, 0), 0)).rgb);
	vec3 nd = normalize(normal_roughness_compatibility(texelFetch(normal_tex, point + ivec2(0, -1), 0)).rgb);
	
	float normal_diff = 0.0;
	vec3 normal_edge_bias = vec3(1.0);
	normal_diff += normal_indicator(normal_edge_bias, n, nu, depth_diff);
	normal_diff += normal_indicator(normal_edge_bias, n, nl, depth_diff);
	normal_diff += normal_indicator(normal_edge_bias, n, nr, depth_diff);
	normal_diff += normal_indicator(normal_edge_bias, n, nd, depth_diff);
	//normal_diff = smoothstep(0.01, 0.02, normal_diff);
	//normal_diff = clamp(normal_diff-(1.0-neg_depth_diff), 0., 1.);
	
	vec3 highlight_color = vec3(1.0);
	float highlight_strength = 0.1;
	float shadow_strength = 0.4;
	vec3 shadow_color = vec3(0.0);
	
	vec3 final_highlight_color = mix(color.rgb, highlight_color, highlight_strength);
	vec3 final_shadow_color = mix(color.rgb, shadow_color, shadow_strength);
	color.rgb = mix(color.rgb, final_highlight_color, normal_diff);
	color.rgb = mix(color.rgb, final_shadow_color, depth_diff);
	
	//color = 1.0 - color;
	//color.rgb = n.rgb;
	//color.rgb += normal_diff;
	//color.rgb = normalize(normal_roughness_compatibility(texelFetch(normal_tex, point, 0)).rgb);

	//color.rgb = texelFetch(depth_tex, point, 0).rgb / texelFetch(depth_tex, point, 0).w;

//color.rgb = vec3((smoothstep(-0.0005, 0.0005, neg_depth_diff)-0.5) * 2.0 + 0.5);
//color.rgb *= vec3((step(0.01, normal_diff) * (smoothstep(-0.0002, 0.0002, neg_depth_diff)-0.5)) * 1.2 + 1.0);
color.rgb *= vec3(((smoothstep(-0.0002, 0.0002, neg_depth_diff)-0.5) * 1.5 + 1.0));
//color.rgb = vec3(step(0.01, normal_diff));
//color.rgb = vec3(depth_diff);
	imageStore(screen_tex, point, color);
}
