# AeroBeat Camera Gesture GUI Verification

**Date:** 2026-05-20  
**Status:** Draft  
**Agent:** Byte 🐈‍⬛

---

## Goal

Sync `aerobeat-tool-headless-manager` into the relevant AeroBeat projects, wire it into the camera-gesture `.testbed` project as a GodotEnv dependency + autoload singleton, and then perform the in-person Godot editor GUI verification pass with the safe close path in place.

---

## Overview

The code-side live/replay hookup landed yesterday, along with the candidate fixture videos and first-pass timing windows. Derrick has now added an important new prerequisite: `aerobeat-tool-headless-manager` must be synced into the AeroBeat repos, and in `aerobeat-tool-camera-gesture-control` it must be installed into `/.testbed/` via GodotEnv and wired into the test scene as an autoload singleton. That singleton exposes the listener that lets me and spawned subagents close a Godot dev test cleanly, which matters here because MediaPipe teardown has been causing OS-level crash risk when the project is closed the wrong way.

So this continuation now has two phases. First, land the headless-manager dependency/autoload integration needed for safe dev-test shutdown in the camera-gesture testbed. Second, do the real GUI verification pass through the Godot editor with normal human-style start/stop and the new safe-close path in place. The verification still needs to confirm that `mediapipe_live` truthfully drives preview/status/motion, that `mediapipe_replay` truthfully drives from the recorded clips and sidecars, and that switching between `fake`, `mediapipe_live`, and `mediapipe_replay` is clean and honestly reported. If the runtime looks sound, we should gather enough exported-trace evidence to answer the highest-priority follow-up question about forward/backward `translation.z` polarity. If anything fails, the result should be a precise bug list tied to the observed GUI behavior.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Prior hookup-fix plan / current handoff truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-19-camera-gesture-replay-hookup-fix.md` |
| `REF-02` | Camera gesture repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control` |
| `REF-03` | Candidate fixture videos + YAML sidecars | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/assets/fixtures/camera_gesture/head_pose/candidates/` |
| `REF-04` | Desktop-control skill / screenshot-first GUI workflow | `/home/derrick/.openclaw/workspace/skills/desktop-control/SKILL.md` |
| `REF-05` | Headless-manager repo that provides safe dev-test close listener | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-headless-manager` |

---

## Tasks

### Task 1: Preflight the headless-manager + GUI verification path

**Bead ID:** `aerobeat-tool-camera-gesture-control-d6t`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`  
**Prompt:** Preflight the AeroBeat camera-gesture verification lane. Confirm the owning repo state, inspect how `aerobeat-tool-headless-manager` should be synced and consumed, locate the Godot testbed entrypoint, inspect the local desktop/session control path, and produce the safest concrete procedure that honors Derrick’s “no headless MediaPipe verification” rule while using the new safe-close listener. Claim the bead on start and close it when the runbook is crisp.

**Folders Created/Deleted/Modified:**
- `None planned`

**Files Created/Deleted/Modified:**
- `Potential notes only`

**Status:** ✅ Complete

**Results:** Preflight confirmed the testbed entrypoint at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/project.godot` with `run/main_scene="res://scenes/camera_gesture_testbed.tscn"` and scene script `scripts/camera_gesture_testbed.gd`. It also confirmed that `/.testbed/addons.jsonc` does not yet include `aerobeat-tool-headless-manager`. The sibling headless-manager repo is now present locally at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-headless-manager`, and its consumer contract is clear from `README.md`: add the GodotEnv manifest entry and autoload `AeroHeadlessManager="*res://addons/aerobeat-tool-headless-manager/src/AeroHeadlessManager.gd"`. Critical truth: the current listener is headless-only by design (`OS.is_debug_build() and DisplayServer.get_name() == "headless"`) and therefore will not arm during the required GUI editor verification pass. So we should still integrate it honestly, but the safe-close path for GUI verification remains: Stop Running Project first, wait for teardown, then close the editor gracefully; do not use PID kills, helper kills, ad-hoc terminate shortcuts, or `xdotool windowclose`.

---

### Task 2: Sync and integrate the headless-manager safe-close path

**Bead ID:** `aerobeat-tool-camera-gesture-control-plv`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-05`  
**Prompt:** Sync `aerobeat-tool-headless-manager` into the relevant AeroBeat project state, then add it to `aerobeat-tool-camera-gesture-control/.testbed/` as a GodotEnv dependency and wire it into the testing scene as an autoload singleton. Confirm the listener contract truthfully: integrate it as designed, but do not overclaim GUI-safe-close behavior if it only arms in headless mode. Document the exact close path that me and future subagents should use for GUI verification: Stop Running Project first, wait for teardown, then close the editor gracefully. Claim the bead on start, validate, commit/push, and close only when the integration is real.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`
- `Potential GodotEnv-managed addon/dependency paths`

**Files Created/Deleted/Modified:**
- `GodotEnv manifests / lockfiles as needed`
- `Project settings / autoload config as needed`
- `Testing scene integration files as needed`

**Status:** ✅ Complete

**Results:** Integrated `aerobeat-tool-headless-manager` into the hidden `.testbed` consumer contract by adding the GodotEnv dependency in `/.testbed/addons.jsonc`, wiring the autoload in `/.testbed/project.godot`, and ignoring the project-local sentinel folder at `/.testbed/.headless/`. Added a repo-local guard in `/.testbed/tests/test_example.gd` so validation now checks both the mounted addon manifest entry and the exact autoload path, while also truth-checking that the consumed manager still contains the headless-only arming contract (`OS.is_debug_build()` plus `DisplayServer.get_name() == "headless"`). Restored addons from inside `/.testbed/` with `godotenv addons install`; a stale generated `.uid` inside the ignored `/.testbed/addons/aerobeat-input-core/` mirror initially blocked reinstall, so that generated artifact was discarded and the restore rerun successfully. Safe validation stayed non-destructive and avoided headless MediaPipe scene verification: `godot --headless --path .testbed --import` completed successfully, and `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/test_example.gd -gexit` passed `5/5`. Important truth for Task 3: this integration does **not** prove GUI-safe-close behavior, because the current listener only arms in debug headless runtime sessions; for GUI verification the required close path remains Stop Running Project first, wait for teardown, then close the editor gracefully.

---

### Task 3: Run the GUI verification pass in the Godot editor

**Bead ID:** `aerobeat-tool-camera-gesture-control-g8j`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Using the safe GUI path and the integrated headless-manager listener, open the camera-gesture testbed in the Godot editor and perform the in-person verification pass. Verify `fake`, `mediapipe_live`, and `mediapipe_replay`; confirm preview/status/motion truthfulness; test mode switching; verify the safe close behavior is used correctly; and gather the best available evidence about forward/backward `translation.z` polarity from exported traces. Claim the bead on start and close it only when the result is either a passing QA report or a precise failure report with evidence.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`
- `Potential export/debug artifact folders if the scene writes them`

**Files Created/Deleted/Modified:**
- `Potential trace exports / screenshots / notes`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit the truth of the integration + verification result and decide next action

**Bead ID:** `aerobeat-tool-camera-gesture-control-x9g`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`  
**Prompt:** Independently audit the headless-manager integration and the GUI verification evidence. Decide whether the camera-gesture testbed is genuinely ready, partially ready with explicit follow-up work, or still blocked. Check that the safe close path is truly wired and that any `translation.z` conclusion is supported by trace evidence rather than assumption. Claim the bead on start and close it when the verdict is justified.

**Folders Created/Deleted/Modified:**
- `None planned`

**Files Created/Deleted/Modified:**
- `Plan update / evidence references only`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Started on 2026-05-20*
