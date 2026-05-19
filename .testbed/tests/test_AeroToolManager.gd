extends GutTest

func test_tool_manager_creates_controller_and_bumps_repo_version() -> void:
	var manager := AeroToolManager.new()
	assert_eq(AeroToolManager.VERSION, "0.2.0", "Manager version should match the YAML profile slice")
	assert_eq(
		manager.get_default_camera_gesture_profile_path(),
		"res://assets/profiles/camera_gesture/default_v1.camera_gesture.yaml",
		"Manager should expose the checked-in default YAML profile path"
	)
	var controller := manager.create_camera_gesture_controller()
	assert_true(controller is CameraGestureController, "Manager should create the camera gesture controller")
	controller.free()
	manager.free()
