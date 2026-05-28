extends Control

const CONTROLLER_SCRIPT := preload("res://addons/aerobeat-tool-camera-gesture-control/src/camera_gesture_controller.gd")
const FAKE_INPUT_SOURCE_SCRIPT := preload("res://scripts/fake_camera_input_source.gd")
const TRACKING_INSET_OVERLAY_SCRIPT := preload("res://scripts/tracking_inset_overlay.gd")
const TRACE_CAPTURE_STORE_SCRIPT := preload("res://scripts/trace_capture_store.gd")
const FIXTURE_RUNTIME_CONFIG_SCRIPT := preload("res://scripts/camera_gesture_fixture_runtime_config.gd")

const DEFAULT_PROFILE_REPO_RELATIVE_PATH := "../assets/profiles/camera_gesture/default_v1.camera_gesture.yaml"
const TESTBED_PROFILE_EXPORT_PATH := "user://camera_gesture_profiles/working.camera_gesture.yaml"
const TRACE_EXPORT_ROOT := "user://trace_exports/camera_gesture"
const DEFAULT_FIXTURE_VIDEO_PATH := "res://assets/fixtures/camera_gesture/head_pose/candidates/head_rotate_left_repeat_04_take_01.mp4"
const DEFAULT_FIXTURE_SIDECAR_PATH := "res://assets/fixtures/camera_gesture/head_pose/candidates/head_rotate_left_repeat_04_take_01.fixture.yaml"
const MEDIAPIPE_PROVIDER_PATH := "res://addons/aerobeat-input-mediapipe-python/src/input_provider.gd"
const MEDIAPIPE_CAMERA_VIEW_PATH := "res://addons/aerobeat-input-mediapipe-python/src/camera_view.gd"
const MEDIAPIPE_AUTOSTART_MANAGER_PATH := "res://addons/aerobeat-input-mediapipe-python/src/autostart_manager.gd"
const VIDEO_PLAYER_MANAGER_PATH := "res://addons/aerobeat-tool-video-player/src/AeroVideoPlayerManager.gd"
const GODOT_VIDEO_BACKEND_PATH := "res://addons/aerobeat-vendor-godot-video/src/AeroGodotVideoBackend.gd"
const PROVIDER_SESSION_REGISTRY_PATH := "res://addons/aerobeat-input-core/src/runtime/provider_session_registry.gd"
const DEFAULT_MEDIAPIPE_STREAM_URL := "http://127.0.0.1:4243/camera"
const DEFAULT_TESTBED_VIEWPORT_SIZE := Vector2i(960, 540)
const PREVIEW_STACK_MIN_SIZE := Vector2(640.0, 360.0)
const LEFT_PANEL_SPLIT_OFFSET := 360
const LEFT_PANEL_MIN_WIDTH := 340
const MEDIA_INSET_WIDTH := 416.0
const MEDIA_INSET_HEIGHT := 296.0
const CAMERA_FEED_MIN_HEIGHT := 236.0
const DEBUG_TABS_MIN_HEIGHT := 180.0
const PREVIEW_CORNER_MARGIN := 20.0
const MEDIA_INSET_COLLAPSED_HEIGHT := 52.0
const TOGGLE_GLYPH_EXPANDED := "▾"
const TOGGLE_GLYPH_COLLAPSED := "▸"
const LEFT_PANEL_FONT_SIZE := 15
const LEFT_PANEL_INPUT_FONT_SIZE := 14
const STATUS_LABEL_FONT_SIZE := 16
const SECTION_TITLE_FONT_SIZE := 18
const TITLE_FONT_SIZE := 26
const PREVIEW_TITLE_FONT_SIZE := 22
const MEDIA_TITLE_FONT_SIZE := 18
const MEDIAPIPE_SESSION_OWNER_ID := "aerobeat-tool-camera-gesture-control:testbed"
const MEDIAPIPE_SESSION_CONSUMER_ID := "aerobeat-tool-camera-gesture-control:testbed_consumer"
const MEDIAPIPE_SESSION_KEY := "mediapipe_python/camera_gesture_testbed"
const SOURCE_MODE_FAKE := "fake"
const SOURCE_MODE_MEDIAPIPE_LIVE := "mediapipe_live"
const SOURCE_MODE_MEDIAPIPE_REPLAY := "mediapipe_replay"
const SOURCE_OPTIONS := [SOURCE_MODE_FAKE, SOURCE_MODE_MEDIAPIPE_LIVE, SOURCE_MODE_MEDIAPIPE_REPLAY]
const CONTROL_MODE_OPTIONS := ["gesture", "mouse_wasd", "disabled"]
const SAMPLE_SOURCE_OPTIONS := ["head_position", "head_velocity", "head_rotation"]
const TRACE_LEVEL_OPTIONS := ["off", "basic", "verbose"]
const MEDIAPIPE_TRACKING_QUALITY_OPTIONS := ["none", "optimized", "full"]
const MEDIAPIPE_TRACKING_QUALITY_PRESETS := {
	"none": {
		"min_visibility": 0.35,
		"tracking_overlay_mode": "off",
		"gesture_eval_interval_frames": 1,
	},
	"optimized": {
		"min_visibility": 0.35,
		"tracking_overlay_mode": "optimized",
		"gesture_eval_interval_frames": 1,
	},
	"full": {
		"min_visibility": 0.35,
		"tracking_overlay_mode": "full",
		"gesture_eval_interval_frames": 1,
	},
}
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
var _mediapipe_live_camera_option: OptionButton
var _mediapipe_tracking_quality_option: OptionButton
var _profile_path_edit: LineEdit
var _trace_export_root_edit: LineEdit
var _fixture_key_edit: LineEdit
var _fixture_video_path_edit: LineEdit
var _fixture_sidecar_path_edit: LineEdit
var _fixture_runtime_helper = null
var _mediapipe_live_camera_row: VBoxContainer
var _mediapipe_tracking_quality_row: VBoxContainer
var _mediapipe_live_note_label: Label
var _fixture_runtime_config := {}
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
var _media_inset_panel: PanelContainer
var _media_title_label: Label
var _media_inset_toggle_button: Button
var _field_refs := {}
var _fake_controls := {}
var _current_input_source: Node = null
var _fake_input_source: FakeCameraInputSource
var _mediapipe_input_source: Node = null
var _mediapipe_provider_backend: Node = null
var _mediapipe_camera_view = null
var _mediapipe_autostart_manager: Node = null
var _video_player_manager: Node = null
var _video_player_surface: Control = null
var _video_player_last_loaded_source := ""
var _video_player_last_error := ""
var _mediapipe_runtime_signature := ""
var _mediapipe_runtime_status := "inactive"
var _mediapipe_runtime_last_error := ""
var _mediapipe_runtime_request_serial := 0
var _mediapipe_owned_restart_cleanup_pending := false
var _mediapipe_controller_reattach_pending := false
var _mediapipe_input_source_is_borrowed := false
var _mediapipe_owned_session_key := ""
var _mediapipe_borrowed_session_key := ""
var _mediapipe_session_owner_id := ""
var _mediapipe_session_metadata := {}
var _mediapipe_available_camera_devices: Array = []
var _selected_mediapipe_live_camera_id := "0"
var _selected_mediapipe_tracking_quality := "full"
var _suppress_mediapipe_live_camera_signal := false
var _suppress_mediapipe_tracking_quality_signal := false
var _source_mode := SOURCE_MODE_FAKE
var _latest_provider_state := {}
var _latest_source_snapshot := {}
var _latest_pose_landmarks: Array = []
var _recent_trace_frames: Array = []
var _animated_world_markers: Array = []
var _preview_title_label: Label
var _left_panel: VBoxContainer
var _profile_section_content: VBoxContainer
var _source_section_content: VBoxContainer
var _trace_section_content: VBoxContainer
var _tuning_section_content: VBoxContainer
var _fake_section_content: VBoxContainer
var _debug_tabs: TabContainer
var _debug_tabs_toggle_button: Button

func _ready() -> void:
	name = "CameraGestureControlTestbed"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_trace_store = TRACE_CAPTURE_STORE_SCRIPT.new()
	_fixture_runtime_helper = FIXTURE_RUNTIME_CONFIG_SCRIPT.new()
	_controller = CONTROLLER_SCRIPT.new()
	add_child(_controller)
	_controller.control_mode_changed.connect(_on_controller_mode_changed)
	_controller.tracking_state_changed.connect(_on_tracking_state_changed)
	_controller.profile_loaded.connect(_on_profile_loaded)
	_controller.profile_saved.connect(_on_profile_saved)

	_bind_layout_nodes()
	_populate_layout_controls()
	_build_world()
	_setup_sources()
	_controller.attach_camera(_camera)
	_load_default_profile_on_boot()
	_apply_profile_to_ui(_controller.get_profile())
	_refresh_fixture_runtime_config(true)
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
	_tracking_overlay.set_display_rect(_current_tracking_overlay_display_rect())
	_tracking_overlay.update_snapshot(_latest_source_snapshot)
	_capture_trace_frame_if_needed()
	_update_debug_surfaces()

func _notification(what: int) -> void:
	if what != NOTIFICATION_EXIT_TREE:
		return
	if _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("stop_stream"):
		_mediapipe_camera_view.stop_stream()
	_reset_video_player_surface()
	_teardown_mediapipe_runtime()

func _bind_layout_nodes() -> void:
	var root_split := get_node("RootMargin/RootSplit") as HSplitContainer
	root_split.split_offset = LEFT_PANEL_SPLIT_OFFSET

	var left_scroll := get_node("RootMargin/RootSplit/LeftPanelScroll") as ScrollContainer
	left_scroll.custom_minimum_size = Vector2(LEFT_PANEL_MIN_WIDTH, 0.0)

	_left_panel = get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel") as VBoxContainer
	_left_panel.custom_minimum_size = Vector2(LEFT_PANEL_MIN_WIDTH, 0.0)

	var title := get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/HeaderPanel/HeaderMargin/HeaderColumn/TitleLabel") as Label
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)

	
	_status_label = get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/HeaderPanel/HeaderMargin/HeaderColumn/StatusLabel") as Label
	_status_label.add_theme_font_size_override("font_size", STATUS_LABEL_FONT_SIZE)

	_source_label = get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/HeaderPanel/HeaderMargin/HeaderColumn/SourceLabel") as Label
	_source_label.add_theme_font_size_override("font_size", STATUS_LABEL_FONT_SIZE)

	_tracking_label = get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/HeaderPanel/HeaderMargin/HeaderColumn/TrackingLabel") as Label
	_tracking_label.add_theme_font_size_override("font_size", STATUS_LABEL_FONT_SIZE)

	_profile_identity_label = get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/HeaderPanel/HeaderMargin/HeaderColumn/ProfileIdentityLabel") as Label
	_profile_identity_label.add_theme_font_size_override("font_size", STATUS_LABEL_FONT_SIZE)

	_profile_section_content = get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/ProfileSection/ProfileMargin/ProfileSectionContent") as VBoxContainer
	_source_section_content = get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/SourceSection/SourceMargin/SourceSectionContent") as VBoxContainer
	_trace_section_content = get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/TraceSection/TraceMargin/TraceSectionContent") as VBoxContainer
	_tuning_section_content = get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/TuningSection/TuningMargin/TuningSectionContent") as VBoxContainer
	_fake_section_content = get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/FakeSection/FakeMargin/FakeSectionContent") as VBoxContainer

	var preview_stack := get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack") as Control
	preview_stack.custom_minimum_size = PREVIEW_STACK_MIN_SIZE

	_subviewport = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/WorldPreviewViewportContainer/WorldPreviewViewport") as SubViewport

	_preview_title_label = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/OverlayTop/PreviewTitleLabel") as Label
	_preview_title_label.add_theme_font_size_override("font_size", PREVIEW_TITLE_FONT_SIZE)
	_preview_stats_label = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/OverlayTop/PreviewStatsLabel") as RichTextLabel

	_media_inset_panel = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel") as PanelContainer
	_media_inset_panel.offset_left = -MEDIA_INSET_WIDTH - PREVIEW_CORNER_MARGIN
	_media_inset_panel.offset_top = -MEDIA_INSET_HEIGHT - PREVIEW_CORNER_MARGIN
	_media_inset_panel.offset_right = -PREVIEW_CORNER_MARGIN
	_media_inset_panel.offset_bottom = -PREVIEW_CORNER_MARGIN

	_media_title_label = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/MediaToolbar/MediaTitleLabel") as Label
	_media_title_label.visible = true
	_media_title_label.add_theme_font_size_override("font_size", MEDIA_TITLE_FONT_SIZE)
	_media_inset_toggle_button = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/MediaToolbar/MediaInsetToggleButton") as Button
	_media_inset_toggle_button.toggled.connect(_on_media_inset_toggle_toggled)

	_camera_feed_host = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/CameraFeedHost") as Control
	_camera_feed_host.custom_minimum_size = Vector2(0.0, CAMERA_FEED_MIN_HEIGHT)
	_media_inset_placeholder = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/CameraFeedHost/MediaInsetPlaceholder") as ColorRect
	_media_placeholder_label = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/CameraFeedHost/MediaInsetPlaceholder/MediaPlaceholderLabel") as Label
	_media_placeholder_label.visible = true
	_tracking_overlay = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/CameraFeedHost/TrackingInsetOverlay") as CameraGestureTrackingInsetOverlay
	_media_inset_status_label = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/MediaInsetStatusLabel") as Label
	_media_inset_status_label.visible = true

	_debug_tabs_toggle_button = get_node("RootMargin/RootSplit/RightColumn/DebugToolbar/DebugTabsToggleButton") as Button
	_debug_tabs_toggle_button.toggled.connect(_on_debug_tabs_toggle_toggled)
	_debug_tabs = get_node("RootMargin/RootSplit/RightColumn/DebugTabs") as TabContainer
	_debug_tabs.custom_minimum_size = Vector2(0.0, DEBUG_TABS_MIN_HEIGHT)
	_runtime_debug_label = get_node("RootMargin/RootSplit/RightColumn/DebugTabs/Runtime/RuntimeMargin/RuntimeDebugLabel") as RichTextLabel
	_trace_debug_label = get_node("RootMargin/RootSplit/RightColumn/DebugTabs/Trace/TraceMargin/TraceDebugLabel") as RichTextLabel
	_fixture_debug_label = get_node("RootMargin/RootSplit/RightColumn/DebugTabs/Fixture/FixtureMargin/FixtureDebugLabel") as RichTextLabel
	_provider_debug_label = get_node("RootMargin/RootSplit/RightColumn/DebugTabs/Provider/ProviderMargin/ProviderDebugLabel") as RichTextLabel
	_apply_media_inset_visibility(_media_inset_toggle_button.button_pressed)
	_apply_debug_tabs_visibility(_debug_tabs_toggle_button.button_pressed)

func _populate_layout_controls() -> void:
	_profile_section_content.get_node("SectionTitleLabel").add_theme_font_size_override("font_size", SECTION_TITLE_FONT_SIZE)
	_source_section_content.get_node("SectionTitleLabel").add_theme_font_size_override("font_size", SECTION_TITLE_FONT_SIZE)
	_trace_section_content.get_node("SectionTitleLabel").add_theme_font_size_override("font_size", SECTION_TITLE_FONT_SIZE)
	_tuning_section_content.get_node("SectionTitleLabel").add_theme_font_size_override("font_size", SECTION_TITLE_FONT_SIZE)
	_fake_section_content.get_node("SectionTitleLabel").add_theme_font_size_override("font_size", SECTION_TITLE_FONT_SIZE)

	var default_profile_hint := Label.new()
	default_profile_hint.name = "DefaultProfileHint"
	default_profile_hint.text = "Checked-in default: %s" % _default_profile_absolute_path()
	default_profile_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_profile_section_content.add_child(default_profile_hint)

	_profile_path_edit = LineEdit.new()
	_profile_path_edit.name = "ProfilePathEdit"
	_profile_path_edit.placeholder_text = "Path used for load/reload/export"
	_profile_path_edit.text = TESTBED_PROFILE_EXPORT_PATH
	_profile_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profile_section_content.add_child(_profile_path_edit)

	var profile_buttons_top := HFlowContainer.new()
	profile_buttons_top.name = "ProfileButtonsTop"
	profile_buttons_top.add_theme_constant_override("h_separation", 8)
	profile_buttons_top.add_theme_constant_override("v_separation", 8)
	_profile_section_content.add_child(profile_buttons_top)
	profile_buttons_top.add_child(_make_button("Load default YAML", _load_default_profile))
	profile_buttons_top.add_child(_make_button("Load path", _load_profile_from_path))
	profile_buttons_top.add_child(_make_button("Reload path", _reload_profile_from_path))

	var profile_buttons_bottom := HFlowContainer.new()
	profile_buttons_bottom.name = "ProfileButtonsBottom"
	profile_buttons_bottom.add_theme_constant_override("h_separation", 8)
	profile_buttons_bottom.add_theme_constant_override("v_separation", 8)
	_profile_section_content.add_child(profile_buttons_bottom)
	profile_buttons_bottom.add_child(_make_button("Export YAML snapshot", _export_profile_to_path))
	profile_buttons_bottom.add_child(_make_button("Reset runtime defaults", _reset_profile))

	_source_option = _add_option(_source_section_content, "Input source", SOURCE_OPTIONS, _on_source_mode_selected)

	_mediapipe_live_camera_option = OptionButton.new()
	_mediapipe_live_camera_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mediapipe_live_camera_option.item_selected.connect(_on_mediapipe_live_camera_selected)
	_mediapipe_live_camera_row = _labeled_control("Live camera", _mediapipe_live_camera_option)
	_source_section_content.add_child(_mediapipe_live_camera_row)

	_mediapipe_tracking_quality_option = OptionButton.new()
	_mediapipe_tracking_quality_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for quality in MEDIAPIPE_TRACKING_QUALITY_OPTIONS:
		_mediapipe_tracking_quality_option.add_item(quality)
	_mediapipe_tracking_quality_option.item_selected.connect(_on_mediapipe_tracking_quality_selected)
	_mediapipe_tracking_quality_row = _labeled_control("Tracking quality", _mediapipe_tracking_quality_option)
	_source_section_content.add_child(_mediapipe_tracking_quality_row)

	_mediapipe_live_note_label = Label.new()
	_mediapipe_live_note_label.text = "Live webcam parity controls mirror the proving flow camera source + tracking overlay tuning."
	_mediapipe_live_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_source_section_content.add_child(_mediapipe_live_note_label)
	_set_option_value(_mediapipe_tracking_quality_option, _selected_mediapipe_tracking_quality)
	_fixture_key_edit = LineEdit.new()
	_fixture_key_edit.name = "FixtureKeyEdit"
	_fixture_key_edit.placeholder_text = "Fixture key / intent family"
	_fixture_key_edit.text = "camera_gesture/head_pose/head_rotate_left_repeat_04_take_01"
	_fixture_key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_source_section_content.add_child(_labeled_control("Fixture key", _fixture_key_edit))

	_fixture_video_path_edit = LineEdit.new()
	_fixture_video_path_edit.name = "FixtureVideoPathEdit"
	_fixture_video_path_edit.placeholder_text = "Fixture video path used for replay mode"
	_fixture_video_path_edit.text = DEFAULT_FIXTURE_VIDEO_PATH
	_fixture_video_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_source_section_content.add_child(_labeled_control("Fixture video path", _fixture_video_path_edit))

	_fixture_sidecar_path_edit = LineEdit.new()
	_fixture_sidecar_path_edit.name = "FixtureSidecarPathEdit"
	_fixture_sidecar_path_edit.placeholder_text = "Fixture sidecar YAML path"
	_fixture_sidecar_path_edit.text = DEFAULT_FIXTURE_SIDECAR_PATH
	_fixture_sidecar_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_source_section_content.add_child(_labeled_control("Fixture sidecar path", _fixture_sidecar_path_edit))

	var source_buttons := HFlowContainer.new()
	source_buttons.name = "SourceButtons"
	source_buttons.add_theme_constant_override("h_separation", 8)
	source_buttons.add_theme_constant_override("v_separation", 8)
	_source_section_content.add_child(source_buttons)
	source_buttons.add_child(_make_button("Apply source / restart runtime", _apply_source_runtime_selection))
	source_buttons.add_child(_make_button("Refresh fixture hints", _refresh_fixture_runtime_from_ui))

	var fixture_note := Label.new()
	fixture_note.text = "Replay mode now launches MediaPipe through AutoStartManager with the selected fixture video, sidecar hints can steer the runtime sample source, and trace export stays structured for later oracle work."
	fixture_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_source_section_content.add_child(fixture_note)

	_trace_export_root_edit = LineEdit.new()
	_trace_export_root_edit.name = "TraceExportRootEdit"
	_trace_export_root_edit.placeholder_text = "Trace export root"
	_trace_export_root_edit.text = TRACE_EXPORT_ROOT
	_trace_export_root_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_trace_section_content.add_child(_labeled_control("Trace export root", _trace_export_root_edit))

	var trace_buttons := HFlowContainer.new()
	trace_buttons.name = "TraceButtons"
	trace_buttons.add_theme_constant_override("h_separation", 8)
	trace_buttons.add_theme_constant_override("v_separation", 8)
	_trace_section_content.add_child(trace_buttons)
	trace_buttons.add_child(_make_button("Start capture", _start_trace_capture))
	trace_buttons.add_child(_make_button("Stop + export", _stop_and_export_trace_capture))

	var trace_buttons_bottom := HFlowContainer.new()
	trace_buttons_bottom.name = "TraceButtonsBottom"
	trace_buttons_bottom.add_theme_constant_override("h_separation", 8)
	trace_buttons_bottom.add_theme_constant_override("v_separation", 8)
	_trace_section_content.add_child(trace_buttons_bottom)
	trace_buttons_bottom.add_child(_make_button("Export snapshot now", _export_trace_snapshot))
	trace_buttons_bottom.add_child(_make_button("Clear trace buffer", _clear_recent_trace))

	_trace_status_label = Label.new()
	_trace_status_label.name = "TraceStatusLabel"
	_trace_status_label.text = "Trace: idle"
	_trace_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_trace_section_content.add_child(_trace_status_label)

	_field_refs["enabled"] = _add_toggle(_tuning_section_content, "Enabled", true, _on_profile_field_changed)
	_field_refs["mode"] = _add_option(_tuning_section_content, "Control mode", CONTROL_MODE_OPTIONS, _on_profile_field_changed)
	_field_refs["sample_source"] = _add_option(_tuning_section_content, "Sample source", SAMPLE_SOURCE_OPTIONS, _on_profile_field_changed)
	_field_refs["debug_trace_level"] = _add_option(_tuning_section_content, "Debug trace level", TRACE_LEVEL_OPTIONS, _on_profile_field_changed)
	_field_refs["invert_x"] = _add_toggle(_tuning_section_content, "Invert X", false, _on_profile_field_changed)
	_field_refs["invert_y"] = _add_toggle(_tuning_section_content, "Invert Y", false, _on_profile_field_changed)
	_field_refs["freeze_on_tracking_loss"] = _add_toggle(_tuning_section_content, "Freeze on tracking loss", true, _on_profile_field_changed)
	_field_refs["look_sensitivity_x"] = _add_slider(_tuning_section_content, "Look sensitivity X", 0.1, 3.0, 0.05, 1.0, _on_profile_field_changed)
	_field_refs["look_sensitivity_y"] = _add_slider(_tuning_section_content, "Look sensitivity Y", 0.1, 3.0, 0.05, 1.0, _on_profile_field_changed)
	_field_refs["translation_sensitivity_x"] = _add_slider(_tuning_section_content, "Translation sensitivity X", 0.1, 3.0, 0.05, 1.0, _on_profile_field_changed)
	_field_refs["translation_sensitivity_y"] = _add_slider(_tuning_section_content, "Translation sensitivity Y", 0.1, 3.0, 0.05, 0.6, _on_profile_field_changed)
	_field_refs["translation_sensitivity_z"] = _add_slider(_tuning_section_content, "Translation sensitivity Z", 0.1, 3.0, 0.05, 0.4, _on_profile_field_changed)
	_field_refs["max_yaw_degrees"] = _add_slider(_tuning_section_content, "Max yaw degrees", 0.0, 60.0, 1.0, 20.0, _on_profile_field_changed)
	_field_refs["max_pitch_degrees"] = _add_slider(_tuning_section_content, "Max pitch degrees", 0.0, 45.0, 1.0, 12.0, _on_profile_field_changed)
	_field_refs["max_roll_degrees"] = _add_slider(_tuning_section_content, "Max roll degrees", 0.0, 30.0, 1.0, 4.0, _on_profile_field_changed)
	_field_refs["max_translation_x"] = _add_slider(_tuning_section_content, "Max translation X", 0.0, 2.0, 0.01, 0.6, _on_profile_field_changed)
	_field_refs["max_translation_y"] = _add_slider(_tuning_section_content, "Max translation Y", 0.0, 2.0, 0.01, 0.35, _on_profile_field_changed)
	_field_refs["max_translation_z"] = _add_slider(_tuning_section_content, "Max translation Z", 0.0, 2.0, 0.01, 0.45, _on_profile_field_changed)
	_field_refs["smoothing"] = _add_slider(_tuning_section_content, "Smoothing", 0.0, 1.0, 0.01, 0.2, _on_profile_field_changed)
	_field_refs["deadzone"] = _add_slider(_tuning_section_content, "Deadzone", 0.0, 0.5, 0.01, 0.03, _on_profile_field_changed)
	_field_refs["recenter_speed"] = _add_slider(_tuning_section_content, "Recenter speed", 0.0, 10.0, 0.1, 1.8, _on_profile_field_changed)
	_field_refs["tracking_confidence_threshold"] = _add_slider(_tuning_section_content, "Tracking confidence threshold", 0.0, 1.0, 0.01, 0.45, _on_profile_field_changed)

	_fake_controls["tracking"] = _add_toggle(_fake_section_content, "Fake tracking active", true, _on_fake_control_changed)
	_fake_controls["confidence"] = _add_slider(_fake_section_content, "Fake confidence", 0.0, 1.0, 0.01, 1.0, _on_fake_control_changed)
	_fake_controls["animate"] = _add_toggle(_fake_section_content, "Animate fake input", true, _on_fake_control_changed)
	_fake_controls["animation_speed"] = _add_slider(_fake_section_content, "Fake animation speed", 0.1, 4.0, 0.1, 1.0, _on_fake_control_changed)

	_apply_left_panel_readability_theme(_left_panel)

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
		var marker_material := StandardMaterial3D.new()
		marker_material.albedo_color = config.get("color", Color.WHITE)
		mesh.material_override = marker_material
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

	_ensure_mediapipe_camera_view_if_possible()
	if _source_option == null:
		return
	if not ResourceLoader.exists(MEDIAPIPE_PROVIDER_PATH):
		_source_mode = SOURCE_MODE_FAKE
		_source_option.select(0)
		for item_index in range(1, _source_option.item_count):
			_source_option.set_item_disabled(item_index, true)
	elif not ResourceLoader.exists(MEDIAPIPE_AUTOSTART_MANAGER_PATH):
		var replay_index := SOURCE_OPTIONS.find(SOURCE_MODE_MEDIAPIPE_REPLAY)
		if replay_index >= 0:
			_source_option.set_item_disabled(replay_index, true)

func _switch_input_source(mode: String) -> void:
	_refresh_fixture_runtime_config(false)
	_source_mode = mode if SOURCE_OPTIONS.has(mode) else SOURCE_MODE_FAKE
	match _source_mode:
		SOURCE_MODE_MEDIAPIPE_LIVE, SOURCE_MODE_MEDIAPIPE_REPLAY:
			if _ensure_mediapipe_input_source(_source_mode) and _controller.attach_input_source(_mediapipe_input_source):
				_current_input_source = _mediapipe_input_source
				_wire_mediapipe_backend_if_possible()
				_ensure_mediapipe_runtime_for_active_source()
				_update_status("Using %s input source" % _source_mode_label(_source_mode))
			else:
				_release_borrowed_mediapipe_session()
				_current_input_source = _fake_input_source
				_controller.attach_input_source(_fake_input_source)
				_source_mode = SOURCE_MODE_FAKE
				if _source_option != null:
					_source_option.select(0)
				_update_status("MediaPipe unavailable; fell back to fake source")
		_:
			_release_borrowed_mediapipe_session()
			_reset_mediapipe_autostart_manager()
			_current_input_source = _fake_input_source
			_controller.attach_input_source(_fake_input_source)
			_update_status("Using fake input source")
	_source_label.text = _build_source_status_line()
	_refresh_mediapipe_live_controls_visibility()
	_refresh_mediapipe_live_control_values()
	for control in _fake_controls.values():
		control.visible = _current_input_source == _fake_input_source
	_refresh_media_inset_surface()

func _apply_source_runtime_selection() -> void:
	_refresh_fixture_runtime_config(true)
	_switch_input_source(_get_option_value(_source_option))

func _refresh_fixture_runtime_from_ui() -> void:
	_refresh_fixture_runtime_config(true)
	_update_status("Refreshed fixture runtime hints")

func _refresh_fixture_runtime_config(update_fields: bool = false) -> Dictionary:
	if _fixture_runtime_helper == null:
		return _fixture_runtime_config
	_fixture_runtime_config = _fixture_runtime_helper.resolve(
		_fixture_video_path_edit.text,
		_fixture_sidecar_path_edit.text
	)
	if update_fields:
		var effective_video: Dictionary = _fixture_runtime_config.get("effective_video", {}) if _fixture_runtime_config.get("effective_video", {}) is Dictionary else {}
		var sidecar: Dictionary = _fixture_runtime_config.get("sidecar", {}) if _fixture_runtime_config.get("sidecar", {}) is Dictionary else {}
		if bool(sidecar.get("exists", false)):
			_fixture_sidecar_path_edit.text = str(sidecar.get("display_path", _fixture_sidecar_path_edit.text))
		if bool(effective_video.get("exists", false)):
			_fixture_video_path_edit.text = str(effective_video.get("display_path", _fixture_video_path_edit.text))
		var fixture_key := str(_fixture_runtime_config.get("fixture_key", "")).strip_edges()
		if not fixture_key.is_empty():
			_fixture_key_edit.text = fixture_key
	_apply_fixture_runtime_hints(_fixture_runtime_config)
	return _fixture_runtime_config

func _apply_fixture_runtime_hints(config: Dictionary) -> void:
	var sample_source_hint := str(config.get("sample_source_hint", "")).strip_edges()
	if sample_source_hint.is_empty() or not _field_refs.has("sample_source"):
		return
	_set_option_value(_field_refs["sample_source"], sample_source_hint)
	_apply_ui_to_controller_profile()

func _provider_session_registry_available() -> bool:
	return ResourceLoader.exists(PROVIDER_SESSION_REGISTRY_PATH)

func _load_provider_session_registry():
	if not _provider_session_registry_available():
		return null
	return load(PROVIDER_SESSION_REGISTRY_PATH)

func _ensure_mediapipe_input_source(requested_mode: String) -> bool:
	if _mediapipe_input_source != null and is_instance_valid(_mediapipe_input_source):
		if _mediapipe_input_source_is_borrowed:
			var requested_metadata := _build_mediapipe_session_metadata_for_mode(requested_mode)
			var borrowed_runtime_mode := str(_mediapipe_session_metadata.get("runtime_mode", "")).strip_edges()
			var borrowed_camera := str(_mediapipe_session_metadata.get("camera_source", "")).strip_edges()
			var borrowed_overlay_mode := str(_mediapipe_session_metadata.get("tracking_overlay_mode", "")).strip_edges()
			var borrowed_interval := int(_mediapipe_session_metadata.get("gesture_eval_interval_frames", 1))
			var borrowed_matches_request := false
			if borrowed_runtime_mode.is_empty() or borrowed_runtime_mode == _source_mode_runtime_label(requested_mode):
				borrowed_matches_request = (
					borrowed_camera == str(requested_metadata.get("camera_source", "")).strip_edges()
					and borrowed_overlay_mode == str(requested_metadata.get("tracking_overlay_mode", "")).strip_edges()
					and borrowed_interval == int(requested_metadata.get("gesture_eval_interval_frames", 1))
				)
			if borrowed_matches_request:
				return true
			_release_borrowed_mediapipe_session()
		else:
			_apply_local_mediapipe_runtime_settings(requested_mode)
			_apply_mediapipe_session_metadata({"metadata": _build_mediapipe_session_metadata_for_mode(requested_mode)})
			_publish_owned_mediapipe_session()
			return true
	if _try_acquire_shared_mediapipe_session(requested_mode):
		return true
	return _start_local_mediapipe_input_source(requested_mode)

func _try_acquire_shared_mediapipe_session(requested_mode: String) -> bool:
	if _mediapipe_input_source != null and is_instance_valid(_mediapipe_input_source) and _mediapipe_input_source_is_borrowed:
		var requested_metadata := _build_mediapipe_session_metadata_for_mode(requested_mode)
		var borrowed_runtime_mode := str(_mediapipe_session_metadata.get("runtime_mode", "")).strip_edges()
		var borrowed_camera := str(_mediapipe_session_metadata.get("camera_source", "")).strip_edges()
		var borrowed_overlay_mode := str(_mediapipe_session_metadata.get("tracking_overlay_mode", "")).strip_edges()
		var borrowed_interval := int(_mediapipe_session_metadata.get("gesture_eval_interval_frames", 1))
		var borrowed_matches_request := false
		if borrowed_runtime_mode.is_empty() or borrowed_runtime_mode == _source_mode_runtime_label(requested_mode):
			borrowed_matches_request = (
				borrowed_camera == str(requested_metadata.get("camera_source", "")).strip_edges()
				and borrowed_overlay_mode == str(requested_metadata.get("tracking_overlay_mode", "")).strip_edges()
				and borrowed_interval == int(requested_metadata.get("gesture_eval_interval_frames", 1))
			)
		if borrowed_matches_request:
			return true
		_release_borrowed_mediapipe_session()
	var registry = _load_provider_session_registry()
	if registry == null:
		return false
	var requested_metadata := _build_mediapipe_session_metadata_for_mode(requested_mode)
	var request_filters := {
		"provider_id": "mediapipe_python",
		"metadata_match": {
			"runtime_mode": str(requested_metadata.get("runtime_mode", "")),
			"camera_source": str(requested_metadata.get("camera_source", "")),
			"tracking_overlay_mode": str(requested_metadata.get("tracking_overlay_mode", "")),
			"gesture_eval_interval_frames": int(requested_metadata.get("gesture_eval_interval_frames", 1)),
			"min_visibility": float(requested_metadata.get("min_visibility", 0.35)),
		},
	}
	var request: Dictionary = registry.request_session(request_filters)
	if not bool(request.get("ok", false)):
		return false
	var session: Dictionary = request.get("session", {}) if request.get("session", {}) is Dictionary else {}
	var session_metadata: Dictionary = session.get("metadata", {}) if session.get("metadata", {}) is Dictionary else {}
	var session_runtime_mode := str(session_metadata.get("runtime_mode", "")).strip_edges()
	if requested_mode == SOURCE_MODE_MEDIAPIPE_REPLAY and session_runtime_mode != "replay":
		return false
	if requested_mode == SOURCE_MODE_MEDIAPIPE_LIVE and session_runtime_mode == "replay":
		return false
	var session_key := str(session.get("session_key", "")).strip_edges()
	if session_key.is_empty():
		return false
	var acquire: Dictionary = registry.acquire_session(MEDIAPIPE_SESSION_CONSUMER_ID, {"session_key": session_key})
	if not bool(acquire.get("ok", false)):
		return false
	var acquired_session: Dictionary = acquire.get("session", {}) if acquire.get("session", {}) is Dictionary else {}
	var shared_provider := acquired_session.get("provider", null) as Node
	if shared_provider == null or not is_instance_valid(shared_provider):
		registry.release_session(MEDIAPIPE_SESSION_CONSUMER_ID, session_key)
		return false
	_disconnect_mediapipe_backend_if_possible()
	_disconnect_mediapipe_input_source_signals(_mediapipe_input_source)
	_reset_mediapipe_autostart_manager()
	_mediapipe_input_source = shared_provider
	_mediapipe_input_source_is_borrowed = true
	_mediapipe_borrowed_session_key = session_key
	_mediapipe_owned_session_key = ""
	_mediapipe_session_owner_id = str(acquired_session.get("owner_id", "")).strip_edges()
	_apply_mediapipe_session_metadata(acquired_session)
	_connect_mediapipe_input_source_signals(_mediapipe_input_source)
	_wire_mediapipe_backend_if_possible()
	return true

func _start_local_mediapipe_input_source(requested_mode: String) -> bool:
	if _mediapipe_input_source != null and is_instance_valid(_mediapipe_input_source) and not _mediapipe_input_source_is_borrowed:
		_apply_local_mediapipe_runtime_settings(requested_mode)
		_apply_mediapipe_session_metadata({"metadata": _build_mediapipe_session_metadata_for_mode(requested_mode)})
		_publish_owned_mediapipe_session()
		return true
	if not ResourceLoader.exists(MEDIAPIPE_PROVIDER_PATH):
		return false
	var script: GDScript = load(MEDIAPIPE_PROVIDER_PATH)
	if script == null:
		return false
	_disconnect_mediapipe_backend_if_possible()
	_disconnect_mediapipe_input_source_signals(_mediapipe_input_source)
	var local_input_source: Node = script.new()
	local_input_source.name = "MediaPipePythonInputSource"
	add_child(local_input_source)
	var started := true
	if local_input_source.has_method("start"):
		started = bool(local_input_source.start(_mediapipe_start_settings_json_for_mode(requested_mode)))
	if not started:
		local_input_source.queue_free()
		return false
	_mediapipe_input_source = local_input_source
	_mediapipe_input_source_is_borrowed = false
	_mediapipe_borrowed_session_key = ""
	_mediapipe_session_owner_id = MEDIAPIPE_SESSION_OWNER_ID
	_apply_mediapipe_session_metadata({"metadata": _build_mediapipe_session_metadata_for_mode(requested_mode)})
	_connect_mediapipe_input_source_signals(_mediapipe_input_source)
	_wire_mediapipe_backend_if_possible()
	_publish_owned_mediapipe_session()
	return true

func _publish_owned_mediapipe_session() -> Dictionary:
	if _mediapipe_input_source == null or not is_instance_valid(_mediapipe_input_source) or _mediapipe_input_source_is_borrowed:
		return {}
	var registry = _load_provider_session_registry()
	if registry == null:
		return {}
	var provider := _mediapipe_input_source as AeroInputProvider
	if provider == null:
		return {}
	var publish: Dictionary = registry.publish_session(
		MEDIAPIPE_SESSION_OWNER_ID,
		provider,
		{
			"session_key": MEDIAPIPE_SESSION_KEY,
			"metadata": _default_mediapipe_session_metadata(),
		}
	)
	if bool(publish.get("ok", false)):
		var session: Dictionary = publish.get("session", {}) if publish.get("session", {}) is Dictionary else {}
		_mediapipe_owned_session_key = str(session.get("session_key", MEDIAPIPE_SESSION_KEY)).strip_edges()
		_mediapipe_session_owner_id = MEDIAPIPE_SESSION_OWNER_ID
		_apply_mediapipe_session_metadata(session)
	return publish

func _release_borrowed_mediapipe_session() -> void:
	if not _mediapipe_input_source_is_borrowed:
		return
	var borrowed_session_key := _mediapipe_borrowed_session_key
	var registry = _load_provider_session_registry()
	if registry != null and not borrowed_session_key.is_empty():
		registry.release_session(MEDIAPIPE_SESSION_CONSUMER_ID, borrowed_session_key)
	_disconnect_mediapipe_backend_if_possible()
	_disconnect_mediapipe_input_source_signals(_mediapipe_input_source)
	_mediapipe_input_source = null
	_mediapipe_input_source_is_borrowed = false
	_mediapipe_borrowed_session_key = ""
	_mediapipe_session_owner_id = ""
	_mediapipe_session_metadata = {}
	_mediapipe_runtime_status = "inactive"
	_mediapipe_runtime_last_error = ""

func _teardown_mediapipe_runtime() -> void:
	_release_borrowed_mediapipe_session()
	_reset_mediapipe_autostart_manager()
	if _mediapipe_input_source == null or not is_instance_valid(_mediapipe_input_source):
		return
	var owned_source := _mediapipe_input_source
	var registry = _load_provider_session_registry()
	if registry != null and not _mediapipe_owned_session_key.is_empty():
		registry.unpublish_session(MEDIAPIPE_SESSION_OWNER_ID, _mediapipe_owned_session_key)
	_disconnect_mediapipe_backend_if_possible()
	_disconnect_mediapipe_input_source_signals(owned_source)
	if owned_source.has_method("stop"):
		owned_source.stop()
	if owned_source.get_parent() == self:
		owned_source.queue_free()
	_mediapipe_input_source = null
	_mediapipe_input_source_is_borrowed = false
	_mediapipe_owned_session_key = ""
	_mediapipe_borrowed_session_key = ""
	_mediapipe_session_owner_id = ""
	_mediapipe_session_metadata = {}
	_mediapipe_runtime_status = "inactive"
	_mediapipe_runtime_last_error = ""

func _disconnect_mediapipe_backend_if_possible() -> void:
	if _mediapipe_provider_backend != null:
		var pose_callable := Callable(self, "_on_mediapipe_pose_updated")
		if _mediapipe_provider_backend.has_signal("pose_updated") and _mediapipe_provider_backend.is_connected(&"pose_updated", pose_callable):
			_mediapipe_provider_backend.disconnect(&"pose_updated", pose_callable)
	_mediapipe_provider_backend = null
	_latest_pose_landmarks.clear()
	if _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("update_overlay"):
		_mediapipe_camera_view.update_overlay([])

func _ensure_mediapipe_runtime_for_active_source() -> void:
	_selected_mediapipe_live_camera_id = _normalize_live_camera_selection(str(_mediapipe_session_metadata.get("camera_source", _selected_mediapipe_live_camera_id)))
	_selected_mediapipe_tracking_quality = _normalize_tracking_quality_value(str(_mediapipe_session_metadata.get("tracking_quality", _selected_mediapipe_tracking_quality)))
	_refresh_mediapipe_live_control_values()
	_configure_mediapipe_camera_view_for_mode(_source_mode)
	if not _is_mediapipe_mode(_source_mode):
		return
	if _mediapipe_input_source_is_borrowed:
		_reset_mediapipe_autostart_manager()
		_mediapipe_runtime_status = "borrowed session"
		call_deferred("_ensure_mediapipe_camera_stream")
		return
	_mediapipe_runtime_request_serial += 1
	var request_serial := _mediapipe_runtime_request_serial
	call_deferred("_start_owned_mediapipe_runtime_async", request_serial, _source_mode)

func _start_owned_mediapipe_runtime_async(request_serial: int, requested_mode: String) -> void:
	if request_serial != _mediapipe_runtime_request_serial or not _is_mediapipe_mode(requested_mode):
		return
	var runtime_signature := _build_mediapipe_runtime_signature(requested_mode)
	if requested_mode == SOURCE_MODE_MEDIAPIPE_REPLAY and _requested_mediapipe_camera_source_override(requested_mode).is_empty():
		_update_status("Replay mode requires a valid fixture video path")
		return
	var existing_manager := _mediapipe_autostart_manager != null and is_instance_valid(_mediapipe_autostart_manager)
	if not existing_manager:
		if not _ensure_mediapipe_autostart_manager(requested_mode):
			_update_status("MediaPipe AutoStartManager seam is unavailable")
			return
	else:
		_mediapipe_autostart_manager.camera_source_override = _requested_mediapipe_camera_source_override(requested_mode)
		var tracking_quality_settings := _current_mediapipe_tracking_quality_settings()
		_mediapipe_autostart_manager.tracking_overlay_mode = str(tracking_quality_settings.get("tracking_overlay_mode", "full"))
	var needs_restart := existing_manager and _mediapipe_runtime_signature != runtime_signature
	var started := true
	_mediapipe_runtime_status = "starting"
	_mediapipe_runtime_last_error = ""
	if needs_restart:
		started = bool(await _restart_owned_mediapipe_server_for_request(requested_mode))
	elif _mediapipe_autostart_manager.has_method("is_server_running") and not bool(_mediapipe_autostart_manager.is_server_running()):
		started = bool(await _mediapipe_autostart_manager.start_server())
	if request_serial != _mediapipe_runtime_request_serial:
		return
	if not started:
		_mediapipe_runtime_status = "failed"
		if _mediapipe_runtime_last_error.is_empty():
			_mediapipe_runtime_last_error = "restart_server returned false" if needs_restart else "start_server returned false"
		_update_status("Failed to start %s runtime" % _source_mode_label(requested_mode))
		return
	var ready := await _await_owned_mediapipe_runtime_ready(request_serial, requested_mode)
	if request_serial != _mediapipe_runtime_request_serial:
		return
	if not ready:
		_mediapipe_runtime_status = "failed"
		if _mediapipe_runtime_last_error.is_empty():
			_mediapipe_runtime_last_error = "runtime did not become ready before timeout"
		_update_status("Failed to stabilize %s runtime" % _source_mode_label(requested_mode))
		return
	_reattach_controller_to_mediapipe_input_source_if_needed(requested_mode)
	_mediapipe_runtime_status = "ready"
	_mediapipe_runtime_signature = runtime_signature
	_update_status("%s runtime ready" % _source_mode_label(requested_mode))

func _clear_owned_mediapipe_runtime_state() -> void:
	_clear_owned_mediapipe_preview_state()
	_teardown_owned_mediapipe_input_source_for_restart()

func _clear_owned_mediapipe_preview_state() -> void:
	_latest_pose_landmarks.clear()
	if _tracking_overlay != null:
		_tracking_overlay.clear_snapshot()
	if _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("update_overlay"):
		_mediapipe_camera_view.update_overlay([])
	if _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("is_streaming") and bool(_mediapipe_camera_view.is_streaming()):
		_mediapipe_camera_view.stop_stream()

func _mark_owned_mediapipe_restart_cleanup_pending() -> void:
	_mediapipe_owned_restart_cleanup_pending = true
	_mediapipe_runtime_status = "stopping"

func _complete_owned_mediapipe_restart_cleanup_if_pending() -> void:
	if not _mediapipe_owned_restart_cleanup_pending:
		return
	_mediapipe_owned_restart_cleanup_pending = false
	_clear_owned_mediapipe_preview_state()
	_teardown_owned_mediapipe_input_source_for_restart()

func _detach_controller_from_input_source_for_restart(source: Node) -> void:
	if source == null or _controller == null:
		return
	if _current_input_source != source:
		return
	_controller.detach_input_source()
	_current_input_source = null
	_mediapipe_controller_reattach_pending = true

func _reattach_controller_to_mediapipe_input_source_if_needed(requested_mode: String) -> void:
	if _controller == null:
		return
	if not _is_mediapipe_mode(requested_mode):
		return
	if _mediapipe_input_source == null or not is_instance_valid(_mediapipe_input_source):
		return
	if not _mediapipe_controller_reattach_pending and _current_input_source == _mediapipe_input_source:
		return
	if _controller.attach_input_source(_mediapipe_input_source):
		_current_input_source = _mediapipe_input_source
		_mediapipe_controller_reattach_pending = false

func _teardown_owned_mediapipe_input_source_for_restart() -> void:
	if _mediapipe_input_source == null or not is_instance_valid(_mediapipe_input_source) or _mediapipe_input_source_is_borrowed:
		return
	var owned_source := _mediapipe_input_source
	_detach_controller_from_input_source_for_restart(owned_source)
	var registry = _load_provider_session_registry()
	if registry != null and not _mediapipe_owned_session_key.is_empty():
		registry.unpublish_session(MEDIAPIPE_SESSION_OWNER_ID, _mediapipe_owned_session_key)
	_disconnect_mediapipe_backend_if_possible()
	_disconnect_mediapipe_input_source_signals(owned_source)
	if owned_source.has_method("stop"):
		owned_source.stop()
	if owned_source.get_parent() == self:
		owned_source.queue_free()
	_mediapipe_input_source = null
	_mediapipe_input_source_is_borrowed = false
	_mediapipe_owned_session_key = ""
	_mediapipe_borrowed_session_key = ""
	_mediapipe_session_owner_id = ""
	_mediapipe_session_metadata = {}

func _restart_owned_mediapipe_server_for_request(requested_mode: String) -> bool:
	if _mediapipe_autostart_manager == null or not is_instance_valid(_mediapipe_autostart_manager):
		return false
	var requested_override := _requested_mediapipe_camera_source_override(requested_mode)
	_mark_owned_mediapipe_restart_cleanup_pending()
	_mediapipe_autostart_manager.camera_source_override = requested_override
	if requested_mode == SOURCE_MODE_MEDIAPIPE_LIVE and _mediapipe_input_source != null and is_instance_valid(_mediapipe_input_source) and _mediapipe_input_source.has_method("set_selected_camera_device_id"):
		_mediapipe_input_source.set_selected_camera_device_id(requested_override)
	var restart_ok := false
	if _mediapipe_autostart_manager.has_method("restart_server"):
		restart_ok = bool(await _mediapipe_autostart_manager.restart_server(requested_override))
	else:
		await _mediapipe_autostart_manager.stop_server()
		_mediapipe_autostart_manager.camera_source_override = requested_override
		restart_ok = bool(await _mediapipe_autostart_manager.start_server())
	_complete_owned_mediapipe_restart_cleanup_if_pending()
	if not restart_ok:
		return false
	if not _start_local_mediapipe_input_source(requested_mode):
		_mediapipe_runtime_last_error = "failed to recreate owned input source after restart"
		return false
	return true

func _await_owned_mediapipe_runtime_ready(request_serial: int, requested_mode: String, timeout_ms: int = 8000) -> bool:
	var deadline_ms := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline_ms:
		if request_serial != _mediapipe_runtime_request_serial:
			return false
		if _owned_mediapipe_runtime_is_ready(requested_mode):
			return true
		await _ensure_mediapipe_camera_stream()
		if _owned_mediapipe_runtime_is_ready(requested_mode):
			return true
		await get_tree().process_frame
	return _owned_mediapipe_runtime_is_ready(requested_mode)

func _owned_mediapipe_runtime_is_ready(requested_mode: String) -> bool:
	if _mediapipe_input_source == null or not is_instance_valid(_mediapipe_input_source):
		return false
	if _mediapipe_autostart_manager == null or not is_instance_valid(_mediapipe_autostart_manager):
		return false
	if _mediapipe_autostart_manager.has_method("is_server_running") and not bool(_mediapipe_autostart_manager.is_server_running()):
		return false
	if _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("is_streaming"):
		if not bool(_mediapipe_camera_view.is_streaming()):
			return false
	if requested_mode == SOURCE_MODE_MEDIAPIPE_REPLAY:
		return bool(_fixture_runtime_config.get("runtime_ready", false))
	return true

func _ensure_mediapipe_autostart_manager(requested_mode: String) -> bool:
	if not ResourceLoader.exists(MEDIAPIPE_AUTOSTART_MANAGER_PATH):
		return false
	var autostart_script: GDScript = load(MEDIAPIPE_AUTOSTART_MANAGER_PATH)
	if autostart_script == null:
		return false
	_mediapipe_autostart_manager = autostart_script.new()
	_mediapipe_autostart_manager.name = "MediaPipeAutoStartManager"
	_mediapipe_autostart_manager.auto_start = false
	_mediapipe_autostart_manager.use_camera_stream = true
	_mediapipe_autostart_manager.camera_source_override = _requested_mediapipe_camera_source_override(requested_mode)
	if _mediapipe_autostart_manager.has_signal("server_started"):
		_mediapipe_autostart_manager.server_started.connect(_on_mediapipe_server_started)
	if _mediapipe_autostart_manager.has_signal("server_stopped"):
		_mediapipe_autostart_manager.server_stopped.connect(_on_mediapipe_server_stopped)
	if _mediapipe_autostart_manager.has_signal("server_failed"):
		_mediapipe_autostart_manager.server_failed.connect(_on_mediapipe_server_failed)
	if _mediapipe_autostart_manager.has_signal("check_progress"):
		_mediapipe_autostart_manager.check_progress.connect(_on_mediapipe_server_progress)
	add_child(_mediapipe_autostart_manager)
	var tracking_quality_settings := _current_mediapipe_tracking_quality_settings()
	_mediapipe_autostart_manager.tracking_overlay_mode = str(tracking_quality_settings.get("tracking_overlay_mode", "full"))
	_mediapipe_runtime_signature = _build_mediapipe_runtime_signature(requested_mode)
	return true

func _reset_mediapipe_autostart_manager() -> void:
	if _mediapipe_autostart_manager != null and is_instance_valid(_mediapipe_autostart_manager):
		_mediapipe_autostart_manager.queue_free()
	_mediapipe_autostart_manager = null
	_mediapipe_runtime_signature = ""

func _requested_mediapipe_camera_source_override(requested_mode: String) -> String:
	if requested_mode == SOURCE_MODE_MEDIAPIPE_REPLAY:
		var effective_video: Dictionary = _fixture_runtime_config.get("effective_video", {}) if _fixture_runtime_config.get("effective_video", {}) is Dictionary else {}
		return str(effective_video.get("display_path", "")).strip_edges()
	return _selected_mediapipe_live_camera_id.strip_edges()

func _mediapipe_start_settings_json_for_mode(requested_mode: String) -> String:
	var settings := {
		"flip_horizontal": requested_mode == SOURCE_MODE_MEDIAPIPE_LIVE,
	}
	if requested_mode == SOURCE_MODE_MEDIAPIPE_LIVE:
		var tracking_quality_settings := _current_mediapipe_tracking_quality_settings()
		settings["min_visibility"] = tracking_quality_settings.get("min_visibility", 0.35)
		settings["tracking_overlay_mode"] = tracking_quality_settings.get("tracking_overlay_mode", "full")
		settings["gesture_eval_interval_frames"] = tracking_quality_settings.get("gesture_eval_interval_frames", 1)
		var selected_camera_id := _selected_mediapipe_live_camera_id.strip_edges()
		if not selected_camera_id.is_empty():
			settings["selected_camera_device_id"] = selected_camera_id
	return JSON.stringify(settings)

func _apply_local_mediapipe_runtime_settings(requested_mode: String) -> void:
	if _mediapipe_input_source == null or not is_instance_valid(_mediapipe_input_source):
		return
	if _mediapipe_input_source.has_method("_apply_settings"):
		_mediapipe_input_source.call("_apply_settings", _mediapipe_start_settings_json_for_mode(requested_mode))

func _build_mediapipe_runtime_signature(requested_mode: String) -> String:
	var tracking_quality_settings := _current_mediapipe_tracking_quality_settings() if requested_mode == SOURCE_MODE_MEDIAPIPE_LIVE else {}
	return "%s|%s|%s|%s" % [
		requested_mode,
		_requested_mediapipe_camera_source_override(requested_mode),
		str(tracking_quality_settings.get("tracking_overlay_mode", "")),
		str(tracking_quality_settings.get("gesture_eval_interval_frames", "")),
	]

func _default_mediapipe_session_metadata() -> Dictionary:
	return _build_mediapipe_session_metadata_for_mode(_source_mode)

func _build_mediapipe_session_metadata_for_mode(requested_mode: String) -> Dictionary:
	var runtime_label := _source_mode_runtime_label(requested_mode)
	var requested_source := _requested_mediapipe_camera_source_override(requested_mode)
	if requested_source.is_empty():
		requested_source = "0"
	var effective_video: Dictionary = _fixture_runtime_config.get("effective_video", {}) if _fixture_runtime_config.get("effective_video", {}) is Dictionary else {}
	var sidecar: Dictionary = _fixture_runtime_config.get("sidecar", {}) if _fixture_runtime_config.get("sidecar", {}) is Dictionary else {}
	var tracking_quality_settings := _current_mediapipe_tracking_quality_settings() if requested_mode == SOURCE_MODE_MEDIAPIPE_LIVE else {
		"min_visibility": 0.35,
		"tracking_overlay_mode": "full",
		"gesture_eval_interval_frames": 1,
	}
	return {
		"lane": "camera_gesture_testbed",
		"device": requested_source if runtime_label == "live" else "fixture_video",
		"stream_url": DEFAULT_MEDIAPIPE_STREAM_URL,
		"runtime_mode": runtime_label,
		"camera_source": requested_source,
		"fixture_key": _fixture_key_edit.text.strip_edges(),
		"fixture_video_path": str(effective_video.get("display_path", _fixture_video_path_edit.text.strip_edges())),
		"fixture_sidecar_path": str(sidecar.get("display_path", _fixture_sidecar_path_edit.text.strip_edges())),
		"sample_source_hint": str(_fixture_runtime_config.get("sample_source_hint", "")),
		"source_mode": requested_mode,
		"tracking_quality": _selected_mediapipe_tracking_quality,
		"min_visibility": float(tracking_quality_settings.get("min_visibility", 0.35)),
		"tracking_overlay_mode": str(tracking_quality_settings.get("tracking_overlay_mode", "full")),
		"gesture_eval_interval_frames": int(tracking_quality_settings.get("gesture_eval_interval_frames", 1)),
	}

func _apply_mediapipe_session_metadata(session_record: Dictionary) -> void:
	var metadata: Dictionary = session_record.get("metadata", {}) if session_record.get("metadata", {}) is Dictionary else {}
	_mediapipe_session_metadata = metadata.duplicate(true)
	_selected_mediapipe_live_camera_id = _normalize_live_camera_selection(str(_mediapipe_session_metadata.get("camera_source", _selected_mediapipe_live_camera_id)))
	_selected_mediapipe_tracking_quality = _normalize_tracking_quality_value(str(_mediapipe_session_metadata.get("tracking_quality", _selected_mediapipe_tracking_quality)))
	var stream_url := str(_mediapipe_session_metadata.get("stream_url", DEFAULT_MEDIAPIPE_STREAM_URL)).strip_edges()
	if stream_url.is_empty():
		stream_url = DEFAULT_MEDIAPIPE_STREAM_URL
	if _mediapipe_camera_view != null:
		_mediapipe_camera_view.stream_url = stream_url
	_refresh_mediapipe_live_control_values()
	if _source_label != null:
		_source_label.text = _build_source_status_line()
	_configure_mediapipe_camera_view_for_mode(_source_mode)

func _configure_mediapipe_camera_view_for_mode(mode: String) -> void:
	if _mediapipe_camera_view == null:
		return
	_set_object_property_if_present(_mediapipe_camera_view, "flip_horizontal", mode == SOURCE_MODE_MEDIAPIPE_LIVE)
	_set_object_property_if_present(_mediapipe_camera_view, "show_overlay", false)

func _on_mediapipe_server_progress(_percentage: int, message: String) -> void:
	_mediapipe_runtime_status = message

func _on_mediapipe_server_started(_pid: int) -> void:
	# AutoStartManager emits server_started as soon as the detached process exists,
	# before its own stabilization wait finishes. Starting the preview stream here can
	# race replay startup and consume the only immediate retry window too early.
	_mediapipe_runtime_status = "stabilizing"
	_mediapipe_runtime_last_error = ""

func _on_mediapipe_server_stopped() -> void:
	_mediapipe_runtime_status = "stopped"
	_complete_owned_mediapipe_restart_cleanup_if_pending()

func _on_mediapipe_server_failed(error: String) -> void:
	_mediapipe_runtime_status = "failed"
	_mediapipe_runtime_last_error = error

func _is_mediapipe_mode(mode: String) -> bool:
	return mode == SOURCE_MODE_MEDIAPIPE_LIVE or mode == SOURCE_MODE_MEDIAPIPE_REPLAY

func _source_mode_runtime_label(mode: String) -> String:
	return "replay" if mode == SOURCE_MODE_MEDIAPIPE_REPLAY else "live"

func _source_mode_label(mode: String) -> String:
	match mode:
		SOURCE_MODE_MEDIAPIPE_LIVE:
			return "MediaPipe live"
		SOURCE_MODE_MEDIAPIPE_REPLAY:
			return "MediaPipe replay"
		_:
			return "Fake"

func _current_mediapipe_tracking_quality_settings() -> Dictionary:
	var quality := _normalize_tracking_quality_value(_selected_mediapipe_tracking_quality)
	var preset: Variant = MEDIAPIPE_TRACKING_QUALITY_PRESETS.get(quality, MEDIAPIPE_TRACKING_QUALITY_PRESETS["full"])
	return preset.duplicate(true) if preset is Dictionary else {}

func _normalize_tracking_quality_value(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	return normalized if MEDIAPIPE_TRACKING_QUALITY_OPTIONS.has(normalized) else "full"

func _normalize_live_camera_selection(value: String) -> String:
	var normalized := value.strip_edges()
	return "0" if normalized.is_empty() else normalized

func _refresh_mediapipe_live_controls_visibility() -> void:
	var show_live_controls := _source_mode == SOURCE_MODE_MEDIAPIPE_LIVE
	if _mediapipe_live_camera_row != null:
		_mediapipe_live_camera_row.visible = show_live_controls
	if _mediapipe_tracking_quality_row != null:
		_mediapipe_tracking_quality_row.visible = show_live_controls
	if _mediapipe_live_note_label != null:
		_mediapipe_live_note_label.visible = show_live_controls

func _refresh_mediapipe_live_control_values() -> void:
	if _mediapipe_live_camera_option != null:
		_populate_mediapipe_live_camera_picker()
	if _mediapipe_tracking_quality_option != null:
		_suppress_mediapipe_tracking_quality_signal = true
		_set_option_value(_mediapipe_tracking_quality_option, _normalize_tracking_quality_value(_selected_mediapipe_tracking_quality))
		_suppress_mediapipe_tracking_quality_signal = false

func _refresh_mediapipe_available_camera_devices() -> void:
	var devices: Array = []
	if _mediapipe_input_source != null and is_instance_valid(_mediapipe_input_source) and _mediapipe_input_source.has_method("get_available_camera_devices"):
		devices = _mediapipe_input_source.get_available_camera_devices()
	if devices.is_empty():
		var fallback_id := _normalize_live_camera_selection(str(_mediapipe_session_metadata.get("camera_source", _selected_mediapipe_live_camera_id)))
		devices.append({
			"id": fallback_id,
			"label": "Default camera" if fallback_id == "0" else fallback_id.get_file(),
		})
	_mediapipe_available_camera_devices = devices.duplicate(true)
	if not _camera_device_list_has_id(_mediapipe_available_camera_devices, _selected_mediapipe_live_camera_id):
		_selected_mediapipe_live_camera_id = _first_camera_device_id(_mediapipe_available_camera_devices)

func _camera_device_list_has_id(devices: Array, device_id: String) -> bool:
	for device_variant: Variant in devices:
		if not device_variant is Dictionary:
			continue
		if str((device_variant as Dictionary).get("id", "")).strip_edges() == device_id:
			return true
	return false

func _first_camera_device_id(devices: Array) -> String:
	for device_variant: Variant in devices:
		if not device_variant is Dictionary:
			continue
		var device_id := str((device_variant as Dictionary).get("id", "")).strip_edges()
		if not device_id.is_empty():
			return device_id
	return "0"

func _populate_mediapipe_live_camera_picker() -> void:
	if _mediapipe_live_camera_option == null:
		return
	_refresh_mediapipe_available_camera_devices()
	_suppress_mediapipe_live_camera_signal = true
	_mediapipe_live_camera_option.clear()
	var selected_index := -1
	for index: int in range(_mediapipe_available_camera_devices.size()):
		var device_variant: Variant = _mediapipe_available_camera_devices[index]
		if not device_variant is Dictionary:
			continue
		var device: Dictionary = device_variant
		var device_id := str(device.get("id", "")).strip_edges()
		_mediapipe_live_camera_option.add_item(_camera_device_label(device))
		var item_index := _mediapipe_live_camera_option.item_count - 1
		_mediapipe_live_camera_option.set_item_metadata(item_index, device_id)
		_mediapipe_live_camera_option.set_item_tooltip(item_index, device_id)
		if device_id == _selected_mediapipe_live_camera_id:
			selected_index = item_index
	if selected_index == -1 and _mediapipe_live_camera_option.item_count > 0:
		selected_index = 0
		_selected_mediapipe_live_camera_id = _normalize_live_camera_selection(str(_mediapipe_live_camera_option.get_item_metadata(0)))
	if selected_index >= 0:
		_mediapipe_live_camera_option.select(selected_index)
	_suppress_mediapipe_live_camera_signal = false

func _camera_device_label(device: Dictionary) -> String:
	var label := str(device.get("label", "")).strip_edges()
	var device_id := str(device.get("id", "")).strip_edges()
	if label.is_empty():
		label = "Default camera" if device_id == "0" else device_id
	if label == device_id or device_id.is_empty():
		return label
	return "%s (%s)" % [label, device_id]

func _get_selected_mediapipe_live_camera_option_id() -> String:
	if _mediapipe_live_camera_option == null or _mediapipe_live_camera_option.selected < 0 or _mediapipe_live_camera_option.selected >= _mediapipe_live_camera_option.item_count:
		return _selected_mediapipe_live_camera_id
	return str(_mediapipe_live_camera_option.get_item_metadata(_mediapipe_live_camera_option.selected)).strip_edges()

func _build_active_camera_text() -> String:
	if _source_mode == SOURCE_MODE_MEDIAPIPE_REPLAY:
		var effective_video: Dictionary = _fixture_runtime_config.get("effective_video", {}) if _fixture_runtime_config.get("effective_video", {}) is Dictionary else {}
		return str(effective_video.get("display_path", _fixture_video_path_edit.text.strip_edges()))
	var camera_id := _normalize_live_camera_selection(str(_mediapipe_session_metadata.get("camera_source", _selected_mediapipe_live_camera_id))) if _source_mode == SOURCE_MODE_MEDIAPIPE_LIVE else _selected_mediapipe_live_camera_id
	for device_variant: Variant in _mediapipe_available_camera_devices:
		if device_variant is Dictionary and str((device_variant as Dictionary).get("id", "")).strip_edges() == camera_id:
			return _camera_device_label(device_variant as Dictionary)
	return "Default camera" if camera_id == "0" else camera_id

func _build_tracking_quality_compact_text() -> String:
	return _normalize_tracking_quality_value(str(_mediapipe_session_metadata.get("tracking_quality", _selected_mediapipe_tracking_quality)))

func _build_tracking_quality_summary_text() -> String:
	var settings := _current_mediapipe_tracking_quality_settings()
	return "%s (overlay=%s, min_visibility=%.2f, gesture_every=%s frame%s)" % [
		_build_tracking_quality_compact_text(),
		str(_mediapipe_session_metadata.get("tracking_overlay_mode", settings.get("tracking_overlay_mode", "full"))),
		float(_mediapipe_session_metadata.get("min_visibility", settings.get("min_visibility", 0.35))),
		str(_mediapipe_session_metadata.get("gesture_eval_interval_frames", settings.get("gesture_eval_interval_frames", 1))),
		"" if int(_mediapipe_session_metadata.get("gesture_eval_interval_frames", settings.get("gesture_eval_interval_frames", 1))) == 1 else "s",
	]

func _build_source_status_line() -> String:
	if _source_mode == SOURCE_MODE_MEDIAPIPE_LIVE:
		return "Input source: %s | camera %s | %s" % [_source_mode_label(_source_mode), _build_active_camera_text(), _build_tracking_quality_compact_text()]
	if _source_mode == SOURCE_MODE_MEDIAPIPE_REPLAY:
		return "Input source: %s | replay %s" % [_source_mode_label(_source_mode), _build_active_camera_text()]
	return "Input source: %s" % _source_mode_label(_source_mode)

func _connect_mediapipe_input_source_signals(source: Node) -> void:
	if source == null or not is_instance_valid(source):
		return
	var callable := Callable(self, "_on_mediapipe_camera_devices_changed")
	if source.has_signal("camera_devices_changed") and not source.is_connected(&"camera_devices_changed", callable):
		source.connect(&"camera_devices_changed", callable)

func _disconnect_mediapipe_input_source_signals(source: Node) -> void:
	if source == null or not is_instance_valid(source):
		return
	var callable := Callable(self, "_on_mediapipe_camera_devices_changed")
	if source.has_signal("camera_devices_changed") and source.is_connected(&"camera_devices_changed", callable):
		source.disconnect(&"camera_devices_changed", callable)

func _on_mediapipe_camera_devices_changed(devices: Array, selected_device_id: String) -> void:
	_mediapipe_available_camera_devices = devices.duplicate(true)
	_selected_mediapipe_live_camera_id = _normalize_live_camera_selection(selected_device_id if not selected_device_id.strip_edges().is_empty() else _selected_mediapipe_live_camera_id)
	_refresh_mediapipe_live_control_values()
	_source_label.text = _build_source_status_line()

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
		"provider_session": _build_mediapipe_session_debug_state(),
		"fixture": {
			"key": _fixture_key_edit.text.strip_edges(),
			"video_path": _fixture_video_path_edit.text.strip_edges(),
			"sidecar_path": _fixture_sidecar_path_edit.text.strip_edges(),
			"runtime_config": _trace_store.to_json_safe(_fixture_runtime_config),
		},
		"media_inset": {
			"source_mode": _source_mode,
			"source_mode_label": _source_mode_label(_source_mode),
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
	var tracking_quality_settings := _current_mediapipe_tracking_quality_settings()
	var snapshot := {
		"source_mode": _source_mode,
		"source_mode_label": _source_mode_label(_source_mode),
		"tracking": _current_input_source != null and _current_input_source.has_method("is_tracking") and bool(_current_input_source.is_tracking()),
		"confidence": _read_current_source_confidence(),
		"threshold": float(_controller.get_debug_state().get("tracking_state", {}).get("threshold", 0.0)),
		"camera_feed_requested": _is_mediapipe_mode(_source_mode),
		"camera_feed_live": _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("is_streaming") and bool(_mediapipe_camera_view.is_streaming()),
		"runtime_mode": _source_mode_runtime_label(_source_mode) if _is_mediapipe_mode(_source_mode) else "fake",
		"fixture_key": _fixture_key_edit.text.strip_edges(),
		"fixture_runtime_ready": bool(_fixture_runtime_config.get("runtime_ready", false)),
		"live_camera_id": _selected_mediapipe_live_camera_id,
		"tracking_quality": _selected_mediapipe_tracking_quality,
		"tracking_quality_settings": tracking_quality_settings.duplicate(true),
		"tracking_overlay_mode": str(tracking_quality_settings.get("tracking_overlay_mode", "off")) if _is_mediapipe_mode(_source_mode) else "off",
		"tracking_min_visibility": float(tracking_quality_settings.get("min_visibility", 0.35)),
		"pose_landmarks": _latest_pose_landmarks.duplicate(true),
	}
	if _current_input_source != null and _current_input_source.has_method("get_head_position"):
		snapshot["head_position"] = _coerce_vector3(_current_input_source.get_head_position())
	if _current_input_source != null and _current_input_source.has_method("get_head_velocity"):
		snapshot["head_velocity"] = _coerce_vector3(_current_input_source.get_head_velocity())
	if _current_input_source != null and _current_input_source.has_method("get_head_rotation"):
		var head_rotation: Variant = _current_input_source.get_head_rotation()
		if head_rotation is Quaternion:
			snapshot["head_rotation_euler"] = (head_rotation as Quaternion).get_euler()
	if _current_input_source == _fake_input_source and _fake_input_source != null:
		snapshot["fake_animate"] = _fake_input_source.animate
		snapshot["fake_animation_speed"] = _fake_input_source.animation_speed
	return snapshot

func _collect_provider_snapshot() -> Dictionary:
	var snapshot := _build_mediapipe_session_debug_state()
	if not _is_mediapipe_mode(_source_mode) or _mediapipe_provider_backend == null:
		snapshot["provider_mode"] = _source_mode
		snapshot["landmark_count"] = _latest_pose_landmarks.size()
		return snapshot
	var detector_state: Dictionary = {}
	if _mediapipe_provider_backend.has_method("get_detector_state"):
		detector_state = _mediapipe_provider_backend.get_detector_state()
	var metrics: Dictionary = detector_state.get("metrics", {}) if detector_state.get("metrics", {}) is Dictionary else {}
	var confidences: Dictionary = metrics.get("confidences", {}) if metrics.get("confidences", {}) is Dictionary else {}
	var events: Array = detector_state.get("events", []) if detector_state.get("events", []) is Array else []
	snapshot["provider_mode"] = _source_mode
	snapshot["tracking_state"] = detector_state.get("tracking_state", "")
	snapshot["head_confidence"] = float(confidences.get("head", 0.0))
	snapshot["torso_confidence"] = float(confidences.get("torso", 0.0))
	snapshot["event_count"] = events.size()
	snapshot["landmark_count"] = _latest_pose_landmarks.size()
	return snapshot

func _build_mediapipe_session_debug_state() -> Dictionary:
	var provider_live := _mediapipe_input_source != null and is_instance_valid(_mediapipe_input_source)
	var session_role := "inactive"
	var session_key := ""
	if _mediapipe_input_source_is_borrowed:
		session_role = "borrowed"
		session_key = _mediapipe_borrowed_session_key
	elif provider_live:
		session_role = "owned"
		session_key = _mediapipe_owned_session_key
	var owner_id := _mediapipe_session_owner_id
	if owner_id.is_empty() and session_role == "owned":
		owner_id = MEDIAPIPE_SESSION_OWNER_ID
	return {
		"registry_available": _provider_session_registry_available(),
		"session_role": session_role,
		"session_key": session_key,
		"owner_id": owner_id,
		"borrowed": _mediapipe_input_source_is_borrowed,
		"provider_live": provider_live,
		"stream_url": str(_mediapipe_session_metadata.get("stream_url", DEFAULT_MEDIAPIPE_STREAM_URL)),
		"runtime_mode": str(_mediapipe_session_metadata.get("runtime_mode", "")),
		"camera_source": str(_mediapipe_session_metadata.get("camera_source", "")),
		"fixture_key": str(_mediapipe_session_metadata.get("fixture_key", "")),
		"runtime_status": _mediapipe_runtime_status,
		"runtime_last_error": _mediapipe_runtime_last_error,
		"tracking_quality": str(_mediapipe_session_metadata.get("tracking_quality", _selected_mediapipe_tracking_quality)),
		"min_visibility": float(_mediapipe_session_metadata.get("min_visibility", _current_mediapipe_tracking_quality_settings().get("min_visibility", 0.35))),
		"tracking_overlay_mode": str(_mediapipe_session_metadata.get("tracking_overlay_mode", _current_mediapipe_tracking_quality_settings().get("tracking_overlay_mode", "full"))),
		"gesture_eval_interval_frames": int(_mediapipe_session_metadata.get("gesture_eval_interval_frames", _current_mediapipe_tracking_quality_settings().get("gesture_eval_interval_frames", 1))),
		"known_limitation": "cross-lane duplicate prevention only works when the owner lane publishes a session through AeroProviderSessionRegistry with matching camera/tuning metadata",
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
	_preview_stats_label.text = "Source: %s\nRuntime: %s\nCamera: %s\nTracking quality: %s\nTranslation: %s\nRotation(deg): %s" % [
		_source_mode_label(_source_mode),
		_mediapipe_runtime_status,
		_build_active_camera_text(),
		_build_tracking_quality_summary_text(),
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
		"Input source mode: %s" % _source_mode_label(_source_mode),
		"MediaPipe runtime: %s" % _mediapipe_runtime_status,
		"Active camera: %s" % _build_active_camera_text(),
		"Tracking quality: %s" % _build_tracking_quality_summary_text(),
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
	var effective_video: Dictionary = _fixture_runtime_config.get("effective_video", {}) if _fixture_runtime_config.get("effective_video", {}) is Dictionary else {}
	var sidecar: Dictionary = _fixture_runtime_config.get("sidecar", {}) if _fixture_runtime_config.get("sidecar", {}) is Dictionary else {}
	var sidecar_summary: Dictionary = _fixture_runtime_config.get("sidecar_summary", {}) if _fixture_runtime_config.get("sidecar_summary", {}) is Dictionary else {}
	var lines := [
		"Fixture key: %s" % _fixture_key_edit.text.strip_edges(),
		"Configured video path: %s" % _fixture_video_path_edit.text.strip_edges(),
		"Resolved replay source: %s" % str(effective_video.get("display_path", "")),
		"Replay source ready: %s" % str(bool(_fixture_runtime_config.get("runtime_ready", false))),
		"Sidecar path: %s" % _fixture_sidecar_path_edit.text.strip_edges(),
		"Resolved sidecar: %s" % str(sidecar.get("display_path", "")),
		"Sample-source hint: %s" % str(_fixture_runtime_config.get("sample_source_hint", "")),
		"Trace export root: %s" % _trace_export_root_edit.text.strip_edges(),
		"Active profile path: %s" % str(active_profile.get("source_path", "")),
		"",
		"Sidecar summary:",
		"- fixture_id: %s" % str(sidecar_summary.get("fixture_id", "")),
		"- feature/family: %s / %s" % [str(sidecar_summary.get("feature", "")), str(sidecar_summary.get("family", ""))],
		"- primary channel/axis: %s / %s" % [str(sidecar_summary.get("primary_channel", "")), str(sidecar_summary.get("primary_axis", ""))],
		"- semantic direction: %s" % str(sidecar_summary.get("semantic_direction", "")),
		"- expected windows: %s" % str(sidecar_summary.get("expected_window_count", 0)),
		"",
		"Harness readiness:",
		"- left config/debug panel: ready",
		"- 1920×1080 world preview: ready",
		"- bottom-left media/tracking inset: wired for fake/live/replay truth",
		"- donor-style AutoStartManager seam: wired for owned MediaPipe live + replay",
		"- shared-session reuse seam: integrated on the camera-gesture side",
		"- duplicate-prevention limit: owner lanes still need to publish registry sessions for true cross-lane reuse",
		"- fixture replay path: wired for trace export and later oracle work",
		"- oracle assertions: still pending later slice",
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

func _current_tracking_overlay_display_rect() -> Rect2:
	if _tracking_overlay == null:
		return Rect2()
	var overlay_size := _tracking_overlay.size
	if overlay_size.x <= 0.0 or overlay_size.y <= 0.0:
		return Rect2(Vector2.ZERO, overlay_size)
	if _source_mode == SOURCE_MODE_MEDIAPIPE_REPLAY and _video_player_surface != null and is_instance_valid(_video_player_surface) and _video_player_surface.visible:
		return Rect2(Vector2.ZERO, overlay_size)
	if _mediapipe_camera_view == null or not is_instance_valid(_mediapipe_camera_view):
		return Rect2(Vector2.ZERO, overlay_size)
	var displayed_size_value: Variant = _mediapipe_camera_view.call("_get_displayed_image_size")
	if displayed_size_value is Vector2:
		var displayed_size: Vector2 = displayed_size_value
		var displayed_offset_value: Variant = _mediapipe_camera_view.call("_get_displayed_image_offset", displayed_size)
		if displayed_offset_value is Vector2:
			var displayed_offset: Vector2 = displayed_offset_value
			if displayed_size.x > 0.0 and displayed_size.y > 0.0:
				return Rect2(displayed_offset, displayed_size)
	return Rect2(Vector2.ZERO, overlay_size)

func _build_media_inset_status_line() -> String:
	if _source_mode == SOURCE_MODE_FAKE:
		return "Inset: fake source preview with tracking overlay"
	if _source_mode == SOURCE_MODE_MEDIAPIPE_REPLAY and _is_video_player_replay_ready():
		return "Inset: MediaPipe replay via AeroVideoPlayerManager + tracking overlay (%s)" % _build_tracking_quality_compact_text()
	if _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("is_streaming") and bool(_mediapipe_camera_view.is_streaming()):
		return "Inset: %s feed live + tracking overlay (%s)" % [_source_mode_label(_source_mode), _build_tracking_quality_compact_text()]
	if _source_mode == SOURCE_MODE_MEDIAPIPE_REPLAY and _video_player_last_error != "":
		return "Inset: replay delegated to AeroVideoPlayerManager, waiting on video load (%s)" % _video_player_last_error
	if _mediapipe_camera_view != null:
		return "Inset: %s requested, waiting for stream (%s | %s)" % [_source_mode_label(_source_mode), _build_active_camera_text(), _mediapipe_runtime_status]
	return "Inset: MediaPipe camera view seam unavailable; overlay-only fallback"

func _refresh_media_inset_surface() -> void:
	if _is_mediapipe_mode(_source_mode) and _mediapipe_camera_view == null:
		_ensure_mediapipe_camera_view_if_possible()
	var wants_replay_surface := _source_mode == SOURCE_MODE_MEDIAPIPE_REPLAY and _ensure_video_player_surface_if_possible()
	if wants_replay_surface:
		_sync_replay_video_surface()
	elif _video_player_manager != null and is_instance_valid(_video_player_manager) and _video_player_manager.has_method("unload"):
		_video_player_manager.unload()
		_video_player_last_loaded_source = ""
		_video_player_last_error = ""
	if _is_mediapipe_mode(_source_mode) and _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("start_stream"):
		call_deferred("_ensure_mediapipe_camera_stream")
	elif _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("stop_stream"):
		_mediapipe_camera_view.stop_stream()
	if _mediapipe_camera_view != null and _mediapipe_camera_view is CanvasItem:
		(_mediapipe_camera_view as CanvasItem).visible = _source_mode != SOURCE_MODE_MEDIAPIPE_REPLAY or not wants_replay_surface
	if _video_player_surface != null and is_instance_valid(_video_player_surface):
		_video_player_surface.visible = wants_replay_surface
	_media_inset_placeholder.visible = not _is_active_media_surface_ready()
	_media_placeholder_label.text = _build_media_placeholder_text()

func _ensure_mediapipe_camera_stream() -> void:
	if not _is_mediapipe_mode(_source_mode):
		return
	if _mediapipe_camera_view == null:
		_ensure_mediapipe_camera_view_if_possible()
	if _mediapipe_camera_view == null:
		return
	if _mediapipe_camera_view.has_method("is_streaming") and bool(_mediapipe_camera_view.is_streaming()):
		_media_inset_placeholder.visible = false
		return
	if _mediapipe_camera_view.has_method("start_stream"):
		var started_result: Variant = await _mediapipe_camera_view.start_stream()
		var started: bool = bool(started_result)
		_media_inset_placeholder.visible = not started
		_media_placeholder_label.text = _build_media_placeholder_text()

func _is_active_media_surface_ready() -> bool:
	if _source_mode == SOURCE_MODE_MEDIAPIPE_REPLAY:
		if _video_player_manager != null and is_instance_valid(_video_player_manager):
			return _is_video_player_replay_ready()
		return _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("is_streaming") and bool(_mediapipe_camera_view.is_streaming())
	return _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("is_streaming") and bool(_mediapipe_camera_view.is_streaming())

func _is_video_player_replay_ready() -> bool:
	if _video_player_manager == null or not is_instance_valid(_video_player_manager):
		return false
	if not _video_player_manager.has_method("get_state"):
		return false
	var state: Variant = _video_player_manager.get_state()
	if not (state is Dictionary):
		return false
	return bool((state as Dictionary).get("media_loaded", false))

func _ensure_video_player_surface_if_possible() -> bool:
	if _camera_feed_host == null:
		return false
	if _video_player_surface == null or not is_instance_valid(_video_player_surface):
		var surface := Control.new()
		surface.name = "ReplayVideoSurface"
		surface.set_anchors_preset(Control.PRESET_FULL_RECT)
		surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_camera_feed_host.add_child(surface)
		_camera_feed_host.move_child(surface, 0)
		_video_player_surface = surface
	if _video_player_manager != null and is_instance_valid(_video_player_manager):
		return true
	if not ResourceLoader.exists(VIDEO_PLAYER_MANAGER_PATH):
		return false
	var manager_script: GDScript = load(VIDEO_PLAYER_MANAGER_PATH)
	if manager_script == null:
		return false
	var manager = manager_script.new()
	if manager == null:
		return false
		
	if ResourceLoader.exists(GODOT_VIDEO_BACKEND_PATH):
		var backend_script: GDScript = load(GODOT_VIDEO_BACKEND_PATH)
		if backend_script != null and manager.has_method("set_backend"):
			manager.set_backend(backend_script.new())
	manager.name = "ReplayVideoPlayerManager"
	add_child(manager)
	_video_player_manager = manager
	if _video_player_manager.has_signal("state_changed"):
		_video_player_manager.state_changed.connect(_on_video_player_state_changed)
	if _video_player_manager.has_signal("media_loaded"):
		_video_player_manager.media_loaded.connect(_on_video_player_media_loaded)
	if _video_player_manager.has_signal("error_raised"):
		_video_player_manager.error_raised.connect(_on_video_player_error_raised)
	if _video_player_manager.has_method("attach_surface"):
		_video_player_manager.attach_surface(_video_player_surface)
	return true

func _sync_replay_video_surface() -> void:
	if _video_player_manager == null or not is_instance_valid(_video_player_manager):
		return
	var replay_source_path := _requested_mediapipe_camera_source_override(SOURCE_MODE_MEDIAPIPE_REPLAY)
	if replay_source_path.is_empty():
		return
	if _video_player_manager.has_method("attach_surface"):
		_video_player_manager.attach_surface(_video_player_surface)
	if replay_source_path == _video_player_last_loaded_source and _is_video_player_replay_ready():
		if _video_player_manager.has_method("play"):
			_video_player_manager.play()
		return
	if _video_player_manager.has_method("load"):
		_video_player_last_error = ""
		_video_player_last_loaded_source = replay_source_path
		_video_player_manager.load({
			"path": replay_source_path,
			"autoplay": true,
			"loop": true,
			"metadata": {
				"source_mode": SOURCE_MODE_MEDIAPIPE_REPLAY,
				"fixture_key": _fixture_key_edit.text.strip_edges(),
				"delegated_owner": "aerobeat-tool-video-player",
			}
		})

func _reset_video_player_surface() -> void:
	_video_player_last_loaded_source = ""
	_video_player_last_error = ""
	if _video_player_manager != null and is_instance_valid(_video_player_manager) and _video_player_manager.has_method("unload"):
		_video_player_manager.unload()
	if _video_player_manager != null and is_instance_valid(_video_player_manager):
		_video_player_manager.queue_free()
	_video_player_manager = null
	if _video_player_surface != null and is_instance_valid(_video_player_surface):
		_video_player_surface.queue_free()
	_video_player_surface = null

func _on_video_player_state_changed(_state: String, _detail: Dictionary) -> void:
	_media_inset_placeholder.visible = not _is_active_media_surface_ready()
	_media_placeholder_label.text = _build_media_placeholder_text()

func _on_video_player_media_loaded(_info: Dictionary) -> void:
	_video_player_last_error = ""
	_media_inset_placeholder.visible = not _is_active_media_surface_ready()
	_media_placeholder_label.text = _build_media_placeholder_text()

func _on_video_player_error_raised(error_info: Dictionary) -> void:
	_video_player_last_error = str(error_info.get("message", "video player load failed"))
	_media_inset_placeholder.visible = not _is_active_media_surface_ready()
	_media_placeholder_label.text = _build_media_placeholder_text()

func _build_media_placeholder_text() -> String:
	if _source_mode == SOURCE_MODE_FAKE:
		return "Fake source active\nTracking overlay shows normalized head motion."
	if _source_mode == SOURCE_MODE_MEDIAPIPE_REPLAY:
		var effective_video: Dictionary = _fixture_runtime_config.get("effective_video", {}) if _fixture_runtime_config.get("effective_video", {}) is Dictionary else {}
		var replay_path := str(effective_video.get("display_path", _fixture_video_path_edit.text.strip_edges()))
		if _video_player_last_error != "":
			return "Replay delegated to AeroVideoPlayerManager\nVideo load is still pending: %s\nFixture: %s" % [_video_player_last_error, replay_path]
		if _video_player_manager == null or not is_instance_valid(_video_player_manager):
			return "Replay delegated to AeroVideoPlayerManager\nWaiting for replay surface mount: %s" % replay_path
		return "Replay delegated to AeroVideoPlayerManager\nWaiting for fixture playback: %s" % replay_path
	if _mediapipe_camera_view == null:
		return "MediaPipe camera view not mounted in this addon seam yet.\nTracking overlay still shows controller-relevant motion."
	return "MediaPipe live selected\nWaiting for live camera preview stream from %s." % _build_active_camera_text()

func _ensure_mediapipe_camera_view_if_possible() -> void:
	if _mediapipe_camera_view != null and is_instance_valid(_mediapipe_camera_view):
		return
	_rebuild_mediapipe_camera_view()

func _rebuild_mediapipe_camera_view() -> bool:
	if _camera_feed_host == null:
		return false
	var previous_view = _mediapipe_camera_view if _mediapipe_camera_view != null and is_instance_valid(_mediapipe_camera_view) else null
	var camera_view_script: Variant = null
	if previous_view != null:
		camera_view_script = previous_view.get_script()
	if camera_view_script == null:
		if not ResourceLoader.exists(MEDIAPIPE_CAMERA_VIEW_PATH):
			return false
		camera_view_script = load(MEDIAPIPE_CAMERA_VIEW_PATH)
	if camera_view_script == null:
		return false
	var rebuilt_view = camera_view_script.new()
	if rebuilt_view == null:
		return false
	var built_view = rebuilt_view
	built_view.name = "MediaPipeCameraView"
	_apply_mediapipe_camera_view_defaults(built_view)
	if previous_view != null:
		_copy_mediapipe_camera_view_layout(previous_view, built_view)
		if previous_view.get_parent() != null:
			previous_view.replace_by(built_view)
		else:
			_camera_feed_host.add_child(built_view)
	else:
		_camera_feed_host.add_child(built_view)
		_camera_feed_host.move_child(built_view, 0)
	_mediapipe_camera_view = built_view
	_configure_mediapipe_camera_view_for_mode(_source_mode)
	if _mediapipe_camera_view.has_method("update_overlay"):
		_mediapipe_camera_view.update_overlay(_latest_pose_landmarks)
	if previous_view != null and previous_view != built_view:
		if previous_view.has_method("is_streaming") and bool(previous_view.is_streaming()) and previous_view.has_method("stop_stream"):
			previous_view.stop_stream()
		previous_view.queue_free()
	return true

func _apply_mediapipe_camera_view_defaults(camera_view: Variant) -> void:
	if camera_view == null:
		return
	if camera_view is Control:
		camera_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_set_object_property_if_present(camera_view, "expand_mode", TextureRect.EXPAND_IGNORE_SIZE)
	_set_object_property_if_present(camera_view, "stretch_mode", TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_set_object_property_if_present(camera_view, "stream_url", DEFAULT_MEDIAPIPE_STREAM_URL)
	_set_object_property_if_present(camera_view, "show_overlay", false)

func _copy_mediapipe_camera_view_layout(previous_view: Variant, next_view: Variant) -> void:
	if previous_view == null or next_view == null:
		return
	if previous_view is Control and next_view is Control:
		next_view.anchor_left = previous_view.anchor_left
		next_view.anchor_top = previous_view.anchor_top
		next_view.anchor_right = previous_view.anchor_right
		next_view.anchor_bottom = previous_view.anchor_bottom
		next_view.offset_left = previous_view.offset_left
		next_view.offset_top = previous_view.offset_top
		next_view.offset_right = previous_view.offset_right
		next_view.offset_bottom = previous_view.offset_bottom
		next_view.custom_minimum_size = previous_view.custom_minimum_size
		next_view.layout_mode = previous_view.layout_mode
		next_view.size_flags_horizontal = previous_view.size_flags_horizontal
		next_view.size_flags_vertical = previous_view.size_flags_vertical
		next_view.size_flags_stretch_ratio = previous_view.size_flags_stretch_ratio
	_set_object_property_if_present(next_view, "expand_mode", _get_object_property_if_present(previous_view, "expand_mode", TextureRect.EXPAND_IGNORE_SIZE))
	_set_object_property_if_present(next_view, "stretch_mode", _get_object_property_if_present(previous_view, "stretch_mode", TextureRect.STRETCH_KEEP_ASPECT_CENTERED))
	_set_object_property_if_present(next_view, "stream_url", _get_object_property_if_present(previous_view, "stream_url", DEFAULT_MEDIAPIPE_STREAM_URL))
	_set_object_property_if_present(next_view, "show_overlay", false)

func _get_object_property_if_present(target: Variant, property_name: String, fallback: Variant = null) -> Variant:
	if target == null:
		return fallback
	for property_data_variant: Variant in target.get_property_list():
		if not property_data_variant is Dictionary:
			continue
		if String((property_data_variant as Dictionary).get("name", "")) == property_name:
			return target.get(property_name)
	return fallback

func _set_object_property_if_present(target: Variant, property_name: String, value: Variant) -> void:
	if target == null:
		return
	for property_data_variant: Variant in target.get_property_list():
		if not property_data_variant is Dictionary:
			continue
		if String((property_data_variant as Dictionary).get("name", "")) == property_name:
			target.set(property_name, value)
			return

func _wire_mediapipe_backend_if_possible() -> void:
	if _mediapipe_input_source == null or not is_instance_valid(_mediapipe_input_source):
		_disconnect_mediapipe_backend_if_possible()
		return
	var backend: Variant = _mediapipe_input_source.get("_provider")
	if not (backend is Node):
		_disconnect_mediapipe_backend_if_possible()
		return
	if _mediapipe_provider_backend != backend:
		_disconnect_mediapipe_backend_if_possible()
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
		"fixture_runtime_config": _trace_store.to_json_safe(_fixture_runtime_config),
		"profile_path_edit": _profile_path_edit.text.strip_edges(),
		"source_mode": _source_mode,
		"source_mode_label": _source_mode_label(_source_mode),
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
	label.add_theme_font_size_override("font_size", SECTION_TITLE_FONT_SIZE)
	column.add_child(label)
	return column

func _apply_left_panel_readability_theme(node: Node) -> void:
	if node is Label:
		var label := node as Label
		if not label.has_theme_font_size_override("font_size"):
			label.add_theme_font_size_override("font_size", LEFT_PANEL_FONT_SIZE)
	elif node is Button:
		var button := node as Button
		button.add_theme_font_size_override("font_size", LEFT_PANEL_INPUT_FONT_SIZE)
	elif node is LineEdit:
		var line_edit := node as LineEdit
		line_edit.add_theme_font_size_override("font_size", LEFT_PANEL_INPUT_FONT_SIZE)
	elif node is OptionButton:
		var option := node as OptionButton
		option.add_theme_font_size_override("font_size", LEFT_PANEL_INPUT_FONT_SIZE)
	elif node is RichTextLabel:
		var rich_text := node as RichTextLabel
		rich_text.add_theme_font_size_override("normal_font_size", LEFT_PANEL_FONT_SIZE)
	for child in node.get_children():
		_apply_left_panel_readability_theme(child)

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

func _on_mediapipe_live_camera_selected(_index: int) -> void:
	if _suppress_mediapipe_live_camera_signal or _mediapipe_live_camera_option == null:
		return
	_selected_mediapipe_live_camera_id = _normalize_live_camera_selection(_get_selected_mediapipe_live_camera_option_id())
	_refresh_mediapipe_live_control_values()
	if _source_mode == SOURCE_MODE_MEDIAPIPE_LIVE:
		_apply_source_runtime_selection()
	else:
		_update_status("Selected live camera %s" % _build_active_camera_text())

func _on_mediapipe_tracking_quality_selected(_index: int) -> void:
	if _suppress_mediapipe_tracking_quality_signal or _mediapipe_tracking_quality_option == null:
		return
	_selected_mediapipe_tracking_quality = _normalize_tracking_quality_value(_get_option_value(_mediapipe_tracking_quality_option))
	_refresh_mediapipe_live_control_values()
	if _source_mode == SOURCE_MODE_MEDIAPIPE_LIVE:
		_apply_source_runtime_selection()
	else:
		_update_status("Tracking quality ready: %s" % _build_tracking_quality_summary_text())

func _on_media_inset_toggle_toggled(pressed: bool) -> void:
	_apply_media_inset_visibility(pressed)

func _apply_media_inset_visibility(media_inset_visible: bool) -> void:
	if _camera_feed_host != null:
		_camera_feed_host.visible = media_inset_visible
	if _media_inset_status_label != null:
		_media_inset_status_label.visible = media_inset_visible
	if _media_inset_panel != null:
		var target_height := MEDIA_INSET_HEIGHT if media_inset_visible else MEDIA_INSET_COLLAPSED_HEIGHT
		_media_inset_panel.offset_left = -MEDIA_INSET_WIDTH - PREVIEW_CORNER_MARGIN
		_media_inset_panel.offset_top = -target_height - PREVIEW_CORNER_MARGIN
		_media_inset_panel.offset_right = -PREVIEW_CORNER_MARGIN
		_media_inset_panel.offset_bottom = -PREVIEW_CORNER_MARGIN
	if _media_inset_toggle_button != null:
		_media_inset_toggle_button.text = TOGGLE_GLYPH_EXPANDED if media_inset_visible else TOGGLE_GLYPH_COLLAPSED
		_media_inset_toggle_button.tooltip_text = "Collapse media preview" if media_inset_visible else "Restore media preview"
	_update_status("Media preview %s" % ("shown" if media_inset_visible else "collapsed"))

func _on_debug_tabs_toggle_toggled(pressed: bool) -> void:
	_apply_debug_tabs_visibility(pressed)

func _apply_debug_tabs_visibility(debug_tabs_visible: bool) -> void:
	if _debug_tabs != null:
		_debug_tabs.visible = debug_tabs_visible
	if _debug_tabs_toggle_button != null:
		_debug_tabs_toggle_button.text = TOGGLE_GLYPH_EXPANDED if debug_tabs_visible else TOGGLE_GLYPH_COLLAPSED
		_debug_tabs_toggle_button.tooltip_text = "Collapse debug tabs" if debug_tabs_visible else "Restore debug tabs"
	_update_status("Debug tabs %s" % ("shown" if debug_tabs_visible else "hidden"))

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
