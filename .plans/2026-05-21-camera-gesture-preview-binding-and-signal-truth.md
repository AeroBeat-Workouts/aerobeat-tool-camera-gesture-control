# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-21  
**Status:** Draft  
**Agent:** Cookie 🍪

---

## Goal

Fix the two remaining live-camera issues in the camera-gesture `.testbed`: the visible preview feed not reliably rebinding to the selected camera after switching, and the gesture-control system consuming unstable/noisy tracking signal instead of a trustworthy head-tracking path.

---

## Overview

Derrick’s latest manual QA shows the lane is much healthier than before: the GUI no longer crashes, donor-style MediaPipe dots are visible again, and switching cameras now pauses then resumes tracking against the newly selected source. That means the selected camera is reaching at least part of the MediaPipe runtime path. The remaining failures are narrower and likely separable.

First, the visual preview stream is still not reliably rebinding to the selected camera even though tracking appears to move over. That suggests the preview/camera-view reconnection path is not consuming the same effective source identity as the tracking side after restart, or is reconnecting against stale state. Second, the gesture-control system is still jumping around like noise, which suggests the controller-facing signal path is either consuming the wrong normalized values, stale values, or an insufficiently filtered/smoothed signal relative to what the visible MediaPipe overlay is showing.

This pass should therefore begin with a research comparison of the consumer’s preview rebinding and controller signal flow against the donor proving/runtime truth and the consumer’s own visible overlay state. After that, implement the narrowest consumer-owned repair that makes preview source rebinding truthful and reconnects the gesture controller to a stable head-tracking signal. Derrick remains the human QA owner for final behavior verification.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Active live-switch / overlay regression plan with latest manual QA notes | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-21-camera-gesture-live-switch-and-overlay-regressions.md` |
| `REF-02` | Consumer testbed script under test | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scripts/camera_gesture_testbed.gd` |
| `REF-03` | Consumer overlay script under test | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scripts/tracking_inset_overlay.gd` |
| `REF-04` | Consumer controller runtime | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/src/camera_gesture_controller.gd` |
| `REF-05` | Donor proving harness truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-06` | Donor camera/preview runtime path | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/camera_view.gd` |
| `REF-07` | Latest human QA screenshot | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/21/image-1627dafb.png` |

---

## Tasks

### Task 1: Map preview-binding and gesture-signal truth gaps

**Bead ID:** `aerobeat-tool-camera-gesture-control-lz0`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Compare the consumer camera-gesture preview rebinding path and gesture-controller signal flow against the donor proving/runtime truth and the user’s latest QA evidence. Determine why tracking appears to switch but the visible preview feed does not reliably follow, and why the gesture-control system appears extremely noisy/disconnected from the visible MediaPipe pose. Produce an implementation-ready gap list and state whether each fix belongs in the consumer repo or owner repo.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-camera-gesture-preview-binding-and-signal-truth.md`

**Status:** ⏳ In Progress

**Results:** Research subagent launched on 2026-05-21 against bead `aerobeat-tool-camera-gesture-control-lz0`; awaiting preview-binding and gesture-signal gap map.

---

### Task 2: Implement the narrowed repair

**Bead ID:** `aerobeat-tool-camera-gesture-control-2iw`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** Task 1 results plus all above  
**Prompt:** Implement the smallest truthful fix set for the remaining preview-binding and gesture-signal issues. Make the visible preview feed reliably follow the selected live camera after switching, and reconnect the controller to a stable/truthful head-tracking signal path that matches the visible MediaPipe pose. Preserve the working no-crash switch behavior, visible overlay, and replay path.

**Folders Created/Deleted/Modified:**
- consumer `.testbed/`
- consumer `src/`
- owner repo only if proven necessary

**Files Created/Deleted/Modified:**
- exact implementation files pending Task 1

**Status:** ⏳ In Progress

**Results:** Cross-repo coder subagent launched on 2026-05-21 against bead `aerobeat-tool-camera-gesture-control-2iw`; implementing consumer preview rebuild/rebind fixes plus owner-side detector/camera-view reset hardening.

---

### Task 3: Human QA

**Bead ID:** `Human-owned`  
**SubAgent:** `human`  
**Role:** `qa`  
**References:** all above  
**Prompt:** Derrick will manually verify that the selected live camera visibly changes the preview feed after switching and that the gesture-control system now responds stably and sensibly to the visible MediaPipe pose.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-camera-gesture-preview-binding-and-signal-truth.md`

**Status:** ⚪ Human QA Pending

**Results:** Human verification explicitly owned by Derrick.

---

### Task 4: Audit the narrowed repair truthfully

**Bead ID:** `aerobeat-tool-camera-gesture-control-dm6`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** all above  
**Prompt:** Audit the narrowed follow-up repair. Confirm the code truthfully addresses preview rebinding and controller signal-path correctness without overstating final behavior beyond Derrick’s human QA.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-camera-gesture-preview-binding-and-signal-truth.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Draft follow-up plan only.

**Reference Check:** Anchored to the latest narrowed QA findings, the consumer runtime/controller surfaces, and donor preview/runtime truth.

**Commits:**
- None yet.

**Lessons Learned:** Once overlay geometry and restart choreography are mostly right, the remaining bugs often split cleanly into preview-source rebinding truth and controller-signal contract truth.

---

*Last updated on 2026-05-21*
