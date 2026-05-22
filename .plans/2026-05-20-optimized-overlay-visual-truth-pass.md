# AeroBeat Tool Camera Gesture Control

**Date:** 2026-05-20  
**Status:** Draft  
**Agent:** Cookie 🍪

---

## Goal

Resolve the mismatch between code-level QA claims and the actual Byte visual result for `optimized` tracking overlay mode.

---

## Overview

Derrick’s latest Byte screenshot shows that `optimized` still does not match the intended visual truth in the real proving scene. That means the previous QA conclusion was wrong or incomplete. Even if the source filtering looks correct on paper, the actual rendered path on Byte is still showing more face dots than desired, so the next pass must treat the live rendered preview as the source of truth.

This follow-up should focus on the full rendered chain on Byte: scene setting → proving harness config → provider/runtime → landmark payload → overlay draw path. The goal is not to re-prove source hashes; it is to explain why the actual preview still shows the wrong visual output and then fix that real behavior in the owner repo first.

Because Derrick has now supplied direct visual evidence from Byte, future QA for this slice should require screenshot-level or equivalent visual-runtime proof rather than source-only reasoning.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derrick Byte screenshot showing `optimized` still rendering the wrong face-dot set | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/05/21/image-08332375.png` |
| `REF-02` | Prior optimized overlay follow-up plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-20-optimized-overlay-followup.md` |
| `REF-03` | Prior verification pass that incorrectly concluded resolved | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-20-optimized-overlay-verification-pass.md` |
| `REF-04` | Real MediaPipe owner repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` |
| `REF-05` | Consumer proving environment | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control` |
| `REF-06` | Byte verification path | `ssh byte` |

---

## Tasks

### Task 1: Investigate the real rendered-path mismatch on Byte

**Bead ID:** `aerobeat-tool-camera-gesture-control-vye`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Investigate why `optimized` still shows the wrong face-dot set in the actual Byte rendering despite prior source-level QA claims, against bead `aerobeat-tool-camera-gesture-control-vye`. Claim it on start with `bd update aerobeat-tool-camera-gesture-control-vye --status in_progress --json`. Treat Derrick’s screenshot as the source of truth. Follow the full runtime path on Byte if needed: scene config, proving harness, provider/runtime, payload filtering, and overlay drawing. Determine the real cause and produce an explicit fix plan. Do not stop at source hashes or static code reasoning.

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 2: Fix the real runtime/render behavior in the owner repo

**Bead ID:** `aerobeat-input-mediapipe-python-qb0`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** After root cause is known, fix the real runtime/render behavior in the owner repo against bead `aerobeat-input-mediapipe-python-qb0`. Claim it on start in the real `aerobeat-input-mediapipe-python` repo. Fix the missing runtime propagation path so `tracking_overlay_mode` from the proving scene/harness actually reaches the live Python sidecar at launch time. Land source changes in the real owner repo first, then refresh the consumer repo normally and validate against actual rendered output on Byte. Derrick has authorized throwing away any non-canon local owner-repo scene drift on Byte if it is in the way of clean verification.

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 3: QA with visual proof on Byte

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `qa` / `auditor`)  
**Role:** `qa` / `auditor`  
**References:** `REF-01`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Verify the fix with actual visual/runtime evidence on Byte. Do not conclude success from source inspection alone. Require screenshot-level or equivalent direct render proof that `optimized` now matches the intended face-dot set.

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
