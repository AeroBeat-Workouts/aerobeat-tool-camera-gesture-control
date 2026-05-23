# Gesture Testbed Mounted Runtime Prep

**Date:** 2026-05-22  
**Status:** In Progress  
**Agent:** Cookie 🍪

---

## Goal

Add the narrowest consumer-owned fix that lets `aerobeat-tool-camera-gesture-control/.testbed` restore and prepare its mounted `aerobeat-input-mediapipe-python` runtime so the real downstream live and replay testbed paths can start.

---

## Overview

The blocker is not a new vendor-runtime code defect in `aerobeat-input-mediapipe-python`. The real downstream consumer path in `aerobeat-tool-camera-gesture-control` is mounting that addon through GodotEnv as a fresh checkout under `.testbed/addons/aerobeat-input-mediapipe-python/`, and that mounted checkout currently lacks the generated Linux runtime contract files required by `AutoStartManager`: `runtime-manifest.json`, `.runtime-ready`, and `venv/bin/python`.

The narrowest honest fix therefore belongs in the downstream consumer repo. This repo already owns the actual acceptance surface and already tells developers to run `godotenv addons install`, but it does not yet own a truthful follow-up step that prepares the mounted MediaPipe runtime inside the installed addon. The fix should add a repo-owned refresh/prep workflow that (1) restores `.testbed` addons, (2) runs the mounted addon-local `python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --install-requirements --validate`, and (3) verifies the expected runtime files exist before downstream live/replay acceptance.

This should stay out of addon mirrors as a source-edit target. If owner-repo docs need future polish, that is separate. The immediate blocker-fix implementation slice is consumer-owned runtime-prep orchestration in `aerobeat-tool-camera-gesture-control`.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Downstream consumer repo README and current dev/test flow | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/README.md` |
| `REF-02` | Downstream consumer addon manifest showing mounted MediaPipe addon source | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/addons.jsonc` |
| `REF-03` | Owner-repo documented mounted-addon runtime-prep command and contract | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/README.md` |
| `REF-04` | Owner-repo runtime-prep entrypoint | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/prepare_runtime.py` |
| `REF-05` | Acceptance failure writeback naming the missing mounted runtime files | `/home/derrick/.openclaw/workspace/projects/openclaw-cookie/.plans/aerobeat-architecture/2026-05-22-gesture-testbed-full-parity.md` |

---

## Tasks

### Task 1: Implement consumer-owned mounted runtime refresh/prep flow

**Bead ID:** `aerobeat-tool-camera-gesture-control-d0v`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control`, claim `aerobeat-tool-camera-gesture-control-d0v` on start. Implement the narrowest repo-owned fix for the downstream mounted-runtime blocker: add a repo-owned refresh/prep workflow that restores `.testbed` addons and prepares the mounted `aerobeat-input-mediapipe-python` runtime locally for Linux dev acceptance using the mounted addon’s documented `prepare_runtime.py --platform linux-x64 --mode dev --install-requirements --validate` flow. Verify the expected runtime files exist under `.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/`. Do not patch `/addons/` mirrors directly except through the mounted addon-local runtime generation flow itself. Update README/docs/scripts as needed, run relevant repo-local validation, and leave the repo honestly ready for downstream live+replay startup verification.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/README.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/scripts/refresh_testbed_workbench.py`

**Status:** ✅ Complete

**Results:** Implemented a repo-owned consumer refresh/prep workflow in `scripts/refresh_testbed_workbench.py` and documented it in `README.md`. The script mirrors the existing AeroBeat workbench-refresh pattern, then extends it narrowly for this consumer lane: it restores declared `.testbed` addons, proactively discards generated `.testbed/addons/*` and `.testbed/.addons/*` mirrors for declared addons before reinstall so reruns do not fail on consumer-mirror drift, prunes stale generated addon entries, clears Godot caches, re-imports `.testbed`, runs the mounted addon’s documented `python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --install-requirements --validate --json` command from `/.testbed/addons/aerobeat-input-mediapipe-python/`, and verifies the required runtime artifacts under the mounted addon path.

During validation, the first full rerun exposed a real downstream reinstall hazard: `godotenv addons install` refused to refresh `aerobeat-input-core` because a generated `.uid` file inside the consumer mirror made that mounted addon look modified. The workflow was updated to reset generated declared-addon mounts/caches before reinstall, which stays strictly consumer-owned and avoids inventing upstream runtime changes.

Actual downstream validation then passed: the full refresh/prep workflow completed successfully, the mounted runtime reported `validation_status: "ready"`, the required `runtime-manifest.json`, `.runtime-ready`, and `venv/bin/python` files now exist under `/.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/`, and repo-local GUT validation passed `39/39`. Reference IDs validated: `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`.

---

### Task 2: QA the downstream mounted runtime refresh/prep flow

**Bead ID:** `aerobeat-tool-camera-gesture-control-6jg`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control`, claim `aerobeat-tool-camera-gesture-control-6jg` after Task 1 is ready. Independently rerun the consumer-owned refresh/prep flow from a realistic downstream state and verify the mounted addon runtime becomes usable for live and replay startup prerequisites. Confirm `runtime-manifest.json`, `.runtime-ready`, and `venv/bin/python` exist under the mounted addon path, and confirm mounted-addon validation passes from that location.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/`
- downstream generated `.testbed/addons/` runtime state as part of validation

**Files Created/Deleted/Modified:**
- plan writeback only unless QA finds a real gap

**Status:** ✅ Complete

**Results:** Independently QA-verified from a realistic dirty downstream state. First, I reproduced the generated-addon reinstall hazard directly by creating `.testbed/addons/aerobeat-input-core/.qa-hazard/generated.uid` and rerunning bare `godotenv addons install` inside `/.testbed/`; GodotEnv failed exactly on consumer-mirror drift with `Cannot delete modified addon aerobeat-input-core` and reported the dirty generated paths (`?? .qa-hazard/`, `?? src/runtime/provider_session_registry.gd.uid`). Then I ran the repo-owned workflow exactly as documented: `python3 scripts/refresh_testbed_workbench.py --json`.

That QA rerun passed end-to-end. The workflow reset all declared generated mounts/caches before reinstall (`.testbed/addons/*` plus `.testbed/.addons/*` for `aerobeat-input-core`, `aerobeat-input-mediapipe-python`, `aerobeat-tool-core`, `aerobeat-tool-headless-manager`, and `gut`), completed mounted runtime prep with `validation_status: "ready"`, and verified the required linux-x64 artifacts under the mounted addon path:
- `/.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/runtime-manifest.json`
- `/.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/.runtime-ready`
- `/.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/venv/bin/python`

Post-workflow evidence:
- the injected hazard file no longer existed afterward (`Hazard file exists after workflow? NO`)
- the documented downstream repo-local GUT suite passed cleanly with `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`
- GUT result: `39/39` passing, `233` asserts

No QA gaps found for this bead. References validated in the real downstream consumer path: `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`. 

---

### Task 3: Audit ownership and readiness of the mounted runtime blocker fix

**Bead ID:** `aerobeat-tool-camera-gesture-control-8cv`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control`, claim `aerobeat-tool-camera-gesture-control-8cv` after QA. Audit that the implemented fix is still the narrowest honest consumer-owned change, that it does not smuggle source edits into addon mirrors, and that the downstream gesture testbed is truly ready for real live+replay startup verification once the prep flow runs.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.plans/`

**Files Created/Deleted/Modified:**
- plan writeback only unless audit finds a real gap

**Status:** ✅ Complete

**Results:** Independently audited the downstream workflow against the plan, commit `f16682c`, QA writeback, and current repo state. First verified the bead was genuinely ready (`bd dep tree aerobeat-tool-camera-gesture-control-8cv` reported `[READY]`) before claiming it. Then confirmed scope stayed consumer-owned by diffing `6239e2b..f16682c`: only `README.md`, `scripts/refresh_testbed_workbench.py`, and this repo-local plan changed; there were no upstream runtime source edits in the consumer-fix commit.

I then re-ran the workflow from an intentionally dirty downstream state I created myself: injected generated-addon hazard files under both `/.testbed/addons/aerobeat-input-core/.audit-hazard/generated.uid` and `/.testbed/.addons/aerobeat-input-core/.audit-cache-hazard/generated.uid`, added a stale generated addon directory `/.testbed/addons/zzz-audit-stale/`, and removed the mounted MediaPipe runtime root `/.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/` before executing `python3 scripts/refresh_testbed_workbench.py --json`.

Observed audit evidence from the real run:
- the workflow reset every declared generated addon mirror/cache before reinstall (`reset_generated_addons` listed all five declared addons under both `/.testbed/addons/` and `/.testbed/.addons/`)
- `godotenv addons install` returned `0`
- the stale generated addon entry was pruned (`removed_addons: ["zzz-audit-stale"]`)
- Godot import returned `0` after cache cleanup
- mounted runtime prep ran from the mounted addon’s documented entrypoint `python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --install-requirements --validate --json` and returned `validation_status: "ready"`
- the required runtime artifacts were present afterward under the mounted addon path:
  - `/.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/runtime-manifest.json`
  - `/.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/.runtime-ready`
  - `/.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/venv/bin/python`
- the injected reinstall-hazard files were gone afterward (`addon-hazard:cleared`, `cache-hazard:cleared`)
- the downstream repo-local GUT suite still passed after the workflow: `39/39` passing, `233` asserts
- the mounted addon checkout itself showed no tracked-source drift after the run (`git status --short` inside `/.testbed/addons/aerobeat-input-mediapipe-python/` was empty)

Audit note: the implementation is correct, but the README’s “does four things in order” bullets currently describe `godotenv addons install` before the mirror reset even though the script resets declared generated mirrors/caches before reinstall. That is a documentation-order nit, not a blocker for this bead’s planned scope. For the planned slice itself, the downstream consumer-owned workflow is genuinely complete and honest. References validated through audit: `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** `aerobeat-tool-camera-gesture-control` now owns a truthful downstream refresh/prep workflow in `scripts/refresh_testbed_workbench.py` plus matching README guidance. Running that workflow from the consumer repo restores the `.testbed` addon mounts, resets generated declared-addon mirrors/caches before reinstall, clears import caches, re-imports `.testbed`, invokes the mounted MediaPipe addon’s documented runtime-prep command in place, and verifies the required linux-x64 runtime artifacts under the mounted addon path.

**Reference Check:** `REF-03` and `REF-04` were satisfied directly by using the mounted addon’s documented `prepare_runtime.py --platform linux-x64 --mode dev --install-requirements --validate` path instead of inventing a new upstream code path. `REF-05` is addressed in the real downstream consumer path because the previously missing mounted runtime files were restored and re-verified under `/.testbed/addons/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/` during audit. `REF-01` and `REF-02` are reflected in the consumer repo’s owned workflow and docs. Audit also verified commit scope stayed in downstream consumer orchestration only (`README.md`, `scripts/refresh_testbed_workbench.py`, and the repo-local plan), with no upstream runtime source edits broadened into this slice.

**Commits:**
- `f16682c` - Add testbed runtime refresh workflow

**Lessons Learned:** The honest downstream failure mode was broader than “run prepare_runtime again.” A repeatable consumer-owned workflow also needed to reset generated addon mirrors before reinstall, because GodotEnv can refuse refreshes when consumer-generated `.uid` drift makes mounted addons look modified. Also, the workflow behavior is right but the README’s ordered step list slightly misstates when the reset happens; that is a small documentation follow-up, not a blocker for mounted-runtime readiness.

---

*Prepared on 2026-05-22*
