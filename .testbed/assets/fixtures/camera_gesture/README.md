# Camera Gesture Fixture Staging

This harness is structurally ready for prerecorded validation fixtures even though the actual recorded clips are not checked in yet.

## Intended layout

Store fixtures under feature folders using same-basename video + sidecar pairs:

- `head_pose/candidates/<name>.mp4`
- `head_pose/candidates/<name>.fixture.yaml`
- `head_pose/canonical/<name>.mp4`
- `head_pose/canonical/<name>.fixture.yaml`
- `head_pose/deprecated/<name>.mp4`
- `head_pose/deprecated/<name>.fixture.yaml`

Expected near-term feature families include head pose / look, lateral translation, and depth translation.

The current `.testbed` scene already exposes fixture key, video path, and sidecar path fields and includes those values in trace export manifests so the later replay/oracle slice can plug into the same harness surface.
