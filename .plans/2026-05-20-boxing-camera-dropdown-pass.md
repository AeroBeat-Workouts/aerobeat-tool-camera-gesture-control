# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-20  
**Status:** Draft  
**Agent:** Cookie 🍪

---

## Goal

Replace the Boxing and Flow proving scenes’ manual camera-source UX with matching auto-populated camera dropdowns that update the live preview/tracking feed, and remove the impractical `Camera Source` exported input from both Boxing and Flow proving scene scripts.

---

## Overview

Derrick wants the current Boxing scene to stop exposing a manual, empty `Camera Source` path/ID workflow to humans. Instead, the live camera proving UI should auto-detect camera options, present them in a dropdown above the preview panel in the top-left container, default to the currently active/default live camera, and restart/update the feed when a different camera is selected. The “Live camera default …” text line should be removed as part of that cleanup.

Flow should receive the same camera dropdown treatment in the same preview-area location with the same rules and layout/positioning as Boxing. This is meant to become the standard proving-scene live-camera UX, not a Boxing-only special case.

This pass also removes the `Camera Source` exported public variable from both the Boxing and Flow proving scene scripts, because it is not a practical human-facing control. The camera chooser should now live in-scene. When a prerecorded video source is set in the editor, the camera-selection UI should be hidden so the scene clearly communicates that the camera picker is not relevant in prerecorded mode.

This work must follow the repo ownership rules already established: the real behavior belongs in the owning source repos, not by hand-editing mirrored `/addons/` copies as the source of truth. If the Boxing/Flow proving scripts and scenes being changed are housed in the real `aerobeat-input-mediapipe-python` repo, land the durable changes there first, then refresh the consumer tool repo through the normal GodotEnv/addon flow and verify the mounted scene behavior there.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derrick screenshot showing the Boxing scene area where the dropdown should replace current camera-source UX | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/20/image-11dab123.png` |
| `REF-02` | Base proving harness script with current exported `camera_source` variable and camera-source summary logic | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-03` | Boxing proving harness specialization | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons/aerobeat-input-mediapipe-python/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-04` | Boxing proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn` |
| `REF-05` | Flow proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons/aerobeat-input-mediapipe-python/.testbed/scenes/flow_proving.tscn` |
| `REF-06` | Real provider-side camera-selection contract already landed in input-core / mediapipe-python | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/interfaces/input_provider.gd` |
| `REF-07` | Real MediaPipe provider/harness source repo that should own durable proving-scene edits before consumer refresh | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` |

---

## Tasks

### Task 1: Implement Boxing camera dropdown + remove exported camera-source field

**Bead ID:** `aerobeat-tool-camera-gesture-control-4uk` + `aerobeat-input-mediapipe-python-ss0`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Implement the 2026-05-20 Boxing/Flow camera dropdown pass in the owning repo(s). Claim coordination bead `aerobeat-tool-camera-gesture-control-4uk` and implementation bead `aerobeat-input-mediapipe-python-ss0` on start in their respective repos. Replace the current Boxing scene’s manual camera-source UX with an auto-populated dropdown shown above the camera feed in the top-left container. Flow should receive the same dropdown in the same preview-area location with matching rules and layout/positioning. Remove the `Live camera default ...` text line. The dropdown should default to the current/default live camera, populate from detected camera options, and when a new camera is selected it should update/restart the live preview + tracking feed to use the newly selected camera. Remove the `Camera Source` exported public variable from both BoxingProving and FlowProving scene scripts. When a prerecorded video source is set in the editor, hide the camera-selection UI in the scene. Land durable source changes in the real `aerobeat-input-mediapipe-python` repo first, then refresh the consumer tool repo through GodotEnv/addon flow and verify there. Commit/push by default and leave a concise handoff.

**Folders Created/Deleted/Modified:**
- real `aerobeat-input-mediapipe-python/.testbed/scripts/`
- real `aerobeat-input-mediapipe-python/.testbed/scenes/`
- consumer `aerobeat-tool-camera-gesture-control/.testbed/` via addon refresh only as needed

**Files Created/Deleted/Modified:**
- real proving harness / boxing harness / flow harness scripts as needed
- real boxing/flow proving scenes as needed
- tests/validation helpers if needed

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 2: QA Boxing dropdown behavior and prerecorded hide/show rules

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** QA the Boxing/Flow camera dropdown pass after coder handoff. Claim the assigned bead on start. Verify in the highest-fidelity path available that both the Boxing and Flow proving scenes show an auto-populated camera dropdown above the preview in the same location/layout, default to the current/default live camera, update the preview/tracking feed when a different camera is selected, remove the `Live camera default ...` text line, and hide the camera selector when prerecorded video mode is active. Also confirm the `Camera Source` exported public variable is gone from both BoxingProving and FlowProving scene scripts.

**Folders Created/Deleted/Modified:**
- QA evidence only if needed

**Files Created/Deleted/Modified:**
- none expected unless evidence is added

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 3: Audit the dropdown pass

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Audit the Boxing/Flow camera dropdown pass after QA. Claim the assigned bead on start. Independently truth-check that the camera dropdown is now the correct live-camera UX for both Boxing and Flow with matching placement/behavior, that manual exported camera-source fields were removed from Boxing/Flow proving scripts, and that prerecorded mode hides the camera picker as specified. Confirm the work was landed in the real owning repo first and consumed through normal addon refresh, not by treating mirrored consumer copies as source of truth.

**Folders Created/Deleted/Modified:**
- repo inspection only

**Files Created/Deleted/Modified:**
- none expected unless audit evidence is added

**Status:** ⏳ Pending

**Results:** Not started.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending execution.

**Reference Check:** Pending execution.

**Commits:**
- Pending

**Lessons Learned:** Pending execution.

---

*Completed on Pending*
