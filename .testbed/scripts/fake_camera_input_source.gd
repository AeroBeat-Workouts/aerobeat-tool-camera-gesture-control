class_name FakeCameraInputSource
extends Node

@export var tracking := true
@export var confidence := 1.0
@export var head_position := Vector3(0.5, 0.5, 0.0)
@export var head_velocity := Vector3.ZERO
@export var head_rotation := Quaternion.IDENTITY
@export var animate := true
@export var animation_speed := 1.0

var _last_position := Vector3(0.5, 0.5, 0.0)
var _time := 0.0

func _process(delta: float) -> void:
	if not animate:
		head_velocity = (head_position - _last_position) / maxf(delta, 0.0001)
		_last_position = head_position
		return
	_time += delta * animation_speed
	var next_position := Vector3(
		0.5 + sin(_time * 1.3) * 0.18,
		0.5 + cos(_time * 0.9) * 0.14,
		sin(_time * 0.65) * 0.08
	)
	head_velocity = (next_position - _last_position) / maxf(delta, 0.0001)
	head_position = next_position
	head_rotation = Quaternion.from_euler(Vector3(sin(_time) * 0.08, cos(_time * 1.2) * 0.12, sin(_time * 0.7) * 0.03))
	_last_position = next_position

func is_tracking() -> bool:
	return tracking

func get_tracking_confidence(_body_part: StringName) -> float:
	return confidence

func get_head_position(_mode := 0) -> Vector3:
	return head_position

func get_head_velocity() -> Vector3:
	return head_velocity

func get_head_rotation() -> Quaternion:
	return head_rotation
