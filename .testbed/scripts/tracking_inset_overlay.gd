class_name CameraGestureTrackingInsetOverlay
extends Control

const MAX_TRAIL_POINTS := 24
const GRID_COLOR := Color(1.0, 1.0, 1.0, 0.10)
const CENTER_COLOR := Color(0.45, 0.85, 1.0, 0.28)
const ACTIVE_COLOR := Color(0.24, 0.90, 0.60, 0.92)
const INACTIVE_COLOR := Color(1.0, 0.45, 0.32, 0.85)
const TRAIL_COLOR := Color(0.46, 0.82, 1.0, 0.55)
const VELOCITY_COLOR := Color(1.0, 0.85, 0.32, 0.78)
const LANDMARK_COLOR := Color(0.0, 1.0, 0.5, 0.9)
const LANDMARK_COLOR_LOW_CONFIDENCE := Color(1.0, 0.5, 0.0, 0.7)
const SKELETON_COLOR := Color(0.0, 0.8, 1.0, 0.8)
const SKELETON_WIDTH := 2.0
const LANDMARK_RADIUS := 4.0
const POSITION_SENTINEL := Vector2(-1.0, -1.0)

const SKELETON_CONNECTIONS: Array = [
	[0, 1], [1, 2], [2, 3], [3, 7],
	[0, 4], [4, 5], [5, 6], [6, 8],
	[9, 10],
	[11, 12], [11, 23], [12, 24], [23, 24],
	[11, 13], [13, 15], [15, 17], [15, 19], [15, 21],
	[12, 14], [14, 16], [16, 18], [16, 20], [16, 22],
	[23, 25], [25, 27], [27, 29], [27, 31],
	[24, 26], [26, 28], [28, 30], [28, 32],
]

var _snapshot := {}
var _trail: Array[Vector2] = []
var _display_rect := Rect2()

func update_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	var normalized := _extract_normalized_position(_snapshot)
	if normalized != POSITION_SENTINEL:
		_trail.append(normalized)
		while _trail.size() > MAX_TRAIL_POINTS:
			_trail.remove_at(0)
	elif not bool(_snapshot.get("tracking", false)) and _trail.size() > 6:
		while _trail.size() > 6:
			_trail.remove_at(0)
	queue_redraw()

func set_display_rect(rect: Rect2) -> void:
	_display_rect = rect
	queue_redraw()

func clear_snapshot() -> void:
	_snapshot.clear()
	_trail.clear()
	queue_redraw()

func _draw() -> void:
	var rect := _effective_display_rect()
	draw_rect(rect, Color(0.02, 0.04, 0.07, 0.20), false, 1.0)
	_draw_guides(rect)
	_draw_confidence_bar(rect)
	_draw_pose_landmarks(rect)
	_draw_motion(rect)

func _effective_display_rect() -> Rect2:
	if _display_rect.size.x > 0.0 and _display_rect.size.y > 0.0:
		return _display_rect
	return Rect2(Vector2.ZERO, size)

func _draw_guides(rect: Rect2) -> void:
	var center := rect.get_center()
	draw_line(Vector2(rect.position.x, center.y), Vector2(rect.end.x, center.y), CENTER_COLOR, 1.5)
	draw_line(Vector2(center.x, rect.position.y), Vector2(center.x, rect.end.y), CENTER_COLOR, 1.5)
	for ratio in [0.25, 0.75]:
		var x := lerpf(rect.position.x, rect.end.x, ratio)
		var y := lerpf(rect.position.y, rect.end.y, ratio)
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), GRID_COLOR, 1.0)
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), GRID_COLOR, 1.0)

func _draw_confidence_bar(rect: Rect2) -> void:
	var confidence := clampf(float(_snapshot.get("confidence", 0.0)), 0.0, 1.0)
	var threshold := clampf(float(_snapshot.get("threshold", 0.0)), 0.0, 1.0)
	var bar_rect := Rect2(rect.position + Vector2(10.0, 10.0), Vector2(max(rect.size.x - 20.0, 20.0), 10.0))
	draw_rect(bar_rect, Color(1.0, 1.0, 1.0, 0.08), true)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * confidence, bar_rect.size.y)), ACTIVE_COLOR if confidence >= threshold else INACTIVE_COLOR, true)
	var threshold_x := bar_rect.position.x + bar_rect.size.x * threshold
	draw_line(Vector2(threshold_x, bar_rect.position.y - 2.0), Vector2(threshold_x, bar_rect.end.y + 2.0), Color.WHITE, 1.0)

func _draw_pose_landmarks(rect: Rect2) -> void:
	if _overlay_mode_from_snapshot() == "off":
		return
	var landmarks := _filtered_landmarks_for_display()
	if landmarks.is_empty():
		return
	_draw_pose_skeleton(rect, landmarks)
	for landmark: Dictionary in landmarks:
		var pos := _landmark_to_rect_point(rect, landmark)
		var visibility := float(landmark.get("v", 0.0))
		var color := LANDMARK_COLOR if visibility > 0.8 else LANDMARK_COLOR_LOW_CONFIDENCE
		draw_circle(pos, LANDMARK_RADIUS, color)
		draw_arc(pos, LANDMARK_RADIUS, 0.0, TAU, 16, Color.BLACK, 1.0)

func _draw_pose_skeleton(rect: Rect2, landmarks: Array) -> void:
	var landmark_dict := {}
	for landmark: Dictionary in landmarks:
		landmark_dict[int(landmark.get("id", -1))] = landmark
	for connection: Array in SKELETON_CONNECTIONS:
		var id1 := int(connection[0])
		var id2 := int(connection[1])
		if not landmark_dict.has(id1) or not landmark_dict.has(id2):
			continue
		var pos1 := _landmark_to_rect_point(rect, landmark_dict[id1])
		var pos2 := _landmark_to_rect_point(rect, landmark_dict[id2])
		draw_line(pos1, pos2, SKELETON_COLOR, SKELETON_WIDTH)

func _draw_motion(rect: Rect2) -> void:
	if _trail.size() >= 2:
		for index in range(_trail.size() - 1):
			var alpha := float(index + 1) / float(_trail.size())
			draw_line(_to_rect_point(rect, _trail[index]), _to_rect_point(rect, _trail[index + 1]), TRAIL_COLOR * Color(1.0, 1.0, 1.0, alpha), 2.0)

	var normalized := _extract_normalized_position(_snapshot)
	if normalized == POSITION_SENTINEL:
		return
	var point := _to_rect_point(rect, normalized)
	var active := bool(_snapshot.get("tracking", false))
	var color := ACTIVE_COLOR if active else INACTIVE_COLOR
	draw_circle(point, 7.0, color)
	draw_circle(point, 14.0, color * Color(1.0, 1.0, 1.0, 0.22))

	var velocity := _extract_velocity(_snapshot)
	if velocity.length() > 0.001:
		var arrow := point + Vector2(velocity.x, velocity.y) * rect.size * 0.12
		draw_line(point, arrow, VELOCITY_COLOR, 2.0)
		var direction := (arrow - point).normalized()
		var left := arrow - direction * 10.0 + Vector2(-direction.y, direction.x) * 5.0
		var right := arrow - direction * 10.0 + Vector2(direction.y, -direction.x) * 5.0
		draw_line(arrow, left, VELOCITY_COLOR, 2.0)
		draw_line(arrow, right, VELOCITY_COLOR, 2.0)

func _extract_normalized_position(snapshot: Dictionary) -> Vector2:
	var raw: Variant = snapshot.get("head_position", null)
	if raw is Vector3:
		var raw_position: Vector3 = raw
		return Vector2(clampf(raw_position.x, 0.0, 1.0), 1.0 - clampf(raw_position.y, 0.0, 1.0))
	if raw is Dictionary:
		return Vector2(clampf(float(raw.get("x", 0.5)), 0.0, 1.0), 1.0 - clampf(float(raw.get("y", 0.5)), 0.0, 1.0))
	return POSITION_SENTINEL

func _extract_velocity(snapshot: Dictionary) -> Vector2:
	var raw: Variant = snapshot.get("head_velocity", null)
	if raw is Vector3:
		var velocity: Vector3 = raw
		return Vector2(velocity.x, -velocity.y)
	if raw is Dictionary:
		return Vector2(float(raw.get("x", 0.0)), -float(raw.get("y", 0.0)))
	return Vector2.ZERO

func _overlay_mode_from_snapshot() -> String:
	return String(_snapshot.get("tracking_overlay_mode", "off")).strip_edges().to_lower()

func _filtered_landmarks_for_display() -> Array:
	var filtered: Array = []
	var min_visibility := clampf(float(_snapshot.get("tracking_min_visibility", 0.5)), 0.0, 1.0)
	var raw_landmarks: Array = _snapshot.get("pose_landmarks", []) if _snapshot.get("pose_landmarks", []) is Array else []
	for landmark_variant: Variant in raw_landmarks:
		if not landmark_variant is Dictionary:
			continue
		var landmark: Dictionary = landmark_variant
		var visibility := float(landmark.get("v", 0.0))
		if visibility < min_visibility:
			continue
		if not _landmark_is_in_bounds(landmark):
			continue
		filtered.append({
			"id": int(landmark.get("id", -1)),
			"x": float(landmark.get("x", 0.0)),
			"y": float(landmark.get("y", 0.0)),
			"v": visibility,
		})
	return filtered

func _landmark_is_in_bounds(landmark: Dictionary) -> bool:
	return float(landmark.get("x", -1.0)) >= 0.0 \
		and float(landmark.get("x", -1.0)) <= 1.0 \
		and float(landmark.get("y", -1.0)) >= 0.0 \
		and float(landmark.get("y", -1.0)) <= 1.0

func _landmark_to_rect_point(rect: Rect2, landmark: Dictionary) -> Vector2:
	return Vector2(
		rect.position.x + float(landmark.get("x", 0.0)) * rect.size.x,
		rect.position.y + (1.0 - float(landmark.get("y", 0.0))) * rect.size.y
	)

func _to_rect_point(rect: Rect2, normalized: Vector2) -> Vector2:
	return Vector2(
		lerpf(rect.position.x + 10.0, rect.end.x - 10.0, normalized.x),
		lerpf(rect.position.y + 24.0, rect.end.y - 10.0, normalized.y)
	)
