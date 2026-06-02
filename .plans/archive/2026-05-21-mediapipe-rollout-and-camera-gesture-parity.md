# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-21  
**Status:** Stale  
**Agent:** Cookie 🍪

---

## Goal

Roll the latest `aerobeat-input-mediapipe-python` camera-switch fix out to `pico`, `chip`, and `byte`, then bring `aerobeat-tool-camera-gesture-control` to bug-fix and feature parity for live-webcam camera selection and tracking-quality controls.

---

## Overview

Cookie-side manual verification confirms the live camera-switch crash is fixed in `aerobeat-input-mediapipe-python` with commit `ca0b7af` (`Serialize Godot camera switch lifecycle`). The first part of this plan is an environment rollout pass: SSH into `pico`, `chip`, and `byte`, update the relevant local repo state, and refresh the GodotEnv-mounted testbed dependencies/runtime state so the fixed owner repo is what those terminals will actually run.

The second part is the next product lane Derrick described for `aerobeat-tool-camera-gesture-control`. That repo already consumes `aerobeat-input-mediapipe-python` through its hidden `.testbed` and reuses an existing provider session when available, but it is missing the newest MediaPipe bug fixes/features on its own testbed surface. The required end state is feature parity with the MediaPipe Python proving flow for the live-webcam path: when live webcam is selected, the left-hand settings panel should expose camera selection and tracking quality options (`none`, `optimized`, `full`), while prerecorded-video flow keeps its existing replay behavior.

This likely spans at least two ownership surfaces: the real `aerobeat-input-mediapipe-python` repo if any shared provider/runtime contract or donor-harness behavior still needs to move forward there, and the consumer-facing `aerobeat-tool-camera-gesture-control` repo for the left-panel GUI wiring and testbed behavior. Durable fixes must land in the real owning repo first whenever parity depends on MediaPipe source behavior, then the consumer testbed should be refreshed through the normal GodotEnv workflow.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Freshly landed camera-switch lifecycle fix | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` |
| `REF-02` | Camera-switch repair/investigation plans | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/mediapipe-python/2026-05-21-camera-switch-regression-trace.md`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/mediapipe-python/2026-05-21-camera-switch-single-owner-repair.md` |
| `REF-03` | Camera-gesture repo hidden testbed owner | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/` |
| `REF-04` | Camera-gesture testbed script surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scripts/camera_gesture_testbed.gd` |
| `REF-05` | Camera-gesture testbed scene/UI surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scenes/camera_gesture_testbed.tscn` |
| `REF-06` | Existing prior plan noting the queued Byte performance lane this request supersedes | `Source: memory/2026-05-20.md#L22-L29` |
| `REF-07` | Canonical GodotEnv restore workflow already used in this lane | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/README.md`, prior plan refs to `godotenv addons install` / `godotenv-sync` |

---

## Tasks

### Task 1: Remote rollout to pico / chip / byte

**Bead ID:** `aerobeat-tool-camera-gesture-control-q6o`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-07`  
**Prompt:** SSH into `pico`, `chip`, and `byte` and make sure each host’s local `aerobeat-input-mediapipe-python` terminal/runtime state includes commit `ca0b7af` (or newer on `main`) and refreshed GodotEnv/testbed dependency state so the camera-switch lifecycle fix is actually present when Derrick tests there. Use the canonical local workflow on each host; do not invent mirror-only hacks. Record exactly what was updated per host, what repo state/commit each host ended on, and any host-specific caveats or failures.

**Folders Created/Deleted/Modified:**
- repo-local `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-mediapipe-rollout-and-camera-gesture-parity.md`

**Status:** ✅ Complete

**Results:** Remote rollout completed. All three owner repos (`pico`, `chip`, `byte`) ended on `ca0b7af2dfcf` on `main`, their camera-gesture `.testbed` MediaPipe mounts were refreshed, and mounted runtimes were verified ready. `chip` required extra cleanup of editor-generated repo dirt before pull plus installation of `python3.12-venv` to rebuild the addon-local runtime. Verified fix markers in both owner and mounted addon surfaces on each host, including `_camera_switch_cleanup_pending`, `while _is_stopping or _is_starting`, and `while _is_starting`.

---

### Task 2: Parity gap audit for camera-gesture live-webcam controls

**Bead ID:** `aerobeat-tool-camera-gesture-control-1cm`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Compare the current `aerobeat-tool-camera-gesture-control` hidden testbed against the current `aerobeat-input-mediapipe-python` proving flow and map the exact parity gaps for live-webcam camera selection and tracking-quality controls. Separate what must change in the owner repo versus the consumer repo. Produce an implementation-ready gap list with exact files/scene nodes/scripts.

**Folders Created/Deleted/Modified:**
- repo-local `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-mediapipe-rollout-and-camera-gesture-parity.md`

**Status:** ✅ Complete

**Results:** Gap audit completed. Confirmed the owner repo already has the needed live-camera picker/restart path and the relevant provider/config surfaces. The missing parity is primarily in the consumer testbed: `camera_gesture_testbed.gd` does not expose a live camera picker, does not restart/reconfigure owned MediaPipe runtime on camera change, and only passes `flip_horizontal` in its start settings instead of parity fields like selected camera, `min_visibility`, `tracking_overlay_mode`, and `gesture_eval_interval_frames`. Exact-parity work appears consumer-owned unless Derrick wants additional beyond-parity MediaPipe confidence controls.

---

### Task 3: Implement parity in the owning repo(s)

**Bead ID:** `aerobeat-tool-camera-gesture-control-1jy`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, gap-audit results  
**Prompt:** Implement the smallest truthful parity pass so the camera-gesture testbed gains the latest MediaPipe Python fixes/features for the live-webcam path. When live webcam is selected, the left settings panel should expose camera selection and tracking quality options (`none`, `optimized`, `full`). Preserve prerecorded-video behavior and input-core/session-reuse truths. Land durable source changes in the real owner repo first when required, then refresh the consumer testbed through the normal GodotEnv workflow.

**Folders Created/Deleted/Modified:**
- real `aerobeat-input-mediapipe-python/` if needed
- `aerobeat-tool-camera-gesture-control/.testbed/`
- `aerobeat-tool-camera-gesture-control/src/` if needed

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-mediapipe-rollout-and-camera-gesture-parity.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scripts/camera_gesture_testbed.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scenes/camera_gesture_testbed.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/tests/test_camera_gesture_session_reuse.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/tests/test_camera_gesture_testbed_scene.gd`

**Status:** ✅ Complete

**Results:** Implemented the parity pass entirely in the consumer repo; no owner-repo source changes were needed. Added live-only left-panel camera selection and tracking-quality controls (`none`, `optimized`, `full`), preserved prerecorded replay behavior, wired selected camera/tuning into startup settings and restart behavior, tightened live shared-session reuse to match camera+tuning metadata, and updated status/debug truth surfaces. Validation: `godot --headless --path .testbed --import` plus full GUT suite (`29/29` passed). Commit pushed: `68d382b` — `Add live mediapipe camera parity controls`.

---

### Task 4: QA parity behavior in the camera-gesture testbed

**Bead ID:** `aerobeat-tool-camera-gesture-control-6p9`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Verify the parity behavior in the camera-gesture `.testbed` at the highest-fidelity safe level available: confirm the live-webcam mode shows the new camera-selection and tracking-quality controls in the left-hand settings panel, confirm those controls are hidden or not misleading when prerecorded-video mode is active, and truth-check that the consumer environment is actually using the refreshed MediaPipe source behavior. Respect the normal no-fake-mirror rule.

**Folders Created/Deleted/Modified:**
- repo-local `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-mediapipe-rollout-and-camera-gesture-parity.md`

**Status:** ⚪ Canceled

**Results:** QA canceled at Derrick’s instruction because this lane requires human verification of real camera-switch behavior. Agent-run automated/headless validation remains limited to the coder’s safe import/GUT checks; final behavioral acceptance for camera switching is deferred to human verification.

---

### Task 5: Audit the final state and close the loop

**Bead ID:** `aerobeat-tool-camera-gesture-control-zhz`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** all above  
**Prompt:** Independently audit both halves of the plan: remote rollout truth on `pico`/`chip`/`byte`, and feature/bug-fix parity in `aerobeat-tool-camera-gesture-control`. Confirm the fix is present on the remote hosts, confirm ownership boundaries were respected, and confirm the camera-gesture live-webcam GUI now exposes the requested parity controls truthfully.

**Folders Created/Deleted/Modified:**
- repo-local `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-mediapipe-rollout-and-camera-gesture-parity.md`

**Status:** ✅ Complete

**Results:** Audit confirmed the remote rollout on `pico`, `chip`, and `byte` is real, ownership boundaries were respected, and commit `68d382b` broadly matches the requested consumer-side parity target. The earlier automated-coverage gap in `res://tests/test_camera_gesture_session_reuse.gd` has now been resolved by follow-up commit `24bed82`, with independent audit confirming the repaired file parses, its focused test passes (`2/2`), and the broader suite now truthfully includes it (`31/31` passed). QA remains intentionally canceled in favor of Derrick’s human camera-switch verification, which is now the only remaining behavioral acceptance step.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Completed the remote rollout of the MediaPipe camera-switch fix to `pico`, `chip`, and `byte`, and landed a consumer-side parity pass in `aerobeat-tool-camera-gesture-control` for live-only camera selection and tracking-quality controls. The follow-up truth-gap repair also landed, so automated coverage now honestly includes the new session-reuse test while human camera-switch verification remains the intentional final behavior check outside this plan.

**Reference Check:** `REF-01` and `REF-02` were satisfied by the verified remote rollout to commit `ca0b7af2dfcf` on all three hosts. `REF-03` through `REF-05` were satisfied by the consumer-side parity implementation in commit `68d382b`. `REF-06` remains superseded by this new lane. `REF-07` was followed for refresh workflow. The earlier audit gap was resolved by follow-up commit `24bed82`, and the suite now truthfully includes the repaired session-reuse test (`31/31` passed). Manual live camera-switch verification remains the separate human acceptance step Derrick explicitly retained.

**Commits:**
- `68d382b` - Add live mediapipe camera parity controls
- `24bed82` - Fix camera gesture session reuse test parse error

**Lessons Learned:** The rollout and consumer parity work were solid, but the audit was right to challenge the original test claim. Repairing the truth gap immediately kept the lane honest without conflating automated coverage with the still-required human verification of real camera switching.

---

*Last updated on 2026-05-21*
