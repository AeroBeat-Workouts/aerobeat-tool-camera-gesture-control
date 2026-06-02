# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-21  
**Status:** Stale  
**Agent:** Cookie 🍪

---

## Goal

Identify the actual remaining crash boundary for the live tracking-quality change path in the camera-gesture `.testbed`, since the previous controller/provider lifetime fix was real but insufficient.

---

## Overview

Derrick’s latest manual QA confirms the Zorin GUI still crashes on live tracking-quality change even after the controller/provider handoff fix was implemented and independently audited. That means the prior diagnosis captured a real bug, but not the last bug. We should stop guessing and treat this as a crash-forensics pass.

This pass should focus on the exact quality-change restart lifecycle in the consumer scene, compare it again against donor truth, and identify which boundary is still unsafe in real GUI conditions. Likely candidates remain preview thread teardown/rebuild ordering, provider/runtime restart overlap, overlay-mode transition behavior, or stale mounted/runtime state interactions that don’t show up in targeted tests. Final behavior verification remains human-owned by Derrick.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current quality-change crash plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-21-camera-gesture-quality-switch-crash-regression.md` |
| `REF-02` | Consumer testbed script under test | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scripts/camera_gesture_testbed.gd` |
| `REF-03` | Consumer overlay script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scripts/tracking_inset_overlay.gd` |
| `REF-04` | Donor proving harness truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-05` | Owner runtime paths still in play | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/camera_view.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/input_provider.gd` |

---

## Tasks

### Task 1: Quality-change crash forensics and boundary mapping

**Bead ID:** `aerobeat-tool-camera-gesture-control-bg2`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Re-investigate the live tracking-quality crash path now that the controller/provider handoff bug has been fixed but the real GUI crash still persists. Identify the remaining likely unsafe boundary with concrete evidence and rank the candidates. Compare consumer sequencing to donor truth and call out whether the next fix should be consumer-only, owner-only, or cross-repo.

**Status:** ⏳ In Progress

**Results:** Research subagent launched on 2026-05-21 against bead `aerobeat-tool-camera-gesture-control-bg2`; awaiting the remaining crash-boundary map.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Crash-forensics plan drafted; execution in progress.

**Reference Check:** Anchored to the still-failing manual QA result after the audited handoff fix.

**Commits:**
- None yet.

**Lessons Learned:** When a real GUI crash survives a clean code/audit pass, the next honest move is crash forensics on the remaining lifecycle boundaries rather than another guess-driven patch.

---

*Last updated on 2026-05-21*
