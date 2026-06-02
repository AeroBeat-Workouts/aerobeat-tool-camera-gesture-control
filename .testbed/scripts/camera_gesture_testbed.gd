extends Control

const MANAGER_SCRIPT := preload("res://addons/aerobeat-tool-camera-gesture-control/src/AeroCameraGestureControlManager.gd")
const CONTROLLER_SCRIPT := preload("res://addons/aerobeat-tool-camera-gesture-control/src/camera_gesture_controller.gd")
const FAKE_INPUT_SOURCE_SCRIPT := preload("res://scripts/fake_camera_input_source.gd")
const TRACKING_INSET_OVERLAY_SCRIPT := preload("res://scripts/tracking_inset_overlay.gd")
const TRACE_CAPTURE_STORE_SCRIPT := preload("res://scripts/trace_capture_store.gd")
const FIXTURE_RUNTIME_CONFIG_SCRIPT := preload("res://scripts/camera_gesture_fixture_runtime_config.gd")
const PREVIEW_SURFACE_SCRIPT := preload("res://scripts/camera_tracking_preview_surface.gd")
const VIDEO_PLAYER_MANAGER_SCRIPT := preload("res://addons/aerobeat-tool-video-player/src/AeroVideoPlayerManager.gd")
const GODOT_VIDEO_BACKEND_SCRIPT := preload("res://addons/aerobeat-vendor-godot-video/src/AeroGodotVideoBackend.gd")
const MEDIAPIPE_BACKEND_SCRIPT := preload("res://addons/aerobeat-vendor-mediapipe-python/src/MediaPipePythonCameraTrackingBackend.gd")
const MEDIAPIPE_RUNTIME_BRIDGE_SCRIPT := preload("res://addons/aerobeat-vendor-mediapipe-python/src/MediaPipePythonRuntimeBridge.gd")

const DEFAULT_PROFILE_REPO_RELATIVE_PATH := "../assets/profiles/camera_gesture/default_v1.camera_gesture.yaml"
const DEFAULT_FIXTURE_VIDEO_PATH := "res://assets/fixtures/camera_gesture/head_pose/candidates/head_rotate_left_repeat_04_take_01.mp4"
const DEFAULT_FIXTURE_SIDECAR_PATH := "res://assets/fixtures/camera_gesture/head_pose/candidates/head_rotate_left_repeat_04_take_01.fixture.yaml"
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
const STATUS_LABEL_FONT_SIZE := 16
const TITLE_FONT_SIZE := 26
const PREVIEW_TITLE_FONT_SIZE := 22
const MEDIA_TITLE_FONT_SIZE := 18
const SOURCE_MODE_FAKE := "fake"
const SOURCE_MODE_MEDIAPIPE_LIVE := "mediapipe_live"
const SOURCE_MODE_MEDIAPIPE_REPLAY := "mediapipe_replay"
const SOURCE_OPTIONS := [SOURCE_MODE_FAKE, SOURCE_MODE_MEDIAPIPE_LIVE, SOURCE_MODE_MEDIAPIPE_REPLAY]
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

var _manager: Node = null
var _controller: Node = null
var _camera_tracking: Node = null
var _fake_input_source = null
var _trace_store = null
var _fixture_runtime_helper = null

var _camera: Camera3D
var _world_root: Node3D
var _subviewport: SubViewport
var _status_label: Label
var _source_label: Label
var _tracking_label: Label
var _profile_identity_label: Label
var _source_option: OptionButton
var _mediapipe_live_camera_option: OptionButton
var _mediapipe_tracking_quality_option: OptionButton
var _fixture_video_path_edit: LineEdit
var _fixture_sidecar_path_edit: LineEdit
var _mediapipe_live_camera_row: VBoxContainer
var _mediapipe_tracking_quality_row: VBoxContainer
var _tracking_overlay
var _camera_feed_host: Control
var _media_inset_panel: PanelContainer
var _media_inset_toggle_button: Button
var _debug_tabs: TabContainer
var _debug_tabs_toggle_button: Button
var _preview_title_label: Label
var _media_title_label: Label

var _current_input_source: Node = null
var _mediapipe_camera_view = null
var _video_player_manager: Node = null
var _video_player_surface: Control = null
var _video_player_last_loaded_source := ""
var _video_player_last_error := ""
var _mediapipe_runtime_status := "inactive"
var _mediapipe_runtime_last_error := ""
var _selected_mediapipe_live_camera_id := "0"
var _selected_mediapipe_tracking_quality := "full"
var _suppress_mediapipe_live_camera_signal := false
var _suppress_mediapipe_tracking_quality_signal := false
var _source_mode := SOURCE_MODE_FAKE
var _latest_pose_landmarks: Array = []
var _latest_tracking_frame := {}
var _latest_tracking_state := {}
var _latest_source_snapshot := {}
var _fixture_runtime_config := {}

func _ready() -> void:
	name = "CameraGestureControlTestbed"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_trace_store = TRACE_CAPTURE_STORE_SCRIPT.new()
	_fixture_runtime_helper = FIXTURE_RUNTIME_CONFIG_SCRIPT.new()
	_manager = MANAGER_SCRIPT.new()
	_controller = CONTROLLER_SCRIPT.new()
	_fake_input_source = FAKE_INPUT_SOURCE_SCRIPT.new()
	add_child(_manager)
	add_child(_controller)
	add_child(_fake_input_source)
	_bind_layout_nodes()
	_populate_layout_controls()
	_build_world()
	_ensure_mediapipe_camera_view()
	_load_default_profile_on_boot()
	_switch_input_source(_source_mode)
	_update_status("Ready")
	set_process(true)

func _process(_delta: float) -> void:
	_latest_source_snapshot = _collect_source_snapshot()
	if _tracking_overlay != null:
		_tracking_overlay.set_display_rect(_current_tracking_overlay_display_rect())
		_tracking_overlay.update_snapshot(_latest_source_snapshot)
	_update_labels_from_controller()

func _notification(what: int) -> void:
	if what != NOTIFICATION_EXIT_TREE:
		return
	_teardown_mediapipe_runtime()
	_reset_video_player_surface()

func _bind_layout_nodes() -> void:
	var root_split := get_node("RootMargin/RootSplit") as HSplitContainer
	root_split.split_offset = LEFT_PANEL_SPLIT_OFFSET
	var left_scroll := get_node("RootMargin/RootSplit/LeftPanelScroll") as ScrollContainer
	left_scroll.custom_minimum_size = Vector2(LEFT_PANEL_MIN_WIDTH, 0.0)
	var title := get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/HeaderPanel/HeaderMargin/HeaderColumn/TitleLabel") as Label
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	_status_label = get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/HeaderPanel/HeaderMargin/HeaderColumn/StatusLabel") as Label
	_source_label = get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/HeaderPanel/HeaderMargin/HeaderColumn/SourceLabel") as Label
	_tracking_label = get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/HeaderPanel/HeaderMargin/HeaderColumn/TrackingLabel") as Label
	_profile_identity_label = get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/HeaderPanel/HeaderMargin/HeaderColumn/ProfileIdentityLabel") as Label
	for label in [_status_label, _source_label, _tracking_label, _profile_identity_label]:
		label.add_theme_font_size_override("font_size", STATUS_LABEL_FONT_SIZE)
	var preview_stack := get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack") as Control
	preview_stack.custom_minimum_size = PREVIEW_STACK_MIN_SIZE
	var viewport_container := get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/WorldPreviewViewportContainer") as SubViewportContainer
	viewport_container.stretch = false
	_subviewport = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/WorldPreviewViewportContainer/WorldPreviewViewport") as SubViewport
	_subviewport.size = DEFAULT_TESTBED_VIEWPORT_SIZE
	_preview_title_label = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/OverlayTop/PreviewTitleLabel") as Label
	_preview_title_label.add_theme_font_size_override("font_size", PREVIEW_TITLE_FONT_SIZE)
	_media_inset_panel = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel") as PanelContainer
	_media_inset_panel.anchor_left = 1.0
	_media_inset_panel.anchor_right = 1.0
	_media_inset_panel.anchor_top = 1.0
	_media_inset_panel.anchor_bottom = 1.0
	_media_inset_panel.offset_left = -(MEDIA_INSET_WIDTH + PREVIEW_CORNER_MARGIN)
	_media_inset_panel.offset_top = -(MEDIA_INSET_HEIGHT + PREVIEW_CORNER_MARGIN)
	_media_inset_panel.offset_right = -PREVIEW_CORNER_MARGIN
	_media_inset_panel.offset_bottom = -PREVIEW_CORNER_MARGIN
	_media_inset_toggle_button = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/MediaToolbar/MediaInsetToggleButton") as Button
	_media_inset_toggle_button.set_pressed_no_signal(true)
	_media_inset_toggle_button.toggled.connect(_on_media_toggle_toggled)
	_media_inset_toggle_button.text = TOGGLE_GLYPH_EXPANDED
	_media_title_label = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/MediaToolbar/MediaTitleLabel") as Label
	_media_title_label.add_theme_font_size_override("font_size", MEDIA_TITLE_FONT_SIZE)
	_camera_feed_host = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/CameraFeedHost") as Control
	_camera_feed_host.custom_minimum_size.y = CAMERA_FEED_MIN_HEIGHT
	_tracking_overlay = get_node("RootMargin/RootSplit/RightColumn/PreviewPanel/PreviewMargin/PreviewStack/MediaInsetPanel/MediaInsetMargin/MediaInsetColumn/CameraFeedHost/TrackingInsetOverlay")
	_debug_tabs = get_node("RootMargin/RootSplit/RightColumn/DebugTabs") as TabContainer
	_debug_tabs.custom_minimum_size.y = DEBUG_TABS_MIN_HEIGHT
	_debug_tabs_toggle_button = get_node("RootMargin/RootSplit/RightColumn/DebugToolbar/DebugTabsToggleButton") as Button
	_debug_tabs_toggle_button.set_pressed_no_signal(true)
	_debug_tabs_toggle_button.toggled.connect(_on_debug_tabs_toggle_toggled)
	_debug_tabs_toggle_button.text = TOGGLE_GLYPH_EXPANDED

func _populate_layout_controls() -> void:
	var source_section := get_node("RootMargin/RootSplit/LeftPanelScroll/LeftPanel/SourceSection/SourceMargin/SourceSectionContent") as VBoxContainer
	_source_option = OptionButton.new()
	for option in SOURCE_OPTIONS:
		_source_option.add_item(option)
	_source_option.item_selected.connect(_on_source_mode_selected)
	source_section.add_child(_labeled_control("Source mode", _source_option))
	_mediapipe_live_camera_option = OptionButton.new()
	_mediapipe_live_camera_option.item_selected.connect(_on_live_camera_selected)
	_mediapipe_live_camera_row = _labeled_control("Live camera", _mediapipe_live_camera_option)
	source_section.add_child(_mediapipe_live_camera_row)
	_mediapipe_tracking_quality_option = OptionButton.new()
	for option in MEDIAPIPE_TRACKING_QUALITY_OPTIONS:
		_mediapipe_tracking_quality_option.add_item(option)
	_mediapipe_tracking_quality_option.item_selected.connect(_on_mediapipe_tracking_quality_selected)
	_mediapipe_tracking_quality_row = _labeled_control("Tracking quality", _mediapipe_tracking_quality_option)
	source_section.add_child(_mediapipe_tracking_quality_row)
	_fixture_video_path_edit = LineEdit.new()
	_fixture_video_path_edit.text = DEFAULT_FIXTURE_VIDEO_PATH
	source_section.add_child(_labeled_control("Fixture video", _fixture_video_path_edit))
	_fixture_sidecar_path_edit = LineEdit.new()
	_fixture_sidecar_path_edit.text = DEFAULT_FIXTURE_SIDECAR_PATH
	source_section.add_child(_labeled_control("Fixture sidecar", _fixture_sidecar_path_edit))
	_set_option_value(_source_option, _source_mode)
	_set_option_value(_mediapipe_tracking_quality_option, _selected_mediapipe_tracking_quality)
	_refresh_live_camera_options()
	_refresh_source_mode_visibility()

func _labeled_control(label_text: String, control: Control) -> VBoxContainer:
	var row := VBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row

func _build_world() -> void:
	_world_root = Node3D.new()
	_world_root.name = "WorldRoot"
	_subviewport.add_child(_world_root)
	_camera = Camera3D.new()
	_camera.current = true
	_camera.position = Vector3(0.0, 1.6, 4.5)
	_world_root.add_child(_camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35.0, 30.0, 0.0)
	_world_root.add_child(light)
	_controller.attach_camera(_camera)

func _ensure_mediapipe_camera_view() -> void:
	if _mediapipe_camera_view != null and is_instance_valid(_mediapipe_camera_view):
		return
	var view = PREVIEW_SURFACE_SCRIPT.new()
	view.name = "MediaPipeCameraView"
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_camera_feed_host.add_child(view)
	_camera_feed_host.move_child(view, 0)
	_mediapipe_camera_view = view

func _load_default_profile_on_boot() -> void:
	var profile_path := ProjectSettings.globalize_path("res://%s" % DEFAULT_PROFILE_REPO_RELATIVE_PATH)
	if FileAccess.file_exists(profile_path):
		_controller.load_profile(profile_path)

func _ensure_camera_tracking() -> Node:
	if _camera_tracking != null and is_instance_valid(_camera_tracking):
		return _camera_tracking
	_camera_tracking = _manager.create_camera_tracking()
	if _camera_tracking != null:
		_camera_tracking.name = "CameraTracking"
		add_child(_camera_tracking)
		if _camera_tracking.has_signal("tracking_updated"):
			_camera_tracking.tracking_updated.connect(_on_camera_tracking_updated)
		if _camera_tracking.has_signal("state_changed"):
			_camera_tracking.state_changed.connect(_on_camera_tracking_state_changed)
		if _camera_tracking.has_signal("error_raised"):
			_camera_tracking.error_raised.connect(_on_camera_tracking_error_raised)
	return _camera_tracking

func _ensure_vendor_backend() -> bool:
	var tracking := _ensure_camera_tracking()
	if tracking == null:
		return false
	var backend = MEDIAPIPE_BACKEND_SCRIPT.new()
	var bridge = MEDIAPIPE_RUNTIME_BRIDGE_SCRIPT.new()
	backend.set_runtime_bridge(bridge)
	tracking.set_backend(backend, "mediapipe_python")
	return true

func _switch_input_source(mode: String) -> void:
	_source_mode = mode
	_set_option_value(_source_option, mode)
	_refresh_source_mode_visibility()
	if mode == SOURCE_MODE_FAKE:
		_teardown_mediapipe_runtime()
		_current_input_source = _fake_input_source
		_controller.attach_input_source(_fake_input_source)
		_update_status("Fake source active")
		return
	if not _ensure_vendor_backend():
		_update_status("CameraTracking backend unavailable")
		return
		
	_current_input_source = _ensure_camera_tracking()
	_controller.attach_camera_tracking(_current_input_source)
	await _start_owned_mediapipe_runtime_async(0, mode)

func _build_tracking_quality_settings() -> Dictionary:
	return (MEDIAPIPE_TRACKING_QUALITY_PRESETS.get(_selected_mediapipe_tracking_quality, MEDIAPIPE_TRACKING_QUALITY_PRESETS["full"]) as Dictionary).duplicate(true)

func _build_tracking_config_for_mode(mode: String) -> Dictionary:
	var settings := _build_tracking_quality_settings()
	var config := {}
	if mode == SOURCE_MODE_MEDIAPIPE_REPLAY:
		config = _manager.build_replay_camera_tracking_config(_fixture_video_path_edit.text.strip_edges())
		config["preview"] = {
			"enabled": false,
			"surface_mode": "attach",
			"flip_horizontal": false,
		}
	else:
		config = _manager.build_live_camera_tracking_config(_selected_mediapipe_live_camera_id)
		config["preview"] = {
			"enabled": true,
			"surface_mode": "attach",
			"flip_horizontal": true,
		}
	config["tracking"] = {
		"overlay_mode": str(settings.get("tracking_overlay_mode", "full")),
		"min_visibility": float(settings.get("min_visibility", 0.35)),
		"gesture_eval_interval_frames": int(settings.get("gesture_eval_interval_frames", 1)),
	}
	return config

func _mediapipe_start_settings_json_for_mode(mode: String) -> String:
	var config := _build_tracking_config_for_mode(mode)
	var settings := {
		"selected_camera_device_id": str(config.get("source", {}).get("camera_id", "")),
		"flip_horizontal": bool(config.get("preview", {}).get("flip_horizontal", true)),
		"tracking_overlay_mode": str(config.get("tracking", {}).get("overlay_mode", "off")),
		"gesture_eval_interval_frames": int(config.get("tracking", {}).get("gesture_eval_interval_frames", 1)),
		"min_visibility": float(config.get("tracking", {}).get("min_visibility", 0.35)),
	}
	return JSON.stringify(settings)

func _start_owned_mediapipe_runtime_async(_request_serial: int, requested_mode: String) -> void:
	var tracking := _ensure_camera_tracking()
	if tracking == null:
		_mediapipe_runtime_status = "error"
		return
	_mediapipe_runtime_status = "starting"
	_mediapipe_runtime_last_error = ""
	if _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("stop_stream"):
		_mediapipe_camera_view.stop_stream()
	var config := _build_tracking_config_for_mode(requested_mode)
	if requested_mode == SOURCE_MODE_MEDIAPIPE_REPLAY:
		tracking.detach_preview_surface()
		_sync_replay_video_surface(config)
	else:
		_ensure_mediapipe_camera_view()
		tracking.attach_preview_surface(_mediapipe_camera_view)
		if _video_player_manager != null and is_instance_valid(_video_player_manager) and _video_player_manager.has_method("unload"):
			_video_player_manager.unload()
			_video_player_last_loaded_source = ""
			_video_player_last_error = ""
	if tracking.is_running():
		tracking.change(config)
	else:
		tracking.start(config)
	if requested_mode == SOURCE_MODE_MEDIAPIPE_LIVE and _mediapipe_camera_view != null and _mediapipe_camera_view.has_method("start_stream"):
		_mediapipe_camera_view.start_stream()
	_mediapipe_runtime_status = "ready" if tracking.get_state().get("state", "") == "running" else str(tracking.get_state().get("state", "starting"))
	_update_status("%s active" % _source_mode_label(requested_mode))

func _sync_replay_video_surface(config: Dictionary) -> void:
	if not _ensure_video_player_surface_if_possible():
		return
	var replay_source_path := str(config.get("source", {}).get("path", "")).strip_edges()
	if replay_source_path.is_empty():
		return
	if _video_player_manager.has_method("attach_surface"):
		_video_player_manager.attach_surface(_video_player_surface)
	if replay_source_path != _video_player_last_loaded_source and _video_player_manager.has_method("load"):
		_video_player_last_loaded_source = replay_source_path
		_video_player_last_error = ""
		_video_player_manager.load({
			"path": replay_source_path,
			"kind": "file",
			"autoplay": true,
			"fit_mode": "contain",
		})
	if _video_player_manager.has_method("play"):
		_video_player_manager.play()

func _ensure_video_player_surface_if_possible() -> bool:
	if _video_player_surface == null or not is_instance_valid(_video_player_surface):
		var surface := Control.new()
		surface.name = "ReplayVideoSurface"
		surface.set_anchors_preset(Control.PRESET_FULL_RECT)
		_camera_feed_host.add_child(surface)
		_camera_feed_host.move_child(surface, 0)
		_video_player_surface = surface
	if _video_player_manager != null and is_instance_valid(_video_player_manager):
		return true
	_video_player_manager = VIDEO_PLAYER_MANAGER_SCRIPT.new()
	add_child(_video_player_manager)
	var backend = GODOT_VIDEO_BACKEND_SCRIPT.new()
	_video_player_manager.set_backend(backend)
	if _video_player_manager.has_signal("error_raised"):
		_video_player_manager.error_raised.connect(_on_video_player_error_raised)
	if _video_player_manager.has_signal("media_loaded"):
		_video_player_manager.media_loaded.connect(_on_video_player_media_loaded)
	if _video_player_manager.has_method("attach_surface"):
		_video_player_manager.attach_surface(_video_player_surface)
	return true

func _reset_video_player_surface() -> void:
	_video_player_last_loaded_source = ""
	_video_player_last_error = ""
	if _video_player_manager != null and is_instance_valid(_video_player_manager) and _video_player_manager.has_method("unload"):
		_video_player_manager.unload()
	if _video_player_surface != null and is_instance_valid(_video_player_surface):
		_video_player_surface.queue_free()
	_video_player_surface = null
	if _video_player_manager != null and is_instance_valid(_video_player_manager):
		_video_player_manager.queue_free()
	_video_player_manager = null

func _teardown_mediapipe_runtime() -> void:
	if _camera_tracking != null and is_instance_valid(_camera_tracking):
		if _camera_tracking.has_method("stop"):
			_camera_tracking.stop()
		if _camera_tracking.has_method("detach_preview_surface"):
			_camera_tracking.detach_preview_surface()
	_mediapipe_runtime_status = "inactive"
	_current_input_source = null

func _collect_source_snapshot() -> Dictionary:
	if _source_mode == SOURCE_MODE_FAKE:
		return {
			"source_mode": _source_mode,
			"tracking": _fake_input_source.is_tracking(),
			"tracking_overlay_mode": "off",
			"pose_landmarks": [],
			"head_position": _fake_input_source.get_head_position(),
			"head_velocity": _fake_input_source.get_head_velocity(),
		}
	var settings := _build_tracking_quality_settings()
	var frame: Dictionary = _latest_tracking_frame.duplicate(true)
	if frame.is_empty() and _camera_tracking != null and is_instance_valid(_camera_tracking) and _camera_tracking.has_method("get_tracking_frame"):
		frame = _camera_tracking.get_tracking_frame()
	return {
		"source_mode": _source_mode,
		"tracking": bool(_latest_tracking_state.get("tracking", false)),
		"tracking_overlay_mode": str(settings.get("tracking_overlay_mode", "off")),
		"tracking_min_visibility": float(settings.get("min_visibility", 0.35)),
		"pose_landmarks": frame.get("landmarks", []).duplicate(true),
		"head_position": _controller.get_debug_state().get("current_translation", Vector3.ZERO),
		"head_velocity": Vector3.ZERO,
		"tracking_state": frame.get("tracking_state", ""),
	}

func _collect_provider_snapshot() -> Dictionary:
	var tracking_state := {}
	var preview_descriptor := {}
	var active_config := {}
	if _camera_tracking != null and is_instance_valid(_camera_tracking):
		tracking_state = _camera_tracking.get_state()
		preview_descriptor = _camera_tracking.get_preview_descriptor()
		active_config = _camera_tracking.get_active_config()
	return {
		"source_mode": _source_mode,
		"runtime_status": _mediapipe_runtime_status,
		"tracking_session_state": tracking_state,
		"preview_descriptor": preview_descriptor,
		"active_config": active_config,
		"replay_surface_ready": _video_player_surface != null and is_instance_valid(_video_player_surface),
		"video_player_loaded_source": _video_player_last_loaded_source,
	}

func _current_tracking_overlay_display_rect() -> Rect2:
	var target: Control = _mediapipe_camera_view if _mediapipe_camera_view != null and is_instance_valid(_mediapipe_camera_view) else _camera_feed_host
	if target == null:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	if target.has_method("_get_displayed_image_size") and target.has_method("_get_displayed_image_offset"):
		var displayed_size: Vector2 = target._get_displayed_image_size()
		var displayed_offset: Vector2 = target._get_displayed_image_offset(displayed_size)
		return Rect2(displayed_offset, displayed_size)
	return Rect2(Vector2.ZERO, target.size)

func _refresh_live_camera_options() -> void:
	if _mediapipe_live_camera_option == null:
		return
	_suppress_mediapipe_live_camera_signal = true
	_mediapipe_live_camera_option.clear()
	var cameras: Array = []
	if _camera_tracking != null and is_instance_valid(_camera_tracking) and _camera_tracking.has_method("list_cameras"):
		cameras = _camera_tracking.list_cameras()
	if cameras.is_empty():
		cameras = [{"id": "0", "label": "Default camera"}]
	for camera_entry in cameras:
		var camera_id := str(camera_entry.get("id", "0"))
		var label := str(camera_entry.get("label", camera_id))
		_mediapipe_live_camera_option.add_item(label)
		_mediapipe_live_camera_option.set_item_metadata(_mediapipe_live_camera_option.item_count - 1, camera_id)
	if _mediapipe_live_camera_option.item_count > 0:
		for index in range(_mediapipe_live_camera_option.item_count):
			if str(_mediapipe_live_camera_option.get_item_metadata(index)) == _selected_mediapipe_live_camera_id:
				_mediapipe_live_camera_option.select(index)
				break
	_suppress_mediapipe_live_camera_signal = false

func _refresh_source_mode_visibility() -> void:
	var live_controls_visible := _source_mode == SOURCE_MODE_MEDIAPIPE_LIVE
	if _mediapipe_live_camera_row != null:
		_mediapipe_live_camera_row.visible = live_controls_visible
	if _mediapipe_tracking_quality_row != null:
		_mediapipe_tracking_quality_row.visible = live_controls_visible
	if _video_player_surface != null and is_instance_valid(_video_player_surface):
		_video_player_surface.visible = _source_mode == SOURCE_MODE_MEDIAPIPE_REPLAY
	if _mediapipe_camera_view != null and is_instance_valid(_mediapipe_camera_view):
		_mediapipe_camera_view.visible = _source_mode != SOURCE_MODE_MEDIAPIPE_REPLAY

func _set_option_value(option_button: OptionButton, value: String) -> void:
	for index in range(option_button.item_count):
		if option_button.get_item_text(index) == value or str(option_button.get_item_metadata(index)) == value:
			option_button.select(index)
			return

func _source_mode_label(mode: String) -> String:
	match mode:
		SOURCE_MODE_MEDIAPIPE_LIVE:
			return "CameraTracking live"
		SOURCE_MODE_MEDIAPIPE_REPLAY:
			return "CameraTracking replay"
		_:
			return "Fake"

func _update_labels_from_controller() -> void:
	_source_label.text = "Input source: %s" % _source_mode_label(_source_mode)
	var tracking_state: Dictionary = _controller.get_debug_state().get("tracking_state", {})
	_tracking_label.text = "Tracking: %s | confidence %.2f / %.2f" % [
		"active" if bool(tracking_state.get("tracking", false)) else "inactive",
		float(tracking_state.get("confidence", 0.0)),
		float(tracking_state.get("threshold", 0.0)),
	]
	var active_profile: Dictionary = _controller.get_debug_state().get("active_profile", {})
	_profile_identity_label.text = "Profile: %s" % str(active_profile.get("profile_id", "default_v1"))
	_preview_title_label.text = "16:9 harness — %s" % _source_mode_label(_source_mode)
	_media_title_label.text = "Media / Tracking Inset"

func _update_status(text: String) -> void:
	_status_label.text = text

func _on_source_mode_selected(index: int) -> void:
	_switch_input_source(_source_option.get_item_text(index))

func _on_live_camera_selected(index: int) -> void:
	if _suppress_mediapipe_live_camera_signal:
		return
	_selected_mediapipe_live_camera_id = str(_mediapipe_live_camera_option.get_item_metadata(index))
	if _source_mode == SOURCE_MODE_MEDIAPIPE_LIVE:
		await _start_owned_mediapipe_runtime_async(0, _source_mode)

func _on_mediapipe_tracking_quality_selected(index: int) -> void:
	if _suppress_mediapipe_tracking_quality_signal:
		return
	_selected_mediapipe_tracking_quality = _mediapipe_tracking_quality_option.get_item_text(index)
	if _source_mode != SOURCE_MODE_FAKE:
		await _start_owned_mediapipe_runtime_async(0, _source_mode)

func _on_media_toggle_toggled(pressed: bool) -> void:
	_camera_feed_host.visible = pressed
	_media_inset_toggle_button.text = TOGGLE_GLYPH_EXPANDED if pressed else TOGGLE_GLYPH_COLLAPSED
	_media_inset_panel.offset_top = -(MEDIA_INSET_HEIGHT + PREVIEW_CORNER_MARGIN) if pressed else -(MEDIA_INSET_COLLAPSED_HEIGHT + PREVIEW_CORNER_MARGIN)

func _on_debug_tabs_toggle_toggled(pressed: bool) -> void:
	_debug_tabs.visible = pressed
	_debug_tabs_toggle_button.text = TOGGLE_GLYPH_EXPANDED if pressed else TOGGLE_GLYPH_COLLAPSED

func _on_camera_tracking_updated(frame: Dictionary) -> void:
	_latest_tracking_frame = frame.duplicate(true)
	_latest_pose_landmarks = frame.get("landmarks", []).duplicate(true)

func _on_camera_tracking_state_changed(state: String, detail: Dictionary) -> void:
	_mediapipe_runtime_status = state
	_latest_tracking_state = {
		"tracking": bool(detail.get("tracking_ready", false)),
		"confidence": float(_controller.get_debug_state().get("tracking_state", {}).get("confidence", 0.0)),
		"threshold": float(_controller.get_debug_state().get("tracking_state", {}).get("threshold", 0.0)),
	}
	_refresh_live_camera_options()

func _on_camera_tracking_error_raised(error_info: Dictionary) -> void:
	_mediapipe_runtime_last_error = str(error_info.get("message", "camera tracking error"))
	_mediapipe_runtime_status = "error"

func _on_video_player_media_loaded(_info: Dictionary) -> void:
	_video_player_last_error = ""

func _on_video_player_error_raised(error_info: Dictionary) -> void:
	_video_player_last_error = str(error_info.get("message", "video player load failed"))

func _on_mediapipe_server_started(_pid: int) -> void:
	_mediapipe_runtime_status = "stabilizing"
