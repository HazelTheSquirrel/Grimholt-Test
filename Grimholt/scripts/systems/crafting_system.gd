extends RefCounted
class_name GrimholtCraftingSystem

const RECIPES := {
    "iron_ingot": {
        "name": "Eisenbarren",
        "profession": "smithing",
        "station": "forge",
        "inputs": {"iron_ore": 2, "wood": 1},
        "output": {"iron_ingot": 1},
        "experience": 25
    },
    "wooden_plank": {
        "name": "Holzplanke",
        "profession": "carpentry",
        "station": "sawmill",
        "inputs": {"wood": 2},
        "output": {"wooden_plank": 3},
        "experience": 10
    },
    "healing_potion": {
        "name": "Heiltrank",
        "profession": "alchemy",
        "station": "alchemy_table",
        "inputs": {"herb": 2},
        "output": {"healing_potion": 1},
        "experience": 20
    }
}

static func craft(recipe_id: String, inventory: GrimholtInventory, professions: GrimholtProfessionSystem) -> bool:
    if not RECIPES.has(recipe_id) or inventory == null or professions == null:
        return false
    var recipe: Dictionary = RECIPES[recipe_id]
    var inputs: Dictionary = recipe["inputs"]
    var outputs: Dictionary = recipe["output"]
    if not inventory.has_items(inputs) or not inventory.can_add_items(outputs):
        return false
    if not inventory.remove_items(inputs):
        return false
    for item_id in outputs:
        inventory.add_item(String(item_id), int(outputs[item_id]))
    professions.add_experience(String(recipe["profession"]), int(recipe["experience"]))
    return true
