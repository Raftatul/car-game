class_name InventoryComponent
extends Node

signal active_slot_changed(old_idx: int, idx: int)
signal item_added(idx: int, item: Item)
signal item_removed(idx: int)

@export_range(1, 10, 1.0, "or_greater") var slot_count: int = 1

var active_slot: int = 0 :
	set(v):
		if v != active_slot:
			active_slot_changed.emit(active_slot, v)
			active_slot = v

var inventory: Dictionary[int, Item] = {}


func _ready() -> void:
	for i in range(slot_count):
		inventory[i] = null


func select_next_slot(should_wrap: bool = true) -> void:
	if should_wrap:
		active_slot = wrap(active_slot + 1, 0, slot_count)
	else:
		active_slot = min(active_slot + 1, slot_count - 1)


func select_previous_slot(should_wrap: bool = true) -> void:
	if should_wrap:
		active_slot = wrap(active_slot - 1, 0, slot_count)
	else:
		active_slot = max(active_slot - 1, 0)


func is_inventory_full() -> bool:
	return inventory.keys().filter(_filter_empty_slots).is_empty()


func is_slot_full(idx: int) -> bool:
	return is_instance_valid(inventory[idx])


func get_selected_item() -> Item:
	return inventory[active_slot]


func add_item(item: Item) -> int:
	var idx: int = active_slot
	if is_slot_full(idx):
		idx = inventory.keys().filter(_filter_empty_slots)[0]
	inventory[idx] = item
	item_added.emit(idx, item)
	return idx


func remove_item(item: Item) -> void:
	var idx: int = inventory.find_key(item)
	inventory[idx] = null
	item_removed.emit(idx)


func remove_item_via_index(idx: int) -> void:
	inventory[idx] = null
	item_removed.emit(idx)


func _filter_empty_slots(idx: int) -> bool:
	return !is_instance_valid(inventory[idx])
