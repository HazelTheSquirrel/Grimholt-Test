extends StaticBody3D
class_name GrimholtResourceNode

var resource_id: String = ""
var yield_item: String = ""
var yield_amount: int = 1
var display_name: String = ""
var depleted: bool = false

func configure(id: String, label: String, item_id: String, amount: int) -> void:
    resource_id = id
    display_name = label
    yield_item = item_id
    yield_amount = amount
    collision_layer = 1
    collision_mask = 1
    _build_visuals()

func _build_visuals() -> void:
    var collision := CollisionShape3D.new()
    if resource_id == "tree":
        var capsule := CapsuleShape3D.new()
        capsule.radius = 0.65
        capsule.height = 4.5
        collision.shape = capsule
        collision.position.y = 2.1
        var trunk := MeshInstance3D.new()
        var trunk_mesh := CylinderMesh.new()
        trunk_mesh.top_radius = 0.22
        trunk_mesh.bottom_radius = 0.38
        trunk_mesh.height = 3.0
        trunk.mesh = trunk_mesh
        trunk.position.y = 1.5
        var trunk_material := StandardMaterial3D.new()
        trunk_material.albedo_color = Color(0.28, 0.16, 0.09)
        trunk.material_override = trunk_material
        add_child(trunk)
        var crown := MeshInstance3D.new()
        var crown_mesh := SphereMesh.new()
        crown_mesh.radius = 1.35
        crown_mesh.height = 2.7
        crown.mesh = crown_mesh
        crown.position.y = 3.5
        var leaf_material := StandardMaterial3D.new()
        leaf_material.albedo_color = Color(0.12, 0.29, 0.13)
        leaf_material.roughness = 1.0
        crown.material_override = leaf_material
        add_child(crown)
    elif resource_id == "iron_vein":
        var sphere := SphereShape3D.new()
        sphere.radius = 0.9
        collision.shape = sphere
        collision.position.y = 0.8
        var ore := MeshInstance3D.new()
        var ore_mesh := SphereMesh.new()
        ore_mesh.radius = 0.85
        ore_mesh.height = 1.4
        ore.mesh = ore_mesh
        ore.position.y = 0.8
        var ore_material := StandardMaterial3D.new()
        ore_material.albedo_color = Color(0.30, 0.34, 0.39)
        ore_material.metallic = 0.55
        ore_material.roughness = 0.72
        ore.material_override = ore_material
        add_child(ore)
    else:
        var sphere := SphereShape3D.new()
        sphere.radius = 0.45
        collision.shape = sphere
        collision.position.y = 0.45
        var plant := MeshInstance3D.new()
        var plant_mesh := SphereMesh.new()
        plant_mesh.radius = 0.42
        plant_mesh.height = 0.8
        plant.mesh = plant_mesh
        plant.position.y = 0.45
        var plant_material := StandardMaterial3D.new()
        plant_material.albedo_color = Color(0.25, 0.55, 0.22)
        plant.material_override = plant_material
        add_child(plant)
    add_child(collision)

func harvest(target_inventory: GrimholtInventory) -> bool:
    if depleted or target_inventory == null:
        return false
    if not target_inventory.add_item(yield_item, yield_amount):
        return false
    depleted = true
    queue_free()
    return true
