# aerobeat-tool-camera-gesture-control

Reusable AeroBeat camera-control tool lane for turning tracked head/camera input into tunable camera motion.

## Scope

This repo owns the first-pass reusable camera controller contract for the AeroBeat tool lane.

- Runtime controller lives in `src/`
- Hidden proving workbench lives in `.testbed/`
- Runtime stays tracker-agnostic and input-core-facing
- MediaPipe Python is allowed only in the hidden `.testbed/` dependency path via GodotEnv

## Locked runtime surface

`src/camera_gesture_controller.gd` exposes the frozen first-lane API:

- `set_enabled(enabled)`
- `set_control_mode(mode)`
- `attach_camera(camera)` / `detach_camera()`
- `attach_input_source(input_source)` / `detach_input_source()`
- `apply_profile(profile)` / `get_profile()`
- `load_profile(path)` / `save_profile(path)`
- `get_debug_state()`

Signals:

- `control_mode_changed(mode)`
- `tracking_state_changed(state)`
- `profile_loaded(profile)`
- `profile_saved(path)`

Control modes:

- `gesture`
- `mouse_wasd`
- `disabled`

## Profile schema

Profiles are JSON dictionaries with a versioned first-lane schema that includes:

- `version`
- `mode`
- `invert_x`, `invert_y`
- `look_sensitivity_x`, `look_sensitivity_y`
- `translation_sensitivity_x`, `translation_sensitivity_y`, `translation_sensitivity_z`
- `max_yaw_degrees`, `max_pitch_degrees`, `max_roll_degrees`
- `max_translation_meters`
- `smoothing`
- `deadzone`
- `recenter_speed`
- `tracking_confidence_threshold`
- `freeze_on_tracking_loss`
- `sample_source`

## Hidden proving testbed

The `.testbed/` workbench provides:

- gesture vs mouse+WASD mode comparison
- left-panel tuning controls for the runtime profile
- JSON save/load round-trip buttons
- MediaPipe-Python-via-GodotEnv integration when that addon mount is available
- fake-input fallback when MediaPipe is not mounted or not running

## Dev/test flow

Restore hidden testbed dependencies:

```bash
cd .testbed
godotenv addons install
```

Open the proving workbench:

```bash
godot --editor --path .testbed
```

Headless import smoke check:

```bash
godot --headless --path .testbed --import
```

Run repo-local tests:

```bash
godot --headless --path .testbed --script addons/gut/gut_cmdln.gd \
  -gdir=res://tests \
  -ginclude_subdirs \
  -gexit
```
