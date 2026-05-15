extends GutTest

func test_camera_gesture_testbed_scene_loads() -> void:
	var scene := load("res://scenes/camera_gesture_testbed.tscn")
	assert_true(scene != null, "Camera gesture testbed scene should be loadable")
