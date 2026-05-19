extends GutTest

const README_PATH := "../README.md"
const PLUGIN_CFG_PATH := "../plugin.cfg"
const ADDONS_MANIFEST_PATH := "addons.jsonc"
const DEFAULT_PROFILE_PATH := "../assets/profiles/camera_gesture/default_v1.camera_gesture.yaml"

func _read_repo_file(relative_path: String) -> String:
	var absolute_path := ProjectSettings.globalize_path("res://%s" % relative_path)
	assert_true(FileAccess.file_exists(absolute_path), "Expected repo file to exist: %s" % absolute_path)
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	assert_true(file != null, "Expected repo file to open: %s" % absolute_path)
	return file.get_as_text()

func test_readme_states_runtime_and_testbed_boundaries() -> void:
	var readme_text := _read_repo_file(README_PATH)
	assert_true(readme_text.contains("tracker-agnostic"), "README should describe the tracker-agnostic runtime boundary")
	assert_true(readme_text.contains("MediaPipe Python is allowed only in the hidden `.testbed/`"), "README should keep MediaPipe behind the hidden testbed boundary")
	assert_true(readme_text.contains("gesture vs mouse+WASD mode comparison"), "README should describe the proving scene comparison goal")
	assert_true(readme_text.contains("YAML"), "README should explain the YAML profile contract")

func test_plugin_cfg_matches_camera_gesture_control_identity() -> void:
	var config := ConfigFile.new()
	var error := config.load(ProjectSettings.globalize_path("res://%s" % PLUGIN_CFG_PATH))
	assert_eq(error, OK, "plugin.cfg should parse cleanly")
	assert_eq(config.get_value("plugin", "name", ""), "AeroBeat Camera Gesture Control")
	assert_true(String(config.get_value("plugin", "description", "")).contains("contract-driven camera controller"))
	assert_eq(config.get_value("plugin", "version", ""), "0.2.0")

func test_addons_manifest_includes_testbed_only_mediapipe_path() -> void:
	var manifest_text := _read_repo_file(ADDONS_MANIFEST_PATH)
	assert_true(manifest_text.contains('"aerobeat-input-core"'), "addons manifest should mount input-core for the hidden proving path")
	assert_true(manifest_text.contains('"aerobeat-input-mediapipe-python"'), "addons manifest should mount mediapipe python only for the hidden proving path")
	assert_true(manifest_text.contains('"gut"'), "addons manifest should keep GUT for repo-local validation")

func test_default_yaml_profile_exists() -> void:
	var default_profile_path := ProjectSettings.globalize_path("res://%s" % DEFAULT_PROFILE_PATH)
	assert_true(FileAccess.file_exists(default_profile_path), "Checked-in default YAML profile should exist")
	var profile_text := _read_repo_file(DEFAULT_PROFILE_PATH)
	assert_true(profile_text.contains("schema:"), "Default profile should declare schema metadata")
	assert_true(profile_text.contains("profile_id: default_v1"), "Default profile should expose the default profile id")
