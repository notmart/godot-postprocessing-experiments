extends Control

func _process(delta: float) -> void:
	$SubViewport.size = Vector2i(get_viewport().get_visible_rect().size / 2.0)
