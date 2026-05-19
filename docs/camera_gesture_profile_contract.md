# Camera Gesture Profile Contract v1

This repo now treats YAML as the durable authored profile format for camera-gesture tuning.

## Location

Checked-in profiles live under:

- `assets/profiles/camera_gesture/`

The first working profile is:

- `assets/profiles/camera_gesture/default_v1.camera_gesture.yaml`

## Scope boundary

The YAML profile owns developer-editable tuning values only.

It **does** own:
- control mode defaults
- tracking gates and sample-source choice
- rotation/translation sensitivities and bounds
- smoothing, deadzone, and recenter behavior
- lightweight debug/trace intent such as `debug.trace_level`

It **does not** own:
- the active `Camera3D`
- scene paths or camera-node ownership
- MediaPipe/session ownership
- fixture replay/harness runtime state

The runtime host must still provide the active `Camera3D` explicitly via `attach_camera(camera)`.

## v1 schema

```yaml
schema:
  id: camera_gesture_profile
  version: 1

profile_id: default_v1
display_name: Default v1
description: Baseline parallax tuning for the first camera-gesture runtime slice.
mode: gesture

tracking:
  sample_source: head_position
  confidence_threshold: 0.45
  freeze_on_tracking_loss: true

response:
  invert_x: false
  invert_y: false
  smoothing: 0.2
  deadzone: 0.03
  recenter_speed: 1.8

rotation:
  look_sensitivity_x: 1.0
  look_sensitivity_y: 1.0
  max_yaw_degrees: 20.0
  max_pitch_degrees: 12.0
  max_roll_degrees: 4.0

translation:
  sensitivity_x: 1.0
  sensitivity_y: 0.6
  sensitivity_z: 0.4
  max_meters: [0.6, 0.35, 0.45]

debug:
  trace_level: basic
```

## Runtime behavior

`CameraGestureController` resolves the YAML document into the runtime profile it already uses internally.

Expected behavior:
- YAML is the primary checked-in authored format.
- Legacy flat JSON profile dictionaries remain loadable for compatibility.
- `apply_profile(profile)` may still accept inline dictionaries, but the durable on-disk contract is the YAML document above.
- `save_profile(path)` writes YAML for `.yaml` / `.yml` targets and JSON for `.json` targets.

## Debug-state contract

`get_debug_state()` must expose active profile metadata separately from live camera attachment/runtime state.

At minimum the debug surface should include:
- `active_profile.profile_id`
- `active_profile.display_name`
- `active_profile.source_path`
- `active_profile.source_format`
- `active_profile.source_hash`
- `active_profile.schema_id`
- `active_profile.schema_version`

This keeps config identity traceable without moving scene-specific runtime ownership into the profile.

## Harness note

The hidden `.testbed/` should treat repo-root YAML profiles as the source-of-truth tuning assets, while still allowing user-space save/load round-trips for experimentation.
