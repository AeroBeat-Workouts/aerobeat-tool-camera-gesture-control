extends GutTest

const TRACE_STORE_SCRIPT := preload("res://scripts/trace_capture_store.gd")

class FakeBoundsCameraView:
	extends Control

	func _get_displayed_image_size() -> Vector2:
		return Vector2(320.0, 240.0)

	func _get_displayed_image_offset(_displayed_size: Vector2) -> Vector2:
		return Vector2(48.0, 12.0)

func _instantiate_testbed() -> Control:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	return instance

func test_camera_gesture_testbed_scene_loads() -> void:
	var scene := load("res://scenes/camera_gesture_testbed.tscn")
	assert_true(scene != null, "Camera gesture testbed scene should be loadable")

func test_camera_gesture_testbed_scene_builds_harness_nodes() -> void:
	var instance := _instantiate_testbed()
	var root_split := instance.get_node_or_null("RootMargin/RootSplit") as HSplitContainer
	assert_true(root_split != null, "Harness should build a root split layout")
	assert_eq(root_split.split_offset, 360, "Harness should keep the left panel readable without consuming the preview column")
	var media_inset := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel") as PanelContainer
	assert_true(media_inset != null, "Harness should expose the preview inset panel")
	assert_eq(media_inset.anchor_left, 1.0)
	assert_eq(media_inset.anchor_right, 1.0)
	assert_eq(media_inset.anchor_top, 1.0)
	assert_eq(media_inset.anchor_bottom, 1.0)
	assert_eq(media_inset.offset_right, -20.0)
	assert_eq(media_inset.offset_bottom, -20.0)
	assert_eq(media_inset.offset_left, -436.0)
	assert_eq(media_inset.offset_top, -316.0)
	var debug_tabs := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/DebugTabs") as TabContainer
	assert_true(debug_tabs != null, "Harness should expose richer debug tabs")
	assert_eq(debug_tabs.custom_minimum_size.y, 180.0)
	var preview_stack := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack") as Control
	assert_eq(preview_stack.custom_minimum_size, Vector2(640.0, 360.0))
	var viewport := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/WorldPreviewViewportContainer/WorldPreviewViewport") as SubViewport
	assert_eq(viewport.size, Vector2i(960, 540), "Harness viewport should use the rebuilt tracking-boundary proving size")
	var camera_feed_host := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/CameraFeedHost") as Control
	assert_true(camera_feed_host != null)
	assert_eq(camera_feed_host.custom_minimum_size.y, 236.0)
	var camera_view := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/CameraFeedHost/MediaPipeCameraView") as TextureRect
	assert_true(camera_view != null, "Harness should mount the CameraTracking preview surface")
	assert_eq(camera_view.expand_mode, TextureRect.EXPAND_IGNORE_SIZE)
	assert_eq(camera_view.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)

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
	assert_true(not result.is_empty())
	assert_true(FileAccess.file_exists(String(result.get("manifest_path", ""))))
	assert_true(FileAccess.file_exists(String(result.get("frames_path", ""))))

func test_camera_gesture_testbed_exposes_fake_live_and_replay_defaults() -> void:
	var instance := _instantiate_testbed()
	var source_option := instance.get("_source_option") as OptionButton
	assert_eq(source_option.item_count, 3)
	assert_eq(source_option.get_item_text(0), "fake")
	assert_eq(source_option.get_item_text(1), "mediapipe_live")
	assert_eq(source_option.get_item_text(2), "mediapipe_replay")
	var fixture_video_path_edit := instance.get("_fixture_video_path_edit") as LineEdit
	var fixture_sidecar_path_edit := instance.get("_fixture_sidecar_path_edit") as LineEdit
	assert_true(fixture_video_path_edit.text.contains("head_rotate_left_repeat_04_take_01.mp4"))
	assert_true(fixture_sidecar_path_edit.text.contains("head_rotate_left_repeat_04_take_01.fixture.yaml"))

func test_debug_tabs_toggle_hides_and_restores_diagnostics() -> void:
	var instance := _instantiate_testbed()
	var toggle := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/DebugToolbar/DebugTabsToggleButton") as Button
	var debug_tabs := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/DebugTabs") as TabContainer
	assert_true(debug_tabs.visible)
	toggle.button_pressed = false
	assert_false(debug_tabs.visible)
	assert_eq(toggle.text, "▸")
	toggle.button_pressed = true
	assert_true(debug_tabs.visible)
	assert_eq(toggle.text, "▾")

func test_media_toggle_collapses_and_restores_preview_surface() -> void:
	var instance := _instantiate_testbed()
	var toggle := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/MediaToolbar/MediaInsetToggleButton") as Button
	var media_inset := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel") as PanelContainer
	var camera_feed_host := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/CameraFeedHost") as Control
	assert_true(camera_feed_host.visible)
	toggle.button_pressed = false
	assert_false(camera_feed_host.visible)
	assert_eq(toggle.text, "▸")
	assert_eq(media_inset.offset_top, -72.0)
	toggle.button_pressed = true
	assert_true(camera_feed_host.visible)
	assert_eq(toggle.text, "▾")
	assert_eq(media_inset.offset_top, -316.0)

func test_mediapipe_runtime_settings_disable_horizontal_flip_for_replay() -> void:
	var instance := _instantiate_testbed()
	var replay_settings := JSON.parse_string(String(instance.call("_mediapipe_start_settings_json_for_mode", "mediapipe_replay"))) as Dictionary
	var live_settings := JSON.parse_string(String(instance.call("_mediapipe_start_settings_json_for_mode", "mediapipe_live"))) as Dictionary
	assert_eq(bool(replay_settings.get("flip_horizontal", true)), false)
	assert_eq(bool(live_settings.get("flip_horizontal", false)), true)

func test_live_camera_controls_stay_hidden_for_fake_mode_and_expose_tracking_defaults() -> void:
	var instance := _instantiate_testbed()
	var live_camera_row := instance.get("_mediapipe_live_camera_row") as VBoxContainer
	var tracking_quality_row := instance.get("_mediapipe_tracking_quality_row") as VBoxContainer
	var tracking_quality_option := instance.get("_mediapipe_tracking_quality_option") as OptionButton
	assert_false(live_camera_row.visible)
	assert_false(tracking_quality_row.visible)
	assert_eq(tracking_quality_option.item_count, 3)
	assert_eq(tracking_quality_option.get_item_text(0), "none")
	assert_eq(tracking_quality_option.get_item_text(1), "optimized")
	assert_eq(tracking_quality_option.get_item_text(2), "full")
	assert_eq(String(instance.get("_selected_mediapipe_tracking_quality")), "full")

func test_mediapipe_runtime_settings_include_live_camera_and_tracking_quality_tuning() -> void:
	var instance := _instantiate_testbed()
	instance.set("_selected_mediapipe_live_camera_id", "/dev/video2")
	instance.set("_selected_mediapipe_tracking_quality", "optimized")
	var live_settings := JSON.parse_string(String(instance.call("_mediapipe_start_settings_json_for_mode", "mediapipe_live"))) as Dictionary
	assert_eq(String(live_settings.get("selected_camera_device_id", "")), "/dev/video2")
	assert_eq(String(live_settings.get("tracking_overlay_mode", "")), "optimized")
	assert_eq(int(live_settings.get("gesture_eval_interval_frames", 0)), 1)
	assert_almost_eq(float(live_settings.get("min_visibility", 0.0)), 0.35, 0.001)

func test_camera_view_overlay_is_disabled_for_tracking_preview_surface() -> void:
	var instance := _instantiate_testbed()
	var camera_view = instance.get("_mediapipe_camera_view")
	assert_true(camera_view != null)
	assert_false(bool(camera_view.show_overlay))

func test_tracking_overlay_display_rect_uses_displayed_image_bounds() -> void:
	var instance := _instantiate_testbed()
	await get_tree().process_frame
	var camera_view := FakeBoundsCameraView.new()
	add_child_autofree(camera_view)
	instance.set("_mediapipe_camera_view", camera_view)
	var rect: Rect2 = instance.call("_current_tracking_overlay_display_rect")
	assert_eq(rect.position, Vector2(48.0, 12.0))
	assert_eq(rect.size, Vector2(320.0, 240.0))

func test_overlay_normalization_flips_provider_y_and_velocity_for_gameplay_space() -> void:
	var overlay_script := load("res://scripts/tracking_inset_overlay.gd")
	var overlay = add_child_autofree(overlay_script.new())
	var position: Vector2 = overlay.call("_extract_normalized_position", {"head_position": Vector3(0.25, 0.20, 0.0)})
	var velocity: Vector2 = overlay.call("_extract_velocity", {"head_velocity": Vector3(0.10, 0.30, 0.0)})
	assert_eq(position, Vector2(0.25, 0.80))
	assert_eq(velocity, Vector2(0.10, -0.30))

func test_overlay_filters_and_projects_provider_landmarks_for_visible_pose_dots() -> void:
	var overlay_script := load("res://scripts/tracking_inset_overlay.gd")
	var overlay = add_child_autofree(overlay_script.new())
	overlay.call("update_snapshot", {
		"tracking_overlay_mode": "optimized",
		"tracking_min_visibility": 0.35,
		"pose_landmarks": [
			{"id": 0, "x": 0.25, "y": 0.20, "v": 0.90},
			{"id": 1, "x": 0.75, "y": 0.60, "v": 0.20},
			{"id": 2, "x": 1.20, "y": 0.40, "v": 0.95},
		],
	})
	var landmarks: Array = overlay.call("_filtered_landmarks_for_display")
	assert_eq(landmarks.size(), 1)
	var rect := Rect2(Vector2(48.0, 12.0), Vector2(320.0, 240.0))
	var projected: Vector2 = overlay.call("_landmark_to_rect_point", rect, landmarks[0])
	assert_eq(projected, Vector2(128.0, 204.0))

func test_collect_source_snapshot_carries_pose_overlay_payload_for_live_and_disables_it_for_fake() -> void:
	var instance := _instantiate_testbed()
	instance.set("_source_mode", "mediapipe_live")
	instance.set("_selected_mediapipe_tracking_quality", "optimized")
	instance.set("_latest_tracking_frame", {"landmarks": [{"id": 0, "x": 0.4, "y": 0.3, "v": 0.8}]})
	instance.set("_latest_tracking_state", {"tracking": true})
	var live_snapshot: Dictionary = instance.call("_collect_source_snapshot")
	assert_eq(String(live_snapshot.get("tracking_overlay_mode", "")), "optimized")
	assert_eq(int((live_snapshot.get("pose_landmarks", []) as Array).size()), 1)
	instance.set("_source_mode", "fake")
	var fake_snapshot: Dictionary = instance.call("_collect_source_snapshot")
	assert_eq(String(fake_snapshot.get("tracking_overlay_mode", "")), "off")

func test_server_started_signal_marks_runtime_stabilizing() -> void:
	var instance := _instantiate_testbed()
	instance.call("_on_mediapipe_server_started", 123)
	assert_eq(String(instance.get("_mediapipe_runtime_status")), "stabilizing")
