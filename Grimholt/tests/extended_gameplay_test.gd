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
    for frame in range(125):
        await physics_frame
    var live_player := live_scene.get_node("Player") as GrimholtPlayer
    if live_player == null or not live_player.is_on_floor():
        _fail("Live player did not reach the terrain before interaction.")
        return
    var live_terrain := live_scene.get_node("TerrainWorld")
    if live_terrain.get_node_or_null("GrassTufts") == null or live_terrain.get_node_or_null("ScatteredStones") == null:
        _fail("Landscape ground cover and stone scatter were not generated.")
        return
    if not live_player._interact():
        _fail("E interaction ray did not reach the starter oak in front of the player.")
        return
    if live_player.inventory.get_item_count("wood") != 4:
        _fail("Starter oak harvest did not add the configured four wood to the live player inventory.")
        return
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
