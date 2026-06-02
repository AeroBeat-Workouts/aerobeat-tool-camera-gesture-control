# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-21  
**Status:** Stale  
**Agent:** Cookie 🍪

---

## Goal

Fix the newly observed crash regression when switching tracking quality from `full` to `simple` in the camera-gesture `.testbed`.

---

## Overview

Derrick’s latest manual QA surfaced a new, narrower regression: changing tracking quality from `full` to `simple` crashes the Zorin OS GUI. This is distinct from the earlier camera-device switching issue and should be treated as its own focused lifecycle bug.

The correct first move is to compare the consumer quality-switch path against the donor `aerobeat-input-mediapipe-python` proving flow, then determine whether the crash comes from consumer restart choreography, owner-side provider reconfiguration/reset, or overlay renderer state transitions. Because this crash affects the live GUI path directly, final truth remains human-owned.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Active preview-binding / signal-truth plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-21-camera-gesture-preview-binding-and-signal-truth.md` |
| `REF-02` | Consumer testbed script under test | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scripts/camera_gesture_testbed.gd` |
| `REF-03` | Consumer overlay script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scripts/tracking_inset_overlay.gd` |
| `REF-04` | Donor proving harness source of truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-05` | Owner provider/runtime path likely involved | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/camera_view.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/input_provider.gd` |

---

## Tasks

### Task 1: Map quality-switch crash path against donor truth

**Bead ID:** `aerobeat-tool-camera-gesture-control-0c1`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Compare the camera-gesture consumer path for tracking-quality changes against the donor proving harness/runtime truth and identify the likely crash surface for `full` → `simple`. Determine whether the bug is consumer-owned, owner-owned, or cross-repo, and produce an implementation-ready gap list.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-camera-gesture-quality-switch-crash-regression.md`

**Status:** ✅ Complete

**Results:** Crash-path mapping completed. Confirmed the consumer is using a hot quality-switch restart path that tears down/rebuilds preview state before the sidecar restart completes and reuses the existing owned provider across the transition, unlike donor truth. The highest-probability crash surface is therefore the consumer’s out-of-order teardown/restart/reuse sequence during live quality changes, with `MediaPipeCameraView.stop_stream()` thread waiting acting as a secondary contributing surface rather than the primary root cause.

---

### Task 2: Implement the narrowed crash fix

**Bead ID:** `aerobeat-tool-camera-gesture-control-y4m`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** Task 1 results plus all above  
**Prompt:** Implement the smallest truthful fix for the `full` → `simple` tracking-quality crash regression. Respect repo ownership boundaries, keep the change narrow, and preserve already-working camera switch and overlay behavior.

**Folders Created/Deleted/Modified:**
- consumer `.testbed/`
- owner repo only if proven necessary

**Files Created/Deleted/Modified:**
- exact implementation files pending Task 1

**Status:** ⏳ In Progress

**Results:** Follow-up coder subagent launched on 2026-05-21 against bead `aerobeat-tool-camera-gesture-control-hnq`; fixing the controller/provider handoff so quality restarts do not leave the controller attached to a freed provider.

---

### Task 3: Human QA

**Bead ID:** `Human-owned`  
**SubAgent:** `human`  
**Role:** `qa`  
**References:** all above  
**Prompt:** Derrick will manually verify that switching tracking quality no longer crashes the GUI and that the resulting overlay/tracking behavior remains sensible.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-camera-gesture-quality-switch-crash-regression.md`

**Status:** ⚪ Human QA Pending

**Results:** Human verification explicitly owned by Derrick.

---

### Task 4: Audit the narrowed crash fix

**Bead ID:** `aerobeat-tool-camera-gesture-control-5xa`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** all above  
**Prompt:** Audit the narrowed repair for the quality-switch crash path. Confirm the code truthfully addresses the likely crash surface without overstating behavior beyond Derrick’s manual QA.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-camera-gesture-quality-switch-crash-regression.md`

**Status:** ⏳ In Progress

**Results:** Auditor subagent launched on 2026-05-21 against bead `aerobeat-tool-camera-gesture-control-hg1`; reviewing commit `78c2126` and the controller/provider handoff fix.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Draft crash-regression plan only.

**Reference Check:** Anchored to the consumer quality-switch surface and donor proving/runtime truth.

**Commits:**
- None yet.

**Lessons Learned:** Once camera-device switching is mostly stabilized, quality-mode transitions can still exercise a distinct crash path that deserves its own narrow lifecycle investigation.

---

*Last updated on 2026-05-21*
