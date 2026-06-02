extends GutTest

const TESTBED_SCENE := preload("res://scenes/camera_gesture_testbed.tscn")

class FakeTrackingSession:
	extends Node

	signal tracking_updated(frame: Dictionary)
	signal state_changed(state: String, detail: Dictionary)
	signal preview_changed(descriptor: Dictionary)
	signal error_raised(error_info: Dictionary)

	var running := false
	var start_call_count := 0
	var change_call_count := 0
	var stop_call_count := 0
	var active_config := {}
	var preview_descriptor := {"backend": "fake", "attached": false}
	var state_detail := {
		"backend_ready": true,
		"preview_ready": true,
		"tracking_ready": true,
		"source_ready": true,
	}
	var tracking_frame := {
		"tracking_state": "tracked",
		"landmarks": [{"id": 0, "x": 0.52, "y": 0.44, "z": 0.0, "v": 0.92}],
	}

	func start(config: Dictionary) -> void:
		start_call_count += 1
		running = true
		active_config = config.duplicate(true)
		state_changed.emit("running", state_detail.duplicate(true))
		tracking_updated.emit(tracking_frame.duplicate(true))

	func change(config: Dictionary) -> void:
		change_call_count += 1
		running = true
		active_config = config.duplicate(true)
		state_changed.emit("running", state_detail.duplicate(true))
		tracking_updated.emit(tracking_frame.duplicate(true))

	func stop() -> void:
		stop_call_count += 1
		running = false
		state_changed.emit("idle", {
			"backend_ready": false,
			"preview_ready": false,
			"tracking_ready": false,
			"source_ready": false,
		})

	func detach_preview_surface() -> void:
		preview_descriptor["attached"] = false

	func attach_preview_surface(node: Node) -> void:
		preview_descriptor["attached"] = node != null
		preview_descriptor["surface_path"] = node.get_path() if node != null and node.is_inside_tree() else NodePath()

	func get_tracking_frame() -> Dictionary:
		return tracking_frame.duplicate(true)

	func get_state() -> Dictionary:
		return {"state": "running" if running else "idle", "detail": state_detail.duplicate(true)}

	func get_preview_descriptor() -> Dictionary:
		return preview_descriptor.duplicate(true)

	func get_active_config() -> Dictionary:
		return active_config.duplicate(true)

	func list_cameras() -> Array:
		return [{"id": "0", "label": "Default camera"}, {"id": "/dev/video2", "label": "Logitech"}]

	func is_running() -> bool:
		return running

func _instantiate_testbed() -> Control:
	var instance := TESTBED_SCENE.instantiate()
	add_child_autofree(instance)
	return instance

func test_live_and_replay_configs_flow_through_camera_tracking_boundary() -> void:
	var instance := _instantiate_testbed()
	var tracking := FakeTrackingSession.new()
	add_child_autofree(tracking)
	instance.set("_camera_tracking", tracking)
	instance.set("_source_mode", "mediapipe_live")
	await instance.call("_start_owned_mediapipe_runtime_async", 0, "mediapipe_live")
	assert_eq(tracking.start_call_count, 1, "Live mode should start the CameraTracking session")
	assert_eq(String(tracking.get_active_config().get("source", {}).get("kind", "")), "live_camera")
	assert_eq(String(tracking.get_active_config().get("preview", {}).get("surface_mode", "")), "attach")
	await instance.call("_start_owned_mediapipe_runtime_async", 0, "mediapipe_replay")
	assert_eq(tracking.change_call_count, 1, "Replay mode should reconfigure the same CameraTracking session")
	assert_eq(String(tracking.get_active_config().get("source", {}).get("kind", "")), "video_file")
	assert_eq(String(tracking.get_active_config().get("source", {}).get("path", "")), String((instance.get("_fixture_video_path_edit") as LineEdit).text))

func test_collect_provider_snapshot_reports_tracking_session_state_instead_of_provider_registry_state() -> void:
	var instance := _instantiate_testbed()
	var tracking := FakeTrackingSession.new()
	add_child_autofree(tracking)
	tracking.start({"source": {"kind": "live_camera", "camera_id": "0"}})
	instance.set("_camera_tracking", tracking)
	instance.set("_mediapipe_runtime_status", "ready")
	instance.set("_source_mode", "mediapipe_live")
	var snapshot: Dictionary = instance.call("_collect_provider_snapshot")
	assert_eq(String(snapshot.get("runtime_status", "")), "ready")
	assert_eq(String(snapshot.get("tracking_session_state", {}).get("state", "")), "running")
	assert_eq(String(snapshot.get("active_config", {}).get("source", {}).get("kind", "")), "live_camera")
	assert_false(snapshot.has("session_role"), "Tracking-boundary snapshot should no longer expose provider-session-registry role bookkeeping")
