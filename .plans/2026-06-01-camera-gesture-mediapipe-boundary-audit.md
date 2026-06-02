# AeroBeat Tool Camera Gesture Control

**Date:** 2026-06-01  
**Status:** Blocked  
**Last Updated:** 2026-06-01 21:54 EDT  
**Blocked Reason:** Deliberately paused pending Chip's in-flight `aerobeat-tool-camera-tracking` changes so this audit can be evaluated against the new tracking-boundary reality before execution  
**Agent:** `byte`

---

## Goal

Audit and, if approved for execution, realign `aerobeat-tool-camera-gesture-control` so its repo-root `src/` surface, repo-root README/internal docs, and `.testbed/` GodotEnv manifest depend only on `aerobeat-tool-camera-tracking` for camera tracking, with MediaPipe-specific knowledge and the sidecar dependency owned downstream by `aerobeat-vendor-mediapipe-python` rather than directly by this repo.

---

## Overview

This lane is about enforcing the ownership boundary, not just doing a grep-and-complain pass. Derrick clarified the intended architecture more strictly: the sharable package at this repo root and the hidden `.testbed/` Godot project should depend directly on `aerobeat-tool-camera-tracking` for camera tracking, while concrete MediaPipe sidecar ownership belongs further downstream in `aerobeat-vendor-mediapipe-python`. A direct `.testbed/addons/` dependency on `aerobeat-input-mediapipe-python` is not acceptable and should be removed as part of this plan’s required end state.

The first pass will inventory the current boundary truth across repo-root source, README/internal docs, `.testbed/` manifests/scripts, and any generated addon mirrors. The second pass will compare that truth against the desired dependency chain so we can classify drift precisely: acceptable tracking-tool references, repo-root documentation leaks, root-source coupling, stale package names, or direct vendor coupling that should move behind `aerobeat-tool-camera-tracking`. The output should be an implementation-ready audit report with exact offending files/lines, an allow/deny classification for each reference, and a concrete remediation map.

Because Derrick has already declared removal of the direct `.testbed/addons/` MediaPipe dependency to be an explicit requirement, this plan now includes a bounded implementation task after the audit rather than treating cleanup as merely optional.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Camera-gesture repo root README and current package boundary language | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/README.md` |
| `REF-02` | Camera-gesture repo sharable source boundary | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/src/` |
| `REF-03` | Camera-gesture hidden testbed dependency manifest | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons.jsonc` |
| `REF-04` | Camera-gesture internal profile contract doc | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/docs/camera_gesture_profile_contract.md` |
| `REF-05` | Desired intermediate ownership repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/README.md` |
| `REF-06` | Camera-tracking hidden testbed dependency manifest showing vendor package ownership | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.testbed/addons.jsonc` |
| `REF-07` | Desired vendor ownership repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python/` |
| `REF-08` | Current audit signal: repo-root `src/` has no direct MediaPipe string hits while README still does | Fresh grep inventory captured on 2026-06-01 during plan creation |
| `REF-09` | Derrick clarification: camera-gesture-control `src/` and `.testbed/` should depend directly on `aerobeat-tool-camera-tracking`; direct `.testbed/addons/` dependency on `aerobeat-input-mediapipe-python` should be removed | User instruction, 2026-06-01 21:46 EDT |

---

## Tasks

### Task 1: Inventory camera-gesture boundary references

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-08`, `REF-09`  
**Prompt:** Audit `aerobeat-tool-camera-gesture-control` for all MediaPipe-specific references across repo-root `src/`, repo-root README/docs, and `.testbed/` manifests/docs/scripts. Classify each hit as one of: `allowed-testbed-only`, `root-doc-leak`, `root-src-coupling`, `stale-name`, `direct-dependency-violation`, or `unclear`. Be exact about file paths and line numbers. Treat repo-root `src/`, published-facing repo-root docs, and the `.testbed/` dependency manifest as strict package-boundary surfaces because Derrick has explicitly required `.testbed/` to depend on `aerobeat-tool-camera-tracking`, not directly on `aerobeat-input-mediapipe-python`. Do not rewrite anything yet; produce a findings list only.

**Folders Created/Deleted/Modified:**
- repo-local `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-camera-gesture-mediapipe-boundary-audit.md`

**Status:** ⏳ Pending

**Results:** Pending Derrick approval.

---

### Task 2: Verify dependency-chain truth against the intended architecture

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-03`, `REF-05`, `REF-06`, `REF-07`, `REF-09`  
**Prompt:** Verify whether the actual dependency chain matches Derrick’s intended architecture: `aerobeat-tool-camera-gesture-control` should depend directly on `aerobeat-tool-camera-tracking` in both sharable source assumptions and `.testbed/` GodotEnv setup; `aerobeat-tool-camera-tracking` should bring in `aerobeat-vendor-mediapipe-python` as the sibling dependency that owns the MediaPipe sidecar; and `aerobeat-tool-camera-gesture-control` should not directly depend on `aerobeat-input-mediapipe-python` in `.testbed/addons.jsonc` or generated addon state. Identify every place the current repo bypasses that chain, still names old packages, or documents the wrong ownership boundary.

**Folders Created/Deleted/Modified:**
- repo-local `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-camera-gesture-mediapipe-boundary-audit.md`

**Status:** ⏳ Pending

**Results:** Pending Derrick approval.

---

### Task 3: Produce audit verdict and remediation map

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** all above  
**Prompt:** Using the findings from Tasks 1 and 2, produce the final audit verdict for `aerobeat-tool-camera-gesture-control`. State whether the repo currently satisfies Derrick’s intended boundary. Separate: (a) already-correct boundary behavior, (b) documentation leaks, (c) source coupling, (d) dependency-chain violations, and (e) required cleanup to remove the direct `.testbed` dependency on `aerobeat-input-mediapipe-python` and align on `aerobeat-tool-camera-tracking` → `aerobeat-vendor-mediapipe-python`. For each failure, recommend the minimum owning repo/file where the fix belongs.

**Folders Created/Deleted/Modified:**
- repo-local `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-camera-gesture-mediapipe-boundary-audit.md`

**Status:** ⏳ Pending

**Results:** Pending Derrick approval.

---

### Task 4: Remove direct MediaPipe dependency and realign the testbed boundary

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-03`, `REF-05`, `REF-06`, `REF-07`, `REF-09`, Task 3 findings  
**Prompt:** After the audit confirms the drift, implement the required boundary cleanup in the true owning repo(s). In `aerobeat-tool-camera-gesture-control`, remove the direct `.testbed/addons.jsonc` dependency on `aerobeat-input-mediapipe-python`, delete the generated `.testbed/addons/` mirror for that package as appropriate, and realign the `.testbed` Godot project plus any repo docs/scripts so camera tracking depends only on `aerobeat-tool-camera-tracking`. Preserve tracker-agnostic repo-root `src/` ownership. If any downstream package wiring must change so `aerobeat-tool-camera-tracking` truthfully brings in `aerobeat-vendor-mediapipe-python`, land that only in the true owning repo and document it exactly.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`
- additional owning repo folders only if audit proves they must change

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-camera-gesture-mediapipe-boundary-audit.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons.jsonc`
- additional files to be determined by audit

**Status:** ⏳ Pending

**Results:** Not started. This task is part of the plan’s required end state once execution is approved.

---

## Final Results

**Status:** ⚠️ Paused

**What We Built:** Drafted an execution plan for a boundary/ownership audit and required dependency-boundary cleanup of `aerobeat-tool-camera-gesture-control`, centered on keeping MediaPipe-specific knowledge out of repo-root `src/` and repo-root docs, and on making the repo’s `.testbed` depend directly on `aerobeat-tool-camera-tracking` rather than directly on `aerobeat-input-mediapipe-python`.

**Reference Check:** `REF-01` through `REF-09` were gathered to anchor the audit scope and expected dependency chain. Initial spot check already shows no direct `MediaPipe` string hits under repo-root `src/`, while the current repo-root README still contains multiple MediaPipe-specific references and the current `.testbed/addons.jsonc` still names the direct MediaPipe package, both of which remain likely execution targets once the upstream tracking repo settles.

**Commits:**
- None yet

**Lessons Learned:** This plan should not be executed against a moving ownership boundary. Chip’s in-flight `aerobeat-tool-camera-tracking` changes may remove or generalize more MediaPipe knowledge first, so the right next move is to pause here and re-audit the plan against that updated repo state before implementation.

---

*Drafted on 2026-06-01*
