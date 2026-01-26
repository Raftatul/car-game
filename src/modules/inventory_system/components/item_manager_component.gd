class_name ItemManagerComponent
extends Node

@export var inventory_component: InventoryComponent
@export var model: Node3D
@export var raycast: RayCast3D

var wants_item_use: bool = false
var wants_item_drop: bool = false

var wants_scroll_up: bool = false
var wants_scroll_down: bool = false


func _ready() -> void:
	if !is_instance_valid(inventory_component): return
	
	inventory_component.active_slot_changed.connect(_on_inventory_component_active_slot_changed)


func update() -> void:
	if !is_instance_valid(inventory_component): return
	
	if wants_scroll_up:
		inventory_component.select_next_slot()
	elif wants_scroll_down:
		inventory_component.select_previous_slot()
	
	var selected_item: Item = inventory_component.get_selected_item()
	if selected_item:
		if wants_item_use:
			selected_item.use(get_parent())
		elif wants_item_drop:
			drop_item(selected_item)


func drop_item(item: Item) -> void:
	if !is_instance_valid(model) or !is_instance_valid(raycast) or !is_instance_valid(item): return
	
	var drop_pos: Vector3 = model.to_global(raycast.target_position)
	if raycast.is_colliding():
		drop_pos = raycast.position
	inventory_component.remove_item_via_index(inventory_component.active_slot)
	_rpc_drop_item.rpc(item.get_path(), drop_pos)
	item.dropped()


@rpc("any_peer", "call_local", "reliable")
func _rpc_drop_item(node_path: NodePath, drop_pos: Vector3) -> void:
	var item: Item = get_tree().root.get_node(node_path)
	if !is_instance_valid(item): return
	item.reparent(get_tree().current_scene)
	item.global_position = drop_pos


@rpc("any_peer", "call_local", "reliable")
func _rpc_set_item_visible(node_path: NodePath, state: bool) -> void:
	var item: Item = get_tree().root.get_node(node_path)
	if !is_instance_valid(item): return
	item.visible = state


func _on_inventory_component_active_slot_changed(old_idx: int, idx: int) -> void:
	var old_item: Item = inventory_component.inventory[old_idx]
	var new_item: Item = inventory_component.inventory[idx]
	
	if old_item:
		_rpc_set_item_visible.rpc(old_item.get_path(), false)
	if new_item:
		_rpc_set_item_visible.rpc(new_item.get_path(), true)
