extends GameItem

@export var force: float = 1.0


func _pre_use() -> void:
	_rpc_play_animation.rpc("rotate")


func _use(_delta: float) -> void:
	if actor is PlayerCharacter:
		if actor.is_in_water():
			actor.apply_central_force(actor.model.global_basis.y * force)


func _post_use() -> void:
	_rpc_stop_animation.rpc()


func _energy_drained() -> void:
	_rpc_stop_animation.rpc()
