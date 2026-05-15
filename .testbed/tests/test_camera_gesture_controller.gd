extends GutTest

const CONTROLLER_SCRIPT := preload("res://src/camera_gesture_controller.gd")
const FAKE_INPUT_SOURCE_SCRIPT := preload("res://scripts/fake_camera_input_source.gd")
const PROFILE_PATH := "user://test_camera_gesture_profile.json"

func _make_controller() -> CameraGestureController:
	var controller: CameraGestureController = CONTROLLER_SCRIPT.new()
	add_child_autofree(controller)
	return controller

func _make_camera() -> Camera3D:
	var camera := Camera3D.new()
	add_child_autofree(camera)
	return camera

func _make_source() -> FakeCameraInputSource:
	var source: FakeCameraInputSource = FAKE_INPUT_SOURCE_SCRIPT.new()
	source.animate = false
	add_child_autofree(source)
	return source

func test_profile_defaults_keep_locked_schema() -> void:
	var controller := _make_controller()
	var profile := controller.get_profile()
	assert_eq(profile.get("version"), 1)
	assert_eq(profile.get("mode"), "gesture")
	assert_true(profile.has("invert_x"))
	assert_true(profile.has("look_sensitivity_x"))
	assert_true(profile.has("max_translation_meters"))
	assert_true(profile.has("freeze_on_tracking_loss"))
	assert_true(profile.has("sample_source"))

func test_attach_input_source_requires_provider_like_surface() -> void:
	var controller := _make_controller()
	var invalid_source := Node.new()
	add_child_autofree(invalid_source)
	assert_false(controller.attach_input_source(invalid_source), "Random nodes should not satisfy the controller boundary")

func test_mode_switching_and_profile_application_stay_in_sync() -> void:
	var controller := _make_controller()
	controller.apply_profile({
		"mode": "mouse_wasd",
		"look_sensitivity_x": 1.8,
		"sample_source": "head_velocity",
	})
	assert_eq(controller.get_profile().get("mode"), "mouse_wasd")
	assert_eq(controller.get_profile().get("sample_source"), "head_velocity")
	controller.set_control_mode("disabled")
	assert_eq(controller.get_profile().get("mode"), "disabled")

func test_tracking_state_reflects_confidence_threshold() -> void:
	var controller := _make_controller()
	var source := _make_source()
	var camera := _make_camera()
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
	var controller := _make_controller()
	var source := _make_source()
	var camera := _make_camera()
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
	var debug_state := controller.get_debug_state()
	var translation: Vector3 = debug_state.get("current_translation", Vector3.ZERO)
	assert_almost_eq(translation.x, 0.1, 0.001, "Translation X should clamp to the profile maximum")
	assert_almost_eq(absf(translation.y), 0.1, 0.001, "Translation Y should clamp to the profile maximum")

func test_profile_round_trip_save_and_load() -> void:
	var controller := _make_controller()
	controller.apply_profile({
		"mode": "mouse_wasd",
		"invert_x": true,
		"tracking_confidence_threshold": 0.72,
	})
	var save_result := controller.save_profile(PROFILE_PATH)
	assert_eq(save_result.get("path"), PROFILE_PATH)
	var reloaded := controller.load_profile(PROFILE_PATH)
	assert_eq(reloaded.get("mode"), "mouse_wasd")
	assert_true(reloaded.get("invert_x"))
	assert_almost_eq(float(reloaded.get("tracking_confidence_threshold", 0.0)), 0.72, 0.001)
