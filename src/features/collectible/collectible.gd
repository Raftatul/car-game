extends RigidBody3D


@rpc("any_peer", "call_local", "reliable")
func _rpc_disable_node() -> void:
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return
	
	if body is PlayerCharacter:
		if body.set_item_in_hand(self):
			_rpc_disable_node.rpc()
