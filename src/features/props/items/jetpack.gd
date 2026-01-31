extends GameItem

@export var force: float = 1.0
@export var acceleration: float = 10.0


func _pre_use() -> void:
	_rpc_play_animation.rpc("rotate")


func _use(delta: float) -> void:
	if actor is PlayerCharacter:
		if actor.buoyancy.is_in_water():
			actor.velocity = actor.velocity.move_toward(actor.model.global_basis.y * force, acceleration * delta)


func _post_use() -> void:
	_rpc_stop_animation.rpc()


func _lifetime_drained() -> void:
	_rpc_stop_animation.rpc()
