extends GutTest

const TRACE_STORE_SCRIPT := preload("res://scripts/trace_capture_store.gd")

class FakeCameraView:
	extends TextureRect

	var stream_url := "http://127.0.0.1:4243/camera"
	var start_stream_call_count := 0
	var overlay_updates: Array = []
	var _streaming := false

	func start_stream() -> bool:
		start_stream_call_count += 1
		_streaming = true
		return true

	func is_streaming() -> bool:
		return _streaming

	func stop_stream() -> void:
		_streaming = false

	func update_overlay(landmarks: Array) -> void:
		overlay_updates.append(landmarks.duplicate(true))

	func _get_displayed_image_size() -> Vector2:
		return size if size.x > 0.0 and size.y > 0.0 else Vector2(640.0, 480.0)

	func _get_displayed_image_offset(_displayed_size: Vector2) -> Vector2:
		return Vector2.ZERO

class FakeBoundsCameraView:
	extends Control

	func _get_displayed_image_size() -> Vector2:
		return Vector2(320.0, 240.0)

	func _get_displayed_image_offset(_displayed_size: Vector2) -> Vector2:
		return Vector2(48.0, 12.0)

class FakeAutoStartManager:
	extends Node

	var camera_source_override := ""
	var tracking_overlay_mode := "full"
	var restart_server_call_count := 0
	var restart_server_last_override := ""
	var server_running := true

	func restart_server(new_camera_source_override: String = "") -> bool:
		restart_server_call_count += 1
		restart_server_last_override = new_camera_source_override
		camera_source_override = new_camera_source_override
		server_running = true
		return true

	func is_server_running() -> bool:
		return server_running

class FakeFallbackAutoStartManager:
	extends Node

	var camera_source_override := ""
	var tracking_overlay_mode := "full"
	var stop_server_call_count := 0
	var start_server_call_count := 0
	var server_running := true

	func stop_server() -> void:
		stop_server_call_count += 1
		server_running = false

	func start_server() -> bool:
		start_server_call_count += 1
		server_running = true
		return true

	func is_server_running() -> bool:
		return server_running

class FakeSelectableInputSource:
	extends Node

	var selected_camera_device_id := ""
	var set_selected_camera_device_id_call_count := 0
	var stop_call_count := 0

	func is_tracking() -> bool:
		return true

	func get_head_position() -> Vector3:
		return Vector3(0.5, 0.5, 0.0)

	func get_tracking_confidence(_joint := &"head") -> float:
		return 1.0

	func set_selected_camera_device_id(device_id: String) -> bool:
		set_selected_camera_device_id_call_count += 1
		selected_camera_device_id = device_id
		return true

	func stop() -> void:
		stop_call_count += 1

func test_camera_gesture_testbed_scene_loads() -> void:
	var scene := load("res://scenes/camera_gesture_testbed.tscn")
	assert_true(scene != null, "Camera gesture testbed scene should be loadable")

func test_camera_gesture_testbed_scene_builds_harness_nodes() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	var root_split := instance.get_node_or_null("RootMargin/RootSplit") as HSplitContainer
	assert_true(root_split != null, "Harness should build a root split layout")
	assert_eq(root_split.split_offset, 360, "Harness should keep the left panel readable without consuming the preview column")
	assert_true(instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel") != null, "Harness should expose the right preview panel")
	var media_inset := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel") as PanelContainer
	assert_true(media_inset != null, "Harness should expose the preview inset panel")
	var media_toggle := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/MediaToolbar/MediaInsetToggleButton") as Button
	assert_true(media_toggle != null, "Harness should expose a matching minimize/restore control for the media preview")
	assert_eq(media_toggle.text, "▾", "Media preview should default to the expanded icon state")
	assert_eq(media_inset.anchor_left, 1.0, "Preview inset should stay anchored to the bottom-right corner for live/replay comparison")
	assert_eq(media_inset.anchor_right, 1.0, "Preview inset should stay anchored to the bottom-right corner for live/replay comparison")
	assert_eq(media_inset.anchor_top, 1.0, "Preview inset should stay anchored to the bottom-right corner for live/replay comparison")
	assert_eq(media_inset.anchor_bottom, 1.0, "Preview inset should stay anchored to the bottom-right corner for live/replay comparison")
	assert_eq(media_inset.offset_right, -20.0, "Preview inset should keep a visible right margin from the preview edge")
	assert_eq(media_inset.offset_bottom, -20.0, "Preview inset should keep a visible bottom margin from the preview edge")
	assert_eq(media_inset.offset_left, -436.0, "Preview inset should reserve a substantially larger width for replay/live dot comparison")
	assert_eq(media_inset.offset_top, -316.0, "Preview inset should reserve a substantially larger height for replay/live dot comparison")
	var debug_toolbar := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/DebugToolbar") as HBoxContainer
	assert_true(debug_toolbar != null, "Harness should expose a dedicated debug toolbar for collapsing the tab area")
	var debug_tabs_toggle := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/DebugToolbar/DebugTabsToggleButton") as Button
	assert_true(debug_tabs_toggle != null, "Harness should expose a clear hide/show control for the debug tabs")
	assert_eq(debug_tabs_toggle.text, "▾", "Debug toolbar should default to the expanded icon state")
	var debug_tabs := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/DebugTabs") as TabContainer
	assert_true(debug_tabs != null, "Harness should expose richer debug tabs")
	assert_eq(debug_tabs.custom_minimum_size.y, 180.0, "Debug tabs should leave more vertical room for the world preview")
	var runtime_margin := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/DebugTabs/Runtime/RuntimeMargin") as MarginContainer
	assert_true(runtime_margin != null, "Runtime tab should wrap the debug surface in a scene-authored margin container")
	assert_eq(runtime_margin.get_theme_constant("margin_left"), 12, "Debug tab margins should match the left-panel section inset")
	assert_eq(runtime_margin.get_theme_constant("margin_top"), 10, "Debug tab margins should match the left-panel section inset")
	assert_eq(runtime_margin.get_theme_constant("margin_right"), 12, "Debug tab margins should match the left-panel section inset")
	assert_eq(runtime_margin.get_theme_constant("margin_bottom"), 12, "Debug tab margins should match the left-panel section inset")
	var left_scroll := instance.get_node_or_null("RootMargin/RootSplit/LeftPanelScroll") as ScrollContainer
	assert_true(left_scroll != null, "Harness should expose the left panel scroll container")
	assert_eq(left_scroll.custom_minimum_size.x, 340.0, "Left panel minimum width should stay readable without forcing controls off-screen")
	var left_panel := instance.get_node_or_null("RootMargin/RootSplit/LeftPanelScroll/LeftPanel") as VBoxContainer
	assert_true(left_panel != null, "Harness should expose the left panel container")
	var title := instance.get_node_or_null("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/HeaderPanel/HeaderMargin/HeaderColumn/TitleLabel") as Label
	assert_true(title != null, "Harness should expose the scene title label")
	assert_eq(title.get_theme_font_size("font_size"), 26, "Scene title should use the larger readability font")
	var preview_stack := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack") as Control
	assert_true(preview_stack != null, "Harness should expose the preview stack root")
	assert_eq(preview_stack.custom_minimum_size, Vector2(640.0, 360.0), "Preview stack should preserve a readable world surface without demanding full-HD layout space")
	var viewport := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/WorldPreviewViewportContainer/WorldPreviewViewport") as SubViewport
	assert_true(viewport != null, "Harness should create the world preview viewport")
	assert_eq(viewport.size, Vector2i(640, 360), "Harness viewport should follow the responsive preview frame so the world surface stays visible inside the rebuilt layout")
	var camera_feed_host := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/CameraFeedHost") as Control
	assert_true(camera_feed_host != null, "Harness should expose the media preview host")
	assert_eq(camera_feed_host.custom_minimum_size.y, 236.0, "Media preview host should be large enough to compare the feed against the tracking dots comfortably")
	var camera_view := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/CameraFeedHost/MediaPipeCameraView") as TextureRect
	assert_true(camera_view != null, "Harness should mount the MediaPipe camera view when the addon is present")
	assert_eq(camera_view.expand_mode, TextureRect.EXPAND_IGNORE_SIZE, "Media preview should fill its host instead of collapsing to texture-native sizing")
	assert_eq(camera_view.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "Media preview should keep the source visible instead of cropping unpredictably")

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

func test_debug_tabs_toggle_hides_and_restores_diagnostics() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	var toggle := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/DebugToolbar/DebugTabsToggleButton") as Button
	var debug_tabs := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/DebugTabs") as TabContainer
	assert_true(toggle != null, "Harness should expose the debug-tabs toggle button")
	assert_true(debug_tabs != null, "Harness should expose the debug tabs")
	assert_true(debug_tabs.visible, "Debug tabs should start visible for diagnosis")

	toggle.button_pressed = false
	assert_false(debug_tabs.visible, "Turning the debug toggle off should collapse the debug tabs")
	assert_eq(toggle.text, "▸", "Collapsed debug state should advertise restore with the matching icon treatment")

	toggle.button_pressed = true
	assert_true(debug_tabs.visible, "Turning the debug toggle back on should restore the debug tabs")
	assert_eq(toggle.text, "▾", "Expanded debug state should advertise collapse with the matching icon treatment")

func test_media_toggle_collapses_and_restores_preview_surface() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	var toggle := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/MediaToolbar/MediaInsetToggleButton") as Button
	var media_inset := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel") as PanelContainer
	var camera_feed_host := instance.get_node_or_null("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/CameraFeedHost") as Control
	assert_true(toggle != null, "Harness should expose the media preview toggle button")
	assert_true(media_inset != null, "Harness should expose the media inset panel")
	assert_true(camera_feed_host != null, "Harness should expose the media preview host")
	assert_true(camera_feed_host.visible, "Media preview should start expanded for diagnosis")

	toggle.button_pressed = false
	assert_false(camera_feed_host.visible, "Turning the media toggle off should collapse the preview surface")
	assert_eq(toggle.text, "▸", "Collapsed media preview should advertise restore with the matching icon treatment")
	assert_eq(media_inset.offset_top, -72.0, "Collapsed media preview should shrink to a compact title-bar footprint while staying anchored")

	toggle.button_pressed = true
	assert_true(camera_feed_host.visible, "Turning the media toggle back on should restore the preview surface")
	assert_eq(toggle.text, "▾", "Expanded media preview should advertise collapse with the matching icon treatment")
	assert_eq(media_inset.offset_top, -316.0, "Expanded media preview should restore the larger diagnostic surface")

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

func test_mediapipe_runtime_settings_disable_horizontal_flip_for_replay() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	var replay_settings := JSON.parse_string(String(instance.call("_mediapipe_start_settings_json_for_mode", "mediapipe_replay"))) as Dictionary
	var live_settings := JSON.parse_string(String(instance.call("_mediapipe_start_settings_json_for_mode", "mediapipe_live"))) as Dictionary
	assert_eq(bool(replay_settings.get("flip_horizontal", true)), false, "Replay runtime should not mirror provider landmarks against prerecorded video")
	assert_eq(bool(live_settings.get("flip_horizontal", false)), true, "Live runtime should preserve mirrored camera behavior")

func test_live_mediapipe_controls_stay_hidden_for_fake_mode_and_expose_parity_defaults() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	var live_camera_row := instance.get("_mediapipe_live_camera_row") as VBoxContainer
	var tracking_quality_row := instance.get("_mediapipe_tracking_quality_row") as VBoxContainer
	var tracking_quality_option := instance.get("_mediapipe_tracking_quality_option") as OptionButton
	assert_true(live_camera_row != null, "Testbed should create a dedicated live-camera picker row")
	assert_true(tracking_quality_row != null, "Testbed should create a dedicated tracking-quality row")
	assert_false(live_camera_row.visible, "Live-only camera picker should stay hidden while fake mode is active")
	assert_false(tracking_quality_row.visible, "Live-only tracking quality should stay hidden while fake mode is active")
	assert_eq(tracking_quality_option.item_count, 3, "Tracking quality should expose the three proving-flow parity options")
	assert_eq(tracking_quality_option.get_item_text(0), "none")
	assert_eq(tracking_quality_option.get_item_text(1), "optimized")
	assert_eq(tracking_quality_option.get_item_text(2), "full")
	assert_eq(String(instance.get("_selected_mediapipe_tracking_quality")), "full")

func test_mediapipe_runtime_settings_include_live_camera_and_tracking_quality_tuning() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	instance.set("_selected_mediapipe_live_camera_id", "/dev/video2")
	instance.set("_selected_mediapipe_tracking_quality", "optimized")
	var live_settings := JSON.parse_string(String(instance.call("_mediapipe_start_settings_json_for_mode", "mediapipe_live"))) as Dictionary
	assert_eq(String(live_settings.get("selected_camera_device_id", "")), "/dev/video2", "Live runtime should forward the selected camera device to the provider")
	assert_eq(String(live_settings.get("tracking_overlay_mode", "")), "optimized", "Live runtime should forward the effective overlay mode")
	assert_eq(int(live_settings.get("gesture_eval_interval_frames", 0)), 1, "Parity pass should keep the proving-flow gesture cadence truthful by default")
	assert_almost_eq(float(live_settings.get("min_visibility", 0.0)), 0.35, 0.001, "Live runtime should forward the proving-flow min-visibility default")

func test_camera_view_overlay_is_disabled_for_provider_normalized_landmarks() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	var camera_view = instance.get("_mediapipe_camera_view")
	assert_true(camera_view != null, "Harness should create a MediaPipe camera view when the addon seam exists")
	assert_false(bool(camera_view.show_overlay), "Camera view built-in overlay should stay disabled because the harness uses provider-normalized gameplay-space landmarks")

func test_tracking_overlay_display_rect_uses_displayed_image_bounds() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	await get_tree().process_frame
	var camera_view := FakeBoundsCameraView.new()
	add_child_autofree(camera_view)
	instance.set("_mediapipe_camera_view", camera_view)
	var rect: Rect2 = instance.call("_current_tracking_overlay_display_rect")
	assert_eq(rect.position, Vector2(48.0, 12.0), "Tracking inset should draw inside the actual displayed-image offset, not the full host rect")
	assert_eq(rect.size, Vector2(320.0, 240.0), "Tracking inset should draw inside the actual displayed-image bounds, not the full host rect")

func test_overlay_normalization_flips_provider_y_and_velocity_for_gameplay_space() -> void:
	var overlay_script := load("res://scripts/tracking_inset_overlay.gd")
	var overlay = add_child_autofree(overlay_script.new())
	var position: Vector2 = overlay.call("_extract_normalized_position", {"head_position": Vector3(0.25, 0.20, 0.0)})
	var velocity: Vector2 = overlay.call("_extract_velocity", {"head_velocity": Vector3(0.10, 0.30, 0.0)})
	assert_eq(position, Vector2(0.25, 0.80), "Overlay should convert provider-normalized gameplay Y into top-left UI space with 1.0 - y")
	assert_eq(velocity, Vector2(0.10, -0.30), "Overlay velocity should use the same Y convention as the converted gameplay-space position")

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
	assert_eq(landmarks.size(), 1, "Overlay should keep only in-bounds landmarks that meet the visibility threshold")
	var rect := Rect2(Vector2(48.0, 12.0), Vector2(320.0, 240.0))
	var projected: Vector2 = overlay.call("_landmark_to_rect_point", rect, landmarks[0])
	assert_eq(projected, Vector2(128.0, 204.0), "Overlay should map provider-normalized gameplay landmarks into the displayed-image rect without double-mirroring")

func test_collect_source_snapshot_carries_pose_overlay_payload_for_live_and_disables_it_for_fake() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	instance.set("_source_mode", "mediapipe_live")
	instance.set("_selected_mediapipe_tracking_quality", "optimized")
	instance.set("_latest_pose_landmarks", [{"id": 0, "x": 0.4, "y": 0.3, "v": 0.8}])
	var live_snapshot: Dictionary = instance.call("_collect_source_snapshot")
	assert_eq(String(live_snapshot.get("tracking_overlay_mode", "")), "optimized", "Live snapshot should tell the inset overlay to render the selected donor-style tracking mode")
	assert_eq(int((live_snapshot.get("pose_landmarks", []) as Array).size()), 1, "Live snapshot should include the latest normalized pose landmarks for visible overlay rendering")
	instance.set("_source_mode", "fake")
	var fake_snapshot: Dictionary = instance.call("_collect_source_snapshot")
	assert_eq(String(fake_snapshot.get("tracking_overlay_mode", "")), "off", "Fake snapshot should not request donor-style landmark overlay rendering")

func test_live_camera_runtime_restart_uses_restart_server_and_waits_for_stream_ready() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	var manager := FakeAutoStartManager.new()
	add_child_autofree(manager)
	var existing_camera_view = instance.get("_mediapipe_camera_view")
	if existing_camera_view != null and is_instance_valid(existing_camera_view):
		existing_camera_view.queue_free()
		await get_tree().process_frame
	var camera_view := FakeCameraView.new()
	var camera_feed_host := instance.get("_camera_feed_host") as Control
	camera_feed_host.add_child(camera_view)
	camera_feed_host.move_child(camera_view, 0)
	instance.set("_mediapipe_autostart_manager", manager)
	instance.set("_mediapipe_camera_view", camera_view)
	var input_source := FakeSelectableInputSource.new()
	add_child_autofree(input_source)
	instance.set("_mediapipe_input_source", input_source)
	instance.set("_source_mode", "mediapipe_live")
	instance.set("_selected_mediapipe_live_camera_id", "/dev/video7")
	instance.set("_selected_mediapipe_tracking_quality", "optimized")
	instance.set("_mediapipe_runtime_signature", "mediapipe_live|0|full|1")
	await instance.call("_start_owned_mediapipe_runtime_async", 0, "mediapipe_live")
	assert_eq(manager.restart_server_call_count, 1, "Live camera switch should route through restart_server when the active runtime signature changes")
	assert_eq(manager.restart_server_last_override, "/dev/video7", "Live camera switch should restart the owned runtime with the newly selected camera override")
	assert_eq(input_source.set_selected_camera_device_id_call_count, 1, "Live camera switch should also push the chosen device into the active input source before restart")
	assert_eq(String(input_source.selected_camera_device_id), "/dev/video7", "Live camera switch should keep the active input source aligned with the chosen camera")
	var rebuilt_camera_view = instance.get("_mediapipe_camera_view") as FakeCameraView
	assert_false(rebuilt_camera_view == camera_view, "Live camera switch should rebuild the preview widget instead of reusing stale view state")
	assert_eq(rebuilt_camera_view.start_stream_call_count, 1, "Owned runtime restart should wait for the rebuilt preview stream to be started again before declaring readiness")
	assert_eq(camera_view.start_stream_call_count, 0, "Old preview widget should be replaced rather than restarted in place")
	assert_eq(String(instance.get("_mediapipe_runtime_status")), "ready", "Owned runtime restart should only report ready after the restart choreography finishes")

func test_live_camera_runtime_restart_falls_back_to_stop_start_and_preserves_camera_override() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	var manager := FakeFallbackAutoStartManager.new()
	add_child_autofree(manager)
	var existing_camera_view = instance.get("_mediapipe_camera_view")
	if existing_camera_view != null and is_instance_valid(existing_camera_view):
		existing_camera_view.queue_free()
		await get_tree().process_frame
	var camera_view := FakeCameraView.new()
	var camera_feed_host := instance.get("_camera_feed_host") as Control
	camera_feed_host.add_child(camera_view)
	camera_feed_host.move_child(camera_view, 0)
	var input_source := FakeSelectableInputSource.new()
	add_child_autofree(input_source)
	instance.set("_mediapipe_autostart_manager", manager)
	instance.set("_mediapipe_camera_view", camera_view)
	instance.set("_mediapipe_input_source", input_source)
	instance.set("_source_mode", "mediapipe_live")
	instance.set("_selected_mediapipe_live_camera_id", "/dev/video5")
	instance.set("_selected_mediapipe_tracking_quality", "full")
	instance.set("_mediapipe_runtime_signature", "mediapipe_live|0|full|1")
	await instance.call("_start_owned_mediapipe_runtime_async", 0, "mediapipe_live")
	assert_eq(manager.stop_server_call_count, 1, "When restart_server is unavailable, live camera switch should stop the owned sidecar before restarting it")
	assert_eq(manager.start_server_call_count, 1, "When restart_server is unavailable, live camera switch should restart the owned sidecar explicitly")
	assert_eq(String(manager.camera_source_override), "/dev/video5", "Fallback restart path should preserve the selected camera override for the restarted sidecar")
	assert_eq(input_source.set_selected_camera_device_id_call_count, 1, "Fallback restart path should keep the active input source camera source aligned with the selected live camera")
	assert_eq(String(input_source.selected_camera_device_id), "/dev/video5")
	assert_eq(input_source.stop_call_count, 1, "Fallback restart path should stop the stale owned input source before recreating it")
	var rebuilt_camera_view = instance.get("_mediapipe_camera_view") as FakeCameraView
	assert_false(rebuilt_camera_view == camera_view, "Fallback restart path should also rebuild the preview widget before streaming resumes")
	assert_eq(rebuilt_camera_view.start_stream_call_count, 1, "Fallback restart path should still wait for the rebuilt preview stream to become ready")
	assert_eq(String(instance.get("_mediapipe_runtime_status")), "ready")

func test_tracking_quality_restart_recreates_owned_input_source_after_stop_boundary() -> void:
	var packed_scene: PackedScene = load("res://scenes/camera_gesture_testbed.tscn")
	var instance := packed_scene.instantiate()
	add_child_autofree(instance)
	var manager := FakeAutoStartManager.new()
	add_child_autofree(manager)
	var existing_camera_view = instance.get("_mediapipe_camera_view")
	if existing_camera_view != null and is_instance_valid(existing_camera_view):
		existing_camera_view.queue_free()
		await get_tree().process_frame
	var camera_view := FakeCameraView.new()
	var camera_feed_host := instance.get("_camera_feed_host") as Control
	camera_feed_host.add_child(camera_view)
	camera_feed_host.move_child(camera_view, 0)
	var input_source := FakeSelectableInputSource.new()
	add_child_autofree(input_source)
	instance.set("_mediapipe_autostart_manager", manager)
	instance.set("_mediapipe_camera_view", camera_view)
	instance.set("_mediapipe_input_source", input_source)
	instance.set("_source_mode", "mediapipe_live")
	instance.set("_current_input_source", input_source)
	var controller := instance.get("_controller") as CameraGestureController
	assert_true(controller.attach_input_source(input_source), "Tracking-quality restart test should start with the controller bound to the stale owned provider")
	instance.set("_selected_mediapipe_live_camera_id", "/dev/video3")
	instance.set("_selected_mediapipe_tracking_quality", "optimized")
	instance.set("_mediapipe_runtime_signature", "mediapipe_live|/dev/video3|full|1")
	await instance.call("_start_owned_mediapipe_runtime_async", 0, "mediapipe_live")
	assert_eq(manager.restart_server_call_count, 1, "Tracking-quality change should still route through owned-runtime restart")
	assert_eq(input_source.stop_call_count, 1, "Tracking-quality restart should stop the stale owned input source before recreating it")
	var restarted_input_source = instance.get("_mediapipe_input_source")
	assert_false(restarted_input_source == input_source, "Tracking-quality restart should recreate the owned input source instead of hot-reusing the stale one")
	assert_eq(instance.get("_current_input_source"), restarted_input_source, "Tracking-quality restart should replace the scene's active input-source pointer after the owned provider is rebuilt")
	assert_eq(String(controller.get_debug_state().get("input_source_path", "")), str(restarted_input_source.get_path()), "Tracking-quality restart should rebind the controller to the rebuilt provider instead of leaving it attached to the freed one")
	var rebuilt_camera_view = instance.get("_mediapipe_camera_view") as FakeCameraView
	assert_false(rebuilt_camera_view == camera_view, "Tracking-quality restart should rebuild the preview widget after cleanup")
	assert_eq(rebuilt_camera_view.start_stream_call_count, 1, "Tracking-quality restart should wait for the rebuilt preview stream before reporting ready")
	assert_eq(String(instance.get("_mediapipe_runtime_status")), "ready")
