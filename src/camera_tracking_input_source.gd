class_name CameraTrackingInputSource
extends Node

const TRACKING_STATE_TRACKED: String = "tracked"
const TRACKING_STATE_REACQUIRING: String = "reacquiring"
const NOSE_LANDMARK_ID: int = 0

var _tracking_session: Node = null
var _last_tracking_frame: Dictionary = {}
var _last_tracking_signature: String = ""
var _tracking: bool = false
var _tracking_confidence: float = 0.0
var _head_position: Vector3 = Vector3.ZERO
var _head_velocity: Vector3 = Vector3.ZERO
var _head_rotation: Quaternion = Quaternion.IDENTITY
var _last_timestamp_ms: int = 0
var _last_source_kind: String = ""

func set_tracking_session(tracking_session: Node) -> bool:
	if tracking_session == null:
		return false
	if not _validate_tracking_session(tracking_session):
		return false
	if _tracking_session == tracking_session:
		_sync_from_tracking_session(true)
		return true
	_clear_tracking_session_connections()
	_tracking_session = tracking_session
	_connect_tracking_session()
	_sync_from_tracking_session(true)
	return true

func clear_tracking_session() -> void:
	_clear_tracking_session_connections()
	_tracking_session = null
	_reset_runtime_state()

func get_tracking_session() -> Node:
	return _tracking_session

func get_tracking_session_path() -> String:
	if _tracking_session == null or not is_instance_valid(_tracking_session):
		return ""
	return str(_tracking_session.get_path())

func is_tracking() -> bool:
	_sync_from_tracking_session()
	return _tracking

func get_head_position() -> Vector3:
	_sync_from_tracking_session()
	return _head_position

func get_head_velocity() -> Vector3:
	_sync_from_tracking_session()
	return _head_velocity

func get_head_rotation() -> Quaternion:
	_sync_from_tracking_session()
	return _head_rotation

func get_tracking_confidence(_feature: StringName = &"head") -> float:
	_sync_from_tracking_session()
	return _tracking_confidence

func get_debug_state() -> Dictionary:
	_sync_from_tracking_session()
	return {
		"tracking": _tracking,
		"confidence": _tracking_confidence,
		"head_position": _head_position,
		"head_velocity": _head_velocity,
		"head_rotation": _head_rotation,
		"source_kind": _last_source_kind,
		"tracking_session_path": get_tracking_session_path(),
		"tracking_frame": _last_tracking_frame.duplicate(true),
	}

func _exit_tree() -> void:
	clear_tracking_session()

func _validate_tracking_session(tracking_session: Node) -> bool:
	return tracking_session.has_method("get_tracking_frame") and tracking_session.has_method("get_state")

func _connect_tracking_session() -> void:
	if _tracking_session == null:
		return
	if _tracking_session.has_signal("tracking_updated") and not _tracking_session.tracking_updated.is_connected(_on_tracking_updated):
		_tracking_session.tracking_updated.connect(_on_tracking_updated)
	if _tracking_session.has_signal("state_changed") and not _tracking_session.state_changed.is_connected(_on_state_changed):
		_tracking_session.state_changed.connect(_on_state_changed)

func _clear_tracking_session_connections() -> void:
	if _tracking_session == null:
		return
	if _tracking_session.has_signal("tracking_updated") and _tracking_session.tracking_updated.is_connected(_on_tracking_updated):
		_tracking_session.tracking_updated.disconnect(_on_tracking_updated)
	if _tracking_session.has_signal("state_changed") and _tracking_session.state_changed.is_connected(_on_state_changed):
		_tracking_session.state_changed.disconnect(_on_state_changed)

func _sync_from_tracking_session(force: bool = false) -> void:
	if _tracking_session == null or not is_instance_valid(_tracking_session):
		_reset_runtime_state()
		return
	var frame_variant: Variant = _tracking_session.get_tracking_frame()
	if not frame_variant is Dictionary:
		if force:
			_reset_runtime_state()
		return
	var frame: Dictionary = frame_variant
	var signature: String = _build_tracking_frame_signature(frame)
	if not force and signature == _last_tracking_signature:
		return
	_last_tracking_signature = signature
	_last_tracking_frame = frame.duplicate(true)
	_apply_tracking_frame(frame)

func _build_tracking_frame_signature(frame: Dictionary) -> String:
	var raw_landmarks: Variant = frame.get("landmarks", [])
	var landmark_count: int = raw_landmarks.size() if raw_landmarks is Array else 0
	return "%s|%s|%s|%d|%s" % [
		str(frame.get("timestamp_ms", "")),
		str(frame.get("frame_index", "")),
		str(frame.get("tracking_state", "")),
		landmark_count,
		str(frame.get("source_id", "")),
	]

func _apply_tracking_frame(frame: Dictionary) -> void:
	var state_variant: Variant = _tracking_session.get_state() if _tracking_session != null and _tracking_session.has_method("get_state") else {}
	var state: Dictionary = state_variant if state_variant is Dictionary else {}
	var tracking_detail: Dictionary = state.get("detail", {}) if state.get("detail", {}) is Dictionary else {}
	var tracking_state: String = String(frame.get("tracking_state", "")).strip_edges().to_lower()
	var landmark: Dictionary = _find_head_landmark(frame)
	var has_head_landmark: bool = not landmark.is_empty()
	var tracking_active: bool = tracking_state == TRACKING_STATE_TRACKED or tracking_state == TRACKING_STATE_REACQUIRING
	if not tracking_active:
		tracking_active = bool(tracking_detail.get("tracking_ready", false)) and has_head_landmark
	_last_source_kind = String(frame.get("source_kind", "")).strip_edges().to_lower()
	_tracking = tracking_active and has_head_landmark
	_tracking_confidence = float(landmark.get("v", 0.0)) if has_head_landmark else 0.0
	_head_rotation = Quaternion.IDENTITY
	if not has_head_landmark:
		_head_velocity = Vector3.ZERO
		if not _tracking:
			_head_position = Vector3.ZERO
			_last_timestamp_ms = 0
		return
	var next_position: Vector3 = Vector3(
		float(landmark.get("x", 0.5)),
		float(landmark.get("y", 0.5)),
		float(landmark.get("z", 0.0))
	)
	var timestamp_ms: int = maxi(int(frame.get("timestamp_ms", 0)), 0)
	if _last_timestamp_ms > 0 and timestamp_ms > _last_timestamp_ms:
		var delta_seconds: float = float(timestamp_ms - _last_timestamp_ms) / 1000.0
		if delta_seconds > 0.0:
			_head_velocity = (next_position - _head_position) / delta_seconds
		else:
			_head_velocity = Vector3.ZERO
	else:
		_head_velocity = Vector3.ZERO
	_head_position = next_position
	_last_timestamp_ms = timestamp_ms

func _find_head_landmark(frame: Dictionary) -> Dictionary:
	var landmarks_variant: Variant = frame.get("landmarks", [])
	if not landmarks_variant is Array:
		return {}
	var best_landmark: Dictionary = {}
	var best_confidence: float = -1.0
	for landmark_variant: Variant in landmarks_variant:
		if not landmark_variant is Dictionary:
			continue
		var landmark: Dictionary = landmark_variant
		if int(landmark.get("id", -1)) == NOSE_LANDMARK_ID:
			return landmark.duplicate(true)
		var confidence: float = float(landmark.get("v", 0.0))
		if confidence > best_confidence:
			best_confidence = confidence
			best_landmark = landmark.duplicate(true)
	return best_landmark

func _reset_runtime_state() -> void:
	_last_tracking_frame = {}
	_last_tracking_signature = ""
	_tracking = false
	_tracking_confidence = 0.0
	_head_position = Vector3.ZERO
	_head_velocity = Vector3.ZERO
	_head_rotation = Quaternion.IDENTITY
	_last_timestamp_ms = 0
	_last_source_kind = ""

func _on_tracking_updated(frame: Dictionary) -> void:
	_last_tracking_signature = _build_tracking_frame_signature(frame)
	_last_tracking_frame = frame.duplicate(true)
	_apply_tracking_frame(frame)

func _on_state_changed(_state: String, _detail: Dictionary) -> void:
	_sync_from_tracking_session(true)
