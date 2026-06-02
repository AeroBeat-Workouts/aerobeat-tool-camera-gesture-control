# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-21  
**Status:** Stale  
**Agent:** Cookie 🍪

---

## Goal

Fix the two remaining live-camera regressions in the camera-gesture `.testbed`: make camera selection actually switch the visible device, and restore visible donor-style tracking dots for `full` / `optimized` modes.

---

## Overview

Derrick’s latest manual QA narrowed the problem sharply. The prior repair successfully stopped the Zorin GUI crash and corrected the overlay bounds/orientation issue, but two real failures remain: switching cameras does not visibly switch to the newly selected device, and no visible tracking dots appear under either `full` or `optimized`.

That means this pass should stay tightly focused. First, prove where camera-source propagation is breaking in the consumer-owned restart path — whether the selected device is failing to reach the preview-side autostart path, the provider-side runtime, or the ready/rebind stage after restart. Second, restore visible donor-style tracking dots truthfully instead of relying on the disabled built-in `camera_view` overlay path. The donor `aerobeat-input-mediapipe-python` proving scenes remain the source of truth for what “visible overlay” means.

Derrick remains the human QA owner for final behavior verification.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Active regression plan and latest human QA notes | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-21-camera-gesture-live-switch-and-overlay-regressions.md` |
| `REF-02` | Consumer testbed script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scripts/camera_gesture_testbed.gd` |
| `REF-03` | Consumer inset overlay script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scripts/tracking_inset_overlay.gd` |
| `REF-04` | Donor proving harness source of truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-05` | Donor overlay drawer source of truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/landmark_drawer.gd` |
| `REF-06` | Latest human QA screenshots | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/21/image-99590bcf.png`, `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/21/image-aed2a9c2.png` |

---

## Tasks

### Task 1: Fix camera-source propagation and restore visible donor-style overlay

**Bead ID:** `aerobeat-tool-camera-gesture-control-q81`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control`, fix the two remaining live-camera regressions: (1) selected live camera does not actually switch the visible camera, and (2) visible tracking dots are missing for `full` / `optimized`. Keep the work narrow and consumer-owned unless a new truth gap proves otherwise. Use the donor proving harness and donor overlay drawer behavior as source of truth. Commit/push by default and report exact files changed, validation performed, and what Derrick should retest manually.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`
- `.testbed/tests/` if needed

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-camera-gesture-camera-switch-propagation-and-visible-overlay.md`
- exact implementation files pending work

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 2: Audit the narrowed follow-up truthfully

**Bead ID:** `aerobeat-tool-camera-gesture-control-dqr`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** all above  
**Prompt:** Audit the narrow follow-up repair. Confirm the code now truthfully propagates selected live camera changes through the consumer restart path and restores visible donor-style tracking dots for `full` / `optimized`. Human QA remains Derrick-owned, so do not claim final behavioral success beyond code/validation truth.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-camera-gesture-camera-switch-propagation-and-visible-overlay.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Follow-up plan drafted; execution in progress.

**Reference Check:** Anchored to the narrowed human QA failures and the donor proving/overlay source of truth.

**Commits:**
- None yet.

**Lessons Learned:** Once crash-risk and geometry bugs are removed, remaining regressions often collapse to a narrower source-propagation bug and a missing visual parity layer.

---

*Last updated on 2026-05-21*
