# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-21  
**Status:** In Progress  
**Agent:** Cookie 🍪

---

## Goal

Fix the camera-gesture `.testbed` live-camera regressions so camera switching recovers cleanly and the MediaPipe tracking overlay matches the visual inset behavior/alignment of the working `aerobeat-input-mediapipe-python` proving scenes.

---

## Overview

Derrick’s live retest on the camera-gesture consumer surface produced four concrete truths: the live camera can start, camera switching currently enters a frozen bad state instead of recovering to the newly selected device, the tracking dots render outside the visible preview bounds, and the tracking dots are flipped / visually misaligned compared with the real `aerobeat-input-mediapipe-python` proving scenes.

That means this is no longer a general parity feature lane; it is a regression repair and donor-parity truth pass. The working donor behavior in the real MediaPipe Python proving scenes must be treated as the source of truth for both the camera-switch lifecycle and overlay/inset alignment logic. Durable edits still belong in the real owning source repo when the bug is actually there, but the earlier gap audit suggested this lane is mostly consumer-owned. This plan therefore starts with a narrow source-of-truth comparison against the donor scenes/scripts and only then moves to implementation in the owning repo(s) indicated by that comparison.

Derrick has already supplied a screenshot artifact showing the overlay escaping the visible inset bounds and misaligning against the video. That artifact should be cited directly in the repair pass rather than relying on memory.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Consumer regression/parity plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-21-mediapipe-rollout-and-camera-gesture-parity.md` |
| `REF-02` | Consumer runtime regeneration plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-21-camera-gesture-runtime-regeneration.md` |
| `REF-03` | Consumer testbed script under test | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scripts/camera_gesture_testbed.gd` |
| `REF-04` | Consumer testbed scene/UI under test | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scenes/camera_gesture_testbed.tscn` |
| `REF-05` | Donor owner repo proving harness source of truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-06` | Donor owner repo camera/overlay scene logic | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/` |
| `REF-07` | User-provided screenshot artifact showing overlay misalignment/out-of-bounds behavior | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/21/image-311acc1d.png` |

---

## Tasks

### Task 1: Donor-vs-consumer regression mapping

**Bead ID:** `aerobeat-tool-camera-gesture-control-sih`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Compare the broken camera-gesture consumer flow against the working `aerobeat-input-mediapipe-python` donor proving scenes. Map the exact differences responsible for: (1) frozen bad-state camera switching, (2) overlay dots escaping the inset bounds, and (3) overlay flip/alignment mismatch. Use the user screenshot artifact as evidence. Produce an implementation-ready gap list and state whether each fix belongs in the consumer repo or the owner repo.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-camera-gesture-live-switch-and-overlay-regressions.md`

**Status:** ✅ Complete

**Results:** Regression mapping completed. Confirmed the frozen live-camera bad state is caused by the consumer testbed not using the donor proving harness restart choreography on camera changes, while the overlay bugs are also consumer-owned: `TrackingInsetOverlay` maps to the full control rect instead of displayed-image bounds, uses the wrong Y contract, and the consumer additionally enables `MediaPipeCameraView.show_overlay = true` even though it is feeding provider-normalized gameplay-space landmarks into a view overlay that expects camera-image-space coordinates. The donor proving harness disables that built-in overlay and uses donor-style bounds-aware drawer logic instead.

---

### Task 2: Implement the regression fixes in the owning repo(s)

**Bead ID:** `aerobeat-tool-camera-gesture-control-2co`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, Task 1 results  
**Prompt:** Implement the smallest truthful fix set for the live-camera regressions. Restore clean camera-switch recovery, keep the overlay inside the visible inset bounds, and align/flip the overlay to match the donor proving scenes. Respect repo ownership boundaries: fix real owner-repo behavior there if the comparison proves the bug is upstream; otherwise keep the work consumer-owned. Commit/push by default and report exact files changed plus validation performed.

**Folders Created/Deleted/Modified:**
- consumer `.testbed/`
- real owner repo only if proven necessary

**Files Created/Deleted/Modified:**
- exact implementation files pending Task 1

**Status:** ⏳ In Progress

**Results:** Coder subagent launched on 2026-05-21 against bead `aerobeat-tool-camera-gesture-control-2co`; implementing the confirmed consumer-owned switch and overlay parity repairs.

---

### Task 3: QA the repaired behavior against the donor truth

**Bead ID:** `Human-owned`  
**SubAgent:** `human`  
**Role:** `qa`  
**References:** `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Derrick will manually verify the repaired camera-gesture consumer behavior against the working donor scenes and the user-provided screenshot evidence. Acceptance focus: camera switching no longer freezes into a bad state, overlay dots stay within the inset bounds, and alignment/flip behavior matches donor truth.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-camera-gesture-live-switch-and-overlay-regressions.md`

**Status:** ⚪ Human QA In Progress

**Results:** Derrick manually verified on 2026-05-21 that camera switching no longer crashes the Zorin OS GUI. After follow-up fixes, donor-style MediaPipe dots are visible again inside the inset, and camera switching now pauses tracking then resumes against the newly selected camera source. Remaining failures: the visual camera feed does not reliably switch with the selected device (the second camera only appeared temporarily on a later switch), and the gesture-control system driven from the tracking data is still extremely noisy/jumpy and does not appear stably coupled to the visible tracking pose. Latest screenshot evidence: `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/21/image-1627dafb.png`.

---

### Task 4: Audit final truth

**Bead ID:** `aerobeat-tool-camera-gesture-control-rom`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** all above  
**Prompt:** Independently audit the regression mapping, implementation, and QA results. Confirm the repair truly addresses the frozen-switch bad state and the overlay bounds/alignment mismatch against the donor scenes, and call out any unsupported claims.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-camera-gesture-live-switch-and-overlay-regressions.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Draft regression-repair plan only.

**Reference Check:** Anchored to the donor proving harness as source of truth and the provided screenshot artifact as direct evidence.

**Commits:**
- None yet.

**Lessons Learned:** Consumer parity work can still diverge from the donor proving scenes in subtle but visible ways; screenshot-backed donor comparison should be the first move before another implementation pass.

---

*Last updated on 2026-05-21*
