extends Node3D

var stored_fish: int = 0 :
	set(v):
		stored_fish = v
		_update_label()

var required_fish: int = 0 :
	set(v):
		required_fish = v
		_update_label()

@onready var label: Label3D = $Label3D


func _ready() -> void:
	required_fish = get_tree().get_nodes_in_group("fish").size()


func _update_label() -> void:
	label.text = "🐟 %s/%s" % [stored_fish, required_fish]


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return
	
	if body is PlayerCharacter:
		var item: Node3D = body.get_item_in_hand()
		if item:
			stored_fish += 1
			body.set_item_in_hand(null)
			_rpc_destroy_item.rpc(item.get_path())


@rpc("any_peer", "call_local", "reliable")
func _rpc_destroy_item(node_path: NodePath) -> void:
	var item = get_tree().root.get_node(node_path)
	if item:
		item.queue_free()
