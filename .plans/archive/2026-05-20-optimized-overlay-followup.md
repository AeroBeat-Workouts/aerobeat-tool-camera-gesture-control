# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-20  
**Status:** Stale  
**Agent:** Cookie 🍪

---

## Goal

Finish the `optimized` tracking-overlay mode so Boxing/Flow proving scenes stop showing the extra tracking dots Derrick still sees in the camera preview.

---

## Overview

Derrick’s latest verification pass is mostly green: Boxing prerecorded works, Boxing live webcam works including camera swapping on Byte, Flow prerecorded works, and Flow live webcam works including camera swapping. The remaining issue is narrow but important: setting Boxing tracking overlay mode to `optimized` still leaves tracking dots visible in the preview, which means the intended optimized-mode behavior is not fully implemented from the user’s point of view.

The contract for `optimized` was previously clarified: preserve useful tracking for arms/legs/core and keep only the minimum head data needed for head position/rotation (left eye, right eye, central head point / nose). This follow-up should verify whether the remaining visible dots are caused by the overlay draw path ignoring the filtered landmark payload, by an incorrect mode mapping in the proving harness/provider chain, or by a mismatch between “optimized tracking” and “optimized visual overlay” expectations. Then it should land the actual fix in the real owner repo and validate on the proving scenes.

This is a real-owner-repo-first fix. Durable edits belong in the real `aerobeat-input-mediapipe-python` repo, then the consumer proving environment should be refreshed and verified normally.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | MediaPipe owner repo with tracking mode / overlay logic | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` |
| `REF-02` | Consumer proving environment used for Boxing/Flow validation | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control` |
| `REF-03` | Prior performance / tracking-mode plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-20-mediapipe-byte-performance-pass.md` |
| `REF-04` | Prior regression repair plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-20-byte-camera-dropdown-regression-repair.md` |

---

## Tasks

### Task 1: Fix optimized overlay behavior in the owner repo

**Bead ID:** `aerobeat-tool-camera-gesture-control-vor`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Implement the optimized-overlay follow-up against bead `aerobeat-tool-camera-gesture-control-vor`, claiming it on start in the coordination repo while doing the durable source fix in the real `aerobeat-input-mediapipe-python` repo. Determine why `optimized` tracking mode is still drawing the full face landmark set in the proving preview, then fix the real owner code so the visible overlay matches the intended optimized behavior. Acceptance target: in `optimized`, visible face/head dots must collapse to only left eye, right eye, and nose/center head point; no mouth, eyebrow, or other extra face dots should remain visible. Land the durable fix in the owner repo first, then refresh the consumer proving environment normally and validate there. Commit/push by default and leave a concise handoff.

**Folders Created/Deleted/Modified:**
- real `aerobeat-input-mediapipe-python/src/`
- real `aerobeat-input-mediapipe-python/.testbed/`
- consumer proving environment via refresh only as needed

**Files Created/Deleted/Modified:**
- repo-dependent; likely provider / overlay draw / proving harness files

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 2: QA and audit the optimized overlay result

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `qa` / `auditor`)  
**Role:** `qa` / `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Verify that `optimized` mode now behaves as intended in the proving scenes: the remaining extra dots should be gone, while the useful live-camera behaviors that just passed (Boxing/Flow prerecorded, Boxing/Flow live camera, camera swapping) remain intact.

**Folders Created/Deleted/Modified:**
- QA evidence only if needed

**Files Created/Deleted/Modified:**
- none expected unless evidence is added

**Status:** ⏳ Pending

**Results:** Not started.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending follow-up.

**Reference Check:** Pending follow-up.

**Commits:**
- Pending

**Lessons Learned:** Pending follow-up.

---

*Completed on Pending*
