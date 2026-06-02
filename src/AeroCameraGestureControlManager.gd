class_name AeroCameraGestureControlManager
extends Node

signal initialized

const VERSION: String = "0.4.0"
const CONTROLLER_SCRIPT := preload("camera_gesture_controller.gd")
const CAMERA_TRACKING_SCRIPT_PATH := "res://addons/aerobeat-tool-camera-tracking/src/CameraTracking.gd"
const DEFAULT_CAMERA_GESTURE_PROFILE_PATH := "res://assets/profiles/camera_gesture/default_v1.camera_gesture.yaml"
const DEFAULT_CAMERA_TRACKING_BACKEND := "camera_tracking_default"
const SOURCE_KIND_LIVE_CAMERA := "live_camera"
const SOURCE_KIND_VIDEO_FILE := "video_file"

@export var is_active: bool = true

var _is_initialized: bool = false

func _ready() -> void:
	_initialize()

func _initialize() -> void:
	if _is_initialized:
		return
	_is_initialized = true
	initialized.emit()
	print("AeroCameraGestureControlManager initialized.")

func create_camera_gesture_controller():
	return CONTROLLER_SCRIPT.new()

func create_camera_tracking() -> Node:
	var camera_tracking_script: Variant = load(CAMERA_TRACKING_SCRIPT_PATH)
	if camera_tracking_script == null:
		push_error("AeroCameraGestureControlManager: CameraTracking contract addon is not mounted")
		return null
	return camera_tracking_script.new()

func build_live_camera_tracking_config(camera_id: String = "", overrides: Dictionary = {}) -> Dictionary:
	var config := {
		"backend": DEFAULT_CAMERA_TRACKING_BACKEND,
		"source": {
			"kind": SOURCE_KIND_LIVE_CAMERA,
			"camera_id": camera_id,
		},
		"preview": {
			"enabled": true,
			"surface_mode": "attach",
			"flip_horizontal": true,
		},
	}
	_deep_merge(config, overrides)
	return config

func build_replay_camera_tracking_config(replay_path: String, overrides: Dictionary = {}) -> Dictionary:
	var config := build_live_camera_tracking_config("", overrides)
	config["source"] = {
		"kind": SOURCE_KIND_VIDEO_FILE,
		"path": replay_path,
	}
	return config

func get_default_camera_gesture_profile_path() -> String:
	return DEFAULT_CAMERA_GESTURE_PROFILE_PATH

func _deep_merge(base: Dictionary, incoming: Dictionary) -> void:
	for key_variant: Variant in incoming.keys():
		var key := key_variant
		var incoming_value: Variant = incoming[key]
		if base.has(key) and base[key] is Dictionary and incoming_value is Dictionary:
			_deep_merge(base[key], incoming_value)
		else:
			base[key] = incoming_value
