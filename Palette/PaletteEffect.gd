@tool
extends CompositorEffect
class_name PaletteEffect

var rd: RenderingDevice
var shader: RID
var pipeline: RID

@export var palette: Texture2D
var palette_image: Image = Image.new()

var nearest_sampler : RID
var linear_sampler : RID

func _init() -> void:
	palette_image.load("res://Palette/palette.png")
	palette_image.convert(Image.FORMAT_RGBAF)
	RenderingServer.call_on_render_thread(__initialize_compute_shader)


func _notification(what: int) -> void:
	if what ==  NOTIFICATION_PREDELETE && shader.is_valid():
		RenderingServer.free_rid(shader)

func _get_image_uniform(image: RID, binding: int) -> RDUniform:
	var uniform: RDUniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = binding
	uniform.add_id(image)
	return uniform

func _get_sampler_uniform(image : RID, binding : int = 0, linear : bool = true) -> RDUniform:
	var uniform : RDUniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uniform.binding = binding
	if linear:
		uniform.add_id(linear_sampler)
	else:
		uniform.add_id(nearest_sampler)
	uniform.add_id(image)
	return uniform

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
		var fmt = RDTextureFormat.new()
		fmt.width = palette_image.get_width()
		fmt.height = palette_image.get_height()
		fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
		fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		var tex_view = RDTextureView.new()
		var tex = rd.texture_create(fmt, tex_view, [palette_image.get_data()])
		var palette_tex: RID = tex
		var uniform: RDUniform = _get_image_uniform(screen_tex, 0)
		var uniform2: RDUniform = _get_sampler_uniform(palette_tex, 0, false)
		
		var screen_tex_uniform_set: RID = UniformSetCacheRD.get_cache(shader, 0, [uniform])
		var palette_tex_uniform_set: RID = UniformSetCacheRD.get_cache(shader, 1, [uniform2])
		var compute_list: int = rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		rd.compute_list_bind_uniform_set(compute_list, screen_tex_uniform_set, 0)
		rd.compute_list_bind_uniform_set(compute_list, palette_tex_uniform_set, 1)
		rd.compute_list_set_push_constant(compute_list, push_constants.to_byte_array(), push_constants.size() * 4)
		rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
		rd.compute_list_end()


func __initialize_compute_shader() -> void:
	rd = RenderingServer.get_rendering_device()
	if !rd:
		return
	
	# Create our samplers
	var sampler_state : RDSamplerState = RDSamplerState.new()
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	nearest_sampler = rd.sampler_create(sampler_state)

	sampler_state = RDSamplerState.new()
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	linear_sampler = rd.sampler_create(sampler_state)
	
	var gglsl_file: RDShaderFile = load("res://Palette/PaletteEffect.glsl")
	shader = rd.shader_create_from_spirv(gglsl_file.get_spirv())
	pipeline = rd.compute_pipeline_create(shader)
