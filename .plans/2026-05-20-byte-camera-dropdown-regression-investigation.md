# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-20  
**Status:** Draft  
**Agent:** Cookie 🍪

---

## Goal

Diagnose and fix the new Boxing/Flow proving-scene regressions on Byte: incorrect live-camera handling, incomplete camera enumeration, and prerecorded Flow startup failure.

---

## Overview

Derrick’s latest Byte test found that the new camera-dropdown pass regressed core proving behavior. In the Boxing scene, live-camera mode was selected but the runtime behaved as if `/dev/video0` were a prerecorded source, causing the default camera preview to fail and the dropdown to list only a single camera on a machine that should expose at least two. In the Flow scene, prerecorded mode correctly hid the dropdown, but the proving run still failed with the Python server dying shortly after startup.

This slice is now a bug investigation and repair pass. It likely spans real owner-repo behavior in `aerobeat-input-mediapipe-python`, plus validation in the consuming `aerobeat-tool-camera-gesture-control` environment. Derrick explicitly authorized investigation on Byte over SSH/Tailscale (`ssh byte`) if the issue cannot be reproduced or fully explained from the local host alone.

The highest-value first questions are: why live camera `/dev/video0` is being treated as a prerecorded path, why the second webcam is missing from enumeration on Byte, and whether the Flow prerecorded failure is a separate provider/server startup regression or a side effect of the same source-selection bug.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derrick screenshot from Boxing on Byte showing `/dev/video0` treated as a prerecorded source and only one dropdown option | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/20/image-9755c4ad.png` |
| `REF-02` | Active Boxing/Flow camera-dropdown implementation plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-20-boxing-camera-dropdown-pass.md` |
| `REF-03` | Real proving harness owner repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` |
| `REF-04` | Consumer proving environment used on Byte | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control` |
| `REF-05` | Byte host access path authorized by Derrick | `ssh byte` |

---

## Tasks

### Task 1: Investigate Byte regressions and determine root causes

**Bead ID:** `aerobeat-tool-camera-gesture-control-mrg`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Investigate the Byte regressions after the Boxing/Flow camera-dropdown pass against bead `aerobeat-tool-camera-gesture-control-mrg`. Claim it on start with `bd update aerobeat-tool-camera-gesture-control-mrg --status in_progress --json`. Determine why Boxing live-camera mode is treating `/dev/video0` like a prerecorded source, why only one webcam appears in the dropdown on Byte, and why Flow prerecorded mode causes the Python server to die. Use the real owner repo and consumer repo state first; if needed, use `ssh byte` to inspect the actual device/runtime environment on Byte. Produce a concise root-cause report and explicit fix plan. Do not make code changes yet unless required to capture decisive evidence.

**Folders Created/Deleted/Modified:**
- repo inspection only
- remote Byte inspection if needed

**Files Created/Deleted/Modified:**
- none expected unless evidence notes are added

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 2: Implement the regression fixes in the real owner repo(s)

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** After root cause is known, fix the Byte regressions in the real owner repo(s): correct live-camera vs prerecorded-source routing, repair camera enumeration on Byte so all expected webcams appear, and fix the Flow prerecorded startup failure. Land durable fixes in the real source repo first, then refresh the consumer proving environment normally and validate on Byte if feasible.

**Folders Created/Deleted/Modified:**
- real `aerobeat-input-mediapipe-python`
- consumer `aerobeat-tool-camera-gesture-control` via refresh/validation as needed

**Files Created/Deleted/Modified:**
- repo-dependent; likely proving harness / provider / process launch paths

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 3: QA and audit the fixes on the real target behavior

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `qa` / `auditor`)  
**Role:** `qa` / `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Verify the fixes against the actual behaviors Derrick reported: Boxing live-camera default should load correctly, all expected camera options should appear on Byte, Flow prerecorded mode should launch without killing the Python server, and the dropdown hide/show rules should still work.

**Folders Created/Deleted/Modified:**
- QA evidence only if needed

**Files Created/Deleted/Modified:**
- none expected unless evidence is added

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
