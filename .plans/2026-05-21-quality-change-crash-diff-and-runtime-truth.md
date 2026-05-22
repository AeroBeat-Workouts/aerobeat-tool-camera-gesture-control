# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-21  
**Status:** Draft  
**Agent:** Cookie 🍪

---

## Goal

Determine why tracking-quality changes still crash Zorin in the camera-gesture consumer lane by diffing it against the working `aerobeat-input-mediapipe-python` testbed and truth-checking both the mounted addon revision and the Linux sidecar runtime install/state.

---

## Overview

Derrick’s latest manual QA proves the earlier consumer-only restart-lifecycle fix was insufficient: changing tracking quality in the camera-gesture `.testbed` still crashes the Zorin GUI. Derrick explicitly asked for a truth pass on three candidate explanations: (1) the camera-gesture scene/script is still not actually implementing the same lifecycle as the working `mediapipe-python` testbed, (2) the mounted `mediapipe-python` version in the consumer project is stale relative to the owner repo, or (3) the Linux Python sidecar/runtime install is incorrect or inconsistent.

This pass therefore starts with comparison and environment truth, not more guess-driven patching. We need to diff the relevant consumer-vs-donor scene/script/runtime paths, verify the mounted addon revision and shape under `.testbed/addons/`, and verify the mounted Linux runtime contract under `python_mediapipe/assets/runtimes/linux-x64/`. Only after that should implementation begin.

Derrick remains the human QA owner for final GUI behavior verification.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current quality-switch crash plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-21-camera-gesture-quality-switch-crash-regression.md` |
| `REF-02` | Consumer scene/script under test | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scenes/camera_gesture_testbed.tscn`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scripts/camera_gesture_testbed.gd` |
| `REF-03` | Donor proving harness truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-04` | Mounted addon/runtime path to truth-check | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons/aerobeat-input-mediapipe-python/` |
| `REF-05` | Owner repo/runtime path to compare against | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/` |

---

## Tasks

### Task 1: Consumer-vs-donor diff and mounted/runtime truth check

**Bead ID:** `aerobeat-tool-camera-gesture-control-0vg`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Diff the camera-gesture consumer lane against the working `mediapipe-python` donor lane for the tracking-quality-change path. Explicitly check: (1) scene/script lifecycle differences, (2) whether the mounted addon under `.testbed/addons/aerobeat-input-mediapipe-python` is stale relative to the owner repo, and (3) whether the mounted Linux runtime install/state is wrong or inconsistent. Produce a ranked diagnosis with concrete evidence and the narrowest next fix target.

**Status:** ⏳ In Progress

**Results:** Research subagent launched on 2026-05-21 against bead `aerobeat-tool-camera-gesture-control-0vg`; awaiting consumer-vs-donor diff and mounted runtime truth report.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Draft truth-pass plan only.

**Reference Check:** Anchored to the consumer/donor scene-script diff and mounted runtime truth paths Derrick explicitly requested.

**Commits:**
- None yet.

**Lessons Learned:** When GUI crash fixes fail to hold, the next honest move is a source-of-truth diff plus runtime/install verification rather than more local lifecycle guessing.

---

*Last updated on 2026-05-21*
