extends GutTest

const TRACE_STORE_SCRIPT := preload("res://scripts/trace_capture_store.gd")

class FakeCameraView:
	extends Control

	var start_stream_call_count := 0

	func start_stream() -> bool:
		start_stream_call_count += 1
		return true

func test_camera_gesture_testbed_scene_loads() -> void:
	var scene := load("res://scenes/camera_gesture_testbed.tscn")
	assert_true(scene != null, "Camera gesture testbed scene should be loadable")

func test_camera_gesture_testbed_scene_builds_harness_nodes() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	var root_split := instance.get_node_or_null("RootSplit") as HSplitContainer
	assert_true(root_split != null, "Harness should build a root split layout")
	assert_eq(root_split.split_offset, 520, "Harness should widen the left panel for readability")
	assert_true(instance.get_node_or_null("RootSplit/RightColumn/PreviewPanel") != null, "Harness should expose the right preview panel")
	assert_true(instance.get_node_or_null("RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel") != null, "Harness should expose the bottom-left media inset")
	assert_true(instance.get_node_or_null("RootSplit/RightColumn/DebugTabs") != null, "Harness should expose richer debug tabs")
	var left_scroll := instance.get_node_or_null("RootSplit/LeftPanelScroll") as ScrollContainer
	assert_true(left_scroll != null, "Harness should expose the left panel scroll container")
	assert_eq(left_scroll.custom_minimum_size.x, 500.0, "Left panel minimum width should grow with the larger text")
	var left_panel := instance.get_node_or_null("RootSplit/LeftPanelScroll/LeftPanel") as VBoxContainer
	assert_true(left_panel != null, "Harness should expose the left panel container")
	var title := left_panel.get_child(0) as Label
	assert_true(title != null, "Harness should expose the scene title label")
	assert_eq(title.get_theme_font_size("font_size"), 30, "Scene title should use the larger readability font")
	var viewport := instance.get_node_or_null("RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/WorldPreviewViewportContainer/WorldPreviewViewport") as SubViewport
	assert_true(viewport != null, "Harness should create the world preview viewport")
	assert_eq(viewport.size, Vector2i(1920, 1080), "Harness viewport should target AeroBeat's default 1920x1080 surface")

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

func test_camera_gesture_testbed_exposes_split_source_modes_and_real_fixture_defaults() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	var source_option := instance.get("_source_option") as OptionButton
	assert_eq(source_option.item_count, 3, "Testbed should expose fake, live, and replay source modes")
	assert_eq(source_option.get_item_text(0), "fake")
	assert_eq(source_option.get_item_text(1), "mediapipe_live")
	assert_eq(source_option.get_item_text(2), "mediapipe_replay")
	var fixture_video_path_edit := instance.get("_fixture_video_path_edit") as LineEdit
	var fixture_sidecar_path_edit := instance.get("_fixture_sidecar_path_edit") as LineEdit
	assert_true(fixture_video_path_edit.text.contains("head_rotate_left_repeat_04_take_01.mp4"), "Fixture default should point at a checked-in candidate video")
	assert_true(fixture_sidecar_path_edit.text.contains("head_rotate_left_repeat_04_take_01.fixture.yaml"), "Fixture default should point at a checked-in candidate sidecar")

func test_server_started_signal_does_not_start_camera_stream_before_stabilization_finishes() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	var camera_view := FakeCameraView.new()
	camera_view.name = "FakeCameraView"
	add_child_autofree(camera_view)
	instance.set("_mediapipe_camera_view", camera_view)
	instance.set("_source_mode", "mediapipe_replay")

	instance.call("_on_mediapipe_server_started", 123)
	await get_tree().process_frame

	assert_eq(String(instance.get("_mediapipe_runtime_status")), "stabilizing", "Server-started signal should mark replay as stabilizing, not ready")
	assert_eq(camera_view.start_stream_call_count, 0, "Server-started signal should not eagerly start the camera stream before stabilization completes")
