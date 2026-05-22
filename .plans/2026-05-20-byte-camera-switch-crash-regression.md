# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-20  
**Status:** Draft  
**Agent:** Cookie 🍪

---

## Goal

Repair the new Byte regression where switching cameras in the Boxing proving scene crashes the Zorin OS session / breaks the proving environment, regardless of `optimized` vs `full` tracking mode.

---

## Overview

Derrick reproduced the crash twice on Byte: once while using `optimized`, and again while using `full`. In both cases, the trigger was switching from the native webcam to the Logitech webcam in the Boxing proving scene. That means the regression is not limited to overlay-mode semantics. The likely fault domain is the newer camera-selection/device-switch path, sidecar/provider session handling, or the newly introduced camera-device contract/signal integration.

The latest screenshot also showed a parse/load-time contract error around `camera_devices_changed`, which means the stack may be entering a broken state before or during the camera-switch workflow. This pass should therefore treat the entire camera-switch path as suspect: scene UI change handling, proving harness logic, provider contract wiring, sidecar restart/teardown, and mounted addon alignment on Byte.

This is a high-severity regression because it destabilizes the desktop session and invalidates earlier “working” conclusions. The next pass should prioritize safe diagnosis on Byte, isolate the exact trigger, and land the repair in the real owner repo(s) first, followed by canonical sync and Byte re-validation.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derrick screenshot showing the post-crash parse/load error in the proving project | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/21/image-bed40107.png` |
| `REF-02` | Prior visual-truth investigation plan for optimized overlay mismatch | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-20-optimized-overlay-visual-truth-pass.md` |
| `REF-03` | Real MediaPipe owner repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` |
| `REF-04` | Real input-core repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core` |
| `REF-05` | Consumer proving environment on Byte | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control` |
| `REF-06` | Canonical sync helper | `/home/derrick/.openclaw/workspace/scripts/godotenv-sync` |
| `REF-07` | Authorized direct Byte access path | `ssh byte` |

---

## Tasks

### Task 1: Investigate the Byte camera-switch crash and contract mismatch

**Bead ID:** `aerobeat-tool-camera-gesture-control-6rm`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Investigate the high-severity Byte regression where switching cameras in the Boxing proving scene crashes the session / breaks the proving environment, and where post-crash reload shows the `camera_devices_changed` parse/load error, against bead `aerobeat-tool-camera-gesture-control-6rm`. Claim it on start with `bd update aerobeat-tool-camera-gesture-control-6rm --status in_progress --json`. Treat Byte runtime behavior as the source of truth. Determine the exact trigger and whether the root cause is contract mismatch, mounted-addon misalignment, sidecar/provider session handling, camera-switch restart logic, or some combination. Use `ssh byte` as needed and produce a precise root-cause report plus fix plan.

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 2: Repair the real owner repo(s) and re-sync Byte cleanly

**Bead ID:** `aerobeat-input-mediapipe-python-bbs`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** After root cause is known, repair the regression in the real owner repo(s) first against bead `aerobeat-input-mediapipe-python-bbs`. Claim it on start in the real `aerobeat-input-mediapipe-python` repo. Fix the broken camera-switch/runtime/contract path, then refresh Byte and the consumer proving environment using the canonical `godotenv-sync` workflow. Do not patch `/addons/` clones as source of truth. This pass should prioritize implementation and clean Byte alignment; final safe end-to-end verification is intentionally deferred to Derrick's human test tomorrow.

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 3: QA and audit on Byte with actual camera switching

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `qa` / `auditor`)  
**Role:** `qa` / `auditor`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Verify the repaired behavior on Byte with the real user action: start the Boxing proving scene, switch from the native webcam to the Logitech webcam, and confirm the system remains stable and the camera actually switches. Also confirm the `camera_devices_changed` parse/load error is gone.

**Status:** ⏳ Pending

**Results:** Not started.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending investigation.

**Reference Check:** Pending investigation.

**Commits:**
- Pending

**Lessons Learned:** Pending investigation.

---

*Completed on Pending*
