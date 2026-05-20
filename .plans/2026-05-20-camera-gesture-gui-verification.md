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
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture-t6/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture-t6/shot_editor_open.png`
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture-t6/shot_editor_loaded.png`
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture-t6/shot_running_fake.png`
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture-t6/shot_scrolled1.png`
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture-t6/harness_running_replay.png`
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture-t6/harness_after_f8.png`
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture-t6/after_stop_before_harness.png`
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture-t6/after_editor_close_for_harness.png`
- `/home/derrick/.openclaw/workspace/.temp/qa-camera-gesture-t6/harness_after_close.png`

**Status:** ❌ Failed

**Results:** Real GUI verification did **not** confirm the replay-start fix. I reran the normal editor path in fake mode and captured `shot_running_fake.png`, which shows the widened left panel and larger section/status text in use; compared with the earlier `/.temp/qa-camera-gesture/shot3.png`, the UI is materially easier to read because the source/runtime section is no longer cramped and the status/profile text is legible without zooming. I then scrolled the live testbed UI far enough to expose the `Source + fixture runtime` controls and confirmed the replay controls are present in the real scene via `shot_scrolled1.png`, but reliable dropdown actuation through the current GUI-control lane remained flaky enough that I could not truthfully claim a manual in-scene selection.

To keep the verification honest while still using the real GUI/editor path, I stopped the run with **F8**, closed the editor gracefully, temporarily changed only the local startup default from `fake` to `mediapipe_replay`, relaunched the editor, and reran the scene normally with **F6**. That produced direct GUI evidence in `harness_running_replay.png`: the scene came up as **`Input source: MediaPipe replay`**, but the status was **`Failed to start MediaPipe replay runtime`** and the right-hand preview reported **`Runtime: failed`**, so replay playback still did not start. The debugger/output evidence in `harness_after_f8.png` plus the captured editor log show the root symptom is still present: `ERROR: Failed to connect, status: 3` from `res://addons/aerobeat-input-mediapipe-python/src/camera_view.gd:205 @ _connect_with_retry()`. The same run also surfaced a more specific blocker before that connection failure: AutoStartManager reported a missing sidecar runtime manifest, sentinel, and Python executable under `/.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/`, so this lane is blocked before replay can become healthy.

Safe-stop/close rules were preserved throughout. The temporary startup-default harness change was reverted before finishing. Truthful QA verdict: readability improved in practice, but recorded-video replay still fails to start and the `status: 3` symptom still appears in a real GUI run.

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

---

### Task 8: Repair Linux python sidecar runtime provisioning for replay

**Bead ID:** `aerobeat-tool-camera-gesture-control-5e8`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`  
**Prompt:** Repair the Linux python sidecar runtime provisioning/state used by the mounted `aerobeat-input-mediapipe-python` addon so recorded-video replay can actually boot from the camera-gesture `.testbed`. Treat the current QA evidence as source truth: runtime manifest / sentinel / python executable are missing under the mounted addon runtime path, and replay still fails with `camera_view.gd:205 @ _connect_with_retry(): Failed to connect, status: 3`. Fix the provisioning path honestly, validate safely without violating the no-headless-MediaPipe rule, update this plan with actual results, commit/push by default, and close the bead only when the provisioning repair is real.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons.jsonc`
- `Mounted addon/runtime state refreshed via GodotEnv reinstall and owning-repo runtime prep`

**Status:** ✅ Complete

**Results:** Root cause was consumer-side provisioning drift, not a missing source-side runtime build step. The camera-gesture `.testbed` was mounting `aerobeat-input-mediapipe-python` as a fresh remote Git checkout via `/.testbed/addons.jsonc`, but the Linux sidecar runtime contract is intentionally local and gitignored (`python_mediapipe/assets/runtimes/linux-x64/`). That meant the mounted addon could never contain the required `runtime-manifest.json`, `.runtime-ready`, or `venv/bin/python`, which matches the QA evidence exactly and explains why replay still fell through to `camera_view.gd:205 @ _connect_with_retry(): Failed to connect, status: 3`.

The honest fix stayed out of generated mirrors. In the consumer repo, `/.testbed/addons.jsonc` now resolves `aerobeat-input-mediapipe-python` from the local sibling repo `../../aerobeat-input-mediapipe-python` with `source: "symlink"`, so the mounted addon sees the owning repo’s prepared runtime state instead of an impossible-to-hydrate remote checkout. In the owning source repo, I refreshed the real Linux runtime contract with `python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --install-requirements --validate --json`, which reported `validation_status: "ready"` and zero validation errors. Then in the consumer repo I removed the stale generated addon/cache copies and reran `cd .testbed && godotenv addons install`; the refreshed mount is now a symlink to `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python`.

Safe non-headless-MediaPipe validation only: verified from the mounted consumer path that `python_mediapipe/assets/runtimes/linux-x64/runtime-manifest.json`, `.runtime-ready`, and `venv/bin/python` all exist again, reran `python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --validate --json` from the mounted addon path with zero validation errors, and confirmed the mounted runtime interpreter can import `mediapipe`, `cv2`, and `numpy`. Important truth boundary: this coder slice repairs the real provisioning path and removes the missing-runtime blocker, but it does **not** itself claim that GUI replay has been re-verified end-to-end; Task 9 still owns the in-editor replay proof.

---

### Task 9: Verify replay boot after Linux sidecar runtime repair

**Bead ID:** `aerobeat-tool-camera-gesture-control-nue`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Verify in the real Godot editor that recorded-video replay now boots after the Linux python sidecar runtime repair. Confirm whether the `status: 3` failure is gone, whether runtime state becomes healthy, and whether replay actually starts. Preserve the Godot-safe start/stop/close rules, gather evidence, update this plan with actual results, and close the bead only when the result is truthful.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`
- `Potential screenshot/export evidence folders`

**Files Created/Deleted/Modified:**
- `Potential screenshots / trace exports / notes`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 10: Audit the Linux sidecar runtime repair follow-up

**Bead ID:** `aerobeat-tool-camera-gesture-control-rdl`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`  
**Prompt:** Independently audit the Linux python sidecar runtime repair and replay follow-up. Verify whether replay boot is genuinely fixed or honestly narrowed further, and record the exact remaining blocker if it still fails. Update this plan with the verdict and close the bead only when the truth is clear.

**Folders Created/Deleted/Modified:**
- `None planned`

**Files Created/Deleted/Modified:**
- `Plan update / evidence references only`

**Status:** ⏳ Pending

**Results:** Pending.

---

---

### Task 11: Restore the addon-local runtime install flow and remove the bad mount workaround

**Bead ID:** `aerobeat-tool-camera-gesture-control-5ez`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`  
**Prompt:** Fix the replay-runtime regression the right way: use the addon/runtime install script or documented local runtime preparation flow so the gitignored Linux sidecar files are installed locally within the addon workflow, and undo the incorrect consumer-mount workaround if it changed the intended contract. Treat Derrick’s correction as source truth: the right fix is addon-local runtime install, not consumer mount strategy drift. Validate safely without violating the no-headless-MediaPipe rule, update this plan with actual results, commit/push by default in the owning repo(s), and close the bead only when the intended runtime-install path is restored honestly.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/`

**Files Created/Deleted/Modified:**
- `Addon/runtime install config or docs as needed`
- `Consumer addon manifest refresh if needed`
- `Repo-local tests / notes as needed`

**Status:** ✅ Complete

**Results:** Derrick’s correction was right: the durable source repos did not need a new consumer mount contract. The bad workaround was the `1987f4a` consumer manifest drift that changed `/.testbed/addons.jsonc` from the normal Git-sourced `aerobeat-input-mediapipe-python` addon to a local sibling-repo symlink. I restored the intended consumer contract by reverting that manifest entry back to `git@github.com:AeroBeat-Workouts/aerobeat-input-mediapipe-python.git` on `main`, then refreshed the consumer cleanly with `cd .testbed && rm -rf addons/aerobeat-input-mediapipe-python .addons/aerobeat-input-mediapipe-python && godotenv addons install`.

The real repair used the addon’s existing documented local runtime-preparation flow, not new source changes in the addon repo: from the installed addon path at `/.testbed/addons/aerobeat-input-mediapipe-python/`, I ran `python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --install-requirements --validate --json`. That created the mounted addon-local Linux runtime in `python_mediapipe/assets/runtimes/linux-x64/` with a ready manifest, sentinel, and `venv/bin/python`, all inside the addon workflow where the replay path expects them. Validation stayed non-headless-MediaPipe: the prep command returned `validation_status: "ready"` with zero validation errors, the mounted runtime files now exist under the consumer addon path, and the mounted runtime interpreter successfully imported `mediapipe`, `cv2`, and `numpy`.

Important truth boundary: no durable source edit was needed in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python`; the correct fix there was to use the already-documented runtime prep flow honestly. The only durable code/config change in this slice was undoing the incorrect consumer workaround so the intended contract is restored. GUI replay itself is still unclaimed here; Task 12 still owns the real editor verification.

---

### Task 12: Verify replay boot after restoring addon-local runtime install

**Bead ID:** `aerobeat-tool-camera-gesture-control-k1y`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Verify in the real Godot editor that recorded-video replay boots after the addon-local runtime install flow is restored. Confirm whether the `status: 3` failure is gone, whether runtime state becomes healthy, and whether replay actually starts. Preserve the Godot-safe start/stop/close rules, gather evidence, update this plan with actual results, and close the bead only when the result is truthful.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`
- `Potential screenshot/export evidence folders`

**Files Created/Deleted/Modified:**
- `Potential screenshots / trace exports / notes`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 13: Audit the addon-local runtime install restoration

**Bead ID:** `aerobeat-tool-camera-gesture-control-6vt`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`  
**Prompt:** Independently audit the restored addon-local runtime install flow and replay follow-up. Verify whether the regression is genuinely fixed or honestly narrowed further, and record the exact remaining blocker if replay still fails. Update this plan with the verdict and close the bead only when the truth is clear.

**Folders Created/Deleted/Modified:**
- `None planned`

**Files Created/Deleted/Modified:**
- `Plan update / evidence references only`

**Status:** ⏳ Pending

**Results:** Pending.

---

---

### Task 14: Fix open warnings, restore usable testbed layout, and re-debug live/replay startup

**Bead ID:** `aerobeat-tool-camera-gesture-control-b0b`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Fix the newly reported regressions in the camera-gesture testbed. Address the project-open warnings shown in Derrick’s screenshot, repair the test-scene layout so the UI remains readable without hiding critical controls/previews (including the world preview and tracking/minimap preview texture), and continue debugging the remaining live/replay startup failure that still hits `camera_view.gd:205 @ _connect_with_retry(): Failed to connect, status: 3`. Treat Derrick’s manual report and screenshots as source truth, validate safely without violating the no-headless-MediaPipe rule, update this plan with actual results, commit/push by default, and close the bead only when the source-side fixes are real.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`

**Files Created/Deleted/Modified:**
- `Scene/layout scripts and resources as needed`
- `Runtime/startup scripts as needed`
- `Repo-local tests as needed`

**Status:** ✅ Complete

**Results:** Fixed the newly reported source-side regressions without overclaiming GUI runtime success. The project-open warnings were caused by local variable names shadowing `Control` / `CanvasItem` members (`position`, `rotation`, `material`) in the rebuilt harness scripts; those were renamed in `tracking_inset_overlay.gd`, `camera_gesture_testbed.gd`, and the controller helper. The readability regression came from overcorrecting the left-column expansion and preview sizing: the previous pass forced a `520` split with a `500px` minimum left panel, kept the preview stack demanding full-HD minimum layout space, left the debug tabs too tall, and parked the media inset on top of the main preview. The layout is now rebalanced to keep the larger fonts but restore usable surfaces: left split `440`, left minimum width `420`, preview stack minimum `960×540`, debug tabs reduced to `220px`, and the tracking/media inset moved to the bottom-right with explicit `TextureRect` expand/stretch settings so the preview texture stays visible.

I also narrowed the remaining `camera_view.gd:205 ... Failed to connect, status: 3` failure to a real source-side addon bug plus a local runtime-state prerequisite. In `aerobeat-input-mediapipe-python/src/runtime/desktop_sidecar_runtime.gd`, runtime validation was resolving `model_assets[].relative_path` against `res://../...` (consumer project root) instead of the mounted addon package root, which falsely reported the required pose-landmarker assets as missing and blocked startup before the stream could ever become healthy. The durable fix now resolves those model assets through `resolve_package_path(owner_script_path, relative_path)`. Safe validation stayed inside Derrick’s rule set: `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/camera_gesture_testbed.gd` passed, `~/.local/bin/godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/test_camera_gesture_testbed_scene.gd -gexit` passed `6/6`, and a direct non-scene runtime-contract probe against the mounted addon now returns `{"valid":true}` after restoring the documented addon-local Linux runtime with `python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --install-requirements --validate --json`. Important truth boundary: this coder slice fixes the warning/layout regressions and removes the false "missing model asset" startup blocker in source, but it does **not** itself prove that real GUI live/replay no longer hit `status: 3`; Task 15 remains the required manual QA proof.

---

### Task 15: Verify the repaired layout and live/replay behavior in the real editor

**Bead ID:** `aerobeat-tool-camera-gesture-control-8kh`  
**SubAgent:** `Manual / Derrick`  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Derrick will verify in the real Godot editor that the camera-gesture testbed layout is usable again and that critical surfaces are visible on-screen, including the world preview and the tracking/minimap preview texture. Derrick will also verify whether live/replay still hit `status: 3` or now boot correctly, using the existing Godot-safe start/stop/close rules.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`
- `Potential screenshot/export evidence folders`

**Files Created/Deleted/Modified:**
- `Potential screenshots / notes / trace exports`

**Status:** ⏸️ Deferred to Derrick

**Results:** QA intentionally skipped by request; Derrick will handle this phase manually.

---

### Task 16: Audit the warning/layout/runtime follow-up

**Bead ID:** `aerobeat-tool-camera-gesture-control-sh9`  
**SubAgent:** `Manual / Derrick`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Derrick will handle the final truth check on the warning/layout/runtime follow-up after manual verification.

**Folders Created/Deleted/Modified:**
- `None planned`

**Files Created/Deleted/Modified:**
- `Plan update / evidence references only`

**Status:** ⏸️ Deferred to Derrick

**Results:** Audit intentionally skipped by request; Derrick will handle this phase manually.

---

### Task 17: Rework the testbed UI structure for responsive 16:9 use and reduce font pressure slightly

**Bead ID:** `aerobeat-tool-camera-gesture-control-msg`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Incorporate Derrick’s latest manual feedback into the camera-gesture testbed. Slightly decrease font size across the panels, rebuild the UI to fit a 16:9 test surface responsively using proper anchors/containers instead of letting major regions fall off-screen, and prefer defining the UI as subnodes under `CameraGestureTestbed` in the scene hierarchy rather than spawning the whole interface from code if that is the cleaner/safer route. Preserve important surfaces on-screen at once, especially the world preview and the tracking/minimap replay preview texture. Continue treating QA/audit as Derrick-handled for this session, validate safely without violating the no-headless-MediaPipe rule, update this plan with actual results, commit/push by default, and close the bead only when the source-side UI rework is real.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`

**Files Created/Deleted/Modified:**
- `/.testbed/scenes/camera_gesture_testbed.tscn`
- `/.testbed/scripts/camera_gesture_testbed.gd`
- `/.testbed/tests/test_camera_gesture_testbed_scene.gd`

**Status:** ✅ Complete

**Results:** Reworked the harness UI around a scene-defined responsive scaffold instead of spawning the whole interface from code. `/.testbed/scenes/camera_gesture_testbed.tscn` now owns the major 16:9 layout structure under `CameraGestureTestbed`: a margin-wrapped root split, a scrollable left workflow column, a right preview column, a bottom-right tracking/media inset, and persistent debug tabs. `camera_gesture_testbed.gd` now binds/populates those scene subnodes instead of constructing the entire shell procedurally, which makes the anchors/containers explicit and safer to maintain.

Font pressure was reduced slightly rather than increased: left-panel body text dropped to `15`, input text to `14`, status rows to `16`, section titles to `18`, the scene title to `26`, preview title to `22`, and media inset title to `18`. The responsive sizing was also rebalanced for a 16:9 test surface: left split `360`, left minimum width `340`, preview minimum `640×360`, media inset `280×184`, camera-feed minimum height `132`, and debug tabs minimum height `180`. That keeps the world preview and tracking/minimap replay preview texture on-screen together instead of letting the left rail and inset crowd them off the surface.

Safe validation stayed within Derrick’s no-headless-MediaPipe rule: `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/camera_gesture_testbed.gd` passed, and `~/.local/bin/godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/test_camera_gesture_testbed_scene.gd -gexit` passed `6/6` after updating the scene-layout assertions to the new responsive scaffold. Important truth boundary: this coder slice proves the source-side responsive UI rework and scene-structure migration are real, but Derrick still owns the final manual runtime truth-check for on-screen fit and live/replay behavior in the real editor.

---

---

### Task 18: Add direct scene margins around debug-tab text surfaces

**Bead ID:** `aerobeat-tool-camera-gesture-control-64j`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`  
**Prompt:** Add margin around the bottom-right debug-tab text surfaces directly in the scene hierarchy rather than procedurally. Follow the same direction Derrick is already taking with manual hierarchy edits: wrap the debug-tab `RichTextLabel` surfaces in scene-authored `MarginContainer` nodes so the text has inset spacing similar to the left sidebar sections. Keep the change narrow, respect any recent manual hierarchy tweaks already present, validate safely, update this plan with actual results, commit/push by default, and close the bead only when the direct scene margin change is real.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`

**Files Created/Deleted/Modified:**
- `/.testbed/scenes/camera_gesture_testbed.tscn`
- `/.testbed/scripts/camera_gesture_testbed.gd`
- `/.testbed/tests/test_camera_gesture_testbed_scene.gd`

**Status:** ✅ Complete

**Results:** Landed the margin change directly in the scene hierarchy, keeping the scope narrow and aligned with Derrick’s manual scene-first direction. Each debug tab under `RootMargin/RootSplit/RightColumn/DebugTabs` now wraps its `RichTextLabel` in a scene-authored `MarginContainer`: `Runtime/RuntimeMargin/RuntimeDebugLabel`, `Trace/TraceMargin/TraceDebugLabel`, `Fixture/FixtureMargin/FixtureDebugLabel`, and `Provider/ProviderMargin/ProviderDebugLabel`. Each wrapper uses the same inset constants already used by the left sidebar sections (`left=12`, `top=10`, `right=12`, `bottom=12`), so the bottom-right debug text surfaces now have matching padding without adding new procedural layout code.

Because the wrapper nodes change the label paths, `/.testbed/scripts/camera_gesture_testbed.gd` was updated minimally to bind the four debug labels through the new margin containers, and the scene-layout GUT test now asserts that the runtime tab margin container exists with the expected inset values. Safe validation stayed repo-local and non-destructive: `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/camera_gesture_testbed.gd` passed, and `~/.local/bin/godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/test_camera_gesture_testbed_scene.gd -gexit` passed `6/6`.

---

---

### Task 19: Investigate replay landmark alignment and missing 3D response

**Bead ID:** `aerobeat-tool-camera-gesture-control-gth`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Investigate the new manually verified replay-state issues. Treat Derrick’s report and screenshot as source truth: replay video now loads, but the MediaPipe dots do not appear to match the MediaPipe/replay texture, and the 3D workspace camera did not visibly respond to the replay clip. Determine whether the remaining problem is in replay landmark alignment, controller hookup/application, or an obvious tracking-quality limitation surfaced honestly by the current footage. Prefer source-side debugging/instrumentation and narrow fixes over guesswork, validate safely without violating the no-headless-MediaPipe rule, update this plan with actual results, commit/push by default, and close the bead only when the source-side findings/fixes are real.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`

**Files Created/Deleted/Modified:**
- `/.testbed/scripts/camera_gesture_testbed.gd`
- `/src/camera_gesture_controller.gd`
- `/.testbed/tests/test_camera_gesture_controller.gd`
- `/.testbed/tests/test_camera_gesture_testbed_scene.gd`
- `Plan update / evidence references only`

**Status:** ✅ Complete

**Results:** Derrick’s screenshot/report narrowed this to two separate source-side issues rather than a single replay-loader failure. First, the overlay mismatch in replay was real alignment drift from runtime config, not just weak footage: the testbed was visually unmirroring the replay texture (`MediaPipeCameraView.flip_horizontal = false`) but still starting/reusing the local provider with its default `flip_horizontal = true`, so provider-normalized landmark X coordinates stayed mirrored against the unmirrored prerecorded video. The fix now routes explicit runtime settings through `camera_gesture_testbed.gd` so local MediaPipe replay sessions start/update with `{"flip_horizontal": false}` while live sessions keep mirrored-camera behavior.

Second, the missing 3D workspace response was primarily controller hookup/application, not replay asset loading: the selected replay sidecar correctly hints `sample_source=head_rotation`, but the current MediaPipe adapter lane still reports `Quaternion.IDENTITY` when no dedicated head-rotation quaternion is available. That meant the controller truthfully applied zero rotation for replay clips that were asking for the `head_rotation` lane. Rather than pretending full 6DOF head pose now exists, the controller now adds a narrow compatibility fallback: when `sample_source=head_rotation` returns identity, it derives rotation-only response from the existing head-position sample and keeps translation at zero. This restores visible camera response for the current 2D replay fixtures without overclaiming a true pose-estimation implementation.

Safe validation stayed repo-local only: `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/camera_gesture_testbed.gd` passed, and `~/.local/bin/godot --headless --path .testbed -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gtest=res://tests/test_camera_gesture_controller.gd,res://tests/test_camera_gesture_testbed_scene.gd -gexit` passed (with the wider discovered suite also clean at `27/27`). Remaining truth boundary: this does not prove the replay footage is high-quality enough for perfect anatomical alignment; it fixes a real replay mirroring/config bug and a real controller response gap, while any residual wobble should now be judged against the underlying clip quality instead of these two source defects.

---

---

### Task 20: Make debug tabs hideable and enlarge the anchored media preview for diagnosis

**Bead ID:** `aerobeat-tool-camera-gesture-control-6ux`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`  
**Prompt:** Implement a narrow diagnostic-UI follow-up in the camera-gesture testbed. Make the bottom-right tab/debug-info area minimizable or hideable, and enlarge the media preview significantly so it is easy to compare the replay/live feed against the tracking dots while still keeping that preview anchored to the bottom-right with margin. Treat the dummy → live/replay freeze bug as explicitly out of scope for this slice; this pass is about visibility and inspectability, not runtime-state fixes. Keep the change scene-first where practical, validate safely without violating the no-headless-MediaPipe rule, update this plan with actual results, commit/push by default, and close the bead only when the UI diagnostic improvement is real.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`

**Files Created/Deleted/Modified:**
- `/.testbed/scenes/camera_gesture_testbed.tscn`
- `/.testbed/scripts/camera_gesture_testbed.gd`
- `/.testbed/tests/test_camera_gesture_testbed_scene.gd`

**Status:** ✅ Complete

**Results:** Landed the diagnostic-only UI follow-up with a scene-first bias and kept the dummy → live/replay freeze bug explicitly out of scope. The bottom-right debug area is now collapsible without losing the affordance to bring it back: `/.testbed/scenes/camera_gesture_testbed.tscn` adds a dedicated `DebugToolbar` row above `DebugTabs` with a persistent toggle button that starts in the expanded state (`Hide debug tabs`) and collapses the tab body to a compact header-only state (`Show debug tabs`) when pressed. `camera_gesture_testbed.gd` binds that scene-authored control, updates the button label on toggle, and leaves the rest of the diagnostic surfaces untouched.

The media/tracking preview was also enlarged substantially while staying anchored to the bottom-right corner with explicit margin. The inset is now `416×296` instead of the previous small diagnostic stamp, uses a `20px` bottom/right corner margin, and raises the embedded feed host minimum height from `132` to `236`, making live/replay footage much easier to compare directly against the tracking dots. To make the enlarged diagnostic surface self-explanatory during manual use, the media title, placeholder copy, and inset status label are now visible by default. Safe repo-local validation stayed within Derrick’s rules: `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/camera_gesture_testbed.gd` passed, and `~/.local/bin/godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/test_camera_gesture_testbed_scene.gd -gexit` passed `8/8` after adding assertions for the larger anchored inset and the hide/show debug-tabs behavior.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** The camera-gesture `.testbed` now consumes `aerobeat-tool-headless-manager` through GodotEnv and autoloads it truthfully, with repo-local tests guarding that contract. The GUI verification lane also produced real evidence that fake mode runs, the normal Stop Running Project path reaches clean debugger teardown, and a graceful editor close succeeds after teardown.

**Reference Check:** `REF-02` and `REF-05` are satisfied for the integration truth: the consumer wiring is present and the headless-manager contract remains explicitly headless-only. `REF-03` is **not yet satisfied** for replay verification because no GUI evidence proves the prerecorded fixture path was actually selected and run. `REF-01` is only partially satisfied because the intended live/replay truth pass and the first real trace export still did not happen.

**Commits:**
- No new auditor commit; audited current working tree state and evidence only.

**Lessons Learned:** The safe-close improvement is worth keeping, but it does not remove the need for the normal GUI stop path because the current manager intentionally does not arm in windowed editor sessions. Also, the camera-gesture lane now has trace-export scaffolding ready, but any claim about forward/backward `translation.z` polarity must wait for a real exported trace from live or replay mode rather than screenshots or assumptions alone. The follow-up replay QA also proved that source-side timing was not the only blocker: Linux sidecar runtime provisioning inside the mounted `aerobeat-input-mediapipe-python` addon path must be correct before replay can ever become healthy. Derrick then corrected the intended fix path explicitly: the right repair is to run the addon/runtime install script locally so the gitignored runtime files are present inside the addon workflow, not to change the consumer mount strategy as the primary solution. The next manual regression report added three more truths: project-open warnings are still present, the enlarged UI pass regressed usability by hiding important controls/previews off-screen and crowding out the world preview, and both live/replay still reproduce `camera_view.gd:205 @ _connect_with_retry(): Failed to connect, status: 3`.

---

*Started on 2026-05-20*
