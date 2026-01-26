class_name ItemManagerComponent
extends Node

@export var inventory_component: InventoryComponent
@export var model: Node3D
@export var raycast: RayCast3D

@export var sockets: Dictionary[Item.ATTACH_POINTS, Node3D]

var wants_item_use: bool = false
var wants_item_drop: bool = false

var wants_scroll_up: bool = false
var wants_scroll_down: bool = false

var item_in_use: Item


func _ready() -> void:
	if !is_instance_valid(inventory_component): return
	
	inventory_component.active_slot_changed.connect(_on_inventory_component_active_slot_changed)
	inventory_component.item_added.connect(_on_inventory_component_item_added)


func tick(delta: float) -> void:
	if !is_instance_valid(inventory_component): return
	
	if wants_scroll_up:
		inventory_component.select_next_slot()
	elif wants_scroll_down:
		inventory_component.select_previous_slot()
	
	var selected_item: Item = inventory_component.get_selected_item()
	if selected_item:
		if wants_item_use:
			_handle_item_use(delta, selected_item)
		elif is_instance_valid(item_in_use):
			item_in_use.post_use(get_parent())
			item_in_use = null
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


func _handle_item_use(delta: float, item: Item) -> void:
	if !is_instance_valid(item_in_use):
		item_in_use = item
		item.pre_use(get_parent())
	else:
		item.use(delta, get_parent())


func _get_socket(item: Item) -> Node3D:
	return sockets[item.attach_point]


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


@rpc("any_peer", "call_local")
func _rpc_set_item_in_hand(node_path: NodePath, should_be_visible: bool) -> void:
	var item: Item = get_tree().root.get_node(node_path)
	if item:
		item.visible = should_be_visible
		item.reparent.call_deferred(_get_socket(item))
		item.set_deferred("position", Vector3.ZERO)
		item.set_deferred("rotation", Vector3.ZERO)


func _on_inventory_component_item_added(_idx: int, item: Item) -> void:
	_rpc_set_item_in_hand.rpc(item.get_path(), item == inventory_component.get_selected_item())


func _on_inventory_component_active_slot_changed(old_idx: int, idx: int) -> void:
	var old_item: Item = inventory_component.inventory[old_idx]
	var new_item: Item = inventory_component.inventory[idx]
	
	if old_item:
		_rpc_set_item_visible.rpc(old_item.get_path(), false)
	if new_item:
		_rpc_set_item_visible.rpc(new_item.get_path(), true)
