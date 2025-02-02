@tool
extends CompositorEffect
class_name PaletteEffect

var rd: RenderingDevice
var shader: RID
var pipeline: RID

func _init() -> void:
	RenderingServer.call_on_render_thread(__initialize_compute_shader)


func _notification(what: int) -> void:
	if what ==  NOTIFICATION_PREDELETE && shader.is_valid():
		RenderingServer.free_rid(shader)


func _render_callback(effect_callback_type: int, render_data: RenderData) -> void:
	if !rd:
		return
	
	var scene_buffers: RenderSceneBuffersRD = render_data.get_render_scene_buffers()
	if !scene_buffers:
		return
	
	var size: Vector2i = scene_buffers.get_internal_size()
	if size.x == 0 || size.y == 0:
		return
	
	var x_groups: int = size.x / 16
	var y_groups: int = size.y / 16
	
	var push_constants: PackedFloat32Array = PackedFloat32Array()
	push_constants.append(size.x)
	push_constants.append(size.y)
	push_constants.append(0.0)
	push_constants.append(0.0)
	
	for view in scene_buffers.get_view_count():
		var screen_tex: RID = scene_buffers.get_color_layer(view)
		var uniform: RDUniform = RDUniform.new()
		uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		uniform.binding = 0
		uniform.add_id(screen_tex)
		
		var image_uniform_set: RID = UniformSetCacheRD.get_cache(shader, 0, [uniform])
		var compute_list: int = rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		rd.compute_list_bind_uniform_set(compute_list, image_uniform_set, 0)
		rd.compute_list_set_push_constant(compute_list, push_constants.to_byte_array(), push_constants.size() * 4)
		rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
		rd.compute_list_end()


func __initialize_compute_shader() -> void:
	rd = RenderingServer.get_rendering_device()
	if !rd:
		return
	var gglsl_file: RDShaderFile = load("res://Palette/PaletteEffect.glsl")
	shader = rd.shader_create_from_spirv(gglsl_file.get_spirv())
	pipeline = rd.compute_pipeline_create(shader)
