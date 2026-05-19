class_name CameraGestureController
extends Node

signal control_mode_changed(mode: String)
signal tracking_state_changed(state: Dictionary)
signal profile_loaded(profile: Dictionary)
signal profile_saved(path: String)

const PROFILE_SCHEMA_ID := "camera_gesture_profile"
const PROFILE_SCHEMA_VERSION := 1
const DEFAULT_PROFILE_ID := "default_v1"
const DEFAULT_PROFILE_DISPLAY_NAME := "Default v1"
const DEFAULT_PROFILE_DESCRIPTION := "Baseline parallax tuning for the first camera-gesture runtime slice."
const DEFAULT_DEBUG_TRACE_LEVEL := "basic"

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
const SUPPORTED_DEBUG_TRACE_LEVELS := [
	"off",
	"basic",
	"verbose",
]
const DEFAULT_PROFILE := {
	"version": PROFILE_SCHEMA_VERSION,
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
	"debug_trace_level": DEFAULT_DEBUG_TRACE_LEVEL,
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
var _active_profile_info := {
	"profile_id": DEFAULT_PROFILE_ID,
	"display_name": DEFAULT_PROFILE_DISPLAY_NAME,
	"description": DEFAULT_PROFILE_DESCRIPTION,
	"source_path": "",
	"source_format": "inline",
	"source_hash": "",
	"schema_id": PROFILE_SCHEMA_ID,
	"schema_version": PROFILE_SCHEMA_VERSION,
}

var _rest_position := Vector3.ZERO
var _rest_basis := Basis.IDENTITY
var _current_rotation := Vector3.ZERO
var _current_translation := Vector3.ZERO
var _target_rotation := Vector3.ZERO
var _target_translation := Vector3.ZERO
var _mouse_look_delta := Vector2.ZERO

func _ready() -> void:
	_ensure_active_profile_info_hash()
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
	var profile_document := _coerce_profile_document(profile)
	var serialized_document := _serialize_profile_document(profile_document, "yaml")
	_apply_profile_document(profile_document, "", "inline", serialized_document)

func get_profile() -> Dictionary:
	return _profile.duplicate(true)

func load_profile(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("CameraGestureController: failed to open profile for reading: %s" % path)
		return {}
	var file_text := file.get_as_text()
	var source_format := _detect_profile_format_from_path(path)
	var profile_document := _deserialize_profile_document(file_text, source_format)
	if profile_document.is_empty():
		push_error("CameraGestureController: failed to parse profile: %s" % path)
		return {}
	_last_profile_path = path
	_apply_profile_document(profile_document, path, source_format, file_text)
	var loaded_profile := get_profile()
	profile_loaded.emit(loaded_profile)
	return loaded_profile

func save_profile(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("CameraGestureController: failed to open profile for writing: %s" % path)
		return {}
	var source_format := _detect_profile_format_from_path(path)
	var profile_document := _build_profile_document(_profile, _active_profile_info)
	var serialized_document := _serialize_profile_document(profile_document, source_format)
	if serialized_document.is_empty():
		push_error("CameraGestureController: failed to serialize profile: %s" % path)
		return {}
	file.store_string(serialized_document)
	_last_profile_path = path
	_active_profile_info = _build_active_profile_info(profile_document, path, source_format, serialized_document)
	profile_saved.emit(path)
	return {
		"path": path,
		"format": source_format,
		"profile": get_profile(),
		"profile_document": profile_document,
		"active_profile": _active_profile_info.duplicate(true),
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
		"active_profile": _active_profile_info.duplicate(true),
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
	normalized["version"] = int(normalized.get("version", PROFILE_SCHEMA_VERSION))
	var mode := String(normalized.get("mode", CONTROL_MODE_GESTURE)).to_lower()
	if not VALID_CONTROL_MODES.has(mode):
		mode = CONTROL_MODE_GESTURE
	normalized["mode"] = mode
	var sample_source := String(normalized.get("sample_source", "head_position")).to_lower()
	if not SUPPORTED_SAMPLE_SOURCES.has(sample_source):
		sample_source = "head_position"
	normalized["sample_source"] = sample_source
	var debug_trace_level := String(normalized.get("debug_trace_level", DEFAULT_DEBUG_TRACE_LEVEL)).to_lower()
	if not SUPPORTED_DEBUG_TRACE_LEVELS.has(debug_trace_level):
		debug_trace_level = DEFAULT_DEBUG_TRACE_LEVEL
	normalized["debug_trace_level"] = debug_trace_level
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

func _coerce_profile_document(profile: Dictionary) -> Dictionary:
	if _looks_like_profile_document(profile):
		return _ensure_profile_document_shape(profile)
	return _build_profile_document_from_flat(profile)

func _looks_like_profile_document(profile: Dictionary) -> bool:
	return profile.has("schema") or profile.has("tracking") or profile.has("response") or profile.has("rotation") or profile.has("translation")

func _ensure_profile_document_shape(profile_document: Dictionary) -> Dictionary:
	var resolved_profile := _normalize_profile(_flatten_profile_document(profile_document))
	var metadata := _extract_profile_metadata_from_document(profile_document)
	return _build_profile_document(resolved_profile, metadata)

func _build_profile_document_from_flat(profile: Dictionary) -> Dictionary:
	var resolved_profile := _normalize_profile(profile)
	var metadata := {
		"profile_id": String(profile.get("profile_id", DEFAULT_PROFILE_ID)),
		"display_name": String(profile.get("display_name", DEFAULT_PROFILE_DISPLAY_NAME)),
		"description": String(profile.get("description", DEFAULT_PROFILE_DESCRIPTION)),
		"schema_id": String(profile.get("schema_id", PROFILE_SCHEMA_ID)),
		"schema_version": int(profile.get("schema_version", PROFILE_SCHEMA_VERSION)),
	}
	return _build_profile_document(resolved_profile, metadata)

func _build_profile_document(profile: Dictionary, metadata: Dictionary = {}) -> Dictionary:
	return {
		"schema": {
			"id": String(metadata.get("schema_id", PROFILE_SCHEMA_ID)),
			"version": int(metadata.get("schema_version", profile.get("version", PROFILE_SCHEMA_VERSION))),
		},
		"profile_id": String(metadata.get("profile_id", DEFAULT_PROFILE_ID)),
		"display_name": String(metadata.get("display_name", DEFAULT_PROFILE_DISPLAY_NAME)),
		"description": String(metadata.get("description", DEFAULT_PROFILE_DESCRIPTION)),
		"mode": String(profile.get("mode", CONTROL_MODE_GESTURE)),
		"tracking": {
			"sample_source": String(profile.get("sample_source", "head_position")),
			"confidence_threshold": float(profile.get("tracking_confidence_threshold", 0.45)),
			"freeze_on_tracking_loss": bool(profile.get("freeze_on_tracking_loss", true)),
		},
		"response": {
			"invert_x": bool(profile.get("invert_x", false)),
			"invert_y": bool(profile.get("invert_y", false)),
			"smoothing": float(profile.get("smoothing", 0.2)),
			"deadzone": float(profile.get("deadzone", 0.03)),
			"recenter_speed": float(profile.get("recenter_speed", 1.8)),
		},
		"rotation": {
			"look_sensitivity_x": float(profile.get("look_sensitivity_x", 1.0)),
			"look_sensitivity_y": float(profile.get("look_sensitivity_y", 1.0)),
			"max_yaw_degrees": float(profile.get("max_yaw_degrees", 20.0)),
			"max_pitch_degrees": float(profile.get("max_pitch_degrees", 12.0)),
			"max_roll_degrees": float(profile.get("max_roll_degrees", 4.0)),
		},
		"translation": {
			"sensitivity_x": float(profile.get("translation_sensitivity_x", 1.0)),
			"sensitivity_y": float(profile.get("translation_sensitivity_y", 0.6)),
			"sensitivity_z": float(profile.get("translation_sensitivity_z", 0.4)),
			"max_meters": profile.get("max_translation_meters", [0.6, 0.35, 0.45]).duplicate(true),
		},
		"debug": {
			"trace_level": String(profile.get("debug_trace_level", DEFAULT_DEBUG_TRACE_LEVEL)),
		},
	}

func _flatten_profile_document(profile_document: Dictionary) -> Dictionary:
	var schema: Dictionary = profile_document.get("schema", {}) if profile_document.get("schema", {}) is Dictionary else {}
	var tracking: Dictionary = profile_document.get("tracking", {}) if profile_document.get("tracking", {}) is Dictionary else {}
	var response: Dictionary = profile_document.get("response", {}) if profile_document.get("response", {}) is Dictionary else {}
	var rotation: Dictionary = profile_document.get("rotation", {}) if profile_document.get("rotation", {}) is Dictionary else {}
	var translation: Dictionary = profile_document.get("translation", {}) if profile_document.get("translation", {}) is Dictionary else {}
	var debug: Dictionary = profile_document.get("debug", {}) if profile_document.get("debug", {}) is Dictionary else {}
	return {
		"version": int(schema.get("version", profile_document.get("version", PROFILE_SCHEMA_VERSION))),
		"mode": String(profile_document.get("mode", CONTROL_MODE_GESTURE)),
		"invert_x": bool(response.get("invert_x", false)),
		"invert_y": bool(response.get("invert_y", false)),
		"look_sensitivity_x": float(rotation.get("look_sensitivity_x", 1.0)),
		"look_sensitivity_y": float(rotation.get("look_sensitivity_y", 1.0)),
		"translation_sensitivity_x": float(translation.get("sensitivity_x", 1.0)),
		"translation_sensitivity_y": float(translation.get("sensitivity_y", 0.6)),
		"translation_sensitivity_z": float(translation.get("sensitivity_z", 0.4)),
		"max_yaw_degrees": float(rotation.get("max_yaw_degrees", 20.0)),
		"max_pitch_degrees": float(rotation.get("max_pitch_degrees", 12.0)),
		"max_roll_degrees": float(rotation.get("max_roll_degrees", 4.0)),
		"max_translation_meters": translation.get("max_meters", [0.6, 0.35, 0.45]).duplicate(true) if translation.get("max_meters", [0.6, 0.35, 0.45]) is Array else [0.6, 0.35, 0.45],
		"smoothing": float(response.get("smoothing", 0.2)),
		"deadzone": float(response.get("deadzone", 0.03)),
		"recenter_speed": float(response.get("recenter_speed", 1.8)),
		"tracking_confidence_threshold": float(tracking.get("confidence_threshold", 0.45)),
		"freeze_on_tracking_loss": bool(tracking.get("freeze_on_tracking_loss", true)),
		"sample_source": String(tracking.get("sample_source", "head_position")),
		"debug_trace_level": String(debug.get("trace_level", DEFAULT_DEBUG_TRACE_LEVEL)),
	}

func _extract_profile_metadata_from_document(profile_document: Dictionary) -> Dictionary:
	var schema: Dictionary = profile_document.get("schema", {}) if profile_document.get("schema", {}) is Dictionary else {}
	return {
		"profile_id": String(profile_document.get("profile_id", DEFAULT_PROFILE_ID)),
		"display_name": String(profile_document.get("display_name", DEFAULT_PROFILE_DISPLAY_NAME)),
		"description": String(profile_document.get("description", DEFAULT_PROFILE_DESCRIPTION)),
		"schema_id": String(schema.get("id", PROFILE_SCHEMA_ID)),
		"schema_version": int(schema.get("version", PROFILE_SCHEMA_VERSION)),
	}

func _apply_profile_document(profile_document: Dictionary, source_path: String, source_format: String, source_text: String) -> void:
	var resolved_profile := _normalize_profile(_flatten_profile_document(profile_document))
	_profile = resolved_profile
	_enabled = true
	_last_profile_path = source_path
	_active_profile_info = _build_active_profile_info(profile_document, source_path, source_format, source_text)
	set_control_mode(String(_profile.get("mode", CONTROL_MODE_GESTURE)))
	_emit_tracking_state_if_changed(true)

func _build_active_profile_info(profile_document: Dictionary, source_path: String, source_format: String, source_text: String) -> Dictionary:
	var metadata := _extract_profile_metadata_from_document(profile_document)
	return {
		"profile_id": String(metadata.get("profile_id", DEFAULT_PROFILE_ID)),
		"display_name": String(metadata.get("display_name", DEFAULT_PROFILE_DISPLAY_NAME)),
		"description": String(metadata.get("description", DEFAULT_PROFILE_DESCRIPTION)),
		"source_path": source_path,
		"source_format": source_format,
		"source_hash": _hash_profile_text(source_text),
		"schema_id": String(metadata.get("schema_id", PROFILE_SCHEMA_ID)),
		"schema_version": int(metadata.get("schema_version", PROFILE_SCHEMA_VERSION)),
	}

func _ensure_active_profile_info_hash() -> void:
	if not String(_active_profile_info.get("source_hash", "")).is_empty():
		return
	var profile_document := _build_profile_document(_profile, _active_profile_info)
	var serialized_document := _serialize_profile_document(profile_document, "yaml")
	_active_profile_info = _build_active_profile_info(
		profile_document,
		String(_active_profile_info.get("source_path", "")),
		String(_active_profile_info.get("source_format", "inline")),
		serialized_document
	)

func _detect_profile_format_from_path(path: String) -> String:
	var normalized_path := path.to_lower()
	if normalized_path.ends_with(".yaml") or normalized_path.ends_with(".yml"):
		return "yaml"
	return "json"

func _deserialize_profile_document(text: String, source_format: String) -> Dictionary:
	match source_format:
		"yaml":
			var parsed_yaml := _parse_simple_yaml_document(text)
			if parsed_yaml.is_empty():
				return {}
			return _ensure_profile_document_shape(parsed_yaml)
		_:
			var parsed_json: Variant = JSON.parse_string(text)
			if not parsed_json is Dictionary:
				return {}
			var profile_dict: Dictionary = parsed_json
			if _looks_like_profile_document(profile_dict):
				return _ensure_profile_document_shape(profile_dict)
			return _build_profile_document_from_flat(profile_dict)

func _serialize_profile_document(profile_document: Dictionary, source_format: String) -> String:
	match source_format:
		"yaml":
			return _stringify_yaml_document(profile_document)
		_:
			return JSON.stringify(_normalize_profile(_flatten_profile_document(profile_document)), "\t")

func _parse_simple_yaml_document(text: String) -> Dictionary:
	var root := {}
	var stack := [{"indent": -1, "container": root}]
	for raw_line in text.split("\n"):
		var normalized_line := raw_line.replace("\t", "  ")
		var stripped_line := normalized_line.strip_edges()
		if stripped_line.is_empty() or stripped_line.begins_with("#"):
			continue
		var indent_count := normalized_line.length() - normalized_line.lstrip(" ").length()
		var content := normalized_line.substr(indent_count).strip_edges()
		var separator_index := content.find(":")
		if separator_index < 0:
			push_error("CameraGestureController: invalid YAML line: %s" % content)
			return {}
		var key := content.substr(0, separator_index).strip_edges()
		var raw_value := content.substr(separator_index + 1).strip_edges()
		while stack.size() > 0 and int(stack.back().get("indent", -1)) >= indent_count:
			stack.pop_back()
		if stack.is_empty():
			push_error("CameraGestureController: invalid YAML indentation")
			return {}
		var container: Dictionary = stack.back().get("container", {})
		if raw_value.is_empty():
			var child := {}
			container[key] = child
			stack.append({"indent": indent_count, "container": child})
		else:
			container[key] = _parse_yaml_scalar_or_inline_array(raw_value)
	return root

func _parse_yaml_scalar_or_inline_array(raw_value: String) -> Variant:
	var trimmed := raw_value.strip_edges()
	if trimmed.begins_with("[") and trimmed.ends_with("]"):
		var contents := trimmed.substr(1, trimmed.length() - 2).strip_edges()
		if contents.is_empty():
			return []
		var values: Array = []
		for part in contents.split(","):
			values.append(_parse_yaml_scalar_or_inline_array(String(part).strip_edges()))
		return values
	if (trimmed.begins_with('"') and trimmed.ends_with('"')) or (trimmed.begins_with("'") and trimmed.ends_with("'")):
		return trimmed.substr(1, max(trimmed.length() - 2, 0))
	match trimmed.to_lower():
		"true":
			return true
		"false":
			return false
		"null":
			return null
	if trimmed.is_valid_int():
		return int(trimmed)
	if trimmed.is_valid_float():
		return float(trimmed)
	return trimmed

func _stringify_yaml_document(profile_document: Dictionary) -> String:
	var schema: Dictionary = profile_document.get("schema", {}) if profile_document.get("schema", {}) is Dictionary else {}
	var tracking: Dictionary = profile_document.get("tracking", {}) if profile_document.get("tracking", {}) is Dictionary else {}
	var response: Dictionary = profile_document.get("response", {}) if profile_document.get("response", {}) is Dictionary else {}
	var rotation: Dictionary = profile_document.get("rotation", {}) if profile_document.get("rotation", {}) is Dictionary else {}
	var translation: Dictionary = profile_document.get("translation", {}) if profile_document.get("translation", {}) is Dictionary else {}
	var debug: Dictionary = profile_document.get("debug", {}) if profile_document.get("debug", {}) is Dictionary else {}
	var lines := [
		"schema:",
		"  id: %s" % _stringify_yaml_scalar(schema.get("id", PROFILE_SCHEMA_ID)),
		"  version: %s" % _stringify_yaml_scalar(int(schema.get("version", PROFILE_SCHEMA_VERSION))),
		"",
		"profile_id: %s" % _stringify_yaml_scalar(profile_document.get("profile_id", DEFAULT_PROFILE_ID)),
		"display_name: %s" % _stringify_yaml_scalar(profile_document.get("display_name", DEFAULT_PROFILE_DISPLAY_NAME)),
		"description: %s" % _stringify_yaml_scalar(profile_document.get("description", DEFAULT_PROFILE_DESCRIPTION)),
		"mode: %s" % _stringify_yaml_scalar(profile_document.get("mode", CONTROL_MODE_GESTURE)),
		"",
		"tracking:",
		"  sample_source: %s" % _stringify_yaml_scalar(tracking.get("sample_source", "head_position")),
		"  confidence_threshold: %s" % _stringify_yaml_scalar(float(tracking.get("confidence_threshold", 0.45))),
		"  freeze_on_tracking_loss: %s" % _stringify_yaml_scalar(bool(tracking.get("freeze_on_tracking_loss", true))),
		"",
		"response:",
		"  invert_x: %s" % _stringify_yaml_scalar(bool(response.get("invert_x", false))),
		"  invert_y: %s" % _stringify_yaml_scalar(bool(response.get("invert_y", false))),
		"  smoothing: %s" % _stringify_yaml_scalar(float(response.get("smoothing", 0.2))),
		"  deadzone: %s" % _stringify_yaml_scalar(float(response.get("deadzone", 0.03))),
		"  recenter_speed: %s" % _stringify_yaml_scalar(float(response.get("recenter_speed", 1.8))),
		"",
		"rotation:",
		"  look_sensitivity_x: %s" % _stringify_yaml_scalar(float(rotation.get("look_sensitivity_x", 1.0))),
		"  look_sensitivity_y: %s" % _stringify_yaml_scalar(float(rotation.get("look_sensitivity_y", 1.0))),
		"  max_yaw_degrees: %s" % _stringify_yaml_scalar(float(rotation.get("max_yaw_degrees", 20.0))),
		"  max_pitch_degrees: %s" % _stringify_yaml_scalar(float(rotation.get("max_pitch_degrees", 12.0))),
		"  max_roll_degrees: %s" % _stringify_yaml_scalar(float(rotation.get("max_roll_degrees", 4.0))),
		"",
		"translation:",
		"  sensitivity_x: %s" % _stringify_yaml_scalar(float(translation.get("sensitivity_x", 1.0))),
		"  sensitivity_y: %s" % _stringify_yaml_scalar(float(translation.get("sensitivity_y", 0.6))),
		"  sensitivity_z: %s" % _stringify_yaml_scalar(float(translation.get("sensitivity_z", 0.4))),
		"  max_meters: %s" % _stringify_yaml_scalar(translation.get("max_meters", [0.6, 0.35, 0.45])),
		"",
		"debug:",
		"  trace_level: %s" % _stringify_yaml_scalar(debug.get("trace_level", DEFAULT_DEBUG_TRACE_LEVEL)),
	]
	return "\n".join(lines) + "\n"

func _stringify_yaml_scalar(value: Variant) -> String:
	if value is Array:
		var parts: Array[String] = []
		for item in value:
			parts.append(_stringify_yaml_scalar(item))
		return "[%s]" % ", ".join(parts)
	if value is bool:
		return "true" if value else "false"
	if value == null:
		return "null"
	if value is int or value is float:
		return str(value)
	var text := String(value)
	if _yaml_needs_quotes(text):
		return '"%s"' % text.replace('"', '\\"')
	return text

func _yaml_needs_quotes(text: String) -> bool:
	if text.is_empty():
		return true
	for token in ["#", ":", ",", "[", "]", "{", "}", " "]:
		if text.contains(token):
			return true
	return false

func _hash_profile_text(source_text: String) -> String:
	var bytes := source_text.to_utf8_buffer()
	var hash_value: int = 2166136261
	for byte_value in bytes:
		hash_value = int(hash_value ^ int(byte_value))
		hash_value = int((hash_value * 16777619) & 0xffffffff)
	return "fnv1a32:%s" % _int_to_hex8(hash_value)

func _int_to_hex8(value: int) -> String:
	var digits := "0123456789abcdef"
	var remaining := value & 0xffffffff
	var result := ""
	for _index in range(8):
		var nibble := remaining & 0xf
		result = digits.substr(nibble, 1) + result
		remaining = remaining >> 4
	return result
