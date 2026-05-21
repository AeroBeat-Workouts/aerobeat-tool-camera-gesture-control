# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-20  
**Status:** Draft  
**Agent:** Cookie 🍪

---

## Goal

Repair the Byte camera-dropdown regressions by fixing live-camera source classification, Flow prerecorded startup crashes, Boxing default-scene truth, camera enumeration UX, and the cross-repo camera-device contract mismatch.

---

## Overview

The first camera-dropdown pass surfaced multiple real regressions on Byte rather than one isolated bug. The biggest immediate break is source classification: the new dropdown stores live cameras as strings like `/dev/video0`, but the autostart path still interprets non-integer strings as prerecorded file paths, so live-camera startup fails before the provider can do useful work. In parallel, the latest Python sidecar changes introduced an actual crash in prerecorded Flow mode via an undefined helper in `main.py`.

There is also a durable-truth issue around Boxing defaults: the owner repo and the synced/consumer state drifted, so the intended “live camera by default” behavior was not consistently represented in committed source. Finally, the camera-device work introduced a shared-contract mismatch (`camera_devices_changed`) and still needs better camera enumeration UX on Linux/Byte so athletes see meaningful camera choices rather than confusing raw node behavior.

This repair pass should land durable fixes in the real owning repos first, then refresh and validate in the consumer environment, including Byte where needed. The goal is to get Boxing and Flow back to a correct, testable state before further UX/performance iteration.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Byte regression investigation plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-20-byte-camera-dropdown-regression-investigation.md` |
| `REF-02` | Boxing/Flow dropdown implementation plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-20-boxing-camera-dropdown-pass.md` |
| `REF-03` | Byte Boxing screenshot showing `/dev/video0` misclassified as prerecorded | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/20/image-9755c4ad.png` |
| `REF-04` | Real MediaPipe owner repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` |
| `REF-05` | Real input-core contract repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core` |
| `REF-06` | Consumer proving environment / refresh target | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control` |
| `REF-07` | Authorized direct Byte access path | `ssh byte` |

---

## Tasks

### Task 1: Repair source classification and Flow startup crash in the owner repo

**Bead ID:** `aerobeat-input-mediapipe-python-785`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-07`  
**Prompt:** Repair the immediate owner-repo regressions in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` against bead `aerobeat-input-mediapipe-python-785`. Claim it on start with `bd update aerobeat-input-mediapipe-python-785 --status in_progress --json`. Fix live-camera source classification so `/dev/video*` values are treated as live camera sources rather than prerecorded media paths. Fix the prerecorded Flow Python crash in `python_mediapipe/main.py` caused by the undefined `filter_landmarks_for_tracking_mode` path. Also make the Boxing default-scene truth explicit and committed if Boxing is meant to default to live camera rather than a prerecorded fixture. Validate locally and on Byte if needed, commit/push to `main`, and leave a concise handoff. Do the work in the real owner repo only; do not patch a mounted `/addons/` clone as source of truth.

**Folders Created/Deleted/Modified:**
- real `aerobeat-input-mediapipe-python/src/`
- real `aerobeat-input-mediapipe-python/python_mediapipe/`
- real `aerobeat-input-mediapipe-python/.testbed/scenes/`

**Files Created/Deleted/Modified:**
- likely `src/autostart_manager.gd`
- likely `python_mediapipe/main.py`
- likely `.testbed/scenes/boxing_proving.tscn`
- any directly related tests/helpers needed for validation

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 2: Repair camera-device contract mismatch and camera list UX

**Bead ID:** `aerobeat-input-core-xvc` + `aerobeat-tool-camera-gesture-control-3a8`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Repair the cross-repo camera-device integration mismatch against beads `aerobeat-input-core-xvc` and `aerobeat-tool-camera-gesture-control-3a8`. Claim the relevant bead(s) on start in the real repos you touch. Ensure the shared/core contract and MediaPipe implementation agree on camera-device signals/methods (including `camera_devices_changed` if it remains part of the contract). Improve Linux/Byte camera enumeration UX so dropdown entries are meaningful and not misleading raw duplicates where avoidable. Land the durable contract fix in the real input-core repo first if required, then consume it in the real mediapipe-python repo, then refresh the consumer proving environment normally. Do not treat any consumer `/addons/` clone as the source of truth for the repair.

**Folders Created/Deleted/Modified:**
- real `aerobeat-input-core/`
- real `aerobeat-input-mediapipe-python/`
- consumer `aerobeat-tool-camera-gesture-control/.testbed/` via refresh/validation as needed

**Files Created/Deleted/Modified:**
- repo-dependent; likely interface/provider/consumer integration files

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 3: QA and audit on actual target behavior, including Byte

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `qa` / `auditor`)  
**Role:** `qa` / `auditor`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Verify the repaired behavior against Derrick’s reported Byte scenarios: Boxing live camera should default/load correctly, the camera dropdown should show the expected camera choices on Byte, Flow prerecorded mode should launch without killing the Python server, and dropdown hide/show rules should still behave correctly. Validate in the real target environment, using `ssh byte` and/or Byte-local runtime evidence as needed.

**Folders Created/Deleted/Modified:**
- QA evidence only if needed

**Files Created/Deleted/Modified:**
- none expected unless evidence is added

**Status:** ⏳ Pending

**Results:** Not started.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending repair.

**Reference Check:** Pending repair.

**Commits:**
- Pending

**Lessons Learned:** Pending repair.

---

*Completed on Pending*
