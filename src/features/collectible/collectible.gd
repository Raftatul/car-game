extends RigidBody3D


@rpc("any_peer", "call_local", "reliable")
func _rpc_disable_node() -> void:
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)


func _on_interactable_interacted(node: Node) -> void:
	if node is PlayerCharacter:
		if node.set_item_in_hand(self):
			_rpc_disable_node.rpc()
