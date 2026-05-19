# AeroBeat Tool Camera Gesture Control YAML + Trace Implementation

**Date:** 2026-05-19  
**Status:** In Progress  
**Agent:** Byte 🐈‍⬛

---

## Goal

Implement the repo-local YAML profile system, richer debug/trace surfaces, upgraded `.testbed` harness scaffolding, and the required shared `input-core` contract seams so `aerobeat-tool-camera-gesture-control` can reach the point where only final human verification and recorded golden videos remain.

---

## Overview

The contract-definition phase is complete. We now know the intended harness shape, the YAML config boundary, the runtime `Camera3D` targeting rule, and the observability/trace requirements. Derrick also narrowed the initial implementation scope wisely: start with a single `default_v1.camera_gesture.yaml` profile to prove the plumbing, then allow later duplication/splitting once the system is working.

This implementation lane should therefore prioritize infrastructure over breadth. First, land the profile/trace/doc seams in `aerobeat-tool-camera-gesture-control` itself. Second, add the shared session/provider reuse contract that belongs in `aerobeat-input-core`, because this repo must not privately duplicate MediaPipe lifecycle logic. Third, wire the `.testbed` into the richer 16:9 harness layout with visible config/debug state and enough structure to support prerecorded golden-video work once Derrick finishes recording clips.

The stopping condition for this plan is explicit: keep executing slices until the remaining work is the final human verification / review and the addition of Derrick-authored recorded fixtures. That means it is acceptable to leave fixture content itself for later, but not acceptable to leave the harness, YAML, trace, or shared reuse seams undefined or unimplemented if they are feasible now.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Camera gesture repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control` |
| `REF-02` | Contract definition plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-19-golden-video-harness-contract.md` |
| `REF-03` | Validation readiness assessment | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-19-validation-readiness-assessment.md` |
| `REF-04` | Prior first implementation lane | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-15-camera-gesture-control-first-implementation-lane.md` |
| `REF-05` | Input-core repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core` |
| `REF-06` | MediaPipe Python donor harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` |

---

## Tasks

### Task 1: Land repo-local docs + default YAML profile + runtime profile-loading seam

**Bead ID:** `aerobeat-tool-camera-gesture-control-kkw`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-04`  
**Prompt:** Implement the first repo-local slice in `aerobeat-tool-camera-gesture-control`: add durable docs for the YAML profile/harness contract, create a single working `default_v1.camera_gesture.yaml` under the agreed profile path, and upgrade the runtime controller to load/validate/apply that YAML-backed config model instead of the old JSON-only profile assumptions. Preserve runtime-provided `Camera3D` targeting, and expose active profile identity/path/hash/schema info through debug state. Claim the bead on start, run relevant repo-local tests/smoke checks, commit/push on success, and close the bead only when the slice is complete.

**Folders Created/Deleted/Modified:**
- `assets/`
- `assets/profiles/`
- `src/`
- `docs/`

**Files Created/Deleted/Modified:**
- `README.md`
- `src/camera_gesture_controller.gd`
- `src/AeroToolManager.gd`
- `assets/profiles/camera_gesture/default_v1.camera_gesture.yaml`
- `docs/*` as needed

**Status:** ✅ Complete

**Results:** Landed the repo-local YAML profile seam in `aerobeat-tool-camera-gesture-control`: added a durable v1 profile contract doc, checked in `assets/profiles/camera_gesture/default_v1.camera_gesture.yaml`, upgraded `CameraGestureController` to load/validate/apply YAML-first profile documents while preserving legacy flat JSON compatibility, kept active `Camera3D` ownership runtime-provided, exposed active profile identity/path/hash/schema metadata through `get_debug_state()`, and updated README/testbed/tests to reflect the new config story. Validation included `.testbed` addon restore, headless import, full repo-local GUT pass, `git diff --check`, and a headless `--quit-after 2` smoke run. Commit/push details: landed on `main` in commit `feat: land yaml camera gesture profile seam`.

---

### Task 2: Upgrade `.testbed` harness layout + debug/trace capture scaffolding

**Bead ID:** `aerobeat-tool-camera-gesture-control-qn5`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-06`  
**Prompt:** In `aerobeat-tool-camera-gesture-control`, upgrade the hidden `.testbed` toward the agreed 16:9 harness structure: left debug/config panel, right 3D world preview, bottom-left MediaPipe/video+tracking inset, profile load/reload/export controls, and initial trace-capture scaffolding. It does not need final recorded fixtures yet, but it should be structurally ready for them. Claim the bead on start, run relevant repo-local validation/smoke checks, commit/push on success, and close the bead only when complete.

**Folders Created/Deleted/Modified:**
- `.testbed/assets/`
- `.testbed/scenes/`
- `.testbed/scripts/`
- `.testbed/tests/`

**Files Created/Deleted/Modified:**
- `.testbed/scenes/*`
- `.testbed/scripts/*`
- `.testbed/tests/*`
- `.testbed/addons.jsonc`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Add shared MediaPipe reuse/ownership contract in input-core

**Bead ID:** `aerobeat-input-core-1er`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-05`  
**Prompt:** In `aerobeat-input-core`, implement or document the shared contract needed so repos like `aerobeat-tool-camera-gesture-control` can reuse an already-active MediaPipe-capable provider/session instead of spawning duplicates. Keep ownership boundaries explicit and repo-agnostic. Claim the bead on start, run relevant validation in `aerobeat-input-core`, commit/push on success, and close the bead only when the shared seam is truly usable.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/docs/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.testbed/` if needed

**Files Created/Deleted/Modified:**
- input-core shared contract files/docs/tests as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Integrate camera-gesture runtime with input-core reuse seam + finish repo-local validation

**Bead ID:** `aerobeat-tool-camera-gesture-control-5uz`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-06`  
**Prompt:** Integrate the camera-gesture repo with the new input-core reuse/ownership seam, then run the repo-local QA pass needed to prove the implementation stack is ready for Derrick’s fixture recording and final human review. Verify YAML load/apply behavior, testbed config controls, trace/debug outputs, camera attachment rules, and no-duplicate-MediaPipe behavior in the intended dependency path. Claim the bead on start, commit/push any narrow required fixes, and close only when the remaining work is genuinely human verification / recorded fixtures.

**Folders Created/Deleted/Modified:**
- `src/`
- `.testbed/`
- `.plans/`

**Files Created/Deleted/Modified:**
- integration and validation artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Completed on Pending*
