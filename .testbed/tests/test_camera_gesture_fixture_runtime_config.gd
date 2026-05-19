extends GutTest

const FIXTURE_RUNTIME_CONFIG_SCRIPT := preload("res://scripts/camera_gesture_fixture_runtime_config.gd")

func test_sidecar_summary_and_effective_video_resolve_from_checked_in_candidate_pair() -> void:
	var helper = FIXTURE_RUNTIME_CONFIG_SCRIPT.new()
	var config: Dictionary = helper.resolve(
		"res://assets/fixtures/camera_gesture/head_pose/candidates/head_rotate_left_repeat_04_take_01.mp4",
		"res://assets/fixtures/camera_gesture/head_pose/candidates/head_rotate_left_repeat_04_take_01.fixture.yaml"
	)
	assert_true(bool(config.get("runtime_ready", false)), "Checked-in candidate pair should resolve to a replay-ready runtime source")
	assert_eq(str(config.get("fixture_key", "")), "camera_gesture/head_pose/head_rotate_left_repeat_04_take_01")
	assert_eq(str(config.get("sample_source_hint", "")), "head_rotation")
	var sidecar_summary: Dictionary = config.get("sidecar_summary", {})
	assert_eq(str(sidecar_summary.get("primary_channel", "")), "rotation")
	assert_eq(str(sidecar_summary.get("primary_axis", "")), "yaw")
	assert_true(int(sidecar_summary.get("expected_window_count", 0)) > 0, "Expected windows should be counted from the sidecar")

func test_sidecar_video_can_drive_runtime_when_explicit_video_field_is_missing() -> void:
	var helper = FIXTURE_RUNTIME_CONFIG_SCRIPT.new()
	var config: Dictionary = helper.resolve(
		"res://assets/fixtures/camera_gesture/head_pose/candidates/does_not_exist.mp4",
		"res://assets/fixtures/camera_gesture/head_pose/candidates/head_move_left_repeat_04_take_01.fixture.yaml"
	)
	var effective_video: Dictionary = config.get("effective_video", {})
	assert_true(bool(config.get("runtime_ready", false)), "Sidecar-relative video path should make replay runtime-ready even without a valid explicit video field")
	assert_true(str(effective_video.get("display_path", "")).contains("head_move_left_repeat_04_take_01.mp4"))
	assert_eq(str(config.get("effective_video_origin", "")), "sidecar")
