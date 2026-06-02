# aerobeat-tool-camera-gesture-control

Reusable AeroBeat camera-control tool lane for turning tracked head/camera input into tunable camera motion.

## Scope

This repo owns the reusable camera-gesture controller layer for the AeroBeat tool lane.

- Repo-root sharable runtime lives in `src/`
- Durable authored tuning profiles live in `assets/profiles/camera_gesture/`
- Hidden proving workbench lives in `.testbed/`
- Repo-root `src/` consumes `aerobeat-tool-camera-tracking` for camera-tracking lifecycle and live/replay source control
- Repo-root `src/` does **not** know about `aerobeat-vendor-mediapipe-python`
- Hidden `.testbed/` is the only proving ground allowed to mount concrete backend deps through GodotEnv

## Locked runtime surface

`src/camera_gesture_controller.gd` exposes the frozen first-lane API:

- `set_enabled(enabled)`
- `set_control_mode(mode)`
- `attach_camera(camera)` / `detach_camera()`
- `attach_input_source(input_source)` / `detach_input_source()`
- `attach_camera_tracking(camera_tracking)` / `detach_camera_tracking()`
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

## Camera-tracking boundary

The sharable runtime boundary is now explicit:

- `src/AeroCameraGestureControlManager.gd` loads `CameraTracking` from `aerobeat-tool-camera-tracking`
- `src/camera_gesture_controller.gd` can attach directly to a `CameraTracking` session through `attach_camera_tracking(camera_tracking)`
- `src/camera_tracking_input_source.gd` adapts public `CameraTracking` frames into the controller's existing input-source surface
- live camera and replay/video-file flows both pass through `CameraTracking`
- repo-root `src/` remains vendor-clean and does not preload or mount `aerobeat-vendor-mediapipe-python`

That means this package owns camera-motion behavior and profile application, while `aerobeat-tool-camera-tracking` owns tracking lifecycle, source switching, preview attachment semantics, and backend resolution.

## Profile contract

Profiles are authored primarily as YAML documents under:

- `assets/profiles/camera_gesture/default_v1.camera_gesture.yaml`

The v1 document owns developer-editable tuning only:

- schema identity/version
- profile identity/display metadata
- control mode default
- tracking gates and sample-source choice
- rotation/translation sensitivities and bounds
- smoothing, deadzone, and recenter behavior
- lightweight debug trace intent

The YAML profile does **not** own the active `Camera3D`, scene wiring, or vendor/runtime selection. Scene-specific camera targeting still comes from the runtime host via `attach_camera(camera)`.

See `.testbed/docs/camera_gesture_profile_contract.md` for the durable v1 contract.

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
- `camera_tracking_attached`
- `camera_tracking_session_path`

This keeps config identity traceable without moving camera ownership or tracking-service ownership into the profile.

## Hidden proving testbed

The hidden `.testbed/` workbench is the proving ground for the full boundary:

- a 16:9 harness shape with left config/debug controls and a right 3D world preview
- a bottom-right media/tracking inset with honest overlay fallback when no live tracking preview is attached
- gesture vs mouse+WASD mode comparison
- YAML-first profile load / reload / export actions for profile experimentation
- trace-capture scaffolding that exports run manifests, JSONL frame traces, Markdown summaries, and a resolved YAML profile snapshot
- live-camera proving through `CameraTracking` + `aerobeat-vendor-mediapipe-python`
- replay proving through `CameraTracking`, with replay preview delegated through `aerobeat-tool-video-player` + `aerobeat-vendor-godot-video`
- fake-input fallback when the proving stack is unavailable

Concrete backend packages belong here, not in repo-root `src/`.

## GodotEnv development flow

This repo follows the AeroBeat GodotEnv package convention.

- Canonical dev/test manifest: `.testbed/addons.jsonc`
- Installed dev/test addons: `.testbed/addons/`
- GodotEnv cache: `.testbed/.addons/`
- Hidden workbench project: `.testbed/project.godot`
- Repo-local unit tests: `.testbed/tests/`
- Repo-root sharable source: `src/`

The repo root remains the package/published boundary for downstream consumers. `.testbed/` is only the proving surface. Do real sharable work at the repo root, not inside `.testbed/addons/` or `.testbed/.addons/` mirrors.

### Restore dev/test dependencies

From the repo root:

```bash
/home/derrick/.openclaw/workspace/scripts/godotenv-sync
cd .testbed
godotenv addons install
cd ..
python3 .testbed/addons/aerobeat-vendor-mediapipe-python/scripts/prepare_vendor_runtime.py --json
```

Use the sync helper first if the local toolchain or linked workspace packages need refreshing. The final prep command is vendor-owned runtime setup for the hidden proving layer only; repo-root `src/` still remains vendor-clean.

### Import smoke check

From the repo root:

```bash
godot --headless --path .testbed --import
```

### Run repo-local tests

From the repo root:

```bash
godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd \
  -gdir=res://tests \
  -ginclude_subdirs \
  -gexit
```
