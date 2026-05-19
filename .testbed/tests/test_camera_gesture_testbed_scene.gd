extends GutTest

const TRACE_STORE_SCRIPT := preload("res://scripts/trace_capture_store.gd")

func test_camera_gesture_testbed_scene_loads() -> void:
	var scene := load("res://scenes/camera_gesture_testbed.tscn")
	assert_true(scene != null, "Camera gesture testbed scene should be loadable")

func test_camera_gesture_testbed_scene_builds_harness_nodes() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	assert_true(instance.get_node_or_null("RootSplit") != null, "Harness should build a root split layout")
	assert_true(instance.get_node_or_null("RootSplit/RightColumn/PreviewPanel") != null, "Harness should expose the right preview panel")
	assert_true(instance.get_node_or_null("RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel") != null, "Harness should expose the bottom-left media inset")
	assert_true(instance.get_node_or_null("RootSplit/RightColumn/DebugTabs") != null, "Harness should expose richer debug tabs")
	var viewport := instance.get_node_or_null("RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/WorldPreviewViewportContainer/WorldPreviewViewport") as SubViewport
	assert_true(viewport != null, "Harness should create the world preview viewport")
	assert_eq(viewport.size, Vector2i(1280, 720), "Harness viewport should stay 16:9 ready")

func test_trace_capture_store_exports_manifest_and_frames() -> void:
	var store: CameraGestureTraceCaptureStore = TRACE_STORE_SCRIPT.new()
	store.begin_capture({"session_prefix": "gut_trace_test", "fixture_key": "test/head_pose"})
	store.capture_frame(
		{
			"tracking_state": {"tracking": true, "confidence": 0.82},
			"active_profile": {"profile_id": "default_v1"},
			"current_translation": Vector3(0.1, 0.0, 0.0),
			"current_rotation_radians": Vector3(0.0, 0.1, 0.0),
		},
		{"source_mode": "fake", "head_position": Vector3(0.5, 0.5, 0.0)},
		{"provider_mode": "fake"},
		{"note": "gut export"}
	)
	store.end_capture({"reason": "gut_test"})
	var export_root := "user://gut_trace_capture_exports"
	var result := store.export_capture(export_root, {"test": true})
	assert_true(not result.is_empty(), "Trace capture store should export a payload")
	assert_true(FileAccess.file_exists(String(result.get("manifest_path", ""))), "Trace export should write a manifest")
	assert_true(FileAccess.file_exists(String(result.get("frames_path", ""))), "Trace export should write frame JSONL")
	var manifest_file := FileAccess.open(String(result.get("manifest_path", "")), FileAccess.READ)
	assert_true(manifest_file != null, "Manifest file should be readable")
	var manifest_text := manifest_file.get_as_text()
	assert_true(manifest_text.contains("gut_trace_test"), "Manifest should include the session prefix")

func test_fixture_scaffold_readme_exists() -> void:
	var fixture_readme_path := ProjectSettings.globalize_path("res://assets/fixtures/camera_gesture/README.md")
	assert_true(FileAccess.file_exists(fixture_readme_path), "Fixture scaffold README should exist")
	var file := FileAccess.open(fixture_readme_path, FileAccess.READ)
	assert_true(file != null, "Fixture scaffold README should open")
	var text := file.get_as_text()
	assert_true(text.contains("same-basename video + sidecar pairs"), "Fixture scaffold README should describe the intended pair layout")
