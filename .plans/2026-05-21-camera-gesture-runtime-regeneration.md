# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-21  
**Status:** In Progress  
**Agent:** Cookie 🍪

---

## Goal

Repair the missing mounted MediaPipe sidecar runtime in the camera-gesture `.testbed` so live camera startup can run again for human retesting.

---

## Overview

Derrick’s latest runtime error is explicit: the mounted `aerobeat-input-mediapipe-python` addon inside `aerobeat-tool-camera-gesture-control/.testbed/addons/` is missing the addon-local Linux runtime manifest, ready sentinel, and Python executable. This is a consumer runtime-state problem, not a new source-code feature request.

This follow-up should stay extremely narrow: regenerate the mounted addon runtime using the documented `prepare_runtime.py` flow, verify the expected files now exist, and leave the environment ready for Derrick to retest the live camera path. No source edits are expected unless the regen step itself reveals a new truth gap.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current camera-gesture parity plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-21-mediapipe-rollout-and-camera-gesture-parity.md` |
| `REF-02` | Mounted addon runtime path failing startup | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/` |
| `REF-03` | Canonical runtime repair command from AutoStartManager error | `python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --install-requirements --validate` |

---

## Tasks

### Task 1: Regenerate mounted addon runtime and verify readiness

**Bead ID:** `aerobeat-tool-camera-gesture-control-dki`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control`, repair the missing mounted MediaPipe addon runtime under `.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/`. Claim the bead on start with `bd update <id> --status in_progress --json`. Use the documented `prepare_runtime.py` flow against the mounted addon, verify the expected runtime manifest / ready sentinel / Python executable now exist, and report any caveats. Keep the work narrow and do not broaden into source edits unless a new truth gap is proven. Commit source changes only if any are actually needed; otherwise leave this as runtime-state repair only and close the bead with `bd close <id> --reason "Regenerated camera-gesture mounted addon runtime" --json`.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-camera-gesture-runtime-regeneration.md`
- mounted runtime files under `.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Runtime-regeneration plan drafted; execution in progress.

**Reference Check:** Anchored to the exact mounted runtime path and the AutoStartManager repair command.

**Commits:**
- None yet.

**Lessons Learned:** Consumer addon runtime state can drift independently from source commits, so live retest blockers may need repair even after code and rollout lanes are complete.

---

*Last updated on 2026-05-21*
