extends SceneTree

const InventoryScript = preload("res://scripts/systems/inventory.gd")
const ProfessionScript = preload("res://scripts/systems/profession_system.gd")
const CraftingScript = preload("res://scripts/systems/crafting_system.gd")
const ResourceNodeScript = preload("res://scripts/world/resource_node.gd")
const BuildingScript = preload("res://scripts/systems/building_system.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/main.tscn") as PackedScene
    if packed == null:
        _fail("Main scene could not be loaded.")
        return
    var scene := packed.instantiate()
    var capsule := scene.get_node("Player/CollisionShape3D").shape as CapsuleShape3D
    var world_environment := scene.get_node("WorldEnvironment") as WorldEnvironment
    if world_environment == null or world_environment.environment == null:
        _fail("Main scene has no editor-assigned world environment.")
        scene.free()
        return
    if capsule == null or not is_equal_approx(capsule.height, 1.70) or not is_equal_approx(capsule.radius, 0.30):
        _fail("Player capsule is not at the documented 1.70 m human scale.")
        scene.free()
        return
    scene.free()

    var live_scene := packed.instantiate()
    root.add_child(live_scene)
    var terrain_at_spawn := live_scene.get_node("TerrainWorld") as GrimholtTerrainWorld
    var player_at_spawn := live_scene.get_node("Player") as GrimholtPlayer
    if absf(player_at_spawn.global_position.y - terrain_at_spawn.height_at(0.0, 0.0) - 0.20) > 0.01:
        _fail("Player did not start at the configured safe terrain spawn height.")
        return
    var initial_spawn_chunk: Node3D = terrain_at_spawn.active_chunks.get(Vector2i.ZERO)
    if initial_spawn_chunk == null or initial_spawn_chunk.get_node_or_null("TerrainCollision") == null:
        _fail("Spawn chunk collision was not built synchronously before player spawn.")
        return
    for frame in range(125):
        await physics_frame
    var live_player := live_scene.get_node("Player") as GrimholtPlayer
    var terrain_for_spawn := live_scene.get_node("TerrainWorld") as GrimholtTerrainWorld
    var spawn_chunk: Node3D = terrain_for_spawn.active_chunks.get(Vector2i.ZERO)
    if spawn_chunk == null or spawn_chunk.get_node_or_null("TerrainCollision") == null:
        _fail("Spawn chunk collision was not built synchronously before player spawn.")
        return
    var texture_paths := [
        "res://assets/textures/grass_meadow.svg",
        "res://assets/textures/forest_moss.svg",
        "res://assets/textures/rock_slate.svg",
        "res://assets/textures/earth_dirt.svg",
        "res://assets/textures/gravel_sand.svg",
        "res://assets/textures/snow_ice.svg",
        "res://assets/textures/bark_wood.svg",
        "res://assets/textures/leaves_canopy.svg",
        "res://assets/textures/sky_dawn_panorama.svg"
    ]
    for texture_path in texture_paths:
        if not ResourceLoader.exists(texture_path) or ResourceLoader.load(texture_path) == null:
            _fail("Seamless texture asset failed to load: " + texture_path)
            return
    var terrain_material := ResourceLoader.load("res://assets/materials/terrain_grass.tres") as ShaderMaterial
    if terrain_material == null or terrain_material.shader == null:
        _fail("Terrain biome shader material failed to load.")
        return
    for shader_texture in ["grass_texture", "moss_texture", "rock_texture", "dirt_texture", "snow_texture"]:
        if terrain_material.get_shader_parameter(shader_texture) == null:
            _fail("Terrain shader is missing texture parameter: " + shader_texture)
            return
    var sky_resource := ResourceLoader.load("res://environment/world_environment.tres") as Environment
    if sky_resource == null or sky_resource.sky == null or not sky_resource.sky.sky_material is PanoramaSkyMaterial:
        _fail("Custom panoramic sky material failed to load.")
        return
    for material_path in ["res://assets/materials/terrain_rock.tres", "res://assets/materials/wood_bark.tres", "res://assets/materials/foliage_leaves.tres"]:
        if not ResourceLoader.exists(material_path) or not ResourceLoader.load(material_path) is StandardMaterial3D:
            _fail("World material failed to load: " + material_path)
            return
    if live_player == null or not live_player.is_on_floor():
        _fail("Live player did not reach the terrain before interaction.")
        return
    var live_terrain := live_scene.get_node("TerrainWorld")
    if live_terrain.active_chunks.size() != 9:
        _fail("World streaming did not generate the expected 3x3 chunk neighborhood.")
        return
    if not is_equal_approx(live_terrain.WORLD_AREA_KM2, 10000.0) or not is_equal_approx(live_terrain.WORLD_SIZE_METERS, 100000.0):
        _fail("World dimensions do not represent 10,000 km².")
        return
    var center_height := live_terrain.height_at(0.0, 0.0)
    var mountain_height := live_terrain.height_at(42000.0, -31000.0)
    if absf(mountain_height - center_height) < 20.0:
        _fail("Procedural continental relief has insufficient elevation variation.")
        return
    var foliage_found := false
    for chunk in live_terrain.generated_root.get_children():
        if chunk.get_node_or_null("ForestCanopies") != null and chunk.get_node_or_null("GrassCover") != null:
            foliage_found = true
            break
    if not foliage_found:
        _fail("Chunk foliage and ground cover were not generated.")
        return
    var river_chunk: Node3D = live_terrain._create_chunk(12, 0)
    if river_chunk.get_node_or_null("RiverWater") == null:
        _fail("River corridor chunk is missing its water surface.")
        river_chunk.free()
        return
    river_chunk.free()
    var distant_chunk: Node3D = live_terrain._create_chunk(3, -2)
    if distant_chunk.get_node_or_null("MountainWaterfall") == null or distant_chunk.get_node_or_null("Landmark_watchtower_ruin") == null:
        _fail("Waterfall or watchtower ruin landmark was not generated.")
        distant_chunk.free()
        return
    distant_chunk.free()
    var dungeon_chunk: Node3D = live_terrain._create_chunk(-7, -4)
    var cave := dungeon_chunk.find_child("WalkableCaveInterior", true, false)
    if cave == null or cave.find_child("CaveFloorCollision_00", true, false) == null:
        _fail("Dungeon cave interior or walkable floor collision is missing.")
        dungeon_chunk.free()
        return
    dungeon_chunk.free()
    var harvest_key := InputEventKey.new()
    harvest_key.keycode = KEY_E
    harvest_key.pressed = true
    live_player._unhandled_input(harvest_key)
    if live_player.inventory.get_item_count("wood") != 4:
        _fail("Starter oak harvest did not add the configured four wood to the live player inventory.")
        return
    var live_environment := live_scene.get_node("WorldEnvironment") as WorldEnvironment
    if live_environment.environment.sky == null or not live_environment.environment.volumetric_fog_enabled:
        _fail("Runtime environment setup replaced or damaged the editor-assigned sky resource.")
        return
    if not live_player.inventory.add_item("wooden_plank", 6):
        _fail("Could not prepare save/load building regression test.")
        return
    live_player.professions.add_experience("carpentry", 125)
    if not live_player.building_system.place_piece("foundation", Vector3(3.0, 0.0, 3.0), live_player.inventory):
        _fail("Could not place a foundation before saving.")
        return
    var saved_position := Vector3(8.0, live_terrain.height_at(8.0, 9.0) + 0.20, 9.0)
    live_player.global_position = saved_position
    if not bool(live_scene.call("_save_game", false)):
        _fail("Save manager failed to write a valid game snapshot.")
        return
    live_player.global_position = Vector3(-20.0, 30.0, -20.0)
    live_player.inventory.set_items_from_save({})
    live_player.professions.set_experience_from_save({})
    live_player.building_system.restore_from_save([])
    if not bool(live_scene.call("_load_game", false)):
        _fail("Save manager failed to restore a valid game snapshot.")
        return
    if not live_player.global_position.is_equal_approx(saved_position):
        _fail("Save/load did not restore the player position.")
        return
    if live_player.inventory.get_item_count("wood") != 4 or live_player.inventory.get_item_count("wooden_plank") != 0:
        _fail("Save/load did not restore the exact inventory snapshot.")
        return
    if live_player.professions.get_experience("carpentry") != 125:
        _fail("Save/load did not restore profession experience.")
        return
    if live_player.building_system.get_child_count() != 1:
        _fail("Save/load did not restore the placed foundation.")
        return
    # A legacy save can contain a position buried below the current terrain. Loading it
    # must recover to the guaranteed spawn instead of restoring the invalid coordinates.
    var underground_save_position := Vector3(0.0, live_terrain.height_at(0.0, 0.0) - 25.0, 0.0)
    live_player.global_position = underground_save_position
    if not bool(live_scene.call("_save_game", false)):
        _fail("Could not create the underground-save regression fixture.")
        return
    if not bool(live_scene.call("_load_game", false)):
        _fail("Save manager rejected the underground-save recovery fixture.")
        return
    if not live_player.global_position.is_equal_approx(live_terrain.get_safe_spawn_position()):
        _fail("Loading an underground save did not recover the player to the terrain spawn.")
        return
    if not live_terrain.has_resource_id("tree_00"):
        _fail("Starter resource does not have a stable world identity.")
        return
    for world_child in live_terrain.get_children():
        if world_child is GrimholtResourceNode and world_child.persistent_id == "tree_00" and not world_child.is_queued_for_deletion():
            _fail("Save/load respawned a resource already harvested in this world.")
            return
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://grimholt_save.json"))
    live_scene.queue_free()
    await process_frame

    var inventory: GrimholtInventory = InventoryScript.new()
    var professions: GrimholtProfessionSystem = ProfessionScript.new()
    if inventory.add_item("not_an_item", 1) or inventory.add_item("wood", 0) or inventory.add_item("wood", -1):
        _fail("Inventory accepted an unknown item or invalid amount.")
        return

    if not inventory.add_item("wood", 2) or not CraftingScript.craft("wooden_plank", inventory, professions):
        _fail("Carpentry recipe failed with sufficient materials.")
        return
    if inventory.get_item_count("wooden_plank") != 3 or professions.get_experience("carpentry") != 10:
        _fail("Carpentry recipe output or experience is incorrect.")
        return

    if not inventory.add_item("herb", 2) or not CraftingScript.craft("healing_potion", inventory, professions):
        _fail("Alchemy recipe failed with sufficient materials.")
        return
    if inventory.get_item_count("healing_potion") != 1 or professions.get_experience("alchemy") != 20:
        _fail("Alchemy recipe output or experience is incorrect.")
        return

    if not inventory.add_item("iron_ore", 2) or not inventory.add_item("wood", 1) or not CraftingScript.craft("iron_ingot", inventory, professions):
        _fail("Smithing recipe failed with sufficient materials.")
        return
    if inventory.get_item_count("iron_ingot") != 1 or professions.get_experience("smithing") != 25:
        _fail("Smithing recipe output or experience is incorrect.")
        return

    var full_inventory: GrimholtInventory = InventoryScript.new()
    if not full_inventory.add_item("healing_potion", 20) or not full_inventory.add_item("herb", 2):
        _fail("Could not prepare output-capacity regression test.")
        return
    if CraftingScript.craft("healing_potion", full_inventory, professions) or full_inventory.get_item_count("herb") != 2:
        _fail("Failed crafting consumed ingredients when output stack was full.")
        return

    var tree: GrimholtResourceNode = ResourceNodeScript.new()
    tree.configure("tree", "Eiche", "wood", 4)
    root.add_child(tree)
    var trunk := tree.get_node("TreeTrunk") as MeshInstance3D
    if trunk == null or not is_equal_approx((trunk.mesh as CylinderMesh).height, 7.4):
        _fail("Tree trunk is not using the documented world scale.")
        return
    if not tree.harvest(inventory) or tree.harvest(inventory):
        _fail("Resource harvesting is not one-time / correctly guarded.")
        return
    var spruce: GrimholtResourceNode = ResourceNodeScript.new()
    spruce.configure("tree", "Fichte", "wood", 5)
    root.add_child(spruce)
    if spruce.get_node_or_null("SpruceTier0") == null:
        _fail("Spruce placeholder does not have its own conifer silhouette.")
        return
    spruce.free()

    var building: GrimholtBuildingSystem = BuildingScript.new()
    root.add_child(building)
    var building_inventory: GrimholtInventory = InventoryScript.new()
    if not building_inventory.add_item("wooden_plank", 6):
        _fail("Could not prepare building inventory.")
        return
    if not building.place_piece("foundation", Vector3(1.4, 0.0, 1.4), building_inventory):
        _fail("Foundation placement failed with sufficient materials.")
        return
    if building_inventory.get_item_count("wooden_plank") != 0 or building.get_child_count() != 1:
        _fail("Foundation placement did not consume exactly its cost.")
        return
    if not building_inventory.add_item("wooden_plank", 4) or not building.place_piece("wall", Vector3(1.4, 0.25, 1.4), building_inventory):
        _fail("Wall placement failed with sufficient materials.")
        return
    if building.place_piece("unknown_piece", Vector3.ZERO, building_inventory):
        _fail("Unknown building piece was accepted.")
        return

    await process_frame
    building.free()
    inventory.free()
    full_inventory.free()
    building_inventory.free()
    print("PASS: 1.70 m player scale, all crafting recipes, inventory validation, resource harvesting and building costs.")
    quit(0)

func _fail(message: String) -> void:
    push_error("Extended gameplay regression test: " + message)
    quit(1)
