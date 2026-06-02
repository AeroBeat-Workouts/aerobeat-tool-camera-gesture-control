# AeroBeat Tool Camera Gesture Control

**Date:** 2026-06-01  
**Status:** In Progress  
**Last Updated:** 2026-06-02 08:51 EDT  
**Blocked Reason:** None  
**Agent:** `byte`

---

## Goal

Audit and, if approved for execution, realign `aerobeat-tool-camera-gesture-control` so its repo-root `src/` surface, repo-root README/internal docs, and `.testbed/` GodotEnv manifest depend only on `aerobeat-tool-camera-tracking` for camera tracking, with MediaPipe-specific knowledge and the sidecar dependency owned downstream by `aerobeat-vendor-mediapipe-python` rather than directly by this repo.

---

## Overview

This lane is about enforcing the ownership boundary, not just doing a grep-and-complain pass. Derrick’s 2026-06-02 clarification hardens the target more strictly than the fresh audit summary did: repo-root `src/` in `aerobeat-tool-camera-gesture-control` is expected to depend on `aerobeat-tool-camera-tracking` directly. The gesture-control package should not own camera/tracking lifecycle logic itself; it should consume the tracking dependency. In contrast, the hidden `.testbed/` remains the proving ground where direct GodotEnv-mounted dependencies are allowed and refreshed through the canonical `godotenv-sync` flow.

That means the cleanup target is now two-layered. First, repo-root sharable runtime must stop acting like a provider-style tracker implementation seam and instead become a consumer of `aerobeat-tool-camera-tracking` only. Second, the hidden `.testbed/` must stop using the retired `aerobeat-input-mediapipe-python` / provider-session-registry-era wiring and instead prove live-vs-replay behavior through `aerobeat-tool-camera-tracking`, with replay flowing through the current `aerobeat-tool-video-player` + `aerobeat-vendor-godot-video` stack. The repo is not allowed to know about `aerobeat-vendor-mediapipe-python` as a repo-root `src/` dependency; only the proving layer may mount concrete backend dependencies.

The revised plan therefore focuses on four things: (1) move repo-root `src/` onto a true consumer relationship with `aerobeat-tool-camera-tracking`, (2) replace the old `.testbed` dependency manifest with the current proving stack refreshed through `godotenv-sync`, (3) rewrite the hidden testbed runtime around `CameraTracking` lifecycle/live-vs-replay control instead of direct MediaPipe provider/session wiring, and (4) update tests/docs so they lock the new truth instead of preserving the retired MediaPipe/input-core-era architecture.

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
| `REF-10` | Fresh post-refactor audit: `CameraTracking` is now the real upstream boundary; old MediaPipe/input-core-era proving assumptions are stale | Audit completed 2026-06-02 against `aerobeat-tool-camera-tracking`, `aerobeat-input-camera-tracking`, and this repo |
| `REF-11` | Derrick clarification: repo-root `src/` in gesture-control must depend on `aerobeat-tool-camera-tracking`; repo-root `src/` must not know about `aerobeat-vendor-mediapipe-python`; live vs replay should both flow through `aerobeat-tool-camera-tracking`, with replay using `aerobeat-tool-video-player` + `aerobeat-vendor-godot-video`; hidden `.testbed/` is the proving ground refreshed via `godotenv-sync` | User instruction, 2026-06-02 08:10 EDT |

---

## Tasks

### Task 1: Inventory camera-gesture boundary references

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-08`, `REF-09`, `REF-11`  
**Prompt:** Audit `aerobeat-tool-camera-gesture-control` for all MediaPipe-specific, replay-path, and camera-tracking-specific references across repo-root `src/`, repo-root README/docs, and `.testbed/` manifests/docs/scripts. Classify each hit as one of: `allowed-testbed-only`, `root-doc-leak`, `root-src-coupling`, `stale-name`, `direct-dependency-violation`, `missing-tool-camera-tracking-consumer-seam`, or `unclear`. Be exact about file paths and line numbers. Treat repo-root `src/` and published-facing repo-root docs as strict package-boundary surfaces that must depend on `aerobeat-tool-camera-tracking` for live/replay camera tracking behavior while knowing nothing about `aerobeat-vendor-mediapipe-python`. Treat hidden `.testbed/` as the allowed proving ground where concrete GodotEnv-mounted dependencies may exist. Do not rewrite anything yet; produce a findings list only.

**Folders Created/Deleted/Modified:**
- repo-local `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-camera-gesture-mediapipe-boundary-audit.md`

**Status:** ⏳ Pending

**Results:** Pending Derrick approval.

---

### Task 2: Verify current dependency/proving truth against the intended architecture

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-03`, `REF-05`, `REF-06`, `REF-07`, `REF-09`, `REF-10`, `REF-11`  
**Prompt:** Verify whether the actual current dependency chain matches Derrick’s clarified architecture: repo-root `aerobeat-tool-camera-gesture-control/src/` must consume `aerobeat-tool-camera-tracking` for camera tracking and for live-vs-replay mode control; repo-root `src/` must not know about `aerobeat-vendor-mediapipe-python`; the hidden `.testbed/` is allowed to mount concrete proving dependencies through GodotEnv and should be refreshed via `godotenv-sync`; replay should route through `aerobeat-tool-camera-tracking` with the existing `aerobeat-tool-video-player` + `aerobeat-vendor-godot-video` stack. Identify every place the current repo still bypasses that chain, still names old packages, still documents the retired input-core/provider-session-registry ownership boundary, or still lacks the required repo-root consumer seam.

**Folders Created/Deleted/Modified:**
- repo-local `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-camera-gesture-mediapipe-boundary-audit.md`

**Status:** ✅ Complete

**Results:** Fresh 2026-06-02 audit remains valid for the stale MediaPipe/input-core-era proving references, but Derrick’s clarification supersedes the earlier inference that repo-root `src/` could stay wholly generic. The revised execution target is now stricter: repo-root `src/` must become a true consumer of `aerobeat-tool-camera-tracking`, while `.testbed/` remains the direct-dependency proving surface. The existing drift is still concentrated in `.testbed/addons.jsonc`, README/docs, and the hidden testbed runtime/tests, with an additional open question now elevated into required work: what exact repo-root `src/` seam should wrap or consume `CameraTracking` without re-owning vendor/runtime logic.

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

### Task 4: Move gesture-control onto tool-camera-tracking at repo root and replace old proving-era wiring

**Bead ID:** `aerobeat-tool-camera-gesture-control-ep7` (completed src slice), `aerobeat-tool-camera-gesture-control-2lz` (completed proving slice), `aerobeat-tool-camera-gesture-control-y4s` (completed docs/tests slice)  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-03`, `REF-05`, `REF-06`, `REF-07`, `REF-09`, `REF-10`, `REF-11`, Task 3 findings  
**Prompt:** After approval, implement the boundary cleanup in `aerobeat-tool-camera-gesture-control` to satisfy Derrick’s clarified architecture exactly. At repo root `src/`, make this package consume `aerobeat-tool-camera-tracking` for camera tracking and live-vs-replay mode control instead of owning camera/tracking runtime logic itself; repo-root `src/` must not know about `aerobeat-vendor-mediapipe-python`. In hidden `.testbed/`, remove the old `aerobeat-input-mediapipe-python` / provider-session-registry-era wiring, refresh and prove the direct dependency stack through the canonical `godotenv-sync` flow, and route replay through `aerobeat-tool-camera-tracking` using `aerobeat-tool-video-player` + `aerobeat-vendor-godot-video`. Rewrite hidden testbed scripts/tests/docs and any required repo-root docs/tests so the new boundary is explicit and enforced.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`
- repo-root docs/tests as required by the revised boundary

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-camera-gesture-mediapipe-boundary-audit.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/src/camera_tracking_input_source.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/src/camera_gesture_controller.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/src/AeroCameraGestureControlManager.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons.jsonc`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/tests/test_AeroCameraGestureControlManager.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/tests/test_camera_gesture_controller.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scripts/camera_gesture_testbed.gd`
- relevant README/tests/docs to be updated after implementation audit

**Status:** ✅ Complete

**Results:** The first implementation slice (`aerobeat-tool-camera-gesture-control-ep7`) landed in commit `21cfcde` (`Refactor gesture control onto camera tracking boundary`). Repo-root `src/` now consumes `aerobeat-tool-camera-tracking` directly via a new `camera_tracking_input_source.gd` adapter, `camera_gesture_controller.gd` now exposes direct camera-tracking attach/detach seams, and `AeroCameraGestureControlManager.gd` now expresses live/replay through the tracking boundary instead of owning local tracking runtime lifecycle. The second implementation slice (`aerobeat-tool-camera-gesture-control-2lz`) landed in commit `d5451e6` (`Rewire hidden testbed onto camera tracking`) and removed the hidden `.testbed/` dependency on the old `aerobeat-input-mediapipe-python` / provider-session-registry path. Hidden proving now mounts `aerobeat-tool-camera-tracking`, `aerobeat-vendor-mediapipe-python`, `aerobeat-tool-video-player`, and `aerobeat-vendor-godot-video`; the testbed runtime now routes live/replay through `CameraTracking`, and replay preview is delegated through the video-player/godot-video path. This docs/tests slice rewrote the repo README, tightened the profile-contract wording, and replaced stale README assertions with boundary-lock tests that prove repo-root `src/` consumes `aerobeat-tool-camera-tracking`, stays vendor-clean relative to `aerobeat-vendor-mediapipe-python`, and keeps concrete backend ownership inside hidden `.testbed/`. Validation passed with a fresh `37/37` full repo-local GUT run plus a headless `.testbed` import smoke pass. The docs/tests lock is included in the current `Lock camera tracking boundary docs and tests` commit.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Repo-root `src/` in `aerobeat-tool-camera-gesture-control` now consumes `aerobeat-tool-camera-tracking` directly for camera tracking plus live/replay control, the hidden `.testbed/` proving surface has been rewired off the old `aerobeat-input-mediapipe-python` / provider-session-registry path onto the current `CameraTracking`-based live/replay stack, and the repo-facing README/tests/docs now lock that boundary explicitly.

**Reference Check:** `REF-01` through `REF-11` now anchor the audit scope and expected dependency chain. The first execution slice satisfied Derrick’s clarified repo-root rule by landing a direct `aerobeat-tool-camera-tracking` consumer seam in `src/`. The second execution slice satisfied the proving-ground rule by rewiring hidden `.testbed/` onto `CameraTracking`, mounting `aerobeat-vendor-mediapipe-python` only in proving, and routing replay through `aerobeat-tool-video-player` + `aerobeat-vendor-godot-video`. The final docs/tests slice satisfied the remaining repo-facing truth work by removing stale tracker-agnostic/provider-session-registry wording and asserting the new ownership model directly.

**Commits:**
- `21cfcde` - Refactor gesture control onto camera tracking boundary
- `d5451e6` - Rewire hidden testbed onto camera tracking
- Current docs/tests commit - Lock camera tracking boundary docs and tests

**Lessons Learned:** Derrick’s architecture clarification mattered more than the first audit inference: repo-root `src/` was not allowed to remain merely generic. Once the runtime seam moved onto `CameraTracking`, the remaining risk was documentation/test drift preserving the old mental model. Boundary-lock tests were the cleanest way to keep that stale wording from creeping back.

---

*Drafted on 2026-06-01*
