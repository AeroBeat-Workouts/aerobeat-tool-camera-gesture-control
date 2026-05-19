class_name CameraGestureFixtureRuntimeConfig
extends RefCounted

const DEFAULT_FIXTURE_KEY_PREFIX := "camera_gesture"
const VALID_SAMPLE_SOURCES := ["head_position", "head_velocity", "head_rotation"]

func resolve(video_path_text: String, sidecar_path_text: String) -> Dictionary:
	var sidecar := _resolve_path(sidecar_path_text, "")
	var sidecar_summary := _load_sidecar_summary(sidecar)
	var sidecar_video := _resolve_sidecar_video_path(sidecar, sidecar_summary)
	var explicit_video := _resolve_path(video_path_text, str(sidecar.get("resolved_path", "")))
	var effective_video := explicit_video
	var video_source_origin := "field"
	if not bool(explicit_video.get("exists", false)) and bool(sidecar_video.get("exists", false)):
		effective_video = sidecar_video
		video_source_origin = "sidecar"

	var fixture_key := _build_fixture_key(sidecar_summary)
	var sample_source_hint := str(sidecar_summary.get("preferred_sample_source", "")).strip_edges().to_lower()
	if not VALID_SAMPLE_SOURCES.has(sample_source_hint):
		sample_source_hint = ""

	return {
		"fixture_key": fixture_key,
		"video": explicit_video,
		"effective_video": effective_video,
		"effective_video_origin": video_source_origin,
		"sidecar": sidecar,
		"sidecar_summary": sidecar_summary,
		"sidecar_video": sidecar_video,
		"sample_source_hint": sample_source_hint,
		"runtime_ready": bool(effective_video.get("exists", false)),
	}

func _resolve_sidecar_video_path(sidecar: Dictionary, sidecar_summary: Dictionary) -> Dictionary:
	var authored_video_path := str(sidecar_summary.get("video_path", "")).strip_edges()
	var base_path := str(sidecar.get("resolved_path", ""))
	return _resolve_path(authored_video_path, base_path)

func _resolve_path(raw_path: String, relative_to_file_path: String) -> Dictionary:
	var normalized := raw_path.strip_edges()
	if normalized.is_empty():
		return {
			"raw_path": "",
			"display_path": "",
			"resolved_path": "",
			"exists": false,
		}

	var resolved := ""
	if normalized.begins_with("res://") or normalized.begins_with("user://"):
		resolved = ProjectSettings.globalize_path(normalized)
	elif normalized.begins_with("/"):
		resolved = normalized
	else:
		var relative_base := relative_to_file_path.strip_edges()
		if not relative_base.is_empty():
			resolved = relative_base.get_base_dir().path_join(normalized)
		else:
			var trimmed_relative := normalized.trim_prefix("./")
			resolved = ProjectSettings.globalize_path("res://%s" % trimmed_relative)

	return {
		"raw_path": normalized,
		"display_path": _display_path_for(resolved, normalized),
		"resolved_path": resolved,
		"exists": FileAccess.file_exists(resolved),
	}

func _display_path_for(resolved_path: String, fallback: String) -> String:
	var project_root := ProjectSettings.globalize_path("res://")
	if not resolved_path.is_empty() and resolved_path.begins_with(project_root):
		var relative := resolved_path.substr(project_root.length())
		return "res://%s" % relative
	return fallback if not fallback.is_empty() else resolved_path

func _load_sidecar_summary(sidecar: Dictionary) -> Dictionary:
	if not bool(sidecar.get("exists", false)):
		return {}
	var resolved_path := str(sidecar.get("resolved_path", ""))
	var file := FileAccess.open(resolved_path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	var summary := {
		"path": resolved_path,
		"display_path": str(sidecar.get("display_path", "")),
		"fixture_id": "",
		"family": "",
		"feature": "",
		"fixture_stage": "",
		"video_path": "",
		"preferred_sample_source": "",
		"primary_channel": "",
		"primary_axis": "",
		"semantic_direction": "",
		"expected_window_count": 0,
	}

	var section := ""
	for raw_line in text.split("\n"):
		var normalized_line := raw_line.replace("\t", "  ")
		var stripped_line := normalized_line.strip_edges()
		if stripped_line.is_empty() or stripped_line.begins_with("#"):
			continue
		var indent_count := normalized_line.length() - normalized_line.lstrip(" ").length()
		if indent_count == 0 and stripped_line.ends_with(":"):
			section = stripped_line.trim_suffix(":")
			continue
		if indent_count == 0:
			var root_pair := _split_key_value(stripped_line)
			if root_pair.is_empty():
				continue
			summary[root_pair["key"]] = root_pair["value"]
			section = ""
			continue
		if indent_count >= 2 and stripped_line.begins_with("- "):
			if section == "expected_windows":
				summary["expected_window_count"] = int(summary.get("expected_window_count", 0)) + 1
			continue
		var nested_pair := _split_key_value(stripped_line)
		if nested_pair.is_empty():
			continue
		match section:
			"video":
				if nested_pair["key"] == "path":
					summary["video_path"] = nested_pair["value"]
			"tuning_hints":
				if nested_pair["key"] == "preferred_sample_source":
					summary["preferred_sample_source"] = str(nested_pair["value"]).to_lower()
			"expected_controller":
				if nested_pair["key"] == "primary_channel":
					summary["primary_channel"] = nested_pair["value"]
				elif nested_pair["key"] == "primary_axis":
					summary["primary_axis"] = nested_pair["value"]
				elif nested_pair["key"] == "semantic_direction":
					summary["semantic_direction"] = nested_pair["value"]

	if str(summary.get("fixture_id", "")).is_empty():
		summary["fixture_id"] = resolved_path.get_file().trim_suffix(".fixture.yaml").trim_suffix(".yaml")
	if str(summary.get("feature", "")).is_empty():
		summary["feature"] = resolved_path.get_base_dir().get_base_dir().get_file()
	if str(summary.get("fixture_stage", "")).is_empty():
		summary["fixture_stage"] = resolved_path.get_base_dir().get_file()
	return summary

func _build_fixture_key(sidecar_summary: Dictionary) -> String:
	var family := str(sidecar_summary.get("family", "")).strip_edges()
	var feature := str(sidecar_summary.get("feature", "")).strip_edges()
	var fixture_id := str(sidecar_summary.get("fixture_id", "")).strip_edges()
	if fixture_id.is_empty():
		return "%s/manual/live" % DEFAULT_FIXTURE_KEY_PREFIX
	var parts: Array[String] = [DEFAULT_FIXTURE_KEY_PREFIX]
	if not feature.is_empty():
		parts.append(feature)
	if not family.is_empty() and family != DEFAULT_FIXTURE_KEY_PREFIX:
		parts.append(family)
	parts.append(fixture_id)
	return "/".join(parts)

func _split_key_value(line: String) -> Dictionary:
	var separator_index := line.find(":")
	if separator_index < 0:
		return {}
	var key := line.substr(0, separator_index).strip_edges()
	var value := line.substr(separator_index + 1).strip_edges()
	return {
		"key": key,
		"value": _parse_scalar(value),
	}

func _parse_scalar(raw_value: String) -> Variant:
	var trimmed := raw_value.strip_edges()
	if (trimmed.begins_with('"') and trimmed.ends_with('"')) or (trimmed.begins_with("'") and trimmed.ends_with("'")):
		return trimmed.substr(1, max(trimmed.length() - 2, 0))
	if trimmed.is_valid_int():
		return int(trimmed)
	if trimmed.is_valid_float():
		return float(trimmed)
	match trimmed.to_lower():
		"true":
			return true
		"false":
			return false
		"null":
			return null
	return trimmed
