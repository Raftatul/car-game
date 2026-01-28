extends Node


func set_node3d_position(node: Node3D, global_pos: Vector3, reliable: bool = false) -> void:
	if reliable:
		_set_node3d_position_reliable.rpc(node.get_path(), global_pos)
	else:
		_set_node3d_position.rpc(node.get_path(), global_pos)


@rpc("authority", "call_local", "unreliable")
func _set_node3d_position(path: NodePath, global_pos: Vector3) -> void:
	var node: Node3D = get_tree().root.get_node(path)
	if node:
		node.global_position = global_pos


@rpc("authority", "call_local", "reliable")
func _set_node3d_position_reliable(path: NodePath, global_pos: Vector3) -> void:
	var node: Node3D = get_tree().root.get_node(path)
	if node:
		node.global_position = global_pos
