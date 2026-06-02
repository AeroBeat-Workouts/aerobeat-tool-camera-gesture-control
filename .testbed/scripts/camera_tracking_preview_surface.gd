class_name CameraTrackingPreviewSurface
extends TextureRect

@export var show_overlay := false

var _streaming := false

func start_stream() -> bool:
	_streaming = true
	return true

func stop_stream() -> void:
	_streaming = false

func is_streaming() -> bool:
	return _streaming

func _get_displayed_image_size() -> Vector2:
	return size if size.x > 0.0 and size.y > 0.0 else Vector2(640.0, 480.0)

func _get_displayed_image_offset(_displayed_size: Vector2) -> Vector2:
	return Vector2.ZERO
