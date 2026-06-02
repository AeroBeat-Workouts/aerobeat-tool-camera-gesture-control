extends GutTest

const CONTROLLER_SCRIPT: Script = preload("res://addons/aerobeat-tool-camera-gesture-control/src/camera_gesture_controller.gd")
const FAKE_INPUT_SOURCE_SCRIPT: Script = preload("res://scripts/fake_camera_input_source.gd")
const CAMERA_TRACKING_SCRIPT: Script = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTracking.gd")
const CAMERA_TRACKING_FAKE_BACKEND_SCRIPT: Script = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTrackingFakeBackend.gd")
const PROFILE_PATH := "user://test_camera_gesture_profile.camera_gesture.yaml"
const LEGACY_JSON_PROFILE_PATH := "user://test_camera_gesture_profile_legacy.json"
const DEFAULT_PROFILE_REPO_PATH := "../assets/profiles/camera_gesture/default_v1.camera_gesture.yaml"

func _make_controller() -> Node:
	var controller: Node = CONTROLLER_SCRIPT.new()
	add_child_autofree(controller)
	return controller

func _make_camera() -> Camera3D:
	var camera: Camera3D = Camera3D.new()
	add_child_autofree(camera)
	return camera

func _make_source() -> FakeCameraInputSource:
	var source: FakeCameraInputSource = FAKE_INPUT_SOURCE_SCRIPT.new()
	source.animate = false
	add_child_autofree(source)
	return source

func _make_tracking_session(frame_overrides: Dictionary = {}) -> Node:
	var tracker: Node = CAMERA_TRACKING_SCRIPT.new()
	var backend = CAMERA_TRACKING_FAKE_BACKEND_SCRIPT.new()
	add_child_autofree(tracker)
	tracker.set_backend(backend, "fake")
	tracker.start({
		"source": {
			"kind": "live_camera",
			"camera_id": "/dev/video0",
		},
	})
	if not frame_overrides.is_empty():
		var frame: Dictionary = tracker.get_tracking_frame()
		for key_variant: Variant in frame_overrides.keys():
			frame[key_variant] = frame_overrides[key_variant]
		backend.emit_tracking_frame(frame)
	return tracker

func test_profile_defaults_keep_locked_schema() -> void:
	var controller: Node = _make_controller()
	var profile: Dictionary = controller.get_profile()
	assert_eq(profile.get("version"), 1)
	assert_eq(profile.get("mode"), "gesture")
	assert_true(profile.has("invert_x"))
	assert_true(profile.has("look_sensitivity_x"))
	assert_true(profile.has("max_translation_meters"))
	assert_true(profile.has("freeze_on_tracking_loss"))
	assert_true(profile.has("sample_source"))
	assert_eq(profile.get("debug_trace_level"), "basic")

func test_attach_input_source_requires_provider_like_surface() -> void:
	var controller: Node = _make_controller()
	var invalid_source: Node = Node.new()
	add_child_autofree(invalid_source)
	assert_false(controller.attach_input_source(invalid_source), "Random nodes should not satisfy the controller boundary")

func test_mode_switching_and_profile_application_stay_in_sync() -> void:
	var controller: Node = _make_controller()
	controller.apply_profile({
		"mode": "mouse_wasd",
		"look_sensitivity_x": 1.8,
		"sample_source": "head_velocity",
		"debug_trace_level": "verbose",
	})
	assert_eq(controller.get_profile().get("mode"), "mouse_wasd")
	assert_eq(controller.get_profile().get("sample_source"), "head_velocity")
	assert_eq(controller.get_profile().get("debug_trace_level"), "verbose")
	controller.set_control_mode("disabled")
	assert_eq(controller.get_profile().get("mode"), "disabled")

func test_attach_camera_tracking_consumes_camera_tracking_boundary() -> void:
	var controller: Node = _make_controller()
	var tracker: Node = _make_tracking_session({
		"timestamp_ms": 100,
		"tracking_state": "tracked",
		"source_kind": "live_camera",
		"source_id": "/dev/video0",
		"landmarks": [{"id": 0, "x": 0.9, "y": 0.2, "z": 0.1, "v": 0.95}],
	})
	var camera: Camera3D = _make_camera()
	controller.attach_camera(camera)
	assert_true(controller.attach_camera_tracking(tracker), "Controller should accept the public CameraTracking service directly")
	controller.apply_profile({
		"mode": "gesture",
		"smoothing": 0.0,
	})
	controller._process(0.1)
	var debug_state: Dictionary = controller.get_debug_state()
	assert_true(bool(debug_state.get("camera_tracking_attached", false)), "Debug state should expose the CameraTracking boundary attachment")
	assert_ne(String(debug_state.get("camera_tracking_session_path", "")), "", "Debug state should expose the attached CameraTracking node path")
	var tracking_state: Dictionary = debug_state.get("tracking_state", {})
	assert_true(bool(tracking_state.get("tracking", false)), "Tracking should stay active when the CameraTracking frame is tracked")
	assert_almost_eq(float(tracking_state.get("confidence", 0.0)), 0.95, 0.001, "Tracking confidence should flow from CameraTracking landmark visibility")
	var translation: Vector3 = debug_state.get("current_translation", Vector3.ZERO)
	assert_ne(translation, Vector3.INF, "Debug translation should remain readable after CameraTracking attachment")

func test_tracking_state_reflects_confidence_threshold() -> void:
	var controller: Node = _make_controller()
	var source: FakeCameraInputSource = _make_source()
	var camera: Camera3D = _make_camera()
	source.head_position = Vector3(0.9, 0.1, 0.0)
	source.confidence = 0.2
	controller.attach_camera(camera)
	assert_true(controller.attach_input_source(source))
	controller.apply_profile({
		"mode": "gesture",
		"tracking_confidence_threshold": 0.5,
		"freeze_on_tracking_loss": false,
	})
	controller._process(0.1)
	var state: Dictionary = controller.get_debug_state().get("tracking_state", {})
	assert_false(state.get("tracking", true), "Tracking should stay inactive below the confidence threshold")
	source.confidence = 0.9
	controller._process(0.1)
	state = controller.get_debug_state().get("tracking_state", {})
	assert_true(state.get("tracking", false), "Tracking should activate once confidence clears the threshold")

func test_attach_camera_and_gesture_profile_move_camera_with_clamps() -> void:
	var controller: Node = _make_controller()
	var source: FakeCameraInputSource = _make_source()
	var camera: Camera3D = _make_camera()
	source.head_position = Vector3(1.0, 0.0, 1.0)
	controller.attach_camera(camera)
	controller.attach_input_source(source)
	controller.apply_profile({
		"mode": "gesture",
		"smoothing": 0.0,
		"max_translation_meters": [0.1, 0.1, 0.1],
		"max_yaw_degrees": 5.0,
		"max_pitch_degrees": 5.0,
		"max_roll_degrees": 2.0,
	})
	controller._process(0.1)
	var debug_state: Dictionary = controller.get_debug_state()
	var translation: Vector3 = debug_state.get("current_translation", Vector3.ZERO)
	assert_almost_eq(translation.x, 0.1, 0.001, "Translation X should clamp to the profile maximum")
	assert_almost_eq(absf(translation.y), 0.1, 0.001, "Translation Y should clamp to the profile maximum")

func test_detach_camera_restores_rest_transform() -> void:
	var controller: Node = _make_controller()
	var source: FakeCameraInputSource = _make_source()
	var camera: Camera3D = _make_camera()
	camera.position = Vector3(1.0, 2.0, 3.0)
	camera.basis = Basis.from_euler(Vector3(0.1, 0.2, 0.3))
	var rest_position: Vector3 = camera.position
	var rest_basis: Basis = camera.basis
	source.head_position = Vector3(1.0, 0.0, 0.8)
	controller.attach_camera(camera)
	controller.attach_input_source(source)
	controller.apply_profile({
		"mode": "gesture",
		"smoothing": 0.0,
	})
	controller._process(0.1)
	assert_ne(camera.position, rest_position, "Gesture processing should move the camera before detach")
	controller.detach_camera()
	assert_eq(camera.position, rest_position, "Detaching should restore the original camera position")
	assert_eq(camera.basis, rest_basis, "Detaching should restore the original camera basis")

func test_head_rotation_sample_source_falls_back_to_head_position_when_provider_reports_identity_rotation() -> void:
	var controller: Node = _make_controller()
	var source: FakeCameraInputSource = _make_source()
	var camera: Camera3D = _make_camera()
	source.head_position = Vector3(0.85, 0.2, 0.0)
	source.head_rotation = Quaternion.IDENTITY
	controller.attach_camera(camera)
	controller.attach_input_source(source)
	controller.apply_profile({
		"mode": "gesture",
		"sample_source": "head_rotation",
		"smoothing": 0.0,
		"max_yaw_degrees": 20.0,
		"max_pitch_degrees": 12.0,
	})
	controller._process(0.1)
	var debug_state: Dictionary = controller.get_debug_state()
	var rotation: Vector3 = debug_state.get("current_rotation_radians", Vector3.ZERO)
	assert_true(absf(rotation.y) > 0.001 or absf(rotation.x) > 0.001, "Identity head-rotation data should fall back to head-position-derived rotation so replay clips still move the camera")
	var translation: Vector3 = debug_state.get("current_translation", Vector3.ZERO)
	assert_eq(translation, Vector3.ZERO, "Head-rotation fallback should not introduce translation")

func test_load_checked_in_default_yaml_profile_and_expose_profile_metadata() -> void:
	var controller: Node = _make_controller()
	var profile_path: String = ProjectSettings.globalize_path("res://%s" % DEFAULT_PROFILE_REPO_PATH)
	assert_true(FileAccess.file_exists(profile_path), "Checked-in YAML profile should exist")
	var loaded: Dictionary = controller.load_profile(profile_path)
	assert_eq(loaded.get("mode"), "gesture")
	assert_eq(loaded.get("sample_source"), "head_position")
	var active_profile: Dictionary = controller.get_debug_state().get("active_profile", {})
	assert_eq(active_profile.get("profile_id"), "default_v1")
	assert_eq(active_profile.get("source_path"), profile_path)
	assert_eq(active_profile.get("source_format"), "yaml")
	assert_eq(active_profile.get("schema_id"), "camera_gesture_profile")
	assert_eq(active_profile.get("schema_version"), 1)
	assert_true(String(active_profile.get("source_hash", "")).begins_with("fnv1a32:"), "Active profile hash should be exposed for traceability")

func test_profile_round_trip_save_and_load_yaml() -> void:
	var controller: Node = _make_controller()
	controller.apply_profile({
		"mode": "mouse_wasd",
		"invert_x": true,
		"tracking_confidence_threshold": 0.72,
		"debug_trace_level": "verbose",
	})
	var save_result: Dictionary = controller.save_profile(PROFILE_PATH)
	assert_eq(save_result.get("path"), PROFILE_PATH)
	assert_eq(save_result.get("format"), "yaml")
	var reloaded: Dictionary = controller.load_profile(PROFILE_PATH)
	assert_eq(reloaded.get("mode"), "mouse_wasd")
	assert_true(reloaded.get("invert_x"))
	assert_almost_eq(float(reloaded.get("tracking_confidence_threshold", 0.0)), 0.72, 0.001)
	assert_eq(reloaded.get("debug_trace_level"), "verbose")
	var active_profile: Dictionary = controller.get_debug_state().get("active_profile", {})
	assert_eq(active_profile.get("source_format"), "yaml")
	assert_eq(active_profile.get("schema_id"), "camera_gesture_profile")

func test_legacy_json_profile_round_trip_still_works() -> void:
	var controller: Node = _make_controller()
	controller.apply_profile({
		"mode": "mouse_wasd",
		"invert_y": true,
		"tracking_confidence_threshold": 0.61,
	})
	var save_result: Dictionary = controller.save_profile(LEGACY_JSON_PROFILE_PATH)
	assert_eq(save_result.get("format"), "json")
	var reloaded: Dictionary = controller.load_profile(LEGACY_JSON_PROFILE_PATH)
	assert_eq(reloaded.get("mode"), "mouse_wasd")
	assert_true(reloaded.get("invert_y"))
	assert_almost_eq(float(reloaded.get("tracking_confidence_threshold", 0.0)), 0.61, 0.001)
	var active_profile: Dictionary = controller.get_debug_state().get("active_profile", {})
	assert_eq(active_profile.get("source_format"), "json")
	assert_eq(active_profile.get("schema_id"), "camera_gesture_profile")
