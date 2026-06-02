extends GutTest

const README_PATH := "../README.md"
const PLUGIN_CFG_PATH := "../plugin.cfg"
const ADDONS_MANIFEST_PATH := "addons.jsonc"
const DEFAULT_PROFILE_PATH := "../assets/profiles/camera_gesture/default_v1.camera_gesture.yaml"
const MANAGER_SCRIPT_PATH := "../src/AeroCameraGestureControlManager.gd"
const CONTROLLER_SCRIPT_PATH := "../src/camera_gesture_controller.gd"
const CAMERA_TRACKING_INPUT_SOURCE_PATH := "../src/camera_tracking_input_source.gd"

func _read_repo_file(relative_path: String) -> String:
	var absolute_path := ProjectSettings.globalize_path("res://%s" % relative_path)
	assert_true(FileAccess.file_exists(absolute_path), "Expected repo file to exist: %s" % absolute_path)
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	assert_true(file != null, "Expected repo file to open: %s" % absolute_path)
	return file.get_as_text()

func test_readme_states_camera_tracking_boundary_truth() -> void:
	var readme_text := _read_repo_file(README_PATH)
	assert_true(readme_text.contains("Repo-root `src/` consumes `aerobeat-tool-camera-tracking`"), "README should state that repo-root src consumes the camera-tracking tool boundary")
	assert_true(readme_text.contains("Repo-root `src/` does **not** know about `aerobeat-vendor-mediapipe-python`"), "README should state that repo-root src stays vendor-clean")
	assert_true(readme_text.contains("Hidden `.testbed/` is the only proving ground allowed to mount concrete backend deps through GodotEnv"), "README should keep concrete backend dependencies in the hidden proving layer")
	assert_true(readme_text.contains("live camera and replay/video-file flows both pass through `CameraTracking`"), "README should lock live and replay behind CameraTracking")
	assert_true(readme_text.contains("replay preview delegated through `aerobeat-tool-video-player` + `aerobeat-vendor-godot-video`"), "README should describe the replay preview stack under the tracking boundary")
	assert_true(readme_text.contains("16:9 harness"), "README should describe the proving scene layout")
	assert_true(readme_text.contains("YAML"), "README should explain the YAML profile contract")
	assert_false(readme_text.contains("tracker-agnostic and input-core-facing"), "README should no longer preserve the old tracker/input-core-era boundary wording")
	assert_false(readme_text.contains("AeroProviderSessionRegistry"), "README should no longer preserve provider-session-registry wording")
	assert_false(readme_text.contains("aerobeat-input-mediapipe-python"), "README should no longer document the retired direct input-mediapipe dependency")

func test_repo_root_src_stays_vendor_clean_and_tracking_bound() -> void:
	var manager_text := _read_repo_file(MANAGER_SCRIPT_PATH)
	var controller_text := _read_repo_file(CONTROLLER_SCRIPT_PATH)
	var input_adapter_text := _read_repo_file(CAMERA_TRACKING_INPUT_SOURCE_PATH)
	assert_true(manager_text.contains("aerobeat-tool-camera-tracking/src/CameraTracking.gd"), "Manager should load CameraTracking from the tool-camera-tracking package")
	assert_true(controller_text.contains("attach_camera_tracking"), "Controller should expose the CameraTracking attachment seam")
	assert_true(input_adapter_text.contains("get_tracking_frame") and input_adapter_text.contains("get_state"), "Input adapter should consume the public CameraTracking frame/state surface")
	assert_false(manager_text.contains("aerobeat-vendor-mediapipe-python"), "Manager should not know about the vendor MediaPipe package")
	assert_false(controller_text.contains("aerobeat-vendor-mediapipe-python"), "Controller should not know about the vendor MediaPipe package")
	assert_false(input_adapter_text.contains("aerobeat-vendor-mediapipe-python"), "Tracking input adapter should not know about the vendor MediaPipe package")

func test_plugin_cfg_matches_camera_gesture_control_identity() -> void:
	var config := ConfigFile.new()
	var error := config.load(ProjectSettings.globalize_path("res://%s" % PLUGIN_CFG_PATH))
	assert_eq(error, OK, "plugin.cfg should parse cleanly")
	assert_eq(config.get_value("plugin", "name", ""), "AeroBeat Camera Gesture Control")
	assert_true(String(config.get_value("plugin", "description", "")).contains("contract-driven camera controller"))
	assert_eq(config.get_value("plugin", "version", ""), "0.3.0")

func test_addons_manifest_includes_tracking_boundary_proving_stack() -> void:
	var manifest_text := _read_repo_file(ADDONS_MANIFEST_PATH)
	assert_true(manifest_text.contains('"aerobeat-tool-camera-tracking"'), "addons manifest should mount the CameraTracking contract addon for the hidden proving path")
	assert_true(manifest_text.contains('"aerobeat-vendor-mediapipe-python"'), "addons manifest should mount the MediaPipe backend behind CameraTracking for the hidden proving path")
	assert_true(manifest_text.contains('"aerobeat-tool-video-player"'), "addons manifest should mount the replay video-player facade")
	assert_true(manifest_text.contains('"aerobeat-vendor-godot-video"'), "addons manifest should mount the replay playback backend")
	assert_false(manifest_text.contains('"aerobeat-input-mediapipe-python"'), "addons manifest should no longer mount the old direct input provider seam")
	assert_true(manifest_text.contains('"aerobeat-tool-headless-manager"'), "addons manifest should mount the headless-manager autoload dependency for approved headless runs")
	assert_true(manifest_text.contains('"aerobeat-vendor-godot-unit-test"'), "addons manifest should keep GUT for repo-local validation")

func test_project_autoloads_headless_manager_with_truthful_contract() -> void:
	var config := ConfigFile.new()
	var error := config.load(ProjectSettings.globalize_path("res://project.godot"))
	assert_eq(error, OK, "project.godot should parse cleanly")
	assert_eq(
		config.get_value("autoload", "AeroHeadlessManager", ""),
		"*res://addons/aerobeat-tool-headless-manager/src/AeroHeadlessManager.gd",
		"Testbed should autoload AeroHeadlessManager from the mounted addon path"
	)

func test_default_yaml_profile_exists() -> void:
	var default_profile_path := ProjectSettings.globalize_path("res://%s" % DEFAULT_PROFILE_PATH)
	assert_true(FileAccess.file_exists(default_profile_path), "Checked-in default YAML profile should exist")
	var profile_text := _read_repo_file(DEFAULT_PROFILE_PATH)
	assert_true(profile_text.contains("schema:"), "Default profile should declare schema metadata")
	assert_true(profile_text.contains("profile_id: default_v1"), "Default profile should expose the default profile id")
