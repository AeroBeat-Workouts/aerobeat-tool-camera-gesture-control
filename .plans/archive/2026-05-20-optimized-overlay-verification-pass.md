# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-20  
**Status:** Stale  
**Agent:** Cookie 🍪

---

## Goal

Verify whether the `optimized` overlay face-dot fix is actually resolved in the proving scenes, and if so confirm Byte is refreshed/running the corrected state too.

---

## Overview

Derrick still sees the full face tracking dots when choosing `optimized`, which means the recently-landed owner-repo fix may not have actually propagated to the running proving environment, may be incomplete, or may be correct in source but not in the actual rendered path. This pass is not a broad implementation pass yet; it is a targeted verification pass to answer one question cleanly: is the bug really fixed in the real usable environment?

The verification needs two levels. First, QA should validate the actual behavior against the real owner repo plus a properly refreshed consumer environment using the canonical GodotEnv sync workflow rather than ad-hoc addon edits. Second, if the fix appears resolved locally/in-source, the same check should be performed against Byte’s synced state so we know whether Byte is stale, mismatched, or still genuinely broken.

Because the Godot skill has now been updated to require real-source-repo edits and `godotenv-sync`-based refresh instead of treating mounted `/addons/` copies as source of truth, this pass should explicitly use that workflow and report whether the environment is actually aligned.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Optimized overlay follow-up plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-20-optimized-overlay-followup.md` |
| `REF-02` | Real MediaPipe owner repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` |
| `REF-03` | Consumer proving environment | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control` |
| `REF-04` | Canonical GodotEnv sync helper | `/home/derrick/.openclaw/workspace/scripts/godotenv-sync` |
| `REF-05` | Byte access path for direct verification | `ssh byte` |

---

## Tasks

### Task 1: QA optimized overlay behavior and environment alignment

**Bead ID:** `aerobeat-tool-camera-gesture-control-ekc`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Verify whether the `optimized` overlay face-dot bug is actually resolved against bead `aerobeat-tool-camera-gesture-control-ekc`. Claim it on start with `bd update aerobeat-tool-camera-gesture-control-ekc --status in_progress --json`. Use the real owner repo and a properly refreshed consumer proving environment via the canonical `godotenv-sync` workflow, not manual `/addons/` edits. Confirm whether `optimized` now visually reduces visible face/head dots to only left eye, right eye, and nose/center-head, while `full` still shows the full face/head set. If local verification indicates the fix is resolved, then verify Byte’s synced/runtime state matches. If it is not resolved, identify whether the issue is source, refresh propagation, or runtime behavior. Return a precise verdict with evidence and do not modify source unless absolutely necessary for decisive QA evidence setup.

**Folders Created/Deleted/Modified:**
- QA evidence only if needed

**Files Created/Deleted/Modified:**
- none expected unless evidence is added

**Status:** ⏳ Pending

**Results:** Not started.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending verification.

**Reference Check:** Pending verification.

**Commits:**
- Pending

**Lessons Learned:** Pending verification.

---

*Completed on Pending*
