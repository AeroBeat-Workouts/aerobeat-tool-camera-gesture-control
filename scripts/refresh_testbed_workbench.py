#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


CACHE_GLOBS = [
    ".godot/global_script_class_cache.cfg",
    ".godot/editor/filesystem_cache*",
]

MEDIAPIPE_ADDON_KEY = "aerobeat-input-mediapipe-python"
MEDIAPIPE_PREP_RELATIVE_PATH = Path("python_mediapipe/prepare_runtime.py")
REQUIRED_RUNTIME_ARTIFACTS = [
    Path("runtime-manifest.json"),
    Path(".runtime-ready"),
    Path("venv/bin/python"),
]


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Refresh the repo-local .testbed workbench by restoring declared addons, pruning stale "
            "generated addon entries, clearing Godot class/index caches, optionally re-importing, "
            "and preparing the mounted MediaPipe runtime for local linux-x64 development."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=Path(__file__).resolve().parent.parent,
        type=Path,
        help="Repo root containing .testbed/ (defaults to this script's parent repo).",
    )
    parser.add_argument(
        "--platform",
        default="linux-x64",
        help="Runtime platform key passed through to the mounted addon prepare_runtime.py helper.",
    )
    parser.add_argument(
        "--mode",
        default="dev",
        choices=["dev", "release"],
        help="Runtime preparation mode passed through to the mounted addon helper.",
    )
    parser.add_argument(
        "--skip-install",
        action="store_true",
        help="Skip 'godotenv addons install'.",
    )
    parser.add_argument(
        "--skip-import",
        action="store_true",
        help="Skip headless Godot import after cache cleanup.",
    )
    parser.add_argument(
        "--skip-runtime-prep",
        action="store_true",
        help="Skip the mounted MediaPipe runtime prep step.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit machine-readable summary JSON.",
    )
    return parser.parse_args()


def _strip_jsonc_comments(raw_text: str) -> str:
    cleaned_lines: list[str] = []
    for line in raw_text.splitlines():
        in_string = False
        escaped = False
        result_chars: list[str] = []
        i = 0
        while i < len(line):
            char = line[i]
            if in_string:
                result_chars.append(char)
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == '"':
                    in_string = False
                i += 1
                continue

            if char == '"':
                in_string = True
                result_chars.append(char)
                i += 1
                continue

            if char == "/" and i + 1 < len(line) and line[i + 1] == "/":
                break

            result_chars.append(char)
            i += 1

        cleaned_lines.append("".join(result_chars))

    return "\n".join(cleaned_lines)


def _load_declared_addons(addons_jsonc_path: Path) -> set[str]:
    payload = json.loads(_strip_jsonc_comments(addons_jsonc_path.read_text()))
    addons = payload.get("addons", {})
    if not isinstance(addons, dict):
        raise SystemExit(f"Expected object at 'addons' in {addons_jsonc_path}")
    return set(addons.keys())


def _run(command: list[str], *, cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=cwd, text=True, capture_output=True, check=False)


def _remove_path(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
        return
    shutil.rmtree(path)


def _print_failure(summary: dict[str, object], result: subprocess.CompletedProcess[str] | None, *, json_mode: bool) -> None:
    if json_mode:
        print(json.dumps(summary, indent=2))
        return
    if result is not None:
        sys.stderr.write(result.stdout)
        sys.stderr.write(result.stderr)


def _extract_last_json_object(raw_stdout: str) -> dict[str, object] | None:
    stripped = raw_stdout.strip()
    if not stripped:
        return None

    candidates = [stripped]
    last_object_start = stripped.rfind("\n{")
    if last_object_start != -1:
        candidates.insert(0, stripped[last_object_start + 1 :])

    for candidate in candidates:
        try:
            parsed = json.loads(candidate)
        except json.JSONDecodeError:
            continue
        if isinstance(parsed, dict):
            return parsed
    return None


def main() -> int:
    args = _parse_args()
    repo_root = args.repo_root.resolve()
    testbed_root = repo_root / ".testbed"
    addons_jsonc_path = testbed_root / "addons.jsonc"
    addons_dir = testbed_root / "addons"

    if not testbed_root.exists():
        raise SystemExit(f"Missing testbed directory: {testbed_root}")
    if not addons_jsonc_path.exists():
        raise SystemExit(f"Missing addons manifest: {addons_jsonc_path}")

    summary: dict[str, object] = {
        "repo_root": str(repo_root),
        "testbed_root": str(testbed_root),
        "declared_addons": [],
        "reset_generated_addons": [],
        "removed_addons": [],
        "cleared_cache_files": [],
        "install": None,
        "import": None,
        "runtime_prep": None,
        "runtime_root": None,
        "verified_runtime_artifacts": [],
    }

    declared_addons = sorted(_load_declared_addons(addons_jsonc_path))
    summary["declared_addons"] = declared_addons

    if not args.skip_install:
        generated_cache_root = testbed_root / ".addons"
        reset_generated_addons: list[str] = []
        for addon_name in declared_addons:
            for base_dir in (addons_dir, generated_cache_root):
                generated_path = base_dir / addon_name
                if not generated_path.exists() and not generated_path.is_symlink():
                    continue
                _remove_path(generated_path)
                reset_generated_addons.append(str(generated_path.relative_to(repo_root)))
        summary["reset_generated_addons"] = reset_generated_addons

        install_result = _run(["godotenv", "addons", "install"], cwd=testbed_root)
        summary["install"] = {
            "command": "godotenv addons install",
            "returncode": install_result.returncode,
            "stdout": install_result.stdout,
            "stderr": install_result.stderr,
        }
        if install_result.returncode != 0:
            _print_failure(summary, install_result, json_mode=args.json)
            return install_result.returncode

    removed_addons: list[str] = []
    if addons_dir.exists():
        for entry in sorted(addons_dir.iterdir(), key=lambda p: p.name):
            if entry.name.startswith("."):
                continue
            if entry.name in declared_addons:
                continue
            _remove_path(entry)
            removed_addons.append(entry.name)
    summary["removed_addons"] = removed_addons

    cleared_cache_files: list[str] = []
    for pattern in CACHE_GLOBS:
        for cache_path in sorted(testbed_root.glob(pattern)):
            if cache_path.exists():
                cache_path.unlink()
                cleared_cache_files.append(str(cache_path.relative_to(repo_root)))
    summary["cleared_cache_files"] = cleared_cache_files

    if not args.skip_import:
        import_result = _run(
            ["godot", "--headless", "--path", str(testbed_root), "--import", "--quit-after", "1000"],
            cwd=repo_root,
        )
        summary["import"] = {
            "command": f"godot --headless --path {testbed_root} --import --quit-after 1000",
            "returncode": import_result.returncode,
            "stdout": import_result.stdout,
            "stderr": import_result.stderr,
        }
        if import_result.returncode != 0:
            _print_failure(summary, import_result, json_mode=args.json)
            return import_result.returncode

    if not args.skip_runtime_prep:
        mounted_addon_root = addons_dir / MEDIAPIPE_ADDON_KEY
        prepare_runtime_path = mounted_addon_root / MEDIAPIPE_PREP_RELATIVE_PATH
        if not mounted_addon_root.exists():
            raise SystemExit(
                f"Mounted addon is missing after refresh: {mounted_addon_root}. "
                "Run without --skip-install or inspect .testbed/addons.jsonc."
            )
        if not prepare_runtime_path.exists():
            raise SystemExit(
                f"Mounted addon runtime helper is missing: {prepare_runtime_path}. "
                "The downstream flow must use the addon-local documented entrypoint."
            )

        prep_command = [
            "python3",
            str(MEDIAPIPE_PREP_RELATIVE_PATH),
            "--platform",
            args.platform,
            "--mode",
            args.mode,
            "--install-requirements",
            "--validate",
            "--json",
        ]
        runtime_prep_result = _run(prep_command, cwd=mounted_addon_root)
        parsed_stdout = _extract_last_json_object(runtime_prep_result.stdout)

        summary["runtime_prep"] = {
            "command": " ".join(prep_command),
            "cwd": str(mounted_addon_root),
            "returncode": runtime_prep_result.returncode,
            "stdout": runtime_prep_result.stdout,
            "stderr": runtime_prep_result.stderr,
            "result": parsed_stdout,
        }
        if runtime_prep_result.returncode != 0:
            _print_failure(summary, runtime_prep_result, json_mode=args.json)
            return runtime_prep_result.returncode

        runtime_root = mounted_addon_root / "python_mediapipe" / "assets" / "runtimes" / args.platform
        summary["runtime_root"] = str(runtime_root)

        missing_artifacts: list[str] = []
        verified_runtime_artifacts: list[str] = []
        for relative_path in REQUIRED_RUNTIME_ARTIFACTS:
            absolute_path = runtime_root / relative_path
            if absolute_path.exists():
                verified_runtime_artifacts.append(str(absolute_path.relative_to(repo_root)))
            else:
                missing_artifacts.append(str(absolute_path.relative_to(repo_root)))
        summary["verified_runtime_artifacts"] = verified_runtime_artifacts

        if missing_artifacts:
            summary["missing_runtime_artifacts"] = missing_artifacts
            if args.json:
                print(json.dumps(summary, indent=2))
            else:
                for artifact in missing_artifacts:
                    sys.stderr.write(f"Missing required runtime artifact: {artifact}\n")
            return 1

    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        print(f"Refreshed testbed workbench at {testbed_root}")
        if summary["reset_generated_addons"]:
            print("Reset generated addon mounts/caches before reinstall:")
            for addon_path in summary["reset_generated_addons"]:
                print(f"- {addon_path}")
        else:
            print("Reset generated addon mounts/caches before reinstall: none")
        if removed_addons:
            print("Removed stale generated addons:")
            for addon in removed_addons:
                print(f"- {addon}")
        else:
            print("Removed stale generated addons: none")
        if cleared_cache_files:
            print("Cleared Godot caches:")
            for cache_file in cleared_cache_files:
                print(f"- {cache_file}")
        else:
            print("Cleared Godot caches: none")
        if summary["install"] is not None:
            print("Ran: godotenv addons install")
        if summary["import"] is not None:
            print("Ran: godot --headless --path .testbed --import --quit-after 1000")
        if summary["runtime_prep"] is not None:
            print(
                "Ran: python3 python_mediapipe/prepare_runtime.py --platform "
                f"{args.platform} --mode {args.mode} --install-requirements --validate --json"
            )
            print("Verified runtime artifacts:")
            for artifact in summary["verified_runtime_artifacts"]:
                print(f"- {artifact}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
