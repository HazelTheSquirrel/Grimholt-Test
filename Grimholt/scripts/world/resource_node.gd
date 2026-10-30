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

func _add_material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = 0.82
    return material

func _add_mesh(mesh: Mesh, mesh_name: String, position: Vector3, material: Material) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = mesh_name
    instance.mesh = mesh
    instance.position = position
    instance.material_override = material
    add_child(instance)
    return instance

func _build_visuals() -> void:
    var collision := CollisionShape3D.new()
    if resource_id == "tree":
        var capsule := CapsuleShape3D.new()
        capsule.radius = 0.65
        capsule.height = 4.5
        collision.shape = capsule
        collision.position.y = 2.1
        var trunk_mesh := CylinderMesh.new()
        trunk_mesh.top_radius = 0.22
        trunk_mesh.bottom_radius = 0.38
        trunk_mesh.height = 3.0
        _add_mesh(trunk_mesh, "TreeTrunk", Vector3(0, 1.5, 0), _add_material(Color(0.30, 0.17, 0.09)))
        var foliage_material := _add_material(Color(0.12, 0.34, 0.14))
        var crown_mesh := SphereMesh.new()
        crown_mesh.radius = 1.25
        crown_mesh.height = 2.5
        _add_mesh(crown_mesh, "TreeCrown", Vector3(0, 3.35, 0), foliage_material)
        var crown_left := SphereMesh.new()
        crown_left.radius = 0.82
        crown_left.height = 1.65
        _add_mesh(crown_left, "TreeCrownLeft", Vector3(-0.72, 2.9, 0.12), foliage_material)
        var crown_right := SphereMesh.new()
        crown_right.radius = 0.78
        crown_right.height = 1.55
        _add_mesh(crown_right, "TreeCrownRight", Vector3(0.7, 3.0, -0.1), _add_material(Color(0.17, 0.40, 0.16)))
    elif resource_id == "iron_vein":
        var sphere := SphereShape3D.new()
        sphere.radius = 1.0
        collision.shape = sphere
        collision.position.y = 0.75
        var rock_mesh := SphereMesh.new()
        rock_mesh.radius = 0.9
        rock_mesh.height = 1.35
        _add_mesh(rock_mesh, "IronOreRock", Vector3(0, 0.7, 0), _add_material(Color(0.25, 0.30, 0.38), 0.45))
        var ore_crystal := PrismMesh.new()
        ore_crystal.size = Vector3(0.28, 0.85, 0.28)
        _add_mesh(ore_crystal, "IronOreCrystal", Vector3(0.2, 1.15, 0.05), _add_material(Color(0.78, 0.43, 0.20), 0.65))
    else:
        var sphere := SphereShape3D.new()
        sphere.radius = 0.5
        collision.shape = sphere
        collision.position.y = 0.5
        var stem := CylinderMesh.new()
        stem.top_radius = 0.035
        stem.bottom_radius = 0.06
        stem.height = 0.55
        _add_mesh(stem, "HerbStem", Vector3(0, 0.27, 0), _add_material(Color(0.18, 0.42, 0.16)))
        var flower := SphereMesh.new()
        flower.radius = 0.32
        flower.height = 0.52
        _add_mesh(flower, "HerbFlower", Vector3(0, 0.65, 0), _add_material(Color(0.72, 0.25, 0.68)))
        var center := SphereMesh.new()
        center.radius = 0.12
        center.height = 0.2
        _add_mesh(center, "HerbCenter", Vector3(0, 0.7, 0), _add_material(Color(0.98, 0.78, 0.28)))
    add_child(collision)

func harvest(target_inventory: GrimholtInventory) -> bool:
    if depleted or target_inventory == null:
        return false
    if not target_inventory.add_item(yield_item, yield_amount):
        return false
    depleted = true
    queue_free()
    return true
