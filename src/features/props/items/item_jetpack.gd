extends GameItem

@export var force: float = 1.0


func _pre_use() -> void:
	_rpc_play_animation.rpc("rotate")


func _use(delta: float) -> void:
	consume_energy(delta)
	if player.is_in_water():
		player.velocity = player.velocity.move_toward(player.model.global_basis.y * force, force * delta)


func _post_use() -> void:
	_rpc_stop_animation.rpc()


func _energy_drained() -> void:
	_rpc_stop_animation.rpc()
