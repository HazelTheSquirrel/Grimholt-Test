extends Node
class_name GrimholtInventory

signal inventory_changed

var items: Dictionary = {}

func add_item(item_id: String, amount: int = 1) -> bool:
    if not can_add_items({item_id: amount}):
        return false
    items[item_id] = int(items.get(item_id, 0)) + amount
    inventory_changed.emit()
    return true

func can_add_items(additions: Dictionary) -> bool:
    for item_id in additions:
        var amount := int(additions[item_id])
        var definition := GrimholtItemCatalog.get_item(String(item_id))
        if definition.is_empty() or amount <= 0:
            return false
        var stack_limit := int(definition.get("stack", 0))
        if stack_limit <= 0 or get_item_count(String(item_id)) + amount > stack_limit:
            return false
    return true

func get_item_count(item_id: String) -> int:
    return int(items.get(item_id, 0))

func has_items(requirements: Dictionary) -> bool:
    for item_id in requirements:
        var amount := int(requirements[item_id])
        if not GrimholtItemCatalog.exists(String(item_id)) or amount <= 0:
            return false
        if get_item_count(String(item_id)) < amount:
            return false
    return true

func remove_items(requirements: Dictionary) -> bool:
    if not has_items(requirements):
        return false
    for item_id in requirements:
        var remaining := get_item_count(String(item_id)) - int(requirements[item_id])
        if remaining <= 0:
            items.erase(item_id)
        else:
            items[item_id] = remaining
    inventory_changed.emit()
    return true

func get_summary() -> String:
    if items.is_empty():
        return "Inventar: leer"
    var entries: Array[String] = []
    for item_id in items:
        var definition := GrimholtItemCatalog.get_item(String(item_id))
        entries.append("%s x%d" % [definition.get("name", item_id), int(items[item_id])])
    entries.sort()
    return "Inventar: " + " | ".join(entries)
