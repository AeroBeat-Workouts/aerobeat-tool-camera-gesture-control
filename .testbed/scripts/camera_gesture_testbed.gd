extends Control

const CONTROLLER_SCRIPT := preload("res://src/camera_gesture_controller.gd")
const FAKE_INPUT_SOURCE_SCRIPT := preload("res://scripts/fake_camera_input_source.gd")
const TRACKING_INSET_OVERLAY_SCRIPT := preload("res://scripts/tracking_inset_overlay.gd")
const TRACE_CAPTURE_STORE_SCRIPT := preload("res://scripts/trace_capture_store.gd")

const DEFAULT_PROFILE_REPO_RELATIVE_PATH := "../assets/profiles/camera_gesture/default_v1.camera_gesture.yaml"
const TESTBED_PROFILE_EXPORT_PATH := "user://camera_gesture_profiles/working.camera_gesture.yaml"
const TRACE_EXPORT_ROOT := "user://trace_exports/camera_gesture"
const FIXTURE_PLACEHOLDER_VIDEO_PATH := "res://assets/fixtures/camera_gesture/head_pose/candidates/example_take_01.mp4"
const FIXTURE_PLACEHOLDER_SIDECAR_PATH := "res://assets/fixtures/camera_gesture/head_pose/candidates/example_take_01.fixture.yaml"
const MEDIAPIPE_PROVIDER_PATH := "res://addons/aerobeat-input-mediapipe-python/src/input_provider.gd"
const MEDIAPIPE_CAMERA_VIEW_PATH := "res://addons/aerobeat-input-mediapipe-python/src/camera_view.gd"
const SOURCE_OPTIONS := ["fake", "mediapipe_python"]
const CONTROL_MODE_OPTIONS := ["gesture", "mouse_wasd", "disabled"]
const SAMPLE_SOURCE_OPTIONS := ["head_position", "head_velocity", "head_rotation"]
const TRACE_LEVEL_OPTIONS := ["off", "basic", "verbose"]
const RECENT_TRACE_LIMIT := 10

var _controller: CameraGestureController
var _trace_store: CameraGestureTraceCaptureStore
var _camera: Camera3D
var _world_root: Node3D
var _subviewport: SubViewport
var _status_label: Label
var _source_label: Label
var _tracking_label: Label
var _profile_identity_label: Label
var _trace_status_label: Label
var _source_option: OptionButton
var _profile_path_edit: LineEdit
var _trace_export_root_edit: LineEdit
var _fixture_key_edit: LineEdit
var _fixture_video_path_edit: LineEdit
var _fixture_sidecar_path_edit: LineEdit
var _preview_stats_label: RichTextLabel
var _runtime_debug_label: RichTextLabel
var _trace_debug_label: RichTextLabel
var _fixture_debug_label: RichTextLabel
var _provider_debug_label: RichTextLabel
var _media_inset_status_label: Label
var _media_placeholder_label: Label
var _tracking_overlay: CameraGestureTrackingInsetOverlay
var _camera_feed_host: Control
var _media_inset_placeholder: ColorRect
var _field_refs := {}
var _fake_controls := {}
var _current_input_source: Node = null
var _fake_input_source: FakeCameraInputSource
var _mediapipe_input_source: Node = null
var _mediapipe_provider_backend: Node = null
var _mediapipe_camera_view = null
var _source_mode := "fake"
var _latest_provider_state := {}
var _latest_source_snapshot := {}
var _latest_pose_landmarks: Array = []
var _recent_trace_frames: Array = []
var _animated_world_markers: Array = []
var _preview_title_label: Label

func _ready() -> void:
	name = "CameraGestureControlTestbed"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_trace_store = TRACE_CAPTURE_STORE_SCRIPT.new()
	_controller = CONTROLLER_SCRIPT.new()
	add_child(_controller)
	_controller.control_mode_changed.connect(_on_controller_mode_changed)
	_controller.tracking_state_changed.connect(_on_tracking_state_changed)
	_controller.profile_loaded.connect(_on_profile_loaded)
	_controller.profile_saved.connect(_on_profile_saved)

	_build_layout()
	_build_world()
	_setup_sources()
	_controller.attach_camera(_camera)
	_load_default_profile_on_boot()
	_apply_profile_to_ui(_controller.get_profile())
	_switch_input_source(_source_mode)
	_update_status("Ready")
	_update_debug_surfaces()
	set_process(true)

func _process(delta: float) -> void:
	_animate_world_reference(delta)
	if _current_input_source == _fake_input_source and _fake_input_source != null:
		if _fake_controls.has("tracking"):
			_fake_input_source.tracking = _fake_controls["tracking"].button_pressed
		if _fake_controls.has("confidence"):
			_fake_input_source.confidence = _fake_controls["confidence"].value
		if _fake_controls.has("animate"):
			_fake_input_source.animate = _fake_controls["animate"].button_pressed
		if _fake_controls.has("animation_speed"):
			_fake_input_source.animation_speed = _fake_controls["animation_speed"].value

	_latest_provider_state = _collect_provider_snapshot()
	_latest_source_snapshot = _collect_source_snapshot()
	_tracking_overlay.update_snapshot(_latest_source_snapshot)
	_capture_trace_frame_if_needed()
	_update_debug_surfaces()

func _notification(what: int) -> void:
	if what != NOTIFICATION_EXIT_TREE:
		return
	if _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("stop_stream"):
		_mediapipe_camera_view.stop_stream()
	if _mediapipe_input_source != null and _mediapipe_input_source.has_method("stop"):
		_mediapipe_input_source.stop()

func _build_layout() -> void:
	var root := HSplitContainer.new()
	root.name = "RootSplit"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.split_offset = 430
	add_child(root)

	var left_scroll := ScrollContainer.new()
	left_scroll.name = "LeftPanelScroll"
	left_scroll.size_flags_horizontal = Control.SIZE_FILL
	left_scroll.custom_minimum_size = Vector2(400, 0)
	root.add_child(left_scroll)

	var left_panel := VBoxContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.custom_minimum_size = Vector2(400, 820)
	left_panel.add_theme_constant_override("separation", 12)
	left_scroll.add_child(left_panel)

	var title := Label.new()
	title.text = "Camera Gesture Control Harness"
	title.add_theme_font_size_override("font_size", 26)
	left_panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "16:9 proving scene with YAML-first profile controls, 3D parallax preview, MediaPipe/tracking inset, and exportable trace scaffolding."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_panel.add_child(subtitle)

	_status_label = Label.new()
	_status_label.text = "Status: booting"
	left_panel.add_child(_status_label)

	_source_label = Label.new()
	_source_label.text = "Input source: booting"
	left_panel.add_child(_source_label)

	_tracking_label = Label.new()
	_tracking_label.text = "Tracking: booting"
	left_panel.add_child(_tracking_label)

	_profile_identity_label = Label.new()
	_profile_identity_label.text = "Profile: booting"
	_profile_identity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_panel.add_child(_profile_identity_label)

	var profile_panel := _add_section_panel(left_panel, "Profile workflow (YAML-first)")
	var default_profile_hint := Label.new()
	default_profile_hint.name = "DefaultProfileHint"
	default_profile_hint.text = "Checked-in default: %s" % _default_profile_absolute_path()
	default_profile_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile_panel.add_child(default_profile_hint)

	_profile_path_edit = LineEdit.new()
	_profile_path_edit.name = "ProfilePathEdit"
	_profile_path_edit.placeholder_text = "Path used for load/reload/export"
	_profile_path_edit.text = TESTBED_PROFILE_EXPORT_PATH
	profile_panel.add_child(_profile_path_edit)

	var profile_buttons_top := HBoxContainer.new()
	profile_buttons_top.name = "ProfileButtonsTop"
	profile_panel.add_child(profile_buttons_top)
	profile_buttons_top.add_child(_make_button("Load default YAML", _load_default_profile))
	profile_buttons_top.add_child(_make_button("Load path", _load_profile_from_path))
	profile_buttons_top.add_child(_make_button("Reload path", _reload_profile_from_path))

	var profile_buttons_bottom := HBoxContainer.new()
	profile_buttons_bottom.name = "ProfileButtonsBottom"
	profile_panel.add_child(profile_buttons_bottom)
	profile_buttons_bottom.add_child(_make_button("Export YAML snapshot", _export_profile_to_path))
	profile_buttons_bottom.add_child(_make_button("Reset runtime defaults", _reset_profile))

	var source_panel := _add_section_panel(left_panel, "Source + fixture hooks")
	_source_option = _add_option(source_panel, "Input source", SOURCE_OPTIONS, _on_source_mode_selected)
	_fixture_key_edit = LineEdit.new()
	_fixture_key_edit.name = "FixtureKeyEdit"
	_fixture_key_edit.placeholder_text = "Fixture key / intent family"
	_fixture_key_edit.text = "camera_gesture/manual/live"
	source_panel.add_child(_labeled_control("Fixture key", _fixture_key_edit))

	_fixture_video_path_edit = LineEdit.new()
	_fixture_video_path_edit.name = "FixtureVideoPathEdit"
	_fixture_video_path_edit.placeholder_text = "Future prerecorded video path"
	_fixture_video_path_edit.text = FIXTURE_PLACEHOLDER_VIDEO_PATH
	source_panel.add_child(_labeled_control("Fixture video path", _fixture_video_path_edit))

	_fixture_sidecar_path_edit = LineEdit.new()
	_fixture_sidecar_path_edit.name = "FixtureSidecarPathEdit"
	_fixture_sidecar_path_edit.placeholder_text = "Future sidecar YAML path"
	_fixture_sidecar_path_edit.text = FIXTURE_PLACEHOLDER_SIDECAR_PATH
	source_panel.add_child(_labeled_control("Fixture sidecar path", _fixture_sidecar_path_edit))

	var fixture_note := Label.new()
	fixture_note.text = "Practical v1 note: replay/oracle execution is not wired in this slice yet, but these fields flow into trace exports so the later prerecorded-fixture lane can reuse the same harness surface."
	fixture_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	source_panel.add_child(fixture_note)

	var trace_panel := _add_section_panel(left_panel, "Trace capture scaffolding")
	_trace_export_root_edit = LineEdit.new()
	_trace_export_root_edit.name = "TraceExportRootEdit"
	_trace_export_root_edit.placeholder_text = "Trace export root"
	_trace_export_root_edit.text = TRACE_EXPORT_ROOT
	trace_panel.add_child(_labeled_control("Trace export root", _trace_export_root_edit))

	var trace_buttons := HBoxContainer.new()
	trace_buttons.name = "TraceButtons"
	trace_panel.add_child(trace_buttons)
	trace_buttons.add_child(_make_button("Start capture", _start_trace_capture))
	trace_buttons.add_child(_make_button("Stop + export", _stop_and_export_trace_capture))

	var trace_buttons_bottom := HBoxContainer.new()
	trace_buttons_bottom.name = "TraceButtonsBottom"
	trace_panel.add_child(trace_buttons_bottom)
	trace_buttons_bottom.add_child(_make_button("Export snapshot now", _export_trace_snapshot))
	trace_buttons_bottom.add_child(_make_button("Clear trace buffer", _clear_recent_trace))

	_trace_status_label = Label.new()
	_trace_status_label.name = "TraceStatusLabel"
	_trace_status_label.text = "Trace: idle"
	_trace_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	trace_panel.add_child(_trace_status_label)

	var tuning_panel := _add_section_panel(left_panel, "Controller tuning")
	_field_refs["enabled"] = _add_toggle(tuning_panel, "Enabled", true, _on_profile_field_changed)
	_field_refs["mode"] = _add_option(tuning_panel, "Control mode", CONTROL_MODE_OPTIONS, _on_profile_field_changed)
	_field_refs["sample_source"] = _add_option(tuning_panel, "Sample source", SAMPLE_SOURCE_OPTIONS, _on_profile_field_changed)
	_field_refs["debug_trace_level"] = _add_option(tuning_panel, "Debug trace level", TRACE_LEVEL_OPTIONS, _on_profile_field_changed)
	_field_refs["invert_x"] = _add_toggle(tuning_panel, "Invert X", false, _on_profile_field_changed)
	_field_refs["invert_y"] = _add_toggle(tuning_panel, "Invert Y", false, _on_profile_field_changed)
	_field_refs["freeze_on_tracking_loss"] = _add_toggle(tuning_panel, "Freeze on tracking loss", true, _on_profile_field_changed)
	_field_refs["look_sensitivity_x"] = _add_slider(tuning_panel, "Look sensitivity X", 0.1, 3.0, 0.05, 1.0, _on_profile_field_changed)
	_field_refs["look_sensitivity_y"] = _add_slider(tuning_panel, "Look sensitivity Y", 0.1, 3.0, 0.05, 1.0, _on_profile_field_changed)
	_field_refs["translation_sensitivity_x"] = _add_slider(tuning_panel, "Translation sensitivity X", 0.1, 3.0, 0.05, 1.0, _on_profile_field_changed)
	_field_refs["translation_sensitivity_y"] = _add_slider(tuning_panel, "Translation sensitivity Y", 0.1, 3.0, 0.05, 0.6, _on_profile_field_changed)
	_field_refs["translation_sensitivity_z"] = _add_slider(tuning_panel, "Translation sensitivity Z", 0.1, 3.0, 0.05, 0.4, _on_profile_field_changed)
	_field_refs["max_yaw_degrees"] = _add_slider(tuning_panel, "Max yaw degrees", 0.0, 60.0, 1.0, 20.0, _on_profile_field_changed)
	_field_refs["max_pitch_degrees"] = _add_slider(tuning_panel, "Max pitch degrees", 0.0, 45.0, 1.0, 12.0, _on_profile_field_changed)
	_field_refs["max_roll_degrees"] = _add_slider(tuning_panel, "Max roll degrees", 0.0, 30.0, 1.0, 4.0, _on_profile_field_changed)
	_field_refs["max_translation_x"] = _add_slider(tuning_panel, "Max translation X", 0.0, 2.0, 0.01, 0.6, _on_profile_field_changed)
	_field_refs["max_translation_y"] = _add_slider(tuning_panel, "Max translation Y", 0.0, 2.0, 0.01, 0.35, _on_profile_field_changed)
	_field_refs["max_translation_z"] = _add_slider(tuning_panel, "Max translation Z", 0.0, 2.0, 0.01, 0.45, _on_profile_field_changed)
	_field_refs["smoothing"] = _add_slider(tuning_panel, "Smoothing", 0.0, 1.0, 0.01, 0.2, _on_profile_field_changed)
	_field_refs["deadzone"] = _add_slider(tuning_panel, "Deadzone", 0.0, 0.5, 0.01, 0.03, _on_profile_field_changed)
	_field_refs["recenter_speed"] = _add_slider(tuning_panel, "Recenter speed", 0.0, 10.0, 0.1, 1.8, _on_profile_field_changed)
	_field_refs["tracking_confidence_threshold"] = _add_slider(tuning_panel, "Tracking confidence threshold", 0.0, 1.0, 0.01, 0.45, _on_profile_field_changed)

	var fake_panel := _add_section_panel(left_panel, "Fake input controls")
	_fake_controls["tracking"] = _add_toggle(fake_panel, "Fake tracking active", true, _on_fake_control_changed)
	_fake_controls["confidence"] = _add_slider(fake_panel, "Fake confidence", 0.0, 1.0, 0.01, 1.0, _on_fake_control_changed)
	_fake_controls["animate"] = _add_toggle(fake_panel, "Animate fake input", true, _on_fake_control_changed)
	_fake_controls["animation_speed"] = _add_slider(fake_panel, "Fake animation speed", 0.1, 4.0, 0.1, 1.0, _on_fake_control_changed)

	var right_column := VBoxContainer.new()
	right_column.name = "RightColumn"
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_theme_constant_override("separation", 10)
	root.add_child(right_column)

	var preview_panel := PanelContainer.new()
	preview_panel.name = "PreviewPanel"
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_child(preview_panel)

	var preview_margin := MarginContainer.new()
	preview_margin.name = "PreviewMargin"
	preview_margin.add_theme_constant_override("margin_left", 10)
	preview_margin.add_theme_constant_override("margin_top", 10)
	preview_margin.add_theme_constant_override("margin_right", 10)
	preview_margin.add_theme_constant_override("margin_bottom", 10)
	preview_panel.add_child(preview_margin)

	var preview_stack := Control.new()
	preview_stack.name = "PreviewStack"
	preview_stack.custom_minimum_size = Vector2(1280, 720)
	preview_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_margin.add_child(preview_stack)

	var viewport_container := SubViewportContainer.new()
	viewport_container.name = "WorldPreviewViewportContainer"
	viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	preview_stack.add_child(viewport_container)

	_subviewport = SubViewport.new()
	_subviewport.name = "WorldPreviewViewport"
	_subviewport.size = Vector2i(1280, 720)
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(_subviewport)

	var overlay_top := VBoxContainer.new()
	overlay_top.name = "OverlayTop"
	overlay_top.offset_left = 16.0
	overlay_top.offset_top = 16.0
	overlay_top.add_theme_constant_override("separation", 4)
	preview_stack.add_child(overlay_top)

	_preview_title_label = Label.new()
	_preview_title_label.name = "PreviewTitleLabel"
	_preview_title_label.text = "3D World Preview"
	_preview_title_label.add_theme_font_size_override("font_size", 22)
	overlay_top.add_child(_preview_title_label)

	_preview_stats_label = RichTextLabel.new()
	_preview_stats_label.name = "PreviewStatsLabel"
	_preview_stats_label.custom_minimum_size = Vector2(340, 70)
	_preview_stats_label.fit_content = true
	_preview_stats_label.scroll_active = false
	overlay_top.add_child(_preview_stats_label)

	var media_panel := PanelContainer.new()
	media_panel.name = "MediaInsetPanel"
	media_panel.anchor_left = 0.0
	media_panel.anchor_top = 1.0
	media_panel.anchor_right = 0.0
	media_panel.anchor_bottom = 1.0
	media_panel.offset_left = 16.0
	media_panel.offset_top = -272.0
	media_panel.offset_right = 390.0
	media_panel.offset_bottom = -16.0
	preview_stack.add_child(media_panel)

	var media_column := VBoxContainer.new()
	media_column.name = "MediaInsetColumn"
	media_column.add_theme_constant_override("separation", 6)
	media_panel.add_child(media_column)

	var media_title := Label.new()
	media_title.text = "MediaPipe / Tracking Inset"
	media_title.add_theme_font_size_override("font_size", 18)
	media_column.add_child(media_title)

	_camera_feed_host = Control.new()
	_camera_feed_host.name = "CameraFeedHost"
	_camera_feed_host.custom_minimum_size = Vector2(0, 180)
	_camera_feed_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_camera_feed_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	media_column.add_child(_camera_feed_host)

	_media_inset_placeholder = ColorRect.new()
	_media_inset_placeholder.name = "MediaInsetPlaceholder"
	_media_inset_placeholder.color = Color(0.05, 0.07, 0.10, 0.92)
	_media_inset_placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_camera_feed_host.add_child(_media_inset_placeholder)

	_media_placeholder_label = Label.new()
	_media_placeholder_label.name = "MediaPlaceholderLabel"
	_media_placeholder_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_media_placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_media_placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_media_placeholder_label.text = "Awaiting source preview"
	_media_placeholder_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_media_inset_placeholder.add_child(_media_placeholder_label)

	_tracking_overlay = TRACKING_INSET_OVERLAY_SCRIPT.new()
	_tracking_overlay.name = "TrackingInsetOverlay"
	_tracking_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tracking_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camera_feed_host.add_child(_tracking_overlay)

	_media_inset_status_label = Label.new()
	_media_inset_status_label.name = "MediaInsetStatusLabel"
	_media_inset_status_label.text = "Inset: booting"
	_media_inset_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	media_column.add_child(_media_inset_status_label)

	var debug_tabs := TabContainer.new()
	debug_tabs.name = "DebugTabs"
	debug_tabs.custom_minimum_size = Vector2(0, 280)
	debug_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_tabs.size_flags_vertical = Control.SIZE_FILL
	right_column.add_child(debug_tabs)

	_runtime_debug_label = _add_debug_tab(debug_tabs, "Runtime")
	_trace_debug_label = _add_debug_tab(debug_tabs, "Trace")
	_fixture_debug_label = _add_debug_tab(debug_tabs, "Fixture")
	_provider_debug_label = _add_debug_tab(debug_tabs, "Provider")

func _build_world() -> void:
	_world_root = Node3D.new()
	_world_root.name = "WorldRoot"
	_subviewport.add_child(_world_root)

	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.05, 0.09)
	environment.environment = env
	_world_root.add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48.0, -30.0, 0.0)
	sun.light_energy = 1.8
	_world_root.add_child(sun)

	var fill := OmniLight3D.new()
	fill.name = "Fill"
	fill.position = Vector3(0.0, 2.5, 1.8)
	fill.light_energy = 2.1
	_world_root.add_child(fill)

	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = PlaneMesh.new()
	ground.scale = Vector3(10.0, 1.0, 14.0)
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.08, 0.10, 0.14)
	ground.material_override = ground_material
	_world_root.add_child(ground)

	for lane in range(-3, 4):
		var stripe := MeshInstance3D.new()
		stripe.mesh = BoxMesh.new()
		stripe.position = Vector3(float(lane) * 1.1, 0.02, 0.0)
		stripe.scale = Vector3(0.02, 0.02, 6.0)
		var stripe_material := StandardMaterial3D.new()
		stripe_material.albedo_color = Color(0.18, 0.26, 0.36, 0.95)
		stripe.material_override = stripe_material
		_world_root.add_child(stripe)

	var depth_configs := [
		{"name": "NearMarker", "position": Vector3(-2.4, 0.6, 1.8), "color": Color(0.24, 0.92, 0.84), "scale": Vector3(0.7, 1.2, 0.7), "sway": 0.28, "speed": 0.8},
		{"name": "MidMarker", "position": Vector3(0.0, 1.1, -0.2), "color": Color(0.95, 0.72, 0.34), "scale": Vector3(1.0, 2.4, 1.0), "sway": 0.18, "speed": 0.55},
		{"name": "FarMarker", "position": Vector3(2.6, 1.6, -3.1), "color": Color(0.56, 0.68, 1.0), "scale": Vector3(1.3, 3.2, 1.3), "sway": 0.12, "speed": 0.36},
	]
	for config_variant: Variant in depth_configs:
		var config: Dictionary = config_variant
		var mesh := MeshInstance3D.new()
		mesh.name = str(config.get("name", "Marker"))
		mesh.mesh = CylinderMesh.new()
		mesh.position = config.get("position", Vector3.ZERO)
		mesh.scale = config.get("scale", Vector3.ONE)
		var material := StandardMaterial3D.new()
		material.albedo_color = config.get("color", Color.WHITE)
		mesh.material_override = material
		_world_root.add_child(mesh)
		_animated_world_markers.append({
			"node": mesh,
			"base_position": mesh.position,
			"sway": float(config.get("sway", 0.0)),
			"speed": float(config.get("speed", 1.0)),
		})

	for ring_index in range(3):
		var ring := MeshInstance3D.new()
		ring.name = "ReferenceSphere%d" % ring_index
		ring.mesh = SphereMesh.new()
		ring.position = Vector3(-1.4 + float(ring_index) * 1.4, 0.45 + float(ring_index) * 0.25, -1.5 - float(ring_index) * 1.8)
		ring.scale = Vector3.ONE * (0.4 + float(ring_index) * 0.18)
		var ring_material := StandardMaterial3D.new()
		ring_material.emission_enabled = true
		ring_material.emission = Color.from_hsv(0.50 + float(ring_index) * 0.12, 0.45, 0.55)
		ring_material.albedo_color = ring_material.emission
		ring.material_override = ring_material
		_world_root.add_child(ring)

	_camera = Camera3D.new()
	_camera.name = "PreviewCamera"
	_camera.current = true
	_camera.position = Vector3(0.0, 1.55, 5.4)
	_world_root.add_child(_camera)
	_camera.look_at_from_position(_camera.position, Vector3(0.0, 1.1, -0.4))

func _setup_sources() -> void:
	_fake_input_source = FAKE_INPUT_SOURCE_SCRIPT.new()
	_fake_input_source.name = "FakeCameraInputSource"
	add_child(_fake_input_source)
	_fake_input_source.set_process(true)

	if ResourceLoader.exists(MEDIAPIPE_PROVIDER_PATH):
		var script: GDScript = load(MEDIAPIPE_PROVIDER_PATH)
		if script != null:
			_mediapipe_input_source = script.new()
			_mediapipe_input_source.name = "MediaPipePythonInputSource"
			add_child(_mediapipe_input_source)
			if _mediapipe_input_source.has_method("start"):
				var started := bool(_mediapipe_input_source.start("{}"))
				if started:
					_wire_mediapipe_backend_if_possible()
				else:
					_mediapipe_input_source.queue_free()
					_mediapipe_input_source = null
	_ensure_mediapipe_camera_view_if_possible()
	if _mediapipe_input_source == null and _source_option != null:
		_source_mode = "fake"
		_source_option.select(0)
		_source_option.set_item_disabled(1, true)

func _switch_input_source(mode: String) -> void:
	_source_mode = mode if SOURCE_OPTIONS.has(mode) else "fake"
	match _source_mode:
		"mediapipe_python":
			if _mediapipe_input_source != null and _controller.attach_input_source(_mediapipe_input_source):
				_current_input_source = _mediapipe_input_source
				_wire_mediapipe_backend_if_possible()
				_update_status("Using MediaPipe Python input source")
			else:
				_current_input_source = _fake_input_source
				_controller.attach_input_source(_fake_input_source)
				_source_mode = "fake"
				if _source_option != null:
					_source_option.select(0)
				_update_status("MediaPipe unavailable; fell back to fake source")
		_:
			_current_input_source = _fake_input_source
			_controller.attach_input_source(_fake_input_source)
			_update_status("Using fake input source")
	_source_label.text = "Input source: %s" % _source_mode
	for control in _fake_controls.values():
		control.visible = _current_input_source == _fake_input_source
	_refresh_media_inset_surface()

func _load_default_profile_on_boot() -> void:
	var default_path := _default_profile_absolute_path()
	if FileAccess.file_exists(default_path):
		var profile := _controller.load_profile(default_path)
		if not profile.is_empty():
			_profile_path_edit.text = TESTBED_PROFILE_EXPORT_PATH
			_apply_profile_to_ui(profile)
			return
	_controller.apply_profile(CONTROLLER_SCRIPT.DEFAULT_PROFILE)
	_apply_profile_to_ui(_controller.get_profile())

func _load_default_profile() -> void:
	var default_path := _default_profile_absolute_path()
	var profile := _controller.load_profile(default_path)
	if profile.is_empty():
		_update_status("Failed to load checked-in default YAML")
		return
	_apply_profile_to_ui(profile)
	_update_status("Loaded checked-in default YAML profile")

func _load_profile_from_path() -> void:
	var target_path := _profile_path_edit.text.strip_edges()
	if target_path.is_empty():
		_update_status("Load path is empty")
		return
	var profile := _controller.load_profile(target_path)
	if profile.is_empty():
		_update_status("Failed to load profile from %s" % target_path)
		return
	_apply_profile_to_ui(profile)
	_update_status("Loaded profile from %s" % target_path)

func _reload_profile_from_path() -> void:
	_load_profile_from_path()

func _export_profile_to_path() -> void:
	_apply_ui_to_controller_profile()
	var target_path := _normalized_profile_export_path()
	_ensure_parent_dir_for_file(target_path)
	var result := _controller.save_profile(target_path)
	if result.is_empty():
		_update_status("Failed to export YAML profile to %s" % target_path)
		return
	_profile_path_edit.text = target_path
	_update_status("Exported YAML profile snapshot to %s" % target_path)

func _reset_profile() -> void:
	_controller.apply_profile(CONTROLLER_SCRIPT.DEFAULT_PROFILE)
	_apply_profile_to_ui(_controller.get_profile())
	_update_status("Reset controller profile to runtime defaults")

func _start_trace_capture() -> void:
	var context := _build_trace_context()
	_trace_store.begin_capture(context)
	_trace_store.append_note("trace_capture_requested", {"profile_path_edit": _profile_path_edit.text})
	_update_status("Trace capture started")

func _stop_and_export_trace_capture() -> void:
	if not _trace_store.is_capturing():
		_update_status("Trace capture was not running; exporting current snapshot instead")
		_export_trace_snapshot()
		return
	_trace_store.end_capture({"reason": "stop_and_export"})
	var export_result := _export_trace_payload("stop_and_export")
	if export_result.is_empty():
		_update_status("Trace capture stopped, but export failed")
		return
	_update_status("Trace capture exported to %s" % str(export_result.get("export_dir", "")))

func _export_trace_snapshot() -> void:
	var capture_started_here := false
	if not _trace_store.is_capturing():
		_trace_store.begin_capture(_build_trace_context())
		_trace_store.capture_frame(_controller.get_debug_state(), _latest_source_snapshot, _latest_provider_state, {"capture_mode": "single_snapshot"})
		_trace_store.end_capture({"reason": "single_snapshot"})
		capture_started_here = true
	var export_result := _export_trace_payload("snapshot")
	if export_result.is_empty():
		_update_status("Trace snapshot export failed")
		return
	_update_status("Trace snapshot exported to %s" % str(export_result.get("export_dir", "")))
	if capture_started_here:
		_trace_store.reset()

func _clear_recent_trace() -> void:
	_recent_trace_frames.clear()
	if not _trace_store.is_capturing():
		_trace_store.reset()
	_update_status("Cleared recent trace buffer")

func _export_trace_payload(reason: String) -> Dictionary:
	var export_root := _trace_export_root_edit.text.strip_edges()
	var manifest_extra := {
		"reason": reason,
		"fixture": {
			"key": _fixture_key_edit.text.strip_edges(),
			"video_path": _fixture_video_path_edit.text.strip_edges(),
			"sidecar_path": _fixture_sidecar_path_edit.text.strip_edges(),
		},
		"media_inset": {
			"source_mode": _source_mode,
			"camera_feed_available": _mediapipe_camera_view != null,
			"camera_feed_live": _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("is_streaming") and bool(_mediapipe_camera_view.is_streaming()),
			"fallback_message": _media_placeholder_label.text,
		},
	}
	var export_result := _trace_store.export_capture(export_root, manifest_extra)
	if export_result.is_empty():
		return {}
	var export_dir := str(export_result.get("export_dir", ""))
	if not export_dir.is_empty():
		var profile_export_path := export_dir.path_join("resolved_profile.camera_gesture.yaml")
		_controller.save_profile(profile_export_path)
	return export_result

func _capture_trace_frame_if_needed() -> void:
	var debug_state := _controller.get_debug_state()
	_remember_recent_trace_frame(debug_state, _latest_source_snapshot)
	if not _trace_store.is_capturing():
		return
	_trace_store.capture_frame(debug_state, _latest_source_snapshot, _latest_provider_state, {
		"fixture_key": _fixture_key_edit.text.strip_edges(),
		"world_preview_size": _subviewport.size,
	})

func _remember_recent_trace_frame(debug_state: Dictionary, source_snapshot: Dictionary) -> void:
	var tracking_state: Dictionary = debug_state.get("tracking_state", {}) if debug_state.get("tracking_state", {}) is Dictionary else {}
	var translation: Vector3 = debug_state.get("current_translation", Vector3.ZERO)
	var frame_summary := {
		"mode": debug_state.get("control_mode", ""),
		"tracking": bool(tracking_state.get("tracking", false)),
		"confidence": float(tracking_state.get("confidence", 0.0)),
		"translation": translation,
		"source_mode": source_snapshot.get("source_mode", _source_mode),
	}
	_recent_trace_frames.append(frame_summary)
	while _recent_trace_frames.size() > RECENT_TRACE_LIMIT:
		_recent_trace_frames.remove_at(0)

func _collect_source_snapshot() -> Dictionary:
	var snapshot := {
		"source_mode": _source_mode,
		"tracking": _current_input_source != null and _current_input_source.has_method("is_tracking") and bool(_current_input_source.is_tracking()),
		"confidence": _read_current_source_confidence(),
		"threshold": float(_controller.get_debug_state().get("tracking_state", {}).get("threshold", 0.0)),
		"camera_feed_requested": _source_mode == "mediapipe_python",
		"camera_feed_live": _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("is_streaming") and bool(_mediapipe_camera_view.is_streaming()),
	}
	if _current_input_source != null and _current_input_source.has_method("get_head_position"):
		snapshot["head_position"] = _coerce_vector3(_current_input_source.get_head_position())
	if _current_input_source != null and _current_input_source.has_method("get_head_velocity"):
		snapshot["head_velocity"] = _coerce_vector3(_current_input_source.get_head_velocity())
	if _current_input_source != null and _current_input_source.has_method("get_head_rotation"):
		var rotation: Variant = _current_input_source.get_head_rotation()
		if rotation is Quaternion:
			snapshot["head_rotation_euler"] = (rotation as Quaternion).get_euler()
	if _current_input_source == _fake_input_source and _fake_input_source != null:
		snapshot["fake_animate"] = _fake_input_source.animate
		snapshot["fake_animation_speed"] = _fake_input_source.animation_speed
	return snapshot

func _collect_provider_snapshot() -> Dictionary:
	if _source_mode != "mediapipe_python" or _mediapipe_provider_backend == null:
		return {
			"provider_mode": _source_mode,
			"landmark_count": _latest_pose_landmarks.size(),
		}
	var detector_state: Dictionary = {}
	if _mediapipe_provider_backend.has_method("get_detector_state"):
		detector_state = _mediapipe_provider_backend.get_detector_state()
	var metrics: Dictionary = detector_state.get("metrics", {}) if detector_state.get("metrics", {}) is Dictionary else {}
	var confidences: Dictionary = metrics.get("confidences", {}) if metrics.get("confidences", {}) is Dictionary else {}
	var events: Array = detector_state.get("events", []) if detector_state.get("events", []) is Array else []
	return {
		"provider_mode": "mediapipe_python",
		"tracking_state": detector_state.get("tracking_state", ""),
		"head_confidence": float(confidences.get("head", 0.0)),
		"torso_confidence": float(confidences.get("torso", 0.0)),
		"event_count": events.size(),
		"landmark_count": _latest_pose_landmarks.size(),
	}

func _read_current_source_confidence() -> float:
	if _current_input_source == null or not _current_input_source.has_method("get_tracking_confidence"):
		return 0.0
	return float(_current_input_source.get_tracking_confidence(&"head"))

func _apply_ui_to_controller_profile() -> void:
	var profile := _controller.get_profile()
	profile["mode"] = _get_option_value(_field_refs["mode"])
	profile["sample_source"] = _get_option_value(_field_refs["sample_source"])
	profile["debug_trace_level"] = _get_option_value(_field_refs["debug_trace_level"])
	profile["invert_x"] = _field_refs["invert_x"].button_pressed
	profile["invert_y"] = _field_refs["invert_y"].button_pressed
	profile["freeze_on_tracking_loss"] = _field_refs["freeze_on_tracking_loss"].button_pressed
	profile["look_sensitivity_x"] = _field_refs["look_sensitivity_x"].value
	profile["look_sensitivity_y"] = _field_refs["look_sensitivity_y"].value
	profile["translation_sensitivity_x"] = _field_refs["translation_sensitivity_x"].value
	profile["translation_sensitivity_y"] = _field_refs["translation_sensitivity_y"].value
	profile["translation_sensitivity_z"] = _field_refs["translation_sensitivity_z"].value
	profile["max_yaw_degrees"] = _field_refs["max_yaw_degrees"].value
	profile["max_pitch_degrees"] = _field_refs["max_pitch_degrees"].value
	profile["max_roll_degrees"] = _field_refs["max_roll_degrees"].value
	profile["max_translation_meters"] = [
		_field_refs["max_translation_x"].value,
		_field_refs["max_translation_y"].value,
		_field_refs["max_translation_z"].value,
	]
	profile["smoothing"] = _field_refs["smoothing"].value
	profile["deadzone"] = _field_refs["deadzone"].value
	profile["recenter_speed"] = _field_refs["recenter_speed"].value
	profile["tracking_confidence_threshold"] = _field_refs["tracking_confidence_threshold"].value
	_controller.set_enabled(_field_refs["enabled"].button_pressed)
	_controller.apply_profile(profile)

func _apply_profile_to_ui(profile: Dictionary) -> void:
	_field_refs["enabled"].button_pressed = _controller.get_debug_state().get("enabled", true)
	_set_option_value(_field_refs["mode"], str(profile.get("mode", "gesture")))
	_set_option_value(_field_refs["sample_source"], str(profile.get("sample_source", "head_position")))
	_set_option_value(_field_refs["debug_trace_level"], str(profile.get("debug_trace_level", "basic")))
	_field_refs["invert_x"].button_pressed = bool(profile.get("invert_x", false))
	_field_refs["invert_y"].button_pressed = bool(profile.get("invert_y", false))
	_field_refs["freeze_on_tracking_loss"].button_pressed = bool(profile.get("freeze_on_tracking_loss", true))
	_field_refs["look_sensitivity_x"].value = float(profile.get("look_sensitivity_x", 1.0))
	_field_refs["look_sensitivity_y"].value = float(profile.get("look_sensitivity_y", 1.0))
	_field_refs["translation_sensitivity_x"].value = float(profile.get("translation_sensitivity_x", 1.0))
	_field_refs["translation_sensitivity_y"].value = float(profile.get("translation_sensitivity_y", 0.6))
	_field_refs["translation_sensitivity_z"].value = float(profile.get("translation_sensitivity_z", 0.4))
	_field_refs["max_yaw_degrees"].value = float(profile.get("max_yaw_degrees", 20.0))
	_field_refs["max_pitch_degrees"].value = float(profile.get("max_pitch_degrees", 12.0))
	_field_refs["max_roll_degrees"].value = float(profile.get("max_roll_degrees", 4.0))
	var translation: Array = profile.get("max_translation_meters", [0.6, 0.35, 0.45])
	_field_refs["max_translation_x"].value = float(translation[0])
	_field_refs["max_translation_y"].value = float(translation[1])
	_field_refs["max_translation_z"].value = float(translation[2])
	_field_refs["smoothing"].value = float(profile.get("smoothing", 0.2))
	_field_refs["deadzone"].value = float(profile.get("deadzone", 0.03))
	_field_refs["recenter_speed"].value = float(profile.get("recenter_speed", 1.8))
	_field_refs["tracking_confidence_threshold"].value = float(profile.get("tracking_confidence_threshold", 0.45))

func _update_debug_surfaces() -> void:
	var debug_state := _controller.get_debug_state()
	var tracking_state: Dictionary = debug_state.get("tracking_state", {}) if debug_state.get("tracking_state", {}) is Dictionary else {}
	var active_profile: Dictionary = debug_state.get("active_profile", {}) if debug_state.get("active_profile", {}) is Dictionary else {}
	var current_translation: Vector3 = debug_state.get("current_translation", Vector3.ZERO)
	var current_rotation: Vector3 = debug_state.get("current_rotation_radians", Vector3.ZERO)
	var trace_status := _trace_store.get_status()

	_tracking_label.text = "Tracking: %s | confidence %.2f / %.2f" % [
		"active" if bool(tracking_state.get("tracking", false)) else "inactive",
		float(tracking_state.get("confidence", 0.0)),
		float(tracking_state.get("threshold", 0.0)),
	]
	_profile_identity_label.text = "Profile: %s | %s | %s" % [
		str(active_profile.get("profile_id", "")),
		str(active_profile.get("schema_id", "")),
		str(active_profile.get("source_hash", "")),
	]
	_trace_status_label.text = "Trace: %s | frames=%d | export root=%s" % [
		"capturing" if bool(trace_status.get("capturing", false)) else "idle",
		int(trace_status.get("frame_count", 0)),
		_trace_export_root_edit.text,
	]
	_preview_stats_label.text = "Source: %s\nTranslation: %s\nRotation(deg): %s" % [
		_source_mode,
		current_translation,
		Vector3(rad_to_deg(current_rotation.x), rad_to_deg(current_rotation.y), rad_to_deg(current_rotation.z)),
	]
	_media_inset_status_label.text = _build_media_inset_status_line()
	_runtime_debug_label.text = _build_runtime_debug_text(debug_state)
	_trace_debug_label.text = _build_trace_debug_text(trace_status)
	_fixture_debug_label.text = _build_fixture_debug_text(active_profile)
	_provider_debug_label.text = _build_provider_debug_text()

func _build_runtime_debug_text(debug_state: Dictionary) -> String:
	var tracking_state: Dictionary = debug_state.get("tracking_state", {}) if debug_state.get("tracking_state", {}) is Dictionary else {}
	var lines := [
		"Mode: %s" % str(debug_state.get("control_mode", "")),
		"Enabled: %s" % str(debug_state.get("enabled", false)),
		"Camera attached: %s (%s)" % [str(debug_state.get("camera_attached", false)), str(debug_state.get("camera_path", ""))],
		"Input source attached: %s (%s)" % [str(debug_state.get("input_source_attached", false)), str(debug_state.get("input_source_path", ""))],
		"Current translation: %s" % str(debug_state.get("current_translation", Vector3.ZERO)),
		"Target translation: %s" % str(debug_state.get("target_translation", Vector3.ZERO)),
		"Current rotation radians: %s" % str(debug_state.get("current_rotation_radians", Vector3.ZERO)),
		"Target rotation radians: %s" % str(debug_state.get("target_rotation_radians", Vector3.ZERO)),
		"",
		"Tracking state:",
		JSON.stringify(_trace_store.to_json_safe(tracking_state), "\t"),
		"",
		"Active profile:",
		JSON.stringify(_trace_store.to_json_safe(debug_state.get("active_profile", {})), "\t"),
		"",
		"Profile:",
		JSON.stringify(_trace_store.to_json_safe(debug_state.get("profile", {})), "\t"),
	]
	return "\n".join(lines)

func _build_trace_debug_text(trace_status: Dictionary) -> String:
	var lines := [
		"Capture active: %s" % str(trace_status.get("capturing", false)),
		"Session ID: %s" % str(trace_status.get("session_id", "")),
		"Frame count: %s" % str(trace_status.get("frame_count", 0)),
		"Dropped frames: %s" % str(trace_status.get("dropped_frames", 0)),
		"Duration ms: %s" % str(trace_status.get("duration_ms", 0)),
		"",
		"Recent frame summaries:",
	]
	for frame_variant: Variant in _recent_trace_frames:
		var frame: Dictionary = frame_variant
		lines.append("- mode=%s tracking=%s confidence=%.2f source=%s translation=%s" % [
			str(frame.get("mode", "")),
			str(frame.get("tracking", false)),
			float(frame.get("confidence", 0.0)),
			str(frame.get("source_mode", "")),
			str(frame.get("translation", Vector3.ZERO)),
		])
	var last_export: Dictionary = trace_status.get("last_export", {}) if trace_status.get("last_export", {}) is Dictionary else {}
	if not last_export.is_empty():
		lines.append("")
		lines.append("Last export:")
		lines.append(JSON.stringify(_trace_store.to_json_safe(last_export), "\t"))
	return "\n".join(lines)

func _build_fixture_debug_text(active_profile: Dictionary) -> String:
	var lines := [
		"Fixture key: %s" % _fixture_key_edit.text.strip_edges(),
		"Video path: %s" % _fixture_video_path_edit.text.strip_edges(),
		"Sidecar path: %s" % _fixture_sidecar_path_edit.text.strip_edges(),
		"Trace export root: %s" % _trace_export_root_edit.text.strip_edges(),
		"Active profile path: %s" % str(active_profile.get("source_path", "")),
		"",
		"Harness readiness:",
		"- left config/debug panel: ready",
		"- 16:9 world preview: ready",
		"- bottom-left media/tracking inset: ready with honest fallback",
		"- prerecorded fixture path fields: scaffolded",
		"- replay/oracle runner: pending later slice",
	]
	return "\n".join(lines)

func _build_provider_debug_text() -> String:
	var lines := [
		"Media inset status: %s" % _build_media_inset_status_line(),
		"Source snapshot:",
		JSON.stringify(_trace_store.to_json_safe(_latest_source_snapshot), "\t"),
		"",
		"Provider snapshot:",
		JSON.stringify(_trace_store.to_json_safe(_latest_provider_state), "\t"),
	]
	if not _latest_pose_landmarks.is_empty():
		lines.append("")
		lines.append("Latest landmarks captured: %d" % _latest_pose_landmarks.size())
	return "\n".join(lines)

func _build_media_inset_status_line() -> String:
	if _source_mode == "fake":
		return "Inset: fake source preview with tracking overlay"
	if _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("is_streaming") and bool(_mediapipe_camera_view.is_streaming()):
		return "Inset: MediaPipe camera feed live + tracking overlay"
	if _mediapipe_camera_view != null:
		return "Inset: MediaPipe seam mounted, camera feed not live yet; overlay remains active"
	return "Inset: MediaPipe camera view seam unavailable; overlay-only fallback"

func _refresh_media_inset_surface() -> void:
	var wants_mediapipe_view := _source_mode == "mediapipe_python" and _mediapipe_camera_view != null
	if wants_mediapipe_view and _mediapipe_camera_view.has_method("start_stream"):
		call_deferred("_ensure_mediapipe_camera_stream")
	elif _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("stop_stream"):
		_mediapipe_camera_view.stop_stream()
	_media_inset_placeholder.visible = _mediapipe_camera_view == null or not (_mediapipe_camera_view.has_method("is_streaming") and bool(_mediapipe_camera_view.is_streaming()))
	_media_placeholder_label.text = _build_media_placeholder_text()

func _ensure_mediapipe_camera_stream() -> void:
	if _source_mode != "mediapipe_python" or _mediapipe_camera_view == null:
		return
	if _mediapipe_camera_view.has_method("is_streaming") and bool(_mediapipe_camera_view.is_streaming()):
		_media_inset_placeholder.visible = false
		return
	if _mediapipe_camera_view.has_method("start_stream"):
		var started_result: Variant = await _mediapipe_camera_view.start_stream()
		var started: bool = bool(started_result)
		_media_inset_placeholder.visible = not started
		_media_placeholder_label.text = _build_media_placeholder_text()

func _build_media_placeholder_text() -> String:
	if _source_mode == "fake":
		return "Fake source active\nTracking overlay shows normalized head motion."
	if _mediapipe_camera_view == null:
		return "MediaPipe camera view not mounted in this addon seam yet.\nTracking overlay still shows controller-relevant motion."
	return "MediaPipe source active, but live camera texture is not streaming yet.\nThis slice keeps the inset structure honest and ready for the final seam."

func _ensure_mediapipe_camera_view_if_possible() -> void:
	if not ResourceLoader.exists(MEDIAPIPE_CAMERA_VIEW_PATH):
		return
	var camera_view_script: GDScript = load(MEDIAPIPE_CAMERA_VIEW_PATH)
	if camera_view_script == null:
		return
	_mediapipe_camera_view = camera_view_script.new()
	_mediapipe_camera_view.name = "MediaPipeCameraView"
	_mediapipe_camera_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mediapipe_camera_view.stream_url = "http://127.0.0.1:4243/camera"
	_mediapipe_camera_view.show_overlay = true
	_camera_feed_host.add_child(_mediapipe_camera_view)
	_camera_feed_host.move_child(_mediapipe_camera_view, 0)

func _wire_mediapipe_backend_if_possible() -> void:
	if _mediapipe_input_source == null:
		return
	var backend: Variant = _mediapipe_input_source.get("_provider")
	if not (backend is Node):
		return
	_mediapipe_provider_backend = backend
	var pose_callable := Callable(self, "_on_mediapipe_pose_updated")
	if _mediapipe_provider_backend.has_signal("pose_updated") and not _mediapipe_provider_backend.is_connected(&"pose_updated", pose_callable):
		_mediapipe_provider_backend.connect(&"pose_updated", pose_callable)

func _on_mediapipe_pose_updated(landmarks: Array) -> void:
	_latest_pose_landmarks = landmarks.duplicate(true)
	if _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("update_overlay"):
		_mediapipe_camera_view.update_overlay(_latest_pose_landmarks)

func _animate_world_reference(delta: float) -> void:
	var elapsed := float(Time.get_ticks_msec()) / 1000.0
	for marker_variant: Variant in _animated_world_markers:
		var marker: Dictionary = marker_variant
		var node := marker.get("node") as Node3D
		if node == null:
			continue
		var base_position: Vector3 = marker.get("base_position", node.position)
		var sway := float(marker.get("sway", 0.0))
		var speed := float(marker.get("speed", 1.0))
		node.position = base_position + Vector3(0.0, sin(elapsed * speed) * sway * 0.25, cos(elapsed * speed * 0.5) * sway)
		node.rotate_y(delta * speed * 0.22)

func _build_trace_context() -> Dictionary:
	var active_profile: Dictionary = _controller.get_debug_state().get("active_profile", {}) if _controller.get_debug_state().get("active_profile", {}) is Dictionary else {}
	return {
		"session_prefix": "camera_gesture_trace",
		"fixture_key": _fixture_key_edit.text.strip_edges(),
		"fixture_video_path": _fixture_video_path_edit.text.strip_edges(),
		"fixture_sidecar_path": _fixture_sidecar_path_edit.text.strip_edges(),
		"profile_path_edit": _profile_path_edit.text.strip_edges(),
		"source_mode": _source_mode,
		"active_profile": active_profile,
	}

func _default_profile_absolute_path() -> String:
	return ProjectSettings.globalize_path("res://%s" % DEFAULT_PROFILE_REPO_RELATIVE_PATH)

func _normalized_profile_export_path() -> String:
	var target_path := _profile_path_edit.text.strip_edges()
	if target_path.is_empty():
		target_path = TESTBED_PROFILE_EXPORT_PATH
	if not target_path.ends_with(".yaml") and not target_path.ends_with(".yml"):
		target_path += ".camera_gesture.yaml"
	return target_path

func _ensure_parent_dir_for_file(path: String) -> void:
	var normalized := path.strip_edges()
	if normalized.is_empty():
		return
	var globalized := normalized
	if normalized.begins_with("res://") or normalized.begins_with("user://"):
		globalized = ProjectSettings.globalize_path(normalized)
	elif not normalized.begins_with("/"):
		globalized = ProjectSettings.globalize_path("user://%s" % normalized)
	var base_dir := globalized.get_base_dir()
	if not base_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(base_dir)

func _coerce_vector3(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Vector2:
		var vector2: Vector2 = value
		return Vector3(vector2.x, vector2.y, 0.0)
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO

func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	return button

func _add_section_panel(parent: VBoxContainer, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 18)
	column.add_child(label)
	return column

func _labeled_control(label_text: String, control: Control) -> VBoxContainer:
	var column := VBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	column.add_child(label)
	column.add_child(control)
	return column

func _add_debug_tab(tabs: TabContainer, title: String) -> RichTextLabel:
	var container := VBoxContainer.new()
	container.name = title
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var label := RichTextLabel.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.scroll_active = true
	container.add_child(label)
	tabs.add_child(container)
	tabs.set_tab_title(tabs.get_tab_count() - 1, title)
	return label

func _add_toggle(parent: VBoxContainer, label_text: String, default_value: bool, callback: Callable) -> CheckBox:
	var box := CheckBox.new()
	box.text = label_text
	box.button_pressed = default_value
	box.toggled.connect(func(_pressed: bool) -> void: callback.call())
	parent.add_child(box)
	return box

func _add_slider(parent: VBoxContainer, label_text: String, min_value: float, max_value: float, step: float, default_value: float, callback: Callable) -> HSlider:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = default_value
	slider.value_changed.connect(func(_value: float) -> void: callback.call())
	parent.add_child(slider)
	return slider

func _add_option(parent: VBoxContainer, label_text: String, values: Array, callback: Callable) -> OptionButton:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var option := OptionButton.new()
	for value in values:
		option.add_item(value)
	option.item_selected.connect(func(_index: int) -> void: callback.call())
	parent.add_child(option)
	return option

func _set_option_value(option: OptionButton, value: String) -> void:
	for index in range(option.item_count):
		if option.get_item_text(index) == value:
			option.select(index)
			return
	option.select(0)

func _get_option_value(option: OptionButton) -> String:
	return option.get_item_text(option.selected)

func _on_profile_field_changed() -> void:
	_apply_ui_to_controller_profile()

func _on_fake_control_changed() -> void:
	_update_status("Updated fake source controls")

func _on_source_mode_selected() -> void:
	_switch_input_source(_get_option_value(_source_option))

func _on_controller_mode_changed(mode: String) -> void:
	_preview_title_label.text = "3D World Preview (%s)" % mode

func _on_tracking_state_changed(state: Dictionary) -> void:
	_tracking_label.text = "Tracking: %s | confidence %.2f / %.2f" % [
		"active" if bool(state.get("tracking", false)) else "inactive",
		float(state.get("confidence", 0.0)),
		float(state.get("threshold", 0.0)),
	]

func _on_profile_loaded(_profile: Dictionary) -> void:
	_update_status("Profile loaded")
	if _trace_store.is_capturing():
		_trace_store.append_note("profile_loaded", {"path": _profile_path_edit.text.strip_edges()})

func _on_profile_saved(path: String) -> void:
	_update_status("Profile saved to %s" % path)
	if _trace_store.is_capturing():
		_trace_store.append_note("profile_saved", {"path": path})

func _update_status(message: String) -> void:
	_status_label.text = "Status: %s" % message
