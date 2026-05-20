# AeroBeat Camera Gesture Replay Hookup Fix

**Date:** 2026-05-19  
**Status:** ⚠️ Ready for GUI verification  
**Agent:** Byte 🐈‍⬛

---

## Goal

Hook the camera-gesture `.testbed` scene up for real MediaPipe and prerecorded-video fixture execution so the scene no longer truthfully reports that those paths are unhooked.

---

## Overview

Derrick opened the testbed scene and found the current truth: the harness still says it is not hooked up yet for MediaPipe / recorded videos. That means the previous implementation slices landed the structure, fixture staging, YAML config system, and shared session seams, but did not complete the final replay/runtime hookup inside the actual scene UX.

This is the right next fix. The work should focus on making the testbed honestly usable for the intended fixture flow: consume live MediaPipe through the mounted dependency path when available, accept prerecorded-video fixture inputs through a real execution path, surface the active runtime mode clearly in the scene, and align the test scene to AeroBeat’s default 1920×1080 resolution so desktop/editor verification reflects the real target layout. If a full oracle layer is still out of scope, the scene should still support real replay and trace export so Derrick can perform the first meaningful validation passes.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Camera gesture repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control` |
| `REF-02` | Current implementation plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-19-camera-gesture-yaml-trace-implementation.md` |
| `REF-03` | MediaPipe Python donor repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` |
| `REF-04` | Current candidate fixtures | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/assets/fixtures/camera_gesture/head_pose/candidates/` |

---

## Tasks

### Task 1: Inspect the current testbed hookup gap

**Bead ID:** `aerobeat-tool-camera-gesture-control-8lf`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Inspect the current camera-gesture `.testbed` scene/scripts and identify exactly why the scene still reports that MediaPipe / recorded videos are not hooked up. Separate live MediaPipe hookup, prerecorded replay hookup, and any UI messaging drift. Claim the bead on start and close it when the gap is mapped.

**Status:** ✅ Complete

**Results:** Gap mapped from source inspection. Main findings: live MediaPipe hookup mounted the consumer seam but did not compose the donor-style `AutoStartManager`, so local provider startup could exist without actually booting the Python sidecar path. Prerecorded replay fields were only UI/export scaffolding and did not drive runtime mode or video source selection. Stale placeholder defaults and “future prerecorded” copy were still present in the testbed UI/README. The gap was fixable purely in this repo by composing `AutoStartManager`, splitting live/replay source modes, using real fixture paths, and updating truth-reporting copy; no donor-repo blocker was required for the minimal hookup.

---

### Task 2: Implement the real live/replay hookup in the scene

**Bead ID:** `aerobeat-tool-camera-gesture-control-w95`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`  
**Prompt:** Implement the camera-gesture testbed hookup so the scene can honestly use mounted MediaPipe and prerecorded fixture inputs through the intended path. Update the scene UI/status text so it reflects real runtime state rather than stale placeholder copy, and change the test scene to target 1920×1080 so it matches AeroBeat’s default resolution. Claim the bead on start, validate, commit/push, and close only when the hookup is real.

**Status:** ✅ Complete

**Results:** Live/replay hookup landed on `main` in commit `12a479b` (`Wire camera gesture testbed live and replay runtime`). The testbed now exposes `fake`, `mediapipe_live`, and `mediapipe_replay` modes; `mediapipe_live` first reuses a published shared MediaPipe session and otherwise boots a local provider plus donor-style `AutoStartManager`; `mediapipe_replay` resolves the selected fixture video + sidecar through a new fixture runtime helper and drives MediaPipe through `camera_source_override` so the recorded video actually powers runtime. Session metadata/debug/trace exports now report truthful live-vs-replay state, runtime mode, camera source, fixture key, and replay config. The testbed target surface was updated to 1920×1080. Safe validation covered parse/import checks, targeted GUT for fixture runtime config / scene / session reuse, and scoped diff hygiene. Per Derrick’s safety rule, no headless MediaPipe scene verification was attempted.

---

### Task 3: Verify against the new candidate fixtures

**Bead ID:** `aerobeat-tool-camera-gesture-control-2tj`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-04`  
**Prompt:** Run the updated harness against the candidate fixture set and verify that the recorded-video path is actually usable for first-pass trace/export validation. Document any remaining limitation honestly. Claim the bead on start and close when the remaining work is genuinely human review/oracle tuning only.

**Status:** ⚠️ Pending GUI verification

**Results:** The remaining verification step is intentionally GUI-only: open the Godot editor testbed scene, run `mediapipe_live` and `mediapipe_replay` through normal human-style start/stop from the editor, and confirm that live preview, replay preview, status/debug surfaces, and source switching all behave truthfully. This was deliberately left for in-person validation because Derrick warned that MediaPipe headless scene runs can hard-crash the desktop GUI, and that rule was honored.

---

## Final Results

**Status:** ⚠️ Ready for human GUI verification

**What We Built:** A real live/replay hookup path for the camera-gesture testbed. The scene now has explicit `fake`, `mediapipe_live`, and `mediapipe_replay` modes; live mode reuses shared MediaPipe sessions or boots a local sidecar path through `AutoStartManager`; replay mode resolves candidate fixture video + sidecar data and drives MediaPipe via `camera_source_override`; and the test surface now targets AeroBeat’s default 1920×1080 resolution.

**Reference Check:** `REF-01` is satisfied by the repo-local scene/script changes. `REF-03` was used as the donor composition pattern via `AutoStartManager`. `REF-04` is wired into the replay path through real checked-in fixture defaults instead of placeholder examples. The only work intentionally left open is the manual GUI verification step required by Derrick’s MediaPipe crash warning.

**Commits:**
- `12a479b` - `Wire camera gesture testbed live and replay runtime`

**Lessons Learned:** The gap was not an abstract architecture issue; it was the final composition layer inside the actual scene. The fixture/UI/trace scaffolding already existed, but until `AutoStartManager`, replay source selection, and truthful status text were wired into the real testbed, the scene correctly reported itself as not hooked up. Also, the safety rule matters: for this lane, source inspection plus non-MediaPipe-safe checks are acceptable, but final truth must come from the editor GUI path rather than headless MediaPipe scene runs.

---

*Completed on 2026-05-19 — pending in-person GUI verification next session*
