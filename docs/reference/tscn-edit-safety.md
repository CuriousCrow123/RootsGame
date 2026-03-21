# .tscn File Edit Safety Reference

Rules for when agents (or scripts) can safely edit Godot `.tscn` scene files directly.

---

## File Structure

A `.tscn` file has five sections that must appear in this order:

```
[gd_scene format=4 uid="uid://..."]        # 1. File descriptor (first line)

[ext_resource type="..." uid="..." path="..." id="..."]   # 2. External resources
[ext_resource ...]

[sub_resource type="..." id="..."]          # 3. Internal resources
property = value

[node name="..." type="..." parent="..."]   # 4. Nodes
property = value

[connection signal="..." from="..." to="..." method="..."]  # 5. Connections
```

**Ordering constraint:** Within sub_resources, a resource must be defined before it is referenced. If `SubResource("A")` is used in `SubResource("B")`'s properties, `A` must appear before `B`.

---

## Safe Edits

These edits have low corruption risk and are permitted:

| Edit Type | Example | Notes |
|-----------|---------|-------|
| Change property value on existing node | `collision_layer = 2` → `collision_layer = 4` | Any scalar, vector, color, enum |
| Change property value on existing sub_resource | `shading_mode = 0` → `shading_mode = 1` | Same as above |
| Remove a property line | Delete `visible = false` | Godot uses the type's default |
| Add a property to existing node/sub_resource | Add `cast_shadow = 0` to a MeshInstance3D | Must use correct property name and value format |
| Change transform values | Edit `Transform3D(...)` numbers | Repositioning/scaling existing nodes |
| Change resource references to existing IDs | `material = SubResource("A")` → `SubResource("B")` | Target ID must exist in the file |
| Change group membership | `groups=["saveable"]` → `groups=["saveable", "enemy"]` | On existing nodes |
| Fix or remove `load_steps` | Any value, or remove entirely | Godot 4.6 ignores this field |

**Key pattern:** If the entry (`[node]`, `[sub_resource]`, etc.) already exists and you're only changing values within it, the edit is safe.

---

## Dangerous Edits (Forbidden)

These edits have high corruption risk and must not be done by agents:

| Edit Type | Why It's Dangerous |
|-----------|--------------------|
| Add/remove `[ext_resource]` entries | ID strings must be unique (format: `"1_hgl0x"`). UIDs must match `.uid` sidecar files. Duplicates cause silent resource misloading. |
| Add/remove `[sub_resource]` entries | ID must be unique. Must appear before any reference to it. Wrong ordering = parse failure. |
| Add/remove `[node]` entries | Parent paths (`parent="Arm/Hand"`) must reference existing nodes. Wrong path = orphaned node or load failure. |
| Add/remove `[connection]` entries | Node paths must be valid. Wrong paths = silent signal failure. |
| Edit `PackedByteArray` data | Base64-encoded binary (vertex data, index buffers). One wrong character corrupts the mesh. |
| Change `uid="uid://..."` values | UIDs are Godot's file-tracking system. Wrong UIDs break cross-file references. |
| Change `unique_id` integers on nodes | Used for internal engine tracking. Duplicates cause instancing issues. |
| Reorder `[node]` entries | Node processing order and `index` depend on file order. |
| Change `format=` version | Godot may refuse to load or misparse. |

---

## Operational Notes

- **Godot open?** If the scene is loaded in the editor, external edits may be overwritten on next save. Either edit with Godot closed, or reload the scene after editing (Scene → Revert).
- **Default stripping:** Godot removes properties that match the type's default on save. If you set `shading_mode = 1` (the default for StandardMaterial3D), Godot will strip that line next time it saves the scene. This is normal, not corruption.
- **Validation:** After editing, open the scene in Godot. If it loads without errors in the Output panel, the edit was successful.

---

## Community Precedent

Editing `.tscn` files outside the editor is an established practice:

- **Godot docs** describe the format as "not only easy to read, it is also easy to generate" and cite programmatic generation as a use case.
- **godot_parser** (Python library by stevearc) is specifically built for loading, modifying, and writing `.tscn` files programmatically.
- **Git merge conflicts** in `.tscn` files are routinely resolved by hand — property-level conflicts are trivial, structural conflicts are where teams take one side entirely.
- **Godot 4.6 removed `load_steps`** specifically because it caused unnecessary git merge conflicts, acknowledging that developers work with these files directly.

---

## Sources

- [TSCN file format — Godot docs](https://docs.godotengine.org/en/stable/engine_details/file_formats/tscn.html)
- [godot_parser — Python .tscn parser](https://github.com/stevearc/godot_parser)
- [Remove load_steps — PR #103352](https://github.com/godotengine/godot/pull/103352)
- [Automatic .tscn merge conflict handling — Embla Flatlandsmo](https://emblaflatlandsmo.com/2025/01/27/automatic-handling-of-godot-tscn-merge-conflicts-in-git/)
