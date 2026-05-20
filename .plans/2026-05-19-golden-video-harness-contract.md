# AeroBeat Tool Camera Gesture Control Golden Video Harness Contract

**Date:** 2026-05-19  
**Status:** In Progress  
**Agent:** Byte 🐈‍⬛

---

## Goal

Define the agreed product requirements, test harness structure, and controller value/trace contract needed for `aerobeat-tool-camera-gesture-control` to support Derrick-authored golden-truth prerecorded video validation, drawing direct inspiration from the `aerobeat-input-mediapipe-python` `.testbed` workflow.

---

## Overview

Derrick has clarified both the truth source and the product intent. On the human side, Derrick will create the golden-truth videos representing the interactions the system should handle. On the repo side, the missing work is to define the harness structure that can consume those videos, define the exact values the system should expose so iteration is fast and validation is trustworthy, and make sure the head-control requirements themselves are explicit and agreed upon before deeper implementation.

The intended behavior to validate is broader than simple left/right look. The head-control system should support tracked head rotation within bounded horizontal and vertical ranges, plus tracked head movement within bounded front/back and left/right ranges, in service of adding dimensionality and 3D feel to AeroBeat menus. It also needs lifecycle control: the system must be enableable/disableable, athlete-toggleable at will, and it must coexist cleanly with the broader MediaPipe input stack without spinning up a duplicate MediaPipe runtime if one is already active.

Gameplay usage is intentionally still an open product question rather than a pre-decided exclusion. The system may end up being valuable not only in menus but also during active workouts if the parallax/perspective effect feels good in motion — for example, letting head movement during squats or side-to-side dodges reinforce depth and spatial expectation similar to VR workout games. Derrick also called out a possible limited multi-portal design benefit: if the camera/head-control system feels good during gameplay, it may help support a constrained multi-portal illusion with beats approaching from roughly the 11, 12, and 1 o’clock lanes. That is not the same as true 360 gameplay, but it may be enough to recover some of the feel of light multi-directional encounters. Because this may feel great for some athletes and bad for others, the requirements must preserve an athlete-facing on/off option that can disable the parallax/head-control effect and fall back to a more conventional single-portal mode.

A key architectural clarification from Derrick: this repo should not encode wider AeroBeat gameplay policy. Its responsibility is narrower and cleaner: own a config-driven head-control system whose bounded motion ranges and other public behavior values come from developer-editable YAML configuration, and ensure clean coexistence with the shared input stack. That config surface should support swapping tuned value sets on demand — for example menu vs gameplay vs other deterministic contexts — while keeping the underlying rules/logic consistent. Likely configurable values include bounded motion ranges, acceleration/smoothing/easing parameters, and related public control values needed for rapid tuning and side-by-side comparison. The active target camera is not a YAML concern: this repo must accept the active `Camera3D` to affect at runtime when the singleton/controller is started, because the camera is scene-dependent and there must be a valid active 3D camera in the scene for the system to function.

The only wider-system integration concern this repo needs to understand is MediaPipe coexistence via `input-core`: reuse an already-active MediaPipe session when present, and only request/spawn a new one when no active session exists. Because that ownership-sharing behavior does not belong solely inside this repo, the necessary shared contracts will need to be created or updated in `aerobeat-input-core`, and this repo’s root `src/` code will implement/use those contracts rather than inventing a private side channel.

Repo structure expectations are now explicit as well: source code lives in repo-root `src/`, assets live in repo-root `assets/`, and the repo will provide a `.testbed/` Godot project with subfolders `assets/`, `scenes/`, and `scripts/` for validation/testing. The `.testbed/` project should use GodotEnv dependencies so it can mount at least `aerobeat-input-core` and `aerobeat-input-mediapipe-python` for testing. Downstream, this repo is expected to be consumed by `aerobeat-assembly-community` through GodotEnv.

This means the next lane is not implementation-first. It is contract-first. We need to study the `mediapipe-python` `.testbed` proving/fixture workflow, identify which parts transfer cleanly to camera-gesture control, and then adapt that pattern into a repo-local validation design for this tool. The output should freeze:
- head-control product requirements and supported motion dimensions
- fixture storage/layout
- candidate vs canonical review flow
- video + sidecar metadata schema
- intermediate provider-trace expectations
- controller output trace schema
- summary/oracle comparison rules
- human-review artifacts/checklists
- lifecycle/enable-disable expectations
- athlete-facing opt-in/opt-out expectations
- developer-editable YAML configuration surface and swap model
- bounded-range / acceleration / easing / public-value configuration requirements
- runtime-provided active `Camera3D` target requirement
- repo-root `src/` / `assets/` and `.testbed/{assets,scenes,scripts}` structure expectations
- GodotEnv dependency expectations for `.testbed/` and downstream assembly consumption
- MediaPipe coexistence / ownership rules
- `input-core` shared-contract requirements for MediaPipe session reuse/ownership
- the exact runtime/debug values the controller must expose per frame for fast iteration and honest diagnosis

Once those are defined, the repo can move into coder work for replay harnesses, trace capture, coexistence logic, and golden comparison without thrashing on what truth means.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Camera gesture repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control` |
| `REF-02` | Assessment plan/result | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-19-validation-readiness-assessment.md` |
| `REF-03` | MediaPipe Python repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` |
| `REF-04` | MediaPipe Python `.testbed` harness/docs/scripts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed` |
| `REF-05` | Existing camera gesture first-implementation plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/2026-05-15-camera-gesture-control-first-implementation-lane.md` |

---

## Tasks

### Task 1: Study mediapipe-python harness as donor reference

**Bead ID:** `aerobeat-tool-camera-gesture-control-iqt`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-03`, `REF-04`  
**Prompt:** Read the `aerobeat-input-mediapipe-python` `.testbed` fixture/proving workflow and extract the reusable design pattern for prerecorded golden-video validation. Identify fixture layout, sidecar schema, replay path, artifact outputs, review flow, and CI/headless seams. Claim the bead on start and close it when the donor map is complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/`

**Files Created/Deleted/Modified:**
- donor docs/scripts/fixtures as needed for reading only

**Status:** ✅ Complete

**Results:** Donor map completed and bead `aerobeat-tool-camera-gesture-control-iqt` was closed. Main takeaways: the `mediapipe-python` donor provides an excellent contract/design shape for prerecorded golden-video validation, but its implementation is still more replay-plus-evidence-capture than full sidecar-assertion engine. Strong reusable patterns include `.testbed/assets/fixtures/<family>/<feature>/` storage, same-basename video + `.fixture.yaml` sidecars, candidate/canonical/deprecated approval flow, clip timing anchors, claims/non-claims, headless replay injection via env vars through the real runtime path, per-run artifact folders with screenshot/JSON/Markdown outputs, and human verification checklist/log templates. For this repo, those patterns should transfer directly, but camera-gesture control should land stronger machine-evaluable trace/assertion layers earlier than the donor currently does.

---

### Task 2: Define camera-gesture harness structure and repo-owned requirements

**Bead ID:** `aerobeat-tool-camera-gesture-control-b8w`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Using the donor map plus the completed camera-gesture assessment, define the repo-local harness structure for prerecorded golden-video validation and freeze the requirements this repo itself owns. Focus on supported motion dimensions (horizontal/vertical head rotation; left/right and front/back head movement), bounded-range expectations, enable/disable lifecycle behavior, athlete-facing toggle behavior, developer-editable YAML configuration and config-swap expectations, runtime-provided active `Camera3D` targeting, repo structure expectations (`src/`, `assets/`, `.testbed/assets`, `.testbed/scenes`, `.testbed/scripts`), `.testbed` GodotEnv dependency expectations, MediaPipe coexistence rules through input-core (reuse an active MediaPipe lane; do not start a second runtime unless none is active), the need for shared ownership/reuse contracts in `aerobeat-input-core`, fixture storage, candidate/canonical flow, sidecar metadata fields, provider-trace boundary, controller replay boundary, artifact outputs, and oracle comparison layers. Include the expected test scene layout pattern: 16:9 scene, left debug/info panel, right 3D world-space preview, plus bottom-left media/tracking view similar in spirit to the boxing harness in `aerobeat-input-mediapipe-python`. Do not drift into wider AeroBeat gameplay-policy decisions that this repo does not own. Claim the bead on start and close it when the contract is complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/docs/` if created

**Files Created/Deleted/Modified:**
- plan/docs/notes only until implementation is approved

**Status:** ✅ Complete

**Results:** Harness contract defined and bead `aerobeat-tool-camera-gesture-control-b8w` was closed. The contract now has a concrete repo-local shape: curated fixtures live under `.testbed/assets/fixtures/camera_gesture/<feature>/`, with same-basename `.mp4` + `.fixture.yaml` + optional notes files; sidecar YAML asserts controller outputs and observability, not just provider events; candidate/canonical/deprecated review flow stays human-gated; headless replay should drive the real controller through the mounted MediaPipe dependency path; per-run artifacts should include screenshot/report plus controller/provider traces and resolved fixture/config outputs; the golden harness scene should be a 16:9 layout with left debug panel, right 3D world preview, and bottom-left MediaPipe texture + 2D skeleton/tracking view; runtime must receive an explicit active `Camera3D`; and MediaPipe session reuse/ownership semantics require shared contract work in `aerobeat-input-core`, not a private repo-local workaround.

---

### Task 3: Define controller values / trace contract for fast iteration

**Bead ID:** `aerobeat-tool-camera-gesture-control-7w2`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Define the exact values the camera-gesture system should expose per frame and per run to support fast iteration, replay debugging, and golden comparison, plus the YAML-configurable public values that drive behavior. Separate raw input, normalized input, controller decision flags, target transforms, current transforms, active camera identity/attachment state, clamp/freeze/recenter state, timing, summary metrics, active config identity, and the developer-editable bounded-range / acceleration / easing / smoothing values that must be serializable and swappable. Account for the debug/test scene needs too: values should support the left debug panel, YAML load/save actions, and the bottom-left MediaPipe texture + 2D skeleton/tracking view used during live or prerecorded validation. Claim the bead on start and close it when the value contract is complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`

**Files Created/Deleted/Modified:**
- plan/docs/notes only until implementation is approved

**Status:** ✅ Complete

**Results:** YAML config + public-values/trace contract defined and bead `aerobeat-tool-camera-gesture-control-7w2` was closed. The contract locks the repo around swappable self-contained YAML profiles under `assets/profiles/camera_gesture/`, explicit public tuning values for tracking gates, rotation/translation bounds, smoothing/acceleration/deceleration, recenter behavior, and debug trace level, while keeping scene-specific concerns like active `Camera3D` targeting and MediaPipe session ownership out of YAML. It also defines a concrete per-frame trace schema including active config identity/path/hash, gating reasons, raw and normalized input, pre-clamp and post-clamp target outputs, current applied outputs, camera attachment state, and response parameters, plus per-run manifest/report requirements and debug-panel surface requirements needed for fast iteration and golden comparison.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** A contract-first definition pass for `aerobeat-tool-camera-gesture-control` covering (1) the donor pattern from `aerobeat-input-mediapipe-python`, (2) the repo-local golden-video harness structure and ownership boundaries, and (3) the YAML profile plus public-values/trace contract needed to support rapid iteration and honest prerecorded golden-truth validation.

**Reference Check:** `REF-01` and `REF-02` grounded the repo-local requirements; `REF-03` and `REF-04` supplied the donor harness pattern; `REF-05` informed continuity with the repo’s earlier implementation lane. The donor shape transfers well, but we intentionally tightened the contract here by requiring stronger machine-readable trace/evaluator seams earlier than the donor currently enforces.

**Commits:**
- None. This slice produced contract decisions and plan state only.

**Lessons Learned:** The right near-term path is no longer ambiguous: this repo should be built as a config-driven camera-control tool with explicit active-camera runtime targeting, fixture-driven `.testbed` validation, and trace-rich observability, while shared MediaPipe session reuse/ownership must be solved through `aerobeat-input-core` instead of private repo-local lifecycle logic.

---

*Completed on 2026-05-19*
