shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D viewport: filter_nearest;

void fragment () {
	COLOR = texture(viewport, UV);
}