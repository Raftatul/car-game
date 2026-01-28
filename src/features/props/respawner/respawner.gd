extends Node3D

@export var point: Node3D
@export var step: float = 2.0


func _on_area_3d_body_entered(body: Node3D) -> void:
	if !is_multiplayer_authority():
		return
	
	if body is PlayerCharacter:
		var dead_players: Array = get_tree().get_nodes_in_group("players").filter(_filter_dead_players)
		for i in range(dead_players.size()):
			var player: PlayerCharacter = dead_players[i]
			MultiplayerUtility.set_node3d_position(player, point.global_position + Vector3(0.0, step * i, 0.0), true)
			player.revive.rpc()


func _filter_dead_players(a: Node) -> bool:
	if a is PlayerCharacter:
		return a.dead
	return false
