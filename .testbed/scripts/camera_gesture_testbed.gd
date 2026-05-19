extends Control

const CONTROLLER_SCRIPT := preload("res://src/camera_gesture_controller.gd")
const FAKE_INPUT_SOURCE_SCRIPT := preload("res://scripts/fake_camera_input_source.gd")
const TESTBED_PROFILE_PATH := "user://camera_gesture_profile.camera_gesture.yaml"
const MEDIAPIPE_PROVIDER_PATH := "res://addons/aerobeat-input-mediapipe-python/src/input_provider.gd"

var _controller: CameraGestureController
var _camera: Camera3D
var _world_root: Node3D
var _subviewport: SubViewport
var _status_label: Label
var _source_label: Label
var _debug_label: RichTextLabel
var _profile_path_edit: LineEdit
var _field_refs := {}
var _fake_controls := {}
var _current_input_source: Node = null
var _fake_input_source: FakeCameraInputSource
var _mediapipe_input_source: Node = null
var _source_mode := "fake"
var _source_option: OptionButton
var _gesture_status_label: Label

func _ready() -> void:
	name = "CameraGestureControlTestbed"
	set_anchors_preset(Control.PRESET_FULL_RECT)
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
	_controller.apply_profile(_controller.get_profile())
	_apply_profile_to_ui(_controller.get_profile())
	_switch_input_source(_source_mode)
	_update_status("Ready")
	set_process(true)

func _process(_delta: float) -> void:
	if _current_input_source == _fake_input_source and _fake_input_source != null:
		if _fake_controls.has("tracking"):
			_fake_input_source.tracking = _fake_controls["tracking"].button_pressed
		if _fake_controls.has("confidence"):
			_fake_input_source.confidence = _fake_controls["confidence"].value
		if _fake_controls.has("animate"):
			_fake_input_source.animate = _fake_controls["animate"].button_pressed
	_update_debug_panel()

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		if _mediapipe_input_source != null and _mediapipe_input_source.has_method("stop"):
			_mediapipe_input_source.stop()

func _build_layout() -> void:
	var root := HSplitContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.split_offset = 360
	add_child(root)

	var left_scroll := ScrollContainer.new()
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.custom_minimum_size = Vector2(320, 0)
	root.add_child(left_scroll)

	var left_panel := VBoxContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.add_theme_constant_override("separation", 10)
	left_panel.custom_minimum_size = Vector2(330, 720)
	left_scroll.add_child(left_panel)

	var title := Label.new()
	title.text = "Camera Gesture Control Testbed"
	title.add_theme_font_size_override("font_size", 24)
	left_panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Compare gesture control against mouse + WASD, tune the controller profile, and round-trip YAML-first profile saves."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_panel.add_child(subtitle)

	_status_label = Label.new()
	_status_label.text = "Status: booting"
	left_panel.add_child(_status_label)

	_source_label = Label.new()
	_source_label.text = "Input source: booting"
	left_panel.add_child(_source_label)

	_gesture_status_label = Label.new()
	_gesture_status_label.text = "Tracking: unknown"
	left_panel.add_child(_gesture_status_label)

	_source_option = _add_option(left_panel, "Input source", ["fake", "mediapipe_python"], _on_source_mode_selected)
	_field_refs["enabled"] = _add_toggle(left_panel, "Enabled", true, _on_profile_field_changed)
	_field_refs["mode"] = _add_option(left_panel, "Control mode", ["gesture", "mouse_wasd", "disabled"], _on_profile_field_changed)
	_field_refs["sample_source"] = _add_option(left_panel, "Sample source", ["head_position", "head_velocity", "head_rotation"], _on_profile_field_changed)
	_field_refs["invert_x"] = _add_toggle(left_panel, "Invert X", false, _on_profile_field_changed)
	_field_refs["invert_y"] = _add_toggle(left_panel, "Invert Y", false, _on_profile_field_changed)
	_field_refs["freeze_on_tracking_loss"] = _add_toggle(left_panel, "Freeze on tracking loss", true, _on_profile_field_changed)
	_field_refs["look_sensitivity_x"] = _add_slider(left_panel, "Look sensitivity X", 0.1, 3.0, 0.05, 1.0, _on_profile_field_changed)
	_field_refs["look_sensitivity_y"] = _add_slider(left_panel, "Look sensitivity Y", 0.1, 3.0, 0.05, 1.0, _on_profile_field_changed)
	_field_refs["translation_sensitivity_x"] = _add_slider(left_panel, "Translation sensitivity X", 0.1, 3.0, 0.05, 1.0, _on_profile_field_changed)
	_field_refs["translation_sensitivity_y"] = _add_slider(left_panel, "Translation sensitivity Y", 0.1, 3.0, 0.05, 0.6, _on_profile_field_changed)
	_field_refs["translation_sensitivity_z"] = _add_slider(left_panel, "Translation sensitivity Z", 0.1, 3.0, 0.05, 0.4, _on_profile_field_changed)
	_field_refs["max_yaw_degrees"] = _add_slider(left_panel, "Max yaw degrees", 0.0, 60.0, 1.0, 20.0, _on_profile_field_changed)
	_field_refs["max_pitch_degrees"] = _add_slider(left_panel, "Max pitch degrees", 0.0, 45.0, 1.0, 12.0, _on_profile_field_changed)
	_field_refs["max_roll_degrees"] = _add_slider(left_panel, "Max roll degrees", 0.0, 30.0, 1.0, 4.0, _on_profile_field_changed)
	_field_refs["max_translation_x"] = _add_slider(left_panel, "Max translation X", 0.0, 2.0, 0.01, 0.6, _on_profile_field_changed)
	_field_refs["max_translation_y"] = _add_slider(left_panel, "Max translation Y", 0.0, 2.0, 0.01, 0.35, _on_profile_field_changed)
	_field_refs["max_translation_z"] = _add_slider(left_panel, "Max translation Z", 0.0, 2.0, 0.01, 0.45, _on_profile_field_changed)
	_field_refs["smoothing"] = _add_slider(left_panel, "Smoothing", 0.0, 1.0, 0.01, 0.2, _on_profile_field_changed)
	_field_refs["deadzone"] = _add_slider(left_panel, "Deadzone", 0.0, 0.5, 0.01, 0.03, _on_profile_field_changed)
	_field_refs["recenter_speed"] = _add_slider(left_panel, "Recenter speed", 0.0, 10.0, 0.1, 1.8, _on_profile_field_changed)
	_field_refs["tracking_confidence_threshold"] = _add_slider(left_panel, "Tracking confidence threshold", 0.0, 1.0, 0.01, 0.45, _on_profile_field_changed)

	var fake_header := Label.new()
	fake_header.text = "Fake input source controls"
	fake_header.add_theme_font_size_override("font_size", 18)
	left_panel.add_child(fake_header)
	_fake_controls["tracking"] = _add_toggle(left_panel, "Fake tracking active", true, _on_fake_control_changed)
	_fake_controls["confidence"] = _add_slider(left_panel, "Fake confidence", 0.0, 1.0, 0.01, 1.0, _on_fake_control_changed)
	_fake_controls["animate"] = _add_toggle(left_panel, "Animate fake input", true, _on_fake_control_changed)

	var profile_header := Label.new()
	profile_header.text = "Profile save/load (YAML-first)"
	profile_header.add_theme_font_size_override("font_size", 18)
	left_panel.add_child(profile_header)

	_profile_path_edit = LineEdit.new()
	_profile_path_edit.text = TESTBED_PROFILE_PATH
	left_panel.add_child(_profile_path_edit)

	var button_row := HBoxContainer.new()
	left_panel.add_child(button_row)
	var save_button := Button.new()
	save_button.text = "Save profile"
	save_button.pressed.connect(_save_profile)
	button_row.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "Load profile"
	load_button.pressed.connect(_load_profile)
	button_row.add_child(load_button)
	var reset_button := Button.new()
	reset_button.text = "Reset defaults"
	reset_button.pressed.connect(_reset_profile)
	button_row.add_child(reset_button)

	var right_panel := VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_constant_override("separation", 8)
	root.add_child(right_panel)

	var viewport_container := SubViewportContainer.new()
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(viewport_container)

	_subviewport = SubViewport.new()
	_subviewport.size = Vector2i(1280, 720)
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(_subviewport)

	_debug_label = RichTextLabel.new()
	_debug_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_debug_label.custom_minimum_size = Vector2(0, 220)
	_debug_label.bbcode_enabled = false
	right_panel.add_child(_debug_label)

func _build_world() -> void:
	_world_root = Node3D.new()
	_subviewport.add_child(_world_root)

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.10)
	environment.environment = env
	_world_root.add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -20.0, 0.0)
	_world_root.add_child(sun)

	var fill := OmniLight3D.new()
	fill.position = Vector3(0.0, 2.0, 0.0)
	fill.light_energy = 1.5
	_world_root.add_child(fill)

	var ground := MeshInstance3D.new()
	ground.mesh = PlaneMesh.new()
	ground.scale = Vector3(8.0, 1.0, 8.0)
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.12, 0.16, 0.21)
	ground.material_override = ground_material
	_world_root.add_child(ground)

	for x in range(-2, 3):
		for z in range(-2, 3):
			var cube := MeshInstance3D.new()
			cube.mesh = BoxMesh.new()
			cube.position = Vector3(x * 1.5, 0.5 + absf(float(x * z)) * 0.05, z * 1.5)
			var cube_material := StandardMaterial3D.new()
			cube_material.albedo_color = Color.from_hsv(float(x + 2) / 5.0, 0.65, 0.95)
			cube.material_override = cube_material
			_world_root.add_child(cube)

	_camera = Camera3D.new()
	_camera.current = true
	_camera.position = Vector3(0.0, 1.6, 4.5)
	_world_root.add_child(_camera)
	_camera.look_at_from_position(_camera.position, Vector3(0.0, 1.2, 0.0))

func _setup_sources() -> void:
	_fake_input_source = FAKE_INPUT_SOURCE_SCRIPT.new()
	_fake_input_source.name = "FakeCameraInputSource"
	add_child(_fake_input_source)

	if ResourceLoader.exists(MEDIAPIPE_PROVIDER_PATH):
		var script: GDScript = load(MEDIAPIPE_PROVIDER_PATH)
		if script != null:
			_mediapipe_input_source = script.new()
			_mediapipe_input_source.name = "MediaPipePythonInputSource"
			add_child(_mediapipe_input_source)
			if _mediapipe_input_source.has_method("start"):
				var started: bool = bool(_mediapipe_input_source.start("{}"))
				if not started:
					_mediapipe_input_source = null
	if _mediapipe_input_source == null:
		_source_mode = "fake"
		_source_option.selected = 0
		_source_option.set_item_disabled(1, true)

func _switch_input_source(mode: String) -> void:
	_source_mode = mode
	match mode:
		"mediapipe_python":
			if _mediapipe_input_source != null and _controller.attach_input_source(_mediapipe_input_source):
				_current_input_source = _mediapipe_input_source
				_update_status("Using MediaPipe Python input source")
			else:
				_current_input_source = _fake_input_source
				_controller.attach_input_source(_fake_input_source)
				_update_status("MediaPipe unavailable; fell back to fake source")
		_:
			_current_input_source = _fake_input_source
			_controller.attach_input_source(_fake_input_source)
			_update_status("Using fake input source")
	_source_label.text = "Input source: %s" % _source_mode
	for control in _fake_controls.values():
		control.visible = _current_input_source == _fake_input_source

func _save_profile() -> void:
	_apply_ui_to_controller_profile()
	var result := _controller.save_profile(_profile_path_edit.text)
	if result.is_empty():
		_update_status("Failed to save profile")
		return
	_update_status("Saved profile to %s" % _profile_path_edit.text)

func _load_profile() -> void:
	var profile := _controller.load_profile(_profile_path_edit.text)
	if profile.is_empty():
		_update_status("Failed to load profile")
		return
	_apply_profile_to_ui(profile)
	_update_status("Loaded profile from %s" % _profile_path_edit.text)

func _reset_profile() -> void:
	_controller.apply_profile(CONTROLLER_SCRIPT.DEFAULT_PROFILE)
	_apply_profile_to_ui(_controller.get_profile())
	_update_status("Reset controller profile to defaults")

func _apply_ui_to_controller_profile() -> void:
	var profile := _controller.get_profile()
	profile["mode"] = _get_option_value(_field_refs["mode"])
	profile["sample_source"] = _get_option_value(_field_refs["sample_source"])
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
	_set_option_value(_field_refs["mode"], String(profile.get("mode", "gesture")))
	_set_option_value(_field_refs["sample_source"], String(profile.get("sample_source", "head_position")))
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

func _update_debug_panel() -> void:
	var debug_state := _controller.get_debug_state()
	var lines := [
		"Mode: %s" % debug_state.get("control_mode", ""),
		"Enabled: %s" % debug_state.get("enabled", false),
		"Current source: %s" % _source_mode,
		"Camera attached: %s" % debug_state.get("camera_attached", false),
		"Input source attached: %s" % debug_state.get("input_source_attached", false),
		"",
		"Active profile:",
		JSON.stringify(debug_state.get("active_profile", {}), "\t"),
		"",
		"Tracking state:",
		JSON.stringify(debug_state.get("tracking_state", {}), "\t"),
		"",
		"Profile:",
		JSON.stringify(debug_state.get("profile", {}), "\t"),
	]
	_debug_label.text = "\n".join(lines)

func _update_status(message: String) -> void:
	_status_label.text = "Status: %s" % message

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

func _add_option(parent: VBoxContainer, label_text: String, values: Array[String], callback: Callable) -> OptionButton:
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
	_gesture_status_label.text = "Tracking: mode=%s" % mode

func _on_tracking_state_changed(state: Dictionary) -> void:
	_gesture_status_label.text = "Tracking: %s | confidence %.2f / %.2f" % [
		"active" if bool(state.get("tracking", false)) else "inactive",
		float(state.get("confidence", 0.0)),
		float(state.get("threshold", 0.0)),
	]

func _on_profile_loaded(_profile: Dictionary) -> void:
	_update_status("Profile loaded")

func _on_profile_saved(path: String) -> void:
	_update_status("Profile saved to %s" % path)
