class_name CameraGestureTraceCaptureStore
extends RefCounted

const DEFAULT_SESSION_PREFIX := "camera_gesture_trace"
const DEFAULT_EXPORT_ROOT := "user://trace_exports/camera_gesture"
const MAX_CAPTURE_FRAMES := 7200

var _capturing := false
var _session_id := ""
var _capture_started_ms := 0
var _capture_started_unix := 0
var _capture_started_text := ""
var _capture_context := {}
var _frames: Array = []
var _notes: Array[String] = []
var _dropped_frames := 0
var _last_export := {}
var _last_summary := {}

func reset() -> void:
	_capturing = false
	_session_id = ""
	_capture_started_ms = 0
	_capture_started_unix = 0
	_capture_started_text = ""
	_capture_context = {}
	_frames.clear()
	_notes.clear()
	_dropped_frames = 0
	_last_summary = {}

func begin_capture(context: Dictionary = {}) -> Dictionary:
	reset()
	_capturing = true
	_capture_started_ms = Time.get_ticks_msec()
	_capture_started_unix = Time.get_unix_time_from_system()
	_capture_started_text = Time.get_datetime_string_from_system()
	_session_id = _build_session_id(str(context.get("session_prefix", DEFAULT_SESSION_PREFIX)))
	_capture_context = to_json_safe(context)
	append_note("capture_started")
	return get_status()

func append_note(message: String, extra: Dictionary = {}) -> void:
	var entry := {
		"elapsed_ms": _elapsed_ms(),
		"message": message,
		"extra": to_json_safe(extra),
	}
	_notes.append(JSON.stringify(entry))

func capture_frame(debug_state: Dictionary, source_snapshot: Dictionary = {}, provider_snapshot: Dictionary = {}, extra: Dictionary = {}) -> void:
	if not _capturing:
		return
	var frame := {
		"frame_index": _frames.size() + _dropped_frames + 1,
		"elapsed_ms": _elapsed_ms(),
		"debug_state": to_json_safe(debug_state),
		"source_snapshot": to_json_safe(source_snapshot),
		"provider_snapshot": to_json_safe(provider_snapshot),
		"extra": to_json_safe(extra),
	}
	_frames.append(frame)
	while _frames.size() > MAX_CAPTURE_FRAMES:
		_frames.remove_at(0)
		_dropped_frames += 1

func end_capture(extra_summary: Dictionary = {}) -> Dictionary:
	if not _capturing:
		return _last_summary.duplicate(true)
	_capturing = false
	append_note("capture_stopped", extra_summary)
	_last_summary = _build_summary(extra_summary)
	return _last_summary.duplicate(true)

func export_capture(export_root: String = DEFAULT_EXPORT_ROOT, extra_manifest: Dictionary = {}) -> Dictionary:
	if _session_id.is_empty():
		return {}
	var root_path := _normalize_dir_path(export_root)
	var absolute_root := _globalize_path(root_path)
	if absolute_root.is_empty():
		return {}
	var absolute_export_dir := absolute_root.path_join(_session_id)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute_export_dir)
	if dir_error != OK:
		push_error("TraceCaptureStore: failed to create export dir %s (%s)" % [absolute_export_dir, error_string(dir_error)])
		return {}

	var summary := _last_summary if not _last_summary.is_empty() else _build_summary()
	var manifest := {
		"session_id": _session_id,
		"started_at": _capture_started_text,
		"started_unix": _capture_started_unix,
		"duration_ms": int(summary.get("duration_ms", _elapsed_ms())),
		"capturing": _capturing,
		"frame_count": _frames.size(),
		"dropped_frames": _dropped_frames,
		"context": _capture_context.duplicate(true),
		"summary": summary.duplicate(true),
		"notes_count": _notes.size(),
		"paths": {
			"frames_jsonl": "frames.jsonl",
			"notes_jsonl": "notes.jsonl",
			"manifest_json": "manifest.json",
			"summary_md": "summary.md",
		},
	}
	for key in extra_manifest.keys():
		manifest[key] = to_json_safe(extra_manifest[key])

	var manifest_path := absolute_export_dir.path_join("manifest.json")
	var frames_path := absolute_export_dir.path_join("frames.jsonl")
	var notes_path := absolute_export_dir.path_join("notes.jsonl")
	var summary_path := absolute_export_dir.path_join("summary.md")

	if not _write_text_file(manifest_path, JSON.stringify(manifest, "\t") + "\n"):
		return {}
	if not _write_jsonl_file(frames_path, _frames):
		return {}
	if not _write_lines_file(notes_path, _notes):
		return {}
	if not _write_text_file(summary_path, _build_summary_markdown(summary, manifest)):
		return {}

	_last_export = {
		"session_id": _session_id,
		"export_root": root_path,
		"export_dir": absolute_export_dir,
		"manifest_path": manifest_path,
		"frames_path": frames_path,
		"notes_path": notes_path,
		"summary_path": summary_path,
		"summary": summary.duplicate(true),
	}
	return _last_export.duplicate(true)

func get_status() -> Dictionary:
	return {
		"capturing": _capturing,
		"session_id": _session_id,
		"frame_count": _frames.size(),
		"dropped_frames": _dropped_frames,
		"started_at": _capture_started_text,
		"duration_ms": _elapsed_ms(),
		"context": _capture_context.duplicate(true),
		"last_export": _last_export.duplicate(true),
		"last_summary": _last_summary.duplicate(true),
	}

func get_recent_frames(limit: int = 5) -> Array:
	var start_index := maxi(_frames.size() - max(limit, 0), 0)
	return _frames.slice(start_index, _frames.size()).duplicate(true)

func is_capturing() -> bool:
	return _capturing

func to_json_safe(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key_variant: Variant in value.keys():
			result[str(key_variant)] = to_json_safe(value[key_variant])
		return result
	if value is Array:
		var result_array: Array = []
		for item in value:
			result_array.append(to_json_safe(item))
		return result_array
	if value is Vector2:
		var v2: Vector2 = value
		return {"type": "Vector2", "x": v2.x, "y": v2.y}
	if value is Vector2i:
		var v2i: Vector2i = value
		return {"type": "Vector2i", "x": v2i.x, "y": v2i.y}
	if value is Vector3:
		var v3: Vector3 = value
		return {"type": "Vector3", "x": v3.x, "y": v3.y, "z": v3.z}
	if value is Vector3i:
		var v3i: Vector3i = value
		return {"type": "Vector3i", "x": v3i.x, "y": v3i.y, "z": v3i.z}
	if value is Vector4:
		var v4: Vector4 = value
		return {"type": "Vector4", "x": v4.x, "y": v4.y, "z": v4.z, "w": v4.w}
	if value is Quaternion:
		var q: Quaternion = value
		return {"type": "Quaternion", "x": q.x, "y": q.y, "z": q.z, "w": q.w}
	if value is Basis:
		var basis: Basis = value
		return {
			"type": "Basis",
			"x": to_json_safe(basis.x),
			"y": to_json_safe(basis.y),
			"z": to_json_safe(basis.z),
		}
	if value is Color:
		var color: Color = value
		return {"type": "Color", "r": color.r, "g": color.g, "b": color.b, "a": color.a}
	if value is NodePath:
		return str(value)
	if value is String or value is bool or value is int or value is float or value == null:
		return value
	return str(value)

func _build_summary(extra_summary: Dictionary = {}) -> Dictionary:
	var tracking_active_frames := 0
	var max_confidence := 0.0
	var max_translation_magnitude := 0.0
	var max_rotation_radians := 0.0
	var last_profile_id := ""
	var last_source_mode := str(_capture_context.get("source_mode", ""))
	for frame_variant: Variant in _frames:
		if not (frame_variant is Dictionary):
			continue
		var frame: Dictionary = frame_variant
		var debug_state: Dictionary = frame.get("debug_state", {}) if frame.get("debug_state", {}) is Dictionary else {}
		var tracking_state: Dictionary = debug_state.get("tracking_state", {}) if debug_state.get("tracking_state", {}) is Dictionary else {}
		var current_translation: Dictionary = debug_state.get("current_translation", {}) if debug_state.get("current_translation", {}) is Dictionary else {}
		var current_rotation: Dictionary = debug_state.get("current_rotation_radians", {}) if debug_state.get("current_rotation_radians", {}) is Dictionary else {}
		var active_profile: Dictionary = debug_state.get("active_profile", {}) if debug_state.get("active_profile", {}) is Dictionary else {}
		var source_snapshot: Dictionary = frame.get("source_snapshot", {}) if frame.get("source_snapshot", {}) is Dictionary else {}
		if bool(tracking_state.get("tracking", false)):
			tracking_active_frames += 1
		max_confidence = maxf(max_confidence, float(tracking_state.get("confidence", 0.0)))
		var translation_vector := _vector3_from_jsonish(current_translation)
		var rotation_vector := _vector3_from_jsonish(current_rotation)
		max_translation_magnitude = maxf(max_translation_magnitude, translation_vector.length())
		max_rotation_radians = maxf(max_rotation_radians, rotation_vector.length())
		last_profile_id = str(active_profile.get("profile_id", last_profile_id))
		last_source_mode = str(source_snapshot.get("source_mode", last_source_mode))
	var summary := {
		"duration_ms": _elapsed_ms(),
		"frame_count": _frames.size(),
		"dropped_frames": _dropped_frames,
		"tracking_active_frames": tracking_active_frames,
		"tracking_active_ratio": float(tracking_active_frames) / float(max(_frames.size(), 1)),
		"max_confidence": max_confidence,
		"max_translation_magnitude": max_translation_magnitude,
		"max_rotation_radians": max_rotation_radians,
		"profile_id": last_profile_id,
		"source_mode": last_source_mode,
	}
	for key in extra_summary.keys():
		summary[key] = to_json_safe(extra_summary[key])
	return summary

func _build_summary_markdown(summary: Dictionary, manifest: Dictionary) -> String:
	var lines := [
		"# Camera Gesture Trace Export",
		"",
		"- Session ID: `%s`" % str(manifest.get("session_id", "")),
		"- Started: `%s`" % str(manifest.get("started_at", "")),
		"- Duration ms: `%s`" % str(summary.get("duration_ms", 0)),
		"- Frames: `%s`" % str(summary.get("frame_count", 0)),
		"- Dropped frames: `%s`" % str(summary.get("dropped_frames", 0)),
		"- Tracking active ratio: `%s`" % str(summary.get("tracking_active_ratio", 0.0)),
		"- Max confidence: `%s`" % str(summary.get("max_confidence", 0.0)),
		"- Max translation magnitude: `%s`" % str(summary.get("max_translation_magnitude", 0.0)),
		"- Max rotation radians: `%s`" % str(summary.get("max_rotation_radians", 0.0)),
		"- Profile ID: `%s`" % str(summary.get("profile_id", "")),
		"- Source mode: `%s`" % str(summary.get("source_mode", "")),
		"",
		"## Context",
		"",
		"```json",
		JSON.stringify(manifest.get("context", {}), "\t"),
		"```",
	]
	return "\n".join(lines) + "\n"

func _vector3_from_jsonish(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Dictionary:
		return Vector3(
			float(value.get("x", 0.0)),
			float(value.get("y", 0.0)),
			float(value.get("z", 0.0))
		)
	return Vector3.ZERO

func _build_session_id(prefix: String) -> String:
	var safe_prefix := prefix.strip_edges().to_lower().replace(" ", "_")
	if safe_prefix.is_empty():
		safe_prefix = DEFAULT_SESSION_PREFIX
	return "%s_%d" % [safe_prefix, Time.get_ticks_msec()]

func _elapsed_ms() -> int:
	if _capture_started_ms <= 0:
		return 0
	return max(Time.get_ticks_msec() - _capture_started_ms, 0)

func _normalize_dir_path(path: String) -> String:
	var trimmed := path.strip_edges()
	if trimmed.is_empty():
		return DEFAULT_EXPORT_ROOT
	if trimmed.ends_with("/"):
		return trimmed.substr(0, trimmed.length() - 1)
	return trimmed

func _globalize_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	if path.begins_with("/"):
		return path
	return ProjectSettings.globalize_path("user://%s" % path)

func _write_text_file(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("TraceCaptureStore: failed to open file for writing: %s" % path)
		return false
	file.store_string(text)
	return true

func _write_jsonl_file(path: String, values: Array) -> bool:
	var lines: Array[String] = []
	for value in values:
		lines.append(JSON.stringify(value))
	return _write_lines_file(path, lines)

func _write_lines_file(path: String, lines: Array[String]) -> bool:
	return _write_text_file(path, "\n".join(lines) + ("\n" if not lines.is_empty() else ""))
