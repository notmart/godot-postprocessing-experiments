// NOTE: Shader automatically converted from Godot Engine 4.3.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_noise : source_color, filter_linear_mipmap, repeat_enable;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

// The fixed world space point to pin the texture to
uniform vec3 pinned_world_position = vec3(100.0, 0.0, 100.0);

varying vec2 uv_zero_screen_pos;
varying vec2 vertex_uv;

const mat4 bayerIndex = mat4(
    vec4(00.0/16.0, 12.0/16.0, 03.0/16.0, 15.0/16.0),
    vec4(08.0/16.0, 04.0/16.0, 11.0/16.0, 07.0/16.0),
    vec4(02.0/16.0, 14.0/16.0, 01.0/16.0, 13.0/16.0),
    vec4(10.0/16.0, 06.0/16.0, 09.0/16.0, 05.0/16.0));

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float pattern(vec2 co){
    return sin(co.x * 100.0) * sin(co.y * 100.0);
}

void vertex() {
	//UV = UV * uv1_scale.xy + uv1_offset.xy;

	// Store the original UV for later comparison
    vertex_uv = UV;

    // Check if this vertex has UV coordinates close to (0,0)
    // We use a small epsilon for floating point comparison
    if (length(UV) < 0.001) {
        // Calculate clip space position
        vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);

        // Convert to screen space (0 to 1 range)
        uv_zero_screen_pos = (clip_pos.xy / clip_pos.w) * 0.5 + 0.5;
    }
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	//ALBEDO += rand(UV) - 0.5;
	ALBEDO += pattern(UV)*0.01;

	int x = int(UV.x*100.0) % 4;
	int y = int(UV.y*100.0) % 4;
	float m = bayerIndex[x][y] * 1.0 - 0.5;
	//ALBEDO += m*0.01;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;


	float texture_scale = 1.0;

	// Transform the pinned world position to view space
    vec4 view_pos = VIEW_MATRIX * vec4(pinned_world_position, 1.0);

    // Project the view space position to clip space
    vec4 clip_pos = PROJECTION_MATRIX * view_pos;

    // Convert to screen space (0-1 range)
    vec2 pin_screen_pos = (clip_pos.xy / clip_pos.w) * 0.5 + 0.5;

    // Calculate the offset from the center of the screen
    vec2 offset = pin_screen_pos - vec2(0.5, 0.5);

    // Apply the offset to the current screen coordinates
    // This keeps the texture undistorted but shifted based on the pinned point
    vec2 tex_coord = (SCREEN_UV - offset) / texture_scale;
	tex_coord = (SCREEN_UV*20.0 -pin_screen_pos );
	ALBEDO = mix(albedo.rgb, texture(texture_noise, tex_coord).rgb, 0.98);
	//ALBEDO = pinned_world_position/10.0;
}
