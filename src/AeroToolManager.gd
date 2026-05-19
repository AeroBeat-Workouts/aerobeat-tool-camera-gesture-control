class_name AeroToolManager
extends Node

signal initialized

const VERSION: String = "0.2.0"
const CONTROLLER_SCRIPT := preload("res://src/camera_gesture_controller.gd")
const DEFAULT_CAMERA_GESTURE_PROFILE_PATH := "res://assets/profiles/camera_gesture/default_v1.camera_gesture.yaml"

@export var is_active: bool = true

var _is_initialized: bool = false

func _ready() -> void:
	_initialize()

func _initialize() -> void:
	if _is_initialized:
		return
	_is_initialized = true
	initialized.emit()
	print("AeroToolManager initialized.")

func create_camera_gesture_controller() -> CameraGestureController:
	return CONTROLLER_SCRIPT.new()

func get_default_camera_gesture_profile_path() -> String:
	return DEFAULT_CAMERA_GESTURE_PROFILE_PATH
