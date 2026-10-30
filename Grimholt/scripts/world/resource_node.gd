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

func _textured_material(base_color: Color, noise_scale: float = 0.12, metallic_value: float = 0.0) -> StandardMaterial3D:
    var noise := FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    noise.frequency = noise_scale
    noise.fractal_octaves = 3
    var texture := NoiseTexture2D.new()
    texture.width = 128
    texture.height = 128
    texture.noise = noise
    var material := StandardMaterial3D.new()
    material.albedo_color = base_color
    material.albedo_texture = texture
    material.uv1_triplanar = true
    material.uv1_scale = Vector3(1.5, 1.5, 1.5)
    material.metallic = metallic_value
    material.roughness = 0.88
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
        var trunk_shape := CapsuleShape3D.new()
        trunk_shape.radius = 0.42
        trunk_shape.height = 7.4
        collision.shape = trunk_shape
        collision.position.y = 3.7
        var trunk := CylinderMesh.new()
        trunk.top_radius = 0.28
        trunk.bottom_radius = 0.48
        trunk.height = 7.4
        _add_mesh(trunk, "TreeTrunk", Vector3(0, 3.7, 0), _textured_material(Color(0.30, 0.18, 0.10), 0.2))
        var foliage := _textured_material(Color(0.12, 0.30, 0.12), 0.07)
        var crown := SphereMesh.new()
        crown.radius = 2.4
        crown.height = 4.2
        _add_mesh(crown, "TreeCrown", Vector3(0, 8.0, 0), foliage)
        var crown_left := SphereMesh.new()
        crown_left.radius = 1.65
        crown_left.height = 3.1
        _add_mesh(crown_left, "TreeCrownLeft", Vector3(-1.35, 7.25, 0.45), foliage)
        var crown_right := SphereMesh.new()
        crown_right.radius = 1.7
        crown_right.height = 3.2
        _add_mesh(crown_right, "TreeCrownRight", Vector3(1.25, 7.4, -0.35), _textured_material(Color(0.17, 0.36, 0.14), 0.09))
    elif resource_id == "iron_vein":
        var sphere := SphereShape3D.new()
        sphere.radius = 1.1
        collision.shape = sphere
        collision.position.y = 0.8
        var rock_mesh := SphereMesh.new()
        rock_mesh.radius = 1.0
        rock_mesh.height = 1.5
        _add_mesh(rock_mesh, "IronOreRock", Vector3(0, 0.75, 0), _textured_material(Color(0.25, 0.29, 0.34), 0.16, 0.2))
        var ore_crystal := PrismMesh.new()
        ore_crystal.size = Vector3(0.35, 1.0, 0.35)
        _add_mesh(ore_crystal, "IronOreCrystal", Vector3(0.25, 1.2, 0.05), _textured_material(Color(0.68, 0.39, 0.22), 0.2, 0.55))
    elif resource_id == "shrub":
        var shrub_shape := SphereShape3D.new()
        shrub_shape.radius = 0.65
        collision.shape = shrub_shape
        collision.position.y = 0.55
        var shrub_material := _textured_material(Color(0.16, 0.32, 0.13), 0.09)
        for index in range(3):
            var leaf := SphereMesh.new()
            leaf.radius = 0.62
            leaf.height = 0.95
            var offset := Vector3(float(index - 1) * 0.42, 0.55 + (0.12 if index == 1 else 0.0), 0.0)
            _add_mesh(leaf, "ShrubLeaf%d" % index, offset, shrub_material)
    else:
        var herb_shape := SphereShape3D.new()
        herb_shape.radius = 0.5
        collision.shape = herb_shape
        collision.position.y = 0.5
        var stem := CylinderMesh.new()
        stem.top_radius = 0.035
        stem.bottom_radius = 0.06
        stem.height = 0.55
        _add_mesh(stem, "HerbStem", Vector3(0, 0.27, 0), _textured_material(Color(0.18, 0.42, 0.16)))
        var flower := SphereMesh.new()
        flower.radius = 0.32
        flower.height = 0.52
        _add_mesh(flower, "HerbFlower", Vector3(0, 0.65, 0), _textured_material(Color(0.72, 0.25, 0.68)))
        var center := SphereMesh.new()
        center.radius = 0.12
        center.height = 0.2
        _add_mesh(center, "HerbCenter", Vector3(0, 0.7, 0), _textured_material(Color(0.98, 0.78, 0.28)))
    add_child(collision)

func harvest(target_inventory: GrimholtInventory) -> bool:
    if depleted or target_inventory == null or yield_item.is_empty() or yield_amount <= 0:
        return false
    if not target_inventory.add_item(yield_item, yield_amount):
        return false
    depleted = true
    queue_free()
    return true
