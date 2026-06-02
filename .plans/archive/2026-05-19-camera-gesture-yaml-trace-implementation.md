# AeroBeat Tool Camera Gesture Control YAML + Trace Implementation

**Date:** 2026-05-19  
**Status:** Stale  
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

**Results:** Landed the repo-local YAML profile seam in `aerobeat-tool-camera-gesture-control`: added a durable v1 profile contract doc, checked in `assets/profiles/camera_gesture/default_v1.camera_gesture.yaml`, upgraded `CameraGestureController` to load/validate/apply YAML-first profile documents while preserving legacy flat JSON compatibility, kept active `Camera3D` ownership runtime-provided, exposed active profile identity/path/hash/schema metadata through `get_debug_state()`, and updated README/testbed/tests to reflect the new config story. Validation included `.testbed` addon restore, headless import, full repo-local GUT pass, `git diff --check`, and a headless `--quit-after 2` smoke run. Commit/push details: landed on `main` in commit `30d3a63` (`feat: land yaml camera gesture profile seam`).

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

**Status:** ✅ Complete

**Results:** Rebuilt the hidden `.testbed` into a practical 16:9 harness with a left YAML/profile/debug/config panel, a clearer right-side 3D world preview for parallax/depth validation, and a bottom-left MediaPipe/video + tracking inset. Added YAML-first profile workflow controls (load checked-in default, load path, reload path, export YAML snapshot, reset runtime defaults), initial trace scaffolding (start/stop/export capture, single-snapshot export, JSON manifest + JSONL frames + notes + Markdown summary, resolved YAML snapshot), and staged prerecorded-fixture folder structure/docs under `.testbed/assets/fixtures/camera_gesture/` for later replay/oracle work. Validation included headless import, full repo-local GUT pass, `git diff --check`, and headless smoke run. Commit/push details: landed on `main` in commit `6baa71b` (`feat: upgrade camera gesture harness trace surface`). Known remaining seam: the MediaPipe inset is an honest v1 that still reaches through the current addon seam for some pose/debug wiring; a cleaner shared debug surface is still a follow-up for the shared input-core/final integration slices.

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

**Status:** ✅ Complete

**Results:** Landed a small, explicit shared in-process provider/session reuse seam in `aerobeat-input-core` via `AeroProviderSessionRegistry`, giving downstream repos a repo-agnostic way to publish, request, acquire, release, and unpublish already-active providers with owner/borrower semantics. The seam intentionally does not auto-start/stop providers or hide ownership transfer; it just makes shared reuse explicit and usable. Added docs, unit coverage, and light testbed/README surfacing. Validation included headless import, targeted GUT for the registry, full unit-dir GUT, and scoped `git diff --check`. Commit/push details: landed on `main` in commit `d8abd1d` (`Add shared provider session reuse seam`). For camera-gesture adoption, the next step is to request/acquire a published `mediapipe_python` session before starting a new provider, publish a newly created provider session when ownership stays local, and release/unpublish appropriately on teardown.

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

**Status:** ⚠️ Partial

**Results:** Integrated the camera-gesture testbed with the input-core shared provider-session seam. The harness now requests/acquires an already-published `mediapipe_python` session before any local startup, lazily starts its own MediaPipe provider only when needed, publishes locally owned sessions back through `AeroProviderSessionRegistry`, and cleanly releases or unpublishes on switch-away / teardown according to borrower-vs-owner state. The trace/debug surfaces now expose session-role metadata and the known duplicate-prevention boundary directly, README/testbed docs were refreshed, and repo-local GUT coverage now explicitly proves both borrowed-session reuse and owned-session publish/unpublish behavior. Validation included refreshing `.testbed` addons so the mounted input-core actually contained the new registry seam, headless import, `--check-only` parse checks for the testbed and new tests, targeted GUT for session reuse / controller / testbed scene, full repo-local GUT, `git diff --check`, and a headless `--quit-after 1000` smoke run. Commit/push details: landed on `main` in commit `f633222` (`feat: integrate shared mediapipe session reuse`). Honest remaining blocker: the currently mounted `aerobeat-input-mediapipe-python` owner/proving path still does not auto-publish its live provider session, so true cross-lane duplicate prevention is only available once that owner lane adopts the same registry seam.

---

### Task 5: Publish mediapipe-python owner sessions into the shared registry

**Bead ID:** `aerobeat-input-mediapipe-python-sct`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-05`, `REF-06`  
**Prompt:** In `aerobeat-input-mediapipe-python`, adopt the new `AeroProviderSessionRegistry` owner path so the lane that actually owns/starts a live MediaPipe provider publishes its session when active and unpublishes it on teardown. Keep the seam honest and limited to in-process shared reuse; do not invent cross-process claims. Add the narrow tests/docs needed to prove the owner lane now participates in duplicate-prevention correctly. Claim the bead on start, validate, commit/push, and close only when the owner publication seam is usable by downstream repos like camera-gesture.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/` if needed
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/` if needed

**Files Created/Deleted/Modified:**
- provider/session publication files/tests/docs as needed

**Status:** ✅ Complete

**Results:** Landed the owner-lane publication seam in `aerobeat-input-mediapipe-python`. The assembly-facing `src/input_provider.gd` now auto-publishes itself into `AeroProviderSessionRegistry` under canonical key `mediapipe_python` after successful startup, and cleanly unpublishes on `stop()` and exit-tree teardown. Added narrow unit coverage proving owner start publishes a borrowable shared session, owner stop unpublishes it, and second-owner collisions leave the first canonical session intact. Documented the same-runtime-only scope and the honest limitation that raw proving-harness direct-backend startup is still not a published shared adapter session. Validation included headless import, targeted GUT for the new adapter seam, and `git diff --check`. Commit/push details: landed on `main` in commit `cc23bce` (`feat: publish shared mediapipe owner sessions`). This clears the remaining owner-publication technical blocker for same-runtime duplicate-prevention before recorded fixtures/human review.

---

## Final Results

**Status:** ✅ Ready for human verification + recorded fixtures

**What We Built:** A YAML-first, trace-aware camera-gesture tool lane with a rebuilt hidden 16:9 testbed harness, default checked-in profile, richer debug/export surfaces, and same-runtime shared MediaPipe session reuse across repos. `aerobeat-tool-camera-gesture-control` now reuses published `mediapipe_python` sessions when available, publishes owned sessions when it starts one locally, and tears them down honestly. `aerobeat-input-core` now provides the shared `AeroProviderSessionRegistry` seam, and `aerobeat-input-mediapipe-python` now publishes assembly-facing owner sessions into that registry.

**Reference Check:** `REF-01` and `REF-02` are satisfied by the YAML-first profile/runtime/testbed stack and the contract-driven harness shape now landed in the repo. `REF-05` is satisfied by the shared provider-session registry seam and the camera-gesture consumer adoption path. `REF-06` is satisfied for the same-runtime owner/consumer duplicate-prevention path through the assembly-facing adapter/publisher flow; the documented remaining limitation is only that raw proving-harness direct-backend startup is not itself a published adapter session, which is now explicit rather than hidden.

**Commits:**
- `30d3a63` - `feat: land yaml camera gesture profile seam`
- `6baa71b` - `feat: upgrade camera gesture harness trace surface`
- `f633222` - `feat: integrate shared mediapipe session reuse`
- `d8abd1d` - `Add shared provider session reuse seam` (in `aerobeat-input-core`)
- `cc23bce` - `feat: publish shared mediapipe owner sessions` (in `aerobeat-input-mediapipe-python`)

**Lessons Learned:** Refreshing mounted `.testbed` addons is part of real validation, not bookkeeping; stale mounted copies can make a contract appear absent even after it landed upstream. The right architecture split held up: camera-gesture owns config-driven camera behavior and testbed observability, `input-core` owns shared in-process session reuse semantics, and `mediapipe-python` owns publication of live adapter sessions when it is the lane that actually starts the provider.

---

---

### Task 6: Scaffold first candidate camera-gesture fixture YAMLs

**Bead ID:** `aerobeat-tool-camera-gesture-control-g5l`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`  
**Prompt:** In `aerobeat-tool-camera-gesture-control`, scaffold the first 8 candidate fixture YAML files to match Derrick’s recorded filenames exactly. Place them under `.testbed/assets/fixtures/camera_gesture/head_pose/candidates/` with same-basename `.fixture.yaml` files, using the agreed camera-gesture fixture shape and honest candidate-level defaults. Do not invent precise timing windows beyond safe placeholders if the edited clips are not yet finalized. Make the files easy for Derrick/Byte to tune after the videos are dropped in. Claim the bead on start, validate the YAML/docs shape, commit/push on success, and close the bead when done.

**Folders Created/Deleted/Modified:**
- `.testbed/assets/fixtures/camera_gesture/head_pose/candidates/`

**Files Created/Deleted/Modified:**
- matching `*.fixture.yaml` files for the 8 recorded clips

**Status:** ✅ Complete

**Results:** Created 8 candidate fixture sidecars under `.testbed/assets/fixtures/camera_gesture/head_pose/candidates/` matching Derrick’s recorded basenames exactly. Each YAML uses same-basename pairing with a relative `./<video>.mp4` path, candidate-stage metadata, inferred intent/sample-source/expected axis-direction semantics, and honest placeholder timing scaffolds/comments instead of fabricated precise windows. Validated all 8 with `python3` + `yaml.safe_load`, verifying fixture ids, video paths, family/feature fields, candidate stage, and repetition hints. Commit/push details: landed on `main` in commit `c61cf17` (`Add candidate head-pose fixture scaffolds`). Small follow-up note captured: once edited clips are synced, the first tuning pass should fill the rep windows and verify real `translation.z` sign behavior for forward/backward clips from exported traces rather than assuming it only from filename semantics.

---

---

### Task 7: Tune first candidate fixture timing windows from synced clips

**Bead ID:** `aerobeat-tool-camera-gesture-control-03w`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-06`  
**Prompt:** In `aerobeat-tool-camera-gesture-control`, inspect the 8 synced head-pose candidate clips, tune the candidate `.fixture.yaml` timing windows for the repeated motions, and run the first trace-backed validation pass where feasible. Keep the edits honest: prefer approximate human-authored windows over fake precision, and document any cases where the actual exported trace sign/direction still needs confirmation. Claim the bead on start, validate the YAMLs, commit/push on success, and close the bead when done.

**Folders Created/Deleted/Modified:**
- `.testbed/assets/fixtures/camera_gesture/head_pose/candidates/`
- `.testbed/test-results/fixtures/` if runtime artifacts are produced

**Files Created/Deleted/Modified:**
- 8 candidate `*.fixture.yaml` files
- any small docs/notes updates only if helpful

**Status:** ⏳ Pending

**Results:** Pending.

---

*Completed on 2026-05-19 — remaining work is recorded fixtures + final human verification/review after this timing-tuning pass*
