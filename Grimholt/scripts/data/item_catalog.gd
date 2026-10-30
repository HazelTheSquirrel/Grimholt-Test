extends RefCounted
class_name GrimholtItemCatalog

const ITEMS := {
    "wood": {"name": "Rundholz", "category": "Rohstoff", "stack": 200},
    "iron_ore": {"name": "Eisenerz", "category": "Erz", "stack": 200},
    "herb": {"name": "Heilkraut", "category": "Pflanze", "stack": 200},
    "iron_ingot": {"name": "Eisenbarren", "category": "Barren", "stack": 100},
    "wooden_plank": {"name": "Holzplanke", "category": "Baumaterial", "stack": 200},
    "healing_potion": {"name": "Heiltrank", "category": "Verbrauchsgut", "stack": 20}
}

static func get_item(item_id: String) -> Dictionary:
    return ITEMS.get(item_id, {})

static func exists(item_id: String) -> bool:
    return ITEMS.has(item_id)
