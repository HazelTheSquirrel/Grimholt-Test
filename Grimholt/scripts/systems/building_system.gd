extends Node3D
class_name GrimholtBuildingSystem

const PIECES := {
    "foundation": {"name": "Holzfundament", "cost": {"wooden_plank": 4}, "size": Vector3(2.0, 0.25, 2.0), "offset": 0.125, "color": Color(0.38, 0.25, 0.14)},
    "wall": {"name": "Holzwand", "cost": {"wooden_plank": 3}, "size": Vector3(2.0, 2.5, 0.2), "offset": 1.25, "color": Color(0.48, 0.32, 0.18)},
    "roof": {"name": "Dachsegment", "cost": {"wooden_plank": 2}, "size": Vector3(2.2, 0.2, 2.2), "offset": 2.55, "color": Color(0.25, 0.20, 0.16)}
}

func place_piece(piece_id: String, hit_position: Vector3, inventory: GrimholtInventory) -> bool:
    if not PIECES.has(piece_id) or inventory == null:
        return false
    var definition: Dictionary = PIECES[piece_id]
    var cost: Dictionary = definition["cost"]
    if not inventory.remove_items(cost):
        return false
    var size: Vector3 = definition["size"]
    var snapped := Vector3(round(hit_position.x / 2.0) * 2.0, hit_position.y, round(hit_position.z / 2.0) * 2.0)
    var body := StaticBody3D.new()
    body.name = String(definition["name"])
    body.position = snapped + Vector3.UP * float(definition["offset"])
    body.collision_layer = 1
    var mesh_instance := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh_instance.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = definition["color"]
    material.roughness = 0.9
    mesh_instance.material_override = material
    body.add_child(mesh_instance)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    add_child(body)
    return true
