extends SceneTree

const InventoryScript = preload("res://scripts/systems/inventory.gd")
const ProfessionScript = preload("res://scripts/systems/profession_system.gd")
const CraftingScript = preload("res://scripts/systems/crafting_system.gd")
const ResourceNodeScript = preload("res://scripts/world/resource_node.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var inventory: GrimholtInventory = InventoryScript.new()
    var professions: GrimholtProfessionSystem = ProfessionScript.new()
    if not inventory.add_item("iron_ore", 2) or not inventory.add_item("wood", 1):
        _fail("Valid resources could not be added.")
        return
    if not CraftingScript.craft("iron_ingot", inventory, professions):
        _fail("Iron ingot recipe failed with sufficient materials.")
        return
    if inventory.get_item_count("iron_ingot") != 1 or inventory.get_item_count("iron_ore") != 0:
        _fail("Crafting did not consume and produce the expected items.")
        return
    if professions.get_experience("smithing") != 25:
        _fail("Crafting profession experience was not awarded.")
        return
    if CraftingScript.craft("iron_ingot", inventory, professions):
        _fail("Crafting succeeded without required materials.")
        return
    var resource: GrimholtResourceNode = ResourceNodeScript.new()
    resource.configure("tree", "Eiche", "wood", 4)
    root.add_child(resource)
    if not resource.harvest(inventory):
        _fail("Resource node could not be harvested.")
        return
    if inventory.get_item_count("wood") != 4:
        _fail("Resource node did not award its configured yield.")
        return
    if not inventory.add_item("healing_potion", 20):
        _fail("Could not fill a stack to its configured limit.")
        return
    if inventory.add_item("healing_potion", 1):
        _fail("Inventory accepted an item beyond its configured stack limit.")
        return
    if not inventory.add_item("herb", 2):
        _fail("Could not add ingredients for the output-capacity test.")
        return
    if CraftingScript.craft("healing_potion", inventory, professions):
        _fail("Crafting consumed ingredients despite a full output stack.")
        return
    if inventory.get_item_count("herb") != 2:
        _fail("Failed crafting consumed ingredients when output capacity was unavailable.")
        return
    if resource.harvest(inventory):
        _fail("Depleted resource node was harvested twice.")
        return
    await process_frame
    inventory.free()
    print("PASS: inventory limits, atomic crafting, profession XP and one-time resource harvesting.")
    quit(0)

func _fail(message: String) -> void:
    push_error("Gameplay systems test: " + message)
    quit(1)
