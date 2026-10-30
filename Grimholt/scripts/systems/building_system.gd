extends Node3D
class_name GrimholtBuildingSystem

const GRID_SIZE := 3.0
const PIECES := {
    "foundation": {"name": "Holzfundament", "cost": {"wooden_plank": 6}, "size": Vector3(3.0, 0.25, 3.0), "offset": 0.125, "color": Color(0.38, 0.25, 0.14)},
    "wall": {"name": "Holzwand", "cost": {"wooden_plank": 4}, "size": Vector3(3.0, 2.4, 0.2), "offset": 1.325, "color": Color(0.48, 0.32, 0.18)},
    "roof": {"name": "Dachsegment", "cost": {"wooden_plank": 3}, "size": Vector3(3.2, 0.2, 3.2), "offset": 2.625, "color": Color(0.25, 0.20, 0.16)}
}

func place_piece(piece_id: String, hit_position: Vector3, inventory: GrimholtInventory) -> bool:
    if not PIECES.has(piece_id) or inventory == null:
        return false
    var cost: Dictionary = PIECES[piece_id]["cost"]
    if not inventory.has_items(cost):
        return false
    if not _create_piece(piece_id, hit_position):
        return false
    return inventory.remove_items(cost)

func _create_piece(piece_id: String, hit_position: Vector3) -> bool:
    if not PIECES.has(piece_id):
        return false
    var definition: Dictionary = PIECES[piece_id]
    var snapped := Vector3(round(hit_position.x / GRID_SIZE) * GRID_SIZE, hit_position.y, round(hit_position.z / GRID_SIZE) * GRID_SIZE)
    var body := StaticBody3D.new()
    body.name = String(definition["name"])
    body.set_meta("piece_id", piece_id)
    body.set_meta("build_position", snapped)
    body.position = snapped + Vector3.UP * float(definition["offset"])
    body.collision_layer = 1
    var mesh_instance := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = definition["size"]
    mesh_instance.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = definition["color"]
    material.roughness = 0.94
    material.uv1_triplanar = true
    material.uv1_scale = Vector3(0.7, 0.7, 0.7)
    mesh_instance.material_override = material
    body.add_child(mesh_instance)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = definition["size"]
    collision.shape = shape
    body.add_child(collision)
    add_child(body)
    return true

func get_save_data() -> Array[Dictionary]:
    var saved: Array[Dictionary] = []
    for child in get_children():
        if child is StaticBody3D and child.has_meta("piece_id") and child.has_meta("build_position"):
            var position: Vector3 = child.get_meta("build_position")
            saved.append({
                "piece": String(child.get_meta("piece_id")),
                "position": [position.x, position.y, position.z]
            })
    return saved

func restore_from_save(saved_pieces: Variant) -> bool:
    if not saved_pieces is Array:
        return false
    for entry in saved_pieces:
        if not entry is Dictionary or not PIECES.has(String(entry.get("piece", ""))):
            return false
        var coordinates: Variant = entry.get("position", [])
        if not coordinates is Array or coordinates.size() != 3:
            return false
        for coordinate in coordinates:
            if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)):
                return false
    for child in get_children():
        child.free()
    for entry in saved_pieces:
        var coordinates: Array = entry["position"]
        var position := Vector3(float(coordinates[0]), float(coordinates[1]), float(coordinates[2]))
        _create_piece(String(entry["piece"]), position)
    return true
