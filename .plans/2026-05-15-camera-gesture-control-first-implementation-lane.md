# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-15  
**Status:** Draft  
**Agent:** Cookie 🍪

---

## Goal

Implement the first reusable camera-control Lego piece: a contract-driven runtime camera gesture controller in `/src/`, plus a hidden `.testbed/` scene that compares gesture control against mouse+WASD and exposes JSON-backed tuning values via a left-panel UI.

---

## Overview

This repo should become the reusable interpreter that turns tracked/head-gesture input into controlled camera motion. It should not duplicate MediaPipe implementation work and should not become a desktop-only proof repo. The real runtime value belongs in `/src/`, while the `.testbed/` exists to prove the feel, range limits, smoothing, and configuration story in a desktop environment.

The runtime side should consume an input-core-facing contract rather than embedding MediaPipe-specific assumptions into the tool itself. The hidden testbed should then use `aerobeat-input-mediapipe-python` via GodotEnv to fulfill that contract for local validation. This keeps the tool reusable if another tracking backend exists later.

This lane should also lock a clean tuning/profile story. Multiple key/value pairs should be represented in a JSON-backed profile that can be saved and loaded from the test scene, while the left panel exposes the most important ranges/toggles/sliders so Derrick can compare gesture-driven camera movement against normal mouse + WASD control.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Repo owning this implementation lane | `/home/derrick/Documents/projects/aerobeat/aerobeat-tool-camera-gesture-control` |
| `REF-02` | Parallel coordination umbrella plan | `/home/derrick/Documents/projects/aerobeat/aerobeat-assembly-community/.plans/2026-05-15-parallel-lego-piece-implementation-coordination.md` |
| `REF-03` | Higher-level fallback/design roadmap | `/home/derrick/Documents/projects/aerobeat/aerobeat-assembly-community/.plans/2026-05-15-default-environment-fallback-ladder.md` |
| `REF-04` | MediaPipe Python repo used via GodotEnv in the testbed | `/home/derrick/Documents/projects/aerobeat/aerobeat-input-mediapipe-python` |
| `REF-05` | Input-core contract boundary that runtime logic should consume | `/home/derrick/Documents/projects/aerobeat/aerobeat-input-core` |
| `REF-06` | Environment sample/testbed ecosystem that can inform camera proving scenes later | `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-community` |

---

## Tasks

### Task 1: Inspect repo/template structure and lock the first-lane camera-control contracts

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`  
**Prompt:** In repo `/home/derrick/Documents/projects/aerobeat/aerobeat-tool-camera-gesture-control`, claim the assigned bead and inspect the current repo/template structure. Confirm the runtime/testbed layout, then lock the first-lane contracts: runtime controller API, control modes, JSON tuning/profile schema, input-core-facing adapter boundary, and the testbed UI field list for sliders/toggles.

**Folders Created/Deleted/Modified:**
- Planning/docs only expected

**Files Created/Deleted/Modified:**
- Contract notes only

**Status:** ⏳ Pending

**Results:** Pending execution.

---

### Task 2: Implement the runtime camera gesture controller in `/src/`

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-05`  
**Prompt:** In repo `/home/derrick/Documents/projects/aerobeat/aerobeat-tool-camera-gesture-control`, claim the assigned bead and implement the reusable runtime controller in `/src/`. Keep it contract-driven rather than MediaPipe-specific. Support enabling/disabling, mode switching between `gesture`, `mouse_wasd`, and `disabled`, camera attachment, input-source attachment, clamp/smoothing behavior, and JSON profile application.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-tool-camera-gesture-control/src/`

**Files Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-tool-camera-gesture-control/src/*`

**Status:** ⏳ Pending

**Results:** Pending execution.

---

### Task 3: Build the hidden `.testbed/` comparison scene using MediaPipe Python via GodotEnv

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-04`, `REF-05`  
**Prompt:** In repo `/home/derrick/Documents/projects/aerobeat/aerobeat-tool-camera-gesture-control`, claim the assigned bead and build the hidden `.testbed/` proving scene. Wire the testbed to `aerobeat-input-mediapipe-python` via GodotEnv, provide left-panel controls for `gesture` vs `mouse_wasd` vs `disabled`, expose the locked tuning fields as sliders/toggles, and add save/load JSON profile controls.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`
- `.testbed/assets/`
- `.testbed/scenes/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- `.testbed/scenes/*`
- `.testbed/scripts/*`
- `.testbed/assets/*` only as needed for proving the camera motion visually

**Status:** ⏳ Pending

**Results:** Pending execution.

---

### Task 4: Add repo-local validation and audit the lane

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `qa` / `auditor` workflow roles)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`  
**Prompt:** In repo `/home/derrick/Documents/projects/aerobeat/aerobeat-tool-camera-gesture-control`, claim the assigned bead and add/run the most relevant repo-local validation for this lane. Verify the controller API, mode switching, JSON profile round-trip, clamp/smoothing behavior, and MediaPipe-backed testbed comparison scene. Then audit whether the lane stayed contract-driven rather than collapsing into tracker-specific code.

**Folders Created/Deleted/Modified:**
- `.testbed/tests/` if needed

**Files Created/Deleted/Modified:**
- `.testbed/tests/*` if needed
- `.plans/2026-05-15-camera-gesture-control-first-implementation-lane.md`

**Status:** ⏳ Pending

**Results:** Pending execution.

---

## Suggested First-Lane Contract

This contract is now frozen to match the umbrella coordination plan so the repo can implement without drifting from the other lanes.

### Runtime surface

```gdscript
signal control_mode_changed(mode: String)
signal tracking_state_changed(state: Dictionary)
signal profile_loaded(profile: Dictionary)
signal profile_saved(path: String)

func set_enabled(enabled: bool) -> void
func set_control_mode(mode: String) -> void
func attach_camera(camera: Camera3D) -> void
func detach_camera() -> void
func attach_input_source(input_source: Node) -> bool
func detach_input_source() -> void
func apply_profile(profile: Dictionary) -> void
func get_profile() -> Dictionary
func load_profile(path: String) -> Dictionary
func save_profile(path: String) -> Dictionary
func get_debug_state() -> Dictionary
```

### Control modes

- `gesture`
- `mouse_wasd`
- `disabled`

### Locked tuning/profile schema

```json
{
  "version": 1,
  "mode": "gesture | mouse_wasd | disabled",
  "invert_x": false,
  "invert_y": false,
  "look_sensitivity_x": 1.0,
  "look_sensitivity_y": 1.0,
  "translation_sensitivity_x": 1.0,
  "translation_sensitivity_y": 0.6,
  "translation_sensitivity_z": 0.4,
  "max_yaw_degrees": 20.0,
  "max_pitch_degrees": 12.0,
  "max_roll_degrees": 4.0,
  "max_translation_meters": [0.6, 0.35, 0.45],
  "smoothing": 0.2,
  "deadzone": 0.03,
  "recenter_speed": 1.8,
  "tracking_confidence_threshold": 0.45,
  "freeze_on_tracking_loss": true,
  "sample_source": "head_position"
}
```

### Contract notes for implementation

- Runtime code consumes an input-core-facing source/adapter boundary rather than MediaPipe-specific subprocess or transport details.
- The `.testbed/` may use `aerobeat-input-mediapipe-python` via GodotEnv to satisfy that boundary locally.
- The left-panel testbed UI should expose the JSON-backed tunables directly enough to verify save/load parity and gesture-vs-mouse/WASD feel.

### Testbed truth for this lane

The proving scene should make it easy to answer:
- is gesture control currently active?
- how does it feel versus mouse+WASD?
- what clamp/smoothing values are currently applied?
- can those values be saved/loaded via JSON cleanly?
- does tracking loss behave predictably?

---

## Non-Goals For This Lane

- no direct app integration yet
- no hard-coded MediaPipe-specific runtime logic in the reusable core
- no environment loading logic here
- no performance classifier logic here
- no polished production UX beyond the proving testbed

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Implementation plan for the `aerobeat-tool-camera-gesture-control` lane, now updated to the frozen shared runtime API, control modes, and JSON tuning schema.

**Reference Check:** Scoped against `REF-01` through `REF-06` and aligned to the umbrella contract lock for control modes, JSON-backed tunables, and the input-core adapter boundary.

**Commits:**
- Pending commit

**Lessons Learned:** The camera-control repo should stay focused on translating tracked input into tunable camera behavior, with the frozen API and JSON schema keeping the reusable runtime core from collapsing into tracker-specific code.

---

*Completed on 2026-05-15*
