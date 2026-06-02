extends GutTest

func test_camera_gesture_control_manager_creates_controller_and_tracking_helpers() -> void:
	var manager: Node = AeroCameraGestureControlManager.new()
	assert_eq(AeroCameraGestureControlManager.VERSION, "0.4.0", "Manager version should match the tracking-boundary slice")
	assert_eq(
		manager.get_default_camera_gesture_profile_path(),
		"res://assets/profiles/camera_gesture/default_v1.camera_gesture.yaml",
		"Manager should expose the checked-in default YAML profile path"
	)
	var controller: Node = manager.create_camera_gesture_controller()
	assert_not_null(controller, "Manager should create the camera gesture controller")
	assert_true(controller.has_method("attach_camera_tracking"), "Controller helper should expose the direct CameraTracking attachment seam")
	var tracking: Node = manager.create_camera_tracking()
	assert_not_null(tracking, "Manager should create the mounted CameraTracking service")
	assert_true(tracking.has_method("start"), "Tracking helper should expose the public CameraTracking lifecycle")
	var live_config: Dictionary = manager.build_live_camera_tracking_config("/dev/video7", {
		"tracking": {"overlay_mode": "optimized"},
	})
	assert_eq(live_config.get("backend"), "camera_tracking_default")
	assert_eq(live_config.get("source", {}).get("kind"), "live_camera")
	assert_eq(live_config.get("source", {}).get("camera_id"), "/dev/video7")
	assert_eq(live_config.get("tracking", {}).get("overlay_mode"), "optimized")
	var replay_config: Dictionary = manager.build_replay_camera_tracking_config("user://fixtures/replay.mp4")
	assert_eq(replay_config.get("source", {}).get("kind"), "video_file")
	assert_eq(replay_config.get("source", {}).get("path"), "user://fixtures/replay.mp4")
	controller.free()
	tracking.free()
	manager.free()
