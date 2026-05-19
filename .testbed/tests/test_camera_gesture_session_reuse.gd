extends GutTest

const REGISTRY_SCRIPT := preload("res://addons/aerobeat-input-core/src/runtime/provider_session_registry.gd")
const TESTBED_SCENE := preload("res://scenes/camera_gesture_testbed.tscn")

class FakeBackend:
	extends Node
	signal pose_updated(landmarks: Array)

	func get_detector_state() -> Dictionary:
		return {
			"tracking_state": "tracking",
			"metrics": {
				"confidences": {
					"head": 0.91,
					"torso": 0.83,
				},
			},
			"events": ["pose_ready"],
		}

class FakeSharedProvider:
	extends AeroInputProvider

	var tracking := true
	var head_position := Vector3(0.62, 0.48, 0.05)
	var stop_count := 0
	var _provider := FakeBackend.new()

	func _init() -> void:
		_provider.name = "FakeProviderBackend"
		add_child(_provider)

	func start(_settings_json: String = "") -> bool:
		tracking = true
		started.emit()
		return true

	func stop() -> void:
		stop_count += 1
		tracking = false
		stopped.emit()

	func is_tracking() -> bool:
		return tracking

	func get_provider_id() -> String:
		return "mediapipe_python"

	func has_capability(capability: Capability) -> bool:
		return capability == Capability.GESTURE_RECOGNITION or capability == Capability.VELOCITY

	func trigger_haptic(_side: int, _intensity: float, _duration_ms: int) -> void:
		pass

	func get_head_position(_mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
		return head_position

	func get_left_hand_position(_mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
		return Vector3.ZERO

	func get_right_hand_position(_mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
		return Vector3.ZERO

	func get_left_foot_position(_mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
		return Vector3.ZERO

	func get_right_foot_position(_mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
		return Vector3.ZERO

	func get_head_velocity() -> Vector3:
		return Vector3(0.03, 0.01, 0.0)

	func get_left_hand_velocity() -> Vector3:
		return Vector3.ZERO

	func get_right_hand_velocity() -> Vector3:
		return Vector3.ZERO

	func get_left_foot_velocity() -> Vector3:
		return Vector3.ZERO

	func get_right_foot_velocity() -> Vector3:
		return Vector3.ZERO

	func get_head_rotation() -> Quaternion:
		return Quaternion.IDENTITY

	func get_left_hand_rotation() -> Quaternion:
		return Quaternion.IDENTITY

	func get_right_hand_rotation() -> Quaternion:
		return Quaternion.IDENTITY

	func get_left_foot_rotation() -> Quaternion:
		return Quaternion.IDENTITY

	func get_right_foot_rotation() -> Quaternion:
		return Quaternion.IDENTITY

	func get_tracking_confidence(_body_part: StringName) -> float:
		return 0.91 if tracking else 0.0

func before_each() -> void:
	REGISTRY_SCRIPT.clear_registry_for_testing()

func after_each() -> void:
	REGISTRY_SCRIPT.clear_registry_for_testing()

func _instantiate_testbed() -> Control:
	var instance := TESTBED_SCENE.instantiate()
	add_child_autofree(instance)
	var camera_view = instance.get("_mediapipe_camera_view")
	if camera_view != null:
		camera_view.queue_free()
		instance.set("_mediapipe_camera_view", null)
	return instance

func test_switch_to_mediapipe_reuses_published_shared_session() -> void:
	var shared_provider := FakeSharedProvider.new()
	add_child_autofree(shared_provider)
	var publish := REGISTRY_SCRIPT.publish_session(
		"qa_owner_lane",
		shared_provider,
		{
			"session_key": "mediapipe_python/shared_qa",
			"metadata": {
				"lane": "qa_owner_lane",
				"stream_url": "http://127.0.0.1:4243/camera",
			},
		}
	)
	assert_true(bool(publish.get("ok", false)), "Test setup should publish a shared mediapipe session")

	var instance := _instantiate_testbed()
	instance.call("_switch_input_source", "mediapipe_python")

	assert_eq(instance.get("_source_mode"), "mediapipe_python")
	assert_same(instance.get("_mediapipe_input_source"), shared_provider, "Testbed should reuse the already-published provider instance")
	assert_true(bool(instance.get("_mediapipe_input_source_is_borrowed")), "Shared provider should be marked as borrowed")
	assert_eq(String(instance.get("_mediapipe_borrowed_session_key")), "mediapipe_python/shared_qa")
	assert_eq(String(instance.get("_mediapipe_owned_session_key")), "")
	var provider_snapshot: Dictionary = instance.call("_collect_provider_snapshot")
	assert_eq(String(provider_snapshot.get("session_role", "")), "borrowed")
	assert_eq(String(provider_snapshot.get("owner_id", "")), "qa_owner_lane")
	var acquired := REGISTRY_SCRIPT.request_session({"session_key": "mediapipe_python/shared_qa"})
	assert_true(bool(acquired.get("ok", false)))
	assert_eq(int(acquired.get("session", {}).get("borrower_count", -1)), 1)

	instance.call("_switch_input_source", "fake")
	var released := REGISTRY_SCRIPT.request_session({"session_key": "mediapipe_python/shared_qa"})
	assert_true(bool(released.get("ok", false)))
	assert_eq(int(released.get("session", {}).get("borrower_count", -1)), 0, "Switching away should release the borrowed session")
	assert_false(bool(instance.get("_mediapipe_input_source_is_borrowed")))
	assert_eq(instance.get("_current_input_source"), instance.get("_fake_input_source"))

func test_locally_owned_provider_publishes_and_unpublishes_cleanly_on_teardown() -> void:
	var owned_provider := FakeSharedProvider.new()
	add_child_autofree(owned_provider)
	var instance := _instantiate_testbed()
	instance.set("_mediapipe_input_source", owned_provider)
	instance.set("_mediapipe_input_source_is_borrowed", false)

	var publish: Dictionary = instance.call("_publish_owned_mediapipe_session")
	assert_true(bool(publish.get("ok", false)), "Owned provider should publish through the session registry")
	var request := REGISTRY_SCRIPT.request_session({"session_key": "mediapipe_python/camera_gesture_testbed"})
	assert_true(bool(request.get("ok", false)))
	assert_same(request.get("session", {}).get("provider", null), owned_provider)
	assert_eq(String(instance.get("_mediapipe_owned_session_key")), "mediapipe_python/camera_gesture_testbed")

	instance.call("_teardown_mediapipe_runtime")
	assert_false(bool(REGISTRY_SCRIPT.request_session({"session_key": "mediapipe_python/camera_gesture_testbed"}).get("ok", false)), "Owned session should unpublish on teardown")
	assert_eq(owned_provider.stop_count, 1, "Owned provider should be stopped exactly once on teardown")
	assert_eq(instance.get("_mediapipe_input_source"), null)
