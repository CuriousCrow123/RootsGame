---
paths:
  - "**/*.tscn"
---

Before editing any .tscn file, consult `docs/reference/tscn-edit-safety.md`.

**Safe:** Changing property values on existing nodes/sub_resources, removing properties, adding properties to existing entries.

**Forbidden:** Adding/removing `[ext_resource]`, `[sub_resource]`, `[node]`, or `[connection]` entries. Editing `PackedByteArray` data, `uid`, or `unique_id` values.
