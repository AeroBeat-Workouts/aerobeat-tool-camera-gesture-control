class_name CameraGestureController
extends Node

signal control_mode_changed(mode: String)
signal tracking_state_changed(state: Dictionary)
signal profile_loaded(profile: Dictionary)
signal profile_saved(path: String)

const PROFILE_VERSION := 1
const CONTROL_MODE_GESTURE := "gesture"
const CONTROL_MODE_MOUSE_WASD := "mouse_wasd"
const CONTROL_MODE_DISABLED := "disabled"
const VALID_CONTROL_MODES := [
	CONTROL_MODE_GESTURE,
	CONTROL_MODE_MOUSE_WASD,
	CONTROL_MODE_DISABLED,
]
const SUPPORTED_SAMPLE_SOURCES := [
	"head_position",
	"head_velocity",
	"head_rotation",
]
const DEFAULT_PROFILE := {
	"version": PROFILE_VERSION,
	"mode": CONTROL_MODE_GESTURE,
	"invert_x": false,
	"invert_y": false,
	"look_sensitivity_x": 1.0,
	"look_sensitivity_y": 1.0,
	"translation_sensitivity_x": 1.0,
	"translation_sensitivity_y": 0.6,
	"translation_sensitivity_z": 0.4,
	"max_yaw_degrees": 20.0,
	"max_pitch_degrees": 12.0,
	"max_roll_degrees": 4.0,
	"max_translation_meters": [0.6, 0.35, 0.45],
	"smoothing": 0.2,
	"deadzone": 0.03,
	"recenter_speed": 1.8,
	"tracking_confidence_threshold": 0.45,
	"freeze_on_tracking_loss": true,
	"sample_source": "head_position",
}

var _enabled := true
var _control_mode := CONTROL_MODE_GESTURE
var _camera: Camera3D = null
var _input_source: Node = null
var _profile: Dictionary = DEFAULT_PROFILE.duplicate(true)
var _last_profile_path := ""
var _tracking_state := {
	"tracking": false,
	"confidence": 0.0,
	"threshold": DEFAULT_PROFILE["tracking_confidence_threshold"],
	"sample_source": DEFAULT_PROFILE["sample_source"],
	"freeze_on_tracking_loss": DEFAULT_PROFILE["freeze_on_tracking_loss"],
	"mode": DEFAULT_PROFILE["mode"],
}

var _rest_position := Vector3.ZERO
var _rest_basis := Basis.IDENTITY
var _current_rotation := Vector3.ZERO
var _current_translation := Vector3.ZERO
var _target_rotation := Vector3.ZERO
var _target_translation := Vector3.ZERO
var _mouse_look_delta := Vector2.ZERO

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if _camera == null:
		return

	if not _enabled or _control_mode == CONTROL_MODE_DISABLED:
		_recenter_to_rest(delta)
		return

	match _control_mode:
		CONTROL_MODE_GESTURE:
			_process_gesture(delta)
		CONTROL_MODE_MOUSE_WASD:
			_process_mouse_wasd(delta)
		_:
			_recenter_to_rest(delta)

func _unhandled_input(event: InputEvent) -> void:
	if not _enabled or _control_mode != CONTROL_MODE_MOUSE_WASD:
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_mouse_look_delta += event.relative

func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not _enabled:
		_target_rotation = Vector3.ZERO
		_target_translation = Vector3.ZERO

func set_control_mode(mode: String) -> void:
	var normalized_mode := String(mode).strip_edges().to_lower()
	if not VALID_CONTROL_MODES.has(normalized_mode):
		normalized_mode = CONTROL_MODE_DISABLED
	if _control_mode == normalized_mode:
		return
	_control_mode = normalized_mode
	_profile["mode"] = _control_mode
	_target_rotation = _current_rotation
	_target_translation = _current_translation
	_mouse_look_delta = Vector2.ZERO
	_emit_tracking_state_if_changed()
	control_mode_changed.emit(_control_mode)

func attach_camera(camera: Camera3D) -> void:
	_camera = camera
	_rest_position = camera.position
	_rest_basis = camera.basis
	_current_rotation = Vector3.ZERO
	_current_translation = Vector3.ZERO
	_target_rotation = Vector3.ZERO
	_target_translation = Vector3.ZERO
	_apply_camera_transform()

func detach_camera() -> void:
	if _camera != null:
		_camera.position = _rest_position
		_camera.basis = _rest_basis
	_camera = null

func attach_input_source(input_source: Node) -> bool:
	if input_source == null:
		return false
	if not _validate_input_source(input_source):
		return false
	_input_source = input_source
	_emit_tracking_state_if_changed(true)
	return true

func detach_input_source() -> void:
	_input_source = null
	_emit_tracking_state_if_changed(true)

func apply_profile(profile: Dictionary) -> void:
	_profile = _normalize_profile(profile)
	_enabled = true
	set_control_mode(String(_profile.get("mode", CONTROL_MODE_GESTURE)))
	_emit_tracking_state_if_changed(true)

func get_profile() -> Dictionary:
	return _profile.duplicate(true)

func load_profile(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("CameraGestureController: failed to open profile for reading: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("CameraGestureController: profile JSON was not a dictionary: %s" % path)
		return {}
	_last_profile_path = path
	apply_profile(parsed)
	var loaded_profile := get_profile()
	profile_loaded.emit(loaded_profile)
	return loaded_profile

func save_profile(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("CameraGestureController: failed to open profile for writing: %s" % path)
		return {}
	var profile := get_profile()
	file.store_string(JSON.stringify(profile, "\t"))
	_last_profile_path = path
	profile_saved.emit(path)
	return {
		"path": path,
		"profile": profile,
	}

func get_debug_state() -> Dictionary:
	return {
		"enabled": _enabled,
		"control_mode": _control_mode,
		"camera_attached": _camera != null,
		"camera_path": str(_camera.get_path()) if _camera != null else "",
		"input_source_attached": _input_source != null,
		"input_source_path": str(_input_source.get_path()) if _input_source != null else "",
		"profile": get_profile(),
		"tracking_state": _tracking_state.duplicate(true),
		"current_rotation_radians": _current_rotation,
		"current_translation": _current_translation,
		"target_rotation_radians": _target_rotation,
		"target_translation": _target_translation,
		"last_profile_path": _last_profile_path,
	}

func _process_gesture(delta: float) -> void:
	var sample := _collect_tracking_sample()
	var tracking_active := bool(sample.get("tracking", false))
	if tracking_active:
		_target_rotation = sample.get("rotation", Vector3.ZERO)
		_target_translation = sample.get("translation", Vector3.ZERO)
	elif not bool(_profile.get("freeze_on_tracking_loss", true)):
		_target_rotation = Vector3.ZERO
		_target_translation = Vector3.ZERO

	var recenter_speed := float(_profile.get("recenter_speed", 1.8))
	if tracking_active:
		_current_rotation = _smooth_vector(_current_rotation, _target_rotation, delta)
		_current_translation = _smooth_vector(_current_translation, _target_translation, delta)
	else:
		_current_rotation = _current_rotation.lerp(_target_rotation, clampf(delta * recenter_speed, 0.0, 1.0))
		_current_translation = _current_translation.lerp(_target_translation, clampf(delta * recenter_speed, 0.0, 1.0))
	_apply_camera_transform()

func _process_mouse_wasd(delta: float) -> void:
	var profile := _profile
	var move_input := Vector3(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_page_up") - Input.get_action_strength("ui_page_down"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	var move_scale := Vector3(
		float(profile.get("translation_sensitivity_x", 1.0)),
		float(profile.get("translation_sensitivity_y", 0.6)),
		float(profile.get("translation_sensitivity_z", 0.4))
	) * 1.5
	_target_translation += Vector3(
		move_input.x * move_scale.x,
		move_input.y * move_scale.y,
		move_input.z * move_scale.z
	) * delta
	_target_translation = _clamp_translation(_target_translation)

	var mouse_scale_x := deg_to_rad(float(profile.get("look_sensitivity_x", 1.0)) * 0.1)
	var mouse_scale_y := deg_to_rad(float(profile.get("look_sensitivity_y", 1.0)) * 0.1)
	_target_rotation.y += -_mouse_look_delta.x * mouse_scale_x
	_target_rotation.x += -_mouse_look_delta.y * mouse_scale_y
	_mouse_look_delta = Vector2.ZERO
	_target_rotation = _clamp_rotation(_target_rotation)

	_current_rotation = _smooth_vector(_current_rotation, _target_rotation, delta)
	_current_translation = _smooth_vector(_current_translation, _target_translation, delta)
	_apply_camera_transform()
	_emit_tracking_state_if_changed()

func _recenter_to_rest(delta: float) -> void:
	var recenter_speed := float(_profile.get("recenter_speed", 1.8))
	_current_rotation = _current_rotation.lerp(Vector3.ZERO, clampf(delta * recenter_speed, 0.0, 1.0))
	_current_translation = _current_translation.lerp(Vector3.ZERO, clampf(delta * recenter_speed, 0.0, 1.0))
	_target_rotation = Vector3.ZERO
	_target_translation = Vector3.ZERO
	_apply_camera_transform()
	_emit_tracking_state_if_changed()

func _apply_camera_transform() -> void:
	if _camera == null:
		return
	var rotation_basis := Basis.from_euler(_current_rotation)
	_camera.position = _rest_position + _current_translation
	_camera.basis = _rest_basis * rotation_basis

func _collect_tracking_sample() -> Dictionary:
	var confidence := _read_tracking_confidence()
	var tracking_signal := _input_source != null and _input_source.has_method("is_tracking") and bool(_input_source.is_tracking())
	var threshold := float(_profile.get("tracking_confidence_threshold", 0.45))
	var tracking_active := tracking_signal and confidence >= threshold
	var sample_source := String(_profile.get("sample_source", "head_position"))
	var result := {
		"tracking": tracking_active,
		"confidence": confidence,
		"threshold": threshold,
		"rotation": Vector3.ZERO,
		"translation": Vector3.ZERO,
	}

	if tracking_active:
		match sample_source:
			"head_velocity":
				var velocity := _call_vector3(_input_source, "get_head_velocity")
				result["translation"] = _build_translation_from_vector(velocity)
				result["rotation"] = _build_rotation_from_vector(velocity)
			"head_rotation":
				var head_rotation := _call_quaternion(_input_source, "get_head_rotation")
				result["rotation"] = _clamp_rotation(head_rotation.get_euler())
				result["translation"] = Vector3.ZERO
			_:
				var head_position := _call_position_variant(_input_source, "get_head_position")
				result["translation"] = _build_translation_from_vector(head_position)
				result["rotation"] = _build_rotation_from_vector(head_position)

	_emit_tracking_state_if_changed(false, {
		"tracking": tracking_active,
		"confidence": confidence,
		"threshold": threshold,
		"sample_source": sample_source,
		"freeze_on_tracking_loss": bool(_profile.get("freeze_on_tracking_loss", true)),
		"mode": _control_mode,
	})
	return result

func _build_translation_from_vector(sample: Vector3) -> Vector3:
	var centered := _apply_deadzone_and_center(sample)
	var invert_x := -1.0 if bool(_profile.get("invert_x", false)) else 1.0
	var invert_y := -1.0 if bool(_profile.get("invert_y", false)) else 1.0
	var translation := Vector3(
		centered.x * float(_profile.get("translation_sensitivity_x", 1.0)) * invert_x,
		centered.y * float(_profile.get("translation_sensitivity_y", 0.6)) * invert_y,
		centered.z * float(_profile.get("translation_sensitivity_z", 0.4))
	)
	return _clamp_translation(translation)

func _build_rotation_from_vector(sample: Vector3) -> Vector3:
	var centered := _apply_deadzone_and_center(sample)
	var invert_x := -1.0 if bool(_profile.get("invert_x", false)) else 1.0
	var invert_y := -1.0 if bool(_profile.get("invert_y", false)) else 1.0
	var rotation := Vector3(
		deg_to_rad(-centered.y * float(_profile.get("max_pitch_degrees", 12.0)) * float(_profile.get("look_sensitivity_y", 1.0)) * invert_y),
		deg_to_rad(-centered.x * float(_profile.get("max_yaw_degrees", 20.0)) * float(_profile.get("look_sensitivity_x", 1.0)) * invert_x),
		deg_to_rad(centered.x * float(_profile.get("max_roll_degrees", 4.0)) * invert_x)
	)
	return _clamp_rotation(rotation)

func _apply_deadzone_and_center(sample: Vector3) -> Vector3:
	var centered := sample
	var sample_source := String(_profile.get("sample_source", "head_position"))
	if sample_source == "head_position":
		centered = Vector3(sample.x - 0.5, sample.y - 0.5, sample.z)
	var deadzone := maxf(float(_profile.get("deadzone", 0.03)), 0.0)
	return Vector3(
		_apply_deadzone(centered.x, deadzone),
		_apply_deadzone(centered.y, deadzone),
		_apply_deadzone(centered.z, deadzone),
	)

func _apply_deadzone(value: float, deadzone: float) -> float:
	if absf(value) <= deadzone:
		return 0.0
	return value

func _smooth_vector(current: Vector3, target: Vector3, delta: float) -> Vector3:
	var smoothing := clampf(float(_profile.get("smoothing", 0.2)), 0.0, 1.0)
	if is_zero_approx(smoothing):
		return target
	var alpha := clampf(delta / smoothing, 0.0, 1.0)
	return current.lerp(target, alpha)

func _clamp_rotation(rotation: Vector3) -> Vector3:
	return Vector3(
		clampf(rotation.x, -deg_to_rad(float(_profile.get("max_pitch_degrees", 12.0))), deg_to_rad(float(_profile.get("max_pitch_degrees", 12.0)))),
		clampf(rotation.y, -deg_to_rad(float(_profile.get("max_yaw_degrees", 20.0))), deg_to_rad(float(_profile.get("max_yaw_degrees", 20.0)))),
		clampf(rotation.z, -deg_to_rad(float(_profile.get("max_roll_degrees", 4.0))), deg_to_rad(float(_profile.get("max_roll_degrees", 4.0))))
	)

func _clamp_translation(translation: Vector3) -> Vector3:
	var max_translation: Array = _profile.get("max_translation_meters", [0.6, 0.35, 0.45])
	var limits := Vector3(
		float(max_translation[0]) if max_translation.size() > 0 else 0.6,
		float(max_translation[1]) if max_translation.size() > 1 else 0.35,
		float(max_translation[2]) if max_translation.size() > 2 else 0.45
	)
	return Vector3(
		clampf(translation.x, -limits.x, limits.x),
		clampf(translation.y, -limits.y, limits.y),
		clampf(translation.z, -limits.z, limits.z)
	)

func _read_tracking_confidence() -> float:
	if _input_source == null:
		return 0.0
	if _input_source.has_method("get_tracking_confidence"):
		return float(_input_source.get_tracking_confidence(&"head"))
	return 1.0 if _input_source.has_method("is_tracking") and bool(_input_source.is_tracking()) else 0.0

func _validate_input_source(input_source: Node) -> bool:
	return input_source.has_method("is_tracking") and input_source.has_method("get_head_position")

func _normalize_profile(profile: Dictionary) -> Dictionary:
	var normalized := DEFAULT_PROFILE.duplicate(true)
	for key_variant: Variant in profile.keys():
		var key := String(key_variant)
		normalized[key] = profile[key_variant]
	normalized["version"] = int(normalized.get("version", PROFILE_VERSION))
	var mode := String(normalized.get("mode", CONTROL_MODE_GESTURE)).to_lower()
	if not VALID_CONTROL_MODES.has(mode):
		mode = CONTROL_MODE_GESTURE
	normalized["mode"] = mode
	var sample_source := String(normalized.get("sample_source", "head_position")).to_lower()
	if not SUPPORTED_SAMPLE_SOURCES.has(sample_source):
		sample_source = "head_position"
	normalized["sample_source"] = sample_source
	normalized["invert_x"] = bool(normalized.get("invert_x", false))
	normalized["invert_y"] = bool(normalized.get("invert_y", false))
	normalized["look_sensitivity_x"] = float(normalized.get("look_sensitivity_x", 1.0))
	normalized["look_sensitivity_y"] = float(normalized.get("look_sensitivity_y", 1.0))
	normalized["translation_sensitivity_x"] = float(normalized.get("translation_sensitivity_x", 1.0))
	normalized["translation_sensitivity_y"] = float(normalized.get("translation_sensitivity_y", 0.6))
	normalized["translation_sensitivity_z"] = float(normalized.get("translation_sensitivity_z", 0.4))
	normalized["max_yaw_degrees"] = maxf(float(normalized.get("max_yaw_degrees", 20.0)), 0.0)
	normalized["max_pitch_degrees"] = maxf(float(normalized.get("max_pitch_degrees", 12.0)), 0.0)
	normalized["max_roll_degrees"] = maxf(float(normalized.get("max_roll_degrees", 4.0)), 0.0)
	normalized["smoothing"] = maxf(float(normalized.get("smoothing", 0.2)), 0.0)
	normalized["deadzone"] = maxf(float(normalized.get("deadzone", 0.03)), 0.0)
	normalized["recenter_speed"] = maxf(float(normalized.get("recenter_speed", 1.8)), 0.0)
	normalized["tracking_confidence_threshold"] = clampf(float(normalized.get("tracking_confidence_threshold", 0.45)), 0.0, 1.0)
	normalized["freeze_on_tracking_loss"] = bool(normalized.get("freeze_on_tracking_loss", true))
	var max_translation_variant: Variant = normalized.get("max_translation_meters", [0.6, 0.35, 0.45])
	var max_translation: Array = []
	if max_translation_variant is Array:
		max_translation = max_translation_variant
	while max_translation.size() < 3:
		max_translation.append(DEFAULT_PROFILE["max_translation_meters"][max_translation.size()])
	normalized["max_translation_meters"] = [
		maxf(float(max_translation[0]), 0.0),
		maxf(float(max_translation[1]), 0.0),
		maxf(float(max_translation[2]), 0.0),
	]
	return normalized

func _emit_tracking_state_if_changed(force := false, candidate: Dictionary = {}) -> void:
	var next_state := candidate.duplicate(true) if not candidate.is_empty() else {
		"tracking": false,
		"confidence": 0.0,
		"threshold": float(_profile.get("tracking_confidence_threshold", 0.45)),
		"sample_source": String(_profile.get("sample_source", "head_position")),
		"freeze_on_tracking_loss": bool(_profile.get("freeze_on_tracking_loss", true)),
		"mode": _control_mode,
	}
	if force or JSON.stringify(_tracking_state) != JSON.stringify(next_state):
		_tracking_state = next_state
		tracking_state_changed.emit(_tracking_state.duplicate(true))

func _call_position_variant(target: Node, method_name: String) -> Vector3:
	if target == null or not target.has_method(method_name):
		return Vector3.ZERO
	var value: Variant = target.call(method_name)
	if value is Vector3:
		return value
	if value is Vector2:
		return Vector3(value.x, value.y, 0.0)
	return Vector3.ZERO

func _call_vector3(target: Node, method_name: String) -> Vector3:
	if target == null or not target.has_method(method_name):
		return Vector3.ZERO
	var value: Variant = target.call(method_name)
	return value if value is Vector3 else Vector3.ZERO

func _call_quaternion(target: Node, method_name: String) -> Quaternion:
	if target == null or not target.has_method(method_name):
		return Quaternion.IDENTITY
	var value: Variant = target.call(method_name)
	return value if value is Quaternion else Quaternion.IDENTITY
