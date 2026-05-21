# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-20  
**Status:** Draft  
**Agent:** Cookie 🍪

---

## Goal

Improve MediaPipe proving-scene performance on Byte by reducing camera/overlay/gesture-processing overhead while preserving enough fidelity for real testing.

---

## Overview

Derrick’s latest hands-on test on Byte found that the MediaPipe video feed is currently too slow to be usable for real testing. The likely performance buckets are: camera/preview resolution, landmark overlay draw cost, and per-frame gesture-processing cost. This pass should start by measuring the current pipeline cadence and then make targeted reductions where they matter most.

The current codepaths suggest the pipeline is fairly aggressive by default: the Python side is set up for 640x480 capture, 60 max FPS, full-pose landmark extraction/filtering, and 30 FPS MJPEG preview publishing, while the Godot camera view also updates on a ~33 ms interval. Gesture state evaluation appears to run on every received pose packet rather than on a slower sampled cadence. That makes Derrick’s intuition plausible: we may be paying for both constant pose processing and constant overlay/UI updates.

Derrick has now made an explicit prioritization decision for the first implementation pass: tackle overlay-cost reduction and gesture-evaluation throttling first, before any downres/preprocess-size work. The reasoning is sound: downresing itself can cost CPU time, so we should first remove obviously non-essential work such as drawing full landmark constellations when only a head indicator may be needed, and calculating gesture state every single update if a lower sampled cadence preserves usability. The approved tracking/overlay mode surface for this pass is: `off` (no tracking dots, video only), `full` (current full behavior), and `optimized` (keep arms/legs/core tracking, but reduce the head landmark set itself to only left eye, right eye, and a central head point/nose so head position/rotation remain derivable without extra facial landmarks like mouth/eyebrows).

A second parallel product requirement also needs to be designed into the broader MediaPipe/input stack: camera/webcam selection. This contract belongs in the real input-core repo at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core`, not in a repo-local `/addons/` copy. Both the current `aerobeat-input-mediapipe-python` implementation and a future `aerobeat-input-mediapipe-native` implementation on Android/iOS should eventually expose available cameras and allow AeroBeat UI to select the correct device instead of assuming camera index 0. The correct workflow for this slice is therefore: land contract changes in the real input-core repo first, commit/push there, then pull those changes into the consuming MediaPipe/tool repo(s) via the normal GodotEnv/addon update flow.

This pass should preserve the current proving-harness functionality while finding a more practical default for lower-power hardware like Byte. If measurement shows one dominant bottleneck, the plan should be updated to reflect that rather than blindly applying all three optimizations at once.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Python MediaPipe runtime loop and frame-processing cadence | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/main.py` |
| `REF-02` | Python runtime CLI defaults for FPS / resolution / preprocess size | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/args.py` |
| `REF-03` | MJPEG preview streaming cadence/quality defaults | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/camera_streamer.py` |
| `REF-04` | Godot proving harness update cadence | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-05` | Godot camera-view refresh cadence | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons/aerobeat-input-mediapipe-python/src/camera_view.gd` |
| `REF-06` | Godot landmark overlay drawing path | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons/aerobeat-input-mediapipe-python/.testbed/scripts/landmark_drawer.gd` |
| `REF-07` | Detector substrate / gesture-evaluation path | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons/aerobeat-input-mediapipe-python/src/detectors/pose_detector_substrate.gd` |
| `REF-08` | Input provider contract surface likely to grow camera-selection support | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons/aerobeat-input-mediapipe-python/src/input_provider.gd` |

---

## Tasks

### Task 1: Measure current cadence and lock the first optimization order

**Bead ID:** `aerobeat-tool-camera-gesture-control-cl7`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Inspect the current MediaPipe proving-scene pipeline and document the actual update cadence and likely bottlenecks on Byte against coordination bead `aerobeat-tool-camera-gesture-control-cl7`. Claim it on start with `bd update aerobeat-tool-camera-gesture-control-cl7 --status in_progress --json`. Specifically answer: capture/inference resolution, max processed FPS, MJPEG preview FPS, Godot camera-view refresh cadence, overlay draw cadence, and how often gesture calculations run. Derrick has already prioritized the first implementation pass order as B then C: reduce overlay cost first and gesture-evaluation frequency second, before any downres/preprocess-size work. Validate whether that order is technically sound and identify the concrete codepaths/settings to change first. Also sketch the smallest viable contract shape for future webcam selection support so the implementation pass does not paint us into a corner.

**Folders Created/Deleted/Modified:**
- none expected

**Files Created/Deleted/Modified:**
- plan only unless evidence notes are added

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 2: Implement Byte-first overlay + gesture cadence performance pass

**Bead ID:** `aerobeat-input-core-3az` + `aerobeat-input-mediapipe-python-wu2`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** After the measurement pass, implement the first MediaPipe proving-scene performance pass in the owning repo(s) using Derrick’s chosen order: (B) reduce overlay landmark draw cost first, then (C) reduce gesture-evaluation frequency/cadence where safe. Use the real repo beads `aerobeat-input-core-3az` and `aerobeat-input-mediapipe-python-wu2`; claim the relevant bead in each repo on start. Preserve proving-scene usefulness and document the final cadence/settings. Do not start with downres/preprocess-size changes unless measurement proves B/C are insufficient or clearly not the bottleneck. Implement the approved tracking/overlay modes exactly as: `off` (no tracking dots, video only), `full` (current full behavior), and `optimized` (keep arms/legs/core tracking, but reduce the head landmark set itself to only left eye, right eye, and a central head point/nose; remove extra face points like mouth/eyebrows). Also expose camera selection as a public variable near the top of both boxing and flow scene root scripts, matching the style of the other public variables. In the same slice, add the initial cross-repo contract/design groundwork for webcam selection so the stack can expose available cameras and a selected camera identity instead of assuming index 0. The contract work must happen in the real input-core repo at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core`, be committed/pushed there, and only then be consumed in `aerobeat-input-mediapipe-python` via the normal GodotEnv/addon update flow. Do not treat repo-local `/addons/` copies as the source of truth for contract edits.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/` (real contract owner)
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/` (real provider/runtime owner)
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/` (consuming proving harness)
- never treat repo-local `/addons/` copies as the source of truth for contract edits

**Files Created/Deleted/Modified:**
- repo-dependent; likely input-core contract/interface files first, then provider/harness/runtime integration files in the owning repos, followed by GodotEnv/addon refresh in consumers

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 3: QA and audit the performance + webcam-contract pass

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `qa` / `auditor`)  
**Role:** `qa` / `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Verify the performance pass on the highest-fidelity path available, confirm the feed is materially more usable on lower-power hardware, and independently truth-check that the chosen overlay/gesture-cadence optimization did not break proving-scene behavior. Also confirm the new webcam-selection contract/design changes are coherent and actually move the stack toward provider-agnostic camera selection for future native implementations.

**Folders Created/Deleted/Modified:**
- QA evidence only if needed

**Files Created/Deleted/Modified:**
- none expected unless evidence is added

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
