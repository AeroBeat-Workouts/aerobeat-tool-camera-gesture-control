extends GutTest

func test_tool_manager_creates_controller_and_bumps_repo_version() -> void:
	var manager := AeroToolManager.new()
	assert_eq(AeroToolManager.VERSION, "0.1.0", "Manager version should match the first implementation lane")
	var controller := manager.create_camera_gesture_controller()
	assert_true(controller is CameraGestureController, "Manager should create the camera gesture controller")
	controller.free()
	manager.free()
