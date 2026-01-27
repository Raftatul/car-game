extends HBoxContainer

const INVENTORY_SLOT = preload("uid://clr8v1683e7q5")

@export var inventory_component: InventoryComponent

var slots: Array[InventorySlot]


func _ready() -> void:
	if !is_instance_valid(inventory_component): return
	
	inventory_component.active_slot_changed.connect(_on_active_slot_changed)
	inventory_component.item_added.connect(_on_item_added)
	inventory_component.item_removed.connect(_on_item_removed)
	
	for i in range(inventory_component.slot_count):
		var slot: InventorySlot = INVENTORY_SLOT.instantiate()
		slots.append(slot)
		add_child(slot)
		
		if i == inventory_component.active_slot:
			slot.set_active(true)


func _on_active_slot_changed(_old_idx: int, idx: int) -> void:
	slots[_old_idx].set_active(false)
	slots[idx].set_active(true)


func _on_item_added(idx: int, item: Item) -> void:
	slots[idx].set_item(item)


func _on_item_removed(idx: int) -> void:
	slots[idx].set_item(null)
