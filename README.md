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

- a 16:9 harness shape with left config/debug controls and a right 3D world preview
- a bottom-left MediaPipe/video + tracking inset with an honest overlay-only fallback when the mounted camera-view seam is not live
- gesture vs mouse+WASD mode comparison
- YAML-first profile load / reload / export actions for profile experimentation
- trace-capture scaffolding that exports run manifests, JSONL frame traces, Markdown summaries, and a resolved YAML profile snapshot
- fixture-key / prerecorded-video / sidecar-path fields so the later replay-oracle slice can reuse the same surface
- MediaPipe-Python-via-GodotEnv integration when that addon mount is available
- shared in-process MediaPipe session reuse via `AeroProviderSessionRegistry` before any local provider startup
- fake-input fallback when MediaPipe is not mounted or not running

Current honest limitation: cross-lane duplicate-prevention only works when the owner lane also publishes its active MediaPipe session through the input-core registry. This repo now consumes and publishes that seam, but the mounted MediaPipe proving harness path does not auto-publish yet.

## Dev/test flow

Refresh the hidden testbed workbench and prepare the mounted MediaPipe runtime for local `linux-x64` dev use:

```bash
python3 scripts/refresh_testbed_workbench.py
```

That repo-owned workflow does four things in order:

1. runs `godotenv addons install` in `.testbed/`
2. discards generated `.testbed/addons/*` and `.testbed/.addons/*` mirrors for declared addons, then prunes stale generated addon entries and clears relevant Godot caches
3. re-imports the `.testbed` project headlessly
4. runs the mounted addon's documented runtime prep command from `/.testbed/addons/aerobeat-input-mediapipe-python/`:
   `python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --install-requirements --validate`

Required runtime artifacts are then verified under:

- `.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/runtime-manifest.json`
- `.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/.runtime-ready`
- `.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/venv/bin/python`

If you only need the old addon-restore/import portion without rerunning runtime prep, use:

```bash
python3 scripts/refresh_testbed_workbench.py --skip-runtime-prep
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
