extends SceneTree

const SCENE_PATH := "res://scenes/camera_gesture_testbed.tscn"
const MODE_LIVE := "mediapipe_live"
const MODE_REPLAY := "mediapipe_replay"
const READY_TIMEOUT_MS := 12000

var _instance: Node = null
var _exit_code := 1

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var requested_mode := MODE_LIVE
	if not args.is_empty():
		requested_mode = str(args[0]).strip_edges()
	print("PROBE_MODE=%s" % requested_mode)
	var packed: PackedScene = load(SCENE_PATH)
	print("PROBE_SCENE_LOAD_OK=%s" % str(packed != null))
	if packed == null:
		quit(2)
		return

	_instance = packed.instantiate()
	print("PROBE_SCENE_INSTANCE_OK=%s" % str(_instance != null))
	if _instance == null:
		quit(3)
		return

	root.add_child(_instance)
	current_scene = _instance
	await process_frame
	await process_frame

	if requested_mode == MODE_LIVE:
		_instance.set("_selected_mediapipe_live_camera_id", "0")
	_instance.set("_source_mode", requested_mode)
	var fixture_runtime_config: Dictionary = _instance.call("_refresh_fixture_runtime_config", true)
	print("PROBE_FIXTURE_RUNTIME_READY=%s" % str(bool(fixture_runtime_config.get("runtime_ready", false))))
	print("PROBE_FIXTURE_VIDEO=%s" % str((fixture_runtime_config.get("effective_video", {}) as Dictionary).get("display_path", "")))
	_instance.call("_switch_input_source", requested_mode)

	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	var final_status := ""
	while Time.get_ticks_msec() < deadline:
		await process_frame
		final_status = str(_instance.get("_mediapipe_runtime_status"))
		if final_status == "ready" or final_status == "failed":
			break

	var debug_state: Dictionary = _instance.call("_build_mediapipe_session_debug_state")
	print("PROBE_RUNTIME_STATUS=%s" % final_status)
	print("PROBE_RUNTIME_LAST_ERROR=%s" % str(debug_state.get("runtime_last_error", "")))
	print("PROBE_SESSION_ROLE=%s" % str(debug_state.get("session_role", "")))
	print("PROBE_PROVIDER_LIVE=%s" % str(bool(debug_state.get("provider_live", false))))
	print("PROBE_RUNTIME_MODE=%s" % str(debug_state.get("runtime_mode", "")))
	print("PROBE_CAMERA_SOURCE=%s" % str(debug_state.get("camera_source", "")))
	print("PROBE_TRACKING_QUALITY=%s" % str(debug_state.get("tracking_quality", "")))
	print("PROBE_TRACKING_OVERLAY_MODE=%s" % str(debug_state.get("tracking_overlay_mode", "")))
	print("PROBE_RUNTIME_READY=%s" % str(final_status == "ready"))

	if _instance != null and is_instance_valid(_instance):
		if _instance.has_method("_teardown_mediapipe_runtime"):
			_instance.call("_teardown_mediapipe_runtime")
		_instance.queue_free()
		await process_frame
		await process_frame
	_instance = null

	_exit_code = 0 if final_status == "ready" else 1
	quit(_exit_code)
