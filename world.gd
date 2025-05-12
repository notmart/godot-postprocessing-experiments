extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("camera", -1, 0.1)
	$OmniLight3D/AnimationPlayer.play("flicker", -1, 0.5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Path3D/PathFollow3D/Camera3D.look_at($Cube.global_position)
	$plane.get_surface_override_material(0).set_shader_parameter("pinned_world_position", $ProtoController.to_global(Vector3(0, 1.7, 100)))
