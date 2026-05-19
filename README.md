# aerobeat-tool-camera-gesture-control

Reusable AeroBeat camera-control tool lane for turning tracked head/camera input into tunable camera motion.

## Scope

This repo owns the first-pass reusable camera controller contract for the AeroBeat tool lane.

- Runtime controller lives in `src/`
- Durable authored tuning profiles live in `assets/profiles/camera_gesture/`
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

## Profile contract

Profiles are now authored primarily as YAML documents under:

- `assets/profiles/camera_gesture/default_v1.camera_gesture.yaml`

The v1 document owns developer-editable tuning only:

- schema identity/version
- profile identity/display metadata
- control mode default
- tracking gates and sample-source choice
- rotation/translation sensitivities and bounds
- smoothing, deadzone, and recenter behavior
- lightweight debug trace intent

The YAML profile does **not** own the active `Camera3D`. Scene-specific camera targeting still comes from the runtime host via `attach_camera(camera)`.

See `docs/camera_gesture_profile_contract.md` for the durable v1 contract.

### Compatibility note

- YAML is the durable checked-in authored format.
- Legacy flat JSON profile dictionaries are still loadable for compatibility.
- `save_profile(path)` writes YAML for `.yaml` / `.yml` targets and flat JSON for `.json` targets.

## Debug state

`get_debug_state()` exposes both the resolved runtime profile and the active profile identity metadata, including:

- `active_profile.profile_id`
- `active_profile.source_path`
- `active_profile.source_format`
- `active_profile.source_hash`
- `active_profile.schema_id`
- `active_profile.schema_version`

This keeps config identity traceable without moving camera ownership into the profile.

## Hidden proving testbed

The `.testbed/` workbench provides:

- gesture vs mouse+WASD mode comparison
- left-panel tuning controls for the runtime profile
- YAML-first save/load round-trips for profile experimentation
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
