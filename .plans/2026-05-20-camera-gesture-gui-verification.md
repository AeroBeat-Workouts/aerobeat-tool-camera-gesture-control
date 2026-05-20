# AeroBeat Camera Gesture GUI Verification

**Date:** 2026-05-20  
**Status:** In Progress  
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
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture/shot1.png`
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture/shot2.png`
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture/shot3.png`
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture/after_f8.png`
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture/after_close.png`
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture/x11_input.py`
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture/x11_wm_close.py`

**Status:** ❌ Failed

**Results:** Launched the real GUI editor against `/.testbed/project.godot`, confirmed the scene tab `camera_gesture_testbed.tscn`, and ran the testbed with the normal editor shortcut path (`F6`). Evidence screenshots were captured under `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture/`, including `shot2.png` (scene open in editor), `shot3.png` (running testbed in fake mode), `after_f8.png` (normal Stop Running Project path reached; debugger reports `--- Debugging process stopped ---`), and `after_close.png` (editor gone after graceful WM close). In fake mode, the observed UI was truthful: status `Ready`, input source `Fake`, tracking `active | confidence 1.00 / 0.45`, preview label `Source: Fake`, runtime `inactive`, zero translation at rest, and visible animated world motion consistent with the fake feed. The QA lane then hit a control-path blocker: on this host, keyboard injection into the Xwayland Godot editor was reliable enough for standard editor shortcuts (`F6`, `F8`, WM delete close), but not sufficient to truthfully drive the in-scene source dropdown/buttons for `mediapipe_live` and `mediapipe_replay`. Pointer warping/click attempts did not reliably actuate the Godot UI, and tab focus stayed trapped in the debug-toolbar layer rather than giving a dependable route to the source controls. Because Derrick explicitly forbade headless MediaPipe scene verification and the integrated headless-manager listener is headless-only, I did not substitute a headless or kill-based workaround. Result: safe stop/close behavior was verified for the GUI path, fake mode passed, but `mediapipe_live`, `mediapipe_replay`, clean mode switching, and exported GUI traces for forward/backward `translation.z` polarity remain unverified in this lane and need either manual in-person interaction or a more reliable GUI control path.

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

**Status:** ✅ Complete

**Results:** Auditor pass completed against the repo state, the sibling headless-manager source, the active `.testbed` files, and the captured GUI evidence under `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture/`. The coder claim is verified: `/.testbed/addons.jsonc` now mounts `aerobeat-tool-headless-manager`, `/.testbed/project.godot` now autoloads `AeroHeadlessManager`, and `/.testbed/tests/test_example.gd` truth-checks both the mounted autoload path and the consumed manager’s actual arming contract. The manager source in `REF-05` confirms the important limit directly: it only arms for `OS.is_debug_build()` plus `DisplayServer.get_name() == "headless"`, so this integration is real but does **not** provide GUI-session safe-close automation.

The QA claim is also partially verified by evidence. `shot3.png` shows the running fake-mode scene with truthful on-screen state (`Status: Ready`, `Input source: Fake`, active tracking, profile identity, and non-zero world motion/rotation), `after_f8.png` shows the editor after normal stop with `--- Debugging process stopped ---`, and `after_close.png` shows the editor gone after graceful close. The blocker claim is credible and consistent with the artifact set: the tab-navigation montage never reaches a state change away from fake mode, no GUI evidence shows `mediapipe_live` or `mediapipe_replay` actually selected/running, and no trace-export artifact was produced anywhere under `trace_exports/camera_gesture/`. So fake mode plus the safe stop/close path are proven, but live mode, replay mode, mode switching, and any replay-derived trace export remain unproven in this lane.

Verdict: **⚠️ Partially ready, but still blocked for the original full verification goal.** The integration work is ready and honest, and the GUI close path was used correctly. However, the lane is not ready to claim end-to-end GUI verification because the core live/replay interactions still require either manual in-person control by Derrick or a more reliable Godot GUI control path than the current Xwayland injection surface. `translation.z` polarity remains explicitly **unverified**: I found trace-capture scaffolding in source, but no exported trace manifest/frames proving forward/backward sign, and the fixture YAMLs themselves already say not to assume polarity before first real captured trace.

New manual GUI finding from Derrick after this audit: when the test was switched to recorded-video mode, playback failed to start and logged `camera_view.gd:205 @ _connect_with_retry(): Failed to connect, status: 3`. Derrick also requested a readability pass: increase the font size used in the test scene and widen the left-hand panel to compensate because the current text is too small to read. That turns the next slice into a concrete implementation follow-up rather than a pure control-path blocker.

---

---

### Task 5: Fix recorded-video replay startup and improve test-scene readability

**Bead ID:** `aerobeat-tool-camera-gesture-control-c97`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Investigate and fix the recorded-video replay startup failure observed during manual GUI testing, where switching to recorded video caused playback not to start and logged `camera_view.gd:205 @ _connect_with_retry(): Failed to connect, status: 3`. In the same slice, increase the font size used in the test scene and widen the left-hand panel enough to keep the larger text readable. Validate safely without violating the no-headless-MediaPipe rule, update this plan with actual results, commit/push by default, and close the bead only when the replay-start fix and readability pass are real.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`

**Files Created/Deleted/Modified:**
- `/.testbed/scripts/camera_gesture_testbed.gd`
- `/.testbed/tests/test_camera_gesture_testbed_scene.gd`

**Status:** ✅ Complete

**Results:** Root cause was a startup-timing bug in the testbed scene wiring, not a missing fixture path. `camera_gesture_testbed.gd` was treating `AutoStartManager.server_started` like “preview stream is ready,” but the donor manager emits that signal as soon as the detached sidecar process exists and only does its own stabilization wait afterward. The testbed was also scheduling camera-stream startup a second time after `await start_server()`, so replay mode could hit an early `_ensure_mediapipe_camera_stream()` call while the sidecar was still booting, burn through the first `MediaPipeCameraView.start_stream()` attempt into `camera_view.gd ... Failed to connect, status: 3`, and then drop the later ready-time attempt behind the camera-view start guard. The fix keeps scope in this repo: `_on_mediapipe_server_started()` now marks the runtime `stabilizing` but does **not** eagerly start the preview stream, leaving the post-`await start_server()` path to make the first real connection attempt after the manager’s built-in stabilization window.

In the same slice, the test scene readability was raised materially: the left panel is now wider (`split_offset=520`, minimum width `500`), title/section/status fonts are larger, and the left-panel controls inherit a larger readability theme so the YAML/source/trace surfaces are easier to read during manual QA. Added targeted GUT coverage in `/.testbed/tests/test_camera_gesture_testbed_scene.gd` for both the widened layout/larger title font and the replay-start timing guard. Safe validation stayed within Derrick’s rules: `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/camera_gesture_testbed.gd` passed, and `~/.local/bin/godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/test_camera_gesture_testbed_scene.gd -gexit` passed `6/6`. Important truth limit: this coder slice fixes the replay-start race in source and proves the intended behavior with repo-local tests, but it does **not** itself prove real GUI replay playback; Task 6 still needs the in-person runtime verification before anyone claims the `status: 3` symptom is fully gone in live use.

---

### Task 6: Verify recorded-video replay and readability after the fix

**Bead ID:** `aerobeat-tool-camera-gesture-control-t8b`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Verify the replay-start fix and readability pass in the real testbed. Confirm that recorded-video mode now starts playback instead of failing with `status: 3`, and that the larger font plus widened left-hand panel are genuinely easier to read in use. Preserve the Godot-safe start/stop/close rules, gather evidence, update this plan with actual results, and close the bead only when the follow-up result is truthful.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`
- `Potential screenshot/export evidence folders`

**Files Created/Deleted/Modified:**
- `Potential screenshots / trace exports / notes`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 7: Audit the replay-start/readability follow-up

**Bead ID:** `aerobeat-tool-camera-gesture-control-qiu`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Independently audit the replay-start fix and readability follow-up. Verify that the `status: 3` recorded-video failure is actually resolved or honestly narrowed, and that the UI readability adjustments are real rather than nominal. Update this plan with the verdict and close the bead only when the truth is clear.

**Folders Created/Deleted/Modified:**
- `None planned`

**Files Created/Deleted/Modified:**
- `Plan update / evidence references only`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** The camera-gesture `.testbed` now consumes `aerobeat-tool-headless-manager` through GodotEnv and autoloads it truthfully, with repo-local tests guarding that contract. The GUI verification lane also produced real evidence that fake mode runs, the normal Stop Running Project path reaches clean debugger teardown, and a graceful editor close succeeds after teardown.

**Reference Check:** `REF-02` and `REF-05` are satisfied for the integration truth: the consumer wiring is present and the headless-manager contract remains explicitly headless-only. `REF-03` is **not yet satisfied** for replay verification because no GUI evidence proves the prerecorded fixture path was actually selected and run. `REF-01` is only partially satisfied because the intended live/replay truth pass and the first real trace export still did not happen.

**Commits:**
- No new auditor commit; audited current working tree state and evidence only.

**Lessons Learned:** The safe-close improvement is worth keeping, but it does not remove the need for the normal GUI stop path because the current manager intentionally does not arm in windowed editor sessions. Also, the camera-gesture lane now has trace-export scaffolding ready, but any claim about forward/backward `translation.z` polarity must wait for a real exported trace from live or replay mode rather than screenshots or assumptions alone.

---

*Started on 2026-05-20*
